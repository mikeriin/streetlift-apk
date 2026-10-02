# Rapport du banc kalis_bench 0.1.0

Moteurs : kalis_plan 0.1.0, kalis_adapt 0.1.0, kalis_core 0.3.0 (catalogue 1.1.0). Mode `croisement`, profils `tous`, graine 0, 27 profils. Tout est déterministe, sauf les temps de calcul.

## 1. Programmes créés

Violations de sécurité : **90** au total (Pas d'allègement avant l'échéance : 5 ; Volume hebdomadaire au-dessus du plafond du niveau : 77 ; Séance plus longue que le temps donné : 5 ; Technique avancée sans ses prérequis : 3).

| Profil | Niveau | Semaines | Violations de sécurité | Qualité (moyenne) | Attentes tenues |
| --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | débutant | 12 | 1 | 0.97 | 5/6 |
| `autres_02_hypertrophie_intermediaire` | intermédiaire | 12 | 1 | 0.89 | 5/5 |
| `autres_03_powerlifter_competition` | avancé | 10 | 4 | 0.79 | 3/7 |
| `autres_04_force_generale_46_ans` | intermédiaire | 16 | 0 | 0.98 | 5/5 |
| `autres_05_course_10_km_debutante` | débutant | 12 | 4 | 0.67 | 4/5 |
| `autres_06_semi_marathon_intermediaire` | intermédiaire | 12 | 1 | 0.60 | 5/5 |
| `autres_07_mobilite_sante_senior` | débutant | 12 | 0 | 1.00 | 5/5 |
| `autres_08_crossfit_intermediaire` | intermédiaire | 16 | 4 | 0.94 | 5/5 |
| `autres_09_perte_de_poids_debutante` | débutant | 12 | 0 | 0.83 | 4/6 |
| `autres_10_contraintes_multiples` | débutant | 12 | 0 | 0.82 | 6/6 |
| `street_01_debutant_complet` | débutant | 12 | 2 | 0.87 | 5/7 |
| `street_02_debutant_surpoids` | débutant | 12 | 1 | 0.86 | 6/6 |
| `street_03_debutante` | débutant | 12 | 3 | 0.85 | 3/5 |
| `street_04_reprise_longue_pause` | intermédiaire | 12 | 3 | 0.83 | 3/4 |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 16 | 6 | 0.71 | 4/6 |
| `street_06_inter_sets_reps` | intermédiaire | 12 | 1 | 0.87 | 4/6 |
| `street_07_avance_streetlifting_competition` | avancé | 12 | 4 | 0.88 | 5/10 |
| `street_08_avance_sets_reps_competition` | avancé | 8 | 5 | 0.72 | 2/8 |
| `street_09_elite_streetlifting` | élite | 12 | 8 | 0.94 | 5/10 |
| `street_10_elite_figures` | élite | 16 | 19 | 0.84 | 6/7 |
| `street_11_master_51_ans` | intermédiaire | 16 | 3 | 0.87 | 4/5 |
| `street_12_antecedent_coude` | intermédiaire | 12 | 7 | 0.90 | 2/6 |
| `street_13_peu_de_temps` | intermédiaire | 12 | 0 | 0.85 | 5/6 |
| `street_14_parc_sans_lest` | intermédiaire | 12 | 5 | 0.86 | 3/5 |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 12 | 1 | 0.86 | 4/6 |
| `street_16_specialisation_traction_lestee` | avancé | 10 | 5 | 0.68 | 1/8 |
| `street_17_hybride_street_course` | intermédiaire | 12 | 2 | 0.90 | 4/6 |

### Qualité par critère

| Profil | `volume_bande` | `frequence_prioritaires` | `specificite` | `progression_planifiee` | `equilibre_poussee_tirage` | `points_faibles` | `affutage_aligne` | `variete_utile` | `non_ressemblance_proprietaire` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 0.93 | — | — | 0.94 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_02_hypertrophie_intermediaire` | 0.86 | — | — | 0.96 | 1.00 | 0.50 | — | 1.00 | 1.00 |
| `autres_03_powerlifter_competition` | 0.71 | 0.83 | 0.41 | 1.00 | 1.00 | — | 0.33 | 1.00 | 1.00 |
| `autres_04_force_generale_46_ans` | 0.93 | 1.00 | — | 0.95 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_05_course_10_km_debutante` | — | 1.00 | 0.00 | — | — | — | 0.67 | — | 1.00 |
| `autres_06_semi_marathon_intermediaire` | 0.00 | 1.00 | 0.00 | 0.50 | 1.00 | — | 0.33 | 1.00 | 1.00 |
| `autres_07_mobilite_sante_senior` | — | — | — | — | — | — | — | 1.00 | 1.00 |
| `autres_08_crossfit_intermediaire` | 0.86 | 1.00 | — | 0.77 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_09_perte_de_poids_debutante` | 0.57 | — | — | 0.60 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_10_contraintes_multiples` | 0.50 | — | — | 0.60 | 1.00 | — | — | 1.00 | 1.00 |
| `street_01_debutant_complet` | 0.71 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_02_debutant_surpoids` | 0.79 | — | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_03_debutante` | 0.57 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_04_reprise_longue_pause` | 0.64 | — | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_05_inter_calisthenie_front_lever` | 0.50 | 1.00 | — | 0.50 | 1.00 | 0.00 | — | 1.00 | 1.00 |
| `street_06_inter_sets_reps` | 0.71 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_07_avance_streetlifting_competition` | 0.64 | 0.88 | 0.60 | 0.82 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| `street_08_avance_sets_reps_competition` | 0.64 | 0.83 | 0.26 | 0.72 | 1.00 | — | 0.33 | 1.00 | 1.00 |
| `street_09_elite_streetlifting` | 0.86 | 0.88 | 0.76 | 0.93 | 1.00 | 1.00 | 1.00 | 1.00 | 1.00 |
| `street_10_elite_figures` | 0.50 | 1.00 | — | 0.57 | 1.00 | — | — | 1.00 | 1.00 |
| `street_11_master_51_ans` | 0.57 | 1.00 | — | 0.63 | 1.00 | — | — | 1.00 | 1.00 |
| `street_12_antecedent_coude` | 0.57 | 1.00 | — | 0.81 | 1.00 | — | — | 1.00 | 1.00 |
| `street_13_peu_de_temps` | 0.57 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_14_parc_sans_lest` | 0.64 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_15_travail_physique_sommeil_court` | 0.64 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_16_specialisation_traction_lestee` | 0.64 | 0.50 | 0.09 | 0.84 | 1.00 | — | 0.33 | 1.00 | 1.00 |
| `street_17_hybride_street_course` | 0.93 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |

## 2. Trajectoires simulées

| Profil | Séances faites | Échecs non voulus | Écart au RIR visé (cibles atteignables) | Cibles atteignables | Plus forte hausse (principal) | Gain réel (%/sem) | Performance à l'échéance | Violations (programme évolué) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 36/36 | 0.002 | 1.772 | 0.914 | 0.333 | 0.649 | — | 2 |
| `autres_02_hypertrophie_intermediaire` | 60/60 | 0.003 | 2.481 | 0.933 | 0.063 | 0.096 | — | 11 |
| `autres_03_powerlifter_competition` | 40/40 | 0.0 | 1.201 | 0.995 | 0.027 | 0.037 | 0.972 | 4 |
| `autres_04_force_generale_46_ans` | 48/48 | 0.004 | 1.458 | 1.0 | 0.03 | 0.148 | — | 3 |
| `autres_05_course_10_km_debutante` | 34/36 | 0.0 | 0.0 | 0.0 | 0.0 | — | — | 4 |
| `autres_06_semi_marathon_intermediaire` | 46/48 | 0.0 | 2.452 | 0.735 | 0.0 | 0.284 | — | 1 |
| `autres_07_mobilite_sante_senior` | 46/48 | 0.0 | 3.585 | 0.903 | 0.0 | 0.739 | — | 0 |
| `autres_08_crossfit_intermediaire` | 79/80 | 0.0 | 1.656 | 0.824 | 0.125 | 0.167 | — | 6 |
| `autres_09_perte_de_poids_debutante` | 36/36 | 0.005 | 2.255 | 0.828 | 0.143 | 0.823 | — | 0 |
| `autres_10_contraintes_multiples` | 36/36 | 0.0 | 2.888 | 0.978 | 0.0 | 0.774 | — | 0 |
| `street_01_debutant_complet` | 36/36 | 0.0 | 2.12 | 0.686 | 0.0 | 1.298 | — | 4 |
| `street_02_debutant_surpoids` | 36/36 | 0.027 | 2.799 | 0.692 | 0.0 | 1.073 | — | 5 |
| `street_03_debutante` | 36/36 | 0.0 | 2.216 | 0.559 | 0.0 | 1.418 | — | 3 |
| `street_04_reprise_longue_pause` | 48/48 | 0.002 | 2.247 | 0.79 | 0.0 | 0.38 | — | 6 |
| `street_05_inter_calisthenie_front_lever` | 63/64 | 0.0 | 2.035 | 0.762 | 0.0 | 0.266 | — | 8 |
| `street_06_inter_sets_reps` | 48/48 | 0.002 | 2.223 | 0.83 | 0.0 | 0.366 | — | 4 |
| `street_07_avance_streetlifting_competition` | 60/60 | 0.004 | 1.503 | 0.935 | 0.047 | 0.031 | 0.94 | 6 |
| `street_08_avance_sets_reps_competition` | 40/40 | 0.0 | 1.983 | 0.773 | 0.014 | 0.048 | 0.856 | 6 |
| `street_09_elite_streetlifting` | 60/60 | 0.0 | 1.51 | 0.79 | 0.06 | 0.017 | 0.937 | 7 |
| `street_10_elite_figures` | 91/96 | 0.0 | 1.443 | 0.62 | 0.023 | 0.028 | — | 20 |
| `street_11_master_51_ans` | 48/48 | 0.0 | 1.759 | 0.747 | 0.016 | 0.235 | — | 3 |
| `street_12_antecedent_coude` | 48/48 | 0.002 | 1.537 | 0.912 | 0.044 | 0.089 | — | 8 |
| `street_13_peu_de_temps` | 34/36 | 0.0 | 2.245 | 0.836 | 0.0 | 0.448 | — | 0 |
| `street_14_parc_sans_lest` | 46/48 | 0.0 | 2.252 | 0.754 | 0.0 | 0.416 | — | 4 |
| `street_15_travail_physique_sommeil_court` | 36/36 | 0.0 | 2.121 | 0.92 | 0.0 | 0.421 | — | 1 |
| `street_16_specialisation_traction_lestee` | 40/40 | 0.0 | 1.623 | 0.97 | 0.042 | 0.031 | 1.0 | 5 |
| `street_17_hybride_street_course` | 58/60 | 0.003 | 2.052 | 0.914 | 0.0 | 0.416 | — | 2 |

## 3. Détail par profil

### `autres_01_debutant_musculation` — Débutant en musculation

Non transmis au moteur par le profil actuel : ancienneté d'entraînement en mois.

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 6 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 12.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.93 — 13 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; au-dessus du plafond : glutes.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.94 — Sur 9 mouvements principaux, secondaires ou figures du premier bloc : 8 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 1 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 87 / 81 (rapport 1.07).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 21 exercices de renforcement distincts en première semaine pour 23 emplacements ; 0 doublons de chaîne dans une même séance ; 31 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.077, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/6) :
- tenue — Au moins 2 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- **non tenue** — Squat ou presse au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Tirage au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Pectoraux : pas plus de 12 séries dures par semaine (mesuré : 7.5 séries dures par semaine en montée)
- tenue — Quadriceps : au moins 5 séries dures par semaine (mesuré : 8.7 séries dures par semaine en montée)
- tenue — Aucun exercice avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 2 violation(s) de sécurité (Hausse de charge trop rapide : 1 ; Volume hebdomadaire au-dessus du plafond du niveau : 1).

### `autres_02_hypertrophie_intermediaire` — Hypertrophie esthétique, intermédiaire

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; points faibles.

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : glutes.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.96 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc : 12 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 1 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 105 / 105 (rapport 1.00).
- Couverture des points faibles : 0.50 — 1 points faibles couverts sur 2 vérifiables ; non couverts : delt_middle : 12.0 séries/sem (attendu ≥ 14).
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 31 exercices de renforcement distincts en première semaine pour 31 emplacements ; 0 doublons de chaîne dans une même séance ; 45 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.155, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Fessiers : au moins 14 séries dures par semaine (mesuré : 21.2 séries dures par semaine en montée)
- tenue — Deltoïde moyen : au moins 10 séries dures par semaine (mesuré : 12.0 séries dures par semaine en montée)
- tenue — Fessiers : pas plus de 25 séries dures par semaine (mesuré : 21.2 séries dures par semaine en montée)
- tenue — Pas plus de 7 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Isolation des épaules au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 11 violation(s) de sécurité (Hausse de charge trop rapide : 9 ; Volume hebdomadaire au-dessus du plafond du niveau : 2).

### `autres_03_powerlifter_competition` — Powerlifter, compétition dans 10 semaines

Non transmis au moteur par le profil actuel : ancienneté des tests ; valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois.

Sécurité : 4 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 3 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 26.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 9 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 33.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 7 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 30.5.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 30 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : triceps, glutes, quads.
- Fréquence des mouvements prioritaires : 0.83 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.41 — Part des séries dures sur les mouvements de l'échéance : 21 % avant les quatre dernières semaines, 21 % pendant.
- Progression planifiée : 1.00 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc : 15 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 0 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 140 / 119 (rapport 1.18).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 10) : nature build, volume 0 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 6.
- Variété utile : 1.00 — 30 exercices de renforcement distincts en première semaine pour 32 emplacements ; 0 doublons de chaîne dans une même séance ; 37 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.100, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/7) :
- **non tenue** — Volume réduit de 30 à 70 % la semaine de la compétition (mesuré : volume 0 % sous le pic la semaine de l'échéance)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Développé couché au moins trois fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Soulevé de terre au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Charges chiffrées sur les trois mouvements (mesuré : 35 prescriptions chargées ou en % du 1RM sur 35)
- **non tenue** — Une exposition lourde par semaine au moins au squat (mesuré : 0.3 exposition(s) lourde(s) par semaine en montée)
- **non tenue** — Épreuve sur les trois mouvements la semaine de la compétition (mesuré : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : build))

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 3 ; Pas d'allègement avant l'échéance : 1).

### `autres_04_force_generale_46_ans` — Force générale après 40 ans

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; antécédents de blessure sans gêne actuelle ; description de la blessure ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.93 — 13 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.95 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc : 9 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 1 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 84 / 84 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 19 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 28 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.081, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Charges chiffrées au squat et au développé couché (mesuré : 27 prescriptions chargées ou en % du 1RM sur 27)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Jamais moins d'une répétition en réserve (mesuré : RIR le plus bas des 16 premières semaines : 2.0)
- tenue — Au moins 20 minutes de mobilité par semaine (mesuré : 34 min par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 3 violation(s) de sécurité (Hausse de charge trop rapide : 2 ; Volume hebdomadaire au-dessus du plafond du niveau : 1).

### `autres_05_course_10_km_debutante` — Course : premier 10 km

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois.

Sécurité : 4 violation(s).
- **Séance plus longue que le temps donné** — Semaine 4, jour 1 : 80 min estimées pour 45 min disponibles.
- **Séance plus longue que le temps donné** — Semaine 8, jour 1 : 80 min estimées pour 45 min disponibles.
- **Séance plus longue que le temps donné** — Semaine 12, jour 1 : 80 min estimées pour 45 min disponibles.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 20 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : sans objet — Sans objet : programme sans renforcement dominant.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.00 — Part des séries dures sur les mouvements de l'échéance : 0 % avant les quatre dernières semaines, 0 % pendant.
- Progression planifiée : sans objet — Sans objet : programme sans renforcement dominant.
- Équilibre poussée / tirage : sans objet — Sans objet : programme sans renforcement dominant.
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.67 — Semaine de l'échéance (semaine 12) : nature test, volume 0 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : sans objet — 0 exercices de renforcement distincts en première semaine pour 0 emplacements ; 0 doublons de chaîne dans une même séance ; 0 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/5) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 127 min par semaine en montée)
- tenue — Pas de sprint (mesuré : aucun)
- tenue — Semaine de la course allégée d'au moins 20 % (mesuré : volume 0 % sous le pic la semaine de l'échéance)
- tenue — Pas plus de 4 semaines de charge sans allègement (mesuré : 2 semaines de charge de suite au plus)
- **non tenue** — Séances de 65 minutes au plus (mesuré : séance la plus longue : 80 min estimées)

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Séance plus longue que le temps donné : 3 ; Pas d'allègement avant l'échéance : 1).

### `autres_06_semi_marathon_intermediaire` — Semi-marathon, intermédiaire

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois.

Sécurité : 1 violation(s).
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume -6 % sous le pic des six semaines précédentes (au moins 20 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.00 — 0 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : chest, delt_anterior, delt_middle, delt_posterior, lats, upper_back, biceps, triceps, abs, lower_back, glutes, quads, hamstrings, calves.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.00 — Part des séries dures sur les mouvements de l'échéance : 0 % avant les quatre dernières semaines, 0 % pendant.
- Progression planifiée : 0.50 — Sur 1 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 1 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 12 / 14 (rapport 0.86).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 12) : nature build, volume -6 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 10.
- Variété utile : 1.00 — 8 exercices de renforcement distincts en première semaine pour 8 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.031, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Au moins 180 minutes de course par semaine (mesuré : 191 min par semaine en montée)
- tenue — Une séance de qualité (fractionné) par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Sortie longue chaque semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Pas plus de 4 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Une semaine allégée ou de test avant la course (mesuré : 2 semaine(s) de nature test)

Programme tel qu'il a évolué sous le moteur d'évolution : 1 violation(s) de sécurité (Pas d'allègement avant l'échéance : 1).

### `autres_07_mobilite_sante_senior` — Mobilité et santé, senior

Non transmis au moteur par le profil actuel : ancienneté d'entraînement en mois.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : sans objet — Sans objet : programme sans renforcement dominant.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : sans objet — Sans objet : programme sans renforcement dominant.
- Équilibre poussée / tirage : sans objet — Sans objet : programme sans renforcement dominant.
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 8 exercices de renforcement distincts en première semaine pour 8 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.034, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Ni saut, ni sprint, ni corde (mesuré : aucun)
- tenue — Au moins 30 minutes de mobilité par semaine (mesuré : 46 min par semaine en montée)
- tenue — Séances de 33 minutes au plus (mesuré : séance la plus longue : 31 min estimées)
- tenue — Au moins 3 répétitions en réserve (mesuré : RIR le plus bas des 12 premières semaines : 3.0)
- tenue — Renforcement des jambes (squat, fente, assis-debout) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_08_crossfit_intermediaire` — CrossFit, intermédiaire

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 4 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 20.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; au-dessus du plafond : triceps, glutes.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.77 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc : 7 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 6 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 147 / 126 (rapport 1.17).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 16 exercices de renforcement distincts en première semaine pour 17 emplacements ; 0 doublons de chaîne dans une même séance ; 21 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.068, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Formats codifiés (AMRAP, EMOM, tours) (mesuré : formats : rounds)
- tenue — Haltérophilie ou force à la barre au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins 30 minutes de conditionnement par semaine (mesuré : 42 min par semaine en montée)
- tenue — Pas plus de 7 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Travail vers le muscle-up au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 6 violation(s) de sécurité (Hausse de charge trop rapide : 2 ; Volume hebdomadaire au-dessus du plafond du niveau : 4).

### `autres_09_perte_de_poids_debutante` — Perte de poids, débutante

Non transmis au moteur par le profil actuel : ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie ; déficit énergétique en cours.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : delt_middle, delt_posterior, biceps, lower_back, hamstrings, calves.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 5 mouvements principaux, secondaires ou figures du premier bloc : 1 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 4 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 54 / 54 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 11 exercices de renforcement distincts en première semaine pour 11 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.080, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/6) :
- **non tenue** — Ni saut, ni sprint, ni corde, ni burpees (mesuré : présents : Pas chassés latéraux (éducatif de course))
- **non tenue** — Pas de course à pied au début (mesuré : présents : Footing en endurance fondamentale)
- tenue — Au moins 30 minutes de cardio à faible impact par semaine (mesuré : 38 min par semaine en montée)
- tenue — Au moins 2 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Quadriceps : au moins 4 séries dures par semaine (mesuré : 6.5 séries dures par semaine en montée)
- tenue — Exercices de niveau débutant ou intermédiaire (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_10_contraintes_multiples` — Contraintes multiples

Non transmis au moteur par le profil actuel : description de la blessure ; antécédents de blessure sans gêne actuelle ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie ; durée de la coupure avant le programme.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : delt_middle, biceps, abs, lower_back, quads, hamstrings, calves.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 5 mouvements principaux, secondaires ou figures du premier bloc : 1 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 4 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 54 / 54 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 10 exercices de renforcement distincts en première semaine pour 10 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.080, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Aucun exercice à contrainte forte sur le genou (mesuré : aucun)
- tenue — Ni saut, ni sprint, ni course (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 3.0)
- tenue — Séances de 44 minutes au plus (mesuré : séance la plus longue : 35 min estimées)
- tenue — Quadriceps : pas plus de 8 séries dures par semaine (mesuré : 3.7 séries dures par semaine en montée)
- tenue — Au moins 15 minutes de mobilité par semaine (mesuré : 18 min par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_01_debutant_complet` — Débutant complet, aucune traction

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 2 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 6 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 15.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 2 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 13.0.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : hamstrings, calves ; au-dessus du plafond : glutes, quads.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 11 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 72 / 72 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 16 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.048, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/7) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Travail de traction adapté (assistée, négative ou suspension) au moins deux fois par semaine (mesuré : 0.0 séance(s) par semaine en montée)
- **non tenue** — Jambes (squat ou fente) au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 10.5 séries dures par semaine en montée)
- tenue — Séances de 50 minutes au plus (mesuré : séance la plus longue : 32 min estimées)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 3 ; Hausse de volume trop rapide : 1).

### `street_02_debutant_surpoids` — Débutant sédentaire en surpoids

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie ; déficit énergétique en cours.

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 9 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 13.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.79 — 11 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : hamstrings, calves ; au-dessus du plafond : quads.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 10 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 81 / 81 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 14 exercices de renforcement distincts en première semaine pour 17 emplacements ; 0 doublons de chaîne dans une même séance ; 20 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.042, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Ni pliométrie, ni sprint, ni corde à sauter, ni balistique (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Exercices de niveau débutant seulement (mesuré : aucun au-dessus)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Séances de 45 minutes au plus (mesuré : séance la plus longue : 30 min estimées)
- tenue — Pectoraux : pas plus de 10 séries dures par semaine (mesuré : 6.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 5 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 5).

### `street_03_debutante` — Débutante, objectif première traction

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 3 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — abs : 9 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 16.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 9 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 14.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 6 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 15.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : delt_middle, hamstrings, calves ; au-dessus du plafond : abs, glutes, quads.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 10 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 72 / 56 (rapport 1.29).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 16 emplacements ; 0 doublons de chaîne dans une même séance ; 16 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.045, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/5) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- **non tenue** — Travail de traction adapté au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Pompes (ou un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Jambes au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 3 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 3).

### `street_04_reprise_longue_pause` — Reprise après neuf mois d'arrêt

Non transmis au moteur par le profil actuel : ancienneté des tests ; valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; durée de la coupure avant le programme.

Sécurité : 3 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 8 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 28.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — upper_back : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 23.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 25.0.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : lower_back, calves ; au-dessus du plafond : lats, upper_back, triceps.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 12 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 144 / 126 (rapport 1.14).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 19 exercices de renforcement distincts en première semaine pour 22 emplacements ; 0 doublons de chaîne dans une même séance ; 23 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.120, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/4) :
- tenue — Au moins 3 répétitions en réserve les deux premières semaines (mesuré : RIR le plus bas des 2 premières semaines : 3.0)
- **non tenue** — Grand dorsal : pas plus de 16 séries dures par semaine (mesuré : 24.4 séries dures par semaine en montée)
- tenue — Pas de négatives ni d'excentriques accentués (mesuré : aucun)
- tenue — Tractions (ou un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 6 violation(s) de sécurité (Hausse de volume trop rapide : 1 ; Volume hebdomadaire au-dessus du plafond du niveau : 3 ; Montée trop rapide de la charge bras tendus : 2).

### `street_05_inter_calisthenie_front_lever` — Intermédiaire calisthénie, premiers muscle-ups, objectif front lever

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; points faibles.

Sécurité : 6 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 25.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — delt_anterior : 13 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 30.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 13 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 28.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — upper_back : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 25.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 25.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 23.0.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : chest, delt_anterior, lats, upper_back, triceps, quads.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 16 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 16 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 230 / 230 (rapport 1.00).
- Couverture des points faibles : 0.00 — 0 points faibles couverts sur 1 vérifiables ; non couverts : cd-muscle-up-barre-strict : 1.0 séance/sem.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 21 exercices de renforcement distincts en première semaine pour 24 emplacements ; 0 doublons de chaîne dans une même séance ; 25 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.111, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/6) :
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : trois jours par semaine au plus (mesuré : 2 jours par semaine au plus pour une même famille)
- **non tenue** — Muscle-up (ou un palier) au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- **non tenue** — Tirage dynamique (vertical ou horizontal) au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jambes au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 8 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 8).

### `street_06_inter_sets_reps` — Intermédiaire sets & reps

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 25.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : lower_back, hamstrings, calves ; au-dessus du plafond : lats.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 12 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 133 / 126 (rapport 1.06).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 21 exercices de renforcement distincts en première semaine pour 22 emplacements ; 0 doublons de chaîne dans une même séance ; 24 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.160, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/6) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- **non tenue** — Dips au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions et de dips en densité (repos de 90 s au plus, EMOM, tours) (mesuré : 100 % des séries avec 90s de repos ou moins (ou en format de densité))
- **non tenue** — Au moins un format de densité (EMOM, AMRAP, tours, série dégressive) (mesuré : aucun de ces formats)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Jambes au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 4).

### `street_07_avance_streetlifting_competition` — Avancé streetlifting, compétition dans 12 semaines

Non transmis au moteur par le profil actuel : ancienneté des tests ; valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois ; points faibles.

Sécurité : 4 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 8 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 31.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 8 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 31.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 8 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 26.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 6 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 27.0.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : chest, lats, triceps, glutes.
- Fréquence des mouvements prioritaires : 0.88 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.60 — Part des séries dures sur les mouvements de l'échéance : 30 % avant les quatre dernières semaines, 30 % pendant.
- Progression planifiée : 0.82 — Sur 17 mouvements principaux, secondaires ou figures du premier bloc : 11 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 6 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 222 / 148 (rapport 1.50).
- Couverture des points faibles : 1.00 — 1 points faibles couverts sur 1 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 58 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 1.00 — 32 exercices de renforcement distincts en première semaine pour 35 emplacements ; 0 doublons de chaîne dans une même séance ; 39 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.193, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/10) :
- tenue — Volume réduit de 40 à 70 % la semaine de la compétition (mesuré : volume 58 % sous le pic la semaine de l'échéance)
- tenue — Traction lestée au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Dips lesté au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- **non tenue** — Au moins une exposition lourde (85 % et plus, ou 5 répétitions au plus sous charge) par semaine en traction lestée (mesuré : 0.5 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées (kg ou % du 1RM) sur les quatre mouvements de compétition (mesuré : 64 prescriptions chargées ou en % du 1RM sur 64)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- **non tenue** — Ondulation : au moins deux plages de répétitions par semaine en traction lestée (mesuré : 1.0 plage(s) de répétitions distincte(s) par semaine)
- **non tenue** — Série haute puis séries allégées, ou clusters (mesuré : aucun de ces formats)
- **non tenue** — Variante pour le point faible (traction lestée pause en bas) au moins une fois par semaine (mesuré : 0.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 6 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 5 ; Montée trop rapide de la charge bras tendus : 1).

### `street_08_avance_sets_reps_competition` — Avancé sets & reps, compétition dans 8 semaines

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois.

Sécurité : 5 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 5 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 29.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 6 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 32.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 5 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 29.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 1 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 29.5.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 30 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : chest, lats, triceps, glutes.
- Fréquence des mouvements prioritaires : 0.83 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.26 — Part des séries dures sur les mouvements de l'échéance : 14 % avant les quatre dernières semaines, 13 % pendant.
- Progression planifiée : 0.72 — Sur 20 mouvements principaux, secondaires ou figures du premier bloc : 9 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 11 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 102 / 94 (rapport 1.09).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 8) : nature build, volume 0 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 6.
- Variété utile : 1.00 — 34 exercices de renforcement distincts en première semaine pour 37 emplacements ; 0 doublons de chaîne dans une même séance ; 41 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.176, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (2/8) :
- **non tenue** — Volume réduit de 40 à 60 % la semaine de la compétition (mesuré : volume 0 % sous le pic la semaine de l'échéance)
- **non tenue** — Tractions au moins quatre fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Muscle-ups au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Dips au moins trois fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Au moins la moitié des séries de tractions, dips et muscle-ups en densité (mesuré : 74 % des séries avec 90s de repos ou moins (ou en format de densité))
- **non tenue** — Formats de l'épreuve : tours, EMOM, AMRAP, séries dégressives (mesuré : aucun de ces formats)
- tenue — Une séance lestée lourde par semaine en traction (mesuré : 1.0 séance(s) par semaine en montée)
- **non tenue** — Épreuve sur les mouvements visés la semaine de la compétition (mesuré : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : build))

Programme tel qu'il a évolué sous le moteur d'évolution : 6 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 5 ; Pas d'allègement avant l'échéance : 1).

### `street_09_elite_streetlifting` — Élite streetlifting, niveau national

Non transmis au moteur par le profil actuel : ancienneté des tests ; valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; description de la blessure ; ancienneté d'entraînement en mois ; points faibles.

Sécurité : 8 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — delt_anterior : 3 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 32.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — 5 groupes au-dessus de 25 séries dures en semaine 2 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 6 groupes au-dessus de 25 séries dures en semaine 3 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 6 groupes au-dessus de 25 séries dures en semaine 4 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 6 groupes au-dessus de 25 séries dures en semaine 5 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 5 groupes au-dessus de 25 séries dures en semaine 9 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 5 groupes au-dessus de 25 séries dures en semaine 10 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 5 groupes au-dessus de 25 séries dures en semaine 11 (au plus 2 en élite).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : delt_anterior.
- Fréquence des mouvements prioritaires : 0.88 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.76 — Part des séries dures sur les mouvements de l'échéance : 29 % avant les quatre dernières semaines, 30 % pendant.
- Progression planifiée : 0.93 — Sur 14 mouvements principaux, secondaires ou figures du premier bloc : 12 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 2 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 193 / 177 (rapport 1.09).
- Couverture des points faibles : 1.00 — 2 points faibles couverts sur 2 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 56 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 1.00 — 31 exercices de renforcement distincts en première semaine pour 33 emplacements ; 0 doublons de chaîne dans une même séance ; 39 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.175, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/10) :
- tenue — Volume réduit de 40 à 70 % la semaine du championnat (mesuré : volume 56 % sous le pic la semaine de l'échéance)
- **non tenue** — Traction lestée au moins trois fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- **non tenue** — Dips lesté au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Une exposition lourde par semaine au moins sur chaque mouvement de compétition (mesuré : 1.3 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées sur les quatre mouvements de compétition (mesuré : 56 prescriptions chargées ou en % du 1RM sur 56)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- **non tenue** — Série haute puis séries allégées, clusters ou vagues (mesuré : aucun de ces formats)
- **non tenue** — 8 à 18 séries dures par semaine en traction lestée et ses variantes (mesuré : 5.8 séries dures par semaine en montée)
- tenue — Épreuve sur les mouvements de compétition la semaine du championnat (mesuré : 4 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 7 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 7).

### `street_10_elite_figures` — Élite figures : planche et front lever complets en cours

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; description de la blessure ; ancienneté d'entraînement en mois.

Sécurité : 19 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 14 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 42.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — delt_anterior : 14 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 43.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 14 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 44.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — upper_back : 11 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 34.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 3 semaine(s) au-dessus du plafond du niveau élite (30 séries dures), jusqu'à 32.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — 4 groupes au-dessus de 25 séries dures en semaine 1 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 7 groupes au-dessus de 25 séries dures en semaine 2 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 3 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 4 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 5 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 4 groupes au-dessus de 25 séries dures en semaine 7 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 6 groupes au-dessus de 25 séries dures en semaine 8 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 9 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 10 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 8 groupes au-dessus de 25 séries dures en semaine 11 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 4 groupes au-dessus de 25 séries dures en semaine 13 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 6 groupes au-dessus de 25 séries dures en semaine 14 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 7 groupes au-dessus de 25 séries dures en semaine 15 (au plus 2 en élite).
- **Volume hebdomadaire au-dessus du plafond du niveau** — 7 groupes au-dessus de 25 séries dures en semaine 16 (au plus 2 en élite).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : lower_back, hamstrings, calves ; au-dessus du plafond : chest, delt_anterior, lats, upper_back.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.57 — Sur 22 mouvements principaux, secondaires ou figures du premier bloc : 3 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 19 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 409 / 398 (rapport 1.03).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 22 exercices de renforcement distincts en première semaine pour 30 emplacements ; 0 doublons de chaîne dans une même séance ; 27 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.093, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/7) :
- tenue — Planche (un palier) au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : quatre jours par semaine au plus (mesuré : 3 jours par semaine au plus pour une même famille)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- **non tenue** — Préparation ou mobilité des poignets et des épaules au moins trois fois par semaine (mesuré : 0.0 séance(s) par semaine en montée)
- tenue — Dynamique dans le schéma des figures au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes en entretien au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 20 violation(s) de sécurité (Hausse de charge trop rapide : 1 ; Volume hebdomadaire au-dessus du plafond du niveau : 19).

### `street_11_master_51_ans` — Athlète de 51 ans, intermédiaire

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie.

Sécurité : 3 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 22.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — upper_back : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 20.5.
- **Technique avancée sans ses prérequis** — Dips lesté partiel haut surchargé : technique réservée au niveau avancé et au-delà.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : biceps, lower_back, hamstrings, calves ; au-dessus du plafond : lats, upper_back.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.63 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc : 4 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 11 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 168 / 171 (rapport 0.98).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 17 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 20 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.128, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/5) :
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jamais moins d'une répétition en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Grand dorsal : pas plus de 18 séries dures par semaine (mesuré : 20.3 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 3 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 2 ; Technique avancée sans ses prérequis : 1).

### `street_12_antecedent_coude` — Antécédent de tendinopathie du coude

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; description de la blessure ; ancienneté d'entraînement en mois.

Sécurité : 7 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 4 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 20.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 23.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — abs : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 22.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quads : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 27.5.
- **Technique avancée sans ses prérequis** — Isométrie lestée en haut de traction : technique réservée au niveau avancé et au-delà.
- **Technique avancée sans ses prérequis** — Isométrie lestée en appui aux barres parallèles : technique réservée au niveau avancé et au-delà.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : chest, lats, abs, glutes, quads.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.81 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc : 8 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 5 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 126 / 126 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 25 exercices de renforcement distincts en première semaine pour 26 emplacements ; 0 doublons de chaîne dans une même séance ; 31 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.163, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (2/6) :
- **non tenue** — Aucun exercice à contrainte forte sur le coude (mesuré : présents : Dips lesté de compétition, Isométrie lestée en haut de traction, Muscle-up lesté de compétition, Isométrie lestée en appui aux barres parallèles, Traction lestée de compétition)
- tenue — Ni négatives, ni excentriques lents, ni surcharges en traction (mesuré : aucun)
- **non tenue** — Biceps : pas plus de 10 séries dures par semaine (mesuré : 15.6 séries dures par semaine en montée)
- tenue — Dips lesté au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Tirage horizontal au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- **non tenue** — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 1.5)

Programme tel qu'il a évolué sous le moteur d'évolution : 8 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 6 ; Technique avancée sans ses prérequis : 2).

### `street_13_peu_de_temps` — Peu de temps : trois séances de 45 minutes

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : delt_middle, delt_posterior, lower_back, glutes, hamstrings, calves.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 11 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 126 / 84 (rapport 1.50).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 15 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.158, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/6) :
- tenue — Séances de 48 minutes au plus (mesuré : séance la plus longue : 38 min estimées)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 18.9 séries dures par semaine en montée)
- tenue — Pectoraux : au moins 4 séries dures par semaine (mesuré : 16.5 séries dures par semaine en montée)
- **non tenue** — Supersets pour gagner du temps (mesuré : aucun de ces formats)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_14_parc_sans_lest` — Parc seulement, sans lest ni élastique

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 5 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — delt_anterior : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 22.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 26.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — upper_back : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 24.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — glutes : 1 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : delt_anterior, lats, upper_back, triceps.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 11 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 142 / 142 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 19 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 26 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.154, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/5) :
- **non tenue** — Tractions au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions en densité (mesuré : 100 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- **non tenue** — Une variante dure de traction (archer, typewriter, poitrine à la barre) au moins une fois par semaine (mesuré : 0.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 4).

### `street_15_travail_physique_sommeil_court` — Travail physique et sommeil court

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois ; sommeil habituel ; stress de vie ; travail physique.

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 1 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 20.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : delt_middle, lower_back, hamstrings, calves ; au-dessus du plafond : lats.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 13 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 126 / 106 (rapport 1.19).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 17 emplacements ; 0 doublons de chaîne dans une même séance ; 19 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.130, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/6) :
- **non tenue** — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 20.1 séries dures par semaine en montée)
- **non tenue** — Quadriceps : pas plus de 10 séries dures par semaine (mesuré : 15.4 séries dures par semaine en montée)
- tenue — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Séances de 62 minutes au plus (mesuré : séance la plus longue : 42 min estimées)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 20.1 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 1 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 1).

### `street_16_specialisation_traction_lestee` — Spécialisation : priorité à la traction lestée

Non transmis au moteur par le profil actuel : ancienneté des tests ; valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; nature de l'échéance (compétition ou test), priorité et format de l'épreuve : seul un objectif daté par mouvement est transmis ; ancienneté d'entraînement en mois ; mouvements prioritaires et mouvements à entretenir.

Sécurité : 5 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — chest : 9 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 35.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — delt_anterior : 9 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 34.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — lats : 7 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 28.5.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 5 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 28.5.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 30 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : calves ; au-dessus du plafond : chest, delt_anterior, lats, triceps.
- Fréquence des mouvements prioritaires : 0.50 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.09 — Part des séries dures sur les mouvements de l'échéance : 5 % avant les quatre dernières semaines, 4 % pendant.
- Progression planifiée : 0.84 — Sur 16 mouvements principaux, secondaires ou figures du premier bloc : 11 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 5 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 164 / 157 (rapport 1.04).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 10) : nature build, volume 0 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 6.
- Variété utile : 1.00 — 26 exercices de renforcement distincts en première semaine pour 28 emplacements ; 0 doublons de chaîne dans une même séance ; 31 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.178, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (1/8) :
- **non tenue** — Traction lestée au moins trois fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- **non tenue** — Au moins 30 % des séries dures sur la traction lestée et ses variantes (mesuré : 4 % des séries dures en montée)
- **non tenue** — Dips lesté en entretien : 3 à 8 séries dures par semaine (mesuré : 10.4 séries dures par semaine en montée)
- **non tenue** — Squat en entretien : 3 à 8 séries dures par semaine (mesuré : 9.4 séries dures par semaine en montée)
- **non tenue** — Volume réduit de 30 à 60 % la semaine du test (mesuré : volume 0 % sous le pic la semaine de l'échéance)
- **non tenue** — Épreuve de traction lestée la semaine du test (mesuré : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : build))
- **non tenue** — Une exposition lourde par semaine au moins en traction lestée (mesuré : 0.1 exposition(s) lourde(s) par semaine en montée)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 5 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 4 ; Pas d'allègement avant l'échéance : 1).

### `street_17_hybride_street_course` — Hybride street et course

Non transmis au moteur par le profil actuel : valeur exacte des records (le profil v2 lit une fourchette : la valeur est donnée comme bas et haut) ; ancienneté d'entraînement en mois.

Sécurité : 2 violation(s).
- **Séance plus longue que le temps donné** — Semaine 5, jour 1 : 78 min estimées pour 60 min disponibles.
- **Séance plus longue que le temps donné** — Semaine 10, jour 1 : 78 min estimées pour 60 min disponibles.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.93 — 13 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : calves.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc : 0 montent en charge, en répétitions ou en durée entre la première et la dernière semaine de montée ; 13 ne montent qu'en séries ou en effort.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 126 / 112 (rapport 1.13).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 20 exercices de renforcement distincts en première semaine pour 22 emplacements ; 0 doublons de chaîne dans une même séance ; 26 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.100, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/6) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 108 min par semaine en montée)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- **non tenue** — Dips au moins deux fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Au plus une séance de course intense par semaine : une séance de fractionné présente (mesuré : 1.0 séance(s) par semaine en montée)
- **non tenue** — Quadriceps : pas plus de 12 séries dures par semaine (mesuré : 13.3 séries dures par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 2 violation(s) de sécurité (Séance plus longue que le temps donné : 2).

