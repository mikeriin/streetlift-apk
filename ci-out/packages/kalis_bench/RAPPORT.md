# Rapport du banc kalis_bench 0.2.3

Moteurs : kalis_plan 0.2.3, kalis_adapt 0.3.0, kalis_core 0.4.3 (catalogue 1.1.0). Mode `croisement`, profils `tous`, graine 0, 27 profils. Tout est déterministe, sauf les temps de calcul.

## 1. Programmes créés

Violations de sécurité : **0** au total.

| Profil | Niveau | Semaines | Violations de sécurité | Qualité (moyenne) | Attentes tenues |
| --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | débutant | 12 | 0 | 0.96 | 6/6 |
| `autres_02_hypertrophie_intermediaire` | intermédiaire | 12 | 0 | 0.88 | 5/5 |
| `autres_03_powerlifter_competition` | avancé | 10 | 0 | 0.92 | 6/7 |
| `autres_04_force_generale_46_ans` | intermédiaire | 16 | 0 | 0.90 | 3/5 |
| `autres_05_course_10_km_debutante` | débutant | 12 | 0 | 0.65 | 3/5 |
| `autres_06_semi_marathon_intermediaire` | intermédiaire | 12 | 0 | 0.73 | 4/5 |
| `autres_07_mobilite_sante_senior` | débutant | 12 | 0 | 0.90 | 5/5 |
| `autres_08_crossfit_intermediaire` | intermédiaire | 16 | 0 | 0.82 | 4/5 |
| `autres_09_perte_de_poids_debutante` | débutant | 12 | 0 | 0.86 | 6/6 |
| `autres_10_contraintes_multiples` | débutant | 12 | 0 | 0.81 | 6/6 |
| `street_01_debutant_complet` | débutant | 12 | 0 | 0.88 | 7/7 |
| `street_02_debutant_surpoids` | débutant | 12 | 0 | 0.80 | 6/6 |
| `street_03_debutante` | débutant | 12 | 0 | 0.81 | 5/5 |
| `street_04_reprise_longue_pause` | intermédiaire | 12 | 0 | 0.68 | 4/4 |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 16 | 0 | 0.90 | 6/6 |
| `street_06_inter_sets_reps` | intermédiaire | 12 | 0 | 0.83 | 6/6 |
| `street_07_avance_streetlifting_competition` | avancé | 12 | 0 | 0.95 | 10/10 |
| `street_08_avance_sets_reps_competition` | avancé | 8 | 0 | 0.83 | 7/8 |
| `street_09_elite_streetlifting` | élite | 12 | 0 | 0.95 | 9/10 |
| `street_10_elite_figures` | élite | 16 | 0 | 0.81 | 6/7 |
| `street_11_master_51_ans` | intermédiaire | 16 | 0 | 0.92 | 5/5 |
| `street_12_antecedent_coude` | intermédiaire | 12 | 0 | 0.81 | 5/6 |
| `street_13_peu_de_temps` | intermédiaire | 12 | 0 | 0.88 | 6/6 |
| `street_14_parc_sans_lest` | intermédiaire | 12 | 0 | 0.86 | 4/5 |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 12 | 0 | 0.90 | 5/6 |
| `street_16_specialisation_traction_lestee` | avancé | 10 | 0 | 0.76 | 8/8 |
| `street_17_hybride_street_course` | intermédiaire | 12 | 0 | 0.92 | 6/6 |

### Qualité par critère

| Profil | `volume_bande` | `frequence_prioritaires` | `specificite` | `progression_planifiee` | `equilibre_poussee_tirage` | `points_faibles` | `affutage_aligne` | `variete_utile` | `non_ressemblance_proprietaire` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 0.79 | — | — | 1.00 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_02_hypertrophie_intermediaire` | 0.86 | — | — | 1.00 | 0.92 | 0.50 | — | 1.00 | 1.00 |
| `autres_03_powerlifter_competition` | 0.57 | 1.00 | 1.00 | 0.75 | 1.00 | — | 1.00 | 1.00 | 1.00 |
| `autres_04_force_generale_46_ans` | 0.57 | 1.00 | — | 0.83 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_05_course_10_km_debutante` | 0.21 | 1.00 | 0.00 | — | — | — | 0.67 | 1.00 | 1.00 |
| `autres_06_semi_marathon_intermediaire` | — | 1.00 | 0.00 | — | — | — | 0.67 | 1.00 | 1.00 |
| `autres_07_mobilite_sante_senior` | 0.50 | — | — | 1.00 | 1.00 | — | — | 1.00 | 1.00 |
| `autres_08_crossfit_intermediaire` | 0.43 | 1.00 | — | 0.60 | 0.92 | — | — | 1.00 | 1.00 |
| `autres_09_perte_de_poids_debutante` | 0.71 | — | — | 1.00 | 0.60 | — | — | 1.00 | 1.00 |
| `autres_10_contraintes_multiples` | 0.43 | — | — | 0.91 | 0.71 | — | — | 1.00 | 1.00 |
| `street_01_debutant_complet` | 0.64 | 1.00 | — | 0.79 | 0.88 | — | — | 1.00 | 1.00 |
| `street_02_debutant_surpoids` | 0.43 | — | — | 1.00 | 0.55 | — | — | 1.00 | 1.00 |
| `street_03_debutante` | 0.36 | 1.00 | — | 0.94 | 0.67 | — | — | 0.88 | 1.00 |
| `street_04_reprise_longue_pause` | 0.00 | — | — | 0.38 | 1.00 | — | — | 1.00 | 1.00 |
| `street_05_inter_calisthenie_front_lever` | 0.50 | 1.00 | — | 1.00 | 0.81 | 1.00 | — | 1.00 | 1.00 |
| `street_06_inter_sets_reps` | 0.50 | 1.00 | — | 0.45 | 1.00 | — | — | 1.00 | 1.00 |
| `street_07_avance_streetlifting_competition` | 0.64 | 1.00 | 1.00 | 0.90 | 1.00 | 1.00 | 1.00 | 0.97 | 1.00 |
| `street_08_avance_sets_reps_competition` | 0.36 | 1.00 | 0.72 | 0.63 | 0.94 | — | 1.00 | 1.00 | 1.00 |
| `street_09_elite_streetlifting` | 0.71 | 1.00 | 1.00 | 0.92 | 1.00 | 1.00 | 1.00 | 0.95 | 1.00 |
| `street_10_elite_figures` | 0.21 | 1.00 | — | 0.67 | 1.00 | — | — | 1.00 | 1.00 |
| `street_11_master_51_ans` | 0.57 | 1.00 | — | 0.93 | 1.00 | — | — | 1.00 | 1.00 |
| `street_12_antecedent_coude` | 0.57 | 1.00 | — | 0.50 | 0.82 | — | — | 1.00 | 1.00 |
| `street_13_peu_de_temps` | 0.43 | 1.00 | — | 0.90 | 1.00 | — | — | 0.95 | 1.00 |
| `street_14_parc_sans_lest` | 0.57 | 1.00 | — | 0.60 | 1.00 | — | — | 1.00 | 1.00 |
| `street_15_travail_physique_sommeil_court` | 0.57 | 1.00 | — | 0.88 | 1.00 | — | — | 0.96 | 1.00 |
| `street_16_specialisation_traction_lestee` | 0.29 | 1.00 | 0.84 | 0.43 | 0.53 | — | 1.00 | 1.00 | 1.00 |
| `street_17_hybride_street_course` | 0.57 | 1.00 | — | 1.00 | 1.00 | — | — | 0.95 | 1.00 |

## 2. Trajectoires simulées

| Profil | Séances faites | Échecs non voulus | Écart au RIR visé (cibles atteignables) | Cibles atteignables | Plus forte hausse (principal) | Gain réel (%/sem) | Performance à l'échéance | Déblocages non respectés | Repères non tenus | Violations (programme évolué) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 36/36 | 0.003 | 2.159 | 1.0 | 0.167 | 0.42 | — | 0 | ecart_rir, ecart_effort | 0 |
| `autres_02_hypertrophie_intermediaire` | 60/60 | 0.009 | 2.867 | 0.947 | 0.143 | 0.181 | — | 0 | ecart_rir, pics_de_charge, ecart_effort, pics_a_schema_egal | 0 |
| `autres_03_powerlifter_competition` | 40/40 | 0.0 | 2.527 | 0.928 | 0.27 | 0.088 | 1.015 | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `autres_04_force_generale_46_ans` | 48/48 | 0.003 | 3.066 | 0.91 | 0.227 | 0.239 | — | 0 | ecart_rir, pics_de_charge, ecart_effort, pics_a_schema_egal | 0 |
| `autres_05_course_10_km_debutante` | 34/36 | 0.0 | 3.393 | 0.386 | 0.0 | — | — | 0 | ecart_rir, ecart_effort | 0 |
| `autres_06_semi_marathon_intermediaire` | 46/48 | 0.0 | 1.218 | 0.579 | 0.0 | — | — | 0 | ecart_rir | 0 |
| `autres_07_mobilite_sante_senior` | 46/48 | 0.0 | 5.117 | 0.678 | 0.0 | 1.376 | — | 0 | ecart_rir, ecart_effort | 0 |
| `autres_08_crossfit_intermediaire` | 79/80 | 0.006 | 1.742 | 0.601 | 0.171 | 0.188 | — | 0 | ecart_rir, pics_de_charge, ecart_effort, pics_a_schema_egal | 0 |
| `autres_09_perte_de_poids_debutante` | 36/36 | 0.0 | 2.658 | 1.0 | 0.333 | 0.485 | — | 0 | ecart_rir, ecart_effort | 0 |
| `autres_10_contraintes_multiples` | 36/36 | 0.0 | 1.939 | 0.992 | 0.2 | 0.922 | — | 0 | ecart_rir, ecart_effort, pics_a_schema_egal | 0 |
| `street_01_debutant_complet` | 36/36 | 0.0 | 3.024 | 0.779 | 0.0 | 0.894 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_02_debutant_surpoids` | 36/36 | 0.0 | 2.413 | 0.68 | 0.0 | 1.196 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_03_debutante` | 36/36 | 0.0 | 3.919 | 0.62 | 0.0 | 0.749 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_04_reprise_longue_pause` | 48/48 | 0.0 | 2.975 | 0.443 | 0.0 | 0.532 | — | 0 | ecart_rir | 0 |
| `street_05_inter_calisthenie_front_lever` | 63/64 | 0.0 | 1.643 | 0.671 | 0.0 | — | — | 0 | ecart_rir | 0 |
| `street_06_inter_sets_reps` | 48/48 | 0.0 | 2.159 | 0.58 | 0.0 | 0.304 | — | 0 | ecart_rir | 0 |
| `street_07_avance_streetlifting_competition` | 60/60 | 0.0 | 2.718 | 0.673 | 0.326 | 0.062 | 1.012 | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `street_08_avance_sets_reps_competition` | 40/40 | 0.0 | 3.561 | 0.534 | 0.0 | 0.158 | 0.851 | 0 | ecart_rir, performance_echeance, ecart_effort | 0 |
| `street_09_elite_streetlifting` | 60/60 | 0.003 | 3.18 | 0.604 | 0.333 | 0.025 | 1.01 | 0 | ecart_rir, pics_de_charge | 0 |
| `street_10_elite_figures` | 91/96 | 0.0 | 2.182 | 0.285 | 0.0 | 0.069 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_11_master_51_ans` | 48/48 | 0.0 | 1.609 | 0.752 | 0.068 | 0.25 | — | 0 | ecart_rir | 0 |
| `street_12_antecedent_coude` | 48/48 | 0.0 | 2.484 | 0.628 | 0.313 | 0.256 | — | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `street_13_peu_de_temps` | 34/36 | 0.0 | 1.706 | 0.725 | 0.0 | 0.577 | — | 0 | ecart_rir, ecart_effort | 0 |
| `street_14_parc_sans_lest` | 46/48 | 0.0 | 2.383 | 0.647 | 0.0 | 0.358 | — | 0 | ecart_rir | 0 |
| `street_15_travail_physique_sommeil_court` | 36/36 | 0.0 | 2.045 | 0.675 | 0.0 | 0.549 | — | 0 | ecart_rir | 0 |
| `street_16_specialisation_traction_lestee` | 40/40 | 0.002 | 2.313 | 0.712 | 0.322 | 0.117 | 1.045 | 0 | ecart_rir, pics_de_charge, ecart_effort | 0 |
| `street_17_hybride_street_course` | 58/60 | 0.0 | 1.875 | 0.606 | 0.0 | 0.513 | — | 0 | ecart_rir, ecart_effort | 0 |

## 3. Détail par profil

### `autres_01_debutant_musculation` — Débutant en musculation

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.79 — 11 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde postérieur, lombaires, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 12 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 54 / 54 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 18 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.095, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Au moins 2 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 2.0)
- tenue — Squat ou presse au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Tirage au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Pectoraux : pas plus de 12 séries dures par semaine (mesuré : 5.0 séries dures par semaine en montée)
- tenue — Quadriceps : au moins 5 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)
- tenue — Aucun exercice avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_02_hypertrophie_intermediaire` — Hypertrophie esthétique, intermédiaire

Non transmis au moteur par le profil actuel : points faibles musculaires (le profil ne porte que les points faibles d'un mouvement).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.86 — 12 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : abdominaux, lombaires.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 15 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 15 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.92 — Séries dures de tirage / de poussée sur les semaines de montée : 108 / 117 (rapport 0.92).
- Couverture des points faibles : 0.50 — 1 points faibles couverts sur 2 vérifiables ; non couverts : delt_middle : 11.0 séries/sem (attendu ≥ 14).
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 29 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.156, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Fessiers : au moins 14 séries dures par semaine (mesuré : 16.0 séries dures par semaine en montée)
- tenue — Deltoïde moyen : au moins 10 séries dures par semaine (mesuré : 11.0 séries dures par semaine en montée)
- tenue — Fessiers : pas plus de 25 séries dures par semaine (mesuré : 16.0 séries dures par semaine en montée)
- tenue — Pas plus de 7 semaines de charge sans allègement (mesuré : 5 semaines de charge de suite au plus)
- tenue — Isolation des épaules au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_03_powerlifter_competition` — Powerlifter, compétition dans 10 semaines

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, haut du dos, biceps, abdominaux, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 48 % avant les quatre dernières semaines, 49 % pendant.
- Progression planifiée : 0.75 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 68 / 60 (rapport 1.13).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 10) : nature test, volume 57 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 10.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 24 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.098, exercices × schémas 0.021 (seuil 0.3).

Attentes de coach (6/7) :
- tenue — Volume réduit de 30 à 70 % la semaine de la compétition (mesuré : volume 57 % sous le pic la semaine de l'échéance)
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Développé couché au moins trois fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)
- tenue — Soulevé de terre au moins une fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Charges chiffrées sur les trois mouvements (mesuré : 36 prescriptions chargées ou en % du 1RM sur 48)
- tenue — Une exposition lourde par semaine au moins au squat (mesuré : 2.0 exposition(s) lourde(s) par semaine en montée)
- tenue — Épreuve sur les trois mouvements la semaine de la compétition (mesuré : 3 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : test))

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_04_force_generale_46_ans` — Force générale après 40 ans

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, haut du dos, biceps, abdominaux, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.83 — Sur 6 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 5 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 99 / 99 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 20 emplacements ; 0 doublons de chaîne dans une même séance ; 12 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.146, exercices × schémas 0.020 (seuil 0.3).

Attentes de coach (3/5) :
- tenue — Squat au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- **non tenue** — Charges chiffrées au squat et au développé couché (mesuré : 44 prescriptions chargées ou en % du 1RM sur 55)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Jamais moins d'une répétition en réserve (mesuré : RIR le plus bas des 16 premières semaines : 2.0)
- **non tenue** — Au moins 20 minutes de mobilité par semaine (mesuré : 13 min par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_05_course_10_km_debutante` — Course : premier 10 km

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.21 — 3 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, grand dorsal, haut du dos, biceps, triceps, abdominaux, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.00 — Part des séries dures sur les mouvements de l'échéance : 0 % avant les quatre dernières semaines, 0 % pendant.
- Progression planifiée : sans objet — Sur 0 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 0 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : sans objet — Séries dures de tirage / de poussée sur les semaines de montée : 0 / 0.
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.67 — Semaine de l'échéance (semaine 12) : nature test, volume 100 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 1.00 — 2 exercices de renforcement distincts en première semaine pour 4 emplacements ; 0 doublons de chaîne dans une même séance ; 2 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (3/5) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 105 min par semaine en montée)
- **non tenue** — Pas de sprint (mesuré : présents : Éducatif de course montées de genoux)
- tenue — Semaine de la course allégée d'au moins 20 % (mesuré : volume 100 % sous le pic la semaine de l'échéance)
- tenue — Pas plus de 4 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- **non tenue** — Séances de 65 minutes au plus (mesuré : séance la plus longue : 79 min estimées)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_06_semi_marathon_intermediaire` — Semi-marathon, intermédiaire

Non transmis au moteur par le profil actuel : libellé de l'échéance.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : sans objet — Sans objet : programme sans renforcement dominant.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.00 — Part des séries dures sur les mouvements de l'échéance : 0 % avant les quatre dernières semaines, 0 % pendant.
- Progression planifiée : sans objet — Sans objet : programme sans renforcement dominant.
- Équilibre poussée / tirage : sans objet — Sans objet : programme sans renforcement dominant.
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 0.67 — Semaine de l'échéance (semaine 12) : nature test, volume 100 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 12.
- Variété utile : 1.00 — 2 exercices de renforcement distincts en première semaine pour 4 emplacements ; 0 doublons de chaîne dans une même séance ; 2 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/5) :
- tenue — Au moins 180 minutes de course par semaine (mesuré : 206 min par semaine en montée)
- **non tenue** — Une séance de qualité (fractionné) par semaine (mesuré : 0.5 séance(s) par semaine en montée)
- tenue — Sortie longue chaque semaine (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Pas plus de 4 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Une semaine allégée ou de test avant la course (mesuré : 1 semaine(s) de nature test)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_07_mobilite_sante_senior` — Mobilité et santé, senior

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 10 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 54 / 54 (rapport 1.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 5 exercices de renforcement distincts en première semaine pour 11 emplacements ; 0 doublons de chaîne dans une même séance ; 5 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Ni saut, ni sprint, ni corde (mesuré : aucun)
- tenue — Au moins 30 minutes de mobilité par semaine (mesuré : 38 min par semaine en montée)
- tenue — Séances de 33 minutes au plus (mesuré : séance la plus longue : 30 min estimées)
- tenue — Au moins 3 répétitions en réserve (mesuré : RIR le plus bas des 12 premières semaines : 3.0)
- tenue — Renforcement des jambes (squat, fente, assis-debout) au moins deux fois par semaine (mesuré : 4.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_08_crossfit_intermediaire` — CrossFit, intermédiaire

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.43 — 6 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, haut du dos, biceps, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.92 — Séries dures de tirage / de poussée sur les semaines de montée : 87 / 95 (rapport 0.92).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 12 exercices de renforcement distincts en première semaine pour 18 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.077, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/5) :
- tenue — Formats codifiés (AMRAP, EMOM, tours) (mesuré : formats : amrap, emom)
- tenue — Haltérophilie ou force à la barre au moins trois fois par semaine (mesuré : 5.0 séance(s) par semaine en montée)
- **non tenue** — Au moins 30 minutes de conditionnement par semaine (mesuré : 14 min par semaine en montée)
- tenue — Pas plus de 7 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Travail vers le muscle-up au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_09_perte_de_poids_debutante` — Perte de poids, débutante

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.71 — 10 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde postérieur, biceps, lombaires, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.60 — Séries dures de tirage / de poussée sur les semaines de montée : 54 / 90 (rapport 0.60).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 8 exercices de renforcement distincts en première semaine pour 17 emplacements ; 0 doublons de chaîne dans une même séance ; 8 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.063, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Ni saut, ni sprint, ni corde, ni burpees (mesuré : aucun)
- tenue — Pas de course à pied au début (mesuré : aucun)
- tenue — Au moins 30 minutes de cardio à faible impact par semaine (mesuré : 36 min par semaine en montée)
- tenue — Au moins 2 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Quadriceps : au moins 4 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)
- tenue — Exercices de niveau débutant ou intermédiaire (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `autres_10_contraintes_multiples` — Contraintes multiples

Non transmis au moteur par le profil actuel : description de la blessure.

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.43 — 6 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde moyen, deltoïde postérieur, biceps, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.91 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 10 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.71 — Séries dures de tirage / de poussée sur les semaines de montée : 48 / 68 (rapport 0.71).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 7 exercices de renforcement distincts en première semaine pour 15 emplacements ; 0 doublons de chaîne dans une même séance ; 7 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.026, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Aucun exercice à contrainte forte sur le genou (mesuré : aucun)
- tenue — Ni saut, ni sprint, ni course (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 3.0)
- tenue — Séances de 44 minutes au plus (mesuré : séance la plus longue : 39 min estimées)
- tenue — Quadriceps : pas plus de 8 séries dures par semaine (mesuré : 5.9 séries dures par semaine en montée)
- tenue — Au moins 15 minutes de mobilité par semaine (mesuré : 21 min par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_01_debutant_complet` — Débutant complet, aucune traction

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.64 — 9 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.79 — Sur 14 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.88 — Séries dures de tirage / de poussée sur les semaines de montée : 52 / 59 (rapport 0.88).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 10 exercices de renforcement distincts en première semaine pour 23 emplacements ; 0 doublons de chaîne dans une même séance ; 13 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.050, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (7/7) :
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Travail de traction adapté (assistée, négative ou suspension) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes (squat ou fente) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 6.5 séries dures par semaine en montée)
- tenue — Séances de 50 minutes au plus (mesuré : séance la plus longue : 37 min estimées)
- tenue — Aucun exercice de niveau avancé ou élite (mesuré : aucun au-dessus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_02_debutant_surpoids` — Débutant sédentaire en surpoids

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.43 — 6 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, triceps, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 11 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.55 — Séries dures de tirage / de poussée sur les semaines de montée : 98 / 27 (rapport 3.63).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 7 exercices de renforcement distincts en première semaine pour 16 emplacements ; 0 doublons de chaîne dans une même séance ; 8 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.000, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Ni pliométrie, ni sprint, ni corde à sauter, ni balistique (mesuré : aucun)
- tenue — Au moins 3 répétitions en réserve les quatre premières semaines (mesuré : RIR le plus bas des 4 premières semaines : 3.0)
- tenue — Exercices de niveau débutant seulement (mesuré : aucun au-dessus)
- tenue — Tirage horizontal au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Séances de 45 minutes au plus (mesuré : séance la plus longue : 36 min estimées)
- tenue — Pectoraux : pas plus de 10 séries dures par semaine (mesuré : 3.0 séries dures par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_03_debutante` — Débutante, objectif première traction

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.36 — 5 groupes majeurs sur 14 entre 4 et 12 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, biceps, triceps, abdominaux, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.94 — Sur 17 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 16 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.67 — Séries dures de tirage / de poussée sur les semaines de montée : 60 / 20 (rapport 3.00).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.88 — 11 exercices de renforcement distincts en première semaine pour 25 emplacements ; 3 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.043, exercices × schémas 0.000 (seuil 0.3).

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
- Volume par muscle dans la bande du référentiel : 0.00 — 0 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : pectoraux, deltoïde antérieur, deltoïde moyen, deltoïde postérieur, grand dorsal, haut du dos, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : sans objet — Sans objet : aucun mouvement prioritaire déclaré.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.38 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 2 ; seulement en séries ou en effort : 2.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 66 / 51 (rapport 1.29).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 13 exercices de renforcement distincts en première semaine pour 27 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.136, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (4/4) :
- tenue — Au moins 3 répétitions en réserve les deux premières semaines (mesuré : RIR le plus bas des 2 premières semaines : 3.0)
- tenue — Grand dorsal : pas plus de 16 séries dures par semaine (mesuré : 7.6 séries dures par semaine en montée)
- tenue — Pas de négatives ni d'excentriques accentués (mesuré : aucun)
- tenue — Tractions (ou un palier) au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_05_inter_calisthenie_front_lever` — Intermédiaire calisthénie, premiers muscle-ups, objectif front lever

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, biceps, lombaires, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 1.00 — Sur 13 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 13 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 0.81 — Séries dures de tirage / de poussée sur les semaines de montée : 146 / 59 (rapport 2.47).
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
- Volume par muscle dans la bande du référentiel : 0.50 — 7 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.45 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 4 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 92 / 60 (rapport 1.53).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 17 exercices de renforcement distincts en première semaine pour 32 emplacements ; 0 doublons de chaîne dans une même séance ; 18 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.235, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions et de dips en densité (repos de 90 s au plus, EMOM, tours) (mesuré : 57 % des séries avec 90s de repos ou moins (ou en format de densité))
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
- Volume par muscle dans la bande du référentiel : 0.36 — 5 groupes majeurs sur 14 entre 10 et 25 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, lombaires, fessiers, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : 0.72 — Part des séries dures sur les mouvements de l'échéance : 24 % avant les quatre dernières semaines, 29 % pendant.
- Progression planifiée : 0.63 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 0.94 — Séries dures de tirage / de poussée sur les semaines de montée : 62 / 29 (rapport 2.14).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : 1.00 — Semaine de l'échéance (semaine 8) : nature test, volume 63 % sous le pic des six semaines précédentes ; épreuve la plus proche : semaine 8.
- Variété utile : 1.00 — 15 exercices de renforcement distincts en première semaine pour 38 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.250, exercices × schémas 0.020 (seuil 0.3).

Attentes de coach (7/8) :
- tenue — Volume réduit de 40 à 60 % la semaine de la compétition (mesuré : volume 63 % sous le pic la semaine de l'échéance)
- **non tenue** — Tractions au moins quatre fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Muscle-ups au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Dips au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins la moitié des séries de tractions, dips et muscle-ups en densité (mesuré : 58 % des séries avec 90s de repos ou moins (ou en format de densité))
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
- Spécificité à l'approche de l'échéance : 1.00 — Part des séries dures sur les mouvements de l'échéance : 53 % avant les quatre dernières semaines, 58 % pendant.
- Progression planifiée : 0.92 — Sur 12 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 11 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 144 / 112 (rapport 1.29).
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
- Volume par muscle dans la bande du référentiel : 0.21 — 3 groupes majeurs sur 14 entre 12 et 30 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, haut du dos, biceps, triceps, lombaires, fessiers, quadriceps, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.67 — Sur 18 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 12 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 155 / 100 (rapport 1.55).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 17 exercices de renforcement distincts en première semaine pour 40 emplacements ; 0 doublons de chaîne dans une même séance ; 17 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.121, exercices × schémas 0.042 (seuil 0.3).

Attentes de coach (6/7) :
- **non tenue** — Planche (un palier) au moins trois fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
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
- Progression planifiée : 0.93 — Sur 7 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 1.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 141 / 99 (rapport 1.42).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 14 exercices de renforcement distincts en première semaine pour 25 emplacements ; 0 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.235, exercices × schémas 0.020 (seuil 0.3).

Attentes de coach (5/5) :
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Jamais moins d'une répétition en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 2.0)
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : pas plus de 18 séries dures par semaine (mesuré : 12.8 séries dures par semaine en montée)

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
- Volume par muscle dans la bande du référentiel : 0.43 — 6 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde antérieur, deltoïde moyen, deltoïde postérieur, biceps, triceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.90 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 9 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 93 / 48 (rapport 1.94).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.95 — 10 exercices de renforcement distincts en première semaine pour 21 emplacements ; 1 doublons de chaîne dans une même séance ; 11 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.200, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Séances de 48 minutes au plus (mesuré : séance la plus longue : 33 min estimées)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Jambes au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 11.6 séries dures par semaine en montée)
- tenue — Pectoraux : au moins 4 séries dures par semaine (mesuré : 9.4 séries dures par semaine en montée)
- tenue — Supersets pour gagner du temps (mesuré : formats : superset)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_14_parc_sans_lest` — Parc seulement, sans lest ni élastique

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.60 — Sur 10 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 6 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 92 / 85 (rapport 1.08).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 1.00 — 14 exercices de renforcement distincts en première semaine pour 27 emplacements ; 0 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.222, exercices × schémas 0.028 (seuil 0.3).

Attentes de coach (4/5) :
- tenue — Tractions au moins trois fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Au moins un tiers des séries de tractions en densité (mesuré : 57 % des séries avec 90s de repos ou moins (ou en format de densité))
- tenue — Jambes au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)
- **non tenue** — Une variante dure de traction (archer, typewriter, poitrine à la barre) au moins une fois par semaine (mesuré : 0.5 séance(s) par semaine en montée)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

### `street_15_travail_physique_sommeil_court` — Travail physique et sommeil court

Non transmis au moteur par le profil actuel : qualité du sommeil (seule la durée est transmise).

Sécurité : aucune violation.

Qualité :
- Volume par muscle dans la bande du référentiel : 0.57 — 8 groupes majeurs sur 14 entre 8 et 20 séries dures par semaine (semaines de montée) ; sous le plancher : deltoïde moyen, deltoïde postérieur, biceps, lombaires, ischio-jambiers, mollets.
- Fréquence des mouvements prioritaires : 1.00 — Séances par semaine où chaque mouvement prioritaire (ou un palier de sa chaîne) est travaillé ; attendu : au moins 2.
- Spécificité à l'approche de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire à six semaines ou plus.
- Progression planifiée : 0.88 — Sur 8 mouvements principaux, secondaires ou figures du premier bloc — en charge, en répétitions ou en durée entre la première et la dernière semaine de montée : 7 ; seulement en séries ou en effort : 0.
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 73 / 72 (rapport 1.01).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.96 — 14 exercices de renforcement distincts en première semaine pour 24 emplacements ; 1 doublons de chaîne dans une même séance ; 15 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.188, exercices × schémas 0.000 (seuil 0.3).

Attentes de coach (5/6) :
- tenue — Grand dorsal : pas plus de 12 séries dures par semaine (mesuré : 9.1 séries dures par semaine en montée)
- tenue — Quadriceps : pas plus de 10 séries dures par semaine (mesuré : 10.0 séries dures par semaine en montée)
- **non tenue** — Jamais moins de 2 répétitions en réserve sur les 12 semaines (mesuré : RIR le plus bas des 12 premières semaines : 1.0)
- tenue — Tractions au moins deux fois par semaine (mesuré : 3.0 séance(s) par semaine en montée)
- tenue — Séances de 62 minutes au plus (mesuré : séance la plus longue : 45 min estimées)
- tenue — Grand dorsal : au moins 6 séries dures par semaine (mesuré : 9.1 séries dures par semaine en montée)

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
- Équilibre poussée / tirage : 1.00 — Séries dures de tirage / de poussée sur les semaines de montée : 113 / 72 (rapport 1.57).
- Couverture des points faibles : sans objet — Sans objet : aucun point faible déclaré.
- Affûtage aligné sur la date de l'échéance : sans objet — Sans objet : pas d'échéance prioritaire dans le programme.
- Variété utile : 0.95 — 13 exercices de renforcement distincts en première semaine pour 22 emplacements ; 1 doublons de chaîne dans une même séance ; 14 exercices distincts sur tout le programme.
- Non-ressemblance au programme du propriétaire : 1.00 — Indice de Jaccard le plus haut entre une semaine générée et une semaine du propriétaire : exercices 0.143, exercices × schémas 0.053 (seuil 0.3).

Attentes de coach (6/6) :
- tenue — Au moins 90 minutes de course par semaine (mesuré : 111 min par semaine en montée)
- tenue — Tractions au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Dips au moins deux fois par semaine (mesuré : 2.0 séance(s) par semaine en montée)
- tenue — Au plus une séance de course intense par semaine : une séance de fractionné présente (mesuré : 1.0 séance(s) par semaine en montée)
- tenue — Quadriceps : pas plus de 12 séries dures par semaine (mesuré : 9.0 séries dures par semaine en montée)
- tenue — Pas plus de 6 semaines de charge sans allègement (mesuré : 4 semaines de charge de suite au plus)

Programme tel qu'il a évolué sous le moteur d'évolution : 0 violation(s) de sécurité.

