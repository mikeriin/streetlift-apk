// UI2 (refonte UI, séance) — captures de la zone (PIPELINE_UI.md §3) :
// Bilan du jour, page d'exercice, série validée et barre de repos, menu ⋮,
// liste des exercices, consignes (« Voir la fiche »), détail du bilan
// ouvert sur la douleur, feuille de douleur, fin de séance, résumé de
// Koach, historique, récompenses, jour de repos ; sombre et clair,
// palettes `bordeaux` et `neon` ; 320 dp à 200 % de texte. Lancé par la CI
// avec --dart-define=KALIS_CAPTURE=true ; fichiers validation/UI/ui2_*.png
// recopiés dans ci-out/captures-ui/ (ignoré sans la variable). Chaque
// capture vérifie aussi qu'aucune exception ni aucun débordement ne
// survient.
//
// Données synthétiques : programme du propriétaire (fixture de test),
// journal simulé, horloge fixe.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_summary_screen.dart';
import 'package:streetlift_tracker/adapt/health_check.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/kit/kit.dart' show showKSnack;
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/rewards.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/ui_capture.dart';

/// Programme du propriétaire commencé le 13/07/2026, journal des 11
/// premières semaines ; « aujourd'hui » : lundi 28/09 (S12·J1).
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

const _reward = RewardSummary(
  heading: 'Séance validée',
  title: 'S12 · J1',
  xpBefore: 1180,
  xpAfter: 1320,
  levelBefore: 6,
  levelAfter: 7,
  rankBefore: 'Recrue',
  rankAfter: 'Recrue',
  lines: [
    RewardLine('Journée du programme', 100, 'base'),
    RewardLine('Objectif de séance atteint', 40, 'goal'),
  ],
  records: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();

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
      ..autoTimer = true;
    if (uiCaptureEnabled) await loadUiFonts();
  });

  /// Monte [home] dans le thème demandé.
  Future<void> show(
    WidgetTester tester,
    Widget home, {
    required bool dark,
    required String palette,
    double width = 390,
    double height = 844,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store.settings.theme = dark ? 'dark' : 'light';
    final spec = KAccentSpec.all.firstWhere((s) => s.id == palette);
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(dark, spec, false),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(
    WidgetTester tester,
    String name,
    bool dark,
    String palette, {
    String suffix = '',
  }) async {
    final error = tester.takeException();
    expect(
      error,
      isNull,
      reason: '$name $palette ${dark ? 'sombre' : 'clair'}',
    );
    if (!uiCaptureEnabled) return;
    await saveUiPng(
      tester,
      root,
      'ui2_${name}_${palette}_${dark ? 'sombre' : 'clair'}$suffix',
    );
  }

  /// Avance l'horloge des chronos sans attendre la fin des animations.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => store.flush());
  }

  for (final palette in ['bordeaux', 'neon']) {
    for (final dark in [true, false]) {
      final mode = '$palette ${dark ? 'sombre' : 'clair'}';

      testWidgets('séance : bilan, exercice, série, menus ($mode)', (
        tester,
      ) async {
        store.clearSession(12, 1);
        final week = store.program.week(12);
        final day = week.day(1)!;
        await show(
          tester,
          SessionScreen(week: week, day: day),
          dark: dark,
          palette: palette,
        );
        await shot(tester, 'bilan', dark, palette);

        // « Passer » : premier exercice.
        await tester.tap(find.byKey(const ValueKey('feel-skip')));
        await settle(tester);
        await shot(tester, 'exercice', dark, palette);

        // Menu ⋮ et liste des exercices.
        await tester.tap(find.byTooltip('Options de séance'));
        await settle(tester);
        await shot(tester, 'menu', dark, palette);
        await tester.tap(find.byKey(const ValueKey('sheet-close')));
        await settle(tester);
        await tester.tap(find.text('Exercices'));
        await settle(tester);
        await shot(tester, 'liste', dark, palette);
        await tester.tapAt(const Offset(10, 10));
        await settle(tester);

        // Consignes de l'exercice (ⓘ) avec « Voir la fiche ».
        final info = find.byTooltip('Consignes de l’exercice').first;
        await tester.tap(info);
        await settle(tester);
        await shot(tester, 'consignes', dark, palette);
        await tester.tap(find.byKey(const ValueKey('sheet-close')));
        await settle(tester);

        // Série 1 validée : ligne des flammes, barre de repos, Koach.
        final check = find.byTooltip('Valider la série 1').first;
        await tester.ensureVisible(check);
        await settle(tester);
        await tester.tap(check);
        await settle(tester);
        await shot(tester, 'serie_validee', dark, palette);

        // Message de Koach posé au-dessus de la barre de repos (C8).
        final ctx = tester.element(find.byType(PageView));
        showKSnack(
          ctx,
          message: 'Koach : série suivante dans 2 s',
          bottom: SessionBottomInset.of(ctx),
          actionLabel: 'Annuler',
          onAction: () {},
        );
        await settle(tester);
        await shot(tester, 'message_koach', dark, palette);
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
        await settle(tester);

        // Suppression de l'historique : confirmation (R8).
        await tester.tap(find.byTooltip('Options de séance'));
        await settle(tester);
        await tester.tap(find.text('Supprimer l’historique de cette séance'));
        await settle(tester);
        await shot(tester, 'confirmation', dark, palette);
        await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
        await settle(tester);

        // Fin de séance (dernière page).
        await tester.tap(find.text('Exercices'));
        await settle(tester);
        await tester.tap(find.text('Bilan de séance').last);
        await settle(tester);
        await shot(tester, 'fin', dark, palette);
        await close(tester);
        store.clearSession(12, 1);
      }, skip: !uiCaptureEnabled);

      testWidgets('bilan détaillé : douleur, feuille de zone ($mode)', (
        tester,
      ) async {
        await show(
          tester,
          const HealthDetailScreen(initial: kc.HealthCheck(), focusPain: true),
          dark: dark,
          palette: palette,
        );
        await shot(tester, 'douleur', dark, palette);
        final zone = find.byKey(
          ValueKey('pain-zone-${kc.BodyZone.values.first.code}'),
        );
        await tester.ensureVisible(zone);
        await tester.pumpAndSettle();
        await tester.tap(zone);
        await tester.pumpAndSettle();
        await shot(tester, 'feuille_douleur', dark, palette);
        await close(tester);
      }, skip: !uiCaptureEnabled);

      testWidgets('résumé de Koach, historique, récompenses ($mode)', (
        tester,
      ) async {
        final week = store.program.week(12);
        final day = week.day(1)!;
        await show(
          tester,
          AdaptSummaryScreen(week: week, base: day),
          dark: dark,
          palette: palette,
        );
        await shot(tester, 'resume_koach', dark, palette);

        final w11 = store.program.week(11);
        final key = [
          for (final d in w11.days)
            if (store.logs[store.sessionKey(11, d.j)]?.done ?? false) d,
        ].firstOrNull;
        if (key != null) {
          await show(
            tester,
            SessionHistoryScreen(
              log: store.logs[store.sessionKey(11, key.j)]!,
              week: w11,
              day: key,
            ),
            dark: dark,
            palette: palette,
          );
          await shot(tester, 'historique', dark, palette);
        }

        await show(
          tester,
          const RewardScreen(reward: _reward),
          dark: dark,
          palette: palette,
        );
        await tester.pump(const Duration(seconds: 6));
        await shot(tester, 'recompenses', dark, palette);

        final rest = [
          for (final w in [11, 12, 13])
            for (final d in store.program.week(w).days)
              if (d.exercises.isEmpty) (store.program.week(w), d),
        ].firstOrNull;
        if (rest != null) {
          await show(
            tester,
            SessionScreen(week: rest.$1, day: rest.$2),
            dark: dark,
            palette: palette,
          );
          await shot(tester, 'repos', dark, palette);
        }
        await close(tester);
      }, skip: !uiCaptureEnabled);
    }
  }

  testWidgets('320 dp à 200 % de texte : bilan, exercice, menu, fin', (
    tester,
  ) async {
    store.clearSession(12, 1);
    final week = store.program.week(12);
    final day = week.day(1)!;
    await show(
      tester,
      SessionScreen(week: week, day: day),
      dark: true,
      palette: 'bordeaux',
      width: 320,
      height: 720,
      scale: 2,
    );
    await shot(tester, 'bilan', true, 'bordeaux', suffix: '_320');
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('feel-skip')),
      find.byKey(const ValueKey('health-page')),
      const Offset(0, -200),
    );
    await settle(tester);
    await shot(tester, 'bilan_bas', true, 'bordeaux', suffix: '_320');
    await tester.tap(find.byKey(const ValueKey('feel-skip')));
    await settle(tester);
    await shot(tester, 'exercice', true, 'bordeaux', suffix: '_320');
    final check = find.byTooltip('Valider la série 1').first;
    await tester.ensureVisible(check);
    await settle(tester);
    await shot(tester, 'tableau', true, 'bordeaux', suffix: '_320');
    await tester.tap(check);
    await settle(tester);
    await shot(tester, 'serie_validee', true, 'bordeaux', suffix: '_320');
    await tester.tap(find.byTooltip('Options de séance'));
    await settle(tester);
    await shot(tester, 'menu', true, 'bordeaux', suffix: '_320');
    await close(tester);
    store.clearSession(12, 1);
  }, skip: !uiCaptureEnabled);

  testWidgets('360 × 760 : cinq séries visibles sans défilement', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPadding);
    final week = store.program.week(8);
    final day = week.day(1)!;
    store.clearSession(8, 1);
    await show(
      tester,
      SessionScreen(week: week, day: day),
      dark: true,
      palette: 'bordeaux',
      width: 360,
      height: 760,
    );
    final skip = find.byKey(const ValueKey('feel-skip'));
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip);
      await settle(tester);
    }
    await shot(tester, 'cinq_series', true, 'bordeaux', suffix: '_360');
    await close(tester);
    store.clearSession(8, 1);
  }, skip: !uiCaptureEnabled);

  testWidgets('chrono de mode : bouton et barre lancée', (tester) async {
    // Première page de la saison avec un chrono de mode (EMOM, AMRAP,
    // intervalles, tenue) ou une tenue chronométrée.
    (WeekPlan, DayPlan, int)? found;
    for (final w in [12, 13, 14, 15, 16]) {
      for (final d in store.program.week(w).days) {
        final groups = store.groups(d, week: w);
        for (var i = 0; i < groups.length && found == null; i++) {
          if (groups[i].any(
            (e) =>
                e.timer != null ||
                e.interval != null ||
                const {'emom', 'hold', 'duration'}.contains(
                  store.logSpec(e).kind,
                ),
          )) {
            found = (store.program.week(w), d, i);
          }
        }
      }
    }
    if (found == null) return;
    final (week, day, index) = found;
    store.clearSession(week.n, day.j);
    await show(
      tester,
      SessionScreen(week: week, day: day),
      dark: true,
      palette: 'bordeaux',
    );
    final skip = find.byKey(const ValueKey('feel-skip'));
    final bilan = skip.evaluate().isNotEmpty;
    await tester.tap(find.text('Exercices'));
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('list-item-${index + (bilan ? 1 : 0)}')));
    await settle(tester);
    await shot(tester, 'chrono_mode', true, 'bordeaux');
    final launch = find.textContaining('Lancer');
    final timer = find.byTooltip('Compte à rebours');
    if (launch.evaluate().isNotEmpty) {
      await tester.ensureVisible(launch.first);
      await settle(tester);
      await tester.tap(launch.first);
    } else if (timer.evaluate().isNotEmpty) {
      await tester.ensureVisible(timer.first);
      await settle(tester);
      await tester.tap(timer.first);
    }
    await settle(tester);
    await shot(tester, 'chrono_lance', true, 'bordeaux');
    await close(tester);
    store.clearSession(week.n, day.j);
  }, skip: !uiCaptureEnabled);
}
