# Mesures de kalis_plan 0.1.0

Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (catalogue 1.1.0, règles 1.1.0) : 40 profils types et 1000 profils aléatoires seedés (`lib/testing.dart`, graines 500 000 et suivantes). Les temps dépendent de la machine ; tout le reste est déterministe.

## 1. Profils types

Note globale, part du temps disponible utilisée, erreur de dosage (points de pourcentage), groupes musculaires majeurs dans leur bande de volume (séries réglées de la passe 2), schémas de base couverts sur ceux que le matériel et le niveau permettent, nombre d'exercices, contraintes dures violées.

| Profil | Note | Temps | Dosage | Volume | Schémas | Exercices | Violations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | 0.947 | 98 % | 16.0 | 100 % | 3/3 | 11 | 0 |
| `femme_45_musculation_salle_4x60` | 0.971 | 97 % | 0.0 | 96 % | 6/6 | 37 | 0 |
| `coureur_cardio_3x45` | 0.928 | 97 % | 7.4 | 80 % | 4/5 | 13 | 0 |
| `crossfit_5x60` | 0.958 | 96 % | 0.0 | 93 % | 6/6 | 46 | 0 |
| `calisthenie_figures_4x75` | 0.952 | 92 % | 0.2 | 84 % | 6/6 | 39 | 0 |
| `street_streetlifting_4x90` | 0.951 | 95 % | 5.3 | 78 % | 6/6 | 29 | 0 |
| `street_sets_reps_4x60` | 0.953 | 99 % | 1.6 | 73 % | 6/6 | 23 | 0 |
| `street_calisthenie_5x60` | 0.958 | 83 % | 1.8 | 76 % | 6/6 | 26 | 0 |
| `blessure_epaule_musculation_3x60` | 0.967 | 99 % | 0.0 | 87 % | 5/5 | 21 | 0 |
| `minimal_1x20` | 0.917 | 98 % | 35.0 | 100 % | 2/3 | 6 | 0 |
| `six_jours_musculation_avance_6x75` | 0.967 | 82 % | 0.0 | 93 % | 6/6 | 36 | 0 |
| `senior_65_forme_generale_3x40` | 0.934 | 99 % | 4.3 | 93 % | 4/6 | 23 | 0 |
| `proprietaire_streetlifting_avance` | 0.949 | 93 % | 0.3 | 84 % | 6/6 | 36 | 0 |
| `homme_25_musculation_debutant_3x60` | 0.973 | 98 % | 0.0 | 73 % | 6/6 | 18 | 0 |
| `femme_30_street_workout_parc_3x45` | 0.960 | 95 % | 0.1 | 93 % | 6/6 | 24 | 0 |
| `mobilite_seule_5x20` | 0.976 | 93 % | 0.0 | 100 % | 0/0 | 36 | 0 |
| `cardio_debutant_marche_3x30` | 0.976 | 100 % | 0.0 | 100 % | 0/0 | 3 | 0 |
| `homme_50_reprise_genou_3x45` | 0.960 | 98 % | 4.4 | 80 % | 6/6 | 12 | 0 |
| `lombalgie_musculation_3x50` | 0.961 | 100 % | 1.2 | 73 % | 6/6 | 26 | 0 |
| `poignet_calisthenie_3x60` | 0.953 | 98 % | 0.0 | 89 % | 6/6 | 18 | 0 |
| `femme_22_calisthenie_debutante_maison` | 0.942 | 99 % | 0.2 | 80 % | 6/6 | 28 | 0 |
| `homme_35_crossfit_maison_kettlebell` | 0.948 | 95 % | 0.7 | 73 % | 6/6 | 17 | 0 |
| `musculation_maison_halteres_4x45` | 0.959 | 94 % | 0.0 | 91 % | 5/6 | 21 | 0 |
| `elite_calisthenie_6x90` | 0.942 | 57 % | 6.4 | 80 % | 6/6 | 42 | 0 |
| `streetlifting_debutant_3x60` | 0.964 | 99 % | 0.6 | 89 % | 6/6 | 20 | 0 |
| `forme_generale_exterieur_3x40` | 0.948 | 97 % | 0.1 | 93 % | 4/6 | 15 | 0 |
| `senior_72_mobilite_marche_4x30` | 0.974 | 94 % | 0.0 | 100 % | 0/0 | 26 | 0 |
| `femme_60_musculation_salle_2x45` | 0.951 | 99 % | 0.3 | 62 % | 5/6 | 13 | 0 |
| `homme_40_cardio_musculation_50_50` | 0.971 | 99 % | 0.0 | 89 % | 6/6 | 17 | 0 |
| `trois_disciplines_70_20_10` | 0.970 | 99 % | 1.2 | 96 % | 6/6 | 28 | 0 |
| `niveaux_inconnus_sans_poids` | 0.973 | 97 % | 0.0 | 100 % | 6/6 | 14 | 0 |
| `sans_objectif_mode_libre` | 0.972 | 95 % | 0.2 | 91 % | 6/6 | 20 | 0 |
| `objectif_habitude_seul` | 0.936 | 96 % | 2.5 | 93 % | 4/6 | 14 | 0 |
| `objectif_figure_front_lever` | 0.958 | 92 % | 0.1 | 56 % | 6/6 | 23 | 0 |
| `semi_marathon` | 0.951 | 99 % | 5.4 | 100 % | 4/4 | 19 | 0 |
| `prudent_sante_musculation` | 0.943 | 96 % | 7.4 | 96 % | 5/6 | 9 | 0 |
| `tres_grand_lourd` | 0.967 | 99 % | 2.4 | 76 % | 6/6 | 17 | 0 |
| `petite_legere` | 0.958 | 81 % | 0.1 | 71 % | 6/6 | 21 | 0 |
| `sept_jours_courts_7x20` | 0.943 | 98 % | 12.4 | 93 % | 5/6 | 33 | 0 |
| `materiel_complet_gouts_marques` | 0.969 | 98 % | 0.1 | 73 % | 6/6 | 27 | 0 |

## 2. Temps de calcul

Par profil type : médiane de trois exécutions, moteur neuf à chaque fois, après un premier passage de mise en route. Temps en millisecondes sur la machine du contrôle (un cœur).

| Opération | Médiane | 95e centile | Maximum |
| --- | --- | --- | --- |
| Passe 1 (création) | 27.3 | 52.5 | 63.8 |
| Passe 2 | 1.2 | 3.4 | 3.9 |
| Génération complète (passes 1 + 2) | 28.5 | 54.9 | 65.5 |
| Régénération après une action de revue | 7.5 | 12.2 | 15.8 |
| Variantes d'un exercice | 1.1 | 1.8 | 3.4 |
| Autre proposition | 14.9 | 27.8 | 36.1 |
| Bloc suivant | 8.3 | 14.6 | 19.6 |
| Restructuration de la fin du bloc | 7.8 | 15.3 | 18.6 |

## 3. Population de 1000 profils aléatoires

Programmes avec une contrainte dure violée : **0** ; programmes invalides au sens du contrat : **0** ; programmes avec au moins une séance de repli : 2.

| Mesure | Moyenne | 5e centile | Médiane | 95e centile | Minimum | Maximum |
| --- | --- | --- | --- | --- | --- | --- |
| Note globale | 0.922 | 0.849 | 0.929 | 0.967 | 0.733 | 0.977 |
| Temps utilisé (%) | 89.0 | 54.6 | 95.3 | 99.7 | 22.9 | 100.0 |
| Groupes dans leur bande (%) | 80.6 | 51.1 | 82.2 | 100.0 | 4.4 | 100.0 |
| Erreur de dosage (points) | 9.3 | 0.0 | 1.7 | 39.9 | 0.0 | 100.0 |
| Schémas de base couverts (%) | 91.9 | 50.0 | 100.0 | 100.0 | 0.0 | 100.0 |
| Passe 1 (ms) | 26.818 | 5.300 | 22.200 | 62.300 | 1.300 | 181.600 |
| Régénération en revue (ms) | 6.861 | 1.900 | 6.300 | 13.400 | 0.500 | 27.100 |

Diff minimal — changements d'exercice hors de l'emplacement visé, par action de revue :

| Action | Moyenne | Sans aucun autre changement | Maximum |
| --- | --- | --- | --- |
| `cannot_do` | 0.63 | 74 % | 12 |
| `dislike` | 0.59 | 79 % | 12 |
| `remove` | 0.57 | 55 % | 9 |

## 4. « Autre proposition »

Graines 1 à 7 de chaque profil type (280 propositions). Note rapportée à celle de la meilleure : minimum 0.9875, médiane 0.9993 (plancher du contrat : 0.97). Part d'exercices absents de chacune des propositions déjà montrées : médiane 42 %, minimum 0 % ; **90 %** des propositions atteignent le tiers visé. Programmes distincts parmi les huit premiers : 8.0 en moyenne, 8 au minimum.

## 5. Convergence de la recherche

Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils types selon l'effort de recuit ; dernières colonnes : profils dont l'objectif est au-dessus, puis au-dessous, de celui de l'effort × 1.

| Effort | Coups de recuit | Objectif moyen | Temps moyen (ms) | Profils améliorés | Profils dégradés |
| --- | --- | --- | --- | --- | --- |
| × 0.0 | 0 | 1.95196 | 15.0 | — | — |
| × 0.25 | 750 | 1.95300 | 19.7 | — | — |
| × 0.5 | 1500 | 1.95441 | 22.0 | — | — |
| × 1.0 | 3000 | 1.95499 | 26.8 | — | — |
| × 2.0 | 6000 | 1.95640 | 33.4 | 23 | 12 |
| × 4.0 | 12000 | 1.95717 | 45.7 | 29 | 9 |

## 6. Sensibilité aux poids de la note

Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : recouvrement moyen (Jaccard) des exercices avec le programme de référence sur les 40 profils types, nombre de programmes identiques, et regret moyen (objectif de référence perdu par le programme obtenu, sur une échelle de 0 à 2).

| Poids | Jaccard × 0,8 | Identiques | Regret | Jaccard × 1,2 | Identiques | Regret |
| --- | --- | --- | --- | --- | --- | --- |
| `recovery` | 0.52 | 10 | -0.0002 | 0.56 | 12 | 0.0001 |
| `fatigue_balance` | 0.50 | 9 | -0.0002 | 0.51 | 10 | 0.0003 |
| `joint_load` | 0.66 | 18 | -0.0003 | 0.65 | 18 | -0.0002 |
| `goal_specificity` | 0.40 | 3 | 0.0002 | 0.43 | 6 | -0.0000 |
| `discipline_dosage` | 0.43 | 2 | -0.0003 | 0.45 | 3 | 0.0002 |
| `muscle_volume` | 0.41 | 2 | -0.0000 | 0.42 | 3 | 0.0005 |
| `pattern_balance` | 0.39 | 2 | 0.0001 | 0.42 | 3 | -0.0004 |
| `discipline_structure` | 0.43 | 4 | -0.0004 | 0.40 | 1 | 0.0001 |
| `time_use` | 0.42 | 3 | -0.0009 | 0.45 | 3 | 0.0000 |
| `variety` | 0.45 | 5 | -0.0006 | 0.47 | 5 | -0.0002 |
| `exercise_fit` | 0.39 | 2 | -0.0004 | 0.42 | 2 | -0.0002 |
| `stimulus_fatigue` | 0.44 | 3 | -0.0001 | 0.42 | 3 | -0.0001 |
| `preferences` | 0.45 | 7 | 0.0000 | 0.44 | 5 | -0.0003 |
| `novelty` | 0.54 | 13 | 0.0001 | 0.60 | 14 | -0.0006 |

## 7. Séries créditées par minute de renforcement

Séries fractionnaires créditées aux groupes majeurs par minute de renforcement, sur les profils types qui en comportent (37) : moyenne 0.94, médiane 0.96, de 0.65 à 1.21. Paramètre `creditsPerMinute` : 0.9.

## 8. Non-ressemblance au programme du propriétaire

Programme du propriétaire : 40 semaines, 45 exercices du catalogue, dont 36 accessoires. Ressemblance = indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du propriétaire la plus proche. Le programme du propriétaire comparé à lui-même, entre semaines de blocs différents : minimum 0.21, premier décile 0.30, médiane 0.60. Seuil : 0.3.

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profils types — propriétaire (graines 0 à 3) | 4 | 0.190 | 0.211 |
| Profils types — street (graines 0 à 3) | 52 | 0.063 | 0.173 |
| Profils types — sans street (graines 0 à 3) | 104 | 0.063 | 0.211 |
| Population aléatoire | 1000 | 0.040 | 0.160 |

Séance par séance (profils types, graines 0 à 3) : ressemblance maximale avec une séance du propriétaire, médiane 0.08, maximum 0.33.

Accessoires du propriétaire chez les 328 profils aléatoires sans discipline street : part des profils (où l'exercice est admissible) dont le programme le contient, face à l'exercice hors programme du propriétaire le plus choisi de la même catégorie. Sur-représenté = plus de 5 % et plus du double de ce pair. Accessoires propres au propriétaire (exercices des disciplines street de la base) sur-représentés : **0** ; accessoires du fonds commun de la musculation au-dessus de la même règle : 1 (`mu-mollets-debout-machine`).

| Accessoire du propriétaire | Propre | Catégorie | Admissible | Choisi | Meilleur pair | Choisi |
| --- | --- | --- | --- | --- | --- | --- |
| `sw-traction-scapulaire` | oui | Préparation scapulaire | 205 | 3.9 % | `mu-halo-kettlebell` | 10.2 % |
| `mo-routine-mobilite-epaules-poignets` | non | Mobilité articulaire | 144 | 47.2 % | `mo-wall-slides` | 55.9 % |
| `mu-rowing-poulie-assis-triangle` | non | Tirage horizontal | 148 | 35.1 % | `sw-row-australien` | 62.3 % |
| `mu-mollets-debout-machine` | non | Mollets et cheville | 138 | 23.9 % | `mu-mollets-unilateral-haltere` | 10.5 % |
| `mu-leg-curl-couche` | non | Flexion de genou (ischio-jambiers) | 141 | 23.4 % | `mu-nordic-hamstring-curl` | 19.4 % |
| `mu-elevation-laterale-halteres` | non | Isolation épaules | 151 | 21.9 % | `mu-oiseau-halteres` | 17.9 % |
| `mu-fente-marchee-halteres` | non | Fente / unilatéral jambes | 104 | 21.2 % | `cf-fente-overhead-disque` | 21.1 % |
| `mu-face-pull-corde` | non | Tirage horizontal | 140 | 18.6 % | `sw-row-australien` | 62.3 % |
| `ca-marche-recuperation` | non | Marche et portage | 242 | 16.9 % | `ca-marche-rapide` | 20.7 % |
| `mu-developpe-couche-barre` | non | Poussée horizontale | 122 | 14.8 % | `mu-developpe-couche-halteres` | 31.6 % |
| `mu-developpe-militaire-barre-debout` | non | Poussée verticale | 87 | 12.6 % | `sw-dips-assistes-pieds` | 20.0 % |
| `mu-pallof-press-debout` | non | Gainage anti-rotation | 141 | 12.1 % | `mu-bird-dog` | 14.2 % |
| `mu-y-raise-banc-incline` | non | Préparation scapulaire | 135 | 8.9 % | `mu-halo-kettlebell` | 10.2 % |
| `mu-rowing-haltere-unilateral-banc` | non | Tirage horizontal | 141 | 7.1 % | `sw-row-australien` | 62.3 % |
| `mu-rowing-barre-pronation` | non | Tirage horizontal | 105 | 6.7 % | `sw-row-australien` | 62.3 % |

