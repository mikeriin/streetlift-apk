// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Discipline secondaire et son dosage.
final class DisciplineShare {
  const DisciplineShare({
    required this.discipline,
    required this.pct,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DisciplineShare.fromJson(Map<String, Object?> json) {
    return DisciplineShare(
      discipline: jsonEnum(json, 'discipline', TrainingDiscipline.fromCode),
      pct: jsonInt(json, 'pct'),
    );
  }

  /// Discipline.
  final TrainingDiscipline discipline;

  /// Part en pour cent.
  final int pct;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'discipline': discipline.code,
      'pct': pct,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DisciplineShare copyWith({
    TrainingDiscipline? discipline,
    int? pct,
  }) {
    return DisciplineShare(
      discipline: discipline ?? this.discipline,
      pct: pct ?? this.pct,
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
    checkRange(out, '$path.pct', pct, 1, 99);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is DisciplineShare && discipline == other.discipline && pct == other.pct;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[discipline, pct]);

  @override
  String toString() => 'DisciplineShare(${toJson()})';
}

/// Discipline principale et 0 à 2 secondaires dosées (D3.2).
///
/// Invariant : Somme des parts = 100 ; disciplines distinctes ; la principale
/// a la plus grande part.
final class DisciplineMix {
  const DisciplineMix({
    required this.primary,
    required this.primaryPct,
    required this.secondaries,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DisciplineMix.fromJson(Map<String, Object?> json) {
    return DisciplineMix(
      primary: jsonEnum(json, 'primary', TrainingDiscipline.fromCode),
      primaryPct: jsonInt(json, 'primaryPct'),
      secondaries: jsonList(json, 'secondaries', (v) => DisciplineShare.fromJson(jsonAsObject(v, 'secondaries'))),
    );
  }

  /// Discipline principale.
  final TrainingDiscipline primary;

  /// Part de la principale, en pour cent.
  final int primaryPct;

  /// Disciplines secondaires.
  final List<DisciplineShare> secondaries;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primary': primary.code,
      'primaryPct': primaryPct,
      'secondaries': [for (final e in secondaries) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DisciplineMix copyWith({
    TrainingDiscipline? primary,
    int? primaryPct,
    List<DisciplineShare>? secondaries,
  }) {
    return DisciplineMix(
      primary: primary ?? this.primary,
      primaryPct: primaryPct ?? this.primaryPct,
      secondaries: secondaries ?? this.secondaries,
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
    checkRange(out, '$path.primaryPct', primaryPct, 1, 100);
    checkLength(out, '$path.secondaries', secondaries.length, null, 2);
    for (var i = 0; i < secondaries.length; i++) { secondaries[i].collectViolations('$path.secondaries[$i]', out); }
    _validateDisciplineMix(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in secondaries) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is DisciplineMix && primary == other.primary && primaryPct == other.primaryPct && jsonListEquals(secondaries, other.secondaries);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[primary, primaryPct, Object.hashAll(secondaries)]);

  @override
  String toString() => 'DisciplineMix(${toJson()})';
}

/// Mode street : une principale parmi trois, les deux autres dosées (D3.3).
///
/// Invariant : Somme = 100 ; la principale a la plus grande part, strictement
/// positive.
final class StreetMode {
  const StreetMode({
    required this.primary,
    required this.streetliftingPct,
    required this.setsRepsPct,
    required this.calisthenicsPct,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory StreetMode.fromJson(Map<String, Object?> json) {
    return StreetMode(
      primary: jsonEnum(json, 'primary', StreetStyle.fromCode),
      streetliftingPct: jsonInt(json, 'streetliftingPct'),
      setsRepsPct: jsonInt(json, 'setsRepsPct'),
      calisthenicsPct: jsonInt(json, 'calisthenicsPct'),
    );
  }

  /// Composante principale.
  final StreetStyle primary;

  /// Part du streetlifting.
  final int streetliftingPct;

  /// Part du sets & reps.
  final int setsRepsPct;

  /// Part de la calisthénie.
  final int calisthenicsPct;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primary': primary.code,
      'streetliftingPct': streetliftingPct,
      'setsRepsPct': setsRepsPct,
      'calisthenicsPct': calisthenicsPct,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  StreetMode copyWith({
    StreetStyle? primary,
    int? streetliftingPct,
    int? setsRepsPct,
    int? calisthenicsPct,
  }) {
    return StreetMode(
      primary: primary ?? this.primary,
      streetliftingPct: streetliftingPct ?? this.streetliftingPct,
      setsRepsPct: setsRepsPct ?? this.setsRepsPct,
      calisthenicsPct: calisthenicsPct ?? this.calisthenicsPct,
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
    checkRange(out, '$path.streetliftingPct', streetliftingPct, 0, 100);
    checkRange(out, '$path.setsRepsPct', setsRepsPct, 0, 100);
    checkRange(out, '$path.calisthenicsPct', calisthenicsPct, 0, 100);
    _validateStreetMode(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is StreetMode && primary == other.primary && streetliftingPct == other.streetliftingPct && setsRepsPct == other.setsRepsPct && calisthenicsPct == other.calisthenicsPct;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[primary, streetliftingPct, setsRepsPct, calisthenicsPct]);

  @override
  String toString() => 'StreetMode(${toJson()})';
}

/// Niveau déclaré sur un mouvement : fourchette ou « je ne sais pas » (D3.5).
///
/// Invariant : `known` ⇒ `low` ≤ `high` renseignés ; sinon `low` et `high`
/// absents ; `distanceMeters` seulement pour `time_seconds`.
final class MovementLevel {
  const MovementLevel({
    required this.exerciseId,
    required this.measure,
    required this.known,
    this.low,
    this.high,
    this.distanceMeters,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory MovementLevel.fromJson(Map<String, Object?> json) {
    return MovementLevel(
      exerciseId: jsonString(json, 'exerciseId'),
      measure: jsonEnum(json, 'measure', LevelMeasure.fromCode),
      known: jsonBool(json, 'known'),
      low: jsonDoubleOrNull(json, 'low'),
      high: jsonDoubleOrNull(json, 'high'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
    );
  }

  /// Exercice de référence.
  final String exerciseId;

  /// Grandeur déclarée.
  final LevelMeasure measure;

  /// false = « je ne sais pas » (aucune valeur).
  final bool known;

  /// Borne basse de la fourchette.
  final double? low;

  /// Borne haute de la fourchette.
  final double? high;

  /// Distance, pour `time_seconds`.
  final double? distanceMeters;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'measure': measure.code,
      'known': known,
      if (low case final v?) 'low': v,
      if (high case final v?) 'high': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  MovementLevel copyWith({
    String? exerciseId,
    LevelMeasure? measure,
    bool? known,
    Object? low = unset,
    Object? high = unset,
    Object? distanceMeters = unset,
  }) {
    return MovementLevel(
      exerciseId: exerciseId ?? this.exerciseId,
      measure: measure ?? this.measure,
      known: known ?? this.known,
      low: identical(low, unset) ? this.low : low as double?,
      high: identical(high, unset) ? this.high : high as double?,
      distanceMeters: identical(distanceMeters, unset) ? this.distanceMeters : distanceMeters as double?,
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
    if (low case final v?) { checkRange(out, '$path.low', v, 0, null); }
    if (high case final v?) { checkRange(out, '$path.high', v, 0, null); }
    if (distanceMeters case final v?) { checkRange(out, '$path.distanceMeters', v, 0, null); }
    _validateMovementLevel(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is MovementLevel && exerciseId == other.exerciseId && measure == other.measure && known == other.known && low == other.low && high == other.high && distanceMeters == other.distanceMeters;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, measure, known, low, high, distanceMeters]);

  @override
  String toString() => 'MovementLevel(${toJson()})';
}

/// Objectif : performance chiffrée datée, ou habitude (D3.8).
///
/// Invariant : Performance : `exerciseId`, `metric`, `targetDate` renseignés,
/// champs d'habitude absents. Habitude : `sessionsPerWeek` et `weeks`
/// renseignés, champs de performance absents.
final class Goal {
  const Goal({
    required this.id,
    required this.kind,
    required this.origin,
    required this.createdOn,
    this.exerciseId,
    this.metric,
    this.targetValue,
    this.distanceMeters,
    this.targetDate,
    this.sessionsPerWeek,
    this.weeks,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Goal.fromJson(Map<String, Object?> json) {
    return Goal(
      id: jsonString(json, 'id'),
      kind: jsonEnum(json, 'kind', GoalKind.fromCode),
      origin: jsonEnum(json, 'origin', GoalOrigin.fromCode),
      createdOn: jsonDate(json, 'createdOn'),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      metric: jsonEnumOrNull(json, 'metric', GoalMetric.fromCode),
      targetValue: jsonDoubleOrNull(json, 'targetValue'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      targetDate: jsonDateOrNull(json, 'targetDate'),
      sessionsPerWeek: jsonIntOrNull(json, 'sessionsPerWeek'),
      weeks: jsonIntOrNull(json, 'weeks'),
    );
  }

  /// Identifiant stable de l'objectif.
  final String id;

  /// Performance ou habitude.
  final GoalKind kind;

  /// Saisi par l'utilisateur ou suggéré par Koach.
  final GoalOrigin origin;

  /// Jour de création.
  final CivilDate createdOn;

  /// Exercice visé (performance).
  final String? exerciseId;

  /// Grandeur visée (performance).
  final GoalMetric? metric;

  /// Valeur cible, dans l'unité de `metric` (absente pour `skill_unlocked`).
  final double? targetValue;

  /// Distance de référence pour `time_seconds`.
  final double? distanceMeters;

  /// Échéance (performance).
  final CivilDate? targetDate;

  /// Séances par semaine (habitude).
  final int? sessionsPerWeek;

  /// Durée en semaines (habitude).
  final int? weeks;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.code,
      'origin': origin.code,
      'createdOn': createdOn.iso,
      if (exerciseId case final v?) 'exerciseId': v,
      if (metric case final v?) 'metric': v.code,
      if (targetValue case final v?) 'targetValue': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (targetDate case final v?) 'targetDate': v.iso,
      if (sessionsPerWeek case final v?) 'sessionsPerWeek': v,
      if (weeks case final v?) 'weeks': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Goal copyWith({
    String? id,
    GoalKind? kind,
    GoalOrigin? origin,
    CivilDate? createdOn,
    Object? exerciseId = unset,
    Object? metric = unset,
    Object? targetValue = unset,
    Object? distanceMeters = unset,
    Object? targetDate = unset,
    Object? sessionsPerWeek = unset,
    Object? weeks = unset,
  }) {
    return Goal(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      origin: origin ?? this.origin,
      createdOn: createdOn ?? this.createdOn,
      exerciseId: identical(exerciseId, unset) ? this.exerciseId : exerciseId as String?,
      metric: identical(metric, unset) ? this.metric : metric as GoalMetric?,
      targetValue: identical(targetValue, unset) ? this.targetValue : targetValue as double?,
      distanceMeters: identical(distanceMeters, unset) ? this.distanceMeters : distanceMeters as double?,
      targetDate: identical(targetDate, unset) ? this.targetDate : targetDate as CivilDate?,
      sessionsPerWeek: identical(sessionsPerWeek, unset) ? this.sessionsPerWeek : sessionsPerWeek as int?,
      weeks: identical(weeks, unset) ? this.weeks : weeks as int?,
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
    if (exerciseId case final v?) { checkLength(out, '$path.exerciseId', v.length, 1, null); }
    if (targetValue case final v?) { checkRange(out, '$path.targetValue', v, 0, null); }
    if (distanceMeters case final v?) { checkRange(out, '$path.distanceMeters', v, 0, null); }
    if (sessionsPerWeek case final v?) { checkRange(out, '$path.sessionsPerWeek', v, 1, 14); }
    if (weeks case final v?) { checkRange(out, '$path.weeks', v, 1, 104); }
    _validateGoal(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) { out.add(v); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Goal && id == other.id && kind == other.kind && origin == other.origin && createdOn == other.createdOn && exerciseId == other.exerciseId && metric == other.metric && targetValue == other.targetValue && distanceMeters == other.distanceMeters && targetDate == other.targetDate && sessionsPerWeek == other.sessionsPerWeek && weeks == other.weeks;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[id, kind, origin, createdOn, exerciseId, metric, targetValue, distanceMeters, targetDate, sessionsPerWeek, weeks]);

  @override
  String toString() => 'Goal(${toJson()})';
}

/// Disponibilité d'un jour précis (D3.6).
final class DaySlot {
  const DaySlot({
    required this.weekday,
    required this.minutes,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DaySlot.fromJson(Map<String, Object?> json) {
    return DaySlot(
      weekday: jsonInt(json, 'weekday'),
      minutes: jsonInt(json, 'minutes'),
    );
  }

  /// Jour ISO : 1 = lundi … 7 = dimanche.
  final int weekday;

  /// Durée disponible, en minutes.
  final int minutes;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'weekday': weekday,
      'minutes': minutes,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DaySlot copyWith({
    int? weekday,
    int? minutes,
  }) {
    return DaySlot(
      weekday: weekday ?? this.weekday,
      minutes: minutes ?? this.minutes,
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
    checkRange(out, '$path.weekday', weekday, 1, 7);
    checkRange(out, '$path.minutes', minutes, 10, 300);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is DaySlot && weekday == other.weekday && minutes == other.minutes;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[weekday, minutes]);

  @override
  String toString() => 'DaySlot(${toJson()})';
}

/// Plus petit pas de charge disponible pour un type de charge.
final class LoadIncrement {
  const LoadIncrement({
    required this.loadType,
    required this.stepKg,
    this.minKg,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory LoadIncrement.fromJson(Map<String, Object?> json) {
    return LoadIncrement(
      loadType: jsonEnum(json, 'loadType', LoadType.fromCode),
      stepKg: jsonDouble(json, 'stepKg'),
      minKg: jsonDoubleOrNull(json, 'minKg'),
    );
  }

  /// Type de charge.
  final LoadType loadType;

  /// Pas de charge, en kg.
  final double stepKg;

  /// Plus petite charge disponible, en kg.
  final double? minKg;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'loadType': loadType.code,
      'stepKg': stepKg,
      if (minKg case final v?) 'minKg': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  LoadIncrement copyWith({
    LoadType? loadType,
    double? stepKg,
    Object? minKg = unset,
  }) {
    return LoadIncrement(
      loadType: loadType ?? this.loadType,
      stepKg: stepKg ?? this.stepKg,
      minKg: identical(minKg, unset) ? this.minKg : minKg as double?,
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
    checkRange(out, '$path.stepKg', stepKg, 0.05, 50);
    if (minKg case final v?) { checkRange(out, '$path.minKg', v, 0, null); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is LoadIncrement && loadType == other.loadType && stepKg == other.stepKg && minKg == other.minKg;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[loadType, stepKg, minKg]);

  @override
  String toString() => 'LoadIncrement(${toJson()})';
}

/// Blessure ou limitation déclarée.
final class Limitation {
  const Limitation({
    required this.zone,
    required this.side,
    this.joint,
    required this.discomfort,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Limitation.fromJson(Map<String, Object?> json) {
    return Limitation(
      zone: jsonEnum(json, 'zone', BodyZone.fromCode),
      side: jsonEnum(json, 'side', BodySide.fromCode),
      joint: jsonEnumOrNull(json, 'joint', Joint.fromCode),
      discomfort: jsonInt(json, 'discomfort'),
    );
  }

  /// Zone du corps.
  final BodyZone zone;

  /// Côté.
  final BodySide side;

  /// Articulation concernée, si la zone en désigne une.
  final Joint? joint;

  /// Gêne de 0 à 10.
  final int discomfort;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'zone': zone.code,
      'side': side.code,
      if (joint case final v?) 'joint': v.code,
      'discomfort': discomfort,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Limitation copyWith({
    BodyZone? zone,
    BodySide? side,
    Object? joint = unset,
    int? discomfort,
  }) {
    return Limitation(
      zone: zone ?? this.zone,
      side: side ?? this.side,
      joint: identical(joint, unset) ? this.joint : joint as Joint?,
      discomfort: discomfort ?? this.discomfort,
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
    checkRange(out, '$path.discomfort', discomfort, 0, 10);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Limitation && zone == other.zone && side == other.side && joint == other.joint && discomfort == other.discomfort;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[zone, side, joint, discomfort]);

  @override
  String toString() => 'Limitation(${toJson()})';
}

/// Référence au questionnaire santé L13 (aucune réponse n'est copiée ici).
final class HealthScreeningRef {
  const HealthScreeningRef({
    required this.questionnaireId,
    this.answeredOn,
    required this.outcome,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory HealthScreeningRef.fromJson(Map<String, Object?> json) {
    return HealthScreeningRef(
      questionnaireId: jsonString(json, 'questionnaireId'),
      answeredOn: jsonDateOrNull(json, 'answeredOn'),
      outcome: jsonEnum(json, 'outcome', HealthScreeningOutcome.fromCode),
    );
  }

  /// Identifiant et version du questionnaire.
  final String questionnaireId;

  /// Jour de réponse.
  final CivilDate? answeredOn;

  /// Résultat : standard, mode prudent, non répondu.
  final HealthScreeningOutcome outcome;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'questionnaireId': questionnaireId,
      if (answeredOn case final v?) 'answeredOn': v.iso,
      'outcome': outcome.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  HealthScreeningRef copyWith({
    String? questionnaireId,
    Object? answeredOn = unset,
    HealthScreeningOutcome? outcome,
  }) {
    return HealthScreeningRef(
      questionnaireId: questionnaireId ?? this.questionnaireId,
      answeredOn: identical(answeredOn, unset) ? this.answeredOn : answeredOn as CivilDate?,
      outcome: outcome ?? this.outcome,
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
    checkLength(out, '$path.questionnaireId', questionnaireId.length, 1, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is HealthScreeningRef && questionnaireId == other.questionnaireId && answeredOn == other.answeredOn && outcome == other.outcome;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[questionnaireId, answeredOn, outcome]);

  @override
  String toString() => 'HealthScreeningRef(${toJson()})';
}

/// Profil d'athlète v2 (D3).
///
/// Invariant : Jours de `availability` distincts ; lieux, matériel, exercices
/// aimés et détestés sans doublon ; aimés ∩ détestés = ∅.
/// Invariant : Un seul incrément par type de charge ; `updatedOn` ≥
/// `createdOn`.
/// Invariant : Mode street activé ⇒ `disciplines` est l'image du mode street
/// (`StreetMode.toDisciplineMix()`).
final class AthleteProfile {
  const AthleteProfile({
    this.schemaVersion = currentSchemaVersion,
    this.displayName,
    required this.sex,
    required this.birthYear,
    required this.heightCm,
    this.bodyWeightKg,
    required this.disciplines,
    this.streetMode,
    required this.movementLevels,
    required this.goals,
    required this.availability,
    required this.places,
    required this.equipment,
    required this.loadIncrements,
    required this.limitations,
    required this.likedExerciseIds,
    required this.dislikedExerciseIds,
    required this.guidanceMode,
    this.healthScreening,
    required this.createdOn,
    required this.updatedOn,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AthleteProfile.fromJson(Map<String, Object?> json) {
    return AthleteProfile(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      displayName: jsonStringOrNull(json, 'displayName'),
      sex: jsonEnum(json, 'sex', Sex.fromCode),
      birthYear: jsonInt(json, 'birthYear'),
      heightCm: jsonInt(json, 'heightCm'),
      bodyWeightKg: jsonDoubleOrNull(json, 'bodyWeightKg'),
      disciplines: jsonObj(json, 'disciplines', DisciplineMix.fromJson),
      streetMode: jsonObjOrNull(json, 'streetMode', StreetMode.fromJson),
      movementLevels: jsonList(json, 'movementLevels', (v) => MovementLevel.fromJson(jsonAsObject(v, 'movementLevels'))),
      goals: jsonList(json, 'goals', (v) => Goal.fromJson(jsonAsObject(v, 'goals'))),
      availability: jsonList(json, 'availability', (v) => DaySlot.fromJson(jsonAsObject(v, 'availability'))),
      places: jsonList(json, 'places', (v) => Place.fromCode(jsonAsString(v, 'places'))),
      equipment: jsonList(json, 'equipment', (v) => jsonAsString(v, 'equipment')),
      loadIncrements: jsonList(json, 'loadIncrements', (v) => LoadIncrement.fromJson(jsonAsObject(v, 'loadIncrements'))),
      limitations: jsonList(json, 'limitations', (v) => Limitation.fromJson(jsonAsObject(v, 'limitations'))),
      likedExerciseIds: jsonList(json, 'likedExerciseIds', (v) => jsonAsString(v, 'likedExerciseIds')),
      dislikedExerciseIds: jsonList(json, 'dislikedExerciseIds', (v) => jsonAsString(v, 'dislikedExerciseIds')),
      guidanceMode: jsonEnum(json, 'guidanceMode', GuidanceMode.fromCode),
      healthScreening: jsonObjOrNull(json, 'healthScreening', HealthScreeningRef.fromJson),
      createdOn: jsonDate(json, 'createdOn'),
      updatedOn: jsonDate(json, 'updatedOn'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 2;

  /// Version du schéma (2).
  final int schemaVersion;

  /// Prénom ou pseudo, facultatif.
  final String? displayName;

  /// Sexe déclaré.
  final Sex sex;

  /// Année de naissance.
  final int birthYear;

  /// Taille en centimètres.
  final int heightCm;

  /// Poids de corps en kg, facultatif.
  final double? bodyWeightKg;

  /// Disciplines et dosages.
  final DisciplineMix disciplines;

  /// Mode street, s'il est activé.
  final StreetMode? streetMode;

  /// Niveaux déclarés par mouvement.
  final List<MovementLevel> movementLevels;

  /// Objectifs.
  final List<Goal> goals;

  /// Jours et durées disponibles.
  final List<DaySlot> availability;

  /// Lieux d'entraînement.
  final List<Place> places;

  /// Matériel disponible (vocabulaire `materiel` de la base).
  final List<String> equipment;

  /// Incréments de charge par type de charge.
  final List<LoadIncrement> loadIncrements;

  /// Blessures et limitations.
  final List<Limitation> limitations;

  /// Exercices aimés.
  final List<String> likedExerciseIds;

  /// Exercices détestés.
  final List<String> dislikedExerciseIds;

  /// Mode assisté ou libre.
  final GuidanceMode guidanceMode;

  /// Référence au questionnaire santé.
  final HealthScreeningRef? healthScreening;

  /// Jour de création du profil.
  final CivilDate createdOn;

  /// Jour de dernière modification.
  final CivilDate updatedOn;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      if (displayName case final v?) 'displayName': v,
      'sex': sex.code,
      'birthYear': birthYear,
      'heightCm': heightCm,
      if (bodyWeightKg case final v?) 'bodyWeightKg': v,
      'disciplines': disciplines.toJson(),
      if (streetMode case final v?) 'streetMode': v.toJson(),
      'movementLevels': [for (final e in movementLevels) e.toJson()],
      'goals': [for (final e in goals) e.toJson()],
      'availability': [for (final e in availability) e.toJson()],
      'places': [for (final e in places) e.code],
      'equipment': [for (final e in equipment) e],
      'loadIncrements': [for (final e in loadIncrements) e.toJson()],
      'limitations': [for (final e in limitations) e.toJson()],
      'likedExerciseIds': [for (final e in likedExerciseIds) e],
      'dislikedExerciseIds': [for (final e in dislikedExerciseIds) e],
      'guidanceMode': guidanceMode.code,
      if (healthScreening case final v?) 'healthScreening': v.toJson(),
      'createdOn': createdOn.iso,
      'updatedOn': updatedOn.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AthleteProfile copyWith({
    int? schemaVersion,
    Object? displayName = unset,
    Sex? sex,
    int? birthYear,
    int? heightCm,
    Object? bodyWeightKg = unset,
    DisciplineMix? disciplines,
    Object? streetMode = unset,
    List<MovementLevel>? movementLevels,
    List<Goal>? goals,
    List<DaySlot>? availability,
    List<Place>? places,
    List<String>? equipment,
    List<LoadIncrement>? loadIncrements,
    List<Limitation>? limitations,
    List<String>? likedExerciseIds,
    List<String>? dislikedExerciseIds,
    GuidanceMode? guidanceMode,
    Object? healthScreening = unset,
    CivilDate? createdOn,
    CivilDate? updatedOn,
  }) {
    return AthleteProfile(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      displayName: identical(displayName, unset) ? this.displayName : displayName as String?,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      bodyWeightKg: identical(bodyWeightKg, unset) ? this.bodyWeightKg : bodyWeightKg as double?,
      disciplines: disciplines ?? this.disciplines,
      streetMode: identical(streetMode, unset) ? this.streetMode : streetMode as StreetMode?,
      movementLevels: movementLevels ?? this.movementLevels,
      goals: goals ?? this.goals,
      availability: availability ?? this.availability,
      places: places ?? this.places,
      equipment: equipment ?? this.equipment,
      loadIncrements: loadIncrements ?? this.loadIncrements,
      limitations: limitations ?? this.limitations,
      likedExerciseIds: likedExerciseIds ?? this.likedExerciseIds,
      dislikedExerciseIds: dislikedExerciseIds ?? this.dislikedExerciseIds,
      guidanceMode: guidanceMode ?? this.guidanceMode,
      healthScreening: identical(healthScreening, unset) ? this.healthScreening : healthScreening as HealthScreeningRef?,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
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
    checkRange(out, '$path.schemaVersion', schemaVersion, 2, currentSchemaVersion);
    if (displayName case final v?) { checkLength(out, '$path.displayName', v.length, null, 40); }
    checkRange(out, '$path.birthYear', birthYear, 1900, 2100);
    checkRange(out, '$path.heightCm', heightCm, 100, 250);
    if (bodyWeightKg case final v?) { checkRange(out, '$path.bodyWeightKg', v, 25, 300); }
    disciplines.collectViolations('$path.disciplines', out);
    if (streetMode case final v?) { v.collectViolations('$path.streetMode', out); }
    for (var i = 0; i < movementLevels.length; i++) { movementLevels[i].collectViolations('$path.movementLevels[$i]', out); }
    for (var i = 0; i < goals.length; i++) { goals[i].collectViolations('$path.goals[$i]', out); }
    checkLength(out, '$path.availability', availability.length, 1, 7);
    for (var i = 0; i < availability.length; i++) { availability[i].collectViolations('$path.availability[$i]', out); }
    checkLength(out, '$path.places', places.length, 1, 3);
    for (var i = 0; i < equipment.length; i++) { checkLength(out, '$path.equipment[$i]', equipment[i].length, 1, null); }
    for (var i = 0; i < loadIncrements.length; i++) { loadIncrements[i].collectViolations('$path.loadIncrements[$i]', out); }
    for (var i = 0; i < limitations.length; i++) { limitations[i].collectViolations('$path.limitations[$i]', out); }
    for (var i = 0; i < likedExerciseIds.length; i++) { checkLength(out, '$path.likedExerciseIds[$i]', likedExerciseIds[i].length, 1, null); }
    for (var i = 0; i < dislikedExerciseIds.length; i++) { checkLength(out, '$path.dislikedExerciseIds[$i]', dislikedExerciseIds[i].length, 1, null); }
    if (healthScreening case final v?) { v.collectViolations('$path.healthScreening', out); }
    _validateAthleteProfile(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    disciplines.collectExerciseIds(out);
    streetMode?.collectExerciseIds(out);
    for (final e in movementLevels) { e.collectExerciseIds(out); }
    for (final e in goals) { e.collectExerciseIds(out); }
    for (final e in availability) { e.collectExerciseIds(out); }
    for (final e in loadIncrements) { e.collectExerciseIds(out); }
    for (final e in limitations) { e.collectExerciseIds(out); }
    out.addAll(likedExerciseIds);
    out.addAll(dislikedExerciseIds);
    healthScreening?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AthleteProfile && schemaVersion == other.schemaVersion && displayName == other.displayName && sex == other.sex && birthYear == other.birthYear && heightCm == other.heightCm && bodyWeightKg == other.bodyWeightKg && disciplines == other.disciplines && streetMode == other.streetMode && jsonListEquals(movementLevels, other.movementLevels) && jsonListEquals(goals, other.goals) && jsonListEquals(availability, other.availability) && jsonListEquals(places, other.places) && jsonListEquals(equipment, other.equipment) && jsonListEquals(loadIncrements, other.loadIncrements) && jsonListEquals(limitations, other.limitations) && jsonListEquals(likedExerciseIds, other.likedExerciseIds) && jsonListEquals(dislikedExerciseIds, other.dislikedExerciseIds) && guidanceMode == other.guidanceMode && healthScreening == other.healthScreening && createdOn == other.createdOn && updatedOn == other.updatedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, displayName, sex, birthYear, heightCm, bodyWeightKg, disciplines, streetMode, Object.hashAll(movementLevels), Object.hashAll(goals), Object.hashAll(availability), Object.hashAll(places), Object.hashAll(equipment), Object.hashAll(loadIncrements), Object.hashAll(limitations), Object.hashAll(likedExerciseIds), Object.hashAll(dislikedExerciseIds), guidanceMode, healthScreening, createdOn, updatedOn]);

  @override
  String toString() => 'AthleteProfile(${toJson()})';
}
