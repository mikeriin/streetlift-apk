# Livraison KM5 — Koach 1.0.7 : la rampe de volume ne coupe jamais sous l'écrit (`kalis_adapt` 1.0.6, `kalis_bench` 0.5.8)

Lot KM5 du pipeline CP (lot de méthode Koach ; décisions C13.3, C17.33, C17.37, C17.39, **C17.40** ; prompt `prompts/KM5.txt`), voie A, session Opus 5.5 effort maximal, du 20/10/2026 16:36 UTC au 21/10/2026 01:59 UTC. L'outil `add_repo` n'est pas dans la session : accès en écriture vérifié par `git push --dry-run` puis par le push de la ligne « en cours ». Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : compilation, analyse, tests et campagne Dart sur la CI (`claude/ci-cp-a`, commits « KM5 contrôle (dev) »). Aucune donnée réelle, aucun déchiffrement, clé des références non lue (C17.33). Lot sans panel ni relecture documentée (C13.3). Sous-agent Opus pour la relecture indépendante ; sauvegardes sur `cp-sauvegardes/KM5`.

**En une phrase** : Koach 1.0.7 ne retire plus jamais une série ni un exercice de ton programme au nom du volume — il sert ton écrit et ne borne que les séries qu'il ajoute lui-même, à max(limite de la rampe, écrit servi de la semaine) ; sur les 90 600 saisons du banc, en Dart et en Python (saisons identiques une à une, à 8·10⁻¹² près sur un nombre d'une saison) : **0 violation de sécurité** (nouvelle définition), **0 avec l'ancienne définition**, **0 série ou item retiré sous l'écrit par la rampe**, 0 coupe silencieuse, 0 saison plantée ; ton mardi de poussée du 20/10 serait servi en entier.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.6 (Koach 1.0.7, `koachVersion` `1.0.7-ref.1`) | `etiquettes/kalis_adapt-v1.0.6` | référence Python (`reference/koach/seance.py`, `rupture.py`, paramètres `1.0.7-ref.1`, `CHANGEMENTS_1_0_7.md`, `SOURCES.md`, note datée au contrat, `PORTAGE_DART.md`, tests `test_km5_rampe.py` 19, `test_securite_regles.py`, `test_campagne.py`, fixtures) ; portage Dart ligne pour ligne (`lib/src/koach/seance.dart`, `rupture.dart`, `dual.dart`, `parametres.dart`, `lib/koach_textes.dart`) ; asset `assets/koach/koach_params_1_0_7.json` (344 clés, **SHA-256 `2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c`**) ; tests `test/koach_km5_rampe_test.dart` (18), `koach_parametres_test.dart`, `koach_textes_test.dart` ; `CHANGELOG.md`, `docs/INTEGRATION_KM3.md` § 11 |
| `kalis_bench` | 0.5.8 | `etiquettes/kalis_bench-v0.5.8` | nouvelle définition de « volume_trop_vite » des saisons servies par Koach (`kmFiltrerVolumeEcrit`, `KmConstatsSaison.constatsEtSeries`, `kmSecuriteSaison`), indicateur `ancienne_definition`, mesures KM5 (`kmMesureRampe`), agrégats `tool/kr1_securite.py`, test `test/km5_filtre_test.dart`, fixtures km2 régénérées ; `docs/CRITERES_KM5.md`, `docs/data/km5/` |

`kalis_core`, `kalis_plan` (0.4.2) inchangés. `moteurs` : 737d528d (`etiquettes/kalis_adapt-v1.0.6`, `etiquettes/kalis_bench-v0.5.8`) ; contrôle complet `claude/ci-cp-a` : run 39509091986 (vert ; arbre des paquets identique à celui livré) ; campagne : run 39475063809. Rien dans l'application (intégration : KB4).

## 2. Mécanisme avant / après

**1.0.6** (KM4) : la rampe de volume (limite de la semaine par groupe majeur, mesurée sur le réalisé des semaines d'avant) était tenue en **coupant le programme écrit** — accessoires d'abord, secondaires, principaux jusqu'à la moitié de leur écrit. Avec un programme choisi plus volumineux que les semaines d'avant, la séance se vidait. Le scénario du constat, rejoué sur 1.0.6 (synthétique : trois semaines d'un programme A, puis programme B de six séances en PPL, +43 % « chest », +57 % « delt_anterior », +60 % « triceps ») : lundi de tirage servi muscle-up lesté 3/6, traction lestée 4/8, rowing 1/3, face pull **retiré**, curl 1/3 ; mardi de poussée : dip lesté 8, tractions 8, pompes lestées 2/4, développé militaire 1/3, rotations externes 2, **extension triceps et élévations latérales retirées** (`koach.retour_gradue`, groupes triceps 25,2 et delt_anterior 21,0) — le constat du propriétaire.

**1.0.7** (`CHANGEMENTS_1_0_7.md`, contrat § 8.3) :

1. **Écrit du programme** d'un item = `sets − koachVolume` (`koachVolume` : séries que Koach ajoute ou retire ; posé par la planification, tenu à jour par la semaine allégée d'un diagnostic et par le bras A du contrôle dual).
2. **Plafond** par groupe et par semaine = max(L, écrit **servi** de la semaine) ; L = limite de la rampe, inchangée ; écrit servi = chaque ligne écrite au plus à ses séries servies (une ligne retirée par la douleur ne laisse pas sa place aux ajouts de Koach), compté une fois par séance. Allègement : max(limite de l'allègement, écrit servi).
3. **Seules les séries ajoutées par Koach** au-dessus de l'écrit d'une ligne du jour sont retirées, tant qu'un groupe dépasse son plafond : accessoires d'abord, puis secondaires, principaux en dernier, dans un rang la ligne la plus tardive (l'ajout le plus récent ; règle équivalente à « ajouts les plus récents d'abord », dite comme telle). Jamais sous l'écrit ; raison nouvelle `koach.ajout_borne`.
4. Coupes sous l'écrit gardées pour leurs causes : douleur (un principal sous douleur peut aller à 0), zone sensible, rampe tendineuse des tenues bras tendus (seule raison `koach.retour_gradue` restante), surmenage, bilan, coupure, test reporté, séance bornée, endurance.
5. Un allègement se décide sur l'écrit du programme (les ajouts de Koach ne défont plus un allègement écrit).
6. Modulation hebdomadaire (`plafond_volume` ±15 %) inchangée : ses baisses viennent de l'optimisation de la performance prévue, pas de la rampe ; ses hausses sont des ajouts, bornés.
7. C17.38.4 (séries hors du servi) : sans effet sur les coupes désormais ; comptage gardé.
8. Paramètres : `securite.retour_plancher_principal`, `retour_repartition_semaines`, `retour_emprunt_plancher` retirées (sans objet) ; aucune valeur changée.

**Scénarios dédiés** (Python et Dart, mêmes valeurs) : (a) programme B servi **à toutes ses séries écrites**, lundi de tirage et mardi de poussée compris, aucune raison de la rampe de volume ; (b) même athlète, gêne à l'épaule (4/10) le mardi : les cinq mouvements qui la sollicitent (dip, pompes lestées, développé militaire, rotations externes, élévations latérales) retirés par la conduite sous douleur (`koach.douleur_retrait`), tractions et extension triceps à leur écrit ; (c) ajouts de Koach (+5 séries sur un écrit à la limite) retirés accessoire d'abord, l'écrit gardé, raisons `koach.ajout_borne` (limite 12, écrit 12).

## 3. Validateur : nouvelle définition (critère 8, clé `7_securite`)

Violation `volume_trop_vite` d'une saison servie par Koach = servi d'un groupe dans la semaine > max(limite de la rampe, écrit du programme de la semaine) ; le constat porte les deux nombres. Avant : limite seule (un programme plus volumineux que le passé servi « violait » servi tel qu'écrit). Détail et raison : `kalis_bench/docs/CRITERES_KM5.md` § 1. Le plafond de Koach (écrit servi) est au plus celui du validateur (écrit du programme) : Koach est plus prudent que la règle qu'il est mesuré contre.

## 4. Critères avant / après

| Mesure (90 600 saisons) | 1.0.6 (KM4) | **1.0.7 Dart** | **1.0.7 Python** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | **0** | **0** |
| Critère 7 / 8, nouvelle définition | — | **0** | **0** |
| Ancienne définition (indicateur) | 0 | 0 (0 saison) | 0 (0 saison) |
| **Série ou item retiré sous l'écrit par la rampe** | 749 items sur un échantillon de 27 saisons | **0** | **0** |
| Coupe sous l'écrit sans cause (mesure indépendante) | — | 0 | 0 |
| Ajouts de Koach bornés | — | 4 040 séries | 4 040 |
| « Retour à l'écrit » | 54 064 | 4 216 | 4 216 |
| Réalisée appariée (indicateur) | 243 277 | 22 290 | 22 290 |

| Critère (graines 0-5) | Seuil | 1.0.6 | **1.0.7** | Bruit |
| --- | --- | --- | --- | --- |
| 1 e1RM rang 6 | < 3 % (écart accepté) | 3,70 % | 3,68 % | 0,15 pt |
| 2 mauvais jour | < 1 % | 0,78 % | 0,84 % | 0,25 pt |
| 3 convergence | ≤ 11,0 | 4,77 | 4,76 | 0,30 |
| 4 couverture | 88-92 % | 92,08 % | 92,03 % | 0,8 pt |
| 5 calibration | indicateur | 7,4 pts ; 0,186 ± 0,075 | 6,06 pts ; 0,193 ± 0,074 | — |
| 6 jour J | ≥ 0,9154 | 0,9349 | **0,9364** | 0,005 |
| 7 bis (six jeux) | ≥ 90 % | 24, 22, 19, 23, 22, 21 | 24, 22, 19, 22, 22, 21 | ± 1 cas |
| 11 temps | ≤ 10 s ; ≤ 50 ms | 0,331 s ; 21,9 ms | 0,176 s ; 26,9 ms | — |

Aucun recul au-delà du bruit. **Performance le jour J** : 0,9349 → 0,9364 (+0,0015, sous le bruit) : servir le volume écrit ne coûte rien au jour J sur le banc. Parité : 90 599 saisons identiques, 1 à 8·10⁻¹² sur deux nombres d'estimation (arrondi d'algèbre linéaire, sous la tolérance 1e-9), sans effet sur les agrégats.

## 5. Relecture indépendante

Sous-agent Opus (diff complet, sondes Python, 311 tests relancés) : 0 bloquant de code (documents en retard, faits ensuite) ; traités : **M1** l'écrit d'une ligne retirée par la douleur laissait sa place aux ajouts de Koach (plafond = écrit servi, testé) ; **M2** l'allègement se décidait sur l'écrit avec ajouts (écrit du programme, testé) ; **M3** le critère KM5 était vrai par construction (mesure indépendante `sans_cause_*` ajoutée : 0 sur 90 600 saisons, et elle ne voit pas les coupes de 1.0.6, qui sont dites) ; **m1** un second `prescrire` de la même séance comptait l'écrit deux fois (compté une fois, testé) ; **m5** double lecture du programme dans le filtre (une seule). Dits comme limites : **M4** la montée d'un vrai test n'entre pas dans le plan (comme 1.0.6 ; 0 violation sur la campagne, vue « tests faits ») ; **m2** le groupe d'un constat est retrouvé par sa valeur (à égalité, gardé : prudent) ; parité relue sans divergence.

## 6. Incidents

- Run A (39463684069) : compile ; échecs attendus (documents, sortie Python d'`evaluer_saison` de `adv-7ee0da71` : `echecs` 0,004292 → 0,004093, `gain` −0,00053 → −0,000389 recalculés par la référence 1.0.7).
- Run B (39470578630) et premier contrôle complet annulés : formatage Dart ; patchs du run C (39473916713) appliqués (le premier essai par `git apply` depuis un sous-dossier ne les avait pas appliqués, d'où l'échec du contrôle 39475006138 au formatage) ; le formatage ne change aucun comportement : la campagne du run B (bis), sur l'arbre d'avant formatage de deux fichiers de test et de `koach_textes.dart`, vaut pour l'arbre livré.
- Tests Python sur la CI : 313 verts, 3 échecs connus de `test_fixtures` (numpy de la CI, comme KM4) ; 316 verts en session.

## 7. Ce que KB4 doit monter

- Copier `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` de `etiquettes/kalis_adapt-v1.0.6` ; asset `koach_params_1_0_7.json` à la place de `koach_params_1_0_6.json` (version `1.0.7-ref.1`, 344 clés, SHA-256 `2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c`) ; test d'empreinte.
- Passer à `plan('seance')` les items modulés (avec `koachVolume` de `Planification.appliquer`) ; toute transformation de l'application qui change `sets` avant Koach garde `koachVolume` = servies − écrites ; `manquees` et `reste_semaine` à l'écrit du programme.
- `koach.retour_gradue` d'un groupe majeur ou `allegement` n'est plus émis : la garde `koachGardeSeance` peut couvrir tous les rôles (une ligne absente du servi sans raison de douleur, test reporté, séance bornée, endurance ou rampe tendineuse n'est jamais un choix de Koach 1.0.7) ; afficher `koach.ajout_borne` (texte dans `koach_textes.dart`).
- Un seul `prescrire` compté par séance ; l'aperçu reste sur une copie du moteur. Réactivation après l'arrêt d'urgence : point 3 du prompt KB4.

## 8. Limites et recommandations au pilotage

1. **Valider KM5** : `kalis_adapt` 1.0.6 (Koach 1.0.7), `kalis_bench` 0.5.8 ; 0 violation (nouvelle et ancienne définition), 0 série ou item retiré sous l'écrit par la rampe, 0 coupe silencieuse, en Dart et en Python ; critères sans recul ; puis KB4.
2. Crédits de groupes (lot KS) : toujours recommandé, moins urgent (ils ne coupent plus rien).
3. Montée du vrai test hors du plan (M4) et tenues bras tendus (M1 de KM4) : à surveiller.
4. Critère 4 à 92,03 % (bande 88-92) : sous le bruit.
