// Modèles du programme v3.3 — miroir du JSON généré depuis le classeur Excel.
import 'package:flutter/material.dart';

double _d(dynamic v) => (v as num).toDouble();

/// Spec de charge : traduction directe des formules Excel du classeur.
class LoadSpec {
  final String type; // system | barbell | acc | fixed | none
  final String? ref; // cellule Pilotage (B8..B11, B25..B45)
  final double? pct;
  final int? dayReps;
  final double? step;
  final double? kg;

  LoadSpec.fixed(double? v)
    : type = v == null ? 'none' : 'fixed',
      ref = null,
      pct = null,
      dayReps = null,
      step = null,
      kg = v;

  LoadSpec.fromJson(Map<String, dynamic> j)
    : type = j['type'] as String,
      ref = j['ref'] as String?,
      pct = j['pct'] == null ? null : _d(j['pct']),
      dayReps = j['dayReps'] as int?,
      step = j['step'] == null ? null : _d(j['step']),
      kg = j['kg'] == null ? null : _d(j['kg']);
}

/// Spec de séries : texte fixe ou volume indexé sur un max du Pilotage.
class SetsSpec {
  final String type; // text | volume
  final String? value;
  final String? prefix;
  final double? coef;
  final String? ref;
  final int? div;
  final String? suffix;

  SetsSpec.text(String v)
    : type = 'text',
      value = v,
      prefix = null,
      coef = null,
      ref = null,
      div = null,
      suffix = null;

  SetsSpec.fromJson(Map<String, dynamic> j)
    : type = j['type'] as String,
      value = j['value'] as String?,
      prefix = j['prefix'] as String?,
      coef = j['coef'] == null ? null : _d(j['coef']),
      ref = j['ref'] as String?,
      div = j['div'] as int?,
      suffix = j['suffix'] as String?;
}

class Exercise {
  final String id;
  final String name;
  final SetsSpec sets;
  final String intensity;
  final LoadSpec load;
  final String rest;
  final int? restSec;
  final String tempo;
  final String cue;
  final bool main;
  final bool prevention;

  /// Renseignés par les séances personnalisées (modes d'exécution).
  final int? forcedSets;
  final Map<String, dynamic>? timer; // {type: emom|amrap|hiit, ...}

  Exercise.manual({
    required this.id,
    required this.name,
    required String setsText,
    this.intensity = '',
    double? kg,
    this.rest = '',
    this.restSec,
    this.tempo = '',
    this.cue = '',
    this.main = false,
    this.forcedSets,
    this.timer,
  }) : sets = SetsSpec.text(setsText),
       load = LoadSpec.fixed(kg),
       prevention = false;

  Exercise.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      sets = SetsSpec.fromJson(j['sets'] as Map<String, dynamic>),
      intensity = j['intensity'] as String? ?? '',
      load = LoadSpec.fromJson(j['load'] as Map<String, dynamic>),
      rest = j['rest'] as String? ?? '',
      restSec = j['restSec'] as int?,
      tempo = j['tempo'] as String? ?? '',
      cue = j['cue'] as String? ?? '',
      main = j['main'] as bool? ?? false,
      prevention = j['prevention'] as bool? ?? false,
      forcedSets = null,
      timer = null;

  /// Format intervalle type « 8× (30 s effort / 30 s repos) ».
  ({int rounds, int work, int rest})? get interval {
    final s = sets.value ?? '';
    final m = RegExp(
      r'^(\d+)\s*[×x]\s*\((\d+)\s*s(?:\s*effort)?\s*/\s*(\d+)\s*s(?:\s*repos)?\)',
    ).firstMatch(s);
    if (m == null) return null;
    return (
      rounds: int.parse(m.group(1)!),
      work: int.parse(m.group(2)!),
      rest: int.parse(m.group(3)!),
    );
  }
}

class DayPlan {
  final int j;
  final String title;
  final String cycle;
  final String conduite;
  final List<Exercise> exercises;

  DayPlan.manual({
    required this.j,
    required this.title,
    this.cycle = '',
    this.conduite = '',
    required this.exercises,
  });

  DayPlan.fromJson(Map<String, dynamic> j0)
    : j = j0['j'] as int,
      title = j0['title'] as String,
      cycle = j0['cycle'] as String? ?? '',
      conduite = j0['conduite'] as String? ?? '',
      exercises =
          (j0['exercises'] as List)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
}

class WeekPlan {
  final int n;
  final String dates;
  final String block;
  final String blockKey;
  final Color color;
  final List<DayPlan> days;

  WeekPlan.manual({
    required this.n,
    this.dates = '',
    required this.block,
    this.blockKey = 'CU',
    required this.color,
    required this.days,
  });

  WeekPlan.fromJson(Map<String, dynamic> j)
    : n = j['n'] as int,
      dates = j['dates'] as String? ?? '',
      block = j['block'] as String,
      blockKey = j['blockKey'] as String,
      color = Color(int.parse('FF${j['color']}', radix: 16)),
      days =
          (j['days'] as List)
              .map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
              .toList();

  DayPlan? day(int j) {
    for (final d in days) {
      if (d.j == j) return d;
    }
    return null;
  }
}

class MainLift {
  final String ref, key, name, unit;
  final double oneRm, target;
  MainLift.fromJson(Map<String, dynamic> j)
    : ref = j['ref'] as String,
      key = j['key'] as String,
      name = j['name'] as String,
      unit = j['unit'] as String,
      oneRm = _d(j['oneRm']),
      target = _d(j['target']);
}

class RepMax {
  final String ref, name;
  final double max, target;
  RepMax.fromJson(Map<String, dynamic> j)
    : ref = j['ref'] as String,
      name = j['name'] as String,
      max = _d(j['max']),
      target = _d(j['target']);
}

class AccessoryRef {
  final String ref, name, note;
  final double refLoad;
  final int refReps;
  AccessoryRef.fromJson(Map<String, dynamic> j)
    : ref = j['ref'] as String,
      name = j['name'] as String,
      note = j['note'] as String? ?? '',
      refLoad = _d(j['refLoad']),
      refReps = j['refReps'] as int;
}

class PilotageDefaults {
  final double bodyweight;
  final List<MainLift> mainLifts;
  final List<RepMax> repMax;
  final List<AccessoryRef> accessories;
  PilotageDefaults.fromJson(Map<String, dynamic> j)
    : bodyweight = _d(j['bodyweight']),
      mainLifts =
          (j['mainLifts'] as List)
              .map((e) => MainLift.fromJson(e as Map<String, dynamic>))
              .toList(),
      repMax =
          (j['repMax'] as List)
              .map((e) => RepMax.fromJson(e as Map<String, dynamic>))
              .toList(),
      accessories =
          (j['accessories'] as List)
              .map((e) => AccessoryRef.fromJson(e as Map<String, dynamic>))
              .toList();
}

class Program {
  final DateTime anchorMonday;
  final PilotageDefaults pilotage;
  final List<WeekPlan> weeks;

  Program.fromJson(Map<String, dynamic> j)
    : anchorMonday = DateTime.parse(j['meta']['anchorMonday'] as String),
      pilotage = PilotageDefaults.fromJson(
        j['pilotage'] as Map<String, dynamic>,
      ),
      weeks =
          (j['weeks'] as List)
              .map((w) => WeekPlan.fromJson(w as Map<String, dynamic>))
              .toList();

  WeekPlan week(int n) => weeks.firstWhere((w) => w.n == n);

  /// Semaine du programme correspondant à une date (bornée 1..40).
  int weekFor(DateTime date) {
    // Compare des jours civils : le changement d'heure ne doit pas décaler
    // le lundi dans la semaine précédente (journée de 23 ou 25 heures).
    final d0 = DateTime.utc(
      anchorMonday.year,
      anchorMonday.month,
      anchorMonday.day,
    );
    final d1 = DateTime.utc(date.year, date.month, date.day);
    final w = (d1.difference(d0).inDays / 7).floor() + 1;
    return w.clamp(1, weeks.length);
  }

  DateTime dateFor(int week, int day) => DateTime(
    anchorMonday.year,
    anchorMonday.month,
    anchorMonday.day + (week - 1) * 7 + day - 1,
  );

  bool containsDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(dateFor(1, 1)) &&
        day.isBefore(dateFor(weeks.length + 1, 1));
  }

  /// J courant (lundi = J1 … dimanche = J7).
  int dayFor(DateTime date) => date.weekday;
}
