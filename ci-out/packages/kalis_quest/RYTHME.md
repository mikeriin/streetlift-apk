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
| `debutant_2x` | 5 (3–5) | 9 (7–10) | 20 (18–21) | 29 (28–30) | 41 (40–42) | 59 (58–60) | 73 (72–75) |
| `debutant_3x` | 5 (4–5) | 9 (8–10) | 22 (21–23) | 32 (30–33) | 46 (45–47) | 67 (66–68) | 83 (83–85) |
| `intermediaire_4x` | 6 (5–6) | 11 (10–12) | 25 (24–26) | 37 (35–37) | 53 (52–54) | 76 (76–78) | 95 (94–96) |
| `avance_street_4x` | 6 (5–6) | 11 (10–12) | 25 (24–26) | 37 (35–37) | 53 (52–53) | 75 (75–77) | 94 (93–95) |
| `expert_6x` | 7 (6–7) | 13 (13–14) | 31 (30–31) | 44 (43–45) | 64 (63–64) | 92 (91–93) | 151 (149–152) |
| `irregulier_3x` | 4 (3–5) | 8 (6–9) | 18 (17–20) | 25 (24–26) | 36 (34–37) | 52 (51–53) | 65 (62–66) |
| `vacances_5x` | 6 (5–7) | 12 (11–13) | 28 (26–29) | 41 (40–41) | 57 (55–57) | 81 (81–83) | 110 (100–118) |
| `maladie_3x` | 5 (4–6) | 10 (9–11) | 22 (20–23) | 32 (32–34) | 47 (46–48) | 68 (67–69) | 84 (83–85) |

Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige est passé).

### Semaines pour atteindre un niveau

| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 4 (3–4.7) | 20 (18–21.7) | 75.5 (72.3–78) | jamais en 156 sem. |
| `debutant_3x` | 4 (3–4) | 17 (15–18.7) | 60 (58–62.7) | jamais en 156 sem. |
| `intermediaire_4x` | 3 (3–3) | 13 (12–14) | 46 (45–48) | jamais en 156 sem. |
| `avance_street_4x` | 3 (3–3) | 13 (12–13.7) | 47 (45.3–48.7) | jamais en 156 sem. |
| `expert_6x` | 2 (2–2) | 9 (9–10) | 33 (32–34) | 121 (119–122) |
| `irregulier_3x` | 4 (4–5.7) | 25.5 (21.2–28.7) | 93 (88.3–101) | jamais en 156 sem. |
| `vacances_5x` | 2 (2–3) | 10.5 (10–11.7) | 41 (40–43) | 151 (148–154) |
| `maladie_3x` | 3 (3–4) | 16 (15–17.7) | 58 (57–60) | jamais en 156 sem. |

Prolongement à 208 semaines des archétypes de repère (24 graines) :

| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |
| --- | --- | --- | --- |
| `debutant_3x` | 60 (58–62.7) sem. — 24/24 graines | jamais | 97 (96–99) |
| `intermediaire_4x` | 46 (45–48) sem. — 24/24 graines | 170.5 (167.3–173.7) sem. — 24/24 graines | 142 (140–144) |

### Courbe médiane (niveau global, toutes les 13 semaines)

| Archétype | S12 | S24 | S36 | S48 | S60 | S72 | S84 | S96 | S108 | S120 | S132 | S144 | S156 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 19 | 28 | 34 | 39 | 44 | 49 | 53 | 57 | 60 | 64 | 67 | 70 | 73 |
| `debutant_3x` | 21 | 30 | 38 | 44 | 50 | 55 | 60 | 64 | 68 | 72 | 76 | 80 | 83 |
| `intermediaire_4x` | 24 | 35 | 44 | 51 | 57 | 63 | 68 | 73 | 78 | 83 | 87 | 91 | 95 |
| `avance_street_4x` | 24 | 35 | 44 | 51 | 57 | 62 | 67 | 72 | 77 | 81 | 86 | 90 | 94 |
| `expert_6x` | 29 | 42 | 52 | 61 | 69 | 76 | 82 | 88 | 94 | 99 | 126 | 140 | 151 |
| `irregulier_3x` | 17 | 24 | 31 | 34 | 39 | 43 | 47 | 51 | 53 | 57 | 60 | 63 | 65 |
| `vacances_5x` | 27 | 39 | 46 | 55 | 61 | 68 | 73 | 78 | 83 | 88 | 93 | 97 | 110 |
| `maladie_3x` | 21 | 31 | 39 | 45 | 51 | 55 | 60 | 65 | 69 | 73 | 77 | 80 | 84 |

## 3. XP

| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 55152 (54045–57618) | 354.9 | 37 % | 26 % | 0 % | 0 % | 38 % |
| `debutant_3x` | 70181 (69242–72354) | 452.1 | 46 % | 21 % | 1 % | 0 % | 31 % |
| `intermediaire_4x` | 89843 (88337–91761) | 576.8 | 54 % | 18 % | 0 % | 0 % | 27 % |
| `avance_street_4x` | 87600 (86095–89036) | 560.9 | 54 % | 19 % | 1 % | 0 % | 27 % |
| `expert_6x` | 127610 (125794–128697) | 816.5 | 64 % | 13 % | 0 % | 0 % | 23 % |
| `irregulier_3x` | 43944 (40935–45098) | 277.6 | 47 % | 19 % | 0 % | 0 % | 34 % |
| `vacances_5x` | 101039 (99492–103793) | 649.8 | 60 % | 14 % | 0 % | 0 % | 26 % |
| `maladie_3x` | 70879 (69677–73194) | 456.6 | 49 % | 19 % | 0 % | 0 % | 32 % |

## 4. Quêtes

Créées et terminées par simulation (moyennes), part terminée.

| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |
| --- | --- | --- | --- | --- |
| `debutant_2x` | 943.5 / 1950.8 (48 %) | 178.8 / 312 (57 %) | 64.8 / 78 (83 %) | 63.3 / 156 (41 %) |
| `debutant_3x` | 1144.5 / 2106 (54 %) | 165.5 / 312 (53 %) | 60.1 / 64 (94 %) | 45.5 / 156 (29 %) |
| `intermediaire_4x` | 1266.4 / 2262.3 (56 %) | 182 / 312 (58 %) | 61.8 / 64 (97 %) | 51.8 / 156 (33 %) |
| `avance_street_4x` | 1347.1 / 2262.3 (60 %) | 161.3 / 312 (52 %) | 52 / 52 (100 %) | 51 / 156 (33 %) |
| `expert_6x` | 1764.3 / 2576.8 (69 %) | 165.1 / 312 (53 %) | 52 / 52 (100 %) | 41.2 / 156 (26 %) |
| `irregulier_3x` | 788.8 / 2105.1 (38 %) | 118.2 / 312 (38 %) | 39.3 / 78 (50 %) | 51.2 / 156 (33 %) |
| `vacances_5x` | 1458.5 / 2320.2 (63 %) | 170.8 / 288 (59 %) | 54 / 64 (84 %) | 62.6 / 144 (44 %) |
| `maladie_3x` | 1170.3 / 2045.8 (57 %) | 166.3 / 300 (55 %) | 60.3 / 78 (77 %) | 64.6 / 150 (43 %) |

## 5. Série de semaines, notes, coffres, Krédits

| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 112 / 0 / 43 | 13 (10–17) | 0 % / 1 % / 90 % / 10 % | 53 (48–59) | 4.92 | 8 | 7439 (7192–7971) |
| `debutant_3x` | 114 / 0 / 41 | 14 (9–17) | 0 % / 15 % / 77 % / 7 % | 85 (79–90) | 5 | 8 | 8224 (7875–8570) |
| `intermediaire_4x` | 147.1 / 0 / 7.9 | 49 (31–64) | 0 % / 16 % / 77 % / 6 % | 114 (108–120) | 4.93 | 8 | 9644 (9359–9934) |
| `avance_street_4x` | 150 / 0 / 5 | 57 (43–108) | 0 % / 18 % / 76 % / 5 % | 116 (110–126) | 4.93 | 8 | 9321 (9067–9658) |
| `expert_6x` | 149.8 / 0 / 5.3 | 65 (40–90) | 1 % / 48 % / 49 % / 3 % | 173 (165–183) | 5.14 | 8 | 11951 (11528–12372) |
| `irregulier_3x` | 28.5 / 0 / 126.5 | 3 (2–4) | 19 % / 7 % / 59 % / 15 % | 50 (46–54) | 4.85 | 8 | 5302 (5025–5518) |
| `vacances_5x` | 127 / 11 / 17 | 25 (16–34) | 10 % / 12 % / 71 % / 7 % | 125 (119–133) | 5.03 | 8 | 10278 (9659–10666) |
| `maladie_3x` | 93.5 / 7.2 / 54.3 | 9 (7–13) | 0 % / 1 % / 90 % / 10 % | 74 (68–82) | 5.02 | 8 | 8083 (7776–8579) |

Krédits par origine (moyennes) :

| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |
| --- | --- | --- | --- | --- | --- |
| `debutant_2x` | 5850 | 953 | 502 | 226 | 0 |
| `debutant_3x` | 5865 | 1506 | 572 | 201 | 98 |
| `intermediaire_4x` | 6516 | 2004 | 651 | 452 | 45 |
| `avance_street_4x` | 6145 | 2038 | 644 | 446 | 71 |
| `expert_6x` | 7159 | 3073 | 1239 | 423 | 63 |
| `irregulier_3x` | 3944 | 885 | 437 | 3 | 14 |
| `vacances_5x` | 6711 | 2253 | 907 | 331 | 11 |
| `maladie_3x` | 6123 | 1295 | 574 | 150 | 0 |

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
| `debutant_2x` | 0 | 0 | 0 | 0.941 | jamais | 1764 |
| `debutant_3x` | 0 | 0 | 0 | 0.918 | jamais | 2109 |
| `intermediaire_4x` | 0 | 0 | 0 | 0.95 | jamais | 2364 |
| `avance_street_4x` | 0 | 0 | 0 | 0.964 | jamais | 2430 |
| `expert_6x` | 0 | 0 | 0 | 0.945 | jamais | 3124 |
| `irregulier_3x` | 0 | 0 | 0 | 0.988 | jamais | 1423 |
| `vacances_5x` | 0 | 0 | 0 | 0.996 | jamais | 2576 |
| `maladie_3x` | 2.7 | 0 | 0 | 0.97 | jamais | 2055 |

### Triche par surentraînement

Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque séance et une séance en plus quatre jours de repos sur cinq.

| Archétype | XP honnête | XP tricheur | Écart médian | XP d'effort honnête | XP d'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `debutant_3x` | 70181 (69242–72354) | 71675 (71428–72181) | 1581 | 32751 | 37740 | 452.4 | 0.936 |
| `intermediaire_4x` | 89843 (88337–91761) | 96603 (96049–97165) | 6529 | 48888 | 57171 | 314.8 | 0.986 |

Les séances en plus du tricheur prennent la place des séances prévues qu'il manque : son XP d'effort monte jusqu'au plafond du programme, jamais au-delà. Face au même programme fait en entier (assiduité parfaite), le surentraînement ne rapporte rien :

| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |
| --- | --- | --- | --- | --- |
| `debutant_3x` | 24 | 81093 | 71290 | -9003 |
| `intermediaire_4x` | 24 | 103300 | 96776 | -6090 |

## 8. Temps de calcul

VM Dart de la CI, journal de 895 séances (156 semaines, archétype `expert_6x`).

| Appel | Médiane | Maximum | Budget |
| --- | --- | --- | --- |
| Calcul complet depuis tout le journal (registre démarré le premier jour, un seul appel à la fin) | 61 ms | 72.5 ms | ≤ 200 ms |
| Appel du lendemain (état à jour) | 11 ms | 14.5 ms | ≤ 200 ms |
