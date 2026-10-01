// G7 (D4, D4.9, D5.10) — création du programme avec `kalis_plan` branchée
// sur le magasin : départ du nouveau programme, programme précédent gardé
// (semaines passées et retour possible pendant 7 jours), mise à jour du
// profil par la revue, bloc suivant (fin de bloc), « Où j'en suis » et
// séances « reprise », journal du moteur de la session de test.
// Modèles : plan/plan_program.dart, plan/plan_creation.dart.
part of 'store.dart';

/// Départ d'un nouveau programme.
typedef PlanStart = ({
  kc.CivilDate start,
  int firstWeek,
  bool replacing,
  DateTime programStart,
});

extension PlanStore on AppStore {
  /// Journal du moteur statique de la dernière création (session de test,
  /// hors sauvegarde).
  static const _kJournal = 'plan_engine_journal_v1';

  String get _planAt => profileAt(storeClock());

  DateTime get _planToday {
    final n = storeClock();
    return DateTime(n.year, n.month, n.day);
  }

  /// Un programme créé par kalis_plan est en place.
  bool get programPlanned => planProgram != null;

  /// Libellés de la mise en forme (catalogue, objectifs du profil).
  PlanLabels get planLabels => PlanLabels(
    name: (id) => content.byId[id]?.nom ?? id,
    cue: (id) {
      final d = content.detail(id);
      if (d == null) return '';
      return d.pointsCles.take(2).join(' · ');
    },
    goal: planGoalLabel,
  );

  /// Libellé d'un objectif du profil (raison `plan.goal_support`).
  String planGoalLabel(String goalId) {
    for (final g in athlete?.profile.goals ?? const <kc.Goal>[]) {
      if (g.id != goalId) continue;
      final ex = g.exerciseId;
      if (ex != null) return content.byId[ex]?.nom ?? ex;
      return g.kind == kc.GoalKind.habit ? 'régularité' : '';
    }
    return '';
  }

  /// La création est possible : profil v2 et base chargée.
  bool get planCanCreate =>
      athlete != null && content.catalog != null && AthleteProfileStore(this).athleteProfileForEngines != null;

  // ------------------------------------------------------------ départ

  bool _loggedAt(int week, int j) {
    final l = logs[sessionKey(week, j)];
    return l != null &&
        (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done)));
  }

  /// Où commence un nouveau programme créé aujourd'hui. Sans programme en
  /// cours (ou pas encore commencé) : aujourd'hui, semaine 1. Sinon : au
  /// début de la semaine de programme suivante (l'aujourd'hui reste celui
  /// du programme en cours), après toute séance déjà saisie ; les semaines
  /// passées restent celles du programme en cours.
  PlanStart planStartFor() {
    final today = _planToday;
    final start = program.start;
    var hasLogs = false;
    var lastLogged = 0;
    for (final k in logs.keys) {
      final m = RegExp(r'^S(\d+)-J(\d)$').firstMatch(k);
      if (m == null) continue;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      if (w == 0 || !_loggedAt(w, j)) continue;
      hasLogs = true;
      if (w > lastLogged) lastLogged = w;
    }
    final replacing =
        start != null || programInstance != null || planProgram != null;
    if (start == null || !hasLogs || program.beforeStart(today)) {
      return (
        start: civilOf(today),
        firstWeek: 1,
        replacing: replacing,
        programStart: today,
      );
    }
    final o = Program.civilIndex(today) - Program.civilIndex(start);
    var first = o % 7 == 0 ? o ~/ 7 + 1 : o ~/ 7 + 2;
    if (first <= lastLogged) first = lastLogged + 1;
    final d = DateTime(start.year, start.month, start.day + (first - 1) * 7);
    return (
      start: civilOf(d),
      firstWeek: first,
      replacing: true,
      programStart: start,
    );
  }

  /// Nouvelle création pour le profil v2 (null : profil ou base absents).
  PlanCreation? newPlanCreation({bool? journal}) {
    final profile = AthleteProfileStore(this).athleteProfileForEngines;
    final catalog = content.catalog;
    if (profile == null || catalog == null) return null;
    final s = planStartFor();
    return PlanCreation(
      catalog: catalog,
      profile: profile,
      startDate: s.start,
      journalOn: journal ?? SessionSpace.isDev,
    );
  }

  /// Semaines (schéma programme_v33) du programme affiché, copie profonde.
  List<Map<String, dynamic>> _displayedWeeksJson() {
    final plan = planProgram;
    if (plan != null) {
      return planWeeks(
        plan,
        startWeekday: program.start?.weekday ??
            plan.blocks.first.block.pass1.startDate.weekday,
        labels: planLabels,
      );
    }
    final inst = programInstance;
    if (inst != null && inst.generated) return copyWeeks(inst.weeks);
    return copyWeeks(_baseProgramJson['weeks'] as List);
  }

  Map<String, dynamic> _displayedKoachJson(List<Map<String, dynamic>> weeks) {
    final plan = planProgram;
    if (plan != null) return planKoachJson(plan, weeks, _baseKoachJson);
    final inst = programInstance;
    if (inst != null && inst.generated) return inst.koachJson(_baseKoachJson);
    return _baseKoachJson;
  }

  /// Valide le programme de [c] (passe 2 faite) : il devient l'instance
  /// active. Le programme précédent est gardé (semaines passées, retour
  /// pendant 7 jours) ; le profil apprend ce que la revue a dit.
  void applyPlanCreation(PlanCreation c) {
    final s = planStartFor();
    final at = _planAt;
    final hadProgram = s.replacing;
    final prefix = <Map<String, dynamic>>[];
    var prefixKoach = const <String, dynamic>{};
    if (s.firstWeek > 1) {
      final weeks = _displayedWeeksJson();
      final koach = _displayedKoachJson(weeks);
      for (var n = 1; n < s.firstWeek; n++) {
        final w = weeks.where((x) => x['n'] == n).toList();
        prefix.add(w.isEmpty ? restWeek(n) : w.first);
      }
      final ex = <String, dynamic>{};
      final ids = {
        for (final w in prefix)
          for (final d in w['days'] as List)
            for (final e in (d as Map)['exercises'] as List)
              '${(e as Map)['id']}',
      };
      for (final e in ((koach['exercises'] as Map?) ?? const {}).entries) {
        if (ids.contains('${e.key}')) ex['${e.key}'] = e.value;
      }
      final types = <String, dynamic>{};
      for (final e in ((koach['weeks'] as Map?) ?? const {}).entries) {
        final n = int.tryParse('${e.key}');
        if (n != null && n < s.firstWeek) types['${e.key}'] = e.value;
      }
      prefixKoach = {'exercises': ex, 'weeks': types};
    }
    final previous = hadProgram
        ? planProgram?.previous ??
              PlanPrevious(
                programInstance: programInstance?.toJson(withUndo: false),
                start: program.start == null
                    ? null
                    : civilDateString(program.start!),
                startOrigin: startOrigin,
                at: at,
              )
        : null;
    final next = PlanProgram(
      origin: hadProgram ? 'replace' : 'creation',
      createdAt: at,
      updatedAt: at,
      firstWeek: s.firstWeek,
      prefix: prefix,
      prefixKoach: prefixKoach,
      blocks: [c.entry(at)],
      previous: previous,
    );
    _planProfileLearned(c.profile);
    planProgram = next;
    _planRaw = null;
    programInstance = null;
    if (s.firstWeek == 1) programResume = null;
    startOrigin = 'user';
    _materializeProgram(s.programStart);
    if (c.journalOn) unawaited(savePlanJournal(c));
    _planChanged();
  }

  /// Ce que la revue a appris (« je sais faire », « je ne sais pas
  /// faire », aimés, détestés) reporté dans le profil v2 enregistré ; les
  /// changements du profil qui touchaient le programme sont lus (G6).
  void _planProfileLearned(kc.AthleteProfile learned) {
    final a = athlete;
    if (a == null) return;
    final p = a.profile.copyWith(
      knownExerciseIds: learned.knownExerciseIds,
      cannotDoExerciseIds: learned.cannotDoExerciseIds,
      likedExerciseIds: learned.likedExerciseIds,
      dislikedExerciseIds: learned.dislikedExerciseIds,
    );
    final same = kc.jsonDeepEquals(p.toJson(), a.profile.toJson());
    if (same && !a.programChangePending) return;
    athlete = AthleteRecord(
      profile: p,
      savedAt: a.savedAt,
      birthYearAt: a.birthYearAt,
      limitationsAt: a.limitationsAt,
      changes: [
        for (final c in a.changes) ProfileChange(c.at, c.rubrics, false),
      ],
    );
  }

  void _planChanged() {
    _progression = null;
    _koachCache = null;
    _koachCacheRevision = -1;
    _koachAuxRevision++;
    _allEx = null;
    _muscleIndex = null;
    pilotageEpoch++;
    _persist();
    notifyListeners();
  }

  // ------------------------------------------- retour à l'ancien programme

  /// L'ancien programme peut être rétabli : moins de 7 jours, et aucune
  /// séance du nouveau programme saisie.
  bool get planCanUndo {
    final plan = planProgram;
    final prev = plan?.previous;
    if (plan == null || prev == null) return false;
    final at = DateTime.tryParse(plan.createdAt);
    if (at == null || storeClock().difference(at) > kPlanUndoWindow) {
      return false;
    }
    for (var n = plan.firstWeek; n <= plan.totalWeeks; n++) {
      for (var j = 1; j <= 7; j++) {
        if (_loggedAt(n, j)) return false;
      }
    }
    return true;
  }

  /// Rétablit le programme précédent tel qu'il était.
  bool undoPlanProgram() {
    if (!planCanUndo) return false;
    final prev = planProgram!.previous!;
    programInstance = prev.programInstance == null
        ? null
        : ProgramInstance.fromJson(prev.programInstance);
    planProgram = null;
    startOrigin = prev.startOrigin;
    _materializeProgram(parseCivilDate(prev.start));
    _planChanged();
    return true;
  }

  // ---------------------------------------------------------- fin de bloc

  /// Dernier bloc dans sa dernière semaine (ou terminé) : le bloc suivant
  /// peut être préparé (D4.8).
  bool get planBlockEnding {
    final plan = planProgram;
    final start = program.start;
    if (plan == null || start == null) return false;
    final o = Program.civilIndex(_planToday) - Program.civilIndex(start);
    return o >= (plan.totalWeeks - 1) * 7;
  }

  /// Résumé d'adaptation du bloc en cours, d'après le journal seul (le
  /// moteur dynamique le fournira en G9) : séances prévues et faites.
  kc.AdaptationSummary _planSummary() {
    final plan = planProgram!;
    var planned = 0, completed = 0;
    final first = plan.blockFirstWeek(plan.blocks.length - 1);
    for (var n = first; n <= plan.totalWeeks; n++) {
      if (n < 1 || n > program.weeks.length) continue;
      for (final d in program.week(n).days) {
        if (d.exercises.isEmpty) continue;
        if (isResume(n, d.j)) continue;
        planned++;
        if (isDone(n, d.j)) completed++;
      }
    }
    return kc.AdaptationSummary(
      asOf: civilOf(_planToday),
      weeksObserved: plan.blocks.last.weeks,
      sessionsPlanned: planned,
      sessionsCompleted: completed,
      unlockLevel: kc.UnlockLevel.loadsReps,
      confidence: 0,
      estimates: const [],
      pains: const [],
      avoidedExerciseIds: const [],
      reasons: const [],
    );
  }

  /// Bloc suivant proposé par le moteur (null : impossible).
  ({kc.BlockProposal proposal, kc.NextBlockRequest request})?
  proposeNextBlock() {
    final plan = planProgram;
    final start = program.start;
    final profile = AthleteProfileStore(this).athleteProfileForEngines;
    final catalog = content.catalog;
    if (plan == null || start == null || profile == null || catalog == null) {
      return null;
    }
    final last = plan.blocks.last;
    final n = plan.totalWeeks + 1;
    final d = DateTime(start.year, start.month, start.day + (n - 1) * 7);
    final req = kc.NextBlockRequest(
      profile: profile,
      seed: last.seed,
      startDate: civilOf(d),
      previous: last.block,
      adaptation: _planSummary(),
      locks: const [],
    );
    try {
      return (proposal: kp.KalisPlan().nextBlock(catalog, req), request: req);
    } catch (_) {
      return null;
    }
  }

  /// Ajoute le bloc suivant validé.
  void applyNextBlock(kc.BlockProposal p, int seed) {
    final plan = planProgram;
    if (plan == null) return;
    final at = _planAt;
    planProgram = plan.copyWith(
      updatedAt: at,
      blocks: [
        ...plan.blocks,
        PlanBlockEntry(
          block: p.block,
          seed: seed,
          locks: const [],
          validatedAt: at,
        ),
      ],
      clearPrevious: true,
    );
    _materializeProgram(program.start);
    _planChanged();
  }

  // ------------------------------------------------------- Où j'en suis

  /// Séance marquée « reprise » (neutre) et sans journal.
  bool isResume(int week, int j) {
    final r = programResume;
    if (r == null) return false;
    return r.keys.contains(sessionKey(week, j)) && !_loggedAt(week, j);
  }

  /// Semaine et séance où l'utilisateur dit être (S, J), aujourd'hui.
  ({int week, int day})? get programPosition {
    final start = program.start;
    if (start == null) return null;
    final o = Program.civilIndex(_planToday) - Program.civilIndex(start);
    if (o < 0) return (week: 1, day: 1);
    return (week: o ~/ 7 + 1, day: o % 7 + 1);
  }

  /// « Où j'en suis » (D4.9) : la journée (S[week], J[day]) devient
  /// aujourd'hui ; les journées d'entraînement d'avant sans journal sont
  /// marquées « reprise » : neutres (ni XP, ni statistiques, ni série, ni
  /// records, ni données pour les moteurs). Rien d'autre ne change.
  void setProgramPosition(int week, int day) {
    final w = week.clamp(1, program.weeks.length);
    final d = day.clamp(1, 7);
    final today = _planToday;
    final before = program.start;
    final start = DateTime(
      today.year,
      today.month,
      today.day - ((w - 1) * 7 + d - 1),
    );
    final days = <({int week, int j, bool training})>[
      for (final wk in program.weeks)
        for (final dp in wk.days)
          (week: wk.n, j: dp.j, training: dp.exercises.isNotEmpty),
    ];
    final keys = resumeKeysFor(
      days: days,
      week: w,
      day: d,
      logged: _loggedAt,
    );
    programResume = ProgramResume(
      at: _planAt,
      week: w,
      day: d,
      keys: keys,
      previousStart: before == null ? null : civilDateString(before),
    );
    program.start = start;
    startOrigin = 'user';
    _planChanged();
  }

  /// Proposer « Où j'en suis » : un programme est en place mais aucune
  /// séance n'a été saisie depuis 14 jours (restauration d'une sauvegarde,
  /// nouveau téléphone) et la question n'a pas été réglée depuis.
  bool get planPositionSuggested {
    final start = program.start;
    if (start == null) return false;
    final today = _planToday;
    if (program.beforeStart(today)) return false;
    DateTime? last;
    for (final l in logs.values) {
      final f = l.finishedAt == null ? null : DateTime.tryParse(l.finishedAt!);
      if (f != null && (last == null || f.isAfter(last))) last = f;
    }
    final r = programResume;
    final settled = r == null ? null : DateTime.tryParse(r.at);
    final ref = [last, settled].whereType<DateTime>().fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
    if (ref == null) return Program.civilIndex(today) - Program.civilIndex(start) >= 14;
    return Program.civilIndex(today) - Program.civilIndex(ref) >= 14;
  }

  static const _kPositionLater = 'program_position_later_v1';

  /// « Où j'en suis » proposé sur l'accueil (au plus une fois par jour).
  bool get planPositionProposed {
    if (!planPositionSuggested) return false;
    try {
      return _prefs.getString(_kPositionLater) != civilDateString(_planToday);
    } catch (_) {
      return true;
    }
  }

  /// « Plus tard » : la proposition revient le lendemain.
  Future<void> snoozePlanPosition() async {
    try {
      await _prefs.setString(_kPositionLater, civilDateString(_planToday));
    } catch (_) {}
    notifyListeners();
  }

  // ------------------------------------------------ journal (mode dev)

  Future<void> savePlanJournal(PlanCreation c) async {
    try {
      await _prefs.setString(
        _kJournal,
        AppStore._pack(
          jsonEncode(c.journalJson(engineVersion: kp.kalisPlanVersion)),
        ),
      );
    } catch (_) {}
  }

  /// Journal du moteur de la dernière création (session de test), JSON.
  String? get planJournalText {
    try {
      return AppStore._unpack(_prefs.getString(_kJournal));
    } catch (_) {
      return null;
    }
  }
}

/// Jour de la semaine en toutes lettres d'un jour civil (« lundi »).
String planDayName(kc.CivilDate d) => weekdayName(d.weekday).toLowerCase();
