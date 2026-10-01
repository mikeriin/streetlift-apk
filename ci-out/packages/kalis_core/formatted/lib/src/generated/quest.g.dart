// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Écriture du registre d'XP (ajout seul, D7.3).
final class XpEntry {
  const XpEntry({
    required this.sequence,
    required this.date,
    required this.source,
    required this.amount,
    this.sessionId,
    this.refId,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory XpEntry.fromJson(Map<String, Object?> json) {
    return XpEntry(
      sequence: jsonInt(json, 'sequence'),
      date: jsonDate(json, 'date'),
      source: jsonEnum(json, 'source', XpSource.fromCode),
      amount: jsonInt(json, 'amount'),
      sessionId: jsonStringOrNull(json, 'sessionId'),
      refId: jsonStringOrNull(json, 'refId'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Rang dans le registre.
  final int sequence;

  /// Jour.
  final CivilDate date;

  /// Origine.
  final XpSource source;

  /// XP gagnés (jamais négatifs).
  final int amount;

  /// Séance à l'origine.
  final String? sessionId;

  /// Quête, objectif ou record à l'origine.
  final String? refId;

  /// Pourquoi.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'date': date.iso,
      'source': source.code,
      'amount': amount,
      if (sessionId case final v?) 'sessionId': v,
      if (refId case final v?) 'refId': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  XpEntry copyWith({
    int? sequence,
    CivilDate? date,
    XpSource? source,
    int? amount,
    Object? sessionId = unset,
    Object? refId = unset,
    List<Reason>? reasons,
  }) {
    return XpEntry(
      sequence: sequence ?? this.sequence,
      date: date ?? this.date,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      sessionId: identical(sessionId, unset)
          ? this.sessionId
          : sessionId as String?,
      refId: identical(refId, unset) ? this.refId : refId as String?,
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
    checkRange(out, '$path.sequence', sequence, 0, null);
    checkRange(out, '$path.amount', amount, 0, null);
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
        other is XpEntry &&
            sequence == other.sequence &&
            date == other.date &&
            source == other.source &&
            amount == other.amount &&
            sessionId == other.sessionId &&
            refId == other.refId &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    sequence,
    date,
    source,
    amount,
    sessionId,
    refId,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'XpEntry(${toJson()})';
}

/// Écriture du registre de Krédits (D7.7).
final class KreditEntry {
  const KreditEntry({
    required this.sequence,
    required this.date,
    required this.source,
    required this.amount,
    this.refId,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory KreditEntry.fromJson(Map<String, Object?> json) {
    return KreditEntry(
      sequence: jsonInt(json, 'sequence'),
      date: jsonDate(json, 'date'),
      source: jsonEnum(json, 'source', KreditSource.fromCode),
      amount: jsonInt(json, 'amount'),
      refId: jsonStringOrNull(json, 'refId'),
    );
  }

  /// Rang dans le registre.
  final int sequence;

  /// Jour.
  final CivilDate date;

  /// Origine.
  final KreditSource source;

  /// Krédits gagnés.
  final int amount;

  /// Référence de l'origine.
  final String? refId;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sequence': sequence,
      'date': date.iso,
      'source': source.code,
      'amount': amount,
      if (refId case final v?) 'refId': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  KreditEntry copyWith({
    int? sequence,
    CivilDate? date,
    KreditSource? source,
    int? amount,
    Object? refId = unset,
  }) {
    return KreditEntry(
      sequence: sequence ?? this.sequence,
      date: date ?? this.date,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      refId: identical(refId, unset) ? this.refId : refId as String?,
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
    checkRange(out, '$path.amount', amount, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is KreditEntry &&
            sequence == other.sequence &&
            date == other.date &&
            source == other.source &&
            amount == other.amount &&
            refId == other.refId;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[sequence, date, source, amount, refId]);

  @override
  String toString() => 'KreditEntry(${toJson()})';
}

/// Niveau et prestige (D7.4).
final class LevelState {
  const LevelState({
    required this.level,
    required this.prestige,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory LevelState.fromJson(Map<String, Object?> json) {
    return LevelState(
      level: jsonInt(json, 'level'),
      prestige: jsonInt(json, 'prestige'),
      totalXp: jsonInt(json, 'totalXp'),
      xpIntoLevel: jsonInt(json, 'xpIntoLevel'),
      xpForNextLevel: jsonInt(json, 'xpForNextLevel'),
    );
  }

  /// Niveau.
  final int level;

  /// Prestige.
  final int prestige;

  /// XP acquis à vie.
  final int totalXp;

  /// XP dans le niveau en cours.
  final int xpIntoLevel;

  /// XP du niveau en cours au suivant.
  final int xpForNextLevel;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'level': level,
      'prestige': prestige,
      'totalXp': totalXp,
      'xpIntoLevel': xpIntoLevel,
      'xpForNextLevel': xpForNextLevel,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  LevelState copyWith({
    int? level,
    int? prestige,
    int? totalXp,
    int? xpIntoLevel,
    int? xpForNextLevel,
  }) {
    return LevelState(
      level: level ?? this.level,
      prestige: prestige ?? this.prestige,
      totalXp: totalXp ?? this.totalXp,
      xpIntoLevel: xpIntoLevel ?? this.xpIntoLevel,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
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
    checkRange(out, '$path.level', level, 1, 100);
    checkRange(out, '$path.prestige', prestige, 0, null);
    checkRange(out, '$path.totalXp', totalXp, 0, null);
    checkRange(out, '$path.xpIntoLevel', xpIntoLevel, 0, null);
    checkRange(out, '$path.xpForNextLevel', xpForNextLevel, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LevelState &&
            level == other.level &&
            prestige == other.prestige &&
            totalXp == other.totalXp &&
            xpIntoLevel == other.xpIntoLevel &&
            xpForNextLevel == other.xpForNextLevel;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    level,
    prestige,
    totalXp,
    xpIntoLevel,
    xpForNextLevel,
  ]);

  @override
  String toString() => 'LevelState(${toJson()})';
}

/// Attribut façon RPG (D7.5).
final class AttributeScore {
  const AttributeScore({required this.attribute, required this.value});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory AttributeScore.fromJson(Map<String, Object?> json) {
    return AttributeScore(
      attribute: jsonEnum(json, 'attribute', AthleteAttribute.fromCode),
      value: jsonDouble(json, 'value'),
    );
  }

  /// Attribut.
  final AthleteAttribute attribute;

  /// Valeur, de 0 à 100.
  final double value;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{'attribute': attribute.code, 'value': value};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  AttributeScore copyWith({AthleteAttribute? attribute, double? value}) {
    return AttributeScore(
      attribute: attribute ?? this.attribute,
      value: value ?? this.value,
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
    checkRange(out, '$path.value', value, 0, 100);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttributeScore &&
            attribute == other.attribute &&
            value == other.value;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[attribute, value]);

  @override
  String toString() => 'AttributeScore(${toJson()})';
}

/// Rang sur un mouvement (D7.5).
final class MovementRank {
  const MovementRank({
    required this.exerciseId,
    required this.tier,
    required this.score,
    this.nextTierAt,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory MovementRank.fromJson(Map<String, Object?> json) {
    return MovementRank(
      exerciseId: jsonString(json, 'exerciseId'),
      tier: jsonEnum(json, 'tier', MovementRankTier.fromCode),
      score: jsonDouble(json, 'score'),
      nextTierAt: jsonDoubleOrNull(json, 'nextTierAt'),
    );
  }

  /// Mouvement.
  final String exerciseId;

  /// Rang.
  final MovementRankTier tier;

  /// Performance normalisée utilisée pour le rang.
  final double score;

  /// Performance du rang suivant.
  final double? nextTierAt;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exerciseId': exerciseId,
      'tier': tier.code,
      'score': score,
      if (nextTierAt case final v?) 'nextTierAt': v,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  MovementRank copyWith({
    String? exerciseId,
    MovementRankTier? tier,
    double? score,
    Object? nextTierAt = unset,
  }) {
    return MovementRank(
      exerciseId: exerciseId ?? this.exerciseId,
      tier: tier ?? this.tier,
      score: score ?? this.score,
      nextTierAt: identical(nextTierAt, unset)
          ? this.nextTierAt
          : nextTierAt as double?,
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
    checkRange(out, '$path.score', score, 0, null);
    if (nextTierAt case final v?) {
      checkRange(out, '$path.nextTierAt', v, 0, null);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    out.add(exerciseId);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MovementRank &&
            exerciseId == other.exerciseId &&
            tier == other.tier &&
            score == other.score &&
            nextTierAt == other.nextTierAt;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[exerciseId, tier, score, nextTierAt]);

  @override
  String toString() => 'MovementRank(${toJson()})';
}

/// Quête (D7.6).
final class Quest {
  const Quest({
    required this.id,
    required this.kind,
    required this.template,
    required this.params,
    required this.startsOn,
    this.endsOn,
    required this.progress,
    required this.target,
    required this.status,
    required this.rewardXp,
    required this.rewardKredits,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Quest.fromJson(Map<String, Object?> json) {
    return Quest(
      id: jsonString(json, 'id'),
      kind: jsonEnum(json, 'kind', QuestKind.fromCode),
      template: jsonString(json, 'template'),
      params: jsonObject(json, 'params'),
      startsOn: jsonDate(json, 'startsOn'),
      endsOn: jsonDateOrNull(json, 'endsOn'),
      progress: jsonDouble(json, 'progress'),
      target: jsonDouble(json, 'target'),
      status: jsonEnum(json, 'status', QuestStatus.fromCode),
      rewardXp: jsonInt(json, 'rewardXp'),
      rewardKredits: jsonInt(json, 'rewardKredits'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Identifiant.
  final String id;

  /// Famille.
  final QuestKind kind;

  /// Code du modèle de quête.
  final String template;

  /// Paramètres du modèle.
  final Map<String, Object?> params;

  /// Début.
  final CivilDate startsOn;

  /// Fin.
  final CivilDate? endsOn;

  /// Avancement.
  final double progress;

  /// Cible.
  final double target;

  /// État.
  final QuestStatus status;

  /// XP à la clé.
  final int rewardXp;

  /// Krédits à la clé.
  final int rewardKredits;

  /// Pourquoi cette quête.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.code,
      'template': template,
      'params': params,
      'startsOn': startsOn.iso,
      if (endsOn case final v?) 'endsOn': v.iso,
      'progress': progress,
      'target': target,
      'status': status.code,
      'rewardXp': rewardXp,
      'rewardKredits': rewardKredits,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Quest copyWith({
    String? id,
    QuestKind? kind,
    String? template,
    Map<String, Object?>? params,
    CivilDate? startsOn,
    Object? endsOn = unset,
    double? progress,
    double? target,
    QuestStatus? status,
    int? rewardXp,
    int? rewardKredits,
    List<Reason>? reasons,
  }) {
    return Quest(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      template: template ?? this.template,
      params: params ?? this.params,
      startsOn: startsOn ?? this.startsOn,
      endsOn: identical(endsOn, unset) ? this.endsOn : endsOn as CivilDate?,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      status: status ?? this.status,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardKredits: rewardKredits ?? this.rewardKredits,
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
    checkLength(out, '$path.template', template.length, 1, null);
    checkJson(out, '$path.params', params);
    checkRange(out, '$path.progress', progress, 0, null);
    checkRange(out, '$path.target', target, 0, null);
    checkRange(out, '$path.rewardXp', rewardXp, 0, null);
    checkRange(out, '$path.rewardKredits', rewardKredits, 0, null);
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
        other is Quest &&
            id == other.id &&
            kind == other.kind &&
            template == other.template &&
            jsonDeepEquals(params, other.params) &&
            startsOn == other.startsOn &&
            endsOn == other.endsOn &&
            progress == other.progress &&
            target == other.target &&
            status == other.status &&
            rewardXp == other.rewardXp &&
            rewardKredits == other.rewardKredits &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    kind,
    template,
    jsonDeepHash(params),
    startsOn,
    endsOn,
    progress,
    target,
    status,
    rewardXp,
    rewardKredits,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'Quest(${toJson()})';
}

/// Jalon automatique d'un objectif.
final class Milestone {
  const Milestone({required this.fraction, this.reachedOn});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Milestone.fromJson(Map<String, Object?> json) {
    return Milestone(
      fraction: jsonDouble(json, 'fraction'),
      reachedOn: jsonDateOrNull(json, 'reachedOn'),
    );
  }

  /// Part de l'objectif, de 0 à 1.
  final double fraction;

  /// Jour d'atteinte.
  final CivilDate? reachedOn;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fraction': fraction,
      if (reachedOn case final v?) 'reachedOn': v.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Milestone copyWith({double? fraction, Object? reachedOn = unset}) {
    return Milestone(
      fraction: fraction ?? this.fraction,
      reachedOn: identical(reachedOn, unset)
          ? this.reachedOn
          : reachedOn as CivilDate?,
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
    checkRange(out, '$path.fraction', fraction, 0, 1);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Milestone &&
            fraction == other.fraction &&
            reachedOn == other.reachedOn;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[fraction, reachedOn]);

  @override
  String toString() => 'Milestone(${toJson()})';
}

/// Prédiction de la date d'atteinte d'un objectif.
///
/// Invariant : `earliestOn` ≤ `expectedOn` ≤ `latestOn`.
final class Prediction {
  const Prediction({
    required this.expectedOn,
    required this.earliestOn,
    required this.latestOn,
    required this.confidence,
    required this.method,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Prediction.fromJson(Map<String, Object?> json) {
    return Prediction(
      expectedOn: jsonDate(json, 'expectedOn'),
      earliestOn: jsonDate(json, 'earliestOn'),
      latestOn: jsonDate(json, 'latestOn'),
      confidence: jsonDouble(json, 'confidence'),
      method: jsonString(json, 'method'),
    );
  }

  /// Date attendue.
  final CivilDate expectedOn;

  /// Borne basse.
  final CivilDate earliestOn;

  /// Borne haute.
  final CivilDate latestOn;

  /// Confiance, de 0 à 1.
  final double confidence;

  /// Code de la méthode.
  final String method;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'expectedOn': expectedOn.iso,
      'earliestOn': earliestOn.iso,
      'latestOn': latestOn.iso,
      'confidence': confidence,
      'method': method,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Prediction copyWith({
    CivilDate? expectedOn,
    CivilDate? earliestOn,
    CivilDate? latestOn,
    double? confidence,
    String? method,
  }) {
    return Prediction(
      expectedOn: expectedOn ?? this.expectedOn,
      earliestOn: earliestOn ?? this.earliestOn,
      latestOn: latestOn ?? this.latestOn,
      confidence: confidence ?? this.confidence,
      method: method ?? this.method,
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
    checkRange(out, '$path.confidence', confidence, 0, 1);
    checkLength(out, '$path.method', method.length, 1, null);
    _validatePrediction(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {}

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Prediction &&
            expectedOn == other.expectedOn &&
            earliestOn == other.earliestOn &&
            latestOn == other.latestOn &&
            confidence == other.confidence &&
            method == other.method;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    expectedOn,
    earliestOn,
    latestOn,
    confidence,
    method,
  ]);

  @override
  String toString() => 'Prediction(${toJson()})';
}

/// Avancement d'un objectif du profil.
final class GoalProgress {
  const GoalProgress({
    required this.goalId,
    required this.current,
    required this.target,
    required this.fraction,
    this.achievedOn,
    required this.milestones,
    this.prediction,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory GoalProgress.fromJson(Map<String, Object?> json) {
    return GoalProgress(
      goalId: jsonString(json, 'goalId'),
      current: jsonDouble(json, 'current'),
      target: jsonDouble(json, 'target'),
      fraction: jsonDouble(json, 'fraction'),
      achievedOn: jsonDateOrNull(json, 'achievedOn'),
      milestones: jsonList(
        json,
        'milestones',
        (v) => Milestone.fromJson(jsonAsObject(v, 'milestones')),
      ),
      prediction: jsonObjOrNull(json, 'prediction', Prediction.fromJson),
    );
  }

  /// Objectif.
  final String goalId;

  /// Valeur actuelle.
  final double current;

  /// Valeur cible.
  final double target;

  /// Avancement, de 0 à 1.
  final double fraction;

  /// Jour d'atteinte.
  final CivilDate? achievedOn;

  /// Jalons.
  final List<Milestone> milestones;

  /// Prédiction.
  final Prediction? prediction;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'goalId': goalId,
      'current': current,
      'target': target,
      'fraction': fraction,
      if (achievedOn case final v?) 'achievedOn': v.iso,
      'milestones': [for (final e in milestones) e.toJson()],
      if (prediction case final v?) 'prediction': v.toJson(),
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  GoalProgress copyWith({
    String? goalId,
    double? current,
    double? target,
    double? fraction,
    Object? achievedOn = unset,
    List<Milestone>? milestones,
    Object? prediction = unset,
  }) {
    return GoalProgress(
      goalId: goalId ?? this.goalId,
      current: current ?? this.current,
      target: target ?? this.target,
      fraction: fraction ?? this.fraction,
      achievedOn: identical(achievedOn, unset)
          ? this.achievedOn
          : achievedOn as CivilDate?,
      milestones: milestones ?? this.milestones,
      prediction: identical(prediction, unset)
          ? this.prediction
          : prediction as Prediction?,
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
    checkLength(out, '$path.goalId', goalId.length, 1, null);
    checkRange(out, '$path.current', current, null, null);
    checkRange(out, '$path.target', target, null, null);
    checkRange(out, '$path.fraction', fraction, 0, 1);
    for (var i = 0; i < milestones.length; i++) {
      milestones[i].collectViolations('$path.milestones[$i]', out);
    }
    if (prediction case final v?) {
      v.collectViolations('$path.prediction', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in milestones) {
      e.collectExerciseIds(out);
    }
    prediction?.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GoalProgress &&
            goalId == other.goalId &&
            current == other.current &&
            target == other.target &&
            fraction == other.fraction &&
            achievedOn == other.achievedOn &&
            jsonListEquals(milestones, other.milestones) &&
            prediction == other.prediction;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    goalId,
    current,
    target,
    fraction,
    achievedOn,
    Object.hashAll(milestones),
    prediction,
  ]);

  @override
  String toString() => 'GoalProgress(${toJson()})';
}

/// Événement de plaisir (D8.1).
final class DelightEvent {
  const DelightEvent({
    required this.kind,
    required this.date,
    this.sessionId,
    this.exerciseId,
    this.recordKind,
    this.value,
    this.previousValue,
    this.grade,
    this.combo,
    this.streakWeeks,
    this.kredits,
    required this.reasons,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory DelightEvent.fromJson(Map<String, Object?> json) {
    return DelightEvent(
      kind: jsonEnum(json, 'kind', DelightKind.fromCode),
      date: jsonDate(json, 'date'),
      sessionId: jsonStringOrNull(json, 'sessionId'),
      exerciseId: jsonStringOrNull(json, 'exerciseId'),
      recordKind: jsonEnumOrNull(json, 'recordKind', RecordKind.fromCode),
      value: jsonDoubleOrNull(json, 'value'),
      previousValue: jsonDoubleOrNull(json, 'previousValue'),
      grade: jsonEnumOrNull(json, 'grade', SessionGrade.fromCode),
      combo: jsonIntOrNull(json, 'combo'),
      streakWeeks: jsonIntOrNull(json, 'streakWeeks'),
      kredits: jsonIntOrNull(json, 'kredits'),
      reasons: jsonList(
        json,
        'reasons',
        (v) => Reason.fromJson(jsonAsObject(v, 'reasons')),
      ),
    );
  }

  /// Nature.
  final DelightKind kind;

  /// Jour.
  final CivilDate date;

  /// Séance.
  final String? sessionId;

  /// Exercice.
  final String? exerciseId;

  /// Nature du record.
  final RecordKind? recordKind;

  /// Valeur atteinte.
  final double? value;

  /// Valeur précédente.
  final double? previousValue;

  /// Note de séance.
  final SessionGrade? grade;

  /// Longueur du combo.
  final int? combo;

  /// Série de semaines.
  final int? streakWeeks;

  /// Krédits du coffre.
  final int? kredits;

  /// Raisons.
  final List<Reason> reasons;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.code,
      'date': date.iso,
      if (sessionId case final v?) 'sessionId': v,
      if (exerciseId case final v?) 'exerciseId': v,
      if (recordKind case final v?) 'recordKind': v.code,
      if (value case final v?) 'value': v,
      if (previousValue case final v?) 'previousValue': v,
      if (grade case final v?) 'grade': v.code,
      if (combo case final v?) 'combo': v,
      if (streakWeeks case final v?) 'streakWeeks': v,
      if (kredits case final v?) 'kredits': v,
      'reasons': [for (final e in reasons) e.toJson()],
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  DelightEvent copyWith({
    DelightKind? kind,
    CivilDate? date,
    Object? sessionId = unset,
    Object? exerciseId = unset,
    Object? recordKind = unset,
    Object? value = unset,
    Object? previousValue = unset,
    Object? grade = unset,
    Object? combo = unset,
    Object? streakWeeks = unset,
    Object? kredits = unset,
    List<Reason>? reasons,
  }) {
    return DelightEvent(
      kind: kind ?? this.kind,
      date: date ?? this.date,
      sessionId: identical(sessionId, unset)
          ? this.sessionId
          : sessionId as String?,
      exerciseId: identical(exerciseId, unset)
          ? this.exerciseId
          : exerciseId as String?,
      recordKind: identical(recordKind, unset)
          ? this.recordKind
          : recordKind as RecordKind?,
      value: identical(value, unset) ? this.value : value as double?,
      previousValue: identical(previousValue, unset)
          ? this.previousValue
          : previousValue as double?,
      grade: identical(grade, unset) ? this.grade : grade as SessionGrade?,
      combo: identical(combo, unset) ? this.combo : combo as int?,
      streakWeeks: identical(streakWeeks, unset)
          ? this.streakWeeks
          : streakWeeks as int?,
      kredits: identical(kredits, unset) ? this.kredits : kredits as int?,
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
    if (exerciseId case final v?) {
      checkLength(out, '$path.exerciseId', v.length, 1, null);
    }
    if (value case final v?) {
      checkRange(out, '$path.value', v, null, null);
    }
    if (previousValue case final v?) {
      checkRange(out, '$path.previousValue', v, null, null);
    }
    if (combo case final v?) {
      checkRange(out, '$path.combo', v, 0, null);
    }
    if (streakWeeks case final v?) {
      checkRange(out, '$path.streakWeeks', v, 0, null);
    }
    if (kredits case final v?) {
      checkRange(out, '$path.kredits', v, 0, null);
    }
    for (var i = 0; i < reasons.length; i++) {
      reasons[i].collectViolations('$path.reasons[$i]', out);
    }
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    if (exerciseId case final v?) {
      out.add(v);
    }
    for (final e in reasons) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DelightEvent &&
            kind == other.kind &&
            date == other.date &&
            sessionId == other.sessionId &&
            exerciseId == other.exerciseId &&
            recordKind == other.recordKind &&
            value == other.value &&
            previousValue == other.previousValue &&
            grade == other.grade &&
            combo == other.combo &&
            streakWeeks == other.streakWeeks &&
            kredits == other.kredits &&
            jsonListEquals(reasons, other.reasons);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    kind,
    date,
    sessionId,
    exerciseId,
    recordKind,
    value,
    previousValue,
    grade,
    combo,
    streakWeeks,
    kredits,
    Object.hashAll(reasons),
  ]);

  @override
  String toString() => 'DelightEvent(${toJson()})';
}

/// État persistant du leveling, stocké par l'application.
///
/// Invariant : Registres en ajout seul : `sequence` = rang dans la liste (0,
/// 1, 2…) ; dates croissantes au sens large.
final class QuestState {
  const QuestState({
    this.schemaVersion = currentSchemaVersion,
    required this.xp,
    required this.kredits,
    required this.quests,
    this.lastEvaluatedOn,
    required this.data,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory QuestState.fromJson(Map<String, Object?> json) {
    return QuestState(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      xp: jsonList(json, 'xp', (v) => XpEntry.fromJson(jsonAsObject(v, 'xp'))),
      kredits: jsonList(
        json,
        'kredits',
        (v) => KreditEntry.fromJson(jsonAsObject(v, 'kredits')),
      ),
      quests: jsonList(
        json,
        'quests',
        (v) => Quest.fromJson(jsonAsObject(v, 'quests')),
      ),
      lastEvaluatedOn: jsonDateOrNull(json, 'lastEvaluatedOn'),
      data: jsonObject(json, 'data'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Registre d'XP.
  final List<XpEntry> xp;

  /// Registre de Krédits.
  final List<KreditEntry> kredits;

  /// Quêtes en cours et passées.
  final List<Quest> quests;

  /// Dernier jour évalué.
  final CivilDate? lastEvaluatedOn;

  /// État opaque de kalis_quest.
  final Map<String, Object?> data;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'xp': [for (final e in xp) e.toJson()],
      'kredits': [for (final e in kredits) e.toJson()],
      'quests': [for (final e in quests) e.toJson()],
      if (lastEvaluatedOn case final v?) 'lastEvaluatedOn': v.iso,
      'data': data,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  QuestState copyWith({
    int? schemaVersion,
    List<XpEntry>? xp,
    List<KreditEntry>? kredits,
    List<Quest>? quests,
    Object? lastEvaluatedOn = unset,
    Map<String, Object?>? data,
  }) {
    return QuestState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      xp: xp ?? this.xp,
      kredits: kredits ?? this.kredits,
      quests: quests ?? this.quests,
      lastEvaluatedOn: identical(lastEvaluatedOn, unset)
          ? this.lastEvaluatedOn
          : lastEvaluatedOn as CivilDate?,
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
    checkRange(
      out,
      '$path.schemaVersion',
      schemaVersion,
      1,
      currentSchemaVersion,
    );
    for (var i = 0; i < xp.length; i++) {
      xp[i].collectViolations('$path.xp[$i]', out);
    }
    for (var i = 0; i < kredits.length; i++) {
      kredits[i].collectViolations('$path.kredits[$i]', out);
    }
    for (var i = 0; i < quests.length; i++) {
      quests[i].collectViolations('$path.quests[$i]', out);
    }
    checkJson(out, '$path.data', data);
    _validateQuestState(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    for (final e in xp) {
      e.collectExerciseIds(out);
    }
    for (final e in kredits) {
      e.collectExerciseIds(out);
    }
    for (final e in quests) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestState &&
            schemaVersion == other.schemaVersion &&
            jsonListEquals(xp, other.xp) &&
            jsonListEquals(kredits, other.kredits) &&
            jsonListEquals(quests, other.quests) &&
            lastEvaluatedOn == other.lastEvaluatedOn &&
            jsonDeepEquals(data, other.data);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    Object.hashAll(xp),
    Object.hashAll(kredits),
    Object.hashAll(quests),
    lastEvaluatedOn,
    jsonDeepHash(data),
  ]);

  @override
  String toString() => 'QuestState(${toJson()})';
}

/// Entrée du moteur de leveling.
final class QuestInput {
  const QuestInput({
    this.schemaVersion = currentSchemaVersion,
    required this.profile,
    required this.log,
    this.block,
    this.adaptation,
    required this.state,
    required this.today,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory QuestInput.fromJson(Map<String, Object?> json) {
    return QuestInput(
      schemaVersion: jsonInt(json, 'schemaVersion'),
      profile: jsonObj(json, 'profile', AthleteProfile.fromJson),
      log: jsonObj(json, 'log', TrainingLog.fromJson),
      block: jsonObjOrNull(json, 'block', ProgramBlock.fromJson),
      adaptation: jsonObjOrNull(json, 'adaptation', AdaptationSummary.fromJson),
      state: jsonObj(json, 'state', QuestState.fromJson),
      today: jsonDate(json, 'today'),
    );
  }

  /// Version courante du schéma JSON de ce type.
  static const int currentSchemaVersion = 1;

  /// Version du schéma (1).
  final int schemaVersion;

  /// Profil.
  final AthleteProfile profile;

  /// Journal complet.
  final TrainingLog log;

  /// Bloc en cours.
  final ProgramBlock? block;

  /// Résumé d'adaptation.
  final AdaptationSummary? adaptation;

  /// État précédent.
  final QuestState state;

  /// « Aujourd'hui », fourni par l'application.
  final CivilDate today;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'profile': profile.toJson(),
      'log': log.toJson(),
      if (block case final v?) 'block': v.toJson(),
      if (adaptation case final v?) 'adaptation': v.toJson(),
      'state': state.toJson(),
      'today': today.iso,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  QuestInput copyWith({
    int? schemaVersion,
    AthleteProfile? profile,
    TrainingLog? log,
    Object? block = unset,
    Object? adaptation = unset,
    QuestState? state,
    CivilDate? today,
  }) {
    return QuestInput(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      profile: profile ?? this.profile,
      log: log ?? this.log,
      block: identical(block, unset) ? this.block : block as ProgramBlock?,
      adaptation: identical(adaptation, unset)
          ? this.adaptation
          : adaptation as AdaptationSummary?,
      state: state ?? this.state,
      today: today ?? this.today,
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
    log.collectViolations('$path.log', out);
    if (block case final v?) {
      v.collectViolations('$path.block', out);
    }
    if (adaptation case final v?) {
      v.collectViolations('$path.adaptation', out);
    }
    state.collectViolations('$path.state', out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    profile.collectExerciseIds(out);
    log.collectExerciseIds(out);
    block?.collectExerciseIds(out);
    adaptation?.collectExerciseIds(out);
    state.collectExerciseIds(out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestInput &&
            schemaVersion == other.schemaVersion &&
            profile == other.profile &&
            log == other.log &&
            block == other.block &&
            adaptation == other.adaptation &&
            state == other.state &&
            today == other.today;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    schemaVersion,
    profile,
    log,
    block,
    adaptation,
    state,
    today,
  ]);

  @override
  String toString() => 'QuestInput(${toJson()})';
}

/// Résultat du moteur de leveling.
final class QuestOutcome {
  const QuestOutcome({
    required this.state,
    required this.level,
    required this.attributes,
    required this.ranks,
    required this.goals,
    required this.events,
    required this.kreditBalance,
  });

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory QuestOutcome.fromJson(Map<String, Object?> json) {
    return QuestOutcome(
      state: jsonObj(json, 'state', QuestState.fromJson),
      level: jsonObj(json, 'level', LevelState.fromJson),
      attributes: jsonList(
        json,
        'attributes',
        (v) => AttributeScore.fromJson(jsonAsObject(v, 'attributes')),
      ),
      ranks: jsonList(
        json,
        'ranks',
        (v) => MovementRank.fromJson(jsonAsObject(v, 'ranks')),
      ),
      goals: jsonList(
        json,
        'goals',
        (v) => GoalProgress.fromJson(jsonAsObject(v, 'goals')),
      ),
      events: jsonList(
        json,
        'events',
        (v) => DelightEvent.fromJson(jsonAsObject(v, 'events')),
      ),
      kreditBalance: jsonInt(json, 'kreditBalance'),
    );
  }

  /// Nouvel état (les registres ne perdent jamais d'écriture).
  final QuestState state;

  /// Niveau et prestige.
  final LevelState level;

  /// Attributs.
  final List<AttributeScore> attributes;

  /// Rangs par mouvement.
  final List<MovementRank> ranks;

  /// Avancement des objectifs.
  final List<GoalProgress> goals;

  /// Événements de plaisir nouveaux.
  final List<DelightEvent> events;

  /// Solde de Krédits.
  final int kreditBalance;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.toJson(),
      'level': level.toJson(),
      'attributes': [for (final e in attributes) e.toJson()],
      'ranks': [for (final e in ranks) e.toJson()],
      'goals': [for (final e in goals) e.toJson()],
      'events': [for (final e in events) e.toJson()],
      'kreditBalance': kreditBalance,
    };
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  QuestOutcome copyWith({
    QuestState? state,
    LevelState? level,
    List<AttributeScore>? attributes,
    List<MovementRank>? ranks,
    List<GoalProgress>? goals,
    List<DelightEvent>? events,
    int? kreditBalance,
  }) {
    return QuestOutcome(
      state: state ?? this.state,
      level: level ?? this.level,
      attributes: attributes ?? this.attributes,
      ranks: ranks ?? this.ranks,
      goals: goals ?? this.goals,
      events: events ?? this.events,
      kreditBalance: kreditBalance ?? this.kreditBalance,
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
    state.collectViolations('$path.state', out);
    level.collectViolations('$path.level', out);
    for (var i = 0; i < attributes.length; i++) {
      attributes[i].collectViolations('$path.attributes[$i]', out);
    }
    for (var i = 0; i < ranks.length; i++) {
      ranks[i].collectViolations('$path.ranks[$i]', out);
    }
    for (var i = 0; i < goals.length; i++) {
      goals[i].collectViolations('$path.goals[$i]', out);
    }
    for (var i = 0; i < events.length; i++) {
      events[i].collectViolations('$path.events[$i]', out);
    }
    checkRange(out, '$path.kreditBalance', kreditBalance, 0, null);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    state.collectExerciseIds(out);
    level.collectExerciseIds(out);
    for (final e in attributes) {
      e.collectExerciseIds(out);
    }
    for (final e in ranks) {
      e.collectExerciseIds(out);
    }
    for (final e in goals) {
      e.collectExerciseIds(out);
    }
    for (final e in events) {
      e.collectExerciseIds(out);
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestOutcome &&
            state == other.state &&
            level == other.level &&
            jsonListEquals(attributes, other.attributes) &&
            jsonListEquals(ranks, other.ranks) &&
            jsonListEquals(goals, other.goals) &&
            jsonListEquals(events, other.events) &&
            kreditBalance == other.kreditBalance;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    state,
    level,
    Object.hashAll(attributes),
    Object.hashAll(ranks),
    Object.hashAll(goals),
    Object.hashAll(events),
    kreditBalance,
  ]);

  @override
  String toString() => 'QuestOutcome(${toJson()})';
}
