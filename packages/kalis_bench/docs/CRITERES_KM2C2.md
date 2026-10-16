# Critères du cahier KM sur Koach 1.0.3 en Dart (lot KM2c2, `kalis_adapt` 1.0.2)

**Note (lot KR1, 16/10/2026)** : `kalis_adapt/reference/donnees/reference/` et `temoin/` contiennent désormais les saisons régénérées sur `kalis_plan` 0.4.1 (34 profils) ; les saisons figées sur 0.3.1 lues par les commandes ci-dessous sont dans `kalis_bench/docs/data/kr1/saisons_figees_0_3_1/reference/` et `temoin/` (remplacer les chemins pour refaire ces mesures).

Mesures du 16/10/2026, CI `claude/ci-cp-a` (run 38853167917, VM Dart de la CI, 4 cœurs), code de `kalis_adapt` 1.0.2
et `kalis_bench` 0.5.1. Données : `docs/data/km2c2/`. Avant : `kalis_adapt` 1.0.1 (Koach 1.0.2,
`docs/data/km2c1/criteres_km2c1_g05.json`) ; référence : Koach 1.0.3 Python (`kalis_adapt/reference/donnees/criteres_km1c3.json`,
`calibration_grappes_km1c3.json`, `comparaison_adversaires_km1c3*.json`).

**Saisons figées.** Depuis `kalis_plan` 0.4.0 (KS1), la saison vivante de `kmReferenceSeason` n'est plus celle que lit
la référence Python (`reference/donnees/reference/`, figée sur `kalis_plan` 0.3.1 : charges du § 8 du cahier KS). Une
première campagne sur les saisons vivantes (run 38851049094) donnait donc d'autres chiffres (12 adversaires de
`autres_03_powerlifter_competition` sur 40 et les prévisions de la planification dès la première semaine, κ = 1 :
sans rapport avec le delta porté). La parité se mesure sur les saisons figées et le témoin relu :

```
dart run bin/km2.dart --graines 0-5 --coeurs 4 --partie i/4 \
    --saisons-figees ../kalis_adapt/reference/donnees/reference --temoin ../kalis_adapt/reference/donnees/temoin
dart run bin/km2.dart assembler --sortie criteres_km2c2_g05.json <les quatre parts>
dart run bin/km2.dart adversaires --rejouer <jeu> --temoin-lu <témoin> \
    --saisons-figees ../kalis_adapt/reference/donnees/reference
```

## Campagne (graines 0 à 5, 4 320 saisons, Koach complet)

Quatre parts de 1 080 saisons (990 à 1 070 s chacune, en parallèle), 0 saison plantée ; déterminisme vérifié (deux
isolats, mêmes empreintes). Les critères 1 à 4, 6 et 7, les critères secondaires et le bilan sont **identiques** à
ceux de la référence Python sur les mêmes saisons (`criteres_km1c3.json`), valeur pour valeur ; critère 5 :
`python3 -m banc.calibration_grappes` sur les 4 320 saisons Dart donne un fichier identique, champ pour champ, à
`calibration_grappes_km1c3.json` (`calibration_grappes_km2c2.json`) ; l'ancienne mesure par déciles (KM1) aussi
(0,220143, n 5 796).

| Critère | Seuil | 1.0.2 Dart (KM2c1) | 1.0.3 Dart (KM2c2) | 1.0.3 Python (KM1c3) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart documenté, C13.11.1) | 3,92 % | 3,94 % | 3,94 % |
| 2 mauvais jour isolé | < 1 % | 0,91 % | 0,87 % | 0,87 % |
| 3 convergence sous 3 % | ≤ témoin 11,98 | 5,28 | 5,28 | 5,28 |
| 4 couverture à 90 % | 88-92 % | 89,96 % | 90,21 % | 90,21 % |
| 5 calibration (C13.13.1 amendée par C17.13.2) | biais ± 5 points ; écart max < quantile 90 % d'un modèle parfait aux issues liées | +0,2 ; 16,8 (médiane 21,2) | biais −0,6 point [−8,5 ; +7,8] ; 24,4 contre q90 32,8 (médiane 21,3 ; un modèle parfait fait au moins autant dans 35 % des tirages) : **tenu** | identique |
| 6 jour J | ≥ témoin 0,9324 | 0,9450 | 0,9449 | 0,9449 |
| 7 sécurité | 0 | 0 | 0 | 0 |
| 8 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,127 s ; 12,7 ms | 0,335 s ; 9,7 ms | — (Python : 0,56 s ; 7,3 ms) |

## Banc adversarial (critères 7 et 7 bis, Koach sans extension, témoin relu, saisons figées)

Pour chacun des six jeux, les mesures de Koach par adversaire, les groupes et le critère 7 bis sont **identiques** à
ceux de la référence Python (`comparaison_adversaires_km1c3*.json`).

| Jeu | Appariés | ≥ témoin − 0,03 | Sous témoin − 0,10 (non excusés) | Pire écart | Pire Koach (critère 7) |
| --- | --- | --- | --- | --- | --- |
| KM1 (`adversaires_v1.json`) | 24 | 24 (100 %) | 0 | −0,018 | 0,788 |
| KM2 b300 | 24 | 22 (92 %) | 1 | −0,143 | 0,774 |
| KM2 complet b600 | 24 | 22 (92 %) | 1 | −0,103 | 0,450 |
| KM2 b3000 | 24 | 21 (88 %) | 1 | −0,234 | 0,519 |
| Recherche de KM1c2 | 24 | 22 (92 %) | 1 | −0,145 | 0,704 |
| Recherche de KM1c3 contre 1.0.3 (indicateur suivi, C17.13.1) | 24 | 19 (79 %) | 2 | −0,150 | 0,555 |

Critère 7 tenu partout (témoin : pire cas 0). Critère 7 bis : mêmes chiffres que la référence (accepté comme tenue du
point C13.13.2, C17.13.1).
