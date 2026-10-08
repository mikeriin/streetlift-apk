// L6 — Jeux de données synthétiques reproductibles pour les mesures de
// performance (KT-023). Aucune donnée réelle : valeurs tirées d'un générateur
// pseudo-aléatoire à graine fixe (mulberry32, le même que les simulations
// Koach), dates fixes. Le même code produit exactement le même document sur
// la base et sur la candidate : il n'utilise que des API publiques présentes
// dans les deux versions (6.1 et ultérieures depuis G2).
//
// Quatre profils :
// - `neuf`     : aucune donnée (première ouverture) ;
// - `regulier` : 11 semaines du programme ;
// - `long`     : les 40 semaines ;
// - `charge`   : les 40 semaines, une note par exercice.
// G2 : les séances perso, résultats WOD, WOD perso ou modifiés, achats et
// envies des anciens profils ont été retirés avec ces fonctions.

import 'dart:convert';

import 'package:streetlift_tracker/store.dart';

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
  final weeks = profile == 'regulier' ? 11 : 40;
  final notes = profile == 'charge';

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
      // Chaque série a sa propre heure de validation (toutes les 2 min 30),
      // comme dans l'application ; la séance se termine après la dernière.
      var clock = DateTime(date.year, date.month, date.day, 17);
      String nextSet() => _iso(clock = clock.add(const Duration(seconds: 150)));
      final log = SessionLog(done: true, title: 'S${week.n} · J${day.j}');
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
              completedAt: nextSet(),
            ),
          ),
          note: notes ? 'Note synthétique ${r.next(1000)}' : '',
        );
      }
      log.finishedAt = _iso(clock.add(const Duration(minutes: 5)));
      logs[app.sessionKey(week.n, day.j)] = log.toJson();
    }
  }

  data['logs'] = logs;
  return data;
}

/// Inventaire réel d'un document (compté, jamais recopié d'un audit).
Map<String, int> perfInventory(Map<String, dynamic>? data) {
  if (data == null) return {'seances': 0, 'series': 0};
  final logs = data['logs'] as Map<String, dynamic>;
  var sets = 0;
  for (final l in logs.values) {
    for (final e in ((l as Map)['ex'] as Map).values) {
      sets += ((e as Map)['sets'] as List).length;
    }
  }
  return {'seances': logs.length, 'series': sets};
}
