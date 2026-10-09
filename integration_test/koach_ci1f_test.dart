// CI1f (dev6.11.0, pipeline CP, DECISIONS_CP.md C11.6) sur émulateur
// Android, lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_ci1f_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : programme de 40 semaines du propriétaire commencé il
// y a 19 semaines (aujourd'hui S20·J1), profil d'exemple en mode assisté.
// Séance du jour : myo-reps saisis mini-série par mini-série (activation
// puis mini-séries, mini-repos lancé, total calculé), série validée ;
// séance de S20·J3 : contraste affiché comme un groupe (3 tours, chrono,
// résultat du groupe).
// Relevé `ci1f_releve_<partie>.json`, captures `ci1f_*_<thème>.png`.
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
import 'package:streetlift_tracker/main.dart';
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

  void record() => data['ci1f_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ci1f_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (final dy in const [-250.0, 250.0]) {
      for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
        final lists = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable();
        if (lists.evaluate().isEmpty) break;
        final s = tester.state<ScrollableState>(lists.last).position;
        if ((dy < 0 && s.pixels >= s.maxScrollExtent) ||
            (dy > 0 && s.pixels <= s.minScrollExtent)) {
          break;
        }
        await tester.drag(lists.last, Offset(0, dy));
        await wait(tester, 300);
      }
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.last);
      await wait(tester, 400);
    }
  }

  Future<void> tapF(WidgetTester tester, Finder f, {int ms = 800}) async {
    await scrollTo(tester, f);
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  Finder keyStarts(String prefix) => find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> && k.value.startsWith(prefix);
  });

  Finder tip(bool Function(String m) test) => find.byWidgetPredicate(
    (w) => w is Tooltip && w.message != null && test(w.message!),
  );

  /// Séance ouverte, bilan passé, premier exercice ; puis pages suivantes
  /// jusqu'à [target] (au plus 12 pages).
  Future<bool> openTo(WidgetTester tester, int w, int j, Finder target) async {
    final week = store.program.week(w);
    final day = week.day(j)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 800);
    final skip = find.byKey(const ValueKey('feel-skip'));
    if (skip.evaluate().isNotEmpty) await tapF(tester, skip, ms: 1200);
    final start = find.byKey(const ValueKey('bilan-start'));
    if (await until(tester, start, max: 40)) {
      await tapF(tester, start, ms: 1500);
    }
    for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
      final pages = find.byType(PageView);
      if (pages.evaluate().isEmpty) break;
      await tester.drag(pages.first, const Offset(-360, 0));
      await wait(tester, 900);
    }
    return target.evaluate().isNotEmpty;
  }

  testWidgets('CI1f $_part ($theme, $accent) : myo-reps mini-série par '
      'mini-série ; contraste en groupe', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(
      DateTime(real.year, real.month, real.day - 19 * 7),
    );
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 140))),
          guidance: kc.GuidanceMode.assisted,
          // Myo-reps servis comme tels à partir du niveau avancé.
        ).copyWith(experience: kc.ExperienceLevel.advanced),
      )..consent = 'refused',
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );
    final now = store.storeClock();
    final w = store.program.weekFor(now);
    final j = store.program.offsetOf(now)! % 7 + 1;
    releve['jour'] = 'S$w-J$j';
    final imp = store.importedProgram;
    releve['absents'] = imp?.absent;
    await shot('01_accueil');

    // 1. Myo-reps (S20·J1, curl à la barre EZ).
    final add = keyStarts('miniset-add-');
    releve['myo_page'] = await openTo(tester, w, j, add);
    if (add.evaluate().isNotEmpty) {
      await scrollTo(tester, add);
      await shot('02_myo_avant');
      for (var i = 0; i < 4; i++) {
        if (add.hitTestable().evaluate().isEmpty) await scrollTo(tester, add);
        if (add.evaluate().isEmpty) break;
        await tester.tap(add.hitTestable().first);
        await wait(tester, 700);
      }
      releve['myo_parties'] = keyStarts('miniset-part-').evaluate().length;
      releve['myo_conseil'] = (tester.widget<Text>(
        keyStarts('miniset-advice-').first,
      )).data;
      releve['chrono_intra'] = store.settings.autoTimer;
      await scrollTo(tester, keyStarts('miniset-advice-'));
      await shot('03_myo_mini_series');
      // Série validée : une ligne, total des mini-séries.
      final check = tip((m) => m.startsWith('Valider la série'));
      if (check.evaluate().isNotEmpty) {
        await tapF(tester, check, ms: 1200);
      }
      final log = store.logs[store.sessionKey(w, j)];
      final sets = [
        for (final x in log?.ex.values ?? const <ExerciseLog>[])
          for (final s in x.sets)
            if (s.parts != null) s,
      ];
      releve['myo_serie'] = sets.isEmpty
          ? null
          : {
              'reps': sets.first.reps,
              'parts': [for (final p in sets.first.parts!) p.value],
              'validee': sets.first.done,
            };
      await shot('04_myo_validee');
    }
    await home(tester);

    // 2. Contraste en groupe (S20·J3).
    final group = keyStarts('group-card-');
    final cw = w, cj = 3;
    releve['contraste_page'] = await openTo(tester, cw, cj, group);
    if (group.evaluate().isNotEmpty) {
      await scrollTo(tester, group);
      releve['groupe_titre'] = (tester.widget<Text>(
        keyStarts('group-title-').first,
      )).data;
      await shot('05_contraste_groupe');
      final plus = tip((m) => m.startsWith('Tours') && m.endsWith('un de moins'));
      if (plus.evaluate().isNotEmpty) {
        await tapF(tester, plus, ms: 600);
      }
      releve['groupe_resultat'] = store.logs[store.sessionKey(cw, cj)]?.groups
          .map((k, v) => MapEntry(k, v));
      await scrollTo(tester, keyStarts('group-rounds-'));
      await shot('06_contraste_resultat');
    }
    await home(tester);
    await store.flush();
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['accueil'], isTrue);
    expect(releve['myo_page'], isTrue);
    expect(releve['myo_parties'], 4);
    expect((releve['myo_serie'] as Map?)?['validee'], isTrue);
    expect(releve['contraste_page'], isTrue);
    expect(releve['groupe_resultat'], isNotNull);
  }, timeout: _limit);
}
