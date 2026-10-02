import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/notification_settings.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/quest/progression_view.dart';
import 'package:streetlift_tracker/store.dart';
import 'support/fake_notifications.dart';

Widget page(Widget child, {bool dark = true}) => MaterialApp(
  theme: buildTheme(dark),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(1.3)),
    child: child!,
  ),
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });
  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('la pastille ouvre la progression depuis l’accueil', (
    tester,
  ) async {
    await tester.pumpWidget(page(const HomeScreen()));
    await tester.tap(find.byTooltip('Ouvrir ma progression'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgressionScreen), findsOneWidget);
    expect(find.text('STATS'), findsOneWidget);
    expect(find.byKey(const ValueKey('progression-level')), findsOneWidget);
    expect(tester.takeException(), null);
  });
  for (final dark in [true, false]) {
    testWidgets(
      'G12 : progression lisible à 320 px avec texte agrandi, thème $dark',
      (tester) async {
        narrow(tester);
        await tester.pumpWidget(page(const ProgressionScreen(), dark: dark));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('progression-level')), findsOneWidget);
        final scroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('stats-progression-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        for (var i = 0; i < 6; i++) {
          await tester.drag(scroll, const Offset(0, -420));
          await tester.pumpAndSettle();
          expect(tester.takeException(), null);
        }
        await tester.tap(find.byTooltip('Comprendre les XP'));
        await tester.pumpAndSettle();
        expect(find.text('Comment progresser'), findsOneWidget);
        expect(tester.takeException(), null);
      },
    );
  }
  testWidgets(
    'un canal désactivé est visible et propose le bon réglage Android',
    (tester) async {
      narrow(tester);
      store.settings.notifOn = true;
      final backend = FakeNotifications()..channelAllowed = false;
      final service = NotificationService(store, backend);
      await tester.pumpWidget(
        page(
          Scaffold(
            body: ListView(
              children: [NotificationSettingsPanel(service: service)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Canal « Rappel quotidien » désactivé'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ouvrir les réglages Android'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ouvrir les réglages Android'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );
  testWidgets('les rappels restent configurables sans boutons de test', (
    tester,
  ) async {
    narrow(tester);
    store.settings.notifOn = true;
    final backend = FakeNotifications()..exact = false;
    final service = NotificationService(store, backend);
    await tester.pumpWidget(
      page(
        Scaffold(
          body: ListView(
            children: [NotificationSettingsPanel(service: service)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Heure du rappel'), findsOneWidget);
    expect(find.text('Tester maintenant'), findsNothing);
    expect(find.textContaining('Test dans'), findsNothing);
    await tester.tap(find.text('Options Android'));
    await tester.pumpAndSettle();
    expect(find.text('Autoriser l’heure précise'), findsOneWidget);
    expect(backend.shown, 0);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    store.settings.notifOn = false;
  });
}
