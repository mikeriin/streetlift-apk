# Critères du cahier KM mesurés sur Koach Dart (lot KM2)

Mesures du 11/10/2026, `kalis_adapt` 1.0.0 (Koach 1.0, portage Dart de la référence Python 1.0.1) contre le
témoin `kalis_adapt` 0.3.1, sur la matrice du banc : 27 profils, tous leurs scénarios, trois modèles de vérité
(a, b, c), planification (1 000 trajectoires), surveillance, contrôle dual et adhérence, comme la campagne de KM1.
Commande : `dart run bin/km2.dart` (`lib/src/km/campagne.dart`, `criteres_moteur.dart`), en quatre parts
(`--partie i/4`) assemblées (`assembler`) sur les runners de la CI (VM Dart 3.13.4, 4 cœurs). Données :
`docs/data/km2/`.

## Le banc Dart redonne la référence

Campagne sur les graines 0 et 1 (1 440 saisons, `criteres_km2_g01.json`) : les critères 1, 2, 3, 4, 6 et 7 sont
**identiques à la décimale près** à ceux de la référence Python (`kalis_adapt/reference/donnees/criteres_km1.json`,
KM1 correction 1). Seuls changent les temps (VM Dart au lieu de Python) et la mesure du critère 5, fixée depuis par
C13.11.2. Le rejeu des 40 adversaires de KM1 redonne le pire cas publié (0,798913). Cinq saisons complètes sont aussi
vérifiées ligne par ligne contre Python (`test/km2_banc_test.dart`).

## Critères (11)

| # | Critère | Seuil | Koach, graines 0-5 (4 320 saisons) | Koach, graines 0-1 (= KM1) | Témoin 0.3.1 | Tenu |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM au rang 6 (moyenne des 3 vérités) | < 3 % | 3,95 % (a 3,04, b 5,08, c 3,72) | 3,98 % | 7,11 % | non (écart documenté, C13.11.1 ; ne recule pas) |
| 2 | Mauvais jour isolé (contrefactuel apparié) | < 1 % | 0,95 % | 0,95 % | — | oui |
| 3 | Séances pour passer sous 3 % | ≤ témoin | 5,25 | 4,86 | 11,98 | oui |
| 4 | Couverture de l'intervalle à 90 % (rangs ≥ 3) | 88-92 % | **93,2 %** | 90,4 % | 83,4 % | non sur 6 graines |
| 5 | Calibration de P(réussite) par cible (C13.11.2 : 1 prévision par cible à 4 semaines, déciles ≥ 30) | ≤ 5 points | **15,3 points** (n = 1 758) | 13,9 points | — | non |
| 6 | Performance le jour J (meilleure barre / maximum du jour) | ≥ témoin | 0,9459 | 0,9409 | 0,9324 / 0,9254 | oui |
| 7 | Pire cas du banc adversarial | ≥ témoin | voir plus bas : 0,2260 (nouvelle recherche) | 0,7989 (adversaires de KM1) | 0,0 | oui (au sens du cahier) |
| 8 | Violations de sécurité | 0 | 0 | 0 | 111 / 38 | oui |
| 9 | Parité Python / Dart | ≤ 1e-9 | 13 fixtures (traces comprises) + 5 saisons + 1 440 saisons de la campagne | | | oui |
| 10 | Rejeu du journal réel | bascule | non mesuré (C13.11.3 : juste avant la bascule) | | | — |
| 11 | Temps (VM Dart, après une saison de chauffe JIT) | ≤ 10 s, ≤ 50 ms | replanification 0,21 s max ; série (observe + plan suivant) 21,5 ms max, p95 ≈ 1,3 ms | 0,20 s ; 30,6 ms | — | oui |

Ligne 8 (violations de sécurité, clé `7_securite` du JSON) : comme en KM1, la vue « servi » qui compte chaque tentative prescrite d'une rampe de test comme
une série dure, et les séances manquées à leur volume écrit, est publiée à part (`mesure_avec_rampes_de_test`,
KM1.5 accepté par C13.10.1).

Temps (ligne 11) : saison `kmSaisonTemps` de 16 semaines ; `observe` et `plan` chronométrés sur un moteur sans
extension (comme la référence), les replanifications sur le rejeu de la même saison avec la planification. Une saison
de chauffe (compilation JIT de la VM ; l'application est compilée d'avance) est chronométrée à part
(`premiere_saison`). L'application replanifie jusqu'à 40 semaines : KM3 mesure sur émulateur.

Banc adversarial : les « violations » des tableaux de `comparaison_adversaires_km2_*.json` sont indicatives (tous les
constats du programme servi, retours à l'écrit et rampes de test compris, comme en KM1 : 185 à 212 selon la
recherche) ; aucune aggravation ni poussée de douleur chez Koach.

## Critère 5 (calibration de P(réussite)), mesure fixée par C13.11.2

Déciles des 1 758 cibles (graines 0 à 5) : 0-10 % prédit 2,0 % / observé 1,0 % (n 1 233) ; 10-20 % : 14,1 / 3,7 (192) ;
20-30 % : 24,6 / 27,3 (110) ; 30-40 % : 35,2 / 32,2 (59) ; 40-50 % : 45,6 / 36,1 (72) ; 50-60 % : 53,6 / 68,9 (45) ;
60-70 % : 65,3 / 57,1 (35). Écart maximal sur les déciles d'au moins 30 cibles : **15,3 points** (50-60 %), puis
10,4 (10-20 %). Au-delà de 5 points : C13.11.2 prévoit une passe courte « KM1 correction 2 » limitée au modèle de
réussite du jumeau (Koach Dart en portera l'écart).

## Critère 4 sur six graines

Sur les graines 0 et 1 (celles de KM1, sur lesquelles `defaut_modele_sd` a été calé), la couverture vaut 90,4 % ;
sur les graines 0 à 5, 93,2 % (rangs 6 : 93,9 %, 12 : 94,3 %) : l'intervalle est trop large sur les graines que le
calage n'a pas vues. Ce n'est pas un défaut de portage (le Dart redonne exactement 90,4 % sur les graines 0-1) ;
c'est le calage de `mesure.defaut_modele_sd` (0,015), à refaire sur plus de graines.

## Banc adversarial

| Recherche | Koach | Adversaires | Pire Koach | Moyenne Koach (pires, n = 32) | Moyenne témoin (mêmes adversaires) | Koach ≥ témoin, appariés |
| --- | --- | --- | --- | --- | --- | --- |
| KM1, rejouée | sans extension | 40 | 0,7989 | 0,872 | 0,603 | — |
| KM1, rejouée | complet | 40 | 0,7474 | 0,842 | 0,603 | — |
| nouvelle, budget 300 | sans extension | 40 | 0,7699 | 0,854 | 0,650 | — |
| **nouvelle, budget 3 000** | sans extension | 40 | **0,2260** | 0,601 | 0,660 | 9 sur 24 |
| **nouvelle, budget 600** | complet | 40 | **0,2482** | 0,699 | 0,719 | 9 sur 24 |

Le critère du cahier (pire cas de Koach ≥ pire cas du témoin) reste tenu parce que le pire cas du témoin vaut 0
(saisons sans barre réussie). Mais une recherche plus longue trouve des athlètes sur lesquels Koach fait nettement
moins bien que 0.3.1 **sur le même athlète** : par exemple `adv-31c45cfb` (powerlifter, vérité b, coupure de 12 jours
à J−19, douleur lombaire 3/10 de J14 à J33, notes peu fiables) : Koach 0,226 (développé couché ouvert et maintenu à
37,5 kg pour un maximum vrai de 165 kg), témoin 0,823. Mécanisme observé (référence Python, même résultat que le
Dart) : après la coupure et la douleur, les séances servent des charges très basses (« pas de hausse », « hausse
bornée » ancrée sur les derniers passages légers) ; l'ouverture des tentatives est bornée par ce que les barres
réussies des 42 derniers jours justifient (+10 %), ces barres sont légères, et les tentatives suivantes ne montent
pas malgré des barres dites faciles. C'est une question de méthode (règles de KM1 « plus prudentes que 0.3.1 »),
hors du périmètre d'un portage à l'identique : signalée au pilotage.
