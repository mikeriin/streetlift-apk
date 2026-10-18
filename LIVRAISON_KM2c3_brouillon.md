# Livraison KM2c3 — Portage Dart de Koach 1.0.5 : `kalis_adapt` 1.0.4, `kalis_bench` 0.5.6

Lot KM2c3 du pipeline CP (KM2 correction 3 ; portage à oracle exact, C13.9 ; décisions C13.3, C17.17.3, C17.23, C17.26, C17.27 ; prompt `prompts/KM2c3.txt`), voie A, session Opus 5.5 effort maximal (cse_01RgefQJuvkg7SCNCJUPJrgt), du 17/10/2026 23:21 UTC au 18/10/2026 __FIN__ UTC. Lancement : message sans ligne « Lot : » ; KM2c3 seul lot moteur « à faire ». Outil `add_repo` absent de la session ; accès en écriture vérifié par `git push --dry-run` (nouvelle référence) puis par le push de la ligne « en cours ». Pas de SDK Dart dans la session : compilation, format, analyse, tests et campagnes sur la CI (`claude/ci-cp-a`, commits « KM2c3 contrôle (dev) », méthode de KR1 et KM1c4). Clé des références non lue (aucune référence privée nécessaire). Lot sans panel ni relecture documentée (C13.3). Sous-agents sur Opus (port des tests, relecture indépendante) ; sauvegardes sur `cp-sauvegardes/KM2c3`.

**En une phrase** : le Koach que servira l'application (`kalis_adapt` 1.0.4, Dart) est désormais exactement la référence 1.0.5 — sur les 90 600 saisons du couple `kalis_plan` 0.4.2 × Koach 1.0.5, chaque saison simulée en Dart est identique, champ par champ, à la saison de la campagne Python de KM1c4, les six jeux d'adversaires aussi — et le critère dur C17.17.3 est tenu **par le moteur Dart** : 0 violation du critère 7, 0 saison plantée ; critère 11 sur la VM Dart : 0,206 s par replanification, 32,0 ms par série au pire.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.4 (Koach 1.0.5, `koachVersion` `1.0.5-ref.1`) | `etiquettes/kalis_adapt-v1.0.4` | `lib/src/koach/` : `securite.dart`, `seance.dart`, `modele.dart`, `rupture.dart`, `parametres.dart` ; asset `assets/koach/koach_params_1_0_5.json` ; `lib/koach_textes.dart` (deux textes neutres) ; `lib/src/sim/truth.dart` (modèle de vérité) ; tests repointés et nouveaux ; `reference/fix_dart/` et `reference/params/koach_params_d4.json` supprimés ; fixtures complémentaires `test/fixtures/km2c2/` régénérées ; documents (`CHANGELOG.md`, `CONTRAT.md` K.1 et K.5, `docs/INTEGRATION_KM3.md`, `reference/PORTAGE_DART.md`, corrections d'en-tête de `reference/CONTRAT_1_0.md`, `CHANGEMENTS_1_0_5.md`, `README.md`) |
| `kalis_bench` | 0.5.6 | `etiquettes/kalis_bench-v0.5.6` | tests et CLI km2 sur `koach_params_v1.json` ; fixtures `test/fixtures/km2/` régénérées (4 changent) et trois saisons ajoutées ; `tool/km2c3_comparer.py` ; `docs/CRITERES_KM2C3.md`, `docs/data/km2c3/` |

`kalis_core`, `kalis_plan` (0.4.2) et la référence Python (`reference/koach/`, `reference/banc/`, paramètres, fixtures) inchangés ; seuls changent, dans `reference/`, la liste des saisons de `fixtures/generer_banc_km2.py` (trois ajoutées, fixtures du banc Dart) et des documents (§ 6). `moteurs` : __MOTEURS__ ; contrôle complet `claude/ci-cp-a` : run __RUN__ (arbre identique). Rien dans l'application (intégration : KB1).

## 2. Portage (delta 1.0.4 → 1.0.5, `PORTAGE_DART.md`)

Ligne pour ligne, mêmes opérations flottantes dans le même ordre :

- `securite.dart` : `episode`, `sensible`, `sensibles`, `geneRecente` ; règle 4 dans `conduite`, après le bloc « gêne depuis la dernière séance » et avant `recente` (première raison retenue, comme la référence).
- `seance.dart` : état `ecritZone`, `budgetSemaine`, `rampeZone`, `retourZone`, `manqueZone`, `expoJour`, `reserveEchauffement` ; `_semaineDeCharge`, `_compterEcritZone`, `_compterManqueZone`, `_manqueRecent`, `_budgetZoneSemaine` (remplace `_budgetReprise`), `_habitudeAvant`, `_departRetour`, `_budgetRetour`, `_entrerRetour`, `_budgetsZoneJour` ; `ouvrir` (zones sensibles triées, puis zones en retour, suspendues en semaine verrouillée), `prescrire` (écrit par zone, entrée en retour, permis du jour, réserve d'échauffement, porte du vrai test), `_item` (permis appliqué à tout item, échauffement borné par sa réserve, retrait seulement sur zone épuisée), `fermer` (`expoJour`). `Seances._semaine_connue`, appelée nulle part dans la référence, n'est pas portée. Ajout hors référence : `Seances.appelsVraiTest` (journal des exercices pour lesquels la porte de `prescrire` consulte `_vraiTest`), lu par les tests à la place de l'espion de la référence ; il n'entre dans aucun résultat.
- `modele.dart` : `elargir(part)` (λ borné à [0 ; 1], toutes les branches, lignes puis colonnes × (1 − λ), bloc des composantes ÷ (1 − λ), + λ·v0).
- `rupture.dart` : `elargissement_vers_a_priori` (défaut 0,25, borne [0 ; 1]), action `{'action': 'elargir', 'part': part}`.
- Paramètres : asset `koach_params_1_0_5.json`, copie à l'octet près de `reference/params/koach_params_v1.json`, `1.0.5-ref.1`, SHA-256 `d8a492b7…f26d`, **345 clés** (6 à la racine, 339 dans les sections). L'en-tête du contrat, `CHANGEMENTS_1_0_5.md`, `PORTAGE_DART.md` et `README.md` de la référence écrivaient 346 (6 + 340) : 1.0.4 en avait 338 (6 + 332), plus 7 = 345 ; corrigé dans ces documents (le fichier n'a pas changé).
- **Écart à `PORTAGE_DART.md`, voulu** : `rupture.elargissement_rien_de_special` n'est PAS retirée du fichier, de l'asset ni des bornes. La retirer change le fichier de paramètres de la référence, dont le SHA-256 est inscrit au contrat et vérifié par les fixtures de parité (`sha256_fichier_parametres`), et le prompt exige un asset de même SHA-256 que la référence et interdit de toucher la référence. Elle est gardée, comme dans la référence (« gardée pour les validateurs »), dans les défauts et les bornes du Dart ; le code ne la lit plus ; le validateur l'admet sans l'exiger (test). Son retrait est à faire dans un lot KM qui change la référence.
- Modèle de vérité (`truth.dart`) : `_painKnown = false` au début d'un épisode de la fiche (`advance`) et d'un épisode tendineux (`endWeek`), comme `banc/verite.py` ; `SimAthlete.painKnown` (lecture) et `setForTest` ; `test/km2c3_verite_test.dart` (échoue sans la correction : le drapeau restait vrai).
- Textes (`koach_textes.dart`, relecture M2) : `koach.reprise_dose` et le retrait `reprise_dose` étaient écrits pour une reprise « après douleur » ; depuis 1.0.5 ils servent aussi la rampe de retour après une coupure, sans douleur connue : « Retour progressif : séries limitées sur … pour ménager … » et « Je retire … : la dose du jour pour … est atteinte (retour progressif). ». Codes et paramètres inchangés.

## 3. Parité

| Mesure | Résultat |
| --- | --- |
| 15 fixtures de la référence (`reference/fixtures/`, traces comprises) et 3 complémentaires (`test/fixtures/km2c2/`, régénérées avec 1.0.5) | parité 1e-9, `koach_parite_test` vert (runs A, B, D) |
| 23 tests de `reference/tests/test_km1c4_douleur.py` portés en Dart (`test/koach_km1c4_douleur_test.dart` : zone sensible, budgets, prorata, réserve d'échauffement, sortie progressive, arrêt levé, semaines manquées, règle 3 bis, règle 4, rejeu) | 23 verts, mêmes valeurs que la référence |
| Banc : 10 saisons entières (`kalis_bench/test/fixtures/km2/`, dont les trois ajoutées : `autres_08` référence b 47, `ks_01` douleur à l'épaule b 38, `street_03` séances manquées b 57, qui portent la zone sensible sans arrêt, la sortie progressive et la rampe de retour) | identiques (séries, estimations, items servis, journaux, états, sécurité) |
| **Campagne entière : 90 600 saisons Dart contre les 90 600 saisons de la campagne Python de KM1c4** (run 39041787498, une saison par fichier ; `tool/km2c3_comparer.py`, dictionnaire complet de chaque saison, flottants à 1e-9) | **90 600 identiques**, 0 différente, 0 manquante |
| Critères 1 à 7 et secondaires (graines 0-5) | identiques au fichier de critères Python de KM1c4 |
| Six jeux d'adversaires (critères 7 et 7 bis) | 0 écart, adversaire par adversaire, avec la référence recalculée sur la CI (run 39090980389) |

Deux champs exclus de la comparaison des saisons, justifiés : `duree_s` (temps machine) et l'ordre de `first_under`, comparé trié (la référence le remplit en parcourant un ensemble Python dont l'ordre dépend du hachage des chaînes, aléatoire d'un processus à l'autre ; les critères n'en lisent que les valeurs). Une première comparaison, sans ces exclusions, donnait 90 600 saisons « différentes » sur ces seuls champs.

Couverture du delta par les 15 fixtures (mesurée en Python, traceur de lignes sur la référence) : `elargir` n'est exécuté par aucune ; plus de 50 lignes de `seance.py` non plus (sortie progressive, arrêt levé, recherche arrière, zone épuisée, réserve d'échauffement…). D'où le port des 23 tests, les trois saisons du banc ajoutées et la comparaison des 90 600 saisons, qui exécutent ces branches (`elargir` : réponses « rien de spécial » répétées des saisons du banc `ks_test_ppl6` séances manquées et `street_03` b 57, et branche « mauvais jour » par `test/koach_elargir_test.dart`).

## 4. Campagne Dart : sécurité du couple servi (critère dur C17.17.3)

34 profils × 100 graines × 3 modèles de vérité × scénarios, Koach complet, saisons de `kalis_plan` 0.4.2, témoin 0.3.1 relu ; 34 parts (17 groupes de six graines × 2) ; 129 627 s de calcul cumulé (la campagne Python : 1 137 000 s), 2 h 38 de bout en bout (run 39080556198). `kalis_bench/docs/CRITERES_KM2C3.md` § 2, `docs/data/km2c3/securite/`.

| Mesure | KR1 (0.4.1 × 1.0.4, Dart) | KM1c4 (0.4.2 × 1.0.5, Python) | **KM2c3 (0.4.2 × 1.0.5, Dart)** |
| --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | **0** |
| **Critère 7** | 63 | 0 | **0** (graine 0 : 0 ; graines 0-5 : 0) |
| « Retour à l'écrit » (à part) | 45 046 | 50 828 | 50 828 |
| Réalisée appariée (indicateur) | 259 646 | 238 906 (61 095 saisons) | 238 906 (61 095 saisons) |
| Réalisée contre le plan initial | 634 325 | 581 363 | 581 363 |
| Plan initial de `kalis_plan` | 0 | 0 | 0 |

## 5. Critères du cahier KM (graines 0-5, Dart)

| Critère | Seuil | **KM2c3 (Dart)** | Référence (KM1c4, Python) |
| --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart accepté) | 3,67 % (témoin 5,83 %) | identique |
| 2 mauvais jour isolé | < 1 % | 0,88 % (n 36) | identique (0,008841 ; `LIVRAISON_KM1c4.md` § 4 écrit 0,81 % : ce n'est pas la valeur du fichier de critères) |
| 3 convergence sous 3 % | ≤ témoin 11,00 | 4,83 | identique |
| 4 couverture à 90 % | 88-92 % | 91,94 % | identique |
| 5 calibration | indicateur (C17.13.2, C17.26.3) | mesure du critère (une prévision par cible) : écart max 8,8 pts < q90 d'un modèle parfait 24,3 ; biais +4,4 pts ; mesure KM1 (décile 7) 25,9 pts | identique |
| 6 jour J | ≥ témoin 0,9154 | 0,9339 | identique |
| 7 sécurité / pire cas adversarial | 0 / ≥ témoin | 0 / 0,450 | identique |
| 7 bis (6 jeux, tenus sur 24) | ≥ 90 %, aucun sous −0,10 | 24, 22, 18, 23, 22, 21 | identique |
| 8 / 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | **0,206 s ; 32,0 ms** (`observe` max 31,9 ms, médiane 0,64 ; plan de séance max 1,2 ms) | — (KR1 Dart : 0,242 s ; 26,6 ms) |

**Critère 5 et son bruit (C17.26.3)** : calibration par grappes sur chacun des 17 groupes de six graines (`docs/data/km2c3/critere5/`). Écart maximal : 0,088 à 0,350, moyenne 0,189, **écart-type 0,071** ; sous le q90 d'un modèle parfait dans les 17 groupes ; le groupe 0-5 (celui du critère) est le plus bas des 17 : sa valeur seule n'est pas représentative. Biais prévu − observé (P ≥ 10 %) : **positif dans 15 groupes sur 17**, moyenne +4,9 points (erreur-type 1,2), hors de ± 5 points dans 8 groupes : Koach surestime un peu ses chances de réussite à quatre semaines de l'échéance. Comportement de la référence 1.0.5 (Dart identique), pas du portage ; indicateur pour un futur lot de calibration.

**Fichiers d'adversaires de KM1c4** : `reference/donnees/comparaison_adversaires_km1c4_<jeu>.json` ne sont pas ceux de la référence finale (ils donnent 19 tenus sur `km1c3` et −0,238 sur `km2_b3000`, les chiffres « sans la règle 3 bis ») ; la référence finale, relancée localement et sur la CI, donne les chiffres que KM1c4 a publiés (24, 22, 18, 23, 22, 21), et le Dart lui est identique. Les comparaisons recalculées sont dans `kalis_bench/docs/data/km2c3/comparaison/` ; remplacer les fichiers de `reference/donnees/` revient au prochain lot qui touche la référence.

## 6. Relecture indépendante, contrôles, taille, limites

- **Relecture indépendante** (sous-agent Opus, delta Python contre portage, fonction par fonction ; sonde Python) : **0 bloquant**. Majeurs : M1 fichiers nouveaux à committer (fait) ; M2 textes de raison trompeurs pour la règle 3 bis (corrigés, § 2). Mineurs : m1 test du vrai test peu discriminant (journal `appelsVraiTest` ajouté, les deux tests comparent maintenant la liste des appels à celle de la référence) ; m2 documents de la référence incohérents (345 clés, clé gardée : corrigés et consignés) ; m3 journaux des versions (faits) ; m4 cas limites sans effet sur la parité (identité de liste Python, `reste_semaine` nul, paramètre non entier inatteignable : section `securite` figée à l'import) — dits, non changés.
- **Contrôles de mise au point** (`claude/ci-cp-a`) : run 39079886275 (A : compilation, parité, banc ; deux corrections : import, nombre de clés), 39080305867 (B : 23 tests portés verts), 39081202129 (D : après relecture, 10 saisons du banc ; la version écrite dans `docs/PROPRIETAIRE.md` corrigée ensuite), 39080556198 (C : campagne, adversaires), 39090980389 (E : comparaisons). Contrôle complet : run __RUN__ sur l'arbre de `moteurs` __MOTEURS__.
- **Tests Python de la référence** : 297 verts en session (Python 3.13, numpy 2.5.3), dont `test_km1c4_douleur.py`, `test_kr1_violations.py`, `test_rupture.py`, `test_documents.py`, `test_fixtures.py` ; fixtures de la référence et du banc vérifiées à jour (`generer.py --verifier`, `generer_banc_km2.py --verifier`, `generer_km2c2.py --verifier`).
- **Taille de l'arbre de `kalis_adapt`** : 31,49 Mo (fichiers suivis) contre 40,5 Mo après KM1c4 et 31,1 Mo après KR1. Les copies figées (9,0 Mo) sont retirées ; les 0,4 Mo de plus que KR1 viennent de KM1c4 (données de référence régénérées sur `kalis_plan` 0.4.2 : +0,21 Mo ; tests et documents de la référence : +0,1 Mo) et de ce lot (tests portés et fixtures complémentaires : environ +0,1 Mo). Ce que KB1 copie dans l'application (C17.19.3) : `lib/` (1,28 Mo) et `assets/koach/` (0,83 Mo), soit 2,1 Mo.
- **Limites** : (a) `elargissement_rien_de_special` gardée (§ 2) ; (b) le critère 5 reste un indicateur, avec un biais positif systématique entre groupes (§ 5) ; (c) les limites de méthode de KM1c4 (C17.26.4 : douleur silencieuse pendant une absence courte ou voulue ; tolérance du modèle de vérité qui ne décroît pas sans exposition) valent pour le Dart à l'identique ; (d) `first_under` : l'ordre de la référence dépend du hachage Python (sans effet sur aucun critère ; à trier dans la référence si un jour un critère en lisait l'ordre).

## 7. Ce que KB1 doit copier dans l'application (C17.19.3 : Dart et assets seulement)

- `packages/kalis_adapt/lib/` et `packages/kalis_adapt/assets/koach/` de l'étiquette `etiquettes/kalis_adapt-v1.0.4`, à l'octet, avec `pubspec.yaml` ; jamais `reference/`, `test/`, `tool/`, `docs/`.
- Asset de paramètres : `assets/koach/koach_params_1_0_5.json` à la place de `koach_params_1_0_4.json` (version `1.0.5-ref.1`, 345 clés, SHA-256 `d8a492b7debca0e4a504ed399efee0a8a6e4e003ab99f7cbb7f49c114bfbf26d`) ; mettre à jour la déclaration dans `pubspec.yaml`, le chemin lu par `rootBundle` et le test d'empreinte de l'application (`docs/INTEGRATION_KM3.md` § 3, mis à jour).
- API, schéma du journal et codes de raison inchangés : aucun code de l'application à changer pour le moteur ; deux textes de raison changent (`koach_textes.dart`) ; un journal existant rejoué donne les décisions de 1.0.5 (une valeur de paramètre et sept clés nouvelles).
- Avec `kalis_plan` 0.4.2 (KS1c2), le couple monté est exactement celui mesuré ici.

## 8. Recommandations au pilotage (C8)

1. **Valider KM2c3** : `kalis_adapt` 1.0.4 (Koach 1.0.5 en Dart, identique à la référence sur les 90 600 saisons et les six jeux d'adversaires), `kalis_bench` 0.5.6 ; critère dur C17.17.3 tenu par le moteur Dart (0 violation, 0 saison plantée) ; critère 11 tenu (0,206 s ; 32,0 ms).
2. **KB1** : monter `kalis_adapt` 1.0.4 et `kalis_plan` 0.4.2 (§ 7), puis le critère 10 sur un export neuf avant d'ouvrir la bascule.
3. Au prochain lot qui touche la référence : retirer `elargissement_rien_de_special` (fichier, défauts, bornes, des deux côtés) ; remplacer les `comparaison_adversaires_km1c4_*.json` périmés ; regarder le biais positif du critère 5 (+4,9 points en moyenne sur 17 groupes) si un lot de calibration est ouvert.
