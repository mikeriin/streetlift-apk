# kalis_adapt — rejeu du programme importé du propriétaire

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` à partir de `test/fixtures/proprietaire.json.gz` : le programme de 40 semaines du propriétaire, importé sans changer sa structure (D5.10), et un journal **simulé** de ses 11 premières semaines (athlète `avance_street`, graine 0). 223 exercices du programme ne sont pas portés dans la fixture (sans correspondance au catalogue, ou format hors plage : montées en singles, tours, EMOM). Même rejeu à la main : `dart run kalis_adapt:replay --journal test/fixtures/proprietaire.json.gz`.

Moteur `kalis_adapt` 0.2.1. Journal : 65 séances, 1297 séries, du 2026-10-05 au 2026-12-19 ; « aujourd'hui » : 2026-12-21. Bloc `proprietaire-v33` (40 semaines).

## Résumé d'adaptation

- Semaines de données : 11 ; séances faites : 65 sur 67 prévues.
- Niveau de déblocage : `session_restructure` ; confiance globale : 0.72.
- Forme du jour (modèle) : 0.71 ; forme 301.32, fatigue 47.37 (unités du modèle).
- Faits marquants : `adapt.unlock_level`(level=session_restructure) ; `adapt.missed_sessions`(missed=2, planned=67).

## Capacités estimées

| Exercice | Capacité | ± | Tendance / semaine | Séries | Dernière séance |
| --- | --- | --- | --- | --- | --- |
| Muscle-up barre assisté élastique | 19.5 répétitions max | 2.3 | 0.02 | 31 | 2026-12-12 |
| Muscle-up barre négatif | 17.2 répétitions max | 1.4 | 0.00 | 36 | 2026-12-12 |
| Muscle-up barre strict | 9.0 répétitions max | 0.5 | -0.02 | 8 | 2026-12-19 |
| Traction explosive poitrine à la barre | 21.7 répétitions max | 2.5 | 0.03 | 41 | 2026-12-19 |
| Tenue haute false grip aux anneaux | 39.6 s (tenue max) | 2.2 | 0.09 | 41 | 2026-12-12 |
| Back squat barre haute | 89.7 kg (1RM, charge totale) | 12.7 | -0.07 | 49 | 2026-12-19 |
| Curl biceps à la barre EZ | 39.6 kg (1RM, charge totale) | 3.6 | 0.02 | 17 | 2026-12-14 |
| Curl marteau aux haltères | 15.7 kg (1RM, charge totale) | 1.5 | 0.04 | 18 | 2026-12-17 |
| Développé couché barre | 78.1 kg (1RM, charge totale) | 6.2 | 0.16 | 45 | 2026-12-15 |
| Développé militaire barre debout | 63.6 kg (1RM, charge totale) | 5.2 | -0.03 | 60 | 2026-12-15 |
| Élévation latérale haltères | 11.9 kg (1RM, charge totale) | 1.3 | 0.01 | 48 | 2026-12-18 |
| Face pull à la poulie corde | 70.6 kg (1RM, charge totale) | 7.1 | -0.03 | 152 | 2026-12-17 |
| Hip thrust à la barre | 137.3 kg (1RM, charge totale) | 9.9 | 0.02 | 43 | 2026-12-16 |
| Hollow body hold | 57.2 s (tenue max) | 2.5 | 0.09 | 56 | 2026-12-16 |
| Leg curl couché | 55.6 kg (1RM, charge totale) | 4.8 | -0.11 | 42 | 2026-12-16 |
| Mollets debout à la machine | 147.3 kg (1RM, charge totale) | 14.9 | -0.08 | 50 | 2026-12-16 |
| Pallof press debout | 33.8 kg (1RM, charge totale) | 3.3 | -0.06 | 48 | 2026-12-16 |
| Pushdown à la corde | 33.1 kg (1RM, charge totale) | 3.0 | -0.01 | 53 | 2026-12-18 |
| Rotation externe haltère couché sur le côté | 9.8 kg (1RM, charge totale) | 1.1 | -0.02 | 159 | 2026-12-18 |
| Roue abdominale à genoux | 16.5 répétitions max | 0.4 | 0.04 | 46 | 2026-12-16 |
| Rowing barre buste penché prise pronation | 79.3 kg (1RM, charge totale) | 7.8 | 0.20 | 88 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | 41.6 kg (1RM, charge totale) | 3.8 | 0.12 | 57 | 2026-12-17 |
| Rowing poulie basse assis au triangle | 64.8 kg (1RM, charge totale) | 6.5 | 0.05 | 41 | 2026-12-17 |
| Soulevé de terre roumain à la barre | 132.9 kg (1RM, charge totale) | 10.4 | 0.13 | 42 | 2026-12-16 |
| Tirage vertical poulie prise neutre | 92.4 kg (1RM, charge totale) | 6.6 | 0.01 | 43 | 2026-12-14 |
| Y raise sur banc incliné | 17.1 kg (1RM, charge totale) | 1.7 | 0.04 | 39 | 2026-12-15 |
| Dead hang lesté | 86.6 s (tenue max) | 1.9 | 0.13 | 39 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | 44.3 s (tenue max) | 6.6 | 0.06 | 21 | 2026-12-12 |
| Dips lesté de compétition | 128.4 kg (1RM, charge totale) | 8.5 | 0.05 | 76 | 2026-12-15 |
| Muscle-up lesté de compétition | 86.3 kg (1RM, charge totale) | 4.6 | -0.10 | 82 | 2026-12-14 |
| Muscle-up négatif lesté | 98.3 kg (1RM, charge totale) | 4.5 | 0.04 | 48 | 2026-12-12 |
| Pompe lestée au gilet | 108.5 kg (1RM, charge totale) | 8.7 | -0.16 | 61 | 2026-12-15 |
| Relevé de jambes suspendu lesté | 105.0 kg (1RM, charge totale) | 8.7 | -0.04 | 38 | 2026-12-19 |
| Squat de compétition | 120.5 kg (1RM, charge totale) | 6.5 | -0.05 | 68 | 2026-12-16 |
| Traction lestée de compétition | 123.2 kg (1RM, charge totale) | 8.1 | -0.02 | 74 | 2026-12-14 |
| Dips aux barres parallèles | 61.6 répétitions max | 1.3 | -0.19 | 57 | 2026-12-18 |
| Pompe classique | 66.8 répétitions max | 1.4 | -0.01 | 66 | 2026-12-18 |
| Traction pronation | 27.1 répétitions max | 0.6 | -0.02 | 65 | 2026-12-17 |
| Traction scapulaire | 40.7 répétitions max | 3.4 | 0.06 | 54 | 2026-12-17 |

## Propositions

- `volume:quads:down:proprietaire-v33@12` — volume (portée exercise), confiance 0.73, niveau requis `volume`, 24 changement(s) : `adapt.volume_down`(sets=1) ; `adapt.volume_response`(muscle=quads, weeklySets=12.8)

## Records

| Exercice | Record | Valeur | Jour |
| --- | --- | --- | --- |
| Muscle-up barre assisté élastique | max_reps | 6.0 | 2026-10-24 |
| Muscle-up barre négatif | max_reps | 6.0 | 2026-10-05 |
| Muscle-up barre strict | max_reps | 9.0 | 2026-10-12 |
| Traction explosive poitrine à la barre | max_reps | 6.0 | 2026-10-24 |
| Tenue haute false grip aux anneaux | max_hold_seconds | 30.0 | 2026-10-31 |
| Curl biceps à la barre EZ | one_rm_kg | 37.1 | 2026-11-30 |
| Développé couché barre | one_rm_kg | 74.8 | 2026-11-24 |
| Développé militaire barre debout | one_rm_kg | 60.0 | 2026-12-15 |
| Face pull à la poulie corde | one_rm_kg | 43.1 | 2026-10-12 |
| Hip thrust à la barre | one_rm_kg | 138.4 | 2026-11-25 |
| Hollow body hold | max_hold_seconds | 45.0 | 2026-10-07 |
| Leg curl couché | one_rm_kg | 53.3 | 2026-11-04 |
| Mollets debout à la machine | one_rm_kg | 135.7 | 2026-10-21 |
| Pallof press debout | one_rm_kg | 33.9 | 2026-10-07 |
| Pushdown à la corde | one_rm_kg | 29.3 | 2026-12-01 |
| Rotation externe haltère couché sur le côté | one_rm_kg | 10.0 | 2026-11-20 |
| Roue abdominale à genoux | max_reps | 14.0 | 2026-11-11 |
| Rowing barre buste penché prise pronation | one_rm_kg | 76.7 | 2026-11-30 |
| Rowing haltère unilatéral appui sur banc | one_rm_kg | 35.5 | 2026-10-22 |
| Rowing poulie basse assis au triangle | one_rm_kg | 63.3 | 2026-10-22 |
| Soulevé de terre roumain à la barre | one_rm_kg | 109.5 | 2026-12-09 |
| Tirage vertical poulie prise neutre | one_rm_kg | 87.8 | 2026-11-30 |
| Dead hang lesté | max_hold_seconds | 83.0 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | max_hold_seconds | 11.0 | 2026-10-24 |
| Dips lesté de compétition | one_rm_kg | 123.4 | 2026-11-10 |
| Muscle-up lesté de compétition | one_rm_kg | 84.1 | 2026-10-19 |
| Muscle-up négatif lesté | one_rm_kg | 102.2 | 2026-11-21 |
| Pompe lestée au gilet | one_rm_kg | 111.3 | 2026-10-20 |
| Relevé de jambes suspendu lesté | one_rm_kg | 103.3 | 2026-12-12 |
| Squat de compétition | one_rm_kg | 116.7 | 2026-11-25 |
| Traction lestée de compétition | one_rm_kg | 117.9 | 2026-10-26 |
| Dips aux barres parallèles | max_reps | 64.0 | 2026-10-13 |
| Pompe classique | max_reps | 67.0 | 2026-10-13 |
| Traction pronation | max_reps | 27.0 | 2026-10-15 |
| Traction scapulaire | max_reps | 20.0 | 2026-10-19 |

## Séance prescrite — semaine 12, jour 1

Confiance 0.78 ; `adapt.readiness`(readiness=0.706).

- **Muscle-up lesté de compétition** : 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) — 88 % du 1RM, repos 240 s
  - `adapt.load_up`(deltaKg=5.0)
- **Traction lestée de compétition** : 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) — 86 % du 1RM, repos 300 s
  - `adapt.load_up`(deltaKg=8.75)
- **Rowing barre buste penché prise pronation** : 10 @ 60 kg (7 fl.) · 8 @ 60 kg (7 fl.) · 8 @ 60 kg (7 fl.) — 75 % du 1RM, repos 180 s
  - `adapt.load_up`(deltaKg=2.5)
- **Curl biceps à la barre EZ** : 14 @ 27.5 kg (7 fl.) · 12 @ 27.5 kg (7 fl.) — 69 % du 1RM, repos 90 s
  - `adapt.increment_coarse`(stepKg=2.5)
- **Face pull à la poulie corde** : 18 @ 45 kg (5 fl.) · 16 @ 45 kg (5 fl.) · 15 @ 45 kg (5 fl.) — 64 % du 1RM, repos 60 s

## Journal du moteur (fin)

- n° 53, 2026-12-12, `session` : readiness=0.602, residual=0.0015, sessionId=sim-68, unplannedFails=0, unrated=0, workSets=29
- n° 54, 2026-12-14, `session` : readiness=0.636, residual=-0.0093, sessionId=sim-70, unplannedFails=1, unrated=0, workSets=22
- n° 55, 2026-12-15, `session` : readiness=0.614, residual=-0.0068, sessionId=sim-71, unplannedFails=2, unrated=0, workSets=20
- n° 56, 2026-12-16, `session` : readiness=0.587, residual=-0.0074, sessionId=sim-72, unplannedFails=3, unrated=0, workSets=21
- n° 57, 2026-12-17, `session` : readiness=0.429, residual=-0.0057, sessionId=sim-73, unplannedFails=0, unrated=0, workSets=20
- n° 58, 2026-12-18, `session` : readiness=0.58, residual=-0.0176, sessionId=sim-74, unplannedFails=0, unrated=0, workSets=13
- n° 59, 2026-12-19, `session` : readiness=0.633, residual=-0.0196, sessionId=sim-75, unplannedFails=1, unrated=0, workSets=14
- n° 60, 2026-12-21, `proposal` : adherence=0.0, fatigue=-0.1, id=volume:quads:down:proprietaire-v33@12, kind=volume, progress=0.218, risk=0.0, threshold=0.65, utility=0.318
