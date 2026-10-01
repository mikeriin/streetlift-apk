# kalis_adapt — rejeu du programme importé du propriétaire

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` à partir de `test/fixtures/proprietaire.json.gz` : le programme de 40 semaines du propriétaire, importé sans changer sa structure (D5.10), et un journal **simulé** de ses 11 premières semaines (athlète `avance_street`, graine 0). 223 exercices du programme ne sont pas portés dans la fixture (sans correspondance au catalogue, ou format hors plage : montées en singles, tours, EMOM). Même rejeu à la main : `dart run kalis_adapt:replay --journal test/fixtures/proprietaire.json.gz`.

Moteur `kalis_adapt` 0.1.0. Journal : 65 séances, 1297 séries, du 2026-10-05 au 2026-12-19 ; « aujourd'hui » : 2026-12-21. Bloc `proprietaire-v33` (40 semaines).

## Résumé d'adaptation

- Semaines de données : 11 ; séances faites : 65 sur 67 prévues.
- Niveau de déblocage : `session_restructure` ; confiance globale : 0.70.
- Forme du jour (modèle) : 0.60 ; forme 289.57, fatigue 45.83 (unités du modèle).
- Faits marquants : `adapt.unlock_level`(level=session_restructure) ; `adapt.missed_sessions`(missed=2, planned=67).

## Capacités estimées

| Exercice | Capacité | ± | Tendance / semaine | Séries | Dernière séance |
| --- | --- | --- | --- | --- | --- |
| Muscle-up barre assisté élastique | 19.9 répétitions max | 2.8 | 0.03 | 30 | 2026-12-12 |
| Muscle-up barre négatif | 15.6 répétitions max | 1.5 | 0.00 | 36 | 2026-12-12 |
| Muscle-up barre strict | 9.3 répétitions max | 0.6 | -0.02 | 8 | 2026-12-19 |
| Traction explosive poitrine à la barre | 20.3 répétitions max | 2.7 | 0.03 | 41 | 2026-12-19 |
| Tenue haute false grip aux anneaux | 40.0 s (tenue max) | 2.2 | 0.09 | 39 | 2026-12-12 |
| Back squat barre haute | 97.3 kg (1RM, charge totale) | 10.8 | -0.20 | 47 | 2026-12-19 |
| Curl biceps à la barre EZ | 41.6 kg (1RM, charge totale) | 3.9 | 0.03 | 18 | 2026-12-14 |
| Curl marteau aux haltères | 15.8 kg (1RM, charge totale) | 1.6 | 0.03 | 17 | 2026-12-17 |
| Développé couché barre | 84.7 kg (1RM, charge totale) | 7.0 | 0.05 | 46 | 2026-12-15 |
| Développé militaire barre debout | 65.9 kg (1RM, charge totale) | 5.5 | -0.03 | 62 | 2026-12-15 |
| Élévation latérale haltères | 10.1 kg (1RM, charge totale) | 0.5 | -0.00 | 41 | 2026-12-18 |
| Face pull à la poulie corde | 78.2 kg (1RM, charge totale) | 9.6 | -0.10 | 153 | 2026-12-17 |
| Hip thrust à la barre | 140.6 kg (1RM, charge totale) | 9.8 | -0.03 | 44 | 2026-12-16 |
| Hollow body hold | 57.2 s (tenue max) | 2.5 | 0.09 | 56 | 2026-12-16 |
| Leg curl couché | 56.9 kg (1RM, charge totale) | 5.4 | -0.03 | 39 | 2026-12-16 |
| Mollets debout à la machine | 152.1 kg (1RM, charge totale) | 14.7 | -0.31 | 48 | 2026-12-16 |
| Pallof press debout | 34.9 kg (1RM, charge totale) | 3.1 | -0.03 | 43 | 2026-12-16 |
| Pushdown à la corde | 33.4 kg (1RM, charge totale) | 2.9 | -0.03 | 50 | 2026-12-18 |
| Rotation externe haltère couché sur le côté | 10.7 kg (1RM, charge totale) | 1.3 | -0.02 | 166 | 2026-12-18 |
| Roue abdominale à genoux | 16.1 répétitions max | 0.5 | 0.05 | 45 | 2026-12-16 |
| Rowing barre buste penché prise pronation | 83.0 kg (1RM, charge totale) | 7.6 | -0.00 | 85 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | 41.9 kg (1RM, charge totale) | 4.2 | 0.15 | 49 | 2026-12-17 |
| Rowing poulie basse assis au triangle | 68.9 kg (1RM, charge totale) | 7.3 | 0.10 | 41 | 2026-12-17 |
| Soulevé de terre roumain à la barre | 136.1 kg (1RM, charge totale) | 10.7 | 0.00 | 42 | 2026-12-16 |
| Tirage vertical poulie prise neutre | 93.4 kg (1RM, charge totale) | 7.1 | -0.04 | 45 | 2026-12-14 |
| Y raise sur banc incliné | 18.5 kg (1RM, charge totale) | 1.8 | 0.01 | 35 | 2026-12-15 |
| Dead hang lesté | 86.4 s (tenue max) | 1.9 | 0.08 | 40 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | 41.6 s (tenue max) | 6.4 | 0.06 | 21 | 2026-12-12 |
| Dips lesté de compétition | 130.6 kg (1RM, charge totale) | 8.8 | -0.00 | 74 | 2026-12-15 |
| Muscle-up lesté de compétition | 87.0 kg (1RM, charge totale) | 4.4 | -0.08 | 83 | 2026-12-14 |
| Muscle-up négatif lesté | 101.0 kg (1RM, charge totale) | 2.4 | 0.16 | 44 | 2026-12-12 |
| Pompe lestée au gilet | 108.3 kg (1RM, charge totale) | 7.6 | -0.20 | 60 | 2026-12-15 |
| Relevé de jambes suspendu lesté | 107.0 kg (1RM, charge totale) | 8.8 | 0.07 | 38 | 2026-12-19 |
| Squat de compétition | 120.2 kg (1RM, charge totale) | 6.6 | -0.00 | 68 | 2026-12-16 |
| Traction lestée de compétition | 124.9 kg (1RM, charge totale) | 8.0 | -0.03 | 74 | 2026-12-14 |
| Dips aux barres parallèles | 62.7 répétitions max | 1.3 | -0.13 | 55 | 2026-12-18 |
| Pompe classique | 62.6 répétitions max | 1.4 | -0.23 | 64 | 2026-12-18 |
| Traction pronation | 26.8 répétitions max | 0.6 | -0.04 | 61 | 2026-12-17 |
| Traction scapulaire | 34.7 répétitions max | 3.8 | 0.05 | 54 | 2026-12-17 |

## Propositions

- `volume:hamstrings:down:proprietaire-v33@12` — volume (portée exercise), confiance 0.66, niveau requis `volume`, 24 changement(s) : `adapt.volume_down`(sets=1) ; `adapt.volume_response`(muscle=hamstrings, weeklySets=8.3)

## Records

| Exercice | Record | Valeur | Jour |
| --- | --- | --- | --- |
| Muscle-up barre assisté élastique | max_reps | 4.0 | 2026-10-24 |
| Muscle-up barre négatif | max_reps | 4.0 | 2026-10-05 |
| Muscle-up barre strict | max_reps | 9.0 | 2026-10-12 |
| Traction explosive poitrine à la barre | max_reps | 4.0 | 2026-10-24 |
| Tenue haute false grip aux anneaux | max_hold_seconds | 30.0 | 2026-10-31 |
| Développé couché barre | one_rm_kg | 83.3 | 2026-12-15 |
| Développé militaire barre debout | one_rm_kg | 63.3 | 2026-11-24 |
| Élévation latérale haltères | one_rm_kg | 10.7 | 2026-10-27 |
| Face pull à la poulie corde | one_rm_kg | 58.6 | 2026-11-09 |
| Hip thrust à la barre | one_rm_kg | 141.8 | 2026-11-25 |
| Hollow body hold | max_hold_seconds | 45.0 | 2026-10-07 |
| Leg curl couché | one_rm_kg | 54.0 | 2026-11-25 |
| Mollets debout à la machine | one_rm_kg | 134.2 | 2026-10-21 |
| Pallof press debout | one_rm_kg | 33.9 | 2026-10-07 |
| Pushdown à la corde | one_rm_kg | 30.0 | 2026-12-01 |
| Rotation externe haltère couché sur le côté | one_rm_kg | 10.7 | 2026-11-03 |
| Roue abdominale à genoux | max_reps | 14.0 | 2026-12-16 |
| Rowing barre buste penché prise pronation | one_rm_kg | 80.0 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | one_rm_kg | 35.5 | 2026-10-22 |
| Rowing poulie basse assis au triangle | one_rm_kg | 63.0 | 2026-10-22 |
| Soulevé de terre roumain à la barre | one_rm_kg | 109.5 | 2026-12-09 |
| Tirage vertical poulie prise neutre | one_rm_kg | 87.8 | 2026-11-30 |
| Y raise sur banc incliné | one_rm_kg | 14.4 | 2026-12-15 |
| Dead hang lesté | max_hold_seconds | 83.0 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | max_hold_seconds | 9.0 | 2026-10-24 |
| Dips lesté de compétition | one_rm_kg | 123.4 | 2026-11-10 |
| Muscle-up lesté de compétition | one_rm_kg | 82.6 | 2026-11-09 |
| Muscle-up négatif lesté | one_rm_kg | 100.6 | 2026-11-21 |
| Pompe lestée au gilet | one_rm_kg | 111.1 | 2026-10-20 |
| Relevé de jambes suspendu lesté | one_rm_kg | 103.3 | 2026-12-12 |
| Squat de compétition | one_rm_kg | 114.2 | 2026-11-25 |
| Traction lestée de compétition | one_rm_kg | 117.9 | 2026-11-09 |
| Dips aux barres parallèles | max_reps | 64.0 | 2026-10-13 |
| Pompe classique | max_reps | 67.0 | 2026-10-13 |
| Traction pronation | max_reps | 27.0 | 2026-10-15 |
| Traction scapulaire | max_reps | 14.0 | 2026-10-19 |

## Séance prescrite — semaine 12, jour 1

Confiance 0.79 ; `adapt.readiness`(readiness=0.598).

- **Muscle-up lesté de compétition** : 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 3 @ 6.25 kg (7 fl.) · 2 @ 6.25 kg (7 fl.) — 87 % du 1RM, repos 240 s
  - `adapt.load_up`(deltaKg=5.0)
- **Traction lestée de compétition** : 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) · 4 @ 36.25 kg (7 fl.) — 85 % du 1RM, repos 300 s
  - `adapt.load_up`(deltaKg=7.5)
- **Rowing barre buste penché prise pronation** : 9 @ 62.5 kg (7 fl.) · 8 @ 62.5 kg (7 fl.) · 8 @ 62.5 kg (7 fl.) — 75 % du 1RM, repos 180 s
  - `adapt.load_up`(deltaKg=2.5)
- **Curl biceps à la barre EZ** : 12 @ 30 kg (7 fl.) · 10 @ 30 kg (7 fl.) — 72 % du 1RM, repos 90 s
  - `adapt.load_up`(deltaKg=2.5)
- **Face pull à la poulie corde** : 19 @ 47.5 kg (5 fl.) · 17 @ 47.5 kg (5 fl.) · 16 @ 47.5 kg (5 fl.) — 61 % du 1RM, repos 60 s
  - `adapt.load_up`(deltaKg=2.5)

## Journal du moteur (fin)

- n° 53, 2026-12-12, `session` : readiness=0.466, residual=-0.0076, sessionId=sim-68, unplannedFails=0, unrated=0, workSets=29
- n° 54, 2026-12-14, `session` : readiness=0.495, residual=-0.0146, sessionId=sim-70, unplannedFails=0, unrated=0, workSets=22
- n° 55, 2026-12-15, `session` : readiness=0.478, residual=-0.0132, sessionId=sim-71, unplannedFails=1, unrated=0, workSets=20
- n° 56, 2026-12-16, `session` : readiness=0.451, residual=-0.0137, sessionId=sim-72, unplannedFails=1, unrated=0, workSets=21
- n° 57, 2026-12-17, `session` : readiness=0.293, residual=-0.005, sessionId=sim-73, unplannedFails=0, unrated=0, workSets=20
- n° 58, 2026-12-18, `session` : readiness=0.436, residual=-0.0062, sessionId=sim-74, unplannedFails=1, unrated=0, workSets=13
- n° 59, 2026-12-19, `session` : readiness=0.483, residual=-0.0148, sessionId=sim-75, unplannedFails=0, unrated=0, workSets=14
- n° 60, 2026-12-21, `proposal` : adherence=0.0, fatigue=-0.1, id=volume:hamstrings:down:proprietaire-v33@12, kind=volume, progress=0.199, risk=0.0, threshold=0.65, utility=0.299
