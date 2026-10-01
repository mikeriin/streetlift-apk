# kalis_adapt — mesures de la campagne de simulation

Document généré par `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (moteur 0.1.0) à partir de `docs/data/campagne.json` : 8 athlètes simulés × 24 semaines × 6 graines × 3 politiques à programme égal, puis 4 graines par athlète en boucle complète. Lecture et limites : `VALIDATION.md`.

Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur de l'intervalle de confiance à 95 % (1,96 × erreur standard entre graines).

## 1. Écart au RIR visé, échecs, progression

Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors séries ouvertes et semaines de test. RIR MAE : écart absolu moyen entre le RIR réel et le RIR affiché. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 répétition de l'échec quand la cible en laissait au moins 2. Gain : progression moyenne de la capacité vraie sur la simulation.

| Athlète | Politique | RIR MAE | Biais | Échecs non prévus | Quasi-échecs | Gain |
| --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 2.40 ± 0.61 | 1.76 | 2.87 ± 0.75 % | 3.69 ± 0.80 % | 2.8 ± 0.7 % |
| debutant_salle | double_progression | — | 0.00 | 8.32 ± 2.40 % | 0.00 ± 0.00 % | 3.0 ± 0.4 % |
| debutant_salle | L7/L11 | 6.24 ± 1.27 | 5.44 | 8.68 ± 2.57 % | 5.66 ± 1.21 % | 2.8 ± 0.4 % |
| intermediaire_salle | kalis_adapt | 3.71 ± 0.70 | 3.04 | 2.35 ± 0.38 % | 3.12 ± 0.85 % | -1.9 ± 0.2 % |
| intermediaire_salle | double_progression | — | 0.00 | 3.81 ± 0.63 % | 0.00 ± 0.00 % | -1.9 ± 0.1 % |
| intermediaire_salle | L7/L11 | 5.79 ± 0.66 | 4.94 | 4.12 ± 0.50 % | 5.30 ± 1.06 % | -1.9 ± 0.1 % |
| avance_street | kalis_adapt | 2.64 ± 0.26 | 2.01 | 0.49 ± 0.31 % | 1.45 ± 0.49 % | -3.2 ± 0.0 % |
| avance_street | double_progression | — | 0.00 | 4.26 ± 1.16 % | 0.00 ± 0.00 % | -3.2 ± 0.0 % |
| avance_street | L7/L11 | 3.14 ± 0.32 | 2.23 | 4.86 ± 1.34 % | 2.48 ± 0.99 % | -3.2 ± 0.0 % |
| notes_paresseuses | kalis_adapt | 3.59 ± 0.21 | 3.14 | 0.74 ± 0.34 % | 0.98 ± 0.49 % | -1.2 ± 0.2 % |
| notes_paresseuses | double_progression | — | 0.00 | 0.31 ± 0.56 % | 0.00 ± 0.00 % | -1.2 ± 0.2 % |
| notes_paresseuses | L7/L11 | 5.03 ± 0.94 | 4.74 | 0.46 ± 0.54 % | 0.96 ± 0.37 % | -1.7 ± 0.2 % |
| irregulier | kalis_adapt | 2.18 ± 0.45 | 1.67 | 0.39 ± 0.47 % | 1.14 ± 0.66 % | -2.3 ± 0.9 % |
| irregulier | double_progression | — | 0.00 | 0.20 ± 0.40 % | 0.00 ± 0.00 % | -2.4 ± 1.0 % |
| irregulier | L7/L11 | 4.48 ± 1.44 | 3.91 | 0.64 ± 0.43 % | 1.22 ± 0.61 % | -2.5 ± 0.9 % |
| maison_halteres | kalis_adapt | 5.19 ± 0.94 | 4.92 | 0.10 ± 0.09 % | 0.36 ± 0.32 % | -1.1 ± 0.9 % |
| maison_halteres | double_progression | — | 0.00 | 4.03 ± 2.66 % | 0.00 ± 0.00 % | 0.2 ± 0.5 % |
| maison_halteres | L7/L11 | 11.67 ± 2.96 | 10.94 | 4.47 ± 3.08 % | 1.50 ± 0.66 % | -0.0 ± 0.5 % |
| calisthenie_parc | kalis_adapt | 5.65 ± 1.07 | 5.62 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -2.3 ± 0.4 % |
| calisthenie_parc | double_progression | — | 0.00 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -2.3 ± 0.2 % |
| calisthenie_parc | L7/L11 | — | 0.00 | 0.00 ± 0.00 % | 0.00 ± 0.00 % | -2.3 ± 0.2 % |
| douleur_et_lieu | kalis_adapt | 3.07 ± 0.63 | 2.37 | 3.46 ± 0.53 % | 3.90 ± 0.61 % | -2.9 ± 0.1 % |
| douleur_et_lieu | double_progression | — | 0.00 | 5.82 ± 1.57 % | 0.00 ± 0.00 % | -1.7 ± 0.1 % |
| douleur_et_lieu | L7/L11 | 5.08 ± 1.44 | 4.09 | 6.03 ± 1.61 % | 5.46 ± 0.62 % | -1.8 ± 0.1 % |

### Différences appariées (mêmes graines, mêmes aléas)

Moyenne de la différence `kalis_adapt − référence`, simulation par simulation. RIR MAE : négatif = `kalis_adapt` plus près de la cible. Gain : positif = `kalis_adapt` progresse plus.

| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | Gain vs double progression | Gain vs L7/L11 |
| --- | --- | --- | --- | --- |
| debutant_salle | — | -3.84 ± 0.92 | -0.1 ± 0.5 % | 0.1 ± 0.5 % |
| intermediaire_salle | — | -2.08 ± 0.93 | 0.1 ± 0.1 % | 0.1 ± 0.1 % |
| avance_street | — | -0.50 ± 0.28 | 0.0 ± 0.0 % | 0.0 ± 0.0 % |
| notes_paresseuses | — | -1.44 ± 0.96 | -0.0 ± 0.1 % | 0.5 ± 0.1 % |
| irregulier | — | -2.30 ± 1.62 | 0.1 ± 0.1 % | 0.2 ± 0.2 % |
| maison_halteres | — | -6.48 ± 2.41 | -1.3 ± 0.5 % | -1.1 ± 0.5 % |
| calisthenie_parc | — | — | -0.1 ± 0.2 % | -0.1 ± 0.2 % |
| douleur_et_lieu | — | -2.02 ± 1.09 | -1.2 ± 0.1 % | -1.1 ± 0.1 % |

### Par nature d'exercice (`kalis_adapt`)

| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et tenues |
| --- | --- | --- |
| debutant_salle | 2.69 ± 0.70 | 1.60 ± 0.57 |
| intermediaire_salle | 3.44 ± 0.62 | 4.63 ± 1.48 |
| avance_street | 1.41 ± 0.24 | 4.05 ± 0.51 |
| notes_paresseuses | 2.54 ± 0.40 | 6.50 ± 0.89 |
| irregulier | 1.44 ± 0.23 | 4.67 ± 1.55 |
| maison_halteres | 7.63 ± 1.41 | 2.22 ± 0.69 |
| calisthenie_parc | — | 5.65 ± 1.07 |
| douleur_et_lieu | 3.27 ± 0.82 | 2.66 ± 0.33 |

## 2. Erreur de capacité

Erreur relative absolue après 1, 3, 6 et 12 séances de l'exercice. Capacité opérationnelle : charge du milieu de plage au RIR visé (ce qui sert à prescrire) ; 1RM : capacité extrapolée à une répétition. Couverture : part des estimations dont l'intervalle annoncé à 95 % contient la vérité (cible : 95 %). La double progression n'estime rien.

| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | 1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 11.1 % | 7.7 % | 7.8 % | 6.6 % | 12.5 % | 8.8 % | 8.7 % | 7.8 % | 81 % |
| debutant_salle | L7/L11 | 11.0 % | 10.2 % | 10.7 % | 11.3 % | 10.7 % | 9.5 % | 9.2 % | 8.1 % | 34 % |
| intermediaire_salle | kalis_adapt | 17.2 % | 11.6 % | 10.9 % | 10.6 % | 18.9 % | 13.5 % | 12.9 % | 12.0 % | 82 % |
| intermediaire_salle | L7/L11 | 5.1 % | 4.1 % | 5.2 % | 6.4 % | 8.3 % | 9.0 % | 7.5 % | 6.5 % | 50 % |
| avance_street | kalis_adapt | 14.8 % | 8.6 % | 7.0 % | 5.6 % | 16.0 % | 9.9 % | 8.5 % | 7.2 % | 82 % |
| avance_street | L7/L11 | 5.7 % | 5.6 % | 5.6 % | 8.3 % | 6.3 % | 6.1 % | 5.3 % | 4.9 % | 58 % |
| notes_paresseuses | kalis_adapt | 13.0 % | 8.7 % | 7.6 % | 5.4 % | 13.5 % | 10.2 % | 9.3 % | 6.7 % | 80 % |
| notes_paresseuses | L7/L11 | 8.7 % | 6.6 % | 7.8 % | 8.1 % | 10.1 % | 10.1 % | 8.0 % | 6.5 % | 39 % |
| irregulier | kalis_adapt | 12.8 % | 6.7 % | 6.4 % | 3.0 % | 14.5 % | 8.4 % | 8.5 % | 5.4 % | 85 % |
| irregulier | L7/L11 | 7.0 % | 5.9 % | 6.0 % | 7.9 % | 11.3 % | 9.6 % | 11.0 % | 6.8 % | 34 % |
| maison_halteres | kalis_adapt | 16.2 % | 13.3 % | 12.3 % | 10.2 % | 17.0 % | 14.1 % | 13.3 % | 11.5 % | 70 % |
| maison_halteres | L7/L11 | 14.7 % | 11.9 % | 11.8 % | 10.8 % | 10.9 % | 10.1 % | 10.5 % | 10.8 % | 39 % |
| calisthenie_parc | kalis_adapt | 27.2 % | 24.5 % | 23.7 % | 19.0 % | 27.2 % | 24.5 % | 23.7 % | 19.0 % | 49 % |
| douleur_et_lieu | kalis_adapt | 14.7 % | 7.7 % | 7.8 % | 6.9 % | 16.1 % | 9.4 % | 9.5 % | 8.3 % | 81 % |
| douleur_et_lieu | L7/L11 | 8.5 % | 6.4 % | 6.7 % | 6.9 % | 8.3 % | 9.3 % | 10.0 % | 8.3 % | 32 % |

## 3. Stabilité et sécurité

Changements : changements de charge de première série par simulation, après calibrage. Inversions : part de ces changements qui défont le précédent. Hausse max : plus forte hausse de charge totale d'une séance à l'autre sur un mouvement principal, après calibrage (un seul cran de grille peut dépasser 10 % quand le plus petit cran du matériel est plus grand). Aggravations : hausses de charge sur une zone signalée douloureuse.

| Athlète | Politique | Changements | Inversions | Hausse max (principal) | Hausses > 10 % | Séances ajustées | Aggravations |
| --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | kalis_adapt | 30.3 | 60.0 % | 25.0 % | 20 | 14.9 % | 0.00 |
| debutant_salle | double_progression | 73.2 | 74.1 % | 25.0 % | 34 | 0.0 % | 0.00 |
| debutant_salle | L7/L11 | 58.2 | 75.0 % | 18.2 % | 16 | 0.0 % | 0.00 |
| intermediaire_salle | kalis_adapt | 37.0 | 62.3 % | 11.1 % | 1 | 18.8 % | 0.00 |
| intermediaire_salle | double_progression | 105.8 | 74.2 % | 12.5 % | 12 | 0.0 % | 0.00 |
| intermediaire_salle | L7/L11 | 88.5 | 72.4 % | 15.0 % | 12 | 0.0 % | 0.00 |
| avance_street | kalis_adapt | 57.5 | 57.3 % | 7.2 % | 0 | 30.4 % | 0.00 |
| avance_street | double_progression | 96.3 | 44.5 % | 3.0 % | 0 | 0.0 % | 0.00 |
| avance_street | L7/L11 | 131.3 | 53.9 % | 9.3 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | kalis_adapt | 25.0 | 39.4 % | 7.7 % | 0 | 13.9 % | 0.00 |
| notes_paresseuses | double_progression | 58.7 | 62.6 % | 4.8 % | 0 | 0.0 % | 0.00 |
| notes_paresseuses | L7/L11 | 56.5 | 57.8 % | 7.4 % | 0 | 0.0 % | 0.00 |
| irregulier | kalis_adapt | 16.0 | 36.1 % | 6.3 % | 0 | 15.4 % | 0.00 |
| irregulier | double_progression | 44.2 | 37.3 % | 7.1 % | 0 | 0.0 % | 0.00 |
| irregulier | L7/L11 | 51.3 | 50.1 % | 30.8 % | 11 | 0.0 % | 0.00 |
| maison_halteres | kalis_adapt | 28.3 | 73.8 % | 33.3 % | 49 | 15.3 % | 0.00 |
| maison_halteres | double_progression | 99.2 | 83.7 % | 33.3 % | 107 | 0.0 % | 0.00 |
| maison_halteres | L7/L11 | 58.2 | 78.2 % | 50.0 % | 20 | 0.0 % | 0.00 |
| calisthenie_parc | kalis_adapt | 0.0 | 0.0 % | 0.0 % | 0 | 4.3 % | 0.00 |
| calisthenie_parc | double_progression | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| calisthenie_parc | L7/L11 | 0.0 | 0.0 % | 0.0 % | 0 | 0.0 % | 0.00 |
| douleur_et_lieu | kalis_adapt | 30.5 | 59.2 % | 20.0 % | 6 | 27.4 % | 0.00 |
| douleur_et_lieu | double_progression | 82.0 | 71.7 % | 20.0 % | 26 | 0.0 % | 19.33 |
| douleur_et_lieu | L7/L11 | 83.8 | 66.9 % | 20.0 % | 20 | 0.0 % | 16.50 |

## 4. Boucle complète (`kalis_adapt`, mode assisté)

Revue chaque fin de semaine, propositions appliquées, bloc suivant construit par `kalis_plan` à partir du résumé d'adaptation. Propositions : nombre moyen par simulation de 24 semaines. Déblocage : semaine moyenne où le niveau est atteint.

| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | Séance | Bloc | Volume inversé |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| debutant_salle | 2.60 ± 0.82 | 1.8 ± 0.5 % | 2.0 | 0.0 | 3.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| intermediaire_salle | 3.53 ± 0.64 | -2.6 ± 0.1 % | 2.5 | 0.0 | 3.5 | 0.0 | 0.0 | 0.3 | 0.0 % |
| avance_street | 1.86 ± 0.24 | -3.4 ± 0.1 % | 5.8 | 3.5 | 3.3 | 0.0 | 0.0 | 0.0 | 0.0 % |
| notes_paresseuses | 2.89 ± 0.41 | -2.7 ± 0.4 % | 0.5 | 0.0 | 3.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| irregulier | 1.70 ± 0.53 | -3.5 ± 0.3 % | 2.3 | 0.0 | 2.0 | 0.0 | 0.0 | 0.0 | 12.5 % |
| maison_halteres | 4.64 ± 1.07 | -1.6 ± 1.0 % | 1.5 | 0.0 | 1.8 | 0.0 | 0.0 | 0.0 | 0.0 % |
| calisthenie_parc | 2.87 ± 0.67 | -3.6 ± 0.4 % | 0.0 | 0.0 | 1.0 | 0.0 | 0.0 | 0.0 | 0.0 % |
| douleur_et_lieu | 3.83 ± 0.22 | -3.3 ± 0.1 % | 3.0 | 0.0 | 2.8 | 1.0 | 0.0 | 0.0 | 0.0 % |

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
| Décision de séance (`prescribeSession`) | 0.04 ms | 0.09 ms | 7.53 ms | ≤ 50 ms |
| Mise à jour après une série (`adviseNextSet`) | 0.05 ms | 0.10 ms | 4.44 ms | ≤ 5 ms |
| Revue (`review`) | 0.68 ms | 0.77 ms | 0.90 ms | — |
| Décision de séance à froid | 9.11 ms | 11.64 ms | 12.72 ms | — |
