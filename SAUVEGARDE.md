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

## Reste à faire
- Lire le contrôle dev, corriger la compilation ; passe 0 du panel sur les saisons (mesure avant).
- Corrections du programme écrit (LANCEMENTS.md CX, points 1 à 7 ; C7.7 street_08 et street_14 ; remarques de la relecture documentée des manches 1 et 2 qui relèvent du programme).
- Boucles (≤ 10), relecture documentée, relecture indépendante du code, non-ressemblance (clé), page de relecture (manche « street complet (CX, date) »), fin de lot.
