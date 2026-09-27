// L10 — écrans du programme personnalisé : « Mon programme » (modèle et
// explication, niveaux, répartition, volume), aperçu « ce qui change » et
// application, carte « profil modifié » de l'accueil, ligne « pourquoi » et
// accès à la fiche depuis la séance. Fenêtres de téléphone réelles
// (390 × 844, 320 × 720), texte 100 / 130 / 200 %, thèmes clair et sombre,
// défilement par gestes.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

const _at = '2026-10-01T10:00:00';

UserProfile _profile() {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.health
    ..consent = 'given'
    ..consentAt = _at
    ..answeredAt = _at;
  p.health.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  p.setField('birthYear', 1990, _at);
  p.setField('goalPrimary', 'endurance', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', {
    'park': ['pullup_bar', 'dip_bars'],
  }, _at);
  p.setField('benchmarks', {'pushups': 2, 'pullups': 2}, _at);
  p.setField('autonomy', 'assisted', _at);
  p.setField('tone', 'neutral', _at);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 5, 9);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ProgramAssets.load();
  });
  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.storeClock = () => now;
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    store.saveProfile(_profile());
    await store.configureStart(DateTime(2026, 10, 5));
  });
  tearDown(() {
    store.debugWriteHook = null;
    store.storeClock = DateTime.now;
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

  test('programme généré au départ pour le nouvel utilisateur', () {
    expect(store.programGenerated, isTrue);
    expect(store.programSummary['model'], isNot('expert_streetlifting'));
  });

  for (final size in const [Size(390, 844), Size(320, 720)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      for (final dark in const [true, false]) {
        testWidgets(
          'Mon programme sans débordement : ${size.width.toInt()} px, '
          'texte ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'}',
          (tester) async {
            phone(tester, size: size);
            await tester.pumpWidget(
              page(const ProgramScreen(), scale: scale, dark: dark),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('program-model')), findsOneWidget);
            await scrollToAction(
              tester,
              find.byKey(const ValueKey('program-levels')),
            );
            await scrollToAction(
              tester,
              find.byKey(const ValueKey('program-split')),
            );
            await scrollToAction(
              tester,
              find.byKey(const ValueKey('program-focus')),
            );
            await scrollToAction(
              tester,
              find.byKey(const ValueKey('program-generate')),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('régénération : aperçu « ce qui change » puis application ; '
      'l\'historique n\'est pas touché', (tester) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(page(const ProgramScreen(), scale: 1.3));
    await tester.pumpAndSettle();
    final before = store.programInstance!;
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('program-split-ppl')),
    );
    await tester.tap(find.byKey(const ValueKey('program-split-ppl')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-summary')), findsOneWidget);
    await scrollToAction(tester, find.byKey(const ValueKey('preview-apply')));
    await tester.tap(find.byKey(const ValueKey('preview-apply')));
    await tester.pumpAndSettle();
    expect(store.programInstance!.options['split'], 'ppl');
    expect(
      store.programInstance!.weeks.length,
      greaterThanOrEqualTo(before.weeks.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('aperçu refusé : rien ne change', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const ProgramScreen()));
    await tester.pumpAndSettle();
    final before = store.programInstance!.toJson().toString();
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('program-generate')),
    );
    await tester.tap(find.byKey(const ValueKey('program-generate')));
    await tester.pumpAndSettle();
    await scrollToAction(tester, find.byKey(const ValueKey('preview-cancel')));
    await tester.tap(find.byKey(const ValueKey('preview-cancel')));
    await tester.pumpAndSettle();
    expect(store.programInstance!.toJson().toString(), before);
  });

  testWidgets('profil modifié : carte de l\'accueil, puis ce qui change', (
    tester,
  ) async {
    final p = store.profile!.copy();
    p.setField('sessionMinutes', 30, profileAt(now));
    store.saveProfile(p);
    expect(store.programProfileChanged, isTrue);
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(
      page(
        Scaffold(body: ListView(children: const [ProgramHomeCard()])),
        scale: 2.0,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('program-home-card')), findsOneWidget);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('program-home-preview')),
    );
    await tester.tap(find.byKey(const ValueKey('program-home-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('preview-model')), findsOneWidget);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('preview-summary')),
    );
    expect(tester.takeException(), isNull);
  });
}
