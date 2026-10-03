# Simulation de rythme — kalis_quest 0.1.0

Document généré par `dart run bin/kalis_quest_cli.dart --rapport <dossier>` (mise en tableaux de `docs/data/campagne.json`). 8 archétypes × 200 graines × 156 semaines ; le moteur est appelé à la fin de chaque semaine avec le bloc en cours de `kalis_plan`. Valeurs : médiane (10ᵉ–90ᵉ centile) sur les graines, ou moyenne quand un seul nombre est donné. Lecture et limites : `VALIDATION.md`.

## 1. Archétypes

| Archétype | Profil type | Séances prévues / sem. | Séances récompensées / sem. | Ce qu'il représente |
| --- | --- | --- | --- | --- |
| `debutant_2x` | `debutant_forme_generale_maison_2x30` | 2 | 1.7 | Débutant, 2 séances de 30 min par semaine à la maison. |
| `debutant_3x` | `homme_25_musculation_debutant_3x60` | 3 | 2.7 | Débutant régulier, 3 séances par semaine en salle (repère). |
| `intermediaire_4x` | `femme_45_musculation_salle_4x60` | 4 | 3.6 | Intermédiaire régulière, 4 séances par semaine (repère). |
| `avance_street_4x` | `street_streetlifting_4x90` | 4 | 3.68 | Avancé en streetlifting, 4 séances de 90 min par semaine. |
| `expert_6x` | `six_jours_musculation_avance_6x75` | 6 | 5.7 | Expert, 6 séances par semaine. |
| `irregulier_3x` | `femme_30_street_workout_parc_3x45` | 3 | 1.56 | Irrégulière : 3 séances prévues, 60 % faites, deux arrêts non déclarés de 3 et 4 semaines par an. |
| `vacances_5x` | `crossfit_5x60` | 4.62 | 4.06 | 5 séances par semaine, vacances déclarées : 3 semaines l'été, 1 semaine l'hiver. |
| `maladie_3x` | `senior_65_forme_generale_3x40` | 2.81 | 2.37 | Senior, 3 séances par semaine, deux maladies déclarées de 10 jours par an, douleur déclarée avant 8 % des séances (dont 30 % faites quand même sans épargner la zone). |

## 2. Niveau dans le temps

| Archétype | Sem. 1 | Sem. 3 | Sem. 13 | Sem. 26 | Sem. 52 | Sem. 104 | Sem. 156 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5 (3–5) | 9 (8–10) | 21 (19–22) | 30 (28–31) | 43 (41–44) | 62 (60–63) | 77 (75–78) |
| `debutant_3x` | 5 (4–6) | 10 (9–11) | 23 (21–24) | 33 (32–34) | 48 (47–49) | 70 (69–71) | 87 (86–89) |
| `intermediaire_4x` | 6 (5–7) | 11 (10–12) | 26 (25–27) | 38 (37–39) | 55 (54–56) | 80 (79–81) | 99 (98–100) |
| `avance_street_4x` | 6 (5–7) | 11 (11–12) | 27 (26–27) | 38 (37–39) | 55 (54–56) | 79 (78–80) | 98 (97–99) |
| `expert_6x` | 8 (7–8) | 14 (13–15) | 32 (31–32) | 46 (45–46) | 66 (65–67) | 96 (95–97) | 160 (158–161) |
| `irregulier_3x` | 4 (3–5) | 8 (6–9) | 19 (17–20) | 26 (24–27) | 37 (35–39) | 54 (52–56) | 67 (65–68) |
| `vacances_5x` | 7 (6–8) | 13 (12–14) | 29 (27–30) | 42 (41–43) | 58 (57–59) | 84 (83–85) | 127 (122–130) |
| `maladie_3x` | 6 (4–6) | 10 (9–12) | 22 (21–24) | 33 (32–35) | 48 (47–49) | 70 (68–71) | 86 (85–88) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (3–5) | 18 (16–20.1) | 69 (65–73) | jamais en 156 sem. |
| `debutant_3x` | 3 (3–4) | 15 (14–17) | 55 (53–57) | jamais en 156 sem. |
| `intermediaire_4x` | 3 (2–3) | 12 (11–13) | 43 (42–45) | 155 (154–156) — 57/200 graines |
| `avance_street_4x` | 3 (2–3) | 12 (11–13) | 43 (42–45) | 155 (155–156) — 14/200 graines |
| `expert_6x` | 2 (2–2) | 9 (8–9) | 30 (30–31) | 112 (110–113) |
| `irregulier_3x` | 4 (4–5) | 24 (20–27) | 88 (84–93) | jamais en 156 sem. |
| `vacances_5x` | 2 (2–3) | 10 (9–11) | 39 (38–40) | 142 (140–145) |
| `maladie_3x` | 3 (3–4) | 16 (14–17) | 55 (53–58) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (50 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 55 (52.9–57) sem. — 50/50 graines | 199 (194.9–202) sem. — 50/50 graines | 115 (109–120) |
| `intermediaire_4x` | 43 (42–45) sem. — 50/50 graines | 158 (155–161) sem. — 50/50 graines | 152 (150–154) |

### Courbe médiane (niveau global, toutes les 12 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 20 | 29 | 35 | 41 | 46 | 51 | 55 | 59 | 63 | 67 | 70 | 73 | 77 |
| `debutant_3x` | 22 | 32 | 40 | 46 | 52 | 57 | 63 | 67 | 72 | 76 | 80 | 84 | 87 |
| `intermediaire_4x` | 25 | 36 | 45 | 53 | 59 | 65 | 71 | 76 | 81 | 86 | 91 | 95 | 99 |
| `avance_street_4x` | 25 | 37 | 45 | 53 | 59 | 65 | 71 | 76 | 81 | 86 | 90 | 94 | 98 |
| `expert_6x` | 30 | 44 | 54 | 64 | 72 | 79 | 86 | 92 | 98 | 122 | 138 | 150 | 160 |
| `irregulier_3x` | 18 | 25 | 31 | 35 | 40 | 45 | 48 | 52 | 55 | 58 | 61 | 65 | 67 |
| `vacances_5x` | 28 | 40 | 48 | 56 | 63 | 70 | 75 | 81 | 86 | 91 | 97 | 100 | 127 |
| `maladie_3x` | 21 | 32 | 40 | 46 | 52 | 57 | 62 | 67 | 71 | 75 | 79 | 82 | 86 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 58233 (55960–60368) | 373.2 | 40 % | 24 % | 0 % | 0 % | 36 % |
| `debutant_3x` | 74671 (72811–76475) | 478.6 | 50 % | 20 % | 1 % | 0 % | 29 % |
| `intermediaire_4x` | 94230 (92433–95885) | 603.8 | 56 % | 17 % | 0 % | 0 % | 26 % |
| `avance_street_4x` | 93160 (91197–94741) | 596.5 | 56 % | 17 % | 1 % | 0 % | 26 % |
| `expert_6x` | 133387 (131778–134939) | 854.7 | 65 % | 13 % | 0 % | 0 % | 22 % |
| `irregulier_3x` | 44973 (42552–47155) | 287.9 | 49 % | 18 % | 0 % | 0 % | 33 % |
| `vacances_5x` | 104839 (102585–107080) | 672.3 | 61 % | 14 % | 0 % | 0 % | 25 % |
| `maladie_3x` | 72794 (70698–74776) | 466.6 | 51 % | 18 % | 0 % | 0 % | 32 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 941.2 / 1949 (48 %) | 177.4 / 312 (57 %) | 64.9 / 78 (83 %) | 63 / 156 (40 %) |
| `debutant_3x` | 1142.3 / 2105 (54 %) | 164.3 / 312 (53 %) | 60 / 64 (94 %) | 45.2 / 156 (29 %) |
| `intermediaire_4x` | 1265.2 / 2260.2 (56 %) | 182.3 / 312 (58 %) | 61.6 / 64 (96 %) | 52 / 156 (33 %) |
| `avance_street_4x` | 1338.6 / 2260.2 (59 %) | 163.4 / 312 (52 %) | 51.9 / 52 (100 %) | 50.7 / 156 (33 %) |
| `expert_6x` | 1756.1 / 2572.1 (68 %) | 166.1 / 312 (53 %) | 52 / 52 (100 %) | 41.8 / 156 (27 %) |
| `irregulier_3x` | 788.2 / 2104 (38 %) | 117.6 / 312 (38 %) | 40 / 78 (51 %) | 50 / 156 (32 %) |
| `vacances_5x` | 1454.2 / 2314.8 (63 %) | 170.2 / 288 (59 %) | 58.9 / 64 (92 %) | 63.3 / 144 (44 %) |
| `maladie_3x` | 1166.8 / 2045.4 (57 %) | 164.8 / 300 (55 %) | 63.8 / 78 (82 %) | 65.8 / 150 (44 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 111.7 / 0 / 43.3 | 12 (9–18) | 0 % / 1 % / 94 % / 5 % | 54 (48–59) | 4.9 | 8 | 7516 (7134–7897) |
| `debutant_3x` | 113 / 0 / 42.1 | 13 (9–17) | 1 % / 33 % / 61 % / 6 % | 86 (79–93) | 4.9 | 8 | 8214 (7896–8559) |
| `intermediaire_4x` | 147 / 0 / 8 | 44 (31–68) | 0 % / 34 % / 61 % / 4 % | 114 (106–120) | 4.95 | 8 | 9642 (9327–9999) |
| `avance_street_4x` | 149.7 / 0 / 5.3 | 58 (39–96) | 0 % / 39 % / 58 % / 2 % | 116 (109–123) | 4.95 | 8 | 9335 (9019–9656) |
| `expert_6x` | 150 / 0 / 5 | 59 (38–98) | 1 % / 75 % / 24 % / 1 % | 174 (166–183) | 5.12 | 8 | 11993 (11609–12316) |
| `irregulier_3x` | 28.6 / 0 / 126.4 | 3 (2–4) | 19 % / 10 % / 58 % / 14 % | 49 (45–54) | 4.92 | 8 | 5258 (4955–5600) |
| `vacances_5x` | 127.7 / 11 / 16.3 | 25 (18–40) | 10 % / 25 % / 60 % / 6 % | 127 (119–134) | 5 | 8 | 10530 (10095–10849) |
| `maladie_3x` | 90.8 / 9.7 / 54.5 | 9 (6–12) | 0 % / 1 % / 89 % / 10 % | 75 (69–82) | 4.91 | 8 | 8302 (7949–8622) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5836 | 933 | 518 | 226 | 0 |
| `debutant_3x` | 5840 | 1493 | 592 | 197 | 100 |
| `intermediaire_4x` | 6514 | 1969 | 681 | 453 | 45 |
| `avance_street_4x` | 6149 | 2010 | 668 | 440 | 70 |
| `expert_6x` | 7162 | 3018 | 1300 | 442 | 66 |
| `irregulier_3x` | 3951 | 856 | 449 | 2 | 13 |
| `vacances_5x` | 6902 | 2189 | 1065 | 328 | 11 |
| `maladie_3x` | 6256 | 1306 | 586 | 144 | 0 |

## 6. Avancements

Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).

| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 17.7 (18) | 8.4 (8.4) | 3.5 (3.6) | 1 (12.2) | 69.6 (100) | 71.7 (100) | 0 | 0 |
| `debutant_3x` | 36.7 (39) | 12.4 (12.4) | 7.3 (7.8) | 11.8 (14.3) | 7.8 (37.3) | 75.6 (100) | 38 | 6 |
| `intermediaire_4x` | 41.1 (50) | 27.9 (27.9) | 8.2 (10) | 11.4 (14) | 82.4 (97.1) | 91.7 (98.3) | 15.2 | 6.3 |
| `avance_street_4x` | 54 (56.7) | 27 (27) | 38.4 (41.6) | 50.5 (56.3) | 7.3 (30.6) | 93.3 (98.3) | 27.5 | 8 |
| `expert_6x` | 57 (59.5) | 1 (1) | 11.4 (11.9) | 20.1 (23) | 1 (15.9) | 96.7 (100) | 25.9 | 5.1 |
| `irregulier_3x` | 18 (18) | 19 (19) | 3.6 (3.6) | 7.6 (20.6) | 46.8 (72.3) | 31.1 (65.6) | 4.5 | 1 |
| `vacances_5x` | 30 (41.5) | 19.8 (21) | 51 (53.3) | 26.1 (31.3) | 68.1 (94.5) | 80.9 (97.3) | 3.7 | 2.2 |
| `maladie_3x` | 12 (12) | 8.4 (8.4) | 2.4 (2.4) | 1 (14) | 99 (100) | 70.6 (91.1) | 0 | 0 |

## 7. Garde-fous mesurés

| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d'effort / plafond | Niveau en baisse | Écritures d'XP |
| --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 0 | 0 | 0 | 0.964 | jamais | 1761 |
| `debutant_3x` | 0 | 0 | 0 | 0.964 | jamais | 2105 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.98 | jamais | 2364 |
| `avance_street_4x` | 0 | 0 | 0 | 0.982 | jamais | 2425 |
| `expert_6x` | 0 | 0 | 0 | 0.976 | jamais | 3120 |
| `irregulier_3x` | 0 | 0 | 0 | 1 | jamais | 1423 |
| `vacances_5x` | 0 | 0 | 0 | 1 | jamais | 2578 |
| `maladie_3x` | 2.8 | 0 | 0 | 0.994 | jamais | 2054 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 74671 (72811–76475) | 76727 (76246–77271) | 2148 | 37022 | 42671 | 452.1 | 0.97 |
| `intermediaire_4x` | 94230 (92433–95885) | 100698 (100227–101276) | 6513 | 53087 | 61426 | 314.4 | 1 |

Les séances en plus du tricheur prennent la place des séances prévues qu'il manque : son XP d'effort monte jusqu'au plafond du programme, jamais au-delà. Face au même programme fait en entier (assiduité parfaite), le surentraînement ne rapporte rien :

| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |
| --- | --- | --- | --- | --- |
| `debutant_3x` | 50 | 86117 | 76742 | -8373 |
| `intermediaire_4x` | 50 | 107924 | 100940 | -6638 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 71.9 ms | 95.7 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 12.7 ms | 14.9 ms | ≤ 200 ms |
