# Journal des versions de kalis_plan

## 0.3.1

Lot CY, partie 0 (sécurité) du pipeline « Calibrage des programmes ». Contrat inchangé (notes de coach
additives). Constats de la relecture documentée de CP2 (manches 7 et 8) : `docs/CALIBRAGE_CY.md` de
`kalis_bench`.

- **Avis médical avant la première semaine** : note de bloc `clearance_first` quand le questionnaire de santé
  est « prudent » ou qu'une gêne déclarée atteint 5/10 (ACSM 2015, dépistage avant l'activité) ;
  l'application la montre avant la première séance (`docs/INTEGRATION_CI.md`).
- **Épaule opérée ou à antécédent** : note `shoulder_history` sur le développé au-dessus de la tête.
- **Pas de test maximal sur une articulation douloureuse** : gêne relevée au bloc précédent à 3/10 ou plus,
  gêne déclarée à 4/10 ou plus, zone à l'arrêt (tests de fin de bloc et objectif daté ; une vraie épreuve
  reste écrite).
- **Jour de test de tirage** : le travail ordinaire de tirage vertical et de muscle-up qui restait après les
  tests saute.
- **Premier muscle-up** : le test d'un mouvement à risque élevé jamais réussi vise une répétition propre (au
  lieu de 8 à 15).
- **Course** : lendemain d'une course d'épreuve sans footing écrit ; texte de la règle de durée aligné sur la
  règle appliquée (plus longue course des quatre dernières semaines + 10 %).
- **Croisement (CY, boucle 1)** : le plafond de volume de répétitions ne compte plus les variantes plus faciles
  que le mouvement (pompe mains surélevées, sur les genoux, assistée), qui gardent leur propre dose ; débutant
  qui vise la première traction : deux séries assistées chaque jour (douze séries de tirage vertical par semaine
  au plus avec descentes et tenue) ; plateau de traction sans lest à douze tractions et plus : archer et
  typewriter d'abord (environ un tiers du maximum par côté).
- **Croisement (CY, boucle 2)** : après une échéance de course, la sortie longue repart à 70 % de la plus
  longue puis +10 % par semaine au plus ; la note « zone de l'épreuve » suit les répétitions écrites quand le
  garde-fou de volume les réduit.

## 0.3.0

Lot CP2, partie 1 (« les autres disciplines ») du pipeline « Calibrage des programmes ». `kalis_core` 0.4.3,
contrat additif (nouvelles notes de coach, nouveaux styles internes). Le chemin street est inchangé dans sa
méthode (passe complète du panel street en fin de lot : `docs/CALIBRAGE_CP2.md`). Journal et sources :
`docs/CALIBRAGE_CP2.md`, partie 1 ; sources vérifiées des règles chiffrées : même document.

- **Le coach écrit les autres disciplines** : `coachEligible` accepte un profil au schéma 3 dont la discipline
  principale est la musculation, la course et le cardio, le CrossFit, la mobilité ou la forme générale (avec
  n'importe quelles disciplines secondaires). Styles : hypertrophie, force (force athlétique et force générale),
  endurance, conditionnement, santé (`lib/src/coach/general.dart`). Un débutant ne fait pas de force
  athlétique (séries égales, double progression).
- **Musculation** : répartition de la semaine selon le nombre de séances (corps entier, haut / bas, poussée /
  tirage / jambes), polyarticulaires d'abord et une isolation en position allongée par muscle, groupe
  prioritaire (spécialisation « muscle » du profil) en tête de séance, quatre séries, trois fois par semaine dès
  quatre séances (pratique de terrain, choix raisonné) ; charges à environ 72 % du 1RM pour 8 à 12 répétitions à 2
  ou 3 en réserve, charge calibrée quand la barre vide dépasse le 1RM estimé.
- **Force** : squat deux à trois fois, couché trois à quatre fois, soulevé de terre une à deux fois par semaine,
  séries de tête et séries allégées, variantes de la phase faible ; antécédent lombaire : soulevé de terre en
  séries égales modérées, sans série de tête ni test.
- **Course** : sortie longue le jour le plus long, tracée d'une semaine à l'autre (110 % au plus de la plus
  longue des quatre semaines d'avant ; Frandsen et al. 2025), bornée au départ par la plus longue course connue ;
  une à deux séances de qualité, allure des fractions au kilomètre tirée du test, allure de l'objectif une semaine
  sur deux ; débutant : footing entier les six premières semaines ; affûtage à trois fractions (Bosquet et al.
  2007) ; test de mi-parcours sur la moitié de la distance, borné par le créneau ; l'épreuve elle-même le jour J ;
  12 min gardées pour le renforcement du coureur ; échauffement de coureur.
- **Conditionnement (CrossFit)** : pièces au format codifié (AMRAP, EMOM, « pour le temps », suite imposée,
  intervalles) ramenées à la durée du créneau, bloc de force à partir de 40 min, rameur et course de la pièce au
  format de la pièce, tours d'une pièce « pour le temps » ajustables par les garde-fous de volume, réserve de la
  reprise respectée ; muscle-up visé : pratique, dips à la barre droite, préparation scapulaire, tirage de la pièce
  au rowing.
- **Santé, mobilité, senior** : renforcement deux à trois fois par semaine, équilibre à chaque séance à partir de
  65 ans (OMS 2020 ; Sherrington et al. 2019), assis-debout de chaise, étirements à chaque séance, repos de 60 à
  75 s, marche et cardio à faible impact qui prennent le temps restant (et la consigne dit la même durée) ; genou
  gêné : chaise haute à 45-60° et flexion limitée ; cardio déclaré en discipline secondaire en fin de séance.
- Semaines « de test » sans test (musculation, santé) écrites comme des allègements ; un mouvement d'épreuve que
  le programme n'entraîne pas ne se teste pas ; échauffement et version courte selon la discipline.
- Relecture de `kalis_plan` (`coachAudit`) : le jour d'une course d'épreuve (test chronométré de l'échéance)
  n'est pas compté dans la durée des séances.
- Mode prudent (questionnaire de santé, 65 ans et plus) : CrossFit écrit en programme de santé ; course sans
  séance de qualité.
- Notes : échauffement et version courte propres à la discipline (`warmup_run`, `warmup_gym`, `warmup_health`,
  `short_run`, `short_health` ; `value` en minutes) ; nouvelles notes `wod_pace`, `chair_squat`, `knee_shallow`, `balance_progress`,
  `hold_support` (`docs/NOTES_COACH.md`).
- **Changements qui touchent aussi le chemin street** (sécurité ou correction ; vérifiés par la passe complète du
  panel street de fin de lot) : une charge écrite au-dessus du 1RM de travail (barre vide trop lourde) devient
  « à calibrer » ; `interval_pace` donne l'allure au kilomètre (le texte disait « 400 m ») ; affûtage de course à
  trois fractions ; plancher d'une course facile borné par le créneau ; consigne `easy_pace` alignée sur la durée
  réduite d'une marche de fin de séance.

## 0.2.3

Lot CP2, partie 0 (« finir le street ») du pipeline « Calibrage des programmes ». `kalis_core` 0.4.2, contrat
inchangé (additif : nouvelles notes de coach). Le chemin 0.1 est inchangé. Journal :
`docs/CALIBRAGE_CP2.md`.

- **Charge et douleur (sécurité, C9.7, C9.8)** : charge lestée bornée d'une semaine à l'autre même quand les
  répétitions changent (référence : dernière semaine de charge, jamais l'allègement), tonnage par exercice
  lesté +15 % au plus ; coude gêné : +2,5 kg par semaine (5 en pic) ; **bloc de reprise** quand un mouvement
  visé est à l'arrêt ou en reprise graduée après une douleur qui dure (ni affûtage, ni test, ni épreuve ;
  volume +10 % par semaine au plus ; échéance repoussée ; note `pain_reprise`) ; une zone signalée sur trois
  séances au bloc précédent reste « sensible » (2/10) au bloc suivant : appui chargé de l'échauffement retiré,
  pompe écrite poignet neutre ; gêne du poignet déclarée : figures en appui sans prise neutre réduites de
  moitié dès la première semaine (note `wrist_spare`), variantes sur parallettes ou anneaux d'abord, une
  seule grosse séance d'appui ; première semaine du premier bloc : répétitions au poids du corps par
  mouvement bornées à 4 fois le maximum ; muscle-up arrêté avant la casse de la transition.
- **Repères** : un 1RM seulement déclaré (jamais testé) nettement plus haut que l'estimation du moteur
  d'évolution est remplacé par elle au bloc suivant (baisse de 15 % au plus) ; série repère à la première
  séance sur un record non testé récemment (note `entry_check`).
- **Méthode** : bloc de réalisation d'un objectif de répétitions (variante de surcharge gardée, repos-pause,
  repos de la zone de l'épreuve réduit chaque semaine, simulation du test à J−10, note `reps_rehearsal`) ;
  tenues de figure vers le critère de passage (note `step_criterion`) ; plateau ou repère manqué : une
  séance de volume ou au chrono devient une séance de surcharge ; échelle de poussée du débutant avec un
  seul critère et la hauteur d'appui réglée en semaine 1 ; tirage du débutant plafonné.
- **Débutant sans ancienneté** : `coachEligible` l'accepte (« moins de 6 mois » par défaut).

## 0.2.2

Lot « CX correction 1 » du pipeline « Calibrage des programmes » (croisement avec `kalis_adapt` 0.2.2).
`kalis_core` 0.4.2. Le chemin 0.1 est inchangé (mêmes programmes à l'octet près, version du moteur mise à
part). Détail et sources : `CONTRAT.md`, § 12.14 ; journal : `packages/kalis_bench/docs/CALIBRAGE_CX.md`.

- **Douleur qui dure ou qui revient (sécurité)** : une raison `adapt.pain_persistent` du résumé
  d'adaptation (ou de la demande de restructuration) écarte du bloc tout mouvement qui provoque la zone
  (`coachPainStopHits` : contrainte forte sur l'articulation ; pour le poignet, tout appui en extension sans
  prise neutre, et sous contrainte forte seul un appui tenu — parallettes, anneaux, barres parallèles,
  poignées — reste permis ; tirage en pronation pour le coude), avec une note « arrêt » (consulter un
  médecin ou un kinésithérapeute ; reprise après deux semaines à 2/10 au plus) ; le bloc suivant reprend
  ces mouvements à 50 % des séries, +10 % par semaine, 3 en réserve au moins (notes `pain_stop`,
  `pain_return`).
- **Tests** : placés à partir du troisième jour de la semaine (deuxième si la semaine n'a pas deux séances
  assez tardives), jamais pendant une reprise ; les jours qui précèdent un test sont des jours faciles ; un
  test de figure porte sur l'étape visée elle-même (jamais un remplaçant). Un test plus bas que le repère
  de 15 % au plus fait foi seul (le bloc suivant est écrit sur le résultat) ; plus bas, il fait foi confirmé
  par le test d'avant, et seul il ne fait baisser le repère que de 15 % (ou jusqu'à l'estimation sûre).
  Une estimation ne défait pas un test de moins de quatre semaines et n'abaisse jamais un 1RM déclaré ou
  testé ; une série de deux répétitions ou plus n'abaisse pas seule un 1RM connu de plus de 15 % ; un 1RM
  déclaré ou estimé est relevé d'après le maximum au poids du corps (un 1RM testé ou de compétition fait
  foi) ; une barre de
  compétition plus basse que le 1RM connu ne l'abaisse pas. Après un test mesuré depuis la reprise, pas de
  gain supposé.
- **Répétitions et réserve** : au poids du corps sur un maximum de répétitions, répétitions + réserve écrite
  jamais au-dessus du repère (zone de l'épreuve comprise ; une pratique d'une répétition garde sa réserve). La
  note de la zone de l'épreuve dit la part des répétitions écrites.
- **Recul d'étape pour douleur** : quand la douleur écarte l'étape de travail d'une figure, l'étape plus
  facile porte la raison et le critère de retour (note `pain_step`).
- **Plateau** : un test qui ne dépasse pas le repère d'avant change la méthode du bloc suivant (variantes
  tempo excentrique — 45 % du maximum en répétitions, note `slow_tempo` —, archer, typewriter pour le
  tirage) et le dit (note `plateau`).
- **Zone de l'épreuve** (objectif de répétitions maximales, bloc de réalisation) : séries du mouvement visé
  à 72-80 % du maximum, 90 s de repos, 2 en réserve au moins et répétitions + réserve sous le repère
  (note `event_zone`), séance de force remplacée par le
  mouvement exact (12 et plus) ; repos-pause sur le principal réservé à l'avancé et à l'élite ; affûtage :
  intensité gardée au poids du corps, doubles à 86 % en lesté.
- **Volume de répétitions au poids du corps** : +15 % par semaine au plus sur le maximum des trois semaines
  d'avant, par famille de mouvement ; une seule variable monte à la fois dans les blocs de densité ; départs
  au chrono : un départ de plus par semaine au plus, deux sur deux semaines au plus ; sous dix répétitions
  de maximum, les départs montent seuls, 5 en réserve vraies, et sous sept le chrono cède au volume.
- **Douleur et restructuration** : une figure gardée sur prise neutre pendant un arrêt porte la note d'arrêt,
  jamais `pain_trend` ; une restructuration lit les semaines gardées du bloc pour ses garde-fous ; une
  amplitude partielle surchargée qui revient après quatre semaines repart de son entrée.
- **Étape de figure sautée** : l'étape de travail (ou la figure visée) d'une piste du profil n'est plus écartée
  du bloc suivant parce qu'elle a été sautée ; seul l'arrêt pour douleur l'écarte.
- **Poignet douloureux** (3/10 ou plus, ou zone à l'arrêt) : plus de pompes sur poignets à l'échauffement
  (rotations et pressions des doigts à la place).
- **Débutant** : préparation des poignets, tenues +15 % par semaine au plus (2 s au moins, jamais sous 55 %
  du maintien testé), test de la tenue
  menton non borné à 30 s, essais stricts de traction écrits seulement sans traction acquise.
- **Charges** : hausse comparée à la semaine précédente seule, sur le même emplacement ou, d'un bloc à l'autre,
  sur la plus lourde charge du même exercice à répétitions égales ; après une transition ou une introduction,
  2,5 % de charge par répétition d'écart ; estimation du 1RM sans charge connue +3 % ; séries allégées à
  65 % puis +3 % par palier des répétitions de la série lourde ; ouverture d'une épreuve à 98 % au moins du
  plus lourd simple ou double des trois semaines d'avant (pourcentage et note recalculés) ; pourcentage
  affiché calculé sur la charge arrondie ; 1RM de référence écrit dans l'export ; repos de 2 min en phase
  spécifique quand l'objectif est en répétitions.
- **Figures** : tenues lourdes à 60, 65 puis 70 % du maximum (+2 % par palier, 75 % au plus, 70 % les jours
  légers), arrondies au plus proche tant qu'elles restent à 8 points de la part visée et à 76 % au plus ; plus de tenues de remplissage quand l'étape plus facile dépasse
  25 s, sauf si l'objectif est une durée sur l'étape actuelle ; jusqu'à 10 séries quand le maximum est de
  5 s au plus.
- **Textes** : objectif ambitieux et repère de mi-parcours alignés sur ce que fait le moteur (le bloc suivant repart
  du test, aucune série ajoutée) ; version courte de la séance (4 ou 5 min d'échauffement, un ou deux exercices, 2 séries),
  point d'étape (une variable à la fois, pas de séries ajoutées), règle des départs au chrono réécrite.
- **Échauffement** : montée 5 @40 %, 3 @60 %, 2 @75 %, 1 @85 %, écrite à chaque exercice concerné, aussi avant
  le muscle-up ; dips du débutant (ou assistés) à amplitude progressive.

## 0.2.1

Lot CX du pipeline « Calibrage des programmes » : le programme écrit tenu sur une saison street complète
(croisement avec `kalis_adapt` 0.2.1). `kalis_core` 0.4.2. Le chemin 0.1 est inchangé (mêmes programmes à
l'octet près, version du moteur mise à part). Détail, sources et mesures : `CONTRAT.md`, § 12.13 ;
journal de calibrage : `packages/kalis_bench/docs/CALIBRAGE_CX.md`.

- **Bloc suivant d'après le test réel** : le dernier test mesuré (test guidé, compétition) fait foi, même
  plus bas qu'un record déclaré ; pas de gain supposé quand le repère vient du test de la semaine
  précédente ; les estimations du résumé d'adaptation (assez d'observations, erreur faible) abaissent le
  repère, jamais ne le montent ; les douleurs du résumé sont lues comme des gênes.
- **Échelle de poussée du débutant** (genoux → mains surélevées → sol) écrite comme une échelle de figure
  (`Pass1Plan.skillLadders`), critère de passage mesurable.
- **Figures** : critère de passage chiffré (tenue de 12, 11, 9 ou 7 s × 3 sur deux séances, environ 75 %
  du maximum), étape suivante ouverte à 75 % ; tenues à 60-70 % les jours légers, 75-85 % les jours lourds.
- **Charges** : séries allégées à −5 % (intensification, réalisation) ou −8 % ; trois séries lourdes au
  moins en intensification et en réalisation ; hausse hebdomadaire du volume de 15 % au plus ; lest sous le
  plus petit pas : série chiffrée au poids du corps.
- **Échéance** : catégorie de poids et pesée (streetlifting), format d'épreuve inconnu dit (sets & reps),
  semaine de transition après une épreuve principale, partielles retirées les quatre dernières semaines.
- **Récupération** : jours de traction écartés de 48 h autant que les jours d'entraînement le permettent
  (répétitions : jusqu'à trois séances de tirage ; streetlifting : volume et séance légère loin du tirage lourd).
- **Test du chemin vers la traction** : tenue menton au-dessus de la barre, comptée en secondes.
- Lieu du jour : un exercice au mur n'est plus proposé au parc sans mur (`feasibleAt` de `kalis_core`
  0.4.2).
- **Douleur relevée par le moteur d'évolution** (sous 6/10) : une figure reste au bloc suivant, à 60 % de ses
  séries (`pain_trend`), même quand le moteur l'avait écartée.
- **Débutants** : tenue menton à 60-70 % du maintien, test de l'objectif en tête de séance, pompe au sol en
  grappes dès le deuxième bloc, négatives de pompe gardées, critère de l'échelle de poussée sur deux séries,
  une seule règle d'élastique, essais stricts de traction dès la sixième semaine.
- **Lest** : 1RM de travail relevé d'après le maximum au poids du corps ; une estimation n'abaisse un 1RM
  qu'au-delà de 6 %.

## 0.2.0

Lot CP1 du pipeline « Calibrage des programmes » : le street au niveau d'un coach.

- Chemin street (`lib/src/coach/`) pour les profils au schéma 3 remplis par le questionnaire 0.4
  (expérience et ancienneté renseignées) dont la discipline principale est le streetlifting, le sets &
  reps ou la calisthénie : lecture du profil (`Athlete`), saison calée à rebours sur l'échéance
  (`shapeBlock`, `seasonPlanOf`), squelette par style (`buildSkeleton` : débutant, sets & reps,
  streetlifting, figures), dosage par méthode et par semaine (`prescribeBlock`), garde-fous (plafond et
  montée du volume, tenues bras tendus, hausse de charge, durée de séance).
- `KalisPlan` réalise aussi `SeasonPlanner` (`planSeason`).
- Les autres profils (schéma 2, disciplines non street) gardent le chemin 0.1, inchangé : mêmes
  programmes à l'octet près, version du moteur mise à part.
- Contrat : `CONTRAT.md`, § 12 ; notes de coach : `docs/NOTES_COACH.md` ; journal de calibrage :
  `docs/CALIBRAGE_CP1.md`.

## 0.1.0

Première version (lot G4 du pipeline « Génération et progression »).

- `KalisPlan` réalise `PlanEngine` de kalis_core 0.1.0 : `createPass1`, `review`, `variants`,
  `createPass2`, `nextBlock`, `restructure`.
- Passe 1 : optimisation sous contraintes dures, note explicite à 14 composantes (sécurité puis
  qualité), construction gloutonne avec anticipation, recuit simulé seedé, descente, départage par
  hachage FNV-1a ; « Autre proposition » par la graine.
- Revue, variantes (plus facile, équivalente, autre matériel, toutes les compatibles triées par
  proximité) et régénération à diff minimal avec verrous.
- Passe 2 : séries, plages, flammes visées, repos, charges de départ prudentes « à calibrer »,
  semaines d'introduction, de montée, de décharge et de test.
- Blocs glissants (`nextBlock`) et restructuration d'une séance, d'une semaine ou de la fin du bloc.
- `PlanInspector` (note relue, contraintes dures revérifiées, mesures), `lib/testing.dart` (profils
  aléatoires seedés), `lib/report.dart` (rapports), ligne de commande `dart run kalis_plan:plan`,
  simulateur `bin/kalis_plan_cli.dart`.
- Validation : `docs/` (profils types, comparaison au générateur L10, non-ressemblance, mesures,
  relecture indépendante avant livraison : `docs/VALIDATION.md`, § 8).
- Portabilité : exponentielle et logarithme du recuit calculés par le paquet (`stableExp`, `stableLn`).
