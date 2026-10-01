# Mesures de kalis_plan 0.1.0

Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (catalogue 1.1.0, règles 1.1.0) : 40 profils types et 1000 profils aléatoires seedés (`lib/testing.dart`, graines 500 000 et suivantes). Les temps dépendent de la machine ; tout le reste est déterministe.

## 1. Profils types

Note globale, part du temps disponible utilisée, erreur de dosage (points de pourcentage), groupes musculaires majeurs dans leur bande de volume (séries réglées de la passe 2), schémas de base couverts sur ceux que le matériel et le niveau permettent, nombre d'exercices, contraintes dures violées.

| Profil | Note | Temps | Dosage | Volume | Schémas | Exercices | Violations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | 0.948 | 99 % | 4.2 | 100 % | 3/3 | 11 | 0 |
| `femme_45_musculation_salle_4x60` | 0.972 | 99 % | 0.1 | 96 % | 6/6 | 34 | 0 |
| `coureur_cardio_3x45` | 0.928 | 100 % | 1.4 | 82 % | 4/5 | 19 | 0 |
| `crossfit_5x60` | 0.953 | 98 % | 0.0 | 87 % | 6/6 | 44 | 0 |
| `calisthenie_figures_4x75` | 0.952 | 85 % | 0.1 | 76 % | 6/6 | 37 | 0 |
| `street_streetlifting_4x90` | 0.956 | 91 % | 0.2 | 91 % | 6/6 | 28 | 0 |
| `street_sets_reps_4x60` | 0.943 | 83 % | 0.7 | 73 % | 6/6 | 19 | 0 |
| `street_calisthenie_5x60` | 0.962 | 87 % | 0.5 | 73 % | 6/6 | 28 | 0 |
| `blessure_epaule_musculation_3x60` | 0.958 | 99 % | 0.0 | 69 % | 5/5 | 21 | 0 |
| `minimal_1x20` | 0.913 | 99 % | 35.0 | 100 % | 1/3 | 5 | 0 |
| `six_jours_musculation_avance_6x75` | 0.967 | 89 % | 0.0 | 93 % | 6/6 | 37 | 0 |
| `senior_65_forme_generale_3x40` | 0.935 | 99 % | 3.0 | 87 % | 5/6 | 22 | 0 |
| `proprietaire_streetlifting_avance` | 0.931 | 94 % | 0.0 | 93 % | 6/6 | 39 | 0 |
| `homme_25_musculation_debutant_3x60` | 0.973 | 98 % | 0.0 | 89 % | 6/6 | 18 | 0 |
| `femme_30_street_workout_parc_3x45` | 0.962 | 92 % | 0.2 | 84 % | 6/6 | 25 | 0 |
| `mobilite_seule_5x20` | 0.975 | 92 % | 0.0 | 100 % | 0/0 | 33 | 0 |
| `cardio_debutant_marche_3x30` | 0.976 | 100 % | 0.0 | 100 % | 0/0 | 3 | 0 |
| `homme_50_reprise_genou_3x45` | 0.963 | 97 % | 4.2 | 76 % | 6/6 | 12 | 0 |
| `lombalgie_musculation_3x50` | 0.962 | 99 % | 0.1 | 62 % | 6/6 | 24 | 0 |
| `poignet_calisthenie_3x60` | 0.953 | 97 % | 0.0 | 73 % | 6/6 | 19 | 0 |
| `femme_22_calisthenie_debutante_maison` | 0.943 | 97 % | 0.1 | 93 % | 5/6 | 27 | 0 |
| `homme_35_crossfit_maison_kettlebell` | 0.947 | 96 % | 0.2 | 78 % | 6/6 | 18 | 0 |
| `musculation_maison_halteres_4x45` | 0.959 | 97 % | 0.0 | 87 % | 6/6 | 23 | 0 |
| `elite_calisthenie_6x90` | 0.934 | 59 % | 0.4 | 71 % | 6/6 | 37 | 0 |
| `streetlifting_debutant_3x60` | 0.962 | 99 % | 2.2 | 78 % | 6/6 | 18 | 0 |
| `forme_generale_exterieur_3x40` | 0.948 | 99 % | 4.3 | 100 % | 6/6 | 19 | 0 |
| `senior_72_mobilite_marche_4x30` | 0.974 | 94 % | 0.0 | 100 % | 0/0 | 25 | 0 |
| `femme_60_musculation_salle_2x45` | 0.958 | 98 % | 0.6 | 76 % | 6/6 | 13 | 0 |
| `homme_40_cardio_musculation_50_50` | 0.967 | 98 % | 0.5 | 67 % | 6/6 | 17 | 0 |
| `trois_disciplines_70_20_10` | 0.968 | 98 % | 1.3 | 76 % | 6/6 | 27 | 0 |
| `niveaux_inconnus_sans_poids` | 0.966 | 98 % | 0.0 | 91 % | 6/6 | 15 | 0 |
| `sans_objectif_mode_libre` | 0.969 | 77 % | 0.4 | 84 % | 6/6 | 16 | 0 |
| `objectif_habitude_seul` | 0.937 | 98 % | 4.5 | 78 % | 6/6 | 13 | 0 |
| `objectif_figure_front_lever` | 0.951 | 82 % | 0.3 | 69 % | 6/6 | 20 | 0 |
| `semi_marathon` | 0.949 | 98 % | 1.6 | 100 % | 4/4 | 19 | 0 |
| `prudent_sante_musculation` | 0.950 | 99 % | 2.2 | 76 % | 6/6 | 10 | 0 |
| `tres_grand_lourd` | 0.969 | 99 % | 0.0 | 51 % | 6/6 | 19 | 0 |
| `petite_legere` | 0.958 | 94 % | 0.1 | 71 % | 6/6 | 23 | 0 |
| `sept_jours_courts_7x20` | 0.936 | 96 % | 7.0 | 82 % | 5/6 | 31 | 0 |
| `materiel_complet_gouts_marques` | 0.969 | 96 % | 0.3 | 100 % | 6/6 | 26 | 0 |

## 2. Temps de calcul

Par profil type : médiane de trois exécutions, moteur neuf à chaque fois, après un premier passage de mise en route. Temps en millisecondes sur la machine du contrôle (un cœur).

| Opération | Médiane | 95e centile | Maximum |
| --- | --- | --- | --- |
| Passe 1 (création) | 22.2 | 59.5 | 77.2 |
| Passe 2 | 1.1 | 3.0 | 3.3 |
| Génération complète (passes 1 + 2) | 23.5 | 62.5 | 79.0 |
| Régénération après une action de revue | 7.5 | 12.2 | 13.6 |
| Variantes d'un exercice | 1.0 | 1.7 | 1.9 |
| Autre proposition | 12.6 | 31.4 | 81.3 |
| Bloc suivant | 7.8 | 16.2 | 19.5 |
| Restructuration de la fin du bloc | 7.3 | 17.0 | 18.0 |

## 3. Population de 1000 profils aléatoires

Programmes avec une contrainte dure violée : **0** ; programmes invalides au sens du contrat : **0** ; programmes avec au moins une séance de repli : 2.

| Mesure | Moyenne | 5e centile | Médiane | 95e centile | Minimum | Maximum |
| --- | --- | --- | --- | --- | --- | --- |
| Note globale | 0.921 | 0.853 | 0.927 | 0.966 | 0.744 | 0.977 |
| Temps utilisé (%) | 88.6 | 54.5 | 95.1 | 99.7 | 21.6 | 100.0 |
| Groupes dans leur bande (%) | 77.8 | 46.7 | 80.0 | 100.0 | 22.2 | 100.0 |
| Erreur de dosage (points) | 8.7 | 0.0 | 1.6 | 35.8 | 0.0 | 100.0 |
| Schémas de base couverts (%) | 91.8 | 40.0 | 100.0 | 100.0 | 0.0 | 100.0 |
| Passe 1 (ms) | 25.058 | 3.700 | 18.800 | 62.000 | 0.900 | 159.700 |
| Régénération en revue (ms) | 7.276 | 2.100 | 6.700 | 14.800 | 0.500 | 25.500 |

Diff minimal — changements d'exercice hors de l'emplacement visé, par action de revue :

| Action | Moyenne | Sans aucun autre changement | Maximum |
| --- | --- | --- | --- |
| `cannot_do` | 0.64 | 70 % | 12 |
| `dislike` | 0.60 | 78 % | 12 |
| `remove` | 0.55 | 54 % | 7 |

## 4. « Autre proposition »

Graines 1 à 7 de chaque profil type (280 propositions). Note rapportée à celle de la meilleure : minimum 0.9859, médiane 0.9995 (plancher du contrat : 0.97). Part d'exercices absents de chacune des propositions déjà montrées : médiane 42 %, minimum 0 % ; **89 %** des propositions atteignent le tiers visé. Programmes distincts parmi les huit premiers : 8.0 en moyenne, 8 au minimum.

## 5. Convergence de la recherche

Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils types selon l'effort de recuit ; dernière colonne : profils dont l'objectif dépasse celui de l'effort × 1.

| Effort | Coups de recuit | Objectif moyen | Temps moyen (ms) | Profils améliorés |
| --- | --- | --- | --- | --- |
| × 0.0 | 0 | 1.95086 | 17.1 | — |
| × 0.25 | 375 | 1.95233 | 18.5 | — |
| × 0.5 | 750 | 1.95315 | 21.8 | — |
| × 1.0 | 1500 | 1.95349 | 24.9 | — |
| × 2.0 | 3000 | 1.95529 | 28.1 | 25 |
| × 4.0 | 6000 | 1.95529 | 35.9 | 26 |

## 6. Sensibilité aux poids de la note

Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : recouvrement moyen (Jaccard) des exercices avec le programme de référence sur les 40 profils types, et nombre de programmes identiques.

| Poids | Jaccard × 0,8 | Identiques | Jaccard × 1,2 | Identiques |
| --- | --- | --- | --- | --- |
| `recovery` | 0.60 | 15 | 0.66 | 18 |
| `fatigue_balance` | 0.57 | 12 | 0.58 | 13 |
| `joint_load` | 0.70 | 22 | 0.74 | 23 |
| `goal_specificity` | 0.50 | 9 | 0.49 | 9 |
| `discipline_dosage` | 0.45 | 5 | 0.46 | 6 |
| `muscle_volume` | 0.44 | 4 | 0.45 | 5 |
| `pattern_balance` | 0.51 | 9 | 0.50 | 8 |
| `discipline_structure` | 0.49 | 6 | 0.48 | 7 |
| `time_use` | 0.47 | 4 | 0.46 | 5 |
| `variety` | 0.50 | 9 | 0.51 | 8 |
| `exercise_fit` | 0.47 | 4 | 0.47 | 6 |
| `stimulus_fatigue` | 0.54 | 9 | 0.52 | 7 |
| `preferences` | 0.57 | 12 | 0.49 | 8 |
| `novelty` | 0.74 | 23 | 0.72 | 23 |

## 7. Séries créditées par minute de renforcement

Séries fractionnaires créditées aux groupes majeurs par minute de renforcement, sur les profils types qui en comportent (37) : moyenne 0.91, médiane 0.92, de 0.60 à 1.11. Paramètre `creditsPerMinute` : 0.9.

## 8. Non-ressemblance au programme du propriétaire

Programme du propriétaire : 40 semaines, 45 exercices du catalogue, dont 36 accessoires. Ressemblance = indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du propriétaire la plus proche. Le programme du propriétaire comparé à lui-même, entre semaines de blocs différents : minimum 0.21, premier décile 0.30, médiane 0.60. Seuil : 0.3.

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profils types — propriétaire (graines 0 à 3) | 4 | 0.173 | 0.173 |
| Profils types — street (graines 0 à 3) | 52 | 0.074 | 0.167 |
| Profils types — sans street (graines 0 à 3) | 104 | 0.071 | 0.210 |
| Population aléatoire | 1000 | 0.040 | 0.222 |

Séance par séance (profils types, graines 0 à 3) : ressemblance maximale avec une séance du propriétaire, médiane 0.09, maximum 0.40.

Accessoires du propriétaire chez les 328 profils aléatoires sans discipline street : part des profils (où l'exercice est admissible) dont le programme le contient, face à l'exercice hors programme du propriétaire le plus choisi de la même catégorie. Sur-représenté = plus de 5 % et plus du double de ce pair : **1** (`mu-mollets-debout-machine`).

| Accessoire du propriétaire | Catégorie | Admissible | Choisi | Meilleur pair | Choisi |
| --- | --- | --- | --- | --- | --- |
| `mo-routine-mobilite-epaules-poignets` | Mobilité articulaire | 144 | 38.9 % | `mo-wall-slides` | 49.5 % |
| `mu-rowing-poulie-assis-triangle` | Tirage horizontal | 148 | 32.4 % | `sw-row-australien` | 55.1 % |
| `mu-mollets-debout-machine` | Mollets et cheville | 138 | 27.5 % | `mu-mollets-unilateral-haltere` | 12.9 % |
| `mu-face-pull-corde` | Tirage horizontal | 140 | 25.7 % | `sw-row-australien` | 55.1 % |
| `mu-elevation-laterale-halteres` | Isolation épaules | 151 | 18.5 % | `mu-lu-raise` | 24.5 % |
| `mu-fente-marchee-halteres` | Fente / unilatéral jambes | 104 | 16.3 % | `cf-fente-overhead-disque` | 28.9 % |
| `mu-leg-curl-couche` | Flexion de genou (ischio-jambiers) | 141 | 16.3 % | `mu-nordic-hamstring-curl` | 29.9 % |
| `mu-developpe-militaire-barre-debout` | Poussée verticale | 87 | 14.9 % | `sw-pompe-pike` | 25.8 % |
| `ca-marche-recuperation` | Marche et portage | 242 | 14.5 % | `ca-marche-tapis-incline` | 18.7 % |
| `mu-developpe-couche-barre` | Poussée horizontale | 122 | 12.3 % | `mu-developpe-couche-halteres` | 36.8 % |
| `mu-pallof-press-debout` | Gainage anti-rotation | 141 | 7.8 % | `mu-bird-dog` | 14.2 % |
| `mu-rowing-barre-pronation` | Tirage horizontal | 105 | 7.6 % | `sw-row-australien` | 55.1 % |
| `mu-y-raise-banc-incline` | Préparation scapulaire | 135 | 7.4 % | `mu-halo-kettlebell` | 13.4 % |
| `mu-rowing-haltere-unilateral-banc` | Tirage horizontal | 141 | 6.4 % | `sw-row-australien` | 55.1 % |
| `mu-hollow-body-hold` | Gainage anti-extension | 156 | 5.1 % | `mu-planche-rkc` | 31.6 % |
| `sw-traction-scapulaire` | Préparation scapulaire | 205 | 4.4 % | `mu-halo-kettlebell` | 13.4 % |
| `mu-hip-thrust-barre` | Extension de hanche | 98 | 4.1 % | `mu-reverse-hyper-machine` | 23.5 % |
| `mu-souleve-de-terre-roumain-barre` | Charnière de hanche | 104 | 3.8 % | `mu-souleve-de-terre-conventionnel` | 37.1 % |
| `mu-pushdown-corde` | Isolation triceps | 147 | 3.4 % | `mu-extension-croisee-couche-haltere` | 7.1 % |
| `mu-tirage-vertical-prise-neutre` | Tirage vertical | 147 | 3.4 % | `mu-tirage-vertical-prise-large-pronation` | 44.6 % |

