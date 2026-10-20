part of 'koach.dart';

// Paramètres et fiches de Koach en assets JSON versionnés (lot KM2, cahier
// KM « Contraintes » : paramètres externalisés dans un fichier JSON
// versionné). Les fichiers sont des copies à l'octet près de la référence
// Python : `reference/params/koach_params_v1.json` et
// `reference/qualites/vecteurs_qualites_v1.json` (contrat § 2.5, § 7).
//
// Ce module ne lit aucun fichier : il décode et contrôle un texte JSON.
// L'application copie les deux fichiers dans ses propres assets et vérifie
// leur SHA-256 (`koachParametresSha256`, `koachFichesSha256`) :
// docs/INTEGRATION_KM3.md, § 3 (le paquet ne déclare pas d'assets Flutter :
// `koachAssetParametres` et `koachAssetFiches` ne sont que les clés
// qu'auraient ces assets s'il les déclarait). Les tests et les outils les
// lisent avec `dart:io` depuis la racine du paquet (`koachFichierParametres`).

/// Version du moteur porté (`koach.VERSION` de la référence Python).
const String koachVersion = '1.0.7-ref.1';

/// Version du fichier de paramètres livré (champ `version`, contrat § 7.2).
const String koachParametresVersion = '1.0.7-ref.1';

/// Schéma du fichier de paramètres (champ `schema`, contrat § 7.1).
const int koachParametresSchema = 1;

/// SHA-256 des octets du fichier de paramètres livré (en-tête du contrat).
const String koachParametresSha256 =
    '2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c';

/// Nombre de clés du fichier de paramètres : 6 à la racine, 338 dans les
/// onze sections (contrat § 7.4 ; 1.0.5 : 345 ; 1.0.6 : 347, trois clés de
/// `securite` ajoutées, `rupture.elargissement_rien_de_special` retirée ;
/// 1.0.7 : les trois clés de `securite` de 1.0.6 retirées, sans objet).
const int koachParametresCles = 344;

/// Clés de la racine du fichier de paramètres (contrat § 7.1).
const List<String> koachParametresRacine = [
  'schema',
  'version',
  'date',
  'note',
  'qualites',
  'classes_reponse',
];

/// Les onze sections du fichier de paramètres, dans l'ordre du fichier
/// (contrat § 7.1).
const List<String> koachParametresSections = [
  'a_priori',
  'mesure',
  'jour',
  'fatigue',
  'dynamique',
  'test_adaptatif',
  'planification',
  'securite',
  'adherence',
  'rupture',
  'controle_dual',
];

/// Clé Flutter de l'asset de paramètres (asset déclaré par le paquet).
const String koachAssetParametres =
    'packages/kalis_adapt/assets/koach/koach_params_1_0_7.json';

/// Chemin du fichier de paramètres, relatif à la racine du paquet.
const String koachFichierParametres = 'assets/koach/koach_params_1_0_7.json';

/// Version des fiches d'exercices livrées (champ `version`).
const String koachFichesVersion = '1.0.0';

/// Schéma des fiches d'exercices (champ `schema`).
const int koachFichesSchema = 1;

/// SHA-256 des octets du fichier des fiches livré.
const String koachFichesSha256 =
    '71454d2d6fcc6df8823b23cb640eec5293f40e91822bda9afa75f5ca0098ba6c';

/// Clé Flutter de l'asset des fiches (asset déclaré par le paquet).
const String koachAssetFiches =
    'packages/kalis_adapt/assets/koach/vecteurs_qualites_v1.json';

/// Chemin du fichier des fiches, relatif à la racine du paquet.
const String koachFichierFiches = 'assets/koach/vecteurs_qualites_v1.json';

/// Majeure d'une version (`'1.0.1-ref.1'` → `'1'`), comme
/// `version.split('.')[0]` de la validation d'import.
String _paMajeure(String version) => version.split('.')[0];

/// Texte JSON décodé ; une erreur de syntaxe devient une [FormatException]
/// préfixée par [quoi].
Object? _paDecoder(String texte, String quoi) {
  try {
    return jsonDecode(texte);
  } on FormatException catch (exc) {
    throw FormatException('$quoi : json_invalide: ${exc.message}');
  }
}

/// Liste JSON de [n] textes.
bool _paTextes(Object? v, int n) =>
    v is List<Object?> && v.length == n && v.every((x) => x is String);

/// Décode et contrôle le fichier de paramètres initial de Koach (texte
/// JSON) : racine objet, `schema` = [koachParametresSchema], `version`
/// texte de même majeure que [koachVersion], `date` et `note` textes,
/// `qualites` (10 textes), `classes_reponse` (5 textes), les onze sections
/// présentes et objets, aucune autre clé à la racine ; puis les règles de
/// la validation d'import (`validerParametres` de `rupture`, contrat § 7.3)
/// appliquées au fichier lui-même : types, bornes simples (`bornes`) et
/// positivité des écarts-types, `sigma`, `tau` et `bruit`. Lève
/// [FormatException] avec la liste des erreurs. Le dictionnaire rendu se
/// passe tel quel au constructeur de [Koach].
Json lireParametresKoach(String texte) {
  final brut = _paDecoder(texte, 'parametres Koach');
  if (brut is! Map<String, Object?>) {
    throw const FormatException('parametres Koach : racine_non_objet');
  }
  final p = brut;
  final erreurs = <String>[];
  if (!egalJson(p['schema'], koachParametresSchema)) {
    erreurs.add('schema: attendu $koachParametresSchema');
  }
  final version = p['version'];
  if (version is! String || _paMajeure(version) != _paMajeure(koachVersion)) {
    erreurs.add('version: majeure attendue ${_paMajeure(koachVersion)}');
  }
  for (final cle in const ['date', 'note']) {
    if (p[cle] is! String) {
      erreurs.add('type: $cle');
    }
  }
  if (!_paTextes(p['qualites'], nq)) {
    erreurs.add('type: qualites ($nq textes)');
  }
  if (!_paTextes(p['classes_reponse'], classesK.length)) {
    erreurs.add('type: classes_reponse (${classesK.length} textes)');
  }
  for (final sec in koachParametresSections) {
    if (!p.containsKey(sec)) {
      erreurs.add('section_absente: $sec');
    } else if (p[sec] is! Map<String, Object?>) {
      erreurs.add('type: $sec');
    }
  }
  for (final cle in p.keys) {
    if (!koachParametresRacine.contains(cle) &&
        !koachParametresSections.contains(cle)) {
      erreurs.add('section_inconnue: $cle');
    }
  }
  if (erreurs.isEmpty) {
    // Mêmes règles que l'import du mode dev (types, bornes, positivité),
    // le fichier servant de référence à lui-même.
    erreurs.addAll(validerParametres(p, p));
  }
  if (erreurs.isNotEmpty) {
    throw FormatException('parametres Koach : ${erreurs.join('; ')}');
  }
  return p;
}

/// Décode les fiches d'exercices de Koach (`vecteurs_qualites_v1.json`,
/// contrat § 2.5) et rend le champ `exercices` : identifiant → fiche, dans
/// l'ordre du fichier. Contrôle : racine objet, `schema` =
/// [koachFichesSchema], `exercices` objet dont chaque fiche est un objet
/// avec un `type` texte et un `vecteur` de [nq] nombres. Lève
/// [FormatException] avec la liste des erreurs.
Map<String, Json> lireFichesKoach(String texte) {
  final brut = _paDecoder(texte, 'fiches Koach');
  if (brut is! Map<String, Object?>) {
    throw const FormatException('fiches Koach : racine_non_objet');
  }
  final erreurs = <String>[];
  if (!egalJson(brut['schema'], koachFichesSchema)) {
    erreurs.add('schema: attendu $koachFichesSchema');
  }
  final exercices = brut['exercices'];
  final out = <String, Json>{};
  if (exercices is! Map<String, Object?>) {
    erreurs.add('type: exercices');
  } else {
    for (final e in exercices.entries) {
      final fiche = e.value;
      if (fiche is! Map<String, Object?>) {
        erreurs.add('type: exercices.${e.key}');
        continue;
      }
      final vecteur = fiche['vecteur'];
      if (fiche['type'] is! String) {
        erreurs.add('type: exercices.${e.key}.type');
      }
      if (vecteur is! List<Object?> ||
          vecteur.length != nq ||
          !vecteur.every((x) => x is num)) {
        erreurs.add('type: exercices.${e.key}.vecteur');
      }
      out[e.key] = fiche;
    }
  }
  if (erreurs.isNotEmpty) {
    throw FormatException('fiches Koach : ${erreurs.join('; ')}');
  }
  return out;
}
