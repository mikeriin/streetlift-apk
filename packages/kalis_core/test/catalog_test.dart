import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

const String sourceSha256 =
    '1a44c2b059389143f682b5e6b050d6382f795b446bb8ce3dae915d10c59b01f6';

void main() {
  final catalog = loadCatalog();
  final raw =
      jsonDecode(utf8.decode(catalogJsonBytes())) as Map<String, Object?>;
  final rawExercises = (raw['exercices']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final vocab = raw['vocabulaires']! as Map<String, Object?>;
  List<String> words(String key) =>
      (vocab[key]! as List<Object?>).cast<String>();

  group('source', () {
    test('la copie de la base v1.1.0 a la somme de contrôle attendue', () {
      final digest = sha256.convert(File(sourcePath).readAsBytesSync());
      expect(digest.toString(), sourceSha256);
      expect(catalog.sourceSha256, sourceSha256);
      expect(catalog.sourceVersion, '1.1.0');
      expect(catalog.sourceDate, '2026-09-28');
    });

    test('la base est conservée telle quelle dans le catalogue', () {
      final source =
          jsonDecode(File(sourcePath).readAsStringSync())
              as Map<String, Object?>;
      final sourceExercises = (source['exercices']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(rawExercises.length, sourceExercises.length);
      for (var i = 0; i < sourceExercises.length; i++) {
        final compiled = Map<String, Object?>.of(rawExercises[i])
          ..remove('calc');
        expect(
          jsonDeepEquals(compiled, sourceExercises[i]),
          isTrue,
          reason: '${sourceExercises[i]['id']}',
        );
      }
    });
  });

  group('schéma de la base', () {
    test('1 039 exercices, 8 disciplines aux effectifs attendus', () {
      expect(catalog.length, 1039);
      expect(catalog.schemaVersion, 1);
      expect(catalog.rulesVersion, isNotEmpty);
      const expected = <CatalogDiscipline, int>{
        CatalogDiscipline.musculation: 448,
        CatalogDiscipline.streetWorkout: 109,
        CatalogDiscipline.streetlifting: 61,
        CatalogDiscipline.calisthenicsStatic: 100,
        CatalogDiscipline.calisthenicsDynamic: 110,
        CatalogDiscipline.crossfit: 54,
        CatalogDiscipline.cardio: 47,
        CatalogDiscipline.mobility: 110,
      };
      for (final entry in expected.entries) {
        expect(
          catalog.byDiscipline(entry.key).length,
          entry.value,
          reason: entry.key.code,
        );
      }
    });

    test('vocabulaires fermés : 56 muscles, 68 matériels, 56 catégories', () {
      expect(catalog.muscles.length, 56);
      expect(catalog.equipmentVocabulary.length, 68);
      expect(catalog.categories.length, 56);
      expect(words('niveaux'), <String>[
        for (final l in ExerciseLevel.values) l.code,
      ]);
      expect(words('disciplines'), <String>[
        for (final d in CatalogDiscipline.values) d.code,
      ]);
      final muscles = catalog.muscles.toSet();
      final equipment = catalog.equipmentVocabulary.toSet();
      final categories = catalog.categories.toSet();
      for (final e in catalog.exercises) {
        expect(categories, contains(e.category), reason: e.id);
        expect(e.equipment, isNotEmpty, reason: e.id);
        expect(equipment.containsAll(e.equipment), isTrue, reason: e.id);
        expect(e.equipment.toSet().length, e.equipment.length, reason: e.id);
        for (final list in <List<String>>[
          e.primaryMuscles,
          e.secondaryMuscles,
          e.stabilizerMuscles,
          e.stretchedMuscles,
        ]) {
          expect(muscles.containsAll(list), isTrue, reason: e.id);
        }
      }
    });

    test('identifiants uniques et bien formés', () {
      final ids = <String>{for (final e in catalog.exercises) e.id};
      expect(ids.length, catalog.length);
      final pattern = RegExp(r'^[a-z]{2}-[a-z0-9-]+$');
      for (final id in ids) {
        expect(pattern.hasMatch(id), isTrue, reason: id);
      }
    });

    test('un muscle figure dans une seule colonne par exercice', () {
      for (final e in catalog.exercises) {
        final all = <String>[
          ...e.primaryMuscles,
          ...e.secondaryMuscles,
          ...e.stabilizerMuscles,
        ];
        expect(all.toSet().length, all.length, reason: e.id);
      }
    });

    test(
      'variante_de : existe, sans cycle, racine et profondeur cohérentes',
      () {
        for (final e in catalog.exercises) {
          final ancestors = catalog.ancestorsOf(e.id);
          expect(ancestors.length, e.depth, reason: e.id);
          expect(ancestors.map((a) => a.id).toSet().length, ancestors.length);
          expect(ancestors.any((a) => a.id == e.id), isFalse, reason: e.id);
          final root = ancestors.isEmpty ? e : ancestors.last;
          expect(root.variantOf, isNull);
          expect(catalog.rootOf(e.id).id, root.id);
          expect(e.rootId, root.id);
          expect(catalog.parentOf(e.id)?.id, e.variantOf);
          expect(catalog.familyOf(e.id), contains(e));
          if (e.variantOf != null) {
            expect(catalog.childrenOf(e.variantOf!), contains(e));
          }
        }
        final children = <String>{
          for (final e in catalog.exercises)
            for (final c in catalog.childrenOf(e.id)) c.id,
        };
        expect(
          children.length,
          catalog.exercises.where((e) => e.variantOf != null).length,
        );
      },
    );
  });

  group('champs calculés', () {
    test('les vocabulaires calculés sont ceux des enums du contrat', () {
      Set<String> codes(Iterable<String> values) => values.toSet();
      expect(
        codes(words('schemas')),
        codes(MovementPattern.values.map((v) => v.code)),
      );
      expect(
        codes(words('familles')),
        codes(MovementFamily.values.map((v) => v.code)),
      );
      expect(words('plans'), <String>[
        for (final v in MovementPlane.values) v.code,
      ]);
      expect(words('articularites'), <String>[
        for (final v in Articularity.values) v.code,
      ]);
      expect(words('regimes'), <String>[
        for (final v in ContractionMode.values) v.code,
      ]);
      expect(words('lieux'), <String>[for (final v in Place.values) v.code]);
      expect(words('articulations'), <String>[
        for (final v in Joint.values) v.code,
      ]);
      expect(words('contraintes'), <String>[
        for (final v in JointStress.values) v.code,
      ]);
      expect(words('types_charge'), <String>[
        for (final v in LoadType.values) v.code,
      ]);
      expect(words('unites'), <String>[
        for (final v in MeasureUnit.values) v.code,
      ]);
      expect(words('lateralites'), <String>[
        for (final v in Laterality.values) v.code,
      ]);
      expect(words('sources_fraction'), <String>[
        for (final v in FractionSource.values) v.code,
      ]);
    });

    test('domaines : difficulté, fatigue, lieux, contraintes, fraction', () {
      for (final e in catalog.exercises) {
        expect(e.difficulty, inInclusiveRange(1, 10), reason: e.id);
        expect(e.systemicFatigue, inInclusiveRange(1, 5), reason: e.id);
        expect(e.localFatigue, inInclusiveRange(1, 5), reason: e.id);
        expect(e.places, isNotEmpty, reason: e.id);
        expect(e.places.toSet().length, e.places.length, reason: e.id);
        expect(e.jointStress.keys.toSet(), Joint.values.toSet(), reason: e.id);
        final fraction = e.bodyweightFraction;
        if (fraction != null) {
          expect(
            e.loadType,
            anyOf(LoadType.bodyweight, LoadType.addedWeight),
            reason: e.id,
          );
          expect(fraction.value, inInclusiveRange(0.3, 1.0), reason: e.id);
          expect(
            fraction.reference == null,
            fraction.source == FractionSource.estimated,
            reason: e.id,
          );
        }
      }
    });

    test('la difficulté ne décroît jamais quand le niveau monte', () {
      final lowest = <ExerciseLevel, int>{};
      final highest = <ExerciseLevel, int>{};
      for (final e in catalog.exercises) {
        lowest[e.level] = min(lowest[e.level] ?? 10, e.difficulty);
        highest[e.level] = max(highest[e.level] ?? 1, e.difficulty);
      }
      for (var i = 1; i < ExerciseLevel.values.length; i++) {
        final below = ExerciseLevel.values[i - 1];
        final above = ExerciseLevel.values[i];
        expect(
          highest[below]!,
          lessThanOrEqualTo(lowest[above]!),
          reason: '${below.code} / ${above.code}',
        );
      }
      expect(lowest[ExerciseLevel.beginner], 1);
      expect(highest[ExerciseLevel.elite], 10);
    });

    test('tenues et étirements se mesurent en secondes', () {
      for (final e in catalog.exercises) {
        if (e.contractionMode == ContractionMode.isometric ||
            e.contractionMode == ContractionMode.passive) {
          expect(e.unit, MeasureUnit.seconds, reason: e.id);
          expect(e.articularity, Articularity.notApplicable, reason: e.id);
        }
      }
    });

    test('prérequis : existants, au plus 2, plus faciles, sans cycle', () {
      for (final e in catalog.exercises) {
        expect(e.prerequisites.length, lessThanOrEqualTo(2), reason: e.id);
        expect(e.prerequisites.toSet().length, e.prerequisites.length);
        for (final id in e.prerequisites) {
          final p = catalog.exercise(id);
          expect(p.id, isNot(e.id));
          if (e.loadType == LoadType.addedWeight) {
            expect(p.loadType, LoadType.bodyweight, reason: e.id);
            expect(p.assisted, isFalse, reason: e.id);
            expect(p.family, e.family, reason: e.id);
            expect(p.difficulty, lessThanOrEqualTo(e.difficulty), reason: e.id);
          } else {
            expect(p.rootId, e.rootId, reason: e.id);
            expect(p.difficulty, lessThan(e.difficulty), reason: e.id);
          }
        }
        final seen = <String>{};
        final stack = <String>[e.id];
        while (stack.isNotEmpty) {
          for (final p in catalog.exercise(stack.removeLast()).prerequisites) {
            expect(p, isNot(e.id), reason: 'cycle de prérequis : ${e.id}');
            if (seen.add(p)) {
              stack.add(p);
            }
          }
        }
      }
    });

    test(
      'vecteur musculaire : principal 1, secondaire 0,5, stabilisateur 0,2',
      () {
        expect(Catalog.primaryWeight, 1.0);
        expect(Catalog.secondaryWeight, 0.5);
        expect(Catalog.stabilizerWeight, 0.2);
        for (final e in catalog.exercises) {
          final expected = <String, double>{
            for (final m in e.stabilizerMuscles) m: 0.2,
            for (final m in e.secondaryMuscles) m: 0.5,
            for (final m in e.primaryMuscles) m: 1.0,
          };
          expect(e.muscleIndices.length, expected.length, reason: e.id);
          for (var i = 0; i < e.muscleIndices.length; i++) {
            if (i > 0) {
              expect(e.muscleIndices[i], greaterThan(e.muscleIndices[i - 1]));
            }
            final muscle = catalog.muscles[e.muscleIndices[i]];
            expect(e.muscleWeights[i], expected[muscle], reason: e.id);
            expect(catalog.weightOf(e, muscle), expected[muscle]);
          }
        }
      },
    );

    test('cas types relus', () {
      final pushUp = catalog.exercise('sw-pompe');
      expect(pushUp.pattern, MovementPattern.pousseeHorizontale);
      expect(pushUp.family, MovementFamily.poussee);
      expect(pushUp.loadType, LoadType.bodyweight);
      expect(pushUp.unit, MeasureUnit.repetitions);
      expect(pushUp.bodyweightFraction!.value, 0.72);
      expect(pushUp.bodyweightFraction!.source, FractionSource.published);
      expect(pushUp.places, Place.values);

      final weightedPullUp = catalog.exercise('sl-traction-lestee');
      expect(weightedPullUp.pattern, MovementPattern.tirageVertical);
      expect(weightedPullUp.loadType, LoadType.addedWeight);
      expect(weightedPullUp.prerequisites, <String>['sw-traction-pronation']);
      expect(weightedPullUp.bodyweightFraction!.value, 0.97);

      final planche = catalog.exercise('cs-planche');
      expect(planche.contractionMode, ContractionMode.isometric);
      expect(planche.unit, MeasureUnit.seconds);
      expect(planche.difficulty, 10);
      expect(planche.stressOn(Joint.wrist), JointStress.high);
      expect(planche.bodyweightFraction, isNull);

      final deadlift = catalog.exercise('mu-souleve-de-terre-conventionnel');
      expect(deadlift.pattern, MovementPattern.charniereHanche);
      expect(deadlift.systemicFatigue, 5);
      expect(deadlift.stressOn(Joint.lumbar), JointStress.high);
      expect(deadlift.places, <Place>[Place.gym]);
      expect(deadlift.loadType, LoadType.barbell);

      final run = catalog.exercise('ca-footing-endurance-fondamentale');
      expect(run.contractionMode, ContractionMode.cyclic);
      expect(run.unit, MeasureUnit.seconds);
      expect(run.loadType, LoadType.none);
      expect(run.places, <Place>[Place.outdoor]);

      final assisted = catalog.exercise('sw-traction-assistee-elastique');
      expect(assisted.assisted, isTrue);
      expect(assisted.loadType, LoadType.bodyweight);
    });
  });

  group('index', () {
    test('par identifiant', () {
      expect(catalog.contains('sw-pompe'), isTrue);
      expect(catalog.find('inconnu'), isNull);
      expect(() => catalog.exercise('inconnu'), throwsArgumentError);
    });

    test('par nom et alias, sans casse ni accents', () {
      expect(
        catalog.byLabel('Pompe classique').map((e) => e.id),
        contains('sw-pompe'),
      );
      expect(
        catalog.byLabel('  pompe   CLASSIQUE ').map((e) => e.id),
        contains('sw-pompe'),
      );
      final deadHang = catalog.exercise('sw-dead-hang');
      for (final alias in deadHang.aliases) {
        expect(catalog.byLabel(alias), contains(deadHang), reason: alias);
      }
      expect(
        catalog.byLabel('élévation latérale haltères'),
        catalog.byLabel('Elevation laterale halteres'),
      );
      expect(catalog.byLabel('exercice qui n’existe pas'), isEmpty);
      for (final e in catalog.exercises) {
        expect(catalog.byLabel(e.name), contains(e), reason: e.id);
      }
      expect(
        Catalog.normalizeLabel('  Élévation   LATÉRALE à l’haltère '),
        "elevation laterale a l'haltere",
      );
    });

    test('par discipline, catégorie, schéma, famille : partitions', () {
      int total<T>(Iterable<T> keys, List<CatalogExercise> Function(T) index) =>
          keys.fold(0, (sum, k) => sum + index(k).length);
      expect(total(CatalogDiscipline.values, catalog.byDiscipline), 1039);
      expect(total(catalog.categories, catalog.byCategory), 1039);
      expect(total(MovementPattern.values, catalog.byPattern), 1039);
      expect(total(MovementFamily.values, catalog.byFamily), 1039);
      for (final pattern in MovementPattern.values) {
        expect(catalog.byPattern(pattern), isNotEmpty, reason: pattern.code);
        for (final e in catalog.byPattern(pattern)) {
          expect(e.pattern, pattern);
        }
      }
    });

    test('par muscle et par matériel', () {
      const lats = 'grand dorsal';
      final all = catalog.byMuscle(lats);
      final secondary = catalog.byMuscle(lats, minWeight: 0.5);
      final primary = catalog.byMuscle(lats, minWeight: 1);
      expect(primary, isNotEmpty);
      expect(primary.length, lessThan(secondary.length));
      expect(secondary.length, lessThan(all.length));
      for (final e in primary) {
        expect(e.primaryMuscles, contains(lats));
      }
      expect(primary.map((e) => e.id), contains('sw-traction-pronation'));
      expect(catalog.byMuscle('muscle inconnu'), isEmpty);
      for (final item in catalog.equipmentVocabulary) {
        for (final e in catalog.byEquipment(item)) {
          expect(e.equipment, contains(item));
        }
      }
      expect(
        catalog.byEquipment('barre fixe').map((e) => e.id),
        contains('sw-traction-pronation'),
      );
    });

    test('faisabilité selon le matériel disponible', () {
      final pullUp = catalog.exercise('sw-traction-pronation');
      expect(pullUp.feasibleWith(<String>{}), isFalse);
      expect(pullUp.feasibleWith(<String>{'barre fixe'}), isTrue);
      expect(catalog.exercise('sw-pompe').feasibleWith(<String>{}), isTrue);
      expect(
        catalog.exercise('sw-pompe-murale').feasibleWith(<String>{}),
        isTrue,
      );
    });

    test('faisabilité selon le lieu (0.4.2)', () {
      final wall = catalog.exercise('cs-handstand-dos-au-mur');
      expect(wall.equipment, contains('mur'));
      // Un mur ne bloque jamais feasibleWith (lecture de 0.4.1).
      expect(wall.feasibleWith(<String>{}), isTrue);
      expect(wall.feasibleAt(<String>{}, place: Place.home), isTrue);
      expect(wall.feasibleAt(<String>{}, place: Place.gym), isTrue);
      expect(wall.feasibleAt(<String>{}, place: Place.outdoor), isFalse);
      expect(wall.feasibleAt(<String>{'mur'}, place: Place.outdoor), isTrue);
      expect(
        wall.feasibleAt(<String>{}, places: <Place>{Place.outdoor}),
        isFalse,
      );
      expect(
        wall.feasibleAt(
          <String>{},
          places: <Place>{Place.outdoor, Place.home},
        ),
        isTrue,
      );
      expect(wall.feasibleAt(<String>{}), isTrue);

      final incline = catalog.exercise('sw-pompe-inclinee');
      expect(incline.feasibleAt(<String>{}, place: Place.home), isTrue);
      expect(incline.feasibleAt(<String>{}, place: Place.outdoor), isFalse);
      expect(
        incline.feasibleAt(<String>{'barre basse'}, place: Place.outdoor),
        isTrue,
      );
      expect(
        incline.feasibleAt(<String>{'barres parallèles'}, place: Place.gym),
        isTrue,
      );

      final pike = catalog.exercise('cs-handstand-pike-pieds-sureleves');
      expect(pike.feasibleAt(<String>{}, place: Place.outdoor), isFalse);
      expect(
        pike.feasibleAt(<String>{'banc plat'}, place: Place.outdoor),
        isTrue,
      );

      final pullUp = catalog.exercise('sw-traction-pronation');
      expect(pullUp.feasibleAt(<String>{}, place: Place.home), isFalse);
      expect(
        pullUp.feasibleAt(<String>{'barre fixe'}, place: Place.outdoor),
        isTrue,
      );
    });

    test('tables de lieu et de remplacement cohérentes avec le catalogue', () {
      final vocabulary = catalog.equipmentVocabulary.toSet();
      expect(vocabulary, containsAll(placeBoundEquipment.keys));
      for (final entry in equipmentAlternatives.entries) {
        expect(catalog.exercise(entry.key).id, entry.key);
        for (final alternative in entry.value) {
          expect(vocabulary, containsAll(alternative));
        }
      }
      for (final id in homeFurnitureExercises) {
        expect(catalog.exercise(id).id, id);
      }
      // feasibleAt n'est jamais plus strict que feasibleWith hors du mur.
      for (final e in catalog.exercises) {
        if (e.equipment.contains('mur')) {
          continue;
        }
        for (final place in Place.values) {
          if (e.feasibleWith(<String>{})) {
            expect(e.feasibleAt(<String>{}, place: place), isTrue, reason: e.id);
          }
        }
      }
    });

    test('contrôles de références', () {
      expect(catalog.checkExerciseIds(<String>['sw-pompe']), isEmpty);
      expect(
        codesOf(catalog.checkExerciseIds(<String>['sw-pompe', 'xx-rien'])),
        <String>['unknown_exercise'],
      );
      expect(
        codesOf(catalog.checkEquipment(<String>['barre fixe', 'trampoline'])),
        <String>['unknown_equipment'],
      );
    });
  });

  group('proximité', () {
    test('symétrique, bornée, 1 pour soi-même (10 000 paires seedées)', () {
      final r = Random(20261001);
      final n = catalog.length;
      for (var i = 0; i < 10000; i++) {
        final a = catalog.exercises[r.nextInt(n)].id;
        final b = catalog.exercises[r.nextInt(n)].id;
        final ab = catalog.similarity(a, b);
        expect(ab, inInclusiveRange(0.0, 1.0));
        expect(ab, catalog.similarity(b, a));
        expect(catalog.similarity(a, a), 1.0);
        if (a != b) {
          expect(ab, lessThanOrEqualTo(1.0));
        }
      }
    });

    test('une variante est plus proche qu\'un exercice sans rapport', () {
      final close = catalog.similarity('sw-pompe', 'sw-pompe-diamant');
      final same = catalog.similarity('sw-pompe', 'mu-developpe-couche-barre');
      final far = catalog.similarity('sw-pompe', 'mu-leg-extension');
      expect(close, greaterThan(same));
      expect(same, greaterThan(far));
      expect(far, lessThan(0.25));
      expect(close, greaterThan(0.8));
    });

    test('poids de la proximité : somme 1', () {
      expect(
        Catalog.similarityMuscleWeight +
            Catalog.similarityPatternWeight +
            Catalog.similarityChainWeight +
            Catalog.similarityDifficultyWeight,
        closeTo(1.0, 1e-12),
      );
    });

    test('mostSimilar : trié, déterministe, filtrable, sans soi-même', () {
      final first = catalog.mostSimilar('sw-traction-pronation', limit: 15);
      final again = catalog.mostSimilar('sw-traction-pronation', limit: 15);
      expect(first.map((e) => e.id), again.map((e) => e.id));
      expect(first.length, 15);
      expect(first.map((e) => e.id), isNot(contains('sw-traction-pronation')));
      for (var i = 1; i < first.length; i++) {
        expect(
          catalog.similarity('sw-traction-pronation', first[i - 1].id),
          greaterThanOrEqualTo(
            catalog.similarity('sw-traction-pronation', first[i].id),
          ),
        );
      }
      final gymFree = catalog.mostSimilar(
        'sw-traction-pronation',
        limit: 5,
        where: (e) => e.loadType == LoadType.cable,
      );
      expect(gymFree, hasLength(5));
      expect(gymFree.every((e) => e.loadType == LoadType.cable), isTrue);
      expect(gymFree.first.pattern, MovementPattern.tirageVertical);
    });
  });

  group('chargement', () {
    Map<String, Object?> copy() =>
        jsonDecode(utf8.decode(catalogJsonBytes())) as Map<String, Object?>;
    List<Map<String, Object?>> exercisesOf(Map<String, Object?> json) =>
        (json['exercices']! as List<Object?>).cast<Map<String, Object?>>();

    test('refuse un schéma plus récent', () {
      final json = copy()..['schema'] = Catalog.supportedSchemaVersion + 1;
      expect(() => Catalog.fromJson(json), throwsFormatException);
    });

    test('refuse un identifiant en double', () {
      final json = copy();
      exercisesOf(json)[1]['id'] = exercisesOf(json)[0]['id'];
      expect(() => Catalog.fromJson(json), throwsFormatException);
    });

    test('refuse un code inconnu', () {
      final json = copy();
      (exercisesOf(json)[0]['calc']! as Map<String, Object?>)['schema'] =
          'lancer';
      expect(() => Catalog.fromJson(json), throwsFormatException);
    });

    test('refuse une variante_de inconnue ou cyclique', () {
      final unknown = copy();
      exercisesOf(unknown)[0]['variante_de'] = 'xx-inconnu';
      expect(() => Catalog.fromJson(unknown), throwsFormatException);
      final cyclic = copy();
      final list = exercisesOf(cyclic);
      final a = list.firstWhere((e) => e['variante_de'] == null);
      final b = list.firstWhere((e) => e['variante_de'] == a['id']);
      a['variante_de'] = b['id'];
      expect(() => Catalog.fromJson(cyclic), throwsFormatException);
    });

    test('deux chargements donnent le même catalogue', () {
      final other = loadCatalog();
      expect(other.length, catalog.length);
      for (var i = 0; i < catalog.length; i++) {
        final a = catalog.exercises[i];
        final b = other.exercises[i];
        expect(a.id, b.id);
        expect(a.difficulty, b.difficulty);
        expect(a.muscleWeights, b.muscleWeights);
      }
    });

    test('temps de chargement ≤ 150 ms (décompression comprise)', () {
      final bytes = File(catalogPath).readAsBytesSync();
      var best = 1 << 30;
      for (var i = 0; i < 9; i++) {
        final watch = Stopwatch()..start();
        final loaded = Catalog.fromJsonBytes(gzip.decode(bytes));
        watch.stop();
        expect(loaded.length, 1039);
        best = min(best, watch.elapsedMicroseconds);
      }
      // ignore: avoid_print
      print('chargement du catalogue : meilleur de 9 = ${best / 1000} ms');
      expect(best, lessThanOrEqualTo(150000));
    });
  });
}
