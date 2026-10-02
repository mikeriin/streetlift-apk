// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Mouvement d'une compétition de force à tentatives (0.4.0).
final class CompetitionLift {
  const CompetitionLift({
    required this.exerciseId,
    required this.attempts,
    this.minIncrementKg,
    this.bestKg,
    this.targetKg,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory CompetitionLift.fromJson(Map<String, Object?> json) {
    return CompetitionLift(
      exerciseId: jsonString(json, 'exerciseId'),
      attempts: jsonInt(json, 'attempts'),
      minIncrementKg: jsonDoubleOrNull(json, 'minIncrementKg'),
      bestKg: jsonDoubleOrNull(json, 'bestKg'),
      targetKg: jsonDoubleOrNull(json, 'targetKg'),
    );
  }

  /// Mouvement.
  final String exerciseId;

  /// Tentatives accordées.
  final int attempts;

  /// Plus petit saut de charge admis entre deux tentatives, en kg.
  final double? minIncrementKg;

  /// Meilleure barre déjà validée, en kg de charge externe (lest seul).
  final double? bestKg;

  /// Barre visée, en kg de charge externe.
  final double? targetKg;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'attempts': attempts,
      if (minIncrementKg case final v?) 'minIncrementKg': v,
      if (bestKg case final v?) 'bestKg': v,
      if (targetKg case final v?) 'targetKg': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  CompetitionLift copyWith({
    String? exerciseId,
    int? attempts,
    Object? minIncrementKg = unset,
    Object? bestKg = unset,
    Object? targetKg = unset,
  }) {
    return CompetitionLift(
      exerciseId: exerciseId ?? this.exerciseId,
      attempts: attempts ?? this.attempts,
      minIncrementKg: identical(minIncrementKg, unset)
          ? this.minIncrementKg
          : minIncrementKg as double?,
      bestKg: identical(bestKg, unset) ? this.bestKg : bestKg as double?,
      targetKg: identical(targetKg, unset)
          ? this.targetKg
          : targetKg as double?,
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
    checkRange(out, '$path.attempts', attempts, 1, 4);
    if (minIncrementKg case final v?) {
      checkRange(out, '$path.minIncrementKg', v, 0.25, 10);
    }
    if (bestKg case final v?) {
      checkRange(out, '$path.bestKg', v, -300, 1000);
    }
    if (targetKg case final v?) {
      checkRange(out, '$path.targetKg', v, -300, 1000);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CompetitionLift &&
            exerciseId == other.exerciseId &&
            attempts == other.attempts &&
            minIncrementKg == other.minIncrementKg &&
            bestKg == other.bestKg &&
            targetKg == other.targetKg;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    attempts,
    minIncrementKg,
    bestKg,
    targetKg,
  ]);

  @override
  String toString() => 'CompetitionLift(${toJson()})';
}

/// Poste d'une épreuve de répétitions (0.4.0) : un exercice, son volume
/// imposé ou son maximum.
///
/// Invariant : `reps` et `seconds` ne sont pas renseignés ensemble.
final class EventStation {
  const EventStation({
    required this.exerciseId,
    this.reps,
    this.seconds,
    this.externalLoadKg,
    this.unbroken,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory EventStation.fromJson(Map<String, Object?> json) {
    return EventStation(
      exerciseId: jsonString(json, 'exerciseId'),
      reps: jsonIntOrNull(json, 'reps'),
      seconds: jsonIntOrNull(json, 'seconds'),
      externalLoadKg: jsonDoubleOrNull(json, 'externalLoadKg'),
      unbroken: jsonBoolOrNull(json, 'unbroken'),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Répétitions imposées (absent : maximum).
  final int? reps;

  /// Durée imposée d'un maintien, en secondes.
  final int? seconds;

  /// Lest imposé, en kg.
  final double? externalLoadKg;

  /// Série indivisible (aucun repos pendant le poste).
  final bool? unbroken;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      if (reps case final v?) 'reps': v,
      if (seconds case final v?) 'seconds': v,
      if (externalLoadKg case final v?) 'externalLoadKg': v,
      if (unbroken case final v?) 'unbroken': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  EventStation copyWith({
    String? exerciseId,
    Object? reps = unset,
    Object? seconds = unset,
    Object? externalLoadKg = unset,
    Object? unbroken = unset,
  }) {
    return EventStation(
      exerciseId: exerciseId ?? this.exerciseId,
      reps: identical(reps, unset) ? this.reps : reps as int?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      externalLoadKg: identical(externalLoadKg, unset)
          ? this.externalLoadKg
          : externalLoadKg as double?,
      unbroken: identical(unbroken, unset) ? this.unbroken : unbroken as bool?,
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
    if (reps case final v?) {
      checkRange(out, '$path.reps', v, 1, 1000);
    }
    if (seconds case final v?) {
      checkRange(out, '$path.seconds', v, 1, 3600);
    }
    if (externalLoadKg case final v?) {
      checkRange(out, '$path.externalLoadKg', v, -300, 1000);
    }
    _validateEventStation(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EventStation &&
            exerciseId == other.exerciseId &&
            reps == other.reps &&
            seconds == other.seconds &&
            externalLoadKg == other.externalLoadKg &&
            unbroken == other.unbroken;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    reps,
    seconds,
    externalLoadKg,
    unbroken,
  ]);

  @override
  String toString() => 'EventStation(${toJson()})';
}

/// Échéance de la saison (0.4.0) : compétition ou test daté. Les formats
/// varient d'un organisateur à l'autre : rien n'est figé (mouvements,
/// tentatives, postes et temps sont des données).
///
/// Invariant : Compétition de force : `lifts` ; compétition de répétitions :
/// `mode` et `stations` ; course : `distanceMeters`.
/// Invariant : Mouvements de `lifts` distincts ; `stations` renseigné ⇒
/// `mode` renseigné.
final class SeasonEvent {
  const SeasonEvent({
    required this.id,
    required this.kind,
    required this.priority,
    required this.date,
    this.name,
    this.ruleset,
    this.weightClassKg,
    this.openWeightClass,
    this.lifts,
    this.mode,
    this.stations,
    this.rounds,
    this.timeLimitSeconds,
    this.distanceMeters,
    this.targetSeconds,
    this.goalIds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SeasonEvent.fromJson(Map<String, Object?> json) {
    return SeasonEvent(
      id: jsonString(json, 'id'),
      kind: jsonEnum(json, 'kind', EventKind.fromCode),
      priority: jsonEnum(json, 'priority', EventPriority.fromCode),
      date: jsonDate(json, 'date'),
      name: jsonStringOrNull(json, 'name'),
      ruleset: jsonStringOrNull(json, 'ruleset'),
      weightClassKg: jsonDoubleOrNull(json, 'weightClassKg'),
      openWeightClass: jsonBoolOrNull(json, 'openWeightClass'),
      lifts: jsonListOrNull(
        json,
        'lifts',
        (v) => CompetitionLift.fromJson(jsonAsObject(v, 'lifts')),
      ),
      mode: jsonEnumOrNull(json, 'mode', RepsEventMode.fromCode),
      stations: jsonListOrNull(
        json,
        'stations',
        (v) => EventStation.fromJson(jsonAsObject(v, 'stations')),
      ),
      rounds: jsonIntOrNull(json, 'rounds'),
      timeLimitSeconds: jsonIntOrNull(json, 'timeLimitSeconds'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      targetSeconds: jsonIntOrNull(json, 'targetSeconds'),
      goalIds: jsonListOrNull(
        json,
        'goalIds',
        (v) => jsonAsString(v, 'goalIds'),
      ),
    );
  }

  /// Identifiant stable de l'échéance.
  final String id;

  /// Nature.
  final EventKind kind;

  /// Priorité dans la saison.
  final EventPriority priority;

  /// Jour de l'échéance.
  final CivilDate date;

  /// Nom donné par l'utilisateur.
  final String? name;

  /// Code libre du règlement (`final_rep`, `isf_classic`, `isf_multirep`…),
  /// s'il est connu.
  final String? ruleset;

  /// Limite haute de la catégorie de poids de corps visée, en kg.
  final double? weightClassKg;

  /// Catégorie « plus de » : `weightClassKg` est alors la limite basse.
  final bool? openWeightClass;

  /// Mouvements, dans l'ordre de la compétition (compétition de force).
  final List<CompetitionLift>? lifts;

  /// Format de l'épreuve de répétitions.
  final RepsEventMode? mode;

  /// Postes, dans l'ordre (épreuve de répétitions).
  final List<EventStation>? stations;

  /// Nombre de tours de la suite de postes.
  final int? rounds;

  /// Limite de temps, en secondes.
  final int? timeLimitSeconds;

  /// Distance de la course, en mètres.
  final double? distanceMeters;

  /// Temps visé, en secondes.
  final int? targetSeconds;

  /// Objectifs du profil que sert cette échéance.
  final List<String>? goalIds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.code,
      'priority': priority.code,
      'date': date.iso,
      if (name case final v?) 'name': v,
      if (ruleset case final v?) 'ruleset': v,
      if (weightClassKg case final v?) 'weightClassKg': v,
      if (openWeightClass case final v?) 'openWeightClass': v,
      if (lifts case final v?) 'lifts': [for (final e in v) e.toJson()],
      if (mode case final v?) 'mode': v.code,
      if (stations case final v?) 'stations': [for (final e in v) e.toJson()],
      if (rounds case final v?) 'rounds': v,
      if (timeLimitSeconds case final v?) 'timeLimitSeconds': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (targetSeconds case final v?) 'targetSeconds': v,
      if (goalIds case final v?) 'goalIds': [for (final e in v) e],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SeasonEvent copyWith({
    String? id,
    EventKind? kind,
    EventPriority? priority,
    CivilDate? date,
    Object? name = unset,
    Object? ruleset = unset,
    Object? weightClassKg = unset,
    Object? openWeightClass = unset,
    Object? lifts = unset,
    Object? mode = unset,
    Object? stations = unset,
    Object? rounds = unset,
    Object? timeLimitSeconds = unset,
    Object? distanceMeters = unset,
    Object? targetSeconds = unset,
    Object? goalIds = unset,
  }) {
    return SeasonEvent(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      date: date ?? this.date,
      name: identical(name, unset) ? this.name : name as String?,
      ruleset: identical(ruleset, unset) ? this.ruleset : ruleset as String?,
      weightClassKg: identical(weightClassKg, unset)
          ? this.weightClassKg
          : weightClassKg as double?,
      openWeightClass: identical(openWeightClass, unset)
          ? this.openWeightClass
          : openWeightClass as bool?,
      lifts: identical(lifts, unset)
          ? this.lifts
          : lifts as List<CompetitionLift>?,
      mode: identical(mode, unset) ? this.mode : mode as RepsEventMode?,
      stations: identical(stations, unset)
          ? this.stations
          : stations as List<EventStation>?,
      rounds: identical(rounds, unset) ? this.rounds : rounds as int?,
      timeLimitSeconds: identical(timeLimitSeconds, unset)
          ? this.timeLimitSeconds
          : timeLimitSeconds as int?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      targetSeconds: identical(targetSeconds, unset)
          ? this.targetSeconds
          : targetSeconds as int?,
      goalIds: identical(goalIds, unset)
          ? this.goalIds
          : goalIds as List<String>?,
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
    if (name case final v?) {
      checkLength(out, '$path.name', v.length, null, 60);
    }
    if (ruleset case final v?) {
      checkLength(out, '$path.ruleset', v.length, 1, 40);
    }
    if (weightClassKg case final v?) {
      checkRange(out, '$path.weightClassKg', v, 25, 300);
    }
    if (lifts case final v?) {
      checkLength(out, '$path.lifts', v.length, 1, 6);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.lifts[$i]', out);
      }
    }
    if (stations case final v?) {
      checkLength(out, '$path.stations', v.length, 1, 40);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.stations[$i]', out);
      }
    }
    if (rounds case final v?) {
      checkRange(out, '$path.rounds', v, 1, 50);
    }
    if (timeLimitSeconds case final v?) {
      checkRange(out, '$path.timeLimitSeconds', v, 10, 14400);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    if (targetSeconds case final v?) {
      checkRange(out, '$path.targetSeconds', v, 1, 86400);
    }
    if (goalIds case final v?) {
      for (var i = 0; i < v.length; i++) {
        checkLength(out, '$path.goalIds[$i]', v[i].length, 1, null);
      }
    }
    checkVariant(
      out,
      path,
      kind.code,
      <String, Object?>{
        'lifts': lifts,
        'mode': mode,
        'stations': stations,
        'rounds': rounds,
        'timeLimitSeconds': timeLimitSeconds,
        'distanceMeters': distanceMeters,
        'targetSeconds': targetSeconds,
      },
      const <String, List<String>>{
        'strength_competition': <String>['lifts'],
        'reps_competition': <String>['mode', 'stations'],
        'freestyle_competition': <String>[],
        'race': <String>['distanceMeters'],
        'other_competition': <String>[],
        'personal_test': <String>[],
      },
      const <String, List<String>>{
        'strength_competition': <String>['timeLimitSeconds'],
        'reps_competition': <String>[
          'rounds',
          'timeLimitSeconds',
          'targetSeconds',
        ],
        'freestyle_competition': <String>['timeLimitSeconds'],
        'race': <String>['targetSeconds', 'timeLimitSeconds'],
        'other_competition': <String>[
          'lifts',
          'mode',
          'stations',
          'rounds',
          'timeLimitSeconds',
          'distanceMeters',
          'targetSeconds',
        ],
        'personal_test': <String>[
          'lifts',
          'mode',
          'stations',
          'rounds',
          'timeLimitSeconds',
          'distanceMeters',
          'targetSeconds',
        ],
      },
    );
    _validateSeasonEvent(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in lifts ?? const <CompetitionLift>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in stations ?? const <EventStation>[]) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SeasonEvent &&
            id == other.id &&
            kind == other.kind &&
            priority == other.priority &&
            date == other.date &&
            name == other.name &&
            ruleset == other.ruleset &&
            weightClassKg == other.weightClassKg &&
            openWeightClass == other.openWeightClass &&
            jsonDeepEquals(lifts, other.lifts) &&
            mode == other.mode &&
            jsonDeepEquals(stations, other.stations) &&
            rounds == other.rounds &&
            timeLimitSeconds == other.timeLimitSeconds &&
            distanceMeters == other.distanceMeters &&
            targetSeconds == other.targetSeconds &&
            jsonDeepEquals(goalIds, other.goalIds);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    kind,
    priority,
    date,
    name,
    ruleset,
    weightClassKg,
    openWeightClass,
    jsonDeepHash(lifts),
    mode,
    jsonDeepHash(stations),
    rounds,
    timeLimitSeconds,
    distanceMeters,
    targetSeconds,
    jsonDeepHash(goalIds),
  ]);

  @override
  String toString() => 'SeasonEvent(${toJson()})';
}

/// Spécialisation (0.4.0) : priorité donnée à un mouvement, une figure, un
/// groupe musculaire ou un schéma, et sort du reste.
///
/// Invariant : Exactement la cible de `kind` : `exerciseId` (mouvement,
/// figure), `muscle` ou `pattern`.
final class Specialization {
  const Specialization({
    required this.kind,
    this.exerciseId,
    this.muscle,
    this.pattern,
    this.weeks,
    this.maintenance,
    this.startedOn,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Specialization.fromJson(Map<String, Object?> json) {
    return Specialization(
      kind: jsonEnum(json, 'kind', SpecializationKind.fromCode),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      muscle: jsonStringOrNull(json, 'muscle'),
      pattern: jsonEnumOrNull(json, 'pattern', MovementPattern.fromCode),
      weeks: jsonIntOrNull(json, 'weeks'),
      maintenance: jsonEnumOrNull(
        json,
        'maintenance',
        MaintenancePolicy.fromCode,
      ),
      startedOn: jsonDateOrNull(json, 'startedOn'),
    );
  }

  /// Nature de la cible.
  final SpecializationKind kind;

  /// Mouvement ou figure visé.
  final String? exerciseId;

  /// Groupe musculaire visé (vocabulaire `muscles` de la base).
  final String? muscle;

  /// Schéma de mouvement visé.
  final MovementPattern? pattern;

  /// Durée voulue, en semaines (absent : au moteur de la fixer).
  final int? weeks;

  /// Sort du reste (absent : au moteur de le fixer).
  final MaintenancePolicy? maintenance;

  /// Premier jour de la spécialisation en cours.
  final CivilDate? startedOn;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (exerciseId case final v?) 'exerciseId': v,
      if (muscle case final v?) 'muscle': v,
      if (pattern case final v?) 'pattern': v.code,
      if (weeks case final v?) 'weeks': v,
      if (maintenance case final v?) 'maintenance': v.code,
      if (startedOn case final v?) 'startedOn': v.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Specialization copyWith({
    SpecializationKind? kind,
    Object? exerciseId = unset,
    Object? muscle = unset,
    Object? pattern = unset,
    Object? weeks = unset,
    Object? maintenance = unset,
    Object? startedOn = unset,
  }) {
    return Specialization(
      kind: kind ?? this.kind,
      exerciseId: identical(exerciseId, unset)
          ? this.exerciseId
          : exerciseId as String?,
      muscle: identical(muscle, unset) ? this.muscle : muscle as String?,
      pattern: identical(pattern, unset)
          ? this.pattern
          : pattern as MovementPattern?,
      weeks: identical(weeks, unset) ? this.weeks : weeks as int?,
      maintenance: identical(maintenance, unset)
          ? this.maintenance
          : maintenance as MaintenancePolicy?,
      startedOn: identical(startedOn, unset)
          ? this.startedOn
          : startedOn as CivilDate?,
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
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
    if (muscle case final v?) {
      checkLength(out, '$path.muscle', v.length, 1, null);
    }
    if (weeks case final v?) {
      checkRange(out, '$path.weeks', v, 2, 26);
    }
    checkVariant(
      out,
      path,
      kind.code,
      <String, Object?>{
        'exerciseId': exerciseId,
        'muscle': muscle,
        'pattern': pattern,
      },
      const <String, List<String>>{
        'exercise': <String>['exerciseId'],
        'skill': <String>['exerciseId'],
        'muscle': <String>['muscle'],
        'pattern': <String>['pattern'],
      },
      const <String, List<String>>{
        'exercise': <String>[],
        'skill': <String>[],
        'muscle': <String>[],
        'pattern': <String>[],
      },
    );
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
        other is Specialization &&
            kind == other.kind &&
            exerciseId == other.exerciseId &&
            muscle == other.muscle &&
            pattern == other.pattern &&
            weeks == other.weeks &&
            maintenance == other.maintenance &&
            startedOn == other.startedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    exerciseId,
    muscle,
    pattern,
    weeks,
    maintenance,
    startedOn,
  ]);

  @override
  String toString() => 'Specialization(${toJson()})';
}

/// Où en est l'utilisateur sur une figure (0.4.0) : figure visée, étape
/// actuelle de sa progression (graphe `variante_de` du catalogue), meilleure
/// performance sur cette étape.
final class SkillState {
  const SkillState({
    required this.targetExerciseId,
    required this.currentExerciseId,
    this.bestHoldSeconds,
    this.bestReps,
    this.assessedOn,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SkillState.fromJson(Map<String, Object?> json) {
    return SkillState(
      targetExerciseId: jsonString(json, 'targetExerciseId'),
      currentExerciseId: jsonString(json, 'currentExerciseId'),
      bestHoldSeconds: jsonIntOrNull(json, 'bestHoldSeconds'),
      bestReps: jsonIntOrNull(json, 'bestReps'),
      assessedOn: jsonDateOrNull(json, 'assessedOn'),
    );
  }

  /// Figure visée.
  final String targetExerciseId;

  /// Étape actuelle (la figure elle-même si elle est acquise).
  final String currentExerciseId;

  /// Meilleur maintien propre sur l'étape actuelle, en secondes.
  final int? bestHoldSeconds;

  /// Meilleur nombre de répétitions propres sur l'étape actuelle.
  final int? bestReps;

  /// Jour de cette mesure.
  final CivilDate? assessedOn;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetExerciseId': targetExerciseId,
      'currentExerciseId': currentExerciseId,
      if (bestHoldSeconds case final v?) 'bestHoldSeconds': v,
      if (bestReps case final v?) 'bestReps': v,
      if (assessedOn case final v?) 'assessedOn': v.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SkillState copyWith({
    String? targetExerciseId,
    String? currentExerciseId,
    Object? bestHoldSeconds = unset,
    Object? bestReps = unset,
    Object? assessedOn = unset,
  }) {
    return SkillState(
      targetExerciseId: targetExerciseId ?? this.targetExerciseId,
      currentExerciseId: currentExerciseId ?? this.currentExerciseId,
      bestHoldSeconds: identical(bestHoldSeconds, unset)
          ? this.bestHoldSeconds
          : bestHoldSeconds as int?,
      bestReps: identical(bestReps, unset) ? this.bestReps : bestReps as int?,
      assessedOn: identical(assessedOn, unset)
          ? this.assessedOn
          : assessedOn as CivilDate?,
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
    checkLength(
      out,
      '$path.targetExerciseId',
      targetExerciseId.length,
      1,
      null,
    );
    checkLength(
      out,
      '$path.currentExerciseId',
      currentExerciseId.length,
      1,
      null,
    );
    if (bestHoldSeconds case final v?) {
      checkRange(out, '$path.bestHoldSeconds', v, 0, 3600);
    }
    if (bestReps case final v?) {
      checkRange(out, '$path.bestReps', v, 0, 1000);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(targetExerciseId);
    out.add(currentExerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SkillState &&
            targetExerciseId == other.targetExerciseId &&
            currentExerciseId == other.currentExerciseId &&
            bestHoldSeconds == other.bestHoldSeconds &&
            bestReps == other.bestReps &&
            assessedOn == other.assessedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    targetExerciseId,
    currentExerciseId,
    bestHoldSeconds,
    bestReps,
    assessedOn,
  ]);

  @override
  String toString() => 'SkillState(${toJson()})';
}

/// Critère de passage d'une étape de figure (0.4.0). Paramétrable : les
/// valeurs sont un usage d'entraîneur, pas une norme.
///
/// Invariant : Au moins `holdSeconds` ou `reps`.
final class StepCriterion {
  const StepCriterion({
    this.holdSeconds,
    this.reps,
    required this.sets,
    this.minQuality,
    this.sessions,
    this.minWeeks,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory StepCriterion.fromJson(Map<String, Object?> json) {
    return StepCriterion(
      holdSeconds: jsonIntOrNull(json, 'holdSeconds'),
      reps: jsonIntOrNull(json, 'reps'),
      sets: jsonInt(json, 'sets'),
      minQuality: jsonIntOrNull(json, 'minQuality'),
      sessions: jsonIntOrNull(json, 'sessions'),
      minWeeks: jsonIntOrNull(json, 'minWeeks'),
    );
  }

  /// Maintien exigé par série, en secondes.
  final int? holdSeconds;

  /// Répétitions exigées par série.
  final int? reps;

  /// Nombre de séries qui doivent atteindre le critère dans une séance.
  final int sets;

  /// Propreté minimale déclarée (`SetRecord.quality`, de 1 à 5).
  final int? minQuality;

  /// Nombre de séances de suite où le critère doit être tenu.
  final int? sessions;

  /// Durée minimale à cette étape, en semaines (adaptation des tendons).
  final int? minWeeks;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (holdSeconds case final v?) 'holdSeconds': v,
      if (reps case final v?) 'reps': v,
      'sets': sets,
      if (minQuality case final v?) 'minQuality': v,
      if (sessions case final v?) 'sessions': v,
      if (minWeeks case final v?) 'minWeeks': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  StepCriterion copyWith({
    Object? holdSeconds = unset,
    Object? reps = unset,
    int? sets,
    Object? minQuality = unset,
    Object? sessions = unset,
    Object? minWeeks = unset,
  }) {
    return StepCriterion(
      holdSeconds: identical(holdSeconds, unset)
          ? this.holdSeconds
          : holdSeconds as int?,
      reps: identical(reps, unset) ? this.reps : reps as int?,
      sets: sets ?? this.sets,
      minQuality: identical(minQuality, unset)
          ? this.minQuality
          : minQuality as int?,
      sessions: identical(sessions, unset) ? this.sessions : sessions as int?,
      minWeeks: identical(minWeeks, unset) ? this.minWeeks : minWeeks as int?,
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
    if (holdSeconds case final v?) {
      checkRange(out, '$path.holdSeconds', v, 1, 600);
    }
    if (reps case final v?) {
      checkRange(out, '$path.reps', v, 1, 200);
    }
    checkRange(out, '$path.sets', sets, 1, 10);
    if (minQuality case final v?) {
      checkRange(out, '$path.minQuality', v, 1, 5);
    }
    if (sessions case final v?) {
      checkRange(out, '$path.sessions', v, 1, 20);
    }
    if (minWeeks case final v?) {
      checkRange(out, '$path.minWeeks', v, 0, 52);
    }
    _validateStepCriterion(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StepCriterion &&
            holdSeconds == other.holdSeconds &&
            reps == other.reps &&
            sets == other.sets &&
            minQuality == other.minQuality &&
            sessions == other.sessions &&
            minWeeks == other.minWeeks;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    holdSeconds,
    reps,
    sets,
    minQuality,
    sessions,
    minWeeks,
  ]);

  @override
  String toString() => 'StepCriterion(${toJson()})';
}

/// Étape d'une échelle de figure (0.4.0).
final class SkillStep {
  const SkillStep({required this.exerciseId, required this.criterion});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SkillStep.fromJson(Map<String, Object?> json) {
    return SkillStep(
      exerciseId: jsonString(json, 'exerciseId'),
      criterion: jsonObj(json, 'criterion', StepCriterion.fromJson),
    );
  }

  /// Exercice de l'étape.
  final String exerciseId;

  /// Critère pour passer à l'étape suivante (pour la dernière étape : figure
  /// acquise).
  final StepCriterion criterion;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'criterion': criterion.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SkillStep copyWith({String? exerciseId, StepCriterion? criterion}) {
    return SkillStep(
      exerciseId: exerciseId ?? this.exerciseId,
      criterion: criterion ?? this.criterion,
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
    criterion.collectViolations('$path.criterion', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    criterion.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SkillStep &&
            exerciseId == other.exerciseId &&
            criterion == other.criterion;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, criterion]);

  @override
  String toString() => 'SkillStep(${toJson()})';
}

/// Échelle de progression d'une figure (0.4.0), de la plus facile à la figure
/// visée.
///
/// Invariant : Étapes distinctes ; la dernière est la figure visée.
final class SkillLadder {
  const SkillLadder({required this.targetExerciseId, required this.steps});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SkillLadder.fromJson(Map<String, Object?> json) {
    return SkillLadder(
      targetExerciseId: jsonString(json, 'targetExerciseId'),
      steps: jsonList(
        json,
        'steps',
        (v) => SkillStep.fromJson(jsonAsObject(v, 'steps')),
      ),
    );
  }

  /// Figure visée.
  final String targetExerciseId;

  /// Étapes, dans l'ordre de difficulté.
  final List<SkillStep> steps;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetExerciseId': targetExerciseId,
      'steps': [for (final e in steps) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SkillLadder copyWith({String? targetExerciseId, List<SkillStep>? steps}) {
    return SkillLadder(
      targetExerciseId: targetExerciseId ?? this.targetExerciseId,
      steps: steps ?? this.steps,
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
    checkLength(
      out,
      '$path.targetExerciseId',
      targetExerciseId.length,
      1,
      null,
    );
    checkLength(out, '$path.steps', steps.length, 1, 20);
    for (var i = 0; i < steps.length; i++) {
      steps[i].collectViolations('$path.steps[$i]', out);
    }
    _validateSkillLadder(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(targetExerciseId);
    for (final e in steps) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SkillLadder &&
            targetExerciseId == other.targetExerciseId &&
            jsonListEquals(steps, other.steps);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[targetExerciseId, Object.hashAll(steps)]);

  @override
  String toString() => 'SkillLadder(${toJson()})';
}

/// Suivi d'une figure par le moteur dynamique (0.4.0).
final class SkillProgress {
  const SkillProgress({
    required this.targetExerciseId,
    required this.currentExerciseId,
    required this.stepIndex,
    required this.weeksAtStep,
    required this.criterionMet,
    this.bestHoldSeconds,
    this.bestReps,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SkillProgress.fromJson(Map<String, Object?> json) {
    return SkillProgress(
      targetExerciseId: jsonString(json, 'targetExerciseId'),
      currentExerciseId: jsonString(json, 'currentExerciseId'),
      stepIndex: jsonInt(json, 'stepIndex'),
      weeksAtStep: jsonInt(json, 'weeksAtStep'),
      criterionMet: jsonBool(json, 'criterionMet'),
      bestHoldSeconds: jsonIntOrNull(json, 'bestHoldSeconds'),
      bestReps: jsonIntOrNull(json, 'bestReps'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Figure visée.
  final String targetExerciseId;

  /// Étape actuelle.
  final String currentExerciseId;

  /// Rang de l'étape actuelle dans l'échelle (0 = première).
  final int stepIndex;

  /// Semaines passées à cette étape.
  final int weeksAtStep;

  /// Le critère de passage est tenu.
  final bool criterionMet;

  /// Meilleur maintien propre sur l'étape, en secondes.
  final int? bestHoldSeconds;

  /// Meilleur nombre de répétitions propres sur l'étape.
  final int? bestReps;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetExerciseId': targetExerciseId,
      'currentExerciseId': currentExerciseId,
      'stepIndex': stepIndex,
      'weeksAtStep': weeksAtStep,
      'criterionMet': criterionMet,
      if (bestHoldSeconds case final v?) 'bestHoldSeconds': v,
      if (bestReps case final v?) 'bestReps': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SkillProgress copyWith({
    String? targetExerciseId,
    String? currentExerciseId,
    int? stepIndex,
    int? weeksAtStep,
    bool? criterionMet,
    Object? bestHoldSeconds = unset,
    Object? bestReps = unset,
    List<Reason>? reasons,
  }) {
    return SkillProgress(
      targetExerciseId: targetExerciseId ?? this.targetExerciseId,
      currentExerciseId: currentExerciseId ?? this.currentExerciseId,
      stepIndex: stepIndex ?? this.stepIndex,
      weeksAtStep: weeksAtStep ?? this.weeksAtStep,
      criterionMet: criterionMet ?? this.criterionMet,
      bestHoldSeconds: identical(bestHoldSeconds, unset)
          ? this.bestHoldSeconds
          : bestHoldSeconds as int?,
      bestReps: identical(bestReps, unset) ? this.bestReps : bestReps as int?,
      reasons: reasons ?? this.reasons,
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
    checkLength(
      out,
      '$path.targetExerciseId',
      targetExerciseId.length,
      1,
      null,
    );
    checkLength(
      out,
      '$path.currentExerciseId',
      currentExerciseId.length,
      1,
      null,
    );
    checkRange(out, '$path.stepIndex', stepIndex, 0, null);
    checkRange(out, '$path.weeksAtStep', weeksAtStep, 0, null);
    if (bestHoldSeconds case final v?) {
      checkRange(out, '$path.bestHoldSeconds', v, 0, 3600);
    }
    if (bestReps case final v?) {
      checkRange(out, '$path.bestReps', v, 0, 1000);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(targetExerciseId);
    out.add(currentExerciseId);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SkillProgress &&
            targetExerciseId == other.targetExerciseId &&
            currentExerciseId == other.currentExerciseId &&
            stepIndex == other.stepIndex &&
            weeksAtStep == other.weeksAtStep &&
            criterionMet == other.criterionMet &&
            bestHoldSeconds == other.bestHoldSeconds &&
            bestReps == other.bestReps &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    targetExerciseId,
    currentExerciseId,
    stepIndex,
    weeksAtStep,
    criterionMet,
    bestHoldSeconds,
    bestReps,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'SkillProgress(${toJson()})';
}

/// Phase d'un plan de saison (0.4.0).
final class SeasonPhase {
  const SeasonPhase({
    required this.index,
    required this.kind,
    required this.startDate,
    required this.weeks,
    this.eventId,
    this.volumeFactor,
    this.intensityFactor,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SeasonPhase.fromJson(Map<String, Object?> json) {
    return SeasonPhase(
      index: jsonInt(json, 'index'),
      kind: jsonEnum(json, 'kind', PhaseKind.fromCode),
      startDate: jsonDate(json, 'startDate'),
      weeks: jsonInt(json, 'weeks'),
      eventId: jsonStringOrNull(json, 'eventId'),
      volumeFactor: jsonDoubleOrNull(json, 'volumeFactor'),
      intensityFactor: jsonDoubleOrNull(json, 'intensityFactor'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Rang de la phase (0 = première).
  final int index;

  /// Nature.
  final PhaseKind kind;

  /// Premier jour de la phase.
  final CivilDate startDate;

  /// Durée, en semaines.
  final int weeks;

  /// Échéance que prépare la phase.
  final String? eventId;

  /// Volume visé, rapporté au volume de pointe de la saison (1 = pointe).
  final double? volumeFactor;

  /// Intensité moyenne visée, rapportée à celle de la phase la plus intense (1
  /// = pointe).
  final double? intensityFactor;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'index': index,
      'kind': kind.code,
      'startDate': startDate.iso,
      'weeks': weeks,
      if (eventId case final v?) 'eventId': v,
      if (volumeFactor case final v?) 'volumeFactor': v,
      if (intensityFactor case final v?) 'intensityFactor': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SeasonPhase copyWith({
    int? index,
    PhaseKind? kind,
    CivilDate? startDate,
    int? weeks,
    Object? eventId = unset,
    Object? volumeFactor = unset,
    Object? intensityFactor = unset,
    List<Reason>? reasons,
  }) {
    return SeasonPhase(
      index: index ?? this.index,
      kind: kind ?? this.kind,
      startDate: startDate ?? this.startDate,
      weeks: weeks ?? this.weeks,
      eventId: identical(eventId, unset) ? this.eventId : eventId as String?,
      volumeFactor: identical(volumeFactor, unset)
          ? this.volumeFactor
          : volumeFactor as double?,
      intensityFactor: identical(intensityFactor, unset)
          ? this.intensityFactor
          : intensityFactor as double?,
      reasons: reasons ?? this.reasons,
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
    checkRange(out, '$path.index', index, 0, null);
    checkRange(out, '$path.weeks', weeks, 1, 26);
    if (volumeFactor case final v?) {
      checkRange(out, '$path.volumeFactor', v, 0, 2);
    }
    if (intensityFactor case final v?) {
      checkRange(out, '$path.intensityFactor', v, 0, 2);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SeasonPhase &&
            index == other.index &&
            kind == other.kind &&
            startDate == other.startDate &&
            weeks == other.weeks &&
            eventId == other.eventId &&
            volumeFactor == other.volumeFactor &&
            intensityFactor == other.intensityFactor &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    index,
    kind,
    startDate,
    weeks,
    eventId,
    volumeFactor,
    intensityFactor,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'SeasonPhase(${toJson()})';
}

/// Plan de saison (0.4.0) : squelette de phases au-dessus des blocs de 4 à 6
/// semaines (D4.8 inchangé : les blocs restent générés au fil de l'eau).
///
/// Invariant : `index` = rang dans `phases` ; les phases se suivent sans trou
/// ni chevauchement (chacune commence 7 × `weeks` jours après la précédente).
final class SeasonPlan {
  const SeasonPlan({
    this.schemaVersion = currentSchemaVersion,
    required this.createdOn,
    required this.engineVersion,
    required this.eventIds,
    required this.phases,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SeasonPlan.fromJson(Map<String, Object?> json) {
    return SeasonPlan(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      createdOn: jsonDate(json, 'createdOn'),
      engineVersion: jsonString(json, 'engineVersion'),
      eventIds: jsonList(json, 'eventIds', (v) => jsonAsString(v, 'eventIds')),
      phases: jsonList(
        json,
        'phases',
        (v) => SeasonPhase.fromJson(jsonAsObject(v, 'phases')),
      ),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Jour de création ou de dernière révision.
  final CivilDate createdOn;

  /// Version de kalis_plan.
  final String engineVersion;

  /// Échéances du profil prises en compte (`SeasonEvent.id`).
  final List<String> eventIds;

  /// Phases, dans l'ordre.
  final List<SeasonPhase> phases;

  /// Logique de la saison.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'createdOn': createdOn.iso,
      'engineVersion': engineVersion,
      'eventIds': [for (final e in eventIds) e],
      'phases': [for (final e in phases) e.toJson()],
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SeasonPlan copyWith({
    int? schemaVersion,
    CivilDate? createdOn,
    String? engineVersion,
    List<String>? eventIds,
    List<SeasonPhase>? phases,
    List<Reason>? reasons,
  }) {
    return SeasonPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdOn: createdOn ?? this.createdOn,
      engineVersion: engineVersion ?? this.engineVersion,
      eventIds: eventIds ?? this.eventIds,
      phases: phases ?? this.phases,
      reasons: reasons ?? this.reasons,
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
    for (var i = 0; i < eventIds.length; i++) {
      checkLength(out, '$path.eventIds[$i]', eventIds[i].length, 1, null);
    }
    checkLength(out, '$path.phases', phases.length, 1, 60);
    for (var i = 0; i < phases.length; i++) {
      phases[i].collectViolations('$path.phases[$i]', out);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    _validateSeasonPlan(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in phases) {
      e.collectExerciseIds(out);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SeasonPlan &&
            schemaVersion == other.schemaVersion &&
            createdOn == other.createdOn &&
            engineVersion == other.engineVersion &&
            jsonListEquals(eventIds, other.eventIds) &&
            jsonListEquals(phases, other.phases) &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    createdOn,
    engineVersion,
    Object.hashAll(eventIds),
    Object.hashAll(phases),
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'SeasonPlan(${toJson()})';
}

/// Intention d'un bloc (0.4.0) : sa place dans la saison.
final class BlockIntent {
  const BlockIntent({
    required this.phase,
    this.seasonPhaseIndex,
    this.eventId,
    this.weeksToEvent,
    this.undulation,
    this.specialization,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory BlockIntent.fromJson(Map<String, Object?> json) {
    return BlockIntent(
      phase: jsonEnum(json, 'phase', PhaseKind.fromCode),
      seasonPhaseIndex: jsonIntOrNull(json, 'seasonPhaseIndex'),
      eventId: jsonStringOrNull(json, 'eventId'),
      weeksToEvent: jsonIntOrNull(json, 'weeksToEvent'),
      undulation: jsonEnumOrNull(json, 'undulation', UndulationModel.fromCode),
      specialization: jsonObjOrNull(
        json,
        'specialization',
        Specialization.fromJson,
      ),
    );
  }

  /// Phase que réalise le bloc.
  final PhaseKind phase;

  /// Rang de la phase dans le plan de saison.
  final int? seasonPhaseIndex;

  /// Échéance préparée.
  final String? eventId;

  /// Semaines entre le début du bloc et l'échéance.
  final int? weeksToEvent;

  /// Modèle d'ondulation du bloc.
  final UndulationModel? undulation;

  /// Spécialisation servie par le bloc.
  final Specialization? specialization;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'phase': phase.code,
      if (seasonPhaseIndex case final v?) 'seasonPhaseIndex': v,
      if (eventId case final v?) 'eventId': v,
      if (weeksToEvent case final v?) 'weeksToEvent': v,
      if (undulation case final v?) 'undulation': v.code,
      if (specialization case final v?) 'specialization': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  BlockIntent copyWith({
    PhaseKind? phase,
    Object? seasonPhaseIndex = unset,
    Object? eventId = unset,
    Object? weeksToEvent = unset,
    Object? undulation = unset,
    Object? specialization = unset,
  }) {
    return BlockIntent(
      phase: phase ?? this.phase,
      seasonPhaseIndex: identical(seasonPhaseIndex, unset)
          ? this.seasonPhaseIndex
          : seasonPhaseIndex as int?,
      eventId: identical(eventId, unset) ? this.eventId : eventId as String?,
      weeksToEvent: identical(weeksToEvent, unset)
          ? this.weeksToEvent
          : weeksToEvent as int?,
      undulation: identical(undulation, unset)
          ? this.undulation
          : undulation as UndulationModel?,
      specialization: identical(specialization, unset)
          ? this.specialization
          : specialization as Specialization?,
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
    if (seasonPhaseIndex case final v?) {
      checkRange(out, '$path.seasonPhaseIndex', v, 0, null);
    }
    if (weeksToEvent case final v?) {
      checkRange(out, '$path.weeksToEvent', v, 0, 104);
    }
    if (specialization case final v?) {
      v.collectViolations('$path.specialization', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    specialization?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BlockIntent &&
            phase == other.phase &&
            seasonPhaseIndex == other.seasonPhaseIndex &&
            eventId == other.eventId &&
            weeksToEvent == other.weeksToEvent &&
            undulation == other.undulation &&
            specialization == other.specialization;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    phase,
    seasonPhaseIndex,
    eventId,
    weeksToEvent,
    undulation,
    specialization,
  ]);

  @override
  String toString() => 'BlockIntent(${toJson()})';
}

/// Volume hebdomadaire toléré par un groupe musculaire, appris par le moteur
/// dynamique (0.4.0).
///
/// Invariant : `weeklySetsLow` ≤ `weeklySetsHigh`.
final class VolumeTolerance {
  const VolumeTolerance({
    required this.muscle,
    required this.weeklySetsLow,
    required this.weeklySetsHigh,
    required this.confidence,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory VolumeTolerance.fromJson(Map<String, Object?> json) {
    return VolumeTolerance(
      muscle: jsonString(json, 'muscle'),
      weeklySetsLow: jsonDouble(json, 'weeklySetsLow'),
      weeklySetsHigh: jsonDouble(json, 'weeklySetsHigh'),
      confidence: jsonDouble(json, 'confidence'),
    );
  }

  /// Groupe musculaire (vocabulaire de `kalis_plan`).
  final String muscle;

  /// Bas de la plage de séries hebdomadaires bien tolérées.
  final double weeklySetsLow;

  /// Haut de la plage.
  final double weeklySetsHigh;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'muscle': muscle,
      'weeklySetsLow': weeklySetsLow,
      'weeklySetsHigh': weeklySetsHigh,
      'confidence': confidence,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  VolumeTolerance copyWith({
    String? muscle,
    double? weeklySetsLow,
    double? weeklySetsHigh,
    double? confidence,
  }) {
    return VolumeTolerance(
      muscle: muscle ?? this.muscle,
      weeklySetsLow: weeklySetsLow ?? this.weeklySetsLow,
      weeklySetsHigh: weeklySetsHigh ?? this.weeklySetsHigh,
      confidence: confidence ?? this.confidence,
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
    checkLength(out, '$path.muscle', muscle.length, 1, null);
    checkRange(out, '$path.weeklySetsLow', weeklySetsLow, 0, 80);
    checkRange(out, '$path.weeklySetsHigh', weeklySetsHigh, 0, 80);
    checkRange(out, '$path.confidence', confidence, 0, 1);
    _validateVolumeTolerance(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VolumeTolerance &&
            muscle == other.muscle &&
            weeklySetsLow == other.weeklySetsLow &&
            weeklySetsHigh == other.weeklySetsHigh &&
            confidence == other.confidence;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    muscle,
    weeklySetsLow,
    weeklySetsHigh,
    confidence,
  ]);

  @override
  String toString() => 'VolumeTolerance(${toJson()})';
}

/// Tentative déjà faite le jour d'une compétition (0.4.0).
final class AttemptResult {
  const AttemptResult({
    required this.exerciseId,
    required this.index,
    required this.loadKg,
    required this.success,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AttemptResult.fromJson(Map<String, Object?> json) {
    return AttemptResult(
      exerciseId: jsonString(json, 'exerciseId'),
      index: jsonInt(json, 'index'),
      loadKg: jsonDouble(json, 'loadKg'),
      success: jsonBool(json, 'success'),
    );
  }

  /// Mouvement.
  final String exerciseId;

  /// Rang de la tentative (0 = ouverture).
  final int index;

  /// Charge externe tentée, en kg.
  final double loadKg;

  /// Tentative validée.
  final bool success;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'index': index,
      'loadKg': loadKg,
      'success': success,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AttemptResult copyWith({
    String? exerciseId,
    int? index,
    double? loadKg,
    bool? success,
  }) {
    return AttemptResult(
      exerciseId: exerciseId ?? this.exerciseId,
      index: index ?? this.index,
      loadKg: loadKg ?? this.loadKg,
      success: success ?? this.success,
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
    checkRange(out, '$path.index', index, 0, 3);
    checkRange(out, '$path.loadKg', loadKg, -300, 1000);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttemptResult &&
            exerciseId == other.exerciseId &&
            index == other.index &&
            loadKg == other.loadKg &&
            success == other.success;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[exerciseId, index, loadKg, success]);

  @override
  String toString() => 'AttemptResult(${toJson()})';
}

/// Tentative proposée (0.4.0).
final class AttemptSuggestion {
  const AttemptSuggestion({
    required this.index,
    required this.loadKg,
    this.successProbability,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AttemptSuggestion.fromJson(Map<String, Object?> json) {
    return AttemptSuggestion(
      index: jsonInt(json, 'index'),
      loadKg: jsonDouble(json, 'loadKg'),
      successProbability: jsonDoubleOrNull(json, 'successProbability'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Rang de la tentative (0 = ouverture).
  final int index;

  /// Charge externe proposée, en kg.
  final double loadKg;

  /// Probabilité de réussite estimée, de 0 à 1.
  final double? successProbability;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'index': index,
      'loadKg': loadKg,
      if (successProbability case final v?) 'successProbability': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AttemptSuggestion copyWith({
    int? index,
    double? loadKg,
    Object? successProbability = unset,
    List<Reason>? reasons,
  }) {
    return AttemptSuggestion(
      index: index ?? this.index,
      loadKg: loadKg ?? this.loadKg,
      successProbability: identical(successProbability, unset)
          ? this.successProbability
          : successProbability as double?,
      reasons: reasons ?? this.reasons,
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
    checkRange(out, '$path.index', index, 0, 3);
    checkRange(out, '$path.loadKg', loadKg, -300, 1000);
    if (successProbability case final v?) {
      checkRange(out, '$path.successProbability', v, 0, 1);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttemptSuggestion &&
            index == other.index &&
            loadKg == other.loadKg &&
            successProbability == other.successProbability &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    index,
    loadKg,
    successProbability,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'AttemptSuggestion(${toJson()})';
}

/// Tentatives proposées pour un mouvement (0.4.0).
///
/// Invariant : Charges proposées croissantes au sens large (une charge ne
/// baisse jamais).
final class LiftAttempts {
  const LiftAttempts({
    required this.exerciseId,
    this.estimateKg,
    this.standardErrorKg,
    required this.attempts,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory LiftAttempts.fromJson(Map<String, Object?> json) {
    return LiftAttempts(
      exerciseId: jsonString(json, 'exerciseId'),
      estimateKg: jsonDoubleOrNull(json, 'estimateKg'),
      standardErrorKg: jsonDoubleOrNull(json, 'standardErrorKg'),
      attempts: jsonList(
        json,
        'attempts',
        (v) => AttemptSuggestion.fromJson(jsonAsObject(v, 'attempts')),
      ),
    );
  }

  /// Mouvement.
  final String exerciseId;

  /// Maximum du jour estimé, en kg de charge externe.
  final double? estimateKg;

  /// Écart-type de cette estimation, en kg.
  final double? standardErrorKg;

  /// Tentatives restantes, dans l'ordre.
  final List<AttemptSuggestion> attempts;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      if (estimateKg case final v?) 'estimateKg': v,
      if (standardErrorKg case final v?) 'standardErrorKg': v,
      'attempts': [for (final e in attempts) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  LiftAttempts copyWith({
    String? exerciseId,
    Object? estimateKg = unset,
    Object? standardErrorKg = unset,
    List<AttemptSuggestion>? attempts,
  }) {
    return LiftAttempts(
      exerciseId: exerciseId ?? this.exerciseId,
      estimateKg: identical(estimateKg, unset)
          ? this.estimateKg
          : estimateKg as double?,
      standardErrorKg: identical(standardErrorKg, unset)
          ? this.standardErrorKg
          : standardErrorKg as double?,
      attempts: attempts ?? this.attempts,
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
    if (estimateKg case final v?) {
      checkRange(out, '$path.estimateKg', v, -300, 1000);
    }
    if (standardErrorKg case final v?) {
      checkRange(out, '$path.standardErrorKg', v, 0, null);
    }
    checkLength(out, '$path.attempts', attempts.length, null, 4);
    for (var i = 0; i < attempts.length; i++) {
      attempts[i].collectViolations('$path.attempts[$i]', out);
    }
    _validateLiftAttempts(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in attempts) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LiftAttempts &&
            exerciseId == other.exerciseId &&
            estimateKg == other.estimateKg &&
            standardErrorKg == other.standardErrorKg &&
            jsonListEquals(attempts, other.attempts);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    estimateKg,
    standardErrorKg,
    Object.hashAll(attempts),
  ]);

  @override
  String toString() => 'LiftAttempts(${toJson()})';
}

/// Stratégie de rythme sur un poste d'une épreuve de répétitions (0.4.0).
final class PacingSegment {
  const PacingSegment({
    required this.exerciseId,
    required this.setReps,
    this.restSeconds,
    this.targetSeconds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PacingSegment.fromJson(Map<String, Object?> json) {
    return PacingSegment(
      exerciseId: jsonString(json, 'exerciseId'),
      setReps: jsonList(json, 'setReps', (v) => jsonAsInt(v, 'setReps')),
      restSeconds: jsonIntOrNull(json, 'restSeconds'),
      targetSeconds: jsonIntOrNull(json, 'targetSeconds'),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Répétitions prévues par série, dans l'ordre.
  final List<int> setReps;

  /// Repos prévu entre les séries, en secondes.
  final int? restSeconds;

  /// Temps visé sur ce poste, en secondes.
  final int? targetSeconds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'setReps': [for (final e in setReps) e],
      if (restSeconds case final v?) 'restSeconds': v,
      if (targetSeconds case final v?) 'targetSeconds': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PacingSegment copyWith({
    String? exerciseId,
    List<int>? setReps,
    Object? restSeconds = unset,
    Object? targetSeconds = unset,
  }) {
    return PacingSegment(
      exerciseId: exerciseId ?? this.exerciseId,
      setReps: setReps ?? this.setReps,
      restSeconds: identical(restSeconds, unset)
          ? this.restSeconds
          : restSeconds as int?,
      targetSeconds: identical(targetSeconds, unset)
          ? this.targetSeconds
          : targetSeconds as int?,
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
    checkLength(out, '$path.setReps', setReps.length, null, 60);
    if (restSeconds case final v?) {
      checkRange(out, '$path.restSeconds', v, 0, 900);
    }
    if (targetSeconds case final v?) {
      checkRange(out, '$path.targetSeconds', v, 1, 14400);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PacingSegment &&
            exerciseId == other.exerciseId &&
            jsonListEquals(setReps, other.setReps) &&
            restSeconds == other.restSeconds &&
            targetSeconds == other.targetSeconds;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    Object.hashAll(setReps),
    restSeconds,
    targetSeconds,
  ]);

  @override
  String toString() => 'PacingSegment(${toJson()})';
}

/// Requête du jour d'une échéance (0.4.0).
final class EventDayRequest {
  const EventDayRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.input,
    required this.eventId,
    this.bodyWeightKg,
    required this.done,
    this.healthCheck,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory EventDayRequest.fromJson(Map<String, Object?> json) {
    return EventDayRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      input: jsonObj(json, 'input', AdaptInput.fromJson),
      eventId: jsonString(json, 'eventId'),
      bodyWeightKg: jsonDoubleOrNull(json, 'bodyWeightKg'),
      done: jsonList(
        json,
        'done',
        (v) => AttemptResult.fromJson(jsonAsObject(v, 'done')),
      ),
      healthCheck: jsonObjOrNull(json, 'healthCheck', HealthCheck.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Profil, bloc, journal, « aujourd'hui », état.
  final AdaptInput input;

  /// Échéance du profil (`SeasonEvent.id`).
  final String eventId;

  /// Poids de corps du jour (pesée), en kg.
  final double? bodyWeightKg;

  /// Tentatives déjà faites, dans l'ordre.
  final List<AttemptResult> done;

  /// Bilan santé du jour (une réponse absente n'est jamais remplacée).
  final HealthCheck? healthCheck;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'input': input.toJson(),
      'eventId': eventId,
      if (bodyWeightKg case final v?) 'bodyWeightKg': v,
      'done': [for (final e in done) e.toJson()],
      if (healthCheck case final v?) 'healthCheck': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  EventDayRequest copyWith({
    int? schemaVersion,
    AdaptInput? input,
    String? eventId,
    Object? bodyWeightKg = unset,
    List<AttemptResult>? done,
    Object? healthCheck = unset,
  }) {
    return EventDayRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      input: input ?? this.input,
      eventId: eventId ?? this.eventId,
      bodyWeightKg: identical(bodyWeightKg, unset)
          ? this.bodyWeightKg
          : bodyWeightKg as double?,
      done: done ?? this.done,
      healthCheck: identical(healthCheck, unset)
          ? this.healthCheck
          : healthCheck as HealthCheck?,
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
    input.collectViolations('$path.input', out);
    checkLength(out, '$path.eventId', eventId.length, 1, null);
    if (bodyWeightKg case final v?) {
      checkRange(out, '$path.bodyWeightKg', v, 25, 300);
    }
    for (var i = 0; i < done.length; i++) {
      done[i].collectViolations('$path.done[$i]', out);
    }
    if (healthCheck case final v?) {
      v.collectViolations('$path.healthCheck', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    input.collectExerciseIds(out);
    for (final e in done) {
      e.collectExerciseIds(out);
    }
    healthCheck?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EventDayRequest &&
            schemaVersion == other.schemaVersion &&
            input == other.input &&
            eventId == other.eventId &&
            bodyWeightKg == other.bodyWeightKg &&
            jsonListEquals(done, other.done) &&
            healthCheck == other.healthCheck;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    input,
    eventId,
    bodyWeightKg,
    Object.hashAll(done),
    healthCheck,
  ]);

  @override
  String toString() => 'EventDayRequest(${toJson()})';
}

/// Plan du jour d'une échéance (0.4.0) : tentatives d'une compétition de
/// force, ou objectif et rythme d'une épreuve de répétitions.
final class EventDayPlan {
  const EventDayPlan({
    this.schemaVersion = currentSchemaVersion,
    required this.eventId,
    required this.lifts,
    this.pacing,
    this.targetTotalReps,
    this.targetSeconds,
    required this.confidence,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory EventDayPlan.fromJson(Map<String, Object?> json) {
    return EventDayPlan(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      eventId: jsonString(json, 'eventId'),
      lifts: jsonList(
        json,
        'lifts',
        (v) => LiftAttempts.fromJson(jsonAsObject(v, 'lifts')),
      ),
      pacing: jsonListOrNull(
        json,
        'pacing',
        (v) => PacingSegment.fromJson(jsonAsObject(v, 'pacing')),
      ),
      targetTotalReps: jsonIntOrNull(json, 'targetTotalReps'),
      targetSeconds: jsonIntOrNull(json, 'targetSeconds'),
      confidence: jsonDouble(json, 'confidence'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Échéance.
  final String eventId;

  /// Tentatives par mouvement (compétition de force).
  final List<LiftAttempts> lifts;

  /// Rythme par poste (épreuve de répétitions).
  final List<PacingSegment>? pacing;

  /// Objectif de répétitions totales.
  final int? targetTotalReps;

  /// Objectif de temps, en secondes.
  final int? targetSeconds;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'eventId': eventId,
      'lifts': [for (final e in lifts) e.toJson()],
      if (pacing case final v?) 'pacing': [for (final e in v) e.toJson()],
      if (targetTotalReps case final v?) 'targetTotalReps': v,
      if (targetSeconds case final v?) 'targetSeconds': v,
      'confidence': confidence,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  EventDayPlan copyWith({
    int? schemaVersion,
    String? eventId,
    List<LiftAttempts>? lifts,
    Object? pacing = unset,
    Object? targetTotalReps = unset,
    Object? targetSeconds = unset,
    double? confidence,
    List<Reason>? reasons,
  }) {
    return EventDayPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      eventId: eventId ?? this.eventId,
      lifts: lifts ?? this.lifts,
      pacing: identical(pacing, unset)
          ? this.pacing
          : pacing as List<PacingSegment>?,
      targetTotalReps: identical(targetTotalReps, unset)
          ? this.targetTotalReps
          : targetTotalReps as int?,
      targetSeconds: identical(targetSeconds, unset)
          ? this.targetSeconds
          : targetSeconds as int?,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
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
    checkLength(out, '$path.eventId', eventId.length, 1, null);
    for (var i = 0; i < lifts.length; i++) {
      lifts[i].collectViolations('$path.lifts[$i]', out);
    }
    if (pacing case final v?) {
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.pacing[$i]', out);
      }
    }
    if (targetTotalReps case final v?) {
      checkRange(out, '$path.targetTotalReps', v, 0, 100000);
    }
    if (targetSeconds case final v?) {
      checkRange(out, '$path.targetSeconds', v, 1, 86400);
    }
    checkRange(out, '$path.confidence', confidence, 0, 1);
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in lifts) {
      e.collectExerciseIds(out);
    }
    for (final e in pacing ?? const <PacingSegment>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EventDayPlan &&
            schemaVersion == other.schemaVersion &&
            eventId == other.eventId &&
            jsonListEquals(lifts, other.lifts) &&
            jsonDeepEquals(pacing, other.pacing) &&
            targetTotalReps == other.targetTotalReps &&
            targetSeconds == other.targetSeconds &&
            confidence == other.confidence &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    eventId,
    Object.hashAll(lifts),
    jsonDeepHash(pacing),
    targetTotalReps,
    targetSeconds,
    confidence,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'EventDayPlan(${toJson()})';
}

/// Requête de plan de saison (0.4.0) : les échéances sont celles du profil
/// (`AthleteProfile.events`).
final class SeasonRequest {
  const SeasonRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.seed,
    required this.today,
    required this.startDate,
    this.previous,
    this.currentBlock,
    this.adaptation,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SeasonRequest.fromJson(Map<String, Object?> json) {
    return SeasonRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      seed: jsonInt(json, 'seed'),
      today: jsonDate(json, 'today'),
      startDate: jsonDate(json, 'startDate'),
      previous: jsonObjOrNull(json, 'previous', SeasonPlan.fromJson),
      currentBlock: jsonObjOrNull(json, 'currentBlock', ProgramBlock.fromJson),
      adaptation: jsonObjOrNull(json, 'adaptation', AdaptationSummary.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Profil.
  final AthleteProfile profile;

  /// Graine.
  final int seed;

  /// « Aujourd'hui ».
  final CivilDate today;

  /// Premier jour à planifier.
  final CivilDate startDate;

  /// Plan de saison en cours, à réviser.
  final SeasonPlan? previous;

  /// Bloc en cours.
  final ProgramBlock? currentBlock;

  /// Résumé d'adaptation.
  final AdaptationSummary? adaptation;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'seed': seed,
      'today': today.iso,
      'startDate': startDate.iso,
      if (previous case final v?) 'previous': v.toJson(),
      if (currentBlock case final v?) 'currentBlock': v.toJson(),
      if (adaptation case final v?) 'adaptation': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SeasonRequest copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    int? seed,
    CivilDate? today,
    CivilDate? startDate,
    Object? previous = unset,
    Object? currentBlock = unset,
    Object? adaptation = unset,
  }) {
    return SeasonRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      seed: seed ?? this.seed,
      today: today ?? this.today,
      startDate: startDate ?? this.startDate,
      previous: identical(previous, unset)
          ? this.previous
          : previous as SeasonPlan?,
      currentBlock: identical(currentBlock, unset)
          ? this.currentBlock
          : currentBlock as ProgramBlock?,
      adaptation: identical(adaptation, unset)
          ? this.adaptation
          : adaptation as AdaptationSummary?,
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
    profile.collectViolations('$path.profile', out);
    checkRange(out, '$path.seed', seed, 0, null);
    if (previous case final v?) {
      v.collectViolations('$path.previous', out);
    }
    if (currentBlock case final v?) {
      v.collectViolations('$path.currentBlock', out);
    }
    if (adaptation case final v?) {
      v.collectViolations('$path.adaptation', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    previous?.collectExerciseIds(out);
    currentBlock?.collectExerciseIds(out);
    adaptation?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SeasonRequest &&
            schemaVersion == other.schemaVersion &&
            profile == other.profile &&
            seed == other.seed &&
            today == other.today &&
            startDate == other.startDate &&
            previous == other.previous &&
            currentBlock == other.currentBlock &&
            adaptation == other.adaptation;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    profile,
    seed,
    today,
    startDate,
    previous,
    currentBlock,
    adaptation,
  ]);

  @override
  String toString() => 'SeasonRequest(${toJson()})';
}
