# Critères KM5 — Koach 1.0.7 (la rampe de volume ne coupe jamais sous l'écrit), couple `kalis_plan` 0.4.2 × `kalis_adapt` 1.0.6

Lot KM5 (DECISIONS_CP.md C17.40). Campagne complète unique, code figé, sans exploration de variantes : 90 600 saisons du banc (34 profils × 100 graines × trois modèles de vérité × scénarios), saisons de `kalis_plan` 0.4.2, témoin 0.3.1 relu, en Dart (34 parts) **et** en Python (50 parts) dans le même run (39475063809, arbre `moteurs` du lot). Données : `docs/data/km5/`.

## 1. Définition de « volume_trop_vite » : avant / après

- **Avant (jusqu'à KM4)** : dans les vues servies par Koach, un constat `volume_trop_vite` est relevé quand les séries dures servies d'un groupe majeur dans la semaine dépassent la limite de la rampe (+20 % ou +2 séries sur la plus haute des trois semaines précédentes ; +30 % ou +4 sur deux semaines de charge), limite calculée sur le **servi** des semaines précédentes. Un programme choisi par l'athlète plus volumineux que son passé servi déclenchait donc le constat même servi exactement tel qu'écrit ; Koach 1.0.5 / 1.0.6, qui tient la même règle, coupait le programme écrit pour l'éviter (constat du propriétaire, C17.40.2).
- **Après (KM5, C17.40.3)** : violation = séries servies du groupe dans la semaine > **max(limite de la rampe, séries écrites par le programme pour ce groupe dans la semaine)** + 1e-9. Le constat porte `value` (servi), `limit` (limite de la rampe) et `ecrit` (écrit de la semaine). Pourquoi : le programme est le choix de l'athlète (C11, C11.2) ; la rampe protège contre ce que le moteur **ajoute**, pas contre l'écrit. S'applique aux vues de Koach (plan modulé, servie, servie tests faits, réalisée, et aux blocs hybrides du reclassement « retour à l'écrit ») ; le plan initial de `kalis_plan` et le contrefactuel apparié, programmes écrits, sont validés comme avant. Code : `kmFiltrerVolumeEcrit` (Dart), `securite_banc.filtrer_volume_ecrit` (Python).
- **Indicateur** : `ancienne_definition` (les deux vues du critère 7 classées avec l'ancienne définition).

## 2. Sécurité, rampe et critère KM5 (100 graines)

| Mesure | 1.0.6 (KM4, run D, Dart) | **1.0.7, Dart** | **1.0.7, Python** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | **0** | **0** |
| **Critère 7 / 8 (nouvelle définition)** | — | **0** | **0** |
| Critère 7 avec l'ancienne définition (indicateur) | 0 | **0** (0 saison) | **0** (0 saison) |
| **Série ou item retiré sous l'écrit par la rampe de volume** (`sous_ecrit_*`, critère C17.40) | non mesuré (échantillon de 27 saisons : 749 items, 1 388 séries) | **0** | **0** |
| Ligne servie sous l'écrit sans cause dite ni visible (`sans_cause_*`, mesure indépendante) | — | **0** | **0** |
| Principal retiré par la rampe sans douleur (KM4) | 0 | 0 | 0 |
| Ajouts de Koach bornés (`koach.ajout_borne`) | — | 4 040 (4 040 séries, sur 6 168 519 séances) | 4 040 |
| « Retour à l'écrit » (à part, C13.10.1) | 54 064 | **4 216** | 4 216 |
| Réalisée appariée (indicateur ; nouvelle définition en 1.0.7) | 243 277 | 22 290 | 22 290 |
| Réalisée contre le plan initial (diagnostic ; nouvelle définition en 1.0.7) | 588 202 | 36 107 | 36 107 |

Les deux mesures du critère KM5 se complètent : `sous_ecrit_*` compte les lignes servies sous leur écrit alors qu'une raison de la rampe de volume porte sur leur exercice (ce que 1.0.6 faisait : 749 items sur un échantillon de 27 saisons, `--rapide`, vérité b) ; `sans_cause_*` compte les lignes servies sous leur écrit sans aucune raison de Koach, reçues à leur écrit, bilan sans palier, aucune zone sollicitée en douleur, arrêt, reprise ou zone sensible (coupes silencieuses). Les deux valent 0 sur les 90 600 saisons.

« Retour à l'écrit » ÷ 13 et réalisée appariée ÷ 11 : Koach ne sert plus en dessous de l'écrit au nom du volume, il n'y a presque plus de semaines servies basses suivies d'un retour au programme (ce qui reste vient des autres causes : douleur, bilan, coupure). Ajouts bornés par scénario : maladie 1 094, séances manquées 520, douleur au coude 426, parc seulement 409, référence 404, douleur à l'épaule 383, deuxième échéance 336, échéance avancée 261, changement de discipline 207. Vue « servi » sans tests faits (indicateur, tentatives prescrites comptées) : `volume_trop_vite` 62 194 → 59 576 (graines 0-5), `decharge_absente` 0 → 17.

## 3. Critères du cahier (graines 0-5)

| Critère | Seuil | 1.0.6 (KM4) | **1.0.7** (Dart = Python) | Bruit (KR1) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,70 % | 3,68 % | 0,15 pt |
| 2 mauvais jour isolé | < 1 % | 0,78 % | 0,84 % | 0,25 pt |
| 3 convergence | ≤ témoin 11,0 | 4,77 | 4,759 | 0,30 |
| 4 couverture à 90 % | 88-92 % | 92,08 % | 92,03 % (bande dépassée de 0,03 pt, sous le bruit) | 0,8 pt |
| 5 calibration (C13.11.2) | indicateur | 7,4 pts ; 17 groupes : 0,186 ± 0,075 | 6,06 pts ; 17 groupes : 0,193 ± 0,074 | — |
| 6 jour J | ≥ témoin 0,9154 | 0,9349 | **0,9364** | 0,005 |
| 7 / 8 sécurité | 0 | 0 | 0 | — |
| 7 bis (tenus sur 24 : km1_v1, km1c2, km1c3, b300, b600, b3000) | ≥ 90 %, aucun sous −0,10 | 24, 22, 19, 23, 22, 21 | 24, 22, 19, 22, 22, 21 | ± 1 cas |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,331 s ; 21,9 ms | 0,176 s ; 26,9 ms | — |

Aucun recul au-delà du bruit. Jour J : +0,0015 (plus de volume servi, sous le bruit). Critère 7 bis : un cas de moins tenu sur `b300` (23 → 22), dans la marge de ± 1 cas.

## 4. Parité Dart ↔ Python

90 600 saisons comparées une à une (`comparaison/COMPARAISON_SAISONS_KM5.md`, champs `duree_s` et ordre de `first_under` exclus comme KM2c3) : **90 599 identiques**, 1 différente sur deux nombres d'une ligne d'estimation (`autres_02_hypertrophie_intermediaire`, séances manquées, vérité b, graine 36 : erreur d'e1RM −0,006268971158647885 contre −0,006268971150305003, écart 8·10⁻¹², sous la tolérance de parité de 1e-9 des fixtures) : arrondi d'algèbre linéaire (numpy de la CI contre Dart), sans effet sur aucun agrégat (sécurité, rampe, critères 0-5 identiques au chiffre près).
