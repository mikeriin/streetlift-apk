# Règles de sécurité de kalis_adapt 0.3.1 et critères de sécurité du banc : inventaire pour Koach 1.0

Source : dépôt `/home/claude/moteurs`, branche `moteurs`, commit `aacbe054` (« kalis_plan 0.3.1, kalis_adapt 0.3.1 »).
Lu en lecture seule. Chemins relatifs à `packages/`. « A » = `kalis_adapt/lib/src/`, « P » = `kalis_plan/lib/src/coach/`,
« B » = `kalis_bench/lib/src/`. Les valeurs viennent du code (`A/params.dart`, `AdaptParams.standard`, ligne du
défaut entre parenthèses). Quand le CONTRAT et le code divergent, le code fait foi et l'écart est signalé **[ÉCART]**.

## 0. À lire d'abord

1. **Deux modes.** Un bloc qui porte au moins un champ du contrat 0.4.0 (intention de bloc ou de semaine, échelle
   de figure, groupe, `dayStress`, technique, intensité, autorégulation, test, `skillTargetId`) est servi en
   **mode coach** (`blockCoached`, A/coach.dart:23-48). Sinon : règles de 0.1 (§ A1 à A6 seulement) plus l'endurance.
   Tous les blocs de kalis_plan 0.3.1 du chemin coach sont en mode coach. Koach doit reprendre le mode coach.
2. **Échelle des flammes** (kalis_core/lib/src/flames.dart:26-31) : RIR = 0 pour 10 flammes, sinon (11 − f)/2.
   10→0 ; 9→1 ; 8→1,5 ; 7→2 ; 6→2,5 ; 5→3 ; 4→3,5 ; 3→4 ; 2→4,5 ; 1→« 5 et plus ».
3. **Sollicitation d'une zone** `zoneLevel` (A/book.dart:62-78) : 1 = contrainte articulaire forte (`JointStress.high`)
   ou travail direct d'un muscle de la zone ; 0,5 = contrainte moyenne ou muscle secondaire ; 0 sinon. Zones sans
   articulation (haut du dos, poitrine, abdomen, cuisse, bas de jambe) : muscles de `zoneGroups` (A/book.dart:96+).
   `excludedByPain(zone, i, hard, severe)` = `(niveau ≥ 1 et i ≥ hard) ou (niveau ≥ 0,5 et i ≥ severe)` (A/book.dart:82-91).
4. **Ce que le banc contrôle.** `safetyFindings` (B/safety.dart:315) lit les **blocs** du programme (pass1/pass2) :
   celui que kalis_plan écrit, et le programme « évolué » = blocs reconstruits + propositions appliquées par la
   revue (B/report.dart:203-233 ; B/season.dart:600-650, `servedBlocksOf`). Il ne lit **pas** les séances
   servies jour par jour (`prescribeSession`). Les règles A s'appliquent à la séance servie ; elles ne sont
   contrôlées par le banc qu'à travers les mesures de trajectoire (CRITERES.md §4 : 0 hausse > 10 % d'un mouvement
   principal, 0 aggravation de douleur, échecs non voulus ≤ 5 %).
5. **Rien dans kalis_adapt 0.3.1 ne lit `healthScreening`, l'âge, l'IMC ni un « plafond de la première semaine ».**
   Ces règles sont dans kalis_plan (génération du bloc) ; elles sont résumées en § A13 parce que le banc les
   contrôle (critères `impact_deconseille`, `volume_trop_vite`).

---

# Partie A — Règles de sécurité de kalis_adapt 0.3.1

Notation : **Décl.** = condition de déclenchement ; **Action** ; **Durée/levée** ; **Param.** ; **Réf.**

## A1. Douleur du jour (règle de base, deux modes)

### A1.1 Enregistrement, seuil et « zone active »
- **Décl.** Bilan du jour avec `pains`. Pour chaque zone citée : intensité max du jour notée (`notePain`,
  A/model.dart:508-528) ; liste `pains` vide = aucune douleur, les zones suivies passent à 0 (`clearPain`,
  A/model.dart:539-548) ; liste absente = question non posée (CONTRAT §2, l. 68-70).
- **Zone active** : dernière intensité > `painThreshold` **et** dernier signalement il y a ≤ `painClearDays` jours
  (`painActive`, A/model.dart:552-559). Donc active à partir de **4/10**.
- **Douleurs du jour** retenues pour la séance : zones actives, avec leur dernière intensité (A/session.dart:223-228).
- **Zone bloquante pour un exercice** (`painBlocks`, A/model.dart:565-581) : zone active, **ou** signalée au-dessus du
  seuil depuis la dernière séance de cet exercice (même levée depuis), et `zoneLevel ≥ 0,5`.
- **Param.** `painThreshold` 3 (l. 93) ; `painClearDays` 14 (l. 97).

### A1.2 Pas de hausse sur une zone douloureuse (invariant I3)
- **Décl.** Exercice dont une zone est bloquante (A1.1).
- **Action** : aucune charge au-dessus de la dernière séance de l'exercice ; sans charge, aucune cible (répétitions,
  secondes) au-dessus de la plus grande série de la dernière séance ; aucune ligne de plus que la dernière séance
  de l'emplacement (« lignes gelées »). +1 RIR sur la cible (plafonné à RIR 5).
- **Réf.** 0.1 : A/model.dart:2204-2211 (`heldCause 'pain'`), A/session.dart:1909-1912 ; coach : A/coach.dart:1122-1126,
  1140-1142, 1256-1267 (charge), 1463-1486 et 1560-1589 (sans charge), 915-922 (lignes gelées) ; +1 RIR :
  A/model.dart:1311-1314. Conseil d'entre-séries : jamais plus lourd que la série précédente (A/coach_advice.dart:109-131).
- **Param.** `painRirBonus` 1 (l. 96).
- **Durée** : tant que la zone est bloquante (≤ 14 jours après le dernier signalement > 3).

### A1.3 Retrait ou remplacement par la douleur du jour
- **Décl.** (mode coach) `excludedByPain(zone, i, hard = painHard, severe = coachPainStop)` : niveau 1 et i ≥ **4**,
  ou niveau 0,5 et i ≥ **5**. (Mode 0.1 : severe = `painSevere` **7**.) A/session.dart:364-373.
- **Action** : remplacé par le plus proche remplaçant (A1.5), sinon retiré (`exerciseRemoved`, raison
  `adapt.pain_reported`). A/session.dart:489-546.
- **Param.** `painHard` 4 (l. 94) ; `coachPainStop` 5 (l. 187) ; `painSevere` 7 (l. 95, mode 0.1 seulement).
- **[ÉCART]** CONTRAT §4.7 et INTEGRATION_CI §4 disent « 7/10 sur contrainte moyenne » : vrai seulement hors mode
  coach ; en mode coach le code retire à 5 (CONTRAT §11.8 et §11.16 le disent). CONTRAT §8 limite 11 (« 5 à 6/10
  gardé ») est périmée pour le mode coach.

### A1.4 Allègement à 4/10 sur contrainte moyenne (mode coach)
- **Décl.** Douleur du jour ≥ `coachPainRegress` (4) et `zoneLevel ≥ 0,5`, exercice non exclu par A1.3.
  A/session.dart:374-378.
- **Action** : séries × `coachPainRegressSets` arrondi vers le bas, au moins 1 (A/session.dart:1180-1212) ; +1 RIR
  (plafond 5) (A/session.dart:1296-1298) ; en plus A1.2. Technique d'intensification retirée (A9.2).
- **Param.** `coachPainRegress` 4 (l. 186) ; `coachPainRegressSets` 0,6 (l. 188).
- Note : le commentaire de A/session.dart:1180 dit « 5 sur 10 », le code teste ≥ 4.

### A1.5 Choix d'un remplaçant (`findSubstitute`, A/session.dart:91-177)
- Exclus : l'exercice lui-même, déjà présent, détesté ou déclaré non su, autre unité, plus difficile
  (`difficulty` supérieure), autre discipline **et** autre chaîne, infaisable avec le matériel ou au lieu du jour,
  autre mode de capacité, interdit par `avoid` (arrêts en cours, A2).
- Doit épargner chaque zone douloureuse : non exclu par la douleur (mode coach : severe = 5) **et**
  `zoneLevel(remplaçant) ≤ zoneLevel(original)` (A/session.dart:155-164).
- Proximité `planSimilarity ≥ 0,45` (`substituteMinSimilarity`, A/session.dart:28).
- Remplaçant choisi pour une douleur du jour (mode coach) : servi à **3 RIR au moins**, sans hausse, charge
  ≤ `coachPainSubPct` × 1RM (A/session.dart:856-872, 1309-1322 ; plafond appliqué même sans part du 1RM écrite,
  A/session.dart:1846-1885).
- **Param.** `coachPainSubPct` 0,70 (l. 181) ; `coachReturnRir` 3 (l. 177).

### A1.6 Tests et douleur (mode coach)
- **Décl.** Ligne de test et (zone du jour avec `zoneLevel ≥ 0,5`) ou (zone signalée **> 2/10** dans les 7 derniers
  jours, `reportsBetween(day−6, day)`, `zoneLevel ≥ 0,5`). A/session.dart:394-433.
- **Action** : test **retiré, jamais remplacé** (`adapt.pain_reported`).
- **Param.** `coachReturnPain` 2 (l. 178).

### A1.7 Proposition « épargner la zone » (revue)
- **Décl.** ≥ 2 séances de suite au-dessus de 3/10 et zone active (A/review.dart:911-941).
- **Action** : proposition `painSparing` (portée bloc, confiance 0,9), emplacements libres = ceux qui sollicitent la
  zone (`zoneLevel > 0`), demandée à kalis_plan. Niveau de déblocage `loads_reps` (dès le 1er jour).

## A2. Douleur qui dure : arrêt, renvoi vers un professionnel (mode coach)

### A2.1 Déclenchement de l'arrêt (`PainState.stopAt`, A/model.dart:122-202)
Signalements ≥ `painPersistMin` (3) regroupés en épisodes (écart ≤ 14 jours entre deux signalements). Arrêt de la
zone si, dans l'épisode en cours, **au moins une** condition :
- (a) **dure** : dernier − premier signalement ≥ 3/10 ≥ 14 jours (`painPersistDays`) ;
- (b) **forte** : signalements ≥ 5/10 étalés sur ≥ 7 jours (`painStrongMin`, `painStrongDays`) ;
- (c) **retour** : l'épisode précédent était réel (≥ 2 signalements, ou un ≥ 4/10) et le nouveau commence ≤ 84 jours
  après sa fin (`painRecurDays`) ;
- (d) **≥ 3 séances de suite > 3/10** (donc ≥ 4/10) dans l'épisode (A/model.dart:170-193).
- Pas d'arrêt si le dernier signalement ≥ 3 date de ≥ 14 jours (`painResumeDays`, A/model.dart:127).
- **Param. (constantes hors AdaptParams)** A/model.dart:20-46 : `painPersistMin` 3, `painPersistDays` 14,
  `painEpisodeGapDays` 14, `painResumeDays` 14, `painStrongMin` 5, `painStrongDays` 7, `painRecurDays` 84.
- **[ÉCART]** CONTRAT §11.15 ne cite pas (d) ; il n'apparaît que dans la note de relecture du 08/10/2026
  (CONTRAT l. 1302-1304). Le code l'applique.

### A2.2 Action pendant l'arrêt (A/session.dart:552-855)
1. **Mouvements qui provoquent la zone** (`coachPainStopHits`, P/athlete.dart:153-155) : retirés, **échauffement
   compris** (A/session.dart:581-643). Provoque = contrainte forte sur l'articulation de la zone ; pour le poignet,
   contrainte moyenne ou forte **sans** prise neutre (moyenne : matériel de `coachNeutralGripEquipment` = barre
   fixe, barres parallèles, barre basse, anneaux, parallettes, poignées, sangles ; forte : `coachNeutralSupportEquipment`
   = barres parallèles, anneaux, parallettes, poignées) (P/athlete.dart:95-147) ; pour le coude, aussi tout tirage
   vertical en pronation (`coachPronationPull`, P/athlete.dart:162-172 : id contenant `pronation`, `large`, `nuque`,
   ou `sl-traction-lestee`, sauf `neutre`, `supination`, `chin`, `corde`, assisté).
2. **Mouvements qui chargent la zone sans la provoquer** (`zoneLevel ≥ 0,5`) : gardés au **premier palier de
   reprise** : séries × 0,5 arrondi vers le bas (≥ 1), 3 RIR au moins, aucune hausse, charge ≤ 67,5 % du 1RM, jamais
   de test (`stopDose`, A/session.dart:763-796, 840).
3. **Escalade** : si l'arrêt existait déjà il y a 14 jours (`coachStopEscalateDays`) **et** la zone est encore
   signalée ≥ 3/10 dans les 7 derniers jours → ces mouvements sont **retirés aussi**, échauffement compris
   (A/session.dart:805-809, 840-849).
4. **Renvoi vers un professionnel** : raison `adapt.pain_persistent` (zone, séances) sur la séance à la première
   séance de l'arrêt puis à la première séance de chaque semaine d'arrêt (`_stopNoticeDue`, A/session.dart:574-580,
   2397-2420). La revue la porte tant que l'arrêt dure (A/review.dart:384-395) et propose `painSparing` (« pain_stop »,
   confiance 0,95) sur les emplacements libres qui provoquent la zone (A/review.dart:867-909). Le texte « consulter »
   est écrit par kalis_plan (note `clearance_first`, P/prescribe.dart:8225-8236 ; INTEGRATION_CI §5.1).
5. Un mouvement retiré par un arrêt n'est pas compté « sauté » dans le résumé (A/review.dart:409-434).
- **Levée** : 14 jours sans signalement ≥ 3/10 (A/model.dart:127, `liftedOn` A/model.dart:231-261), puis reprise
  graduée (A3). Jamais de levée en cours de séance ni sur une semaine qui n'est pas de charge (A3.2).
- **Param.** `coachStopEscalateDays` 14 (l. 180) ; `coachReturnStart` 0,5 (l. 174) ; `coachReturnRir` 3 (l. 177) ;
  67,5 % : constante de `_returnLoadAt` (A/session.dart:2372-2373).

### A2.3 Douleur qui dure au bas du corps : course retirée
- **Décl.** Mode coach, arrêt sur hanche, cuisse, genou, bas de jambe ou cheville/pied.
- **Action** : toute ligne de **course** retirée tant que l'arrêt tient (`adapt.pain_persistent`) ; cardio sans impact
  gardé. Au retour (zone en reprise graduée), course à ≤ `enduranceResumeLong` (50 %) de l'écrit, cause `resume_14`.
- **Réf.** A/session.dart:2527-2567, 2626-2628 ; CONTRAT §13.1 règle 2 bis.

## A3. Reprise graduée (mode coach, `A/pain_return.dart`)

### A3.1 Zones en reprise
- Zone en reprise si le bloc l'écrit (notes `pain_return` / `pain_return_item` de kalis_plan, A/pain_return.dart:18-51)
  **ou** si son arrêt a été levé il y a ≤ `coachReturnWatchDays` jours (A/pain_return.dart:142-189).
- Une semaine « de charge » pour la reprise = semaine non verrouillée ou d'introduction (`returnLoadedWeek`,
  A/pain_return.dart:57-58). Une semaine compte quand la levée laisse au moins 4 de ses jours (l. 158-163).

### A3.2 Arrêt gardé
- **Décl.** Levée récente mais aucune semaine de charge commencée depuis et semaine du jour non de charge
  (allègement, affûtage, test, compétition, transition).
- **Action** : l'arrêt est gardé (zone `held`) jusqu'à la première semaine de charge ou d'introduction : mouvements qui
  la provoquent retirés, échauffement compris (A/pain_return.dart:165-170 ; A/session.dart:645-672).

### A3.3 Paliers
- **Reprise propre au moteur** (arrêt levé au milieu d'un bloc qui écrit encore les mouvements) : part du volume
  écrit = `coachReturnStart + coachReturnStep × semaines de charge écoulées` (0,5 ; 0,6 ; 0,7 ; 0,8 ; 0,9 ; fin à 1,0),
  une semaine allégée garde la part de la dernière semaine de charge (A/pain_return.dart:171-181).
- **Reprise écrite par le bloc** : part `pain_return_item` de la ligne ; si les deux existent, la plus basse
  (A/session.dart:704-718). Plusieurs zones : la plus basse.
- **Séries** = séries écrites × part ÷ part écrite, arrondi vers le bas, ≥ 1 (A/session.dart:715-751).
- **Charge** ≤ `0,675 + 0,25 × (part − 0,5)` du 1RM : 67,5 % ; 70 % ; 72,5 % ; 75 % ; 77,5 % (A/session.dart:2372-2373 ;
  appliqué A/coach.dart:992-997 et A/session.dart:1846-1885).
- **Dose plafonnée** (`doseCapped`) : ni séries ajoutées, ni plage étendue, ni tenue allongée, ni série repère ;
  ≥ 3 RIR ; aucune hausse dans la séance (A/session.dart:1309-1323 ; A/advise.dart:195-203 ; A/coach_advice.dart:109-150).
- **Tests** sur une zone en reprise : retirés (A/session.dart:691-701) ; une reprise écrite par le bloc reporte ses
  tests au bloc suivant (CONTRAT §11.16).
- **Recul d'un palier** (`_responds`, A/pain_return.dart:203-233) si, sur les 7 derniers jours : un signalement
  > 2/10 ; ou les deux derniers signalements montent (le dernier > 0) ; ou la pire gêne de la semaine > pire gêne de la
  semaine d'avant. Effet : part − 0,10, plancher 0,40 ; séries réduites d'autant ; la zone compte comme douloureuse
  (aucune hausse) (A/session.dart:719-728).
- **Hausse de la quantité par série** sur une zone à l'arrêt ou sortie d'arrêt depuis ≤ 84 jours (zone « récente » ;
  aussi toute zone signalée > 2/10 le jour même, A/session.dart:1238-1244) : répétitions ou secondes par série
  ≤ `max(⌊dernière × 1,10⌋, dernière + 1)` d'une séance à la suivante, même si le bloc écrit plus ; pas de série
  repère ni de plage étendue (A/coach.dart:1601-1613 ; zones : A/session.dart:2379-2392).
- Une gêne ≥ 3/10 qui revient relance l'arrêt (A2.1 c).
- **Param.** `coachReturnStart` 0,5 (l. 174) ; `coachReturnStep` 0,1 (l. 175) ; `coachReturnFloor` 0,4 (l. 176) ;
  `coachReturnRir` 3 (l. 177) ; `coachReturnPain` 2 (l. 178) ; `coachReturnWatchDays` 84 (l. 179) ;
  `coachRecentRise` 0,10 (l. 182). kalis_plan : `coachPainReturnStart` 0,5, `coachPainReturnStep` 0,1,
  `coachPainReturnSteps` 5 (P/athlete.dart:177-185).

## A4. Poignet (mode coach)

### A4.1 Première gêne (avant tout arrêt)
- **Décl.** Poignet signalé ≥ 3/10 dans les 14 derniers jours (`wristGeneRecent`, A/session.dart:2456-2460), pas d'arrêt
  du poignet ; ligne de travail, au poids du corps (mode répétitions), contrainte **moyenne** sur le poignet, qui
  provoque le poignet, pas déjà sur appui neutre (A/session.dart:442-451).
- **Action** : remplacée par un appui neutre faisable aujourd'hui : parallettes, poignées, ou `sw-pompe-inclinee`
  quand le matériel compte `barre basse` (mains serrées sur la barre) ; jamais un remplaçant à contrainte forte sur
  le poignet ni interdit par un arrêt (A/session.dart:452-487 ; `coachWristNeutralSupport` A/session.dart:2438-2452).
  Raison `adapt.pain_reported` (zone `wrist_hand`, intensité = pire gêne des 14 jours). Sans appui neutre : ligne
  gardée, dose plafonnée (A4.3).

### A4.2 Arrêt du poignet
- Toute poussée en extension qui provoque le poignet est retirée, échauffement compris (A2.2) ; une poussée de travail
  au poids du corps est remplacée par un appui **parallettes ou poignées seulement** (jamais barres parallèles,
  anneaux, ni `sw-pompe-inclinee`), contrainte poignet ≤ moyenne, servi au premier palier (A/session.dart:591-633).
- **Toute charge externe d'appui** chargeant le poignet (`zoneLevel ≥ 0,5`, mode chargé) est retirée dès l'arrêt,
  prise neutre comprise (A/session.dart:838-849).
- **Poignet « chaud »** (arrêt et signalement ≥ 3/10 le jour même ou dans les 6 jours d'avant, `wristStopHot`,
  A/session.dart:2876-2891) : tout ce qui charge le poignet est retiré, échauffement compris, sauf les appuis
  parallettes/poignées à contrainte < forte (planche, équilibre, HSPU retirés même sur parallettes)
  (A/session.dart:816-849). Quand la gêne de la semaine redescend ≤ 2/10 : retour à la règle précédente.
- Remplaçant pour la douleur du jour pendant un arrêt du poignet : seulement si contrainte poignet basse ou appui
  parallettes/poignées (`stopAvoid`, A/session.dart:338-345).

### A4.3 Poignet sensible : dose plafonnée
- **Décl.** Poignet en zone fragile du profil (antécédent < 12 mois ou gêne déclarée ≥ 2), en reprise ou arrêt gardé,
  à l'arrêt, ou signalé ≥ 1/10 dans les 14 derniers jours (`wristSensitive`, A/session.dart:1688-1716).
- **Action** : toute ligne qui provoque le poignet est servie à la dose écrite au plus (`doseCapped` : ni séries
  fractionnées ajoutées, ni tenue allongée vers 50 % du max, ni répétitions au-delà de l'écrit, ni série repère)
  (A/session.dart:1330-1335 ; A/advise.dart:186-188).

## A5. Bilan de santé du jour (deux modes) et « maladie »

### A5.1 Lecture (`readHealth`, A/fatigue.dart:160-216)
- Seules les réponses données comptent. Décalage général = −`healthPerPoint` × (`healthNeutral` − réponse générale)
  si réponse < 4. Détail : −`sleepPerHour` par heure sous `sleepHoursNeutral` (3 h au plus) ; −`detailPerItem` par
  réponse de détail ≤ 2 sur 5 (sommeil, énergie, humeur, courbatures, stress, motivation, alimentation, hydratation).
  Décalage = général + `detailShare` × détail (détail seul si pas de réponse générale), plancher `healthFloor`.
- **Palier 2** si décalage ≤ `healthLevel2` **ou** réponse générale ≤ 1 ; **palier 1** si décalage ≤ `healthLevel1`
  **ou** réponse générale ≤ 2 ; sinon 0.
- **Param.** `healthPerPoint` 0,015 (l. 83) ; `healthNeutral` 4 (l. 84) ; `sleepHoursNeutral` 6 (l. 85) ;
  `sleepPerHour` 0,01 (l. 86) ; `detailPerItem` 0,01 (l. 87) ; `detailShare` 0,5 (l. 88) ; `healthFloor` −0,08 (l. 89) ;
  `healthLevel1` −0,02 (l. 90) ; `healthLevel2` −0,04 (l. 91) ; `healthRirBonus` 0,5 (l. 92).

### A5.2 Effets
| Palier | Effet | Réf. |
| --- | --- | --- |
| tout palier | capacité prévue baissée du décalage ; `loadReduced` (facteur exp(décalage)) affiché sur les exercices chargés si palier ≥ 1 | A/session.dart:1379-1390 |
| 1 | +0,5 RIR sur chaque cible ; **aucune hausse** (charge, répétitions, secondes ; base = dernière séance d'une semaine de charge de l'emplacement, jamais une séance légère ni une séance de jour bas) ; tests retirés (mode coach, hors jour d'échéance) | A/session.dart:233-242, 979-1001 ; A/coach.dart:1131-1139 ; marques : CONTRAT §13.1 r. 5 |
| 2 | +1 RIR ; aucune hausse ; **une série de moins** par exercice ayant des flammes cibles (plancher 3 séries pour un mouvement principal, 2 sinon ; mode coach : seulement si la technique permet de réduire les séries) ; mode coach : **aucune série sous 3 RIR**, pas de test, pas de technique d'intensification (A9.2), simple d'entraînement ≤ 85 % du max du jour | A/session.dart:1148-1178, 1299-1305 ; A/coach.dart:767-768, 1268-1282 |
| 1 ou 2 | endurance : séance de qualité → course facile (A10.2) ; palier 2 : durée ×0,7 | A/session.dart:2604-2713 |
| 1 ou 2 | tentatives : maximum du jour réduit de 2 % × palier (A8.2) | A/coach.dart:2270-2273 |

- Conseil d'entre-séries : jamais plus lourd que la série précédente un jour de palier ≥ 1, bilan redonné ou relu
  dans la séance (A/advise.dart:113-140, 429-465 ; A/coach_advice.dart:116-131).
- Programme importé en % seul (mode 0.1) : seule « aucune hausse » s'applique (CONTRAT §4.5).
- **Param.** `coachLowDayRir` 3 (l. 147) ; 0,85 et 0,92 sont des constantes (A/coach.dart:1276).
- **Maladie** : aucune règle propre ; elle passe par le bilan (palier 1/2), la coupure (A6) et l'alerte de surmenage.

## A6. Fatigue, récupération, coupure

### A6.1 Reprise après coupure (mode coach)
- **Décl.** ≥ `coachBreakDays` jours depuis la dernière séance, ou une telle coupure dans les 7 derniers jours
  (A/session.dart:1097-1113).
- **Action** : séries × `coachBreakSets` arrondi au plus proche (si ≥ 1 et < séries) sur toute ligne réductible hors
  test et hors endurance (A/session.dart:1114-1146). Raison `adapt.resume_after_break` dès 7 jours (A/session.dart:283-292).
- **Param.** `coachBreakDays` 14 (l. 148) ; `coachBreakSets` 0,8 (l. 149).

### A6.2 Alerte de surmenage (mode coach, mouvement principal)
- **Décl.** Deux séances mesurées de suite ≥ `coachOverreachDrop` sous la séance de référence, les trois en
  ≤ `coachOverreachSpanDays` jours (A/model.dart:452-453).
- **Action** : pendant `coachOverreachDays` jours, lignes − round(lignes × `coachOverreachCut`) (≥ 1 retirée, jamais
  la dernière : seulement si ≥ 2 lignes), intensité gardée, en semaine de charge seulement (A/coach.dart:923-958).
- **Param.** 0,05 (l. 143) ; 7 (l. 144) ; 21 (l. 145) ; 0,4 (l. 146).

### A6.3 Décharge anticipée (revue)
- **Décl.** Semaine suivante `build` ou `intro` et (forme du jour < `deloadReadiness` sur les `deloadSessions` dernières
  séances, ou ≥ 3 séances récentes à résidu moyen ≤ −3 % avec forme < 0,6) (A/review.dart:572-588).
- **Action** : proposition `deload` : séries × 0,6 arrondi (≥ 1), RIR + 2 (plafond 5) sur la semaine suivante
  (A/review.dart:598-633 ; `deloadVolumeFactor` 0,6 et `deloadRirBonus` 2, kalis_plan/lib/src/pass2.dart:25, 31).
  Bloquée si la semaine suivante est verrouillée (A/review.dart:1041-1042). Déblocage `volume` (2 semaines de données).
- **Param.** `deloadReadiness` 0,4 (l. 117) ; `deloadSessions` 2 (l. 118).

### A6.4 Récupération déclarée réduite
- **Décl.** Profil : sommeil habituel < 6 h, stress élevé ou métier physique lourd (`recoveryLimited`,
  A/session.dart:1792-1795).
- **Action** : aucune proposition de hausse de volume (A/review.dart:1037-1038) ; raisons `adapt.recovery_profile`
  (A/session.dart:1759-1787 ; aussi objectif « perdre du poids », qui ne bloque rien).

### A6.5 Semaines servies telles quelles, échéance proche
- `WeekPolicy` (A/coach.dart:51-119) : `build` = accumulation, intensification, réalisation ; `locked` = ni `build` ni
  maintien (intro, décharge, affûtage, test, compétition, transition) ; `peak` = affûtage, compétition.
- **Semaine verrouillée** : aucune hausse au-delà de la charge écrite (`lockUp`, A/session.dart:1291 ; A/model.dart:2216-2219),
  plage du bloc non étendue, aucune série repère (`_withinBlock` A/session.dart:1742-1754), aucune technique
  d'intensification, aucune série fractionnée ajoutée ; test chargé jamais plus lourd que `startLoadKg` écrit
  (A/coach.dart:2147-2152). Maintien : garde-fous sans pilotage à la hausse.
- **Échéance principale ≤ `coachEventNearDays` jours** : pas de pilotage à la hausse (couloir), pas de série au ressenti,
  pas de série repère, pas de double progression (A/replay.dart:132 ; A/coach.dart:1052-1062, 1174-1188) ; la revue
  bloque hausse de volume et échange d'exercice à ≤ 2 × 14 = 28 jours (A/review.dart:1030, 1039-1040).
- **Invariant C2** : jamais plus de séries que le bloc n'en écrit le jour même, sauf séries fractionnées (A9.4)
  (CONTRAT §11.10). Le volume ne monte que par une proposition de la revue (A11), jamais en affûtage.
- **Param.** `coachEventNearDays` 14 (l. 183).

## A7. Bornes de hausse de charge, de répétitions et de durée

### A7.1 D'une séance à l'autre, mode 0.1 (règle générale)
- Charge totale ≤ dernière × (1 + `maxUpMain`) (mouvement principal), × (1 + `maxUpOther`) (autres),
  × (1 + `maxUpCalibration`) (calibrage = écart-type > `calibrationSd` et < `calibrationSessions` séances) ;
  **un seul cran** permis quand le plus petit cran dépasse la borne (A/model.dart:2220-2271 ; A/session.dart:1900-1924).
- Aucune hausse après échec non prévu, zone douloureuse, bilan bas (A/model.dart:2204-2215). Test : sans plafond de
  hausse, verrous gardés (A/session.dart:1913-1917).
- Sans charge : aucune cible au-dessus de la plus grande série de la dernière séance (CONTRAT §4.1).
- **Param.** `maxUpMain` 0,10 (l. 62) ; `maxUpOther` 0,20 (l. 63) ; `maxUpCalibration` 0,25 (l. 64) ;
  `calibrationSd` 0,06 (l. 57) ; `calibrationSessions` 3 (l. 59) ; `calibrationRirBonus` 1 (l. 58, mode 0.1 seulement).

### A7.2 D'une séance à l'autre, mode coach (charges en % du 1RM)
Charge écrite = part × 1RM estimé (ou 1RM du mouvement de référence), sur la grille (A/coach.dart:974-1051).
1. **Couloir** (semaine `build`, niveau ≥ intermédiaire, pas jour léger ni série à ≤ 2 flammes, pas d'échéance proche,
   pas de douleur, pas de reprise, pas de bilan bas, pas d'excentrique accentué, pas d'entrée graduée) : charge = la plus
   forte de `[part − coachCorridorDown ; part + up]` qui tient la réserve visée en moyenne et RIR visé − 1,5 (≥ 0,5) sur la
   pire série ; `up` = `coachCorridorUp` + `coachCorridorWiden` × séances « faciles au haut du couloir », ≤ `coachCorridorUpMax`,
   0 si exercice incertain, **0 si part écrite ≥ `coachCorridorHeavyShare`** (A/coach.dart:1052-1100).
2. **Hors couloir** (débutant, jour léger, semaine verrouillée, échéance, douleur, reprise, bilan bas) : charge écrite,
   abaissée seulement si elle ne laisse pas RIR visé − 1 (`adapt.rir_cap`, A/coach.dart:1101-1109).
3. **Verrous** (A/coach.dart:1111-1164) : même emplacement, mêmes répétitions qu'à la dernière séance : après échec non
   prévu (ou dernière séance échouée), douleur, bilan bas, ou **répétitions écrites non atteintes** (dernière séance :
   plus grande série < répétitions du schéma) → pas au-dessus de la dernière charge ; sinon hausse ≤
   `coachRiseOf` = `coachRise[niveau]` (× `coachHistoryRiseFactor` si l'exercice sollicite une zone fragile du profil :
   antécédent < 12 mois ou gêne déclarée ≥ 2, A/replay.dart:42-51, 120-125), **un cran toujours permis**
   (A/coach.dart:830-833, 1144-1157). Variante écrite en % d'un autre mouvement : ≤ `maxUpMain` (÷ 2 si fragile).
   Accessoires : plafond doublé (`riseCap` = 2 × rise hors principal/secondaire, A/session.dart:1293-1295 ; utilisé par la
   règle générale A/model.dart:2220-2222).
4. **Schéma changé au même emplacement** : charge totale ≤ base × (1 + rise) × (1 + `coachRepLoadShare` × min(rép. de
   moins, `coachRepGapMax`)), base = dernière séance d'une semaine de charge ; 0 rép. comptée si zone fragile ; un cran
   au moins (A/coach.dart:1209-1235).
5. **Premier passage à un schéma** : ≤ max(charge écrite, +`maxUpMain` (ou un cran) sur la plus lourde barre réussie
   des `attemptRecentDays` derniers jours ou la dernière charge) (A/coach.dart:1236-1255 ; invariant C1).
6. **Double progression « 2 pour 2 »** (seule hausse au-delà du modèle) : même emplacement et schéma, `reached ≥ coachTwoForTwo`,
   aucun verrou, semaine `build` non verrouillée, pas jour léger, pas d'échéance, pas de reprise ni douleur, pas bilan bas,
   part écrite < 0,85, pas test ni excentrique : +1 cran si ce cran ≤ `coachTwoForTwoMaxStep` de la charge totale et
   tient la réserve (A/coach.dart:1174-1199).
7. **Simple d'entraînement** (1 rép., hors test) : ≤ 92 % du 1RM du jour, 85 % un jour de bilan ≥ 1 (A/coach.dart:1268-1282).
8. **Exercice nouveau écrit en % d'un autre mouvement** : 1re séance à `coachNewExerciseShare` × charge écrite, puis
   paliers ≤ 10 % (5 % si fragile) ; sur zone fragile, part ≤ `coachOverloadFragileMax` du 1RM de référence
   (A/coach.dart:1039-1051).
9. **Effort affiché** : jamais plus dur que la cible du bloc (A/coach.dart:1291-1308).
- **Param.** `coachRise` [0,10 ; 0,05 ; 0,05 ; 0,05] (l. 125) ; `coachHistoryRiseFactor` 0,5 (l. 166) ;
  `coachCorridorDown` 0,05 (l. 126) ; `coachCorridorUp` 0,075 (l. 127) ; `coachCorridorWiden` 0,025 (l. 128) ;
  `coachCorridorUpMax` 0,15 (l. 155) ; `coachCorridorHeavyShare` 0,85 (l. 156) ; `coachRepLoadShare` 0,025 (l. 157) ;
  `coachRepGapMax` 4 (l. 158) ; `coachTwoForTwo` 2 (l. 159) ; `coachTwoForTwoMaxStep` 0,10 (l. 160) ;
  `coachWorstSetSlack` 1,5 (l. 161) ; `coachBreachRir` 1 (l. 162) ; `coachNewExerciseShare` 0,6 (l. 138) ;
  `coachOverloadFragileMax` 1,0 (l. 139) ; `attemptRecentDays` 42 (l. 197).

### A7.3 Sans charge (répétitions au poids du corps, mode coach)
- Cible ≤ prévision à RIR = min(RIR visé − 1, `coachDirectGuardRir`) (≥ 0,5) ; verrous échec/douleur/bilan bas comme A1.2 ;
  plafond « zone récente » (A3.3) ; après un échec dans la séance, ≤ dernière série faite (A/coach.dart:1560-1599).
- Plage : le haut servi garde la réserve du bloc (`⌊capacité × (1 − fatigue) − RIR + 0,3⌋`), sans descendre sous le bas
  tant que c'est sûr (A/coach.dart:1818-1830).
- Part d'un test (`percent_benchmark`) : cible = part × maximum, ≤ maximum − RIR ; au-dessus de l'écrit, au plus
  dernière série de l'emplacement + 1 (A/coach.dart:1739-1767).
- Plage étendue (au plus le double, 30 rép.) seulement en semaine `build`, hors assisté, dose plafonnée, zone récente,
  technique, test, jour léger, échéance (A/coach.dart:1768-1792).
- **Param.** `coachDirectGuardRir` 2 (l. 140).

### A7.4 Conseil série par série
- Mode 0.1 : la cible ne change que si l'écart ≥ `adviceGapFlames` flammes ou après un échec ; −`maxDownSet` au plus par
  série (un cran toujours permis), +`maxUpSet` (+`maxUpSetCalibration` en calibrage ou sans cible prévue) ; après un
  échec non prévu : recalcul sans hausse ; **2 échecs non prévus → `stop_exercise`** ; repos conseillé +60 s (≤ 900 s)
  (A/model.dart:2550-2556, 2565-2653, 2684-2685 ; A/advise.dart:405-408).
- Mode coach (A/coach_advice.dart) : verrous `clampLocked` (échec dans la séance, douleur, bilan bas, reprise, dose
  plafonnée → jamais plus lourd ; sans charge, jamais plus long que la ligne précédente) (l. 109-150) ; après un échec non
  prévu : −7,5 % de charge totale (`× 0,925`), gardé sur toutes les séries suivantes (l. 244-305) ; plafond d'effort
  dépassé (`stop_at_rir`, écart ≥ 1 point) : −2,5 % par point, −5 % au plus, un cran au moins (l. 52-68, 553-603) ; deux
  lignes de suite → arrêt après `minSets` (défaut `coachStopMinSets`) (l. 439-454) ; propreté sous le plancher → arrêt,
  étape plus facile conseillée sauf reprise/douleur/dose plafonnée (l. 318-351) ; chute de répétitions ≥ `repDrop` →
  arrêt sauf série dite facile (≥ 3 RIR) (l. 353-369) ; hausse d'un cran seulement si série au haut de la plage, ≥ 2 RIR
  de plus que visé, semaine `build`, niveau ≥ 1, pas de verrou, cran ≤ `coachEasyStepShare` (l. 605-635).
- **Param.** `adviceGapFlames` 2 (l. 68) ; `maxDownSet` 0,15 (l. 65) ; `maxUpSet` 0,05 (l. 66) ; `maxUpSetCalibration`
  0,10 (l. 67) ; `coachBreachCut` 0,025 (l. 163) ; `coachBreachCutMax` 0,05 (l. 164) ; `coachStopMinSets` 2 (l. 185) ;
  `coachEasyGapRir` 2 (l. 165) ; `coachEasyStepShare` 0,05 (l. 189).

## A8. Tests maximaux et tentatives (mode coach)

### A8.1 Conditions pour servir un test
- Jamais un jour de bilan palier ≥ 1, hors jour d'échéance (A/session.dart:975-1001).
- Jamais sur zone douloureuse du jour, zone signalée > 2/10 dans la semaine, zone en reprise, arrêt gardé (A1.6, A3.3).
- **Report** à une autre séance de la même semaine : séance d'un bon jour (palier 0, aucune douleur du jour), ≥ 48 h
  après le jour prévu, test non fait, matériel et lieu du jour, étape de figure acquise, aucune zone à l'arrêt, en
  reprise, douleur du jour ou signalée > 2/10 dans la semaine avec `zoneLevel ≥ 0,5` ; inséré après les échauffements
  (A/session.dart:1003-1092).
- Test de course plus long que la borne de sortie (A10.3) : servi comme course bornée à effort modéré, test reporté.
- Test xRM : charge prévue pour (rép. + RIR du test) au quantile prudent ; semaine verrouillée : ≤ charge écrite ; verrous
  échec/douleur/bilan bas : ≤ dernière charge (A/coach.dart:2135-2172). Rép./maintien max : série ouverte, repère bas =
  prévision prudente (A/coach.dart:2173-2203).

### A8.2 Échelle des tentatives (`attemptLadder`, A/coach.dart:2253-2382)
- Maximum estimé du jour (charge totale) × (1 + `coachTaperGain`) si la semaine du jour ou la précédente est d'affûtage
  ou de compétition, **avant la 1re barre seulement** (A/coach.dart:2093-2095 ; A/event_day.dart:137-140 ;
  A/coach_advice.dart:196-197).
- Réductions : × (1 − `attemptLowHealthShare` × palier du bilan) ; × (1 − `attemptLowHealthShare`) de plus si douleur
  (`pain`), échec récent (`previous_failure`) ou pesée (`weigh_in`) (l. 2270-2277).
- `attemptProbability(total, estimate, relSd)` = Φ((ln estimate − ln total) / max(relSd, 0,01)), relSd = écart-type du
  1RM du jour (estimation + effet de jour) (l. 2236-2242 ; `dayRelSd` l. 2064-2067).
- **Ouverture** : plus lourde charge de la grille ≤ `attemptOpenerShare` × estimation avec probabilité ≥
  `attemptOpenerProbability` ; si une barre réussie dans les 42 derniers jours existe, est plus légère et pèse
  ≥ 0,85 × estimation (charge totale), l'ouverture = cette barre (l. 2325-2336).
- **2e** : probabilité ≥ `attemptSecondProbability` ; **3e** : ≥ `attemptThirdProbability` (objectif « plus gros total »),
  `attemptSecureProbability` (assurer un total ; simulation de tentatives), `attemptRecordProbability` (record ; barre
  visée tentée si sa probabilité ≥ 0,35) (l. 2301-2349).
- **Sauts** après une réussite : 2e ≤ +5 %, 3e ≤ +3 % de charge totale, et ≤ +5 kg de charge externe (l. 2350-2362).
- **Jamais décroissantes** ; après une barre manquée, la même barre ; au moins + le saut minimal de la compétition après
  une réussite (l. 2321-2324, 2363-2368 ; invariant C4).
- Flammes affichées : 7, 9, 10 (A/coach.dart:2121). Échauffement du jour d'échéance : 40, 55, 70, 80, 87 % de l'ouverture.
- **Param.** `attemptOpenerShare` **0,91** (l. 190) ; `attemptOpenerProbability` 0,95 (l. 191) ;
  `attemptSecondProbability` 0,80 (l. 192) ; `attemptThirdProbability` 0,50 (l. 193) ; `attemptSecureProbability` 0,70
  (l. 194) ; `attemptRecordProbability` 0,35 (l. 195) ; `attemptLowHealthShare` 0,02 (l. 196) ; `attemptRecentDays` 42
  (l. 197) ; `coachTaperGain` 0,02 (l. 171).
- **[ÉCART]** CONTRAT §11.6 et tableau §11.11 : ouverture « au plus 93 % » ; le code (et CONTRAT §11.15) : **91 %**.
  CONTRAT §11.6 ne dit pas la condition « barre récente ≥ 85 % de l'estimation ».

### A8.3 Séries repères (mesure de la capacité)
- Série repère, série de tête repère, tenue repère : seulement si rien n'a mesuré depuis `coachProbeDays` jours, et
  **jamais** en semaine verrouillée, échéance proche, jour léger, bilan bas, zone douloureuse ou récente, reprise, dose
  plafonnée, après un échec (A/coach.dart:1372-1395, 1504-1553, 1933-1986). Réserve visée `benchmarkRir` (1,5), **2 pour
  un débutant** (A/coach.dart:1535) ; +`benchmarkExtraReps` rép. ouvertes (sans charge : jusqu'au double du haut) ; tête
  repère : +`coachTopProbeReps`, hors semaine de réalisation ; tenue repère : jusqu'à la durée écrite, dans la borne
  tendons (A9.1).
- **Param.** `coachProbeDays` 14 (l. 141) ; `benchmarkRir` 1,5 (l. 70) ; `benchmarkExtraReps` 6 (l. 71) ;
  `coachTopProbeReps` 3 (l. 142) ; mode 0.1 : `benchmarkMaxRir` 3 (l. 74), `benchmarkEveryDays` 6 (l. 72).

## A9. Tendons, techniques, assistance, figures

### A9.1 Tenues en bras tendus et en appui (`tendonLoaded`)
- **Décl.** Exercice en mode tenue de famille `figureStatique` (A/coach.dart:1435-1437), hors test.
- **Action, par tenue** : secondes servies ≤ `max(⌊dernière × (1 + coachHoldRise[niveau])⌋, dernière + coachHoldRiseSlackSeconds)`,
  dernière = plus grande tenue de la dernière séance du même emplacement ; plancher : `⌊meilleur maintien récent × coachHoldMaxFloorShare⌋`
  (meilleur maintien depuis la dernière coupure ≥ 14 jours et dans les `coachHoldBestDays` jours) (A/coach.dart:1845-1866).
- **Action, temps total de l'emplacement** : Σ secondes ≤ `max(⌊total × (1 + rise)⌋, total + 1)` (plancher 55 % du meilleur
  × nombre de tenues) ; au-delà, chaque tenue raccourcie à total ÷ n (« un seul changement à la fois ») (A/coach.dart:1895-1929).
  Raison `adapt.tendon_load` (zone la plus contrainte parmi coude, épaule, poignet).
- **Maintiens en général** : ≤ `coachHoldMaxShare` × maximum du jour (A/coach.dart:1463-1467) ; en semaine `build`, une
  durée écrite < `coachHoldEasyShare` × maximum mesuré (≤ 28 jours) monte vers `coachHoldUsefulShare` × maximum, par les
  paliers ci-dessus (A/coach.dart:1793-1813).
- **Param.** `coachHoldRise` [0,20 ; 0,15 ; 0,10 ; 0,10] (l. 167) ; `coachHoldRiseSlackSeconds` 1 (l. 168) ;
  `coachHoldMaxFloorShare` 0,55 (l. 169) ; `coachHoldBestDays` 28 (l. 170) ; `coachHoldMaxShare` 0,75 (l. 131) ;
  `coachHoldEasyShare` 0,4 (l. 132) ; `coachHoldUsefulShare` 0,5 (l. 133).
- Pas de borne sur le **nombre de séances bras tendus par semaine** ni sur le passage de levier dans kalis_adapt : ce
  sont des critères du banc (B4, B5) que kalis_plan respecte à l'écriture.

### A9.2 Techniques avancées (`techniqueAccessLevel`, A/coach.dart:123-142)
- Niveau d'accès (0 débutant, 1 intermédiaire, 2 avancé, 3 élite) : **1** = `top_set_backoff`, `drop_set`, `amrap`,
  `pyramid`, `ladder`, `density`, `for_time` ; **2** = `cluster`, `rest_pause`, `myo_reps`, `accentuated_eccentric`,
  `contrast`, `wave` ; autres 0. Niveau inconnu au profil → servi comme intermédiaire (A/session.dart:954-955 ;
  A/replay.dart:130).
- **Action** : technique au-dessus du niveau → `standardEquivalent` (séries classiques au même travail approché :
  paliers → séries au nombre médian de rép. ; densité/contre-la-montre → 3 séries d'un quart ; cluster → 2/3 du total
  d'une traite) ; raison `plan.technique_withheld` cause `level` (A/session.dart:951-973, 1622-1686).
- **Techniques qui intensifient** (`rest_pause`, `myo_reps`, `drop_set`, `accentuated_eccentric`, `amrap`, `cluster`,
  `wave`, `contrast`, A/coach.dart:147-155) : non servies sur zone douloureuse, bilan palier 2, semaine verrouillée ;
  excentrique accentué non servi à ≤ `coachEccentricEventDays` jours d'une échéance ni sur zone fragile ; charge
  d'excentrique ≤ 110 % du 1RM (A/coach.dart:754-790, 1065-1069).
- **Param.** `coachEccentricEventDays` 10 (l. 184).

### A9.3 Élastique / assistance (mode coach)
- Plage du bloc gardée ; progression par l'assistance. **Un cran de moins** seulement si (deux séances de suite au même cran
  au haut de la plage, ou première série dite ≥ 2 rép. plus facile, ou une séance entière dite ≥ `coachAssistWideRir`
  plus facile) **et** ≥ `coachAssistMinDays` jours depuis le dernier changement, semaine `build`, pas d'échéance, pas de
  verrou. **Un cran de plus** seulement après un échec ou le bas de la cible manqué deux séances de suite au même cran
  (A/coach.dart:1987-2030). Changement de cran : capacité attendue × `coachAssistStepShare`, incertitude +`coachAssistStepSd`
  (A/model.dart:1539-1542).
- **Param.** `coachAssistMinDays` 7 (l. 172) ; `coachAssistWideRir` 2 (l. 229) ; `coachAssistGapRir` 2 (l. 134) ;
  `coachAssistStepShare` 0,75 (l. 135) ; `coachAssistStepSd` 0,25 (l. 136).

### A9.4 Séries fractionnées (seul cas où plus de lignes que le bloc)
- **Décl.** Répétitions sans charge, standard, hors test, assisté ou maintien ; le bas de la plage ne laisse pas la réserve.
- **Action** : rép. par série = min(⌊capacité − RIR + 0,3⌋, cible sûre), nombre = ⌈séries × bas ÷ rép.⌉, au plus 2 × séries
  (3 au moins) ; **aucune série ajoutée** après échec, douleur, bilan bas, dose plafonnée, semaine verrouillée, technique
  écrite, calibrage, ou sans mesure du maximum dans les 28 derniers jours (A/coach.dart:1672-1725).

### A9.5 Figures (étapes)
- Étape dont le passage n'est pas acquis : remplacée par l'étape en cours (qui suit les règles de douleur et d'arrêt, sinon
  retirée) (A/session.dart:875-949). Passage non acquis si une douleur active > `skillPainMax` sollicite l'étape
  (`zoneLevel ≥ 0,5`) (A/skills.dart:116-127). Ancienneté déclarée → `skillTenureWeeks`.
- **Param.** `skillPainMax` 3 (l. 202) ; `skillSessions` 3 (l. 198) ; `skillDownSessions` 2 (l. 199) ; `skillDownShare` 0,5
  (l. 200) ; `skillTenureWeeks` [2, 8, 18, 30] (l. 201).

## A10. Endurance et conditionnement (deux modes, `enduranceConduct` vrai, l. 228)
Principe : jamais plus long, plus loin, plus de répétitions ou de séries, ni plus dur que l'écrit (invariant E1). Durées
arrondies vers le bas. A/session.dart:2476-2872.

### A10.1 Reprise après coupure
- **Décl.** Aucune séance depuis ≥ `enduranceResumeShortDays` / ≥ `enduranceResumeLongDays` jours.
- **Action** : course, cardio, conditionnement à `enduranceResumeShort` / `enduranceResumeLong` de l'écrit ; mobilité et
  échauffement non réduits (A/session.dart:2569-2643). Pas de cumul avec A6.1 ni A5 (A/session.dart:1121-1130, 1152-1160).
- **Param.** 7 (l. 212) / 0,7 (l. 213) ; 14 (l. 214) / 0,5 (l. 215).

### A10.2 Jour sans
- **Décl.** Bilan palier ≥ 1 ; ou douleur du bas du corps (hanche, cuisse, genou, bas de jambe, cheville) ≥ `enduranceLegPain`
  (dernière intensité, ≤ 14 jours) ; ou une course des `enduranceHardDays` derniers jours notée ≥ `enduranceHardMargin`
  flammes au-dessus de la cible (sans cible : ≥ `enduranceHardFlames` + 1 = 9) (A/session.dart:2579-2613 ;
  A/endurance.dart:230-245).
- **Action** : séance de qualité (RIR visé ≤ `enduranceQualityRir`, allure/intensité, test, ou id de fractionné/seuil/côtes/
  sprint, A/endurance.dart:290-300) → **course facile** de la durée de travail écrite, à `enduranceEasyRir`, sans allure ni
  cibles ; impossible → séance retirée (A/session.dart:2647-2697). Palier 2 : durée course et cardio × `enduranceBadDayShare`
  (A/session.dart:2698-2713). Invariant E3 : aucune séance de qualité un jour de bilan bas.
- **Param.** `enduranceLegPain` 3 (l. 223) ; `enduranceHardDays` 3 (l. 218) ; `enduranceHardMargin` 2 (l. 217) ;
  `enduranceHardFlames` 8 (l. 219) ; `enduranceQualityRir` 3 (l. 220) ; `enduranceEasyRir` 5 (l. 221) ;
  `enduranceBadDayShare` 0,7 (l. 216).

### A10.3 Sortie bornée (pic de durée)
- **Décl.** ≥ `enduranceSpikeMinRuns` courses dans les `enduranceSpikeDays` jours précédents.
- **Action** : course du jour (somme des lignes de course, échauffement exclu) ≤ plus longue course de la fenêtre ×
  (1 + `enduranceSpike`) ; réduction proportionnelle puis une fraction de moins ; test plus long → course bornée à ≤ 6 flammes
  (`easyFlames + 1`), test reporté (A/session.dart:2716-2813). Invariant E2.
- **Param.** `enduranceSpike` 0,10 (l. 209) ; `enduranceSpikeDays` 30 (l. 210) ; `enduranceSpikeMinRuns` 3 (l. 211) ;
  `enduranceRunSpeed` 2,6 m/s si aucune allure au journal (l. 222).
- Pas de borne de hausse **hebdomadaire** de durée de course ni de sortie longue dans kalis_adapt (CONTRAT §12.1 r. 3 :
  la borne des 30 jours remplace la règle des 10 %/semaine). kalis_plan écrit la sortie longue (`coachRunLongRise` 0,1,
  P/prescribe.dart:653).

### A10.4 Conditionnement mis à l'échelle (jours durs consécutifs)
- **Décl.** Jour sans (cause ≠ course dure seule) ou ≥ `wodHardStreak` jours durs de conditionnement de suite juste avant
  (ligne de conditionnement notée ≥ 8 ; un jour sans séance ne rompt pas la suite, deux oui ; fenêtre 7 jours)
  (A/session.dart:2815-2819 ; A/endurance.dart:249-269).
- **Action** : répétitions ou durée × `wodScaleShare`, une flamme de moins sur l'effort visé (A/session.dart:2820-2846).
- **Param.** `wodScaleShare` 0,75 (l. 224) ; `wodHardStreak` 2 (l. 225).

### A10.5 Fatigue croisée
- **Décl.** Course notée ≥ 8 flammes la veille. **Action** : −1 flamme (≈ +0,5 RIR) sur les exercices modélisés du bas du
  corps (hors test, échauffement, cible ≤ 1 flamme) (A/session.dart:2848-2871).
- Fatigue : 600 s d'effort = une série de travail, 6 au plus par ligne (`enduranceFatigueSeconds` 600 l. 226,
  `enduranceFatigueMax` 6 l. 227).

## A11. Revue hebdomadaire : propositions et leurs garde-fous
- **Déblocage** (A/review.dart:100-130) : charges/rép./épargne de zone dès le 1er jour ; volume et décharge ≥ `volumeMinWeeks`
  (2) semaines de données ; échange ≥ `swapMinWeeks` (4) ; restructuration de séance 1 bloc + 4 semaines ; de bloc 2 blocs +
  8 semaines. Confiances minimales 0,5 / 0,65 / 0,75 / 0,8 / 0,85 (l. 110-114). Refus : rien pendant `refusalQuietDays` 28
  (l. 115) ; échange : pas de nouvel échange pendant `swapQuietDays` 21 (l. 116).
- **Volume +1 série** (A/review.dart:719-741) : pente du groupe ≤ 0 avec probabilité ≥ 0,7, résidu ≥ −1 %, forme ≥ 0,6,
  assiduité ≥ 80 %, séries hebdo du groupe < haut de la bande de kalis_plan (`volumeBandsByLevel` = (4,10), (8,16), (12,20),
  (12,20), kalis_plan/lib/src/context.dart:433-438), **et chaque groupe majeur de l'exercice reste ≤ `coachWeeklyCeilingSets`
  = [12, 20, 25, 30] sur chaque semaine modifiée** (`_upFits`, A/review.dart:1467, 1507-1546). Appliquée à toutes les semaines
  ≥ semaine suivante sauf décharge et test ; séries ∈ [1 ; 20] ; pas sur vagues/pyramide/échelle/densité/contre-la-montre
  (A/review.dart:1572-1601). **Deux propositions de volume au plus par revue** (l. 747). Bloquée (mode coach) si semaine
  suivante non `build`, récupération réduite, échéance ≤ 28 jours (l. 1032-1043).
- **Volume −1 série** : résidu ≤ −2 % et forme < 0,6 (l. 703-718).
- **Programme importé** (> 6 semaines) : jamais restructuré sauf `restructureImported` (A/review.dart:754-755).

## A12. Débutants, âge, assistance : ce que kalis_adapt fait en propre
- Débutant (niveau 0) : pas de couloir (charge écrite servie) (A/coach.dart:1058) ; hausse ≤ 10 % à schéma égal (`coachRise[0]`) ;
  série repère à 2 RIR (A/coach.dart:1535) ; pas de cran de plus sur série facile au conseil (A/coach_advice.dart:619) ;
  techniques de niveau ≥ 1 retirées. **Aucune règle « pas d'échec chez le débutant » dans kalis_adapt** : le RIR vient du bloc
  (kalis_plan : plancher 2 RIR pour débutant et mode prudent, P/prescribe.dart:1064-1071) ; c'est un critère du banc (B9).
- Âge, IMC, questionnaire santé : **aucune lecture dans kalis_adapt** (recherche `healthScreening`, `birthYear` : aucun
  résultat dans A/).

## A13. Règles de kalis_plan contrôlées par le banc (pour mémoire, génération du bloc)
- **Mode prudent** `cautious` = questionnaire absent ou issue ≠ `standard`, ou âge ≥ 65, ou âge < 18 (P/athlete.dart:957-962) :
  tout exercice à impact écarté (P/athlete.dart:1076, 1495-1497) ; intensité ≤ 85 % du 1RM (P/prescribe.dart:1344-1348) ;
  plancher 2 RIR (P/prescribe.dart:1070) ; pas de test 1RM à l'échéance, test 3RM à 85 % (P/prescribe.dart:4232, 4304-4308) ;
  pas de séance de qualité en course (P/general.dart:1145-1147) ; musculation/CrossFit → programme santé (P/general.dart:228-241).
- Débutant d'IMC ≥ 30 : pliométrie, corde, balistique, haltérophilie écartées (P/athlete.dart:1075, 1498-1503).
- Âge ≥ 60 : volume × 0,8 ; âge ≥ 40 : montée lente (`slowRamp`) (P/athlete.dart:970-972, 1073). Cumul des réductions ≤ 40 %
  (P/athlete.dart:1021-1030).
- Note `clearance_first` (avis médical avant la 1re séance) si issue `cautious` ou gêne déclarée ≥ 5 (P/prescribe.dart:8232-8236).
- **Première semaine** : rép. au poids du corps ≤ 4 × maximum par mouvement (`coachFirstWeekRepsShare`, P/prescribe.dart:589,
  6480-6495) ; hausse hebdo de ce volume ≤ 15 % (`coachVolumeRise`, l. 571), 10 % en bloc de reprise (`coachRepriseRise`, l. 578) ;
  charge de départ ≤ 67,5 % du 1RM sans historique (P/prescribe.dart:6948-6962) ; reprise après ≥ 10 semaines d'arrêt :
  séries dures × 0,5 ; 0,57 ; 0,66 ; 0,76 (P/prescribe.dart:6668-6680). Hausse de charge hebdo ≤ `coachLoadRise`
  [0,10 ; 0,05 ; 0,05 ; 0,05] (P/prescribe.dart:617) — **égale à la borne du banc** (marge possiblement nulle, cf. B1).
- **[ÉCART]** Le banc lit `cautious` seulement si `healthScreening.outcome == 'cautious'` (B/safety.dart:931-934) ; kalis_plan est
  plus large (absent, ≠ standard, âge). L'âge du banc = 2026 − année de naissance (B/safety.dart:930, 970).

---

# Partie B — Critères de sécurité calculables du banc (`B/safety.dart`)

## B0. Grandeurs (`B/analysis.dart`)
- **Semaines** : pour chaque bloc, chaque semaine de `pass2.weeks`, rang global, jusqu'à `horizonWeeks` (l. 504-565). Jour :
  budget `minutesBudget` et jour ISO lus dans `pass1.days[dayIndex]` (l. 522-527).
- **Semaine allégée par nature** `isLight` : `kind` ∈ {intro, deload, test} (l. 460-463). `WeekKind` vient de `pass2`.
- **RIR d'un item** = `Flames.toRir(targetFlames)`, `null` sans flammes (l. 171-174).
- **Série dure d'un item** = `p.sets` si renforcement (`traits.kind.isResistance`), pas échauffement, et (RIR `null` ou
  RIR ≤ 4, soit **flammes ≥ 3**) ; sinon 0 (l. 47-48, 199-208).
- **Séries créditées à un groupe** = séries dures × `creditOf(g)` ÷ 2 (crédit 2 muscle principal → 1 ; 1 secondaire → 0,5)
  (l. 212-213). Groupes **majeurs** : tous sauf avant-bras, adducteurs, trapèzes supérieurs (kalis_plan/lib/src/traits.dart:17-62).
- **Charge totale** = `startLoadKg` + fraction de poids du corps du catalogue × poids de corps (75 kg par défaut) ;
  `null` sans `startLoadKg` (l. 13, 216-226). **`percentOfOneRm` et `intensity` ne sont lus par aucun critère de sécurité.**
- **Secondes de tenue** = `sets × secondsHigh` (sinon `secondsLow`) si item en secondes et renforcement (l. 256-257).
- **Famille bras tendus** : back lever (racine ou id `cs-back-lever…`) → poussée ; `cs-tenue-menton…` → aucune ; sinon
  schéma `figureStatiquePoussee` / `Tirage` / `Mixte` (l. 229-253).
- **Durée estimée d'un item** = 45 s + séries × effort + (séries − 1) × repos (`restSeconds`, défaut 60) ; effort = `repsHigh` × 3 s
  × côtés (2 si unilatéral), ou `secondsHigh` (× côtés si renforcement), ou distance ÷ allure (record × 0,9, sinon 2,5 m/s),
  ou calories × 6, ou 30 s (l. 261-277). Séance = Σ + 300 s s'il y a du renforcement (l. 334-342).
- **Minutes de conditionnement** = Σ durées des items non renforcement (l. 403-411).
- **Champs de l'item lus** : `sets`, `repsLow/High`, `secondsLow/High`, `targetFlames`, `startLoadKg`, `restSeconds`,
  `distanceMeters`, `calories`, `kind` (work/test/warmup), `format`, `technique.kind`, `test.kind`, `reasons` (note
  `event_day`), `exerciseId`, `slotId` ; `groups[].format` du jour.

## B1. `charge_trop_vite` (l. 321-358)
- **Mesure** : pour la clé `dayIndex | slotId | exerciseId`, charge totale semaine w ÷ charge totale semaine w−1 − 1, seulement
  si la même clé existe la semaine **immédiatement** précédente et a le **même `repsHigh`** (`repsHigh ?? repsLow ?? 0`). Items
  ignorés : sans `startLoadKg`, charge totale ≤ 0, tests.
- **Seuil** `loadRise` [0,10 ; 0,05 ; 0,05 ; 0,05] (débutant → élite). Violation si hausse > seuil + 1e-9.
- **Exceptions** : schéma de répétitions différent ; semaine non consécutive ; test.

## B2. `volume_trop_vite` (l. 360-420, `rampLimit` l. 269-303)
- **Mesure** : séries dures créditées par grand groupe et par semaine.
- **Seuil 1 semaine** (w ≥ 1) : référence = plus haut des 3 semaines précédentes ; si l'une est une semaine de charge, réf =
  max(plus haute de charge, plus haute allégée), limite = max(réf × 1,20 ; réf + 2). Si les 3 sont allégées : limite =
  max(réf × 1,20 ; réf + 2 ; réf ÷ 0,5).
- **Seuil 2 semaines** (si le seuil 1 tient, w ≥ 2, semaines w, w−1, w−2 toutes de charge, série[w−2] > 0) : limite =
  max(série[w−2] × 1,30 ; série[w−2] + 4).
- **Param.** `volumeRise` 0,20 ; `volumeRiseSets` 2 ; `volumeRiseTwoWeeks` 0,30 ; `volumeRiseTwoWeeksSets` 4 ; `rampShare` 0,5
  (l. 90-105). Identiques à tous les niveaux.

## B3. `plafond_volume` (l. 421-469)
- **Mesure** : séries dures créditées par grand groupe et par semaine. Violation (un constat par groupe) si une semaine > plafond
  [12 ; 20 ; 25 ; 30]. Élite : en plus, une semaine où **plus de 2** groupes dépassent 25 → constat.

## B4. `tendon_figures` (l. 610-665)
- **Jours** : nombre de séances de la semaine contenant au moins un item de la famille > [2 ; 3 ; 3 ; 4] → constat.
- **Hausse** (w ≥ 1) : secondes de tenue de la famille > `rampLimit` (rise [0,20 ; 0,15 ; 0,10 ; 0,10], tolérance 5 s) **et**
  référence (max des 3 semaines précédentes, toutes natures) > 0.
- **Exceptions** : famille sans tenue dans les 3 semaines d'avant (pas de référence) ; tenue menton exclue.

## B5. `levier_trop_tot` (l. 666-706)
- **Mesure** : première semaine d'apparition de chaque exercice bras tendus, par racine de chaîne. Constat si un exercice plus
  difficile (`difficulty`) de la même racine apparaît 1 à N−1 semaines après un plus facile, N = [12 ; 8 ; 8 ; 6], sauf s'il est
  connu du profil (record > 0 ou `knownExerciseIds`).

## B6. `technique_sans_prerequis` (l. 183-206, 487-521)
- Codes de `format` ou `technique.kind` (hors `standard`) : `top_set_backoff`, `drop_set`, `amrap` ≥ intermédiaire ;
  `cluster`, `rest_pause`, `myo_reps`, `accentuated_eccentric`, `contrast`, `wave` ≥ avancé ; autres codes libres.
  Exercices par nature (id contient) : `supramaximal`, `partielle-haute`, `partiel-haut`, `partiel-surcharge`,
  `isometrie-lestee` ≥ avancé ; `chaines` ≥ intermédiaire. (Les formats d'enchaînement du jour ne sont pas contrôlés ici.)

## B7. `exercice_trop_avance` / `exercice_non_acquis` (l. 472-559)
- Trop avancé : item de renforcement, exercice non connu, niveau catalogue > niveau profil + 1.
- Non acquis : profil déclare l'exercice non su (record ≤ 0 ou `cannotDoExerciseIds`) et l'item est cet exercice, ou un palier non
  assisté de même racine et de difficulté ≥, ou un exercice qui l'a en prérequis.

## B8. `contre_indication` (l. 562-608)
- Pour chaque blessure du profil ayant une articulation du catalogue (épaule, coude, poignet, lombaires, genou, hanche, cheville ;
  autres zones non contrôlées) : contrainte forte et gêne ≥ 4 ; ou contrainte moyenne et gêne ≥ 6 ; ou contrainte forte, zone
  fragile (antécédent < 12 mois ou gêne ≥ 2), item de renforcement hors test et **RIR < 1** (flammes 10 ; sans flammes, RIR pris = 5).
  Un constat par exercice et par blessure.

## B9. `echec_risque` (l. 708-770)
- Items de renforcement, hors test et échauffement, avec flammes. (i) RIR < 2 (**flammes ≥ 8**) sur mouvement à risque élevé
  (`isHighRisk` l. 212-234 : équilibres, muscle-up, figures statiques et dynamiques, freestyle, haltérophilie, poussée aux
  anneaux, squat/développés à la barre). (ii) Débutant : RIR ≤ 0 (flammes 10) sur tout exercice. (iii) Débutant : Σ `sets` des
  items à RIR ≤ 1 (flammes ≥ 9) sur risque élevé ou modéré (`isModerateRisk` l. 238-247 : tirage vertical, dips/poussée
  verticale basse, lesté, barre polyarticulaire) ≥ 2 dans la semaine.

## B10. `seance_trop_longue` (l. 772-804)
- Durée estimée (B0) > `minutesBudget` × 1,15 + 3 min. Exception : jour comportant un test `timeTrial` avec raison
  `note: event_day`.

## B11. `decharge_absente` (l. 806-846)
- Semaine « allégée » si séries dures totales ≤ 0,70 × plus haut des 3 semaines précédentes (sans référence : `isLight`).
  Constat (une fois par série) quand la suite de semaines non allégées dépasse [12 ; 7 ; 6 ; 6].

## B12. `affutage_absent` (l. 848-898)
- Échéance A la plus proche, semaine `at = weeksOut − 1`. Au-delà du programme → constat. Si `at ≥ 2` : volume = séries dures
  totales (minutes de conditionnement si aucune série dure dans les 6 semaines d'avant) ; baisse = 1 − volume[at] ÷ pic des
  semaines `at−6 … at−1` ; constat si baisse < [0,30 ; 0,30 ; 0,40 ; 0,40].

## B13. `reprise_trop_dure` (l. 900-927)
- Profil avec coupure ≥ 2 semaines : tout item de renforcement de la **semaine 0**, hors échauffement et test, à RIR < 3
  (**flammes ≥ 6**) → constat par exercice.

## B14. `impact_deconseille` (l. 929-965)
- Âge (2026 − naissance) ≥ 65 ou questionnaire `cautious` : tout item dont `traits.impact` (pliométrie, sprint, haltérophilie,
  corde, mode explosif, kalis_plan/lib/src/traits.dart:481-486). Débutant d'IMC ≥ 30 : schémas pliométrie, corde, balistique,
  haltérophilie.

## B15. Sensibilité aux modifications d'un moteur (par rapport au programme écrit par kalis_plan)

Préalable : le banc ne voit une modification que si elle est écrite **dans les blocs** (programme évolué). Les séries
sont entières : ±15 % sur 2 à 6 séries = 0 ou ±1 série selon l'arrondi (±17 % à ±50 %). Les flammes sont entières : ±5 %
ne change rien (arrondi) ou change d'une flamme (±10 % à ±50 %). Les « marges typiques » ci-dessous sont déduites du code
(bornes de kalis_plan vs bornes du banc), **non mesurées** sur les profils du banc.

| Critère | (a) séries ±15 % | (b) intensité ±5 % | Grandeur touchée et marge typique |
| --- | --- | --- | --- |
| `charge_trop_vite` | non (sets non lu) | **oui** si `startLoadKg` change ; non si seul `percentOfOneRm`/`intensity` change ; non si `repsHigh` change (comparaison sautée) ; flammes : non | kalis_plan écrit jusqu'à la même borne (`coachLoadRise` = `loadRise`, P/prescribe.dart:617) : marge **0 à quelques points**. +5 % sur w (w−1 inchangée) ou −5 % sur w−1 ajoute ≈ 5 points : violation dès qu'il y avait une hausse prévue (intermédiaire et plus) ; débutant : marge ≈ 5–10 points |
| `volume_trop_vite` | **oui** (une semaine modifiée par rapport aux 3 d'avant ; et règle 2 semaines) | oui seulement si les flammes passent de 3 à 2 ou de 2 à 3 (série dure ↔ non dure) | Tolérance absolue +2 séries (+4 sur 2 semaines) : sur un groupe à 8–12 séries, ±1 série tient si kalis_plan n'est pas déjà à la borne ; kalis_plan s'audite contre la même règle (P/audit.dart) → marge possiblement nulle. Ne modifier que de façon **uniforme** sur toutes les semaines (ratio inchangé) ou en baisse |
| `plafond_volume` | **oui** en hausse | idem flammes 2↔3 | Plafond 12/20/25/30 ; bandes de kalis_plan (10/16/20/20) laissent 2–10 séries de marge, mais un groupe porté par plusieurs exercices peut être près du plafond. Kalis_adapt vérifie le plafond avant +1 série (A11) |
| `tendon_figures` (secondes) | **oui** (secondes = séries × durée) | **oui** (`secondsHigh` ±5 %) | Hausse admise 20/15/10/10 % ou +5 s ; kalis_plan suppose un progrès du maintien max de 5/4/3/2 %/sem. au plus (`coachPlannedHoldRate`, P/athlete.dart:291-292) → marge ≈ 5–15 points si les durées écrites suivent ce rythme (non vérifié) ; +15 % de séries isolé viole chez avancé/élite (10 %) sauf total ≤ 50 s (+5 s) |
| `tendon_figures` (jours) | non | non | — (changer de jour ou ajouter une séance : oui) |
| `levier_trop_tot` | non | non | — (changer d'exercice : oui) |
| `technique_sans_prerequis` | non | non | — (ajouter une technique : oui) |
| `exercice_trop_avance`, `exercice_non_acquis` | non | non | — (échanger un exercice : oui) |
| `contre_indication` | non | **oui** si les flammes passent à 10 (RIR 0) sur contrainte forte d'une zone fragile | Marge = écart à 10 flammes (kalis_plan : plancher 2 RIR sur zone à ménager) |
| `echec_risque` | oui pour (iii) débutant (Σ séries à RIR ≤ 1 ≥ 2) si de telles séries existent | **oui** si flammes 7→8 sur risque élevé ; débutant 9→10 ou ≥ 9 | kalis_plan : plancher 2 RIR (7 flammes) sur risque élevé, débutant, prudent (P/prescribe.dart:1064-1071) → marge **0 flamme** sur ces mouvements : toute hausse d'une flamme viole |
| `seance_trop_longue` | **oui** (+15 % de séries ≈ +15 % de durée de l'item) | faible (+5 % de rép./secondes sur la part effort seulement) | Tolérance 15 % + 3 min ; marge inconnue (dépend du remplissage du budget par kalis_plan) |
| `decharge_absente` | **oui** (+15 % dans la semaine allégée, ou −15 % dans les semaines de référence) | flammes 2↔3 | Décharge kalis_plan à 0,6 du volume → +15 % = 0,69 ≤ 0,70 : marge ≈ 1 point (arrondi des séries défavorable) |
| `affutage_absent` | **oui** (+15 % en semaine d'échéance, ou −15 % sur le pic) | flammes 2↔3 ; minutes de conditionnement (±5 % de durée/distance) si programme sans renforcement | Baisse exigée 30/40 % ; marge = baisse écrite − exigée ; +15 % sur une semaine à −40 % donne −31 % |
| `reprise_trop_dure` | non | **oui** si flammes ≥ 6 en semaine 0 après ≥ 2 semaines d'arrêt | Marge = écart à 6 flammes |
| `impact_deconseille` | non | non | — (ajouter un exercice à impact : oui) |

**(c) « Rien d'autre »** (charges, séries, flammes, durées, exercices, jours inchangés dans les blocs) : aucun critère ne peut
changer ; les constats éventuels sont ceux du programme de kalis_plan.

Règles pratiques pour Koach : ne jamais écrire dans le bloc une hausse de `startLoadKg` d'une semaine à la suivante à `repsHigh`
égal ; ne jamais monter `targetFlames` ; ne monter séries ou secondes que sur toutes les semaines à la fois et sous les plafonds
recalculés ; garder les modifications du jour dans la séance servie (non vue par `safety.dart`), sous les règles de la Partie A.

---

# Partie C — Règle → où l'implémenter

S = prescription de la séance ; C = conseil série par série ; R = revue hebdomadaire ; G = génération / modification du bloc.

| Règle | S | C | R | G |
| --- | --- | --- | --- | --- |
| A1.1 Seuil douleur > 3, zone active 14 j, zone bloquante | x | x | x | |
| A1.2 Pas de hausse sur zone douloureuse, +1 RIR, lignes gelées | x | x | | |
| A1.3 Retrait/remplacement (4 forte, 5 moyenne ; 7 en 0.1) | x | | | |
| A1.4 Allègement 4/10 moyenne (×0,6 séries, +1 RIR) | x | | | |
| A1.5 Remplaçant : ≤ difficulté, ≥ 0,45, ≤ zoneLevel, 3 RIR, ≤ 70 % 1RM | x | | | |
| A1.6 Test retiré sur zone douloureuse / > 2/10 dans la semaine | x | | | |
| A1.7 Proposition épargner la zone (2 séances > 3) | | | x | x |
| A2.1 Déclenchement de l'arrêt (14 j ≥ 3 ; 7 j ≥ 5 ; retour 84 j ; 3 séances > 3) | x | x | x | |
| A2.2 Retrait des mouvements provocants, premier palier, escalade 14 j, renvoi hebdomadaire | x | | x | x |
| A2.3 Course retirée (arrêt bas du corps), retour à 50 % | x | | | |
| A3 Reprise graduée (50 % +10 %/sem., plancher 40 %, 67,5 % + 2,5 %/palier, 3 RIR, arrêt gardé, recul) | x | x | | x |
| A3.3 Hausse ≤ 10 %/séance sur zone récente | x | x | | |
| A4.1 Première gêne du poignet → appui neutre | x | | | |
| A4.2 Arrêt du poignet (parallettes/poignées, charge externe retirée, poignet chaud) | x | | | x |
| A4.3 Poignet sensible : dose plafonnée | x | x | | |
| A5 Bilan : paliers 1/2 (+0,5/+1 RIR, pas de hausse, −1 série, ≥ 3 RIR, pas de test) | x | x | | |
| A6.1 Coupure ≥ 14 j : séries ×0,8 | x | | | |
| A6.2 Alerte de surmenage (−40 % lignes, 7 j) | x | | x | |
| A6.3 Décharge anticipée (×0,6 séries, +2 RIR) | | | x | x |
| A6.4 Récupération réduite : pas de hausse de volume | | | x | |
| A6.5 Semaines verrouillées, échéance ≤ 14 j (≤ 28 j pour la revue), C2 | x | x | x | |
| A7.1/A7.2 Bornes séance à séance (10/5/5/5 %, ×0,5 fragile, un cran, couloir, 85 %, schéma changé, 2 pour 2, simple 92/85 %) | x | | | |
| A7.3 Sans charge (réserve gardée, +1 rép. au-dessus de l'écrit) | x | x | | |
| A7.4 Conseil (−15 %/+5 %, −7,5 % après échec, stop après 2 échecs, stop_at_rir) | | x | | |
| A8.1 Conditions de test, report 48 h | x | | | |
| A8.2 Échelle des tentatives (91 % / 95 % ; 80 % ; 50/70/35 % ; +5 %/+3 %/+5 kg ; −2 %) | x | x | | |
| A8.3 Séries repères (14 j, verrous) | x | x | | |
| A9.1 Tendons : hausse par tenue et par emplacement 20/15/10/10 %, plancher 55 % | x | x | | |
| A9.2 Techniques réservées (niveau), intensification retirée | x | | | x |
| A9.3 Élastique (2 séances, 7 j) | x | x | | |
| A9.4 Séries fractionnées (≤ 2×, conditions) | x | | | |
| A9.5 Étapes de figures, douleur > 3 bloque le passage | x | x | x | |
| A10 Endurance (reprise 70/50 %, jour sans, +10 %/30 j, WOD 75 %, fatigue croisée) | x | | | |
| A11 Propositions de volume (plafond 12/20/25/30, 2 max, blocages) | | | x | x |
| A13 Mode prudent, impact, IMC, première semaine, coupure longue | | | | x |
| B1 `charge_trop_vite` | | | | x |
| B2 `volume_trop_vite`, B3 `plafond_volume` | | | x | x |
| B4 `tendon_figures`, B5 `levier_trop_tot` | | | | x |
| B6–B8 techniques, exercices, contre-indications | | | x | x |
| B9 `echec_risque`, B13 `reprise_trop_dure` | | | | x |
| B10 `seance_trop_longue` | | | | x |
| B11 `decharge_absente`, B12 `affutage_absent` | | | x | x |
| B14 `impact_deconseille` | | | | x |

## Écarts CONTRAT ↔ code relevés (récapitulatif)
1. Ouverture des tentatives : 93 % (CONTRAT §11.6, §11.11) contre 0,91 dans le code (params.dart:190 ; CONTRAT §11.15 dit 91 %).
2. Retrait sur contrainte moyenne : 7/10 (CONTRAT §4.7, INTEGRATION_CI §4) ; 5/10 en mode coach dans le code
   (A/session.dart:369) ; limite 11 du §8 périmée en mode coach.
3. Arrêt après 3 séances de suite > 3/10 : dans le code (A/model.dart:193), absent du §11.15 (seulement la note de relecture).
4. Ouverture limitée à une barre récente seulement si elle pèse ≥ 85 % du maximum estimé (A/coach.dart:2329) : non dit au CONTRAT.
5. Commentaire A/session.dart:1180 « 5 sur 10 » pour l'allègement ; code : ≥ 4 (`coachPainRegress`).
6. Titre du CONTRAT « 0.2.3 » alors que le paquet est 0.3.1 (§12 et §13 ajoutés).
7. Appui neutre : kalis_plan tient barres parallèles et anneaux pour neutres (`coachPainProvokes`) ; kalis_adapt ne garde que
   parallettes et poignées pendant un arrêt « chaud » du poignet et comme remplaçant (A/session.dart:2438-2445).
8. `cautious` : kalis_plan (absent, ≠ standard, âge ≥ 65 ou < 18) plus large que le banc (`outcome == cautious` ou âge ≥ 65).
