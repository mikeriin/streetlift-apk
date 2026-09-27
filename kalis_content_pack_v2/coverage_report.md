# Rapport de couverture et de validation — pack de contenu Kalis Track v2 (L9R)

Généré par `tools/validate.py`. Statistiques calculées sur `exercises_v2.json`, `poses.json`, `muscles.json`, `atlas.svg`.

## 1. Synthèse

- Exercices dans le pack : **625** (505 issus de la base v1, 50 ajoutés en L9, 70 ajoutés en L9R pour la couverture).
- Utilisables par le générateur : **575** ; doublons signalés : 22 ; tests : 19 ; hors générateur : 9.
- Sources : 3499 références au total ; exercices avec ≥ 2 sources concordantes pour les muscles : 625 / 625.
- Chaînes de progression : 24 ; entrées « débutant complet » : 12.
- Gabarits de pose : 246 ; démonstrations : 573 disponibles, 34 statiques (position de départ seulement), 18 indisponibles.

## 2. Contrôles automatiques

| Contrôle | Résultat |
| --- | --- |
| schema | OK |
| taxonomie | OK |
| atlas | OK |
| sources | OK |
| graphe | OK |
| poses | OK |
| statuts | OK |
| correspondance | OK |
| prerequis | OK |
| substitutions | OK |

### Avertissements : prérequis (non bloquants)

Exercices de difficulté ≥ 7 sans prérequis explicite (le générateur doit les réserver aux profils avancés) :

`archer-rows-anneaux`, `around-the-world-suspendu`, `burpees-navy-seal`, `butterfly-pull-ups`, `chest-to-bar-kipping`, `clean-et-jerk`, `descente-en-pont-le-long-du-mur`, `dips-aux-anneaux`, `dips-aux-anneaux-rto-tournes`, `dips-coreens`, `dragon-flag-negatif-support-au-sol`, `dragon-flag-support-au-sol`, `extension-triceps-au-poids-de-corps-pieds-sureleves`, `fentes-bulgares-sautees`, `foulees-bondissantes-bounding`, `front-lever-negatif`, `front-lever-pull-ups-tuck`, `front-lever-raises`, `hspu-kipping`, `ice-cream-makers`, `isometrie-de-transition-muscle-up`, `kettlebell-snatch`, `man-makers`, `muscle-up`, `muscle-up-aux-anneaux`, `muscle-up-aux-anneaux-strict`, `nordic-curl-excentrique`, `overhead-carry-barre`, `pancake-a-plat-poitrine-au-sol`, `pistol-squat-saute`, `planche-a-levier-long-mains-avancees`, `planche-a-un-bras`, `planche-bras-et-jambe-opposes-tenue`, `planche-laterale-etoile`, `planche-superman-tenue`, `pompes-pliometriques-mains-sur-boxes`, `pompes-typewriter`, `pont-dorsal-une-jambe`, `power-clean`, `press-to-handstand-pike-press`, `push-jerk`, `rollout-barre`, `rowing-inverse-a-un-bras-barre-basse`, `rowing-inverse-a-un-bras-sous-table`, `russian-dips`, `sauts-en-contrebas-depth-jumps`, `shrimp-squat-avance-pied-tenu-a-deux-mains`, `snatch-arrache`, `squat-overhead`, `tirage-bucheron-a-la-barre-fixe`, `toes-to-bar-strict`, `traction-a-la-serviette`, `traction-autour-du-monde`, `traction-explosive`, `traction-haute-explosive-high-pull-up`, `traction-l-sit`, `traction-sternum`, `traction-typewriter`, `tuck-jump-burpees`, `windshield-wipers-essuie-glaces`

## 3. Matrice de couverture pour le générateur

Nombre d'exercices utilisables par type de mouvement, lieu et tranche de difficulté (seuil : 3). Une case en **gras** signale un manque.

| Type | Maison sans matériel 1-3 | Maison sans matériel 4-6 | Maison sans matériel 7-10 | Maison équipée 1-3 | Maison équipée 4-6 | Maison équipée 7-10 | Parc de street workout 1-3 | Parc de street workout 4-6 | Parc de street workout 7-10 | Salle 1-3 | Salle 4-6 | Salle 7-10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Poussée horizontale | 8 | 9 | 3 | 10 | 14 | 4 | 8 | 14 | 4 | 13 | 17 | 4 |
| Poussée verticale | 3 | 3 | 3 | 8 | 18 | 11 | 6 | 15 | 11 | 9 | 22 | 12 |
| Tirage horizontal | 3 | 3 | **1** | 15 | 6 | 4 | 10 | 5 | 4 | 18 | 10 | 4 |
| Tirage vertical | **1** | **0** | **0** | 6 | 18 | 17 | 4 | 18 | 16 | 11 | 18 | 17 |
| Squat | 4 | 6 | 4 | 7 | 8 | 5 | 5 | 8 | 4 | 9 | 17 | 6 |
| Charnière de hanche | 4 | 3 | **0** | 6 | 8 | 3 | 3 | 4 | **1** | 9 | 15 | 5 |
| Fente | 7 | 4 | **1** | 8 | 8 | 5 | 7 | 7 | 3 | 8 | 8 | 5 |
| Gainage anti-extension | 11 | 3 | 5 | 11 | 6 | 9 | 11 | 3 | 4 | 11 | 7 | 10 |
| Gainage anti-rotation | 6 | 4 | **2** | 8 | 4 | 4 | 6 | 4 | 4 | 10 | 5 | 4 |
| Gainage anti-flexion latérale | 3 | 3 | **2** | 4 | 4 | 3 | 3 | 3 | 3 | 4 | 5 | 3 |
| Portés | **0** | **0** | **0** | 7 | 5 | **2** | 3 | 3 | **1** | 9 | 6 | 4 |
| Locomotion | 5 | 7 | 3 | 7 | 7 | 4 | 7 | 7 | 4 | 8 | 7 | 4 |
| Mobilité | 15 | 3 | 3 | 17 | 4 | 3 | 15 | 4 | 3 | 17 | 4 | 3 |
| Figure statique | 3 | 6 | 5 | 11 | 21 | 16 | 11 | 21 | 19 | 11 | 22 | 19 |
| Figure dynamique | **2** | **2** | **1** | **2** | 11 | 16 | **2** | 8 | 15 | **2** | 12 | 19 |
| Conditionnement | 6 | 4 | **2** | 10 | 13 | 6 | 9 | 10 | 4 | 14 | 21 | 6 |
| Isolation (mono-articulaire) | 4 | 4 | 3 | 36 | 5 | 4 | 11 | 3 | 4 | 61 | 6 | 4 |
| Flexion du tronc | 5 | 3 | **0** | 6 | 8 | 3 | 6 | 7 | 3 | 8 | 9 | 3 |

### Manques restants (22 cases sous le seuil)

Règle L9R : au moins 3 exercices par case dès qu'un exercice réel existe. Les cases ci-dessous n'ont pas été comblées par des variantes artificielles ; la justification est donnée pour chacune (décision D-L9R-08).

| Type | Lieu | Difficulté | Nombre | Justification |
| --- | --- | --- | --- | --- |
| Tirage horizontal | Maison sans matériel | 7-10 | 1 | sans barre ni anneaux, seul le rowing inversé à un bras sous une table atteint le niveau 7. |
| Tirage vertical | Maison sans matériel | 1-3 | 1 | un tirage vertical exige un point d'accroche au-dessus de la tête (barre, anneaux, élastique) ; les tractions sur un haut de porte sont exclues pour des raisons de sécurité. |
| Tirage vertical | Maison sans matériel | 4-6 | 0 | un tirage vertical exige un point d'accroche au-dessus de la tête (barre, anneaux, élastique) ; les tractions sur un haut de porte sont exclues pour des raisons de sécurité. |
| Tirage vertical | Maison sans matériel | 7-10 | 0 | un tirage vertical exige un point d'accroche au-dessus de la tête (barre, anneaux, élastique) ; les tractions sur un haut de porte sont exclues pour des raisons de sécurité. |
| Charnière de hanche | Maison sans matériel | 7-10 | 0 | au-delà du soulevé de terre unijambe au poids de corps, une charnière de niveau 7+ exige une charge ; le curl nordique est classé en isolation. |
| Charnière de hanche | Parc de street workout | 7-10 | 1 | niveau 7+ : hip thrust unijambe lesté ; le reste exige une charge lourde. |
| Fente | Maison sans matériel | 7-10 | 1 | au poids de corps, seules les fentes bulgares sautées atteignent le niveau 7 ; les autres variantes lourdes exigent une charge. |
| Gainage anti-rotation | Maison sans matériel | 7-10 | 2 | les gainages anti-rotation de niveau 7+ sans matériel se limitent à la planche à un bras et à la planche bras-jambe opposés. |
| Gainage anti-flexion latérale | Maison sans matériel | 7-10 | 2 | niveau 7+ sans matériel : planche latérale étoile et Copenhague à levier long ; le drapeau est une figure statique. |
| Portés | Maison sans matériel | 1-3 | 0 | un porté exige une charge à porter ; un sac chargé relève du matériel « sac lesté » (maison équipée, parc, salle). |
| Portés | Maison sans matériel | 4-6 | 0 | un porté exige une charge à porter ; un sac chargé relève du matériel « sac lesté » (maison équipée, parc, salle). |
| Portés | Maison sans matériel | 7-10 | 0 | un porté exige une charge à porter ; un sac chargé relève du matériel « sac lesté » (maison équipée, parc, salle). |
| Portés | Maison équipée | 7-10 | 2 | niveau 7+ : porté de sac lourd et farmer walk haltères lourds. |
| Portés | Parc de street workout | 7-10 | 1 | les portés au parc reposent sur le sac lesté (suitcase, bear hug, zercher, overhead, farmer). |
| Figure dynamique | Maison sans matériel | 1-3 | 2 | les figures dynamiques de niveau 1-3 sans matériel se limitent au kick-up et aux wall walks partiels ; les roulades, sans source musculaire concordante, ne sont pas ajoutées (règle des deux sources). |
| Figure dynamique | Maison sans matériel | 4-6 | 2 | les figures dynamiques de niveau 1-3 sans matériel se limitent au kick-up et aux wall walks partiels ; les roulades, sans source musculaire concordante, ne sont pas ajoutées (règle des deux sources). |
| Figure dynamique | Maison sans matériel | 7-10 | 1 | les figures dynamiques de niveau 1-3 sans matériel se limitent au kick-up et aux wall walks partiels ; les roulades, sans source musculaire concordante, ne sont pas ajoutées (règle des deux sources). |
| Figure dynamique | Maison équipée | 1-3 | 2 | voir maison sans matériel : les figures dynamiques faciles se font au mur. |
| Figure dynamique | Parc de street workout | 1-3 | 2 | voir maison sans matériel. |
| Figure dynamique | Salle | 1-3 | 2 | voir maison sans matériel. |
| Conditionnement | Maison sans matériel | 7-10 | 2 | sans matériel, seuls les burpees avancés atteignent le niveau 7 ; les sprints répétés sont classés en locomotion. |
| Flexion du tronc | Maison sans matériel | 7-10 | 0 | les flexions du tronc de niveau 7+ exigent une suspension (barre) ou un lest ; le dragon flag est classé en gainage anti-extension. |

## 4. Substitutions

Substitutions calculées : même type de mouvement, difficulté ±1, par lieu (3 au plus, classées par écart de difficulté puis muscles primaires communs). Exercices du générateur sans substitution dans un de leurs lieux compatibles : **0**.

## 5. Correspondances

- Base v1 : 505 noms rattachés sur 505.
- Programme de 40 semaines : 79 intitulés distincts rattachés (44 exacts, 35 par analyse du nom, avec méthodes).

## 6. Liste prioritaire des 150 exercices (démonstrations contrôlées visuellement en premier)

Score = 10·ln(1 + occurrences dans le programme v33) + 6 × arbres de progression (max 2) + 4 si mouvement fondamental de difficulté ≤ 4 + 3 si réalisable sans salle + 2 si au moins 3 lieux. Seuls les exercices utilisables par le générateur sont classés. Les planches de contrôle correspondantes sont dans `planches/prioritaires_XX.png`.

| Rang | Exercice | Score | Statut démo | Justification |
| --- | --- | --- | --- | --- |
| 1 | Scapular pull-ups (`scapular-pull-ups`) | 60.7 | disponible | 52 occurrence(s) dans le programme v33; étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 2 | Pompes (`pompes`) | 60.12 | disponible | 49 occurrence(s) dans le programme v33; étape de 3 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 3 | Traction pronation (`traction-pronation`) | 54.38 | disponible | 41 occurrence(s) dans le programme v33; étape de 3 arbre(s) de progression; réalisable sans salle |
| 4 | Muscle-up lesté (`muscle-up-leste`) | 49.07 | disponible | 44 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 5 | Hollow body hold (`hollow-body-hold`) | 49.01 | disponible | 29 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 6 | Dips (`dips`) | 48.14 | disponible | 40 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 7 | Dips lestés (`dips-lestes`) | 48.14 | disponible | 40 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 8 | Back squat (`back-squat`) | 48.07 | disponible | 44 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 9 | Travail poignet excentrique (haltère) (`travail-poignet-excentrique-haltere`) | 47.96 | disponible | 120 occurrence(s) dans le programme v33 |
| 10 | Face pulls (`face-pulls`) | 47.94 | disponible | 80 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 11 | Rotations externes (par haltère) (`rotations-externes-par-haltere`) | 46.82 | statique | 107 occurrence(s) dans le programme v33 |
| 12 | Mobilité épaules + poignets (`mobilite-epaules-poignets`) | 46.74 | disponible | 64 occurrence(s) dans le programme v33; réalisable sans salle |
| 13 | Pompes lestées (`pompes-lestees`) | 46.55 | disponible | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 14 | Traction lestée (`traction-lestee`) | 46.55 | disponible | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 15 | Tractions explosives poitrine-barre (`tractions-explosives-poitrine-barre`) | 46.55 | disponible | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 16 | Soulevé de terre roumain (`souleve-de-terre-roumain`) | 45.55 | disponible | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 17 | Négatifs de muscle-up (`negatifs-de-muscle-up`) | 44.67 | disponible | 28 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 18 | Dead-hang lesté ou PdC (`dead-hang-leste-ou-pdc`) | 44.55 | disponible | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible; réalisable sans salle |
| 19 | Transitions de muscle-up à l'élastique (`transitions-de-muscle-up-a-l-elastique`) | 43.58 | disponible | 25 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; réalisable sans salle |
| 20 | Élévations latérales (`elevations-laterales`) | 43.57 | disponible | 77 occurrence(s) dans le programme v33 |
| 21 | Hip thrust (`hip-thrust`) | 42.96 | disponible | 26 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 22 | Rowing barre penché (`rowing-barre-penche`) | 42.5 | disponible | 46 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 23 | Ab wheel (`ab-wheel`) | 41.55 | disponible | 34 occurrence(s) dans le programme v33; étape de 1 arbre(s) de progression |
| 24 | Extension triceps poulie corde (`extension-triceps-poulie-corde`) | 41.11 | disponible | 60 occurrence(s) dans le programme v33 |
| 25 | Leg raises lestés (suspendu) (`leg-raises-lestes-suspendu`) | 40.55 | disponible | 34 occurrence(s) dans le programme v33; réalisable sans salle |
| 26 | Développé militaire debout (`developpe-militaire-debout`) | 39.55 | disponible | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 27 | Rowing unilatéral haltère (`rowing-unilateral-haltere`) | 39.55 | disponible | 34 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 28 | Pallof press (`pallof-press`) | 38.01 | disponible | 29 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 29 | Excentriques de transition LESTÉS (`excentriques-de-transition-lestes`) | 37.58 | disponible | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 30 | False grip hold (anneaux ou barre) (`false-grip-hold-anneaux-ou-barre`) | 37.58 | disponible | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 31 | Isométrie bas de dip (`isometrie-bas-de-dip`) | 37.58 | disponible | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 32 | Isométrie de transition muscle-up (`isometrie-de-transition-muscle-up`) | 37.58 | disponible | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 33 | Muscle-up (`muscle-up`) | 37.58 | disponible | 25 occurrence(s) dans le programme v33; réalisable sans salle |
| 34 | Développé couché (`developpe-couche`) | 36.96 | disponible | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 35 | Fentes marchées haltères (`fentes-marchees-halteres`) | 36.96 | disponible | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 36 | Tirage horizontal poulie (`tirage-horizontal-poulie`) | 36.96 | disponible | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 37 | Tirage vertical prise neutre (`tirage-vertical-prise-neutre`) | 36.96 | disponible | 26 occurrence(s) dans le programme v33; mouvement fondamental accessible |
| 38 | Curl barre EZ (`curl-barre-ez`) | 35.55 | disponible | 34 occurrence(s) dans le programme v33 |
| 39 | Curl marteau (`curl-marteau`) | 35.55 | disponible | 34 occurrence(s) dans le programme v33 |
| 40 | Leg curl (`leg-curl`) | 35.55 | disponible | 34 occurrence(s) dans le programme v33 |
| 41 | Squat endurance @ 70 kg (`squat-endurance-70-kg`) | 35.26 | disponible | 33 occurrence(s) dans le programme v33 |
| 42 | Mollets debout (`mollets-debout`) | 32.96 | disponible | 26 occurrence(s) dans le programme v33 |
| 43 | YTW à plat ventre (banc incliné) (`ytw-a-plat-ventre-banc-incline`) | 32.96 | disponible | 26 occurrence(s) dans le programme v33 |
| 44 | Squat pause (`squat-pause`) | 21.97 | disponible | 8 occurrence(s) dans le programme v33 |
| 45 | Dips à résistance accommodante (élastique depuis le sol) (`dips-a-resistance-accommodante-elastique-depuis-le-sol`) | 21.09 | disponible | 4 occurrence(s) dans le programme v33; réalisable sans salle |
| 46 | Dead-hang (`dead-hang`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 47 | Pike push-ups (`pike-push-ups`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 48 | Planche de gainage sur les coudes (`planche-gainage`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 49 | Planche latérale (`planche-laterale`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 50 | Squat au poids de corps (`squat-au-poids-de-corps`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 51 | Support hold aux barres (`support-hold-aux-barres`) | 21.0 | disponible | étape de 2 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 52 | Mobilité complète (`mobilite-complete`) | 18.86 | indisponible | 3 occurrence(s) dans le programme v33; réalisable sans salle |
| 53 | Fentes bulgares (`fentes-bulgares`) | 17.0 | disponible | étape de 2 arbre(s) de progression; réalisable sans salle |
| 54 | German hang (tenue) (`german-hang-tenue`) | 17.0 | disponible | étape de 2 arbre(s) de progression; réalisable sans salle |
| 55 | Squat profond tenu (`squat-profond-tenu`) | 17.0 | disponible | étape de 2 arbre(s) de progression; réalisable sans salle |
| 56 | Traction poitrine-barre (`traction-poitrine-barre`) | 17.0 | disponible | étape de 2 arbre(s) de progression; réalisable sans salle |
| 57 | ATR dos au mur (tenue) (`atr-dos-au-mur-tenue`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 58 | Australian pull-ups (rows barre basse) (`australian-pull-ups-rows-barre-basse`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 59 | Body saw (sliders) (`body-saw-sliders`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 60 | Charnière de hanche au bâton (`charniere-de-hanche-au-baton`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 61 | Dead bug (`dead-bug`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 62 | Dips assistés élastique (`dips-assistes-elastique`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 63 | Dips négatifs (`dips-negatifs`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 64 | Dips sur banc genoux fléchis (`dips-sur-banc-genoux-flechis`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 65 | Dips sur banc (triceps) (`dips-sur-banc-triceps`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 66 | Fente statique (split squat) (`fente-statique-split-squat`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 67 | Hollow body groupé (`hollow-body-groupe`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 68 | Hollow rocks (`hollow-rocks`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 69 | L-sit tuck (tenue) (`l-sit-tuck-tenue`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 70 | L-sit une jambe (`l-sit-une-jambe`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 71 | Pike hold (V inversé) (`pike-hold-v-inverse`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 72 | Planche bras tendus + taps (`planche-bras-tendus-taps`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 73 | Planche latérale sur les genoux (`planche-laterale-sur-les-genoux`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 74 | Planche lean (`planche-lean`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 75 | Planche RKC (coudes) (`planche-rkc-coudes`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 76 | Planche sur les genoux (`planche-sur-les-genoux`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 77 | Pompes à genoux (`pompes-a-genoux`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 78 | Pompes au mur (`pompes-au-mur`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 79 | Pompes inclinées (mains surélevées) (`pompes-inclinees-mains-surelevees`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 80 | Pont fessier au sol (`pont-fessier-au-sol`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 81 | Pont fessier une jambe (`pont-fessier-une-jambe`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 82 | Rowing australien barre haute (`rowing-australien-barre-haute`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 83 | Squat assisté (appui) (`squat-assiste-appui`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 84 | Squat cosaque (`squat-cosaque`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 85 | Squat sur chaise (`squat-sur-chaise`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 86 | Suspension passive pieds au sol (`suspension-passive-pieds-au-sol`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 87 | Traction assistée élastique (`traction-assistee-elastique`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 88 | Traction négative lente (`traction-negative-lente`) | 15.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible; réalisable sans salle |
| 89 | ATR (équilibre) (`atr-equilibre`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 90 | ATR poitrine au mur (tenue) (`atr-poitrine-au-mur-tenue`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 91 | Back lever advanced tuck (`back-lever-advanced-tuck`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 92 | Back lever complet (`back-lever-complet`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 93 | Back lever straddle (`back-lever-straddle`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 94 | Back lever tuck (`back-lever-tuck`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 95 | Bridge (pont dorsal) (`bridge-pont-dorsal`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 96 | Cercles de bras (`cercles-de-bras`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 97 | Copenhagen plank (`copenhagen-plank`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 98 | Dislocations épaules bâton (`dislocations-epaules-baton`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 99 | Dislocations épaules élastique (`dislocations-epaules-elastique`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 100 | Étirements fléchisseurs de hanche (`etirements-flechisseurs-de-hanche`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 101 | Fente basse étirement (hanche) (`fente-basse-etirement-hanche`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 102 | Front lever advanced tuck (`front-lever-advanced-tuck`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 103 | Front lever complet (`front-lever-complet`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 104 | Front lever one leg (`front-lever-one-leg`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 105 | Front lever straddle (`front-lever-straddle`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 106 | Front lever tuck (`front-lever-tuck`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 107 | Handstand push-ups (mur) (`handstand-push-ups-mur`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 108 | Handstand walk (marche en ATR) (`handstand-walk-marche-en-atr`) | 11.0 | statique | étape de 1 arbre(s) de progression; réalisable sans salle |
| 109 | HSPU freestanding (progression) (`hspu-freestanding-progression`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 110 | HSPU stricts en déficit (`hspu-stricts-en-deficit`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 111 | L-sit (`l-sit`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 112 | Manna progression (`manna-progression`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 113 | Mobilisation cheville genou au mur (`mobilisation-cheville-genou-au-mur`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 114 | Mobilité hanches (90/90) (`mobilite-hanches-90-90`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 115 | Mollets unilatéraux sur marche (`mollets-unilateraux-sur-marche`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 116 | Muscle-up kipping (`muscle-up-kipping`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 117 | Muscle-up strict (`muscle-up-strict`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 118 | Pike push-ups surélevés (pieds sur banc) (`pike-push-ups-sureleves-pieds-sur-banc`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 119 | Pistol squat (`pistol-squat`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 120 | Pistol squat assisté (`pistol-squat-assiste`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 121 | Pistol squat sur box (`pistol-squat-sur-box`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 122 | Planche advanced tuck (`planche-advanced-tuck`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 123 | Planche complète (`planche-complete`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 124 | Planche straddle (`planche-straddle`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 125 | Pompe à un bras (`pompe-a-un-bras`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 126 | Pompes archer (`pompes-archer`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 127 | Pompes diamant (`pompes-diamant`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 128 | Pompes diamant surélevées (`pompes-diamant-surelevees`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 129 | Pompes pseudo-planche (`pompes-pseudo-planche`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 130 | Pompes une main (progression) (`pompes-une-main-progression`) | 11.0 | indisponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 131 | Pseudo-planche hold (`pseudo-planche-hold`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 132 | Shoulder taps en ATR (`shoulder-taps-en-atr`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 133 | Shrimp squat (`shrimp-squat`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 134 | Skater squat (`skater-squat`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 135 | Traction archer (`traction-archer`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 136 | Traction une main (assistée) (`traction-une-main-assistee`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 137 | Traction une main (négative) (`traction-une-main-negative`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 138 | Tuck planche (`tuck-planche`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 139 | V-sit progression (`v-sit-progression`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 140 | V-sit (tenue) (`v-sit-tenue`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 141 | Wall slides (glissés au mur) (`wall-slides-glisses-au-mur`) | 11.0 | disponible | étape de 1 arbre(s) de progression; réalisable sans salle |
| 142 | Ab wheel à genoux (amplitude courte) (`ab-wheel-a-genoux-amplitude-courte`) | 10.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 143 | Box squat (`box-squat`) | 10.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 144 | Soulevé de terre roumain haltères (`souleve-de-terre-roumain-halteres`) | 10.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 145 | Squat gobelet (`squat-gobelet`) | 10.0 | disponible | étape de 1 arbre(s) de progression; mouvement fondamental accessible |
| 146 | Arch rocks (`arch-rocks`) | 9.0 | disponible | mouvement fondamental accessible; réalisable sans salle |
| 147 | Bear crawl (`bear-crawl`) | 9.0 | disponible | mouvement fondamental accessible; réalisable sans salle |
| 148 | Bear hug carry sac lesté (`bear-hug-carry-sac-leste`) | 9.0 | statique | mouvement fondamental accessible; réalisable sans salle |
| 149 | Bicycle crunchs (`bicycle-crunchs`) | 9.0 | disponible | mouvement fondamental accessible; réalisable sans salle |
| 150 | Bird dog (`bird-dog`) | 9.0 | disponible | mouvement fondamental accessible; réalisable sans salle |
