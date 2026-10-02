// G12 (D1.3, D3.8, D7) — leveling branché sur le magasin : le moteur de
// progression `kalis_quest` lit le profil v2, le journal des moteurs (G9),
// le bloc en cours et le résumé du moteur dynamique ; l'application garde
// seulement son état (section `questState` de la sauvegarde) et l'affiche.
//
// Aucune règle de progression ici : XP, niveaux, quêtes, attributs, rangs,
// objectifs et Krédits viennent du moteur. Le registre d'XP est en ajout
// seul (le niveau ne redescend jamais, même après la suppression d'une
// séance). Remise à zéro (D1.3) : l'état démarre vide au premier appel ;
// l'ancien système (XP dérivés du journal) est retiré.
part of 'store.dart';

/// Moteur de progression de l'application (une seule instance).
final kq.KalisQuest kalisQuestEngine = kq.KalisQuest();

/// Courbe des niveaux du moteur (pastille, aperçu d'import).
final kq.LevelCurve kalisLevelCurve = kalisQuestEngine.curve;

/// Section `questState` (v1) de la sauvegarde : état du moteur (registres
/// d'XP et de Krédits, quêtes, état opaque), graine de l'utilisateur,
/// déclarations des quêtes de récupération, présentations de Koach déjà
/// faites. Facultative : absente tant que la progression n'a jamais été
/// calculée (installation neuve sans profil).
class QuestData {
  static const int version = 1;

  /// Bornes de lecture d'un fichier (KT-015).
  static const int maxEntries = 200000;
  static const int maxQuests = 5000;

  final kc.QuestState state;

  /// Graine fixe de l'utilisateur (coffres, choix des quêtes).
  final int seed;

  /// Quêtes de récupération déclarées faites (jour même), gardées 7 jours.
  final List<kc.QuestClaim> claims;

  /// Nouveautés déjà présentées par Koach (codes d'écran).
  final Set<String> intros;

  /// « Nouveau départ » annoncé (D1.3).
  final bool resetAnnounced;

  const QuestData({
    required this.state,
    required this.seed,
    this.claims = const [],
    this.intros = const {},
    this.resetAnnounced = false,
  });

  static const kc.QuestState emptyState = kc.QuestState(
    xp: [],
    kredits: [],
    quests: [],
    data: {},
  );

  QuestData copyWith({
    kc.QuestState? state,
    List<kc.QuestClaim>? claims,
    Set<String>? intros,
    bool? resetAnnounced,
  }) => QuestData(
    state: state ?? this.state,
    seed: seed,
    claims: claims ?? this.claims,
    intros: intros ?? this.intros,
    resetAnnounced: resetAnnounced ?? this.resetAnnounced,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'seed': seed,
    'state': state.toJson(),
    if (claims.isNotEmpty) 'claims': [for (final c in claims) c.toJson()],
    if (intros.isNotEmpty) 'intros': intros.toList()..sort(),
    if (resetAnnounced) 'resetAnnounced': true,
  };

  /// Lecture stricte : [FormatException] si la section est illisible ou
  /// hors contrat (registres, quêtes).
  factory QuestData.fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('questState');
    final m = Map<String, Object?>.from(raw);
    final v = m['version'];
    if (v is! int || v < 1) throw const FormatException('questState.version');
    final seed = m['seed'];
    if (seed is! int || seed < 0) {
      throw const FormatException('questState.seed');
    }
    final rawState = m['state'];
    if (rawState is! Map) throw const FormatException('questState.state');
    final s = Map<String, Object?>.from(rawState);
    if ((s['xp'] is List && (s['xp'] as List).length > maxEntries) ||
        (s['kredits'] is List && (s['kredits'] as List).length > maxEntries) ||
        (s['quests'] is List && (s['quests'] as List).length > maxQuests)) {
      throw const FormatException('questState : trop d’entrées');
    }
    final state = kc.QuestState.fromJson(s);
    if (state.validate().isNotEmpty) {
      throw const FormatException('questState hors contrat');
    }
    final claims = <kc.QuestClaim>[];
    final rawClaims = m['claims'];
    if (rawClaims != null) {
      if (rawClaims is! List || rawClaims.length > 1000) {
        throw const FormatException('questState.claims');
      }
      for (final c in rawClaims) {
        if (c is! Map) throw const FormatException('questState.claims');
        claims.add(kc.QuestClaim.fromJson(Map<String, Object?>.from(c)));
      }
    }
    final intros = <String>{};
    final rawIntros = m['intros'];
    if (rawIntros != null) {
      if (rawIntros is! List || rawIntros.length > 100) {
        throw const FormatException('questState.intros');
      }
      for (final i in rawIntros) {
        if (i is! String) throw const FormatException('questState.intros');
        intros.add(i);
      }
    }
    final announced = m['resetAnnounced'];
    if (announced != null && announced is! bool) {
      throw const FormatException('questState.resetAnnounced');
    }
    return QuestData(
      state: state,
      seed: seed,
      claims: claims,
      intros: intros,
      resetAnnounced: announced == true,
    );
  }

  /// XP total du registre.
  int get totalXp {
    var sum = 0;
    for (final e in state.xp) {
      sum += e.amount;
    }
    return sum;
  }
}

/// Gains d'une séance (ou d'une action), pour l'écran de fin de séance.
class QuestGains {
  /// XP par origine (effort, régularité, records, jalons, quêtes).
  final Map<kc.XpSource, int> xpBySource;
  final int kredits;
  final kc.LevelState before, after;

  /// Quêtes payées depuis la marque.
  final List<kc.Quest> quests;

  /// Événements nouveaux (records, coffre, note, combo, rang…).
  final List<kc.DelightEvent> events;

  /// Séance faite malgré une douleur déclarée : aucune récompense.
  final bool painNoReward;

  /// Gain borné par un plafond (séance en plus, séance écourtée).
  final String? cappedScope;

  const QuestGains({
    required this.xpBySource,
    required this.kredits,
    required this.before,
    required this.after,
    this.quests = const [],
    this.events = const [],
    this.painNoReward = false,
    this.cappedScope,
  });

  int get xp => xpBySource.values.fold(0, (a, b) => a + b);
  bool get levelUp =>
      kq.LevelCurve.ordinal(after) > kq.LevelCurve.ordinal(before);
  bool get isEmpty =>
      xp == 0 &&
      kredits == 0 &&
      quests.isEmpty &&
      events.isEmpty &&
      !painNoReward &&
      cappedScope == null;
}

/// Marque posée avant une action : longueurs des registres et niveau.
class QuestMark {
  final int xp, kredits, events;
  final kc.LevelState level;
  final String? sessionId;
  const QuestMark(this.xp, this.kredits, this.events, this.level, this.sessionId);
}

extension QuestStore on AppStore {
  kc.CivilDate get _questToday => civilOf(storeClock());

  /// Le moteur peut tourner : base chargée, profil v2, section lisible.
  bool get questAvailable =>
      _questRaw == null && SessionAdaptStore(this).adaptAvailable;

  /// Section `questState` illisible au démarrage (gardée telle quelle).
  bool get questUnreadable => _questRaw != null;

  /// Niveau affiché (pastille) : celui du moteur, sinon celui du registre
  /// enregistré (niveau 1 sans registre).
  kc.LevelState get questLevel {
    final o = quest;
    if (o != null) return o.level;
    return kalisLevelCurve.stateOf(questData?.totalXp ?? 0);
  }

  /// Dernier résultat du moteur (calculé au besoin, gardé tant que rien ne
  /// change) ; null si le moteur ne peut pas tourner.
  kc.QuestOutcome? get quest {
    if (!questAvailable) return null;
    final adaptStore = SessionAdaptStore(this);
    final profile = adaptStore.adaptProfile;
    if (profile == null) return null;
    final place = evolutionPlace;
    final review = lastEvolutionReview;
    final today = _questToday;
    final log = adaptStore.adaptTrainingLog(today: today);
    final key = [
      today.iso,
      identityHashCode(log),
      identityHashCode(profile),
      place?.blockId,
      identityHashCode(place?.block),
      identityHashCode(review),
      _questRevision,
    ].join('|');
    if (key == _questKey && _questOutcome != null) return _questOutcome;
    final data = questData ?? QuestData(state: QuestData.emptyState, seed: _newQuestSeed());
    final input = kc.QuestInput(
      profile: profile,
      log: log,
      block: place?.block,
      adaptation: review?.review.summary,
      state: data.state,
      today: today,
      seed: data.seed,
      claims: [
        for (final c in data.claims)
          if (c.date == today) c,
      ],
    );
    final sw = Stopwatch()..start();
    final kc.QuestOutcome outcome;
    try {
      outcome = kalisQuestEngine.evaluate(content.catalog!, input);
    } catch (e) {
      questError = '$e';
      _questKey = key;
      _questOutcome = null;
      return null;
    }
    sw.stop();
    questLastMs = sw.elapsedMilliseconds;
    questError = null;
    _questOutcome = outcome;
    _questEvents.addAll(outcome.events);
    final changed =
        questData == null || !_sameQuestState(data.state, outcome.state);
    if (changed) {
      // Déclarations de plus de 7 jours retirées (le moteur ne les lit que
      // le jour même).
      final keep = [
        for (final c in data.claims)
          if (today.dayNumber - c.date.dayNumber <= 7) c,
      ];
      questData = data.copyWith(state: outcome.state, claims: keep);
      _questRevision++;
      _persist();
    }
    // Clé recalculée après l'écriture : la révision a pu changer.
    _questKey = [
      today.iso,
      identityHashCode(log),
      identityHashCode(profile),
      place?.blockId,
      identityHashCode(place?.block),
      identityHashCode(review),
      _questRevision,
    ].join('|');
    return outcome;
  }

  static bool _sameQuestState(kc.QuestState a, kc.QuestState b) =>
      a.xp.length == b.xp.length &&
      a.kredits.length == b.kredits.length &&
      a.lastEvaluatedOn == b.lastEvaluatedOn &&
      kc.jsonDeepEquals(
        [for (final q in a.quests) q.toJson()],
        [for (final q in b.quests) q.toJson()],
      ) &&
      kc.jsonDeepEquals(a.data, b.data);

  int _newQuestSeed() => math.Random.secure().nextInt(1 << 31);

  /// Recalcule et prévient les écrans si quelque chose a changé.
  void questRefresh() {
    final before = _questRevision;
    final o = quest;
    if (o != null && before != _questRevision) notifyListeners();
  }

  // ------------------------------------------------------------ gains

  /// Marque avant une action (fin de séance, outil de test).
  QuestMark questMark({String? sessionId}) {
    quest;
    final d = questData;
    return QuestMark(
      d?.state.xp.length ?? 0,
      d?.state.kredits.length ?? 0,
      _questEvents.length,
      questLevel,
      sessionId,
    );
  }

  /// Gains depuis [mark] (null si rien n'a été gagné ni signalé).
  QuestGains? questGainsSince(QuestMark mark) {
    final o = quest;
    final d = questData;
    if (o == null || d == null) return null;
    final bySource = <kc.XpSource, int>{};
    var pain = false;
    String? capped;
    final paidQuests = <String>{};
    for (final e in d.state.xp.skip(mark.xp)) {
      if (e.amount > 0) {
        bySource.update(e.source, (v) => v + e.amount, ifAbsent: () => e.amount);
      }
      if (e.source == kc.XpSource.quest && e.refId != null) {
        paidQuests.add(e.refId!);
      }
      if (mark.sessionId != null && e.sessionId == mark.sessionId) {
        for (final r in e.reasons) {
          if (r.code == 'quest.no_reward_pain') pain = true;
          if (r.code == 'quest.xp_capped') {
            capped = '${r.params['scope'] ?? ''}';
          }
        }
      }
    }
    var kredits = 0;
    for (final e in d.state.kredits.skip(mark.kredits)) {
      kredits += e.amount;
    }
    final gains = QuestGains(
      xpBySource: bySource,
      kredits: kredits,
      before: mark.level,
      after: o.level,
      quests: [
        for (final q in d.state.quests)
          if (paidQuests.contains(q.id)) q,
      ],
      events: _questEvents.skip(mark.events).toList(),
      painNoReward: pain,
      cappedScope: capped,
    );
    return gains.isEmpty ? null : gains;
  }

  /// Gains en attente de l'écran de fin de séance (consommés une fois).
  QuestGains? consumeGains() {
    final g = _pendingGains;
    _pendingGains = null;
    return g;
  }

  // ----------------------------------------------------------- quêtes

  /// Quêtes de l'état (en cours et récentes).
  List<kc.Quest> get questList => quest?.state.quests ?? const [];

  /// Déclare faite la quête de récupération [questId] (aujourd'hui).
  void questClaim(String questId) {
    final d = questData;
    if (d == null) return;
    final today = _questToday;
    if (d.claims.any((c) => c.questId == questId && c.date == today)) return;
    questData = d.copyWith(
      claims: [
        ...d.claims,
        kc.QuestClaim(questId: questId, date: today),
      ],
    );
    _questRevision++;
    _persist();
    questRefresh();
    notifyListeners();
  }

  /// La quête [q] se déclare (récupération d'un jour de repos), aujourd'hui.
  bool questClaimable(kc.Quest q) =>
      q.status == kc.QuestStatus.active &&
      q.params['claimable'] == true &&
      q.startsOn == _questToday &&
      !(questData?.claims.any(
            (c) => c.questId == q.id && c.date == _questToday,
          ) ??
          false);

  // ------------------------------------------------------ Koach (D6.4)

  /// Koach a déjà présenté la nouveauté [code].
  bool questIntroSeen(String code) =>
      questData?.intros.contains(code) ?? false;

  void markQuestIntro(String code) {
    final d = questData;
    if (d == null || d.intros.contains(code)) return;
    questData = d.copyWith(intros: {...d.intros, code});
    _questRevision++;
    _persist();
    notifyListeners();
  }

  /// « Nouveau départ » à annoncer (D1.3) : une seule fois, à qui avait un
  /// historique d'entraînement avant le branchement.
  bool get questResetToAnnounce {
    final d = questData;
    if (d == null || d.resetAnnounced) return false;
    return logs.values.any((l) => l.done);
  }

  void markQuestResetAnnounced() {
    final d = questData;
    if (d == null || d.resetAnnounced) return;
    questData = d.copyWith(resetAnnounced: true);
    _questRevision++;
    _persist();
    notifyListeners();
  }

  // -------------------------------------------------------- objectifs

  /// Avancement de l'objectif [goalId] (null : inconnu du moteur).
  kc.GoalProgress? goalProgressOf(String goalId) {
    for (final g in quest?.goals ?? const <kc.GoalProgress>[]) {
      if (g.goalId == goalId) return g;
    }
    return null;
  }

  /// Objectifs suggérés par Koach (moteur), sans ceux déjà au profil.
  List<kc.Goal> get questSuggestedGoals {
    final have = <String>{
      for (final g in athleteProfile?.goals ?? const <kc.Goal>[])
        if (g.exerciseId != null) '${g.exerciseId}|${g.metric?.code}',
    };
    return [
      for (final g in quest?.suggestedGoals ?? const <kc.Goal>[])
        if (!have.contains('${g.exerciseId}|${g.metric?.code}')) g,
    ];
  }

  /// Remplace les objectifs du profil (ajout d'une suggestion, échéance ou
  /// cible ajustée). Le programme n'est pas recréé : le bloc suivant lira
  /// le profil.
  bool saveAthleteGoals(List<kc.Goal> goals) {
    final a = athlete;
    if (a == null) return false;
    final today = _questToday;
    final p = a.profile.copyWith(
      goals: goals,
      updatedOn: a.profile.createdOn > today ? a.profile.createdOn : today,
    );
    if (p.validate().isNotEmpty) return false;
    final changes = [
      ...a.changes,
      ProfileChange(athleteAt(storeClock()), const ['goals'], false),
    ];
    if (changes.length > AthleteRecord.maxChanges) {
      changes.removeRange(0, changes.length - AthleteRecord.maxChanges);
    }
    athlete = AthleteRecord(
      profile: p,
      savedAt: athleteAt(storeClock()),
      birthYearAt: a.birthYearAt,
      limitationsAt: a.limitationsAt,
      changes: changes,
    );
    _athleteRaw = null;
    pilotageEpoch++;
    _persist();
    notifyListeners();
    return true;
  }

  /// Ajoute l'objectif suggéré [g] au profil (identifiant neuf, « proposé
  /// par Koach »).
  bool addSuggestedGoal(kc.Goal g) {
    final goals = [...?athleteProfile?.goals];
    goals.add(
      g.copyWith(
        id: nextGoalId(goals),
        origin: kc.GoalOrigin.suggested,
        createdOn: _questToday,
      ),
    );
    return saveAthleteGoals(goals);
  }

  /// Applique la proposition du moteur pour l'objectif en retard [goalId] :
  /// nouvelle échéance ([date]) ou nouvelle cible ([target]).
  bool adjustGoal(String goalId, {kc.CivilDate? date, double? target}) {
    final goals = [...?athleteProfile?.goals];
    final i = goals.indexWhere((g) => g.id == goalId);
    if (i < 0) return false;
    goals[i] = goals[i].copyWith(
      targetDate: date ?? goals[i].targetDate,
      targetValue: target ?? goals[i].targetValue,
    );
    return saveAthleteGoals(goals);
  }

  // ------------------------------------------------- outils de test (G1)

  /// Session de test : +[amount] XP au registre (écriture datée
  /// d'aujourd'hui, jamais retirée), puis calcul du moteur (niveaux et
  /// Krédits de niveau par le moteur).
  QuestGains? devAddXp(int amount) {
    if (!kDevBuild || !SessionSpace.isDev) return null;
    if (quest == null) return null;
    final mark = questMark();
    final d = questData!;
    final n = d.state.xp.length;
    final id = 'dev-xp-$n';
    final entry = kc.XpEntry(
      sequence: n,
      date: _questToday,
      source: kc.XpSource.quest,
      amount: amount,
      refId: id,
      reasons: [
        kc.Reason(code: 'quest.xp_quest', params: {'questId': id}),
      ],
    );
    questData = d.copyWith(
      state: d.state.copyWith(xp: [...d.state.xp, entry]),
    );
    _questRevision++;
    _persist();
    final gains = questGainsSince(mark);
    notifyListeners();
    return gains;
  }

  /// Session de test : les quêtes du jour encore actives sont marquées
  /// faites ; le moteur les paie comme une quête réussie.
  QuestGains? devCompleteDailyQuests() {
    if (!kDevBuild || !SessionSpace.isDev) return null;
    if (quest == null) return null;
    final mark = questMark();
    final d = questData!;
    final today = _questToday;
    var any = false;
    final quests = [
      for (final q in d.state.quests)
        if (q.kind == kc.QuestKind.daily &&
            q.status == kc.QuestStatus.active &&
            q.startsOn == today)
          () {
            any = true;
            return q.copyWith(
              progress: q.target,
              params: {...q.params, 'claimable': true},
            );
          }()
        else
          q,
    ];
    if (!any) return null;
    questData = d.copyWith(state: d.state.copyWith(quests: quests));
    _questRevision++;
    _persist();
    final gains = questGainsSince(mark);
    notifyListeners();
    return gains;
  }
}
