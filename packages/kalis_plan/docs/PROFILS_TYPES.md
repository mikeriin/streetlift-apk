# Profils types de kalis_plan

Fichier généré par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (kalis_plan 0.4.3, catalogue 1.1.0, règles 1.1.0) — ne pas modifier à la main ; `test/docs_test.dart` le compare au moteur.

Pour chacun des 40 profils des jeux de données de `kalis_core` : la passe 1 (exercices par séance), une revue simulée (« je ne sais pas faire » sur un exercice, puis remplacement d'un autre par sa variante équivalente), le diff, puis la passe 2 du programme revu. Notation d'une prescription : séries × plage · flammes visées · repos · charge de départ (ou part du 1RM visée).

## 1. `debutant_forme_generale_maison_2x30`

Débutant, forme générale, 2 × 30 min à la maison sans matériel.

Profil : general_fitness 100 % — mardi 30 min, vendredi 30 min — lieux maison — expérience beginner, 82 kg, né en 1994, male, santé standard.

### Passe 1

Note 0.957 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.95 · muscle_volume 0.95 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.60 · stimulus_fatigue 0.83 · preferences 1.00 · novelty 1.00.

- **mardi** (30 min, estimé 30 min) — `strength.full_body`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Marche rapide — conditioning `ca-marche-rapide`
- **vendredi** (30 min, estimé 30 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Pompe classique — secondary `sw-pompe`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Marche rapide — conditioning `ca-marche-rapide`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`

Dosage : cardio 38 % (visé 35 %), mobility 10 % (visé 15 %), generalFitness 52 % (visé 50 %) — erreur 4.8 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 5 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 5 [1.5-5], abs 3 [1.5-5], lower_back 3 [1.5-5], glutes 5 [1.5-5], quads 2 [1.5-5], hamstrings 1.5 [1.5-5], calves 1 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 5 séries ; chaîne postérieure 3 / genou 2 ; schémas de base 3/3.

### Revue simulée

- « Je ne sais pas faire » sur Pompe classique (`d1.2`) :
  - `exercise_added` jour 0 → Pompe sur les genoux (plan.reoptimized)
  - `exercise_removed` jour 0 : Pompe classique (plan.reoptimized)
  - `exercise_replaced` jour 1 : Pompe classique → Table inversée (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par Étirement fessier en figure 4 allongé (`d1.5`) :
  - `exercise_replaced` jour 1 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe sur les genoux | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s |
| Gainage latéral bras tendu | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Marche rapide | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Table inversée | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s |
| Air squat | 2×7-11 · 5 fl. · 90s | 3×7-11 · 5 fl. · 90s | 3×7-11 · 6 fl. · 90s | 3×7-11 · 7 fl. · 90s |
| Gainage latéral sur le coude | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Marche rapide | 9-10 min | 9-10 min | 9-10 min | 9-10 min |
| Étirement fessier en figure 4 allongé | 1×20-30 s · 10s | 1×20-30 s · 10s | 1×20-30 s · 10s | 1×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

## 2. `femme_45_musculation_salle_4x60`

Femme de 45 ans, musculation, 4 × 60 min en salle.

Profil : musculation 80 % + mobility 20 % — lundi 60 min, mardi 60 min, jeudi 60 min, samedi 60 min — lieux salle — 63 kg, né en 1981, female, santé standard.

### Passe 1

Note 0.972 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 0.99 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.pull`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Tirage vertical poulie prise large pronation — main `mu-tirage-vertical-prise-large-pronation`
  - Cuban press haltères — accessory `mu-cuban-press`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Pallof press debout — core `mu-pallof-press-debout`
  - Lancer rotatif au médecine-ball — core `mu-lancer-rotatif-medecine-ball`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`
- **mardi** (60 min, estimé 59 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Hip thrust à la barre — accessory `mu-hip-thrust-barre`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - W raise sur banc incliné — accessory `mu-w-raise-banc-incline`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Étirement adducteurs debout en fente latérale — cooldown `mo-adducteurs-fente-laterale`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **jeudi** (60 min, estimé 59 min) — `strength.upper`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Développé épaules à la Smith machine assis — secondary `mu-developpe-epaules-smith-assis`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **samedi** (60 min, estimé 60 min) — `strength.lower`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Lu raise — accessory `mu-lu-raise`
  - Mollets à la presse à cuisses — accessory `mu-mollets-presse`

Dosage : musculation 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 8.5 [8-16], delt_anterior 12 [8-16], delt_middle 9 [8-16], delt_posterior 8 [8-16], lats 11 [8-16], upper_back 13.5 [8-16], biceps 8.5 [8-16], triceps 10 [8-16], abs 9 [8-16], lower_back 9.5 [8-16], glutes 16 [8-16], quads 8.5 [8-16], hamstrings 7.5 [8-16], calves 8 [8-16]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 11 / poussée 9 séries ; chaîne postérieure 9 / genou 8 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Mollets debout à la machine (`d2.7`) :
  - `exercise_replaced` jour 2 : Mollets debout à la machine → Mobilisation cheville genou au mur (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
  - `exercise_removed` jour 3 : Mollets à la presse à cuisses (plan.reoptimized)
- Remplacement par Straddle en appui au mur (`d1.6`) :
  - `exercise_replaced` jour 1 : Étirement adducteurs debout en fente latérale → Straddle en appui au mur (plan.user_replaced)
  - `order_changed` jour 1 (plan.reoptimized)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Cuban press haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl biceps à la barre droite | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Lancer rotatif au médecine-ball | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Étirement du biceps au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement pectoral au cadre de porte | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 5 fl. · 180s · 32.5 kg | 4×2-5 · 6 fl. · 180s · 35 kg | TEST 3×1-3 · 9 fl. · 240s [3@40 5fl. / 1@45 7fl. / 1@47.5 9fl.] |
| Hip thrust à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| W raise sur banc incliné | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Straddle en appui au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 20 kg | 3×6-10 · 5 fl. · 120s · 20 kg | 3×6-10 · 6 fl. · 120s · 20 kg | 3×6-10 · 7 fl. · 120s · 20 kg | 2×6-10 · 3 fl. · 120s · 20 kg |
| Rowing inversé à la Smith machine | 3×6-12 · 3 fl. · 90s | 4×6-12 · 3 fl. · 90s | 4×6-12 · 4 fl. · 90s | 4×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Rowing poulie basse assis au triangle | CALIBRAGE 3×8-12 · 3 fl. · 120s | 4×8-12 · 3 fl. · 120s | 4×8-12 · 4 fl. · 120s | 4×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Développé épaules à la Smith machine assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Étirement du biceps au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Back squat barre haute | 3×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 5 fl. · 180s · 32.5 kg | 4×2-5 · 6 fl. · 180s · 35 kg | 2×3-6 · 2 fl. · 180s · 32.5 kg |
| Soulevé de terre conventionnel | 2×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 6 fl. · 120s · 42.5 kg | 3×6-10 · 7 fl. · 120s · 45 kg | 2×6-10 · 3 fl. · 120s · 42.5 kg |
| Développé couché Smith machine | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Lu raise | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

## 3. `coureur_cardio_3x45`

Coureur : cardio principal, mobilité et musculation en appoint, 3 × 45 min dehors.

Profil : cardio 70 % + musculation 20 % + mobility 10 % — mardi 45 min (maison), jeudi 45 min, dimanche 75 min (exterieur) — lieux exterieur, maison — expérience intermediate, 68 kg, né en 1988, male, santé standard.

### Passe 1

Note 0.933 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.93 · muscle_volume 0.69 · pattern_balance 0.93 · discipline_structure 0.95 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.91 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 45 min) — `strength.full_body`
  - Pompe pike — main `sw-pompe-pike`
  - Air squat — secondary `mu-air-squat`
  - Nordic hamstring curl assisté à l'élastique — accessory `mu-nordic-hamstring-curl-assiste`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **jeudi** (45 min, estimé 43 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Planche RKC — core `mu-planche-rkc`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **dimanche** (75 min, estimé 75 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`

Dosage : musculation 25 % (visé 20 %), cardio 66 % (visé 70 %), mobility 10 % (visé 10 %) — erreur 4.5 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 2 [2-5], delt_anterior 2 [2-5], delt_middle 2.5 [2-5], delt_posterior 4 [2-5], lats 2 [2-5], upper_back 5 [2-5], biceps 1.5 [2-5], triceps 3 [2-5], abs 5 [2-5], lower_back 2 [2-5], glutes 2 [2-5], quads 2 [2-5], hamstrings 2 [2-5], calves 2 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 2 / poussée 2 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 4/5.

### Revue simulée

- « Je ne sais pas faire » sur Face pull à l'élastique (`d0.4`) :
  - `exercise_replaced` jour 0 : Face pull à l'élastique → Band pull-apart (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Étirement fessier en figure 4 allongé (`d0.6`) :
  - `exercise_replaced` jour 0 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)
  - `order_changed` jour 0 (plan.reoptimized)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Air squat | 2×15-22 · 5 fl. · 90s | 2×15-22 · 5 fl. · 90s | 2×15-22 · 6 fl. · 90s | 2×15-22 · 7 fl. · 90s | 1×15-22 · 3 fl. · 90s |
| Nordic hamstring curl assisté à l'élastique | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Band pull-apart | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 2×20-40 s · 4 fl. · 60s | 2×20-40 s · 5 fl. · 60s | 2×20-40 s · 6 fl. · 60s | 1×20-40 s · 2 fl. · 60s |
| Étirement du biceps au mur | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 18-20 min | 22-25 min | 22-25 min | 22-25 min | TEST 1×10000 m |
| Tirage bras tendus à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 49-55 min | 63-70 min | 63-70 min | 67-75 min | 40-45 min |

## 4. `crossfit_5x60`

CrossFit, 5 × 60 min en box.

Profil : crossfit 80 % + mobility 20 % — lundi 60 min, mardi 60 min, mercredi 60 min, vendredi 60 min, samedi 60 min — lieux salle — 66 kg, né en 1996, female, santé standard.

### Passe 1

Note 0.957 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.85 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.pull`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Épaulé-jeté — main `mu-epaule-jete`
  - Traction aux anneaux — secondary `sw-traction-anneaux`
  - Cuban press haltères — accessory `mu-cuban-press`
  - Burpee latéral par-dessus la barre — conditioning `cf-burpee-lateral-barre`
  - Montées de genoux — conditioning `cf-high-knees`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **mardi** (60 min, estimé 58 min) — `mobility`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Inchworm (chenille) — warmup `mo-inchworm`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Hollow body hold — core `mu-hollow-body-hold`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
  - Rameur en endurance — conditioning `ca-rameur-endurance`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs du poignet bras tendu — cooldown `mo-etirement-flechisseurs-poignet-bras-tendu`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
  - Sleeper stretch — cooldown `mo-sleeper-stretch`
- **mercredi** (60 min, estimé 59 min) — `strength.upper`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Traction pronation — secondary `sw-traction-pronation`
  - Pompe à un bras assistée main sur ballon — secondary `cd-pompe-un-bras-assistee`
  - Lu raise — accessory `mu-lu-raise`
  - Burpee box jump-over — conditioning `cf-burpee-box-jump-over`
  - Traction kipping — conditioning `cf-traction-kipping`
- **vendredi** (60 min, estimé 54 min) — `strength.lower`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Lancer arrière par-dessus la tête au médecine-ball — secondary `mu-lancer-arriere-medecine-ball`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Planche RKC — core `mu-planche-rkc`
  - Devil press — conditioning `cf-devil-press`
  - Burpee — conditioning `cf-burpee`
  - Pogo jumps — conditioning `cf-pogo-jumps`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **samedi** (60 min, estimé 57 min) — `skills`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Balancier creux-cambré à la barre — skill `cd-kip-swing-barre`
  - Skin the cat tenu — skill `cs-skin-the-cat-tenu`
  - Développé militaire kettlebell — main `mu-developpe-kettlebell`
  - Burpee broad jump — conditioning `cf-burpee-broad-jump`
  - Thruster à la barre — conditioning `cf-thruster-barre`
  - Tuck jumps — conditioning `cf-tuck-jumps`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`

Dosage : crossfit 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9.5 [7.5-15.5], delt_anterior 15.5 [7.5-15.5], delt_middle 9 [7.5-15.5], delt_posterior 4.5 [7.5-15.5], lats 13 [7.5-15.5], upper_back 9 [7.5-15.5], biceps 8.5 [7.5-15.5], triceps 15.5 [7.5-15.5], abs 11 [7.5-15.5], lower_back 9 [7.5-15.5], glutes 14 [7.5-15.5], quads 10 [7.5-15.5], hamstrings 8 [7.5-15.5], calves 7.5 [7.5-15.5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 16 / poussée 12 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Mobilité hanches 90/90 passive (`d1.7`) :
  - `exercise_replaced` jour 1 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
  - `exercise_removed` jour 4 : Mobilité hanches 90/90 passive (plan.reoptimized)
- Remplacement par Thruster aux haltères (`d4.6`) :
  - `exercise_replaced` jour 4 : Thruster à la barre → Thruster aux haltères (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Épaulé-jeté | 4×2-3 · 3 fl. · 150s · 40 kg | 5×2-3 · 3 fl. · 150s · 40 kg | 5×2-3 · 4 fl. · 150s · 40 kg | 5×2-3 · 5 fl. · 150s · 40 kg | 3×2-3 · 1 fl. · 150s · 37.5 kg |
| Traction aux anneaux | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Cuban press haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Burpee latéral par-dessus la barre | 3×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 2×8-12 · 15s · rounds wod-d0 |
| Montées de genoux | 3×30-40 s · 15s · rounds wod-d0 | 4×30-40 s · 15s · rounds wod-d0 | 4×30-40 s · 15s · rounds wod-d0 | 4×30-40 s · 15s · rounds wod-d0 | 2×30-40 s · 15s · rounds wod-d0 |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Inchworm (chenille) | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Hollow body hold | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Rameur en endurance | 9-10 min | 13-15 min | 13-15 min | 13-15 min | 9-10 min |
| Étirement des fléchisseurs du poignet bras tendu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Sleeper stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Soulevé de terre jambes tendues | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Traction pronation | 2×3-4 · 5 fl. · 90s | 3×3-4 · 5 fl. · 90s | 3×3-4 · 6 fl. · 90s | 3×3-4 · 7 fl. · 90s | 2×3-4 · 3 fl. · 90s |
| Pompe à un bras assistée main sur ballon | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Lu raise | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Burpee box jump-over | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |
| Traction kipping | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Lancer arrière par-dessus la tête au médecine-ball | 2×5-8 · 3 fl. · 90s | 3×5-8 · 3 fl. · 90s | 3×5-8 · 4 fl. · 90s | 3×5-8 · 5 fl. · 90s | 2×5-8 · 1 fl. · 90s |
| Back squat barre haute | 2×5-8 · 4 fl. · 150s · 50 kg | 3×5-8 · 4 fl. · 150s · 50 kg | 3×5-8 · 5 fl. · 150s · 52.5 kg | 3×5-8 · 6 fl. · 150s · 52.5 kg | 2×5-8 · 2 fl. · 150s · 50 kg |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Devil press | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Burpee | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Pogo jumps | 4×30-40 s · 15s · rounds wod-d3 | 5×30-40 s · 15s · rounds wod-d3 | 5×30-40 s · 15s · rounds wod-d3 | 5×30-40 s · 15s · rounds wod-d3 | 3×30-40 s · 15s · rounds wod-d3 |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Balancier creux-cambré à la barre | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Skin the cat tenu | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Développé militaire kettlebell | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Burpee broad jump | 3×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 2×8-12 · 15s · rounds wod-d4 |
| Thruster aux haltères | 3×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 2×8-12 · 15s · rounds wod-d4 |
| Tuck jumps | 4×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 3×8-12 · 15s · rounds wod-d4 |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 5. `calisthenie_figures_4x75`

Calisthénie orientée figures (front lever, planche), 4 × 75 min au parc.

Profil : calisthenics 80 % + mobility 20 % — lundi 75 min, mercredi 75 min, vendredi 75 min, samedi 75 min — lieux exterieur, maison — 70 kg, né en 1999, male, santé standard.

### Passe 1

Note 0.953 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.96 · pattern_balance 1.00 · discipline_structure 0.88 · time_use 0.95 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.80 · preferences 0.90 · novelty 1.00.

- **lundi** (75 min, estimé 58 min) — `skills`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Planche tuck — skill `cs-planche-tuck`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Traction pronation — main `sw-traction-pronation`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Superman dynamique — core `mu-superman`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`
- **mercredi** (75 min, estimé 58 min) — `skills`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Handstand libre — skill `cs-handstand`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Traction aux anneaux — main `sw-traction-anneaux`
  - Étirement de l'élévateur de la scapula — cooldown `mo-etirement-elevateur-scapula`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`
- **vendredi** (75 min, estimé 59 min) — `skills`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Planche tuck — skill `cs-planche-tuck`
  - Back lever une jambe — skill `cs-back-lever-une-jambe`
  - Handstand libre — skill `cs-handstand`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Étirement des fléchisseurs du poignet bras tendu — cooldown `mo-etirement-flechisseurs-poignet-bras-tendu`
- **samedi** (75 min, estimé 59 min) — `strength.lower`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Skater squat — main `sw-skater-squat`
  - Hip airplane — accessory `mu-hip-airplane`
  - Arch rocks — core `mu-arch-rocks`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : calisthenics 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 11 [8-16], delt_anterior 14 [8-16], delt_middle 6 [8-16], delt_posterior 9 [8-16], lats 16 [8-16], upper_back 13 [8-16], biceps 9.5 [8-16], triceps 9 [8-16], abs 12 [8-16], lower_back 6 [8-16], glutes 9 [8-16], quads 12 [8-16], hamstrings 4.5 [8-16], calves 0 [0-16]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 22 / poussée 20 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Pike assis passif (`d3.7`) :
  - `exercise_replaced` jour 3 : Pike assis passif → Demi-grand écart (half split) (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par L-sit aux barres parallèles (`d3.2`) :
  - `exercise_replaced` jour 3 : L-sit sur parallettes → L-sit aux barres parallèles (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | TEST 2×1-12 s · 10 fl. · 180s |
| Planche tuck | 4×5-7 s · 4 fl. · 120s | 5×5-7 s · 4 fl. · 120s | 5×5-7 s · 5 fl. · 120s | 5×5-7 s · 6 fl. · 120s | TEST 2×1-14 s · 10 fl. · 180s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Traction pronation | 2×7-10 · 5 fl. · 90s | 3×7-10 · 5 fl. · 90s | 3×7-10 · 6 fl. · 90s | 3×7-10 · 7 fl. · 90s | 2×7-10 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Superman dynamique | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | 2×4-6 s · 2 fl. · 120s |
| Handstand libre | 5×7-11 s · 4 fl. · 120s | 5×7-11 s · 4 fl. · 120s | 6×7-11 s · 5 fl. · 120s | 6×7-11 s · 6 fl. · 120s | 4×7-11 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Traction aux anneaux | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Étirement de l'élévateur de la scapula | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | 2×4-6 s · 2 fl. · 120s |
| Planche tuck | 4×5-7 s · 4 fl. · 120s | 5×5-7 s · 4 fl. · 120s | 5×5-7 s · 5 fl. · 120s | 5×5-7 s · 6 fl. · 120s | 3×5-7 s · 2 fl. · 120s |
| Back lever une jambe | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Handstand libre | 4×7-11 s · 4 fl. · 120s | 5×7-11 s · 4 fl. · 120s | 5×7-11 s · 5 fl. · 120s | 5×7-11 s · 6 fl. · 120s | 3×7-11 s · 2 fl. · 120s |
| Pont dorsal au sol | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| L-sit aux barres parallèles | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Skater squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 6. `street_streetlifting_4x90`

Mode street, principale streetlifting (60/25/15), 4 × 90 min.

Profil : streetlifting 60 % + street_workout 25 % + calisthenics 15 % — lundi 90 min, mardi 90 min, jeudi 90 min, samedi 90 min — lieux salle, exterieur — mode street, 78 kg, né en 1997, male, santé standard.

### Passe 1

Note 0.955 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.97 · muscle_volume 0.94 · pattern_balance 1.00 · discipline_structure 0.93 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.60 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 86 min) — `strength.full_body`
  - Back lever — skill `cs-back-lever`
  - Planche une jambe — skill `cs-planche-une-jambe`
  - Squat de compétition — main `sl-squat-competition`
  - Rack pull — secondary `mu-rack-pull`
  - Hip thrust à la barre — accessory `mu-hip-thrust-barre`
  - Élévation latérale à la poulie câble derrière le dos — accessory `mu-elevation-laterale-poulie-derriere-dos`
  - Pompe scapulaire — accessory `sw-pompe-scapulaire`
- **mardi** (90 min, estimé 82 min) — `strength.upper`
  - Front lever row tuck — skill `cd-front-lever-row-tuck`
  - Muscle-up lesté de compétition — main `sl-muscle-up-leste`
  - Traction lestée de compétition — main `sl-traction-lestee`
  - Isométrie lestée en appui aux barres parallèles — accessory `sl-dips-isometrie-lestee-appui`
  - Suspension en supination — accessory `sw-suspension-supination`
  - Arch rocks — core `mu-arch-rocks`
  - Knees-to-elbows — core `sw-knees-to-elbows`
- **jeudi** (90 min, estimé 83 min) — `strength.upper`
  - Dips lesté de compétition — main `sl-dips-leste`
  - Muscle-up lesté de compétition — main `sl-muscle-up-leste`
  - Dips aux barres parallèles prise inversée — secondary `sw-dips-prise-inversee`
  - Traction pronation — secondary `sw-traction-pronation`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **samedi** (90 min, estimé 84 min) — `strength.full_body`
  - Squat de compétition — main `sl-squat-competition`
  - Dips aux anneaux — secondary `sw-dips-anneaux`
  - Pistol squat — secondary `sw-pistol-squat`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Isométrie lestée en haut de traction — accessory `sl-traction-isometrie-lestee-haute`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`

Dosage : streetWorkout 25 % (visé 25 %), streetlifting 61 % (visé 60 %), calisthenics 15 % (visé 15 %) — erreur 0.5 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 20.5 [12-20], delt_anterior 21 [12-20], delt_middle 9.5 [12-20], delt_posterior 15 [12-20], lats 20 [12-20], upper_back 19.5 [12-20], biceps 19 [12-20], triceps 19.5 [12-20], abs 14 [12-20], lower_back 11 [12-20], glutes 20 [12-20], quads 18.5 [12-20], hamstrings 13.5 [12-20], calves 5 [0-20]. Groupes majeurs dans leur bande : 76 %.

Équilibre : tirage 28 / poussée 26 séries ; chaîne postérieure 10 / genou 14 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Muscle-up lesté de compétition (`d1.2`) :
  - `exercise_replaced` jour 1 : Muscle-up lesté de compétition → Muscle-up négatif lesté (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
  - `exercise_added` jour 2 → Traction haute lestée (high pull) (plan.reoptimized)
  - `exercise_removed` jour 2 : Muscle-up lesté de compétition (plan.reoptimized)
- Remplacement par Band pull-apart (`d3.6`) :
  - `exercise_replaced` jour 3 : Face pull à l'élastique → Band pull-apart (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Back lever | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 6×5-10 s · 4 fl. · 120s | 6×5-10 s · 5 fl. · 120s | 6×5-10 s · 6 fl. · 120s | 4×5-10 s · 2 fl. · 120s |
| Planche une jambe | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 6×5-10 s · 4 fl. · 120s | 6×5-10 s · 5 fl. · 120s | 6×5-10 s · 6 fl. · 120s | 4×5-10 s · 2 fl. · 120s |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 75 kg | 4×3-6 · 5 fl. · 180s · 75 kg | 5×3-6 · 5 fl. · 180s · 75 kg | 5×3-6 · 6 fl. · 180s · 75 kg | 5×2-5 · 7 fl. · 180s · 80 kg | 3×3-6 · 3 fl. · 180s · 72.5 kg |
| Rack pull | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Hip thrust à la barre | CALIBRAGE 2×10-15 · 6 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 2×10-15 · 8 fl. · 75s | 1×10-15 · 4 fl. · 75s |
| Élévation latérale à la poulie câble derrière le dos | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Pompe scapulaire | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Front lever row tuck | 5×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 6×2-5 · 4 fl. · 150s | 6×2-5 · 5 fl. · 150s | 6×2-5 · 6 fl. · 150s | 4×2-5 · 2 fl. · 150s |
| Traction lestée de compétition | 5×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 5 fl. · 180s · 0 kg | 6×3-6 · 5 fl. · 180s · 0 kg | 6×3-6 · 6 fl. · 180s · 0 kg | 6×2-5 · 7 fl. · 180s · 1.25 kg | TEST 3×1-3 · 9 fl. · 240s [3@8.75 5fl. / 1@18.75 7fl. / 1@25 9fl.] |
| Muscle-up négatif lesté | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 3×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Isométrie lestée en appui aux barres parallèles | 2×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 3×5-12 s · 7 fl. · 60s | 2×5-12 s · 3 fl. · 60s |
| Suspension en supination | 2×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 3×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Arch rocks | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Knees-to-elbows | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Dips lesté de compétition | 5×3-6 · 5 fl. · 180s · 7.5 kg | 5×3-6 · 5 fl. · 180s · 7.5 kg | 6×3-6 · 5 fl. · 180s · 7.5 kg | 6×3-6 · 6 fl. · 180s · 8.75 kg | 6×2-5 · 7 fl. · 180s · 12.5 kg | 4×3-6 · 3 fl. · 180s · 5 kg |
| Traction haute lestée (high pull) | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Dips aux barres parallèles prise inversée | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 3×7-11 · 5 fl. · 90s | 4×7-11 · 5 fl. · 90s | 4×7-11 · 5 fl. · 90s | 4×7-11 · 6 fl. · 90s | 4×7-11 · 7 fl. · 90s | 2×7-11 · 3 fl. · 90s |
| Curl biceps à la barre droite | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 75 kg | 4×3-6 · 5 fl. · 180s · 75 kg | 5×3-6 · 5 fl. · 180s · 75 kg | 5×3-6 · 6 fl. · 180s · 75 kg | 5×2-5 · 7 fl. · 180s · 80 kg | 3×3-6 · 3 fl. · 180s · 72.5 kg |
| Dips aux anneaux | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pistol squat | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Soulevé de terre conventionnel | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Isométrie lestée en haut de traction | 1×5-12 s · 5 fl. · 60s | 1×5-12 s · 5 fl. · 60s | 1×5-12 s · 5 fl. · 60s | 1×5-12 s · 6 fl. · 60s | 1×5-12 s · 7 fl. · 60s | 1×5-12 s · 3 fl. · 60s |
| Band pull-apart | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de genoux oblique suspendu | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 7. `street_sets_reps_4x60`

Mode street, principale sets & reps (20/60/20), 4 × 60 min au parc.

Profil : street_workout 60 % + streetlifting 20 % + calisthenics 20 % — lundi 60 min, mercredi 60 min, vendredi 60 min, dimanche 60 min — lieux exterieur — mode street, 65 kg, né en 2001, male, santé standard.

### Passe 1

Note 0.951 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.97 · muscle_volume 0.93 · pattern_balance 0.99 · discipline_structure 0.93 · time_use 0.99 · variety 1.00 · exercise_fit 0.61 · stimulus_fatigue 0.73 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.full_body`
  - Handstand libre — skill `cs-handstand`
  - Shrimp squat débutant (genou et pointe au sol) — main `sw-shrimp-squat-bras-libres`
  - Skater squat — secondary `sw-skater-squat`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Arch rocks — core `mu-arch-rocks`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mercredi** (60 min, estimé 59 min) — `strength.upper`
  - Traction pronation — main `sw-traction-pronation`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - HSPU au mur dos au mur — secondary `cd-hspu-mur-dos`
  - Pompe sphinx — accessory `sw-pompe-sphinx`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - V-up — core `mu-v-up`
- **vendredi** (60 min, estimé 60 min) — `strength.full_body`
  - Front lever — skill `cs-front-lever`
  - Traction archer — main `sw-traction-archer`
  - Pistol squat négatif — secondary `sw-pistol-squat-negatif`
  - Pompe classique — secondary `sw-pompe`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
- **dimanche** (60 min, estimé 57 min) — `strength.pull`
  - Muscle-up barre strict — skill `cd-muscle-up-barre-strict`
  - Traction typewriter — main `sw-traction-typewriter`
  - Dead hang — accessory `sw-dead-hang`
  - Row scapulaire — accessory `sw-row-scapulaire`
  - Knees-to-elbows — core `sw-knees-to-elbows`
  - Superman dynamique — core `mu-superman`

Dosage : streetWorkout 59 % (visé 60 %), streetlifting 20 % (visé 20 %), calisthenics 21 % (visé 20 %) — erreur 0.9 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 12.5 [12-20], delt_anterior 15.5 [12-20], delt_middle 7.5 [12-20], delt_posterior 12 [12-20], lats 18 [12-20], upper_back 20 [12-20], biceps 15 [12-20], triceps 20 [12-20], abs 15 [12-20], lower_back 6 [12-20], glutes 16 [12-20], quads 13 [12-20], hamstrings 5 [12-20], calves 3 [0-20]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 19.5 / poussée 18.5 séries ; chaîne postérieure 7 / genou 9 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Relevé de jambes tendues suspendu (`d1.6`) :
  - `exercise_replaced` jour 1 : Relevé de jambes tendues suspendu → Flutter kicks (plan.user_cannot_do, plan.variant_easier)
  - `exercise_removed` jour 3 : Knees-to-elbows (plan.reoptimized)
- Remplacement par Front lever half-lay (`d2.1`) :
  - `exercise_replaced` jour 2 : Front lever → Front lever half-lay (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Shrimp squat débutant (genou et pointe au sol) | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Skater squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction pronation | 4×9-13 · 5 fl. · 90s | 4×9-13 · 5 fl. · 90s | 5×9-13 · 5 fl. · 90s | 5×9-13 · 6 fl. · 90s | 5×9-13 · 7 fl. · 90s | TEST 1×1-30 · 10 fl. · 180s |
| Dips aux barres parallèles | 3×15-22 · 5 fl. · 90s | 4×15-22 · 5 fl. · 90s | 4×15-22 · 5 fl. · 90s | 4×15-22 · 6 fl. · 90s | 4×15-22 · 7 fl. · 90s | 2×15-22 · 3 fl. · 90s |
| HSPU au mur dos au mur | 3×3-8 · 5 fl. · 90s | 4×3-8 · 5 fl. · 90s | 4×3-8 · 5 fl. · 90s | 4×3-8 · 6 fl. · 90s | 4×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Pompe sphinx | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Flutter kicks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| V-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Front lever half-lay | 2×5-10 s · 4 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 3×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Traction archer | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 5×6-12 · 5 fl. · 90s | 5×6-12 · 6 fl. · 90s | 5×6-12 · 7 fl. · 90s | 3×6-12 · 3 fl. · 90s |
| Pistol squat négatif | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pompe classique | 3×22-30 · 5 fl. · 90s | 4×22-30 · 5 fl. · 90s | 4×22-30 · 5 fl. · 90s | 4×22-30 · 6 fl. · 90s | 4×22-30 · 7 fl. · 90s | 2×22-30 · 3 fl. · 90s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Muscle-up barre strict | 5×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 6×2-5 · 4 fl. · 150s | 6×2-5 · 5 fl. · 150s | 6×2-5 · 6 fl. · 150s | 4×2-5 · 2 fl. · 150s |
| Traction typewriter | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 5×6-12 · 5 fl. · 90s | 5×6-12 · 6 fl. · 90s | 5×6-12 · 7 fl. · 90s | 3×6-12 · 3 fl. · 90s |
| Dead hang | 3×20-40 s · 5 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 6 fl. · 60s | 4×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Row scapulaire | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Superman dynamique | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 8. `street_calisthenie_5x60`

Mode street, principale calisthénie (0/40/60), 5 × 60 min.

Profil : calisthenics 60 % + street_workout 40 % — lundi 60 min, mardi 60 min, jeudi 60 min, vendredi 60 min, dimanche 60 min — lieux exterieur, maison — mode street, 54 kg, né en 1998, female, santé standard.

### Passe 1

Note 0.964 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.96 · time_use 1.00 · variety 1.00 · exercise_fit 0.63 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Handstand libre — skill `cs-handstand`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Compression pike assis — skill `cs-compression-pike`
  - Shrimp squat débutant (genou et pointe au sol) — main `sw-shrimp-squat-bras-libres`
  - Skater squat — secondary `sw-skater-squat`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mardi** (60 min, estimé 57 min) — `skills`
  - Handstand libre — skill `cs-handstand`
  - Suspension un bras — skill `cs-suspension-un-bras`
  - German hang — skill `cs-german-hang`
  - Support hold aux anneaux — skill `cs-support-anneaux`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Suspension en supination — accessory `sw-suspension-supination`
- **jeudi** (60 min, estimé 58 min) — `strength.pull`
  - Suspension un bras — skill `cs-suspension-un-bras`
  - Balancier creux-cambré à la barre — skill `cd-kip-swing-barre`
  - Pistol squat négatif — main `sw-pistol-squat-negatif`
  - Traction pronation — secondary `sw-traction-pronation`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Arch hold — core `mu-arch-hold`
- **vendredi** (60 min, estimé 54 min) — `skills`
  - Handstand libre — skill `cs-handstand`
  - Wall walk — skill `cd-wall-walk`
  - German hang — skill `cs-german-hang`
  - Planche lean — skill `cs-planche-lean`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **dimanche** (60 min, estimé 55 min) — `strength.upper`
  - Handstand dos au mur — skill `cs-handstand-dos-au-mur`
  - Front lever assisté élastique — skill `cs-front-lever-assiste-elastique`
  - Traction explosive poitrine à la barre — main `cd-traction-explosive-poitrine-barre`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Nordic hamstring curl assisté à l'élastique — accessory `mu-nordic-hamstring-curl-assiste`
  - Dead hang — accessory `sw-dead-hang`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`

Dosage : streetWorkout 40 % (visé 40 %), calisthenics 60 % (visé 60 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 12.5 [8-16], delt_anterior 18 [8-16], delt_middle 9 [8-16], delt_posterior 9 [8-16], lats 16.5 [8-16], upper_back 15 [8-16], biceps 16 [8-16], triceps 14 [8-16], abs 16 [8-16], lower_back 7.5 [8-16], glutes 12.5 [8-16], quads 14 [8-16], hamstrings 8.5 [8-16], calves 6 [0-16]. Groupes majeurs dans leur bande : 82 %.

Équilibre : tirage 34.5 / poussée 31.5 séries ; chaîne postérieure 8 / genou 9 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Balancier creux-cambré à la barre (`d2.2`) :
  - `exercise_replaced` jour 2 : Balancier creux-cambré à la barre → Pull-over à la barre (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par Gainage latéral bras tendu (`d3.5`) :
  - `exercise_replaced` jour 3 : Gainage latéral sur le coude → Gainage latéral bras tendu (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 2×5-10 s · 4 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 3×5-10 s · 6 fl. · 120s | TEST 2×1-30 s · 10 fl. · 180s |
| Tenue menton au-dessus de la barre supination | 2×10-20 s · 4 fl. · 120s | 3×10-20 s · 4 fl. · 120s | 3×10-20 s · 5 fl. · 120s | 3×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Compression pike assis | 2×10-20 s · 4 fl. · 120s | 3×10-20 s · 4 fl. · 120s | 3×10-20 s · 5 fl. · 120s | 3×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Shrimp squat débutant (genou et pointe au sol) | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Skater squat | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Relevé de genoux oblique suspendu | 2×8-12 · 4 fl. · 60s | 2×8-12 · 4 fl. · 60s | 2×8-12 · 5 fl. · 60s | 2×8-12 · 6 fl. · 60s | 1×8-12 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Suspension un bras | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| German hang | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Support hold aux anneaux | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Nordic hamstring curl négatif | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Suspension en supination | 2×20-40 s · 4 fl. · 60s | 2×20-40 s · 4 fl. · 60s | 2×20-40 s · 5 fl. · 60s | 2×20-40 s · 6 fl. · 60s | 1×20-40 s · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Pull-over à la barre | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Suspension un bras | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Pistol squat négatif | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×3-4 · 5 fl. · 90s | 3×3-4 · 5 fl. · 90s | 3×3-4 · 6 fl. · 90s | 3×3-4 · 7 fl. · 90s | 2×3-4 · 3 fl. · 90s |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Arch hold | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Wall walk | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| German hang | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Planche lean | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Gainage latéral bras tendu | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand dos au mur | 3×15-22 s · 4 fl. · 120s | 4×15-22 s · 4 fl. · 120s | 4×15-22 s · 5 fl. · 120s | 4×15-22 s · 6 fl. · 120s | 2×15-22 s · 2 fl. · 120s |
| Front lever assisté élastique | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Traction explosive poitrine à la barre | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Dips aux barres parallèles | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| Nordic hamstring curl assisté à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Dead hang | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Relevé de jambes tendues suspendu | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |

## 9. `blessure_epaule_musculation_3x60`

Musculation avec une blessure d'épaule droite (gêne 6/10).

Profil : musculation 100 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 88 kg, né en 1985, male, santé standard, shoulder gêne 6/10.

### Passe 1

Note 0.969 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.94 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.99 · time_use 1.00 · variety 1.00 · exercise_fit 0.73 · stimulus_fatigue 0.69 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Barre au front à la barre EZ — accessory `mu-barre-au-front-ez`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Halo kettlebell — accessory `mu-halo-kettlebell`
  - Traction scapulaire — accessory `sw-traction-scapulaire`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`
- **mercredi** (60 min, estimé 59 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre jambes tendues — secondary `mu-souleve-de-terre-jambes-tendues`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Drag curl à la barre — accessory `mu-drag-curl-barre`
  - Y raise sur banc incliné — accessory `mu-y-raise-banc-incline`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Sit-up — core `mu-sit-up`
- **vendredi** (60 min, estimé 59 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Extension triceps couchée à la poulie — accessory `mu-extension-couchee-poulie`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Pallof press debout — core `mu-pallof-press-debout`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [8-16], delt_anterior 10.5 [8-16], delt_middle 6 [8-16], delt_posterior 7.5 [8-16], lats 9 [8-16], upper_back 10.5 [8-16], biceps 10.5 [8-16], triceps 15 [8-16], abs 9 [8-16], lower_back 13.5 [8-16], glutes 15 [8-16], quads 12 [8-16], hamstrings 9 [8-16], calves 7.5 [8-16]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 9 / genou 9 ; schémas de base 5/5.

### Revue simulée

- « Je ne sais pas faire » sur Barre au front à la barre EZ (`d0.3`) :
  - `exercise_replaced` jour 0 : Barre au front à la barre EZ → Barre au front aux haltères (plan.user_cannot_do, plan.variant_easier)
  - `exercise_removed` jour 2 : Extension triceps couchée à la poulie (plan.reoptimized)
- Remplacement par Y raise sur banc incliné (`d0.5`) :
  - `exercise_replaced` jour 0 : Halo kettlebell → Y raise sur banc incliné (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 6 fl. · 120s · 67.5 kg | 3×6-10 · 7 fl. · 120s · 70 kg | 2×6-10 · 3 fl. · 120s · 67.5 kg |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 6 fl. · 120s · 50 kg | 3×6-10 · 7 fl. · 120s · 50 kg | 2×6-10 · 3 fl. · 120s · 47.5 kg |
| Barre au front aux haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Traction scapulaire | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Flexion latérale à l'haltère | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 6 fl. · 120s · 67.5 kg | 3×6-10 · 7 fl. · 120s · 70 kg | 2×6-10 · 3 fl. · 120s · 67.5 kg |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Drag curl à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Leg curl couché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Sit-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×6-10 · 5 fl. · 120s · 67.5 kg | 4×6-10 · 5 fl. · 120s · 67.5 kg | 4×6-10 · 6 fl. · 120s · 67.5 kg | 4×6-10 · 7 fl. · 120s · 70 kg | 2×6-10 · 3 fl. · 120s · 67.5 kg |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 6 fl. · 120s · 50 kg | 3×6-10 · 7 fl. · 120s · 50 kg | 2×6-10 · 3 fl. · 120s · 47.5 kg |
| Curl biceps à la barre droite | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pallof press debout | CALIBRAGE 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 10. `minimal_1x20`

Une seule séance de 20 min par semaine, à la maison.

Profil : general_fitness 100 % — mercredi 20 min — lieux maison — né en 1990, undisclosed, santé standard.

### Passe 1

Note 0.918 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.65 · muscle_volume 1.00 · pattern_balance 0.86 · discipline_structure 0.88 · time_use 1.00 · variety 1.00 · exercise_fit 0.58 · stimulus_fatigue 0.89 · preferences 1.00 · novelty 1.00.

- **mercredi** (20 min, estimé 19 min) — `strength.full_body`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Pompe classique — main `sw-pompe`
  - Chaise contre le mur — accessory `mu-wall-sit`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`

Dosage : cardio 0 % (visé 35 %), mobility 37 % (visé 15 %), generalFitness 63 % (visé 50 %) — erreur 35.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 2 [0.5-5], delt_anterior 2 [0.5-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 2 [0.5-5], abs 2 [0.5-5], lower_back 2 [0.5-5], glutes 0.5 [0.5-5], quads 1 [0.5-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 2 séries ; chaîne postérieure 0 / genou 1 ; schémas de base 2/3.

### Revue simulée

- « Je ne sais pas faire » sur Pompe classique (`d0.2`) :
  - `exercise_replaced` jour 0 : Pompe classique → Pompe négative (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Demi-grand écart (half split) (`d0.6`) :
  - `exercise_replaced` jour 0 : Étirement chaîne postérieure en flexion avant debout → Demi-grand écart (half split) (plan.user_replaced)

### Passe 2

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s |
| Pompe négative | 2×10-15 · 3 fl. · 90s | 2×10-15 · 3 fl. · 90s | 2×10-15 · 4 fl. · 90s | 2×10-15 · 5 fl. · 90s |
| Chaise contre le mur | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 4 fl. · 60s | 1×5-12 s · 5 fl. · 60s |
| Gainage latéral sur le coude | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 11. `six_jours_musculation_avance_6x75`

Musculation avancée, 6 × 75 min en salle.

Profil : musculation 100 % — lundi 75 min, mardi 75 min, mercredi 75 min, jeudi 75 min, vendredi 75 min, samedi 75 min — lieux salle — expérience advanced, 90 kg, né en 1993, male, santé standard.

### Passe 1

Note 0.965 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 0.95 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.66 · preferences 1.00 · novelty 1.00.

- **lundi** (75 min, estimé 72 min) — `strength.full_body`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Extension lombaire à la machine — core `mu-extension-lombaire-machine`
- **mardi** (75 min, estimé 67 min) — `strength.pull`
  - Rowing poulie basse assis prise supination — main `mu-rowing-poulie-assis-supination`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Rowing buste penché à la Smith machine — secondary `mu-rowing-smith-machine`
  - Tirage bras tendu unilatéral poulie haute — accessory `mu-tirage-bras-tendus-unilateral-poulie`
  - Rotation externe à la poulie coude au corps — accessory `mu-rotation-externe-poulie`
  - Planche RKC — core `mu-planche-rkc`
- **mercredi** (75 min, estimé 66 min) — `strength.lower`
  - Fente avant aux haltères — main `mu-fente-avant-halteres`
  - Split squat aux haltères — secondary `mu-split-squat`
  - Nordic hamstring curl complet — accessory `mu-nordic-hamstring-curl`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Leg extension — accessory `mu-leg-extension`
  - V-up — core `mu-v-up`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
- **jeudi** (75 min, estimé 65 min) — `strength.upper`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise neutre — secondary `mu-tirage-vertical-prise-neutre`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
- **vendredi** (75 min, estimé 65 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre roumain unilatéral à l'haltère — secondary `mu-souleve-de-terre-roumain-unilateral`
  - Leg extension unilatéral — accessory `mu-leg-extension-unilateral`
  - Rotation externe haltère couché sur le côté — accessory `mu-rotation-externe-haltere-couche`
  - Tenue anti-rotation unilatérale à la poulie — core `mu-anti-rotation-unilaterale-poulie`
  - Rotation du tronc à la poulie assis — core `mu-rotation-poulie-bassin-bloque`
- **samedi** (75 min, estimé 74 min) — `strength.push`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Développé militaire barre debout — secondary `mu-developpe-militaire-barre-debout`
  - Élévation latérale lean-away haltère — accessory `mu-elevation-laterale-lean-away`
  - Mollets unilatéral debout à l'haltère — accessory `mu-mollets-unilateral-haltere`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 13 [12-20], delt_anterior 20 [12-20], delt_middle 14 [12-20], delt_posterior 13.5 [12-20], lats 23 [12-20], upper_back 19.5 [12-20], biceps 18 [12-20], triceps 14.5 [12-20], abs 21 [12-20], lower_back 18.5 [12-20], glutes 20 [12-20], quads 20 [12-20], hamstrings 17 [12-20], calves 15.5 [12-20]. Groupes majeurs dans leur bande : 84 %.

Équilibre : tirage 23 / poussée 23 séries ; chaîne postérieure 17 / genou 16 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Extension lombaire à la machine (`d0.6`) :
  - `exercise_replaced` jour 0 : Extension lombaire à la machine → Hyperextension 45° accent dos (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Nordic hamstring curl négatif (`d2.3`) :
  - `exercise_replaced` jour 2 : Nordic hamstring curl complet → Nordic hamstring curl négatif (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé couché barre | 4×3-6 · 5 fl. · 180s · 90 kg | 4×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 6 fl. · 180s · 90 kg | 5×2-5 · 7 fl. · 180s · 92.5 kg | TEST 3×1-3 · 9 fl. · 240s [3@102.5 5fl. / 1@115 7fl. / 1@122.5 9fl.] |
| Soulevé de terre conventionnel | 3×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 6 fl. · 120s · 132.5 kg | 4×6-10 · 7 fl. · 120s · 135 kg | 2×6-10 · 3 fl. · 120s · 127.5 kg |
| Développé haltères assis | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Leg curl couché | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Hyperextension 45° accent dos | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Rowing poulie basse assis prise supination | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing buste penché à la Smith machine | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage bras tendu unilatéral poulie haute | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Rotation externe à la poulie coude au corps | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Fente avant aux haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Split squat aux haltères | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Nordic hamstring curl négatif | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Leg extension | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| V-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé couché barre | 4×3-6 · 5 fl. · 180s · 90 kg | 4×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 6 fl. · 180s · 90 kg | 5×2-5 · 7 fl. · 180s · 92.5 kg | 3×3-6 · 3 fl. · 180s · 87.5 kg |
| Rowing poulie basse assis au triangle | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise neutre | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Mollets debout à la machine | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 6 fl. · 120s · 107.5 kg | 4×6-10 · 7 fl. · 120s · 107.5 kg | 2×6-10 · 3 fl. · 120s · 102.5 kg |
| Soulevé de terre roumain unilatéral à l'haltère | CALIBRAGE 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 5×6-10 · 5 fl. · 120s · 70 % 1RM | 5×6-10 · 6 fl. · 120s · 71 % 1RM | 5×6-10 · 7 fl. · 120s · 71 % 1RM | 3×6-10 · 3 fl. · 120s · 68 % 1RM |
| Leg extension unilatéral | CALIBRAGE 2×10-15 · 6 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 2×10-15 · 8 fl. · 75s | 1×10-15 · 4 fl. · 75s |
| Rotation externe haltère couché sur le côté | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Tenue anti-rotation unilatérale à la poulie | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Rotation du tronc à la poulie assis | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé couché barre | 4×3-6 · 5 fl. · 180s · 90 kg | 4×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 6 fl. · 180s · 90 kg | 5×2-5 · 7 fl. · 180s · 92.5 kg | 3×3-6 · 3 fl. · 180s · 87.5 kg |
| Développé militaire barre debout | 3×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 6 fl. · 120s · 50 kg | 4×6-10 · 7 fl. · 120s · 50 kg | 2×6-10 · 3 fl. · 120s · 47.5 kg |
| Élévation latérale lean-away haltère | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Mollets unilatéral debout à l'haltère | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Curl biceps à la barre droite | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Flexion latérale à l'haltère | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 12. `senior_65_forme_generale_3x40`

Senior de 65 ans, forme générale, 3 × 40 min, questionnaire santé en mode prudent.

Profil : general_fitness 60 % + mobility 40 % — lundi 40 min, mercredi 40 min, vendredi 40 min — lieux maison, exterieur — 64 kg, né en 1961, female, santé cautious, knee gêne 3/10.

### Passe 1

Note 0.937 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.99 · goal_specificity 1.00 · discipline_dosage 0.93 · muscle_volume 0.83 · pattern_balance 0.94 · discipline_structure 0.93 · time_use 1.00 · variety 1.00 · exercise_fit 0.64 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **lundi** (40 min, estimé 40 min) — `cardio.endurance`
  - Dislocations d'épaules au bâton — warmup `mo-dislocations-epaules-baton`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Marche de récupération — conditioning `ca-marche-recuperation`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **mercredi** (40 min, estimé 40 min) — `mobility`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Air squat — main `mu-air-squat`
  - Pompe contre le mur — secondary `sw-pompe-murale`
  - Élévation latérale à l'élastique — accessory `mu-elevation-laterale-elastique`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement du dessus du pied assis sur les talons — cooldown `mo-etirement-dessus-pied`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **vendredi** (40 min, estimé 40 min) — `mobility`
  - Dislocations d'épaules au bâton — warmup `mo-dislocations-epaules-baton`
  - Tirage vertical à l'élastique — main `mu-tirage-vertical-elastique`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Mountain climbers — core `mu-mountain-climbers`
  - Étirement en chiot (ouverture d'épaules au sol) — cooldown `mo-etirement-chiot`
  - Étirement de l'élévateur de la scapula — cooldown `mo-etirement-elevateur-scapula`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`

Dosage : cardio 19 % (visé 21 %), mobility 44 % (visé 49 %), generalFitness 37 % (visé 30 %) — erreur 7.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [1.5-5], delt_anterior 4 [1.5-5], delt_middle 2 [1.5-5], delt_posterior 1 [1.5-5], lats 5 [1.5-5], upper_back 2.5 [1.5-5], biceps 1.5 [1.5-5], triceps 4 [1.5-5], abs 3 [1.5-5], lower_back 2 [1.5-5], glutes 5 [1.5-5], quads 4 [1.5-5], hamstrings 1 [0-5], calves 1.5 [1.5-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 5 / poussée 3 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Air squat (`d1.2`) :
  - `exercise_replaced` jour 1 : Air squat → Chaise contre le mur (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par Pompe scapulaire (`d0.2`) :
  - `exercise_replaced` jour 0 : Tirage bras tendus à l'élastique → Pompe scapulaire (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe scapulaire | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Marche de récupération | 13-15 min | 18-20 min | 18-20 min | 18-20 min |
| Étirement des gastrocnémiens au mur jambe tendue | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe contre le mur | 2×4-6 · 3 fl. · 90s | 3×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s |
| Chaise contre le mur | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 4 fl. · 60s | 1×5-12 s · 5 fl. · 60s |
| Élévation latérale à l'élastique | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement du biceps au mur | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s |
| Étirement du dessus du pied assis sur les talons | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Tirage vertical à l'élastique | 2×8-12 · 3 fl. · 90s | 3×8-12 · 3 fl. · 90s | 3×8-12 · 4 fl. · 90s | 3×8-12 · 5 fl. · 90s |
| Pont fessier au sol | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Mountain climbers | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Étirement en chiot (ouverture d'épaules au sol) | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement de l'élévateur de la scapula | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Pigeon au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

## 13. `proprietaire_streetlifting_avance`

Profil calqué sur le propriétaire : streetlifting avancé, environ 71,5 kg, mode street.

Profil : streetlifting 70 % + street_workout 20 % + calisthenics 10 % — lundi 90 min, mardi 90 min, mercredi 75 min, vendredi 90 min, samedi 90 min — lieux salle, exterieur — mode street, expérience advanced, 71.5 kg, né en 1996, male, santé standard, elbow gêne 2/10.

### Passe 1

Note 0.952 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.92 · goal_specificity 0.99 · discipline_dosage 1.00 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.91 · time_use 0.97 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.59 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 76 min) — `strength.full_body`
  - Squat de compétition — main `sl-squat-competition`
  - Pistol squat — secondary `sw-pistol-squat`
  - Traction pronation — secondary `sw-traction-pronation`
  - Dead hang lesté — accessory `sl-dead-hang-leste`
  - Rotation externe à la poulie coude au corps — accessory `mu-rotation-externe-poulie`
  - Relevé de genoux suspendu lesté — core `sl-releve-genoux-suspendu-leste`
  - V-up — core `mu-v-up`
- **mardi** (90 min, estimé 75 min) — `strength.push`
  - Dips lesté de compétition — main `sl-dips-leste`
  - Dips coréens — secondary `cd-dips-coreens`
  - Pompe pike pieds surélevés — secondary `sw-pompe-pike-pieds-sureleves`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Pushdown à la corde — accessory `mu-pushdown-corde`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mercredi** (75 min, estimé 63 min) — `strength.full_body`
  - Traction haute lestée (high pull) — main `sl-traction-haute-lestee`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Soulevé de terre roumain unilatéral à l'haltère — secondary `mu-souleve-de-terre-roumain-unilateral`
  - Row scapulaire — accessory `sw-row-scapulaire`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`
- **vendredi** (90 min, estimé 75 min) — `strength.upper`
  - Muscle-up lesté de compétition — main `sl-muscle-up-leste`
  - Traction lestée de compétition — main `sl-traction-lestee`
  - Traction chest-to-bar — secondary `sw-traction-chest-to-bar`
  - Isométrie lestée en appui aux barres parallèles — accessory `sl-dips-isometrie-lestee-appui`
  - Élévation latérale à la poulie câble derrière le dos — accessory `mu-elevation-laterale-poulie-derriere-dos`
  - Bear crawl — core `mu-bear-crawl`
  - Planche RKC — core `mu-planche-rkc`
- **samedi** (90 min, estimé 76 min) — `strength.full_body`
  - Back lever prise supination — skill `cs-back-lever-supination`
  - Planche une jambe — skill `cs-planche-une-jambe`
  - Squat de compétition — main `sl-squat-competition`
  - Nordic hamstring curl complet — accessory `mu-nordic-hamstring-curl`
  - Tenue statique à la barre olympique — accessory `mu-tenue-statique-barre-olympique`
  - Oiseau haltères buste penché — accessory `mu-oiseau-halteres`
  - Arch rocks — core `mu-arch-rocks`

Dosage : streetWorkout 20 % (visé 20 %), streetlifting 70 % (visé 70 %), calisthenics 10 % (visé 10 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 20 [12-20], delt_anterior 20 [12-20], delt_middle 10.5 [12-20], delt_posterior 17 [12-20], lats 20 [12-20], upper_back 20 [12-20], biceps 20 [12-20], triceps 20 [12-20], abs 22 [12-20], lower_back 10 [12-20], glutes 18 [12-20], quads 17 [12-20], hamstrings 16 [12-20], calves 6.5 [0-20]. Groupes majeurs dans leur bande : 82 %.

Équilibre : tirage 23.5 / poussée 23.5 séries ; chaîne postérieure 11 / genou 14 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Curl biceps à la barre droite (`d1.4`) :
  - `exercise_replaced` jour 1 : Curl biceps à la barre droite → Curl biceps aux haltères simultané (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Dead hang lesté (`d4.5`) :
  - `exercise_replaced` jour 4 : Tenue statique à la barre olympique → Dead hang lesté (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 77.5 kg | 4×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 6 fl. · 180s · 80 kg | 5×2-5 · 7 fl. · 180s · 82.5 kg | TEST 3×1-3 · 9 fl. · 240s [3@90 5fl. / 1@102.5 7fl. / 1@110 9fl.] |
| Pistol squat | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 3×14-21 · 5 fl. · 90s | 4×14-21 · 5 fl. · 90s | 4×14-21 · 5 fl. · 90s | 4×14-21 · 6 fl. · 90s | 4×14-21 · 7 fl. · 90s | 2×14-21 · 3 fl. · 90s |
| Dead hang lesté | 2×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 3×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Rotation externe à la poulie coude au corps | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Relevé de genoux suspendu lesté | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| V-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Dips lesté de compétition | 4×3-6 · 5 fl. · 180s · 28.75 kg | 4×3-6 · 5 fl. · 180s · 28.75 kg | 5×3-6 · 5 fl. · 180s · 28.75 kg | 5×3-6 · 6 fl. · 180s · 30 kg | 5×2-5 · 7 fl. · 180s · 33.75 kg | TEST 3×1-3 · 9 fl. · 240s [3@43.75 5fl. / 1@57.5 7fl. / 1@66.25 9fl.] |
| Dips coréens | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe pike pieds surélevés | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 7 fl. · 75s | 2×10-15 · 7 fl. · 75s | 2×10-15 · 7 fl. · 75s | 2×10-15 · 8 fl. · 75s | 2×10-15 · 9 fl. · 75s | 1×10-15 · 5 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Pushdown à la corde | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction haute lestée (high pull) | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Soulevé de terre conventionnel | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Soulevé de terre roumain unilatéral à l'haltère | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Row scapulaire | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de genoux oblique suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Muscle-up lesté de compétition | 4×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 6 fl. · 180s · 0 kg | 5×2-5 · 7 fl. · 180s · 0 kg | TEST 3×1-3 · 9 fl. · 240s [3@0 5fl. / 1@3.75 7fl. / 1@8.75 9fl.] |
| Traction lestée de compétition | 3×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 6 fl. · 180s · 15 kg | 4×2-5 · 7 fl. · 180s · 18.75 kg | TEST 3×1-3 · 9 fl. · 240s [3@27.5 5fl. / 1@40 7fl. / 1@47.5 9fl.] |
| Traction chest-to-bar | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Isométrie lestée en appui aux barres parallèles | 2×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 3×5-12 s · 7 fl. · 60s | 2×5-12 s · 3 fl. · 60s |
| Élévation latérale à la poulie câble derrière le dos | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Bear crawl | 2×20 m · 4 fl. · 60s | 2×20 m · 4 fl. · 60s | 2×20 m · 4 fl. · 60s | 2×20 m · 5 fl. · 60s | 2×20 m · 6 fl. · 60s | 1×20 m · 2 fl. · 60s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Back lever prise supination | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| Planche une jambe | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 77.5 kg | 4×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 6 fl. · 180s · 80 kg | 5×2-5 · 7 fl. · 180s · 82.5 kg | 3×3-6 · 3 fl. · 180s · 77.5 kg |
| Nordic hamstring curl complet | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Dead hang lesté | 2×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 3×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Oiseau haltères buste penché | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 14. `homme_25_musculation_debutant_3x60`

Homme de 25 ans, débutant en musculation, 3 × 60 min en salle.

Profil : musculation 100 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 70 kg, né en 2001, male, santé standard.

### Passe 1

Note 0.974 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 0.99 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.74 · stimulus_fatigue 0.79 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.upper`
  - Pompe classique — main `sw-pompe`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`
- **mercredi** (60 min, estimé 58 min) — `strength.upper`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Face pull à la poulie corde — secondary `mu-face-pull-corde`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Mollets unilatéral debout à l'haltère — accessory `mu-mollets-unilateral-haltere`
- **vendredi** (60 min, estimé 60 min) — `strength.upper`
  - Développé couché Smith machine — main `mu-developpe-couche-smith`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Row australien — secondary `sw-row-australien`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Turkish get-up — core `mu-turkish-get-up`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9.5 [8-16], delt_anterior 12.5 [8-16], delt_middle 8 [8-16], delt_posterior 11.5 [8-16], lats 12 [8-16], upper_back 14.5 [8-16], biceps 8 [8-16], triceps 9.5 [8-16], abs 9 [8-16], lower_back 7.5 [8-16], glutes 12 [8-16], quads 9 [8-16], hamstrings 7.5 [8-16], calves 6 [8-16]. Groupes majeurs dans leur bande : 82 %.

Équilibre : tirage 16 / poussée 13 séries ; chaîne postérieure 6 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Développé couché barre (`d1.1`) :
  - `exercise_replaced` jour 1 : Développé couché barre → Développé couché Smith machine (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Rowing poulie basse assis unilatéral (`d0.3`) :
  - `exercise_replaced` jour 0 : Rowing poulie basse assis au triangle → Rowing poulie basse assis unilatéral (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Pompe classique | 2×5-7 · 5 fl. · 90s | 3×5-7 · 5 fl. · 90s | 3×5-7 · 6 fl. · 90s | 3×5-7 · 7 fl. · 90s | 2×5-7 · 3 fl. · 90s |
| Presse à cuisses 45° | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing poulie basse assis unilatéral | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Gainage ventral sur les coudes | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Développé couché Smith machine | CALIBRAGE 3×5-8 · 4 fl. · 150s · 72 % 1RM | 4×5-8 · 4 fl. · 150s · 72 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | TEST 1×1-16 · 10 fl. · 180s |
| Face pull à la poulie corde | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mollets unilatéral debout à l'haltère | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Développé couché Smith machine | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé haltères assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Mollets debout à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Turkish get-up | CALIBRAGE 2×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 4 fl. · 90s · 80 % 1RM | 3×2-4 · 5 fl. · 90s · 81 % 1RM | 2×2-4 · 1 fl. · 90s · 77 % 1RM |

## 15. `femme_30_street_workout_parc_3x45`

Femme de 30 ans, street workout au parc, 3 × 45 min.

Profil : street_workout 80 % + mobility 20 % — mardi 45 min, jeudi 45 min, samedi 45 min — lieux exterieur — 60 kg, né en 1996, female, santé standard.

### Passe 1

Note 0.965 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.90 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.88 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 41 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Pompe classique — secondary `sw-pompe`
  - Row australien — secondary `sw-row-australien`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Relevé de genoux suspendu — core `sw-releve-genoux-suspendu`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **jeudi** (45 min, estimé 42 min) — `strength.upper`
  - Handstand dos au mur — skill `cs-handstand-dos-au-mur`
  - Traction assistée à l'élastique — main `sw-traction-assistee-elastique`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Pompe classique — secondary `sw-pompe`
  - Dead hang — accessory `sw-dead-hang`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement des fléchisseurs du poignet bras tendu — cooldown `mo-etirement-flechisseurs-poignet-bras-tendu`
- **samedi** (45 min, estimé 43 min) — `strength.upper`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Traction assistée pieds au sol — main `sw-traction-assistee-pieds-au-sol`
  - Pompe classique — secondary `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Élévation latérale à l'élastique — accessory `mu-elevation-laterale-elastique`
  - Bird dog — core `mu-bird-dog`
  - Mountain climbers — core `mu-mountain-climbers`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`

Dosage : streetWorkout 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9 [4-10], delt_anterior 12 [4-10], delt_middle 4 [4-10], delt_posterior 6 [4-10], lats 10.5 [4-10], upper_back 10 [4-10], biceps 7.5 [4-10], triceps 10 [4-10], abs 6 [4-10], lower_back 4 [4-10], glutes 7 [4-10], quads 6.5 [4-10], hamstrings 1 [0-10], calves 1.5 [0-10]. Groupes majeurs dans leur bande : 87 %.

Équilibre : tirage 12 / poussée 12 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement des fléchisseurs de hanche en semi-agenouillé (`d0.7`) :
  - `exercise_replaced` jour 0 : Étirement des fléchisseurs de hanche en semi-agenouillé → Couch stretch (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
- Remplacement par Flutter kicks (`d0.5`) :
  - `exercise_replaced` jour 0 : Relevé de genoux suspendu → Flutter kicks (plan.user_replaced)
  - `order_changed` jour 0 (plan.reoptimized)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Air squat | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pompe classique | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Row australien | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Flutter kicks | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Couch stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Handstand dos au mur | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| Traction assistée à l'élastique | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | TEST 1×1-24 · 10 fl. · 180s |
| Row australien prise large | 2×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s | 2×3-8 · 1 fl. · 90s |
| Pompe classique | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Dead hang | 2×5-12 s · 3 fl. · 60s | 3×5-12 s · 4 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 2×5-12 s · 1 fl. · 60s |
| Étirement du biceps au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Traction assistée pieds au sol | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pompe classique | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Élévation latérale à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Bird dog | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Mountain climbers | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 16. `mobilite_seule_5x20`

Mobilité seule, 5 × 20 min à la maison.

Profil : mobility 100 % — lundi 20 min, mardi 20 min, mercredi 20 min, jeudi 20 min, vendredi 20 min — lieux maison — 58 kg, né en 1979, female, santé standard.

### Passe 1

Note 0.976 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (20 min, estimé 18 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — mobility `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Pigeon au sol — mobility `mo-pigeon-sol`
  - Routine mobilité complète — mobility `mo-routine-mobilite-complete`
- **mardi** (20 min, estimé 19 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Étirement en appui sur le dos des mains — mobility `mo-appui-dos-des-mains`
  - Étirement chaîne postérieure en flexion avant debout — mobility `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Routine mobilité complète — mobility `mo-routine-mobilite-complete`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **mercredi** (20 min, estimé 20 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Cat-cow — mobility `mo-cat-cow`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Extension thoracique sur rouleau — mobility `mo-extension-thoracique-rouleau`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — mobility `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **jeudi** (20 min, estimé 19 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — mobility `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Mobilité douce du cou en trois plans — mobility `mo-mobilite-cou-trois-plans`
  - Soupir physiologique — mobility `mo-soupir-physiologique`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **vendredi** (20 min, estimé 19 min) — `mobility`
  - Frog stretch (grenouille) — mobility `mo-frog-stretch`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - CARs d'épaule — mobility `mo-cars-epaule`
  - Étirement chaîne postérieure en flexion avant debout — mobility `mo-chaine-posterieure-flexion-avant-debout`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Wall slides dos au mur — mobility `mo-wall-slides`

Dosage : mobility 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Étirement des fléchisseurs de hanche en semi-agenouillé (`d2.6`) :
  - `exercise_removed` jour 0 : Étirement des fléchisseurs de hanche en semi-agenouillé (plan.reoptimized)
  - `exercise_replaced` jour 2 : Étirement des fléchisseurs de hanche en semi-agenouillé → Couch stretch (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
  - `exercise_removed` jour 3 : Étirement des fléchisseurs de hanche en semi-agenouillé (plan.reoptimized)
- Remplacement par Demi-grand écart (half split) (`d4.4`) :
  - `exercise_replaced` jour 4 : Étirement chaîne postérieure en flexion avant debout → Demi-grand écart (half split) (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine mobilité complète | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement en appui sur le dos des mains | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Routine mobilité complète | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Couch stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Cat-cow | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Extension thoracique sur rouleau | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Mobilité douce du cou en trois plans | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Soupir physiologique | 2×120-180 s · 15s | 2×120-180 s · 15s | 2×120-180 s · 15s | 2×120-180 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Frog stretch (grenouille) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| CARs d'épaule | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

## 17. `cardio_debutant_marche_3x30`

Débutant en cardio (marche, vélo), 3 × 30 min.

Profil : cardio 100 % — lundi 30 min, mercredi 30 min, samedi 30 min — lieux exterieur, maison — 96 kg, né en 1975, male, santé cautious.

### Passe 1

Note 0.976 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 30 min) — `cardio.endurance`
  - Vélo en endurance — conditioning `ca-velo-endurance`
- **mercredi** (30 min, estimé 30 min) — `cardio.endurance`
  - Vélo en endurance — conditioning `ca-velo-endurance`
- **samedi** (30 min, estimé 30 min) — `cardio.endurance`
  - Vélo en endurance — conditioning `ca-velo-endurance`

Dosage : cardio 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Vélo en endurance (`d0.1`) :
  - `exercise_replaced` jour 0 : Vélo en endurance → Vélo de récupération très léger (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 1 → Marche de récupération (plan.reoptimized)
  - `exercise_removed` jour 1 : Vélo en endurance (plan.reoptimized)
  - `exercise_added` jour 2 → Marche de récupération (plan.reoptimized)
  - `exercise_removed` jour 2 : Vélo en endurance (plan.reoptimized)
- Remplacement par Marche rapide (`d2.2`) :
  - `exercise_replaced` jour 2 : Marche de récupération → Marche rapide (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Vélo de récupération très léger | 22-25 min | 22-25 min | 27-30 min | 27-30 min |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche de récupération | 22-25 min | 22-25 min | 27-30 min | 27-30 min |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche rapide | 18-20 min | 22-25 min | 22-25 min | 22-25 min |

## 18. `homme_50_reprise_genou_3x45`

Homme de 50 ans en reprise, genou gauche sensible (gêne 4/10).

Profil : musculation 70 % + cardio 30 % — mardi 45 min, jeudi 45 min, samedi 45 min — lieux salle — 85 kg, né en 1976, male, santé standard, knee gêne 4/10.

### Passe 1

Note 0.961 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.98 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.89 · pattern_balance 0.99 · discipline_structure 0.96 · time_use 1.00 · variety 1.00 · exercise_fit 0.73 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `strength.upper`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Row australien — secondary `sw-row-australien`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
- **jeudi** (45 min, estimé 45 min) — `strength.full_body`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Planche RKC — core `mu-planche-rkc`
  - Marche de récupération — conditioning `ca-marche-recuperation`
- **samedi** (45 min, estimé 43 min) — `cardio.endurance`
  - Row australien — main `sw-row-australien`
  - Mountain climbers — core `mu-mountain-climbers`
  - Marche de récupération — conditioning `ca-marche-recuperation`

Dosage : musculation 70 % (visé 70 %), cardio 30 % (visé 30 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [5-10], delt_anterior 6 [5-10], delt_middle 0 [5-10], delt_posterior 7.5 [5-10], lats 9 [5-10], upper_back 9 [5-10], biceps 4.5 [5-10], triceps 6 [5-10], abs 6 [5-10], lower_back 4.5 [5-10], glutes 9 [5-10], quads 6 [5-10], hamstrings 7.5 [5-10], calves 4.5 [5-10]. Groupes majeurs dans leur bande : 78 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 6 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Planche RKC (`d1.4`) :
  - `exercise_replaced` jour 1 : Planche RKC → Gainage ventral sur les coudes (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Marche sur tapis incliné (`d1.5`) :
  - `exercise_replaced` jour 1 : Marche de récupération → Marche sur tapis incliné (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Mollets debout à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 37.5 kg | 3×6-10 · 5 fl. · 120s · 37.5 kg | 3×6-10 · 6 fl. · 120s · 37.5 kg | 3×6-10 · 7 fl. · 120s · 37.5 kg | 2×6-10 · 3 fl. · 120s · 35 kg |
| Presse à cuisses 45° | 2×6-10 · 5 fl. · 120s · 75 kg | 3×6-10 · 5 fl. · 120s · 75 kg | 3×6-10 · 6 fl. · 120s · 75 kg | 3×6-10 · 7 fl. · 120s · 75 kg | 2×6-10 · 3 fl. · 120s · 70 kg |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Gainage ventral sur les coudes | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Marche sur tapis incliné | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Mountain climbers | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Marche de récupération | 18-20 min | 22-25 min | 22-25 min | 22-25 min | 13-15 min |

## 19. `lombalgie_musculation_3x50`

Musculation avec le bas du dos sensible (gêne 5/10).

Profil : musculation 80 % + mobility 20 % — lundi 50 min, mercredi 50 min, vendredi 50 min — lieux salle — 67 kg, né en 1989, female, santé standard, lower_back gêne 5/10.

### Passe 1

Note 0.966 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.96 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.96 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (50 min, estimé 50 min) — `strength.full_body`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Dips aux barres parallèles — main `sw-dips-barres-paralleles`
  - Copenhagen plank — accessory `mu-copenhagen-plank`
  - Nordic hamstring curl assisté à l'élastique — accessory `mu-nordic-hamstring-curl-assiste`
  - Élévation latérale buste appuyé sur banc incliné — accessory `mu-elevation-laterale-buste-appuye-banc-incline`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Lancer rotatif au médecine-ball — core `mu-lancer-rotatif-medecine-ball`
  - Étirement du trapèze supérieur — cooldown `mo-etirement-trapeze-superieur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **mercredi** (50 min, estimé 49 min) — `strength.full_body`
  - CARs d'épaule — warmup `mo-cars-epaule`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Pompe classique — secondary `sw-pompe`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement en chiot (ouverture d'épaules au sol) — cooldown `mo-etirement-chiot`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **vendredi** (50 min, estimé 48 min) — `strength.full_body`
  - Fente marchée aux haltères — main `mu-fente-marchee-halteres`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Élévation frontale haltères — accessory `mu-elevation-frontale-halteres`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`

Dosage : musculation 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9 [6.5-13], delt_anterior 10.5 [6.5-13], delt_middle 6 [6.5-13], delt_posterior 6 [6.5-13], lats 9 [6.5-13], upper_back 7.5 [6.5-13], biceps 6 [6.5-13], triceps 7.5 [6.5-13], abs 7.5 [6.5-13], lower_back 3 [6.5-13], glutes 9 [6.5-13], quads 6 [6.5-13], hamstrings 7.5 [6.5-13], calves 6 [6.5-13]. Groupes majeurs dans leur bande : 62 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 6 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement en chiot (ouverture d'épaules au sol) (`d1.8`) :
  - `exercise_replaced` jour 1 : Étirement en chiot (ouverture d'épaules au sol) → Étirement du grand dorsal en charnière à la barre (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Auto-massage du dos thoracique au rouleau (`d2.8`) :
  - `exercise_replaced` jour 2 : Routine d'auto-massage au rouleau (membres inférieurs et dos) → Auto-massage du dos thoracique au rouleau (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Copenhagen plank | 2×5-12 s · 4 fl. · 60s | 3×5-12 s · 4 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 2×5-12 s · 2 fl. · 60s |
| Nordic hamstring curl assisté à l'élastique | 2×8-12 · 5 fl. · 75s | 3×8-12 · 5 fl. · 75s | 3×8-12 · 6 fl. · 75s | 3×8-12 · 7 fl. · 75s | 2×8-12 · 3 fl. · 75s |
| Élévation latérale buste appuyé sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Lancer rotatif au médecine-ball | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Étirement du trapèze supérieur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| CARs d'épaule | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 32.5 kg | 3×6-10 · 5 fl. · 120s · 32.5 kg | 3×6-10 · 6 fl. · 120s · 32.5 kg | 3×6-10 · 7 fl. · 120s · 35 kg | 2×6-10 · 3 fl. · 120s · 32.5 kg |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pompe classique | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Leg curl couché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement du grand dorsal en charnière à la barre | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Fente marchée aux haltères | 2×20 m · 4 fl. · 90s | 3×20 m · 4 fl. · 90s | 3×20 m · 5 fl. · 90s | 3×20 m · 6 fl. · 90s | 2×20 m · 2 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation frontale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Auto-massage du dos thoracique au rouleau | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

## 20. `poignet_calisthenie_3x60`

Calisthénie avec un poignet droit sensible (gêne 4/10).

Profil : calisthenics 100 % — lundi 60 min, mercredi 60 min, samedi 60 min — lieux exterieur — 64 kg, né en 2000, male, santé standard, wrist_hand gêne 4/10.

### Passe 1

Note 0.953 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.92 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.95 · pattern_balance 1.00 · discipline_structure 0.85 · time_use 1.00 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.84 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 58 min) — `skills`
  - Front lever assisté élastique — skill `cs-front-lever-assiste-elastique`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Support hold aux barres parallèles — skill `cs-support-barres-paralleles`
  - Skater squat — main `sw-skater-squat`
  - Traction pronation — secondary `sw-traction-pronation`
  - Superman dynamique — core `mu-superman`
- **mercredi** (60 min, estimé 60 min) — `strength.pull`
  - Back lever straddle — skill `cs-back-lever-straddle`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Traction pronation — main `sw-traction-pronation`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Hip airplane — accessory `mu-hip-airplane`
  - Arch rocks — core `mu-arch-rocks`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **samedi** (60 min, estimé 60 min) — `strength.upper`
  - Back lever tuck avancé — skill `cs-back-lever-tuck-avance`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Pompe à un bras mains surélevées — main `cd-pompe-un-bras-surelevee`
  - Pompe pike — secondary `sw-pompe-pike`
  - Pompe en T — secondary `sw-pompe-t`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`

Dosage : calisthenics 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 15.5 [8-16], delt_anterior 14 [8-16], delt_middle 4.5 [8-16], delt_posterior 9 [8-16], lats 16 [8-16], upper_back 16 [8-16], biceps 8.5 [8-16], triceps 15.5 [8-16], abs 13.5 [8-16], lower_back 9 [8-16], glutes 9 [8-16], quads 12 [8-16], hamstrings 4.5 [8-16], calves 0 [0-16]. Groupes majeurs dans leur bande : 84 %.

Équilibre : tirage 19 / poussée 13 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Hip airplane (`d1.5`) :
  - `exercise_replaced` jour 1 : Hip airplane → Clamshell (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Back lever straddle (`d2.1`) :
  - `exercise_replaced` jour 2 : Back lever tuck avancé → Back lever straddle (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Front lever assisté élastique | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Support hold aux barres parallèles | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Skater squat | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×6-9 · 5 fl. · 90s | 3×6-9 · 5 fl. · 90s | 3×6-9 · 6 fl. · 90s | 3×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Superman dynamique | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back lever straddle | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Traction pronation | 2×6-9 · 5 fl. · 90s | 3×6-9 · 5 fl. · 90s | 3×6-9 · 6 fl. · 90s | 3×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Clamshell | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back lever straddle | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Pompe à un bras mains surélevées | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Face pull à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 21. `femme_22_calisthenie_debutante_maison`

Débutante en calisthénie à la maison, avec barre de traction.

Profil : calisthenics 70 % + mobility 30 % — lundi 45 min, mercredi 45 min, vendredi 45 min — lieux maison — 57 kg, né en 2004, female, santé standard.

### Passe 1

Note 0.952 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.94 · pattern_balance 0.99 · discipline_structure 0.85 · time_use 1.00 · variety 1.00 · exercise_fit 0.64 · stimulus_fatigue 0.87 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 44 min) — `strength.upper`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - World's greatest stretch — warmup `mo-worlds-greatest-stretch`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Traction assistée à l'élastique — main `sw-traction-assistee-elastique`
  - Développé épaules à l'élastique debout — secondary `mu-developpe-epaules-elastique-debout`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Étirement de l'élévateur de la scapula — cooldown `mo-etirement-elevateur-scapula`
  - Étirement des fléchisseurs du poignet bras tendu — cooldown `mo-etirement-flechisseurs-poignet-bras-tendu`
- **mercredi** (45 min, estimé 45 min) — `strength.upper`
  - Bascules en appui doigts vers l'avant — warmup `mo-bascules-appui-doigts-avant`
  - Squat profond tenu — warmup `mo-squat-profond-tenu`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Pompe sur les genoux — main `sw-pompe-genoux`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Élévation latérale à l'élastique — accessory `mu-elevation-laterale-elastique`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **vendredi** (45 min, estimé 44 min) — `strength.upper`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Traction assistée à l'élastique — main `sw-traction-assistee-elastique`
  - Air squat — secondary `mu-air-squat`
  - Pompe sur les genoux — secondary `sw-pompe-genoux`
  - Dead hang — accessory `sw-dead-hang`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement en chiot (ouverture d'épaules au sol) — cooldown `mo-etirement-chiot`

Dosage : calisthenics 70 % (visé 70 %), mobility 30 % (visé 30 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [4-10], delt_anterior 10 [4-10], delt_middle 5 [4-10], delt_posterior 3 [4-10], lats 10 [4-10], upper_back 6.5 [4-10], biceps 9 [4-10], triceps 7.5 [4-10], abs 5 [4-10], lower_back 4 [4-10], glutes 5 [4-10], quads 4 [4-10], hamstrings 1 [0-10], calves 1.5 [0-10]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 14 / poussée 9 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Pompe sur les genoux (`d1.5`) :
  - `exercise_replaced` jour 1 : Pompe sur les genoux → Pompe négative (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 2 → Pompe contre le mur (plan.reoptimized)
  - `exercise_removed` jour 2 : Pompe sur les genoux (plan.reoptimized)
- Remplacement par Traction négative (`d2.3`) :
  - `exercise_replaced` jour 2 : Traction assistée à l'élastique → Traction négative (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| World's greatest stretch | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Tenue menton au-dessus de la barre supination | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| Traction assistée à l'élastique | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s | TEST 1×1-24 · 10 fl. · 180s |
| Développé épaules à l'élastique debout | 2×8-12 · 3 fl. · 90s | 3×8-12 · 4 fl. · 90s | 3×8-12 · 5 fl. · 90s | 2×8-12 · 1 fl. · 90s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 2×10-20 s · 1 fl. · 60s |
| Étirement de l'élévateur de la scapula | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Bascules en appui doigts vers l'avant | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Squat profond tenu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Wall slides dos au mur | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s |
| Tenue menton au-dessus de la barre supination | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| Pompe négative | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Élévation latérale à l'élastique | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s | 1×8-12 · 1 fl. · 75s |
| Gainage latéral bras tendu | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Mountain climbers | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Tenue menton au-dessus de la barre supination | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| Traction négative | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s | 1×6-12 · 1 fl. · 90s |
| Air squat | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pompe contre le mur | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Dead hang | 2×10-15 s · 3 fl. · 60s | 2×10-15 s · 4 fl. · 60s | 2×10-15 s · 5 fl. · 60s | 1×10-15 s · 1 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement en chiot (ouverture d'épaules au sol) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 22. `homme_35_crossfit_maison_kettlebell`

CrossFit à la maison avec kettlebell et corde à sauter, 4 × 40 min.

Profil : crossfit 70 % + cardio 30 % — lundi 40 min, mardi 40 min, jeudi 40 min, samedi 40 min — lieux maison, exterieur — 84 kg, né en 1991, male, santé standard.

### Passe 1

Note 0.947 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.93 · pattern_balance 0.88 · discipline_structure 0.92 · time_use 1.00 · variety 0.94 · exercise_fit 0.65 · stimulus_fatigue 0.87 · preferences 1.00 · novelty 1.00.

- **lundi** (40 min, estimé 40 min) — `cardio.endurance`
  - Marche rapide — conditioning `ca-marche-rapide`
- **mardi** (40 min, estimé 37 min) — `strength.upper`
  - Saut en longueur sans élan — secondary `mu-broad-jump`
  - Traction explosive poitrine à la barre — main `cd-traction-explosive-poitrine-barre`
  - Pompe en T — secondary `sw-pompe-t`
  - Burpee avec tuck jump — conditioning `cf-burpee-tuck-jump`
  - Toes-to-bar kipping — conditioning `cf-toes-to-bar-kipping`
  - Traction kipping — conditioning `cf-traction-kipping`
- **jeudi** (40 min, estimé 39 min) — `skills`
  - Wall walk — skill `cd-wall-walk`
  - Saut en longueur sans élan — secondary `mu-broad-jump`
  - V-up — core `mu-v-up`
  - Saut en étoile — conditioning `cf-saut-etoile`
  - Box step-over — conditioning `cf-box-step-over`
  - Burpee — conditioning `cf-burpee`
- **samedi** (40 min, estimé 37 min) — `strength.pull`
  - Back lever tuck avancé — skill `cs-back-lever-tuck-avance`
  - Traction pronation — main `sw-traction-pronation`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
  - Burpee Navy SEAL — conditioning `cf-burpee-navy-seal`
  - Box jump-over — conditioning `cf-box-jump-over`
  - Sit-up AbMat en papillon — conditioning `cf-sit-up-abmat`

Dosage : crossfit 71 % (visé 70 %), cardio 29 % (visé 30 %) — erreur 0.8 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [3.5-7], delt_anterior 7 [3.5-7], delt_middle 2.5 [3.5-7], delt_posterior 3 [3.5-7], lats 7 [3.5-7], upper_back 4 [3.5-7], biceps 5 [3.5-7], triceps 6.5 [3.5-7], abs 6.5 [3.5-7], lower_back 2 [3.5-7], glutes 4 [3.5-7], quads 4 [3.5-7], hamstrings 4 [3.5-7], calves 4 [3.5-7]. Groupes majeurs dans leur bande : 82 %.

Équilibre : tirage 9 / poussée 7 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Burpee avec tuck jump (`d1.4`) :
  - `exercise_replaced` jour 1 : Burpee avec tuck jump → Burpee (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par Toe touch (`d3.6`) :
  - `exercise_replaced` jour 3 : Sit-up AbMat en papillon → Toe touch (plan.user_replaced)
  - `order_changed` jour 3 (plan.reoptimized)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Marche rapide | 27-30 min | 31-35 min | 36-40 min | 36-40 min | 22-25 min |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Saut en longueur sans élan | 2×5-8 · 3 fl. · 90s | 3×5-8 · 3 fl. · 90s | 3×5-8 · 4 fl. · 90s | 3×5-8 · 5 fl. · 90s | 2×5-8 · 1 fl. · 90s |
| Traction explosive poitrine à la barre | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Toes-to-bar kipping | 3×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 2×8-12 · 15s · rounds wod-d1 |
| Traction kipping | 3×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 2×8-12 · 15s · rounds wod-d1 |
| Burpee | 3×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 4×8-12 · 15s · rounds wod-d1 | 2×8-12 · 15s · rounds wod-d1 |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Wall walk | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Saut en longueur sans élan | 2×5-8 · 3 fl. · 90s | 3×5-8 · 3 fl. · 90s | 3×5-8 · 4 fl. · 90s | 3×5-8 · 5 fl. · 90s | 2×5-8 · 1 fl. · 90s |
| V-up | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| Saut en étoile | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |
| Box step-over | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |
| Burpee | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back lever tuck avancé | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| Toe touch | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| Burpee Navy SEAL | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Box jump-over | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |

## 23. `musculation_maison_halteres_4x45`

Musculation à la maison avec haltères et banc, 4 × 45 min.

Profil : musculation 100 % — lundi 45 min, mardi 45 min, jeudi 45 min, vendredi 45 min — lieux maison — 77 kg, né en 1987, male, santé standard.

### Passe 1

Note 0.959 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.90 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.67 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 42 min) — `strength.push`
  - Développé haltère unilatéral debout — main `mu-developpe-haltere-unilateral-debout`
  - Développé couché haltères — secondary `mu-developpe-couche-halteres`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Relevé de jambes allongé au sol — core `mu-releve-jambes-allonge`
  - Sit-up — core `mu-sit-up`
- **mardi** (45 min, estimé 44 min) — `strength.full_body`
  - Rowing assis à l'élastique — main `mu-rowing-elastique-assis`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Reverse hyper sur banc — accessory `mu-reverse-hyper-banc`
  - Curl marteau aux haltères — accessory `mu-curl-marteau-halteres`
  - Rotation externe haltère couché sur le côté — accessory `mu-rotation-externe-haltere-couche`
  - Gainage latéral sur les genoux — core `mu-gainage-lateral-genoux`
- **jeudi** (45 min, estimé 42 min) — `strength.upper`
  - Rowing haltère unilatéral appui sur banc — main `mu-rowing-haltere-unilateral-banc`
  - Tirage vertical à l'élastique — secondary `mu-tirage-vertical-elastique`
  - Pompe classique — secondary `sw-pompe`
  - Barre au front aux haltères — accessory `mu-barre-au-front-halteres`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`
- **vendredi** (45 min, estimé 43 min) — `strength.lower`
  - Fente arrière aux haltères — main `mu-fente-arriere-halteres`
  - Fente latérale — secondary `mu-fente-laterale`
  - Élévation latérale partielle en position basse — accessory `mu-elevation-laterale-partielle`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 5 [4-10], delt_anterior 11 [4-10], delt_middle 9 [4-10], delt_posterior 4.5 [4-10], lats 9 [4-10], upper_back 9 [4-10], biceps 9.5 [4-10], triceps 9.5 [4-10], abs 10 [4-10], lower_back 8 [4-10], glutes 10 [4-10], quads 8 [4-10], hamstrings 5 [4-10], calves 0 [0-10]. Groupes majeurs dans leur bande : 96 %.

Équilibre : tirage 9 / poussée 8 séries ; chaîne postérieure 4 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Curl marteau aux haltères (`d1.4`) :
  - `exercise_replaced` jour 1 : Curl marteau aux haltères → Curl biceps à l'élastique (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Tuck-up (`d0.5`) :
  - `exercise_replaced` jour 0 : Sit-up → Tuck-up (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Développé haltère unilatéral debout | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM |
| Développé couché haltères | 2×6-10 · 5 fl. · 120s · 16 kg | 3×6-10 · 5 fl. · 120s · 16 kg | 3×6-10 · 6 fl. · 120s · 16 kg | 3×6-10 · 7 fl. · 120s · 16 kg |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Relevé de jambes allongé au sol | 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |
| Tuck-up | 2×10-15 · 3 fl. · 60s | 3×10-15 · 3 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rowing assis à l'élastique | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Reverse hyper sur banc | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Curl biceps à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Rotation externe haltère couché sur le côté | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Gainage latéral sur les genoux | 2×20-40 s · 3 fl. · 60s | 3×20-40 s · 3 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rowing haltère unilatéral appui sur banc | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Tirage vertical à l'élastique | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Pompe classique | 2×12-18 · 5 fl. · 90s | 2×12-18 · 5 fl. · 90s | 2×12-18 · 6 fl. · 90s | 2×12-18 · 7 fl. · 90s |
| Barre au front aux haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Flexion latérale à l'haltère | CALIBRAGE 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Fente arrière aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Fente latérale | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Élévation latérale partielle en position basse | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

## 24. `elite_calisthenie_6x90`

Calisthénie de niveau élite, 6 × 90 min.

Profil : calisthenics 90 % + mobility 10 % — lundi 90 min, mardi 90 min, mercredi 90 min, jeudi 90 min, vendredi 90 min, samedi 90 min — lieux salle, exterieur — 66 kg, né en 1998, male, santé standard.

### Passe 1

Note 0.950 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.90 · pattern_balance 1.00 · discipline_structure 0.91 · time_use 0.92 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.73 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 58 min) — `strength.full_body`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Planche straddle — skill `cs-planche-straddle`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Élévation latérale à l'élastique — accessory `mu-elevation-laterale-elastique`
  - Dead hang — accessory `sw-dead-hang`
  - Arch rocks — core `mu-arch-rocks`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
- **mardi** (90 min, estimé 59 min) — `skills`
  - Traction un bras — skill `cd-traction-un-bras`
  - Front lever — skill `cs-front-lever`
  - Tenue menton au-dessus de la barre un bras — skill `cs-tenue-menton-barre-un-bras`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Étirement du grand dorsal en charnière à la barre — cooldown `mo-etirement-grand-dorsal-barre`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **mercredi** (90 min, estimé 58 min) — `strength.push`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Planche straddle — skill `cs-planche-straddle`
  - HSPU au mur dos au mur — main `cd-hspu-mur-dos`
  - Hip airplane — accessory `mu-hip-airplane`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
  - Relevé de jambes allongé au sol — core `mu-releve-jambes-allonge`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Étirement en bas de dips aux barres parallèles — cooldown `mo-etirement-bas-dips-barres`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **jeudi** (90 min, estimé 58 min) — `skills`
  - Traction un bras — skill `cd-traction-un-bras`
  - Front lever — skill `cs-front-lever`
  - Drapeau humain tuck — skill `cs-drapeau-tuck`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Planche RKC — core `mu-planche-rkc`
- **vendredi** (90 min, estimé 58 min) — `skills`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Planche une jambe — skill `cs-planche-une-jambe`
  - Planche push-up straddle assistée à l'élastique — skill `cd-planche-pushup-straddle-elastique`
  - HSPU libre — main `cd-hspu-libre`
  - Toes-to-bar négatif — core `sw-toes-to-bar-negatif`
  - Bird dog — core `mu-bird-dog`
- **samedi** (90 min, estimé 59 min) — `skills`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Traction un bras — skill `cd-traction-un-bras`
  - Front lever — skill `cs-front-lever`
  - Skater squat — main `sw-skater-squat`
  - Hollow body hold — core `mu-hollow-body-hold`
  - Pancake assis — cooldown `mo-pancake-assis`
  - Étirement en bas de dips aux barres parallèles — cooldown `mo-etirement-bas-dips-barres`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : calisthenics 89 % (visé 90 %), mobility 11 % (visé 10 %) — erreur 0.6 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 20 [12-20], delt_anterior 22.5 [12-20], delt_middle 12 [12-20], delt_posterior 14 [12-20], lats 24 [12-20], upper_back 17 [12-20], biceps 18 [12-20], triceps 22.5 [12-20], abs 21 [12-20], lower_back 12 [12-20], glutes 14 [12-20], quads 16 [12-20], hamstrings 5 [12-20], calves 0 [0-20]. Groupes majeurs dans leur bande : 64 %.

Équilibre : tirage 36 / poussée 28 séries ; chaîne postérieure 4 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Traction un bras (`d3.1`) :
  - `exercise_removed` jour 1 : Traction un bras (plan.reoptimized)
  - `exercise_replaced` jour 3 : Traction un bras → Traction archer excentrique lente (plan.user_cannot_do, plan.variant_easier)
  - `exercise_removed` jour 5 : Traction un bras (plan.reoptimized)
- Remplacement par Frog stretch (grenouille) (`d2.8`) :
  - `exercise_replaced` jour 2 : Étirement en bas de dips aux barres parallèles → Frog stretch (grenouille) (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Planche straddle | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 5×4-6 s · 4 fl. · 120s | 5×4-6 s · 5 fl. · 120s | 5×4-6 s · 6 fl. · 120s | TEST 2×1-12 s · 10 fl. · 180s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Pont fessier au sol | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Élévation latérale à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Dead hang | 2×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 3×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Front lever | 5×6-9 s · 4 fl. · 120s | 5×6-9 s · 4 fl. · 120s | 6×6-9 s · 4 fl. · 120s | 6×6-9 s · 5 fl. · 120s | 6×6-9 s · 6 fl. · 120s | 4×6-9 s · 2 fl. · 120s |
| Tenue menton au-dessus de la barre un bras | 5×10-20 s · 4 fl. · 120s | 5×10-20 s · 4 fl. · 120s | 6×10-20 s · 4 fl. · 120s | 6×10-20 s · 5 fl. · 120s | 6×10-20 s · 6 fl. · 120s | 4×10-20 s · 2 fl. · 120s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Étirement du grand dorsal en charnière à la barre | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Planche straddle | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 5×4-6 s · 4 fl. · 120s | 5×4-6 s · 5 fl. · 120s | 5×4-6 s · 6 fl. · 120s | 3×4-6 s · 2 fl. · 120s |
| HSPU au mur dos au mur | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de jambes allongé au sol | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Frog stretch (grenouille) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction archer excentrique lente | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Front lever | 4×6-9 s · 4 fl. · 120s | 4×6-9 s · 4 fl. · 120s | 5×6-9 s · 4 fl. · 120s | 5×6-9 s · 5 fl. · 120s | 5×6-9 s · 6 fl. · 120s | 3×6-9 s · 2 fl. · 120s |
| Drapeau humain tuck | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Planche une jambe | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 6×5-10 s · 4 fl. · 120s | 6×5-10 s · 5 fl. · 120s | 6×5-10 s · 6 fl. · 120s | 4×5-10 s · 2 fl. · 120s |
| Planche push-up straddle assistée à l'élastique | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| HSPU libre | 3×2-3 · 5 fl. · 90s | 4×2-3 · 5 fl. · 90s | 4×2-3 · 5 fl. · 90s | 4×2-3 · 6 fl. · 90s | 4×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Toes-to-bar négatif | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Bird dog | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Front lever | 5×6-9 s · 4 fl. · 120s | 5×6-9 s · 4 fl. · 120s | 6×6-9 s · 4 fl. · 120s | 6×6-9 s · 5 fl. · 120s | 6×6-9 s · 6 fl. · 120s | 4×6-9 s · 2 fl. · 120s |
| Skater squat | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hollow body hold | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Pancake assis | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement en bas de dips aux barres parallèles | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |

## 25. `streetlifting_debutant_3x60`

Débutant en streetlifting : peu de tractions, pas encore de lest.

Profil : streetlifting 50 % + street_workout 40 % + calisthenics 10 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — mode street, 74 kg, né en 2002, male, santé standard.

### Passe 1

Note 0.967 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.95 · pattern_balance 1.00 · discipline_structure 0.95 · time_use 1.00 · variety 1.00 · exercise_fit 0.80 · stimulus_fatigue 0.61 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 55 min) — `strength.upper`
  - Squat de compétition — main `sl-squat-competition`
  - Dips au banc lesté — secondary `sl-dips-banc-leste`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Traction pronation — secondary `sw-traction-pronation`
  - Row australien aux barres parallèles — secondary `sw-row-australien-barres-paralleles`
- **mercredi** (60 min, estimé 59 min) — `strength.full_body`
  - Compression straddle assis — skill `cs-compression-straddle`
  - Squat de compétition — main `sl-squat-competition`
  - Traction pronation — secondary `sw-traction-pronation`
  - Rack pull — secondary `mu-rack-pull`
  - Pompe en T — secondary `sw-pompe-t`
- **vendredi** (60 min, estimé 58 min) — `strength.upper`
  - Traction explosive poitrine à la barre — main `cd-traction-explosive-poitrine-barre`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Traction pronation — secondary `sw-traction-pronation`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Pompe en T — secondary `sw-pompe-t`
  - Row australien aux barres parallèles — secondary `sw-row-australien-barres-paralleles`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`

Dosage : streetWorkout 41 % (visé 40 %), streetlifting 50 % (visé 50 %), calisthenics 9 % (visé 10 %) — erreur 1.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 13.5 [8-16], delt_anterior 13.5 [8-16], delt_middle 3 [8-16], delt_posterior 9 [8-16], lats 18 [8-16], upper_back 15 [8-16], biceps 12 [8-16], triceps 16.5 [8-16], abs 8 [8-16], lower_back 8 [8-16], glutes 15 [8-16], quads 15 [8-16], hamstrings 11 [8-16], calves 3 [0-16]. Groupes majeurs dans leur bande : 78 %.

Équilibre : tirage 18 / poussée 15 séries ; chaîne postérieure 8 / genou 10 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Dips aux barres parallèles (`d0.3`) :
  - `exercise_replaced` jour 0 : Dips aux barres parallèles → Développé couché pieds sur le banc (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_removed` jour 2 : Dips aux barres parallèles (plan.reoptimized)
- Remplacement par Rack pull (`d2.4`) :
  - `exercise_replaced` jour 2 : Soulevé de terre conventionnel → Rack pull (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 6 fl. · 180s · 47.5 kg | 5×2-5 · 7 fl. · 180s · 50 kg | 3×3-6 · 3 fl. · 180s · 45 kg |
| Dips au banc lesté | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Développé couché pieds sur le banc | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 2×5-8 · 4 fl. · 150s · 72 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 6 fl. · 150s · 74 % 1RM | 1×5-8 · 2 fl. · 150s · 71 % 1RM |
| Row australien aux barres parallèles | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Compression straddle assis | 2×10-20 s · 4 fl. · 120s | 3×10-20 s · 4 fl. · 120s | 3×10-20 s · 5 fl. · 120s | 3×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 6 fl. · 180s · 47.5 kg | 5×2-5 · 7 fl. · 180s · 50 kg | 3×3-6 · 3 fl. · 180s · 45 kg |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Rack pull | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 3×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Pompe en T | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Traction explosive poitrine à la barre | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Rack pull | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Pompe en T | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Row australien aux barres parallèles | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Relevé de jambes tendues suspendu | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 26. `forme_generale_exterieur_3x40`

Forme générale en extérieur, 3 × 40 min.

Profil : general_fitness 70 % + cardio 30 % — mardi 40 min, jeudi 40 min, dimanche 40 min — lieux exterieur — 62 kg, né en 1992, female, santé standard.

### Passe 1

Note 0.950 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.81 · pattern_balance 0.88 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.89 · preferences 1.00 · novelty 1.00.

- **mardi** (40 min, estimé 39 min) — `cardio.endurance`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **jeudi** (40 min, estimé 39 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Row australien — secondary `sw-row-australien`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **dimanche** (40 min, estimé 39 min) — `strength.full_body`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`

Dosage : cardio 54 % (visé 55 %), mobility 10 % (visé 11 %), generalFitness 35 % (visé 35 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [2-5], delt_anterior 3 [2-5], delt_middle 1 [2-5], delt_posterior 5 [2-5], lats 3 [2-5], upper_back 5 [2-5], biceps 2.5 [2-5], triceps 3 [2-5], abs 4 [2-5], lower_back 4 [2-5], glutes 5 [2-5], quads 3 [2-5], hamstrings 1 [0-5], calves 1.5 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement chaîne postérieure en flexion avant debout (`d0.3`) :
  - `exercise_replaced` jour 0 : Étirement chaîne postérieure en flexion avant debout → Demi-grand écart (half split) (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Chaise contre le mur (`d1.1`) :
  - `exercise_replaced` jour 1 : Air squat → Chaise contre le mur (plan.user_replaced)
  - `order_changed` jour 1 (plan.reoptimized)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Corde à sauter sauts simples | 3×45-60 s · 30s | 4×45-60 s · 30s | 4×45-60 s · 30s | 4×45-60 s · 30s |
| Footing en endurance fondamentale | 22-25 min | 22-25 min | 27-30 min | 27-30 min |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Row australien | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Chaise contre le mur | 2×5-12 s · 3 fl. · 60s | 3×5-12 s · 3 fl. · 60s | 3×5-12 s · 4 fl. · 60s | 3×5-12 s · 5 fl. · 60s |
| Gainage latéral bras tendu | 2×10-20 s · 3 fl. · 60s | 3×10-20 s · 3 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s |
| Corde à sauter sauts simples | 3×45-60 s · 30s | 4×45-60 s · 30s | 4×45-60 s · 30s | 4×45-60 s · 30s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe classique | 2×3-4 · 3 fl. · 90s | 3×3-4 · 3 fl. · 90s | 3×3-4 · 4 fl. · 90s | 3×3-4 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Footing en endurance fondamentale | 9-10 min | 13-15 min | 13-15 min | 13-15 min |

## 27. `senior_72_mobilite_marche_4x30`

Senior de 72 ans : mobilité et marche, 4 × 30 min, mode prudent.

Profil : mobility 60 % + cardio 40 % — lundi 30 min, mercredi 30 min, vendredi 30 min, dimanche 30 min — lieux maison, exterieur — 79 kg, né en 1954, male, santé cautious, hip gêne 3/10, lower_back gêne 2/10.

### Passe 1

Note 0.974 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.63 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 27 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — mobility `mo-chaine-posterieure-flexion-avant-debout`
  - Mobilisation cheville genou au mur — mobility `mo-cheville-genou-mur`
  - Cohérence cardiaque — mobility `mo-coherence-cardiaque`
  - Étirement pectoral au cadre de porte — mobility `mo-etirement-pectoral-cadre-porte`
  - Étirement des orteils en extension agenouillé — mobility `mo-extension-orteils-agenouille`
  - Marche sur les talons — mobility `mo-marche-talons`
  - Respiration crocodile — mobility `mo-respiration-crocodile`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **mercredi** (30 min, estimé 28 min) — `cardio.endurance`
  - Marche de récupération — conditioning `ca-marche-recuperation`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **vendredi** (30 min, estimé 30 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Bascules en appui doigts vers l'avant — mobility `mo-bascules-appui-doigts-avant`
  - Étirement chaîne postérieure en flexion avant debout — mobility `mo-chaine-posterieure-flexion-avant-debout`
  - Mobilisation cheville genou au mur — mobility `mo-cheville-genou-mur`
  - Étirement des fléchisseurs du poignet bras tendu — mobility `mo-etirement-flechisseurs-poignet-bras-tendu`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Mobilité douce du cou en trois plans — mobility `mo-mobilite-cou-trois-plans`
  - Respiration crocodile — mobility `mo-respiration-crocodile`
  - Rotation interne active de hanche en quadrupédie — mobility `mo-rotation-interne-hanche-quadrupedie`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **dimanche** (30 min, estimé 28 min) — `cardio.endurance`
  - Marche de récupération — conditioning `ca-marche-recuperation`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Cobra (extension du rachis au sol) — cooldown `mo-cobra`

Dosage : cardio 40 % (visé 40 %), mobility 60 % (visé 60 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Mobilité douce du cou en trois plans (`d2.7`) :
  - `exercise_replaced` jour 2 : Mobilité douce du cou en trois plans → Rétraction du menton (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par CARs de cheville (`d2.4`) :
  - `exercise_replaced` jour 2 : Mobilisation cheville genou au mur → CARs de cheville (plan.user_replaced)
  - `order_changed` jour 2 (plan.reoptimized)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Cohérence cardiaque | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Étirement pectoral au cadre de porte | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des orteils en extension agenouillé | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Marche sur les talons | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche de récupération | 18-20 min | 22-25 min | 22-25 min | 22-25 min |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Bascules en appui doigts vers l'avant | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| CARs de cheville | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche de récupération | 13-15 min | 18-20 min | 18-20 min | 18-20 min |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Cobra (extension du rachis au sol) | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

## 28. `femme_60_musculation_salle_2x45`

Femme de 60 ans, musculation sur machines, 2 × 45 min.

Profil : musculation 80 % + mobility 20 % — mardi 45 min, vendredi 45 min — lieux salle — 70 kg, né en 1966, female, santé standard.

### Passe 1

Note 0.951 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.77 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.86 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 45 min) — `strength.upper`
  - Pompe en T — main `sw-pompe-t`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé épaules à la Smith machine assis — secondary `mu-developpe-epaules-smith-assis`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Mountain climbers — core `mu-mountain-climbers`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **vendredi** (45 min, estimé 45 min) — `strength.full_body`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Presse à cuisses 45° — main `mu-presse-cuisses-45`
  - Row australien — secondary `sw-row-australien`
  - Rowing menton à la poulie — accessory `mu-rowing-menton-poulie`
  - Planche RKC — core `mu-planche-rkc`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : musculation 82 % (visé 80 %), mobility 18 % (visé 20 %) — erreur 2.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 4.5 [4-7.5], delt_anterior 7.5 [4-7.5], delt_middle 7.5 [4-7.5], delt_posterior 4.5 [4-7.5], lats 6 [4-7.5], upper_back 4.5 [4-7.5], biceps 4.5 [4-7.5], triceps 4.5 [4-7.5], abs 7.5 [4-7.5], lower_back 1.5 [4-7.5], glutes 6 [4-7.5], quads 6 [4-7.5], hamstrings 4.5 [4-7.5], calves 0 [4-7.5]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement des fléchisseurs de hanche en semi-agenouillé (`d1.7`) :
  - `exercise_replaced` jour 1 : Étirement des fléchisseurs de hanche en semi-agenouillé → Couch stretch (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par CARs de hanche (`d1.1`) :
  - `exercise_replaced` jour 1 : Rotation interne active de hanche en quadrupédie → CARs de hanche (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pompe en T | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé épaules à la Smith machine assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mountain climbers | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| CARs de hanche | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Presse à cuisses 45° | 2×6-10 · 5 fl. · 120s · 35 kg | 3×6-10 · 5 fl. · 120s · 35 kg | 3×6-10 · 6 fl. · 120s · 35 kg | 3×6-10 · 7 fl. · 120s · 35 kg | 2×6-10 · 3 fl. · 120s · 35 kg |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Rowing menton à la poulie | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Couch stretch | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 29. `homme_40_cardio_musculation_50_50`

Cardio et musculation à parts égales (50/50), 4 × 50 min.

Profil : cardio 50 % + musculation 50 % — lundi 50 min, mercredi 50 min, vendredi 50 min, dimanche 50 min — lieux salle, exterieur — 80 kg, né en 1986, male, santé standard.

### Passe 1

Note 0.974 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.98 · pattern_balance 0.99 · discipline_structure 0.99 · time_use 1.00 · variety 1.00 · exercise_fit 0.73 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (50 min, estimé 46 min) — `strength.full_body`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Planche RKC — core `mu-planche-rkc`
- **mercredi** (50 min, estimé 49 min) — `strength.full_body`
  - Éducatif de course talons-fesses — conditioning `ca-educatif-talons-fesses`
  - Soulevé de terre conventionnel — main `mu-souleve-de-terre-conventionnel`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Rowing menton à la poulie — accessory `mu-rowing-menton-poulie`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
- **vendredi** (50 min, estimé 48 min) — `strength.full_body`
  - Fartlek — conditioning `ca-fartlek`
  - Fente marchée aux haltères — main `mu-fente-marchee-halteres`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Cuban press haltères — accessory `mu-cuban-press`
- **dimanche** (50 min, estimé 50 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`

Dosage : musculation 50 % (visé 50 %), cardio 50 % (visé 50 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [5.5-10.5], delt_anterior 9 [5.5-10.5], delt_middle 6 [5.5-10.5], delt_posterior 6 [5.5-10.5], lats 9 [5.5-10.5], upper_back 10.5 [5.5-10.5], biceps 6 [5.5-10.5], triceps 7.5 [5.5-10.5], abs 6 [5.5-10.5], lower_back 5 [5.5-10.5], glutes 8 [5.5-10.5], quads 6 [5.5-10.5], hamstrings 6.5 [5.5-10.5], calves 2.5 [5.5-10.5]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 5 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Soulevé de terre jambes tendues (`d0.2`) :
  - `exercise_replaced` jour 0 : Soulevé de terre jambes tendues → Soulevé de terre roumain aux haltères (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
- Remplacement par Accélérations progressives en ligne droite (`d1.1`) :
  - `exercise_replaced` jour 1 : Éducatif de course talons-fesses → Accélérations progressives en ligne droite (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 13-15 min | 18-20 min | 18-20 min | 18-20 min | 9-10 min |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 6 fl. · 120s · 42.5 kg | 3×6-10 · 7 fl. · 120s · 45 kg | 2×6-10 · 3 fl. · 120s · 42.5 kg |
| Soulevé de terre roumain aux haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 2×6-10 · 5 fl. · 120s · 70 % 1RM | 2×6-10 · 6 fl. · 120s · 71 % 1RM | 2×6-10 · 7 fl. · 120s · 71 % 1RM | 1×6-10 · 3 fl. · 120s · 68 % 1RM |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Accélérations progressives en ligne droite | 2×30 m · 30s | 3×30 m · 30s | 3×30 m · 30s | 3×30 m · 30s | 2×30 m · 30s |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing menton à la poulie | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Fartlek | 4×60-90 s · 90s | 5×60-90 s · 90s | 5×60-90 s · 90s | 5×60-90 s · 90s | 3×60-90 s · 90s |
| Fente marchée aux haltères | 2×20 m · 4 fl. · 90s | 3×20 m · 4 fl. · 90s | 3×20 m · 5 fl. · 90s | 3×20 m · 6 fl. · 90s | 2×20 m · 2 fl. · 90s |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Rowing inversé à la Smith machine | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Cuban press haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 36-40 min | 40-45 min | 45-50 min | 45-50 min | 27-30 min |

## 30. `trois_disciplines_70_20_10`

Trois disciplines dosées : musculation 70 %, mobilité 20 %, cardio 10 % (exemple de D3.2).

Profil : musculation 70 % + mobility 20 % + cardio 10 % — lundi 60 min, mercredi 45 min, samedi 90 min — lieux salle — 75 kg, né en 1990, male, santé standard.

### Passe 1

Note 0.969 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.full_body`
  - Pistol squat debout sur banc — main `sw-pistol-squat-banc`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Planche RKC — core `mu-planche-rkc`
  - Sit-up — core `mu-sit-up`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement du trapèze supérieur — cooldown `mo-etirement-trapeze-superieur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **mercredi** (45 min, estimé 45 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Pompe classique — secondary `sw-pompe`
  - Élévation frontale haltères — accessory `mu-elevation-frontale-halteres`
  - Pallof press debout — core `mu-pallof-press-debout`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **samedi** (90 min, estimé 90 min) — `strength.full_body`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Barre au front à la barre EZ — accessory `mu-barre-au-front-ez`
  - Élévation latérale buste appuyé sur banc incliné — accessory `mu-elevation-laterale-buste-appuye-banc-incline`
  - Y raise sur banc incliné — accessory `mu-y-raise-banc-incline`
  - Vélo en endurance — conditioning `ca-velo-endurance`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`

Dosage : musculation 69 % (visé 70 %), cardio 11 % (visé 10 %), mobility 19 % (visé 20 %) — erreur 1.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7 [7.5-14.5], delt_anterior 11 [7.5-14.5], delt_middle 9 [7.5-14.5], delt_posterior 7.5 [7.5-14.5], lats 9 [7.5-14.5], upper_back 13.5 [7.5-14.5], biceps 7 [7.5-14.5], triceps 9 [7.5-14.5], abs 8 [7.5-14.5], lower_back 7.5 [7.5-14.5], glutes 12 [7.5-14.5], quads 9 [7.5-14.5], hamstrings 7.5 [7.5-14.5], calves 4.5 [7.5-14.5]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 6 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Routine d'auto-massage au rouleau (membres inférieurs et dos) (`d0.9`) :
  - `exercise_replaced` jour 0 : Routine d'auto-massage au rouleau (membres inférieurs et dos) → Demi-grand écart (half split) (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_removed` jour 1 : Routine d'auto-massage au rouleau (membres inférieurs et dos) (plan.reoptimized)
  - `exercise_removed` jour 2 : Routine d'auto-massage au rouleau (membres inférieurs et dos) (plan.reoptimized)
- Remplacement par Tuck-up (`d0.6`) :
  - `exercise_replaced` jour 0 : Sit-up → Tuck-up (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pistol squat debout sur banc | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Tuck-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement du trapèze supérieur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 55 kg | 3×6-10 · 5 fl. · 120s · 55 kg | 3×6-10 · 6 fl. · 120s · 55 kg | 3×6-10 · 7 fl. · 120s · 57.5 kg | 2×6-10 · 3 fl. · 120s · 55 kg |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pompe classique | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Élévation frontale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Routine mobilité épaules et poignets | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Barre au front à la barre EZ | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Élévation latérale buste appuyé sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Vélo en endurance | 13-15 min | 18-20 min | 18-20 min | 18-20 min | 9-10 min |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

## 31. `niveaux_inconnus_sans_poids`

Aucun niveau connu (« je ne sais pas » partout), poids non renseigné.

Profil : musculation 100 % — mardi 60 min, jeudi 60 min — lieux salle — né en 1995, female, santé not_answered.

### Passe 1

Note 0.972 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **mardi** (60 min, estimé 59 min) — `strength.full_body`
  - Soulevé de terre kettlebell — main `mu-souleve-de-terre-kettlebell`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Chaise contre le mur — accessory `mu-wall-sit`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`
- **jeudi** (60 min, estimé 59 min) — `strength.full_body`
  - Développé haltères assis — main `mu-developpe-halteres-assis`
  - Soulevé de terre kettlebell — secondary `mu-souleve-de-terre-kettlebell`
  - Air squat — secondary `mu-air-squat`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - W raise sur banc incliné — accessory `mu-w-raise-banc-incline`
  - Pallof press debout — core `mu-pallof-press-debout`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [4-10], delt_anterior 10 [4-10], delt_middle 5 [4-10], delt_posterior 5.5 [4-10], lats 9 [4-10], upper_back 9.5 [4-10], biceps 4.5 [4-10], triceps 7.5 [4-10], abs 4 [4-10], lower_back 3 [4-10], glutes 10 [4-10], quads 8 [4-10], hamstrings 6 [4-10], calves 3.5 [4-10]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 6 / genou 5 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Soulevé de terre kettlebell (`d0.1`) :
  - `exercise_replaced` jour 0 : Soulevé de terre kettlebell → Hip thrust à la machine (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_added` jour 1 → Soulevé de terre roumain aux haltères (plan.reoptimized)
  - `exercise_removed` jour 1 : Soulevé de terre kettlebell (plan.reoptimized)
- Remplacement par Mollets debout à la Smith machine (`d0.7`) :
  - `exercise_replaced` jour 0 : Mollets debout à la machine → Mollets debout à la Smith machine (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Développé couché Smith machine | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Chaise contre le mur | 2×5-12 s · 3 fl. · 60s | 2×5-12 s · 3 fl. · 60s | 2×5-12 s · 4 fl. · 60s | 2×5-12 s · 5 fl. · 60s |
| Hip thrust à la machine | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Mollets debout à la Smith machine | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Gainage ventral sur les coudes | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Développé haltères assis | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Soulevé de terre roumain aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Air squat | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Développé couché Smith machine | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| W raise sur banc incliné | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |

## 32. `sans_objectif_mode_libre`

Aucun objectif, mode libre.

Profil : street_workout 60 % + musculation 40 % — lundi 60 min, jeudi 60 min, samedi 60 min — lieux salle, exterieur — 92 kg, né en 1983, male, santé standard.

### Passe 1

Note 0.970 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 0.98 · discipline_structure 0.96 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.82 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.full_body`
  - Soulevé de terre conventionnel — main `mu-souleve-de-terre-conventionnel`
  - Pistol squat debout sur banc — secondary `sw-pistol-squat-banc`
  - Pompe diamant — secondary `sw-pompe-diamant`
  - Traction pronation — secondary `sw-traction-pronation`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Porté au-dessus de la tête (overhead carry) — accessory `mu-overhead-carry`
  - Leg curl couché — accessory `mu-leg-curl-couche`
- **jeudi** (60 min, estimé 57 min) — `strength.upper`
  - Pistol squat debout sur banc — main `sw-pistol-squat-banc`
  - Pompe pike — secondary `sw-pompe-pike`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Turkish get-up — core `mu-turkish-get-up`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`
- **samedi** (60 min, estimé 56 min) — `strength.push`
  - Handstand libre — skill `cs-handstand`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Pompe pike — main `sw-pompe-pike`
  - Traction pronation — secondary `sw-traction-pronation`
  - Pompe prise large — secondary `sw-pompe-large`
  - Pont fessier pieds surélevés — accessory `mu-pont-fessier-pieds-sureleves`
  - Planche RKC — core `mu-planche-rkc`

Dosage : musculation 40 % (visé 40 %), streetWorkout 60 % (visé 60 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 13 [8-16], delt_anterior 16.5 [8-16], delt_middle 8 [8-16], delt_posterior 11 [8-16], lats 15 [8-16], upper_back 16.5 [8-16], biceps 9 [8-16], triceps 15 [8-16], abs 10.5 [8-16], lower_back 7.5 [8-16], glutes 16 [8-16], quads 13 [8-16], hamstrings 12 [8-16], calves 7 [8-16]. Groupes majeurs dans leur bande : 78 %.

Équilibre : tirage 18 / poussée 17 séries ; chaîne postérieure 9 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Turkish get-up (`d1.5`) :
  - `exercise_replaced` jour 1 : Turkish get-up → Gainage latéral bras tendu (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Pont fessier unilatéral (`d2.6`) :
  - `exercise_replaced` jour 2 : Pont fessier pieds surélevés → Pont fessier unilatéral (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pistol squat debout sur banc | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe diamant | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Porté au-dessus de la tête (overhead carry) | 2×30 m · 4 fl. · 90s | 3×30 m · 4 fl. · 90s | 3×30 m · 5 fl. · 90s | 3×30 m · 6 fl. · 90s | 2×30 m · 2 fl. · 90s |
| Leg curl couché | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pistol squat debout sur banc | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Gainage latéral bras tendu | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Flexion latérale à l'haltère | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Pompe prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |

## 33. `objectif_habitude_seul`

Un seul objectif d'habitude suggéré par Koach.

Profil : general_fitness 100 % — lundi 30 min, mercredi 30 min, vendredi 30 min — lieux maison — 65 kg, né en 1993, female, santé standard.

### Passe 1

Note 0.937 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.78 · pattern_balance 0.88 · discipline_structure 0.93 · time_use 1.00 · variety 1.00 · exercise_fit 0.64 · stimulus_fatigue 0.83 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 30 min) — `cardio.endurance`
  - Marche rapide — conditioning `ca-marche-rapide`
- **mercredi** (30 min, estimé 29 min) — `strength.full_body`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **vendredi** (30 min, estimé 30 min) — `strength.full_body`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Rowing assis à l'élastique — main `mu-rowing-elastique-assis`
  - Fente arrière au poids du corps — secondary `mu-fente-arriere-poids-du-corps`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`

Dosage : cardio 36 % (visé 35 %), mobility 15 % (visé 15 %), generalFitness 49 % (visé 50 %) — erreur 0.9 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [2-5], delt_anterior 3 [2-5], delt_middle 1 [2-5], delt_posterior 3.5 [2-5], lats 3 [2-5], upper_back 5 [2-5], biceps 2.5 [2-5], triceps 3 [2-5], abs 4 [2-5], lower_back 4 [2-5], glutes 5 [2-5], quads 3 [2-5], hamstrings 2.5 [2-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Fente arrière au poids du corps (`d2.3`) :
  - `exercise_replaced` jour 2 : Fente arrière au poids du corps → Fente arrière aux haltères (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par Étirement fessier en figure 4 allongé (`d1.5`) :
  - `exercise_replaced` jour 1 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche rapide | 22-25 min | 22-25 min | 27-30 min | 27-30 min |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe classique | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s |
| Fente arrière aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Rowing assis à l'élastique | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Gainage latéral bras tendu | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 34. `objectif_figure_front_lever`

Objectif de figure : front lever débloqué.

Profil : calisthenics 60 % + street_workout 40 % — lundi 60 min, mercredi 60 min, vendredi 60 min, samedi 60 min — lieux exterieur — 68 kg, né en 2000, male, santé standard.

### Passe 1

Note 0.961 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.92 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 0.96 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.78 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 49 min) — `strength.upper`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - Handstand libre — skill `cs-handstand`
  - Traction aux anneaux — main `sw-traction-anneaux`
  - Skater squat — secondary `sw-skater-squat`
  - Gainage latéral avec abduction de hanche — core `mu-gainage-lateral-abduction`
- **mercredi** (60 min, estimé 49 min) — `skills`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - Handstand libre — skill `cs-handstand`
  - L-sit au sol — skill `cs-l-sit-sol`
  - Pompe pseudo-planche — main `cd-pompe-pseudo-planche`
  - Pompe hindoue — secondary `sw-pompe-hindu`
- **vendredi** (60 min, estimé 49 min) — `strength.upper`
  - Back lever straddle — skill `cs-back-lever-straddle`
  - Handstand libre — skill `cs-handstand`
  - HSPU au mur amplitude réduite sur coussin — main `cd-hspu-mur-amplitude-reduite`
  - Dead hang — accessory `sw-dead-hang`
  - Knees-to-elbows — core `sw-knees-to-elbows`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **samedi** (60 min, estimé 50 min) — `strength.pull`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - Front lever raise tuck — skill `cd-front-lever-raise-tuck`
  - Traction pronation — main `sw-traction-pronation`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`

Dosage : streetWorkout 42 % (visé 40 %), calisthenics 58 % (visé 60 %) — erreur 1.7 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 12 [8-16], delt_anterior 17 [8-16], delt_middle 9 [8-16], delt_posterior 11 [8-16], lats 16 [8-16], upper_back 13.5 [8-16], biceps 8 [8-16], triceps 17 [8-16], abs 15 [8-16], lower_back 1.5 [8-16], glutes 9 [8-16], quads 9 [8-16], hamstrings 3 [8-16], calves 0 [0-16]. Groupes majeurs dans leur bande : 76 %.

Équilibre : tirage 26 / poussée 21 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Front lever tuck (`d3.1`) :
  - `exercise_added` jour 0 → Front lever assisté élastique (plan.reoptimized)
  - `exercise_removed` jour 0 : Front lever tuck (plan.reoptimized)
  - `exercise_added` jour 1 → Front lever assisté élastique (plan.reoptimized)
  - `exercise_removed` jour 1 : Front lever tuck (plan.reoptimized)
  - `exercise_replaced` jour 3 : Front lever tuck → Front lever assisté élastique (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Pompe dive bomber (`d1.5`) :
  - `exercise_replaced` jour 1 : Pompe hindoue → Pompe dive bomber (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever assisté élastique | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | TEST 2×1-20 s · 10 fl. · 180s |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Traction aux anneaux | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Skater squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Gainage latéral avec abduction de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever assisté élastique | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit au sol | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Pompe pseudo-planche | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pompe dive bomber | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Back lever straddle | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| HSPU au mur amplitude réduite sur coussin | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Dead hang | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Knees-to-elbows | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever assisté élastique | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Front lever raise tuck | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Traction pronation | 2×6-9 · 5 fl. · 90s | 3×6-9 · 5 fl. · 90s | 3×6-9 · 6 fl. · 90s | 3×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de jambes tendues suspendu | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 35. `semi_marathon`

Objectif de temps sur semi-marathon.

Profil : cardio 80 % + mobility 10 % + musculation 10 % — mardi 60 min, jeudi 60 min, samedi 45 min, dimanche 120 min — lieux exterieur — 59 kg, né en 1990, female, santé standard.

### Passe 1

Note 0.960 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.97 · muscle_volume 0.92 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.72 · preferences 1.00 · novelty 1.00.

- **mardi** (60 min, estimé 60 min) — `cardio.intervals`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Fractionné en côtes longues — conditioning `ca-cotes-longues`
  - Pompe hindoue — main `sw-pompe-hindu`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **jeudi** (60 min, estimé 60 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **samedi** (45 min, estimé 45 min) — `cardio.endurance`
  - Sortie longue en course à pied — conditioning `ca-sortie-longue`
- **dimanche** (120 min, estimé 118 min) — `cardio.endurance`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Pompe pike — main `sw-pompe-pike`
  - Skater squat — secondary `sw-skater-squat`
  - V-up — core `mu-v-up`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : musculation 12 % (visé 10 %), cardio 80 % (visé 80 %), mobility 8 % (visé 10 %) — erreur 2.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 5 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 1 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 1 [0-5], biceps 0 [0-5], triceps 5 [1.5-5], abs 5 [1.5-5], lower_back 1.5 [1.5-5], glutes 4 [1.5-5], quads 3 [1.5-5], hamstrings 2 [1.5-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 5 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 4/4.

### Revue simulée

- « Je ne sais pas faire » sur Mobilité hanches 90/90 passive (`d0.6`) :
  - `exercise_replaced` jour 0 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_removed` jour 3 : Mobilité hanches 90/90 passive (plan.reoptimized)
- Remplacement par Demi-grand écart (half split) (`d0.8`) :
  - `exercise_replaced` jour 0 : Étirement des gastrocnémiens au mur jambe tendue → Demi-grand écart (half split) (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |
| Fractionné en côtes longues | 4×60-90 s · 90s | 5×60-90 s · 90s | 5×60-90 s · 90s | 5×60-90 s · 90s | 3×60-90 s · 90s |
| Pompe hindoue | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Mountain climbers | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 5 fl. · 60s | 1×20-40 s · 6 fl. · 60s | 1×20-40 s · 2 fl. · 60s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 1×20-30 s · 10s | 1×20-30 s · 10s | 1×20-30 s · 10s | 1×20-30 s · 10s | 1×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 40-45 min | 49-55 min | 49-55 min | 54-60 min | 31-35 min |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Sortie longue en course à pied | 31-35 min | 36-40 min | 40-45 min | 40-45 min | TEST 1×21097.5 m |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Footing en endurance fondamentale | 49-55 min | 63-70 min | 63-70 min | 67-75 min | 40-45 min |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 3×45-60 s · 30s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| Skater squat | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| V-up | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 36. `prudent_sante_musculation`

Questionnaire santé en mode prudent, musculation légère.

Profil : musculation 60 % + cardio 40 % — lundi 45 min, jeudi 45 min — lieux salle — 89 kg, né en 1970, male, santé cautious.

### Passe 1

Note 0.953 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.84 · pattern_balance 0.94 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 0.91 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 44 min) — `strength.upper`
  - Pompe classique — main `sw-pompe`
  - Tirage haut à la machine convergente — secondary `mu-tirage-haut-machine-convergente`
  - Reverse hyper sur banc — accessory `mu-reverse-hyper-banc`
  - Mountain climbers — core `mu-mountain-climbers`
  - Vélo en endurance — conditioning `ca-velo-endurance`
- **jeudi** (45 min, estimé 43 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Pompe classique — secondary `sw-pompe`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Vélo en endurance — conditioning `ca-velo-endurance`

Dosage : musculation 61 % (visé 60 %), cardio 39 % (visé 40 %) — erreur 1.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [2.5-6], delt_anterior 6 [2.5-6], delt_middle 0 [2.5-6], delt_posterior 3 [2.5-6], lats 6 [2.5-6], upper_back 6 [2.5-6], biceps 3 [2.5-6], triceps 6 [2.5-6], abs 4 [2.5-6], lower_back 3 [2.5-6], glutes 5 [2.5-6], quads 5 [2.5-6], hamstrings 1 [2.5-6], calves 1.5 [2.5-6]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Mountain climbers (`d0.4`) :
  - `exercise_replaced` jour 0 : Mountain climbers → Gainage latéral sur les genoux (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Goblet squat (`d1.1`) :
  - `exercise_replaced` jour 1 : Air squat → Goblet squat (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe classique | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Tirage haut à la machine convergente | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Reverse hyper sur banc | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Gainage latéral sur les genoux | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Vélo en endurance | 9-10 min | 13-15 min | 13-15 min | 13-15 min |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Goblet squat | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Rowing inversé à la Smith machine | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Pompe classique | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Vélo en endurance | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

## 37. `tres_grand_lourd`

Grand gabarit : 198 cm, 130 kg.

Profil : musculation 70 % + cardio 30 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 130 kg, né en 1992, male, santé standard.

### Passe 1

Note 0.971 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.77 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 57 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - V-up — core `mu-v-up`
- **mercredi** (60 min, estimé 59 min) — `cardio.endurance`
  - Row australien — main `sw-row-australien`
  - Copenhagen plank — accessory `mu-copenhagen-plank`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Rameur en endurance — conditioning `ca-rameur-endurance`
- **vendredi** (60 min, estimé 58 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre jambes tendues — secondary `mu-souleve-de-terre-jambes-tendues`
  - Row australien — secondary `sw-row-australien`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Vélo en endurance — conditioning `ca-velo-endurance`

Dosage : musculation 72 % (visé 70 %), cardio 28 % (visé 30 %) — erreur 1.7 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [6.5-13.5], delt_anterior 10.5 [6.5-13.5], delt_middle 6 [6.5-13.5], delt_posterior 7.5 [6.5-13.5], lats 9 [6.5-13.5], upper_back 9 [6.5-13.5], biceps 6 [6.5-13.5], triceps 7.5 [6.5-13.5], abs 7.5 [6.5-13.5], lower_back 11.5 [6.5-13.5], glutes 13 [6.5-13.5], quads 9 [6.5-13.5], hamstrings 7 [6.5-13.5], calves 5 [6.5-13.5]. Groupes majeurs dans leur bande : 82 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 7 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Woodchop à la poulie haut vers bas (`d2.5`) :
  - `exercise_replaced` jour 2 : Woodchop à la poulie haut vers bas → Rotation du tronc à la poulie assis (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Soulevé de terre roumain à la barre (`d2.2`) :
  - `exercise_replaced` jour 2 : Soulevé de terre jambes tendues → Soulevé de terre roumain à la barre (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 6 fl. · 120s · 87.5 kg | 3×6-10 · 7 fl. · 120s · 90 kg | 2×6-10 · 3 fl. · 120s · 85 kg |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé haltères assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Développé couché Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| V-up | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Row australien | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Copenhagen plank | 2×5-12 s · 4 fl. · 60s | 3×5-12 s · 4 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 2×5-12 s · 2 fl. · 60s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Rameur en endurance | 22-25 min | 27-30 min | 31-35 min | 31-35 min | 18-20 min |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 6 fl. · 120s · 87.5 kg | 3×6-10 · 7 fl. · 120s · 90 kg | 2×6-10 · 3 fl. · 120s · 85 kg |
| Soulevé de terre roumain à la barre | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Développé couché Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rotation du tronc à la poulie assis | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Vélo en endurance | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |

## 38. `petite_legere`

Petit gabarit : 150 cm, 45 kg.

Profil : street_workout 70 % + mobility 30 % — mardi 45 min, jeudi 45 min, samedi 45 min — lieux exterieur, maison — 45 kg, né en 1999, female, santé standard.

### Passe 1

Note 0.959 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.90 · pattern_balance 1.00 · discipline_structure 0.94 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `strength.full_body`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Pompe en T — main `sw-pompe-t`
  - Skater squat — secondary `sw-skater-squat`
  - Traction pronation — secondary `sw-traction-pronation`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement de la capsule postérieure bras croisé — cooldown `mo-etirement-capsule-posterieure-bras-croise`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **jeudi** (45 min, estimé 41 min) — `strength.full_body`
  - Dips aux barres parallèles — main `sw-dips-barres-paralleles`
  - Row archer — secondary `sw-row-archer`
  - Nordic hamstring curl assisté à l'élastique — accessory `mu-nordic-hamstring-curl-assiste`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Étirement en bas de dips aux barres parallèles — cooldown `mo-etirement-bas-dips-barres`
  - Étirement en appui sur le dos des mains — cooldown `mo-appui-dos-des-mains`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
  - Sleeper stretch — cooldown `mo-sleeper-stretch`
- **samedi** (45 min, estimé 44 min) — `strength.upper`
  - Pompe classique — main `sw-pompe`
  - Row australien aux barres parallèles — secondary `sw-row-australien-barres-paralleles`
  - Élévation latérale à l'élastique — accessory `mu-elevation-laterale-elastique`
  - Bird dog — core `mu-bird-dog`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : streetWorkout 70 % (visé 70 %), mobility 30 % (visé 30 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9 [5-10], delt_anterior 10.5 [5-10], delt_middle 4.5 [5-10], delt_posterior 4.5 [5-10], lats 9 [5-10], upper_back 9 [5-10], biceps 7.5 [5-10], triceps 9 [5-10], abs 7.5 [5-10], lower_back 4 [5-10], glutes 7 [5-10], quads 6 [5-10], hamstrings 4.5 [5-10], calves 1.5 [0-10]. Groupes majeurs dans leur bande : 69 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Bird dog (`d2.4`) :
  - `exercise_replaced` jour 2 : Bird dog → Gainage latéral sur les genoux (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Toes-to-bar négatif (`d1.4`) :
  - `exercise_replaced` jour 1 : Relevé de jambes tendues suspendu → Toes-to-bar négatif (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Pompe en T | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Skater squat | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Traction pronation | 2×1-2 · 5 fl. · 90s | 3×1-2 · 5 fl. · 90s | 3×1-2 · 6 fl. · 90s | 3×1-2 · 7 fl. · 90s | 2×1-2 · 3 fl. · 90s |
| Pike assis passif | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement de la capsule postérieure bras croisé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Row archer | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Nordic hamstring curl assisté à l'élastique | 2×8-12 · 5 fl. · 75s | 3×8-12 · 5 fl. · 75s | 3×8-12 · 6 fl. · 75s | 3×8-12 · 7 fl. · 75s | 2×8-12 · 3 fl. · 75s |
| Toes-to-bar négatif | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Étirement en bas de dips aux barres parallèles | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement en appui sur le dos des mains | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Sleeper stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pompe classique | 2×6-9 · 5 fl. · 90s | 3×6-9 · 5 fl. · 90s | 3×6-9 · 6 fl. · 90s | 3×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Row australien aux barres parallèles | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Élévation latérale à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur les genoux | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 39. `sept_jours_courts_7x20`

Tous les jours, 20 min.

Profil : general_fitness 50 % + mobility 30 % + cardio 20 % — lundi 20 min, mardi 20 min, mercredi 20 min, jeudi 20 min, vendredi 20 min, samedi 20 min, dimanche 20 min — lieux maison — 76 kg, né en 1984, male, santé standard.

### Passe 1

Note 0.947 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.92 · muscle_volume 0.93 · pattern_balance 0.94 · discipline_structure 0.97 · time_use 1.00 · variety 0.96 · exercise_fit 0.60 · stimulus_fatigue 0.82 · preferences 1.00 · novelty 1.00.

- **lundi** (20 min, estimé 20 min) — `cardio.endurance`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Pompe classique — main `sw-pompe`
  - Marche rapide — conditioning `ca-marche-rapide`
- **mardi** (20 min, estimé 20 min) — `strength.full_body`
  - Tirage vertical à l'élastique — main `mu-tirage-vertical-elastique`
  - Fente latérale — secondary `mu-fente-laterale`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **mercredi** (20 min, estimé 20 min) — `cardio.endurance`
  - Marche rapide — conditioning `ca-marche-rapide`
- **jeudi** (20 min, estimé 20 min) — `strength.full_body`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Mobilité douce du cou en trois plans — warmup `mo-mobilite-cou-trois-plans`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **vendredi** (20 min, estimé 20 min) — `cardio.endurance`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Marche rapide — conditioning `ca-marche-rapide`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **samedi** (20 min, estimé 20 min) — `mobility`
  - Bascules en appui doigts vers l'avant — mobility `mo-bascules-appui-doigts-avant`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Étirement pectoral au cadre de porte — mobility `mo-etirement-pectoral-cadre-porte`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — mobility `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — mobility `mo-pigeon-sol`
  - Sleeper stretch — mobility `mo-sleeper-stretch`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **dimanche** (20 min, estimé 19 min) — `mobility`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : cardio 31 % (visé 38 %), mobility 36 % (visé 38 %), generalFitness 33 % (visé 25 %) — erreur 7.5 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 4 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 2 [1.5-5], delt_posterior 1 [1.5-5], lats 4 [1.5-5], upper_back 2 [1.5-5], biceps 2 [1.5-5], triceps 5 [1.5-5], abs 3 [1.5-5], lower_back 2 [1.5-5], glutes 4 [1.5-5], quads 3 [1.5-5], hamstrings 2 [1.5-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 4 / poussée 4 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Pompe classique (`d3.3`) :
  - `exercise_removed` jour 0 : Pompe classique (plan.reoptimized)
  - `exercise_replaced` jour 3 : Pompe classique → Pompe négative (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Élévation latérale haltères (`d4.1`) :
  - `exercise_replaced` jour 4 : Rowing menton haltères → Élévation latérale haltères (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s |
| Marche rapide | 9-10 min | 13-15 min | 13-15 min | 13-15 min |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Tirage vertical à l'élastique | 2×10-15 · 3 fl. · 90s | 2×10-15 · 3 fl. · 90s | 2×10-15 · 4 fl. · 90s | 2×10-15 · 5 fl. · 90s |
| Fente latérale | 2×6-12 · 3 fl. · 90s | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche rapide | 13-15 min | 18-20 min | 18-20 min | 18-20 min |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Mobilité douce du cou en trois plans | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe négative | 2×10-15 · 3 fl. · 90s | 2×10-15 · 3 fl. · 90s | 2×10-15 · 4 fl. · 90s | 2×10-15 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Marche rapide | 9-10 min | 9-10 min | 9-10 min | 9-10 min |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Bascules en appui doigts vers l'avant | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement pectoral au cadre de porte | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Sleeper stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Tirage bras tendus à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Mountain climbers | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 40. `materiel_complet_gouts_marques`

Salle complète, nombreux exercices aimés et détestés.

Profil : musculation 60 % + street_workout 20 % + cardio 20 % — lundi 60 min, mardi 60 min, jeudi 60 min, vendredi 60 min — lieux salle, maison, exterieur — 68 kg, né en 1994, female, santé standard.

### Passe 1

Note 0.967 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.74 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Back squat barre basse — main `mu-back-squat-barre-basse`
  - Soulevé de terre roumain à la barre — secondary `mu-souleve-de-terre-roumain-barre`
  - Traction pronation — secondary `sw-traction-pronation`
  - Traction supination — secondary `sw-traction-supination`
  - Face pull à la poulie corde — secondary `mu-face-pull-corde`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **mardi** (60 min, estimé 60 min) — `cardio.intervals`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Extension nuque à l'haltère à deux mains — accessory `mu-extension-nuque-haltere-deux-mains`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Corde à sauter en croisés — conditioning `ca-corde-croises`
  - Rameur en endurance — conditioning `ca-rameur-endurance`
- **jeudi** (60 min, estimé 58 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre jambes tendues — secondary `mu-souleve-de-terre-jambes-tendues`
  - Fente avant aux haltères — secondary `mu-fente-avant-halteres`
  - Pompe diamant — secondary `sw-pompe-diamant`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **vendredi** (60 min, estimé 59 min) — `strength.upper`
  - Marche latérale en appui renversé au mur — skill `cd-marche-laterale-mur`
  - Handstand libre — skill `cs-handstand`
  - Row australien aux anneaux — main `sw-row-australien-anneaux`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Élévation frontale haltères — accessory `mu-elevation-frontale-halteres`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Bear crawl — core `mu-bear-crawl`

Dosage : musculation 60 % (visé 60 %), streetWorkout 20 % (visé 20 %), cardio 20 % (visé 20 %) — erreur 0.5 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 9.5 [8-16], delt_anterior 13 [8-16], delt_middle 8.5 [8-16], delt_posterior 11 [8-16], lats 16 [8-16], upper_back 16 [8-16], biceps 10.5 [8-16], triceps 13 [8-16], abs 9 [8-16], lower_back 10.5 [8-16], glutes 15 [8-16], quads 9 [8-16], hamstrings 10.5 [8-16], calves 7.5 [8-16]. Groupes majeurs dans leur bande : 96 %.

Équilibre : tirage 19 / poussée 13 séries ; chaîne postérieure 9 / genou 9 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Rowing poulie basse assis au triangle (`d3.4`) :
  - `exercise_replaced` jour 3 : Rowing poulie basse assis au triangle → Rowing buste penché à la Smith machine (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Course sur tapis en endurance (`d2.6`) :
  - `exercise_replaced` jour 2 : Footing en endurance fondamentale → Course sur tapis en endurance (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre basse | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Soulevé de terre roumain à la barre | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Traction supination | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Face pull à la poulie corde | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Développé couché haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Extension nuque à l'haltère à deux mains | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Corde à sauter en croisés | 5×15-30 · 45s | 5×15-30 · 45s | 6×15-30 · 45s | 6×15-30 · 45s | 4×15-30 · 45s |
| Rameur en endurance | 18-20 min | 22-25 min | 22-25 min | 22-25 min | 13-15 min |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 52.5 kg | 3×6-10 · 5 fl. · 120s · 52.5 kg | 3×6-10 · 6 fl. · 120s · 52.5 kg | 3×6-10 · 7 fl. · 120s · 52.5 kg | 2×6-10 · 3 fl. · 120s · 50 kg |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Fente avant aux haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pompe diamant | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Leg curl couché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Course sur tapis en endurance | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Marche latérale en appui renversé au mur | 2×5 m · 4 fl. · 120s | 3×5 m · 4 fl. · 120s | 3×5 m · 5 fl. · 120s | 3×5 m · 6 fl. · 120s | 2×5 m · 2 fl. · 120s |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Row australien aux anneaux | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Rowing buste penché à la Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation frontale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Bear crawl | 2×20 m · 4 fl. · 60s | 3×20 m · 4 fl. · 60s | 3×20 m · 5 fl. · 60s | 3×20 m · 6 fl. · 60s | 2×20 m · 2 fl. · 60s |

