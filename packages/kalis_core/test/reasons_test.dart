import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('codes uniques, bien formés, sans texte', () {
    final codes = <String>{for (final s in reasonRegistry) s.code};
    expect(codes.length, reasonRegistry.length);
    final pattern = RegExp(r'^(plan|adapt|quest)\.[a-z][a-z0-9_]*$');
    final param = RegExp(r'^[a-z][A-Za-z0-9]*$');
    for (final spec in reasonRegistry) {
      expect(pattern.hasMatch(spec.code), isTrue, reason: spec.code);
      for (final name in spec.params.keys) {
        expect(param.hasMatch(name), isTrue, reason: '${spec.code}.$name');
      }
    }
    for (final engine in <String>['plan.', 'adapt.', 'quest.']) {
      expect(
        codes.where((c) => c.startsWith(engine)).length,
        greaterThanOrEqualTo(10),
        reason: engine,
      );
    }
  });

  test('recherche dans le registre', () {
    expect(reasonSpecOf(ReasonCodes.planMuscleVolume)!.params.keys, <String>[
      'muscle',
      'weeklySets',
      'targetLow',
      'targetHigh',
    ]);
    expect(reasonSpecOf('plan.inconnu'), isNull);
    expect(ReasonCodes.adaptPainPersistent, 'adapt.pain_persistent');
  });

  test('une raison valide passe', () {
    const ok = Reason(
      code: ReasonCodes.planMuscleVolume,
      params: <String, Object?>{
        'muscle': 'grand dorsal',
        'weeklySets': 8.5,
        'targetLow': 10,
        'targetHigh': 16.0,
      },
    );
    expect(ok.validate(), isEmpty);
    expect(
      const Reason(
        code: ReasonCodes.planLockKept,
        params: <String, Object?>{},
      ).validate(),
      isEmpty,
    );
  });

  test('code inconnu, paramètre manquant, en trop ou mal typé', () {
    expect(
      codesOf(
        const Reason(
          code: 'plan.nouveau',
          params: <String, Object?>{},
        ).validate(),
      ),
      <String>['unknown_reason_code'],
    );
    expect(
      codesOf(
        const Reason(
          code: ReasonCodes.adaptLoadUp,
          params: <String, Object?>{},
        ).validate(),
      ),
      <String>['missing_param'],
    );
    expect(
      codesOf(
        const Reason(
          code: ReasonCodes.adaptLoadUp,
          params: <String, Object?>{'deltaKg': 2.5, 'pourquoi': 'parce que'},
        ).validate(),
      ),
      <String>['unknown_param'],
    );
    expect(
      codesOf(
        const Reason(
          code: ReasonCodes.adaptRepsUp,
          params: <String, Object?>{'delta': 1.5},
        ).validate(),
      ),
      <String>['param_type'],
    );
    expect(
      codesOf(
        const Reason(
          code: ReasonCodes.questXpEffort,
          params: <String, Object?>{'sets': 12, 'capped': 'oui'},
        ).validate(),
      ),
      <String>['param_type'],
    );
    expect(
      codesOf(
        const Reason(
          code: ReasonCodes.adaptLoadUp,
          params: <String, Object?>{'deltaKg': double.nan},
        ).validate(),
      ),
      contains('param_type'),
    );
  });
}
