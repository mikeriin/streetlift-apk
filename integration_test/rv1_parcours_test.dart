// RV1 (dev7.5.0, DECISIONS_CP.md C17.41) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/rv1_parcours_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, palette bordeaux, taille d'affichage 90 % ;
// b = thème clair, palette neon, taille d'affichage 110 %.
// Session personnelle : sauvegarde synthétique de la forme de celle du
// propriétaire après PR2 (ancien programme au journal, trois semaines
// d'historique S12 à S14, nouveau programme à partir de S15 = S1 affichée,
// semaine type `kb2c1_semaine.dart` : six séances en PPL, E2MOM avec ligne
// enchaînée, finisher en superset, intervalles, GtG hors séance, drop sets,
// squat à charge fixe) ; jamais l'export réel (C17.33.2).
// Une semaine complète : J1 et J2 servies par Koach ; arrêt d'urgence ;
// J3 et J4 telles qu'écrites (intervalles une ligne par tour, EMOM minute
// par minute, drop set) ; réactivation ; J5 et J6 servies par Koach (charge
// fixe du squat à 70 kg). Chaque page de chaque séance capturée, accueil,
// Mon programme, Stats et Réglages ; sauvegarde exportée puis réimportée à
// l'identique. Relevé `rv1_releve_<partie>.json`, captures
// `rv1_*_<partie>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/home_screen.dart' show openProgramDay;
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/program_screens.dart' show ProgramScreen;
import 'package:streetlift_tracker/settings_screen.dart' show SettingsScreen;
import 'package:streetlift_tracker/stats_screen.dart' show StatsScreen;
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';
import 'kb2c1_semaine.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 9));

Future<Map<String, dynamic>> _asset(String name) async {
  final bytes = await rootBundle.load('assets/$name');
  return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
      as Map<String, dynamic>;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final palette = dark ? 'bordeaux' : 'neon';
  final size = dark ? 90 : 110;
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'palette': palette,
    'taille': size,
  };
  final shots = <String>[];
  binding.reportData = data;

  void record() => data['rv1_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['rv1_${name}_$_part.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    shots.add(name);
    releve['captures'] = shots;
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 120}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
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

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  /// Bilan « Bien » puis les écrans d'ajustement, jusqu'au début de la
  /// séance (servie par Koach, ou écrite : « Premier exercice ») ; un
  /// popup est fermé (« Plus tard »).
  Future<void> begin(WidgetTester tester, int w, int j, bool koach) async {
    await until(tester, find.byKey(const ValueKey('health-question')), max: 40);
    await wait(tester, 600);
    final feel = find.byKey(const ValueKey('feel-4')).hitTestable();
    if (feel.evaluate().isNotEmpty) {
      await tester.tap(feel.first);
      await wait(tester, 900);
    }
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < 60000) {
      if (koach &&
          (store.koachOpen(w, j) || store.koachAnswerRefused(w, j)) &&
          find
              .byKey(const ValueKey('health-question'))
              .hitTestable()
              .evaluate()
              .isEmpty) {
        break;
      }
      if (find
          .byKey(const ValueKey('koach-diag-start'))
          .hitTestable()
          .evaluate()
          .isNotEmpty) {
        await tester.binding.handlePopRoute();
        await wait(tester, 900);
        continue;
      }
      var tapped = false;
      for (final k in const ['adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k)).hitTestable();
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          await wait(tester, 300);
          tapped = true;
        }
      }
      if (!koach && !tapped) break;
      await wait(tester, 250);
    }
    await wait(tester, 800);
  }

  /// Valide toutes les séries de S[w]·J[j] (séance servie ou écrite), puis
  /// la marque faite.
  void doAll(int w, int j) {
    final base = store.program.week(w).day(j)!;
    final a = store.sessionAdapt(w, j);
    final day = a == null ? base : store.adaptDay(w, base, a);
    for (final e in day.exercises) {
      final log = store.exLog(w, j, e);
      for (var i = 0; i < log.sets.length; i++) {
        if (log.sets[i].done) continue;
        if (e.engine) {
          store.koachEnsureTarget(w, base, e, i);
          store.adaptPrefill(w, j, e, log);
        }
        final s = log.sets[i];
        if (s.reps.isEmpty) s.reps = '5';
        s.flames = 8;
        if (!store.toggleSet(log, i, store.logSpec(e)).ok) {
          s.reps = '5';
          store.toggleSet(log, i, store.logSpec(e));
        }
        if (e.engine) store.koachAfterSet(w, base, e, i);
      }
    }
    store.markSessionDone(w, j, true);
  }

  Future<void> dayOffset(WidgetTester tester, kc.CivilDate d) async {
    final now0 = KalisClock.now().subtract(
      Duration(days: KalisClock.offsetDays),
    );
    final offset =
        DateTime(
          d.year,
          d.month,
          d.day,
        ).difference(DateTime(now0.year, now0.month, now0.day)).inHours ~/
        24;
    KalisClock.setOffsetDays(offset);
    await wait(tester, 300);
  }

  /// Ouvre S[wk]·J[j], passe le bilan, capture chaque page de la séance,
  /// revient à l'accueil puis fait la séance.
  Future<void> visit(
    WidgetTester tester,
    int wk,
    int j,
    kc.CivilDate monday, {
    required bool koach,
  }) async {
    await dayOffset(tester, monday.addDays(j - 1));
    await store.koachRefresh();
    await wait(tester, 600);
    final w = store.program.week(wk);
    final base = w.day(j)!;
    if (j == 3) await shot('accueil_j3_gtg');
    unawaited(openProgramDay(appNavigator.currentState!, w, base));
    await wait(tester, 1200);
    await begin(tester, wk, j, koach);
    final a = store.sessionAdapt(wk, j);
    final day = a == null ? base : store.adaptDay(wk, base, a);
    final pages = store.groups(day, week: wk);
    final rel = <String, Object?>{
      'koach': store.koachOpen(wk, j),
      'pages': pages.length,
      'cartes': [
        for (final g in pages)
          [
            for (final e in g)
              '${store.splitName(e.name).$1} · ${store.setsLabel(e)} · '
                  '${store.setCount(e)} lignes · '
                  '${store.logSpec(e).kind}${store.logSpec(e).rowPrefix}',
          ],
      ],
    };
    for (var p = 0; p < pages.length; p++) {
      await shot('j${j}_page${p + 1}');
      if (p == pages.length - 1) break;
      final pv = find.byType(PageView);
      if (pv.evaluate().isEmpty) break;
      await tester.fling(pv.first, const Offset(-320, 0), 1600);
      await wait(tester, 900);
    }
    rel['exceptions'] = '${tester.takeException() ?? ''}';
    await home(tester);
    doAll(wk, j);
    rel['faite'] = store.logs[store.sessionKey(wk, j)]?.done ?? false;
    releve['j$j'] = rel;
    record();
  }

  Future<void> screen(WidgetTester tester, Widget w, String name) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => w),
      ),
    );
    await wait(tester, 1800);
    await shot(name);
    await home(tester);
  }

  testWidgets('RV1 $_part ($theme, $palette, $size %) : une semaine du '
      'programme PR2, Koach actif, arrêté puis réactivé ; sauvegarde '
      'exportée puis réimportée', (tester) async {
    KalisClock.setOffsetDays(0);
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = palette;
    seed.settings.displaySize = size;
    seed.saveSettings();
    final b = filledBackup(seed);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    // Trois semaines d'historique (S12 à S14).
    logs.removeWhere((k, _) {
      final w = int.parse(k.substring(1, k.indexOf('-')));
      return w < 12 || w > 14;
    });
    final base = await _asset('programme_v33.json.gz');
    final koach = await _asset('koach_program.json.gz');
    b['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test-rv1',
      'seed': 0,
      'weeks': [
        for (final w in (base['weeks'] as List).take(14))
          (w as Map).cast<String, dynamic>(),
        for (var n = 15; n <= 24; n++)
          (jsonDecode(kKb2c1Semaine) as Map<String, dynamic>)
            ..['n'] = n
            ..['blockKey'] = n <= 19 ? 'NA' : 'NB',
      ],
      'koach': {
        'exercises': koach['exercises'],
        'weeks': {
          for (final e in (koach['weeks'] as Map).entries)
            if (int.parse('${e.key}') <= 14) '${e.key}': e.value,
        },
      },
      'summary': {'firstShownWeek': 15},
      'cycle': 1,
    };
    final pilot = (b['pilotage'] as Map).cast<String, dynamic>();
    const refs = {
      'B4': 71.5,
      'B8': 55.0,
      'B9': 75.0,
      'B10': 15.0,
      'B11': 120.0,
      'B16': 10.0,
      'B17': 30.0,
      'B18': 70.0,
      'B19': 65.0,
      'B20': 35.0,
    };
    for (final e in refs.entries) {
      pilot.putIfAbsent(e.key, () => e.value);
    }
    b['pilotage'] = pilot;
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    releve['import'] = await seed.importAll(jsonEncode(b));
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    final wk = store.koachTakeoverPlanned() ?? 15;
    releve['semaine'] = wk;
    final monday = store.koachLundi!.addDays(7 * (wk - 1));
    await dayOffset(tester, monday);
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(KalisClock.now()),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await wait(tester, 600);
    await store.koachRefresh();
    releve['koach_actif'] = store.koachEngine.snap != null;
    await shot('accueil_lundi');

    // J1, J2 : servies par Koach.
    await visit(tester, wk, 1, monday, koach: true);
    await visit(tester, wk, 2, monday, koach: true);
    // Arrêt d'urgence : J3, J4 telles qu'écrites.
    store.koachStop();
    await wait(tester, 600);
    releve['arret'] = store.koachEngine.stop != null;
    await visit(tester, wk, 3, monday, koach: false);
    final j3 = store.program.week(wk).day(3)!;
    final iv = j3.exercises.firstWhere((e) => e.interval != null);
    releve['intervalles'] = {
      'label': store.setsLabel(iv),
      'lignes': store.setCount(iv),
      'journal': store.exLog(wk, 3, iv).sets.length,
      'spec': '${store.logSpec(iv).kind}${store.logSpec(iv).rowPrefix}',
    };
    await visit(tester, wk, 4, monday, koach: false);
    final mu = store.program.week(wk).day(4)!.exercises.first;
    releve['emom'] = {
      'label': store.setsLabel(mu),
      'lignes': store.setCount(mu),
      'journal': store.exLog(wk, 4, mu).sets.length,
    };
    // Réactivation ; J5, J6 servies par Koach.
    await dayOffset(tester, monday.addDays(4));
    unawaited(store.koachResume());
    for (var i = 0; i < 300 && store.koachEngine.stop != null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 300 && store.koachBusy; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    releve['reactive'] = store.koachEngine.stop == null;
    await visit(tester, wk, 5, monday, koach: true);
    await visit(tester, wk, 6, monday, koach: true);
    await shot('accueil_fin_semaine');

    // Écrans visités : Mon programme, Stats, Réglages.
    await screen(tester, const ProgramScreen(), 'mon_programme');
    await screen(tester, const StatsScreen(standalone: true), 'stats');
    await screen(tester, const SettingsScreen(), 'reglages');

    // Sauvegarde exportée puis réimportée à l'identique.
    final before = store.exportForFile(appVersion: 'rv1');
    Map<String, dynamic> sections(String t) {
      final m = Map<String, dynamic>.of(jsonDecode(t) as Map<String, dynamic>)
        ..remove('exportedAt')
        ..remove('appVersion')
        ..remove('sessionDeTest')
        ..remove('decalageJours');
      return m;
    }

    releve['reimport'] = await store.importAll(before);
    final after = store.exportForFile(appVersion: 'rv1');
    await wait(tester, 900);
    final a0 = sections(before), a1 = sections(after);
    releve['sections_differentes'] = [
      for (final k in {...a0.keys, ...a1.keys})
        if (jsonEncode(a0[k]) != jsonEncode(a1[k])) k,
    ];
    await shot('accueil_apres_import');
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    for (final j in const [1, 2, 3, 4, 5, 6]) {
      final r = releve['j$j'] as Map;
      expect(r['faite'], isTrue, reason: 'J$j');
      expect(r['exceptions'], '', reason: 'J$j');
    }
    expect((releve['j1'] as Map)['koach'], isTrue);
    expect((releve['j2'] as Map)['koach'], isTrue);
    expect(releve['arret'], isTrue);
    expect((releve['intervalles'] as Map)['lignes'], 8);
    expect((releve['intervalles'] as Map)['journal'], 8);
    expect((releve['emom'] as Map)['lignes'], 8);
    expect(releve['reactive'], isTrue);
    expect(releve['reimport'], isTrue);
    expect(releve['sections_differentes'], isEmpty);
  }, timeout: _limit);
}
