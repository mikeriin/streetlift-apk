// UI4 (refonte UI, cahier §4.4) : recherche des réglages. Chaque entrée de
// l'index est trouvée par son libellé et par ses mots proches ; chaque
// destination existe (la page s'ouvre et la ligne mise en évidence y est) ;
// « repos » trouve « Repos par défaut » en premier et l'ouvre en évidence ;
// aucun résultat : message et action (pas de cul-de-sac).
// Tests de widgets (moteur de test Flutter). Données synthétiques.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/guided_tests.dart';
import 'package:streetlift_tracker/kit/kit.dart' show KRowFrame;
import 'package:streetlift_tracker/koach/koach_gallery_screen.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/settings_search.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'phone_test_support.dart';

Widget _app(Widget home) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

/// Ligne mise en évidence (1,5 s) sur la page ouverte.
final _lit = find.byWidgetPredicate((w) => w is KRowFrame && w.highlight);

Future<void> _settleHighlight(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

/// Les entrées d'aide ou de destination et l'écran qu'elles ouvrent.
final _screens = <String, Finder>{
  'profile': find.byType(ProfileScreen),
  'references': find.byType(PilotageScreen),
  'guided-tests': find.byType(GuidedTestsScreen),
  'safety': find.byType(SafetyScreen),
  'recovery': find.byType(RecoveryScreen),
  'explainer': find.byKey(const ValueKey('program-explainer')),
  'koach-gallery': find.byType(KoachGalleryScreen),
  'feedback': find.byType(FeedbackScreen),
  'licences': find.byType(MentionsScreen),
  'diagnostic-3d': find.byType(Engine3DScreen),
};

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
      // Les lignes conditionnelles existent : heure du rappel, anciennes
      // réponses de Koach.
      ..notifOn = true;
    final answers = store.koach.answers.putIfAbsent(
      'S1-J1',
      SessionAnswers.new,
    );
    answers.pain['squat'] = 2;
  });

  test('l’index couvre chaque réglage et chaque page d’aide (§4.4)', () {
    final ids = [for (final e in settingsSearchIndex) e.id];
    expect(ids.toSet().length, ids.length, reason: 'identifiants uniques');
    expect(
      ids,
      containsAll([
        'theme', 'palette', 'contrast', 'muscle-names', 'halo', //
        'rest', 'ready', 'auto-rest', 'sound', 'vibration', //
        'velocity', 'prefill', 'wakelock', 'pounds', //
        'reminder', 'reminder-time', 'celebrations', 'weekly-goal', //
        'export', 'import', 'copy', 'paste', 'retired-copy', 'privacy', //
        'delete-answers', 'erase', //
        'profile', 'references', 'guided-tests', 'safety', 'recovery', //
        'explainer', 'koach-gallery', 'feedback', 'licences', //
        'diagnostic-3d',
      ]),
    );
    for (final e in settingsSearchIndex) {
      expect(e.words, isNotEmpty, reason: e.id);
      expect(e.path, isNotEmpty, reason: e.id);
      // Une destination : une page des Réglages, ou un écran.
      expect(e.page != null || _screens.containsKey(e.id), isTrue);
    }
  });

  test('chaque entrée est trouvée par son libellé et ses mots proches', () {
    for (final e in settingsSearchIndex) {
      if (!e.isAvailable) continue;
      expect(searchSettings(e.label), contains(e), reason: e.label);
      for (final w in e.words) {
        expect(searchSettings(w), contains(e), reason: '${e.id} : « $w »');
      }
    }
  });

  test('mots proches du cahier, sans accents ni majuscules', () {
    final pairs = <String, String>{
      'repos': 'rest',
      'récup': 'rest',
      'Pause': 'rest',
      'kg': 'pounds',
      'livres': 'pounds',
      'unité': 'pounds',
      'son': 'sound',
      'bip': 'sound',
      'vibration': 'vibration',
      'vibreur': 'vibration',
      'thème': 'theme',
      'SOMBRE': 'theme',
      'clair': 'theme',
      'couleur': 'palette',
      'palette': 'palette',
      'rappel': 'reminder',
      'notification': 'reminder',
      'sauvegarde': 'export',
      'export': 'export',
      'import': 'import',
      'profil': 'profile',
      'poids': 'profile',
      'taille': 'profile',
      'références': 'references',
      '1RM': 'references',
      'max': 'references',
    };
    for (final MapEntry(key: query, value: id) in pairs.entries) {
      expect(
        searchSettings(query).map((e) => e.id),
        contains(id),
        reason: '« $query » → $id',
      );
    }
    // Tous les mots sont requis.
    expect(searchSettings('repos son').map((e) => e.id).toList(), ['sound']);
    expect(searchSettings(''), isEmpty);
    expect(searchSettings('   '), isEmpty);
  });

  test('« repos » : « Repos par défaut » en premier, classement par score', () {
    final hits = searchSettings('repos');
    expect(hits.first.id, 'rest');
    expect(hits.map((e) => e.id), containsAll(['auto-rest', 'recovery']));
    expect(
      hits.indexWhere((e) => e.id == 'auto-rest'),
      lessThan(hits.indexWhere((e) => e.id == 'recovery')),
    );
  });

  test('une ligne absente n’est pas proposée', () {
    store.settings.notifOn = false;
    store.koach.answers.clear();
    final ids = [
      for (final e in settingsSearchIndex)
        if (e.isAvailable) e.id,
    ];
    expect(ids, isNot(contains('reminder-time')));
    expect(ids, isNot(contains('delete-answers')));
    expect(
      searchSettings('heure du rappel').map((e) => e.id),
      isNot(contains('reminder-time')),
    );
    // Sans la copie d'avant la suppression des WOD, pas de résultat.
    expect(store.retiredNotice, isNull);
    expect(searchSettings('wod'), isEmpty);
  });

  testWidgets('chaque page de réglage s’ouvre avec la ligne en évidence', (
    tester,
  ) async {
    phone(tester);
    for (final e in settingsSearchIndex) {
      final page = e.page;
      if (page == null || !e.isAvailable) continue;
      await tester.pumpWidget(
        _app(SettingsScreen(page: page, highlight: e.id)),
      );
      await tester.pumpAndSettle();
      expect(find.text(e.label), findsWidgets, reason: e.id);
      expect(_lit, findsOneWidget, reason: e.id);
      final label = find.descendant(of: _lit, matching: find.text(e.label));
      expect(label, findsOneWidget, reason: e.id);
      expect(
        label.hitTestable(),
        findsOneWidget,
        reason: '${e.id} : amenée à l’écran',
      );
      await _settleHighlight(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('chaque page d’aide s’ouvre depuis son résultat', (tester) async {
    phone(tester);
    for (final e in settingsSearchIndex) {
      if (e.page != null) continue;
      await tester.pumpWidget(_app(const SettingsScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('settings-search')),
        e.label,
      );
      await tester.pumpAndSettle();
      final result = find.byKey(ValueKey('settings-result-${e.id}'));
      await tester.ensureVisible(result);
      await tester.pumpAndSettle();
      await tester.tap(result);
      // Certaines destinations s'animent sans fin (Koach, 3D) : pas
      // d'attente du repos complet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(_screens[e.id], findsWidgets, reason: e.id);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('« repos » : résultats groupés, ouvre Séance en évidence', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-search')),
      'repos',
    );
    await tester.pumpAndSettle();
    // La carte Profil et les rubriques laissent la place aux résultats.
    expect(find.byKey(const ValueKey('settings-profile')), findsNothing);
    expect(
      find.byKey(const ValueKey('settings-page-appearance')),
      findsNothing,
    );
    final count = searchSettings('repos').length;
    expect(
      find.text(
        '$count résultats. Toucher un résultat ouvre sa page et met le '
        'réglage en évidence.',
      ),
      findsOneWidget,
    );
    expect(find.text('Réglages'), findsWidgets);
    expect(find.text('Aide'), findsOneWidget);
    final first = find.byKey(const ValueKey('settings-result-rest'));
    final recovery = find.byKey(const ValueKey('settings-result-recovery'));
    await tester.ensureVisible(recovery);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(recovery).dy, greaterThan(0));
    await tester.ensureVisible(first);
    await tester.pumpAndSettle();
    // Titre = libellé, description = chemin, valeur actuelle à droite.
    expect(
      find.descendant(of: first, matching: find.text('Repos par défaut')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('Séance › Chronomètres')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text(settingsSecondsLabel(store.settings.defaultRest)),
      ),
      findsOneWidget,
    );
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.text('SÉANCE'), findsOneWidget);
    expect(
      find.descendant(of: _lit, matching: find.text('Repos par défaut')),
      findsOneWidget,
    );
    await _settleHighlight(tester);
    // « Retour » ramène aux résultats.
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(first, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aucun résultat : message et action, pas de cul-de-sac', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('settings-search')),
      'zzqxw',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-search-empty')), findsOneWidget);
    expect(find.text('Aucun réglage trouvé'), findsOneWidget);
    await tester.tap(find.text('Effacer la recherche').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-search-empty')), findsNothing);
    expect(find.byKey(const ValueKey('settings-profile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
