# Journal des versions de kalis_plan

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
