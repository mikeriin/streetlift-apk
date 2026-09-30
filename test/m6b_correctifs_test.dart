// M6b (mannequin 3D) : correctifs d'affichage et d'usage du mannequin fixe.
// Voir docs/AUDIT_M6b.md (une ligne par défaut, correction et test).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
    await MannequinMap.load();
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  Future<void> settle(WidgetTester tester, Finder ready) async {
    for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(ready, findsWidgets);
  }

  group('D1 · Anatomie : filtre « Muscles profonds » retiré', () {
    test('M8 : plus de catégorie Affichage (ni « Os »), 15 groupes', () {
      expect(
        AnatomyFilters.categories.where((c) => c.id == 'affichage'),
        isEmpty,
      );
      expect(AnatomyFilters.total, 15);
      expect(AnatomyFilters.all.count, 15);
      // L'écorché n'a aucune région profonde : le filtre n'avait pas d'effet.
      expect(MannequinMap.loaded!.deepIds, isEmpty);
    });

    testWidgets('menu, résumé et libellé d’accessibilité', (tester) async {
      phone(tester);
      AnatomyScreen.session = null;
      await tester.pumpWidget(
        page(const AnatomyScreen(initialGroup: 'dorsaux')),
      );
      await settle(tester, find.byType(MuscleMap2D));
      expect(find.text('Filtres · 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('anatomy-filters')));
      await tester.pumpAndSettle();
      expect(find.text('Muscles profonds'), findsNothing);
      expect(find.byKey(const ValueKey('anatomy-filter-bones')), findsNothing);
      expect(
        find.byKey(const ValueKey('anatomy-filter-dorsaux')),
        findsWidgets,
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      // D2 : plus de « en rouge » (M8 : couleur dominante).
      final label = tester
          .widget<MuscleMap2D>(find.byType(MuscleMap2D))
          .semanticLabel;
      expect(label, contains('Dorsaux'));
      expect(label, isNot(contains('rouge')));
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('anatomy-group-list')),
      );
      expect(find.textContaining('Muscles profonds'), findsNothing);
      expect(find.textContaining('(profond)'), findsNothing);
      expect(find.text('Os affichés'), findsNothing);
      expect(find.textContaining('Grand dorsal'), findsWidgets);
      AnatomyScreen.session = null;
    });
  });

  testWidgets('D6 · légende des rôles : pastilles en halo sur le mannequin', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        const Scaffold(
          body: Column(
            children: [
              AtlasRoleLegend(key: ValueKey('plein')),
              AtlasRoleLegend(
                key: ValueKey('halo'),
                stretchColor: Color(0xFF5B8DB0),
                haloAlpha: MannequinHaloPainter.alphaFor,
                haloBase: kMuscleGray,
              ),
            ],
          ),
        ),
      ),
    );
    List<BoxDecoration> swatches(String key) => [
      for (final c in tester.widgetList<Container>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Container),
        ),
      ))
        c.decoration! as BoxDecoration,
    ];
    final plain = swatches('plein');
    expect(plain.first.color, heat(1));
    expect(plain.first.boxShadow, isNull);
    final halo = swatches('halo');
    expect(halo, hasLength(4));
    // Principal : halo de la couleur dominante à l'opacité du mannequin,
    // posé sur le gris des muscles, avec un flou autour.
    final glow = heat(1).withValues(alpha: MannequinHaloPainter.alphaFor(1));
    expect(halo.first.color, Color.alphaBlend(glow, kMuscleGray));
    expect(halo.first.boxShadow!.single.color, glow);
    // Plus l'intensité baisse, plus le halo est discret.
    expect(
      halo[1].boxShadow!.single.color.a,
      lessThan(halo[0].boxShadow!.single.color.a),
    );
    // Étiré : teinte froide.
    expect(
      halo.last.boxShadow!.single.color,
      const Color(
        0xFF5B8DB0,
      ).withValues(alpha: MannequinHaloPainter.alphaFor(kIntensityStretched)),
    );
  });

  test('D7 · aires des régions lues dans la carte', () async {
    final raw = await rootBundle.loadString(kMannequinMapAsset);
    expect(raw, contains('"aire"'));
    final map = MannequinMap.loaded!;
    // M6c : aires vues de face et de dos (peau du personnage) : grand
    // dorsal vu de dos au moins 1,65 × biceps vu de face (traction : Dos).
    expect(raw, contains('"aire_face"'));
    final lat = map.byId['latissimus_dorsi_left']!;
    final biceps = map.byId['biceps_brachii_left']!;
    expect(lat.aire, greaterThan(biceps.aire));
    expect(lat.aireDos, greaterThan(kStartViewDominance * biceps.aireFace));
    expect(map.byId['rectus_abdominis_left']!.aireDos, 0);
  });
}
