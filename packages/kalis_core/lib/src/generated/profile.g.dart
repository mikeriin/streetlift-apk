// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Discipline secondaire et son dosage.
final class DisciplineShare {
  const DisciplineShare({required this.discipline, required this.pct});

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
    return <String, Object?>{'discipline': discipline.code, 'pct': pct};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DisciplineShare copyWith({TrainingDiscipline? discipline, int? pct}) {
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
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DisciplineShare &&
            discipline == other.discipline &&
            pct == other.pct;
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
      secondaries: jsonList(
        json,
        'secondaries',
        (v) => DisciplineShare.fromJson(jsonAsObject(v, 'secondaries')),
      ),
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
    for (var i = 0; i < secondaries.length; i++) {
      secondaries[i].collectViolations('$path.secondaries[$i]', out);
    }
    _validateDisciplineMix(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in secondaries) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DisciplineMix &&
            primary == other.primary &&
            primaryPct == other.primaryPct &&
            jsonListEquals(secondaries, other.secondaries);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    primary,
    primaryPct,
    Object.hashAll(secondaries),
  ]);

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
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StreetMode &&
            primary == other.primary &&
            streetliftingPct == other.streetliftingPct &&
            setsRepsPct == other.setsRepsPct &&
            calisthenicsPct == other.calisthenicsPct;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    primary,
    streetliftingPct,
    setsRepsPct,
    calisthenicsPct,
  ]);

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
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
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
    if (low case final v?) {
      checkRange(out, '$path.low', v, 0, null);
    }
    if (high case final v?) {
      checkRange(out, '$path.high', v, 0, null);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    _validateMovementLevel(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MovementLevel &&
            exerciseId == other.exerciseId &&
            measure == other.measure &&
            known == other.known &&
            low == other.low &&
            high == other.high &&
            distanceMeters == other.distanceMeters;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    measure,
    known,
    low,
    high,
    distanceMeters,
  ]);

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
    this.loadKg,
    this.durationSeconds,
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
      loadKg: jsonDoubleOrNull(json, 'loadKg'),
      durationSeconds: jsonIntOrNull(json, 'durationSeconds'),
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

  /// Valeur cible, dans l'unité de `metric` (charge EXTERNE pour `one_rm_kg` ;
  /// absente pour `skill_unlocked`).
  final double? targetValue;

  /// Distance de référence pour `time_seconds`.
  final double? distanceMeters;

  /// Charge externe de référence pour `max_reps` (« 38 répétitions à 70 kg »).
  final double? loadKg;

  /// Durée de référence pour `distance_meters`.
  final int? durationSeconds;

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
      if (loadKg case final v?) 'loadKg': v,
      if (durationSeconds case final v?) 'durationSeconds': v,
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
    Object? loadKg = unset,
    Object? durationSeconds = unset,
    Object? targetDate = unset,
    Object? sessionsPerWeek = unset,
    Object? weeks = unset,
  }) {
    return Goal(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      origin: origin ?? this.origin,
      createdOn: createdOn ?? this.createdOn,
      exerciseId: identical(exerciseId, unset)
          ? this.exerciseId
          : exerciseId as String?,
      metric: identical(metric, unset) ? this.metric : metric as GoalMetric?,
      targetValue: identical(targetValue, unset)
          ? this.targetValue
          : targetValue as double?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      loadKg: identical(loadKg, unset) ? this.loadKg : loadKg as double?,
      durationSeconds: identical(durationSeconds, unset)
          ? this.durationSeconds
          : durationSeconds as int?,
      targetDate: identical(targetDate, unset)
          ? this.targetDate
          : targetDate as CivilDate?,
      sessionsPerWeek: identical(sessionsPerWeek, unset)
          ? this.sessionsPerWeek
          : sessionsPerWeek as int?,
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
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
    if (targetValue case final v?) {
      checkRange(out, '$path.targetValue', v, 0, null);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    if (loadKg case final v?) {
      checkRange(out, '$path.loadKg', v, 0, null);
    }
    if (durationSeconds case final v?) {
      checkRange(out, '$path.durationSeconds', v, 1, null);
    }
    if (sessionsPerWeek case final v?) {
      checkRange(out, '$path.sessionsPerWeek', v, 1, 14);
    }
    if (weeks case final v?) {
      checkRange(out, '$path.weeks', v, 1, 104);
    }
    _validateGoal(this, path, out);
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
        other is Goal &&
            id == other.id &&
            kind == other.kind &&
            origin == other.origin &&
            createdOn == other.createdOn &&
            exerciseId == other.exerciseId &&
            metric == other.metric &&
            targetValue == other.targetValue &&
            distanceMeters == other.distanceMeters &&
            loadKg == other.loadKg &&
            durationSeconds == other.durationSeconds &&
            targetDate == other.targetDate &&
            sessionsPerWeek == other.sessionsPerWeek &&
            weeks == other.weeks;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    kind,
    origin,
    createdOn,
    exerciseId,
    metric,
    targetValue,
    distanceMeters,
    loadKg,
    durationSeconds,
    targetDate,
    sessionsPerWeek,
    weeks,
  ]);

  @override
  String toString() => 'Goal(${toJson()})';
}

/// Disponibilité d'un jour précis (D3.6).
final class DaySlot {
  const DaySlot({required this.weekday, required this.minutes, this.place});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DaySlot.fromJson(Map<String, Object?> json) {
    return DaySlot(
      weekday: jsonInt(json, 'weekday'),
      minutes: jsonInt(json, 'minutes'),
      place: jsonEnumOrNull(json, 'place', Place.fromCode),
    );
  }

  /// Jour ISO : 1 = lundi … 7 = dimanche.
  final int weekday;

  /// Durée disponible, en minutes.
  final int minutes;

  /// Lieu de ce jour-là (absent : n'importe quel lieu du profil).
  final Place? place;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'weekday': weekday,
      'minutes': minutes,
      if (place case final v?) 'place': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DaySlot copyWith({int? weekday, int? minutes, Object? place = unset}) {
    return DaySlot(
      weekday: weekday ?? this.weekday,
      minutes: minutes ?? this.minutes,
      place: identical(place, unset) ? this.place : place as Place?,
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
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DaySlot &&
            weekday == other.weekday &&
            minutes == other.minutes &&
            place == other.place;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[weekday, minutes, place]);

  @override
  String toString() => 'DaySlot(${toJson()})';
}

/// Matériel disponible dans un lieu.
final class PlaceEquipment {
  const PlaceEquipment({required this.place, required this.equipment});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlaceEquipment.fromJson(Map<String, Object?> json) {
    return PlaceEquipment(
      place: jsonEnum(json, 'place', Place.fromCode),
      equipment: jsonList(
        json,
        'equipment',
        (v) => jsonAsString(v, 'equipment'),
      ),
    );
  }

  /// Lieu.
  final Place place;

  /// Matériel disponible dans ce lieu (vocabulaire `materiel` de la base).
  final List<String> equipment;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'place': place.code,
      'equipment': [for (final e in equipment) e],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlaceEquipment copyWith({Place? place, List<String>? equipment}) {
    return PlaceEquipment(
      place: place ?? this.place,
      equipment: equipment ?? this.equipment,
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
    for (var i = 0; i < equipment.length; i++) {
      checkLength(out, '$path.equipment[$i]', equipment[i].length, 1, null);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlaceEquipment &&
            place == other.place &&
            jsonListEquals(equipment, other.equipment);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[place, Object.hashAll(equipment)]);

  @override
  String toString() => 'PlaceEquipment(${toJson()})';
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
    if (minKg case final v?) {
      checkRange(out, '$path.minKg', v, 0, null);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LoadIncrement &&
            loadType == other.loadType &&
            stepKg == other.stepKg &&
            minKg == other.minKg;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[loadType, stepKg, minKg]);

  @override
  String toString() => 'LoadIncrement(${toJson()})';
}

/// Blessure ou limitation déclarée.
///
/// Invariant : `aggravatedBy` sans doublon.
final class Limitation {
  const Limitation({
    required this.zone,
    required this.side,
    this.joint,
    required this.discomfort,
    this.since,
    this.aggravatedBy,
    this.effortDiscomfort,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Limitation.fromJson(Map<String, Object?> json) {
    return Limitation(
      zone: jsonEnum(json, 'zone', BodyZone.fromCode),
      side: jsonEnum(json, 'side', BodySide.fromCode),
      joint: jsonEnumOrNull(json, 'joint', Joint.fromCode),
      discomfort: jsonInt(json, 'discomfort'),
      since: jsonEnumOrNull(json, 'since', ConstraintSince.fromCode),
      aggravatedBy: jsonListOrNull(
        json,
        'aggravatedBy',
        (v) => AggravatingMovement.fromCode(jsonAsString(v, 'aggravatedBy')),
      ),
      effortDiscomfort: jsonIntOrNull(json, 'effortDiscomfort'),
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

  /// Depuis quand (0.4.0). Une gêne décrit une contrainte d'entraînement,
  /// jamais un diagnostic.
  final ConstraintSince? since;

  /// Familles de mouvements qui la réveillent (0.4.0).
  final List<AggravatingMovement>? aggravatedBy;

  /// Gêne au plus fort pendant l'effort, de 0 à 10 (0.4.0) ; `discomfort` reste
  /// la gêne du moment.
  final int? effortDiscomfort;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'zone': zone.code,
      'side': side.code,
      if (joint case final v?) 'joint': v.code,
      'discomfort': discomfort,
      if (since case final v?) 'since': v.code,
      if (aggravatedBy case final v?)
        'aggravatedBy': [for (final e in v) e.code],
      if (effortDiscomfort case final v?) 'effortDiscomfort': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Limitation copyWith({
    BodyZone? zone,
    BodySide? side,
    Object? joint = unset,
    int? discomfort,
    Object? since = unset,
    Object? aggravatedBy = unset,
    Object? effortDiscomfort = unset,
  }) {
    return Limitation(
      zone: zone ?? this.zone,
      side: side ?? this.side,
      joint: identical(joint, unset) ? this.joint : joint as Joint?,
      discomfort: discomfort ?? this.discomfort,
      since: identical(since, unset) ? this.since : since as ConstraintSince?,
      aggravatedBy: identical(aggravatedBy, unset)
          ? this.aggravatedBy
          : aggravatedBy as List<AggravatingMovement>?,
      effortDiscomfort: identical(effortDiscomfort, unset)
          ? this.effortDiscomfort
          : effortDiscomfort as int?,
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
    if (aggravatedBy case final v?) {
      checkLength(out, '$path.aggravatedBy', v.length, null, 14);
    }
    if (effortDiscomfort case final v?) {
      checkRange(out, '$path.effortDiscomfort', v, 0, 10);
    }
    _validateLimitation(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Limitation &&
            zone == other.zone &&
            side == other.side &&
            joint == other.joint &&
            discomfort == other.discomfort &&
            since == other.since &&
            jsonDeepEquals(aggravatedBy, other.aggravatedBy) &&
            effortDiscomfort == other.effortDiscomfort;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    zone,
    side,
    joint,
    discomfort,
    since,
    jsonDeepHash(aggravatedBy),
    effortDiscomfort,
  ]);

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
      answeredOn: identical(answeredOn, unset)
          ? this.answeredOn
          : answeredOn as CivilDate?,
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
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HealthScreeningRef &&
            questionnaireId == other.questionnaireId &&
            answeredOn == other.answeredOn &&
            outcome == other.outcome;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[questionnaireId, answeredOn, outcome]);

  @override
  String toString() => 'HealthScreeningRef(${toJson()})';
}

/// Profil d'athlète (D3). Schéma 3 depuis 0.4.0 : le schéma 2 reste lu tel
/// quel ; les champs du schéma 3 sont tous optionnels.
///
/// Invariant : Jours de `availability` distincts ; lieux, matériel, exercices
/// aimés et détestés sans doublon ; aimés ∩ détestés = ∅.
/// Invariant : Un seul incrément par type de charge ; `updatedOn` ≥
/// `createdOn`.
/// Invariant : Mode street activé ⇒ `disciplines` est l'image du mode street
/// (`StreetMode.toDisciplineMix()`).
/// Invariant : `equipmentByPlace` : un lieu au plus une fois, parmi `places`,
/// matériel inclus dans `equipment` ; `DaySlot.place` parmi `places` ; su ∩
/// pas su = ∅.
/// Invariant : Un champ du schéma 3 renseigné ⇒ `schemaVersion` ≥ 3 ;
/// identifiants d'`events` distincts ; figures visées de `skills` distinctes
/// ; mouvements de `recentTraining` distincts ; les `goalIds` d'une échéance
/// sont des objectifs du profil ; `targetBodyWeightKg` seulement avec
/// `bodyWeightGoal` `lose` ou `gain` ; `weakPoints` distincts (mouvement et
/// nature) ; `lifestyleUpdatedOn` ≥ `createdOn`.
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
    this.equipmentByPlace,
    required this.loadIncrements,
    required this.limitations,
    required this.likedExerciseIds,
    required this.dislikedExerciseIds,
    this.knownExerciseIds,
    this.cannotDoExerciseIds,
    this.experience,
    required this.guidanceMode,
    this.healthScreening,
    required this.createdOn,
    required this.updatedOn,
    this.trainingAge,
    this.trainingGap,
    this.sleep,
    this.stress,
    this.occupationalLoad,
    this.otherSports,
    this.bodyWeightGoal,
    this.benchmarks,
    this.events,
    this.skills,
    this.weakPoints,
    this.specialization,
    this.recentTraining,
    this.currentPhase,
    this.emphasis,
    this.enduranceBase,
    this.targetBodyWeightKg,
    this.lifestyleUpdatedOn,
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
      movementLevels: jsonList(
        json,
        'movementLevels',
        (v) => MovementLevel.fromJson(jsonAsObject(v, 'movementLevels')),
      ),
      goals: jsonList(
        json,
        'goals',
        (v) => Goal.fromJson(jsonAsObject(v, 'goals')),
      ),
      availability: jsonList(
        json,
        'availability',
        (v) => DaySlot.fromJson(jsonAsObject(v, 'availability')),
      ),
      places: jsonList(
        json,
        'places',
        (v) => Place.fromCode(jsonAsString(v, 'places')),
      ),
      equipment: jsonList(
        json,
        'equipment',
        (v) => jsonAsString(v, 'equipment'),
      ),
      equipmentByPlace: jsonListOrNull(
        json,
        'equipmentByPlace',
        (v) => PlaceEquipment.fromJson(jsonAsObject(v, 'equipmentByPlace')),
      ),
      loadIncrements: jsonList(
        json,
        'loadIncrements',
        (v) => LoadIncrement.fromJson(jsonAsObject(v, 'loadIncrements')),
      ),
      limitations: jsonList(
        json,
        'limitations',
        (v) => Limitation.fromJson(jsonAsObject(v, 'limitations')),
      ),
      likedExerciseIds: jsonList(
        json,
        'likedExerciseIds',
        (v) => jsonAsString(v, 'likedExerciseIds'),
      ),
      dislikedExerciseIds: jsonList(
        json,
        'dislikedExerciseIds',
        (v) => jsonAsString(v, 'dislikedExerciseIds'),
      ),
      knownExerciseIds: jsonListOrNull(
        json,
        'knownExerciseIds',
        (v) => jsonAsString(v, 'knownExerciseIds'),
      ),
      cannotDoExerciseIds: jsonListOrNull(
        json,
        'cannotDoExerciseIds',
        (v) => jsonAsString(v, 'cannotDoExerciseIds'),
      ),
      experience: jsonEnumOrNull(json, 'experience', ExperienceLevel.fromCode),
      guidanceMode: jsonEnum(json, 'guidanceMode', GuidanceMode.fromCode),
      healthScreening: jsonObjOrNull(
        json,
        'healthScreening',
        HealthScreeningRef.fromJson,
      ),
      createdOn: jsonDate(json, 'createdOn'),
      updatedOn: jsonDate(json, 'updatedOn'),
      trainingAge: jsonEnumOrNull(json, 'trainingAge', TrainingAge.fromCode),
      trainingGap: jsonEnumOrNull(json, 'trainingGap', TrainingGap.fromCode),
      sleep: jsonEnumOrNull(json, 'sleep', SleepBand.fromCode),
      stress: jsonEnumOrNull(json, 'stress', StressBand.fromCode),
      occupationalLoad: jsonEnumOrNull(
        json,
        'occupationalLoad',
        OccupationalLoad.fromCode,
      ),
      otherSports: jsonListOrNull(
        json,
        'otherSports',
        (v) => OtherSport.fromJson(jsonAsObject(v, 'otherSports')),
      ),
      bodyWeightGoal: jsonEnumOrNull(
        json,
        'bodyWeightGoal',
        BodyWeightGoal.fromCode,
      ),
      benchmarks: jsonListOrNull(
        json,
        'benchmarks',
        (v) => Benchmark.fromJson(jsonAsObject(v, 'benchmarks')),
      ),
      events: jsonListOrNull(
        json,
        'events',
        (v) => SeasonEvent.fromJson(jsonAsObject(v, 'events')),
      ),
      skills: jsonListOrNull(
        json,
        'skills',
        (v) => SkillState.fromJson(jsonAsObject(v, 'skills')),
      ),
      weakPoints: jsonListOrNull(
        json,
        'weakPoints',
        (v) => WeakPoint.fromJson(jsonAsObject(v, 'weakPoints')),
      ),
      specialization: jsonObjOrNull(
        json,
        'specialization',
        Specialization.fromJson,
      ),
      recentTraining: jsonListOrNull(
        json,
        'recentTraining',
        (v) => RecentTraining.fromJson(jsonAsObject(v, 'recentTraining')),
      ),
      currentPhase: jsonEnumOrNull(json, 'currentPhase', CurrentPhase.fromCode),
      emphasis: jsonEnumOrNull(json, 'emphasis', TrainingEmphasis.fromCode),
      enduranceBase: jsonObjOrNull(
        json,
        'enduranceBase',
        EnduranceBase.fromJson,
      ),
      targetBodyWeightKg: jsonDoubleOrNull(json, 'targetBodyWeightKg'),
      lifestyleUpdatedOn: jsonDateOrNull(json, 'lifestyleUpdatedOn'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 3;

  /// Version du schéma (2 ou 3).
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

  /// Matériel disponible, tous lieux confondus (vocabulaire `materiel` de la
  /// base).
  final List<String> equipment;

  /// Matériel par lieu, quand il diffère d'un lieu à l'autre (absent :
  /// `equipment` vaut partout).
  final List<PlaceEquipment>? equipmentByPlace;

  /// Incréments de charge par type de charge.
  final List<LoadIncrement> loadIncrements;

  /// Blessures et limitations.
  final List<Limitation> limitations;

  /// Exercices aimés.
  final List<String> likedExerciseIds;

  /// Exercices détestés.
  final List<String> dislikedExerciseIds;

  /// Exercices que l'utilisateur a dit savoir faire (revue, D4.5).
  final List<String>? knownExerciseIds;

  /// Exercices que l'utilisateur a dit ne pas savoir faire (revue, D4.5).
  final List<String>? cannotDoExerciseIds;

  /// Niveau global d'expérience déclaré.
  final ExperienceLevel? experience;

  /// Mode assisté ou libre.
  final GuidanceMode guidanceMode;

  /// Référence au questionnaire santé.
  final HealthScreeningRef? healthScreening;

  /// Jour de création du profil.
  final CivilDate createdOn;

  /// Jour de dernière modification.
  final CivilDate updatedOn;

  /// Ancienneté de pratique régulière de la discipline principale (schéma 3).
  final TrainingAge? trainingAge;

  /// Interruption en cours au moment de répondre (schéma 3) ; ensuite, les
  /// coupures se lisent dans le journal.
  final TrainingGap? trainingGap;

  /// Durée habituelle de sommeil (schéma 3).
  final SleepBand? sleep;

  /// Stress habituel de la vie hors entraînement (schéma 3).
  final StressBand? stress;

  /// Charge physique habituelle du métier ou des journées (schéma 3).
  final OccupationalLoad? occupationalLoad;

  /// Autres sports réguliers (schéma 3). Absent : question non posée ou passée
  /// ; liste vide : aucun.
  final List<OtherSport>? otherSports;

  /// Évolution voulue du poids de corps en ce moment (schéma 3).
  final BodyWeightGoal? bodyWeightGoal;

  /// Tests et records connus (schéma 3). Absent : question non posée ou passée.
  final List<Benchmark>? benchmarks;

  /// Compétitions et tests datés (schéma 3). Absent : question non posée ou
  /// passée ; liste vide : aucune échéance.
  final List<SeasonEvent>? events;

  /// Figures visées et étape actuelle, par ordre de priorité (schéma 3).
  final List<SkillState>? skills;

  /// Points faibles déclarés (schéma 3).
  final List<WeakPoint>? weakPoints;

  /// Priorité voulue par l'utilisateur (schéma 3).
  final Specialization? specialization;

  /// Charge d'entraînement actuelle par mouvement ou figure (schéma 3).
  final List<RecentTraining>? recentTraining;

  /// Ce que l'utilisateur fait en ce moment (schéma 3).
  final CurrentPhase? currentPhase;

  /// Ce qu'il cherche surtout en musculation (schéma 3).
  final TrainingEmphasis? emphasis;

  /// Volume de course actuel (schéma 3).
  final EnduranceBase? enduranceBase;

  /// Poids de corps visé, en kg, quand `bodyWeightGoal` vaut `lose` ou `gain`
  /// (schéma 3).
  final double? targetBodyWeightKg;

  /// Jour de la dernière réponse aux questions de récupération et de vie
  /// (sommeil, stress, métier, autres sports, poids, charge actuelle) (schéma
  /// 3) : elles se redemandent de temps en temps.
  final CivilDate? lifestyleUpdatedOn;

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
      if (equipmentByPlace case final v?)
        'equipmentByPlace': [for (final e in v) e.toJson()],
      'loadIncrements': [for (final e in loadIncrements) e.toJson()],
      'limitations': [for (final e in limitations) e.toJson()],
      'likedExerciseIds': [for (final e in likedExerciseIds) e],
      'dislikedExerciseIds': [for (final e in dislikedExerciseIds) e],
      if (knownExerciseIds case final v?)
        'knownExerciseIds': [for (final e in v) e],
      if (cannotDoExerciseIds case final v?)
        'cannotDoExerciseIds': [for (final e in v) e],
      if (experience case final v?) 'experience': v.code,
      'guidanceMode': guidanceMode.code,
      if (healthScreening case final v?) 'healthScreening': v.toJson(),
      'createdOn': createdOn.iso,
      'updatedOn': updatedOn.iso,
      if (trainingAge case final v?) 'trainingAge': v.code,
      if (trainingGap case final v?) 'trainingGap': v.code,
      if (sleep case final v?) 'sleep': v.code,
      if (stress case final v?) 'stress': v.code,
      if (occupationalLoad case final v?) 'occupationalLoad': v.code,
      if (otherSports case final v?)
        'otherSports': [for (final e in v) e.toJson()],
      if (bodyWeightGoal case final v?) 'bodyWeightGoal': v.code,
      if (benchmarks case final v?)
        'benchmarks': [for (final e in v) e.toJson()],
      if (events case final v?) 'events': [for (final e in v) e.toJson()],
      if (skills case final v?) 'skills': [for (final e in v) e.toJson()],
      if (weakPoints case final v?)
        'weakPoints': [for (final e in v) e.toJson()],
      if (specialization case final v?) 'specialization': v.toJson(),
      if (recentTraining case final v?)
        'recentTraining': [for (final e in v) e.toJson()],
      if (currentPhase case final v?) 'currentPhase': v.code,
      if (emphasis case final v?) 'emphasis': v.code,
      if (enduranceBase case final v?) 'enduranceBase': v.toJson(),
      if (targetBodyWeightKg case final v?) 'targetBodyWeightKg': v,
      if (lifestyleUpdatedOn case final v?) 'lifestyleUpdatedOn': v.iso,
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
    Object? equipmentByPlace = unset,
    List<LoadIncrement>? loadIncrements,
    List<Limitation>? limitations,
    List<String>? likedExerciseIds,
    List<String>? dislikedExerciseIds,
    Object? knownExerciseIds = unset,
    Object? cannotDoExerciseIds = unset,
    Object? experience = unset,
    GuidanceMode? guidanceMode,
    Object? healthScreening = unset,
    CivilDate? createdOn,
    CivilDate? updatedOn,
    Object? trainingAge = unset,
    Object? trainingGap = unset,
    Object? sleep = unset,
    Object? stress = unset,
    Object? occupationalLoad = unset,
    Object? otherSports = unset,
    Object? bodyWeightGoal = unset,
    Object? benchmarks = unset,
    Object? events = unset,
    Object? skills = unset,
    Object? weakPoints = unset,
    Object? specialization = unset,
    Object? recentTraining = unset,
    Object? currentPhase = unset,
    Object? emphasis = unset,
    Object? enduranceBase = unset,
    Object? targetBodyWeightKg = unset,
    Object? lifestyleUpdatedOn = unset,
  }) {
    return AthleteProfile(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      displayName: identical(displayName, unset)
          ? this.displayName
          : displayName as String?,
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      bodyWeightKg: identical(bodyWeightKg, unset)
          ? this.bodyWeightKg
          : bodyWeightKg as double?,
      disciplines: disciplines ?? this.disciplines,
      streetMode: identical(streetMode, unset)
          ? this.streetMode
          : streetMode as StreetMode?,
      movementLevels: movementLevels ?? this.movementLevels,
      goals: goals ?? this.goals,
      availability: availability ?? this.availability,
      places: places ?? this.places,
      equipment: equipment ?? this.equipment,
      equipmentByPlace: identical(equipmentByPlace, unset)
          ? this.equipmentByPlace
          : equipmentByPlace as List<PlaceEquipment>?,
      loadIncrements: loadIncrements ?? this.loadIncrements,
      limitations: limitations ?? this.limitations,
      likedExerciseIds: likedExerciseIds ?? this.likedExerciseIds,
      dislikedExerciseIds: dislikedExerciseIds ?? this.dislikedExerciseIds,
      knownExerciseIds: identical(knownExerciseIds, unset)
          ? this.knownExerciseIds
          : knownExerciseIds as List<String>?,
      cannotDoExerciseIds: identical(cannotDoExerciseIds, unset)
          ? this.cannotDoExerciseIds
          : cannotDoExerciseIds as List<String>?,
      experience: identical(experience, unset)
          ? this.experience
          : experience as ExperienceLevel?,
      guidanceMode: guidanceMode ?? this.guidanceMode,
      healthScreening: identical(healthScreening, unset)
          ? this.healthScreening
          : healthScreening as HealthScreeningRef?,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
      trainingAge: identical(trainingAge, unset)
          ? this.trainingAge
          : trainingAge as TrainingAge?,
      trainingGap: identical(trainingGap, unset)
          ? this.trainingGap
          : trainingGap as TrainingGap?,
      sleep: identical(sleep, unset) ? this.sleep : sleep as SleepBand?,
      stress: identical(stress, unset) ? this.stress : stress as StressBand?,
      occupationalLoad: identical(occupationalLoad, unset)
          ? this.occupationalLoad
          : occupationalLoad as OccupationalLoad?,
      otherSports: identical(otherSports, unset)
          ? this.otherSports
          : otherSports as List<OtherSport>?,
      bodyWeightGoal: identical(bodyWeightGoal, unset)
          ? this.bodyWeightGoal
          : bodyWeightGoal as BodyWeightGoal?,
      benchmarks: identical(benchmarks, unset)
          ? this.benchmarks
          : benchmarks as List<Benchmark>?,
      events: identical(events, unset)
          ? this.events
          : events as List<SeasonEvent>?,
      skills: identical(skills, unset)
          ? this.skills
          : skills as List<SkillState>?,
      weakPoints: identical(weakPoints, unset)
          ? this.weakPoints
          : weakPoints as List<WeakPoint>?,
      specialization: identical(specialization, unset)
          ? this.specialization
          : specialization as Specialization?,
      recentTraining: identical(recentTraining, unset)
          ? this.recentTraining
          : recentTraining as List<RecentTraining>?,
      currentPhase: identical(currentPhase, unset)
          ? this.currentPhase
          : currentPhase as CurrentPhase?,
      emphasis: identical(emphasis, unset)
          ? this.emphasis
          : emphasis as TrainingEmphasis?,
      enduranceBase: identical(enduranceBase, unset)
          ? this.enduranceBase
          : enduranceBase as EnduranceBase?,
      targetBodyWeightKg: identical(targetBodyWeightKg, unset)
          ? this.targetBodyWeightKg
          : targetBodyWeightKg as double?,
      lifestyleUpdatedOn: identical(lifestyleUpdatedOn, unset)
          ? this.lifestyleUpdatedOn
          : lifestyleUpdatedOn as CivilDate?,
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
      2,
      currentSchemaVersion,
    );
    if (displayName case final v?) {
      checkLength(out, '$path.displayName', v.length, null, 40);
    }
    checkRange(out, '$path.birthYear', birthYear, 1900, 2100);
    checkRange(out, '$path.heightCm', heightCm, 100, 250);
    if (bodyWeightKg case final v?) {
      checkRange(out, '$path.bodyWeightKg', v, 25, 300);
    }
    disciplines.collectViolations('$path.disciplines', out);
    if (streetMode case final v?) {
      v.collectViolations('$path.streetMode', out);
    }
    for (var i = 0; i < movementLevels.length; i++) {
      movementLevels[i].collectViolations('$path.movementLevels[$i]', out);
    }
    for (var i = 0; i < goals.length; i++) {
      goals[i].collectViolations('$path.goals[$i]', out);
    }
    checkLength(out, '$path.availability', availability.length, 1, 7);
    for (var i = 0; i < availability.length; i++) {
      availability[i].collectViolations('$path.availability[$i]', out);
    }
    checkLength(out, '$path.places', places.length, 1, 3);
    for (var i = 0; i < equipment.length; i++) {
      checkLength(out, '$path.equipment[$i]', equipment[i].length, 1, null);
    }
    if (equipmentByPlace case final v?) {
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.equipmentByPlace[$i]', out);
      }
    }
    for (var i = 0; i < loadIncrements.length; i++) {
      loadIncrements[i].collectViolations('$path.loadIncrements[$i]', out);
    }
    for (var i = 0; i < limitations.length; i++) {
      limitations[i].collectViolations('$path.limitations[$i]', out);
    }
    for (var i = 0; i < likedExerciseIds.length; i++) {
      checkLength(
        out,
        '$path.likedExerciseIds[$i]',
        likedExerciseIds[i].length,
        1,
        null,
      );
    }
    for (var i = 0; i < dislikedExerciseIds.length; i++) {
      checkLength(
        out,
        '$path.dislikedExerciseIds[$i]',
        dislikedExerciseIds[i].length,
        1,
        null,
      );
    }
    if (knownExerciseIds case final v?) {
      for (var i = 0; i < v.length; i++) {
        checkLength(out, '$path.knownExerciseIds[$i]', v[i].length, 1, null);
      }
    }
    if (cannotDoExerciseIds case final v?) {
      for (var i = 0; i < v.length; i++) {
        checkLength(out, '$path.cannotDoExerciseIds[$i]', v[i].length, 1, null);
      }
    }
    if (healthScreening case final v?) {
      v.collectViolations('$path.healthScreening', out);
    }
    if (otherSports case final v?) {
      checkLength(out, '$path.otherSports', v.length, null, 6);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.otherSports[$i]', out);
      }
    }
    if (benchmarks case final v?) {
      checkLength(out, '$path.benchmarks', v.length, null, 200);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.benchmarks[$i]', out);
      }
    }
    if (events case final v?) {
      checkLength(out, '$path.events', v.length, null, 20);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.events[$i]', out);
      }
    }
    if (skills case final v?) {
      checkLength(out, '$path.skills', v.length, null, 30);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.skills[$i]', out);
      }
    }
    if (weakPoints case final v?) {
      checkLength(out, '$path.weakPoints', v.length, null, 30);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.weakPoints[$i]', out);
      }
    }
    if (specialization case final v?) {
      v.collectViolations('$path.specialization', out);
    }
    if (recentTraining case final v?) {
      checkLength(out, '$path.recentTraining', v.length, null, 12);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.recentTraining[$i]', out);
      }
    }
    if (enduranceBase case final v?) {
      v.collectViolations('$path.enduranceBase', out);
    }
    if (targetBodyWeightKg case final v?) {
      checkRange(out, '$path.targetBodyWeightKg', v, 25, 300);
    }
    _validateAthleteProfile(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    disciplines.collectExerciseIds(out);
    streetMode?.collectExerciseIds(out);
    for (final e in movementLevels) {
      e.collectExerciseIds(out);
    }
    for (final e in goals) {
      e.collectExerciseIds(out);
    }
    for (final e in availability) {
      e.collectExerciseIds(out);
    }
    for (final e in equipmentByPlace ?? const <PlaceEquipment>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in loadIncrements) {
      e.collectExerciseIds(out);
    }
    for (final e in limitations) {
      e.collectExerciseIds(out);
    }
    out.addAll(likedExerciseIds);
    out.addAll(dislikedExerciseIds);
    if (knownExerciseIds case final v?) {
      out.addAll(v);
    }
    if (cannotDoExerciseIds case final v?) {
      out.addAll(v);
    }
    healthScreening?.collectExerciseIds(out);
    for (final e in otherSports ?? const <OtherSport>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in benchmarks ?? const <Benchmark>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in events ?? const <SeasonEvent>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in skills ?? const <SkillState>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in weakPoints ?? const <WeakPoint>[]) {
      e.collectExerciseIds(out);
    }
    specialization?.collectExerciseIds(out);
    for (final e in recentTraining ?? const <RecentTraining>[]) {
      e.collectExerciseIds(out);
    }
    enduranceBase?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AthleteProfile &&
            schemaVersion == other.schemaVersion &&
            displayName == other.displayName &&
            sex == other.sex &&
            birthYear == other.birthYear &&
            heightCm == other.heightCm &&
            bodyWeightKg == other.bodyWeightKg &&
            disciplines == other.disciplines &&
            streetMode == other.streetMode &&
            jsonListEquals(movementLevels, other.movementLevels) &&
            jsonListEquals(goals, other.goals) &&
            jsonListEquals(availability, other.availability) &&
            jsonListEquals(places, other.places) &&
            jsonListEquals(equipment, other.equipment) &&
            jsonDeepEquals(equipmentByPlace, other.equipmentByPlace) &&
            jsonListEquals(loadIncrements, other.loadIncrements) &&
            jsonListEquals(limitations, other.limitations) &&
            jsonListEquals(likedExerciseIds, other.likedExerciseIds) &&
            jsonListEquals(dislikedExerciseIds, other.dislikedExerciseIds) &&
            jsonDeepEquals(knownExerciseIds, other.knownExerciseIds) &&
            jsonDeepEquals(cannotDoExerciseIds, other.cannotDoExerciseIds) &&
            experience == other.experience &&
            guidanceMode == other.guidanceMode &&
            healthScreening == other.healthScreening &&
            createdOn == other.createdOn &&
            updatedOn == other.updatedOn &&
            trainingAge == other.trainingAge &&
            trainingGap == other.trainingGap &&
            sleep == other.sleep &&
            stress == other.stress &&
            occupationalLoad == other.occupationalLoad &&
            jsonDeepEquals(otherSports, other.otherSports) &&
            bodyWeightGoal == other.bodyWeightGoal &&
            jsonDeepEquals(benchmarks, other.benchmarks) &&
            jsonDeepEquals(events, other.events) &&
            jsonDeepEquals(skills, other.skills) &&
            jsonDeepEquals(weakPoints, other.weakPoints) &&
            specialization == other.specialization &&
            jsonDeepEquals(recentTraining, other.recentTraining) &&
            currentPhase == other.currentPhase &&
            emphasis == other.emphasis &&
            enduranceBase == other.enduranceBase &&
            targetBodyWeightKg == other.targetBodyWeightKg &&
            lifestyleUpdatedOn == other.lifestyleUpdatedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    displayName,
    sex,
    birthYear,
    heightCm,
    bodyWeightKg,
    disciplines,
    streetMode,
    Object.hashAll(movementLevels),
    Object.hashAll(goals),
    Object.hashAll(availability),
    Object.hashAll(places),
    Object.hashAll(equipment),
    jsonDeepHash(equipmentByPlace),
    Object.hashAll(loadIncrements),
    Object.hashAll(limitations),
    Object.hashAll(likedExerciseIds),
    Object.hashAll(dislikedExerciseIds),
    jsonDeepHash(knownExerciseIds),
    jsonDeepHash(cannotDoExerciseIds),
    experience,
    guidanceMode,
    healthScreening,
    createdOn,
    updatedOn,
    trainingAge,
    trainingGap,
    sleep,
    stress,
    occupationalLoad,
    jsonDeepHash(otherSports),
    bodyWeightGoal,
    jsonDeepHash(benchmarks),
    jsonDeepHash(events),
    jsonDeepHash(skills),
    jsonDeepHash(weakPoints),
    specialization,
    jsonDeepHash(recentTraining),
    currentPhase,
    emphasis,
    enduranceBase,
    targetBodyWeightKg,
    lifestyleUpdatedOn,
  ]);

  @override
  String toString() => 'AthleteProfile(${toJson()})';
}

/// Autre sport pratiqué régulièrement en plus du programme (0.4.0). Sert à
/// placer les séances (pas de coefficient de volume).
///
/// Invariant : `weekdays` : jours de 1 à 7, distincts ; `regions` distinctes.
final class OtherSport {
  const OtherSport({
    required this.kind,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    this.weekdays,
    this.regions,
    this.hard,
    this.mainSport,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory OtherSport.fromJson(Map<String, Object?> json) {
    return OtherSport(
      kind: jsonEnum(json, 'kind', OtherSportKind.fromCode),
      sessionsPerWeek: jsonInt(json, 'sessionsPerWeek'),
      minutesPerSession: jsonInt(json, 'minutesPerSession'),
      weekdays: jsonListOrNull(
        json,
        'weekdays',
        (v) => jsonAsInt(v, 'weekdays'),
      ),
      regions: jsonListOrNull(
        json,
        'regions',
        (v) => BodyRegion.fromCode(jsonAsString(v, 'regions')),
      ),
      hard: jsonBoolOrNull(json, 'hard'),
      mainSport: jsonBoolOrNull(json, 'mainSport'),
    );
  }

  /// Sport.
  final OtherSportKind kind;

  /// Séances par semaine.
  final int sessionsPerWeek;

  /// Durée habituelle d'une séance, en minutes.
  final int minutesPerSession;

  /// Jours ISO habituels (1 = lundi … 7 = dimanche), s'ils sont fixes.
  final List<int>? weekdays;

  /// Régions sollicitées, quand le sport ne suffit pas à le dire (tous sauf
  /// course, vélo, natation, escalade).
  final List<BodyRegion>? regions;

  /// Séances intenses (fractionné, matchs, combats).
  final bool? hard;

  /// C'est le sport principal de l'utilisateur : le programme passe après lui.
  final bool? mainSport;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      'sessionsPerWeek': sessionsPerWeek,
      'minutesPerSession': minutesPerSession,
      if (weekdays case final v?) 'weekdays': [for (final e in v) e],
      if (regions case final v?) 'regions': [for (final e in v) e.code],
      if (hard case final v?) 'hard': v,
      if (mainSport case final v?) 'mainSport': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  OtherSport copyWith({
    OtherSportKind? kind,
    int? sessionsPerWeek,
    int? minutesPerSession,
    Object? weekdays = unset,
    Object? regions = unset,
    Object? hard = unset,
    Object? mainSport = unset,
  }) {
    return OtherSport(
      kind: kind ?? this.kind,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      minutesPerSession: minutesPerSession ?? this.minutesPerSession,
      weekdays: identical(weekdays, unset)
          ? this.weekdays
          : weekdays as List<int>?,
      regions: identical(regions, unset)
          ? this.regions
          : regions as List<BodyRegion>?,
      hard: identical(hard, unset) ? this.hard : hard as bool?,
      mainSport: identical(mainSport, unset)
          ? this.mainSport
          : mainSport as bool?,
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
    checkRange(out, '$path.sessionsPerWeek', sessionsPerWeek, 1, 14);
    checkRange(out, '$path.minutesPerSession', minutesPerSession, 10, 600);
    if (weekdays case final v?) {
      checkLength(out, '$path.weekdays', v.length, null, 7);
    }
    if (regions case final v?) {
      checkLength(out, '$path.regions', v.length, null, 5);
    }
    _validateOtherSport(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtherSport &&
            kind == other.kind &&
            sessionsPerWeek == other.sessionsPerWeek &&
            minutesPerSession == other.minutesPerSession &&
            jsonDeepEquals(weekdays, other.weekdays) &&
            jsonDeepEquals(regions, other.regions) &&
            hard == other.hard &&
            mainSport == other.mainSport;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    sessionsPerWeek,
    minutesPerSession,
    jsonDeepHash(weekdays),
    jsonDeepHash(regions),
    hard,
    mainSport,
  ]);

  @override
  String toString() => 'OtherSport(${toJson()})';
}

/// Ce que l'utilisateur fait aujourd'hui sur un mouvement ou une figure
/// (0.4.0) : sert à caler le premier bloc sur sa charge réelle.
final class RecentTraining {
  const RecentTraining({
    required this.exerciseId,
    required this.sessionsPerWeek,
    this.hardSets,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory RecentTraining.fromJson(Map<String, Object?> json) {
    return RecentTraining(
      exerciseId: jsonString(json, 'exerciseId'),
      sessionsPerWeek: jsonInt(json, 'sessionsPerWeek'),
      hardSets: jsonEnumOrNull(json, 'hardSets', HardSetsBand.fromCode),
    );
  }

  /// Mouvement ou figure.
  final String exerciseId;

  /// Séances par semaine où il est travaillé (0 : pas en ce moment).
  final int sessionsPerWeek;

  /// Séries dures par semaine sur ce mouvement.
  final HardSetsBand? hardSets;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'sessionsPerWeek': sessionsPerWeek,
      if (hardSets case final v?) 'hardSets': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  RecentTraining copyWith({
    String? exerciseId,
    int? sessionsPerWeek,
    Object? hardSets = unset,
  }) {
    return RecentTraining(
      exerciseId: exerciseId ?? this.exerciseId,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      hardSets: identical(hardSets, unset)
          ? this.hardSets
          : hardSets as HardSetsBand?,
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
    checkRange(out, '$path.sessionsPerWeek', sessionsPerWeek, 0, 14);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecentTraining &&
            exerciseId == other.exerciseId &&
            sessionsPerWeek == other.sessionsPerWeek &&
            hardSets == other.hardSets;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[exerciseId, sessionsPerWeek, hardSets]);

  @override
  String toString() => 'RecentTraining(${toJson()})';
}

/// Volume de course actuel (0.4.0) : sert à caler le premier bloc d'un
/// coureur.
final class EnduranceBase {
  const EnduranceBase({
    required this.weeklyVolume,
    required this.sessionsPerWeek,
    this.longRun,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory EnduranceBase.fromJson(Map<String, Object?> json) {
    return EnduranceBase(
      weeklyVolume: jsonEnum(json, 'weeklyVolume', RunVolumeBand.fromCode),
      sessionsPerWeek: jsonInt(json, 'sessionsPerWeek'),
      longRun: jsonEnumOrNull(json, 'longRun', LongRunBand.fromCode),
    );
  }

  /// Distance par semaine, en moyenne sur les 4 dernières semaines.
  final RunVolumeBand weeklyVolume;

  /// Sorties par semaine.
  final int sessionsPerWeek;

  /// Plus longue sortie récente.
  final LongRunBand? longRun;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'weeklyVolume': weeklyVolume.code,
      'sessionsPerWeek': sessionsPerWeek,
      if (longRun case final v?) 'longRun': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  EnduranceBase copyWith({
    RunVolumeBand? weeklyVolume,
    int? sessionsPerWeek,
    Object? longRun = unset,
  }) {
    return EnduranceBase(
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      longRun: identical(longRun, unset)
          ? this.longRun
          : longRun as LongRunBand?,
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
    checkRange(out, '$path.sessionsPerWeek', sessionsPerWeek, 0, 14);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnduranceBase &&
            weeklyVolume == other.weeklyVolume &&
            sessionsPerWeek == other.sessionsPerWeek &&
            longRun == other.longRun;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[weeklyVolume, sessionsPerWeek, longRun]);

  @override
  String toString() => 'EnduranceBase(${toJson()})';
}

/// Test ou record sur un exercice (0.4.0) : valeur exacte, datée, avec son
/// origine. Convention de charge : EXTERNE, comme l'utilisateur la lit (lest
/// seul pour un exercice lesté).
///
/// Invariant : `load_reps` : charge externe et répétitions (1 répétition, RIR
/// 0 = maximum mesuré) ; `max_reps` : répétitions (charge externe si
/// l'épreuve est lestée, durée si elle est limitée en temps) ; `max_hold` :
/// secondes ; `time_trial`, `distance_trial` : distance et durée ;
/// `reps_for_time` : répétitions imposées et temps réalisé.
final class Benchmark {
  const Benchmark({
    required this.exerciseId,
    required this.kind,
    required this.source,
    this.date,
    this.externalLoadKg,
    this.reps,
    this.rir,
    this.seconds,
    this.distanceMeters,
    this.bodyWeightKg,
    this.protocolId,
    this.competitionStandard,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Benchmark.fromJson(Map<String, Object?> json) {
    return Benchmark(
      exerciseId: jsonString(json, 'exerciseId'),
      kind: jsonEnum(json, 'kind', BenchmarkKind.fromCode),
      source: jsonEnum(json, 'source', BenchmarkSource.fromCode),
      date: jsonDateOrNull(json, 'date'),
      externalLoadKg: jsonDoubleOrNull(json, 'externalLoadKg'),
      reps: jsonIntOrNull(json, 'reps'),
      rir: jsonDoubleOrNull(json, 'rir'),
      seconds: jsonIntOrNull(json, 'seconds'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      bodyWeightKg: jsonDoubleOrNull(json, 'bodyWeightKg'),
      protocolId: jsonStringOrNull(json, 'protocolId'),
      competitionStandard: jsonBoolOrNull(json, 'competitionStandard'),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Nature.
  final BenchmarkKind kind;

  /// Origine.
  final BenchmarkSource source;

  /// Jour du test ou du record (absent : inconnu).
  final CivilDate? date;

  /// Charge externe, en kg (0 : sans charge ; négative : assistance).
  final double? externalLoadKg;

  /// Répétitions réalisées.
  final int? reps;

  /// Répétitions en réserve déclarées à la fin de la série (0 : série au
  /// maximum ; absent : inconnu).
  final double? rir;

  /// Durée, en secondes (maintien, temps réalisé, durée imposée).
  final int? seconds;

  /// Distance, en mètres.
  final double? distanceMeters;

  /// Poids de corps le jour du test, en kg (exercices au poids du corps ou
  /// lestés).
  final double? bodyWeightKg;

  /// Protocole de test guidé suivi (`docs/PARCOURS_V3.md`, § tests guidés).
  final String? protocolId;

  /// Fait au standard de compétition (amplitude complète, arrêts marqués) ;
  /// absent : inconnu. Les tentatives ne se fondent que sur des records au
  /// standard.
  final bool? competitionStandard;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'kind': kind.code,
      'source': source.code,
      if (date case final v?) 'date': v.iso,
      if (externalLoadKg case final v?) 'externalLoadKg': v,
      if (reps case final v?) 'reps': v,
      if (rir case final v?) 'rir': v,
      if (seconds case final v?) 'seconds': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (bodyWeightKg case final v?) 'bodyWeightKg': v,
      if (protocolId case final v?) 'protocolId': v,
      if (competitionStandard case final v?) 'competitionStandard': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Benchmark copyWith({
    String? exerciseId,
    BenchmarkKind? kind,
    BenchmarkSource? source,
    Object? date = unset,
    Object? externalLoadKg = unset,
    Object? reps = unset,
    Object? rir = unset,
    Object? seconds = unset,
    Object? distanceMeters = unset,
    Object? bodyWeightKg = unset,
    Object? protocolId = unset,
    Object? competitionStandard = unset,
  }) {
    return Benchmark(
      exerciseId: exerciseId ?? this.exerciseId,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      date: identical(date, unset) ? this.date : date as CivilDate?,
      externalLoadKg: identical(externalLoadKg, unset)
          ? this.externalLoadKg
          : externalLoadKg as double?,
      reps: identical(reps, unset) ? this.reps : reps as int?,
      rir: identical(rir, unset) ? this.rir : rir as double?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      bodyWeightKg: identical(bodyWeightKg, unset)
          ? this.bodyWeightKg
          : bodyWeightKg as double?,
      protocolId: identical(protocolId, unset)
          ? this.protocolId
          : protocolId as String?,
      competitionStandard: identical(competitionStandard, unset)
          ? this.competitionStandard
          : competitionStandard as bool?,
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
    if (externalLoadKg case final v?) {
      checkRange(out, '$path.externalLoadKg', v, -300, 1000);
    }
    if (reps case final v?) {
      checkRange(out, '$path.reps', v, 1, 1000);
    }
    if (rir case final v?) {
      checkRange(out, '$path.rir', v, 0, 10);
    }
    if (seconds case final v?) {
      checkRange(out, '$path.seconds', v, 1, 86400);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 1, null);
    }
    if (bodyWeightKg case final v?) {
      checkRange(out, '$path.bodyWeightKg', v, 25, 300);
    }
    if (protocolId case final v?) {
      checkLength(out, '$path.protocolId', v.length, 1, 40);
    }
    checkVariant(
      out,
      path,
      kind.code,
      <String, Object?>{
        'externalLoadKg': externalLoadKg,
        'reps': reps,
        'rir': rir,
        'seconds': seconds,
        'distanceMeters': distanceMeters,
      },
      const <String, List<String>>{
        'load_reps': <String>['externalLoadKg', 'reps'],
        'max_reps': <String>['reps'],
        'max_hold': <String>['seconds'],
        'time_trial': <String>['distanceMeters', 'seconds'],
        'distance_trial': <String>['distanceMeters', 'seconds'],
        'reps_for_time': <String>['reps', 'seconds'],
      },
      const <String, List<String>>{
        'load_reps': <String>['rir'],
        'max_reps': <String>['externalLoadKg', 'seconds'],
        'max_hold': <String>['externalLoadKg'],
        'time_trial': <String>[],
        'distance_trial': <String>[],
        'reps_for_time': <String>['externalLoadKg'],
      },
    );
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Benchmark &&
            exerciseId == other.exerciseId &&
            kind == other.kind &&
            source == other.source &&
            date == other.date &&
            externalLoadKg == other.externalLoadKg &&
            reps == other.reps &&
            rir == other.rir &&
            seconds == other.seconds &&
            distanceMeters == other.distanceMeters &&
            bodyWeightKg == other.bodyWeightKg &&
            protocolId == other.protocolId &&
            competitionStandard == other.competitionStandard;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    kind,
    source,
    date,
    externalLoadKg,
    reps,
    rir,
    seconds,
    distanceMeters,
    bodyWeightKg,
    protocolId,
    competitionStandard,
  ]);

  @override
  String toString() => 'Benchmark(${toJson()})';
}

/// Point faible déclaré sur un mouvement (0.4.0). Sert à choisir les
/// exercices d'assistance ; ce n'est pas une douleur (voir `Limitation`).
final class WeakPoint {
  const WeakPoint({required this.exerciseId, required this.kind});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory WeakPoint.fromJson(Map<String, Object?> json) {
    return WeakPoint(
      exerciseId: jsonString(json, 'exerciseId'),
      kind: jsonEnum(json, 'kind', WeakPointKind.fromCode),
    );
  }

  /// Mouvement concerné.
  final String exerciseId;

  /// Où ça bloque.
  final WeakPointKind kind;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{'exerciseId': exerciseId, 'kind': kind.code};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  WeakPoint copyWith({String? exerciseId, WeakPointKind? kind}) {
    return WeakPoint(
      exerciseId: exerciseId ?? this.exerciseId,
      kind: kind ?? this.kind,
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
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WeakPoint &&
            exerciseId == other.exerciseId &&
            kind == other.kind;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, kind]);

  @override
  String toString() => 'WeakPoint(${toJson()})';
}
