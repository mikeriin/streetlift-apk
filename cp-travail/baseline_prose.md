# Mesure de départ — moteurs 0.1 (lot CR)

État du 03/10/2026. Moteurs mesurés : `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0, sur `kalis_core` 0.4.0 (catalogue 1.1.0). Banc : `kalis_bench` 0.1.0, mode `croisement`, graine 0, 27 profils types (17 street, 10 autres disciplines, `docs/PROFILS.md`).

Ce document est la feuille de route des lots CP1, CA1, CP2 et CA2 : il dit où en sont les moteurs avant tout calibrage, et dans quel ordre corriger.

## 1. Ce qui a été mesuré, et comment

1. **Critères calculables** (`docs/CRITERES.md`) : sécurité (toute violation compte, la cible est zéro), qualité (0 à 1), attentes de coach propres à chaque profil, trajectoires simulées avec `kalis_adapt`. Chiffres tirés du rapport du contrôle automatique (`ci-out/packages/kalis_bench/rapport.json` sur `claude/ci-cp-a`), reproductibles par `dart run bin/run.dart`.
2. **Panel** (`docs/PANEL.md`) : une passe complète, quatre écoles × 27 profils, soit 108 notes d'ensemble. Chaque relecteur reçoit le profil, le programme créé et le résumé de la trajectoire simulée, avec la grille gelée de son école et le référentiel ; il ne voit ni le code, ni les autres notes, ni les programmes de référence. L'étalonnage (`docs/ETALONNAGE_PANEL.md`) borne la lecture des notes : un écart d'un point entre deux passes n'est pas significatif.

Limites de la mesure : §6.

## 2. Synthèse

- **Panel.** {{SYN}} Le seuil du calibrage est 9/10 pour chaque école et chaque profil : l'écart à combler est de 2 à 6 points selon les profils.
- **Sécurité.** {{TOTAL_SAFE}} violations sur les programmes créés ({{TOTAL_REAL}} sur les programmes après adaptation simulée). {{NZERO}} profils sur 27 sans violation : {{ZERO}}.
- **Attentes de coach.** {{ATT}}.
- **Trajectoires.** {{TRAJ}} Avec une échéance, la performance simulée le jour J reste sous le meilleur niveau antérieur pour quatre profils sur cinq testés.

Les moteurs 0.1 produisent des programmes structurés, équilibrés entre poussée et tirage, faisables dans le temps donné pour la plupart, et prudents sur l'effort. Ils ne tiennent pas compte de l'échéance, sous-dosent l'intensité des pratiquants avancés, travaillent trop peu les mouvements visés, ne savent pas faire progresser un débutant vers sa première traction ni un pratiquant vers une figure, et ne modélisent presque pas la course.

## 3. Panel : notes d'ensemble, école × profil

{{T_PANEL}}

### Notes par critère (moyenne sur les programmes où le critère s'applique)

{{T_CRIT}}

Les critères les plus bas donnent l'ordre des chantiers : affûtage, pic et tests (F5, S8), progression et critères de passage des figures (C6), endurance de force et cardio (S4), périodisation (F4), intensité (F2), choix des paliers (C1), préparation articulaire (C7), spécificité (F1). Les plus hauts sont ceux que les moteurs 0.1 tiennent déjà : repos et durée (H7), effort prudent (S6), adhésion (S7), fréquence par muscle (H2), gestion de la fatigue (H8).

Les {{NB_CORR}} corrections jugées nécessaires, profil par profil et école par école, sont dans `docs/baseline/CORRECTIONS_PANEL_0_1.md`.

## 4. Critères calculables

### 4.1 Sécurité (cible : zéro)

{{T_SAFE}}

Lecture :

- **Volume au-dessus du plafond du niveau** (deux tiers des violations) : le moteur additionne trop de séries sur les mêmes muscles, surtout grand dorsal, fessiers, triceps, quadriceps et pectoraux, et jusqu'à 19 dépassements pour l'élite figures. Les plafonds personnels attendus par un coach (51 ans, reprise, travail physique, antécédent du coude) sont dépassés de 13 à 68 % (§4.2).
- **Volume trop vite** : hausses au-delà de la borne du niveau, le plus souvent en semaines 7, 8 et 12 ; la plupart des dépassements sont faibles (0,1 à 2 séries).
- **Bras tendus trop vite** et **technique sans prérequis** : maintiens en bras tendus allongés de 3 à 5 secondes de trop au changement de bloc ; isométries lestées et dips partiels surchargés servis à des intermédiaires, dont le profil à l'antécédent du coude.
- **Pas d'allègement avant l'échéance** : cinq des sept profils à échéance arrivent au jour J sans baisse de volume.
- **Séance trop longue** : les séances de course dépassent le temps donné.
- Après adaptation simulée, le total passe de {{TOTAL_SAFE}} à {{TOTAL_REAL}} : `kalis_adapt` 0.1.0 ajoute surtout des hausses de charge trop rapides en musculation (+5,3 % pour 5 % admis, par pas de disques) et des hausses de volume chez les débutants street.

### 4.2 Qualité et attentes de coach

{{T_ATT}}

La qualité moyenne masque les trous : la spécificité (part du travail sur les mouvements visés) vaut 0,09 pour la spécialisation traction lestée, 0,26 pour la compétition sets & reps, 0,41 pour le powerlifting et 0 en course ; la progression planifiée vaut 0,50 pour presque tous les profils street sans lest (aucune progression lisible d'une semaine à l'autre) ; l'affûtage aligné vaut 0,33 pour quatre profils à échéance. Détail par critère : `RAPPORT.md` du contrôle, §1.

### 4.3 Trajectoires simulées (`kalis_adapt` 0.1.0)

{{T_TRAJ}}

Lecture :

- **Écart au RIR visé** : aucun profil à cibles mesurables ne tient le repère (le 10 km n'a aucune cible mesurable). Les charges et répétitions proposées laissent en moyenne deux répétitions de marge de plus que prévu ; l'adaptation ne rattrape pas l'écart, faute de recalculer la cible après chaque séance.
- **Cibles atteignables** : pour les débutants street et l'élite figures, 30 à 45 % des prescriptions sont hors de portée de l'athlète simulé (exercice trop dur ou plage de répétitions impossible).
- **Gain réel** : 0,02 à 0,05 % par semaine pour les avancés et l'élite sous charge, c'est-à-dire une progression nulle sur le cycle.
- **Performance à l'échéance** : 86 à 97 % du meilleur niveau antérieur pour quatre des cinq profils testés ; la préparation n'amène pas l'athlète à son pic.
- **Course, mobilité, conditionnement** : `kalis_adapt` 0.1.0 ne modélise pas ces séances (aucune cible atteignable pour le 10 km, aucun gain mesurable).
- Aucun déblocage de niveau d'adaptation non respecté, aucune aggravation de douleur simulée, très peu d'échecs non voulus.

### 4.4 Non-ressemblance

- **Programme personnel du propriétaire** : critère `non_ressemblance_proprietaire` à 1,00 pour les 27 profils (indice de Jaccard « exercice × schéma » sous 0,30 partout).
- **Programmes de référence privés** : calculée dans la session du lot, avec la clé, par `tool/reference_jaccard.py`, sur les références relues dans cette session (cinq documents sur six, dont un en partie ; voir `pipeline/cp/DECISIONS_CP.md`, CR). Plus fort indice entre une semaine générée et une semaine de référence : **0,014** en lecture exacte, **0,222** en lecture tolérante (même famille d'exercice, même nombre de séries, répétitions de la référence dans la plage générée). Les deux sont sous le seuil de 0,30 pour chaque profil.

{{T_JAC}}

## 5. Défauts, par ordre de priorité

Chaque défaut cite sa mesure. Lots : **CP1** = `kalis_plan` street ; **CA1** = `kalis_adapt` street ; **CP2** et **CA2** = autres disciplines. Dans un lot, traiter dans l'ordre.

### 5.1 Street — création du programme (CP1)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **L'échéance est ignorée.** Pas d'affûtage, pas de pic, pas de simulation ni d'épreuve le jour J ; le dernier bloc repart d'une introduction ; tests posés au milieu ou étalés sur trois jours ; semaines de test presque vides. | F5 moyenne 3,0 (la plus basse de tous les critères) ; S8 3,5 ; `affutage_absent` × 5 ; attentes « volume réduit » et « épreuve la semaine de l'échéance » non tenues | street 07, 08, 09, 16 ; tous les profils à tests |
| 2 | **Intensité sous-dosée et charges mal calculées chez les avancés.** Charges plafonnées vers 77 à 81 % ; aucune exposition lourde régulière, ni série haute suivie de séries allégées ; pourcentage affiché différent de la charge prescrite ; pourcentages appliqués au lest au lieu de la charge totale (corps + lest) ; mentions « à déterminer » ou « voir les séries ». | F2 4,7 ; attentes « exposition lourde par semaine » non tenues (0,1 à 1,3 par semaine) ; gain simulé 0,02 à 0,05 %/sem | street 07, 09, 16 |
| 3 | **Spécificité insuffisante.** Le mouvement visé est absent ou travaillé une fois par semaine ; le volume se disperse sur des variantes ; le muscle-up lesté de compétition n'est jamais chargé ; 4 % des séries dures sur la traction lestée quand elle est la priorité. | F1 5,0 ; qualité `specificite` 0,09 à 0,76 ; 15 attentes de fréquence non tenues | street 05 à 09, 14, 16, 17 |
| 4 | **Blocs identiques, pas de progression écrite.** Deux blocs qui se répètent, aucune règle de progression d'une semaine à l'autre, aucune ondulation. | F4 4,5 ; H5 5,0 ; qualité `progression_planifiee` 0,50 pour 10 profils street | tous |
| 5 | **Débutants : pas de chemin vers la première traction.** Aucun travail adapté (négatives, assistance, tirage australien) ou une fois par semaine ; pompes prescrites à 1 ou 2 répétitions avec 4 de marge ; tests de traction pour qui n'en fait aucune ; jambes une fois par semaine. | Attentes « traction adaptée deux fois par semaine » non tenues (0 et 1) ; 31 à 44 % de cibles hors de portée ; C1 4,9 | street 01, 02, 03 |
| 6 | **Figures : pas de progression par paliers.** Paliers hors de portée ou sans rapport avec le niveau, aucun critère de passage, maintiens allongés trop vite, pas de préparation des poignets et des épaules. | C6 4,1 ; C7 4,9 ; `tendon_figures` × 6 ; 38 % de cibles hors de portée pour l'élite figures | street 05, 10, 11 |
| 7 | **Volume par muscle au-dessus des plafonds**, et plafonds personnels non appliqués (âge, reprise, travail physique, sommeil court, antécédent). | `plafond_volume` × 77, `volume_trop_vite` × 16 ; attentes de plafond non tenues (grand dorsal 20 à 24 séries pour 12 à 18 permises) | street 04, 05, 09, 10, 11, 12, 14, 15 |
| 8 | **Sets & reps : aucune méthode d'endurance de force.** Ni EMOM, ni AMRAP, ni tours, ni séries dégressives ; fréquence des mouvements de l'épreuve deux fois trop basse. | S4 4,2 ; attentes « format de densité » non tenues ; qualité `specificite` 0,26 | street 06, 08 |
| 9 | **Données du profil ignorées.** Exercices à forte contrainte sur le coude malgré l'antécédent ; technique avancée sans prérequis ; hausse de volume de 40 % en deuxième semaine de reprise (relevée par le panel) ; rien pour le sommeil court ni le métier physique ; parc sans lest : aucune variante dure ; créneau court : pas de supersets. | `technique_sans_prerequis` × 3 ; attentes non tenues des profils 04, 12, 13, 14, 15 ; F8 5,4 | street 04, 11 à 15 |
| 10 | **Exercices inadaptés et consignes absentes.** Variantes au-dessus du niveau (pompes en équilibre libre, archer en séries longues, ischios nordiques à 10–15 répétitions, muscle-up lesté sans muscle-up) ; pas d'échauffement écrit, pas de règle en cas de douleur, série à l'échec sous lest en semaine de test. | S9 5,2 ; H4 5,7 ; corrections nécessaires du panel | plusieurs |

### 5.2 Street — adaptation (CA1)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **L'écart au RIR visé n'est pas rattrapé.** Deux répétitions de marge en trop en moyenne, sans correction de la charge ou des répétitions à la séance suivante. | Écart 1,4 à 2,8 ; repère non tenu pour les 17 profils street | tous |
| 2 | **Pas de pilotage vers l'échéance.** Ni affûtage, ni tests, ni choix des tentatives ; performance simulée sous le meilleur niveau antérieur. | Performance à l'échéance 86 à 94 % (street 07, 08, 09) | street 07, 08, 09, 16 |
| 3 | **Progression nulle des avancés.** Les hausses de charge proposées sont trop rares pour produire un gain. | Gain 0,02 à 0,05 %/sem | street 07, 08, 09, 10, 16 |
| 4 | **Cibles hors de portée non corrigées.** L'adaptation ne remplace pas l'exercice ni la plage quand l'athlète ne peut pas la tenir. | Cibles atteignables 56 à 79 % | street 01 à 05, 08 à 11, 14 |
| 5 | **L'adaptation ajoute des violations.** Hausses de volume au-dessus des bornes après les semaines allégées, maintiens en bras tendus allongés trop vite. | Violations du programme évolué supérieures à celles du programme créé pour 10 profils street | street 01 à 07, 12, 13, 15 |
| 6 | **Peu de propositions.** Les niveaux d'adaptation se débloquent, mais aucune proposition (volume, décharge, remplacement) n'est appliquée pour 13 profils street sur 17. | `proposalsApplied` du rapport | tous sauf street 07, 09, 11, 16 |

### 5.3 Autres disciplines — création (CP2)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **Course non modélisée.** Pas d'allures, tests de 10 ou 21 km au milieu du plan, pas de progression du volume ni de sortie longue construite, pas d'affûtage, séances plus longues que le créneau. | Notes 3,0 à 4,5 ; qualité `specificite` 0 ; `seance_trop_longue` × 5 ; `affutage_absent` × 2 | autres 05, 06 ; street 17 |
| 2 | **Powerlifting : pas de pic.** Développé couché une fois par semaine, aucune exposition lourde, pas d'affûtage ni d'épreuve le jour J. | Notes 3,0 à 4,5 ; 4 attentes sur 7 non tenues | autres 03 |
| 3 | **Force générale et CrossFit : intensité et structure.** Charges trop basses pour un objectif de force, volume au-dessus des plafonds, hausses de charge de 5,3 % pour 5 % admis. | `charge_trop_vite` × 5 ; `plafond_volume` × 5 ; force 3,5 pour autres 04 | autres 02, 04, 08 |
| 4 | **Priorité musculaire ignorée en hypertrophie.** Le groupe à développer ne reçoit pas plus de travail que les autres. | Qualité `points_faibles` 0,50 | autres 02 |
| 5 | **Santé, perte de poids, senior : contraintes mal lues.** Course et déplacements latéraux malgré la consigne sans impact, pas de travail d'équilibre pour le senior, squat ou presse une fois par semaine pour le débutant. | Attentes non tenues d'autres 01 et 09 ; corrections du panel pour autres 07 et 10 | autres 01, 07, 09, 10 |

### 5.4 Autres disciplines — adaptation (CA2)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **Cardio, conditionnement et mobilité non modélisés** : aucune cible, aucun retour exploité. | Cibles atteignables 0 % pour autres 05 ; aucun gain mesurable | autres 05, 06, 07, 08 |
| 2 | **Hausses de charge trop rapides en musculation** après adaptation. | `charge_trop_vite` : 5 à 11 violations sur le programme évolué | autres 02, 04, 08 |
| 3 | **Écart au RIR visé**, comme en street, jusqu'à 3,6 répétitions pour le senior. | Repère non tenu pour 9 profils sur 10 | tous |

## 6. Limites de cette mesure

- **Une seule passe du panel.** L'incertitude d'une note est d'environ un point (répétabilité mesurée à l'étalonnage : écart maximal 1, moyen 0,25). Les notes de 3 à 7 sont très loin du seuil ; le classement fin entre profils voisins n'est pas significatif.
- **Le relecteur note le programme et le résumé de la trajectoire ensemble.** La note d'ensemble mêle donc `kalis_plan` et `kalis_adapt`. Les lots CP1 et CA1 devront séparer les deux lectures quand ils calibrent l'un sans l'autre.
- **Athlète simulé.** Les trajectoires viennent d'un modèle d'athlète déterministe (`docs/CRITERES.md`) : il mesure la cohérence de l'adaptation, pas ce que ferait une personne réelle.
- **Bornes de sécurité.** Elles viennent du référentiel (`docs/REFERENTIEL.md`) et de `kalis_core` (profil v3) ; là où les deux diffèrent, la borne retenue et sa raison sont dans `pipeline/cp/DECISIONS_CP.md` (CR).
- **Plafond de l'échelle.** À l'étalonnage, les meilleurs programmes écrits à la main ont obtenu 9 de chaque école, jamais 10 : atteindre 9 est possible, mais le panel trouve toujours une amélioration.
- **Relecture du propriétaire.** La page « Relecture Kalis Track » (manche 0) recueille ses notes sur dix de ces programmes ; elles serviront à recaler le panel avant CP1 si elles s'en écartent.
