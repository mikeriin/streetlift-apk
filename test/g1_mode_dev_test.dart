// G1 — mode dev : isolation des données de la session de test, suppression
// complète, horloge et voyage dans le temps, fenêtre de 2 s entre les
// appuis, appui long de 3 s (relâcher avant annule), outils de test,
// avertissement à l'import d'une sauvegarde de session de test.
//
// Deux passages en CI : `flutter test` (build ordinaire : le mode dev est
// absent, le logo n'a aucun geste) et `flutter test
// --dart-define=KALIS_DEV=true test/g1_mode_dev_test.dart` (build de
// développement : parcours complet de la session de test).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/backup_files.dart';
import 'package:streetlift_tracker/brand.dart';
import 'package:streetlift_tracker/data_control.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/dev/dev_widgets.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_host.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

Widget _page(Widget child, {bool dark = true, double scale = 1}) =>
    MaterialApp(
      theme: buildTheme(dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void _silencePlatform() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('toujours', () {
    test('KalisPrefs : deux espaces sans lecture ni écriture croisée', () async {
      SharedPreferences.setMockInitialValues({
        'a': '1',
        'n': 4,
        '${SessionSpace.devPrefix}a': '2',
        SessionSpace.controlKey: '{}',
      });
      final raw = await SharedPreferences.getInstance();
      final perso = KalisPrefs(raw, dev: false);
      final test = KalisPrefs(raw, dev: true);
      expect(perso.getKeys(), {'a', 'n'});
      expect(test.getKeys(), {'a'});
      expect(perso.getString('a'), '1');
      expect(test.getString('a'), '2');
      expect(test.getInt('n'), isNull);
      await test.setString('b', 'x');
      await test.setInt('n', 9);
      expect(perso.containsKey('b'), isFalse);
      expect(perso.getInt('n'), 4);
      expect(raw.getString('${SessionSpace.devPrefix}b'), 'x');
      await test.remove('a');
      expect(perso.getString('a'), '1');
      await perso.remove('a');
      expect(test.getKeys(), {'b', 'n'});
      expect(perso.snapshot(), {'n': 4});
      expect(
        () => perso.setString(SessionSpace.controlKey, 'y'),
        throwsArgumentError,
      );
      expect(() => test.getString(SessionSpace.controlKey), throwsArgumentError);
      expect(raw.getString(SessionSpace.controlKey), '{}');
    });

    test('Horloge : décalage seulement dans un build de développement', () {
      final before = DateTime.now();
      KalisClock.setOffsetDays(3);
      expect(KalisClock.offsetDays, kDevBuild ? 3 : 0);
      final now = KalisClock.now();
      expect(
        _day(now),
        DateTime(before.year, before.month, before.day + (kDevBuild ? 3 : 0)),
      );
      KalisClock.setOffsetDays(0);
      expect(KalisClock.offsetDays, 0);
      expect(
        KalisClock.now().difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('Série d’appuis : 5 appuis, 2 s au plus entre deux', () {
      final s = TapStreak();
      var t = DateTime(2026, 10, 1);
      bool tap(int ms) {
        t = t.add(Duration(milliseconds: ms));
        return s.tap(t);
      }

      expect([for (var i = 0; i < 4; i++) tap(2000)], [false, false, false, false]);
      expect(tap(2000), isTrue); // 2 s pile : compté.
      expect(s.count, 0);
      for (var i = 0; i < 4; i++) {
        tap(300);
      }
      expect(s.count, 4);
      expect(tap(2001), isFalse); // au-delà de 2 s : la série repart.
      expect(s.count, 1);
      expect([for (var i = 0; i < 4; i++) tap(1)], [false, false, false, true]);
      // Horloge qui recule : nouvelle série.
      tap(10);
      t = t.subtract(const Duration(seconds: 5));
      expect(s.tap(t), isFalse);
      expect(s.count, 1);
    });

    test('Nom et marque des exports de la session de test', () {
      final at = DateTime(2026, 10, 1, 9, 5);
      expect(backupFileName(at), 'kalis-track-sauvegarde-2026-10-01-0905.json');
      expect(
        backupFileName(at, test: true),
        'kalis-track-session-de-test-2026-10-01-0905.json',
      );
      expect(isTestSessionBackup('{"sessionDeTest":true}'), isTrue);
      expect(isTestSessionBackup('{"sessionDeTest":false}'), isFalse);
      expect(isTestSessionBackup('{"format":3}'), isFalse);
      expect(isTestSessionBackup('pas du json'), isFalse);
      expect(isTestSessionBackup('[1]'), isFalse);
    });

    testWidgets(
      'Build ordinaire : logo d’origine, aucun geste',
      (tester) async {
        _silencePlatform();
        await tester.pumpWidget(_page(const Center(child: HeaderLogo())));
        expect(find.byType(KalisLogo), findsOneWidget);
        expect(find.byType(DevLogoGesture), findsNothing);
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byType(KalisLogo), warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(DevSession.active.value, isFalse);
        expect(SessionSpace.isDev, isFalse);
      },
      skip: kDevBuild,
    );

    group('import', () {
      setUpAll(() async {
        SharedPreferences.setMockInitialValues({});
        store = AppStore();
        await store.init();
      });

      testWidgets(
        'Sauvegarde d’une session de test : avertissement avant tout aperçu',
        (tester) async {
          final data =
              jsonDecode(store.exportForFile(appVersion: 't')) as Map<String, dynamic>;
          data['sessionDeTest'] = true;
          final raw = jsonEncode(data);
          await tester.pumpWidget(
            _page(
              Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () =>
                        confirmAndImport(context, raw, appVersion: 't'),
                    child: const Text('Importer'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Importer'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('test-session-import-warning')),
            findsOneWidget,
          );
          expect(find.byType(ImportPreviewDialog), findsNothing);
          await tester.tap(find.text('Annuler'));
          await tester.pumpAndSettle();
          expect(find.byType(ImportPreviewDialog), findsNothing);
          expect(find.textContaining('Import annulé'), findsOneWidget);

          // Continuer : l'aperçu habituel s'ouvre ensuite (rien n'est encore
          // importé).
          await tester.tap(find.text('Importer'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('test-session-import-continue')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ImportPreviewDialog), findsOneWidget);
          Navigator.of(tester.element(find.byType(ImportPreviewDialog))).pop();
          await tester.pumpAndSettle();
          expect(find.textContaining('Import annulé'), findsOneWidget);

          // Sauvegarde ordinaire : aucun avertissement.
          await tester.pumpWidget(
            _page(
              Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => confirmAndImport(
                      context,
                      store.exportForFile(appVersion: 't'),
                      appVersion: 't',
                    ),
                    child: const Text('Importer normal'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Importer normal'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('test-session-import-warning')),
            findsNothing,
          );
          expect(find.byType(ImportPreviewDialog), findsOneWidget);
          Navigator.of(tester.element(find.byType(ImportPreviewDialog))).pop();
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('build de développement', () {
    late AppStore original;
    var cleared = 0;
    setUp(() {
      original = store;
      cleared = 0;
      DevShare.debugHook = (name, text) async {
        if (name == null) cleared++;
        return 'shared';
      };
    });
    tearDown(() {
      store = original;
      DevShare.debugHook = null;
      SessionSpace.devActive = false;
      KalisClock.setOffsetDays(0);
      DevSession.active.value = false;
    });

    test(
      'Session de test : installation neuve, isolation, voyage dans le temps, redémarrage, suppression complète',
      () async {
        SharedPreferences.setMockInitialValues({});
        final raw = await SharedPreferences.getInstance();
        await DevSession.load();
        expect(DevSession.active.value, isFalse);

        // Session personnelle avec des données.
        final perso = AppStore();
        await perso.init();
        perso.settings
          ..accent = 'turquoise'
          ..theme = 'dark';
        perso.saveSettings();
        expect(
          await perso.configureStart(
            _day(DateTime.now()).subtract(const Duration(days: 10)),
          ),
          StartSave.saved,
        );
        perso.saveProfile(perso.ownerDraft());
        await perso.flush();
        expect(perso.isFreshInstall, isFalse);
        String persoRaw() => jsonEncode(KalisPrefs(raw, dev: false).snapshot());
        final before = persoRaw();
        final keysBefore = raw.getKeys().toSet();
        final at = DateTime(2026, 10, 1, 12);
        final exportBefore = jsonDecode(
          perso.exportForFile(appVersion: 't', at: at),
        );
        expect((exportBefore as Map).containsKey('sessionDeTest'), isFalse);

        // Création : installation neuve.
        await DevSession.create();
        expect(DevSession.active.value, isTrue);
        expect(SessionSpace.isDev, isTrue);
        expect(DevSession.createdAt, isNotNull);
        final test = AppStore();
        await test.init();
        expect(test.isFreshInstall, isTrue);
        expect(test.settings.accent, 'rouge');
        expect(test.program.start, isNull);
        expect(test.profile, isNull);
        test.settings.accent = 'violet';
        test.saveSettings();
        expect(await test.configureStart(_day(DateTime.now())), StartSave.saved);
        await test.flush();
        expect(persoRaw(), before);
        expect(
          raw.getKeys().where((k) => k.startsWith(SessionSpace.devPrefix)),
          isNotEmpty,
        );
        // Une seconde création ne remplace pas la session en cours.
        await DevSession.create();
        expect(
          KalisPrefs(raw, dev: true).getString('settings_v1') ??
              KalisPrefs(raw, dev: true).getString('kalis_state_v3'),
          isNotNull,
        );

        // Export marqué « session de test ».
        final exported =
            jsonDecode(test.exportForFile(appVersion: 't', at: at)) as Map;
        expect(exported['sessionDeTest'], isTrue);
        expect(exported['decalageJours'], 0);
        expect(isTestSessionBackup(jsonEncode(exported)), isTrue);

        // Voyage dans le temps : date de la session de test seulement.
        final real = DateTime.now();
        await DevSession.setOffsetDays(7);
        expect(KalisClock.offsetDays, 7);
        expect(
          _day(KalisClock.now()),
          DateTime(real.year, real.month, real.day + 7),
        );
        final travelled = AppStore();
        await travelled.init();
        expect(_day(travelled.storeClock()), _day(KalisClock.now()));
        expect(travelled.settings.accent, 'violet');
        expect(persoRaw(), before);

        // Redémarrage à froid : la session de test est relue du stockage.
        SessionSpace.devActive = false;
        KalisClock.setOffsetDays(0);
        DevSession.active.value = false;
        await DevSession.load();
        expect(DevSession.active.value, isTrue);
        expect(SessionSpace.isDev, isTrue);
        expect(KalisClock.offsetDays, 7);

        // « Supprimer les données » dans la session de test : la session
        // personnelle n'est pas touchée.
        final again = AppStore();
        await again.init();
        final erased = await again.eraseAllData();
        expect(erased.status, EraseStatus.success);
        expect(persoRaw(), before);

        // Suppression : plus aucune clé ni fichier de la session de test.
        final remaining = await DevSession.destroy();
        expect(remaining, isEmpty);
        expect(cleared, 1);
        expect(DevSession.active.value, isFalse);
        expect(SessionSpace.isDev, isFalse);
        expect(KalisClock.offsetDays, 0);
        expect(raw.getKeys().where(SessionSpace.reserved), isEmpty);
        expect(raw.getKeys().toSet(), keysBefore);
        expect(persoRaw(), before);
        final back = AppStore();
        await back.init();
        expect(back.isFreshInstall, isFalse);
        expect(back.settings.accent, 'turquoise');
        expect(
          jsonDecode(back.exportForFile(appVersion: 't', at: at)),
          exportBefore,
        );
      },
      skip: !kDevBuild,
    );

    testWidgets(
      'Logo : 5 appuis rapprochés démarrent la session de test',
      (tester) async {
        _silencePlatform();
        var now = DateTime(2026, 10, 1, 8);
        var started = 0;
        await tester.pumpWidget(
          _page(
            Center(
              child: DevLogoGesture(
                active: false,
                onFiveTaps: () => started++,
                onHoldComplete: () {},
                clock: () => now,
              ),
            ),
          ),
        );
        Future<void> tapAfter(int ms) async {
          now = now.add(Duration(milliseconds: ms));
          await tester.tap(find.byType(DevLogoGesture));
          await tester.pump();
        }

        for (var i = 0; i < 4; i++) {
          await tapAfter(2000);
        }
        expect(started, 0);
        await tapAfter(2000);
        expect(started, 1);
        for (var i = 0; i < 4; i++) {
          await tapAfter(400);
        }
        await tapAfter(2100); // trop tard : la série repart de 1.
        expect(started, 1);
        for (var i = 0; i < 3; i++) {
          await tapAfter(400);
        }
        expect(started, 1);
        await tapAfter(400);
        expect(started, 2);
        // Appui trop long : ce n'est pas un appui court.
        final g = await tester.startGesture(
          tester.getCenter(find.byType(DevLogoGesture)),
        );
        now = now.add(const Duration(seconds: 1));
        await g.up();
        await tester.pump();
        expect(started, 2);
        expect(find.byType(KalisLogo), findsOneWidget);
        final logo = tester.widget<KalisLogo>(find.byType(KalisLogo));
        expect(logo.color, isNot(kDevPink));
      },
      skip: !kDevBuild,
    );

    testWidgets(
      'Logo rose : appui long de 3 s, relâcher avant annule',
      (tester) async {
        _silencePlatform();
        var deleted = 0;
        await tester.pumpWidget(
          _page(
            Center(
              child: DevLogoGesture(
                active: true,
                onFiveTaps: () => fail('5 appuis pendant la session de test'),
                onHoldComplete: () => deleted++,
              ),
            ),
          ),
        );
        final logo = tester.widget<KalisLogo>(find.byType(KalisLogo));
        expect(logo.color, kDevPink);
        final center = tester.getCenter(find.byType(DevLogoGesture));
        final ring = find.byKey(const ValueKey('dev-hold-ring'));

        var g = await tester.startGesture(center);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1500));
        expect(ring, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1400));
        await g.up();
        await tester.pump();
        expect(deleted, 0);
        expect(ring, findsNothing);

        // Glisser hors du logo annule aussi.
        g = await tester.startGesture(center);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await g.moveBy(const Offset(60, 0));
        await tester.pump(const Duration(seconds: 3));
        await g.up();
        await tester.pump();
        expect(deleted, 0);

        g = await tester.startGesture(center);
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(deleted, 1);
        await g.up();
        await tester.pump(const Duration(seconds: 1));
        expect(deleted, 1);

        // Appuis courts pendant la session de test : rien.
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.byType(DevLogoGesture));
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(deleted, 1);
        final handle = tester.ensureSemantics();
        await tester.pump();
        final semantics = tester.getSemantics(find.byType(DevLogoGesture));
        expect(semantics.label, contains('session de test active'));
        handle.dispose();
      },
      skip: !kDevBuild,
    );

    testWidgets(
      'Outils de test : lisibles en clair et en sombre, texte à 200 %',
      (tester) async {
        _silencePlatform();
        SharedPreferences.setMockInitialValues({});
        await tester.runAsync(DevSession.create);
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        for (final dark in [true, false]) {
          for (final scale in [1.0, 2.0]) {
            await tester.pumpWidget(
              _page(const DevToolsSheet(), dark: dark, scale: scale),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            expect(find.text('Outils de test'), findsOneWidget);
            expect(find.byKey(const ValueKey('dev-date')), findsOneWidget);
            expect(find.text('Aujourd’hui (heure réelle)'), findsOneWidget);
            for (final key in [
              'dev-plus-day',
              'dev-plus-week',
              'dev-pick-date',
              'dev-today',
              'dev-export',
              'dev-delete',
            ]) {
              expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
            }
            expect(find.text('Simulateur de séances'), findsOneWidget);
            expect(find.text('Inspecteur du moteur'), findsOneWidget);
          }
        }
        // Export JSON par le menu de partage.
        await tester.pumpWidget(_page(const DevToolsSheet()));
        SharedPreferences.setMockInitialValues({});
        store = AppStore();
        await tester.runAsync(store.init);
        String? sharedName, sharedText;
        DevShare.debugHook = (name, text) async {
          sharedName = name;
          sharedText = text;
          return 'shared';
        };
        await tester.ensureVisible(find.byKey(const ValueKey('dev-export')));
        await tester.tap(find.byKey(const ValueKey('dev-export')));
        for (var i = 0; i < 5; i++) {
          await tester.pump();
        }
        expect(sharedName, startsWith('kalis-track-session-de-test-'));
        expect(isTestSessionBackup(sharedText!), isTrue);
      },
      skip: !kDevBuild,
    );

    testWidgets(
      'Racine : redémarrage logique, application démontée puis remontée',
      (tester) async {
        final events = <String>[];
        var built = 0;
        await tester.pumpWidget(
          SessionHost(
            boot: () async {},
            builder: (init) => _Probe(
              init: init,
              onBuild: () => built++,
              onDispose: () => events.add('démonté'),
            ),
          ),
        );
        expect(find.byType(_Probe), findsOneWidget);
        expect(find.byType(DevBadge), findsOneWidget);
        final first = store;
        final done = SessionHost.restart(() async {
          events.add('changement');
        }, message: 'Session de test supprimée');
        await tester.pump();
        expect(SessionHost.switching, isTrue);
        expect(find.byType(_Probe), findsNothing);
        await tester.pump();
        await tester.pump();
        await done;
        await tester.pump();
        expect(events, ['démonté', 'changement']);
        expect(identical(store, first), isFalse);
        expect(find.byType(_Probe), findsOneWidget);
        expect(built, greaterThanOrEqualTo(2));
        expect(find.text('Session de test supprimée'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Session de test supprimée'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
      skip: !kDevBuild,
    );
  });
}

class _Probe extends StatefulWidget {
  final Future<void> init;
  final VoidCallback onBuild, onDispose;
  const _Probe({
    required this.init,
    required this.onBuild,
    required this.onDispose,
  });
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    // L'initialisation du magasin neuf (actifs) peut ne pas se terminer
    // dans le temps simulé du test : son résultat est ignoré.
    widget.init.catchError((_) {});
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return const SizedBox.expand();
  }
}
