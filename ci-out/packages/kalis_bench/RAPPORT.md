# Rapport du banc kalis_bench 0.2.0

Moteurs : kalis_plan 0.2.1, kalis_adapt 0.2.1, kalis_core 0.4.2 (catalogue 1.1.0). Mode `croisement`, profils `tous`, graine 0, 27 profils. Tout est déterministe, sauf les temps de calcul.

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
| `street_02_debutant_surpoids` | débutant | 12 | 0 | 0.91 | 6/6 |
| `street_03_debutante` | débutant | 12 | 0 | 0.95 | 5/5 |
| `street_04_reprise_longue_pause` | intermédiaire | 12 | 0 | 0.79 | 4/4 |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 16 | 0 | 0.90 | 6/6 |
| `street_06_inter_sets_reps` | intermédiaire | 12 | 0 | 0.88 | 6/6 |
| `street_07_avance_streetlifting_competition` | avancé | 12 | 0 | 0.95 | 10/10 |
| `street_08_avance_sets_reps_competition` | avancé | 8 | 0 | 0.86 | 5/8 |
| `street_09_elite_streetlifting` | élite | 12 | 0 | 0.95 | 9/10 |
| `street_10_elite_figures` | élite | 16 | 0 | 0.81 | 7/7 |
| `street_11_master_51_ans` | intermédiaire | 16 | 0 | 0.89 | 5/5 |
| `street_12_antecedent_coude` | intermédiaire | 12 | 0 | 0.81 | 5/6 |
| `street_13_peu_de_temps` | intermédiaire | 12 | 0 | 0.85 | 6/6 |
| `street_14_parc_sans_lest` | intermédiaire | 12 | 0 | 0.87 | 5/5 |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 12 | 0 | 0.90 | 6/6 |
| `street_16_specialisation_traction_lestee` | avancé | 10 | 0 | 0.76 | 8/8 |
| `street_17_hybride_street_course` | intermédiaire | 12 | 0 | 0.92 | 6/6 |

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
| `street_01_debutant_complet` | 0.79 | 1.00 | — | 0.79 | 1.00 | — | — | 1.00 | 1.00 |
| `street_02_debutant_surpoids` | 0.57 | — | — | 1.00 | 1.00 | — | — | 1.00 | 1.00 |
| `street_03_debutante` | 0.71 | 1.00 | — | 1.00 | 1.00 | — | — | 0.96 | 1.00 |
| `street_04_reprise_longue_pause` | 0.21 | — | — | 0.75 | 1.00 | — | — | 1.00 | 1.00 |
| `street_05_inter_calisthenie_front_lever` | 0.50 | 1.00 | — | 0.77 | 1.00 | 1.00 | — | 1.00 | 1.00 |
| `street_06_inter_sets_reps` | 0.64 | 1.00 | — | 0.65 | 1.00 | — | — | 1.00 | 1.00 |
| `street_07_avance_streetlifting_competition` | 0.64 | 1.00 | 1.00 | 0.90 | 1.00 | 1.00 | 1.00 | 0.97 | 1.00 |
| `street_08_avance_sets_reps_competition` | 0.50 | 1.00 | 0.83 | 0.58 | 1.00 | — | 1.00 | 1.00 | 1.00 |
| `street_09_elite_streetlifting` | 0.71 | 1.00 | 1.00 | 0.92 | 1.00 | 1.00 | 1.00 | 0.95 | 1.00 |
| `street_10_elite_figures` | 0.43 | 1.00 | — | 0.65 | 0.83 | — | — | 0.96 | 1.00 |
| `street_11_master_51_ans` | 0.57 | 1.00 | — | 0.79 | 1.00 | — | — | 1.00 | 1.00 |
| `street_12_antecedent_coude` | 0.57 | 1.00 | — | 0.50 | 0.82 | — | — | 1.00 | 1.00 |
| `street_13_peu_de_temps` | 0.57 | 1.00 | — | 0.77 | 0.86 | — | — | 0.91 | 1.00 |
| `street_14_parc_sans_lest` | 0.57 | 1.00 | — | 0.65 | 1.00 | — | — | 1.00 | 1.00 |
| `street_15_travail_physique_sommeil_court` | 0.57 | 1.00 | — | 0.88 | 1.00 | — | — | 0.96 | 1.00 |
| `street_16_specialisation_traction_lestee` | 0.29 | 1.00 | 0.84 | 0.43 | 0.53 | — | 1.00 | 1.00 | 1.00 |
| `street_17_hybride_street_course` | 0.57 | 1.00 | — | 1.00 | 1.00 | — | — | 0.95 | 1.00 |

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
| `street_01_debutant_complet` | 36/36 | 0.0 | 3.193 | 0.787 | 0.0 | 1.169 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_02_debutant_surpoids` | 36/36 | 0.0 | 2.704 | 0.79 | 0.0 | 1.471 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_03_debutante` | 36/36 | 0.0 | 3.238 | 0.681 | 0.0 | 1.167 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_04_reprise_longue_pause` | 48/48 | 0.0 | 3.196 | 0.529 | 0.0 | 0.585 | — | 0 | ecart_rir | 0 |
| `street_05_inter_calisthenie_front_lever` | 63/64 | 0.0 | 1.783 | 0.647 | 0.0 | — | — | 0 | ecart_rir | 0 |
| `street_06_inter_sets_reps` | 48/48 | 0.0 | 2.27 | 0.593 | 0.0 | 0.302 | — | 0 | ecart_rir | 0 |
| `street_07_avance_streetlifting_competition` | 60/60 | 0.001 | 2.907 | 0.672 | 0.337 | 0.058 | 1.028 | 0 | ecart_rir, pics_de_charge, ecart_effort, pics_a_schema_egal | 0 |
| `street_08_avance_sets_reps_competition` | 40/40 | 0.0 | 3.623 | 0.56 | 0.0 | 0.157 | 0.822 | 0 | ecart_rir, performance_echeance | 0 |
| `street_09_elite_streetlifting` | 60/60 | 0.0 | 3.2 | 0.601 | 0.328 | 0.024 | 1.019 | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `street_10_elite_figures` | 91/96 | 0.0 | 2.794 | 0.314 | 0.0 | 0.053 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_11_master_51_ans` | 48/48 | 0.0 | 1.69 | 0.785 | 0.049 | 0.273 | — | 0 | ecart_rir | 0 |
| `street_12_antecedent_coude` | 48/48 | 0.0 | 2.384 | 0.629 | 0.286 | 0.251 | — | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `street_13_peu_de_temps` | 34/36 | 0.0 | 1.395 | 0.723 | 0.0 | 0.645 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_14_parc_sans_lest` | 46/48 | 0.0 | 2.37 | 0.674 | 0.0 | 0.397 | — | 0 | ecart_rir | 0 |
| `street_15_travail_physique_sommeil_court` | 36/36 | 0.0 | 2.146 | 0.665 | 0.0 | 0.599 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_16_specialisation_traction_lestee` | 40/40 | 0.002 | 2.703 | 0.714 | 0.376 | 0.12 | 0.976 | 0 | ecart_rir, pics_de_charge, performance_echeance, ecart_effort | 0 |
| `street_17_hybride_street_course` | 58/60 | 0.0 | 1.916 | 0.605 | 0.0 | 0.519 | — | 0 | ecart_rir, ecart_effort | 0 |

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
- Volume par muscle dans la bande du référentiel : 0.79 — 11 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.79 — Sur 14 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 87 / 62 (rapport 1.40).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 10 exercices de renforcement distincts en première semaine pour 23 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.053, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (7/7) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Travail de traction adapté (assistée, négative ou suspension) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes (squat ou fente) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 10.9 séries dures par semaine en montée)
- tenue — Séances de 50 minutes au plus (mesuré : séance la plus longue : 40 min estimées)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_02_debutant_surpoids` — Débutant sédentaire en surpoids

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 100 / 68 (rapport 1.47).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 7 exercices de renforcement distincts en première semaine pour 16 emplacements ; 0 doublons de chaîne dans une même séance ; 8 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Ni pliométrie, ni sprint, ni corde à sauter, ni balistique (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Exercices de niveau débutant seulement (mesuré : aucun au-dessus)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Séances de 45 minutes au plus (mesuré : séance la plus longue : 39 min estimées)
- tenue — Pectoraux : pas plus de 10 séries dures par semaine (mesuré : 7.6 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_03_debutante` — Débutante, objectif première traction

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 15 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 87 / 76 (rapport 1.14).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.96 — 11 exercices de renforcement distincts en première semaine pour 23 emplacements ; 1 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.045, exercices × schémas 0.000 (seuil 0.3).

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
- Volume par muscle dans la bande du référentiel : 0.21 — 3 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.75 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 4.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 82 / 66 (rapport 1.24).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 27 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.150, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/4) :
- tenue — Au moins 3 répétitions en réserve les deux premières semaines (mesuré : RIR le plus bas des 2 premières semaines : 3.0)
- tenue — Grand dorsal : pas plus de 16 séries dures par semaine (mesuré : 9.3 séries dures par semaine en montée)
- tenue — Pas de négatives ni d'excentriques accentués (mesuré : aucun)
- tenue — Tractions (ou un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_05_inter_calisthenie_front_lever` — Intermédiaire calisthénie, premiers muscle-ups, objectif front lever

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, biceps, lombaires, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.77 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 10 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 160 / 83 (rapport 1.93).
- Couverture des points faibles : 1.00 — 1 points faibles couverts sur 1 vérifiables.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 31 emplacements ; 0 doublons de chaîne dans une même séance ; 16 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.095, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : trois jours par semaine au plus (mesuré : 3 jours par semaine au plus pour une même famille)
- tenue — Muscle-up (ou un palier) au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Tirage dynamique (vertical ou horizontal) au moins trois fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)
- tenue — Jambes au moins une fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_06_inter_sets_reps` — Intermédiaire sets & reps

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.65 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 3.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 104 / 72 (rapport 1.44).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 17 exercices de renforcement distincts en première semaine pour 32 emplacements ; 0 doublons de chaîne dans une même séance ; 17 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.235, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions et de dips en densité (repos de 90 s au plus, EMOM, tours) (mesuré : 51 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Au moins un format de densité (EMOM, AMRAP, tours, série dégressive) (mesuré : formats : emom)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Jambes au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_07_avance_streetlifting_competition` — Avancé streetlifting, compétition dans 12 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 50 % avant les quatre dernières semaines, 56 % pendant.
- Progression planifiée : 0.90 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 9 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 116 / 69 (rapport 1.69).
- Couverture des points faibles : 1.00 — 1 points faibles couverts sur 1 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 61 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 0.97 — 16 exercices de renforcement distincts en première semaine pour 37 emplacements ; 1 doublons de chaîne dans une même séance ; 16 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.222, exercices × schémas 0.095 (seuil 0.3).

Attentes de coach (10/10) :
- tenue — Volume réduit de 40 à 70 % la semaine de la compétition (mesuré : volume 61 % sous le pic la semaine de l'échéance)
- tenue — Traction lestée au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Dips lesté au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au moins une exposition lourde (85 % et plus, ou 5 répétitions au plus sous charge) par semaine en traction lestée (mesuré : 2.0 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées (kg ou % du 1RM) sur les quatre mouvements de compétition (mesuré : 70 prescriptions chargées ou en % du 1RM sur 70)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Ondulation : au moins deux plages de répétitions par semaine en traction lestée (mesuré : 2.0 plage(s) de répétitions distincte(s) par semaine)
- tenue — Série haute puis séries allégées, ou clusters (mesuré : formats : top_set_backoff)
- tenue — Variante pour le point faible (traction lestée pause en bas) au moins une fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_08_avance_sets_reps_competition` — Avancé sets & reps, compétition dans 8 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.83 — Part des séries dures sur les mouvements de l'échéance : 29 % avant les quatre dernières semaines, 33 % pendant.
- Progression planifiée : 0.58 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 4.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 71 / 50 (rapport 1.42).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 8) : nature test, volume 66 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 8.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 38 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.250, exercices × schémas 0.020 (seuil 0.3).

Attentes de coach (5/8) :
- **non tenue** — Volume réduit de 40 à 60 % la semaine de la compétition (mesuré : volume 66 % sous le pic la semaine de l'échéance)
- **non tenue** — Tractions au moins quatre fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Muscle-ups au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- **non tenue** — Au moins la moitié des séries de tractions, dips et muscle-ups en densité (mesuré : 47 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Formats de l'épreuve : tours, EMOM, AMRAP, séries dégressives (mesuré : formats : emom)
- tenue — Une séance lestée lourde par semaine en traction (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Épreuve sur les mouvements visés la semaine de la compétition (mesuré : 3 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_09_elite_streetlifting` — Élite streetlifting, niveau national

Non transmis au moteur par le profil actuel : libellé de l'échéance ; description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 53 % avant les quatre dernières semaines, 57 % pendant.
- Progression planifiée : 0.92 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 150 / 112 (rapport 1.34).
- Couverture des points faibles : 1.00 — 2 points faibles couverts sur 2 vérifiables.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 12) : nature test, volume 68 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 0.95 — 18 exercices de renforcement distincts en première semaine pour 42 emplacements ; 2 doublons de chaîne dans une même séance ; 19 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.207, exercices × schémas 0.098 (seuil 0.3).

Attentes de coach (9/10) :
- tenue — Volume réduit de 40 à 70 % la semaine du championnat (mesuré : volume 68 % sous le pic la semaine de l'échéance)
- **non tenue** — Traction lestée au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Dips lesté au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Une exposition lourde par semaine au moins sur chaque mouvement de compétition (mesuré : 5.0 exposition(s) lourde(s) par semaine en montée)
- tenue — Charges chiffrées sur les quatre mouvements de compétition (mesuré : 82 prescriptions chargées ou en % du 1RM sur 82)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Série haute puis séries allégées, clusters ou vagues (mesuré : formats : top_set_backoff)
- tenue — 8 à 18 séries dures par semaine en traction lestée et ses variantes (mesuré : 9.4 séries dures par semaine en montée)
- tenue — Épreuve sur les mouvements de compétition la semaine du championnat (mesuré : 4 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_10_elite_figures` — Élite figures : planche et front lever complets en cours

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.43 — 6 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, haut du dos, biceps, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.65 — Sur 23 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 15 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.83 — Séries dures de tirage / de poussée sur les semaines de montée : 165 / 198 (rapport 0.83).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.96 — 18 exercices de renforcement distincts en première semaine pour 45 emplacements ; 2 doublons de chaîne dans une même séance ; 18 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.114, exercices × schémas 0.041 (seuil 0.3).

Attentes de coach (7/7) :
- tenue — Planche (un palier) au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Front lever (un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Tenues bras tendus d'une même famille : quatre jours par semaine au plus (mesuré : 3 jours par semaine au plus pour une même famille)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 3 semaines de charge de suite au plus)
- tenue — Préparation ou mobilité des poignets et des épaules au moins trois fois par semaine (mesuré : 6.0 séance(s) par semaine en montée)
- tenue — Dynamique dans le schéma des figures au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes en entretien au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_11_master_51_ans` — Athlète de 51 ans, intermédiaire

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.79 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 143 / 99 (rapport 1.44).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 14 exercices de renforcement distincts en première semaine pour 25 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.235, exercices × schémas 0.053 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jamais moins d'une répétition en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 18 séries dures par semaine (mesuré : 13.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_12_antecedent_coude` — Antécédent de tendinopathie du coude

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.50 — Sur 6 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 3 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.82 — Séries dures de tirage / de poussée sur les semaines de montée : 72 / 88 (rapport 0.82).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 32 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.139, exercices × schémas 0.026 (seuil 0.3).

Attentes de coach (5/6) :
- **non tenue** — Aucun exercice à contrainte forte sur le coude (mesuré : présents : Dips lesté de compétition)
- tenue — Ni négatives, ni excentriques lents, ni surcharges en traction (mesuré : aucun)
- tenue — Biceps : pas plus de 10 séries dures par semaine (mesuré : 6.0 séries dures par semaine en montée)
- tenue — Dips lesté au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_13_peu_de_temps` — Peu de temps : trois séances de 45 minutes

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, triceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.77 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 8 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 0.86 — Séries dures de tirage / de poussée sur les semaines de montée : 128 / 55 (rapport 2.33).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.91 — 10 exercices de renforcement distincts en première semaine pour 23 emplacements ; 2 doublons de chaîne dans une même séance ; 10 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.188, exercices × schémas 0.063 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Séances de 48 minutes au plus (mesuré : séance la plus longue : 35 min estimées)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 16.0 séries dures par semaine en montée)
- tenue — Pectoraux : au moins 4 séries dures par semaine (mesuré : 9.9 séries dures par semaine en montée)
- tenue — Supersets pour gagner du temps (mesuré : formats : superset)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_14_parc_sans_lest` — Parc seulement, sans lest ni élastique

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.65 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 103 / 87 (rapport 1.18).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 14 exercices de renforcement distincts en première semaine pour 27 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.222, exercices × schémas 0.028 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions en densité (mesuré : 51 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Une variante dure de traction (archer, typewriter, poitrine à la barre) au moins une fois par semaine (mesuré : 1.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_15_travail_physique_sommeil_court` — Travail physique et sommeil court

Non transmis au moteur par le profil actuel : qualité du sommeil (seule la durée est transmise).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.88 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 80 / 72 (rapport 1.11).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.96 — 14 exercices de renforcement distincts en première semaine pour 24 emplacements ; 1 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.188, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 10.0 séries dures par semaine en montée)
- tenue — Quadriceps : pas plus de 10 séries dures par semaine (mesuré : 10.0 séries dures par semaine en montée)
- tenue — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Séances de 62 minutes au plus (mesuré : séance la plus longue : 46 min estimées)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 10.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_16_specialisation_traction_lestee` — Spécialisation : priorité à la traction lestée

Non transmis au moteur par le profil actuel : libellé de l'échéance ; liste des mouvements à entretenir (la spécialisation porte la cible ; le reste passe en entretien d'office).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.29 — 4 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.84 — Part des séries dures sur les mouvements de l'échéance : 33 % avant les quatre dernières semaines, 34 % pendant.
- Progression planifiée : 0.43 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 3 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.53 — Séries dures de tirage / de poussée sur les semaines de montée : 114 / 30 (rapport 3.80).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 10) : nature test, volume 57 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 10.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 26 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.174, exercices × schémas 0.086 (seuil 0.3).

Attentes de coach (8/8) :
- tenue — Traction lestée au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins 30 % des séries dures sur la traction lestée et ses variantes (mesuré : 32 % des séries dures en montée)
- tenue — Dips lesté en entretien : 3 à 8 séries dures par semaine (mesuré : 5.0 séries dures par semaine en montée)
- tenue — Squat en entretien : 3 à 8 séries dures par semaine (mesuré : 5.0 séries dures par semaine en montée)
- tenue — Volume réduit de 30 à 60 % la semaine du test (mesuré : volume 57 % sous le pic la semaine de l'échéance)
- tenue — Épreuve de traction lestée la semaine du test (mesuré : 1 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))
- tenue — Une exposition lourde par semaine au moins en traction lestée (mesuré : 3.0 exposition(s) lourde(s) par semaine en montée)
- tenue — Pas plus de 5 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_17_hybride_street_course` — Hybride street et course

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, biceps, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 120 / 72 (rapport 1.67).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.95 — 13 exercices de renforcement distincts en première semaine pour 22 emplacements ; 1 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.143, exercices × schémas 0.053 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 111 min par semaine en montée)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Dips au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au plus une séance de course intense par semaine : une séance de fractionné présente (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Quadriceps : pas plus de 12 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

