/// Catalogue d'exercices compilé : la base v1.1 du propriétaire et ses
/// champs calculés par règles (`tools/catalog/`), avec ses index, le graphe
/// `variante_de` et une proximité de base entre exercices.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'contracts.dart';
import 'json_util.dart';

/// Fraction de la masse du corps mobilisée par un exercice au poids du
/// corps ou lesté.
final class BodyweightFraction {
  /// Fraction [value], d'origine [source].
  const BodyweightFraction({
    required this.value,
    required this.source,
    required this.reference,
    required this.note,
  });

  /// Fraction de la masse du corps, de 0 à 1.
  final double value;

  /// Valeur publiée, dérivée d'une publication, ou estimée.
  final FractionSource source;

  /// Clé de la référence (`suprak2011`, `ebben2011`, `winter2009`), absente
  /// pour une estimation.
  final String? reference;

  /// Ce que la valeur représente.
  final String note;
}

/// Exercice du catalogue : champs de la base et champs calculés.
final class CatalogExercise {
  CatalogExercise._({
    required this.id,
    required this.name,
    required this.aliases,
    required this.discipline,
    required this.category,
    required this.variantOf,
    required this.level,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.stabilizerMuscles,
    required this.stretchedMuscles,
    required this.keyPoints,
    required this.commonMistakes,
    required this.breathing,
    required this.equipment,
    required this.pattern,
    required this.family,
    required this.plane,
    required this.articularity,
    required this.contractionMode,
    required this.difficulty,
    required this.places,
    required this.jointStress,
    required this.prerequisites,
    required this.systemicFatigue,
    required this.localFatigue,
    required this.loadType,
    required this.assisted,
    required this.bodyweightFraction,
    required this.unit,
    required this.laterality,
    required this.rootId,
    required this.depth,
    required this.muscleIndices,
    required this.muscleWeights,
  }) : _norm = _vectorNorm(muscleWeights);

  factory CatalogExercise._fromJson(
    Map<String, Object?> json,
    List<String> muscles,
  ) {
    final calc = jsonObject(json, 'calc');
    final stress = jsonObject(calc, 'contraintes');
    final fatigue = jsonObject(calc, 'fatigue');
    final fraction = jsonObjectOrNull(calc, 'fraction_pdc');
    final vector = jsonList(calc, 'vecteur', (v) => v);
    final indices = <int>[];
    final weights = <double>[];
    for (final pair in vector) {
      if (pair is! List<Object?> || pair.length != 2) {
        throw const FormatException('Champ "vecteur" : paires attendues');
      }
      final index = jsonAsInt(pair[0], 'vecteur');
      if (index < 0 || index >= muscles.length) {
        throw FormatException('Champ "vecteur" : muscle inconnu', index);
      }
      indices.add(index);
      weights.add(jsonAsDouble(pair[1], 'vecteur'));
    }
    List<String> strings(Map<String, Object?> source, String key) =>
        jsonList(source, key, (v) => jsonAsString(v, key));
    return CatalogExercise._(
      id: jsonString(json, 'id'),
      name: jsonString(json, 'nom'),
      aliases: strings(json, 'alias'),
      discipline: jsonEnum(json, 'discipline', CatalogDiscipline.fromCode),
      category: jsonString(json, 'categorie'),
      variantOf: jsonStringOrNull(json, 'variante_de'),
      level: jsonEnum(json, 'niveau', ExerciseLevel.fromCode),
      primaryMuscles: strings(json, 'muscles_principaux'),
      secondaryMuscles: strings(json, 'muscles_secondaires'),
      stabilizerMuscles: strings(json, 'muscles_stabilisateurs'),
      stretchedMuscles: strings(json, 'muscles_etires'),
      keyPoints: strings(json, 'points_cles'),
      commonMistakes: strings(json, 'erreurs_frequentes'),
      breathing: jsonString(json, 'respiration'),
      equipment: strings(json, 'materiel'),
      pattern: jsonEnum(calc, 'schema', MovementPattern.fromCode),
      family: jsonEnum(calc, 'famille', MovementFamily.fromCode),
      plane: jsonEnum(calc, 'plan', MovementPlane.fromCode),
      articularity: jsonEnum(calc, 'articularite', Articularity.fromCode),
      contractionMode: jsonEnum(calc, 'regime', ContractionMode.fromCode),
      difficulty: jsonInt(calc, 'difficulte'),
      places: jsonList(
        calc,
        'lieux',
        (v) => Place.fromCode(jsonAsString(v, 'lieux')),
      ),
      jointStress: Map<Joint, JointStress>.unmodifiable(<Joint, JointStress>{
        for (final joint in Joint.values)
          joint: jsonEnum(stress, joint.code, JointStress.fromCode),
      }),
      prerequisites: strings(calc, 'prerequis'),
      systemicFatigue: jsonInt(fatigue, 'systemique'),
      localFatigue: jsonInt(fatigue, 'locale'),
      loadType: jsonEnum(calc, 'type_charge', LoadType.fromCode),
      assisted: jsonBool(calc, 'assiste'),
      bodyweightFraction: fraction == null
          ? null
          : BodyweightFraction(
              value: jsonDouble(fraction, 'valeur'),
              source: jsonEnum(fraction, 'source', FractionSource.fromCode),
              reference: jsonStringOrNull(fraction, 'reference'),
              note: jsonString(fraction, 'note'),
            ),
      unit: jsonEnum(calc, 'unite', MeasureUnit.fromCode),
      laterality: jsonEnum(calc, 'lateralite', Laterality.fromCode),
      rootId: jsonString(calc, 'racine'),
      depth: jsonInt(calc, 'profondeur'),
      muscleIndices: List<int>.unmodifiable(indices),
      muscleWeights: List<double>.unmodifiable(weights),
    );
  }

  static double _vectorNorm(List<double> weights) {
    var sum = 0.0;
    for (final w in weights) {
      sum += w * w;
    }
    return math.sqrt(sum);
  }

  /// Identifiant stable (`sw-traction-pronation`).
  final String id;

  /// Nom affiché.
  final String name;

  /// Autres noms.
  final List<String> aliases;

  /// Discipline dans la base.
  final CatalogDiscipline discipline;

  /// Catégorie de la base (vocabulaire `categories`).
  final String category;

  /// Exercice dont celui-ci est une variante, ou `null` pour une racine.
  final String? variantOf;

  /// Niveau de la base.
  final ExerciseLevel level;

  /// Muscles principaux (vocabulaire `muscles`).
  final List<String> primaryMuscles;

  /// Muscles secondaires.
  final List<String> secondaryMuscles;

  /// Muscles stabilisateurs.
  final List<String> stabilizerMuscles;

  /// Muscles étirés.
  final List<String> stretchedMuscles;

  /// Points clés d'exécution (texte de la base).
  final List<String> keyPoints;

  /// Erreurs fréquentes (texte de la base).
  final List<String> commonMistakes;

  /// Consigne de respiration (texte de la base).
  final String breathing;

  /// Matériel nécessaire (vocabulaire `materiel`), jamais vide.
  final List<String> equipment;

  /// Schéma de mouvement (calculé).
  final MovementPattern pattern;

  /// Famille du schéma (calculé).
  final MovementFamily family;

  /// Plan dominant (calculé).
  final MovementPlane plane;

  /// Poly- ou mono-articulaire (calculé).
  final Articularity articularity;

  /// Régime de contraction dominant (calculé).
  final ContractionMode contractionMode;

  /// Difficulté de 1 à 10 (calculée), croissante avec le niveau.
  final int difficulty;

  /// Lieux où tout le matériel est habituellement disponible (calculé).
  final List<Place> places;

  /// Contrainte sur chacune des 7 articulations suivies (calculé).
  final Map<Joint, JointStress> jointStress;

  /// Paliers conseillés avant cet exercice (calculé, 0 à 2 identifiants).
  final List<String> prerequisites;

  /// Coût de fatigue systémique, de 1 à 5 (calculé).
  final int systemicFatigue;

  /// Coût de fatigue locale, de 1 à 5 (calculé).
  final int localFatigue;

  /// Type de charge (calculé).
  final LoadType loadType;

  /// Exercice assisté (élastique, machine, appui) (calculé).
  final bool assisted;

  /// Fraction du poids du corps mobilisée, ou `null` quand la notion n'a
  /// pas de sens (charge externe, levier, gainage, cardio, mobilité).
  final BodyweightFraction? bodyweightFraction;

  /// Unité principale d'une série (calculé).
  final MeasureUnit unit;

  /// Latéralité (calculé).
  final Laterality laterality;

  /// Racine de la chaîne `variante_de` (l'exercice lui-même s'il n'est la
  /// variante d'aucun autre).
  final String rootId;

  /// Distance à la racine dans la chaîne `variante_de` (0 pour une racine).
  final int depth;

  /// Indices (dans [Catalog.muscles]) des muscles du vecteur pondéré, en
  /// ordre croissant.
  final List<int> muscleIndices;

  /// Poids du vecteur musculaire, alignés sur [muscleIndices] : principal
  /// 1, secondaire 0,5, stabilisateur 0,2.
  final List<double> muscleWeights;

  final double _norm;

  /// Contrainte sur [joint].
  JointStress stressOn(Joint joint) => jointStress[joint]!;

  /// Vrai si l'exercice peut se faire avec le seul matériel [available]
  /// (noms du vocabulaire `materiel`). Le matériel de
  /// [alwaysAvailableEquipment] ne bloque jamais.
  bool feasibleWith(Set<String> available) {
    for (final item in equipment) {
      if (!alwaysAvailableEquipment.contains(item) &&
          !available.contains(item)) {
        return false;
      }
    }
    return true;
  }

  /// Cosinus des vecteurs musculaires de cet exercice et de [other], de 0
  /// (aucun muscle commun) à 1 (mêmes muscles, mêmes poids).
  double muscleCosine(CatalogExercise other) {
    if (_norm == 0 || other._norm == 0) {
      return 0;
    }
    var dot = 0.0;
    var i = 0;
    var j = 0;
    while (i < muscleIndices.length && j < other.muscleIndices.length) {
      final a = muscleIndices[i];
      final b = other.muscleIndices[j];
      if (a == b) {
        dot += muscleWeights[i] * other.muscleWeights[j];
        i++;
        j++;
      } else if (a < b) {
        i++;
      } else {
        j++;
      }
    }
    final cosine = dot / (_norm * other._norm);
    return cosine > 1 ? 1 : cosine;
  }

  @override
  String toString() => 'CatalogExercise($id)';
}

/// Matériel du vocabulaire qui ne bloque jamais un exercice : le sol, un
/// mur, et le matériel de confort ou consommable (tapis, magnésie).
const Set<String> alwaysAvailableEquipment = <String>{
  'aucun (sol)',
  'mur',
  'tapis',
  'magnésie',
};

/// Catalogue d'exercices compilé.
///
/// Non modifiable après chargement. L'application lui passe les octets de
/// `data/catalog_v1.json.gz` **décompressés** (`gzip.decode`, `dart:io`
/// n'étant pas permis dans le paquet).
final class Catalog {
  Catalog._({
    required this.schemaVersion,
    required this.rulesVersion,
    required this.sourceVersion,
    required this.sourceDate,
    required this.sourceSha256,
    required this.exercises,
    required this.muscles,
    required this.equipmentVocabulary,
    required this.categories,
  }) {
    for (final e in exercises) {
      if (_byId.containsKey(e.id)) {
        throw FormatException('Catalogue : identifiant en double', e.id);
      }
      _byId[e.id] = e;
    }
    for (final e in exercises) {
      final parent = e.variantOf;
      if (parent != null) {
        if (!_byId.containsKey(parent)) {
          throw FormatException('Catalogue : variante_de inconnue', e.id);
        }
        (_children[parent] ??= <CatalogExercise>[]).add(e);
      }
      for (final p in e.prerequisites) {
        if (!_byId.containsKey(p)) {
          throw FormatException('Catalogue : prérequis inconnu', e.id);
        }
      }
      (_families[e.rootId] ??= <CatalogExercise>[]).add(e);
      (_byDiscipline[e.discipline] ??= <CatalogExercise>[]).add(e);
      (_byCategory[e.category] ??= <CatalogExercise>[]).add(e);
      (_byPattern[e.pattern] ??= <CatalogExercise>[]).add(e);
      (_byFamily[e.family] ??= <CatalogExercise>[]).add(e);
      for (final item in e.equipment) {
        (_byEquipment[item] ??= <CatalogExercise>[]).add(e);
      }
      for (final index in e.muscleIndices) {
        (_byMuscle[muscles[index]] ??= <CatalogExercise>[]).add(e);
      }
      for (final label in <String>[e.name, ...e.aliases]) {
        final list = _byLabel[normalizeLabel(label)] ??= <CatalogExercise>[];
        if (!list.contains(e)) {
          list.add(e);
        }
      }
    }
    // Graphe `variante_de` sans cycle : chaque chaîne atteint sa racine.
    for (final e in exercises) {
      var current = e;
      var steps = 0;
      while (current.variantOf != null) {
        current = _byId[current.variantOf]!;
        steps++;
        if (steps > exercises.length) {
          throw FormatException('Catalogue : cycle variante_de', e.id);
        }
      }
      if (current.id != e.rootId || steps != e.depth) {
        throw FormatException('Catalogue : racine incohérente', e.id);
      }
    }
  }

  /// Lit le catalogue depuis son JSON en UTF-8 (octets **décompressés**).
  ///
  /// [FormatException] si le schéma est plus récent que
  /// [supportedSchemaVersion] ou si le contenu est invalide.
  factory Catalog.fromJsonBytes(List<int> utf8Json) {
    final decoded = const Utf8Decoder()
        .fuse(const JsonDecoder())
        .convert(utf8Json);
    return Catalog.fromJson(jsonAsObject(decoded, 'catalogue'));
  }

  /// Lit le catalogue depuis son objet JSON.
  factory Catalog.fromJson(Map<String, Object?> json) {
    final schema = jsonInt(json, 'schema');
    if (schema < 1 || schema > supportedSchemaVersion) {
      throw FormatException('Catalogue : schéma non pris en charge', schema);
    }
    final source = jsonObject(json, 'source');
    final vocab = jsonObject(json, 'vocabulaires');
    List<String> strings(String key) =>
        jsonList(vocab, key, (v) => jsonAsString(v, key));
    final muscles = strings('muscles');
    return Catalog._(
      schemaVersion: schema,
      rulesVersion: jsonString(json, 'regles_version'),
      sourceVersion: jsonString(source, 'version'),
      sourceDate: jsonString(source, 'date'),
      sourceSha256: jsonString(source, 'sha256'),
      muscles: muscles,
      equipmentVocabulary: strings('materiel'),
      categories: strings('categories'),
      exercises: jsonList(
        json,
        'exercices',
        (v) => CatalogExercise._fromJson(jsonAsObject(v, 'exercices'), muscles),
      ),
    );
  }

  /// Plus grande version du schéma du catalogue que ce paquet sait lire.
  static const int supportedSchemaVersion = 1;

  /// Poids d'un muscle principal dans le vecteur musculaire.
  static const double primaryWeight = 1.0;

  /// Poids d'un muscle secondaire.
  static const double secondaryWeight = 0.5;

  /// Poids d'un muscle stabilisateur.
  static const double stabilizerWeight = 0.2;

  /// Version du schéma du fichier lu.
  final int schemaVersion;

  /// Version des règles des champs calculés.
  final String rulesVersion;

  /// Version de la base source (`1.1.0`).
  final String sourceVersion;

  /// Date de la base source (`AAAA-MM-JJ`).
  final String sourceDate;

  /// Somme de contrôle SHA-256 de la base source.
  final String sourceSha256;

  /// Tous les exercices, dans l'ordre de la base.
  final List<CatalogExercise> exercises;

  /// Vocabulaire des muscles (56).
  final List<String> muscles;

  /// Vocabulaire du matériel (68).
  final List<String> equipmentVocabulary;

  /// Vocabulaire des catégories (56).
  final List<String> categories;

  final Map<String, CatalogExercise> _byId = <String, CatalogExercise>{};
  final Map<String, List<CatalogExercise>> _children =
      <String, List<CatalogExercise>>{};
  final Map<String, List<CatalogExercise>> _families =
      <String, List<CatalogExercise>>{};
  final Map<CatalogDiscipline, List<CatalogExercise>> _byDiscipline =
      <CatalogDiscipline, List<CatalogExercise>>{};
  final Map<String, List<CatalogExercise>> _byCategory =
      <String, List<CatalogExercise>>{};
  final Map<MovementPattern, List<CatalogExercise>> _byPattern =
      <MovementPattern, List<CatalogExercise>>{};
  final Map<MovementFamily, List<CatalogExercise>> _byFamily =
      <MovementFamily, List<CatalogExercise>>{};
  final Map<String, List<CatalogExercise>> _byEquipment =
      <String, List<CatalogExercise>>{};
  final Map<String, List<CatalogExercise>> _byMuscle =
      <String, List<CatalogExercise>>{};
  final Map<String, List<CatalogExercise>> _byLabel =
      <String, List<CatalogExercise>>{};

  static const List<CatalogExercise> _none = <CatalogExercise>[];

  static List<CatalogExercise> _view(List<CatalogExercise>? list) =>
      list == null ? _none : List<CatalogExercise>.unmodifiable(list);

  /// Nombre d'exercices.
  int get length => exercises.length;

  /// Vrai si [id] est un identifiant du catalogue.
  bool contains(String id) => _byId.containsKey(id);

  /// Exercice d'identifiant [id], ou `null`.
  CatalogExercise? find(String id) => _byId[id];

  /// Exercice d'identifiant [id] ; [ArgumentError] s'il n'existe pas.
  CatalogExercise exercise(String id) {
    final e = _byId[id];
    if (e == null) {
      throw ArgumentError.value(id, 'id', 'exercice inconnu du catalogue');
    }
    return e;
  }

  /// Exercices dont le nom ou un alias est [label], sans tenir compte de la
  /// casse, des accents ni des espaces répétés.
  List<CatalogExercise> byLabel(String label) =>
      _view(_byLabel[normalizeLabel(label)]);

  /// Exercices d'une discipline de la base.
  List<CatalogExercise> byDiscipline(CatalogDiscipline discipline) =>
      _view(_byDiscipline[discipline]);

  /// Exercices d'une catégorie de la base.
  List<CatalogExercise> byCategory(String category) =>
      _view(_byCategory[category]);

  /// Exercices d'un schéma de mouvement.
  List<CatalogExercise> byPattern(MovementPattern pattern) =>
      _view(_byPattern[pattern]);

  /// Exercices d'une famille de schémas.
  List<CatalogExercise> byFamily(MovementFamily family) =>
      _view(_byFamily[family]);

  /// Exercices qui demandent le matériel [equipment].
  List<CatalogExercise> byEquipment(String equipment) =>
      _view(_byEquipment[equipment]);

  /// Exercices qui sollicitent [muscle] avec un poids d'au moins
  /// [minWeight] (1 : principal ; 0,5 : au moins secondaire ; 0,2 : tous).
  List<CatalogExercise> byMuscle(String muscle, {double minWeight = 0.2}) {
    final index = muscles.indexOf(muscle);
    final all = _byMuscle[muscle];
    if (index < 0 || all == null) {
      return _none;
    }
    return List<CatalogExercise>.unmodifiable(
      all.where((e) => weightOf(e, muscle) >= minWeight),
    );
  }

  /// Poids de [muscle] dans le vecteur de [exercise] (0 s'il est absent).
  double weightOf(CatalogExercise exercise, String muscle) {
    final index = muscles.indexOf(muscle);
    final at = exercise.muscleIndices.indexOf(index);
    return at < 0 ? 0 : exercise.muscleWeights[at];
  }

  /// Exercice dont [id] est une variante, ou `null` pour une racine.
  CatalogExercise? parentOf(String id) {
    final parent = exercise(id).variantOf;
    return parent == null ? null : _byId[parent];
  }

  /// Variantes directes de [id], dans l'ordre de la base.
  List<CatalogExercise> childrenOf(String id) =>
      _view(_children[exercise(id).id]);

  /// Racine de la chaîne `variante_de` de [id].
  CatalogExercise rootOf(String id) => _byId[exercise(id).rootId]!;

  /// Tous les exercices de la famille `variante_de` de [id] (lui compris),
  /// dans l'ordre de la base.
  List<CatalogExercise> familyOf(String id) =>
      _view(_families[exercise(id).rootId]);

  /// Chaîne des ancêtres de [id], du parent direct à la racine.
  List<CatalogExercise> ancestorsOf(String id) {
    final out = <CatalogExercise>[];
    var current = exercise(id);
    while (current.variantOf != null) {
      current = _byId[current.variantOf]!;
      out.add(current);
    }
    return out;
  }

  /// Proximité de base entre deux exercices, de 0 à 1.
  ///
  /// `0,55 × cosinus des vecteurs musculaires + 0,20 × schéma (1 : même
  /// schéma ; 0,5 : même famille ; 0 sinon) + 0,15 × même famille
  /// variante_de + 0,10 × (1 − |écart de difficulté| / 9)`. Symétrique ;
  /// vaut 1 pour un exercice et lui-même. Les poids sont un choix raisonné
  /// (CONTRAT.md) que `kalis_plan` peut raffiner.
  double similarity(String a, String b) {
    final ea = exercise(a);
    final eb = exercise(b);
    if (identical(ea, eb)) {
      return 1;
    }
    final pattern = ea.pattern == eb.pattern
        ? 1.0
        : (ea.family == eb.family ? 0.5 : 0.0);
    final chain = ea.rootId == eb.rootId ? 1.0 : 0.0;
    final level = 1 - (ea.difficulty - eb.difficulty).abs() / 9;
    final value =
        similarityMuscleWeight * ea.muscleCosine(eb) +
        similarityPatternWeight * pattern +
        similarityChainWeight * chain +
        similarityDifficultyWeight * level;
    return value < 0 ? 0 : (value > 1 ? 1 : value);
  }

  /// Poids du cosinus musculaire dans [similarity].
  static const double similarityMuscleWeight = 0.55;

  /// Poids du schéma de mouvement dans [similarity].
  static const double similarityPatternWeight = 0.20;

  /// Poids de la chaîne `variante_de` dans [similarity].
  static const double similarityChainWeight = 0.15;

  /// Poids de l'écart de difficulté dans [similarity].
  static const double similarityDifficultyWeight = 0.10;

  /// Les [limit] exercices les plus proches de [id] (lui exclu), par
  /// proximité décroissante puis par identifiant ; [where] filtre les
  /// candidats.
  List<CatalogExercise> mostSimilar(
    String id, {
    int limit = 10,
    bool Function(CatalogExercise candidate)? where,
  }) {
    final scored = <(double, CatalogExercise)>[
      for (final e in exercises)
        if (e.id != id && (where == null || where(e)))
          (similarity(id, e.id), e),
    ];
    scored.sort((x, y) {
      final byScore = y.$1.compareTo(x.$1);
      return byScore != 0 ? byScore : x.$2.id.compareTo(y.$2.id);
    });
    return List<CatalogExercise>.unmodifiable(
      scored.take(limit).map((s) => s.$2),
    );
  }

  /// Violations pour chaque identifiant de [ids] absent du catalogue.
  List<Violation> checkExerciseIds(Iterable<String> ids) {
    return <Violation>[
      for (final id in ids)
        if (!contains(id)) Violation(r'$', 'unknown_exercise', id),
    ];
  }

  /// Violations pour chaque matériel de [equipment] absent du vocabulaire.
  List<Violation> checkEquipment(Iterable<String> equipment) {
    final known = equipmentVocabulary.toSet();
    return <Violation>[
      for (final item in equipment)
        if (!known.contains(item)) Violation(r'$', 'unknown_equipment', item),
    ];
  }

  /// Violations d'un profil au regard du catalogue : exercices et matériel
  /// inconnus (en plus de `profile.validate()`). Schéma 3 (0.4.0) : le
  /// groupe musculaire d'une spécialisation est dans le vocabulaire
  /// `muscles`. L'étape actuelle d'une figure n'est pas contrôlée : une
  /// échelle (`SkillLadder`) peut passer par un exercice d'une autre famille.
  List<Violation> checkProfile(AthleteProfile profile) {
    final ids = <String>{};
    profile.collectExerciseIds(ids);
    final muscle = profile.specialization?.muscle;
    return <Violation>[
      ...checkExerciseIds(ids),
      ...checkEquipment(profile.equipment),
      if (muscle != null && !muscles.contains(muscle))
        Violation(r'$.specialization.muscle', 'unknown_muscle', muscle),
    ];
  }

  /// Vrai si [stepId] est la figure [targetId] elle-même ou l'une de ses
  /// variantes (un exercice dont la chaîne `variante_de` remonte à
  /// [targetId]). Faux si l'un des deux identifiants est inconnu.
  bool isProgressionStep(String stepId, String targetId) {
    if (!contains(stepId) || !contains(targetId)) {
      return false;
    }
    if (stepId == targetId) {
      return true;
    }
    for (final ancestor in ancestorsOf(stepId)) {
      if (ancestor.id == targetId) {
        return true;
      }
    }
    return false;
  }

  /// Étapes candidates de la progression vers la figure [targetId] (0.4.0) :
  /// ses variantes (les exercices dont la chaîne `variante_de` remonte à
  /// [targetId]) dans l'ordre de la base, puis la figure elle-même.
  ///
  /// Sert à la question « Où en es-tu ? » du profil. Ce n'est pas une
  /// échelle ordonnée et validée : la liste contient aussi des variantes
  /// plus dures (autre support, un bras) ; l'échelle avec ses critères de
  /// passage est un `SkillLadder`, construit par `kalis_plan`.
  /// [ArgumentError] si [targetId] est inconnu.
  List<CatalogExercise> progressionCandidates(String targetId) {
    final target = exercise(targetId);
    return List<CatalogExercise>.unmodifiable(<CatalogExercise>[
      for (final e in familyOf(targetId))
        if (e.id != targetId && isProgressionStep(e.id, targetId)) e,
      target,
    ]);
  }

  /// Forme de comparaison d'un nom : minuscules, sans accents, espaces
  /// réduits.
  static String normalizeLabel(String label) {
    final buffer = StringBuffer();
    var pendingSpace = false;
    for (final rune in label.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final folded = _folding[char] ?? char;
      if (folded.trim().isEmpty) {
        pendingSpace = buffer.isNotEmpty;
        continue;
      }
      if (pendingSpace) {
        buffer.write(' ');
        pendingSpace = false;
      }
      buffer.write(folded);
    }
    return buffer.toString();
  }

  static const Map<String, String> _folding = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'ã': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ÿ': 'y',
    'ñ': 'n',
    'œ': 'oe',
    'æ': 'ae',
    '’': "'",
  };
}
