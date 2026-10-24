# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 1.0.8) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 200 graines × 4 politiques (dont l'oracle) à programme égal, puis 40 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. « oracle » n'est pas un moteur : c'est la politique qui connaît la vérité de l'athlète ; son écart est le plancher qu'imposent la grille des charges, l'arrondi des répétitions et la plage. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 1.28 ± 0.03 | 0.62 | 96 % | 1.37 | 0.91 ± 0.10 % | 1.98 ± 0.17 % | 0.43 ± 0.00 % |
| debutant_salle | double_progression | 1.98 ± 0.06 | 1.57 | 97 % | 2.15 | 3.17 ± 0.27 % | 2.43 ± 0.20 % | 0.45 ± 0.01 % |
| debutant_salle | L7/L11 | 3.43 ± 0.09 | 2.83 | 97 % | 3.57 | 3.81 ± 0.30 % | 3.83 ± 0.25 % | 0.45 ± 0.00 % |
| debutant_salle | oracle | 0.25 ± 0.00 | 0.03 | 97 % | 0.26 | 0.12 ± 0.03 % | 0.11 ± 0.02 % | 0.42 ± 0.00 % |
| intermediaire_salle | kalis_adapt | 1.22 ± 0.03 | 0.28 | 92 % | 1.60 | 0.80 ± 0.09 % | 2.01 ± 0.17 % | 0.04 ± 0.00 % |
| intermediaire_salle | double_progression | 2.58 ± 0.08 | 2.35 | 89 % | 3.61 | 2.77 ± 0.15 % | 2.79 ± 0.16 % | 0.03 ± 0.00 % |
| intermediaire_salle | L7/L11 | 4.13 ± 0.10 | 3.50 | 88 % | 5.01 | 3.21 ± 0.17 % | 4.48 ± 0.22 % | 0.02 ± 0.00 % |
| intermediaire_salle | oracle | 0.27 ± 0.00 | 0.04 | 89 % | 0.63 | 2.60 ± 0.15 % | 2.52 ± 0.14 % | 0.03 ± 0.00 % |
| avance_street | kalis_adapt | 0.99 ± 0.02 | 0.10 | 85 % | 1.60 | 0.58 ± 0.05 % | 1.69 ± 0.10 % | -0.00 ± 0.00 % |
| avance_street | double_progression | 2.05 ± 0.04 | 1.71 | 83 % | 3.75 | 4.10 ± 0.26 % | 2.46 ± 0.16 % | -0.00 ± 0.00 % |
| avance_street | L7/L11 | 2.47 ± 0.05 | 1.78 | 83 % | 4.17 | 4.75 ± 0.28 % | 3.96 ± 0.18 % | -0.00 ± 0.00 % |
| avance_street | oracle | 0.24 ± 0.00 | 0.02 | 83 % | 1.06 | 0.00 ± 0.00 % | 0.01 ± 0.01 % | -0.00 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 1.49 ± 0.06 | 0.69 | 89 % | 1.77 | 0.88 ± 0.08 % | 2.24 ± 0.19 % | 0.08 ± 0.00 % |
| notes_paresseuses | double_progression | 2.68 ± 0.08 | 2.49 | 89 % | 3.69 | 0.09 ± 0.03 % | 0.19 ± 0.04 % | 0.08 ± 0.00 % |
| notes_paresseuses | L7/L11 | 4.91 ± 0.15 | 4.57 | 88 % | 5.69 | 0.46 ± 0.05 % | 1.37 ± 0.10 % | 0.07 ± 0.00 % |
| notes_paresseuses | oracle | 0.28 ± 0.00 | 0.05 | 88 % | 0.62 | 0.02 ± 0.02 % | 0.02 ± 0.02 % | 0.11 ± 0.00 % |
| irregulier | kalis_adapt | 1.18 ± 0.03 | 0.42 | 88 % | 1.77 | 0.49 ± 0.07 % | 1.56 ± 0.15 % | 0.07 ± 0.00 % |
| irregulier | double_progression | 2.44 ± 0.11 | 2.24 | 88 % | 4.03 | 0.21 ± 0.11 % | 0.25 ± 0.08 % | 0.07 ± 0.00 % |
| irregulier | L7/L11 | 3.44 ± 0.13 | 2.87 | 88 % | 4.99 | 0.72 ± 0.14 % | 1.78 ± 0.18 % | 0.06 ± 0.00 % |
| irregulier | oracle | 0.28 ± 0.01 | 0.05 | 88 % | 0.98 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.00 % |
| maison_halteres | kalis_adapt | 1.79 ± 0.07 | 1.20 | 92 % | 1.91 | 0.82 ± 0.08 % | 1.36 ± 0.11 % | 0.29 ± 0.00 % |
| maison_halteres | double_progression | 3.41 ± 0.11 | 2.96 | 93 % | 3.73 | 2.69 ± 0.30 % | 2.05 ± 0.21 % | 0.29 ± 0.00 % |
| maison_halteres | L7/L11 | 5.97 ± 0.20 | 5.35 | 93 % | 6.08 | 3.15 ± 0.31 % | 3.09 ± 0.22 % | 0.28 ± 0.00 % |
| maison_halteres | oracle | 0.35 ± 0.01 | 0.14 | 92 % | 0.38 | 0.03 ± 0.03 % | 0.03 ± 0.02 % | 0.33 ± 0.00 % |
| calisthenie_parc | kalis_adapt | 1.24 ± 0.06 | 0.95 | 53 % | 3.02 | 0.06 ± 0.02 % | 0.09 ± 0.03 % | 0.16 ± 0.00 % |
| calisthenie_parc | double_progression | 3.42 ± 0.11 | 3.34 | 53 % | 7.14 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.11 ± 0.00 % |
| calisthenie_parc | L7/L11 | 3.42 ± 0.11 | 3.34 | 53 % | 7.14 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.11 ± 0.00 % |
| calisthenie_parc | oracle | 0.33 ± 0.01 | 0.11 | 52 % | 2.83 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.19 ± 0.00 % |
| douleur_et_lieu | kalis_adapt | 1.26 ± 0.03 | 0.47 | 92 % | 1.46 | 0.69 ± 0.08 % | 2.00 ± 0.17 % | 0.02 ± 0.00 % |
| douleur_et_lieu | double_progression | 2.17 ± 0.07 | 1.93 | 90 % | 2.63 | 0.43 ± 0.10 % | 0.49 ± 0.09 % | 0.05 ± 0.00 % |
| douleur_et_lieu | L7/L11 | 3.47 ± 0.10 | 2.86 | 90 % | 3.78 | 0.95 ± 0.13 % | 2.30 ± 0.17 % | 0.04 ± 0.00 % |
| douleur_et_lieu | oracle | 0.27 ± 0.00 | 0.03 | 90 % | 0.39 | 0.08 ± 0.03 % | 0.08 ± 0.03 % | 0.03 ± 0.00 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | -0.69 ± 0.04 | -2.15 ± 0.08 | -0.01 ± 0.00 % | -0.01 ± 0.00 % |
| intermediaire_salle | -1.36 ± 0.07 | -2.91 ± 0.09 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| avance_street | -1.06 ± 0.04 | -1.47 ± 0.04 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -1.19 ± 0.08 | -3.42 ± 0.14 | 0.00 ± 0.00 % | 0.02 ± 0.00 % |
| irregulier | -1.26 ± 0.10 | -2.26 ± 0.12 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| maison_halteres | -1.62 ± 0.09 | -4.18 ± 0.19 | 0.00 ± 0.00 % | 0.02 ± 0.00 % |
| calisthenie_parc | -2.18 ± 0.10 | -2.18 ± 0.10 | 0.05 ± 0.00 % | 0.05 ± 0.00 % |
| douleur_et_lieu | -0.91 ± 0.06 | -2.22 ± 0.10 | -0.03 ± 0.00 % | -0.03 ± 0.00 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 1.25 ± 0.03 | 1.36 ± 0.06 |
| intermediaire_salle | 1.21 ± 0.03 | 1.31 ± 0.07 |
| avance_street | 1.06 ± 0.02 | 0.91 ± 0.03 |
| notes_paresseuses | 1.52 ± 0.07 | 1.42 ± 0.07 |
| irregulier | 1.12 ± 0.02 | 1.42 ± 0.08 |
| maison_halteres | 1.92 ± 0.08 | 1.65 ± 0.07 |
| calisthenie_parc | — | 1.24 ± 0.06 |
| douleur_et_lieu | 1.30 ± 0.04 | 1.13 ± 0.05 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 11.9 % | 6.3 % | 5.8 % | 4.3 % | 12.9 % | 8.0 % | 7.8 % | 6.2 % | 85 % |
| debutant_salle | L7/L11 | 10.7 % | 10.0 % | 10.7 % | 10.7 % | 9.4 % | 8.1 % | 7.6 % | 7.6 % | 50 % |
| intermediaire_salle | kalis_adapt | 12.3 % | 4.6 % | 3.9 % | 3.0 % | 13.9 % | 7.5 % | 6.9 % | 5.9 % | 91 % |
| intermediaire_salle | L7/L11 | 7.8 % | 6.8 % | 6.2 % | 6.5 % | 7.5 % | 7.4 % | 6.9 % | 6.5 % | 50 % |
| avance_street | kalis_adapt | 11.4 % | 7.1 % | 6.0 % | 5.1 % | 12.4 % | 8.6 % | 7.5 % | 6.5 % | 83 % |
| avance_street | L7/L11 | 5.7 % | 5.2 % | 5.3 % | 6.6 % | 5.9 % | 5.9 % | 4.7 % | 4.0 % | 59 % |
| notes_paresseuses | kalis_adapt | 13.6 % | 8.2 % | 5.4 % | 3.8 % | 14.8 % | 10.0 % | 7.5 % | 6.0 % | 86 % |
| notes_paresseuses | L7/L11 | 8.7 % | 7.4 % | 7.3 % | 6.2 % | 9.0 % | 7.8 % | 7.5 % | 7.7 % | 29 % |
| irregulier | kalis_adapt | 11.2 % | 6.2 % | 5.8 % | 2.7 % | 12.5 % | 8.3 % | 7.7 % | 5.1 % | 83 % |
| irregulier | L7/L11 | 7.1 % | 5.8 % | 5.2 % | 5.2 % | 8.4 % | 9.2 % | 8.9 % | 8.5 % | 34 % |
| maison_halteres | kalis_adapt | 13.7 % | 7.9 % | 6.4 % | 6.2 % | 14.4 % | 9.4 % | 8.2 % | 7.8 % | 78 % |
| maison_halteres | L7/L11 | 12.9 % | 11.3 % | 11.2 % | 11.6 % | 11.5 % | 10.3 % | 9.7 % | 9.6 % | 43 % |
| calisthenie_parc | kalis_adapt | 22.4 % | 17.4 % | 15.1 % | 15.4 % | 22.4 % | 17.4 % | 15.1 % | 15.4 % | 56 % |
| douleur_et_lieu | kalis_adapt | 11.9 % | 5.4 % | 4.2 % | 4.7 % | 13.4 % | 7.8 % | 6.7 % | 6.8 % | 88 % |
| douleur_et_lieu | L7/L11 | 8.3 % | 6.6 % | 6.8 % | 6.6 % | 9.5 % | 9.3 % | 8.9 % | 8.4 % | 36 % |

### Mouvements principaux seulement

L'ancien moteur L7 n'estimait que les mouvements principaux, à partir d'un niveau déclaré : la comparaison se fait sur eux.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 |
| --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 10.5 % | 4.0 % | 3.3 % | 3.1 % |
| debutant_salle | L7/L11 | 10.7 % | 10.0 % | 10.7 % | 10.7 % |
| intermediaire_salle | kalis_adapt | 6.8 % | 2.3 % | 1.7 % | 1.3 % |
| intermediaire_salle | L7/L11 | 7.8 % | 6.8 % | 6.2 % | 6.5 % |
| avance_street | kalis_adapt | 2.8 % | 1.7 % | 1.8 % | 1.5 % |
| avance_street | L7/L11 | 5.7 % | 5.2 % | 5.3 % | 6.6 % |
| notes_paresseuses | kalis_adapt | 10.1 % | 5.6 % | 3.9 % | 2.7 % |
| notes_paresseuses | L7/L11 | 8.7 % | 7.4 % | 7.3 % | 6.2 % |
| irregulier | kalis_adapt | 9.0 % | 4.6 % | 3.2 % | 2.9 % |
| irregulier | L7/L11 | 7.1 % | 5.8 % | 5.2 % | 5.2 % |
| maison_halteres | kalis_adapt | 13.2 % | 4.9 % | 3.5 % | 2.9 % |
| maison_halteres | L7/L11 | 12.9 % | 11.3 % | 11.2 % | 11.6 % |
| calisthenie_parc | kalis_adapt | 17.5 % | 11.5 % | 8.9 % | 8.0 % |
| douleur_et_lieu | kalis_adapt | 10.1 % | 4.0 % | 2.3 % | 2.1 % |
| douleur_et_lieu | L7/L11 | 8.3 % | 6.6 % | 6.8 % | 6.6 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'un mouvement principal par rapport à la plus forte charge de sa séance précédente, à partir de la 4ᵉ séance de l'exercice et hors semaines de test. Hausses > 10 % : celles qui franchissent plus d'un cran de la grille (ce que l'invariant I1 interdit à `kalis_adapt`), et celles d'un seul cran (le plus petit cran du matériel dépasse 10 %), sur toutes les simulations. Aggravations : hausses de charge sur une zone signalée douloureuse, par simulation.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 %, plusieurs crans | Hausses > 10 %, un cran | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 42.5 | 57.9 % | 25.0 % | 0 | 409 | 15.9 % | 0.00 |
| debutant_salle | double_progression | 62.6 | 69.2 % | 33.3 % | 0 | 861 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 59.0 | 67.0 % | 40.0 % | 34 | 237 | 0.0 % | 0.00 |
| debutant_salle | oracle | 59.7 | 71.5 % | 25.0 % | 163 | 468 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 47.4 | 58.4 % | 16.7 % | 0 | 143 | 32.6 % | 0.00 |
| intermediaire_salle | double_progression | 91.7 | 67.8 % | 16.7 % | 0 | 488 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 93.4 | 66.6 % | 16.7 % | 72 | 630 | 0.0 % | 0.00 |
| intermediaire_salle | oracle | 58.3 | 68.7 % | 22.2 % | 174 | 546 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 54.0 | 56.0 % | 10.0 % | 0 | 0 | 29.7 % | 0.00 |
| avance_street | double_progression | 75.2 | 36.8 % | 3.1 % | 0 | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 113.0 | 53.7 % | 14.3 % | 26 | 0 | 0.0 % | 0.00 |
| avance_street | oracle | 107.4 | 64.8 % | 14.6 % | 96 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 27.5 | 43.4 % | 9.7 % | 0 | 0 | 14.0 % | 0.00 |
| notes_paresseuses | double_progression | 61.7 | 61.4 % | 4.5 % | 0 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 51.6 | 52.8 % | 21.7 % | 10 | 0 | 0.0 % | 0.00 |
| notes_paresseuses | oracle | 81.3 | 71.5 % | 16.0 % | 106 | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 27.8 | 46.1 % | 9.1 % | 0 | 0 | 21.5 % | 0.00 |
| irregulier | double_progression | 40.3 | 31.2 % | 2.9 % | 0 | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 54.2 | 47.6 % | 41.9 % | 226 | 0 | 0.0 % | 0.00 |
| irregulier | oracle | 76.6 | 66.2 % | 20.4 % | 174 | 0 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 31.7 | 61.8 % | 50.0 % | 0 | 885 | 15.8 % | 0.00 |
| maison_halteres | double_progression | 91.9 | 81.9 % | 50.0 % | 0 | 2821 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 55.8 | 74.6 % | 50.0 % | 0 | 595 | 0.0 % | 0.00 |
| maison_halteres | oracle | 26.8 | 72.1 % | 33.3 % | 2 | 1218 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 5.2 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| calisthenie_parc | oracle | 0.0 | 0.0 % | 0.0 % | 0 | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 41.7 | 56.1 % | 50.0 % | 0 | 281 | 28.3 % | 0.00 |
| douleur_et_lieu | double_progression | 93.5 | 71.1 % | 33.3 % | 0 | 767 | 0.0 % | 16.01 |
| douleur_et_lieu | L7/L11 | 95.1 | 66.2 % | 33.3 % | 30 | 294 | 0.0 % | 12.71 |
| douleur_et_lieu | oracle | 76.8 | 73.3 % | 25.0 % | 125 | 441 | 0.0 % | 4.87 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.19 ± 0.06 | 0.40 ± 0.01 % | 0.6 | 0.0 | 0.5 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.21 ± 0.06 | 0.03 ± 0.01 % | 2.5 | 0.1 | 3.1 | 0.0 | 0.0 | 0.0 | 0.0 % |
| avance_street | 0.96 ± 0.02 | 0.00 ± 0.00 % | 3.3 | 1.4 | 0.8 | 0.0 | 0.0 | 0.0 | 1.1 % |
| notes_paresseuses | 1.39 ± 0.12 | 0.05 ± 0.01 % | 2.8 | 0.0 | 1.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.11 ± 0.05 | 0.03 ± 0.01 % | 1.6 | 0.0 | 0.5 | 0.0 | 0.0 | 0.0 | 1.1 % |
| maison_halteres | 1.52 ± 0.09 | 0.35 ± 0.01 % | 0.8 | 0.0 | 0.9 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 1.21 ± 0.10 | 0.20 ± 0.01 % | 0.4 | 0.0 | 0.4 | 0.0 | 0.0 | 0.1 | 0.0 % |
| douleur_et_lieu | 1.39 ± 0.12 | 0.01 ± 0.01 % | 2.8 | 0.1 | 1.9 | 0.0 | 0.0 | 0.0 | 0.0 % |

| Athlète | Volume | Échange d'exercice | Restructuration de séance | Restructuration de bloc |
| --- | --- | --- | --- | --- |
| debutant_salle | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| intermediaire_salle | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| avance_street | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 7.0 (40/40) | semaine 13.0 (40/40) |
| notes_paresseuses | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.1 (40/40) |
| irregulier | semaine 2.1 (40/40) | semaine 4.1 (40/40) | semaine 6.0 (40/40) | semaine 11.0 (40/40) |
| maison_halteres | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 5.0 (40/40) | semaine 10.0 (40/40) |
| calisthenie_parc | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 5.0 (40/40) | semaine 10.0 (40/40) |
| douleur_et_lieu | semaine 2.0 (40/40) | semaine 4.0 (40/40) | semaine 6.0 (40/40) | semaine 11.3 (40/40) |

Candidates retenues par la revue, par simulation (nature : cause — `unlock` niveau de déblocage pas encore atteint, `confidence` confiance sous le seuil du niveau, `utility` utilité nulle ou négative, `refused` refus récent, `settled` déjà décidée, `recent_swap` échange trop récent, `scope` changement qui déborde de sa portée, `no_change` et `plan_error` rien à proposer par `kalis_plan`) :

| Athlète | Candidates retenues |
| --- | --- |
| debutant_salle | block_restructure:no_change 0.1 ; block_restructure:unlock 0.1 ; exercise_swap:recent_swap 0.1 |
| intermediaire_salle | block_restructure:no_change 0.0 ; block_restructure:unlock 0.1 ; deload:confidence 0.0 ; exercise_swap:recent_swap 0.6 ; exercise_swap:scope 2.1 ; exercise_swap:unlock 2.4 ; volume:confidence 0.1 |
| avance_street | deload:confidence 0.4 ; exercise_swap:recent_swap 0.1 ; volume:confidence 0.1 |
| notes_paresseuses | block_restructure:no_change 0.1 ; block_restructure:unlock 0.0 ; exercise_swap:recent_swap 0.1 |
| irregulier | block_restructure:no_change 4.5 ; block_restructure:unlock 1.6 ; deload:confidence 0.1 ; exercise_swap:recent_swap 0.1 ; exercise_swap:scope 0.0 ; volume:confidence 0.1 |
| maison_halteres | block_restructure:no_change 0.2 ; block_restructure:unlock 0.2 ; deload:confidence 0.0 ; exercise_swap:recent_swap 0.0 ; exercise_swap:scope 0.0 |
| calisthenie_parc | block_restructure:no_change 0.0 ; block_restructure:unlock 0.1 ; exercise_swap:scope 0.2 |
| douleur_et_lieu | block_restructure:unlock 0.1 ; deload:confidence 0.1 ; exercise_swap:recent_swap 0.1 ; exercise_swap:scope 0.0 ; pain_sparing:no_change 2.4 ; pain_sparing:scope 0.5 ; volume:confidence 0.1 |

## 5. Temps de calcul

Mesurés par le simulateur sur la machine de contrôle (le moteur n'a pas d'horloge), sur 117 séances et 1689 conseils de l'athlète `avance_street`, après une première simulation non mesurée (le code est alors compilé, comme il l'est d'avance sur téléphone). « À froid » : instance neuve, tout le journal rejoué (117 séances). Machine : linux, 4 cœurs — pas un téléphone.

| Opération | Médiane | 95ᵉ centile | 99ᵉ centile | Maximum | Cible |
| --- | --- | --- | --- | --- | --- |
| Décision de séance (`prescribeSession`) | 0.15 ms | 0.22 ms | 6.30 ms | 9.91 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.07 ms | 0.13 ms | 0.16 ms | 2.31 ms | ≤ 5 ms |
| Revue (`review`) | 0.79 ms | 0.83 ms | 1.76 ms | 1.76 ms | — |
| Décision de séance à froid | 12.44 ms | 21.94 ms | 25.89 ms | 25.89 ms | — |
