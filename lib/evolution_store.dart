// G10 (D5.1, D5.6, D5.7, D5.11) — évolution du programme branchée sur le
// magasin : revue du moteur dynamique (`kalis_adapt.review`) sur le bloc de
// la semaine en cours, propositions appliquées (mode assisté) ou soumises
// (mode libre), refus transmis au moteur, annulation jusqu'à la séance
// concernée, historique des changements, déblocage visible.
//
// Aucune règle d'entraînement ici : le moteur propose (avec le moteur
// statique pour les restructurations, D5.1), `applyProposal` applique. Une
// proposition appliquée est une couche posée sur son bloc à la lecture
// (plan/plan_evolution.dart) : les blocs enregistrés ne changent jamais.
part of 'store.dart';

/// Dernière revue du moteur (inspecteur, déblocage, export du mode dev) ;
/// jamais sauvegardée.
class EvolutionReview {
  final kc.AdaptReview review;
  final kc.AdaptInput input;
  final AdaptPlace place;

  /// Semaine (S) du programme de la revue.
  final int week;
  final int ms;
  const EvolutionReview({
    required this.review,
    required this.input,
    required this.place,
    required this.week,
    required this.ms,
  });
}

/// Niveau de déblocage (D5.7) et prochain palier, pour Koach.
class EvolutionUnlock {
  final kc.UnlockLevel level;
  final int weeksObserved;
  final int blocksDone;

  /// Prochain niveau (null : tout est débloqué).
  final kc.UnlockLevel? next;

  /// Semaines de données qui manquent pour [next] (0 : il ne manque que des
  /// blocs ou la confiance).
  final int weeksToNext;

  /// Blocs terminés qui manquent pour [next].
  final int blocksToNext;
  final double confidence;
  const EvolutionUnlock({
    required this.level,
    required this.weeksObserved,
    required this.blocksDone,
    required this.next,
    required this.weeksToNext,
    required this.blocksToNext,
    required this.confidence,
  });
}

extension EvolutionStore on AppStore {
  kc.CivilDate get _evoToday => civilOf(storeClock());

  /// Bloc [base] avec les propositions en place (jusqu'à la semaine [atWeek]
  /// du bloc comprise ; null : toutes).
  kc.ProgramBlock evolveBlock(kc.ProgramBlock base, {int? atWeek}) {
    final list = planEvolution.inEffect(base.pass1.blockId);
    if (list.isEmpty) return base;
    return evolvedBlock(base, list, atWeek: atWeek);
  }

  /// Mise en forme d'une semaine du programme créé : le bloc tel qu'il est
  /// cette semaine-là (ajustements de la passe 2 puis propositions en
  /// place).
  PlanBlockEntry _evoWeekEntry(PlanBlockEntry e, int weekIndex) {
    final list = planEvolution.inEffect(e.block.pass1.blockId);
    if (list.isEmpty) return e;
    return PlanBlockEntry(
      block: evolvedBlock(adjustedBlock(e), list, atWeek: weekIndex),
      seed: e.seed,
      locks: e.locks,
      validatedAt: e.validatedAt,
    );
  }

  /// Semaine (S) d'aujourd'hui dans le programme ; après sa fin (bloc
  /// suivant pas encore validé), la dernière ; null avant son départ.
  int? get _evoWeek {
    final now = storeClock();
    if (program.afterEnd(now)) return program.weeks.length;
    if (!program.containsDate(now)) return null;
    return program.weekFor(now);
  }

  /// Place de la semaine en cours dans un bloc du moteur (première journée
  /// d'entraînement de la semaine).
  AdaptPlace? get evolutionPlace {
    final w = _evoWeek;
    if (w == null) return null;
    for (var j = 1; j <= 7; j++) {
      final p = SessionAdaptStore(this).adaptPlaceOf(w, j);
      if (p != null) return p;
    }
    return null;
  }

  /// CI1 : jour d'échéance (`EventDayAdvisor.planEventDay`) : pour une
  /// compétition de force, l'échauffement et les tentatives proposées
  /// (recalculées après chaque tentative faite, [done]) ; pour une épreuve
  /// de répétitions, l'objectif et le rythme. Null : pas de bloc en cours,
  /// échéance inconnue du profil ou erreur du moteur.
  kc.EventDayPlan? evolutionEventDay(
    String eventId, {
    List<kc.AttemptResult> done = const [],
    kc.EventObjective? objective,
    double? bodyWeightKg,
  }) {
    final place = evolutionPlace;
    final catalog = content.catalog;
    if (place == null || catalog == null) return null;
    final input = _evoInput(place);
    if (input == null) return null;
    if (!(input.profile.events ?? const <kc.SeasonEvent>[]).any(
      (e) => e.id == eventId,
    )) {
      return null;
    }
    try {
      final plan = kalisAdaptEngine.planEventDay(
        catalog,
        kc.EventDayRequest(
          input: input,
          eventId: eventId,
          done: done,
          objective: objective,
          bodyWeightKg: bodyWeightKg,
        ),
      );
      return plan.validate().isEmpty ? plan : null;
    } catch (_) {
      return null;
    }
  }

  /// Entrée du moteur pour la revue de la semaine en cours.
  kc.AdaptInput? _evoInput(AdaptPlace place) {
    final profile = SessionAdaptStore(this).adaptProfile;
    if (profile == null) return null;
    return kc.AdaptInput(
      profile: profile,
      block: place.block,
      log: SessionAdaptStore(this).adaptTrainingLog(),
      today: _evoToday,
      decisions: planEvolution.decisions,
      season: SessionAdaptStore(this).adaptSeasonOf(place),
    );
  }

  /// Revue du moteur sur le bloc de la semaine en cours : nouvelles
  /// propositions appliquées (mode assisté) ou soumises (mode libre) ;
  /// propositions en attente que le moteur ne fait plus retirées. Une seule
  /// revue par état (jour, journal, bloc, décisions, mode). Vrai si
  /// l'évolution a changé.
  bool evolutionRefresh({bool force = false}) {
    // Section illisible au démarrage : gardée telle quelle, rien n'est
    // écrit par-dessus (aucune perte).
    if (_evoRaw != null) return false;
    if (!SessionAdaptStore(this).adaptAvailable) return false;
    final w = _evoWeek;
    final place = evolutionPlace;
    if (w == null || place == null) return false;
    final input = _evoInput(place);
    if (input == null) return false;
    final mode = SessionAdaptStore(this).adaptMode;
    final key = [
      _evoToday.iso,
      place.blockId,
      identityHashCode(place.block),
      identityHashCode(input.log),
      identityHashCode(input.profile),
      _evoRevision,
      mode,
    ].join('|');
    if (!force && key == _evoRefreshKey) return false;
    _evoRefreshKey = key;
    kc.AdaptReview review;
    final sw = Stopwatch()..start();
    try {
      review = kalisAdaptEngine.review(content.catalog!, input);
    } catch (_) {
      return false;
    }
    sw.stop();
    lastEvolutionReview = EvolutionReview(
      review: review,
      input: input,
      place: place,
      week: w,
      ms: sw.elapsedMilliseconds,
    );
    // CI1 : tests et figures d'un bloc du chemin calibré reportés au
    // profil (jamais pour le programme importé du propriétaire).
    final reported =
        !place.imported &&
        ct.isCoachBlock(place.block) &&
        AthleteProfileStore(
          this,
        ).reportEngineResults(review, since: place.block.pass1.startDate);
    return evolutionReceive(place, review.proposals) || reported;
  }

  /// Propositions [proposals] du moteur pour le bloc de [place] : nouvelles
  /// propositions appliquées (mode assisté) ou en attente (mode libre) ;
  /// celles en attente que le moteur ne fait plus (ou d'un autre bloc) sont
  /// retirées. Vrai si
  /// l'évolution a changé. (Appelé par [evolutionRefresh] ; public pour les
  /// tests.)
  bool evolutionReceive(AdaptPlace place, List<kc.Proposal> proposals) {
    if (_evoRaw != null) return false;
    // CI1c (C10.2) : sur le bloc importé (programme de 40 semaines), une
    // proposition qui ne peut pas s'appliquer jour pour jour par-dessus le
    // programme n'est plus proposée comme applicable : Koach le dit en
    // clair dans Évolution.
    if (place.imported) {
      final kept = <kc.Proposal>[];
      final off = <kc.Proposal>[];
      for (final p in proposals) {
        (evolutionApplicable(place, p) ? kept : off).add(p);
      }
      evolutionNotApplicable = off;
      proposals = kept;
    } else {
      evolutionNotApplicable = const [];
    }
    final mode = SessionAdaptStore(this).adaptMode;
    final today = _evoToday.iso;
    final offered = {for (final p in proposals) p.id};
    final out = <EvolutionEntry>[];
    var changed = false;
    for (final e in planEvolution.entries) {
      if (e.status == EvoStatus.pending &&
          (e.blockId != place.blockId || !offered.contains(e.id))) {
        // Le moteur ne la fait plus (semaine passée, données nouvelles,
        // autre bloc).
        changed = true;
        continue;
      }
      out.add(e);
    }
    for (final p in proposals) {
      final i = out.indexWhere(
        (e) => e.id == p.id && e.blockId == place.blockId,
      );
      final auto = mode == 'assisted' && p.autoApplicable;
      if (i < 0) {
        out.add(
          EvolutionEntry(
            proposal: p,
            blockId: place.blockId,
            status: auto ? EvoStatus.applied : EvoStatus.pending,
            decidedOn: auto ? today : null,
            mode: mode,
          ),
        );
        changed = true;
      } else if (out[i].status == EvoStatus.pending &&
          (auto || !kc.jsonDeepEquals(out[i].proposal.toJson(), p.toJson()))) {
        // Toujours proposée : la plus récente (bloc et diff à jour) ;
        // appliquée si le mode est passé à assisté.
        final next = out[i].copyWith(
          proposal: p,
          status: auto ? EvoStatus.applied : null,
          decidedOn: auto ? today : null,
          mode: auto ? mode : null,
          clearLater: auto,
        );
        if (auto) {
          // Couches dans l'ordre où elles sont appliquées.
          out
            ..removeAt(i)
            ..add(next);
        } else {
          out[i] = next;
        }
        changed = true;
      }
    }
    if (!changed) return false;
    _evoCommit(out);
    return true;
  }

  /// CI1c : la proposition [p] change le bloc de [place] et, pour le bloc
  /// importé, garde ses journées (la couche se montre jour pour jour).
  bool evolutionApplicable(AdaptPlace place, kc.Proposal p) {
    try {
      final after = ka.applyProposal(place.block, p);
      if (identical(after, place.block)) return false;
      if (kc.jsonDeepEquals(after.toJson(), place.block.toJson())) {
        return false;
      }
      return !place.imported ||
          SessionAdaptStore.importedLayoutKept(place.block, after);
    } catch (_) {
      return false;
    }
  }

  void _evoCommit(List<EvolutionEntry> entries) {
    planEvolution = planEvolution.withEntries(entries);
    _evoRaw = null;
    _evoRevision++;
    _materializeProgram(program.start);
    _allEx = null;
    _muscleIndex = null;
    pilotageEpoch++;
    _persist();
    notifyListeners();
  }

  void _evoSet(EvolutionEntry e, EvolutionEntry next) {
    if (_evoRaw != null) return;
    bool same(EvolutionEntry x) =>
        identical(x, e) || (x.id == e.id && x.blockId == e.blockId);
    // Une proposition qui entre en place passe en dernier : les couches
    // s'appliquent dans l'ordre des décisions.
    final moved = next.inEffect && !e.inEffect;
    _evoCommit([
      for (final x in planEvolution.entries)
        if (!same(x)) x else if (!moved) next,
      if (moved) next,
    ]);
  }

  /// Semaine du bloc [blockId] en cours aujourd'hui (null : autre bloc).
  int? evolutionCurrentWeek(String blockId) {
    final p = evolutionPlace;
    return p != null && p.blockId == blockId ? p.weekIndex : null;
  }

  /// Mode libre : « Accepter ».
  void evolutionAccept(EvolutionEntry e) {
    if (e.status != EvoStatus.pending) return;
    _evoSet(
      e,
      e.copyWith(
        status: EvoStatus.accepted,
        decidedOn: _evoToday.iso,
        mode: SessionAdaptStore(this).adaptMode,
        clearLater: true,
        seen: true,
      ),
    );
  }

  /// Mode libre : « Refuser » ; le moteur ne la repropose pas avant son
  /// délai (28 jours, contrat de kalis_adapt § 4.10).
  void evolutionRefuse(EvolutionEntry e) {
    if (e.status != EvoStatus.pending) return;
    _evoSet(
      e,
      e.copyWith(
        status: EvoStatus.refused,
        decidedOn: _evoToday.iso,
        mode: SessionAdaptStore(this).adaptMode,
        clearLater: true,
        seen: true,
      ),
    );
  }

  /// Mode libre : « Plus tard » (la carte revient le lendemain).
  void evolutionLater(EvolutionEntry e) {
    if (e.status != EvoStatus.pending) return;
    _evoSet(e, e.copyWith(laterUntil: _evoToday.addDays(1).iso));
  }

  /// « Compris » : la carte de l'accueil ne montre plus ce changement
  /// (il reste dans l'historique, annulable tant que c'est permis).
  void evolutionSeen(EvolutionEntry e) {
    if (e.seen) return;
    _evoSet(e, e.copyWith(seen: true));
  }

  /// Une séance du bloc [blockId] a été commencée ou faite à partir de la
  /// semaine [fromWeek] du bloc.
  bool _evoStartedFrom(String blockId, int fromWeek) {
    for (final k in logs.keys) {
      final m = RegExp(r'^S(\d+)-J(\d)$').firstMatch(k);
      if (m == null) continue;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      final l = logs[k]!;
      final started =
          l.done || l.ex.values.any((x) => x.sets.any((s) => s.done));
      if (!started) continue;
      final a = SessionAdaptStore(this).sessionAdaptOf(k);
      if (a != null) {
        if (a.blockId == blockId && a.weekIndex >= fromWeek) return true;
        continue;
      }
      final p = SessionAdaptStore(this).adaptPlaceOf(w, j);
      if (p != null && p.blockId == blockId && p.weekIndex >= fromWeek) {
        return true;
      }
    }
    return false;
  }

  /// « Annuler » possible : changement en place, le dernier de son bloc,
  /// et aucune séance concernée commencée.
  bool evolutionCanUndo(EvolutionEntry e) {
    if (!e.inEffect) return false;
    final list = planEvolution.inEffect(e.blockId);
    if (list.isEmpty || list.last.id != e.id) return false;
    return !_evoStartedFrom(e.blockId, e.fromWeek);
  }

  /// Annule un changement en place (mode assisté ou proposition acceptée).
  bool evolutionUndo(EvolutionEntry e) {
    if (!evolutionCanUndo(e)) return false;
    _evoSet(
      e,
      e.copyWith(
        status: EvoStatus.undone,
        decidedOn: _evoToday.iso,
        mode: SessionAdaptStore(this).adaptMode,
        seen: true,
      ),
    );
    return true;
  }

  /// Propositions en attente (mode libre), hors « Plus tard ».
  List<EvolutionEntry> get evolutionPending {
    final today = _evoToday.iso;
    return [
      for (final e in planEvolution.entries)
        if (e.status == EvoStatus.pending &&
            (e.laterUntil == null || e.laterUntil!.compareTo(today) <= 0))
          e,
    ];
  }

  /// Changements appliqués que Koach annonce encore (pas lus, annulables).
  List<EvolutionEntry> get evolutionAnnounced => [
    for (final e in planEvolution.entries)
      if (e.inEffect && !e.seen && evolutionCanUndo(e)) e,
  ];

  /// Changements qui concernent la séance S[week]·J[j] et commencent cette
  /// semaine-là (carte au début de la séance).
  List<EvolutionEntry> evolutionForSession(int week, int j) {
    final place = SessionAdaptStore(this).adaptPlaceOf(week, j);
    if (place == null) return const [];
    return [
      for (final e in planEvolution.entries)
        if (e.blockId == place.blockId &&
            e.inEffect &&
            e.fromWeek == place.weekIndex &&
            evolutionTouchesDay(e, place.dayIndex))
          e,
    ];
  }

  /// La proposition change la journée [dayIndex] (diff, ou restructuration
  /// sans détail de jour).
  static bool evolutionTouchesDay(EvolutionEntry e, int dayIndex) {
    final changes = e.proposal.diff?.changes ?? const <kc.PlanChange>[];
    if (changes.isEmpty) return e.proposal.block != null;
    return changes.any((c) => c.dayIndex == null || c.dayIndex == dayIndex);
  }

  /// Historique des changements (le plus récent d'abord), hors propositions
  /// en attente.
  List<EvolutionEntry> get evolutionHistory => [
    for (final e in planEvolution.entries.reversed)
      if (e.status != EvoStatus.pending) e,
  ];

  /// Mode assisté ou libre (D3.7, D5.6), modifiable dans Mon programme.
  void setGuidanceMode(String mode) {
    final a = athlete;
    if (a == null || (mode != 'assisted' && mode != 'free')) return;
    final m = mode == 'free' ? kc.GuidanceMode.free : kc.GuidanceMode.assisted;
    if (a.profile.guidanceMode == m) return;
    final at = athleteAt(storeClock());
    athlete = AthleteRecord(
      profile: a.profile.copyWith(guidanceMode: m),
      savedAt: at,
      birthYearAt: a.birthYearAt,
      limitationsAt: a.limitationsAt,
      changes: AthleteProfileStore._withChange(
        a.changes,
        ProfileChange(at, const ['mode'], false),
      ),
    );
    _athleteRaw = null;
    _persist();
    notifyListeners();
  }

  /// Déblocage (D5.7) d'après la dernière revue (sans revue : rien de
  /// débloqué au-delà des charges).
  EvolutionUnlock get evolutionUnlock {
    final r = lastEvolutionReview;
    final s = r?.review.summary;
    final weeks = s?.weeksObserved ?? 0;
    final imported = r?.place.imported ?? false;
    final blocks = r == null
        ? 0
        : (imported ? weeks ~/ 6 : r.place.block.pass1.blockIndex);
    const p = ka.AdaptParams.standard;
    final level = s?.unlockLevel ?? ka.unlockLevelFor(weeks, blocks, p);
    const order = kc.UnlockLevel.values;
    final next = level.index + 1 < order.length ? order[level.index + 1] : null;
    var w = 0, b = 0;
    switch (next) {
      case kc.UnlockLevel.volume:
        w = p.volumeMinWeeks - weeks;
      case kc.UnlockLevel.exerciseSwap:
        w = p.swapMinWeeks - weeks;
      case kc.UnlockLevel.sessionRestructure:
        w = p.sessionRestructureMinWeeks - weeks;
        b = 1 - blocks;
      case kc.UnlockLevel.blockRestructure:
        w = p.blockRestructureMinWeeks - weeks;
        b = 2 - blocks;
      default:
    }
    return EvolutionUnlock(
      level: level,
      weeksObserved: weeks,
      blocksDone: blocks,
      next: next,
      weeksToNext: w < 0 ? 0 : w,
      blocksToNext: b < 0 ? 0 : b,
      confidence: s?.confidence ?? 0,
    );
  }

  /// Journal du moteur exportable (mode dev, D2.5) : entrée et résultat de
  /// la dernière revue, propositions et suites données, temps de calcul.
  Map<String, Object?>? get evolutionJournalJson {
    final r = lastEvolutionReview;
    if (r == null) return null;
    return {
      'kind': 'kalis_adapt_journal',
      'v': 1,
      'engineVersion': kalisAdaptEngine.engineVersion,
      'catalogVersion': content.catalog?.sourceVersion,
      'today': r.input.today.iso,
      'week': r.week,
      'blockId': r.place.blockId,
      'importedBlock': r.place.imported,
      'mode': SessionAdaptStore(this).adaptMode,
      'ms': r.ms,
      'decisions': [for (final d in r.input.decisions ?? const []) d.toJson()],
      'evolution': planEvolution.toJson(),
      'review': r.review.toJson(),
      'sessions': r.input.log.sessions.length,
    };
  }
}
