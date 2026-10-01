# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.1.0) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 200 graines × 4 politiques (dont l'oracle) à programme égal, puis 40 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. « oracle » n'est pas un moteur : c'est la politique qui connaît la vérité de l'athlète ; son écart est le plancher qu'imposent la grille des charges, l'arrondi des répétitions et la plage. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 1.30 ± 0.03 | 0.61 | 96 % | 1.35 | 0.95 ± 0.10 % | 2.11 ± 0.19 % | 0.29 ± 0.01 % |
| debutant_salle | double_progression | 1.96 ± 0.06 | 1.52 | 93 % | 2.08 | 6.67 ± 0.44 % | 5.52 ± 0.33 % | 0.28 ± 0.01 % |
| debutant_salle | L7/L11 | 3.48 ± 0.10 | 2.85 | 93 % | 3.51 | 7.23 ± 0.47 % | 6.93 ± 0.37 % | 0.29 ± 0.00 % |
| debutant_salle | oracle | 0.25 ± 0.00 | 0.03 | 93 % | 0.32 | 2.98 ± 0.19 % | 2.88 ± 0.19 % | 0.24 ± 0.00 % |
| intermediaire_salle | kalis_adapt | 1.22 ± 0.03 | 0.34 | 92 % | 1.55 | 0.88 ± 0.09 % | 2.02 ± 0.16 % | 0.05 ± 0.00 % |
| intermediaire_salle | double_progression | 2.67 ± 0.08 | 2.41 | 89 % | 3.61 | 3.70 ± 0.11 % | 3.70 ± 0.11 % | 0.04 ± 0.00 % |
| intermediaire_salle | L7/L11 | 3.93 ± 0.10 | 3.34 | 88 % | 4.72 | 4.14 ± 0.13 % | 5.26 ± 0.17 % | 0.04 ± 0.00 % |
| intermediaire_salle | oracle | 0.26 ± 0.00 | 0.03 | 88 % | 0.56 | 3.07 ± 0.10 % | 3.01 ± 0.08 % | 0.03 ± 0.00 % |
| avance_street | kalis_adapt | 1.01 ± 0.01 | 0.06 | 82 % | 1.60 | 0.66 ± 0.05 % | 1.97 ± 0.11 % | -0.00 ± 0.00 % |
| avance_street | double_progression | 2.03 ± 0.05 | 1.67 | 81 % | 3.73 | 4.74 ± 0.30 % | 2.74 ± 0.17 % | -0.00 ± 0.00 % |
| avance_street | L7/L11 | 2.59 ± 0.05 | 1.85 | 80 % | 4.27 | 5.64 ± 0.32 % | 4.66 ± 0.21 % | -0.01 ± 0.00 % |
| avance_street | oracle | 0.24 ± 0.00 | 0.02 | 81 % | 1.08 | 0.04 ± 0.03 % | 0.03 ± 0.02 % | -0.00 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 1.39 ± 0.05 | 0.51 | 93 % | 1.75 | 0.92 ± 0.09 % | 2.28 ± 0.19 % | 0.07 ± 0.00 % |
| notes_paresseuses | double_progression | 2.59 ± 0.09 | 2.37 | 93 % | 3.79 | 0.21 ± 0.05 % | 0.26 ± 0.06 % | 0.07 ± 0.00 % |
| notes_paresseuses | L7/L11 | 4.46 ± 0.12 | 4.19 | 93 % | 5.59 | 0.37 ± 0.06 % | 0.87 ± 0.08 % | 0.06 ± 0.00 % |
| notes_paresseuses | oracle | 0.29 ± 0.01 | 0.05 | 93 % | 0.66 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.00 % |
| irregulier | kalis_adapt | 1.19 ± 0.03 | 0.43 | 96 % | 1.36 | 0.50 ± 0.07 % | 1.52 ± 0.15 % | 0.01 ± 0.00 % |
| irregulier | double_progression | 2.53 ± 0.09 | 2.34 | 95 % | 3.20 | 0.25 ± 0.09 % | 0.26 ± 0.07 % | 0.01 ± 0.00 % |
| irregulier | L7/L11 | 3.57 ± 0.12 | 3.09 | 95 % | 4.21 | 0.60 ± 0.11 % | 1.32 ± 0.13 % | -0.00 ± 0.00 % |
| irregulier | oracle | 0.28 ± 0.01 | 0.06 | 95 % | 0.48 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.02 ± 0.00 % |
| maison_halteres | kalis_adapt | 1.73 ± 0.06 | 1.13 | 91 % | 1.85 | 0.82 ± 0.08 % | 1.36 ± 0.12 % | 0.30 ± 0.00 % |
| maison_halteres | double_progression | 3.37 ± 0.10 | 2.95 | 90 % | 3.68 | 2.34 ± 0.28 % | 1.83 ± 0.20 % | 0.29 ± 0.00 % |
| maison_halteres | L7/L11 | 6.18 ± 0.18 | 5.58 | 90 % | 6.18 | 2.76 ± 0.29 % | 2.92 ± 0.22 % | 0.28 ± 0.00 % |
| maison_halteres | oracle | 0.32 ± 0.01 | 0.13 | 90 % | 0.38 | 0.03 ± 0.03 % | 0.03 ± 0.02 % | 0.34 ± 0.00 % |
| calisthenie_parc | kalis_adapt | 1.26 ± 0.07 | 0.99 | 49 % | 3.15 | 0.07 ± 0.02 % | 0.08 ± 0.03 % | 0.07 ± 0.00 % |
| calisthenie_parc | double_progression | 3.54 ± 0.16 | 3.46 | 47 % | 8.09 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.00 % |
| calisthenie_parc | L7/L11 | 3.54 ± 0.16 | 3.46 | 47 % | 8.09 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.00 % |
| calisthenie_parc | oracle | 0.32 ± 0.01 | 0.11 | 45 % | 2.93 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.09 ± 0.00 % |
| douleur_et_lieu | kalis_adapt | 1.19 ± 0.03 | 0.40 | 90 % | 1.40 | 0.62 ± 0.07 % | 1.78 ± 0.15 % | 0.04 ± 0.00 % |
| douleur_et_lieu | double_progression | 2.12 ± 0.06 | 1.84 | 84 % | 2.80 | 4.82 ± 0.19 % | 4.50 ± 0.16 % | 0.05 ± 0.00 % |
| douleur_et_lieu | L7/L11 | 3.33 ± 0.10 | 2.74 | 84 % | 3.78 | 5.15 ± 0.20 % | 5.76 ± 0.20 % | 0.05 ± 0.00 % |
| douleur_et_lieu | oracle | 0.27 ± 0.00 | 0.04 | 84 % | 0.58 | 3.89 ± 0.12 % | 3.79 ± 0.13 % | 0.03 ± 0.00 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | -0.66 ± 0.05 | -2.18 ± 0.10 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| intermediaire_salle | -1.45 ± 0.08 | -2.71 ± 0.09 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| avance_street | -1.02 ± 0.05 | -1.58 ± 0.05 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -1.20 ± 0.08 | -3.07 ± 0.12 | 0.00 ± 0.00 % | 0.01 ± 0.00 % |
| irregulier | -1.34 ± 0.08 | -2.38 ± 0.12 | 0.01 ± 0.00 % | 0.01 ± 0.00 % |
| maison_halteres | -1.64 ± 0.08 | -4.45 ± 0.17 | 0.01 ± 0.00 % | 0.02 ± 0.00 % |
| calisthenie_parc | -2.28 ± 0.15 | -2.28 ± 0.15 | 0.04 ± 0.00 % | 0.04 ± 0.00 % |
| douleur_et_lieu | -0.93 ± 0.06 | -2.14 ± 0.10 | -0.00 ± 0.00 % | -0.00 ± 0.00 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 1.31 ± 0.04 | 1.26 ± 0.05 |
| intermediaire_salle | 1.19 ± 0.03 | 1.31 ± 0.06 |
| avance_street | 1.07 ± 0.02 | 0.90 ± 0.03 |
| notes_paresseuses | 1.28 ± 0.05 | 1.82 ± 0.08 |
| irregulier | 1.12 ± 0.02 | 1.49 ± 0.06 |
| maison_halteres | 1.87 ± 0.07 | 1.54 ± 0.07 |
| calisthenie_parc | — | 1.26 ± 0.07 |
| douleur_et_lieu | 1.23 ± 0.04 | 1.07 ± 0.04 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 12.7 % | 6.3 % | 6.0 % | 4.3 % | 13.6 % | 8.0 % | 7.8 % | 6.2 % | 86 % |
| debutant_salle | L7/L11 | 10.3 % | 9.0 % | 9.6 % | 9.4 % | 9.1 % | 8.1 % | 7.6 % | 7.6 % | 46 % |
| intermediaire_salle | kalis_adapt | 12.3 % | 5.7 % | 4.7 % | 3.8 % | 13.6 % | 8.1 % | 7.2 % | 6.3 % | 88 % |
| intermediaire_salle | L7/L11 | 7.3 % | 5.4 % | 6.0 % | 5.6 % | 7.4 % | 7.6 % | 6.9 % | 6.6 % | 45 % |
| avance_street | kalis_adapt | 10.4 % | 6.6 % | 5.7 % | 4.9 % | 11.6 % | 8.2 % | 7.2 % | 6.3 % | 83 % |
| avance_street | L7/L11 | 5.8 % | 5.4 % | 5.9 % | 7.1 % | 5.9 % | 6.0 % | 5.0 % | 4.1 % | 57 % |
| notes_paresseuses | kalis_adapt | 12.2 % | 7.3 % | 5.1 % | 2.5 % | 13.3 % | 9.0 % | 6.9 % | 4.6 % | 88 % |
| notes_paresseuses | L7/L11 | 9.1 % | 7.2 % | 7.4 % | 6.2 % | 8.3 % | 8.1 % | 7.6 % | 7.9 % | 30 % |
| irregulier | kalis_adapt | 10.4 % | 5.7 % | 4.9 % | 2.2 % | 11.6 % | 7.7 % | 7.1 % | 5.1 % | 89 % |
| irregulier | L7/L11 | 7.7 % | 6.3 % | 5.8 % | 6.0 % | 8.6 % | 8.1 % | 7.7 % | 7.5 % | 39 % |
| maison_halteres | kalis_adapt | 15.5 % | 9.5 % | 8.6 % | 7.6 % | 16.3 % | 11.0 % | 10.2 % | 9.5 % | 76 % |
| maison_halteres | L7/L11 | 13.7 % | 12.1 % | 11.9 % | 12.2 % | 11.2 % | 10.1 % | 9.5 % | 9.4 % | 44 % |
| calisthenie_parc | kalis_adapt | 24.9 % | 20.7 % | 19.2 % | 16.1 % | 24.9 % | 20.7 % | 19.2 % | 16.1 % | 53 % |
| douleur_et_lieu | kalis_adapt | 11.9 % | 4.6 % | 3.9 % | 3.9 % | 13.3 % | 6.8 % | 6.1 % | 6.0 % | 89 % |
| douleur_et_lieu | L7/L11 | 8.3 % | 6.7 % | 6.9 % | 6.7 % | 9.2 % | 8.8 % | 8.5 % | 8.3 % | 36 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'une séance à l'autre sur un mouvement principal, après calibrage (un seul cran de grille peut dépasser 10 % quand le plus petit cran du matériel est plus grand). Aggravations : hausses de charge sur une zone signalée douloureuse.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 % | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 42.4 | 59.3 % | 40.0 % | 499 | 34.8 % | 0.00 |
| debutant_salle | double_progression | 63.8 | 69.9 % | 33.3 % | 873 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 57.6 | 66.9 % | 50.0 % | 288 | 0.0 % | 0.00 |
| debutant_salle | oracle | 62.9 | 73.9 % | 25.0 % | 776 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 43.9 | 60.9 % | 19.1 % | 119 | 28.2 % | 0.00 |
| intermediaire_salle | double_progression | 85.9 | 70.9 % | 12.5 % | 215 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 86.4 | 70.8 % | 22.2 % | 534 | 0.0 % | 0.00 |
| intermediaire_salle | oracle | 60.0 | 72.5 % | 25.0 % | 491 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 58.2 | 57.3 % | 9.9 % | 0 | 30.6 % | 0.00 |
| avance_street | double_progression | 79.3 | 38.1 % | 3.2 % | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 120.7 | 54.4 % | 17.0 % | 50 | 0.0 % | 0.00 |
| avance_street | oracle | 116.0 | 64.7 % | 15.3 % | 76 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 28.6 | 40.1 % | 15.8 % | 11 | 14.1 % | 0.00 |
| notes_paresseuses | double_progression | 52.2 | 51.8 % | 5.9 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 55.5 | 48.7 % | 20.8 % | 25 | 0.0 % | 0.00 |
| notes_paresseuses | oracle | 97.2 | 72.1 % | 18.2 % | 149 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 27.0 | 43.0 % | 14.3 % | 5 | 16.1 % | 0.00 |
| irregulier | double_progression | 39.0 | 29.9 % | 9.1 % | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 52.1 | 46.9 % | 46.7 % | 405 | 0.0 % | 0.00 |
| irregulier | oracle | 75.7 | 65.4 % | 25.0 % | 352 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 28.6 | 63.1 % | 100.0 % | 1171 | 15.7 % | 0.00 |
| maison_halteres | double_progression | 90.0 | 84.0 % | 50.0 % | 3225 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 51.0 | 76.9 % | 50.0 % | 536 | 0.0 % | 0.00 |
| maison_halteres | oracle | 24.7 | 73.3 % | 33.3 % | 984 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 4.6 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| calisthenie_parc | oracle | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 38.0 | 57.9 % | 50.0 % | 346 | 39.3 % | 0.00 |
| douleur_et_lieu | double_progression | 67.8 | 67.9 % | 33.3 % | 763 | 0.0 % | 15.47 |
| douleur_et_lieu | L7/L11 | 77.2 | 65.0 % | 33.3 % | 342 | 0.0 % | 12.83 |
| douleur_et_lieu | oracle | 73.7 | 74.3 % | 25.0 % | 564 | 0.0 % | 5.66 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.18 ± 0.06 | 0.27 ± 0.01 % | 0.6 | 0.0 | 3.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.14 ± 0.04 | 0.05 ± 0.01 % | 1.3 | 0.1 | 5.4 | 0.0 | 0.0 | 0.0 | 1.1 % |
| avance_street | 0.99 ± 0.03 | -0.01 ± 0.00 % | 5.9 | 1.6 | 5.9 | 0.0 | 0.0 | 0.0 | 2.4 % |
| notes_paresseuses | 1.31 ± 0.08 | 0.06 ± 0.00 % | 1.1 | 0.0 | 3.1 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.15 ± 0.05 | 0.00 ± 0.02 % | 1.2 | 0.0 | 2.1 | 0.0 | 0.0 | 0.0 | 1.1 % |
| maison_halteres | 1.50 ± 0.12 | 0.34 ± 0.01 % | 0.7 | 0.0 | 2.1 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 1.27 ± 0.11 | 0.14 ± 0.01 % | 0.3 | 0.0 | 1.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 1.18 ± 0.08 | 0.05 ± 0.01 % | 3.1 | 0.0 | 5.5 | 1.0 | 0.0 | 0.0 | 0.5 % |

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

## 5. Temps de calcul

Mesurés par le simulateur sur la machine de contrôle (le moteur n'a pas d'horloge), sur 117 séances et 1766 conseils de l'athlète `avance_street`. « À froid » : premier appel, tout le journal rejoué (117 séances).

| Opération | Médiane | 95ᵉ centile | Maximum | Cible |
| --- | --- | --- | --- | --- |
| Décision de séance (`prescribeSession`) | 0.06 ms | 0.09 ms | 10.86 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.06 ms | 0.12 ms | 5.67 ms | ≤ 5 ms |
| Revue (`review`) | 0.98 ms | 1.17 ms | 2.24 ms | — |
| Décision de séance à froid | 12.34 ms | 18.65 ms | 20.07 ms | — |
