// G1 correction 1 — retour du propriétaire (01/10/2026) : « Fermer
// entièrement l'app pendant [le démarrage] fait recommencer à la toute
// première question. » Le brouillon du démarrage (étape et réponses) est
// gardé et repris ; effacé à l'enregistrement du profil ; jamais gardé
// pour un âge de moins de 18 ans ; propre à la session.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/profile_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });
  setUp(() async {
    await store.eraseAllData();
    store.storeClock = () => DateTime(2026, 10, 1, 12);
  });
  tearDown(() => store.storeClock = DateTime.now);

  Widget page() => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ProfileFlow(onDone: () {}),
  );

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await scrollToAction(tester, f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Fermeture de l'application : l'écran disparaît sans enregistrement.
  Future<void> kill(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('fermer pendant le démarrage : reprise à la même étape, '
      'réponses gardées', (tester) async {
    phone(tester);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tap(tester, 'flow-next-welcome');
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '1990');
    await tester.pumpAndSettle();
    await tap(tester, 'flow-next-age');
    await tap(tester, 'flow-next-goals');
    await tap(tester, 'flow-day-1');
    await tap(tester, 'flow-day-3');
    await tap(tester, 'flow-minutes-45');
    // Passage en arrière-plan sur l'étape en cours (disponibilités).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await kill(tester);
    expect(store.profileFlowDraft, isNotNull);

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-availability')), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-welcome')), findsNothing);
    await tap(tester, 'flow-next-availability'); // jours et durée repris
    expect(find.byKey(const ValueKey('flow-places')), findsOneWidget);
    await kill(tester);

    // Reprise à l'étape suivante, puis fin du démarrage : brouillon effacé.
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-places')), findsOneWidget);
    await tap(tester, 'flow-place-park');
    await tap(tester, 'flow-next-places');
    await tap(tester, 'flow-bench-pushups-1');
    await tap(tester, 'flow-next-level');
    await tap(tester, 'flow-consent-refused');
    await tap(tester, 'flow-next-health');
    await tap(tester, 'flow-next-mode');
    await tap(tester, 'flow-next-recap');
    final p = store.profile!;
    expect(p.intValue('birthYear'), 1990);
    expect((p.value('days') as List).cast<int>(), [1, 3]);
    expect(p.intValue('sessionMinutes'), 45);
    await tester.pumpAndSettle();
    expect(store.profileFlowDraft, isNull);
  });

  testWidgets('moins de 18 ans : aucun brouillon gardé', (tester) async {
    phone(tester);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tap(tester, 'flow-next-welcome');
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '2015');
    await tester.pumpAndSettle();
    await tap(tester, 'flow-next-age');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await kill(tester);
    expect(store.profileFlowDraft, isNull);
  });

  testWidgets('brouillon hors sauvegarde, effacé avec les données', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tap(tester, 'flow-next-welcome');
    await kill(tester);
    expect(store.profileFlowDraft, isNotNull);
    expect(store.exportAll(), isNot(contains('profile_flow_draft')));
    final raw = await SharedPreferences.getInstance();
    expect(
      KalisPrefs(raw, dev: false).getKeys(),
      contains('profile_flow_draft_v1'),
    );
    await store.eraseAllData();
    expect(store.profileFlowDraft, isNull);
  });
}
