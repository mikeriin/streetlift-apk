# kalis_plan face au générateur L10

Fichier généré par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (kalis_plan 0.2.2) à partir de `docs/data/l10_sorties.json.gz` — ne pas modifier à la main ; `test/docs_test.dart` le compare au moteur. Lecture et limites de la comparaison : `docs/VALIDATION.md`, § 5.

Les deux générateurs reçoivent les mêmes 40 profils types (kalis_core). L'ancien générateur (L10, version 1.0.0, graine 0) ne lit qu'une partie du profil : la traduction est décrite dans `tool/l10_export_test.dart.txt`. Semaine comparée : la semaine 3 de L10 (première semaine de charge sans calibrage) et la dernière semaine de montée de kalis_plan. Chaque durée est celle que le générateur estime lui-même ; les séries par groupe sont recomptées de la même façon des deux côtés (muscle principal 1, muscle secondaire 0,5, exercices de travail seulement).

| Critère | L10 | kalis_plan |
| --- | --- | --- |
| Profils dont chaque discipline a un programme | 9 sur 40 (dont 6 où la musculation est traitée comme un objectif de force) | 40 sur 40 |
| Erreur de dosage en trois familles — renforcement, cardio, mobilité — en points, moyenne (34 profils sans « forme générale ») | 23.8 | 0.4 |
| Profils à 10 points ou moins de leur dosage | 14 sur 34 | 34 sur 34 |
| Séances plus longues que le temps donné ce jour-là | 33 sur 143 (15 profils) | 0 sur 143 (0 profils) |
| Temps donné utilisé, moyenne | 91 % | 95 % |
| Groupes musculaires majeurs sous 4 séries par semaine, moyenne par profil (27 profils de renforcement) | 0.7 | 0.8 |
| Groupes musculaires majeurs au-dessus de 20 séries par semaine, moyenne par profil | 1.5 | 2.3 |
| Tirage et poussée équilibrés (rapport entre 2/3 et 3/2) | 21 sur 27 | 24 sur 27 |
| Chaîne postérieure et genou équilibrés (rapport entre 2/3 et 3/2) | 13 sur 27 | 26 sur 27 |
| Exercices à contrainte maximale sur une articulation dont la gêne est d'au moins 4/10 (4 profils) | 0 | 0 |

## Détail par profil

Temps : séances au-delà du temps donné / séances, puis part du temps utilisée. Dosage : erreur en trois familles, en points (— : profil avec « forme générale »). Volume : groupes majeurs sous 4 séries / au-dessus de 20. T/P et CP/G : séries de tirage / de poussée, de chaîne postérieure / à dominante genou.

| Profil | Disciplines sans programme (L10) | Temps L10 | Temps KP | Dosage L10 | Dosage KP | Volume L10 | Volume KP | T/P L10 | T/P KP | CP/G L10 | CP/G KP |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | — | 2/2 · 100 % | 0/2 · 99 % | — | — | 12 / 0 | 10 / 0 | 2 / 2 | 0 / 5 | 2 / 4 | 3 / 2 |
| `femme_45_musculation_salle_4x60` | mobility | 0/4 · 89 % | 0/4 · 99 % | 16.0 | 0.1 | 0 / 2 | 0 / 0 | 14 / 22 | 12 / 12 | 4 / 12 | 11 / 10 |
| `coureur_cardio_3x45` | cardio, mobility | 0/3 · 80 % | 0/3 · 98 % | 70.0 | 4.5 | 2 / 0 | 10 / 0 | 8 / 13 | 2 / 2 | 6 / 6 | 2 / 2 |
| `crossfit_5x60` | crossfit, mobility | 0/5 · 80 % | 0/5 · 94 % | 15.6 | 0.0 | 0 / 1 | 0 / 4 | 18 / 18 | 14 / 14 | 6 / 8 | 3 / 3 |
| `calisthenie_figures_4x75` | calisthenics, mobility | 0/4 · 90 % | 0/4 · 93 % | 16.9 | 0.1 | 0 / 7 | 1 / 5 | 26 / 18 | 29 / 28 | 4 / 14 | 6 / 6 |
| `street_streetlifting_4x90` | calisthenics | 0/4 · 76 % | 0/4 · 92 % | 3.1 | 0.0 | 0 / 7 | 0 / 9 | 20 / 28 | 25.5 / 20.5 | 6 / 12 | 11 / 15 |
| `street_sets_reps_4x60` | calisthenics | 0/4 · 93 % | 0/4 · 96 % | 3.8 | 0.0 | 1 / 4 | 0 / 3 | 17 / 14 | 21 / 19 | 4 / 14 | 7 / 9 |
| `street_calisthenie_5x60` | calisthenics | 0/5 · 81 % | 0/5 · 79 % | 4.4 | 0.0 | 0 / 0 | 1 / 4 | 20 / 12 | 26 / 26 | 4 / 12 | 3 / 3 |
| `blessure_epaule_musculation_3x60` | — | 0/3 · 91 % | 0/3 · 99 % | 3.9 | 0.0 | 0 / 0 | 0 / 1 | 20 / 19 | 6 / 6 | 7 / 9 | 9 / 9 |
| `minimal_1x20` | — | 1/1 · 100 % | 0/1 · 97 % | — | — | 14 / 0 | 14 / 0 | 1 / 1 | 0 / 2 | 1 / 2 | 0 / 1 |
| `six_jours_musculation_avance_6x75` | — | 0/6 · 65 % | 0/6 · 85 % | 4.4 | 0.0 | 0 / 9 | 0 / 8 | 19 / 25 | 20 / 20 | 4 / 13 | 11 / 12 |
| `senior_65_forme_generale_3x40` | mobility | 3/3 · 100 % | 0/3 · 100 % | — | — | 1 / 0 | 9 / 0 | 8 / 10 | 5 / 3 | 6 / 6 | 2 / 3 |
| `proprietaire_streetlifting_avance` | calisthenics | 0/5 · 70 % | 0/5 · 89 % | 3.4 | 0.0 | 0 / 8 | 0 / 10 | 24 / 24 | 23 / 21 | 6 / 12 | 12 / 17 |
| `homme_25_musculation_debutant_3x60` | — | 0/3 · 93 % | 0/3 · 98 % | 3.8 | 0.0 | 1 / 0 | 0 / 0 | 14 / 14 | 16 / 13 | 9 / 12 | 7 / 6 |
| `femme_30_street_workout_parc_3x45` | mobility | 2/3 · 99 % | 0/3 · 83 % | 15.4 | 0.0 | 2 / 0 | 3 / 0 | 17 / 12 | 12 / 9 | 6 / 6 | 2 / 3 |
| `mobilite_seule_5x20` | mobility | 1/5 · 99 % | 0/5 · 95 % | 59.3 | 0.0 | 7 / 0 | 14 / 0 | 2 / 6 | 0 / 0 | 2 / 8 | 0 / 0 |
| `cardio_debutant_marche_3x30` | cardio | 3/3 · 100 % | 0/3 · 100 % | 100.0 | 0.0 | 8 / 0 | 14 / 0 | 4 / 4 | 0 / 0 | 2 / 6 | 0 / 0 |
| `homme_50_reprise_genou_3x45` | cardio | 0/3 · 95 % | 0/3 · 98 % | 30.0 | 0.2 | 1 / 0 | 2 / 0 | 14 / 17 | 9 / 6 | 6 / 6 | 6 / 3 |
| `lombalgie_musculation_3x50` | mobility | 0/3 · 92 % | 0/3 · 98 % | 15.3 | 0.1 | 1 / 0 | 1 / 0 | 18 / 15 | 9 / 6 | 6 / 8 | 6 / 6 |
| `poignet_calisthenie_3x60` | calisthenics | 0/3 · 92 % | 0/3 · 98 % | 3.9 | 0.0 | 0 / 0 | 1 / 4 | 18 / 19 | 16 / 10 | 11 / 13 | 6 / 7 |
| `femme_22_calisthenie_debutante_maison` | calisthenics, mobility | 1/3 · 95 % | 0/3 · 98 % | 25.0 | 0.1 | 2 / 0 | 3 / 0 | 15 / 15 | 12 / 9 | 6 / 6 | 2 / 3 |
| `homme_35_crossfit_maison_kettlebell` | cardio, crossfit | 3/4 · 99 % | 0/4 · 96 % | 30.0 | 0.0 | 1 / 1 | 3 / 0 | 10 / 10 | 10 / 6 | 4 / 8 | 3 / 3 |
| `musculation_maison_halteres_4x45` | — | 0/4 · 95 % | 0/4 · 96 % | 5.0 | 0.0 | 0 / 1 | 1 / 0 | 8 / 12 | 9 / 8 | 4 / 8 | 4 / 6 |
| `elite_calisthenie_6x90` | calisthenics, mobility | 0/6 · 43 % | 0/6 · 62 % | 4.4 | 3.0 | 1 / 0 | 1 / 9 | 16 / 24 | 37 / 24 | 4 / 8 | 3 / 3 |
| `streetlifting_debutant_3x60` | calisthenics | 0/3 · 94 % | 0/3 · 97 % | 3.8 | 0.0 | 1 / 0 | 0 / 0 | 16 / 9 | 18 / 16 | 8 / 12 | 8 / 10 |
| `forme_generale_exterieur_3x40` | cardio | 3/3 · 100 % | 0/3 · 98 % | — | — | 2 / 0 | 9 / 0 | 10 / 10 | 3 / 3 | 6 / 6 | 2 / 3 |
| `senior_72_mobilite_marche_4x30` | cardio, mobility | 3/4 · 100 % | 0/4 · 94 % | 74.4 | 0.1 | 6 / 0 | 14 / 0 | 4 / 6 | 0 / 0 | 4 / 8 | 0 / 0 |
| `femme_60_musculation_salle_2x45` | mobility | 2/2 · 100 % | 0/2 · 99 % | 15.2 | 0.1 | 2 / 0 | 6 / 0 | 8 / 8 | 6 / 6 | 5 / 6 | 3 / 3 |
| `homme_40_cardio_musculation_50_50` | cardio | 0/4 · 93 % | 0/4 · 98 % | 50.0 | 0.0 | 1 / 0 | 1 / 0 | 8 / 23 | 9 / 6 | 4 / 8 | 3 / 3 |
| `trois_disciplines_70_20_10` | cardio, mobility | 1/3 · 85 % | 0/3 · 99 % | 26.1 | 1.6 | 1 / 0 | 0 / 0 | 15 / 14 | 12 / 9 | 9 / 12 | 6 / 6 |
| `niveaux_inconnus_sans_poids` | — | 0/2 · 93 % | 0/2 · 98 % | 3.8 | 0.0 | 1 / 0 | 0 / 0 | 12 / 12 | 9 / 9 | 4 / 8 | 5 / 6 |
| `sans_objectif_mode_libre` | — | 0/3 · 94 % | 0/3 · 97 % | 3.7 | 0.0 | 1 / 0 | 0 / 0 | 18 / 14 | 15 / 13 | 6 / 8 | 9 / 9 |
| `objectif_habitude_seul` | — | 3/3 · 100 % | 0/3 · 99 % | — | — | 8 / 0 | 10 / 0 | 2 / 6 | 3 / 3 | 2 / 6 | 2 / 3 |
| `objectif_figure_front_lever` | calisthenics | 0/4 · 91 % | 0/4 · 81 % | 3.9 | 0.0 | 1 / 0 | 1 / 4 | 18 / 10 | 26 / 20 | 4 / 12 | 3 / 3 |
| `semi_marathon` | cardio, mobility | 0/4 · 79 % | 0/4 · 100 % | 80.0 | 2.1 | 1 / 0 | 8 / 0 | 12 / 21 | 0 / 5 | 4 / 8 | 2 / 2 |
| `prudent_sante_musculation` | cardio | 0/2 · 93 % | 0/2 · 98 % | 40.0 | 1.8 | 2 / 0 | 5 / 0 | 8 / 10 | 6 / 6 | 4 / 7 | 2 / 3 |
| `tres_grand_lourd` | cardio | 0/3 · 92 % | 0/3 · 100 % | 30.0 | 0.8 | 1 / 0 | 0 / 0 | 14 / 17 | 10 / 9 | 10 / 12 | 7 / 6 |
| `petite_legere` | mobility | 2/3 · 99 % | 0/3 · 97 % | 25.4 | 0.0 | 1 / 0 | 3 / 0 | 16 / 10 | 10 / 9 | 6 / 8 | 3 / 4 |
| `sept_jours_courts_7x20` | cardio, mobility | 3/7 · 100 % | 0/7 · 99 % | — | — | 7 / 0 | 9 / 0 | 2 / 14 | 4 / 4 | 1 / 10 | 2 / 2 |
| `materiel_complet_gouts_marques` | cardio | 0/4 · 89 % | 0/4 · 97 % | 20.0 | 0.3 | 1 / 1 | 0 / 0 | 12 / 10 | 15 / 14 | 4 / 10 | 9 / 6 |
