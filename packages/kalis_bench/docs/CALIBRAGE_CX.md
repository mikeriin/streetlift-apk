# Calibrage du croisement street (lot CX)

Lot CX du pipeline « Calibrage des programmes » : `kalis_plan` 0.2 écrit le plan de saison et chaque bloc,
`kalis_adapt` 0.2 conduit chaque séance d'un athlète simulé, les résumés d'adaptation et les résultats de test
nourrissent le bloc suivant (saisons croisées, `lib/src/season.dart`). Le panel note les **saisons** : le
programme tel que les blocs successifs l'ont écrit (export concis), puis la saison simulée (décisions du
moteur, tests, jour de l'échéance ; modèle de vérité B, graine 0, saison de référence). Cible (C7.5) : 9 au
moins pour chaque école et chaque profil street, 0 violation de sécurité.

## Avant la première boucle

- Empreintes des cinq grilles : identiques à `docs/PANEL.md` (concaténation `7d337a2e…`).
- Dérive du panel (ancres `p06_a` et `p17_c`, un appel Opus par école) : variante (a) 1 / 1 / 1 / 1, variante
  (c) 9 / 9 / 9 / 8 → pas de dérive.

## Passe 0 (complète, 68 couples) — moteurs livrés (`kalis_plan` 0.2.0, `kalis_adapt` 0.2.0)

Contrôle `claude/ci-cp-a` run 37222464508 (banc des saisons, moteurs inchangés).

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 6 | 6 | 5,5 | 6,5 |
| `street_02_debutant_surpoids` | 8 | 7 | 7 | 8 |
| `street_03_debutante` | 4,5 | 5 | 4,5 | 5 |
| `street_04_reprise_longue_pause` | 8 | 7 | 7 | 8 |
| `street_05_inter_calisthenie_front_lever` | 7 | 6 | 7 | 7 |
| `street_06_inter_sets_reps` | 7 | 6,5 | 7,5 | 6,5 |
| `street_07_avance_streetlifting_competition` | 8 | 7 | 8 | 8 |
| `street_08_avance_sets_reps_competition` | 6,5 | 6,5 | 6,5 | 6 |
| `street_09_elite_streetlifting` | 7 | 6,5 | 7 | 6,5 |
| `street_10_elite_figures` | 6,5 | 6 | 6 | 6 |
| `street_11_master_51_ans` | 7,5 | 7 | 7,5 | 7,5 |
| `street_12_antecedent_coude` | 8 | 8 | 7,5 | 8 |
| `street_13_peu_de_temps` | 7,5 | 7 | 7 | 7 |
| `street_14_parc_sans_lest` | 7,5 | 7 | 7,5 | 7 |
| `street_15_travail_physique_sommeil_court` | 7 | 8 | 8 | 8 |
| `street_16_specialisation_traction_lestee` | 8 | 8 | 9 | 8 |
| `street_17_hybride_street_course` | 7 | 7 | 8 | 7 |

Couples à 9 ou plus : 1 sur 68 ; minimum 4,5 ; moyenne 7,01. Les saisons sont notées plus sévèrement que les
programmes seuls (CP1 : 66 sur 68) et que les trajectoires d'un seul cycle (CA1 : 34 sur 68) : elles
montrent ce que le moteur de création fait des résultats réels.

Corrections nécessaires de la passe 0, lues en entier (`cx-outils/notes/p0.json` sur la sauvegarde), par
famille et par nombre de couples concernés :

1. **Blocs écrits sur le repère attendu, pas sur le test** (presque tous les profils, toutes écoles) : séries de
   tête au-dessus du maximum mesuré (27 dips pour 22, 18 tractions pour 14, tenues de 9 s pour un maximum de
   7 s), 1RM déclarés jamais recalés vers le bas (dips +90 kg déclarés, environ +78 kg réels).
2. **Charge du coude** : tirage cinq jours sur cinq ou deux jours de suite (street_06, 07, 08, 09, 14, 17).
3. **Après l'échéance** : pas de transition, reprise à pleine charge la semaine suivante (street_07, 08, 09, 16).
4. **Figures** : critère de passage hors de portée (3 × 12 s pour un maximum de 12 à 13 s), étape actuelle
   retirée au profit de l'étape suivante (street_10), pas de dynamique ni de tirage de force (street_05).
5. **Débutants** : élastique jamais affiné, négatives à dose fixe, pompe sur les genoux trop facile ou simples
   de pompe classique, test de descente rendu en répétitions (street_01, 02, 03).
6. **Douleur** : poignet à 4 sur 10 plusieurs semaines, bloc suivant qui passe à une variante plus dure
   (street_04), partielles surchargées au-dessus du 1RM sur un coude à antécédent (street_09).
7. **Divers** : séries de volume de traction lestée trop faciles (street_16), règle « réductions déjà
   appliquées » contradictoire avec la baisse du jour (street_10).

## Boucle 1 (04/10/2026)

Corrections (moteurs du contrôle 43426224) : le dernier test mesuré fait foi, sans gain supposé après un test ;
estimations du résumé d'adaptation (6 séries au moins, erreur ≤ 6 %) qui abaissent un repère ; douleurs du
résumé lues comme des gênes ; semaine de transition après une épreuve principale ; tirage jamais deux jours de
suite ; partielles retirées les quatre dernières semaines et plafonnées à 95 % sur un coude à antécédent ;
négatives du débutant 3 × 4-5 de 5 s ; échelle de poussée écrite au contrat ; critère de passage des figures à
environ 75 % du maximum ; tenues 60-70 % / 75-85 % ; séries allégées −5 / −8 % ; trois séries lourdes en
intensification et réalisation ; hausse de volume 15 % ; catégorie de poids et format d'épreuve ; test du chemin
vers la traction en secondes ; lieu du jour (`feasibleAt`, kalis_core 0.4.2).

Recherche ciblée : `cx-outils/docs/recherche_boucle0.md` (règlement FinalRep, absence de règlement unifié en
sets & reps, isométrie ≥ 70 % pour les tendons, lien faible de la tenue menton avec la traction, affûtage).

Panel complet (68 couples, saisons du contrôle 43426224) :

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 6,5 | 7 | 6 | 7,5 |
| `street_02_debutant_surpoids` | 8 | 9 | 9 | 9 |
| `street_03_debutante` | 5,5 | 6 | 5,5 | 7 |
| `street_04_reprise_longue_pause` | 9 | 9 | 9 | 9 |
| `street_05_inter_calisthenie_front_lever` | 8 | 6 | 7 | 7 |
| `street_06_inter_sets_reps` | 8 | 9 | 8 | 9 |
| `street_07_avance_streetlifting_competition` | 9 | 7 | 9 | 9 |
| `street_08_avance_sets_reps_competition` | 9 | 7 | 8 | 8 |
| `street_09_elite_streetlifting` | 8 | 8 | 8 | 9 |
| `street_10_elite_figures` | 5,5 | 4 | 6,5 | 5 |
| `street_11_master_51_ans` | 8 | 8 | 8 | 8 |
| `street_12_antecedent_coude` | 9 | 9 | 9 | 9 |
| `street_13_peu_de_temps` | 8 | 7 | 8 | 7 |
| `street_14_parc_sans_lest` | 9 | 9 | 9 | 9 |
| `street_15_travail_physique_sommeil_court` | 7 | 8 | 8 | 8 |
| `street_16_specialisation_traction_lestee` | 8 | 8 | 7 | 8 |
| `street_17_hybride_street_course` | 7 | 7 | 8 | 9 |

Couples à 9 ou plus : 23 sur 68 (1 en passe 0) ; minimum 4 (4,5) ; moyenne 7,81 (7,01). `street_14` : 9 dans
les quatre écoles. Les blocs écrits sur le test ne sont plus relevés ; restent, par famille :

1. **Objectif non testé** (street_01, 03) : le test du chemin vers la traction (tenue menton) était retiré
   par le budget des tenues bras tendus, où la tenue bras fléchis était comptée à tort.
2. **Poussée du débutant** (street_02, 03) : la variante facile monte en séries d'endurance (13-17), la pompe
   au sol n'est pas pratiquée avant le troisième bloc.
3. **Figure retirée sur douleur** (street_10) : poignet à 4/10, la planche disparaît quatre semaines (la
   douleur relevée rejetait l'exercice) ; test final sur un exercice hors de l'échelle.
4. **Réalisation des répétitions** (street_06, 13, 15, 17) : semaines identiques, séries à 40-60 % du
   maximum, bloc spécifique plus léger que la construction.
5. **Lest sous le poids du corps** (street_11, 16) : séries de 2-3 tractions faciles à « 83 % » ; note « 1RM
   proche du poids du corps » erronée en semaine de transition.
6. **Divers** : test d'un mauvais jour qui fait tomber tout le bloc de figure (street_05), reprise après
   transition en une marche (street_08), partielles surchargées d'emblée (street_09), force dynamique du front
   lever (street_05).

Violations de sécurité de la saison réalisée (banc, 4 graines × 3 vérités × 8 scénarios) : `affutage_absent`
dans tous les tirages du scénario « échéance avancée » de street_07, 08 et 09 était un artefact de mesure (la
saison réalisée mettait bout à bout les blocs écrits, y compris les semaines non servies du bloc arrêté par le
changement de profil) : `servedBlocksOf` ne garde que les semaines servies.

## Boucle 2 (04/10/2026)

Corrections (contrôles fca6bf0 et 093f556) : tenue menton hors du budget des tenues bras tendus (plan et banc) —
le test du chemin vers la traction n'est plus retiré ; douleur relevée au bloc précédent : figure gardée à 60 %
des séries (`pain_trend`, Silbernagel et al. 2007) ; variante facile de l'échelle de poussée plafonnée à 8-12 ;
pompe au sol en séries courtes dès le deuxième bloc ; réalisation des échéances de répétitions à 65-75 % du
maximum, départs au chrono qui montent ; semaine de reprise à 75 % après la transition ; partielles d'entrée à
82,5 % sur un coude à antécédent ; lest sous le poids du corps : série au poids du corps d'après le maximum au
poids du corps ; note « 1RM proche du poids du corps » seulement à 78 % ; test plus bas recoupé par
l'estimation ; allègement à 65 % au plus ; descentes freinées de traction sous dix tractions. Recherche :
`cx-outils/docs/recherche_boucle2.md`.

Panel (couples sous 9 ou dont l'export a changé de plus de 10 % : 59 couples renotés ; street_04, street_14 et
street_17 santé gardés) :

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 7 | 8 | 7 | 7,5 |
| `street_02_debutant_surpoids` | 9 | 8 | 8 | 9 |
| `street_03_debutante` | 6,5 | 7 | 6,5 | 6,5 |
| `street_04_reprise_longue_pause` | 9 | 9 | 9 | 9 |
| `street_05_inter_calisthenie_front_lever` | 7 | 7 | 6,5 | 8 |
| `street_06_inter_sets_reps` | 8 | 8 | 9 | 8 |
| `street_07_avance_streetlifting_competition` | 9 | 8 | 8 | 8 |
| `street_08_avance_sets_reps_competition` | 6 | 6,5 | 5,5 | 8 |
| `street_09_elite_streetlifting` | 7,5 | 7 | 7 | 7,5 |
| `street_10_elite_figures` | 6 | 5,5 | 5 | 7 |
| `street_11_master_51_ans` | 7 | 8 | 8 | 7 |
| `street_12_antecedent_coude` | 9 | 8 | 8 | 8 |
| `street_13_peu_de_temps` | 6,5 | 7 | 9 | 9 |
| `street_14_parc_sans_lest` | 9 | 9 | 9 | 9 |
| `street_15_travail_physique_sommeil_court` | 9 | 9 | 8 | 9 |
| `street_16_specialisation_traction_lestee` | 9 | 8 | 8 | 9 |
| `street_17_hybride_street_course` | 9 | 7 | 7 | 9 |

22 couples sur 68 à 9 (23 à la boucle 1) ; minimum 5 (4) ; moyenne 7,80 (7,81). Gain sur le minimum, pas sur le
nombre. Ce que la lecture des corrections a montré :

1. **Bloc repassé au mode 0.1 après une proposition appliquée** (street_03, 08 et plusieurs scénarios) :
   `kalis_adapt` reconstruisait les semaines sans leur intention en appliquant un diff de prescriptions ; le bloc
   suivant était ensuite servi sans phase. Corrigé dans `kalis_adapt` 0.2.1 (`applyProposal`).
2. **Séries de travail encore écrites sur le repère attendu au test du bloc** (street_08, 11) : corrigé — le
   repère attendu ne vaut plus que pour la cible d'un test.
3. **Estimations sans record sur des exercices où elles ne mesurent pas un 1RM** (partielles surchargées de
   street_09 : « +52,5 kg ≈ 95 % » ; curl du poignet de street_12) : limitées aux mouvements de compétition
   lestés.
4. **Amorçage du muscle-up lesté écrit 2 × 8** (street_09) : la série au poids du corps ouvrait les répétitions
   d'un simple ; corrigé.
5. **Débutants** : tenue menton à 46 % du maintien (plafond de 15 s), test de traction placé après la série
   maximale de pompes, négatives de pompe retirées au deuxième bloc, traction stricte jamais essayée avant le
   test ; corrigés (plafond 25 s, test de l'objectif d'abord, négatives gardées, essais stricts dès la sixième
   semaine dans la règle de l'élastique).
6. **Restent** : volume de street_08 au premier bloc (densité de dips), figures de street_05 et 10 (progression
   des tenues, force dynamique, charge des poignets), affûtage de street_09 en une marche.
