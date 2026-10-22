# Sauvegarde KM6 (Koach 1.0.8)

Session Opus 5.5 lancée le 22/10/2026 vers 09:05 UTC (sans ligne « Lot : » ; KM6 posé « en cours » par le pilotage).
`ETAT_CP.md` : KM6 « en cours depuis 2026-10-22 09:10 UTC » (pipeline ea49b729).

## Fait
- Lecture : PIPELINE_CP, C17.37-C17.47, prompt KM6, LIVRAISON_RV1 § 5, RV1c1 § 4, KB4 § 8, KM4 § 5/§ 9, KM5.
- Pas de SDK Dart (proxy) : Dart compilé et testé sur `claude/ci-cp-a` (commits « KM6 contrôle (dev) »), comme KM5.

## Décisions
- X1 : défaut poulie 2,5 kg (min 2,5) dans `grid.dart` et `banc/verite.py` ; table non déplacée dans kalis_core
  (dite et alignée : test de kalis_bench qui compare les défauts de `kalis_plan` et de `kalis_adapt`).
- X2 : `plan('seance')` accepte `groups` (GroupSpec JSON) et renvoie `groups` recalés (tours = max des séries servies).
- X3/X7 : passe finale de `prescrire` : technique recalée (port de `coherentTechnique`), groupe de l'emplacement gardé.
- X4/X5/X6 : `_cible_charge` / test xRM (seance.py ~2290-2370, ~2750).
- X8 : `Planification.appliquer` pose `koachModule` ; raison `koach.volume_semaine` ; mesure dans `mesure_rampe`.
- Crédits : règles dans `kalis_plan` traits.dart ET `qualites/regles.py` (R8) ; tirage vertical et tractions chest 0,
  muscle-ups chest 0,5, pull-over haltère 0,5.

## Reste
Tout le code, données régénérées (km1 export), campagne, livraison.
