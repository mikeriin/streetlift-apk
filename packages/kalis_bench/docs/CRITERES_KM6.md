# Critères KM6 — Koach 1.0.8 (bugs de la revue RV1, crédits de groupes des tirages), couple `kalis_plan` 0.4.3 × `kalis_adapt` 1.0.7

Lot KM6 (DECISIONS_CP.md C17.47). Campagne complète unique, code figé, sans exploration de variantes : 90 600 saisons du banc (34 profils × 100 graines × trois modèles de vérité × scénarios), saisons de `kalis_plan` 0.4.3 (crédits « chest » des tirages, poulie par 2,5 kg), témoin 0.3.1 relu (régénéré sur `kalis_plan` 0.4.3), en Dart (34 parts) **et** en Python (50 parts) dans le même run (39764317745, arbre des paquets a58e94ec, identique à l'arbre livré sauf `test/km2_adversaire_test.dart`, valeurs attendues recalculées). Données : `docs/data/km6/`.

## 1. Sécurité, rampe et modulation (100 graines)

| Mesure | 1.0.7 (KM5, Dart = Python) | **1.0.8, Dart** | **1.0.8, Python** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | **0** | **0** |
| **Critère 7 / 8 (définition de KM5)** | 0 | **0** | **0** |
| Critère 7 avec l'ancienne définition (indicateur) | 0 | **0** (0 saison) | **0** (0 saison) |
| **Série ou item retiré sous l'écrit par la rampe de volume** | 0 | **0** | **0** |
| Ligne servie sous l'écrit sans cause dite ni visible | 0 | **0** | **0** |
| Principal retiré par la rampe sans douleur (KM4) | 0 | 0 | 0 |
| Ajouts de Koach bornés (`koach.ajout_borne`) | 4 040 | 3 673 | 3 673 |
| « Retour à l'écrit » (à part, C13.10.1) | 4 216 | 4 219 | 4 219 |
| Réalisée appariée (indicateur) | 22 290 | 22 414 | 22 414 |
| Réalisée contre le plan initial (diagnostic) | 36 107 | 35 588 | 35 588 |
| **Lignes baissées sous l'écrit par la modulation hebdomadaire (X8)** | non mesuré, sans raison | **1 825 960** lignes (1 826 779 séries) dans 1 113 375 séances sur 6 168 519 | identique |
| dont sans raison `koach.volume_semaine` | — | **0** | **0** |

**Contrôle « rampe déguisée » (X8, C17.40.3).** Part des lignes baissées par la modulation là où la rampe de volume couperait (écrit du programme de la semaine au-dessus de la limite de la rampe) : 9,81 % (339 718 sur 3 463 742) ; ailleurs : 4,42 % (1 457 394 sur 32 986 729). La modulation baisse plus souvent les semaines lourdes, mais elle ne lit aucune limite tirée du réalisé : son objectif est la performance prévue par le jumeau (fatigue, récupération, accoutumance, affûtage), avec des pénalités de surcharge et de tendon au-dessus de l'écrit seulement, et elle est bornée à ± `plafond_volume` (15 %) par qualité et à une série au moins par ligne ; 81 % des lignes baissées (1 457 394 sur 1 797 112 lignes appariées à l'écrit de leur semaine) le sont là où la rampe ne couperait pas. Ce n'est pas une rampe déguisée ; la règle n'est pas changée (pas de mesure qui le demande) ; chaque baisse est désormais dite.

## 2. Critères du cahier (graines 0-5)

| Critère | Seuil | 1.0.7 (KM5) | **1.0.8** (Dart = Python) | Bruit (KR1) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,68 % | 3,74 % | 0,15 pt |
| 2 mauvais jour isolé | < 1 % | 0,84 % | 0,86 % | 0,25 pt |
| 3 convergence | ≤ témoin 11,06 | 4,759 | 4,809 | 0,30 |
| 4 couverture à 90 % | 88-92 % | 92,03 % | 91,90 % (dans la bande) | 0,8 pt |
| 5 calibration (C13.11.2) | indicateur | 6,06 pts ; 17 groupes : 0,193 ± 0,074 | 11,95 pts ; 17 groupes : 0,190 ± 0,076 | — |
| 6 jour J | ≥ témoin 0,9156 | 0,9364 | **0,9362** | 0,005 |
| 7 / 8 sécurité | 0 | 0 | 0 | — |
| 7 bis (tenus sur 24 : km1_v1, km1c2, km1c3, b300, b600, b3000) | ≥ 90 %, aucun sous −0,10 | 24, 22, 19, 22, 22, 21 | 24, 22, 19, 23, 22, 21 | ± 1 cas |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,176 s ; 26,9 ms | 0,124 s ; 28,6 ms | — |

Aucun recul au-delà du bruit. Critère 5 : la valeur des graines 0-5 passe de 6,06 à 11,95 points, mais la moyenne sur les 17 groupes de graines est inchangée (0,190 ± 0,076 contre 0,193 ± 0,074) : la valeur de KM5 était le minimum des 17 groupes, celle de KM6 est dans la distribution. Critère 7 bis : un cas de plus tenu sur `b300` (22 → 23) ; sur `b3000`, mêmes 21 tenus, deux cas sous −0,10 non excusés au lieu d'un. Le témoin ayant été régénéré sur `kalis_plan` 0.4.3, les comparaisons à l'adversaire bougent aussi par le témoin.

## 3. Parité Dart ↔ Python

90 600 saisons comparées une à une (`comparaison/COMPARAISON_SAISONS_KM6.md`, mêmes exclusions que KM2c3) : **90 599 identiques**, 1 différente sur un nombre d'une ligne d'estimation (`autres_02_hypertrophie_intermediaire`, maladie, vérité c, graine 14 : 0,0009259226536211251 contre 0,0009259226524263031, écart 1,2·10⁻¹², relatif 1,3·10⁻⁹ : juste au-dessus de la tolérance de comparaison de la campagne, 1e-12 absolu ou 1e-9 relatif ; sous la tolérance de parité des fixtures, 1e-9 × max(1, |a|, |b|)) : arrondi d'algèbre linéaire, comme la saison de KM5, sans effet sur aucun agrégat (sécurité, rampe, modulation, critères 0-5 identiques au chiffre près).

## 4. Crédits de groupes : trois tables

`test/km6_credits_test.dart` compare exercice par exercice les crédits de `kalis_plan` 0.4.3 (`CatalogTraits`, `chestCreditRule`), les fiches de Koach (référence et asset, champ `groupes`) et l'export lu par le validateur Python (`donnees/catalogue_infos.json.gz`) : aucun écart. Table avant / après : `kalis_adapt/reference/CHANGEMENTS_1_0_8.md` § B et `SOURCES.md` § 4.
