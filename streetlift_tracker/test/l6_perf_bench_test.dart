// L6 — Banc de mesure hôte (KT-023). Désactivé sans
// --dart-define=KALIS_PERF=true : ce n'est pas un test de non-régression et
// il ne pose aucun seuil (les durées dépendent de la machine).
//
// Niveau de preuve : « mesure hôte ». Le code tourne dans flutter_tester
// (machine virtuelle Dart en JIT, mode debug, sans GPU ni rastérisation) :
// les durées comparent deux versions du code sur la même machine et les
// mêmes données, elles ne sont PAS des durées sur téléphone.
//
// Le fichier n'utilise que des API publiques présentes dans la base 3.0.2 et
// dans la candidate L6 : le même banc tourne sur les deux arbres, en
// alternance, dans un même job CI (voir tools/perf_compare.py).
//
// Sortie : une ligne JSON par mesure (valeurs brutes en ms), écrite dans
// KALIS_PERF_OUT (fichier) et préfixée « KALIS_PERF » dans la sortie.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';

import 'support/perf_fixtures.dart';

const _enabled = bool.fromEnvironment('KALIS_PERF');
const _out = String.fromEnvironment('KALIS_PERF_OUT');
const _label = String.fromEnvironment('KALIS_PERF_LABEL', defaultValue: '?');
const _stateKey = 'kalis_state_v3';

/// Répétitions mesurées par scénario (après échauffement).
const _n = int.fromEnvironment('KALIS_PERF_N', defaultValue: 9);
const _warm = 2;

final _failures = <String>[];

void _emit(Map<String, Object?> row) {
  final line = jsonEncode({'label': _label, ...row});
  // ignore: avoid_print
  print('KALIS_PERF $line');
  if (_out.isNotEmpty) {
    File(_out).writeAsStringSync('$line\n', mode: FileMode.append);
  }
}

double _ms(Stopwatch sw) => sw.elapsedMicroseconds / 1000.0;

Future<void> _measure(
  String scenario,
  String profile,
  Future<double> Function() once, {
  int warm = _warm,
  int n = _n,
  Map<String, Object?> extra = const {},
}) async {
  try {
    for (var i = 0; i < warm; i++) {
      await once();
    }
    final values = <double>[];
    for (var i = 0; i < n; i++) {
      values.add(await once());
    }
    _emit({
      'scenario': scenario,
      'profile': profile,
      'status': 'ok',
      'unit': 'ms',
      'warmup': warm,
      'values': values,
      ...extra,
    });
  } catch (error, stack) {
    _failures.add('$scenario/$profile: $error');
    _emit({
      'scenario': scenario,
      'profile': profile,
      'status': 'echec',
      'error': '$error',
      'stack': '$stack'.split('\n').take(6).join(' | '),
    });
  }
}

/// Document stocké (clé principale) produit par l'application elle-même
/// pour le profil, et texte d'export équivalent.
final _stored = <String, String?>{};
final _exports = <String, String>{};
final _inventory = <String, Map<String, int>>{};

Future<void> _prepareProfiles() async {
  SharedPreferences.setMockInitialValues({});
  final seed = AppStore();
  await seed.init();
  for (final profile in perfProfiles) {
    final doc = perfBackup(seed, profile);
    _inventory[profile] = perfInventory(doc);
    if (doc == null) {
      _stored[profile] = null;
      continue;
    }
    SharedPreferences.setMockInitialValues({});
    final app = AppStore();
    await app.init();
    final ok = await app.importAll(jsonEncode(doc));
    if (!ok) throw StateError('fixture $profile refusée à l’import');
    await app.flush();
    _stored[profile] = (await SharedPreferences.getInstance()).getString(
      _stateKey,
    );
    _exports[profile] = app.exportAll();
    app.dispose();
  }
  seed.dispose();
}

Future<AppStore> _loaded(String profile) async {
  final stored = _stored[profile];
  SharedPreferences.setMockInitialValues({
    if (stored != null) _stateKey: stored,
  });
  final app = AppStore();
  await app.init();
  app.settings
    ..sound = false
    ..vibration = false
    ..wakelock = false
    ..autoTimer = false;
  return app;
}

/// Journal de programme non terminé, pour les saisies en cours.
ExerciseLog _openSet(AppStore app) {
  final week = app.program.weeks.last;
  final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
  final key = app.sessionKey(week.n, day.j);
  app.logs.remove(key);
  return app.exLog(week.n, day.j, day.exercises.first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('L6 banc hôte', skip: !_enabled, () {
    setUpAll(() async {
      await _prepareProfiles();
      _emit({
        'scenario': 'meta',
        'profile': '-',
        'status': 'ok',
        'dart': Platform.version,
        'os': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'cpus': Platform.numberOfProcessors,
        'n': _n,
        'warmup': _warm,
        'seed': perfSeed,
        'inventory': _inventory,
        'storedBytes': {
          for (final e in _stored.entries) e.key: e.value?.length ?? 0,
        },
        'exportBytes': {
          for (final e in _exports.entries) e.key: e.value.length,
        },
      });
    });

    tearDownAll(() {
      if (_failures.isNotEmpty) {
        fail('Mesures en échec : ${_failures.join(' ; ')}');
      }
    });

    test('démarrage : lecture du stockage, migrations, catalogue', () async {
      for (final profile in perfProfiles) {
        await _measure('store.init', profile, () async {
          final stored = _stored[profile];
          SharedPreferences.setMockInitialValues({
            if (stored != null) _stateKey: stored,
          });
          final app = AppStore();
          final sw = Stopwatch()..start();
          await app.init();
          sw.stop();
          app.dispose();
          return _ms(sw);
        });
      }
    });

    test('catalogue : génération et estimations', () async {
      final app = await _loaded('long');
      await _measure('catalog.generate', '-', () async {
        final sw = Stopwatch()..start();
        final list = app.catalogWods();
        sw.stop();
        expect(list, isNotEmpty);
        return _ms(sw);
      }, extra: {'wods': app.catalogWods().length});
      await _measure('catalog.rank', 'long', () async {
        final sw = Stopwatch()..start();
        app.rankCatalog();
        sw.stop();
        return _ms(sw);
      });
      // Estimations de tout le catalogue : deux passages successifs (le
      // second devrait profiter du cache s'il couvre tout le catalogue).
      await _measure('catalog.estimate.pass2', 'long', () async {
        for (final w in app.wods) {
          app.wodEstimate(w);
        }
        final sw = Stopwatch()..start();
        for (final w in app.wods) {
          app.wodEstimate(w);
        }
        sw.stop();
        return _ms(sw);
      }, extra: {'wods': app.wods.length});
      await _measure('catalog.wodStats.all', 'long', () async {
        final sw = Stopwatch()..start();
        for (final w in app.wods) {
          app.wodStats(w);
        }
        sw.stop();
        return _ms(sw);
      });
      await _measure('catalog.recommended', 'long', () async {
        app.notifyListeners();
        final sw = Stopwatch()..start();
        app.recommended();
        app.trialWod;
        app.weeklyIds;
        sw.stop();
        return _ms(sw);
      });
      app.dispose();
    });

    test('STATS : dérivés recalculés après une modification', () async {
      for (final profile in perfProfiles) {
        final app = await _loaded(profile);
        await _measure('derive.progression', profile, () async {
          app.notifyListeners();
          final sw = Stopwatch()..start();
          app.progression;
          sw.stop();
          return _ms(sw);
        });
        await _measure('derive.progression+game', profile, () async {
          app.notifyListeners();
          final sw = Stopwatch()..start();
          app.game;
          app.credits;
          sw.stop();
          return _ms(sw);
        });
        await _measure('stats.history', profile, () async {
          final sw = Stopwatch()..start();
          statsHistory(app);
          sw.stop();
          return _ms(sw);
        });
        await _measure('stats.exerciseBests', profile, () async {
          final sw = Stopwatch()..start();
          exerciseBests(app.logs);
          sw.stop();
          return _ms(sw);
        });
        await _measure('stats.weeklyMuscles', profile, () async {
          final sw = Stopwatch()..start();
          app.weeklyMuscles(DateTime(2026, 3, 25));
          sw.stop();
          return _ms(sw);
        });
        app.dispose();
      }
    });

    test(
      'persistance : saisie, validation, écriture, export, import',
      () async {
        for (final profile in perfProfiles) {
          final app = await _loaded(profile);
          final log = _openSet(app);
          var reps = 1;
          // Saisie d'une série (note/charge) : notification sans recalcul
          // des badges, puis écriture complète attendue (accusé de l'API).
          await _measure('save.keystroke+flush', profile, () async {
            log.sets.first.reps = '${reps++ % 20 + 1}';
            final sw = Stopwatch()..start();
            app.saveLogs(affectsProgression: false);
            await app.flush();
            sw.stop();
            expect(app.hasUnsavedChanges, isFalse);
            return _ms(sw);
          });
          await _measure('save.encode.exportAll', profile, () async {
            final sw = Stopwatch()..start();
            app.exportAll();
            sw.stop();
            return _ms(sw);
          });
          // Validation d'une série : invalide progression/jeu, relus comme
          // le fait l'écran, puis écriture attendue.
          final spec = app.logSpec(
            app.program.weeks.last.days
                .firstWhere((d) => d.exercises.isNotEmpty)
                .exercises
                .first,
          );
          log.sets.first
            ..kg = '50'
            ..reps = '5'
            ..rir = '2';
          await _measure('save.toggleSet+derive+flush', profile, () async {
            final sw = Stopwatch()..start();
            app.toggleSet(log, 0, spec);
            app.game;
            app.credits;
            await app.flush();
            sw.stop();
            return _ms(sw);
          });
          if (profile != 'neuf') {
            final text = _exports[profile]!;
            await _measure('import.preview', profile, () async {
              final sw = Stopwatch()..start();
              final r = app.previewImport(text);
              sw.stop();
              expect(r.preview, isNotNull);
              return _ms(sw);
            }, n: 5);
            await _measure('import.apply', profile, () async {
              final sw = Stopwatch()..start();
              final ok = await app.importAll(text);
              sw.stop();
              expect(ok, isTrue);
              return _ms(sw);
            }, n: 5);
          }
          await app.flush();
          app.dispose();
        }
      },
    );
  });

  group(
    'L6 banc hôte — écrans (moteur de test, sans GPU)',
    skip: !_enabled,
    () {
      for (final profile in ['long', 'charge']) {
        testWidgets('parcours $profile', (tester) async {
          await tester.runAsync(() async {
            if (_stored.isEmpty) await _prepareProfiles();
            SharedPreferences.setMockInitialValues({
              _stateKey: _stored[profile]!,
            });
            if (store.program.weeks.isEmpty) {
              await store.init();
            } else {
              expect(await store.importAll(_exports[profile]!), isTrue);
            }
            store.settings
              ..sound = false
              ..vibration = false
              ..wakelock = false
              ..autoTimer = false
              ..celebrations = false;
          });
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          Future<double> timedPump([Duration? d]) async {
            final sw = Stopwatch()..start();
            await tester.pump(d);
            sw.stop();
            return _ms(sw);
          }

          // Premier écran utile (PROGRAMME) une fois les données chargées.
          await _measure('ui.firstFrame', profile, () async {
            await tester.pumpWidget(const SizedBox());
            final sw = Stopwatch()..start();
            await tester.pumpWidget(const SLApp());
            sw.stop();
            await tester.pumpAndSettle();
            return _ms(sw);
          }, n: 5);

          // Premier affichage de STATS puis de chaque section.
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(const SLApp());
          await tester.pumpAndSettle();
          final firstStats = <double>[];
          await tester.tap(find.byKey(const ValueKey('nav-1')));
          firstStats.add(await timedPump());
          await tester.pumpAndSettle();
          final sections = <double>[];
          for (var i = 1; i < 4; i++) {
            await tester.tap(find.byKey(ValueKey('stats-section-$i')));
            sections.add(await timedPump());
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const ValueKey('nav-0')));
          final arsenal = await timedPump();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('nav-3')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('nav-2')));
          final back = await timedPump();
          await tester.pumpAndSettle();
          _emit({
            'scenario': 'ui.nav.firstVisit',
            'profile': profile,
            'status': 'ok',
            'unit': 'ms',
            'values': {
              'stats': firstStats,
              'statsSections': sections,
              'arsenal': [arsenal],
              'programmeReturn': [back],
            },
          });

          // Séance ouverte par-dessus les quatre onglets visités.
          final week = store.program.weeks.last;
          final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
          store.logs.remove(store.sessionKey(week.n, day.j));
          appNavigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => SessionScreen(week: week, day: day),
            ),
          );
          await tester.pumpAndSettle();
          final exercise = day.exercises.first;
          final log = store.exLog(week.n, day.j, exercise);
          var reps = 1;
          await _measure('ui.session.keystroke', profile, () async {
            log.sets.first.reps = '${reps++ % 20 + 1}';
            store.saveLogs(affectsProgression: false);
            return timedPump();
          }, n: 15);
          final spec = store.logSpec(exercise);
          log.sets.first
            ..kg = '50'
            ..reps = '5'
            ..rir = '2';
          await _measure('ui.session.toggleSet', profile, () async {
            store.toggleSet(log, 0, spec);
            return timedPump();
          }, n: 10);
          await tester.pump(const Duration(seconds: 1));
          await tester.runAsync(store.flush);
          appNavigator.currentState!.pop();
          await tester.pumpAndSettle();

          // Catalogue WOD complet : ouverture, recherche, filtre, défilement.
          await _measure('ui.catalog.open', profile, () async {
            appNavigator.currentState!.push(
              MaterialPageRoute<void>(builder: (_) => const WodCatalogScreen()),
            );
            final t = await timedPump();
            await tester.pumpAndSettle();
            appNavigator.currentState!.pop();
            await tester.pumpAndSettle();
            return t;
          }, n: 5);
          appNavigator.currentState!.push(
            MaterialPageRoute<void>(builder: (_) => const WodCatalogScreen()),
          );
          await tester.pumpAndSettle();
          final search = find.byType(TextField).first;
          await _measure('ui.catalog.search', profile, () async {
            await tester.enterText(search, 'burpee');
            final t = await timedPump();
            await tester.enterText(search, '');
            await tester.pump();
            return t;
          }, n: 5);
          final chip = find.text('< 15 min');
          if (chip.evaluate().isNotEmpty) {
            await _measure('ui.catalog.filterShort', profile, () async {
              await tester.tap(chip.first);
              final t = await timedPump();
              await tester.tap(chip.first);
              await tester.pump();
              return t;
            }, n: 5);
          }
          await _measure('ui.catalog.scroll60', profile, () async {
            final list = find.byType(Scrollable).first;
            final sw = Stopwatch()..start();
            await tester.fling(list, const Offset(0, -3000), 4000);
            for (var i = 0; i < 60; i++) {
              await tester.pump(const Duration(milliseconds: 16));
            }
            sw.stop();
            await tester.pumpAndSettle();
            await tester.fling(list, const Offset(0, 6000), 8000);
            await tester.pumpAndSettle();
            return _ms(sw);
          }, n: 5);
          appNavigator.currentState!.pop();
          await tester.pumpAndSettle();

          // Changement de dominante et de mode (écran PROGRAMME, onglets
          // visités) : un aller-retour mesuré frame par frame.
          await _measure('ui.appearance.switch', profile, () async {
            store.settings.accent = 'vert';
            store.saveSettings();
            final a = await timedPump();
            store.settings.accent = 'rouge';
            store.saveSettings();
            await tester.pump();
            return a;
          }, n: 5);

          // Mémoire de l'hôte (processus flutter_tester, JIT) : ordre de
          // grandeur seulement, le ramasse-miettes n'est pas forcé.
          final rssBefore = ProcessInfo.currentRss;
          for (var i = 0; i < 10; i++) {
            appNavigator.currentState!.push(
              MaterialPageRoute<void>(builder: (_) => const WodCatalogScreen()),
            );
            await tester.pumpAndSettle();
            appNavigator.currentState!.pop();
            await tester.pumpAndSettle();
            appNavigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => SessionScreen(week: week, day: day),
              ),
            );
            await tester.pumpAndSettle();
            appNavigator.currentState!.pop();
            await tester.pumpAndSettle();
          }
          _emit({
            'scenario': 'ui.memory.rss10cycles',
            'profile': profile,
            'status': 'ok',
            'unit': 'bytes',
            'values': [rssBefore, ProcessInfo.currentRss],
            'note': 'RSS hôte avant/après 10 cycles, GC non forcé',
          });

          await tester.pump(const Duration(seconds: 1));
          await tester.runAsync(store.flush);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        });
      }
    },
  );

  // Rappelle que la progression est calculée par les deux versions de la
  // même manière (sanity : aucun profil ne doit donner une progression vide
  // alors qu'il contient des séances).
  test('L6 banc hôte — cohérence des profils', skip: !_enabled, () async {
    for (final profile in ['regulier', 'long', 'charge']) {
      final app = await _loaded(profile);
      final p = Progression.calculate(
        logs: app.logs,
        catalog: app.wods,
        program: app.program,
        now: DateTime(2026, 9, 26, 12),
      );
      expect(p.totalXp, greaterThan(0), reason: profile);
      app.dispose();
    }
  });
}
