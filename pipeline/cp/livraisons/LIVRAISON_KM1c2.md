# Livraison KM1c2 — « KM1 correction 2 » : référence Python de Koach 1.0.2

Lot KM1c2 du pipeline CP (méthode Koach, `CAHIER_KM.md`, décision C13.12), voie A, session Fable 5.1 effort maximal,
le 11/10/2026 de 05:20 à 11:30 UTC. Prompt : `prompts/KM1c2.txt`. Base : `moteurs` df28b47c (référence
1.0.1, `kalis_adapt` 1.0.0).

**En une phrase** : la référence Python de Koach passe en 1.0.2 (paramètres `1.0.2-ref.1`) ; le blocage sur des
charges basses après une coupure est corrigé (l'adversaire de C13.12 passe de 0,23 à 0,85 de son maximum, au-dessus
du moteur actuel) et l'intervalle à 90 % est juste sur six graines (89,96 %) ; aucun critère tenu ne recule et la
sécurité reste à 0 violation ; **deux cibles de C13.12 ne sont pas atteintes** après les deux itérations permises :
le critère 7 bis apparié (tenu sur trois jeux d'adversaires connus sur quatre, 71 % sur une recherche neuve) et le
critère 5 (16,8 points au pire décile), dont la mesure, telle qu'elle est définie, ne peut pas descendre à 5 points
sur ce banc (démonstration chiffrée au § 4). Le pilotage tranche (§ 6).

## 1. Livré

| Élément | Où | Contenu |
| --- | --- | --- |
| Référence Koach 1.0.2 | `moteurs` 9ac79e40, `packages/kalis_adapt/reference/` | `koach/seance.py`, `modele.py`, `planification.py`, `dual.py`, `rupture.py` ; `VERSION = '1.0.2-ref.1'` |
| Paramètres | `params/koach_params_v1.json` | `1.0.2-ref.1`, 322 clés (5 nouvelles, 1 valeur changée), SHA-256 `211c9361…f5da` |
| Fixtures de parité | `fixtures/` | les 13 régénérées, plus `moteur_11.json` (tentatives après une coupure de 12 jours) : 14 |
| Liste exacte des changements | `CHANGEMENTS_1_0_2.md` | sections A à G : règles, paramètres, banc, tests, relecture, mesures finales |
| Contrat | `CONTRAT_1_0.md` | note datée du 11/10/2026 ; règles de séance, tentatives, tables de paramètres à jour |
| Sources | `SOURCES.md` | une ligne par clé nouvelle ou changée (référence vérifiée ou mesure) |
| Portage | `PORTAGE_DART.md` | section « delta 1.0.2 » pour KM2c1 |
| Mesures | `donnees/criteres_km1c2.json`, `donnees/adversaires_km1c2*.json`, `donnees/comparaison_adversaires_km1c2*.json`, `donnees/calibration_grappes_km1c2.json` | campagne six graines, recherche adversariale neuve, comparaisons appariées, analyse du critère 5 |
| `kalis_bench` 0.4.1 | `etiquettes/kalis_bench-v0.4.1` | chemins des tests seulement (voir § 7) ; aucune mesure ni API changée |

Le code Dart de `kalis_adapt` (`lib/`) n'est pas touché : `kalis_adapt` reste 1.0.0 (Koach 1.0.1) jusqu'au portage
KM2c1. L'API et le schéma du journal du contrat 1.0 ne changent pas.

Contrôle complet (`claude/ci-cp-a`) : run 38129459466, vert (formatage, analyse, tests de tous les paquets Dart). Tests
Python de la référence : 237 verts ; `fixtures/generer.py --verifier` : à jour.

## 2. Critères du cahier, avant (1.0.1) et après (1.0.2), six graines

Même matrice que KM2 : 27 profils, tous leurs scénarios, vérités a, b et c, graines 0 à 5, 4 320 saisons, Koach
complet (planification à 1 000 trajectoires, surveillance, contrôle dual, adhérence), 0 saison plantée. Avant :
`kalis_bench/docs/data/km2/criteres_km2_g05.json` (Dart = Python à 1e-9). Après : `donnees/criteres_km1c2.json`.

| # | Critère | Seuil | 1.0.1 | 1.0.2 | Témoin 0.3.1 | Tenu |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM au rang 6 | < 3 % | 3,95 % | **3,92 %** | 7,11 % | non — écart documenté (C13.11.1), ne recule pas |
| 2 | Mauvais jour isolé (apparié) | < 1 % | 0,95 % | **0,91 %** | — | oui |
| 3 | Convergence sous 3 % (séances) | ≤ témoin | 5,25 | 5,28 | 11,98 | oui |
| 4 | Couverture de l'intervalle à 90 % | 88-92 % | 93,2 % | **89,96 %** | 83,4 % | **oui** (non tenu en 1.0.1) |
| 5 | Calibration de P(réussite), une prévision par cible (C13.11.2) | ≤ 5 points | 15,3 points | 16,8 points | — | non (§ 4) |
| 6 | Jour J (meilleure barre / maximum) | ≥ témoin | 0,9459 | 0,9450 | 0,9324 | oui |
| 7 | Pire cas adversarial | ≥ témoin | 0,226 | **0,499** (recherche neuve de 3 000 saisons contre 1.0.2) | 0,0 | oui |
| 7 bis | Adversaires appariés (C13.12) | ≥ 90 % à témoin − 0,03 ; aucun sous témoin − 0,10 | 42 % ; 13 cas ; pire −0,60 | 83 % ; 2 cas ; pire −0,30 sur le même jeu (§ 3) | — | non (§ 3) |
| 8 | Violations de sécurité | 0 | 0 | **0** | 54 (apparié) | oui |
| 9 | Parité Python / Dart | ≤ 1e-9 | tenue (1.0.1) | à refaire au portage KM2c1 (14 fixtures prêtes) | — | — |
| 10 | Rejeu du journal réel | bascule | — | — (C13.11.3) | — | — |
| 11 | Temps | ≤ 10 s ; ≤ 50 ms | 0,21 s ; 21,5 ms (VM Dart) | 0,44 s ; 2,8 ms (Python, runner de la CI ; VM Dart : KM2c1) | — | oui |

Bilan : **7 critères tenus** (2, 3, 4, 6, 7, 8, 11) ; non tenus : 1 (écart documenté), 5, 7 bis ; 9 se remesure en
KM2c1, 10 à la bascule. Par rapport à 1.0.1 : le critère 4 passe au vert, aucun critère tenu ne recule (3 et 6
varient de 0,03 séance et de 0,0009, dans le bruit : l'écart-type de l'écart apparié du jour J est 0,0016).

Détail utile :
- Critère 1 par vérité : a 2,98 %, b 5,11 %, c 3,66 % (1.0.1 : 3,95 % en moyenne).
- Critère 4 par vérité : a 93,9 %, b 88,0 %, c 88,0 % ; par rang de séance : 93,9 % au rang 3, 91,7 % au rang 6,
  91,2 % au rang 12, 81,7 % au rang 24 (n 1 058 : la fin des longues saisons reste trop étroite).
- Critère 8 : aucune aggravation, aucune poussée de douleur, aucune hausse au-delà des bornes, rien d'introduit ni
  d'aggravé par Koach au validateur (plan modulé et séances servies, tentatives faites). La vue qui compte chaque
  tentative prescrite d'une rampe de test comme une série dure reste publiée à part (`mesure_avec_rampes_de_test`),
  comme en KM1 (KM1.5).

## 3. Adversaires appariés (critère 7 bis)

Koach 1.0.2 rejoué en Python sans extension (`PolitiqueKoach()`, configuration du banc adversarial de KM1), témoin
0.3.1 rejoué en Dart (`bin/km1.dart --outils-seuls`) sur les mêmes athlètes ; 24 adversaires appariés par jeu (ceux
où les deux moteurs ont un jour J). Colonnes 1.0.1 : mesures publiées par KM2.

| Jeu d'adversaires | 1.0.1 : ≥ témoin − 0,03 | 1.0.1 : sous témoin − 0,10 | 1.0.2 : ≥ témoin − 0,03 | 1.0.2 : sous témoin − 0,10 | Pire écart (1.0.1 → 1.0.2) | Pire Koach (1.0.1 → 1.0.2) | 7 bis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| KM1 (300 saisons, contre 1.0) | 22 (92 %) | 1 | 24 (100 %) | 0 | −0,138 → −0,016 | 0,799 → 0,809 | tenu |
| KM2 b300 (contre 1.0.1) | 20 (83 %) | 2 | 23 (96 %) | 0 | −0,138 → −0,070 | 0,770 → 0,805 | tenu |
| KM2 complet b600 (contre 1.0.1 complet) | 12 (50 %) | 6 | 22 (92 %) | 0 | −0,556 → −0,099 | 0,248 → 0,441 | tenu |
| KM2 b3000 (contre 1.0.1) | 10 (42 %) | 13 | 20 (83 %) | 2 | −0,597 → −0,303 | 0,226 → 0,499 | non |
| Recherche neuve, 3 000 saisons contre 1.0.2 | — | — | 17 (71 %) | 6 | −0,303 | 0,499 | non |

Aucune violation de sécurité, aucune aggravation, aucune poussée, aucun plantage de Koach sur les cinq jeux.

Ce qui est corrigé (cause de C13.12) : la semaine du retour d'une coupure, toute charge et l'ouverture des tentatives
étaient bornées par le « dernier passage » de l'exercice, quel que soit l'emplacement (sur `adv-31c45cfb` : un simple
d'affûtage à 47,5 kg pour un maximum de 157 kg, puis trois tentatives à 47,5 kg). 1.0.2 remonte par paliers mesurés
(§ 5.1). `adv-31c45cfb` : 0,226 → 0,854 (témoin 0,823).

Ce qui reste (les 6 cas sous le plancher de la recherche neuve : 5 sur le streetlifter avancé, 1 sur le
powerlifter) : dans chacun, sur une graine, un mouvement du jour J finit à zéro. L'estimation y est de 10 à 12 %
trop haute (notes bruitées de 1 à 2,5 flammes, réserve dite décalée, séries non notées, 19 à 32 % de séances
manquées), l'ouverture tombe au-dessus du maximum du jour (145 kg pour 142 kg ; 232,5 kg pour 230 kg) et la barre,
gardée après un échec (règle A8.2 de 0.3.1, inchangée : en compétition on ne baisse pas une barre), est ratée trois
fois ; les autres mouvements de la même saison sont à 0,87-0,99. Le témoin ouvre à 91 % d'une estimation en retard
et passe ses barres : il gagne sur ces athlètes par sous-estimation, et perd ailleurs (il finit à zéro sur 7 des 24
adversaires appariés, où Koach fait 0,50 à 0,94). Ce n'est plus un excès de
prudence des bornes de reprise : c'est l'estimation sous notes non fiables, hors du périmètre des deux itérations.

## 4. Critère 5 : mesuré, corrigé là où il était faux, et pourquoi 5 points sont hors d'atteinte de la mesure

Mesure de C13.11.2 (une prévision par cible, 4 semaines avant l'échéance ; déciles d'au moins 30 cas ; 1 758 cas).

| Décile prévu | 1.0.1 : n ; prévu ; observé | 1.0.2 : n ; prévu ; observé |
| --- | --- | --- |
| 0-10 % | 1 233 ; 2,0 % ; 1,0 % | 1 374 ; 1,5 % ; 1,2 % |
| 10-20 % | 192 ; 14,1 % ; 3,6 % | 100 ; 13,8 % ; 6,0 % |
| 20-30 % | 110 ; 24,6 % ; 27,3 % | 75 ; 24,5 % ; 40,0 % |
| 30-40 % | 59 ; 35,2 % ; 32,2 % | 56 ; 35,9 % ; 30,4 % |
| 40-50 % | 72 ; 45,6 % ; 36,1 % | 55 ; 44,8 % ; 43,6 % |
| 50-60 % | 45 ; 53,6 % ; 68,9 % | 38 ; 54,3 % ; 71,1 % |
| 60-70 % | 35 ; 65,3 % ; 57,1 % | 37 ; 65,3 % ; 59,5 % |

- Écart maximal : 15,3 → 16,8 points. Écart pondéré sur tous les cas : 3,2 → 2,4 points. Cas à 10 % et plus : prévu
  31,2 %, observé 27,4 % en 1.0.1 ; prévu 36,4 %, observé 36,2 % en 1.0.2 (biais global +0,2 point).
- Ce qui a été corrigé : la dispersion des trajectoires du jumeau à l'échéance était trop large pour les cibles
  chargées. Mesurée sur les graines 0, 2 et 4 (717 cibles : rapport 0,623 entre la dispersion observée et la
  dispersion simulée), vérifiée sur les graines 1, 3 et 5 jamais vues (0,625). Paramètre `dispersion_echeance` = 0,62.
- Pourquoi la mesure ne peut pas conclure à 5 points (`donnees/calibration_grappes_km1c2.json`,
  `banc/calibration_grappes.py`) : les 1 758 cas ne sont pas indépendants. Le même athlète (profil, graine) et la
  même cible reviennent dans chaque scénario et chaque vérité, avec la même issue : 96 grappes (graine, profil,
  exercice), dont 80 à issue unique ; les 384 cas à 10 % et plus viennent de 42 grappes et de 5 profils. Un modèle
  **parfaitement calibré** dont les issues sont liées dans la grappe donne un écart maximal médian de 21 points
  (10 % des tirages sous 12 points ; aucun sous 5 points sur 2 000 tirages). 16,8 points, comme 15,3, n'est pas
  distinguable d'une calibration parfaite ; par moitié de graines, les mêmes déciles sont tantôt au-dessus, tantôt
  au-dessous (30-40 % prévus : 3,8 % observés sur les graines 0, 2, 4 ; 53,3 % sur 1, 3, 5).
- Ce que la mesure permet de dire : pas de biais global (+0,2 point ; intervalle à 90 % par rééchantillonnage des
  grappes : −7 à +8 points) ; le défaut le plus net de 1.0.1 (10-20 % prévus, 3,6 % observés, 4,2 écarts-types en
  comptant les cas comme indépendants) est réduit (écart de 10,4 à 7,8 points).

## 5. Ce qui change dans la méthode

Liste exacte : `CHANGEMENTS_1_0_2.md`. Chaque paramètre a sa ligne dans `SOURCES.md`.

### 5.1 Reprise par paliers mesurés (point 1 de C13.12)

- Lignes chargées, semaine du retour d'une coupure : la première série est bornée par la dernière séance du **même
  schéma** (emplacement et répétitions), plus par le dernier passage tous emplacements confondus. Chaque série
  suivante ne monte (règle ordinaire : +5 % ou un cran) que si le palier précédent est franchi : série réussie,
  notée, dite au plus aussi dure que visé, répétitions faites. Sinon la charge reste. Aucune série ne dépasse la
  borne de hausse d'une séance ordinaire (A7.2 de 0.3.1). Séries × 0,8, pas de test maximal hors jour d'épreuve, pas
  de série de mesure : inchangés.
- L'ancre « dernier passage de l'exercice » ne vaut plus que sous douleur (zone douloureuse, bloquante ou en
  reprise) : c'est l'invariant de 0.3.1 et celui que le modèle de douleur du banc sanctionne. Un jour de bilan bas
  sans douleur : borne de la dernière séance du même schéma, charge gelée d'une série à l'autre (comme 0.3.1).
- Ouverture des tentatives : le plafond « barres réussies des 42 jours + 10 % » devient un palier selon la note de
  la plus lourde barre récente : +10 % si elle a été dite à 4 répétitions de réserve ou plus, +7,5 % à 3, +5 % à 2,
  +2,5 % à 1, rien si elle n'est pas notée ou dite à la limite ; la note la plus dure des barres à moins de 5 % de
  la plus lourde l'emporte ; une barre ratée récente plafonne. Construction (`SOURCES.md`) : une barre dite à R
  répétitions de l'échec vaut un (R + 1)RM dans la table charge-répétitions de la NSCA (Sheppard et Triplett 2016),
  moins une répétition de prudence parce que la réserve annoncée se trompe d'environ une répétition (Halperin et al.
  2022, 12 études). Contexte vérifié : choix des tentatives en compétition (Travis 2021 : ouverture à 91 % du
  troisième essai ; Howells 2022), reprise après arrêt (consensus CSCCa / NSCA, Caterisano 2019 ; Bosquet 2013 et
  McMaster 2013 : peu de perte de force maximale en 2 à 3 semaines). La remontée par paliers elle-même est un choix
  de Koach, mesuré sur le banc, pas une recommandation chiffrée de ces textes.
- Tentatives suivantes : quand le saut en pourcentage est plus petit qu'un cran de la grille, un cran est permis
  après une barre dite facile. Sauts, probabilités, barre gardée après un échec : règles de 0.3.1, inchangées.
- Deux itérations : (1) palier par barre ; (2) palier de la plus lourde barre avec la note la plus dure des barres
  proches (retenue : échecs d'ouverture 12 → 6 sur 409 ouvertures d'adversaires connus, jour J du banc inchangé).

### 5.2 P(réussite) du jour J (point 2)

Dispersion du jumeau à l'échéance multipliée par `dispersion_echeance` (0,62, mesurée puis vérifiée sur des graines
jamais vues), pour les cibles chargées seulement, appliquée progressivement sur les 4 premières semaines de journal
(mesuré : 0,89 sans journal, 0,57 à mi-saison, 0,63 à 4 semaines de l'échéance). Cibles en répétitions ou en tenue :
mesure non concluante (0,69 et 1,06 selon la moitié des graines), inchangées. Deux itérations : (1) tous horizons et
toutes cibles ; (2) cibles chargées et montée en 4 semaines, après la relecture.

### 5.3 Intervalle à 90 % (point 3)

`mesure.defaut_modele_sd` 0,015 → 0,010 et un facteur `mesure.intervalle_echelle` = 0,9 sur l'écart-type du filtre.
Le défaut de modèle seul ne suffisait pas (92,3 % encore à zéro sur les graines 0, 2, 4) : c'est le « seulement ce
qui est nécessaire » du prompt. Réglé sur les graines 0, 2 et 4 (90,2 % hors ligne), mesuré sur les six : 89,96 %.
Le contrôle dual lit la variance brute du filtre (ses mises à jour bayésiennes ne changent pas).

## 6. Ce que le pilotage doit trancher

1. **Critère 7 bis non tenu sur une recherche neuve (71 %, 6 cas sous le plancher)** alors que le mécanisme visé par
   C13.12 est corrigé. Les cas restants sont des ouvertures au-dessus du maximum du jour quand l'estimation est trop
   haute sous notes non fiables. Pistes, toutes hors du périmètre de ce lot (elles touchent l'estimation ou une
   règle de 0.3.1) : (a) ouverture plus basse quand les notes de l'athlète se sont montrées peu fiables (dispersion
   des résidus de ses notes), au prix du jour J moyen (mesuré ici : exiger P ≥ 0,975 à l'ouverture pour
   tous fait passer le jour J du banc de 0,9412 à 0,9387, P ≥ 0,99 à 0,9313) ; (b) accepter 7 bis sur les jeux connus et suivre la recherche neuve comme indicateur ; (c) une passe
   « estimation sous notes non fiables ». Recommandation : (b) pour le portage KM2c1, (c) avant la bascule.
2. **Critère 5** : la mesure par déciles sur 4 320 saisons juge 42 grappes indépendantes ; elle ne peut pas descendre
   à 5 points même pour un modèle parfait. Recommandation : remplacer le seuil par une mesure qui respecte la
   dépendance — biais global des cas à 10 % et plus dans ± 5 points (mesuré : +0,2), et écart maximal par décile
   jugé contre la distribution d'un modèle parfait aux issues liées (mesuré : 16,8 points, sous la médiane de 21) —
   ou multiplier les athlètes indépendants (environ 30 graines pour 200 grappes, soit cinq fois le calcul).
3. **Règle signalée par la relecture, préexistante, non modifiée** : après un échec non prévu, 0.3.1 interdit toute
   hausse par rapport à la dernière séance de l'exercice ; Koach ne l'interdit que sur le même schéma. Règle plus
   prudente à ajouter ou non (coût sur le jour J à mesurer).
4. Constat hors configuration officielle : sans la planification (banc « outils seuls »), 3 poussées de douleur sur
   une saison (profil street_03, séances manquées, vérité b, graine 2), identiques en 1.0.1 ; 0 en Koach complet.

## 7. Pour KM2c1 (portage court)

- Delta à porter : `PORTAGE_DART.md`, section 1.0.2 ; `CHANGEMENTS_1_0_2.md` A à D. Fichiers Dart concernés :
  `seance`, `modele`, `planification`, `dual`, `rupture`, `parametres` ; asset `koach_params_1_0_2.json`.
- Les tests Dart de `kalis_adapt` 1.0.0 et de `kalis_bench` lisent depuis ce lot des copies figées de 1.0.1
  (`reference/fix_dart/`, `reference/params/koach_params_d1.json`, chemins de même longueur) : sans elles, la
  régénération des fixtures aurait cassé le contrôle Dart avant le portage. KM2c1 repointe ces tests vers
  `reference/fixtures/` (14 fixtures) et `params/koach_params_v1.json`, puis supprime les copies. C'est la seule
  raison de `kalis_bench` 0.4.1.
- `Memoire.barres` double `charges_reussies` (mêmes valeurs) : fusion possible au portage.

## 8. Relecture, contrôle, budget

- Relecture indépendante du diff (sous-agent Opus) : 2 bloquants et 4 majeurs, tous corrigés et testés (schéma
  nouveau sans barre récente un jour gelé ; paliers au-delà de la borne de séance ; série demandée avant la
  première ; test xRM le jour d'épreuve ; dispersion appliquée à tous les horizons ; bornes d'import), 10 mineurs
  traités ou déclarés (`CHANGEMENTS_1_0_2.md` § F). La campagne et la recherche adversariale finales ont été
  refaites après ces corrections.
- Références vérifiées par un sous-agent Opus (existence, contenu, portée) avant d'entrer dans `SOURCES.md`.
- Pas de SDK Dart dans la session : campagnes Python et témoin Dart exécutés sur la CI (`claude/ci-cp-a` et
  `claude/ci-cp-b`, aucun autre lot moteur en cours), par des commits « KM1c2 contrôle (dev) » à arbre réduit.
- Sous-agents sur Opus ; sauvegardes sur `cp-sauvegardes/KM1c2`. La clé des références n'a pas été utilisée (aucune
  référence privée nécessaire à ce lot).
