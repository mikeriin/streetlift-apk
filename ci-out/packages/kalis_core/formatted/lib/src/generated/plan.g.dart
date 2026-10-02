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
/// répétitions (D4.4). C'est la semaine type du bloc ; la passe 2 fait foi
/// semaine par semaine.
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
    this.intent,
    this.skillLadders,
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
      intent: jsonObjOrNull(json, 'intent', BlockIntent.fromJson),
      skillLadders: jsonListOrNull(
        json,
        'skillLadders',
        (v) => SkillLadder.fromJson(jsonAsObject(v, 'skillLadders')),
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

  /// Durée du bloc, en semaines. `kalis_plan` produit des blocs de 4 à 6
  /// semaines (D4.8) ; un programme importé (celui du propriétaire, D5.10) peut
  /// en compter jusqu'à 52.
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

  /// Intention du bloc : sa place dans la saison (0.4.0).
  final BlockIntent? intent;

  /// Échelles de progression des figures travaillées dans le bloc (0.4.0).
  final List<SkillLadder>? skillLadders;

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
      if (intent case final v?) 'intent': v.toJson(),
      if (skillLadders case final v?)
        'skillLadders': [for (final e in v) e.toJson()],
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
    Object? intent = unset,
    Object? skillLadders = unset,
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
      intent: identical(intent, unset) ? this.intent : intent as BlockIntent?,
      skillLadders: identical(skillLadders, unset)
          ? this.skillLadders
          : skillLadders as List<SkillLadder>?,
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
    checkRange(out, '$path.weeks', weeks, 1, 52);
    checkRange(out, '$path.seed', seed, 0, null);
    for (var i = 0; i < days.length; i++) {
      days[i].collectViolations('$path.days[$i]', out);
    }
    score.collectViolations('$path.score', out);
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    if (intent case final v?) {
      v.collectViolations('$path.intent', out);
    }
    if (skillLadders case final v?) {
      checkLength(out, '$path.skillLadders', v.length, null, 30);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.skillLadders[$i]', out);
      }
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
    intent?.collectExerciseIds(out);
    for (final e in skillLadders ?? const <SkillLadder>[]) {
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
            jsonListEquals(reasons, other.reasons) &&
            intent == other.intent &&
            jsonDeepEquals(skillLadders, other.skillLadders);
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
    intent,
    jsonDeepHash(skillLadders),
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
    this.fromPrescription,
    this.toPrescription,
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
      fromPrescription: jsonObjOrNull(
        json,
        'fromPrescription',
        ExercisePrescription.fromJson,
      ),
      toPrescription: jsonObjOrNull(
        json,
        'toPrescription',
        ExercisePrescription.fromJson,
      ),
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

  /// Prescription avant (`prescription_changed`).
  final ExercisePrescription? fromPrescription;

  /// Prescription après (`prescription_changed`) : appliquer le changement =
  /// remplacer la prescription de (`weekIndex`, `dayIndex`, `slotId`) par
  /// celle-ci.
  final ExercisePrescription? toPrescription;

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
      if (fromPrescription case final v?) 'fromPrescription': v.toJson(),
      if (toPrescription case final v?) 'toPrescription': v.toJson(),
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
    Object? fromPrescription = unset,
    Object? toPrescription = unset,
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
      fromPrescription: identical(fromPrescription, unset)
          ? this.fromPrescription
          : fromPrescription as ExercisePrescription?,
      toPrescription: identical(toPrescription, unset)
          ? this.toPrescription
          : toPrescription as ExercisePrescription?,
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
    if (fromPrescription case final v?) {
      v.collectViolations('$path.fromPrescription', out);
    }
    if (toPrescription case final v?) {
      v.collectViolations('$path.toPrescription', out);
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
    fromPrescription?.collectExerciseIds(out);
    toPrescription?.collectExerciseIds(out);
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
            fromPrescription == other.fromPrescription &&
            toPrescription == other.toPrescription &&
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
    fromPrescription,
    toPrescription,
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
/// calories ; bornes basses ≤ bornes hautes, renseignées ensemble ;
/// `setTargets`, s'il est présent, a `sets` éléments.
/// Invariant : (0.4.0) `test` renseigné ⇒ `kind` vaut `test` ; série de tête
/// et séries allégées : `technique.backoffSets` < `sets`.
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
    this.targetFlames,
    this.restSeconds,
    this.startLoadKg,
    this.percentOfOneRm,
    required this.toCalibrate,
    required this.loadBasis,
    this.setTargets,
    this.groupId,
    this.format,
    this.kind,
    required this.reasons,
    this.technique,
    this.tempo,
    this.intensity,
    this.autoregulation,
    this.test,
    this.dayStress,
    this.skillTargetId,
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
      targetFlames: jsonIntOrNull(json, 'targetFlames'),
      restSeconds: jsonIntOrNull(json, 'restSeconds'),
      startLoadKg: jsonDoubleOrNull(json, 'startLoadKg'),
      percentOfOneRm: jsonDoubleOrNull(json, 'percentOfOneRm'),
      toCalibrate: jsonBool(json, 'toCalibrate'),
      loadBasis: jsonEnum(json, 'loadBasis', LoadBasis.fromCode),
      setTargets: jsonListOrNull(
        json,
        'setTargets',
        (v) => SetTarget.fromJson(jsonAsObject(v, 'setTargets')),
      ),
      groupId: jsonStringOrNull(json, 'groupId'),
      format: jsonStringOrNull(json, 'format'),
      kind: jsonEnumOrNull(json, 'kind', SetKind.fromCode),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
      technique: jsonObjOrNull(json, 'technique', SetTechnique.fromJson),
      tempo: jsonObjOrNull(json, 'tempo', Tempo.fromJson),
      intensity: jsonObjOrNull(json, 'intensity', IntensityTarget.fromJson),
      autoregulation: jsonListOrNull(
        json,
        'autoregulation',
        (v) => AutoregulationRule.fromJson(jsonAsObject(v, 'autoregulation')),
      ),
      test: jsonObjOrNull(json, 'test', TestSpec.fromJson),
      dayStress: jsonEnumOrNull(json, 'dayStress', DayStress.fromCode),
      skillTargetId: jsonStringOrNull(json, 'skillTargetId'),
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

  /// Flammes visées (absent : sans cible de difficulté — mobilité,
  /// échauffement).
  final int? targetFlames;

  /// Repos entre les séries, en secondes (absent : libre).
  final int? restSeconds;

  /// Charge externe de départ, en kg (prudente ; même convention que
  /// `SetRecord.externalLoadKg`).
  final double? startLoadKg;

  /// Charge exprimée en part du 1RM de charge totale, de 0 à 1,5 (programme
  /// importé, ou repère du moteur).
  final double? percentOfOneRm;

  /// Charge à calibrer sur les premières séances.
  final bool toCalibrate;

  /// Ce que désigne la charge.
  final LoadBasis loadBasis;

  /// Cible série par série, quand les séries diffèrent (montée de calibrage,
  /// série lourde puis séries allégées) ; sa longueur est `sets`. Absent :
  /// toutes les séries suivent la prescription.
  final List<SetTarget>? setTargets;

  /// Groupe d'exercices enchaînés dans la séance (superset, tours, circuit) :
  /// même valeur pour les membres du groupe.
  final String? groupId;

  /// Code du format du groupe ou de l'exercice (`superset`, `rounds`, `amrap`,
  /// `emom`, `intervals`…).
  final String? format;

  /// Rôle des séries (absent : travail) ; `test` pour une séance de test.
  final SetKind? kind;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Technique de série (0.4.0) ; absente : séries normales.
  final SetTechnique? technique;

  /// Tempo des répétitions (0.4.0).
  final Tempo? tempo;

  /// Intensité relative à un test, au maintien max, à une étape, à une vitesse
  /// ; plafond de RIR (0.4.0).
  final IntensityTarget? intensity;

  /// Règles d'autorégulation que le moteur dynamique exécute (0.4.0).
  final List<AutoregulationRule>? autoregulation;

  /// Description du test, quand `kind` vaut `test` (0.4.0).
  final TestSpec? test;

  /// Ondulation : jour lourd, moyen ou léger pour ce mouvement (0.4.0).
  final DayStress? dayStress;

  /// Figure visée dont cet exercice est une étape (0.4.0).
  final String? skillTargetId;

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
      if (targetFlames case final v?) 'targetFlames': v,
      if (restSeconds case final v?) 'restSeconds': v,
      if (startLoadKg case final v?) 'startLoadKg': v,
      if (percentOfOneRm case final v?) 'percentOfOneRm': v,
      'toCalibrate': toCalibrate,
      'loadBasis': loadBasis.code,
      if (setTargets case final v?)
        'setTargets': [for (final e in v) e.toJson()],
      if (groupId case final v?) 'groupId': v,
      if (format case final v?) 'format': v,
      if (kind case final v?) 'kind': v.code,
      'reasons': [for (final e in reasons) e.toJson()],
      if (technique case final v?) 'technique': v.toJson(),
      if (tempo case final v?) 'tempo': v.toJson(),
      if (intensity case final v?) 'intensity': v.toJson(),
      if (autoregulation case final v?)
        'autoregulation': [for (final e in v) e.toJson()],
      if (test case final v?) 'test': v.toJson(),
      if (dayStress case final v?) 'dayStress': v.code,
      if (skillTargetId case final v?) 'skillTargetId': v,
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
    Object? targetFlames = unset,
    Object? restSeconds = unset,
    Object? startLoadKg = unset,
    Object? percentOfOneRm = unset,
    bool? toCalibrate,
    LoadBasis? loadBasis,
    Object? setTargets = unset,
    Object? groupId = unset,
    Object? format = unset,
    Object? kind = unset,
    List<Reason>? reasons,
    Object? technique = unset,
    Object? tempo = unset,
    Object? intensity = unset,
    Object? autoregulation = unset,
    Object? test = unset,
    Object? dayStress = unset,
    Object? skillTargetId = unset,
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
      targetFlames: identical(targetFlames, unset)
          ? this.targetFlames
          : targetFlames as int?,
      restSeconds: identical(restSeconds, unset)
          ? this.restSeconds
          : restSeconds as int?,
      startLoadKg: identical(startLoadKg, unset)
          ? this.startLoadKg
          : startLoadKg as double?,
      percentOfOneRm: identical(percentOfOneRm, unset)
          ? this.percentOfOneRm
          : percentOfOneRm as double?,
      toCalibrate: toCalibrate ?? this.toCalibrate,
      loadBasis: loadBasis ?? this.loadBasis,
      setTargets: identical(setTargets, unset)
          ? this.setTargets
          : setTargets as List<SetTarget>?,
      groupId: identical(groupId, unset) ? this.groupId : groupId as String?,
      format: identical(format, unset) ? this.format : format as String?,
      kind: identical(kind, unset) ? this.kind : kind as SetKind?,
      reasons: reasons ?? this.reasons,
      technique: identical(technique, unset)
          ? this.technique
          : technique as SetTechnique?,
      tempo: identical(tempo, unset) ? this.tempo : tempo as Tempo?,
      intensity: identical(intensity, unset)
          ? this.intensity
          : intensity as IntensityTarget?,
      autoregulation: identical(autoregulation, unset)
          ? this.autoregulation
          : autoregulation as List<AutoregulationRule>?,
      test: identical(test, unset) ? this.test : test as TestSpec?,
      dayStress: identical(dayStress, unset)
          ? this.dayStress
          : dayStress as DayStress?,
      skillTargetId: identical(skillTargetId, unset)
          ? this.skillTargetId
          : skillTargetId as String?,
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
    if (targetFlames case final v?) {
      checkRange(out, '$path.targetFlames', v, 1, 10);
    }
    if (restSeconds case final v?) {
      checkRange(out, '$path.restSeconds', v, 0, 900);
    }
    if (startLoadKg case final v?) {
      checkRange(out, '$path.startLoadKg', v, -300, 1000);
    }
    if (percentOfOneRm case final v?) {
      checkRange(out, '$path.percentOfOneRm', v, 0, 1.5);
    }
    if (setTargets case final v?) {
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.setTargets[$i]', out);
      }
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
    if (technique case final v?) {
      v.collectViolations('$path.technique', out);
    }
    if (tempo case final v?) {
      v.collectViolations('$path.tempo', out);
    }
    if (intensity case final v?) {
      v.collectViolations('$path.intensity', out);
    }
    if (autoregulation case final v?) {
      checkLength(out, '$path.autoregulation', v.length, null, 3);
      for (var i = 0; i < v.length; i++) {
        v[i].collectViolations('$path.autoregulation[$i]', out);
      }
    }
    if (test case final v?) {
      v.collectViolations('$path.test', out);
    }
    if (skillTargetId case final v?) {
      checkLength(out, '$path.skillTargetId', v.length, 1, null);
    }
    _validateExercisePrescription(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
    for (final e in setTargets ?? const <SetTarget>[]) {
      e.collectExerciseIds(out);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
    technique?.collectExerciseIds(out);
    tempo?.collectExerciseIds(out);
    intensity?.collectExerciseIds(out);
    for (final e in autoregulation ?? const <AutoregulationRule>[]) {
      e.collectExerciseIds(out);
    }
    test?.collectExerciseIds(out);
    if (skillTargetId case final v?) {
      out.add(v);
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
            percentOfOneRm == other.percentOfOneRm &&
            toCalibrate == other.toCalibrate &&
            loadBasis == other.loadBasis &&
            jsonDeepEquals(setTargets, other.setTargets) &&
            groupId == other.groupId &&
            format == other.format &&
            kind == other.kind &&
            jsonListEquals(reasons, other.reasons) &&
            technique == other.technique &&
            tempo == other.tempo &&
            intensity == other.intensity &&
            jsonDeepEquals(autoregulation, other.autoregulation) &&
            test == other.test &&
            dayStress == other.dayStress &&
            skillTargetId == other.skillTargetId;
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
    percentOfOneRm,
    toCalibrate,
    loadBasis,
    jsonDeepHash(setTargets),
    groupId,
    format,
    kind,
    Object.hashAll(reasons),
    technique,
    tempo,
    intensity,
    jsonDeepHash(autoregulation),
    test,
    dayStress,
    skillTargetId,
  ]);

  @override
  String toString() => 'ExercisePrescription(${toJson()})';
}

/// Prescriptions d'une séance.
final class DayPrescription {
  const DayPrescription({
    required this.dayIndex,
    required this.items,
    this.stress,
  });

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
      stress: jsonEnumOrNull(json, 'stress', DayStress.fromCode),
    );
  }

  /// Jour d'entraînement.
  final int dayIndex;

  /// Exercices, dans l'ordre.
  final List<ExercisePrescription> items;

  /// Ondulation : séance lourde, moyenne ou légère (0.4.0).
  final DayStress? stress;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dayIndex': dayIndex,
      'items': [for (final e in items) e.toJson()],
      if (stress case final v?) 'stress': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DayPrescription copyWith({
    int? dayIndex,
    List<ExercisePrescription>? items,
    Object? stress = unset,
  }) {
    return DayPrescription(
      dayIndex: dayIndex ?? this.dayIndex,
      items: items ?? this.items,
      stress: identical(stress, unset) ? this.stress : stress as DayStress?,
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
            jsonListEquals(items, other.items) &&
            stress == other.stress;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[dayIndex, Object.hashAll(items), stress]);

  @override
  String toString() => 'DayPrescription(${toJson()})';
}

/// Prescriptions d'une semaine du bloc.
final class WeekPrescription {
  const WeekPrescription({
    required this.weekIndex,
    required this.kind,
    required this.days,
    this.intent,
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
      intent: jsonEnumOrNull(json, 'intent', WeekIntent.fromCode),
    );
  }

  /// Semaine dans le bloc (0 = première).
  final int weekIndex;

  /// Nature de la semaine.
  final WeekKind kind;

  /// Séances.
  final List<DayPrescription> days;

  /// Intention de la semaine (0.4.0) ; `kind` reste renseigné.
  final WeekIntent? intent;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'weekIndex': weekIndex,
      'kind': kind.code,
      'days': [for (final e in days) e.toJson()],
      if (intent case final v?) 'intent': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  WeekPrescription copyWith({
    int? weekIndex,
    WeekKind? kind,
    List<DayPrescription>? days,
    Object? intent = unset,
  }) {
    return WeekPrescription(
      weekIndex: weekIndex ?? this.weekIndex,
      kind: kind ?? this.kind,
      days: days ?? this.days,
      intent: identical(intent, unset) ? this.intent : intent as WeekIntent?,
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
            jsonListEquals(days, other.days) &&
            intent == other.intent;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[weekIndex, kind, Object.hashAll(days), intent]);

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
/// `pass1.weeks` ; `slotId` uniques dans une séance ; chaque séance prescrite
/// renvoie à un jour de la passe 1. La passe 2 fait foi : une semaine peut
/// prescrire un autre exercice que la semaine type pour un emplacement
/// (échange en cours de bloc, semaine de test), ou un emplacement propre à
/// cette semaine.
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
    this.season,
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
      season: jsonObjOrNull(json, 'season', SeasonPlan.fromJson),
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

  /// Plan de saison en cours (0.4.0).
  final SeasonPlan? season;

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
      if (season case final v?) 'season': v.toJson(),
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
    Object? season = unset,
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
      season: identical(season, unset) ? this.season : season as SeasonPlan?,
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
    if (season case final v?) {
      v.collectViolations('$path.season', out);
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
    season?.collectExerciseIds(out);
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
            adaptation == other.adaptation &&
            season == other.season;
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
    season,
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
    this.season,
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
      season: jsonObjOrNull(json, 'season', SeasonPlan.fromJson),
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

  /// Plan de saison en cours (0.4.0).
  final SeasonPlan? season;

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
      if (season case final v?) 'season': v.toJson(),
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
    Object? season = unset,
  }) {
    return NextBlockRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      seed: seed ?? this.seed,
      startDate: startDate ?? this.startDate,
      previous: previous ?? this.previous,
      adaptation: adaptation ?? this.adaptation,
      locks: locks ?? this.locks,
      season: identical(season, unset) ? this.season : season as SeasonPlan?,
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
    if (season case final v?) {
      v.collectViolations('$path.season', out);
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
    season?.collectExerciseIds(out);
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
            jsonListEquals(locks, other.locks) &&
            season == other.season;
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
    season,
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
    this.season,
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
      season: jsonObjOrNull(json, 'season', SeasonPlan.fromJson),
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

  /// Plan de saison en cours (0.4.0).
  final SeasonPlan? season;

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
      if (season case final v?) 'season': v.toJson(),
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
    Object? season = unset,
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
      season: identical(season, unset) ? this.season : season as SeasonPlan?,
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
    if (season case final v?) {
      v.collectViolations('$path.season', out);
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
    season?.collectExerciseIds(out);
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
            adaptation == other.adaptation &&
            season == other.season;
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
    season,
  ]);

  @override
  String toString() => 'RestructureRequest(${toJson()})';
}

/// Requête d'action de revue de la passe 1.
final class ReviewRequest {
  const ReviewRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.request,
    required this.current,
    required this.action,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory ReviewRequest.fromJson(Map<String, Object?> json) {
    return ReviewRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      request: jsonObj(json, 'request', PlanRequest.fromJson),
      current: jsonObj(json, 'current', Pass1Plan.fromJson),
      action: jsonObj(json, 'action', ReviewAction.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Requête de création (avec les verrous déjà posés).
  final PlanRequest request;

  /// Programme en cours de revue.
  final Pass1Plan current;

  /// Action de l'utilisateur.
  final ReviewAction action;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'request': request.toJson(),
      'current': current.toJson(),
      'action': action.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  ReviewRequest copyWith({
    int? schemaVersion,
    PlanRequest? request,
    Pass1Plan? current,
    ReviewAction? action,
  }) {
    return ReviewRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      request: request ?? this.request,
      current: current ?? this.current,
      action: action ?? this.action,
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
    request.collectViolations('$path.request', out);
    current.collectViolations('$path.current', out);
    action.collectViolations('$path.action', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    request.collectExerciseIds(out);
    current.collectExerciseIds(out);
    action.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReviewRequest &&
            schemaVersion == other.schemaVersion &&
            request == other.request &&
            current == other.current &&
            action == other.action;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[schemaVersion, request, current, action]);

  @override
  String toString() => 'ReviewRequest(${toJson()})';
}

/// Requête de variantes pour un emplacement.
final class VariantsRequest {
  const VariantsRequest({
    this.schemaVersion = currentSchemaVersion,
    required this.request,
    required this.current,
    required this.slotId,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory VariantsRequest.fromJson(Map<String, Object?> json) {
    return VariantsRequest(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      request: jsonObj(json, 'request', PlanRequest.fromJson),
      current: jsonObj(json, 'current', Pass1Plan.fromJson),
      slotId: jsonString(json, 'slotId'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Requête de création.
  final PlanRequest request;

  /// Programme en cours de revue.
  final Pass1Plan current;

  /// Emplacement.
  final String slotId;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'request': request.toJson(),
      'current': current.toJson(),
      'slotId': slotId,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  VariantsRequest copyWith({
    int? schemaVersion,
    PlanRequest? request,
    Pass1Plan? current,
    String? slotId,
  }) {
    return VariantsRequest(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      request: request ?? this.request,
      current: current ?? this.current,
      slotId: slotId ?? this.slotId,
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
    request.collectViolations('$path.request', out);
    current.collectViolations('$path.current', out);
    checkLength(out, '$path.slotId', slotId.length, 1, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    request.collectExerciseIds(out);
    current.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VariantsRequest &&
            schemaVersion == other.schemaVersion &&
            request == other.request &&
            current == other.current &&
            slotId == other.slotId;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[schemaVersion, request, current, slotId]);

  @override
  String toString() => 'VariantsRequest(${toJson()})';
}

/// Requête de passe 2.
final class Pass2Request {
  const Pass2Request({
    this.schemaVersion = currentSchemaVersion,
    required this.request,
    required this.pass1,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Pass2Request.fromJson(Map<String, Object?> json) {
    return Pass2Request(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      request: jsonObj(json, 'request', PlanRequest.fromJson),
      pass1: jsonObj(json, 'pass1', Pass1Plan.fromJson),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Requête de création.
  final PlanRequest request;

  /// Passe 1 validée par l'utilisateur.
  final Pass1Plan pass1;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'request': request.toJson(),
      'pass1': pass1.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Pass2Request copyWith({
    int? schemaVersion,
    PlanRequest? request,
    Pass1Plan? pass1,
  }) {
    return Pass2Request(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      request: request ?? this.request,
      pass1: pass1 ?? this.pass1,
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
    request.collectViolations('$path.request', out);
    pass1.collectViolations('$path.pass1', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    request.collectExerciseIds(out);
    pass1.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Pass2Request &&
            schemaVersion == other.schemaVersion &&
            request == other.request &&
            pass1 == other.pass1;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[schemaVersion, request, pass1]);

  @override
  String toString() => 'Pass2Request(${toJson()})';
}

/// Bloc proposé et ce qui change par rapport au précédent.
final class BlockProposal {
  const BlockProposal({required this.block, required this.diff, this.season});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory BlockProposal.fromJson(Map<String, Object?> json) {
    return BlockProposal(
      block: jsonObj(json, 'block', ProgramBlock.fromJson),
      diff: jsonObj(json, 'diff', PlanDiff.fromJson),
      season: jsonObjOrNull(json, 'season', SeasonPlan.fromJson),
    );
  }

  /// Bloc proposé.
  final ProgramBlock block;

  /// Changements par rapport au bloc de référence.
  final PlanDiff diff;

  /// Plan de saison révisé, si le bloc proposé le modifie (0.4.0).
  final SeasonPlan? season;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'block': block.toJson(),
      'diff': diff.toJson(),
      if (season case final v?) 'season': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  BlockProposal copyWith({
    ProgramBlock? block,
    PlanDiff? diff,
    Object? season = unset,
  }) {
    return BlockProposal(
      block: block ?? this.block,
      diff: diff ?? this.diff,
      season: identical(season, unset) ? this.season : season as SeasonPlan?,
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
    block.collectViolations('$path.block', out);
    diff.collectViolations('$path.diff', out);
    if (season case final v?) {
      v.collectViolations('$path.season', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    block.collectExerciseIds(out);
    diff.collectExerciseIds(out);
    season?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BlockProposal &&
            block == other.block &&
            diff == other.diff &&
            season == other.season;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[block, diff, season]);

  @override
  String toString() => 'BlockProposal(${toJson()})';
}

/// Tempo d'une répétition, en secondes par phase (0.4.0) ; 0 = sans consigne
/// (ou explosif pour la phase concentrique).
final class Tempo {
  const Tempo({
    required this.eccentricSeconds,
    required this.bottomPauseSeconds,
    required this.concentricSeconds,
    required this.topPauseSeconds,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Tempo.fromJson(Map<String, Object?> json) {
    return Tempo(
      eccentricSeconds: jsonInt(json, 'eccentricSeconds'),
      bottomPauseSeconds: jsonInt(json, 'bottomPauseSeconds'),
      concentricSeconds: jsonInt(json, 'concentricSeconds'),
      topPauseSeconds: jsonInt(json, 'topPauseSeconds'),
    );
  }

  /// Descente (phase excentrique).
  final int eccentricSeconds;

  /// Pause en bas.
  final int bottomPauseSeconds;

  /// Montée (phase concentrique).
  final int concentricSeconds;

  /// Pause en haut.
  final int topPauseSeconds;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'eccentricSeconds': eccentricSeconds,
      'bottomPauseSeconds': bottomPauseSeconds,
      'concentricSeconds': concentricSeconds,
      'topPauseSeconds': topPauseSeconds,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Tempo copyWith({
    int? eccentricSeconds,
    int? bottomPauseSeconds,
    int? concentricSeconds,
    int? topPauseSeconds,
  }) {
    return Tempo(
      eccentricSeconds: eccentricSeconds ?? this.eccentricSeconds,
      bottomPauseSeconds: bottomPauseSeconds ?? this.bottomPauseSeconds,
      concentricSeconds: concentricSeconds ?? this.concentricSeconds,
      topPauseSeconds: topPauseSeconds ?? this.topPauseSeconds,
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
    checkRange(out, '$path.eccentricSeconds', eccentricSeconds, 0, 30);
    checkRange(out, '$path.bottomPauseSeconds', bottomPauseSeconds, 0, 30);
    checkRange(out, '$path.concentricSeconds', concentricSeconds, 0, 30);
    checkRange(out, '$path.topPauseSeconds', topPauseSeconds, 0, 30);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Tempo &&
            eccentricSeconds == other.eccentricSeconds &&
            bottomPauseSeconds == other.bottomPauseSeconds &&
            concentricSeconds == other.concentricSeconds &&
            topPauseSeconds == other.topPauseSeconds;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    eccentricSeconds,
    bottomPauseSeconds,
    concentricSeconds,
    topPauseSeconds,
  ]);

  @override
  String toString() => 'Tempo(${toJson()})';
}

/// Technique de série et ses paramètres (0.4.0). Sens de
/// `ExercisePrescription.sets` et de la plage de répétitions pour chaque
/// technique : CONTRAT.md §12.
///
/// Invariant : Chaque technique porte exactement ses paramètres (tableau de
/// CONTRAT.md §12) : un paramètre d'une autre technique est une violation.
/// Invariant : Plages basses ≤ plages hautes, renseignées ensemble ;
/// `ladderStart` ≤ `ladderTop` ; répétitions de `waveReps` et de
/// `pyramidReps` de 1 à 100.
final class SetTechnique {
  const SetTechnique({
    required this.kind,
    this.backoffSets,
    this.backoffDropPct,
    this.backoffRepsLow,
    this.backoffRepsHigh,
    this.miniSets,
    this.miniSetReps,
    this.intraRestSeconds,
    this.activationRepsLow,
    this.activationRepsHigh,
    this.totalRepsTarget,
    this.drops,
    this.dropPct,
    this.eccentricLoadPct,
    this.eccentricOnly,
    this.pairedSlotId,
    this.pairedRestSeconds,
    this.waves,
    this.waveReps,
    this.waveStepPct,
    this.durationSeconds,
    this.intervalSeconds,
    this.intervals,
    this.repsPerInterval,
    this.ladderStart,
    this.ladderStep,
    this.ladderTop,
    this.ladderCount,
    this.pyramidReps,
    this.qualityFloor,
    this.maxAttempts,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory SetTechnique.fromJson(Map<String, Object?> json) {
    return SetTechnique(
      kind: jsonEnum(json, 'kind', SetTechniqueKind.fromCode),
      backoffSets: jsonIntOrNull(json, 'backoffSets'),
      backoffDropPct: jsonDoubleOrNull(json, 'backoffDropPct'),
      backoffRepsLow: jsonIntOrNull(json, 'backoffRepsLow'),
      backoffRepsHigh: jsonIntOrNull(json, 'backoffRepsHigh'),
      miniSets: jsonIntOrNull(json, 'miniSets'),
      miniSetReps: jsonIntOrNull(json, 'miniSetReps'),
      intraRestSeconds: jsonIntOrNull(json, 'intraRestSeconds'),
      activationRepsLow: jsonIntOrNull(json, 'activationRepsLow'),
      activationRepsHigh: jsonIntOrNull(json, 'activationRepsHigh'),
      totalRepsTarget: jsonIntOrNull(json, 'totalRepsTarget'),
      drops: jsonIntOrNull(json, 'drops'),
      dropPct: jsonDoubleOrNull(json, 'dropPct'),
      eccentricLoadPct: jsonDoubleOrNull(json, 'eccentricLoadPct'),
      eccentricOnly: jsonBoolOrNull(json, 'eccentricOnly'),
      pairedSlotId: jsonStringOrNull(json, 'pairedSlotId'),
      pairedRestSeconds: jsonIntOrNull(json, 'pairedRestSeconds'),
      waves: jsonIntOrNull(json, 'waves'),
      waveReps: jsonListOrNull(
        json,
        'waveReps',
        (v) => jsonAsInt(v, 'waveReps'),
      ),
      waveStepPct: jsonDoubleOrNull(json, 'waveStepPct'),
      durationSeconds: jsonIntOrNull(json, 'durationSeconds'),
      intervalSeconds: jsonIntOrNull(json, 'intervalSeconds'),
      intervals: jsonIntOrNull(json, 'intervals'),
      repsPerInterval: jsonIntOrNull(json, 'repsPerInterval'),
      ladderStart: jsonIntOrNull(json, 'ladderStart'),
      ladderStep: jsonIntOrNull(json, 'ladderStep'),
      ladderTop: jsonIntOrNull(json, 'ladderTop'),
      ladderCount: jsonIntOrNull(json, 'ladderCount'),
      pyramidReps: jsonListOrNull(
        json,
        'pyramidReps',
        (v) => jsonAsInt(v, 'pyramidReps'),
      ),
      qualityFloor: jsonIntOrNull(json, 'qualityFloor'),
      maxAttempts: jsonIntOrNull(json, 'maxAttempts'),
    );
  }

  /// Technique.
  final SetTechniqueKind kind;

  /// Séries allégées après la série de tête.
  final int? backoffSets;

  /// Baisse de charge des séries allégées, en part de la charge de tête (0,10 =
  /// −10 %).
  final double? backoffDropPct;

  /// Bas de la plage de répétitions des séries allégées.
  final int? backoffRepsLow;

  /// Haut de la plage de répétitions des séries allégées.
  final int? backoffRepsHigh;

  /// Mini-séries par série (clusters) ; plafond de mini-séries (rest-pause,
  /// myo-reps).
  final int? miniSets;

  /// Répétitions par mini-série.
  final int? miniSetReps;

  /// Repos entre deux mini-séries, en secondes.
  final int? intraRestSeconds;

  /// Bas de la plage de la série d'activation (myo-reps).
  final int? activationRepsLow;

  /// Haut de la plage de la série d'activation (myo-reps).
  final int? activationRepsHigh;

  /// Répétitions totales visées (rest-pause, densité).
  final int? totalRepsTarget;

  /// Nombre de baisses de charge (dégressive).
  final int? drops;

  /// Baisse de charge à chaque palier, en part de la charge précédente.
  final double? dropPct;

  /// Charge de la phase excentrique, en part du 1RM de charge totale (peut
  /// dépasser 1).
  final double? eccentricLoadPct;

  /// Négatives seules (la montée est aidée ou sautée).
  final bool? eccentricOnly;

  /// Emplacement de l'exercice explosif enchaîné (contraste).
  final String? pairedSlotId;

  /// Repos avant l'exercice enchaîné, en secondes.
  final int? pairedRestSeconds;

  /// Nombre de vagues.
  final int? waves;

  /// Répétitions de chaque palier d'une vague, dans l'ordre (ex. 3, 2, 1).
  final List<int>? waveReps;

  /// Hausse de charge d'une vague à la suivante, en part de la charge.
  final double? waveStepPct;

  /// Durée du bloc, en secondes (AMRAP, densité).
  final int? durationSeconds;

  /// Durée d'un intervalle, en secondes (EMOM).
  final int? intervalSeconds;

  /// Nombre d'intervalles (EMOM).
  final int? intervals;

  /// Répétitions par intervalle (EMOM).
  final int? repsPerInterval;

  /// Première marche de l'échelle, en répétitions.
  final int? ladderStart;

  /// Pas de l'échelle, en répétitions.
  final int? ladderStep;

  /// Dernière marche de l'échelle, en répétitions.
  final int? ladderTop;

  /// Nombre d'échelles enchaînées.
  final int? ladderCount;

  /// Répétitions de chaque palier de la pyramide, dans l'ordre (ex. 10, 8, 6,
  /// 4, 2).
  final List<int>? pyramidReps;

  /// Propreté minimale (1 à 5) : la pratique s'arrête dès qu'un essai passe
  /// dessous.
  final int? qualityFloor;

  /// Plafond d'essais (pratique de figure).
  final int? maxAttempts;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (backoffSets case final v?) 'backoffSets': v,
      if (backoffDropPct case final v?) 'backoffDropPct': v,
      if (backoffRepsLow case final v?) 'backoffRepsLow': v,
      if (backoffRepsHigh case final v?) 'backoffRepsHigh': v,
      if (miniSets case final v?) 'miniSets': v,
      if (miniSetReps case final v?) 'miniSetReps': v,
      if (intraRestSeconds case final v?) 'intraRestSeconds': v,
      if (activationRepsLow case final v?) 'activationRepsLow': v,
      if (activationRepsHigh case final v?) 'activationRepsHigh': v,
      if (totalRepsTarget case final v?) 'totalRepsTarget': v,
      if (drops case final v?) 'drops': v,
      if (dropPct case final v?) 'dropPct': v,
      if (eccentricLoadPct case final v?) 'eccentricLoadPct': v,
      if (eccentricOnly case final v?) 'eccentricOnly': v,
      if (pairedSlotId case final v?) 'pairedSlotId': v,
      if (pairedRestSeconds case final v?) 'pairedRestSeconds': v,
      if (waves case final v?) 'waves': v,
      if (waveReps case final v?) 'waveReps': [for (final e in v) e],
      if (waveStepPct case final v?) 'waveStepPct': v,
      if (durationSeconds case final v?) 'durationSeconds': v,
      if (intervalSeconds case final v?) 'intervalSeconds': v,
      if (intervals case final v?) 'intervals': v,
      if (repsPerInterval case final v?) 'repsPerInterval': v,
      if (ladderStart case final v?) 'ladderStart': v,
      if (ladderStep case final v?) 'ladderStep': v,
      if (ladderTop case final v?) 'ladderTop': v,
      if (ladderCount case final v?) 'ladderCount': v,
      if (pyramidReps case final v?) 'pyramidReps': [for (final e in v) e],
      if (qualityFloor case final v?) 'qualityFloor': v,
      if (maxAttempts case final v?) 'maxAttempts': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  SetTechnique copyWith({
    SetTechniqueKind? kind,
    Object? backoffSets = unset,
    Object? backoffDropPct = unset,
    Object? backoffRepsLow = unset,
    Object? backoffRepsHigh = unset,
    Object? miniSets = unset,
    Object? miniSetReps = unset,
    Object? intraRestSeconds = unset,
    Object? activationRepsLow = unset,
    Object? activationRepsHigh = unset,
    Object? totalRepsTarget = unset,
    Object? drops = unset,
    Object? dropPct = unset,
    Object? eccentricLoadPct = unset,
    Object? eccentricOnly = unset,
    Object? pairedSlotId = unset,
    Object? pairedRestSeconds = unset,
    Object? waves = unset,
    Object? waveReps = unset,
    Object? waveStepPct = unset,
    Object? durationSeconds = unset,
    Object? intervalSeconds = unset,
    Object? intervals = unset,
    Object? repsPerInterval = unset,
    Object? ladderStart = unset,
    Object? ladderStep = unset,
    Object? ladderTop = unset,
    Object? ladderCount = unset,
    Object? pyramidReps = unset,
    Object? qualityFloor = unset,
    Object? maxAttempts = unset,
  }) {
    return SetTechnique(
      kind: kind ?? this.kind,
      backoffSets: identical(backoffSets, unset)
          ? this.backoffSets
          : backoffSets as int?,
      backoffDropPct: identical(backoffDropPct, unset)
          ? this.backoffDropPct
          : backoffDropPct as double?,
      backoffRepsLow: identical(backoffRepsLow, unset)
          ? this.backoffRepsLow
          : backoffRepsLow as int?,
      backoffRepsHigh: identical(backoffRepsHigh, unset)
          ? this.backoffRepsHigh
          : backoffRepsHigh as int?,
      miniSets: identical(miniSets, unset) ? this.miniSets : miniSets as int?,
      miniSetReps: identical(miniSetReps, unset)
          ? this.miniSetReps
          : miniSetReps as int?,
      intraRestSeconds: identical(intraRestSeconds, unset)
          ? this.intraRestSeconds
          : intraRestSeconds as int?,
      activationRepsLow: identical(activationRepsLow, unset)
          ? this.activationRepsLow
          : activationRepsLow as int?,
      activationRepsHigh: identical(activationRepsHigh, unset)
          ? this.activationRepsHigh
          : activationRepsHigh as int?,
      totalRepsTarget: identical(totalRepsTarget, unset)
          ? this.totalRepsTarget
          : totalRepsTarget as int?,
      drops: identical(drops, unset) ? this.drops : drops as int?,
      dropPct: identical(dropPct, unset) ? this.dropPct : dropPct as double?,
      eccentricLoadPct: identical(eccentricLoadPct, unset)
          ? this.eccentricLoadPct
          : eccentricLoadPct as double?,
      eccentricOnly: identical(eccentricOnly, unset)
          ? this.eccentricOnly
          : eccentricOnly as bool?,
      pairedSlotId: identical(pairedSlotId, unset)
          ? this.pairedSlotId
          : pairedSlotId as String?,
      pairedRestSeconds: identical(pairedRestSeconds, unset)
          ? this.pairedRestSeconds
          : pairedRestSeconds as int?,
      waves: identical(waves, unset) ? this.waves : waves as int?,
      waveReps: identical(waveReps, unset)
          ? this.waveReps
          : waveReps as List<int>?,
      waveStepPct: identical(waveStepPct, unset)
          ? this.waveStepPct
          : waveStepPct as double?,
      durationSeconds: identical(durationSeconds, unset)
          ? this.durationSeconds
          : durationSeconds as int?,
      intervalSeconds: identical(intervalSeconds, unset)
          ? this.intervalSeconds
          : intervalSeconds as int?,
      intervals: identical(intervals, unset)
          ? this.intervals
          : intervals as int?,
      repsPerInterval: identical(repsPerInterval, unset)
          ? this.repsPerInterval
          : repsPerInterval as int?,
      ladderStart: identical(ladderStart, unset)
          ? this.ladderStart
          : ladderStart as int?,
      ladderStep: identical(ladderStep, unset)
          ? this.ladderStep
          : ladderStep as int?,
      ladderTop: identical(ladderTop, unset)
          ? this.ladderTop
          : ladderTop as int?,
      ladderCount: identical(ladderCount, unset)
          ? this.ladderCount
          : ladderCount as int?,
      pyramidReps: identical(pyramidReps, unset)
          ? this.pyramidReps
          : pyramidReps as List<int>?,
      qualityFloor: identical(qualityFloor, unset)
          ? this.qualityFloor
          : qualityFloor as int?,
      maxAttempts: identical(maxAttempts, unset)
          ? this.maxAttempts
          : maxAttempts as int?,
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
    if (backoffSets case final v?) {
      checkRange(out, '$path.backoffSets', v, 1, 10);
    }
    if (backoffDropPct case final v?) {
      checkRange(out, '$path.backoffDropPct', v, 0, 0.6);
    }
    if (backoffRepsLow case final v?) {
      checkRange(out, '$path.backoffRepsLow', v, 1, 100);
    }
    if (backoffRepsHigh case final v?) {
      checkRange(out, '$path.backoffRepsHigh', v, 1, 100);
    }
    if (miniSets case final v?) {
      checkRange(out, '$path.miniSets', v, 1, 20);
    }
    if (miniSetReps case final v?) {
      checkRange(out, '$path.miniSetReps', v, 1, 30);
    }
    if (intraRestSeconds case final v?) {
      checkRange(out, '$path.intraRestSeconds', v, 1, 120);
    }
    if (activationRepsLow case final v?) {
      checkRange(out, '$path.activationRepsLow', v, 1, 100);
    }
    if (activationRepsHigh case final v?) {
      checkRange(out, '$path.activationRepsHigh', v, 1, 100);
    }
    if (totalRepsTarget case final v?) {
      checkRange(out, '$path.totalRepsTarget', v, 1, 1000);
    }
    if (drops case final v?) {
      checkRange(out, '$path.drops', v, 1, 6);
    }
    if (dropPct case final v?) {
      checkRange(out, '$path.dropPct', v, 0.05, 0.6);
    }
    if (eccentricLoadPct case final v?) {
      checkRange(out, '$path.eccentricLoadPct', v, 0, 1.5);
    }
    if (pairedSlotId case final v?) {
      checkLength(out, '$path.pairedSlotId', v.length, 1, null);
    }
    if (pairedRestSeconds case final v?) {
      checkRange(out, '$path.pairedRestSeconds', v, 0, 900);
    }
    if (waves case final v?) {
      checkRange(out, '$path.waves', v, 1, 6);
    }
    if (waveReps case final v?) {
      checkLength(out, '$path.waveReps', v.length, 1, 8);
    }
    if (waveStepPct case final v?) {
      checkRange(out, '$path.waveStepPct', v, 0, 0.2);
    }
    if (durationSeconds case final v?) {
      checkRange(out, '$path.durationSeconds', v, 10, 7200);
    }
    if (intervalSeconds case final v?) {
      checkRange(out, '$path.intervalSeconds', v, 10, 900);
    }
    if (intervals case final v?) {
      checkRange(out, '$path.intervals', v, 1, 120);
    }
    if (repsPerInterval case final v?) {
      checkRange(out, '$path.repsPerInterval', v, 1, 100);
    }
    if (ladderStart case final v?) {
      checkRange(out, '$path.ladderStart', v, 1, 100);
    }
    if (ladderStep case final v?) {
      checkRange(out, '$path.ladderStep', v, 1, 20);
    }
    if (ladderTop case final v?) {
      checkRange(out, '$path.ladderTop', v, 1, 100);
    }
    if (ladderCount case final v?) {
      checkRange(out, '$path.ladderCount', v, 1, 20);
    }
    if (pyramidReps case final v?) {
      checkLength(out, '$path.pyramidReps', v.length, 2, 20);
    }
    if (qualityFloor case final v?) {
      checkRange(out, '$path.qualityFloor', v, 1, 5);
    }
    if (maxAttempts case final v?) {
      checkRange(out, '$path.maxAttempts', v, 1, 30);
    }
    checkVariant(
      out,
      path,
      kind.code,
      <String, Object?>{
        'backoffSets': backoffSets,
        'backoffDropPct': backoffDropPct,
        'backoffRepsLow': backoffRepsLow,
        'backoffRepsHigh': backoffRepsHigh,
        'miniSets': miniSets,
        'miniSetReps': miniSetReps,
        'intraRestSeconds': intraRestSeconds,
        'activationRepsLow': activationRepsLow,
        'activationRepsHigh': activationRepsHigh,
        'totalRepsTarget': totalRepsTarget,
        'drops': drops,
        'dropPct': dropPct,
        'eccentricLoadPct': eccentricLoadPct,
        'eccentricOnly': eccentricOnly,
        'pairedSlotId': pairedSlotId,
        'pairedRestSeconds': pairedRestSeconds,
        'waves': waves,
        'waveReps': waveReps,
        'waveStepPct': waveStepPct,
        'durationSeconds': durationSeconds,
        'intervalSeconds': intervalSeconds,
        'intervals': intervals,
        'repsPerInterval': repsPerInterval,
        'ladderStart': ladderStart,
        'ladderStep': ladderStep,
        'ladderTop': ladderTop,
        'ladderCount': ladderCount,
        'pyramidReps': pyramidReps,
        'qualityFloor': qualityFloor,
        'maxAttempts': maxAttempts,
      },
      const <String, List<String>>{
        'standard': <String>[],
        'top_set_backoff': <String>['backoffSets', 'backoffDropPct'],
        'cluster': <String>['miniSets', 'miniSetReps', 'intraRestSeconds'],
        'rest_pause': <String>['intraRestSeconds'],
        'myo_reps': <String>['miniSetReps', 'intraRestSeconds'],
        'drop_set': <String>['drops', 'dropPct'],
        'isometric_hold': <String>[],
        'accentuated_eccentric': <String>[],
        'contrast': <String>['pairedSlotId'],
        'wave': <String>['waves', 'waveReps'],
        'amrap': <String>[],
        'emom': <String>['intervalSeconds', 'intervals'],
        'density': <String>['durationSeconds'],
        'ladder': <String>['ladderStart', 'ladderStep', 'ladderTop'],
        'pyramid': <String>['pyramidReps'],
        'skill_practice': <String>[],
      },
      const <String, List<String>>{
        'standard': <String>[],
        'top_set_backoff': <String>['backoffRepsLow', 'backoffRepsHigh'],
        'cluster': <String>[],
        'rest_pause': <String>['miniSets', 'totalRepsTarget'],
        'myo_reps': <String>[
          'miniSets',
          'activationRepsLow',
          'activationRepsHigh',
        ],
        'drop_set': <String>[],
        'isometric_hold': <String>[],
        'accentuated_eccentric': <String>['eccentricLoadPct', 'eccentricOnly'],
        'contrast': <String>['pairedRestSeconds'],
        'wave': <String>['waveStepPct'],
        'amrap': <String>['durationSeconds'],
        'emom': <String>['repsPerInterval'],
        'density': <String>['totalRepsTarget'],
        'ladder': <String>['ladderCount'],
        'pyramid': <String>[],
        'skill_practice': <String>['qualityFloor', 'maxAttempts'],
      },
    );
    _validateSetTechnique(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SetTechnique &&
            kind == other.kind &&
            backoffSets == other.backoffSets &&
            backoffDropPct == other.backoffDropPct &&
            backoffRepsLow == other.backoffRepsLow &&
            backoffRepsHigh == other.backoffRepsHigh &&
            miniSets == other.miniSets &&
            miniSetReps == other.miniSetReps &&
            intraRestSeconds == other.intraRestSeconds &&
            activationRepsLow == other.activationRepsLow &&
            activationRepsHigh == other.activationRepsHigh &&
            totalRepsTarget == other.totalRepsTarget &&
            drops == other.drops &&
            dropPct == other.dropPct &&
            eccentricLoadPct == other.eccentricLoadPct &&
            eccentricOnly == other.eccentricOnly &&
            pairedSlotId == other.pairedSlotId &&
            pairedRestSeconds == other.pairedRestSeconds &&
            waves == other.waves &&
            jsonDeepEquals(waveReps, other.waveReps) &&
            waveStepPct == other.waveStepPct &&
            durationSeconds == other.durationSeconds &&
            intervalSeconds == other.intervalSeconds &&
            intervals == other.intervals &&
            repsPerInterval == other.repsPerInterval &&
            ladderStart == other.ladderStart &&
            ladderStep == other.ladderStep &&
            ladderTop == other.ladderTop &&
            ladderCount == other.ladderCount &&
            jsonDeepEquals(pyramidReps, other.pyramidReps) &&
            qualityFloor == other.qualityFloor &&
            maxAttempts == other.maxAttempts;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    backoffSets,
    backoffDropPct,
    backoffRepsLow,
    backoffRepsHigh,
    miniSets,
    miniSetReps,
    intraRestSeconds,
    activationRepsLow,
    activationRepsHigh,
    totalRepsTarget,
    drops,
    dropPct,
    eccentricLoadPct,
    eccentricOnly,
    pairedSlotId,
    pairedRestSeconds,
    waves,
    jsonDeepHash(waveReps),
    waveStepPct,
    durationSeconds,
    intervalSeconds,
    intervals,
    repsPerInterval,
    ladderStart,
    ladderStep,
    ladderTop,
    ladderCount,
    jsonDeepHash(pyramidReps),
    qualityFloor,
    maxAttempts,
  ]);

  @override
  String toString() => 'SetTechnique(${toJson()})';
}

/// Intensité visée, exprimée autrement qu'en flammes (0.4.0).
/// `ExercisePrescription.percentOfOneRm` et `targetFlames` restent valables ;
/// ce type ajoute les intensités relatives à un test, au maintien max, à une
/// étape de figure, à une vitesse.
///
/// Invariant : `value` ≤ `valueHigh` ; bases en part : `value` et `valueHigh`
/// ≤ 1,5.
final class IntensityTarget {
  const IntensityTarget({
    required this.basis,
    this.value,
    this.valueHigh,
    this.referenceExerciseId,
    this.referenceKind,
    this.stepExerciseId,
    this.rirCap,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory IntensityTarget.fromJson(Map<String, Object?> json) {
    return IntensityTarget(
      basis: jsonEnum(json, 'basis', IntensityBasis.fromCode),
      value: jsonDoubleOrNull(json, 'value'),
      valueHigh: jsonDoubleOrNull(json, 'valueHigh'),
      referenceExerciseId: jsonStringOrNull(json, 'referenceExerciseId'),
      referenceKind: jsonEnumOrNull(
        json,
        'referenceKind',
        BenchmarkKind.fromCode,
      ),
      stepExerciseId: jsonStringOrNull(json, 'stepExerciseId'),
      rirCap: jsonDoubleOrNull(json, 'rirCap'),
    );
  }

  /// Ce que désigne `value`.
  final IntensityBasis basis;

  /// Valeur visée (ou bas de la plage) : part de 0 à 1,5 pour les bases en part
  /// ; répétitions en réserve pour `rir`.
  final double? value;

  /// Haut de la plage, même unité.
  final double? valueHigh;

  /// Exercice du test de référence, s'il diffère de l'exercice prescrit.
  final String? referenceExerciseId;

  /// Nature du test de référence (`percent_benchmark` : part des répétitions
  /// max, du maintien max…).
  final BenchmarkKind? referenceKind;

  /// Étape de progression visée (`progression_step`).
  final String? stepExerciseId;

  /// Plafond d'effort : ne jamais finir une série avec moins de répétitions en
  /// réserve que cette valeur ; la charge est abaissée sinon.
  final double? rirCap;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'basis': basis.code,
      if (value case final v?) 'value': v,
      if (valueHigh case final v?) 'valueHigh': v,
      if (referenceExerciseId case final v?) 'referenceExerciseId': v,
      if (referenceKind case final v?) 'referenceKind': v.code,
      if (stepExerciseId case final v?) 'stepExerciseId': v,
      if (rirCap case final v?) 'rirCap': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  IntensityTarget copyWith({
    IntensityBasis? basis,
    Object? value = unset,
    Object? valueHigh = unset,
    Object? referenceExerciseId = unset,
    Object? referenceKind = unset,
    Object? stepExerciseId = unset,
    Object? rirCap = unset,
  }) {
    return IntensityTarget(
      basis: basis ?? this.basis,
      value: identical(value, unset) ? this.value : value as double?,
      valueHigh: identical(valueHigh, unset)
          ? this.valueHigh
          : valueHigh as double?,
      referenceExerciseId: identical(referenceExerciseId, unset)
          ? this.referenceExerciseId
          : referenceExerciseId as String?,
      referenceKind: identical(referenceKind, unset)
          ? this.referenceKind
          : referenceKind as BenchmarkKind?,
      stepExerciseId: identical(stepExerciseId, unset)
          ? this.stepExerciseId
          : stepExerciseId as String?,
      rirCap: identical(rirCap, unset) ? this.rirCap : rirCap as double?,
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
    if (value case final v?) {
      checkRange(out, '$path.value', v, 0, 10);
    }
    if (valueHigh case final v?) {
      checkRange(out, '$path.valueHigh', v, 0, 10);
    }
    if (referenceExerciseId case final v?) {
      checkLength(out, '$path.referenceExerciseId', v.length, 1, null);
    }
    if (stepExerciseId case final v?) {
      checkLength(out, '$path.stepExerciseId', v.length, 1, null);
    }
    if (rirCap case final v?) {
      checkRange(out, '$path.rirCap', v, 0, 10);
    }
    checkVariant(
      out,
      path,
      basis.code,
      <String, Object?>{
        'value': value,
        'valueHigh': valueHigh,
        'referenceExerciseId': referenceExerciseId,
        'referenceKind': referenceKind,
        'stepExerciseId': stepExerciseId,
      },
      const <String, List<String>>{
        'percent_one_rm': <String>['value'],
        'percent_benchmark': <String>['value', 'referenceKind'],
        'rir': <String>['value'],
        'hold_fraction': <String>['value'],
        'progression_step': <String>['stepExerciseId'],
        'speed_fraction': <String>['value'],
        'heart_rate_fraction': <String>['value'],
      },
      const <String, List<String>>{
        'percent_one_rm': <String>['valueHigh', 'referenceExerciseId'],
        'percent_benchmark': <String>['valueHigh', 'referenceExerciseId'],
        'rir': <String>['valueHigh'],
        'hold_fraction': <String>['valueHigh', 'referenceExerciseId'],
        'progression_step': <String>[],
        'speed_fraction': <String>[
          'valueHigh',
          'referenceKind',
          'referenceExerciseId',
        ],
        'heart_rate_fraction': <String>['valueHigh'],
      },
    );
    _validateIntensityTarget(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (referenceExerciseId case final v?) {
      out.add(v);
    }
    if (stepExerciseId case final v?) {
      out.add(v);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is IntensityTarget &&
            basis == other.basis &&
            value == other.value &&
            valueHigh == other.valueHigh &&
            referenceExerciseId == other.referenceExerciseId &&
            referenceKind == other.referenceKind &&
            stepExerciseId == other.stepExerciseId &&
            rirCap == other.rirCap;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    basis,
    value,
    valueHigh,
    referenceExerciseId,
    referenceKind,
    stepExerciseId,
    rirCap,
  ]);

  @override
  String toString() => 'IntensityTarget(${toJson()})';
}

/// Règle d'autorégulation portée par une prescription (0.4.0) : le moteur
/// dynamique l'exécute pendant la séance.
///
/// Invariant : `rirFloor` ≤ `rirCeiling` ; `minSets` ≤ `maxSets`.
final class AutoregulationRule {
  const AutoregulationRule({
    required this.kind,
    this.pct,
    this.rirFloor,
    this.rirCeiling,
    this.minSets,
    this.maxSets,
    this.repDrop,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AutoregulationRule.fromJson(Map<String, Object?> json) {
    return AutoregulationRule(
      kind: jsonEnum(json, 'kind', AutoregulationKind.fromCode),
      pct: jsonDoubleOrNull(json, 'pct'),
      rirFloor: jsonDoubleOrNull(json, 'rirFloor'),
      rirCeiling: jsonDoubleOrNull(json, 'rirCeiling'),
      minSets: jsonIntOrNull(json, 'minSets'),
      maxSets: jsonIntOrNull(json, 'maxSets'),
      repDrop: jsonIntOrNull(json, 'repDrop'),
    );
  }

  /// Règle.
  final AutoregulationKind kind;

  /// Part : baisse appliquée à la série de tête réalisée
  /// (`backoff_from_top_set`), part du meilleur maintien du jour
  /// (`hold_from_best`), pas de correction de charge par répétition d'écart
  /// (`load_from_rir`).
  final double? pct;

  /// Plancher de répétitions en réserve.
  final double? rirFloor;

  /// Plafond de répétitions en réserve.
  final double? rirCeiling;

  /// Nombre minimal de séries.
  final int? minSets;

  /// Nombre maximal de séries.
  final int? maxSets;

  /// Chute de répétitions, par rapport à la première série, qui arrête
  /// l'exercice.
  final int? repDrop;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (pct case final v?) 'pct': v,
      if (rirFloor case final v?) 'rirFloor': v,
      if (rirCeiling case final v?) 'rirCeiling': v,
      if (minSets case final v?) 'minSets': v,
      if (maxSets case final v?) 'maxSets': v,
      if (repDrop case final v?) 'repDrop': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AutoregulationRule copyWith({
    AutoregulationKind? kind,
    Object? pct = unset,
    Object? rirFloor = unset,
    Object? rirCeiling = unset,
    Object? minSets = unset,
    Object? maxSets = unset,
    Object? repDrop = unset,
  }) {
    return AutoregulationRule(
      kind: kind ?? this.kind,
      pct: identical(pct, unset) ? this.pct : pct as double?,
      rirFloor: identical(rirFloor, unset)
          ? this.rirFloor
          : rirFloor as double?,
      rirCeiling: identical(rirCeiling, unset)
          ? this.rirCeiling
          : rirCeiling as double?,
      minSets: identical(minSets, unset) ? this.minSets : minSets as int?,
      maxSets: identical(maxSets, unset) ? this.maxSets : maxSets as int?,
      repDrop: identical(repDrop, unset) ? this.repDrop : repDrop as int?,
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
    if (pct case final v?) {
      checkRange(out, '$path.pct', v, 0, 1);
    }
    if (rirFloor case final v?) {
      checkRange(out, '$path.rirFloor', v, 0, 10);
    }
    if (rirCeiling case final v?) {
      checkRange(out, '$path.rirCeiling', v, 0, 10);
    }
    if (minSets case final v?) {
      checkRange(out, '$path.minSets', v, 0, 20);
    }
    if (maxSets case final v?) {
      checkRange(out, '$path.maxSets', v, 1, 30);
    }
    if (repDrop case final v?) {
      checkRange(out, '$path.repDrop', v, 1, 50);
    }
    checkVariant(
      out,
      path,
      kind.code,
      <String, Object?>{
        'pct': pct,
        'rirFloor': rirFloor,
        'rirCeiling': rirCeiling,
        'minSets': minSets,
        'maxSets': maxSets,
        'repDrop': repDrop,
      },
      const <String, List<String>>{
        'backoff_from_top_set': <String>['pct'],
        'load_from_rir': <String>['rirFloor', 'rirCeiling'],
        'stop_at_rir': <String>['rirFloor'],
        'stop_on_rep_drop': <String>['repDrop'],
        'hold_from_best': <String>['pct'],
        'last_set_amrap': <String>[],
      },
      const <String, List<String>>{
        'backoff_from_top_set': <String>['rirCeiling', 'minSets', 'maxSets'],
        'load_from_rir': <String>['pct'],
        'stop_at_rir': <String>['minSets', 'maxSets'],
        'stop_on_rep_drop': <String>['minSets', 'maxSets'],
        'hold_from_best': <String>[],
        'last_set_amrap': <String>['rirFloor'],
      },
    );
    _validateAutoregulationRule(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AutoregulationRule &&
            kind == other.kind &&
            pct == other.pct &&
            rirFloor == other.rirFloor &&
            rirCeiling == other.rirCeiling &&
            minSets == other.minSets &&
            maxSets == other.maxSets &&
            repDrop == other.repDrop;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    pct,
    rirFloor,
    rirCeiling,
    minSets,
    maxSets,
    repDrop,
  ]);

  @override
  String toString() => 'AutoregulationRule(${toJson()})';
}

/// Série ou exercice de test (0.4.0), porté par une prescription dont `kind`
/// vaut `test`.
final class TestSpec {
  const TestSpec({
    required this.kind,
    this.protocolId,
    this.targetRir,
    this.attempts,
    this.benchmarkKind,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory TestSpec.fromJson(Map<String, Object?> json) {
    return TestSpec(
      kind: jsonEnum(json, 'kind', TestKind.fromCode),
      protocolId: jsonStringOrNull(json, 'protocolId'),
      targetRir: jsonDoubleOrNull(json, 'targetRir'),
      attempts: jsonIntOrNull(json, 'attempts'),
      benchmarkKind: jsonEnumOrNull(
        json,
        'benchmarkKind',
        BenchmarkKind.fromCode,
      ),
    );
  }

  /// Nature du test.
  final TestKind kind;

  /// Protocole de test guidé (`docs/PARCOURS_V3.md`, § tests guidés).
  final String? protocolId;

  /// Répétitions en réserve à garder (série d'estimation).
  final double? targetRir;

  /// Nombre d'essais au plus (maximum, simulation de tentatives).
  final int? attempts;

  /// Nature de la valeur à reporter dans le profil (`AdaptReview.testResults`).
  final BenchmarkKind? benchmarkKind;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      if (protocolId case final v?) 'protocolId': v,
      if (targetRir case final v?) 'targetRir': v,
      if (attempts case final v?) 'attempts': v,
      if (benchmarkKind case final v?) 'benchmarkKind': v.code,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  TestSpec copyWith({
    TestKind? kind,
    Object? protocolId = unset,
    Object? targetRir = unset,
    Object? attempts = unset,
    Object? benchmarkKind = unset,
  }) {
    return TestSpec(
      kind: kind ?? this.kind,
      protocolId: identical(protocolId, unset)
          ? this.protocolId
          : protocolId as String?,
      targetRir: identical(targetRir, unset)
          ? this.targetRir
          : targetRir as double?,
      attempts: identical(attempts, unset) ? this.attempts : attempts as int?,
      benchmarkKind: identical(benchmarkKind, unset)
          ? this.benchmarkKind
          : benchmarkKind as BenchmarkKind?,
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
    if (protocolId case final v?) {
      checkLength(out, '$path.protocolId', v.length, 1, 40);
    }
    if (targetRir case final v?) {
      checkRange(out, '$path.targetRir', v, 0, 5);
    }
    if (attempts case final v?) {
      checkRange(out, '$path.attempts', v, 1, 6);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TestSpec &&
            kind == other.kind &&
            protocolId == other.protocolId &&
            targetRir == other.targetRir &&
            attempts == other.attempts &&
            benchmarkKind == other.benchmarkKind;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    protocolId,
    targetRir,
    attempts,
    benchmarkKind,
  ]);

  @override
  String toString() => 'TestSpec(${toJson()})';
}
