# Livraison KR1 — Koach sur `kalis_plan` 0.4.1 : données de référence et campagne du couple (`kalis_adapt` 1.0.3, `kalis_bench` 0.5.3)

Lot KR1 du pipeline CP (méthode Koach ; décisions C13.3, C17.12, C17.13, C17.16, C17.17, C17.18 ; prompt `prompts/KR1.txt`), voie A, session Opus 5.5 effort maximal, le 16/10/2026 de 12:00 à __FIN__ UTC. Lancement : message sans ligne « Lot : » ; KR1 seul lot moteur « à faire ». `add_repo` absent de la session ; accès en écriture vérifié par `git push --dry-run` puis par le push de la ligne « en cours ». Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : mise au point, campagnes et contrôle sur la CI (`claude/ci-cp-a`). Clé des références non lue (aucune référence privée nécessaire). Lot sans panel ni relecture documentée (C13.3) ; validation par le pilotage.

**En une phrase** : les données de référence de Koach sont régénérées sur `kalis_plan` 0.4.1 et étendues aux 34 profils (la saison du banc est de nouveau exactement celle que lit Python), le couple réellement servi (`kalis_plan` 0.4.1 × Koach complet) est mesuré sur 90 600 saisons (34 profils, 100 graines, trois modèles de vérité, tous les scénarios) ; la campagne a trouvé un défaut de Koach — des réponses « rien de spécial » répétées faisaient diverger l'incertitude jusqu'à planter la séance (8 saisons sur 5 436) —, corrigé à la source (Koach 1.0.4, référence et Dart, parité 1e-9) ; sur les saisons racontées (graine 0) et sur les graines 0 à 5 le couple fait 0 violation, mais sur toutes les graines il reste **63 violations du critère 7 (59 poussées de douleur, 4 aggravations, 25 saisons sur 90 600)**, dont les causes sont établies et reproduites par des tests : elles relèvent de la conduite sous douleur de Koach (méthode), que ce lot ne change pas ; **le critère dur de la bascule n'est pas tenu** ; décision requise (§ 7).

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.3 | `etiquettes/kalis_adapt-v1.0.3` | Koach 1.0.4 (référence Python et Dart) : élargissement « rien de spécial » plafonné à l'a priori ; asset `koach_params_1_0_4.json` (`1.0.4-ref.1`, mêmes valeurs, SHA-256 `2d023854…9016`) ; données de référence régénérées (34 profils) ; fixtures régénérées ; `reference/CHANGEMENTS_1_0_4.md`, note datée du 16/10 au contrat |
| `kalis_bench` | 0.5.3 | `etiquettes/kalis_bench-v0.5.3` | exports et campagne de Koach sur 34 profils ; égalité stricte saison vivante = saison lue par Python ; vues de sécurité « réalisée » et « réalisée appariée » ; correction du classement « retour à l'écrit » après un bloc interrompu ; outils `tool/kr1_securite.py`, `tool/kr1_comparer.py` ; `docs/CRITERES_KR1.md`, `docs/data/kr1/` (dont les saisons figées sur 0.3.1, sorties de `kalis_adapt`) |

`kalis_core` et `kalis_plan` inchangés (aucune violation n'a sa cause dans `kalis_plan` 0.4.1 : pas de 0.4.2). `moteurs` : __COMMIT__ ; contrôle complet `claude/ci-cp-a` : run __RUN__ (arbre identique). Rien dans l'application. Arbre de `kalis_adapt` : 29,6 → 31,1 Mo (C17.19.3 : marge de 3,5 Mo ; les saisons figées sont placées dans `kalis_bench`, que l'application ne copie pas).

## 2. Données de référence régénérées (point 1)

- `kalis_bench` `bin/km1.dart` sur `kalis_plan` 0.4.1 : `reference/donnees/reference/` et `temoin/` (34 profils, 302 saisons ; témoin 0.3.1 sur 16 graines), `securite_dart.json.gz` (302 saisons, 0 constat). Catalogue et traces du modèle de vérité : identiques à l'octet. Le test de sécurité de la référence n'a plus d'exception connue : la hausse de volume de `street_06` (changement de discipline) de 0.3.1 a disparu avec la troncature de KS1c1.
- Les saisons figées sur 0.3.1 (historique des mesures KM1 à KM2c2) sont dans `kalis_bench/docs/data/kr1/saisons_figees_0_3_1/` (`--saisons-figees` les relit).
- Parité : `kalis_bench/test/km2_banc_test.dart` compare la saison vivante (`kmReferenceSeason`) à la saison lue par Python **à l'égalité stricte** (avant : squelette seulement) ; 7 saisons du banc rejouées contre la référence (dont `ks_test_ppl6` sur quarante semaines et `autres_08` après un bloc interrompu), sécurité de la saison comprise ; 15 + 3 fixtures de Koach, traces comprises : vertes. La campagne Dart (graines 0-5, 34 profils) redonne les critères de la campagne Python sur les mêmes saisons ; 20 saisons tirées au hasard sont identiques champ pour champ (seul l'ordre des « premiers passages », un `set` Python, diffère ; l'outil de comparaison les lit comme multiensemble).

## 3. Correction de Koach 1.0.4 : élargissement plafonné (point 3)

**Constat** : première campagne du couple (Koach 1.0.3, graines 0-5) : 8 saisons plantées, toutes `ks_test_ppl6`, séances manquées (`NaN` dans `Seances._cibleTenue` en Dart, `OverflowError` en Python). **Cause** : l'utilisateur simulé répond « rien de spécial » à 15 diagnostics en quarante semaines ; chaque réponse multipliait la variance de toute capacité par 4, sans borne (écart-type de ln capacité 0,36 → 20). Un utilisateur réel le déclencherait de même.

**Correction** (`modele.elargir`, `variances_a_priori` ; Dart à l'identique) : variance de chaque composante de capacité = min(4·v ; max(v ; v0)), v0 son a priori de population (« réapprentissage rapide » : jamais plus incertain qu'un athlète inconnu). 0 saison plantée sur 90 600 ; écart-type maximal 0,41 sur la saison qui plantait. **Limite (relecture, M1)** : élargissement par composante ; quand une partie seulement des composantes d'une capacité est plafonnée, sa variance est multipliée par un facteur entre 1 environ et plus de 4 (0,987 à 18,6 mesuré sur les saisons de quarante semaines) ; écart-type borné. Un élargissement uniforme borné est une question de méthode (§ 7).

Tests : `reference/tests/test_rupture.py` (trois tests, dont un a posteriori réel), `kalis_adapt/test/koach_elargir_test.dart`, fixture du banc `ks_test_ppl6` (15 élargissements).

## 4. Campagne du couple (point 2) : violations

`kalis_bench` `docs/CRITERES_KR1.md` § 1, `docs/data/kr1/securite/`.

| Mesure | Toutes graines (90 600) | Graine 0 (saisons racontées, 906) | Graines 0-5 (5 436) |
| --- | --- | --- | --- |
| Saisons plantées | 0 | 0 | 0 |
| **Critère 7 du cahier** | **63** (25 saisons) : 59 poussées, 4 aggravations | **0** | **0** |
| « Retour à l'écrit » (C13.10.1, à part) | 45 046 | 76 | 2 236 |
| Réalisée appariée (diagnostic, § 6) | 259 646 (62 401 saisons) | 784 | 12 248 |
| Plan initial de `kalis_plan` 0.4.1 | 0 | 0 | 0 |

**Par profil et scénario (critère 7)** : `autres_08` (CrossFit) 38 poussées, toutes à la graine 47 (sept scénarios) ; `street_03` 13 (séances manquées, vérité b) ; `ks_01` 4 et `ks_03` 4 (douleur à l'épaule ou au coude, graine 38) ; `street_10` 4 aggravations (séances manquées, vérité b). Par modèle de vérité : b 48, c 15, a 0.

**Causes établies** (`kalis_adapt/reference/tests/test_kr1_violations.py` : quatre saisons rejouées, mécanisme vérifié) :

1. **Poussées (59)** : après un épisode douloureux, le modèle de vérité garde la zone « réactive » douze semaines (tolérance ≈ exposition de la dernière semaine ou moitié de l'habitude, au moins 4) ; une semaine qui y expose plus de 1,5 fois la tolérance déclenche une gêne de 2 à 3 sur 10. Koach ne réagit pas à une gêne ≤ 3 (`securite.douleur_seuil`), et l'exposition servie remonte d'un coup dans trois situations : (a) **aucune reprise faute d'arrêt** — `autres_08`, graine 47 : surcharge à l'épaule au 4e jour (pièce de conditionnement), épisode trop court pour un arrêt, puis 7 à 13 séries par semaine sur l'épaule pour une tolérance de 3 à 4 : 7 poussées ; (b) **fin de la reprise graduée** — `ks_01`, douleur à l'épaule, graine 38 : 2-3 séries par semaine en reprise, une semaine à 0, puis 7 séries à la fin de la fenêtre de reprise (84 jours) : 2 poussées ; (c) **retour après des séances manquées** — `street_03`, graine 19 : deux semaines sans exposer le poignet, puis 8 séries : 1 poussée.
2. **Aggravations (4)** : douleur connue de 5 au poignet (tenues, vérité b), Koach monte la charge des dips lestés (sollicitation du poignet 0,5) de 10 à 11,25 kg : sa conduite ne bloque les hausses sur une zone douloureuse qu'à partir de `securite.douleur_moyenne_contrainte` (5) pour une sollicitation moyenne ; le banc compte toute hausse au-dessus de 3.
3. **Hausses de volume (9 mesurées, 0 réelles)** : séance manquée comptée à son volume écrit après un bloc interrompu, mal classée par le banc (indice de semaine sans troncature du bloc) ; corrigé dans `kalis_bench` 0.5.3 (Dart et Python), ce sont des « retours à l'écrit » (C13.10.1). Test `test_retour_a_l_ecrit_apres_un_bloc_interrompu`, fixture du banc.

**Pas de correction dans ce lot pour 1 et 2** : ce sont des règles de méthode de la conduite sous douleur (seuil de gêne, reprise sans arrêt, fin de reprise, hausse sous douleur moyenne), dont chaque changement touche toutes les saisons avec douleur et demande une recherche (modèle de surveillance de la douleur des tendinopathies), une remesure complète (cent graines) et un portage : un lot de méthode Koach (C13.9) plutôt qu'une passe de mesure. Les tests attendent les violations : ils échoueront quand la méthode les retirera.

**Comparaison** : le couple CX (`kalis_plan` 0.4.1 × `kalis_adapt` 0.3.x, KS1c1) comptait 1 331 violations réalisées sur les mêmes 90 600 saisons, toutes définitions du banc confondues ; le témoin 0.3.1 fait 110 poussées sur les saisons appariées des graines 0 à 5 (34 profils), Koach 0 sur les mêmes et 59 sur les 90 600.

**Propositions « volume » de `kalis_adapt` 0.3.x** (`review.dart`, `_upFits`, cause des violations restantes de KS1c1) : hors de ce couple (Koach ne les applique pas) ; KM3 les a retirées de l'application (C17.17.2, C17.19).

## 5. Critères du cahier KM (1 à 8, 11) contre les saisons figées

Graines 0 à 5 ; bruit = écart-type des 17 groupes de six graines (`docs/CRITERES_KR1.md` § 4).

| Critère | Seuil | Figées (27 profils) | Couple (27) | Couple (34) | Bruit | Recul |
| --- | --- | --- | --- | --- | --- | --- |
| 1 erreur d'e1RM | < 3 % (écart accepté) | 3,94 % | 3,83 % | 3,61 % | 0,2 pt | non |
| 2 mauvais jour | < 1 % | 0,87 % | 0,88 % | 0,88 % | 0,25 pt | non |
| 3 convergence | ≤ témoin | 5,28 (11,98) | 5,42 (11,92) | 4,88 (11,01) | 0,3 | non |
| 4 couverture | 88-92 % | 90,21 % | 90,08 % | 91,42 % | 0,9 pt | non |
| 5 calibration | biais ± 5 ; écart max < q90 | −0,6 ; 24,4 < 32,8 | −1,6 ; 18,9 < 30,4 | idem | — | non |
| 6 jour J | ≥ témoin | 0,9449 (0,9324) | 0,9453 (0,9320) | 0,9374 (0,9154) | 0,004 | non |
| 7 pire adversaire | ≥ témoin (0) | 0,450 au plus bas | — | 0,450 au plus bas | — | non |
| 7 bis (6 jeux) | ≥ 90 % ; aucun sous −0,10 | 24, 22, 22, 21, 22 ; 19 | — | 24, 22, 22, 21, 22 ; 20 | — | non |
| 8 sécurité | 0 | 0 | 0 | 0 (graines 0-5) ; **63** (100 graines) | — | — |
| 11 temps | ≤ 10 s ; ≤ 50 ms | 0,335 s ; 9,7 ms | 0,242 s ; 26,6 ms | idem | 6,6 ms (max 39 ms) | dans le budget |

Aucun recul au-delà du bruit. À noter : sur d'autres groupes de six graines, le critère 2 va jusqu'à 1,59 % et le critère 4 jusqu'à 94,0 % : les seuils de 1 % et de 92 % ne sont tenus que sur la mesure du cahier (graines 0 à 5, C13.12).

## 6. Saison réalisée appariée (diagnostic nouveau, à trancher)

Vue `realise_apparie` : la saison réellement faite (séances manquées vidées) contre le plan écrit aux mêmes séances manquées. Elle compte 259 646 hausses de volume par groupe au-delà de la règle du banc (+20 % ou +2 séries sur la meilleure des trois semaines précédentes) dans 62 401 saisons sur 90 600 (784 à la graine 0) : le volume que sert Koach varie d'une semaine à l'autre (prudence, dose, allègements, exercices arrêtés) puis revient vers l'écrit (par exemple : ischios servis 1, 1, 1, 1,5 puis 4 séries pour 5 à 6 écrites). Aucune décision n'en fait un critère ; les poussées de douleur (§ 4) en sont la forme qui compte pour le corps. Une règle « rampe sur le volume réalisé, par groupe et par zone sensible » dans Koach couvrirait les deux (§ 7).

## 7. Recommandations au pilotage (C8) — décision requise

1. **Valider KR1 comme mesure du couple** : `kalis_adapt` 1.0.3 (Koach 1.0.4 : correction de robustesse, aucune valeur de paramètre changée, critères sans recul) et `kalis_bench` 0.5.3 ; données de référence de Koach sur `kalis_plan` 0.4.1.
2. **Critère dur de la bascule (C17.17.3) non tenu** : 0 sur les saisons racontées et sur les graines 0 à 5, 63 sur toutes les graines. Proposition : un lot de méthode Koach (Fable, C13.9 ; « KM1c4 » puis portage) sur la conduite sous douleur et la rampe du réalisé : (a) reprise graduée après tout épisode au-dessus du seuil, même sans arrêt ; (b) pas de saut en fin de reprise (sortie seulement à 100 %) ; (c) exposition hebdomadaire d'une zone sensible bornée par l'exposition réalisée des semaines précédentes (retour après séances manquées compris) ; (d) aucune hausse de charge sur un exercice qui sollicite une zone douloureuse (≥ 0,5) tant que la douleur dépasse le seuil ; (e) élargissement « rien de spécial » uniforme et borné (relecture M1). Remesure sur les 90 600 saisons (critère 7 et vue appariée), jour J et adversaires sans recul. Alternative : faire du critère dur « 0 sur les saisons racontées et les graines 0 à 5 » et suivre les 63 comme indicateur (moins de 0,03 % des saisons ; gênes de 2 à 3 sur 10).
3. **KB1** (ouverture de la bascule) : à lancer après la décision 2 ; `kalis_adapt` 1.0.3 peut remplacer 1.0.2 dans l'application (asset de paramètres à remplacer, `docs/INTEGRATION_KM3.md`).

## 8. Relecture, contrôle, budget

- **Relecture indépendante** (sous-agent Opus, diff complet et code environnant, sondes Python) : 0 bloquant, 3 majeurs, 13 mineurs. M1 (élargissement par composante : variance d'une capacité ×0,99 à ×18,6) : docs corrigées, test sur a posteriori réel, solution uniforme recommandée (§ 7.2 e) ; M2 (vue réalisée dominée par le vidage des séances manquées) : vue appariée ajoutée (Python et Dart), seule publiée comme diagnostic ; M3 (pas de test ni de parité de la vue réalisée) : sécurité ajoutée aux fixtures du banc et comparée en Dart, test Python. Mineurs : docs périmées (contrat K.5, README, `koach.dart`, `PORTAGE_DART.md`, `INTEGRATION_KM3.md`), docstring, outils (NaN, infini, doublons, repli), libellés du CHANGELOG ; traités. Non traités, dits ici : une piste créée tard n'est jamais élargie (écrit au contrat).
- **Contrôle** : mise au point par des commits « KR1 contrôle (dev) » (runs 38898708985, 38906984200, 38932288447, 38947564079) ; contrôle complet run __RUN__ sur l'arbre de `moteurs` __COMMIT__.
- **Incidents** : une publication de mise au point a bloqué la file (assemblage Python sans parts) ; GitHub Actions est resté en file une heure (19:00-19:45 UTC). Les parts de campagne de cent graines restent dans les artefacts des runs (90 jours) ; la branche ne garde que celles des graines 0 à 5.
- Budget (§ 9) : sous-agent sur Opus ; sauvegardes sur `cp-sauvegardes/KR1`.
