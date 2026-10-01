# Simulation de rythme — kalis_quest 0.1.0

Document généré par `dart run bin/kalis_quest_cli.dart --rapport <dossier>` (mise en tableaux de `docs/data/campagne.json`). 8 archétypes × 24 graines × 156 semaines ; le moteur est appelé à la fin de chaque semaine avec le bloc en cours de `kalis_plan`. Valeurs : médiane (10ᵉ–90ᵉ centile) sur les graines, ou moyenne quand un seul nombre est donné. Lecture et limites : `VALIDATION.md`.

## 1. Archétypes

| Archétype | Profil type | Séances prévues / sem. | Séances récompensées / sem. | Ce qu'il représente |
| --- | --- | --- | --- | --- |
| `debutant_2x` | `debutant_forme_generale_maison_2x30` | 2 | 1.7 | Débutant, 2 séances de 30 min par semaine à la maison. |
| `debutant_3x` | `homme_25_musculation_debutant_3x60` | 3 | 2.71 | Débutant régulier, 3 séances par semaine en salle (repère). |
| `intermediaire_4x` | `femme_45_musculation_salle_4x60` | 4 | 3.6 | Intermédiaire régulière, 4 séances par semaine (repère). |
| `avance_street_4x` | `street_streetlifting_4x90` | 4 | 3.68 | Avancé en streetlifting, 4 séances de 90 min par semaine. |
| `expert_6x` | `six_jours_musculation_avance_6x75` | 6 | 5.7 | Expert, 6 séances par semaine. |
| `irregulier_3x` | `femme_30_street_workout_parc_3x45` | 3 | 1.55 | Irrégulière : 3 séances prévues, 60 % faites, deux arrêts non déclarés de 3 et 4 semaines par an. |
| `vacances_5x` | `crossfit_5x60` | 4.62 | 4.05 | 5 séances par semaine, vacances déclarées : 3 semaines l'été, 1 semaine l'hiver. |
| `maladie_3x` | `senior_65_forme_generale_3x40` | 2.81 | 2.38 | Senior, 3 séances par semaine, deux maladies déclarées de 10 jours par an, douleur déclarée avant 8 % des séances (dont 30 % faites quand même sans épargner la zone). |

## 2. Niveau dans le temps

| Archétype | Sem. 1 | Sem. 3 | Sem. 13 | Sem. 26 | Sem. 52 | Sem. 104 | Sem. 156 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5 (3–5) | 9 (8–10) | 21 (19–22) | 30 (29–31) | 43 (42–44) | 62 (61–63) | 76 (76–78) |
| `debutant_3x` | 5 (4–6) | 10 (9–11) | 23 (22–24) | 33 (32–35) | 49 (47–50) | 70 (69–71) | 88 (87–89) |
| `intermediaire_4x` | 6 (5–6) | 11 (10–12) | 26 (25–27) | 38 (36–39) | 55 (54–56) | 80 (79–81) | 99 (98–100) |
| `avance_street_4x` | 6 (5–7) | 11 (11–12) | 27 (26–27) | 38 (37–39) | 55 (54–56) | 79 (78–81) | 98 (97–99) |
| `expert_6x` | 8 (7–8) | 14 (13–15) | 32 (31–32) | 46 (45–46) | 66 (65–67) | 96 (95–97) | 160 (158–161) |
| `irregulier_3x` | 4 (3–5) | 8 (6–9) | 19 (17–21) | 26 (24–27) | 37 (35–39) | 54 (53–55) | 67 (65–68) |
| `vacances_5x` | 7 (6–7) | 13 (12–14) | 29 (27–30) | 42 (41–43) | 59 (57–59) | 84 (83–85) | 126 (123–131) |
| `maladie_3x` | 5 (4–6) | 11 (9–12) | 23 (21–24) | 33 (33–35) | 48 (47–50) | 70 (69–71) | 86 (86–88) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (3–4) | 18 (17–20) | 70 (65.6–72.4) | jamais en 156 sem. |
| `debutant_3x` | 3 (3–4) | 15 (14–16) | 55 (52–57) | jamais en 156 sem. |
| `intermediaire_4x` | 3 (2–3) | 12 (11–13) | 43 (42–44) | 154.5 (153.3–155.7) — 4/24 graines |
| `avance_street_4x` | 3 (2–3) | 12 (11–12.7) | 43 (41.3–44) | 155.5 (155.1–155.9) — 2/24 graines |
| `expert_6x` | 2 (2–2) | 9 (8–9) | 30 (30–31) | 112 (110.3–113.7) |
| `irregulier_3x` | 4 (4–5) | 24 (20–26.7) | 88 (84–92) | jamais en 156 sem. |
| `vacances_5x` | 2 (2–3) | 10 (9–11) | 39 (37.3–40) | 143 (140–145) |
| `maladie_3x` | 3 (3–4) | 16 (14.3–16.7) | 55 (52–57) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (24 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 55 (52–57) sem. — 24/24 graines | 198.5 (194.3–202.7) sem. — 24/24 graines | 116 (110–121) |
| `intermediaire_4x` | 43 (42–44) sem. — 24/24 graines | 158 (155.3–160.7) sem. — 24/24 graines | 152 (150–154) |

### Courbe médiane (niveau global, toutes les 13 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 20 | 29 | 35 | 41 | 46 | 51 | 55 | 59 | 63 | 67 | 70 | 73 | 76 |
| `debutant_3x` | 22 | 32 | 40 | 47 | 52 | 58 | 63 | 68 | 72 | 76 | 80 | 84 | 88 |
| `intermediaire_4x` | 25 | 37 | 45 | 53 | 60 | 65 | 71 | 76 | 81 | 86 | 90 | 95 | 99 |
| `avance_street_4x` | 25 | 37 | 46 | 53 | 60 | 65 | 71 | 76 | 81 | 86 | 90 | 94 | 98 |
| `expert_6x` | 30 | 44 | 55 | 64 | 72 | 79 | 86 | 92 | 98 | 122 | 138 | 150 | 160 |
| `irregulier_3x` | 18 | 25 | 32 | 35 | 40 | 45 | 49 | 52 | 55 | 59 | 62 | 65 | 67 |
| `vacances_5x` | 28 | 40 | 48 | 56 | 63 | 70 | 75 | 81 | 86 | 91 | 96 | 100 | 126 |
| `maladie_3x` | 22 | 32 | 40 | 46 | 52 | 57 | 62 | 67 | 71 | 75 | 79 | 83 | 86 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 57978 (56972–60677) | 373.9 | 40 % | 24 % | 0 % | 0 % | 36 % |
| `debutant_3x` | 74715 (73722–76884) | 480.5 | 50 % | 20 % | 1 % | 0 % | 29 % |
| `intermediaire_4x` | 94078 (92380–95933) | 603.3 | 56 % | 17 % | 0 % | 0 % | 26 % |
| `avance_street_4x` | 92978 (91501–94751) | 596.2 | 56 % | 17 % | 1 % | 0 % | 26 % |
| `expert_6x` | 133411 (131607–134286) | 853.8 | 65 % | 13 % | 0 % | 0 % | 22 % |
| `irregulier_3x` | 45335 (42316–46616) | 286.9 | 49 % | 18 % | 0 % | 0 % | 33 % |
| `vacances_5x` | 104450 (102906–107222) | 671.7 | 61 % | 14 % | 0 % | 0 % | 26 % |
| `maladie_3x` | 72847 (71668–75055) | 469.3 | 51 % | 18 % | 0 % | 0 % | 32 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 943.5 / 1950.8 (48 %) | 178.8 / 312 (57 %) | 64.8 / 78 (83 %) | 63.3 / 156 (41 %) |
| `debutant_3x` | 1144.5 / 2106 (54 %) | 165.5 / 312 (53 %) | 60.1 / 64 (94 %) | 46.3 / 156 (30 %) |
| `intermediaire_4x` | 1266.4 / 2262.3 (56 %) | 182 / 312 (58 %) | 61.8 / 64 (97 %) | 52.1 / 156 (33 %) |
| `avance_street_4x` | 1347.1 / 2262.3 (60 %) | 161.3 / 312 (52 %) | 52 / 52 (100 %) | 50.4 / 156 (32 %) |
| `expert_6x` | 1764.3 / 2576.8 (69 %) | 165.1 / 312 (53 %) | 52 / 52 (100 %) | 41.8 / 156 (27 %) |
| `irregulier_3x` | 788.8 / 2105.1 (38 %) | 118.2 / 312 (38 %) | 39.3 / 78 (50 %) | 50.1 / 156 (32 %) |
| `vacances_5x` | 1458.5 / 2320.2 (63 %) | 170.8 / 288 (59 %) | 58.8 / 64 (92 %) | 63.5 / 144 (44 %) |
| `maladie_3x` | 1170.3 / 2045.8 (57 %) | 166.2 / 300 (55 %) | 64.5 / 78 (83 %) | 65.8 / 150 (44 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 112 / 0 / 43 | 13 (10–17) | 0 % / 1 % / 94 % / 4 % | 53 (48–59) | 4.92 | 8 | 7494 (7189–7964) |
| `debutant_3x` | 114 / 0 / 41 | 14 (9–17) | 0 % / 33 % / 62 % / 5 % | 85 (79–90) | 5 | 8 | 8251 (7916–8610) |
| `intermediaire_4x` | 147.1 / 0 / 7.9 | 49 (31–64) | 0 % / 34 % / 61 % / 4 % | 114 (108–120) | 4.93 | 8 | 9719 (9357–9929) |
| `avance_street_4x` | 150 / 0 / 5 | 57 (43–108) | 0 % / 39 % / 58 % / 2 % | 116 (110–126) | 4.93 | 8 | 9342 (9064–9671) |
| `expert_6x` | 149.8 / 0 / 5.3 | 65 (40–90) | 1 % / 75 % / 23 % / 1 % | 173 (165–183) | 5.14 | 8 | 12028 (11579–12461) |
| `irregulier_3x` | 28.5 / 0 / 126.5 | 3 (2–4) | 19 % / 10 % / 57 % / 14 % | 50 (46–54) | 4.85 | 8 | 5282 (5037–5523) |
| `vacances_5x` | 127 / 11 / 17 | 25 (16–34) | 10 % / 25 % / 60 % / 6 % | 125 (119–133) | 5.03 | 8 | 10555 (10145–10975) |
| `maladie_3x` | 91.7 / 9.8 / 53.5 | 9 (7–12) | 0 % / 1 % / 89 % / 9 % | 74 (68–82) | 5.02 | 8 | 8327 (7943–8748) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5851 | 953 | 518 | 226 | 0 |
| `debutant_3x` | 5874 | 1506 | 593 | 201 | 98 |
| `intermediaire_4x` | 6519 | 2004 | 682 | 452 | 45 |
| `avance_street_4x` | 6139 | 2038 | 669 | 446 | 71 |
| `expert_6x` | 7166 | 3073 | 1300 | 423 | 63 |
| `irregulier_3x` | 3933 | 885 | 448 | 3 | 14 |
| `vacances_5x` | 6912 | 2253 | 1065 | 331 | 11 |
| `maladie_3x` | 6305 | 1295 | 588 | 148 | 0 |

## 6. Avancements

Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).

| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 17.7 (18) | 8.4 (8.4) | 3.5 (3.6) | 1 (10.9) | 68.6 (100) | 70 (100) | 0 | 0 |
| `debutant_3x` | 35.4 (38.8) | 12.4 (12.4) | 7.1 (7.8) | 12.5 (14.3) | 7.9 (37.5) | 75 (100) | 38 | 6 |
| `intermediaire_4x` | 40.6 (49.6) | 27.9 (27.9) | 8.1 (9.9) | 11.5 (14.1) | 83.3 (96.9) | 91.7 (98.3) | 15.3 | 6.3 |
| `avance_street_4x` | 54.4 (56.7) | 27 (27) | 38.3 (41.5) | 50.5 (56.3) | 7 (31.2) | 93.3 (99.2) | 28 | 8 |
| `expert_6x` | 56.9 (59.9) | 1 (1) | 11.4 (12) | 20.6 (23.2) | 1 (16) | 95 (100) | 24.8 | 5 |
| `irregulier_3x` | 18 (18) | 19 (19) | 3.6 (3.6) | 9.4 (20.7) | 40.9 (73) | 28.9 (64.5) | 4.5 | 1 |
| `vacances_5x` | 35.7 (42.6) | 19.8 (21) | 52.1 (53.5) | 25.8 (31.4) | 63.6 (93.9) | 81.3 (97.3) | 3.7 | 2.3 |
| `maladie_3x` | 12 (12) | 8.4 (8.4) | 2.4 (2.4) | 1 (11.3) | 94.2 (100) | 68.9 (92.2) | 0 | 0 |

## 7. Garde-fous mesurés

| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d'effort / plafond | Niveau en baisse | Écritures d'XP |
| --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 0 | 0 | 0 | 0.964 | jamais | 1764 |
| `debutant_3x` | 0 | 0 | 0 | 0.948 | jamais | 2110 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.97 | jamais | 2364 |
| `avance_street_4x` | 0 | 0 | 0 | 0.975 | jamais | 2430 |
| `expert_6x` | 0 | 0 | 0 | 0.974 | jamais | 3125 |
| `irregulier_3x` | 0 | 0 | 0 | 0.988 | jamais | 1422 |
| `vacances_5x` | 0 | 0 | 0 | 1 | jamais | 2582 |
| `maladie_3x` | 2.7 | 0 | 0 | 0.994 | jamais | 2060 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 74715 (73722–76884) | 76920 (76440–77255) | 2121 | 37156 | 42691 | 452.4 | 0.97 |
| `intermediaire_4x` | 94078 (92380–95933) | 100822 (100348–101315) | 6668 | 53020 | 61428 | 314.8 | 0.993 |

Les séances en plus du tricheur prennent la place des séances prévues qu'il manque : son XP d'effort monte jusqu'au plafond du programme, jamais au-delà. Face au même programme fait en entier (assiduité parfaite), le surentraînement ne rapporte rien :

| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |
| --- | --- | --- | --- | --- |
| `debutant_3x` | 24 | 86165 | 76741 | -8583 |
| `intermediaire_4x` | 24 | 107928 | 100931 | -6652 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 70.3 ms | 80.3 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 12.5 ms | 14.3 ms | ≤ 200 ms |
