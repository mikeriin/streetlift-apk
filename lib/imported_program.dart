// CI1e (dev6.10.0, pipeline CP, DECISIONS_CP.md C11) — le programme de 40
// semaines du propriétaire (et toute semaine importée : ancien programme
// L10, semaines d'avant un programme créé) passe sous toutes les
// fonctionnalités des moteurs.
//
// Annotation déterministe, faite à la lecture (le programme d'origine reste
// lisible et n'est jamais réécrit) :
//
// - découpage en blocs du moteur d'au plus 6 semaines : un bloc par bloc
//   du programme (P0, B1…), coupé après une semaine allégée quand il
//   dépasse 6 semaines (le moteur ne restructure pas un bloc plus long) ;
// - intention de chaque semaine (contrat 0.4.0 : `WeekIntent`) d'après la
//   nature de la semaine (allégée, test) et le titre du bloc et du cycle
//   (phase 0 tests, hypertrophie, force, force max, endurance, peaking) ;
// - intention du bloc (`BlockIntent` : phase, rang dans la saison,
//   échéance) et plan de saison (`SeasonPlan`) dont l'échéance est la fin
//   de la dernière semaine importée (S40 pour le propriétaire) ;
// - rôle de chaque ligne : intensité visée en RIR (`IntensityTarget`),
//   tests de répétitions ou de maintien max (`TestSpec`), test de 1RM
//   (montée en singles puis tentatives : lignes `warmup` puis `attempt`),
//   clusters (`SetTechnique.cluster`) ;
// - emplacements stables d'une semaine à l'autre (`j<J>-<exercice>`) : le
//   moteur suit la même ligne de semaine en semaine (marques de séance,
//   double progression).
//
// Ce qui ne se déduit pas proprement du texte du programme reste absent
// (myo-reps, échelles, tours, EMOM, contrastes, durées, intervalles) :
// ces lignes restent servies telles qu'écrites. Liste : [ImportedProgram.absent].
part of 'store.dart';

/// Échéance de la fin du programme importé (C11 : fin de S40).
const kImportedEventId = 'kt-fin-programme-importe';

/// Bloc du moteur tiré du programme importé.
class ImportedSegment {
  /// Rang du bloc (0 = premier).
  final int index;

  /// Première et dernière semaines (S) du bloc.
  final int first;
  final int last;

  /// Titre du bloc du programme (« Bloc 2 — Force »).
  final String label;
  final kc.SeasonPhaseKind phase;
  final kc.ProgramBlock block;

  /// Journée du bloc (dayIndex) de chaque journée J de la semaine.
  final Map<int, int> dayOfJ;
  const ImportedSegment({
    required this.index,
    required this.first,
    required this.last,
    required this.label,
    required this.phase,
    required this.block,
    required this.dayOfJ,
  });

  int get weeks => last - first + 1;
  String get blockId => block.pass1.blockId;
  bool contains(int week) => week >= first && week <= last;
}

/// Programme importé annoté au contrat 0.4.0.
class ImportedProgram {
  final List<ImportedSegment> segments;
  final kc.SeasonPlan? season;

  /// Échéance de la fin du programme (null : départ inconnu).
  final kc.SeasonEvent? event;

  /// Emplacement de chaque exercice porté : « S|id » → emplacement (un
  /// exercice déplacé d'un jour à l'autre par Koach garde le sien).
  final Map<String, String> slots;

  /// Lignes du programme non portées (format sans équivalent au contrat),
  /// par libellé de série : « 1×15 puis 4×(4) » → nombre.
  final Map<String, int> absent;
  const ImportedProgram({
    required this.segments,
    required this.season,
    required this.event,
    required this.slots,
    required this.absent,
  });

  ImportedSegment? segmentOf(int week) {
    for (final s in segments) {
      if (s.contains(week)) return s;
    }
    return null;
  }

  ImportedSegment? byBlockId(String id) {
    for (final s in segments) {
      if (s.blockId == id) return s;
    }
    return null;
  }

  String? slotOf(int week, int j, String exerciseId) =>
      slots['$week|${exerciseId.split('~').first}'];
}

/// Identifiant du bloc importé qui commence à la semaine [first].
String importedBlockId(int first) => '$kLegacyProgramBlockId/S$first';

/// Découpage des semaines [first]..[last] en blocs : un par bloc du
/// programme ([keyOf]), coupé après une semaine allégée ([deload]) quand
/// il dépasse 6 semaines, puis en parts égales s'il en reste de trop
/// longues. Pur et déterministe (testé).
List<(int, int)> importedRanges(
  int first,
  int last,
  String Function(int week) keyOf,
  bool Function(int week) deload,
) {
  final out = <(int, int)>[];
  if (last < first) return out;
  var a = first;
  for (var n = first; n <= last; n++) {
    if (n == last || keyOf(n + 1) != keyOf(n)) {
      out.addAll(_splitRange(a, n, deload));
      a = n + 1;
    }
  }
  return out;
}

List<(int, int)> _splitRange(int a, int b, bool Function(int) deload) {
  if (b - a + 1 <= 6) return [(a, b)];
  final parts = <(int, int)>[];
  var s = a;
  for (var n = a; n < b; n++) {
    // Fin de cycle : après une semaine allégée, au moins 3 semaines dans
    // la part.
    if (deload(n) && n - s + 1 >= 3) {
      parts.add((s, n));
      s = n + 1;
    }
  }
  parts.add((s, b));
  final out = <(int, int)>[];
  for (final (x, y) in parts) {
    final len = y - x + 1;
    if (len <= 6) {
      out.add((x, y));
      continue;
    }
    final k = (len + 5) ~/ 6;
    var at = x;
    for (var i = 0; i < k; i++) {
      final size = len ~/ k + (i < len % k ? 1 : 0);
      out.add((at, at + size - 1));
      at += size;
    }
  }
  return out;
}

/// Phase d'un titre de bloc ou de cycle (null : rien de reconnu).
kc.SeasonPhaseKind? importedPhaseOf(String text) {
  final t = normalizeText(text);
  if (t.contains('peaking') ||
      t.contains('pic') ||
      t.contains('singles') ||
      t.contains('simulation') ||
      t.contains('force max')) {
    return kc.SeasonPhaseKind.realization;
  }
  if (t.contains('force') || t.contains('reintensification')) {
    return kc.SeasonPhaseKind.intensification;
  }
  if (t.contains('hypertrophie') ||
      t.contains('endurance') ||
      t.contains('volume') ||
      t.contains('familiarisation')) {
    return kc.SeasonPhaseKind.accumulation;
  }
  if (t.contains('test') || t.contains('phase 0')) {
    return kc.SeasonPhaseKind.test;
  }
  return null;
}

kc.WeekIntent _intentOfPhase(kc.SeasonPhaseKind p) => switch (p) {
  kc.SeasonPhaseKind.intensification => kc.WeekIntent.intensification,
  kc.SeasonPhaseKind.realization => kc.WeekIntent.realization,
  kc.SeasonPhaseKind.test => kc.WeekIntent.test,
  kc.SeasonPhaseKind.deload => kc.WeekIntent.deload,
  _ => kc.WeekIntent.accumulation,
};

kc.SeasonPhaseKind? _phaseOfIntent(kc.WeekIntent i) => switch (i) {
  kc.WeekIntent.accumulation ||
  kc.WeekIntent.intro => kc.SeasonPhaseKind.accumulation,
  kc.WeekIntent.intensification => kc.SeasonPhaseKind.intensification,
  kc.WeekIntent.realization => kc.SeasonPhaseKind.realization,
  _ => null,
};

extension ImportedProgramStore on AppStore {
  /// Dernière semaine (S) portée par les blocs importés.
  int get importedLastWeek {
    final plan = planProgram;
    return plan == null ? program.weeks.length : plan.firstWeek - 1;
  }

  /// Programme importé annoté (null : rien d'importé, base ou profil
  /// absents).
  ImportedProgram? get importedProgram {
    final catalog = content.catalog;
    final book = _adaptBookForImport();
    if (catalog == null || book == null) return null;
    final sig = [
      'imported',
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
        return _buildImported(catalog, book);
      } catch (_) {
        return null;
      }
    });
  }

  ka.ExerciseBook? _adaptBookForImport() =>
      SessionAdaptStore(this)._adaptBook();

  ImportedProgram? _buildImported(kc.Catalog catalog, ka.ExerciseBook book) {
    final lastWeek = math.min(importedLastWeek, program.weeks.length);
    if (lastWeek < 1) return null;
    final start = program.start;
    String keyOf(int n) {
      final w = program.week(n);
      return w.blockKey.isEmpty ? w.block : w.blockKey;
    }

    final ranges = importedRanges(1, lastWeek, keyOf, weekKinds.isDeload);
    final absent = <String, int>{};
    final slots = <String, String>{};
    final eventDay = start == null
        ? null
        : civilOf(DateTime(start.year, start.month, start.day + lastWeek * 7 - 1));
    final event = eventDay == null
        ? null
        : kc.SeasonEvent(
            id: kImportedEventId,
            kind: kc.EventKind.personalTest,
            priority: kc.EventPriority.main,
            date: eventDay,
            name: 'Fin du programme (S$lastWeek)',
          );
    // Intentions des semaines.
    final intents = <int, kc.WeekIntent>{};
    for (var n = 1; n <= lastWeek; n++) {
      final w = program.week(n);
      final cycle = w.days.isEmpty ? '' : w.days.first.cycle;
      final blockPhase = importedPhaseOf(w.block);
      if (weekKinds.isDeload(n)) {
        intents[n] = kc.WeekIntent.deload;
      } else if (weekKinds.isTest(n)) {
        intents[n] = kc.WeekIntent.test;
      } else if (w.blockKey == 'P0' ||
          normalizeText(cycle).contains('familiarisation')) {
        intents[n] = kc.WeekIntent.intro;
      } else {
        final p =
            importedPhaseOf(cycle) ??
            blockPhase ??
            kc.SeasonPhaseKind.accumulation;
        intents[n] = _intentOfPhase(
          p == kc.SeasonPhaseKind.test ? kc.SeasonPhaseKind.accumulation : p,
        );
      }
    }
    // Phase de chaque bloc : la plus fréquente de ses semaines de charge ;
    // égalité : celle du titre du bloc ; aucune : test.
    final phases = <kc.SeasonPhaseKind>[];
    for (final (a, b) in ranges) {
      final count = <kc.SeasonPhaseKind, int>{};
      for (var n = a; n <= b; n++) {
        final p = _phaseOfIntent(intents[n]!);
        if (p != null && intents[n] != kc.WeekIntent.intro) {
          count[p] = (count[p] ?? 0) + 1;
        }
      }
      if (count.isEmpty) {
        phases.add(kc.SeasonPhaseKind.test);
        continue;
      }
      final top = count.values.reduce(math.max);
      final best = [
        for (final e in count.entries)
          if (e.value == top) e.key,
      ];
      final label = importedPhaseOf(program.week(a).block);
      phases.add(
        best.length > 1 && label != null && best.contains(label)
            ? label
            : best.first,
      );
    }
    // Plan de saison : blocs consécutifs de même phase réunis.
    final seasonPhases = <kc.SeasonPhase>[];
    final phaseIndexOf = <int>[];
    if (start != null) {
      for (var i = 0; i < ranges.length; i++) {
        final (a, b) = ranges[i];
        if (seasonPhases.isNotEmpty &&
            seasonPhases.last.kind == phases[i] &&
            seasonPhases.last.weeks + (b - a + 1) <= 26) {
          final p = seasonPhases.removeLast();
          seasonPhases.add(p.copyWith(weeks: p.weeks + (b - a + 1)));
        } else {
          seasonPhases.add(
            kc.SeasonPhase(
              index: seasonPhases.length,
              kind: phases[i],
              startDate: civilOf(
                DateTime(start.year, start.month, start.day + (a - 1) * 7),
              ),
              weeks: b - a + 1,
              reasons: const <kc.Reason>[],
            ),
          );
        }
        phaseIndexOf.add(seasonPhases.length - 1);
      }
      if (event != null && seasonPhases.isNotEmpty) {
        final p = seasonPhases.removeLast();
        seasonPhases.add(p.copyWith(eventId: kImportedEventId));
      }
    }
    kc.SeasonPlan? season;
    if (seasonPhases.isNotEmpty) {
      final s = kc.SeasonPlan(
        createdOn: civilOf(start!),
        engineVersion: 'import',
        eventIds: [if (event != null) kImportedEventId],
        phases: seasonPhases,
        reasons: const <kc.Reason>[],
      );
      season = s.validate().isEmpty ? s : null;
    }
    final segments = <ImportedSegment>[];
    for (var i = 0; i < ranges.length; i++) {
      final (a, b) = ranges[i];
      final seg = _buildSegment(
        index: i,
        first: a,
        last: b,
        phase: phases[i],
        intents: intents,
        seasonPhaseIndex: season == null ? null : phaseIndexOf[i],
        event: season == null ? null : event,
        catalog: catalog,
        book: book,
        slots: slots,
        absent: absent,
      );
      if (seg != null) segments.add(seg);
    }
    if (segments.isEmpty) return null;
    return ImportedProgram(
      segments: segments,
      season: season,
      event: season == null ? null : event,
      slots: slots,
      absent: absent,
    );
  }

  ImportedSegment? _buildSegment({
    required int index,
    required int first,
    required int last,
    required kc.SeasonPhaseKind phase,
    required Map<int, kc.WeekIntent> intents,
    required int? seasonPhaseIndex,
    required kc.SeasonEvent? event,
    required kc.Catalog catalog,
    required ka.ExerciseBook book,
    required Map<String, String> slots,
    required Map<String, int> absent,
  }) {
    final weeks =
        <
          (
            int,
            kc.WeekKind,
            kc.WeekIntent,
            Map<int, List<kc.ExercisePrescription>>,
          )
        >[];
    final js = <int>{};
    final slotExercise = <String, String>{};
    final slotRole = <String, kc.SlotRole>{};
    for (var n = first; n <= last; n++) {
      final w = program.week(n);
      final days = <int, List<kc.ExercisePrescription>>{};
      // Toujours le programme d'origine (sans la couche de Koach).
      for (final d in [for (final x in w.days) x.original]) {
        final items = <kc.ExercisePrescription>[];
        final seen = <String, int>{};
        for (final e in d.exercises) {
          final it = _importItem(e, d.j, catalog, book);
          if (it == null) {
            final label = setsLabel(e).trim();
            if (label.isNotEmpty && label != '—') {
              final k = label.replaceAll(RegExp(r'\d+'), 'N');
              absent[k] = (absent[k] ?? 0) + 1;
            }
            continue;
          }
          // Emplacement stable : même exercice, même journée, même rang.
          final base = 'j${d.j}-${it.$1.exerciseId}';
          final k = (seen[base] ?? 0) + 1;
          seen[base] = k;
          final slot = k == 1 ? base : '$base#$k';
          final item = it.$1.copyWith(slotId: slot);
          items.add(item);
          slots['$n|${e.id.split('~').first}'] = slot;
          slotExercise.putIfAbsent(slot, () => item.exerciseId);
          if (it.$2 == kc.SlotRole.main || !slotRole.containsKey(slot)) {
            slotRole[slot] = it.$2;
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
      weeks.add((n - first, kind, intents[n]!, days));
    }
    if (js.isEmpty) return null;
    final ordered = js.toList()..sort();
    final dayOfJ = {for (var i = 0; i < ordered.length; i++) ordered[i]: i};
    final start = program.start;
    final startDay = start == null
        ? civilOf(storeClock())
        : civilOf(DateTime(start.year, start.month, start.day + (first - 1) * 7));
    final blockId = importedBlockId(first);
    final slotList = slotExercise.keys.toList()..sort();
    int? weeksToEvent;
    if (event != null) {
      final d = event.date.dayNumber - startDay.dayNumber;
      weeksToEvent = (d ~/ 7).clamp(0, 104);
    }
    final pass1 = kc.Pass1Plan(
      blockId: blockId,
      blockIndex: index,
      weeks: weeks.length,
      startDate: startDay,
      seed: 0,
      engineVersion: 'import',
      days: [
        for (final j in ordered)
          kc.PlanDay(
            dayIndex: dayOfJ[j]!,
            weekday: SessionAdaptStore(this)._adaptWeekday(j),
            minutesBudget: 90,
            focus: 'imported',
            slots: [
              for (final s in slotList)
                if (s.startsWith('j$j-'))
                  kc.PlanSlot(
                    slotId: s,
                    exerciseId: slotExercise[s]!,
                    role: slotRole[s]!,
                    // C11 : échanges et restructurations permis.
                    locked: false,
                    reasons: const <kc.Reason>[],
                  ),
            ],
          ),
      ],
      score: const kc.PlanScore(total: 0, components: <kc.ScoreComponent>[]),
      reasons: const <kc.Reason>[],
      intent: kc.BlockIntent(
        phase: phase,
        seasonPhaseIndex: seasonPhaseIndex,
        eventId: event?.id,
        weeksToEvent: weeksToEvent,
      ),
    );
    final pass2 = kc.Pass2Plan(
      blockId: blockId,
      engineVersion: 'import',
      weeks: [
        for (final (i, kind, intent, days) in weeks)
          kc.WeekPrescription(
            weekIndex: i,
            kind: kind,
            intent: intent,
            days: [
              for (final j in ordered)
                if (days.containsKey(j))
                  kc.DayPrescription(dayIndex: dayOfJ[j]!, items: days[j]!),
            ],
          ),
      ],
      reasons: const <kc.Reason>[],
    );
    var block = kc.ProgramBlock(pass1: pass1, pass2: pass2);
    if (block.validate().isNotEmpty) {
      // Intention du bloc hors contrat : bloc sans elle (les semaines
      // gardent la leur).
      block = kc.ProgramBlock(
        pass1: pass1.copyWith(intent: null),
        pass2: pass2,
      );
      if (block.validate().isNotEmpty) return null;
    }
    return ImportedSegment(
      index: index,
      first: first,
      last: last,
      label: program.week(first).block,
      phase: phase,
      block: block,
      dayOfJ: dayOfJ,
    );
  }

  /// Prescription portée d'un exercice du programme (null : sans
  /// équivalent dans la base, ou format sans équivalent au contrat).
  (kc.ExercisePrescription, kc.SlotRole)? _importItem(
    Exercise e,
    int j,
    kc.Catalog catalog,
    ka.ExerciseBook book,
  ) {
    final base = SessionAdaptStore(this)._adaptImportItem(e, j, catalog, book);
    if (base == null) return _importSpecial(e, j, catalog, book);
    final (it, role) = base;
    final rich = _annotate(e, it);
    return (rich, role);
  }

  /// Champs 0.4.0 d'une prescription simple : intensité en RIR, test de
  /// répétitions ou de maintien max. Rien n'est ajouté qui ne se lise
  /// dans le programme ; une annotation hors contrat est retirée.
  kc.ExercisePrescription _annotate(Exercise e, kc.ExercisePrescription it) {
    var out = it;
    if (it.kind == kc.SetKind.test) {
      final timed = it.secondsLow != null;
      out = out.copyWith(
        test: kc.TestSpec(
          kind: timed ? kc.TestKind.maxHold : kc.TestKind.maxReps,
          benchmarkKind: timed
              ? kc.BenchmarkKind.maxHold
              : kc.BenchmarkKind.maxReps,
        ),
      );
    } else {
      final rir = _rirRange(e.intensity);
      if (rir != null) {
        out = out.copyWith(
          intensity: kc.IntensityTarget(
            basis: kc.IntensityBasis.rir,
            value: rir.$1,
            valueHigh: rir.$2 > rir.$1 ? rir.$2 : null,
          ),
        );
      }
    }
    if (out.validate().isNotEmpty) {
      // Flammes hors de la plage écrite, par exemple : prescription
      // simple, comme avant CI1e.
      return it;
    }
    return out;
  }

  static (double, double)? _rirRange(String intensity) {
    final m = RegExp(
      r'RIR\s*(\d+(?:[.,]\d+)?)(?:\s*-\s*(\d+(?:[.,]\d+)?))?',
    ).firstMatch(intensity);
    if (m == null) return null;
    final a = double.parse(m.group(1)!.replaceAll(',', '.'));
    final b = m.group(2) == null
        ? a
        : double.parse(m.group(2)!.replaceAll(',', '.'));
    if (a > 10 || b > 10 || b < a) return null;
    return (a, b);
  }

  /// Formats que la portée simple ne lit pas mais que le contrat décrit :
  /// clusters (« 6×3 en clusters (30 s intra) ») et test de 1RM
  /// (« Montée en singles puis 3 tentatives » : 3 montées, puis les
  /// tentatives).
  (kc.ExercisePrescription, kc.SlotRole)? _importSpecial(
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
    if (cat.unit == kc.MeasureUnit.seconds) return null;
    final sp = logSpec(e);
    final text = setsLabel(e).toLowerCase().trim();
    final n = setCount(e);
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
    final loaded = info.mode == ka.CapacityMode.loaded;
    double? startKg;
    if (loaded && basis != kc.LoadBasis.bodyweight) {
      final kg = loadFor(e);
      if (kg != null && kg >= 0 && kg <= 1000) {
        startKg = (kg * 100).roundToDouble() / 100;
        if (basis == kc.LoadBasis.external && startKg <= 0) startKg = null;
      }
    }
    final role = e.main ? kc.SlotRole.main : kc.SlotRole.secondary;
    final slot = SessionAdaptStore.importedSlot(j, e.id);
    kc.ExercisePrescription? it;
    if (sp.cluster && sp.rowPrefix == 'C') {
      final m = RegExp(
        r'^(\d+)\s*[×x]\s*(\d+)\s*en clusters?\s*\((\d+)\s*s intra\)',
      ).firstMatch(text);
      if (m == null) return null;
      final sets = int.parse(m.group(1)!);
      final reps = int.parse(m.group(2)!);
      final intra = int.parse(m.group(3)!);
      if (sets < 1 || sets > 20 || reps < 1 || reps > 20) return null;
      if (intra < 1 || intra > 120) return null;
      final rir = _rirRange(e.intensity);
      it = kc.ExercisePrescription(
        slotId: slot,
        exerciseId: id,
        sets: sets,
        repsLow: reps,
        repsHigh: reps,
        targetFlames: rir == null
            ? null
            : kc.Flames.fromRir((rir.$1 + rir.$2) / 2),
        restSeconds: e.restSec?.clamp(0, 900),
        startLoadKg: startKg,
        toCalibrate: false,
        loadBasis: basis,
        reasons: const <kc.Reason>[],
        technique: kc.SetTechnique(
          kind: kc.SetTechniqueKind.cluster,
          miniSets: reps,
          miniSetReps: 1,
          intraRestSeconds: intra,
        ),
        intensity: rir == null
            ? null
            : kc.IntensityTarget(
                basis: kc.IntensityBasis.rir,
                value: rir.$1,
                valueHigh: rir.$2 > rir.$1 ? rir.$2 : null,
              ),
      );
    } else if (sp.rowPrefix == 'T' &&
        text.contains('montée') &&
        text.contains('tentative') &&
        n == 6) {
      final tries = RegExp(r'(\d+)\s*tentatives').firstMatch(text);
      final attempts = tries == null ? 3 : int.parse(tries.group(1)!);
      it = kc.ExercisePrescription(
        slotId: slot,
        exerciseId: id,
        sets: n,
        repsLow: 1,
        repsHigh: 1,
        targetFlames: kc.Flames.failure,
        restSeconds: e.restSec?.clamp(0, 900),
        startLoadKg: startKg,
        toCalibrate: false,
        loadBasis: basis,
        kind: kc.SetKind.test,
        reasons: const <kc.Reason>[],
        setTargets: [
          for (var i = 0; i < n; i++)
            kc.SetTarget(
              repsLow: 1,
              repsHigh: 1,
              role: i < n - 3 ? kc.SetRole.warmup : kc.SetRole.attempt,
            ),
        ],
        test: kc.TestSpec(
          kind: kc.TestKind.oneRm,
          attempts: attempts.clamp(1, 6),
          benchmarkKind: kc.BenchmarkKind.loadReps,
        ),
      );
    }
    if (it == null || it.validate().isNotEmpty) return null;
    return (it, role);
  }
}
