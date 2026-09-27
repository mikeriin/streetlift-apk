// L8 — écrans : démarrage court (KT-039), refus des moins de 18 ans,
// santé et consentement (KT-041, KT-042), confirmation d'une installation
// existante (KT-043), écran Profil, question progressive (KT-040).
// Fenêtres de téléphone réelles (390 × 844, 320 × 720), texte 100 / 130 /
// 200 %, thèmes clair et sombre, défilement par gestes.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/profile_screens.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 26, 12);

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

  /// Parcours complet du démarrage court avec les réponses les plus
  /// rapides. Renvoie (écrans, taps, saisies).
  Future<(int, int, int)> runOnboarding(WidgetTester tester) async {
    var taps = 0, entries = 0;
    final screens = <String>{};
    Future<void> tap(String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
      taps++;
    }

    void seen() {
      for (final s in kFlowSteps) {
        if (find.byKey(ValueKey('flow-$s')).evaluate().isNotEmpty) {
          screens.add(s);
        }
      }
    }

    seen();
    await tap('flow-next-welcome');
    seen();
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '1990');
    entries++;
    await tester.pumpAndSettle();
    await tap('flow-next-age');
    seen();
    expect(find.byKey(const ValueKey('flow-goal-health')), findsOneWidget);
    await tap('flow-next-goals'); // « Forme et santé » présélectionné
    seen();
    await tap('flow-day-1');
    await tap('flow-day-3');
    await tap('flow-day-5');
    await tap('flow-minutes-45');
    await tap('flow-next-availability');
    seen();
    await tap('flow-place-park');
    await tap('flow-next-places');
    seen();
    await tap('flow-bench-pushups-1');
    await tap('flow-next-level');
    seen();
    await tap('flow-consent-given');
    for (final q in kHealthQuestions) {
      await tap('flow-q-${q.id}-false');
    }
    await tap('flow-next-health');
    seen();
    await tap('flow-next-mode');
    seen();
    expect(find.byKey(const ValueKey('flow-recap')), findsOneWidget);
    await tap('flow-next-recap');
    return (screens.length, taps, entries);
  }

  testWidgets('démarrage court complet : 9 écrans, taps comptés, profil '
      'enregistré, accueil ensuite', (tester) async {
    phone(tester);
    expect(store.isFreshInstall, isTrue);
    await tester.pumpWidget(const SLApp(profileGate: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-welcome')), findsOneWidget);
    final (screens, taps, entries) = await runOnboarding(tester);
    expect(screens, kFlowSteps.length);
    // Mesure : 24 taps et 1 saisie avec 3 jours et 8 réponses de santé
    // (estimation ≈ 3 s par geste : environ 75 s, sous les 2 minutes).
    expect(taps, lessThanOrEqualTo(26));
    expect(entries, 1);
    // ignore: avoid_print
    print('L8 démarrage : $screens écrans, $taps taps, $entries saisie');
    expect(find.byType(RootNav), findsOneWidget);
    final p = store.profile!;
    expect(p.origin, 'onboarding');
    expect(p.intValue('birthYear'), 1990);
    expect(p.stringValue('goalPrimary'), 'health');
    expect(p.level, 'novice');
    expect(p.stringValue('autonomy'), 'guided');
    expect(p.stringValue('tone'), 'kind');
    expect(store.caution.active, isFalse);
    expect(p.events, hasLength(1));
    await store.flush();
    expect(jsonDecode(store.exportAll())['profile'], isNotNull);
  });

  testWidgets('moins de 18 ans : message neutre, aucune écriture', (
    tester,
  ) async {
    phone(tester);
    await store.flush();
    var writes = 0;
    store.debugWriteHook = (_) async {
      writes++;
      return true;
    };
    final prefs = await SharedPreferences.getInstance();
    final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
    await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flow-next-welcome')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '2012');
    await tester.enterText(find.byKey(const ValueKey('flow-weight')), '50');
    await tester.pumpAndSettle();
    await scrollToAction(tester, find.byKey(const ValueKey('flow-next-age')));
    await tester.tap(find.byKey(const ValueKey('flow-next-age')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('minor-message')), findsOneWidget);
    expect(find.textContaining('18 ans et plus'), findsOneWidget);
    // 18 ans cette année, pas encore fêtés : même refus.
    await tester.tap(find.byKey(const ValueKey('minor-back')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '2008');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flow-adult18-false')));
    await tester.pumpAndSettle();
    await scrollToAction(tester, find.byKey(const ValueKey('flow-next-age')));
    await tester.tap(find.byKey(const ValueKey('flow-next-age')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('minor-message')), findsOneWidget);
    // Attente au-delà du délai de sauvegarde (600 ms) : rien de demandé.
    await tester.pump(const Duration(seconds: 2));
    expect(store.hasUnsavedChanges, isFalse);
    expect(writes, 0);
    expect(store.profile, isNull);
    expect(store.koach.weighIns, isEmpty);
    expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
  });

  testWidgets('consentement refusé : mode prudent annoncé, sans santé', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
    await tester.pumpAndSettle();
    Future<void> tap(String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('flow-next-welcome');
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '1985');
    await tap('flow-next-age');
    await tap('flow-goal-strength');
    await tap('flow-next-goals');
    await tap('flow-day-2');
    await tap('flow-minutes-60');
    await tap('flow-next-availability');
    await tap('flow-place-gym');
    await tap('flow-next-places');
    await tap('flow-bench-pushups-3');
    await tap('flow-next-level');
    await tap('flow-consent-refused');
    expect(find.byKey(const ValueKey('flow-refused')), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-q-heart-false')), findsNothing);
    await tap('flow-next-health');
    // Repère avancé → Assisté + Exigeant par défaut.
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('flow-tone-demanding')))
          .selected,
      isTrue,
    );
    await tap('flow-next-mode');
    expect(find.text('Mode prudent activé'), findsOneWidget);
    await tap('flow-next-recap');
    expect(find.text('ACCUEIL'), findsOneWidget);
    expect(store.profile!.health.consent, 'refused');
    expect(store.caution.active, isTrue);
    expect(store.caution.reasons, contains('no_consent'));
  });

  testWidgets('installation existante : confirmation proposée, « Plus '
      'tard », puis confirmation sans rien modifier', (tester) async {
    phone(tester);
    store.program.start = DateTime(2026, 7, 13);
    store.startOrigin = 'migration';
    store.values['B19'] = 65;
    store.refStatus['B19'] = 'set';
    store.logs['S1-J1'] = SessionLog(
      done: true,
      finishedAt: '2026-07-13T18:00:00',
    );
    final before = jsonDecode(store.exportAll());
    expect(store.needsProfileConfirmation, isTrue);
    await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
    await tester.pumpAndSettle();
    expect(find.text('Ton profil est pré-rempli'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flow-later')));
    await tester.pumpAndSettle();
    expect(find.text('ACCUEIL'), findsOneWidget);
    expect(store.profile, isNull);
    // Réglages → Profil : confirmation à tout moment.
    await tester.pumpWidget(page(const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-create')));
    await tester.pumpAndSettle();
    Future<void> tap(String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    await tap('flow-next-welcome');
    await tester.enterText(find.byKey(const ValueKey('flow-year')), '1992');
    await tap('flow-next-age');
    expect(find.byKey(const ValueKey('flow-event')), findsOneWidget);
    await tap('flow-next-goals');
    await tap('flow-day-1');
    await tap('flow-minutes-90');
    await tap('flow-next-availability');
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('flow-place-park')))
          .selected,
      isTrue,
    );
    await tap('flow-next-places');
    await tap('flow-next-level');
    await tap('flow-consent-given');
    for (final q in kHealthQuestions) {
      await tap('flow-q-${q.id}-false');
    }
    await tap('flow-next-health');
    await tap('flow-next-mode');
    await tap('flow-next-recap');
    final p = store.profile!;
    expect(p.origin, 'migration');
    expect(p.fields['goalPrimary']!.source, 'estimated');
    expect(p.fields['benchmarks']!.source, 'measured');
    expect(p.fields['birthYear']!.source, 'declared');
    final after = jsonDecode(store.exportAll()) as Map<String, dynamic>;
    after.remove('profile');
    expect(jsonEncode(after), jsonEncode(before));
  });

  for (final (size, scale, dark) in const [
    (Size(320, 720), 2.0, false),
    (Size(320, 720), 1.3, true),
    (Size(390, 844), 2.0, true),
  ]) {
    testWidgets('chaque écran sans débordement : ${size.width.toInt()} px, '
        'texte ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'}', (
      tester,
    ) async {
      phone(tester, size: size);
      await tester.pumpWidget(
        page(
          const ProfileGate(child: Text('ACCUEIL')),
          scale: scale,
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        final f = find.byKey(ValueKey(key));
        await scrollToAction(tester, f);
        await tester.tap(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key);
      }

      await tap('flow-next-welcome');
      await tester.enterText(find.byKey(const ValueKey('flow-year')), '1958');
      await tester.pumpAndSettle();
      await tap('flow-next-age');
      await tap('flow-goal-event');
      await tap('flow-goal2-strength');
      await tap('flow-weight-plus');
      await tap('flow-event-date');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tap('flow-event-item-pullups_max');
      await tap('flow-next-goals');
      for (final d in [1, 2, 4, 6]) {
        await tap('flow-day-$d');
      }
      await tap('flow-minutes-120');
      await tap('flow-next-availability');
      await tap('flow-place-park');
      await tap('flow-place-gym');
      await tap('flow-equip-gym-rings');
      await tap('flow-next-places');
      await tap('flow-bench-pushups-4');
      await tap('flow-bench-pullups-4');
      await tap('flow-next-level');
      await tap('flow-consent-given');
      for (final q in kHealthQuestions) {
        await tap('flow-q-${q.id}-false');
      }
      await tap('flow-add-injury');
      // Feuille d'ajout : défilement par gestes dans la feuille.
      await tap('injury-zone-knee');
      await tap('injury-save');
      await tap('flow-next-health');
      await tap('flow-autonomy-expert');
      await tap('flow-next-mode');
      // Né en 1958 : 65 ans et plus → mode prudent.
      await scrollToAction(tester, find.text('Mode prudent activé'));
      await tap('flow-next-recap');
      expect(find.text('ACCUEIL'), findsOneWidget);
      expect(store.profile!.stringValue('autonomy'), 'expert');
      expect(store.caution.reasons, contains('age65'));
      // Écran Profil au même format.
      await tester.pumpWidget(
        page(const ProfileScreen(), scale: scale, dark: dark),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('profile-clearance')),
      );
    });
  }

  testWidgets('écran Profil : accord du médecin daté, retrait du '
      'consentement', (tester) async {
    phone(tester);
    final p =
        store.newProfileDraft()
          ..setField('birthYear', 1980, '2026-09-26T10:00:00')
          ..setField('autonomy', 'assisted', '2026-09-26T10:00:00')
          ..setField('tone', 'neutral', '2026-09-26T10:00:00');
    p.health
      ..consent = 'given'
      ..consentAt = '2026-09-26T10:00:00'
      ..answeredAt = '2026-09-26T10:00:00'
      ..answers.addAll({
        for (final q in kHealthQuestions) q.id: q.id == 'joint',
      });
    store.saveProfile(p);
    await tester.pumpWidget(page(const ProfileScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Mode prudent activé'), findsOneWidget);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('profile-clearance')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-clearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('clearance-confirm')));
    await tester.pumpAndSettle();
    expect(store.caution.active, isFalse);
    expect(store.profile!.health.clearanceAt, isNotNull);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('profile-consent-withdraw')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-consent-withdraw')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('withdraw-confirm')));
    await tester.pumpAndSettle();
    expect(store.profile!.health.consent, 'withdrawn');
    expect(store.profile!.health.hasHealthContent, isFalse);
    expect(store.caution.active, isTrue);
    expect(find.byKey(const ValueKey('profile-consent-give')), findsOneWidget);
  });

  testWidgets('question progressive : une question, enregistrer ou reporter', (
    tester,
  ) async {
    phone(tester);
    store.saveProfile(
      store.newProfileDraft()
        ..setField('birthYear', 1980, '2026-09-26T10:00:00'),
    );
    late BuildContext ctx;
    await tester.pumpWidget(
      page(
        Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: Text('APRÈS SÉANCE'));
          },
        ),
      ),
    );
    final q = store.progressiveQuestionFor('S2-J1')!;
    expect(q, 'experience');
    final done = showProgressiveQuestion(ctx, q, 'S2-J1');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progressive-question')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pq-6to24m')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pq-save')));
    await tester.pumpAndSettle();
    await done;
    expect(store.profile!.stringValue('experience'), '6to24m');
    expect(store.progressiveQuestionFor('S2-J1'), isNull);
    final next = store.progressiveQuestionFor('S2-J2')!;
    final later = showProgressiveQuestion(ctx, next, 'S2-J2');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pq-later')));
    await tester.pumpAndSettle();
    await later;
    expect(store.profile!.later.containsKey(next), isTrue);
  });
}
