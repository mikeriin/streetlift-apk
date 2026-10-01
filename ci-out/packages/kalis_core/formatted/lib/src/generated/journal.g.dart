// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Douleur signalée.
final class PainReport {
  const PainReport({
    required this.zone,
    required this.side,
    this.joint,
    required this.intensity,
    required this.phase,
    this.exerciseId,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PainReport.fromJson(Map<String, Object?> json) {
    return PainReport(
      zone: jsonEnum(json, 'zone', BodyZone.fromCode),
      side: jsonEnum(json, 'side', BodySide.fromCode),
      joint: jsonEnumOrNull(json, 'joint', Joint.fromCode),
      intensity: jsonInt(json, 'intensity'),
      phase: jsonEnum(json, 'phase', PainPhase.fromCode),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
    );
  }

  /// Zone.
  final BodyZone zone;

  /// Côté.
  final BodySide side;

  /// Articulation, si la zone en désigne une.
  final Joint? joint;

  /// Intensité de 0 à 10.
  final int intensity;

  /// Avant, pendant ou après la séance.
  final PainPhase phase;

  /// Exercice pendant lequel elle est apparue.
  final String? exerciseId;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'zone': zone.code,
      'side': side.code,
      if (joint case final v?) 'joint': v.code,
      'intensity': intensity,
      'phase': phase.code,
      if (exerciseId case final v?) 'exerciseId': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PainReport copyWith({
    BodyZone? zone,
    BodySide? side,
    Object? joint = unset,
    int? intensity,
    PainPhase? phase,
    Object? exerciseId = unset,
  }) {
    return PainReport(
      zone: zone ?? this.zone,
      side: side ?? this.side,
      joint: identical(joint, unset) ? this.joint : joint as Joint?,
      intensity: intensity ?? this.intensity,
      phase: phase ?? this.phase,
      exerciseId: identical(exerciseId, unset)
          ? this.exerciseId
          : exerciseId as String?,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkRange(out, '$path.intensity', intensity, 0, 10);
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) {
      out.add(v);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PainReport &&
            zone == other.zone &&
            side == other.side &&
            joint == other.joint &&
            intensity == other.intensity &&
            phase == other.phase &&
            exerciseId == other.exerciseId;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    zone,
    side,
    joint,
    intensity,
    phase,
    exerciseId,
  ]);

  @override
  String toString() => 'PainReport(${toJson()})';
}

/// Bilan santé de début de séance (D5.8). Chaque question est facultative :
/// une réponse absente reste absente (aucune valeur par défaut). Échelles de
/// 1 à 5 : 5 = état le plus favorable.
final class HealthCheck {
  const HealthCheck({
    this.overall,
    this.sleepQuality,
    this.sleepHours,
    this.energy,
    this.mood,
    this.soreness,
    this.stress,
    this.motivation,
    this.nutrition,
    this.hydration,
    this.minutesAvailable,
    required this.pains,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory HealthCheck.fromJson(Map<String, Object?> json) {
    return HealthCheck(
      overall: jsonIntOrNull(json, 'overall'),
      sleepQuality: jsonIntOrNull(json, 'sleepQuality'),
      sleepHours: jsonDoubleOrNull(json, 'sleepHours'),
      energy: jsonIntOrNull(json, 'energy'),
      mood: jsonIntOrNull(json, 'mood'),
      soreness: jsonIntOrNull(json, 'soreness'),
      stress: jsonIntOrNull(json, 'stress'),
      motivation: jsonIntOrNull(json, 'motivation'),
      nutrition: jsonIntOrNull(json, 'nutrition'),
      hydration: jsonIntOrNull(json, 'hydration'),
      minutesAvailable: jsonIntOrNull(json, 'minutesAvailable'),
      pains: jsonList(
        json,
        'pains',
        (v) => PainReport.fromJson(jsonAsObject(v, 'pains')),
      ),
    );
  }

  /// « Comment tu te sens ? »
  final int? overall;

  /// Qualité du sommeil.
  final int? sleepQuality;

  /// Heures de sommeil.
  final double? sleepHours;

  /// Énergie.
  final int? energy;

  /// Humeur.
  final int? mood;

  /// Courbatures (5 = aucune).
  final int? soreness;

  /// Stress (5 = aucun).
  final int? stress;

  /// Motivation.
  final int? motivation;

  /// Alimentation.
  final int? nutrition;

  /// Hydratation.
  final int? hydration;

  /// Temps disponible aujourd'hui, en minutes.
  final int? minutesAvailable;

  /// Douleurs localisées.
  final List<PainReport> pains;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (overall case final v?) 'overall': v,
      if (sleepQuality case final v?) 'sleepQuality': v,
      if (sleepHours case final v?) 'sleepHours': v,
      if (energy case final v?) 'energy': v,
      if (mood case final v?) 'mood': v,
      if (soreness case final v?) 'soreness': v,
      if (stress case final v?) 'stress': v,
      if (motivation case final v?) 'motivation': v,
      if (nutrition case final v?) 'nutrition': v,
      if (hydration case final v?) 'hydration': v,
      if (minutesAvailable case final v?) 'minutesAvailable': v,
      'pains': [for (final e in pains) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  HealthCheck copyWith({
    Object? overall = unset,
    Object? sleepQuality = unset,
    Object? sleepHours = unset,
    Object? energy = unset,
    Object? mood = unset,
    Object? soreness = unset,
    Object? stress = unset,
    Object? motivation = unset,
    Object? nutrition = unset,
    Object? hydration = unset,
    Object? minutesAvailable = unset,
    List<PainReport>? pains,
  }) {
    return HealthCheck(
      overall: identical(overall, unset) ? this.overall : overall as int?,
      sleepQuality: identical(sleepQuality, unset)
          ? this.sleepQuality
          : sleepQuality as int?,
      sleepHours: identical(sleepHours, unset)
          ? this.sleepHours
          : sleepHours as double?,
      energy: identical(energy, unset) ? this.energy : energy as int?,
      mood: identical(mood, unset) ? this.mood : mood as int?,
      soreness: identical(soreness, unset) ? this.soreness : soreness as int?,
      stress: identical(stress, unset) ? this.stress : stress as int?,
      motivation: identical(motivation, unset)
          ? this.motivation
          : motivation as int?,
      nutrition: identical(nutrition, unset)
          ? this.nutrition
          : nutrition as int?,
      hydration: identical(hydration, unset)
          ? this.hydration
          : hydration as int?,
      minutesAvailable: identical(minutesAvailable, unset)
          ? this.minutesAvailable
          : minutesAvailable as int?,
      pains: pains ?? this.pains,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    if (overall case final v?) {
      checkRange(out, '$path.overall', v, 1, 5);
    }
    if (sleepQuality case final v?) {
      checkRange(out, '$path.sleepQuality', v, 1, 5);
    }
    if (sleepHours case final v?) {
      checkRange(out, '$path.sleepHours', v, 0, 24);
    }
    if (energy case final v?) {
      checkRange(out, '$path.energy', v, 1, 5);
    }
    if (mood case final v?) {
      checkRange(out, '$path.mood', v, 1, 5);
    }
    if (soreness case final v?) {
      checkRange(out, '$path.soreness', v, 1, 5);
    }
    if (stress case final v?) {
      checkRange(out, '$path.stress', v, 1, 5);
    }
    if (motivation case final v?) {
      checkRange(out, '$path.motivation', v, 1, 5);
    }
    if (nutrition case final v?) {
      checkRange(out, '$path.nutrition', v, 1, 5);
    }
    if (hydration case final v?) {
      checkRange(out, '$path.hydration', v, 1, 5);
    }
    if (minutesAvailable case final v?) {
      checkRange(out, '$path.minutesAvailable', v, 0, 600);
    }
    for (var i = 0; i < pains.length; i++) {
      pains[i].collectViolations('$path.pains[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in pains) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HealthCheck &&
            overall == other.overall &&
            sleepQuality == other.sleepQuality &&
            sleepHours == other.sleepHours &&
            energy == other.energy &&
            mood == other.mood &&
            soreness == other.soreness &&
            stress == other.stress &&
            motivation == other.motivation &&
            nutrition == other.nutrition &&
            hydration == other.hydration &&
            minutesAvailable == other.minutesAvailable &&
            jsonListEquals(pains, other.pains);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    overall,
    sleepQuality,
    sleepHours,
    energy,
    mood,
    soreness,
    stress,
    motivation,
    nutrition,
    hydration,
    minutesAvailable,
    Object.hashAll(pains),
  ]);

  @override
  String toString() => 'HealthCheck(${toJson()})';
}

/// Cible prescrite d'une série, telle qu'elle était affichée.
///
/// Invariant : `repsLow` ≤ `repsHigh` quand les deux sont renseignés.
final class SetTarget {
  const SetTarget({
    this.repsLow,
    this.repsHigh,
    this.seconds,
    this.distanceMeters,
    this.loadKg,
    this.flames,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SetTarget.fromJson(Map<String, Object?> json) {
    return SetTarget(
      repsLow: jsonIntOrNull(json, 'repsLow'),
      repsHigh: jsonIntOrNull(json, 'repsHigh'),
      seconds: jsonIntOrNull(json, 'seconds'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      loadKg: jsonDoubleOrNull(json, 'loadKg'),
      flames: jsonIntOrNull(json, 'flames'),
    );
  }

  /// Bas de la plage de répétitions.
  final int? repsLow;

  /// Haut de la plage de répétitions.
  final int? repsHigh;

  /// Durée visée, en secondes.
  final int? seconds;

  /// Distance visée, en mètres.
  final double? distanceMeters;

  /// Charge externe prescrite, en kg.
  final double? loadKg;

  /// Flammes visées.
  final int? flames;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (repsLow case final v?) 'repsLow': v,
      if (repsHigh case final v?) 'repsHigh': v,
      if (seconds case final v?) 'seconds': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (loadKg case final v?) 'loadKg': v,
      if (flames case final v?) 'flames': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SetTarget copyWith({
    Object? repsLow = unset,
    Object? repsHigh = unset,
    Object? seconds = unset,
    Object? distanceMeters = unset,
    Object? loadKg = unset,
    Object? flames = unset,
  }) {
    return SetTarget(
      repsLow: identical(repsLow, unset) ? this.repsLow : repsLow as int?,
      repsHigh: identical(repsHigh, unset) ? this.repsHigh : repsHigh as int?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      loadKg: identical(loadKg, unset) ? this.loadKg : loadKg as double?,
      flames: identical(flames, unset) ? this.flames : flames as int?,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    if (repsLow case final v?) {
      checkRange(out, '$path.repsLow', v, 0, 1000);
    }
    if (repsHigh case final v?) {
      checkRange(out, '$path.repsHigh', v, 0, 1000);
    }
    if (seconds case final v?) {
      checkRange(out, '$path.seconds', v, 0, 86400);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    if (loadKg case final v?) {
      checkRange(out, '$path.loadKg', v, -300, 1000);
    }
    if (flames case final v?) {
      checkRange(out, '$path.flames', v, 1, 10);
    }
    _validateSetTarget(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SetTarget &&
            repsLow == other.repsLow &&
            repsHigh == other.repsHigh &&
            seconds == other.seconds &&
            distanceMeters == other.distanceMeters &&
            loadKg == other.loadKg &&
            flames == other.flames;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    repsLow,
    repsHigh,
    seconds,
    distanceMeters,
    loadKg,
    flames,
  ]);

  @override
  String toString() => 'SetTarget(${toJson()})';
}

/// Série réalisée.
///
/// Invariant : Au moins une mesure parmi `reps`, `seconds`, `distanceMeters`,
/// `calories`.
final class SetRecord {
  const SetRecord({
    required this.exerciseId,
    required this.exerciseOrder,
    required this.setIndex,
    required this.kind,
    this.externalLoadKg,
    this.reps,
    this.seconds,
    this.distanceMeters,
    this.calories,
    this.flames,
    required this.success,
    required this.excluded,
    this.side,
    this.target,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SetRecord.fromJson(Map<String, Object?> json) {
    return SetRecord(
      exerciseId: jsonString(json, 'exerciseId'),
      exerciseOrder: jsonInt(json, 'exerciseOrder'),
      setIndex: jsonInt(json, 'setIndex'),
      kind: jsonEnum(json, 'kind', SetKind.fromCode),
      externalLoadKg: jsonDoubleOrNull(json, 'externalLoadKg'),
      reps: jsonIntOrNull(json, 'reps'),
      seconds: jsonIntOrNull(json, 'seconds'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      calories: jsonDoubleOrNull(json, 'calories'),
      flames: jsonIntOrNull(json, 'flames'),
      success: jsonBool(json, 'success'),
      excluded: jsonBool(json, 'excluded'),
      side: jsonEnumOrNull(json, 'side', BodySide.fromCode),
      target: jsonObjOrNull(json, 'target', SetTarget.fromJson),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Rang de l'exercice dans la séance (0 = premier).
  final int exerciseOrder;

  /// Rang de la série dans l'exercice (0 = première).
  final int setIndex;

  /// Rôle de la série.
  final SetKind kind;

  /// Charge externe en kg (lest, barre, par haltère… ; négative = assistance ;
  /// absente = aucune).
  final double? externalLoadKg;

  /// Répétitions réalisées.
  final int? reps;

  /// Durée réalisée, en secondes.
  final int? seconds;

  /// Distance réalisée, en mètres.
  final double? distanceMeters;

  /// Calories réalisées.
  final double? calories;

  /// Note de difficulté de 1 à 10 flammes ; absente = « pas de note ».
  final int? flames;

  /// La série a atteint sa cible.
  final bool success;

  /// Série écartée (incident), gardée au journal, ignorée des moteurs.
  final bool excluded;

  /// Côté travaillé (exercice unilatéral).
  final BodySide? side;

  /// Cible prescrite.
  final SetTarget? target;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'exerciseOrder': exerciseOrder,
      'setIndex': setIndex,
      'kind': kind.code,
      if (externalLoadKg case final v?) 'externalLoadKg': v,
      if (reps case final v?) 'reps': v,
      if (seconds case final v?) 'seconds': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (calories case final v?) 'calories': v,
      if (flames case final v?) 'flames': v,
      'success': success,
      'excluded': excluded,
      if (side case final v?) 'side': v.code,
      if (target case final v?) 'target': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SetRecord copyWith({
    String? exerciseId,
    int? exerciseOrder,
    int? setIndex,
    SetKind? kind,
    Object? externalLoadKg = unset,
    Object? reps = unset,
    Object? seconds = unset,
    Object? distanceMeters = unset,
    Object? calories = unset,
    Object? flames = unset,
    bool? success,
    bool? excluded,
    Object? side = unset,
    Object? target = unset,
  }) {
    return SetRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseOrder: exerciseOrder ?? this.exerciseOrder,
      setIndex: setIndex ?? this.setIndex,
      kind: kind ?? this.kind,
      externalLoadKg: identical(externalLoadKg, unset)
          ? this.externalLoadKg
          : externalLoadKg as double?,
      reps: identical(reps, unset) ? this.reps : reps as int?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      calories: identical(calories, unset)
          ? this.calories
          : calories as double?,
      flames: identical(flames, unset) ? this.flames : flames as int?,
      success: success ?? this.success,
      excluded: excluded ?? this.excluded,
      side: identical(side, unset) ? this.side : side as BodySide?,
      target: identical(target, unset) ? this.target : target as SetTarget?,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkLength(out, '$path.exerciseId', exerciseId.length, 1, null);
    checkRange(out, '$path.exerciseOrder', exerciseOrder, 0, null);
    checkRange(out, '$path.setIndex', setIndex, 0, null);
    if (externalLoadKg case final v?) {
      checkRange(out, '$path.externalLoadKg', v, -300, 1000);
    }
    if (reps case final v?) {
      checkRange(out, '$path.reps', v, 0, 1000);
    }
    if (seconds case final v?) {
      checkRange(out, '$path.seconds', v, 0, 86400);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    if (calories case final v?) {
      checkRange(out, '$path.calories', v, 0, null);
    }
    if (flames case final v?) {
      checkRange(out, '$path.flames', v, 1, 10);
    }
    if (target case final v?) {
      v.collectViolations('$path.target', out);
    }
    _validateSetRecord(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    target?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SetRecord &&
            exerciseId == other.exerciseId &&
            exerciseOrder == other.exerciseOrder &&
            setIndex == other.setIndex &&
            kind == other.kind &&
            externalLoadKg == other.externalLoadKg &&
            reps == other.reps &&
            seconds == other.seconds &&
            distanceMeters == other.distanceMeters &&
            calories == other.calories &&
            flames == other.flames &&
            success == other.success &&
            excluded == other.excluded &&
            side == other.side &&
            target == other.target;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    exerciseOrder,
    setIndex,
    kind,
    externalLoadKg,
    reps,
    seconds,
    distanceMeters,
    calories,
    flames,
    success,
    excluded,
    side,
    target,
  ]);

  @override
  String toString() => 'SetRecord(${toJson()})';
}

/// Place d'une séance dans le programme.
final class ProgramRef {
  const ProgramRef({
    required this.blockId,
    required this.weekIndex,
    required this.dayIndex,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ProgramRef.fromJson(Map<String, Object?> json) {
    return ProgramRef(
      blockId: jsonString(json, 'blockId'),
      weekIndex: jsonInt(json, 'weekIndex'),
      dayIndex: jsonInt(json, 'dayIndex'),
    );
  }

  /// Identifiant du bloc.
  final String blockId;

  /// Semaine dans le bloc (0 = première).
  final int weekIndex;

  /// Jour d'entraînement dans la semaine (0 = premier).
  final int dayIndex;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'blockId': blockId,
      'weekIndex': weekIndex,
      'dayIndex': dayIndex,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ProgramRef copyWith({String? blockId, int? weekIndex, int? dayIndex}) {
    return ProgramRef(
      blockId: blockId ?? this.blockId,
      weekIndex: weekIndex ?? this.weekIndex,
      dayIndex: dayIndex ?? this.dayIndex,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkLength(out, '$path.blockId', blockId.length, 1, null);
    checkRange(out, '$path.weekIndex', weekIndex, 0, null);
    checkRange(out, '$path.dayIndex', dayIndex, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProgramRef &&
            blockId == other.blockId &&
            weekIndex == other.weekIndex &&
            dayIndex == other.dayIndex;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[blockId, weekIndex, dayIndex]);

  @override
  String toString() => 'ProgramRef(${toJson()})';
}

/// Séance du journal. Dates en jours civils.
final class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.date,
    required this.origin,
    this.programRef,
    required this.resume,
    required this.completed,
    this.durationMinutes,
    this.bodyWeightKg,
    this.healthCheck,
    required this.sets,
    required this.pains,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SessionRecord.fromJson(Map<String, Object?> json) {
    return SessionRecord(
      id: jsonString(json, 'id'),
      date: jsonDate(json, 'date'),
      origin: jsonEnum(json, 'origin', SessionOrigin.fromCode),
      programRef: jsonObjOrNull(json, 'programRef', ProgramRef.fromJson),
      resume: jsonBool(json, 'resume'),
      completed: jsonBool(json, 'completed'),
      durationMinutes: jsonIntOrNull(json, 'durationMinutes'),
      bodyWeightKg: jsonDoubleOrNull(json, 'bodyWeightKg'),
      healthCheck: jsonObjOrNull(json, 'healthCheck', HealthCheck.fromJson),
      sets: jsonList(
        json,
        'sets',
        (v) => SetRecord.fromJson(jsonAsObject(v, 'sets')),
      ),
      pains: jsonList(
        json,
        'pains',
        (v) => PainReport.fromJson(jsonAsObject(v, 'pains')),
      ),
    );
  }

  /// Identifiant unique de la séance.
  final String id;

  /// Jour civil de la séance.
  final CivilDate date;

  /// Origine.
  final SessionOrigin origin;

  /// Place dans le programme.
  final ProgramRef? programRef;

  /// Marqueur « reprise » (D4.9) : séance neutre, ignorée des moteurs (ni XP,
  /// ni statistiques, ni série, ni records).
  final bool resume;

  /// Séance terminée.
  final bool completed;

  /// Durée de la séance, en minutes.
  final int? durationMinutes;

  /// Poids de corps du jour, en kg.
  final double? bodyWeightKg;

  /// Bilan santé de début de séance.
  final HealthCheck? healthCheck;

  /// Séries, dans l'ordre de réalisation.
  final List<SetRecord> sets;

  /// Douleurs signalées pendant ou après la séance.
  final List<PainReport> pains;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'date': date.iso,
      'origin': origin.code,
      if (programRef case final v?) 'programRef': v.toJson(),
      'resume': resume,
      'completed': completed,
      if (durationMinutes case final v?) 'durationMinutes': v,
      if (bodyWeightKg case final v?) 'bodyWeightKg': v,
      if (healthCheck case final v?) 'healthCheck': v.toJson(),
      'sets': [for (final e in sets) e.toJson()],
      'pains': [for (final e in pains) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SessionRecord copyWith({
    String? id,
    CivilDate? date,
    SessionOrigin? origin,
    Object? programRef = unset,
    bool? resume,
    bool? completed,
    Object? durationMinutes = unset,
    Object? bodyWeightKg = unset,
    Object? healthCheck = unset,
    List<SetRecord>? sets,
    List<PainReport>? pains,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      origin: origin ?? this.origin,
      programRef: identical(programRef, unset)
          ? this.programRef
          : programRef as ProgramRef?,
      resume: resume ?? this.resume,
      completed: completed ?? this.completed,
      durationMinutes: identical(durationMinutes, unset)
          ? this.durationMinutes
          : durationMinutes as int?,
      bodyWeightKg: identical(bodyWeightKg, unset)
          ? this.bodyWeightKg
          : bodyWeightKg as double?,
      healthCheck: identical(healthCheck, unset)
          ? this.healthCheck
          : healthCheck as HealthCheck?,
      sets: sets ?? this.sets,
      pains: pains ?? this.pains,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkLength(out, '$path.id', id.length, 1, null);
    if (programRef case final v?) {
      v.collectViolations('$path.programRef', out);
    }
    if (durationMinutes case final v?) {
      checkRange(out, '$path.durationMinutes', v, 0, 600);
    }
    if (bodyWeightKg case final v?) {
      checkRange(out, '$path.bodyWeightKg', v, 25, 300);
    }
    if (healthCheck case final v?) {
      v.collectViolations('$path.healthCheck', out);
    }
    for (var i = 0; i < sets.length; i++) {
      sets[i].collectViolations('$path.sets[$i]', out);
    }
    for (var i = 0; i < pains.length; i++) {
      pains[i].collectViolations('$path.pains[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    programRef?.collectExerciseIds(out);
    healthCheck?.collectExerciseIds(out);
    for (final e in sets) {
      e.collectExerciseIds(out);
    }
    for (final e in pains) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SessionRecord &&
            id == other.id &&
            date == other.date &&
            origin == other.origin &&
            programRef == other.programRef &&
            resume == other.resume &&
            completed == other.completed &&
            durationMinutes == other.durationMinutes &&
            bodyWeightKg == other.bodyWeightKg &&
            healthCheck == other.healthCheck &&
            jsonListEquals(sets, other.sets) &&
            jsonListEquals(pains, other.pains);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    date,
    origin,
    programRef,
    resume,
    completed,
    durationMinutes,
    bodyWeightKg,
    healthCheck,
    Object.hashAll(sets),
    Object.hashAll(pains),
  ]);

  @override
  String toString() => 'SessionRecord(${toJson()})';
}

/// Journal de séances.
///
/// Invariant : Identifiants de séance uniques ; dates croissantes (au sens
/// large).
final class TrainingLog {
  const TrainingLog({
    this.schemaVersion = currentSchemaVersion,
    required this.sessions,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory TrainingLog.fromJson(Map<String, Object?> json) {
    return TrainingLog(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      sessions: jsonList(
        json,
        'sessions',
        (v) => SessionRecord.fromJson(jsonAsObject(v, 'sessions')),
      ),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Séances, par date croissante.
  final List<SessionRecord> sessions;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'sessions': [for (final e in sessions) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  TrainingLog copyWith({int? schemaVersion, List<SessionRecord>? sessions}) {
    return TrainingLog(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sessions: sessions ?? this.sessions,
    );
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkRange(
      out,
      '$path.schemaVersion',
      schemaVersion,
      1,
      currentSchemaVersion,
    );
    for (var i = 0; i < sessions.length; i++) {
      sessions[i].collectViolations('$path.sessions[$i]', out);
    }
    _validateTrainingLog(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in sessions) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TrainingLog &&
            schemaVersion == other.schemaVersion &&
            jsonListEquals(sessions, other.sessions);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[schemaVersion, Object.hashAll(sessions)]);

  @override
  String toString() => 'TrainingLog(${toJson()})';
}
