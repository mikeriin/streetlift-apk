# Contrat L9 (révision L9R) — pack de contenu Kalis Track v2

Le lot L9R remplace la seconde passe prévue pour L9 : pack **autonome**, aucune modification de l'application. Il sera intégré par L9b (moteur Flutter des démonstrations, atlas, lecture de `exercises_v2.json`) puis consommé par le générateur de programmes du lot L10. Les sections marquées **(L9R)** changent par rapport au pack v1 ; le reste est reconduit.

| Élément | Version |
| --- | --- |
| Pack | **2.0.0** (candidat, avant relecture du propriétaire) — archive `kalis_content_pack_v2_candidat.zip` |
| Schéma exercice | **2.1.0** |
| Taxonomie musculaire (`muscles.json`) et atlas (`atlas.svg`) | 2.0.0 |
| Poses (`poses.json`) | 2.0.0 |
| Moteur de rendu de référence | `renderer_reference/kt_pose.js` 2.0.0 |
| Entrées | `assets/exercises_db.json.gz` (505 exercices) et `assets/programme_v33.json.gz` de la branche `main` |
| Outils | Python 3.11 (bibliothèque standard ; `shapely` pour reconstruire l'atlas ; `playwright` + Chromium pour les planches) ; Node 22 facultatif (parité JS) |

## 1. Base existante et correspondances (reconduit)

- 505 exercices v1 (`n`, `g`, `eq`), tous rattachés à un identifiant v2 stable (`mapping_v1_to_v2.json#base_v1`, `canonique` pour les doublons) ; programme v33 : 79 intitulés rattachés avec leurs méthodes (`#programme_v33`).
- Défauts v1 conservés et signalés (`non_conformites`, `doublon_de`) ; aucune entrée supprimée.

## 2. Schéma v2.1.0 d'un exercice (`exercises_v2.json` → `exercices[]`) **(L9R)**

Le fichier contient aussi `vocabulaires` (libellés français de tous les identifiants, dont `muscles`, `muscles_familles`, `muscles_alias`), `sources` (clés de provenance) et `licence`.

| Champ | Type | Règle |
| --- | --- | --- |
| `id` | chaîne | slug ASCII `^[a-z0-9]+(-[a-z0-9]+)*$`, **stable, jamais réutilisé** ; les 555 identifiants de la v1 sont inchangés |
| `nom`, `alias` | chaîne, liste | nom v1 conservé (capitales et intitulés ambigus corrigés, ancien nom en alias) |
| `origine` | `base_v1` \| `ajout_l9` \| **`ajout_l9r`** | 505 + 50 + 70 |
| `role`, `generateur`, `famille`, `type_mouvement`, `plan`, `vue`, `unilateral` | | comme en v1 ; `famille` = archétype (237), clé de `sources/archetypes_sources.json` |
| `muscles_primaires`, `muscles_secondaires` | listes d'identifiants | **taxonomie détaillée** (`muscles.json`, 81 entrées) ; un muscle n'est jamais à la fois primaire et secondaire |
| **`muscles_stabilisateurs`** | liste | muscles en travail isométrique (gainage, coiffe, préhension…) ; distincts des moteurs |
| **`muscles_etires`** | liste | pour les exercices de mobilité |
| **`sources`** | liste `{url, consulte_le, type, entree}` | références consultées pour l'archétype (`type` : base, encyclopedie, organisme, autre) ; aucun texte repris |
| **`sources_meta`** | objet | `archetype`, `nb_sources_concordantes` (≥ 2), `desaccord`, `note_concordance`, `stabilisateurs_origine` (`source` \| `raisonnement`), `surcharge_exercice`, `difficulte_reference` |
| `mode_charge`, `mesure`, `difficulte`, `prerequis`, `progressions`, `regressions`, `contrainte_articulaire`, `precautions`, `materiel`, `lieux`, `points_cles` (3), `erreurs_frequentes` (2), `respiration`, `methodes`, `substitutions`, `substitutions_elargies`, `variante_de`, `doublon_de`, `non_conformites`, `v1` | | comme en v1 |
| `pose` | **`{gabarit, vue, statut, motif, reference}`** | `statut` ∈ `disponible` \| `statique` \| `indisponible` ; `motif` obligatoire hors `disponible` ; renvoi vers `poses.json#/exercices/<id>` |
| `provenance` | objet champ → clé | `kt_v1`, `sources_croisees` (muscles, type, sources), `genere_l9r`, `calcule` ; `*` = défaut |

## 3. Taxonomie et atlas musculaire (`muscles.json`, `atlas.svg`) **(L9R)**

### Taxonomie
- **81 entrées** (51 superficielles dessinées, 30 profondes listées en texte) : muscles ou chefs utiles à l'entraînement. Le prompt visait « environ 90 » : les 81 retenues couvrent tous les chefs demandés (grand pectoral claviculaire / sterno-costal / abdominal, deltoïde ×3, trapèze ×3, triceps ×3, quadriceps ×4, ischio-jambiers ×4, adducteurs ×5, coiffe ×4…) ; les subdivisions non discriminantes à l'entraînement (chefs du deltoïde postérieur, faisceaux des érecteurs au-delà de lombaire/thoracique, muscles isolés du pied) n'ont pas été ajoutées pour ne pas créer d'attributions invérifiables.
- Champs : `id` (stable), `nom`, `latin`, `famille`, `groupe` (**un des 11 groupes de `lib/muscle_body.dart`** : pectoraux, épaules, biceps, triceps, avant-bras, gainage, dos, quadriceps, ischios, fessiers, mollets — compatibilité de la carte actuelle), `vues` (`face`, `dos`), `profondeur`, `actions`, `regions` (ids des régions du SVG).
- `alias` : groupes composés (`pectoraux`, `ischios`, `coiffe`, `prehension`…) → listes d'ids ; `groupes_app` : ordre des 11 groupes.
- Rattachements aux groupes de l'application : adducteurs et fléchisseurs de hanche → `quadriceps` (face antérieure/interne de la cuisse) ; muscles du cou → `dos` (sterno-cléido-mastoïdien : `gainage`) ; carré des lombes, multifides → `dos` ; dentelé antérieur → `pectoraux` ; tibial antérieur, fibulaires → `mollets`.

### Atlas (dessin original)
- `viewBox 0 0 600 760` ; groupe `#vue-face` (x 0–300) et `#vue-dos` (x 300–600, translate 300). Personnage stylisé, aplats.
- Une région fermée par muscle superficiel et par côté : `path.muscle` avec `id="{vue}-{muscle}-{d|g}"`, `data-muscle`, `data-side`, `fill="currentColor" fill-opacity="0.32"` ; silhouette `path.corps` (opacité 0,18) ; repères anatomiques `path.repere` (clavicules, ligne blanche, rotules, colonne, tendon calcanéen). **Aucun chevauchement par construction** (découpe géométrique avec 1,1 px de séparation), symétrie par miroir.
- Couleurs par rôles, jamais en dur : corps = `neutre_moyen` (#8A8A8A), primaire = accent de la couleur dominante active (6 palettes de `app_theme.dart` × modes sombre/clair), secondaire = même accent atténué (opacité 0,42), stabilisateur = contour accent tireté, étiré = contour `focus`. L'information est toujours donnée en texte à côté.
- Contrôle : `planches/atlas_planche.png` (face, dos, numérotation des 51 régions, muscles profonds en texte) rendu par Chromium et vérifié visuellement.

## 4. Démonstrations par cinématique calculée (`poses.json`) **(L9R)**

### Modèle corporel (`tools/body_model.py`)
- Unité = taille H ; y vers le haut ; sol y = 0. Vue de profil : le personnage regarde vers +x ; en ATR (rotation de 180° dans le plan), face et pointes de pied vers −x, talons et doigts vers +x. Vue de face : +x = gauche du personnage.
- 23 points : tête, cou, épaules, coudes, poignets, mains (bout des doigts), prises (centre de la paume), bassin, hanches, genoux, chevilles, talons, pointes de pied. Longueurs (Drillis & Contini, fractions de H) : tronc 0,288 ; cou 0,110 ; bras 0,186 ; avant-bras 0,146 ; main 0,108 (prise à 0,050) ; cuisse 0,245 ; jambe 0,246 ; pied 0,045 (talon) + 0,107 (pointe), hauteur de cheville 0,039 ; demi-largeurs de face 0,130 (épaules) et 0,095 (bassin) ; tête r = 0,065. Masses et centres de masse segmentaires : Winter (table 4.1).
- Angles articulaires (fiche biomécanique, degrés) : `t` tronc absolu (0 vertical, + vers +x) ; `n` cou ; `hanche` flexion ; `genou` flexion ; `cheville` flexion dorsale (+) / plantaire (−) ; `epaule` flexion (profil) ou abduction (face) ; `coude` flexion ; `poignet` extension ; `p` bassin (face). Conversion en angles absolus de segment (convention v1 conservée pour le moteur : segments vers le bas 0 = bas, +90 = +x ; tronc et cou 0 = haut) : bras = −t + épaule ; avant-bras = bras + coude ; main = avant-bras + poignet ; cuisse = −t + hanche ; jambe = cuisse − genou ; pied = jambe + 90 + cheville.
- Amplitudes (contrôle) : hanche −30/135, genou −5/155, cheville −60/40, épaule −70/190, coude −5/155, poignet −90/90, cou −60/70 ; face : abduction hanche −30/100, épaule −10/190. Exceptions déclarées par gabarit (`exceptions_amplitude`) pour les figures.

### Fiche biomécanique et résolution (`tools/biomeca.py`, `tools/pose_solver.py`)
- 260 fiches (`REG`) : `images_cles` (angles de départ, ancrage, paramètres libres bornés, contraintes), `accessoires`, `contacts`, `boucle`, `phases` (articulations motrices, angles début/fin, repère), `prise`, `placement`, `contacts_texte`, `trajectoire_charge`, `tempo`, `sources` (références cinématiques), `debout`, `charge`, `note`.
- Chaque image clé est **calculée** : cinématique directe depuis les angles, puis résolution des paramètres libres pour satisfaire les contraintes (`y`/`x` d'une articulation, `com_over`/`com_x`/`com_between` pour le centre de masse, `abs` pour l'orientation d'un segment, `dist`, `min_y`) par descente par coordonnées ; le résidu est stocké (`residu_contraintes`, seuil 0,12).
- Origine x sous le centre de masse de l'image 0, sauf gabarits à origine fixe (locomotion, sauts, burpee, traîneau, wall walk, inchworm, extension triceps au sol).

### Contrôles automatiques (`tools/pose_checks.py`, 0 défaut sur 260 gabarits)
1. longueurs de segments constantes (1 %) sur chaque image et pendant l'interpolation ; 2. angles dans les amplitudes ; 3. contacts déclarés respectés (0,03) ; 4. aucune articulation sous le sol (−0,04) ni dans un accessoire plein ; 5. centre de masse au-dessus de l'appui (pieds, mains au sol) pour les gabarits debout, phases aériennes exclues ; 6. accessoires attachés à des articulations connues, valeurs finies.

### Structure de `poses.json`
- En-tête : `version`, `repere`, `modele` (articulations, segments, longueurs, épaisseurs), `roles_couleur`, `zones_silhouette`, `statuts`, `provenance`.
- `gabarits` (246 utilisés) : `{vue, boucle, images_cles[{label, phase, angles_articulaires, angles, bassin, anchor{joint,pos}, hold, dur, joints, residu_contraintes}], accessoires, contacts, exceptions_amplitude, debout, fiche_biomecanique, charge, note}`.
- `exercices` : id → `{gabarit, statut, motif, accessoires (charges ajoutées), retirer (types d'accessoires du gabarit à ne pas dessiner), muscles{primaires, secondaires}, controles_automatiques}`. Statuts : 572 `disponible`, 35 `statique` (geste hors du plan : position de départ seulement), 18 `indisponible` (l'application affiche l'atlas et les consignes).

### Moteur de rendu de référence (`renderer_reference/kt_pose.js`, spécification pour L9b)
- Silhouette volumétrique : membres en capsules (épaisseurs `WIDTH`), tronc en polygone, mains, pieds, tête ; membres du côté éloigné en `neutre_moyen_loin`. `MUSCLE_ZONE` : muscle → zones de la silhouette ; primaires en accent, secondaires atténués ; en vue de face les zones dorsales sont dessinées en contour.
- Accessoires paramétrés : barre fixe, barres parallèles, anneaux, barre basse, banc, box, marche, mur, poteau, poulie, élastique, machine, rameur, vélo, traîneau, corde ondulatoire, bâton, corde à sauter (boucle sagittale), serviette, barre chargée (disque de 45 cm), haltères, kettlebell, lest, gilet, disque, médecine-ball, sac lesté, roue, rouleau, cale/parallettes.
- Interpolation et chronologie (à reproduire en Flutter) : `v = (1 − cos πu)/2` ; interpolation linéaire des angles absolus sans repli modulo 360 ; cinématique depuis le bassin ; si deux images partagent l'ancrage, translation pour garder l'articulation d'ancrage exactement en place, sinon bassin interpolé ; `hold` puis `dur` ; boucle `aller-retour` ou `cycle` ; `staticStrip` pour la réduction des animations.
- API : `fromPack(gabarit, entree)`, `Player`, `svgFor`, `staticStrip`, `poseOf`, `roles(accent, mode)`, `ACCENTS`. Test de parité : positions `joints` de `poses.json` reproduites à < 0,002.

### Contrôle visuel
Planches PNG rendues par Chromium et regardées une à une : `planches/prioritaires_01..10.png` (150 exercices prioritaires, liste `planches/prioritaires_150.json` et `coverage_report.md` §6) et `planches/ajouts_l9r_01..03.png` (70 ajouts). Un exercice non représentable fidèlement est `indisponible` (18) ou `statique` (35) plutôt qu'animé faussement.

## 5. Autres fichiers

- `progressions.json` : 24 chaînes, 12 entrées débutant, arêtes et prérequis transverses (inchangé, tests : pas de cycle, pas d'orphelin, difficulté non décroissante).
- `mapping_v1_to_v2.json`, `coverage_report.md` (contrôles, matrice, manques justifiés, liste des 150), `validation_register.md` (§0 sources et attributions, seuils, contraintes, difficultés, NC, doublons, démonstrations, précautions), `relectures_traitees.md`, `licences.md`.
- `sources/archetypes_sources.json` (237 archétypes : sources, consensus, désaccords, erreurs v1, références de difficulté) et `sources/cinematique_references.json` (angles de référence, amplitudes, proportions).
- `review_tool.html` (outil de relecture autonome, publié au même lien que la v1 avec la base partagée `relectures_v2`) ; `renderer_reference/index.html` (démonstration 6 palettes × 2 modes).
- `tools/` : `kb_muscles.py` (taxonomie), `kb_sources.py`, `kb_archetypes.py`, `kb_exercises.py`, `kb_progressions.py`, `kb_vocab.py`, `atlas_geom.py` + `atlas_build.py`, `body_model.py`, `pose_solver.py`, `biomeca.py`, `pose_checks.py`, `build_poses.py`, `build_pack.py`, `validate.py`, `build_register.py`, `build_html.py`, `planche.py`, `render_png.py`, tests `tests/test_pack.py`.

## 6. Décisions

### Décisions L9 tranchées par le prompt L9R
| Réf. | Résolution |
| --- | --- |
| D-L9-01 | Sources publiques consultées pour vérifier les faits (voir `licences.md`) ; aucun texte ni base importés. |
| D-L9-02 | Types `isolation`, `flexion_tronc`, `hors_categorie` conservés. |
| D-L9-04 | Sans objet : rôles de couleur définis par le moteur v2 (`roles()`), `neutre_moyen` = #8A8A8A conservé. |
| D-L9-06 | « Maison équipée » = matériel léger confirmé. |
| Couverture | 79 → 22 cases sous le seuil ; 70 exercices ajoutés ; manques restants justifiés (`coverage_report.md` §3). |

### Décisions prises par défaut en L9R (réversibles)
| Réf. | Décision |
| --- | --- |
| D-L9R-01 | Relectures : la collection `relectures` était vide au lancement ; le traitement de l'étape 1 s'appuie sur le constat général, vérifié exercice par exercice (`relectures_traitees.md`). Les remarques déposées dans `relectures_v2` seront traitées à la validation. |
| D-L9R-02 | Taxonomie de 81 entrées (au lieu d'« environ 90ʼ) : tous les chefs demandés, sans subdivision invérifiable ; le découpage en chefs des muscles nommés globalement par les sources est un raisonnement anatomique signalé (`validation_register.md` §0.3). |
| D-L9R-03 | Un muscle cité par une seule source majoritairement contredite est rétrogradé (primaire → secondaire, secondaire → stabilisateur) plutôt que supprimé ; le désaccord est conservé. |
| D-L9R-04 | Six archétypes n'ont qu'une source directe ; la seconde source décrit une variante très proche (`note_concordance`). Retenus comme concordants, à confirmer par le propriétaire. |
| D-L9R-05 | Curl nordique, curl ischio glissé, sissy squat assisté : classés `isolation` (mono-articulaire) ; dragon flag : `gainage_anti_extension` ; sprints répétés et bounding : `locomotion`. |
| D-L9R-06 | Exposition à la licence CC-BY-SA de wger : option A (références conservées, rien reproduit) appliquée en attendant la décision du propriétaire (`licences.md` §3). |
| D-L9R-07 | Démonstrations : un geste hors du plan de la vue est réduit à sa position de départ (`statique`) ; un geste sans gabarit fidèle est `indisponible`. Une même famille de gabarit sert plusieurs variantes de prise (largeur, neutre, supination) : la différence est portée par le texte. |
| D-L9R-08 | Matrice de couverture : aucune variante artificielle ajoutée pour atteindre 3 ; les 22 cases restantes sont justifiées une à une. |
| D-L9R-09 | Les 70 ajouts L9R sont des variantes d'archétypes sourcés (aucun nouvel archétype sans deux sources) ; les roulades et la roue, sans source musculaire concordante, ne sont pas ajoutées. |
| D-L9R-10 | Charges : `sac_leste` porte le mode de charge `objet_leste` ; un porté à la barre (trap bar, overhead barre) n'ajoute pas de lest. |
| D-L9R-11 | Outil de relecture publié au même lien (version 2 de l'artefact), collection `relectures_v2`, l'ancienne collection `relectures` conservée (vide). |

## 7. Résultats exacts des tests (candidat v2)

Commande : `KT_V1_DB=… KT_PROGRAMME=… python3 -m unittest discover -s tools/tests -v` (Python 3.11, Node 22).
- **36 tests, 36 réussis, 0 échec, 0 ignoré** (sans les variables : 35 réussis, 1 ignoré — correspondance complète).
- `python3 tools/validate.py . --v1 … --programme …` : schéma, taxonomie, atlas, sources, graphe, poses, statuts, correspondance, prérequis, substitutions : **tous OK** ; 22 cases de la matrice sous le seuil (justifiées) ; 60 avertissements « difficulté ≥ 7 sans prérequis explicite » (non bloquants) ; 0 archétype sous deux sources concordantes.
- `python3 tools/pose_checks.py` : 260 gabarits, 0 défaut.
