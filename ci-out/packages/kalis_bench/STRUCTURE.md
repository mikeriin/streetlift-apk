# Structure de la semaine — critères du lot KS1

Mesures automatiques (`pipeline/cp/CAHIER_KS.md`, § 9) sur les 34 profils (banc et profils ajoutés `profiles_ks`), graine 0, horizon du profil (le profil de test sur 40 semaines). Couverture, temps et principal : semaines de charge (ni introduction, ni allègement, ni test) ; temps estimé par `coachSessionSeconds` de `kalis_plan` ; récupération : composante `recovery` de la note de chaque bloc, profils à 4 séances et plus.

| Critère | Seuil | Mesuré | Tenu |
| --- | --- | --- | --- |
| Violations de sécurité (programmes créés) | 0 | 0 | oui |
| Violations de sécurité (saisons des profils ajoutés, modèle B, graine 0, scénarios) | 0 | 2 | **non** |
| Couverture des objectifs (semaines de charge) | 100 % | 100,0 % (0 couple(s) sans porteur) | oui |
| Récupération ≥ 0,9 par bloc (4 séances et plus) | 0 bloc sous le seuil | 2 | **non** |
| Temps par séance ± 15 % | 0 séance hors bande | 1175 sur 1329 | **non** |
| Séance sans principal | 0 | 51 | **non** |
| Squelette des profils mono-discipline identique à 0.3.1 | tous, sauf écart justifié | 27 sur 27 | oui |
| Ordre par exigence : mouvement le plus exigeant en tête de séance | 0 séance | 0 sur 149 | oui |
| Ordre par exigence : son jour en tête de la rotation | 0 bloc | 12 sur 44 | **non** |
| Jour typé sans exercice de son schéma (KS1c2), 34 profils du banc (34 profils, 399 jours) | 0 | 0 | oui |
| Jour d'un gabarit typé sans emplacement principal (KS1c2), 34 profils du banc | 0 | 0 | oui |
| Jour typé sans exercice de son schéma (KS1c2), grille des profils incomplets (576 profils, 8928 jours) | 0 | 0 | oui |
| Jour d'un gabarit typé sans emplacement principal (KS1c2), grille des profils incomplets | 0 | 0 | oui |
| Violations de sécurité (programmes créés), grille des profils incomplets | 0 | 0 profil(s) | oui |
| Profil de test : gabarit ppl6_q à chaque bloc | oui | oui | oui |
| Profil de test : muscle-up lesté en tête du premier jour, qui ouvre la rotation | oui | oui | oui |
| Profil de test : neuf objectifs et quatre cibles de l'échéance portés chaque semaine de charge | oui | oui | oui |
| Profil de test : chaque schéma deux fois par semaine, à 72 h | oui | oui | oui |
| Profil de test : aucun schéma lourd deux jours de suite | oui | oui | oui |
| Profil de test : séances de 100 à 125 min (semaines de charge) | oui | non | **non** |
| Profil de test : aucune séance sans principal | oui | oui | oui |
| Profil de test : premier jour : tirage, force | oui | oui | oui |

Critère KS1c2 : un exercice porteur est un emplacement principal, secondaire ou de figure du schéma. Les gabarits d'avant 0.4.0 (figés par le critère d'identité) écrivent des jours de volume en secondaires : 291 jour(s) sans emplacement principal, leurs schémas tous portés (comptés à part, comme au lot KS1).

## Blocs sous le seuil de récupération

- `autres_02_hypertrophie_intermediaire` bloc 0 (0,852, gabarit inchangé)
- `autres_02_hypertrophie_intermediaire` bloc 1 (0,852, gabarit inchangé)

## Séances sans principal

- `autres_03_powerlifter_competition` 0/3 (gabarit inchangé)
- `autres_03_powerlifter_competition` 1/3 (gabarit inchangé)
- `autres_04_force_generale_46_ans` 0/2 (gabarit inchangé)
- `autres_04_force_generale_46_ans` 1/2 (gabarit inchangé)
- `autres_04_force_generale_46_ans` 2/2 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 0/1 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 0/2 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 0/4 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 1/1 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 1/2 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 1/4 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 2/1 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 2/2 (gabarit inchangé)
- `autres_08_crossfit_intermediaire` 2/4 (gabarit inchangé)
- `street_04_reprise_longue_pause` 0/1 (gabarit inchangé)
- `street_04_reprise_longue_pause` 0/3 (gabarit inchangé)
- `street_04_reprise_longue_pause` 1/1 (gabarit inchangé)
- `street_04_reprise_longue_pause` 1/3 (gabarit inchangé)
- `street_07_avance_streetlifting_competition` 0/3 (gabarit inchangé)
- `street_07_avance_streetlifting_competition` 1/3 (gabarit inchangé)
- `street_07_avance_streetlifting_competition` 2/3 (gabarit inchangé)
- `street_08_avance_sets_reps_competition` 0/1 (gabarit inchangé)
- `street_08_avance_sets_reps_competition` 1/1 (gabarit inchangé)
- `street_09_elite_streetlifting` 0/3 (gabarit inchangé)
- `street_09_elite_streetlifting` 1/3 (gabarit inchangé)
- `street_09_elite_streetlifting` 2/3 (gabarit inchangé)
- `street_10_elite_figures` 0/1 (gabarit inchangé)
- `street_10_elite_figures` 0/4 (gabarit inchangé)
- `street_10_elite_figures` 1/1 (gabarit inchangé)
- `street_10_elite_figures` 1/4 (gabarit inchangé)
- `street_10_elite_figures` 2/1 (gabarit inchangé)
- `street_10_elite_figures` 2/4 (gabarit inchangé)
- `street_10_elite_figures` 3/1 (gabarit inchangé)
- `street_10_elite_figures` 3/4 (gabarit inchangé)
- `street_13_peu_de_temps` 0/1 (gabarit inchangé)
- `street_13_peu_de_temps` 0/2 (gabarit inchangé)
- `street_13_peu_de_temps` 1/1 (gabarit inchangé)
- `street_13_peu_de_temps` 1/2 (gabarit inchangé)
- `street_15_travail_physique_sommeil_court` 0/1 (gabarit inchangé)
- `street_15_travail_physique_sommeil_court` 1/1 (gabarit inchangé)
- `street_16_specialisation_traction_lestee` 0/1 (gabarit inchangé)
- `street_16_specialisation_traction_lestee` 0/2 (gabarit inchangé)
- `street_16_specialisation_traction_lestee` 1/1 (gabarit inchangé)
- `street_16_specialisation_traction_lestee` 1/2 (gabarit inchangé)
- `street_17_hybride_street_course` 0/0 (gabarit inchangé)
- `street_17_hybride_street_course` 1/0 (gabarit inchangé)
- `ks_05_force_hypertrophie` 0/3 (gabarit inchangé)
- `ks_05_force_hypertrophie` 1/3 (gabarit inchangé)
- `ks_06_calisthenie_sets_reps_30` 0/3 (gabarit inchangé)
- `ks_06_calisthenie_sets_reps_30` 1/3 (gabarit inchangé)
- `ks_06_calisthenie_sets_reps_30` 2/3 (gabarit inchangé)

## Blocs où le jour le plus exigeant n'ouvre pas la rotation

- `street_07_avance_streetlifting_competition` bloc 0 (gabarit inchangé)
- `street_07_avance_streetlifting_competition` bloc 1 (gabarit inchangé)
- `street_07_avance_streetlifting_competition` bloc 2 (gabarit inchangé)
- `street_08_avance_sets_reps_competition` bloc 0 (gabarit inchangé)
- `street_08_avance_sets_reps_competition` bloc 1 (gabarit inchangé)
- `street_09_elite_streetlifting` bloc 0 (gabarit inchangé)
- `street_09_elite_streetlifting` bloc 1 (gabarit inchangé)
- `street_09_elite_streetlifting` bloc 2 (gabarit inchangé)
- `street_10_elite_figures` bloc 0 (gabarit inchangé)
- `street_10_elite_figures` bloc 1 (gabarit inchangé)
- `street_10_elite_figures` bloc 2 (gabarit inchangé)
- `street_10_elite_figures` bloc 3 (gabarit inchangé)

## Par profil

| Profil | Séances | Gabarit | Sécurité | Objectifs sans porteur | Récupération (min) | Temps hors bande | Sans principal | Avant (0.3.1) : récupération, sans porteur, temps hors bande |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 3 | gym_split | 0 | 0 | 1,000 | 27 sur 27 (51,2 % à 70,0 %) | 0 | 1,000 (0.1) ; 0 ; 27 sur 27 |
| `autres_02_hypertrophie_intermediaire` | 5 | gym_split | 0 | 0 | 0,852 | 45 sur 45 (40,3 % à 66,4 %) | 0 | 0,905 (0.1) ; 0 ; 45 sur 45 |
| `autres_03_powerlifter_competition` | 4 | power_dup | 0 | 0 | 1,000 | 24 sur 24 (34,4 % à 44,2 %) | 2 | 0,649 (0.1) ; 0 ; 24 sur 24 |
| `autres_04_force_generale_46_ans` | 3 | power_dup | 0 | 0 | 1,000 | 33 sur 33 (60,0 % à 68,8 %) | 3 | 1,000 (0.1) ; 0 ; 33 sur 33 |
| `autres_05_course_10_km_debutante` | 3 | run_week | 0 | 0 | 1,000 | 3 sur 24 (67,5 % à 96,4 %) | 0 | 1,000 (0.1) ; 0 ; 3 sur 24 |
| `autres_06_semi_marathon_intermediaire` | 4 | run_week | 0 | 0 | 1,000 | 11 sur 32 (49,6 % à 99,4 %) | 0 | 1,000 (0.1) ; 0 ; 11 sur 32 |
| `autres_07_mobilite_sante_senior` | 4 | health_week | 0 | 0 | 1,000 | 18 sur 36 (76,7 % à 99,8 %) | 0 | 0,803 (0.1) ; 0 ; 18 sur 36 |
| `autres_08_crossfit_intermediaire` | 5 | wod_week | 0 | 0 | 1,000 | 55 sur 55 (41,4 % à 84,3 %) | 9 | 0,474 (0.1) ; 0 ; 55 sur 55 |
| `autres_09_perte_de_poids_debutante` | 3 | health_week | 0 | 0 | 1,000 | 0 sur 27 (98,1 % à 99,9 %) | 0 | 1,000 (0.1) ; 0 ; 0 sur 27 |
| `autres_10_contraintes_multiples` | 3 | health_week | 0 | 0 | 1,000 | 15 sur 27 (60,2 % à 96,6 %) | 0 | 1,000 (0.1) ; 0 ; 15 sur 27 |
| `street_01_debutant_complet` | 3 | fb_beginner | 0 | 0 | 1,000 | 9 sur 24 (73,6 % à 97,4 %) | 0 | 1,000 (0.1) ; 0 ; 9 sur 24 |
| `street_02_debutant_surpoids` | 3 | fb_beginner | 0 | 0 | 1,000 | 0 sur 27 (86,4 % à 99,5 %) | 0 | 1,000 (0.1) ; 0 ; 0 sur 27 |
| `street_03_debutante` | 3 | fb_beginner | 0 | 0 | 1,000 | 23 sur 24 (52,8 % à 85,1 %) | 0 | 1,000 (0.1) ; 0 ; 23 sur 24 |
| `street_04_reprise_longue_pause` | 4 | reps_pillars | 0 | 0 | 1,000 | 36 sur 36 (35,6 % à 55,7 %) | 4 | 0,543 (0.1) ; 0 ; 36 sur 36 |
| `street_05_inter_calisthenie_front_lever` | 4 | figures | 0 | 0 | 1,000 | 44 sur 44 (44,3 % à 67,4 %) | 0 | 0,685 (0.1) ; 0 ; 44 sur 44 |
| `street_06_inter_sets_reps` | 4 | reps_pillars | 0 | 0 | 1,000 | 31 sur 32 (57,1 % à 86,8 %) | 0 | 0,766 (0.1) ; 0 ; 31 sur 32 |
| `street_07_avance_streetlifting_competition` | 5 | lift_dup | 0 | 0 | 1,000 | 35 sur 35 (44,3 % à 75,6 %) | 3 | 0,414 (0.1) ; 0 ; 35 sur 35 |
| `street_08_avance_sets_reps_competition` | 5 | reps_pillars | 0 | 0 | 1,000 | 20 sur 20 (39,0 % à 70,9 %) | 2 | 0,395 (0.1) ; 0 ; 20 sur 20 |
| `street_09_elite_streetlifting` | 5 | lift_dup | 0 | 0 | 1,000 | 35 sur 35 (38,4 % à 61,3 %) | 3 | 0,494 (0.1) ; 0 ; 35 sur 35 |
| `street_10_elite_figures` | 6 | figures | 0 | 0 | 1,000 | 66 sur 66 (23,5 % à 72,9 %) | 8 | 0,171 (0.1) ; 0 ; 66 sur 66 |
| `street_11_master_51_ans` | 3 | mix_q | 0 | 0 | 1,000 | 33 sur 33 (66,4 % à 82,3 %) | 0 | 1,000 (0.1) ; 0 ; 32 sur 33 |
| `street_12_antecedent_coude` | 4 | ul4 | 0 | 0 | 1,000 | 32 sur 32 (39,6 % à 55,7 %) | 0 | 0,778 (0.1) ; 0 ; 32 sur 32 |
| `street_13_peu_de_temps` | 3 | reps_pillars | 0 | 0 | 1,000 | 24 sur 24 (53,1 % à 73,8 %) | 4 | 1,000 (0.1) ; 0 ; 24 sur 24 |
| `street_14_parc_sans_lest` | 4 | reps_pillars | 0 | 0 | 1,000 | 32 sur 32 (49,8 % à 66,9 %) | 0 | 0,632 (0.1) ; 0 ; 32 sur 32 |
| `street_15_travail_physique_sommeil_court` | 3 | reps_pillars | 0 | 0 | 1,000 | 24 sur 24 (57,1 % à 78,2 %) | 2 | 1,000 (0.1) ; 0 ; 24 sur 24 |
| `street_16_specialisation_traction_lestee` | 4 | lift_dup | 0 | 0 | 1,000 | 24 sur 24 (27,9 % à 61,9 %) | 4 | 0,874 (0.1) ; 0 ; 24 sur 24 |
| `street_17_hybride_street_course` | 5 | reps_pillars | 0 | 0 | 1,000 | 31 sur 40 (54,7 % à 96,3 %) | 2 | 0,513 (0.1) ; 0 ; 31 sur 40 |
| `ks_01_streetlifting_sets_reps_4_seances` | 4 | ul4 | 0 | 0 | 1,000 | 44 sur 44 (40,6 % à 78,5 %) | 0 | 0,436 (0.1) ; 22 ; 44 sur 44 |
| `ks_02_streetlifting_sets_reps_5_seances` | 5 | pp_l5 | 0 | 0 | 1,000 | 55 sur 55 (43,0 % à 64,9 %) | 0 | 0,569 (0.1) ; 22 ; 55 sur 55 |
| `ks_03_streetlifting_sets_reps_6_seances` | 6 | ppl6_q | 0 | 0 | 1,000 | 66 sur 66 (35,2 % à 62,4 %) | 0 | 0,288 (0.1) ; 22 ; 66 sur 66 |
| `ks_04_sets_reps_principal_streetlifting_secondaire` | 4 | ul4 | 0 | 0 | 1,000 | 30 sur 32 (40,6 % à 85,0 %) | 0 | 0,528 (0.1) ; 0 ; 32 sur 32 |
| `ks_05_force_hypertrophie` | 4 | power_dup | 0 | 0 | 1,000 | 32 sur 32 (44,7 % à 67,3 %) | 2 | 0,414 (0.1) ; 0 ; 32 sur 32 |
| `ks_06_calisthenie_sets_reps_30` | 4 | figures | 0 | 0 | 1,000 | 44 sur 44 (50,2 % à 71,4 %) | 3 | 0,695 (0.1) ; 0 ; 44 sur 44 |
| `ks_test_ppl6` | 6 | ppl6_q | 0 | 0 | 1,000 | 174 sur 174 (26,8 % à 47,2 %) | 0 | 0,504 (0.1) ; 116 ; 174 sur 174 |
