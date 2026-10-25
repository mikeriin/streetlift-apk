// RV4 (dev7.7.2, DECISIONS_CP.md C17.51.5) sur émulateur Android, lancé
// par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/rv4_remplacement_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet ; profil en mode
// libre. Session personnelle : sauvegarde synthétique de la forme de celle
// du propriétaire après PR2 (comme KB5, RV3) ; jamais l'export réel
// (C17.33.2). Vendredi (J5, poussée densité) : menu ⋯ du dip lesté de
// l'E2MOM, « Remplacer pour aujourd'hui », recherche « hspu mur », HSPU au
// mur dos au mur : la carte garde le groupe, le format et le chrono ; b :
// « Barre au front EZ » retirée pour aujourd'hui (pas de matériel).
// Relevé `rv4_releve_<partie>.json`, captures `rv4_*_<thème>.png`.
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
import 'package:streetlift_tracker/models.dart' show DayPlan;
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
  final accent = dark ? 'rouge' : 'violet';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
    'mode': 'free',
  };
  binding.reportData = data;

  void record() => data['rv4_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['rv4_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  testWidgets('RV4 $_part ($theme, $accent) : HSPU au mur à la place du '
      'dip lesté (J5, E2MOM)', (tester) async {
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
      'generator': 'test-rv4',
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
          guidance: kc.GuidanceMode.free,
        ),
      )..consent = 'refused',
    );
    await wait(tester, 600);
    await store.koachRefresh();
    releve['koach_actif'] = store.koachEngine.snap != null;
    releve['depuis'] = store.koachEngine.fromWeek;

    // Vendredi : séance de poussée densité ouverte par l'écran.
    await dayOffset(tester, monday.addDays(4));
    await store.koachRefresh();
    final w15 = store.program.week(wk);
    final j5 = w15.day(5)!;
    unawaited(openProgramDay(appNavigator.currentState!, w15, j5));
    await wait(tester, 900);
    await begin(tester, wk, 5);
    releve['servie'] = store.koachOpen(wk, 5);
    DayPlan shownDay() {
      final a = store.sessionAdapt(wk, 5);
      return a == null
          ? store.withDayChanges(wk, j5)
          : store.adaptDay(wk, j5, a);
    }

    final dip = shownDay().exercises
        .where((e) => e.name.startsWith('DIP LESTÉ'))
        .firstOrNull;
    releve['dip'] = dip?.id;
    if (dip != null) {
      releve['groupe_avant'] = store.exerciseGroupOf(wk, 5, dip)?.toJson();
      releve['series_avant'] = store.setsLabel(dip);
      final idx = store
          .groups(shownDay(), week: wk)
          .indexWhere((g) => g.any((e) => e.id == dip.id));
      releve['page'] = idx + 1;
      for (var p = 0; p < idx; p++) {
        final pv = find.byType(PageView);
        if (pv.evaluate().isEmpty) break;
        await tester.fling(pv.first, const Offset(-320, 0), 1600);
        await wait(tester, 900);
      }
      final menu = find.byKey(ValueKey('${dip.id}-menu'));
      releve['menu'] = await until(tester, menu, max: 60);
      if (menu.evaluate().isNotEmpty) {
        await tester.tap(menu.first);
        await wait(tester, 900);
        await shot('1_menu');
        final act = find.byKey(const ValueKey('action-replace'));
        releve['action'] = act.evaluate().isNotEmpty;
        if (act.evaluate().isNotEmpty) {
          await tester.tap(act.first);
          await wait(tester, 1200);
          // KB6 : la recherche est sous les propositions de Koach : on la
          // fait venir à l'écran.
          final recherche = find.byKey(const ValueKey('replace-search'));
          final defile = find.byType(Scrollable);
          if (recherche.evaluate().isEmpty && defile.evaluate().isNotEmpty) {
            try {
              await tester.scrollUntilVisible(
                recherche,
                300,
                scrollable: defile.last,
              );
            } catch (_) {}
            await wait(tester, 600);
          }
          final champ = find.descendant(
            of: recherche,
            matching: find.byType(EditableText),
          );
          releve['recherche'] = champ.evaluate().isNotEmpty;
          if (champ.evaluate().isNotEmpty) {
            await tester.enterText(champ.first, 'hspu mur dos');
            await wait(tester, 900);
            await shot('2_recherche');
            final row = find.byKey(const ValueKey('replace-cd-hspu-mur-dos'));
            // Clavier fermé, ligne visible, appui répété tant que l'écran
            // de remplacement est encore là (transition, clavier).
            FocusManager.instance.primaryFocus?.unfocus();
            await wait(tester, 900);
            final ouvert = find.byKey(const ValueKey('replace-page'));
            for (var essai = 0; essai < 4; essai++) {
              if (!await until(tester, row, max: 40)) break;
              await tester.ensureVisible(row.first);
              await wait(tester, 900);
              await tester.tap(row.first, warnIfMissed: false);
              await wait(tester, 1500);
              if (ouvert.evaluate().isEmpty) break;
            }
          }
        }
      }
      final h = shownDay().exercises
          .where((e) => e.catalogId == 'cd-hspu-mur-dos')
          .firstOrNull;
      releve['hspu'] = h?.id;
      if (h != null) {
        releve['nom'] = h.name;
        releve['series_apres'] = store.setsLabel(h);
        releve['groupe_apres'] = store.exerciseGroupOf(wk, 5, h)?.toJson();
        releve['kg'] = store.showKgFor(h, store.exLog(wk, 5, h));
        final carte = find.byKey(ValueKey('exercise-card-${h.id}'));
        final seule = find.byKey(ValueKey('${h.id}-menu'));
        releve['carte'] =
            await until(tester, seule, max: 60) || carte.evaluate().isNotEmpty;
        await wait(tester, 600);
        await shot('3_carte');
      }
    }
    if (_part == 'b') {
      final front = shownDay().exercises
          .where((e) => e.name.startsWith('Barre au front'))
          .firstOrNull;
      if (front != null) {
        store.dayRemove(wk, shownDay(), front, 'materiel');
        releve['retrait'] = !shownDay().exercises.any((e) => e.id == front.id);
        releve['retraits'] = [
          for (final l in store.dayRemovedLines(wk, 5)) '${l.name}|${l.reason}',
        ];
      }
    }
    releve['programme_intact'] = !store.program
        .week(wk)
        .day(5)!
        .exercises
        .any((e) => e.name.startsWith('HSPU'));
    await home(tester);
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    expect(releve['servie'], isTrue);
    expect(releve['dip'], isNotNull);
    expect(releve['menu'], isTrue);
    expect(releve['action'], isTrue);
    expect(releve['recherche'], isTrue);
    expect(releve['hspu'], isNotNull);
    // KB6 : même nombre de séries et même format (« · E2MOM ») ; la cible
    // est celle de départ de Koach pour le remplaçant.
    expect(
      '${releve['series_apres']}'.split('×').first,
      '${releve['series_avant']}'.split('×').first,
    );
    expect('${releve['series_apres']}', endsWith('· E2MOM'));
    expect(
      jsonEncode(releve['groupe_apres']),
      jsonEncode(releve['groupe_avant']),
    );
    expect(releve['kg'], isFalse);
    expect(releve['carte'], isTrue);
    expect(releve['programme_intact'], isTrue);
    if (_part == 'b') expect(releve['retrait'], isTrue);
  }, timeout: _limit);
}
