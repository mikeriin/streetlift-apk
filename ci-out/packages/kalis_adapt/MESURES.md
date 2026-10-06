# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.2.3) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 200 graines × 4 politiques (dont l'oracle) à programme égal, puis 40 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. « oracle » n'est pas un moteur : c'est la politique qui connaît la vérité de l'athlète ; son écart est le plancher qu'imposent la grille des charges, l'arrondi des répétitions et la plage. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 1.30 ± 0.03 | 0.60 | 96 % | 1.35 | 0.97 ± 0.11 % | 2.16 ± 0.19 % | 0.29 ± 0.01 % |
| debutant_salle | double_progression | 1.96 ± 0.06 | 1.52 | 93 % | 2.08 | 6.67 ± 0.44 % | 5.52 ± 0.33 % | 0.28 ± 0.01 % |
| debutant_salle | L7/L11 | 3.48 ± 0.10 | 2.85 | 93 % | 3.51 | 7.23 ± 0.47 % | 6.93 ± 0.37 % | 0.29 ± 0.00 % |
| debutant_salle | oracle | 0.25 ± 0.00 | 0.03 | 93 % | 0.32 | 2.98 ± 0.19 % | 2.88 ± 0.19 % | 0.24 ± 0.00 % |
| intermediaire_salle | kalis_adapt | 1.21 ± 0.03 | 0.34 | 92 % | 1.55 | 0.86 ± 0.09 % | 2.01 ± 0.17 % | 0.05 ± 0.00 % |
| intermediaire_salle | double_progression | 2.67 ± 0.08 | 2.41 | 89 % | 3.61 | 3.70 ± 0.11 % | 3.70 ± 0.11 % | 0.04 ± 0.00 % |
| intermediaire_salle | L7/L11 | 3.93 ± 0.10 | 3.34 | 88 % | 4.72 | 4.14 ± 0.13 % | 5.26 ± 0.17 % | 0.04 ± 0.00 % |
| intermediaire_salle | oracle | 0.26 ± 0.00 | 0.03 | 88 % | 0.56 | 3.07 ± 0.10 % | 3.01 ± 0.08 % | 0.03 ± 0.00 % |
| avance_street | kalis_adapt | 1.03 ± 0.02 | 0.09 | 82 % | 1.61 | 0.65 ± 0.05 % | 1.94 ± 0.11 % | -0.00 ± 0.00 % |
| avance_street | double_progression | 2.03 ± 0.05 | 1.67 | 81 % | 3.73 | 4.74 ± 0.30 % | 2.74 ± 0.17 % | -0.00 ± 0.00 % |
| avance_street | L7/L11 | 2.59 ± 0.05 | 1.85 | 80 % | 4.27 | 5.64 ± 0.32 % | 4.66 ± 0.21 % | -0.01 ± 0.00 % |
| avance_street | oracle | 0.24 ± 0.00 | 0.02 | 81 % | 1.08 | 0.04 ± 0.03 % | 0.03 ± 0.02 % | -0.00 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 1.34 ± 0.04 | 0.47 | 93 % | 1.71 | 0.93 ± 0.09 % | 2.29 ± 0.19 % | 0.07 ± 0.00 % |
| notes_paresseuses | double_progression | 2.59 ± 0.09 | 2.37 | 93 % | 3.79 | 0.21 ± 0.05 % | 0.26 ± 0.06 % | 0.07 ± 0.00 % |
| notes_paresseuses | L7/L11 | 4.46 ± 0.12 | 4.19 | 93 % | 5.59 | 0.37 ± 0.06 % | 0.87 ± 0.08 % | 0.06 ± 0.00 % |
| notes_paresseuses | oracle | 0.29 ± 0.01 | 0.05 | 93 % | 0.66 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.00 % |
| irregulier | kalis_adapt | 1.19 ± 0.03 | 0.42 | 96 % | 1.35 | 0.48 ± 0.07 % | 1.51 ± 0.15 % | 0.01 ± 0.00 % |
| irregulier | double_progression | 2.53 ± 0.09 | 2.34 | 95 % | 3.20 | 0.25 ± 0.09 % | 0.26 ± 0.07 % | 0.01 ± 0.00 % |
| irregulier | L7/L11 | 3.57 ± 0.12 | 3.09 | 95 % | 4.21 | 0.60 ± 0.11 % | 1.32 ± 0.13 % | -0.00 ± 0.00 % |
| irregulier | oracle | 0.28 ± 0.01 | 0.06 | 95 % | 0.48 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.02 ± 0.00 % |
| maison_halteres | kalis_adapt | 1.72 ± 0.06 | 1.12 | 91 % | 1.84 | 0.84 ± 0.08 % | 1.39 ± 0.13 % | 0.30 ± 0.00 % |
| maison_halteres | double_progression | 3.37 ± 0.10 | 2.95 | 90 % | 3.68 | 2.34 ± 0.28 % | 1.83 ± 0.20 % | 0.29 ± 0.00 % |
| maison_halteres | L7/L11 | 6.18 ± 0.18 | 5.58 | 90 % | 6.18 | 2.76 ± 0.29 % | 2.92 ± 0.22 % | 0.28 ± 0.00 % |
| maison_halteres | oracle | 0.32 ± 0.01 | 0.13 | 90 % | 0.38 | 0.03 ± 0.03 % | 0.03 ± 0.02 % | 0.34 ± 0.00 % |
| calisthenie_parc | kalis_adapt | 1.20 ± 0.06 | 0.93 | 49 % | 3.11 | 0.06 ± 0.02 % | 0.08 ± 0.03 % | 0.07 ± 0.00 % |
| calisthenie_parc | double_progression | 3.54 ± 0.16 | 3.46 | 47 % | 8.09 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.00 % |
| calisthenie_parc | L7/L11 | 3.54 ± 0.16 | 3.46 | 47 % | 8.09 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.00 % |
| calisthenie_parc | oracle | 0.32 ± 0.01 | 0.11 | 45 % | 2.93 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.00 % |
| douleur_et_lieu | kalis_adapt | 1.19 ± 0.03 | 0.40 | 90 % | 1.40 | 0.62 ± 0.07 % | 1.76 ± 0.15 % | 0.04 ± 0.00 % |
| douleur_et_lieu | double_progression | 2.12 ± 0.06 | 1.84 | 84 % | 2.80 | 4.82 ± 0.19 % | 4.50 ± 0.16 % | 0.05 ± 0.00 % |
| douleur_et_lieu | L7/L11 | 3.33 ± 0.10 | 2.74 | 84 % | 3.78 | 5.15 ± 0.20 % | 5.76 ± 0.20 % | 0.05 ± 0.00 % |
| douleur_et_lieu | oracle | 0.27 ± 0.00 | 0.04 | 84 % | 0.58 | 3.89 ± 0.12 % | 3.79 ± 0.13 % | 0.03 ± 0.00 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | -0.66 ± 0.05 | -2.18 ± 0.10 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| intermediaire_salle | -1.46 ± 0.07 | -2.72 ± 0.09 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| avance_street | -1.00 ± 0.05 | -1.56 ± 0.05 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -1.24 ± 0.08 | -3.11 ± 0.12 | 0.00 ± 0.00 % | 0.01 ± 0.00 % |
| irregulier | -1.35 ± 0.08 | -2.39 ± 0.12 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| maison_halteres | -1.65 ± 0.08 | -4.46 ± 0.18 | 0.01 ± 0.00 % | 0.02 ± 0.00 % |
| calisthenie_parc | -2.34 ± 0.15 | -2.34 ± 0.15 | 0.04 ± 0.00 % | 0.04 ± 0.00 % |
| douleur_et_lieu | -0.93 ± 0.06 | -2.14 ± 0.10 | -0.00 ± 0.00 % | -0.00 ± 0.00 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 1.32 ± 0.04 | 1.25 ± 0.05 |
| intermediaire_salle | 1.19 ± 0.03 | 1.29 ± 0.06 |
| avance_street | 1.10 ± 0.02 | 0.90 ± 0.03 |
| notes_paresseuses | 1.24 ± 0.05 | 1.75 ± 0.08 |
| irregulier | 1.12 ± 0.02 | 1.47 ± 0.07 |
| maison_halteres | 1.86 ± 0.07 | 1.53 ± 0.07 |
| calisthenie_parc | — | 1.20 ± 0.06 |
| douleur_et_lieu | 1.24 ± 0.04 | 1.07 ± 0.05 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 12.7 % | 6.2 % | 5.9 % | 4.3 % | 13.6 % | 7.9 % | 7.7 % | 6.3 % | 86 % |
| debutant_salle | L7/L11 | 10.3 % | 9.0 % | 9.6 % | 9.4 % | 9.1 % | 8.1 % | 7.6 % | 7.6 % | 46 % |
| intermediaire_salle | kalis_adapt | 12.3 % | 5.7 % | 4.6 % | 3.7 % | 13.6 % | 8.1 % | 7.1 % | 6.2 % | 89 % |
| intermediaire_salle | L7/L11 | 7.3 % | 5.4 % | 6.0 % | 5.6 % | 7.4 % | 7.6 % | 6.9 % | 6.6 % | 45 % |
| avance_street | kalis_adapt | 10.4 % | 6.6 % | 5.6 % | 4.9 % | 11.6 % | 8.2 % | 7.3 % | 6.3 % | 84 % |
| avance_street | L7/L11 | 5.8 % | 5.4 % | 5.9 % | 7.1 % | 5.9 % | 6.0 % | 5.0 % | 4.1 % | 57 % |
| notes_paresseuses | kalis_adapt | 12.2 % | 7.3 % | 5.0 % | 2.4 % | 13.3 % | 9.1 % | 6.8 % | 4.5 % | 88 % |
| notes_paresseuses | L7/L11 | 9.1 % | 7.2 % | 7.4 % | 6.2 % | 8.3 % | 8.1 % | 7.6 % | 7.9 % | 30 % |
| irregulier | kalis_adapt | 10.4 % | 5.6 % | 4.8 % | 2.2 % | 11.6 % | 7.7 % | 7.0 % | 5.1 % | 90 % |
| irregulier | L7/L11 | 7.7 % | 6.3 % | 5.8 % | 6.0 % | 8.6 % | 8.1 % | 7.7 % | 7.5 % | 39 % |
| maison_halteres | kalis_adapt | 15.5 % | 9.5 % | 8.5 % | 7.5 % | 16.3 % | 10.9 % | 10.1 % | 9.4 % | 77 % |
| maison_halteres | L7/L11 | 13.7 % | 12.1 % | 11.9 % | 12.2 % | 11.2 % | 10.1 % | 9.5 % | 9.4 % | 44 % |
| calisthenie_parc | kalis_adapt | 24.8 % | 20.6 % | 18.7 % | 15.4 % | 24.8 % | 20.6 % | 18.7 % | 15.4 % | 56 % |
| douleur_et_lieu | kalis_adapt | 11.9 % | 4.6 % | 3.8 % | 3.8 % | 13.3 % | 6.7 % | 5.9 % | 5.9 % | 89 % |
| douleur_et_lieu | L7/L11 | 8.3 % | 6.7 % | 6.9 % | 6.7 % | 9.2 % | 8.8 % | 8.5 % | 8.3 % | 36 % |

### Mouvements principaux seulement

L'ancien moteur L7 n'estimait que les mouvements principaux, à partir d'un niveau déclaré : la comparaison se fait sur eux.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 |
| --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 11.4 % | 3.1 % | 2.1 % | 1.6 % |
| debutant_salle | L7/L11 | 10.3 % | 9.0 % | 9.6 % | 9.4 % |
| intermediaire_salle | kalis_adapt | 4.6 % | 1.9 % | 1.5 % | 1.3 % |
| intermediaire_salle | L7/L11 | 7.3 % | 5.4 % | 6.0 % | 5.6 % |
| avance_street | kalis_adapt | 2.8 % | 1.7 % | 1.6 % | 1.5 % |
| avance_street | L7/L11 | 5.8 % | 5.4 % | 5.9 % | 7.1 % |
| notes_paresseuses | kalis_adapt | 6.4 % | 3.2 % | 2.1 % | 1.3 % |
| notes_paresseuses | L7/L11 | 9.1 % | 7.2 % | 7.4 % | 6.2 % |
| irregulier | kalis_adapt | 6.3 % | 2.4 % | 1.7 % | 1.4 % |
| irregulier | L7/L11 | 7.7 % | 6.3 % | 5.8 % | 6.0 % |
| maison_halteres | kalis_adapt | 13.9 % | 5.2 % | 3.7 % | 3.1 % |
| maison_halteres | L7/L11 | 13.7 % | 12.1 % | 11.9 % | 12.2 % |
| calisthenie_parc | kalis_adapt | 17.7 % | 12.1 % | 9.0 % | 7.8 % |
| douleur_et_lieu | kalis_adapt | 10.2 % | 2.4 % | 1.6 % | 1.4 % |
| douleur_et_lieu | L7/L11 | 8.3 % | 6.7 % | 6.9 % | 6.7 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'un mouvement principal par rapport à la plus forte charge de sa séance précédente, à partir de la 4ᵉ séance de l'exercice et hors semaines de test. Hausses > 10 % : celles qui franchissent plus d'un cran de la grille (ce que l'invariant I1 interdit à `kalis_adapt`), et celles d'un seul cran (le plus petit cran du matériel dépasse 10 %), sur toutes les simulations. Aggravations : hausses de charge sur une zone signalée douloureuse, par simulation.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 %, plusieurs crans | Hausses > 10 %, un cran | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 43.1 | 59.3 % | 33.3 % | 0 | 409 | 34.9 % | 0.00 |
| debutant_salle | double_progression | 63.8 | 69.9 % | 33.3 % | 0 | 873 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 57.6 | 66.9 % | 50.0 % | 55 | 228 | 0.0 % | 0.00 |
| debutant_salle | oracle | 62.9 | 73.9 % | 25.0 % | 304 | 472 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 43.8 | 60.6 % | 12.5 % | 0 | 75 | 28.2 % | 0.00 |
| intermediaire_salle | double_progression | 85.9 | 70.9 % | 12.5 % | 0 | 215 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 86.4 | 70.8 % | 22.2 % | 71 | 414 | 0.0 % | 0.00 |
| intermediaire_salle | oracle | 60.0 | 72.5 % | 25.0 % | 235 | 256 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 61.9 | 57.2 % | 9.9 % | 0 | 0 | 30.5 % | 0.00 |
| avance_street | double_progression | 79.3 | 38.1 % | 3.2 % | 0 | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 120.7 | 54.4 % | 16.2 % | 20 | 0 | 0.0 % | 0.00 |
| avance_street | oracle | 116.0 | 64.7 % | 15.3 % | 76 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 29.1 | 40.8 % | 10.0 % | 0 | 0 | 14.1 % | 0.00 |
| notes_paresseuses | double_progression | 52.2 | 51.8 % | 5.9 % | 0 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 55.5 | 48.7 % | 20.8 % | 16 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | oracle | 97.2 | 72.1 % | 18.2 % | 149 | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 27.6 | 42.8 % | 10.0 % | 0 | 0 | 16.2 % | 0.00 |
| irregulier | double_progression | 39.0 | 29.9 % | 9.1 % | 0 | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 52.1 | 46.9 % | 44.4 % | 352 | 0 | 0.0 % | 0.00 |
| irregulier | oracle | 75.7 | 65.4 % | 25.0 % | 352 | 0 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 29.3 | 64.0 % | 50.0 % | 0 | 962 | 15.7 % | 0.00 |
| maison_halteres | double_progression | 90.0 | 84.0 % | 50.0 % | 0 | 3225 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 51.0 | 76.9 % | 50.0 % | 0 | 536 | 0.0 % | 0.00 |
| maison_halteres | oracle | 24.7 | 73.3 % | 33.3 % | 0 | 984 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 4.6 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | oracle | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 39.1 | 57.8 % | 33.3 % | 0 | 273 | 39.3 % | 0.00 |
| douleur_et_lieu | double_progression | 67.8 | 67.9 % | 33.3 % | 0 | 763 | 0.0 % | 15.47 |
| douleur_et_lieu | L7/L11 | 77.2 | 65.0 % | 33.3 % | 25 | 304 | 0.0 % | 12.83 |
| douleur_et_lieu | oracle | 73.7 | 74.3 % | 25.0 % | 111 | 453 | 0.0 % | 5.66 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.20 ± 0.07 | 0.28 ± 0.01 % | 0.6 | 0.0 | 1.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.14 ± 0.05 | 0.05 ± 0.01 % | 1.3 | 0.1 | 2.2 | 0.0 | 0.0 | 0.0 | 0.8 % |
| avance_street | 1.04 ± 0.03 | -0.00 ± 0.00 % | 4.5 | 1.5 | 1.2 | 0.0 | 0.0 | 0.0 | 1.1 % |
| notes_paresseuses | 1.28 ± 0.07 | 0.06 ± 0.00 % | 1.5 | 0.0 | 0.7 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.13 ± 0.05 | -0.00 ± 0.02 % | 1.7 | 0.0 | 0.7 | 0.0 | 0.0 | 0.0 | 0.0 % |
| maison_halteres | 1.50 ± 0.13 | 0.34 ± 0.01 % | 1.0 | 0.0 | 0.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 1.24 ± 0.11 | 0.14 ± 0.01 % | 0.1 | 0.0 | 0.4 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 1.20 ± 0.08 | 0.07 ± 0.00 % | 3.5 | 0.0 | 2.9 | 0.0 | 0.0 | 0.0 | 1.7 % |

| Athlète | Volume | Échange d'exercice | Restructuration de séance | Restructuration de bloc |
| --- | --- | --- | --- | --- |
| debutant_salle | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| intermediaire_salle | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| avance_street | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 7.0 (40/40) | semaine 13.0 (40/40) |
| notes_paresseuses | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| irregulier | semaine 2.1 (40/40) | semaine 4.1 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| maison_halteres | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 5.0 (40/40) | semaine 10.0 (40/40) |
| calisthenie_parc | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 5.0 (40/40) | semaine 10.0 (40/40) |
| douleur_et_lieu | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.9 (40/40) |

Candidates retenues par la revue, par simulation (nature : cause — `unlock` niveau de déblocage pas encore atteint, `confidence` confiance sous le seuil du niveau, `utility` utilité nulle ou négative, `refused` refus récent, `settled` déjà décidée, `recent_swap` échange trop récent, `scope` changement qui déborde de sa portée, `no_change` et `plan_error` rien à proposer par `kalis_plan`) :

| Athlète | Candidates retenues |
| --- | --- |
| debutant_salle | block_restructure:no_change 0.1 ; block_restructure:unlock 0.1 ; deload:confidence 0.0 ; exercise_swap:recent_swap 0.2 ; exercise_swap:unlock 1.9 |
| intermediaire_salle | block_restructure:no_change 0.0 ; block_restructure:unlock 0.1 ; deload:confidence 0.1 ; exercise_swap:recent_swap 0.0 ; exercise_swap:scope 1.5 |
| avance_street | deload:confidence 0.4 ; exercise_swap:recent_swap 0.1 ; exercise_swap:scope 0.3 ; volume:confidence 0.1 |
| notes_paresseuses | block_restructure:no_change 0.0 ; block_restructure:unlock 0.0 ; exercise_swap:scope 0.3 |
| irregulier | block_restructure:no_change 4.5 ; block_restructure:unlock 1.6 ; deload:confidence 0.1 |
| maison_halteres | block_restructure:no_change 0.2 ; block_restructure:unlock 0.2 ; exercise_swap:scope 0.3 |
| calisthenie_parc | block_restructure:no_change 0.1 ; block_restructure:unlock 0.1 |
| douleur_et_lieu | block_restructure:unlock 0.1 ; deload:confidence 0.3 ; exercise_swap:recent_swap 0.5 ; exercise_swap:scope 0.1 ; exercise_swap:unlock 2.5 ; pain_sparing:no_change 2.9 ; pain_sparing:scope 0.1 ; volume:confidence 0.1 |

## 5. Temps de calcul

Mesurés par le simulateur sur la machine de contrôle (le moteur n'a pas d'horloge), sur 117 séances et 1766 conseils de l'athlète `avance_street`, après une première simulation non mesurée (le code est alors compilé, comme il l'est d'avance sur téléphone). « À froid » : instance neuve, tout le journal rejoué (117 séances). Machine : linux, 4 cœurs — pas un téléphone.

| Opération | Médiane | 95ᵉ centile | 99ᵉ centile | Maximum | Cible |
| --- | --- | --- | --- | --- | --- |
| Décision de séance (`prescribeSession`) | 0.07 ms | 0.09 ms | 6.68 ms | 10.35 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.07 ms | 0.13 ms | 0.16 ms | 6.28 ms | ≤ 5 ms |
| Revue (`review`) | 0.90 ms | 1.01 ms | 1.49 ms | 1.49 ms | — |
| Décision de séance à froid | 13.19 ms | 23.98 ms | 24.24 ms | 24.24 ms | — |
