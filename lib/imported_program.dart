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
// CI1f (C11.6) : les formats propres du programme sont annotés à leur tour :
// myo-reps (activation puis mini-séries, technique `myo_reps`), durées
// (mobilité, cardio léger : prescription en secondes, conduite de
// l'endurance de `kalis_adapt` 0.3.0), HIIT (groupe `intervals`), EMOM
// (technique `emom`, une ligne par minute, dans un groupe `emom` qui réunit
// les exercices enchaînés), contrastes et échelles (groupes `circuit` :
// tours ; lignes servies telles qu'écrites, le moteur ne règle pas leurs
// répétitions : une échelle ou un contraste n'est pas une série d'une
// traite) ; « N × ? reps » : maximum de référence estimé d'après le profil
// (test reporté) ou le journal, sinon servi tel qu'écrit.
//
// Ce qui ne se déduit toujours pas proprement reste absent, servi tel
// qu'écrit. Liste : [ImportedProgram.absent].
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

  /// CI1f : emplacements servis tels qu'écrits (contrastes, échelles) :
  /// dans le bloc et dans leur groupe, mais l'application garde la ligne
  /// du programme (le moteur ne règle pas leurs répétitions).
  final Set<String> asWritten;

  /// CI1f : exercice du bloc quand il diffère du nom de la ligne
  /// (contraste du squat : squat sauté), par emplacement.
  final Map<String, String> exerciseOf;

  /// CI1f : références estimées pour « N × ? reps » : référence →
  /// (valeur, source).
  final Map<String, (double, String)> estimates;
  const ImportedProgram({
    required this.segments,
    required this.season,
    required this.event,
    required this.slots,
    required this.absent,
    this.asWritten = const {},
    this.exerciseOf = const {},
    this.estimates = const {},
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

/// CI1f : ligne du programme portée au contrat : prescription, rôle de
/// l'emplacement, groupe (format et paramètres ; son identifiant est posé
/// par la journée) et service tel qu'écrit (contrastes, échelles).
class _ImportedLine {
  final kc.ExercisePrescription item;
  final kc.SlotRole role;
  final kc.GroupSpec? group;
  final bool asWritten;
  const _ImportedLine(
    this.item,
    this.role, {
    this.group,
    this.asWritten = false,
  });
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

  /// CI1e : ajustements de Koach décidés avant 6.10.0 sur le bloc importé
  /// unique (`legacy-programme-v33`, 40 semaines) ramenés sur les blocs
  /// annotés : même changement, nouveau bloc, semaine et journée du bloc,
  /// emplacement stable. Un ajustement qui couvre plusieurs blocs est
  /// partagé en un ajustement par bloc. Une restructuration (bloc entier,
  /// impossible sur ce bloc avant 6.10.0) reste telle quelle. Vrai si
  /// l'évolution a changé.
  bool migrateLegacyEvolution() {
    if (_evoRaw != null) return false;
    if (!planEvolution.entries.any((e) => e.blockId == kLegacyProgramBlockId)) {
      return false;
    }
    final next = convertLegacyEntries(planEvolution.entries);
    if (next == null) return false;
    planEvolution = planEvolution.withEntries(next);
    _evoRevision++;
    _evoRefreshKey = '';
    SessionAdaptStore(this).syncImportedOverlay();
    return true;
  }

  /// Conversion de [entries] (null : programme importé indisponible).
  List<EvolutionEntry>? convertLegacyEntries(List<EvolutionEntry> entries) {
    final imp = importedProgram;
    if (imp == null) return null;
    final last = math.min(importedLastWeek, program.weeks.length);
    // Journées du bloc unique d'avant : J avec des exercices, dans l'ordre.
    final oldJs = <int>{
      for (var n = 1; n <= last; n++)
        for (final d in program.week(n).days)
          if (d.original.exercises.isNotEmpty) d.j,
    }.toList()..sort();
    final out = <EvolutionEntry>[];
    for (final e in entries) {
      final changes = e.proposal.diff?.changes;
      if (e.blockId != kLegacyProgramBlockId ||
          e.proposal.block != null ||
          changes == null ||
          changes.isEmpty) {
        out.add(e);
        continue;
      }
      final bySeg = <ImportedSegment, List<Map<String, Object?>>>{};
      for (final c in changes) {
        final week = (c.weekIndex ?? e.fromWeek) + 1;
        final seg = imp.segmentOf(week);
        if (seg == null) continue;
        final j = c.dayIndex == null || c.dayIndex! >= oldJs.length
            ? null
            : oldJs[c.dayIndex!];
        String? slot(String? old) {
          if (old == null || j == null) return old;
          final m = RegExp(r'^j\d-(.+)$').firstMatch(old);
          if (m == null) return old;
          return imp.slotOf(week, j, m[1]!) ?? old;
        }

        Object? item(kc.ExercisePrescription? x) =>
            x?.copyWith(slotId: slot(x.slotId) ?? x.slotId).toJson();
        final m = c.toJson();
        m['weekIndex'] = week - seg.first;
        if (c.dayIndex != null) {
          final d = j == null ? null : seg.dayOfJ[j];
          if (d == null) continue;
          m['dayIndex'] = d;
        }
        if (c.slotId != null) m['slotId'] = slot(c.slotId);
        if (c.fromPrescription != null) {
          m['fromPrescription'] = item(c.fromPrescription);
        }
        if (c.toPrescription != null) {
          m['toPrescription'] = item(c.toPrescription);
        }
        (bySeg[seg] ??= []).add(m);
      }
      if (bySeg.isEmpty) {
        out.add(e);
        continue;
      }
      final segs = bySeg.keys.toList()..sort((a, b) => a.first - b.first);
      final at = e.id.lastIndexOf('@');
      final base = at < 0 ? e.id : e.id.substring(0, at);
      final conv = <EvolutionEntry>[];
      try {
        for (final seg in segs) {
          final from = math.max(0, e.fromWeek + 1 - seg.first);
          final id = '$base${segs.length > 1 ? '#S${seg.first}' : ''}@$from';
          final pj = e.proposal.toJson();
          final diff = Map<String, Object?>.of(
            (pj['diff']! as Map).cast<String, Object?>(),
          )..['changes'] = bySeg[seg];
          final p = kc.Proposal.fromJson({...pj, 'id': id, 'diff': diff});
          if (p.validate().isNotEmpty) throw const FormatException();
          conv.add(
            EvolutionEntry.fromJson({
              ...e.toJson(),
              'proposal': p.toJson(),
              'blockId': seg.blockId,
            }),
          );
        }
      } catch (_) {
        // Ajustement illisible une fois ramené : gardé tel quel.
        out.add(e);
        continue;
      }
      out.addAll(conv);
    }
    return out;
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
    final asWritten = <String>{};
    final exerciseOf = <String, String>{};
    final estimates = _importEstimates(book);
    final eventDay = start == null
        ? null
        : civilOf(
            DateTime(start.year, start.month, start.day + lastWeek * 7 - 1),
          );
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
        final c = normalizeText(cycle);
        var p =
            importedPhaseOf(cycle) ??
            blockPhase ??
            kc.SeasonPhaseKind.accumulation;
        // « pic de volume » d'un bloc d'hypertrophie ou d'endurance : pointe
        // de volume, pas réalisation ; montée d'un bloc de force max :
        // intensification.
        if (p == kc.SeasonPhaseKind.realization &&
            blockPhase == kc.SeasonPhaseKind.accumulation &&
            !c.contains('singles') &&
            !c.contains('simulation')) {
          p = kc.SeasonPhaseKind.accumulation;
        }
        if (blockPhase == kc.SeasonPhaseKind.realization &&
            c.contains('montee')) {
          p = kc.SeasonPhaseKind.intensification;
        }
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
        asWritten: asWritten,
        exerciseOf: exerciseOf,
        estimates: estimates,
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
      asWritten: asWritten,
      exerciseOf: exerciseOf,
      estimates: estimates,
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
    required Set<String> asWritten,
    required Map<String, String> exerciseOf,
    required Map<String, (double, String)> estimates,
  }) {
    final weeks =
        <
          (
            int,
            kc.WeekKind,
            kc.WeekIntent,
            Map<int, List<kc.ExercisePrescription>>,
            Map<int, List<kc.GroupSpec>>,
          )
        >[];
    final js = <int>{};
    final slotExercise = <String, String>{};
    final slotRole = <String, kc.SlotRole>{};
    for (var n = first; n <= last; n++) {
      final w = program.week(n);
      final days = <int, List<kc.ExercisePrescription>>{};
      final dayGroups = <int, List<kc.GroupSpec>>{};
      // Toujours le programme d'origine (sans la couche de Koach).
      for (final d in [for (final x in w.days) x.original]) {
        final items = <kc.ExercisePrescription>[];
        final groups = <kc.GroupSpec>[];
        final seen = <String, int>{};
        for (final e in d.exercises) {
          final it = _importItem(e, d.j, catalog, book, estimates);
          if (it == null) {
            final label = setsLabel(e).trim();
            if (label.isNotEmpty && label != '—') {
              final k = label.replaceAll(RegExp(r'\d+'), 'N');
              absent[k] = (absent[k] ?? 0) + 1;
            }
            continue;
          }
          // Emplacement stable : même exercice, même journée, même rang.
          final base = 'j${d.j}-${it.item.exerciseId}';
          final k = (seen[base] ?? 0) + 1;
          seen[base] = k;
          final slot = k == 1 ? base : '$base#$k';
          var item = it.item.copyWith(slotId: slot);
          // CI1f : groupe de la ligne ; une ligne « enchaînée » rejoint le
          // groupe de même format de la ligne d'avant.
          final g = it.group;
          if (g != null) {
            final prev = items.isEmpty ? null : items.last.groupId;
            final joined =
                normalizeText(e.name).contains('enchain') && prev != null
                ? groups.where((x) => x.groupId == prev).firstOrNull
                : null;
            if (joined != null && joined.format == g.format) {
              item = item.copyWith(groupId: joined.groupId);
            } else {
              final id = 'g$slot';
              groups.add(g.copyWith(groupId: id));
              item = item.copyWith(groupId: id);
            }
          }
          items.add(item);
          slots['$n|${e.id.split('~').first}'] = slot;
          if (it.asWritten) asWritten.add(slot);
          final named = content.idFor(e.name);
          if (named != null && named != item.exerciseId) {
            exerciseOf[slot] = item.exerciseId;
          }
          slotExercise.putIfAbsent(slot, () => item.exerciseId);
          if (it.role == kc.SlotRole.main || !slotRole.containsKey(slot)) {
            slotRole[slot] = it.role;
          }
        }
        if (items.isNotEmpty) {
          days[d.j] = items;
          if (groups.isNotEmpty) dayGroups[d.j] = groups;
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
      weeks.add((n - first, kind, intents[n]!, days, dayGroups));
    }
    if (js.isEmpty) return null;
    final ordered = js.toList()..sort();
    final dayOfJ = {for (var i = 0; i < ordered.length; i++) ordered[i]: i};
    final start = program.start;
    final startDay = start == null
        ? civilOf(storeClock())
        : civilOf(
            DateTime(start.year, start.month, start.day + (first - 1) * 7),
          );
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
        for (final (i, kind, intent, days, groups) in weeks)
          kc.WeekPrescription(
            weekIndex: i,
            kind: kind,
            intent: intent,
            days: [
              for (final j in ordered)
                if (days.containsKey(j))
                  kc.DayPrescription(
                    dayIndex: dayOfJ[j]!,
                    items: days[j]!,
                    groups: groups[j],
                  ),
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
    }
    if (block.validate().isNotEmpty) {
      // Toujours hors contrat : bloc porté comme avant 6.10.0, sans champ
      // 0.4.0 (servi par la règle générale plutôt que perdu).
      block = kc.ProgramBlock(
        pass1: pass1.copyWith(intent: null),
        pass2: pass2.copyWith(
          weeks: [
            for (final w in pass2.weeks)
              w.copyWith(
                intent: null,
                days: [
                  for (final d in w.days)
                    d.copyWith(
                      groups: null,
                      items: [
                        for (final it in d.items)
                          if (it.technique == null &&
                              it.test?.kind != kc.TestKind.oneRm)
                            it.copyWith(
                              intensity: null,
                              test: null,
                              groupId: null,
                            ),
                      ],
                    ),
                ],
              ),
          ],
        ),
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
  _ImportedLine? _importItem(
    Exercise e,
    int j,
    kc.Catalog catalog,
    ka.ExerciseBook book,
    Map<String, (double, String)> estimates,
  ) {
    final base = SessionAdaptStore(this)._adaptImportItem(e, j, catalog, book);
    if (base == null) {
      final special = _importSpecial(e, j, catalog, book);
      if (special != null) return _ImportedLine(special.$1, special.$2);
      return _importFormat(e, j, catalog, book, estimates);
    }
    final (it, role) = base;
    final rich = _annotate(e, it);
    return _ImportedLine(rich, role);
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

  /// CI1f : maximums de référence (Références, « Tractions (max) »…) non
  /// renseignés, estimés d'après le profil (test reporté, réponse du
  /// questionnaire) ou, à défaut, d'après le meilleur test de répétitions
  /// au maximum du journal. Référence → (valeur, source).
  Map<String, (double, String)> _importEstimates(ka.ExerciseBook book) {
    final out = <String, (double, String)>{};
    final profile = adaptProfile;
    for (final r in program.pilotage.repMax) {
      if (values.containsKey(r.ref)) continue;
      final id = content.idFor(r.name);
      if (id == null) continue;
      kc.Benchmark? best;
      for (final b in profile?.benchmarks ?? const <kc.Benchmark>[]) {
        if (b.exerciseId != id || b.kind != kc.BenchmarkKind.maxReps) {
          continue;
        }
        final reps = b.reps;
        if (reps == null || reps < 1) continue;
        final later =
            best == null ||
            (b.date?.dayNumber ?? -1) > (best.date?.dayNumber ?? -1);
        if (later) best = b;
      }
      if (best != null) {
        out[r.ref] = (best.reps!.toDouble(), 'profile');
        continue;
      }
      var top = 0;
      for (final log in logs.entries) {
        final m = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(log.key);
        if (m == null) continue;
        final w = int.parse(m[1]!), jj = int.parse(m[2]!);
        if (w < 1 || w > program.weeks.length) continue;
        final d = program.week(w).day(jj);
        if (d == null) continue;
        for (final e in d.original.exercises) {
          final x = log.value.ex[e.id];
          if (x == null || content.idFor(e.name) != id) continue;
          if (logSpec(e).kind != 'repsMax') continue;
          for (final set in x.sets) {
            if (!set.done || set.excluded) continue;
            final v = parseWholeNumber(set.reps);
            if (v != null && v > top) top = v;
          }
        }
      }
      if (top > 0) out[r.ref] = (top.toDouble(), 'journal');
    }
    return out;
  }

  /// CI1f : « N × ? reps » servi sur une référence estimée : ce que Koach
  /// en dit (null : référence renseignée, ou rien d'estimé).
  String? referenceEstimateText(Exercise e) {
    final s = e.sets;
    if (s.type != 'volume' || values.containsKey(s.ref)) return null;
    final est = importedProgram?.estimates[s.ref];
    if (est == null) return null;
    final v = est.$1 == est.$1.roundToDouble()
        ? est.$1.toInt().toString()
        : est.$1.toString().replaceAll('.', ',');
    final from = est.$2 == 'profile' ? 'ton profil' : 'ton meilleur test noté';
    return 'Ta référence « ${referenceLabel(s.ref!)} » n’est pas renseignée : '
        'j’ai pris $v d’après $from. Renseigne-la dans Références pour la '
        'fixer.';
  }

  /// Rôle de l'emplacement d'une ligne (comme la portée simple).
  kc.SlotRole _importRole(Exercise e, ka.ExerciseInfo info) => e.main
      ? kc.SlotRole.main
      : e.prevention
      ? kc.SlotRole.accessory
      : (e.load.type == 'system' || e.load.type == 'barbell'
            ? kc.SlotRole.secondary
            : (info.mode == null
                  ? kc.SlotRole.mobility
                  : kc.SlotRole.accessory));

  /// Base de charge et charge de départ d'une ligne (comme les clusters).
  (kc.LoadBasis, double?) _importLoad(
    Exercise e,
    kc.CatalogExercise cat,
    ka.ExerciseInfo info,
  ) {
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
    double? startKg;
    if (info.mode == ka.CapacityMode.loaded &&
        basis != kc.LoadBasis.bodyweight) {
      final kg = loadFor(e);
      if (kg != null && kg >= 0 && kg <= 1000) {
        startKg = (kg * 100).roundToDouble() / 100;
        if (basis == kc.LoadBasis.external && startKg <= 0) startKg = null;
      }
    }
    return (basis, startKg);
  }

  /// CI1f (C11.6) : formats propres du programme — myo-reps, durées, HIIT,
  /// EMOM, contrastes, échelles, séries « N × ? reps » (référence estimée).
  /// Null : format toujours sans équivalent propre (servi tel qu'écrit).
  _ImportedLine? _importFormat(
    Exercise e,
    int j,
    kc.Catalog catalog,
    ka.ExerciseBook book,
    Map<String, (double, String)> estimates,
  ) {
    final id = e.catalogId ?? content.idFor(e.name);
    if (id == null) return null;
    final cat = catalog.find(id);
    final info = book.find(id);
    if (cat == null || info == null) return null;
    final slot = SessionAdaptStore.importedSlot(j, e.id);
    final sp = logSpec(e);
    final rir = _rirRange(e.intensity);
    final flames = rir == null
        ? null
        : kc.Flames.fromRir((rir.$1 + rir.$2) / 2);
    final intensity = rir == null
        ? null
        : kc.IntensityTarget(
            basis: kc.IntensityBasis.rir,
            value: rir.$1,
            valueHigh: rir.$2 > rir.$1 ? rir.$2 : null,
          );
    final rest = e.restSec?.clamp(0, 900);
    // « N × ? reps » et « EMOM 12 min × ? reps » : référence estimée.
    var label = setsLabel(e);
    final sets = e.sets;
    if (sets.type == 'volume' && label.contains('?')) {
      final est = estimates[sets.ref];
      if (est == null) return null;
      final n = (sets.coef! * est.$1 / sets.div!).round();
      if (n < 1) return null;
      label = '${sets.prefix}$n${sets.suffix}';
      if (sp.kind == 'reps') {
        final x = Exercise.adapted(e, sets: SetsSpec.text(label));
        final base = SessionAdaptStore(
          this,
        )._adaptImportItem(x, j, catalog, book);
        if (base == null) return null;
        return _ImportedLine(_annotate(x, base.$1), base.$2);
      }
    }
    final text = label.toLowerCase().trim();
    final role = _importRole(e, info);
    final (basis, startKg) = _importLoad(e, cat, info);
    _ImportedLine? line;
    if (sp.myo) {
      // « 1×15 puis 4×(4) » : activation puis mini-séries. La plage de la
      // ligne est celle de l'activation : `kalis_adapt` 0.3.0 lit la
      // première partie comme la série et règle la charge sur elle.
      final m = RegExp(
        r'^1\s*[×x]\s*(\d+)(?:\s*-\s*(\d+))?\s*puis\s*(\d+)\s*[×x]\s*\(?\s*(\d+)',
      ).firstMatch(text);
      if (m == null || info.mode == null) return null;
      final lo = int.parse(m.group(1)!);
      final hi = int.parse(m.group(2) ?? m.group(1)!);
      final minis = int.parse(m.group(3)!);
      final each = int.parse(m.group(4)!);
      if (lo < 1 || hi < lo || hi > 100 || minis < 1 || minis > 20) {
        return null;
      }
      if (each < 1 || each > 50) return null;
      line = _ImportedLine(
        kc.ExercisePrescription(
          slotId: slot,
          exerciseId: id,
          sets: 1,
          repsLow: lo,
          repsHigh: hi,
          targetFlames: flames,
          startLoadKg: startKg,
          toCalibrate: false,
          loadBasis: basis,
          reasons: const <kc.Reason>[],
          technique: kc.SetTechnique(
            kind: kc.SetTechniqueKind.myoReps,
            miniSetReps: each,
            miniSets: minis,
            intraRestSeconds: (sp.intra ?? 10).clamp(5, 60),
          ),
          intensity: intensity,
        ),
        role,
      );
    } else if (sp.kind == 'duration') {
      // « 10 min », « 30-45 min » : mobilité, marche ou vélo léger, conduits
      // par l'endurance de `kalis_adapt` 0.3.0.
      final m = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?\s*min$').firstMatch(text);
      if (m == null || info.mode != null) return null;
      if (cat.unit != kc.MeasureUnit.seconds) return null;
      final lo = int.parse(m.group(1)!) * 60;
      final hi = int.parse(m.group(2) ?? m.group(1)!) * 60;
      if (lo < 60 || hi < lo || hi > 4 * 3600) return null;
      line = _ImportedLine(
        kc.ExercisePrescription(
          slotId: slot,
          exerciseId: id,
          sets: 1,
          secondsLow: lo,
          secondsHigh: hi,
          toCalibrate: false,
          loadBasis: kc.LoadBasis.unloaded,
          reasons: const <kc.Reason>[],
        ),
        kc.SlotRole.mobility,
      );
    } else if (sp.kind == 'interval' && e.interval != null) {
      // « 8× (30 s effort / 30 s repos) » : groupe d'intervalles.
      final iv = e.interval!;
      if (info.mode != null) return null;
      if (iv.rounds < 1 || iv.rounds > 20) return null;
      if (iv.work < 5 || iv.work > 3600 || iv.rest > 3600) return null;
      line = _ImportedLine(
        kc.ExercisePrescription(
          slotId: slot,
          exerciseId: id,
          sets: iv.rounds,
          secondsLow: iv.work,
          secondsHigh: iv.work,
          restSeconds: iv.rest,
          toCalibrate: false,
          loadBasis: basis == kc.LoadBasis.external
              ? kc.LoadBasis.unloaded
              : basis,
          reasons: const <kc.Reason>[],
        ),
        kc.SlotRole.conditioning,
        group: kc.GroupSpec(
          groupId: 'g',
          format: kc.GroupFormat.intervals,
          rounds: iv.rounds,
          intervalSeconds: iv.work,
          restBetweenRoundsSeconds: iv.rest,
        ),
      );
    } else if (sp.kind == 'emom') {
      // « EMOM 12 min × 5 reps par minute » : une ligne par minute
      // (technique `emom`), dans un groupe au temps qui réunit les
      // exercices enchaînés dans la même minute.
      final m = RegExp(
        r'^emom\s*(\d+)\s*min\s*[×x]\s*(\d+)\s*reps',
      ).firstMatch(text);
      if (m == null || info.mode == null) return null;
      final minutes = int.parse(m.group(1)!);
      final reps = int.parse(m.group(2)!);
      if (minutes < 2 || minutes > 20 || reps < 1 || reps > 100) return null;
      line = _ImportedLine(
        kc.ExercisePrescription(
          slotId: slot,
          exerciseId: id,
          sets: minutes,
          repsLow: reps,
          repsHigh: reps,
          targetFlames: flames,
          restSeconds: 0,
          startLoadKg: startKg,
          toCalibrate: false,
          loadBasis: basis,
          reasons: const <kc.Reason>[],
          technique: kc.SetTechnique(
            kind: kc.SetTechniqueKind.emom,
            intervalSeconds: 60,
            intervals: minutes,
          ),
          intensity: intensity,
        ),
        role,
        group: kc.GroupSpec(
          groupId: 'g',
          format: kc.GroupFormat.emom,
          intervalSeconds: 60,
          durationSeconds: minutes * 60,
        ),
      );
    } else if (sp.rowPrefix == 'R' || sp.rowPrefix == 'É') {
      // Contrastes (« 3 rounds : 3 sauts groupés + 5 squats sautés ») et
      // échelles (« 4 échelles dégressives de 7 à 1 ») : tours d'un groupe,
      // servis tels qu'écrits.
      int rounds;
      int perRound;
      var exerciseId = id;
      final c = RegExp(r'^(\d+)\s*rounds?\s*:\s*(.+)$').firstMatch(text);
      final l = RegExp(
        r'^(\d+)\s*échelles?\s*(?:dégressives?\s*)?de\s*(\d+)\s*à\s*(\d+)',
      ).firstMatch(text);
      if (sp.rowPrefix == 'R' && c != null) {
        rounds = int.parse(c.group(1)!);
        perRound = 0;
        for (final n in RegExp(r'(\d+)').allMatches(c.group(2)!)) {
          perRound += int.parse(n.group(1)!);
        }
        // Contraste du squat : la ligne est la partie explosive.
        final what = normalizeText(c.group(2)!);
        if (what.contains('saut') && catalog.find('mu-squat-saute') != null) {
          exerciseId = 'mu-squat-saute';
        }
      } else if (sp.rowPrefix == 'É' && l != null) {
        rounds = int.parse(l.group(1)!);
        final a = int.parse(l.group(2)!), b = int.parse(l.group(3)!);
        final top = math.max(a, b), bottom = math.min(a, b);
        if (bottom < 1 || top > 30) return null;
        perRound = (top + bottom) * (top - bottom + 1) ~/ 2;
      } else {
        return null;
      }
      if (rounds < 1 || rounds > 20 || perRound < 1 || perRound > 500) {
        return null;
      }
      final xInfo = book.find(exerciseId);
      final xCat = catalog.find(exerciseId);
      if (xInfo == null || xCat == null) return null;
      final (xBasis, xKg) = _importLoad(e, xCat, xInfo);
      line = _ImportedLine(
        kc.ExercisePrescription(
          slotId: slot,
          exerciseId: exerciseId,
          sets: rounds,
          repsLow: perRound,
          repsHigh: perRound,
          targetFlames: flames,
          restSeconds: rest,
          startLoadKg: xKg,
          toCalibrate: false,
          loadBasis: xBasis,
          reasons: const <kc.Reason>[],
          intensity: intensity,
        ),
        exerciseId == id ? role : kc.SlotRole.accessory,
        group: kc.GroupSpec(
          groupId: 'g',
          format: kc.GroupFormat.circuit,
          rounds: rounds,
          restBetweenRoundsSeconds: rest,
        ),
        asWritten: true,
      );
    }
    if (line == null || line.item.validate().isNotEmpty) return null;
    return line;
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
        text.contains('tentative')) {
      // Comme `kalis_plan` écrit un test de 1RM : une ligne par tentative
      // (charges montantes calculées par le moteur) ; les singles de
      // montée sont l'échauffement, hors journal.
      final tries = RegExp(r'(\d+)\s*tentatives').firstMatch(text);
      final attempts = (tries == null ? 3 : int.parse(tries.group(1)!)).clamp(
        1,
        6,
      );
      it = kc.ExercisePrescription(
        slotId: slot,
        exerciseId: id,
        sets: attempts,
        repsLow: 1,
        repsHigh: 1,
        targetFlames: kc.Flames.failure,
        restSeconds: e.restSec?.clamp(0, 900),
        startLoadKg: startKg,
        toCalibrate: false,
        loadBasis: basis,
        kind: kc.SetKind.test,
        reasons: const <kc.Reason>[],
        test: kc.TestSpec(
          kind: kc.TestKind.oneRm,
          attempts: attempts,
          benchmarkKind: kc.BenchmarkKind.loadReps,
        ),
      );
    }
    if (it == null || it.validate().isNotEmpty) return null;
    return (it, role);
  }
}
