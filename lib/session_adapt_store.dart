// G9 (D5.3-D5.10) — la séance servie par le moteur dynamique `kalis_adapt`,
// branchée sur le magasin :
//
// - place de chaque journée dans un bloc du moteur : bloc de `kalis_plan`
//   (programme créé, ajustements de la passe 2 compris) ou bloc importé
//   depuis les semaines affichées (programme personnel du propriétaire,
//   ancien programme L10, semaines d'avant un programme créé), sans rien
//   changer à leur structure (D5.10) ;
// - journal présenté au moteur (règles C1 à C12 de G3 + emplacement, cible
//   affichée et bilan de chaque séance servie) ;
// - séance du jour : prescription figée dans le journal (`SessionLog.adapt`),
//   bilan santé, ajustement appliqué (mode assisté) ou proposé (mode libre),
//   conseils après chaque série, résumé de fin de séance.
//
// Aucune règle d'entraînement ici : charges, répétitions, flammes visées,
// ajustements et conseils viennent du moteur (D0.3). Modèle :
// adapt/session_adapt.dart ; textes : adapt/adapt_texts.dart.
part of 'store.dart';

/// Moteur dynamique partagé : il garde son dernier rejeu (même résultat,
/// moins de calcul quand le journal et le bloc sont les mêmes objets).
final ka.KalisAdapt kalisAdaptEngine = ka.KalisAdapt();

/// Lecture de `SessionLog.adapt`, attachée à l'objet JSON lui-même (chaque
/// écriture en crée un nouveau).
final Expando<(SessionAdapt?,)> _g9Parsed = Expando('g9');

/// Place d'une journée dans un bloc du moteur.
class AdaptPlace {
  final kc.ProgramBlock block;
  final int weekIndex;
  final int dayIndex;

  /// Bloc importé (programme existant porté tel quel).
  final bool imported;
  const AdaptPlace(this.block, this.weekIndex, this.dayIndex, this.imported);

  String get blockId => block.pass1.blockId;

  kc.DayPrescription? get day {
    for (final w in block.pass2.weeks) {
      if (w.weekIndex != weekIndex) continue;
      for (final d in w.days) {
        if (d.dayIndex == dayIndex) return d;
      }
    }
    return null;
  }
}

/// Évolution d'un exercice sur la séance (résumé de fin).
class AdaptExerciseSummary {
  final String exerciseId;
  final String name;
  final bool calibrating;
  final kc.ExerciseEstimate? before;
  final kc.ExerciseEstimate? after;

  /// Première série de la prochaine séance où l'exercice revient.
  final SetGoal? next;
  final SetGoal? today;
  const AdaptExerciseSummary({
    required this.exerciseId,
    required this.name,
    required this.calibrating,
    this.before,
    this.after,
    this.next,
    this.today,
  });

  /// Capacité estimée en hausse de plus d'un demi-écart-type.
  bool get progressed {
    final a = before, b = after;
    if (a == null || b == null) return false;
    return b.capacity - a.capacity > 0.5 * math.max(b.standardError, 1e-9) &&
        b.capacity > a.capacity * 1.005;
  }
}

/// Résumé de fin de séance (D9 §4).
class AdaptSessionSummary {
  final List<AdaptExerciseSummary> exercises;
  final List<String> painReferralZones;
  const AdaptSessionSummary(this.exercises, this.painReferralZones);
}

extension SessionAdaptStore on AppStore {
  // ------------------------------------------------------------ outils

  kc.CivilDate get _adaptToday => civilOf(storeClock());

  String _adaptNameOf(String id) => content.byId[id]?.nom ?? id;

  /// Nom d'un exercice de la base (textes de Koach).
  String adaptExerciseName(String id) => _adaptNameOf(id);

  /// Le moteur peut servir les séances : profil v2 et base chargée.
  bool get adaptAvailable => content.catalog != null && adaptProfile != null;

  /// Mode du profil (D3.7, D5.6).
  String get adaptMode {
    final m = athlete?.profile.guidanceMode;
    return m == kc.GuidanceMode.free ? 'free' : 'assisted';
  }

  ka.ExerciseBook? _adaptBook() {
    final catalog = content.catalog;
    final profile = adaptProfile;
    if (catalog == null || profile == null) return null;
    return _g9Memo(
      'book|${identityHashCode(catalog)}|${identityHashCode(athlete)}',
      () => ka.ExerciseBook(catalog, profile),
    );
  }

  T _g9Memo<T>(String key, T Function() build) {
    if (_g9Cache.containsKey(key)) {
      // Plus récent en dernier (éviction des plus anciens).
      final v = _g9Cache.remove(key);
      _g9Cache[key] = v;
      return v as T;
    }
    if (_g9Cache.length >= 256) {
      for (final k in _g9Cache.keys.take(64).toList()) {
        _g9Cache.remove(k);
      }
    }
    final v = build();
    _g9Cache[key] = v;
    return v;
  }

  /// Profil v2 pour les moteurs, le même objet tant que le profil et la
  /// référence santé ne changent pas (le moteur garde alors son rejeu).
  kc.AthleteProfile? get adaptProfile {
    final a = athlete;
    if (a == null) return null;
    final ref = jsonEncode(AthleteProfileStore(this).athleteHealthRef.toJson());
    final hit = _g9Cache['profile'];
    if (hit is (AthleteRecord, String, kc.AthleteProfile) &&
        identical(hit.$1, a) &&
        hit.$2 == ref) {
      return hit.$3;
    }
    final p = AthleteProfileStore(this).athleteProfileForEngines;
    if (p != null) _g9Cache['profile'] = (a, ref, p);
    return p;
  }

  // ------------------------------------------------------------ blocs

  /// Jour de la semaine (ISO) d'une journée J du programme.
  int _adaptWeekday(int j) {
    final s = program.start;
    if (s == null) return j;
    return (s.weekday - 1 + j - 1) % 7 + 1;
  }

  /// Dernière semaine (S) portée par un bloc importé.
  int get _importedLastWeek {
    final plan = planProgram;
    return plan == null ? program.weeks.length : plan.firstWeek - 1;
  }

  /// Place de la journée S[week]·J[j] dans un bloc du moteur (null : hors
  /// de tout bloc, ou semaine sans prescription portable).
  AdaptPlace? adaptPlaceOf(int week, int j) {
    if (week < 1 || week > program.weeks.length) return null;
    final plan = planProgram;
    if (plan != null && week >= plan.firstWeek) {
      final loc = plan.locate(week);
      if (loc == null) return null;
      final block = _adaptPlanBlock(loc.block);
      final startWeekday =
          program.start?.weekday ?? block.pass1.startDate.weekday;
      for (final d in block.pass1.days) {
        if (planJ(d.weekday, startWeekday) == j) {
          return AdaptPlace(block, loc.weekIndex, d.dayIndex, false);
        }
      }
      return null;
    }
    if (week > _importedLastWeek) return null;
    final chunk = (week - 1) ~/ 52;
    final built = _adaptImported(chunk);
    if (built == null) return null;
    final day = built.dayOfJ[j];
    if (day == null) return null;
    // G10 : propositions en place sur le bloc importé (le programme affiché
    // ne change pas ; la séance servie, si).
    final block = _g9Memo(
      'evolved|${identityHashCode(built.block)}|$_evoRevision',
      () => EvolutionStore(this).evolveBlock(built.block),
    );
    return AdaptPlace(block, week - 1 - chunk * 52, day, true);
  }

  /// Bloc de `kalis_plan` avec les ajustements de la passe 2 et (G10) les
  /// propositions du moteur dynamique en place.
  kc.ProgramBlock _adaptPlanBlock(int index) {
    final plan = planProgram!;
    final sig =
        'plan|${identityHashCode(plan)}|${plan.updatedAt}|'
        '${plan.blocks.length}|${plan.blocks[index].validatedAt}|$index|'
        '$_evoRevision';
    return _g9Memo(sig, () {
      final e = plan.blocks[index];
      return EvolutionStore(this).evolveBlock(adjustedBlock(e));
    });
  }

  /// Emplacement du bloc importé d'un exercice du programme affiché.
  static String importedSlot(int j, String exerciseId) =>
      'j$j-${exerciseId.split('~').first}';

  // ------------------------------------- CI1c : couche sur le bloc importé

  /// Identifiant du bloc importé de la tranche [chunk] (52 semaines).
  static String _importedBlockId(int chunk) => chunk == 0
      ? kLegacyProgramBlockId
      : '$kLegacyProgramBlockId-${chunk + 1}';

  /// CI1c (C10.2) : les propositions de Koach en place (appliquées en mode
  /// assisté ou acceptées) sur le bloc importé — le programme de 40
  /// semaines du propriétaire — sont montrées dans le programme affiché
  /// (MON PROGRAMME, accueil, séance) : chaque journée touchée est
  /// remplacée, à la lecture, par une journée qui porte l'ajustement, avec
  /// l'original en dessous ([DayPlan.original]). Rien n'est réécrit ni
  /// régénéré : retirer la proposition (annuler) rend la journée
  /// d'origine. Appelé après chaque mise en forme du programme et à chaque
  /// changement du magasin (rien n'est recalculé si rien n'a changé).
  void syncImportedOverlay() {
    final chunks = <int>{};
    final ids = <String>[];
    if (_evoRaw == null) {
      for (final e in planEvolution.entries) {
        if (!e.inEffect || !e.blockId.startsWith(kLegacyProgramBlockId)) {
          continue;
        }
        for (var c = 0; c * 52 < program.weeks.length; c++) {
          if (_importedBlockId(c) == e.blockId) chunks.add(c);
        }
        ids.add('${e.blockId}/${e.id}/${e.status}');
      }
    }
    final key = StringBuffer()
      ..write(identityHashCode(program))
      ..write('|$_overlayGen|$_evoRevision|')
      ..write(ids.join(','));
    final built = <int, ({kc.ProgramBlock block, Map<int, int> dayOfJ})?>{};
    if (chunks.isNotEmpty) {
      for (final c in chunks) {
        built[c] = _adaptImported(c);
        key.write('|$c:${identityHashCode(built[c])}');
      }
    }
    final k = key.toString();
    if (k == _overlayKey) return;
    _overlayKey = k;
    // Journées d'origine rétablies, puis couches posées à nouveau.
    for (final w in program.weeks) {
      for (var i = 0; i < w.days.length; i++) {
        final s = w.days[i].source;
        if (s != null) w.days[i] = s;
      }
    }
    try {
      for (final c in chunks) {
        final b = built[c];
        if (b != null) _overlayChunk(c, b);
      }
    } catch (_) {
      // Couche impossible à poser : le programme d'origine reste affiché
      // (la séance servie garde les ajustements, comme avant CI1c).
      for (final w in program.weeks) {
        for (var i = 0; i < w.days.length; i++) {
          final s = w.days[i].source;
          if (s != null) w.days[i] = s;
        }
      }
    }
  }

  void _overlayChunk(
    int chunk,
    ({kc.ProgramBlock block, Map<int, int> dayOfJ}) built,
  ) {
    final evolved = _g9Memo(
      'evolved|${identityHashCode(built.block)}|$_evoRevision',
      () => EvolutionStore(this).evolveBlock(built.block),
    );
    if (identical(evolved, built.block)) return;
    if (!importedLayoutKept(built.block, evolved)) return;
    final entries = planEvolution.inEffect(_importedBlockId(chunk));
    final first = chunk * 52 + 1;
    final last = math.min(first + 51, _importedLastWeek);
    for (var n = first; n <= last; n++) {
      if (n > program.weeks.length) break;
      final weekIndex = n - first;
      final week = program.week(n);
      for (var i = 0; i < week.days.length; i++) {
        final d = week.days[i];
        final dayIndex = built.dayOfJ[d.j];
        if (dayIndex == null) continue;
        final orig = _blockItems(built.block, weekIndex, dayIndex);
        final evo = _blockItems(evolved, weekIndex, dayIndex);
        if (kc.jsonDeepEquals(
          [for (final x in orig) x.toJson()],
          [for (final x in evo) x.toJson()],
        )) {
          continue;
        }
        final touching = [
          for (final e in entries)
            if (e.fromWeek <= weekIndex &&
                EvolutionStore.evolutionTouchesDay(e, dayIndex))
              e,
        ];
        week.days[i] = _overlayDay(d.original, orig, evo, touching, evolved);
      }
    }
  }

  /// Le bloc ajusté garde les journées du bloc importé (même jour de la
  /// semaine pour chaque journée) : sinon la couche ne peut pas être
  /// montrée jour pour jour (et la proposition n'est pas applicable).
  static bool importedLayoutKept(kc.ProgramBlock a, kc.ProgramBlock b) {
    if (identical(a, b)) return true;
    final da = {for (final d in a.pass1.days) d.dayIndex: d.weekday};
    final db = {for (final d in b.pass1.days) d.dayIndex: d.weekday};
    if (da.length != db.length) return false;
    for (final e in da.entries) {
      if (db[e.key] != e.value) return false;
    }
    if (a.pass2.weeks.length != b.pass2.weeks.length) return false;
    // Un emplacement ajouté doit pouvoir porter un exercice du programme
    // affiché (« j<J>-<identifiant> »).
    final js = <int, int>{};
    for (final d in a.pass1.days) {
      final m = RegExp(
        r'^j(\d)-',
      ).firstMatch(d.slots.isEmpty ? '' : d.slots.first.slotId);
      if (m != null) js[d.dayIndex] = int.parse(m.group(1)!);
    }
    for (final w in b.pass2.weeks) {
      for (final d in w.days) {
        final j = js[d.dayIndex];
        for (final it in d.items) {
          if (j == null || !it.slotId.startsWith('j$j-')) return false;
        }
      }
    }
    return true;
  }

  static List<kc.ExercisePrescription> _blockItems(
    kc.ProgramBlock b,
    int weekIndex,
    int dayIndex,
  ) {
    for (final w in b.pass2.weeks) {
      if (w.weekIndex != weekIndex) continue;
      for (final d in w.days) {
        if (d.dayIndex == dayIndex) return d.items;
      }
    }
    return const [];
  }

  /// Journée [d] du programme importé avec les prescriptions ajustées
  /// [evo] (au lieu de [orig]) : séries, répétitions, charge, repos ou
  /// exercice changés, exercice retiré ou ajouté. Un exercice que le bloc
  /// importé ne porte pas reste celui du programme.
  DayPlan _overlayDay(
    DayPlan d,
    List<kc.ExercisePrescription> orig,
    List<kc.ExercisePrescription> evo,
    List<EvolutionEntry> entries,
    kc.ProgramBlock evolved,
  ) {
    final o = {for (final x in orig) x.slotId: x};
    final v = {for (final x in evo) x.slotId: x};
    final why = _overlayWhy(entries, evolved);
    final out = <Exercise>[];
    final ids = <String>{};
    for (final e in d.exercises) {
      ids.add(e.id);
      final slot = importedSlot(d.j, e.id);
      final a = o[slot];
      if (a == null) {
        out.add(e);
        continue;
      }
      final b = v[slot];
      if (b == null) continue; // retiré par Koach
      if (kc.jsonDeepEquals(a.toJson(), b.toJson())) {
        out.add(e);
        continue;
      }
      out.add(_overlayExercise(e, a, b, why));
    }
    for (final b in evo) {
      if (o.containsKey(b.slotId)) continue;
      final id = b.slotId.substring('j${d.j}-'.length);
      if (id.isEmpty || ids.contains(id) || id.contains('~')) continue;
      final shell = Exercise.manual(
        id: id,
        name: _adaptNameOf(b.exerciseId),
        setsText: adaptSetsText(b),
      );
      out.add(_overlayExercise(shell, null, b, why));
    }
    return DayPlan.overlay(d, out);
  }

  Exercise _overlayExercise(
    Exercise e,
    kc.ExercisePrescription? a,
    kc.ExercisePrescription b,
    String why,
  ) {
    final o = a != null && a.exerciseId == b.exerciseId ? a : null;
    final sameAmount =
        o != null &&
        o.repsLow == b.repsLow &&
        o.repsHigh == b.repsHigh &&
        o.secondsLow == b.secondsLow &&
        o.secondsHigh == b.secondsHigh &&
        o.kind == b.kind &&
        b.setTargets == null &&
        o.setTargets == null;
    SetsSpec? sets;
    if (o != null && sameAmount) {
      sets = o.sets == b.sets ? e.sets : e.sets.withCount(b.sets);
    }
    final sameLoad =
        o != null &&
        o.startLoadKg == b.startLoadKg &&
        o.percentOfOneRm == b.percentOfOneRm &&
        o.loadBasis == b.loadBasis;
    final sameRest = o != null && o.restSeconds == b.restSeconds;
    final sameIntensity =
        o != null && o.targetFlames == b.targetFlames && o.kind == b.kind;
    return Exercise.koach(
      e,
      name: o != null ? e.name : _adaptNameOf(b.exerciseId),
      sets: sets ?? SetsSpec.text(adaptSetsText(b)),
      intensity: sameIntensity
          ? e.intensity
          : b.kind == kc.SetKind.test
          ? 'Test : au maximum, proprement'
          : adaptIntensity(b),
      load: sameLoad
          ? e.load
          : LoadSpec.fixed(
              b.loadBasis == kc.LoadBasis.bodyweight ? null : b.startLoadKg,
            ),
      rest: sameRest ? e.rest : pt.restLabel(b.restSeconds),
      restSec: sameRest ? e.restSec : b.restSeconds,
      cue: o != null ? e.cue : PlanStore(this).planLabels.cue(b.exerciseId),
      why: [
        if (why.isNotEmpty) why,
        if (o != null && e.why.isNotEmpty) e.why,
      ].join(' '),
      catalogId: b.exerciseId,
    );
  }

  /// « Koach : ajouter 1 série à Tractions (accepté le 28/09). » — ce qui a
  /// changé, par qui et quand (C10.2).
  String _overlayWhy(List<EvolutionEntry> entries, kc.ProgramBlock block) {
    if (entries.isEmpty) return 'Ajusté par Koach.';
    final e = entries.last;
    final action = et.evolutionAction(
      e,
      exerciseName: _adaptNameOf,
      dayName: (i) {
        for (final d in block.pass1.days) {
          if (d.dayIndex == i) return weekdayName(d.weekday);
        }
        return 'jour';
      },
    );
    final on = e.decidedOn;
    final date = on == null || on.length < 10
        ? ''
        : ' le ${on.substring(8, 10)}/${on.substring(5, 7)}';
    final how = e.status == EvoStatus.accepted
        ? 'accepté$date'
        : 'appliqué$date (mode assisté)';
    return 'Koach : ${et.capitalized(action)} ($how, annulable dans '
        'Évolution).';
  }

  /// Emplacement d'un exercice du journal (clé) dans le bloc de la journée.
  String? adaptSlotOf(int week, int j, String key) {
    final base = key.split('~').first;
    final plan = planProgram;
    if (plan != null && week >= plan.firstWeek) {
      final m = RegExp(r'^k\d+\.\d+\.(.+)$').firstMatch(base);
      return m?.group(1);
    }
    return importedSlot(j, base);
  }

  ({kc.ProgramBlock block, Map<int, int> dayOfJ})? _adaptImported(int chunk) {
    final catalog = content.catalog;
    final book = _adaptBook();
    if (catalog == null || book == null) return null;
    final sig = [
      'import',
      chunk,
      identityHashCode(program),
      identityHashCode(planProgram),
      planProgram?.updatedAt ?? '-',
      program.weeks.length,
      program.start?.toIso8601String() ?? '-',
      identityHashCode(weekKinds),
      identityHashCode(book),
      for (final e in values.entries) '${e.key}=${e.value}',
    ].join('|');
    return _g9Memo(sig, () {
      try {
        return _adaptBuildImported(chunk, catalog, book);
      } catch (_) {
        return null;
      }
    });
  }

  ({kc.ProgramBlock block, Map<int, int> dayOfJ})? _adaptBuildImported(
    int chunk,
    kc.Catalog catalog,
    ka.ExerciseBook book,
  ) {
    final first = chunk * 52 + 1;
    final last = math.min(first + 51, _importedLastWeek);
    if (last < first) return null;
    final weeks =
        <(int, kc.WeekKind, Map<int, List<kc.ExercisePrescription>>)>[];
    final js = <int>{};
    final slotExercise = <String, String>{};
    final slotRole = <String, kc.SlotRole>{};
    for (var n = first; n <= last; n++) {
      final w = program.week(n);
      final days = <int, List<kc.ExercisePrescription>>{};
      // CI1c : toujours le programme d'origine (sans la couche de Koach).
      for (final d in [for (final x in w.days) x.original]) {
        final items = <kc.ExercisePrescription>[];
        final used = <String>{};
        for (final e in d.exercises) {
          final it = _adaptImportItem(e, d.j, catalog, book);
          if (it == null || !used.add(it.$1.slotId)) continue;
          items.add(it.$1);
          slotExercise.putIfAbsent(it.$1.slotId, () => it.$1.exerciseId);
          if (it.$2 == kc.SlotRole.main ||
              !slotRole.containsKey(it.$1.slotId)) {
            slotRole[it.$1.slotId] = it.$2;
          }
        }
        if (items.isNotEmpty) {
          days[d.j] = items;
          js.add(d.j);
        }
      }
      final kind = weekKinds.isDeload(n)
          ? kc.WeekKind.deload
          : weekKinds.isTest(n)
          ? kc.WeekKind.test
          : w.blockKey == 'P0'
          ? kc.WeekKind.intro
          : kc.WeekKind.build;
      weeks.add((n - first, kind, days));
    }
    if (js.isEmpty) return null;
    final ordered = js.toList()..sort();
    final dayOfJ = {for (var i = 0; i < ordered.length; i++) ordered[i]: i};
    final start = program.start;
    final startDay = start == null
        ? _adaptToday
        : civilOf(DateTime(start.year, start.month, start.day + chunk * 364));
    final blockId = chunk == 0
        ? kLegacyProgramBlockId
        : '$kLegacyProgramBlockId-${chunk + 1}';
    final slots = slotExercise.keys.toList()..sort();
    final pass1 = kc.Pass1Plan(
      blockId: blockId,
      blockIndex: 0,
      weeks: weeks.length,
      startDate: startDay,
      seed: 0,
      engineVersion: 'import',
      days: [
        for (final j in ordered)
          kc.PlanDay(
            dayIndex: dayOfJ[j]!,
            weekday: _adaptWeekday(j),
            minutesBudget: 90,
            focus: 'imported',
            slots: [
              for (final s in slots)
                if (s.startsWith('j$j-'))
                  kc.PlanSlot(
                    slotId: s,
                    exerciseId: slotExercise[s]!,
                    role: slotRole[s]!,
                    locked: true,
                    reasons: const <kc.Reason>[],
                  ),
            ],
          ),
      ],
      score: const kc.PlanScore(total: 0, components: <kc.ScoreComponent>[]),
      reasons: const <kc.Reason>[],
    );
    final pass2 = kc.Pass2Plan(
      blockId: blockId,
      engineVersion: 'import',
      weeks: [
        for (final (index, kind, days) in weeks)
          kc.WeekPrescription(
            weekIndex: index,
            kind: kind,
            days: [
              for (final j in ordered)
                if (days.containsKey(j))
                  kc.DayPrescription(dayIndex: dayOfJ[j]!, items: days[j]!),
            ],
          ),
      ],
      reasons: const <kc.Reason>[],
    );
    final block = kc.ProgramBlock(pass1: pass1, pass2: pass2);
    if (block.validate().isNotEmpty) return null;
    return (block: block, dayOfJ: dayOfJ);
  }

  /// Prescription portée d'un exercice du programme affiché (null : sans
  /// équivalent dans la base, ou format que le contrat ne décrit pas par
  /// une plage — montées, myo-reps, clusters, échelles, EMOM, durées).
  (kc.ExercisePrescription, kc.SlotRole)? _adaptImportItem(
    Exercise e,
    int j,
    kc.Catalog catalog,
    ka.ExerciseBook book,
  ) {
    final id = e.catalogId ?? content.idFor(e.name);
    if (id == null) return null;
    final cat = catalog.find(id);
    final info = book.find(id);
    if (cat == null || info == null) return null;
    final sp = logSpec(e);
    if (sp.myo || sp.cluster || sp.rowPrefix.isNotEmpty) return null;
    final n = setCount(e);
    if (n < 1 || n > 20) return null;
    final text = setsLabel(e).toLowerCase().trim();
    final timed = cat.unit == kc.MeasureUnit.seconds;
    int? rl, rh, sl, sh;
    var test = false;
    switch (sp.kind) {
      case 'repsMax':
        if (timed) return null;
        test = true;
        rl = 1;
        rh = 200;
      case 'holdMax':
        if (!timed) return null;
        test = true;
        sl = 1;
        sh = 600;
      case 'hold':
        if (!timed) return null;
        final m = RegExp(
          r'^\d+\s*[×x]\s*(\d+)(?:\s*-\s*(\d+))?\s*s\b',
        ).firstMatch(text);
        if (m == null) return null;
        sl = int.parse(m.group(1)!);
        sh = int.parse(m.group(2) ?? m.group(1)!);
      case 'reps':
        if (timed) return null;
        final m = RegExp(
          r'^\d+\s*[×x]\s*(\d+)(?:\s*-\s*(\d+))?',
        ).firstMatch(text);
        if (m == null) return null;
        rl = int.parse(m.group(1)!);
        rh = int.parse(m.group(2) ?? m.group(1)!);
      default:
        return null;
    }
    if ((rl != null && (rl < 1 || rh! < rl)) ||
        (sl != null && (sl < 1 || sh! < sl))) {
      return null;
    }
    int? flames;
    final rir = RegExp(
      r'RIR\s*(\d+(?:[.,]\d+)?)(?:\s*-\s*(\d+(?:[.,]\d+)?))?',
    ).firstMatch(e.intensity);
    if (test) {
      flames = kc.Flames.failure;
    } else if (rir != null) {
      final a = double.parse(rir.group(1)!.replaceAll(',', '.'));
      final b = rir.group(2) == null
          ? a
          : double.parse(rir.group(2)!.replaceAll(',', '.'));
      flames = kc.Flames.fromRir((a + b) / 2);
    }
    final loaded = info.mode == ka.CapacityMode.loaded;
    double? share;
    final pct = e.load.pct;
    if (flames == null && loaded && pct != null && pct > 0) {
      var v = pct;
      if (e.load.type == 'system') {
        final bw = values['B4'];
        final rm = values[e.load.ref ?? ''];
        if (bw == null || rm == null || rm + info.fraction * bw <= 0) {
          v = -1;
        } else {
          v =
              (pct * (rm + bw) - bw + info.fraction * bw) /
              (rm + info.fraction * bw);
        }
      }
      if (v >= 0 && v <= 1.5) share = (v * 1000).roundToDouble() / 1000;
    }
    final basis = switch (cat.loadType) {
      kc.LoadType.addedWeight => kc.LoadBasis.bodyweightPlusExternal,
      kc.LoadType.barbell ||
      kc.LoadType.dumbbells ||
      kc.LoadType.kettlebell ||
      kc.LoadType.machine ||
      kc.LoadType.cable ||
      kc.LoadType.other => kc.LoadBasis.external,
      kc.LoadType.bodyweight => kc.LoadBasis.bodyweight,
      kc.LoadType.none || kc.LoadType.band => kc.LoadBasis.unloaded,
    };
    double? start;
    if (loaded && basis != kc.LoadBasis.bodyweight) {
      final kg = loadFor(e);
      if (kg != null && kg >= 0 && kg <= 1000) {
        start = (kg * 100).roundToDouble() / 100;
        if (basis == kc.LoadBasis.external && start <= 0) start = null;
      }
    }
    final rest = e.restSec;
    final role = e.main
        ? kc.SlotRole.main
        : e.prevention
        ? kc.SlotRole.accessory
        : (e.load.type == 'system' || e.load.type == 'barbell'
              ? kc.SlotRole.secondary
              : (info.mode == null
                    ? kc.SlotRole.mobility
                    : kc.SlotRole.accessory));
    return (
      kc.ExercisePrescription(
        slotId: importedSlot(j, e.id),
        exerciseId: id,
        sets: n,
        repsLow: rl,
        repsHigh: rh,
        secondsLow: sl,
        secondsHigh: sh,
        targetFlames: flames,
        restSeconds: rest?.clamp(0, 900),
        startLoadKg: start,
        percentOfOneRm: share,
        toCalibrate: false,
        loadBasis: basis,
        kind: test ? kc.SetKind.test : null,
        reasons: const <kc.Reason>[],
      ),
      role,
    );
  }

  // ----------------------------------------------------------- journal

  /// Séance du journal servie par le moteur (null : absente ou illisible).
  SessionAdapt? sessionAdaptOf(String key) {
    final raw = logs[key]?.adapt;
    if (raw == null) return null;
    // Lecture gardée tant que le JSON est le même objet (chaque écriture
    // en crée un nouveau).
    final hit = _g9Parsed[raw];
    if (hit != null) return hit.$1;
    SessionAdapt? parsed;
    try {
      parsed = SessionAdapt.fromJson(raw);
    } on FormatException {
      parsed = null;
    }
    _g9Parsed[raw] = (parsed,);
    return parsed;
  }

  SessionAdapt? sessionAdapt(int week, int j) =>
      sessionAdaptOf(sessionKey(week, j));

  /// Prescription de l'emplacement [slot] dans la séance faite.
  kc.ExercisePrescription? _adaptItem(SessionAdapt a, String? slot) {
    if (slot == null) return null;
    for (final it in a.active.items) {
      if (it.slotId == slot) return it;
    }
    return null;
  }

  /// Journal présenté au moteur (sans la séance [excludeKey]), jusqu'à
  /// [today] compris.
  kc.TrainingLog adaptTrainingLog({String? excludeKey, kc.CivilDate? today}) {
    final day = today ?? _adaptToday;
    final sig = StringBuffer('log|$excludeKey|${day.iso}|')
      ..write(identityHashCode(program))
      ..write('|')
      ..write(identityHashCode(planProgram))
      ..write('|')
      ..write(program.start?.toIso8601String());
    for (final e in logs.entries) {
      if (e.key == excludeKey) continue;
      var n = 0;
      for (final x in e.value.ex.values) {
        for (final s in x.sets) {
          if (s.done) {
            n =
                (n * 31 +
                    Object.hash(
                      s.kg,
                      s.reps,
                      s.rir,
                      s.flames,
                      s.flamesUnknown,
                      s.excluded,
                      s.effort,
                    )) &
                0x3fffffff;
          }
        }
      }
      sig.write(
        '|${e.key}:${e.value.done}:${e.value.finishedAt}:$n:'
        '${e.value.adapt == null ? '-' : identityHashCode(e.value.adapt)}',
      );
    }
    sig.write('|${programResume?.keys.length}|${koach.answers.length}');
    return _g9Memo(sig.toString(), () => _adaptBuildLog(excludeKey, day));
  }

  kc.TrainingLog _adaptBuildLog(String? excludeKey, kc.CivilDate today) {
    final start = program.start;
    final doc = <String, dynamic>{
      'logs': {for (final e in logs.entries) e.key: e.value.toJson()},
      if (start != null) 'programStart': {'date': civilDateString(start)},
      if (!koach.pristine) 'koach': koach.toJson(),
      if (programResume != null) 'programResume': programResume!.toJson(),
    };
    final converted = convertLegacyJournal(
      doc,
      exerciseId: content.idFor,
      usesSeconds: (id) => content.byId[id]?.ex.unit.code == 'secondes',
      dayOrder: (w, j) => w >= 1 && w <= program.weeks.length
          ? [for (final e in program.week(w).day(j)?.exercises ?? []) e.id]
          : const [],
      legacyDate: program.legacyDateFor,
      skip: (k) => k == excludeKey,
      slotOf: adaptSlotOf,
      testOf: (w, j, key) {
        final a = sessionAdaptOf(sessionKey(w, j));
        if (a == null) return false;
        return _adaptItem(a, adaptSlotOf(w, j, key))?.kind == kc.SetKind.test;
      },
      session: (w, j, key) {
        final a = sessionAdaptOf(key);
        if (a != null) {
          return {
            'origin': 'program',
            'programRef': {
              'blockId': a.blockId,
              'weekIndex': a.weekIndex,
              'dayIndex': a.dayIndex,
            },
            if (a.check != null) 'healthCheck': a.check!.toJson(),
            if (a.place != null) 'place': a.place!.code,
            'plannedWorkSets': plannedWorkSetsOf(a.active),
          };
        }
        final place = adaptPlaceOf(w, j);
        return {
          'programRef': place == null
              ? null
              : {
                  'blockId': place.blockId,
                  'weekIndex': place.weekIndex,
                  'dayIndex': place.dayIndex,
                },
        };
      },
      targetOf: (w, j, key, index) {
        final a = sessionAdaptOf(sessionKey(w, j));
        if (a == null) return null;
        final it = _adaptItem(a, adaptSlotOf(w, j, key));
        if (it == null) return null;
        final g = adviceGoal(it, index, a.advice[key] ?? const []);
        return g.toTarget().toJson();
      },
    );
    final sessions = [
      for (final s in converted.log.sessions)
        if (s.date.compareTo(today) <= 0) s,
    ];
    return kc.TrainingLog(sessions: sessions, breaks: converted.log.breaks);
  }

  // ------------------------------------------------------- prescription

  kc.AdaptInput? _adaptInput(AdaptPlace place, String excludeKey) {
    final profile = adaptProfile;
    if (profile == null) return null;
    return kc.AdaptInput(
      profile: profile,
      block: place.block,
      log: adaptTrainingLog(excludeKey: excludeKey),
      today: _adaptToday,
      season: adaptSeasonOf(place),
    );
  }

  /// CI1 : plan de saison du bloc servi (programme créé au chemin
  /// calibré) ; null pour un bloc importé (programme du propriétaire) ou
  /// un programme du chemin 0.1.
  kc.SeasonPlan? adaptSeasonOf(AdaptPlace place) =>
      place.imported ? null : planProgram?.season;

  kc.SessionPlan _adaptPrescribe(
    AdaptPlace place,
    kc.AdaptInput input,
    kc.HealthCheck? check,
    kc.Place? where,
  ) => kalisAdaptEngine.prescribeSession(
    content.catalog!,
    kc.SessionRequest(
      input: input,
      weekIndex: place.weekIndex,
      dayIndex: place.dayIndex,
      healthCheck: check,
      place: where,
    ),
  );

  /// Bilan qui compte pour le moteur : au moins une réponse.
  static bool _answered(kc.HealthCheck? c) =>
      c != null && c.toJson().isNotEmpty;

  /// Faits du bilan, gardés même sans l'ajustement : temps disponible et
  /// douleurs (null : aucun).
  static kc.HealthCheck? factsOf(kc.HealthCheck c) {
    final j = c.toJson();
    final out = <String, Object?>{
      if (j.containsKey('minutesAvailable'))
        'minutesAvailable': j['minutesAvailable'],
      if (j.containsKey('pains')) 'pains': j['pains'],
    };
    return out.isEmpty ? null : kc.HealthCheck.fromJson(out);
  }

  /// Séance du moteur pour la journée [base] de la semaine [week], d'après
  /// l'état courant (CI1c, C10) :
  ///
  /// - séance **non commencée** (aucune série validée) : toujours
  ///   prescrite à nouveau à l'ouverture — bloc avec les ajustements de
  ///   Koach en place, journal, profil, réglages du moment ; le bilan du
  ///   jour, le lieu et la suite donnée à l'ajustement du bilan restent
  ///   s'ils ont été donnés aujourd'hui ;
  /// - séance **commencée** : gardée (séries validées jamais perdues) ;
  ///   si la journée du bloc a changé depuis la prescription, ce qui reste
  ///   à faire (exercices pas encore commencés) suit la nouvelle
  ///   prescription.
  ///
  /// Null : séance hors moteur (profil v2 absent, journée hors bloc,
  /// séance commencée ou faite avant G9, erreur du moteur).
  SessionAdapt? adaptOpen(int week, DayPlan base) {
    if (week < 1 || base.exercises.isEmpty) return null;
    final key = sessionKey(week, base.j);
    final log = logs[key];
    final started =
        log != null &&
        (log.done || log.ex.values.any((x) => x.sets.any((s) => s.done)));
    final stored = log?.adapt == null ? null : sessionAdaptOf(key);
    // Séance du moteur illisible : gardée telle quelle, hors moteur.
    if (log?.adapt != null && stored == null) return null;
    if (started) {
      if (stored == null) return null;
      return _adaptRefreshStarted(week, base, stored) ?? stored;
    }
    if (!adaptAvailable) return stored;
    final place = adaptPlaceOf(week, base.j);
    if (place == null) return null;
    final today = _adaptToday.iso;
    if (stored != null &&
        stored.date == today &&
        stored.blockId == place.blockId &&
        stored.weekIndex == place.weekIndex &&
        stored.dayIndex == place.dayIndex) {
      // Ouverte plus tôt aujourd'hui : même bilan, même lieu, prescription
      // à jour.
      return _adaptReprescribe(
            week,
            base,
            stored,
            check: stored.check,
            where: stored.place,
            asked: stored.asked,
            quiet: true,
          ) ??
          stored;
    }
    try {
      final input = _adaptInput(place, key);
      if (input == null) return stored;
      final plan = _adaptPrescribe(place, input, null, null);
      final a = SessionAdapt(
        blockId: place.blockId,
        weekIndex: place.weekIndex,
        dayIndex: place.dayIndex,
        date: today,
        mode: adaptMode,
        plan: plan,
        source: _adaptSourceOf(place),
      );
      final target = sessionLog(week, base.j);
      target.adapt = a.toJson().cast<String, dynamic>();
      // Séries préparées (non validées) : nombre et cibles du moteur.
      for (final x in target.ex.values) {
        for (final s in x.sets) {
          if (s.done) continue;
          s.kg = '';
          s.reps = '';
        }
      }
      _adaptResync(week, base, a, a, target, key);
      _adaptQuietSave();
      return a;
    } catch (_) {
      return stored;
    }
  }

  /// Appelé pendant la construction de l'écran de séance : écriture
  /// différée, sans prévenir les écouteurs.
  void _adaptQuietSave() {
    _dataRevision++;
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 600), _flushLogs);
  }

  /// CI1c : empreinte de la journée du bloc servie (prescriptions écrites,
  /// ajustements de Koach compris) et du mode.
  String? _adaptSourceOf(AdaptPlace place) {
    final d = place.day;
    if (d == null) return null;
    return '${adaptMode[0]}${fnv1a32(jsonEncode(d.toJson()))}';
  }

  /// CI1c : séance commencée dont la journée du bloc a changé depuis la
  /// prescription (ajustement de Koach accepté, bloc remplacé) : nouvelle
  /// prescription pour les exercices pas encore commencés ; ceux qui ont
  /// une série validée gardent leur prescription et leurs conseils. Null :
  /// rien à changer.
  SessionAdapt? _adaptRefreshStarted(int week, DayPlan base, SessionAdapt a) {
    if (a.source == null || a.date != _adaptToday.iso) return null;
    if (!adaptAvailable) return null;
    final place = adaptPlaceOf(week, base.j);
    if (place == null ||
        place.blockId != a.blockId ||
        place.weekIndex != a.weekIndex ||
        place.dayIndex != a.dayIndex) {
      return null;
    }
    final src = _adaptSourceOf(place);
    if (src == null || src == a.source) return null;
    final key = sessionKey(week, base.j);
    final log = logs[key];
    if (log == null || log.done) return null;
    try {
      final input = _adaptInput(place, key);
      if (input == null) return null;
      final useCheck = _answered(a.check) ? a.check : null;
      // Emplacements commencés : prescription d'origine gardée.
      final startedSlots = <String>{
        for (final e in log.ex.entries)
          if (e.value.sets.any((s) => s.done))
            if (adaptSlotOf(week, base.j, e.key) case final slot?) slot,
      };
      kc.SessionPlan merge(kc.SessionPlan fresh, kc.SessionPlan old) {
        final keep = {
          for (final it in old.items)
            if (startedSlots.contains(it.slotId)) it.slotId: it,
        };
        final items = <kc.ExercisePrescription>[
          for (final it in fresh.items) keep.remove(it.slotId) ?? it,
          ...keep.values,
        ];
        return fresh.copyWith(items: items);
      }

      final plan = merge(
        _adaptPrescribe(place, input, useCheck, a.place),
        a.plan,
      );
      kc.SessionPlan? without;
      if (useCheck != null) {
        final b = merge(
          _adaptPrescribe(place, input, factsOf(useCheck), a.place),
          a.base ?? a.plan,
        );
        if (!jsonDeepEquals(b.toJson(), plan.toJson())) without = b;
      }
      final next = SessionAdapt(
        blockId: a.blockId,
        weekIndex: a.weekIndex,
        dayIndex: a.dayIndex,
        date: a.date,
        mode: a.mode,
        asked: a.asked,
        check: a.check,
        place: a.place,
        plan: plan,
        base: without,
        choice: without == null ? null : (a.choice ?? _defaultChoice(a.mode)),
        advice: {
          for (final e in a.advice.entries)
            if (startedSlots.contains(adaptSlotOf(week, base.j, e.key)))
              e.key: e.value,
        },
        source: src,
      );
      final target = sessionLog(week, base.j);
      target.adapt = next.toJson().cast<String, dynamic>();
      _adaptResync(week, base, a, next, target, key);
      _adaptQuietSave();
      return next;
    } catch (_) {
      return null;
    }
  }

  static String _defaultChoice(String mode) =>
      mode == 'assisted' ? 'applied' : 'pending';

  void _adaptStore(
    int week,
    DayPlan base,
    SessionAdapt before,
    SessionAdapt a,
  ) {
    final key = sessionKey(week, base.j);
    final log = sessionLog(week, base.j);
    log.adapt = a.toJson().cast<String, dynamic>();
    _adaptResync(week, base, before, a, log, key);
    saveLogs();
  }

  /// Nouvelle prescription avec le bilan [check] et le lieu [where] ; la
  /// séance sans l'effet du bilan est gardée quand elle diffère.
  SessionAdapt? _adaptReprescribe(
    int week,
    DayPlan base,
    SessionAdapt a, {
    required kc.HealthCheck? check,
    required kc.Place? where,
    required bool asked,
    bool quiet = false,
  }) {
    final key = sessionKey(week, base.j);
    final place = adaptPlaceOf(week, base.j);
    if (place == null || place.blockId != a.blockId) return null;
    try {
      final input = _adaptInput(place, key);
      if (input == null) return null;
      final useCheck = _answered(check) ? check : null;
      final plan = _adaptPrescribe(place, input, useCheck, where);
      kc.SessionPlan? without;
      if (useCheck != null) {
        // « Garder ma séance » / « Annuler » retire l'effet de la forme du
        // jour, pas les faits donnés : temps disponible et douleurs restent.
        final facts = factsOf(useCheck);
        final b = _adaptPrescribe(place, input, facts, where);
        if (!jsonDeepEquals(b.toJson(), plan.toJson())) without = b;
      }
      final mode = adaptMode;
      final next = SessionAdapt(
        blockId: a.blockId,
        weekIndex: a.weekIndex,
        dayIndex: a.dayIndex,
        date: _adaptToday.iso,
        mode: mode,
        asked: asked,
        check: useCheck,
        place: where,
        plan: plan,
        base: without,
        // CI1c : à la réouverture (quiet), la suite déjà donnée à
        // l'ajustement du bilan est gardée.
        choice: without == null
            ? null
            : (quiet && a.base != null && a.choice != null && a.mode == mode
                  ? a.choice
                  : _defaultChoice(mode)),
        // Conseils calculés pour l'ancienne prescription : retirés.
        advice: const {},
        source: _adaptSourceOf(place),
      );
      if (quiet) {
        // Réouverture : séance gardée si rien n'a changé ; séries
        // préparées remises au nombre et aux cibles de la séance servie.
        final same = jsonDeepEquals(next.toJson(), a.toJson());
        final kept = same ? a : next;
        final target = sessionLog(week, base.j);
        if (!same) target.adapt = next.toJson().cast<String, dynamic>();
        _adaptResync(week, base, a, kept, target, key);
        _adaptQuietSave();
        return kept;
      }
      _adaptStore(week, base, a, next);
      return next;
    } catch (_) {
      return null;
    }
  }

  /// Réponse au bilan (D5.8) : seules les réponses données comptent.
  /// [check] null ou vide avec [skipped] : bilan passé.
  SessionAdapt? adaptAnswer(
    int week,
    DayPlan base,
    kc.HealthCheck? check, {
    bool skipped = false,
  }) {
    final a = sessionAdapt(week, base.j);
    if (a == null) return null;
    if (skipped && !_answered(check)) {
      if (!_answered(a.check)) {
        final next = a.copyWith(asked: true);
        _adaptStore(week, base, a, next);
        return next;
      }
      // Bilan passé : la forme du jour n'est plus prise en compte ; le
      // temps disponible et les douleurs déjà dits restent.
      return _adaptReprescribe(
        week,
        base,
        a,
        check: factsOf(a.check!),
        where: a.place,
        asked: true,
      );
    }
    return _adaptReprescribe(
      week,
      base,
      a,
      check: check,
      where: a.place,
      asked: true,
    );
  }

  /// Temps disponible aujourd'hui (« J'ai seulement… minutes ») : ajouté au
  /// bilan ([minutes] null : retiré).
  SessionAdapt? adaptSetMinutes(int week, DayPlan base, int? minutes) {
    final a = sessionAdapt(week, base.j);
    if (a == null) return null;
    final c = (a.check ?? const kc.HealthCheck()).toJson();
    if (minutes == null) {
      c.remove('minutesAvailable');
    } else {
      c['minutesAvailable'] = minutes;
    }
    return _adaptReprescribe(
      week,
      base,
      a,
      check: kc.HealthCheck.fromJson(c),
      where: a.place,
      asked: a.asked,
    );
  }

  /// Lieu du jour (« Je m'entraîne ailleurs ») ; null : lieu prévu.
  SessionAdapt? adaptSetPlace(int week, DayPlan base, kc.Place? where) {
    final a = sessionAdapt(week, base.j);
    if (a == null) return null;
    return _adaptReprescribe(
      week,
      base,
      a,
      check: a.check,
      where: where,
      asked: a.asked,
    );
  }

  /// Suite donnée à l'ajustement du bilan : `undone`, `applied` (mode
  /// assisté), `accepted`, `kept` (mode libre).
  SessionAdapt? adaptChoose(int week, DayPlan base, String choice) {
    final a = sessionAdapt(week, base.j);
    if (a == null || a.base == null || !kAdaptChoices.contains(choice)) {
      return a;
    }
    final next = a.copyWith(choice: choice);
    _adaptStore(week, base, a, next);
    return next;
  }

  // ------------------------------------------------------ séance du jour

  /// Journée telle que le moteur la sert : exercices du programme, avec
  /// séries, charges et cibles de la séance faite ; remplacés ou retirés
  /// par l'ajustement (un exercice déjà commencé reste). Un exercice que le
  /// moteur ne porte pas (format sans plage) reste celui du programme.
  DayPlan adaptDay(int week, DayPlan base, SessionAdapt a) {
    final place = adaptPlaceOf(week, base.j);
    final blockSlots = {
      for (final it in place?.day?.items ?? const <kc.ExercisePrescription>[])
        it.slotId: it,
    };
    final log = logs[sessionKey(week, base.j)];
    final out = <Exercise>[];
    for (final e in base.exercises) {
      final slot = adaptSlotOf(week, base.j, e.id);
      final it = _adaptItem(a, slot);
      if (it == null) {
        if (slot != null && blockSlots.containsKey(slot)) {
          final started = log?.ex[e.id]?.sets.any((s) => s.done) ?? false;
          if (!started) continue; // retiré par l'ajustement
        }
        out.add(e);
        continue;
      }
      // CI1c : remplacé aujourd'hui seulement quand l'exercice servi n'est
      // pas celui du programme affiché (un échange accepté sur le bloc
      // importé est déjà dans le programme affiché, sous son nom).
      final shownId = e.catalogId ?? content.idFor(e.name);
      final swapped = shownId != null && shownId != it.exerciseId;
      final id = swapped ? '${e.id}~${it.exerciseId}' : e.id;
      final g = adviceGoal(it, 0, a.advice[id] ?? const []);
      out.add(
        Exercise.engine(
          e,
          id: id,
          name: swapped ? _adaptNameOf(it.exerciseId) : e.name,
          setsText: adaptSetsText(it),
          setCount: it.sets,
          intensity: it.kind == kc.SetKind.test
              ? 'Test : au maximum, proprement'
              : adaptIntensity(it),
          kg: it.loadBasis == kc.LoadBasis.bodyweight ? null : g.kg,
          rest: pt.restLabel(it.restSeconds),
          restSec: it.restSeconds,
          cue: swapped ? PlanStore(this).planLabels.cue(it.exerciseId) : e.cue,
          why: swapped
              ? 'Remplace « ${splitName(e.name).$1} » aujourd’hui.'
              : e.why,
          catalogId: it.exerciseId,
          slotId: slot,
          tempo: ct.coachTempoText(it),
          timer: _adaptTimerOf(it),
        ),
      );
    }
    // CI1b (`kalis_adapt` 0.2.2, mode coach) : un test de la semaine pas
    // encore fait (bilan bas, séance manquée) est servi ce jour, avant le
    // travail du jour ; il porte l'emplacement du jour d'origine.
    if (place != null && !place.imported) {
      final known = <String>{
        ...blockSlots.keys,
        for (final e in out)
          if (adaptSlotOf(week, base.j, e.id) case final s?) s,
      };
      final moved = <Exercise>[];
      for (final it in a.active.items) {
        if (it.kind != kc.SetKind.test || !known.add(it.slotId)) continue;
        final from = _adaptWeekExercise(week, it.slotId);
        if (from == null) continue;
        moved.add(
          Exercise.engine(
            from.e,
            id: planExerciseId(week, base.j, it.slotId),
            name: from.e.name,
            setsText: adaptSetsText(it),
            setCount: it.sets,
            intensity: 'Test : au maximum, proprement',
            kg: it.loadBasis == kc.LoadBasis.bodyweight
                ? null
                : adviceGoal(
                    it,
                    0,
                    a.advice[planExerciseId(week, base.j, it.slotId)] ??
                        const [],
                  ).kg,
            rest: pt.restLabel(it.restSeconds),
            restSec: it.restSeconds,
            cue: from.e.cue,
            why:
                'Test de la semaine reporté ici (prévu '
                '${_adaptDayName(week, from.j)}).',
            catalogId: it.exerciseId,
            slotId: it.slotId,
            tempo: ct.coachTempoText(it),
            timer: _adaptTimerOf(it),
          ),
        );
      }
      if (moved.isNotEmpty) {
        var at = 0;
        while (at < out.length &&
            _adaptItem(a, adaptSlotOf(week, base.j, out[at].id))?.kind ==
                kc.SetKind.warmup) {
          at++;
        }
        out.insertAll(at, moved);
      }
    }
    return DayPlan.adapted(base, out);
  }

  /// CI1b : jour de la semaine (« mardi ») de la journée S[week]·J[j].
  String _adaptDayName(int week, int j) {
    final s = program.start;
    if (s == null) return 'un autre jour';
    return weekdayName(
      DateTime(s.year, s.month, s.day + (week - 1) * 7 + j - 1).weekday,
    );
  }

  /// CI1b : exercice du programme de la semaine [week] à l'emplacement
  /// [slot] (autre jour de la semaine), avec son jour.
  ({Exercise e, int j})? _adaptWeekExercise(int week, String slot) {
    if (week < 1 || week > program.weeks.length) return null;
    for (final d in program.week(week).days) {
      for (final e in d.exercises) {
        if (adaptSlotOf(week, d.j, e.id) == slot) return (e: e, j: d.j);
      }
    }
    return null;
  }

  /// CI1 : chrono de la technique servie (EMOM, bloc au temps), dans le
  /// format des chronos de l'application ; null : chrono par série ou
  /// aucun.
  Map<String, dynamic>? _adaptTimerOf(kc.ExercisePrescription it) {
    final t = it.technique;
    if (t == null) return null;
    switch (t.kind) {
      case kc.SetTechniqueKind.emom:
        final every = t.intervalSeconds ?? 60;
        return {
          'type': 'emom',
          'rounds': t.intervals ?? it.sets,
          'interval': every < 10 ? 60 : every,
        };
      case kc.SetTechniqueKind.density:
      case kc.SetTechniqueKind.amrap:
      case kc.SetTechniqueKind.forTime:
        final d = t.durationSeconds;
        if (d == null || d < 10) return null;
        return {'type': 'amrap', 'sec': d};
      default:
        return null;
    }
  }

  /// CI1 : prescription du bloc (programme écrit) de l'exercice servi :
  /// notes de coach, règle de douleur, technique écrite.
  kc.ExercisePrescription? adaptBlockItemFor(int week, int j, Exercise e) {
    if (!e.engine || e.slotId == null) return null;
    final place = adaptPlaceOf(week, j);
    for (final it in place?.day?.items ?? const <kc.ExercisePrescription>[]) {
      if (it.slotId == e.slotId) return it;
    }
    // CI1b : test reporté d'un autre jour de la semaine (bloc du moteur
    // calibré seulement, jamais le bloc importé du propriétaire).
    if (place == null || place.imported) return null;
    for (final w in place.block.pass2.weeks) {
      if (w.weekIndex != place.weekIndex) continue;
      for (final d in w.days) {
        for (final it in d.items) {
          if (it.slotId == e.slotId) return it;
        }
      }
    }
    return null;
  }

  /// CI1 : libellé de la ligne [i] d'un exercice servi selon son rôle
  /// (« Tête », « A1 » pour une série allégée, « Éc1 » pour une montée,
  /// « M3 » pour la 3e minute d'un EMOM…) ; null : numérotation habituelle.
  String? adaptRowLabel(int week, int j, Exercise e, int i) {
    final a = sessionAdapt(week, j);
    if (a == null || !e.engine) return null;
    final it = _adaptItem(a, e.slotId);
    if (it == null) return null;
    final role = ct.prescriptionRow(it, i).role;
    if (role == null) return null;
    var first = i;
    while (first > 0 && ct.prescriptionRow(it, first - 1).role == role) {
      first--;
    }
    return ct.rowRoleShort(role, i, first);
  }

  /// CI1 : repos écrit après la ligne [i] d'un exercice servi (cible de la
  /// série, puis mini-repos d'un EMOM : ce qui reste de la minute est géré
  /// par le chrono) ; null : repos de l'exercice.
  int? adaptRestAfter(int week, int j, Exercise e, int i) {
    final a = sessionAdapt(week, j);
    if (a == null || !e.engine) return null;
    final it = _adaptItem(a, e.slotId);
    if (it == null) return null;
    if (it.technique?.kind == kc.SetTechniqueKind.emom) return 0;
    return adviceGoal(it, i, a.advice[e.id] ?? const []).restSec;
  }

  /// Prescription d'un exercice de la séance servie.
  kc.ExercisePrescription? adaptItemFor(int week, int j, Exercise e) {
    final a = sessionAdapt(week, j);
    if (a == null || !e.engine) return null;
    return _adaptItem(a, e.slotId);
  }

  /// Cible de la série [index] d'un exercice de la séance servie (après
  /// les conseils actifs).
  SetGoal? adaptGoal(int week, int j, Exercise e, int index) {
    final a = sessionAdapt(week, j);
    if (a == null || !e.engine) return null;
    final it = _adaptItem(a, e.slotId);
    if (it == null) return null;
    return adviceGoal(it, index, a.advice[e.id] ?? const []);
  }

  /// Texte « kg » et « valeur » pré-remplis d'une cible.
  ({String kg, String value}) _goalTexts(SetGoal g, bool loaded) => (
    kg: loaded && g.kg != null ? adaptKgField(g.kg!) : '',
    value: g.prefill == null ? '' : '${g.prefill}',
  );

  /// Pré-remplit les séries non validées encore vides d'un exercice servi.
  void adaptPrefill(int week, int j, Exercise e, ExerciseLog log) {
    final a = sessionAdapt(week, j);
    if (a == null || !e.engine) return;
    final it = _adaptItem(a, e.slotId);
    if (it == null) return;
    final loaded =
        it.loadBasis != kc.LoadBasis.bodyweight &&
        it.loadBasis != kc.LoadBasis.unloaded;
    final test =
        it.kind == kc.SetKind.test &&
        ((it.repsHigh ?? 0) >= 100 || (it.secondsHigh ?? 0) >= 300);
    for (var i = 0; i < log.sets.length; i++) {
      final s = log.sets[i];
      if (s.done) continue;
      final t = _goalTexts(
        adviceGoal(it, i, a.advice[e.id] ?? const []),
        loaded,
      );
      if (s.kg.isEmpty && t.kg.isNotEmpty) s.kg = t.kg;
      if (s.reps.isEmpty && t.value.isNotEmpty && !test) s.reps = t.value;
    }
  }

  /// Après un changement de la séance faite ou des conseils : nombre de
  /// séries et valeurs pré-remplies des séries non validées que
  /// l'utilisateur n'a pas modifiées.
  void _adaptResync(
    int week,
    DayPlan base,
    SessionAdapt before,
    SessionAdapt after,
    SessionLog log,
    String key,
  ) {
    for (final entry in log.ex.entries) {
      final slot = adaptSlotOf(week, base.j, entry.key);
      final itA = _adaptItem(before, slot);
      final itB = _adaptItem(after, slot);
      if (itB == null) continue;
      final x = entry.value;
      // Séries : celles de la séance faite, sans retirer une série validée.
      while (x.sets.length > itB.sets && !x.sets.last.done) {
        x.sets.removeLast();
      }
      while (x.sets.length < itB.sets) {
        x.addSet();
      }
      final loaded =
          itB.loadBasis != kc.LoadBasis.bodyweight &&
          itB.loadBasis != kc.LoadBasis.unloaded;
      for (var i = 0; i < x.sets.length; i++) {
        final s = x.sets[i];
        if (s.done) continue;
        final nb = _goalTexts(
          adviceGoal(itB, i, after.advice[entry.key] ?? const []),
          loaded,
        );
        if (itA == null) {
          if (s.kg.isEmpty) s.kg = nb.kg;
          if (s.reps.isEmpty) s.reps = nb.value;
          continue;
        }
        final na = _goalTexts(
          adviceGoal(itA, i, before.advice[entry.key] ?? const []),
          loaded,
        );
        if (s.kg == na.kg || s.kg.isEmpty) s.kg = nb.kg;
        if (s.reps == na.value || s.reps.isEmpty) s.reps = nb.value;
      }
    }
  }

  // ------------------------------------------------- pendant la séance

  /// Séries déjà faites de la séance, dans l'ordre de réalisation.
  List<kc.SetRecord> _adaptDone(int week, DayPlan day, SessionAdapt a) {
    final key = sessionKey(week, day.j);
    final log = logs[key];
    if (log == null) return const [];
    final rows = <(String, int, kc.SetRecord)>[];
    var order = 0;
    for (final e in day.exercises) {
      final x = log.ex[e.id];
      if (x == null) continue;
      final id = e.catalogId ?? content.idFor(e.name);
      if (id == null) continue;
      final seconds = content.byId[id]?.ex.unit.code == 'secondes';
      final it = _adaptItem(a, e.slotId ?? adaptSlotOf(week, day.j, e.id));
      var setIndex = 0;
      var any = false;
      for (var i = 0; i < x.sets.length; i++) {
        final s = x.sets[i];
        if (!s.done) continue;
        final v = parseWholeNumber(s.reps);
        if (v == null) continue;
        final g = it == null
            ? null
            : adviceGoal(it, i, a.advice[e.id] ?? const []);
        final low = g?.low;
        rows.add((
          s.completedAt ?? '',
          rows.length,
          kc.SetRecord(
            exerciseId: id,
            exerciseOrder: order,
            setIndex: setIndex++,
            kind:
                it?.kind == kc.SetKind.test ||
                    g?.role == kc.SetRole.test ||
                    g?.role == kc.SetRole.attempt
                ? kc.SetKind.test
                : g?.role == kc.SetRole.warmup
                ? kc.SetKind.warmup
                : kc.SetKind.work,
            role: g?.role,
            externalLoadKg: parseLoadKg(s.kg),
            reps: seconds ? null : v,
            seconds: seconds ? v : null,
            flames: s.flames,
            success: v > 0 && (low == null || v >= low),
            excluded: s.excluded,
            slotId: it?.slotId ?? e.slotId,
            target: g?.toTarget(),
          ),
        ));
        any = true;
      }
      if (any) order++;
    }
    rows.sort((x, y) {
      final c = x.$1.compareTo(y.$1);
      return c != 0 ? c : x.$2.compareTo(y.$2);
    });
    return [for (final r in rows) r.$3];
  }

  /// Conseil du moteur après la série [index] de [e] (validée) : la cible
  /// des séries suivantes (D5.4, §4.4 du contrat). Mode assisté : appliqué
  /// aux séries non validées que l'utilisateur n'a pas modifiées ; mode
  /// libre : en attente de son accord. Null : rien à dire.
  ({kc.IntraSessionAdvice advice, AdviceStep? step})? adaptAfterSet(
    int week,
    DayPlan day,
    Exercise e,
    int index,
  ) {
    final a = sessionAdapt(week, day.j);
    if (a == null || !e.engine || e.slotId == null) return null;
    final it = _adaptItem(a, e.slotId);
    final placeOf = adaptPlaceOf(week, day.j);
    if (it == null || placeOf == null || placeOf.blockId != a.blockId) {
      return null;
    }
    final key = sessionKey(week, day.j);
    try {
      final input = _adaptInput(placeOf, key);
      if (input == null) return null;
      final advice = kalisAdaptEngine.adviseNextSet(
        content.catalog!,
        kc.AdviceRequest(
          input: input,
          session: a.active,
          done: _adaptDone(week, day, a),
          slotId: it.slotId,
          healthCheck: a.activeCheck,
        ),
      );
      final log = logs[key]?.ex[e.id];
      var next = -1;
      if (log != null) {
        for (var i = index + 1; i < log.sets.length; i++) {
          if (!log.sets[i].done) {
            next = i;
            break;
          }
        }
      }
      if (advice.action == kc.IntraSessionAction.keep ||
          advice.action == kc.IntraSessionAction.restMore ||
          advice.action == kc.IntraSessionAction.stopExercise ||
          next < 0) {
        return (advice: advice, step: null);
      }
      final seconds = prescriptionInSeconds(it);
      final step = AdviceStep(
        from: next,
        action: advice.action.code,
        kg: advice.nextLoadKg,
        low: seconds ? advice.nextSeconds : advice.nextRepsLow,
        high: seconds ? advice.nextSeconds : advice.nextRepsHigh,
        status: a.assisted ? 'applied' : 'pending',
        reasons: advice.reasons,
        rest: advice.restSeconds,
      );
      final updated = a.withAdvice(e.id, step);
      _adaptStore(week, day, a, updated);
      return (advice: advice, step: step);
    } catch (_) {
      return null;
    }
  }

  /// G9 correction 1 : la note de la série [index] de [e], dernière validée,
  /// a été corrigée sous la série. Le conseil qu'elle avait produit (pour la
  /// première série non validée qui suit) est retiré, puis recalculé avec
  /// la nouvelle note.
  ({kc.IntraSessionAdvice advice, AdviceStep? step})? adaptReviseAfterSet(
    int week,
    DayPlan day,
    Exercise e,
    int index,
  ) {
    final a = sessionAdapt(week, day.j);
    if (a == null || !e.engine) return null;
    final log = logs[sessionKey(week, day.j)]?.ex[e.id];
    if (log == null || index >= log.sets.length || !log.sets[index].done) {
      return null;
    }
    var next = -1;
    for (var i = index + 1; i < log.sets.length; i++) {
      if (!log.sets[i].done) {
        next = i;
        break;
      }
    }
    final l = a.advice[e.id];
    if (l != null && l.isNotEmpty && next >= 0 && l.last.from == next) {
      _adaptStore(week, day, a, a.withoutLastAdvice(e.id));
    }
    return adaptAfterSet(week, day, e, index);
  }

  /// Conseil en attente ou appliqué de [e] : `undone` (annuler),
  /// `accepted`, `kept` (mode libre).
  void adaptAdviceDecision(int week, DayPlan day, Exercise e, String status) {
    final a = sessionAdapt(week, day.j);
    if (a == null) return;
    final updated = a.withLastAdviceStatus(e.id, status);
    _adaptStore(week, day, a, updated);
  }

  /// Dernier conseil en attente de [e] (mode libre).
  AdviceStep? adaptPendingAdvice(int week, int j, Exercise e) {
    final a = sessionAdapt(week, j);
    final l = a?.advice[e.id];
    if (l == null || l.isEmpty || l.last.status != 'pending') return null;
    return l.last;
  }

  /// Prescription affichée au journal (« Prescrit ce jour-là »).
  String adaptPrescribedText(int week, int j, Exercise e) {
    final g = adaptGoal(week, j, e, 0);
    final it = adaptItemFor(week, j, e);
    if (it == null || g == null) return '';
    return [
      if (g.kg != null && it.loadBasis != kc.LoadBasis.bodyweight)
        adaptKg(g.kg!),
      adaptSetsText(it),
      if (it.targetFlames != null) '${it.targetFlames} flammes',
    ].join(' · ');
  }

  // ------------------------------------------------------ fin de séance

  /// Résumé de Koach en fin de séance : calibrage, capacité estimée avant
  /// et après la séance, première série de la prochaine fois.
  AdaptSessionSummary? adaptSummary(int week, DayPlan base) {
    final a = sessionAdapt(week, base.j);
    final place = adaptPlaceOf(week, base.j);
    final profile = adaptProfile;
    final catalog = content.catalog;
    if (a == null || place == null || profile == null || catalog == null) {
      return null;
    }
    final key = sessionKey(week, base.j);
    try {
      final before = kalisAdaptEngine.estimates(
        catalog,
        kc.AdaptInput(
          profile: profile,
          block: place.block,
          log: adaptTrainingLog(excludeKey: key),
          today: _adaptToday,
          season: adaptSeasonOf(place),
        ),
      );
      final withLog = adaptTrainingLog();
      final after = kalisAdaptEngine.estimates(
        catalog,
        kc.AdaptInput(
          profile: profile,
          block: place.block,
          log: withLog,
          today: _adaptToday,
          season: adaptSeasonOf(place),
        ),
      );
      kc.ExerciseEstimate? find(List<kc.ExerciseEstimate> l, String id) {
        for (final x in l) {
          if (x.exerciseId == id) return x;
        }
        return null;
      }

      final day = adaptDay(week, base, a);
      final nextPlans = <String, kc.SessionPlan?>{};
      final out = <AdaptExerciseSummary>[];
      final seen = <String>{};
      final log = logs[key];
      for (final e in day.exercises) {
        if (!e.engine || e.catalogId == null) continue;
        final id = e.catalogId!;
        if (!(log?.ex[e.id]?.sets.any((s) => s.done) ?? false)) continue;
        if (!seen.add(id)) continue;
        final it = _adaptItem(a, e.slotId);
        final next = _adaptNextGoal(week, base.j, id, withLog, nextPlans);
        out.add(
          AdaptExerciseSummary(
            exerciseId: id,
            name: _adaptNameOf(id),
            calibrating:
                it != null &&
                (it.toCalibrate ||
                    it.reasons.any((r) => r.code == 'adapt.calibration')),
            before: find(before, id),
            after: find(after, id),
            next: next,
            today: it == null ? null : adaptGoal(week, base.j, e, 0),
          ),
        );
      }
      return AdaptSessionSummary(out, adaptPainReferralZones);
    } catch (_) {
      return null;
    }
  }

  /// Première série de la prochaine journée (dans les 6 semaines) où
  /// l'exercice [id] revient, prescrite avec le journal [log].
  SetGoal? _adaptNextGoal(
    int week,
    int j,
    String id,
    kc.TrainingLog log,
    Map<String, kc.SessionPlan?> cache,
  ) {
    final profile = adaptProfile;
    if (profile == null) return null;
    for (var n = week; n <= math.min(week + 6, program.weeks.length); n++) {
      for (final d in program.week(n).days) {
        if (n == week && d.j <= j) continue;
        if (d.exercises.isEmpty) continue;
        final place = adaptPlaceOf(n, d.j);
        if (place == null) continue;
        final dayItems = place.day?.items ?? const <kc.ExercisePrescription>[];
        if (!dayItems.any((it) => it.exerciseId == id)) continue;
        final k = '${place.blockId}|${place.weekIndex}|${place.dayIndex}';
        // Prescrite au jour prévu de cette séance (la fatigue du jour
        // retombe d'ici là), jamais avant aujourd'hui.
        var day = _adaptToday;
        if (program.start != null) {
          final planned = civilOf(program.dateFor(n, d.j));
          if (planned.compareTo(day) > 0) day = planned;
        }
        final plan = cache.putIfAbsent(k, () {
          try {
            return kalisAdaptEngine.prescribeSession(
              content.catalog!,
              kc.SessionRequest(
                input: kc.AdaptInput(
                  profile: profile,
                  block: place.block,
                  log: log,
                  today: day,
                ),
                weekIndex: place.weekIndex,
                dayIndex: place.dayIndex,
              ),
            );
          } catch (_) {
            return null;
          }
        });
        if (plan == null) return null;
        for (final it in plan.items) {
          if (it.exerciseId == id) return planGoal(it, 0);
        }
        return null;
      }
    }
    return null;
  }

  // ------------------------------------------------ échelle des flammes

  static const _kFlamesIntro = 'g9_flammes_expliquees_v1';

  /// La phrase qui explique l'échelle a déjà été montrée (clé de la
  /// session active, hors sauvegarde).
  bool get flamesIntroSeen => _prefs.getBool(_kFlamesIntro) ?? false;

  Future<void> markFlamesIntroSeen() async {
    if (flamesIntroSeen) return;
    await _prefs.setBool(_kFlamesIntro, true);
  }

  // ------------------------------------------------- douleur (règle L13)

  /// Douleurs du bilan pour une zone, de la séance la plus ancienne à la
  /// plus récente ; une séance dont le bilan a posé la question sans que
  /// la zone soit citée compte 0 ; une séance sans la question est exclue.
  List<int> zonePainHistory(kc.BodyZone zone) {
    final rows = <(String, String, int)>[];
    for (final e in logs.entries) {
      final a = sessionAdaptOf(e.key);
      final pains = a?.check?.pains;
      if (a == null || pains == null) continue;
      var v = 0;
      for (final p in pains) {
        if (p.zone == zone && p.intensity > v) v = p.intensity;
      }
      rows.add((a.date, e.key, v));
    }
    rows.sort((x, y) {
      final c = x.$1.compareTo(y.$1);
      return c != 0 ? c : x.$2.compareTo(y.$2);
    });
    return [for (final r in rows) r.$3];
  }

  /// Zones (libellés) dont la douleur dépasse 3/10 sur plus de 2 séances
  /// de suite : renvoi vers un professionnel (règle L13 conservée).
  List<String> get adaptPainReferralZones => [
    for (final z in kc.BodyZone.values)
      if (painNeedsReferral(zonePainHistory(z))) kZoneLabels[z] ?? z.code,
  ];
}
