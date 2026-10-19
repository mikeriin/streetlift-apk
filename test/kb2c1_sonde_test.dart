// KB2 correction 1 — sonde (temporaire) : séance S15·J1 servie par Koach
// sur un programme importé de la forme PR2 (semaine `test/fixtures/
// pr9_semaine.json`, synthétique). Imprime l'écrit, l'aperçu et le servi.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(utf8.decode(gzip.decode(File('assets/$name').readAsBytesSync())))
        as Map<String, dynamic>;

Future<void> _pr2(AppStore app) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    return w > 14;
  });
  final base = _asset('programme_v33.json.gz');
  final koach = _asset('koach_program.json.gz');
  final semaine =
      jsonDecode(File('test/fixtures/pr9_semaine.json').readAsStringSync())
          as Map<String, dynamic>;
  final weeks = [
    for (final w in (base['weeks'] as List).take(14))
      (w as Map).cast<String, dynamic>(),
    for (var n = 15; n <= 24; n++)
      (jsonDecode(jsonEncode(semaine)) as Map<String, dynamic>)
        ..['n'] = n
        ..['blockKey'] = n <= 19 ? 'NA' : 'NB',
  ];
  b['programInstance'] = {
    'v': 1,
    'kind': 'generated',
    'origin': 'user',
    'createdAt': '2026-10-17T12:00:00',
    'updatedAt': '2026-10-17T12:00:00',
    'generator': 'test-kb2c1',
    'seed': 0,
    'weeks': weeks,
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
  expect(await app.importAll(jsonEncode(b)), isTrue);
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: kc.GuidanceMode.assisted,
      ),
    )..consent = 'refused',
  );
}

void _dump(String tag, AppStore app, int week, DayPlan base) {
  final a = app.sessionAdapt(week, base.j);
  final lines = <String>['SONDE|$tag|etat=${a?.koach?['state']}'];
  for (final e in base.exercises) {
    lines.add(
      'SONDE|$tag|ecrit|${e.id}|${e.name}|${app.setsLabel(e)}|'
      'slot=${app.adaptSlotOf(week, base.j, e.id)}',
    );
  }
  final info = app.koachJourInfo(week, base.j);
  for (final it in info?.items ?? const <Map<String, Object?>>[]) {
    lines.add(
      'SONDE|$tag|info|${it['slotId']}|${it['exerciseId']}|'
      'sets=${it['sets']}|kind=${it['kind']}|g=${it['groupId']}|'
      'fl=${it['targetFlames']}',
    );
  }
  if (a != null) {
    for (final it in a.plan.items) {
      lines.add(
        'SONDE|$tag|plan|${it.slotId}|${it.exerciseId}|sets=${it.sets}|'
        'g=${it.groupId}',
      );
    }
    final served = a.koach?['items'];
    if (served is List) {
      for (final it in served) {
        if (it is Map) {
          lines.add(
            'SONDE|$tag|servi|${it['slotId']}|${it['exerciseId']}|'
            'sets=${it['sets']}|koach=${it['koach']}',
          );
        }
      }
    }
    lines.add('SONDE|$tag|raisons|${jsonEncode(a.koach?['raisons'])}');
    final shown = app.adaptDay(week, base, a);
    for (final e in shown.exercises) {
      lines.add(
        'SONDE|$tag|affiche|${e.id}|${e.name}|${app.setsLabel(e)}|'
        'slot=${e.slotId}',
      );
    }
  }
  // ignore: avoid_print
  print(lines.join('\n'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 19, 7);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    clock = DateTime(2026, 10, 19, 7);
    app = AppStore()..storeClock = () => clock;
    await app.init();
  });
  tearDown(() async {
    debugKoachBasculeAutorisee = false;
    await app.flush();
    app.dispose();
  });

  for (final alerte in const [false, true]) {
    test('sonde S15·J1 (alerte=$alerte)', () async {
      await _pr2(app);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15, reason: '${app.koachEngine.blocked}');
      final base = app.program.week(15).day(1)!;
      app.adaptOpen(15, base);
      _dump('apercu-$alerte', app, 15, base);
      if (alerte) {
        app.koachLive!.surveillance!.alertes = [true, false, false, false];
        // ignore: avoid_print
        print(
          'SONDE|questions|${jsonEncode(app.koachQuestions(const {}))}|'
          'causes=${app.koachAlertCauses}',
        );
      }
      final ok = await app.koachStart(15, base);
      // ignore: avoid_print
      print('SONDE|start=$ok|err=${app.koachRuntimeError}');
      _dump('servi-$alerte', app, 15, base);
    });
  }
}
