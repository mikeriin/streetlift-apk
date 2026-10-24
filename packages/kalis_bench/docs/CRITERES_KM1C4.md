# Couple `kalis_plan` 0.4.2 × Koach 1.0.5 (référence Python) : sécurité et critères du cahier KM (lot KM1c4)

Mesures du 17/10/2026, CI `claude/ci-cp-a` (VM 4 cœurs), référence Python de Koach 1.0.5 (`kalis_adapt/reference/`,
paramètres `1.0.5-ref.1`), `kalis_plan` 0.4.2, `kalis_bench` 0.5.5. Données : `docs/data/km1c4/`. Saisons :
`kmReferenceSeason` sur `kalis_plan` 0.4.2 (`bin/km1.dart`, export des 34 profils ; identiques à celles de 0.4.1 hors
`engineVersion` ; le témoin 0.3.1 change sur les cinq saisons « douleur à l'épaule » de `ks_01` à `ks_04` et
`street_12`, KS1c2), les mêmes que lit la référence Python (`kalis_adapt/reference/donnees/reference/`, régénérées).
Koach complet (planification, surveillance, contrôle dual, adhérence), comme les campagnes KM1 à KR1.

Le moteur Dart de `kalis_adapt` 1.0.3 reste Koach 1.0.4 (portage de 1.0.5 : lot KM2c3) : la campagne « après » est donc
la campagne Python de la référence (`banc.campagne --partie i/20`, 20 parts sur la CI, saisons de `kalis_plan` 0.4.2
exportées dans chaque part), agrégée en flux par `banc/securite_campagne.py` (mêmes mesures que
`tool/kr1_securite.py` sur les parts Dart). Le « point de départ » (avant) est la campagne Dart de KR1 rejouée sur
`kalis_plan` 0.4.2 (`bin/km2.dart`, Koach 1.0.4).

```
# avant (Dart, Koach 1.0.4), 17 groupes de six graines, deux parts chacun
dart run bin/km2.dart --graines a-b --coeurs 4 --temoin ../kalis_adapt/reference/donnees/temoin --partie h/2
python3 -I tool/kr1_securite.py --sortie securite.json --md SECURITE.md <parts>
# après (Python, Koach 1.0.5), 20 parts, 100 graines
python3 -m banc.campagne --graines 100 --coeurs 4 --partie i/20 --travail <dossier>
python3 -m banc.securite_campagne --sortie securite.json --md SECURITE.md --liste liste.json [--graines 0-5] <dossier>
python3 -m banc.campagne --graines 6 --coeurs 4 --travail <dossier> --temps-existants --sortie criteres.json
```

Runs : 39009299479 (avant : export 0.4.2, campagne Dart 0.4.2 × 1.0.4, point de départ), 39016950696 (après : campagne
Python 1.0.5, 100 graines), 39027489495 (assemblage des mêmes parts sur le témoin 0.4.2 : sécurité, critères 0-5).

## 1. Sécurité, 34 profils × 100 graines × 3 modèles de vérité × scénarios (90 600 saisons)

`docs/data/km1c4/securite/` : `securite_km1c4_100g.json`, `SECURITE_KM1C4_100G.md`, `liste_c7_km1c4_100g.json` (liste
complète des saisons en violation) ; graine 0 et graines 0 à 5 : `securite_km1c4_g0.json`, `securite_km1c4_g0_5.json` ;
point de départ : `securite_km1c4_depart_100g.json`, `liste_c7_km1c4_depart_100g.json`, `securite_km1c4_depart_g0_5.json`.

| Mesure | KR1 (0.4.1 × 1.0.4, Dart) | Point de départ (0.4.2 × 1.0.4, Dart) | **0.4.2 × 1.0.5 (Python)** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | 0 |
| **Critère 7 du cahier** (poussées, aggravations, hausses > 10 %, constats introduits ou aggravés par Koach) | **63** : 59 poussées, 4 aggravations (25 saisons) | **63** : 59 poussées (b 41, c 18), 4 aggravations (b) ; 25 saisons, mêmes saisons que KR1 | **0 (règles 1 à 5 seules, run 39016950696 : 4 poussées, 3 saisons `street_03`)** |
| dont graine 0 (saisons racontées) / graines 0-5 | 0 / 0 | 0 / 0 | 0 / 0 |
| « Retour à l'écrit » (publié à part, DECISIONS_CP.md C13.10.1) | 45 046 (11 589 saisons) | 45 046 (11 595 saisons) | 50 828 (12 924 saisons) |
| Saison réalisée appariée (indicateur, LIVRAISON_KR1.md § 6) | 259 646 (62 401 saisons) | 259 646 (62 401 saisons ; graine 0 : 784) | 238 906 (61 095 saisons ; graine 0 : 650) |
| Saison réalisée contre le plan initial (diagnostic) | 634 325 | 634 325 (72 197 saisons) | 581 363 |
| Plan initial de `kalis_plan` seul | 0 | 0 | 0 |

Critère 7 : 0 constat, aucune poussée, aucune aggravation, aucune hausse de charge de plus de 10 % sur plusieurs crans, aucun constat du validateur introduit ou aggravé par Koach (`plan_module`, `servi_tests_faits`), sur les 90 600 saisons (1 137 000 s de calcul cumulé, 20 parts). Réalisée appariée : 234 120 hausses de volume par groupe, 4 420 `tendon_figures`, 234 `decharge_absente`, 132 `affutage_absent` (259 646 en KR1, 255 480 avec les règles 1 à 5 : la rampe de retour abaisse le réalisé après une coupure, ce qui déplace des hausses vers « retour à l'écrit » : 45 046 → 50 828).

## 2. Critères du cahier (graines 0 à 5) : avant / après

Avant : campagne Dart du point de départ (`criteres_km1c4_depart_g0_5.json`, identique à KR1 `criteres_kr1_34p_g0_5.json`
sur les critères 1 à 7) et campagne Python de KR1 (`kr1/criteres/criteres_kr1_python_34p_g0_5.json`, mêmes valeurs,
critère 5 « toutes dates » 0,145). Après : campagne Python 1.0.5 (`docs/data/km1c4/criteres/criteres_km1c4_python_g0_5.json`,
témoin 0.4.2). Bruit : écart-type des 17 groupes de six graines de KR1 (`kr1/criteres/criteres_kr1_par_groupe.json`,
34 profils).

| Critère | Seuil | Avant (1.0.4) | **Après (1.0.5)** | Bruit KR1 | Recul au-delà du bruit |
| --- | --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,61 % | 3,67 % | 0,15 pt | non (+0,06 pt) |
| 2 mauvais jour isolé | < 1 % | 0,88 % | 0,81 % | 0,25 pt | non (mieux) |
| 3 convergence sous 3 % | ≤ témoin | 4,88 (témoin 11,01) | 4,83 (témoin 11,00) | 0,30 | non (mieux) |
| 4 couverture à 90 % | 88-92 % | 91,42 % | 91,94 % | 0,8 pt | non (+0,52 pt, dans la bande) |
| 5 calibration (toutes dates, Python) | biais ± 5 pts ; écart max < q90 | 0,145 | 0,259 (décile 7, 71 cas : prévu 75,2 %, observé 49,3 %) | — | hors bruit mesuré : 1,4 erreur-type binomiale (73 et 71 cas) ; déjà non tenu |
| 6 jour J | ≥ témoin | 0,9374 (témoin 0,9154) | 0,9339 (témoin 0,9154 ; +0,0159 ± 0,0030) | 0,005 | non (−0,0035, sous 0,005) |
| 7 pire cas adversarial | ≥ témoin (0) | 0,450 au plus bas | 0,450 au plus bas (inchangé) | — | non |
| 7 bis apparié (6 jeux) | ≥ 90 % ; aucun sous −0,10 | 24, 22, 22, 21, 22 ; 20 (KR1, Dart) | 24, 22, 18, 23, 22, 21 | — | −1 sur `km1c3`, +1 sur `km2_b300` (§ 3) |
| 8 sécurité (graines 0-5) | 0 | 0 | 0 | — | non |
| 11 temps | ≤ 10 s ; ≤ 50 ms | 0,242 s ; 26,6 ms (VM Dart, KR1) | Python seulement (§ 4) | — | à mesurer au portage |

Critère 1 : 3,67 % contre 3,61 % (bruit 0,15 pt) ; le témoin fait 5,83 %. Critère 4 : 91,94 %, dans la bande 88-92 %, +0,52 pt (bruit 0,8 pt). Critère 5 : écart maximal d'un décile peuplé (n ≥ 30), porté par le décile 7 (71 à 73 cas selon la version) : 14,5 → 25,9 pts ; erreur pondérée tous cas 0,018 → 0,026 ; le critère n'est tenu par aucune version depuis KM1c2 (« à trancher », KM1c3) ; KR1 n'a pas mesuré son bruit entre groupes ; sur 71 cas, l'erreur-type binomiale d'une proportion observée vaut 6 pts : l'écart entre les deux versions (10 pts) est de 1,4 erreur-type. Critère 6 : Koach 0,9339 contre 0,9374 (bruit 0,005) ; le gain sur le témoin apparié reste +0,0159 ± 0,0030 (KR1 : +0,0197 ± 0,0029) : coût de la conduite sous douleur sur le jour J, −0,004, dans le bruit. Secondaires : MAE au rang 6 répétitions 9,54 % (témoin 21,08 %), tenues 17,10 % (27,75 %), échecs 0,68 % (0,73 %), gain hebdomadaire 0,00210 (0,00193), alertes de rupture 2,73 pour 100 séances.

## 3. Critère 7 bis : six jeux d'adversaires (Python, témoin stocké)

`kalis_adapt/reference/donnees/comparaison_adversaires_km1c4_<jeu>.json` (`banc.adversaire --comparer`, Koach 1.0.5
rejoué en Python sur les adversaires des jeux `km1_v1`, `km1c2`, `km1c3`, `km2_b300`, `km2_complet_b600`, `km2_b3000`,
témoin Dart 0.3.1 stocké).

| Jeu | KM1c3 (1.0.3, Python, témoin stocké) : tenus / sous le plancher / pire écart / jour J moyen | KR1 (1.0.4, Dart, son témoin) : tenus | **KM1c4 (1.0.5)** : tenus / sous le plancher / pire écart / jour J moyen |
| --- | --- | --- | --- |
| `km1_v1` | 24 / 0 / −0,018 / 0,8860 | 24 | **24** / 0 / −0,009 / 0,8866 |
| `km1c2` | 22 / 1 / −0,145 / 0,8705 | 22 | **22** / 1 / −0,142 / 0,8708 |
| `km1c3` | 19 / 2 / −0,150 / 0,8146 | 20 (témoin Dart différent sur `adv-1f8d4738`) | **18** / 2 / −0,144 / 0,8104 |
| `km2_b300` | 22 / 1 / −0,143 / 0,8764 | 22 | **23** / 1 / −0,143 / 0,8782 |
| `km2_complet_b600` | 22 / 1 / −0,103 / 0,9001 | 22 | **22** / 1 / −0,103 / 0,9001 |
| `km2_b3000` | 21 / 1 / −0,234 / 0,8800 | 21 | **21** / 1 / −0,248 / 0,8805 |

Même témoin que KM1c3 (celui que lit Python) : cas sous le plancher identiques sur les six jeux ; tenus −1 sur `km1c3`
(`adv-8f63907e`, `street_07` c : sur une de ses trois graines, le muscle-up lesté ouvert à 6,25 kg échoue trois fois là
où 1.0.4 ouvrait à 0 kg — l'estimation apprise pendant la rampe de retour d'une coupure de 11 jours avec 26 % de
séances manquées : 0,935 → 0,630 sur cette graine, +0,016 et −0,013 sur les deux autres), +1 sur `km2_b300`
(`adv-433b3b7e`, +0,027) ; jour J moyen des jeux de −0,004 à +0,002 ; les adversaires qui changent de jour J ont tous
une fiche de douleur, un diagnostic « rien de spécial » ou une coupure. Les règles 1 à 5 seules donnaient 24, 22, 19,
23, 22, 21 ; la règle 3 bis appliquée en semaine de compétition coûtait jusqu'à −0,26 à un adversaire
(`adv-5e2b8ac3` : tentatives de dips retirées le jour J), d'où sa suspension en semaine verrouillée (CHANGEMENTS § B).

## 4. Temps de calcul (indicatif : référence Python)

Le critère 11 vaut pour le portage Dart (KM2c3). Coût des règles 1 à 5 en Python (`criteres_moteur.mesurer_temps`,
trois mesures par version, médianes des moyennes ; session du lot, 2 cœurs, numpy 2.5.3) :
`docs/data/km1c4/criteres/temps_python_km1c4.json`.

| Saison | `observe` série (ms) 1.0.4 → 1.0.5 | plan de séance (ms) | replanification (s) |
| --- | --- | --- | --- |
| `street_07` référence a 0 (saison du critère) | 2,41 → 2,34 (−2,7 %) | 0,948 → 0,949 (+0,1 %) | 0,471 → 0,485 (+3,1 %) |
| `ks_01` douleur à l'épaule b 38 | 2,33 → 2,21 (−5,1 %) | 0,890 → 0,894 (+0,5 %) | 0,770 → 0,786 (+2,1 %) |
| `autres_08` référence b 47 | 1,87 → 1,88 (+0,5 %) | 0,878 → 0,911 (+3,7 %) | 0,290 → 0,295 (+1,8 %) |

Écarts de −5 à +4 % : dans le bruit de la machine (les trois mesures d'une même version s'écartent d'autant).
