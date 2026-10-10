// UI4 (refonte UI, cahier §4.1 à §4.6) : racine des Réglages au gabarit
// « menu racine » (recherche, carte Profil, six rubriques), réglages à deux
// appuis au plus (R4), objectif de la semaine en segments (§4.3),
// suppression confirmée (R8), plus d'entrée Programme ni Références.
// Tests de widgets (moteur de test Flutter) : ils ne remplacent pas un essai
// sur téléphone. Données synthétiques.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/kit/kit.dart' show KSegmentedRow;
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/settings_search.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

/// Réponses des anciens questionnaires de Koach L7 (lecture seule depuis
/// G10), semées directement dans les données.
void _legacyAnswers() {
  store.koach.answers.putIfAbsent('S1-J1', SessionAnswers.new).pain['squat'] =
      2;
}

/// Laisse s'éteindre la mise en évidence (1,5 s) et les animations.
Finder _segment(Finder row, int value) =>
    find.descendant(of: row, matching: find.byKey(ValueKey('segment-$value')));

Future<void> _settleHighlight(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });
  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..notifOn = false;
  });

  test('durées au format C9 : secondes jusqu’à 90 s, minutes au-delà', () {
    expect(settingsSecondsLabel(0), '0 s');
    expect(settingsSecondsLabel(90), '90 s');
    expect(settingsSecondsLabel(105), '1 min 45');
    expect(settingsSecondsLabel(120), '2 min');
    expect(settingsSecondsLabel(150), '2 min 30');
    expect(settingsSecondsLabel(300), '5 min');
  });

  testWidgets('racine : recherche, carte Profil, six rubriques, rien d’autre', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('L’application à ta façon.'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-search')), findsOneWidget);
    expect(find.text('Rechercher un réglage'), findsOneWidget);
    // Carte Profil sans profil : « Mon profil », état « À créer ».
    final profile = find.byKey(const ValueKey('settings-profile'));
    expect(profile, findsOneWidget);
    expect(
      find.descendant(of: profile, matching: find.text('Mon profil')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: profile,
        matching: find.text(
          'Profil, mes références, tests guidés, santé · À créer',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Plus'), findsOneWidget);
    final tops = <double>[];
    for (final page in SettingsPage.values) {
      final row = find.byKey(ValueKey('settings-page-${page.name}'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: row, matching: find.text(page.title)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text(page.description)),
        findsOneWidget,
      );
      tops.add(tester.getTopLeft(row).dy);
    }
    // Ordre du cahier (§4.1) : Apparence, Séance, Notifications,
    // Progression et jeu, puis Données et confidentialité, Aide et à propos.
    expect(SettingsPage.values.map((p) => p.title).toList(), [
      'Apparence',
      'Séance',
      'Notifications',
      'Progression et jeu',
      'Données et confidentialité',
      'Aide et à propos',
    ]);
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]));
    }
    // Plus aucune entrée déplacée ni réglage en place sur la racine.
    for (final gone in [
      'Programme',
      'Mon programme',
      'Départ du programme',
      'Références',
      'Koach',
      'Affichage 3D',
      'Préférences',
      'Chronomètres',
      'Saisie des séries',
      'Pendant la séance',
      'Sauvegardes',
      'À propos',
      'Thème',
      'Contraste renforcé',
    ]) {
      expect(find.text(gone), findsNothing, reason: gone);
    }
    for (final key in [
      'settings-program',
      'settings-program-start',
      'accent-picker',
    ]) {
      expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
    }
    // La version ne s'écrit qu'une fois, dans Aide et à propos.
    expect(find.textContaining(kAppVersion), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carte Profil : prénom, initiale, ouvre le Profil', (
    tester,
  ) async {
    phone(tester);
    store.seedSampleAthleteProfile();
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    final profile = find.byKey(const ValueKey('settings-profile'));
    final name = store.athlete!.profile.displayName!;
    expect(
      find.descendant(of: profile, matching: find.text(name)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: profile, matching: find.text('G')),
      findsOneWidget,
    );
    expect(find.text('Mon profil'), findsNothing);
    await tester.tap(profile);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chaque réglage est à deux appuis au plus de la racine (R4)', (
    tester,
  ) async {
    phone(tester);
    store.settings.notifOn = true;
    _legacyAnswers();
    for (final entry in settingsSearchIndex) {
      final page = entry.page;
      if (page == null || !entry.isAvailable) continue;
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();
      // Appui 1 : la rubrique.
      final row = find.byKey(ValueKey('settings-page-${page.name}'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      // Le réglage est sur cette page : l'appui 2 le change.
      await scrollToAction(tester, find.text(entry.label).first);
      expect(find.text(entry.label), findsWidgets, reason: entry.id);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('les réglages simples s’appliquent tout de suite', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.session)),
    );
    await tester.pumpAndSettle();
    expect(find.text('SÉANCE'), findsOneWidget);
    for (final section in [
      'Chronomètres',
      'Fin du repos',
      'Saisie des séries',
      'Écran et unités',
    ]) {
      await scrollToAction(tester, find.text(section));
    }
    await scrollToAction(tester, find.text('Repos par défaut'), up: true);
    final rest = store.settings.defaultRest;
    await tester.tap(find.byTooltip('Augmenter Repos par défaut'));
    await tester.pumpAndSettle();
    expect(store.settings.defaultRest, rest + 15);
    expect(find.text(settingsSecondsLabel(rest + 15)), findsOneWidget);
    // §4.6 : description corrigée de la vibration.
    expect(
      find.textContaining('Fin de chrono, validation et records'),
      findsOneWidget,
    );
    await scrollToAction(tester, find.text('Charges suggérées en livres (lb)'));
    final lb = store.settings.lb;
    await tester.tap(find.text('Charges suggérées en livres (lb)'));
    await tester.pumpAndSettle();
    expect(store.settings.lb, !lb);
    store.settings
      ..defaultRest = rest
      ..lb = lb;
    expect(tester.takeException(), isNull);
  });

  testWidgets('objectif de la semaine : segments Adaptatif, 2 à 6 (§4.3)', (
    tester,
  ) async {
    phone(tester);
    store.settings.weeklyGoal = 1;
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.progression)),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('settings-weekly-goal'));
    expect(row, findsOneWidget);
    for (final v in kWeeklyGoalChoices) {
      expect(_segment(row, v), findsOneWidget, reason: '$v');
    }
    expect(_segment(row, 1), findsNothing);
    expect(find.text('Adaptatif'), findsOneWidget);
    // Une valeur 1 déjà enregistrée est affichée telle quelle, sans
    // migration : aucun segment choisi.
    expect(tester.widget<KSegmentedRow<int>>(row).selected, isNull);
    expect(find.text('Actuellement : 1 jour par semaine'), findsOneWidget);
    expect(store.settings.weeklyGoal, 1);
    await tester.tap(_segment(row, 4));
    await tester.pumpAndSettle();
    expect(store.settings.weeklyGoal, 4);
    expect(tester.widget<KSegmentedRow<int>>(row).selected, 4);
    expect(find.text('Cap personnel, sans XP'), findsOneWidget);
    await tester.tap(_segment(row, 0));
    await tester.pumpAndSettle();
    expect(store.settings.weeklyGoal, 0);
    expect(find.text('Adaptatif : moyenne récente + 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supprimer les anciennes réponses : confirmation destructive', (
    tester,
  ) async {
    phone(tester);
    _legacyAnswers();
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.data)),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('settings-delete-answers'));
    await scrollToAction(tester, row);
    expect(find.text('Zone sensible'), findsOneWidget);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer tes réponses ?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(store.koach.answers, isNotEmpty);
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-ok')));
    await tester.pumpAndSettle();
    expect(store.koach.answers, isEmpty);
    // La ligne disparaît avec les réponses ; l'effacement complet reste.
    expect(row, findsNothing);
    await scrollToAction(
      tester,
      find.text('Supprimer les données de l’application'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Données et confidentialité : textes et libellés sans jargon', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.data)),
    );
    await tester.pumpAndSettle();
    expect(find.text('DONNÉES ET CONFIDENTIALITÉ'), findsOneWidget);
    // R9 : plus de « pilotage ».
    expect(find.textContaining('pilotage'), findsNothing);
    expect(
      find.textContaining('références, journal, réglages'),
      findsOneWidget,
    );
    for (final label in [
      'Sauvegarde Android',
      'Confidentialité',
      'Politique de confidentialité',
      'Supprimer les données de l’application',
    ]) {
      await scrollToAction(tester, find.text(label));
    }
    expect(
      find.textContaining('Tout est calculé et conservé sur ce téléphone'),
      findsOneWidget,
    );
    // Sans anciennes données de Koach, pas de section à leur sujet.
    expect(find.text('Anciennes données de Koach'), findsNothing);
    expect(find.text('Ancien Koach et adaptations au quotidien'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Aide et à propos : version une fois, entrées de l’aide', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.about)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kalis Track $kAppVersion'), findsOneWidget);
    for (final key in [
      'about-safety',
      'about-explainer',
      'about-koach-gallery',
      'about-feedback',
      'about-licences',
      'about-engine3d',
    ]) {
      await scrollToAction(tester, find.byKey(ValueKey(key)));
    }
    expect(find.text('Diagnostic 3D'), findsOneWidget);
    expect(find.text('Moteur 3D'), findsNothing);
    // « Récupération » vit dans Santé et sécurité (plus de doublon).
    expect(find.byKey(const ValueKey('about-recovery')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coller une sauvegarde : sous-page, texte rendu à l’aperçu', (
    tester,
  ) async {
    phone(tester);
    String? pasted;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                pasted = await Navigator.push<String>(
                  context,
                  MaterialPageRoute<String>(
                    builder: (_) => const PasteBackupPage(),
                  ),
                );
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('COLLER UNE SAUVEGARDE'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('paste-field')),
      '  {"texte": 1}  ',
    );
    await tester.tap(find.byKey(const ValueKey('paste-preview')));
    await tester.pumpAndSettle();
    expect(pasted, '{"texte": 1}');
    expect(tester.takeException(), isNull);
  });

  testWidgets('mise en évidence : la ligne visée s’allume puis s’éteint', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      _app(const SettingsScreen(page: SettingsPage.data, highlight: 'erase')),
    );
    await tester.pumpAndSettle();
    final erase = find.text('Supprimer les données de l’application');
    expect(erase.hitTestable(), findsOneWidget, reason: 'amenée à l’écran');
    await _settleHighlight(tester);
    expect(tester.takeException(), isNull);
  });
}
