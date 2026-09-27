// L13 — écrans : santé et sécurité, récupération, politique de
// confidentialité, retour de test, avertissement au démarrage et dans
// « À propos », blocage d'un profil de moins de 18 ans.
// Fenêtres de téléphone (390 × 844, 320 × 720), texte 100 / 130 / 200 %,
// thèmes clair et sombre, défilement par gestes réels.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/profile_screens.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'phone_test_support.dart';

/// Défilement réel et lent (gestes chronométrés, sans élan) de la liste
/// principale jusqu'à ce que [target] soit touchable. Les cartes de ce lot
/// sont hautes à 200 % : un geste rapide (élan) pourrait les sauter.
Future<void> reach(WidgetTester tester, Finder target, {bool up = false}) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 80 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.timedDrag(
      list,
      Offset(0, up ? 150 : -150),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget, reason: 'Atteint par défilement');
}

/// Laisse le chargement réel de l'asset (politique) se terminer.
Future<void> settleAsset(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 20 && ready.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(ready, findsOneWidget);
}

const _at = '2026-09-27T10:00:00';

UserProfile _profile({int birthYear = 1990}) {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.health
    ..consent = 'given'
    ..consentAt = _at
    ..answeredAt = _at
    ..answers.addAll({for (final q in kHealthQuestions) q.id: false});
  p.setField('birthYear', birthYear, _at);
  p.setField('goalPrimary', 'health', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', {
    'park': ['pullup_bar'],
  }, _at);
  p.setField('benchmarks', {'pushups': 2}, _at);
  p.setField('autonomy', 'assisted', _at);
  p.setField('tone', 'neutral', _at);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 27, 12);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });
  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.storeClock = () => now;
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    FeedbackChannel.debugHook = null;
  });
  tearDown(() {
    store.storeClock = DateTime.now;
    FeedbackChannel.debugHook = null;
  });

  Widget page(Widget child, {double scale = 1, bool dark = true}) =>
      MaterialApp(
        theme: buildTheme(dark),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: child,
      );

  for (final (size, scale, dark) in [
    (const Size(390, 844), 1.0, true),
    (const Size(320, 720), 1.3, false),
    (const Size(320, 720), 2.0, true),
  ]) {
    testWidgets('santé et sécurité lisible ${size.width.toInt()} px, '
        'texte ${(scale * 100).round()} %', (tester) async {
      phone(tester, size: size);
      await tester.pumpWidget(
        page(const SafetyScreen(), scale: scale, dark: dark),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('safety-alert')), findsOneWidget);
      expect(find.textContaining('poitrine'), findsWidgets);
      await reach(
        tester,
        find.byKey(const ValueKey('safety-situation-age65')),
      );
      await reach(
        tester,
        find.byKey(const ValueKey('wellness-disclaimer')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('récupération et confidentialité ${size.width.toInt()} px, '
        'texte ${(scale * 100).round()} %', (tester) async {
      phone(tester, size: size);
      await tester.pumpWidget(
        page(const RecoveryScreen(), scale: scale, dark: dark),
      );
      await tester.pumpAndSettle();
      await reach(
        tester,
        find.byKey(const ValueKey('recovery-listen')),
      );
      await tester.pumpWidget(
        page(const PrivacyPolicyScreen(), scale: scale, dark: dark),
      );
      await settleAsset(tester, find.byKey(const ValueKey('privacy-screen')));
      expect(find.byKey(const ValueKey('privacy-screen')), findsOneWidget);
      await reach(
        tester,
        find.textContaining('Un profil importé qui indique moins de 18 ans'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('douleur persistante : renvoi affiché dans Santé et sécurité', (
    tester,
  ) async {
    phone(tester);
    var t = DateTime(2026, 9, 1, 18);
    for (final key in ['S3-J1', 'S3-J3', 'S4-J1']) {
      store.logs[key] = SessionLog(done: true, finishedAt: t.toIso8601String());
      store.setKoachPain(key, 'dip', 5);
      t = t.add(const Duration(days: 2));
    }
    await tester.pumpWidget(page(const SafetyScreen()));
    await tester.pumpAndSettle();
    await reach(tester, find.byKey(const ValueKey('safety-referral')));
    expect(find.textContaining('professionnel de santé'), findsWidgets);
  });

  testWidgets('retour de test : aperçu exact, seules les données choisies', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    store.saveProfile(_profile());
    String? shared;
    FeedbackChannel.debugHook = (text) async {
      shared = text;
      return 'shared';
    };
    await tester.pumpWidget(page(const FeedbackScreen(appVersion: '4.3.0')));
    await tester.pumpAndSettle();
    // Formulaire vide : rien à partager.
    final share = find.byKey(const ValueKey('feedback-share'));
    await reach(tester, share);
    expect(tester.widget<ButtonStyleButton>(share).onPressed, isNull);
    await reach(
      tester,
      find.byKey(const ValueKey('feedback-blocked')),
      up: true,
    );
    await tester.enterText(
      find.byKey(const ValueKey('feedback-blocked')),
      'Le chrono coupe la musique',
    );
    await tester.pumpAndSettle();
    // Version décochée ; niveau et mode prudent non cochés par défaut.
    final version = find.byKey(const ValueKey('feedback-include-version'));
    await reach(tester, version);
    await tester.tap(version);
    await tester.pumpAndSettle();
    await reach(tester, share);
    await tester.tap(share);
    await tester.pumpAndSettle();
    expect(shared, isNotNull);
    expect(shared, contains('Ce qui bloque : Le chrono coupe la musique'));
    for (final absent in ['Version', 'Niveau', 'Mode prudent', 'Note :']) {
      expect(shared, isNot(contains(absent)), reason: absent);
    }
    // Aucune donnée d'entraînement, de poids ni de santé.
    expect(shared, isNot(contains('kg')));
    expect(shared, isNot(contains('santé')));
    // Rien n'est écrit par le formulaire.
    expect(tester.takeException(), isNull);
  });

  testWidgets('avertissement au démarrage (installation neuve)', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-welcome')), findsOneWidget);
    await reach(
      tester,
      find.byKey(const ValueKey('wellness-disclaimer')),
    );
    expect(find.textContaining('pas un dispositif médical'), findsOneWidget);
  });

  testWidgets('À propos : avertissement et quatre entrées L13', (tester) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(page(const SettingsScreen(section: 9), scale: 1.3));
    await tester.pumpAndSettle();
    for (final key in [
      'wellness-disclaimer',
      'about-safety',
      'about-recovery',
      'about-privacy',
      'about-feedback',
    ]) {
      await reach(tester, find.byKey(ValueKey(key)));
    }
    await reach(tester, find.byKey(const ValueKey('about-privacy')), up: true);
    await tester.tap(find.byKey(const ValueKey('about-privacy')));
    await settleAsset(tester, find.byKey(const ValueKey('privacy-screen')));
    expect(find.byKey(const ValueKey('privacy-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profil importé de moins de 18 ans : application bloquée', (
    tester,
  ) async {
    phone(tester);
    store.saveProfile(_profile(birthYear: 2012));
    await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('minor-gate')), findsOneWidget);
    expect(find.text('ACCUEIL'), findsNothing);
    // Correction de l'année : l'application s'ouvre.
    final p = store.profile!.copy()..setField('birthYear', 1990, _at);
    store.saveProfile(p);
    await tester.pumpAndSettle();
    expect(find.text('ACCUEIL'), findsOneWidget);
  });
}
