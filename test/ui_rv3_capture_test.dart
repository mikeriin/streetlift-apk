// RV3 (dev7.7.1, C17.51.1) — rendus de test de la carte de la modulation
// de la semaine (`KoachVolumeCard`) : mode assisté (appliquée, « Annuler »),
// mode libre (proposée, « Accepter » / « Garder l'écrit »), choix fait ;
// sombre et clair × `bordeaux` et `violet`, 390 dp. Lancé par la CI avec
// --dart-define=KALIS_CAPTURE=true ; fichiers validation/UI/rv3_<état>_
// <palette>_<thème>.png, recopiés dans ci-out/captures-ui/. Données
// synthétiques (programme PR2), modulation forcée sur le plan de Koach.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart' show Exercise;
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();
  var clock = DateTime(2026, 10, 20, 7); // mardi, S15·J2

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    store.storeClock = () => clock;
    await store.init();
    await importPr2Nouveau(store, firstWeek: 12);
    store.koachNoteInstall();
    await store.koachRefresh();
    await loadUiFonts();
  });
  tearDownAll(() => debugKoachBasculeAutorisee = false);

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    required bool dark,
    required String palette,
  }) async {
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          home: home,
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: name);
    if (uiCaptureEnabled) {
      await saveUiPng(tester, root, name, pixelRatio: 1.5);
    }
  }

  const variants = [(true, 'bordeaux'), (false, 'violet')];
  String suffix(bool dark, String p) => '${p}_${dark ? 'sombre' : 'clair'}';

  /// Séance S15·J[j] servie par Koach, modulation de la semaine forcée ;
  /// rend une ligne modulée (null : aucune).
  Future<Exercise?> servir(WidgetTester tester, int j) async {
    clock = DateTime(2026, 10, 18 + j, 7);
    final base = store.program.week(15).day(j)!;
    await tester.runAsync(() async {
      await store.koachRefresh();
      final pl = store.koachLive!.planification!;
      pl.plan[14] = {
        ...?pl.plan[14],
        'volume': List<double>.filled(10, 0.4),
        'intensite': 0.0,
      };
      store.adaptOpen(15, base);
      await store.koachStart(15, base);
    });
    final a = store.sessionAdapt(15, j)!;
    return store
        .adaptDay(15, base, a)
        .exercises
        .where((x) => store.koachVolume(15, j, x) != null)
        .firstOrNull;
  }

  Widget card(int j, Exercise x) => Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(x.name),
        KoachVolumeCard(
          week: 15,
          day: store.program.week(15).day(j)!,
          exercise: x,
          onChanged: () {},
        ),
      ],
    ),
  );

  testWidgets('carte de la modulation : assisté (lundi), libre (mardi), '
      'choix fait', (tester) async {
    final e1 = await servir(tester, 1);
    expect(e1, isNotNull, reason: 'lundi : aucune ligne modulée');
    for (final (dark, p) in variants) {
      await show(tester, card(1, e1!), dark: dark, palette: p);
      expect(
        find.byKey(ValueKey('koach-volume-undo-${e1.id}')),
        findsOneWidget,
      );
      await shot(tester, 'rv3_assiste_${suffix(dark, p)}');
    }
    store.setGuidanceMode('free');
    final e2 = await servir(tester, 2);
    expect(e2, isNotNull, reason: 'mardi : aucune ligne modulée');
    final id = e2!.id;
    for (final (dark, p) in variants) {
      await show(tester, card(2, e2), dark: dark, palette: p);
      expect(find.byKey(ValueKey('koach-volume-accept-$id')), findsOneWidget);
      expect(find.byKey(ValueKey('koach-volume-keep-$id')), findsOneWidget);
      await shot(tester, 'rv3_libre_${suffix(dark, p)}');
    }
    await tester.tap(find.byKey(ValueKey('koach-volume-accept-$id')));
    await tester.pump();
    for (final (dark, p) in variants) {
      await show(tester, card(2, e2), dark: dark, palette: p);
      expect(find.byKey(ValueKey('koach-volume-done-$id')), findsOneWidget);
      expect(find.textContaining('Accepté'), findsOneWidget);
      await shot(tester, 'rv3_accepte_${suffix(dark, p)}');
    }
    store.setGuidanceMode('assisted');
  });
}
