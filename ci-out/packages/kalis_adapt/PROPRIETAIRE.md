# kalis_adapt — rejeu du programme importé du propriétaire

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` à partir de `test/fixtures/proprietaire.json.gz` : le programme de 40 semaines du propriétaire, importé sans changer sa structure (D5.10), et un journal **simulé** de ses 11 premières semaines (athlète `avance_street`, graine 0). 223 exercices du programme ne sont pas portés dans la fixture (sans correspondance au catalogue, ou format hors plage : montées en singles, tours, EMOM). Même rejeu à la main : `dart run kalis_adapt:replay --journal test/fixtures/proprietaire.json.gz`.

Moteur `kalis_adapt` 0.1.0. Journal : 65 séances, 1295 séries, du 2026-10-05 au 2026-12-19 ; « aujourd'hui » : 2026-12-21. Bloc `proprietaire-v33` (40 semaines).

## Résumé d'adaptation

- Semaines de données : 11 ; séances faites : 65 sur 67 prévues.
- Niveau de déblocage : `session_restructure` ; confiance globale : 0.71.
- Forme du jour (modèle) : 0.67 ; forme 297.90, fatigue 46.90 (unités du modèle).
- Faits marquants : `adapt.unlock_level`(level=session_restructure) ; `adapt.missed_sessions`(missed=2, planned=67).

## Capacités estimées

| Exercice | Capacité | ± | Tendance / semaine | Séries | Dernière séance |
| --- | --- | --- | --- | --- | --- |
| Muscle-up barre assisté élastique | 19.5 répétitions max | 2.3 | 0.02 | 31 | 2026-12-12 |
| Muscle-up barre négatif | 17.3 répétitions max | 1.4 | 0.00 | 36 | 2026-12-12 |
| Muscle-up barre strict | 9.1 répétitions max | 0.6 | -0.02 | 8 | 2026-12-19 |
| Traction explosive poitrine à la barre | 21.7 répétitions max | 2.5 | 0.03 | 41 | 2026-12-19 |
| Tenue haute false grip aux anneaux | 39.9 s (tenue max) | 2.2 | 0.09 | 40 | 2026-12-12 |
| Back squat barre haute | 103.6 kg (1RM, charge totale) | 20.4 | -0.10 | 48 | 2026-12-19 |
| Curl biceps à la barre EZ | 39.9 kg (1RM, charge totale) | 3.5 | 0.02 | 18 | 2026-12-14 |
| Curl marteau aux haltères | 15.5 kg (1RM, charge totale) | 1.5 | 0.02 | 18 | 2026-12-17 |
| Développé couché barre | 79.7 kg (1RM, charge totale) | 6.8 | 0.26 | 46 | 2026-12-15 |
| Développé militaire barre debout | 63.4 kg (1RM, charge totale) | 5.4 | -0.03 | 59 | 2026-12-15 |
| Élévation latérale haltères | 12.0 kg (1RM, charge totale) | 1.3 | 0.06 | 47 | 2026-12-18 |
| Face pull à la poulie corde | 72.4 kg (1RM, charge totale) | 8.5 | 0.11 | 160 | 2026-12-17 |
| Hip thrust à la barre | 137.1 kg (1RM, charge totale) | 11.0 | -0.09 | 44 | 2026-12-16 |
| Hollow body hold | 57.1 s (tenue max) | 2.5 | 0.08 | 56 | 2026-12-16 |
| Leg curl couché | 55.7 kg (1RM, charge totale) | 5.2 | -0.02 | 43 | 2026-12-16 |
| Mollets debout à la machine | 136.8 kg (1RM, charge totale) | 10.8 | -0.15 | 45 | 2026-12-16 |
| Pallof press debout | 33.9 kg (1RM, charge totale) | 3.4 | -0.06 | 48 | 2026-12-16 |
| Pushdown à la corde | 34.8 kg (1RM, charge totale) | 3.5 | 0.17 | 56 | 2026-12-18 |
| Rotation externe haltère couché sur le côté | 9.7 kg (1RM, charge totale) | 1.1 | -0.02 | 157 | 2026-12-18 |
| Roue abdominale à genoux | 16.7 répétitions max | 0.4 | 0.04 | 46 | 2026-12-16 |
| Rowing barre buste penché prise pronation | 76.8 kg (1RM, charge totale) | 5.8 | 0.12 | 84 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | 41.6 kg (1RM, charge totale) | 4.0 | 0.13 | 56 | 2026-12-17 |
| Rowing poulie basse assis au triangle | 65.4 kg (1RM, charge totale) | 6.8 | 0.04 | 43 | 2026-12-17 |
| Soulevé de terre roumain à la barre | 132.3 kg (1RM, charge totale) | 10.3 | 0.15 | 44 | 2026-12-16 |
| Tirage vertical poulie prise neutre | 94.4 kg (1RM, charge totale) | 8.8 | -0.01 | 44 | 2026-12-14 |
| Y raise sur banc incliné | 17.1 kg (1RM, charge totale) | 1.8 | 0.03 | 39 | 2026-12-15 |
| Dead hang lesté | 85.1 s (tenue max) | 1.8 | 0.09 | 39 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | 44.3 s (tenue max) | 6.6 | 0.06 | 21 | 2026-12-12 |
| Dips lesté de compétition | 128.7 kg (1RM, charge totale) | 8.7 | 0.05 | 76 | 2026-12-15 |
| Muscle-up lesté de compétition | 86.5 kg (1RM, charge totale) | 4.4 | -0.11 | 82 | 2026-12-14 |
| Muscle-up négatif lesté | 100.3 kg (1RM, charge totale) | 3.3 | 0.01 | 47 | 2026-12-12 |
| Pompe lestée au gilet | 106.7 kg (1RM, charge totale) | 8.4 | -0.18 | 56 | 2026-12-15 |
| Relevé de jambes suspendu lesté | 106.3 kg (1RM, charge totale) | 8.9 | 0.03 | 42 | 2026-12-19 |
| Squat de compétition | 120.2 kg (1RM, charge totale) | 6.7 | -0.01 | 67 | 2026-12-16 |
| Traction lestée de compétition | 123.1 kg (1RM, charge totale) | 7.9 | -0.05 | 74 | 2026-12-14 |
| Dips aux barres parallèles | 57.8 répétitions max | 1.2 | -0.61 | 56 | 2026-12-18 |
| Pompe classique | 58.3 répétitions max | 1.2 | -1.26 | 65 | 2026-12-18 |
| Traction pronation | 27.4 répétitions max | 0.6 | -0.01 | 64 | 2026-12-17 |
| Traction scapulaire | 40.7 répétitions max | 3.4 | 0.06 | 54 | 2026-12-17 |

## Propositions

- `volume:delt_anterior:down:proprietaire-v33@12` — volume (portée exercise), confiance 1.00, niveau requis `volume`, 24 changement(s) : `adapt.volume_down`(sets=1) ; `adapt.volume_response`(muscle=delt_anterior, weeklySets=27.5)
- `volume:triceps:down:proprietaire-v33@12` — volume (portée exercise), confiance 1.00, niveau requis `volume`, 24 changement(s) : `adapt.volume_down`(sets=1) ; `adapt.volume_response`(muscle=triceps, weeklySets=35.0)

## Records

| Exercice | Record | Valeur | Jour |
| --- | --- | --- | --- |
| Muscle-up barre assisté élastique | max_reps | 6.0 | 2026-10-24 |
| Muscle-up barre négatif | max_reps | 6.0 | 2026-10-05 |
| Muscle-up barre strict | max_reps | 9.0 | 2026-10-12 |
| Traction explosive poitrine à la barre | max_reps | 6.0 | 2026-10-24 |
| Tenue haute false grip aux anneaux | max_hold_seconds | 30.0 | 2026-10-31 |
| Curl biceps à la barre EZ | one_rm_kg | 37.1 | 2026-11-30 |
| Développé couché barre | one_rm_kg | 74.8 | 2026-12-01 |
| Développé militaire barre debout | one_rm_kg | 60.8 | 2026-12-01 |
| Élévation latérale haltères | one_rm_kg | 10.8 | 2026-10-27 |
| Hip thrust à la barre | one_rm_kg | 133.3 | 2026-12-02 |
| Hollow body hold | max_hold_seconds | 45.0 | 2026-10-07 |
| Leg curl couché | one_rm_kg | 52.0 | 2026-11-04 |
| Mollets debout à la machine | one_rm_kg | 135.7 | 2026-10-21 |
| Pallof press debout | one_rm_kg | 33.9 | 2026-10-07 |
| Pushdown à la corde | one_rm_kg | 30.0 | 2026-12-01 |
| Rotation externe haltère couché sur le côté | one_rm_kg | 10.0 | 2026-11-20 |
| Roue abdominale à genoux | max_reps | 14.0 | 2026-11-25 |
| Rowing barre buste penché prise pronation | one_rm_kg | 76.7 | 2026-12-14 |
| Rowing haltère unilatéral appui sur banc | one_rm_kg | 36.4 | 2026-12-17 |
| Rowing poulie basse assis au triangle | one_rm_kg | 63.3 | 2026-10-22 |
| Soulevé de terre roumain à la barre | one_rm_kg | 112.0 | 2026-12-09 |
| Tirage vertical poulie prise neutre | one_rm_kg | 84.5 | 2026-11-30 |
| Dead hang lesté | max_hold_seconds | 83.0 | 2026-12-17 |
| Isométrie lestée au point de blocage de dips | max_hold_seconds | 11.0 | 2026-10-24 |
| Dips lesté de compétition | one_rm_kg | 128.2 | 2026-11-24 |
| Muscle-up lesté de compétition | one_rm_kg | 82.1 | 2026-10-26 |
| Muscle-up négatif lesté | one_rm_kg | 102.2 | 2026-11-21 |
| Pompe lestée au gilet | one_rm_kg | 111.3 | 2026-10-20 |
| Relevé de jambes suspendu lesté | one_rm_kg | 103.3 | 2026-12-19 |
| Squat de compétition | one_rm_kg | 117.5 | 2026-11-25 |
| Traction lestée de compétition | one_rm_kg | 119.5 | 2026-11-23 |
| Dips aux barres parallèles | max_reps | 64.0 | 2026-10-13 |
| Pompe classique | max_reps | 67.0 | 2026-10-13 |
| Traction pronation | max_reps | 27.0 | 2026-10-15 |
| Traction scapulaire | max_reps | 20.0 | 2026-10-19 |

## Séance prescrite — semaine 12, jour 1

Confiance 0.80 ; `adapt.readiness`(readiness=0.666).

- **Muscle-up lesté de compétition** : 3 @ 5 kg (7 fl.) · 3 @ 5 kg (7 fl.) · 3 @ 5 kg (7 fl.) · 3 @ 5 kg (7 fl.) · 3–9 @ 5 kg (8 fl.) — 86 % du 1RM, repos 240 s
  - `adapt.load_up`(deltaKg=3.75) ; `adapt.benchmark_set`(rir=1.5)
- **Traction lestée de compétition** : 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4 @ 35 kg (7 fl.) · 4–10 @ 35 kg (8 fl.) — 85 % du 1RM, repos 300 s
  - `adapt.load_up`(deltaKg=7.5) ; `adapt.benchmark_set`(rir=1.5)
- **Rowing barre buste penché prise pronation** : 8 @ 60 kg (7 fl.) · 8 @ 60 kg (7 fl.) · 7 @ 60 kg (7 fl.) — 78 % du 1RM, repos 180 s
  - `adapt.load_up`(deltaKg=2.5)
- **Curl biceps à la barre EZ** : 13 @ 27.5 kg (7 fl.) · 11–17 @ 27.5 kg (8 fl.) — 69 % du 1RM, repos 90 s
  - `adapt.increment_coarse`(stepKg=2.5) ; `adapt.benchmark_set`(rir=1.5)
- **Face pull à la poulie corde** : 18 @ 45 kg (5 fl.) · 17 @ 45 kg (5 fl.) · 15 @ 45 kg (5 fl.) — 62 % du 1RM, repos 60 s

## Journal du moteur (fin)

- n° 54, 2026-12-14, `session` : readiness=0.592, residual=-0.0104, sessionId=sim-70, unplannedFails=0, unrated=0, workSets=22
- n° 55, 2026-12-15, `session` : readiness=0.571, residual=-0.0037, sessionId=sim-71, unplannedFails=0, unrated=0, workSets=20
- n° 56, 2026-12-16, `session` : readiness=0.548, residual=-0.0043, sessionId=sim-72, unplannedFails=0, unrated=0, workSets=21
- n° 57, 2026-12-17, `session` : readiness=0.4, residual=0.0015, sessionId=sim-73, unplannedFails=0, unrated=0, workSets=20
- n° 58, 2026-12-18, `session` : readiness=0.533, residual=-0.2082, sessionId=sim-74, unplannedFails=2, unrated=0, workSets=13
- n° 59, 2026-12-19, `session` : readiness=0.569, residual=-0.0167, sessionId=sim-75, unplannedFails=0, unrated=0, workSets=14
- n° 60, 2026-12-21, `proposal` : adherence=0.0, fatigue=-0.1, id=volume:delt_anterior:down:proprietaire-v33@12, kind=volume, progress=0.3, risk=0.0, threshold=0.65, utility=0.4
- n° 61, 2026-12-21, `proposal` : adherence=0.0, fatigue=-0.1, id=volume:triceps:down:proprietaire-v33@12, kind=volume, progress=0.3, risk=0.0, threshold=0.65, utility=0.4
