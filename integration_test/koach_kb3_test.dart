// KB3 (dev7.3.0, DECISIONS_CP.md C17.39) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_kb3_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : sauvegarde synthétique de la forme de celle du
// propriétaire après PR2 (ancien programme S1 à S14 au journal, nouveau
// programme à partir de S15 = S1 affichée, semaine type `kb2c1_semaine.dart`
// avec un pull-over « chest » ajouté au lundi de tirage) ; jamais l'export
// réel (C17.33.2). Horloge au lundi de la prise de main :
// 1. J1 servi par Koach (KB4 : 1.0.7) : muscle-up lesté en tête et traction
//    lestée servis par Koach, pull-over gardé (KB3 : 1.0.6 le retirait
//    d'abord ; C17.40 : la rampe ne coupe plus sous l'écrit) ; temps de la
//    séance servie mesuré ;
// 2. rôles transmis dans `reste_semaine`.
// Relevé `kb3_releve_<partie>.json`, captures `kb3_*_<thème>.png`.
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
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';
import 'kb2c1_semaine.dart';

/// Semaine type PR2 avec un pull-over (accessoire qui crédite « chest »)
/// au lundi de tirage, après la traction lestée et ses pompes.
Map<String, dynamic> _semaine() {
  final s = jsonDecode(kKb2c1Semaine) as Map<String, dynamic>;
  final j1 = (s['days'] as List).first as Map<String, dynamic>;
  final ex = (j1['exercises'] as List).cast<Map<String, dynamic>>();
  ex.insert(3, {
    'id': 'NA-S15J1-08',
    'name': 'Pull-over haltère',
    'sets': {'type': 'text', 'value': '3×12'},
    'intensity': 'RIR 2',
    'load': {'type': 'acc', 'ref': 'B43', 'dayReps': 12, 'step': 2.0},
    'rest': '90 s',
    'restSec': 90,
    'tempo': 'Contrôlé',
    'cue': 'Accessoire de la cible KB3 (données synthétiques).',
    'main': false,
    'prevention': false,
    'catalogId': 'mu-pull-over-haltere',
  });
  j1['exercises'] = ex;
  return s;
}

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

  void record() => data['kb3_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['kb3_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  testWidgets('KB3 $_part ($theme, $accent) : Koach sur le programme PR2 '
      '(KB4 : accessoire « chest » gardé)', (tester) async {
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
      'generator': 'test-kb3',
      'seed': 0,
      'weeks': [
        for (final w in (base['weeks'] as List).take(14))
          (w as Map).cast<String, dynamic>(),
        for (var n = 15; n <= 24; n++)
          _semaine()
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

    // 1. J1 : séance servie par Koach.
    final w15 = store.program.week(wk);
    final j1 = w15.day(1)!;
    releve['j1_ecrit'] = _structure(wk, 1);
    unawaited(openProgramDay(appNavigator.currentState!, w15, j1));
    final dialog = find.byKey(const ValueKey('koach-takeover'));
    for (var i = 0; i < 600 && dialog.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await wait(tester, 900);
    final sw = Stopwatch()..start();
    await begin(tester, wk, 1, () async {
      await tester.binding.handlePopRoute();
      await wait(tester, 900);
    });
    releve['j1_servie'] = store.koachOpen(wk, 1);
    releve['temps_debut_ms'] = sw.elapsedMilliseconds;
    releve['temps'] = store.koachTemps.toJson();
    final a = store.sessionAdapt(wk, 1)!;
    final st = a.koach!;
    final items = [
      for (final x in (st['items'] as List? ?? const []))
        (x as Map).cast<String, Object?>(),
    ];
    final servis = {for (final x in items) '${x['exerciseId']}': x['sets']};
    releve['servis'] = servis;
    releve['ecrites'] = st['ecrites'];
    releve['retraits'] = st['retraits'];
    releve['j1_affiche'] = _structure(wk, 1);
    final shown = store.adaptDay(wk, j1, a).exercises;
    releve['cartes'] = [
      for (final e in shown) '${e.catalogId} · ${store.setsLabel(e)}',
    ];
    final entete = store.koachSessionReasons(wk, 1);
    releve['entete'] = entete;
    final lignes = {
      for (final e in shown)
        if (store.koachReasonLine(wk, 1, e) case final l?) '${e.catalogId}': l,
    };
    releve['raisons_cartes'] = lignes;
    releve['je_retire_affiche'] = find
        .textContaining('Je retire', findRichText: true)
        .evaluate()
        .isNotEmpty;
    await shot('1_seance_j1');
    // Muscle-up lesté (E2MOM, PR8 : séries du programme) : la réduction de
    // Koach est dite sur sa carte (« … séries sur 6 »).
    final mu = shown.first;
    releve['mu_carte'] = store.setsLabel(mu);
    final ml = find.textContaining('séries sur', findRichText: true);
    if (lignes[mu.catalogId]?.contains('séries sur') ?? false) {
      for (var i = 0; i < 6 && ml.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await wait(tester, 400);
      }
    }
    releve['reduction_affichee'] = ml.evaluate().isNotEmpty;
    await shot('2_carte_reduite');
    // 2. Rôles transmis dans reste_semaine.
    final debut = store.koachEngine.journal.lastWhere(
      (x) => x['type'] == 'seance_debut',
    );
    final reste =
        ((debut['contexte'] as Map?)?['reste_semaine'] as List?) ?? const [];
    releve['reste_seances'] = reste.length;
    releve['reste_roles'] = reste.every(
      (s) => (s as List).every((it) => (it as Map).containsKey('role')),
    );
    await home(tester);
    await store.flush();
    KalisClock.setOffsetDays(0);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['koach_actif'], isTrue);
    expect(releve['j1_servie'], isTrue);
    expect((servis['sl-muscle-up-leste'] as num?) ?? 0, inInclusiveRange(1, 6));
    expect((servis['sl-traction-lestee'] as num?) ?? 0, inInclusiveRange(1, 8));
    // KB4 (Koach 1.0.7, C17.40) : la rampe de volume ne coupe plus sous
    // l'écrit : le pull-over « chest » reste servi, aucun retrait, aucun
    // « Je retire … » en tête de séance.
    expect(
      (releve['cartes'] as List).any(
        (c) => '$c'.startsWith('mu-pull-over-haltere'),
      ),
      isTrue,
    );
    expect((st['retraits'] as List?) ?? const [], isEmpty);
    expect(entete.where((t) => t.startsWith('Je retire')), isEmpty);
    expect((releve['j1_affiche'] as List).first, startsWith('MUSCLE-UP LESTÉ'));
    expect(releve['mu_carte'], '6×2 · E2MOM');
    if (((servis['sl-muscle-up-leste'] as num?) ?? 6) < 6) {
      expect(lignes['sl-muscle-up-leste'], contains('séries sur 6'));
    }
    expect(releve['reste_seances'], 5);
    expect(releve['reste_roles'], isTrue);
  }, timeout: _limit);
}
