part of 'contracts.dart';

// Invariants croisés des contrats (ceux qu'une borne par champ ne suffit
// pas à exprimer). Chaque fonction est appelée par le `collectViolations`
// généré du type correspondant.

void _validateDisciplineMix(DisciplineMix v, String path, List<Violation> out) {
  var sum = v.primaryPct;
  final seen = <TrainingDiscipline>{v.primary};
  for (var i = 0; i < v.secondaries.length; i++) {
    final s = v.secondaries[i];
    sum += s.pct;
    if (!seen.add(s.discipline)) {
      out.add(
        Violation('$path.secondaries[$i]', 'duplicate', s.discipline.code),
      );
    }
    if (s.pct > v.primaryPct) {
      out.add(
        Violation(
          '$path.secondaries[$i].pct',
          'secondary_above_primary',
          '${s.pct} > ${v.primaryPct}',
        ),
      );
    }
  }
  if (sum != 100) {
    out.add(Violation(path, 'sum_not_100', 'somme des parts = $sum'));
  }
}

void _validateStreetMode(StreetMode v, String path, List<Violation> out) {
  final sum = v.streetliftingPct + v.setsRepsPct + v.calisthenicsPct;
  if (sum != 100) {
    out.add(Violation(path, 'sum_not_100', 'somme des parts = $sum'));
  }
  final primaryPct = v.pctOf(v.primary);
  if (primaryPct <= 0) {
    out.add(Violation('$path.primary', 'primary_without_share', 'part nulle'));
  }
  for (final style in StreetStyle.values) {
    if (v.pctOf(style) > primaryPct) {
      out.add(
        Violation(
          path,
          'secondary_above_primary',
          '${style.code} > principale',
        ),
      );
    }
  }
}

void _validateMovementLevel(MovementLevel v, String path, List<Violation> out) {
  final low = v.low;
  final high = v.high;
  if (v.known) {
    if (low == null || high == null) {
      out.add(Violation(path, 'range_missing', 'fourchette attendue'));
    } else if (low > high) {
      out.add(Violation(path, 'range_inverted', '$low > $high'));
    }
  } else if (low != null || high != null) {
    out.add(
      Violation(path, 'value_on_unknown', '« je ne sais pas » sans valeur'),
    );
  }
  final timed = v.measure == LevelMeasure.timeSeconds;
  if (timed != (v.distanceMeters != null)) {
    out.add(
      Violation(
        '$path.distanceMeters',
        'distance_mismatch',
        'distance attendue pour time_seconds seulement',
      ),
    );
  }
}

void _validateGoal(Goal v, String path, List<Violation> out) {
  void forbid(String field, Object? value) {
    if (value != null) {
      out.add(
        Violation('$path.$field', 'unexpected_field', 'kind ${v.kind.code}'),
      );
    }
  }

  void require(String field, Object? value) {
    if (value == null) {
      out.add(
        Violation('$path.$field', 'missing_field', 'kind ${v.kind.code}'),
      );
    }
  }

  switch (v.kind) {
    case GoalKind.performance:
      require('exerciseId', v.exerciseId);
      require('metric', v.metric);
      require('targetDate', v.targetDate);
      forbid('sessionsPerWeek', v.sessionsPerWeek);
      forbid('weeks', v.weeks);
      final metric = v.metric;
      if (metric != null) {
        if (metric == GoalMetric.skillUnlocked) {
          forbid('targetValue', v.targetValue);
        } else {
          require('targetValue', v.targetValue);
        }
        if (metric == GoalMetric.timeSeconds) {
          require('distanceMeters', v.distanceMeters);
        } else {
          forbid('distanceMeters', v.distanceMeters);
        }
        if (metric != GoalMetric.maxReps) {
          forbid('loadKg', v.loadKg);
        }
        if (metric == GoalMetric.distanceMeters) {
          require('durationSeconds', v.durationSeconds);
        } else {
          forbid('durationSeconds', v.durationSeconds);
        }
      }
      final targetDate = v.targetDate;
      if (targetDate != null && targetDate < v.createdOn) {
        out.add(
          Violation('$path.targetDate', 'date_before_creation', targetDate.iso),
        );
      }
    case GoalKind.habit:
      require('sessionsPerWeek', v.sessionsPerWeek);
      require('weeks', v.weeks);
      forbid('exerciseId', v.exerciseId);
      forbid('metric', v.metric);
      forbid('targetValue', v.targetValue);
      forbid('distanceMeters', v.distanceMeters);
      forbid('loadKg', v.loadKg);
      forbid('durationSeconds', v.durationSeconds);
      forbid('targetDate', v.targetDate);
  }
}

void _validateAthleteProfile(
  AthleteProfile v,
  String path,
  List<Violation> out,
) {
  checkDistinct(
    out,
    '$path.availability',
    v.availability.map((d) => d.weekday),
  );
  checkDistinct(out, '$path.places', v.places);
  checkDistinct(out, '$path.equipment', v.equipment);
  checkDistinct(out, '$path.likedExerciseIds', v.likedExerciseIds);
  checkDistinct(out, '$path.dislikedExerciseIds', v.dislikedExerciseIds);
  checkDistinct(out, '$path.goals', v.goals.map((g) => g.id));
  checkDistinct(
    out,
    '$path.loadIncrements',
    v.loadIncrements.map((i) => i.loadType),
  );
  checkDistinct(
    out,
    '$path.movementLevels',
    v.movementLevels.map((m) => '${m.exerciseId}|${m.measure.code}'),
  );
  final disliked = v.dislikedExerciseIds.toSet();
  for (final id in v.likedExerciseIds) {
    if (disliked.contains(id)) {
      out.add(Violation('$path.likedExerciseIds', 'liked_and_disliked', id));
    }
  }
  if (v.updatedOn < v.createdOn) {
    out.add(
      Violation('$path.updatedOn', 'date_before_creation', v.updatedOn.iso),
    );
  }
  if (v.birthYear > v.createdOn.year) {
    out.add(Violation('$path.birthYear', 'birth_after_creation', ''));
  }
  final byPlace = v.equipmentByPlace;
  if (byPlace != null) {
    checkDistinct(out, '$path.equipmentByPlace', byPlace.map((p) => p.place));
    final all = v.equipment.toSet();
    for (var i = 0; i < byPlace.length; i++) {
      if (!v.places.contains(byPlace[i].place)) {
        out.add(
          Violation('$path.equipmentByPlace[$i].place', 'unknown_place', ''),
        );
      }
      for (final item in byPlace[i].equipment) {
        if (!all.contains(item)) {
          out.add(
            Violation(
              '$path.equipmentByPlace[$i].equipment',
              'not_in_equipment',
              item,
            ),
          );
        }
      }
    }
  }
  for (var i = 0; i < v.availability.length; i++) {
    final place = v.availability[i].place;
    if (place != null && !v.places.contains(place)) {
      out.add(Violation('$path.availability[$i].place', 'unknown_place', ''));
    }
  }
  final known = v.knownExerciseIds;
  final cannot = v.cannotDoExerciseIds;
  if (known != null) {
    checkDistinct(out, '$path.knownExerciseIds', known);
  }
  if (cannot != null) {
    checkDistinct(out, '$path.cannotDoExerciseIds', cannot);
    final knownSet = (known ?? const <String>[]).toSet();
    for (final id in cannot) {
      if (knownSet.contains(id)) {
        out.add(Violation('$path.cannotDoExerciseIds', 'known_and_cannot', id));
      }
    }
  }
  final street = v.streetMode;
  if (street != null && street.toDisciplineMix() != v.disciplines) {
    out.add(
      Violation(
        '$path.disciplines',
        'street_mode_mismatch',
        'disciplines ≠ image du mode street',
      ),
    );
  }
  for (var i = 0; i < v.limitations.length; i++) {
    final l = v.limitations[i];
    final joint = l.joint;
    if (joint != null && joint != l.zone.joint) {
      out.add(
        Violation('$path.limitations[$i].joint', 'joint_zone_mismatch', ''),
      );
    }
  }
  // Schéma 3 (0.4.0) : un champ du schéma 3 n'existe pas dans un profil 2.
  if (v.schemaVersion < 3) {
    for (final name in v.schema3FieldsPresent) {
      out.add(Violation('$path.$name', 'schema3_field', 'schemaVersion 2'));
    }
  }
  final events = v.events;
  if (events != null) {
    checkDistinct(out, '$path.events', events.map((e) => e.id));
  }
  final skills = v.skills;
  if (skills != null) {
    checkDistinct(out, '$path.skills', skills.map((s) => s.targetExerciseId));
  }
  if (events != null) {
    final goalIds = <String>{for (final g in v.goals) g.id};
    for (var i = 0; i < events.length; i++) {
      for (final id in events[i].goalIds ?? const <String>[]) {
        if (!goalIds.contains(id)) {
          out.add(Violation('$path.events[$i].goalIds', 'unknown_goal', id));
        }
      }
    }
  }
  final recentTraining = v.recentTraining;
  if (recentTraining != null) {
    checkDistinct(
      out,
      '$path.recentTraining',
      recentTraining.map((r) => r.exerciseId),
    );
  }
  if (v.targetBodyWeightKg != null &&
      v.bodyWeightGoal != BodyWeightGoal.lose &&
      v.bodyWeightGoal != BodyWeightGoal.gain) {
    out.add(
      Violation(
        '$path.targetBodyWeightKg',
        'unexpected_field',
        'bodyWeightGoal ≠ lose, gain',
      ),
    );
  }
  final weakPoints = v.weakPoints;
  if (weakPoints != null) {
    checkDistinct(
      out,
      '$path.weakPoints',
      weakPoints.map((w) => '${w.exerciseId}|${w.kind.code}'),
    );
  }
  final lifestyle = v.lifestyleUpdatedOn;
  if (lifestyle != null && lifestyle < v.createdOn) {
    out.add(
      Violation(
        '$path.lifestyleUpdatedOn',
        'date_before_creation',
        lifestyle.iso,
      ),
    );
  }
}

void _validateSetTarget(SetTarget v, String path, List<Violation> out) {
  void ordered(String name, int? low, int? high) {
    if (low != null && high != null && low > high) {
      out.add(Violation(path, 'range_inverted', '$name : $low > $high'));
    }
  }

  ordered('reps', v.repsLow, v.repsHigh);
  ordered('seconds', v.secondsLow, v.secondsHigh);
}

void _validateTrainingBreak(TrainingBreak v, String path, List<Violation> out) {
  final end = v.endDate;
  if (end != null && end < v.startDate) {
    out.add(Violation('$path.endDate', 'dates_not_ordered', end.iso));
  }
}

void _validateSetRecord(SetRecord v, String path, List<Violation> out) {
  if (v.reps == null &&
      v.seconds == null &&
      v.distanceMeters == null &&
      v.calories == null) {
    out.add(Violation(path, 'no_measure', 'aucune mesure'));
  }
  // 0.4.0 : les répétitions de la série sont le total de ses parties.
  final parts = v.parts;
  final reps = v.reps;
  if (parts != null && parts.isNotEmpty && reps != null) {
    var total = 0;
    var counted = true;
    for (final part in parts) {
      final partReps = part.reps;
      if (partReps == null) {
        counted = false;
      } else {
        total += partReps;
      }
    }
    if (counted && total != reps) {
      out.add(Violation('$path.parts', 'parts_mismatch', '$total ≠ $reps'));
    }
  }
}

// 0.4.0 : un résultat au plus par groupe d'exercices enchaînés.
void _validateSessionRecord(SessionRecord v, String path, List<Violation> out) {
  final groupResults = v.groupResults;
  if (groupResults != null) {
    checkDistinct(
      out,
      '$path.groupResults',
      groupResults.map((g) => g.groupId),
    );
  }
}

// 0.4.0 : groupes distincts, et chacun a au moins un membre dans la séance.
void _validateGroups(
  List<GroupSpec>? groups,
  List<ExercisePrescription> items,
  String path,
  List<Violation> out,
) {
  if (groups == null) {
    return;
  }
  checkDistinct(out, '$path.groups', groups.map((g) => g.groupId));
  final used = <String>{};
  for (final item in items) {
    final groupId = item.groupId;
    if (groupId != null) {
      used.add(groupId);
    }
  }
  for (var i = 0; i < groups.length; i++) {
    if (!used.contains(groups[i].groupId)) {
      out.add(
        Violation(
          '$path.groups[$i].groupId',
          'unknown_group',
          groups[i].groupId,
        ),
      );
    }
  }
}

void _validateDayPrescription(
  DayPrescription v,
  String path,
  List<Violation> out,
) {
  _validateGroups(v.groups, v.items, path, out);
}

void _validateSessionPlan(SessionPlan v, String path, List<Violation> out) {
  _validateGroups(v.groups, v.items, path, out);
}

// 0.4.0 : la cause d'un échec ne se dit que pour une tentative manquée.
void _validateAttemptResult(AttemptResult v, String path, List<Violation> out) {
  if (v.success && v.failure != null) {
    out.add(Violation('$path.failure', 'unexpected_field', 'success'));
  }
}

void _validateTrainingLog(TrainingLog v, String path, List<Violation> out) {
  checkDistinct(out, '$path.sessions', v.sessions.map((s) => s.id));
  for (var i = 1; i < v.sessions.length; i++) {
    if (v.sessions[i].date < v.sessions[i - 1].date) {
      out.add(
        Violation(
          '$path.sessions[$i].date',
          'not_chronological',
          v.sessions[i].date.iso,
        ),
      );
    }
  }
}

void _validatePlanLock(PlanLock v, String path, List<Violation> out) {
  void require(String field, Object? value) {
    if (value == null) {
      out.add(
        Violation('$path.$field', 'missing_field', 'kind ${v.kind.code}'),
      );
    }
  }

  switch (v.kind) {
    case LockKind.keepSlot:
      require('slotId', v.slotId);
      require('exerciseId', v.exerciseId);
    case LockKind.requireExercise:
    case LockKind.excludeExercise:
      require('exerciseId', v.exerciseId);
    case LockKind.keepDay:
      require('dayIndex', v.dayIndex);
  }
}

void _validatePass1Plan(Pass1Plan v, String path, List<Violation> out) {
  final slotIds = <String>[];
  for (var i = 0; i < v.days.length; i++) {
    if (v.days[i].dayIndex != i) {
      out.add(
        Violation(
          '$path.days[$i].dayIndex',
          'index_mismatch',
          '${v.days[i].dayIndex} ≠ $i',
        ),
      );
    }
    slotIds.addAll(v.days[i].slots.map((s) => s.slotId));
  }
  checkDistinct(out, '$path.days', slotIds);
  checkDistinct(out, '$path.days', v.days.map((d) => 'jour ${d.weekday}'));
}

void _validateReviewAction(ReviewAction v, String path, List<Violation> out) {
  void require(String field, Object? value) {
    if (value == null) {
      out.add(
        Violation('$path.$field', 'missing_field', 'kind ${v.kind.code}'),
      );
    }
  }

  switch (v.kind) {
    case ReviewKind.canDo:
    case ReviewKind.cannotDo:
    case ReviewKind.dislike:
    case ReviewKind.remove:
      require('slotId', v.slotId);
    case ReviewKind.add:
      require('dayIndex', v.dayIndex);
      require('exerciseId', v.exerciseId);
    case ReviewKind.replace:
      require('slotId', v.slotId);
      require('replacementExerciseId', v.replacementExerciseId);
  }
}

void _validateExercisePrescription(
  ExercisePrescription v,
  String path,
  List<Violation> out,
) {
  void pair(String name, int? low, int? high) {
    if ((low == null) != (high == null)) {
      out.add(Violation(path, 'range_incomplete', name));
    } else if (low != null && high != null && low > high) {
      out.add(Violation(path, 'range_inverted', '$name : $low > $high'));
    }
  }

  pair('reps', v.repsLow, v.repsHigh);
  pair('seconds', v.secondsLow, v.secondsHigh);
  final measures = <Object?>[
    v.repsLow,
    v.secondsLow,
    v.distanceMeters,
    v.calories,
  ].where((m) => m != null).length;
  if (measures != 1) {
    out.add(
      Violation(
        path,
        'measure_count',
        '$measures familles de mesure, 1 attendue',
      ),
    );
  }
  if (v.loadBasis == LoadBasis.unloaded && v.startLoadKg != null) {
    out.add(Violation('$path.startLoadKg', 'unexpected_field', 'unloaded'));
  }
  final targets = v.setTargets;
  if (targets != null && targets.length != v.sets) {
    out.add(
      Violation(
        '$path.setTargets',
        'set_count',
        '${targets.length} cibles pour ${v.sets} séries',
      ),
    );
  }
  // 0.4.0 : un test se déclare sur une prescription de rôle « test ».
  if (v.test != null && v.kind != SetKind.test) {
    out.add(Violation('$path.test', 'unexpected_field', 'kind ≠ test'));
  }
  final technique = v.technique;
  if (technique != null && technique.lastSetOnly != true) {
    _validateTechniqueInPrescription(v, technique, path, out);
  }
  // Deux écritures de la même intensité doivent s'accorder.
  final intensity = v.intensity;
  if (intensity != null) {
    final low = intensity.value;
    final high = intensity.valueHigh ?? low;
    final percent = v.percentOfOneRm;
    if (intensity.basis == IntensityBasis.percentOneRm &&
        intensity.referenceExerciseId == null &&
        percent != null &&
        (percent < low || percent > high)) {
      out.add(
        Violation('$path.intensity', 'intensity_mismatch', 'percentOfOneRm'),
      );
    }
    final flames = v.targetFlames;
    if (intensity.basis == IntensityBasis.rir &&
        flames != null &&
        Flames.isValid(flames)) {
      final rir = Flames.toRir(flames);
      // 1 flamme : « 5 et plus », compatible avec toute plage ≥ 5.
      final open = Flames.isOpenEnded(flames) && high >= rir;
      if (!open && (rir < low || rir > high)) {
        out.add(
          Violation('$path.intensity', 'intensity_mismatch', 'targetFlames'),
        );
      }
    }
  }
  final drop = technique?.backoffDropPct;
  for (final rule in v.autoregulation ?? const <AutoregulationRule>[]) {
    final pct = rule.pct;
    if (rule.kind == AutoregulationKind.backoffFromTopSet &&
        pct != null &&
        drop != null &&
        pct != drop) {
      out.add(
        Violation('$path.autoregulation', 'intensity_mismatch', 'pct ≠ drop'),
      );
    }
  }
}

// Sens de `sets` et de la plage de répétitions selon la technique : `sets`
// est le nombre de lignes de journal attendues (CONTRAT.md §12).
void _validateTechniqueInPrescription(
  ExercisePrescription v,
  SetTechnique t,
  String path,
  List<Violation> out,
) {
  void sets(int expected, String what) {
    if (v.sets != expected) {
      out.add(
        Violation(
          '$path.sets',
          'set_count',
          '${v.sets} séries, $expected attendues ($what)',
        ),
      );
    }
  }

  void reps(int low, int high, String what) {
    final repsLow = v.repsLow;
    final repsHigh = v.repsHigh;
    if (repsLow != null &&
        repsHigh != null &&
        (repsLow != low || repsHigh != high)) {
      out.add(
        Violation(
          path,
          'reps_mismatch',
          '$repsLow-$repsHigh, $low-$high attendues ($what)',
        ),
      );
    }
  }

  switch (t.kind) {
    case SetTechniqueKind.topSetBackoff:
      final backoffSets = t.backoffSets;
      if (backoffSets != null && backoffSets >= v.sets) {
        out.add(
          Violation(
            '$path.technique.backoffSets',
            'set_count',
            '$backoffSets séries allégées pour ${v.sets} séries',
          ),
        );
      }
    case SetTechniqueKind.cluster:
      final miniSets = t.miniSets;
      final miniSetReps = t.miniSetReps;
      final repsLow = v.repsLow;
      final repsHigh = v.repsHigh;
      if (miniSets != null &&
          miniSetReps != null &&
          repsLow != null &&
          repsHigh != null) {
        final total = miniSets * miniSetReps;
        if (total < repsLow || total > repsHigh) {
          out.add(
            Violation(
              path,
              'reps_mismatch',
              '$miniSets × $miniSetReps hors de $repsLow-$repsHigh',
            ),
          );
        }
      }
    case SetTechniqueKind.wave:
      final waves = t.waves;
      final waveReps = t.waveReps;
      if (waves != null && waveReps != null && waveReps.isNotEmpty) {
        sets(waves * waveReps.length, 'vagues');
        reps(_minOf(waveReps), _maxOf(waveReps), 'vagues');
      }
    case SetTechniqueKind.pyramid:
      final pyramidReps = t.pyramidReps;
      if (pyramidReps != null && pyramidReps.isNotEmpty) {
        sets(pyramidReps.length, 'pyramide');
        reps(_minOf(pyramidReps), _maxOf(pyramidReps), 'pyramide');
      }
    case SetTechniqueKind.ladder:
      final start = t.ladderStart;
      final step = t.ladderStep;
      final top = t.ladderTop;
      if (start != null &&
          step != null &&
          top != null &&
          step > 0 &&
          top >= start &&
          (top - start) % step == 0) {
        final rungs = (top - start) ~/ step + 1;
        sets(rungs * (t.ladderCount ?? 1), 'échelle');
        reps(start, top, 'échelle');
      }
    case SetTechniqueKind.emom:
      final intervals = t.intervals;
      if (intervals != null) {
        sets(intervals, 'intervalles');
      }
    case SetTechniqueKind.density:
    case SetTechniqueKind.forTime:
      sets(1, 'un bloc');
    case SetTechniqueKind.standard:
    case SetTechniqueKind.restPause:
    case SetTechniqueKind.myoReps:
    case SetTechniqueKind.dropSet:
    case SetTechniqueKind.isometricHold:
    case SetTechniqueKind.accentuatedEccentric:
    case SetTechniqueKind.contrast:
    case SetTechniqueKind.amrap:
    case SetTechniqueKind.skillPractice:
      break;
  }
}

int _minOf(List<int> values) => values.reduce((a, b) => a < b ? a : b);

int _maxOf(List<int> values) => values.reduce((a, b) => a > b ? a : b);

void _validatePass2Plan(Pass2Plan v, String path, List<Violation> out) {
  for (var i = 0; i < v.weeks.length; i++) {
    if (v.weeks[i].weekIndex != i) {
      out.add(
        Violation(
          '$path.weeks[$i].weekIndex',
          'index_mismatch',
          '${v.weeks[i].weekIndex} ≠ $i',
        ),
      );
    }
  }
}

void _validateProgramBlock(ProgramBlock v, String path, List<Violation> out) {
  if (v.pass1.blockId != v.pass2.blockId) {
    out.add(
      Violation('$path.pass2.blockId', 'block_mismatch', v.pass2.blockId),
    );
  }
  if (v.pass2.weeks.length != v.pass1.weeks) {
    out.add(
      Violation(
        '$path.pass2.weeks',
        'week_count',
        '${v.pass2.weeks.length} ≠ ${v.pass1.weeks}',
      ),
    );
  }
  // La passe 2 fait foi semaine par semaine : un emplacement peut y porter
  // un autre exercice que dans la semaine type, ou n'exister que cette
  // semaine-là. Seuls le jour et l'unicité des emplacements sont imposés.
  for (final week in v.pass2.weeks) {
    for (final day in week.days) {
      final where = 'semaine ${week.weekIndex}, jour ${day.dayIndex}';
      if (day.dayIndex >= v.pass1.days.length) {
        out.add(Violation('$path.pass2', 'unknown_day', where));
      }
      final seen = <String>{};
      for (final item in day.items) {
        if (!seen.add(item.slotId)) {
          out.add(
            Violation('$path.pass2', 'duplicate', '$where, ${item.slotId}'),
          );
        }
      }
    }
  }
}

void _validatePrediction(Prediction v, String path, List<Violation> out) {
  if (v.earliestOn > v.expectedOn || v.expectedOn > v.latestOn) {
    out.add(Violation(path, 'dates_not_ordered', ''));
  }
}

void _validateQuestState(QuestState v, String path, List<Violation> out) {
  for (var i = 0; i < v.xp.length; i++) {
    if (v.xp[i].sequence != i) {
      out.add(Violation('$path.xp[$i].sequence', 'index_mismatch', ''));
    }
    if (i > 0 && v.xp[i].date < v.xp[i - 1].date) {
      out.add(Violation('$path.xp[$i].date', 'not_chronological', ''));
    }
  }
  for (var i = 0; i < v.kredits.length; i++) {
    if (v.kredits[i].sequence != i) {
      out.add(Violation('$path.kredits[$i].sequence', 'index_mismatch', ''));
    }
    if (i > 0 && v.kredits[i].date < v.kredits[i - 1].date) {
      out.add(Violation('$path.kredits[$i].date', 'not_chronological', ''));
    }
  }
  checkDistinct(out, '$path.quests', v.quests.map((q) => q.id));
}

void _validateRestructureRequest(
  RestructureRequest v,
  String path,
  List<Violation> out,
) {
  if (v.scope == RestructureScope.session && v.dayIndex == null) {
    out.add(Violation('$path.dayIndex', 'missing_field', 'scope session'));
  }
}

// ---------------------------------------------------------------------------
// 0.4.0 (lot CQ) : profil v3, saison, compétition, figures, prescriptions
// avancées. Les champs obligatoires ou interdits selon la variante sont
// contrôlés par le code généré (`checkVariant`) ; ici, les invariants
// croisés restants.
// ---------------------------------------------------------------------------

void _orderedPair(
  List<Violation> out,
  String path,
  String name,
  num? low,
  num? high,
) {
  if ((low == null) != (high == null)) {
    out.add(Violation(path, 'range_incomplete', name));
  } else if (low != null && high != null && low > high) {
    out.add(Violation(path, 'range_inverted', '$name : $low > $high'));
  }
}

void _validateLimitation(Limitation v, String path, List<Violation> out) {
  final aggravatedBy = v.aggravatedBy;
  if (aggravatedBy != null) {
    checkDistinct(out, '$path.aggravatedBy', aggravatedBy);
  }
}

void _validateOtherSport(OtherSport v, String path, List<Violation> out) {
  final weekdays = v.weekdays;
  if (weekdays != null) {
    checkDistinct(out, '$path.weekdays', weekdays);
    for (var i = 0; i < weekdays.length; i++) {
      checkRange(out, '$path.weekdays[$i]', weekdays[i], 1, 7);
    }
  }
  final regions = v.regions;
  if (regions != null) {
    checkDistinct(out, '$path.regions', regions);
  }
}

void _validateEventStation(EventStation v, String path, List<Violation> out) {
  if (v.reps != null && v.seconds != null) {
    out.add(Violation(path, 'measure_count', 'reps et seconds'));
  }
}

void _validateSeasonEvent(SeasonEvent v, String path, List<Violation> out) {
  final lifts = v.lifts;
  if (lifts != null) {
    checkDistinct(out, '$path.lifts', lifts.map((l) => l.exerciseId));
  }
  // Une compétition de répétitions exige déjà `mode` (variante).
  if (v.kind != EventKind.repsCompetition &&
      v.stations != null &&
      v.mode == null) {
    out.add(Violation('$path.mode', 'missing_field', 'stations'));
  }
  final goalIds = v.goalIds;
  if (goalIds != null) {
    checkDistinct(out, '$path.goalIds', goalIds);
  }
}

void _validateStepCriterion(StepCriterion v, String path, List<Violation> out) {
  if (v.holdSeconds == null && v.reps == null) {
    out.add(Violation(path, 'no_measure', 'holdSeconds ou reps'));
  }
}

void _validateSkillLadder(SkillLadder v, String path, List<Violation> out) {
  checkDistinct(out, '$path.steps', v.steps.map((s) => s.exerciseId));
  if (v.steps.isNotEmpty && v.steps.last.exerciseId != v.targetExerciseId) {
    out.add(
      Violation('$path.steps', 'last_step_not_target', v.targetExerciseId),
    );
  }
}

void _validateSeasonPhase(SeasonPhase v, String path, List<Violation> out) {
  final overrides = v.overrides;
  if (overrides != null) {
    checkDistinct(out, '$path.overrides', overrides.map((o) => o.exerciseId));
  }
}

void _validatePacingSegment(PacingSegment v, String path, List<Violation> out) {
  for (var i = 0; i < v.setReps.length; i++) {
    checkRange(out, '$path.setReps[$i]', v.setReps[i], 1, 1000);
  }
}

void _validateSetPart(SetPart v, String path, List<Violation> out) {
  if (v.reps == null && v.seconds == null) {
    out.add(Violation(path, 'no_measure', 'reps ou seconds'));
  }
}

void _validateSeasonPlan(SeasonPlan v, String path, List<Violation> out) {
  checkDistinct(out, '$path.eventIds', v.eventIds);
  for (var i = 0; i < v.phases.length; i++) {
    final phase = v.phases[i];
    final eventId = phase.eventId;
    if (eventId != null && !v.eventIds.contains(eventId)) {
      out.add(Violation('$path.phases[$i].eventId', 'unknown_event', eventId));
    }
    if (phase.index != i) {
      out.add(
        Violation(
          '$path.phases[$i].index',
          'index_mismatch',
          '${phase.index} ≠ $i',
        ),
      );
    }
    if (i > 0) {
      final previous = v.phases[i - 1];
      final expected = previous.startDate.addDays(7 * previous.weeks);
      if (phase.startDate != expected) {
        out.add(
          Violation(
            '$path.phases[$i].startDate',
            'phases_not_contiguous',
            '${phase.startDate.iso} ≠ ${expected.iso}',
          ),
        );
      }
    }
  }
}

void _validateVolumeTolerance(
  VolumeTolerance v,
  String path,
  List<Violation> out,
) {
  if (v.weeklySetsLow > v.weeklySetsHigh) {
    out.add(
      Violation(
        path,
        'range_inverted',
        '${v.weeklySetsLow} > ${v.weeklySetsHigh}',
      ),
    );
  }
}

void _validateLiftAttempts(LiftAttempts v, String path, List<Violation> out) {
  for (var i = 1; i < v.attempts.length; i++) {
    if (v.attempts[i].loadKg < v.attempts[i - 1].loadKg) {
      out.add(
        Violation(
          '$path.attempts[$i].loadKg',
          'attempt_decreasing',
          '${v.attempts[i].loadKg} < ${v.attempts[i - 1].loadKg}',
        ),
      );
    }
    if (v.attempts[i].index <= v.attempts[i - 1].index) {
      out.add(Violation('$path.attempts[$i].index', 'index_mismatch', ''));
    }
  }
}

void _validateSetTechnique(SetTechnique v, String path, List<Violation> out) {
  _orderedPair(out, path, 'backoffReps', v.backoffRepsLow, v.backoffRepsHigh);
  final start = v.ladderStart;
  final top = v.ladderTop;
  final step = v.ladderStep;
  if (start != null && top != null) {
    if (start > top) {
      out.add(Violation(path, 'range_inverted', 'ladder : $start > $top'));
    } else if (step != null && step > 0 && (top - start) % step != 0) {
      out.add(Violation('$path.ladderStep', 'ladder_step', '$start à $top'));
    }
  }
  void repsList(String name, List<int>? reps) {
    if (reps == null) {
      return;
    }
    for (var i = 0; i < reps.length; i++) {
      checkRange(out, '$path.$name[$i]', reps[i], 1, 100);
    }
  }

  repsList('waveReps', v.waveReps);
  repsList('pyramidReps', v.pyramidReps);
  // « Seulement la dernière série » n'a de sens que pour une vraie technique.
  if (v.lastSetOnly != null && v.kind == SetTechniqueKind.standard) {
    out.add(Violation('$path.lastSetOnly', 'unexpected_field', 'standard'));
  }
}

void _validateIntensityTarget(
  IntensityTarget v,
  String path,
  List<Violation> out,
) {
  final value = v.value;
  final high = v.valueHigh;
  if (high != null && value > high) {
    out.add(Violation(path, 'range_inverted', 'value : $value > $high'));
  }
  // Bases en part : de 0 à 1,5 ; répétitions en réserve : de 0 à 10 ;
  // vitesse : la borne générale (15 m/s).
  final double max;
  switch (v.basis) {
    case IntensityBasis.percentOneRm:
    case IntensityBasis.percentBenchmark:
    case IntensityBasis.speedFraction:
    case IntensityBasis.bodyweightFraction:
      max = 1.5;
    case IntensityBasis.rir:
      max = 10;
    case IntensityBasis.absoluteSpeed:
      max = 15;
  }
  // La borne générale (0 à 15) est déjà contrôlée par le code généré : seule
  // la borne haute propre à la base est signalée ici.
  if (max < 15) {
    if (value.isFinite && value > max) {
      out.add(Violation('$path.value', 'above_max', '$value > $max'));
    }
    if (high != null && high.isFinite && high > max) {
      out.add(Violation('$path.valueHigh', 'above_max', '$high > $max'));
    }
  }
}

void _validateAutoregulationRule(
  AutoregulationRule v,
  String path,
  List<Violation> out,
) {
  final floor = v.rirFloor;
  final ceiling = v.rirCeiling;
  if (floor != null && ceiling != null && floor > ceiling) {
    out.add(Violation(path, 'range_inverted', 'rir : $floor > $ceiling'));
  }
  final minSets = v.minSets;
  final maxSets = v.maxSets;
  if (minSets != null && maxSets != null && minSets > maxSets) {
    out.add(Violation(path, 'range_inverted', 'sets : $minSets > $maxSets'));
  }
}
