// Rendus de l'application réelle : flutter test --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/progression_screen.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  const capture = bool.fromEnvironment('KALIS_CAPTURE');
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'rendus bordeaux et anthracite : écrans, thèmes et largeur compacte',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false;
      final sdk = Platform.environment['FLUTTER_ROOT'];
      if (sdk != null) {
        final dir = Directory('$sdk/bin/cache/artifacts/material_fonts');
        final fonts = dir.listSync().whereType<File>().where(
          (f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf'),
        );
        for (final family in ['Roboto', 'Ahem']) {
          final loader = FontLoader(family);
          for (final file in fonts) {
            loader.addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            );
          }
          await loader.load();
        }
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await icons.load();
      }
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetPadding);
      final boundaryKey = GlobalKey();
      var serial = 0;
      Future<void> render(
        Widget screen,
        bool dark,
        double width, {
        double height = 844,
      }) async {
        store.settings.theme = dark ? 'dark' : 'light';
        tester.view.physicalSize = Size(width, height);
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              key: ValueKey(serial++),
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              debugShowCheckedModeBanner: false,
              theme: buildTheme(dark),
              home: screen,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final context = tester.element(find.byType(MaterialApp));
          await Future.wait([
            // L9b : carte musculaire dessinée (atlas), plus d'images.
            precacheImage(
              const AssetImage('assets/icon/logo_mark.png'),
              context,
            ),
          ]);
        });
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          null,
          reason: '${screen.runtimeType} $width $dark',
        );
      }

      Future<void> save(String name) async {
        final render =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('validation/2.5.0/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      await render(const StatsScreen(), true, 390);
      await save('stats_vide_dark');
      final now = DateTime.now();
      final monday = DateTime(
        now.year,
        now.month,
        now.day - now.weekday + 1,
        8,
      );
      // Journal simulé exclusivement dans ce test de captures.
      for (var i = 0; i < 9; i++) {
        final week = 5 + i ~/ 3;
        final day = [1, 2, 4][i % 3];
        final date = i == 8
            ? now.subtract(const Duration(minutes: 10))
            : monday.subtract(Duration(days: 2 + (i ~/ 2) * 7 + i % 2));
        store.sessionLog(week, day)
          ..done = true
          ..title = 'S$week · ${store.program.week(week).day(day)!.title}'
          ..finishedAt = date.toIso8601String();
        for (final exercise
            in store.program.week(week).day(day)!.exercises.take(4)) {
          final log = store.exLog(week, day, exercise);
          for (final set in log.sets) {
            set
              ..done = true
              ..kg = '15'
              ..reps = '6'
              ..completedAt = date.toIso8601String();
          }
        }
      }
      store.sessionLog(11, 1).done = true;
      store.sessionLog(11, 2).done = true;
      store.notifyListeners();
      for (final dark in [true, false]) {
        final mode = dark ? 'dark' : 'light';
        await render(RootNav(referenceDate: DateTime(2026, 9, 24)), dark, 390);
        for (final tab in {
          2: 'programme',
          0: 'arsenal',
          1: 'stats_apercu',
          3: 'reglages',
        }.entries) {
          await tester.tap(find.byKey(ValueKey('nav-${tab.key}')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), null);
          await save('${tab.value}_$mode');
          if (tab.key == 1) {
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('stats-activity')),
              300,
              scrollable: find
                  .descendant(
                    of: find.byType(StatsScreen),
                    matching: find.byType(Scrollable),
                  )
                  .last,
            );
            await tester.pumpAndSettle();
            await save('stats_activite_$mode');
            final stats = tester.state<StatsScreenState>(
              find.byType(StatsScreen),
            );
            for (final section in [
              StatsSection.journey,
              StatsSection.performance,
              StatsSection.history,
            ]) {
              stats.selectSection(section);
              await tester.pumpAndSettle();
              expect(tester.takeException(), null);
              await save('stats_${section.name}_$mode');
            }
          }
        }
        final week = store.program.week(11);
        final day = week.day(1)!;
        final pages = <String, Widget>{
          'seance': SessionScreen(week: week, day: day),
          'historique': SessionHistoryScreen(
            log: store.sessionLog(11, 1),
            sessionKey: '11-1',
          ),
          'progression': const ProgressionScreen(),
          'chronometres': const SettingsScreen(page: SettingsPage.session),
          'references': const PilotageScreen(),
        };
        for (final page in pages.entries) {
          await render(page.value, dark, 390);
          await save('${page.key}_$mode');
        }
        await render(RootNav(referenceDate: DateTime(2026, 9, 24)), dark, 320);
        await save('programme_${mode}_320');
        await render(
          RootNav(referenceDate: DateTime(2026, 9, 24)),
          dark,
          390,
          height: 760,
        );
        await save('programme_${mode}_390_760');
        await render(const StatsScreen(), dark, 320);
        await save('stats_${mode}_320');
        await render(
          const StatsScreen(initialSection: StatsSection.journey),
          dark,
          320,
        );
        await save('arbre_${mode}_320');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    skip: !capture,
  );
}
