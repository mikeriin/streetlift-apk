// Structure de la semaine (0.4.4, lot KS1) : type du jour, gabarit retenu,
// six codes de raison ; évolution additive (un JSON de 0.4.3 se relit et se
// réécrit à l'identique).
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'samples.dart';

void main() {
  group('0.4.4 : structure de la semaine', () {
    test('un Pass1Plan de 0.4.3 se relit et se réécrit à l\'identique', () {
      final json = basePass1().toJson();
      expect(json.containsKey('split'), isFalse);
      final text = jsonEncode(json);
      final back = Pass1Plan.fromJson(jsonDecode(text) as Map<String, Object?>);
      expect(jsonEncode(back.toJson()), text);
      expect(back.split, isNull);
      expect(back.days.single.type, isNull);
      expect(back.validate(), isEmpty);
    });

    test('type du jour et gabarit : aller-retour JSON, validation', () {
      final base = basePass1();
      final plan = base.copyWith(
        days: <PlanDay>[
          base.days.single.copyWith(
            type: const DayType(
              patterns: <DayPattern>[DayPattern.pull],
              quality: DayQuality.force,
              stress: DayStress.heavy,
            ),
          ),
        ],
        split: SplitChoice(
          templateId: 'ppl6_q',
          reasons: <Reason>[
            Reason(
              code: ReasonCodes.planSplitChosen,
              params: <String, Object?>{'templateId': 'ppl6_q', 'sessions': 6},
            ),
          ],
        ),
      );
      expect(plan.validate(), isEmpty);
      final text = jsonEncode(plan.toJson());
      final back = Pass1Plan.fromJson(jsonDecode(text) as Map<String, Object?>);
      expect(jsonEncode(back.toJson()), text);
      expect(back.split!.templateId, 'ppl6_q');
      expect(back.days.single.type!.patterns, <DayPattern>[DayPattern.pull]);
      expect(back.days.single.type!.quality, DayQuality.force);
      expect(back.days.single.type!.stress, DayStress.heavy);
      final day = (plan.toJson()['days']! as List<Object?>).single;
      expect((day! as Map<String, Object?>)['type'], <String, Object?>{
        'patterns': <Object?>['pull'],
        'quality': 'force',
        'stress': 'heavy',
      });
    });

    test('un type de jour sans schéma est invalide', () {
      const empty = DayType(
        patterns: <DayPattern>[],
        quality: DayQuality.endurance,
      );
      expect(empty.validate(), isNotEmpty);
    });

    test('énumérations : codes stables', () {
      expect(
        <String>[for (final p in DayPattern.values) p.code],
        <String>['pull', 'push', 'legs', 'full', 'skill', 'run', 'recovery'],
      );
      expect(
        <String>[for (final q in DayQuality.values) q.code],
        <String>[
          'force',
          'volume',
          'endurance',
          'power',
          'skill',
          'conditioning',
          'run',
          'recovery',
        ],
      );
    });

    test('six codes de raison et leurs paramètres', () {
      final specs = <String, Map<String, ReasonParamType>>{
        'plan.split_chosen': <String, ReasonParamType>{
          'templateId': ReasonParamType.text,
          'sessions': ReasonParamType.integer,
        },
        'plan.day_type': <String, ReasonParamType>{
          'patterns': ReasonParamType.text,
          'quality': ReasonParamType.text,
        },
        'plan.goal_uncovered': <String, ReasonParamType>{
          'goalId': ReasonParamType.text,
        },
        'plan.milestone': <String, ReasonParamType>{
          'date': ReasonParamType.text,
          'goals': ReasonParamType.integer,
        },
        'plan.replaced_disliked': <String, ReasonParamType>{
          'exerciseId': ReasonParamType.exerciseId,
        },
        'plan.replaced_cannot_do': <String, ReasonParamType>{
          'exerciseId': ReasonParamType.exerciseId,
        },
      };
      for (final entry in specs.entries) {
        expect(reasonSpecOf(entry.key)?.params, entry.value, reason: entry.key);
      }
      const r = Reason(
        code: ReasonCodes.planReplacedDisliked,
        params: <String, Object?>{'exerciseId': 'sw-pompe'},
      );
      expect(r.validate(), isEmpty);
    });
  });
}
