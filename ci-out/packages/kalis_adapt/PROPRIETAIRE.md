# kalis_adapt — rejeu du programme importé du propriétaire

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` à partir de `test/fixtures/proprietaire.json.gz` : le programme de 40 semaines du propriétaire, importé sans changer sa structure (D5.10), et un journal **simulé** de ses 11 premières semaines (athlète `avance_street`, graine 0). 223 exercices du programme ne sont pas portés dans la fixture (sans correspondance au catalogue, ou format hors plage : montées en singles, tours, EMOM). Même rejeu à la main : `dart run kalis_adapt:replay --journal test/fixtures/proprietaire.json.gz`.

Moteur `kalis_adapt` 0.1.0. Journal : 65 séances, 1295 séries, du 2026-10-05 au 2026-12-19 ; « aujourd'hui » : 2026-12-21. Bloc `proprietaire-v33` (40 semaines).

## Résumé d'adaptation

- Semaines de données : 11 ; séances faites : 65 sur 67 prévues.
- Niveau de déblocage : `session_restructure` ; confiance globale : 0.71.
- Forme du jour (modèle) : 0.68 ; forme 289.33, fatigue 45.30 (unités du modèle).
- Faits marquants : `adapt.unlock_level`(level=session_restructure) ; `adapt.missed_sessions`(missed=2, planned=67).

## Capacités estimées

| Exercice | Capacité | ± | Tendance / semaine | Séries | Dernière séance |
| --- | --- | --- | --- | --- | --- |
| Muscle-up barre assisté élastique | 19.4 répétitions max | 2.3 | 0.02 | 31 | 2026-12-12 |
| Muscle-up barre négatif | 17.2 répétitions max | 1.4 | 0.00 | 36 | 2026-12-12 |
| Muscle-up barre strict | 9.1 répétitions max | 0.6 | -0.02 | 8 | 2026-12-19 |
| Traction explosive poitrine à la barre | 21.6 répétitions max | 2.5 | 0.03 | 41 | 2026-12-19 |
| Tenue haute false grip aux anneaux | 39.8 s (tenue max) | 2.2 | 0.09 | 40 | 2026-12-12 |
| Back squat barre haute | 103.8 kg (1RM, charge totale) | 20.6 | -0.06 | 48 | 2026-12-19 |
| Curl biceps à la barre EZ | 39.9 kg (1RM, charge totale) | 3.5 | 0.02 | 18 | 2026-12-14 |
| Curl marteau aux haltères | 15.2 kg (1RM, charge totale) | 1.4 | 0.01 | 16 | 2026-12-17 |
| Développé couché barre | 78.1 kg (1RM, charge totale) | 6.5 | 0.14 | 45 | 2026-12-15 |
| Développé militaire barre debout | 64.0 kg (1RM, charge totale) | 5.5 | 0.02 | 61 | 2026-12-15 |
| Élévation latérale haltères | 11.4 kg (1RM, charge totale) | 1.5 | 0.01 | 47 | 2026-12-18 |
| Face pull à la poulie corde | 72.5 kg (1RM, charge totale) | 8.9 | -0.04 | 158 | 2026-12-17 |
| Hip thrust à la barre | 139.2 kg (1RM, charge totale) | 11.3 | 0.03 | 45 | 2026-12-16 |
| Hollow body hold | 57.4 s (tenue max) | 2.5 | 0.08 | 56 | 2026-12-16 |
| Leg curl couché | 56.5 kg (1RM, charge totale) | 5.4 | -0.09 | 44 | 2026-12-16 |
| Mollets debout à la machine | 135.8 kg (1RM, charge totale) | 10.4 | -0.16 | 48 | 2026-12-16 |
| Pallof press debout | 33.9 kg (1RM, charge totale) | 3.5 | -0.05 | 48 | 2026-12-16 |
| Pushdown à la corde | 34.1 kg (1RM, charge totale) | 3.6 | -0.01 | 56 | 2026-12-18 |
| Rotation externe haltère couché sur le côté | 10.0 kg (1RM, charge totale) | 1.1 | -0.01 | 167 | 2026-12-18 |
| Roue abdominale à genoux | 16.0 répétitions max | 0.5 | 0.05 | 43 | 2026-12-16 |
| Rowing barre buste penché prise pronation | 79.2 kg (1RM, charge totale) | 7.1 | 0.17 | 88 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | 41.0 kg (1RM, charge totale) | 4.2 | 0.16 | 51 | 2026-12-17 |
| Rowing poulie basse assis au triangle | 63.8 kg (1RM, charge totale) | 6.8 | 0.19 | 37 | 2026-12-17 |
| Soulevé de terre roumain à la barre | 132.9 kg (1RM, charge totale) | 10.6 | 0.19 | 42 | 2026-12-16 |
| Tirage vertical poulie prise neutre | 95.0 kg (1RM, charge totale) | 8.8 | -0.01 | 45 | 2026-12-14 |
| Y raise sur banc incliné | 17.2 kg (1RM, charge totale) | 1.8 | 0.05 | 39 | 2026-12-15 |
| Dead hang lesté | 85.8 s (tenue max) | 1.9 | -0.09 | 39 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | 41.5 s (tenue max) | 6.4 | 0.06 | 21 | 2026-12-12 |
| Dips lesté de compétition | 128.6 kg (1RM, charge totale) | 8.6 | 0.04 | 75 | 2026-12-15 |
| Muscle-up lesté de compétition | 86.9 kg (1RM, charge totale) | 4.4 | -0.07 | 83 | 2026-12-14 |
| Muscle-up négatif lesté | 100.7 kg (1RM, charge totale) | 2.4 | 0.15 | 45 | 2026-12-12 |
| Pompe lestée au gilet | 106.6 kg (1RM, charge totale) | 8.2 | -0.23 | 57 | 2026-12-15 |
| Relevé de jambes suspendu lesté | 104.9 kg (1RM, charge totale) | 8.6 | 0.04 | 41 | 2026-12-19 |
| Squat de compétition | 120.2 kg (1RM, charge totale) | 6.7 | 0.01 | 67 | 2026-12-16 |
| Traction lestée de compétition | 122.5 kg (1RM, charge totale) | 7.9 | -0.01 | 74 | 2026-12-14 |
| Dips aux barres parallèles | 62.3 répétitions max | 1.4 | -0.14 | 56 | 2026-12-18 |
| Pompe classique | 63.3 répétitions max | 1.4 | -0.18 | 66 | 2026-12-18 |
| Traction pronation | 26.8 répétitions max | 0.6 | -0.04 | 61 | 2026-12-17 |
| Traction scapulaire | 40.6 répétitions max | 3.4 | 0.06 | 54 | 2026-12-17 |

## Propositions

Aucune proposition aujourd'hui.

## Records

| Exercice | Record | Valeur | Jour |
| --- | --- | --- | --- |
| Muscle-up barre assisté élastique | max_reps | 6.0 | 2026-10-24 |
| Muscle-up barre négatif | max_reps | 6.0 | 2026-10-05 |
| Muscle-up barre strict | max_reps | 9.0 | 2026-10-12 |
| Traction explosive poitrine à la barre | max_reps | 6.0 | 2026-10-24 |
| Tenue haute false grip aux anneaux | max_hold_seconds | 30.0 | 2026-10-31 |
| Curl biceps à la barre EZ | one_rm_kg | 37.1 | 2026-11-30 |
| Développé couché barre | one_rm_kg | 76.7 | 2026-12-15 |
| Développé militaire barre debout | one_rm_kg | 60.8 | 2026-12-01 |
| Hip thrust à la barre | one_rm_kg | 133.3 | 2026-12-02 |
| Hollow body hold | max_hold_seconds | 45.0 | 2026-10-07 |
| Leg curl couché | one_rm_kg | 52.0 | 2026-11-04 |
| Mollets debout à la machine | one_rm_kg | 135.7 | 2026-10-21 |
| Pallof press debout | one_rm_kg | 33.9 | 2026-10-07 |
| Pushdown à la corde | one_rm_kg | 30.0 | 2026-12-01 |
| Rotation externe haltère couché sur le côté | one_rm_kg | 10.1 | 2026-11-20 |
| Roue abdominale à genoux | max_reps | 14.0 | 2026-12-16 |
| Rowing barre buste penché prise pronation | one_rm_kg | 76.7 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | one_rm_kg | 36.4 | 2026-10-22 |
| Rowing poulie basse assis au triangle | one_rm_kg | 63.3 | 2026-10-22 |
| Tirage vertical poulie prise neutre | one_rm_kg | 84.5 | 2026-11-30 |
| Dead hang lesté | max_hold_seconds | 84.0 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | max_hold_seconds | 9.0 | 2026-10-24 |
| Dips lesté de compétition | one_rm_kg | 121.8 | 2026-11-10 |
| Muscle-up lesté de compétition | one_rm_kg | 82.6 | 2026-11-09 |
| Muscle-up négatif lesté | one_rm_kg | 102.2 | 2026-11-21 |
| Pompe lestée au gilet | one_rm_kg | 111.3 | 2026-10-20 |
| Relevé de jambes suspendu lesté | one_rm_kg | 104.6 | 2026-10-31 |
| Squat de compétition | one_rm_kg | 114.2 | 2026-12-09 |
| Traction lestée de compétition | one_rm_kg | 116.3 | 2026-11-09 |
| Dips aux barres parallèles | max_reps | 64.0 | 2026-10-13 |
| Pompe classique | max_reps | 67.0 | 2026-10-13 |
| Traction pronation | max_reps | 27.0 | 2026-10-15 |
| Traction scapulaire | max_reps | 20.0 | 2026-10-19 |

## Séance prescrite — semaine 12, jour 1

Confiance 0.80 ; `adapt.readiness`(readiness=0.679).

- **Muscle-up lesté de compétition** : 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 2 @ 6.25 kg (7 fl.) · 2 @ 6.25 kg (7 fl.) — 87 % du 1RM, repos 240 s
  - `adapt.load_up`(deltaKg=5.0)
- **Traction lestée de compétition** : 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) — 85 % du 1RM, repos 300 s
  - `adapt.load_up`(deltaKg=7.5)
- **Rowing barre buste penché prise pronation** : 8 @ 60 kg (7 fl.) · 8 @ 60 kg (7 fl.) · 7 @ 60 kg (7 fl.) — 76 % du 1RM, repos 180 s
  - `adapt.load_up`(deltaKg=2.5)
- **Curl biceps à la barre EZ** : 13 @ 27.5 kg (7 fl.) · 11 @ 27.5 kg (7 fl.) — 69 % du 1RM, repos 90 s
  - `adapt.increment_coarse`(stepKg=2.5)
- **Face pull à la poulie corde** : 21 @ 42.5 kg (5 fl.) · 18 @ 42.5 kg (5 fl.) · 17 @ 42.5 kg (5 fl.) — 59 % du 1RM, repos 60 s
  - `adapt.increment_coarse`(stepKg=2.5)

## Journal du moteur (fin)

- n° 52, 2026-12-11, `session` : readiness=0.0, residual=0.0043, sessionId=sim-67, unplannedFails=0, unrated=0, workSets=11
- n° 53, 2026-12-12, `session` : readiness=0.565, residual=-0.006, sessionId=sim-68, unplannedFails=0, unrated=0, workSets=29
- n° 54, 2026-12-14, `session` : readiness=0.59, residual=-0.0084, sessionId=sim-70, unplannedFails=0, unrated=0, workSets=22
- n° 55, 2026-12-15, `session` : readiness=0.57, residual=-0.0055, sessionId=sim-71, unplannedFails=0, unrated=0, workSets=20
- n° 56, 2026-12-16, `session` : readiness=0.545, residual=-0.0054, sessionId=sim-72, unplannedFails=0, unrated=0, workSets=21
- n° 57, 2026-12-17, `session` : readiness=0.397, residual=-0.0019, sessionId=sim-73, unplannedFails=0, unrated=0, workSets=20
- n° 58, 2026-12-18, `session` : readiness=0.543, residual=-0.0049, sessionId=sim-74, unplannedFails=0, unrated=0, workSets=13
- n° 59, 2026-12-19, `session` : readiness=0.594, residual=-0.0124, sessionId=sim-75, unplannedFails=0, unrated=0, workSets=14
