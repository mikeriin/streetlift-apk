# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.1.0) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 6 graines × 3 politiques à programme égal, puis 4 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors séries ouvertes et semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché, sur les séries dont la cible est atteignable — il existe une charge de la grille de l'athlète (ou, sans charge, un nombre de répétitions) qui met le RIR visé dans la plage du bloc, étendue comme le moteur sait l'étendre ; « Atteignable » en donne la part, « toutes séries » l'écart sans ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. Gain : progression moyenne de la capacité vraie par semaine, entre la première et la dernière séance de chaque exercice suivi au moins trois semaines.

| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE (toutes séries) | Échecs non prévus | Quasi-échecs | Gain par semaine |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 2.45 ± 0.86 | 2.11 | 93 % | 2.67 | 2.94 ± 0.77 % | 3.35 ± 0.75 % | 0.17 ± 0.04 % |
| debutant_salle | double_progression | 1.92 ± 0.39 | 1.57 | 92 % | 2.09 | 8.28 ± 2.40 % | 6.48 ± 0.86 % | 0.19 ± 0.02 % |
| debutant_salle | L7/L11 | 4.28 ± 0.77 | 3.74 | 93 % | 4.18 | 8.62 ± 2.64 % | 7.74 ± 1.29 % | 0.19 ± 0.02 % |
| intermediaire_salle | kalis_adapt | 1.80 ± 0.72 | 1.29 | 91 % | 2.46 | 2.35 ± 0.44 % | 2.79 ± 0.53 % | -0.01 ± 0.01 % |
| intermediaire_salle | double_progression | 3.10 ± 0.52 | 2.91 | 89 % | 3.97 | 3.56 ± 0.65 % | 3.61 ± 0.51 % | -0.01 ± 0.01 % |
| intermediaire_salle | L7/L11 | 4.11 ± 0.47 | 3.58 | 89 % | 4.93 | 3.82 ± 0.57 % | 4.96 ± 1.06 % | -0.01 ± 0.01 % |
| avance_street | kalis_adapt | 1.07 ± 0.14 | 0.38 | 84 % | 1.80 | 0.36 ± 0.15 % | 1.40 ± 0.46 % | -0.01 ± 0.00 % |
| avance_street | double_progression | 2.09 ± 0.13 | 1.80 | 83 % | 3.72 | 4.06 ± 1.17 % | 2.60 ± 0.66 % | -0.01 ± 0.00 % |
| avance_street | L7/L11 | 2.67 ± 0.15 | 1.98 | 82 % | 4.28 | 4.77 ± 1.41 % | 4.38 ± 1.23 % | -0.01 ± 0.00 % |
| notes_paresseuses | kalis_adapt | 2.38 ± 0.58 | 1.94 | 95 % | 2.75 | 0.79 ± 0.29 % | 0.82 ± 0.56 % | 0.01 ± 0.02 % |
| notes_paresseuses | double_progression | 3.22 ± 0.54 | 3.04 | 95 % | 3.90 | 0.33 ± 0.56 % | 0.26 ± 0.29 % | 0.01 ± 0.02 % |
| notes_paresseuses | L7/L11 | 4.71 ± 0.82 | 4.49 | 95 % | 5.39 | 0.44 ± 0.51 % | 0.84 ± 0.39 % | -0.01 ± 0.02 % |
| irregulier | kalis_adapt | 1.55 ± 0.28 | 1.10 | 97 % | 1.74 | 0.24 ± 0.29 % | 0.46 ± 0.35 % | -0.03 ± 0.05 % |
| irregulier | double_progression | 2.62 ± 0.46 | 2.48 | 96 % | 3.11 | 0.20 ± 0.40 % | 0.14 ± 0.26 % | -0.04 ± 0.05 % |
| irregulier | L7/L11 | 3.72 ± 0.39 | 3.29 | 96 % | 4.21 | 0.43 ± 0.45 % | 1.29 ± 0.75 % | -0.04 ± 0.05 % |
| maison_halteres | kalis_adapt | 5.35 ± 1.71 | 5.12 | 89 % | 5.35 | 0.10 ± 0.07 % | 0.24 ± 0.21 % | 0.06 ± 0.05 % |
| maison_halteres | double_progression | 3.59 ± 0.77 | 3.33 | 90 % | 3.87 | 3.63 ± 2.69 % | 2.15 ± 1.62 % | 0.14 ± 0.03 % |
| maison_halteres | L7/L11 | 5.99 ± 0.76 | 5.55 | 90 % | 5.94 | 4.11 ± 2.96 % | 2.88 ± 1.65 % | 0.13 ± 0.03 % |
| calisthenie_parc | kalis_adapt | 1.66 ± 0.59 | 1.60 | 50 % | 3.58 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -0.08 ± 0.03 % |
| calisthenie_parc | double_progression | 3.79 ± 0.93 | 3.76 | 48 % | 8.08 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -0.08 ± 0.01 % |
| calisthenie_parc | L7/L11 | 3.79 ± 0.93 | 3.76 | 48 % | 8.08 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -0.08 ± 0.01 % |
| douleur_et_lieu | kalis_adapt | 1.66 ± 0.39 | 1.21 | 86 % | 2.30 | 3.36 ± 0.41 % | 3.92 ± 0.55 % | -0.02 ± 0.01 % |
| douleur_et_lieu | double_progression | 2.22 ± 0.50 | 1.96 | 84 % | 3.10 | 5.61 ± 1.49 % | 4.94 ± 0.95 % | 0.01 ± 0.01 % |
| douleur_et_lieu | L7/L11 | 3.36 ± 0.44 | 2.79 | 84 % | 3.95 | 6.01 ± 1.69 % | 6.16 ± 1.54 % | 0.01 ± 0.01 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | 0.53 ± 0.76 | -1.83 ± 0.87 | -0.03 ± 0.03 % | -0.02 ± 0.03 % |
| intermediaire_salle | -1.31 ± 0.24 | -2.31 ± 0.56 | -0.00 ± 0.01 % | -0.00 ± 0.01 % |
| avance_street | -1.02 ± 0.19 | -1.60 ± 0.16 | 0.00 ± 0.00 % | 0.00 ± 0.00 % |
| notes_paresseuses | -0.84 ± 0.18 | -2.33 ± 0.41 | 0.00 ± 0.01 % | 0.02 ± 0.01 % |
| irregulier | -1.07 ± 0.26 | -2.17 ± 0.33 | 0.01 ± 0.01 % | 0.01 ± 0.01 % |
| maison_halteres | 1.76 ± 1.62 | -0.64 ± 1.25 | -0.08 ± 0.03 % | -0.07 ± 0.03 % |
| calisthenie_parc | -2.13 ± 1.00 | -2.13 ± 1.00 | 0.01 ± 0.02 % | 0.01 ± 0.02 % |
| douleur_et_lieu | -0.56 ± 0.20 | -1.70 ± 0.45 | -0.03 ± 0.01 % | -0.02 ± 0.01 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 2.70 ± 1.08 | 1.69 ± 0.59 |
| intermediaire_salle | 1.78 ± 0.85 | 1.90 ± 0.49 |
| avance_street | 1.08 ± 0.09 | 1.05 ± 0.24 |
| notes_paresseuses | 1.95 ± 0.71 | 3.87 ± 1.08 |
| irregulier | 1.34 ± 0.22 | 2.30 ± 0.57 |
| maison_halteres | 7.55 ± 2.86 | 2.35 ± 0.75 |
| calisthenie_parc | — | 1.66 ± 0.59 |
| douleur_et_lieu | 1.75 ± 0.31 | 1.41 ± 0.62 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 11.9 % | 8.9 % | 8.7 % | 7.4 % | 13.2 % | 10.1 % | 9.5 % | 8.2 % | 79 % |
| debutant_salle | L7/L11 | 12.5 % | 12.2 % | 12.5 % | 12.9 % | 11.7 % | 10.7 % | 10.6 % | 10.3 % | 29 % |
| intermediaire_salle | kalis_adapt | 14.8 % | 10.8 % | 10.1 % | 9.6 % | 15.8 % | 12.7 % | 11.8 % | 11.0 % | 83 % |
| intermediaire_salle | L7/L11 | 6.1 % | 4.3 % | 5.8 % | 6.9 % | 7.3 % | 8.3 % | 6.9 % | 6.4 % | 49 % |
| avance_street | kalis_adapt | 10.7 % | 6.8 % | 5.5 % | 5.0 % | 11.7 % | 8.3 % | 7.1 % | 6.5 % | 84 % |
| avance_street | L7/L11 | 6.5 % | 5.9 % | 5.5 % | 8.0 % | 6.5 % | 5.4 % | 4.7 % | 4.7 % | 58 % |
| notes_paresseuses | kalis_adapt | 11.9 % | 8.8 % | 7.3 % | 4.6 % | 12.9 % | 10.2 % | 9.1 % | 6.4 % | 83 % |
| notes_paresseuses | L7/L11 | 8.2 % | 7.1 % | 7.1 % | 7.1 % | 9.1 % | 9.0 % | 7.4 % | 6.4 % | 43 % |
| irregulier | kalis_adapt | 11.6 % | 6.0 % | 5.6 % | 2.7 % | 12.9 % | 7.5 % | 7.6 % | 5.2 % | 87 % |
| irregulier | L7/L11 | 6.3 % | 5.9 % | 5.4 % | 8.7 % | 9.4 % | 9.2 % | 9.0 % | 5.0 % | 48 % |
| maison_halteres | kalis_adapt | 16.0 % | 14.1 % | 13.1 % | 10.9 % | 16.7 % | 15.1 % | 14.4 % | 12.5 % | 67 % |
| maison_halteres | L7/L11 | 14.1 % | 11.9 % | 12.0 % | 10.0 % | 11.7 % | 10.9 % | 10.4 % | 9.5 % | 38 % |
| calisthenie_parc | kalis_adapt | 26.5 % | 23.6 % | 22.7 % | 17.1 % | 26.5 % | 23.6 % | 22.7 % | 17.1 % | 45 % |
| douleur_et_lieu | kalis_adapt | 11.7 % | 7.9 % | 7.7 % | 6.6 % | 12.7 % | 9.2 % | 8.6 % | 7.8 % | 81 % |
| douleur_et_lieu | L7/L11 | 8.8 % | 6.8 % | 7.2 % | 6.5 % | 7.0 % | 7.8 % | 8.3 % | 7.8 % | 39 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'une séance à l'autre sur un mouvement principal, après calibrage (un seul cran de grille peut dépasser 10 % quand le plus petit cran du matériel est plus grand). Aggravations : hausses de charge sur une zone signalée douloureuse.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 % | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 23.2 | 50.6 % | 25.0 % | 18 | 14.2 % | 0.00 |
| debutant_salle | double_progression | 65.8 | 72.0 % | 25.0 % | 29 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 56.5 | 71.8 % | 18.2 % | 12 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 28.7 | 55.7 % | 11.1 % | 2 | 19.0 % | 0.00 |
| intermediaire_salle | double_progression | 85.8 | 72.9 % | 12.5 % | 5 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 86.5 | 72.3 % | 14.3 % | 16 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 51.3 | 56.2 % | 7.2 % | 0 | 30.3 % | 0.00 |
| avance_street | double_progression | 84.0 | 41.9 % | 3.0 % | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 124.8 | 54.7 % | 9.3 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 21.0 | 35.5 % | 8.0 % | 0 | 13.9 % | 0.00 |
| notes_paresseuses | double_progression | 54.0 | 58.4 % | 4.8 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 50.8 | 54.6 % | 7.7 % | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 14.8 | 30.0 % | 6.3 % | 0 | 15.4 % | 0.00 |
| irregulier | double_progression | 34.8 | 31.3 % | 7.7 % | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 50.2 | 50.6 % | 30.8 % | 12 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 21.8 | 69.9 % | 50.0 % | 30 | 15.3 % | 0.00 |
| maison_halteres | double_progression | 90.0 | 83.7 % | 33.3 % | 92 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 50.3 | 76.7 % | 50.0 % | 16 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 4.3 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 25.5 | 49.7 % | 20.0 % | 9 | 27.2 % | 0.00 |
| douleur_et_lieu | double_progression | 65.2 | 65.2 % | 20.0 % | 28 | 0.0 % | 12.00 |
| douleur_et_lieu | L7/L11 | 78.7 | 65.9 % | 20.0 % | 22 | 0.0 % | 13.67 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 1.66 ± 0.62 | 0.16 ± 0.07 % | 1.3 | 0.0 | 2.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 1.92 ± 1.28 | -0.01 ± 0.02 % | 2.5 | 0.0 | 2.8 | 0.0 | 0.0 | 0.3 | 0.0 % |
| avance_street | 1.09 ± 0.20 | -0.01 ± 0.00 % | 5.0 | 2.8 | 3.3 | 0.0 | 0.0 | 0.0 | 3.6 % |
| notes_paresseuses | 2.27 ± 0.63 | 0.01 ± 0.01 % | 0.5 | 0.0 | 2.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.59 ± 0.42 | 0.00 ± 0.03 % | 1.5 | 0.0 | 1.5 | 0.0 | 0.0 | 0.0 | 0.0 % |
| maison_halteres | 4.52 ± 1.62 | 0.10 ± 0.07 % | 1.5 | 0.0 | 2.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 2.14 ± 0.49 | -0.01 ± 0.03 % | 0.3 | 0.0 | 0.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 1.92 ± 0.56 | 0.01 ± 0.01 % | 3.3 | 0.0 | 2.0 | 1.0 | 0.0 | 0.0 | 0.0 % |

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
| Décision de séance (`prescribeSession`) | 0.06 ms | 0.16 ms | 9.61 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.07 ms | 0.13 ms | 3.55 ms | ≤ 5 ms |
| Revue (`review`) | 0.85 ms | 1.07 ms | 1.20 ms | — |
| Décision de séance à froid | 11.92 ms | 16.03 ms | 16.54 ms | — |
