// L6 — Jeux de données synthétiques reproductibles pour les mesures de
// performance (KT-023). Aucune donnée réelle : valeurs tirées d'un générateur
// pseudo-aléatoire à graine fixe (mulberry32, le même que les simulations
// Koach), dates fixes. Le même code produit exactement le même document sur
// la base 3.0.2 et sur la candidate : il n'utilise que des API publiques
// présentes dans les deux versions.
//
// Quatre profils :
// - `neuf`     : aucune donnée (première ouverture) ;
// - `regulier` : 11 semaines du programme, 20 séances perso, 40 résultats WOD ;
// - `long`     : les 40 semaines, 60 séances perso (80 occurrences),
//                300 résultats WOD, 30 achats ;
// - `charge`   : les 40 semaines, 150 séances perso (600 occurrences à
//                6 exercices), 1 500 résultats WOD sur 600 WOD, 50 WOD perso,
//                30 WOD du catalogue modifiés, 150 achats, 40 envies, une
//                note par exercice. Chargé mais légitime : très en deçà des
//                limites d'import (20 000 séances, 100 000 résultats).

import 'dart:convert';

import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';

/// Générateur mulberry32 (entiers 32 bits), identique d'une plate-forme à
/// l'autre.
class PerfRandom {
  int _state;
  PerfRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Entier dans [0, n).
  int next(int n) => nextUint32() % n;
}

const perfProfiles = ['neuf', 'regulier', 'long', 'charge'];

/// Graine fixe, commune à tous les profils.
const perfSeed = 20260926;

/// Départ du programme des fixtures (lundi).
final perfStart = DateTime(2026, 1, 5);

String _iso(DateTime d) => d.toIso8601String();

String _kg(PerfRandom r) {
  final whole = 20 + r.next(90);
  return r.next(2) == 0 ? '$whole' : '$whole,5';
}

/// Document de sauvegarde (format 3) du profil, construit sur l'export
/// d'une instance neuve [app] déjà initialisée. `neuf` renvoie null.
Map<String, dynamic>? perfBackup(AppStore app, String profile) {
  if (profile == 'neuf') return null;
  final r = PerfRandom(perfSeed + perfProfiles.indexOf(profile));
  final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
  final heavy = profile == 'charge';
  final weeks = profile == 'regulier' ? 11 : 40;
  final notes = heavy;

  data['programStart'] = {
    'status': 'set',
    'date':
        '${perfStart.year}-${perfStart.month.toString().padLeft(2, '0')}-${perfStart.day.toString().padLeft(2, '0')}',
    'origin': 'user',
  };
  // Références renseignées : toutes celles du tableau, valeurs plausibles.
  final pilotage = <String, dynamic>{};
  final status = <String, dynamic>{};
  for (final ref in app.referenceRefs) {
    pilotage[ref] = ref == 'B4' ? 72.0 : (10 + r.next(90)).toDouble();
    status[ref] = 'set';
  }
  data['pilotage'] = pilotage;
  data['referenceStatus'] = status;

  final logs = <String, dynamic>{};
  for (final week in app.program.weeks) {
    if (week.n > weeks) break;
    for (final day in week.days) {
      if (day.exercises.isEmpty) continue;
      final date = perfStart.add(Duration(days: (week.n - 1) * 7 + day.j - 1));
      final at = _iso(DateTime(date.year, date.month, date.day, 18));
      final log = SessionLog(
        done: true,
        finishedAt: at,
        title: 'S${week.n} · J${day.j}',
      );
      for (final ex in day.exercises) {
        log.exerciseNames[ex.id] = ex.name;
        log.ex[ex.id] = ExerciseLog(
          sets: List.generate(
            app.setCount(ex).clamp(1, 12),
            (_) => SetEntry(
              kg: _kg(r),
              reps: '${3 + r.next(10)}',
              rir: '${r.next(4)}',
              done: true,
              completedAt: at,
            ),
          ),
          note: notes ? 'Note synthétique ${r.next(1000)}' : '',
        );
      }
      logs[app.sessionKey(week.n, day.j)] = log.toJson();
    }
  }

  final templates = switch (profile) {
    'regulier' => 20,
    'long' => 60,
    _ => 150,
  };
  final archivesPer = switch (profile) {
    'regulier' => 0,
    'long' => 0,
    _ => 3,
  };
  const names = [
    'Tractions',
    'Dips',
    'Pompes',
    'Squat',
    'Muscle-up',
    'Rowing barre',
  ];
  final custom = <Map<String, dynamic>>[];
  for (var i = 1; i <= templates; i++) {
    final count = heavy ? 6 : 2;
    final items = [
      for (var e = 0; e < count; e++)
        CustomExercise(uid: 'p${i}x$e', name: names[e % names.length]),
    ];
    custom.add(CustomSession(id: '$i', name: 'Perso $i', items: items).toJson());
    SessionLog occurrence(int n) {
      final date = perfStart.add(Duration(days: (i * 3 + n * 11) % 270));
      final at = _iso(DateTime(date.year, date.month, date.day, 7));
      return SessionLog(
        done: true,
        finishedAt: at,
        title: 'Perso $i',
        customId: '$i',
        exerciseNames: {for (final e in items) 'CU-${e.uid}': e.name},
        ex: {
          for (final e in items)
            'CU-${e.uid}': ExerciseLog(
              sets: List.generate(
                4,
                (_) => SetEntry(
                  kg: r.next(3) == 0 ? _kg(r) : '',
                  reps: '${5 + r.next(15)}',
                  done: true,
                  completedAt: at,
                ),
              ),
              note: notes ? 'Perso ${r.next(1000)}' : '',
            ),
        },
      );
    }

    logs['S0-J$i'] = occurrence(0).toJson();
    for (var a = 1; a <= archivesPer; a++) {
      logs['S0-J$i@a$a'] = occurrence(a).toJson();
    }
    // `long` : 20 séances répétées une fois (comme la fixture L2).
    if (profile == 'long' && i <= 20) {
      logs['S0-J$i@r$i'] = occurrence(1).toJson();
    }
  }
  data['logs'] = logs;
  data['custom'] = custom;

  final catalog = app.wods.where(app.isCatalog).toList();
  final resultCount = switch (profile) {
    'regulier' => 40,
    'long' => 300,
    _ => 1500,
  };
  final spread = switch (profile) {
    'regulier' => 25,
    'long' => 100,
    _ => 600,
  };
  final results = <String, dynamic>{};
  for (var i = 0; i < resultCount; i++) {
    final w = catalog[(i * 7) % spread];
    final list = results.putIfAbsent(w.id, () => <Object?>[]) as List<Object?>;
    final day = perfStart.add(Duration(days: (i * 5) % 270));
    list.add(
      WodResult(
        at: _iso(DateTime(day.year, day.month, day.day, 12)),
        score: '${10 + r.next(20)}:${r.next(60).toString().padLeft(2, '0')}',
        seconds: 600 + r.next(1200),
        notes: heavy ? 'Résultat synthétique $i' : '',
      ).toJson(),
    );
  }
  final cat = data['catalog'] as Map<String, dynamic>;
  cat['results'] = results;
  if (heavy) {
    cat['user'] = [
      for (var i = 0; i < 50; i++)
        {
          'id': 'perf$i',
          'name': 'WOD perso $i',
          'type': 'fortime',
          'rounds': 3 + i % 5,
          'restSec': 0,
          'minutes': 0,
          'interval': 60,
          'scheme': '',
          'lines': ['${10 + i % 10} pompes', '${5 + i % 5} tractions', '20 squats'],
          'notes': '',
          'source': 'Perso',
        },
    ];
    final edits = <String, dynamic>{};
    for (final w in catalog.skip(700).take(30)) {
      edits[w.id] = {
        'id': w.id,
        'name': '${w.name} (modifié)',
        'type': w.type,
        'rounds': w.rounds,
        'restSec': w.restSec,
        'minutes': w.minutes,
        'interval': w.interval,
        'scheme': w.scheme,
        'lines': w.lines,
        'notes': w.notes,
        'source': w.source,
      };
    }
    cat['edits'] = edits;
  }
  final purchases = switch (profile) {
    'regulier' => 10,
    'long' => 30,
    _ => 150,
  };
  data['unlocked'] = {
    for (final w in catalog.take(purchases)) w.id: app.basePrice(w),
  };
  data['wishlist'] = [
    for (final w in catalog.skip(purchases).take(heavy ? 40 : 5)) w.id,
  ];
  return data;
}

/// Inventaire réel d'un document (compté, jamais recopié d'un audit).
Map<String, int> perfInventory(Map<String, dynamic>? data) {
  if (data == null) {
    return {'seances': 0, 'series': 0, 'resultatsWod': 0, 'wodPerso': 0};
  }
  final logs = data['logs'] as Map<String, dynamic>;
  var sets = 0;
  for (final l in logs.values) {
    for (final e in ((l as Map)['ex'] as Map).values) {
      sets += ((e as Map)['sets'] as List).length;
    }
  }
  final cat = data['catalog'] as Map<String, dynamic>;
  var results = 0;
  for (final l in (cat['results'] as Map).values) {
    results += (l as List).length;
  }
  return {
    'seances': logs.length,
    'series': sets,
    'resultatsWod': results,
    'wodPerso': (cat['user'] as List).length,
    'wodModifies': (cat['edits'] as Map).length,
    'achats': (data['unlocked'] as Map).length,
    'seancesPersoModeles': (data['custom'] as List).length,
  };
}
