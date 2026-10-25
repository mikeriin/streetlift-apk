# Critères KM7 — Koach 1.0.9 (forme du jour versée sans être appliquée, remplaçants en séance), couple `kalis_plan` 0.4.3 × `kalis_adapt` 1.0.8

Lot KM7 (DECISIONS_CP.md C17.54, lot express). Campagne complète unique, code du moteur figé : 90 600 saisons du banc (34 profils × 100 graines × trois modèles de vérité × scénarios), en Dart (34 parts) **et** en Python (50 parts) dans le même run (40107907131, essai 3, arbre 0b4d8b6c ; publié sur `claude/ci-cp-a` 32f5de2), six jeux d'adversaires, et la variante « l'athlète garde l'écrit une fois sur deux » (run 40107907131 pour « non versé », run 40161629201 pour « versé », témoin corrigé). Données : `docs/data/km7/`.

## 1. Campagne ordinaire : identique à KM6

Sans les nouveaux champs (`bilan.applique`, `remplace`), Koach 1.0.9 sert et apprend exactement comme 1.0.8. Les fichiers de critères, de sécurité et d'adversaires de KM7 sont **identiques** à ceux de KM6 (`kalis_bench/docs/data/km6/`), champ par champ, hormis la version du moteur et les durées de calcul.

| Mesure (100 graines) | 1.0.8 (KM6) | **1.0.9 Dart** | **1.0.9 Python** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | **0** | **0** |
| Critère 7 / 8 (violations de sécurité) | 0 | **0** | **0** |
| Série ou item retiré sous l'écrit par la rampe | 0 | **0** | **0** |
| Coupe sous l'écrit sans cause | 0 | **0** | **0** |
| « Retour à l'écrit » / réalisée appariée | 4 219 / 22 414 | 4 219 / 22 414 | 4 219 / 22 414 |

| Critère (graines 0-5) | Seuil | 1.0.8 | **1.0.9** (Dart = Python) |
| --- | --- | --- | --- |
| 1 e1RM rang 6 | < 3 % (écart accepté) | 3,74 % | 3,74 % |
| 2 mauvais jour | < 1 % | 0,86 % | 0,86 % |
| 3 convergence | ≤ 11,06 | 4,809 | 4,809 |
| 4 couverture | 88-92 % | 91,90 % | 91,90 % |
| 5 calibration | indicateur | 11,95 pts | 11,95 pts |
| 6 jour J | ≥ 0,9156 | 0,9362 | 0,9362 |
| 7 bis (six jeux) | ≥ 90 % | 24, 22, 19, 23, 22, 21 | 24, 22, 19, 23, 22, 21 |
| 11 temps (VM Dart, CI) | ≤ 10 s ; ≤ 50 ms | 0,124 s ; 28,6 ms | replanification ≤ 0,114 s ; mise à jour après une série ≤ 14,0 ms (p95 0,71 ms) |

**Parité** : 90 600 saisons comparées une à une, 90 599 identiques ; la même saison qu'en KM6 diffère de 1,2·10⁻¹² sur une ligne d'estimation (`autres_02`, maladie, vérité c, graine 14 ; arrondi d'algèbre linéaire).

## 2. Variante « garde l'écrit une fois sur deux » (mode Libre)

Chaque séance dont le bilan a une forme du jour est gardée à l'écrit une fois sur deux (pile ou face déterministe par graine et par jour). « Versé » : bilan complet avec `applique: false`. « Non versé » : seuls les faits du bilan (lecture de dev7.7.2). Campagne Python.

**Plan identique au plan sans forme** (version « versé », un témoin dans la même séance : copie du moteur, extensions comprises, mêmes événements avant le plan, seuls les faits du bilan) : **395 364 séances gardées sur 395 364, item par item, raisons comprises** (graines 0-17, 16 308 saisons, 780 783 séances avec forme). Premier passage (run a) : 886 écarts, tous dus au témoin, une copie du moteur sans ses extensions qui ne recevait pas la réponse au diagnostic de la surveillance versée entre le début de séance et le plan. Une saison relue (street_01, maladie, vérité b, jour 44) : douleur retirée chez le moteur, appui neutre chez le témoin. Témoin corrigé : 0 écart.

| Graines 0-5 (5 436 saisons) | Non versé | **Versé** | Écart | Bruit (KR1) |
| --- | --- | --- | --- | --- |
| Résidu d'e1RM de la séance gardée (moyenne, \|·\|) | 0,01906 | **0,01767** | −7,3 % | — |
| Résidu brut de la séance gardée (réserve) | 2,055 | **1,990** | −3,2 % | — |
| Résidu d'e1RM de la séance suivante | 0,01791 | 0,01789 | −0,1 % | — |
| Résidu brut de la séance suivante | 1,970 | 2,009 | +2,0 % | — |
| 1 e1RM rang 6 | 3,68 % | **3,65 %** | −0,03 pt | 0,15 pt |
| 3 convergence | 4,714 | **4,614** | −0,10 | 0,30 |
| 4 couverture à 90 % | 91,21 % | 92,20 % | +1,0 pt | 0,8 pt |
| 6 jour J | 0,9349 | **0,9385** | +0,004 | 0,005 |
| 7 sécurité | 0 | **0** | — | — |

**Ce que Koach apprend de plus.** Avec la forme versée, la séance gardée est interprétée avec l'a priori du bilan : son résidu d'e1RM baisse de 7 %, parce qu'une moins bonne séance un jour de bilan bas est attribuée au jour et pas à la capacité. Sur les critères, le gain est réel mais **dans le bruit** : e1RM −0,03 pt, convergence −0,10 séance, jour J +0,004. La séance suivante n'est pas mieux prédite : résidu d'e1RM égal, résidu brut +2 %. Seul effet au-delà du bruit, la couverture passe de 91,2 % à 92,2 %, juste au-dessus de la bande 88-92 % : l'intervalle est un peu plus large, ce qui est prudent et sans effet sur la sécurité. Pour comparaison, la campagne ordinaire (bilan appliqué partout) donne e1RM 3,74 %, convergence 4,81, couverture 91,9 %, jour J 0,9362.

## 3. Remplaçants

Tests seulement (le banc ne remplace pas d'exercice) : `reference/tests/test_km7.py`, `test/koach_km7_test.dart`. Parité Dart ↔ Python : fixture de 7 scénarios et 1 218 demandes aléatoires (relecture indépendante), sans écart. Temps de `Koach.remplacants` sur le catalogue complet (1 039 fiches, VM Dart de la session) : médiane 2,2 ms, maximum 19,5 ms.
