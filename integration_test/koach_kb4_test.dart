// KB4 (dev7.4.0, DECISIONS_CP.md C17.40) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_kb4_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : sauvegarde synthétique de la forme de celle du
// propriétaire après PR2 (ancien programme au journal, trois semaines
// d'historique S12 à S14, nouveau programme à partir de S15 = S1 affichée,
// semaine type `kb2c1_semaine.dart`) ; jamais l'export réel (C17.33.2).
// 1. lundi de tirage servi par Koach 1.0.7 et fait ; mardi de poussée
//    servi avec toutes ses lignes à leurs séries écrites (dip lesté E2MOM
//    8 × 3 et tractions PdC dans la pause, pompes lestées 4 × 6,
//    développé militaire 3 × 8, rotations externes 2 × 15, extension
//    triceps 3 × 12, élévations latérales 3 × 15) : capture de chaque page
//    de la séance ;
// 2. arrêt d'urgence : J4 servie telle qu'écrite, l'EMOM des muscle-ups
//    minute par minute (en-tête du départ chronométré, une ligne par
//    minute) : capture ;
// 3. carte de reprise de l'accueil (arrêt d'avant dev7.4.0) : capture,
//    « Réactiver Koach » ; Koach reprend à la première séance non faite.
// Relevé `kb4_releve_<partie>.json`, captures `kb4_*_<thème>.png`.
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

/// Structure de la séance affichée : titre de chaque carte, dans l'ordre.
List<String> _structure(int week, int j) {
  final base = store.program.week(week).day(j)!;
  final a = store.sessionAdapt(week, j);
  final day = a == null ? base : store.adaptDay(week, base, a);
  return [
    for (final g in store.groups(day, week: week))
      g.map((e) => store.splitName(e.name).$1).join(' + '),
  ];
}

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

  void record() => data['kb4_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['kb4_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
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

  /// Bilan « Bien », puis les écrans d'ajustement, jusqu'au début de la
  /// séance de Koach (60 s au plus) ; un popup est fermé (« Plus tard »).
  Future<void> begin(WidgetTester tester, int w, int j) async {
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 600);
    final feel = find.byKey(const ValueKey('feel-4')).hitTestable();
    if (feel.evaluate().isNotEmpty) {
      await tester.tap(feel.first);
      await wait(tester, 300);
    }
    final sw = Stopwatch()..start();
    while (!store.koachOpen(w, j) &&
        !store.koachAnswerRefused(w, j) &&
        sw.elapsedMilliseconds < 60000) {
      await wait(tester, 250);
      if (find
          .byKey(const ValueKey('koach-diag-start'))
          .hitTestable()
          .evaluate()
          .isNotEmpty) {
        await tester.binding.handlePopRoute();
        await wait(tester, 900);
        continue;
      }
      for (final k in const ['adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k)).hitTestable();
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          await wait(tester, 300);
        }
      }
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

  testWidgets('KB4 $_part ($theme, $accent) : Koach 1.0.7 sert le programme '
      'PR2 à ses séries écrites ; EMOM minute par minute ; reprise', (
    tester,
  ) async {
    KalisClock.setOffsetDays(0);
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
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
      'generator': 'test-kb4',
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
    releve['prevue'] = wk;
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
    releve['depuis'] = store.koachEngine.fromWeek;

    // 1. Lundi : séance de tirage servie par Koach, faite.
    final w15 = store.program.week(wk);
    final j1 = w15.day(1)!;
    store.adaptOpen(wk, j1);
    releve['j1_servie'] = await store.koachStart(wk, j1);
    final st1 = store.sessionAdapt(wk, 1)!.koach!;
    releve['j1_servis'] = {
      for (final x in st1['items'] as List)
        '${(x as Map)['exerciseId']}': x['sets'],
    };
    releve['j1_retraits'] = st1['retraits'];
    releve['j1_garde'] = st1['garde'];
    doAll(wk, 1);
    releve['j1_faite'] = store.logs[store.sessionKey(wk, 1)]?.done;

    // Mardi : séance de poussée servie par Koach, page par page.
    await dayOffset(tester, monday.addDays(1));
    await store.koachRefresh();
    final j2 = store.program.week(wk).day(2)!;
    releve['j2_ecrit'] = _structure(wk, 2);
    unawaited(openProgramDay(appNavigator.currentState!, w15, j2));
    await wait(tester, 900);
    final sw = Stopwatch()..start();
    await begin(tester, wk, 2);
    releve['j2_servie'] = store.koachOpen(wk, 2);
    releve['temps_debut_ms'] = sw.elapsedMilliseconds;
    final a2 = store.sessionAdapt(wk, 2)!;
    final st2 = a2.koach!;
    final ecrites2 = {
      for (final x in store.koachJourInfo(wk, 2)!.items)
        '${x['slotId']}': x['sets'],
    };
    final servis2 = {
      for (final x in st2['items'] as List)
        '${(x as Map)['slotId']}': x['sets'],
    };
    releve['j2_ecrites'] = ecrites2;
    releve['j2_servis'] = servis2;
    releve['j2_retraits'] = st2['retraits'];
    releve['j2_garde'] = st2['garde'];
    releve['j2_invalide'] = st2['invalide'];
    releve['j2_affiche'] = _structure(wk, 2);
    final shown2 = store.adaptDay(wk, j2, a2).exercises;
    releve['j2_cartes'] = [
      for (final e in shown2) '${e.catalogId} · ${store.setsLabel(e)}',
    ];
    releve['j2_entete'] = store.koachSessionReasons(wk, 2, max: 9);
    releve['temps'] = store.koachTemps.toJson();
    final pages = store.groups(store.adaptDay(wk, j2, a2), week: wk).length;
    releve['j2_pages'] = pages;
    for (var p = 0; p < pages; p++) {
      await shot('1_poussee_page${p + 1}');
      if (p == pages - 1) break;
      final pv = find.byType(PageView);
      if (pv.evaluate().isEmpty) break;
      await tester.fling(pv.first, const Offset(-320, 0), 1600);
      await wait(tester, 900);
    }
    await home(tester);

    // 2. Arrêt d'urgence ; J4 telle qu'écrite : EMOM minute par minute.
    store.koachStop();
    await wait(tester, 600);
    releve['arret'] = store.koachEngine.stop != null;
    final j4 = store.program.week(wk).day(4)!;
    final mu = j4.exercises.first;
    final spMu = store.logSpec(mu);
    releve['emom_label'] = store.setsLabel(mu);
    releve['emom_lignes'] = store.setCount(mu);
    releve['emom_every'] = spMu.every;
    releve['emom_reps'] = store.plannedReps(mu, spMu, store.setCount(mu));
    unawaited(openProgramDay(appNavigator.currentState!, w15, j4));
    await wait(tester, 1500);
    final health = find.byKey(const ValueKey('health-question'));
    if (health.evaluate().isNotEmpty) {
      final skip = find.byKey(const ValueKey('bilan-start')).hitTestable();
      if (skip.evaluate().isNotEmpty) {
        await tester.tap(skip.first);
        await wait(tester, 900);
      }
    }
    // En-tête du départ chronométré : celui du groupe au temps du bloc
    // (« EMOM · 8 min », Lancer) ou, hors groupe, « EMOM · 8 tours ».
    final entete = find.textContaining(
      RegExp('EMOM · ${store.setCount(mu)} (min|tours)'),
    );
    await until(tester, entete, max: 60);
    releve['emom_entete'] = entete.evaluate().isNotEmpty;
    releve['emom_lancer'] = find.text('Lancer').evaluate().isNotEmpty;
    releve['j4_lignes_log'] = store.exLog(wk, 4, mu).sets.length;
    await shot('2_emom_minute_par_minute');
    await home(tester);

    // 3. Carte de reprise (arrêt d'avant dev7.4.0), puis réactivation.
    store.koachEngine.annonce107 = null;
    store.notifyListeners();
    await wait(tester, 900);
    final card = find.byKey(const ValueKey('koach-reprise-card'));
    for (var i = 0; i < 8 && card.hitTestable().evaluate().isEmpty; i++) {
      final list = find.byType(ListView);
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, -240));
      await wait(tester, 400);
    }
    releve['carte_reprise'] = card.evaluate().isNotEmpty;
    if (card.evaluate().isNotEmpty) await tester.ensureVisible(card);
    await wait(tester, 500);
    await shot('3_carte_reprise');
    final go = find.byKey(const ValueKey('koach-reprise-reactiver'));
    if (go.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(go.hitTestable().first);
    } else {
      unawaited(store.koachResume());
    }
    for (var i = 0; i < 300 && store.koachEngine.stop != null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 300 && store.koachBusy; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await wait(tester, 900);
    releve['reactive'] = store.koachEngine.stop == null;
    releve['carte_apres'] = card.evaluate().isNotEmpty;
    releve['j2_versee'] = store.koachEngine.versed.contains(
      store.sessionKey(wk, 2),
    );
    final j3 = store.program.week(wk).day(3)!;
    releve['j3_servie_par_koach'] = store.koachServesDay(wk, 3);
    releve['j3_apercu'] = store.adaptOpen(wk, j3)?.koach?['state'];
    final types = [for (final x in store.koachEngine.journal) '${x['type']}'];
    releve['debuts'] = types.where((t) => t == 'seance_debut').length;
    releve['fins'] = types.where((t) => t == 'seance_fin').length;
    // J2 commencée (servie par Koach, pas finie) : son début est au journal.
    releve['ouvertes'] =
        store.koachOpen(wk, 2) &&
            !(store.logs[store.sessionKey(wk, 2)]?.done ?? false)
        ? 1
        : 0;
    await shot('4_accueil_reactive');
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    expect(releve['j1_servie'], isTrue);
    expect(releve['j1_faite'], isTrue);
    expect((releve['j1_retraits'] as List?) ?? const [], isEmpty);
    expect(releve['j2_servie'], isTrue);
    expect(releve['j2_invalide'], isNull);
    expect((releve['j2_retraits'] as List?) ?? const [], isEmpty);
    expect(releve['j2_garde'], isNull);
    for (final x in ecrites2.entries) {
      expect(servis2[x.key], isNotNull, reason: x.key);
      expect(
        (servis2[x.key] as num),
        greaterThanOrEqualTo(x.value as num),
        reason: x.key,
      );
    }
    expect(releve['j2_affiche'], releve['j2_ecrit']);
    expect(
      (releve['j2_entete'] as List).where((t) => '$t'.startsWith('Je retire')),
      isEmpty,
    );
    expect(releve['arret'], isTrue);
    expect(releve['emom_lignes'], 8);
    expect(releve['emom_every'], 60);
    expect(releve['j4_lignes_log'], 8);
    expect(releve['emom_entete'], isTrue);
    expect(releve['emom_lancer'], isTrue);
    expect(releve['carte_reprise'], isTrue);
    expect(releve['reactive'], isTrue);
    expect(releve['carte_apres'], isFalse);
    expect(releve['j3_servie_par_koach'], isTrue);
    expect(releve['j3_apercu'], 'preview');
    expect(
      releve['debuts'] as int,
      (releve['fins'] as int) + (releve['ouvertes'] as int),
    );
  }, timeout: _limit);
}
