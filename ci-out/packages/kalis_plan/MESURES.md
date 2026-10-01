# Mesures de kalis_plan 0.1.0

Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (catalogue 1.1.0, règles 1.1.0) : 40 profils types et 1000 profils aléatoires seedés (`lib/testing.dart`, graines 500 000 et suivantes). Les temps dépendent de la machine ; tout le reste est déterministe.

## 1. Profils types

Note globale, part du temps disponible utilisée, erreur de dosage (points de pourcentage), groupes musculaires majeurs dans leur bande de volume (séries réglées de la passe 2), schémas de base couverts sur ceux que le matériel et le niveau permettent, nombre d'exercices, contraintes dures violées.

| Profil | Note | Temps | Dosage | Volume | Schémas | Exercices | Violations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_forme_generale_maison_2x30` | 0.948 | 99 % | 4.2 | 100 % | 3/3 | 11 | 0 |
| `femme_45_musculation_salle_4x60` | 0.969 | 98 % | 0.1 | 87 % | 6/6 | 36 | 0 |
| `coureur_cardio_3x45` | 0.930 | 98 % | 5.1 | 87 % | 4/5 | 18 | 0 |
| `crossfit_5x60` | 0.961 | 97 % | 0.0 | 91 % | 6/6 | 48 | 0 |
| `calisthenie_figures_4x75` | 0.952 | 85 % | 0.1 | 76 % | 6/6 | 37 | 0 |
| `street_streetlifting_4x90` | 0.957 | 93 % | 0.3 | 87 % | 6/6 | 31 | 0 |
| `street_sets_reps_4x60` | 0.948 | 98 % | 6.4 | 73 % | 6/6 | 23 | 0 |
| `street_calisthenie_5x60` | 0.960 | 84 % | 0.7 | 84 % | 6/6 | 26 | 0 |
| `blessure_epaule_musculation_3x60` | 0.963 | 98 % | 0.0 | 40 % | 5/5 | 21 | 0 |
| `minimal_1x20` | 0.913 | 97 % | 35.0 | 100 % | 1/3 | 5 | 0 |
| `six_jours_musculation_avance_6x75` | 0.969 | 84 % | 0.0 | 100 % | 6/6 | 37 | 0 |
| `senior_65_forme_generale_3x40` | 0.936 | 99 % | 3.2 | 87 % | 5/6 | 23 | 0 |
| `proprietaire_streetlifting_avance` | 0.947 | 92 % | 0.5 | 91 % | 6/6 | 36 | 0 |
| `homme_25_musculation_debutant_3x60` | 0.973 | 98 % | 0.0 | 89 % | 6/6 | 18 | 0 |
| `femme_30_street_workout_parc_3x45` | 0.958 | 93 % | 0.0 | 93 % | 6/6 | 25 | 0 |
| `mobilite_seule_5x20` | 0.976 | 93 % | 0.0 | 100 % | 0/0 | 36 | 0 |
| `cardio_debutant_marche_3x30` | 0.976 | 100 % | 0.0 | 100 % | 0/0 | 3 | 0 |
| `homme_50_reprise_genou_3x45` | 0.965 | 97 % | 4.2 | 69 % | 6/6 | 13 | 0 |
| `lombalgie_musculation_3x50` | 0.961 | 99 % | 0.6 | 38 % | 6/6 | 23 | 0 |
| `poignet_calisthenie_3x60` | 0.948 | 95 % | 0.0 | 73 % | 6/6 | 18 | 0 |
| `femme_22_calisthenie_debutante_maison` | 0.936 | 95 % | 0.1 | 100 % | 6/6 | 26 | 0 |
| `homme_35_crossfit_maison_kettlebell` | 0.952 | 94 % | 0.4 | 78 % | 6/6 | 19 | 0 |
| `musculation_maison_halteres_4x45` | 0.961 | 84 % | 0.0 | 87 % | 6/6 | 18 | 0 |
| `elite_calisthenie_6x90` | 0.947 | 65 % | 0.5 | 64 % | 6/6 | 45 | 0 |
| `streetlifting_debutant_3x60` | 0.963 | 98 % | 0.8 | 64 % | 6/6 | 18 | 0 |
| `forme_generale_exterieur_3x40` | 0.952 | 97 % | 5.2 | 93 % | 4/6 | 15 | 0 |
| `senior_72_mobilite_marche_4x30` | 0.974 | 94 % | 0.0 | 100 % | 0/0 | 26 | 0 |
| `femme_60_musculation_salle_2x45` | 0.960 | 99 % | 0.8 | 62 % | 6/6 | 13 | 0 |
| `homme_40_cardio_musculation_50_50` | 0.972 | 99 % | 1.8 | 73 % | 6/6 | 15 | 0 |
| `trois_disciplines_70_20_10` | 0.967 | 100 % | 1.1 | 89 % | 6/6 | 28 | 0 |
| `niveaux_inconnus_sans_poids` | 0.971 | 96 % | 0.0 | 96 % | 6/6 | 14 | 0 |
| `sans_objectif_mode_libre` | 0.969 | 77 % | 0.4 | 84 % | 6/6 | 16 | 0 |
| `objectif_habitude_seul` | 0.939 | 98 % | 5.6 | 62 % | 5/6 | 12 | 0 |
| `objectif_figure_front_lever` | 0.951 | 82 % | 0.3 | 69 % | 6/6 | 20 | 0 |
| `semi_marathon` | 0.953 | 100 % | 6.8 | 100 % | 4/4 | 19 | 0 |
| `prudent_sante_musculation` | 0.952 | 97 % | 1.3 | 84 % | 5/6 | 10 | 0 |
| `tres_grand_lourd` | 0.968 | 100 % | 0.3 | 71 % | 6/6 | 16 | 0 |
| `petite_legere` | 0.959 | 91 % | 0.0 | 71 % | 6/6 | 23 | 0 |
| `sept_jours_courts_7x20` | 0.939 | 99 % | 7.4 | 78 % | 6/6 | 27 | 0 |
| `materiel_complet_gouts_marques` | 0.969 | 96 % | 0.3 | 100 % | 6/6 | 26 | 0 |

## 2. Temps de calcul

Par profil type : médiane de trois exécutions, moteur neuf à chaque fois, après un premier passage de mise en route. Temps en millisecondes sur la machine du contrôle (un cœur).

| Opération | Médiane | 95e centile | Maximum |
| --- | --- | --- | --- |
| Passe 1 (création) | 27.4 | 55.3 | 58.6 |
| Passe 2 | 1.1 | 3.6 | 3.9 |
| Génération complète (passes 1 + 2) | 28.4 | 58.9 | 61.7 |
| Régénération après une action de revue | 7.6 | 15.8 | 24.1 |
| Variantes d'un exercice | 1.0 | 1.6 | 1.8 |
| Autre proposition | 15.1 | 30.0 | 42.5 |
| Bloc suivant | 8.2 | 18.3 | 22.1 |
| Restructuration de la fin du bloc | 8.1 | 15.5 | 18.0 |

## 3. Population de 1000 profils aléatoires

Programmes avec une contrainte dure violée : **0** ; programmes invalides au sens du contrat : **0** ; programmes avec au moins une séance de repli : 2.

| Mesure | Moyenne | 5e centile | Médiane | 95e centile | Minimum | Maximum |
| --- | --- | --- | --- | --- | --- | --- |
| Note globale | 0.923 | 0.855 | 0.929 | 0.967 | 0.745 | 0.977 |
| Temps utilisé (%) | 89.4 | 57.1 | 95.2 | 99.7 | 22.9 | 100.0 |
| Groupes dans leur bande (%) | 78.0 | 44.4 | 80.0 | 100.0 | 15.6 | 100.0 |
| Erreur de dosage (points) | 9.2 | 0.0 | 1.5 | 40.2 | 0.0 | 100.0 |
| Schémas de base couverts (%) | 91.4 | 33.3 | 100.0 | 100.0 | 0.0 | 100.0 |
| Passe 1 (ms) | 27.958 | 5.000 | 23.400 | 63.200 | 1.100 | 162.300 |
| Régénération en revue (ms) | 7.103 | 1.900 | 6.500 | 14.200 | 0.500 | 73.600 |

Diff minimal — changements d'exercice hors de l'emplacement visé, par action de revue :

| Action | Moyenne | Sans aucun autre changement | Maximum |
| --- | --- | --- | --- |
| `cannot_do` | 0.59 | 73 % | 12 |
| `dislike` | 0.58 | 80 % | 12 |
| `remove` | 0.50 | 57 % | 4 |

## 4. « Autre proposition »

Graines 1 à 7 de chaque profil type (280 propositions). Note rapportée à celle de la meilleure : minimum 0.9780, médiane 0.9992 (plancher du contrat : 0.97). Part d'exercices absents de chacune des propositions déjà montrées : médiane 42 %, minimum 0 % ; **91 %** des propositions atteignent le tiers visé. Programmes distincts parmi les huit premiers : 8.0 en moyenne, 8 au minimum.

## 5. Convergence de la recherche

Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils types selon l'effort de recuit ; dernière colonne : profils dont l'objectif dépasse celui de l'effort × 1.

| Effort | Coups de recuit | Objectif moyen | Temps moyen (ms) | Profils améliorés |
| --- | --- | --- | --- | --- |
| × 0.0 | 0 | 1.95086 | 17.0 | — |
| × 0.25 | 750 | 1.95315 | 21.5 | — |
| × 0.5 | 1500 | 1.95349 | 24.5 | — |
| × 1.0 | 3000 | 1.95529 | 27.5 | — |
| × 2.0 | 6000 | 1.95529 | 35.3 | 17 |
| × 4.0 | 12000 | 1.95683 | 47.8 | 27 |

## 6. Sensibilité aux poids de la note

Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : recouvrement moyen (Jaccard) des exercices avec le programme de référence sur les 40 profils types, nombre de programmes identiques, et regret moyen (objectif de référence perdu par le programme obtenu, sur une échelle de 0 à 2).

| Poids | Jaccard × 0,8 | Identiques | Regret | Jaccard × 1,2 | Identiques | Regret |
| --- | --- | --- | --- | --- | --- | --- |
| `recovery` | 0.49 | 7 | 0.0004 | 0.50 | 8 | 0.0003 |
| `fatigue_balance` | 0.49 | 7 | 0.0012 | 0.48 | 7 | 0.0008 |
| `joint_load` | 0.56 | 12 | 0.0013 | 0.60 | 13 | 0.0008 |
| `goal_specificity` | 0.48 | 7 | 0.0003 | 0.47 | 7 | 0.0003 |
| `discipline_dosage` | 0.42 | 3 | 0.0010 | 0.45 | 4 | 0.0004 |
| `muscle_volume` | 0.41 | 2 | 0.0008 | 0.40 | 2 | 0.0009 |
| `pattern_balance` | 0.42 | 4 | 0.0011 | 0.43 | 3 | 0.0014 |
| `discipline_structure` | 0.44 | 4 | 0.0007 | 0.44 | 6 | 0.0008 |
| `time_use` | 0.45 | 5 | 0.0001 | 0.40 | 3 | 0.0017 |
| `variety` | 0.47 | 5 | 0.0011 | 0.48 | 7 | 0.0008 |
| `exercise_fit` | 0.43 | 4 | 0.0010 | 0.44 | 3 | 0.0013 |
| `stimulus_fatigue` | 0.44 | 5 | 0.0000 | 0.50 | 5 | 0.0006 |
| `preferences` | 0.50 | 6 | 0.0002 | 0.47 | 5 | 0.0009 |
| `novelty` | 0.59 | 13 | 0.0004 | 0.58 | 13 | -0.0000 |

## 7. Séries créditées par minute de renforcement

Séries fractionnaires créditées aux groupes majeurs par minute de renforcement, sur les profils types qui en comportent (37) : moyenne 0.90, médiane 0.88, de 0.65 à 1.18. Paramètre `creditsPerMinute` : 0.9.

## 8. Non-ressemblance au programme du propriétaire

Programme du propriétaire : 40 semaines, 45 exercices du catalogue, dont 36 accessoires. Ressemblance = indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du propriétaire la plus proche. Le programme du propriétaire comparé à lui-même, entre semaines de blocs différents : minimum 0.21, premier décile 0.30, médiane 0.60. Seuil : 0.3.

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profils types — propriétaire (graines 0 à 3) | 4 | 0.164 | 0.173 |
| Profils types — street (graines 0 à 3) | 52 | 0.075 | 0.196 |
| Profils types — sans street (graines 0 à 3) | 104 | 0.067 | 0.197 |
| Population aléatoire | 1000 | 0.042 | 0.175 |

Séance par séance (profils types, graines 0 à 3) : ressemblance maximale avec une séance du propriétaire, médiane 0.09, maximum 0.33.

Accessoires du propriétaire chez les 328 profils aléatoires sans discipline street : part des profils (où l'exercice est admissible) dont le programme le contient, face à l'exercice hors programme du propriétaire le plus choisi de la même catégorie. Sur-représenté = plus de 5 % et plus du double de ce pair. Accessoires propres au propriétaire (exercices des disciplines street de la base) sur-représentés : **0** ; accessoires du fonds commun de la musculation au-dessus de la même règle : 1 (`mu-mollets-debout-machine`).

| Accessoire du propriétaire | Propre | Catégorie | Admissible | Choisi | Meilleur pair | Choisi |
| --- | --- | --- | --- | --- | --- | --- |
| `sw-traction-scapulaire` | oui | Préparation scapulaire | 205 | 4.4 % | `sw-active-hang` | 8.3 % |
| `mo-routine-mobilite-epaules-poignets` | non | Mobilité articulaire | 144 | 48.6 % | `mo-wall-slides` | 47.8 % |
| `mu-rowing-poulie-assis-triangle` | non | Tirage horizontal | 148 | 37.2 % | `sw-row-australien` | 47.8 % |
| `mu-mollets-debout-machine` | non | Mollets et cheville | 138 | 26.1 % | `mu-mollets-unilateral-haltere` | 11.3 % |
| `mu-elevation-laterale-halteres` | non | Isolation épaules | 151 | 23.8 % | `mu-lu-raise` | 31.4 % |
| `mu-face-pull-corde` | non | Tirage horizontal | 140 | 20.0 % | `sw-row-australien` | 47.8 % |
| `mu-fente-marchee-halteres` | non | Fente / unilatéral jambes | 104 | 19.2 % | `mu-fente-laterale` | 25.6 % |
| `ca-marche-recuperation` | non | Marche et portage | 242 | 17.4 % | `ca-marche-rapide` | 21.1 % |
| `mu-developpe-militaire-barre-debout` | non | Poussée verticale | 87 | 16.1 % | `sw-dips-assistes-pieds` | 20.0 % |
| `mu-leg-curl-couche` | non | Flexion de genou (ischio-jambiers) | 141 | 14.9 % | `mu-nordic-hamstring-curl` | 22.4 % |
| `mu-developpe-couche-barre` | non | Poussée horizontale | 122 | 14.8 % | `mu-developpe-couche-halteres` | 39.8 % |
| `mu-y-raise-banc-incline` | non | Préparation scapulaire | 135 | 12.6 % | `sw-active-hang` | 8.3 % |
| `mu-pallof-press-debout` | non | Gainage anti-rotation | 141 | 11.3 % | `mu-bird-dog` | 12.4 % |
| `mu-hollow-body-hold` | non | Gainage anti-extension | 156 | 9.6 % | `mu-planche-rkc` | 35.5 % |
| `mu-rowing-barre-pronation` | non | Tirage horizontal | 105 | 8.6 % | `sw-row-australien` | 47.8 % |

