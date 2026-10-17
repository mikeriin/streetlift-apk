// PR9 — captures de la séance du programme PPL street (S1·J1 : muscle-up
// en E2MOM, traction + pompes enchaînées, rowing, poignets, finisher face
// pulls + curl) : chaque page, la feuille ⓘ, le menu ⋯ et la note en
// flammes, sombre et clair. Lancé avec --dart-define=KALIS_CAPTURE=true
// (workflow captures.yml : images poussées dans shots/) ; sans la
// variable, vérifie l'absence d'exception et de débordement.
//
// Données synthétiques : semaine type du programme (test/fixtures),
// références de la fixture de test, horloge fixe.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/program_instance.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/ui_capture.dart';

Future<void> _state(AppStore app) async {
  final backup = backupOf(app);
  final week = (jsonDecode(
    File('test/fixtures/pr9_semaine.json').readAsStringSync(),
  ) as Map).cast<String, dynamic>();
  backup['programStart'] = {
    'status': 'set',
    'date': '2026-10-19',
    'origin': 'migration',
  };
  backup['programInstance'] = {
    'v': 1,
    'kind': 'generated',
    'origin': 'user',
    'createdAt': '2026-10-17T12:00:00',
    'updatedAt': '2026-10-17T12:00:00',
    'generator': 'test',
    'seed': 0,
    'weeks': [week, restWeek(2)],
    'cycle': 1,
  };
  expect(await app.importAll(jsonEncode(backup)), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    store.storeClock = () => DateTime(2026, 10, 19, 9);
    await store.init();
    await _state(store);
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(store.storeClock()),
          guidance: kc.GuidanceMode.assisted,
        ).copyWith(experience: kc.ExperienceLevel.advanced),
      )..consent = 'refused',
    );
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    if (uiCaptureEnabled) await loadUiFonts();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, {required bool dark}) async {
    tester.view.physicalSize = const Size(390, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store.settings.theme = dark ? 'dark' : 'light';
    final week = store.program.week(1);
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(dark),
          home: SessionScreen(week: week, day: week.day(1)!),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> shot(WidgetTester tester, String name, bool dark) async {
    expect(tester.takeException(), isNull, reason: name);
    if (!uiCaptureEnabled) return;
    await saveUiPng(
      tester,
      root,
      'pr9_${name}_${dark ? 'sombre' : 'clair'}',
      pixelRatio: 1.5,
    );
  }

  for (final dark in [true, false]) {
    testWidgets('pages de la séance, ${dark ? 'sombre' : 'clair'}', (
      tester,
    ) async {
      await show(tester, dark: dark);
      final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
      for (var i = 0; i < 8; i++) {
        pages.jumpToPage(i);
        await settle(tester);
        await shot(tester, 'page$i', dark);
      }
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  }

  testWidgets('feuille ⓘ, menu ⋯ et note en flammes', (tester) async {
    await show(tester, dark: true);
    final pages = tester.widget<PageView>(find.byType(PageView)).controller!;
    // Page de la traction (première page avec une coche « Valider »).
    for (var i = 0; i < 8; i++) {
      pages.jumpToPage(i);
      await settle(tester);
      if (find.byTooltip('Valider la série 1').evaluate().isNotEmpty) break;
    }
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await settle(tester);
    await shot(tester, 'serie_validee', true);
    final flame = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('set-flame-') &&
          !(w.key! as ValueKey<String>).value.startsWith('set-flame-value'),
    );
    if (flame.evaluate().isNotEmpty) {
      await tester.tap(flame.first);
      await settle(tester);
      await shot(tester, 'flammes_popup', true);
      await tester.tapAt(const Offset(4, 4));
      await settle(tester);
    }
    Finder keyed(String suffix) => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.endsWith(suffix),
    );
    final info = keyed('-instructions');
    if (info.evaluate().isNotEmpty) {
      await tester.tap(info.first);
      await settle(tester);
      await shot(tester, 'feuille_info', true);
      await tester.tapAt(const Offset(4, 4));
      await settle(tester);
    }
    final menu = keyed('-menu');
    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu.first);
      await settle(tester);
      await shot(tester, 'menu', true);
    }
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
