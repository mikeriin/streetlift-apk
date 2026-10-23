// RV3 (sonde provisoire) : relevé du mercredi au bilan bas (dead hang de
// la pause du squat E3MOM) et d'une semaine modulée par Koach.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('RV3|$nom|${jsonEncode(v)}');
}

void main() {
  late AppStore app;
  var clock = DateTime(2026, 10, 19, 7);

  setUp(() async {
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    clock = DateTime(2026, 10, 19, 7);
    SharedPreferences.setMockInitialValues({});
    app = AppStore()..storeClock = () => clock;
    await app.init();
  });
  tearDown(() async {
    debugKoachBasculeAutorisee = false;
    await app.flush();
    app.dispose();
  });

  Future<void> activate() async {
    await importPr2Nouveau(app, firstWeek: 12);
    app.koachNoteInstall();
    await app.koachRefresh();
    expect(app.koachEngine.fromWeek, 15);
  }

  Future<void> ouvrir(int j, {kc.HealthCheck? check}) async {
    clock = DateTime(2026, 10, 18 + j, 7);
    await app.koachRefresh();
    final base = app.program.week(15).day(j)!;
    expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
    if (check != null) app.adaptAnswer(15, base, check);
    expect(await app.koachStart(15, base), isTrue, reason: 'J$j');
  }

  Map<String, Object?> releve(int j) {
    final a = app.sessionAdapt(15, j)!;
    final st = a.koach!;
    Object? court(Object? x) => x is Map
        ? {
            for (final k in const [
              'slotId',
              'exerciseId',
              'sets',
              'groupId',
              'koachModule',
              'koachVolume',
              'kind',
              'secondsLow',
              'repsLow',
            ])
              if (x.containsKey(k)) k: x[k],
          }
        : x;
    return {
      'ecrits': [for (final x in app.koachJourInfo(15, j)!.items) court(x)],
      'groupesEcrits': [
        for (final g in app.adaptPlaceOf(15, j)!.day!.groups ?? const [])
          g.toJson(),
      ],
      'servis': [for (final x in st['items'] as List) court(x)],
      'plan': [for (final x in a.plan.items) court(x.toJson())],
      'groupes': [for (final g in a.plan.groups ?? const []) g.toJson()],
      'raisons': st['raisons'],
      'ouverture': st['ouverture'],
      'retraits': st['retraits'],
      'ecrites': st['ecrites'],
      'recales': st['groupesRecales'],
      'entete': app.koachSessionReasons(15, j, max: 9),
      'cartes': [
        for (final x
            in app
                .adaptDay(15, app.program.week(15).day(j)!, a)
                .exercises)
          '${x.catalogId}|${x.slotId}|${app.setsLabel(x)}',
      ],
    };
  }

  test('sonde : mercredi au bilan bas', () async {
    await activate();
    await ouvrir(
      3,
      check: const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
    );
    _sonde('j3_bilan_bas', releve(3));
  });

  test('sonde : mercredi sans bilan', () async {
    await activate();
    await ouvrir(3);
    _sonde('j3_normal', releve(3));
  });

  test('sonde : semaine modulée (plan de la planification forcé)', () async {
    await activate();
    clock = DateTime(2026, 10, 20, 7);
    await app.koachRefresh();
    final pl = app.koachLive!.planification!;
    _sonde('plan_avant', pl.plan[14]);
    pl.plan[14] = {
      ...?pl.plan[14],
      'volume': List<double>.filled(10, 0.66),
      'intensite': 0.0,
    };
    final base = app.program.week(15).day(2)!;
    final ap = app.adaptOpen(15, base)!;
    _sonde('apercu_j2', [
      for (final x in ap.plan.items) '${x.slotId}:${x.exerciseId}:${x.sets}',
    ]);
    expect(await app.koachStart(15, base), isTrue);
    _sonde('plan_apres', app.koachLive!.planification!.plan[14]);
    _sonde('j2_module', releve(2));
  });
}
