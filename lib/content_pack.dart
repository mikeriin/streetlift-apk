// Base d'exercices v1.1 du propriétaire (G3, D4.10) : le catalogue compilé
// de `kalis_core` (1 039 exercices, 8 disciplines) remplace le pack 2.0.0
// dans Arsenal, les fiches, la recherche, les filtres, la carte des muscles
// et la démonstration.
//
// - Catalogue : `assets/catalog/catalog_v1.json.gz`, copie octet pour octet
//   de l'asset du paquet étiqueté (tools/correspondance), lu par
//   `Catalog.fromJsonBytes` une fois au démarrage.
// - Historique : aucune donnée de l'utilisateur n'est réécrite. Les séances,
//   l'historique et les records gardent les noms enregistrés ; un nom est
//   résolu en identifiant v1.1 à la lecture par la table de correspondance
//   `assets/catalog/correspondance.json` (anciens identifiants du pack 2.0.0
//   et anciens noms → identifiants v1.1, construite par règles puis relue :
//   docs/G3_CORRESPONDANCE.md).
// - Muscles : les 56 muscles de la base sont reliés aux muscles de l'atlas
//   (carte 2D, mannequin) par [kBaseMuscleAtlas] ; un muscle profond sans
//   région de carte est listé en texte sur la fiche.
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart';
import 'package:kalis_core/kalis_core.dart' show Catalog, CatalogExercise;

import 'atlas_data.dart';
import 'search.dart';

/// Muscles de la base v1.1 → muscles de l'atlas (carte 2D et mannequin).
/// Chaque muscle de la base y figure (test).
const kBaseMuscleAtlas = <String, List<String>>{
  'grand pectoral (faisceau claviculaire)': ['grand_pectoral_claviculaire'],
  'grand pectoral (faisceau sternal)': ['grand_pectoral_sterno_costal'],
  'grand pectoral (faisceau abdominal)': ['grand_pectoral_abdominal'],
  'petit pectoral': ['petit_pectoral'],
  'deltoïde antérieur': ['deltoide_anterieur'],
  'deltoïde moyen': ['deltoide_moyen'],
  'deltoïde postérieur': ['deltoide_posterieur'],
  'coiffe des rotateurs': [
    'supra_epineux',
    'infra_epineux',
    'petit_rond',
    'sous_scapulaire',
  ],
  'grand dorsal': ['grand_dorsal'],
  'grand rond': ['grand_rond'],
  'trapèze supérieur': ['trapeze_superieur'],
  'trapèze moyen': ['trapeze_moyen'],
  'trapèze inférieur': ['trapeze_inferieur'],
  'rhomboïdes': ['rhomboides'],
  'élévateur de la scapula': ['elevateur_scapula'],
  'dentelé antérieur': ['dentele_anterieur'],
  'érecteurs du rachis': ['erecteurs_lombaires', 'erecteurs_thoraciques'],
  'multifides': ['multifides'],
  'carré des lombes': ['carre_des_lombes'],
  'biceps brachial': ['biceps_chef_long', 'biceps_chef_court'],
  'brachial': ['brachial'],
  'brachio-radial': ['brachio_radial'],
  'coraco-brachial': ['coraco_brachial'],
  'triceps brachial (chef long)': ['triceps_chef_long'],
  'triceps brachial (chefs latéral et médial)': [
    'triceps_chef_lateral',
    'triceps_chef_medial',
  ],
  'anconé': ['ancone'],
  'fléchisseurs du poignet': ['flechisseurs_du_poignet'],
  'extenseurs du poignet': ['extenseurs_du_poignet'],
  'fléchisseurs des doigts': [
    'flechisseurs_superficiels_des_doigts',
    'flechisseurs_profonds_des_doigts',
  ],
  'pronateurs de l\'avant-bras': ['rond_pronateur', 'carre_pronateur'],
  'supinateur': ['supinateur'],
  'muscles intrinsèques de la main': ['muscles_intrinseques_main'],
  'grand droit de l\'abdomen': ['droit_abdomen'],
  'obliques externes': ['oblique_externe'],
  'obliques internes': ['oblique_interne'],
  'transverse de l\'abdomen': ['transverse_abdomen'],
  'diaphragme': ['diaphragme'],
  'psoas-iliaque': ['grand_psoas', 'iliaque'],
  'grand fessier': ['grand_fessier'],
  'moyen fessier': ['moyen_fessier'],
  'petit fessier': ['petit_fessier'],
  'tenseur du fascia lata': ['tenseur_fascia_lata'],
  'rotateurs externes de hanche': ['rotateurs_lateraux_hanche'],
  'adducteurs': [
    'long_adducteur',
    'court_adducteur',
    'grand_adducteur',
    'pectine',
    'gracile',
  ],
  'sartorius': ['sartorius'],
  'quadriceps (droit fémoral)': ['droit_femoral'],
  'quadriceps (vastes)': [
    'vaste_lateral',
    'vaste_medial',
    'vaste_intermediaire',
  ],
  'ischio-jambiers': [
    'biceps_femoral',
    'biceps_femoral_chef_court',
    'semi_tendineux',
    'semi_membraneux',
  ],
  'gastrocnémiens': ['gastrocnemien_medial', 'gastrocnemien_lateral'],
  'soléaire': ['soleaire'],
  'tibial antérieur': ['tibial_anterieur'],
  'fibulaires': ['fibulaires'],
  'muscles intrinsèques du pied': ['muscles_intrinseques_pied'],
  'sterno-cléido-mastoïdien': ['sterno_cleido_mastoidien'],
  'fléchisseurs profonds du cou': ['flechisseurs_cervicaux_profonds'],
  'extenseurs du cou': ['extenseurs_cervicaux'],
};

/// Muscles de l'atlas d'un muscle de la base (vide si inconnu).
List<String> atlasOfBaseMuscle(String muscle) =>
    kBaseMuscleAtlas[muscle] ?? const [];

/// Libellé de la base (muscle, matériel) avec majuscule initiale.
String capitalized(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// Libellé d'un muscle de la base, avec majuscule.
String baseMuscleLabel(String muscle) => capitalized(muscle);

/// Libellés des familles de mouvement (champ calculé `famille`).
const kCatalogFamilyLabels = <String, String>{
  'poussee': 'Poussée',
  'tirage': 'Tirage',
  'jambes_genou': 'Jambes, dominante genou',
  'jambes_hanche': 'Jambes, dominante hanche',
  'tronc': 'Tronc',
  'gainage': 'Gainage',
  'isolation_haut': 'Isolation haut du corps',
  'isolation_bras': 'Isolation bras',
  'isolation_jambes': 'Isolation jambes',
  'figure_statique': 'Figure statique',
  'figure_dynamique': 'Figure dynamique',
  'explosif': 'Explosivité',
  'porte': 'Portés',
  'conditionnement': 'Conditionnement',
  'cardio': 'Cardio',
  'mobilite': 'Mobilité',
  'recuperation': 'Récupération',
  'cou': 'Cou',
};

/// Libellés des lieux (champ calculé `lieux`).
const kPlaceLabels = <String, String>{
  'salle': 'Salle',
  'maison': 'Maison',
  'exterieur': 'Extérieur',
};

/// Libellés des articulations (contraintes articulaires).
const kJointLabels = <String, String>{
  'epaule': 'Épaule',
  'coude': 'Coude',
  'poignet': 'Poignet',
  'lombaires': 'Lombaires',
  'genou': 'Genou',
  'hanche': 'Hanche',
  'cheville': 'Cheville',
};

/// Libellés des unités de mesure.
const kUnitLabels = <String, String>{
  'repetitions': 'Répétitions',
  'secondes': 'Durée',
  'distance': 'Distance',
  'calories': 'Calories',
};

/// Libellés des types de charge.
const kLoadTypeLabels = <String, String>{
  'aucune': 'Sans charge',
  'poids_du_corps': 'Poids du corps',
  'lest': 'Lest',
  'barre': 'Barre',
  'halteres': 'Haltères',
  'kettlebell': 'Kettlebell',
  'machine': 'Machine',
  'poulie': 'Poulie',
  'elastique': 'Élastique',
  'autre': 'Charge libre',
};

/// L13 (KT-074) : textes de la base v1.1 (asset figé, copie octet pour octet
/// du paquet) reformulés à l'affichage : entraînement, jamais soin ni
/// rééducation. Les originaux sont listés dans `tools/check_claims.py`
/// (CORRECTED_AT_DISPLAY) ; tout autre texte de la base passe le contrôle.
const kCatalogWording = <String, String>{
  "Option de choix en cas de douleur antérieure de l'épaule, la rotation externe relative soulage l'articulation":
      "Option de choix si l'avant de l'épaule est sensible : la rotation externe relative ménage l'articulation",
  "Tends complètement les coudes au retour pour soulager le biceps":
      "Tends complètement les coudes au retour pour relâcher le biceps",
  "Barre EZ possible pour soulager les poignets":
      "Barre EZ possible pour ménager les poignets",
  "Avec la corde, écarte les mains en montant pour ouvrir les coudes et soulager l'épaule":
      "Avec la corde, écarte les mains en montant pour ouvrir les coudes et ménager l'épaule",
  "Version assise, buste penché sur les cuisses, possible pour soulager le bas du dos":
      "Version assise, buste penché sur les cuisses, possible pour ménager le bas du dos",
  "La prise neutre et l'indépendance des bras soulagent coudes et poignets par rapport à la barre et autorisent une flexion plus profonde":
      "La prise neutre et l'indépendance des bras ménagent coudes et poignets par rapport à la barre et autorisent une flexion plus profonde",
  "Charge nettement inférieure au wrist curl, barre EZ légère conseillée pour soulager les poignets":
      "Charge nettement inférieure au wrist curl, barre EZ légère conseillée pour ménager les poignets",
  "Travail isolé de chaque côté, adapté à la rééducation et aux tempos excentriques lents (4 à 5 s)":
      "Travail isolé de chaque côté, adapté à une reprise progressive et aux tempos excentriques lents (4 à 5 s)",
  "Résistance souvent plus faible et courbe plus régulière qu'à 45° : bonne option débutant, en rééducation ou pour des séries longues":
      "Résistance souvent plus faible et courbe plus régulière qu'à 45° : bonne option débutant, en reprise progressive ou pour des séries longues",
  "Poignets douloureux en extension forte → surcharge des extenseurs, à soulager sur parallettes":
      "Poignets douloureux en extension forte → surcharge des extenseurs, à ménager sur parallettes",
  "Descente précipitée pour soulager les abdominaux → perte de contrôle et brûlures":
      "Descente précipitée pour relâcher les abdominaux → perte de contrôle et brûlures",
  "Mains tournées vers l'extérieur à 45° ou doigts vers l'arrière pour soulager le tendon du biceps":
      "Mains tournées vers l'extérieur à 45° ou doigts vers l'arrière pour ménager le tendon du biceps",
  "Parallettes à 15 à 20 cm du mur, écartement d'épaules, prise neutre qui soulage les poignets":
      "Parallettes à 15 à 20 cm du mur, écartement d'épaules, prise neutre qui ménage les poignets",
  "Pratiqué au sol ou sur parallettes pour soulager les poignets":
      "Pratiqué au sol ou sur parallettes pour ménager les poignets",
  "Parallettes au niveau des hanches, prise neutre qui soulage l'extension du poignet":
      "Parallettes au niveau des hanches, prise neutre qui limite l'extension du poignet",
};

/// Texte de la base tel qu'il s'affiche (L13).
String catalogWording(String text) => kCatalogWording[text] ?? text;

/// Groupes historiques de l'application d'une liste de muscles de la base
/// (ordre d'apparition, sans doublon).
List<String> appGroupsOfBaseMuscles(Iterable<String> muscles) {
  final out = <String>[];
  for (final m in muscles) {
    for (final a in atlasOfBaseMuscle(m)) {
      final g = atlasMuscles[a]?.groupe;
      if (g != null && !out.contains(g)) out.add(g);
    }
  }
  return out;
}

/// Entrée de la bibliothèque : un exercice de la base v1.1.
class ExerciseEntry {
  final CatalogExercise ex;
  ExerciseEntry(this.ex);

  String get id => ex.id;
  String get nom => ex.name;
  List<String> get alias => ex.aliases;
  String get discipline => ex.discipline.code;
  String get niveau => ex.level.code;
  String get categorie => ex.category;
  String get famille => ex.family.code;
  int get difficulte => ex.difficulty;
  List<String> get lieux => [for (final p in ex.places) p.code];
  List<String> get materiel => ex.equipment;

  /// Groupes historiques (pectoraux, dos…) des muscles principaux.
  late final List<String> groupes = appGroupsOfBaseMuscles(ex.primaryMuscles);

  /// Document de recherche (calculé une fois).
  late final SearchDoc searchDoc = exerciseSearchDoc(this);

  /// Format historique de la base (`n`, `g`, `eq`) + identifiant.
  Map<String, dynamic> toLegacy() => {
    'n': nom,
    'g': groupes.join(', '),
    'eq': materiel.isEmpty ? 'poids de corps' : materiel.join(', '),
    'id': id,
  };
}

/// Fiche d'un exercice (tout vient du catalogue, déjà chargé).
class ExerciseDetail {
  final CatalogExercise ex;
  final Catalog catalog;
  const ExerciseDetail(this.ex, this.catalog);

  static List<String> _atlas(List<String> muscles) => [
    for (final m in muscles) ...atlasOfBaseMuscle(m),
  ].toSet().toList();

  /// Muscles de l'atlas par rôle (carte 2D, mannequin, STATS).
  List<String> get primaires => _atlas(ex.primaryMuscles);
  List<String> get secondaires => _atlas(ex.secondaryMuscles);
  List<String> get stabilisateurs => _atlas(ex.stabilizerMuscles);
  List<String> get etires => _atlas(ex.stretchedMuscles);

  /// Muscles de la base par rôle (libellés de la fiche).
  List<String> get musclesPrincipaux => ex.primaryMuscles;
  List<String> get musclesSecondaires => ex.secondaryMuscles;
  List<String> get musclesStabilisateurs => ex.stabilizerMuscles;
  List<String> get musclesEtires => ex.stretchedMuscles;

  List<String> get pointsCles => [for (final t in ex.keyPoints) catalogWording(t)];
  List<String> get erreurs => [
    for (final t in ex.commonMistakes) catalogWording(t),
  ];
  String get respiration => catalogWording(ex.breathing);
  String get unite => ex.unit.code;
  String get typeCharge => ex.loadType.code;

  /// Paliers conseillés (champ calculé de la base).
  List<String> get prerequis => ex.prerequisites;
  String? get varianteDe => ex.variantOf;

  /// Exercices dont celui-ci est la référence (`variante_de`).
  List<String> get variantes => [
    for (final c in catalog.childrenOf(ex.id)) c.id,
  ];

  /// Contrainte par articulation : `faible`, `moyenne`, `forte`.
  Map<String, String> get contraintes => {
    for (final e in ex.jointStress.entries) e.key.code: e.value.code,
  };
}

/// Base v1.1 chargée, index et correspondances.
class ContentIndex {
  final Catalog? catalog;
  final List<ExerciseEntry> entries;
  final Map<String, ExerciseEntry> byId = {};

  /// Ancien identifiant (pack 2.0.0) → identifiant v1.1 (null : sans
  /// équivalent).
  final Map<String, String?> legacyIds;

  /// Ancien nom enregistré (pack, base v1, programme v33) → identifiant v1.1.
  final Map<String, String> legacyNames;
  final Map<String, String> _byNormalizedName = {};

  ContentIndex._(this.catalog, this.legacyIds, this.legacyNames)
    : entries = [
        for (final e in catalog?.exercises ?? const <CatalogExercise>[])
          ExerciseEntry(e),
      ] {
    for (final e in entries) {
      byId[e.id] = e;
    }
    // Les anciens noms passent avant les noms et alias de la base.
    for (final e in entries) {
      for (final a in [...e.alias, e.nom]) {
        _byNormalizedName[normalizeText(a)] = e.id;
      }
    }
    legacyNames.forEach((name, id) {
      _byNormalizedName[normalizeText(name)] = id;
    });
  }

  /// Index vide (avant le chargement).
  factory ContentIndex.empty() => ContentIndex._(null, const {}, const {});

  /// Catalogue chargé et table `correspondance.json` décodée.
  factory ContentIndex.from(Catalog catalog, Map<String, dynamic> table) =>
      ContentIndex._(
        catalog,
        {
          for (final e in (table['ids'] as Map<String, dynamic>).entries)
            e.key: e.value as String?,
        },
        {
          for (final e in (table['noms'] as Map<String, dynamic>).entries)
            e.key: e.value as String,
        },
      );

  static const catalogAsset = 'assets/catalog/catalog_v1.json.gz';
  static const correspondenceAsset = 'assets/catalog/correspondance.json';

  static Future<ContentIndex> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final bytes = await b.load(catalogAsset);
    final catalog = Catalog.fromJsonBytes(
      gzip.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
    final table =
        jsonDecode(await b.loadString(correspondenceAsset, cache: false))
            as Map<String, dynamic>;
    return ContentIndex.from(catalog, table);
  }

  /// Version de la base (« 1.1.0 »), vide avant le chargement.
  String get version => catalog?.sourceVersion ?? '';

  /// Identifiant v1.1 d'un nom enregistré (séance, historique, record,
  /// intitulé du programme), d'un ancien identifiant ou d'un identifiant
  /// v1.1 ; null pour un exercice personnel ou sans équivalent. Ordre :
  /// ancien nom exact, nom sans précision (« — … », « […] »), nom ou alias
  /// normalisé, identifiant v1.1, ancien identifiant.
  String? idFor(String name) {
    final exact = legacyNames[name];
    if (exact != null) return exact;
    final base = name.split(' — ').first.split(' [').first.trim();
    final found =
        legacyNames[base] ??
        _byNormalizedName[normalizeText(name)] ??
        _byNormalizedName[normalizeText(base)];
    if (found != null) return found;
    if (byId.containsKey(name)) return name;
    return legacyIds[name];
  }

  ExerciseEntry? entryFor(String name) {
    final id = idFor(name);
    return id == null ? null : byId[id];
  }

  /// Fiche d'un exercice v1.1 (null si inconnu).
  ExerciseDetail? detail(String id) {
    final e = byId[id];
    return e == null ? null : ExerciseDetail(e.ex, catalog!);
  }

  /// Anciens identifiants (pack 2.0.0) rattachés à un exercice v1.1 :
  /// démonstrations existantes conservées par correspondance d'id.
  List<String> legacyIdsOf(String id) => [
    for (final e in legacyIds.entries)
      if (e.value == id) e.key,
  ];

  /// Matériel de la base, dans l'ordre du vocabulaire.
  List<String> get equipmentVocabulary =>
      catalog?.equipmentVocabulary ?? const [];
}

/// Document de recherche d'un exercice : nom et alias, discipline,
/// catégorie et famille, matériel, lieux et muscles.
SearchDoc exerciseSearchDoc(ExerciseEntry e) => SearchDoc(
  name: e.nom,
  meta: [
    e.discipline,
    e.categorie,
    kCatalogFamilyLabels[e.famille] ?? e.famille,
  ].join(' '),
  body: [...e.materiel, for (final l in e.lieux) kPlaceLabels[l] ?? l].join(' '),
  notes: [
    ...e.alias,
    ...e.ex.primaryMuscles,
    ...e.ex.secondaryMuscles,
  ].join(' '),
);

/// Ancienne base (pack 2.0.0), conservée pour les moteurs L10 et L11
/// jusqu'à leur retrait (G10) : nom enregistré → ancien identifiant, même
/// règle que la résolution d'avant G3 (base v1 canonique, intitulé du
/// programme v33, nom ou alias).
class LegacyPackIndex {
  final Map<String, String> _baseV1, _programme, _byNormalizedName;
  LegacyPackIndex._(this._baseV1, this._programme, this._byNormalizedName);

  factory LegacyPackIndex.empty() => LegacyPackIndex._({}, {}, {});

  /// [index] : `assets/content/index.json.gz` décodé.
  factory LegacyPackIndex.fromJson(Map<String, dynamic> index) {
    final names = <String, String>{};
    for (final e in index['exercices'] as List) {
      final m = e as Map<String, dynamic>;
      final id = m['id'] as String;
      for (final a in (m['alias'] as List? ?? const [])) {
        names[normalizeText('$a')] = id;
      }
      names[normalizeText(m['nom'] as String)] = id;
      names[normalizeText(m['n'] as String)] = id;
    }
    return LegacyPackIndex._(
      {
        for (final e in (index['base_v1'] as Map<String, dynamic>).entries)
          e.key:
              ((e.value as Map)['canonique'] ?? (e.value as Map)['id'])
                  as String,
      },
      {
        for (final e in (index['programme_v33'] as Map<String, dynamic>).entries)
          e.key: (e.value as Map)['id'] as String,
      },
      names,
    );
  }

  String? idFor(String name) {
    final exact = _baseV1[name] ?? _programme[name];
    if (exact != null) return exact;
    final base = name.split(' — ').first.split(' [').first.trim();
    return _baseV1[base] ??
        _programme[base] ??
        _byNormalizedName[normalizeText(name)] ??
        _byNormalizedName[normalizeText(base)];
  }
}
