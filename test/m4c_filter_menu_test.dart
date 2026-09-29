// M4c : filtres normalisés. Composant commun `FilterMenu` (union dans une
// catégorie, intersection entre catégories, compteur, réinitialisation,
// puces, catégories repliables, accessibilité, thèmes et couleurs) et un
// écran par famille : bibliothèque d'exercices, catalogue WOD, choix
// d'exercice (l'historique de STATS : test/stats_test.dart ; l'Anatomie :
// test/m4b_anatomie_test.dart).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/builder_screen.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';

import 'phone_test_support.dart';

const _cats = [
  FilterCategory(
    id: 'couleur',
    label: 'Couleur',
    options: [
      FilterOption('rouge', 'Rouge'),
      FilterOption('bleu', 'Bleu'),
      FilterOption('vert', 'Vert'),
    ],
  ),
  FilterCategory(
    id: 'taille',
    label: 'Taille',
    options: [FilterOption('petit', 'Petit'), FilterOption('grand', 'Grand')],
  ),
];

/// Éléments filtrés par le menu de test : (couleur, taille).
const _items = [
  ('rouge', 'petit'),
  ('rouge', 'grand'),
  ('bleu', 'petit'),
  ('vert', 'grand'),
];

List<(String, String)> _filter(FilterSelection s) => [
  for (final i in _items)
    if (s.matches('couleur', (k) => k == i.$1) &&
        s.matches('taille', (k) => k == i.$2))
      i,
];

Widget _app(
  Widget home, {
  bool dark = true,
  double scale = 1,
  KAccentSpec accent = KAccentSpec.rouge,
}) => MaterialApp(
  theme: buildTheme(dark, accent),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: home,
);

class _Host extends StatefulWidget {
  final FilterSelection initial;
  const _Host({this.initial = const FilterSelection()});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late FilterSelection value = widget.initial;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Test')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilterMenu(
          keyPrefix: 't',
          categories: _cats,
          value: value,
          initial: widget.initial,
          onChanged: (v) => setState(() => value = v),
        ),
        for (final i in _filter(value)) Text('élément ${i.$1} ${i.$2}'),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sélection', () {
    test('union dans une catégorie, intersection entre catégories', () {
      const none = FilterSelection();
      expect(_filter(none), _items);
      final rougeOuBleu = none
          .toggle('couleur', 'rouge')
          .toggle('couleur', 'bleu');
      expect(_filter(rougeOuBleu).length, 3);
      final etPetit = rougeOuBleu.toggle('taille', 'petit');
      expect(_filter(etPetit), [('rouge', 'petit'), ('bleu', 'petit')]);
      expect(etPetit.count(_cats), 3);
      expect(etPetit.toggle('couleur', 'rouge').count(_cats), 2);
      expect(etPetit.active(_cats).map((a) => a.$2.label), [
        'Rouge',
        'Bleu',
        'Petit',
      ]);
    });

    test('égalité indépendante de l’ordre et des catégories vides', () {
      final a = const FilterSelection().toggle('couleur', 'rouge');
      const b = FilterSelection({
        'couleur': {'rouge'},
        'taille': {},
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.withKeys('couleur', const {}), const FilterSelection());
    });
  });

  group('menu', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('t-filters')));
      await tester.pumpAndSettle();
    }

    Future<void> tapItem(WidgetTester tester, String key) async {
      final item = find.byKey(ValueKey('t-$key')).first;
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();
    }

    testWidgets('compteur, cases qui se superposent, puces, réinitialiser', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(_app(const _Host()));
      expect(find.text('Filtres · 0'), findsOneWidget);
      expect(find.textContaining('élément'), findsNWidgets(4));
      await open(tester);
      // Menu court (5 options) : toutes les catégories dépliées.
      await tapItem(tester, 'filter-rouge');
      await tapItem(tester, 'filter-bleu');
      await tapItem(tester, 'filter-petit');
      expect(find.text('Filtres · 3'), findsOneWidget);
      expect(find.text('élément rouge petit'), findsOneWidget);
      expect(find.text('élément bleu petit'), findsOneWidget);
      expect(find.text('élément rouge grand'), findsNothing);
      // Toucher en dehors : le menu se ferme, les filtres restent.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('t-filter-rouge')), findsNothing);
      expect(find.text('Filtres · 3'), findsOneWidget);
      // Puces supprimables sous le bouton.
      for (final k in ['rouge', 'bleu', 'petit']) {
        expect(find.byKey(ValueKey('t-chip-$k')), findsOneWidget);
      }
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('t-chip-petit')),
          matching: find.byIcon(Icons.cancel),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Filtres · 2'), findsOneWidget);
      expect(find.text('élément rouge grand'), findsOneWidget);
      expect(find.byKey(const ValueKey('t-chip-petit')), findsNothing);
      // Réinitialiser (menu) : filtres de départ.
      await open(tester);
      await tapItem(tester, 'filter-reset');
      expect(find.text('Filtres · 0'), findsOneWidget);
      expect(find.textContaining('élément'), findsNWidgets(4));
      expect(find.byKey(const ValueKey('t-chips')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tout cocher, tout décocher par catégorie ; catégories '
        'repliables', (tester) async {
      phone(tester);
      await tester.pumpWidget(
        _app(
          const _Host(
            initial: FilterSelection({
              'taille': {'grand'},
            }),
          ),
        ),
      );
      expect(find.text('Filtres · 1'), findsOneWidget);
      await open(tester);
      await tapItem(tester, 'filter-all-couleur');
      expect(find.text('Filtres · 4'), findsOneWidget);
      await tapItem(tester, 'filter-none-taille');
      expect(find.text('Filtres · 3'), findsOneWidget);
      expect(find.textContaining('élément'), findsNWidgets(4));
      // Réinitialiser : retour aux filtres de départ de l'écran.
      await tapItem(tester, 'filter-reset');
      expect(find.text('Filtres · 1'), findsOneWidget);
      // Replier une catégorie : ses cases disparaissent.
      await tapItem(tester, 'filter-cat-couleur');
      expect(find.byKey(const ValueKey('t-filter-rouge')), findsNothing);
      expect(find.byKey(const ValueKey('t-filter-grand')), findsWidgets);
      await tapItem(tester, 'filter-cat-couleur');
      expect(find.byKey(const ValueKey('t-filter-rouge')), findsWidgets);
    });

    testWidgets('accessibilité : bouton et cases lus avec catégorie et '
        'état, cibles de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      phone(tester);
      await tester.pumpWidget(_app(const _Host()));
      expect(
        tester.getSemantics(find.byKey(const ValueKey('t-filters'))),
        isSemantics(
          label: 'Filtres, 0 actif sur 5',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('t-filters'))).height,
        greaterThanOrEqualTo(48),
      );
      await open(tester);
      await tapItem(tester, 'filter-bleu');
      for (final (key, label, checked) in [
        ('bleu', 'Bleu, Couleur', true),
        ('rouge', 'Rouge, Couleur', false),
        ('petit', 'Petit, Taille', false),
      ]) {
        final item = find.byKey(ValueKey('t-filter-$key')).first;
        expect(
          tester.getSemantics(item),
          isSemantics(
            label: label,
            hasCheckedState: true,
            isChecked: checked,
            hasTapAction: true,
          ),
          reason: key,
        );
        expect(tester.getSize(item).height, greaterThanOrEqualTo(48));
      }
      expect(
        tester.getSemantics(find.byKey(const ValueKey('t-filter-cat-couleur'))),
        isSemantics(label: 'Couleur, 1 sur 3 cochés, déplié', isButton: true),
      );
      handle.dispose();
    });

    for (final dark in [true, false]) {
      for (final accent in KAccentSpec.all) {
        testWidgets('thème ${dark ? 'sombre' : 'clair'}, ${accent.label}, '
            'texte 200 %, 320 px', (tester) async {
          phone(tester, size: const Size(320, 720));
          await tester.pumpWidget(
            _app(const _Host(), dark: dark, scale: 2, accent: accent),
          );
          await open(tester);
          await tapItem(tester, 'filter-rouge');
          await tapItem(tester, 'filter-all-taille');
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          expect(find.text('Filtres · 3'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      await ContentLibrary.load();
    });

    Future<void> openMenu(WidgetTester tester, String prefix) async {
      final button = find.byKey(ValueKey('$prefix-filters'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    Future<void> tapItem(WidgetTester tester, String key) async {
      final item = find.byKey(ValueKey(key)).first;
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();
    }

    int countIn(String text) =>
        int.parse(RegExp(r'(\d+) exercice').firstMatch(text)!.group(1)!);

    testWidgets('bibliothèque : union, intersection, mémorisée pendant la '
        'session', (tester) async {
      phone(tester);
      ExerciseLibraryScreen.session = const FilterSelection();
      await tester.pumpWidget(_app(const ExerciseLibraryScreen()));
      await tester.pumpAndSettle();
      final counter = find.textContaining(RegExp(r'^\d+ exercices?$'));
      final all = countIn(tester.widget<Text>(counter).data!);
      await openMenu(tester, 'library');
      // Menu long : seule la première catégorie est dépliée.
      expect(
        find.byKey(const ValueKey('library-filter-type:tirage_vertical')),
        findsWidgets,
      );
      expect(find.byKey(const ValueKey('library-filter-niv:1')), findsNothing);
      await tapItem(tester, 'library-filter-type:tirage_vertical');
      final vertical = countIn(tester.widget<Text>(counter).data!);
      await tapItem(tester, 'library-filter-type:tirage_horizontal');
      final both = countIn(tester.widget<Text>(counter).data!);
      expect(vertical, lessThan(all));
      expect(both, greaterThan(vertical));
      await tapItem(tester, 'library-filter-cat-niveau');
      await tapItem(tester, 'library-filter-niv:3');
      final hard = countIn(tester.widget<Text>(counter).data!);
      expect(hard, lessThan(both));
      expect(
        hard,
        searchExercises(
          store.content,
          '',
          const ExerciseFilters(
            types: {'tirage_vertical', 'tirage_horizontal'},
            niveaux: {3},
          ),
        ).length,
      );
      expect(find.text('Filtres · 3'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      // Écran refermé puis rouvert : mêmes filtres (session).
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(const ExerciseLibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Filtres · 3'), findsOneWidget);
      expect(countIn(tester.widget<Text>(counter).data!), hard);
      ExerciseLibraryScreen.session = const FilterSelection();
      expect(tester.takeException(), isNull);
    });

    testWidgets('catalogue WOD : filtres par catégorie, vitrine masquée', (
      tester,
    ) async {
      phone(tester);
      WodCatalogScreen.session = const FilterSelection();
      await tester.pumpWidget(_app(const WodCatalogScreen()));
      await tester.pumpAndSettle();
      int total() => int.parse(
        RegExp(r'WODs · (\d+)')
            .firstMatch(
              tester.widget<Text>(find.textContaining('WODs · ')).data!,
            )!
            .group(1)!,
      );
      final all = total();
      await openMenu(tester, 'wod');
      await tapItem(tester, 'wod-filter-cat-format');
      await tapItem(tester, 'wod-filter-ty:amrap');
      final amrap = total();
      await tapItem(tester, 'wod-filter-ty:emom');
      final amrapOrEmom = total();
      expect(amrap, lessThan(all));
      expect(amrapOrEmom, greaterThan(amrap));
      await tapItem(tester, 'wod-filter-cat-duree');
      await tapItem(tester, 'wod-filter-du:short');
      expect(total(), lessThanOrEqualTo(amrapOrEmom));
      expect(find.text('Filtres · 3'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wod-chip-ty:amrap')), findsOneWidget);
      expect(find.byKey(const ValueKey('wod-chip-du:short')), findsOneWidget);
      // Réinitialiser (puces) : catalogue complet.
      await tester.tap(find.byKey(const ValueKey('wod-chips-reset')));
      await tester.pumpAndSettle();
      expect(total(), all);
      expect(find.text('Filtres · 0'), findsOneWidget);
      WodCatalogScreen.session = const FilterSelection();
      expect(tester.takeException(), isNull);
    });

    testWidgets('choix d’exercice : groupe et matériel', (tester) async {
      phone(tester);
      exercisePickerFilters = const FilterSelection();
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => pickExercise(context),
                  child: const Text('Choisir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choisir'));
      await tester.pumpAndSettle();
      final counter = find.textContaining(RegExp(r'^\d+ exercices?'));
      final all = countIn(tester.widget<Text>(counter).data!);
      await openMenu(tester, 'picker');
      final groups = find.byWidgetPredicate(
        (w) =>
            w is CheckboxListTile &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('picker-filter-g:'),
      );
      expect(groups, findsWidgets);
      final first =
          (tester.widget(groups.first).key! as ValueKey<String>).value;
      await tapItem(tester, first);
      final one = countIn(tester.widget<Text>(counter).data!);
      expect(one, lessThan(all));
      expect(find.text('Filtres · 1'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(first.replaceFirst('filter', 'chip'))),
        findsOneWidget,
      );
      exercisePickerFilters = const FilterSelection();
      expect(tester.takeException(), isNull);
    });
  });
}
