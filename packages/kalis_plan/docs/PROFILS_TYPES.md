# Profils types de kalis_plan

Fichier généré par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (kalis_plan 0.1.0, catalogue 1.1.0, règles 1.1.0) — ne pas modifier à la main ; `test/docs_test.dart` le compare au moteur.

Pour chacun des 40 profils des jeux de données de `kalis_core` : la passe 1 (exercices par séance), une revue simulée (« je ne sais pas faire » sur un exercice, puis remplacement d'un autre par sa variante équivalente), le diff, puis la passe 2 du programme revu. Notation d'une prescription : séries × plage · flammes visées · repos · charge de départ (ou part du 1RM visée).

## 1. `debutant_forme_generale_maison_2x30`

Débutant, forme générale, 2 × 30 min à la maison sans matériel.

Profil : general_fitness 100 % — mardi 30 min, vendredi 30 min — lieux maison — expérience beginner, 82 kg, né en 1994, male, santé standard.

### Passe 1

Note 0.947 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.84 · muscle_volume 0.86 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.87 · preferences 1.00 · novelty 1.00.

- **mardi** (30 min, estimé 29 min) — `strength.full_body`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Pompe classique — main `sw-pompe`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Bird dog — core `mu-bird-dog`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **vendredi** (30 min, estimé 30 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Pompe classique — secondary `sw-pompe`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Marche rapide — conditioning `ca-marche-rapide`

Dosage : cardio 19 % (visé 35 %), mobility 15 % (visé 15 %), generalFitness 66 % (visé 50 %) — erreur 16.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 5 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 5 [1.5-5], abs 4 [1.5-5], lower_back 4 [1.5-5], glutes 5 [1.5-5], quads 5 [1.5-5], hamstrings 3 [1.5-5], calves 3 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 5 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 3/3.

### Revue simulée

- « Je ne sais pas faire » sur Mountain climbers (`d0.6`) :
  - `exercise_replaced` jour 0 : Mountain climbers → Gainage latéral sur les genoux (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Gainage latéral bras tendu (`d1.3`) :
  - `exercise_replaced` jour 1 : Gainage latéral sur le coude → Gainage latéral bras tendu (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe classique | 2×2-3 · 3 fl. · 90s | 3×2-3 · 3 fl. · 90s | 3×2-3 · 4 fl. · 90s | 3×2-3 · 5 fl. · 90s |
| Nordic hamstring curl négatif | 2×8-12 · 5 fl. · 75s | 2×8-12 · 5 fl. · 75s | 2×8-12 · 6 fl. · 75s | 2×8-12 · 7 fl. · 75s |
| Bird dog | 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |
| Gainage latéral sur les genoux | 1×20-40 s · 3 fl. · 60s | 1×20-40 s · 3 fl. · 60s | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 5 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Air squat | 2×7-11 · 5 fl. · 90s | 3×7-11 · 5 fl. · 90s | 3×7-11 · 6 fl. · 90s | 3×7-11 · 7 fl. · 90s |
| Pompe classique | 2×2-3 · 3 fl. · 90s | 2×2-3 · 3 fl. · 90s | 2×2-3 · 4 fl. · 90s | 2×2-3 · 5 fl. · 90s |
| Gainage latéral bras tendu | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Marche rapide | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

## 2. `femme_45_musculation_salle_4x60`

Femme de 45 ans, musculation, 4 × 60 min en salle.

Profil : musculation 80 % + mobility 20 % — lundi 60 min, mardi 60 min, jeudi 60 min, samedi 60 min — lieux salle — 63 kg, né en 1981, female, santé standard.

### Passe 1

Note 0.971 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 1.00 · discipline_structure 0.99 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.73 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 58 min) — `strength.push`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Table inversée — warmup `mo-table-inversee`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Porté en rack kettlebell — accessory `mu-rack-carry`
  - Extension nuque à l'haltère à deux mains — accessory `mu-extension-nuque-haltere-deux-mains`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Pallof press debout — core `mu-pallof-press-debout`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **mardi** (60 min, estimé 57 min) — `strength.full_body`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Rowing menton à la poulie — accessory `mu-rowing-menton-poulie`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Planche RKC — core `mu-planche-rkc`
  - V-up — core `mu-v-up`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`
  - Sleeper stretch — cooldown `mo-sleeper-stretch`
- **jeudi** (60 min, estimé 60 min) — `strength.full_body`
  - Soulevé de terre conventionnel — main `mu-souleve-de-terre-conventionnel`
  - Fente marchée aux haltères — secondary `mu-fente-marchee-halteres`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Hip thrust à la barre — accessory `mu-hip-thrust-barre`
  - Y raise sur banc incliné — accessory `mu-y-raise-banc-incline`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Frog stretch (grenouille) — cooldown `mo-frog-stretch`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **samedi** (60 min, estimé 58 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Row australien — secondary `sw-row-australien`
  - Développé épaules à la Smith machine assis — secondary `mu-developpe-epaules-smith-assis`
  - Pont fessier pieds surélevés — accessory `mu-pont-fessier-pieds-sureleves`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Ouverture d'épaules en extension mains sur banc — cooldown `mo-ouverture-epaules-extension-banc`

Dosage : musculation 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 8.5 [8-16], delt_anterior 13 [8-16], delt_middle 9 [8-16], delt_posterior 10 [8-16], lats 11 [8-16], upper_back 14 [8-16], biceps 8.5 [8-16], triceps 11.5 [8-16], abs 15 [8-16], lower_back 8 [8-16], glutes 16 [8-16], quads 11.5 [8-16], hamstrings 9 [8-16], calves 5 [8-16]. Groupes majeurs dans leur bande : 96 %.

Équilibre : tirage 11 / poussée 9 séries ; chaîne postérieure 9 / genou 11 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Woodchop à la poulie haut vers bas (`d2.7`) :
  - `exercise_replaced` jour 2 : Woodchop à la poulie haut vers bas → Rotation du tronc à la poulie assis (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Développé couché haltères prise neutre (`d0.4`) :
  - `exercise_replaced` jour 0 : Développé couché haltères → Développé couché haltères prise neutre (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Table inversée | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Développé couché haltères prise neutre | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Porté en rack kettlebell | 2×30 m · 4 fl. · 90s | 3×30 m · 4 fl. · 90s | 3×30 m · 5 fl. · 90s | 3×30 m · 6 fl. · 90s | 2×30 m · 2 fl. · 90s |
| Extension nuque à l'haltère à deux mains | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Back squat barre haute | 3×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 5 fl. · 180s · 32.5 kg | 4×2-5 · 6 fl. · 180s · 35 kg | TEST 3×1-3 · 9 fl. · 240s [3@40 5fl. / 1@45 7fl. / 1@47.5 9fl.] |
| Rowing menton à la poulie | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| V-up | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Sleeper stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre conventionnel | 2×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 6 fl. · 120s · 42.5 kg | 3×6-10 · 7 fl. · 120s · 45 kg | 2×6-10 · 3 fl. · 120s · 42.5 kg |
| Fente marchée aux haltères | 2×20 m · 4 fl. · 90s | 3×20 m · 4 fl. · 90s | 3×20 m · 5 fl. · 90s | 3×20 m · 6 fl. · 90s | 2×20 m · 2 fl. · 90s |
| Rowing inversé à la Smith machine | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Hip thrust à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Rotation du tronc à la poulie assis | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Frog stretch (grenouille) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 4 fl. · 180s · 32.5 kg | 4×3-6 · 5 fl. · 180s · 32.5 kg | 4×2-5 · 6 fl. · 180s · 35 kg | 2×3-6 · 2 fl. · 180s · 32.5 kg |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 20 kg | 3×6-10 · 5 fl. · 120s · 20 kg | 3×6-10 · 6 fl. · 120s · 20 kg | 3×6-10 · 7 fl. · 120s · 20 kg | 2×6-10 · 3 fl. · 120s · 20 kg |
| Row australien | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Développé épaules à la Smith machine assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pont fessier pieds surélevés | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Ouverture d'épaules en extension mains sur banc | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 3. `coureur_cardio_3x45`

Coureur : cardio principal, mobilité et musculation en appoint, 3 × 45 min dehors.

Profil : cardio 70 % + musculation 20 % + mobility 10 % — mardi 45 min (maison), jeudi 45 min, dimanche 75 min (exterieur) — lieux exterieur, maison — expérience intermediate, 68 kg, né en 1988, male, santé standard.

### Passe 1

Note 0.928 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.92 · muscle_volume 0.63 · pattern_balance 0.93 · discipline_structure 0.95 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.90 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `strength.full_body`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Air squat — main `mu-air-squat`
  - Nordic hamstring curl assisté à l'élastique — accessory `mu-nordic-hamstring-curl-assiste`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **jeudi** (45 min, estimé 44 min) — `cardio.endurance`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **dimanche** (75 min, estimé 71 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Pompe pike — main `sw-pompe-pike`
  - Bird dog — core `mu-bird-dog`

Dosage : musculation 27 % (visé 20 %), cardio 63 % (visé 70 %), mobility 9 % (visé 10 %) — erreur 7.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [2-5], delt_anterior 3 [2-5], delt_middle 1.5 [2-5], delt_posterior 1.5 [2-5], lats 3 [2-5], upper_back 3 [2-5], biceps 0 [2-5], triceps 4.5 [2-5], abs 3 [2-5], lower_back 5 [2-5], glutes 5 [2-5], quads 3 [2-5], hamstrings 3 [2-5], calves 3 [0-5]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 4/5.

### Revue simulée

- « Je ne sais pas faire » sur Tirage bras tendus à l'élastique (`d0.4`) :
  - `exercise_replaced` jour 0 : Tirage bras tendus à l'élastique → Face pull à l'élastique (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Demi-grand écart (half split) (`d0.6`) :
  - `exercise_replaced` jour 0 : Étirement chaîne postérieure en flexion avant debout → Demi-grand écart (half split) (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Air squat | 2×15-22 · 5 fl. · 90s | 3×15-22 · 5 fl. · 90s | 3×15-22 · 6 fl. · 90s | 3×15-22 · 7 fl. · 90s | 2×15-22 · 3 fl. · 90s |
| Nordic hamstring curl assisté à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Demi-grand écart (half split) | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Footing en endurance fondamentale | 27-30 min | 31-35 min | 36-40 min | 36-40 min | TEST 1×10000 m |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 40-45 min | 49-55 min | 49-55 min | 54-60 min | 31-35 min |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| Bird dog | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |

## 4. `crossfit_5x60`

CrossFit, 5 × 60 min en box.

Profil : crossfit 80 % + mobility 20 % — lundi 60 min, mardi 60 min, mercredi 60 min, vendredi 60 min, samedi 60 min — lieux salle — 66 kg, né en 1996, female, santé standard.

### Passe 1

Note 0.958 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.90 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 0.73 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 58 min) — `strength.upper`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Épaulé-jeté — main `mu-epaule-jete`
  - HSPU au mur amplitude réduite sur coussin — secondary `cd-hspu-mur-amplitude-reduite`
  - Traction pronation — secondary `sw-traction-pronation`
  - Traction kipping — conditioning `cf-traction-kipping`
  - Demi-burpee — conditioning `cf-demi-burpee`
  - Sit-up AbMat en papillon — conditioning `cf-sit-up-abmat`
- **mardi** (60 min, estimé 55 min) — `mobility`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Hollow body hold — core `mu-hollow-body-hold`
  - Planche RKC — core `mu-planche-rkc`
  - Burpee Navy SEAL — conditioning `cf-burpee-navy-seal`
  - Rameur en sprint — conditioning `ca-rameur-sprint`
  - Étirement adducteurs debout en fente latérale — cooldown `mo-adducteurs-fente-laterale`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **mercredi** (60 min, estimé 60 min) — `strength.push`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Soulevé de terre kettlebell — main `mu-souleve-de-terre-kettlebell`
  - Pompe prise large — secondary `sw-pompe-large`
  - Burpee avec tuck jump — conditioning `cf-burpee-tuck-jump`
  - Wall ball — conditioning `cf-wall-ball`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **vendredi** (60 min, estimé 56 min) — `strength.lower`
  - Épaulé haltère unilatéral — main `mu-epaule-haltere-unilateral`
  - Back squat barre haute — secondary `mu-back-squat-barre-haute`
  - V-up — core `mu-v-up`
  - Fente marchée overhead au disque — conditioning `cf-fente-overhead-disque`
  - Box step-over — conditioning `cf-box-step-over`
  - Burpee — conditioning `cf-burpee`
  - Étirement de l'élévateur de la scapula — cooldown `mo-etirement-elevateur-scapula`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **samedi** (60 min, estimé 60 min) — `strength.pull`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Rowing barre buste penché prise supination — main `mu-rowing-barre-supination`
  - Porté au-dessus de la tête (overhead carry) — accessory `mu-overhead-carry`
  - Gainage ventral lesté — core `mu-gainage-ventral-leste`
  - Burpee avec traction — conditioning `cf-burpee-traction`
  - Thruster à la barre — conditioning `cf-thruster-barre`
  - Saut en étoile — conditioning `cf-saut-etoile`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`

Dosage : crossfit 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 11 [7.5-15.5], delt_anterior 15 [7.5-15.5], delt_middle 7.5 [7.5-15.5], delt_posterior 4 [7.5-15.5], lats 14 [7.5-15.5], upper_back 8.5 [7.5-15.5], biceps 8.5 [7.5-15.5], triceps 15 [7.5-15.5], abs 13.5 [7.5-15.5], lower_back 7.5 [7.5-15.5], glutes 15 [7.5-15.5], quads 13.5 [7.5-15.5], hamstrings 9 [7.5-15.5], calves 7.5 [7.5-15.5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 14 / poussée 12 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Mobilisation cheville genou au mur (`d2.2`) :
  - `exercise_replaced` jour 2 : Mobilisation cheville genou au mur → CARs de cheville (plan.user_cannot_do, plan.variant_easier)
  - `exercise_removed` jour 4 : Mobilisation cheville genou au mur (plan.reoptimized)
- Remplacement par Hollow rocks (`d1.2`) :
  - `exercise_replaced` jour 1 : Hollow body hold → Hollow rocks (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Épaulé-jeté | 4×2-3 · 3 fl. · 150s · 40 kg | 5×2-3 · 3 fl. · 150s · 40 kg | 5×2-3 · 4 fl. · 150s · 40 kg | 5×2-3 · 5 fl. · 150s · 40 kg | 3×2-3 · 1 fl. · 150s · 37.5 kg |
| HSPU au mur amplitude réduite sur coussin | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 3×3-4 · 5 fl. · 90s | 4×3-4 · 5 fl. · 90s | 4×3-4 · 6 fl. · 90s | 4×3-4 · 7 fl. · 90s | 2×3-4 · 3 fl. · 90s |
| Traction kipping | 3×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 2×8-12 · 15s · rounds wod-d0 |
| Demi-burpee | 3×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 2×8-12 · 15s · rounds wod-d0 |
| Sit-up AbMat en papillon | 3×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 4×8-12 · 15s · rounds wod-d0 | 2×8-12 · 15s · rounds wod-d0 |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Hollow rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Burpee Navy SEAL | 3×8-12 · 15s | 4×8-12 · 15s | 4×8-12 · 15s | 4×8-12 · 15s | 2×8-12 · 15s |
| Rameur en sprint | 4×15-20 s · 100s | 5×15-20 s · 100s | 5×15-20 s · 100s | 5×15-20 s · 100s | 3×15-20 s · 100s |
| Étirement adducteurs debout en fente latérale | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement du biceps au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement pectoral au cadre de porte | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Respiration crocodile | 2×120-180 s · 15s | 2×120-180 s · 15s | 2×120-180 s · 15s | 2×120-180 s · 15s | 1×120-180 s · 15s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| CARs de cheville | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Soulevé de terre kettlebell | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Pompe prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Burpee avec tuck jump | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |
| Wall ball | 3×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 4×8-12 · 15s · rounds wod-d2 | 2×8-12 · 15s · rounds wod-d2 |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement pectoral au cadre de porte | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Épaulé haltère unilatéral | CALIBRAGE 4×2-3 · 3 fl. · 150s · 81 % 1RM | 5×2-3 · 3 fl. · 150s · 81 % 1RM | 5×2-3 · 4 fl. · 150s · 82 % 1RM | 5×2-3 · 5 fl. · 150s · 83 % 1RM | 3×2-3 · 1 fl. · 150s · 79 % 1RM |
| Back squat barre haute | 2×5-8 · 4 fl. · 150s · 50 kg | 3×5-8 · 4 fl. · 150s · 50 kg | 3×5-8 · 5 fl. · 150s · 52.5 kg | 3×5-8 · 6 fl. · 150s · 52.5 kg | 2×5-8 · 2 fl. · 150s · 50 kg |
| V-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Fente marchée overhead au disque | 3×20 m · 15s · rounds wod-d3 | 4×20 m · 15s · rounds wod-d3 | 4×20 m · 15s · rounds wod-d3 | 4×20 m · 15s · rounds wod-d3 | 2×20 m · 15s · rounds wod-d3 |
| Box step-over | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Burpee | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Étirement de l'élévateur de la scapula | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Rowing barre buste penché prise supination | CALIBRAGE 3×5-8 · 4 fl. · 150s · 72 % 1RM | 4×5-8 · 4 fl. · 150s · 72 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Porté au-dessus de la tête (overhead carry) | 2×30 m · 5 fl. · 90s | 3×30 m · 5 fl. · 90s | 3×30 m · 6 fl. · 90s | 3×30 m · 7 fl. · 90s | 2×30 m · 3 fl. · 90s |
| Gainage ventral lesté | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Burpee avec traction | 3×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 2×8-12 · 15s · rounds wod-d4 |
| Thruster à la barre | 3×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 4×8-12 · 15s · rounds wod-d4 | 2×8-12 · 15s · rounds wod-d4 |
| Saut en étoile | 4×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 5×8-12 · 15s · rounds wod-d4 | 3×8-12 · 15s · rounds wod-d4 |
| Étirement pectoral au cadre de porte | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 5. `calisthenie_figures_4x75`

Calisthénie orientée figures (front lever, planche), 4 × 75 min au parc.

Profil : calisthenics 80 % + mobility 20 % — lundi 75 min, mercredi 75 min, vendredi 75 min, samedi 75 min — lieux exterieur, maison — 70 kg, né en 1999, male, santé standard.

### Passe 1

Note 0.952 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.92 · pattern_balance 0.93 · discipline_structure 0.88 · time_use 0.98 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (75 min, estimé 71 min) — `skills`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Handstand libre — skill `cs-handstand`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Shrimp squat débutant (genou et pointe au sol) — main `sw-shrimp-squat-bras-libres`
  - Skater squat — secondary `sw-skater-squat`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
  - Pancake assis — cooldown `mo-pancake-assis`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **mercredi** (75 min, estimé 68 min) — `skills`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Planche tuck — skill `cs-planche-tuck`
  - Ice cream maker tuck — skill `cd-ice-cream-maker-tuck`
  - Handstand libre — skill `cs-handstand`
  - Traction explosive poitrine à la barre — main `cd-traction-explosive-poitrine-barre`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **vendredi** (75 min, estimé 67 min) — `skills`
  - Planche tuck — skill `cs-planche-tuck`
  - Handstand libre — skill `cs-handstand`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Dips aux barres parallèles — main `sw-dips-barres-paralleles`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Étirement adducteurs debout en fente latérale — cooldown `mo-adducteurs-fente-laterale`
  - Étirement fessier en figure 4 allongé — cooldown `mo-figure-4-allonge`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **samedi** (75 min, estimé 71 min) — `strength.full_body`
  - CARs de hanche — warmup `mo-cars-hanche`
  - Front lever tuck avancé — skill `cs-front-lever-tuck-avance`
  - Traction pronation — main `sw-traction-pronation`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Hip airplane — accessory `mu-hip-airplane`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Pancake assis — cooldown `mo-pancake-assis`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : calisthenics 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 16 [8-16], delt_anterior 16 [8-16], delt_middle 7 [8-16], delt_posterior 13 [8-16], lats 19 [8-16], upper_back 16 [8-16], biceps 8 [8-16], triceps 16 [8-16], abs 14.5 [8-16], lower_back 8 [8-16], glutes 13 [8-16], quads 11 [8-16], hamstrings 8 [8-16], calves 3 [0-16]. Groupes majeurs dans leur bande : 84 %.

Équilibre : tirage 25 / poussée 25 séries ; chaîne postérieure 6 / genou 7 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement fessier en figure 4 allongé (`d2.8`) :
  - `exercise_replaced` jour 2 : Étirement fessier en figure 4 allongé → Mobilité hanches 90/90 passive (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par Straddle en appui au mur (`d2.7`) :
  - `exercise_replaced` jour 2 : Étirement adducteurs debout en fente latérale → Straddle en appui au mur (plan.user_replaced)
  - `order_changed` jour 2 (plan.reoptimized)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | TEST 2×1-12 s · 10 fl. · 180s |
| Handstand libre | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Shrimp squat débutant (genou et pointe au sol) | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Skater squat | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pancake assis | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | 2×4-6 s · 2 fl. · 120s |
| Planche tuck | 4×5-7 s · 4 fl. · 120s | 5×5-7 s · 4 fl. · 120s | 5×5-7 s · 5 fl. · 120s | 5×5-7 s · 6 fl. · 120s | TEST 2×1-14 s · 10 fl. · 180s |
| Ice cream maker tuck | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Handstand libre | 4×7-11 s · 4 fl. · 120s | 5×7-11 s · 4 fl. · 120s | 5×7-11 s · 5 fl. · 120s | 5×7-11 s · 6 fl. · 120s | 3×7-11 s · 2 fl. · 120s |
| Traction explosive poitrine à la barre | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Planche tuck | 4×5-7 s · 4 fl. · 120s | 5×5-7 s · 4 fl. · 120s | 5×5-7 s · 5 fl. · 120s | 5×5-7 s · 6 fl. · 120s | 3×5-7 s · 2 fl. · 120s |
| Handstand libre | 4×7-11 s · 4 fl. · 120s | 5×7-11 s · 4 fl. · 120s | 5×7-11 s · 5 fl. · 120s | 5×7-11 s · 6 fl. · 120s | 3×7-11 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Dips aux barres parallèles | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pike assis passif | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Straddle en appui au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| CARs de hanche | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Front lever tuck avancé | 3×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 5 fl. · 120s | 4×4-6 s · 6 fl. · 120s | 2×4-6 s · 2 fl. · 120s |
| Traction pronation | 2×7-10 · 5 fl. · 90s | 3×7-10 · 5 fl. · 90s | 3×7-10 · 6 fl. · 90s | 3×7-10 · 7 fl. · 90s | 2×7-10 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Nordic hamstring curl négatif | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 3×20-40 s · 4 fl. · 60s | 4×20-40 s · 4 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Pancake assis | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pike assis passif | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 6. `street_streetlifting_4x90`

Mode street, principale streetlifting (60/25/15), 4 × 90 min.

Profil : streetlifting 60 % + street_workout 25 % + calisthenics 15 % — lundi 90 min, mardi 90 min, jeudi 90 min, samedi 90 min — lieux salle, exterieur — mode street, 78 kg, né en 1997, male, santé standard.

### Passe 1

Note 0.951 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 0.98 · discipline_dosage 0.92 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.93 · time_use 0.99 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.60 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 87 min) — `strength.push`
  - Elbow lever un bras — skill `cs-elbow-lever-un-bras`
  - Dips lesté de compétition — main `sl-dips-leste`
  - Dips aux anneaux — secondary `sw-dips-anneaux`
  - Pronation au levier — accessory `mu-pronation-levier`
  - Shrug barre — accessory `mu-shrug-barre`
  - Dead hang — accessory `sw-dead-hang`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mardi** (90 min, estimé 89 min) — `strength.full_body`
  - Squat de compétition — main `sl-squat-competition`
  - Traction lestée de compétition — main `sl-traction-lestee`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Élévation latérale à la poulie câble derrière le dos — accessory `mu-elevation-laterale-poulie-derriere-dos`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Pompe scapulaire — accessory `sw-pompe-scapulaire`
  - Knees-to-elbows — core `sw-knees-to-elbows`
- **jeudi** (90 min, estimé 84 min) — `strength.pull`
  - Tenue menton au-dessus de la barre un bras — skill `cs-tenue-menton-barre-un-bras`
  - Squat de compétition — main `sl-squat-competition`
  - Muscle-up lesté de compétition — main `sl-muscle-up-leste`
  - Isométrie lestée en haut de traction — accessory `sl-traction-isometrie-lestee-haute`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Arch rocks — core `mu-arch-rocks`
  - Planche RKC — core `mu-planche-rkc`
- **samedi** (90 min, estimé 83 min) — `strength.upper`
  - L-sit aux barres parallèles — skill `cs-l-sit-barres-paralleles`
  - Traction lestée de compétition — main `sl-traction-lestee`
  - Dips sur barre fixe lesté — secondary `sl-dips-barre-fixe-leste`
  - Traction pronation — secondary `sw-traction-pronation`
  - Soulevé de terre prise arraché — secondary `mu-souleve-de-terre-prise-arrache`
  - HSPU au mur dos au mur — secondary `cd-hspu-mur-dos`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`

Dosage : streetWorkout 20 % (visé 25 %), streetlifting 65 % (visé 60 %), calisthenics 15 % (visé 15 %) — erreur 5.3 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 19 [12-20], delt_anterior 19.5 [12-20], delt_middle 12 [12-20], delt_posterior 11.5 [12-20], lats 20 [12-20], upper_back 20 [12-20], biceps 19 [12-20], triceps 20 [12-20], abs 23 [12-20], lower_back 12.5 [12-20], glutes 15.5 [12-20], quads 20 [12-20], hamstrings 11 [12-20], calves 3 [0-20]. Groupes majeurs dans leur bande : 78 %.

Équilibre : tirage 25.5 / poussée 23.5 séries ; chaîne postérieure 8 / genou 10 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Squat de compétition (`d1.1`) :
  - `exercise_replaced` jour 1 : Squat de compétition → Pin squat (squat depuis les sécurités) (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
  - `exercise_added` jour 2 → Box squat à profondeur de compétition (plan.reoptimized)
  - `exercise_removed` jour 2 : Squat de compétition (plan.reoptimized)
- Remplacement par Soulevé de terre en déficit (`d3.5`) :
  - `exercise_replaced` jour 3 : Soulevé de terre prise arraché → Soulevé de terre en déficit (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Elbow lever un bras | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| Dips lesté de compétition | 4×3-6 · 5 fl. · 180s · 7.5 kg | 4×3-6 · 5 fl. · 180s · 7.5 kg | 5×3-6 · 5 fl. · 180s · 7.5 kg | 5×3-6 · 6 fl. · 180s · 8.75 kg | 5×2-5 · 7 fl. · 180s · 12.5 kg | 3×3-6 · 3 fl. · 180s · 5 kg |
| Dips aux anneaux | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pronation au levier | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Shrug barre | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Dead hang | 3×20-40 s · 5 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 6 fl. · 60s | 4×20-40 s · 7 fl. · 60s | 2×20-40 s · 3 fl. · 60s |
| Relevé de genoux oblique suspendu | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction lestée de compétition | 4×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 6 fl. · 180s · 0 kg | 5×2-5 · 7 fl. · 180s · 1.25 kg | TEST 3×1-3 · 9 fl. · 240s [3@8.75 5fl. / 1@18.75 7fl. / 1@25 9fl.] |
| Pin squat (squat depuis les sécurités) | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Soulevé de terre conventionnel | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Élévation latérale à la poulie câble derrière le dos | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Curl biceps à la barre droite | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Pompe scapulaire | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Knees-to-elbows | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Tenue menton au-dessus de la barre un bras | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 6×5-10 s · 4 fl. · 120s | 6×5-10 s · 5 fl. · 120s | 6×5-10 s · 6 fl. · 120s | 4×5-10 s · 2 fl. · 120s |
| Muscle-up lesté de compétition | CALIBRAGE 5×3-6 · 5 fl. · 180s · 77 % 1RM | 5×3-6 · 5 fl. · 180s · 77 % 1RM | 6×3-6 · 5 fl. · 180s · 77 % 1RM | 6×3-6 · 6 fl. · 180s · 78 % 1RM | 6×2-5 · 7 fl. · 180s · 81 % 1RM | 4×3-6 · 3 fl. · 180s · 75 % 1RM |
| Box squat à profondeur de compétition | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Isométrie lestée en haut de traction | 2×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 3×5-12 s · 7 fl. · 60s | 2×5-12 s · 3 fl. · 60s |
| Élévation latérale haltères | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| L-sit aux barres parallèles | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Traction lestée de compétition | 4×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 5 fl. · 180s · 0 kg | 5×3-6 · 6 fl. · 180s · 0 kg | 5×2-5 · 7 fl. · 180s · 1.25 kg | 3×3-6 · 3 fl. · 180s · 0 kg |
| Dips sur barre fixe lesté | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 7 fl. · 150s · 75 % 1RM | 1×5-8 · 3 fl. · 150s · 71 % 1RM |
| Traction pronation | 3×7-11 · 5 fl. · 90s | 4×7-11 · 5 fl. · 90s | 4×7-11 · 5 fl. · 90s | 4×7-11 · 6 fl. · 90s | 4×7-11 · 7 fl. · 90s | 2×7-11 · 3 fl. · 90s |
| Soulevé de terre en déficit | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| HSPU au mur dos au mur | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 7. `street_sets_reps_4x60`

Mode street, principale sets & reps (20/60/20), 4 × 60 min au parc.

Profil : street_workout 60 % + streetlifting 20 % + calisthenics 20 % — lundi 60 min, mercredi 60 min, vendredi 60 min, dimanche 60 min — lieux exterieur — mode street, 65 kg, né en 2001, male, santé standard.

### Passe 1

Note 0.953 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.97 · muscle_volume 0.93 · pattern_balance 0.99 · discipline_structure 0.93 · time_use 1.00 · variety 0.94 · exercise_fit 0.66 · stimulus_fatigue 0.76 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Traction pronation — main `sw-traction-pronation`
  - Shrimp squat débutant (genou et pointe au sol) — secondary `sw-shrimp-squat-bras-libres`
  - Skater squat — secondary `sw-skater-squat`
  - Hip airplane — accessory `mu-hip-airplane`
  - Arch rocks — core `mu-arch-rocks`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mercredi** (60 min, estimé 60 min) — `strength.upper`
  - Muscle-up barre strict — skill `cd-muscle-up-barre-strict`
  - Traction archer — main `sw-traction-archer`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`
- **vendredi** (60 min, estimé 59 min) — `strength.upper`
  - Traction pronation — main `sw-traction-pronation`
  - Pistol squat négatif — secondary `sw-pistol-squat-negatif`
  - HSPU au mur dos au mur — secondary `cd-hspu-mur-dos`
  - Pompe classique — secondary `sw-pompe`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Relevé de genoux suspendu — core `sw-releve-genoux-suspendu`
- **dimanche** (60 min, estimé 59 min) — `strength.upper`
  - Back lever — skill `cs-back-lever`
  - Handstand libre — skill `cs-handstand`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Pompe sphinx — accessory `sw-pompe-sphinx`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
  - Knees-to-elbows — core `sw-knees-to-elbows`

Dosage : streetWorkout 60 % (visé 60 %), streetlifting 19 % (visé 20 %), calisthenics 22 % (visé 20 %) — erreur 1.6 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 20 [12-20], delt_anterior 19.5 [12-20], delt_middle 7 [12-20], delt_posterior 6.5 [12-20], lats 17.5 [12-20], upper_back 15 [12-20], biceps 13.5 [12-20], triceps 19.5 [12-20], abs 20 [12-20], lower_back 6 [12-20], glutes 13 [12-20], quads 14 [12-20], hamstrings 11.5 [12-20], calves 7 [0-20]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 20.5 / poussée 19.5 séries ; chaîne postérieure 8 / genou 10 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Muscle-up barre strict (`d1.1`) :
  - `exercise_replaced` jour 1 : Muscle-up barre strict → Tour d'appui arrière (plan.user_cannot_do, plan.variant_easier)
- Remplacement par HSPU au mur ventre face au mur (`d2.3`) :
  - `exercise_replaced` jour 2 : HSPU au mur dos au mur → HSPU au mur ventre face au mur (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction pronation | 4×9-13 · 5 fl. · 90s | 4×9-13 · 5 fl. · 90s | 5×9-13 · 5 fl. · 90s | 5×9-13 · 6 fl. · 90s | 5×9-13 · 7 fl. · 90s | TEST 1×1-30 · 10 fl. · 180s |
| Shrimp squat débutant (genou et pointe au sol) | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Skater squat | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch rocks | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Tour d'appui arrière | 2×2-5 · 4 fl. · 150s | 3×2-5 · 4 fl. · 150s | 3×2-5 · 4 fl. · 150s | 3×2-5 · 5 fl. · 150s | 3×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Traction archer | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 5×6-12 · 5 fl. · 90s | 5×6-12 · 6 fl. · 90s | 5×6-12 · 7 fl. · 90s | 3×6-12 · 3 fl. · 90s |
| Dips aux barres parallèles | 3×15-22 · 5 fl. · 90s | 4×15-22 · 5 fl. · 90s | 4×15-22 · 5 fl. · 90s | 4×15-22 · 6 fl. · 90s | 4×15-22 · 7 fl. · 90s | 2×15-22 · 3 fl. · 90s |
| Nordic hamstring curl négatif | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de genoux oblique suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction pronation | 3×9-13 · 5 fl. · 90s | 4×9-13 · 5 fl. · 90s | 4×9-13 · 5 fl. · 90s | 4×9-13 · 6 fl. · 90s | 4×9-13 · 7 fl. · 90s | 2×9-13 · 3 fl. · 90s |
| Pistol squat négatif | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| HSPU au mur ventre face au mur | 4×3-8 · 5 fl. · 90s | 4×3-8 · 5 fl. · 90s | 5×3-8 · 5 fl. · 90s | 5×3-8 · 6 fl. · 90s | 5×3-8 · 7 fl. · 90s | 3×3-8 · 3 fl. · 90s |
| Pompe classique | 3×22-30 · 5 fl. · 90s | 4×22-30 · 5 fl. · 90s | 4×22-30 · 5 fl. · 90s | 4×22-30 · 6 fl. · 90s | 4×22-30 · 7 fl. · 90s | 2×22-30 · 3 fl. · 90s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de genoux suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Back lever | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| Handstand libre | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 5×10-20 s · 4 fl. · 120s | 5×10-20 s · 5 fl. · 120s | 5×10-20 s · 6 fl. · 120s | 3×10-20 s · 2 fl. · 120s |
| Nordic hamstring curl négatif | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pompe sphinx | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Knees-to-elbows | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 8. `street_calisthenie_5x60`

Mode street, principale calisthénie (0/40/60), 5 × 60 min.

Profil : calisthenics 60 % + street_workout 40 % — lundi 60 min, mardi 60 min, jeudi 60 min, vendredi 60 min, dimanche 60 min — lieux exterieur, maison — mode street, 54 kg, né en 1998, female, santé standard.

### Passe 1

Note 0.958 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.90 · time_use 0.97 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.83 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 50 min) — `strength.lower`
  - L-sit au sol — skill `cs-l-sit-sol`
  - Compression pike assis — skill `cs-compression-pike`
  - Skater squat — main `sw-skater-squat`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **mardi** (60 min, estimé 50 min) — `skills`
  - Handstand dos au mur — skill `cs-handstand-dos-au-mur`
  - Muscle-up sauté — skill `cd-muscle-up-saute`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`
- **jeudi** (60 min, estimé 50 min) — `skills`
  - Muscle-up barre basse pieds au sol — skill `cd-muscle-up-barre-basse-pieds-au-sol`
  - Tenue menton au-dessus de la barre supination — skill `cs-tenue-menton-barre-supination`
  - Compression pike assis — skill `cs-compression-pike`
  - Traction pronation — main `sw-traction-pronation`
  - Reverse nordic — accessory `mu-reverse-nordic`
- **vendredi** (60 min, estimé 51 min) — `strength.upper`
  - Handstand libre — skill `cs-handstand`
  - Row australien prise large — main `sw-row-australien-large`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Hip airplane — accessory `mu-hip-airplane`
  - Dead hang — accessory `sw-dead-hang`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
- **dimanche** (60 min, estimé 50 min) — `skills`
  - Handstand libre — skill `cs-handstand`
  - Muscle-up barre basse pieds au sol — skill `cd-muscle-up-barre-basse-pieds-au-sol`
  - German hang — skill `cs-german-hang`
  - Pompe pseudo-planche — main `cd-pompe-pseudo-planche`
  - Pompe hindoue — secondary `sw-pompe-hindu`

Dosage : streetWorkout 42 % (visé 40 %), calisthenics 58 % (visé 60 %) — erreur 1.8 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 15.5 [8-16], delt_anterior 17 [8-16], delt_middle 7.5 [8-16], delt_posterior 9.5 [8-16], lats 15.5 [8-16], upper_back 13.5 [8-16], biceps 15 [8-16], triceps 16 [8-16], abs 15 [8-16], lower_back 7.5 [8-16], glutes 15 [8-16], quads 15 [8-16], hamstrings 6 [8-16], calves 1 [0-16]. Groupes majeurs dans leur bande : 76 %.

Équilibre : tirage 24 / poussée 24 séries ; chaîne postérieure 6 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Pont fessier au sol (`d3.3`) :
  - `exercise_removed` jour 0 : Pont fessier unilatéral (plan.reoptimized)
  - `exercise_replaced` jour 3 : Pont fessier au sol → Nordic hamstring curl assisté à l'élastique (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par Tenue menton au-dessus de la barre pronation (`d2.2`) :
  - `exercise_replaced` jour 2 : Tenue menton au-dessus de la barre supination → Tenue menton au-dessus de la barre pronation (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| L-sit au sol | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Compression pike assis | 4×10-20 s · 4 fl. · 120s | 5×10-20 s · 4 fl. · 120s | 5×10-20 s · 5 fl. · 120s | 5×10-20 s · 6 fl. · 120s | 3×10-20 s · 2 fl. · 120s |
| Skater squat | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Gainage latéral sur le coude | 3×20-40 s · 4 fl. · 60s | 4×20-40 s · 4 fl. · 60s | 4×20-40 s · 5 fl. · 60s | 4×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand dos au mur | 3×15-22 s · 4 fl. · 120s | 4×15-22 s · 4 fl. · 120s | 4×15-22 s · 5 fl. · 120s | 4×15-22 s · 6 fl. · 120s | 2×15-22 s · 2 fl. · 120s |
| Muscle-up sauté | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Tenue menton au-dessus de la barre supination | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Face pull à l'élastique | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage ventral sur les coudes | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Muscle-up barre basse pieds au sol | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Tenue menton au-dessus de la barre pronation | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Compression pike assis | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Traction pronation | 2×3-4 · 5 fl. · 90s | 3×3-4 · 5 fl. · 90s | 3×3-4 · 6 fl. · 90s | 3×3-4 · 7 fl. · 90s | 2×3-4 · 3 fl. · 90s |
| Reverse nordic | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | TEST 2×1-30 s · 10 fl. · 180s |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Nordic hamstring curl assisté à l'élastique | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Dead hang | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Gainage latéral avec relevés de hanche | 2×8-12 · 4 fl. · 60s | 2×8-12 · 4 fl. · 60s | 2×8-12 · 5 fl. · 60s | 2×8-12 · 6 fl. · 60s | 1×8-12 · 2 fl. · 60s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Muscle-up barre basse pieds au sol | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| German hang | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Pompe pseudo-planche | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe hindoue | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |

## 9. `blessure_epaule_musculation_3x60`

Musculation avec une blessure d'épaule droite (gêne 6/10).

Profil : musculation 100 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 88 kg, né en 1985, male, santé standard, shoulder gêne 6/10.

### Passe 1

Note 0.967 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.94 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.74 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre jambes tendues — secondary `mu-souleve-de-terre-jambes-tendues`
  - Pompe classique — secondary `sw-pompe`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Pushdown à la corde — accessory `mu-pushdown-corde`
  - T raise sur banc incliné — accessory `mu-t-raise-banc-incline`
- **mercredi** (60 min, estimé 59 min) — `strength.full_body`
  - Soulevé de terre conventionnel — main `mu-souleve-de-terre-conventionnel`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Tirage vertical poulie prise serrée supination — secondary `mu-tirage-vertical-prise-serree-supination`
  - Curl biceps à la poulie basse (barre) — accessory `mu-curl-poulie-basse-barre`
  - Y raise sur banc incliné — accessory `mu-y-raise-banc-incline`
  - Traction scapulaire — accessory `sw-traction-scapulaire`
  - Pallof press debout — core `mu-pallof-press-debout`
- **vendredi** (60 min, estimé 59 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Belt squat — secondary `mu-belt-squat`
  - Row australien — secondary `sw-row-australien`
  - Halo kettlebell — accessory `mu-halo-kettlebell`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`
  - Sit-up — core `mu-sit-up`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [8-16], delt_anterior 10.5 [8-16], delt_middle 8 [8-16], delt_posterior 10 [8-16], lats 9 [8-16], upper_back 16 [8-16], biceps 13.5 [8-16], triceps 10.5 [8-16], abs 9 [8-16], lower_back 12 [8-16], glutes 15 [8-16], quads 12 [8-16], hamstrings 9 [8-16], calves 7.5 [8-16]. Groupes majeurs dans leur bande : 87 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 9 / genou 9 ; schémas de base 5/5.

### Revue simulée

- « Je ne sais pas faire » sur Pompe classique (`d0.3`) :
  - `exercise_replaced` jour 0 : Pompe classique → Presse pectorale convergente assise (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Heel touch (`d2.6`) :
  - `exercise_replaced` jour 2 : Flexion latérale à l'haltère → Heel touch (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 6 fl. · 120s · 67.5 kg | 3×6-10 · 7 fl. · 120s · 70 kg | 2×6-10 · 3 fl. · 120s · 67.5 kg |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Presse pectorale convergente assise | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Curl biceps à la barre droite | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pushdown à la corde | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| T raise sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 5 fl. · 120s · 50 kg | 3×6-10 · 6 fl. · 120s · 50 kg | 3×6-10 · 7 fl. · 120s · 50 kg | 2×6-10 · 3 fl. · 120s · 47.5 kg |
| Tirage vertical poulie prise serrée supination | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Curl biceps à la poulie basse (barre) | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Traction scapulaire | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 5 fl. · 120s · 67.5 kg | 3×6-10 · 6 fl. · 120s · 67.5 kg | 3×6-10 · 7 fl. · 120s · 70 kg | 2×6-10 · 3 fl. · 120s · 67.5 kg |
| Belt squat | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Halo kettlebell | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Leg curl couché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Heel touch | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Sit-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 10. `minimal_1x20`

Une seule séance de 20 min par semaine, à la maison.

Profil : general_fitness 100 % — mercredi 20 min — lieux maison — né en 1990, undisclosed, santé standard.

### Passe 1

Note 0.917 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.65 · muscle_volume 1.00 · pattern_balance 0.86 · discipline_structure 0.88 · time_use 1.00 · variety 1.00 · exercise_fit 0.58 · stimulus_fatigue 0.89 · preferences 1.00 · novelty 1.00.

- **mercredi** (20 min, estimé 20 min) — `strength.full_body`
  - Cercles de bras — warmup `mo-cercles-bras`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Pompe classique — main `sw-pompe`
  - Chaise contre le mur — accessory `mu-wall-sit`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : cardio 0 % (visé 35 %), mobility 38 % (visé 15 %), generalFitness 62 % (visé 50 %) — erreur 35.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 2 [0.5-5], delt_anterior 2 [0.5-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 2 [0.5-5], abs 2 [0.5-5], lower_back 2 [0.5-5], glutes 0.5 [0.5-5], quads 1 [0.5-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 2 séries ; chaîne postérieure 0 / genou 1 ; schémas de base 2/3.

### Revue simulée

- « Je ne sais pas faire » sur Wall slides dos au mur (`d0.2`) :
  - `exercise_replaced` jour 0 : Wall slides dos au mur → CARs d'épaule (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
- Remplacement par Étirement fessier en figure 4 allongé (`d0.6`) :
  - `exercise_replaced` jour 0 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)

### Passe 2

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| CARs d'épaule | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s |
| Cercles de bras | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe classique | 2×6-12 · 3 fl. · 90s | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s |
| Chaise contre le mur | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 4 fl. · 60s | 1×5-12 s · 5 fl. · 60s |
| Gainage latéral sur le coude | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 11. `six_jours_musculation_avance_6x75`

Musculation avancée, 6 × 75 min en salle.

Profil : musculation 100 % — lundi 75 min, mardi 75 min, mercredi 75 min, jeudi 75 min, vendredi 75 min, samedi 75 min — lieux salle — expérience advanced, 90 kg, né en 1993, male, santé standard.

### Passe 1

Note 0.967 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 0.96 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.69 · preferences 1.00 · novelty 1.00.

- **lundi** (75 min, estimé 62 min) — `strength.full_body`
  - Développé décliné Smith machine — main `mu-developpe-decline-smith`
  - Développé couché haltères — secondary `mu-developpe-couche-halteres`
  - Back squat barre basse — secondary `mu-back-squat-barre-basse`
  - Barre au front à la barre EZ — accessory `mu-barre-au-front-ez`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - V-up — core `mu-v-up`
- **mardi** (75 min, estimé 62 min) — `strength.pull`
  - Rowing poulie basse assis prise supination — main `mu-rowing-poulie-assis-supination`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Rowing buste penché à la Smith machine — secondary `mu-rowing-smith-machine`
  - Oiseau haltères buste penché — accessory `mu-oiseau-halteres`
  - Roue abdominale à genoux — core `mu-roue-abdominale-genoux`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
- **mercredi** (75 min, estimé 61 min) — `strength.push`
  - Développé militaire barre debout — main `mu-developpe-militaire-barre-debout`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Élévation latérale lean-away haltère — accessory `mu-elevation-laterale-lean-away`
  - Curl concentré à l'haltère — accessory `mu-curl-concentre`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Extension lombaire à la machine — core `mu-extension-lombaire-machine`
- **jeudi** (75 min, estimé 61 min) — `strength.full_body`
  - Squat de compétition — main `sl-squat-competition`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Face pull à la poulie corde — secondary `mu-face-pull-corde`
  - Rotation externe à la poulie coude au corps — accessory `mu-rotation-externe-poulie`
  - Planche RKC — core `mu-planche-rkc`
  - Sit-up sur banc décliné — core `mu-sit-up-decline`
- **vendredi** (75 min, estimé 62 min) — `strength.upper`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Tirage vertical poulie prise serrée supination — secondary `mu-tirage-vertical-prise-serree-supination`
  - Curl biceps à la barre droite — accessory `mu-curl-barre-droite`
  - Pull-over haltère allongé sur banc — accessory `mu-pull-over-haltere`
  - Hollow body hold — core `mu-hollow-body-hold`
  - Pallof press debout — core `mu-pallof-press-debout`
- **samedi** (75 min, estimé 62 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre kettlebell — secondary `mu-souleve-de-terre-kettlebell`
  - Mollets unilatéral debout à l'haltère — accessory `mu-mollets-unilateral-haltere`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Rotation externe haltère couché sur le côté — accessory `mu-rotation-externe-haltere-couche`
  - Gainage ventral lesté — core `mu-gainage-ventral-leste`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 20 [12-20], delt_anterior 20 [12-20], delt_middle 17.5 [12-20], delt_posterior 14.5 [12-20], lats 20 [12-20], upper_back 20 [12-20], biceps 18.5 [12-20], triceps 19.5 [12-20], abs 24 [12-20], lower_back 13 [12-20], glutes 20 [12-20], quads 18 [12-20], hamstrings 15 [12-20], calves 15.5 [12-20]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 24 / poussée 21 séries ; chaîne postérieure 11 / genou 12 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur V-up (`d0.6`) :
  - `exercise_replaced` jour 0 : V-up → Tuck-up (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Élévation latérale à la poulie unilatérale (`d2.3`) :
  - `exercise_replaced` jour 2 : Élévation latérale lean-away haltère → Élévation latérale à la poulie unilatérale (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé décliné Smith machine | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Développé couché haltères | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Back squat barre basse | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Barre au front à la barre EZ | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Leg curl couché | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Tuck-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Rowing poulie basse assis prise supination | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 5×6-10 · 5 fl. · 120s · 70 % 1RM | 5×6-10 · 6 fl. · 120s · 71 % 1RM | 5×6-10 · 7 fl. · 120s · 71 % 1RM | 3×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing buste penché à la Smith machine | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Oiseau haltères buste penché | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Roue abdominale à genoux | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé militaire barre debout | 3×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 5 fl. · 120s · 50 kg | 4×6-10 · 6 fl. · 120s · 50 kg | 4×6-10 · 7 fl. · 120s · 50 kg | 2×6-10 · 3 fl. · 120s · 47.5 kg |
| Développé haltères assis | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Élévation latérale à la poulie unilatérale | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Curl concentré à l'haltère | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Mollets debout à la machine | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Extension lombaire à la machine | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Squat de compétition | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Soulevé de terre conventionnel | 3×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 5 fl. · 120s · 130 kg | 4×6-10 · 6 fl. · 120s · 132.5 kg | 4×6-10 · 7 fl. · 120s · 135 kg | 2×6-10 · 3 fl. · 120s · 127.5 kg |
| Face pull à la poulie corde | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rotation externe à la poulie coude au corps | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Sit-up sur banc décliné | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Développé couché barre | 4×3-6 · 5 fl. · 180s · 90 kg | 4×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 5 fl. · 180s · 90 kg | 5×3-6 · 6 fl. · 180s · 90 kg | 5×2-5 · 7 fl. · 180s · 92.5 kg | TEST 3×1-3 · 9 fl. · 240s [3@102.5 5fl. / 1@115 7fl. / 1@122.5 9fl.] |
| Tirage vertical poulie prise serrée supination | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Curl biceps à la barre droite | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Pull-over haltère allongé sur banc | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Hollow body hold | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 5 fl. · 120s · 105 kg | 4×6-10 · 6 fl. · 120s · 107.5 kg | 4×6-10 · 7 fl. · 120s · 107.5 kg | 2×6-10 · 3 fl. · 120s · 102.5 kg |
| Soulevé de terre kettlebell | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Mollets unilatéral debout à l'haltère | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Rotation externe haltère couché sur le côté | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Gainage ventral lesté | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

## 12. `senior_65_forme_generale_3x40`

Senior de 65 ans, forme générale, 3 × 40 min, questionnaire santé en mode prudent.

Profil : general_fitness 60 % + mobility 40 % — lundi 40 min, mercredi 40 min, vendredi 40 min — lieux maison, exterieur — 64 kg, né en 1961, female, santé cautious, knee gêne 3/10.

### Passe 1

Note 0.934 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.99 · goal_specificity 1.00 · discipline_dosage 0.96 · muscle_volume 0.81 · pattern_balance 0.88 · discipline_structure 0.92 · time_use 1.00 · variety 1.00 · exercise_fit 0.64 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (40 min, estimé 40 min) — `cardio.endurance`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Marche rapide — conditioning `ca-marche-rapide`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
- **mercredi** (40 min, estimé 40 min) — `mobility`
  - Mobilisation cheville genou au mur — warmup `mo-cheville-genou-mur`
  - Squat profond tenu — warmup `mo-squat-profond-tenu`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Rowing assis à l'élastique — main `mu-rowing-elastique-assis`
  - Air squat — secondary `mu-air-squat`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement en chiot (ouverture d'épaules au sol) — cooldown `mo-etirement-chiot`
  - Étirement en rotation externe assisté au bâton — cooldown `mo-rotation-externe-assistee-baton`
  - Thread the needle — cooldown `mo-thread-the-needle`
- **vendredi** (40 min, estimé 39 min) — `mobility`
  - Pompe contre le mur — main `sw-pompe-murale`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Mountain climbers — core `mu-mountain-climbers`
  - Étirement adducteurs debout en fente latérale — cooldown `mo-adducteurs-fente-laterale`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Étirement ischio-jambiers assis unilatéral — cooldown `mo-ischio-assis-unilateral`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : cardio 19 % (visé 21 %), mobility 46 % (visé 49 %), generalFitness 34 % (visé 30 %) — erreur 4.3 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [1.5-5], delt_anterior 3 [1.5-5], delt_middle 1 [1.5-5], delt_posterior 3.5 [1.5-5], lats 3 [1.5-5], upper_back 5 [1.5-5], biceps 2.5 [1.5-5], triceps 3 [1.5-5], abs 4 [1.5-5], lower_back 2 [1.5-5], glutes 5 [1.5-5], quads 5 [1.5-5], hamstrings 1 [0-5], calves 1.5 [1.5-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Squat profond tenu (`d1.2`) :
  - `exercise_replaced` jour 1 : Squat profond tenu → Papillon assis (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par Band pull-apart (`d0.2`) :
  - `exercise_replaced` jour 0 : Face pull à l'élastique → Band pull-apart (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Band pull-apart | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Marche rapide | 13-15 min | 18-20 min | 18-20 min | 18-20 min |
| Étirement pectoral au cadre de porte | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Rowing assis à l'élastique | 2×8-12 · 3 fl. · 90s | 3×8-12 · 3 fl. · 90s | 3×8-12 · 4 fl. · 90s | 3×8-12 · 5 fl. · 90s |
| Air squat | 2×4-6 · 3 fl. · 90s | 3×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement en chiot (ouverture d'épaules au sol) | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Papillon assis | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement en rotation externe assisté au bâton | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Thread the needle | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe contre le mur | 2×4-6 · 3 fl. · 90s | 3×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s |
| Pont fessier au sol | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Mountain climbers | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Étirement adducteurs debout en fente latérale | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement pectoral au cadre de porte | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement ischio-jambiers assis unilatéral | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Pigeon au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

## 13. `proprietaire_streetlifting_avance`

Profil calqué sur le propriétaire : streetlifting avancé, environ 71,5 kg, mode street.

Profil : streetlifting 70 % + street_workout 20 % + calisthenics 10 % — lundi 90 min, mardi 90 min, mercredi 75 min, vendredi 90 min, samedi 90 min — lieux salle, exterieur — mode street, expérience advanced, 71.5 kg, né en 1996, male, santé standard, elbow gêne 2/10.

### Passe 1

Note 0.949 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.92 · goal_specificity 0.99 · discipline_dosage 0.99 · muscle_volume 0.97 · pattern_balance 1.00 · discipline_structure 0.90 · time_use 0.99 · variety 1.00 · exercise_fit 0.65 · stimulus_fatigue 0.64 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 81 min) — `strength.full_body`
  - Dips sur barre fixe lesté — main `sl-dips-barre-fixe-leste`
  - Rack pull — secondary `mu-rack-pull`
  - Pompe classique — secondary `sw-pompe`
  - Élévation latérale à la poulie câble derrière le dos — accessory `mu-elevation-laterale-poulie-derriere-dos`
  - Rotation externe à la poulie coude au corps — accessory `mu-rotation-externe-poulie`
  - Pompe scapulaire — accessory `sw-pompe-scapulaire`
  - Hollow body hold — core `mu-hollow-body-hold`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
- **mardi** (90 min, estimé 82 min) — `strength.pull`
  - Traction un bras assistée élastique — skill `cd-traction-un-bras-assistee-elastique`
  - Traction lestée de compétition — main `sl-traction-lestee`
  - Traction en L — secondary `sw-traction-l-sit`
  - Band pull-apart — accessory `mu-band-pull-apart`
  - Curl concentré à l'haltère — accessory `mu-curl-concentre`
  - Oiseau haltères buste penché — accessory `mu-oiseau-halteres`
  - Planche RKC — core `mu-planche-rkc`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
- **mercredi** (75 min, estimé 70 min) — `strength.full_body`
  - Planche push-up straddle assistée à l'élastique — skill `cd-planche-pushup-straddle-elastique`
  - Squat de compétition — main `sl-squat-competition`
  - Pistol squat — secondary `sw-pistol-squat`
  - Rowing menton barre — accessory `mu-rowing-menton-barre`
  - Élévation latérale lean-away haltère — accessory `mu-elevation-laterale-lean-away`
- **vendredi** (90 min, estimé 87 min) — `strength.upper`
  - Dips lesté de compétition — main `sl-dips-leste`
  - Muscle-up lesté de compétition — main `sl-muscle-up-leste`
  - Dips au banc lesté — secondary `sl-dips-banc-leste`
  - Traction chest-to-bar — secondary `sw-traction-chest-to-bar`
  - Rowing poulie basse assis prise large pronation — secondary `mu-rowing-poulie-assis-prise-large`
  - Isométrie lestée en haut de traction — accessory `sl-traction-isometrie-lestee-haute`
  - Rotation externe haltère couché sur le côté — accessory `mu-rotation-externe-haltere-couche`
  - Knees-to-elbows — core `sw-knees-to-elbows`
- **samedi** (90 min, estimé 84 min) — `strength.lower`
  - L-sit aux anneaux — skill `cs-l-sit-anneaux`
  - Squat de compétition — main `sl-squat-competition`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Soulevé de terre roumain à la barre — secondary `mu-souleve-de-terre-roumain-barre`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Arch rocks — core `mu-arch-rocks`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`

Dosage : streetWorkout 20 % (visé 20 %), streetlifting 70 % (visé 70 %), calisthenics 10 % (visé 10 %) — erreur 0.3 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 19 [12-20], delt_anterior 20 [12-20], delt_middle 13.5 [12-20], delt_posterior 19.5 [12-20], lats 20 [12-20], upper_back 20 [12-20], biceps 17 [12-20], triceps 19 [12-20], abs 21 [12-20], lower_back 13 [12-20], glutes 22 [12-20], quads 20 [12-20], hamstrings 17 [12-20], calves 5 [0-20]. Groupes majeurs dans leur bande : 84 %.

Équilibre : tirage 24 / poussée 22 séries ; chaîne postérieure 12 / genou 16 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Isométrie lestée en haut de traction (`d3.6`) :
  - `exercise_replaced` jour 3 : Isométrie lestée en haut de traction → Traction lestée partielle haute surchargée (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par Superman dynamique (`d4.6`) :
  - `exercise_replaced` jour 4 : Arch rocks → Superman dynamique (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Dips sur barre fixe lesté | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Rack pull | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Pompe classique | 3×30 · 5 fl. · 90s | 4×30 · 5 fl. · 90s | 4×30 · 5 fl. · 90s | 4×30 · 6 fl. · 90s | 4×30 · 7 fl. · 90s | 2×30 · 3 fl. · 90s |
| Élévation latérale à la poulie câble derrière le dos | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Rotation externe à la poulie coude au corps | CALIBRAGE 3×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 4×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Pompe scapulaire | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Hollow body hold | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction un bras assistée élastique | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Traction lestée de compétition | 3×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 5 fl. · 180s · 15 kg | 4×3-6 · 6 fl. · 180s · 15 kg | 4×2-5 · 7 fl. · 180s · 18.75 kg | TEST 3×1-3 · 9 fl. · 240s [3@27.5 5fl. / 1@40 7fl. / 1@47.5 9fl.] |
| Traction en L | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Band pull-apart | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl concentré à l'haltère | CALIBRAGE 2×10-15 · 7 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 3×10-15 · 9 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Oiseau haltères buste penché | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Planche push-up straddle assistée à l'élastique | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Squat de compétition | 5×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 5 fl. · 180s · 77.5 kg | 6×3-6 · 5 fl. · 180s · 77.5 kg | 6×3-6 · 6 fl. · 180s · 80 kg | 6×2-5 · 7 fl. · 180s · 82.5 kg | TEST 3×1-3 · 9 fl. · 240s [3@90 5fl. / 1@102.5 7fl. / 1@110 9fl.] |
| Pistol squat | 3×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 5 fl. · 90s | 4×6-12 · 6 fl. · 90s | 4×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Rowing menton barre | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Élévation latérale lean-away haltère | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Dips lesté de compétition | 3×3-6 · 5 fl. · 180s · 28.75 kg | 4×3-6 · 5 fl. · 180s · 28.75 kg | 4×3-6 · 5 fl. · 180s · 28.75 kg | 4×3-6 · 6 fl. · 180s · 30 kg | 4×2-5 · 7 fl. · 180s · 33.75 kg | TEST 3×1-3 · 9 fl. · 240s [3@43.75 5fl. / 1@57.5 7fl. / 1@66.25 9fl.] |
| Muscle-up lesté de compétition | 3×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 5 fl. · 180s · 0 kg | 4×3-6 · 6 fl. · 180s · 0 kg | 4×2-5 · 7 fl. · 180s · 0 kg | TEST 3×1-3 · 9 fl. · 240s [3@0 5fl. / 1@3.75 7fl. / 1@8.75 9fl.] |
| Traction lestée partielle haute surchargée | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 7 fl. · 150s · 75 % 1RM | 1×5-8 · 3 fl. · 150s · 71 % 1RM |
| Dips au banc lesté | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 3×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Traction chest-to-bar | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Rowing poulie basse assis prise large pronation | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 7 fl. · 150s · 75 % 1RM | 1×5-8 · 3 fl. · 150s · 71 % 1RM |
| Rotation externe haltère couché sur le côté | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Knees-to-elbows | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| L-sit aux anneaux | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Squat de compétition | 5×3-6 · 5 fl. · 180s · 77.5 kg | 5×3-6 · 5 fl. · 180s · 77.5 kg | 6×3-6 · 5 fl. · 180s · 77.5 kg | 6×3-6 · 6 fl. · 180s · 80 kg | 6×2-5 · 7 fl. · 180s · 82.5 kg | 4×3-6 · 3 fl. · 180s · 77.5 kg |
| Soulevé de terre conventionnel | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Soulevé de terre roumain à la barre | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 3×10-15 · 8 fl. · 75s | 2×10-15 · 4 fl. · 75s |
| Superman dynamique | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de genoux oblique suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 14. `homme_25_musculation_debutant_3x60`

Homme de 25 ans, débutant en musculation, 3 × 60 min en salle.

Profil : musculation 100 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 70 kg, né en 2001, male, santé standard.

### Passe 1

Note 0.973 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 0.99 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.73 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 58 min) — `strength.pull`
  - Pompe classique — main `sw-pompe`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Face pull à la poulie corde — secondary `mu-face-pull-corde`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Rowing menton à la poulie — accessory `mu-rowing-menton-poulie`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`
- **mercredi** (60 min, estimé 59 min) — `strength.upper`
  - Développé couché Smith machine — main `mu-developpe-couche-smith`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Row australien — secondary `sw-row-australien`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Mollets unilatéral debout à l'haltère — accessory `mu-mollets-unilateral-haltere`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **vendredi** (60 min, estimé 60 min) — `strength.push`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Turkish get-up — core `mu-turkish-get-up`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 11 [8-16], delt_anterior 12.5 [8-16], delt_middle 7.5 [8-16], delt_posterior 10.5 [8-16], lats 12 [8-16], upper_back 12 [8-16], biceps 7.5 [8-16], triceps 11 [8-16], abs 9 [8-16], lower_back 7.5 [8-16], glutes 12 [8-16], quads 9 [8-16], hamstrings 7.5 [8-16], calves 8 [8-16]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 15 / poussée 13 séries ; chaîne postérieure 6 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Développé couché Smith machine (`d1.1`) :
  - `exercise_replaced` jour 1 : Développé couché Smith machine → Développé couché avec pause (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 2 → Larsen press (plan.reoptimized)
  - `exercise_removed` jour 2 : Développé couché barre (plan.reoptimized)
- Remplacement par Rowing poulie basse assis prise large pronation (`d0.3`) :
  - `exercise_replaced` jour 0 : Face pull à la poulie corde → Rowing poulie basse assis prise large pronation (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Pompe classique | 2×5-7 · 5 fl. · 90s | 3×5-7 · 5 fl. · 90s | 3×5-7 · 6 fl. · 90s | 3×5-7 · 7 fl. · 90s | 2×5-7 · 3 fl. · 90s |
| Presse à cuisses 45° | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing poulie basse assis prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing menton à la poulie | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage ventral sur les coudes | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Développé couché avec pause | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | TEST 1×1-16 · 10 fl. · 180s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mollets unilatéral debout à l'haltère | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Larsen press | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé haltères assis | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Mollets debout à la machine | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Turkish get-up | CALIBRAGE 2×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 4 fl. · 90s · 80 % 1RM | 3×2-4 · 5 fl. · 90s · 81 % 1RM | 2×2-4 · 1 fl. · 90s · 77 % 1RM |

## 15. `femme_30_street_workout_parc_3x45`

Femme de 30 ans, street workout au parc, 3 × 45 min.

Profil : street_workout 80 % + mobility 20 % — mardi 45 min, jeudi 45 min, samedi 45 min — lieux exterieur — 60 kg, né en 1996, female, santé standard.

### Passe 1

Note 0.960 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.96 · pattern_balance 1.00 · discipline_structure 0.88 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.84 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `strength.upper`
  - Wall walk — skill `cd-wall-walk`
  - Traction sautée — main `sw-traction-sautee`
  - Row australien — secondary `sw-row-australien`
  - Arch hold — core `mu-arch-hold`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
  - Respiration crocodile — cooldown `mo-respiration-crocodile`
- **jeudi** (45 min, estimé 43 min) — `strength.full_body`
  - Inchworm (chenille) — warmup `mo-inchworm`
  - Fente arrière au poids du corps — main `mu-fente-arriere-poids-du-corps`
  - Pompe classique — secondary `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`
  - Relevé de genoux suspendu — core `sw-releve-genoux-suspendu`
  - Étirement pectoral au cadre de porte — cooldown `mo-etirement-pectoral-cadre-porte`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **samedi** (45 min, estimé 42 min) — `strength.upper`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Traction sautée — main `sw-traction-sautee`
  - Pompe classique — secondary `sw-pompe`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Pompe scapulaire — accessory `sw-pompe-scapulaire`
  - Bird dog — core `mu-bird-dog`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`

Dosage : streetWorkout 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7 [4-10], delt_anterior 8 [4-10], delt_middle 2.5 [4-10], delt_posterior 6 [4-10], lats 9 [4-10], upper_back 10 [4-10], biceps 6 [4-10], triceps 8 [4-10], abs 9 [4-10], lower_back 6 [4-10], glutes 10 [4-10], quads 8 [4-10], hamstrings 2.5 [0-10], calves 0 [0-10]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Étirement des fléchisseurs de hanche en semi-agenouillé (`d0.7`) :
  - `exercise_replaced` jour 0 : Étirement des fléchisseurs de hanche en semi-agenouillé → Couch stretch (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_removed` jour 1 : Étirement des fléchisseurs de hanche en semi-agenouillé (plan.reoptimized)
- Remplacement par Gainage avec touches d'épaules (`d2.6`) :
  - `exercise_replaced` jour 2 : Bird dog → Gainage avec touches d'épaules (plan.user_replaced)
  - `order_changed` jour 2 (plan.reoptimized)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Wall walk | 2×2-5 · 3 fl. · 150s | 3×2-5 · 4 fl. · 150s | 3×2-5 · 5 fl. · 150s | 2×2-5 · 1 fl. · 150s |
| Traction sautée | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | TEST 1×1-24 · 10 fl. · 180s |
| Row australien | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Arch hold | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Mountain climbers | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Couch stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Inchworm (chenille) | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Fente arrière au poids du corps | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pompe classique | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Gainage ventral sur les coudes | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Relevé de genoux suspendu | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Étirement pectoral au cadre de porte | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Traction sautée | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Pompe classique | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s | 2×10-15 · 1 fl. · 75s |
| Pompe scapulaire | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s | 1×10-20 s · 1 fl. · 60s |
| Gainage avec touches d'épaules | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 16. `mobilite_seule_5x20`

Mobilité seule, 5 × 20 min à la maison.

Profil : mobility 100 % — lundi 20 min, mardi 20 min, mercredi 20 min, jeudi 20 min, vendredi 20 min — lieux maison — 58 kg, né en 1979, female, santé standard.

### Passe 1

Note 0.976 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (20 min, estimé 18 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — mobility `mo-flechisseurs-hanche-semi-agenouille`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Marche sur les talons — mobility `mo-marche-talons`
  - Pigeon au sol — mobility `mo-pigeon-sol`
- **mardi** (20 min, estimé 19 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Mobilisation cheville genou au mur — mobility `mo-cheville-genou-mur`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Marche sur les talons — mobility `mo-marche-talons`
  - Wall slides dos au mur — mobility `mo-wall-slides`
  - World's greatest stretch — mobility `mo-worlds-greatest-stretch`
- **mercredi** (20 min, estimé 19 min) — `mobility`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Mobilité douce du cou en trois plans — mobility `mo-mobilite-cou-trois-plans`
  - Respiration en boîte — mobility `mo-respiration-boite`
  - Rotation thoracique à quatre pattes main derrière la tête — mobility `mo-rotation-thoracique-quatre-pattes`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **jeudi** (20 min, estimé 19 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Soupir physiologique — mobility `mo-soupir-physiologique`
  - Wall slides dos au mur — mobility `mo-wall-slides`
  - World's greatest stretch — mobility `mo-worlds-greatest-stretch`
- **vendredi** (20 min, estimé 19 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Bascules en appui doigts vers l'avant — mobility `mo-bascules-appui-doigts-avant`
  - Mobilisation cheville genou au mur — mobility `mo-cheville-genou-mur`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — mobility `mo-foam-roller-routine`
  - Respiration crocodile — mobility `mo-respiration-crocodile`
  - Wall slides dos au mur — mobility `mo-wall-slides`

Dosage : mobility 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Mobilité douce du cou en trois plans (`d2.4`) :
  - `exercise_replaced` jour 2 : Mobilité douce du cou en trois plans → Rétraction du menton (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par Étirement fessier en figure 4 allongé (`d3.1`) :
  - `exercise_replaced` jour 3 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)
  - `order_changed` jour 3 (plan.reoptimized)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Marche sur les talons | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Marche sur les talons | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| World's greatest stretch | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Respiration en boîte | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Rotation thoracique à quatre pattes main derrière la tête | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Soupir physiologique | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| World's greatest stretch | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Bascules en appui doigts vers l'avant | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Respiration crocodile | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

## 17. `cardio_debutant_marche_3x30`

Débutant en cardio (marche, vélo), 3 × 30 min.

Profil : cardio 100 % — lundi 30 min, mercredi 30 min, samedi 30 min — lieux exterieur, maison — 96 kg, né en 1975, male, santé cautious.

### Passe 1

Note 0.976 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 30 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **mercredi** (30 min, estimé 30 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **samedi** (30 min, estimé 30 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`

Dosage : cardio 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Footing en endurance fondamentale (`d0.1`) :
  - `exercise_replaced` jour 0 : Footing en endurance fondamentale → Vélo de récupération très léger (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 1 → Marche de récupération (plan.reoptimized)
  - `exercise_removed` jour 1 : Footing en endurance fondamentale (plan.reoptimized)
  - `exercise_added` jour 2 → Marche de récupération (plan.reoptimized)
  - `exercise_removed` jour 2 : Footing en endurance fondamentale (plan.reoptimized)
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

Note 0.960 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.98 · goal_specificity 1.00 · discipline_dosage 0.96 · muscle_volume 0.93 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `cardio.endurance`
  - Tirage vertical poulie prise large pronation — main `mu-tirage-vertical-prise-large-pronation`
  - Marche de récupération — conditioning `ca-marche-recuperation`
- **jeudi** (45 min, estimé 45 min) — `strength.full_body`
  - Développé couché barre — main `mu-developpe-couche-barre`
  - Rowing inversé à la Smith machine pieds surélevés — secondary `mu-rowing-inverse-smith-pieds-sureleves`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Élévation latérale buste appuyé sur banc incliné — accessory `mu-elevation-laterale-buste-appuye-banc-incline`
  - Flexion latérale à l'haltère — core `mu-flexion-laterale-haltere`
- **samedi** (45 min, estimé 43 min) — `strength.upper`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Turkish get-up — core `mu-turkish-get-up`

Dosage : musculation 74 % (visé 70 %), cardio 26 % (visé 30 %) — erreur 4.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [5-10], delt_anterior 7 [5-10], delt_middle 5 [5-10], delt_posterior 6 [5-10], lats 9 [5-10], upper_back 10 [5-10], biceps 4.5 [5-10], triceps 6 [5-10], abs 5 [5-10], lower_back 6 [5-10], glutes 8 [5-10], quads 5 [5-10], hamstrings 4.5 [5-10], calves 1.5 [5-10]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 9 / poussée 7 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Élévation latérale buste appuyé sur banc incliné (`d1.4`) :
  - `exercise_replaced` jour 1 : Élévation latérale buste appuyé sur banc incliné → Élévation latérale à la machine (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Tirage vertical à l'élastique (`d0.1`) :
  - `exercise_replaced` jour 0 : Tirage vertical poulie prise large pronation → Tirage vertical à l'élastique (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Tirage vertical à l'élastique | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Marche de récupération | 22-25 min | 22-25 min | 27-30 min | 27-30 min | 18-20 min |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 37.5 kg | 3×6-10 · 5 fl. · 120s · 37.5 kg | 3×6-10 · 6 fl. · 120s · 37.5 kg | 3×6-10 · 7 fl. · 120s · 37.5 kg | 2×6-10 · 3 fl. · 120s · 35 kg |
| Rowing inversé à la Smith machine pieds surélevés | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Presse à cuisses 45° | 2×6-10 · 5 fl. · 120s · 75 kg | 3×6-10 · 5 fl. · 120s · 75 kg | 3×6-10 · 6 fl. · 120s · 75 kg | 3×6-10 · 7 fl. · 120s · 75 kg | 2×6-10 · 3 fl. · 120s · 70 kg |
| Élévation latérale à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Flexion latérale à l'haltère | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 37.5 kg | 2×6-10 · 5 fl. · 120s · 37.5 kg | 2×6-10 · 6 fl. · 120s · 37.5 kg | 2×6-10 · 7 fl. · 120s · 37.5 kg | 1×6-10 · 3 fl. · 120s · 35 kg |
| Développé haltères assis | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 2×6-10 · 5 fl. · 120s · 70 % 1RM | 2×6-10 · 6 fl. · 120s · 71 % 1RM | 2×6-10 · 7 fl. · 120s · 71 % 1RM | 1×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing inversé à la Smith machine | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Turkish get-up | CALIBRAGE 2×2-4 · 3 fl. · 90s · 79 % 1RM | 2×2-4 · 3 fl. · 90s · 79 % 1RM | 2×2-4 · 4 fl. · 90s · 80 % 1RM | 2×2-4 · 5 fl. · 90s · 81 % 1RM | 1×2-4 · 1 fl. · 90s · 77 % 1RM |

## 19. `lombalgie_musculation_3x50`

Musculation avec le bas du dos sensible (gêne 5/10).

Profil : musculation 80 % + mobility 20 % — lundi 50 min, mercredi 50 min, vendredi 50 min — lieux salle — 67 kg, né en 1989, female, santé standard, lower_back gêne 5/10.

### Passe 1

Note 0.961 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.96 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.95 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.65 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (50 min, estimé 50 min) — `strength.upper`
  - Rocking des adducteurs en quadrupédie — warmup `mo-adducteurs-rocking`
  - CARs de hanche — warmup `mo-cars-hanche`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Tirage vertical poulie prise serrée supination — secondary `mu-tirage-vertical-prise-serree-supination`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Élévation latérale buste appuyé sur banc incliné — accessory `mu-elevation-laterale-buste-appuye-banc-incline`
  - V-up — core `mu-v-up`
  - Étirement adducteurs debout en fente latérale — cooldown `mo-adducteurs-fente-laterale`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **mercredi** (50 min, estimé 49 min) — `strength.full_body`
  - CARs d'épaule — warmup `mo-cars-epaule`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Traction pronation — main `sw-traction-pronation`
  - Air squat — secondary `mu-air-squat`
  - Drag curl à la barre — accessory `mu-drag-curl-barre`
  - Lu raise — accessory `mu-lu-raise`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **vendredi** (50 min, estimé 50 min) — `strength.upper`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Pompe en T — secondary `sw-pompe-t`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Planche RKC — core `mu-planche-rkc`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : musculation 81 % (visé 80 %), mobility 19 % (visé 20 %) — erreur 1.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 12 [6.5-13], delt_anterior 10.5 [6.5-13], delt_middle 6.5 [6.5-13], delt_posterior 7 [6.5-13], lats 12 [6.5-13], upper_back 10 [6.5-13], biceps 9 [6.5-13], triceps 10.5 [6.5-13], abs 6.5 [6.5-13], lower_back 2.5 [6.5-13], glutes 8 [6.5-13], quads 6 [6.5-13], hamstrings 5 [6.5-13], calves 4.5 [6.5-13]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 12 / poussée 9 séries ; chaîne postérieure 5 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Leg curl couché (`d1.7`) :
  - `exercise_replaced` jour 1 : Leg curl couché → Nordic hamstring curl assisté à l'élastique (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Pigeon sur banc ou box (`d2.7`) :
  - `exercise_replaced` jour 2 : Mobilité hanches 90/90 passive → Pigeon sur banc ou box (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Rocking des adducteurs en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| CARs de hanche | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Développé couché haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise serrée supination | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Élévation latérale buste appuyé sur banc incliné | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| V-up | 2×8-12 · 4 fl. · 60s | 2×8-12 · 4 fl. · 60s | 2×8-12 · 5 fl. · 60s | 2×8-12 · 6 fl. · 60s | 1×8-12 · 2 fl. · 60s |
| Étirement adducteurs debout en fente latérale | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| CARs d'épaule | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Traction pronation | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Air squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Drag curl à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Lu raise | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Nordic hamstring curl assisté à l'élastique | 2×8-12 · 5 fl. · 75s | 3×8-12 · 5 fl. · 75s | 3×8-12 · 6 fl. · 75s | 3×8-12 · 7 fl. · 75s | 2×8-12 · 3 fl. · 75s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 32.5 kg | 3×6-10 · 5 fl. · 120s · 32.5 kg | 3×6-10 · 6 fl. · 120s · 32.5 kg | 3×6-10 · 7 fl. · 120s · 35 kg | 2×6-10 · 3 fl. · 120s · 32.5 kg |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Pompe en T | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage bras tendus à l'élastique | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |
| Pigeon sur banc ou box | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 20. `poignet_calisthenie_3x60`

Calisthénie avec un poignet droit sensible (gêne 4/10).

Profil : calisthenics 100 % — lundi 60 min, mercredi 60 min, samedi 60 min — lieux exterieur — 64 kg, né en 2000, male, santé standard, wrist_hand gêne 4/10.

### Passe 1

Note 0.953 — recovery 1.00 · fatigue_balance 1.00 · joint_load 0.93 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.96 · pattern_balance 1.00 · discipline_structure 0.84 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.84 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 58 min) — `strength.upper`
  - Back lever une jambe — skill `cs-back-lever-une-jambe`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Pompe en T — main `sw-pompe-t`
  - Skater squat — secondary `sw-skater-squat`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
- **mercredi** (60 min, estimé 59 min) — `strength.upper`
  - Skin the cat — skill `cd-skin-the-cat`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Pompe pike — main `sw-pompe-pike`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
  - Hip airplane — accessory `mu-hip-airplane`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **samedi** (60 min, estimé 58 min) — `skills`
  - Front lever assisté élastique — skill `cs-front-lever-assiste-elastique`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Support hold aux anneaux — skill `cs-support-anneaux`
  - Skater squat — main `sw-skater-squat`
  - Traction pronation — secondary `sw-traction-pronation`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`

Dosage : calisthenics 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 13 [8-16], delt_anterior 10 [8-16], delt_middle 4.5 [8-16], delt_posterior 8.5 [8-16], lats 14 [8-16], upper_back 13.5 [8-16], biceps 8 [8-16], triceps 13.5 [8-16], abs 14.5 [8-16], lower_back 6 [8-16], glutes 16 [8-16], quads 13 [8-16], hamstrings 8 [8-16], calves 0 [0-16]. Groupes majeurs dans leur bande : 89 %.

Équilibre : tirage 16 / poussée 10 séries ; chaîne postérieure 6 / genou 7 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Back lever une jambe (`d0.1`) :
  - `exercise_replaced` jour 0 : Back lever une jambe → Support hold aux anneaux (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
- Remplacement par Clamshell (`d1.5`) :
  - `exercise_replaced` jour 1 : Hip airplane → Clamshell (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Support hold aux anneaux | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Skater squat | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Face pull à l'élastique | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral avec relevés de hanche | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Skin the cat | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Clamshell | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Front lever assisté élastique | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| L-sit sur parallettes | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Support hold aux anneaux | 2×10-20 s · 4 fl. · 120s | 3×10-20 s · 4 fl. · 120s | 3×10-20 s · 5 fl. · 120s | 3×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Skater squat | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 3×6-9 · 5 fl. · 90s | 4×6-9 · 5 fl. · 90s | 4×6-9 · 6 fl. · 90s | 4×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Pont fessier au sol | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

## 21. `femme_22_calisthenie_debutante_maison`

Débutante en calisthénie à la maison, avec barre de traction.

Profil : calisthenics 70 % + mobility 30 % — lundi 45 min, mercredi 45 min, vendredi 45 min — lieux maison — 57 kg, né en 2004, female, santé standard.

### Passe 1

Note 0.942 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.93 · pattern_balance 1.00 · discipline_structure 0.77 · time_use 1.00 · variety 1.00 · exercise_fit 0.63 · stimulus_fatigue 0.89 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 45 min) — `strength.upper`
  - Rocking des adducteurs en quadrupédie — warmup `mo-adducteurs-rocking`
  - Cat-cow — warmup `mo-cat-cow`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Inverted hang — skill `cs-inverted-hang`
  - L-sit une jambe — skill `cs-l-sit-une-jambe`
  - Pompe sur les genoux — main `sw-pompe-genoux`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **mercredi** (45 min, estimé 45 min) — `strength.upper`
  - Rocking des adducteurs en quadrupédie — warmup `mo-adducteurs-rocking`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - L-sit une jambe — skill `cs-l-sit-une-jambe`
  - Traction sautée — main `sw-traction-sautee`
  - Pompe sur les genoux — secondary `sw-pompe-genoux`
  - Chaise contre le mur — accessory `mu-wall-sit`
  - Dead hang — accessory `sw-dead-hang`
  - Bird dog — core `mu-bird-dog`
  - Étirement de l'élévateur de la scapula — cooldown `mo-etirement-elevateur-scapula`
  - Étirement des fléchisseurs de hanche en semi-agenouillé — cooldown `mo-flechisseurs-hanche-semi-agenouille`
- **vendredi** (45 min, estimé 44 min) — `strength.upper`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Traction sautée — main `sw-traction-sautee`
  - Développé épaules à l'élastique debout — secondary `mu-developpe-epaules-elastique-debout`
  - Band pull-apart — accessory `mu-band-pull-apart`
  - Sit-up — core `mu-sit-up`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement du biceps au mur — cooldown `mo-etirement-biceps-mur`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`

Dosage : calisthenics 70 % (visé 70 %), mobility 30 % (visé 30 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [4-10], delt_anterior 10 [4-10], delt_middle 4 [4-10], delt_posterior 5 [4-10], lats 10 [4-10], upper_back 10.5 [4-10], biceps 4.5 [4-10], triceps 10.5 [4-10], abs 6 [4-10], lower_back 2 [4-10], glutes 7.5 [4-10], quads 8 [4-10], hamstrings 1 [0-10], calves 0 [0-10]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 2 / genou 1 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Wall slides dos au mur (`d2.2`) :
  - `exercise_removed` jour 0 : Wall slides dos au mur (plan.reoptimized)
  - `exercise_removed` jour 1 : Wall slides dos au mur (plan.reoptimized)
  - `exercise_replaced` jour 2 : Wall slides dos au mur → Lift-off en rotation externe 90/90 allongé ventral (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par L-sit tuck (`d0.5`) :
  - `exercise_replaced` jour 0 : L-sit une jambe → L-sit tuck (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Rocking des adducteurs en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Cat-cow | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Inverted hang | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| L-sit tuck | 2×5-10 s · 3 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 2×5-10 s · 1 fl. · 120s |
| Pompe sur les genoux | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Rocking des adducteurs en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| L-sit une jambe | 2×5-10 s · 3 fl. · 120s | 2×5-10 s · 4 fl. · 120s | 2×5-10 s · 5 fl. · 120s | 1×5-10 s · 1 fl. · 120s |
| Traction sautée | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | TEST 1×1-24 · 10 fl. · 180s |
| Pompe sur les genoux | 2×4-6 · 3 fl. · 90s | 3×4-6 · 4 fl. · 90s | 3×4-6 · 5 fl. · 90s | 2×4-6 · 1 fl. · 90s |
| Chaise contre le mur | 1×5-12 s · 3 fl. · 60s | 1×5-12 s · 4 fl. · 60s | 1×5-12 s · 5 fl. · 60s | 1×5-12 s · 1 fl. · 60s |
| Dead hang | 2×10-15 s · 3 fl. · 60s | 2×10-15 s · 4 fl. · 60s | 2×10-15 s · 5 fl. · 60s | 1×10-15 s · 1 fl. · 60s |
| Bird dog | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Étirement de l'élévateur de la scapula | 3×20-30 s · 10s | 4×20-30 s · 10s | 4×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des fléchisseurs de hanche en semi-agenouillé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (test) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Traction sautée | 2×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Développé épaules à l'élastique debout | 2×8-12 · 3 fl. · 90s | 3×8-12 · 4 fl. · 90s | 3×8-12 · 5 fl. · 90s | 2×8-12 · 1 fl. · 90s |
| Band pull-apart | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s | 1×10-15 · 1 fl. · 75s |
| Sit-up | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 1×10-15 · 1 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement du biceps au mur | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 22. `homme_35_crossfit_maison_kettlebell`

CrossFit à la maison avec kettlebell et corde à sauter, 4 × 40 min.

Profil : crossfit 70 % + cardio 30 % — lundi 40 min, mardi 40 min, jeudi 40 min, samedi 40 min — lieux maison, exterieur — 84 kg, né en 1991, male, santé standard.

### Passe 1

Note 0.948 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.91 · pattern_balance 1.00 · discipline_structure 0.87 · time_use 0.99 · variety 1.00 · exercise_fit 0.63 · stimulus_fatigue 0.76 · preferences 1.00 · novelty 1.00.

- **lundi** (40 min, estimé 40 min) — `cardio.endurance`
  - Marche de récupération — conditioning `ca-marche-recuperation`
- **mardi** (40 min, estimé 36 min) — `strength.full_body`
  - Traction prise mixte — main `sw-traction-prise-mixte`
  - Soulevé de terre kettlebell — secondary `mu-souleve-de-terre-kettlebell`
  - Burpee — conditioning `cf-burpee`
  - Squat jacks — conditioning `cf-squat-jacks`
  - Pogo jumps — conditioning `cf-pogo-jumps`
- **jeudi** (40 min, estimé 39 min) — `strength.upper`
  - Back lever tuck avancé — skill `cs-back-lever-tuck-avance`
  - Saut en longueur sans élan — secondary `mu-broad-jump`
  - Développé kettlebell bottoms-up — main `mu-bottoms-up-press-kettlebell`
  - Traction pronation — secondary `sw-traction-pronation`
  - Knees-to-elbows — core `sw-knees-to-elbows`
- **samedi** (40 min, estimé 37 min) — `strength.full_body`
  - Cossack squat — main `mu-cossack-squat`
  - Pompe en T — secondary `sw-pompe-t`
  - V-up — core `mu-v-up`
  - Burpee avec tuck jump — conditioning `cf-burpee-tuck-jump`
  - Saut en étoile — conditioning `cf-saut-etoile`
  - Traction kipping — conditioning `cf-traction-kipping`

Dosage : crossfit 71 % (visé 70 %), cardio 29 % (visé 30 %) — erreur 0.7 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7 [3.5-7], delt_anterior 7 [3.5-7], delt_middle 3 [3.5-7], delt_posterior 1.5 [3.5-7], lats 6.5 [3.5-7], upper_back 5 [3.5-7], biceps 5.5 [3.5-7], triceps 6 [3.5-7], abs 6.5 [3.5-7], lower_back 2.5 [3.5-7], glutes 8 [3.5-7], quads 6.5 [3.5-7], hamstrings 5 [3.5-7], calves 3.5 [3.5-7]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 8 / poussée 6 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Cossack squat (`d3.1`) :
  - `exercise_replaced` jour 3 : Cossack squat → Goblet squat (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par Burpee box jump-over (`d3.4`) :
  - `exercise_replaced` jour 3 : Burpee avec tuck jump → Burpee box jump-over (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Marche de récupération | 27-30 min | 31-35 min | 36-40 min | 36-40 min | 22-25 min |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Traction prise mixte | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Soulevé de terre kettlebell | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Burpee | 4×8-12 · 15s · rounds wod-d1 | 5×8-12 · 15s · rounds wod-d1 | 5×8-12 · 15s · rounds wod-d1 | 5×8-12 · 15s · rounds wod-d1 | 3×8-12 · 15s · rounds wod-d1 |
| Squat jacks | 3×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 2×30-40 s · 15s · rounds wod-d1 |
| Pogo jumps | 3×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 4×30-40 s · 15s · rounds wod-d1 | 2×30-40 s · 15s · rounds wod-d1 |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back lever tuck avancé | 2×5-10 s · 4 fl. · 120s | 2×5-10 s · 4 fl. · 120s | 2×5-10 s · 5 fl. · 120s | 2×5-10 s · 6 fl. · 120s | 1×5-10 s · 2 fl. · 120s |
| Saut en longueur sans élan | 2×5-8 · 3 fl. · 90s | 3×5-8 · 3 fl. · 90s | 3×5-8 · 4 fl. · 90s | 3×5-8 · 5 fl. · 90s | 2×5-8 · 1 fl. · 90s |
| Développé kettlebell bottoms-up | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Knees-to-elbows | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Goblet squat | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 2×5-8 · 4 fl. · 150s · 72 % 1RM | 2×5-8 · 5 fl. · 150s · 73 % 1RM | 2×5-8 · 6 fl. · 150s · 74 % 1RM | 1×5-8 · 2 fl. · 150s · 71 % 1RM |
| V-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Burpee box jump-over | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Saut en étoile | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |
| Traction kipping | 3×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 4×8-12 · 15s · rounds wod-d3 | 2×8-12 · 15s · rounds wod-d3 |

## 23. `musculation_maison_halteres_4x45`

Musculation à la maison avec haltères et banc, 4 × 45 min.

Profil : musculation 100 % — lundi 45 min, mardi 45 min, jeudi 45 min, vendredi 45 min — lieux maison — 77 kg, né en 1987, male, santé standard.

### Passe 1

Note 0.959 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 0.94 · discipline_structure 0.93 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.69 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 43 min) — `strength.push`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Curl concentré à l'haltère — accessory `mu-curl-concentre`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Rotation interne haltère couché sur le côté — accessory `mu-rotation-interne-haltere-couche`
  - Dead bug — core `mu-dead-bug`
- **mardi** (45 min, estimé 41 min) — `strength.full_body`
  - Split squat aux haltères — main `mu-split-squat`
  - Tirage vertical à l'élastique — secondary `mu-tirage-vertical-elastique`
  - Pont fessier pieds surélevés — accessory `mu-pont-fessier-pieds-sureleves`
  - Band pull-apart — accessory `mu-band-pull-apart`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Sit-up — core `mu-sit-up`
- **jeudi** (45 min, estimé 44 min) — `strength.push`
  - Pompe classique — main `sw-pompe`
  - Extension triceps couchée croisée à l'haltère — accessory `mu-extension-croisee-couche-haltere`
  - Lu raise — accessory `mu-lu-raise`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Oiseau haltères buste penché — accessory `mu-oiseau-halteres`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
- **vendredi** (45 min, estimé 41 min) — `strength.full_body`
  - Fente arrière aux haltères — main `mu-fente-arriere-halteres`
  - Rowing haltère unilatéral appui sur banc — secondary `mu-rowing-haltere-unilateral-banc`
  - Soulevé de terre roumain aux haltères — secondary `mu-souleve-de-terre-roumain-halteres`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [4-10], delt_anterior 9 [4-10], delt_middle 7.5 [4-10], delt_posterior 6.5 [4-10], lats 7.5 [4-10], upper_back 9.5 [4-10], biceps 8 [4-10], triceps 9 [4-10], abs 10 [4-10], lower_back 5.5 [4-10], glutes 11 [4-10], quads 6 [4-10], hamstrings 6.5 [4-10], calves 1 [0-10]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 5 / genou 6 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Band pull-apart (`d1.4`) :
  - `exercise_replaced` jour 1 : Band pull-apart → Face pull à l'élastique (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Dead bug touche-talon (`d0.5`) :
  - `exercise_replaced` jour 0 : Dead bug → Dead bug touche-talon (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Développé couché haltères | 2×6-10 · 5 fl. · 120s · 16 kg | 3×6-10 · 5 fl. · 120s · 16 kg | 3×6-10 · 6 fl. · 120s · 16 kg | 3×6-10 · 7 fl. · 120s · 16 kg |
| Curl concentré à l'haltère | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Rotation interne haltère couché sur le côté | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Dead bug touche-talon | 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Split squat aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Tirage vertical à l'élastique | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Pont fessier pieds surélevés | 2×8-12 · 3 fl. · 75s | 2×8-12 · 3 fl. · 75s | 2×8-12 · 4 fl. · 75s | 2×8-12 · 5 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Sit-up | 2×10-15 · 3 fl. · 60s | 2×10-15 · 3 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Pompe classique | 2×12-18 · 5 fl. · 90s | 3×12-18 · 5 fl. · 90s | 3×12-18 · 6 fl. · 90s | 3×12-18 · 7 fl. · 90s |
| Extension triceps couchée croisée à l'haltère | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Lu raise | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Oiseau haltères buste penché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s |
| Gainage latéral bras tendu | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Fente arrière aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Rowing haltère unilatéral appui sur banc | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Soulevé de terre roumain aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Gainage ventral sur les coudes | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

## 24. `elite_calisthenie_6x90`

Calisthénie de niveau élite, 6 × 90 min.

Profil : calisthenics 90 % + mobility 10 % — lundi 90 min, mardi 90 min, mercredi 90 min, jeudi 90 min, vendredi 90 min, samedi 90 min — lieux salle, exterieur — 66 kg, né en 1998, male, santé standard.

### Passe 1

Note 0.942 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.93 · muscle_volume 0.93 · pattern_balance 1.00 · discipline_structure 0.85 · time_use 0.88 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (90 min, estimé 51 min) — `strength.full_body`
  - L-sit sur parallettes — skill `cs-l-sit`
  - HSPU libre — main `cd-hspu-libre`
  - Skater squat — secondary `sw-skater-squat`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Étirement en bas de dips aux barres parallèles — cooldown `mo-etirement-bas-dips-barres`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **mardi** (90 min, estimé 51 min) — `skills`
  - Traction un bras — skill `cd-traction-un-bras`
  - Ice cream maker — skill `cd-ice-cream-maker`
  - Front lever — skill `cs-front-lever`
  - Relevé de genoux oblique suspendu — core `sw-releve-genoux-oblique`
- **mercredi** (90 min, estimé 52 min) — `skills`
  - Planche straddle — skill `cs-planche-straddle`
  - L-sit sur parallettes — skill `cs-l-sit`
  - HSPU au mur dos au mur — main `cd-hspu-mur-dos`
  - Hip airplane — accessory `mu-hip-airplane`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **jeudi** (90 min, estimé 52 min) — `skills`
  - Traction un bras — skill `cd-traction-un-bras`
  - Front lever row tuck — skill `cd-front-lever-row-tuck`
  - Front lever — skill `cs-front-lever`
  - Étirement de la capsule postérieure bras croisé — cooldown `mo-etirement-capsule-posterieure-bras-croise`
- **vendredi** (90 min, estimé 52 min) — `strength.lower`
  - Squat profond tenu — warmup `mo-squat-profond-tenu`
  - Table inversée — warmup `mo-table-inversee`
  - L-sit sur parallettes — skill `cs-l-sit`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
  - Arch rocks — core `mu-arch-rocks`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **samedi** (90 min, estimé 52 min) — `mobility`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Planche straddle — skill `cs-planche-straddle`
  - HSPU au mur ventre face au mur — main `cd-hspu-mur-ventre-face`
  - Bird dog — core `mu-bird-dog`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Papillon assis — cooldown `mo-papillon`
  - Pigeon au sol — cooldown `mo-pigeon-sol`

Dosage : calisthenics 84 % (visé 90 %), mobility 16 % (visé 10 %) — erreur 6.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 19 [12-20], delt_anterior 18 [12-20], delt_middle 12 [12-20], delt_posterior 14 [12-20], lats 20 [12-20], upper_back 17.5 [12-20], biceps 12 [12-20], triceps 23.5 [12-20], abs 18 [12-20], lower_back 11 [12-20], glutes 13 [12-20], quads 12 [12-20], hamstrings 4.5 [12-20], calves 0 [0-20]. Groupes majeurs dans leur bande : 80 %.

Équilibre : tirage 30 / poussée 22 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Table inversée (`d4.2`) :
  - `exercise_replaced` jour 4 : Table inversée → Étirement des épaules en extension assis au sol (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 4 (plan.reoptimized)
- Remplacement par HSPU au mur dos au mur (`d5.3`) :
  - `exercise_replaced` jour 5 : HSPU au mur ventre face au mur → HSPU au mur dos au mur (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| HSPU libre | 3×2-3 · 5 fl. · 90s | 4×2-3 · 5 fl. · 90s | 4×2-3 · 5 fl. · 90s | 4×2-3 · 6 fl. · 90s | 4×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Skater squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Étirement en bas de dips aux barres parallèles | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction un bras | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Ice cream maker | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Front lever | 3×6-9 s · 4 fl. · 120s | 4×6-9 s · 4 fl. · 120s | 4×6-9 s · 4 fl. · 120s | 4×6-9 s · 5 fl. · 120s | 4×6-9 s · 6 fl. · 120s | 2×6-9 s · 2 fl. · 120s |
| Relevé de genoux oblique suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Planche straddle | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 5×4-6 s · 4 fl. · 120s | 5×4-6 s · 5 fl. · 120s | 5×4-6 s · 6 fl. · 120s | TEST 2×1-12 s · 10 fl. · 180s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| HSPU au mur dos au mur | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Traction un bras | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Front lever row tuck | 4×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 5×2-5 · 4 fl. · 150s | 5×2-5 · 5 fl. · 150s | 5×2-5 · 6 fl. · 150s | 3×2-5 · 2 fl. · 150s |
| Front lever | 5×6-9 s · 4 fl. · 120s | 5×6-9 s · 4 fl. · 120s | 6×6-9 s · 4 fl. · 120s | 6×6-9 s · 5 fl. · 120s | 6×6-9 s · 6 fl. · 120s | 4×6-9 s · 2 fl. · 120s |
| Étirement de la capsule postérieure bras croisé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Squat profond tenu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| L-sit sur parallettes | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch rocks | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pike assis passif | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des épaules en extension assis au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (build) | S6 (test) |
| --- | --- | --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Planche straddle | 4×4-6 s · 4 fl. · 120s | 4×4-6 s · 4 fl. · 120s | 5×4-6 s · 4 fl. · 120s | 5×4-6 s · 5 fl. · 120s | 5×4-6 s · 6 fl. · 120s | 3×4-6 s · 2 fl. · 120s |
| HSPU au mur dos au mur | 3×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 5 fl. · 90s | 4×10-15 · 6 fl. · 90s | 4×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Bird dog | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Pike assis passif | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Papillon assis | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 25. `streetlifting_debutant_3x60`

Débutant en streetlifting : peu de tractions, pas encore de lest.

Profil : streetlifting 50 % + street_workout 40 % + calisthenics 10 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — mode street, 74 kg, né en 2002, male, santé standard.

### Passe 1

Note 0.964 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 0.99 · discipline_dosage 0.99 · muscle_volume 0.99 · pattern_balance 1.00 · discipline_structure 0.93 · time_use 1.00 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.71 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.upper`
  - Handstand libre — skill `cs-handstand`
  - Squat de compétition — main `sl-squat-competition`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Pompe en T — secondary `sw-pompe-t`
  - Row australien prise large — secondary `sw-row-australien-large`
- **mercredi** (60 min, estimé 58 min) — `strength.full_body`
  - Dips au banc lesté — main `sl-dips-banc-leste`
  - Traction pronation — secondary `sw-traction-pronation`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Walkout supramaximal au squat — accessory `sl-squat-walkout-supramaximal`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Planche RKC — core `mu-planche-rkc`
- **vendredi** (60 min, estimé 60 min) — `strength.upper`
  - Skin the cat groupé — skill `cd-skin-the-cat-groupe`
  - Dips au banc pieds surélevés — main `sw-dips-banc-pieds-sureleves`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Traction pronation — secondary `sw-traction-pronation`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Pompe en T — secondary `sw-pompe-t`
  - Row australien — secondary `sw-row-australien`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`

Dosage : streetWorkout 40 % (visé 40 %), streetlifting 51 % (visé 50 %), calisthenics 10 % (visé 10 %) — erreur 0.6 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 15.5 [8-16], delt_anterior 18 [8-16], delt_middle 8 [8-16], delt_posterior 13.5 [8-16], lats 16 [8-16], upper_back 16 [8-16], biceps 9.5 [8-16], triceps 16.5 [8-16], abs 9 [8-16], lower_back 10 [8-16], glutes 11.5 [8-16], quads 13 [8-16], hamstrings 8.5 [8-16], calves 3 [0-16]. Groupes majeurs dans leur bande : 89 %.

Équilibre : tirage 20 / poussée 19 séries ; chaîne postérieure 7 / genou 8 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Élévation latérale haltères (`d1.6`) :
  - `exercise_replaced` jour 1 : Élévation latérale haltères → Rowing menton haltères (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Relevé de genoux oblique suspendu (`d2.8`) :
  - `exercise_replaced` jour 2 : Windshield wiper suspendu genoux fléchis → Relevé de genoux oblique suspendu (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Squat de compétition | 4×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 5 fl. · 180s · 47.5 kg | 5×3-6 · 6 fl. · 180s · 47.5 kg | 5×2-5 · 7 fl. · 180s · 50 kg | 3×3-6 · 3 fl. · 180s · 45 kg |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Row australien prise large | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Dips au banc lesté | CALIBRAGE 2×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 4 fl. · 150s · 72 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 2×5-8 · 2 fl. · 150s · 71 % 1RM |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Soulevé de terre conventionnel | CALIBRAGE 3×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 5 fl. · 150s · 73 % 1RM | 4×5-8 · 6 fl. · 150s · 74 % 1RM | 4×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Row australien prise large | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Walkout supramaximal au squat | 2×5-12 s · 5 fl. · 60s | 3×5-12 s · 5 fl. · 60s | 3×5-12 s · 6 fl. · 60s | 3×5-12 s · 7 fl. · 60s | 2×5-12 s · 3 fl. · 60s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Planche RKC | 2×10-20 s · 4 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s | 3×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Skin the cat groupé | 2×2-5 · 4 fl. · 150s | 2×2-5 · 4 fl. · 150s | 2×2-5 · 5 fl. · 150s | 2×2-5 · 6 fl. · 150s | 1×2-5 · 2 fl. · 150s |
| Dips au banc pieds surélevés | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Dips aux barres parallèles | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Soulevé de terre conventionnel | CALIBRAGE 2×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 5 fl. · 150s · 73 % 1RM | 3×5-8 · 6 fl. · 150s · 74 % 1RM | 3×5-8 · 7 fl. · 150s · 75 % 1RM | 2×5-8 · 3 fl. · 150s · 71 % 1RM |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Relevé de genoux oblique suspendu | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |

## 26. `forme_generale_exterieur_3x40`

Forme générale en extérieur, 3 × 40 min.

Profil : general_fitness 70 % + cardio 30 % — mardi 40 min, jeudi 40 min, dimanche 40 min — lieux exterieur — 62 kg, né en 1992, female, santé standard.

### Passe 1

Note 0.948 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.81 · pattern_balance 0.88 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.89 · preferences 1.00 · novelty 1.00.

- **mardi** (40 min, estimé 37 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Pompe classique — secondary `sw-pompe`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **jeudi** (40 min, estimé 40 min) — `strength.full_body`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Row australien — main `sw-row-australien`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement de la capsule postérieure bras croisé — cooldown `mo-etirement-capsule-posterieure-bras-croise`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **dimanche** (40 min, estimé 40 min) — `cardio.endurance`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`

Dosage : cardio 54 % (visé 55 %), mobility 10 % (visé 11 %), generalFitness 35 % (visé 35 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [2-5], delt_anterior 3 [2-5], delt_middle 1 [2-5], delt_posterior 5 [2-5], lats 3 [2-5], upper_back 5 [2-5], biceps 2.5 [2-5], triceps 3 [2-5], abs 4 [2-5], lower_back 4 [2-5], glutes 4 [2-5], quads 2 [2-5], hamstrings 1 [0-5], calves 1 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Gainage latéral sur le coude (`d0.3`) :
  - `exercise_replaced` jour 0 : Gainage latéral sur le coude → Gainage latéral sur les genoux (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 1 → Mountain climbers (plan.reoptimized)
  - `exercise_removed` jour 1 : Gainage latéral bras tendu (plan.reoptimized)
- Remplacement par Corde à sauter en pas alternés (`d0.4`) :
  - `exercise_replaced` jour 0 : Corde à sauter sauts simples → Corde à sauter en pas alternés (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Air squat | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Pompe classique | 2×3-4 · 3 fl. · 90s | 3×3-4 · 3 fl. · 90s | 3×3-4 · 4 fl. · 90s | 3×3-4 · 5 fl. · 90s |
| Gainage latéral sur les genoux | 1×20-40 s · 3 fl. · 60s | 1×20-40 s · 3 fl. · 60s | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 5 fl. · 60s |
| Corde à sauter en pas alternés | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s |
| Footing en endurance fondamentale | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Row australien | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Mountain climbers | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s |
| Étirement de la capsule postérieure bras croisé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Footing en endurance fondamentale | 22-25 min | 22-25 min | 27-30 min | 27-30 min |

## 27. `senior_72_mobilite_marche_4x30`

Senior de 72 ans : mobilité et marche, 4 × 30 min, mode prudent.

Profil : mobility 60 % + cardio 40 % — lundi 30 min, mercredi 30 min, vendredi 30 min, dimanche 30 min — lieux maison, exterieur — 79 kg, né en 1954, male, santé cautious, hip gêne 3/10, lower_back gêne 2/10.

### Passe 1

Note 0.974 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 1.00 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.63 · stimulus_fatigue 1.00 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 29 min) — `cardio.endurance`
  - Table inversée — warmup `mo-table-inversee`
  - Marche rapide — conditioning `ca-marche-rapide`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **mercredi** (30 min, estimé 28 min) — `cardio.endurance`
  - Marche rapide — conditioning `ca-marche-rapide`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **vendredi** (30 min, estimé 29 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Bascules en appui doigts vers l'avant — mobility `mo-bascules-appui-doigts-avant`
  - Étirement chaîne postérieure en flexion avant debout — mobility `mo-chaine-posterieure-flexion-avant-debout`
  - Cohérence cardiaque — mobility `mo-coherence-cardiaque`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des fléchisseurs du poignet bras tendu — mobility `mo-etirement-flechisseurs-poignet-bras-tendu`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Marche sur les talons — mobility `mo-marche-talons`
  - Mobilité douce du cou en trois plans — mobility `mo-mobilite-cou-trois-plans`
  - Wall slides dos au mur — mobility `mo-wall-slides`
- **dimanche** (30 min, estimé 27 min) — `mobility`
  - Mobilité hanches 90/90 passive — mobility `mo-90-90-passif`
  - Bascules en appui doigts vers l'avant — mobility `mo-bascules-appui-doigts-avant`
  - Cat-cow — mobility `mo-cat-cow`
  - Mobilisation cheville genou au mur — mobility `mo-cheville-genou-mur`
  - Dislocations d'épaules au bâton — mobility `mo-dislocations-epaules-baton`
  - Étirement des fléchisseurs du poignet bras tendu — mobility `mo-etirement-flechisseurs-poignet-bras-tendu`
  - Étirement des gastrocnémiens au mur jambe tendue — mobility `mo-etirement-gastrocnemiens-mur`
  - Rotation thoracique à quatre pattes main derrière la tête — mobility `mo-rotation-thoracique-quatre-pattes`
  - Thread the needle — mobility `mo-thread-the-needle`
  - Wall slides dos au mur — mobility `mo-wall-slides`

Dosage : cardio 40 % (visé 40 %), mobility 60 % (visé 60 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 0 [0-5], delt_anterior 0 [0-5], delt_middle 0 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 0 [0-5], biceps 0 [0-5], triceps 0 [0-5], abs 0 [0-5], lower_back 0 [0-5], glutes 0 [0-5], quads 0 [0-5], hamstrings 0 [0-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 0 séries ; chaîne postérieure 0 / genou 0 ; schémas de base 0/0.

### Revue simulée

- « Je ne sais pas faire » sur Bascules en appui doigts vers l'avant (`d3.2`) :
  - `exercise_removed` jour 2 : Bascules en appui doigts vers l'avant (plan.reoptimized)
  - `exercise_replaced` jour 3 : Bascules en appui doigts vers l'avant → Pressions des doigts en appui (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par Glissé des avant-bras face au mur (`d2.10`) :
  - `exercise_replaced` jour 2 : Wall slides dos au mur → Glissé des avant-bras face au mur (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Table inversée | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s |
| Marche rapide | 13-15 min | 18-20 min | 18-20 min | 18-20 min |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche rapide | 18-20 min | 22-25 min | 22-25 min | 22-25 min |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Cohérence cardiaque | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s | 3×30-45 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Marche sur les talons | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Mobilité douce du cou en trois plans | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Glissé des avant-bras face au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Mobilité hanches 90/90 passive | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Cat-cow | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Mobilisation cheville genou au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Dislocations d'épaules au bâton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Étirement des fléchisseurs du poignet bras tendu | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Pressions des doigts en appui | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Rotation thoracique à quatre pattes main derrière la tête | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Thread the needle | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |

## 28. `femme_60_musculation_salle_2x45`

Femme de 60 ans, musculation sur machines, 2 × 45 min.

Profil : musculation 80 % + mobility 20 % — mardi 45 min, vendredi 45 min — lieux salle — 70 kg, né en 1966, female, santé standard.

### Passe 1

Note 0.951 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.81 · pattern_balance 0.94 · discipline_structure 0.99 · time_use 1.00 · variety 1.00 · exercise_fit 0.68 · stimulus_fatigue 0.76 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 44 min) — `strength.full_body`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Tirage haut à la machine convergente — secondary `mu-tirage-haut-machine-convergente`
  - Heel touch — core `mu-heel-touch`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
  - Pigeon au sol — cooldown `mo-pigeon-sol`
- **vendredi** (45 min, estimé 44 min) — `strength.full_body`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Rowing inversé à la Smith machine — secondary `mu-rowing-inverse-smith-machine`
  - Reverse hyper sur banc — accessory `mu-reverse-hyper-banc`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Étirement ischio-jambiers allongé à l'élastique — cooldown `mo-ischio-allonge-elastique`

Dosage : musculation 80 % (visé 80 %), mobility 20 % (visé 20 %) — erreur 0.3 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [4-7.5], delt_anterior 6 [4-7.5], delt_middle 0 [4-7.5], delt_posterior 3 [4-7.5], lats 6 [4-7.5], upper_back 6 [4-7.5], biceps 3 [4-7.5], triceps 6 [4-7.5], abs 6 [4-7.5], lower_back 1.5 [4-7.5], glutes 6 [4-7.5], quads 6 [4-7.5], hamstrings 3 [4-7.5], calves 0 [4-7.5]. Groupes majeurs dans leur bande : 62 %.

Équilibre : tirage 6 / poussée 6 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Wall slides dos au mur (`d1.2`) :
  - `exercise_replaced` jour 1 : Wall slides dos au mur → CARs d'épaule (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 1 (plan.reoptimized)
- Remplacement par Développé couché haltères prise neutre (`d1.3`) :
  - `exercise_replaced` jour 1 : Développé couché haltères → Développé couché haltères prise neutre (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Développé couché haltères | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Presse à cuisses 45° | 2×6-10 · 5 fl. · 120s · 35 kg | 3×6-10 · 5 fl. · 120s · 35 kg | 3×6-10 · 6 fl. · 120s · 35 kg | 3×6-10 · 7 fl. · 120s · 35 kg | 2×6-10 · 3 fl. · 120s · 35 kg |
| Tirage haut à la machine convergente | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Heel touch | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |
| Pigeon au sol | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| CARs d'épaule | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Développé couché haltères prise neutre | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing inversé à la Smith machine | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Reverse hyper sur banc | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de jambes tendues suspendu | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Étirement ischio-jambiers allongé à l'élastique | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 29. `homme_40_cardio_musculation_50_50`

Cardio et musculation à parts égales (50/50), 4 × 50 min.

Profil : cardio 50 % + musculation 50 % — lundi 50 min, mercredi 50 min, vendredi 50 min, dimanche 50 min — lieux salle, exterieur — 80 kg, né en 1986, male, santé standard.

### Passe 1

Note 0.971 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.98 · pattern_balance 0.99 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **lundi** (50 min, estimé 48 min) — `strength.pull`
  - Course à allure seuil (tempo run) — conditioning `ca-course-seuil-tempo`
  - Rowing poulie basse assis au triangle — main `mu-rowing-poulie-assis-triangle`
  - Rowing buste penché à la Smith machine — secondary `mu-rowing-smith-machine`
  - Planche RKC — core `mu-planche-rkc`
- **mercredi** (50 min, estimé 50 min) — `strength.full_body`
  - Éducatif de course talons-fesses — conditioning `ca-educatif-talons-fesses`
  - Soulevé de terre jambes tendues — main `mu-souleve-de-terre-jambes-tendues`
  - Développé couché barre — secondary `mu-developpe-couche-barre`
  - Air squat — secondary `mu-air-squat`
  - Tirage haut à la machine convergente — secondary `mu-tirage-haut-machine-convergente`
  - Rowing menton à la poulie — accessory `mu-rowing-menton-poulie`
- **vendredi** (50 min, estimé 50 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **dimanche** (50 min, estimé 49 min) — `strength.full_body`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Soulevé de terre conventionnel — main `mu-souleve-de-terre-conventionnel`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Élévation latérale à la poulie câble derrière le dos — accessory `mu-elevation-laterale-poulie-derriere-dos`
  - V-up — core `mu-v-up`

Dosage : musculation 50 % (visé 50 %), cardio 50 % (visé 50 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 6 [5.5-10.5], delt_anterior 7.5 [5.5-10.5], delt_middle 5 [5.5-10.5], delt_posterior 5.5 [5.5-10.5], lats 9 [5.5-10.5], upper_back 10.5 [5.5-10.5], biceps 6 [5.5-10.5], triceps 6 [5.5-10.5], abs 6 [5.5-10.5], lower_back 6 [5.5-10.5], glutes 9 [5.5-10.5], quads 6 [5.5-10.5], hamstrings 6 [5.5-10.5], calves 3 [5.5-10.5]. Groupes majeurs dans leur bande : 89 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 6 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Corde à sauter sauts simples (`d3.1`) :
  - `exercise_replaced` jour 3 : Corde à sauter sauts simples → Vélo de récupération très léger (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 3 (plan.reoptimized)
- Remplacement par Tirage vertical machine convergente (`d1.5`) :
  - `exercise_replaced` jour 1 : Tirage haut à la machine convergente → Tirage vertical machine convergente (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Course à allure seuil (tempo run) | 13-15 min | 18-20 min | 18-20 min | 18-20 min | 9-10 min |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing buste penché à la Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Planche RKC | 3×10-20 s · 4 fl. · 60s | 4×10-20 s · 4 fl. · 60s | 4×10-20 s · 5 fl. · 60s | 4×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Éducatif de course talons-fesses | 2×30 m · 30s | 3×30 m · 30s | 3×30 m · 30s | 3×30 m · 30s | 2×30 m · 30s |
| Soulevé de terre jambes tendues | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé couché barre | 2×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 5 fl. · 120s · 42.5 kg | 3×6-10 · 6 fl. · 120s · 42.5 kg | 3×6-10 · 7 fl. · 120s · 45 kg | 2×6-10 · 3 fl. · 120s · 42.5 kg |
| Air squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Tirage vertical machine convergente | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing menton à la poulie | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 36-40 min | 40-45 min | 45-50 min | 45-50 min | 27-30 min |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |
| Vélo de récupération très léger | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Élévation latérale à la poulie câble derrière le dos | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| V-up | 2×8-12 · 4 fl. · 60s | 2×8-12 · 4 fl. · 60s | 2×8-12 · 5 fl. · 60s | 2×8-12 · 6 fl. · 60s | 1×8-12 · 2 fl. · 60s |

## 30. `trois_disciplines_70_20_10`

Trois disciplines dosées : musculation 70 %, mobilité 20 %, cardio 10 % (exemple de D3.2).

Profil : musculation 70 % + mobility 20 % + cardio 10 % — lundi 60 min, mercredi 45 min, samedi 90 min — lieux salle — 75 kg, né en 1990, male, santé standard.

### Passe 1

Note 0.970 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.99 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.82 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Rotation interne active de hanche en quadrupédie — warmup `mo-rotation-interne-hanche-quadrupedie`
  - Row australien — main `sw-row-australien`
  - Dips machine assise — secondary `mu-dips-machine-assise`
  - Pont fessier pieds surélevés — accessory `mu-pont-fessier-pieds-sureleves`
  - Lu raise — accessory `mu-lu-raise`
  - Curl biceps aux haltères simultané — accessory `mu-curl-halteres-simultane`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **mercredi** (45 min, estimé 45 min) — `strength.full_body`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Fente marchée aux haltères — main `mu-fente-marchee-halteres`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Pompe classique — secondary `sw-pompe`
  - Oiseau haltères buste penché — accessory `mu-oiseau-halteres`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`
- **samedi** (90 min, estimé 90 min) — `strength.full_body`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Soulevé de terre conventionnel — secondary `mu-souleve-de-terre-conventionnel`
  - Tirage vertical poulie prise serrée supination — secondary `mu-tirage-vertical-prise-serree-supination`
  - Porté au-dessus de la tête (overhead carry) — accessory `mu-overhead-carry`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Sit-up — core `mu-sit-up`
  - Marche de récupération — conditioning `ca-marche-recuperation`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
  - Routine d'auto-massage au rouleau (membres inférieurs et dos) — cooldown `mo-foam-roller-routine`

Dosage : musculation 70 % (visé 70 %), cardio 11 % (visé 10 %), mobility 19 % (visé 20 %) — erreur 1.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 8 [7.5-14.5], delt_anterior 10.5 [7.5-14.5], delt_middle 10.5 [7.5-14.5], delt_posterior 7.5 [7.5-14.5], lats 10 [7.5-14.5], upper_back 12.5 [7.5-14.5], biceps 10 [7.5-14.5], triceps 7.5 [7.5-14.5], abs 7.5 [7.5-14.5], lower_back 9 [7.5-14.5], glutes 12 [7.5-14.5], quads 9 [7.5-14.5], hamstrings 7.5 [7.5-14.5], calves 4.5 [7.5-14.5]. Groupes majeurs dans leur bande : 96 %.

Équilibre : tirage 10 / poussée 6 séries ; chaîne postérieure 6 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Back squat barre haute (`d2.3`) :
  - `exercise_replaced` jour 2 : Back squat barre haute → Squat à la Smith machine (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 2 (plan.reoptimized)
- Remplacement par Porté en rack kettlebell (`d2.6`) :
  - `exercise_replaced` jour 2 : Porté au-dessus de la tête (overhead carry) → Porté en rack kettlebell (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Dips machine assise | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pont fessier pieds surélevés | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Lu raise | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Curl biceps aux haltères simultané | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral sur le coude | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Fente marchée aux haltères | 2×20 m · 4 fl. · 90s | 3×20 m · 4 fl. · 90s | 3×20 m · 5 fl. · 90s | 3×20 m · 6 fl. · 90s | 2×20 m · 2 fl. · 90s |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Pompe classique | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Oiseau haltères buste penché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s | 1×60-90 s · 15s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Rétraction du menton | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Soulevé de terre conventionnel | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Squat à la Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise serrée supination | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Porté en rack kettlebell | 2×30 m · 4 fl. · 90s | 3×30 m · 4 fl. · 90s | 3×30 m · 5 fl. · 90s | 3×30 m · 6 fl. · 90s | 2×30 m · 2 fl. · 90s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Sit-up | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Marche de récupération | 13-15 min | 18-20 min | 18-20 min | 18-20 min | 9-10 min |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Routine d'auto-massage au rouleau (membres inférieurs et dos) | 2×60-90 s · 15s | 2×60-90 s · 15s | 2×60-90 s · 15s | 2×60-90 s · 15s | 1×60-90 s · 15s |

## 31. `niveaux_inconnus_sans_poids`

Aucun niveau connu (« je ne sais pas » partout), poids non renseigné.

Profil : musculation 100 % — mardi 60 min, jeudi 60 min — lieux salle — né en 1995, female, santé not_answered.

### Passe 1

Note 0.973 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.96 · pattern_balance 1.00 · discipline_structure 1.00 · time_use 1.00 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.79 · preferences 1.00 · novelty 1.00.

- **mardi** (60 min, estimé 59 min) — `strength.full_body`
  - Développé couché haltères — main `mu-developpe-couche-halteres`
  - Développé haltères assis — secondary `mu-developpe-halteres-assis`
  - Soulevé de terre kettlebell — secondary `mu-souleve-de-terre-kettlebell`
  - Presse à cuisses 45° — secondary `mu-presse-cuisses-45`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
- **jeudi** (60 min, estimé 58 min) — `strength.full_body`
  - Air squat — main `mu-air-squat`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Leg curl couché — accessory `mu-leg-curl-couche`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Gainage ventral sur les coudes — core `mu-gainage-ventral-coudes`

Dosage : musculation 100 % (visé 100 %) — erreur 0.0 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [4-10], delt_anterior 10 [4-10], delt_middle 5 [4-10], delt_posterior 4.5 [4-10], lats 9 [4-10], upper_back 9 [4-10], biceps 4.5 [4-10], triceps 7.5 [4-10], abs 5 [4-10], lower_back 4.5 [4-10], glutes 9 [4-10], quads 7.5 [4-10], hamstrings 6.5 [4-10], calves 4.5 [4-10]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 9 / poussée 9 séries ; chaîne postérieure 5 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Rowing poulie basse assis au triangle (`d0.5`) :
  - `exercise_replaced` jour 0 : Développé haltères assis → Y raise sur banc incliné (plan.reoptimized)
  - `exercise_replaced` jour 0 : Rowing poulie basse assis au triangle → Rowing buste penché à la Smith machine (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
  - `exercise_removed` jour 1 : Rowing poulie basse assis au triangle (plan.reoptimized)
- Remplacement par Leg curl assis (`d1.6`) :
  - `exercise_replaced` jour 1 : Leg curl couché → Leg curl assis (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Développé couché haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Soulevé de terre kettlebell | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Presse à cuisses 45° | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Rowing buste penché à la Smith machine | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Y raise sur banc incliné | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 3×10-20 s · 3 fl. · 60s | 3×10-20 s · 4 fl. · 60s | 3×10-20 s · 5 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Air squat | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Développé couché Smith machine | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Leg curl assis | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Mollets debout à la machine | CALIBRAGE 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Gainage ventral sur les coudes | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

## 32. `sans_objectif_mode_libre`

Aucun objectif, mode libre.

Profil : street_workout 60 % + musculation 40 % — lundi 60 min, jeudi 60 min, samedi 60 min — lieux salle, exterieur — 92 kg, né en 1983, male, santé standard.

### Passe 1

Note 0.972 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 0.99 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 57 min) — `strength.full_body`
  - Pistol squat debout sur banc — main `sw-pistol-squat-banc`
  - Pompe hindoue — secondary `sw-pompe-hindu`
  - Traction pronation — secondary `sw-traction-pronation`
  - Soulevé de terre kettlebell — secondary `mu-souleve-de-terre-kettlebell`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Porté au-dessus de la tête (overhead carry) — accessory `mu-overhead-carry`
  - Mollets debout à la Smith machine — accessory `mu-mollets-smith`
- **jeudi** (60 min, estimé 57 min) — `strength.upper`
  - Wall walk — skill `cd-wall-walk`
  - HSPU négatif au mur — main `cd-hspu-negatif-mur`
  - Traction pronation — secondary `sw-traction-pronation`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - Turkish get-up — core `mu-turkish-get-up`
- **samedi** (60 min, estimé 57 min) — `strength.full_body`
  - Dips aux barres parallèles — main `sw-dips-barres-paralleles`
  - Pistol squat debout sur banc — secondary `sw-pistol-squat-banc`
  - Pompe en T — secondary `sw-pompe-t`
  - Traction pronation — secondary `sw-traction-pronation`
  - Row australien prise large — secondary `sw-row-australien-large`
  - Reverse hyper à la machine — accessory `mu-reverse-hyper-machine`
  - Planche RKC — core `mu-planche-rkc`

Dosage : musculation 40 % (visé 40 %), streetWorkout 60 % (visé 60 %) — erreur 0.2 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 16 [8-16], delt_anterior 17 [8-16], delt_middle 8.5 [8-16], delt_posterior 13 [8-16], lats 15.5 [8-16], upper_back 16 [8-16], biceps 9.5 [8-16], triceps 15.5 [8-16], abs 10 [8-16], lower_back 6 [8-16], glutes 15 [8-16], quads 10.5 [8-16], hamstrings 9 [8-16], calves 9 [8-16]. Groupes majeurs dans leur bande : 91 %.

Équilibre : tirage 19 / poussée 16 séries ; chaîne postérieure 6 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Mollets debout à la machine (`d1.5`) :
  - `exercise_removed` jour 0 : Mollets debout à la Smith machine (plan.reoptimized)
  - `exercise_replaced` jour 1 : Mollets debout à la machine → Leg curl couché (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Gainage latéral avec abduction de hanche (`d1.6`) :
  - `exercise_replaced` jour 1 : Turkish get-up → Gainage latéral avec abduction de hanche (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Pistol squat debout sur banc | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe hindoue | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Soulevé de terre kettlebell | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Porté au-dessus de la tête (overhead carry) | 3×30 m · 4 fl. · 90s | 4×30 m · 4 fl. · 90s | 4×30 m · 5 fl. · 90s | 4×30 m · 6 fl. · 90s | 2×30 m · 2 fl. · 90s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Wall walk | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| HSPU négatif au mur | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Tirage vertical poulie prise large pronation | CALIBRAGE 3×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 5 fl. · 120s · 70 % 1RM | 4×6-10 · 6 fl. · 120s · 71 % 1RM | 4×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Leg curl couché | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Gainage latéral avec abduction de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Dips aux barres parallèles | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pistol squat debout sur banc | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe en T | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×4-6 · 5 fl. · 90s | 3×4-6 · 5 fl. · 90s | 3×4-6 · 6 fl. · 90s | 3×4-6 · 7 fl. · 90s | 2×4-6 · 3 fl. · 90s |
| Row australien prise large | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Reverse hyper à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Planche RKC | 3×10-20 s · 4 fl. · 60s | 4×10-20 s · 4 fl. · 60s | 4×10-20 s · 5 fl. · 60s | 4×10-20 s · 6 fl. · 60s | 2×10-20 s · 2 fl. · 60s |

## 33. `objectif_habitude_seul`

Un seul objectif d'habitude suggéré par Koach.

Profil : general_fitness 100 % — lundi 30 min, mercredi 30 min, vendredi 30 min — lieux maison — 65 kg, né en 1993, female, santé standard.

### Passe 1

Note 0.936 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.97 · muscle_volume 0.80 · pattern_balance 0.88 · discipline_structure 0.92 · time_use 1.00 · variety 1.00 · exercise_fit 0.64 · stimulus_fatigue 0.80 · preferences 1.00 · novelty 1.00.

- **lundi** (30 min, estimé 29 min) — `strength.full_body`
  - Squat profond tenu — warmup `mo-squat-profond-tenu`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Mountain climbers — core `mu-mountain-climbers`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **mercredi** (30 min, estimé 29 min) — `cardio.endurance`
  - Marche sur les talons — warmup `mo-marche-talons`
  - Fente arrière au poids du corps — main `mu-fente-arriere-poids-du-corps`
  - Marche rapide — conditioning `ca-marche-rapide`
- **vendredi** (30 min, estimé 28 min) — `strength.pull`
  - Rowing assis à l'élastique — main `mu-rowing-elastique-assis`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Marche de récupération — conditioning `ca-marche-recuperation`
  - Sleeper stretch — cooldown `mo-sleeper-stretch`

Dosage : cardio 32 % (visé 35 %), mobility 15 % (visé 15 %), generalFitness 52 % (visé 50 %) — erreur 2.5 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 3 [2-5], delt_anterior 3 [2-5], delt_middle 1 [2-5], delt_posterior 3.5 [2-5], lats 3 [2-5], upper_back 5 [2-5], biceps 2.5 [2-5], triceps 3 [2-5], abs 4 [2-5], lower_back 2 [2-5], glutes 5 [2-5], quads 5 [2-5], hamstrings 2.5 [2-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 3 / poussée 3 séries ; chaîne postérieure 2 / genou 3 ; schémas de base 4/6.

### Revue simulée

- « Je ne sais pas faire » sur Wall slides dos au mur (`d0.2`) :
  - `exercise_replaced` jour 0 : Wall slides dos au mur → CARs d'épaule (plan.user_cannot_do, plan.variant_easier)
  - `order_changed` jour 0 (plan.reoptimized)
- Remplacement par Fente arrière aux haltères (`d1.2`) :
  - `exercise_replaced` jour 1 : Fente arrière au poids du corps → Fente arrière aux haltères (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| CARs d'épaule | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Squat profond tenu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Pompe classique | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Face pull à l'élastique | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Mountain climbers | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche sur les talons | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s |
| Fente arrière aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Marche rapide | 9-10 min | 9-10 min | 9-10 min | 9-10 min |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rowing assis à l'élastique | 2×10-15 · 3 fl. · 90s | 3×10-15 · 3 fl. · 90s | 3×10-15 · 4 fl. · 90s | 3×10-15 · 5 fl. · 90s |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Marche de récupération | 9-10 min | 9-10 min | 9-10 min | 9-10 min |
| Sleeper stretch | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 34. `objectif_figure_front_lever`

Objectif de figure : front lever débloqué.

Profil : calisthenics 60 % + street_workout 40 % — lundi 60 min, mercredi 60 min, vendredi 60 min, samedi 60 min — lieux exterieur — 68 kg, né en 2000, male, santé standard.

### Passe 1

Note 0.958 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.98 · muscle_volume 0.92 · pattern_balance 1.00 · discipline_structure 0.94 · time_use 1.00 · variety 1.00 · exercise_fit 0.70 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 0.75.

- **lundi** (60 min, estimé 55 min) — `strength.pull`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - L-sit aux barres parallèles — skill `cs-l-sit-barres-paralleles`
  - Traction aux anneaux — main `sw-traction-anneaux`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Skater squat — secondary `sw-skater-squat`
  - Planche RKC — core `mu-planche-rkc`
- **mercredi** (60 min, estimé 56 min) — `skills`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - Front lever raise tuck — skill `cd-front-lever-raise-tuck`
  - Handstand libre — skill `cs-handstand`
  - L-sit aux barres parallèles — skill `cs-l-sit-barres-paralleles`
  - Gainage latéral avec relevés de hanche — core `mu-gainage-lateral-releves-hanche`
- **vendredi** (60 min, estimé 55 min) — `strength.pull`
  - Front lever tuck — skill `cs-front-lever-tuck`
  - Tenue haute false grip aux anneaux — skill `cs-tenue-haute-false-grip-anneaux`
  - Traction pronation — main `sw-traction-pronation`
  - Pont fessier unilatéral — accessory `mu-pont-fessier-unilateral`
  - Hip airplane — accessory `mu-hip-airplane`
  - Arch rocks — core `mu-arch-rocks`
- **samedi** (60 min, estimé 55 min) — `skills`
  - Planche tuck — skill `cs-planche-tuck`
  - Handstand libre — skill `cs-handstand`
  - L-sit aux barres parallèles — skill `cs-l-sit-barres-paralleles`
  - HSPU au mur amplitude réduite sur coussin — main `cd-hspu-mur-amplitude-reduite`
  - Pompe hindoue — secondary `sw-pompe-hindu`
  - Windshield wiper suspendu genoux fléchis — core `sw-windshield-wiper-tuck`

Dosage : streetWorkout 40 % (visé 40 %), calisthenics 60 % (visé 60 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 14.5 [8-16], delt_anterior 16 [8-16], delt_middle 8 [8-16], delt_posterior 12 [8-16], lats 19 [8-16], upper_back 16.5 [8-16], biceps 8 [8-16], triceps 17.5 [8-16], abs 16.5 [8-16], lower_back 7 [8-16], glutes 9 [8-16], quads 9 [8-16], hamstrings 4.5 [8-16], calves 0 [0-16]. Groupes majeurs dans leur bande : 56 %.

Équilibre : tirage 26 / poussée 22 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Arch rocks (`d2.6`) :
  - `exercise_replaced` jour 2 : Arch rocks → Arch hold (plan.user_cannot_do, plan.variant_easier)
- Remplacement par L-sit au sol (`d1.4`) :
  - `exercise_replaced` jour 1 : L-sit aux barres parallèles → L-sit au sol (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | TEST 2×1-22 s · 10 fl. · 180s |
| L-sit aux barres parallèles | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Traction aux anneaux | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Dips aux barres parallèles | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Skater squat | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Planche RKC | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Front lever raise tuck | 3×2-5 · 4 fl. · 150s | 4×2-5 · 4 fl. · 150s | 4×2-5 · 5 fl. · 150s | 4×2-5 · 6 fl. · 150s | 2×2-5 · 2 fl. · 150s |
| Handstand libre | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| L-sit au sol | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| Gainage latéral avec relevés de hanche | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Front lever tuck | 3×7-11 s · 4 fl. · 120s | 4×7-11 s · 4 fl. · 120s | 4×7-11 s · 5 fl. · 120s | 4×7-11 s · 6 fl. · 120s | 2×7-11 s · 2 fl. · 120s |
| Tenue haute false grip aux anneaux | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Traction pronation | 2×6-9 · 5 fl. · 90s | 3×6-9 · 5 fl. · 90s | 3×6-9 · 6 fl. · 90s | 3×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Pont fessier unilatéral | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Arch hold | 2×20-40 s · 4 fl. · 60s | 3×20-40 s · 4 fl. · 60s | 3×20-40 s · 5 fl. · 60s | 3×20-40 s · 6 fl. · 60s | 2×20-40 s · 2 fl. · 60s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Planche tuck | 4×5-10 s · 4 fl. · 120s | 5×5-10 s · 4 fl. · 120s | 5×5-10 s · 5 fl. · 120s | 5×5-10 s · 6 fl. · 120s | 3×5-10 s · 2 fl. · 120s |
| Handstand libre | 3×5-10 s · 4 fl. · 120s | 4×5-10 s · 4 fl. · 120s | 4×5-10 s · 5 fl. · 120s | 4×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| L-sit aux barres parallèles | 3×10-20 s · 4 fl. · 120s | 4×10-20 s · 4 fl. · 120s | 4×10-20 s · 5 fl. · 120s | 4×10-20 s · 6 fl. · 120s | 2×10-20 s · 2 fl. · 120s |
| HSPU au mur amplitude réduite sur coussin | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Pompe hindoue | 2×10-15 · 5 fl. · 90s | 2×10-15 · 5 fl. · 90s | 2×10-15 · 6 fl. · 90s | 2×10-15 · 7 fl. · 90s | 1×10-15 · 3 fl. · 90s |
| Windshield wiper suspendu genoux fléchis | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |

## 35. `semi_marathon`

Objectif de temps sur semi-marathon.

Profil : cardio 80 % + mobility 10 % + musculation 10 % — mardi 60 min, jeudi 60 min, samedi 45 min, dimanche 120 min — lieux exterieur — 59 kg, né en 1990, female, santé standard.

### Passe 1

Note 0.951 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.92 · muscle_volume 0.88 · pattern_balance 1.00 · discipline_structure 0.97 · time_use 1.00 · variety 1.00 · exercise_fit 0.66 · stimulus_fatigue 0.75 · preferences 1.00 · novelty 1.00.

- **mardi** (60 min, estimé 58 min) — `strength.full_body`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
  - Cossack squat — main `mu-cossack-squat`
  - Pompe hindoue — secondary `sw-pompe-hindu`
  - Nordic hamstring curl négatif — accessory `mu-nordic-hamstring-curl-negatif`
  - Planche RKC — core `mu-planche-rkc`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **jeudi** (60 min, estimé 60 min) — `cardio.endurance`
  - Footing en endurance fondamentale — conditioning `ca-footing-endurance-fondamentale`
- **samedi** (45 min, estimé 45 min) — `cardio.intervals`
  - Fractionné 400 m — conditioning `ca-fractionne-400m`
  - Hip airplane — accessory `mu-hip-airplane`
  - Relevé de jambes allongé au sol — core `mu-releve-jambes-allonge`
  - V-up — core `mu-v-up`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **dimanche** (120 min, estimé 120 min) — `cardio.endurance`
  - Sortie longue en course à pied — conditioning `ca-sortie-longue`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Pompe pike — main `sw-pompe-pike`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`

Dosage : musculation 15 % (visé 10 %), cardio 78 % (visé 80 %), mobility 6 % (visé 10 %) — erreur 5.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 5 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 1 [0-5], delt_posterior 0 [0-5], lats 0 [0-5], upper_back 1 [0-5], biceps 0 [0-5], triceps 5 [1.5-5], abs 5 [1.5-5], lower_back 1.5 [1.5-5], glutes 4 [1.5-5], quads 4 [1.5-5], hamstrings 3 [1.5-5], calves 2 [0-5]. Groupes majeurs dans leur bande : 100 %.

Équilibre : tirage 0 / poussée 5 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 4/4.

### Revue simulée

- « Je ne sais pas faire » sur Planche RKC (`d0.6`) :
  - `exercise_replaced` jour 0 : Planche RKC → Gainage ventral sur les coudes (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Étirement fessier en figure 4 allongé (`d3.4`) :
  - `exercise_replaced` jour 3 : Mobilité hanches 90/90 passive → Étirement fessier en figure 4 allongé (plan.user_replaced)
  - `order_changed` jour 3 (plan.reoptimized)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Wall slides dos au mur | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Footing en endurance fondamentale | 22-25 min | 22-25 min | 27-30 min | 27-30 min | 18-20 min |
| Cossack squat | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| Pompe hindoue | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Nordic hamstring curl négatif | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Gainage ventral sur les coudes | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 4 fl. · 60s | 1×20-40 s · 5 fl. · 60s | 1×20-40 s · 6 fl. · 60s | 1×20-40 s · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 3×20-30 s · 10s | 2×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Footing en endurance fondamentale | 40-45 min | 49-55 min | 49-55 min | 54-60 min | 31-35 min |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Fractionné 400 m | 4×400 m · 114s | 5×400 m · 114s | 5×400 m · 114s | 5×400 m · 114s | 3×400 m · 114s |
| Hip airplane | 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Relevé de jambes allongé au sol | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| V-up | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (test) |
| --- | --- | --- | --- | --- | --- |
| Sortie longue en course à pied | 63-70 min | 76-85 min | 81-90 min | 85-95 min | TEST 1×21097.5 m |
| Corde à sauter sauts simples | 5×45-60 s · 30s | 5×45-60 s · 30s | 6×45-60 s · 30s | 6×45-60 s · 30s | 4×45-60 s · 30s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 2×6-12 · 5 fl. · 90s | 2×6-12 · 6 fl. · 90s | 2×6-12 · 7 fl. · 90s | 1×6-12 · 3 fl. · 90s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement fessier en figure 4 allongé | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 36. `prudent_sante_musculation`

Questionnaire santé en mode prudent, musculation légère.

Profil : musculation 60 % + cardio 40 % — lundi 45 min, jeudi 45 min — lieux salle — 89 kg, né en 1970, male, santé cautious.

### Passe 1

Note 0.943 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.93 · muscle_volume 0.75 · pattern_balance 0.94 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.67 · stimulus_fatigue 0.88 · preferences 1.00 · novelty 1.00.

- **lundi** (45 min, estimé 43 min) — `strength.full_body`
  - Soulevé de terre kettlebell — main `mu-souleve-de-terre-kettlebell`
  - Air squat — secondary `mu-air-squat`
  - Pompe classique — secondary `sw-pompe`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Tirage bras tendus poulie haute à la barre — accessory `mu-tirage-bras-tendus-poulie-barre`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
- **jeudi** (45 min, estimé 44 min) — `cardio.endurance`
  - Tirage vertical poulie prise large pronation — main `mu-tirage-vertical-prise-large-pronation`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Vélo en endurance — conditioning `ca-velo-endurance`

Dosage : musculation 67 % (visé 60 %), cardio 33 % (visé 40 %) — erreur 7.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 4 [2.5-6], delt_anterior 4.5 [2.5-6], delt_middle 3 [2.5-6], delt_posterior 2.5 [2.5-6], lats 5 [2.5-6], upper_back 2.5 [2.5-6], biceps 3 [2.5-6], triceps 4 [2.5-6], abs 4 [2.5-6], lower_back 5.5 [2.5-6], glutes 6 [2.5-6], quads 4.5 [2.5-6], hamstrings 3 [2.5-6], calves 1.5 [2.5-6]. Groupes majeurs dans leur bande : 96 %.

Équilibre : tirage 5 / poussée 3 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Air squat (`d0.2`) :
  - `exercise_replaced` jour 0 : Air squat → Belt squat (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Soulevé de terre roumain aux haltères (`d0.1`) :
  - `exercise_replaced` jour 0 : Soulevé de terre kettlebell → Soulevé de terre roumain aux haltères (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Soulevé de terre roumain aux haltères | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Belt squat | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Pompe classique | 2×3-8 · 3 fl. · 90s | 3×3-8 · 3 fl. · 90s | 3×3-8 · 4 fl. · 90s | 3×3-8 · 5 fl. · 90s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Tirage bras tendus poulie haute à la barre | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Gainage latéral bras tendu | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM |
| Gainage latéral sur le coude | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 3 fl. · 60s | 2×10-20 s · 4 fl. · 60s | 2×10-20 s · 5 fl. · 60s |
| Vélo en endurance | 18-20 min | 22-25 min | 22-25 min | 22-25 min |

## 37. `tres_grand_lourd`

Grand gabarit : 198 cm, 130 kg.

Profil : musculation 70 % + cardio 30 % — lundi 60 min, mercredi 60 min, vendredi 60 min — lieux salle — 130 kg, né en 1992, male, santé standard.

### Passe 1

Note 0.967 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.99 · muscle_volume 0.94 · pattern_balance 1.00 · discipline_structure 0.98 · time_use 1.00 · variety 1.00 · exercise_fit 0.71 · stimulus_fatigue 0.79 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 60 min) — `strength.full_body`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Dips aux barres parallèles — secondary `sw-dips-barres-paralleles`
  - Rowing poulie basse assis prise large pronation — secondary `mu-rowing-poulie-assis-prise-large`
  - Reverse hyper sur banc — accessory `mu-reverse-hyper-banc`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Pallof press debout — core `mu-pallof-press-debout`
  - V-up — core `mu-v-up`
- **mercredi** (60 min, estimé 59 min) — `cardio.endurance`
  - Tirage vertical poulie prise large pronation — main `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Vélo en endurance — conditioning `ca-velo-endurance`
- **vendredi** (60 min, estimé 60 min) — `strength.full_body`
  - Back squat barre basse — main `mu-back-squat-barre-basse`
  - Row australien — secondary `sw-row-australien`
  - Hip thrust à la barre — accessory `mu-hip-thrust-barre`
  - Lu raise — accessory `mu-lu-raise`
  - Élévation frontale haltères — accessory `mu-elevation-frontale-halteres`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Vélo en endurance — conditioning `ca-velo-endurance`

Dosage : musculation 72 % (visé 70 %), cardio 28 % (visé 30 %) — erreur 2.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [6.5-13.5], delt_anterior 12.5 [6.5-13.5], delt_middle 7 [6.5-13.5], delt_posterior 8.5 [6.5-13.5], lats 8 [6.5-13.5], upper_back 12 [6.5-13.5], biceps 6.5 [6.5-13.5], triceps 6 [6.5-13.5], abs 9 [6.5-13.5], lower_back 5 [6.5-13.5], glutes 13 [6.5-13.5], quads 7.5 [6.5-13.5], hamstrings 5 [6.5-13.5], calves 3 [6.5-13.5]. Groupes majeurs dans leur bande : 76 %.

Équilibre : tirage 10 / poussée 6 séries ; chaîne postérieure 7 / genou 6 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Woodchop à la poulie haut vers bas (`d2.6`) :
  - `exercise_replaced` jour 2 : Woodchop à la poulie haut vers bas → Rotation du tronc à la poulie assis (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Row australien aux barres parallèles (`d2.2`) :
  - `exercise_replaced` jour 2 : Row australien → Row australien aux barres parallèles (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 2×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 5 fl. · 120s · 87.5 kg | 3×6-10 · 6 fl. · 120s · 87.5 kg | 3×6-10 · 7 fl. · 120s · 90 kg | 2×6-10 · 3 fl. · 120s · 85 kg |
| Dips aux barres parallèles | 2×3-8 · 5 fl. · 90s | 3×3-8 · 5 fl. · 90s | 3×3-8 · 6 fl. · 90s | 3×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Rowing poulie basse assis prise large pronation | CALIBRAGE 3×8-12 · 3 fl. · 120s | 4×8-12 · 3 fl. · 120s | 4×8-12 · 4 fl. · 120s | 4×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Reverse hyper sur banc | 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Pallof press debout | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| V-up | 2×8-12 · 4 fl. · 60s | 3×8-12 · 4 fl. · 60s | 3×8-12 · 5 fl. · 60s | 3×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×8-12 · 3 fl. · 120s | 3×8-12 · 3 fl. · 120s | 3×8-12 · 4 fl. · 120s | 3×8-12 · 5 fl. · 120s · 67 % 1RM | 2×8-12 · 1 fl. · 120s |
| Développé couché Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Vélo en endurance | 22-25 min | 27-30 min | 31-35 min | 31-35 min | 18-20 min |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre basse | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Row australien aux barres parallèles | 2×6-12 · 3 fl. · 90s | 3×6-12 · 3 fl. · 90s | 3×6-12 · 4 fl. · 90s | 3×6-12 · 5 fl. · 90s | 2×6-12 · 1 fl. · 90s |
| Hip thrust à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Lu raise | CALIBRAGE 3×10-15 · 5 fl. · 75s | 4×10-15 · 5 fl. · 75s | 4×10-15 · 6 fl. · 75s | 4×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Élévation frontale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Rotation du tronc à la poulie assis | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Vélo en endurance | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |

## 38. `petite_legere`

Petit gabarit : 150 cm, 45 kg.

Profil : street_workout 70 % + mobility 30 % — mardi 45 min, jeudi 45 min, samedi 45 min — lieux exterieur, maison — 45 kg, né en 1999, female, santé standard.

### Passe 1

Note 0.958 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.89 · pattern_balance 1.00 · discipline_structure 0.95 · time_use 0.97 · variety 1.00 · exercise_fit 0.69 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **mardi** (45 min, estimé 36 min) — `strength.full_body`
  - Rocking des adducteurs en quadrupédie — warmup `mo-adducteurs-rocking`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Skater squat — main `sw-skater-squat`
  - Row australien — secondary `sw-row-australien`
  - Traction sautée — secondary `sw-traction-sautee`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **jeudi** (45 min, estimé 36 min) — `strength.full_body`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Routine mobilité épaules et poignets — warmup `mo-routine-mobilite-epaules-poignets`
  - Pompe classique — main `sw-pompe`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Pike assis passif — cooldown `mo-pike-assis-passif`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
- **samedi** (45 min, estimé 36 min) — `strength.upper`
  - CARs de hanche — warmup `mo-cars-hanche`
  - Pompe pike — main `sw-pompe-pike`
  - Traction pronation — secondary `sw-traction-pronation`
  - Face pull à l'élastique — accessory `mu-face-pull-elastique`
  - Knees-to-elbows — core `sw-knees-to-elbows`
  - Pont dorsal au sol — cooldown `mo-pont-dorsal`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`

Dosage : streetWorkout 70 % (visé 70 %), mobility 30 % (visé 30 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 7.5 [5-10], delt_anterior 6 [5-10], delt_middle 3 [5-10], delt_posterior 7.5 [5-10], lats 9 [5-10], upper_back 10.5 [5-10], biceps 6 [5-10], triceps 6 [5-10], abs 6 [5-10], lower_back 0 [5-10], glutes 7.5 [5-10], quads 7.5 [5-10], hamstrings 3 [5-10], calves 0 [0-10]. Groupes majeurs dans leur bande : 71 %.

Équilibre : tirage 9 / poussée 6 séries ; chaîne postérieure 3 / genou 3 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Relevé de jambes tendues suspendu (`d1.5`) :
  - `exercise_replaced` jour 1 : Relevé de jambes tendues suspendu → Flutter kicks (plan.user_cannot_do, plan.variant_easier)
  - `exercise_added` jour 2 → Relevé de genoux oblique suspendu (plan.reoptimized)
  - `exercise_removed` jour 2 : Knees-to-elbows (plan.reoptimized)
- Remplacement par Windshield wiper suspendu genoux fléchis (`d2.8`) :
  - `exercise_replaced` jour 2 : Relevé de genoux oblique suspendu → Windshield wiper suspendu genoux fléchis (plan.user_replaced)

### Passe 2

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Rocking des adducteurs en quadrupédie | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Skater squat | 3×3-8 · 5 fl. · 90s | 4×3-8 · 5 fl. · 90s | 4×3-8 · 6 fl. · 90s | 4×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Row australien | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Traction sautée | 2×10-15 · 5 fl. · 90s | 3×10-15 · 5 fl. · 90s | 3×10-15 · 6 fl. · 90s | 3×10-15 · 7 fl. · 90s | 2×10-15 · 3 fl. · 90s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Rétraction du menton | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 2×8-12 · 10s |
| Routine mobilité épaules et poignets | 4-5 min | 4-5 min | 4-5 min | 4-5 min | 4-5 min |
| Pompe classique | 3×6-9 · 5 fl. · 90s | 4×6-9 · 5 fl. · 90s | 4×6-9 · 6 fl. · 90s | 4×6-9 · 7 fl. · 90s | 2×6-9 · 3 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Flutter kicks | 2×10-15 · 4 fl. · 60s | 2×10-15 · 4 fl. · 60s | 2×10-15 · 5 fl. · 60s | 2×10-15 · 6 fl. · 60s | 1×10-15 · 2 fl. · 60s |
| Pike assis passif | 3×30-45 s · 10s | 4×30-45 s · 10s | 4×30-45 s · 10s | 4×30-45 s · 10s | 2×30-45 s · 10s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| CARs de hanche | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 1×8-12 · 10s |
| Pompe pike | 3×3-8 · 5 fl. · 90s | 4×3-8 · 5 fl. · 90s | 4×3-8 · 6 fl. · 90s | 4×3-8 · 7 fl. · 90s | 2×3-8 · 3 fl. · 90s |
| Traction pronation | 2×1-2 · 5 fl. · 90s | 3×1-2 · 5 fl. · 90s | 3×1-2 · 6 fl. · 90s | 3×1-2 · 7 fl. · 90s | 2×1-2 · 3 fl. · 90s |
| Face pull à l'élastique | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Windshield wiper suspendu genoux fléchis | 3×8-12 · 4 fl. · 60s | 4×8-12 · 4 fl. · 60s | 4×8-12 · 5 fl. · 60s | 4×8-12 · 6 fl. · 60s | 2×8-12 · 2 fl. · 60s |
| Pont dorsal au sol | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 2×30-45 s · 10s | 1×30-45 s · 10s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 1×20-30 s · 10s |

## 39. `sept_jours_courts_7x20`

Tous les jours, 20 min.

Profil : general_fitness 50 % + mobility 30 % + cardio 20 % — lundi 20 min, mardi 20 min, mercredi 20 min, jeudi 20 min, vendredi 20 min, samedi 20 min, dimanche 20 min — lieux maison — 76 kg, né en 1984, male, santé standard.

### Passe 1

Note 0.943 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 0.88 · muscle_volume 0.95 · pattern_balance 0.94 · discipline_structure 0.95 · time_use 1.00 · variety 1.00 · exercise_fit 0.56 · stimulus_fatigue 0.83 · preferences 1.00 · novelty 1.00.

- **lundi** (20 min, estimé 18 min) — `strength.full_body`
  - Tirage vertical à l'élastique — main `mu-tirage-vertical-elastique`
  - Pont fessier au sol — accessory `mu-pont-fessier-sol`
  - Gainage latéral bras tendu — core `mu-gainage-lateral-bras-tendu`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
- **mardi** (20 min, estimé 20 min) — `mobility`
  - Lift-off en rotation externe 90/90 allongé ventral — warmup `mo-lift-off-rotation-externe-90-90`
  - Rétraction du menton — warmup `mo-retraction-menton`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
- **mercredi** (20 min, estimé 20 min) — `strength.upper`
  - World's greatest stretch — warmup `mo-worlds-greatest-stretch`
  - Pompe classique — main `sw-pompe`
  - Tirage bras tendus à l'élastique — accessory `mu-tirage-bras-tendus-elastique`
  - Soupir physiologique — cooldown `mo-soupir-physiologique`
- **jeudi** (20 min, estimé 19 min) — `mobility`
  - CARs de hanche — warmup `mo-cars-hanche`
  - Squat profond tenu — warmup `mo-squat-profond-tenu`
  - Table inversée — warmup `mo-table-inversee`
  - Fente latérale — main `mu-fente-laterale`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
- **vendredi** (20 min, estimé 20 min) — `cardio.endurance`
  - Marche rapide — conditioning `ca-marche-rapide`
- **samedi** (20 min, estimé 20 min) — `mobility`
  - Table inversée — warmup `mo-table-inversee`
  - Gainage latéral sur le coude — core `mu-gainage-lateral-coude`
  - Mountain climbers — core `mu-mountain-climbers`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Mobilité hanches 90/90 passive — cooldown `mo-90-90-passif`
  - Étirement chaîne postérieure en flexion avant debout — cooldown `mo-chaine-posterieure-flexion-avant-debout`
  - Étirement des gastrocnémiens au mur jambe tendue — cooldown `mo-etirement-gastrocnemiens-mur`
- **dimanche** (20 min, estimé 20 min) — `mobility`
  - Cercles de bras — warmup `mo-cercles-bras`
  - Marche sur les talons — warmup `mo-marche-talons`
  - Wall slides dos au mur — warmup `mo-wall-slides`
  - Pompe contre le mur — main `sw-pompe-murale`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Étirement en chiot (ouverture d'épaules au sol) — cooldown `mo-etirement-chiot`

Dosage : cardio 25 % (visé 38 %), mobility 38 % (visé 38 %), generalFitness 37 % (visé 25 %) — erreur 12.4 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 4 [1.5-5], delt_anterior 5 [1.5-5], delt_middle 2 [1.5-5], delt_posterior 1.5 [1.5-5], lats 5 [1.5-5], upper_back 2.5 [1.5-5], biceps 2 [1.5-5], triceps 5.5 [1.5-5], abs 4 [1.5-5], lower_back 3 [1.5-5], glutes 4 [1.5-5], quads 3 [1.5-5], hamstrings 2 [1.5-5], calves 0 [0-5]. Groupes majeurs dans leur bande : 93 %.

Équilibre : tirage 5 / poussée 4 séries ; chaîne postérieure 2 / genou 2 ; schémas de base 5/6.

### Revue simulée

- « Je ne sais pas faire » sur Gainage latéral bras tendu (`d0.3`) :
  - `exercise_replaced` jour 0 : Gainage latéral bras tendu → Gainage latéral sur les genoux (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Rotation interne active de hanche en quadrupédie (`d3.1`) :
  - `exercise_replaced` jour 3 : CARs de hanche → Rotation interne active de hanche en quadrupédie (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Tirage vertical à l'élastique | 2×10-15 · 3 fl. · 90s | 2×10-15 · 3 fl. · 90s | 2×10-15 · 4 fl. · 90s | 2×10-15 · 5 fl. · 90s |
| Pont fessier au sol | 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Gainage latéral sur les genoux | 2×20-40 s · 3 fl. · 60s | 2×20-40 s · 3 fl. · 60s | 2×20-40 s · 4 fl. · 60s | 2×20-40 s · 5 fl. · 60s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Lift-off en rotation externe 90/90 allongé ventral | 2×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s | 3×8-12 · 10s |
| Rétraction du menton | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 3 fl. · 75s | 2×10-15 · 3 fl. · 75s | 2×10-15 · 4 fl. · 75s | 2×10-15 · 5 fl. · 75s |
| Corde à sauter sauts simples | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s |

mercredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| World's greatest stretch | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe classique | 2×6-12 · 3 fl. · 90s | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s |
| Tirage bras tendus à l'élastique | 2×10-15 · 3 fl. · 75s | 3×10-15 · 3 fl. · 75s | 3×10-15 · 4 fl. · 75s | 3×10-15 · 5 fl. · 75s |
| Soupir physiologique | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s | 1×120-180 s · 15s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Rotation interne active de hanche en quadrupédie | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Squat profond tenu | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Table inversée | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s | 1×8-12 · 10s |
| Fente latérale | 2×6-12 · 3 fl. · 90s | 2×6-12 · 3 fl. · 90s | 2×6-12 · 4 fl. · 90s | 2×6-12 · 5 fl. · 90s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Marche rapide | 13-15 min | 18-20 min | 18-20 min | 18-20 min |

samedi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Table inversée | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Gainage latéral sur le coude | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Mountain climbers | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 3 fl. · 60s | 1×10-20 s · 4 fl. · 60s | 1×10-20 s · 5 fl. · 60s |
| Corde à sauter sauts simples | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s |
| Mobilité hanches 90/90 passive | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement chaîne postérieure en flexion avant debout | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Étirement des gastrocnémiens au mur jambe tendue | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

dimanche :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) |
| --- | --- | --- | --- | --- |
| Cercles de bras | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Marche sur les talons | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |
| Wall slides dos au mur | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s | 2×8-12 · 10s |
| Pompe contre le mur | 2×10-15 · 3 fl. · 90s | 2×10-15 · 3 fl. · 90s | 2×10-15 · 4 fl. · 90s | 2×10-15 · 5 fl. · 90s |
| Corde à sauter sauts simples | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s | 2×45-60 s · 30s |
| Étirement en chiot (ouverture d'épaules au sol) | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s | 2×20-30 s · 10s |

## 40. `materiel_complet_gouts_marques`

Salle complète, nombreux exercices aimés et détestés.

Profil : musculation 60 % + street_workout 20 % + cardio 20 % — lundi 60 min, mardi 60 min, jeudi 60 min, vendredi 60 min — lieux salle, maison, exterieur — 68 kg, né en 1994, female, santé standard.

### Passe 1

Note 0.969 — recovery 1.00 · fatigue_balance 1.00 · joint_load 1.00 · goal_specificity 1.00 · discipline_dosage 1.00 · muscle_volume 0.99 · pattern_balance 0.99 · discipline_structure 0.95 · time_use 1.00 · variety 1.00 · exercise_fit 0.72 · stimulus_fatigue 0.81 · preferences 1.00 · novelty 1.00.

- **lundi** (60 min, estimé 59 min) — `strength.lower`
  - Back squat barre haute — main `mu-back-squat-barre-haute`
  - Épaulé au sac lesté — accessory `mu-epaule-sac-leste`
  - Hip thrust à la barre — accessory `mu-hip-thrust-barre`
  - Mollets debout à la machine — accessory `mu-mollets-debout-machine`
  - V-up — core `mu-v-up`
  - Woodchop à la poulie haut vers bas — core `mu-woodchop-haut-bas`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
- **mardi** (60 min, estimé 60 min) — `strength.upper`
  - Dips aux barres parallèles — main `sw-dips-barres-paralleles`
  - Pompe pike — secondary `sw-pompe-pike`
  - Row australien pieds surélevés — secondary `sw-row-australien-pieds-sureleves`
  - Traction pronation — secondary `sw-traction-pronation`
  - Écarté poulie vis-à-vis milieu — accessory `mu-ecarte-poulie-vis-a-vis-milieu`
  - Élévation latérale haltères — accessory `mu-elevation-laterale-halteres`
  - Relevé de jambes tendues suspendu — core `sw-releve-jambes-tendues-suspendu`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
- **jeudi** (60 min, estimé 59 min) — `strength.pull`
  - Clutch flag — skill `cs-clutch-flag`
  - Face pull à la poulie corde — main `mu-face-pull-corde`
  - Rowing poulie basse assis au triangle — secondary `mu-rowing-poulie-assis-triangle`
  - Tirage vertical poulie prise large pronation — secondary `mu-tirage-vertical-prise-large-pronation`
  - Développé couché Smith machine — secondary `mu-developpe-couche-smith`
  - Corde à sauter en croisés — conditioning `ca-corde-croises`
- **vendredi** (60 min, estimé 57 min) — `strength.lower`
  - Soulevé de terre roumain à la barre — main `mu-souleve-de-terre-roumain-barre`
  - Mollets donkey — accessory `mu-mollets-donkey`
  - Rowing menton haltères — accessory `mu-rowing-menton-halteres`
  - Turkish get-up — core `mu-turkish-get-up`
  - Corde à sauter sauts simples — conditioning `ca-corde-sauts-simples`
  - Rameur en endurance — conditioning `ca-rameur-endurance`

Dosage : musculation 60 % (visé 60 %), streetWorkout 20 % (visé 20 %), cardio 20 % (visé 20 %) — erreur 0.1 points.

Volume hebdomadaire (séries fractionnaires [bande]) : chest 14.5 [8-16], delt_anterior 13.5 [8-16], delt_middle 9 [8-16], delt_posterior 10.5 [8-16], lats 15.5 [8-16], upper_back 16.5 [8-16], biceps 11.5 [8-16], triceps 9 [8-16], abs 14 [8-16], lower_back 8.5 [8-16], glutes 17 [8-16], quads 14.5 [8-16], hamstrings 7.5 [8-16], calves 8 [8-16]. Groupes majeurs dans leur bande : 73 %.

Équilibre : tirage 15 / poussée 12 séries ; chaîne postérieure 6 / genou 4 ; schémas de base 6/6.

### Revue simulée

- « Je ne sais pas faire » sur Corde à sauter en croisés (`d2.6`) :
  - `exercise_replaced` jour 2 : Corde à sauter en croisés → Corde à sauter sauts simples (plan.user_cannot_do, plan.variant_easier)
- Remplacement par Row archer (`d1.3`) :
  - `exercise_replaced` jour 1 : Row australien pieds surélevés → Row archer (plan.user_replaced)

### Passe 2

lundi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Back squat barre haute | 3×6-10 · 5 fl. · 120s · 52.5 kg | 4×6-10 · 5 fl. · 120s · 52.5 kg | 4×6-10 · 6 fl. · 120s · 52.5 kg | 4×6-10 · 7 fl. · 120s · 52.5 kg | 2×6-10 · 3 fl. · 120s · 50 kg |
| Épaulé au sac lesté | 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Hip thrust à la barre | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Mollets debout à la machine | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| V-up | 3×10-15 · 4 fl. · 60s | 4×10-15 · 4 fl. · 60s | 4×10-15 · 5 fl. · 60s | 4×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Woodchop à la poulie haut vers bas | CALIBRAGE 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 3×45-60 s · 30s |

mardi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Dips aux barres parallèles | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Pompe pike | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Row archer | 2×6-12 · 5 fl. · 90s | 3×6-12 · 5 fl. · 90s | 3×6-12 · 6 fl. · 90s | 3×6-12 · 7 fl. · 90s | 2×6-12 · 3 fl. · 90s |
| Traction pronation | 2×2-3 · 5 fl. · 90s | 3×2-3 · 5 fl. · 90s | 3×2-3 · 6 fl. · 90s | 3×2-3 · 7 fl. · 90s | 2×2-3 · 3 fl. · 90s |
| Écarté poulie vis-à-vis milieu | CALIBRAGE 2×10-15 · 5 fl. · 75s | 2×10-15 · 5 fl. · 75s | 2×10-15 · 6 fl. · 75s | 2×10-15 · 7 fl. · 75s | 1×10-15 · 3 fl. · 75s |
| Élévation latérale haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Relevé de jambes tendues suspendu | 2×10-15 · 4 fl. · 60s | 3×10-15 · 4 fl. · 60s | 3×10-15 · 5 fl. · 60s | 3×10-15 · 6 fl. · 60s | 2×10-15 · 2 fl. · 60s |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 3×45-60 s · 30s |

jeudi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Clutch flag | 2×5-10 s · 4 fl. · 120s | 3×5-10 s · 4 fl. · 120s | 3×5-10 s · 5 fl. · 120s | 3×5-10 s · 6 fl. · 120s | 2×5-10 s · 2 fl. · 120s |
| Face pull à la poulie corde | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Rowing poulie basse assis au triangle | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Tirage vertical poulie prise large pronation | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Développé couché Smith machine | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 3×45-60 s · 30s |

vendredi :

| Exercice | S1 (intro) | S2 (build) | S3 (build) | S4 (build) | S5 (deload) |
| --- | --- | --- | --- | --- | --- |
| Soulevé de terre roumain à la barre | CALIBRAGE 2×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 5 fl. · 120s · 70 % 1RM | 3×6-10 · 6 fl. · 120s · 71 % 1RM | 3×6-10 · 7 fl. · 120s · 71 % 1RM | 2×6-10 · 3 fl. · 120s · 68 % 1RM |
| Mollets donkey | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Rowing menton haltères | CALIBRAGE 2×10-15 · 5 fl. · 75s | 3×10-15 · 5 fl. · 75s | 3×10-15 · 6 fl. · 75s | 3×10-15 · 7 fl. · 75s | 2×10-15 · 3 fl. · 75s |
| Turkish get-up | CALIBRAGE 2×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 3 fl. · 90s · 79 % 1RM | 3×2-4 · 4 fl. · 90s · 80 % 1RM | 3×2-4 · 5 fl. · 90s · 81 % 1RM | 2×2-4 · 1 fl. · 90s · 77 % 1RM |
| Corde à sauter sauts simples | 4×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 5×45-60 s · 30s | 3×45-60 s · 30s |
| Rameur en endurance | 9-10 min | 9-10 min | 9-10 min | 9-10 min | 4-5 min |

