# Contrat L9 — pack de contenu Kalis Track v1

Lot L9 du pipeline automatisé (tickets KT-044 à KT-049). Pack autonome : **aucune modification de l'application**. Il sera intégré au lot L9b (moteur Flutter des démonstrations, lecture de `exercises_v2.json`) puis consommé par le générateur de programmes du lot L10.

| Élément | Version |
| --- | --- |
| Pack | 1.0.0 (première passe, avant relecture du propriétaire) |
| Schéma exercice | 2.0.0 |
| Moteur de rendu de référence | `renderer_reference/kt_pose.js` 1.0.0 |
| Entrées | `assets/exercises_db.json.gz` et `assets/programme_v33.json.gz` de `streetlift_tracker_v33.zip` (branche `main`) |
| Outils | Python 3.11, bibliothèque standard uniquement ; Node 22 facultatif (test de parité JS) |

## 1. Analyse de la base existante (505 exercices)

- Champs v1 : `n` (nom), `g` (groupes musculaires en texte libre, 18 valeurs), `eq` (matériel, 18 valeurs). Aucun identifiant, aucune difficulté, aucun lieu.
- Répartition du matériel v1 : poids de corps 154, barre fixe 95, barre 61, haltères 48, barres parallèles 31, machine/poulie 33, élastique 17, lest 14, kettlebell 14, anneaux 13, autres 25.
- Défauts relevés : matériel « poids de corps » pour des exercices qui exigent un accessoire (roue, ergomètre, poteau, lest…), groupes musculaires erronés (nordic curl, good morning), intitulés génériques ou ambigus (« Isométrie maximale », « Planche (gainage) »), entrées qui ne sont pas des exercices (« Bilan », « Repos actif », « Contraste français »), charges absolues dans le nom (« Squat endurance @ 70 kg ») et doublons (« Dip » / « Dips » / « Dips PdC »…). Liste complète : `validation_register.md` §4 et §5.
- Programme v33 : 79 intitulés distincts, 1 812 occurrences ; 44 intitulés correspondent exactement à la base, 35 sont des combinaisons « exercice — méthode » (clusters, EMOM, GtG, contraste…), rattachées par analyse du nom avec leurs méthodes.

## 2. Schéma v2 d'un exercice (`exercises_v2.json` → `exercices[]`)

Le fichier contient aussi `vocabulaires` (tous les libellés français des identifiants), `sources` et `licence`.

| Champ | Type | Règle |
| --- | --- | --- |
| `id` | chaîne | slug ASCII `^[a-z0-9]+(-[a-z0-9]+)*$`, dérivé du nom v1, **stable, jamais réutilisé** (un exercice retiré garde son id réservé) |
| `nom` | chaîne | français ; nom v1 conservé sauf capitales et intitulés ambigus (l'ancien nom passe alors en alias) |
| `alias` | liste de chaînes | autres noms, dont le nom v1 s'il a changé |
| `origine` | `base_v1` \| `ajout_l9` | |
| `role` | `exercice` \| `test` \| `hors_generateur` | les tests et entrées de suivi ne sont jamais tirés par le générateur |
| `generateur` | booléen | vrai si `role = exercice`, pas un doublon, type ≠ `hors_categorie` |
| `famille` | chaîne | archétype de mouvement (regroupe les variantes) |
| `type_mouvement` | énumération | les 16 types du prompt + `isolation`, `flexion_tronc`, `hors_categorie` (voir D-L9-02) |
| `plan` | `sagittal` \| `frontal` \| `transversal` | plan principal du geste |
| `vue` | `profil` \| `face` | vue de la démonstration |
| `unilateral` | booléen | |
| `muscles_primaires`, `muscles_secondaires` | listes d'identifiants | vocabulaire normalisé de 24 muscles (`vocabulaires.muscles`) |
| `mode_charge` | énumération | `poids_de_corps`, `lest`, `barre`, `halteres`, `kettlebell`, `machine`, `poulie`, `elastique`, `assistance`, `objet_leste` |
| `mesure` | `repetitions` \| `temps` \| `distance` | |
| `difficulte` | entier 1–10 | calibré pour un adulte non entraîné au poids de corps ; pour un exercice chargé, cote la technicité et l'accessibilité |
| `prerequis` | liste `{id, seuil}` | seuil mesurable en texte (« 3 × 10 propres ») ; issu des arbres, sinon de la variante de base |
| `progressions`, `regressions` | listes d'id | arêtes des arbres (KT-045) |
| `contrainte_articulaire` | objet | 8 zones (`epaule`, `coude`, `poignet`, `rachis_lombaire`, `rachis_cervical`, `hanche`, `genou`, `cheville`), entiers 0–3 |
| `precautions` | liste d'identifiants | 19 consignes d'entraînement normalisées (`vocabulaires.precautions`), sans vocabulaire médical |
| `materiel` | liste d'identifiants | 36 entrées normalisées, chacune avec ses lieux compatibles |
| `lieux` | liste | intersection des lieux du matériel : `maison_sans_materiel`, `maison_equipee`, `parc_street_workout`, `salle` |
| `points_cles` | 3 chaînes | consignes |
| `erreurs_frequentes` | 2 chaînes | |
| `respiration` | chaîne | |
| `methodes` | liste | méthodes portées par la variante (tempo, pause, clusters, test_1rm…) |
| `substitutions` | objet lieu → liste d'id (≤ 3) | même type de mouvement, difficulté ±1, classées par écart puis muscles communs |
| `substitutions_elargies` | liste de lieux | lieux où l'on a dû élargir (écart 2, puis muscles communs à écart ≤ 3) |
| `pose` | `{gabarit, vue, reference}` | renvoi vers `poses.json#/exercices/<id>` |
| `variante_de` | id ou null | variante de charge ou de méthode d'un exercice de base |
| `doublon_de` | id ou null | doublon signalé ; le générateur utilise l'entrée canonique |
| `non_conformites` | liste de chaînes | défauts de la base v1, sans suppression |
| `v1` | `{nom, groupe, materiel}` ou null | données d'origine |
| `provenance` | objet champ → source | `kt_v1`, `genere_l9`, `calcule` ; la clé `*` donne la source par défaut |

## 3. Arbres de progression (`progressions.json`)

- `chaines[]` : `{id, titre, etapes[]}` ; chaque étape `{id, seuil_passage, suivant}`. `seuil_passage` = critère pour passer à l'étape suivante : `{series, repetitions | secondes | lest_pct_poids_de_corps, par_cote, texte}` ; `null` sur la dernière étape.
- `aretes[]` : `{de, vers, seuil, type}` avec `type = progression` (dans une chaîne) ou `prerequis_transverse` (ex. dips 3 × 10 avant les transitions de muscle-up). Une régression est une arête parcourue à l'envers.
- `entrees_debutant` : nœuds sans prédécesseur, tous de difficulté ≤ 2.
- 24 chaînes : pompes (mur → un bras), pompes lestées, pompes triceps, tractions (suspension → lestées), tractions vers un bras, dips (banc → lestés), squat (assisté → pistol), squat crevette, back squat, charnière (pont fessier → soulevé de terre roumain), gainage ventral, gainage creux, gainage latéral, muscle-up, front lever, back lever, planche, équilibre sur les mains, HSPU, L-sit, drapeau, mobilité épaules, hanches et chevilles.
- Invariants testés : pas de cycle (global), pas d'étape orpheline, tout nœud atteignable depuis une entrée débutant, difficulté non décroissante le long d'une chaîne, seuil présent sur chaque étape non finale.

## 4. Démonstrations par données de posture (`poses.json`)

### Squelette et repère
- 17 points : tête, cou, épaules, coudes, poignets (centre de la prise), bassin, hanches, genoux, chevilles, pointes de pied (côtés `_g` et `_d`).
- Unité = taille du personnage ; y vers le haut ; sol en y = 0 ; origine x sous le centre de masse de l'image clé 0 (masses segmentaires de Winter).
- Longueurs : tronc 0,300 ; épaule à 0,265 le long du tronc ; cou 0,095 ; bras 0,180 ; avant-bras + main 0,190 ; cuisse 0,245 ; jambe 0,245 ; pied 0,130 (profil) ou 0,045 (face) ; demi-largeurs d'épaules 0,120 et de bassin 0,085 en vue de face ; rayon de tête 0,062.

### Angles (source de vérité)
Chaque image clé stocke des angles **absolus** en degrés : `t` (tronc), `n` (cou), `p` (bassin, vue de face), et par côté `ua` (bras), `fa` (avant-bras), `th` (cuisse), `sh` (jambe), `ft` (pied). Segments « vers le bas » : 0 = vers le bas, +90 = vers +x. Tronc et cou : 0 = vers le haut, +90 = penché vers +x. Les positions `joints` sont fournies pour les tests et la version statique ; elles sont recalculées à l'identique par le moteur (écart < 0,002, test de parité).

### Structure
- `gabarits` : `{vue, boucle, images_cles[{label, angles, bassin, anchor{joint,pos}, hold, dur, joints}], accessoires, contacts, exceptions_amplitude, note}`. 200 gabarits utilisés.
- `exercices` : id → `{gabarit, accessoires (ajoutés : barre chargée, haltères, lest…), segments_accent}`.
- Accessoires paramétrés : barre fixe, barres parallèles, anneaux, banc, box, barre chargée, haltères, kettlebell, élastique, poulie, mur, sol, poteau, médecine-ball, sac lesté, traîneau, ergomètres, corde.

### Interpolation et chronologie (à reproduire en Flutter)
1. `v = (1 − cos(π·u)) / 2` (sinus entrée-sortie) sur chaque transition.
2. Interpolation linéaire des valeurs d'angle stockées, **sans repli modulo 360** (le sens de rotation est porté par les données).
3. Cinématique directe depuis le bassin.
4. Si les deux images partagent le même ancrage, translation pour garder l'articulation d'ancrage exactement sur sa position (mains sur la barre, pieds au sol) ; sinon le bassin est interpolé.
5. Image i tenue `hold` s puis transition `dur` s. Boucle `aller-retour` : 0 → … → n → … → 0 ; `cycle` : 0 → … → n → 0.
6. Réduction des animations : images clés côte à côte (`staticStrip`), sans mouvement.

### Couleurs par rôles (jamais de valeur fixe)
| Rôle | Usage | Sombre | Clair |
| --- | --- | --- | --- |
| `accent` | segments des muscles primaires | `KAccentSpec.bright` | `accentLight ?? principal` |
| `neutre_moyen` | corps | `#8A8A8A` | `#8A8A8A` |
| `neutre_contraste` | accessoires, sol | `#F4F4F4` | `#121212` |
| fond | | `#121212` | `#F4F4F4` |
Aplats uniquement ; les membres du côté éloigné (profil) sont dessinés à 55 % d'opacité. Les muscles sont toujours listés en texte à côté de l'animation.

### Contrôles automatiques
Longueurs constantes (tolérance 2 %) sur chaque image et pendant l'interpolation ; amplitudes articulaires dans des bornes (profil : épaule −95/195°, coude −5/160°, hanche −40/150°, genou −5/160°, cheville 5/135°, cou −50/60° ; face : bornes d'abduction) avec exceptions déclarées par gabarit pour les figures avancées ; contacts (pieds au sol, mains sur la barre, bassin sur le banc) à 0,02 près ; aucune articulation sous le sol.

## 5. Autres fichiers

- `mapping_v1_to_v2.json` : `base_v1` (505 noms → `{id, canonique}`) et `programme_v33` (79 intitulés → `{id, methodes, occurrences, correspondance}`).
- `coverage_report.md` : résultats des contrôles, matrice type × lieu × tranche de difficulté, manques, liste prioritaire des 150 exercices avec justification.
- `validation_register.md` : points à faire valider (seuils, contraintes, difficultés, non-conformités, doublons, limites des démonstrations, précautions).
- `licences.md` : sources et obligations.
- `review_tool.html` : outil de relecture autonome ; `renderer_reference/` : moteur de référence et page de démonstration (6 palettes × 2 modes).
- `tools/` : `build_pack.py`, `build_poses.py`, `kinematics.py`, `pose_templates.py`, `pose_checks.py`, `validate.py`, `build_html.py`, `build_register.py`, bases de connaissances `kb_*.py`, tests `tests/test_pack.py`.

## 6. Décisions prises par défaut

| Réf. | Décision | Réversible |
| --- | --- | --- |
| D-L9-01 | Aucune donnée externe importée : les licences n'ont pas pu être vérifiées depuis l'environnement (réseau limité aux registres de paquets). Tout l'enrichissement est généré et marqué `genere_l9`. | oui |
| D-L9-02 | Trois types ajoutés à la liste du prompt : `isolation` (curls, extensions, mollets…), `flexion_tronc` (crunchs, relevés de jambes) et `hors_categorie` (entrées non conformes). Sans eux, un curl serait compté comme tirage et fausserait la matrice du générateur. | oui |
| D-L9-03 | Doublons et non-conformités conservés avec `doublon_de` et `non_conformites` ; le générateur n'utilise que l'entrée canonique ; l'historique des séances reste lisible par l'ancien nom. | oui |
| D-L9-04 | Rôle « neutre moyen » = `#8A8A8A` (KPalette.gray) dans les deux modes : contraste suffisant sur les deux fonds et distinct des 6 accents. À ajouter comme rôle nommé dans `app_theme.dart` en L9b. | oui |
| D-L9-05 | Rachis modélisé par un segment rigide, vue unique par exercice (profil ou face) ; les gestes hors plan sont projetés. | oui |
| D-L9-06 | « Maison équipée » = matériel léger (barre de traction, élastiques, haltères, kettlebell, anneaux, banc, lest, box) ; barre olympique, rack, poulie, machines et ergomètres = salle uniquement. | oui |
| D-L9-07 | Tests (1RM, max) et variantes de méthode (clusters, singles, tempo) gardés comme entrées distinctes liées par `variante_de`, avec `methodes`. | oui |
| D-L9-08 | Paliers lestés exprimés en % du poids de corps (25 % tractions, 30 % dips, 20 % pompes) pour rester valables quel que soit le gabarit du pratiquant. | oui |
| D-L9-09 | Substitutions : si aucune candidate à ±1 dans un lieu, repli à ±2 puis « muscles primaires communs, écart ≤ 3 », signalé dans `substitutions_elargies` (13 exercices). | oui |
| D-L9-10 | 50 exercices ajoutés : étapes manquantes des arbres, mobilité, et comblement des manques « maison sans matériel ». | oui |

## 7. Résultats exacts des tests (première passe)

Commande : `KT_V1_DB=… KT_PROGRAMME=… python3 -m unittest discover -s tools/tests -v` (Python 3.11.15, Node 22).
- **25 tests, 25 réussis, 0 échec, 0 ignoré** (sans les variables d'environnement : 24 réussis, 1 ignoré — correspondance complète).
- `python3 tools/validate.py . --v1 … --programme …` : schéma OK, graphe OK, poses OK, interpolation OK, correspondances OK, prérequis OK, substitutions OK ; 79 cases de la matrice sous le seuil de 3 (listées, non bloquantes) ; 39 avertissements « difficulté ≥ 7 sans prérequis explicite ».
