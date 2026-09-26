// Jeux de données synthétiques L2 (aucune donnée réelle) : utilisateur neuf,
// historique rempli, séances perso répétées, achats normaux et remisés,
// droits anciens à coût zéro, formats historiques, données dégradées.

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';

Map<String, dynamic> backupOf(AppStore app) =>
    jsonDecode(app.exportAll()) as Map<String, dynamic>;

/// Texte « gz: » + base64, comme l'export compact.
String gzText(String json) =>
    'gz:${base64Encode(gzip.encode(utf8.encode(json)))}';

/// Données très compressibles : [bytes] espaces dans un JSON valide.
String compressibleBomb(int bytes) {
  final spaces = Uint8List(bytes)..fillRange(0, bytes, 0x20);
  final json =
      BytesBuilder()
        ..add(utf8.encode('{"kalisTrack":1,"format":3,"pad":"'))
        ..add(spaces)
        ..add(utf8.encode('"}'));
  return 'gz:${base64Encode(gzip.encode(json.takeBytes()))}';
}

/// Historique rempli représentatif : chaque journée d'entraînement des
/// 40 semaines saisie en entier, 60 séances perso (dont 20 répétées, donc
/// archivées), 300 résultats de WOD et 30 achats.
Map<String, dynamic> filledBackup(AppStore app) {
  final data = backupOf(app);
  final logs = <String, dynamic>{};
  for (final week in app.program.weeks) {
    for (final day in week.days) {
      if (day.exercises.isEmpty) continue;
      // Historique d'un utilisateur existant : calendrier d'origine
      // (13/07/2026), indépendant du départ de l'instance de test (L4).
      final date = app.program.legacyDateFor(week.n, day.j);
      final at =
          DateTime(date.year, date.month, date.day, 18).toIso8601String();
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
  final custom = <Map<String, dynamic>>[];
  for (var i = 1; i <= 60; i++) {
    final session = CustomSession(
      id: '$i',
      name: 'Perso $i',
      items: [
        CustomExercise(uid: 'u$i', name: 'Tractions'),
        CustomExercise(uid: 'v$i', name: 'Dips'),
      ],
    );
    custom.add(session.toJson());
    SessionLog occurrence(String day) => SessionLog(
      done: true,
      finishedAt: '2026-0$day-10T19:00:00.000',
      customId: '$i',
      exerciseNames: {'CU-u$i': 'Tractions', 'CU-v$i': 'Dips'},
      ex: {
        'CU-u$i': ExerciseLog(
          sets: List.generate(4, (_) => SetEntry(reps: '10', done: true)),
        ),
        'CU-v$i': ExerciseLog(
          sets: List.generate(4, (_) => SetEntry(reps: '12', done: true)),
        ),
      },
    );
    logs['S0-J$i'] = occurrence('8').toJson();
    if (i <= 20) logs['S0-J$i@r$i'] = occurrence('7').toJson();
  }
  final catalog = app.wods.where(app.isCatalog).toList();
  final results = <String, dynamic>{};
  for (var i = 0; i < 300; i++) {
    final w = catalog[i % 100];
    final list = results.putIfAbsent(w.id, () => <Object?>[]) as List<Object?>;
    list.add(
      WodResult(
        at: '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')}T07:00:00',
        score: '12:${(i % 60).toString().padLeft(2, '0')}',
        seconds: 720 + i % 60,
        notes: 'Résultat synthétique $i',
      ).toJson(),
    );
  }
  data['logs'] = logs;
  data['custom'] = custom;
  (data['catalog'] as Map<String, dynamic>)['results'] = results;
  data['unlocked'] = {for (final w in catalog.take(30)) w.id: app.basePrice(w)};
  return data;
}

/// Achats normaux et remisés (prix payés figés, remise comprise).
Map<String, int> purchases(AppStore app) {
  final catalog = app.wods.where(app.isCatalog).toList();
  final full = catalog.firstWhere((w) => app.basePrice(w) == 3);
  final discounted = catalog.firstWhere(
    (w) => app.basePrice(w) == 4 && w.id != full.id,
  );
  return {full.id: 3, discounted.id: 2};
}

/// Premier WOD du catalogue « seed » et un second, pour les droits anciens.
({String free, String paid}) legacyIds(AppStore app) {
  final seeds = app.wods.where(app.isCatalog).map((w) => w.id).toList();
  return (free: seeds[0], paid: seeds[1]);
}

/// Export format 2 (avant le catalogue compact), avec droits à coût zéro.
Map<String, dynamic> formatV2(AppStore app, Map<String, int> unlocked) => {
  'kalisTrack': 1,
  'format': 2,
  'pilotage': {'B4': 78},
  'logs': {
    'S8-J1': SessionLog(done: true, finishedAt: '2026-09-01T10:00:00').toJson(),
  },
  'settings': AppSettings().toJson(),
  'wods': app.wods.map((w) => w.toJson()).toList(),
  'unlocked': unlocked,
};

/// Export format 1 (sans champ « format »).
Map<String, dynamic> formatV1(AppStore app) => {
  'kalisTrack': 1,
  'pilotage': {'B4': 77},
  'logs': {
    'S9-J2': SessionLog(done: true, finishedAt: '2026-09-02T10:00:00').toJson(),
  },
  'settings': AppSettings().toJson(),
};
