# Critères du cahier KM sur Koach 1.0.2 en Dart (lot KM2c1, `kalis_adapt` 1.0.1)

Mesures du 15/10/2026, CI `claude/ci-cp-a` (VM Dart 3.13.4, 4 cœurs), code de `kalis_adapt` 1.0.1 et `kalis_bench` 0.4.2.
Données : `docs/data/km2c1/`. Avant : `kalis_adapt` 1.0.0 (Koach 1.0.1, `docs/data/km2/criteres_km2_g05.json`) ;
témoin : `kalis_adapt` 0.3.1 sur les mêmes saisons.

## Campagne (graines 0 à 5, 4 320 saisons, Koach complet)

`dart run bin/km2.dart --graines 0-5 --coeurs 4 --partie i/4` (quatre parts de 1 080 saisons, 604 à 706 s chacune),
puis `assembler` : `criteres_km2c1_g05.json`. 0 saison plantée ; déterminisme vérifié (deux isolats, mêmes empreintes).

| Critère | Seuil | 1.0.1 (KM2) | 1.0.2 Dart (KM2c1) | 1.0.2 Python (KM1c2) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart documenté, C13.11.1) | 3,95 % | 3,92 % | 3,92 % |
| 2 mauvais jour isolé | < 1 % | 0,95 % | 0,91 % | 0,91 % |
| 3 convergence sous 3 % | ≤ témoin 11,98 | 5,25 | 5,28 | 5,28 |
| 4 couverture à 90 % | 88-92 % | 93,2 % | 89,96 % (n 69 484) | 89,96 % |
| 5 calibration (mesure C13.13.1) | biais ± 5 points ; écart max sous la médiane d'un modèle parfait aux issues liées | — | biais +0,2 point [−7,0 ; +8,2] ; 16,8 points contre 21,2 | identique |
| 6 jour J | ≥ témoin 0,9324 | 0,9459 | 0,9450 | 0,9450 |
| 7 sécurité | 0 | 0 | 0 (aucune aggravation, aucune poussée, aucune hausse interdite, validateur : rien d'introduit dans les plans modulés) | 0 |
| 8 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,21 s ; 21,5 ms | 0,127 s ; 12,7 ms | — (Python : 0,44 s ; 2,8 ms) |

Les critères 1 à 4, 6 et 7 sont identiques à la décimale publiée à ceux de la référence Python sur les mêmes saisons
(`kalis_adapt/reference/donnees/criteres_km1c2.json`). Critère 5 : `python3 -m banc.calibration_grappes` sur les 4 320
saisons Dart donne un résultat identique, champ pour champ, à `donnees/calibration_grappes_km1c2.json`
(`calibration_grappes_km2c1.json`) ; l'ancienne mesure par déciles reste rapportée (16,78 points).

## Banc adversarial (critère 7 et 7 bis, Koach sans extension, témoin relu)

`dart run bin/km2.dart adversaires --rejouer <jeu> --temoin-lu <témoin>` sur les cinq jeux connus. Pour chaque jeu,
les mesures de Koach par adversaire, les groupes et le critère 7 bis sont identiques à ceux de la référence Python
(`donnees/comparaison_adversaires_km1c2*.json`).

| Jeu | Appariés | ≥ témoin − 0,03 | Sous témoin − 0,10 | Pire écart | Pire Koach (critère 7) |
| --- | --- | --- | --- | --- | --- |
| KM1 (`adversaires_v1.json`) | 24 | 24 (100 %) | 0 | −0,016 | 0,809 |
| KM2 b300 | 24 | 23 (96 %) | 0 | −0,070 | 0,805 |
| KM2 complet b600 | 24 | 22 (92 %) | 0 | −0,099 | 0,441 |
| KM2 b3000 | 24 | 20 (83 %) | 2 | −0,303 | 0,499 |
| Recherche de KM1c2 contre 1.0.2 (indicateur suivi, C13.13.2) | 24 | 17 (71 %) | 6 | −0,303 | 0,499 |

Critère 7 tenu partout (témoin : pire cas 0). Critère 7 bis : tenu sur les trois premiers jeux, non tenu sur b3000
(accepté pour le portage, C13.13.2) ; la recherche neuve est l'indicateur que KM1c3 doit faire progresser.
