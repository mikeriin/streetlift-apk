# Livraison CX — saisons street croisées : `kalis_plan` 0.2.1 × `kalis_adapt` 0.2.1

Lot moteur du pipeline « Calibrage des programmes » (voie A, Opus 5.5, effort maximal), exécuté du 04/10/2026 17:38 UTC au 05/10/2026.

**État : à valider — cible non atteinte.** Les paquets sont publiés et leurs contrôles sont verts. Mais la cible C7.5 — 9 au moins pour chacune des quatre écoles du panel et chacun des 17 profils street, sur les saisons croisées — n'est pas atteinte : 25 couples sur 68 sont à 9 (1 sur 68 avant le lot), le minimum est 4. C7.7 non plus (`street_08` : 5 à 8 ; `street_14` : 8 partout). Un constat touche la sécurité (douleur de poignet qui dure sur `street_10`, partie 7). Une décision est demandée (partie 8).

Page de relecture : https://claude.ai/artifact/48CYFBy75Xykohm674vLNq (manche 3, « street complet (CX, 04/10/2026) »).

## 1. Ce qui est livré

| Élément | Valeur |
| --- | --- |
| Paquets | `kalis_core` 0.4.2, `kalis_plan` 0.2.1, `kalis_adapt` 0.2.1, `kalis_bench` 0.2.0 |
| Branche | `moteurs`, commits 90f1fc8 (`kalis_core` seul) et e90e33e |
| Étiquettes | `etiquettes/kalis_core-v0.4.2`, `etiquettes/kalis_plan-v0.2.1`, `etiquettes/kalis_adapt-v0.2.1`, `etiquettes/kalis_bench-v0.2.0` |
| Contrôle | `claude/ci-cp-a`, run 37255941742 (mode complet, 100 graines), commit fac8af5 : vert ; `packages/` identique au commit livré, à la fin de `docs/CALIBRAGE_CX.md` près (Markdown, lu par aucun test) |
| Sauvegardes | `cp-sauvegardes/CX` |

**Saison croisée.** `kalis_plan` écrit le plan de saison et chaque bloc ; `kalis_adapt` conduit chaque séance d'un athlète simulé ; le résumé d'adaptation et les résultats de test d'un bloc nourrissent le bloc suivant. Saisons de 16 à 17 semaines, jusqu'à une semaine après l'échéance.

`kalis_plan` 0.2.1 (programme écrit, contrat § 12.13) :

- **bloc suivant d'après le test réel** : le dernier test mesuré fait foi, même sous un record déclaré ; repère manquant rempli par l'estimation du journal quand elle est sûre ; un test plus bas que l'estimation récente est recoupé avant d'abaisser un repère ;
- **échelle de poussée du débutant** (genoux → mains surélevées → sol) écrite comme une échelle du contrat, critère de passage mesurable, pompe au sol en pratique dès le deuxième bloc ;
- **figures** : critère de passage chiffré à environ 75 % du maximum, étape suivante ouverte à 75 %, tenues à 60-70 % les jours légers et 75-85 % les jours lourds, tirage bras tendus les jours de force quand le front lever est visé ;
- **charges** : séries allégées à −5 % (intensification, réalisation) ou −8 %, trois séries lourdes au moins en intensification et réalisation, hausse hebdomadaire du volume de 15 % au plus, lest sous le plus petit pas chiffré au poids du corps, 1RM de travail relevé d'après le maximum au poids du corps ;
- **échéance** : catégorie de poids et pesée (streetlifting), format d'épreuve inconnu dit (sets & reps), part spécifique de 65 à 75 % en intensification et réalisation pour les objectifs de répétitions, semaine de transition après l'épreuve ;
- **récupération** : jours de traction écartés de 48 h autant que possible, plafond de la semaine d'allègement à 65 % des séries ;
- **douleur qui dure** (`pain_trend`) : la figure reste au programme avec −40 % de volume et la variante la plus douce ;
- **test de la tenue menton** compté en secondes ; exercice au mur jamais proposé au parc sans mur (`feasibleAt` de `kalis_core` 0.4.2).

`kalis_adapt` 0.2.1 : une proposition appliquée ne fait plus perdre au bloc ses champs du contrat 0.4.0 (le bloc repassait en mode 0.1) ; chemin 0.1 inchangé à l'octet près.

`kalis_bench` 0.2.0 : banc des saisons — 17 profils × 8 scénarios (référence, séances manquées, maladie, douleur au coude, douleur à l'épaule, parc seulement, échéance avancée de deux semaines, deuxième échéance) × 3 modèles de vérité × 100 graines, comparaison au couple 0.1, export concis des saisons pour le panel et la page. Critères de sécurité, seuils, profils types et grilles du panel **inchangés** ; seule précision : les critères portent sur les blocs effectivement servis.

`kalis_core` 0.4.2 (commit séparé, additif) : `CatalogExercise.feasibleAt` (matériel et lieu) et trois tables publiques.

Le programme de 40 semaines du propriétaire n'est pas régénéré.

## 2. Banc des saisons, avant et après

Banc `kalis_bench` 0.2.0 (contrôle complet, 100 graines par modèle de vérité). « cx » : `kalis_plan` 0.2.1 × `kalis_adapt` 0.2.1 sur la saison croisée ; « 0.1 » : les moteurs 0.1 sur la même saison de référence. Moyennes sur les 17 profils et les trois modèles de vérité (`ci-out/packages/kalis_bench/SAISONS.md`).

| Saison | Couple | Écart d'effort (rép.) | Échecs non voulus | Progression / sem. | Tentatives réussies | Jour J ÷ maximum du jour | Écrit ↔ servi | Retirés sans raison | Violations par saison |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| référence | 0.1 | 1,49 | 0,63 % | 0,174 % | — | — | 6,8 % | 0,00 | 9,93 |
| référence | **cx** | **1,12** | **0,30 %** | **0,278 %** | 87 % | 95,6 % | 12,5 % | 0,00 | **0,03** |
| séances manquées | cx | 1,13 | 0,35 % | 0,135 % | 86 % | 95,8 % | 13,5 % | 0,00 | 0,04 |
| maladie | cx | 1,13 | 0,30 % | 0,277 % | 91 % | 95,1 % | 12,4 % | 0,00 | 0,04 |
| douleur au coude | cx | 1,11 | 0,26 % | 0,213 % | 85 % | 93,0 % | 16,3 % | 0,01 | 0,10 |
| douleur à l'épaule | cx | 1,15 | 0,28 % | 0,202 % | 86 % | 92,6 % | 15,3 % | 0,03 | 0,08 |
| parc seulement | cx | 1,12 | 0,28 % | 0,255 % | 87 % | 95,7 % | 12,5 % | 0,00 | 0,08 |
| échéance avancée | cx | 1,13 | 0,31 % | 0,286 % | 87 % | 95,6 % | 12,5 % | 0,00 | 0,03 |
| deuxième échéance | cx | 1,05 | 0,28 % | 0,257 % | 87 % | 96,7 % | 11,7 % | 0,00 | 0,02 |

Lecture :

- **Mieux que 0.1** sur la saison de référence : effort affiché plus juste (1,12 contre 1,49 répétition d'écart), deux fois moins d'échecs non voulus, progression réelle plus forte (0,278 % contre 0,174 % par semaine), et presque plus de violations de sécurité du programme tel qu'il a évolué (0,03 par saison contre 9,93).
- « Écrit ↔ servi » plus haut qu'en 0.1 : le moteur d'évolution recale davantage le programme écrit (répétitions recalées sur le maximum mesuré, crans d'assistance).
- **Saisons racontées** (modèle B, graine 0, `saisons/SECURITE.md`) : 0 violation sur la saison de référence des 17 profils ; 6 dans 4 des 119 saisons de scénario : `street_03` parc seulement (volume du deltoïde antérieur +1 série au-dessus de la borne) et échéance avancée (fessiers et quadriceps jusqu'à 13 séries pour un plafond de 12) ; `street_10` séances manquées (7 semaines de charge sans allègement, 6 admises) ; `street_16` douleur au coude (squat +7,1 % et +6,5 % de charge en une semaine, seuil 5 %).
- **Programmes écrits** (rapport du banc, `RAPPORT.md`) : 0 violation sur les 17 profils street ; les 23 du rapport viennent des autres disciplines (moteur 0.1, hors périmètre).
- Le banc ne voit pas la douleur de poignet qui dure sur `street_10` (partie 7).

## 3. Panel et relecture documentée

Panel : quatre écoles, en aveugle, sur la saison (programme écrit bloc après bloc, puis saison simulée, modèle B, graine 0). Passe finale complète sur la version livrée ; `street_16` × force renoté une fois (C7.9.4, 8 puis 9). Relecture documentée : trois relecteurs Opus, sources du web seulement, sept saisons.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 8 | 9 | 8 | 9 | 6,5 |
| `street_02_debutant_surpoids` | 9 | 8 | 8 | 9 | — |
| `street_03_debutante` | 7 | 7 | 7 | 8 | — |
| `street_04_reprise_longue_pause` | 9 | 9 | 9 | 9 | — |
| `street_05_inter_calisthenie_front_lever` | 7 | 7 | 7 | 8 | — |
| `street_06_inter_sets_reps` | 8 | 9 | 7,5 | 9 | 6 |
| `street_07_avance_streetlifting_competition` | 9 | 8 | 9 | 8 | 7 |
| `street_08_avance_sets_reps_competition` | 5 | 8 | 6,5 | 7 | 6 |
| `street_09_elite_streetlifting` | 8 | 9 | 9 | 8 | — |
| `street_10_elite_figures` | 6 | 4,5 | 4 | 7 | 5 |
| `street_11_master_51_ans` | 8 | 8 | 7 | 7 | — |
| `street_12_antecedent_coude` | 8 | 8 | 8 | 8 | 6 |
| `street_13_peu_de_temps` | 8 | 9 | 8 | 8 | — |
| `street_14_parc_sans_lest` | 8 | 8 | 8 | 8 | 6 |
| `street_15_travail_physique_sommeil_court` | 9 | 9 | 9 | 9 | — |
| `street_16_specialisation_traction_lestee` | 9 | 9 | 9 | 9 | — |
| `street_17_hybride_street_course` | 8 | 9 | 8 | 9 | — |

- **Panel** : 25 couples sur 68 à 9, minimum 4, moyenne 8,01 (passe 0 : 1 sur 68, minimum 4,5, moyenne 7,01). À 9 partout : `street_04`, `street_15`, `street_16`. L'incertitude du panel est d'un point : sur des exports identiques, la boucle 5 donnait 32 couples à 9 et `street_14` à 9 partout ; la dernière notation fait foi.
- **Ce que le panel demande encore** (corrections nécessaires, lues en entier) : figures de l'élite (tenues trop près du maximum sur des leviers trop durs, pas d'outil de surcharge du front lever, douleur de poignet qui dure sans arrêt ni consultation) ; montée de volume du premier bloc de `street_08` (+35 % de dips en une semaine), tests juste après le pic ; poussée de la débutante (pompe au sol à 1-3 répétitions, critères contradictoires) ; front lever de `street_05` (tenues qui ne montent pas, tirage bras tendus absent) ; plateau sans changement de stimulus (`street_11`, `street_13`).
- **Relecture documentée** : 5 à 7, moyenne 6,1 (sans seuil, C7.6), notes écrites sur la page (manche 3).

## 4. Remarques de la page de relecture et de la relecture documentée, traitées

La page ne porte aucune note du propriétaire. Remarques des manches 1 et 2 sur le programme écrit (LANCEMENTS.md, CX) :

| Remarque | Suite |
| --- | --- |
| Bloc suivant écrit sur le repère attendu, pas sur le test | **corrigé** (test réel, estimation sûre, recoupement d'un test bas) |
| Échelle de poussée du débutant | **corrigé** en partie : échelle du contrat, critère mesurable ; la pompe au sol reste dosée trop bas (`street_03`) → CP2 |
| Seuils, critère et tenues des figures ; tirage de force | **corrigé** pour l'intermédiaire ; l'élite reste mal dosée (`street_10`) → correction demandée |
| Séries allégées −5 / −8 %, trois séries ≥ 85 % | **corrigé** |
| Réalisation spécifique, format sets & reps, catégorie et pesée | **corrigé** |
| Tractions deux jours de suite, hausses de 10 à 15 %, charges « à calibrer » chiffrées | **corrigé** ; la montée du premier bloc de `street_08` dépasse encore la borne → correction demandée |
| Test de maintien d'une négative compté en répétitions ; mur au parc | **corrigé** (tenue menton en secondes ; `feasibleAt`) |
| Temps disponible non utilisé | non corrigé (le moteur ne remplit pas un créneau) → CP2 |

Relecture documentée de la manche 3 (sept saisons) :

| Remarque | Suite |
| --- | --- |
| Test en allègement ou juste après un pic, bloc suivant réécrit à la baisse (`street_06`, 08, 10, 14) | en partie : un test bas est recoupé avec l'estimation récente ; le placement du test (jours légers avant, test seul) → CP2 |
| Séries assistées trop faciles, pompe figée, pas de test final (`street_01`) | élastique choisi sur la série repère (CX) ; pompe et test final → CP2 |
| Travail spécifique à l'objectif de répétitions, variantes dures au parc, muscle-up figé (`street_06`, 14) | part spécifique portée à 65-75 % (CX) ; variantes dures et figures au parc → CP2 |
| Simples lourds de muscle-up, palier entre 65 et 85 %, jeudi trop dense (`street_07`) | → CP2 |
| Volume, format de l'épreuve, muscle-up chargé (`street_08`) | même constat que le panel → correction demandée |
| Figures et poignet (`street_10`) | même constat que le panel → correction demandée, en tête |
| Pourcentages des dips recalés sur le test, objectif, conduite sous douleur à 5/10 (`street_12`) | séries de tête recalées sur le test (CX) ; ouverture et objectif → CP2 ; conduite sous douleur → CA2 |

Une source de la relecture n'a pu être ouverte (fiche MSD Manual sur l'épicondylite médiale : vue seulement dans les résultats de recherche).

## 5. Calibrage

Cinq boucles sur dix (C7.2), chaque boucle avec une recherche ciblée (`docs/CALIBRAGE_CX.md`).

| Passe | Couples à 9 | Minimum | Moyenne | Ce que la boucle a changé |
| --- | --- | --- | --- | --- |
| 0 (complète) | 1 / 68 | 4,5 | 7,01 | — |
| 1 | 23 / 68 | 4 | 7,81 | bloc suivant sur le test et les estimations, transition après l'échéance, tirage espacé, échelle de poussée, critères et tenues des figures, séries allégées et lourdes, catégorie et format |
| 2 | 22 / 68 | 5 | 7,80 | douleur qui dure (`pain_trend`), test de traction en secondes, réalisation des répétitions, reprise après la transition, allègement à 65 %, descentes freinées |
| 4 (boucles 3 et 4) | 31 / 68 | 5 | 8,04 | intentions gardées par `kalis_adapt`, séries sur le dernier repère mesuré, deuxième figure, tirage bras tendus, introduction, relecture indépendante |
| 5 | 32 / 68 | 5 | 8,06 | 1RM de travail d'après le poids du corps, figure écartée pour douleur gardée, poussée du débutant, marge de 6 % des estimations |
| finale (complète) | 25 / 68 | 4 | 8,01 | — |

Passes 1 à 5 : couples renotés selon la règle d'économie (sous 9 dont l'export a changé, ou à 9 avec plus de 10 % de lignes changées). La règle « deux boucles sans gain » n'est pas remplie ; j'ai arrêté après la boucle 5 pour le temps et le budget du lot, les corrections restantes étant profondes.

Relecture indépendante du code (Opus, lecture seule) : 12 constats, tous traités (`docs/CALIBRAGE_CX.md`).

## 6. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse, tests des cinq paquets et outils Python (mode complet, 100 graines) | vert (run 37255941742 ; `kalis_core` 328 tests, `kalis_plan` 213, `kalis_adapt` 233, `kalis_bench` 65, `kalis_quest` 162) |
| Chemin 0.1 (`kalis_plan`, `kalis_adapt`) | inchangé à l'octet près (tests de référence) |
| Profils types, attentes, critères et grilles du panel | inchangés (empreintes des grilles identiques à `docs/PANEL.md`) |
| Dérive du panel avant la première boucle | aucune |
| Relecture indépendante du code (Opus, lecture seule) | 12 constats, tous traités |
| Non-ressemblance aux programmes de référence (17 saisons écrites) | maximum exact 0,150, tolérant 0,214 (seuil 0,30) ; détail chiffré sur `cp-references` |
| Programme importé du propriétaire | non régénéré, rejoué inchangé (`docs/PROPRIETAIRE.md`) |

## 7. Limites

- **Sécurité, constat ouvert** : sur `street_10`, la gêne du poignet reste à 4/10 plusieurs blocs ; `pain_trend` garde la figure (−40 % de volume) alors que la règle écrite dans le programme demande l'arrêt du mouvement et une consultation quand la gêne dure deux semaines. Le banc ne compte pas ce cas.
- Un bloc écrit ne change d'étape de figure ou de cran d'échelle qu'au bloc suivant ; le créneau disponible n'est pas rempli.
- Tirage bras tendus absent pour `street_05` (le constructeur des jours de force ne le place pas pour ce profil).
- Pas de règle de plateau (changement de stimulus quand les répétitions stagnent).
- Tout est mesuré sur des athlètes simulés ; le contenu sportif n'a pas été relu par un professionnel diplômé.

## 8. Décision demandée et suite proposée

La cible « 9 partout » n'est pas atteinte (25 couples sur 68, minimum 4) et un constat touche la sécurité. Ma recommandation :

1. **ne pas valider CX comme « street au niveau coach »** ; accepter les paquets comme base de la suite : ils font mieux que la livraison précédente dans toutes les écoles (1 → 25 couples à 9, moyenne 7,01 → 8,01) et que 0.1 sur le banc des saisons ;
2. **ouvrir une passe « CX correction 1 » courte, avant CP2**, sur trois points : (a) douleur qui dure deux semaines au même niveau → arrêt du mouvement provocant, consigne de consultation, reprise graduée après deux semaines à 2/10 au plus (`street_10`) ; (b) montée de volume du premier bloc bornée à +10-15 % par semaine sur le mouvement de l'épreuve, tests à l'écart du pic (`street_08`) ; (c) dosage des figures de l'élite : tenues à 50-70 % du maximum sur un levier dont le maximum est entre 8 et 25 s, volume en secondes cumulées, outil de surcharge du front lever ;
3. **reporter à CP2** la poussée de la débutante, la règle de plateau, le placement des tests, les variantes dures au parc, les simples lourds du muscle-up, le créneau disponible ; **à CA2** l'estimation moins prudente, le passage d'un cran d'échelle et la conduite sous douleur.

Décisions du lot : `DECISIONS_CP.md`, section CX. Journal du calibrage : `packages/kalis_bench/docs/CALIBRAGE_CX.md`.
