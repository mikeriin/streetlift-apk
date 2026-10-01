// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Verrou : ce que la revue a figé (D4.6).
///
/// Invariant : `keep_slot` : `slotId` et `exerciseId` ; `require_exercise`,
/// `exclude_exercise` : `exerciseId` ; `keep_day` : `dayIndex`.
final class PlanLock {
  const PlanLock({
    required this.kind,
    this.dayIndex,
    this.slotId,
    this.exerciseId,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanLock.fromJson(Map<String, Object?> json) {
    return PlanLock(
      kind: jsonEnum(json, 'kind', LockKind.fromCode),
      dayIndex: jsonIntOrNull(json, 'dayIndex'),
      slotId: jsonStringOrNull(json, 'slotId'),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
    );
  }

  /// Nature du verrou.
  final LockKind kind;

  /// Jour concerné.
  final int? dayIndex;

  /// Emplacement concerné.
  final String? slotId;

  /// Exercice concerné.
  final String? exerciseId;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (dayIndex case final v?) 'dayIndex': v,
      if (slotId case final v?) 'slotId': v,
      if (exerciseId case final v?) 'exerciseId': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanLock copyWith({
    LockKind? kind,
    Object? dayIndex = unset,
    Object? slotId = unset,
    Object? exerciseId = unset,
  }) {
    return PlanLock(
      kind: kind ?? this.kind,
      dayIndex: identical(dayIndex, unset) ? this.dayIndex : dayIndex as int?,
      slotId: identical(slotId, unset) ? this.slotId : slotId as String?,
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
    if (dayIndex case final v?) {
      checkRange(out, '$path.dayIndex', v, 0, null);
    }
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
    _validatePlanLock(this, path, out);
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
        other is PlanLock &&
            kind == other.kind &&
            dayIndex == other.dayIndex &&
            slotId == other.slotId &&
            exerciseId == other.exerciseId;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[kind, dayIndex, slotId, exerciseId]);

  @override
  String toString() => 'PlanLock(${toJson()})';
}

/// Exercice placé dans une séance (passe 1).
final class PlanSlot {
  const PlanSlot({
    required this.slotId,
    required this.exerciseId,
    required this.role,
    required this.locked,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanSlot.fromJson(Map<String, Object?> json) {
    return PlanSlot(
      slotId: jsonString(json, 'slotId'),
      exerciseId: jsonString(json, 'exerciseId'),
      role: jsonEnum(json, 'role', SlotRole.fromCode),
      locked: jsonBool(json, 'locked'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Identifiant stable de l'emplacement dans le bloc.
  final String slotId;

  /// Exercice.
  final String exerciseId;

  /// Rôle dans la séance.
  final SlotRole role;

  /// Validé par l'utilisateur : ne bouge plus.
  final bool locked;

  /// Pourquoi cet exercice.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'slotId': slotId,
      'exerciseId': exerciseId,
      'role': role.code,
      'locked': locked,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanSlot copyWith({
    String? slotId,
    String? exerciseId,
    SlotRole? role,
    bool? locked,
    List<Reason>? reasons,
  }) {
    return PlanSlot(
      slotId: slotId ?? this.slotId,
      exerciseId: exerciseId ?? this.exerciseId,
      role: role ?? this.role,
      locked: locked ?? this.locked,
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
    checkLength(out, '$path.slotId', slotId.length, 1, null);
    checkLength(out, '$path.exerciseId', exerciseId.length, 1, null);
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanSlot &&
            slotId == other.slotId &&
            exerciseId == other.exerciseId &&
            role == other.role &&
            locked == other.locked &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    slotId,
    exerciseId,
    role,
    locked,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'PlanSlot(${toJson()})';
}

/// Séance type d'un jour d'entraînement (passe 1).
final class PlanDay {
  const PlanDay({
    required this.dayIndex,
    required this.weekday,
    required this.minutesBudget,
    required this.focus,
    required this.slots,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanDay.fromJson(Map<String, Object?> json) {
    return PlanDay(
      dayIndex: jsonInt(json, 'dayIndex'),
      weekday: jsonInt(json, 'weekday'),
      minutesBudget: jsonInt(json, 'minutesBudget'),
      focus: jsonString(json, 'focus'),
      slots: jsonList(
        json,
        'slots',
        (v) => PlanSlot.fromJson(jsonAsObject(v, 'slots')),
      ),
    );
  }

  /// Rang du jour d'entraînement dans la semaine (0 = premier).
  final int dayIndex;

  /// Jour ISO : 1 = lundi … 7 = dimanche.
  final int weekday;

  /// Durée prévue, en minutes.
  final int minutesBudget;

  /// Code du thème de la séance.
  final String focus;

  /// Exercices, dans l'ordre.
  final List<PlanSlot> slots;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dayIndex': dayIndex,
      'weekday': weekday,
      'minutesBudget': minutesBudget,
      'focus': focus,
      'slots': [for (final e in slots) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanDay copyWith({
    int? dayIndex,
    int? weekday,
    int? minutesBudget,
    String? focus,
    List<PlanSlot>? slots,
  }) {
    return PlanDay(
      dayIndex: dayIndex ?? this.dayIndex,
      weekday: weekday ?? this.weekday,
      minutesBudget: minutesBudget ?? this.minutesBudget,
      focus: focus ?? this.focus,
      slots: slots ?? this.slots,
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
    checkRange(out, '$path.dayIndex', dayIndex, 0, null);
    checkRange(out, '$path.weekday', weekday, 1, 7);
    checkRange(out, '$path.minutesBudget', minutesBudget, 0, 300);
    for (var i = 0; i < slots.length; i++) {
      slots[i].collectViolations('$path.slots[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in slots) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanDay &&
            dayIndex == other.dayIndex &&
            weekday == other.weekday &&
            minutesBudget == other.minutesBudget &&
            focus == other.focus &&
            jsonListEquals(slots, other.slots);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    dayIndex,
    weekday,
    minutesBudget,
    focus,
    Object.hashAll(slots),
  ]);

  @override
  String toString() => 'PlanDay(${toJson()})';
}

/// Composante de la note d'un programme (D4.2).
final class ScoreComponent {
  const ScoreComponent({
    required this.code,
    required this.value,
    required this.weight,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ScoreComponent.fromJson(Map<String, Object?> json) {
    return ScoreComponent(
      code: jsonString(json, 'code'),
      value: jsonDouble(json, 'value'),
      weight: jsonDouble(json, 'weight'),
    );
  }

  /// Code de la composante.
  final String code;

  /// Valeur, de 0 à 1.
  final double value;

  /// Poids dans la note.
  final double weight;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{'code': code, 'value': value, 'weight': weight};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ScoreComponent copyWith({String? code, double? value, double? weight}) {
    return ScoreComponent(
      code: code ?? this.code,
      value: value ?? this.value,
      weight: weight ?? this.weight,
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
    checkLength(out, '$path.code', code.length, 1, null);
    checkRange(out, '$path.value', value, 0, 1);
    checkRange(out, '$path.weight', weight, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScoreComponent &&
            code == other.code &&
            value == other.value &&
            weight == other.weight;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[code, value, weight]);

  @override
  String toString() => 'ScoreComponent(${toJson()})';
}

/// Note d'un programme candidat.
final class PlanScore {
  const PlanScore({required this.total, required this.components});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanScore.fromJson(Map<String, Object?> json) {
    return PlanScore(
      total: jsonDouble(json, 'total'),
      components: jsonList(
        json,
        'components',
        (v) => ScoreComponent.fromJson(jsonAsObject(v, 'components')),
      ),
    );
  }

  /// Note globale, de 0 à 1.
  final double total;

  /// Détail.
  final List<ScoreComponent> components;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'total': total,
      'components': [for (final e in components) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanScore copyWith({double? total, List<ScoreComponent>? components}) {
    return PlanScore(
      total: total ?? this.total,
      components: components ?? this.components,
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
    checkRange(out, '$path.total', total, 0, 1);
    for (var i = 0; i < components.length; i++) {
      components[i].collectViolations('$path.components[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in components) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanScore &&
            total == other.total &&
            jsonListEquals(components, other.components);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[total, Object.hashAll(components)]);

  @override
  String toString() => 'PlanScore(${toJson()})';
}

/// Passe 1 : le bloc, ses jours, ses exercices et leurs rôles, sans séries ni
/// répétitions (D4.4).
///
/// Invariant : `dayIndex` = rang dans `days` ; `slotId` uniques dans le bloc.
final class Pass1Plan {
  const Pass1Plan({
    this.schemaVersion = currentSchemaVersion,
    required this.blockId,
    required this.blockIndex,
    required this.weeks,
    required this.startDate,
    required this.seed,
    required this.engineVersion,
    required this.days,
    required this.score,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Pass1Plan.fromJson(Map<String, Object?> json) {
    return Pass1Plan(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      blockId: jsonString(json, 'blockId'),
      blockIndex: jsonInt(json, 'blockIndex'),
      weeks: jsonInt(json, 'weeks'),
      startDate: jsonDate(json, 'startDate'),
      seed: jsonInt(json, 'seed'),
      engineVersion: jsonString(json, 'engineVersion'),
      days: jsonList(
        json,
        'days',
        (v) => PlanDay.fromJson(jsonAsObject(v, 'days')),
      ),
      score: jsonObj(json, 'score', PlanScore.fromJson),
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

  /// Identifiant du bloc.
  final String blockId;

  /// Rang du bloc dans le programme (0 = premier).
  final int blockIndex;

  /// Durée du bloc, en semaines (D4.8).
  final int weeks;

  /// Premier jour du bloc.
  final CivilDate startDate;

  /// Graine utilisée.
  final int seed;

  /// Version de kalis_plan.
  final String engineVersion;

  /// Jours d'entraînement.
  final List<PlanDay> days;

  /// Note du programme retenu.
  final PlanScore score;

  /// Raisons au niveau du bloc.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'blockId': blockId,
      'blockIndex': blockIndex,
      'weeks': weeks,
      'startDate': startDate.iso,
      'seed': seed,
      'engineVersion': engineVersion,
      'days': [for (final e in days) e.toJson()],
      'score': score.toJson(),
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Pass1Plan copyWith({
    int? schemaVersion,
    String? blockId,
    int? blockIndex,
    int? weeks,
    CivilDate? startDate,
    int? seed,
    String? engineVersion,
    List<PlanDay>? days,
    PlanScore? score,
    List<Reason>? reasons,
  }) {
    return Pass1Plan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      blockId: blockId ?? this.blockId,
      blockIndex: blockIndex ?? this.blockIndex,
      weeks: weeks ?? this.weeks,
      startDate: startDate ?? this.startDate,
      seed: seed ?? this.seed,
      engineVersion: engineVersion ?? this.engineVersion,
      days: days ?? this.days,
      score: score ?? this.score,
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
    checkLength(out, '$path.blockId', blockId.length, 1, null);
    checkRange(out, '$path.blockIndex', blockIndex, 0, null);
    checkRange(out, '$path.weeks', weeks, 4, 6);
    checkRange(out, '$path.seed', seed, 0, null);
    for (var i = 0; i < days.length; i++) {
      days[i].collectViolations('$path.days[$i]', out);
    }
    score.collectViolations('$path.score', out);
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    _validatePass1Plan(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in days) {
      e.collectExerciseIds(out);
    }
    score.collectExerciseIds(out);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Pass1Plan &&
            schemaVersion == other.schemaVersion &&
            blockId == other.blockId &&
            blockIndex == other.blockIndex &&
            weeks == other.weeks &&
            startDate == other.startDate &&
            seed == other.seed &&
            engineVersion == other.engineVersion &&
            jsonListEquals(days, other.days) &&
            score == other.score &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    blockId,
    blockIndex,
    weeks,
    startDate,
    seed,
    engineVersion,
    Object.hashAll(days),
    score,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'Pass1Plan(${toJson()})';
}

/// Action de revue de la passe 1 (D4.5).
///
/// Invariant : `can_do`, `cannot_do`, `dislike`, `remove` : `slotId` ; `add`
/// : `dayIndex` et `exerciseId` ; `replace` : `slotId` et
/// `replacementExerciseId`.
final class ReviewAction {
  const ReviewAction({
    required this.kind,
    this.slotId,
    this.dayIndex,
    this.exerciseId,
    this.replacementExerciseId,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ReviewAction.fromJson(Map<String, Object?> json) {
    return ReviewAction(
      kind: jsonEnum(json, 'kind', ReviewKind.fromCode),
      slotId: jsonStringOrNull(json, 'slotId'),
      dayIndex: jsonIntOrNull(json, 'dayIndex'),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      replacementExerciseId: jsonStringOrNull(json, 'replacementExerciseId'),
    );
  }

  /// Action.
  final ReviewKind kind;

  /// Emplacement visé.
  final String? slotId;

  /// Jour visé (ajout).
  final int? dayIndex;

  /// Exercice ajouté.
  final String? exerciseId;

  /// Variante choisie (remplacement).
  final String? replacementExerciseId;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (slotId case final v?) 'slotId': v,
      if (dayIndex case final v?) 'dayIndex': v,
      if (exerciseId case final v?) 'exerciseId': v,
      if (replacementExerciseId case final v?) 'replacementExerciseId': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ReviewAction copyWith({
    ReviewKind? kind,
    Object? slotId = unset,
    Object? dayIndex = unset,
    Object? exerciseId = unset,
    Object? replacementExerciseId = unset,
  }) {
    return ReviewAction(
      kind: kind ?? this.kind,
      slotId: identical(slotId, unset) ? this.slotId : slotId as String?,
      dayIndex: identical(dayIndex, unset) ? this.dayIndex : dayIndex as int?,
      exerciseId: identical(exerciseId, unset)
          ? this.exerciseId
          : exerciseId as String?,
      replacementExerciseId: identical(replacementExerciseId, unset)
          ? this.replacementExerciseId
          : replacementExerciseId as String?,
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
    if (dayIndex case final v?) {
      checkRange(out, '$path.dayIndex', v, 0, null);
    }
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
    if (replacementExerciseId case final v?) {
      checkLength(out, '$path.replacementExerciseId', v.length, 1, null);
    }
    _validateReviewAction(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) {
      out.add(v);
    }
    if (replacementExerciseId case final v?) {
      out.add(v);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewAction &&
            kind == other.kind &&
            slotId == other.slotId &&
            dayIndex == other.dayIndex &&
            exerciseId == other.exerciseId &&
            replacementExerciseId == other.replacementExerciseId;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    slotId,
    dayIndex,
    exerciseId,
    replacementExerciseId,
  ]);

  @override
  String toString() => 'ReviewAction(${toJson()})';
}

/// Ce que la revue apprend sur l'utilisateur (à reporter dans le profil par
/// l'application).
final class ProfileDelta {
  const ProfileDelta({
    required this.knownExerciseIds,
    required this.unknownExerciseIds,
    required this.likedExerciseIds,
    required this.dislikedExerciseIds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ProfileDelta.fromJson(Map<String, Object?> json) {
    return ProfileDelta(
      knownExerciseIds: jsonList(
        json,
        'knownExerciseIds',
        (v) => jsonAsString(v, 'knownExerciseIds'),
      ),
      unknownExerciseIds: jsonList(
        json,
        'unknownExerciseIds',
        (v) => jsonAsString(v, 'unknownExerciseIds'),
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
    );
  }

  /// « Je sais faire ».
  final List<String> knownExerciseIds;

  /// « Je ne sais pas faire ».
  final List<String> unknownExerciseIds;

  /// Exercices ajoutés parce qu'aimés.
  final List<String> likedExerciseIds;

  /// « Je n'aime pas ».
  final List<String> dislikedExerciseIds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'knownExerciseIds': [for (final e in knownExerciseIds) e],
      'unknownExerciseIds': [for (final e in unknownExerciseIds) e],
      'likedExerciseIds': [for (final e in likedExerciseIds) e],
      'dislikedExerciseIds': [for (final e in dislikedExerciseIds) e],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ProfileDelta copyWith({
    List<String>? knownExerciseIds,
    List<String>? unknownExerciseIds,
    List<String>? likedExerciseIds,
    List<String>? dislikedExerciseIds,
  }) {
    return ProfileDelta(
      knownExerciseIds: knownExerciseIds ?? this.knownExerciseIds,
      unknownExerciseIds: unknownExerciseIds ?? this.unknownExerciseIds,
      likedExerciseIds: likedExerciseIds ?? this.likedExerciseIds,
      dislikedExerciseIds: dislikedExerciseIds ?? this.dislikedExerciseIds,
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
    for (var i = 0; i < knownExerciseIds.length; i++) {
      checkLength(
        out,
        '$path.knownExerciseIds[$i]',
        knownExerciseIds[i].length,
        1,
        null,
      );
    }
    for (var i = 0; i < unknownExerciseIds.length; i++) {
      checkLength(
        out,
        '$path.unknownExerciseIds[$i]',
        unknownExerciseIds[i].length,
        1,
        null,
      );
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
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.addAll(knownExerciseIds);
    out.addAll(unknownExerciseIds);
    out.addAll(likedExerciseIds);
    out.addAll(dislikedExerciseIds);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileDelta &&
            jsonListEquals(knownExerciseIds, other.knownExerciseIds) &&
            jsonListEquals(unknownExerciseIds, other.unknownExerciseIds) &&
            jsonListEquals(likedExerciseIds, other.likedExerciseIds) &&
            jsonListEquals(dislikedExerciseIds, other.dislikedExerciseIds);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    Object.hashAll(knownExerciseIds),
    Object.hashAll(unknownExerciseIds),
    Object.hashAll(likedExerciseIds),
    Object.hashAll(dislikedExerciseIds),
  ]);

  @override
  String toString() => 'ProfileDelta(${toJson()})';
}

/// Changement typé entre deux programmes.
final class PlanChange {
  const PlanChange({
    required this.kind,
    this.dayIndex,
    this.weekIndex,
    this.slotId,
    this.fromExerciseId,
    this.toExerciseId,
    this.fromDayIndex,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanChange.fromJson(Map<String, Object?> json) {
    return PlanChange(
      kind: jsonEnum(json, 'kind', ChangeKind.fromCode),
      dayIndex: jsonIntOrNull(json, 'dayIndex'),
      weekIndex: jsonIntOrNull(json, 'weekIndex'),
      slotId: jsonStringOrNull(json, 'slotId'),
      fromExerciseId: jsonStringOrNull(json, 'fromExerciseId'),
      toExerciseId: jsonStringOrNull(json, 'toExerciseId'),
      fromDayIndex: jsonIntOrNull(json, 'fromDayIndex'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Nature du changement.
  final ChangeKind kind;

  /// Jour concerné.
  final int? dayIndex;

  /// Semaine concernée (prescriptions).
  final int? weekIndex;

  /// Emplacement concerné.
  final String? slotId;

  /// Exercice avant.
  final String? fromExerciseId;

  /// Exercice après.
  final String? toExerciseId;

  /// Jour d'origine (déplacement).
  final int? fromDayIndex;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (dayIndex case final v?) 'dayIndex': v,
      if (weekIndex case final v?) 'weekIndex': v,
      if (slotId case final v?) 'slotId': v,
      if (fromExerciseId case final v?) 'fromExerciseId': v,
      if (toExerciseId case final v?) 'toExerciseId': v,
      if (fromDayIndex case final v?) 'fromDayIndex': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanChange copyWith({
    ChangeKind? kind,
    Object? dayIndex = unset,
    Object? weekIndex = unset,
    Object? slotId = unset,
    Object? fromExerciseId = unset,
    Object? toExerciseId = unset,
    Object? fromDayIndex = unset,
    List<Reason>? reasons,
  }) {
    return PlanChange(
      kind: kind ?? this.kind,
      dayIndex: identical(dayIndex, unset) ? this.dayIndex : dayIndex as int?,
      weekIndex: identical(weekIndex, unset)
          ? this.weekIndex
          : weekIndex as int?,
      slotId: identical(slotId, unset) ? this.slotId : slotId as String?,
      fromExerciseId: identical(fromExerciseId, unset)
          ? this.fromExerciseId
          : fromExerciseId as String?,
      toExerciseId: identical(toExerciseId, unset)
          ? this.toExerciseId
          : toExerciseId as String?,
      fromDayIndex: identical(fromDayIndex, unset)
          ? this.fromDayIndex
          : fromDayIndex as int?,
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
    if (dayIndex case final v?) {
      checkRange(out, '$path.dayIndex', v, 0, null);
    }
    if (weekIndex case final v?) {
      checkRange(out, '$path.weekIndex', v, 0, null);
    }
    if (fromExerciseId case final v?) {
      checkLength(out, '$path.fromExerciseId', v.length, 1, null);
    }
    if (toExerciseId case final v?) {
      checkLength(out, '$path.toExerciseId', v.length, 1, null);
    }
    if (fromDayIndex case final v?) {
      checkRange(out, '$path.fromDayIndex', v, 0, null);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (fromExerciseId case final v?) {
      out.add(v);
    }
    if (toExerciseId case final v?) {
      out.add(v);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanChange &&
            kind == other.kind &&
            dayIndex == other.dayIndex &&
            weekIndex == other.weekIndex &&
            slotId == other.slotId &&
            fromExerciseId == other.fromExerciseId &&
            toExerciseId == other.toExerciseId &&
            fromDayIndex == other.fromDayIndex &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    dayIndex,
    weekIndex,
    slotId,
    fromExerciseId,
    toExerciseId,
    fromDayIndex,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'PlanChange(${toJson()})';
}

/// Ce qui a bougé entre deux programmes, et pourquoi (D4.6).
final class PlanDiff {
  const PlanDiff({required this.changes});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanDiff.fromJson(Map<String, Object?> json) {
    return PlanDiff(
      changes: jsonList(
        json,
        'changes',
        (v) => PlanChange.fromJson(jsonAsObject(v, 'changes')),
      ),
    );
  }

  /// Changements, dans un ordre stable.
  final List<PlanChange> changes;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'changes': [for (final e in changes) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanDiff copyWith({List<PlanChange>? changes}) {
    return PlanDiff(changes: changes ?? this.changes);
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    for (var i = 0; i < changes.length; i++) {
      changes[i].collectViolations('$path.changes[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in changes) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanDiff && jsonListEquals(changes, other.changes);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[Object.hashAll(changes)]);

  @override
  String toString() => 'PlanDiff(${toJson()})';
}

/// Résultat d'une action de revue : programme ré-optimisé, diff, verrous à
/// jour.
final class ReviewResult {
  const ReviewResult({
    required this.plan,
    required this.diff,
    required this.locks,
    required this.profileDelta,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ReviewResult.fromJson(Map<String, Object?> json) {
    return ReviewResult(
      plan: jsonObj(json, 'plan', Pass1Plan.fromJson),
      diff: jsonObj(json, 'diff', PlanDiff.fromJson),
      locks: jsonList(
        json,
        'locks',
        (v) => PlanLock.fromJson(jsonAsObject(v, 'locks')),
      ),
      profileDelta: jsonObj(json, 'profileDelta', ProfileDelta.fromJson),
    );
  }

  /// Programme après l'action.
  final Pass1Plan plan;

  /// Ce qui a bougé.
  final PlanDiff diff;

  /// Verrous à repasser dans la requête suivante.
  final List<PlanLock> locks;

  /// Ce que l'action apprend sur l'utilisateur.
  final ProfileDelta profileDelta;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'plan': plan.toJson(),
      'diff': diff.toJson(),
      'locks': [for (final e in locks) e.toJson()],
      'profileDelta': profileDelta.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ReviewResult copyWith({
    Pass1Plan? plan,
    PlanDiff? diff,
    List<PlanLock>? locks,
    ProfileDelta? profileDelta,
  }) {
    return ReviewResult(
      plan: plan ?? this.plan,
      diff: diff ?? this.diff,
      locks: locks ?? this.locks,
      profileDelta: profileDelta ?? this.profileDelta,
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
    plan.collectViolations('$path.plan', out);
    diff.collectViolations('$path.diff', out);
    for (var i = 0; i < locks.length; i++) {
      locks[i].collectViolations('$path.locks[$i]', out);
    }
    profileDelta.collectViolations('$path.profileDelta', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    plan.collectExerciseIds(out);
    diff.collectExerciseIds(out);
    for (final e in locks) {
      e.collectExerciseIds(out);
    }
    profileDelta.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewResult &&
            plan == other.plan &&
            diff == other.diff &&
            jsonListEquals(locks, other.locks) &&
            profileDelta == other.profileDelta;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    plan,
    diff,
    Object.hashAll(locks),
    profileDelta,
  ]);

  @override
  String toString() => 'ReviewResult(${toJson()})';
}

/// Variante proposée pour un emplacement.
final class Variant {
  const Variant({
    required this.exerciseId,
    required this.kind,
    required this.similarity,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Variant.fromJson(Map<String, Object?> json) {
    return Variant(
      exerciseId: jsonString(json, 'exerciseId'),
      kind: jsonEnum(json, 'kind', VariantKind.fromCode),
      similarity: jsonDouble(json, 'similarity'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Exercice proposé.
  final String exerciseId;

  /// Plus facile, équivalente, autre matériel, autre.
  final VariantKind kind;

  /// Proximité avec l'exercice remplacé, de 0 à 1.
  final double similarity;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'kind': kind.code,
      'similarity': similarity,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Variant copyWith({
    String? exerciseId,
    VariantKind? kind,
    double? similarity,
    List<Reason>? reasons,
  }) {
    return Variant(
      exerciseId: exerciseId ?? this.exerciseId,
      kind: kind ?? this.kind,
      similarity: similarity ?? this.similarity,
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
    checkRange(out, '$path.similarity', similarity, 0, 1);
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Variant &&
            exerciseId == other.exerciseId &&
            kind == other.kind &&
            similarity == other.similarity &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    exerciseId,
    kind,
    similarity,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'Variant(${toJson()})';
}

/// Variantes d'un emplacement : 3 ciblées + toutes (D4.5).
final class VariantSet {
  const VariantSet({
    required this.slotId,
    required this.targeted,
    required this.all,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory VariantSet.fromJson(Map<String, Object?> json) {
    return VariantSet(
      slotId: jsonString(json, 'slotId'),
      targeted: jsonList(
        json,
        'targeted',
        (v) => Variant.fromJson(jsonAsObject(v, 'targeted')),
      ),
      all: jsonList(
        json,
        'all',
        (v) => Variant.fromJson(jsonAsObject(v, 'all')),
      ),
    );
  }

  /// Emplacement.
  final String slotId;

  /// Jusqu'à 3 variantes ciblées.
  final List<Variant> targeted;

  /// Toutes les variantes admissibles, par proximité décroissante.
  final List<Variant> all;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'slotId': slotId,
      'targeted': [for (final e in targeted) e.toJson()],
      'all': [for (final e in all) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  VariantSet copyWith({
    String? slotId,
    List<Variant>? targeted,
    List<Variant>? all,
  }) {
    return VariantSet(
      slotId: slotId ?? this.slotId,
      targeted: targeted ?? this.targeted,
      all: all ?? this.all,
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
    checkLength(out, '$path.slotId', slotId.length, 1, null);
    checkLength(out, '$path.targeted', targeted.length, null, 3);
    for (var i = 0; i < targeted.length; i++) {
      targeted[i].collectViolations('$path.targeted[$i]', out);
    }
    for (var i = 0; i < all.length; i++) {
      all[i].collectViolations('$path.all[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in targeted) {
      e.collectExerciseIds(out);
    }
    for (final e in all) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VariantSet &&
            slotId == other.slotId &&
            jsonListEquals(targeted, other.targeted) &&
            jsonListEquals(all, other.all);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    slotId,
    Object.hashAll(targeted),
    Object.hashAll(all),
  ]);

  @override
  String toString() => 'VariantSet(${toJson()})';
}

/// Prescription d'un exercice pour une séance (passe 2, D4.7).
///
/// Invariant : Une seule famille de mesure : répétitions, temps, distance ou
/// calories ; bornes basses ≤ bornes hautes, renseignées ensemble.
final class ExercisePrescription {
  const ExercisePrescription({
    required this.slotId,
    required this.exerciseId,
    required this.sets,
    this.repsLow,
    this.repsHigh,
    this.secondsLow,
    this.secondsHigh,
    this.distanceMeters,
    this.calories,
    required this.targetFlames,
    required this.restSeconds,
    this.startLoadKg,
    required this.toCalibrate,
    required this.loadBasis,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ExercisePrescription.fromJson(Map<String, Object?> json) {
    return ExercisePrescription(
      slotId: jsonString(json, 'slotId'),
      exerciseId: jsonString(json, 'exerciseId'),
      sets: jsonInt(json, 'sets'),
      repsLow: jsonIntOrNull(json, 'repsLow'),
      repsHigh: jsonIntOrNull(json, 'repsHigh'),
      secondsLow: jsonIntOrNull(json, 'secondsLow'),
      secondsHigh: jsonIntOrNull(json, 'secondsHigh'),
      distanceMeters: jsonDoubleOrNull(json, 'distanceMeters'),
      calories: jsonDoubleOrNull(json, 'calories'),
      targetFlames: jsonInt(json, 'targetFlames'),
      restSeconds: jsonInt(json, 'restSeconds'),
      startLoadKg: jsonDoubleOrNull(json, 'startLoadKg'),
      toCalibrate: jsonBool(json, 'toCalibrate'),
      loadBasis: jsonEnum(json, 'loadBasis', LoadBasis.fromCode),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Emplacement.
  final String slotId;

  /// Exercice.
  final String exerciseId;

  /// Nombre de séries.
  final int sets;

  /// Bas de la plage de répétitions.
  final int? repsLow;

  /// Haut de la plage de répétitions.
  final int? repsHigh;

  /// Bas de la plage de temps, en secondes.
  final int? secondsLow;

  /// Haut de la plage de temps, en secondes.
  final int? secondsHigh;

  /// Distance par série, en mètres.
  final double? distanceMeters;

  /// Calories par série.
  final double? calories;

  /// Flammes visées.
  final int targetFlames;

  /// Repos entre les séries, en secondes.
  final int restSeconds;

  /// Charge externe de départ, en kg (prudente).
  final double? startLoadKg;

  /// Charge à calibrer sur les premières séances.
  final bool toCalibrate;

  /// Ce que désigne la charge.
  final LoadBasis loadBasis;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'slotId': slotId,
      'exerciseId': exerciseId,
      'sets': sets,
      if (repsLow case final v?) 'repsLow': v,
      if (repsHigh case final v?) 'repsHigh': v,
      if (secondsLow case final v?) 'secondsLow': v,
      if (secondsHigh case final v?) 'secondsHigh': v,
      if (distanceMeters case final v?) 'distanceMeters': v,
      if (calories case final v?) 'calories': v,
      'targetFlames': targetFlames,
      'restSeconds': restSeconds,
      if (startLoadKg case final v?) 'startLoadKg': v,
      'toCalibrate': toCalibrate,
      'loadBasis': loadBasis.code,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ExercisePrescription copyWith({
    String? slotId,
    String? exerciseId,
    int? sets,
    Object? repsLow = unset,
    Object? repsHigh = unset,
    Object? secondsLow = unset,
    Object? secondsHigh = unset,
    Object? distanceMeters = unset,
    Object? calories = unset,
    int? targetFlames,
    int? restSeconds,
    Object? startLoadKg = unset,
    bool? toCalibrate,
    LoadBasis? loadBasis,
    List<Reason>? reasons,
  }) {
    return ExercisePrescription(
      slotId: slotId ?? this.slotId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      repsLow: identical(repsLow, unset) ? this.repsLow : repsLow as int?,
      repsHigh: identical(repsHigh, unset) ? this.repsHigh : repsHigh as int?,
      secondsLow: identical(secondsLow, unset)
          ? this.secondsLow
          : secondsLow as int?,
      secondsHigh: identical(secondsHigh, unset)
          ? this.secondsHigh
          : secondsHigh as int?,
      distanceMeters: identical(distanceMeters, unset)
          ? this.distanceMeters
          : distanceMeters as double?,
      calories: identical(calories, unset)
          ? this.calories
          : calories as double?,
      targetFlames: targetFlames ?? this.targetFlames,
      restSeconds: restSeconds ?? this.restSeconds,
      startLoadKg: identical(startLoadKg, unset)
          ? this.startLoadKg
          : startLoadKg as double?,
      toCalibrate: toCalibrate ?? this.toCalibrate,
      loadBasis: loadBasis ?? this.loadBasis,
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
    checkLength(out, '$path.slotId', slotId.length, 1, null);
    checkLength(out, '$path.exerciseId', exerciseId.length, 1, null);
    checkRange(out, '$path.sets', sets, 1, 20);
    if (repsLow case final v?) {
      checkRange(out, '$path.repsLow', v, 1, 1000);
    }
    if (repsHigh case final v?) {
      checkRange(out, '$path.repsHigh', v, 1, 1000);
    }
    if (secondsLow case final v?) {
      checkRange(out, '$path.secondsLow', v, 1, 86400);
    }
    if (secondsHigh case final v?) {
      checkRange(out, '$path.secondsHigh', v, 1, 86400);
    }
    if (distanceMeters case final v?) {
      checkRange(out, '$path.distanceMeters', v, 0, null);
    }
    if (calories case final v?) {
      checkRange(out, '$path.calories', v, 0, null);
    }
    checkRange(out, '$path.targetFlames', targetFlames, 1, 10);
    checkRange(out, '$path.restSeconds', restSeconds, 0, 900);
    if (startLoadKg case final v?) {
      checkRange(out, '$path.startLoadKg', v, -300, 1000);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    _validateExercisePrescription(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExercisePrescription &&
            slotId == other.slotId &&
            exerciseId == other.exerciseId &&
            sets == other.sets &&
            repsLow == other.repsLow &&
            repsHigh == other.repsHigh &&
            secondsLow == other.secondsLow &&
            secondsHigh == other.secondsHigh &&
            distanceMeters == other.distanceMeters &&
            calories == other.calories &&
            targetFlames == other.targetFlames &&
            restSeconds == other.restSeconds &&
            startLoadKg == other.startLoadKg &&
            toCalibrate == other.toCalibrate &&
            loadBasis == other.loadBasis &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    slotId,
    exerciseId,
    sets,
    repsLow,
    repsHigh,
    secondsLow,
    secondsHigh,
    distanceMeters,
    calories,
    targetFlames,
    restSeconds,
    startLoadKg,
    toCalibrate,
    loadBasis,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'ExercisePrescription(${toJson()})';
}

/// Prescriptions d'une séance.
final class DayPrescription {
  const DayPrescription({required this.dayIndex, required this.items});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DayPrescription.fromJson(Map<String, Object?> json) {
    return DayPrescription(
      dayIndex: jsonInt(json, 'dayIndex'),
      items: jsonList(
        json,
        'items',
        (v) => ExercisePrescription.fromJson(jsonAsObject(v, 'items')),
      ),
    );
  }

  /// Jour d'entraînement.
  final int dayIndex;

  /// Exercices, dans l'ordre.
  final List<ExercisePrescription> items;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dayIndex': dayIndex,
      'items': [for (final e in items) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DayPrescription copyWith({int? dayIndex, List<ExercisePrescription>? items}) {
    return DayPrescription(
      dayIndex: dayIndex ?? this.dayIndex,
      items: items ?? this.items,
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
    checkRange(out, '$path.dayIndex', dayIndex, 0, null);
    for (var i = 0; i < items.length; i++) {
      items[i].collectViolations('$path.items[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in items) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DayPrescription &&
            dayIndex == other.dayIndex &&
            jsonListEquals(items, other.items);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[dayIndex, Object.hashAll(items)]);

  @override
  String toString() => 'DayPrescription(${toJson()})';
}

/// Prescriptions d'une semaine du bloc.
final class WeekPrescription {
  const WeekPrescription({
    required this.weekIndex,
    required this.kind,
    required this.days,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory WeekPrescription.fromJson(Map<String, Object?> json) {
    return WeekPrescription(
      weekIndex: jsonInt(json, 'weekIndex'),
      kind: jsonEnum(json, 'kind', WeekKind.fromCode),
      days: jsonList(
        json,
        'days',
        (v) => DayPrescription.fromJson(jsonAsObject(v, 'days')),
      ),
    );
  }

  /// Semaine dans le bloc (0 = première).
  final int weekIndex;

  /// Nature de la semaine.
  final WeekKind kind;

  /// Séances.
  final List<DayPrescription> days;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'weekIndex': weekIndex,
      'kind': kind.code,
      'days': [for (final e in days) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  WeekPrescription copyWith({
    int? weekIndex,
    WeekKind? kind,
    List<DayPrescription>? days,
  }) {
    return WeekPrescription(
      weekIndex: weekIndex ?? this.weekIndex,
      kind: kind ?? this.kind,
      days: days ?? this.days,
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
    checkRange(out, '$path.weekIndex', weekIndex, 0, null);
    for (var i = 0; i < days.length; i++) {
      days[i].collectViolations('$path.days[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in days) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WeekPrescription &&
            weekIndex == other.weekIndex &&
            kind == other.kind &&
            jsonListEquals(days, other.days);
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[weekIndex, kind, Object.hashAll(days)]);

  @override
  String toString() => 'WeekPrescription(${toJson()})';
}

/// Passe 2 : prescriptions par semaine.
///
/// Invariant : `weekIndex` = rang dans `weeks`.
final class Pass2Plan {
  const Pass2Plan({
    this.schemaVersion = currentSchemaVersion,
    required this.blockId,
    required this.engineVersion,
    required this.weeks,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Pass2Plan.fromJson(Map<String, Object?> json) {
    return Pass2Plan(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      blockId: jsonString(json, 'blockId'),
      engineVersion: jsonString(json, 'engineVersion'),
      weeks: jsonList(
        json,
        'weeks',
        (v) => WeekPrescription.fromJson(jsonAsObject(v, 'weeks')),
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

  /// Identifiant du bloc (celui de la passe 1).
  final String blockId;

  /// Version de kalis_plan.
  final String engineVersion;

  /// Semaines du bloc.
  final List<WeekPrescription> weeks;

  /// Logique du bloc.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'blockId': blockId,
      'engineVersion': engineVersion,
      'weeks': [for (final e in weeks) e.toJson()],
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Pass2Plan copyWith({
    int? schemaVersion,
    String? blockId,
    String? engineVersion,
    List<WeekPrescription>? weeks,
    List<Reason>? reasons,
  }) {
    return Pass2Plan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      blockId: blockId ?? this.blockId,
      engineVersion: engineVersion ?? this.engineVersion,
      weeks: weeks ?? this.weeks,
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
    checkLength(out, '$path.blockId', blockId.length, 1, null);
    for (var i = 0; i < weeks.length; i++) {
      weeks[i].collectViolations('$path.weeks[$i]', out);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    _validatePass2Plan(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in weeks) {
      e.collectExerciseIds(out);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Pass2Plan &&
            schemaVersion == other.schemaVersion &&
            blockId == other.blockId &&
            engineVersion == other.engineVersion &&
            jsonListEquals(weeks, other.weeks) &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    blockId,
    engineVersion,
    Object.hashAll(weeks),
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'Pass2Plan(${toJson()})';
}

/// Bloc de programme complet (passes 1 et 2), stocké par l'application.
///
/// Invariant : Même `blockId` ; autant de semaines de passe 2 que
/// `pass1.weeks` ; chaque prescription renvoie à un emplacement de la passe
/// 1.
final class ProgramBlock {
  const ProgramBlock({
    this.schemaVersion = currentSchemaVersion,
    required this.pass1,
    required this.pass2,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ProgramBlock.fromJson(Map<String, Object?> json) {
    return ProgramBlock(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      pass1: jsonObj(json, 'pass1', Pass1Plan.fromJson),
      pass2: jsonObj(json, 'pass2', Pass2Plan.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Passe 1.
  final Pass1Plan pass1;

  /// Passe 2.
  final Pass2Plan pass2;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'pass1': pass1.toJson(),
      'pass2': pass2.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ProgramBlock copyWith({
    int? schemaVersion,
    Pass1Plan? pass1,
    Pass2Plan? pass2,
  }) {
    return ProgramBlock(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      pass1: pass1 ?? this.pass1,
      pass2: pass2 ?? this.pass2,
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
    pass1.collectViolations('$path.pass1', out);
    pass2.collectViolations('$path.pass2', out);
    _validateProgramBlock(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    pass1.collectExerciseIds(out);
    pass2.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProgramBlock &&
            schemaVersion == other.schemaVersion &&
            pass1 == other.pass1 &&
            pass2 == other.pass2;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, pass1, pass2]);

  @override
  String toString() => 'ProgramBlock(${toJson()})';
}

/// Requête de création d'un programme.
final class PlanRequest {
  const PlanRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.seed,
    required this.startDate,
    this.blockWeeks,
    required this.locks,
    this.previousBlock,
    this.adaptation,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory PlanRequest.fromJson(Map<String, Object?> json) {
    return PlanRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      seed: jsonInt(json, 'seed'),
      startDate: jsonDate(json, 'startDate'),
      blockWeeks: jsonIntOrNull(json, 'blockWeeks'),
      locks: jsonList(
        json,
        'locks',
        (v) => PlanLock.fromJson(jsonAsObject(v, 'locks')),
      ),
      previousBlock: jsonObjOrNull(
        json,
        'previousBlock',
        ProgramBlock.fromJson,
      ),
      adaptation: jsonObjOrNull(json, 'adaptation', AdaptationSummary.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Profil.
  final AthleteProfile profile;

  /// Graine (« Autre proposition » = nouvelle graine, D4.3).
  final int seed;

  /// Premier jour du bloc.
  final CivilDate startDate;

  /// Durée souhaitée du bloc, en semaines.
  final int? blockWeeks;

  /// Verrous.
  final List<PlanLock> locks;

  /// Bloc précédent.
  final ProgramBlock? previousBlock;

  /// Résumé d'adaptation.
  final AdaptationSummary? adaptation;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'seed': seed,
      'startDate': startDate.iso,
      if (blockWeeks case final v?) 'blockWeeks': v,
      'locks': [for (final e in locks) e.toJson()],
      if (previousBlock case final v?) 'previousBlock': v.toJson(),
      if (adaptation case final v?) 'adaptation': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  PlanRequest copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    int? seed,
    CivilDate? startDate,
    Object? blockWeeks = unset,
    List<PlanLock>? locks,
    Object? previousBlock = unset,
    Object? adaptation = unset,
  }) {
    return PlanRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      seed: seed ?? this.seed,
      startDate: startDate ?? this.startDate,
      blockWeeks: identical(blockWeeks, unset)
          ? this.blockWeeks
          : blockWeeks as int?,
      locks: locks ?? this.locks,
      previousBlock: identical(previousBlock, unset)
          ? this.previousBlock
          : previousBlock as ProgramBlock?,
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
    if (blockWeeks case final v?) {
      checkRange(out, '$path.blockWeeks', v, 4, 6);
    }
    for (var i = 0; i < locks.length; i++) {
      locks[i].collectViolations('$path.locks[$i]', out);
    }
    if (previousBlock case final v?) {
      v.collectViolations('$path.previousBlock', out);
    }
    if (adaptation case final v?) {
      v.collectViolations('$path.adaptation', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    for (final e in locks) {
      e.collectExerciseIds(out);
    }
    previousBlock?.collectExerciseIds(out);
    adaptation?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlanRequest &&
            schemaVersion == other.schemaVersion &&
            profile == other.profile &&
            seed == other.seed &&
            startDate == other.startDate &&
            blockWeeks == other.blockWeeks &&
            jsonListEquals(locks, other.locks) &&
            previousBlock == other.previousBlock &&
            adaptation == other.adaptation;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    profile,
    seed,
    startDate,
    blockWeeks,
    Object.hashAll(locks),
    previousBlock,
    adaptation,
  ]);

  @override
  String toString() => 'PlanRequest(${toJson()})';
}

/// Requête du bloc suivant (D4.8).
final class NextBlockRequest {
  const NextBlockRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.seed,
    required this.startDate,
    required this.previous,
    required this.adaptation,
    required this.locks,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory NextBlockRequest.fromJson(Map<String, Object?> json) {
    return NextBlockRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      seed: jsonInt(json, 'seed'),
      startDate: jsonDate(json, 'startDate'),
      previous: jsonObj(json, 'previous', ProgramBlock.fromJson),
      adaptation: jsonObj(json, 'adaptation', AdaptationSummary.fromJson),
      locks: jsonList(
        json,
        'locks',
        (v) => PlanLock.fromJson(jsonAsObject(v, 'locks')),
      ),
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

  /// Premier jour du nouveau bloc.
  final CivilDate startDate;

  /// Bloc qui se termine.
  final ProgramBlock previous;

  /// Résumé d'adaptation.
  final AdaptationSummary adaptation;

  /// Verrous.
  final List<PlanLock> locks;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'seed': seed,
      'startDate': startDate.iso,
      'previous': previous.toJson(),
      'adaptation': adaptation.toJson(),
      'locks': [for (final e in locks) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  NextBlockRequest copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    int? seed,
    CivilDate? startDate,
    ProgramBlock? previous,
    AdaptationSummary? adaptation,
    List<PlanLock>? locks,
  }) {
    return NextBlockRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      seed: seed ?? this.seed,
      startDate: startDate ?? this.startDate,
      previous: previous ?? this.previous,
      adaptation: adaptation ?? this.adaptation,
      locks: locks ?? this.locks,
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
    previous.collectViolations('$path.previous', out);
    adaptation.collectViolations('$path.adaptation', out);
    for (var i = 0; i < locks.length; i++) {
      locks[i].collectViolations('$path.locks[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    previous.collectExerciseIds(out);
    adaptation.collectExerciseIds(out);
    for (final e in locks) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NextBlockRequest &&
            schemaVersion == other.schemaVersion &&
            profile == other.profile &&
            seed == other.seed &&
            startDate == other.startDate &&
            previous == other.previous &&
            adaptation == other.adaptation &&
            jsonListEquals(locks, other.locks);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    profile,
    seed,
    startDate,
    previous,
    adaptation,
    Object.hashAll(locks),
  ]);

  @override
  String toString() => 'NextBlockRequest(${toJson()})';
}

/// Requête de restructuration (D5.1 : le moteur dynamique appelle le
/// statique).
///
/// Invariant : Portée `session` ⇒ `dayIndex` renseigné.
final class RestructureRequest {
  const RestructureRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.seed,
    required this.today,
    required this.current,
    required this.scope,
    this.dayIndex,
    this.fromWeekIndex,
    required this.reasons,
    required this.locks,
    this.adaptation,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory RestructureRequest.fromJson(Map<String, Object?> json) {
    return RestructureRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      seed: jsonInt(json, 'seed'),
      today: jsonDate(json, 'today'),
      current: jsonObj(json, 'current', ProgramBlock.fromJson),
      scope: jsonEnum(json, 'scope', RestructureScope.fromCode),
      dayIndex: jsonIntOrNull(json, 'dayIndex'),
      fromWeekIndex: jsonIntOrNull(json, 'fromWeekIndex'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
      locks: jsonList(
        json,
        'locks',
        (v) => PlanLock.fromJson(jsonAsObject(v, 'locks')),
      ),
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

  /// Bloc en cours.
  final ProgramBlock current;

  /// Portée.
  final RestructureScope scope;

  /// Jour visé (portée séance).
  final int? dayIndex;

  /// Première semaine modifiable.
  final int? fromWeekIndex;

  /// Raisons de la restructuration.
  final List<Reason> reasons;

  /// Verrous.
  final List<PlanLock> locks;

  /// Résumé d'adaptation.
  final AdaptationSummary? adaptation;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'seed': seed,
      'today': today.iso,
      'current': current.toJson(),
      'scope': scope.code,
      if (dayIndex case final v?) 'dayIndex': v,
      if (fromWeekIndex case final v?) 'fromWeekIndex': v,
      'reasons': [for (final e in reasons) e.toJson()],
      'locks': [for (final e in locks) e.toJson()],
      if (adaptation case final v?) 'adaptation': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  RestructureRequest copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    int? seed,
    CivilDate? today,
    ProgramBlock? current,
    RestructureScope? scope,
    Object? dayIndex = unset,
    Object? fromWeekIndex = unset,
    List<Reason>? reasons,
    List<PlanLock>? locks,
    Object? adaptation = unset,
  }) {
    return RestructureRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      seed: seed ?? this.seed,
      today: today ?? this.today,
      current: current ?? this.current,
      scope: scope ?? this.scope,
      dayIndex: identical(dayIndex, unset) ? this.dayIndex : dayIndex as int?,
      fromWeekIndex: identical(fromWeekIndex, unset)
          ? this.fromWeekIndex
          : fromWeekIndex as int?,
      reasons: reasons ?? this.reasons,
      locks: locks ?? this.locks,
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
    current.collectViolations('$path.current', out);
    if (dayIndex case final v?) {
      checkRange(out, '$path.dayIndex', v, 0, null);
    }
    if (fromWeekIndex case final v?) {
      checkRange(out, '$path.fromWeekIndex', v, 0, null);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    for (var i = 0; i < locks.length; i++) {
      locks[i].collectViolations('$path.locks[$i]', out);
    }
    if (adaptation case final v?) {
      v.collectViolations('$path.adaptation', out);
    }
    _validateRestructureRequest(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    current.collectExerciseIds(out);
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
    for (final e in locks) {
      e.collectExerciseIds(out);
    }
    adaptation?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RestructureRequest &&
            schemaVersion == other.schemaVersion &&
            profile == other.profile &&
            seed == other.seed &&
            today == other.today &&
            current == other.current &&
            scope == other.scope &&
            dayIndex == other.dayIndex &&
            fromWeekIndex == other.fromWeekIndex &&
            jsonListEquals(reasons, other.reasons) &&
            jsonListEquals(locks, other.locks) &&
            adaptation == other.adaptation;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    profile,
    seed,
    today,
    current,
    scope,
    dayIndex,
    fromWeekIndex,
    Object.hashAll(reasons),
    Object.hashAll(locks),
    adaptation,
  ]);

  @override
  String toString() => 'RestructureRequest(${toJson()})';
}

/// Bloc proposé et ce qui change par rapport au précédent.
final class BlockProposal {
  const BlockProposal({required this.block, required this.diff});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory BlockProposal.fromJson(Map<String, Object?> json) {
    return BlockProposal(
      block: jsonObj(json, 'block', ProgramBlock.fromJson),
      diff: jsonObj(json, 'diff', PlanDiff.fromJson),
    );
  }

  /// Bloc proposé.
  final ProgramBlock block;

  /// Changements par rapport au bloc de référence.
  final PlanDiff diff;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{'block': block.toJson(), 'diff': diff.toJson()};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  BlockProposal copyWith({ProgramBlock? block, PlanDiff? diff}) {
    return BlockProposal(block: block ?? this.block, diff: diff ?? this.diff);
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    block.collectViolations('$path.block', out);
    diff.collectViolations('$path.diff', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    block.collectExerciseIds(out);
    diff.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BlockProposal && block == other.block && diff == other.diff;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[block, diff]);

  @override
  String toString() => 'BlockProposal(${toJson()})';
}
