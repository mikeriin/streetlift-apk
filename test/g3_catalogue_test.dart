// G3 (dev6.2.0, D4.10) — base d'exercices v1.1 dans l'application :
// - catalogue : asset identique octet pour octet à celui du paquet étiqueté
//   (kalis_core-v0.1.0), chargé par `Catalog` de kalis_core ;
// - muscles : chaque muscle de la base relié à l'atlas, dessiné sur la carte
//   ou listé comme profond ;
// - correspondance : intitulés du programme embarqué, anciens identifiants,
//   noms d'un historique complet ; démonstrations reliées par identifiant ;
// - conversion du journal (règles C1 à C12) : exemple du paquet reproduit à
//   l'identique, puis correspondance réelle et historique complet ;
// - fiches : une par discipline, sombre et clair, sans exception.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' show jsonDeepEquals;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/journal_adapter.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/ui.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

/// Muscles de la base sans région sur la carte 2D (profonds, listés en
/// texte sur la fiche).
const _profonds = {
  'petit pectoral',
  'élévateur de la scapula',
  'multifides',
  'carré des lombes',
  'coraco-brachial',
  'supinateur',
  'muscles intrinsèques de la main',
  'obliques internes',
  'transverse de l\'abdomen',
  'diaphragme',
  'petit fessier',
  'rotateurs externes de hanche',
  'muscles intrinsèques du pied',
  'fléchisseurs profonds du cou',
};

/// Un exercice par discipline.
const _parDiscipline = {
  'Musculation': 'mu-developpe-couche-barre',
  'Street workout': 'sw-traction-pronation',
  'Streetlifting': 'sl-squat-competition',
  'Calisthénie statique': 'cs-planche-tuck',
  'Calisthénie dynamique': 'cd-muscle-up-barre-strict',
  'CrossFit / WOD': 'cf-burpee',
  'Cardio': 'ca-footing-endurance-fondamentale',
  'Mobilité': 'mo-routine-mobilite-epaules-poignets',
};

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File(
            'packages/kalis_core/test/fixtures/legacy_journal.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  group('catalogue', () {
    test('asset de l\'application = asset du paquet, octet pour octet', () {
      final app = File(ContentIndex.catalogAsset).readAsBytesSync();
      final pkg = File(
        'packages/kalis_core/data/catalog_v1.json.gz',
      ).readAsBytesSync();
      expect(app.length, pkg.length);
      expect(app, pkg);
      // Et la table de correspondance désigne bien ce fichier.
      final table =
          jsonDecode(File(ContentIndex.correspondenceAsset).readAsStringSync())
              as Map<String, dynamic>;
      expect((table['catalogue'] as Map)['version'], '1.1.0');
      expect((table['catalogue'] as Map)['exercices'], 1039);
    });

    test('1 039 exercices, 8 disciplines, chargés par kalis_core', () async {
      final watch = Stopwatch()..start();
      // Un autre bundle que rootBundle : vraie lecture, sans le cache du
      // processus.
      final index = await ContentIndex.load(PlatformAssetBundle());
      watch.stop();
      // ignore: avoid_print
      print('G3_PERF chargement_catalogue_ms=${watch.elapsedMilliseconds}');
      expect(index.entries.length, 1039);
      expect(index.version, '1.1.0');
      expect(
        {for (final e in index.entries) e.discipline},
        {..._parDiscipline.keys},
      );
      expect(store.content.entries.length, 1039);
      // Base lue une fois par processus : un nouveau magasin la reprend.
      expect(
        identical(await ContentIndex.load(), await ContentIndex.load()),
        isTrue,
      );
      // Garde-fou large (environnement de test, JIT) ; le paquet mesure
      // ≤ 150 ms en VM.
      expect(watch.elapsedMilliseconds, lessThan(5000));
    });

    test('chaque muscle de la base a une région, ou est profond', () {
      final muscles = store.content.catalog!.muscles;
      expect(muscles.length, 56);
      expect(kBaseMuscleAtlas.keys.toSet(), muscles.toSet());
      final deep = <String>{};
      for (final m in muscles) {
        final atlas = atlasOfBaseMuscle(m);
        expect(atlas, isNotEmpty, reason: m);
        for (final a in atlas) {
          expect(atlasMuscles.containsKey(a), isTrue, reason: '$m : $a');
        }
        if (!atlas.any(mapDrawsMuscle)) deep.add(m);
      }
      expect(deep, _profonds);
      // Groupes historiques : chaque muscle non profond en a un.
      for (final m in muscles) {
        if (deep.contains(m)) continue;
        final g = appGroupsOfBaseMuscles([m]);
        expect(g, isNotEmpty, reason: m);
        for (final x in g) {
          expect(AppStore.muscleGroups, contains(x), reason: m);
        }
      }
    });
  });

  test('L13 : textes reformulés à l’affichage, table à jour', () {
    final texts = <String>{
      for (final e in store.content.catalog!.exercises) ...[
        ...e.keyPoints,
        ...e.commonMistakes,
        e.breathing,
      ],
    };
    expect(kCatalogWording, hasLength(15));
    for (final k in kCatalogWording.keys) {
      expect(texts, contains(k), reason: k);
    }
    for (final e in store.content.entries) {
      final d = store.content.detail(e.id)!;
      for (final t in [...d.pointsCles, ...d.erreurs, d.respiration]) {
        expect(kCatalogWording.containsKey(t), isFalse, reason: e.id);
      }
    }
  });

  group('correspondance', () {
    test('intitulés du programme embarqué : tous reliés (sauf le bilan)', () {
      final labels = <String>{
        for (final w in store.program.weeks)
          for (final d in w.days)
            for (final e in d.exercises) e.name,
      };
      expect(labels.length, greaterThan(70));
      final missing = [
        for (final l in labels)
          if (store.exerciseIdFor(l) == null) l,
      ];
      expect(missing, ['BILAN — report des résultats']);
      for (final l in labels) {
        final id = store.exerciseIdFor(l);
        if (id != null) expect(store.content.byId.containsKey(id), isTrue);
      }
      // Les quatre lifts de streetlifting du programme.
      expect(
        store.exerciseIdFor('MUSCLE-UP LESTÉ — lift n°1, avant tout tirage'),
        'sl-muscle-up-leste',
      );
      expect(
        store.exerciseIdFor('TRACTION LESTÉE — lift principal'),
        'sl-traction-lestee',
      );
      expect(
        store.exerciseIdFor('DIP LESTÉ — lift principal'),
        'sl-dips-leste',
      );
      expect(
        store.exerciseIdFor('BACK SQUAT — lift principal'),
        'sl-squat-competition',
      );
    });

    test('anciens identifiants : 625, 10 sans équivalent, tous valides', () {
      final ids = store.content.legacyIds;
      expect(ids.length, 625);
      expect(ids.values.where((v) => v == null).length, 10);
      for (final e in ids.entries) {
        if (e.value == null) continue;
        expect(store.content.byId.containsKey(e.value), isTrue, reason: e.key);
        // Un ancien identifiant se résout aussi directement.
        expect(store.content.idFor(e.key), isNotNull, reason: e.key);
      }
      expect(
        store.content.idFor('sw-traction-pronation'),
        'sw-traction-pronation',
      );
      expect(store.exerciseIdFor('Mon mouvement maison 42'), isNull);
    });

    test(
      'historique complet de 40 semaines : chaque nom saisi est relié',
      () async {
        SharedPreferences.setMockInitialValues({});
        final app = AppStore();
        await app.init();
        expect(await app.importAll(jsonEncode(filledBackup(app))), isTrue);
        final names = <String>{
          for (final log in app.logs.values) ...log.exerciseNames.values,
        };
        final missing = [
          for (final n in names)
            if (app.exerciseIdFor(n) == null) n,
        ];
        expect(missing, ['BILAN — report des résultats']);
        app.dispose();
      },
    );

    test('démonstration existante gardée par correspondance d\'id', () async {
      final reg = await ClipRegistry.load();
      final debug = reg.debugClip!;
      final r = ClipRegistry([
        debug,
        ClipEntry(
          id: 'back-squat',
          asset: debug.asset,
          name: 'Back squat',
          exercises: const ['back-squat'],
          debug: false,
          fps: 30,
          frames: 181,
          bytes: debug.bytes,
          duration: 6,
          phases: debug.phases,
        ),
      ]);
      expect(ClipRegistry.legacyIds['back-squat'], 'sl-squat-competition');
      expect(r.forExercise('sl-squat-competition')!.id, 'back-squat');
      expect(r.forExercise('back-squat')!.id, 'back-squat');
      expect(r.forExercise('sw-traction-pronation'), isNull);
      expect(
        store.content.legacyIdsOf('sl-squat-competition'),
        contains('back-squat'),
      );
    });
  });

  group('conversion du journal (C1 à C12)', () {
    List<String> order(int w, int j) =>
        w >= 1 && w <= store.program.weeks.length
        ? [for (final e in store.program.week(w).day(j)?.exercises ?? []) e.id]
        : const [];

    bool seconds(String id) =>
        store.content.byId[id]?.ex.unit.code == 'secondes';

    test('exemple du paquet reproduit à l\'identique', () {
      final fx = _fixture();
      // Correspondance indicative utilisée par l'exemple (paquet).
      final owner =
          jsonDecode(
                utf8.decode(
                  gzip.decode(
                    File(
                      'packages/kalis_core/test/fixtures/owner_program_v33.json.gz',
                    ).readAsBytesSync(),
                  ),
                ),
              )
              as Map<String, dynamic>;
      final indicative = {
        for (final e in owner['exerciseNames'] as List)
          (e as Map)['name'] as String: e['catalogId'] as String?,
      };
      final out = convertLegacyJournal(
        (fx['before'] as Map).cast<String, dynamic>(),
        exerciseId: (n) => indicative[n],
        usesSeconds: seconds,
        dayOrder: order,
        legacyDate: store.program.legacyDateFor,
      );
      expect(out.log.validate(), isEmpty);
      expect(
        jsonDeepEquals(jsonDecode(jsonEncode(out.log.toJson())), fx['after']),
        isTrue,
      );
      expect(out.report.toJson(), fx['report']);
    });

    test('correspondance du lot : seul le bilan reste sans exercice', () {
      final fx = _fixture();
      final out = convertLegacyJournal(
        (fx['before'] as Map).cast<String, dynamic>(),
        exerciseId: store.content.idFor,
        usesSeconds: seconds,
        dayOrder: order,
        legacyDate: store.program.legacyDateFor,
      );
      expect(out.log.validate(), isEmpty);
      expect(out.report.unmappedExerciseNames, [
        'BILAN — report des résultats',
      ]);
      final ref = fx['report'] as Map<String, dynamic>;
      expect(out.report.sessionsRead, ref['sessionsRead']);
      expect(out.report.manualSessionsDropped, ref['manualSessionsDropped']);
      expect(out.report.setsNotDone, ref['setsNotDone']);
      // Séries faites : converties, ou sans mesure, ou du bilan.
      expect(
        out.report.setsConverted +
            out.report.setsUnmappedExercise +
            out.report.setsWithoutMeasure,
        (ref['setsConverted'] as int) +
            (ref['setsUnmappedExercise'] as int) +
            (ref['setsWithoutMeasure'] as int),
      );
      expect(
        out.report.setsConverted,
        greaterThan(ref['setsConverted'] as int),
      );
    });

    test(
      'historique complet : journal kalis_core valide, rien d\'inventé',
      () async {
        SharedPreferences.setMockInitialValues({});
        final app = AppStore();
        await app.init();
        final doc = filledBackup(app);
        expect(await app.importAll(jsonEncode(doc)), isTrue);
        final out = app.coreTrainingLog();
        expect(out.log.validate(), isEmpty);
        final r = out.report;
        final logs = doc['logs'] as Map<String, dynamic>;
        expect(r.sessionsRead, logs.length);
        expect(r.manualSessionsDropped, 0);
        expect(r.unmappedExerciseNames, ['BILAN — report des résultats']);
        // Chaque série faite est convertie, sauf celles du bilan.
        var done = 0, bilan = 0;
        for (final s in logs.values) {
          final m = s as Map;
          final names = (m['exerciseNames'] as Map).cast<String, dynamic>();
          (m['ex'] as Map).forEach((k, v) {
            final n = (v as Map)['sets'] as List;
            final d = n.where((x) => (x as Map)['done'] == true).length;
            done += d;
            if ('${names[k]}'.startsWith('BILAN')) bilan += d;
          });
        }
        expect(r.setsConverted + r.setsWithoutMeasure, done - bilan);
        expect(r.setsUnmappedExercise, bilan);
        expect(r.sessionsConverted + r.emptySessionsDropped, logs.length);
        // Identifiants : tous de la base, aucun inventé.
        final ids = {
          for (final s in out.log.sessions)
            for (final x in s.sets) x.exerciseId,
        };
        expect(store.content.catalog!.checkExerciseIds(ids), isEmpty);
        app.dispose();
      },
    );
  });

  group('fiches : une par discipline', () {
    Widget host(Widget page, {required bool dark}) => MaterialApp(
      theme: buildTheme(dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: page,
    );

    for (final dark in const [true, false]) {
      for (final e in _parDiscipline.entries) {
        testWidgets('${e.key} (${dark ? 'sombre' : 'clair'}, 200 %)', (
          tester,
        ) async {
          phone(tester, size: const Size(360, 720));
          await tester.pumpWidget(
            host(ExerciseSheetScreen(id: e.value), dark: dark),
          );
          await tester.pumpAndSettle();
          final entry = store.content.byId[e.value]!;
          expect(entry.discipline, e.key);
          expect(find.text(entry.nom.toUpperCase()), findsOneWidget);
          // Puce de la discipline (UI4 : puces neutres `KChip`).
          final badges = [
            for (final b in tester.widgetList<KChip>(
              find.byType(KChip, skipOffstage: false),
            ))
              b.label,
          ];
          expect(badges, contains(e.key), reason: '$badges');
          final d = store.content.detail(e.value)!;
          for (final k in const [
            'fiche-points-cles',
            'fiche-erreurs',
            'fiche-respiration',
            'fiche-muscles',
            'fiche-materiel',
          ]) {
            await scrollSlowlyTo(tester, find.byKey(ValueKey(k)));
            expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
            if (k == 'fiche-respiration') {
              expect(find.text(d.respiration), findsOneWidget);
            }
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
