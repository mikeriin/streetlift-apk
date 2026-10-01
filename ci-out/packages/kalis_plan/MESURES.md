# Mesures de kalis_plan 0.1.0

Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (catalogue 1.1.0, règles 1.1.0) : 40 profils types et 1000 profils aléatoires seedés (`lib/testing.dart`, graines 500 000 et suivantes). Les temps dépendent de la machine ; tout le reste est déterministe.

## 1. Profils types

Note globale, part du temps disponible utilisée, erreur de dosage (points de pourcentage), groupes musculaires majeurs dans leur bande de volume (séries réglées de la passe 2), schémas de base couverts sur ceux que le matériel et le niveau permettent, nombre d'exercices, contraintes dures violées.

| Profil | Note | Temps | Dosage | Volume | Schémas | Exercices | Violations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | 0.947 | 98 % | 16.0 | 100 % | 3/3 | 11 | 0 |
| `femme_45_musculation_salle_4x60` | 0.971 | 97 % | 0.0 | 96 % | 6/6 | 39 | 0 |
| `coureur_cardio_3x45` | 0.933 | 98 % | 4.0 | 78 % | 4/5 | 14 | 0 |
| `crossfit_5x60` | 0.956 | 99 % | 0.0 | 91 % | 6/6 | 48 | 0 |
| `calisthenie_figures_4x75` | 0.952 | 92 % | 0.2 | 84 % | 6/6 | 39 | 0 |
| `street_streetlifting_4x90` | 0.951 | 95 % | 5.3 | 78 % | 6/6 | 29 | 0 |
| `street_sets_reps_4x60` | 0.953 | 99 % | 1.6 | 73 % | 6/6 | 23 | 0 |
| `street_calisthenie_5x60` | 0.958 | 83 % | 1.8 | 76 % | 6/6 | 26 | 0 |
| `blessure_epaule_musculation_3x60` | 0.963 | 98 % | 0.0 | 84 % | 5/5 | 21 | 0 |
| `minimal_1x20` | 0.917 | 98 % | 35.0 | 100 % | 2/3 | 6 | 0 |
| `six_jours_musculation_avance_6x75` | 0.967 | 84 % | 0.0 | 93 % | 6/6 | 36 | 0 |
| `senior_65_forme_generale_3x40` | 0.933 | 99 % | 1.8 | 93 % | 4/6 | 24 | 0 |
| `proprietaire_streetlifting_avance` | 0.949 | 93 % | 0.3 | 84 % | 6/6 | 36 | 0 |
| `homme_25_musculation_debutant_3x60` | 0.973 | 99 % | 0.0 | 89 % | 6/6 | 19 | 0 |
| `femme_30_street_workout_parc_3x45` | 0.960 | 95 % | 0.1 | 93 % | 6/6 | 24 | 0 |
| `mobilite_seule_5x20` | 0.976 | 93 % | 0.0 | 100 % | 0/0 | 36 | 0 |
| `cardio_debutant_marche_3x30` | 0.976 | 100 % | 0.0 | 100 % | 0/0 | 3 | 0 |
| `homme_50_reprise_genou_3x45` | 0.961 | 99 % | 4.7 | 76 % | 6/6 | 12 | 0 |
| `lombalgie_musculation_3x50` | 0.966 | 99 % | 0.0 | 60 % | 6/6 | 23 | 0 |
| `poignet_calisthenie_3x60` | 0.953 | 98 % | 0.0 | 89 % | 6/6 | 18 | 0 |
| `femme_22_calisthenie_debutante_maison` | 0.942 | 99 % | 0.2 | 80 % | 6/6 | 28 | 0 |
| `homme_35_crossfit_maison_kettlebell` | 0.945 | 94 % | 0.5 | 78 % | 6/6 | 16 | 0 |
| `musculation_maison_halteres_4x45` | 0.959 | 87 % | 0.0 | 96 % | 6/6 | 20 | 0 |
| `elite_calisthenie_6x90` | 0.942 | 57 % | 6.4 | 80 % | 6/6 | 42 | 0 |
| `streetlifting_debutant_3x60` | 0.964 | 99 % | 0.6 | 89 % | 6/6 | 20 | 0 |
| `forme_generale_exterieur_3x40` | 0.951 | 99 % | 6.5 | 84 % | 5/6 | 17 | 0 |
| `senior_72_mobilite_marche_4x30` | 0.974 | 94 % | 0.0 | 100 % | 0/0 | 26 | 0 |
| `femme_60_musculation_salle_2x45` | 0.954 | 100 % | 1.1 | 71 % | 6/6 | 14 | 0 |
| `homme_40_cardio_musculation_50_50` | 0.973 | 98 % | 1.3 | 82 % | 6/6 | 15 | 0 |
| `trois_disciplines_70_20_10` | 0.969 | 99 % | 1.9 | 96 % | 6/6 | 28 | 0 |
| `niveaux_inconnus_sans_poids` | 0.970 | 97 % | 0.0 | 91 % | 6/6 | 14 | 0 |
| `sans_objectif_mode_libre` | 0.972 | 95 % | 0.2 | 91 % | 6/6 | 20 | 0 |
| `objectif_habitude_seul` | 0.939 | 99 % | 3.9 | 93 % | 5/6 | 12 | 0 |
| `objectif_figure_front_lever` | 0.958 | 92 % | 0.1 | 56 % | 6/6 | 23 | 0 |
| `semi_marathon` | 0.951 | 99 % | 5.4 | 100 % | 4/4 | 19 | 0 |
| `prudent_sante_musculation` | 0.948 | 97 % | 7.6 | 82 % | 6/6 | 11 | 0 |
| `tres_grand_lourd` | 0.970 | 96 % | 1.5 | 89 % | 6/6 | 14 | 0 |
| `petite_legere` | 0.958 | 81 % | 0.1 | 71 % | 6/6 | 21 | 0 |
| `sept_jours_courts_7x20` | 0.944 | 99 % | 7.7 | 89 % | 5/6 | 30 | 0 |
| `materiel_complet_gouts_marques` | 0.969 | 98 % | 0.1 | 73 % | 6/6 | 27 | 0 |

## 2. Temps de calcul

Par profil type : médiane de trois exécutions, moteur neuf à chaque fois, après un premier passage de mise en route. Temps en millisecondes sur la machine du contrôle (un cœur).

| Opération | Médiane | 95e centile | Maximum |
| --- | --- | --- | --- |
| Passe 1 (création) | 27.7 | 53.2 | 71.2 |
| Passe 2 | 1.1 | 4.0 | 4.4 |
| Génération complète (passes 1 + 2) | 29.0 | 57.3 | 74.2 |
| Régénération après une action de revue | 6.9 | 13.1 | 20.4 |
| Variantes d'un exercice | 1.0 | 1.8 | 1.9 |
| Autre proposition | 16.2 | 30.7 | 33.5 |
| Bloc suivant | 7.7 | 15.4 | 25.5 |
| Restructuration de la fin du bloc | 7.6 | 15.4 | 20.7 |

## 3. Population de 1000 profils aléatoires

Programmes avec une contrainte dure violée : **0** ; programmes invalides au sens du contrat : **0** ; programmes avec au moins une séance de repli : 2.

| Mesure | Moyenne | 5e centile | Médiane | 95e centile | Minimum | Maximum |
| --- | --- | --- | --- | --- | --- | --- |
| Note globale | 0.922 | 0.847 | 0.930 | 0.967 | 0.733 | 0.977 |
| Temps utilisé (%) | 89.0 | 54.6 | 95.3 | 99.7 | 22.9 | 100.0 |
| Groupes dans leur bande (%) | 80.5 | 51.1 | 82.2 | 100.0 | 0.0 | 100.0 |
| Erreur de dosage (points) | 9.3 | 0.0 | 1.6 | 39.0 | 0.0 | 100.0 |
| Schémas de base couverts (%) | 91.8 | 50.0 | 100.0 | 100.0 | 0.0 | 100.0 |
| Passe 1 (ms) | 28.940 | 5.100 | 23.400 | 69.700 | 1.200 | 210.900 |
| Régénération en revue (ms) | 7.315 | 1.900 | 6.600 | 14.700 | 0.500 | 75.700 |

Diff minimal — changements d'exercice hors de l'emplacement visé, par action de revue :

| Action | Moyenne | Sans aucun autre changement | Maximum |
| --- | --- | --- | --- |
| `cannot_do` | 0.68 | 72 % | 12 |
| `dislike` | 0.59 | 78 % | 12 |
| `remove` | 0.58 | 56 % | 9 |

## 4. « Autre proposition »

Graines 1 à 7 de chaque profil type (280 propositions). Note rapportée à celle de la meilleure : minimum 0.9875, médiane 0.9993 (plancher du contrat : 0.97). Part d'exercices absents de chacune des propositions déjà montrées : médiane 43 %, minimum 0 % ; **91 %** des propositions atteignent le tiers visé. Programmes distincts parmi les huit premiers : 8.0 en moyenne, 8 au minimum.

## 5. Convergence de la recherche

Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils types selon l'effort de recuit ; dernières colonnes : profils dont l'objectif est au-dessus, puis au-dessous, de celui de l'effort × 1.

| Effort | Coups de recuit | Objectif moyen | Temps moyen (ms) | Profils améliorés | Profils dégradés |
| --- | --- | --- | --- | --- | --- |
| × 0.0 | 0 | 1.95197 | 16.4 | — | — |
| × 0.25 | 750 | 1.95331 | 21.9 | — | — |
| × 0.5 | 1500 | 1.95461 | 23.9 | — | — |
| × 1.0 | 3000 | 1.95537 | 29.0 | — | — |
| × 2.0 | 6000 | 1.95636 | 36.7 | 19 | 16 |
| × 4.0 | 12000 | 1.95690 | 50.0 | 24 | 14 |

## 6. Sensibilité aux poids de la note

Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : recouvrement moyen (Jaccard) des exercices avec le programme de référence sur les 40 profils types, nombre de programmes identiques, et regret moyen (objectif de référence perdu par le programme obtenu, sur une échelle de 0 à 2).

| Poids | Jaccard × 0,8 | Identiques | Regret | Jaccard × 1,2 | Identiques | Regret |
| --- | --- | --- | --- | --- | --- | --- |
| `recovery` | 0.55 | 11 | 0.0000 | 0.54 | 10 | 0.0004 |
| `fatigue_balance` | 0.51 | 10 | 0.0008 | 0.56 | 11 | 0.0002 |
| `joint_load` | 0.62 | 16 | -0.0001 | 0.63 | 17 | 0.0003 |
| `goal_specificity` | 0.44 | 4 | 0.0008 | 0.43 | 6 | -0.0003 |
| `discipline_dosage` | 0.43 | 2 | 0.0000 | 0.43 | 2 | -0.0001 |
| `muscle_volume` | 0.40 | 2 | 0.0007 | 0.39 | 2 | 0.0005 |
| `pattern_balance` | 0.40 | 2 | 0.0004 | 0.43 | 4 | 0.0001 |
| `discipline_structure` | 0.43 | 3 | -0.0002 | 0.39 | 1 | 0.0004 |
| `time_use` | 0.40 | 2 | -0.0002 | 0.44 | 2 | 0.0008 |
| `variety` | 0.44 | 5 | 0.0004 | 0.46 | 4 | -0.0001 |
| `exercise_fit` | 0.43 | 2 | -0.0002 | 0.41 | 2 | 0.0002 |
| `stimulus_fatigue` | 0.44 | 3 | 0.0002 | 0.42 | 3 | 0.0001 |
| `preferences` | 0.43 | 6 | -0.0001 | 0.46 | 4 | -0.0000 |
| `novelty` | 0.60 | 15 | -0.0002 | 0.56 | 11 | 0.0005 |

## 7. Séries créditées par minute de renforcement

Séries fractionnaires créditées aux groupes majeurs par minute de renforcement, sur les profils types qui en comportent (37) : moyenne 0.94, médiane 0.95, de 0.65 à 1.21. Paramètre `creditsPerMinute` : 0.9.

## 8. Non-ressemblance au programme du propriétaire

Programme du propriétaire : 40 semaines, 45 exercices du catalogue, dont 36 accessoires. Ressemblance = indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du propriétaire la plus proche. Le programme du propriétaire comparé à lui-même, entre semaines de blocs différents : minimum 0.21, premier décile 0.30, médiane 0.60. Seuil : 0.3.

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profils types — propriétaire (graines 0 à 3) | 4 | 0.190 | 0.211 |
| Profils types — street (graines 0 à 3) | 52 | 0.063 | 0.173 |
| Profils types — sans street (graines 0 à 3) | 104 | 0.065 | 0.182 |
| Population aléatoire | 1000 | 0.040 | 0.160 |

Séance par séance (profils types, graines 0 à 3) : ressemblance maximale avec une séance du propriétaire, médiane 0.08, maximum 0.43.

Accessoires du propriétaire chez les 328 profils aléatoires sans discipline street : part des profils (où l'exercice est admissible) dont le programme le contient, face à l'exercice hors programme du propriétaire le plus choisi de la même catégorie. Sur-représenté = plus de 5 % et plus du double de ce pair. Accessoires propres au propriétaire (exercices des disciplines street de la base) sur-représentés : **0** ; accessoires du fonds commun de la musculation au-dessus de la même règle : 1 (`mu-mollets-debout-machine`).

| Accessoire du propriétaire | Propre | Catégorie | Admissible | Choisi | Meilleur pair | Choisi |
| --- | --- | --- | --- | --- | --- | --- |
| `sw-traction-scapulaire` | oui | Préparation scapulaire | 205 | 4.9 % | `mu-halo-kettlebell` | 13.4 % |
| `mo-routine-mobilite-epaules-poignets` | non | Mobilité articulaire | 144 | 45.8 % | `mo-wall-slides` | 54.3 % |
| `mu-rowing-poulie-assis-triangle` | non | Tirage horizontal | 148 | 33.1 % | `sw-row-australien` | 44.9 % |
| `mu-mollets-debout-machine` | non | Mollets et cheville | 138 | 24.6 % | `mu-mollets-unilateral-haltere` | 11.3 % |
| `mu-leg-curl-couche` | non | Flexion de genou (ischio-jambiers) | 141 | 21.3 % | `mu-nordic-hamstring-curl` | 17.9 % |
| `mu-fente-marchee-halteres` | non | Fente / unilatéral jambes | 104 | 20.2 % | `cf-fente-overhead-disque` | 28.9 % |
| `ca-marche-recuperation` | non | Marche et portage | 242 | 18.2 % | `ca-marche-rapide` | 20.2 % |
| `mu-developpe-militaire-barre-debout` | non | Poussée verticale | 87 | 16.1 % | `sw-pompe-pike` | 24.2 % |
| `mu-elevation-laterale-halteres` | non | Isolation épaules | 151 | 14.6 % | `mu-oiseau-halteres` | 15.9 % |
| `mu-face-pull-corde` | non | Tirage horizontal | 140 | 14.3 % | `sw-row-australien` | 44.9 % |
| `mu-developpe-couche-barre` | non | Poussée horizontale | 122 | 13.9 % | `mu-developpe-couche-halteres` | 34.6 % |
| `mu-y-raise-banc-incline` | non | Préparation scapulaire | 135 | 11.9 % | `mu-halo-kettlebell` | 13.4 % |
| `mu-rowing-haltere-unilateral-banc` | non | Tirage horizontal | 141 | 8.5 % | `sw-row-australien` | 44.9 % |
| `mu-rowing-barre-pronation` | non | Tirage horizontal | 105 | 7.6 % | `sw-row-australien` | 44.9 % |
| `mu-hollow-body-hold` | non | Gainage anti-extension | 156 | 7.1 % | `mu-planche-rkc` | 34.2 % |

