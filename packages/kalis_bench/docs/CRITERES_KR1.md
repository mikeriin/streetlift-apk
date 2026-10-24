# Couple `kalis_plan` 0.4.1 × Koach 1.0.4 : sécurité et critères du cahier KM (lot KR1)

Mesures du 16/10/2026, CI `claude/ci-cp-a` (VM Dart de la CI, 4 cœurs), `kalis_adapt` 1.0.3 (Koach 1.0.4),
`kalis_plan` 0.4.1, `kalis_bench` 0.5.3. Données : `docs/data/kr1/`. Saisons : `kmReferenceSeason` sur le
`kalis_plan` courant, identiques aux données de référence régénérées que lit Python
(`kalis_adapt/reference/donnees/reference/`, 34 profils ; `test/km2_banc_test.dart`, égalité stricte). Koach complet
(planification, surveillance, contrôle dual, adhérence), comme les campagnes KM1 à KM2c2.

```
dart run bin/km2.dart --graines a-b --coeurs 4 --temoin ../kalis_adapt/reference/donnees/temoin --partie h/2
python3 -I tool/kr1_securite.py --sortie securite.json --md SECURITE.md <parts>
dart run bin/km2.dart assembler --sortie criteres.json <parts d'un groupe de graines>
```

Runs : 38932288447 (critères par groupe, adversaires), 38947564079 (sécurité avec les vues réalisées, critères du
groupe 0-5, tests), 38906984200 (campagne Python de la référence sur les graines 0 à 5), 38898708985 (Koach 1.0.3 :
saisons plantées).

## 1. Sécurité, 34 profils × 100 graines × 3 modèles de vérité × scénarios (90 600 saisons)

`docs/data/kr1/securite/securite_kr1_100g.json`, `SECURITE_KR1_100G.md` ; graines 0 à 5 : `securite_kr1_g0_5.json`.

| Mesure | Toutes graines | Graine 0 (saisons racontées) | Graines 0-5 |
| --- | --- | --- | --- |
| Saisons plantées | 0 (Koach 1.0.3 : 8 sur 5 436, graines 0-5) | 0 | 0 |
| **Critère 7 du cahier** (introduits ou aggravés par Koach, douleur, hausses > 10 %) | **63** : 59 poussées de douleur, 4 aggravations (25 saisons) | **0** | 0 |
| dont hausses de volume « introduites » | 0 (9 mesurés, reclassés « retour à l'écrit » après correction du banc, § 2) | 0 | 0 |
| « Retour à l'écrit » (publié à part, DECISIONS_CP.md C13.10.1) | 45 046 (11 589 saisons) | 76 | 2 236 |
| Saison réalisée appariée (diagnostic, § 3) | 259 646, dont 255 630 hausses de volume (62 401 saisons) | 784 | 12 248 |
| Saison réalisée contre le plan initial (diagnostic) | 634 325 | 2 204 | 29 761 |
| Plan initial de `kalis_plan` 0.4.1 seul | 0 | 0 | 0 |

Critère 7, par profil : `autres_08` 38 poussées (graine 47, sept scénarios), `street_03` 13 (séances manquées,
vérité b), `ks_01` 4 et `ks_03` 4 (douleur au coude ou à l'épaule, graine 38), `street_10` 4 aggravations (séances
manquées, vérité b). Par modèle de vérité : b 48, c 15, a 0. Causes : LIVRAISON_KR1.md § 4 et
`kalis_adapt/reference/tests/test_kr1_violations.py`.

## 2. Correction du banc : retour à l'écrit après un bloc interrompu

Les 9 hausses de volume « introduites » (`ks_01` échéance avancée, graines 18 et 86 ; `ks_06` changement de
discipline, graine 38 ; `autres_08` changement de discipline, graine 87) suivaient une séance manquée comptée à son
volume écrit, après un bloc interrompu : `kmRetirerRetoursALEcrit` (et `campagne.retirer_retours_a_l_ecrit`)
indexait les semaines de la saison sans tronquer ce bloc, et testait l'hypothèse « semaines d'avant écrites » sur la
mauvaise semaine. Corrigé (semaines servies, `blockWeeks`) ; les 9 sont des « retours à l'écrit » (vérifié en
Python sur chacune ; fixture du banc et test Python).

## 3. Saison réalisée appariée (vue `realise_apparie`, diagnostic)

Séances faites telles que servies, séances manquées vidées, classées contre le plan écrit aux MÊMES séances
manquées vidées. Ce qui reste mesure les hausses de volume par groupe d'une semaine à l'autre (règle du banc :
+20 % ou +2 séries sur la plus haute des trois semaines précédentes) dans ce que l'athlète a réellement fait, au-delà
de ce qu'aurait donné le plan écrit : le volume servi par Koach varie d'une semaine à l'autre (prudence, contrôle de
dose, allègements, exercices arrêtés), puis revient vers l'écrit. Exemple (`autres_08`, changement de discipline, a,
87) : ischios servis 1 ; 1 ; 1 ; 1,5 puis 4 séries (écrit : 5 ; 5 ; 6 ; 6 ; 6). Ni le cahier ni les décisions ne
font de cette vue un critère ; elle est publiée pour la décision du pilotage (LIVRAISON_KR1.md § 6).

## 4. Critères du cahier (graines 0 à 5) et bruit entre groupes de graines

Saisons figées (KM2c2) : 27 profils, `kalis_plan` 0.3.1, Koach 1.0.3. Couple : `kalis_plan` 0.4.1, Koach 1.0.4,
27 profils (même ensemble) et 34 profils. Bruit : écart-type des 17 groupes de six graines
(`docs/data/kr1/criteres/criteres_kr1_par_groupe.json`).

| Critère | Seuil | Figées (27) | Couple (27) | Couple (34) | Bruit (27 ; 34) | Recul au-delà du bruit |
| --- | --- | --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,94 % | 3,83 % | 3,61 % | 0,20 ; 0,15 pt | non (mieux) |
| 2 mauvais jour isolé | < 1 % | 0,87 % | 0,88 % | 0,88 % | 0,25 pt | non (+0,01 pt) |
| 3 convergence sous 3 % | ≤ témoin | 5,28 (témoin 11,98) | 5,42 (témoin 11,92) | 4,88 (témoin 11,01) | 0,31 ; 0,30 | non (+0,14) |
| 4 couverture à 90 % | 88-92 % | 90,21 % | 90,08 % | 91,42 % | 0,9 ; 0,8 pt | non |
| 5 calibration | biais ± 5 pts ; écart max < q90 | −0,6 ; 24,4 < 32,8 | −1,6 ; 18,9 < 30,4 | identique | — | non (mieux) |
| 6 jour J | ≥ témoin | 0,9449 (témoin 0,9324) | 0,9453 (témoin 0,9320 ; +0,0116 ± 0,0015) | 0,9374 (témoin 0,9154 ; +0,0197 ± 0,0029) | 0,004 ; 0,005 | non |
| 7 pire cas adversarial | ≥ témoin (0) | 0,450 à 0,788 | — | 0,450 à 0,782 | — | non |
| 7 bis apparié (6 jeux) | ≥ 90 % ; aucun sous −0,10 | 24, 22, 22, 21, 22 ; 19 | — | 24, 22, 22, 21, 22 ; 20 | — | non (égal ou mieux) |
| 8 sécurité (graines 0-5) | 0 | 0 | 0 | 0 | — | non |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,335 s ; 9,7 ms | 0,242 s ; 26,6 ms | idem | 0,05 s ; 6,6 ms (max 39,1 ms) | dans le budget |

Critères 1 à 4, 6, 7 et secondaires : la campagne Dart (graines 0-5, 34 profils) donne les mêmes valeurs que la
référence Python (`criteres_kr1_python_34p_g0_5.json`, même mesure du critère 5 « toutes dates » 0,145) ; vingt
saisons tirées au hasard sont identiques champ pour champ, vues de sécurité comprises
(`parite_saisons_echantillon_g05.json` ; seul l'ordre des « premiers passages », un ensemble Python, diffère).

Sur les autres groupes de graines (34 profils) : critère 2 de 0,79 à 1,59 % (moyenne 1,10 %), critère 4 de 90,6 à
94,0 % (moyenne 92,2 %) : les seuils de 1 % et de 92 % ne tiennent pas sur tous les groupes de six graines ; la mesure
du cahier (graines 0 à 5, C13.12) les tient. Critère 6 apparié seulement sur les graines 0 à 15 (témoin exporté sur 16
graines).
