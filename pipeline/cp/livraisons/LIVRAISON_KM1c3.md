# Livraison KM1c3 — « KM1 correction 3 » : estimation sous notes non fiables, référence Koach 1.0.3

Lot KM1c3 du pipeline CP (méthode Koach, `CAHIER_KM.md`, décisions C13.13.2, C17.7, C17.8.2, C17.9), voie A, session Fable 5.1 effort maximal, le 15/10/2026 de 19:09 à 02:40 (16/10) UTC. Prompt : `prompts/KM1c3.txt` ; contexte : `LANCEMENTS.md`, section KM1c3. Base : `moteurs` e502e963 (référence 1.0.2, `kalis_adapt` 1.0.1). Lot sans panel ni relecture documentée (C13.3) ; validation automatique par le pilotage.

**En une phrase** : la référence Python de Koach passe en 1.0.3 : chaque athlète reçoit un indicateur bayésien de la fiabilité de ses notes (bruit des notes contre la population, part des séries non notées, oubli), qui n'élargit que l'incertitude de ses capacités (jamais la moyenne) et rend l'ouverture des tentatives prudente par les barres prouvées quand ses notes ne sont pas fiables ; un athlète aux notes fiables garde les prescriptions de 1.0.2. Sur les cinq jeux d'adversaires connus, le jour J moyen monte de 0,866 à 0,886 (sous le plancher : 8 → 4 cas) (recherche neuve de KM1c2 : 17/24, 0,810 → 22/24, 0,876), le banc ne bouge pas (critère 6 : 0,9450 → 0,9449), la sécurité reste à 0 violation ; le critère 7 bis reste tenu sur le jeu KM1 seulement : sur b300, b600 et la recherche neuve de KM1c2 il manque un cas (un zéro isolé d'ouverture par jeu, dont deux préexistants), sur b3000 trois cas (dont un préexistant de sous-estimation), et la recherche neuve contre 1.0.3 donne 19/24 (KM1c2 : 17/24, 6 sous le plancher). Les règles après échec sont mesurées et tranchées (règle de 0.3.1 rétablie ; barre suivante après un échec hors compétition), `defaut_modele_sd` a sa borne basse, et le rejeu du journal réel donne la fiabilité des notes du propriétaire (κ = 1 aujourd'hui).

## 1. Livré

| Élément | Où | Contenu |
| --- | --- | --- |
| Référence Koach 1.0.3 | `moteurs` 2d3a5766, `packages/kalis_adapt/reference/` | `koach/modele.py` (classe `Fiabilite`, κ), `seance.py` (échelle des tentatives, palier et marge, barre suivante après un échec, règle d'échec non prévu, prudence des séries lourdes, montée), `planification.py` (tirages), `rupture.py` (bornes, figées), `moteur.py` (`posterior`), `rejeu/walk_forward.py` (section D) ; `VERSION = '1.0.3-ref.1'` |
| Paramètres | `params/koach_params_v1.json` | `1.0.3-ref.1`, 338 clés (16 nouvelles, aucune valeur existante changée), SHA-256 `d129a4e9422b90bfa0aa9034770c57ea698b49ab92c0e8dc0df703bd37231aa0` |
| Fixtures de parité | `fixtures/` | les 14 régénérées, plus `moteur_12.json` (notes peu fiables, κ jusqu'à 1,4, test 1RM hors compétition) : 15 |
| Liste exacte des changements | `CHANGEMENTS_1_0_3.md` | sections A à H : indicateur, tentatives, règles après échec, import, rejeu, banc et tests, mesures finales, portage |
| Contrat | `CONTRAT_1_0.md` | note datée du 15/10/2026 ; § 5.13 nouveau ; § 3.4, 4.3, 6.3, 6.5, 7.2 à 7.4, 8.1, 9.6 à jour |
| Sources | `SOURCES.md` | une ligne par clé nouvelle (choix raisonné dit comme tel, mesure du banc, règle de 0.3.1) ; règles de compétition vérifiées |
| Portage | `PORTAGE_DART.md` | section « Delta 1.0.2 → 1.0.3 (lot KM2c2) » |
| Mesures | `donnees/criteres_km1c3.json`, `donnees/adversaires_km1c3.json`, `donnees/adversaires_km1c3_temoin.json.gz`, `donnees/comparaison_adversaires_km1c3*.json`, `donnees/rejeu_journal_agregats_km1c3.json` | campagne six graines, recherche adversariale neuve et témoin, comparaisons appariées des six jeux, rejeu du journal réel (agrégats) |
| Tests Dart | `kalis_adapt/test/` (5 fichiers), `reference/fix_dart/`, `reference/params/koach_params_d2.json` | copies figées de 1.0.2 lues par les tests de `kalis_adapt` 1.0.1 jusqu'au portage KM2c2 ; `kalis_bench` non touché |

Le code Dart de `kalis_adapt` (`lib/`) n'est pas touché : `kalis_adapt` reste 1.0.1 (Koach 1.0.2) jusqu'au portage KM2c2. L'API et le schéma du journal du contrat 1.0 ne changent pas ; `posterior()` gagne la clé `fiabilite`.

Contrôle complet (`claude/ci-cp-a`) : run 38831793524, vert. Tests Python de la référence : 261 verts (16 nouveaux dans `test_fiabilite.py`, 3 dans `test_rupture.py`, 1 dans `test_rejeu.py` ; `test_documents` vérifie l'empreinte du fichier de paramètres) ; `fixtures/generer.py --verifier` : à jour.

## 2. Ce qui change dans la méthode (points 1 à 4 du prompt)

### 2.1 Fiabilité des notes (point 1)

Cause mesurée : sur les 543 ouvertures de jour J des cinq jeux d'adversaires connus (états capturés à l'ouverture), 14 des 17 mouvements finis à zéro avaient une estimation à plus de 4 % au-dessus de la vérité ; la part de ces estimations passe de 7 % chez les athlètes aux notes fiables et toutes notées à 16-18 % chez ceux dont le bruit des notes est ≥ 1 ou qui ne notent pas une série sur trois. Les notes ouvertes contredites (« 4 en réserve ou plus » sur un simple à 95 % du maximum) ne nourrissaient pas `bruit_rir`.

Indicateur (contrat § 5.13) : grille a posteriori sur ln φ (facteur de variance du bruit des notes de l'athlète contre le bruit de population, 13 points de 1/8 à 8, a priori ln φ ~ N(0 ; 0,5²), vraisemblance de la catégorie de chaque note perçue, ouvertes comprises, avec la queue lourde du filtre), part des séries de force faites sans note (Beta(1, 4)), oubli λ = 0,98 (≈ 50 séries) ; mêmes grilles par schéma (lourd ≤ 5 répétitions, léger), rapportées. κ² = 1 + 1,0·(E[φ] − 1,133)⁺ + 12·(ρ − 0,2)⁺², κ ≤ 2 : zone morte aux moyennes a priori, donc κ = 1 exactement pour un athlète au moins aussi fiable que l'a priori. κ multiplie l'écart-type de `capacite` et de `capacite_du_jour` (hors `brut`) et les lignes des capacités dans les tirages du jumeau ; la moyenne de l'état est identique avec ou sans (testé). Conséquences voulues : intervalle publié plus large, vrai test déclenché plus tôt (`_mesure_utile`), contrôle dual calibré plus tard, P(réussite) du jumeau plus basse — pour les athlètes aux notes peu fiables seulement. Corrélation de l'indicateur avec le bruit vrai des 448 saisons adversariales : 0,54 (ln φ 0,58), contre 0,35 pour `bruit_rir`.

Coefficients mesurés (SOURCES.md) sur les 543 ouvertures : la part des estimations au-dessus de la vérité de plus de 1,645 σ passe, avec κ, de 4,5 % à 0,6 % pour φ ≥ 1,5 et de 6,0 % à 2,7 % pour ρ ≥ 0,3, sans changer les athlètes fiables (1,2 %).

### 2.2 Prudence ciblée aux tentatives et aux séries lourdes (point 2)

- **L'ouverture au quantile élargi n'est pas retenue** (mesurée) : hors ligne (884 ouvertures, règle rejouée), σ·κ au quantile 0,95 abaisse l'ouverture de 5 à 9 % chez tout athlète bruité (jour J des adversaires −0,009) sans éviter un seul échec d'ouverture (17 → 17) ; en simulation complète sur le jeu b3000 : jour J −0,033, 7 bis 20/24 → 18/24. Les échecs d'ouverture sont des biais (estimation trop haute), pas une variance. L'échelle des tentatives lit donc l'écart-type brut.
- **Retenu** : chez un athlète dont les notes sont peu fiables (κ > 1), le palier accordé par la note d'une barre est réduit (× max(0 ; 1 − 3(κ − 1))) et chaque barre réussie des 42 jours ne vaut que (1 − marge) de sa charge, marge = min(5 % ; 10 %·(κ − 1)) : l'estimation n'est pas une preuve et une barre réussie ne prouve le maximum d'aujourd'hui qu'à la variation de jour près. Hors ligne (états capturés avec l'indicateur final ; les choix ont été faits sur la capture d'avant relecture, dont `CHANGEMENTS_1_0_3.md` § B et `SOURCES.md` citent les chiffres — 17 → 7, +0,017 —, et revérifiés ici) : échecs d'ouverture 17 → 6, jour J des adversaires +0,015, banc −0,0001. Variantes écartées : marge fixe 2,5 % (+0,016, équivalente ; écartée pour la continuité en κ = 1) ou 5 % (+0,013, 4 échecs, banc −0,004), pente 0,15 (+0,014), palier réduit seul (0,000), barres à la limite seules à 97,5 % (+0,004, 14 échecs), part 0,91/κ (−0,075 : ouverture 8 % plus basse pour tout athlète bruité), prudence uniforme P ≥ 0,975 (17 échecs, −0,005 ; KM1c2 : 0,9412 → 0,9387 au banc complet) ou 0,99 (−0,013).
- **Séries lourdes** : prudence de plus `prudence_charge_fiabilite`·(κ − 1) écarts-types (≤ 5 répétitions), mesurée à 1,0 (X2, § 5) : jour J moyen des cinq jeux 0,884 contre 0,886 (b3000 +0,010, b300 −0,007, KM1c2 −0,009), banc graine 0 0,9580 contre 0,9584 ; laissée à 0 (les cas se déplacent d'un jeu à l'autre sans gain net ; l'écart-type élargi agit déjà par `prudence_charge`).
- **Coût de la prudence ciblée contre la prudence uniforme** : sur le banc complet (critère 6, 4 320 saisons, 516 appariées), 0,9450 → 0,9449 (écart apparié à 0.3.1 +0,0105 ± 0,0016) : nul ; la prudence uniforme P ≥ 0,975 coûtait 0,0025 en KM1c2 (0,9412 → 0,9387) et n'évite aucun échec d'ouverture (§ 5). La prudence ciblée ne touche que les athlètes à κ > 1 (2 à 4 % des saisons du banc, un tiers des adversaires).

### 2.3 Règles après un échec (point 3)

- **A8.2, barre gardée après un échec** : mesurée avec, sans et conditionnée à la fiabilité (hors ligne : sans = conditionnée, +0,027 de jour J des adversaires, 2,5 / 5 / 7,5 % équivalents). Tranché : en semaine de compétition la même barre (principe de la barre montante et progression d'au moins 2,5 kg : règles fondées sur l'IPF, vérifiées) ; hors compétition (test 1RM à l'entraînement) la barre suivante suit l'estimation mise à jour par l'échec, au plus 5 % sous la barre ratée. Les jours J du banc sont des semaines `competition` : la règle n'y joue pas.
- **Échec non prévu, règle de 0.3.1** (aucune hausse par rapport à la dernière séance de l'exercice, quel que soit le schéma) : mesurée avec (1), sans (0) et conditionnée (2) en simulation complète : jour J identique à 0,002 près sur les cinq jeux et le banc. Tranché : **rétablie pour tous** (garde-fou du couple validé, coût nul).

### 2.4 Import (point 4, m3 de KM2c1)

`mesure.defaut_modele_sd` ∈ [0,001 ; 0,1] (cohérent avec la règle des clés `_sd`), bornes des clés nouvelles, grille et a priori de la fiabilité figés à l'import, `appliquer_parametres` repointe l'indicateur.

## 3. Critères du cahier, avant (1.0.2) et après (1.0.3), six graines

Même matrice que KM1c2 : 27 profils, tous leurs scénarios, vérités a, b et c, graines 0 à 5, 4 320 saisons, Koach complet (planification à 1 000 trajectoires, surveillance, contrôle dual, adhérence), 0 saison plantée. Avant : `donnees/criteres_km1c2.json`. Après : `donnees/criteres_km1c3.json` (partie 1/2 sur la CI, run 38814063895 ; partie 2/2 en local ; assemblage).

| # | Critère | Seuil | 1.0.2 | 1.0.3 | Témoin 0.3.1 | Tenu |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM au rang 6 | < 3 % | 3,92 % | 3,94 % | 7,11 % | non (écart accepté C13.11 ; +0,02 point, sous l'erreur type 0,07) |
| 2 | Mauvais jour isolé (apparié) | < 1 % | 0,91 % | 0,87 % | — | oui |
| 3 | Convergence sous 3 % (séances) | ≤ témoin | 5,28 | 5,28 | 11,98 | oui |
| 4 | Couverture de l'intervalle à 90 % | 88-92 % | 89,96 % | 90,21 % | 83,4 % | oui |
| 5 | Calibration de P(réussite), C13.13.1 | biais ± 5 points ; écart max < médiane d'un modèle parfait | +0,2 ; 16,8 contre 21,2 | −0,6 ; 24,4 contre 21,3 (d5, n = 37 : 54 % prévus, 78 % observés ; un modèle parfait fait au moins autant dans 35 % des tirages) | — | biais oui ; écart max non (était oui : 16,8) |
| 6 | Jour J (meilleure barre / maximum) | ≥ témoin 0,9324 | 0,9450 | 0,9449 | 0,9324 | oui |
| 7 | Pire cas adversarial | ≥ témoin | 0,499 | 0,555 (recherche neuve de 3 000 saisons contre 1.0.3) | 0,0 | tenu (et mieux que 1.0.2) |
| 7 bis | Adversaires appariés (C13.12) | ≥ 90 % à témoin − 0,03 ; aucun sous témoin − 0,10 | 17/24 sur la recherche neuve, 6 sous le plancher | KM1 24/24 ; b300, b600, KM1c2 22/24 avec un cas sous le plancher chacun ; b3000 21/24, 1 ; recherche neuve 19/24, 2 | — | tenu sur KM1 seulement ; non tenu sur les autres jeux (§ 4) |
| 8 | Violations de sécurité | 0 | 0 | 0 | — | oui |
| 9 | Parité Python / Dart | ≤ 1e-9 | tenue (1.0.2) | à refaire au portage KM2c2 (15 fixtures prêtes) | — | — |
| 10 | Rejeu du journal réel | bascule | — | rapporté (§ 6) | — | — |
| 11 | Temps | ≤ 10 s ; ≤ 50 ms | 0,44 s ; 2,8 ms (Python) | 0,56 s ; 7,3 ms (Python) | — | oui |

Bilan : tenus 2, 3, 4, 6, 7, 8, 11 et le biais du critère 5 ; critère 1 écart accepté (C13.11), 3,94 % contre 3,92 % : +0,02 point (3,918 → 3,939), sous l'erreur type de la mesure (0,07 point), par vérité a 2,99 / b 5,14 / c 3,68 % ; critère 2 0,91 → 0,87 % et pire cas 5,0 → 3,7 % ; critère 4 89,96 → 90,21 % (vérité a 94,1, b 88,2, c 88,3 %). **Critère 5 (C13.13.1)** : biais −0,6 point dans ± 5 (IC 90 % par grappes [−8,5 ; +7,8]) ; écart maximal par décile 24,4 points contre une médiane de 21,3 pour un modèle parfait aux issues liées : **non tenu à la lettre, alors qu'il l'était en KM1c2 (16,8)**. L'écart vient du même décile d5 (P prévue 50-60 %, 37 cas liés par grappes) : 29 réussites sur 37 contre 27 sur 38 en 1.0.2, et un modèle parfaitement calibré fait au moins 24,4 points dans 35 % des tirages (73 % pour 16,8) ; les autres déciles s'améliorent (d1 7,8 → 3,8, d2 15,5 → 9,4, d7 25,6 → 18,9), l'erreur pondérée sur tous les cas passe de 2,14 à 2,05 points et l'écart maximal sur les 5 796 cas de 26,6 à 22,0 points. Cause plausible, non prouvée à n = 37 : la P(réussite) du jumeau baisse pour les athlètes à κ > 1 (voulu), ce qui fait descendre dans d5 des cibles qu'ils atteignent quand même. Signalé au pilotage (§ 8) : recul formel d'un critère tenu, dans le bruit de la mesure. Critère 11 : série observée 7,3 ms au pire (2,8 en 1.0.2 : la vraisemblance de φ est calculée à chaque note, 13 points de grille × catégories ; 1,4 ms en médiane), replanification 0,56 s (0,44) — loin des seuils, et le Dart de KM2c1 est 10 fois plus rapide que le Python.

## 4. Adversaires appariés (critère 7 bis), six jeux

Koach 1.0.3 rejoué en Python sans extension (`PolitiqueKoach()`), témoin 0.3.1 rejoué en Dart (`bin/km1.dart --outils-seuls`, stocké pour les cinq jeux connus, calculé sur la CI pour la recherche neuve) ; 24 adversaires appariés par jeu.

| Jeu d'adversaires | 1.0.2 : ≥ témoin − 0,03 ; sous témoin − 0,10 ; jour J moyen | 1.0.3 : ≥ témoin − 0,03 | 1.0.3 : sous témoin − 0,10 | 1.0.3 : pire écart | 1.0.3 : jour J moyen | 7 bis |
| --- | --- | --- | --- | --- | --- | --- |
| KM1 (300 contre 1.0) | 24 (100 %) ; 0 ; 0,896 | 24 (100 %) | 0 | −0,018 | 0,891 | tenu |
| KM2 b300 (contre 1.0.1) | 23 (96 %) ; 0 ; 0,897 | 22 (92 %) | 1 (adv-051f1dee, −0,143) | −0,143 | 0,883 | non tenu (un cas) |
| KM2 complet b600 | 22 (92 %) ; 0 ; 0,875 | 22 (92 %) | 1 (adv-a0dd8069, −0,103 ; était −0,099) | −0,103 | 0,884 | non tenu (un cas) |
| KM2 b3000 | 20 (83 %) ; 2 ; 0,855 | 21 (88 %) | 1 (adv-29523095, −0,234 ; était −0,226) | −0,234 | 0,894 | non tenu |
| Recherche neuve de KM1c2 (3 000 contre 1.0.2) | 17 (71 %) ; 6 ; 0,810 | 22 (92 %) | 1 (adv-5e2b8ac3, −0,145 ; était −0,154) | −0,145 | 0,876 | non tenu (un cas) |
| **Recherche neuve de KM1c3 (3 000 contre 1.0.3)** | — | 19 (79 %) | 2 (adv-5e2b8ac3 −0,145 ; adv-7c601acb −0,134) + 1 excusé (adv-449d92ef −0,150, témoin avec 3 violations) | −0,150 | 0,817 (témoin 0,621) | non tenu |

Lecture. Sur les cinq jeux connus, le jour J moyen des adversaires passe de 0,866 à 0,886 (+0,019) et le nombre de cas sous le plancher de 8 à 4 ; 1.0.3 règle cinq des six cas sous le plancher de la recherche neuve de KM1c2 (adv-1c0774cf 0,799 → 0,970, adv-049b3624 0,641 → 0,970, adv-8b8d24c6 0,765 → 0,941, adv-08722fc3 0,760 → 0,913, adv-a75eb4c8 0,795 → 0,946) et les deux de b3000 n'en sont plus qu'un. Les quatre cas restants : un seul est nouveau (adv-051f1dee, powerlifter aux notes bruitées, graine 3 : un zéro isolé au squat, 185 kg ouverts pour un maximum du jour de 183,2 — estimation +2,6 %, mauvais jour −2,3 % —, trois essais à la même barre en semaine de compétition ; les deux autres graines 0,91 et 0,96, et la graine 2 ouvre à 172,5 pour 174,4) ; adv-a0dd8069 et adv-5e2b8ac3 (streetlifting, vérité c) avaient déjà un zéro isolé sur un mouvement d'une graine en 1.0.2 (−0,099 et −0,154, écarts inchangés à 0,01 près) ; adv-29523095 (powerlifter, vérité b, −0,226 en 1.0.2) est une sous-estimation d'un athlète qui progresse vite (barres réussies à 0,66-0,77 du maximum, témoin lui-même à 0,75), pas un problème de notes. Le critère 7 bis est donc tenu sur KM1, tenu à un cas près (un zéro isolé d'ouverture par jeu) sur b300, b600 et la recherche neuve de KM1c2, et non tenu sur b3000 (21/24 et un cas préexistant). La recherche neuve contre 1.0.3 (3 000 saisons, 88 adversaires dont 16 déjà connus de KM1c2) donne 19/24 à témoin − 0,03, deux cas sous le plancher non excusés (adv-5e2b8ac3, déjà connu ; adv-7c601acb, streetlifting vérité c : un zéro isolé sur un mouvement d'une graine, 0,826 en moyenne) et un excusé (adv-449d92ef, le témoin y commet 3 violations) ; les trois autres cas entre −0,03 et −0,10 sont des powerlifters ou streetlifters de vérité b aux notes très bruitées (bruit 1,8 à 2,5, un tiers des séries non notées) que les deux moteurs sous-estiment (témoin 0,74 à 0,81). Le pire adversaire trouvé vaut 0,555 (KM1c2 : 0,499 contre 1.0.2), et la recherche neuve contre 1.0.3 fait mieux (19/24, 2 sous le plancher, 0,817) que celle de KM1c2 contre 1.0.2 (17/24, 6, 0,810) — alors qu'elle cherche contre le moteur corrigé.

## 5. Mesures qui ont décidé (points 2 et 3), état capturé et simulation complète

Deux outils, tous deux dans le scratchpad de la session (non livrés, reproductibles depuis `banc/`) : (a) **état capturé** — les 543 ouvertures de jour J des cinq jeux connus et 341 du banc (graine 0) sont rejouées hors ligne avec l'état du modèle à l'index 0 de `_tentative` (moyenne, écart-type, barres prouvées et ratées des 42 jours, φ, ρ de l'indicateur final), ce qui mesure une règle d'ouverture et son échelle de trois tentatives en quelques secondes (la règle de 1.0.2 reproduit exactement les 543 ouvertures capturées en 1.0.2) ; (b) **simulation complète** — les cinq jeux (7 bis contre le témoin stocké) et le banc graine 0 sans extension (jour J, couverture, erreur), 10 à 25 min par variante sur 2 cœurs. Les critères officiels (§ 3) viennent de la campagne Koach complet. Le tableau ci-dessous est la remesure sur la capture finale (indicateur d'après relecture) des règles choisies sur la capture d'avant relecture ; les ordres de grandeur et le classement des règles sont les mêmes.

État capturé (543 ouvertures d'adversaires : jour J moyen de l'ouverture rejouée, échecs d'ouverture ; banc : écart) :

| Règle d'ouverture (écart au jour J moyen de 1.0.2 : adversaires 0,8676, banc 0,9516) | Jour J adversaires | Échecs d'ouverture (sur 17) | Banc |
| --- | --- | --- | --- |
| σ·κ au quantile 0,95 (V1) | −0,009 | 17 | 0,000 |
| prudence uniforme P ≥ 0,975 (sans κ) ; P ≥ 0,99 | −0,005 ; −0,013 | 17 ; 17 | −0,0001 ; −0,0004 |
| part 0,91 / κ | −0,075 | 2 | −0,016 |
| palier × (1 − 3(κ − 1)) seul | 0,000 | 17 | 0,000 |
| palier réduit + barres à la limite ou non notées à 97,5 % | +0,004 | 14 | −0,0005 |
| palier réduit + marge fixe 2,5 % ; 5 % sur toutes les barres prouvées | +0,016 ; +0,013 | 6 ; 4 | −0,0012 ; −0,0038 |
| **palier réduit + marge min(5 % ; 10 %(κ − 1)) sur toutes les barres prouvées (retenue)** | **+0,015** | **6** | **−0,0001** |
| barre suivante après un échec (≤ 5 % sous ; 2,5 % ; 7,5 % ; conditionnée à κ > 1) | +0,027 ; +0,026 ; +0,027 ; +0,027 | 17 | +0,0004 |
| retenue + barre suivante après un échec | +0,023 | 6 | +0,0003 |

Simulation complète (cinq jeux : tenus/24, cas sous le plancher, jour J moyen ; banc graine 0 : jour J) :

| Variante | KM1 | b300 | b600 | b3000 | KM1c2 | Banc |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0.2 (reproduit KM1c2) | 24, 0, 0,896 | 23, 0, 0,897 | 22, 0, 0,875 | 20, 2, 0,855 | 17, 6, 0,810 | 0,9577 |
| V1 : κ sur σ à l'ouverture seul (a = 1, c = 12) | 24, 0, 0,890 | 22, 1, 0,884 | 22, 1, 0,881 | 18, 4, 0,819 | 18, 5, 0,814 | 0,9603 |
| X1 : règle retenue, avant relecture | 24, 0, 0,891 | 22, 1, 0,883 | 22, 1, 0,882 | 21, 1, 0,893 | 21, 2, 0,870 | 0,9597 |
| X3 = X1 + règle de 0.3.1 (échec non prévu, tout schéma) | 24, 0, 0,891 | 22, 1, 0,883 | 22, 1, 0,882 | 21, 1, 0,893 | 21, 2, 0,868 | 0,9597 |
| X4 = X1 + règle de 0.3.1 conditionnée à κ > 1 | 24, 0, 0,891 | 22, 1, 0,883 | 22, 1, 0,882 | 21, 1, 0,893 | 21, 2, 0,868 | — |
| **1.0.3 final (après relecture : queue lourde, échauffements, plafond κ = 2)** | **24, 0, 0,891** | **22, 1, 0,883** | **22, 1, 0,884** | **21, 1, 0,894** | **22, 1, 0,876** | **0,9584** |
| X2 : 1.0.3 + prudence des séries lourdes 1,0·(κ − 1) σ | 24, 0, 0,891 | 22, 1, 0,876 | 22, 1, 0,884 | 22, 0, 0,904 | 21, 2, 0,867 | 0,9580 |

Lecture : l'élargissement seul (V1) abaisse l'ouverture de 5 à 9 % chez tout athlète bruité sans sauver les cas à +7 % d'erreur (b3000 : 4 cas sous le plancher) ; la prudence par les barres prouvées (X1) sauve les cas de la recherche neuve de KM1c2 sans coût sur les athlètes fiables ; la règle de 0.3.1 ne coûte rien (X3 = X1 à 0,002 près, X4 = X3) ; la prudence des séries lourdes (X2) déplace les cas d'un jeu à l'autre (b3000 +0,010, b300 −0,007, KM1c2 −0,009 ; moyenne des cinq 0,884 contre 0,886) : laissée à 0. Le banc graine 0 sans extension du code final : 0,9584 (1.0.2 : 0,9577), couverture 0,8725, erreur 0,0393 ; κ > 1,05 dans 2 % des saisons (κ max 1,14).

## 6. Rejeu du journal réel du propriétaire (point 5, part « rejeu » du critère 10)

Journal déchiffré sous `/tmp` (clé par fichier en mode 600), export du 09/10/2026 (39 séances terminées, 896 séries ; depuis S12 : 200 séries validées, 101 notées), programme et annotations de l'application, correspondance des noms reconstruite (78 lignes sur 79, « BILAN » exclue). Agrégats seulement : `donnees/rejeu_journal_agregats_km1c3.json`.

- **Estimation (A, une séance d'avance, depuis S12)** : 38 séries notées, erreur moyenne 4,6 % (médiane 2,5 %), biais −0,3 %, couverture 97,4 % — identiques à 1.0.2 : κ = 1 en fin de journal, le moteur n'a rien changé pour lui. Critère 10 (bascule) : 100 séries notées non atteintes dans cet export (38) ; à refaire sur un export neuf juste avant la bascule (C13.11.3).
- **Fiabilité des notes du propriétaire** : en fin de journal E[φ] = 0,91 (P(φ ≥ 2) = 3 %), 182 notes de force, part non notée 18,6 % (séries lourdes 35 %, légères 17 %) : ses notes sont au moins aussi fiables que l'a priori, κ = 1,000 — ses prescriptions avec 1.0.3 sont celles de 1.0.2 (palier d'ouverture et séries lourdes : écart 0,0 % sur ses 4 mouvements principaux chargés). À l'entrée de S12, 69 % de ses séries n'étaient pas notées : κ valait 1,97 — avec 1.0.3 à cette date, une tentative aurait été ouverte sous le palier des barres prouvées (marge 5 %, palier nul) et un vrai test déclenché plus tôt ; depuis S12 il note la plupart de ses séries et l'oubli l'a réhabilité en quatre semaines.
- Calibration des notes (C, 167 notes) : notes ouvertes prévues 43,7 % contre 20,4 % observées, écart moyen note − prévision −2,1 répétitions : il dit ses séries plus dures que le moteur ne les prévoit (biais appris par BA et BP, pas une dispersion : φ < 1).

## 7. Sécurité

0 violation de sécurité sur les 4 320 saisons de la campagne et sur les six jeux d'adversaires (aucune aggravation, aucune poussée de douleur, aucune hausse interdite ; validateur : rien d'introduit). Les règles ajoutées vont toutes dans le sens prudent (palier réduit, marge, règle de 0.3.1 rétablie) ; la barre suivante après un échec hors compétition ne dépasse jamais la barre ratée.

## 8. Ce qui reste et recommandations au pilotage (C8)

- **Critère 7 bis** : tenu sur KM1 seulement ; sur les cinq jeux connus la moyenne monte de 0,866 à 0,886 et les cas sous le plancher tombent de 8 à 4 (un nouveau, trois préexistants) ; la recherche neuve contre 1.0.3 donne 19/24 (KM1c2 : 17/24, 6 sous le plancher). Les cas restants sont (i) des zéros isolés d'ouverture en semaine de compétition : estimation +2 à 3 %, mauvais jour −2 %, barre gardée par A8.2 (le seul levier est l'ouverture, et toutes les variantes uniformes mesurées coûtent plus qu'elles ne rapportent) ; (ii) des sous-estimations d'athlètes à progression rapide aux notes très bruitées, que le témoin sous-estime aussi. Recommandation (C8) : accepter cet état comme tenue du point C13.13.2 (« estimation sous notes non fiables »), suivre l'indicateur ; une passe sur les zéros isolés ne vaut que si une règle d'ouverture non uniforme est trouvée (par exemple un indicateur de mauvais jour à l'échauffement), hors du périmètre de ce lot.
- **Critère 5** : recul formel (16,8 → 24,4 points, biais −0,6) dans le bruit de la mesure (§ 3). Recommandation : trancher si le critère 5 de C13.13.1 doit lire la médiane du modèle parfait ou son quantile 90 % (32,8 points), puisque la valeur mesurée bouge de 8 points pour 2 cas ; ou laisser tel quel et le remesurer à KM2c2 (Dart, mêmes chiffres attendus).
- **Critère 1** : 3,94 % (écart accepté C13.11), +0,02 point sous l'erreur type : pas un recul mesurable, signalé.
- **Critère 10 (bascule)** : l'export du 09/10/2026 n'a que 38 séries notées depuis S12 (100 demandées) ; à refaire sur un export neuf juste avant KM3 ; la section D du rejeu (fiabilité des notes et prescriptions) est prête.
- **Pour KM2c2** : porter le delta (§ 9), régénérer les 15 fixtures en Dart, repointer les tests et supprimer les copies figées ; temps par série à vérifier (vraisemblance de φ par note).
- **Pour KM3** : `posterior()['fiabilite']` est disponible pour un texte à l'athlète (« tes notes sont fiables / peu fiables, κ ») ; aucun écran n'est demandé par ce lot.
- **Recommandation (C8)** : valider 1.0.3 comme référence et lancer KM2c2 ; trancher les points critère 5 et 7 bis ci-dessus.

## 9. Pour KM2c2 (portage Dart du delta)

`PORTAGE_DART.md`, section « Delta 1.0.2 → 1.0.3 » ; `CHANGEMENTS_1_0_3.md` § H. Fichiers Dart : `modele` (classe `Fiabilite`, `_serie_force`, `capacite`, `capacite_du_jour`), `planification` (`tirer`), `seance` (`proba_reussite`, `_tentative`, `_palier_barres`, `_cible_charge`, `_bornes_hausse`, `_rampe`), `rupture` (bornes, figées, `appliquer_parametres`), `moteur` (`posterior`) ; asset `koach_params_1_0_3.json` ; tests repointés sur `reference/fixtures/` (15) et `koach_params_v1.json`, copies figées supprimées.

## 10. Relecture, contrôle, budget

- Relecture indépendante du diff (sous-agent Opus) : 2 bloquants et 4 majeurs corrigés et testés (statistiques du rejeu sous 3 exercices ; surcharge d'instance ; queue lourde du filtre dans la vraisemblance de φ — chez un athlète au bruit exact de population κ > 1 dans 40 % des cas avant, 20 % après ; échauffements comptés comme non notés ; κ non borné ; textes provisoires), 10 mineurs traités ou déclarés (`CHANGEMENTS_1_0_3.md` § F). Campagne, recherche adversariale et comparaisons refaites après ces corrections.
- Références : règles de compétition (barre montante) vérifiées sur un texte fondé sur l'IPF ; aucune nouvelle valeur chiffrée tirée de la littérature (les coefficients sont des mesures du banc ou des choix raisonnés dits comme tels).
- Pas de SDK Dart dans la session : campagne partie 1/2 et témoin Dart sur la CI (`claude/ci-cp-a`, commits « KM1c3 contrôle (dev) » à arbre réduit), partie 2/2, recherche adversariale et comparaisons en local (2 cœurs).
- `add_repo` absent de la session ; accès en écriture vérifié par `git push --dry-run` puis par le push de la ligne « en cours ». Sous-agents sur Opus ; sauvegardes sur `cp-sauvegardes/KM1c3` (dernière : fin de lot). Session interrompue une fois vers 23:20 UTC (processus tués, fichiers intacts) : campagne relancée sur son cache, aucune mesure perdue.
