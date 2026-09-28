// L9b (KT-079, KT-082) — base d'exercices v2 : migration v1 → v2 sans perte,
// non-régression des données de STATS, correspondance du programme,
// recherche et filtres sur les nouveaux champs, fiches et mentions à 320 px
// et 200 %. Fixture : l'ancienne base embarquée jusqu'en 3.1.0
// (test/fixtures/l9b/exercises_db_v1.json.gz, 505 entrées réelles) et un
// historique complet des 40 semaines + 60 séances personnelles (l2_fixtures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/muscle_body.dart';
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
    await ContentLibrary.load();
  });

  group('base v2 et migration', () {
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

    test('chaque nom v1 et chaque intitulé du programme a son id v2', () {
      for (final e in v1) {
        final id = store.exerciseIdFor(e['n'] as String);
        expect(id, isNotNull, reason: e['n'] as String);
        expect(store.content.byId.containsKey(id), isTrue);
      }
      var lines = 0;
      for (final w in store.program.weeks) {
        for (final d in w.days) {
          for (final ex in d.exercises) {
            lines++;
            final id = store.exerciseIdFor(ex.name);
            expect(id, isNotNull, reason: ex.name);
            expect(store.content.byId.containsKey(id), isTrue, reason: ex.name);
          }
        }
      }
      expect(lines, 1812);
      // Un exercice personnel n'est rattaché à rien.
      expect(store.exerciseIdFor('Mon mouvement maison 42'), isNull);
    });

    test('doublons v1 : le nom mène à l\'exercice canonique', () {
      final doublons = [
        for (final e in store.content.entries)
          if (e.doublonDe != null && e.v1) e,
      ];
      for (final d in doublons) {
        expect(store.exerciseIdFor(d.n), isNot(d.id), reason: d.n);
      }
    });

    test('STATS : groupes musculaires inchangés pour tous les noms v1', () {
      final oldIndex = {
        for (final e in v1)
          (e['n'] as String).toLowerCase(): [
            for (final g in (e['g'] as String).split(','))
              if (AppStore.muscleGroups.contains(g.trim())) g.trim(),
          ],
      };
      final added = {
        for (final e in store.content.entries)
          if (!e.v1) e.n.toLowerCase(),
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
          // Aucun ajout v2 ne capte un nom qui passait par les mots-clés.
          expect(added.contains(key), isFalse, reason: name);
        }
      }
    });

    test(
      'historique complet et séances perso : aucune perte au rechargement',
      () async {
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
        for (final k in const ['logs', 'custom', 'userExercises']) {
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
      },
    );
  });

  group('recherche et filtres (KT-082)', () {
    ContentIndex index() => store.content;

    test('par muscle, alias et nom v2', () {
      final dorsal = searchExercises(
        index(),
        'grand dorsal',
        const ExerciseFilters(),
      );
      expect(
        dorsal.where((e) => e.muscles.contains('grand_dorsal')).length,
        greaterThan(20),
      );
      final roue = searchExercises(
        index(),
        'roue abdominale',
        const ExerciseFilters(),
      );
      expect(roue.map((e) => e.id), contains('ab-wheel'));
      final renamed = store.content.entries.firstWhere(
        (e) =>
            e.v1 && e.doublonDe == null && normalize(e.nom) != normalize(e.n),
      );
      expect(
        searchExercises(
          index(),
          renamed.nom,
          const ExerciseFilters(),
        ).map((e) => e.id),
        contains(renamed.id),
      );
    });

    test('filtres : type, lieu, matériel, difficulté', () {
      final all = searchExercises(index(), '', const ExerciseFilters());
      expect(all.length, lessThan(625)); // doublons v1 non listés
      final parc = searchExercises(
        index(),
        '',
        const ExerciseFilters(lieu: 'parc_street_workout'),
      );
      expect(parc, isNotEmpty);
      expect(
        parc.every((e) => e.lieux.contains('parc_street_workout')),
        isTrue,
      );
      final tirage = searchExercises(
        index(),
        '',
        const ExerciseFilters(type: 'tirage_vertical', materiel: 'barre_fixe'),
      );
      expect(tirage, isNotEmpty);
      expect(
        tirage.every(
          (e) =>
              e.type == 'tirage_vertical' && e.materiel.contains('barre_fixe'),
        ),
        isTrue,
      );
      final avance = searchExercises(
        index(),
        '',
        const ExerciseFilters(niveau: 3),
      );
      expect(avance.every((e) => e.difficulte >= 7), isTrue);
      expect(
        searchExercises(
          index(),
          'traction',
          const ExerciseFilters(niveau: 1),
        ).every((e) => e.difficulte <= 3),
        isTrue,
      );
    });

    test('sélecteur de séance : recherche sur les champs v2', () {
      final e = store.dbExercises.firstWhere((x) => x['id'] == 'ab-wheel');
      final doc = exerciseSearchDoc(store.content, e);
      expect(doc.all, contains('roue abdominale'));
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
                  const ExerciseSheetScreen(id: 'muscle-up'),
                  dark: dark,
                  scale: scale,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), null);
              expect(find.byType(PoseDemo), findsOneWidget);
              expect(find.text('MUSCLE-UP'), findsOneWidget);
              // Défilement réel : atlas des muscles, puis sources en bas.
              await scrollToAction(tester, find.byType(ExerciseAtlas));
              await scrollToAction(tester, find.text('Sources consultées'));
              expect(tester.takeException(), null);
            },
          );
        }
      }
    }

    testWidgets('démonstration indisponible : atlas et consignes', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      final id = store.content.entries
          .firstWhere((e) => e.demo == 'indisponible')
          .id;
      await tester.pumpWidget(
        host(ExerciseSheetScreen(id: id), dark: true, scale: 2),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PoseDemo), findsNothing);
      expect(find.textContaining('Démonstration indisponible'), findsOneWidget);
      await scrollToAction(tester, find.byType(ExerciseAtlas));
      expect(tester.takeException(), null);
    });

    testWidgets('progression navigable vers une autre fiche', (tester) async {
      phone(tester);
      final e = store.content.byId['ab-wheel']!;
      await tester.pumpWidget(
        host(const ExerciseSheetScreen(id: 'ab-wheel'), dark: true, scale: 1),
      );
      await tester.pumpAndSettle();
      final next = store.content.byId['ab-wheel-debout']!.nom;
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
      // En-tête et filtres occupent l'écran à 200 % : défilement réel.
      await scrollToAction(tester, find.text('Ab wheel'));
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
