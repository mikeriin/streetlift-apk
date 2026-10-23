// RV3 (dev7.7.1, DECISIONS_CP.md C17.51) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/rv3_modulation_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis, profil en mode libre ; b = thème clair,
// violet, profil en mode assisté. Session personnelle : sauvegarde
// synthétique de la forme de celle du propriétaire après PR2 (comme KB5) ;
// jamais l'export réel (C17.33.2). Mardi, modulation de la semaine forcée
// sur le plan de Koach : en libre, la ligne est servie à l'écrit et la
// carte propose (« Accepter » / « Garder l'écrit ») ; en assisté, servie
// modulée, « Annuler ». Le choix fait passer la ligne aux séries choisies.
// Relevé `rv3_releve_<partie>.json`, captures `rv3_*_<thème>.png`.
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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  // RV3 : a = mode libre (proposée), b = mode assisté (appliquée).
  final libre = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
    'mode': _part == 'a' ? 'free' : 'assisted',
  };
  binding.reportData = data;

  void record() => data['rv3_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['rv3_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  testWidgets('RV3 $_part ($theme, $accent) : modulation de la semaine '
      'selon le mode du profil', (tester) async {
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
      'generator': 'test-rv3',
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
          guidance: libre ? kc.GuidanceMode.free : kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await wait(tester, 600);
    await store.koachRefresh();
    releve['koach_actif'] = store.koachEngine.snap != null;
    releve['depuis'] = store.koachEngine.fromWeek;

    // Mardi : modulation de la semaine forcée sur le plan de Koach (facteur
    // de volume 0,4), séance de poussée ouverte par l'écran.
    await dayOffset(tester, monday.addDays(1));
    await store.koachRefresh();
    final pl = store.koachLive!.planification!;
    pl.plan[wk - 1] = {
      ...?pl.plan[wk - 1],
      'volume': List<double>.filled(10, 0.4),
      'intensite': 0.0,
    };
    final w15 = store.program.week(wk);
    final j2 = w15.day(2)!;
    unawaited(openProgramDay(appNavigator.currentState!, w15, j2));
    await wait(tester, 900);
    await begin(tester, wk, 2);
    releve['servie'] = store.koachOpen(wk, 2);
    final a2 = store.sessionAdapt(wk, 2)!;
    releve['mode_seance'] = a2.mode;
    releve['volume'] = a2.koach?['volume'];
    final shown = store.adaptDay(wk, j2, a2).exercises;
    final ligne = shown
        .where((e) => store.koachVolume(wk, 2, e) != null)
        .firstOrNull;
    releve['ligne'] = ligne?.catalogId;
    if (ligne != null) {
      final v = store.koachVolume(wk, 2, ligne)!;
      releve['series'] = v.series;
      releve['ecrites'] = v.ecrites;
      releve['applique_avant'] = v.applique;
      releve['lignes_avant'] = store.exLog(wk, 2, ligne).sets.length;
      releve['entete'] = store.koachSessionReasons(wk, 2, max: 9);
      // Page de la ligne.
      final idx = store
          .groups(store.adaptDay(wk, j2, a2), week: wk)
          .indexWhere((g) => g.any((e) => e.id == ligne.id));
      for (var p = 0; p < idx; p++) {
        final pv = find.byType(PageView);
        if (pv.evaluate().isEmpty) break;
        await tester.fling(pv.first, const Offset(-320, 0), 1600);
        await wait(tester, 900);
      }
      releve['page'] = idx + 1;
      final bouton = find.byKey(
        ValueKey(
          libre
              ? 'koach-volume-accept-${ligne.id}'
              : 'koach-volume-undo-${ligne.id}',
        ),
      );
      final autre = find.byKey(ValueKey('koach-volume-keep-${ligne.id}'));
      releve['bouton'] = await until(tester, bouton, max: 60);
      releve['garder_ecrit'] = autre.evaluate().isNotEmpty;
      if (bouton.evaluate().isNotEmpty) {
        await tester.ensureVisible(bouton.first);
        await wait(tester, 600);
        await shot('1_carte');
        await tester.tap(bouton.first);
        await wait(tester, 900);
      }
      final fait = find.byKey(ValueKey('koach-volume-done-${ligne.id}'));
      releve['fait'] = await until(tester, fait, max: 40);
      if (fait.evaluate().isNotEmpty) {
        await tester.ensureVisible(fait.first);
        await wait(tester, 600);
      }
      await shot('2_choix');
      final w = store.koachVolume(wk, 2, ligne)!;
      releve['applique_apres'] = w.applique;
      releve['choix'] = w.choix;
      releve['lignes_apres'] = store.exLog(wk, 2, ligne).sets.length;
      releve['invalide'] = store.sessionAdapt(wk, 2)!.koach!['invalide'];
    }
    await home(tester);
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    expect(releve['servie'], isTrue);
    expect(releve['mode_seance'], libre ? 'free' : 'assisted');
    expect(releve['ligne'], isNotNull);
    expect(releve['applique_avant'], !libre);
    expect(
      releve['lignes_avant'],
      libre ? releve['ecrites'] : releve['series'],
    );
    expect(releve['bouton'], isTrue);
    expect(releve['garder_ecrit'], libre);
    expect(releve['fait'], isTrue);
    expect(releve['applique_apres'], libre);
    expect(releve['choix'], libre ? 'applique' : 'ecrit');
    expect(
      releve['lignes_apres'],
      libre ? releve['series'] : releve['ecrites'],
    );
    expect(releve['invalide'], isNull);
  }, timeout: _limit);
}
