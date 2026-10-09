// Briques : courbe des niveaux, standards de rang, outils numériques.
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart' show CapacityMode, ExerciseBook;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/src/numeric.dart' as numeric;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();

  group('outils numériques', () {
    test('exponentielle et logarithme portables à 1e-10 près', () {
      for (final x in <double>[-30, -3.2, -1, -0.01, 0, 0.5, 1, 4.7, 20]) {
        expect(numeric.exp(x), closeTo(math.exp(x), math.exp(x) * 1e-10));
      }
      for (final x in <double>[1e-6, 0.03, 0.5, 1, 2, 17.5, 1e6]) {
        expect(numeric.ln(x), closeTo(math.log(x), 1e-10));
      }
      expect(numeric.power(2, 0.5), closeTo(math.sqrt2, 1e-10));
      expect(numeric.ln(0), double.negativeInfinity);
    });

    test('loi normale', () {
      expect(numeric.normCdf(0), closeTo(0.5, 1e-7));
      expect(numeric.normCdf(numeric.z60), closeTo(0.6, 1e-6));
      expect(numeric.normCdf(numeric.z90), closeTo(0.9, 1e-6));
      expect(numeric.normCdf(-1.96), closeTo(0.025, 1e-4));
    });

    test('jours de la semaine et lundis', () {
      for (var i = 0; i < 400; i++) {
        final d = CivilDate(2026, 1, 1).addDays(i);
        expect(weekdayOf(d.dayNumber), d.weekday);
        final m = CivilDate.fromDayNumber(mondayOf(d.dayNumber));
        expect(m.weekday, 1);
        expect(d.dayNumber - m.dayNumber, inInclusiveRange(0, 6));
      }
    });

    test(
      'tirages : dans [0 ; 1[, stables, sensibles à la graine et à la clé',
      () {
        var sum = 0.0;
        for (var i = 0; i < 20000; i++) {
          final u = unitOf(3, 'k$i');
          expect(u, inInclusiveRange(0, 0.9999999999));
          sum += u;
        }
        expect(sum / 20000, closeTo(0.5, 0.01));
        expect(unitOf(3, 'a'), unitOf(3, 'a'));
        expect(unitOf(3, 'a'), isNot(unitOf(4, 'a')));
        expect(unitOf(3, 'a'), isNot(unitOf(3, 'b')));
      },
    );
  });

  group('courbe des niveaux', () {
    final curve = LevelCurve(QuestParams.standard);

    test('coût du niveau n : 5 × arrondi(K × n^0,875 / 5), croissant', () {
      expect(curve.costs, hasLength(100));
      for (var n = 1; n <= 100; n++) {
        final exact = QuestParams.standard.levelScale * math.pow(n, 0.875);
        expect(curve.costs[n - 1] % 5, 0);
        expect((curve.costs[n - 1] - exact).abs(), lessThanOrEqualTo(2.5001));
        if (n > 1) {
          expect(curve.costs[n - 1], greaterThanOrEqualTo(curve.costs[n - 2]));
        }
      }
    });

    test('niveau 1 à 0 XP, niveau suivant au seuil exact', () {
      final zero = curve.stateOf(0);
      expect(zero.level, 1);
      expect(zero.prestige, 0);
      expect(zero.xpIntoLevel, 0);
      expect(zero.xpForNextLevel, curve.costs[0]);
      for (var level = 2; level <= 100; level++) {
        final at = curve.xpAt(level);
        expect(curve.stateOf(at).level, level);
        expect(curve.stateOf(at).xpIntoLevel, 0);
        expect(curve.stateOf(at - 1).level, level - 1);
      }
    });

    test('prestige : le niveau repart à 1, l\'XP total est gardé', () {
      final span = curve.prestigeSpan;
      final last = curve.stateOf(span - 1);
      expect(last.level, 100);
      expect(last.prestige, 0);
      final rolled = curve.stateOf(span);
      expect(rolled.level, 1);
      expect(rolled.prestige, 1);
      expect(rolled.totalXp, span);
      expect(curve.stateOf(3 * span + 7).prestige, 3);
    });

    test('le rang global ne baisse jamais quand l\'XP augmente', () {
      var previous = 0;
      for (var xp = 0; xp < 2 * curve.prestigeSpan + 500; xp += 37) {
        final s = curve.stateOf(xp);
        final ordinal = LevelCurve.ordinal(s);
        expect(ordinal, greaterThanOrEqualTo(previous));
        expect(s.level, inInclusiveRange(1, 100));
        expect(s.xpIntoLevel, lessThan(s.xpForNextLevel));
        expect(s.validate(), isEmpty);
        previous = ordinal;
      }
    });
  });

  group('standards de rang', () {
    final book = ExerciseBook(catalog, null);

    test('16 mouvements ; tous les exercices cités sont au catalogue', () {
      expect(Standards.movements, hasLength(16));
      for (final m in Standards.movements) {
        expect(catalog.contains(m.id), isTrue, reason: m.id);
        for (final s in m.sources) {
          expect(catalog.contains(s), isTrue, reason: s);
        }
        for (final r in m.rungs) {
          for (final id in r.exerciseIds) {
            expect(catalog.contains(id), isTrue, reason: id);
            expect(m.sources, contains(id));
          }
        }
        if (m.measure == RankMeasure.hold) {
          expect(m.rungs, hasLength(6));
        } else {
          expect(m.male, hasLength(5));
          expect(m.female, hasLength(5));
        }
      }
    });

    test('la mesure de chaque source est celle que kalis_adapt lui donne', () {
      for (final m in Standards.movements) {
        for (final s in m.sources) {
          final mode = book.find(s)!.mode;
          switch (m.measure) {
            case RankMeasure.load:
              expect(mode, CapacityMode.loaded, reason: s);
            case RankMeasure.reps:
              expect(mode, CapacityMode.reps, reason: s);
            case RankMeasure.hold:
              expect(mode, CapacityMode.hold, reason: s);
            case RankMeasure.run:
              expect(mode, isNull, reason: s);
          }
        }
      }
    });

    test('au poids de référence, les seuils sont ceux de la table', () {
      for (final m in Standards.movements) {
        if (m.measure == RankMeasure.hold) {
          continue;
        }
        final fraction = book.find(m.id)!.fraction;
        final male = Standards.thresholds(m, Sex.male, 80, fraction);
        final female = Standards.thresholds(m, Sex.female, 60, fraction);
        for (var t = 0; t < 5; t++) {
          final wantMale = switch (m.measure) {
            RankMeasure.load => m.male[t] + fraction * 80,
            RankMeasure.run => 5000 / m.male[t],
            _ => m.male[t],
          };
          final wantFemale = switch (m.measure) {
            RankMeasure.load => m.female[t] + fraction * 60,
            RankMeasure.run => 5000 / m.female[t],
            _ => m.female[t],
          };
          expect(male[t], closeTo(wantMale, 1e-6), reason: '${m.id} H $t');
          expect(female[t], closeTo(wantFemale, 1e-6), reason: '${m.id} F $t');
        }
        // Élite : extrapolation d'un demi-pas logarithmique.
        expect(male[5], closeTo(male[4] * math.sqrt(male[4] / male[3]), 1e-6));
      }
    });

    test('seuils strictement croissants pour tout sexe et tout poids', () {
      for (final m in Standards.movements) {
        if (m.measure == RankMeasure.hold) {
          continue;
        }
        final fraction = book.find(m.id)!.fraction;
        for (final sex in Sex.values) {
          for (var bw = 30.0; bw <= 160; bw += 2.5) {
            final t = Standards.thresholds(m, sex, bw, fraction);
            expect(t, hasLength(6));
            for (var i = 1; i < 6; i++) {
              expect(
                t[i],
                greaterThan(t[i - 1]),
                reason: '${m.id} ${sex.code} $bw kg rang $i',
              );
            }
            expect(t.first, greaterThan(0));
          }
        }
      }
    });

    test('à rang égal, une personne plus lourde soulève plus mais pas en '
        'proportion ; elle fait moins de répétitions', () {
      final benchPress = Standards.movement('mu-developpe-couche-barre')!;
      final light = Standards.thresholds(benchPress, Sex.male, 60, 0);
      final heavy = Standards.thresholds(benchPress, Sex.male, 100, 0);
      for (var t = 2; t < 6; t++) {
        expect(heavy[t], greaterThan(light[t]));
        expect(heavy[t] / 100, lessThan(light[t] / 60));
      }
      final pullUps = Standards.movement('sw-traction-pronation')!;
      final few = Standards.thresholds(pullUps, Sex.male, 100, 0.97);
      final many = Standards.thresholds(pullUps, Sex.male, 60, 0.97);
      expect(few[4], lessThan(many[4]));
    });

    test('sexe non précisé : entre les deux tables', () {
      for (final m in Standards.movements) {
        if (m.measure == RankMeasure.hold) {
          continue;
        }
        final fraction = book.find(m.id)!.fraction;
        final a = Standards.thresholds(m, Sex.male, 70, fraction);
        final b = Standards.thresholds(m, Sex.female, 70, fraction);
        final u = Standards.thresholds(m, Sex.undisclosed, 70, fraction);
        for (var t = 0; t < 6; t++) {
          final low = math.min(a[t], b[t]);
          final high = math.max(a[t], b[t]);
          expect(u[t], inInclusiveRange(low - 1e-9, high * 1.06));
        }
      }
    });

    test('points de rang : croissants, entiers aux seuils, inverse', () {
      final m = Standards.movement('mu-developpe-couche-barre')!;
      final t = Standards.thresholds(m, Sex.male, 80, 0);
      expect(Standards.pointsOf(t, 0), 0);
      expect(Standards.pointsOf(t, 28), closeTo(0.5, 1e-9));
      for (var i = 0; i < 6; i++) {
        expect(Standards.pointsOf(t, t[i]), closeTo(i + 1, 1e-9));
        expect(
          Standards.tierOf(Standards.pointsOf(t, t[i] * 1.0001)).index,
          i + 1,
        );
      }
      var previous = -1.0;
      for (var kg = 1.0; kg < 300; kg += 0.5) {
        final p = Standards.pointsOf(t, kg);
        expect(p, greaterThanOrEqualTo(previous));
        expect(p, inInclusiveRange(0, 7));
        previous = p;
      }
      for (final points in <double>[1, 1.5, 2.25, 3.9, 5.5, 6]) {
        expect(
          Standards.pointsOf(t, Standards.valueAt(t, points) * 1.0000001),
          closeTo(points, 1e-3),
        );
      }
    });

    test('figures : échelle de progressions', () {
      final lever = Standards.movement('cs-front-lever')!;
      double points(Map<String, double> held) =>
          Standards.holdPoints(lever, (id) => held[id] ?? 0, 2);
      expect(points(<String, double>{}), 0);
      expect(
        points(<String, double>{'cs-front-lever-tuck': 5}),
        closeTo(0.5, 1e-9),
      );
      expect(
        points(<String, double>{'cs-front-lever-tuck': 10}),
        closeTo(1, 1e-9),
      );
      expect(
        Standards.tierOf(
          points(<String, double>{'cs-front-lever-tuck-avance': 12}),
        ),
        MovementRankTier.silver,
      );
      // Une progression plus dure tenue 2 s vaut les échelons plus bas.
      expect(
        Standards.tierOf(
          points(<String, double>{'cs-front-lever-straddle': 2}),
        ),
        MovementRankTier.silver,
      );
      expect(
        Standards.tierOf(points(<String, double>{'cs-front-lever': 3})),
        MovementRankTier.platinum,
      );
      expect(
        Standards.tierOf(points(<String, double>{'cs-front-lever': 25})),
        MovementRankTier.elite,
      );
    });

    test('héritage : même chaîne du catalogue, sinon aucun rang', () {
      expect(
        Standards.carrierOf(catalog, 'mu-back-squat-barre-basse')!.id,
        'mu-back-squat-barre-haute',
      );
      expect(
        Standards.carrierOf(catalog, 'sl-traction-lestee-prise-neutre')!.id,
        'sl-traction-lestee',
      );
      expect(Standards.carrierOf(catalog, 'sw-pompe-diamant')!.id, 'sw-pompe');
      expect(Standards.carrierOf(catalog, 'mu-front-squat'), isNull);
      expect(Standards.carrierOf(catalog, 'inconnu'), isNull);
    });
  });

  group('taille de la flamme', () {
    test('croît avec la série, de 0 à 10', () {
      const weeks = <int>[1, 2, 3, 4, 6, 8, 12, 16, 26, 52];
      expect(flameSizeOf(0, weeks), 0);
      expect(flameSizeOf(1, weeks), 1);
      expect(flameSizeOf(5, weeks), 4);
      expect(flameSizeOf(52, weeks), 10);
      expect(flameSizeOf(500, weeks), 10);
    });
  });
}
