// UI4 (refonte UI, cahier §4.1, §4.3, §4.4) — onglet Arsenal : racine au
// gabarit « menu racine » avec recherche directe « Exercice ou muscle »
// (résultats « Exercices » puis « Muscles »), fiche › groupe musculaire ›
// Anatomie, Anatomie › « Exercices pour ce muscle » › bibliothèque filtrée,
// réglage du nom au toucher ouvert par un bouton (R5), galerie de Koach
// retirée de l'Anatomie.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/arsenal_screen.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/engine3d.dart' show engine3DSupport;
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/mannequin_3d.dart' show Display3DSettings;
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

Widget _page(Widget child) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: child,
);

/// Carte 2D chargée (images décodées hors de l'horloge de test).
Future<void> _settle(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(ready, findsWidgets);
}

int _count(WidgetTester tester) {
  final count = find.byKey(const ValueKey('library-count'));
  final text = tester.widget<Text>(count).data!;
  return int.parse(text.split(' ').first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
  });

  setUp(() {
    AnatomyScreen.session = null;
    ExerciseLibraryScreen.session = const FilterSelection();
  });

  group('racine d’Arsenal', () {
    testWidgets('recherche directe et les deux entrées', (tester) async {
      final handle = tester.ensureSemantics();
      phone(tester);
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      expect(find.text('ARSENAL'), findsWidgets);
      expect(
        find.text('Tes exercices. Tes muscles. Ta technique.'),
        findsOneWidget,
      );
      expect(find.byType(KSearchField), findsOneWidget);
      expect(find.text('Exercice ou muscle'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Rechercher un exercice ou un muscle'),
        findsWidgets,
      );
      expect(find.text('Consulter'), findsOneWidget);
      expect(find.byKey(const ValueKey('arsenal-exercises')), findsOneWidget);
      expect(find.byKey(const ValueKey('arsenal-anatomy')), findsOneWidget);
      expect(
        find.text('Fiches, démonstrations, muscles et progressions'),
        findsOneWidget,
      );
      expect(
        find.text('Muscles, groupes, vues et leurs exercices'),
        findsOneWidget,
      );
      // Rien n'est cherché tant que le champ est vide.
      expect(
        find.byKey(const ValueKey('arsenal-results-exercises')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('« pector » : groupe « Muscles » ; un résultat ouvre '
        'l’Anatomie sur le bon groupe', (tester) async {
      phone(tester);
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pector');
      await tester.pumpAndSettle();
      final muscles = find.byKey(const ValueKey('arsenal-results-muscles'));
      expect(muscles, findsOneWidget);
      // Même règle de correspondance que la bibliothèque (search.dart).
      final hits = searchMuscles('pector');
      expect(hits.first.isGroup, isTrue);
      expect(hits.first.group, 'pectoraux');
      expect(hits.where((h) => !h.isGroup), isNotEmpty);
      expect(
        hits.every((h) => h.doc.all.contains('pector')),
        isTrue,
        reason: 'chaque résultat contient le mot cherché',
      );
      final row = find.byKey(const ValueKey('arsenal-group-pectoraux'));
      await scrollToAction(tester, row);
      expect(
        find.descendant(of: muscles, matching: row),
        findsOneWidget,
        reason: 'le groupe est rangé sous « Muscles »',
      );
      await tester.tap(row);
      await _settle(tester, find.byType(MuscleMap2D));
      expect(find.text('ANATOMIE'), findsWidgets);
      expect(
        tester.state<AnatomyScreenState>(find.byType(AnatomyScreen)).groups,
        {'pectoraux'},
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('un muscle (pas un groupe) ouvre l’Anatomie sur son groupe', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'grand dorsal');
      await tester.pumpAndSettle();
      final hits = searchMuscles('grand dorsal');
      final hit = hits.firstWhere((h) => h.id == 'grand_dorsal');
      expect(hit.isGroup, isFalse);
      expect(hit.group, 'dorsaux');
      final row = find.byKey(const ValueKey('arsenal-muscle-grand_dorsal'));
      await scrollToAction(tester, row);
      await tester.tap(row);
      await _settle(tester, find.byType(MuscleMap2D));
      expect(
        tester.state<AnatomyScreenState>(find.byType(AnatomyScreen)).groups,
        {'dorsaux'},
      );
    });

    testWidgets('nom d’exercice réel : résultat « Exercices », fiche', (
      tester,
    ) async {
      phone(tester);
      final e = store.content.byId['mu-roue-abdominale-genoux']!;
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), e.nom);
      await tester.pumpAndSettle();
      final group = find.byKey(const ValueKey('arsenal-results-exercises'));
      expect(group, findsOneWidget);
      final row = find.byKey(ValueKey('arsenal-ex-${e.id}'));
      expect(find.descendant(of: group, matching: row), findsOneWidget);
      await scrollToAction(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseSheetScreen), findsOneWidget);
      // R3 : le titre de la fiche est le nom de l'exercice.
      expect(find.text(e.nom.toUpperCase()), findsOneWidget);
      expect(find.text('FICHE EXERCICE'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('beaucoup d’exercices : « Voir les n exercices » ouvre la '
        'bibliothèque sur la recherche', (tester) async {
      phone(tester);
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'traction');
      await tester.pumpAndSettle();
      final all = searchExercises(
        store.content,
        'traction',
        const ExerciseFilters(),
      );
      expect(all.length, greaterThan(ArsenalScreen.exerciseLimit));
      expect(
        find.byKey(const ValueKey('arsenal-results-exercises')),
        findsOneWidget,
      );
      final more = find.byKey(const ValueKey('arsenal-ex-all'));
      await scrollToAction(tester, more);
      expect(find.text('Voir les ${all.length} exercices'), findsOneWidget);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
      expect(_count(tester), all.length);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'traction',
      );
    });

    testWidgets('aucun résultat : message et « Effacer la recherche »', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(_page(const ArsenalScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzqxw');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('arsenal-no-result')), findsOneWidget);
      expect(find.text('Aucun résultat'), findsOneWidget);
      // Les entrées restent joignables (pas de cul-de-sac).
      expect(find.byKey(const ValueKey('arsenal-exercises')), findsOneWidget);
      final clear = find.widgetWithText(KTonalButton, 'Effacer la recherche');
      await scrollToAction(tester, clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('arsenal-no-result')), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });
  });

  testWidgets('fiche › Muscles : un groupe ouvre l’Anatomie sur ce groupe', (
    tester,
  ) async {
    phone(tester);
    const id = 'mu-roue-abdominale-genoux';
    final d = store.content.detail(id)!;
    final groups = mapGroupsOfAtlasMuscles([
      ...d.primaires,
      ...d.secondaires,
      ...d.stabilisateurs,
    ]);
    expect(groups, isNotEmpty);
    await tester.pumpWidget(_page(const ExerciseSheetScreen(id: id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fiche-titre')), findsOneWidget);
    final chip = find.byKey(ValueKey('fiche-groupe-${groups.first}'));
    await scrollToAction(tester, chip);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('fiche-muscles')),
        matching: chip,
      ),
      findsOneWidget,
    );
    await tester.tap(chip);
    await _settle(tester, find.byType(MuscleMap2D));
    expect(
      tester.state<AnatomyScreenState>(find.byType(AnatomyScreen)).groups,
      {groups.first},
    );
    // L'écran a défilé jusqu'au groupe : son bouton est à l'écran.
    expect(
      find.byKey(ValueKey('anatomy-exercises-${groups.first}')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Anatomie › « Exercices pour ce muscle » : liste filtrée non '
      'vide, filtre retirable', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      _page(const AnatomyScreen(initialGroup: 'pectoraux')),
    );
    await _settle(tester, find.byType(MuscleMap2D));
    final button = find.byKey(const ValueKey('anatomy-exercises-pectoraux'));
    expect(button.hitTestable(), findsOneWidget);
    expect(
      find.widgetWithText(KTonalButton, 'Exercices pour ce muscle'),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    final all = searchExercises(store.content, '', const ExerciseFilters());
    final expected = [
      for (final e in all)
        if (exerciseWorksMapGroup(e, 'pectoraux')) e,
    ];
    expect(expected, isNotEmpty);
    expect(expected.length, lessThan(all.length));
    expect(_count(tester), expected.length);
    expect(find.byKey(const ValueKey('library-muscle-chip')), findsOneWidget);
    // Le premier exercice listé sollicite bien les pectoraux.
    expect(
      find.byKey(ValueKey('library-ex-${expected.first.id}')),
      findsOneWidget,
    );
    // Puce retirée : toute la bibliothèque.
    await tester.tap(
      find.byTooltip('Retirer le filtre Groupe musculaire : Pectoraux'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-muscle-chip')), findsNothing);
    expect(_count(tester), all.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bibliothèque vide : action qui la résout (R6)', (tester) async {
    phone(tester);
    await tester.pumpWidget(_page(const ExerciseLibraryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Rechercher un exercice'), findsOneWidget);
    expect(find.text('Nom, muscle, matériel, discipline…'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzqxw');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-empty')), findsOneWidget);
    await tester.tap(find.widgetWithText(KTonalButton, 'Effacer la recherche'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-empty')), findsNothing);
    expect(_count(tester), store.content.entries.length);
  });

  testWidgets('Anatomie : plus de « Galerie de Koach »', (tester) async {
    // Écran haut : toute la liste est construite.
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _page(const AnatomyScreen(initialGroup: 'dorsaux')),
    );
    await _settle(tester, find.byType(MuscleMap2D));
    expect(find.text('Galerie de Koach'), findsNothing);
    expect(find.byKey(const ValueKey('anatomy-koach-gallery')), findsNothing);
    expect(find.byKey(const ValueKey('anatomy-group-list')), findsOneWidget);
  });

  testWidgets('nom au toucher coupé : un bouton ouvre Réglages › Apparence '
      '(R5, plus de chemin écrit)', (tester) async {
    phone(tester);
    Display3DSettings.instance.touchNames.value = false;
    addTearDown(Display3DSettings.instance.reset);
    await tester.pumpWidget(_page(const AnatomyScreen()));
    await _settle(tester, find.byType(MuscleMap2D));
    expect(find.textContaining('Réglages ›'), findsNothing);
    final open = find.byKey(const ValueKey('anatomy-open-appearance'));
    await scrollToAction(tester, open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    final settings = tester.widget<SettingsScreen>(find.byType(SettingsScreen));
    expect(settings.page, SettingsPage.appearance);
    expect(settings.highlight, 'muscle-names');
    // Fin de la mise en évidence (1,5 s) : aucun minuteur en attente.
    await tester.pump(KRowFrame.highlightDuration * 2);
  });
}
