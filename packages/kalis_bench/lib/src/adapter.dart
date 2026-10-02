/// Adaptateur du profil du banc vers le profil d'athlète de `kalis_core`.
///
/// C'est le **seul** endroit qui connaît le schéma du profil des moteurs.
/// Aujourd'hui : `AthleteProfile` v2 (kalis_core 0.3.0). CP1 et CA1 le
/// rebrancheront sur le profil v3 de CQ : il suffit de réécrire
/// [adaptProfile] (voir `docs/PROFILS.md`, § Adaptateur).
library;

import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';

/// Premier jour des programmes du banc (un lundi, celui des simulations de
/// `kalis_adapt` et des rapports de `kalis_plan`).
final CivilDate benchStartDate = CivilDate(2026, 10, 5);

/// Profil adapté et ce que l'adaptation a perdu.
final class AdaptedProfile {
  /// Résultat de l'adaptation.
  const AdaptedProfile(this.profile, this.lost);

  /// Profil lisible par les moteurs.
  final AthleteProfile profile;

  /// Informations du profil du banc que le profil des moteurs ne sait pas
  /// porter (codes stables, voir [lostFieldLabels]).
  final List<String> lost;
}

/// Nom français de chaque information perdue par l'adaptation.
const Map<String, String> lostFieldLabels = <String, String>{
  'records_exact': 'valeur exacte des records (le profil v2 lit une '
      'fourchette : la valeur est donnée comme bas et haut)',
  'records_date': 'ancienneté des tests',
  'training_age': "ancienneté d'entraînement en mois",
  'event_kind': "nature de l'échéance (compétition ou test), priorité et "
      "format de l'épreuve : seul un objectif daté par mouvement est "
      'transmis',
  'weak_points': 'points faibles',
  'injury_history': 'antécédents de blessure sans gêne actuelle',
  'injury_label': 'description de la blessure',
  'sleep': 'sommeil habituel',
  'stress': 'stress de vie',
  'physical_job': 'travail physique',
  'energy_deficit': 'déficit énergétique en cours',
  'other_sports': 'autres sports pratiqués',
  'break': "durée de la coupure avant le programme",
  'specialization': 'mouvements prioritaires et mouvements à entretenir',
};

/// Jour de l'échéance située à [weeksOut] semaines du début [start] : le
/// samedi de la dernière semaine.
CivilDate eventDate(CivilDate start, int weeksOut) =>
    start.addDays(7 * weeksOut - 2);

Map<String, Object?> _goalJson(
  String id,
  BenchTarget t,
  CivilDate start,
  int weeksOut,
) => <String, Object?>{
  'id': id,
  'kind': GoalKind.performance.code,
  'origin': GoalOrigin.user.code,
  'createdOn': start.iso,
  'exerciseId': t.exerciseId,
  'metric': t.metric.code,
  if (t.targetValue != null) 'targetValue': t.targetValue,
  if (t.distanceMeters != null) 'distanceMeters': t.distanceMeters,
  if (t.loadKg != null) 'loadKg': t.loadKg,
  if (t.durationSeconds != null) 'durationSeconds': t.durationSeconds,
  'targetDate': eventDate(start, weeksOut).iso,
};

/// Profil des moteurs du profil du banc [p], pour un programme qui
/// commence le [start].
///
/// [FormatException] si le profil obtenu n'est pas lisible ;
/// [ArgumentError] s'il viole un invariant du contrat de `kalis_core`.
AdaptedProfile adaptProfile(BenchProfile p, {CivilDate? start}) {
  final day = start ?? benchStartDate;
  final lost = <String>[];
  final json = Map<String, Object?>.of(p.core);
  json['schemaVersion'] = 2;
  json['createdOn'] = day.iso;
  json['updatedOn'] = day.iso;
  json.putIfAbsent('likedExerciseIds', () => <Object?>[]);
  json.putIfAbsent('dislikedExerciseIds', () => <Object?>[]);
  json.putIfAbsent('loadIncrements', () => <Object?>[]);
  json.putIfAbsent('guidanceMode', () => GuidanceMode.assisted.code);

  final levels = <Object?>[];
  for (final r in p.records) {
    levels.add(<String, Object?>{
      'exerciseId': r.exerciseId,
      'measure': r.measure.code,
      'known': true,
      'low': r.value,
      'high': r.value,
      if (r.distanceMeters != null) 'distanceMeters': r.distanceMeters,
    });
    if (r.testedWeeksAgo != null && !lost.contains('records_date')) {
      lost.add('records_date');
    }
  }
  if (p.records.isNotEmpty) {
    lost.add('records_exact');
  }
  for (final id in p.unknownLevels) {
    levels.add(<String, Object?>{
      'exerciseId': id,
      'measure': LevelMeasure.maxReps.code,
      'known': false,
    });
  }
  json['movementLevels'] = levels;

  final goals = <Object?>[];
  for (final e in p.events) {
    for (var i = 0; i < e.targets.length; i++) {
      goals.add(_goalJson('${e.id}-${i + 1}', e.targets[i], day, e.weeksOut));
    }
  }
  if (p.events.isNotEmpty) {
    lost.add('event_kind');
  }
  for (final g in p.goals) {
    goals.add(_goalJson(g.id, g.target, day, g.weeksOut));
  }
  final habitSessions = p.habitSessionsPerWeek;
  final habitWeeks = p.habitWeeks;
  if (habitSessions != null && habitWeeks != null) {
    goals.add(<String, Object?>{
      'id': 'habitude',
      'kind': GoalKind.habit.code,
      'origin': GoalOrigin.user.code,
      'createdOn': day.iso,
      'sessionsPerWeek': habitSessions,
      'weeks': habitWeeks,
    });
  }
  json['goals'] = goals;

  final limitations = <Object?>[];
  for (final i in p.injuries) {
    if (i.discomfort > 0) {
      limitations.add(<String, Object?>{
        'zone': i.zone.code,
        'side': i.side.code,
        if (i.joint != null) 'joint': i.joint!.code,
        'discomfort': i.discomfort,
      });
    } else if (!lost.contains('injury_history')) {
      lost.add('injury_history');
    }
    if (!lost.contains('injury_label')) {
      lost.add('injury_label');
    }
  }
  json['limitations'] = limitations;

  lost.add('training_age');
  if (p.weakPoints.isNotEmpty) {
    lost.add('weak_points');
  }
  if (p.recovery.sleepHours != null || p.recovery.sleepQuality != null) {
    lost.add('sleep');
  }
  if (p.recovery.stress != null) {
    lost.add('stress');
  }
  if (p.recovery.physicalJob != 'none') {
    lost.add('physical_job');
  }
  if (p.recovery.energyDeficit) {
    lost.add('energy_deficit');
  }
  if (p.recovery.otherSports.isNotEmpty) {
    lost.add('other_sports');
  }
  if (p.breakWeeks > 0) {
    lost.add('break');
  }
  if (p.priorityExerciseIds.isNotEmpty || p.maintainExerciseIds.isNotEmpty) {
    lost.add('specialization');
  }

  final profile = AthleteProfile.fromJson(json);
  final violations = profile.validate();
  if (violations.isNotEmpty) {
    throw ArgumentError.value(
      p.key,
      'profil',
      'profil adapté invalide : ${violations.join(' ; ')}',
    );
  }
  return AdaptedProfile(profile, List<String>.unmodifiable(lost));
}
