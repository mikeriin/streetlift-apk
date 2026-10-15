// UI5 (refonte UI) — corrections du kit (DECISIONS_UI.md U0.16) et
// composants promus : titre de sous-page jamais coupé, interrupteur et pas à
// pas sous le libellé quand la place manque, segments de 48 dp touchables,
// confirmation qui défile et clés par bouton, feuille de contenu unique,
// feuille de liste ouverte sur un élément, contraste du dock (U0.12).
// Polices réelles chargées (les mesures de largeur en dépendent).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/kit/kit.dart';

import 'support/ui_capture.dart';

Widget host(
  Widget child, {
  bool dark = true,
  String palette = 'bordeaux',
  double scale = 1,
}) => MaterialApp(
  theme: kitTheme(dark: dark, paletteId: palette),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  ),
);

void size(WidgetTester tester, double width, [double height = 900]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Aucun paragraphe de [finder] n'a perdu de texte (ellipse ou lignes en
/// trop).
void expectWhole(WidgetTester tester, Finder finder) {
  for (final e in finder.evaluate()) {
    final p = e.renderObject! as RenderParagraph;
    expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
    expect(p.overflow, isNot(TextOverflow.ellipsis));
  }
}

void main() {
  setUpAll(loadUiFonts);

  group('en-tête de sous-page (C3, U0.16 point 1)', () {
    const titles = [
      'Supprimer les données de l’application',
      'Progression et jeu',
      'Données et confidentialité',
      'Développé couché prise serrée avec élastiques',
    ];
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [320.0, 390.0]) {
        testWidgets('titres entiers à $width dp et ${scale * 100} %', (
          tester,
        ) async {
          size(tester, width, 800);
          for (final t in titles) {
            await tester.pumpWidget(
              host(
                KPage.sub(title: t, children: const [Text('Contenu')]),
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            final title = find.text(t.toUpperCase());
            expect(title, findsOneWidget, reason: t);
            expectWhole(tester, title);
            // La barre suit le titre : le contenu commence sous lui.
            expect(
              tester.getTopLeft(find.text('Contenu')).dy,
              greaterThan(tester.getBottomLeft(title).dy),
              reason: t,
            );
            expect(tester.takeException(), isNull, reason: t);
          }
        });
      }
    }

    testWidgets('retour nommé et clé ; retour masqué sur demande', (
      tester,
    ) async {
      size(tester, 390);
      await tester.pumpWidget(
        host(
          const Scaffold(
            appBar: KTopBar.sub(title: 'Apparence'),
            body: SizedBox.shrink(),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('topbar-back')), findsOneWidget);
      expect(find.byTooltip('Retour'), findsOneWidget);
      await tester.pumpWidget(
        host(
          const Scaffold(
            appBar: KTopBar.sub(title: 'Apparence', showBack: false),
            body: SizedBox.shrink(),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('topbar-back')), findsNothing);
    });
  });

  group('lignes de réglage (U0.16 points 2 à 4)', () {
    testWidgets('interrupteur sous le libellé à 320 dp × 200 %', (
      tester,
    ) async {
      size(tester, 320, 800);
      var on = false;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(KSpacing.page),
              children: [
                StatefulBuilder(
                  builder: (context, set) => KSwitchRow(
                    title: 'Célébrations',
                    subtitle: 'Animations des records et des niveaux',
                    value: on,
                    onChanged: (v) => set(() => on = v),
                  ),
                ),
              ],
            ),
          ),
          scale: 2,
        ),
      );
      final label = find.text('Célébrations');
      expectWhole(tester, label);
      expect(
        tester.getTopLeft(find.byType(Switch)).dy,
        greaterThan(tester.getBottomLeft(label).dy),
      );
      await tester.tap(label);
      await tester.pump();
      expect(on, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('interrupteur à côté du libellé quand il tient', (
      tester,
    ) async {
      size(tester, 390);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(KSpacing.page),
              children: [
                KSwitchRow(
                  title: 'Célébrations',
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final label = tester.getRect(find.text('Célébrations'));
      final sw = tester.getRect(find.byType(Switch));
      expect(sw.left, greaterThan(label.right));
      expect((sw.center.dy - label.center.dy).abs(), lessThan(KSpacing.s16));
    });

    testWidgets('pas à pas sous le libellé sous 420 dp, avec ses clés', (
      tester,
    ) async {
      size(tester, 390);
      var n = 3;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(KSpacing.page),
              children: [
                StatefulBuilder(
                  builder: (context, set) => KStepperRow(
                    title: 'Décompte « Prêt »',
                    value: '$n s',
                    keyPrefix: 'ready',
                    onDecrement: () => set(() => n--),
                    onIncrement: () => set(() => n++),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final label = find.text('Décompte « Prêt »');
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('ready-minus'))).dy,
        greaterThan(tester.getBottomLeft(label).dy),
      );
      await tester.tap(find.byKey(const ValueKey('ready-plus')));
      await tester.pump();
      expect(n, 4);
      expect(find.byKey(const ValueKey('ready-value')), findsOneWidget);
    });
  });

  group('segments : 48 dp touchables par segment (C13)', () {
    const segments = [
      KSegment(0, 'Adaptatif'),
      KSegment(2, '2'),
      KSegment(3, '3'),
      KSegment(4, '4'),
      KSegment(5, '5'),
      KSegment(6, '6'),
    ];
    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('objectif de la semaine à $width dp', (tester) async {
        size(tester, width);
        int? got;
        await tester.pumpWidget(
          host(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(KSpacing.page),
                child: KSegmented<int>(
                  segments: segments,
                  selected: 0,
                  keyPrefix: 'goal',
                  onChanged: (v) => got = v,
                ),
              ),
            ),
          ),
        );
        for (final s in segments) {
          final key = find.byKey(ValueKey('goal-${s.value}'));
          expect(key, findsOneWidget);
          final r = tester.getSize(key);
          expect(r.width, greaterThanOrEqualTo(KSize.target - .01));
          expect(r.height, greaterThanOrEqualTo(KSize.target - .01));
        }
        await tester.tap(find.byKey(const ValueKey('goal-4')));
        expect(got, 4);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('grand texte : choix l’un sous l’autre, rien de coupé', (
      tester,
    ) async {
      size(tester, 320, 1200);
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(KSpacing.page),
              child: KSegmented<int>(
                segments: segments,
                selected: 2,
                onChanged: (_) {},
              ),
            ),
          ),
          scale: 2,
        ),
      );
      expectWhole(tester, find.text('Adaptatif'));
      expect(tester.takeException(), isNull);
    });
  });

  group('feuilles et confirmation', () {
    testWidgets('confirmation : message long qui défile, boutons visibles, '
        'clés par bouton', (tester) async {
      size(tester, 320, 480);
      bool? got;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => got = await showKConfirm(
                    context,
                    title: 'Supprimer toutes les données ?',
                    message: List.filled(
                      12,
                      'Ton journal, ton programme et tes réglages seront '
                      'effacés de ce téléphone.',
                    ).join(' '),
                    confirmLabel: 'Supprimer',
                    destructive: true,
                    confirmKey: const ValueKey('wipe-ok'),
                    cancelKey: const ValueKey('wipe-cancel'),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final ok = find.byKey(const ValueKey('wipe-ok'));
      expect(find.byKey(const ValueKey('wipe-cancel')), findsOneWidget);
      expect(tester.getBottomLeft(ok).dy, lessThanOrEqualTo(480));
      await tester.tap(ok);
      await tester.pumpAndSettle();
      expect(got, isTrue);
    });

    testWidgets('feuille de contenu : titre, contenu, « Fermer »', (
      tester,
    ) async {
      size(tester, 390, 844);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showKContentSheet<void>(
                    context,
                    title: 'Semaine 9',
                    subtitle: 'Bloc 2, semaine 3 sur 8',
                    contentKey: const ValueKey('content'),
                    children: (_) => [
                      for (var i = 0; i < 30; i++) Text('Ligne $i'),
                    ],
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byType(KContentSheet), findsOneWidget);
      expect(find.text('Semaine 9'), findsOneWidget);
      // Fermer reste visible, même avec un contenu plus long que l'écran.
      final close = find.byKey(const ValueKey('sheet-close'));
      expect(tester.getBottomLeft(close).dy, lessThanOrEqualTo(844));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(KContentSheet), findsNothing);
    });

    testWidgets('feuille de liste ouverte sur l’élément courant', (
      tester,
    ) async {
      size(tester, 390, 844);
      int? got;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => got = await showKListSheet(
                    context,
                    title: 'Choisir une semaine',
                    initial: 30,
                    items: [
                      for (var i = 1; i <= 40; i++)
                        KListItem(
                          'Semaine $i',
                          state: i == 31 ? KListState.current : KListState.todo,
                        ),
                    ],
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      final current = find.text('Semaine 31');
      expect(current, findsOneWidget);
      expect(tester.getRect(current).bottom, lessThan(844));
      await tester.tap(current);
      await tester.pumpAndSettle();
      expect(got, 30);
    });
  });

  group('divers', () {
    testWidgets('bouton-icône désactivé : sans fond', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Center(
              child: KIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Ajouter',
                filled: true,
              ),
            ),
          ),
        ),
      );
      final button = tester.widget<IconButton>(find.byType(IconButton));
      final bg = button.style!.backgroundColor!.resolve({WidgetState.disabled});
      expect(bg, Colors.transparent);
    });

    test('étiquette des champs dans la pilule (bord non « outline »)', () {
      final theme = kitTheme(dark: true);
      final border = theme.inputDecorationTheme.enabledBorder!;
      expect(border, isA<KFieldBorder>());
      expect(border.isOutline, isFalse);
    });

    test('dock translucide : icônes et libellé lisibles (U0.12)', () {
      // Fond du dock : `haute` à 96 % sur le contenu qui passe dessous,
      // quel qu'il soit (blanc, noir, aplat de la palette, texte).
      Color over(Color top, double a, Color under) => Color.from(
        alpha: 1,
        red: top.r * a + under.r * (1 - a),
        green: top.g * a + under.g * (1 - a),
        blue: top.b * a + under.b * (1 - a),
      );
      for (final source in kPaletteSources) {
        for (final dark in [true, false]) {
          for (final contrast in [false, true]) {
            final r = KRoles.of(source.id, dark: dark, contrast: contrast);
            // Icônes des onglets repliés (élément graphique, critère
            // 1.4.11 : 3:1, 4,5:1 en contraste renforcé) : on exige 4,5:1
            // dans les deux modes, le niveau du texte courant.
            const need = 4.5;
            for (final under in [
              const Color(0xFFFFFFFF),
              const Color(0xFF000000),
              r.pleine,
              r.texte,
              r.fond,
            ]) {
              // Opaque en contraste renforcé (lib/kit/dock.dart).
              final bg = over(r.haute, contrast ? 1 : .96, under);
              expect(
                kContrast(r.texte2, bg),
                greaterThanOrEqualTo(need - .05),
                reason:
                    '${source.id} ${dark ? 'sombre' : 'clair'} '
                    '${contrast ? 'renforcé ' : ''}icône sur $under',
              );
            }
            // Libellé de l'onglet actif : `surPleine` sur la pilule opaque.
            expect(
              kContrast(r.surPleine, r.pleine),
              greaterThanOrEqualTo(4.5),
              reason: source.id,
            );
          }
        }
      }
    });
  });
}
