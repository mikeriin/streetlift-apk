// UI4 (refonte UI) — captures des écrans de la zone (PIPELINE_UI.md §3) :
// Réglages (racine, recherche, 6 rubriques), Profil, Mes références,
// Arsenal (racine, recherche, bibliothèque, fiche, Anatomie), galerie de
// Koach, pages d'aide, départ du programme, tests guidés, parcours du profil,
// pages de données ; sombre et clair × `bordeaux` et `neon`, page entière
// (390 dp de large), et les écrans denses à 320 dp × 200 % de texte.
// Lancé par la CI avec --dart-define=KALIS_CAPTURE=true ; fichiers
// validation/UI/ui4_<écran>_<palette>_<thème>.png, recopiés dans
// ci-out/captures-ui/.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/arsenal_screen.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/data_control.dart';
import 'package:streetlift_tracker/engine3d.dart' show engine3DSupport;
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/guided_tests.dart';
import 'package:streetlift_tracker/koach/koach_gallery_screen.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/program_start.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
    final now = store.storeClock();
    await store.configureStart(DateTime(now.year, now.month, now.day - 20));
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(now.subtract(const Duration(days: 30))),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await loadUiFonts();
  });

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    required bool dark,
    required String palette,
    double width = 390,
    double height = 2200,
    double scale = 1,
    int settle = 20,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    store.settings.theme = dark ? 'dark' : 'light';
    store.settings.accent = palette;
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          key: UniqueKey(),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark, KAccentSpec.byId(palette)),
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
    for (var i = 0; i < settle; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    int settle = 20,
  }) async {
    for (var i = 0; i < settle; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final e = tester.takeException();
    expect(e, isNull, reason: name);
    await saveUiPng(tester, root, name, pixelRatio: 1.5);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) return;
    await tester.enterText(
      find.descendant(of: f.first, matching: find.byType(EditableText)).first,
      text,
    );
  }

  final screens = <String, Widget Function()>{
    'reglages': () => const SettingsScreen(),
    'reglages_apparence': () =>
        const SettingsScreen(page: SettingsPage.appearance),
    'reglages_seance': () => const SettingsScreen(page: SettingsPage.session),
    'reglages_notifications': () =>
        const SettingsScreen(page: SettingsPage.notifications),
    'reglages_progression': () =>
        const SettingsScreen(page: SettingsPage.progression),
    'reglages_donnees': () => const SettingsScreen(page: SettingsPage.data),
    'reglages_aide': () => const SettingsScreen(page: SettingsPage.about),
    'coller_sauvegarde': () => const PasteBackupPage(),
    'supprimer_donnees': () => const EraseDataDialog(),
    'profil': () => const ProfileScreen(),
    'mes_references': () => const PilotageScreen(),
    'arsenal': () => const ArsenalScreen(),
    'exercices': () => const ExerciseLibraryScreen(),
    'exercices_pectoraux': () =>
        const ExerciseLibraryScreen(muscleGroup: 'pectoraux'),
    'fiche': () => const ExerciseSheetScreen(id: 'mu-roue-abdominale-genoux'),
    'anatomie_pectoraux': () => const AnatomyScreen(initialGroup: 'pectoraux'),
    'galerie_koach': () => const KoachGalleryScreen(),
    'sante_securite': () => const SafetyScreen(),
    'recuperation': () => const RecoveryScreen(),
    'avis': () => const FeedbackScreen(appVersion: kAppVersion),
    'depart_programme': () => const ProgramStartScreen(),
    'tests_guides': () => const GuidedTestsScreen(),
    'parcours_profil': () => const AthleteProfileFlow(),
  };

  testWidgets(
    'UI4 : écrans de la zone × sombre, clair × bordeaux, neon',
    skip: !uiCaptureEnabled,
    (tester) async {
      for (final palette in ['bordeaux', 'neon']) {
        for (final dark in [true, false]) {
          final suffix = '${palette}_${dark ? 'sombre' : 'clair'}';
          for (final entry in screens.entries) {
            await show(tester, entry.value(), dark: dark, palette: palette);
            await shot(tester, 'ui4_${entry.key}_$suffix');
          }
          // Recherches (résultats).
          await show(
            tester,
            const SettingsScreen(),
            dark: dark,
            palette: palette,
          );
          await type(tester, 'settings-search', 'repos');
          await shot(tester, 'ui4_reglages_recherche_$suffix');
          await show(
            tester,
            const ArsenalScreen(),
            dark: dark,
            palette: palette,
          );
          await type(tester, 'arsenal-search', 'pector');
          await shot(tester, 'ui4_arsenal_recherche_$suffix');
          // Mise en évidence d'une ligne ouverte depuis la recherche.
          await show(
            tester,
            const SettingsScreen(page: SettingsPage.session, highlight: 'rest'),
            dark: dark,
            palette: palette,
            settle: 6,
          );
          // Pendant la mise en évidence (1,5 s) : ligne sur fond `haute`.
          await shot(
            tester,
            'ui4_reglages_seance_evidence_$suffix',
            settle: 0,
          );
          await tester.pump(const Duration(seconds: 2));
        }
      }
      store.settings
        ..theme = 'dark'
        ..accent = 'bordeaux';
    },
  );

  testWidgets(
    'UI4 : écrans denses à 320 dp et 200 % de texte',
    skip: !uiCaptureEnabled,
    (tester) async {
      for (final name in [
        'reglages',
        'reglages_apparence',
        'reglages_seance',
        'reglages_progression',
        'reglages_donnees',
        'profil',
        'mes_references',
        'arsenal',
        'parcours_profil',
        'depart_programme',
      ]) {
        await show(
          tester,
          screens[name]!(),
          dark: true,
          palette: 'bordeaux',
          width: 320,
          height: 4000,
          scale: 2,
        );
        await shot(tester, 'ui4_320_${name}_bordeaux_sombre');
      }
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
