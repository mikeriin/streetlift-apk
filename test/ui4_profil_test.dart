// UI4 (refonte UI) — Profil, Mes références, Notifications, Données
// (cahier §4.1, §4.3, §4.5, R3, R8, R9) : « Mes références » depuis le
// Profil, plus de rubrique « Mode assisté ou libre » dans le Profil,
// retraits et suppressions confirmés, effacement des références confirmé,
// import et suppression des données par sous-pages (mêmes résultats),
// mise en évidence d'une ligne des notifications.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/data_control.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/notification_settings.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';
import 'support/fake_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 12);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    rescheduleReminders = () async {};
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
    store.storeClock = DateTime.now;
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  /// Bouton qui lance un parcours avec un vrai BuildContext.
  Widget launcher(Future<void> Function(BuildContext) run) => Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => run(context),
          child: const Text('Lancer'),
        ),
      ),
    ),
  );

  Future<void> tap(WidgetTester tester, Finder f) async {
    await scrollToAction(tester, f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Finder key(String k) => find.byKey(ValueKey(k));

  String topTitle(WidgetTester tester) =>
      tester.widgetList<KTopBar>(find.byType(KTopBar)).last.title!;

  /// Profil v2 avec accord santé ; [yes] : une réponse « oui » (mode
  /// prudent levable par l'accord du médecin).
  void seedProfile({bool yes = false}) {
    final d = ProfileDraft.of(sampleAthleteProfile(on: civilOf(now)))
      ..consent = 'given';
    d.answers.addAll({for (final q in kHealthQuestions) q.id: false});
    if (yes) d.answers[kHealthQuestions.first.id] = true;
    store.saveAthleteProfile(d);
  }

  group('Profil', () {
    test('rubriques : toutes celles du parcours sauf le mode', () {
      expect(profileRubrics, isNot(contains('mode')));
      expect(
        profileRubrics.toSet(),
        kRubricTitles.keys.toSet()..remove('mode'),
      );
    });

    testWidgets('« Mes références » ouvre la page « Mes références » ; pas '
        'de rubrique « Mode assisté ou libre »', (tester) async {
      phone(tester);
      seedProfile();
      await tester.pumpWidget(page(const ProfileScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Profil');
      expect(key('profile-rubric-identity'), findsOneWidget);
      expect(key('profile-rubric-mode'), findsNothing);
      expect(find.text('Mode assisté ou libre'), findsNothing);
      expect(find.text('Mes références'), findsOneWidget);
      expect(
        find.text('Poids du corps, 1RM, maxima et accessoires'),
        findsOneWidget,
      );
      await tap(tester, key('profile-references'));
      expect(find.byType(PilotageScreen), findsOneWidget);
      expect(topTitle(tester), 'Mes références');
      expect(find.textContaining('Pilotage'), findsNothing);
      // Retour : on revient au Profil.
      await tester.tap(find.byTooltip('Retour').last);
      await tester.pumpAndSettle();
      expect(find.byType(PilotageScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans profil : création proposée, « Mes références » '
        'joignable', (tester) async {
      phone(tester);
      await tester.pumpWidget(page(const ProfileScreen()));
      await tester.pumpAndSettle();
      expect(key('profile-missing'), findsOneWidget);
      expect(find.text('Créer mon profil'), findsOneWidget);
      expect(key('profile-references'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retrait de l’accord déclaré et suppression des réponses '
        'de santé : confirmés, « Annuler » ne change rien', (tester) async {
      phone(tester);
      seedProfile(yes: true);
      store.declareDoctorClearance();
      expect(store.caution.cleared, isTrue);
      await tester.pumpWidget(page(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Retirer l'accord déclaré.
      await tap(tester, key('profile-clearance-remove'));
      expect(find.byType(KConfirm), findsOneWidget);
      expect(find.text('Retirer l’accord déclaré ?'), findsOneWidget);
      await tap(tester, key('confirm-cancel'));
      expect(store.caution.cleared, isTrue);
      expect(store.profile!.health.clearanceAt, isNotNull);
      await tap(tester, key('profile-clearance-remove'));
      await tap(tester, key('confirm-ok'));
      expect(store.caution.cleared, isFalse);
      expect(store.profile!.health.clearanceAt, isNull);

      // L'accord du médecin se déclare par la même confirmation.
      await tap(tester, key('profile-clearance'));
      expect(find.text('Accord du médecin'), findsOneWidget);
      await tap(tester, key('confirm-ok'));
      expect(store.caution.cleared, isTrue);

      // Supprimer mes réponses de santé.
      await tap(tester, key('profile-health-delete'));
      expect(find.text('Supprimer tes réponses de santé ?'), findsOneWidget);
      await tap(tester, key('confirm-cancel'));
      expect(store.profile!.health.answers, isNotEmpty);
      await tap(tester, key('profile-health-delete'));
      await tap(tester, key('confirm-ok'));
      expect(store.profile!.health.answers, isEmpty);
      expect(store.profile!.health.consent, 'given');

      // Retirer mon accord : même confirmation, effet inchangé.
      await tap(tester, key('profile-consent-withdraw'));
      expect(find.text('Retirer ton accord ?'), findsOneWidget);
      await tap(tester, key('confirm-cancel'));
      expect(store.profile!.health.consent, 'given');
      await tap(tester, key('profile-consent-withdraw'));
      await tap(tester, key('confirm-ok'));
      expect(store.profile!.health.consent, 'withdrawn');
      expect(tester.takeException(), isNull);
    });
  });

  group('Mes références', () {
    testWidgets('effacer toutes mes références : action visible, confirmée', (
      tester,
    ) async {
      phone(tester);
      store.setValue('B4', 77);
      expect(store.refProvenance('B4'), 'set');
      await tester.pumpWidget(page(const PilotageScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Mes références');
      await tap(tester, key('references-reset'));
      expect(find.text('Effacer tes références ?'), findsOneWidget);
      await tap(tester, key('confirm-cancel'));
      expect(store.refProvenance('B4'), 'set');
      expect(store.values['B4'], 77);
      await tap(tester, key('references-reset'));
      await tap(tester, key('confirm-ok'));
      expect(store.refProvenance('B4'), 'unknown');
      expect(tester.takeException(), isNull);
    });
  });

  group('Données', () {
    testWidgets('import par la sous-page : annuler ne change rien, '
        'remplacer importe', (tester) async {
      phone(tester);
      final raw = jsonEncode(backupOf(store)..['pilotage'] = {'B4': 66});
      final before = store.exportAll();
      await tester.pumpWidget(
        page(launcher((c) => confirmAndImport(c, raw, appVersion: 'test'))),
      );
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      expect(find.byType(ImportPreviewDialog), findsOneWidget);
      expect(topTitle(tester), 'Importer une sauvegarde');
      expect(find.text('Sauvegarder puis remplacer'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(ImportPreviewDialog), findsNothing);
      expect(find.textContaining('Import annulé'), findsOneWidget);
      expect(store.exportAll(), before);

      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.text(
          'Sauvegarder d’abord mes données actuelles dans un fichier '
          '(recommandé)',
        ),
      );
      expect(find.text('Remplacer sans sauvegarde'), findsOneWidget);
      await tester.tap(find.text('Remplacer sans sauvegarde'));
      await tester.pumpAndSettle();
      expect(store.values['B4'], 66);
      expect(find.textContaining('Import réussi'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('mot de confirmation : même règle qu’avant (casse ignorée)', () {
      expect(eraseWordMatches('SUPPRIMER'), isTrue);
      expect(eraseWordMatches('  supprimer '), isTrue);
      expect(eraseWordMatches('Supprimer'), isTrue);
      expect(eraseWordMatches('supprime'), isFalse);
      expect(eraseWordMatches(''), isFalse);
    });

    testWidgets('suppression par la sous-page : mot exigé, puis effacement', (
      tester,
    ) async {
      phone(tester);
      store.setValue('B4', 77);
      EraseStatus? result;
      await tester.pumpWidget(
        page(
          launcher(
            (c) async => result = await eraseAppData(c, appVersion: 'test'),
          ),
        ),
      );
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      expect(find.byType(EraseDataDialog), findsOneWidget);
      expect(topTitle(tester), 'Supprimer les données de l’application');
      expect(find.textContaining('Pilotage'), findsNothing);
      // Retour : rien n'est supprimé.
      await tester.tap(find.byTooltip('Retour').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Suppression annulée'), findsOneWidget);
      expect(store.refProvenance('B4'), 'set');

      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      await tap(
        tester,
        find.text('Exporter d’abord une sauvegarde (recommandé)'),
      );
      final erase = find.widgetWithText(FilledButton, 'Supprimer');
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await scrollToAction(tester, key('erase-word'));
      await tester.enterText(key('erase-word'), 'supprime');
      await tester.pump();
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await tester.enterText(key('erase-word'), 'supprimer');
      await tester.pump();
      expect(tester.widget<FilledButton>(erase).onPressed, isNotNull);
      await tester.tap(erase);
      await tester.pumpAndSettle();
      expect(result, EraseStatus.success);
      expect(store.refProvenance('B4'), isNot('set'));
      expect(
        find.textContaining('revenue à son état d’installation'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Notifications', () {
    for (final (target, rowKey) in [
      ('reminder', 'notif-reminder'),
      ('reminder-time', 'notif-reminder-time'),
    ]) {
      testWidgets('NotificationSettingsPanel(highlight: $target) se '
          'construit et met la ligne en évidence', (tester) async {
        phone(tester);
        store.settings.notifOn = true;
        final service = NotificationService(store, FakeNotifications());
        await tester.pumpWidget(
          page(
            Scaffold(
              body: ListView(
                children: [
                  NotificationSettingsPanel(
                    service: service,
                    highlight: target,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Rappels de séance'), findsOneWidget);
        expect(find.text('Heure du rappel'), findsOneWidget);
        expect(find.text('Options Android'), findsOneWidget);
        final lit = tester.widget<KRowFrame>(
          find.descendant(of: key(rowKey), matching: find.byType(KRowFrame)),
        );
        expect(lit.highlight, isTrue);
        final other = rowKey == 'notif-reminder'
            ? 'notif-reminder-time'
            : 'notif-reminder';
        expect(
          tester
              .widget<KRowFrame>(
                find.descendant(
                  of: key(other),
                  matching: find.byType(KRowFrame),
                ),
              )
              .highlight,
          isFalse,
        );
        // La mise en évidence s'éteint après 1,5 s.
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        store.settings.notifOn = false;
      });
    }
  });
}
