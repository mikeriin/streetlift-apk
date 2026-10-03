# Rapport du banc kalis_bench 0.1.0

Moteurs : kalis_plan 0.2.0, kalis_adapt 0.1.0, kalis_core 0.4.1 (catalogue 1.1.0). Mode `croisement`, profils `tous`, graine 0, 27 profils. Tout est déterministe, sauf les temps de calcul.

## 1. Programmes créés

Violations de sécurité : **23** au total (Pas d'allègement avant l'échéance : 3 ; Hausse de charge trop rapide : 5 ; Volume hebdomadaire au-dessus du plafond du niveau : 9 ; Séance plus longue que le temps donné : 3 ; Hausse de volume trop rapide : 3).

| Profil | Niveau | Semaines | Violations de sécurité | Qualité (moyenne) | Attentes tenues |
| --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | débutant | 12 | 1 | 0.97 | 5/6 |
| `autres_02_hypertrophie_intermediaire` | intermédiaire | 12 | 3 | 0.89 | 5/5 |
| `autres_03_powerlifter_competition` | avancé | 10 | 4 | 0.79 | 3/7 |
| `autres_04_force_generale_46_ans` | intermédiaire | 16 | 3 | 0.98 | 5/5 |
| `autres_05_course_10_km_debutante` | débutant | 12 | 4 | 0.67 | 4/5 |
| `autres_06_semi_marathon_intermediaire` | intermédiaire | 12 | 1 | 0.59 | 5/5 |
| `autres_07_mobilite_sante_senior` | débutant | 12 | 0 | 1.00 | 5/5 |
| `autres_08_crossfit_intermediaire` | intermédiaire | 16 | 7 | 0.94 | 5/5 |
| `autres_09_perte_de_poids_debutante` | débutant | 12 | 0 | 0.83 | 4/6 |
| `autres_10_contraintes_multiples` | débutant | 12 | 0 | 0.82 | 6/6 |
| `street_01_debutant_complet` | débutant | 12 | 0 | 0.93 | 7/7 |
| `street_02_debutant_surpoids` | débutant | 12 | 0 | 0.94 | 6/6 |
| `street_03_debutante` | débutant | 12 | 0 | 0.92 | 5/5 |
| `street_04_reprise_longue_pause` | intermédiaire | 12 | 0 | 0.73 | 4/4 |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 16 | 0 | 0.79 | 6/6 |
| `street_06_inter_sets_reps` | intermédiaire | 12 | 0 | 0.85 | 6/6 |
| `street_07_avance_streetlifting_competition` | avancé | 12 | 0 | 0.94 | 10/10 |
| `street_08_avance_sets_reps_competition` | avancé | 8 | 0 | 0.70 | 7/8 |
| `street_09_elite_streetlifting` | élite | 12 | 0 | 0.94 | 10/10 |
| `street_10_elite_figures` | élite | 16 | 0 | 0.68 | 7/7 |
| `street_11_master_51_ans` | intermédiaire | 16 | 0 | 0.76 | 5/5 |
| `street_12_antecedent_coude` | intermédiaire | 12 | 0 | 0.87 | 5/6 |
| `street_13_peu_de_temps` | intermédiaire | 12 | 0 | 0.82 | 6/6 |
| `street_14_parc_sans_lest` | intermédiaire | 12 | 0 | 0.83 | 5/5 |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 12 | 0 | 0.78 | 6/6 |
| `street_16_specialisation_traction_lestee` | avancé | 10 | 0 | 0.73 | 7/8 |
| `street_17_hybride_street_course` | intermédiaire | 12 | 0 | 0.76 | 6/6 |

### Qualité par critère

| Profil | `volume_bande` | `frequence_prioritaires` | `specificite` | `progression_planifiee` | `equilibre_poussee_tirage` | `points_faibles` | `affutage_aligne` | `variete_utile` | `non_ressemblance_proprietaire` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 0.93 | — | — | 0.94 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_02_hypertrophie_intermediaire` | 0.86 | — | — | 0.96 | 1.00 | 0.50 | — | 1.00 | 1.00 |
| `autres_03_powerlifter_competition` | 0.71 | 0.83 | 0.41 | 1.00 | 1.00 | — | 0.33 | 1.00 | 1.00 |
| `autres_04_force_generale_46_ans` | 0.93 | 1.00 | — | 0.95 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_05_course_10_km_debutante` | — | 1.00 | 0.00 | — | — | — | 0.67 | — | 1.00 |
| `autres_06_semi_marathon_intermediaire` | 0.00 | 1.00 | 0.00 | 0.50 | 0.86 | — | 0.33 | 1.00 | 1.00 |
| `autres_07_mobilite_sante_senior` | — | — | — | — | — | — | — | 1.00 | 1.00 |
| `autres_08_crossfit_intermediaire` | 0.86 | 1.00 | — | 0.77 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_09_perte_de_poids_debutante` | 0.57 | — | — | 0.60 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_10_contraintes_multiples` | 0.50 | — | — | 0.60 | 1.00 | — | — | 1.00 | 1.00 |
| `street_01_debutant_complet` | 0.64 | 1.00 | — | 1.00 | 0.96 | — | — | 1.00 | 1.00 |
| `street_02_debutant_surpoids` | 0.71 | — | — | 1.00 | 1.00 | — | — | 1.00 | 1.00 |
| `street_03_debutante` | 0.64 | 1.00 | — | 1.00 | 0.89 | — | — | 1.00 | 1.00 |
| `street_04_reprise_longue_pause` | 0.29 | — | — | 0.81 | 0.57 | — | — | 1.00 | 1.00 |
| `street_05_inter_calisthenie_front_lever` | 0.29 | 1.00 | — | 0.67 | 0.67 | 1.00 | — | 0.93 | 1.00 |
| `street_06_inter_sets_reps` | 0.57 | 1.00 | — | 0.58 | 1.00 | — | — | 0.93 | 1.00 |
| `street_07_avance_streetlifting_competition` | 0.57 | 1.00 | 1.00 | 0.91 | 1.00 | 1.00 | 1.00 | 0.97 | 1.00 |
| `street_08_avance_sets_reps_competition` | 0.29 | 1.00 | 0.55 | 0.64 | 0.21 | — | 0.89 | 1.00 | 1.00 |
| `street_09_elite_streetlifting` | 0.64 | 1.00 | 1.00 | 0.92 | 1.00 | 1.00 | 1.00 | 0.94 | 1.00 |
| `street_10_elite_figures` | 0.36 | 1.00 | — | 0.14 | 0.60 | — | — | 0.95 | 1.00 |
| `street_11_master_51_ans` | 0.21 | 1.00 | — | 0.71 | 0.62 | — | — | 1.00 | 1.00 |
| `street_12_antecedent_coude` | 0.50 | 1.00 | — | 0.71 | 1.00 | — | — | 1.00 | 1.00 |
| `street_13_peu_de_temps` | 0.57 | 1.00 | — | 0.33 | 1.00 | — | — | 1.00 | 1.00 |
| `street_14_parc_sans_lest` | 0.50 | 1.00 | — | 0.50 | 1.00 | — | — | 1.00 | 1.00 |
| `street_15_travail_physique_sommeil_court` | 0.14 | 1.00 | — | 0.67 | 0.89 | — | — | 1.00 | 1.00 |
| `street_16_specialisation_traction_lestee` | 0.14 | 1.00 | 0.67 | 0.43 | 0.63 | — | 1.00 | 1.00 | 1.00 |
| `street_17_hybride_street_course` | 0.21 | 1.00 | — | 0.71 | 0.62 | — | — | 1.00 | 1.00 |

## 2. Trajectoires simulées

| Profil | Séances faites | Échecs non voulus | Écart au RIR visé (cibles atteignables) | Cibles atteignables | Plus forte hausse (principal) | Gain réel (%/sem) | Performance à l'échéance | Déblocages non respectés | Repères non tenus | Violations (programme évolué) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 36/36 | 0.002 | 1.772 | 0.914 | 0.333 | 0.649 | — | 0 | ecart_rir | 2 |
| `autres_02_hypertrophie_intermediaire` | 60/60 | 0.003 | 2.481 | 0.933 | 0.063 | 0.096 | — | 0 | ecart_rir | 13 |
| `autres_03_powerlifter_competition` | 40/40 | 0.0 | 1.201 | 0.995 | 0.027 | 0.037 | 0.972 | 0 | ecart_rir, performance_echeance | 4 |
| `autres_04_force_generale_46_ans` | 48/48 | 0.004 | 1.458 | 1.0 | 0.03 | 0.148 | — | 0 | ecart_rir | 12 |
| `autres_05_course_10_km_debutante` | 34/36 | 0.0 | 0.0 | 0.0 | 0.0 | — | — | 0 | aucun | 4 |
| `autres_06_semi_marathon_intermediaire` | 46/48 | 0.0 | 2.452 | 0.735 | 0.0 | 0.284 | — | 0 | ecart_rir | 1 |
| `autres_07_mobilite_sante_senior` | 46/48 | 0.0 | 3.585 | 0.903 | 0.0 | 0.739 | — | 0 | ecart_rir | 0 |
| `autres_08_crossfit_intermediaire` | 79/80 | 0.0 | 1.656 | 0.824 | 0.125 | 0.167 | — | 0 | ecart_rir | 12 |
| `autres_09_perte_de_poids_debutante` | 36/36 | 0.005 | 2.255 | 0.828 | 0.143 | 0.823 | — | 0 | ecart_rir | 0 |
| `autres_10_contraintes_multiples` | 36/36 | 0.0 | 2.888 | 0.978 | 0.0 | 0.774 | — | 0 | ecart_rir | 0 |
| `street_01_debutant_complet` | 36/36 | 0.0 | 2.468 | 0.762 | 0.0 | 1.492 | — | 0 | ecart_rir | 0 |
| `street_02_debutant_surpoids` | 36/36 | 0.0 | 2.395 | 0.729 | 0.0 | 1.534 | — | 0 | ecart_rir | 0 |
| `street_03_debutante` | 36/36 | 0.0 | 2.704 | 0.651 | 0.0 | 1.28 | — | 0 | ecart_rir | 0 |
| `street_04_reprise_longue_pause` | 48/48 | 0.003 | 2.381 | 0.448 | 0.0 | 0.426 | — | 0 | ecart_rir | 0 |
| `street_05_inter_calisthenie_front_lever` | 63/64 | 0.0 | 2.41 | 0.547 | 0.0 | — | — | 0 | ecart_rir | 0 |
| `street_06_inter_sets_reps` | 48/48 | 0.001 | 3.173 | 0.439 | 0.0 | 0.342 | — | 0 | ecart_rir | 0 |
| `street_07_avance_streetlifting_competition` | 60/60 | 0.003 | 1.412 | 0.743 | 0.098 | 0.052 | 0.922 | 0 | ecart_rir, performance_echeance | 0 |
| `street_08_avance_sets_reps_competition` | 40/40 | 0.003 | 2.738 | 0.512 | 0.0 | 0.099 | 0.715 | 0 | ecart_rir, performance_echeance | 0 |
| `street_09_elite_streetlifting` | 60/60 | 0.0 | 1.375 | 0.74 | 0.099 | 0.025 | 0.931 | 0 | ecart_rir, performance_echeance | 0 |
| `street_10_elite_figures` | 91/96 | 0.005 | 1.174 | 0.462 | 0.0 | 0.081 | — | 0 | ecart_rir | 0 |
| `street_11_master_51_ans` | 48/48 | 0.002 | 1.888 | 0.598 | 0.171 | 0.234 | — | 0 | ecart_rir, pics_de_charge | 0 |
| `street_12_antecedent_coude` | 48/48 | 0.0 | 1.576 | 0.664 | 0.104 | 0.232 | — | 0 | ecart_rir, pics_de_charge | 0 |
| `street_13_peu_de_temps` | 34/36 | 0.002 | 1.783 | 0.579 | 0.0 | 0.649 | — | 0 | ecart_rir | 0 |
| `street_14_parc_sans_lest` | 46/48 | 0.001 | 2.633 | 0.533 | 0.0 | 0.428 | — | 0 | ecart_rir | 4 |
| `street_15_travail_physique_sommeil_court` | 36/36 | 0.002 | 2.245 | 0.51 | 0.0 | 0.484 | — | 0 | ecart_rir | 0 |
| `street_16_specialisation_traction_lestee` | 40/40 | 0.0 | 1.503 | 0.702 | 0.096 | 0.094 | 0.937 | 0 | ecart_rir, performance_echeance | 0 |
| `street_17_hybride_street_course` | 58/60 | 0.002 | 1.817 | 0.61 | 0.0 | 0.585 | — | 0 | ecart_rir | 0 |

## 3. Détail par profil

### `autres_01_debutant_musculation` — Débutant en musculation

Sécurité : 1 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — fessiers : 6 semaine(s) au-dessus du plafond du niveau débutant (12 séries dures), jusqu'à 12.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.93 — 13 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; au-dessus du plafond : fessiers.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.94 — Sur 9 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 8 ; seulement en séries ou en effort : 1.
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

Non transmis au moteur par le profil actuel : points faibles musculaires (le profil ne porte que les points faibles d'un mouvement).

Sécurité : 3 violation(s).
- **Hausse de charge trop rapide** — Back squat barre haute : charge totale +5.3 % en une semaine (seuil 5.0 %).
- **Hausse de charge trop rapide** — Back squat barre haute : charge totale +5.3 % en une semaine (seuil 5.0 %).
- **Volume hebdomadaire au-dessus du plafond du niveau** — fessiers : 7 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.5.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : mollets ; au-dessus du plafond : fessiers.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.96 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 12 ; seulement en séries ou en effort : 1.
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

Programme tel qu'il a évolué sous le moteur d'évolution : 13 violation(s) de sécurité (Hausse de charge trop rapide : 10 ; Volume hebdomadaire au-dessus du plafond du niveau : 2 ; Hausse de volume trop rapide : 1).

### `autres_03_powerlifter_competition` — Powerlifter, compétition dans 10 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : 4 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 3 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 26.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — fessiers : 9 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 33.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quadriceps : 7 semaine(s) au-dessus du plafond du niveau avancé (25 séries dures), jusqu'à 30.5.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 40 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : mollets ; au-dessus du plafond : triceps, fessiers, quadriceps.
- Fréquence des mouvements prioritaires : 0.83 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.41 — Part des séries dures sur les mouvements de l'échéance : 21 % avant les quatre dernières semaines, 21 % pendant.
- Progression planifiée : 1.00 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 15 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 140 / 119 (rapport 1.18).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 10) : nature montée, volume 0 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 6.
- Variété utile : 1.00 — 30 exercices de renforcement distincts en première semaine pour 32 emplacements ; 0 doublons de chaîne dans une même séance ; 37 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.100, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/7) :
- **non tenue** — Volume réduit de 30 à 70 % la semaine de la compétition (mesuré : volume 0 % sous le pic la semaine de l'échéance)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Développé couché au moins trois fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Soulevé de terre au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Charges chiffrées sur les trois mouvements (mesuré : 35 prescriptions chargées ou en % du 1RM sur 35)
- **non tenue** — Une exposition lourde par semaine au moins au squat (mesuré : 0.3 exposition(s) lourde(s) par semaine en montée)
- **non tenue** — Épreuve sur les trois mouvements la semaine de la compétition (mesuré : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : montée))

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Volume hebdomadaire au-dessus du plafond du niveau : 3 ; Pas d'allègement avant l'échéance : 1).

### `autres_04_force_generale_46_ans` — Force générale après 40 ans

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : 3 violation(s).
- **Hausse de charge trop rapide** — Développé couché barre : charge totale +5.3 % en une semaine (seuil 5.0 %).
- **Hausse de charge trop rapide** — Développé couché barre : charge totale +5.3 % en une semaine (seuil 5.0 %).
- **Hausse de charge trop rapide** — Développé couché barre : charge totale +5.3 % en une semaine (seuil 5.0 %).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.93 — 13 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.95 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 9 ; seulement en séries ou en effort : 1.
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

Programme tel qu'il a évolué sous le moteur d'évolution : 12 violation(s) de sécurité (Hausse de charge trop rapide : 11 ; Volume hebdomadaire au-dessus du plafond du niveau : 1).

### `autres_05_course_10_km_debutante` — Course : premier 10 km

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : 4 violation(s).
- **Séance plus longue que le temps donné** — Semaine 4, jour 1 : 80 min estimées pour 45 min disponibles.
- **Séance plus longue que le temps donné** — Semaine 8, jour 1 : 80 min estimées pour 45 min disponibles.
- **Séance plus longue que le temps donné** — Semaine 12, jour 1 : 80 min estimées pour 45 min disponibles.
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume 0 % sous le pic des six semaines précédentes (au moins 30 % attendus).

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

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : 1 violation(s).
- **Pas d'allègement avant l'échéance** — Semaine de l'échéance : volume -6 % sous le pic des six semaines précédentes (au moins 30 % attendus).

Qualité :
- Volume par muscle dans la bande du référentiel : 0.00 — 0 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, grand dorsal, haut du dos, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.00 — Part des séries dures sur les mouvements de l'échéance : 0 % avant les quatre dernières semaines, 0 % pendant.
- Progression planifiée : 0.50 — Sur 1 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 0 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 0.86 — Séries dures de tirage / de poussée sur les semaines de montée : 12 / 14 (rapport 0.86).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.33 — Semaine de l'échéance (semaine 12) : nature montée, volume -6 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 10.
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

Sécurité : 7 violation(s).
- **Volume hebdomadaire au-dessus du plafond du niveau** — grand dorsal : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Volume hebdomadaire au-dessus du plafond du niveau** — triceps : 9 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Hausse de volume trop rapide** — lombaires : 16.0 séries dures en semaine 12, pour 15.6 admises au vu des trois semaines précédentes.
- **Volume hebdomadaire au-dessus du plafond du niveau** — fessiers : 6 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 21.0.
- **Hausse de volume trop rapide** — quadriceps : 19.5 séries dures en semaine 7, pour 19.2 admises au vu des trois semaines précédentes.
- **Volume hebdomadaire au-dessus du plafond du niveau** — quadriceps : 3 semaine(s) au-dessus du plafond du niveau intermédiaire (20 séries dures), jusqu'à 20.5.
- **Hausse de volume trop rapide** — mollets : 9.0 séries dures en semaine 7, pour 8.5 admises au vu des trois semaines précédentes.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; au-dessus du plafond : triceps, fessiers.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.77 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 6.
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

Programme tel qu'il a évolué sous le moteur d'évolution : 12 violation(s) de sécurité (Hausse de charge trop rapide : 5 ; Volume hebdomadaire au-dessus du plafond du niveau : 4 ; Hausse de volume trop rapide : 3).

### `autres_09_perte_de_poids_debutante` — Perte de poids, débutante

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 5 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 1 ; seulement en séries ou en effort : 4.
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

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, biceps, abdominaux, lombaires, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 5 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 1 ; seulement en séries ou en effort : 4.
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

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 13 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.96 — Séries dures de tirage / de poussée sur les semaines de montée : 80 / 83 (rapport 0.96).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 9 exercices de renforcement distincts en première semaine pour 22 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.059, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (7/7) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Travail de traction adapté (assistée, négative ou suspension) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes (squat ou fente) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 10.0 séries dures par semaine en montée)
- tenue — Séances de 50 minutes au plus (mesuré : séance la plus longue : 34 min estimées)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_02_debutant_surpoids` — Débutant sédentaire en surpoids

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 90 / 54 (rapport 1.67).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 8 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 9 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Ni pliométrie, ni sprint, ni corde à sauter, ni balistique (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Exercices de niveau débutant seulement (mesuré : aucun au-dessus)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Séances de 45 minutes au plus (mesuré : séance la plus longue : 30 min estimées)
- tenue — Pectoraux : pas plus de 10 séries dures par semaine (mesuré : 6.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_03_debutante` — Débutante, objectif première traction

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 15 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.89 — Séries dures de tirage / de poussée sur les semaines de montée : 80 / 90 (rapport 0.89).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 10 exercices de renforcement distincts en première semaine pour 24 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.050, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Travail de traction adapté au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Pompes (ou un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_04_reprise_longue_pause` — Reprise après neuf mois d'arrêt

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.29 — 4 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, biceps, triceps, abdominaux, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.81 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 3.
- Équilibre poussée / tirage : 0.57 — Séries dures de tirage / de poussée sur les semaines de montée : 119 / 34 (rapport 3.50).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 27 emplacements ; 0 doublons de chaîne dans une même séance ; 16 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.143, exercices × schémas 0.050 (seuil 0.3).

Attentes de coach (4/4) :
- tenue — Au moins 3 répétitions en réserve les deux premières semaines (mesuré : RIR le plus bas des 2 premières semaines : 3.0)
- tenue — Grand dorsal : pas plus de 16 séries dures par semaine (mesuré : 13.2 séries dures par semaine en montée)
- tenue — Pas de négatives ni d'excentriques accentués (mesuré : aucun)
- tenue — Tractions (ou un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_05_inter_calisthenie_front_lever` — Intermédiaire calisthénie, premiers muscle-ups, objectif front lever

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.29 — 4 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, haut du dos, biceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.67 — Sur 18 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 12 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.67 — Séries dures de tirage / de poussée sur les semaines de montée : 144 / 48 (rapport 3.00).
- Couverture des points faibles : 1.00 — 1 points faibles couverts sur 1 vérifiables.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.93 — 11 exercices de renforcement distincts en première semaine pour 28 emplacements ; 2 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.222, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : trois jours par semaine au plus (mesuré : 2 jours par semaine au plus pour une même famille)
- tenue — Muscle-up (ou un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)
- tenue — Tirage dynamique (vertical ou horizontal) au moins trois fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)
- tenue — Jambes au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_06_inter_sets_reps` — Intermédiaire sets & reps

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.58 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 99 / 72 (rapport 1.38).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.93 — 14 exercices de renforcement distincts en première semaine pour 28 emplacements ; 2 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.190, exercices × schémas 0.026 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions et de dips en densité (repos de 90 s au plus, EMOM, tours) (mesuré : 72 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Au moins un format de densité (EMOM, AMRAP, tours, série dégressive) (mesuré : formats : emom)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)
- tenue — Jambes au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_07_avance_streetlifting_competition` — Avancé streetlifting, compétition dans 12 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, abdominaux, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 59 % avant les quatre dernières semaines, 62 % pendant.
- Progression planifiée : 0.91 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 10 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 116 / 69 (rapport 1.69).
- Couverture des points faibles : 1.00 — 1 points faibles couverts sur 1 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 61 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 0.97 — 13 exercices de renforcement distincts en première semaine pour 30 emplacements ; 1 doublons de chaîne dans une même séance ; 17 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.227, exercices × schémas 0.093 (seuil 0.3).

Attentes de coach (10/10) :
- tenue — Volume réduit de 40 à 70 % la semaine de la compétition (mesuré : volume 61 % sous le pic la semaine de l'échéance)
- tenue — Traction lestée au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips lesté au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au moins une exposition lourde (85 % et plus, ou 5 répétitions au plus sous charge) par semaine en traction lestée (mesuré : 3.0 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées (kg ou % du 1RM) sur les quatre mouvements de compétition (mesuré : 77 prescriptions chargées ou en % du 1RM sur 77)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Ondulation : au moins deux plages de répétitions par semaine en traction lestée (mesuré : 2.6 plage(s) de répétitions distincte(s) par semaine)
- tenue — Série haute puis séries allégées, ou clusters (mesuré : formats : top_set_backoff)
- tenue — Variante pour le point faible (traction lestée pause en bas) au moins une fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_08_avance_sets_reps_competition` — Avancé sets & reps, compétition dans 8 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.29 — 4 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.55 — Part des séries dures sur les mouvements de l'échéance : 18 % avant les quatre dernières semaines, 22 % pendant.
- Progression planifiée : 0.64 — Sur 14 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 4.
- Équilibre poussée / tirage : 0.21 — Séries dures de tirage / de poussée sur les semaines de montée : 72 / 8 (rapport 9.53).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.89 — Semaine de l'échéance (semaine 8) : nature test, volume 80 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 8.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 37 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.278, exercices × schémas 0.026 (seuil 0.3).

Attentes de coach (7/8) :
- **non tenue** — Volume réduit de 40 à 60 % la semaine de la compétition (mesuré : volume 80 % sous le pic la semaine de l'échéance)
- tenue — Tractions au moins quatre fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)
- tenue — Muscle-ups au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)
- tenue — Au moins la moitié des séries de tractions, dips et muscle-ups en densité (mesuré : 90 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Formats de l'épreuve : tours, EMOM, AMRAP, séries dégressives (mesuré : formats : emom)
- tenue — Une séance lestée lourde par semaine en traction (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Épreuve sur les mouvements visés la semaine de la compétition (mesuré : 3 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_09_elite_streetlifting` — Élite streetlifting, niveau national

Non transmis au moteur par le profil actuel : libellé de l'échéance ; description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 60 % avant les quatre dernières semaines, 62 % pendant.
- Progression planifiée : 0.92 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 150 / 102 (rapport 1.47).
- Couverture des points faibles : 1.00 — 2 points faibles couverts sur 2 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 69 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 0.94 — 14 exercices de renforcement distincts en première semaine pour 33 emplacements ; 2 doublons de chaîne dans une même séance ; 18 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.217, exercices × schémas 0.103 (seuil 0.3).

Attentes de coach (10/10) :
- tenue — Volume réduit de 40 à 70 % la semaine du championnat (mesuré : volume 69 % sous le pic la semaine de l'échéance)
- tenue — Traction lestée au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips lesté au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Une exposition lourde par semaine au moins sur chaque mouvement de compétition (mesuré : 4.7 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées sur les quatre mouvements de compétition (mesuré : 84 prescriptions chargées ou en % du 1RM sur 84)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Série haute puis séries allégées, clusters ou vagues (mesuré : formats : top_set_backoff)
- tenue — 8 à 18 séries dures par semaine en traction lestée et ses variantes (mesuré : 9.4 séries dures par semaine en montée)
- tenue — Épreuve sur les mouvements de compétition la semaine du championnat (mesuré : 4 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_10_elite_figures` — Élite figures : planche et front lever complets en cours

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.36 — 5 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.14 — Sur 28 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.60 — Séries dures de tirage / de poussée sur les semaines de montée : 165 / 275 (rapport 0.60).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.95 — 15 exercices de renforcement distincts en première semaine pour 43 emplacements ; 2 doublons de chaîne dans une même séance ; 19 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.125, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (7/7) :
- tenue — Planche (un palier) au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : quatre jours par semaine au plus (mesuré : 3 jours par semaine au plus pour une même famille)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Préparation ou mobilité des poignets et des épaules au moins trois fois par semaine (mesuré : 6.0 séance(s) par semaine en montée)
- tenue — Dynamique dans le schéma des figures au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes en entretien au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_11_master_51_ans` — Athlète de 51 ans, intermédiaire

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.21 — 3 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, abdominaux, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.71 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 0.62 — Séries dures de tirage / de poussée sur les semaines de montée : 156 / 48 (rapport 3.25).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 23 emplacements ; 0 doublons de chaîne dans une même séance ; 17 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.200, exercices × schémas 0.028 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jamais moins d'une répétition en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 1.0)
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 18 séries dures par semaine (mesuré : 13.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_12_antecedent_coude` — Antécédent de tendinopathie du coude

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, haut du dos, biceps, abdominaux, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.71 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 81 / 72 (rapport 1.13).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 11 exercices de renforcement distincts en première semaine pour 24 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.158, exercices × schémas 0.061 (seuil 0.3).

Attentes de coach (5/6) :
- **non tenue** — Aucun exercice à contrainte forte sur le coude (mesuré : présents : Dips lesté de compétition)
- tenue — Ni négatives, ni excentriques lents, ni surcharges en traction (mesuré : aucun)
- tenue — Biceps : pas plus de 10 séries dures par semaine (mesuré : 7.5 séries dures par semaine en montée)
- tenue — Dips lesté au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_13_peu_de_temps` — Peu de temps : trois séances de 45 minutes

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, abdominaux, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.33 — Sur 9 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 3 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 144 / 81 (rapport 1.78).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 8 exercices de renforcement distincts en première semaine pour 21 emplacements ; 0 doublons de chaîne dans une même séance ; 9 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.188, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Séances de 48 minutes au plus (mesuré : séance la plus longue : 32 min estimées)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 16.0 séries dures par semaine en montée)
- tenue — Pectoraux : au moins 4 séries dures par semaine (mesuré : 13.5 séries dures par semaine en montée)
- tenue — Supersets pour gagner du temps (mesuré : formats : superset)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_14_parc_sans_lest` — Parc seulement, sans lest ni élastique

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 117 / 63 (rapport 1.86).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 26 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.211, exercices × schémas 0.037 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions en densité (mesuré : 63 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)
- tenue — Une variante dure de traction (archer, typewriter, poitrine à la barre) au moins une fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 4 violation(s) de sécurité (Hausse de volume trop rapide : 4).

### `street_15_travail_physique_sommeil_court` — Travail physique et sommeil court

Non transmis au moteur par le profil actuel : qualité du sommeil (seule la durée est transmise).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.14 — 2 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.67 — Sur 6 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 3 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 0.89 — Séries dures de tirage / de poussée sur les semaines de montée : 81 / 36 (rapport 2.25).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 11 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.158, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)
- tenue — Quadriceps : pas plus de 10 séries dures par semaine (mesuré : 7.3 séries dures par semaine en montée)
- tenue — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Séances de 62 minutes au plus (mesuré : séance la plus longue : 54 min estimées)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_16_specialisation_traction_lestee` — Spécialisation : priorité à la traction lestée

Non transmis au moteur par le profil actuel : libellé de l'échéance ; liste des mouvements à entretenir (la spécialisation porte la cible ; le reste passe en entretien d'office).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.14 — 2 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.67 — Part des séries dures sur les mouvements de l'échéance : 38 % avant les quatre dernières semaines, 33 % pendant.
- Progression planifiée : 0.43 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 3 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.63 — Séries dures de tirage / de poussée sur les semaines de montée : 96 / 30 (rapport 3.20).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 10) : nature test, volume 64 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 10.
- Variété utile : 1.00 — 11 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.222, exercices × schémas 0.059 (seuil 0.3).

Attentes de coach (7/8) :
- tenue — Traction lestée au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins 30 % des séries dures sur la traction lestée et ses variantes (mesuré : 38 % des séries dures en montée)
- tenue — Dips lesté en entretien : 3 à 8 séries dures par semaine (mesuré : 5.0 séries dures par semaine en montée)
- tenue — Squat en entretien : 3 à 8 séries dures par semaine (mesuré : 5.0 séries dures par semaine en montée)
- **non tenue** — Volume réduit de 30 à 60 % la semaine du test (mesuré : volume 64 % sous le pic la semaine de l'échéance)
- tenue — Épreuve de traction lestée la semaine du test (mesuré : 1 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))
- tenue — Une exposition lourde par semaine au moins en traction lestée (mesuré : 2.7 exposition(s) lourde(s) par semaine en montée)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_17_hybride_street_course` — Hybride street et course

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.21 — 3 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.71 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 0.62 — Séries dures de tirage / de poussée sur les semaines de montée : 117 / 36 (rapport 3.25).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 11 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.136, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 91 min par semaine en montée)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au plus une séance de course intense par semaine : une séance de fractionné présente (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Quadriceps : pas plus de 12 séries dures par semaine (mesuré : 6.3 séries dures par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

