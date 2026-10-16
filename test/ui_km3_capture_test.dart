// KM3 (dev7.0.0) — rendus de test des écrans de Koach 1.0 : carte d'état
// (en attente de la bascule, active, arrêtée), suggestion de la séance et
// feuille des raisons d'un refus, récapitulatif de fin de bloc,
// inspecteur du mode dev ; sombre et clair × `bordeaux` et `violet`, 390 dp.
// Lancé par la CI avec --dart-define=KALIS_CAPTURE=true ; fichiers
// validation/UI/km3_<écran>_<palette>_<thème>.png, recopiés dans
// ci-out/captures-ui/.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/koach_inspector.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();
  var clock = DateTime(2026, 11, 17, 9); // mardi, S19·J2

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    store.storeClock = () => clock;
    await store.init();
    final b = filledBackup(store);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    logs.removeWhere((k, _) {
      final w = int.parse(k.substring(1, k.indexOf('-')));
      return w > 14;
    });
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    await store.importAll(jsonEncode(b));
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(clock),
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
    double height = 1400,
  }) async {
    tester.view.physicalSize = Size(390, height);
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

  const page = KPage.sub(
    key: ValueKey('koach-engine-page'),
    title: 'Koach 1.0',
    children: [KoachEngineCard()],
  );
  const variants = [(true, 'bordeaux'), (false, 'violet')];
  String suffix(bool dark, String p) => '${p}_${dark ? 'sombre' : 'clair'}';

  testWidgets('carte de Koach : en attente de la bascule', (tester) async {
    for (final (dark, p) in variants) {
      await show(tester, page, dark: dark, palette: p);
      expect(
        find.byKey(const ValueKey('koach-engine-waiting')),
        findsOneWidget,
      );
      await shot(tester, 'km3_attente_${suffix(dark, p)}');
    }
  });

  testWidgets('Koach actif : carte, suggestion, refus, récapitulatif, '
      'inspecteur, arrêt', (tester) async {
    await tester.runAsync(() async {
      store.koachForceBascule(civilOf(clock));
      await store.koachRefresh();
    });
    expect(store.koachEngine.snap, isNotNull);
    for (final (dark, p) in variants) {
      await show(tester, page, dark: dark, palette: p);
      expect(find.byKey(const ValueKey('koach-engine-active')), findsOneWidget);
      await shot(tester, 'km3_actif_${suffix(dark, p)}');
    }
    // Séance du jour servie par Koach, suggestion posée sur la première
    // série du premier exercice.
    final week = store.program.week(19);
    var j = 2;
    while (week.day(j)?.exercises.isEmpty ?? true) {
      j++;
    }
    final base = week.day(j)!;
    store.adaptOpen(19, base);
    await tester.runAsync(() => store.koachStart(19, base));
    final a = store.sessionAdapt(19, j)!;
    final served = store.adaptDay(19, base, a).exercises;
    expect(
      served.any((x) => x.engine && x.slotId != null),
      isTrue,
      reason:
          'S19·J$j : ${a.koach?['state']} · ${store.koachPending(19, j)} · '
          '${store.koachOpen(19, j)} · ${[for (final x in served) '${x.engine}/${x.slotId}']}',
    );
    final e = served.firstWhere((x) => x.engine && x.slotId != null);
    final st = Map<String, Object?>.of(a.koach!);
    st['cibles'] = {
      e.slotId!: {
        '0': {
          'loadKg': 85.0,
          'repsLow': 3,
          'repsHigh': 3,
          'flames': 8,
          'proposition': {
            'type': 'charge_plus',
            'depart': 80.0,
            'cible': 85.0,
            'pas': 2.5,
            'ampleur': 2.0,
            'paliers': [82.5, 85.0],
            'moment': 'entre_series',
          },
        },
      },
    };
    store.sessionLog(19, j).adapt = a
        .copyWith(koach: st)
        .toJson()
        .cast<String, dynamic>();
    Widget card() => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KoachSuggestionCard(
            week: 19,
            day: base,
            exercise: e,
            onChanged: () {},
          ),
        ],
      ),
    );
    for (final (dark, p) in variants) {
      await show(tester, card(), dark: dark, palette: p, height: 600);
      expect(find.byKey(ValueKey('koach-suggestion-${e.id}')), findsOneWidget);
      await shot(tester, 'km3_suggestion_${suffix(dark, p)}');
      await tester.tap(find.byKey(ValueKey('koach-refuse-${e.id}')));
      await shot(tester, 'km3_refus_${suffix(dark, p)}');
      expect(find.text('Trop lourd'), findsOneWidget);
    }
    for (final (dark, p) in variants) {
      await show(tester, const KoachRecapScreen(), dark: dark, palette: p);
      await shot(tester, 'km3_recap_${suffix(dark, p)}');
      await show(
        tester,
        const KoachInspectorScreen(),
        dark: dark,
        palette: p,
        height: 3000,
      );
      await shot(tester, 'km3_inspecteur_${suffix(dark, p)}');
    }
    store.koachStop();
    for (final (dark, p) in variants) {
      await show(tester, page, dark: dark, palette: p);
      expect(
        find.byKey(const ValueKey('koach-engine-stopped')),
        findsOneWidget,
      );
      await shot(tester, 'km3_arret_${suffix(dark, p)}');
    }
  });
}
