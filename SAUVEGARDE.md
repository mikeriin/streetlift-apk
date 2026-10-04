# Sauvegarde CX (croisement street, kalis_plan 0.2.x × kalis_adapt 0.2.x)

Session Opus 5.5 lancée le 04/10/2026 vers 17:35 UTC. Base : `moteurs` ccde1ad2. CX « en cours » poussé sur `pipeline` (8b62abd).

## Fait
- Démarrage : accès push vérifié (push réel de `pipeline`), prérequis C7.9, lectures (PIPELINE_CP, DECISIONS_CP, LANCEMENTS, prompt CX, LIVRAISON_CP1 et CA1), 308 notes de la page de relecture lues (manches 0 à 2, toutes `relecture-documentee`, aucune du propriétaire).
- Grilles du panel : empreintes identiques à `docs/PANEL.md` (concaténation 7d337a2e…).
- Dérive du panel (ancres p06_a et p17_c, un appel Opus par école) : (a) = 1/1/1/1, (c) = 9/9/9/8 → pas de dérive.
- Outils : `cx-outils/panel.py` (dossiers isolés du panel), `cx-outils/ci.sh` (contrôle dev/full sur `claude/ci-cp-a`), `cx-outils/aa_fmt` (formatage d'une copie en CI, jamais sur moteurs), `cx-outils/save.sh`.
- Code (non compilé localement, pas de SDK Dart) : `kalis_adapt` runner : `ProfileChange` (changement de profil en cours de saison, re-planification) ; `kalis_bench` : `season.dart` (scénarios, campagne des saisons, mesures écrit↔servi, retirés sans raison, violations réalisées, stabilité ; couple 0.1 = profil sans `trainingAge`), `season_export.dart` (export « saison »), CLI : `saisons/`, `SAISONS.md`, `saisons.json`.
- Premier contrôle dev poussé (3cfa0a26).

## Diagnostic (pour la suite)
- Correction 1 (bloc suivant d'après le test réel) : `Athlete.read` (kalis_plan coach/athlete.dart) garde le **maximum** des records et des tests ; un test plus bas que le record déclaré est ignoré, et `_maxOf`/`_holdOf` (prescribe.dart) ajoutent le gain prévu depuis la date du test (`seed()` pose `_testedOn` sur le test du bloc précédent). À corriger : le dernier test daté fait foi ; pas de gain prévu quand le repère vient d'un test postérieur.

## Étape 18:37 UTC : premières corrections de kalis_plan écrites (non compilées)
- athlete.dart : le dernier test mesuré (guided_test, competition) fait foi, même plus bas ; prescribe.dart `_measuredAt` : pas de gain supposé quand le repère vient du test de la semaine précédente.
- Séries allégées −8 % (intro, accumulation, dernier lourd), −5 % (intensification, réalisation) ; `_heavySets` : 3 séries au moins en intensification et réalisation.
- Tenues des figures : jours lourds 75 → 85 %, légers 60 → 70 % ; critère de passage `coachStepHold` 12/11/9/7 s × 3 sur 2 séances (≈ 75 % du maximum `coachStepMax`) ; ouverture de l'étape suivante à 75 % de `coachStepMax`.
- Test du chemin vers la traction : tenue menton (secondes, `coachGateExercise`) au lieu de la descente comptée en répétitions ; texte sans promesse (lien faible avec la traction).
- Lest sous le plus petit pas : série au poids du corps chiffrée (plus de « à calibrer »).
- `coachVolumeRise` 0,20 → 0,15.
- kalis_core 0.4.2 (catalog.dart) : `feasibleAt`, `placeBoundEquipment` (mur : maison, salle), `equipmentAlternatives` (pompe inclinée, pike pieds surélevés), `homeFurnitureExercises` ; version 0.4.2 (pubspec, version.dart, parcours_spec.py, parcours_v3.json régénéré ; tests Python 86 verts). Utilisé par kalis_plan (athlete.dart rejection).
- Recherche boucle 0 : cx-outils/docs/recherche_boucle0.md (FinalRep : catégories, pesée 2 h, ordre ; sets & reps sans règlement unifié ; isométrie ≥ 70 % ; flexed-arm hang : lien faible ; affûtage Pritchard).

## Étape 19:15 UTC : passe 0 faite, boucle 1 en contrôle
- Contrôle dev run 37222464508 (3cfa0a26) : banc des saisons compile ; formatage seul en échec (aa_fmt corrigé : --language-version=3.10 ; fmtsync.py ne recopie que les fichiers inchangés depuis le push).
- Passe 0 (68 couples, saisons des moteurs 0.2.0) : 1/68 à 9, minimum 4,5, moyenne 7,01 ; notes : cx-outils/notes/p0.json ; tableau et familles : packages/kalis_bench/docs/CALIBRAGE_CX.md.
- Boucle 1 écrite et poussée en dev (43426224) : estimations du résumé d'adaptation (Athlete.read `estimates`, vers le bas seulement) et douleurs (`adaptationPains`) dans le bloc suivant ; transition après une épreuve principale (`justAfterEvent`) ; tirage non consécutif (reps : avancé jusqu'à 3 jours ; streetlifting : volume et séance légère à 48 h) ; partielles : coude à antécédent 90-95 %, retirées les 4 dernières semaines ; négatives du débutant 3 × 4-5 de 5 s ; volume lesté avancé 5 × 75-80 % ; pas d'étape suivante quand l'étape actuelle est écartée ; texte already_applied ; notes weight_class et event_format.

## Reste à faire
- Lire le contrôle dev, corriger la compilation ; passe 0 du panel sur les saisons (mesure avant).
- Corrections du programme écrit (LANCEMENTS.md CX, points 1 à 7 ; C7.7 street_08 et street_14 ; remarques de la relecture documentée des manches 1 et 2 qui relèvent du programme).
- Boucles (≤ 10), relecture documentée, relecture indépendante du code, non-ressemblance (clé), page de relecture (manche « street complet (CX, date) »), fin de lot.
