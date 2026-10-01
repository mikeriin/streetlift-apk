// Briques du moteur : hachage, proximité, identifiants d'emplacement,
// nature des semaines, flammes, charges de départ, mise à jour du profil.
import 'dart:io';
import 'dart:math' as math;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();

  group('hachage et suite seedée', () {
    test('FNV-1a 32 bits : vecteurs de référence', () {
      // Vecteurs publiés avec l'algorithme (Fowler, Noll, Vo).
      expect(fnv1a32(''), 0x811C9DC5);
      expect(fnv1a32('a'), 0xE40C292C);
      expect(fnv1a32('foobar'), 0xBF9CF968);
    });

    test('xorshift32 : même graine, même suite ; bornes tenues', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      for (var i = 0; i < 1000; i++) {
        final x = a.nextU32();
        expect(x, b.nextU32());
        expect(x, inInclusiveRange(1, 0xFFFFFFFF));
      }
      final c = SeededRandom(0);
      for (var i = 0; i < 1000; i++) {
        expect(c.nextInt(7), inInclusiveRange(0, 6));
        final d = c.nextDouble();
        expect(d >= 0 && d < 1, isTrue);
      }
      a.reset(42);
      b.reset(42);
      expect(a.nextU32(), b.nextU32());
    });
  });

  group('proximité', () {
    test('symétrique, bornée, 1 pour un exercice et lui-même', () {
      final sample = <CatalogExercise>[
        for (var i = 0; i < catalog.exercises.length; i += 23)
          catalog.exercises[i],
      ];
      for (final a in sample) {
        expect(planSimilarity(a, a), closeTo(1, 1e-12));
        for (final b in sample) {
          final s = planSimilarity(a, b);
          expect(s, inInclusiveRange(0, 1));
          expect(s, closeTo(planSimilarity(b, a), 1e-12));
        }
      }
    });

    test(
      'une variante directe est plus proche qu\'un exercice sans rapport',
      () {
        final pushUp = catalog.exercise('sw-pompe');
        final knee = catalog.exercise('sw-pompe-genoux');
        final squat = catalog.exercise('mu-air-squat');
        expect(
          planSimilarity(pushUp, knee),
          greaterThan(planSimilarity(pushUp, squat)),
        );
      },
    );
  });

  group('identifiants d\'emplacement', () {
    test('aller-retour jour ↔ identifiant', () {
      for (var d = 0; d < 7; d++) {
        for (var n = 1; n < 40; n += 7) {
          expect(dayOfSlotId(slotIdFor(d, n)), d);
        }
      }
      expect(dayOfSlotId('ailleurs'), isNull);
      expect(dayOfSlotId('d1'), isNull);
    });
  });

  group('nature des semaines', () {
    test('introduction d\'abord ; test, décharge ou montée en dernier', () {
      for (var weeks = 4; weeks <= 6; weeks++) {
        for (var level = 0; level <= 3; level++) {
          for (final goal in <bool>[false, true]) {
            for (final cautious in <bool>[false, true]) {
              final kinds = weekKindsFor(
                weeks: weeks,
                level: level,
                hasPerformanceGoal: goal,
                cautious: cautious,
              );
              expect(kinds.length, weeks);
              expect(kinds.first, WeekKind.intro);
              for (var w = 1; w < weeks - 1; w++) {
                expect(kinds[w], WeekKind.build);
              }
              final last = goal && !cautious
                  ? WeekKind.test
                  : (level >= 1 ? WeekKind.deload : WeekKind.build);
              expect(kinds.last, last);
            }
          }
        }
      }
    });

    test('durée par défaut : 4 à 6 semaines selon le niveau', () {
      expect(defaultBlockWeeks(0), 4);
      expect(defaultBlockWeeks(1), 5);
      expect(defaultBlockWeeks(2), 6);
      expect(defaultBlockWeeks(3), 6);
    });
  });

  group('passe 2 du propriétaire (1RM connus)', () {
    final fixture = profileOf('proprietaire_streetlifting_avance');
    final engine = KalisPlan();
    final request = requestFor(fixture.profile);
    final pass1 = engine.createPass1(catalog, request);
    final pass2 = engine.createPass2(
      catalog,
      Pass2Request(request: request, pass1: pass1),
    );

    test('charges de départ : jamais au-dessus de 90 % de la charge '
        'd\'Epley, multiples du pas déclaré', () {
      final levels = <String, MovementLevel>{
        for (final l in fixture.profile.movementLevels) l.exerciseId: l,
      };
      final steps = <LoadType, double>{
        for (final i in fixture.profile.loadIncrements) i.loadType: i.stepKg,
      };
      final least = <LoadType, double>{
        for (final i in fixture.profile.loadIncrements)
          if (i.minKg != null) i.loadType: i.minKg!,
      };
      var checked = 0;
      for (final week in pass2.weeks) {
        for (final day in week.days) {
          for (final item in day.items) {
            final load = item.startLoadKg;
            final level = levels[item.exerciseId];
            if (load == null ||
                level == null ||
                level.measure != LevelMeasure.oneRmKg ||
                item.kind == SetKind.test) {
              continue;
            }
            final e = catalog.exercise(item.exerciseId);
            // Une charge ramenée au minimum du matériel (barre à vide, lest
            // nul) n'est plus une charge calculée.
            if (load <= (least[e.loadType] ?? 0) + 1e-9) {
              continue;
            }
            final bw = fixture.profile.bodyWeightKg!;
            final fraction = e.bodyweightFraction?.value ?? 0;
            final total = level.low! + fraction * bw;
            // Epley (1985) : 1RM = charge × (1 + répétitions / 30). La
            // charge de départ ne dépasse jamais 90 % de la charge qui
            // mènerait à l'échec en haut de la plage.
            final bound = 0.9 * total / (1 + item.repsHigh! / 30);
            expect(
              load + fraction * bw,
              lessThanOrEqualTo(bound + 1e-6),
              reason: '${item.exerciseId} s${week.weekIndex}',
            );
            final step = steps[e.loadType];
            if (step != null) {
              final ratio = load / step;
              expect(
                (ratio - ratio.roundToDouble()).abs(),
                lessThan(1e-6),
                reason: '${item.exerciseId} : $load kg, pas $step',
              );
            }
            checked++;
          }
        }
      }
      expect(checked, greaterThan(4));
    });

    test('flammes visées : de 1 à 10, plus hautes en fin de montée qu\'en '
        'introduction', () {
      final intro = <String, int>{};
      final lastBuild = <String, int>{};
      for (final week in pass2.weeks) {
        for (final day in week.days) {
          for (final item in day.items) {
            final f = item.targetFlames;
            if (f == null) {
              continue;
            }
            expect(Flames.isValid(f), isTrue);
            if (week.kind == WeekKind.intro) {
              intro[item.slotId] = f;
            } else if (week.kind == WeekKind.build) {
              lastBuild[item.slotId] = f;
            }
          }
        }
      }
      expect(intro, isNotEmpty);
      for (final e in intro.entries) {
        expect(lastBuild[e.key], greaterThanOrEqualTo(e.value));
      }
    });

    test('semaine de test : une épreuve par objectif, montée jusqu\'à une '
        'série lourde', () {
      final test = pass2.weeks.last;
      expect(test.kind, WeekKind.test);
      final tests = <ExercisePrescription>[
        for (final d in test.days)
          for (final i in d.items)
            if (i.kind == SetKind.test) i,
      ];
      final goals = fixture.profile.goals
          .where((g) => g.kind == GoalKind.performance)
          .length;
      expect(tests.length, inInclusiveRange(1, goals));
      for (final t in tests) {
        final targets = t.setTargets;
        if (targets == null) {
          continue;
        }
        expect(targets.length, t.sets);
        for (var i = 1; i < targets.length; i++) {
          final a = targets[i - 1].loadKg;
          final b = targets[i].loadKg;
          if (a != null && b != null) {
            expect(b, greaterThanOrEqualTo(a));
          }
        }
      }
    });

    test('exercices sans 1RM connu : « à calibrer », jamais de charge '
        'inventée', () {
      final known = <String>{
        for (final l in fixture.profile.movementLevels)
          if (l.measure == LevelMeasure.oneRmKg && l.known) l.exerciseId,
      };
      var calibrations = 0;
      for (final item in pass2.weeks.first.days.expand((d) => d.items)) {
        if (!known.contains(item.exerciseId)) {
          expect(item.startLoadKg, isNull, reason: item.exerciseId);
          if (item.kind == SetKind.calibration) {
            calibrations++;
            expect(item.toCalibrate, isTrue);
          }
        }
      }
      expect(calibrations, greaterThan(0));
    });
  });

  group('mise à jour du profil', () {
    final base = profileOf('materiel_complet_gouts_marques').profile;

    test('« je n\'aime pas » retire des goûts et ajoute aux rejets', () {
      final liked = base.likedExerciseIds.first;
      final updated = applyProfileDelta(
        base,
        ProfileDelta(
          knownExerciseIds: const <String>[],
          unknownExerciseIds: const <String>[],
          likedExerciseIds: const <String>[],
          dislikedExerciseIds: <String>[liked],
        ),
      );
      expect(updated.likedExerciseIds, isNot(contains(liked)));
      expect(updated.dislikedExerciseIds, contains(liked));
      expect(updated.validate(), isEmpty);
    });

    test('« je sais faire » puis « je ne sais pas faire » se remplacent', () {
      const id = 'sw-traction-pronation';
      final knows = applyProfileDelta(
        base,
        const ProfileDelta(
          knownExerciseIds: <String>[id],
          unknownExerciseIds: <String>[],
          likedExerciseIds: <String>[],
          dislikedExerciseIds: <String>[],
        ),
      );
      expect(knows.knownExerciseIds, contains(id));
      final cannot = applyProfileDelta(
        knows,
        const ProfileDelta(
          knownExerciseIds: <String>[],
          unknownExerciseIds: <String>[id],
          likedExerciseIds: <String>[],
          dislikedExerciseIds: <String>[],
        ),
      );
      expect(cannot.knownExerciseIds ?? const <String>[], isNot(contains(id)));
      expect(cannot.cannotDoExerciseIds, contains(id));
    });
  });

  group('paramètres', () {
    test('poids de la note : sommes strictement positives, codes stables', () {
      const w = ScoreWeights();
      expect(w.safetySum, greaterThan(0));
      expect(w.qualitySum, greaterThan(0));
      expect(ScoreWeights.codes.toSet().length, ScoreWeights.codes.length);
      expect(ScoreWeights.codes.length, 14);
    });

    test('bandes de volume : croissantes avec le niveau, bas ≤ haut', () {
      var previousLow = 0;
      for (final (low, high) in volumeBandsByLevel) {
        expect(low, lessThanOrEqualTo(high));
        expect(low, greaterThanOrEqualTo(previousLow));
        previousLow = low;
      }
    });

    test('la version est celle du pubspec et du CHANGELOG', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('version: $kalisPlanVersion'));
      expect(
        File('CHANGELOG.md').readAsStringSync(),
        contains('## $kalisPlanVersion'),
      );
      expect(KalisPlan().engineVersion, kalisPlanVersion);
    });
  });

  group('fonctions élémentaires portables', () {
    test('stableExp suit exp à 1e-12 près sur [-40 ; 0]', () {
      for (var i = 0; i <= 4000; i++) {
        final x = -i / 100;
        final want = math.exp(x);
        expect((stableExp(x) - want).abs(), lessThanOrEqualTo(1e-12 * want));
      }
      expect(stableExp(0), 1);
      expect(stableExp(3), 1);
      expect(stableExp(-800), 0);
    });

    test('stableLn suit log à 1e-13 près de 1e-6 à 1e6', () {
      for (var i = -600; i <= 600; i++) {
        final x = math.pow(10, i / 100).toDouble();
        expect(
          (stableLn(x) - math.log(x)).abs(),
          lessThanOrEqualTo(1e-13 * 15),
        );
      }
      expect(stableLn(1), 0);
    });
  });

  group('charges de départ des 40 profils types', () {
    test('jamais au-dessus de 90 % de la charge d\'Epley en haut de plage, '
        'multiples du pas déclaré', () {
      var checked = 0;
      for (final fixture in loadProfiles()) {
        final profile = fixture.profile;
        final request = requestFor(profile);
        final engine = KalisPlan();
        final pass1 = engine.createPass1(catalog, request);
        final pass2 = engine.createPass2(
          catalog,
          Pass2Request(request: request, pass1: pass1),
        );
        final levels = <String, MovementLevel>{
          for (final l in profile.movementLevels) l.exerciseId: l,
        };
        final steps = <LoadType, double>{
          for (final i in profile.loadIncrements) i.loadType: i.stepKg,
        };
        final least = <LoadType, double>{
          for (final i in profile.loadIncrements)
            if (i.minKg != null) i.loadType: i.minKg!,
        };
        final bw = profile.bodyWeightKg ?? 0;
        for (final week in pass2.weeks) {
          for (final day in week.days) {
            for (final item in day.items) {
              final load = item.startLoadKg;
              if (load == null) {
                continue;
              }
              final e = catalog.exercise(item.exerciseId);
              expect(load, greaterThanOrEqualTo(0), reason: fixture.key);
              final step = steps[e.loadType];
              if (step != null && load > (least[e.loadType] ?? 0) + 1e-9) {
                final ratio = load / step;
                expect(
                  (ratio - ratio.roundToDouble()).abs(),
                  lessThan(1e-6),
                  reason:
                      '${fixture.key} ${item.exerciseId} : $load kg, '
                      'pas $step',
                );
              }
              final level = levels[item.exerciseId];
              final low = level?.low;
              final high = item.repsHigh;
              if (level == null ||
                  low == null ||
                  high == null ||
                  level.measure != LevelMeasure.oneRmKg ||
                  item.kind == SetKind.test ||
                  load <= (least[e.loadType] ?? 0) + 1e-9) {
                continue;
              }
              final fraction = e.bodyweightFraction?.value ?? 0;
              final bound = 0.9 * (low + fraction * bw) / (1 + high / 30);
              expect(
                load + fraction * bw,
                lessThanOrEqualTo(bound + 1e-6),
                reason: '${fixture.key} ${item.exerciseId} s${week.weekIndex}',
              );
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(20));
    });
  });
}
