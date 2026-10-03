// CU (dev6.8.0, PIPELINE_CP) : profil v3 (`kalis_core` 0.4.0) dans le
// parcours de création du profil (G6).
//
// Modèle pur (aucune dépendance Flutter) : réponses du schéma 3 du
// brouillon (JSON du contrat, lues et écrites par des accesseurs typés),
// conditions d'apparition déléguées à `ProfileQuestionnaire` (l'application
// n'en code aucune), réponses devenues sans objet retirées, questions à
// compléter, libellés propres à l'application (points faibles par
// mouvement) et propositions de mouvements (records, figures, charge
// actuelle).
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';

import 'athlete_profile.dart';

/// Message quand le poids est obligatoire (mode street, disciplines au
/// poids du corps : `requiredWhen` de `body_weight`).
const kWeightRequiredError =
    'Indique ton poids : en street et au poids du corps, il sert à doser '
    'chaque série.';

/// JSON canonique d'un objet (comparaisons de réponses).
String jsonEncodeMap(Map<String, Object?> m) => jsonEncode(m);

/// Objet JSON lu ; vide s'il est illisible.
Map<String, Object?> jsonDecodeMap(String s) {
  try {
    final v = jsonDecode(s);
    return v is Map ? v.cast<String, Object?>() : const {};
  } catch (_) {
    return const {};
  }
}

// ============================================================ étapes, écrans

/// Étape du flux de création (G6) → écran du parcours v3
/// (`docs/PARCOURS_V3.md`).
const kStepScreens = <String, String>{
  'identity': 'toi',
  'discipline': 'discipline',
  'secondary': 'dosage',
  'experience': 'experience',
  'levels': 'niveaux',
  'goals': 'objectifs',
  'availability': 'disponibilites',
  'places': 'lieux',
  'recovery': 'recuperation',
  'health': 'sante',
  'preferences': 'preferences',
  'mode': 'mode',
};

/// Étape du flux qui porte un écran du parcours.
String? stepOfScreen(String screen) {
  for (final e in kStepScreens.entries) {
    if (e.value == screen) return e.key;
  }
  return null;
}

/// Clés JSON du schéma 3 au niveau du profil (`schema3FieldsPresent`, hors
/// détails des gênes, portés par `limitations`).
const kSchema3Keys = [
  'trainingAge',
  'trainingGap',
  'sleep',
  'stress',
  'occupationalLoad',
  'otherSports',
  'bodyWeightGoal',
  'benchmarks',
  'events',
  'skills',
  'weakPoints',
  'specialization',
  'recentTraining',
  'currentPhase',
  'emphasis',
  'enduranceBase',
  'targetBodyWeightKg',
  'lifestyleUpdatedOn',
];

/// Réponses datées par `lifestyleUpdatedOn` (écran Récupération et charge
/// actuelle : elles vieillissent, PARCOURS_V3.md § 3).
const kLifestyleKeys = [
  'sleep',
  'stress',
  'occupationalLoad',
  'otherSports',
  'bodyWeightGoal',
  'targetBodyWeightKg',
  'recentTraining',
  'currentPhase',
];

// ============================================== réponses typées du brouillon

T? _enumOf<T>(Object? v, T Function(String) f) {
  if (v is! String) return null;
  try {
    return f(v);
  } on FormatException {
    return null;
  }
}

List<T>? _listOf<T>(Object? v, T Function(Map<String, Object?>) f) {
  if (v is! List) return null;
  try {
    return [for (final x in v) f((x as Map).cast<String, Object?>())];
  } catch (_) {
    return null;
  }
}

T? _objOf<T>(Object? v, T Function(Map<String, Object?>) f) {
  if (v is! Map) return null;
  try {
    return f(v.cast<String, Object?>());
  } catch (_) {
    return null;
  }
}

/// Réponses du schéma 3 du brouillon, typées (stockées en JSON du contrat
/// dans [ProfileDraft.v3] : une réponse absente reste absente, D5.8).
extension DraftV3 on ProfileDraft {
  void _put(String key, Object? value) {
    if (value == null) {
      v3.remove(key);
    } else {
      v3[key] = value;
    }
  }

  TrainingAge? get trainingAge =>
      _enumOf(v3['trainingAge'], TrainingAge.fromCode);
  set trainingAge(TrainingAge? v) => _put('trainingAge', v?.code);

  TrainingGap? get trainingGap =>
      _enumOf(v3['trainingGap'], TrainingGap.fromCode);
  set trainingGap(TrainingGap? v) => _put('trainingGap', v?.code);

  SleepBand? get sleep => _enumOf(v3['sleep'], SleepBand.fromCode);
  set sleep(SleepBand? v) => _put('sleep', v?.code);

  StressBand? get stress => _enumOf(v3['stress'], StressBand.fromCode);
  set stress(StressBand? v) => _put('stress', v?.code);

  OccupationalLoad? get occupationalLoad =>
      _enumOf(v3['occupationalLoad'], OccupationalLoad.fromCode);
  set occupationalLoad(OccupationalLoad? v) =>
      _put('occupationalLoad', v?.code);

  List<OtherSport>? get otherSports =>
      _listOf(v3['otherSports'], OtherSport.fromJson);
  set otherSports(List<OtherSport>? v) =>
      _put('otherSports', v == null ? null : [for (final x in v) x.toJson()]);

  BodyWeightGoal? get bodyWeightGoal =>
      _enumOf(v3['bodyWeightGoal'], BodyWeightGoal.fromCode);
  set bodyWeightGoal(BodyWeightGoal? v) {
    _put('bodyWeightGoal', v?.code);
    if (v != BodyWeightGoal.lose && v != BodyWeightGoal.gain) {
      v3.remove('targetBodyWeightKg');
    }
  }

  double? get targetBodyWeightKg {
    final v = v3['targetBodyWeightKg'];
    return v is num ? v.toDouble() : null;
  }

  set targetBodyWeightKg(double? v) => _put('targetBodyWeightKg', v);

  List<Benchmark>? get benchmarks =>
      _listOf(v3['benchmarks'], Benchmark.fromJson);
  set benchmarks(List<Benchmark>? v) =>
      _put('benchmarks', v == null ? null : [for (final x in v) x.toJson()]);

  List<SeasonEvent>? get events => _listOf(v3['events'], SeasonEvent.fromJson);
  set events(List<SeasonEvent>? v) =>
      _put('events', v == null ? null : [for (final x in v) x.toJson()]);

  List<SkillState>? get skills => _listOf(v3['skills'], SkillState.fromJson);
  set skills(List<SkillState>? v) =>
      _put('skills', v == null ? null : [for (final x in v) x.toJson()]);

  List<WeakPoint>? get weakPoints =>
      _listOf(v3['weakPoints'], WeakPoint.fromJson);
  set weakPoints(List<WeakPoint>? v) =>
      _put('weakPoints', v == null ? null : [for (final x in v) x.toJson()]);

  Specialization? get specialization =>
      _objOf(v3['specialization'], Specialization.fromJson);
  set specialization(Specialization? v) =>
      _put('specialization', v?.toJson());

  List<RecentTraining>? get recentTraining =>
      _listOf(v3['recentTraining'], RecentTraining.fromJson);
  set recentTraining(List<RecentTraining>? v) => _put(
    'recentTraining',
    v == null ? null : [for (final x in v) x.toJson()],
  );

  CurrentPhase? get currentPhase =>
      _enumOf(v3['currentPhase'], CurrentPhase.fromCode);
  set currentPhase(CurrentPhase? v) => _put('currentPhase', v?.code);

  TrainingEmphasis? get emphasis =>
      _enumOf(v3['emphasis'], TrainingEmphasis.fromCode);
  set emphasis(TrainingEmphasis? v) => _put('emphasis', v?.code);

  EnduranceBase? get enduranceBase =>
      _objOf(v3['enduranceBase'], EnduranceBase.fromJson);
  set enduranceBase(EnduranceBase? v) => _put('enduranceBase', v?.toJson());

  /// Réponses datées (récupération, charge actuelle), en JSON comparable.
  Map<String, Object?> get lifestyleJson => {
    for (final k in kLifestyleKeys)
      if (v3[k] != null) k: v3[k],
  };

  /// Vrai si la réponse à la question [q] est donnée (au moins un de ses
  /// champs du schéma 3 est présent, une liste vide comprise).
  bool answered(ProfileQuestion q) {
    for (final f in q.fields) {
      final key = f.split('.').first;
      if (v3.containsKey(key)) return true;
    }
    return false;
  }

  /// Retire les champs écrits par la question [q] (« Passer »).
  void clearQuestion(ProfileQuestion q) {
    for (final f in q.fields) {
      v3.remove(f.split('.').first);
    }
  }

  /// JSON du profil en cours de saisie, lu par les conditions du parcours
  /// (`ProfileQuestionnaire`) : ce qui est déjà répondu, rien d'inventé.
  Map<String, Object?> conditionJson() {
    final w = weightValue;
    final m = mix;
    final s = street ? streetMode : null;
    return <String, Object?>{
      'schemaVersion': 3,
      if (birthYearValue != null) 'birthYear': birthYearValue,
      if (w != null && !w.isNaN) 'bodyWeightKg': w,
      if (m != null) 'disciplines': m.toJson(),
      if (s != null) 'streetMode': s.toJson(),
      if (experience != null) 'experience': experience!.code,
      'goals': [for (final g in goals) g.toJson()],
      ...v3,
    };
  }

  /// Poids de corps obligatoire pour ce profil (`requiredWhen` de
  /// `body_weight` : mode street et disciplines au poids du corps).
  bool weightRequired(ProfileQuestionnaire? parcours, int year) {
    final q = parcours?.question('body_weight');
    if (parcours == null || q == null) return false;
    return parcours.isRequired(q, conditionJson(), todayYear: year);
  }

  /// Retire les réponses du schéma 3 des questions qui ne s'appliquent plus
  /// à ce profil (discipline ou niveau changés) : une question posée
  /// « seulement à ceux pour qui elle compte » (C1.6) ne laisse pas de
  /// réponse orpheline. Les questions reportées restent valables.
  void pruneHidden(ProfileQuestionnaire parcours, int year) {
    for (var round = 0; round < 6; round++) {
      final visible = {
        for (final q in parcours.visibleQuestions(
          conditionJson(),
          todayYear: year,
          includeDeferred: true,
        ))
          q.id,
      };
      var changed = false;
      for (final q in parcours.questions) {
        if (q.since < 3 || visible.contains(q.id) || !answered(q)) continue;
        clearQuestion(q);
        changed = true;
      }
      if (!changed) break;
    }
    if (lifestyleJson.isEmpty) v3.remove('lifestyleUpdatedOn');
  }
}

// ======================================================= textes du parcours

/// Texte de Koach d'une question (`koach`), ou null.
String? koachOf(ProfileQuestion q) => q.json['koach'] as String?;

/// Champ [name] d'un élément de liste d'une question (`items`).
Map<String, Object?>? itemField(ProfileQuestion q, String name) {
  final items = q.json['items'];
  if (items is! List) return null;
  for (final i in items) {
    if (i is Map && i['field'] == name) return i.cast<String, Object?>();
  }
  return null;
}

/// Texte d'un champ d'élément (repli : [fallback]).
String itemText(ProfileQuestion q, String name, String fallback) =>
    itemField(q, name)?['text'] as String? ?? fallback;

/// Réponses d'un champ d'élément : (code, libellé).
List<(String, String)> itemOptions(ProfileQuestion q, String name) {
  final opts = itemField(q, name)?['options'];
  if (opts is! List) return const [];
  return [
    for (final o in opts)
      if (o is Map) ('${o['code']}', '${o['label']}'),
  ];
}

/// Libellé d'une réponse d'une question à choix (repli : le code).
String optionLabel(ProfileQuestion q, String code) {
  for (final o in q.options) {
    if (o.code == code) return o.label;
  }
  return code;
}

/// Libellé d'une réponse d'un champ d'élément (repli : le code).
String itemOptionLabel(ProfileQuestion q, String field, String code) {
  for (final o in itemOptions(q, field)) {
    if (o.$1 == code) return o.$2;
  }
  return code;
}

// ======================================================== points faibles

/// Famille de mouvement pour les libellés des points faibles (E30 de
/// RELECTURES_CQ.md : traction et muscle-up écrits par CQ ; dips et squat
/// écrits par CU sur le même modèle).
enum WeakFamily { pull, muscleUp, dips, squat, other }

WeakFamily weakFamilyOf(CatalogExercise e) {
  final id = e.id.toLowerCase();
  if (e.pattern == MovementPattern.transitionMuscleUp ||
      id.contains('muscle-up') ||
      id.contains('muscle_up')) {
    return WeakFamily.muscleUp;
  }
  if (e.pattern == MovementPattern.tirageVertical) return WeakFamily.pull;
  if (e.pattern == MovementPattern.pousseeVerticaleBasse ||
      id.contains('dips')) {
    return WeakFamily.dips;
  }
  if (e.pattern == MovementPattern.squat) return WeakFamily.squat;
  return WeakFamily.other;
}

/// Réponses proposées pour un mouvement, libellées pour lui (codes du
/// contrat inchangés). `other` : toutes les réponses du parcours.
List<(WeakPointKind, String)> weakPointChoices(
  WeakFamily f,
  ProfileQuestion? q,
) {
  switch (f) {
    case WeakFamily.pull:
      return const [
        (WeakPointKind.bottom, 'Au départ, bras tendus'),
        (WeakPointKind.midRange, 'À mi-hauteur'),
        (WeakPointKind.lockout, 'En haut, le menton ne passe pas'),
        (WeakPointKind.grip, 'La prise lâche'),
        (WeakPointKind.lateSetFatigue, 'Je m’écroule en fin de série'),
        (WeakPointKind.speed, 'Je manque de vitesse'),
      ];
    case WeakFamily.muscleUp:
      return const [
        (WeakPointKind.bottom, 'Tirage pas assez haut'),
        (WeakPointKind.transition, 'Transition'),
        (WeakPointKind.lockout, 'Sortie en dips'),
        (WeakPointKind.grip, 'La prise lâche'),
        (WeakPointKind.speed, 'Je manque d’explosivité'),
        (WeakPointKind.lateSetFatigue, 'Je m’écroule en fin de série'),
      ];
    case WeakFamily.dips:
      return const [
        (WeakPointKind.bottom, 'En bas, je ne remonte pas'),
        (WeakPointKind.midRange, 'À mi-hauteur'),
        (WeakPointKind.lockout, 'En haut, les bras ne se tendent pas'),
        (WeakPointKind.lateSetFatigue, 'Je m’écroule en fin de série'),
        (WeakPointKind.speed, 'Je manque de vitesse'),
      ];
    case WeakFamily.squat:
      return const [
        (WeakPointKind.bottom, 'En bas, je ne remonte pas'),
        (WeakPointKind.midRange, 'À mi-montée'),
        (WeakPointKind.lockout, 'En fin de montée'),
        (WeakPointKind.mobility, 'Je ne descends pas assez bas (souplesse)'),
        (WeakPointKind.balance, 'L’équilibre'),
        (WeakPointKind.lateSetFatigue, 'Je m’écroule en fin de série'),
      ];
    case WeakFamily.other:
      final out = <(WeakPointKind, String)>[];
      for (final o in q == null ? const <(String, String)>[] : itemOptions(q, 'kind')) {
        final k = _enumOf(o.$1, WeakPointKind.fromCode);
        if (k != null) out.add((k, o.$2));
      }
      if (out.isNotEmpty) return out;
      return [for (final k in WeakPointKind.values) (k, k.code)];
  }
}

/// Libellé d'un point faible pour un mouvement.
String weakPointLabel(
  WeakPointKind k,
  CatalogExercise? e,
  ProfileQuestion? q,
) {
  final f = e == null ? WeakFamily.other : weakFamilyOf(e);
  for (final c in weakPointChoices(f, q)) {
    if (c.$1 == k) return c.$2;
  }
  return q == null ? k.code : itemOptionLabel(q, 'kind', k.code);
}

// =============================================== mouvements proposés

/// Mouvements de compétition et principaux d'une discipline (records,
/// charge actuelle) : identifiants du catalogue, du plus parlant au moins
/// parlant. Choix du lot, à partir des mouvements de référence (G6) et des
/// préréglages de règlement de CQ.
const kDisciplineMainExercises = <TrainingDiscipline, List<String>>{
  TrainingDiscipline.streetlifting: [
    'sl-traction-lestee',
    'sl-dips-leste',
    'sl-muscle-up-leste',
    'sl-squat-competition',
  ],
};

/// Exercices proposés d'abord pour les records : mouvements de compétition
/// de la discipline, puis ses mouvements principaux (fourchettes de G6) ;
/// la course d'abord quand le cardio est la discipline principale.
List<String> benchmarkSuggestions(ProfileDraft d, Catalog? catalog) {
  final out = <String>[];
  void add(String id) {
    if ((catalog == null || catalog.find(id) != null) && !out.contains(id)) {
      out.add(id);
    }
  }

  final ds = d.disciplines;
  if (ds.isNotEmpty && ds.first == TrainingDiscipline.cardio) {
    for (final m in kLevelMovements) {
      if (m.measure == LevelMeasure.timeSeconds) add(m.exerciseId);
    }
  }
  for (final disc in ds) {
    for (final id in kDisciplineMainExercises[disc] ?? const <String>[]) {
      add(id);
    }
  }
  for (final m in d.movements) {
    add(m.exerciseId);
  }
  return out;
}

/// Figures du catalogue qui ont une chaîne `variante_de` (cibles de la
/// question `skills`) : figures statiques ou dynamiques avec au moins une
/// étape de progression. Muscle-up, équilibre et L-sit d'abord quand le
/// streetlifting ou le CrossFit est choisi (PARCOURS_V3.md, `skills`).
List<CatalogExercise> skillTargets(Catalog catalog, ProfileDraft d) {
  final all = <CatalogExercise>[];
  for (final e in catalog.exercises) {
    if (e.family != MovementFamily.figureStatique &&
        e.family != MovementFamily.figureDynamique) {
      continue;
    }
    if (e.depth != 0) continue;
    try {
      if (catalog.progressionCandidates(e.id).length < 2) continue;
    } on ArgumentError {
      continue;
    }
    all.add(e);
  }
  final strengthFirst = d.disciplines.any(
    (x) =>
        x == TrainingDiscipline.streetlifting ||
        x == TrainingDiscipline.crossfit,
  );
  if (!strengthFirst) return all;
  bool first(CatalogExercise e) {
    final n = Catalog.normalizeLabel(e.name);
    return n.contains('muscle') ||
        n.contains('equilibre') ||
        n.contains('l-sit') ||
        n.contains('l sit');
  }

  return [...all.where(first), ...all.where((e) => !first(e))];
}

/// Lignes pré-remplies de la charge actuelle (`recent_training`) : records
/// saisis, mouvements de compétition ou principaux, figures saisies ; 4 au
/// plus.
List<String> recentTrainingSuggestions(ProfileDraft d, Catalog? catalog) {
  final out = <String>[];
  void add(String id) {
    if (out.length >= 4 || out.contains(id)) return;
    if (catalog != null && catalog.find(id) == null) return;
    out.add(id);
  }

  for (final b in d.benchmarks ?? const <Benchmark>[]) {
    add(b.exerciseId);
  }
  for (final disc in d.disciplines) {
    for (final id in kDisciplineMainExercises[disc] ?? const <String>[]) {
      add(id);
    }
  }
  for (final s in d.skills ?? const <SkillState>[]) {
    add(s.currentExerciseId);
  }
  for (final m in d.movements) {
    add(m.exerciseId);
  }
  return out;
}

/// Mouvements sur lesquels demander les points faibles : ceux des records,
/// puis ceux des fourchettes déclarées (connues).
List<String> weakPointExercises(ProfileDraft d) {
  final out = <String>[];
  for (final b in d.benchmarks ?? const <Benchmark>[]) {
    if (!out.contains(b.exerciseId)) out.add(b.exerciseId);
  }
  for (final l in d.movementLevels) {
    if (l.known && !out.contains(l.exerciseId)) out.add(l.exerciseId);
  }
  return out;
}

// ================================================= questions à compléter

/// Questions du schéma 3 à proposer par « Compléter mon profil » : visibles
/// pour ce profil (reportées comprises), sans réponse et pas passées
/// ([skipped], tenu par l'application hors du profil).
List<ProfileQuestion> pendingQuestions(
  ProfileQuestionnaire parcours,
  AthleteProfile profile,
  int year, {
  Set<String> skipped = const {},
}) {
  final json = profile.toJson();
  final out = <ProfileQuestion>[];
  for (final q in parcours.visibleQuestions(
    json,
    todayYear: year,
    since: 3,
    includeDeferred: true,
  )) {
    if (skipped.contains(q.id)) continue;
    var has = false;
    for (final f in q.fields) {
      if (json.containsKey(f.split('.').first)) has = true;
    }
    if (!has) out.add(q);
  }
  return out;
}

/// Nombre de questions vues à la création pour un profil (PARCOURS_V3.md
/// § 2) : celles que montre le parcours, reportées exclues.
int creationQuestionCount(
  ProfileQuestionnaire parcours,
  Map<String, Object?> profileJson,
  int year,
) => parcours.visibleQuestions(profileJson, todayYear: year).length;
