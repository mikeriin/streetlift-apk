// Politique de référence « L7/L11 » du simulateur : l'ancien moteur Koach
// (copie figée `koach_engine.dart`) piloté comme l'application 6.0.1 le
// pilotait — repères de charge par mouvement, propositions appliquées
// après chaque séance, conseil pendant la séance, règle de reprise L11.
//
// Portage de l'adaptateur Python de mise au point (même logique) :
// - mouvement principal chargé → « lift » de L7 (filtre de Kalman sur le
//   1RM système, k = 22,4) ; charge = part du repère pour les répétitions
//   prévues au RIR visé ;
// - autre exercice chargé → « accessoire » de L7 (double progression D22) ;
// - exercice sans charge → plage du bloc au ressenti (L7 ne prescrivait pas
//   ces exercices) ;
// - L7 compte le poids du corps entier pour un mouvement lesté.
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

import 'koach_engine.dart' as l7;

const double _k = 22.4;
const double _day = 86400;

String _equipmentOf(LoadType type) {
  switch (type) {
    case LoadType.barbell:
      return 'barbell';
    case LoadType.dumbbells:
    case LoadType.kettlebell:
      return 'dumbbell';
    case LoadType.machine:
      return 'machine';
    case LoadType.cable:
      return 'pulley';
    case LoadType.addedWeight:
    case LoadType.none:
    case LoadType.bodyweight:
    case LoadType.band:
    case LoadType.other:
      return 'plate';
  }
}

final class _Current {
  _Current(this.item, this.info, this.main, this.ref, this.body);

  final ExercisePrescription item;
  final ExerciseInfo info;
  final bool main;
  final String ref;
  final bool body;
  double? kg;
  int sets = 0;
  int planned = 0;
  double rir = 2;
  final List<Map<String, dynamic>> done = <Map<String, dynamic>>[];
}

/// Ancien moteur L7 + règle de reprise L11.
final class L7Policy implements SimPolicy {
  /// Politique pour un athlète de poids de corps [bodyWeightKg].
  L7Policy(this.bodyWeightKg) {
    _input = <String, dynamic>{
      'now': _stamp(0, 0),
      'lifts': <Map<String, dynamic>>[],
      'repmax': <Map<String, dynamic>>[],
      'accessories': <Map<String, dynamic>>[],
      'references': <String, dynamic>{'B4': bodyWeightKg},
      'history': <Map<String, dynamic>>[],
      'weighIns': <Map<String, dynamic>>[],
      'sessions': <Map<String, dynamic>>[],
      'pain': <String, dynamic>{},
    };
  }

  /// Poids de corps, en kg.
  final double bodyWeightKg;

  late final Map<String, dynamic> _input;
  l7.KoachState? _state;
  final Set<String> _known = <String>{};
  final Map<String, _Current> _current = <String, _Current>{};
  final List<_Current> _order = <_Current>[];
  int _count = 0;
  int? _lastDay;
  int _dayNumber = 0;
  double _minute = 0;
  double _cut = 0;
  int _setCut = 0;
  bool _started = false;

  @override
  String get name => 'L7/L11';

  static String _stamp(int dayNumber, double minute) =>
      l7.isoOf(dayNumber * _day + 18 * 3600 + minute * 60);

  Map<String, dynamic> get _references =>
      _input['references'] as Map<String, dynamic>;

  void _setReference(String ref, double value, String source) {
    _references[ref] = value;
    (_input['history'] as List<Map<String, dynamic>>).add(<String, dynamic>{
      'at': _stamp(_dayNumber, source == 'initial' ? -60 : 125),
      'ref': ref,
      'value': value,
      'source': source,
    });
  }

  double _floorKg(ExerciseInfo info) => info.grid.minimum;

  @override
  SessionPlan plan(SessionContext c) {
    _dayNumber = c.date.dayNumber;
    if (!_started) {
      _started = true;
      (_input['weighIns'] as List<Map<String, dynamic>>).add(<String, dynamic>{
        'date': _stamp(_dayNumber, 0).substring(0, 10),
        'kg': bodyWeightKg,
      });
    }
    _minute = 0;
    _count++;
    final last = _lastDay;
    final gap = last == null ? 0 : _dayNumber - last;
    // L11 (KT-060) : règle de reprise après un arrêt.
    if (gap >= 28) {
      _cut = 0.30;
      _setCut = 0;
    } else if (gap >= 14) {
      _cut = 0.20;
      _setCut = 0;
    } else if (gap > 7) {
      _cut = 0.10;
      _setCut = 1;
    } else {
      _cut = 0;
      _setCut = 0;
    }
    _current.clear();
    _order.clear();
    final overall = c.health?.overall;
    final items = <ExercisePrescription>[];
    for (final item in c.prescription.items) {
      final info = c.book.find(item.exerciseId);
      if (info == null || info.mode != CapacityMode.loaded) {
        items.add(item);
        continue;
      }
      final main = c.roleOf(item.slotId) == SlotRole.main;
      final ref = 'R_${item.exerciseId}';
      final body = info.fraction > 0;
      final cur = _Current(item, info, main, ref, body);
      final low = item.repsLow ?? item.repsHigh ?? 8;
      final high = item.repsHigh ?? item.repsLow ?? 8;
      final flames = item.targetFlames;
      cur.rir = flames == null ? 2 : Flames.toRir(flames);
      cur.planned = main ? ((low + high) / 2).ceil() : high;
      cur.sets = item.sets;
      final grid = info.grid;
      if (!_known.contains(item.exerciseId)) {
        _known.add(item.exerciseId);
        if (main) {
          (_input['lifts'] as List<Map<String, dynamic>>).add(<String, dynamic>{
            'key': item.exerciseId,
            'ref': ref,
            'bodyweight': body,
            'k': _k,
            'grid': grid.step,
          });
          for (final declared in c.profile.movementLevels) {
            final dl = declared.low;
            final dh = declared.high;
            if (declared.exerciseId == item.exerciseId &&
                declared.known &&
                declared.measure == LevelMeasure.oneRmKg &&
                dl != null &&
                dh != null &&
                dl > 0) {
              // Niveau déclaré : 1RM de charge externe (lest seul).
              final center = math.sqrt(dl * dh);
              _setReference(ref, grid.nearest(center < 0 ? 0 : center), 'initial');
            }
          }
        } else {
          (_input['accessories'] as List<Map<String, dynamic>>).add(
            <String, dynamic>{
              'ref': ref,
              'equipment': _equipmentOf(info.exercise.loadType),
              'prevention': false,
            },
          );
        }
      }
      final reference = (_references[ref] as num?)?.toDouble();
      final bw = body ? bodyWeightKg : 0.0;
      if (reference == null) {
        cur.kg = null; // première série au jugé
      } else if (main) {
        final mass = l7.pctOf(cur.planned + cur.rir, _k) * (reference + bw);
        final kg = grid.nearest(mass - bw);
        cur.kg = kg < _floorKg(info) ? _floorKg(info) : kg;
      } else {
        cur.kg = reference;
      }
      final kg = cur.kg;
      if (kg != null && _cut > 0) {
        final total = (kg + bw) * (1 - _cut);
        final cutKg = grid.floor(total - bw);
        cur.kg = cutKg < _floorKg(info) ? _floorKg(info) : cutKg;
      }
      // D25 : forme basse → moins de séries.
      if (overall != null && overall * 2 <= l7.koachParams['form_max']!) {
        final reduced =
            (item.sets * (1 - l7.koachParams['fatigue_cut_3']!)).round();
        cur.sets = reduced < 1 ? 1 : reduced;
      }
      cur.sets = cur.sets - _setCut < 1 ? 1 : cur.sets - _setCut;
      _current[item.slotId] = cur;
      _order.add(cur);
      items.add(item.copyWith(sets: cur.sets));
    }
    return SessionPlan(
      date: c.date,
      blockId: c.block.pass1.blockId,
      weekIndex: c.weekIndex,
      dayIndex: c.dayIndex,
      items: items,
      adjustments: const <SessionAdjustment>[],
      confidence: 0,
      reasons: const <Reason>[],
    );
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    final cur = _current[item.slotId];
    if (cur == null) {
      return targetOfItem(item, index);
    }
    if (index >= cur.sets) {
      return null;
    }
    if (index > 0) {
      _observe(cur, done.last);
    }
    return SetTarget(
      repsLow: cur.planned,
      repsHigh: cur.planned,
      loadKg: cur.kg,
      flames: Flames.fromRir(cur.rir),
    );
  }

  /// Enregistre la série [set] de l'exercice [cur] et applique le conseil
  /// de séance de L7.
  void _observe(_Current cur, SetRecord set) {
    if (set.slotId != cur.item.slotId || cur.done.length > set.setIndex) {
      return;
    }
    final kg = set.externalLoadKg ?? 0;
    final reps = set.reps ?? 0;
    final flames = set.flames;
    final rir = flames == null ? null : Flames.toRir(flames);
    cur.done.add(<String, dynamic>{
      'kg': l7.r2(kg),
      'reps': reps,
      'rir': rir,
      'excluded': false,
      'done': true,
      'at': _stamp(_dayNumber, _minute),
    });
    _minute += (cur.item.restSeconds ?? 90) / 60 + 1;
    cur.kg ??= kg;
    final info = cur.info;
    final bw = cur.body ? bodyWeightKg : 0.0;
    if (_references[cur.ref] == null) {
      // Repère initial tiré de la première série.
      if (cur.main) {
        final n = reps + (rir ?? cur.rir);
        final value = info.grid.nearest(l7.oneRm(kg + bw, n, _k) - bw);
        _setReference(cur.ref, value < 0 ? 0 : value, 'initial');
      } else {
        _setReference(cur.ref, kg, 'initial');
      }
    }
    if (cur.main) {
      final suggestion = l7.inSession(
        l7.koachParams,
        <String, dynamic>{'bodyweight': cur.body},
        <Map<String, dynamic>>[
          for (final s in cur.done)
            <String, dynamic>{'kg': s['kg'], 'reps': s['reps'], 'rir': s['rir']},
        ],
        cur.rir,
        cur.planned,
        bodyWeightKg,
        info.grid.stepAbove(kg),
        <String, dynamic>{},
      );
      if (suggestion != null) {
        final next = info.grid.nearest(suggestion.kg);
        cur.kg = next < _floorKg(info) ? _floorKg(info) : next;
      }
    }
  }

  @override
  void finish(SessionContext c, SessionRecord record) {
    final exercises = <Map<String, dynamic>>[];
    final pain = <String, dynamic>{};
    for (final cur in _order) {
      for (final s in record.sets) {
        if (s.slotId == cur.item.slotId) {
          _observe(cur, s);
        }
      }
      if (cur.done.isEmpty) {
        continue;
      }
      exercises.add(<String, dynamic>{
        'id': cur.item.exerciseId,
        'cat': cur.main ? 'strength' : 'accessory',
        'ref': cur.ref,
        'restSec': cur.item.restSeconds ?? 90,
        'rirTarget': cur.rir,
        'plannedReps': cur.planned,
        'cluster': false,
        'sets': cur.done,
      });
      if (cur.main) {
        var worst = 0;
        for (final r in record.pains) {
          if (cur.info.zoneLevel(r.zone) >= 0.5 && r.intensity > worst) {
            worst = r.intensity;
          }
        }
        pain[cur.item.exerciseId] = worst;
      }
    }
    final key = 'S$_count-J1';
    final sessions = _input['sessions'] as List<Map<String, dynamic>>;
    sessions.add(<String, dynamic>{
      'key': key,
      'week': c.simDay ~/ 7 + 1,
      'day': 1,
      'done': true,
      'finishedAt': _stamp(_dayNumber, 120),
      'exercises': exercises,
    });
    (_input['pain'] as Map<String, dynamic>)[key] = pain;
    _input['now'] = _stamp(_dayNumber, 124);
    final state = l7.replayIncremental(_input, _state);
    _state = state;
    for (final proposal in l7.proposals(_input, state, key)) {
      final to = proposal['to'];
      final ref = proposal['ref'];
      if (proposal['kind'] != 'value' || to is! num || ref is! String) {
        continue;
      }
      var value = to.toDouble();
      // Les repères d'accessoires sont des charges : ramenées sur la
      // grille du matériel de l'athlète.
      for (final cur in _order) {
        if (cur.ref == ref && !cur.main) {
          final from = (_references[ref] as num?)?.toDouble();
          var snapped = cur.info.grid.nearest(value);
          if (from != null && snapped == from && value != from) {
            snapped = cur.info.grid.next(from, up: value > from);
          }
          value = snapped;
        }
      }
      _setReference(ref, value, 'koach');
    }
    _lastDay = _dayNumber;
  }

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) {
    final track = _state?.tracks[exerciseId];
    final info = c.book.find(exerciseId);
    if (track == null || info == null) {
      return null;
    }
    // 1RM « système » de L7 (poids de corps entier) ramené à la convention
    // de kalis_core (fraction du poids du corps).
    final offset = info.fraction > 0 ? bodyWeightKg * (1 - info.fraction) : 0.0;
    final capacity = track.x - offset;
    final operational = track.x * l7.pctOf(n, track.k) - offset;
    return SimEstimate(
      capacity: capacity,
      relSd: track.sd / track.x,
      operational: operational,
    );
  }
}
