// L5 — Rendus Flutter de test des principaux écrans (clair/sombre), écrits
// pour tourner à l'identique sur la base 3.0.1 et sur la version L5 :
// même fixture, même taille (390 × 844, et 320 × 720 à 200 % pour
// PROGRAMME), même texte, rouge par défaut. Rendu d'un widget dans le
// moteur de test : ni capture de l'APK, ni essai sur téléphone.
// Désactivé sans --dart-define=KALIS_CAPTURE=true.
//
// Données synthétiques : journal simulé créé uniquement dans ce test.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/builder_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/program_start.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_screen.dart';

import 'support/capture_support.dart';

const _tag = String.fromEnvironment('KALIS_CAPTURE_TAG', defaultValue: 'apres');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('principaux écrans : rendus comparables avant / après L5', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    store.program.start = DateTime(2026, 7, 13);
    final done = DateTime(2026, 9, 21, 18);
    for (final (week, day) in [(11, 1), (11, 2), (11, 4)]) {
      store.sessionLog(week, day)
        ..done = true
        ..title = 'S$week · ${store.program.week(week).day(day)!.title}'
        ..finishedAt = done.add(Duration(days: day)).toIso8601String();
      for (final exercise
          in store.program.week(week).day(day)!.exercises.take(4)) {
        for (final set in store.exLog(week, day, exercise).sets) {
          set
            ..done = true
            ..kg = '15'
            ..reps = '6'
            ..completedAt = done.toIso8601String();
        }
      }
    }
    final wod = Wod(
      id: 'capture_wod',
      name: 'Push & Pull',
      type: 'amrap',
      minutes: 12,
      lines: ['5 tractions', '10 pompes', '15 squats'],
    );
    store.upsertWod(wod);
    store.notifyListeners();
    await loadCaptureFonts();
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    var serial = 0;
    Future<void> show(
      Widget home,
      bool dark, {
      Size size = const Size(390, 844),
      double text = 1,
    }) async {
      tester.view.physicalSize = size;
      store.settings.theme = dark ? 'dark' : 'light';
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            key: ValueKey(serial++),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(text)),
              child: child!,
            ),
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await precacheCaptureImages(tester);
    }

    // WOD du catalogue non acquis, le plus cher (crédits insuffisants si
    // possible ; sinon fiche d'achat).
    final catalog = [
      for (final w in store.wods)
        if (store.isCatalog(w) && !store.unlocked(w)) w,
    ]..sort((a, b) => store.wodCost(b).compareTo(store.wodCost(a)));
    final locked = catalog.first.id;
    final pages = <String, Widget>{
      'stats_apercu': const StatsScreen(),
      'stats_parcours': const StatsScreen(initialSection: StatsSection.journey),
      'stats_performances': const StatsScreen(
        initialSection: StatsSection.performance,
      ),
      'stats_historique': const StatsScreen(
        initialSection: StatsSection.history,
      ),
      'historique_seance': SessionHistoryScreen(
        log: store.sessionLog(11, 1),
        week: store.program.week(11),
        day: store.program.week(11).day(1),
      ),
      'editeur_seance': SessionEditor(
        session: CustomSession(id: 'capture_session', name: 'Haut du corps'),
      ),
      'catalogue_wod': const WodCatalogScreen(),
      'fiche_wod_acquis': WodPreviewScreen(wodId: wod.id),
      'fiche_wod_verrouille': WodPreviewScreen(wodId: locked),
      'chrono_wod': WodRunScreen(wodId: wod.id),
      'references': const PilotageScreen(),
      'depart_programme': ProgramStartScreen(
        initialDate: DateTime(2026, 7, 13),
      ),
      'reglages_chronometres': const SettingsScreen(section: 2),
    };
    for (final dark in [true, false]) {
      final mode = dark ? 'sombre' : 'clair';
      for (final page in pages.entries) {
        await show(page.value, dark);
        final error = tester.takeException();
        if (captureEnabled) {
          await savePng(
            tester,
            boundary,
            '${_tag}_${page.key}_$mode${error == null ? '' : '_ERREUR'}',
          );
        }
        if (error != null) {
          debugPrint('ERREUR ${page.key} $mode : $error');
        }
      }
      await show(
        RootNav(referenceDate: DateTime(2026, 9, 30, 9)),
        dark,
        size: const Size(320, 720),
        text: 2,
      );
      final error = tester.takeException();
      if (captureEnabled) {
        await savePng(
          tester,
          boundary,
          '${_tag}_programme_320_200pct_$mode${error == null ? '' : '_ERREUR'}',
        );
      }
      if (error != null) {
        debugPrint('ERREUR programme 320 200 % $mode : $error');
      }
    }
    // Petits écrans et grand texte : 320 × 720 à 200 %, mode sombre.
    final week = store.program.week(12);
    final compact = <String, Widget>{
      'seance': SessionScreen(week: week, day: week.day(4)!),
      'reglages': const SettingsScreen(),
      ...pages,
    };
    for (final page in compact.entries) {
      await show(page.value, true, size: const Size(320, 720), text: 2);
      final error = tester.takeException();
      if (captureEnabled) {
        await savePng(
          tester,
          boundary,
          '${_tag}_320_200pct_${page.key}${error == null ? '' : '_ERREUR'}',
        );
      }
      if (error != null) {
        debugPrint('ERREUR ${page.key} 320 200 % : $error');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }, skip: !captureEnabled);
}
