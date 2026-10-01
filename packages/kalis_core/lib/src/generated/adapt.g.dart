// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Capacité estimée sur un exercice (D5.2).
final class ExerciseEstimate {
  const ExerciseEstimate({
    required this.exerciseId,
    required this.unit,
    required this.capacity,
    required this.standardError,
    required this.weeklyTrend,
    required this.observations,
    this.lastObservedOn,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ExerciseEstimate.fromJson(Map<String, Object?> json) {
    return ExerciseEstimate(
      exerciseId: jsonString(json, 'exerciseId'),
      unit: jsonEnum(json, 'unit', CapacityUnit.fromCode),
      capacity: jsonDouble(json, 'capacity'),
      standardError: jsonDouble(json, 'standardError'),
      weeklyTrend: jsonDouble(json, 'weeklyTrend'),
      observations: jsonInt(json, 'observations'),
      lastObservedOn: jsonDateOrNull(json, 'lastObservedOn'),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Unité de la capacité.
  final CapacityUnit unit;

  /// Capacité estimée (1RM de charge totale en kg, répétitions max ou tenue
  /// max).
  final double capacity;

  /// Écart-type de l'estimation, même unité.
  final double standardError;

  /// Tendance par semaine, même unité.
  final double weeklyTrend;

  /// Nombre de séries utilisées.
  final int observations;

  /// Dernière séance observée.
  final CivilDate? lastObservedOn;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'unit': unit.code,
      'capacity': capacity,
      'standardError': standardError,
      'weeklyTrend': weeklyTrend,
      'observations': observations,
      if (lastObservedOn case final v?) 'lastObservedOn': v.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ExerciseEstimate copyWith({
    String? exerciseId,
    CapacityUnit? unit,
    double? capacity,
    double? standardError,
    double? weeklyTrend,
    int? observations,
    Object? lastObservedOn = unset,
  }) {
    return ExerciseEstimate(
      exerciseId: exerciseId ?? this.exerciseId,
      unit: unit ?? this.unit,
      capacity: capacity ?? this.capacity,
      standardError: standardError ?? this.standardError,
      weeklyTrend: weeklyTrend ?? this.weeklyTrend,
      observations: observations ?? this.observations,
      lastObservedOn: identical(lastObservedOn, unset) ? this.lastObservedOn : lastObservedOn as CivilDate?,
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
    checkRange(out, '$path.capacity', capacity, 0, null);
    checkRange(out, '$path.standardError', standardError, 0, null);
    checkRange(out, '$path.weeklyTrend', weeklyTrend, null, null);
    checkRange(out, '$path.observations', observations, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ExerciseEstimate && exerciseId == other.exerciseId && unit == other.unit && capacity == other.capacity && standardError == other.standardError && weeklyTrend == other.weeklyTrend && observations == other.observations && lastObservedOn == other.lastObservedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, unit, capacity, standardError, weeklyTrend, observations, lastObservedOn]);

  @override
  String toString() => 'ExerciseEstimate(${toJson()})';
}

/// État du modèle forme / fatigue.
final class FatigueState {
  const FatigueState({
    required this.fitness,
    required this.fatigue,
    required this.readiness,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory FatigueState.fromJson(Map<String, Object?> json) {
    return FatigueState(
      fitness: jsonDouble(json, 'fitness'),
      fatigue: jsonDouble(json, 'fatigue'),
      readiness: jsonDouble(json, 'readiness'),
    );
  }

  /// Forme (unités arbitraires du modèle).
  final double fitness;

  /// Fatigue (unités arbitraires du modèle).
  final double fatigue;

  /// Forme du jour, de 0 à 1.
  final double readiness;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fitness': fitness,
      'fatigue': fatigue,
      'readiness': readiness,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  FatigueState copyWith({
    double? fitness,
    double? fatigue,
    double? readiness,
  }) {
    return FatigueState(
      fitness: fitness ?? this.fitness,
      fatigue: fatigue ?? this.fatigue,
      readiness: readiness ?? this.readiness,
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
    checkRange(out, '$path.fitness', fitness, 0, null);
    checkRange(out, '$path.fatigue', fatigue, 0, null);
    checkRange(out, '$path.readiness', readiness, 0, 1);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is FatigueState && fitness == other.fitness && fatigue == other.fatigue && readiness == other.readiness;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[fitness, fatigue, readiness]);

  @override
  String toString() => 'FatigueState(${toJson()})';
}

/// Suivi d'une zone douloureuse.
final class PainTrend {
  const PainTrend({
    required this.zone,
    required this.side,
    required this.sessionsReported,
    required this.lastIntensity,
    required this.consecutiveAboveThreshold,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PainTrend.fromJson(Map<String, Object?> json) {
    return PainTrend(
      zone: jsonEnum(json, 'zone', BodyZone.fromCode),
      side: jsonEnum(json, 'side', BodySide.fromCode),
      sessionsReported: jsonInt(json, 'sessionsReported'),
      lastIntensity: jsonInt(json, 'lastIntensity'),
      consecutiveAboveThreshold: jsonInt(json, 'consecutiveAboveThreshold'),
    );
  }

  /// Zone.
  final BodyZone zone;

  /// Côté.
  final BodySide side;

  /// Séances où elle a été signalée.
  final int sessionsReported;

  /// Dernière intensité, de 0 à 10.
  final int lastIntensity;

  /// Séances de suite au-dessus du seuil de la règle santé L13.
  final int consecutiveAboveThreshold;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'zone': zone.code,
      'side': side.code,
      'sessionsReported': sessionsReported,
      'lastIntensity': lastIntensity,
      'consecutiveAboveThreshold': consecutiveAboveThreshold,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PainTrend copyWith({
    BodyZone? zone,
    BodySide? side,
    int? sessionsReported,
    int? lastIntensity,
    int? consecutiveAboveThreshold,
  }) {
    return PainTrend(
      zone: zone ?? this.zone,
      side: side ?? this.side,
      sessionsReported: sessionsReported ?? this.sessionsReported,
      lastIntensity: lastIntensity ?? this.lastIntensity,
      consecutiveAboveThreshold: consecutiveAboveThreshold ?? this.consecutiveAboveThreshold,
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
    checkRange(out, '$path.sessionsReported', sessionsReported, 0, null);
    checkRange(out, '$path.lastIntensity', lastIntensity, 0, 10);
    checkRange(out, '$path.consecutiveAboveThreshold', consecutiveAboveThreshold, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is PainTrend && zone == other.zone && side == other.side && sessionsReported == other.sessionsReported && lastIntensity == other.lastIntensity && consecutiveAboveThreshold == other.consecutiveAboveThreshold;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[zone, side, sessionsReported, lastIntensity, consecutiveAboveThreshold]);

  @override
  String toString() => 'PainTrend(${toJson()})';
}

/// Résumé d'adaptation : ce que le moteur dynamique a appris (entrée de
/// `PlanEngine.nextBlock`).
final class AdaptationSummary {
  const AdaptationSummary({
    this.schemaVersion = currentSchemaVersion,
    required this.asOf,
    required this.weeksObserved,
    required this.sessionsPlanned,
    required this.sessionsCompleted,
    required this.unlockLevel,
    required this.confidence,
    required this.estimates,
    this.fatigue,
    required this.pains,
    required this.avoidedExerciseIds,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AdaptationSummary.fromJson(Map<String, Object?> json) {
    return AdaptationSummary(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      asOf: jsonDate(json, 'asOf'),
      weeksObserved: jsonInt(json, 'weeksObserved'),
      sessionsPlanned: jsonInt(json, 'sessionsPlanned'),
      sessionsCompleted: jsonInt(json, 'sessionsCompleted'),
      unlockLevel: jsonEnum(json, 'unlockLevel', UnlockLevel.fromCode),
      confidence: jsonDouble(json, 'confidence'),
      estimates: jsonList(json, 'estimates', (v) => ExerciseEstimate.fromJson(jsonAsObject(v, 'estimates'))),
      fatigue: jsonObjOrNull(json, 'fatigue', FatigueState.fromJson),
      pains: jsonList(json, 'pains', (v) => PainTrend.fromJson(jsonAsObject(v, 'pains'))),
      avoidedExerciseIds: jsonList(json, 'avoidedExerciseIds', (v) => jsonAsString(v, 'avoidedExerciseIds')),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Jour du résumé.
  final CivilDate asOf;

  /// Semaines de données réelles.
  final int weeksObserved;

  /// Séances prévues sur la période.
  final int sessionsPlanned;

  /// Séances terminées (hors « reprise »).
  final int sessionsCompleted;

  /// Niveau de déblocage atteint (D5.7).
  final UnlockLevel unlockLevel;

  /// Confiance globale du modèle, de 0 à 1.
  final double confidence;

  /// Capacités estimées.
  final List<ExerciseEstimate> estimates;

  /// Forme et fatigue.
  final FatigueState? fatigue;

  /// Zones douloureuses suivies.
  final List<PainTrend> pains;

  /// Exercices régulièrement sautés ou refusés.
  final List<String> avoidedExerciseIds;

  /// Faits marquants.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'asOf': asOf.iso,
      'weeksObserved': weeksObserved,
      'sessionsPlanned': sessionsPlanned,
      'sessionsCompleted': sessionsCompleted,
      'unlockLevel': unlockLevel.code,
      'confidence': confidence,
      'estimates': [for (final e in estimates) e.toJson()],
      if (fatigue case final v?) 'fatigue': v.toJson(),
      'pains': [for (final e in pains) e.toJson()],
      'avoidedExerciseIds': [for (final e in avoidedExerciseIds) e],
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AdaptationSummary copyWith({
    int? schemaVersion,
    CivilDate? asOf,
    int? weeksObserved,
    int? sessionsPlanned,
    int? sessionsCompleted,
    UnlockLevel? unlockLevel,
    double? confidence,
    List<ExerciseEstimate>? estimates,
    Object? fatigue = unset,
    List<PainTrend>? pains,
    List<String>? avoidedExerciseIds,
    List<Reason>? reasons,
  }) {
    return AdaptationSummary(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      asOf: asOf ?? this.asOf,
      weeksObserved: weeksObserved ?? this.weeksObserved,
      sessionsPlanned: sessionsPlanned ?? this.sessionsPlanned,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      confidence: confidence ?? this.confidence,
      estimates: estimates ?? this.estimates,
      fatigue: identical(fatigue, unset) ? this.fatigue : fatigue as FatigueState?,
      pains: pains ?? this.pains,
      avoidedExerciseIds: avoidedExerciseIds ?? this.avoidedExerciseIds,
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
    checkRange(out, '$path.schemaVersion', schemaVersion, 1, currentSchemaVersion);
    checkRange(out, '$path.weeksObserved', weeksObserved, 0, null);
    checkRange(out, '$path.sessionsPlanned', sessionsPlanned, 0, null);
    checkRange(out, '$path.sessionsCompleted', sessionsCompleted, 0, null);
    checkRange(out, '$path.confidence', confidence, 0, 1);
    for (var i = 0; i < estimates.length; i++) { estimates[i].collectViolations('$path.estimates[$i]', out); }
    if (fatigue case final v?) { v.collectViolations('$path.fatigue', out); }
    for (var i = 0; i < pains.length; i++) { pains[i].collectViolations('$path.pains[$i]', out); }
    for (var i = 0; i < avoidedExerciseIds.length; i++) { checkLength(out, '$path.avoidedExerciseIds[$i]', avoidedExerciseIds[i].length, 1, null); }
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in estimates) { e.collectExerciseIds(out); }
    fatigue?.collectExerciseIds(out);
    for (final e in pains) { e.collectExerciseIds(out); }
    out.addAll(avoidedExerciseIds);
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AdaptationSummary && schemaVersion == other.schemaVersion && asOf == other.asOf && weeksObserved == other.weeksObserved && sessionsPlanned == other.sessionsPlanned && sessionsCompleted == other.sessionsCompleted && unlockLevel == other.unlockLevel && confidence == other.confidence && jsonListEquals(estimates, other.estimates) && fatigue == other.fatigue && jsonListEquals(pains, other.pains) && jsonListEquals(avoidedExerciseIds, other.avoidedExerciseIds) && jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, asOf, weeksObserved, sessionsPlanned, sessionsCompleted, unlockLevel, confidence, Object.hashAll(estimates), fatigue, Object.hashAll(pains), Object.hashAll(avoidedExerciseIds), Object.hashAll(reasons)]);

  @override
  String toString() => 'AdaptationSummary(${toJson()})';
}

/// Entrée du moteur dynamique.
final class AdaptInput {
  const AdaptInput({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.block,
    required this.log,
    required this.today,
    this.state,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AdaptInput.fromJson(Map<String, Object?> json) {
    return AdaptInput(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      block: jsonObj(json, 'block', ProgramBlock.fromJson),
      log: jsonObj(json, 'log', TrainingLog.fromJson),
      today: jsonDate(json, 'today'),
      state: jsonObjectOrNull(json, 'state'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Profil.
  final AthleteProfile profile;

  /// Bloc en cours.
  final ProgramBlock block;

  /// Journal complet.
  final TrainingLog log;

  /// « Aujourd'hui », fourni par l'application.
  final CivilDate today;

  /// État opaque rendu par le dernier appel (propriété de kalis_adapt).
  final Map<String, Object?>? state;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'block': block.toJson(),
      'log': log.toJson(),
      'today': today.iso,
      if (state case final v?) 'state': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AdaptInput copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    ProgramBlock? block,
    TrainingLog? log,
    CivilDate? today,
    Object? state = unset,
  }) {
    return AdaptInput(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      block: block ?? this.block,
      log: log ?? this.log,
      today: today ?? this.today,
      state: identical(state, unset) ? this.state : state as Map<String, Object?>?,
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
    checkRange(out, '$path.schemaVersion', schemaVersion, 1, currentSchemaVersion);
    profile.collectViolations('$path.profile', out);
    block.collectViolations('$path.block', out);
    log.collectViolations('$path.log', out);
    if (state case final v?) { checkJson(out, '$path.state', v); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    block.collectExerciseIds(out);
    log.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AdaptInput && schemaVersion == other.schemaVersion && profile == other.profile && block == other.block && log == other.log && today == other.today && jsonDeepEquals(state, other.state);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, profile, block, log, today, jsonDeepHash(state)]);

  @override
  String toString() => 'AdaptInput(${toJson()})';
}

/// Ajustement d'une séance (bilan santé, douleur, temps disponible : D5.9).
final class SessionAdjustment {
  const SessionAdjustment({
    required this.kind,
    this.exerciseId,
    this.replacementExerciseId,
    this.loadFactor,
    this.setsDelta,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SessionAdjustment.fromJson(Map<String, Object?> json) {
    return SessionAdjustment(
      kind: jsonEnum(json, 'kind', AdjustmentKind.fromCode),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      replacementExerciseId: jsonStringOrNull(json, 'replacementExerciseId'),
      loadFactor: jsonDoubleOrNull(json, 'loadFactor'),
      setsDelta: jsonIntOrNull(json, 'setsDelta'),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
    );
  }

  /// Nature.
  final AdjustmentKind kind;

  /// Exercice concerné.
  final String? exerciseId;

  /// Exercice de remplacement.
  final String? replacementExerciseId;

  /// Facteur appliqué à la charge.
  final double? loadFactor;

  /// Séries ajoutées (négatif = retirées).
  final int? setsDelta;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (exerciseId case final v?) 'exerciseId': v,
      if (replacementExerciseId case final v?) 'replacementExerciseId': v,
      if (loadFactor case final v?) 'loadFactor': v,
      if (setsDelta case final v?) 'setsDelta': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SessionAdjustment copyWith({
    AdjustmentKind? kind,
    Object? exerciseId = unset,
    Object? replacementExerciseId = unset,
    Object? loadFactor = unset,
    Object? setsDelta = unset,
    List<Reason>? reasons,
  }) {
    return SessionAdjustment(
      kind: kind ?? this.kind,
      exerciseId: identical(exerciseId, unset) ? this.exerciseId : exerciseId as String?,
      replacementExerciseId: identical(replacementExerciseId, unset) ? this.replacementExerciseId : replacementExerciseId as String?,
      loadFactor: identical(loadFactor, unset) ? this.loadFactor : loadFactor as double?,
      setsDelta: identical(setsDelta, unset) ? this.setsDelta : setsDelta as int?,
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
    if (exerciseId case final v?) { checkLength(out, '$path.exerciseId', v.length, 1, null); }
    if (replacementExerciseId case final v?) { checkLength(out, '$path.replacementExerciseId', v.length, 1, null); }
    if (loadFactor case final v?) { checkRange(out, '$path.loadFactor', v, 0, 2); }
    if (setsDelta case final v?) { checkRange(out, '$path.setsDelta', v, -20, 20); }
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) { out.add(v); }
    if (replacementExerciseId case final v?) { out.add(v); }
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SessionAdjustment && kind == other.kind && exerciseId == other.exerciseId && replacementExerciseId == other.replacementExerciseId && loadFactor == other.loadFactor && setsDelta == other.setsDelta && jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[kind, exerciseId, replacementExerciseId, loadFactor, setsDelta, Object.hashAll(reasons)]);

  @override
  String toString() => 'SessionAdjustment(${toJson()})';
}

/// Prescription de la séance du jour, ajustée.
final class SessionPlan {
  const SessionPlan({
    this.schemaVersion = currentSchemaVersion,
    required this.date,
    required this.blockId,
    required this.weekIndex,
    required this.dayIndex,
    required this.items,
    required this.adjustments,
    required this.confidence,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SessionPlan.fromJson(Map<String, Object?> json) {
    return SessionPlan(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      date: jsonDate(json, 'date'),
      blockId: jsonString(json, 'blockId'),
      weekIndex: jsonInt(json, 'weekIndex'),
      dayIndex: jsonInt(json, 'dayIndex'),
      items: jsonList(json, 'items', (v) => ExercisePrescription.fromJson(jsonAsObject(v, 'items'))),
      adjustments: jsonList(json, 'adjustments', (v) => SessionAdjustment.fromJson(jsonAsObject(v, 'adjustments'))),
      confidence: jsonDouble(json, 'confidence'),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Jour de la séance.
  final CivilDate date;

  /// Bloc.
  final String blockId;

  /// Semaine dans le bloc.
  final int weekIndex;

  /// Jour d'entraînement.
  final int dayIndex;

  /// Exercices prescrits.
  final List<ExercisePrescription> items;

  /// Ajustements par rapport au bloc.
  final List<SessionAdjustment> adjustments;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'date': date.iso,
      'blockId': blockId,
      'weekIndex': weekIndex,
      'dayIndex': dayIndex,
      'items': [for (final e in items) e.toJson()],
      'adjustments': [for (final e in adjustments) e.toJson()],
      'confidence': confidence,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SessionPlan copyWith({
    int? schemaVersion,
    CivilDate? date,
    String? blockId,
    int? weekIndex,
    int? dayIndex,
    List<ExercisePrescription>? items,
    List<SessionAdjustment>? adjustments,
    double? confidence,
    List<Reason>? reasons,
  }) {
    return SessionPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      date: date ?? this.date,
      blockId: blockId ?? this.blockId,
      weekIndex: weekIndex ?? this.weekIndex,
      dayIndex: dayIndex ?? this.dayIndex,
      items: items ?? this.items,
      adjustments: adjustments ?? this.adjustments,
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
    checkRange(out, '$path.schemaVersion', schemaVersion, 1, currentSchemaVersion);
    checkLength(out, '$path.blockId', blockId.length, 1, null);
    checkRange(out, '$path.weekIndex', weekIndex, 0, null);
    checkRange(out, '$path.dayIndex', dayIndex, 0, null);
    for (var i = 0; i < items.length; i++) { items[i].collectViolations('$path.items[$i]', out); }
    for (var i = 0; i < adjustments.length; i++) { adjustments[i].collectViolations('$path.adjustments[$i]', out); }
    checkRange(out, '$path.confidence', confidence, 0, 1);
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in items) { e.collectExerciseIds(out); }
    for (final e in adjustments) { e.collectExerciseIds(out); }
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SessionPlan && schemaVersion == other.schemaVersion && date == other.date && blockId == other.blockId && weekIndex == other.weekIndex && dayIndex == other.dayIndex && jsonListEquals(items, other.items) && jsonListEquals(adjustments, other.adjustments) && confidence == other.confidence && jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, date, blockId, weekIndex, dayIndex, Object.hashAll(items), Object.hashAll(adjustments), confidence, Object.hashAll(reasons)]);

  @override
  String toString() => 'SessionPlan(${toJson()})';
}

/// Ajustement intra-séance : conseil pour la série suivante.
final class IntraSessionAdvice {
  const IntraSessionAdvice({
    required this.exerciseId,
    required this.action,
    this.nextLoadKg,
    this.nextRepsLow,
    this.nextRepsHigh,
    this.restSeconds,
    required this.confidence,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory IntraSessionAdvice.fromJson(Map<String, Object?> json) {
    return IntraSessionAdvice(
      exerciseId: jsonString(json, 'exerciseId'),
      action: jsonEnum(json, 'action', IntraSessionAction.fromCode),
      nextLoadKg: jsonDoubleOrNull(json, 'nextLoadKg'),
      nextRepsLow: jsonIntOrNull(json, 'nextRepsLow'),
      nextRepsHigh: jsonIntOrNull(json, 'nextRepsHigh'),
      restSeconds: jsonIntOrNull(json, 'restSeconds'),
      confidence: jsonDouble(json, 'confidence'),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
    );
  }

  /// Exercice.
  final String exerciseId;

  /// Conseil.
  final IntraSessionAction action;

  /// Charge externe conseillée, en kg.
  final double? nextLoadKg;

  /// Bas de la plage conseillée.
  final int? nextRepsLow;

  /// Haut de la plage conseillée.
  final int? nextRepsHigh;

  /// Repos conseillé, en secondes.
  final int? restSeconds;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'action': action.code,
      if (nextLoadKg case final v?) 'nextLoadKg': v,
      if (nextRepsLow case final v?) 'nextRepsLow': v,
      if (nextRepsHigh case final v?) 'nextRepsHigh': v,
      if (restSeconds case final v?) 'restSeconds': v,
      'confidence': confidence,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  IntraSessionAdvice copyWith({
    String? exerciseId,
    IntraSessionAction? action,
    Object? nextLoadKg = unset,
    Object? nextRepsLow = unset,
    Object? nextRepsHigh = unset,
    Object? restSeconds = unset,
    double? confidence,
    List<Reason>? reasons,
  }) {
    return IntraSessionAdvice(
      exerciseId: exerciseId ?? this.exerciseId,
      action: action ?? this.action,
      nextLoadKg: identical(nextLoadKg, unset) ? this.nextLoadKg : nextLoadKg as double?,
      nextRepsLow: identical(nextRepsLow, unset) ? this.nextRepsLow : nextRepsLow as int?,
      nextRepsHigh: identical(nextRepsHigh, unset) ? this.nextRepsHigh : nextRepsHigh as int?,
      restSeconds: identical(restSeconds, unset) ? this.restSeconds : restSeconds as int?,
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
    checkLength(out, '$path.exerciseId', exerciseId.length, 1, null);
    if (nextLoadKg case final v?) { checkRange(out, '$path.nextLoadKg', v, -300, 1000); }
    if (nextRepsLow case final v?) { checkRange(out, '$path.nextRepsLow', v, 0, 1000); }
    if (nextRepsHigh case final v?) { checkRange(out, '$path.nextRepsHigh', v, 0, 1000); }
    if (restSeconds case final v?) { checkRange(out, '$path.restSeconds', v, 0, 900); }
    checkRange(out, '$path.confidence', confidence, 0, 1);
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is IntraSessionAdvice && exerciseId == other.exerciseId && action == other.action && nextLoadKg == other.nextLoadKg && nextRepsLow == other.nextRepsLow && nextRepsHigh == other.nextRepsHigh && restSeconds == other.restSeconds && confidence == other.confidence && jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, action, nextLoadKg, nextRepsLow, nextRepsHigh, restSeconds, confidence, Object.hashAll(reasons)]);

  @override
  String toString() => 'IntraSessionAdvice(${toJson()})';
}

/// Proposition du moteur dynamique (D5.6, D5.7).
final class Proposal {
  const Proposal({
    required this.id,
    required this.kind,
    required this.scope,
    required this.createdOn,
    required this.confidence,
    required this.unlockLevel,
    required this.autoApplicable,
    this.exerciseId,
    this.diff,
    this.block,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Proposal.fromJson(Map<String, Object?> json) {
    return Proposal(
      id: jsonString(json, 'id'),
      kind: jsonEnum(json, 'kind', ProposalKind.fromCode),
      scope: jsonEnum(json, 'scope', ProposalScope.fromCode),
      createdOn: jsonDate(json, 'createdOn'),
      confidence: jsonDouble(json, 'confidence'),
      unlockLevel: jsonEnum(json, 'unlockLevel', UnlockLevel.fromCode),
      autoApplicable: jsonBool(json, 'autoApplicable'),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      diff: jsonObjOrNull(json, 'diff', PlanDiff.fromJson),
      block: jsonObjOrNull(json, 'block', ProgramBlock.fromJson),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
    );
  }

  /// Identifiant stable.
  final String id;

  /// Type.
  final ProposalKind kind;

  /// Portée.
  final ProposalScope scope;

  /// Jour de création.
  final CivilDate createdOn;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Niveau de déblocage requis.
  final UnlockLevel unlockLevel;

  /// Applicable automatiquement en mode assisté.
  final bool autoApplicable;

  /// Exercice concerné.
  final String? exerciseId;

  /// Changement de programme proposé.
  final PlanDiff? diff;

  /// Bloc résultant, pour une restructuration.
  final ProgramBlock? block;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.code,
      'scope': scope.code,
      'createdOn': createdOn.iso,
      'confidence': confidence,
      'unlockLevel': unlockLevel.code,
      'autoApplicable': autoApplicable,
      if (exerciseId case final v?) 'exerciseId': v,
      if (diff case final v?) 'diff': v.toJson(),
      if (block case final v?) 'block': v.toJson(),
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Proposal copyWith({
    String? id,
    ProposalKind? kind,
    ProposalScope? scope,
    CivilDate? createdOn,
    double? confidence,
    UnlockLevel? unlockLevel,
    bool? autoApplicable,
    Object? exerciseId = unset,
    Object? diff = unset,
    Object? block = unset,
    List<Reason>? reasons,
  }) {
    return Proposal(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      scope: scope ?? this.scope,
      createdOn: createdOn ?? this.createdOn,
      confidence: confidence ?? this.confidence,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      autoApplicable: autoApplicable ?? this.autoApplicable,
      exerciseId: identical(exerciseId, unset) ? this.exerciseId : exerciseId as String?,
      diff: identical(diff, unset) ? this.diff : diff as PlanDiff?,
      block: identical(block, unset) ? this.block : block as ProgramBlock?,
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
    checkLength(out, '$path.id', id.length, 1, null);
    checkRange(out, '$path.confidence', confidence, 0, 1);
    if (exerciseId case final v?) { checkLength(out, '$path.exerciseId', v.length, 1, null); }
    if (diff case final v?) { v.collectViolations('$path.diff', out); }
    if (block case final v?) { v.collectViolations('$path.block', out); }
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) { out.add(v); }
    diff?.collectExerciseIds(out);
    block?.collectExerciseIds(out);
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is Proposal && id == other.id && kind == other.kind && scope == other.scope && createdOn == other.createdOn && confidence == other.confidence && unlockLevel == other.unlockLevel && autoApplicable == other.autoApplicable && exerciseId == other.exerciseId && diff == other.diff && block == other.block && jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[id, kind, scope, createdOn, confidence, unlockLevel, autoApplicable, exerciseId, diff, block, Object.hashAll(reasons)]);

  @override
  String toString() => 'Proposal(${toJson()})';
}

/// Entrée du journal du moteur (inspecteur et export du mode dev, D2.5).
final class EngineLogEntry {
  const EngineLogEntry({
    required this.sequence,
    required this.date,
    required this.engine,
    required this.event,
    this.confidence,
    required this.reasons,
    required this.data,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory EngineLogEntry.fromJson(Map<String, Object?> json) {
    return EngineLogEntry(
      sequence: jsonInt(json, 'sequence'),
      date: jsonDate(json, 'date'),
      engine: jsonString(json, 'engine'),
      event: jsonString(json, 'event'),
      confidence: jsonDoubleOrNull(json, 'confidence'),
      reasons: jsonList(json, 'reasons', (v) => Reason.fromJson(jsonAsObject(v, 'reasons'))),
      data: jsonObject(json, 'data'),
    );
  }

  /// Rang dans le journal.
  final int sequence;

  /// Jour.
  final CivilDate date;

  /// Moteur (`plan`, `adapt`, `quest`).
  final String engine;

  /// Code de l'événement.
  final String event;

  /// Confiance de la décision.
  final double? confidence;

  /// Raisons.
  final List<Reason> reasons;

  /// Détail (scores, valeurs du modèle).
  final Map<String, Object?> data;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'date': date.iso,
      'engine': engine,
      'event': event,
      if (confidence case final v?) 'confidence': v,
      'reasons': [for (final e in reasons) e.toJson()],
      'data': data,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  EngineLogEntry copyWith({
    int? sequence,
    CivilDate? date,
    String? engine,
    String? event,
    Object? confidence = unset,
    List<Reason>? reasons,
    Map<String, Object?>? data,
  }) {
    return EngineLogEntry(
      sequence: sequence ?? this.sequence,
      date: date ?? this.date,
      engine: engine ?? this.engine,
      event: event ?? this.event,
      confidence: identical(confidence, unset) ? this.confidence : confidence as double?,
      reasons: reasons ?? this.reasons,
      data: data ?? this.data,
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
    checkRange(out, '$path.sequence', sequence, 0, null);
    checkLength(out, '$path.engine', engine.length, 1, null);
    checkLength(out, '$path.event', event.length, 1, null);
    if (confidence case final v?) { checkRange(out, '$path.confidence', v, 0, 1); }
    for (var i = 0; i < reasons.length; i++) { reasons[i].collectViolations('$path.reasons[$i]', out); }
    checkJson(out, '$path.data', data);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in reasons) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is EngineLogEntry && sequence == other.sequence && date == other.date && engine == other.engine && event == other.event && confidence == other.confidence && jsonListEquals(reasons, other.reasons) && jsonDeepEquals(data, other.data);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[sequence, date, engine, event, confidence, Object.hashAll(reasons), jsonDeepHash(data)]);

  @override
  String toString() => 'EngineLogEntry(${toJson()})';
}

/// Résultat d'une revue du moteur dynamique.
final class AdaptReview {
  const AdaptReview({
    required this.summary,
    required this.proposals,
    required this.state,
    required this.log,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AdaptReview.fromJson(Map<String, Object?> json) {
    return AdaptReview(
      summary: jsonObj(json, 'summary', AdaptationSummary.fromJson),
      proposals: jsonList(json, 'proposals', (v) => Proposal.fromJson(jsonAsObject(v, 'proposals'))),
      state: jsonObject(json, 'state'),
      log: jsonList(json, 'log', (v) => EngineLogEntry.fromJson(jsonAsObject(v, 'log'))),
    );
  }

  /// Résumé d'adaptation.
  final AdaptationSummary summary;

  /// Propositions.
  final List<Proposal> proposals;

  /// État opaque à repasser au prochain appel.
  final Map<String, Object?> state;

  /// Entrées de journal du moteur.
  final List<EngineLogEntry> log;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'summary': summary.toJson(),
      'proposals': [for (final e in proposals) e.toJson()],
      'state': state,
      'log': [for (final e in log) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AdaptReview copyWith({
    AdaptationSummary? summary,
    List<Proposal>? proposals,
    Map<String, Object?>? state,
    List<EngineLogEntry>? log,
  }) {
    return AdaptReview(
      summary: summary ?? this.summary,
      proposals: proposals ?? this.proposals,
      state: state ?? this.state,
      log: log ?? this.log,
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
    summary.collectViolations('$path.summary', out);
    for (var i = 0; i < proposals.length; i++) { proposals[i].collectViolations('$path.proposals[$i]', out); }
    checkJson(out, '$path.state', state);
    for (var i = 0; i < log.length; i++) { log[i].collectViolations('$path.log[$i]', out); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    summary.collectExerciseIds(out);
    for (final e in proposals) { e.collectExerciseIds(out); }
    for (final e in log) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is AdaptReview && summary == other.summary && jsonListEquals(proposals, other.proposals) && jsonDeepEquals(state, other.state) && jsonListEquals(log, other.log);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[summary, Object.hashAll(proposals), jsonDeepHash(state), Object.hashAll(log)]);

  @override
  String toString() => 'AdaptReview(${toJson()})';
}
