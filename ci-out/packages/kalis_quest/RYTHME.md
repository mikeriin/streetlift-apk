# Simulation de rythme — kalis_quest 0.1.0

Document généré par `dart run bin/kalis_quest_cli.dart --rapport <dossier>` (mise en tableaux de `docs/data/campagne.json`). 8 archétypes × 2 graines × 156 semaines ; le moteur est appelé à la fin de chaque semaine avec le bloc en cours de `kalis_plan`. Valeurs : médiane (10ᵉ–90ᵉ centile) sur les graines, ou moyenne quand un seul nombre est donné. Lecture et limites : `VALIDATION.md`.

## 1. Archétypes

| Archétype | Profil type | Séances prévues / sem. | Séances récompensées / sem. | Ce qu'il représente |
| --- | --- | --- | --- | --- |
| `debutant_2x` | `debutant_forme_generale_maison_2x30` | 2 | 1.71 | Débutant, 2 séances de 30 min par semaine à la maison. |
| `debutant_3x` | `homme_25_musculation_debutant_3x60` | 3 | 2.68 | Débutant régulier, 3 séances par semaine en salle (repère). |
| `intermediaire_4x` | `femme_45_musculation_salle_4x60` | 4 | 3.61 | Intermédiaire régulière, 4 séances par semaine (repère). |
| `avance_street_4x` | `street_streetlifting_4x90` | 4 | 3.69 | Avancé en streetlifting, 4 séances de 90 min par semaine. |
| `expert_6x` | `six_jours_musculation_avance_6x75` | 6 | 5.7 | Expert, 6 séances par semaine. |
| `irregulier_3x` | `femme_30_street_workout_parc_3x45` | 3 | 1.52 | Irrégulière : 3 séances prévues, 60 % faites, deux arrêts non déclarés de 3 et 4 semaines par an. |
| `vacances_5x` | `crossfit_5x60` | 4.62 | 4.05 | 5 séances par semaine, vacances déclarées : 3 semaines l'été, 1 semaine l'hiver. |
| `maladie_3x` | `senior_65_forme_generale_3x40` | 2.81 | 2.36 | Senior, 3 séances par semaine, deux maladies déclarées de 10 jours par an, douleur déclarée avant 8 % des séances (dont 30 % faites quand même sans épargner la zone). |

## 2. Niveau dans le temps

| Archétype | Sem. 1 | Sem. 3 | Sem. 13 | Sem. 26 | Sem. 52 | Sem. 104 | Sem. 156 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (3–5) | 10 (9–10) | 21 (20–21) | 31 (30–31) | 44 (42–45) | 63 (61–64) | 78 (76–79) |
| `debutant_3x` | 6 (5–6) | 11 (10–11) | 23 (22–23) | 33 (32–33) | 49 (48–50) | 70 (70–70) | 87 (87–87) |
| `intermediaire_4x` | 5 (5–5) | 11 (10–12) | 26 (25–26) | 38 (37–39) | 56 (55–56) | 80 (79–81) | 99 (98–100) |
| `avance_street_4x` | 6 (5–6) | 12 (11–12) | 26 (26–26) | 39 (38–39) | 56 (55–56) | 80 (79–81) | 99 (97–100) |
| `expert_6x` | 8 (7–8) | 14 (13–15) | 31 (31–31) | 46 (45–46) | 67 (66–67) | 96 (95–97) | 160 (159–161) |
| `irregulier_3x` | 4 (3–4) | 8 (8–8) | 19 (18–19) | 25 (25–25) | 37 (36–37) | 54 (53–54) | 66 (65–66) |
| `vacances_5x` | 7 (6–7) | 13 (13–13) | 29 (29–29) | 42 (41–42) | 59 (58–60) | 85 (84–85) | 127 (124–129) |
| `maladie_3x` | 6 (6–6) | 12 (11–12) | 23 (22–24) | 34 (33–35) | 49 (47–50) | 69 (68–70) | 87 (86–87) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 3.5 (3.1–3.9) | 18.5 (18.1–18.9) | 68.5 (64.9–72.1) | jamais en 156 sem. |
| `debutant_3x` | 3 (3–3) | 16 (15.2–16.8) | 54.5 (52.5–56.5) | jamais en 156 sem. |
| `intermediaire_4x` | 3 (3–3) | 12.5 (12.1–12.9) | 42 (41.2–42.8) | 154 (154–154) — 1/2 graines |
| `avance_street_4x` | 2.5 (2.1–2.9) | 12.5 (12.1–12.9) | 42 (41.2–42.8) | 156 (156–156) — 1/2 graines |
| `expert_6x` | 2 (2–2) | 9 (9–9) | 30.5 (30.1–30.9) | 111.5 (110.3–112.7) |
| `irregulier_3x` | 4.5 (4.1–4.9) | 25.5 (25.1–25.9) | 89 (86.6–91.4) | jamais en 156 sem. |
| `vacances_5x` | 2 (2–2) | 10 (10–10) | 38 (37.2–38.8) | 142.5 (140.5–144.5) |
| `maladie_3x` | 3 (3–3) | 15 (14.2–15.8) | 55 (52.6–57.4) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (2 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 54.5 (52.5–56.5) sem. — 2/2 graines | 198.5 (197.3–199.7) sem. — 2/2 graines | 117 (115–119) |
| `intermediaire_4x` | 42 (41.2–42.8) sem. — 2/2 graines | 158 (154.8–161.2) sem. — 2/2 graines | 153 (151–155) |

### Courbe médiane (niveau global, toutes les 12 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 20 | 29 | 36 | 42 | 47 | 51 | 57 | 60 | 64 | 68 | 71 | 74 | 78 |
| `debutant_3x` | 22 | 31 | 39 | 47 | 52 | 58 | 63 | 68 | 72 | 76 | 79 | 83 | 87 |
| `intermediaire_4x` | 25 | 36 | 46 | 54 | 59 | 66 | 72 | 77 | 82 | 87 | 90 | 95 | 99 |
| `avance_street_4x` | 25 | 37 | 46 | 54 | 60 | 66 | 72 | 77 | 82 | 86 | 90 | 95 | 99 |
| `expert_6x` | 30 | 44 | 55 | 64 | 72 | 79 | 86 | 93 | 98 | 123 | 138 | 150 | 160 |
| `irregulier_3x` | 18 | 24 | 32 | 35 | 40 | 45 | 48 | 53 | 55 | 58 | 60 | 64 | 66 |
| `vacances_5x` | 27 | 40 | 49 | 57 | 64 | 71 | 76 | 82 | 86 | 92 | 96 | 105 | 127 |
| `maladie_3x` | 22 | 32 | 41 | 47 | 52 | 58 | 62 | 67 | 71 | 75 | 79 | 83 | 87 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 59059 (57394–60724) | 378.6 | 40 % | 24 % | 0 % | 0 % | 36 % |
| `debutant_3x` | 74511 (74370–74652) | 477.6 | 50 % | 20 % | 1 % | 0 % | 29 % |
| `intermediaire_4x` | 94251 (92254–96247) | 604.2 | 56 % | 17 % | 0 % | 0 % | 27 % |
| `avance_street_4x` | 93223 (91329–95117) | 597.6 | 56 % | 18 % | 1 % | 0 % | 26 % |
| `expert_6x` | 133146 (132193–134098) | 853.5 | 65 % | 12 % | 0 % | 0 % | 22 % |
| `irregulier_3x` | 43383 (42485–44281) | 278.1 | 49 % | 18 % | 0 % | 0 % | 33 % |
| `vacances_5x` | 105008 (103490–106526) | 673.1 | 61 % | 14 % | 0 % | 0 % | 26 % |
| `maladie_3x` | 72963 (71913–74013) | 467.7 | 51 % | 18 % | 0 % | 0 % | 32 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 943.5 / 1966 (48 %) | 185 / 312 (59 %) | 65 / 78 (83 %) | 68.5 / 156 (44 %) |
| `debutant_3x` | 1136.5 / 2111 (54 %) | 165 / 312 (53 %) | 59.5 / 64 (93 %) | 46 / 156 (30 %) |
| `intermediaire_4x` | 1256.5 / 2265.5 (56 %) | 188.5 / 312 (60 %) | 61 / 64 (95 %) | 57 / 156 (37 %) |
| `avance_street_4x` | 1337.5 / 2265.5 (59 %) | 163 / 312 (52 %) | 51.5 / 52 (99 %) | 51 / 156 (33 %) |
| `expert_6x` | 1766 / 2570.5 (69 %) | 162.5 / 312 (52 %) | 52 / 52 (100 %) | 44 / 156 (28 %) |
| `irregulier_3x` | 763 / 2113.5 (36 %) | 119 / 312 (38 %) | 37 / 78 (47 %) | 45.5 / 156 (29 %) |
| `vacances_5x` | 1464 / 2323.5 (63 %) | 170 / 288 (59 %) | 58.5 / 64 (91 %) | 65 / 144 (45 %) |
| `maladie_3x` | 1167 / 2053.5 (57 %) | 166.5 / 300 (56 %) | 64.5 / 78 (83 %) | 63 / 150 (42 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 112.5 / 0 / 42.5 | 17 (16–17) | 0 % / 1 % / 96 % / 3 % | 64 (63–64) | 4.19 | 8 | 7842 (7509–8174) |
| `debutant_3x` | 111 / 0 / 44 | 16 (15–16) | 0 % / 32 % / 64 % / 4 % | 88 (86–90) | 4.76 | 8 | 8285 (8194–8375) |
| `intermediaire_4x` | 144.5 / 0 / 10.5 | 40 (31–48) | 0 % / 34 % / 62 % / 4 % | 120 (115–125) | 4.69 | 8 | 9769 (9324–10214) |
| `avance_street_4x` | 150 / 0 / 5 | 80 (49–110) | 0 % / 39 % / 58 % / 2 % | 125 (119–131) | 4.63 | 8 | 9483 (9113–9853) |
| `expert_6x` | 150.5 / 0 / 4.5 | 94 (53–135) | 1 % / 75 % / 23 % / 1 % | 182 (179–184) | 4.9 | 8 | 11978 (11904–12051) |
| `irregulier_3x` | 30.5 / 0 / 124.5 | 2 (2–2) | 18 % / 11 % / 56 % / 16 % | 55 (54–56) | 4.31 | 8 | 5223 (5207–5239) |
| `vacances_5x` | 127 / 11 / 17 | 29 (26–31) | 10 % / 25 % / 60 % / 5 % | 137 (131–142) | 4.63 | 8 | 10668 (10478–10858) |
| `maladie_3x` | 88 / 10.5 / 56.5 | 11 (9–13) | 0 % / 1 % / 91 % / 8 % | 78 (76–80) | 4.72 | 8 | 8304 (8081–8526) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5969 | 1105 | 523 | 245 | 0 |
| `debutant_3x` | 5831 | 1570 | 590 | 198 | 96 |
| `intermediaire_4x` | 6601 | 2025 | 680 | 428 | 36 |
| `avance_street_4x` | 6143 | 2125 | 678 | 478 | 60 |
| `expert_6x` | 7175 | 3045 | 1300 | 395 | 63 |
| `irregulier_3x` | 3774 | 995 | 443 | 0 | 12 |
| `vacances_5x` | 6920 | 2335 | 1073 | 330 | 11 |
| `maladie_3x` | 6271 | 1285 | 588 | 160 | 0 |

## 6. Avancements

Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).

| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 17.7 (18) | 8.4 (8.4) | 3.5 (3.6) | 1 (14.9) | 78.8 (96.7) | 68.4 (100) | 0 | 0 |
| `debutant_3x` | 35.8 (39.7) | 12.4 (12.4) | 7.2 (8) | 12.4 (13.8) | 22.9 (35.9) | 72.2 (100) | 36 | 6 |
| `intermediaire_4x` | 44.7 (51.9) | 27.9 (27.9) | 9 (10.4) | 10.6 (13.6) | 85 (97.4) | 95.8 (99.2) | 12.5 | 5.5 |
| `avance_street_4x` | 57.2 (57.5) | 27 (27) | 41 (41) | 51.1 (59.6) | 12.6 (27.3) | 96.7 (100) | 24.5 | 7.5 |
| `expert_6x` | 58.8 (60.8) | 1 (1) | 11.8 (12.2) | 21.1 (23.7) | 4.7 (20.4) | 86.7 (100) | 26 | 4.5 |
| `irregulier_3x` | 17.9 (18) | 19 (19) | 3.6 (3.6) | 4.2 (20.7) | 51.4 (72.8) | 34.5 (64.7) | 4 | 1 |
| `vacances_5x` | 35.3 (42.3) | 19.8 (21) | 52.1 (53.5) | 26.7 (32.6) | 66.6 (93.9) | 74.3 (98) | 3.5 | 2.5 |
| `maladie_3x` | 12 (12) | 8.4 (8.4) | 2.4 (2.4) | 1 (12.1) | 96.3 (100) | 67.8 (95.9) | 0 | 0 |

## 7. Garde-fous mesurés

| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d'effort / plafond | Niveau en baisse | Écritures d'XP |
| --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 0 | 0 | 0 | 0.927 | jamais | 1771 |
| `debutant_3x` | 0 | 0 | 0 | 0.939 | jamais | 2090 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.961 | jamais | 2359 |
| `avance_street_4x` | 0 | 0 | 0 | 0.97 | jamais | 2415 |
| `expert_6x` | 0 | 0 | 0 | 0.953 | jamais | 3120 |
| `irregulier_3x` | 0 | 0 | 0 | 0.973 | jamais | 1379 |
| `vacances_5x` | 0 | 0 | 0 | 1 | jamais | 2582 |
| `maladie_3x` | 3 | 0 | 0 | 0.979 | jamais | 2048 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 74511 (74370–74652) | 76890 (76587–77192) | 2379 | 37038 | 42670 | 442 | 0.97 |
| `intermediaire_4x` | 94251 (92254–96247) | 100336 (100058–100614) | 6086 | 52949 | 61283 | 320.5 | 0.986 |

Les séances en plus du tricheur prennent la place des séances prévues qu'il manque : son XP d'effort monte jusqu'au plafond du programme, jamais au-delà. Face au même programme fait en entier (assiduité parfaite), le surentraînement ne rapporte rien :

| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |
| --- | --- | --- | --- | --- |
| `debutant_3x` | 2 | 86157 | 76408 | -9736 |
| `intermediaire_4x` | 2 | 107927 | 100845 | -7031 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 66.5 ms | 70.2 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 10.9 ms | 27.9 ms | ≤ 200 ms |
