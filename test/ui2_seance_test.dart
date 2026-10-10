// UI2 (refonte UI, séance) — menus et parcours de la séance (cahier §4.1,
// §4.3, §4.6, §6.3) :
// - menu ⋮ en feuille d'actions, au contenu du §4.1, action destructrice
//   dans le dernier groupe et confirmée ;
// - « Douleur ou malaise ? » ouvre le Bilan du jour détaillé sur la section
//   Douleur (4 appuis jusqu'à la douleur enregistrée), avec « Conseils de
//   sécurité » ;
// - ⓘ › « Voir la fiche » (2 appuis) ; ⋮ › « Mes références » (2 appuis) ;
// - « J'ai seulement… minutes » garde l'exercice en cours (§4.6) ;
// - liste des exercices en feuille de liste.
// Données synthétiques : programme du propriétaire (fixture de test).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/health_check.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'l2_fixtures.dart';

Future<void> _ownerState(AppStore app) async {
  final filled = filledBackup(app);
  final logs = (filled['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    return w >= 12;
  });
  filled['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(filled)), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    store.storeClock = () => DateTime(2026, 9, 28, 9);
    await store.init();
    await _ownerState(store);
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(store.storeClock()),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// Séance S12·J1 ouverte, bilan passé : premier exercice affiché.
  Future<(WeekPlan, DayPlan)> open(WidgetTester tester) async {
    store.clearSession(12, 1);
    final week = store.program.week(12);
    final day = week.day(1)!;
    await tester.pumpWidget(page(SessionScreen(week: week, day: day)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feel-skip')));
    await tester.pumpAndSettle();
    return (week, day);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    store.clearSession(12, 1);
    await tester.runAsync(() => store.flush());
  }

  /// Appui compté (parcours du §6.3).
  var taps = 0;
  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
    taps++;
  }

  testWidgets('menu ⋮ : feuille d’actions au contenu du §4.1, suppression '
      'dans le dernier groupe, confirmée', (tester) async {
    phone(tester);
    await open(tester);
    await tester.tap(find.byTooltip('Options de séance'));
    await tester.pumpAndSettle();
    final sheet = find.byType(KActionSheet<String>);
    expect(sheet, findsOneWidget);
    final groups = tester.widget<KActionSheet<String>>(sheet).groups;
    expect(
      [
        for (final g in groups) [for (final a in g) a.label],
      ],
      [
        [
          if (store.program.week(12).day(1)!.conduite.isNotEmpty)
            'Consignes de séance',
          'Bilan du jour',
          'J’ai seulement… minutes',
          'Je m’entraîne ailleurs',
        ],
        ['Douleur ou malaise ?', 'Mes références'],
        ['Supprimer l’historique de cette séance'],
      ],
    );
    expect(groups.last.single.danger, isTrue);
    expect(
      groups.take(2).expand((g) => g).any((a) => a.danger),
      isFalse,
    );
    // Libellés internes retirés (R9).
    expect(find.textContaining('Pilotage'), findsNothing);
    expect(find.text('Effacer l’historique'), findsNothing);
    // Suppression : confirmation, « Annuler » ne supprime rien.
    store.exLog(12, 1, store.program.week(12).day(1)!.exercises.first);
    await tester.tap(find.text('Supprimer l’historique de cette séance'));
    await tester.pumpAndSettle();
    expect(find.byType(KConfirm), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Mes références depuis la séance : 2 appuis, même page', (
    tester,
  ) async {
    phone(tester);
    await open(tester);
    taps = 0;
    await tap(tester, find.byTooltip('Options de séance'));
    await tap(tester, find.text('Mes références'));
    expect(find.byType(PilotageScreen), findsOneWidget);
    expect(taps, 2);
    Navigator.of(tester.element(find.byType(PilotageScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    await close(tester);
  });

  testWidgets('fiche d’exercice pendant la séance : ⓘ › Voir la fiche (2)', (
    tester,
  ) async {
    phone(tester);
    await open(tester);
    taps = 0;
    await tap(tester, find.byTooltip('Consignes de l’exercice').first);
    final sheet = find.text('Voir la fiche');
    expect(sheet, findsOneWidget);
    await tap(tester, sheet);
    expect(find.byType(ExerciseSheetScreen), findsOneWidget);
    expect(taps, 2);
    // Retour : la séance, au même exercice.
    Navigator.of(tester.element(find.byType(ExerciseSheetScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text('Voir la fiche'), findsNothing);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('douleur pendant la séance : ⋮ › Douleur ou malaise ? › zone '
      '› Enregistrer (4 appuis), sur la section Douleur', (tester) async {
    phone(tester);
    await open(tester);
    taps = 0;
    await tap(tester, find.byTooltip('Options de séance'));
    await tap(tester, find.text('Douleur ou malaise ?'));
    expect(find.byType(HealthDetailScreen), findsOneWidget);
    // Ouvert sur la section Douleur : la carte est à l'écran.
    final pains = find.byKey(const ValueKey('detail-pains'));
    expect(pains.hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-safety')), findsOneWidget);
    final zone = kc.BodyZone.values.first;
    await tap(tester, find.byKey(ValueKey('pain-zone-${zone.code}')));
    expect(find.byKey(const ValueKey('pain-sheet')), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('pain-save')));
    expect(taps, 4);
    expect(find.byKey(ValueKey('pain-${zone.code}')), findsOneWidget);
    // « Conseils de sécurité » : la page de santé et sécurité.
    await tester.ensureVisible(find.byKey(const ValueKey('detail-safety')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-safety')));
    await tester.pumpAndSettle();
    expect(find.byType(SafetyScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SafetyScreen))).pop();
    await tester.pumpAndSettle();
    // Validé : la douleur passe au moteur, retour à la séance.
    await tester.ensureVisible(find.byKey(const ValueKey('detail-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-save')));
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    final check = store.sessionAdapt(12, 1)!.check!;
    expect(check.pains!.single.zone, zone);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('liste des exercices : feuille de liste, page courante '
      'cernée ; « J’ai seulement… minutes » garde l’exercice en cours', (
    tester,
  ) async {
    phone(tester);
    await open(tester);
    // Deuxième exercice par la liste.
    await tester.tap(find.text('Exercices'));
    await tester.pumpAndSettle();
    final list = find.byType(KListSheet);
    expect(list, findsOneWidget);
    final items = tester.widget<KListSheet>(list).items;
    expect(items.first.title, 'Bilan du jour');
    expect(items.last.title, 'Bilan de séance');
    expect(items[1].state, KListState.current);
    await tester.tap(find.byKey(const ValueKey('list-item-2')));
    await tester.pumpAndSettle();
    final title = items[2].title;
    // Temps disponible : la séance est recalculée, on reste sur la page
    // d'où l'on vient (et non sur le Bilan du jour).
    await tester.tap(find.byTooltip('Options de séance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J’ai seulement… minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 min'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthCheckPage), findsNothing);
    await tester.tap(find.text('Exercices'));
    await tester.pumpAndSettle();
    final after = tester.widget<KListSheet>(find.byType(KListSheet)).items;
    final current = after.indexWhere((i) => i.state == KListState.current);
    expect(current, greaterThan(0));
    if (after.any((i) => i.title == title)) {
      expect(after[current].title, title);
    }
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
