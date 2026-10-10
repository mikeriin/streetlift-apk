// UI0 (refonte UI) — composants du kit (cahier §4.5, §5.3, §5.4, C1 à C13) :
// rendu, actions, accessibilité (cibles de 48 dp, boutons nommés), formes
// (pilule, rayons des trois familles), aucun débordement à 320 dp et 200 %
// de texte. Rendus de test dans le moteur Flutter (pas un téléphone).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/kit/catalog.dart';
import 'package:streetlift_tracker/kit/kit.dart';

Widget host(
  Widget child, {
  bool dark = true,
  String palette = 'bordeaux',
  double scale = 1,
  bool scroll = true,
}) => MaterialApp(
  theme: kitTheme(dark: dark, paletteId: palette),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: scroll
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(KSpacing.page),
                child: child,
              )
            : child,
      ),
    ),
  ),
);

void size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('jetons', () {
    test('rayons des trois familles, espacements, tailles', () {
      expect(KRadius.card, 24);
      expect(KRadius.menu, 20);
      expect(KRadius.pill, isA<StadiumBorder>());
      expect(KSize.target, 48);
      expect(KSize.primary, 56);
      expect(KSize.dock, 64);
      expect(KSpacing.page, 20);
      expect(KSpacing.cardGap, 12);
    });

    test('typographie du cahier §5.2', () {
      expect(KType.titreRacine.fontSize, 30);
      expect(KType.titreRacine.height! * 30, closeTo(36, .001));
      expect(KType.titreEcran.fontSize, 22);
      expect(KType.titreSeance.fontSize, 20);
      expect(KType.titreCarte.fontSize, 18);
      expect(KType.corpsFort.fontSize, 16);
      expect(KType.corpsFort.fontWeight, FontWeight.w600);
      expect(KType.corps.fontSize, 15);
      expect(KType.detail.fontSize, 13);
      expect(KType.section.fontSize, 14);
      expect(KType.micro.fontSize, 12);
      expect(KType.chiffre.fontSize, 36);
      expect(KType.chiffre.fontFamily, KFont.figures);
      expect(KType.chiffre.fontFeatures, KFont.tabular);
      expect(KType.chrono.fontSize, 34);
      for (final s in [
        KType.titreRacine,
        KType.titreEcran,
        KType.titreSeance,
      ]) {
        expect(s.fontFamily, KFont.title);
        expect(s.fontWeight, FontWeight.w600);
      }
    });

    test('capitales des titres par le jeton (U3)', () {
      final k = KTokens.fallback;
      expect(k.capsTitles, kCapsTitles);
      expect(k.title('Mon programme'), 'MON PROGRAMME');
      expect(k.title('Évolution'), 'ÉVOLUTION');
      final lower = k.copyWith(capsTitles: false);
      expect(lower.title('Mon programme'), 'Mon programme');
      expect(lower.titleStyle(KType.titreEcran).letterSpacing, 0);
      expect(k.titleStyle(KType.titreEcran).letterSpacing, KType.capsSpacing);
    });

    testWidgets('ressorts : durées non nulles, nulles si animations réduites', (
      tester,
    ) async {
      for (final m in [
        KMotion.fast,
        KMotion.standard,
        KMotion.slow,
        KMotion.effect,
      ]) {
        expect(m.duration, greaterThan(Duration.zero));
        expect(m.duration, lessThan(const Duration(milliseconds: 400)));
        expect(m.curve.transform(0), 0);
        expect(m.curve.transform(1), 1);
      }
      expect(KMotion.fast.duration, lessThan(KMotion.standard.duration));
      expect(KMotion.standard.duration, lessThan(KMotion.slow.duration));
      late Duration reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = KMotion.standard.durationIn(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(reduced, Duration.zero);
    });
  });

  group('cartes et surfaces', () {
    testWidgets('carte de contenu : surface, rayon 24, action', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(KCard(onTap: () => taps++, child: const Text('Contenu'))),
      );
      final k = KTokens.of(tester.element(find.text('Contenu')));
      final m = tester.widget<Material>(
        find
            .ancestor(of: find.text('Contenu'), matching: find.byType(Material))
            .first,
      );
      expect(m.color, k.surface);
      expect(
        (m.shape! as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(KRadius.card),
      );
      await tester.tap(find.text('Contenu'));
      expect(taps, 1);
    });

    testWidgets('carte du jour : aplat de la dominante, texte posé dessus', (
      tester,
    ) async {
      for (final palette in ['bordeaux', 'neon']) {
        await tester.pumpWidget(
          host(
            palette: palette,
            const KCard.day(child: Text('Squat et gainage')),
          ),
        );
        final k = KTokens.of(tester.element(find.text('Squat et gainage')));
        final m = tester.widget<Material>(
          find
              .ancestor(
                of: find.text('Squat et gainage'),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(m.color, k.pleine);
        final text = tester.widget<RichText>(
          find.descendant(
            of: find.text('Squat et gainage'),
            matching: find.byType(RichText),
          ),
        );
        expect(text.text.style!.color, k.surPleine);
      }
    });

    testWidgets('état vide : action qui résout (R6)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          KEmpty(
            icon: Icons.event_busy_rounded,
            title: 'Ta saison est vide',
            message: 'Ajoute une compétition.',
            action: 'Ajouter une compétition',
            onAction: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Ajouter une compétition'));
      expect(taps, 1);
    });

    testWidgets('bandeau dans le flux : action et fermeture nommée', (
      tester,
    ) async {
      var actions = 0, closes = 0;
      await tester.pumpWidget(
        host(
          KNotice(
            message: '11 questions pour affiner ton profil.',
            actionLabel: 'Compléter mon profil',
            onAction: () => actions++,
            onClose: () => closes++,
          ),
        ),
      );
      await tester.tap(find.text('Compléter mon profil'));
      await tester.tap(find.byTooltip('Fermer'));
      expect((actions, closes), (1, 1));
    });

    testWidgets('titre de section : 14, 600, texte2, sans capitales (C6)', (
      tester,
    ) async {
      await tester.pumpWidget(host(const KSectionTitle('Chronomètres')));
      final t = tester.widget<Text>(find.text('Chronomètres'));
      final k = KTokens.of(tester.element(find.text('Chronomètres')));
      expect(t.style!.fontSize, 14);
      expect(t.style!.fontWeight, FontWeight.w600);
      expect(t.style!.color, k.texte2);
      expect(find.text('CHRONOMÈTRES'), findsNothing);
    });
  });

  group('menus', () {
    testWidgets('groupe : séparateurs entre lignes, rayon 20', (tester) async {
      await tester.pumpWidget(
        host(
          KMenuGroup(
            title: 'Application',
            children: [
              for (final t in ['Apparence', 'Séance', 'Notifications'])
                KMenuRow(icon: Icons.tune, title: t, onTap: () {}),
            ],
          ),
        ),
      );
      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('Application'), findsOneWidget);
      final shapes = find
          .ancestor(of: find.text('Apparence'), matching: find.byType(Material))
          .evaluate()
          .map((e) => (e.widget as Material).shape);
      expect(shapes, contains(KRadius.menuShape));
    });

    testWidgets('ligne de menu : pastille, description, chevron, 64 dp', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          KMenuGroup(
            children: [
              KMenuRow(
                icon: Icons.palette_outlined,
                title: 'Apparence',
                subtitle: 'Thème, palette, contraste, anatomie 3D',
                onTap: () => taps++,
              ),
              const KMenuRow(title: 'Version', value: '6.11.1'),
            ],
          ),
        ),
      );
      expect(find.byType(KIconTile), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('6.11.1'), findsOneWidget);
      final row = tester.getSize(find.byType(KMenuRow).first);
      expect(row.height, greaterThanOrEqualTo(KSize.menuRow));
      await tester.tap(find.text('Apparence'));
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets(
      'mise en évidence d’une ligne ouverte par la recherche : 1,5 s',
      (tester) async {
        await tester.pumpWidget(
          host(
            KMenuGroup(
              children: [
                KMenuRow(
                  title: 'Repos par défaut',
                  highlight: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        );
        final k = KTokens.of(tester.element(find.text('Repos par défaut')));
        Color fill() =>
            ((tester
                        .widget<AnimatedContainer>(
                          find
                              .ancestor(
                                of: find.text('Repos par défaut'),
                                matching: find.byType(AnimatedContainer),
                              )
                              .first,
                        )
                        .decoration!
                    as ShapeDecoration)
                .color)!;
        expect(fill(), k.haute);
        await tester.pump(const Duration(milliseconds: 1600));
        await tester.pumpAndSettle();
        expect(fill().a, 0);
      },
    );

    testWidgets('interrupteur : toute la ligne bascule le réglage', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            KMenuGroup(
              children: [
                KSwitchRow(
                  title: 'Son en fin de repos',
                  subtitle: 'Trois bips',
                  value: value,
                  onChanged: (v) => set(() => value = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trois bips'));
      await tester.pump();
      expect(value, isTrue);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(value, isFalse);
    });

    testWidgets('pas à pas : trois pilules séparées, bornes, noms', (
      tester,
    ) async {
      var v = 90;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            KMenuGroup(
              children: [
                KStepperRow(
                  title: 'Repos par défaut',
                  value: '$v s',
                  onDecrement: v > 15 ? () => set(() => v -= 15) : null,
                  onIncrement: () => set(() => v += 15),
                  decrementLabel: 'Retirer 15 s',
                  incrementLabel: 'Ajouter 15 s',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Ajouter 15 s'));
      await tester.pump();
      expect(find.text('105 s'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byTooltip('Retirer 15 s'));
        await tester.pump();
      }
      expect(v, 15);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Retirer 15 s')),
        isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('segments : choix en pilule pleine, même forme choisi ou non', (
      tester,
    ) async {
      var selected = 'system';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, set) => host(
            KSegmented<String>(
              segments: const [
                KSegment('system', 'Système'),
                KSegment('dark', 'Sombre'),
                KSegment('light', 'Clair'),
              ],
              selected: selected,
              onChanged: (v) => set(() => selected = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();
      expect(selected, 'dark');
      final k = KTokens.of(tester.element(find.text('Sombre')));
      ShapeDecoration deco(String label) =>
          tester
                  .widget<AnimatedContainer>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as ShapeDecoration;
      expect(deco('Sombre').color, k.pleine);
      expect(deco('Sombre').shape, isA<StadiumBorder>());
      expect(deco('Clair').shape, isA<StadiumBorder>());
      expect(
        tester.getSize(find.byKey(const ValueKey('segment-dark'))).height,
        greaterThanOrEqualTo(KSize.target - 2 * KSpacing.s4),
      );
    });

    testWidgets('recherche : saisie, effacement nommé', (tester) async {
      final seen = <String>[];
      await tester.pumpWidget(
        host(KSearchField(hint: 'Rechercher un réglage', onChanged: seen.add)),
      );
      expect(find.text('Rechercher un réglage'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'repos');
      await tester.pump();
      await tester.tap(find.byTooltip('Effacer la recherche'));
      await tester.pump();
      expect(seen, ['repos', '']);
      expect(
        tester.getSize(find.byType(TextField)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('feuilles et confirmation', () {
    Future<BuildContext> opener(WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox(height: 10);
            },
          ),
        ),
      );
      return ctx;
    }

    testWidgets('feuille d’actions : groupes, danger en dernier, Fermer', (
      tester,
    ) async {
      final ctx = await opener(tester);
      String? got = 'x';
      showKActionSheet<String>(
        ctx,
        title: 'Séance',
        subtitle: 'Corps entier, S1, J2',
        groups: const [
          [
            KAction(
              icon: Icons.menu_book_outlined,
              label: 'Consignes de séance',
              value: 'c',
            ),
          ],
          [
            KAction(
              icon: Icons.delete_outline,
              label: 'Supprimer l’historique de cette séance',
              value: 'del',
              danger: true,
            ),
          ],
        ],
      ).then((v) => got = v);
      await tester.pumpAndSettle();
      expect(find.text('Corps entier, S1, J2'), findsOneWidget);
      final k = KTokens.of(tester.element(find.text('Séance')));
      final del = tester.widget<Text>(
        find.text('Supprimer l’historique de cette séance'),
      );
      expect(del.style!.color, k.danger);
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      expect(got, isNull);
      showKActionSheet<String>(
        ctx,
        title: 'Séance',
        groups: const [
          [
            KAction(
              icon: Icons.menu_book_outlined,
              label: 'Consignes de séance',
              value: 'c',
            ),
          ],
        ],
      ).then((v) => got = v);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consignes de séance'));
      await tester.pumpAndSettle();
      expect(got, 'c');
    });

    testWidgets('action destructrice hors du dernier groupe : refusée (C10)', (
      tester,
    ) async {
      final ctx = await opener(tester);
      expect(
        () => showKActionSheet<String>(
          ctx,
          title: 'Séance',
          groups: const [
            [
              KAction(
                icon: Icons.delete,
                label: 'Supprimer',
                value: 'd',
                danger: true,
              ),
            ],
            [KAction(icon: Icons.info, label: 'Consignes', value: 'c')],
          ],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('feuille de liste : numéros, courant en contour encre', (
      tester,
    ) async {
      final ctx = await opener(tester);
      int? got;
      showKListSheet(
        ctx,
        title: 'Dans cette séance',
        summary: '3 exercices, 22 min',
        items: const [
          KListItem('Bilan du jour', icon: Icons.favorite_border),
          KListItem('Échauffement', state: KListState.done),
          KListItem('Traction pronation', state: KListState.current),
          KListItem('Gainage creux'),
        ],
      ).then((v) => got = v);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      final k = KTokens.of(tester.element(find.text('Traction pronation')));
      final current = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Traction pronation'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect((current.shape! as RoundedRectangleBorder).side.color, k.encre);
      await tester.tap(find.text('Gainage creux'));
      await tester.pumpAndSettle();
      expect(got, 3);
    });

    testWidgets('confirmation : verbe exact, danger si destructeur, Annuler', (
      tester,
    ) async {
      final ctx = await opener(tester);
      bool? got;
      showKConfirm(
        ctx,
        title: 'Supprimer l’historique de cette séance ?',
        message: 'Les séries saisies seront effacées.',
        confirmLabel: 'Supprimer',
        destructive: true,
      ).then((v) => got = v);
      await tester.pumpAndSettle();
      final k = KTokens.of(tester.element(find.text('Supprimer')));
      final ok = tester.widget<FilledButton>(
        find.byKey(const ValueKey('confirm-ok')),
      );
      expect(ok.style!.backgroundColor!.resolve({}), k.danger);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(got, isFalse);
      showKConfirm(
        ctx,
        title: 'Revenir à un programme précédent ?',
        message: 'Ton programme actuel est gardé dans l’historique.',
        confirmLabel: 'Revenir',
      ).then((v) => got = v);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revenir'));
      await tester.pumpAndSettle();
      expect(got, isTrue);
    });
  });

  group('programme et séance', () {
    testWidgets('ligne de jour : titre en capitales, état lu, bouton ⓘ (R7)', (
      tester,
    ) async {
      var info = 0;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          KDayRow(
            number: 'J6',
            title: 'Puissance MU + squat endurance',
            onTap: () {},
            onInfo: () => info++,
          ),
        ),
      );
      expect(find.text('PUISSANCE MU + SQUAT ENDURANCE'), findsOneWidget);
      expect(
        find.bySemanticsLabel('J6, Puissance MU + squat endurance, à venir'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Résumé du jour'));
      expect(info, 1);
      handle.dispose();
    });

    testWidgets('barre de saison : même information que la frise (U7)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const KSeasonBar(
            blocks: [
              KSeasonBlock(3),
              KSeasonBlock(8),
              KSeasonBlock(8),
              KSeasonBlock(21),
            ],
            week: 13,
          ),
        ),
      );
      expect(find.text('S13'), findsOneWidget);
      expect(find.bySemanticsLabel('Semaine 13 sur 40'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tableau des séries : ligne courante en contour encre', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const KSetTable(
            columns: ['kg', 'Reps'],
            rows: [
              KSetRow(
                number: '1',
                state: KSetState.done,
                cells: [KSetField('+32,5'), KSetField('5')],
              ),
              KSetRow(
                number: '2',
                state: KSetState.current,
                cells: [KSetField('+32,5'), KSetField('5')],
              ),
            ],
          ),
        ),
      );
      expect(find.text('kg'), findsOneWidget);
      final k = KTokens.of(tester.element(find.text('kg')));
      final current = tester.widget<Container>(
        find
            .ancestor(of: find.text('2'), matching: find.byType(Container))
            .first,
      );
      final deco = current.decoration! as ShapeDecoration;
      expect((deco.shape as RoundedRectangleBorder).side.color, k.encre);
      expect(
        tester.getSize(find.byType(KSetField).first).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('barre de repos : −15 s / +15 s, arrêt nommé', (tester) async {
      final calls = <String>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          KRestBar(
            remaining: '2:27',
            progress: .5,
            onMinus: () => calls.add('-'),
            onPlus: () => calls.add('+'),
            onStop: () => calls.add('stop'),
          ),
        ),
      );
      await tester.tap(find.text('−15 s'));
      await tester.tap(find.text('+15 s'));
      await tester.tap(find.byTooltip('Arrêter le repos'));
      expect(calls, ['-', '+', 'stop']);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('message court au-dessus du dock', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      showKSnack(
        ctx,
        message: 'Koach : série suivante dans 2 s',
        actionLabel: 'Annuler',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Koach : série suivante dans 2 s'), findsOneWidget);
    });
  });

  group('pages, en-têtes et dock', () {
    testWidgets('page racine : grand titre replié au défilement', (
      tester,
    ) async {
      size(tester, 360, 640);
      await tester.pumpWidget(
        MaterialApp(
          theme: kitTheme(dark: true),
          home: KPage.root(
            title: 'Réglages',
            lead: 'L’application à ta façon.',
            children: [
              for (var i = 0; i < 30; i++) KCard(child: Text('Ligne $i')),
            ],
          ),
        ),
      );
      expect(find.text('RÉGLAGES'), findsNWidgets(2));
      double opacityOf(Finder f) => tester
          .widget<Opacity>(
            find.ancestor(of: f, matching: find.byType(Opacity)).first,
          )
          .opacity;
      final titles = find.text('RÉGLAGES');
      expect(opacityOf(titles.first) + opacityOf(titles.last), closeTo(1, .01));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final o = [opacityOf(titles.first), opacityOf(titles.last)]..sort();
      expect(o, [0, 1]);
    });

    testWidgets('sous-page : retour, titre, une action (C1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kitTheme(dark: false),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => KPage.sub(
                    title: 'Apparence',
                    lead: 'Thème, palette, contraste, anatomie 3D.',
                    action: KIconButton(
                      icon: Icons.more_vert_rounded,
                      tooltip: 'Plus d’actions',
                      onPressed: () {},
                    ),
                    children: const [KCard(child: Text('Contenu'))],
                  ),
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('APPARENCE'), findsOneWidget);
      expect(find.byTooltip('Plus d’actions'), findsOneWidget);
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('titre jamais coupé (C3) : passe à la ligne, 320 dp et 200 %', (
      tester,
    ) async {
      size(tester, 320, 800);
      await tester.pumpWidget(
        host(
          scale: 2,
          Builder(
            builder: (context) => KFitTitle(
              KTokens.of(context).title('Test max tractions au poids de corps'),
              style: KType.titreRacine,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets(
      'dock : 4 onglets, libellé de l’onglet actif seul, pilule pleine',
      (tester) async {
        size(tester, 360, 640);
        var index = 2;
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, set) => MaterialApp(
              theme: kitTheme(dark: true),
              home: Scaffold(
                extendBody: true,
                bottomNavigationBar: KDock(
                  index: index,
                  onTap: (i) => set(() => index = i),
                  items: const [
                    KDockItem(Icons.grid_view_rounded, 'Arsenal'),
                    KDockItem(Icons.insights_rounded, 'Stats'),
                    KDockItem(Icons.fitness_center_rounded, 'Programme'),
                    KDockItem(Icons.settings_outlined, 'Réglages'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PROGRAMME'), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Programme')),
          isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
        );
        await tester.tap(find.byKey(const ValueKey('nav-0')));
        await tester.pumpAndSettle();
        expect(index, 0);
        final dock = tester.getRect(find.byType(KDock));
        expect(dock.height, KDock.height);
        expect(KDock.reserve, KDock.height + 16);
        for (var i = 0; i < 4; i++) {
          expect(
            tester.getSize(find.byKey(ValueKey('nav-$i'))).height,
            KSize.dockItem,
          );
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      },
    );

    testWidgets('sélecteur de palette : 8 pastilles nommées, choix coché', (
      tester,
    ) async {
      String? picked;
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          KPalettePicker(
            selectedId: 'bordeaux',
            onSelected: (id) => picked = id,
          ),
        ),
      );
      for (final p in kPaletteSources) {
        expect(find.byKey(ValueKey('accent-${p.id}')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('accent-check-bordeaux')),
        findsOneWidget,
      );
      expect(find.text('Bordeaux Performance'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('accent-neon')));
      expect(picked, 'neon');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('catalogue', () {
    for (final (width, scale) in const [
      (360.0, 1.0),
      (360.0, 1.3),
      (320.0, 2.0),
    ]) {
      for (final dark in [true, false]) {
        testWidgets(
          'toutes les sections : aucun débordement '
          '(${width.toInt()} dp, ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'})',
          (tester) async {
            size(tester, width, 2400);
            for (final s in kitSamples) {
              await tester.pumpWidget(
                host(dark: dark, scale: scale, KitSampleView(s)),
              );
              await tester.pump(const Duration(milliseconds: 1700));
              expect(tester.takeException(), isNull, reason: s.id);
            }
          },
        );
      }
    }

    testWidgets('écran du catalogue : palettes, thème et contraste locaux', (
      tester,
    ) async {
      size(tester, 360, 2000);
      await tester.pumpWidget(
        MaterialApp(
          theme: kitTheme(dark: true),
          home: const KitCatalogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CATALOGUE DU KIT'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accent-neon')).first);
      await tester.pumpAndSettle();
      final k = KTokens.of(tester.element(find.text('Contraste renforcé')));
      expect(k.paletteId, 'neon');
      expect(tester.takeException(), isNull);
    });
  });
}
