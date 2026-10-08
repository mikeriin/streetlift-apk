# Mesures de kalis_plan 0.2.3

Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (catalogue 1.1.0, règles 1.1.0) : 40 profils types et 1000 profils aléatoires seedés (`lib/testing.dart`, graines 500 000 et suivantes). Les temps dépendent de la machine ; tout le reste est déterministe.

## 1. Profils types

Note globale, part du temps disponible utilisée, erreur de dosage (points de pourcentage), groupes musculaires majeurs dans leur bande de volume (séries réglées de la passe 2), schémas de base couverts sur ceux que le matériel et le niveau permettent, nombre d'exercices, contraintes dures violées.

| Profil | Note | Temps | Dosage | Volume | Schémas | Exercices | Violations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | 0.957 | 99 % | 4.8 | 100 % | 3/3 | 10 | 0 |
| `femme_45_musculation_salle_4x60` | 0.969 | 99 % | 0.1 | 96 % | 6/6 | 35 | 0 |
| `coureur_cardio_3x45` | 0.933 | 98 % | 4.5 | 93 % | 4/5 | 13 | 0 |
| `crossfit_5x60` | 0.956 | 94 % | 0.0 | 91 % | 6/6 | 46 | 0 |
| `calisthenie_figures_4x75` | 0.956 | 93 % | 0.1 | 87 % | 6/6 | 40 | 0 |
| `street_streetlifting_4x90` | 0.959 | 92 % | 0.2 | 80 % | 6/6 | 28 | 0 |
| `street_sets_reps_4x60` | 0.952 | 96 % | 1.7 | 80 % | 6/6 | 23 | 0 |
| `street_calisthenie_5x60` | 0.961 | 79 % | 0.0 | 82 % | 6/6 | 25 | 0 |
| `blessure_epaule_musculation_3x60` | 0.964 | 99 % | 0.0 | 64 % | 5/5 | 21 | 0 |
| `minimal_1x20` | 0.918 | 97 % | 35.0 | 100 % | 2/3 | 6 | 0 |
| `six_jours_musculation_avance_6x75` | 0.967 | 85 % | 0.0 | 73 % | 6/6 | 38 | 0 |
| `senior_65_forme_generale_3x40` | 0.937 | 100 % | 7.2 | 93 % | 5/6 | 23 | 0 |
| `proprietaire_streetlifting_avance` | 0.951 | 89 % | 0.2 | 84 % | 6/6 | 35 | 0 |
| `homme_25_musculation_debutant_3x60` | 0.973 | 98 % | 0.0 | 96 % | 6/6 | 18 | 0 |
| `femme_30_street_workout_parc_3x45` | 0.960 | 83 % | 0.0 | 84 % | 6/6 | 21 | 0 |
| `mobilite_seule_5x20` | 0.976 | 95 % | 0.0 | 100 % | 0/0 | 36 | 0 |
| `cardio_debutant_marche_3x30` | 0.976 | 100 % | 0.0 | 100 % | 0/0 | 3 | 0 |
| `homme_50_reprise_genou_3x45` | 0.963 | 98 % | 0.2 | 82 % | 6/6 | 12 | 0 |
| `lombalgie_musculation_3x50` | 0.964 | 98 % | 0.1 | 64 % | 6/6 | 24 | 0 |
| `poignet_calisthenie_3x60` | 0.953 | 98 % | 0.0 | 89 % | 6/6 | 18 | 0 |
| `femme_22_calisthenie_debutante_maison` | 0.948 | 98 % | 0.1 | 93 % | 6/6 | 28 | 0 |
| `homme_35_crossfit_maison_kettlebell` | 0.949 | 96 % | 0.0 | 49 % | 6/6 | 17 | 0 |
| `musculation_maison_halteres_4x45` | 0.961 | 96 % | 0.0 | 87 % | 6/6 | 21 | 0 |
| `elite_calisthenie_6x90` | 0.943 | 62 % | 3.0 | 56 % | 6/6 | 42 | 0 |
| `streetlifting_debutant_3x60` | 0.965 | 97 % | 0.5 | 80 % | 6/6 | 19 | 0 |
| `forme_generale_exterieur_3x40` | 0.950 | 98 % | 0.0 | 93 % | 4/6 | 15 | 0 |
| `senior_72_mobilite_marche_4x30` | 0.974 | 94 % | 0.1 | 100 % | 0/0 | 25 | 0 |
| `femme_60_musculation_salle_2x45` | 0.955 | 99 % | 0.1 | 62 % | 6/6 | 14 | 0 |
| `homme_40_cardio_musculation_50_50` | 0.971 | 98 % | 0.0 | 87 % | 6/6 | 15 | 0 |
| `trois_disciplines_70_20_10` | 0.971 | 99 % | 1.6 | 96 % | 6/6 | 27 | 0 |
| `niveaux_inconnus_sans_poids` | 0.975 | 98 % | 0.0 | 100 % | 6/6 | 14 | 0 |
| `sans_objectif_mode_libre` | 0.973 | 97 % | 0.0 | 76 % | 6/6 | 21 | 0 |
| `objectif_habitude_seul` | 0.937 | 99 % | 0.9 | 93 % | 4/6 | 12 | 0 |
| `objectif_figure_front_lever` | 0.962 | 81 % | 0.4 | 80 % | 6/6 | 20 | 0 |
| `semi_marathon` | 0.960 | 100 % | 2.1 | 100 % | 4/4 | 19 | 0 |
| `prudent_sante_musculation` | 0.952 | 98 % | 1.8 | 89 % | 5/6 | 10 | 0 |
| `tres_grand_lourd` | 0.972 | 100 % | 0.8 | 76 % | 6/6 | 16 | 0 |
| `petite_legere` | 0.961 | 97 % | 0.0 | 87 % | 6/6 | 24 | 0 |
| `sept_jours_courts_7x20` | 0.947 | 99 % | 7.5 | 93 % | 5/6 | 29 | 0 |
| `materiel_complet_gouts_marques` | 0.967 | 97 % | 0.3 | 96 % | 6/6 | 23 | 0 |

## 2. Temps de calcul

Par profil type : médiane de trois exécutions, moteur neuf à chaque fois, après un premier passage de mise en route. Temps en millisecondes sur la machine du contrôle (un cœur).

| Opération | Médiane | 95e centile | Maximum |
| --- | --- | --- | --- |
| Passe 1 (création) | 48.8 | 88.9 | 92.5 |
| Passe 2 | 1.2 | 2.7 | 4.0 |
| Génération complète (passes 1 + 2) | 50.1 | 90.7 | 95.2 |
| Régénération après une action de revue | 7.1 | 12.4 | 16.6 |
| Variantes d'un exercice | 1.0 | 1.5 | 2.0 |
| Autre proposition | 20.0 | 35.8 | 49.0 |
| Bloc suivant | 8.4 | 17.3 | 21.1 |
| Restructuration de la fin du bloc | 7.5 | 16.3 | 18.9 |

## 3. Population de 1000 profils aléatoires

Programmes avec une contrainte dure violée : **0** ; programmes invalides au sens du contrat : **0** ; programmes avec au moins une séance de repli : 3.

| Mesure | Moyenne | 5e centile | Médiane | 95e centile | Minimum | Maximum |
| --- | --- | --- | --- | --- | --- | --- |
| Note globale | 0.926 | 0.864 | 0.933 | 0.967 | 0.734 | 0.977 |
| Temps utilisé (%) | 88.6 | 56.6 | 95.0 | 99.8 | 25.1 | 100.0 |
| Groupes dans leur bande (%) | 81.9 | 53.3 | 84.4 | 100.0 | 17.8 | 100.0 |
| Erreur de dosage (points) | 9.6 | 0.0 | 1.7 | 40.4 | 0.0 | 100.0 |
| Schémas de base couverts (%) | 92.1 | 50.0 | 100.0 | 100.0 | 0.0 | 100.0 |
| Passe 1 (ms) | 46.611 | 13.500 | 42.400 | 92.500 | 3.100 | 210.800 |
| Régénération en revue (ms) | 6.946 | 2.000 | 6.400 | 13.500 | 0.500 | 30.900 |

Diff minimal — changements d'exercice hors de l'emplacement visé, par action de revue :

| Action | Moyenne | Sans aucun autre changement | Maximum |
| --- | --- | --- | --- |
| `cannot_do` | 0.67 | 74 % | 12 |
| `dislike` | 0.52 | 80 % | 12 |
| `remove` | 0.51 | 58 % | 5 |

## 4. « Autre proposition »

Graines 1 à 7 de chaque profil type (280 propositions). Note rapportée à celle de la meilleure : minimum 0.9811, médiane 0.9985 (plancher du contrat : 0.97). Part d'exercices absents de chacune des propositions déjà montrées : médiane 42 %, minimum 0 % ; **92 %** des propositions atteignent le tiers visé. Programmes distincts parmi les huit premiers : 8.0 en moyenne, 8 au minimum.

## 5. Convergence de la recherche

Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils types selon l'effort de recuit ; dernières colonnes : profils dont l'objectif est au-dessus, puis au-dessous, de celui de l'effort × 1.

| Effort | Coups de recuit | Objectif moyen | Temps moyen (ms) | Profils améliorés | Profils dégradés |
| --- | --- | --- | --- | --- | --- |
| × 0.0 | 0 | 1.95196 | 15.8 | — | — |
| × 0.0625 | 750 | 1.95301 | 20.7 | — | — |
| × 0.125 | 1500 | 1.95442 | 23.1 | — | — |
| × 0.25 | 3000 | 1.95516 | 28.3 | — | — |
| × 0.5 | 6000 | 1.95628 | 35.3 | — | — |
| × 1.0 | 12000 | 1.95715 | 48.9 | — | — |
| × 2.0 | 24000 | 1.95751 | 74.5 | 21 | 17 |

## 6. Sensibilité aux poids de la note

Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : recouvrement moyen (Jaccard) des exercices avec le programme de référence sur les 40 profils types, nombre de programmes identiques, et regret moyen (objectif de référence perdu par le programme obtenu, sur une échelle de 0 à 2).

| Poids | Jaccard × 0,8 | Identiques | Regret | Jaccard × 1,2 | Identiques | Regret |
| --- | --- | --- | --- | --- | --- | --- |
| `recovery` | 0.47 | 5 | 0.0004 | 0.41 | 2 | 0.0003 |
| `fatigue_balance` | 0.42 | 2 | 0.0006 | 0.46 | 4 | 0.0006 |
| `joint_load` | 0.52 | 8 | 0.0002 | 0.47 | 5 | 0.0008 |
| `goal_specificity` | 0.41 | 3 | -0.0000 | 0.41 | 2 | 0.0000 |
| `discipline_dosage` | 0.44 | 2 | 0.0003 | 0.43 | 2 | 0.0001 |
| `muscle_volume` | 0.42 | 3 | 0.0005 | 0.41 | 2 | 0.0000 |
| `pattern_balance` | 0.41 | 2 | 0.0000 | 0.42 | 3 | 0.0001 |
| `discipline_structure` | 0.43 | 2 | 0.0002 | 0.43 | 2 | 0.0000 |
| `time_use` | 0.42 | 3 | 0.0002 | 0.41 | 2 | 0.0006 |
| `variety` | 0.43 | 3 | 0.0001 | 0.41 | 2 | 0.0004 |
| `exercise_fit` | 0.43 | 1 | 0.0000 | 0.44 | 2 | 0.0005 |
| `stimulus_fatigue` | 0.41 | 1 | 0.0006 | 0.41 | 2 | 0.0009 |
| `preferences` | 0.39 | 2 | 0.0007 | 0.43 | 3 | 0.0004 |
| `novelty` | 0.43 | 2 | 0.0001 | 0.42 | 1 | 0.0006 |

## 7. Séries créditées par minute de renforcement

Séries fractionnaires créditées aux groupes majeurs par minute de renforcement, sur les profils types qui en comportent (37) : moyenne 0.94, médiane 0.97, de 0.66 à 1.20. Paramètre `creditsPerMinute` : 0.9.

## 8. Non-ressemblance au programme du propriétaire

Programme du propriétaire : 40 semaines, 45 exercices du catalogue, dont 36 accessoires. Ressemblance = indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du propriétaire la plus proche. Le programme du propriétaire comparé à lui-même, entre semaines de blocs différents : minimum 0.21, premier décile 0.30, médiane 0.60. Seuil : 0.3.

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profils types — propriétaire (graines 0 à 3) | 4 | 0.151 | 0.154 |
| Profils types — street (graines 0 à 3) | 52 | 0.067 | 0.167 |
| Profils types — sans street (graines 0 à 3) | 104 | 0.065 | 0.196 |
| Population aléatoire | 1000 | 0.038 | 0.227 |

Séance par séance (profils types, graines 0 à 3) : ressemblance maximale avec une séance du propriétaire, médiane 0.09, maximum 0.40.

Accessoires du propriétaire chez les 328 profils aléatoires sans discipline street : part des profils (où l'exercice est admissible) dont le programme le contient, face à l'exercice hors programme du propriétaire le plus choisi de la même catégorie. Sur-représenté = plus de 5 % et plus du double de ce pair. Accessoires propres au propriétaire (exercices des disciplines street de la base) sur-représentés : **0** ; accessoires du fonds commun de la musculation au-dessus de la même règle : 1 (`mu-mollets-debout-machine`).

| Accessoire du propriétaire | Propre | Catégorie | Admissible | Choisi | Meilleur pair | Choisi |
| --- | --- | --- | --- | --- | --- | --- |
| `sw-traction-scapulaire` | oui | Préparation scapulaire | 203 | 4.4 % | `mu-halo-kettlebell` | 9.0 % |
| `mo-routine-mobilite-epaules-poignets` | non | Mobilité articulaire | 144 | 53.5 % | `mo-wall-slides` | 53.2 % |
| `mu-rowing-poulie-assis-triangle` | non | Tirage horizontal | 146 | 34.9 % | `sw-row-australien` | 55.1 % |
| `mu-leg-curl-couche` | non | Flexion de genou (ischio-jambiers) | 141 | 25.5 % | `mu-nordic-hamstring-curl` | 28.1 % |
| `mu-fente-marchee-halteres` | non | Fente / unilatéral jambes | 102 | 23.5 % | `cf-fente-overhead-disque` | 32.4 % |
| `ca-marche-recuperation` | non | Marche et portage | 241 | 19.5 % | `ca-marche-rapide` | 25.7 % |
| `mu-developpe-militaire-barre-debout` | non | Poussée verticale | 85 | 17.6 % | `mu-developpe-epaules-elastique-debout` | 17.6 % |
| `mu-mollets-debout-machine` | non | Mollets et cheville | 138 | 17.4 % | `mu-mollets-unilateral-haltere` | 4.9 % |
| `mu-elevation-laterale-halteres` | non | Isolation épaules | 151 | 16.6 % | `mu-elevation-laterale-buste-appuye-banc-incline` | 18.5 % |
| `mu-y-raise-banc-incline` | non | Préparation scapulaire | 133 | 15.8 % | `mu-halo-kettlebell` | 9.0 % |
| `mu-developpe-couche-barre` | non | Poussée horizontale | 122 | 15.6 % | `sw-pompe-t` | 36.9 % |
| `mu-pallof-press-debout` | non | Gainage anti-rotation | 140 | 10.7 % | `mu-bird-dog` | 13.8 % |
| `mu-rowing-barre-pronation` | non | Tirage horizontal | 105 | 10.5 % | `sw-row-australien` | 55.1 % |
| `mu-face-pull-corde` | non | Tirage horizontal | 139 | 7.9 % | `sw-row-australien` | 55.1 % |
| `mu-hollow-body-hold` | non | Gainage anti-extension | 153 | 7.8 % | `mu-planche-rkc` | 38.8 % |

