# Critères KM4 — Koach 1.0.6 (retour gradué priorisé), couple `kalis_plan` 0.4.2 × `kalis_adapt` 1.0.5

Lot KM4 (DECISIONS_CP.md C17.37). Campagnes sur les 90 600 saisons du banc (34 profils × 100 graines × trois modèles de vérité × scénarios), saisons de `kalis_plan` 0.4.2, témoin 0.3.1 relu. Données : `docs/data/km4/`. Mesure nouvelle du banc (0.5.7) : `rampe` par saison (`kmMesureRampe` / `mesure_rampe`) — principaux écrits (`main`) réduits par `koach.retour_gradue`, part servie, et **principaux retirés par la rampe de volume sans douleur** (critère C17.37).

## 1. Runs

| Run | Moteur | Contenu |
| --- | --- | --- |
| A (39247073902) | Dart, Koach 1.0.5 (`kalis_adapt` 1.0.4) | point de départ avec la mesure de la rampe (`data/km4/securite/securite_km4avant_*`) |
| B (39260047813) | Python, 1.0.6 avec répartition sur la semaine (`retour_repartition_semaines` 4) | **critère 7 = 40** (28 saisons, `autres_10`, graines 48 et 96, semaine 5) : répartition désactivée (`data/km4/securite/repartie_python_*`) |
| D (39304949115) | Dart, 1.0.6 sans répartition, variante P (`retour_emprunt_plancher` 1) | campagne Dart complète (`securite_km4P_dart_*`) ; la variante M (0) n'a pas tourné (pas de SDK sur ses parts) |
| E (39312132226) + G | Python, même moteur que D | campagne Python ; la part 13/20 de E a dépassé 355 min (89 438 saisons), refaite par G en 13/40 et 33/40 |
| F (39336305801) | Dart, arbre final | tests, six jeux d'adversaires, critères Dart 0-5, critère 5 par groupe, comparaison D ↔ E |

## 2. Sécurité et rampe (100 graines)

| Mesure | Avant (1.0.5, run A) | 1.0.6 réparti (run B, Python) | **1.0.6 livré (run D, Dart)** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | **0** |
| Critère 7 du cahier | 0 | **40** (`volume_trop_vite`) | **0** |
| « Retour à l'écrit » (à part) | 50 828 | 57 945 | 54 064 |
| Réalisée appariée (indicateur) | 238 906 | 242 810 | 243 277 |
| **Principal retiré par la rampe sans douleur** | **147 665** (126 688 séances) | 0 | **0** |
| Séances avec un principal réduit par le retour gradué | 4,27 % (193 806 / 4 534 824) | 2,52 % | 3,11 % (141 079) |
| Part moyenne des séries écrites servie à un principal réduit | 7,0 % | 34,5 % | 36,2 % |

Par scénario (run D) : la réduction touche surtout les scénarios de douleur (`douleur_coude` 7,7 % des séances avec principal, part servie 24 % ; `douleur_epaule` 9,8 %, 26 %), où un principal sur une zone sensible passe au rang des secondaires (la conduite sous douleur garde la main) ; ailleurs 1,1 à 2,5 %, part servie 54 à 57 %.

Campagne Python (même moteur) : ⟨G⟩.

## 3. Critères du cahier (graines 0-5)

| Critère | Seuil | 1.0.5 (KM2c3) | **1.0.6** (Dart = Python) | Bruit (KR1) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,67 % | 3,70 % | 0,15 pt |
| 2 mauvais jour isolé | < 1 % | 0,88 % | 0,78 % | 0,25 pt |
| 3 convergence | ≤ témoin 11,0 | 4,83 | 4,77 | 0,30 |
| 4 couverture à 90 % | 88-92 % | 91,94 % | **92,08 %** (+0,14 pt, sous le bruit ; bande dépassée de 0,08 pt) | 0,8 pt |
| 5 calibration (mesure C13.11.2) | indicateur | 8,8 pts | 7,4 pts ; par groupe de six graines : moyenne 0,186, écart-type 0,075 (KM2c3 : 0,189, 0,071) | — |
| 6 jour J | ≥ témoin 0,9154 | 0,9339 | 0,9349 | 0,005 |
| 7 sécurité (graines 0-5) | 0 | 0 | 0 | — |
| 7 bis (six jeux, tenus sur 24) | ≥ 90 %, aucun sous −0,10 | 24, 22, 18, 23, 22, 21 | 24, 22, 19, 23, 22, 21 | ± 1 cas |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,206 s ; 32,0 ms | 0,331 s ; 21,9 ms | — |

## 4. Parité

Run F : 89 438 saisons Python (run E) comparées aux saisons Dart du run D, **89 438 identiques**, 0 différente (champs `duree_s` et ordre de `first_under` exclus, comme KM2c3) ; ⟨G⟩.
