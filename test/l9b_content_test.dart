// L9b (KT-079, KT-082) — base d'exercices : migration sans perte,
// non-régression des données de STATS, correspondance du programme,
// recherche et filtres, fiches et mentions à 320 px et 200 %. G3 : la base
// v1.1 (kalis_core, 1 039 exercices) remplace le pack 2.0.0 ; les noms v1 et
// les intitulés du programme sont résolus par la correspondance relue
// (assets/catalog/correspondance.json) ; les groupes musculaires des noms
// enregistrés restent ceux de l'ancienne base (STATS identiques). Fixture :
// l'ancienne base embarquée jusqu'en 3.1.0 (test/fixtures/l9b/
// exercises_db_v1.json.gz, 505 entrées réelles) et un historique complet des
// 40 semaines (l2_fixtures ; séances personnelles retirées en G2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/pose_painter.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

List<Map<String, dynamic>> _v1() => [
  for (final e
      in jsonDecode(
            utf8.decode(
              gzip.decode(
                File(
                  'test/fixtures/l9b/exercises_db_v1.json.gz',
                ).readAsBytesSync(),
              ),
            ),
          )
          as List)
    Map<String, dynamic>.from(e as Map),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final v1 = _v1();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  /// G3 : anciens exercices sans équivalent dans la base v1.1 (relus,
  /// docs/G3_CORRESPONDANCE.md) : pas des exercices (bilan, méthode) ou
  /// gestes absents de la base.
  const sansEquivalent = {
    'Around the world (suspendu)',
    'Bilan',
    'Contraste français',
    'Kettlebell clean & press',
    'Rice bucket (seau de riz)',
  };

  group('base v1.1 et migration', () {
    test('les 505 exercices v1 gardent nom, groupes et matériel', () {
      expect(v1.length, 505);
      final byName = {for (final e in store.dbExercises) e['n']: e};
      for (final e in v1) {
        final now = byName[e['n']];
        expect(now, isNotNull, reason: e['n'] as String);
        expect(now!['g'], e['g'], reason: e['n'] as String);
        expect(now['eq'], e['eq'], reason: e['n'] as String);
        expect(now['id'], isA<String>());
      }
      expect(store.dbExercises.length, 625);
      expect(
        store.dbExercises.map((e) => e['n']).toSet().length,
        store.dbExercises.length,
      );
    });

    test('chaque nom v1 et chaque intitulé du programme a son id v1.1', () {
      for (final e in v1) {
        final name = e['n'] as String;
        final id = store.exerciseIdFor(name);
        if (sansEquivalent.contains(name)) {
          expect(id, isNull, reason: name);
          continue;
        }
        expect(id, isNotNull, reason: name);
        expect(store.content.byId.containsKey(id), isTrue);
      }
      var lines = 0;
      for (final w in store.program.weeks) {
        for (final d in w.days) {
          for (final ex in d.exercises) {
            lines++;
            final id = store.exerciseIdFor(ex.name);
            // Le bilan de phase n'est pas un exercice.
            if (ex.name.startsWith('BILAN')) {
              expect(id, isNull, reason: ex.name);
              continue;
            }
            expect(id, isNotNull, reason: ex.name);
            expect(store.content.byId.containsKey(id), isTrue, reason: ex.name);
          }
        }
      }
      expect(lines, 1812);
      // Un exercice personnel n'est rattaché à rien.
      expect(store.exerciseIdFor('Mon mouvement maison 42'), isNull);
    });

    test('doublons v1 : le nom mène à l\'exercice de son canonique', () {
      final pack =
          jsonDecode(
                utf8.decode(
                  gzip.decode(
                    File('assets/content/index.json.gz').readAsBytesSync(),
                  ),
                ),
              )
              as Map<String, dynamic>;
      final byId = {
        for (final e in pack['exercices'] as List)
          (e as Map)['id'] as String: e,
      };
      var n = 0;
      for (final e in byId.values) {
        final canon = e['doublon_de'] as String?;
        if (canon == null || e['v1'] != true) continue;
        n++;
        expect(
          store.exerciseIdFor(e['n'] as String),
          store.exerciseIdFor(byId[canon]!['n'] as String),
          reason: e['n'] as String,
        );
      }
      expect(n, greaterThan(0));
    });

    test('STATS : groupes musculaires inchangés pour tous les noms v1', () {
      final oldIndex = {
        for (final e in v1)
          (e['n'] as String).toLowerCase(): [
            for (final g in (e['g'] as String).split(','))
              if (AppStore.muscleGroups.contains(g.trim())) g.trim(),
          ],
      };
      final legacyNames = {
        for (final e in v1) (e['n'] as String).toLowerCase(),
      };
      final added = {
        for (final e in store.content.entries)
          if (!legacyNames.contains(e.nom.toLowerCase())) e.nom.toLowerCase(),
      };
      final names = {
        for (final e in v1) e['n'] as String,
        for (final w in store.program.weeks)
          for (final d in w.days)
            for (final ex in d.exercises) ex.name,
      };
      for (final name in names) {
        final key = store.splitName(name).$1.toLowerCase();
        final before = oldIndex[key];
        if (before != null && before.isNotEmpty) {
          expect(store.groupsFor(name), before, reason: name);
        } else {
          // Aucun exercice v1.1 ne capte un nom qui passait par les
          // mots-clés.
          expect(added.contains(key), isFalse, reason: name);
        }
      }
    });

    test('historique complet : aucune perte au rechargement', () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppStore()..storeClock = () => DateTime(2026, 9, 27, 10);
      await app.init();
      final data = filledBackup(app);
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      await app.flush();
      final before = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final weekly = app.weeklyMuscles(DateTime(2026, 8, 20));
      app.dispose();

      final next = AppStore()..storeClock = () => DateTime(2026, 9, 27, 10);
      await next.init();
      final after = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      for (final k in const ['logs', 'userExercises']) {
        expect(after[k], before[k], reason: k);
      }
      expect(next.weeklyMuscles(DateTime(2026, 8, 20)), weekly);
      // Chaque exercice saisi reste rattaché à la base (ou reste personnel).
      var resolved = 0;
      for (final log in next.logs.values) {
        for (final name in log.exerciseNames.values) {
          if (next.exerciseIdFor(name) != null) resolved++;
        }
      }
      expect(resolved, greaterThan(1000));
      next.dispose();
    });
  });

  group('recherche et filtres (KT-082, G3)', () {
    ContentIndex index() => store.content;

    test('par muscle, alias et nom de la base v1.1', () {
      final dorsal = searchExercises(
        index(),
        'grand dorsal',
        const ExerciseFilters(),
      );
      expect(
        dorsal
            .where((e) => e.ex.primaryMuscles.contains('grand dorsal'))
            .length,
        greaterThan(20),
      );
      final roue = searchExercises(
        index(),
        'roue abdominale',
        const ExerciseFilters(),
      );
      expect(roue.map((e) => e.id), contains('mu-roue-abdominale-genoux'));
      // Par alias (« Bench press ») et par nom.
      expect(
        searchExercises(
          index(),
          'bench press',
          const ExerciseFilters(),
        ).map((e) => e.id),
        contains('mu-developpe-couche-barre'),
      );
      expect(
        searchExercises(
          index(),
          'Muscle-up barre strict',
          const ExerciseFilters(),
        ).first.id,
        'cd-muscle-up-barre-strict',
      );
    });

    test('filtres : discipline, type, niveau, lieu, matériel, difficulté', () {
      final all = searchExercises(index(), '', const ExerciseFilters());
      expect(all.length, 1039);
      for (final d in const [
        'Musculation',
        'Street workout',
        'Streetlifting',
        'Calisthénie statique',
        'Calisthénie dynamique',
        'CrossFit / WOD',
        'Cardio',
        'Mobilité',
      ]) {
        final list = searchExercises(
          index(),
          '',
          ExerciseFilters(disciplines: {d}),
        );
        expect(list, isNotEmpty, reason: d);
        expect(list.every((e) => e.discipline == d), isTrue, reason: d);
      }
      final dehors = searchExercises(
        index(),
        '',
        const ExerciseFilters(lieux: {'exterieur'}),
      );
      expect(dehors, isNotEmpty);
      expect(dehors.every((e) => e.lieux.contains('exterieur')), isTrue);
      final tirage = searchExercises(
        index(),
        '',
        const ExerciseFilters(familles: {'tirage'}, materiels: {'barre fixe'}),
      );
      expect(tirage, isNotEmpty);
      expect(
        tirage.every(
          (e) => e.famille == 'tirage' && e.materiel.contains('barre fixe'),
        ),
        isTrue,
      );
      final elite = searchExercises(
        index(),
        '',
        const ExerciseFilters(niveaux: {'Élite'}),
      );
      expect(elite, isNotEmpty);
      expect(elite.every((e) => e.niveau == 'Élite'), isTrue);
      final avance = searchExercises(
        index(),
        '',
        const ExerciseFilters(difficultes: {3}),
      );
      expect(avance.every((e) => e.difficulte >= 7), isTrue);
      expect(
        searchExercises(
          index(),
          'traction',
          const ExerciseFilters(difficultes: {1}),
        ).every((e) => e.difficulte <= 3),
        isTrue,
      );
    });

    test('M4c : union dans une catégorie, intersection entre catégories', () {
      final street = searchExercises(
        index(),
        '',
        const ExerciseFilters(disciplines: {'Street workout'}),
      );
      final lifting = searchExercises(
        index(),
        '',
        const ExerciseFilters(disciplines: {'Streetlifting'}),
      );
      final both = searchExercises(
        index(),
        '',
        const ExerciseFilters(disciplines: {'Street workout', 'Streetlifting'}),
      );
      expect(street, isNotEmpty);
      expect(lifting, isNotEmpty);
      expect(both.length, street.length + lifting.length);
      final easyOrHard = searchExercises(
        index(),
        '',
        const ExerciseFilters(
          disciplines: {'Street workout', 'Streetlifting'},
          difficultes: {1, 3},
        ),
      );
      expect(easyOrHard, isNotEmpty);
      expect(easyOrHard.length, lessThan(both.length));
      expect(
        easyOrHard.every(
          (e) =>
              {'Street workout', 'Streetlifting'}.contains(e.discipline) &&
              (e.difficulte <= 3 || e.difficulte >= 7),
        ),
        isTrue,
      );
      // Correspondance avec le menu « Filtres » (clés préfixées).
      final menu = ExerciseFilters.fromSelection(
        const FilterSelection({
          'discipline': {'disc:Streetlifting'},
          'famille': {'fam:tirage'},
          'niveau': {'lvl:Avancé'},
          'lieu': {'lieu:salle'},
          'materiel': {'mat:barre fixe', 'mat:anneaux'},
          'difficulte': {'dif:2'},
        }),
      );
      expect(menu.disciplines, {'Streetlifting'});
      expect(menu.familles, {'tirage'});
      expect(menu.niveaux, {'Avancé'});
      expect(menu.lieux, {'salle'});
      expect(menu.materiels, {'barre fixe', 'anneaux'});
      expect(menu.difficultes, {2});
      final cats = ExerciseFilters.categories(index());
      expect(cats.map((c) => c.label), [
        'Discipline',
        'Type de mouvement',
        'Niveau',
        'Lieu',
        'Matériel',
        'Difficulté',
      ]);
      expect(cats.first.options.length, 8);
      final keys = [
        for (final c in cats)
          for (final o in c.options) o.key,
      ];
      expect(keys.toSet().length, keys.length, reason: 'clés uniques');
    });

    test('document de recherche : alias, discipline, muscles, lieux', () {
      final doc = store.content.byId['mu-roue-abdominale-genoux']!.searchDoc;
      expect(doc.all, contains('roue abdominale'));
      expect(doc.all, contains('musculation'));
      expect(doc.all, contains('droit de l'));
      expect(doc.all, contains('salle'));
    });
  });

  group('atlas et carte de STATS', () {
    test('51 muscles superficiels dessinés, rattachés aux 11 groupes', () {
      final drawn = {
        for (final r in atlasRegions)
          if (r.kind == 'muscle') r.muscle!,
      };
      expect(drawn.length, 51);
      for (final m in drawn) {
        expect(AppStore.muscleGroups, contains(atlasMuscles[m]!.groupe));
      }
      expect(atlasMuscles.length, 81);
      expect(muscleMasks['front'], contains('pectoraux'));
      expect(muscleMasks['back'], contains('ischios'));
    });

    test('rampe d\'intensité inchangée sur l\'atlas', () {
      final fills = heatAtlasFills({'dos': 1.0, 'biceps': .5});
      final dorsal = fills['grand_dorsal']!.single;
      expect(dorsal.color, heat(1));
      expect(fills['biceps_chef_long']!.single.color, heat(.5));
      expect(fills.containsKey('grand_pectoral_sterno_costal'), isFalse);
      final roles = exerciseAtlasFills(
        accent: SL.accent,
        focus: SL.text,
        primaires: ['grand_dorsal'],
        secondaires: ['grand_dorsal', 'biceps_chef_long'],
        stabilisateurs: ['droit_abdomen'],
      );
      expect(roles['grand_dorsal']!.single.opacity, 1);
      expect(roles['biceps_chef_long']!.single.opacity, .42);
      expect(roles['droit_abdomen']!.single.dashed, isTrue);
    });
  });

  group('fiches à 320 px et 200 %', () {
    // MediaQuery posé par `builder` : les fiches ouvertes par navigation
    // reçoivent aussi la taille de texte et la réduction des animations.
    Widget host(Widget page, {required bool dark, required double scale}) =>
        MaterialApp(
          theme: buildTheme(dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: page,
        );

    for (final size in const [Size(320, 720), Size(390, 844)]) {
      for (final scale in const [1.3, 2.0]) {
        for (final dark in const [true, false]) {
          testWidgets(
            'fiche ${size.width.toInt()} px, texte ${(scale * 100).toInt()} %, ${dark ? 'sombre' : 'clair'}',
            (tester) async {
              phone(tester, size: size);
              await tester.pumpWidget(
                host(
                  const ExerciseSheetScreen(id: 'cd-muscle-up-barre-strict'),
                  dark: dark,
                  scale: scale,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), null);
              // M8 (5.9.0) : sans animation, rien en tête de fiche ; carte
              // 2D des groupes dans la section Muscles.
              expect(find.byType(PoseDemo), findsNothing);
              expect(find.byType(ExerciseMannequin), findsNothing);
              expect(find.text('MUSCLE-UP BARRE STRICT'), findsOneWidget);
              // Défilement réel : liste des muscles, puis variantes en bas
              // (G3 : gestes lents, pour ne pas dépasser l'en-tête d'un
              // geste lancé sur une fiche longue).
              // UI0 (refonte UI, C6) : titres de section sans capitales.
              await scrollSlowlyTo(tester, find.text('Muscles'));
              await scrollSlowlyTo(tester, find.byType(MuscleMap2D));
              expect(tester.takeException(), null);
              await scrollSlowlyTo(tester, find.text('Variantes'));
              expect(tester.takeException(), null);
            },
          );
        }
      }
    }

    testWidgets('démonstration indisponible : carte et consignes', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      // G3 : aucune démonstration d'exercice n'existe encore.
      final id = store.content.entries
          .firstWhere((e) => e.discipline == 'Mobilité')
          .id;
      await tester.pumpWidget(
        host(ExerciseSheetScreen(id: id), dark: true, scale: 2),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PoseDemo), findsNothing);
      // 5.5.3 : plus de mention « Démonstration indisponible ». M8 : rien en
      // tête sans animation.
      expect(find.textContaining('Démonstration indisponible'), findsNothing);
      expect(find.byType(ExerciseMannequin), findsNothing);
      await scrollSlowlyTo(tester, find.text('Muscles'));
      expect(tester.takeException(), null);
    });

    testWidgets('progression navigable vers une autre fiche', (tester) async {
      phone(tester);
      final e = store.content.byId['mu-roue-abdominale-genoux']!;
      expect(
        store.content.detail(e.id)!.variantes,
        contains('mu-roue-abdominale-debout'),
      );
      await tester.pumpWidget(
        host(
          const ExerciseSheetScreen(id: 'mu-roue-abdominale-genoux'),
          dark: true,
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      final next = store.content.byId['mu-roue-abdominale-debout']!.nom;
      await scrollToAction(tester, find.text(next));
      await tester.tap(find.text(next));
      await tester.pumpAndSettle();
      expect(find.text(next.toUpperCase()), findsOneWidget);
      expect(e.nom, isNotEmpty);
      expect(tester.takeException(), null);
    });

    testWidgets('bibliothèque : recherche et filtre à 320 px et 200 %', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      await tester.pumpWidget(
        host(const ExerciseLibraryScreen(), dark: false, scale: 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
      await tester.enterText(find.byType(TextField), 'ab wheel');
      await tester.pumpAndSettle();
      // En-tête et filtres occupent l'écran à 200 % : défilement réel
      // (« Ab wheel » est un alias de la roue abdominale).
      await scrollToAction(tester, find.text('Roue abdominale à genoux'));
      expect(tester.takeException(), null);
    });

    testWidgets('mentions : sources et licences lisibles à 320 px', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      await tester.pumpWidget(
        host(const MentionsScreen(), dark: true, scale: 2),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('SOURCES ET LICENCES'), findsWidgets);
      expect(tester.takeException(), null);
    });
  });
}

String normalize(String s) => s.toLowerCase().trim();
