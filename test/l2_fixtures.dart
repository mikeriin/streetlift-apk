// Jeux de données synthétiques L2 (aucune donnée réelle) : utilisateur neuf,
// historique rempli, formats historiques, données dégradées. G2 : les WOD,
// séances perso et crédits n'existent plus qu'en JSON brut (sections de
// 6.0.x ignorées à l'import, encore bornées par KT-015).

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:streetlift_tracker/store.dart';

import 'support/retired_fixtures.dart';

Map<String, dynamic> backupOf(AppStore app) =>
    jsonDecode(app.exportAll()) as Map<String, dynamic>;

/// Texte « gz: » + base64, comme l'export compact.
String gzText(String json) =>
    'gz:${base64Encode(gzip.encode(utf8.encode(json)))}';

/// Données très compressibles : [bytes] espaces dans un JSON valide.
String compressibleBomb(int bytes) {
  final spaces = Uint8List(bytes)..fillRange(0, bytes, 0x20);
  final json = BytesBuilder()
    ..add(utf8.encode('{"kalisTrack":1,"format":3,"pad":"'))
    ..add(spaces)
    ..add(utf8.encode('"}'));
  return 'gz:${base64Encode(gzip.encode(json.takeBytes()))}';
}

/// Historique rempli représentatif : chaque journée d'entraînement des
/// 40 semaines saisie en entier.
Map<String, dynamic> filledBackup(AppStore app) {
  final data = backupOf(app);
  final logs = <String, dynamic>{};
  for (final week in app.program.weeks) {
    for (final day in week.days) {
      if (day.exercises.isEmpty) continue;
      // Historique d'un utilisateur existant : calendrier d'origine
      // (13/07/2026), indépendant du départ de l'instance de test (L4).
      final date = app.program.legacyDateFor(week.n, day.j);
      final at = DateTime(
        date.year,
        date.month,
        date.day,
        18,
      ).toIso8601String();
      final log = SessionLog(
        done: true,
        finishedAt: at,
        title: 'S${week.n} · J${day.j}',
      );
      for (final ex in day.exercises) {
        log.exerciseNames[ex.id] = ex.name;
        log.ex[ex.id] = ExerciseLog(
          sets: List.generate(
            app.setCount(ex),
            (_) => SetEntry(
              kg: '62,5',
              reps: '8',
              rir: '2',
              done: true,
              completedAt: at,
            ),
          ),
          note: 'Note de séance synthétique',
        );
      }
      logs[app.sessionKey(week.n, day.j)] = log.toJson();
    }
  }
  data['logs'] = logs;
  return data;
}

/// Sauvegarde 6.0.x (format 3) d'un gros utilisateur : [filledBackup] plus,
/// en JSON brut, 60 séances perso (dont 20 répétées, donc archivées),
/// 300 résultats de WOD et 30 WOD débloqués. Depuis G2, ces données sont
/// ignorées à l'import (mais encore bornées).
Map<String, dynamic> filledLegacyBackup(AppStore app) {
  final data = filledBackup(app);
  final logs = data['logs'] as Map<String, dynamic>;
  final custom = <Map<String, dynamic>>[];
  for (var i = 1; i <= 60; i++) {
    custom.add({
      'id': '$i',
      'name': 'Perso $i',
      'items': [
        {'uid': 'u$i', 'name': 'Tractions', 'mode': 'classic'},
        {'uid': 'v$i', 'name': 'Dips', 'mode': 'classic'},
      ],
    });
    logs['S0-J$i'] = manualSessionLog('$i');
    if (i <= 20) logs['S0-J$i@r$i'] = manualSessionLog('$i', day: '03');
  }
  final results = <String, List<Object?>>{};
  for (var i = 0; i < 300; i++) {
    results.putIfAbsent('seed${i % 100 + 1}', () => <Object?>[]).add({
      'at': '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')}T07:00:00',
      'score': '12:${(i % 60).toString().padLeft(2, '0')}',
      'seconds': 720 + i % 60,
      'completed': true,
      'notes': 'Résultat synthétique $i',
    });
  }
  data['custom'] = custom;
  data['catalog'] = {
    'deleted': <Object?>[],
    'edits': <String, Object?>{},
    'user': <Object?>[],
    'results': results,
  };
  data['unlocked'] = {for (var i = 1; i <= 30; i++) 'seed$i': 3};
  return data;
}

/// Export format 2 (avant le catalogue compact) : liste complète des WOD,
/// dont un joué, et droits à coût zéro. WOD ignorés depuis G2.
Map<String, dynamic> formatV2() => {
  'kalisTrack': 1,
  'format': 2,
  'pilotage': {'B4': 78},
  'logs': {
    'S8-J1': SessionLog(done: true, finishedAt: '2026-09-01T10:00:00').toJson(),
  },
  'settings': AppSettings().toJson(),
  'wods': [
    {
      'id': 'seed1',
      'name': 'Fran',
      'type': 'fortime',
      'lines': <Object?>[],
      'results': [
        {'at': '2025-05-01T10:00:00', 'score': '9:30'},
      ],
    },
    {'id': 'seed2', 'name': 'Cindy', 'type': 'amrap', 'lines': <Object?>[]},
  ],
  'unlocked': {'seed1': 0, 'seed2': 0},
};

/// Export format 1 (sans champ « format »).
Map<String, dynamic> formatV1() => {
  'kalisTrack': 1,
  'pilotage': {'B4': 77},
  'logs': {
    'S9-J2': SessionLog(done: true, finishedAt: '2026-09-02T10:00:00').toJson(),
  },
  'settings': AppSettings().toJson(),
};
