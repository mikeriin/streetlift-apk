/// Banc adversarial de Koach (lot KM2) : portage ligne pour ligne de
/// `kalis_adapt/reference/banc/adversaire.py` (lot KM1, brique 4 du cahier
/// `CAHIER_KM.md`).
///
/// Un athlète adverse = une saison de référence existante (profil de base ×
/// scénario × modèle de vérité) dont on modifie la fiche de comportement et
/// de physiologie (`spec`, surcouche de `saison['specJson']`) et des
/// multiplicateurs de vérité par exercice (`surcharges`, clé `*` pour tous
/// les exercices et une clé par mouvement principal). L'espace est
/// paramétré par u ∈ [0, 1]^d ([kmAdvDimensions]) ; [kmDecoder] le traduit
/// en (spec, surcharges) en respectant les bornes par construction.
///
/// Recherche déterministe ([kmChercherAdversaires] : Mulberry32 et FNV-1a
/// du moteur, hypercube latin puis évolution (μ+λ) qui MAXIMISE la
/// difficulté), évaluation d'une saison conduite par Koach
/// ([kmEvaluerSaisonAdversaire] : `kmSimuler` + `PolitiqueKoach`, mêmes
/// mesures que la référence), comparaison avec le témoin 0.3.1
/// ([kmComparerAdversaires] sur les sorties de `kmAdversaryRun`), sorties
/// JSON au schéma de `donnees/adversaires_v1.json` et
/// `donnees/comparaison_adversaires.json` ([kmJsonPython] : même texte que
/// `json.dumps` de Python).
///
/// Fonctions pures : l'exécution (isolats, fichiers, horloge) est dans
/// `bin/km2_adversaire.dart`. La recherche reçoit l'évaluation des saisons
/// sous forme d'une fonction asynchrone ([KmEvaluateurSaisons]) : l'appelant
/// la répartit sur des isolats, les résultats revenant dans l'ordre des
/// travaux (comme `Pool.map` de la référence).
library;

import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart'
    show CapacityMode, ExerciseBook, ExerciseInfo;
import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_adapt/simulation.dart' show SimRandom;
import 'package:kalis_core/kalis_core.dart' show AthleteProfile, Catalog;

import 'campagne.dart'
    show KmEstimations, kmEffort, kmEvenements, kmGainMoyen, kmReprPy;
import 'criteres_moteur.dart'
    show KmBanc, kmArrondiPy, kmSommeD, kmSommePy, kmTriStable;
import 'km_export.dart' show kmOverridesOf;
import 'meneur.dart' show KmTour, kmSimuler;

/// Version du schéma des sorties (`SCHEMA`).
const int kmAdvSchema = 1;

/// Version de l'espace (`VERSION`).
const String kmAdvVersion = 'adversaires_v1';

/// Cellules de recherche par défaut (profil de base, saison de référence).
const List<String> kmAdvProfilsDefaut = <String>[
  'street_07_avance_streetlifting_competition',
  'autres_03_powerlifter_competition',
  'street_06_inter_sets_reps',
  'autres_01_debutant_musculation',
];

/// Scénario par défaut.
const String kmAdvScenarioDefaut = 'reference';

/// Modèles de vérité par défaut.
const String kmAdvModelesDefaut = 'abc';

/// Recul minimal (jours) entre la fin d'un épisode (coupure, maladie,
/// douleur) et la première échéance (`RECUL_ECHEANCE`).
const int kmAdvReculEcheance = 7;

/// Premier jour possible d'un épisode (`DEBUT_EPISODE`).
const int kmAdvDebutEpisode = 7;

/// Zones de douleur tirées (codes `BodyZone`) ; `null` = aucune
/// (`ZONES_DOULEUR`).
const List<String?> kmAdvZonesDouleur = <String?>[
  null,
  'shoulder',
  'elbow',
  'wrist_hand',
  'lower_back',
  'knee',
  'hip',
];

/// Plancher du multiplicateur de capacité des exercices lestés au poids de
/// corps (`PLANCHER_POIDS_CORPS`).
const double kmAdvPlancherPoidsCorps = 0.92;

/// Rang de séance de l'erreur d'e1RM (`RANG_E1RM`).
const int kmAdvRangE1rm = 6;

/// Familles d'exercices de l'erreur d'e1RM, dans l'ordre de repli
/// (`_CHAINE_E1RM`).
const List<String> kmAdvChaineE1rm = <String>[
  'loadedMain',
  'loaded',
  'reps',
  'hold',
];

bool _garderE1rm(String nom, kc.Json e) => switch (nom) {
  'loadedMain' => e['mode'] == 'loaded' && kc.vrai(e['main']),
  'loaded' => e['mode'] == 'loaded',
  'reps' => e['mode'] == 'reps',
  _ => e['mode'] == 'hold',
};

// ---------------------------------------------------------------------------
// Outils (sémantique Python)
// ---------------------------------------------------------------------------

/// `_r4` : `float('%.4f' % x)`.
double kmR4(double x) => kmArrondiPy(x, 4);

/// `_r6` : `None` ou `float('%.6f' % x)`.
double? kmR6(num? x) => x == null ? null : kmArrondiPy(x.toDouble(), 6);

/// Comparaison numérique de Python (`-0.0 == 0.0`).
int _cmp(num a, num b) => a < b ? -1 : (a > b ? 1 : 0);

/// `sorted(pop, key=lambda a: (-a['difficulte'], a['id']))`.
List<kc.Json> _classer(Iterable<kc.Json> pop) => kmTriStable<kc.Json>(pop, (
  a,
  b,
) {
  final c = _cmp(kc.dbl(b['difficulte']), kc.dbl(a['difficulte']));
  return c != 0 ? c : (a['id']! as String).compareTo(b['id']! as String);
});

/// `max(a['difficulte'] for a in pop)` (premier maximum).
double _maxDifficulte(Iterable<kc.Json> pop) {
  double? m;
  for (final a in pop) {
    final d = kc.dbl(a['difficulte']);
    if (m == null || d > m) {
      m = d;
    }
  }
  if (m == null) {
    throw ArgumentError('max() arg is an empty sequence');
  }
  return m;
}

// ---------------------------------------------------------------------------
// JSON au texte de Python
// ---------------------------------------------------------------------------

/// `json.dumps(x, ...)` de Python : [indent] (`None` : une ligne),
/// [ensureAscii], [trier] (`sort_keys`), séparateurs [sepElements] et
/// [sepCle] (défauts de Python : `', '` sans indentation, `','` avec,
/// `': '`). Flottants écrits comme `float.__repr__` (`NaN`, `Infinity`,
/// `-Infinity` pour les non-finis), entiers comme `int.__repr__`.
String kmJsonPython(
  Object? x, {
  int? indent,
  bool ensureAscii = true,
  bool trier = false,
  String? sepElements,
  String? sepCle,
}) {
  final b = StringBuffer();
  _ecrireJsonPy(
    b,
    x,
    0,
    indent,
    ensureAscii,
    trier,
    sepElements ?? (indent == null ? ', ' : ','),
    sepCle ?? ': ',
  );
  return b.toString();
}

void _ecrireTextePy(StringBuffer b, String s, bool ensureAscii) {
  b.write('"');
  for (final cu in s.codeUnits) {
    switch (cu) {
      case 0x5c:
        b.write(r'\\');
      case 0x22:
        b.write(r'\"');
      case 0x08:
        b.write(r'\b');
      case 0x0c:
        b.write(r'\f');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        if (cu < 0x20 || (ensureAscii && cu > 0x7e)) {
          b.write('\\u${cu.toRadixString(16).padLeft(4, '0')}');
        } else {
          b.writeCharCode(cu);
        }
    }
  }
  b.write('"');
}

void _ecrireJsonPy(
  StringBuffer b,
  Object? x,
  int niveau,
  int? indent,
  bool ensureAscii,
  bool trier,
  String sepElements,
  String sepCle,
) {
  if (x == null) {
    b.write('null');
  } else if (x is bool) {
    b.write(x ? 'true' : 'false');
  } else if (x is int) {
    b.write(x);
  } else if (x is double) {
    if (x.isNaN) {
      b.write('NaN');
    } else if (x.isInfinite) {
      b.write(x > 0 ? 'Infinity' : '-Infinity');
    } else {
      b.write(kmReprPy(x));
    }
  } else if (x is String) {
    _ecrireTextePy(b, x, ensureAscii);
  } else if (x is Map<Object?, Object?>) {
    if (x.isEmpty) {
      b.write('{}');
      return;
    }
    final cles = <String>[for (final k in x.keys) '$k'];
    if (trier) {
      cles.sort();
    }
    final parCle = <String, Object?>{
      for (final e in x.entries) '${e.key}': e.value,
    };
    b.write('{');
    final retour = indent == null ? null : '\n${' ' * (indent * (niveau + 1))}';
    if (retour != null) {
      b.write(retour);
    }
    var premier = true;
    for (final k in cles) {
      if (!premier) {
        b.write(sepElements);
        if (retour != null) {
          b.write(retour);
        }
      }
      premier = false;
      _ecrireTextePy(b, k, ensureAscii);
      b.write(sepCle);
      _ecrireJsonPy(
        b,
        parCle[k],
        niveau + 1,
        indent,
        ensureAscii,
        trier,
        sepElements,
        sepCle,
      );
    }
    if (indent != null) {
      b.write('\n${' ' * (indent * niveau)}');
    }
    b.write('}');
  } else if (x is Iterable<Object?>) {
    if (x.isEmpty) {
      b.write('[]');
      return;
    }
    b.write('[');
    final retour = indent == null ? null : '\n${' ' * (indent * (niveau + 1))}';
    if (retour != null) {
      b.write(retour);
    }
    var premier = true;
    for (final v in x) {
      if (!premier) {
        b.write(sepElements);
        if (retour != null) {
          b.write(retour);
        }
      }
      premier = false;
      _ecrireJsonPy(
        b,
        v,
        niveau + 1,
        indent,
        ensureAscii,
        trier,
        sepElements,
        sepCle,
      );
    }
    if (indent != null) {
      b.write('\n${' ' * (indent * niveau)}');
    }
    b.write(']');
  } else {
    throw ArgumentError.value(x, 'x', 'valeur non codable en JSON');
  }
}

/// `_dumps` : `json.dumps(obj, sort_keys=True, ensure_ascii=False,
/// indent=1) + '\n'` (fichiers lisibles de la référence).
String kmDumpsAdversaires(Object? obj) =>
    '${kmJsonPython(obj, indent: 1, ensureAscii: false, trier: true)}\n';

// ---------------------------------------------------------------------------
// Espace des athlètes adverses
// ---------------------------------------------------------------------------

/// Une dimension de l'espace (`Dimension`) : nom, bornes, échelle (`lin`,
/// `log`, `entier`, `zone`), valeur nominale du modèle de vérité et
/// justification de la borne.
final class KmDimension {
  /// Dimension [nom].
  const KmDimension(
    this.nom,
    this.bas,
    this.haut,
    this.echelle,
    this.nominal,
    this.raison,
  );

  /// Nom.
  final String nom;

  /// Borne basse (entier pour `entier` et `zone`).
  final num bas;

  /// Borne haute.
  final num haut;

  /// Échelle : `lin`, `log`, `entier` ou `zone`.
  final String echelle;

  /// Valeur nominale (ou `null`).
  final num? nominal;

  /// Justification de la borne.
  final String raison;

  /// Valeur de la dimension pour u ∈ [0, 1] (`valeur`) : `double` (`lin`,
  /// `log`), `int` (`entier`), `String?` (`zone`).
  Object? valeur(double u0) {
    final u = u0 < 0 ? 0.0 : (u0 > 1 ? 1.0 : u0);
    if (echelle == 'log') {
      final lb = math.log(bas);
      return kmR4(math.exp(lb + u * (math.log(haut) - lb)));
    }
    if (echelle == 'entier') {
      final b = bas.toInt();
      final n = haut.toInt() - b + 1;
      final k = (u * n).truncate();
      return b + (k >= n ? n - 1 : k);
    }
    if (echelle == 'zone') {
      final nz = kmAdvZonesDouleur.length;
      final k = (u * nz).truncate();
      return kmAdvZonesDouleur[k >= nz ? nz - 1 : k];
    }
    return kmR4(bas.toDouble() + u * (haut.toDouble() - bas.toDouble()));
  }

  /// Entrée de `espace` du fichier lisible.
  Map<String, Object?> toJson() => <String, Object?>{
    'nom': nom,
    'bas': bas,
    'haut': haut,
    'echelle': echelle,
    'nominal': nominal,
    'raison': raison,
  };
}

/// Espace des athlètes adverses : bornes et justifications (`DIMENSIONS`).
/// Valeurs nominales de `Spec.DEFAULTS` (`AthleteSpec`) et des tirages de
/// `SimAthlete.truthOf`.
const List<KmDimension> kmAdvDimensions = <KmDimension>[
  KmDimension(
    'ratingNoise',
    0.5,
    2.5,
    'log',
    1.0,
    'Bruit des notes : de 0,5× (athlète très régulier) à 2,5× le nominal (note quasi aléatoire à ±2 RIR près de l\'échec) ; au-delà, plus aucune note n\'informe et aucun moteur ne peut s\'en servir.',
  ),
  KmDimension(
    'rirBias',
    -0.15,
    0.8,
    'lin',
    0.25,
    'Biais multiplicatif du RIR perçu (RIR perçu = vrai / (1 + biais)) : bornes exactes du modèle de vérité (clamp [-0,15 ; 0,8] de `SimAthlete`) ; sans effet sous le modèle C (biais tiré du niveau).',
  ),
  KmDimension(
    'rirBiasSd',
    0.05,
    0.36,
    'lin',
    0.18,
    'Dispersion du biais entre athlètes : du quart au double du nominal.',
  ),
  KmDimension(
    'lazy',
    0.0,
    0.5,
    'lin',
    0.1,
    'Notes paresseuses (recopie la difficulté visée) : jusqu\'à une série sur deux près de la cible ; au-delà la note ne serait plus une mesure mais un écho.',
  ),
  KmDimension(
    'skipRating',
    0.0,
    0.5,
    'lin',
    0.0,
    'Notes sautées : jusqu\'à une série sur deux sans note (Koach rend la note obligatoire sur les principaux, D8 ; 50 % est un majorant prudent pour les autres).',
  ),
  KmDimension(
    'missRate',
    0.0,
    0.35,
    'lin',
    0.08,
    'Séances manquées au hasard : au plus 35 % (le scénario « séances manquées » du banc en met 25 %) ; au-delà ce n\'est plus un programme suivi.',
  ),
  KmDimension(
    'breakDays',
    0,
    14,
    'entier',
    0,
    'Coupure (vacances) : 0 à 14 jours d\'affilée, finie au moins 7 jours avant l\'échéance.',
  ),
  KmDimension(
    'breakFrom',
    0.0,
    1.0,
    'lin',
    null,
    'Début de la coupure, en fraction de la fenêtre possible [7 ; J − 7 − durée].',
  ),
  KmDimension(
    'illnessDays',
    0,
    10,
    'entier',
    0,
    'Maladie (forme −8 %, séances maintenues) : 0 à 10 jours, finie au moins 7 jours avant l\'échéance (le scénario du banc : 7 jours).',
  ),
  KmDimension(
    'illnessFrom',
    0.0,
    1.0,
    'lin',
    null,
    'Début de la maladie, en fraction de la fenêtre possible.',
  ),
  KmDimension(
    'painZone',
    0,
    1,
    'zone',
    null,
    'Zone de douleur : aucune, épaule, coude, poignet/main, lombaires, genou, hanche (codes `BodyZone`).',
  ),
  KmDimension(
    'painIntensity',
    3,
    7,
    'entier',
    5,
    'Intensité de la douleur sur 10 : de 3 (gêne, seuil où le modèle garde une zone réactive) à 7 (au-delà, on arrête de s\'entraîner).',
  ),
  KmDimension(
    'painDays',
    7,
    35,
    'entier',
    21,
    'Durée de l\'épisode douloureux : 1 à 5 semaines (le scénario du banc : 3 semaines), fini au moins 7 jours avant l\'échéance.',
  ),
  KmDimension(
    'painFrom',
    0.0,
    1.0,
    'lin',
    null,
    'Début de la douleur, en fraction de la fenêtre possible.',
  ),
  KmDimension(
    'daySd',
    0.0125,
    0.0625,
    'log',
    0.025,
    'Dispersion de la forme du jour : de 0,5× à 2,5× le nominal (±6 % d\'un jour à l\'autre au maximum, ordre de grandeur des variations de 1RM rapportées).',
  ),
  KmDimension(
    'healthAnswerRate',
    0.1,
    1.0,
    'lin',
    0.7,
    'Taux de réponse au bilan de forme : de 10 % (presque jamais) à toujours.',
  ),
  KmDimension(
    'shortTimeRate',
    0.0,
    0.3,
    'lin',
    0.05,
    'Séances avec peu de temps (60 % du budget) : jusqu\'à près d\'une séance sur trois.',
  ),
  KmDimension(
    'capaciteTous',
    0.8,
    1.2,
    'log',
    1.0,
    'Capacité vraie de TOUS les exercices par rapport au tirage (lui-même centré sur le déclaré, ±8 à 10 %) : ±20 %, soit environ ±25 % du déclaré à un écart-type du tirage (déclaration optimiste ou prudente).',
  ),
  KmDimension(
    'courbeTous',
    0.75,
    1.33,
    'log',
    1.0,
    'Forme de la courbe charge-répétitions de tous les exercices (multiplie curveB, slope et power : seul le paramètre du modèle de vérité de la saison agit) : de 0,75× à 1,33× (≈ ±2 écarts-types du tirage individuel, 0,18 à 0,20 en log).',
  ),
  KmDimension(
    'fatigueTous',
    0.6,
    1.67,
    'log',
    1.0,
    'Sensibilité à la fatigue de séance de tous les exercices : 0,6× à 1,67× (≈ ±1,5 écart-type du tirage, 0,35 en log).',
  ),
  KmDimension(
    'capacitePrincipaux',
    0.8,
    1.2,
    'log',
    1.0,
    'Capacité vraie des mouvements principaux (remplace le facteur « tous » pour eux) : ±20 %, mêmes raisons ; c\'est l\'erreur de déclaration la plus probable (1RM ancien ou estimé).',
  ),
  KmDimension(
    'courbePrincipaux',
    0.75,
    1.33,
    'log',
    1.0,
    'Forme de courbe des mouvements principaux : mêmes bornes.',
  ),
  KmDimension(
    'fatiguePrincipaux',
    0.6,
    1.67,
    'log',
    1.0,
    'Sensibilité à la fatigue des mouvements principaux : mêmes bornes.',
  ),
];

/// Noms des dimensions (`NOMS`).
final List<String> kmAdvNoms = <String>[
  for (final d in kmAdvDimensions) d.nom,
];

/// Dimensions par nom (`PAR_NOM`).
final Map<String, KmDimension> kmAdvParNom = <String, KmDimension>{
  for (final d in kmAdvDimensions) d.nom: d,
};

/// Nombre de dimensions (`D`).
final int kmAdvD = kmAdvDimensions.length;

/// Champs de `spec` que l'espace peut écrire (`CHAMPS_SPEC`, noms
/// `AthleteSpec`).
const List<String> kmAdvChampsSpec = <String>[
  'ratingNoise',
  'rirBias',
  'rirBiasSd',
  'lazy',
  'skipRating',
  'missRate',
  'breakFromDay',
  'breakDays',
  'illnessFromDay',
  'illnessDays',
  'painZone',
  'painFromDay',
  'painDays',
  'painIntensity',
  'daySd',
  'healthAnswerRate',
  'shortTimeRate',
];

/// Multiplicateurs écrits (`CHAMPS_SURCHARGE`, sous-ensemble de
/// `kmOverrideFields`).
const List<String> kmAdvChampsSurcharge = <String>[
  'capacity',
  'curveB',
  'slope',
  'power',
  'fatigueScale',
];

/// Champs de `spec` tirés directement d'une dimension (ordre de `decoder`).
const List<String> _champsDirects = <String>[
  'ratingNoise',
  'rirBias',
  'rirBiasSd',
  'lazy',
  'skipRating',
  'missRate',
  'daySd',
  'healthAnswerRate',
  'shortTimeRate',
];

// ---------------------------------------------------------------------------
// Cadre d'une cellule (profil × scénario × modèle)
// ---------------------------------------------------------------------------

/// Exercices de rôle « main » dans les blocs de la saison, triés
/// (`principaux_de`).
List<String> kmPrincipauxDe(kc.Json saison) {
  final out = <String>{};
  for (final b in kc.jl(saison['blocks'])) {
    for (final d in kc.jl(kc.jm(kc.jm(b)['pass1'])['days'])) {
      for (final s0 in kc.jl(kc.jm(d)['slots'])) {
        final s = kc.jm(s0);
        if (s['role'] == 'main' && kc.vrai(s['exerciseId'])) {
          out.add(s['exerciseId']! as String);
        }
      }
    }
  }
  return out.toList()..sort();
}

/// Exercices chargés de la saison dont la charge totale comprend une part
/// du poids de corps, écrits dans les blocs (pass1 et pass2), triés
/// (`exercices_poids_corps`). [catalog] : catalogue de `kalis_core`
/// (`make_book(catalogue_infos, profil)` de la référence).
List<String> kmExercicesPoidsCorps(Catalog catalog, kc.Json saison) {
  final profil = kc.jm(kc.jm(kc.jl(saison['profiles'])[0])['profile']);
  final livre = ExerciseBook(catalog, AthleteProfile.fromJson(profil));
  final ids = <Object?>{};
  for (final b0 in kc.jl(saison['blocks'])) {
    final b = kc.jm(b0);
    for (final d in kc.jl(kc.jm(b['pass1'])['days'])) {
      for (final s in kc.jl(kc.jm(d)['slots'])) {
        ids.add(kc.jm(s)['exerciseId']);
      }
    }
    for (final w in kc.jl(kc.jm(b['pass2'])['weeks'])) {
      for (final d in kc.jl(kc.jm(w)['days'])) {
        for (final it in kc.jl(kc.jm(d)['items'])) {
          ids.add(kc.jm(it)['exerciseId']);
        }
      }
    }
  }
  final out = <String>[];
  for (final ex in ids) {
    if (ex is! String) {
      continue;
    }
    final ExerciseInfo? info = livre.find(ex);
    if (info != null && info.mode == CapacityMode.loaded && info.fraction > 0) {
      out.add(ex);
    }
  }
  return out..sort();
}

/// Jours d'échéance de la saison, triés, sans doublon (`jours_echeance`).
List<int> kmJoursEcheance(kc.Json saison) {
  final out = <int>{};
  for (final jours in kc.jl(saison['eventDaysByWeek'])) {
    for (final j in kc.jl(jours)) {
      out.add(kc.ent(j));
    }
  }
  return out.toList()..sort();
}

/// Ce que le décodage doit savoir d'une cellule de recherche (`Cadre`).
final class KmCadreAdversaire {
  /// Cadre donné champ par champ.
  KmCadreAdversaire({
    required this.cle,
    required this.scenario,
    required this.kind,
    required this.semaines,
    required this.echeances,
    required this.principaux,
    required this.specBase,
    required this.poidsCorps,
  }) : finEpisodes =
           (echeances.isNotEmpty ? echeances[0] : 7 * semaines) -
           kmAdvReculEcheance;

  /// Cadre de la saison [saison] (export `kmReferenceSeason`, scénario
  /// `saison['scenario']`) sous le modèle de vérité [kind].
  factory KmCadreAdversaire.deSaison(
    Catalog catalog,
    kc.Json saison,
    String kind,
  ) => KmCadreAdversaire(
    cle: saison['key']! as String,
    scenario: saison['scenario']! as String,
    kind: kind,
    semaines: kc.ent(saison['weeks']),
    echeances: kmJoursEcheance(saison),
    principaux: kmPrincipauxDe(saison),
    specBase: Map<String, Object?>.of(kc.jm(saison['specJson'])),
    poidsCorps: kmExercicesPoidsCorps(catalog, saison),
  );

  /// Clé du profil.
  final String cle;

  /// Scénario.
  final String scenario;

  /// Modèle de vérité.
  final String kind;

  /// Semaines de la saison.
  final int semaines;

  /// Jours d'échéance, triés.
  final List<int> echeances;

  /// Mouvements principaux, triés.
  final List<String> principaux;

  /// Fiche d'athlète de la saison (`specJson`).
  final kc.Json specBase;

  /// Exercices lestés au poids de corps, triés.
  final List<String> poidsCorps;

  /// Dernier jour où un épisode peut se terminer (`fin_episodes`).
  final int finEpisodes;

  /// `cle|scenario|kind`.
  String get nom => '$cle|$scenario|$kind';
}

/// Jour de début d'un épisode de [duree] jours, dans
/// [kmAdvDebutEpisode ; finEpisodes − duree] ; `null` si la fenêtre est
/// vide (`_episode`).
int? kmEpisode(KmCadreAdversaire cadre, int duree, double uDebut) {
  final dernier = cadre.finEpisodes - duree;
  if (duree <= 0 || dernier < kmAdvDebutEpisode) {
    return null;
  }
  final n = dernier - kmAdvDebutEpisode + 1;
  final k = (uDebut * n).truncate();
  return kmAdvDebutEpisode + (k >= n ? n - 1 : k);
}

Map<String, double> _mult(double cap, double courbe, double fatigue) =>
    <String, double>{
      'capacity': cap,
      'curveB': courbe,
      'slope': courbe,
      'power': courbe,
      'fatigueScale': fatigue,
    };

/// Vecteur u ∈ [0, 1]^D → (spec, surcharges, paramètres lisibles)
/// (`decoder`).
(kc.Json, Map<String, Map<String, double>>, kc.Json) kmDecoder(
  List<double> u,
  KmCadreAdversaire cadre,
) {
  final v = <String, Object?>{
    for (var i = 0; i < kmAdvDimensions.length; i++)
      kmAdvDimensions[i].nom: kmAdvDimensions[i].valeur(u[i]),
  };
  final spec = <String, Object?>{};
  for (final nom in _champsDirects) {
    spec[nom] = v[nom];
  }
  var debut = kmEpisode(cadre, v['breakDays']! as int, v['breakFrom']! as double);
  if (debut != null) {
    spec['breakFromDay'] = debut;
    spec['breakDays'] = v['breakDays'];
  }
  debut = kmEpisode(cadre, v['illnessDays']! as int, v['illnessFrom']! as double);
  if (debut != null) {
    spec['illnessFromDay'] = debut;
    spec['illnessDays'] = v['illnessDays'];
  }
  if (v['painZone'] != null) {
    debut = kmEpisode(cadre, v['painDays']! as int, v['painFrom']! as double);
    if (debut != null) {
      spec['painZone'] = v['painZone'];
      spec['painFromDay'] = debut;
      spec['painDays'] = v['painDays'];
      spec['painIntensity'] = v['painIntensity'];
    }
  }
  final surcharges = <String, Map<String, double>>{
    '*': _mult(
      v['capaciteTous']! as double,
      v['courbeTous']! as double,
      v['fatigueTous']! as double,
    ),
  };
  for (final ex in cadre.principaux) {
    // Clé exacte : remplace « * » pour cet exercice (même règle en Dart et
    // en Python), d'où l'entrée complète.
    surcharges[ex] = _mult(
      v['capacitePrincipaux']! as double,
      v['courbePrincipaux']! as double,
      v['fatiguePrincipaux']! as double,
    );
  }
  // Plancher des exercices lestés au poids de corps : entrée propre quand
  // le facteur commun le franchit.
  for (final ex in cadre.poidsCorps) {
    final exact = surcharges[ex];
    final m = (exact == null || exact.isEmpty) ? surcharges['*']! : exact;
    if (m['capacity']! < kmAdvPlancherPoidsCorps) {
      surcharges[ex] = <String, double>{
        ...m,
        'capacity': kmAdvPlancherPoidsCorps,
      };
    }
  }
  return (spec, surcharges, v);
}

/// Identifiant stable : empreinte FNV-1a du contenu canonique
/// (`identifiant`).
String kmIdentifiant(
  String cle,
  String scenario,
  String kind,
  kc.Json spec,
  Map<String, Object?> surcharges,
) {
  final texte = kmJsonPython(
    <Object?>[cle, scenario, kind, spec, surcharges],
    trier: true,
    sepElements: ',',
    sepCle: ':',
  );
  return 'adv-${kc.fnv1a32(texte).toRadixString(16).padLeft(8, '0')}';
}

String _strPy(Object? x) => x is String ? x : kmReprPy(x);

/// Liste des écarts aux bornes d'un adversaire exporté, vide s'il est
/// correct (`verifier_bornes`).
List<String> kmVerifierBornes(kc.Json adv) {
  final err = <String>[];
  final spec = kc.jm(adv['spec']);
  for (final k in spec.keys) {
    if (!kmAdvChampsSpec.contains(k)) {
      err.add('champ de spec inconnu : $k');
    }
  }
  for (final nom in _champsDirects) {
    final d = kmAdvParNom[nom]!;
    final x = spec[nom];
    if (x is! num || !(d.bas - 1e-9 <= x && x <= d.haut + 1e-9)) {
      err.add(
        '$nom=${kmReprPy(x)} hors [${_strPy(d.bas)} ; ${_strPy(d.haut)}]',
      );
    }
  }
  final fin = kc.ent(adv['fin_episodes']);
  for (final (champDebut, champDuree, nom) in const <(String, String, String)>[
    ('breakFromDay', 'breakDays', 'breakDays'),
    ('illnessFromDay', 'illnessDays', 'illnessDays'),
    ('painFromDay', 'painDays', 'painDays'),
  ]) {
    if (spec.containsKey(champDebut)) {
      final debut = spec[champDebut];
      final duree = spec[champDuree];
      final d = kmAdvParNom[nom]!;
      if (!(debut is int && duree is int)) {
        err.add('$champDebut/$champDuree : entiers attendus');
        continue;
      }
      if (!(math.max(1, d.bas) <= duree && duree <= d.haut)) {
        err.add('$champDuree=$duree hors bornes');
      }
      if (debut < kmAdvDebutEpisode || debut + duree > fin) {
        err.add(
          '$champDebut : épisode [$debut ; ${debut + duree}] hors fenêtre '
          '[$kmAdvDebutEpisode ; $fin]',
        );
      }
    }
  }
  if (spec.containsKey('painZone')) {
    if (!kmAdvZonesDouleur.sublist(1).contains(spec['painZone'])) {
      err.add('painZone inconnue : ${kmReprPy(spec['painZone'])}');
    }
    final pi = (spec['painIntensity'] ?? 0) as num;
    if (!(3 <= pi && pi <= 7)) {
      err.add('painIntensity hors [3 ; 7]');
    }
  }
  final bornes = <String, KmDimension>{
    'capacity': kmAdvParNom['capaciteTous']!,
    'curveB': kmAdvParNom['courbeTous']!,
    'slope': kmAdvParNom['courbeTous']!,
    'power': kmAdvParNom['courbeTous']!,
    'fatigueScale': kmAdvParNom['fatigueTous']!,
  };
  final surcharges = kc.jm(adv['surcharges']);
  for (final ex in kc.listeOuVide(adv['poids_corps'])) {
    final exact = surcharges[ex];
    final etoile = surcharges['*'];
    final m = kc.vrai(exact)
        ? kc.jm(exact)
        : (kc.vrai(etoile) ? kc.jm(etoile) : <String, Object?>{});
    if (((m['capacity'] ?? 1.0) as num) < kmAdvPlancherPoidsCorps - 1e-9) {
      err.add(
        '$ex : capacité ×${kmReprPy(m['capacity'])} sous le plancher du '
        'poids de corps',
      );
    }
  }
  for (final e in surcharges.entries) {
    for (final f in kc.jm(e.value).entries) {
      final d = bornes[f.key];
      if (d == null) {
        err.add('surcharge inconnue : ${e.key}.${f.key}');
        continue;
      }
      final x = f.value! as num;
      if (!(d.bas - 1e-9 <= x && x <= d.haut + 1e-9)) {
        err.add(
          '${e.key}.${f.key}=${kmReprPy(x)} hors [${_strPy(d.bas)} ; '
          '${_strPy(d.haut)}]',
        );
      }
    }
  }
  return err;
}

// ---------------------------------------------------------------------------
// Graines : présence le jour J
// ---------------------------------------------------------------------------

/// L'athlète [specComplete] (fiche fusionnée) est-il présent le jour
/// [jour] avec la graine [seed] ? Mêmes tirages que le meneur : coupure,
/// puis `calendar|jour` < missRate (`present_le_jour`).
bool kmPresentLeJour(kc.Json specComplete, int seed, int jour) {
  final bf = specComplete['breakFromDay'];
  if (bf != null) {
    final debut = kc.ent(bf);
    final duree = kc.vrai(specComplete['breakDays'])
        ? kc.ent(specComplete['breakDays'])
        : 0;
    if (debut <= jour && jour < debut + duree) {
      return false;
    }
  }
  final miss0 = specComplete['missRate'];
  final miss = miss0 == null ? 0.08 : kc.dbl(miss0);
  return !(SimRandom.of(seed, 'calendar|$jour').next() < miss);
}

/// Les [n] premières graines (à partir de [depart]) où l'athlète est
/// présent à au moins un jour d'échéance (toutes sans échéance)
/// (`graines_valides`).
List<int> kmGrainesValides(
  KmCadreAdversaire cadre,
  kc.Json spec,
  int n, {
  int depart = 0,
}) {
  final complete = <String, Object?>{...cadre.specBase, ...spec};
  final out = <int>[];
  var g = depart;
  while (out.length < n) {
    if (cadre.echeances.isEmpty ||
        cadre.echeances.any((j) => kmPresentLeJour(complete, g, j))) {
      out.add(g);
    }
    g += 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Évaluation d'une saison
// ---------------------------------------------------------------------------

/// (erreur absolue moyenne au rang 6, famille retenue, nombre)
/// (`erreur_e1rm`).
(double?, String?, int) kmErreurE1rm(KmTour tour) {
  for (final nom in kmAdvChaineE1rm) {
    final e = KmEstimations()..add(tour, (x) => _garderE1rm(nom, x));
    final ligne = e.ligne(kmAdvRangE1rm);
    if (ligne != null) {
      return (kc.dbl(ligne['mae']), nom, kc.ent(ligne['n']));
    }
  }
  return (null, null, 0);
}

/// Critère (a) : moyenne de meilleure valeur réussie / max du jour ; 0 si
/// aucun test réussi ou aucun test ; `null` sans échéance (`perf_jour_j`).
/// [evenements] : lignes de `kmEvenements`.
double? kmPerfJourJ(
  List<List<Object?>> evenements,
  bool echeance, [
  bool present = true,
]) {
  if (!echeance || !present) {
    return null;
  }
  final ratios = <double>[
    for (final e in evenements)
      if (kc.vrai(e[4])) kc.dbl(e[2]) / kc.dbl(e[4]),
  ];
  return ratios.isNotEmpty ? kmSommeD(ratios) / ratios.length : 0.0;
}

/// Blocs de la saison où chaque séance faite est remplacée par les items
/// que Koach a servis, avec le nombre de séries réellement faites pour les
/// exercices modélisés (`blocs_servis`).
List<Object?> kmBlocsServisAdversaire(kc.Json saison, KmTour tour) {
  final jourDe = <(int, int, int, int), int>{};
  for (final s0 in kc.jl(saison['sessions'])) {
    final s = kc.jl(s0);
    jourDe[(kc.ent(s[0]), kc.ent(s[1]), kc.ent(s[2]), kc.ent(s[3]))] =
        kc.ent(s[4]);
  }
  final faites = <(Object?, Object?, Object?), int>{};
  final modelises = <Object?>{};
  for (final s in tour.sets) {
    modelises.add(s['exerciseId']);
    final k = (s['simDay'], s['slotId'], s['exerciseId']);
    faites[k] = (faites[k] ?? 0) + 1;
  }
  final blocs = kc.jl(kc.copieProfonde(saison['blocks']));
  for (final (g, bi, wb, di, items) in tour.servi) {
    final simDay = jourDe[(g, bi, wb, di)];
    final nouveaux = <Object?>[];
    for (final it0 in items) {
      final it = kc.copieJson(it0);
      if (modelises.contains(it['exerciseId'])) {
        final n = faites[(simDay, it['slotId'], it['exerciseId'])] ?? 0;
        if (n == 0) {
          continue;
        }
        it['sets'] = n;
      }
      nouveaux.add(it);
    }
    for (final w in kc.jl(kc.jm(kc.jm(blocs[bi])['pass2'])['weeks'])) {
      final wm = kc.jm(w);
      if (wm['weekIndex'] == wb) {
        for (final d in kc.jl(wm['days'])) {
          final dm = kc.jm(d);
          if (dm['dayIndex'] == di) {
            dm['items'] = nouveaux;
          }
        }
      }
    }
  }
  return blocs;
}

/// Texte d'un plantage de Koach (`'%s: %s | %s'` de la référence : type,
/// message, ligne de la pile où l'erreur est levée).
String _textePlantage(Object e, StackTrace st) {
  final lignes = <String>[
    for (final l in st.toString().split('\n'))
      if (l.trim().isNotEmpty) l.trim(),
  ];
  return '${e.runtimeType}: $e | ${lignes.isEmpty ? '' : lignes.first}';
}

/// Simule une saison conduite par Koach (`evaluer_saison`). [travail] :
/// `{cle, scenario, kind, seed, spec, surcharges}`. Renvoie les mesures
/// (sérialisables). Une saison qui plante dans Koach compte pour une
/// performance 0 et est signalée (`plantage`).
///
/// [briques] : extensions de Koach montées (aucune par défaut, comme
/// `PolitiqueKoach()` de la référence ; `kmBriquesCompletes` pour Koach
/// complet, graine du banc = [travail] `seed`) ; [trajectoires] du jumeau
/// (défaut des paramètres).
Map<String, Object?> kmEvaluerSaisonAdversaire(
  KmBanc banc,
  kc.Json travail, {
  List<String> briques = const <String>[],
  int? trajectoires,
}) {
  final cle = travail['cle']! as String;
  final scenario = travail['scenario']! as String;
  final kind = travail['kind']! as String;
  final seed = kc.ent(travail['seed']);
  final saison = kc.copieJson(banc.saison(cle, scenario));
  final echeances = kmJoursEcheance(saison);
  final specJson = <String, Object?>{
    ...kc.jm(saison['specJson']),
    ...kc.jm(travail['spec']),
  };
  final present =
      echeances.isEmpty ||
      echeances.any((j) => kmPresentLeJour(specJson, seed, j));
  final sortie = <String, Object?>{
    'seed': seed,
    'echeance': echeances.isNotEmpty,
    'present': present,
    'plantage': null,
  };
  KmTour? tour;
  Object? erreur;
  StackTrace? pile;
  try {
    tour = kmSimuler(
      banc.catalog,
      saison,
      banc.politique(
        // Sans extension, la graine n'est pas lue (`PolitiqueKoach()` de la
        // référence) ; avec, graine du banc = graine de la saison
        // (`campagne.politique`).
        graine: briques.isEmpty ? 0 : seed,
        briques: briques,
        trajectoires: trajectoires,
      ),
      kind,
      seed,
      specJson: specJson,
      surcharges: kmOverridesOf(travail['surcharges']),
    );
  } catch (e, st) {
    erreur = e;
    pile = st;
  }
  if (tour == null) {
    // Koach est en cours de modification : on note et on continue.
    sortie.addAll(<String, Object?>{
      'plantage': _textePlantage(erreur ?? 'erreur inconnue', pile ?? StackTrace.empty),
      'perf_a': (echeances.isNotEmpty && present) ? 0.0 : null,
      'evenements': <Object?>[],
      'e1rm6': null,
      'e1rm_famille': null,
      'e1rm_n': 0,
      'aggravations': 0,
      'poussees': 0,
      'echecs': null,
      'violations': null,
      'codes_violations': <String, Object?>{},
      'gain': null,
      'faites': 0,
      'prevues': 0,
    });
    return sortie;
  }
  final evs = kmEvenements(tour);
  final (mae, famille, n) = kmErreurE1rm(tour);
  final eff = kmEffort(tour);
  var codes = <String, Object?>{};
  int? nviol;
  try {
    final constats = banc
        .constatsDe(saison)
        .constats(kmBlocsServisAdversaire(saison, tour));
    final parCode = <String, Object?>{};
    for (final c in constats) {
      final code = c['code']! as String;
      parCode[code] = ((parCode[code] as int?) ?? 0) + 1;
    }
    codes = parCode;
    nviol = constats.length;
  } catch (_) {
    codes = <String, Object?>{};
    nviol = null;
  }
  final g = kmGainMoyen(tour);
  sortie.addAll(<String, Object?>{
    'perf_a': kmR6(kmPerfJourJ(evs, echeances.isNotEmpty, present)),
    'evenements': <Object?>[
      for (final e in evs)
        <Object?>[
          e[0],
          e[1],
          kmR6(e[2] as num?),
          kmR6(e[4] as num?),
          kc.vrai(e[4]) ? kmR6(kc.dbl(e[2]) / kc.dbl(e[4])) : null,
        ],
    ],
    'e1rm6': kmR6(mae),
    'e1rm_famille': famille,
    'e1rm_n': n,
    'aggravations': tour.painAggravations,
    'poussees': tour.painFlares,
    'echecs': kmR6(eff['echecs'] as num?),
    'violations': nviol,
    'codes_violations': codes,
    'gain': kmR6(g),
    'faites': tour.sessionsDone,
    'prevues': tour.sessionsPlanned,
  });
  return sortie;
}

/// Difficulté d'un adversaire (à MAXIMISER) à partir de ses saisons :
/// objectif `a` → 1 − moyenne des performances le jour J ; `b` → moyenne
/// des erreurs d'e1RM au rang 6. Renvoie (difficulté, objectif effectif)
/// (`difficulte`).
(double, String) kmDifficulte(List<kc.Json> saisons, String objectif) {
  if (objectif == 'a') {
    final perfs = <num>[
      for (final s in saisons)
        if (s['perf_a'] != null) s['perf_a']! as num,
    ];
    if (perfs.isNotEmpty) {
      return (kmR6(1.0 - kmSommePy(perfs) / perfs.length)!, 'a');
    }
  }
  final errs = <num>[
    for (final s in saisons)
      if (s['e1rm6'] != null) s['e1rm6']! as num,
  ];
  // Plantage sans mesure : difficulté maximale de l'échelle (b).
  if (saisons.any((s) => kc.vrai(s['plantage'])) && errs.isEmpty) {
    return (1.0, 'b');
  }
  return (
    errs.isNotEmpty ? kmR6(kmSommePy(errs) / errs.length)! : 0.0,
    'b',
  );
}

/// Mesures de Koach agrégées sur les graines d'un adversaire (`_resume`).
Map<String, Object?> kmResumeKoach(List<kc.Json> saisons) {
  double? moy(String cle) {
    final xs = <num>[
      for (final s in saisons)
        if (s[cle] != null) s[cle]! as num,
    ];
    return xs.isNotEmpty ? kmR6(kmSommePy(xs) / xs.length) : null;
  }

  final perfs = <num>[
    for (final s in saisons)
      if (s['perf_a'] != null) s['perf_a']! as num,
  ];
  num? minimum;
  for (final p in perfs) {
    if (minimum == null || p < minimum) {
      minimum = p;
    }
  }
  var aggravations = 0;
  var poussees = 0;
  var violations = 0;
  var sansViolations = false;
  for (final s in saisons) {
    aggravations += kc.ent(s['aggravations']);
    poussees += kc.ent(s['poussees']);
    if (s['violations'] == null) {
      sansViolations = true;
    } else {
      violations += kc.ent(s['violations']);
    }
  }
  return <String, Object?>{
    'perf_a': moy('perf_a'),
    'perf_a_min': kmR6(minimum),
    'e1rm6': moy('e1rm6'),
    'echecs': moy('echecs'),
    'aggravations': aggravations,
    'poussees': poussees,
    'violations': sansViolations ? null : violations,
    'plantages': <Object?>[
      for (final s in saisons)
        if (kc.vrai(s['plantage'])) s['plantage'],
    ],
    'gain': moy('gain'),
    'par_graine': saisons,
  };
}

// ---------------------------------------------------------------------------
// Recherche
// ---------------------------------------------------------------------------

/// Hypercube latin de [n] points dans [0, 1]^D (Fisher-Yates par
/// dimension) (`_hypercube`).
List<List<double>> kmHypercube(kc.Mulberry32 rng, int n) {
  final pts = <List<double>>[
    for (var i = 0; i < n; i++) List<double>.filled(kmAdvD, 0.0),
  ];
  for (var j = 0; j < kmAdvD; j++) {
    final perm = <int>[for (var i = 0; i < n; i++) i];
    for (var i = n - 1; i > 0; i--) {
      final k = (rng.next() * (i + 1)).truncate();
      final t = perm[i];
      perm[i] = perm[k];
      perm[k] = t;
    }
    for (var i = 0; i < n; i++) {
      pts[i][j] = (perm[i] + rng.next()) / n;
    }
  }
  return pts;
}

/// Réflexion dans [0, 1] (`_reflechir`).
double kmReflechir(double x0) {
  var x = x0;
  while (x < 0 || x > 1) {
    x = x < 0 ? -x : 2 - x;
  }
  return x;
}

/// Enfant (μ+λ) : bruit gaussien de pas [sigma] sur chaque coordonnée et,
/// avec une probabilité 1/8 par coordonnée, un nouveau tirage uniforme
/// (`_muter`).
List<double> kmMuter(kc.Mulberry32 rng, List<Object?> parent, double sigma) {
  final out = <double>[];
  for (final x in parent) {
    if (rng.next() < 0.125) {
      out.add(rng.next());
    } else {
      out.add(kmReflechir(kc.dbl(x) + sigma * rng.gauss()));
    }
  }
  return out;
}

/// Adversaire décodé de [u] dans la cellule [cadre] (`_adversaire`).
Map<String, Object?> kmAdversaire(
  KmCadreAdversaire cadre,
  List<double> u,
  String role,
  int graines,
) {
  final (spec, surcharges, v) = kmDecoder(u, cadre);
  final seeds = kmGrainesValides(cadre, spec, graines);
  return <String, Object?>{
    'id': kmIdentifiant(cadre.cle, cadre.scenario, cadre.kind, spec, surcharges),
    'role': role,
    'key': cadre.cle,
    'scenario': cadre.scenario,
    'kind': cadre.kind,
    'seeds': seeds,
    'echeance': cadre.echeances.isNotEmpty,
    'echeances': cadre.echeances,
    'fin_episodes': cadre.finEpisodes,
    'poids_corps': cadre.poidsCorps,
    'spec': spec,
    'surcharges': surcharges,
    'parametres': v,
    'u': <Object?>[for (final x in u) kmR6(x)],
  };
}

/// Travaux d'évaluation d'un adversaire, un par graine (`_travaux`).
List<Map<String, Object?>> kmTravaux(kc.Json adv) => <Map<String, Object?>>[
  for (final g in kc.jl(adv['seeds']))
    <String, Object?>{
      'cle': adv['key'],
      'scenario': adv['scenario'],
      'kind': adv['kind'],
      'seed': g,
      'spec': adv['spec'],
      'surcharges': adv['surcharges'],
    },
];

/// Évaluation d'un lot de saisons (`_evaluer_tous`) : mesures de
/// [kmEvaluerSaisonAdversaire], dans l'ordre des travaux.
typedef KmEvaluateurSaisons =
    Future<List<Map<String, Object?>>> Function(
      List<Map<String, Object?>> travaux,
    );

Future<int> _evaluerAdversaires(
  List<Map<String, Object?>> advs,
  String objectif,
  KmEvaluateurSaisons evaluer,
  void Function(int n)? journal,
) async {
  final travaux = <Map<String, Object?>>[];
  for (final a in advs) {
    travaux.addAll(kmTravaux(a));
  }
  final res = await evaluer(travaux);
  if (res.length != travaux.length) {
    throw StateError(
      'évaluation : ${res.length} résultats pour ${travaux.length} saisons',
    );
  }
  var k = 0;
  for (final a in advs) {
    final n = kc.jl(a['seeds']).length;
    final saisons = res.sublist(k, k + n);
    k += n;
    a['koach'] = kmResumeKoach(saisons);
    final (d, o) = kmDifficulte(saisons, objectif);
    a['difficulte'] = d;
    a['objectif_effectif'] = o;
  }
  journal?.call(travaux.length);
  return travaux.length;
}

/// Recherche minimax bornée (`chercher`). [budget] : nombre total de
/// saisons simulées (témoins compris). [cadreDe] : cadre d'une cellule
/// (`Cadre(cle, scenario, kind)`) ; [evaluer] : évaluation des saisons
/// (`_evaluer_tous`) ; [journal] reçoit le nombre de saisons simulées
/// depuis le début après chaque lot (`bavard`). Renvoie le dictionnaire du
/// fichier lisible (`adversaires_v1.json`), dont `adversaires` = les
/// [nPires] plus difficiles (répartis entre cellules) puis [nTemoins]
/// tirés au hasard.
Future<Map<String, Object?>> kmChercherAdversaires({
  required KmCadreAdversaire Function(String cle, String scenario, String kind)
  cadreDe,
  required KmEvaluateurSaisons evaluer,
  int budget = 300,
  List<String> profils = kmAdvProfilsDefaut,
  String scenario = kmAdvScenarioDefaut,
  String modeles = kmAdvModelesDefaut,
  int graines = 2,
  String objectif = 'a',
  int nPires = 32,
  int nTemoins = 8,
  int graine = 20261009,
  void Function(int vus)? journal,
}) async {
  if (graines < 2) {
    throw ArgumentError('au moins 2 graines par adversaire');
  }
  if (objectif != 'a' && objectif != 'b') {
    throw ArgumentError("objectif : 'a' ou 'b'");
  }
  final cadres = <KmCadreAdversaire>[
    for (final c in profils)
      for (final k in modeles.split('')) cadreDe(c, scenario, k),
  ];
  var vus = 0;
  void noter(int n) {
    vus += n;
    journal?.call(vus);
  }

  // Témoins : tirages uniformes dans l'espace, cellules à tour de rôle.
  final rngT = kc.Mulberry32(kc.fnv1a32('$graine|temoins'));
  final temoins = <Map<String, Object?>>[];
  for (var i = 0; i < nTemoins; i++) {
    final u = <double>[for (var j = 0; j < kmAdvD; j++) rngT.next()];
    temoins.add(
      kmAdversaire(cadres[i % cadres.length], u, 'temoin', graines),
    );
  }
  final reste = budget - nTemoins * graines;
  // Adversaires par cellule.
  final parCellule = kc.divEnt(kc.divEnt(reste, cadres.length), graines);
  if (parCellule < 3) {
    throw ArgumentError(
      'budget trop petit : $budget saison(s) pour ${cadres.length} '
      'cellule(s) × $graines graines',
    );
  }
  final n0 = math.max(2, (parCellule / 2.0).ceil());
  final nEvo = parCellule - n0;
  final lam = math.max(1, (nEvo / 3.0).ceil());
  final mu = math.max(2, (n0 / 3.0).ceil());
  final rngs = <kc.Mulberry32>[
    for (final c in cadres) kc.Mulberry32(kc.fnv1a32('$graine|${c.nom}')),
  ];
  final populations = <List<Map<String, Object?>>>[
    for (final _ in cadres) <Map<String, Object?>>[],
  ];
  // 1) Tirage initial (hypercube latin) de toutes les cellules, plus les
  // témoins, évalués ensemble.
  var lot = <Map<String, Object?>>[];
  for (var ci = 0; ci < cadres.length; ci++) {
    final c = cadres[ci];
    for (final u in kmHypercube(rngs[ci], n0)) {
      final a = kmAdversaire(c, u, 'pire', graines);
      a['generation'] = 0;
      populations[ci].add(a);
      lot.add(a);
    }
  }
  await _evaluerAdversaires(
    <Map<String, Object?>>[...lot, ...temoins],
    objectif,
    evaluer,
    noter,
  );
  var initial = <double>[
    for (final pop in populations) _maxDifficulte(pop),
  ];
  var initialId = <Object?>[
    for (final pop in populations) _classer(pop)[0]['id'],
  ];
  // 2) Évolution (μ+λ) : les μ meilleurs de toute la population de la
  // cellule engendrent λ enfants ; le pas décroît de génération en
  // génération (exploration puis raffinement).
  var faits = 0;
  var gen = 0;
  var sigma = 0.20;
  while (faits < nEvo) {
    gen += 1;
    final n = math.min(lam, nEvo - faits);
    lot = <Map<String, Object?>>[];
    for (var ci = 0; ci < cadres.length; ci++) {
      final c = cadres[ci];
      // Les témoins de la cellule, déjà évalués, peuvent servir de parents
      // (ils restent des témoins dans l'export).
      final locaux = <Map<String, Object?>>[
        for (final t in temoins)
          if (t['key'] == c.cle && t['kind'] == c.kind) t,
      ];
      final pop = _classer(<kc.Json>[...populations[ci], ...locaux]);
      final parents = pop.sublist(0, math.min(mu, pop.length));
      final deja = <Object?>{
        for (final a in <kc.Json>[...populations[ci], ...locaux]) a['id'],
      };
      for (var r = 0; r < n; r++) {
        late kc.Json p;
        late Map<String, Object?> a;
        for (var essai = 0; essai < 8; essai++) {
          p = parents[(rngs[ci].next() * parents.length).truncate()];
          a = kmAdversaire(
            c,
            kmMuter(rngs[ci], kc.jl(p['u']), sigma),
            'pire',
            graines,
          );
          if (!deja.contains(a['id'])) {
            break;
          }
        }
        a['generation'] = gen;
        a['parent'] = p['id'];
        deja.add(a['id']);
        populations[ci].add(a);
        lot.add(a);
      }
    }
    await _evaluerAdversaires(lot, objectif, evaluer, noter);
    faits += n;
    sigma *= 0.7;
  }
  // 3) Confirmation : le reste du budget (arrondi de la répartition) ajoute
  // une graine aux adversaires les plus difficiles, cellules à tour de
  // rôle ; leur difficulté est recalculée sur toutes leurs graines.
  final resteFinal = budget - vus;
  if (resteFinal > 0) {
    final classes = <List<kc.Json>>[
      for (final pop in populations) _classer(pop),
    ];
    final ordre = <(int, kc.Json)>[];
    final rangMax = classes.map((cl) => cl.length).reduce(math.max);
    for (var rang = 0; rang < rangMax; rang++) {
      for (var ci = 0; ci < classes.length; ci++) {
        final cl = classes[ci];
        if (rang < cl.length) {
          ordre.add((ci, cl[rang]));
        }
      }
    }
    final choisis = ordre.sublist(0, math.min(resteFinal, ordre.length));
    final travaux = <Map<String, Object?>>[];
    for (final (ci, a) in choisis) {
      final seeds = <int>[for (final s in kc.jl(a['seeds'])) kc.ent(s)];
      final g = kmGrainesValides(
        cadres[ci],
        kc.jm(a['spec']),
        1,
        depart: seeds.reduce(math.max) + 1,
      )[0];
      a['seeds'] = <int>[...seeds, g];
      travaux.addAll(
        kmTravaux(<String, Object?>{
          ...a,
          'seeds': <int>[g],
        }),
      );
    }
    final res = await evaluer(travaux);
    if (res.length != travaux.length) {
      throw StateError(
        'évaluation : ${res.length} résultats pour ${travaux.length} saisons',
      );
    }
    noter(travaux.length);
    for (var i = 0; i < choisis.length; i++) {
      final a = choisis[i].$2;
      final saisons = <kc.Json>[
        for (final x in kc.jl(kc.jm(a['koach'])['par_graine'])) kc.jm(x),
        res[i],
      ];
      a['koach'] = kmResumeKoach(saisons);
      final (d, o) = kmDifficulte(saisons, objectif);
      a['difficulte'] = d;
      a['objectif_effectif'] = o;
      a['confirme'] = true;
    }
    // Le tirage initial est relu après confirmation (même échelle).
    initial = <double>[
      for (final pop in populations)
        _maxDifficulte(pop.where((a) => a['generation'] == 0)),
    ];
    initialId = <Object?>[
      for (final pop in populations)
        _classer(pop.where((a) => a['generation'] == 0))[0]['id'],
    ];
  }
  // 4) Les N pires : à tour de rôle entre cellules, chacune donnant son
  // pire adversaire non encore retenu.
  final classes = <List<kc.Json>>[
    for (final pop in populations) _classer(pop),
  ];
  final pires = <kc.Json>[];
  var rang = 0;
  final rangMax = classes.map((cl) => cl.length).reduce(math.max);
  while (pires.length < nPires && rang < rangMax) {
    for (final cl in classes) {
      if (rang < cl.length && pires.length < nPires) {
        pires.add(cl[rang]);
      }
    }
    rang += 1;
  }
  final cellules = <Object?>[];
  for (var ci = 0; ci < cadres.length; ci++) {
    final c = cadres[ci];
    final cl = classes[ci];
    var plantages = 0;
    for (final a in cl) {
      plantages += kc.jl(kc.jm(a['koach'])['plantages']).length;
    }
    cellules.add(<String, Object?>{
      'cellule': c.nom,
      'echeances': c.echeances,
      'principaux': c.principaux,
      'evalues': cl.length,
      'difficulte_initiale_max': initial[ci],
      'pire_initial': initialId[ci],
      'difficulte_max': cl[0]['difficulte'],
      'objectif_effectif': cl[0]['objectif_effectif'],
      'pire': cl[0]['id'],
      'plantages': plantages,
    });
  }
  final plantages = <Object?>[];
  void noterPlantages(kc.Json a) {
    final seeds = kc.jl(a['seeds']);
    final parGraine = kc.jl(kc.jm(a['koach'])['par_graine']);
    for (var i = 0; i < math.min(seeds.length, parGraine.length); i++) {
      final s = kc.jm(parGraine[i]);
      if (kc.vrai(s['plantage'])) {
        plantages.add(<String, Object?>{
          'id': a['id'],
          'key': a['key'],
          'scenario': a['scenario'],
          'kind': a['kind'],
          'seed': seeds[i],
          'spec': a['spec'],
          'surcharges': a['surcharges'],
          'erreur': s['plantage'],
        });
      }
    }
  }

  for (final pop in populations) {
    pop.forEach(noterPlantages);
  }
  temoins.forEach(noterPlantages);
  return <String, Object?>{
    'schema': kmAdvSchema,
    'version': kmAdvVersion,
    'recherche': <String, Object?>{
      'budget': budget,
      'saisons_simulees': vus,
      'graines_par_adversaire': graines,
      'objectif': objectif,
      'graine': graine,
      'scenario': scenario,
      'profils': List<String>.of(profils),
      'modeles': modeles,
      'adversaires_par_cellule': parCellule,
      'tirage_initial': n0,
      'mu': mu,
      'lambda': lam,
      'generations': gen,
      'n_pires': nPires,
      'n_temoins': nTemoins,
      'recul_echeance_jours': kmAdvReculEcheance,
    },
    'espace': <Object?>[for (final d in kmAdvDimensions) d.toJson()],
    'cellules': cellules,
    'plantages': plantages,
    'adversaires': <Object?>[...pires, ...temoins],
  };
}

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

/// Entrées de `kmAdversaryRun` : une par adversaire et par graine,
/// `{"id", "key", "scenario", "kind", "seed", "spec", "surcharges"}` ;
/// l'identifiant est `<id de l'adversaire>-g<graine>` (`entrees_dart`).
List<Map<String, Object?>> kmEntreesDart(List<kc.Json> adversaires) =>
    <Map<String, Object?>>[
      for (final a in adversaires)
        for (final g in kc.jl(a['seeds']))
          <String, Object?>{
            'id': '${a['id']}-g${kc.ent(g)}',
            'key': a['key'],
            'scenario': a['scenario'],
            'kind': a['kind'],
            'seed': g,
            'spec': a['spec'],
            'surcharges': a['surcharges'],
          },
    ];

/// Adversaires d'un fichier lisible (objet : champ `adversaires`) ou d'une
/// liste (`lire_adversaires`, contenu déjà décodé).
List<kc.Json> kmLireAdversaires(Object? json) {
  final l = json is Map<String, Object?> ? json['adversaires'] : json;
  return <kc.Json>[for (final a in kc.jl(l)) kc.jm(a)];
}

// ---------------------------------------------------------------------------
// Comparaison avec le témoin Dart
// ---------------------------------------------------------------------------

/// Erreur absolue moyenne au rang 6 du témoin (`KmEstimateStats` :
/// `bySession[k]` = [n, Σ|err|, Σerr, Σerr², n<3 %, n couverts]), même
/// chaîne de familles que Koach (`_e1rm_dart`).
(double?, String?) kmE1rmDart(Object? estimates) {
  final est = kc.dictOuVide(estimates);
  for (final nom in kmAdvChaineE1rm) {
    final e = est[nom];
    if (!kc.vrai(e)) {
      continue;
    }
    final rows = kc.listeOuVide(kc.jm(e)['bySession']);
    if (rows.length > kmAdvRangE1rm &&
        kc.dbl(kc.jl(rows[kmAdvRangE1rm])[0]) > 0) {
      final r = kc.jl(rows[kmAdvRangE1rm]);
      return (kc.dbl(r[1]) / kc.dbl(r[0]), nom);
    }
  }
  return (null, null);
}

/// Mesures d'une saison du témoin (élément de la sortie de
/// `kmAdversaryRun`, `adversaires_temoin.json.gz`) (`mesures_dart`).
Map<String, Object?> kmMesuresDart(
  kc.Json entree,
  bool echeance,
  bool present,
) {
  final run = kc.jm(entree['run']);
  final ratios = <double>[];
  for (final e0 in kc.listeOuVide(run['events'])) {
    final e = kc.jl(e0);
    final best = e[3];
    final dayMax = e[5];
    if (kc.vrai(dayMax)) {
      ratios.add(kc.dbl(best) / kc.dbl(dayMax));
    }
  }
  double? perf;
  if (echeance && present) {
    perf = ratios.isNotEmpty ? kmSommeD(ratios) / ratios.length : 0.0;
  }
  final (mae, famille) = kmE1rmDart(entree['estimates']);
  return <String, Object?>{
    'seed': entree['seed'],
    'perf_a': kmR6(perf),
    'e1rm6': kmR6(mae),
    'e1rm_famille': famille,
    'aggravations': run['painAggravations'] ?? 0,
    'poussees': run['painFlares'] ?? 0,
    'violations': run['violations'] ?? 0,
    'codes_violations': kc.vrai(run['violationCodes'])
        ? run['violationCodes']
        : <String, Object?>{},
    'gain': run['gainMean'],
  };
}

List<num> _nonNuls(Iterable<Object?> valeurs) => <num>[
  for (final x in valeurs)
    if (x != null) x as num,
];

num _min(List<num> xs) => xs.reduce((a, b) => b < a ? b : a);

num _max(List<num> xs) => xs.reduce((a, b) => b > a ? b : a);

/// `_stat` : effectif, moyenne, pire (minimum).
Map<String, Object?> kmStatAdv(Iterable<Object?> valeurs) {
  final xs = _nonNuls(valeurs);
  if (xs.isEmpty) {
    return <String, Object?>{'n': 0, 'moyenne': null, 'pire': null};
  }
  return <String, Object?>{
    'n': xs.length,
    'moyenne': kmR6(kmSommePy(xs) / xs.length),
    'pire': kmR6(_min(xs)),
  };
}

/// `_stat_max` : effectif, moyenne, pire (maximum).
Map<String, Object?> kmStatMaxAdv(Iterable<Object?> valeurs) {
  final xs = _nonNuls(valeurs);
  if (xs.isEmpty) {
    return <String, Object?>{'n': 0, 'moyenne': null, 'pire': null};
  }
  return <String, Object?>{
    'n': xs.length,
    'moyenne': kmR6(kmSommePy(xs) / xs.length),
    'pire': kmR6(_max(xs)),
  };
}

int _somme(Iterable<Object?> xs) {
  var s = 0;
  for (final x in xs) {
    s += kc.ent(x);
  }
  return s;
}

/// Compare Koach et le témoin (sorties de `kmAdversaryRun`, [sortieDart])
/// sur les mêmes adversaires (`comparer`). [saisonsKoach] : mesures de
/// Koach rejouées ([kmEvaluerSaisonAdversaire], dans l'ordre de
/// [kmTravaux] de chaque adversaire, adversaires dans l'ordre) ; sans
/// elles, les mesures stockées (`koach.par_graine`, `rejouer_koach=False`).
Map<String, Object?> kmComparerAdversaires(
  List<kc.Json> adversaires,
  List<kc.Json> sortieDart, {
  List<kc.Json>? saisonsKoach,
}) {
  final dart = <Object?, kc.Json>{for (final e in sortieDart) e['id']: e};
  final lignes = <kc.Json>[];
  var k = 0;
  for (final a in adversaires) {
    final seeds = kc.jl(a['seeds']);
    final List<kc.Json> saisons;
    if (saisonsKoach != null) {
      saisons = saisonsKoach.sublist(k, k + seeds.length);
      k += seeds.length;
    } else {
      saisons = <kc.Json>[
        for (final x in kc.jl(kc.jm(a['koach'])['par_graine'])) kc.jm(x),
      ];
    }
    final rk = kmResumeKoach(saisons);
    final temoin = <kc.Json>[];
    final manquants = <Object?>[];
    for (var i = 0; i < math.min(seeds.length, saisons.length); i++) {
      final g = seeds[i];
      final e = dart['${a['id']}-g${kc.ent(g)}'];
      if (e == null) {
        manquants.add(g);
        continue;
      }
      temoin.add(
        kmMesuresDart(e, kc.vrai(a['echeance']), kc.vrai(saisons[i]['present'])),
      );
    }
    final perfsT = _nonNuls(<Object?>[for (final t in temoin) t['perf_a']]);
    final errsT = _nonNuls(<Object?>[for (final t in temoin) t['e1rm6']]);
    lignes.add(<String, Object?>{
      'id': a['id'],
      'role': a['role'],
      'key': a['key'],
      'scenario': a['scenario'],
      'kind': a['kind'],
      'seeds': a['seeds'],
      'echeance': a['echeance'],
      'koach': <String, Object?>{
        for (final kk in const <String>[
          'perf_a',
          'perf_a_min',
          'e1rm6',
          'echecs',
          'aggravations',
          'poussees',
          'violations',
          'plantages',
        ])
          kk: rk[kk],
      },
      'temoin': <String, Object?>{
        'perf_a': perfsT.isNotEmpty
            ? kmR6(kmSommePy(perfsT) / perfsT.length)
            : null,
        'perf_a_min': perfsT.isNotEmpty ? kmR6(_min(perfsT)) : null,
        'e1rm6': errsT.isNotEmpty
            ? kmR6(kmSommePy(errsT) / errsT.length)
            : null,
        'aggravations': _somme(<Object?>[
          for (final t in temoin) t['aggravations'],
        ]),
        'poussees': _somme(<Object?>[for (final t in temoin) t['poussees']]),
        'violations': _somme(<Object?>[
          for (final t in temoin) t['violations'],
        ]),
        'manquants': manquants,
      },
    });
  }

  kc.Json ko(kc.Json l) => kc.jm(l['koach']);
  kc.Json te(kc.Json l) => kc.jm(l['temoin']);
  Map<String, Object?> synthese(List<kc.Json> sel) => <String, Object?>{
    'n': sel.length,
    'perf_a': <String, Object?>{
      'koach': kmStatAdv(<Object?>[for (final l in sel) ko(l)['perf_a']]),
      'temoin': kmStatAdv(<Object?>[for (final l in sel) te(l)['perf_a']]),
    },
    'perf_a_par_saison': <String, Object?>{
      'koach': kmStatAdv(<Object?>[for (final l in sel) ko(l)['perf_a_min']]),
      'temoin': kmStatAdv(<Object?>[
        for (final l in sel) te(l)['perf_a_min'],
      ]),
    },
    'e1rm6': <String, Object?>{
      'koach': kmStatMaxAdv(<Object?>[for (final l in sel) ko(l)['e1rm6']]),
      'temoin': kmStatMaxAdv(<Object?>[for (final l in sel) te(l)['e1rm6']]),
    },
    'securite': <String, Object?>{
      'koach': <String, Object?>{
        'aggravations': _somme(<Object?>[
          for (final l in sel) ko(l)['aggravations'],
        ]),
        'poussees': _somme(<Object?>[for (final l in sel) ko(l)['poussees']]),
        'violations_indicatives': _somme(<Object?>[
          for (final l in sel) ko(l)['violations'] ?? 0,
        ]),
        'plantages': _somme(<Object?>[
          for (final l in sel) kc.jl(ko(l)['plantages']).length,
        ]),
      },
      'temoin': <String, Object?>{
        'aggravations': _somme(<Object?>[
          for (final l in sel) te(l)['aggravations'],
        ]),
        'poussees': _somme(<Object?>[for (final l in sel) te(l)['poussees']]),
        'violations': _somme(<Object?>[
          for (final l in sel) te(l)['violations'],
        ]),
      },
    },
  };

  final groupes = <String, Object?>{
    'tous': synthese(lignes),
    'pires': synthese(<kc.Json>[
      for (final l in lignes)
        if (l['role'] == 'pire') l,
    ]),
    'temoins': synthese(<kc.Json>[
      for (final l in lignes)
        if (l['role'] == 'temoin') l,
    ]),
  };
  final tous = kc.jm(kc.jm(groupes['tous'])['perf_a']);
  final pk = kc.jm(tous['koach'])['pire'] as double?;
  final pt = kc.jm(tous['temoin'])['pire'] as double?;
  return <String, Object?>{
    'schema': kmAdvSchema,
    'adversaires': lignes,
    'groupes': groupes,
    'critere': <String, Object?>{
      'libelle':
          'pire cas de Koach >= pire cas du témoin (performance le jour J, '
          'moyenne par adversaire)',
      'pire_koach': pk,
      'pire_temoin': pt,
      'respecte': (pk == null || pt == null) ? null : pk >= pt - 1e-12,
      'saisons_temoin_manquantes': _somme(<Object?>[
        for (final l in lignes) kc.jl(te(l)['manquants']).length,
      ]),
    },
  };
}

// ---------------------------------------------------------------------------
// Résumés lisibles (ligne de commande de la référence)
// ---------------------------------------------------------------------------

String _pyStr(Object? x) => x is String ? x : kmReprPy(x);

String _f4(Object? x) => kc.dbl(x).toStringAsFixed(4);

/// `_resume_texte` : résumé d'une recherche ([n] pires adversaires).
String kmResumeTexteRecherche(Map<String, Object?> res, [int n = 10]) {
  final lignes = <String>[];
  final r = kc.jm(res['recherche']);
  lignes.add(
    'saisons simulées : ${r['saisons_simulees']} (budget ${r['budget']}), '
    '${r['adversaires_par_cellule']} adversaires par cellule, '
    '${r['generations']} générations',
  );
  for (final c0 in kc.jl(res['cellules'])) {
    final c = kc.jm(c0);
    final pl = kc.ent(c['plantages']);
    lignes.add(
      '  ${(c['cellule']! as String).padRight(60)} initial '
      '${_f4(c['difficulte_initiale_max'])} -> ${_f4(c['difficulte_max'])} '
      '(${c['objectif_effectif']})${pl != 0 ? '  plantages $pl' : ''}',
    );
  }
  final pires = kmTriStable<kc.Json>(
    <kc.Json>[
      for (final a in kc.jl(res['adversaires']))
        if (kc.jm(a)['role'] == 'pire') kc.jm(a),
    ],
    (a, b) {
      var c = (a['objectif_effectif']! as String).compareTo(
        b['objectif_effectif']! as String,
      );
      if (c != 0) {
        return c;
      }
      c = _cmp(kc.dbl(b['difficulte']), kc.dbl(a['difficulte']));
      return c != 0 ? c : (a['id']! as String).compareTo(b['id']! as String);
    },
  );
  lignes.add('pires adversaires :');
  for (final a in pires.take(n)) {
    final k = kc.jm(a['koach']);
    final cle = a['key']! as String;
    lignes.add(
      '  ${a['id']} ${cle.length > 22 ? cle.substring(0, 22) : cle} '
      '${a['kind']} ${a['objectif_effectif']} d=${_f4(a['difficulte'])} '
      'perf_a=${_pyStr(k['perf_a'])} e1rm6=${_pyStr(k['e1rm6'])} '
      'aggr=${k['aggravations']} pouss=${k['poussees']} '
      'echecs=${_pyStr(k['echecs'])}',
    );
  }
  return lignes.join('\n');
}

/// Lignes imprimées par la référence après `comparer` (`main`).
String kmResumeTexteComparaison(Map<String, Object?> cmp) {
  final lignes = <String>[];
  for (final e in kc.jm(cmp['groupes']).entries) {
    final g = kc.jm(e.value);
    final pa = kc.jm(g['perf_a']);
    final k = kc.jm(pa['koach']);
    final t = kc.jm(pa['temoin']);
    lignes.add(
      '${e.key.padRight(8)} n=${g['n']}  jour J koach moy '
      '${_pyStr(k['moyenne'])} pire ${_pyStr(k['pire'])} | témoin moy '
      '${_pyStr(t['moyenne'])} pire ${_pyStr(t['pire'])}',
    );
  }
  lignes.add(
    'critère : ${kmJsonPython(cmp['critere'], ensureAscii: false)}',
  );
  return lignes.join('\n');
}
