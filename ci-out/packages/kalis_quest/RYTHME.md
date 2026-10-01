# Simulation de rythme — kalis_quest 0.1.0

Document généré par `dart run bin/kalis_quest_cli.dart --rapport <dossier>` (mise en tableaux de `docs/data/campagne.json`). 8 archétypes × 4 graines × 156 semaines ; le moteur est appelé à la fin de chaque semaine avec le bloc en cours de `kalis_plan`. Valeurs : médiane (10ᵉ–90ᵉ centile) sur les graines, ou moyenne quand un seul nombre est donné. Lecture et limites : `VALIDATION.md`.

## 1. Archétypes

| Archétype | Profil type | Séances prévues / sem. | Séances récompensées / sem. | Ce qu'il représente |
| --- | --- | --- | --- | --- |
| `debutant_2x` | `debutant_forme_generale_maison_2x30` | 2 | 1.7 | Débutant, 2 séances de 30 min par semaine à la maison. |
| `debutant_3x` | `homme_25_musculation_debutant_3x60` | 3 | 2.69 | Débutant régulier, 3 séances par semaine en salle (repère). |
| `intermediaire_4x` | `femme_45_musculation_salle_4x60` | 4 | 3.58 | Intermédiaire régulière, 4 séances par semaine (repère). |
| `avance_street_4x` | `street_streetlifting_4x90` | 4 | 3.66 | Avancé en streetlifting, 4 séances de 90 min par semaine. |
| `expert_6x` | `six_jours_musculation_avance_6x75` | 6 | 5.67 | Expert, 6 séances par semaine. |
| `irregulier_3x` | `femme_30_street_workout_parc_3x45` | 3 | 1.49 | Irrégulière : 3 séances prévues, 60 % faites, deux arrêts non déclarés de 3 et 4 semaines par an. |
| `vacances_5x` | `crossfit_5x60` | 4.62 | 4.03 | 5 séances par semaine, vacances déclarées : 3 semaines l'été, 1 semaine l'hiver. |
| `maladie_3x` | `senior_65_forme_generale_3x40` | 2.81 | 2.35 | Senior, 3 séances par semaine, deux maladies déclarées de 10 jours par an, douleur déclarée avant 8 % des séances (dont 30 % faites quand même sans épargner la zone). |

## 2. Niveau dans le temps

| Archétype | Sem. 1 | Sem. 3 | Sem. 13 | Sem. 26 | Sem. 52 | Sem. 104 | Sem. 156 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (2–4) | 7 (6–8) | 19 (17–20) | 28 (26–29) | 41 (39–42) | 62 (60–63) | 77 (75–78) |
| `debutant_3x` | 4 (4–5) | 9 (8–9) | 19 (19–20) | 29 (28–30) | 45 (44–46) | 67 (67–68) | 85 (84–85) |
| `intermediaire_4x` | 4 (4–5) | 10 (8–10) | 23 (22–24) | 35 (34–36) | 52 (51–53) | 77 (76–78) | 97 (96–98) |
| `avance_street_4x` | 5 (4–5) | 10 (9–10) | 23 (22–23) | 34 (33–35) | 51 (49–52) | 74 (74–75) | 93 (93–95) |
| `expert_6x` | 6 (5–6) | 12 (11–12) | 28 (27–29) | 42 (41–43) | 63 (62–64) | 93 (93–94) | 151 (151–153) |
| `irregulier_3x` | 3 (2–4) | 7 (6–7) | 16 (15–17) | 23 (21–23) | 32 (31–33) | 49 (48–50) | 61 (60–62) |
| `vacances_5x` | 6 (5–6) | 11 (10–12) | 26 (24–27) | 38 (37–39) | 55 (54–56) | 82 (80–83) | 114 (111–122) |
| `maladie_3x` | 5 (5–5) | 10 (9–10) | 20 (19–21) | 30 (29–31) | 46 (44–47) | 69 (67–69) | 86 (85–87) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 5 (4.3–6.4) | 21.5 (21–23.4) | 74 (69.8–76.8) | jamais en 156 sem. |
| `debutant_3x` | 4 (4–4.7) | 20 (18.6–20.7) | 63.5 (60.9–64) | jamais en 156 sem. |
| `intermediaire_4x` | 3.5 (3–4) | 15 (14.3–15.7) | 48.5 (46.6–50.4) | jamais en 156 sem. |
| `avance_street_4x` | 3.5 (3–4) | 15.5 (15–16) | 51 (48.6–52.7) | jamais en 156 sem. |
| `expert_6x` | 3 (2.3–3) | 11 (11–11) | 35.5 (34.3–36.7) | 117.5 (115.6–118.7) |
| `irregulier_3x` | 5.5 (5–6) | 30 (28.3–34.5) | 105.5 (102.2–107.4) | jamais en 156 sem. |
| `vacances_5x` | 3 (3–3) | 12.5 (12–13.7) | 44.5 (41.9–45.7) | 149 (144.5–150) |
| `maladie_3x` | 3.5 (3–4) | 19 (16.9–19) | 61.5 (56.5–64.4) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (4 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 63.5 (60.9–64) sem. — 4/4 graines | 205 (203.4–206.6) sem. — 3/4 graines | 100 (99–106) |
| `intermediaire_4x` | 48.5 (46.6–50.4) sem. — 4/4 graines | 163 (158.5–164.7) sem. — 4/4 graines | 147 (146–150) |

### Courbe médiane (niveau global, toutes les 13 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 18 | 27 | 34 | 39 | 44 | 49 | 54 | 58 | 63 | 66 | 70 | 74 | 77 |
| `debutant_3x` | 19 | 27 | 36 | 43 | 48 | 54 | 60 | 65 | 69 | 73 | 77 | 81 | 85 |
| `intermediaire_4x` | 22 | 33 | 42 | 50 | 56 | 62 | 68 | 74 | 79 | 84 | 89 | 93 | 97 |
| `avance_street_4x` | 22 | 33 | 42 | 49 | 55 | 61 | 67 | 71 | 76 | 81 | 85 | 89 | 93 |
| `expert_6x` | 27 | 40 | 51 | 60 | 68 | 76 | 83 | 89 | 95 | 108 | 128 | 141 | 151 |
| `irregulier_3x` | 15 | 21 | 28 | 31 | 36 | 40 | 44 | 48 | 50 | 54 | 56 | 60 | 61 |
| `vacances_5x` | 25 | 36 | 44 | 53 | 60 | 67 | 72 | 78 | 84 | 89 | 94 | 98 | 114 |
| `maladie_3x` | 19 | 29 | 38 | 44 | 50 | 55 | 60 | 65 | 70 | 74 | 78 | 81 | 86 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 61465 (59526–63534) | 394.3 | 33 % | 23 % | 0 % | 0 % | 44 % |
| `debutant_3x` | 73332 (72670–73706) | 469.4 | 45 % | 20 % | 1 % | 0 % | 34 % |
| `intermediaire_4x` | 92462 (91622–95256) | 597.2 | 52 % | 17 % | 0 % | 0 % | 31 % |
| `avance_street_4x` | 86170 (85807–89083) | 558.2 | 53 % | 18 % | 1 % | 0 % | 28 % |
| `expert_6x` | 128624 (128210–130724) | 828.4 | 63 % | 13 % | 0 % | 0 % | 24 % |
| `irregulier_3x` | 40786 (40188–42777) | 264.6 | 47 % | 19 % | 0 % | 0 % | 34 % |
| `vacances_5x` | 101787 (100542–105268) | 657.6 | 59 % | 14 % | 0 % | 0 % | 27 % |
| `maladie_3x` | 74259 (73600–75926) | 478.3 | 47 % | 18 % | 0 % | 0 % | 36 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 935.3 / 1955 (48 %) | 173.8 / 312 (56 %) | 67 / 78 (86 %) | 95.5 / 156 (61 %) |
| `debutant_3x` | 1124 / 2107.3 (53 %) | 134.3 / 312 (43 %) | 60 / 64 (94 %) | 59.8 / 156 (38 %) |
| `intermediaire_4x` | 1253.8 / 2268.3 (55 %) | 163.5 / 312 (52 %) | 61.3 / 64 (96 %) | 64.3 / 156 (41 %) |
| `avance_street_4x` | 1335.3 / 2268.3 (59 %) | 125.5 / 312 (40 %) | 51.8 / 52 (100 %) | 7 / 156 (5 %) |
| `expert_6x` | 1758.3 / 2576.5 (68 %) | 118.3 / 312 (38 %) | 52 / 52 (100 %) | 59.8 / 156 (38 %) |
| `irregulier_3x` | 769.5 / 2111.3 (36 %) | 62.3 / 312 (20 %) | 36.3 / 78 (47 %) | 47 / 156 (30 %) |
| `vacances_5x` | 1451.8 / 2322.5 (63 %) | 127 / 288 (44 %) | 54 / 64 (84 %) | 54.3 / 144 (38 %) |
| `maladie_3x` | 1154.5 / 2049.5 (56 %) | 148.8 / 300 (50 %) | 61.3 / 78 (79 %) | 73 / 150 (49 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 112.5 / 0 / 42.5 | 14 (12–17) | 0 % / 1 % / 90 % / 9 % | 58 (51–64) | 4.62 | 8 | 7984 (7658–8359) |
| `debutant_3x` | 110.8 / 0 / 44.3 | 15 (11–16) | 1 % / 14 % / 78 % / 7 % | 84 (75–89) | 5.1 | 8 | 7913 (7697–8229) |
| `intermediaire_4x` | 144.8 / 0 / 10.3 | 47 (33–50) | 0 % / 17 % / 77 % / 6 % | 113 (109–122) | 4.85 | 8 | 9382 (9168–9911) |
| `avance_street_4x` | 148.8 / 0 / 6.3 | 53 (44–99) | 0 % / 18 % / 76 % / 6 % | 117 (114–128) | 4.77 | 8 | 8399 (8272–8893) |
| `expert_6x` | 149.5 / 0 / 5.5 | 60 (47–121) | 1 % / 48 % / 49 % / 3 % | 176 (167–183) | 5.06 | 8 | 11478 (11380–11787) |
| `irregulier_3x` | 26 / 0 / 129 | 2 (2–2) | 19 % / 6 % / 62 % / 14 % | 53 (45–55) | 4.58 | 8 | 4536 (4396–4743) |
| `vacances_5x` | 126.5 / 11 / 17.5 | 29 (20–39) | 10 % / 12 % / 72 % / 6 % | 128 (112–139) | 4.98 | 8 | 9569 (9272–10155) |
| `maladie_3x` | 90.8 / 7.3 / 57 | 10 (6–12) | 0 % / 0 % / 91 % / 9 % | 72 (65–79) | 5.12 | 8 | 7866 (7762–8195) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 6176 | 1063 | 519 | 244 | 1 |
| `debutant_3x` | 5671 | 1418 | 579 | 193 | 89 |
| `intermediaire_4x` | 6411 | 1983 | 661 | 398 | 42 |
| `avance_street_4x` | 5317 | 2083 | 644 | 419 | 68 |
| `expert_6x` | 6868 | 2948 | 1249 | 425 | 65 |
| `irregulier_3x` | 3199 | 928 | 420 | 0 | 14 |
| `vacances_5x` | 6184 | 2173 | 994 | 311 | 11 |
| `maladie_3x` | 6029 | 1190 | 584 | 144 | 0 |

## 6. Avancements

Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).

| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5.1 (5.1) | 5.9 (5.9) | 1 (1) | 1 (10.9) | 64.9 (99.9) | 69.2 (100) | 0.3 | 0 |
| `debutant_3x` | 34.7 (38.5) | 12.4 (12.4) | 6.9 (7.7) | 12.3 (14) | 11.7 (36.4) | 73.9 (100) | 34.5 | 5.8 |
| `intermediaire_4x` | 38.9 (50.3) | 27.9 (27.9) | 7.8 (10.1) | 10.4 (14.3) | 83.2 (98.1) | 88.3 (99.2) | 14.5 | 6 |
| `avance_street_4x` | 56.1 (57.5) | 27 (27) | 39.5 (40.3) | 50.7 (57.2) | 4.4 (32.8) | 89.2 (100) | 28.8 | 7.8 |
| `expert_6x` | 58.2 (59.4) | 1 (1) | 11.6 (11.9) | 21 (23.7) | 1 (21.5) | 88.9 (100) | 26.3 | 5 |
| `irregulier_3x` | 16.3 (16.3) | 19 (19) | 3.3 (3.3) | 4.5 (21.5) | 44 (72.4) | 30 (64.5) | 4.8 | 1 |
| `vacances_5x` | 35.3 (42.1) | 19.8 (19.8) | 37.1 (38.3) | 26.7 (31.2) | 64.3 (95.4) | 75 (96.7) | 3.5 | 2.5 |
| `maladie_3x` | 1 (1) | 1 (1) | 1 (1) | 1 (10.3) | 92.2 (100) | 68.9 (92.5) | 0 | 0 |

## 7. Garde-fous mesurés

| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d'effort / plafond | Niveau en baisse | Écritures d'XP |
| --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 0 | 0 | 0 | 0.895 | jamais | 1780 |
| `debutant_3x` | 0 | 0 | 0 | 0.888 | jamais | 2058 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.936 | jamais | 2339 |
| `avance_street_4x` | 0 | 0 | 0 | 0.934 | jamais | 2333 |
| `expert_6x` | 0 | 0 | 0 | 0.93 | jamais | 3085 |
| `irregulier_3x` | 0 | 0 | 0 | 0.973 | jamais | 1328 |
| `vacances_5x` | 0 | 0 | 0 | 0.996 | jamais | 2511 |
| `maladie_3x` | 3 | 0 | 0 | 0.952 | jamais | 2021 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | Écart le plus favorable au tricheur | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 73332 (72670–73706) | 74420 (74046–75314) | 1436 | 2172 | 32590 | 37836 | 443.3 | 0.936 |
| `intermediaire_4x` | 92462 (91622–95256) | 102503 (101628–103112) | 9864 | 11282 | 48521 | 57105 | 311.3 | 0.975 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 53.9 ms | 65 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 9.9 ms | 18.5 ms | ≤ 200 ms |
