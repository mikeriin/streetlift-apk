# Journal des versions de kalis_plan

## 0.2.2

Lot « CX correction 1 » du pipeline « Calibrage des programmes » (croisement avec `kalis_adapt` 0.2.2).
`kalis_core` 0.4.2. Le chemin 0.1 est inchangé (mêmes programmes à l'octet près, version du moteur mise à
part). Détail et sources : `CONTRAT.md`, § 12.14 ; journal : `packages/kalis_bench/docs/CALIBRAGE_CX.md`.

- **Douleur qui dure ou qui revient (sécurité)** : une raison `adapt.pain_persistent` du résumé
  d'adaptation (ou de la demande de restructuration) écarte du bloc tout mouvement qui provoque la zone
  (`coachPainStopHits` : contrainte forte sur l'articulation, contrainte modérée du poignet sans prise
  neutre, tirage en pronation pour le coude), avec une note « arrêt » (consulter un médecin ou un
  kinésithérapeute ; reprise après deux semaines à 2/10 au plus) ; le bloc suivant reprend ces mouvements
  à 50 % des séries, +10 % par semaine, 3 en réserve au moins (notes `pain_stop`, `pain_return`).
- **Tests** : placés à partir du troisième jour de la semaine (deuxième si la semaine n'a pas deux séances
  assez tardives), jamais pendant une reprise ; les jours qui précèdent un test sont des jours faciles. Un
  repère mesuré ne baisse qu'après deux mesures concordantes (dix semaines au plus) ; une mesure seule plus
  basse cède devant le plus haut du test et de l'estimation du moteur d'évolution. Un record seulement
  déclaré est recalé par le premier test mesuré.
- **Plateau** : un test qui ne dépasse pas le repère d'avant change la méthode du bloc suivant (variantes
  tempo excentrique, archer, typewriter pour le tirage) et le dit (note `plateau`).
- **Volume de répétitions au poids du corps** : +15 % par semaine au plus sur le maximum des trois semaines
  d'avant, par famille de mouvement (séries, puis répétitions retirées) ; une seule variable monte à la fois
  dans les blocs de densité.
- **Figures de l'élite** : plus de tenues de remplissage quand l'étape plus facile dépasse 25 s ; partie
  intense des tenues à 60, 70 puis 75 % du maximum (+2 % par palier, 80 % au plus), jusqu'à 10 séries quand
  le maximum est de 5 s au plus.
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
