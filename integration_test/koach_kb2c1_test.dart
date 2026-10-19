// KB2 correction 1 (dev7.2.2, DECISIONS_CP.md C17.36) sur émulateur
// Android, lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_kb2c1_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : sauvegarde synthétique de la forme de celle du
// propriétaire après PR2 (ancien programme S1 à S14 au journal, nouveau
// programme à partir de S15 = S1 affichée, semaine type
// `kb2c1_semaine.dart` : tirage lourd + muscle-up lesté au départ
// chronométré) ; jamais l'export réel (C17.33.2). Horloge au lundi de la
// prise de main ; alerte hors modèle levée :
// 1. J1 : popup (message d'entrée sans redite, quatre choix sous leur
//    texte), feuille de la question fermée (retour) = « Plus tard » ;
//    séance servie par Koach identique à l'écrit (muscle-up lesté en
//    tête, mêmes blocs) ;
// 2. une série notée, arrêt d'urgence : séance écrite, série gardée ;
//    réactivation ;
// 3. J2 : « Répondre » puis « Rien de spécial » : réponse acceptée,
//    séance servie par Koach.
// Relevé `kb2c1_releve_<partie>.json`, captures `kb2c1_*_<thème>.png`.
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
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
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

  void record() => data['kb2c1_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['kb2c1_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  /// Bilan « Bien », puis le popup s'il vient ([onPopup]), puis les écrans
  /// d'ajustement, jusqu'au début de la séance de Koach (60 s au plus).
  Future<void> begin(
    WidgetTester tester,
    int w,
    int j,
    Future<void> Function() onPopup,
  ) async {
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 600);
    await tapKey(tester, 'feel-4', ms: 300);
    final sw = Stopwatch()..start();
    var popup = false;
    while (!store.koachOpen(w, j) &&
        !store.koachAnswerRefused(w, j) &&
        sw.elapsedMilliseconds < 60000) {
      await wait(tester, 250);
      if (!popup &&
          find
              .byKey(const ValueKey('koach-diag-start'))
              .hitTestable()
              .evaluate()
              .isNotEmpty) {
        popup = true;
        await wait(tester, 600);
        await onPopup();
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
    releve['popup_s$w-j$j'] = popup;
    await wait(tester, 800);
  }

  void alerte() {
    store.koachLive!.surveillance!.alertes = [true, false, false, false];
  }

  testWidgets('KB2c1 $_part ($theme, $accent) : popup de Koach et séance '
      'servie sur le programme PR2', (tester) async {
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
    final keep = <String>[];
    for (var w = 14; w >= 1 && keep.length < 34; w--) {
      for (var j = 7; j >= 1 && keep.length < 34; j--) {
        if (logs.containsKey('S$w-J$j')) keep.add('S$w-J$j');
      }
    }
    logs.removeWhere((k, _) => !keep.contains(k));
    final base = await _asset('programme_v33.json.gz');
    final koach = await _asset('koach_program.json.gz');
    b['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test-kb2c1',
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
    final now0 = KalisClock.now();
    final offset =
        DateTime(
          monday.year,
          monday.month,
          monday.day,
        ).difference(DateTime(now0.year, now0.month, now0.day)).inHours ~/
        24;
    KalisClock.setOffsetDays(offset);
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

    // 1. J1 : popup, feuille fermée = « Plus tard ».
    final w15 = store.program.week(wk);
    final j1 = w15.day(1)!;
    final ecrit = _structure(wk, 1);
    releve['j1_ecrit'] = ecrit;
    unawaited(openProgramDay(appNavigator.currentState!, w15, j1));
    final dialog = find.byKey(const ValueKey('koach-takeover'));
    for (var i = 0; i < 600 && dialog.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await wait(tester, 900);
    alerte();
    releve['alerte'] = store.koachNeedsDiagnostic;
    final intro = koachDiagnosticIntro(store.koachAlertCauses);
    releve['intro'] = intro;
    await begin(tester, wk, 1, () async {
      releve['intro_affichee'] = find.text(intro).evaluate().isNotEmpty;
      await shot('1_popup');
      await tapKey(tester, 'koach-diag-start', ms: 900);
      releve['choix'] = {
        for (final t in const [
          'Une douleur',
          'Moins de temps',
          'Fatigue ou vie chargée',
          'Rien de spécial',
          'Autre chose',
        ])
          t: find.text(t).evaluate().length,
      };
      await shot('2_choix');
      // Retour : la feuille se ferme sans choix = « Plus tard ».
      await tester.binding.handlePopRoute();
      await wait(tester, 900);
    });
    releve['j1_servie'] = store.koachOpen(wk, 1);
    releve['j1_affiche'] = _structure(wk, 1);
    releve['j1_ecrites'] = store.sessionAdapt(wk, 1)?.koach?['ecrites'];
    releve['question_reposee'] = store.koachNeedsDiagnostic;
    await shot('3_seance_j1');

    // 2. Série notée, arrêt d'urgence : séance écrite, série gardée.
    final a = store.sessionAdapt(wk, 1)!;
    final shown = store.adaptDay(wk, j1, a).exercises;
    final row = shown.firstWhere(
      (x) => x.catalogId == 'mu-rowing-barre-pronation',
    );
    final log = store.exLog(wk, 1, row);
    store.adaptPrefill(wk, 1, row, log);
    log.sets[0]
      ..kg = '60'
      ..reps = '8'
      ..done = true;
    store.saveLogs();
    final done = jsonEncode(log.sets[0].toJson());
    await home(tester);
    await push(
      tester,
      const KPage.sub(
        key: ValueKey('koach-engine-page'),
        title: 'Koach 1.0',
        children: [KoachEngineCard()],
      ),
    );
    await tapKey(tester, 'koach-stop', ms: 1200);
    final confirm = find.text('Arrêter');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last);
      await wait(tester, 1200);
    }
    releve['arret'] = store.koachEngine.stop != null;
    await home(tester);
    unawaited(openProgramDay(appNavigator.currentState!, w15, j1));
    await wait(tester, 2000);
    releve['arret_ecrite'] = store.adaptOpen(wk, j1) == null;
    final kept = store.logs[store.sessionKey(wk, 1)]?.ex[row.id];
    releve['arret_serie_gardee'] =
        kept != null && jsonEncode(kept.sets[0].toJson()) == done;
    releve['arret_series'] = kept?.sets.length;
    await shot('4_arret_seance_ecrite');
    await home(tester);
    await push(
      tester,
      const KPage.sub(
        key: ValueKey('koach-engine-page'),
        title: 'Koach 1.0',
        children: [KoachEngineCard()],
      ),
    );
    await tapKey(tester, 'koach-resume', ms: 2500);
    await store.koachRefresh();
    releve['reactive'] =
        store.koachEngine.stop == null && store.koachLive != null;
    releve['reactive_j1_servie'] = store.koachOpen(wk, 1);
    await home(tester);

    // 3. J2 : « Répondre » puis « Rien de spécial ».
    final j2 = w15.day(2)!;
    unawaited(openProgramDay(appNavigator.currentState!, w15, j2));
    await wait(tester, 1500);
    alerte();
    await begin(tester, wk, 2, () async {
      await tapKey(tester, 'koach-diag-start', ms: 900);
      final f = find.text('Rien de spécial').hitTestable();
      if (f.evaluate().isNotEmpty) {
        await tester.tap(f.first);
        await wait(tester, 900);
      }
    });
    releve['j2_servie'] = store.koachOpen(wk, 2);
    releve['j2_refusee'] = store.koachAnswerRefused(wk, 2);
    releve['j2_reponse'] = store.sessionAdapt(wk, 2)?.koach?['diag'];
    releve['j2_alerte_acquittee'] = !store.koachNeedsDiagnostic;
    await shot('5_seance_j2');
    await home(tester);
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    expect(releve['alerte'], isTrue);
    expect(releve['popup_s$wk-j1'], isTrue);
    expect(releve['intro_affichee'], isTrue);
    expect('sort de mon modèle'.allMatches(intro).length, 1);
    final choix = releve['choix'] as Map;
    expect(choix['Une douleur'], 1);
    expect(choix['Moins de temps'], 1);
    expect(choix['Fatigue ou vie chargée'], 1);
    expect(choix['Rien de spécial'], 1);
    expect(choix['Autre chose'], 0);
    expect(releve['j1_servie'], isTrue);
    expect(releve['j1_affiche'], ecrit);
    expect((ecrit.first), startsWith('MUSCLE-UP LESTÉ'));
    expect(releve['question_reposee'], isTrue);
    expect(releve['arret'], isTrue);
    expect(releve['arret_ecrite'], isTrue);
    expect(releve['arret_serie_gardee'], isTrue);
    expect(releve['reactive'], isTrue);
    expect(releve['reactive_j1_servie'], isTrue);
    expect(releve['popup_s$wk-j2'], isTrue);
    expect(releve['j2_servie'], isTrue);
    expect(releve['j2_refusee'], isFalse);
    expect(releve['j2_reponse'], {'cause': 'rien'});
    expect(releve['j2_alerte_acquittee'], isTrue);
  }, timeout: _limit);
}
