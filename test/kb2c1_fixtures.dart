// KB2 correction 1 (dev7.2.2, DECISIONS_CP.md C17.36) — sauvegarde
// synthétique de la forme de celle du propriétaire après PR2 : ancien
// programme S1 à S14 au journal (programme embarqué), nouveau programme à
// partir de S15 (S1 affichée), six séances par semaine en PPL, blocs au
// départ chronométré (semaine type `test/fixtures/pr9_semaine.json` :
// muscle-up lesté puis traction lestée avec les pompes dans la pause,
// séance de tirage ; poussée lourde le lendemain). Jamais l'export réel
// (C17.33.2).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(utf8.decode(gzip.decode(File('assets/$name').readAsBytesSync())))
        as Map<String, dynamic>;

/// Semaine type du nouveau programme (S1 affichée).
Map<String, dynamic> pr2Semaine() =>
    jsonDecode(File('test/fixtures/pr9_semaine.json').readAsStringSync())
        as Map<String, dynamic>;

/// Importe dans [app] la sauvegarde synthétique : journal de l'ancien
/// programme jusqu'à S[lastWeek]·J[lastJ], nouveau programme de S15 à S24
/// (deux blocs), départ affiché S15 ; profil d'athlète enregistré.
Future<void> importPr2Nouveau(
  AppStore app, {
  int lastWeek = 14,
  int lastJ = 7,
}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ) || w > 14;
  });
  final base = _asset('programme_v33.json.gz');
  final koach = _asset('koach_program.json.gz');
  final semaine = pr2Semaine();
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
        (jsonDecode(jsonEncode(semaine)) as Map<String, dynamic>)
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

/// Structure d'une séance affichée : (nom, groupe de la carte) de chaque
/// exercice, dans l'ordre.
List<String> structureSeance(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j);
  final day = a == null ? base : app.adaptDay(week, base, a);
  return [
    for (final g in app.groups(day, week: week))
      g.map((e) => app.splitName(e.name).$1).join(' + '),
  ];
}
