// M56 (mannequin 3D) — préchargement du mannequin au lancement : lancé une
// seule fois, sans effet quand il est désactivé (mesure de référence), sans
// Flutter GPU (moteur de test) il conclut « rien à précharger » sans
// exception ; mesure de l'ouverture d'un mannequin ; carte « Préchargement »
// de l'écran Moteur 3D. Le préchauffage réel (Scene.warmUp) est mesuré sur
// émulateur (integration_test/animations_m56_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/mannequin_preload.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
  });

  setUp(() {
    MannequinPreload.reset();
    MannequinPreload.enabled = true;
  });

  test('désactivé : aucun préchargement', () async {
    MannequinPreload.enabled = false;
    await MannequinPreload.start();
    expect(MannequinPreload.done, isFalse);
    expect(MannequinPreload.report, isNull);
  });

  test('sans Flutter GPU : terminé, rien à précharger, une seule fois',
      () async {
    final first = MannequinPreload.start();
    final second = MannequinPreload.start();
    expect(identical(first, second), isTrue);
    await first;
    expect(MannequinPreload.done, isTrue);
    final r = MannequinPreload.report!;
    expect(r.compatible, isFalse);
    expect(r.warmUpMs, -1);
    expect(r.totalMs, r.loadMs);
  });

  test('ouverture d’un mannequin : première image et images perdues',
      () async {
    final timer = OpenTimer();
    timer.firstImage();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final open = MannequinPreload.lastOpen.value;
    expect(open, isNotNull);
    expect(open!.firstImageMs, greaterThanOrEqualTo(0));
    expect(open.lostFrames, lessThanOrEqualTo(open.frames));
    expect(open.preloaded, isFalse);
    timer.cancel();
  });

  test('ouverture annulée (repli 2D) : aucune mesure', () async {
    final timer = OpenTimer();
    timer.cancel();
    timer.firstImage();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(MannequinPreload.lastOpen.value, isNull);
  });

  testWidgets('écran Moteur 3D : carte « Préchargement »', (tester) async {
    await MannequinPreload.start();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Engine3DScreen(autoMeasure: false),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('engine3d-preload')), findsOneWidget);
    expect(find.text('Rien à précharger sans moteur 3D.'), findsOneWidget);
  });
}
