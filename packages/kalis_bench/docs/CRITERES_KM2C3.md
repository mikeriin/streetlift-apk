# Couple `kalis_plan` 0.4.2 × Koach 1.0.5 en Dart (`kalis_adapt` 1.0.4) : sécurité, critères du cahier KM, parité avec la référence (lot KM2c3)

Mesures du 18/10/2026, CI `claude/ci-cp-a` (VM 4 cœurs), moteur Dart de `kalis_adapt` 1.0.4 (portage ligne pour ligne
de la référence Koach 1.0.5, paramètres `1.0.5-ref.1`), `kalis_plan` 0.4.2, `kalis_bench` 0.5.6. Koach complet
(planification, surveillance, contrôle dual, adhérence), saisons vivantes de `kmReferenceSeason` (les mêmes que lit la
référence Python : `kalis_adapt/reference/donnees/reference/`, égalité stricte vérifiée par `test/km2_banc_test.dart`),
témoin 0.3.1 relu (`donnees/temoin/`). Données : `docs/data/km2c3/`.

```
# campagne : 17 groupes de six graines (le dernier : 96-99), deux parts chacun ; déterminisme vérifié sur 0-5
dart run bin/km2.dart --graines a-b --coeurs 4 [--sans-determinisme] --temoin ../kalis_adapt/reference/donnees/temoin --partie h/2
python3 -I tool/kr1_securite.py --sortie securite.json --md SECURITE.md <parts>
dart run bin/km2.dart assembler --sortie criteres.json <les deux parts de 0-5>
python3 -I tool/kr1_securite.py --extraire <dossier> <parts d'un groupe> ; python3 -m banc.calibration_grappes <dossier> <sortie>
# parité saison par saison avec la campagne Python de KM1c4 (run 39041787498, une saison par fichier)
python3 -I tool/km2c3_comparer.py --python <dossiers de travail Python> --dart <parts> --sortie comparaison.json
# critère 7 bis : six jeux, Koach sans extension, témoin stocké
dart run bin/km2.dart adversaires --rejouer <jeu> --temoin-lu <témoin> --coeurs 4 --sortie <comparaison>
python3 -m banc.adversaire --comparer <témoin> --adversaires <jeu> --rapport <comparaison Python> --processus 4
```

Runs : 39080556198 (campagne Dart, 34 parts, 129 627 s de calcul cumulé — la campagne Python de KM1c4 en demandait
1 137 000 —, 2 h 38 de bout en bout ; six jeux d'adversaires), 39090980389 (référence Python des six jeux recalculée
sur la CI ; comparaisons).

## 1. Parité avec la référence Python 1.0.5

| Mesure | Résultat |
| --- | --- |
| Saisons comparées une à une (dictionnaire complet de `kmMesurerSaison` contre `campagne.mesurer_saison` : estimations, événements, effort, gain, aggravations, poussées, séances, alertes, calibration, sécurité ; flottants à 1e-9) | **90 600 / 90 600 identiques**, 0 différente, 0 manquante d'un côté ou de l'autre |
| Critères 1 à 7 et secondaires (graines 0-5) | identiques à `docs/data/km1c4/criteres/criteres_km1c4_python_g0_5.json`, valeur pour valeur (seuls diffèrent les textes de méthode, la source du temps et la forme de présentation du critère 5, § 3) |
| Six jeux d'adversaires (critères 7 et 7 bis) | 0 écart, adversaire par adversaire, avec la référence Python recalculée sur la CI (`comparaison/comparaison_adversaires_python_km2c3_<jeu>.json`) |

Deux champs sont exclus de la comparaison des saisons : `duree_s` (temps machine) et l'ordre de
`estimations.<mode>.first_under`, comparé trié : la référence le remplit en parcourant un ensemble Python (`ids`,
`banc/mesures.py`), dont l'ordre dépend du hachage des chaînes et change d'un processus à l'autre ; les critères n'en
lisent que les valeurs (moyenne, part sous un seuil). Une première comparaison les incluait : 90 600 saisons
« différentes » sur ces seuls champs, aucune ailleurs.

Les fichiers `kalis_adapt/reference/donnees/comparaison_adversaires_km1c4_<jeu>.json` livrés par KM1c4 ne sont pas
ceux de la référence finale : ils datent de l'état « règles 1 à 5 sans la règle 3 bis » (`km1c3` : 19 tenus, `km2_b3000` :
pire écart −0,238). La référence finale recalculée (locale et CI) donne les chiffres que `CRITERES_KM1C4.md` § 3 et
`LIVRAISON_KM1c4.md` publient (24, 22, 18, 23, 22, 21) ; c'est à elle que le Dart est identique.

## 2. Sécurité, 34 profils × 100 graines × 3 modèles de vérité × scénarios (90 600 saisons)

`docs/data/km2c3/securite/` : `securite_km2c3_100g.json`, `SECURITE_KM2C3_100G.md`, `liste_c7_km2c3_100g.json` (liste
complète, vide) ; graines 0 à 5 : `securite_km2c3_g0_5.json`.

| Mesure | KR1 (0.4.1 × 1.0.4, Dart) | KM1c4 (0.4.2 × 1.0.5, Python) | **KM2c3 (0.4.2 × 1.0.5, Dart)** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | **0** |
| **Critère 7 du cahier** | 63 (59 poussées, 4 aggravations ; 25 saisons) | 0 | **0** (graine 0 : 0 ; graines 0-5 : 0) |
| « Retour à l'écrit » (à part, C13.10.1) | 45 046 | 50 828 (12 924 saisons) | 50 828 |
| Réalisée appariée (indicateur) | 259 646 | 238 906 (61 095 saisons) | 238 906 (61 095 saisons ; graine 0 : 650) |
| Réalisée contre le plan initial (diagnostic) | 634 325 | 581 363 | 581 363 |
| Plan initial de `kalis_plan` seul | 0 | 0 | 0 |

Le critère dur C17.17.3 est tenu **par le moteur Dart** : aucune poussée, aucune aggravation, aucune hausse de charge
de plus de 10 % sur plusieurs crans, aucun constat du validateur introduit ou aggravé par Koach.

## 3. Critères du cahier (graines 0 à 5, 5 436 saisons) : Dart

`docs/data/km2c3/criteres/criteres_km2c3_g0_5.json`. Bruit : écart-type des 17 groupes de six graines de KR1.

| Critère | Seuil | KR1 (1.0.4, Dart) | KM1c4 (1.0.5, Python) | **KM2c3 (1.0.5, Dart)** |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,61 % | 3,67 % | **3,67 %** (témoin 5,83 %) |
| 2 mauvais jour isolé | < 1 % | 0,88 % | 0,81 % | **0,88 %** (n 36 ; même valeur que la référence, 0,008841) |
| 3 convergence sous 3 % | ≤ témoin (11,00) | 4,88 | 4,83 | **4,83** |
| 4 couverture à 90 % | 88-92 % | 91,42 % | 91,94 % | **91,94 %** |
| 5 calibration (C13.11.2, une prévision par cible) | lu selon C17.13.2 | — | décile 7 de la mesure KM1 : 25,9 pts | **écart max 8,8 pts < q90 d'un modèle parfait 24,3 ; biais +4,4 pts [−2,8 ; +12,1]** (§ 4) ; mesure KM1 : 25,9 pts, identique |
| 6 jour J (chargé) | ≥ témoin (0,9154) | 0,9374 | 0,9339 | **0,9339** |
| 7 sécurité (graines 0-5) | 0 | 0 | 0 | **0** |
| 7 pire cas adversarial | ≥ témoin (0) | 0,450 au plus bas | 0,450 | **0,450** (six jeux, tous ≥ témoin) |
| 7 bis apparié (6 jeux, tenus sur 24) | ≥ 90 % ; aucun sous −0,10 | 24, 22, 20, 22, 22, 21 | 24, 22, 18, 23, 22, 21 | **24, 22, 18, 23, 22, 21** (cas sous le plancher : 0, 1, 2 non excusés (3 au total), 1, 1, 1 — identiques à la référence) |
| 8 / 11 temps (VM Dart) | ≤ 10 s par replanification ; ≤ 50 ms par série | 0,242 s ; 26,6 ms | — (Python) | **0,206 s ; 32,0 ms** (`observe` série max 31,9 ms, médiane 0,64 ms ; mise à jour de série max 32,0 ms ; plan de séance max 1,2 ms ; plan de série max 1,5 ms) |

Le critère 2 vaut 0,88 % des deux côtés : la valeur 0,81 % écrite dans `LIVRAISON_KM1c4.md` § 4 ne correspond pas au
fichier de critères Python de KM1c4 (0,008841), que le Dart reproduit à l'identique. Secondaires (identiques à la
référence) : MAE au rang 6 répétitions 9,54 % (témoin 21,08 %), tenues 17,10 % (27,75 %), échecs 0,68 % (0,73 %), gain
hebdomadaire 0,00210 (0,00193), alertes de rupture 2,73 pour 100 séances, séances faites 90,8 % des prévues.

## 4. Critère 5 et son bruit entre les 17 groupes de six graines (indicateur, C17.13.2, C17.26.3)

`docs/data/km2c3/critere5/calibration_grappes_g<a>_<b>.json` (`banc.calibration_grappes` sur les saisons Dart de
chaque groupe ; une prévision par cible, quatre semaines avant l'échéance ; grappes (graine, profil, exercice)).

| Groupe | Cas | Écart max | q90 d'un modèle parfait | Biais prévu − observé (P ≥ 10 %) |
| --- | --- | --- | --- | --- |
| 0-5 | 1 758 | 0,088 | 0,243 | +0,044 |
| 6-11 | 1 800 | 0,246 | 0,269 | +0,063 |
| 12-17 | 1 707 | 0,185 | 0,346 | +0,092 |
| 18-23 | 1 545 | 0,173 | 0,374 | +0,070 |
| 24-29 | 1 752 | 0,227 | 0,315 | +0,088 |
| 30-35 | 1 758 | 0,189 | 0,301 | +0,105 |
| 36-41 | 1 746 | 0,164 | 0,331 | +0,070 |
| 42-47 | 1 845 | 0,350 | 0,358 | +0,093 |
| 48-53 | 1 533 | 0,279 | 0,296 | +0,138 |
| 54-59 | 1 662 | 0,278 | 0,335 | +0,003 |
| 60-65 | 1 389 | 0,139 | 0,303 | −0,016 |
| 66-71 | 1 737 | 0,160 | 0,281 | +0,045 |
| 72-77 | 1 749 | 0,121 | 0,285 | −0,048 |
| 78-83 | 1 452 | 0,103 | 0,352 | +0,024 |
| 84-89 | 1 757 | 0,206 | 0,327 | +0,008 |
| 90-95 | 1 536 | 0,197 | 0,336 | +0,024 |
| 96-99 | 1 047 | 0,104 | 0,323 | +0,027 |
| **17 groupes** | — | moyenne 0,189, écart-type **0,071** (0,088 à 0,350) | — | moyenne **+0,049**, écart-type 0,048 (−0,048 à +0,138) |

Lecture : l'écart maximal est sous le q90 d'un modèle parfaitement calibré aux issues liées dans les 17 groupes ; le
groupe 0-5 (celui du critère) est le plus bas des 17 (0,088) : sa valeur n'est pas représentative, le bruit entre groupes
(0,071) est du même ordre que l'écart lui-même. Le biais, lui, est **positif dans 15 groupes sur 17** (P prévue
au-dessus de la fréquence observée) : +4,9 points en moyenne, erreur-type 1,2 point, hors de ± 5 points dans 8 groupes.
Koach surestime légèrement ses chances de réussite à quatre semaines de l'échéance. C'est un comportement de la
référence 1.0.5 (Dart identique), pas du portage ; à traiter, s'il le faut, par un lot de calibration (C17.26.3).
