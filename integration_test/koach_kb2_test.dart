// KB2 (dev7.2.1, bascule ouverte par dérogation, prise de main immédiate,
// DECISIONS_CP.md C17.32, C17.34) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_kb2_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : sauvegarde synthétique de la forme de celle du
// propriétaire (programme importé PR2 au départ affiché S15, ancien
// journal de 34 séances, environ 790 séries ; jamais l’export réel,
// C17.33.2), laissée par dev7.2.0 (installation notée le 16/10, Koach pas
// actif). Lancement de dev7.2.1, horloge de l'application placée au lundi
// de la semaine de prise de main (S15 = S1 affichée la semaine du 19/10) ;
// J1 ouvert tout de suite → écran d'attente pendant la prise de main,
// puis séance servie par Koach ;
// temps de la prise de main ; journal identique ; squat d'endurance à
// 70 kg (charge fixe C15) servi par Koach le samedi ; arrêt d'urgence puis
// réactivation ; inspecteur (critère 10 affiché).
// Relevé `kb2_releve_<partie>.json`, captures `kb2_*_<thème>.png`.
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
import 'package:streetlift_tracker/dev/koach_inspector.dart';
import 'package:streetlift_tracker/home_screen.dart' show openProgramDay;
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';

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
  };
  binding.reportData = data;

  void record() => data['kb2_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['kb2_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> tapKey(WidgetTester tester, String key, {int ms = 800}) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) return;
    await tester.ensureVisible(f.first);
    await wait(tester, 300);
    if (f.hitTestable().evaluate().isEmpty) return;
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  Future<void> push(WidgetTester tester, Widget page, {int ms = 1500}) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
    await wait(tester, ms);
  }

  /// Début réel de la séance de Koach depuis le bilan (diagnostic hors
  /// modèle éventuel passé), au plus 60 s.
  Future<int> begin(WidgetTester tester, int w, int j) async {
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 600);
    await tapKey(tester, 'feel-4', ms: 300);
    final sw = Stopwatch()..start();
    while (!store.koachOpen(w, j) && sw.elapsedMilliseconds < 60000) {
      await wait(tester, 250);
      for (final k in const ['koach-diag-later', 'adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k)).hitTestable();
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          await wait(tester, 300);
        }
      }
    }
    await wait(tester, 800);
    return sw.elapsedMilliseconds;
  }

  testWidgets('KB2 $_part ($theme, $accent) : prise de main immédiate de '
      'Koach 1.0.5 sur le programme PR2 (S1 affichée)', (tester) async {
    KalisClock.setOffsetDays(0);
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Sauvegarde synthétique (forme de celle du propriétaire) : ancien
    // programme commencé le 13/07/2026, 34 dernières séances de S9 à S14
    // au journal ; nouveau programme importé, départ affiché S15 (PR2).
    final b = filledBackup(seed);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    final keep = <String>[];
    for (var w = 14; w >= 1 && keep.length < 34; w--) {
      for (var j = 7; j >= 1 && keep.length < 34; j--) {
        if (logs.containsKey('S$w-J$j')) keep.add('S$w-J$j');
      }
    }
    logs.removeWhere((k, _) => !keep.contains(k));
    var series = 0;
    for (final l in logs.values) {
      for (final x in ((l as Map)['ex'] as Map).values) {
        series += ((x as Map)['sets'] as List).length;
      }
    }
    releve['donnees'] = {'seances': logs.length, 'series': series};
    final base = await _asset('programme_v33.json.gz');
    final koach = await _asset('koach_program.json.gz');
    b['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test-kb2',
      'seed': 0,
      'weeks': [
        for (final w in (base['weeks'] as List).take(24))
          (w as Map).cast<String, dynamic>(),
      ],
      'koach': {
        'exercises': koach['exercises'],
        'weeks': {
          for (final e in (koach['weeks'] as Map).entries)
            if (int.parse('${e.key}') <= 24) '${e.key}': e.value,
        },
      },
      'summary': {'firstShownWeek': 15},
      'cycle': 1,
    };
    // Références du programme (comme test/kb2_prise_de_main_test.dart) :
    // la ligne de squat d'endurance à 70 kg porte son volume (B20).
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
    // (Profil d'athlète enregistré après le lancement, une fois l'horloge
    // de l'application placée : sans lui, la prise de main attend.)
    await seed.flush();
    // État laissé par dev7.2.0 : installation notée le 16/10, Koach pas
    // actif (aucune section `koachEngine`).
    await raw.setString('km3_installation_v1', '2026-10-16');
    final logsBefore = jsonEncode(
      (jsonDecode(seed.exportAll()) as Map<String, dynamic>)['logs'],
    );
    seed.dispose();

    // Lancement de dev7.2.1 (horloge réelle : le lancement remet à zéro le
    // décalage de l'horloge de la session personnelle).
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    // Semaine de prise de main prévue (S15 = S1 affichée jusqu'au 25/10 ;
    // ensuite la semaine du jour), horloge placée à son lundi.
    final wk = store.koachTakeoverPlanned() ?? 15;
    releve['prevue'] = wk;
    releve['libelle'] = store.program.weekLabel(wk);
    final monday = store.koachLundi!.addDays(7 * (wk - 1));
    final now0 = KalisClock.now();
    final offset =
        DateTime(
          monday.year,
          monday.month,
          monday.day,
        ).difference(DateTime(now0.year, now0.month, now0.day)).inHours ~/
        24;
    KalisClock.setOffsetDays(offset);
    releve['horloge'] = KalisClock.now().toIso8601String();
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(KalisClock.now()),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await wait(tester, 600);

    // J1 ouvert tout de suite : écran d'attente pendant la prise de main,
    // puis séance de Koach.
    final w15 = store.program.week(wk);
    final j1 = w15.day(1)!;
    final sw = Stopwatch()..start();
    unawaited(openProgramDay(appNavigator.currentState!, w15, j1));
    await wait(tester, 900);
    final dialog = find.byKey(const ValueKey('koach-takeover'));
    releve['attente_affichee'] = dialog.evaluate().isNotEmpty;
    if (dialog.evaluate().isNotEmpty) await shot('1_attente');
    // Ce qu'un arrêt brutal laisserait pendant la prise de main : aucun
    // état de Koach écrit, journal identique (relevé seulement si la prise
    // de main n'est pas déjà finie).
    releve['pendant'] = store.koachEngine.snap == null;
    await store.flush();
    final cut = raw.getString('kalis_state_v3') ?? '';
    releve['pendant_actif_ecrit'] = cut.contains('"snap"');
    releve['pendant_journal_identique'] =
        cut.isNotEmpty &&
        jsonEncode(
              ((jsonDecode(
                    cut.startsWith('gz:')
                        ? utf8.decode(
                            gzip.decode(base64Decode(cut.substring(3))),
                          )
                        : cut,
                  )
                  as Map<String, dynamic>)['logs']),
            ) ==
            logsBefore;
    for (var i = 0; i < 1500 && dialog.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final skip = find.byKey(const ValueKey('koach-takeover-skip'));
      if (skip.evaluate().isNotEmpty) releve['attente_trop_longue'] = true;
    }
    releve['attente_ms'] = sw.elapsedMilliseconds;
    // Dates notées au premier lancement de dev7.2.1 (horloge placée) :
    // ouverture de la bascule ; installation gardée de dev7.2.0.
    releve['ouverture'] = store.koachEngine.openedOn;
    releve['installation'] = store.koachEngine.installedOn;
    releve['koach_actif'] = store.koachEngine.snap != null;
    releve['depuis'] = store.koachEngine.fromWeek;
    releve['active_le'] = store.koachEngine.activatedOn;
    releve['evenements'] = store.koachEngine.journal.length;
    releve['temps'] = store.koachTemps.toJson();
    final debutJ1 = await begin(tester, wk, 1);
    releve['j1_debut_ms'] = debutJ1;
    releve['j1_servie'] = store.koachOpen(wk, 1);
    releve['j1_items'] =
        (store.sessionAdapt(wk, 1)?.koach?['items'] as List?)?.length;
    await shot('2_seance_j1');
    await home(tester);
    final logsAfter = (jsonDecode(store.exportAll()) as Map)['logs'] as Map;
    final before = jsonDecode(logsBefore) as Map;
    releve['journal_identique'] = before.keys.every(
      (k) => jsonEncode(logsAfter[k]) == jsonEncode(before[k]),
    );
    releve['origine_presente'] = store.programOrigin != null;

    // Samedi (J6) : squat d'endurance à 70 kg servi par Koach (C15).
    KalisClock.setOffsetDays(offset + 5);
    await store.koachRefresh();
    final imp = store.importedProgram!;
    String? key;
    for (final k in imp.fixedLoad.keys) {
      if (int.parse(k.split('|').first) == wk && imp.fixedLoad[k]!.$2 > 0) {
        key = k;
      }
    }
    releve['charge_fixe_trouvee'] = key != null;
    if (key != null) {
      final slot = key.substring(key.indexOf('|') + 1);
      releve['charge_fixe_kg'] = imp.fixedLoad[key]!.$2;
      var j = 0;
      for (final d in w15.days) {
        for (final e in d.original.exercises) {
          if (imp.slotOf(wk, d.j, e.id) == slot) j = d.j;
        }
      }
      releve['charge_fixe_jour'] = j;
      if (j > 0) {
        final day = w15.day(j)!;
        unawaited(openProgramDay(appNavigator.currentState!, w15, day));
        await begin(tester, 15, j);
        final a = store.sessionAdapt(wk, j);
        releve['j6_servie'] = store.koachOpen(wk, j);
        if (a != null) {
          final e = store
              .adaptDay(wk, day, a)
              .exercises
              .where((x) => x.slotId == slot)
              .firstOrNull;
          if (e != null) {
            final log = store.exLog(wk, j, e);
            store.adaptPrefill(wk, j, e, log);
            final g = store.adaptGoal(wk, j, e, 0);
            releve['squat_kg_servi'] = g?.kg;
            releve['squat_reps'] = '${g?.low}-${g?.high}';
          }
        }
        await shot('3_seance_j6');
        await home(tester);
      }
    }

    // Arrêt d'urgence puis réactivation (Réglages › Koach 1.0).
    await push(
      tester,
      const KPage.sub(
        key: ValueKey('koach-engine-page'),
        title: 'Koach 1.0',
        children: [KoachEngineCard()],
      ),
    );
    await shot('4_koach_actif');
    await tapKey(tester, 'koach-stop', ms: 1200);
    final confirm = find.text('Arrêter');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last);
      await wait(tester, 1200);
    }
    releve['arret'] = store.koachEngine.stop != null;
    releve['arret_ecrit'] =
        !store.koachServesDay(wk, 5) && store.koachStoppedWeek(wk);
    await shot('5_arret');
    await tapKey(tester, 'koach-resume', ms: 2500);
    await store.koachRefresh();
    releve['reactive'] =
        store.koachEngine.stop == null && store.koachLive != null;
    await shot('6_reactive');
    await home(tester);

    // Inspecteur : bascule ouverte par dérogation, critère 10 affiché.
    await push(tester, const KoachInspectorScreen(), ms: 2500);
    releve['inspecteur_critere_10'] = find
        .textContaining('Critère 10 (18/10) : non tenu')
        .evaluate()
        .isNotEmpty;
    releve['inspecteur_derogation'] = find
        .textContaining('ouverte par dérogation')
        .evaluate()
        .isNotEmpty;
    await shot('7_inspecteur');
    await home(tester);
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['ouverture'], isNotNull);
    expect(releve['charge_fixe_trouvee'], isTrue);
    expect(releve['installation'], '2026-10-16');
    expect(releve['prevue'] as int, greaterThanOrEqualTo(15));
    // S1 affichée la semaine du 19/10 (S15 interne).
    expect(releve['libelle'], 'S${(releve['prevue'] as int) - 14}');
    expect(releve['attente_affichee'], isTrue);
    if (releve['pendant'] == true) {
      expect(releve['pendant_actif_ecrit'], isFalse);
      expect(releve['pendant_journal_identique'], isTrue);
    }
    expect(releve['koach_actif'], isTrue);
    expect(releve['depuis'], releve['prevue']);
    expect(releve['j1_servie'], isTrue);
    expect(releve['journal_identique'], isTrue);
    expect(releve['origine_presente'], isTrue);
    expect(releve['charge_fixe_kg'], 70.0);
    expect(releve['j6_servie'], isTrue);
    expect(releve['squat_kg_servi'], 70.0);
    expect(releve['arret'], isTrue);
    expect(releve['arret_ecrit'], isTrue);
    expect(releve['reactive'], isTrue);
    expect(releve['inspecteur_critere_10'], isTrue);
    expect(releve['inspecteur_derogation'], isTrue);
  }, timeout: _limit);
}
