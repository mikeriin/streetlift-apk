// CI1g (dev6.11.1, pipeline CP, DECISIONS_CP.md C11.7) sur émulateur
// Android, lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/clearance_ci1g_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle (programme de 40 semaines du propriétaire) : séance
// du jour ouverte sans étape d'avis médical. Session de test (5 appuis) :
// profil street avec une gêne de l'épaule déclarée à 6/10 (consentement
// santé donné), programme du chemin calibré (`kalis_plan` 0.3.1, note
// `clearance_first`) ; première séance : étape « Avis médical d'abord »,
// « Pas encore » → rappel en tête de la séance, « J'ai eu l'avis » → plus
// rien ; suppression de la session de test, session personnelle intacte.
// Relevé `ci1g_releve_<partie>.json`, captures `ci1g_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
  };
  binding.reportData = data;

  void record() => data['ci1g_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ci1g_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> opened(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
          i > 25) {
        break;
      }
    }
    await wait(tester, 1000);
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 120}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  /// Prochaine journée servie par le moteur à partir d'aujourd'hui.
  (int, int)? nextDay() {
    final now = store.storeClock();
    for (var k = 0; k < 21; k++) {
      final d = DateTime(now.year, now.month, now.day + k);
      if (!store.program.containsDate(d)) continue;
      final w = store.program.weekFor(d);
      final j = store.program.offsetOf(d)! % 7 + 1;
      final day = store.program.week(w).day(j);
      if (day == null || day.exercises.isEmpty) continue;
      if (store.adaptPlaceOf(w, j) == null) continue;
      return (w, j);
    }
    return null;
  }

  Future<void> openSession(WidgetTester tester, int w, int j) async {
    final week = store.program.week(w);
    final day = week.day(j)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('health-page')));
    await wait(tester, 1500);
  }

  testWidgets('CI1g $_part ($theme, $accent) : avis médical avant la '
      'première séance', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 20))),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['perso_accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );

    // 1. Session personnelle : aucune étape d'avis médical.
    final perso = nextDay();
    releve['perso_jour'] = perso == null ? null : 'S${perso.$1}-J${perso.$2}';
    if (perso != null) {
      await openSession(tester, perso.$1, perso.$2);
      releve['perso_sans_etape'] =
          find.byKey(const ValueKey('clearance-dialog')).evaluate().isEmpty &&
          find.byKey(const ValueKey('clearance-card')).evaluate().isEmpty;
      await shot('01_perso_seance');
      await home(tester);
    }
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 2. Session de test : gêne de l'épaule déclarée à 6/10.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    final base = sampleStreetProfile(
      on: civilOf(store.storeClock()),
      beginner: !dark,
    );
    store.saveAthleteProfile(
      ProfileDraft.of(
        base.copyWith(
          limitations: const [
            kc.Limitation(
              zone: kc.BodyZone.shoulder,
              side: kc.BodySide.right,
              joint: kc.Joint.shoulder,
              discomfort: 6,
              since: kc.ConstraintSince.months3To12,
            ),
          ],
        ),
      )..consent = 'given',
    );
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    await store.flush();
    await wait(tester, 1200);
    final dev = nextDay();
    releve['dev_jour'] = dev == null ? null : 'S${dev.$1}-J${dev.$2}';
    if (dev != null) {
      final (w, j) = dev;
      releve['dev_note_du_bloc'] = store.clearancePending(w, j) != null;
      await openSession(tester, w, j);
      releve['dev_etape'] = await until(
        tester,
        find.byKey(const ValueKey('clearance-dialog')),
        max: 40,
      );
      await shot('02_dev_etape');
      final notYet = find.byKey(const ValueKey('clearance-not-yet'));
      if (notYet.evaluate().isNotEmpty) {
        await tester.tap(notYet.first);
        await wait(tester, 1200);
      }
      releve['dev_rappel'] = find
          .byKey(const ValueKey('clearance-card'))
          .evaluate()
          .isNotEmpty;
      await shot('03_dev_rappel');
      final ok = find.byKey(const ValueKey('clearance-card-confirm'));
      if (ok.evaluate().isNotEmpty) {
        await tester.ensureVisible(ok.first);
        await wait(tester, 400);
        await tester.tap(ok.first);
        await wait(tester, 1200);
      }
      releve['dev_confirme'] =
          find.byKey(const ValueKey('clearance-card')).evaluate().isEmpty &&
          store.clearancePending(w, j) == null;
      await shot('04_dev_confirme');
      await home(tester);
    }

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      final del = find.byKey(const ValueKey('dev-delete'));
      await tester.ensureVisible(del.first);
      await wait(tester, 400);
      await tester.tap(del.hitTestable().first);
      await wait(tester, 800);
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      await wait(tester, 600);
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    await store.flush();
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_accueil'], isTrue);
    expect(releve['perso_sans_etape'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_note_du_bloc'], isTrue);
    expect(releve['dev_etape'], isTrue);
    expect(releve['dev_rappel'], isTrue);
    expect(releve['dev_confirme'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
