// L11 (KT-058 à KT-064) — adaptation au jour le jour branchée sur le
// store : séance compressée, échange d'exercice et changement de lieu,
// plan qui glisse, vacances et maladie, reprise après un arrêt, assiduité,
// plateau, modes d'autonomie et charge de séance simplifiée.
// Règles pures : lib/koach_adapt.dart. Contrat : docs/CONTRAT_L11.md.
part of 'store.dart';

/// Proposition affichée à l'accueil (assiduité, plateau, prudence, plan
/// qui glisse).
class AdaptProposal {
  final String id, kind, title, text;

  /// Actions : (identifiant, libellé).
  final List<(String, String)> actions;
  final Map<String, dynamic> data;
  const AdaptProposal(
    this.id,
    this.kind,
    this.title,
    this.text,
    this.actions, [
    this.data = const {},
  ]);
}

/// État d'adaptation d'une séance du programme (bandeau de séance).
class AdaptSessionInfo {
  final String key, mode;
  final ResumeRule? rule;
  final int? episodeStart;
  final bool illness, lighten, shorter, deload;
  final String? choice;

  /// Mouvements principaux concernés par la reprise dans cette séance.
  final Set<String> movements;
  const AdaptSessionInfo({
    required this.key,
    required this.mode,
    this.rule,
    this.episodeStart,
    this.illness = false,
    this.lighten = false,
    this.shorter = false,
    this.deload = false,
    this.choice,
    this.movements = const {},
  });

  /// Adaptation de sécurité (reprise ou maladie) à décider pour la séance.
  bool get safety => (rule != null && movements.isNotEmpty) || illness;

  /// Adaptation de sécurité appliquée (mode Guidé, ou acceptée).
  bool get applied => safety && safetyApplied(mode, choice);
}

extension AdaptStore on AppStore {
  // ------------------------------------------------------------ outils
  int get _adaptToday => dayIndex(storeClock());

  String get _adaptAt => profileAt(storeClock());

  void _adaptSave() {
    _adaptCache.clear();
    _persist();
    notifyListeners();
  }

  void _adaptEvent(String kind, Map<String, dynamic> detail) {
    adapt.events.add(AdaptEvent(_adaptAt, kind, detail));
    if (adapt.events.length > AdaptData.maxEvents) {
      adapt.events.removeRange(0, adapt.events.length - AdaptData.maxEvents);
    }
  }

  /// Valeur mise en cache jusqu'à la prochaine modification des données.
  T _adaptCached<T>(String key, T Function() compute) {
    final rev = '$_dataRevision|$_adaptToday|${identityHashCode(program)}';
    if (_adaptCacheRev != rev) {
      _adaptCache.clear();
      _adaptCacheRev = rev;
    }
    if (_adaptCache.containsKey(key)) return _adaptCache[key] as T;
    // Pas de putIfAbsent : un calcul peut lui-même lire le cache.
    final value = compute();
    _adaptCache[key] = value;
    return value;
  }

  /// Journée du programme, sans lever d'erreur.
  DayPlan? _adaptDayPlan(int week, int j) {
    for (final w in program.weeks) {
      if (w.n == week) return w.day(j);
    }
    return null;
  }

  List<int> _adaptDays(UserProfile p) => [
    for (final x in (p.value('days') as List? ?? const [])) (x as num).toInt(),
  ];

  static final RegExp _programKey = RegExp(r'^S([1-9]\d*)-J([1-7])$');

  // ---------------------------------------------------- autonomie (KT-063)

  /// Mode d'autonomie effectif. Un profil migré dont le mode n'a jamais été
  /// choisi garde le fonctionnement de Koach en 3.x (Assisté).
  String get autonomyMode {
    final p = profile;
    if (p != null) {
      final f = p.fields['autonomy'];
      if (f != null &&
          kAutonomyModes.contains(f.value) &&
          !(p.origin == 'migration' && f.source == 'estimated')) {
        return f.value as String;
      }
    }
    return adapt.autonomy ?? 'assisted';
  }

  /// Changement de mode à tout moment (profil s'il existe).
  void setAutonomyMode(String mode) {
    if (!kAutonomyModes.contains(mode) || mode == autonomyMode) return;
    final before = autonomyMode;
    final p = profile;
    if (p != null) {
      final next = p.copy();
      next.setField('autonomy', mode, profileAt(storeClock()));
      ProfileStore(this).saveProfile(next);
    } else {
      adapt.autonomy = mode;
    }
    _adaptEvent('mode', {'from': before, 'to': mode});
    _adaptSave();
  }

  /// Niveau global (0 débutant … 4 expert) : génération L10, sinon repère
  /// du profil, sinon intermédiaire.
  int get adaptLevel {
    final g = (programSummary['levels'] as Map?)?['global'];
    if (g is int) return g.clamp(0, 4);
    final l = profile?.level;
    final i = l == null ? -1 : kLevels.indexOf(l);
    return i < 0 ? 2 : i;
  }

  // ------------------------------------------------- dates et journal

  /// Jour civil d'une séance : fin enregistrée, sinon première série
  /// validée, sinon aujourd'hui.
  int adaptSessionDay(String key) {
    final l = logs[key];
    final f = DateTime.tryParse(l?.finishedAt ?? '');
    if (l != null && l.done && f != null) return dayIndex(f);
    int? first;
    for (final e in l?.ex.values ?? const <ExerciseLog>[]) {
      for (final s in e.sets) {
        final t = DateTime.tryParse(s.completedAt ?? '');
        if (s.done && t != null) {
          final d = dayIndex(t);
          if (first == null || d < first) first = d;
        }
      }
    }
    return first ?? (f != null ? dayIndex(f) : _adaptToday);
  }

  /// Jours d'entraînement (séances terminées et séries validées), hors la
  /// séance [exclude].
  List<int> adaptTrainingDays({String? exclude}) =>
      _adaptCached('days|$exclude', () {
        final out = <int>{};
        for (final e in logs.entries) {
          if (e.key == exclude) continue;
          final f = DateTime.tryParse(e.value.finishedAt ?? '');
          if (e.value.done && f != null) out.add(dayIndex(f));
          for (final x in e.value.ex.values) {
            for (final s in x.sets) {
              final t = DateTime.tryParse(s.completedAt ?? '');
              if (s.done && t != null) out.add(dayIndex(t));
            }
          }
        }
        return out.toList()..sort();
      });

  Map<String, Exercise> get _adaptProgramIndex => _adaptCached(
    'index',
    () => {
      for (final w in program.weeks)
        for (final d in w.days)
          for (final e in d.exercises) e.id: e,
    },
  );

  /// Mouvement principal suivi par la reprise et le plateau : mouvement
  /// Koach (lest, squat), sinon nom court de l'exercice principal.
  String? adaptMovement(Exercise e) {
    if (!e.main) return null;
    final base = e.id.split('~').first;
    final m = koachProgram.of(base)?.movement;
    return m ?? splitName(e.name).$1.toLowerCase();
  }

  /// Mouvement → jours où il a été travaillé (séries validées), hors la
  /// séance [exclude].
  Map<String, List<int>> adaptMovementDays({String? exclude}) =>
      _adaptCached('moves|$exclude', () {
        final index = _adaptProgramIndex;
        final out = <String, Set<int>>{};
        for (final e in logs.entries) {
          if (e.key == exclude) continue;
          for (final x in e.value.ex.entries) {
            final ex = index[x.key.split('~').first];
            final m = ex == null ? null : adaptMovement(ex);
            if (m == null) continue;
            for (final s in x.value.sets) {
              final t = DateTime.tryParse(s.completedAt ?? '');
              if (s.done && t != null) {
                (out[m] ??= <int>{}).add(dayIndex(t));
              }
            }
          }
        }
        return {for (final e in out.entries) e.key: (e.value.toList()..sort())};
      });

  /// Jours de retour d'une maladie (premier jour après la pause).
  List<int> get _illnessReturns => [
    for (final p in adapt.pauses)
      if (p.kind == 'illness' && p.to != null) dayIndex(DateTime.parse(p.to!)),
  ];

  /// Jours en pause (terminées et en cours).
  Set<int> get _pausedDays {
    final out = <int>{};
    for (final p in [...adapt.pauses, if (adapt.pause != null) adapt.pause!]) {
      final a = dayIndex(DateTime.parse(p.from));
      final b =
          p.to == null ? _adaptToday + 1 : dayIndex(DateTime.parse(p.to!));
      for (var d = a; d < b && d - a < 400; d++) {
        out.add(d);
      }
    }
    return out;
  }

  bool _inLighten(int day) {
    final a = adapt.lightenFrom, b = adapt.lightenTo;
    if (a == null || b == null) return false;
    return day >= dayIndex(DateTime.parse(a)) &&
        day <= dayIndex(DateTime.parse(b));
  }

  /// Semaine de décharge décidée après un plateau (KT-062).
  bool adaptDeloadWeek(int week) => adapt.events.any(
    (e) =>
        e.kind == 'plateau' &&
        e.status == 'applied' &&
        e.detail['deloadWeek'] == week,
  );

  // ---------------------------------------- état d'une séance (KT-060)

  AdaptSessionInfo adaptInfo(int week, int j) {
    final key = sessionKey(week, j);
    return _adaptCached('info|$key', () {
      final mode = autonomyMode;
      if (week < 1) return AdaptSessionInfo(key: key, mode: mode);
      final day = adaptSessionDay(key);
      final choice = adapt.sessions[key]?['resume'] as String?;
      final ep = resumeEpisode(adaptTrainingDays(exclude: key), day);
      ResumeRule? rule;
      final moves = <String>{};
      if (ep != null) {
        rule = resumeRule(ep.$2);
        final d = _adaptDayPlan(week, j);
        final byMove = adaptMovementDays(exclude: key);
        for (final e in d?.exercises ?? const <Exercise>[]) {
          final m = adaptMovement(e);
          if (m == null) continue;
          if (resumeAppliesTo(rule, ep.$1, day, byMove[m] ?? const [])) {
            moves.add(m);
          }
        }
        if (moves.isEmpty) rule = null;
      }
      return AdaptSessionInfo(
        key: key,
        mode: mode,
        rule: rule,
        episodeStart: ep?.$1,
        illness: illnessRecovery(_illnessReturns, day),
        lighten: _inLighten(day),
        shorter:
            adapt.shorter != null &&
            !(logs[key]?.done ?? false) &&
            adapt.sessions[key]?['minutes'] == null,
        deload: adaptDeloadWeek(week),
        choice: choice,
        movements: moves,
      );
    });
  }

  /// Choix pour l'adaptation de sécurité d'une séance (`applied`,
  /// `refused`) ; charges et séries non validées recalculées.
  void setAdaptSafety(int week, DayPlan base, String choice) {
    final key = sessionKey(week, base.j);
    _adaptResync(week, base, () {
      (adapt.sessions[key] ??= {})['resume'] = choice;
      _adaptEvent('safety', {'session': key, 'choice': choice});
    });
  }

  /// Facteur de charge d'un exercice pour une séance (reprise, décharge).
  double adaptLoadFactor(int week, int j, Exercise e) {
    if (week < 1 || !e.main) return 1;
    final info = adaptInfo(week, j);
    var f = 1.0;
    final m = adaptMovement(e);
    if (info.applied &&
        info.rule != null &&
        m != null &&
        info.movements.contains(m)) {
      f *= 1 - info.rule!.loadCut;
    }
    if (info.deload) f *= 0.9;
    return f;
  }

  /// Nombre de séries adapté (hors compression explicite) : reprise (−1
  /// série), maladie (× 0,7), semaine allégée (× 0,8), décharge (× 0,6) ;
  /// la réduction la plus forte s'applique, jamais sous 1 série.
  int adaptSetTarget(int week, int j, Exercise e, int n) {
    if (week < 1 || n <= 1) return n;
    final info = adaptInfo(week, j);
    var out = n;
    final m = adaptMovement(e);
    if (info.applied) {
      if (info.rule != null && m != null && info.movements.contains(m)) {
        out = math.min(out, n - info.rule!.setCut);
      }
      if (info.illness) out = math.min(out, (n * kIllnessVolume).round());
    }
    if (info.lighten && !e.prevention) {
      out = math.min(out, (n * kLightenVolume).round());
    }
    if (info.deload && e.main) out = math.min(out, (n * 0.6).round());
    return math.max(1, out);
  }

  // --------------------------------------------- séance adaptée (KT-058)

  /// Rôle d'un exercice pour la compression.
  String _cRole(Exercise e) {
    if (e.prevention) return 'prevention';
    switch (e.role) {
      case 'warmup' || 'mobility' || 'ramp':
        return 'warmup';
      case 'cooldown':
        return 'cooldown';
      case 'circuit' || 'specific':
        return 'low';
      case 'calibration' || 'test':
        return 'test';
      case 'main':
        return 'main';
      case 'accessory':
        return 'accessory';
    }
    return e.main ? 'main' : 'accessory';
  }

  /// Exercice de substitution enregistré pour une séance.
  Exercise _swapped(Exercise e, Map<String, dynamic> s) {
    final to = s['to'] as String;
    final kg = (s['kg'] as num?)?.toDouble();
    final motive = s['motive'] as String? ?? 'wish';
    final label = switch (motive) {
      'pain' => 'gêne',
      'busy' => 'matériel pris',
      'place' => 'autre lieu',
      _ => 'envie de changer',
    };
    return Exercise.adapted(
      e,
      id: '${e.id}~$to',
      name: s['name'] as String,
      load: LoadSpec.fixed(kg),
      cue:
          'Série 1 = calibrage : charge prudente, garde le RIR visé '
          '(${e.intensity.isEmpty ? 'répétitions en réserve' : e.intensity}) '
          'et ajuste ensuite.',
      why: 'Remplace « ${splitName(e.name).$1} » ($label).',
      exId: to,
    );
  }

  /// Séance du programme telle qu'elle sera faite : échanges, séries
  /// adaptées (compression, reprise, maladie, allègement, décharge),
  /// exercices retirés, accessoires enchaînés. Identique à [base] sans
  /// adaptation.
  DayPlan sessionDay(int week, DayPlan base) {
    if (week < 1 || base.exercises.isEmpty) return base;
    final key = sessionKey(week, base.j);
    return _adaptCached('day|$key|${identityHashCode(base)}', () {
      final o = adapt.sessions[key];
      final plan = _adaptPlan(week, base.j);
      final removed = <String>{...?(plan?['removed'] as List?)?.cast<String>()};
      final sets = (plan?['sets'] as Map?)?.cast<String, int>() ?? const {};
      final swaps = (o?['swaps'] as Map?)?.cast<String, dynamic>() ?? const {};
      final out = <Exercise>[];
      var changed = false;
      for (final e in base.exercises) {
        if (removed.contains(e.id)) {
          changed = true;
          continue;
        }
        var x = e;
        final s = swaps[e.id];
        if (s is Map) {
          x = _swapped(e, s.cast<String, dynamic>());
          changed = true;
        }
        final n0 = setCount(e);
        final n = sets[e.id] ?? adaptSetTarget(week, base.j, e, n0);
        if (n != n0 && reducibleText(setsLabel(e))) {
          final spec = x.sets.withCount(n);
          if (spec != null) {
            x = Exercise.adapted(x, sets: spec);
            changed = true;
          }
        }
        out.add(x);
      }
      // Accessoires enchaînés : le second suit le premier.
      final pairs = [
        for (final p in (plan?['pairs'] as List?) ?? const [])
          ((p as List)[0] as String, p[1] as String),
      ];
      for (final p in pairs) {
        final a = out.indexWhere((e) => e.id.split('~').first == p.$1);
        final b = out.indexWhere((e) => e.id.split('~').first == p.$2);
        if (a < 0 || b < 0 || b == a + 1) continue;
        final moved = out.removeAt(b);
        out.insert(
          out.indexWhere((e) => e.id.split('~').first == p.$1) + 1,
          moved,
        );
        changed = true;
      }
      return changed ? DayPlan.adapted(base, out) : base;
    });
  }

  /// Groupes de pages de la séance adaptée : paires de la compression,
  /// sinon la règle des exercices enchaînés.
  List<List<Exercise>> sessionGroups(int week, DayPlan day) {
    if (week < 1) return groups(day);
    final plan = _adaptPlan(week, day.j);
    final pairs = <String, String>{
      for (final p in (plan?['pairs'] as List?) ?? const [])
        (p as List)[0] as String: p[1] as String,
    };
    if (pairs.isEmpty) return groups(day);
    final out = <List<Exercise>>[];
    final ex = day.exercises;
    var i = 0;
    while (i < ex.length) {
      final e = ex[i];
      final partner = pairs[e.id.split('~').first];
      if (i + 1 < ex.length &&
          (ex[i + 1].name.toLowerCase().contains('enchaîn') ||
              (partner != null && ex[i + 1].id.split('~').first == partner))) {
        out.add([e, ex[i + 1]]);
        i += 2;
      } else {
        out.add([e]);
        i += 1;
      }
    }
    return out;
  }

  /// Compression en vigueur : choisie pour la séance, sinon « séances 20 %
  /// plus courtes ».
  Map<String, dynamic>? _adaptPlan(int week, int j) {
    final o = adapt.sessions[sessionKey(week, j)];
    if (o?['minutes'] != null) return o;
    if (adaptInfo(week, j).shorter) {
      final base = _adaptDayPlan(week, j);
      return base == null ? null : _shorterPlan(week, base);
    }
    // L12 (KT-071) : parcours d'habitude des débutants, séances ramenées à
    // 20 minutes (ou moins selon les disponibilités) les 4 premières
    // semaines ; désactivable dans Motivation et progression.
    final habit = MotivStore(this).motivHabitMinutesFor(week, j);
    if (habit == null) return null;
    final base = _adaptDayPlan(week, j);
    return base == null ? null : _minutesPlan(week, base, habit);
  }

  /// Compression automatique à [minutes] (parcours d'habitude).
  Map<String, dynamic>? _minutesPlan(int week, DayPlan base, int minutes) {
    final key = sessionKey(week, base.j);
    return _adaptCached('habit|$key|$minutes', () {
      final plan = compressSession(
        _cItems(week, base),
        minutes,
        started: _adaptStarted(key),
      );
      return plan.unchanged ? null : plan.toJson();
    });
  }

  /// Éléments de compression d'une séance (séries validées comprises).
  List<CItem> _cItems(int week, DayPlan base) {
    final key = sessionKey(week, base.j);
    final swaps =
        (adapt.sessions[key]?['swaps'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final out = <CItem>[];
    for (final e0 in base.exercises) {
      final s = swaps[e0.id];
      final e = s is Map ? _swapped(e0, s.cast<String, dynamic>()) : e0;
      final n0 = setCount(e0);
      final n = adaptSetTarget(week, base.j, e0, n0);
      final spec = n != n0 ? e.sets.withCount(n) : null;
      final x = spec == null ? e : Exercise.adapted(e, sets: spec);
      final est = exerciseEstimate(x);
      final count = setCount(x);
      final k = est.sets > 0 ? est.sets : count.toDouble();
      final log = logs[key]?.ex[x.id];
      out.add(
        CItem(
          id: e0.id,
          role: _cRole(e0),
          sets: count,
          done: log?.sets.where((s) => s.done).length ?? 0,
          work: k > 0 ? est.work.midpoint / k : 0,
          rest: k > 0 ? est.rest.midpoint / k : 0,
          reducible: reducibleText(setsLabel(e0)),
          groups: groupsFor(e0.name).toSet(),
        ),
      );
    }
    return out;
  }

  bool _adaptStarted(String key) =>
      logs[key]?.ex.values.any((l) => l.sets.any((s) => s.done)) ?? false;

  /// Aperçu d'une compression (rien n'est modifié).
  CPlan adaptCompressPreview(int week, DayPlan base, int minutes) =>
      compressSession(
        _cItems(week, base),
        minutes,
        started: _adaptStarted(sessionKey(week, base.j)),
      );

  /// Séances 20 % plus courtes (assiduité) : compression automatique.
  Map<String, dynamic>? _shorterPlan(int week, DayPlan base) {
    final key = sessionKey(week, base.j);
    return _adaptCached('short|$key', () {
      final items = _cItems(week, base);
      final full = compressSession(items, 100000);
      final minutes = math.max(10, (full.before * kShorterFactor / 60).floor());
      final plan = compressSession(items, minutes, started: _adaptStarted(key));
      return plan.unchanged ? null : plan.toJson();
    });
  }

  /// Applique une compression (séries non validées retirées, exercices non
  /// commencés retirés du journal de la séance).
  void applyCompression(int week, DayPlan base, CPlan plan) {
    if (plan.unchanged) return;
    final key = sessionKey(week, base.j);
    _adaptResync(week, base, () {
      final o = adapt.sessions[key] ??= {};
      o
        ..remove('sets')
        ..remove('removed')
        ..remove('pairs')
        ..remove('warmup')
        ..addAll(plan.toJson())
        ..['at'] = _adaptAt;
      _adaptEvent('compress', {
        'session': key,
        'minutes': plan.minutes,
        'removed': plan.removed.length,
      });
    });
  }

  /// Annule la compression de la séance (séries rétablies).
  void clearCompression(int week, DayPlan base) {
    final key = sessionKey(week, base.j);
    final o = adapt.sessions[key];
    if (o == null || !o.containsKey('minutes')) return;
    _adaptResync(week, base, grow: true, () {
      for (final k in const ['minutes', 'sets', 'removed', 'pairs', 'warmup']) {
        o.remove(k);
      }
      if (o.isEmpty || (o.length == 1 && o.containsKey('at'))) {
        adapt.sessions.remove(key);
      }
      _adaptEvent('uncompress', {'session': key});
    });
  }

  /// Compression enregistrée pour la séance (minutes), sinon null.
  int? adaptCompressed(int week, int j) =>
      adapt.sessions[sessionKey(week, j)]?['minutes'] as int?;

  /// Modifie une adaptation et recale les séries non validées déjà créées :
  /// nombre de lignes (trop nombreuses retirées ; rétablies avec [grow]),
  /// charges pré-remplies égales à l'ancienne suggestion, journaux vides des
  /// exercices retirés ou échangés.
  void _adaptResync(
    int week,
    DayPlan base,
    void Function() change, {
    bool grow = false,
  }) {
    final key = sessionKey(week, base.j);
    final before = sessionDay(week, base);
    final oldKg = <String, String>{
      for (final e in before.exercises)
        if (sessionLoad(week, e, day: base.j) case final double kg)
          e.id: kgFieldText(kg),
    };
    change();
    _adaptCache.clear();
    final after = sessionDay(week, base);
    final session = logs[key];
    if (session != null) {
      final ids = {for (final e in after.exercises) e.id};
      session.ex.removeWhere(
        (id, l) => !ids.contains(id) && !l.sets.any((s) => s.done),
      );
      for (final e in after.exercises) {
        final log = session.ex[e.id];
        if (log == null) continue;
        final target =
            KoachStore(this).koachOn && week >= 1
                ? KoachStore(this).koachSetCount(week, e)
                : setCount(e);
        while (log.sets.length > target &&
            log.sets.length > 1 &&
            !log.sets.last.done) {
          log.sets.removeLast();
        }
        if (grow) {
          while (log.sets.length < target) {
            log.sets.add(SetEntry());
          }
        }
        final kg = sessionLoad(week, e, day: base.j);
        final old = oldKg[e.id];
        if (kg != null && old != null) {
          final text = kgFieldText(kg);
          for (final s in log.sets) {
            if (!s.done && s.kg == old) s.kg = text;
          }
        }
      }
    }
    _adaptSave();
    saveLogs(immediate: true);
  }

  // ------------------------------------------ échange d'exercice (KT-059)

  Future<GenCatalog> adaptCatalog() async =>
      (ProgramAssets.loaded ?? await ProgramAssets.load()).catalog;

  /// Exercice du pack correspondant à un exercice de séance.
  GenExercise? adaptPackOf(Exercise e, GenCatalog c) {
    final id = e.exId ?? content.idFor(e.name);
    return (id == null ? null : c.byId[id]) ??
        c.byId[c.idForName(splitName(e.name).$1) ?? ''];
  }

  /// Lieux connus (profil) : identifiant → matériel.
  Map<String, List<String>> get adaptPlaces {
    final raw = profile?.value('places');
    if (raw is Map && raw.isNotEmpty) {
      return {
        for (final e in raw.entries)
          '${e.key}': [for (final x in (e.value as List? ?? const [])) '$x'],
      };
    }
    return {for (final e in kPlaceDefaults.entries) e.key: e.value};
  }

  /// Matériel du pack disponible : lieu choisi, sinon tous les lieux du
  /// profil.
  Set<String> adaptEquipment({String? place}) {
    final places = adaptPlaces;
    if (place != null) return packEquipment(place, places[place] ?? const []);
    final out = <String>{};
    for (final e in places.entries) {
      out.addAll(packEquipment(e.key, e.value));
    }
    return out;
  }

  Set<String> adaptDisliked(GenCatalog c) => {
    for (final n in profile?.listValue('disliked') ?? const <String>[])
      if (c.idForName(n) case final String id) id,
  };

  /// Trois propositions classées pour remplacer [e] (KT-059).
  List<GenExercise> adaptSwapCandidates(
    GenCatalog c,
    Exercise e, {
    required String motive,
    String? place,
  }) {
    final pack = adaptPackOf(e, c);
    if (pack == null) return const [];
    final key = e.id.split('~').first;
    return swapCandidates(
      c,
      pack,
      equipment: adaptEquipment(place: place),
      motive: motive,
      disliked: adaptDisliked(c),
      exclude: {if (key != e.id) e.id.split('~').last},
    );
  }

  /// Remplace un exercice de la séance (avant sa première série).
  void applySwap(
    int week,
    DayPlan base,
    Exercise original,
    GenExercise to,
    String motive,
    GenCatalog c,
  ) {
    final key = sessionKey(week, base.j);
    final pack = adaptPackOf(original, c);
    final kg = prudentLoad(
      sessionLoad(week, original, day: base.j),
      pack?.loadMode ?? 'poids_de_corps',
      to.loadMode,
    );
    _adaptResync(week, base, () {
      final o = adapt.sessions[key] ??= {};
      final swaps = (o['swaps'] as Map?)?.cast<String, dynamic>() ?? {};
      swaps[original.id.split('~').first] = {
        'to': to.id,
        'name': to.name,
        'motive': motive,
        if (kg != null) 'kg': kg,
      };
      o['swaps'] = swaps;
      _adaptEvent('swap', {
        'session': key,
        'from': original.id.split('~').first,
        'to': to.id,
        'motive': motive,
      });
    });
  }

  /// Rétablit l'exercice d'origine.
  void revertSwap(int week, DayPlan base, String originalId) {
    final key = sessionKey(week, base.j);
    final o = adapt.sessions[key];
    final swaps = (o?['swaps'] as Map?)?.cast<String, dynamic>();
    if (o == null || swaps == null || !swaps.containsKey(originalId)) return;
    _adaptResync(week, base, grow: true, () {
      swaps.remove(originalId);
      if (swaps.isEmpty) o.remove('swaps');
      if (o.isEmpty) adapt.sessions.remove(key);
      _adaptEvent('unswap', {'session': key, 'from': originalId});
    });
  }

  /// Variante de toute la séance pour un autre lieu : exercice → substitut
  /// (null : rien d'équivalent avec ce matériel ; absent : gardé tel quel).
  Map<String, GenExercise?> adaptPlacePreview(
    int week,
    DayPlan base,
    String place,
    GenCatalog c,
  ) {
    final eq = adaptEquipment(place: place);
    final out = <String, GenExercise?>{};
    final used = <String>{};
    for (final e in base.exercises) {
      final pack = adaptPackOf(e, c);
      if (pack == null || pack.materiel.every(eq.contains)) continue;
      final cand = swapCandidates(
        c,
        pack,
        equipment: eq,
        motive: 'wish',
        disliked: adaptDisliked(c),
        exclude: used,
        count: 1,
      );
      out[e.id] = cand.isEmpty ? null : cand.first;
      if (cand.isNotEmpty) used.add(cand.first.id);
    }
    return out;
  }

  void applyPlace(
    int week,
    DayPlan base,
    String place,
    Map<String, GenExercise?> preview,
    GenCatalog c,
  ) {
    final key = sessionKey(week, base.j);
    _adaptResync(week, base, () {
      final o = adapt.sessions[key] ??= {};
      final swaps = (o['swaps'] as Map?)?.cast<String, dynamic>() ?? {};
      for (final e in base.exercises) {
        final to = preview[e.id];
        if (to == null) continue;
        if (logs[key]?.ex[e.id]?.sets.any((s) => s.done) ?? false) continue;
        final pack = adaptPackOf(e, c);
        final kg = prudentLoad(
          sessionLoad(week, e, day: base.j),
          pack?.loadMode ?? 'poids_de_corps',
          to.loadMode,
        );
        swaps[e.id] = {
          'to': to.id,
          'name': to.name,
          'motive': 'place',
          if (kg != null) 'kg': kg,
        };
      }
      if (swaps.isNotEmpty) o['swaps'] = swaps;
      o['place'] = place;
      _adaptEvent('place', {'session': key, 'place': place});
    });
  }

  // ------------------------------- plan qui glisse, pauses (KT-060)

  /// Ordre d'une journée du programme (S·J).
  int _order(int week, int j) => (week - 1) * 7 + j - 1;

  /// Le plan glisse : (clé de la prochaine journée, jours de retard).
  (String, int)? get adaptSlide {
    final start = program.start;
    if (start == null || adapt.pause != null) return null;
    final today = _adaptToday;
    final planned = <(int, int)>[];
    final done = <int>{};
    for (final w in program.weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        final o = _order(w.n, d.j);
        planned.add((o, dayIndex(program.dateFor(w.n, d.j))));
        final l = logs[sessionKey(w.n, d.j)];
        if (l != null &&
            (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done)))) {
          done.add(o);
        }
      }
    }
    // Rien n'a encore été fait : le départ choisi reste la référence.
    if (done.isEmpty) return null;
    final p = slideProposal(planned, done, today);
    if (p == null) return null;
    final week = p.$1 ~/ 7 + 1, j = p.$1 % 7 + 1;
    return (sessionKey(week, j), p.$2);
  }

  /// Décale le départ de [days] jours (réversible) : la prochaine séance
  /// tombe aujourd'hui, aucune séance n'est doublée.
  void applySlide(int days, {String reason = 'slide'}) {
    final start = program.start;
    if (start == null || days <= 0) return;
    final next = DateTime(start.year, start.month, start.day + days);
    program.start = next;
    startOrigin = 'user';
    pilotageEpoch++;
    _adaptEvent('slide', {
      'days': days,
      'from': dayString(start),
      'to': dayString(next),
      'reason': reason,
    });
    _adaptSave();
  }

  /// Annule un glissement (si le départ n'a pas changé depuis).
  bool undoSlide(AdaptEvent e) {
    if (e.kind != 'slide' || e.status != 'applied') return false;
    final start = program.start;
    if (start == null || dayString(start) != e.detail['to']) return false;
    program.start = DateTime.parse(e.detail['from'] as String);
    pilotageEpoch++;
    e.status = 'undone';
    _adaptSave();
    return true;
  }

  void startPause(String kind) {
    if (adapt.pause != null || (kind != 'vacation' && kind != 'illness')) {
      return;
    }
    adapt.pause = AdaptPause(kind, dayString(storeClock()));
    _adaptEvent('pause', {'kind': kind});
    _adaptSave();
  }

  /// Fin de pause : le plan glisse jusqu'à aujourd'hui (aucune séance
  /// doublée) ; après une maladie, première semaine allégée.
  void endPause() {
    final p = adapt.pause;
    if (p == null) return;
    final today = dayString(storeClock());
    adapt.pause = null;
    adapt.pauses.add(AdaptPause(p.kind, p.from, today));
    if (adapt.pauses.length > AdaptData.maxEvents) adapt.pauses.removeAt(0);
    _adaptEvent('resume', {'kind': p.kind, 'from': p.from, 'to': today});
    final slide = adaptSlide;
    if (slide != null) {
      applySlide(slide.$2, reason: 'pause');
    } else {
      _adaptSave();
    }
  }

  /// Séance d'entretien de vacances (2 × 20 min, sans matériel) ajoutée aux
  /// séances perso. Renvoie son nom.
  String addMaintenanceSession(GenCatalog c) {
    const name = 'Entretien vacances (20 min, sans matériel)';
    final existing = customSessions.where((s) => s.name == name);
    if (existing.isNotEmpty) return name;
    final items = <CustomExercise>[
      for (final e in maintenanceExercises(c, adaptLevel))
        e.measure == 'temps'
            ? CustomExercise(
              name: e.name,
              mode: 'iso',
              p: {'series': 3, 'hold': 30},
              rest: 45,
            )
            : CustomExercise(
              name: e.name,
              mode: 'classic',
              p: {'series': 3, 'reps': adaptLevel <= 1 ? 8 : 12},
              rest: 45,
            ),
    ];
    upsertSession(CustomSession(id: newSessionId(), name: name, items: items));
    return name;
  }

  // ------------------------------------------------ assiduité (KT-061)

  List<(int, bool)> _adaptPlanned() {
    final start = program.start;
    if (start == null) return const [];
    final today = _adaptToday;
    final out = <(int, bool)>[];
    for (final w in program.weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        final day = dayIndex(program.dateFor(w.n, d.j));
        if (day >= today || day < today - 70) continue;
        final l = logs[sessionKey(w.n, d.j)];
        out.add((
          day,
          l != null &&
              (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done))),
        ));
      }
    }
    return out;
  }

  /// Taux de séances faites sur 4 semaines glissantes (null : données
  /// insuffisantes).
  double? adaptAdherence({int offset = 0}) => _adaptCached(
    'adh|$offset',
    () => adherenceRate(
      _adaptPlanned(),
      _adaptToday,
      paused: _pausedDays,
      offset: offset,
    ),
  );

  // ------------------------------------------------- plateau (KT-062)

  /// Estimations hebdomadaires (semaine du programme) par mouvement
  /// principal : meilleure série de la semaine (repère d'entraînement).
  Map<String, Map<int, double>> adaptWeeklyEstimates() =>
      _adaptCached('weekly', () {
        final index = _adaptProgramIndex;
        final bw = ProfileStore(this).currentBodyweight;
        final out = <String, Map<int, double>>{};
        for (final l in logs.entries) {
          final m = _programKey.firstMatch(l.key);
          if (m == null) continue;
          final week = int.parse(m.group(1)!);
          for (final x in l.value.ex.entries) {
            if (x.key.contains('~')) continue;
            final e = index[x.key];
            final mv = e == null ? null : adaptMovement(e);
            if (e == null || mv == null) continue;
            for (final s in x.value.sets) {
              if (!s.done || s.excluded) continue;
              final reps = int.tryParse(s.reps.trim());
              if (reps == null || reps <= 0) continue;
              final kg = double.tryParse(s.kg.replaceAll(',', '.'));
              final rir =
                  (s.effort ?? double.tryParse(s.rir.replaceAll(',', '.')) ?? 0)
                      .clamp(0, 5)
                      .toDouble();
              final double? mass = switch (e.load.type) {
                'system' => bw == null ? null : bw + (kg ?? 0),
                _ => (kg ?? 0) > 0 ? kg : null,
              };
              final v = setEstimate(mass, reps, rir);
              final w = out[mv] ??= {};
              if (v > (w[week] ?? 0)) w[week] = v;
            }
          }
        }
        return out;
      });

  bool _adaptFatigue(int fromWeek, int toWeek) {
    for (final d in koach.decisions) {
      if (d.kind != 'fatigue') continue;
      final m = _programKey.firstMatch('${d.detail['session']}');
      if (m == null) continue;
      final w = int.parse(m.group(1)!);
      if (w >= fromWeek && w <= toWeek) return true;
    }
    var hard = 0;
    for (final e in adapt.difficulty.entries) {
      final m = _programKey.firstMatch(e.key);
      if (m == null) continue;
      final w = int.parse(m.group(1)!);
      if (w >= fromWeek && w <= toWeek && (e.value['rpe'] ?? 0) >= 9) hard++;
    }
    return hard >= 2;
  }

  /// Mouvements en plateau cette semaine (KT-062).
  List<String> get adaptPlateaus {
    if (program.start == null) return const [];
    final current = program.weekFor(storeClock());
    return _adaptCached('plateau|$current', () {
      final adherence = adaptAdherence();
      final fatigue = _adaptFatigue(current - 3, current);
      var deload = false;
      for (var w = current - 3; w <= current; w++) {
        if (koachProgram.isDeload(w) || adaptDeloadWeek(w)) deload = true;
      }
      final out = <String>[];
      for (final e in adaptWeeklyEstimates().entries) {
        if (plateauDetected(
          e.value,
          current,
          adherence: adherence,
          fatigue: fatigue,
          deload: deload,
        )) {
          out.add(e.key);
        }
      }
      out.sort();
      return out;
    });
  }

  /// Progression récente (pour « une séance de plus ») : une estimation en
  /// hausse sur les 8 dernières semaines.
  bool get _adaptProgressed {
    final current = program.weekFor(storeClock());
    for (final w in adaptWeeklyEstimates().values) {
      final pts = [
        for (var k = current - 7; k <= current; k++)
          if (w[k] != null) (k.toDouble(), w[k]!),
      ];
      final s = relativeSlope(pts);
      if (s != null && s > 0) return true;
    }
    return false;
  }

  // ------------------------------- charge de séance simplifiée (KT-064)

  /// Profil concerné par la question de difficulté globale : débutant ou
  /// novice, en mode Guidé ou Assisté.
  bool get adaptSimplified => adaptLevel <= 1 && autonomyMode != 'expert';

  /// La question de fin de séance est à poser.
  bool adaptAsksDifficulty(String key) =>
      adaptSimplified &&
      (logs[key]?.done ?? false) &&
      !adapt.difficulty.containsKey(key);

  /// Durée d'une séance en minutes : fin − première série, sinon
  /// estimation.
  int _adaptMinutes(String key) {
    final l = logs[key];
    final end = DateTime.tryParse(l?.finishedAt ?? '');
    DateTime? first;
    for (final e in l?.ex.values ?? const <ExerciseLog>[]) {
      for (final s in e.sets) {
        final t = DateTime.tryParse(s.completedAt ?? '');
        if (s.done && t != null && (first == null || t.isBefore(first))) {
          first = t;
        }
      }
    }
    if (end != null && first != null) {
      final m = end.difference(first).inMinutes;
      if (m >= 5 && m <= 300) return m;
    }
    final match = _programKey.firstMatch(key);
    if (match != null) {
      final w = int.parse(match.group(1)!), j = int.parse(match.group(2)!);
      final d = _adaptDayPlan(w, j);
      if (d != null && d.exercises.isNotEmpty) {
        final m = (dayEstimate(sessionDay(w, d)).elapsed.midpoint / 60).round();
        if (m >= 1) return math.min(m, 600);
      }
    }
    return 45;
  }

  void setSessionDifficulty(String key, int rpe) {
    if (rpe < 0 || rpe > 10) return;
    adapt.difficulty[key] = {'rpe': rpe, 'minutes': _adaptMinutes(key)};
    _adaptSave();
  }

  /// Charges hebdomadaires (semaine civile) des séances notées.
  Map<int, double> adaptWeeklyLoads() => _adaptCached('loads', () {
    final out = <int, double>{};
    for (final e in adapt.difficulty.entries) {
      final day = adaptSessionDay(e.key);
      final w = weekIndexOfDay(day);
      out[w] =
          (out[w] ?? 0) + sessionLoadOf(e.value['rpe']!, e.value['minutes']!);
    }
    return out;
  });

  /// Prudence de la semaine en cours : (ratio, moyenne), sinon null.
  (double, double)? get adaptLoadCaution =>
      loadCaution(adaptWeeklyLoads(), weekIndexOfDay(_adaptToday));

  /// Allège la fin de la semaine civile (séries × 0,8).
  void applyLighten() {
    final today = _adaptToday;
    final end = (weekIndexOfDay(today) + 1) * 7 - 3 - 1;
    adapt
      ..lightenFrom = dayString(dayOfIndex(today))
      ..lightenTo = dayString(dayOfIndex(end));
    _adaptEvent('lighten', {'from': adapt.lightenFrom, 'to': adapt.lightenTo});
    _adaptSave();
  }

  void clearLighten() {
    if (adapt.lightenFrom == null) return;
    adapt
      ..lightenFrom = null
      ..lightenTo = null;
    _adaptEvent('unlighten', const {});
    _adaptSave();
  }

  void setShorter(bool on) {
    if (on == (adapt.shorter != null)) return;
    adapt.shorter = on ? _adaptAt : null;
    _adaptEvent(on ? 'shorter' : 'unshorter', const {});
    _adaptSave();
  }

  // -------------------------------------------- propositions (accueil)

  bool _dismissed(String id) => adapt.dismissed.containsKey(id);

  void dismissAdapt(String id) {
    adapt.dismissed[id] = _adaptAt;
    if (adapt.dismissed.length > AdaptData.maxDismissed) {
      adapt.dismissed.remove(adapt.dismissed.keys.first);
    }
    _adaptSave();
  }

  /// Programme généré : jours de séance modifiables (profil).
  bool get _adaptDaysEditable =>
      programGenerated && profile != null && profile!.value('days') is List;

  List<AdaptProposal> get adaptProposals {
    if (program.start == null) return const [];
    final out = <AdaptProposal>[];
    final week = weekIndexOfDay(_adaptToday);
    if (adapt.pause == null) {
      final slide = adaptSlide;
      if (slide != null && !_dismissed('slide|${slide.$1}')) {
        final label = slide.$1.replaceAll('-', ' · ');
        out.add(
          AdaptProposal(
            'slide|${slide.$1}',
            'slide',
            'Reprendre là où tu t’es arrêté',
            '$label était prévue il y a ${slide.$2} jour${slide.$2 > 1 ? 's' : ''}. '
                'Le programme peut glisser : $label aujourd’hui et la suite '
                'décalée d’autant. Aucune séance n’est doublée.',
            const [('slide', 'Faire glisser'), ('dismiss', 'Plus tard')],
            {'days': slide.$2},
          ),
        );
      }
    }
    final advice = adherenceAdvice(
      adaptAdherence(),
      adaptAdherence(offset: 28),
      _adaptProgressed,
    );
    final rate = adaptAdherence();
    if (advice == 'fewer' && !_dismissed('fewer|$week')) {
      out.add(
        AdaptProposal(
          'fewer|$week',
          'fewer',
          'Un programme à ta mesure',
          '${((rate ?? 0) * 100).round()} % des séances prévues ces 4 '
              'dernières semaines. Un programme tenu vaut mieux qu’un '
              'programme parfait : on peut l’alléger.',
          [
            if (_adaptDaysEditable && _adaptDays(profile!).length > 1)
              ('dropDay', 'Une séance de moins par semaine'),
            if (adapt.shorter == null) ('shorter', 'Séances 20 % plus courtes'),
            ('dismiss', 'Garder tel quel'),
          ],
        ),
      );
    }
    if (advice == 'more' &&
        _adaptDaysEditable &&
        _adaptDays(profile!).length < 7 &&
        !_dismissed('more|$week')) {
      out.add(
        AdaptProposal(
          'more|$week',
          'more',
          'Belle régularité',
          'Au moins 90 % de tes séances faites depuis 8 semaines, et tu '
              'progresses. Si tu en as envie, une séance de plus par semaine '
              'est possible.',
          const [('addDay', 'Une séance de plus'), ('dismiss', 'Non merci')],
        ),
      );
    }
    final current = program.weekFor(storeClock());
    for (final m in adaptPlateaus) {
      final id = 'plateau|$m|$current';
      if (_dismissed(id) ||
          adapt.events.any(
            (e) =>
                e.kind == 'plateau' &&
                e.detail['movement'] == m &&
                (e.detail['week'] as num? ?? 0) >= current - 3,
          )) {
        continue;
      }
      final kind = plateauKind(adaptLevel);
      out.add(
        AdaptProposal(
          id,
          'plateau',
          'Palier : ${_adaptMoveLabel(m)}',
          'Ton estimation progresse de moins de 0,5 % par semaine depuis 3 '
              'semaines, alors que tu t’entraînes régulièrement. '
              '${kPlateauTexts[kind]}',
          [
            (
              'plateau',
              kind == 'deload' ? 'Programmer la décharge' : 'C’est noté',
            ),
            ('dismiss', 'Plus tard'),
          ],
          {'movement': m, 'kind': kind, 'week': current},
        ),
      );
    }
    final caution = adaptLoadCaution;
    if (caution != null && !_dismissed('caution|$week')) {
      final fatigue = koach.decisions.any(
        (d) =>
            d.kind == 'fatigue' &&
            weekIndexOfDay(dayIndex(DateTime.parse(d.at))) == week,
      );
      out.add(
        AdaptProposal(
          'caution|$week',
          'caution',
          'Semaine chargée',
          'Ta charge de la semaine (difficulté × durée) dépasse de '
              '${((caution.$1 - 1) * 100).round()} % la moyenne de tes 4 '
              'semaines précédentes'
              '${fatigue ? ', et Koach a relevé une fatigue probable' : ''}. '
              'C’est un simple repère : alléger la fin de semaine peut aider '
              'à récupérer.',
          [
            if (adapt.lightenFrom == null)
              ('lighten', 'Alléger la fin de semaine'),
            ('dismiss', 'Garder'),
          ],
        ),
      );
    }
    return out;
  }

  String _adaptMoveLabel(String m) {
    final n = koachMovementName(m);
    return n.isEmpty ? m : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  /// Exécute l'action d'une proposition de l'accueil.
  Future<String?> runAdaptAction(AdaptProposal p, String action) async {
    switch (action) {
      case 'dismiss':
        dismissAdapt(p.id);
        return null;
      case 'slide':
        applySlide(p.data['days'] as int);
        return 'Programme décalé de ${p.data['days']} jour(s).';
      case 'shorter':
        setShorter(true);
        dismissAdapt(p.id);
        return 'Séances 20 % plus courtes à partir de maintenant.';
      case 'lighten':
        applyLighten();
        dismissAdapt(p.id);
        return 'Fin de semaine allégée (séries × 0,8).';
      case 'dropDay' || 'addDay':
        final prof = profile;
        if (prof == null) return null;
        final days = _adaptDays(prof);
        final d = action == 'dropDay' ? dayToDrop(days) : dayToAdd(days);
        if (d == null) return null;
        final next = prof.copy();
        final list =
            action == 'dropDay'
                ? (days.where((x) => x != d).toList()..sort())
                : ([...days, d]..sort());
        next.setField('days', list, profileAt(storeClock()));
        _adaptEvent('days', {'action': action, 'day': d});
        dismissAdapt(p.id);
        ProfileStore(this).saveProfile(next);
        return 'Jours de séance modifiés : le programme va être régénéré '
            '(aperçu dans Mon programme).';
      case 'plateau':
        final kind = p.data['kind'] as String;
        final current = p.data['week'] as int;
        _adaptEvent('plateau', {
          'movement': p.data['movement'],
          'kind': kind,
          'week': current,
          if (kind == 'deload') 'deloadWeek': current + 1,
        });
        _adaptSave();
        return kind == 'deload'
            ? 'Décharge programmée la semaine ${current + 1}.'
            : 'Noté.';
    }
    return null;
  }
}
