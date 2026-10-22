# Livraison KM6 — Koach 1.0.8 : bugs moteur de RV1 et crédits de groupes (`kalis_adapt` 1.0.7, `kalis_plan` 0.4.3, `kalis_bench` 0.5.9)

Lot KM6 du pipeline CP (lot de méthode Koach ; décisions C13.3, C17.33, C17.37 à C17.47 ; prompt `prompts/KM6.txt`), voie A, sessions Opus 5.5 effort maximal : 22/10/2026 09:05-12:10 UTC (arrêtée par la limite d'utilisation du compte) puis reprise de 17:55 UTC à la livraison, depuis `cp-sauvegardes/KM6` (PIPELINE_CP.md § 9). Aucune donnée réelle, aucun déchiffrement, clé des références non lue (C17.33). Lot sans panel ni relecture documentée (C13.3) ; relecture indépendante par un sous-agent Opus. Outil `add_repo` absent de la session : accès en écriture vérifié par les pushes de sauvegarde. Dart 3.13.6 (conda-forge) et cache pub du run B0 en session ; campagne sur la CI (`claude/ci-cp-a`).

**En une phrase** : Koach 1.0.8 corrige les huit bugs moteur trouvés par la revue (poulie par 2,5 kg et non 2,5 lb, groupes d'intervalles et EMOM recalés sur les lignes servies, charges jamais au-dessus d'un plafond, test xRM écrit gardé, groupe de l'emplacement gardé, baisse hebdomadaire désormais dite) et ne compte plus les tractions comme du travail de pectoraux (muscle-up et pull-over pour une demi-série), la même table dans `kalis_plan`, les fiches de Koach et le validateur ; sur les 90 600 saisons du banc, en Dart et en Python : **0 violation de sécurité, 0 saison plantée, 0 série retirée sous l'écrit par la rampe, 0 coupe silencieuse**, critères sans recul.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.7 (Koach 1.0.8, `1.0.8-ref.1`) | `etiquettes/kalis_adapt-v1.0.7` | référence Python (`koach/seance.py`, `moteur.py`, `planification.py`, `banc/verite.py`, `banc/politique_koach.py`, `banc/securite_campagne.py`, `qualites/regles.py` R8-a, fiches `1.0.1`, `CHANGEMENTS_1_0_8.md`, `SOURCES.md` § 4, note datée au contrat, `tests/test_km6.py` 25 tests, fixtures) ; portage Dart (`grid.dart`, `seance.dart` `techniqueCoherente` / `groupesServis` / `_coherence`, `moteur.dart` `groups`, `planification.dart` `koachModule`, `parametres.dart`, `koach_textes.dart` `koach.volume_semaine`) ; `test/koach_km6_test.dart` ; asset **`assets/koach/koach_params_1_0_8.json`** (344 clés, aucune valeur changée, SHA-256 `9d74365e58b84fe0e9db7801dd450c053e4ca870184fca5b480b534b116841d1`) ; fiches **`assets/koach/vecteurs_qualites_v1.json`** `1.0.1` (SHA-256 `99b0cae2d0b29d18d5daa30ee92b91990225124e38e44d522e80e8ae01a196e0`) ; `docs/INTEGRATION_KM3.md` § 12 |
| `kalis_plan` | 0.4.3 | `etiquettes/kalis_plan-v0.4.3` | `chestCreditRule` (`traits.dart`, exportée) ; test du dernier recours `_fitVolume` (une tentative de test en moins quand le test seul dépasse la rampe, jamais la dernière ; profil aléatoire 3770) ; programmes du banc régénérés ; contrat § 12.18 |
| `kalis_bench` | 0.5.9 | `etiquettes/kalis_bench-v0.5.9` | `test/km6_credits_test.dart` (trois tables, exercice par exercice ; grilles par défaut alignées) ; mesure X8 (`_kmMesureModule`, `tool/kr1_securite.py`) ; données de référence et témoins régénérés sur `kalis_plan` 0.4.3 ; `docs/CRITERES_KM6.md`, `docs/data/km6/` |

`kalis_core` inchangé (la table des pas par défaut n'y est pas déplacée : six lignes, alignées et testées dans `kalis_bench`). `moteurs` : 25d5bfe6 (étiquettes `kalis_adapt-v1.0.7`, `kalis_plan-v0.4.3`, `kalis_bench-v0.5.9` sur ce commit). Campagne : run 39764317745 (arbre des paquets identique, sauf les valeurs attendues de `km2_adversaire_test.dart`). Contrôle complet : run 39831895492 **vert** sur l'arbre de `moteurs` 25d5bfe6 (`claude/ci-cp-a` 5c5c8a17 : kalis_adapt 409 tests, kalis_bench 296 tests et rapport en 4 324 s, kalis_plan 627 tests, kalis_core, kalis_quest, outils Python). Rien dans l'application (intégration : KB5).

## 2. Bugs avant / après (partie A)

Chaque bug a sa reproduction synthétique et son test de non-régression en Python (`tests/test_km6.py`) et en Dart (`test/koach_km6_test.dart`), mêmes valeurs.

| Bug | Avant (1.0.7) | Après (1.0.8) |
| --- | --- | --- |
| X1 poulie sans profil de pas | grille 2,5 lb : extension triceps servie à 19,28 / 20,41 / 21,55 kg | 2,5 kg, minimum 2,5 kg (défaut de `kalis_plan`) : 20 kg ; défauts des deux paquets comparés par un test |
| X2 groupe `intervals` réduit | « 8× (30 s / 30 s) » mis à l'échelle (`koach.wod_echelle` 75 %) : 6 lignes, 8 tours | `plan('seance')` accepte `groups` et renvoie `groups` recalés : 6 lignes, 6 tours ; EMOM au temps : durée = intervalle × lignes servies ; groupe sans membre retiré |
| X3 EMOM dont Koach baisse les séries | dips lestés EMOM 10 × 3, bilan très bas : 9 séries, `intervals` 10 (plan refusé par l'application) | technique recalée en fin de séance (`technique_coherente`, port de `coherentTechnique`) : 9 séries, `intervals` 9 ; `backoffSets`, paliers, blocs au temps, `setTargets` |
| X4 test xRM verrouillé hors grille | 61 kg écrits servis à 60 kg | 61 kg gardés |
| X5 charge plafonnée | 70 % écrits (91,875 kg) servis à 92,5 kg | arrondi vers le bas après un plafond : 90 kg |
| X6 test adaptatif sous plafond | haltère par 5 kg, plafond 20,1 kg : 25 kg servis | 20 kg |
| X7 remplacement sans `groupId` dans un bloc | course facile hors du bloc d'intervalles | groupe et `format` de l'emplacement gardés ; montée d'un vrai test hors du groupe |
| X8 modulation hebdomadaire sous l'écrit | baisse silencieuse | raison nouvelle `koach.volume_semaine` (« Cette semaine, je te propose N séries sur … au lieu des M écrites : je répartis l'effort de la semaine d'après ta récupération prévue. ») ; `koachModule` posé par la planification ; règle inchangée (mesure § 4) |

Relecture indépendante (sous-agent Opus, diff complet, sondes Python et Dart, avant la campagne) : M1 (mesure « rampe déguisée » sur l'écrit du programme), M2 (`koach.volume_semaine` sur l'exercice écrit, émis seulement si l'exercice servi est celui de l'emplacement), m3 (la modulation ne touche plus aux séries des pyramides, vagues, échelles et blocs au temps), m4 (contre la montre au plus petit nombre de séries ; EMOM au temps), m6 (`koachVolume` cumulé) corrigés et testés ; m5 (moins de tentatives d'un test sur un mouvement non entraîné les trois semaines d'avant) et m7 (charge minimale de la grille au-dessus d'un plafond plus bas) dits comme limites. Parité relue sans divergence (13 cas limites de `technique_coherente`, 5 de `groupes_servis`).

## 3. Crédits de groupes (partie B)

Règle unique (R8-a de la référence = `chestCreditRule` de `kalis_plan` 0.4.3 = crédits lus par le validateur du banc) ; seul le groupe « chest » change ; 53 exercices (27 à 0, 26 de 1 à 0,5). Sources vérifiées le 22/10 : `SOURCES.md` § 4.

| Exercices | « chest » avant | après | Base |
| --- | --- | --- | --- |
| Tractions (pronation, supination, neutre, lestées, prise serrée, un bras, kipping), tirage vertical poulie | 0,5 | **0** | grand pectoral 44-57 % de la contraction maximale contre 117-130 % pour le grand dorsal (Youdas et al. 2010 ; Dickie et al. 2017) ; ni moteur ni synergiste du schéma : choix raisonné, dit |
| Traction explosive aux hanches | 1 | **0** | même règle |
| Muscle-ups (barre, anneaux, lestés), transitions | 1 | **0,5** | phase de poussée courte (Walker et al. 2023 : pectoral très actif, normalisation non comparable) : **choix raisonné, à revoir** |
| Pull-over haltère | 1 | **0,5** | pectoral moins actif qu'au développé (Campos et Silva 2014, à la barre) ; aligné sur les autres pull-over |
| Dips, pompes, développés, rowing, tirages bras tendus, pull-over poulie et machine, front lever 0,5, back lever 1, croix, hefesto | — | inchangés | McKenzie et al. 2022 ; Calatayud et al. 2015 |

Trois tables comparées exercice par exercice (`kalis_bench/test/km6_credits_test.dart`, `tests/test_km6.py`) : aucun écart. Effet mesuré : le scénario de PR2 (lundi de tirage, mardi de poussée) reste servi à toutes ses lignes écrites (`test_km5_rampe.py`, `koach_km5_rampe_test.dart` : écrit « chest » des programmes A et B : 17,5 et 24,5 au lieu de 26,5 et 38,0) ; extension triceps poulie à 2,5 kg près sans profil de pas (X1).

## 4. Critères avant / après

| Mesure (90 600 saisons) | 1.0.7 (KM5) | **1.0.8 Dart** | **1.0.8 Python** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | **0** | **0** |
| Critère 7 / 8 (définition de KM5) | 0 | **0** | **0** |
| Ancienne définition (indicateur) | 0 | 0 | 0 |
| Série ou item retiré sous l'écrit par la rampe | 0 | **0** | **0** |
| Coupe sous l'écrit sans cause (mesure indépendante) | 0 | **0** | **0** |
| Ajouts de Koach bornés | 4 040 | 3 673 | 3 673 |
| « Retour à l'écrit » / réalisée appariée | 4 216 / 22 290 | 4 219 / 22 414 | 4 219 / 22 414 |
| **Modulation hebdomadaire sous l'écrit (X8)** | non mesurée, sans raison | 1 825 960 lignes dans 1 113 375 séances sur 6 168 519 ; **0 sans raison** | identique |

| Critère (graines 0-5) | Seuil | 1.0.7 | **1.0.8** (Dart = Python) | Bruit |
| --- | --- | --- | --- | --- |
| 1 e1RM rang 6 | < 3 % (écart accepté) | 3,68 % | 3,74 % | 0,15 pt |
| 2 mauvais jour | < 1 % | 0,84 % | 0,86 % | 0,25 pt |
| 3 convergence | ≤ 11,06 | 4,759 | 4,809 | 0,30 |
| 4 couverture | 88-92 % | 92,03 % | 91,90 % | 0,8 pt |
| 5 calibration | indicateur | 6,06 pts ; 17 groupes 0,193 ± 0,074 | 11,95 pts ; 17 groupes 0,190 ± 0,076 | — |
| 6 jour J | ≥ 0,9156 | 0,9364 | **0,9362** | 0,005 |
| 7 bis (six jeux) | ≥ 90 % | 24, 22, 19, 22, 22, 21 | 24, 22, 19, 23, 22, 21 | ± 1 cas |
| 11 temps | ≤ 10 s ; ≤ 50 ms | 0,176 s ; 26,9 ms | 0,124 s ; 28,6 ms | — |

Aucun recul au-delà du bruit. Critère 5 : la valeur des graines 0-5 était le minimum des 17 groupes en KM5 ; la moyenne des 17 groupes est inchangée. **Parité** : 90 599 saisons identiques une à une ; 1 écart de 1,2·10⁻¹² sur une ligne d'estimation (`autres_02`, maladie, vérité c, graine 14 ; arrondi d'algèbre linéaire, comme KM5), sans effet sur aucun agrégat.

**X8, rampe déguisée ?** Non. La modulation (± 15 % par qualité, au moins une série) optimise la performance prévue par le jumeau et ne lit aucune limite tirée du réalisé. Elle baisse plus souvent les semaines où la rampe couperait (9,8 % des lignes contre 4,4 % ailleurs : semaines plus lourdes, fatigue prévue plus haute), mais 81 % des lignes baissées sont là où la rampe ne couperait pas. Règle gardée, chaque baisse dite (C17.40.3 respectée : la rampe de volume ne retire rien sous l'écrit, 0 sur la campagne).

## 5. Incidents

- Session du matin arrêtée à 12:10 UTC par la limite d'utilisation du compte, après le lancement du run B (campagne) ; reprise à 17:55 UTC depuis `cp-sauvegardes/KM6` (daec4b26) sans rien refaire.
- Run B : deux échecs attendus, traités. (1) `test_fixtures` sur la CI (Python 3.11) : arrondis de dernier bit, connus depuis KM4 (les fixtures canoniques sont générées dans la session ; `generer.py --verifier` vert et 341 tests Python verts en session). (2) `km2_adversaire_test.dart` : valeurs attendues du témoin (régénéré sur `kalis_plan` 0.4.3) et de `evaluer_saison` pour `adv-7ee0da71` recalculées par la référence 1.0.8 ; le Dart donnait déjà ces valeurs ; 296 tests de `kalis_bench` verts en session.

## 6. Ce que KB5 doit monter

- Copier `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` de `etiquettes/kalis_adapt-v1.0.7`, et `kalis_plan` 0.4.3 de `etiquettes/kalis_plan-v0.4.3` ; asset `koach_params_1_0_8.json` à la place de `koach_params_1_0_7.json` (SHA-256 `9d74365e…41d1`) ; fiches `vecteurs_qualites_v1.json` 1.0.1 (SHA-256 `99b0cae2…96e0`) ; tests d'empreinte.
- Passer les `GroupSpec` de la séance écrite dans `plan({'horizon': 'seance', …, 'groups': […]})` et lire `groups` de la sortie (X2) : la colle de RV1 qui sert les intervalles telle qu'écrite peut tomber (C17.44.4, à décider au pilotage).
- La technique servie est cohérente avec `sets` (X3) : `coherentTechnique` côté application devient une sécurité ; l'item servi garde `groupId` et `format` de son emplacement (X7).
- Afficher `koach.volume_semaine` comme les autres raisons ; ce n'est pas une coupe à garder (`koachGardeSeance`).
- Crédits « chest » des tirages : le rapport « séries par groupe » et la structure de la semaine de l'application suivent `kalis_plan` 0.4.3.
- Détail : `packages/kalis_adapt/docs/INTEGRATION_KM3.md` § 12.

## 7. Limites et recommandations au pilotage

1. **Valider KM6** : Koach 1.0.8 (`kalis_adapt` 1.0.7), `kalis_plan` 0.4.3, `kalis_bench` 0.5.9 ; 0 violation, 0 retrait sous l'écrit par la rampe, 0 coupe silencieuse en Dart et en Python ; critères sans recul ; puis KB5.
2. Muscle-up « chest » 0,5 : choix raisonné ; la seule mesure trouvée (Walker et al. 2023) montre un pectoral très sollicité ; à revoir si une mesure comparable arrive.
3. X8 : la modulation sert sous l'écrit 1,8 million de lignes sur la campagne (au plus −15 % par qualité, une série au moins) ; règle gardée, désormais dite. Si le propriétaire veut que Koach ne baisse jamais l'écrit, même par la modulation, c'est une décision (C17.40.3 ne la couvre pas) : la baisse serait alors limitée à l'intensité.
4. X2 n'est pas mesuré par la campagne (le banc ne passe pas de groupes) : tests unitaires seulement.
5. `test_fixtures` sur la CI Python 3.11 : toujours rouge par arrondis (connu) ; à régler un jour en générant les fixtures dans l'environnement de la CI ou en tolérant 1 ulp.
