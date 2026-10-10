// L5-C — Sélecteur « Couleur dominante » et application sans redémarrage.
// UI0 (refonte UI) : sélecteur des 8 palettes du kit (pastilles de 56 dp,
// 4 par ligne, 8 à partir de 448 dp de large), mêmes comportements.
// Tests de widgets (moteur de test Flutter) : ils ne remplacent ni un essai
// TalkBack réel ni un essai sur téléphone. Données synthétiques.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/kit/kit.dart' show KTokens, KRoles;

Widget settingsPage({
  required bool dark,
  KAccentSpec accent = KAccentSpec.bordeaux,
  double textScale = 1,
}) => MaterialApp(
  theme: buildTheme(dark, accent),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: const SettingsScreen(),
);

void screen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> resetAppearance() async {
  store.debugWriteHook = null;
  store.settings
    ..theme = 'dark'
    ..accent = 'bordeaux'
    ..contrast = false;
  store.saveSettings();
  await store.flush();
}

String journal() =>
    jsonEncode((jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs']);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    store.program.start = DateTime(2026, 7, 13);
  });
  tearDown(resetAppearance);

  for (final (width, scale, columns) in [
    (390.0, 1.0, 4),
    (600.0, 1.0, 8),
    (320.0, 1.0, 4),
    (390.0, 1.3, 4),
    (390.0, 2.0, 4),
    (320.0, 2.0, 4),
  ]) {
    testWidgets(
      'sélecteur à $width px, texte ${(scale * 100).round()} % : $columns colonne(s)',
      (tester) async {
        screen(tester, Size(width, 844));
        for (final dark in [true, false]) {
          await tester.pumpWidget(settingsPage(dark: dark, textScale: scale));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('accent-solar')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          final rows = <double>{};
          final lefts = <double>{};
          for (final spec in KAccentSpec.all) {
            final option = find.byKey(ValueKey('accent-${spec.id}'));
            expect(option, findsOneWidget);
            final rect = tester.getRect(option);
            expect(rect.height, greaterThanOrEqualTo(48));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.right, lessThanOrEqualTo(width));
            expect(find.byTooltip(spec.label), findsOneWidget);
            rows.add(rect.top.roundToDouble());
            lefts.add(rect.left.roundToDouble());
          }
          // Nom de la palette choisie, lisible sans la couleur.
          expect(find.text('Bordeaux Performance'), findsWidgets);
          expect(lefts.length, columns, reason: 'colonnes $width $scale');
          expect(rows.length, (8 / columns).ceil());
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets(
    'sélection lisible sans la couleur et sémantique de choix unique',
    (tester) async {
      screen(tester, const Size(390, 844));
      await tester.pumpWidget(settingsPage(dark: true));
      await tester.pumpAndSettle();
      final handle = tester.ensureSemantics();
      expect(
        find.byKey(const ValueKey('accent-check-bordeaux')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('accent-check-neon')), findsNothing);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('accent-bordeaux'))),
        isSemantics(
          label: 'Bordeaux Performance',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('accent-neon'))),
        isSemantics(
          label: 'Neon Athlete',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: false,
        ),
      );
      handle.dispose();
      await tester.tap(find.byKey(const ValueKey('accent-neon')));
      await tester.pumpAndSettle();
      expect(store.settings.accent, 'neon');
      expect(store.accentMode.value, 'neon');
      expect(store.settings.theme, 'dark');
      await tester.pumpWidget(
        settingsPage(dark: true, accent: KAccentSpec.neon),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('accent-check-neon')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-check-bordeaux')), findsNothing);
      expect(find.textContaining('Neon Athlete :'), findsOneWidget);
    },
  );

  testWidgets('choix rapides dans l’écran : le dernier gagne', (tester) async {
    screen(tester, const Size(390, 844));
    await tester.pumpWidget(settingsPage(dark: false));
    await tester.pumpAndSettle();
    for (final id in [
      'forest',
      'violet',
      'solar',
      'arctic',
      'neon',
      'forest',
    ]) {
      await tester.tap(find.byKey(ValueKey('accent-$id')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await store.flush();
    expect(store.settings.accent, 'forest');
    expect(store.accentMode.value, 'forest');
    expect(store.hasUnsavedChanges, isFalse);
  });

  testWidgets('échec d’écriture : choix affiché, message « non enregistrés »', (
    tester,
  ) async {
    screen(tester, const Size(390, 844));
    await tester.pumpWidget(settingsPage(dark: true));
    await tester.pumpAndSettle();
    store.debugWriteHook = (_) async => false;
    await tester.tap(find.byKey(const ValueKey('accent-violet')));
    await tester.pumpAndSettle();
    await store.flush();
    await tester.pumpAndSettle();
    expect(store.accentMode.value, 'violet');
    expect(find.byKey(const ValueKey('accent-unsaved')), findsOneWidget);
    store.debugWriteHook = null;
    expect(await store.retrySave(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('accent-unsaved')), findsNothing);
  });

  testWidgets(
    'changer de couleur garde onglet, semaine, route, saisies et journal',
    (tester) async {
      screen(tester, const Size(390, 844));
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      final home = tester.state(find.byType(HomeScreen));
      await tester.drag(
        find.byKey(const ValueKey('week-slider')),
        const Offset(-40, 0),
      );
      await tester.pumpAndSettle();
      final week = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('selected-week')),
              matching: find.byType(Text),
            ),
          )
          .data;
      // Séance construite à la main (semaine 0) : les séances manuelles ont
      // disparu en G2, le runner reste le même.
      final plan = WeekPlan.manual(
        n: 0,
        block: 'Couleur',
        color: const Color(0xFF4FA3C7),
        days: [
          DayPlan.manual(
            j: 994,
            title: 'Couleur',
            exercises: [
              Exercise.manual(
                id: 'CU-994-0',
                name: 'Pompes',
                setsText: '2×8',
                forcedSets: 2,
              ),
              Exercise.manual(
                id: 'CU-994-1',
                name: 'Squat',
                setsText: '1×10',
                forcedSets: 1,
              ),
            ],
          ),
        ],
      );
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: plan, day: plan.days.single),
        ),
      );
      await tester.pumpAndSettle();
      final session = tester.state(find.byType(SessionScreen));
      final field = find.byType(TextField).first;
      await tester.enterText(field, '14');
      await tester.pump();
      final fieldState = tester.state(field);
      await store.flush();
      final before = journal();

      for (final spec in [KAccentSpec.forest, KAccentSpec.neon]) {
        store.settings.accent = spec.id;
        store.saveSettings();
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(SessionScreen)), same(session));
        expect(tester.state(find.byType(TextField).first), same(fieldState));
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: field, matching: find.byType(EditableText)),
              )
              .controller
              .text,
          '14',
        );
        expect(
          Theme.of(
            tester.element(find.byType(SessionScreen)),
          ).colorScheme.primary,
          KPalette(true, spec).accent,
        );
        // Composant qui lit la palette sans dépendre du thème, dans une
        // route empilée : il est bien redessiné.
        final dots = find.byType(SessionProgressDots);
        if (dots.evaluate().isNotEmpty) {
          expect(
            tester.widget<SessionProgressDots>(dots.first).color,
            KPalette(true, spec).action,
          );
        }
      }
      await store.flush();
      expect(journal(), before, reason: 'aucune performance créée');
      expect(store.settings.theme, 'dark');

      appNavigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomeScreen)), same(home));
      expect(find.text(week!), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'mode Système : la luminosité suit le téléphone, pas la couleur',
    (tester) async {
      screen(tester, const Size(390, 844));
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      store.settings
        ..theme = 'system'
        ..accent = 'solar';
      store.saveSettings();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      final home = tester.state(find.byType(HomeScreen));
      ThemeData theme() => Theme.of(tester.element(find.byType(HomeScreen)));
      expect(theme().brightness, Brightness.dark);
      expect(
        theme().colorScheme.primary,
        const KPalette(true, KAccentSpec.solar).accent,
      );
      expect(SL.dark, isTrue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(theme().brightness, Brightness.light);
      expect(
        theme().colorScheme.primary,
        const KPalette(false, KAccentSpec.solar).accent,
      );
      expect(SL.dark, isFalse);
      expect(SL.accentSpec, same(KAccentSpec.solar));
      expect(store.settings.accent, 'solar');
      expect(store.settings.theme, 'system');
      expect(tester.state(find.byType(HomeScreen)), same(home));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'les huit palettes × clair/sombre : accueil et réglages sans erreur',
    (tester) async {
      screen(tester, const Size(360, 780));
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      for (final spec in KAccentSpec.all) {
        for (final theme in ['dark', 'light']) {
          store.settings
            ..theme = theme
            ..accent = spec.id;
          store.saveSettings();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('nav-2')));
          await tester.pumpAndSettle();
          final t = Theme.of(tester.element(find.byType(HomeScreen)));
          final p = KPalette(theme == 'dark', spec);
          expect(t.colorScheme.primary, p.accent);
          expect(SL.accentSpec, same(spec));
          await tester.tap(find.byKey(const ValueKey('nav-3')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('accent-check-${spec.id}')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: '${spec.id} $theme');
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('interrupteur « Contraste renforcé » : appliqué tout de suite', (
    tester,
  ) async {
    screen(tester, const Size(390, 844));
    await tester.pumpWidget(const SLApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    final row = find.text('Contraste renforcé');
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(store.settings.contrast, isTrue);
    expect(store.contrastMode.value, isTrue);
    expect(SL.contrast, isTrue);
    final t = Theme.of(tester.element(row));
    expect(t.extension<KTokens>()!.contrast, isTrue);
    expect(
      t.colorScheme.primary,
      KRoles.of('bordeaux', dark: true, contrast: true).encre,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(store.settings.contrast, isFalse);
    expect(SL.contrast, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
