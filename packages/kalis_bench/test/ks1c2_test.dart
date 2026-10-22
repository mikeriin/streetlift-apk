// Critère du lot KS1c2 (« aucun jour sans son principal ») : règle sur des
// jours écrits à la main, profil du constat de KS1A, grille des profils
// incomplets.
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

PlanSlot _slot(String id, SlotRole role) => PlanSlot(
  slotId: 'd0s$id',
  exerciseId: id,
  role: role,
  locked: false,
  reasons: const <Reason>[],
);

PlanDay _day(List<DayPattern> patterns, DayQuality q, List<PlanSlot> slots) =>
    PlanDay(
      dayIndex: 0,
      weekday: 5,
      minutesBudget: 120,
      focus: 'push',
      slots: slots,
      type: DayType(patterns: patterns, quality: q),
    );

void main() {
  final catalog = loadCatalog();

  group('règle sur des jours écrits à la main', () {
    test('jour poussée sans poussée (constat de KS1A) : deux écarts', () {
      final d = _day(
        const <DayPattern>[DayPattern.push],
        DayQuality.endurance,
        <PlanSlot>[
          _slot('sw-active-hang', SlotRole.warmup),
          _slot('sw-releve-jambes-tendues-suspendu', SlotRole.core),
          _slot('mo-cat-cow', SlotRole.mobility),
        ],
      );
      expect(principalGapsOfDay(catalog, d), <String>[
        'principal',
        'schéma push',
      ]);
    });

    test('jour poussée avec dips principal : tenu', () {
      final d = _day(
        const <DayPattern>[DayPattern.push],
        DayQuality.endurance,
        <PlanSlot>[
          _slot('sw-active-hang', SlotRole.warmup),
          _slot('sw-dips-barres-paralleles', SlotRole.main),
        ],
      );
      expect(principalGapsOfDay(catalog, d), isEmpty);
    });

    test('porteur secondaire seul : schéma porté, sans principal', () {
      final d = _day(
        const <DayPattern>[DayPattern.push],
        DayQuality.force,
        <PlanSlot>[_slot('sl-pompe-lestee-disque-dos', SlotRole.secondary)],
      );
      final gaps = principalGapsOfDay(catalog, d);
      expect(gaps, <String>['principal']);
      expect(gaps.where(principalSchemaGap), isEmpty);
    });

    test('corps entier : deux schémas sur trois portés', () {
      final one = _day(
        const <DayPattern>[DayPattern.full],
        DayQuality.force,
        <PlanSlot>[_slot('sl-traction-lestee', SlotRole.main)],
      );
      expect(principalGapsOfDay(catalog, one), <String>['corps entier']);
      final two = _day(
        const <DayPattern>[DayPattern.full],
        DayQuality.force,
        <PlanSlot>[
          _slot('sl-traction-lestee', SlotRole.main),
          _slot('sl-squat-competition', SlotRole.main),
        ],
      );
      expect(principalGapsOfDay(catalog, two), isEmpty);
    });

    test('course, récupération, conditionnement, sans type : sans attente', () {
      for (final q in const <DayQuality>[
        DayQuality.run,
        DayQuality.recovery,
        DayQuality.conditioning,
      ]) {
        expect(
          principalGapsOfDay(
            catalog,
            _day(const <DayPattern>[DayPattern.push], q, const <PlanSlot>[]),
          ),
          isEmpty,
        );
      }
      const untyped = PlanDay(
        dayIndex: 0,
        weekday: 1,
        minutesBudget: 60,
        focus: 'push',
        slots: <PlanSlot>[],
      );
      expect(principalGapsOfDay(catalog, untyped), isEmpty);
    });
  });

  group('grille des profils incomplets', () {
    final base = readJsonObject('profiles_ks1c2/ks1a_street_5050.json');

    test('72 variantes par base, clés uniques, profils lisibles', () {
      final grid = principalGrid(<Map<String, Object?>>[base]);
      expect(grid, hasLength(72));
      expect(grid.map((p) => p.key).toSet(), hasLength(72));
      final none = grid.firstWhere(
        (p) => p.key.endsWith('~none~notAnswered~advanced'),
      );
      expect(none.records, isEmpty);
      final noPush = grid.firstWhere(
        (p) => p.key.endsWith('~noPush~standard~elite'),
      );
      expect(
        noPush.records.where((r) => r.exerciseId.contains('dips')),
        isEmpty,
      );
    });

    test('profil du constat de KS1A et ses variantes : chaque jour typé '
        'porte un principal de son schéma (premier bloc)', () {
      final engine = KalisPlan();
      final m = PrincipalMeasure('grille');
      for (final p in principalGrid(<Map<String, Object?>>[base])) {
        final program = generateProgram(catalog, engine, p, horizonWeeks: 1);
        m.add(catalog, p.key, <Pass1Plan>[
          for (final b in program.blocks) b.pass1,
        ]);
      }
      expect(m.profiles, 72);
      expect(m.schemaGaps, isEmpty);
      expect(m.typedNoMain, isEmpty);
    });
  });
}
