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
      exerciseId: identical(exerciseId, unset) ? this.exerciseId : exerciseId as String?,
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
    if (exerciseId case final v?) { checkLength(out, '$path.exerciseId', v.length, 1, null); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) { out.add(v); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is PainReport && zone == other.zone && side == other.side && joint == other.joint && intensity == other.intensity && phase == other.phase && exerciseId == other.exerciseId;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[zone, side, joint, intensity, phase, exerciseId]);

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
    this.pains,
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
      pains: jsonListOrNull(json, 'pains', (v) => PainReport.fromJson(jsonAsObject(v, 'pains'))),
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

  /// Douleurs localisées (absent : question non posée ou sans réponse ; liste
  /// vide : aucune douleur).
  final List<PainReport>? pains;

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
      if (pains case final v?) 'pains': [for (final e in v) e.toJson()],
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
    Object? pains = unset,
  }) {
    return HealthCheck(
      overall: identical(overall, unset) ? this.overall : overall as int?,
      sleepQuality: identical(sleepQuality, unset) ? this.sleepQuality : sleepQuality as int?,
      sleepHours: identical(sleepHours, unset) ? this.sleepHours : sleepHours as double?,
      energy: identical(energy, unset) ? this.energy : energy as int?,
      mood: identical(mood, unset) ? this.mood : mood as int?,
      soreness: identical(soreness, unset) ? this.soreness : soreness as int?,
      stress: identical(stress, unset) ? this.stress : stress as int?,
      motivation: identical(motivation, unset) ? this.motivation : motivation as int?,
      nutrition: identical(nutrition, unset) ? this.nutrition : nutrition as int?,
      hydration: identical(hydration, unset) ? this.hydration : hydration as int?,
      minutesAvailable: identical(minutesAvailable, unset) ? this.minutesAvailable : minutesAvailable as int?,
      pains: identical(pains, unset) ? this.pains : pains as List<PainReport>?,
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
    if (overall case final v?) { checkRange(out, '$path.overall', v, 1, 5); }
    if (sleepQuality case final v?) { checkRange(out, '$path.sleepQuality', v, 1, 5); }
    if (sleepHours case final v?) { checkRange(out, '$path.sleepHours', v, 0, 24); }
    if (energy case final v?) { checkRange(out, '$path.energy', v, 1, 5); }
    if (mood case final v?) { checkRange(out, '$path.mood', v, 1, 5); }
    if (soreness case final v?) { checkRange(out, '$path.soreness', v, 1, 5); }
    if (stress case final v?) { checkRange(out, '$path.stress', v, 1, 5); }
    if (motivation case final v?) { checkRange(out, '$path.motivation', v, 1, 5); }
    if (nutrition case final v?) { checkRange(out, '$path.nutrition', v, 1, 5); }
    if (hydration case final v?) { checkRange(out, '$path.hydration', v, 1, 5); }
    if (minutesAvailable case final v?) { checkRange(out, '$path.minutesAvailable', v, 0, 600); }
    if (pains case final v?) { for (var i = 0; i < v.length; i++) { v[i].collectViolations('$path.pains[$i]', out); } }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in pains ?? const <PainReport>[]) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is HealthCheck && overall == other.overall && sleepQuality == other.sleepQuality && sleepHours == other.sleepHours && energy == other.energy && mood == other.mood && soreness == other.soreness && stress == other.stress && motivation == other.motivation && nutrition == other.nutrition && hydration == other.hydration && minutesAvailable == other.minutesAvailable && jsonDeepEquals(pains, other.pains);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[overall, sleepQuality, sleepHours, energy, mood, soreness, stress, motivation, nutrition, hydration, minutesAvailable, jsonDeepHash(pains)]);

  @override
  String toString() => 'HealthCheck(${toJson()})';
}

/// Cible prescrite d'une série, telle qu'elle était affichée.
///
/// Invariant : Bornes basses ≤ bornes hautes quand les deux sont renseignées.
final class SetTarget {
  const SetTarget({
    this.repsLow,
    this.repsHigh,
    this.secondsLow,
    this.secondsHigh,
    this.distanceMeters,
    this.calories,
    this.loadKg,
    this.flames,
    this.role,
    this.percentOfOneRm,
    this.restSeconds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SetTarget.fromJson(Map<String, Object?> json) {
    return SetTarget(
      repsLow: jsonIntOrNull(json, 'repsLow'),
      repsHigh: jsonIntOrNull(json, 'repsHigh'),
      secondsLow: jsonIntOrNull(json, 'secondsLow'),
      secondsHigh: jsonIntOrNull(json, 'secondsHigh'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      calories: jsonDoubleOrNull(json, 'calories'),
      loadKg: jsonDoubleOrNull(json, 'loadKg'),
      flames: jsonIntOrNull(json, 'flames'),
      role: jsonEnumOrNull(json, 'role', SetRole.fromCode),
      percentOfOneRm: jsonDoubleOrNull(json, 'percentOfOneRm'),
      restSeconds: jsonIntOrNull(json, 'restSeconds'),
    );
  }

  /// Bas de la plage de répétitions.
  final int? repsLow;

  /// Haut de la plage de répétitions.
  final int? repsHigh;

  /// Bas de la plage de temps, en secondes.
  final int? secondsLow;

  /// Haut de la plage de temps, en secondes.
  final int? secondsHigh;

  /// Distance visée, en mètres.
  final double? distanceMeters;

  /// Calories visées.
  final double? calories;

  /// Charge externe prescrite, en kg (même convention que
  /// `SetRecord.externalLoadKg`).
  final double? loadKg;

  /// Flammes visées.
  final int? flames;

  /// Rôle de la série dans la technique (0.4.0).
  final SetRole? role;

  /// Charge de la série, en part du 1RM de charge totale (0.4.0).
  final double? percentOfOneRm;

  /// Repos après la série, en secondes (0.4.0).
  final int? restSeconds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (repsLow case final v?) 'repsLow': v,
      if (repsHigh case final v?) 'repsHigh': v,
      if (secondsLow case final v?) 'secondsLow': v,
      if (secondsHigh case final v?) 'secondsHigh': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (calories case final v?) 'calories': v,
      if (loadKg case final v?) 'loadKg': v,
      if (flames case final v?) 'flames': v,
      if (role case final v?) 'role': v.code,
      if (percentOfOneRm case final v?) 'percentOfOneRm': v,
      if (restSeconds case final v?) 'restSeconds': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SetTarget copyWith({
    Object? repsLow = unset,
    Object? repsHigh = unset,
    Object? secondsLow = unset,
    Object? secondsHigh = unset,
    Object? distanceMeters = unset,
    Object? calories = unset,
    Object? loadKg = unset,
    Object? flames = unset,
    Object? role = unset,
    Object? percentOfOneRm = unset,
    Object? restSeconds = unset,
  }) {
    return SetTarget(
      repsLow: identical(repsLow, unset) ? this.repsLow : repsLow as int?,
      repsHigh: identical(repsHigh, unset) ? this.repsHigh : repsHigh as int?,
      secondsLow: identical(secondsLow, unset) ? this.secondsLow : secondsLow as int?,
      secondsHigh: identical(secondsHigh, unset) ? this.secondsHigh : secondsHigh as int?,
      distanceMeters: identical(distanceMeters, unset) ? this.distanceMeters : distanceMeters as double?,
      calories: identical(calories, unset) ? this.calories : calories as double?,
      loadKg: identical(loadKg, unset) ? this.loadKg : loadKg as double?,
      flames: identical(flames, unset) ? this.flames : flames as int?,
      role: identical(role, unset) ? this.role : role as SetRole?,
      percentOfOneRm: identical(percentOfOneRm, unset) ? this.percentOfOneRm : percentOfOneRm as double?,
      restSeconds: identical(restSeconds, unset) ? this.restSeconds : restSeconds as int?,
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
    if (repsLow case final v?) { checkRange(out, '$path.repsLow', v, 0, 1000); }
    if (repsHigh case final v?) { checkRange(out, '$path.repsHigh', v, 0, 1000); }
    if (secondsLow case final v?) { checkRange(out, '$path.secondsLow', v, 0, 86400); }
    if (secondsHigh case final v?) { checkRange(out, '$path.secondsHigh', v, 0, 86400); }
    if (distanceMeters case final v?) { checkRange(out, '$path.distanceMeters', v, 0, null); }
    if (calories case final v?) { checkRange(out, '$path.calories', v, 0, null); }
    if (loadKg case final v?) { checkRange(out, '$path.loadKg', v, -300, 1000); }
    if (flames case final v?) { checkRange(out, '$path.flames', v, 1, 10); }
    if (percentOfOneRm case final v?) { checkRange(out, '$path.percentOfOneRm', v, 0, 1.5); }
    if (restSeconds case final v?) { checkRange(out, '$path.restSeconds', v, 0, 900); }
    _validateSetTarget(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SetTarget && repsLow == other.repsLow && repsHigh == other.repsHigh && secondsLow == other.secondsLow && secondsHigh == other.secondsHigh && distanceMeters == other.distanceMeters && calories == other.calories && loadKg == other.loadKg && flames == other.flames && role == other.role && percentOfOneRm == other.percentOfOneRm && restSeconds == other.restSeconds;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[repsLow, repsHigh, secondsLow, secondsHigh, distanceMeters, calories, loadKg, flames, role, percentOfOneRm, restSeconds]);

  @override
  String toString() => 'SetTarget(${toJson()})';
}

/// Série réalisée.
///
/// Invariant : Au moins une mesure parmi `reps`, `seconds`, `distanceMeters`,
/// `calories`.
/// Invariant : (0.4.0) Quand toutes les `parts` ont des répétitions, leur
/// somme vaut `reps`.
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
    this.slotId,
    this.side,
    this.target,
    this.technique,
    this.role,
    this.parts,
    this.restBeforeSeconds,
    this.elapsedSeconds,
    this.rounds,
    this.quality,
    this.attemptIndex,
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
      slotId: jsonStringOrNull(json, 'slotId'),
      side: jsonEnumOrNull(json, 'side', BodySide.fromCode),
      target: jsonObjOrNull(json, 'target', SetTarget.fromJson),
      technique: jsonEnumOrNull(json, 'technique', SetTechniqueKind.fromCode),
      role: jsonEnumOrNull(json, 'role', SetRole.fromCode),
      parts: jsonListOrNull(json, 'parts', (v) => SetPart.fromJson(jsonAsObject(v, 'parts'))),
      restBeforeSeconds: jsonIntOrNull(json, 'restBeforeSeconds'),
      elapsedSeconds: jsonIntOrNull(json, 'elapsedSeconds'),
      rounds: jsonIntOrNull(json, 'rounds'),
      quality: jsonIntOrNull(json, 'quality'),
      attemptIndex: jsonIntOrNull(json, 'attemptIndex'),
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

  /// Charge externe en kg, telle que l'utilisateur la lit : barre et disques
  /// compris ; par haltère ou par kettlebell ; valeur affichée d'une machine ou
  /// d'une poulie ; lest seul pour un exercice lesté (le poids du corps n'y est
  /// jamais ajouté) ; négative = assistance ; absente = aucune.
  final double? externalLoadKg;

  /// Répétitions réalisées (par côté pour un exercice unilatéral).
  final int? reps;

  /// Durée réalisée, en secondes (par côté pour un exercice unilatéral).
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

  /// Emplacement du programme dont vient la série.
  final String? slotId;

  /// Côté travaillé (exercice unilatéral) : `both` = une série par côté,
  /// comptée une fois ; `left` ou `right` = un seul côté.
  final BodySide? side;

  /// Cible prescrite.
  final SetTarget? target;

  /// Technique de la série (0.4.0).
  final SetTechniqueKind? technique;

  /// Rôle de la série dans la technique (0.4.0).
  final SetRole? role;

  /// Détail de la série (0.4.0) : mini-séries d'un cluster, d'un rest-pause, de
  /// myo-reps, paliers d'une dégressive, passages d'un bloc de densité. La
  /// série reste une seule ligne ; `reps` (ou `seconds`) en est le total.
  final List<SetPart>? parts;

  /// Repos pris avant la série, en secondes (0.4.0).
  final int? restBeforeSeconds;

  /// Temps écoulé depuis le début du bloc chronométré, en secondes (AMRAP,
  /// EMOM, densité, épreuve pour le temps) (0.4.0).
  final int? elapsedSeconds;

  /// Tours complets réalisés (AMRAP, circuit) (0.4.0).
  final int? rounds;

  /// Propreté déclarée de 1 à 5 (5 = parfaite) pour une figure ou un maintien
  /// (0.4.0) ; absente = non notée.
  final int? quality;

  /// Rang de la tentative de compétition (0 = ouverture) (0.4.0).
  final int? attemptIndex;

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
      if (slotId case final v?) 'slotId': v,
      if (side case final v?) 'side': v.code,
      if (target case final v?) 'target': v.toJson(),
      if (technique case final v?) 'technique': v.code,
      if (role case final v?) 'role': v.code,
      if (parts case final v?) 'parts': [for (final e in v) e.toJson()],
      if (restBeforeSeconds case final v?) 'restBeforeSeconds': v,
      if (elapsedSeconds case final v?) 'elapsedSeconds': v,
      if (rounds case final v?) 'rounds': v,
      if (quality case final v?) 'quality': v,
      if (attemptIndex case final v?) 'attemptIndex': v,
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
    Object? slotId = unset,
    Object? side = unset,
    Object? target = unset,
    Object? technique = unset,
    Object? role = unset,
    Object? parts = unset,
    Object? restBeforeSeconds = unset,
    Object? elapsedSeconds = unset,
    Object? rounds = unset,
    Object? quality = unset,
    Object? attemptIndex = unset,
  }) {
    return SetRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseOrder: exerciseOrder ?? this.exerciseOrder,
      setIndex: setIndex ?? this.setIndex,
      kind: kind ?? this.kind,
      externalLoadKg: identical(externalLoadKg, unset) ? this.externalLoadKg : externalLoadKg as double?,
      reps: identical(reps, unset) ? this.reps : reps as int?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      distanceMeters: identical(distanceMeters, unset) ? this.distanceMeters : distanceMeters as double?,
      calories: identical(calories, unset) ? this.calories : calories as double?,
      flames: identical(flames, unset) ? this.flames : flames as int?,
      success: success ?? this.success,
      excluded: excluded ?? this.excluded,
      slotId: identical(slotId, unset) ? this.slotId : slotId as String?,
      side: identical(side, unset) ? this.side : side as BodySide?,
      target: identical(target, unset) ? this.target : target as SetTarget?,
      technique: identical(technique, unset) ? this.technique : technique as SetTechniqueKind?,
      role: identical(role, unset) ? this.role : role as SetRole?,
      parts: identical(parts, unset) ? this.parts : parts as List<SetPart>?,
      restBeforeSeconds: identical(restBeforeSeconds, unset) ? this.restBeforeSeconds : restBeforeSeconds as int?,
      elapsedSeconds: identical(elapsedSeconds, unset) ? this.elapsedSeconds : elapsedSeconds as int?,
      rounds: identical(rounds, unset) ? this.rounds : rounds as int?,
      quality: identical(quality, unset) ? this.quality : quality as int?,
      attemptIndex: identical(attemptIndex, unset) ? this.attemptIndex : attemptIndex as int?,
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
    if (externalLoadKg case final v?) { checkRange(out, '$path.externalLoadKg', v, -300, 1000); }
    if (reps case final v?) { checkRange(out, '$path.reps', v, 0, 1000); }
    if (seconds case final v?) { checkRange(out, '$path.seconds', v, 0, 86400); }
    if (distanceMeters case final v?) { checkRange(out, '$path.distanceMeters', v, 0, null); }
    if (calories case final v?) { checkRange(out, '$path.calories', v, 0, null); }
    if (flames case final v?) { checkRange(out, '$path.flames', v, 1, 10); }
    if (target case final v?) { v.collectViolations('$path.target', out); }
    if (parts case final v?) { checkLength(out, '$path.parts', v.length, 1, 120); for (var i = 0; i < v.length; i++) { v[i].collectViolations('$path.parts[$i]', out); } }
    if (restBeforeSeconds case final v?) { checkRange(out, '$path.restBeforeSeconds', v, 0, 3600); }
    if (elapsedSeconds case final v?) { checkRange(out, '$path.elapsedSeconds', v, 0, 86400); }
    if (rounds case final v?) { checkRange(out, '$path.rounds', v, 0, 1000); }
    if (quality case final v?) { checkRange(out, '$path.quality', v, 1, 5); }
    if (attemptIndex case final v?) { checkRange(out, '$path.attemptIndex', v, 0, 3); }
    _validateSetRecord(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    target?.collectExerciseIds(out);
    for (final e in parts ?? const <SetPart>[]) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SetRecord && exerciseId == other.exerciseId && exerciseOrder == other.exerciseOrder && setIndex == other.setIndex && kind == other.kind && externalLoadKg == other.externalLoadKg && reps == other.reps && seconds == other.seconds && distanceMeters == other.distanceMeters && calories == other.calories && flames == other.flames && success == other.success && excluded == other.excluded && slotId == other.slotId && side == other.side && target == other.target && technique == other.technique && role == other.role && jsonDeepEquals(parts, other.parts) && restBeforeSeconds == other.restBeforeSeconds && elapsedSeconds == other.elapsedSeconds && rounds == other.rounds && quality == other.quality && attemptIndex == other.attemptIndex;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[exerciseId, exerciseOrder, setIndex, kind, externalLoadKg, reps, seconds, distanceMeters, calories, flames, success, excluded, slotId, side, target, technique, role, jsonDeepHash(parts), restBeforeSeconds, elapsedSeconds, rounds, quality, attemptIndex]);

  @override
  String toString() => 'SetRecord(${toJson()})';
}

/// Pause déclarée (vacances, maladie…) : ni manquement ni perte de série.
///
/// Invariant : `startDate` ≤ `endDate`.
final class TrainingBreak {
  const TrainingBreak({
    required this.startDate,
    this.endDate,
    required this.reason,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory TrainingBreak.fromJson(Map<String, Object?> json) {
    return TrainingBreak(
      startDate: jsonDate(json, 'startDate'),
      endDate: jsonDateOrNull(json, 'endDate'),
      reason: jsonEnum(json, 'reason', BreakReason.fromCode),
    );
  }

  /// Premier jour de la pause.
  final CivilDate startDate;

  /// Dernier jour de la pause (absent : en cours).
  final CivilDate? endDate;

  /// Motif.
  final BreakReason reason;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'startDate': startDate.iso,
      if (endDate case final v?) 'endDate': v.iso,
      'reason': reason.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  TrainingBreak copyWith({
    CivilDate? startDate,
    Object? endDate = unset,
    BreakReason? reason,
  }) {
    return TrainingBreak(
      startDate: startDate ?? this.startDate,
      endDate: identical(endDate, unset) ? this.endDate : endDate as CivilDate?,
      reason: reason ?? this.reason,
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
    _validateTrainingBreak(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is TrainingBreak && startDate == other.startDate && endDate == other.endDate && reason == other.reason;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[startDate, endDate, reason]);

  @override
  String toString() => 'TrainingBreak(${toJson()})';
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

  /// Rang du jour dans la semaine du bloc, celui de `DayPrescription.dayIndex`
  /// (0 = premier).
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
  ProgramRef copyWith({
    String? blockId,
    int? weekIndex,
    int? dayIndex,
  }) {
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
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ProgramRef && blockId == other.blockId && weekIndex == other.weekIndex && dayIndex == other.dayIndex;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[blockId, weekIndex, dayIndex]);

  @override
  String toString() => 'ProgramRef(${toJson()})';
}

/// Séance du journal. Dates en jours civils.
///
/// Invariant : (0.4.0) Un résultat au plus par groupe (`groupResults` :
/// `groupId` distincts).
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
    this.place,
    this.healthCheck,
    required this.sets,
    required this.pains,
    this.plannedWorkSets,
    this.eventId,
    this.groupResults,
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
      place: jsonEnumOrNull(json, 'place', Place.fromCode),
      healthCheck: jsonObjOrNull(json, 'healthCheck', HealthCheck.fromJson),
      sets: jsonList(json, 'sets', (v) => SetRecord.fromJson(jsonAsObject(v, 'sets'))),
      pains: jsonList(json, 'pains', (v) => PainReport.fromJson(jsonAsObject(v, 'pains'))),
      plannedWorkSets: jsonIntOrNull(json, 'plannedWorkSets'),
      eventId: jsonStringOrNull(json, 'eventId'),
      groupResults: jsonListOrNull(json, 'groupResults', (v) => GroupResult.fromJson(jsonAsObject(v, 'groupResults'))),
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

  /// Lieu de la séance.
  final Place? place;

  /// Bilan santé de début de séance.
  final HealthCheck? healthCheck;

  /// Séries, dans l'ordre de réalisation.
  final List<SetRecord> sets;

  /// Douleurs signalées pendant ou après la séance.
  final List<PainReport> pains;

  /// Nombre de séries de travail prescrites pour cette séance, telle qu'elle a
  /// été affichée (après l'ajustement du bilan santé, de la douleur, du lieu et
  /// du temps du jour) (0.3.0). Sert à `kalis_quest` pour rapporter l'effort au
  /// programme : une séance allégée et faite en entier vaut une séance
  /// complète.
  final int? plannedWorkSets;

  /// Échéance du profil dont cette séance est le jour (0.4.0).
  final String? eventId;

  /// Résultats des groupes d'exercices enchaînés (0.4.0).
  final List<GroupResult>? groupResults;

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
      if (place case final v?) 'place': v.code,
      if (healthCheck case final v?) 'healthCheck': v.toJson(),
      'sets': [for (final e in sets) e.toJson()],
      'pains': [for (final e in pains) e.toJson()],
      if (plannedWorkSets case final v?) 'plannedWorkSets': v,
      if (eventId case final v?) 'eventId': v,
      if (groupResults case final v?) 'groupResults': [for (final e in v) e.toJson()],
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
    Object? place = unset,
    Object? healthCheck = unset,
    List<SetRecord>? sets,
    List<PainReport>? pains,
    Object? plannedWorkSets = unset,
    Object? eventId = unset,
    Object? groupResults = unset,
  }) {
    return SessionRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      origin: origin ?? this.origin,
      programRef: identical(programRef, unset) ? this.programRef : programRef as ProgramRef?,
      resume: resume ?? this.resume,
      completed: completed ?? this.completed,
      durationMinutes: identical(durationMinutes, unset) ? this.durationMinutes : durationMinutes as int?,
      bodyWeightKg: identical(bodyWeightKg, unset) ? this.bodyWeightKg : bodyWeightKg as double?,
      place: identical(place, unset) ? this.place : place as Place?,
      healthCheck: identical(healthCheck, unset) ? this.healthCheck : healthCheck as HealthCheck?,
      sets: sets ?? this.sets,
      pains: pains ?? this.pains,
      plannedWorkSets: identical(plannedWorkSets, unset) ? this.plannedWorkSets : plannedWorkSets as int?,
      eventId: identical(eventId, unset) ? this.eventId : eventId as String?,
      groupResults: identical(groupResults, unset) ? this.groupResults : groupResults as List<GroupResult>?,
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
    if (programRef case final v?) { v.collectViolations('$path.programRef', out); }
    if (durationMinutes case final v?) { checkRange(out, '$path.durationMinutes', v, 0, 600); }
    if (bodyWeightKg case final v?) { checkRange(out, '$path.bodyWeightKg', v, 25, 300); }
    if (healthCheck case final v?) { v.collectViolations('$path.healthCheck', out); }
    for (var i = 0; i < sets.length; i++) { sets[i].collectViolations('$path.sets[$i]', out); }
    for (var i = 0; i < pains.length; i++) { pains[i].collectViolations('$path.pains[$i]', out); }
    if (plannedWorkSets case final v?) { checkRange(out, '$path.plannedWorkSets', v, 0, 500); }
    if (eventId case final v?) { checkLength(out, '$path.eventId', v.length, 1, null); }
    if (groupResults case final v?) { checkLength(out, '$path.groupResults', v.length, null, 20); for (var i = 0; i < v.length; i++) { v[i].collectViolations('$path.groupResults[$i]', out); } }
    _validateSessionRecord(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    programRef?.collectExerciseIds(out);
    healthCheck?.collectExerciseIds(out);
    for (final e in sets) { e.collectExerciseIds(out); }
    for (final e in pains) { e.collectExerciseIds(out); }
    for (final e in groupResults ?? const <GroupResult>[]) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SessionRecord && id == other.id && date == other.date && origin == other.origin && programRef == other.programRef && resume == other.resume && completed == other.completed && durationMinutes == other.durationMinutes && bodyWeightKg == other.bodyWeightKg && place == other.place && healthCheck == other.healthCheck && jsonListEquals(sets, other.sets) && jsonListEquals(pains, other.pains) && plannedWorkSets == other.plannedWorkSets && eventId == other.eventId && jsonDeepEquals(groupResults, other.groupResults);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[id, date, origin, programRef, resume, completed, durationMinutes, bodyWeightKg, place, healthCheck, Object.hashAll(sets), Object.hashAll(pains), plannedWorkSets, eventId, jsonDeepHash(groupResults)]);

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
    this.breaks,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory TrainingLog.fromJson(Map<String, Object?> json) {
    return TrainingLog(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      sessions: jsonList(json, 'sessions', (v) => SessionRecord.fromJson(jsonAsObject(v, 'sessions'))),
      breaks: jsonListOrNull(json, 'breaks', (v) => TrainingBreak.fromJson(jsonAsObject(v, 'breaks'))),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Séances, par date croissante.
  final List<SessionRecord> sessions;

  /// Pauses déclarées.
  final List<TrainingBreak>? breaks;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'sessions': [for (final e in sessions) e.toJson()],
      if (breaks case final v?) 'breaks': [for (final e in v) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  TrainingLog copyWith({
    int? schemaVersion,
    List<SessionRecord>? sessions,
    Object? breaks = unset,
  }) {
    return TrainingLog(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sessions: sessions ?? this.sessions,
      breaks: identical(breaks, unset) ? this.breaks : breaks as List<TrainingBreak>?,
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
    for (var i = 0; i < sessions.length; i++) { sessions[i].collectViolations('$path.sessions[$i]', out); }
    if (breaks case final v?) { for (var i = 0; i < v.length; i++) { v[i].collectViolations('$path.breaks[$i]', out); } }
    _validateTrainingLog(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in sessions) { e.collectExerciseIds(out); }
    for (final e in breaks ?? const <TrainingBreak>[]) { e.collectExerciseIds(out); }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is TrainingLog && schemaVersion == other.schemaVersion && jsonListEquals(sessions, other.sessions) && jsonDeepEquals(breaks, other.breaks);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, Object.hashAll(sessions), jsonDeepHash(breaks)]);

  @override
  String toString() => 'TrainingLog(${toJson()})';
}

/// Résultat d'un groupe d'exercices enchaînés (0.4.0) : temps total, tours,
/// répétitions en plus.
final class GroupResult {
  const GroupResult({
    required this.groupId,
    required this.completed,
    this.elapsedSeconds,
    this.rounds,
    this.extraReps,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory GroupResult.fromJson(Map<String, Object?> json) {
    return GroupResult(
      groupId: jsonString(json, 'groupId'),
      completed: jsonBool(json, 'completed'),
      elapsedSeconds: jsonIntOrNull(json, 'elapsedSeconds'),
      rounds: jsonIntOrNull(json, 'rounds'),
      extraReps: jsonIntOrNull(json, 'extraReps'),
    );
  }

  /// Groupe (`GroupSpec.groupId`).
  final String groupId;

  /// Le groupe a été fait en entier (dans la limite de temps, s'il y en a une).
  final bool completed;

  /// Temps total, en secondes.
  final int? elapsedSeconds;

  /// Tours complets.
  final int? rounds;

  /// Répétitions faites dans le tour entamé.
  final int? extraReps;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'groupId': groupId,
      'completed': completed,
      if (elapsedSeconds case final v?) 'elapsedSeconds': v,
      if (rounds case final v?) 'rounds': v,
      if (extraReps case final v?) 'extraReps': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  GroupResult copyWith({
    String? groupId,
    bool? completed,
    Object? elapsedSeconds = unset,
    Object? rounds = unset,
    Object? extraReps = unset,
  }) {
    return GroupResult(
      groupId: groupId ?? this.groupId,
      completed: completed ?? this.completed,
      elapsedSeconds: identical(elapsedSeconds, unset) ? this.elapsedSeconds : elapsedSeconds as int?,
      rounds: identical(rounds, unset) ? this.rounds : rounds as int?,
      extraReps: identical(extraReps, unset) ? this.extraReps : extraReps as int?,
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
    checkLength(out, '$path.groupId', groupId.length, 1, null);
    if (elapsedSeconds case final v?) { checkRange(out, '$path.elapsedSeconds', v, 0, 86400); }
    if (rounds case final v?) { checkRange(out, '$path.rounds', v, 0, 1000); }
    if (extraReps case final v?) { checkRange(out, '$path.extraReps', v, 0, 10000); }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is GroupResult && groupId == other.groupId && completed == other.completed && elapsedSeconds == other.elapsedSeconds && rounds == other.rounds && extraReps == other.extraReps;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[groupId, completed, elapsedSeconds, rounds, extraReps]);

  @override
  String toString() => 'GroupResult(${toJson()})';
}

/// Partie d'une série (0.4.0) : mini-série d'un cluster, d'un rest-pause ou
/// de myo-reps, palier d'une dégressive, passage d'un bloc de densité. La
/// série reste UNE ligne du journal (`SetRecord`), dont `reps` est le total.
///
/// Invariant : Au moins `reps` ou `seconds`. Quand toutes les parties d'une
/// série ont des répétitions, leur somme est le `reps` de la série
/// (`SetRecord`).
final class SetPart {
  const SetPart({
    this.reps,
    this.seconds,
    this.externalLoadKg,
    this.restBeforeSeconds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SetPart.fromJson(Map<String, Object?> json) {
    return SetPart(
      reps: jsonIntOrNull(json, 'reps'),
      seconds: jsonIntOrNull(json, 'seconds'),
      externalLoadKg: jsonDoubleOrNull(json, 'externalLoadKg'),
      restBeforeSeconds: jsonIntOrNull(json, 'restBeforeSeconds'),
    );
  }

  /// Répétitions de la partie.
  final int? reps;

  /// Durée de la partie, en secondes.
  final int? seconds;

  /// Charge externe de la partie, si elle diffère de celle de la série
  /// (dégressive).
  final double? externalLoadKg;

  /// Repos pris avant la partie, en secondes.
  final int? restBeforeSeconds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (reps case final v?) 'reps': v,
      if (seconds case final v?) 'seconds': v,
      if (externalLoadKg case final v?) 'externalLoadKg': v,
      if (restBeforeSeconds case final v?) 'restBeforeSeconds': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SetPart copyWith({
    Object? reps = unset,
    Object? seconds = unset,
    Object? externalLoadKg = unset,
    Object? restBeforeSeconds = unset,
  }) {
    return SetPart(
      reps: identical(reps, unset) ? this.reps : reps as int?,
      seconds: identical(seconds, unset) ? this.seconds : seconds as int?,
      externalLoadKg: identical(externalLoadKg, unset) ? this.externalLoadKg : externalLoadKg as double?,
      restBeforeSeconds: identical(restBeforeSeconds, unset) ? this.restBeforeSeconds : restBeforeSeconds as int?,
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
    if (reps case final v?) { checkRange(out, '$path.reps', v, 0, 1000); }
    if (seconds case final v?) { checkRange(out, '$path.seconds', v, 0, 86400); }
    if (externalLoadKg case final v?) { checkRange(out, '$path.externalLoadKg', v, -300, 1000); }
    if (restBeforeSeconds case final v?) { checkRange(out, '$path.restBeforeSeconds', v, 0, 3600); }
    _validateSetPart(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is SetPart && reps == other.reps && seconds == other.seconds && externalLoadKg == other.externalLoadKg && restBeforeSeconds == other.restBeforeSeconds;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[reps, seconds, externalLoadKg, restBeforeSeconds]);

  @override
  String toString() => 'SetPart(${toJson()})';
}
