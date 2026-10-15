// BV11 (dev6.19.0, pipeline CP, DECISIONS_CP.md C12.1, C17.9) — base
// d'exercices v1.1, seule source d'exercices de l'application : le pack
// 2.0.0 est retiré (archivé dans tools/archives/pack_2.0.0/ pour les
// outils), sans perdre une ligne d'historique ni changer une séance faite.
//
// - Retrait : plus aucune lecture de `assets/content/` ; groupes musculaires
//   historiques (STATS) gardés par une copie figée du champ `g` du pack.
// - Migration depuis dev6.18.0 : journal proche de celui du propriétaire
//   (programme de 40 semaines commencé le 13/07/2026, S1 à S14 saisies) :
//   mêmes séances, séries, records et statistiques après rechargement ;
//   chaque nom du journal et chaque ligne du programme relié à son id v1.1
//   (sauf le bilan de phase, qui n'est pas un exercice) ; sauvegarde
//   d'origine intacte.
// - Ancienne sauvegarde exportée (format 6.x, exercice personnel, anciens
//   identifiants du pack) : importable, rien ne disparaît.
// - Bibliothèque : catégorie et muscle principal (vocabulaires fermés) dans
//   le menu « Filtres », fiche sur les champs v1.1, thèmes sombre et clair.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/search.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

/// Index du pack 2.0.0 archivé (hors de l'application).
Map<String, dynamic> _archivedIndex() =>
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File(
                'tools/archives/pack_2.0.0/index.json.gz',
              ).readAsBytesSync(),
            ),
          ),
        )
        as Map<String, dynamic>;

/// Sauvegarde du propriétaire (programme commencé le 13/07/2026), journal
/// de S1·J1 à S14·J7 (comme `ci1h_charge_fixe_test`).
Future<void> _owner(AppStore app) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere(
    (k, _) => int.parse(k.substring(1, k.indexOf('-'))) > 14,
  );
  b['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(b)), isTrue);
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

/// Relevé indépendant de la date du jour : séances, séries validées,
/// meilleures performances, records par séance, séries par groupe de
/// chaque semaine saisie.
Map<String, Object?> _releve(AppStore app) {
  final history = statsHistory(app);
  var sets = 0;
  for (final h in history) {
    for (final e in h.session.ex.values) {
      sets += e.sets.where((s) => s.done).length;
    }
  }
  final records = <String, Object?>{};
  for (final h in history) {
    final hits = app.sessionRecords(h.id);
    if (hits.isNotEmpty) {
      records[h.id] = [
        for (final r in hits) [r.exercise, _r(r.kg), r.reps],
      ];
    }
  }
  final bests = exerciseBests(app.logs);
  final start = app.program.start ?? app.program.anchorMonday;
  return {
    'seances': history.length,
    'series': sets,
    'records': records,
    'meilleures': bests.length,
    'semaines': [
      for (var w = 0; w < 14; w++)
        {
          for (final e in app
              .weeklyMuscles(
                DateTime(start.year, start.month, start.day + 7 * w + 6, 22),
              )
              .entries)
            if (e.value > 0) e.key: _r(e.value),
        },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('retrait du pack 2.0.0', () {
    test('plus aucune lecture de assets/content (assets, pubspec, code)', () {
      expect(Directory('assets/content').existsSync(), isFalse);
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('assets/content/')));
      expect(pubspec, contains('assets/catalog/groupes_historiques.json'));
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        expect(text, isNot(contains('assets/content/')), reason: f.path);
        expect(text, isNot(contains('LegacyPackIndex')), reason: f.path);
      }
    });

    test('groupes historiques : copie exacte du champ g du pack', () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppStore();
      await app.init();
      final old = {
        for (final e in _archivedIndex()['exercices'] as List)
          (e as Map)['n'] as String: e['g'] as String,
      };
      expect(old.length, 625);
      expect({for (final e in app.dbExercises) e['n']: e['g']}, old);
      // Un nom de l'ancien pack garde ses groupes (STATS inchangées).
      for (final e in old.entries) {
        final before = [
          for (final g in e.value.split(','))
            if (AppStore.muscleGroups.contains(g.trim())) g.trim(),
        ];
        if (before.isEmpty || app.splitName(e.key).$1 != e.key) continue;
        expect(app.groupsFor(e.key), before, reason: e.key);
      }
      app.dispose();
    });
  });

  group('migration depuis dev6.18.0 (S1 à S14, programme de 40 semaines)', () {
    test('mêmes séances, séries, records et statistiques ; ids v1.1 ; '
        'sauvegarde d\'origine intacte', () async {
      SharedPreferences.setMockInitialValues({});
      final clock = DateTime(2026, 10, 18, 20); // dimanche, S14·J7
      final app = AppStore()..storeClock = () => clock;
      await app.init();
      await _owner(app);
      await app.ensureProgramOrigin();
      await app.flush();
      final before = _releve(app);
      final exported = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final origin = jsonEncode(app.programOrigin);
      expect(app.programOrigin, isNotNull);
      expect(before['seances'], greaterThan(60));
      expect(before['series'], greaterThan(1000));
      app.dispose();

      final next = AppStore()..storeClock = () => clock;
      await next.init();
      expect(_releve(next), before);
      final after = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      for (final k in const ['logs', 'userExercises', 'programStart']) {
        expect(after[k], exported[k], reason: k);
      }
      expect(jsonEncode(next.programOrigin), origin);

      // Chaque nom du journal relié à son id v1.1 ; sans correspondance :
      // seulement le bilan de phase (pas un exercice), gardé tel quel.
      final names = <String>{
        for (final log in next.logs.values) ...log.exerciseNames.values,
      };
      final orphans = [
        for (final n in names)
          if (next.content.idFor(n) == null) n,
      ]..sort();
      // ignore: avoid_print
      print('BV11|journal|noms=${names.length}|sans-id=$orphans');
      expect(orphans.every((n) => n.startsWith('BILAN')), isTrue);
      for (final n in names) {
        final id = next.content.idFor(n);
        if (id != null) expect(next.content.byId.containsKey(id), isTrue);
      }

      // Programme de 40 semaines : chaque ligne reliée à son id v1.1,
      // contenu inchangé (intitulés de l'asset, 1 812 lignes).
      var lines = 0, linked = 0;
      for (final w in next.program.weeks) {
        for (final d in w.days) {
          for (final ex in d.exercises) {
            lines++;
            final id = ex.catalogId ?? next.content.idFor(ex.name);
            if (id != null) {
              linked++;
            } else {
              expect(ex.name, startsWith('BILAN'));
            }
          }
        }
      }
      // ignore: avoid_print
      print('BV11|programme|lignes=$lines|reliees=$linked');
      expect(lines, 1812);
      expect(linked, greaterThan(1700));
      next.dispose();
    });

    test('ancienne sauvegarde exportée (pack 2.0.0) : importable, '
        'exercice personnel et anciens identifiants gardés', () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppStore()..storeClock = () => DateTime(2026, 9, 1, 10);
      await app.init();
      final b = backupOf(app);
      b['userExercises'] = [
        {'n': 'Mon mouvement maison', 'g': 'dos, biceps', 'eq': 'serviette'},
      ];
      final log = SessionLog(
        done: true,
        finishedAt: DateTime(2026, 8, 20, 18).toIso8601String(),
        title: 'S6 · J1',
      );
      // Noms tels qu'enregistrés avant la base v1.1 : nom du pack, ancien
      // identifiant (sauvegarde d'un état intermédiaire), nom personnel.
      for (final (i, name) in const [
        'Back squat',
        'back-squat',
        'Mon mouvement maison',
      ].indexed) {
        log.exerciseNames['x$i'] = name;
        log.ex['x$i'] = ExerciseLog(
          sets: [
            SetEntry(kg: '80', reps: '5', rir: '2', done: true),
            SetEntry(kg: '80', reps: '5', rir: '2', done: true),
          ],
        );
      }
      b['logs'] = {app.sessionKey(6, 1): log.toJson()};
      expect(await app.importBackup(jsonEncode(b)), ImportStatus.success);
      expect(app.userExercises.single['n'], 'Mon mouvement maison');
      expect(app.groupsFor('Mon mouvement maison'), ['dos', 'biceps']);
      expect(app.content.idFor('back-squat'), 'sl-squat-competition');
      expect(app.content.idFor('Back squat'), isNotNull);
      expect(app.content.idFor('Mon mouvement maison'), isNull);
      final kept = app.logs.values.single.exerciseNames.values.toList();
      expect(kept, ['Back squat', 'back-squat', 'Mon mouvement maison']);
      expect(
        app.logs.values.single.ex.values
            .expand((e) => e.sets)
            .where((s) => s.done)
            .length,
        6,
      );
      app.dispose();
    });
  });

  group('bibliothèque v1.1', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
    });

    test('catégorie et muscle principal (vocabulaires fermés)', () {
      final index = store.content;
      expect(index.categoryVocabulary.length, 56);
      expect(index.muscleVocabulary.length, 56);
      final tv = searchExercises(
        index,
        '',
        const ExerciseFilters(categoryNames: {'Tirage vertical'}),
      );
      expect(tv, isNotEmpty);
      expect(tv.every((e) => e.categorie == 'Tirage vertical'), isTrue);
      final gd = searchExercises(
        index,
        '',
        const ExerciseFilters(
          categoryNames: {'Tirage vertical'},
          primaryMuscles: {'grand dorsal'},
        ),
      );
      expect(gd, isNotEmpty);
      expect(gd.length, lessThanOrEqualTo(tv.length));
      expect(
        gd.every((e) => e.ex.primaryMuscles.contains('grand dorsal')),
        isTrue,
      );
      final sel = ExerciseFilters.fromSelection(
        const FilterSelection({
          'categorie': {'cat:Tirage vertical'},
          'muscle': {'mus:grand dorsal'},
        }),
      );
      expect(sel.categoryNames, {'Tirage vertical'});
      expect(sel.primaryMuscles, {'grand dorsal'});
      // Les 8 disciplines sont toutes atteignables.
      final disciplines = {for (final e in index.entries) e.discipline};
      expect(disciplines.length, 8);
    });

    for (final dark in const [true, false]) {
      final theme = dark ? 'sombre' : 'clair';
      testWidgets('filtres catégorie et muscle, puis fiche ($theme)', (
        tester,
      ) async {
        phone(tester);
        ExerciseLibraryScreen.session = const FilterSelection();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(dark),
            home: const ExerciseLibraryScreen(),
          ),
        );
        await tester.pumpAndSettle();
        final counter = find.byKey(const ValueKey('library-count'));
        int count() {
          final text = tester.widget<Text>(counter).data!;
          return int.parse(RegExp(r'(\d+) exercice').firstMatch(text)![1]!);
        }

        Future<void> tap(String key) async {
          final f = find.byKey(ValueKey(key)).first;
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          await tester.tap(f);
          await tester.pumpAndSettle();
        }

        final all = count();
        expect(all, 1039);
        await tap('library-filters');
        await tap('library-filter-cat-categorie');
        await tap('library-filter-cat:Tirage vertical');
        final tv = count();
        expect(tv, lessThan(all));
        await tap('library-filter-cat-muscle');
        await tap('library-filter-mus:grand dorsal');
        final gd = count();
        expect(gd, greaterThan(0));
        expect(gd, lessThanOrEqualTo(tv));
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        final first = find.byWidgetPredicate((w) {
          final k = w.key;
          return k is ValueKey<String> && k.value.startsWith('library-ex-');
        });
        expect(first, findsWidgets);
        await tester.ensureVisible(first.first);
        await tester.pumpAndSettle();
        await tester.tap(first.first);
        await tester.pumpAndSettle();
        for (final title in const [
          'Points clés',
          'Erreurs fréquentes',
          'Respiration',
          'Muscles',
          'Matériel et lieux',
        ]) {
          await scrollSlowlyTo(tester, find.text(title));
          expect(find.text(title), findsOneWidget, reason: title);
        }
        expect(tester.takeException(), isNull);
        ExerciseLibraryScreen.session = const FilterSelection();
      });
    }
  });
}
