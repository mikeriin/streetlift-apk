// THROW-AWAY EXPORT — not a real test. Copy to test/zz_l10_export_test.dart and
// run from the repository root:
//
//   flutter test test/zz_l10_export_test.dart
//
// It maps the 40 AthleteProfile v2 fixtures of kalis_core
// (packages/kalis_core/test/fixtures/profiles.json) to the inputs of the OLD
// generator L10 (lib/program_generator.dart), runs L10 with seed 0 and start
// 2026-10-05, and dumps everything to
// out-packages/kalis_plan/l10/l10_outputs.json.
//
// ======================= MAPPING DECISIONS (profile v2 → GenInputs) ==========
//
// GOAL (L10 knows only: health | strength | endurance | event)
//   discipline → L10 goal:
//     general_fitness → health        musculation   → strength
//     mobility        → health (*)    streetlifting → strength
//     cardio          → health (*)    calisthenics  → strength (*)
//     street_workout  → endurance     crossfit      → endurance (*)
//   (*) not expressible in L10: no cardio/mobility programme, no skills goal
//       (figures are only picked for a muscle-up event), no WOD. A note is
//       recorded. L10 has no hypertrophy goal either: musculation → strength.
//   goalPrimary   = goal of `disciplines.primary`.
//   goalSecondary = the other L10 goal with the largest summed pct among the
//                   secondary disciplines (none if all map to the same goal).
//   goalWeight    = share of the primary goal among (primary + secondary)
//                   pct, clamped to L10's 50..100.
//   `streetMode` is not read separately: its three parts are the same
//   information as the disciplines streetlifting / street_workout /
//   calisthenics, already mapped above.
//   DATED PERFORMANCE GOALS (switch [_kMapDatedGoalsToEvent]): a `performance`
//   goal with a targetDate on a lift L10 has as an "épreuve" becomes
//   goalPrimary = 'event' (eventItems + eventDate = earliest such date); the
//   discipline goal becomes goalSecondary with L10's default weight 70. This
//   is exactly how the app expresses "prepare a test on a date". Other goals
//   (habit, skill_unlocked, holds, running times, bench 1RM…) have no L10
//   equivalent and are only noted.
//
// AVAILABILITY
//   weekdays       = sorted distinct `availability[].weekday` (1 = Monday).
//   sessionMinutes = L10 takes ONE duration for every session: the LOWER
//                    MEDIAN of the per-day minutes (a value the user really
//                    entered; never above what most days allow), clamped to
//                    L10's 10..240. Per-day minutes are kept in the trace and
//                    a note is recorded when they differ.
//
// PLACES / EQUIPMENT
//   salle → gym, exterieur → park, maison → home_equipped when at least one
//   mapped equipment other than the mat is available there, else home_none.
//   Equipment of a place = `equipmentByPlace` entry when present, otherwise
//   the whole profile `equipment` list (the v2 profile is not place-bound, so
//   every place receives the full list; noted when there are several places).
//   dayPlace[weekday] = `availability[].place` when given, else the FIRST
//   place of `places` (without it L10 would take the alphabetically first
//   L10 place id).
//   French equipment → L10 ids: see [_equipToL10]. Items L10 deduces by itself
//   (wall, towel, stick, low bar…) are in [_equipImplicit]; everything else is
//   listed in the notes as unmapped (L10 simply cannot use it).
//
// LEVELS (L10 derives 5 movement levels 0..4 from `measures` only)
//   Only `movementLevels` with known == true are used, with the LOW bound
//   (L10's own prudence rule D-L10-01), source 'estimated':
//     sw-pompe max_reps                      → measures.pushups
//     sw-traction-pronation max_reps         → measures.pullups
//     mu-gainage-ventral-coudes hold seconds → measures.plankSeconds
//     mu-back-squat-barre-haute / sl-squat-competition 1RM
//                                            → measures.squatRatio (÷ weight)
//     sl-traction-lestee 1RM (added load)    → measures.pullLoadPct (% weight)
//     sl-dips-leste 1RM (added load)         → measures.dipLoadPct (% weight)
//   and the Pilotage references used for loads: B4 = body weight, B8 pull,
//   B9 dip, B10 muscle-up, B11 squat. Every other measure (bench, deadlift,
//   knee/wall push-ups, air squats, holds, running…) has no L10 input: noted.
//   `experience` is NOT an L10 generator input: noted, never converted into
//   fake measures. Without any mapped measure L10 puts every movement at
//   level 0 (débutant).
//
// LIMITATIONS → pains (pack joint → 0..10), max discomfort per joint, zone
//   mapped with L10's own kZoneToJoint (wrist_hand → wrist). The side is lost.
//   L10 only excludes exercises when discomfort > 3.
//
// CAUTION (L10 "mode prudent": RIR ≥ 3, difficulty −1, no impact) — same
//   rules as the app (lib/profile.dart evaluateCaution): health screening
//   outcome `cautious` or `not_answered`, age ≥ 65 in 2026, or any discomfort
//   > 3 (the doctor's clearance that lifts it in the app is unknown here).
//
// LIKED / DISLIKED: L10 takes NAMES of its own (old) exercise base. Each new
//   id is resolved (1) with the explicit table [_newToOldId], else (2) by the
//   name/aliases of the new base (packages/kalis_core/data/source/
//   base_exercices_v1.1.0.json) through GenCatalog.idForName. Unresolved ids
//   are dropped and noted. `cannotDoExerciseIds` are added to disliked (hard
//   exclusion is the closest L10 notion).
//
// NOT L10 INPUTS (ignored, noted once in `globalNotes`): sex, heightCm,
//   loadIncrements, knownExerciseIds, displayName. bodyWeightKg and birthYear
//   are only used as described above.
//
// OTHER: autonomy = guidanceMode (assisted → assisted, free → expert; stored
//   by L10, not used by the generator); split = 'auto'; focus = '' (L10
//   chooses pull-ups with a bar, else push-ups); calibration = true (app
//   default for a first programme: light calibration sets in weeks 1-2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/atlas_data.dart' show atlasMuscles;
import 'package:streetlift_tracker/program_generator.dart';

import 'support/l10_support.dart';

const _profilesPath = 'packages/kalis_core/test/fixtures/profiles.json';
const _newBasePath =
    'packages/kalis_core/data/source/base_exercices_v1.1.0.json';
const _outPath = 'out-packages/kalis_plan/l10/l10_outputs.json';
const _seed = 0;
const _kMapDatedGoalsToEvent = true;

final DateTime _start = DateTime(2026, 10, 5);

const _disciplineGoal = <String, String>{
  'general_fitness': 'health',
  'mobility': 'health',
  'cardio': 'health',
  'musculation': 'strength',
  'streetlifting': 'strength',
  'calisthenics': 'strength',
  'street_workout': 'endurance',
  'crossfit': 'endurance',
};

const _disciplineNote = <String, String>{
  'mobility':
      'discipline mobility: L10 has no mobility programme; run as goal '
      '"health" (full-body strength work + short mobility cool-down).',
  'cardio':
      'discipline cardio: L10 has no cardio programme (distance exercises '
      'are excluded); run as goal "health".',
  'calisthenics':
      'discipline calisthenics: L10 has no skills goal (figures are never '
      'selected outside a muscle-up event); run as goal "strength".',
  'crossfit':
      'discipline crossfit: L10 has no WOD/conditioning programme; run as '
      'goal "endurance" (rep endurance with density blocks).',
  'musculation':
      'discipline musculation: L10 has no hypertrophy goal; run as goal '
      '"strength".',
};

/// `exerciseId|metric` of a dated performance goal → L10 event item.
const _goalEvent = <String, String>{
  'sl-traction-lestee|one_rm_kg': 'pull_1rm',
  'sl-dips-leste|one_rm_kg': 'dip_1rm',
  'sl-muscle-up-leste|one_rm_kg': 'mu_1rm',
  'sl-squat-competition|one_rm_kg': 'squat_1rm',
  'mu-back-squat-barre-haute|one_rm_kg': 'squat_1rm',
  'sw-traction-pronation|max_reps': 'pullups_max',
  'sw-dips-barres-paralleles|max_reps': 'dips_max',
  'sw-pompe|max_reps': 'pushups_max',
  'cd-muscle-up-barre-strict|max_reps': 'mu_max',
};

/// French equipment (new base) → L10 normalised equipment id (kEquipment of
/// lib/profile.dart, keys of kEquipmentToPack).
const _equipToL10 = <String, String>{
  'barre fixe': 'pullup_bar',
  'barres parallèles': 'dip_bars',
  'station dips / relevés de jambes': 'dip_bars',
  'anneaux': 'rings',
  'sangles de suspension': 'rings',
  'élastique': 'bands',
  'bande de résistance mini (mini-band)': 'bands',
  'haltères': 'dumbbells',
  'kettlebell': 'kettlebell',
  'barre olympique': 'barbell',
  'cage / rack': 'rack',
  'banc plat': 'bench',
  'banc inclinable': 'bench',
  'ceinture de lest': 'weight_belt',
  'gilet lesté': 'weight_belt',
  'machine guidée': 'machines',
  'poulie': 'machines',
  'presse à cuisses': 'machines',
  'hack squat': 'machines',
  'Smith machine': 'machines',
  'machine à mollets': 'machines',
  'box / plinth': 'box',
  'step': 'box',
  'corde à sauter': 'jump_rope',
  'rameur': 'erg',
  'vélo / home-trainer': 'erg',
  'air bike (assault / echo)': 'erg',
  'SkiErg': 'erg',
  'tapis': 'mat',
};

/// Equipment L10 deduces by itself (no input id): always available, implied
/// by the place, or bundled with another id.
const _equipImplicit = <String>{
  'mur', // always available (kAlwaysPack)
  'bâton', // implied at home (kPlaceImpliedPack)
  'serviette', // implied at home and in a gym
  'barre basse', // implied in a park, and in a gym with a rack
  'poteau vertical', // bundled with pullup_bar
  'piste ou terrain extérieur', // implied in a park (espace_exterieur)
  'disques', // bundled with barbell
};

/// New exercise id → OLD pack id, for liked / disliked exercises whose name
/// does not match automatically. Only unambiguous equivalents.
const _newToOldId = <String, String>{
  'cf-burpee': 'burpees',
  'mu-souleve-de-terre-conventionnel': 'souleve-de-terre',
  'mu-souleve-de-terre-roumain-barre': 'souleve-de-terre-roumain',
  'mu-good-morning-barre': 'good-mornings',
  'mu-face-pull-corde': 'face-pulls',
  'mu-hip-thrust-barre': 'hip-thrust',
  'mu-fente-marchee-halteres': 'fentes-marchees-halteres',
  'mu-leg-extension': 'leg-extension',
  'sw-traction-supination': 'traction-supination',
  'ca-corde-double-unders': 'double-unders',
  'ca-rameur-endurance': 'rameur',
  'cs-front-lever-tuck-avance': 'front-lever-advanced-tuck',
  'cs-front-lever': 'front-lever-complet',
  'cs-handstand': 'atr-equilibre',
};

const _jointFallback = <String, String>{
  'epaule': 'epaule',
  'coude': 'coude',
  'poignet': 'poignet',
  'lombaires': 'rachis_lombaire',
  'cervicales': 'rachis_cervical',
  'hanche': 'hanche',
  'genou': 'genou',
  'cheville': 'cheville',
};

Map<String, dynamic> _obj(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => [
  for (final x in (v is List ? v : const <Object?>[]))
    if (x is Map) x.cast<String, dynamic>(),
];

List<String> _strs(Object? v) => [
  for (final x in (v is List ? v : const <Object?>[])) '$x',
];

int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class _Equip {
  final List<String> ids;
  final List<String> implicit;
  final List<String> unmapped;
  const _Equip(this.ids, this.implicit, this.unmapped);
}

_Equip _mapEquipment(List<String> french) {
  final ids = <String>{};
  final implicit = <String>[];
  final unmapped = <String>[];
  for (final f in french) {
    final id = _equipToL10[f];
    if (id != null) {
      ids.add(id);
    } else if (_equipImplicit.contains(f)) {
      implicit.add(f);
    } else {
      unmapped.add(f);
    }
  }
  return _Equip(ids.toList()..sort(), implicit, unmapped);
}

class _Mapped {
  final GenInputs inputs;
  final List<String> notes;
  final Map<String, dynamic> trace;
  const _Mapped(this.inputs, this.notes, this.trace);
}

/// Old-pack NAME to give to L10 for a new exercise id (null: unresolved).
String? _oldNameFor(
  String newId,
  GenCatalog catalog,
  Map<String, List<String>> newNames,
  List<Map<String, dynamic>> resolved,
  List<String> notes,
  String what,
) {
  String? oldId;
  var via = '';
  final table = _newToOldId[newId];
  if (table != null && catalog.byId.containsKey(table)) {
    oldId = table;
    via = 'table';
  } else {
    for (final n in newNames[newId] ?? const <String>[]) {
      final hit = catalog.idForName(n);
      if (hit != null) {
        oldId = hit;
        via = 'name "$n"';
        break;
      }
    }
  }
  if (oldId == null) {
    notes.add(
      '$what exercise $newId has no equivalent found in the old base: '
      'dropped.',
    );
    return null;
  }
  // L10 resolves names with GenCatalog.idForName: pick a name that really
  // leads back to this id.
  final e = catalog.byId[oldId]!;
  for (final n in [e.nom, e.name, ...e.alias]) {
    if (catalog.idForName(n) == oldId) {
      resolved.add({'what': what, 'newId': newId, 'oldId': oldId, 'via': via});
      return n;
    }
  }
  notes.add(
    '$what exercise $newId → old $oldId, but no name of it resolves back '
    'through idForName: dropped.',
  );
  return null;
}

_Mapped _mapProfile(
  Map<String, dynamic> p,
  GenCatalog catalog,
  Map<String, List<String>> newNames,
) {
  final notes = <String>[];
  final trace = <String, dynamic>{};

  // ------------------------------------------------------------ goals
  final disc = _obj(p['disciplines']);
  final primaryDisc = '${disc['primary']}';
  final share = <String, int>{};
  final seenDisc = <String>{};
  void addDiscipline(String d, int pct) {
    var goal = _disciplineGoal[d];
    if (goal == null) {
      notes.add('discipline $d unknown to this mapping: run as "health".');
      goal = 'health';
    }
    if (seenDisc.add(d) && _disciplineNote[d] != null) {
      notes.add('${_disciplineNote[d]} ($pct %)');
    }
    share[goal] = (share[goal] ?? 0) + pct;
  }

  addDiscipline(primaryDisc, (disc['primaryPct'] as num?)?.toInt() ?? 100);
  for (final s in _maps(disc['secondaries'])) {
    addDiscipline('${s['discipline']}', (s['pct'] as num?)?.toInt() ?? 0);
  }
  var goalPrimary = _disciplineGoal[primaryDisc] ?? 'health';
  String? goalSecondary;
  var goalWeight = 100;
  final others = share.keys.where((g) => g != goalPrimary).toList()..sort();
  if (others.isNotEmpty) {
    others.sort((a, b) {
      final c = share[b]!.compareTo(share[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
    goalSecondary = others.first;
    final pp = share[goalPrimary] ?? 0, ps = share[goalSecondary]!;
    goalWeight = pp + ps <= 0
        ? 70
        : _clamp((100 * pp / (pp + ps)).round(), 50, 100);
  }
  if (goalPrimary == 'health' && goalSecondary != null) {
    notes.add(
      'goalSecondary "$goalSecondary" is passed but L10 ignores the '
      'secondary goal in its "health" model.',
    );
  }
  trace['goalShareByL10Goal'] = share;
  if (p['streetMode'] != null) {
    notes.add(
      'streetMode is not an L10 input; its split is carried by the '
      'disciplines mapping only.',
    );
  }

  DateTime? eventDate;
  final eventItems = <String>{};
  final goalTrace = <Map<String, dynamic>>[];
  for (final g in _maps(p['goals'])) {
    final kind = '${g['kind']}';
    if (kind != 'performance') {
      notes.add(
        'goal ${g['id']} ($kind, ${g['sessionsPerWeek']} sessions/week, '
        '${g['weeks']} weeks) has no L10 input: ignored (days come from '
        'availability).',
      );
      continue;
    }
    final key = '${g['exerciseId']}|${g['metric']}';
    final item = _goalEvent[key];
    final date = parseCivil(g['targetDate']);
    if (!_kMapDatedGoalsToEvent || item == null || date == null) {
      notes.add(
        'performance goal ${g['id']} ($key, target ${g['targetValue']} on '
        '${g['targetDate']}) cannot be expressed in L10: ignored.',
      );
      continue;
    }
    eventItems.add(item);
    if (eventDate == null || date.isBefore(eventDate)) eventDate = date;
    goalTrace.add({'goal': g['id'], 'key': key, 'eventItem': item});
  }
  if (eventItems.isNotEmpty && eventDate != null) {
    final byDiscipline = goalPrimary;
    goalSecondary = byDiscipline;
    goalPrimary = 'event';
    goalWeight = 70;
    final weeks =
        (civilDayIndex(eventDate) - civilDayIndex(_start)) ~/ 7 + 1;
    notes.add(
      'dated performance goal(s) → goalPrimary "event" '
      '(${eventItems.join(', ')}, date ${civilIsoDate(eventDate)}, '
      '$weeks weeks from start); discipline goal "$byDiscipline" becomes '
      'goalSecondary with weight 70. L10 ignores the target VALUE.'
      '${weeks > 40 ? ' Date beyond 40 weeks: L10 produces one ordinary cycle.' : ''}',
    );
    trace['eventGoals'] = goalTrace;
  }

  // ----------------------------------------------------- availability
  final minutesByDay = <int, int>{};
  final placeCodeByDay = <int, String>{};
  for (final a in _maps(p['availability'])) {
    final wd = (a['weekday'] as num?)?.toInt();
    final min = (a['minutes'] as num?)?.toInt();
    if (wd == null || wd < 1 || wd > 7 || min == null) {
      notes.add('availability entry ignored (invalid): ${jsonEncode(a)}');
      continue;
    }
    minutesByDay[wd] = min;
    if (a['place'] != null) placeCodeByDay[wd] = '${a['place']}';
  }
  var weekdays = minutesByDay.keys.toList()..sort();
  var sessionMinutes = 45;
  if (weekdays.isEmpty) {
    weekdays = [1, 3, 5];
    notes.add(
      'no availability: L10 defaults used (Mon/Wed/Fri, 45 min), as the app '
      'does.',
    );
  } else {
    final all = [for (final d in weekdays) minutesByDay[d]!];
    sessionMinutes = _clamp(lowerMedian(all), 10, 240);
    if (all.toSet().length > 1) {
      notes.add(
        'per-day minutes differ (${[for (final d in weekdays) '$d:${minutesByDay[d]}'].join(', ')}): L10 '
        'takes one duration → lower median $sessionMinutes min for every '
        'session.',
      );
    }
  }
  trace['minutesByWeekday'] = {
    for (final d in weekdays)
      if (minutesByDay[d] != null) '$d': minutesByDay[d],
  };

  // ------------------------------------------------- places, equipment
  final byPlace = <String, List<String>>{
    for (final e in _maps(p['equipmentByPlace']))
      '${e['place']}': _strs(e['equipment']),
  };
  final globalEquipment = _strs(p['equipment']);
  final places = <String, List<String>>{};
  final placeOf = <String, String>{}; // new code → L10 place id
  final unmapped = <String>{};
  final implicit = <String>{};
  final placeCodes = _strs(p['places']);
  for (final code in placeCodes) {
    final eq = _mapEquipment(byPlace[code] ?? globalEquipment);
    unmapped.addAll(eq.unmapped);
    implicit.addAll(eq.implicit);
    String? l10;
    if (code == 'salle') {
      l10 = 'gym';
    } else if (code == 'exterieur') {
      l10 = 'park';
    } else if (code == 'maison') {
      l10 = eq.ids.any((e) => e != 'mat') ? 'home_equipped' : 'home_none';
    }
    if (l10 == null) {
      notes.add('place "$code" unknown to L10: ignored.');
      continue;
    }
    placeOf[code] = l10;
    places[l10] = eq.ids;
  }
  if (places.isEmpty) {
    places['home_none'] = const [];
    notes.add('no usable place: L10 default "home_none" without equipment.');
  }
  if (placeOf.length > 1 && byPlace.isEmpty) {
    notes.add(
      'several places and no equipmentByPlace: every L10 place receives the '
      'whole equipment list.',
    );
  }
  if (unmapped.isNotEmpty) {
    notes.add(
      'equipment without L10 id (unusable by L10): '
      '${(unmapped.toList()..sort()).join(', ')}.',
    );
  }
  final defaultPlace = placeCodes.isEmpty ? null : placeOf[placeCodes.first];
  final dayPlace = <int, String>{};
  for (final d in weekdays) {
    final code = placeCodeByDay[d];
    final l10 = (code == null ? null : placeOf[code]) ?? defaultPlace;
    if (code != null && placeOf[code] == null) {
      notes.add('availability place "$code" (weekday $d) is not a profile '
          'place: default place used.');
    }
    if (l10 != null) dayPlace[d] = l10;
  }
  if (placeOf.length > 1) {
    notes.add(
      'days without an explicit place train at the first profile place '
      '("${placeCodes.first}").',
    );
  }
  trace['placeOf'] = placeOf;
  trace['equipmentImplicitInL10'] = implicit.toList()..sort();
  trace['equipmentUnmapped'] = unmapped.toList()..sort();

  // ----------------------------------------------------------- levels
  final bw = (p['bodyWeightKg'] as num?)?.toDouble();
  final measures = <String, double>{};
  final references = <String, double>{};
  if (bw != null && bw > 0) references['B4'] = bw;
  void setMax(Map<String, double> m, String k, double v) {
    final prev = m[k];
    if (prev == null || v > prev) m[k] = v;
  }

  final unknownLevels = <String>[];
  final unusedLevels = <String>[];
  for (final ml in _maps(p['movementLevels'])) {
    final id = '${ml['exerciseId']}';
    final measure = '${ml['measure']}';
    final low = (ml['low'] as num?)?.toDouble();
    if (ml['known'] != true || low == null) {
      unknownLevels.add(id);
      continue;
    }
    final key = '$id|$measure';
    switch (key) {
      case 'sw-pompe|max_reps':
        setMax(measures, 'pushups', low);
      case 'sw-traction-pronation|max_reps':
        setMax(measures, 'pullups', low);
      case 'mu-gainage-ventral-coudes|max_hold_seconds':
        setMax(measures, 'plankSeconds', low);
      case 'mu-back-squat-barre-haute|one_rm_kg' ||
          'sl-squat-competition|one_rm_kg':
        setMax(references, 'B11', low);
        if (bw != null && bw > 0) {
          setMax(measures, 'squatRatio', low / bw);
        } else {
          notes.add('$id known but no body weight: squatRatio not computable.');
        }
      case 'sl-traction-lestee|one_rm_kg':
        setMax(references, 'B8', low);
        if (bw != null && bw > 0) {
          setMax(measures, 'pullLoadPct', low / bw * 100);
        } else {
          notes.add('$id known but no body weight: pullLoadPct not computable.');
        }
      case 'sl-dips-leste|one_rm_kg':
        setMax(references, 'B9', low);
        if (bw != null && bw > 0) {
          setMax(measures, 'dipLoadPct', low / bw * 100);
        } else {
          notes.add('$id known but no body weight: dipLoadPct not computable.');
        }
      case 'sl-muscle-up-leste|one_rm_kg':
        setMax(references, 'B10', low);
      default:
        unusedLevels.add('$id ($measure ${ml['low']}-${ml['high']})');
    }
  }
  if (unusedLevels.isNotEmpty) {
    notes.add(
      'movement levels with no L10 measure (ignored): '
      '${unusedLevels.join(', ')}.',
    );
  }
  if (unknownLevels.isNotEmpty) {
    notes.add(
      'movement levels declared unknown: ${unknownLevels.join(', ')} → no '
      'L10 measure (L10 falls back to the global level).',
    );
  }
  if (measures.isEmpty) {
    notes.add(
      'no L10 measure available: L10 treats every movement as level 0 '
      '(débutant).',
    );
  }
  if (p['experience'] != null) {
    notes.add(
      'experience "${p['experience']}" is not an L10 generator input: '
      'ignored (levels come from measures only).',
    );
  }
  // Low bound of a declared range → source "estimated" (as the app does for
  // profile benchmarks).
  final measureSources = {for (final k in measures.keys) k: 'estimated'};

  // ----------------------------------------------- limitations, caution
  final pains = <String, int>{};
  var painAbove3 = false;
  for (final l in _maps(p['limitations'])) {
    var zone = '${l['zone']}';
    if (zone == 'wrist_hand') zone = 'wrist';
    final joint = kZoneToJoint[zone] ?? _jointFallback['${l['joint']}'];
    final level = (l['discomfort'] as num?)?.toInt() ?? 0;
    if (joint == null) {
      notes.add('limitation zone "${l['zone']}" has no L10 joint: ignored.');
      continue;
    }
    if (level > (pains[joint] ?? 0)) pains[joint] = _clamp(level, 0, 10);
    if (level > 3) painAbove3 = true;
    if ('${l['side']}' != 'both') {
      notes.add(
        'limitation $joint: side "${l['side']}" lost (L10 has no side).',
      );
    }
    if (level > 0 && level <= 3) {
      notes.add(
        'limitation $joint $level/10: passed, but L10 only filters exercises '
        'above 3/10.',
      );
    }
  }
  final birthYear = (p['birthYear'] as num?)?.toInt();
  final age = birthYear == null ? null : _start.year - birthYear;
  final outcome = '${_obj(p['healthScreening'])['outcome']}';
  final cautionReasons = <String>[
    if (outcome == 'cautious') 'healthScreening cautious',
    if (outcome == 'not_answered') 'healthScreening not answered',
    if (age != null && age >= 65) 'age $age ≥ 65',
    if (painAbove3) 'discomfort > 3/10',
  ];
  final caution = cautionReasons.isNotEmpty;
  if (caution) {
    notes.add('L10 caution mode ON (${cautionReasons.join(' ; ')}).');
  }
  trace['age'] = age;
  trace['cautionReasons'] = cautionReasons;

  // -------------------------------------------------- liked / disliked
  final resolved = <Map<String, dynamic>>[];
  final liked = <String>[];
  for (final id in _strs(p['likedExerciseIds'])) {
    final n = _oldNameFor(id, catalog, newNames, resolved, notes, 'liked');
    if (n != null && !liked.contains(n)) liked.add(n);
  }
  final disliked = <String>[];
  for (final id in _strs(p['dislikedExerciseIds'])) {
    final n = _oldNameFor(id, catalog, newNames, resolved, notes, 'disliked');
    if (n != null && !disliked.contains(n)) disliked.add(n);
  }
  for (final id in _strs(p['cannotDoExerciseIds'])) {
    final n = _oldNameFor(id, catalog, newNames, resolved, notes, 'cannotDo');
    if (n != null && !disliked.contains(n)) disliked.add(n);
  }
  if (_strs(p['knownExerciseIds']).isNotEmpty) {
    notes.add('knownExerciseIds are not an L10 input: ignored.');
  }
  trace['exerciseIdResolution'] = resolved;

  final autonomy = '${p['guidanceMode']}' == 'free' ? 'expert' : 'assisted';

  final inputs = GenInputs(
    start: _start,
    goalPrimary: goalPrimary,
    goalSecondary: goalSecondary,
    goalWeight: goalWeight,
    eventDate: goalPrimary == 'event' ? eventDate : null,
    eventItems: goalPrimary == 'event'
        ? (eventItems.toList()..sort())
        : const [],
    weekdays: weekdays,
    sessionMinutes: sessionMinutes,
    dayPlace: dayPlace,
    places: places,
    disliked: disliked,
    liked: liked,
    pains: pains,
    caution: caution,
    autonomy: autonomy,
    measures: measures,
    measureSources: measureSources,
    references: references,
    split: 'auto',
    focus: '',
    calibration: true,
  );
  return _Mapped(inputs, notes, trace);
}

/// Old database entry of an exercise (generator view + raw sheet fields).
Map<String, dynamic> _oldEntry(GenExercise e, Map<String, dynamic> raw) => {
  'id': e.id,
  'name': e.name,
  'nom': e.nom,
  'alias': e.alias,
  // Movement pattern of the old base and L10's derived family / reference
  // movement.
  'type': e.type,
  'family': e.family,
  'refMovement': e.refMovement,
  'famille': raw['famille'],
  'plan': raw['plan'],
  'role': e.role,
  'difficulty': e.difficulty,
  'loadMode': e.loadMode,
  'loaded': e.loaded,
  'measure': e.measure,
  'unilateral': e.unilateral,
  'impact': e.impact,
  'demo': e.demo,
  'materiel': e.materiel,
  'lieux': e.lieux,
  // `groups`: groups of the PRIMARY muscles — the ones L10 counts weekly
  // hard sets on. `allGroups`: every group listed in the index.
  'groups': e.groups,
  'allGroups': e.allGroups,
  'musclesPrimaires': _strs(raw['muscles_primaires']),
  'musclesSecondaires': _strs(raw['muscles_secondaires']),
  'musclesStabilisateurs': _strs(raw['muscles_stabilisateurs']),
  'joints': e.joints,
  'prerequis': e.prereq,
};

void main() {
  test('export L10 programs for the kalis_core profile fixtures', () {
    final out = <String, dynamic>{
      'generatedBy': 'test/zz_l10_export_test.dart',
      'generatorVersion': kGeneratorVersion,
      'seed': _seed,
      'start': civilIsoDate(_start),
      'globalNotes': [
        'L10 inputs do not include: sex, heightCm, loadIncrements, '
            'knownExerciseIds, displayName, experience, streetMode.',
        'program.pilotage (owner base data copied by L10) is omitted; '
            'program.meta and program.weeks are complete.',
        'sessions[].l10EstimateSeconds is the `estimate` L10 writes in each '
            'day (its own TrainingEstimator sum, 45 s between exercises); '
            'recomputedMinutes re-runs the same public estimator on the '
            'exported exercises.',
      ],
    };
    final profilesOut = <String, dynamic>{};
    final usedIds = <String>{};
    try {
      final data = L10Data.load();
      final catalog = data.catalog;
      final details = readGz('assets/content/details.json.gz');
      final sheets = _obj(details['exercices']);
      out['modelsVersion'] = data.models.version;
      out['oldDatabase'] = {
        'sources': [
          'assets/content/index.json.gz',
          'assets/content/details.json.gz',
          'assets/content/progressions.json.gz',
        ],
        'exerciseCount': catalog.all.length,
        'usableByGenerator': catalog.all.where((e) => e.usable).length,
        'chains': catalog.chains.length,
      };
      out['muscleTaxonomy'] = {
        for (final e in atlasMuscles.entries)
          e.key: {
            'nom': e.value.nom,
            'famille': e.value.famille,
            'groupe': e.value.groupe,
          },
      };

      // Names and aliases of the new base (only to resolve liked / disliked).
      final newNames = <String, List<String>>{};
      final newBase = File(_newBasePath);
      if (newBase.existsSync()) {
        final b = _obj(jsonDecode(newBase.readAsStringSync()));
        for (final e in _maps(b['exercices'])) {
          newNames['${e['id']}'] = [
            if (e['nom'] != null) '${e['nom']}',
            ..._strs(e['alias']),
          ];
        }
      } else {
        (out['globalNotes'] as List).add(
          '$_newBasePath not found: liked/disliked resolved with the '
          'explicit table only.',
        );
      }

      final fixtures = _obj(
        jsonDecode(File(_profilesPath).readAsStringSync()),
      );
      for (final f in _maps(fixtures['profiles'])) {
        final key = '${f['key']}';
        final entry = <String, dynamic>{
          'description': f['description'],
          'mappingNotes': <String>[],
          'error': null,
        };
        profilesOut[key] = entry;
        try {
          final mapped = _mapProfile(_obj(f['profile']), catalog, newNames);
          entry['inputs'] = mapped.inputs.toJson();
          entry['mappingNotes'] = mapped.notes;
          entry['mappingTrace'] = mapped.trace;
          entry['levels'] = movementLevels(
            data.models,
            mapped.inputs,
          ).toJson();
          final g = generateProgram(
            models: data.models,
            catalog: catalog,
            base: data.base,
            inputs: mapped.inputs,
            seed: _seed,
          );
          final weeks = g.program['weeks'] as List;
          final sessions = <Map<String, dynamic>>[];
          for (final w in weeks) {
            final wm = _obj(w);
            for (final d in _maps(wm['days'])) {
              final exs = _maps(d['exercises']);
              if (exs.isEmpty) continue;
              for (final e in exs) {
                final id = e['exId'];
                if (id is String) usedIds.add(id);
              }
              double? recomputed;
              try {
                recomputed = dayMinutes(d);
              } catch (_) {
                recomputed = null;
              }
              final estimate = d['estimate'];
              sessions.add({
                'week': wm['n'],
                'j': d['j'],
                'title': d['title'],
                'kind': d['kind'],
                'place': d['place'],
                'budgetMinutes': d['minutes'],
                'exercises': exs.length,
                'l10EstimateSeconds': estimate,
                'l10EstimateMinutes': estimate is num
                    ? (estimate / 60 * 10).round() / 10
                    : null,
                'recomputedMinutes': recomputed == null
                    ? null
                    : (recomputed * 10).round() / 10,
                'capped': d['capped'] == true,
              });
            }
          }
          entry['summary'] = g.summary;
          entry['sessions'] = sessions;
          entry['koachExercises'] = g.koach['exercises'];
          entry['program'] = {'meta': g.program['meta'], 'weeks': weeks};
          // Fail here (inside the try) rather than at the final write if
          // something is not encodable.
          jsonEncode(entry);
        } catch (e, st) {
          entry['error'] = '$e';
          entry['errorStack'] = '$st'.split('\n').take(12).join('\n');
          entry.remove('program');
          entry.remove('summary');
          entry.remove('sessions');
          entry.remove('koachExercises');
        }
      }

      final ids = usedIds.toList()..sort();
      out['exercises'] = {
        for (final id in ids)
          if (catalog.byId[id] != null)
            id: _oldEntry(catalog.byId[id]!, _obj(sheets[id])),
      };
      out['exercisesUnknownToCatalog'] = [
        for (final id in ids)
          if (catalog.byId[id] == null) id,
      ];
    } catch (e, st) {
      out['fatalError'] = '$e';
      out['fatalStack'] = '$st'.split('\n').take(12).join('\n');
    }
    out['profileCount'] = profilesOut.length;
    out['profiles'] = profilesOut;

    final file = File(_outPath)..createSync(recursive: true);
    file.writeAsStringSync('${jsonEncode(out)}\n');
    // ignore: avoid_print
    print(
      'L10 export: ${profilesOut.length} profiles, '
      '${profilesOut.values.where((p) => (p as Map)['error'] != null).length} '
      'errors, ${usedIds.length} distinct exercises → $_outPath '
      '(${file.lengthSync()} bytes)'
      '${out['fatalError'] == null ? '' : ' — FATAL: ${out['fatalError']}'}',
    );
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
