# Mesure de départ — moteurs 0.1 (lot CR)

État du 03/10/2026. Moteurs mesurés : `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0, sur `kalis_core` 0.4.0 (catalogue 1.1.0). Banc : `kalis_bench` 0.1.0, mode `croisement`, graine 0, 27 profils types (17 street, 10 autres disciplines, `docs/PROFILS.md`).

Ce document est la feuille de route des lots CP1, CA1, CP2 et CA2 : il dit où en sont les moteurs avant tout calibrage, et dans quel ordre corriger.

## 1. Ce qui a été mesuré, et comment

1. **Critères calculables** (`docs/CRITERES.md`) : sécurité (toute violation compte, la cible est zéro), qualité (0 à 1), attentes de coach propres à chaque profil, trajectoires simulées avec `kalis_adapt`. Chiffres tirés du rapport du contrôle automatique (`ci-out/packages/kalis_bench/rapport.json` sur `claude/ci-cp-a`), reproductibles par `dart run bin/run.dart`.
2. **Panel** (`docs/PANEL.md`) : une passe complète, quatre écoles × 27 profils, soit 108 notes d'ensemble. Chaque relecteur reçoit le profil, le programme créé et le résumé de la trajectoire simulée, avec la grille gelée de son école et le référentiel ; il ne voit ni le code, ni les autres notes, ni les programmes de référence. L'étalonnage (`docs/ETALONNAGE_PANEL.md`) borne la lecture des notes : un écart d'un point entre deux passes n'est pas significatif.

Limites de la mesure : §6.

## 2. Synthèse

- **Panel.** Moyenne 4,9/10 ; note la plus basse 3,0/10 ; note la plus haute 7,0/10 ; street 4,9, autres disciplines 5,1. Aucun des 27 programmes n'atteint 9/10 pour une seule école ; 29 notes sur 108 sont à 6 ou plus. Le seuil du calibrage est 9/10 pour chaque école et chaque profil : l'écart à combler est de 2 à 6 points selon les profils.
- **Sécurité.** 117 violations sur les programmes créés (167 sur les programmes après adaptation simulée). 4 profils sur 27 sans violation : `street_13_peu_de_temps`, `autres_07_mobilite_sante_senior`, `autres_09_perte_de_poids_debutante`, `autres_10_contraintes_multiples`.
- **Attentes de coach.** 113 attentes tenues sur 166 (68 %).
- **Trajectoires.** Écart moyen au RIR visé : 2,05 répétition (de 1,20 à 3,58, hors course) ; 26 trajectoires sur 27 hors du repère d'écart au RIR. Avec une échéance, la performance simulée le jour J reste sous le meilleur niveau antérieur pour quatre profils sur cinq testés.

Les moteurs 0.1 produisent des programmes structurés, équilibrés entre poussée et tirage, faisables dans le temps donné pour la plupart, et prudents sur l'effort. Ils ne tiennent pas compte de l'échéance, sous-dosent l'intensité des pratiquants avancés, travaillent trop peu les mouvements visés, ne savent pas faire progresser un débutant vers sa première traction ni un pratiquant vers une figure, et ne modélisent presque pas la course.

## 3. Panel : notes d'ensemble, école × profil

| Profil | Niveau | Force | Calisthénie | Hypertrophie | Santé | Moyenne | Plus basse |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | débutant | 5,5 | 6,0 | 6,0 | 6,5 | 6,0 | **5,5** |
| `street_02_debutant_surpoids` | débutant | 7,0 | 7,0 | 7,0 | 5,0 | 6,5 | **5,0** |
| `street_03_debutante` | débutant | 4,5 | 5,0 | 4,5 | 5,0 | 4,8 | **4,5** |
| `street_04_reprise_longue_pause` | intermédiaire | 6,5 | 5,0 | 7,0 | 5,0 | 5,9 | **5,0** |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 4,0 | 5,0 | 5,0 | 4,5 | 4,6 | **4,0** |
| `street_06_inter_sets_reps` | intermédiaire | 4,5 | 5,0 | 7,0 | 4,0 | 5,1 | **4,0** |
| `street_07_avance_streetlifting_competition` | avancé | 3,5 | 4,0 | 4,5 | 4,0 | 4,0 | **3,5** |
| `street_08_avance_sets_reps_competition` | avancé | 4,5 | 3,5 | 5,5 | 4,0 | 4,4 | **3,5** |
| `street_09_elite_streetlifting` | élite | 4,0 | 5,0 | 6,0 | 4,0 | 4,8 | **4,0** |
| `street_10_elite_figures` | élite | 5,0 | 4,0 | 6,0 | 4,0 | 4,8 | **4,0** |
| `street_11_master_51_ans` | intermédiaire | 4,0 | 4,5 | 4,5 | 4,0 | 4,2 | **4,0** |
| `street_12_antecedent_coude` | intermédiaire | 4,0 | 3,5 | 4,0 | 4,0 | 3,9 | **3,5** |
| `street_13_peu_de_temps` | intermédiaire | 6,5 | 6,0 | 5,5 | 6,0 | 6,0 | **5,5** |
| `street_14_parc_sans_lest` | intermédiaire | 4,5 | 4,5 | 5,0 | 4,0 | 4,5 | **4,0** |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 4,0 | 3,5 | 6,0 | 4,5 | 4,5 | **3,5** |
| `street_16_specialisation_traction_lestee` | avancé | 3,0 | 3,0 | 5,0 | 3,0 | 3,5 | **3,0** |
| `street_17_hybride_street_course` | intermédiaire | 5,0 | 5,0 | 6,0 | 5,0 | 5,2 | **5,0** |
| `autres_01_debutant_musculation` | débutant | 6,5 | 6,5 | 7,0 | 7,0 | 6,8 | **6,5** |
| `autres_02_hypertrophie_intermediaire` | intermédiaire | 6,0 | 7,0 | 7,0 | 6,0 | 6,5 | **6,0** |
| `autres_03_powerlifter_competition` | avancé | 3,0 | 4,0 | 4,5 | 3,5 | 3,8 | **3,0** |
| `autres_04_force_generale_46_ans` | intermédiaire | 3,5 | 4,0 | 6,0 | 5,0 | 4,6 | **3,5** |
| `autres_05_course_10_km_debutante` | débutant | 4,0 | 4,0 | 4,5 | 4,0 | 4,1 | **4,0** |
| `autres_06_semi_marathon_intermediaire` | intermédiaire | 3,0 | 3,0 | 4,5 | 3,0 | 3,4 | **3,0** |
| `autres_07_mobilite_sante_senior` | débutant | 5,5 | 5,5 | 5,0 | 5,0 | 5,2 | **5,0** |
| `autres_08_crossfit_intermediaire` | intermédiaire | 5,0 | 4,5 | 6,5 | 5,0 | 5,2 | **4,5** |
| `autres_09_perte_de_poids_debutante` | débutant | 5,0 | 7,0 | 6,0 | 5,0 | 5,8 | **5,0** |
| `autres_10_contraintes_multiples` | débutant | 5,0 | 5,0 | 5,0 | 7,0 | 5,5 | **5,0** |
| **Moyenne** | | 4,7 | 4,8 | 5,6 | 4,7 | 4,9 | **3,0** |

### Notes par critère (moyenne sur les programmes où le critère s'applique)

| Critère | Moyenne | Plus basse | Programmes notés |
| --- | --- | --- | --- |
| F1 — Spécificité et fréquence | 5,0 | 2,5 | 27 |
| F2 — Intensité | 4,7 | 3,0 | 27 |
| F3 — Volume de force | 5,2 | 3,0 | 26 |
| F4 — Périodisation et progression | 4,5 | 3,0 | 27 |
| F5 — Affûtage, pic et tests | 3,0 | 1,0 | 20 |
| F6 — Techniques d'intensification | 6,0 | 3,5 | 12 |
| F7 — Assistance, points faibles, équilibre | 5,0 | 3,0 | 27 |
| F8 — Sécurité et tolérance | 5,4 | 3,0 | 27 |
| F9 — Faisabilité et clarté | 6,0 | 4,0 | 27 |
| C1 — Choix des figures, variantes et paliers | 4,8 | 3,0 | 26 |
| C2 — Pratique motrice | 5,8 | 4,0 | 18 |
| C3 — Dosage des maintiens | 5,7 | 4,0 | 25 |
| C4 — Charge tendineuse | 5,5 | 2,5 | 20 |
| C5 — Force de base | 5,4 | 3,0 | 27 |
| C6 — Progression et critères de passage | 4,1 | 2,0 | 27 |
| C7 — Préparation articulaire, mobilité | 4,9 | 2,0 | 27 |
| C8 — Structure | 5,2 | 2,0 | 27 |
| C9 — Faisabilité et clarté | 5,4 | 3,0 | 27 |
| H1 — Volume par muscle | 6,2 | 2,0 | 27 |
| H2 — Fréquence et répartition | 6,8 | 4,5 | 26 |
| H3 — Effort et plages de répétitions | 6,3 | 4,0 | 26 |
| H4 — Choix des exercices | 5,7 | 4,0 | 26 |
| H5 — Progression | 5,0 | 3,5 | 26 |
| H6 — Équilibre et points faibles | 6,1 | 3,0 | 27 |
| H7 — Repos, densité, durée | 7,5 | 3,0 | 27 |
| H8 — Gestion de la fatigue | 6,8 | 3,5 | 27 |
| H9 — Adéquation au profil et faisabilité | 5,1 | 3,5 | 27 |
| S1 — Sécurité pour ce profil | 5,4 | 3,0 | 27 |
| S2 — Progressivité | 5,9 | 3,5 | 27 |
| S3 — Récupération et tolérance | 5,8 | 3,5 | 27 |
| S4 — Endurance de force et cardio | 4,2 | 2,0 | 17 |
| S5 — Santé articulaire et tendineuse | 5,8 | 4,0 | 27 |
| S6 — Effort et échec | 7,2 | 5,0 | 26 |
| S7 — Adhésion et faisabilité | 7,1 | 4,0 | 27 |
| S8 — Échéance : tests, affûtage, jour J | 3,5 | 1,5 | 20 |
| S9 — Clarté des consignes | 5,2 | 3,0 | 27 |

Les critères les plus bas donnent l'ordre des chantiers : affûtage, pic et tests (F5, S8), progression et critères de passage des figures (C6), endurance de force et cardio (S4), périodisation (F4), intensité (F2), choix des paliers (C1), préparation articulaire (C7), spécificité (F1). Les plus hauts sont ceux que les moteurs 0.1 tiennent déjà : repos et durée (H7), effort prudent (S6), adhésion (S7), fréquence par muscle (H2), gestion de la fatigue (H8).

Les 415 corrections jugées nécessaires, profil par profil et école par école, sont dans `docs/baseline/CORRECTIONS_PANEL_0_1.md`.

## 4. Critères calculables

### 4.1 Sécurité (cible : zéro)

| Profil | Volume au-dessus du plafond | Volume trop vite | Charge trop vite | Bras tendus trop vite | Technique sans prérequis | Séance trop longue | Pas d'allègement avant l'échéance | Total (programme créé) | Total (programme évolué) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 2 | · | · | · | · | · | · | **2** | 6 |
| `street_02_debutant_surpoids` | 1 | · | · | · | · | · | · | **1** | 10 |
| `street_03_debutante` | 3 | · | · | · | · | · | · | **3** | 5 |
| `street_04_reprise_longue_pause` | 3 | 2 | · | · | · | · | · | **5** | 9 |
| `street_05_inter_calisthenie_front_lever` | 6 | · | · | · | · | · | · | **6** | 9 |
| `street_06_inter_sets_reps` | 1 | · | · | · | · | · | · | **1** | 4 |
| `street_07_avance_streetlifting_competition` | 4 | · | · | · | · | · | · | **4** | 6 |
| `street_08_avance_sets_reps_competition` | 4 | 2 | · | · | · | · | 1 | **7** | 7 |
| `street_09_elite_streetlifting` | 8 | · | · | · | · | · | · | **8** | 7 |
| `street_10_elite_figures` | 19 | 4 | · | 2 | · | · | · | **25** | 23 |
| `street_11_master_51_ans` | 2 | 1 | · | 3 | 1 | · | · | **7** | 5 |
| `street_12_antecedent_coude` | 5 | · | · | · | 2 | · | · | **7** | 9 |
| `street_13_peu_de_temps` | · | · | · | · | · | · | · | **0** | 1 |
| `street_14_parc_sans_lest` | 5 | 3 | · | · | · | · | · | **8** | 6 |
| `street_15_travail_physique_sommeil_court` | 1 | · | · | · | · | · | · | **1** | 3 |
| `street_16_specialisation_traction_lestee` | 4 | · | · | 1 | · | · | 1 | **6** | 6 |
| `street_17_hybride_street_course` | · | 1 | · | · | · | 2 | · | **3** | 3 |
| `autres_01_debutant_musculation` | 1 | · | · | · | · | · | · | **1** | 2 |
| `autres_02_hypertrophie_intermediaire` | 1 | · | 2 | · | · | · | · | **3** | 13 |
| `autres_03_powerlifter_competition` | 3 | · | · | · | · | · | 1 | **4** | 4 |
| `autres_04_force_generale_46_ans` | · | · | 3 | · | · | · | · | **3** | 12 |
| `autres_05_course_10_km_debutante` | · | · | · | · | · | 3 | 1 | **4** | 4 |
| `autres_06_semi_marathon_intermediaire` | · | · | · | · | · | · | 1 | **1** | 1 |
| `autres_07_mobilite_sante_senior` | · | · | · | · | · | · | · | **0** | 0 |
| `autres_08_crossfit_intermediaire` | 4 | 3 | · | · | · | · | · | **7** | 12 |
| `autres_09_perte_de_poids_debutante` | · | · | · | · | · | · | · | **0** | 0 |
| `autres_10_contraintes_multiples` | · | · | · | · | · | · | · | **0** | 0 |
| **Total** | 77 | 16 | 5 | 6 | 3 | 5 | 5 | **117** | 167 |

Lecture :

- **Volume au-dessus du plafond du niveau** (deux tiers des violations) : le moteur additionne trop de séries sur les mêmes muscles, surtout grand dorsal, fessiers, triceps, quadriceps et pectoraux, et jusqu'à 19 dépassements pour l'élite figures. Les plafonds personnels attendus par un coach (51 ans, reprise, travail physique, antécédent du coude) sont dépassés de 13 à 68 % (§4.2).
- **Volume trop vite** : hausses au-delà de la borne du niveau, le plus souvent en semaines 7, 8 et 12 ; la plupart des dépassements sont faibles (0,1 à 2 séries).
- **Bras tendus trop vite** et **technique sans prérequis** : maintiens en bras tendus allongés de 3 à 5 secondes de trop au changement de bloc ; isométries lestées et dips partiels surchargés servis à des intermédiaires, dont le profil à l'antécédent du coude.
- **Pas d'allègement avant l'échéance** : cinq des sept profils à échéance arrivent au jour J sans baisse de volume.
- **Séance trop longue** : les séances de course dépassent le temps donné.
- Après adaptation simulée, le total passe de 117 à 167 : `kalis_adapt` 0.1.0 ajoute surtout des hausses de charge trop rapides en musculation (+5,3 % pour 5 % admis, par pas de disques) et des hausses de volume chez les débutants street.

### 4.2 Qualité et attentes de coach

| Profil | Qualité (moyenne, 0 à 1) | Attentes tenues | Attentes non tenues (mesure) |
| --- | --- | --- | --- |
| `street_01_debutant_complet` | 0,87 | 5/7 | Travail de traction adapté (assistée, négative ou suspension) au moins deux fois par semaine : 0.0 séance(s) par semaine en montée<br>Jambes (squat ou fente) au moins deux fois par semaine : 1.0 séance(s) par semaine en montée |
| `street_02_debutant_surpoids` | 0,86 | 6/6 | — |
| `street_03_debutante` | 0,84 | 3/5 | Travail de traction adapté au moins deux fois par semaine : 1.0 séance(s) par semaine en montée<br>Jambes au moins deux fois par semaine : 1.0 séance(s) par semaine en montée |
| `street_04_reprise_longue_pause` | 0,83 | 3/4 | Grand dorsal : pas plus de 16 séries dures par semaine : 24.4 séries dures par semaine en montée |
| `street_05_inter_calisthenie_front_lever` | 0,71 | 4/6 | Muscle-up (ou un palier) au moins deux fois par semaine : 1.0 séance(s) par semaine en montée<br>Tirage dynamique (vertical ou horizontal) au moins trois fois par semaine : 2.0 séance(s) par semaine en montée |
| `street_06_inter_sets_reps` | 0,87 | 4/6 | Dips au moins trois fois par semaine : 2.0 séance(s) par semaine en montée<br>Au moins un format de densité (EMOM, AMRAP, tours, série dégressive) : aucun de ces formats |
| `street_07_avance_streetlifting_competition` | 0,88 | 5/10 | Dips lesté au moins deux fois par semaine : 1.0 séance(s) par semaine en montée<br>Au moins une exposition lourde (85 % et plus, ou 5 répétitions au plus sous charge) par semaine en traction lestée : 0.5 exposition(s) lourde(s) par semaine en montée<br>Ondulation : au moins deux plages de répétitions par semaine en traction lestée : 1.0 plage(s) de répétitions distincte(s) par semaine<br>Série haute puis séries allégées, ou clusters : aucun de ces formats<br>Variante pour le point faible (traction lestée pause en bas) au moins une fois par semaine : 0.0 séance(s) par semaine en montée |
| `street_08_avance_sets_reps_competition` | 0,72 | 2/8 | Volume réduit de 40 à 60 % la semaine de la compétition : volume 0 % sous le pic la semaine de l'échéance<br>Tractions au moins quatre fois par semaine : 2.0 séance(s) par semaine en montée<br>Muscle-ups au moins trois fois par semaine : 2.0 séance(s) par semaine en montée<br>Dips au moins trois fois par semaine : 1.0 séance(s) par semaine en montée<br>Formats de l'épreuve : tours, EMOM, AMRAP, séries dégressives : aucun de ces formats<br>Épreuve sur les mouvements visés la semaine de la compétition : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : montée) |
| `street_09_elite_streetlifting` | 0,94 | 5/10 | Traction lestée au moins trois fois par semaine : 1.0 séance(s) par semaine en montée<br>Dips lesté au moins trois fois par semaine : 2.0 séance(s) par semaine en montée<br>Une exposition lourde par semaine au moins sur chaque mouvement de compétition : 1.3 exposition(s) lourde(s) par semaine en montée<br>Série haute puis séries allégées, clusters ou vagues : aucun de ces formats<br>8 à 18 séries dures par semaine en traction lestée et ses variantes : 5.8 séries dures par semaine en montée |
| `street_10_elite_figures` | 0,84 | 6/7 | Préparation ou mobilité des poignets et des épaules au moins trois fois par semaine : 0.0 séance(s) par semaine en montée |
| `street_11_master_51_ans` | 0,86 | 4/5 | Grand dorsal : pas plus de 18 séries dures par semaine : 20.3 séries dures par semaine en montée |
| `street_12_antecedent_coude` | 0,90 | 2/6 | Aucun exercice à contrainte forte sur le coude : présents : Dips lesté de compétition, Isométrie lestée en haut de traction, Muscle-up lesté de compétition, Isométrie lestée en appui aux barres parallèles, Traction lestée de compétition<br>Biceps : pas plus de 10 séries dures par semaine : 15.6 séries dures par semaine en montée<br>Tirage horizontal au moins deux fois par semaine : 1.0 séance(s) par semaine en montée<br>Jamais moins de 2 répétitions en réserve sur les 12 semaines : RIR le plus bas des 12 premières semaines : 1.5 |
| `street_13_peu_de_temps` | 0,84 | 5/6 | Supersets pour gagner du temps : aucun de ces formats |
| `street_14_parc_sans_lest` | 0,86 | 3/5 | Tractions au moins trois fois par semaine : 2.0 séance(s) par semaine en montée<br>Une variante dure de traction (archer, typewriter, poitrine à la barre) au moins une fois par semaine : 0.0 séance(s) par semaine en montée |
| `street_15_travail_physique_sommeil_court` | 0,86 | 4/6 | Grand dorsal : pas plus de 12 séries dures par semaine : 20.1 séries dures par semaine en montée<br>Quadriceps : pas plus de 10 séries dures par semaine : 15.4 séries dures par semaine en montée |
| `street_16_specialisation_traction_lestee` | 0,68 | 1/8 | Traction lestée au moins trois fois par semaine : 1.0 séance(s) par semaine en montée<br>Au moins 30 % des séries dures sur la traction lestée et ses variantes : 4 % des séries dures en montée<br>Dips lesté en entretien : 3 à 8 séries dures par semaine : 10.4 séries dures par semaine en montée<br>Squat en entretien : 3 à 8 séries dures par semaine : 9.4 séries dures par semaine en montée<br>Volume réduit de 30 à 60 % la semaine du test : volume 0 % sous le pic la semaine de l'échéance<br>Épreuve de traction lestée la semaine du test : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : montée)<br>Une exposition lourde par semaine au moins en traction lestée : 0.1 exposition(s) lourde(s) par semaine en montée |
| `street_17_hybride_street_course` | 0,91 | 4/6 | Dips au moins deux fois par semaine : 1.0 séance(s) par semaine en montée<br>Quadriceps : pas plus de 12 séries dures par semaine : 13.3 séries dures par semaine en montée |
| `autres_01_debutant_musculation` | 0,97 | 5/6 | Squat ou presse au moins deux fois par semaine : 1.0 séance(s) par semaine en montée |
| `autres_02_hypertrophie_intermediaire` | 0,89 | 5/5 | — |
| `autres_03_powerlifter_competition` | 0,79 | 3/7 | Volume réduit de 30 à 70 % la semaine de la compétition : volume 0 % sous le pic la semaine de l'échéance<br>Développé couché au moins trois fois par semaine : 1.0 séance(s) par semaine en montée<br>Une exposition lourde par semaine au moins au squat : 0.3 exposition(s) lourde(s) par semaine en montée<br>Épreuve sur les trois mouvements la semaine de la compétition : 0 épreuve(s) sur les mouvements visés la semaine de l'échéance (nature : montée) |
| `autres_04_force_generale_46_ans` | 0,98 | 5/5 | — |
| `autres_05_course_10_km_debutante` | 0,67 | 4/5 | Séances de 65 minutes au plus : séance la plus longue : 80 min estimées |
| `autres_06_semi_marathon_intermediaire` | 0,59 | 5/5 | — |
| `autres_07_mobilite_sante_senior` | 1,00 | 5/5 | — |
| `autres_08_crossfit_intermediaire` | 0,94 | 5/5 | — |
| `autres_09_perte_de_poids_debutante` | 0,83 | 4/6 | Ni saut, ni sprint, ni corde, ni burpees : présents : Pas chassés latéraux (éducatif de course)<br>Pas de course à pied au début : présents : Footing en endurance fondamentale |
| `autres_10_contraintes_multiples` | 0,82 | 6/6 | — |

La qualité moyenne masque les trous : la spécificité (part du travail sur les mouvements visés) vaut 0,09 pour la spécialisation traction lestée, 0,26 pour la compétition sets & reps, 0,41 pour le powerlifting et 0 en course ; la progression planifiée vaut 0,50 pour presque tous les profils street sans lest (aucune progression lisible d'une semaine à l'autre) ; l'affûtage aligné vaut 0,33 pour quatre profils à échéance. Détail par critère : `RAPPORT.md` du contrôle, §1.

### 4.3 Trajectoires simulées (`kalis_adapt` 0.1.0)

| Profil | Séances faites | Écart au RIR visé | Cibles atteignables | Gain réel (%/sem) | Performance à l'échéance | Propositions appliquées | Repères non tenus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 36/36 | 2,12 | 69 % | 1,30 | — | aucune | écart au RIR visé |
| `street_02_debutant_surpoids` | 36/36 | 2,80 | 69 % | 1,07 | — | aucune | écart au RIR visé |
| `street_03_debutante` | 36/36 | 2,22 | 56 % | 1,42 | — | aucune | écart au RIR visé |
| `street_04_reprise_longue_pause` | 48/48 | 2,25 | 79 % | 0,38 | — | aucune | écart au RIR visé |
| `street_05_inter_calisthenie_front_lever` | 63/64 | 2,04 | 76 % | 0,27 | — | aucune | écart au RIR visé |
| `street_06_inter_sets_reps` | 48/48 | 2,22 | 83 % | 0,37 | — | aucune | écart au RIR visé |
| `street_07_avance_streetlifting_competition` | 60/60 | 1,50 | 94 % | 0,03 | 94 % | volume × 3, deload × 1 | écart au RIR visé, performance à l'échéance |
| `street_08_avance_sets_reps_competition` | 40/40 | 1,98 | 77 % | 0,05 | 86 % | aucune | écart au RIR visé, performance à l'échéance |
| `street_09_elite_streetlifting` | 60/60 | 1,51 | 79 % | 0,02 | 94 % | deload × 1, volume × 3 | écart au RIR visé, performance à l'échéance |
| `street_10_elite_figures` | 91/96 | 1,44 | 62 % | 0,03 | — | aucune | écart au RIR visé |
| `street_11_master_51_ans` | 48/48 | 1,76 | 75 % | 0,23 | — | exercise_swap × 1 | écart au RIR visé |
| `street_12_antecedent_coude` | 48/48 | 1,54 | 91 % | 0,09 | — | aucune | écart au RIR visé |
| `street_13_peu_de_temps` | 34/36 | 2,25 | 84 % | 0,45 | — | aucune | écart au RIR visé |
| `street_14_parc_sans_lest` | 46/48 | 2,25 | 75 % | 0,42 | — | aucune | écart au RIR visé |
| `street_15_travail_physique_sommeil_court` | 36/36 | 2,12 | 92 % | 0,42 | — | aucune | écart au RIR visé |
| `street_16_specialisation_traction_lestee` | 40/40 | 1,62 | 97 % | 0,03 | 100 % | volume × 1 | écart au RIR visé |
| `street_17_hybride_street_course` | 58/60 | 2,05 | 91 % | 0,42 | — | aucune | écart au RIR visé |
| `autres_01_debutant_musculation` | 36/36 | 1,77 | 91 % | 0,65 | — | exercise_swap × 1 | écart au RIR visé |
| `autres_02_hypertrophie_intermediaire` | 60/60 | 2,48 | 93 % | 0,10 | — | exercise_swap × 2 | écart au RIR visé |
| `autres_03_powerlifter_competition` | 40/40 | 1,20 | 100 % | 0,04 | 97 % | volume × 1 | écart au RIR visé, performance à l'échéance |
| `autres_04_force_generale_46_ans` | 48/48 | 1,46 | 100 % | 0,15 | — | aucune | écart au RIR visé |
| `autres_05_course_10_km_debutante` | 34/36 | 0,00 | 0 % | — | — | aucune | aucun |
| `autres_06_semi_marathon_intermediaire` | 46/48 | 2,45 | 74 % | 0,28 | — | aucune | écart au RIR visé |
| `autres_07_mobilite_sante_senior` | 46/48 | 3,58 | 90 % | 0,74 | — | aucune | écart au RIR visé |
| `autres_08_crossfit_intermediaire` | 79/80 | 1,66 | 82 % | 0,17 | — | exercise_swap × 1, volume × 2 | écart au RIR visé |
| `autres_09_perte_de_poids_debutante` | 36/36 | 2,25 | 83 % | 0,82 | — | aucune | écart au RIR visé |
| `autres_10_contraintes_multiples` | 36/36 | 2,89 | 98 % | 0,77 | — | aucune | écart au RIR visé |

Lecture :

- **Écart au RIR visé** : aucun profil à cibles mesurables ne tient le repère (le 10 km n'a aucune cible mesurable). Les charges et répétitions proposées laissent en moyenne deux répétitions de marge de plus que prévu ; l'adaptation ne rattrape pas l'écart, faute de recalculer la cible après chaque séance.
- **Cibles atteignables** : pour les débutants street et l'élite figures, 30 à 45 % des prescriptions sont hors de portée de l'athlète simulé (exercice trop dur ou plage de répétitions impossible).
- **Gain réel** : 0,02 à 0,05 % par semaine pour les avancés et l'élite sous charge, c'est-à-dire une progression nulle sur le cycle.
- **Performance à l'échéance** : 86 à 97 % du meilleur niveau antérieur pour quatre des cinq profils testés ; la préparation n'amène pas l'athlète à son pic.
- **Course, mobilité, conditionnement** : `kalis_adapt` 0.1.0 ne modélise pas ces séances (aucune cible atteignable pour le 10 km, aucun gain mesurable).
- Aucun déblocage de niveau d'adaptation non respecté, aucune aggravation de douleur simulée, très peu d'échecs non voulus.

## 5. Défauts, par ordre de priorité

Chaque défaut cite sa mesure. Lots : **CP1** = `kalis_plan` street ; **CA1** = `kalis_adapt` street ; **CP2** et **CA2** = autres disciplines. Dans un lot, traiter dans l'ordre.

### 5.1 Street — création du programme (CP1)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **L'échéance est ignorée.** Pas d'affûtage, pas de pic, pas de simulation ni d'épreuve le jour J ; le dernier bloc repart d'une introduction ; tests posés au milieu ou étalés sur trois jours ; semaines de test presque vides. | F5 moyenne 3,0 (la plus basse de tous les critères) ; S8 3,5 ; `affutage_absent` × 5 ; attentes « volume réduit » et « épreuve la semaine de l'échéance » non tenues | street 07, 08, 09, 16 ; tous les profils à tests |
| 2 | **Intensité sous-dosée et charges mal calculées chez les avancés.** Charges plafonnées vers 77 à 81 % ; aucune exposition lourde régulière, ni série haute suivie de séries allégées ; pourcentage affiché différent de la charge prescrite ; pourcentages appliqués au lest au lieu de la charge totale (corps + lest) ; mentions « à déterminer » ou « voir les séries ». | F2 4,7 ; attentes « exposition lourde par semaine » non tenues (0,1 à 1,3 par semaine) ; gain simulé 0,02 à 0,05 %/sem | street 07, 09, 16 |
| 3 | **Spécificité insuffisante.** Le mouvement visé est absent ou travaillé une fois par semaine ; le volume se disperse sur des variantes ; le muscle-up lesté de compétition n'est jamais chargé ; 4 % des séries dures sur la traction lestée quand elle est la priorité. | F1 5,0 ; qualité `specificite` 0,09 à 0,76 ; 15 attentes de fréquence non tenues | street 05 à 09, 14, 16, 17 |
| 4 | **Blocs identiques, pas de progression écrite.** Deux blocs qui se répètent, aucune règle de progression d'une semaine à l'autre, aucune ondulation. | F4 4,5 ; H5 5,0 ; qualité `progression_planifiee` 0,50 pour 10 profils street | tous |
| 5 | **Débutants : pas de chemin vers la première traction.** Aucun travail adapté (négatives, assistance, tirage australien) ou une fois par semaine ; pompes prescrites à 1 ou 2 répétitions avec 4 de marge ; tests de traction pour qui n'en fait aucune ; jambes une fois par semaine. | Attentes « traction adaptée deux fois par semaine » non tenues (0 et 1) ; 31 à 44 % de cibles hors de portée ; C1 4,9 | street 01, 02, 03 |
| 6 | **Figures : pas de progression par paliers.** Paliers hors de portée ou sans rapport avec le niveau, aucun critère de passage, maintiens allongés trop vite, pas de préparation des poignets et des épaules. | C6 4,1 ; C7 4,9 ; `tendon_figures` × 6 ; 38 % de cibles hors de portée pour l'élite figures | street 05, 10, 11 |
| 7 | **Volume par muscle au-dessus des plafonds**, et plafonds personnels non appliqués (âge, reprise, travail physique, sommeil court, antécédent). | `plafond_volume` × 77, `volume_trop_vite` × 16 ; attentes de plafond non tenues (grand dorsal 20 à 24 séries pour 12 à 18 permises) | street 04, 05, 09, 10, 11, 12, 14, 15 |
| 8 | **Sets & reps : aucune méthode d'endurance de force.** Ni EMOM, ni AMRAP, ni tours, ni séries dégressives ; fréquence des mouvements de l'épreuve deux fois trop basse. | S4 4,2 ; attentes « format de densité » non tenues ; qualité `specificite` 0,26 | street 06, 08 |
| 9 | **Données du profil ignorées.** Exercices à forte contrainte sur le coude malgré l'antécédent ; technique avancée sans prérequis ; hausse de volume de 40 % en deuxième semaine de reprise (relevée par le panel) ; rien pour le sommeil court ni le métier physique ; parc sans lest : aucune variante dure ; créneau court : pas de supersets. | `technique_sans_prerequis` × 3 ; attentes non tenues des profils 04, 12, 13, 14, 15 ; F8 5,4 | street 04, 11 à 15 |
| 10 | **Exercices inadaptés et consignes absentes.** Variantes au-dessus du niveau (pompes en équilibre libre, archer en séries longues, ischios nordiques à 10–15 répétitions, muscle-up lesté sans muscle-up) ; pas d'échauffement écrit, pas de règle en cas de douleur, série à l'échec sous lest en semaine de test. | S9 5,2 ; H4 5,7 ; corrections nécessaires du panel | plusieurs |

### 5.2 Street — adaptation (CA1)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **L'écart au RIR visé n'est pas rattrapé.** Deux répétitions de marge en trop en moyenne, sans correction de la charge ou des répétitions à la séance suivante. | Écart 1,4 à 2,8 ; repère non tenu pour les 17 profils street | tous |
| 2 | **Pas de pilotage vers l'échéance.** Ni affûtage, ni tests, ni choix des tentatives ; performance simulée sous le meilleur niveau antérieur. | Performance à l'échéance 86 à 94 % (street 07, 08, 09) | street 07, 08, 09, 16 |
| 3 | **Progression nulle des avancés.** Les hausses de charge proposées sont trop rares pour produire un gain. | Gain 0,02 à 0,05 %/sem | street 07, 08, 09, 10, 16 |
| 4 | **Cibles hors de portée non corrigées.** L'adaptation ne remplace pas l'exercice ni la plage quand l'athlète ne peut pas la tenir. | Cibles atteignables 56 à 79 % | street 01 à 05, 08 à 11, 14 |
| 5 | **L'adaptation ajoute des violations.** Hausses de volume au-dessus des bornes après les semaines allégées, maintiens en bras tendus allongés trop vite. | Violations du programme évolué supérieures à celles du programme créé pour 10 profils street | street 01 à 07, 12, 13, 15 |
| 6 | **Peu de propositions.** Les niveaux d'adaptation se débloquent, mais aucune proposition (volume, décharge, remplacement) n'est appliquée pour 13 profils street sur 17. | `proposalsApplied` du rapport | tous sauf street 07, 09, 11, 16 |

### 5.3 Autres disciplines — création (CP2)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **Course non modélisée.** Pas d'allures, tests de 10 ou 21 km au milieu du plan, pas de progression du volume ni de sortie longue construite, pas d'affûtage, séances plus longues que le créneau. | Notes 3,0 à 4,5 ; qualité `specificite` 0 ; `seance_trop_longue` × 5 ; `affutage_absent` × 2 | autres 05, 06 ; street 17 |
| 2 | **Powerlifting : pas de pic.** Développé couché une fois par semaine, aucune exposition lourde, pas d'affûtage ni d'épreuve le jour J. | Notes 3,0 à 4,5 ; 4 attentes sur 7 non tenues | autres 03 |
| 3 | **Force générale et CrossFit : intensité et structure.** Charges trop basses pour un objectif de force, volume au-dessus des plafonds, hausses de charge de 5,3 % pour 5 % admis. | `charge_trop_vite` × 5 ; `plafond_volume` × 5 ; force 3,5 pour autres 04 | autres 02, 04, 08 |
| 4 | **Priorité musculaire ignorée en hypertrophie.** Le groupe à développer ne reçoit pas plus de travail que les autres. | Qualité `points_faibles` 0,50 | autres 02 |
| 5 | **Santé, perte de poids, senior : contraintes mal lues.** Course et déplacements latéraux malgré la consigne sans impact, pas de travail d'équilibre pour le senior, squat ou presse une fois par semaine pour le débutant. | Attentes non tenues d'autres 01 et 09 ; corrections du panel pour autres 07 et 10 | autres 01, 07, 09, 10 |

### 5.4 Autres disciplines — adaptation (CA2)

| Rang | Défaut | Mesure | Profils |
| --- | --- | --- | --- |
| 1 | **Cardio, conditionnement et mobilité non modélisés** : aucune cible, aucun retour exploité. | Cibles atteignables 0 % pour autres 05 ; aucun gain mesurable | autres 05, 06, 07, 08 |
| 2 | **Hausses de charge trop rapides en musculation** après adaptation. | `charge_trop_vite` : 5 à 11 violations sur le programme évolué | autres 02, 04, 08 |
| 3 | **Écart au RIR visé**, comme en street, jusqu'à 3,6 répétitions pour le senior. | Repère non tenu pour 9 profils sur 10 | tous |

## 6. Limites de cette mesure

- **Une seule passe du panel.** L'incertitude d'une note est d'environ un point (répétabilité mesurée à l'étalonnage : écart maximal 1, moyen 0,25). Les notes de 3 à 7 sont très loin du seuil ; le classement fin entre profils voisins n'est pas significatif.
- **Le relecteur note le programme et le résumé de la trajectoire ensemble.** La note d'ensemble mêle donc `kalis_plan` et `kalis_adapt`. Les lots CP1 et CA1 devront séparer les deux lectures quand ils calibrent l'un sans l'autre.
- **Athlète simulé.** Les trajectoires viennent d'un modèle d'athlète déterministe (`docs/CRITERES.md`) : il mesure la cohérence de l'adaptation, pas ce que ferait une personne réelle.
- **Bornes de sécurité.** Elles viennent du référentiel (`docs/REFERENTIEL.md`) et de `kalis_core` (profil v3) ; là où les deux diffèrent, la borne retenue et sa raison sont dans `pipeline/cp/DECISIONS_CP.md` (CR).
- **Plafond de l'échelle.** À l'étalonnage, les meilleurs programmes écrits à la main ont obtenu 9 de chaque école, jamais 10 : atteindre 9 est possible, mais le panel trouve toujours une amélioration.
- **Relecture du propriétaire.** La page « Relecture Kalis Track » (manche 0) recueille ses notes sur dix de ces programmes ; elles serviront à recaler le panel avant CP1 si elles s'en écartent.
