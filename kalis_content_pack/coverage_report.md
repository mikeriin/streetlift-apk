# Rapport de couverture et de validation — pack de contenu Kalis Track v1 (L9)

Généré par `tools/validate.py`. Statistiques calculées sur `exercises_v2.json`.

## 1. Synthèse

- Exercices dans le pack : **555** (dont 505 issus de la base v1 et 50 ajoutés en L9).
- Utilisables par le générateur : **505** ; doublons signalés : 22 ; tests : 19 ; hors générateur : 9.
- Exercices avec au moins une non-conformité signalée : 50.
- Chaînes de progression : 24 ; entrées « débutant complet » : 12.
- Gabarits de pose utilisés : 200 ; couverture des poses : 100 % des exercices.

## 2. Contrôles automatiques

| Contrôle | Résultat |
| --- | --- |
| schema | OK |
| graphe | OK |
| poses | OK |
| interpolation | OK |
| correspondance | OK |
| prerequis | OK |
| substitutions | OK |

### Avertissements (non bloquants)

Exercices de difficulté ≥ 7 sans prérequis explicite (le générateur doit les réserver aux profils avancés) :

`archer-rows-anneaux`, `around-the-world-suspendu`, `butterfly-pull-ups`, `chest-to-bar-kipping`, `clean-et-jerk`, `dips-aux-anneaux`, `dips-aux-anneaux-rto-tournes`, `dips-coreens`, `front-lever-negatif`, `front-lever-pull-ups-tuck`, `front-lever-raises`, `hspu-kipping`, `ice-cream-makers`, `isometrie-de-transition-muscle-up`, `kettlebell-snatch`, `man-makers`, `muscle-up`, `muscle-up-aux-anneaux`, `muscle-up-aux-anneaux-strict`, `nordic-curl-excentrique`, `pompes-pliometriques-mains-sur-boxes`, `pompes-typewriter`, `power-clean`, `push-jerk`, `rollout-barre`, `russian-dips`, `sauts-en-contrebas-depth-jumps`, `snatch-arrache`, `squat-overhead`, `tirage-bucheron-a-la-barre-fixe`, `toes-to-bar-strict`, `traction-a-la-serviette`, `traction-autour-du-monde`, `traction-explosive`, `traction-haute-explosive-high-pull-up`, `traction-l-sit`, `traction-sternum`, `traction-typewriter`, `windshield-wipers-essuie-glaces`

## 3. Matrice de couverture pour le générateur

Nombre d'exercices utilisables par type de mouvement, lieu et tranche de difficulté (seuil : 3). Une case en **gras** signale un manque.

| Type | Maison sans matériel 1-3 | Maison sans matériel 4-6 | Maison sans matériel 7-10 | Maison équipée 1-3 | Maison équipée 4-6 | Maison équipée 7-10 | Parc de street workout 1-3 | Parc de street workout 4-6 | Parc de street workout 7-10 | Salle 1-3 | Salle 4-6 | Salle 7-10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Poussée horizontale | 8 | 9 | 3 | 10 | 14 | 4 | 8 | 14 | 4 | 13 | 17 | 4 |
| Poussée verticale | 3 | **2** | 3 | 8 | 17 | 11 | 6 | 14 | 11 | 9 | 21 | 12 |
| Tirage horizontal | **2** | **0** | **0** | 14 | 3 | **1** | 9 | 3 | **1** | 17 | 7 | **1** |
| Tirage vertical | **1** | **0** | **0** | 6 | 18 | 17 | 4 | 18 | 16 | 11 | 18 | 17 |
| Squat | 4 | 6 | **2** | 7 | 8 | 3 | 5 | 8 | **2** | 9 | 17 | 4 |
| Charnière de hanche | 4 | **2** | **0** | 6 | 6 | **0** | 3 | **2** | **0** | 9 | 13 | **0** |
| Fente | 7 | 4 | **0** | 8 | 8 | **0** | 7 | 7 | **0** | 8 | 8 | **0** |
| Gainage anti-extension | 11 | 3 | **0** | 11 | 6 | 4 | 11 | 3 | **0** | 11 | 7 | 5 |
| Gainage anti-rotation | 6 | **2** | **0** | 8 | **2** | **2** | 6 | **2** | **2** | 10 | 3 | **2** |
| Gainage anti-flexion latérale | 3 | **2** | **0** | 4 | 3 | **0** | 3 | **2** | **0** | 4 | 4 | **0** |
| Portés | **0** | **0** | **0** | 5 | **1** | **0** | **1** | **0** | **0** | 7 | **2** | **0** |
| Locomotion | 5 | 7 | **1** | 7 | 7 | **1** | 7 | 7 | **1** | 8 | 7 | **1** |
| Mobilité | 15 | **2** | **0** | 17 | 3 | **0** | 15 | 3 | **0** | 17 | 3 | **0** |
| Figure statique | **1** | 6 | 5 | 9 | 21 | 16 | 9 | 21 | 19 | 9 | 22 | 19 |
| Figure dynamique | **0** | **2** | **0** | **0** | 11 | 15 | **0** | 8 | 14 | **0** | 12 | 18 |
| Conditionnement | 6 | 4 | **0** | 10 | 13 | **2** | 9 | 10 | **1** | 14 | 21 | **2** |
| Isolation (mono-articulaire) | 4 | **1** | **1** | 36 | **2** | **1** | 11 | **1** | **1** | 61 | 3 | **1** |
| Flexion du tronc | 5 | **1** | **0** | 6 | 6 | **2** | 6 | 5 | **2** | 8 | 7 | **2** |

### Manques signalés (79 cases sous le seuil)

Ces manques sont attendus quand le lieu rend le mouvement impossible ou dangereux (ex. tirage vertical difficile sans matériel) ; le générateur doit alors basculer sur le type voisin ou proposer l'achat d'un élastique. Liste complète :

| Type | Lieu | Difficulté | Nombre |
| --- | --- | --- | --- |
| Poussée verticale | Maison sans matériel | 4-6 | 2 |
| Tirage horizontal | Maison sans matériel | 1-3 | 2 |
| Tirage horizontal | Maison sans matériel | 4-6 | 0 |
| Tirage horizontal | Maison sans matériel | 7-10 | 0 |
| Tirage horizontal | Maison équipée | 7-10 | 1 |
| Tirage horizontal | Parc de street workout | 7-10 | 1 |
| Tirage horizontal | Salle | 7-10 | 1 |
| Tirage vertical | Maison sans matériel | 1-3 | 1 |
| Tirage vertical | Maison sans matériel | 4-6 | 0 |
| Tirage vertical | Maison sans matériel | 7-10 | 0 |
| Squat | Maison sans matériel | 7-10 | 2 |
| Squat | Parc de street workout | 7-10 | 2 |
| Charnière de hanche | Maison sans matériel | 4-6 | 2 |
| Charnière de hanche | Maison sans matériel | 7-10 | 0 |
| Charnière de hanche | Maison équipée | 7-10 | 0 |
| Charnière de hanche | Parc de street workout | 4-6 | 2 |
| Charnière de hanche | Parc de street workout | 7-10 | 0 |
| Charnière de hanche | Salle | 7-10 | 0 |
| Fente | Maison sans matériel | 7-10 | 0 |
| Fente | Maison équipée | 7-10 | 0 |
| Fente | Parc de street workout | 7-10 | 0 |
| Fente | Salle | 7-10 | 0 |
| Gainage anti-extension | Maison sans matériel | 7-10 | 0 |
| Gainage anti-extension | Parc de street workout | 7-10 | 0 |
| Gainage anti-rotation | Maison sans matériel | 4-6 | 2 |
| Gainage anti-rotation | Maison sans matériel | 7-10 | 0 |
| Gainage anti-rotation | Maison équipée | 4-6 | 2 |
| Gainage anti-rotation | Maison équipée | 7-10 | 2 |
| Gainage anti-rotation | Parc de street workout | 4-6 | 2 |
| Gainage anti-rotation | Parc de street workout | 7-10 | 2 |
| Gainage anti-rotation | Salle | 7-10 | 2 |
| Gainage anti-flexion latérale | Maison sans matériel | 4-6 | 2 |
| Gainage anti-flexion latérale | Maison sans matériel | 7-10 | 0 |
| Gainage anti-flexion latérale | Maison équipée | 7-10 | 0 |
| Gainage anti-flexion latérale | Parc de street workout | 4-6 | 2 |
| Gainage anti-flexion latérale | Parc de street workout | 7-10 | 0 |
| Gainage anti-flexion latérale | Salle | 7-10 | 0 |
| Portés | Maison sans matériel | 1-3 | 0 |
| Portés | Maison sans matériel | 4-6 | 0 |
| Portés | Maison sans matériel | 7-10 | 0 |
| Portés | Maison équipée | 4-6 | 1 |
| Portés | Maison équipée | 7-10 | 0 |
| Portés | Parc de street workout | 1-3 | 1 |
| Portés | Parc de street workout | 4-6 | 0 |
| Portés | Parc de street workout | 7-10 | 0 |
| Portés | Salle | 4-6 | 2 |
| Portés | Salle | 7-10 | 0 |
| Locomotion | Maison sans matériel | 7-10 | 1 |
| Locomotion | Maison équipée | 7-10 | 1 |
| Locomotion | Parc de street workout | 7-10 | 1 |
| Locomotion | Salle | 7-10 | 1 |
| Mobilité | Maison sans matériel | 4-6 | 2 |
| Mobilité | Maison sans matériel | 7-10 | 0 |
| Mobilité | Maison équipée | 7-10 | 0 |
| Mobilité | Parc de street workout | 7-10 | 0 |
| Mobilité | Salle | 7-10 | 0 |
| Figure statique | Maison sans matériel | 1-3 | 1 |
| Figure dynamique | Maison sans matériel | 1-3 | 0 |
| Figure dynamique | Maison sans matériel | 4-6 | 2 |
| Figure dynamique | Maison sans matériel | 7-10 | 0 |
| Figure dynamique | Maison équipée | 1-3 | 0 |
| Figure dynamique | Parc de street workout | 1-3 | 0 |
| Figure dynamique | Salle | 1-3 | 0 |
| Conditionnement | Maison sans matériel | 7-10 | 0 |
| Conditionnement | Maison équipée | 7-10 | 2 |
| Conditionnement | Parc de street workout | 7-10 | 1 |
| Conditionnement | Salle | 7-10 | 2 |
| Isolation (mono-articulaire) | Maison sans matériel | 4-6 | 1 |
| Isolation (mono-articulaire) | Maison sans matériel | 7-10 | 1 |
| Isolation (mono-articulaire) | Maison équipée | 4-6 | 2 |
| Isolation (mono-articulaire) | Maison équipée | 7-10 | 1 |
| Isolation (mono-articulaire) | Parc de street workout | 4-6 | 1 |
| Isolation (mono-articulaire) | Parc de street workout | 7-10 | 1 |
| Isolation (mono-articulaire) | Salle | 7-10 | 1 |
| Flexion du tronc | Maison sans matériel | 4-6 | 1 |
| Flexion du tronc | Maison sans matériel | 7-10 | 0 |
| Flexion du tronc | Maison équipée | 7-10 | 2 |
| Flexion du tronc | Parc de street workout | 7-10 | 2 |
| Flexion du tronc | Salle | 7-10 | 2 |

## 4. Substitutions

Substitutions calculées : même type de mouvement, difficulté ±1, par lieu (3 au plus, classées par écart de difficulté puis muscles primaires communs). Exercices du générateur sans substitution dans un de leurs lieux compatibles : **0**.

## 5. Correspondances

- Base v1 : 505 noms rattachés sur 505.
- Programme de 40 semaines : 79 intitulés distincts rattachés (44 exacts, 35 par analyse du nom, avec méthodes).

## 6. Liste prioritaire des 150 exercices (démonstrations à soigner en premier)

Score = 10·ln(1 + occurrences dans le programme v33) + 6 × arbres de progression (max 2) + 4 si mouvement fondamental de difficulté ≤ 4 + 3 si réalisable sans salle + 2 si au moins 3 lieux. Seuls les exercices utilisables par le générateur sont classés.

| Rang | Exercice | Score | Justification |
| --- | --- | --- | --- |
| 1 | Scapular pull-ups (`scapular-pull-ups`) | 60.7 | 52 occurrence(s) dans le programme v33; étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 2 | Pompes (`pompes`) | 60.12 | 49 occurrence(s) dans le programme v33; étape de 3 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 3 | Traction pronation (`traction-pronation`) | 54.38 | 41 occurrence(s) dans le programme v33; étape de 3 arbre(s) de progression; réalisable sans salle |
| 4 | Muscle-up lesté (`muscle-up-leste`) | 49.07 | 44 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 5 | Hollow body hold (`hollow-body-hold`) | 49.01 | 29 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 6 | Dips (`dips`) | 48.14 | 40 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 7 | Dips lestés (`dips-lestes`) | 48.14 | 40 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 8 | Back squat (`back-squat`) | 48.07 | 44 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 9 | Travail poignet excentrique (haltère) (`travail-poignet-excentrique-haltere`) | 47.96 | 120 occurrence(s) dans le programme v33 |
| 10 | Face pulls (`face-pulls`) | 47.94 | 80 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 11 | Rotations externes (par haltère) (`rotations-externes-par-haltere`) | 46.82 | 107 occurrence(s) dans le programme v33 |
| 12 | Mobilité épaules + poignets (`mobilite-epaules-poignets`) | 46.74 | 64 occurrence(s) dans le programme v33; réalisable sans salle |
| 13 | Pompes lestées (`pompes-lestees`) | 46.55 | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 14 | Traction lestée (`traction-lestee`) | 46.55 | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 15 | Tractions explosives poitrine-barre (`tractions-explosives-poitrine-barre`) | 46.55 | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 16 | Soulevé de terre roumain (`souleve-de-terre-roumain`) | 45.55 | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 17 | Négatifs de muscle-up (`negatifs-de-muscle-up`) | 44.67 | 28 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 18 | Dead-hang lesté ou PdC (`dead-hang-leste-ou-pdc`) | 44.55 | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible; réalisable sans salle |
| 19 | Transitions de muscle-up à l'élastique (`transitions-de-muscle-up-a-l-elastique`) | 43.58 | 25 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 20 | Élévations latérales (`elevations-laterales`) | 43.57 | 77 occurrence(s) dans le programme v33 |
| 21 | Hip thrust (`hip-thrust`) | 42.96 | 26 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 22 | Rowing barre penché (`rowing-barre-penche`) | 42.5 | 46 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 23 | Ab wheel (`ab-wheel`) | 41.55 | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression |
| 24 | Extension triceps poulie corde (`extension-triceps-poulie-corde`) | 41.11 | 60 occurrence(s) dans le programme v33 |
| 25 | Leg raises lestés (suspendu) (`leg-raises-lestes-suspendu`) | 40.55 | 34 occurrence(s) dans le programme v33; réalisable sans salle |
| 26 | Développé militaire debout (`developpe-militaire-debout`) | 39.55 | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 27 | Rowing unilatéral haltère (`rowing-unilateral-haltere`) | 39.55 | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 28 | Pallof press (`pallof-press`) | 38.01 | 29 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 29 | Excentriques de transition LESTÉS (`excentriques-de-transition-lestes`) | 37.58 | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 30 | False grip hold (anneaux ou barre) (`false-grip-hold-anneaux-ou-barre`) | 37.58 | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 31 | Isométrie bas de dip (`isometrie-bas-de-dip`) | 37.58 | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 32 | Isométrie de transition muscle-up (`isometrie-de-transition-muscle-up`) | 37.58 | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 33 | Muscle-up (`muscle-up`) | 37.58 | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 34 | Développé couché (`developpe-couche`) | 36.96 | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 35 | Fentes marchées haltères (`fentes-marchees-halteres`) | 36.96 | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 36 | Tirage horizontal poulie (`tirage-horizontal-poulie`) | 36.96 | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 37 | Tirage vertical prise neutre (`tirage-vertical-prise-neutre`) | 36.96 | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 38 | Curl barre EZ (`curl-barre-ez`) | 35.55 | 34 occurrence(s) dans le programme v33 |
| 39 | Curl marteau (`curl-marteau`) | 35.55 | 34 occurrence(s) dans le programme v33 |
| 40 | Leg curl (`leg-curl`) | 35.55 | 34 occurrence(s) dans le programme v33 |
| 41 | Squat endurance @ 70 kg (`squat-endurance-70-kg`) | 35.26 | 33 occurrence(s) dans le programme v33 |
| 42 | Mollets debout (`mollets-debout`) | 32.96 | 26 occurrence(s) dans le programme v33 |
| 43 | YTW à plat ventre (banc incliné) (`ytw-a-plat-ventre-banc-incline`) | 32.96 | 26 occurrence(s) dans le programme v33 |
| 44 | Squat pause (`squat-pause`) | 21.97 | 8 occurrence(s) dans le programme v33 |
| 45 | Dips à résistance accommodante (élastique depuis le sol) (`dips-a-resistance-accommodante-elastique-depuis-le-sol`) | 21.09 | 4 occurrence(s) dans le programme v33; réalisable sans salle |
| 46 | Dead-hang (`dead-hang`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 47 | Pike push-ups (`pike-push-ups`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 48 | Planche de gainage sur les coudes (`planche-gainage`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 49 | Planche latérale (`planche-laterale`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 50 | Squat au poids de corps (`squat-au-poids-de-corps`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 51 | Support hold aux barres (`support-hold-aux-barres`) | 21.0 | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 52 | Mobilité complète (`mobilite-complete`) | 18.86 | 3 occurrence(s) dans le programme v33; réalisable sans salle |
| 53 | Fentes bulgares (`fentes-bulgares`) | 17.0 | étape de 2 arbre(s) de progression; réalisable sans salle |
| 54 | German hang (tenue) (`german-hang-tenue`) | 17.0 | étape de 2 arbre(s) de progression; réalisable sans salle |
| 55 | Squat profond tenu (`squat-profond-tenu`) | 17.0 | étape de 2 arbre(s) de progression; réalisable sans salle |
| 56 | Traction poitrine-barre (`traction-poitrine-barre`) | 17.0 | étape de 2 arbre(s) de progression; réalisable sans salle |
| 57 | ATR dos au mur (tenue) (`atr-dos-au-mur-tenue`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 58 | Australian pull-ups (rows barre basse) (`australian-pull-ups-rows-barre-basse`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 59 | Body saw (sliders) (`body-saw-sliders`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 60 | Charnière de hanche au bâton (`charniere-de-hanche-au-baton`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 61 | Dead bug (`dead-bug`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 62 | Dips assistés élastique (`dips-assistes-elastique`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 63 | Dips négatifs (`dips-negatifs`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 64 | Dips sur banc genoux fléchis (`dips-sur-banc-genoux-flechis`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 65 | Dips sur banc (triceps) (`dips-sur-banc-triceps`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 66 | Fente statique (split squat) (`fente-statique-split-squat`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 67 | Hollow body groupé (`hollow-body-groupe`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 68 | Hollow rocks (`hollow-rocks`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 69 | L-sit tuck (tenue) (`l-sit-tuck-tenue`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 70 | L-sit une jambe (`l-sit-une-jambe`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 71 | Pike hold (V inversé) (`pike-hold-v-inverse`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 72 | Planche bras tendus + taps (`planche-bras-tendus-taps`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 73 | Planche latérale sur les genoux (`planche-laterale-sur-les-genoux`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 74 | Planche lean (`planche-lean`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 75 | Planche RKC (coudes) (`planche-rkc-coudes`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 76 | Planche sur les genoux (`planche-sur-les-genoux`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 77 | Pompes à genoux (`pompes-a-genoux`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 78 | Pompes au mur (`pompes-au-mur`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 79 | Pompes inclinées (mains surélevées) (`pompes-inclinees-mains-surelevees`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 80 | Pont fessier au sol (`pont-fessier-au-sol`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 81 | Pont fessier une jambe (`pont-fessier-une-jambe`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 82 | Rowing australien barre haute (`rowing-australien-barre-haute`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 83 | Squat assisté (appui) (`squat-assiste-appui`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 84 | Squat cosaque (`squat-cosaque`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 85 | Squat sur chaise (`squat-sur-chaise`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 86 | Suspension passive pieds au sol (`suspension-passive-pieds-au-sol`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 87 | Traction assistée élastique (`traction-assistee-elastique`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 88 | Traction négative lente (`traction-negative-lente`) | 15.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 89 | ATR (équilibre) (`atr-equilibre`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 90 | ATR poitrine au mur (tenue) (`atr-poitrine-au-mur-tenue`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 91 | Back lever advanced tuck (`back-lever-advanced-tuck`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 92 | Back lever complet (`back-lever-complet`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 93 | Back lever straddle (`back-lever-straddle`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 94 | Back lever tuck (`back-lever-tuck`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 95 | Bridge (pont dorsal) (`bridge-pont-dorsal`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 96 | Cercles de bras (`cercles-de-bras`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 97 | Copenhagen plank (`copenhagen-plank`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 98 | Dislocations épaules bâton (`dislocations-epaules-baton`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 99 | Dislocations épaules élastique (`dislocations-epaules-elastique`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 100 | Étirements fléchisseurs de hanche (`etirements-flechisseurs-de-hanche`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 101 | Fente basse étirement (hanche) (`fente-basse-etirement-hanche`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 102 | Front lever advanced tuck (`front-lever-advanced-tuck`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 103 | Front lever complet (`front-lever-complet`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 104 | Front lever one leg (`front-lever-one-leg`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 105 | Front lever straddle (`front-lever-straddle`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 106 | Front lever tuck (`front-lever-tuck`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 107 | Handstand push-ups (mur) (`handstand-push-ups-mur`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 108 | Handstand walk (marche en ATR) (`handstand-walk-marche-en-atr`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 109 | HSPU freestanding (progression) (`hspu-freestanding-progression`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 110 | HSPU stricts en déficit (`hspu-stricts-en-deficit`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 111 | L-sit (`l-sit`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 112 | Manna progression (`manna-progression`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 113 | Mobilisation cheville genou au mur (`mobilisation-cheville-genou-au-mur`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 114 | Mobilité hanches (90/90) (`mobilite-hanches-90-90`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 115 | Mollets unilatéraux sur marche (`mollets-unilateraux-sur-marche`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 116 | Muscle-up kipping (`muscle-up-kipping`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 117 | Muscle-up strict (`muscle-up-strict`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 118 | Pike push-ups surélevés (pieds sur banc) (`pike-push-ups-sureleves-pieds-sur-banc`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 119 | Pistol squat (`pistol-squat`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 120 | Pistol squat assisté (`pistol-squat-assiste`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 121 | Pistol squat sur box (`pistol-squat-sur-box`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 122 | Planche advanced tuck (`planche-advanced-tuck`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 123 | Planche complète (`planche-complete`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 124 | Planche straddle (`planche-straddle`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 125 | Pompe à un bras (`pompe-a-un-bras`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 126 | Pompes archer (`pompes-archer`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 127 | Pompes diamant (`pompes-diamant`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 128 | Pompes diamant surélevées (`pompes-diamant-surelevees`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 129 | Pompes pseudo-planche (`pompes-pseudo-planche`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 130 | Pompes une main (progression) (`pompes-une-main-progression`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 131 | Pseudo-planche hold (`pseudo-planche-hold`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 132 | Shoulder taps en ATR (`shoulder-taps-en-atr`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 133 | Shrimp squat (`shrimp-squat`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 134 | Skater squat (`skater-squat`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 135 | Traction archer (`traction-archer`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 136 | Traction une main (assistée) (`traction-une-main-assistee`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 137 | Traction une main (négative) (`traction-une-main-negative`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 138 | Tuck planche (`tuck-planche`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 139 | V-sit progression (`v-sit-progression`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 140 | V-sit (tenue) (`v-sit-tenue`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 141 | Wall slides (glissés au mur) (`wall-slides-glisses-au-mur`) | 11.0 | étape de 1 arbre(s) de progression; réalisable sans salle |
| 142 | Ab wheel à genoux (amplitude courte) (`ab-wheel-a-genoux-amplitude-courte`) | 10.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 143 | Box squat (`box-squat`) | 10.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 144 | Soulevé de terre roumain haltères (`souleve-de-terre-roumain-halteres`) | 10.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 145 | Squat gobelet (`squat-gobelet`) | 10.0 | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 146 | Arch rocks (`arch-rocks`) | 9.0 | mouvement fondamental accessible; réalisable sans salle |
| 147 | Bear crawl (`bear-crawl`) | 9.0 | mouvement fondamental accessible; réalisable sans salle |
| 148 | Bicycle crunchs (`bicycle-crunchs`) | 9.0 | mouvement fondamental accessible; réalisable sans salle |
| 149 | Bird dog (`bird-dog`) | 9.0 | mouvement fondamental accessible; réalisable sans salle |
| 150 | Box jumps (`box-jumps`) | 9.0 | mouvement fondamental accessible; réalisable sans salle |
