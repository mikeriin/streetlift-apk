# Livraison KM4 — Koach 1.0.6 : retour gradué priorisé, jamais de principal retiré sans douleur (`kalis_adapt` 1.0.5, `kalis_bench` 0.5.7)

Lot KM4 du pipeline CP (lot de méthode Koach ; décisions C13.3, C17.17.3, C17.33, C17.37 ; prompt `prompts/KM4.txt`), voie A, session Opus 5.5 effort maximal, du 19/10/2026 11:04 UTC au 20/10/2026 09:07 UTC. Accès en écriture vérifié par `git push --dry-run` (l'outil `add_repo` n'est pas dans la session) puis par le push de la ligne « en cours ». Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : compilation, analyse, tests et campagnes Dart sur la CI (`claude/ci-cp-a`, commits « KM4 contrôle (dev) ») ; formatage Dart par une branche de formatage à distance (`claude/fmt-km4`). Aucune donnée réelle, aucun déchiffrement (C17.33) ; clé des références non lue. Lot sans panel ni relecture documentée (C13.3). Sous-agents sur Opus (recherche des sources, port des tests Dart, relecture indépendante) ; sauvegardes sur `cp-sauvegardes/KM4`.

**En une phrase** : Koach 1.0.6 ne retire plus jamais un exercice principal par la rampe de volume sans douleur — sur les 90 600 saisons du banc, de **147 665 principaux retirés (1.0.5) à 0**, un principal réduit garde en moyenne 36 % de ses séries écrites au lieu de 7 %, les accessoires et les secondaires sont coupés avant lui — avec **0 violation du critère 7** en Dart et en Python (saisons identiques une à une) ; la répartition des coupes sur toute la semaine, écrite et mesurée, est **désactivée** parce qu'elle introduisait 40 constats de sécurité (une séance ensuite manquée compte à son écrit) : c'est la séance du jour qui paie d'abord, dans l'ordre accessoires → secondaires → principaux, et les séances restantes ne cèdent que pour garder le plancher des principaux.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.5 (Koach 1.0.6, `koachVersion` `1.0.6-ref.1`) | `etiquettes/kalis_adapt-v1.0.5` | référence Python (`reference/koach/seance.py`, `rupture.py`, paramètres `1.0.6-ref.1`, tests `test_km4_retour.py` 15, `test_securite_regles.py`, `test_campagne.py`, fixtures, `CHANGEMENTS_1_0_6.md`, `SOURCES.md`, note datée au contrat, `PORTAGE_DART.md`) ; portage Dart ligne pour ligne (`lib/src/koach/seance.dart`, `rupture.dart`, `parametres.dart`, `koach_textes.dart`) ; asset `assets/koach/koach_params_1_0_6.json` (347 clés, SHA-256 `4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a`) ; tests `test/koach_km4_retour_test.dart` (14), `koach_parametres_test.dart`, `koach_textes_test.dart` ; `CHANGELOG.md`, `CONTRAT.md` K.1/K.5, `docs/INTEGRATION_KM3.md` |
| `kalis_bench` | 0.5.7 | `etiquettes/kalis_bench-v0.5.7` | rôle des emplacements dans `reste_semaine` et les séances manquées ; mesure `rampe` par saison (`kmMesureRampe`), agrégat `rampe_principaux` (`tool/kr1_securite.py`) ; fixtures km2 régénérées ; `docs/CRITERES_KM4.md`, `docs/data/km4/` |

`kalis_core`, `kalis_plan` (0.4.2) inchangés. `moteurs` : 91d8ea70 (`etiquettes/kalis_adapt-v1.0.5`, `etiquettes/kalis_bench-v0.5.7`) ; contrôle complet `claude/ci-cp-a` : run 39378780707. Rien dans l'application (intégration : KB3).

## 2. Mécanisme avant / après

**1.0.5** (`_budgets_retour`, `_retour_gradue`) : limite de la semaine par groupe majeur (rampe +20 % ou +2 séries sur trois semaines, +30 % ou +4 sur deux) ; budget du jour = limite − réalisé − **tout l'écrit des séances restantes** ; coupes **dans l'ordre de la séance**, sans rôle, jusqu'à **0 = retrait**. Sur le banc (run A : Dart 1.0.4 = référence 1.0.5, avec la mesure ajoutée) : **147 665 principaux retirés par la rampe sans douleur** (126 688 séances) ; 4,27 % des séances avec un principal en ont un réduit ; un principal réduit garde en moyenne **7,0 %** de ses séries écrites (presque toujours retiré). C'est le constat du propriétaire (C17.37.1) à l'échelle du banc.

**1.0.6** (`CHANGEMENTS_1_0_6.md`, contrat § 8.3) :

1. `prescrire` en deux passes : `_item` sur toutes les lignes (douleur, bilan, coupure, surmenage, rampe du réalisé), puis le **plan du retour gradué de la semaine** (`_plan_retour`), puis retour gradué et vrai test ligne par ligne.
2. Plan : lignes = groupes majeurs (et total d'une semaine d'allègement) ; unités = lignes dures du jour (séries après `_item`) et des séances restantes (écrit) ; excès = réalisé + crédits − limite ; coupes une série à la fois, par étapes : (1) accessoires, gainage, conditionnement, mobilité… à 0 ; (2) secondaires et technique à 1 ; (3) principaux à leur **plancher** max(1, ⌈écrit × 0,5⌉) ; (4) secondaires à 0 ; (5) principaux à 1 — **jamais 0 sans douleur** ; dans une étape, l'unité qui garde la plus grande part de son écrit d'abord (prorata), à égalité la plus tardive.
3. **Ordre jour / semaine** (valeurs livrées : `retour_repartition_semaines` 0, `retour_emprunt_plancher` 1) : (1)-(3) sur la séance du jour, puis (1)-(3) sur les séances restantes (seulement pour garder les planchers du jour), puis (4) et (5), jour puis reste. La **répartition** sur toute la semaine (étapes sur toutes les séances à la fois, si aucune séance manquée dans les N dernières semaines) est écrite, testée (`retour_repartition_semaines` > 0) et **désactivée** (§ 4).
4. Principal tenu par la conduite sous douleur (raison de douleur, ou zone sensible qu'il provoque) : traité comme un secondaire (pas de plancher). Sans rôle : la première ligne dure créditée de la séance du jour est le principal ; une ligne d'une séance restante sans rôle n'est jamais coupée d'avance (relecture, M2).
5. Raison `koach.retour_gradue` : paramètres additifs `ecrites` et `douleur` ; texte « 3 séries au lieu de 6 sur … » ; texte de retrait neutre (« Je retire … aujourd'hui : pour …, le volume que la semaine permet est déjà pris »).
6. Contrat : champ additif `role` des items de `contexte['reste_semaine']` (et des séances manquées).

**Changement de programme** (point 4 du prompt) : la rampe reste mesurée sur le réalisé des semaines précédentes, sans règle de transition : priorité de rôle et planchers suffisent à ne plus vider les premières séances (scénario dédié ci-dessous). Une règle de transition sourcée n'existe pas (recherche : aucune source sur le passage à un programme plus volumineux ; § 3).

**Scénario dédié** (`test_scenario_c17_37_par_defaut`, Python et Dart ; données synthétiques) : athlète avancé, trois semaines d'un programme A (20 séries « chest »), puis un programme B de six séances par semaine en PPL (28 séries « chest », +40 %), séance de tirage en premier (muscle-up lesté 6, traction lestée 4, pull-over 3, face pull 3) : lundi servi **muscle-up lesté 4 sur 6, traction lestée 3 sur 4, pull-over retiré (accessoire), face pull 3** (aucun crédit chest) ; les cinq autres séances servies à leur écrit ; limite de la semaine tenue sur les quatorze groupes (chest 22,5 pour 24 ; triceps 19 pour 19,2). En 1.0.5, dès que l'écrit des séances de poussée dépassait le budget, muscle-up et traction tombaient à 0 (`test_scenario_c17_37_ancien_comportement_pour_memoire`).

## 3. Règles et sources

Recherche faite par un sous-agent Opus (WebSearch/WebFetch, références vérifiées ; détail dans `reference/SOURCES.md`, cinq références ajoutées) :

- **Plancher** `retour_plancher_principal` 0,5 (choix raisonné, cohérent avec) : affûtage efficace = volume réduit de 41 à 60 %, intensité gardée (Bosquet et al. 2007, MSSE 39(8):1358-1365) ; force maintenue avec une série par exercice et par semaine à intensité gardée (Bickel et al. 2011, MSSE 43(7):1177-1187 ; Spiering et al. 2021, JSCR 35(5):1449-1458) ; d'où « au moins la moitié, jamais moins d'une série, charge prescrite gardée ».
- **Ordre des coupes** (assistance d'abord, principal en dernier ; sans rôle, la première ligne est le principal) : priorité des exercices polyarticulaires et prioritaires (ACSM, Ratamess et al. 2009 ; Simão et al. 2012). Aucune source primaire ne dit explicitement « coupez l'assistance avant le mouvement principal » : déduction, dite comme telle.
- **Répartition** (`retour_repartition_semaines`) : aucune étude ne compare une réduction étalée à une réduction concentrée ; à volume égal la fréquence ne change ni l'hypertrophie (Schoenfeld, Grgic, Krieger 2019) ni la force (Ralston et al. 2018). La répartition est donc défendable sur le plan de l'entraînement ; elle est désactivée pour la sécurité mesurée (§ 4), pas pour une raison d'efficacité.
- **Rampe** (inchangée, règle de sécurité) : rapport aigu:chronique 0,8-1,3, risque au-delà de 1,5 (Gabbett 2016) ; > 30 % sur deux semaines (Nielsen et al. 2014) ; critique de l'ACWR (Impellizzeri et al. 2020) : garde-fou interne, jamais une prédiction affichée.

## 4. Critères avant / après

### 4.1 Sécurité et rampe sur les 90 600 saisons

| Mesure | Avant (1.0.5, run A, Dart) | 1.0.6 avec répartition (run B, Python) | **1.0.6 livré (run D, Dart)** | **1.0.6 livré (runs E + G, Python)** |
| --- | --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | **0** | **0** |
| **Critère 7** | 0 | **40** (28 saisons) | **0** | **0** |
| **Principal retiré par la rampe sans douleur** (critère C17.37) | **147 665** | 0 | **0** | **0** |
| Séances avec un principal réduit | 4,27 % | 2,52 % | 3,11 % | 3,11 % |
| Part servie d'un principal réduit (moyenne) | 7,0 % | 34,5 % | 36,2 % | 36,2 % |
| « Retour à l'écrit » (à part, C13.10.1) | 50 828 | 57 945 | 54 064 (+6,4 %) | 54 064 |
| Réalisée appariée (indicateur) | 238 906 | 242 810 | 243 277 (+1,8 %) | 243 277 |

**Répartition sur la semaine (première version du lot)** : la campagne Python (run B) a donné **40 constats « volume_trop_vite » introduits** (28 saisons, toutes `autres_10_contraintes_multiples`, graines 48 et 96, semaine 5, tous scénarios) : une coupe promise à une séance restante, ensuite manquée (taux de base du banc : 8 % des séances), ne tient pas — le validateur, comme Koach, compte une séance manquée à son volume **écrit**. Une répartition sûre contre des absences arbitraires est impossible (seule la réserve de l'écrit restant l'est) ; la condition d'assiduité (aucune séance manquée sur quatre semaines) ne suffit pas. D'où `retour_repartition_semaines` 0. L'échantillon local (302 saisons) montrait déjà le prix de la répartition en « retour à l'écrit » (42 → 95, contre 52 sans répartition).

**Variante d'emprunt** : sans répartition, deux façons de tenir le plancher d'un principal quand la séance du jour n'y suffit pas : P (`retour_emprunt_plancher` 1, livrée) coupe les séances restantes pour garder la moitié de l'écrit ; M (0) fait payer le jour jusqu'à une série par principal avant tout emprunt. Échantillon (302 saisons) : P sert aux principaux réduits 35 % de leur écrit, M 14 %, à « retour à l'écrit » égal (41 contre 43) ; campagne complète de P : 0 violation. La campagne Dart de M n'a pas tourné (parts sans SDK) : P est retenue sur ses mesures.

**Ce que coûtent les planchers** : « retour à l'écrit » +6,4 % (54 064 contre 50 828) — semaines où le plancher des principaux dépasse une limite abaissée par des semaines servies plus bas que l'écrit (douleur, bilan bas, coupure) ; publié à part par décision (C13.10.1), il dit honnêtement que Koach sert alors un peu plus que la rampe calculée sur ce passé abaissé, jamais plus que l'écrit. Réalisée appariée +1,8 %.

### 4.2 Critères du cahier (graines 0-5)

| Critère | Seuil | 1.0.5 (KM2c3) | **1.0.6** (Dart = Python) | Bruit (KR1) |
| --- | --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,67 % | 3,70 % | 0,15 pt |
| 2 mauvais jour isolé | < 1 % | 0,88 % | 0,78 % | 0,25 pt |
| 3 convergence | ≤ témoin 11,0 | 4,83 | 4,77 | 0,30 |
| 4 couverture à 90 % | 88-92 % | 91,94 % | **92,08 %** | 0,8 pt |
| 5 calibration (C13.11.2) | indicateur | 8,8 pts | 7,4 pts ; 17 groupes : 0,186 ± 0,075 (KM2c3 0,189 ± 0,071) | — |
| 6 jour J | ≥ témoin 0,9154 | 0,9339 | 0,9349 | 0,005 |
| 7 / 8 sécurité (graines 0-5) | 0 | 0 | 0 | — |
| 7 bis (six jeux, tenus sur 24) | ≥ 90 %, aucun sous −0,10 | 24, 22, 18, 23, 22, 21 | 24, 22, **19**, 23, 22, 21 | ± 1 cas |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,206 s ; 32,0 ms | 0,331 s ; 21,9 ms | — |

Aucun recul au-delà du bruit. Critère 4 : 92,08 % sort de la bande de 0,08 point (+0,14 point contre 1.0.5, six fois sous le bruit de KR1) : à surveiller, pas un recul mesurable. Critère 7 bis : les cas sous le plancher sont les mêmes qu'en KM2c3, un cas de plus tenu sur `km1c3`.

## 5. Crédits de groupes (point 5) : revue sur sources, table avant / après

Revue faite par un sous-agent Opus (recherche web, références vérifiées une à une ; détail et niveaux de preuve dans `kalis_adapt/reference/SOURCES.md` et ci-dessous). Les crédits « chest » des fiches (`vecteurs_qualites_v1.json`, champ `groupes`) viennent de la base d'exercices v1.1 (muscles principaux = 1, secondaires = 0,5), comme `groupCredits` de `kalis_plan` et le validateur du banc (critère 7).

| Exercice (exemples des fiches) | « chest » actuel | Recommandé par la revue | Source principale |
| --- | --- | --- | --- |
| Traction pronation, lestée (`sw-traction-pronation`, `sl-traction-lestee`) | 0,5 | 0 | Youdas et al. 2010 (JSCR 24(12):3404-3414) : grand pectoral 44-57 % MVIC contre 117-130 % pour le grand dorsal ; Dickie et al. 2017 : prises équivalentes ; aucune donnée d'hypertrophie du pectoral par les tractions |
| Traction supination, prise serrée (`sw-traction-supination`, `sl-traction-lestee-prise-serree`) | 0,5 | 0 (0,5 défendable a minima) | Youdas 2010 : pectoral plus actif en supination |
| Traction neutre, large (`sw-traction-neutre` 0,5 ; `sw-traction-large` 0) | 0 ou 0,5 selon la fiche | 0 | Dickie 2017 |
| Muscle-up barre, anneaux, lesté (`sl-muscle-up-leste`, `cd-muscle-up-barre-strict`…) | 1,0 | 0,5 | Walker et al. 2023 (Int J Exerc Sci 16(1):1451-1460) : seule EMG du muscle-up, phase de poussée réelle (triceps), aucun chiffre pour le pectoral ; analogie avec le haut d'un dip |
| Dips barres parallèles, lestés | 1,0 | 1,0 (inchangé) | McKenzie et al. 2022 (IJERPH 19:13211) |
| Pompes | 1,0 | 1,0 (inchangé) | Calatayud et al. 2015 (JSCR 29(1):246-253) |
| Pull-over haltère (`mu-pull-over-haltere`) | 1,0 | 0,5 | Campos & Silva 2014 (Motriz 20(2):200-205) : pectoral moitié moins actif qu'au développé |
| Rowing, rowing inversé, tirage bras tendus | 0 (0,5 pour deux tirages bras tendus à la poulie) | 0 | choix raisonné (aucune EMG du pectoral) |

**Décision de ce lot : aucun crédit changé.** La table est partagée : `kalis_plan` écrit les programmes avec elle (`groupCredits`, rampe de volume du plan) et le validateur du banc mesure le critère 7 avec elle. Abaisser un crédit dans les fiches de Koach seul ferait compter à Koach moins de séries « chest » que le validateur : Koach servirait davantage de tractions et de muscle-ups que la rampe du banc ne l'admet, et le critère 7 compterait des violations « volume_trop_vite » qui ne sont que des écarts de comptage. Le changement doit être fait **ensemble** dans la correspondance muscles → groupes de `kalis_plan` (`traits.dart`, nouvelle version de `kalis_plan`, programmes régénérés), dans le validateur du banc et dans les fiches de Koach, puis remesuré sur les 90 600 saisons : c'est un lot `kalis_plan` (structure, KS) — recommandation au pilotage (§ 9). Le correctif de fond du constat (répartition, priorité de rôle, plancher) ne dépend pas de ces crédits : sur le scénario dédié, le muscle-up lesté et la traction lestée sont servis à leur écrit avec les crédits actuels.

## 6. Parité Dart

- Fixtures de la référence (15) et complémentaires (3) régénérées ; parité 1e-9 (`koach_parite_test`) ; les 15 tests de `test_km4_retour.py` et le scénario de douleur portés en Dart (`koach_km4_retour_test.dart`, 14 tests) ; 387 tests de `kalis_adapt` et 137 tests km de `kalis_bench` verts (run F) ; les 268 tests de `kalis_bench` verts (run H, 39378877508), après la mise à jour de la sortie Python de `evaluer_saison` pour l'adversaire `adv-7ee0da71` (`km2_adversaire_test.dart` : `echecs` 0,00428 → 0,004292, `gain` −0,000574 → −0,00053, recalculés par la référence 1.0.6 ; le Dart donnait déjà ces valeurs).
- **Campagne entière : 90 600 saisons identiques une à une** entre le Dart (run D) et le Python (runs E et G), 0 différente, 0 sans correspondant (run G, `docs/data/km4/comparaison/` ; champs `duree_s` et ordre de `first_under` exclus, comme KM2c3). Run F : 89 438 identiques sur les 89 438 de E ; la part 13/20 de E (limite de 355 min) a été refaite par G en deux demi-parts (13/40 et 33/40), même arbre, même empreinte. Les agrégats Python (sécurité, rampe, critères 0-5) sont ceux du Dart au chiffre près.
- Tests Python sur la CI (Python 3.11, numpy 2.4) : 309 verts, 3 échecs de `test_fixtures` (`numerique.json`, `planification_1.json`, `planification_2.json` : derniers chiffres d'algèbre linéaire, environnement ; 2 déjà en KM1c4) ; 312 verts en session (Python 3.13, numpy 2.5.3), fixtures générées en session et lues à l'identique par le Dart.

## 7. Relecture indépendante

Sous-agent Opus (diff complet, code environnant, sondes Python ; 308 tests relancés) : **0 bloquant**.

- **M2 (corrigé)** : si l'application donne les rôles du jour mais pas ceux des séances restantes, la répartition traitait les lignes restantes non premières comme des accessoires (coupées d'avance) alors que leur vrai rôle les protégerait le jour venu : 314 semaines sur 3 000 au-delà de la limite (sonde). Correction : une ligne restante sans rôle n'est jamais coupée d'avance (rang 3) ; tests Python et Dart.
- **M1 (gardé, exception dite)** : les tenues bras tendus (`tendon_figures`, secondes par famille) gardent la règle de 1.0.5 (écrit restant réservé ; tenues raccourcies à 5 s, puis une série de moins) : un principal de figure (planche, front lever) peut encore être retiré par la rampe tendineuse. Choix : c'est une règle de **tendon** (adaptation lente des tendons aux tenues bras tendus), pas la rampe de volume visée par C17.37 ; un plancher la dépasserait. Sur le banc, 0 principal retiré au total (les tenues comprises) ; à revoir si le propriétaire le demande.
- Mineurs traités : première ligne sans crédit qui prenait la place du principal (corrigé, testé) ; texte de retrait (« cette semaine » faux, corrigé) ; commentaire orphelin ; scénario de douleur porté en Python. Dits : ordre des raisons changé par les deux passes (10 fixtures sur 12 identiques sur tous leurs plans ; l'application ne doit pas dépendre de l'ordre) ; `slotId` uniques supposés (contrat) ; « douleur » au sens large (zone sensible douze semaines) ; prorata sur l'écrit du reste et sur le servi du jour ; mesure indexée par exercice.

## 8. Ce que KB3 doit monter

- Copier `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` de `etiquettes/kalis_adapt-v1.0.5` (C17.19.3) ; asset `koach_params_1_0_6.json` à la place de `koach_params_1_0_5.json` (version `1.0.6-ref.1`, 347 clés, SHA-256 `4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a`) ; test d'empreinte de l'application.
- **Donner `role` à chaque item de `contexte['reste_semaine']` et des séances manquées** (rôle de l'emplacement, comme `roles` du plan de séance). Sans rôle, Koach reste sûr (ligne restante non coupée d'avance, première ligne du jour = principal) mais protège moins bien.
- La garde de KB2 correction 1 (exercice ramené à 0 servi à la moitié) peut rester en filet : avec 1.0.6, un principal sans douleur n'est plus jamais à 0 ; un accessoire ou un secondaire peut l'être (raison affichée) ; une figure principale peut l'être par la rampe tendineuse (§ 7, M1). Recommandation : garder la garde pour les principaux seulement, ou la retirer.
- Raisons : `ecrites` et `douleur` (textes à jour dans `koach_textes.dart`) ; ordre des raisons changé.
- Pour le propriétaire : le lundi de tirage de son nouveau programme garderait muscle-up lesté et traction lestée (réduits au plus), les accessoires « chest » coupés d'abord.

## 9. Limites et recommandations au pilotage

1. **Valider KM4** : `kalis_adapt` 1.0.5 (Koach 1.0.6), `kalis_bench` 0.5.7 ; critère dur C17.17.3 tenu (0 violation du critère 7) et critère C17.37 tenu (0 principal retiré par la rampe sans douleur) sur les 90 600 saisons, en Dart et en Python.
2. **Répartition sur la semaine** (point 1 du prompt) : non livrée telle quelle — incompatible avec le critère 7 tant qu'une séance manquée compte à son écrit (40 constats mesurés). Si le pilotage veut la répartition, la décision porte sur la convention du banc (compter les séances manquées au réalisé, ce qui est la réalité physiologique) : le code est prêt (`retour_repartition_semaines` 4), il faudrait remesurer.
3. **Crédits de groupes** : revue faite (§ 5), aucun changé : à faire ensemble dans `kalis_plan` (`traits.dart`), le validateur du banc et les fiches de Koach, par un lot `kalis_plan` (KS), avec la table du § 5 (tractions chest 0, muscle-up 0,5, pull-over 0,5).
4. Tenues bras tendus (M1) : exception gardée, à trancher.
5. Critère 4 à 92,08 % (bande 88-92) : sous le bruit, à surveiller au prochain lot de calibration.
6. Incidents de CI : run B lancé deux fois sans le bon script (annulés), run C annulé (après relecture puis après la mesure du run B), part 13/20 du run E au-delà de 355 min (refaite par G), variante M sans SDK ; premier contrôle complet (39363143851) rouge sur un seul test de `kalis_bench` (`km2_adversaire_test`, sortie Python de 1.0.3 écrite en dur, que 1.0.6 change au 6e chiffre ; corrigée, run H vert, second contrôle complet 39378780707 vert). Aucun effet sur les résultats publiés.
