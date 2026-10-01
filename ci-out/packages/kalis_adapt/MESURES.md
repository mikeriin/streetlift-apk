# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.1.0) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 6 graines × 3 politiques à programme égal, puis 4 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 1.34 ± 0.27 | 0.86 | 95 % | 1.49 | 1.50 ± 0.78 % | 1.10 ± 0.79 % | 0.31 ± 0.03 % |
| debutant_salle | double_progression | 2.08 ± 0.44 | 1.74 | 92 % | 2.19 | 8.24 ± 2.47 % | 6.52 ± 0.86 % | 0.29 ± 0.03 % |
| debutant_salle | L7/L11 | 4.51 ± 0.80 | 3.99 | 93 % | 4.40 | 8.46 ± 2.36 % | 8.00 ± 1.84 % | 0.29 ± 0.02 % |
| intermediaire_salle | kalis_adapt | 1.40 ± 0.24 | 0.85 | 91 % | 1.87 | 1.49 ± 0.86 % | 0.88 ± 0.58 % | 0.06 ± 0.01 % |
| intermediaire_salle | double_progression | 3.15 ± 0.47 | 2.96 | 88 % | 4.07 | 3.58 ± 0.64 % | 3.53 ± 0.51 % | 0.04 ± 0.01 % |
| intermediaire_salle | L7/L11 | 4.17 ± 0.47 | 3.65 | 88 % | 5.04 | 3.79 ± 0.63 % | 5.14 ± 1.09 % | 0.04 ± 0.00 % |
| avance_street | kalis_adapt | 1.03 ± 0.09 | 0.33 | 84 % | 1.70 | 1.27 ± 0.37 % | 1.26 ± 0.34 % | -0.00 ± 0.00 % |
| avance_street | double_progression | 2.10 ± 0.13 | 1.80 | 83 % | 3.73 | 4.06 ± 1.17 % | 2.57 ± 0.66 % | -0.00 ± 0.00 % |
| avance_street | L7/L11 | 2.66 ± 0.14 | 1.97 | 82 % | 4.28 | 4.76 ± 1.45 % | 4.29 ± 1.23 % | -0.01 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 1.43 ± 0.16 | 0.89 | 93 % | 1.63 | 1.66 ± 0.61 % | 0.92 ± 0.82 % | 0.07 ± 0.01 % |
| notes_paresseuses | double_progression | 3.12 ± 0.45 | 2.95 | 94 % | 3.96 | 0.31 ± 0.56 % | 0.28 ± 0.34 % | 0.07 ± 0.01 % |
| notes_paresseuses | L7/L11 | 4.86 ± 0.81 | 4.65 | 94 % | 5.65 | 0.42 ± 0.51 % | 0.77 ± 0.40 % | 0.06 ± 0.01 % |
| irregulier | kalis_adapt | 1.34 ± 0.21 | 0.85 | 96 % | 1.44 | 1.21 ± 0.69 % | 0.59 ± 0.45 % | 0.02 ± 0.05 % |
| irregulier | double_progression | 2.64 ± 0.48 | 2.49 | 96 % | 3.18 | 0.20 ± 0.40 % | 0.23 ± 0.29 % | 0.01 ± 0.05 % |
| irregulier | L7/L11 | 3.77 ± 0.44 | 3.38 | 96 % | 4.31 | 0.48 ± 0.43 % | 1.09 ± 0.67 % | 0.01 ± 0.05 % |
| maison_halteres | kalis_adapt | 2.39 ± 1.16 | 1.96 | 90 % | 2.43 | 1.31 ± 0.97 % | 0.94 ± 0.69 % | 0.29 ± 0.01 % |
| maison_halteres | double_progression | 3.76 ± 0.67 | 3.51 | 88 % | 4.02 | 3.61 ± 2.65 % | 2.22 ± 1.83 % | 0.29 ± 0.02 % |
| maison_halteres | L7/L11 | 6.45 ± 0.72 | 6.00 | 88 % | 6.30 | 4.00 ± 2.88 % | 2.94 ± 1.71 % | 0.28 ± 0.01 % |
| calisthenie_parc | kalis_adapt | 1.39 ± 0.52 | 1.26 | 48 % | 3.31 | 0.07 ± 0.14 % | 0.03 ± 0.07 % | 0.07 ± 0.02 % |
| calisthenie_parc | double_progression | 3.76 ± 0.95 | 3.72 | 46 % | 8.39 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.01 % |
| calisthenie_parc | L7/L11 | 3.76 ± 0.95 | 3.72 | 46 % | 8.39 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | 0.04 ± 0.01 % |
| douleur_et_lieu | kalis_adapt | 1.34 ± 0.28 | 0.84 | 89 % | 1.71 | 1.05 ± 0.29 % | 0.81 ± 0.31 % | 0.05 ± 0.01 % |
| douleur_et_lieu | double_progression | 2.21 ± 0.52 | 1.96 | 83 % | 3.15 | 5.61 ± 1.49 % | 4.98 ± 0.97 % | 0.05 ± 0.01 % |
| douleur_et_lieu | L7/L11 | 3.36 ± 0.49 | 2.78 | 83 % | 3.99 | 5.96 ± 1.62 % | 6.06 ± 1.43 % | 0.05 ± 0.01 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | -0.74 ± 0.21 | -3.17 ± 0.81 | 0.03 ± 0.02 % | 0.03 ± 0.02 % |
| intermediaire_salle | -1.75 ± 0.32 | -2.77 ± 0.32 | 0.01 ± 0.01 % | 0.01 ± 0.01 % |
| avance_street | -1.07 ± 0.15 | -1.63 ± 0.12 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -1.70 ± 0.34 | -3.44 ± 0.72 | 0.01 ± 0.01 % | 0.02 ± 0.01 % |
| irregulier | -1.30 ± 0.31 | -2.43 ± 0.38 | 0.01 ± 0.01 % | 0.01 ± 0.00 % |
| maison_halteres | -1.37 ± 1.12 | -4.05 ± 0.95 | -0.00 ± 0.02 % | 0.01 ± 0.01 % |
| calisthenie_parc | -2.37 ± 0.87 | -2.37 ± 0.87 | 0.03 ± 0.01 % | 0.03 ± 0.01 % |
| douleur_et_lieu | -0.87 ± 0.33 | -2.03 ± 0.43 | -0.00 ± 0.01 % | 0.00 ± 0.01 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 1.36 ± 0.25 | 1.26 ± 0.36 |
| intermediaire_salle | 1.42 ± 0.27 | 1.33 ± 0.24 |
| avance_street | 1.09 ± 0.06 | 0.93 ± 0.15 |
| notes_paresseuses | 1.27 ± 0.15 | 2.04 ± 0.45 |
| irregulier | 1.21 ± 0.22 | 1.83 ± 0.31 |
| maison_halteres | 2.76 ± 1.71 | 1.90 ± 0.54 |
| calisthenie_parc | — | 1.39 ± 0.52 |
| douleur_et_lieu | 1.43 ± 0.32 | 1.10 ± 0.33 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 12.7 % | 6.2 % | 6.1 % | 4.9 % | 14.1 % | 7.6 % | 7.6 % | 6.4 % | 87 % |
| debutant_salle | L7/L11 | 12.5 % | 12.5 % | 12.9 % | 13.8 % | 11.7 % | 10.8 % | 10.7 % | 10.3 % | 27 % |
| intermediaire_salle | kalis_adapt | 12.0 % | 6.5 % | 5.6 % | 4.6 % | 13.3 % | 8.3 % | 7.9 % | 6.9 % | 88 % |
| intermediaire_salle | L7/L11 | 6.1 % | 4.5 % | 6.1 % | 6.8 % | 7.3 % | 8.2 % | 6.9 % | 6.3 % | 49 % |
| avance_street | kalis_adapt | 10.5 % | 7.0 % | 5.6 % | 4.9 % | 11.6 % | 8.4 % | 7.0 % | 6.2 % | 84 % |
| avance_street | L7/L11 | 6.5 % | 5.9 % | 5.5 % | 8.0 % | 6.5 % | 5.4 % | 4.7 % | 4.7 % | 57 % |
| notes_paresseuses | kalis_adapt | 11.7 % | 7.4 % | 5.5 % | 2.4 % | 12.8 % | 8.7 % | 7.0 % | 4.0 % | 89 % |
| notes_paresseuses | L7/L11 | 8.2 % | 7.0 % | 7.5 % | 7.5 % | 9.1 % | 8.7 % | 7.0 % | 6.0 % | 46 % |
| irregulier | kalis_adapt | 11.5 % | 6.0 % | 4.9 % | 2.0 % | 12.8 % | 7.4 % | 6.7 % | 4.3 % | 90 % |
| irregulier | L7/L11 | 6.3 % | 5.9 % | 5.5 % | 7.7 % | 9.4 % | 9.1 % | 8.9 % | 6.5 % | 45 % |
| maison_halteres | kalis_adapt | 16.2 % | 11.1 % | 11.0 % | 9.3 % | 16.8 % | 12.5 % | 12.6 % | 11.0 % | 71 % |
| maison_halteres | L7/L11 | 14.1 % | 12.1 % | 12.2 % | 10.6 % | 11.7 % | 10.8 % | 10.2 % | 9.4 % | 42 % |
| calisthenie_parc | kalis_adapt | 26.5 % | 22.8 % | 21.5 % | 15.9 % | 26.5 % | 22.8 % | 21.5 % | 15.9 % | 51 % |
| douleur_et_lieu | kalis_adapt | 11.7 % | 5.2 % | 4.4 % | 4.7 % | 12.9 % | 7.1 % | 6.1 % | 6.1 % | 88 % |
| douleur_et_lieu | L7/L11 | 8.8 % | 6.7 % | 7.0 % | 7.2 % | 7.0 % | 7.8 % | 8.6 % | 7.3 % | 41 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'une séance à l'autre sur un mouvement principal, après calibrage (un seul cran de grille peut dépasser 10 % quand le plus petit cran du matériel est plus grand). Aggravations : hausses de charge sur une zone signalée douloureuse.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 % | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 39.8 | 61.0 % | 50.0 % | 15 | 35.5 % | 0.00 |
| debutant_salle | double_progression | 69.0 | 71.2 % | 25.0 % | 31 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 56.8 | 70.2 % | 18.2 % | 12 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 44.2 | 61.6 % | 11.1 % | 4 | 29.3 % | 0.00 |
| intermediaire_salle | double_progression | 87.0 | 71.2 % | 12.5 % | 4 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 84.7 | 71.5 % | 14.3 % | 18 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 60.2 | 57.5 % | 6.3 % | 0 | 31.0 % | 0.00 |
| avance_street | double_progression | 84.2 | 41.9 % | 3.0 % | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 124.5 | 54.4 % | 9.3 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 30.5 | 43.5 % | 12.5 % | 1 | 14.2 % | 0.00 |
| notes_paresseuses | double_progression | 52.0 | 57.2 % | 4.8 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 53.8 | 53.3 % | 7.4 % | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 26.3 | 38.3 % | 6.3 % | 0 | 15.4 % | 0.00 |
| irregulier | double_progression | 36.0 | 33.4 % | 7.7 % | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 50.2 | 48.9 % | 30.8 % | 13 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 31.2 | 64.2 % | 50.0 % | 35 | 15.7 % | 0.00 |
| maison_halteres | double_progression | 90.8 | 84.1 % | 33.3 % | 104 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 52.2 | 76.2 % | 50.0 % | 16 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 4.3 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 43.0 | 60.5 % | 20.0 % | 14 | 39.0 % | 0.00 |
| douleur_et_lieu | double_progression | 64.7 | 64.5 % | 20.0 % | 26 | 0.0 % | 11.50 |
| douleur_et_lieu | L7/L11 | 77.3 | 66.0 % | 20.0 % | 21 | 0.0 % | 13.50 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.42 ± 0.35 | 0.30 ± 0.02 % | 0.3 | 0.0 | 3.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.25 ± 0.14 | 0.07 ± 0.00 % | 1.3 | 0.0 | 4.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| avance_street | 1.04 ± 0.18 | -0.01 ± 0.00 % | 6.5 | 2.8 | 5.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| notes_paresseuses | 1.35 ± 0.27 | 0.08 ± 0.01 % | 0.5 | 0.0 | 3.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.31 ± 0.29 | 0.07 ± 0.04 % | 1.8 | 0.0 | 3.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| maison_halteres | 2.25 ± 1.12 | 0.34 ± 0.03 % | 0.0 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 1.64 ± 0.35 | 0.14 ± 0.01 % | 0.3 | 0.0 | 1.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 1.45 ± 0.41 | 0.05 ± 0.02 % | 5.3 | 0.0 | 7.0 | 1.0 | 0.0 | 0.0 | 0.0 % |

| Athlète | Volume | Échange d'exercice | Restructuration de séance | Restructuration de bloc |
| --- | --- | --- | --- | --- |
| debutant_salle | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 6.0 (4/4) | semaine 11.0 (4/4) |
| intermediaire_salle | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 6.0 (4/4) | semaine 11.0 (4/4) |
| avance_street | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 7.0 (4/4) | semaine 13.0 (4/4) |
| notes_paresseuses | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 6.0 (4/4) | semaine 11.0 (4/4) |
| irregulier | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 6.0 (4/4) | semaine 11.0 (4/4) |
| maison_halteres | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 5.0 (4/4) | semaine 10.0 (4/4) |
| calisthenie_parc | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 5.0 (4/4) | semaine 10.0 (4/4) |
| douleur_et_lieu | semaine 2.0 (4/4) | semaine 4.0 (4/4) | semaine 6.0 (4/4) | semaine 11.8 (4/4) |

## 5. Temps de calcul

Mesurés par le simulateur sur la machine de contrôle (le moteur n'a pas d'horloge), sur 117 séances et 1766 conseils de l'athlète `avance_street`. « À froid » : premier appel, tout le journal rejoué (117 séances).

| Opération | Médiane | 95ᵉ centile | Maximum | Cible |
| --- | --- | --- | --- | --- |
| Décision de séance (`prescribeSession`) | 0.06 ms | 0.15 ms | 9.48 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.07 ms | 0.13 ms | 3.63 ms | ≤ 5 ms |
| Revue (`review`) | 1.30 ms | 4.12 ms | 4.27 ms | — |
| Décision de séance à froid | 12.30 ms | 17.39 ms | 17.97 ms | — |
