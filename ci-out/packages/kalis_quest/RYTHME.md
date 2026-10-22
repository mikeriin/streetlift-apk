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
| `debutant_3x` | 5 (4–6) | 10 (9–11) | 23 (21–24) | 33 (32–34) | 48 (47–49) | 70 (69–71) | 87 (86–88) |
| `intermediaire_4x` | 6 (5–7) | 11 (10–12) | 26 (25–28) | 38 (37–39) | 55 (54–56) | 80 (79–81) | 100 (99–104) |
| `avance_street_4x` | 6 (5–7) | 11 (11–12) | 27 (26–27) | 38 (37–39) | 55 (54–56) | 79 (78–80) | 98 (97–99) |
| `expert_6x` | 8 (7–8) | 14 (13–15) | 32 (31–32) | 46 (45–46) | 66 (65–67) | 96 (95–97) | 160 (158–161) |
| `irregulier_3x` | 4 (3–5) | 8 (6–9) | 19 (17–20) | 26 (24–27) | 37 (36–39) | 54 (52–56) | 67 (65–69) |
| `vacances_5x` | 7 (6–8) | 13 (12–14) | 29 (27–30) | 42 (40–42) | 58 (57–59) | 84 (83–85) | 124 (120–129) |
| `maladie_3x` | 6 (4–6) | 10 (9–12) | 22 (21–24) | 33 (32–35) | 48 (47–49) | 70 (68–71) | 86 (85–88) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (3–5) | 18 (16–20.1) | 69 (65–73) | jamais en 156 sem. |
| `debutant_3x` | 3 (3–4) | 15 (14–17) | 55 (53–58) | jamais en 156 sem. |
| `intermediaire_4x` | 3 (2–3) | 12 (11–13) | 43 (41–44) | 155 (153–156) — 112/200 graines |
| `avance_street_4x` | 3 (2–3) | 12 (11–13) | 43 (42–45) | 156 (155–156) — 13/200 graines |
| `expert_6x` | 2 (2–2) | 9 (8–9) | 31 (30–31) | 112 (110–114) |
| `irregulier_3x` | 4 (4–5) | 24 (19–27) | 87 (82.9–92) | jamais en 156 sem. |
| `vacances_5x` | 2 (2–3) | 10 (9–11) | 39 (38–41) | 144 (141–147) |
| `maladie_3x` | 3 (3–4) | 16 (14–17) | 55 (53–58) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (50 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 55 (53–57) sem. — 50/50 graines | 200 (195–203.1) sem. — 50/50 graines | 113 (106–119) |
| `intermediaire_4x` | 43 (41–44.1) sem. — 50/50 graines | 156 (153–159.1) sem. — 50/50 graines | 154 (152–156) |

### Courbe médiane (niveau global, toutes les 12 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 20 | 29 | 35 | 41 | 46 | 51 | 55 | 59 | 63 | 67 | 70 | 73 | 77 |
| `debutant_3x` | 22 | 32 | 40 | 46 | 52 | 57 | 62 | 67 | 71 | 76 | 80 | 83 | 87 |
| `intermediaire_4x` | 25 | 37 | 46 | 53 | 60 | 66 | 71 | 77 | 82 | 87 | 91 | 95 | 100 |
| `avance_street_4x` | 25 | 37 | 45 | 53 | 59 | 65 | 71 | 76 | 81 | 86 | 90 | 94 | 98 |
| `expert_6x` | 30 | 44 | 54 | 63 | 71 | 79 | 85 | 92 | 98 | 122 | 138 | 150 | 160 |
| `irregulier_3x` | 18 | 25 | 32 | 35 | 41 | 45 | 49 | 53 | 55 | 59 | 62 | 65 | 67 |
| `vacances_5x` | 27 | 40 | 47 | 56 | 63 | 70 | 75 | 80 | 86 | 91 | 96 | 100 | 124 |
| `maladie_3x` | 21 | 32 | 40 | 46 | 52 | 57 | 62 | 67 | 71 | 75 | 79 | 82 | 86 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 58233 (55960–60368) | 373.2 | 40 % | 24 % | 0 % | 0 % | 36 % |
| `debutant_3x` | 74163 (72387–76053) | 475.8 | 50 % | 20 % | 1 % | 0 % | 29 % |
| `intermediaire_4x` | 95313 (93365–97075) | 610.8 | 57 % | 17 % | 0 % | 0 % | 26 % |
| `avance_street_4x` | 93131 (91257–94795) | 596.7 | 56 % | 17 % | 1 % | 0 % | 26 % |
| `expert_6x` | 133158 (131678–134778) | 853.5 | 65 % | 13 % | 0 % | 0 % | 22 % |
| `irregulier_3x` | 45569 (43328–47823) | 292.2 | 49 % | 18 % | 0 % | 0 % | 33 % |
| `vacances_5x` | 103663 (101644–106028) | 664.9 | 62 % | 14 % | 0 % | 0 % | 25 % |
| `maladie_3x` | 72794 (70698–74776) | 466.6 | 51 % | 18 % | 0 % | 0 % | 32 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 941.2 / 1949 (48 %) | 177.4 / 312 (57 %) | 64.9 / 78 (83 %) | 63 / 156 (40 %) |
| `debutant_3x` | 1138.9 / 2105 (54 %) | 164.2 / 312 (53 %) | 60 / 64 (94 %) | 44.4 / 156 (28 %) |
| `intermediaire_4x` | 1249.5 / 2260.2 (55 %) | 179.9 / 312 (58 %) | 61.6 / 64 (96 %) | 54.6 / 156 (35 %) |
| `avance_street_4x` | 1334.8 / 2260.2 (59 %) | 163.5 / 312 (52 %) | 51.9 / 52 (100 %) | 50.7 / 156 (33 %) |
| `expert_6x` | 1756.9 / 2572.1 (68 %) | 166 / 312 (53 %) | 52 / 52 (100 %) | 42 / 156 (27 %) |
| `irregulier_3x` | 805.2 / 2104 (38 %) | 116.7 / 312 (37 %) | 39.4 / 78 (50 %) | 51.8 / 156 (33 %) |
| `vacances_5x` | 1412.9 / 2314.8 (61 %) | 151.6 / 288 (53 %) | 58.9 / 64 (92 %) | 63.8 / 144 (44 %) |
| `maladie_3x` | 1166.8 / 2045.4 (57 %) | 164.8 / 300 (55 %) | 63.8 / 78 (82 %) | 65.8 / 150 (44 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 111.7 / 0 / 43.3 | 12 (9–18) | 0 % / 1 % / 94 % / 5 % | 54 (48–59) | 4.9 | 8 | 7516 (7134–7897) |
| `debutant_3x` | 113 / 0 / 42.1 | 13 (9–17) | 0 % / 31 % / 63 % / 6 % | 86 (79–93) | 4.9 | 8 | 8186 (7895–8519) |
| `intermediaire_4x` | 147 / 0 / 8 | 44 (31–68) | 1 % / 33 % / 62 % / 4 % | 114 (106–120) | 4.95 | 8 | 9627 (9296–10076) |
| `avance_street_4x` | 149.7 / 0 / 5.3 | 58 (39–96) | 1 % / 38 % / 60 % / 2 % | 116 (109–123) | 4.95 | 8 | 9320 (9001–9668) |
| `expert_6x` | 150 / 0 / 5 | 59 (38–98) | 1 % / 78 % / 21 % / 1 % | 174 (166–183) | 5.12 | 8 | 12000 (11603–12328) |
| `irregulier_3x` | 28.6 / 0 / 126.4 | 3 (2–4) | 18 % / 11 % / 57 % / 14 % | 49 (45–54) | 4.92 | 8 | 5298 (4998–5644) |
| `vacances_5x` | 127.7 / 11 / 16.3 | 25 (18–40) | 10 % / 19 % / 64 % / 7 % | 127 (119–134) | 5 | 8 | 10232 (9850–10585) |
| `maladie_3x` | 90.8 / 9.7 / 54.5 | 9 (6–12) | 0 % / 1 % / 89 % / 10 % | 75 (69–82) | 4.91 | 8 | 8302 (7949–8622) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5836 | 933 | 518 | 226 | 0 |
| `debutant_3x` | 5825 | 1493 | 591 | 197 | 90 |
| `intermediaire_4x` | 6485 | 1969 | 716 | 453 | 37 |
| `avance_street_4x` | 6141 | 2010 | 668 | 440 | 72 |
| `expert_6x` | 7164 | 3018 | 1298 | 442 | 66 |
| `irregulier_3x` | 3979 | 856 | 453 | 2 | 13 |
| `vacances_5x` | 6639 | 2189 | 1051 | 328 | 9 |
| `maladie_3x` | 6256 | 1306 | 586 | 144 | 0 |

## 6. Avancements

Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).

| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 17.7 (18) | 8.4 (8.4) | 3.5 (3.6) | 1 (12.2) | 69.6 (100) | 71.7 (100) | 0 | 0 |
| `debutant_3x` | 30.4 (32.5) | 12.4 (12.4) | 6.1 (6.5) | 10.6 (13.5) | 7.8 (37.3) | 75.6 (100) | 32.9 | 3.9 |
| `intermediaire_4x` | 32.9 (36) | 1 (1) | 6.6 (7.2) | 12.1 (14.2) | 79.5 (92.5) | 91.7 (98.3) | 13 | 5.2 |
| `avance_street_4x` | 53.9 (57.1) | 27 (27) | 38.3 (41.7) | 50.2 (56.1) | 7.3 (30.6) | 93.3 (98.3) | 27.9 | 10 |
| `expert_6x` | 56.7 (59.7) | 1 (1) | 11.3 (11.9) | 20.5 (22.8) | 1 (15.9) | 96.7 (100) | 25.2 | 5.1 |
| `irregulier_3x` | 18 (18) | 19 (19) | 3.6 (3.6) | 22.5 (35.9) | 44.8 (73.6) | 31.1 (65.6) | 4.3 | 1 |
| `vacances_5x` | 30 (41.5) | 23.5 (24.8) | 60 (62.3) | 25.2 (30.1) | 72 (91.2) | 80.9 (97.3) | 3.1 | 2.2 |
| `maladie_3x` | 12 (12) | 8.4 (8.4) | 2.4 (2.4) | 1 (14) | 99 (100) | 70.6 (91.1) | 0 | 0 |

## 7. Garde-fous mesurés

| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d'effort / plafond | Niveau en baisse | Écritures d'XP |
| --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 0 | 0 | 0 | 0.964 | jamais | 1761 |
| `debutant_3x` | 0 | 0 | 0 | 0.973 | jamais | 2096 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.984 | jamais | 2346 |
| `avance_street_4x` | 0 | 0 | 0 | 0.977 | jamais | 2421 |
| `expert_6x` | 0 | 0 | 0 | 0.973 | jamais | 3120 |
| `irregulier_3x` | 0 | 0 | 0 | 1 | jamais | 1440 |
| `vacances_5x` | 0 | 0 | 0 | 0.995 | jamais | 2518 |
| `maladie_3x` | 2.8 | 0 | 0 | 0.994 | jamais | 2054 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 74163 (72387–76053) | 76088 (75562–76614) | 1865 | 36740 | 42177 | 452.1 | 0.988 |
| `intermediaire_4x` | 95313 (93365–97075) | 101645 (101118–102194) | 6407 | 54415 | 62380 | 314.4 | 1 |

Les séances en plus du tricheur prennent la place des séances prévues qu'il manque : son XP d'effort monte jusqu'au plafond du programme, jamais au-delà. Face au même programme fait en entier (assiduité parfaite), le surentraînement ne rapporte rien :

| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |
| --- | --- | --- | --- | --- |
| `debutant_3x` | 50 | 85615 | 75851 | -8965 |
| `intermediaire_4x` | 50 | 109426 | 101991 | -7035 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 40.2 ms | 61.3 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 7.1 ms | 8.7 ms | ≤ 200 ms |
