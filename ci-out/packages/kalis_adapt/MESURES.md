# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.2.0) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 6 graines × 4 politiques (dont l'oracle) à programme égal, puis 3 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. « oracle » n'est pas un moteur : c'est la politique qui connaît la vérité de l'athlète ; son écart est le plancher qu'imposent la grille des charges, l'arrondi des répétitions et la plage. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 1.36 ± 0.25 | 0.77 | 95 % | 1.51 | 0.80 ± 0.59 % | 1.83 ± 1.06 % | 0.32 ± 0.04 % |
| debutant_salle | double_progression | 2.08 ± 0.44 | 1.74 | 92 % | 2.19 | 8.24 ± 2.47 % | 6.52 ± 0.86 % | 0.29 ± 0.03 % |
| debutant_salle | L7/L11 | 4.51 ± 0.80 | 3.99 | 93 % | 4.40 | 8.46 ± 2.36 % | 8.00 ± 1.84 % | 0.29 ± 0.02 % |
| debutant_salle | oracle | 0.25 ± 0.01 | 0.03 | 92 % | 0.34 | 3.74 ± 0.87 % | 3.68 ± 0.90 % | 0.23 ± 0.01 % |
| intermediaire_salle | kalis_adapt | 1.28 ± 0.22 | 0.56 | 91 % | 1.78 | 0.81 ± 0.62 % | 1.79 ± 1.02 % | 0.06 ± 0.01 % |
| intermediaire_salle | double_progression | 3.15 ± 0.47 | 2.96 | 88 % | 4.07 | 3.58 ± 0.64 % | 3.53 ± 0.51 % | 0.04 ± 0.01 % |
| intermediaire_salle | L7/L11 | 4.17 ± 0.47 | 3.65 | 88 % | 5.04 | 3.79 ± 0.63 % | 5.14 ± 1.09 % | 0.04 ± 0.00 % |
| intermediaire_salle | oracle | 0.27 ± 0.02 | 0.03 | 88 % | 0.58 | 3.32 ± 0.87 % | 3.24 ± 0.80 % | 0.03 ± 0.01 % |
| avance_street | kalis_adapt | 1.00 ± 0.08 | 0.15 | 83 % | 1.67 | 0.56 ± 0.40 % | 1.76 ± 0.38 % | -0.00 ± 0.00 % |
| avance_street | double_progression | 2.10 ± 0.13 | 1.80 | 83 % | 3.73 | 4.06 ± 1.17 % | 2.57 ± 0.66 % | -0.00 ± 0.00 % |
| avance_street | L7/L11 | 2.66 ± 0.14 | 1.97 | 82 % | 4.28 | 4.76 ± 1.45 % | 4.29 ± 1.23 % | -0.01 ± 0.00 % |
| avance_street | oracle | 0.24 ± 0.01 | 0.02 | 82 % | 1.17 | 0.07 ± 0.13 % | 0.04 ± 0.07 % | -0.00 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 1.27 ± 0.15 | 0.48 | 93 % | 1.48 | 0.79 ± 0.42 % | 2.32 ± 1.30 % | 0.07 ± 0.01 % |
| notes_paresseuses | double_progression | 3.12 ± 0.45 | 2.95 | 94 % | 3.96 | 0.31 ± 0.56 % | 0.28 ± 0.34 % | 0.07 ± 0.01 % |
| notes_paresseuses | L7/L11 | 4.86 ± 0.81 | 4.65 | 94 % | 5.65 | 0.42 ± 0.51 % | 0.77 ± 0.40 % | 0.06 ± 0.01 % |
| notes_paresseuses | oracle | 0.30 ± 0.04 | 0.07 | 93 % | 0.47 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.01 % |
| irregulier | kalis_adapt | 1.27 ± 0.19 | 0.66 | 96 % | 1.37 | 0.48 ± 0.35 % | 1.37 ± 0.78 % | 0.02 ± 0.05 % |
| irregulier | double_progression | 2.64 ± 0.48 | 2.49 | 96 % | 3.18 | 0.20 ± 0.40 % | 0.23 ± 0.29 % | 0.01 ± 0.05 % |
| irregulier | L7/L11 | 3.77 ± 0.44 | 3.38 | 96 % | 4.31 | 0.48 ± 0.43 % | 1.09 ± 0.67 % | 0.01 ± 0.05 % |
| irregulier | oracle | 0.30 ± 0.04 | 0.08 | 95 % | 0.41 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.03 ± 0.05 % |
| maison_halteres | kalis_adapt | 1.96 ± 0.54 | 1.51 | 90 % | 2.03 | 0.72 ± 0.68 % | 0.88 ± 0.66 % | 0.30 ± 0.01 % |
| maison_halteres | double_progression | 3.76 ± 0.67 | 3.51 | 88 % | 4.02 | 3.61 ± 2.65 % | 2.22 ± 1.83 % | 0.29 ± 0.02 % |
| maison_halteres | L7/L11 | 6.45 ± 0.72 | 6.00 | 88 % | 6.30 | 4.00 ± 2.88 % | 2.94 ± 1.71 % | 0.28 ± 0.01 % |
| maison_halteres | oracle | 0.33 ± 0.07 | 0.14 | 88 % | 0.38 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.34 ± 0.01 % |
| calisthenie_parc | kalis_adapt | 1.44 ± 0.51 | 1.26 | 52 % | 3.07 | 0.15 ± 0.09 % | 0.14 ± 0.20 % | -0.08 ± 0.04 % |
| calisthenie_parc | double_progression | 3.76 ± 0.95 | 3.72 | 46 % | 8.39 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.01 % |
| calisthenie_parc | L7/L11 | 3.76 ± 0.95 | 3.72 | 46 % | 8.39 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.01 % |
| calisthenie_parc | oracle | 0.37 ± 0.11 | 0.18 | 45 % | 3.09 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.02 % |
| douleur_et_lieu | kalis_adapt | 1.31 ± 0.27 | 0.65 | 89 % | 1.71 | 0.48 ± 0.19 % | 1.74 ± 0.48 % | 0.05 ± 0.01 % |
| douleur_et_lieu | double_progression | 2.21 ± 0.52 | 1.96 | 83 % | 3.15 | 5.61 ± 1.49 % | 4.98 ± 0.97 % | 0.05 ± 0.01 % |
| douleur_et_lieu | L7/L11 | 3.36 ± 0.49 | 2.78 | 83 % | 3.99 | 5.96 ± 1.62 % | 6.06 ± 1.43 % | 0.05 ± 0.01 % |
| douleur_et_lieu | oracle | 0.28 ± 0.03 | 0.04 | 83 % | 0.62 | 4.13 ± 0.42 % | 4.03 ± 0.42 % | 0.03 ± 0.00 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | -0.72 ± 0.25 | -3.15 ± 0.80 | 0.03 ± 0.02 % | 0.03 ± 0.03 % |
| intermediaire_salle | -1.87 ± 0.33 | -2.89 ± 0.30 | 0.01 ± 0.01 % | 0.01 ± 0.01 % |
| avance_street | -1.09 ± 0.17 | -1.65 ± 0.15 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -1.85 ± 0.43 | -3.59 ± 0.81 | 0.01 ± 0.01 % | 0.02 ± 0.01 % |
| irregulier | -1.37 ± 0.33 | -2.51 ± 0.37 | 0.01 ± 0.01 % | 0.02 ± 0.00 % |
| maison_halteres | -1.81 ± 0.73 | -4.49 ± 0.54 | 0.01 ± 0.01 % | 0.02 ± 0.01 % |
| calisthenie_parc | -2.32 ± 0.92 | -2.32 ± 0.92 | -0.12 ± 0.04 % | -0.12 ± 0.04 % |
| douleur_et_lieu | -0.90 ± 0.34 | -2.05 ± 0.41 | -0.00 ± 0.01 % | 0.00 ± 0.01 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 1.34 ± 0.21 | 1.41 ± 0.43 |
| intermediaire_salle | 1.29 ± 0.26 | 1.28 ± 0.28 |
| avance_street | 1.06 ± 0.07 | 0.92 ± 0.15 |
| notes_paresseuses | 1.15 ± 0.10 | 1.76 ± 0.52 |
| irregulier | 1.18 ± 0.20 | 1.58 ± 0.25 |
| maison_halteres | 1.92 ± 0.60 | 1.97 ± 0.58 |
| calisthenie_parc | — | 1.44 ± 0.51 |
| douleur_et_lieu | 1.37 ± 0.28 | 1.15 ± 0.40 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 13.1 % | 6.0 % | 5.9 % | 5.1 % | 14.6 % | 7.4 % | 7.3 % | 6.3 % | 86 % |
| debutant_salle | L7/L11 | 12.5 % | 12.5 % | 12.9 % | 13.8 % | 11.7 % | 10.8 % | 10.7 % | 10.3 % | 27 % |
| intermediaire_salle | kalis_adapt | 11.9 % | 6.2 % | 5.2 % | 4.5 % | 13.1 % | 8.2 % | 7.8 % | 7.1 % | 89 % |
| intermediaire_salle | L7/L11 | 6.1 % | 4.5 % | 6.1 % | 6.8 % | 7.3 % | 8.2 % | 6.9 % | 6.3 % | 49 % |
| avance_street | kalis_adapt | 10.4 % | 6.6 % | 5.5 % | 4.8 % | 11.5 % | 8.1 % | 7.0 % | 6.1 % | 85 % |
| avance_street | L7/L11 | 6.5 % | 5.9 % | 5.5 % | 8.0 % | 6.5 % | 5.4 % | 4.7 % | 4.7 % | 57 % |
| notes_paresseuses | kalis_adapt | 11.2 % | 6.9 % | 4.9 % | 2.2 % | 12.3 % | 8.2 % | 6.5 % | 3.8 % | 90 % |
| notes_paresseuses | L7/L11 | 8.2 % | 7.0 % | 7.5 % | 7.5 % | 9.1 % | 8.7 % | 7.0 % | 6.0 % | 46 % |
| irregulier | kalis_adapt | 11.1 % | 5.6 % | 4.7 % | 1.9 % | 12.5 % | 6.9 % | 6.5 % | 4.1 % | 91 % |
| irregulier | L7/L11 | 6.3 % | 5.9 % | 5.5 % | 7.7 % | 9.4 % | 9.1 % | 8.9 % | 6.5 % | 45 % |
| maison_halteres | kalis_adapt | 15.8 % | 10.9 % | 10.1 % | 8.8 % | 16.4 % | 12.2 % | 11.8 % | 10.7 % | 70 % |
| maison_halteres | L7/L11 | 14.1 % | 12.1 % | 12.2 % | 10.6 % | 11.7 % | 10.8 % | 10.2 % | 9.4 % | 42 % |
| calisthenie_parc | kalis_adapt | 26.2 % | 22.5 % | 20.8 % | 15.6 % | 26.2 % | 22.5 % | 20.8 % | 15.6 % | 47 % |
| douleur_et_lieu | kalis_adapt | 11.6 % | 5.2 % | 4.3 % | 4.7 % | 12.8 % | 7.2 % | 6.3 % | 6.1 % | 87 % |
| douleur_et_lieu | L7/L11 | 8.8 % | 6.7 % | 7.0 % | 7.2 % | 7.0 % | 7.8 % | 8.6 % | 7.3 % | 41 % |

### Mouvements principaux seulement

L'ancien moteur L7 n'estimait que les mouvements principaux, à partir d'un niveau déclaré : la comparaison se fait sur eux.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 |
| --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 15.0 % | 2.9 % | 2.1 % | 1.8 % |
| debutant_salle | L7/L11 | 12.5 % | 12.5 % | 12.9 % | 13.8 % |
| intermediaire_salle | kalis_adapt | 3.3 % | 1.6 % | 1.2 % | 1.4 % |
| intermediaire_salle | L7/L11 | 6.1 % | 4.5 % | 6.1 % | 6.8 % |
| avance_street | kalis_adapt | 2.5 % | 2.0 % | 1.7 % | 1.6 % |
| avance_street | L7/L11 | 6.5 % | 5.9 % | 5.5 % | 8.0 % |
| notes_paresseuses | kalis_adapt | 8.1 % | 4.0 % | 2.9 % | 1.2 % |
| notes_paresseuses | L7/L11 | 8.2 % | 7.0 % | 7.5 % | 7.5 % |
| irregulier | kalis_adapt | 12.6 % | 1.7 % | 1.4 % | 1.1 % |
| irregulier | L7/L11 | 6.3 % | 5.9 % | 5.5 % | 7.7 % |
| maison_halteres | kalis_adapt | 18.5 % | 6.9 % | 5.2 % | 3.9 % |
| maison_halteres | L7/L11 | 14.1 % | 12.1 % | 12.2 % | 10.6 % |
| calisthenie_parc | kalis_adapt | 19.1 % | 11.9 % | 9.8 % | 9.2 % |
| douleur_et_lieu | kalis_adapt | 8.8 % | 2.1 % | 1.1 % | 1.5 % |
| douleur_et_lieu | L7/L11 | 8.8 % | 6.7 % | 7.0 % | 7.2 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'un mouvement principal par rapport à la plus forte charge de sa séance précédente, à partir de la 4ᵉ séance de l'exercice et hors semaines de test. Hausses > 10 % : celles qui franchissent plus d'un cran de la grille (ce que l'invariant I1 interdit à `kalis_adapt`), et celles d'un seul cran (le plus petit cran du matériel dépasse 10 %), sur toutes les simulations. Aggravations : hausses de charge sur une zone signalée douloureuse, par simulation.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 %, plusieurs crans | Hausses > 10 %, un cran | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 41.2 | 57.0 % | 20.0 % | 0 | 11 | 36.3 % | 0.00 |
| debutant_salle | double_progression | 69.0 | 71.2 % | 25.0 % | 0 | 31 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 56.8 | 70.2 % | 18.2 % | 1 | 11 | 0.0 % | 0.00 |
| debutant_salle | oracle | 62.7 | 77.8 % | 25.0 % | 9 | 15 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 44.5 | 60.7 % | 11.1 % | 0 | 1 | 29.5 % | 0.00 |
| intermediaire_salle | double_progression | 87.0 | 71.2 % | 12.5 % | 0 | 4 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 84.7 | 71.5 % | 14.3 % | 2 | 15 | 0.0 % | 0.00 |
| intermediaire_salle | oracle | 60.0 | 71.0 % | 17.4 % | 8 | 10 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 61.2 | 56.4 % | 9.4 % | 0 | 0 | 31.1 % | 0.00 |
| avance_street | double_progression | 84.2 | 41.9 % | 3.0 % | 0 | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 124.5 | 54.4 % | 8.8 % | 0 | 0 | 0.0 % | 0.00 |
| avance_street | oracle | 114.2 | 64.1 % | 12.6 % | 3 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 24.5 | 43.0 % | 8.0 % | 0 | 0 | 14.4 % | 0.00 |
| notes_paresseuses | double_progression | 52.0 | 57.2 % | 4.8 % | 0 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 53.8 | 53.3 % | 6.1 % | 0 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | oracle | 89.5 | 69.3 % | 13.5 % | 4 | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 26.3 | 39.5 % | 6.3 % | 0 | 0 | 15.8 % | 0.00 |
| irregulier | double_progression | 36.0 | 33.4 % | 7.7 % | 0 | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 50.2 | 48.9 % | 30.8 % | 10 | 0 | 0.0 % | 0.00 |
| irregulier | oracle | 75.5 | 66.6 % | 20.0 % | 10 | 0 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 28.8 | 66.8 % | 50.0 % | 0 | 22 | 15.7 % | 0.00 |
| maison_halteres | double_progression | 90.8 | 84.1 % | 33.3 % | 0 | 104 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 52.2 | 76.2 % | 50.0 % | 0 | 16 | 0.0 % | 0.00 |
| maison_halteres | oracle | 22.3 | 71.7 % | 25.0 % | 0 | 29 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 4.3 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | oracle | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 43.0 | 61.4 % | 20.0 % | 0 | 10 | 39.4 % | 0.00 |
| douleur_et_lieu | double_progression | 64.7 | 64.5 % | 20.0 % | 0 | 26 | 0.0 % | 11.50 |
| douleur_et_lieu | L7/L11 | 77.3 | 66.0 % | 20.0 % | 1 | 19 | 0.0 % | 13.50 |
| douleur_et_lieu | oracle | 63.8 | 73.5 % | 14.3 % | 0 | 5 | 0.0 % | 1.83 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.49 ± 0.47 | 0.31 ± 0.03 % | 0.3 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.35 ± 0.55 | 0.07 ± 0.01 % | 1.7 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| avance_street | 1.13 ± 0.11 | -0.00 ± 0.00 % | 7.0 | 1.3 | 1.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| notes_paresseuses | 1.25 ± 0.29 | 0.07 ± 0.03 % | 1.0 | 0.0 | 1.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.32 ± 0.34 | 0.05 ± 0.02 % | 3.0 | 0.0 | 1.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| maison_halteres | 1.96 ± 0.83 | 0.34 ± 0.02 % | 0.3 | 0.0 | 0.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 1.71 ± 0.66 | -0.22 ± 0.40 % | 1.7 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 1.45 ± 0.55 | 0.08 ± 0.01 % | 4.3 | 0.0 | 2.7 | 0.0 | 0.0 | 0.0 | 0.0 % |

| Athlète | Volume | Échange d'exercice | Restructuration de séance | Restructuration de bloc |
| --- | --- | --- | --- | --- |
| debutant_salle | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 6.0 (3/3) | semaine 11.0 (3/3) |
| intermediaire_salle | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 6.0 (3/3) | semaine 11.0 (3/3) |
| avance_street | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 7.0 (3/3) | semaine 13.0 (3/3) |
| notes_paresseuses | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 6.0 (3/3) | semaine 11.0 (3/3) |
| irregulier | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 6.0 (3/3) | semaine 11.0 (3/3) |
| maison_halteres | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 5.0 (3/3) | semaine 10.0 (3/3) |
| calisthenie_parc | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 5.0 (3/3) | semaine 10.0 (3/3) |
| douleur_et_lieu | semaine 2.0 (3/3) | semaine 4.0 (3/3) | semaine 6.0 (3/3) | semaine 11.7 (3/3) |

Candidates retenues par la revue, par simulation (nature : cause — `unlock` niveau de déblocage pas encore atteint, `confidence` confiance sous le seuil du niveau, `utility` utilité nulle ou négative, `refused` refus récent, `settled` déjà décidée, `recent_swap` échange trop récent, `scope` changement qui déborde de sa portée, `no_change` et `plan_error` rien à proposer par `kalis_plan`) :

| Athlète | Candidates retenues |
| --- | --- |
| debutant_salle | exercise_swap:unlock 2.0 |
| intermediaire_salle | exercise_swap:scope 2.0 |
| avance_street | deload:confidence 0.7 |
| notes_paresseuses | — |
| irregulier | block_restructure:no_change 3.3 ; block_restructure:unlock 0.7 |
| maison_halteres | block_restructure:no_change 0.3 ; exercise_swap:scope 1.0 |
| calisthenie_parc | exercise_swap:scope 3.0 |
| douleur_et_lieu | exercise_swap:recent_swap 0.3 ; exercise_swap:scope 0.3 ; exercise_swap:unlock 2.0 ; pain_sparing:no_change 3.3 |

## 5. Temps de calcul

Mesurés par le simulateur sur la machine de contrôle (le moteur n'a pas d'horloge), sur 117 séances et 1766 conseils de l'athlète `avance_street`, après une première simulation non mesurée (le code est alors compilé, comme il l'est d'avance sur téléphone). « À froid » : instance neuve, tout le journal rejoué (117 séances). Machine : linux, 4 cœurs — pas un téléphone.

| Opération | Médiane | 95ᵉ centile | 99ᵉ centile | Maximum | Cible |
| --- | --- | --- | --- | --- | --- |
| Décision de séance (`prescribeSession`) | 0.06 ms | 0.12 ms | 6.63 ms | 10.89 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.07 ms | 0.14 ms | 0.22 ms | 3.73 ms | ≤ 5 ms |
| Revue (`review`) | 1.08 ms | 1.16 ms | 1.17 ms | 1.17 ms | — |
| Décision de séance à froid | 13.15 ms | 18.75 ms | 19.56 ms | 19.56 ms | — |
