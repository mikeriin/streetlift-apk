// G7 (D4.7, D4.8, D4.9) : programme créé par `kalis_plan`, tel que
// l'application le stocke et le montre.
//
// - [PlanProgram] : section `planProgram` (v1, facultative) de la
//   sauvegarde. Les blocs sont ceux du moteur (`ProgramBlock`, inchangés,
//   relus par `fromJson`) ; les ajustements de l'utilisateur en passe 2
//   sont gardés à part ([PlanAdjust]) et appliqués à l'affichage. Les
//   semaines d'un programme précédent (programme du propriétaire, ancien
//   programme L10) sont gardées telles quelles avant le premier bloc :
//   l'historique reste attaché aux mêmes séances (clés S·J).
// - [planWeeks] : semaines au schéma `programme_v33` (lu par l'accueil, le
//   calendrier, la séance, STATS) — mise en forme seulement, aucune règle
//   d'entraînement.
// - [ProgramResume] : section `programResume` (v1) — « Où j'en suis »
//   (D4.9) : séances antérieures marquées « reprise », neutres.
//
// Fonctions pures : aucune horloge (dates passées en paramètre).
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart' as kc;

import 'plan_texts.dart';

const kPlanProgramVersion = 1;
const kProgramResumeVersion = 1;

/// Délai pendant lequel l'ancien programme peut être rétabli (comme L10).
const Duration kPlanUndoWindow = Duration(days: 7);

/// Ajustement de l'utilisateur sur un emplacement (toutes les semaines du
/// bloc), en passe 2.
class PlanAdjust {
  final int setsDelta;
  final int repsShift;
  final int restDelta;
  const PlanAdjust({this.setsDelta = 0, this.repsShift = 0, this.restDelta = 0});

  bool get isEmpty => setsDelta == 0 && repsShift == 0 && restDelta == 0;

  PlanAdjust copyWith({int? setsDelta, int? repsShift, int? restDelta}) =>
      PlanAdjust(
        setsDelta: setsDelta ?? this.setsDelta,
        repsShift: repsShift ?? this.repsShift,
        restDelta: restDelta ?? this.restDelta,
      );

  Map<String, Object?> toJson() => {
    if (setsDelta != 0) 'sets': setsDelta,
    if (repsShift != 0) 'reps': repsShift,
    if (restDelta != 0) 'rest': restDelta,
  };

  static PlanAdjust fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Ajustement invalide.');
    int v(String k, int lo, int hi) {
      final x = raw[k] ?? 0;
      if (x is! int || x < lo || x > hi) {
        throw const FormatException('Ajustement invalide.');
      }
      return x;
    }

    return PlanAdjust(
      setsDelta: v('sets', -1, 1),
      repsShift: v('reps', -2, 2),
      restDelta: v('rest', -60, 120),
    );
  }

  /// Prescription ajustée. Les séries de test et de calibrage, et les
  /// cibles série par série, restent celles du moteur.
  kc.ExercisePrescription apply(kc.ExercisePrescription p) {
    if (isEmpty) return p;
    if (p.kind == kc.SetKind.test || p.kind == kc.SetKind.calibration) {
      return p;
    }
    var out = p;
    if (setsDelta != 0 && p.setTargets == null) {
      out = out.copyWith(sets: (p.sets + setsDelta).clamp(1, 20));
    }
    if (repsShift != 0 && p.repsLow != null && p.repsHigh != null) {
      final lo = (p.repsLow! + repsShift).clamp(1, 1000);
      final hi = (p.repsHigh! + repsShift).clamp(lo, 1000);
      out = out.copyWith(repsLow: lo, repsHigh: hi);
    }
    if (restDelta != 0 && p.restSeconds != null) {
      out = out.copyWith(restSeconds: (p.restSeconds! + restDelta).clamp(0, 900));
    }
    return out;
  }
}

/// Bloc validé, avec ce qu'il faut pour le régénérer ou le restructurer.
class PlanBlockEntry {
  final kc.ProgramBlock block;
  final int seed;
  final List<kc.PlanLock> locks;

  /// Emplacement → ajustement de la passe 2.
  final Map<String, PlanAdjust> adjust;

  /// Validation (horodatage local).
  final String validatedAt;
  const PlanBlockEntry({
    required this.block,
    required this.seed,
    required this.locks,
    this.adjust = const {},
    required this.validatedAt,
  });

  int get weeks => block.pass1.weeks;

  Map<String, Object?> toJson() => {
    'block': block.toJson(),
    'seed': seed,
    'locks': [for (final l in locks) l.toJson()],
    if (adjust.values.any((a) => !a.isEmpty))
      'adjust': {
        for (final e in adjust.entries)
          if (!e.value.isEmpty) e.key: e.value.toJson(),
      },
    'validatedAt': validatedAt,
  };

  static PlanBlockEntry fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Bloc invalide.');
    final m = raw.cast<String, Object?>();
    final b = m['block'];
    if (b is! Map) throw const FormatException('Bloc invalide.');
    final block = kc.ProgramBlock.fromJson(b.cast<String, Object?>());
    if (block.validate().isNotEmpty) {
      throw const FormatException('Bloc hors contrat.');
    }
    final seed = m['seed'];
    final at = m['validatedAt'];
    if (seed is! int || seed < 0 || at is! String || at.length > 40) {
      throw const FormatException('Bloc invalide.');
    }
    final locks = <kc.PlanLock>[];
    for (final l in (m['locks'] as List? ?? const [])) {
      if (l is! Map) throw const FormatException('Verrou invalide.');
      locks.add(kc.PlanLock.fromJson(l.cast<String, Object?>()));
    }
    final adjust = <String, PlanAdjust>{};
    final a = m['adjust'];
    if (a != null) {
      if (a is! Map) throw const FormatException('Ajustements invalides.');
      for (final e in a.entries) {
        adjust['${e.key}'] = PlanAdjust.fromJson(e.value);
      }
    }
    return PlanBlockEntry(
      block: block,
      seed: seed,
      locks: locks,
      adjust: adjust,
      validatedAt: at,
    );
  }
}

/// Programme précédent, gardé pour le rétablir (7 jours, tant qu'aucune
/// séance du nouveau programme n'est saisie).
class PlanPrevious {
  final Map<String, dynamic>? programInstance;
  final String? start;
  final String startOrigin;
  final String at;
  const PlanPrevious({
    this.programInstance,
    this.start,
    this.startOrigin = '',
    required this.at,
  });

  Map<String, Object?> toJson() => {
    if (programInstance != null) 'programInstance': programInstance,
    if (start != null) 'start': start,
    'startOrigin': startOrigin,
    'at': at,
  };

  static PlanPrevious fromJson(Object? raw) {
    if (raw is! Map || raw['at'] is! String) {
      throw const FormatException('Programme précédent invalide.');
    }
    final pi = raw['programInstance'];
    if (pi != null && pi is! Map) {
      throw const FormatException('Programme précédent invalide.');
    }
    final s = raw['start'];
    if (s != null && s is! String) {
      throw const FormatException('Programme précédent invalide.');
    }
    return PlanPrevious(
      programInstance: pi == null
          ? null
          : (jsonDecode(jsonEncode(pi)) as Map).cast<String, dynamic>(),
      start: s as String?,
      startOrigin: raw['startOrigin'] as String? ?? '',
      at: raw['at'] as String,
    );
  }
}

/// Programme créé par kalis_plan (section `planProgram`).
class PlanProgram {
  final int version;

  /// `creation` (aucun programme avant) ou `replace`.
  final String origin;
  final String createdAt;
  final String updatedAt;

  /// Numéro de semaine (S) du premier jour du premier bloc.
  final int firstWeek;

  /// Semaines du programme précédent (schéma programme_v33), numérotées 1
  /// à firstWeek - 1 : l'historique reste attaché aux mêmes séances.
  final List<Map<String, dynamic>> prefix;

  /// Annotations Koach (L7) du programme précédent pour ces semaines.
  final Map<String, dynamic> prefixKoach;

  final List<PlanBlockEntry> blocks;
  final PlanPrevious? previous;

  const PlanProgram({
    this.version = kPlanProgramVersion,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    required this.firstWeek,
    this.prefix = const [],
    this.prefixKoach = const {},
    required this.blocks,
    this.previous,
  });

  int get totalWeeks => firstWeek - 1 + blocks.fold(0, (a, b) => a + b.weeks);

  /// Première semaine (S) du bloc [index].
  int blockFirstWeek(int index) {
    var n = firstWeek;
    for (var i = 0; i < index; i++) {
      n += blocks[i].weeks;
    }
    return n;
  }

  /// Bloc et semaine du bloc d'une semaine S (null : semaine du programme
  /// précédent).
  ({int block, int weekIndex})? locate(int week) {
    var n = firstWeek;
    for (var i = 0; i < blocks.length; i++) {
      if (week >= n && week < n + blocks[i].weeks) {
        return (block: i, weekIndex: week - n);
      }
      n += blocks[i].weeks;
    }
    return null;
  }

  PlanProgram copyWith({
    String? updatedAt,
    List<PlanBlockEntry>? blocks,
    PlanPrevious? previous,
    bool clearPrevious = false,
  }) => PlanProgram(
    version: version,
    origin: origin,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    firstWeek: firstWeek,
    prefix: prefix,
    prefixKoach: prefixKoach,
    blocks: blocks ?? this.blocks,
    previous: clearPrevious ? null : (previous ?? this.previous),
  );

  Map<String, Object?> toJson() => {
    'v': version,
    'origin': origin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'firstWeek': firstWeek,
    if (prefix.isNotEmpty) 'prefix': prefix,
    if (prefixKoach.isNotEmpty) 'prefixKoach': prefixKoach,
    'blocks': [for (final b in blocks) b.toJson()],
    if (previous != null) 'previous': previous!.toJson(),
  };

  /// Lecture ; [FormatException] hors contrat.
  static PlanProgram fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Programme : section.');
    final m = raw.cast<String, Object?>();
    final v = m['v'];
    if (v is! int || v < 1 || v > kPlanProgramVersion) {
      throw const FormatException('Programme : version non prise en charge.');
    }
    final origin = m['origin'];
    if (origin != 'creation' && origin != 'replace') {
      throw const FormatException('Programme : origine invalide.');
    }
    String str(String k) {
      final x = m[k];
      if (x is! String || x.length > 40) {
        throw FormatException('Programme : $k invalide.');
      }
      return x;
    }

    final first = m['firstWeek'];
    if (first is! int || first < 1 || first > 520) {
      throw const FormatException('Programme : première semaine invalide.');
    }
    final prefix = <Map<String, dynamic>>[];
    final rawPrefix = m['prefix'];
    if (rawPrefix != null) {
      if (rawPrefix is! List || rawPrefix.length != first - 1) {
        throw const FormatException('Programme : semaines précédentes.');
      }
      for (var k = 0; k < rawPrefix.length; k++) {
        final w = rawPrefix[k];
        if (w is! Map ||
            w['n'] != k + 1 ||
            w['days'] is! List ||
            (w['days'] as List).length != 7) {
          throw const FormatException('Programme : semaine précédente.');
        }
        prefix.add((jsonDecode(jsonEncode(w)) as Map).cast<String, dynamic>());
      }
    } else if (first != 1) {
      throw const FormatException('Programme : semaines précédentes.');
    }
    final pk = m['prefixKoach'];
    if (pk != null && pk is! Map) {
      throw const FormatException('Programme : annotations.');
    }
    final rawBlocks = m['blocks'];
    if (rawBlocks is! List || rawBlocks.isEmpty || rawBlocks.length > 100) {
      throw const FormatException('Programme : blocs invalides.');
    }
    final blocks = [for (final b in rawBlocks) PlanBlockEntry.fromJson(b)];
    final prev = m['previous'];
    return PlanProgram(
      version: v,
      origin: origin as String,
      createdAt: str('createdAt'),
      updatedAt: str('updatedAt'),
      firstWeek: first,
      prefix: prefix,
      prefixKoach: pk == null
          ? const {}
          : (jsonDecode(jsonEncode(pk)) as Map).cast<String, dynamic>(),
      blocks: blocks,
      previous: prev == null ? null : PlanPrevious.fromJson(prev),
    );
  }
}

// ----------------------------------------------------------- mise en forme

/// Ce dont la mise en forme a besoin du catalogue et du profil.
class PlanLabels {
  final String Function(String exerciseId) name;
  final String Function(String exerciseId) cue;
  final String Function(String goalId)? goal;
  const PlanLabels({required this.name, required this.cue, this.goal});
}

/// Identifiant d'un exercice de la semaine S, jour J (clé du journal).
String planExerciseId(int week, int j, String slotId) => 'k$week.$j.$slotId';

/// Jour J (1 à 7, J1 = jour du départ) d'un jour ISO.
int planJ(int isoWeekday, int startWeekday) =>
    (isoWeekday - startWeekday + 7) % 7 + 1;

String _weekColor(kc.WeekKind k) => switch (k) {
  kc.WeekKind.intro => '6B0C0C',
  kc.WeekKind.build => '8E1B1B',
  kc.WeekKind.deload => '808080',
  kc.WeekKind.test => 'A61717',
};

/// Semaine de type L7 (`normal`, `deload`, `test`).
String koachWeekType(kc.WeekKind k) => switch (k) {
  kc.WeekKind.deload => 'deload',
  kc.WeekKind.test => 'test',
  _ => 'normal',
};

/// Prescriptions de la semaine [weekIndex] du bloc [e], ajustées.
List<kc.DayPrescription> adjustedDays(PlanBlockEntry e, int weekIndex) {
  final w = e.block.pass2.weeks[weekIndex];
  return [
    for (final d in w.days)
      kc.DayPrescription(
        dayIndex: d.dayIndex,
        items: [
          for (final it in d.items)
            (e.adjust[it.slotId] ?? const PlanAdjust()).apply(it),
        ],
      ),
  ];
}

/// Une semaine au schéma programme_v33.
Map<String, dynamic> planWeekJson({
  required PlanBlockEntry entry,
  required int blockIndex,
  required int weekIndex,
  required int weekNumber,
  required int startWeekday,
  required PlanLabels labels,
}) {
  final pass1 = entry.block.pass1;
  final week = entry.block.pass2.weeks[weekIndex];
  final kindLabel = kWeekKindLabels[week.kind]!;
  final days = adjustedDays(entry, weekIndex);
  final byJ = <int, ({kc.PlanDay day, kc.DayPrescription? items})>{};
  for (final d in pass1.days) {
    kc.DayPrescription? items;
    for (final x in days) {
      if (x.dayIndex == d.dayIndex) items = x;
    }
    byJ[planJ(d.weekday, startWeekday)] = (day: d, items: items);
  }
  final out = <Map<String, dynamic>>[];
  for (var j = 1; j <= 7; j++) {
    final hit = byJ[j];
    if (hit == null || hit.items == null || hit.items!.items.isEmpty) {
      out.add({
        'j': j,
        'title': 'REPOS',
        'cycle': kindLabel,
        'conduite':
            'Repos : récupération. Marche ou mobilité légère si tu en as envie.',
        'exercises': <Map<String, dynamic>>[],
      });
      continue;
    }
    final roles = {for (final s in hit.day.slots) s.slotId: s.role};
    final exercises = <Map<String, dynamic>>[];
    for (final p in hit.items!.items) {
      final rest = p.restSeconds;
      final why = mainReason(p.reasons) ??
          mainReason([
            for (final s in hit.day.slots)
              if (s.slotId == p.slotId) ...s.reasons,
          ]);
      final flames = p.targetFlames;
      exercises.add({
        'id': planExerciseId(weekNumber, j, p.slotId),
        'name': labels.name(p.exerciseId),
        'sets': {'type': 'text', 'value': prescriptionLabel(p)},
        'intensity': flames == null
            ? ''
            : 'Difficulté visée $flames/10 · RIR ${_rir(flames)}',
        'load': p.startLoadKg != null &&
                p.loadBasis != kc.LoadBasis.bodyweight
            ? {'type': 'fixed', 'kg': p.startLoadKg}
            : {'type': 'none'},
        'rest': restLabel(rest),
        if (rest != null) 'restSec': rest,
        'tempo': '',
        'cue': labels.cue(p.exerciseId),
        'main': roles[p.slotId] == kc.SlotRole.main,
        'prevention': false,
        'why': why == null
            ? ''
            : reasonText(why, exerciseName: labels.name, goalLabel: labels.goal),
        'role': (roles[p.slotId] ?? kc.SlotRole.accessory).code,
        'catalogId': p.exerciseId,
        'slotId': p.slotId,
        if (flames != null) 'flames': flames,
        if (p.toCalibrate) 'toCalibrate': true,
        if (p.kind != null) 'setKind': p.kind!.code,
      });
    }
    out.add({
      'j': j,
      'title': focusLabel(hit.day.focus).toUpperCase(),
      'cycle': kindLabel,
      'conduite': kWeekKindHints[week.kind]!,
      'exercises': exercises,
      'why': kWeekKindHints[week.kind]!,
      'kind': hit.day.focus,
      'minutes': hit.day.minutesBudget,
    });
  }
  return {
    'n': weekNumber,
    'dates': '',
    'block': 'Bloc ${blockIndex + 1} — $kindLabel',
    'blockKey': 'K${blockIndex + 1}',
    'color': _weekColor(week.kind),
    'kind': week.kind.code,
    'days': out,
  };
}

String _rir(int flames) {
  final r = kc.Flames.toRir(flames);
  final t = r == r.roundToDouble() ? r.toInt().toString() : '$r'.replaceAll('.', ',');
  return flames == kc.Flames.min ? '$t et plus' : t;
}

/// Toutes les semaines du programme (précédentes puis blocs).
List<Map<String, dynamic>> planWeeks(
  PlanProgram p, {
  required int startWeekday,
  required PlanLabels labels,
}) {
  final out = <Map<String, dynamic>>[...p.prefix];
  var n = p.firstWeek;
  for (var b = 0; b < p.blocks.length; b++) {
    final e = p.blocks[b];
    for (var w = 0; w < e.weeks; w++) {
      out.add(
        planWeekJson(
          entry: e,
          blockIndex: b,
          weekIndex: w,
          weekNumber: n,
          startWeekday: startWeekday,
          labels: labels,
        ),
      );
      n++;
    }
  }
  return out;
}

/// Annotations Koach (L7) : celles du programme précédent pour ses
/// semaines, RIR visé et nature des semaines pour les blocs.
Map<String, dynamic> planKoachJson(
  PlanProgram p,
  List<Map<String, dynamic>> weeks,
  Map<String, dynamic> baseKoach,
) {
  final exercises = <String, dynamic>{
    ...?(p.prefixKoach['exercises'] as Map?)?.cast<String, dynamic>(),
  };
  final types = <String, dynamic>{
    ...?(p.prefixKoach['weeks'] as Map?)?.cast<String, dynamic>(),
  };
  for (final w in weeks) {
    final n = w['n'] as int;
    if (n < p.firstWeek) continue;
    for (final k in kc.WeekKind.values) {
      if (k.code == w['kind']) types['$n'] = koachWeekType(k);
    }
    for (final d in w['days'] as List) {
      for (final e in (d as Map)['exercises'] as List) {
        final em = e as Map;
        final f = em['flames'];
        if (f is int) {
          exercises['${em['id']}'] = {'rirTarget': kc.Flames.toRir(f)};
        }
      }
    }
  }
  return {
    'version': 1,
    'source': {'generator': 'kalis_plan'},
    'exercises': exercises,
    'accessories': baseKoach['accessories'] ?? const {},
    'weeks': types,
    'curve': baseKoach['curve'] ?? const {},
  };
}

// --------------------------------------------------- bornes des ajustements

/// Résultat d'un ajustement demandé : accepté, ou refusé avec la raison.
class AdjustCheck {
  final bool ok;
  final String message;
  const AdjustCheck.ok([this.message = '']) : ok = true;
  const AdjustCheck.refused(this.message) : ok = false;
}

/// Bornes des ajustements de la passe 2 (D4.7). Elles reprennent ce que
/// garantit le contrat de kalis_plan 0.1.0 (§ 5.1) : au plus une série de
/// plus que la dose du moteur (« le volume vient d'exercices en plus, pas
/// de séries empilées »), 3 séries au plus en programme prudent, plage de
/// répétitions déplacée d'au plus 2 sans dépasser la charge de départ
/// calculée pour elle, repos jamais raccourci de plus de 30 s. Choix de
/// l'application, en attendant une vérification fournie par le moteur
/// (DECISIONS_GP.md, G7).
AdjustCheck checkAdjust(
  PlanBlockEntry entry,
  String slotId,
  PlanAdjust next, {
  required bool cautious,
}) {
  final items = <kc.ExercisePrescription>[
    for (final w in entry.block.pass2.weeks)
      for (final d in w.days)
        for (final it in d.items)
          if (it.slotId == slotId &&
              it.kind != kc.SetKind.test &&
              it.kind != kc.SetKind.calibration)
            it,
  ];
  if (items.isEmpty) {
    return const AdjustCheck.refused(
      'Cet exercice n’a pas de séries réglables cette semaine.',
    );
  }
  if (next.setsDelta > 1) {
    return const AdjustCheck.refused(
      'Pas plus d’une série de plus que ce que je propose : pour plus de '
      'volume, j’ajoute plutôt un exercice que d’empiler les séries.',
    );
  }
  if (next.setsDelta < -1) {
    return const AdjustCheck.refused(
      'Une série de moins au plus : en dessous, l’exercice ne compte presque '
      'plus dans ta semaine.',
    );
  }
  for (final it in items) {
    final s = it.sets + next.setsDelta;
    if (s < 1) {
      return const AdjustCheck.refused(
        'Il faut garder au moins une série par semaine.',
      );
    }
    if (cautious && s > 3 && next.setsDelta > 0) {
      return const AdjustCheck.refused(
        'Ton programme est en mode prudent : 3 séries au plus par exercice.',
      );
    }
  }
  if (next.repsShift != 0) {
    final reps = items.where((i) => i.repsLow != null).toList();
    if (reps.isEmpty) {
      return const AdjustCheck.refused(
        'Cet exercice se règle en temps ou en distance, pas en répétitions.',
      );
    }
    if (next.repsShift.abs() > 2) {
      return const AdjustCheck.refused(
        'La plage bouge de 2 répétitions au plus : au-delà, ce n’est plus le '
        'même travail.',
      );
    }
    if (next.repsShift > 0 && reps.any((i) => i.startLoadKg != null)) {
      return const AdjustCheck.refused(
        'Ta charge de départ est calculée pour cette plage : plus de '
        'répétitions avec la même charge, ce serait trop lourd. Tu peux en '
        'faire moins.',
      );
    }
    for (final i in reps) {
      if (i.repsLow! + next.repsShift < 1) {
        return const AdjustCheck.refused(
          'Il faut au moins une répétition par série.',
        );
      }
    }
  }
  if (next.restDelta != 0) {
    final timed = items.where((i) => i.restSeconds != null).toList();
    if (timed.isEmpty) {
      return const AdjustCheck.refused('Le repos est libre sur cet exercice.');
    }
    if (next.restDelta < -30) {
      return const AdjustCheck.refused(
        'Je ne raccourcis pas le repos de plus de 30 s : tu récupérerais '
        'mal entre les séries.',
      );
    }
    if (next.restDelta > 120) {
      return const AdjustCheck.refused(
        'Deux minutes de plus au plus : au-delà, ta séance ne tient plus '
        'dans ton temps.',
      );
    }
    for (final i in timed) {
      if (i.targetFlames != null && i.restSeconds! + next.restDelta < 30) {
        return const AdjustCheck.refused(
          'Au moins 30 s de repos entre deux séries d’effort.',
        );
      }
    }
  }
  return const AdjustCheck.ok();
}

// --------------------------------------------------------- « Où j'en suis »

/// « Où j'en suis » (D4.9) : séances marquées « reprise ».
class ProgramResume {
  final int version;
  final String at;
  final int week, day;

  /// Clés S·J des séances marquées « reprise » (sans journal au moment du
  /// choix).
  final List<String> keys;

  /// Départ avant le choix (civil, AAAA-MM-JJ) ; null s'il n'y en avait pas.
  final String? previousStart;
  const ProgramResume({
    this.version = kProgramResumeVersion,
    required this.at,
    required this.week,
    required this.day,
    required this.keys,
    this.previousStart,
  });

  Map<String, Object?> toJson() => {
    'v': version,
    'at': at,
    'week': week,
    'day': day,
    'keys': keys,
    if (previousStart != null) 'previousStart': previousStart,
  };

  static ProgramResume fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Reprise invalide.');
    final v = raw['v'];
    final week = raw['week'];
    final day = raw['day'];
    final at = raw['at'];
    final keys = raw['keys'];
    if (v is! int ||
        v < 1 ||
        v > kProgramResumeVersion ||
        week is! int ||
        week < 1 ||
        week > 520 ||
        day is! int ||
        day < 1 ||
        day > 7 ||
        at is! String ||
        keys is! List ||
        keys.length > 4000 ||
        keys.any((k) => k is! String || !RegExp(r'^S\d+-J[1-7]$').hasMatch(k))) {
      throw const FormatException('Reprise invalide.');
    }
    final ps = raw['previousStart'];
    if (ps != null && ps is! String) {
      throw const FormatException('Reprise invalide.');
    }
    return ProgramResume(
      version: v,
      at: at,
      week: week,
      day: day,
      keys: [for (final k in keys) k as String],
      previousStart: ps as String?,
    );
  }
}

/// Séances à marquer « reprise » quand l'utilisateur dit être à la
/// semaine [week], séance [day] : journées d'entraînement antérieures,
/// sans journal ([logged]).
List<String> resumeKeysFor({
  required List<({int week, int j, bool training})> days,
  required int week,
  required int day,
  required bool Function(int week, int j) logged,
}) {
  final at = (week - 1) * 7 + day - 1;
  return [
    for (final d in days)
      if (d.training && (d.week - 1) * 7 + d.j - 1 < at && !logged(d.week, d.j))
        'S${d.week}-J${d.j}',
  ];
}
