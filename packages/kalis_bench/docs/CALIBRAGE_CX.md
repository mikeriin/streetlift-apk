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

## Relecture indépendante du code (04/10/2026)

Un relecteur (sous-agent Opus, sans SDK, diff complet du lot et arbre de travail) : aucun constat bloquant
(compilation, additivité, identité du chemin 0.1, exception). Douze constats, traités ainsi :

1. `applyProposal` ne gardait le contrat 0.4.0 que sur l'intention de bloc : il lit maintenant `blockCoached`
   (intention de semaine, échelles, groupes, stress… comptent aussi).
2. Les douleurs passées par une restructuration devenaient des « douleurs relevées » (figure gardée) :
   `Athlete.read` sépare `extraPains` (restructuration, admission habituelle) et `trendPains` (résumé
   d'adaptation) ; la restructuration lit aussi les estimations et les douleurs du résumé.
3. Le CHANGELOG du banc disait les critères de sécurité inchangés : il dit maintenant la précision de
   `tendon_figures` (tenue menton hors des tenues bras tendus).
4. Échéance avancée : les objectifs datés du même jour avancent aussi dans le profil du banc.
5. Trois commentaires de documentation déplacés (`SimRun`, `coachEligible`, `blockReasonsOf`).
6. Tests : le test des séries fractionnées est renommé (il vérifie la forme des séries fractionnées, pas la
   capacité du jour) ; le test des saisons vérifie que le changement avance bien l'échéance de 14 jours ; le
   titre du test de campagne ne promet plus la saison réalisée.
7. Estimation d'un 1RM : jamais un lest négatif (garde `external > 0`).
8. Test plus bas recoupé par l'estimation : seulement une estimation sûre (erreur ≤ 6 %) et récente (quinze
   jours au plus avant le test) ; un 1RM testé plus bas fait foi (dit dans le commentaire).
9. « Pas de traction deux jours de suite » nuancé dans le CHANGELOG et le CONTRAT de `kalis_plan` (autant que
   les jours le permettent).
10. Commentaires devenus faux corrigés (`_maxOf`, descentes freinées, `seasonTargetWeeks`, `_stat`) ;
    `undoneOf` exempte aussi un bloc qui commence par une semaine de transition.
11. Docs de `kalis_adapt` : la simulation sans changement suit 0.2.0, sauf les blocs au contrat 0.4.0 après
    une proposition appliquée ; conditions où `ProfileChange` ne reconstruit pas le bloc dites.
12. Coût du rapport CI (100 graines par défaut) : gardé, LANCEMENTS.md CX demande au moins 100 graines par
    modèle de vérité ; les essais rapides passent par `season_seeds.txt`.

## Boucles 3 et 4 (04-05/10/2026)

Boucle 3 (contrôle 19129a8) : intentions gardées après une proposition appliquée (`kalis_adapt`), séries de
travail sur le dernier repère mesuré, tenue menton à 60-70 % du maintien (jusqu'à 25 s), test de l'objectif
en tête de séance, négatives de pompe gardées, essais stricts de traction dès la sixième semaine, 1RM estimés
sans record limités aux mouvements de compétition, amorçage sans répétitions ajoutées. Les exports ont peu
changé (0 à 16 % des lignes) : pas de passe du panel sur cette boucle.

Boucle 4 (contrôles e3e0e31 et 4e3842b) : deuxième figure sur d'autres jours que la première, tirage bras
tendus les jours de force quand le front lever est visé, semaine d'introduction à 80 % chez l'avancé et
l'élite (restreinte ensuite aux échéances de répétitions : un test de propriétés de `kalis_plan` a montré un
test de squat au-dessus de la montée admise), corrections de la relecture indépendante.

Panel (41 couples renotés : ceux sous 9 dont l'export a changé, et ceux à 9 dont l'export a changé de plus
de 10 % ; les autres gardent leur note) :

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 8 | 9 | 7 | 8 |
| `street_02_debutant_surpoids` | 9 | 8 | 8 | 9 |
| `street_03_debutante` | 6,5 | 6,5 | 6,5 | 6,5 |
| `street_04_reprise_longue_pause` | 9 | 9 | 9 | 9 |
| `street_05_inter_calisthenie_front_lever` | 7 | 6,5 | 7 | 8 |
| `street_06_inter_sets_reps` | 9 | 9 | 9 | 8 |
| `street_07_avance_streetlifting_competition` | 9 | 8 | 9 | 9 |
| `street_08_avance_sets_reps_competition` | 8 | 5 | 7 | 7 |
| `street_09_elite_streetlifting` | 9 | 8 | 8 | 8 |
| `street_10_elite_figures` | 7 | 7 | 5,5 | 7,5 |
| `street_11_master_51_ans` | 7 | 8 | 7 | 7 |
| `street_12_antecedent_coude` | 9 | 8 | 8 | 9 |
| `street_13_peu_de_temps` | 6,5 | 7 | 9 | 9 |
| `street_14_parc_sans_lest` | 9 | 9 | 9 | 9 |
| `street_15_travail_physique_sommeil_court` | 9 | 9 | 8 | 9 |
| `street_16_specialisation_traction_lestee` | 9 | 9 | 9 | 9 |
| `street_17_hybride_street_course` | 9 | 7 | 7 | 9 |

31 couples sur 68 à 9 (22 à la boucle 2) ; minimum 5 (5) ; moyenne 8,04 (7,80). `street_16` passe à 9 dans
les quatre écoles. Restent, par famille : poussée de street_03 (critère de passage « 3 × 10 » pour deux séries
écrites, une ou deux pompes au sol par séance, deux règles d'élastique) ; « traction lestée » au poids du
corps à 6-7 répétitions de réserve (street_11) ; planche encore écartée de S9 à S15 (street_10 : la douleur
fait écarter l'exercice par le moteur d'évolution, ce qui passait outre `pain_trend`) ; montée de volume du
premier bloc de street_08 ; plateau de répétitions sans changement de stimulus (street_11, 13).

## Boucle 5 (05/10/2026)

Contrôles 5605ba5, fb02992 et 589ceae (tests verts ; seul le contrôle de formatage du mode dev est rouge, comme à
chaque contrôle dev). Corrections : 1RM de travail relevé d'après le maximum au poids du corps (traction et dips
lestés) ; figure écartée par le moteur d'évolution pour une douleur qui dure gardée au bloc suivant avec
`pain_trend` (planche de street_10, écartée de S9 à S15 à la boucle 4) ; une seule règle d'élastique ; critère
de l'échelle de poussée sur deux séries ; pompe au sol en grappes ; introduction des séries de volume ; marge de
6 % avant qu'une estimation abaisse un 1RM. Deux essais retirés après un test de propriétés de `kalis_plan`
(profil 3770 : montée de la charge de squat en semaine de test) : figures sur d'autres jours que la force,
introduction restreinte.

Panel (couples renotés selon la règle d'économie) : 32 couples sur 68 à 9 ; minimum 5 ; moyenne 8,06.

## Passe finale (complète, 68 couples) — moteurs livrés (`kalis_plan` 0.2.1, `kalis_adapt` 0.2.1)

Exports du contrôle 589ceae (code identique au contrôle complet fac8af5, 100 graines). Les 68 couples renotés
par un appel neuf ; `street_16` × force, seul couple sous 9 d'un profil à 9 ailleurs, renoté une fois (C7.9.4) :
8 puis 9, la dernière notation fait foi.

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 8 | 9 | 8 | 9 |
| `street_02_debutant_surpoids` | 9 | 8 | 8 | 9 |
| `street_03_debutante` | 7 | 7 | 7 | 8 |
| `street_04_reprise_longue_pause` | 9 | 9 | 9 | 9 |
| `street_05_inter_calisthenie_front_lever` | 7 | 7 | 7 | 8 |
| `street_06_inter_sets_reps` | 8 | 9 | 7,5 | 9 |
| `street_07_avance_streetlifting_competition` | 9 | 8 | 9 | 8 |
| `street_08_avance_sets_reps_competition` | 5 | 8 | 6,5 | 7 |
| `street_09_elite_streetlifting` | 8 | 9 | 9 | 8 |
| `street_10_elite_figures` | 6 | 4,5 | 4 | 7 |
| `street_11_master_51_ans` | 8 | 8 | 7 | 7 |
| `street_12_antecedent_coude` | 8 | 8 | 8 | 8 |
| `street_13_peu_de_temps` | 8 | 9 | 8 | 8 |
| `street_14_parc_sans_lest` | 8 | 8 | 8 | 8 |
| `street_15_travail_physique_sommeil_court` | 9 | 9 | 9 | 9 |
| `street_16_specialisation_traction_lestee` | 9 | 9 | 9 | 9 |
| `street_17_hybride_street_course` | 8 | 9 | 8 | 9 |

25 couples sur 68 à 9 ; minimum 4 ; moyenne 8,01. À 9 dans les quatre écoles : `street_04`, `street_15`,
`street_16`. La passe finale est plus sévère que la boucle 5 sur des exports identiques ou presque (32 → 25
couples à 9 ; `street_14` passe de 9 à 8 dans les quatre écoles sur un export inchangé depuis la boucle 5) : c'est l'incertitude d'un point du panel
(`docs/PANEL.md`), et la dernière notation fait foi. Cible C7.5 non atteinte ; C7.7 non atteinte (`street_08` :
5 à 8 ; `street_14` : 8 partout).

Corrections nécessaires de la passe finale, par famille (`cx-outils/notes/pf_toutes.json` sur la sauvegarde) :

1. **Figures de l'élite (street_10, 4 à 7)** : tenues réglées trop près du maximum sur des leviers trop durs,
   pas d'outil de surcharge du front lever, et surtout **gêne de poignet à 4/10 pendant plus de deux semaines
   sans que la règle d'arrêt et de consultation écrite dans le programme s'applique** : `pain_trend` garde la
   figure avec −40 % de volume, ce que la règle écrite (« gêne qui dure deux semaines : arrête le mouvement et
   consulte ») contredit. Le banc ne compte pas ce cas (aucune hausse sur la zone douloureuse) ; deux écoles
   plafonnent la note à 5 pour risque sur la santé. Constat de sécurité ouvert, non corrigé dans CX.
2. **Montée de volume du premier bloc de street_08 (5 à 8)** : environ +35 % de dips d'une semaine à l'autre,
   tests juste après le pic, remontée de charge brutale après l'échéance.
3. **Poussée de street_03 (7 à 8)** : la pompe au sol en pratique dès le bloc 2 reste à 1 à 3 répétitions ;
   critères de passage de l'échelle contradictoires ; tirage trop chargé pour une débutante.
4. **Front lever de street_05 (7 à 8)** : tenues qui ne montent pas vers le critère, tirage de force bras tendus
   absent (le tirage bras tendus ajouté les jours de force n'apparaît pas pour ce profil).
5. **Plateau sans changement de stimulus** (street_11, 13) et format spécifique du bloc de réalisation.

## Relecture documentée (manche 3, 05/10/2026)

Trois relecteurs (Opus) sur sept saisons, sources publiques en ligne, consigne `cx-outils/relecture/CONSIGNE.md` ;
notes écrites sur la page de relecture (manche 3, auteur « relecture-documentee »). Sans seuil (C7.6).

| Profil | Ensemble | Adapté | Progression | Volume | Exercices | Faisable |
| --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 6,5 | 7 | 5,5 | 6 | 7,5 | 8,5 |
| `street_06_inter_sets_reps` | 6 | 6,5 | 5 | 6 | 6,5 | 8 |
| `street_14_parc_sans_lest` | 6 | 6 | 5 | 6 | 5,5 | 9 |
| `street_07_avance_streetlifting_competition` | 7 | 7,5 | 6,5 | 7 | 7,5 | 8 |
| `street_08_avance_sets_reps_competition` | 6 | 6,5 | 5,5 | 5 | 6,5 | 7,5 |
| `street_10_elite_figures` | 5 | 6 | 4 | 4,5 | 5,5 | 7 |
| `street_12_antecedent_coude` | 6 | 7 | 5 | 6,5 | 7 | 7,5 |

Moyenne 6,1 ; minimum 5 (street_10). Une source n'a pu être ouverte (fiche MSD Manual sur l'épicondylite
médiale, vue seulement dans les résultats de recherche). Traitement, remarque par remarque :

- **Test en semaine d'allègement ou juste après un pic, bloc suivant réécrit à la baisse** (street_06, 08, 10,
  14) : CX recoupe désormais un test bas avec l'estimation récente (marge 6 %) et garde le repère quand le
  journal le contredit ; le placement du test (jours légers avant, test seul) reste à faire → CP2.
- **Séries assistées trop faciles, poussée figée, pas de test final en fin de saison** (street_01) : échelle de
  poussée et choix de l'élastique sur la série repère faits dans CX ; la pompe au sol reste dosée trop bas et
  la saison de 16 semaines finit sur un bloc de construction quand l'objectif n'est pas atteint → CP2.
- **Travail spécifique à l'objectif de répétitions, variantes dures au parc, muscle-up figé** (street_06, 14) :
  part spécifique portée à 65-75 % en intensification et réalisation ; variantes dures (archer, typewriter,
  tempo) et figures du profil parc → CP2.
- **Simples lourds de muscle-up, palier entre 65 et 85 %, jeudi trop dense** (street_07) → CP2.
- **Volume de street_08, format de l'épreuve, muscle-up chargé** : même constat que le panel → CP2.
- **Figures de street_10** : même constat que le panel (volume isométrique, changement de variable après un
  test en baisse, renforcement du poignet) → CP2, en tête.
- **Pourcentages des dips lestés de street_12 recalés sur le test, objectif ramené à +2,5 à +5 kg, scénario
  douleur 5/10** : recalage sur le test fait dans CX pour les séries de tête ; l'ouverture et l'objectif →
  CP2 ; la conduite sous douleur (dips allégés plutôt qu'un changement d'objectif) → CA2.

## Non-ressemblance (programmes finaux)

`tool/reference_jaccard.py` sur les 17 saisons écrites finales : maximum exact 0,150, tolérant 0,214 (seuil
0,30). Le détail reste chiffré (`analyse_CX.tar.gpg` sur `cp-references`).

## Arrêt du calibrage

Cinq boucles sur dix (C7.2). La règle « deux boucles de suite sans gain » n'est pas remplie (gains de 0,02 à
0,24 point de moyenne par boucle). J'ai arrêté après la boucle 5 pour le temps et le budget du lot : chaque
boucle coûte un contrôle de 50 minutes et une passe partielle du panel, et les corrections restantes sont
profondes (dosage des figures de l'élite et conduite d'une douleur qui dure, montée de volume de street_08,
poussée de la débutante, plateau sans changement de stimulus).

## Correction 1 (05/10/2026) — `kalis_plan` 0.2.2, `kalis_adapt` 0.2.2, `kalis_bench` 0.2.1

Passe « CX correction 1 » (LANCEMENTS.md) : relecture du pilotage de CX (notes 4 à 7) et panel final de CX
(25 couples sur 68 à 9, minimum 4). Mesure avant : passe finale de CX (mêmes moteurs, 0.2.1).

### Recherche ciblée (sources vérifiées, sous-agent Opus)

| Règle | Valeur retenue | Verdict | Sources |
| --- | --- | --- | --- |
| Douleur qui dure : arrêt des mouvements qui provoquent la zone, consulter | 3/10 pendant 2 semaines, 5/10 plus d'une semaine, ou retour dans les 12 semaines après un épisode réel | partiellement soutenu : 3/10 = seuil du coude (Coombes 2015), plus prudent que le modèle de Silbernagel (5/10 si calmé le lendemain) ; 2 semaines = délai NHS avant de consulter ; 5/10 et 12 semaines : choix prudents | Coombes, Bisset, Vicenzino 2015, JOSPT 45(11) ; Silbernagel et al. 2007, AJSM 35(6) ; NHS « Tennis elbow » |
| Reprise graduée après l'arrêt | après 2 semaines à 2/10 au plus ; 50 % du volume, +10 %/semaine, 3 en réserve au moins | partiellement soutenu : reprise graduée guidée par la douleur (Coombes 2015, Silbernagel 2007) ; chiffres = conventions prudentes | idem ; Gabbett 2016, BJSM 50(5) |
| Coude : prise neutre à la place de la pronation | tirage en pronation retiré pendant une poussée | partiellement soutenu (éviter de soulever avant-bras en pronation, Coombes 2015 ; pronation contrariée provocante dans l'épicondylite médiale) | Coombes 2015 ; StatPearls « Golfer's elbow » (NCBI Bookshelf, page non ouverte : captcha) |
| Test après des jours légers, deux mesures concordantes avant de baisser un repère | test à partir du 3e jour de la semaine, reporté un jour de bilan bas | partiellement soutenu (affûtage : Bosquet et al. 2007, MSSE 39(8)) ; deux mesures : règle de mesure | Bosquet 2007 ; Helms et al. 2018, Front Physiol |
| Montée du volume de répétitions | +15 % par semaine au plus (max. des 3 semaines d'avant) | partiellement soutenu : seuil de risque de Gabbett ; « règle des 10 % » non démontrée (Buist 2008), ACWR critiqué (Impellizzeri 2020) — garde-fou prudent, non présenté comme règle validée | Gabbett 2016 ; Buist et al. 2008, AJSM ; Impellizzeri et al. 2020, IJSPP |
| Tentatives | ouverture 91 %, 2e +5 % au plus, 3e +3 % au plus, +5 kg de charge externe au plus | soutenu (élites IPF 2012-2019 : ~91 %, +5 %, +3 % de la 3e visée) | Travis, Zourdos, Bazyler 2021, Percept Mot Skills 128(1) |
| Échec imprévu, simples d'entraînement | −7,5 % après une série manquée ; simple ≤ 92 % du max estimé (85 % un jour de bilan bas) | partiellement soutenu (autorégulation RPE/RIR ; un simple à RPE 8-9 ≈ 90-94 %) | Helms 2018 ; Halperin et al. 2022 (revue des échelles RIR) |
| Montée d'échauffement | 5 @40 %, 3 @60 %, 2 @75 %, 1 @85 % ; aussi avant le muscle-up | partiellement soutenu (échauffement spécifique proche du maximum : Ribeiro et al. 2021, revue) | Ribeiro et al. 2021, Motricidade ; Kraemer & Ratamess 2004, MSSE |
| Plateau : changer de méthode | test qui ne dépasse pas le repère → variante (tempo, archer, typewriter), cible intermédiaire | partiellement soutenu (variation planifiée ; aucun modèle supérieur, Kiely 2012) | Kraemer & Ratamess 2004 ; Kiely 2012, IJSPP |
| Tenues de figures | partie intense 60 à 75 % du max (80 % au plus), jusqu'à 10 séries quand le max ≤ 5 s | partiellement soutenu (isométrie ≥ 70 % de la force max., Oranchuk et al. 2019) ; chiffres = heuristique d'entraîneur | Oranchuk et al. 2019, Scand J Med Sci Sports |

### Dérive du panel (avant la première boucle)

Ancres `p08_a` et `p14_c`, un appel Opus par école : variante (a) 1 / 1 / 1 / 1, variante (c) 8 / 8 / 8 / 8 →
pas de dérive ((a) ≤ 2, (c) ≥ 8).
