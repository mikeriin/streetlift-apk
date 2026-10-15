# Livraison KM2c1 — KM2 correction 1 : Koach 1.0.2 en Dart (`kalis_adapt` 1.0.1)

Lot KM2c1 du pipeline CP (méthode Koach, `CAHIER_KM.md`, décisions C13.12, C13.13, C17), voie A, session Opus 5.5
effort maximal, le 15/10/2026 (15:29 → 19:00 UTC). Prompt : `prompts/KM2c1.txt` ; contexte : `LANCEMENTS.md`,
section KM2c1. Lot sans panel ni relecture documentée (C13.3) ; validation automatique par le pilotage.

**En une phrase** : le delta de méthode de la référence Koach 1.0.2 (KM1c2) est porté en Dart à l'identique — parité
sur les 14 fixtures régénérées, traces comprises ; la campagne Dart sur six graines (4 320 saisons, Koach complet)
redonne exactement les critères de la référence Python, le banc adversarial aussi (cinq jeux, critère 7 bis porté) ;
0 violation de sécurité ; API inchangée.

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.1 | `etiquettes/kalis_adapt-v1.0.1` | Koach 1.0.2 (`lib/src/koach/`), asset `assets/koach/koach_params_1_0_2.json` (`1.0.2-ref.1`, 322 clés, SHA-256 `211c9361…f5da`), `CONTRAT.md` § K, `docs/INTEGRATION_KM3.md` (§ 3 et note de mise à jour) |
| `kalis_bench` | 0.4.2 | `etiquettes/kalis_bench-v0.4.2` | critère 7 bis (`kmCritereApparie`), campagne avec `prevu_jour`, `observe`, `couverture_paires` (comme `campagne.py` 1.0.2), `docs/CRITERES_KM2C1.md`, données `docs/data/km2c1/` |

`kalis_core` et `kalis_plan` inchangés ; rien dans l'application. `moteurs` : e502e963.

### 1.1 Delta porté (`reference/CHANGEMENTS_1_0_2.md`, sections A à C)

- `seance.dart` : reprise par paliers mesurés (`plan['reprise']`, `reprise_plafond` calculé une fois par ligne,
  `palier_franchi` posé par `serieFaite`, série d'index ≥ 1 demandée avant la première bornée comme une première
  série), `_bornesHausse(…, gel:)` avec repli sur le dernier passage un jour gelé sans barre récente, ancre « dernier
  passage » réservée à la douleur, test adaptatif et bras d'intensité coupés en reprise, test xRM du jour d'épreuve
  sous le palier des barres, `_palierBarres` (palier selon la note), ouverture des tentatives plafonnée par ce palier,
  un cran après une barre dite facile, `Memoire.barres` et `barresRatees` remplies par `fermer`.
- `planification.dart` : dispersion des trajectoires des cibles chargées (`dispersion_echeance`, montée en
  `dispersion_echeance_semaines`) ; `previsions[].prevu_jour`.
- `modele.dart` : `capacite(exId, brut:)` et `intervalle_echelle` ; `dual.dart` : variance brute aux deux mises à
  jour bayésiennes ; `rupture.dart` : quatre bornes d'import.
- Paramètres, version du moteur et du fichier `1.0.2-ref.1` (`parametres.dart`).

### 1.2 Tests

- Parité (`test/koach_parite_test.dart`) : `numerique`, `moteur_1` à `moteur_11` (dont la nouvelle fixture de reprise
  et de tentatives après 12 jours de coupure), `planification_1` et `_2` : verts à 1e-9, traces comprises.
- Façade, textes, propriétés, validateur, paramètres : repointés vers `reference/fixtures/` et
  `reference/params/koach_params_v1.json` ; copies figées de 1.0.1 (`reference/fix_dart/`, `koach_params_d1.json`)
  supprimées. Le test de propriétés « garde-fous sur les journaux perturbés » suit la règle A.2 de 1.0.2 : sous
  douleur, jamais au-dessus du dernier passage de l'exercice ; un jour de bilan bas sans douleur, première série au
  plus celle de la dernière séance du même schéma et charge gelée d'une série à l'autre (l'ancien invariant « bilan
  bas → dernier passage » était celui de 1.0.1 et a échoué sur 20 entrées, comme attendu).
- `kalis_bench` : fixtures `test/fixtures/km2/` régénérées (`fixtures/generer_banc_km2.py`), cinq saisons complètes
  avec toutes les extensions identiques à la référence ; évaluation de `adv-7ee0da71` (1.0.2 : 0,950 contre 0,814) ;
  critère 7 bis comparé à la sortie Python sur les mêmes lignes.

## 2. Mesures (`kalis_bench` `docs/CRITERES_KM2C1.md`)

Campagne Dart, graines 0 à 5, 4 320 saisons, 0 plantée, déterminisme vérifié. Les critères 1 à 4, 6 et 7 sont égaux à
la décimale publiée à ceux de la référence Python sur les mêmes saisons (`criteres_km1c2.json`) ; le critère 5 (mesure
de C13.13.1) recalculé sur les saisons Dart par `banc.calibration_grappes` est identique champ pour champ.

| Critère | Seuil | Koach 1.0.1 Dart (KM2) | Koach 1.0.2 Dart (KM2c1) |
| --- | --- | --- | --- |
| 1 erreur d'e1RM au rang 6 | < 3 % (écart documenté, C13.11.1) | 3,95 % | 3,92 % |
| 2 mauvais jour isolé | < 1 % | 0,95 % | 0,91 % |
| 3 convergence sous 3 % | ≤ 11,98 séances | 5,25 | 5,28 |
| 4 couverture à 90 % | 88-92 % | 93,2 % | **89,96 %** |
| 5 calibration (C13.13.1) | biais ± 5 points ; écart max < médiane d'un modèle parfait | 15,3 points (ancienne mesure) | biais +0,2 point ; 16,8 contre 21,2 : **tenu** |
| 6 jour J | ≥ 0,9324 | 0,9459 | 0,9450 |
| 7 pire cas adversarial | ≥ témoin (0) | 0,226 | 0,499 (pire des jeux connus) |
| 7 bis apparié (C13.13.2, portage) | ≥ 90 % ; aucun sous − 0,10 | 10/24 sur b3000 | KM1 24/24, b300 23/24, complet 22/24 ; b3000 20/24 (2 sous) |
| 8 sécurité | 0 | 0 | 0 |
| 9 parité | 1e-9 | tenue (13 fixtures) | tenue (14 fixtures) ; campagne et adversaires identiques à Python |
| 10 rejeu du journal | avant la bascule | — | — |
| 11 temps (VM Dart) | ≤ 10 s ; ≤ 50 ms | 0,21 s ; 21,5 ms | 0,127 s ; 12,7 ms |

Indicateur suivi (C13.13.2) : recherche neuve de KM1c2 contre 1.0.2, 17/24 au niveau du témoin, 6 sous le plancher
(pire écart −0,303) — identique en Dart ; c'est l'objet de KM1c3.

## 3. Relecture indépendante (sous-agent Opus)

- **B1 (bloquant, corrigé)** : moyenne de `frais[:, e, :]` — numpy réduit séquentiellement quand un seul exercice
  est suivi avec plusieurs plans candidats (mise en mémoire avec l'axe des plans le plus rapide) ; le Dart sommait par
  paires. Écart d'un ulp, sous la tolérance des fixtures, mais capable de faire basculer une trajectoire. Corrigé
  comme `_plProgression` (vérifié bit à bit sur numpy : 0 écart sur les 256 lignes de `planification_1`).
- **M1 (corrigé)** : `campagne.dart` ne publiait pas `prevu_jour`, `observe`, `couverture_paires` (ajoutés à
  `campagne.py` par KM1c2).
- m1 (corrigé) : invariant de bilan bas indexé par exercice et étendu aux séries suivantes ; m2 (corrigé) :
  commentaire déplacé.
- **m3 (signalé, non modifié)** : dans la référence comme en Dart, `BORNES` admet `mesure.defaut_modele_sd` = 0 mais la
  règle générique des clés `_sd` (strictement positives) le refuse à l'import. Sans effet sur le moteur livré
  (0,010) ; à trancher dans KM1c3 (borne basse > 0 ou exception, dans les deux langages).

## 4. Contrôle

Contrôle complet sur `claude/ci-cp-a`, run 38777545635 (commit 01d46b69, arbre identique à `moteurs` e502e963) : vert — kalis_core 328 tests, kalis_plan 305, kalis_adapt 326, kalis_bench 179 (banc complet compris), kalis_quest 162, outils Python. Contrôles
de mise au point : commits « KM2c1 contrôle (dev) » à arbre réduit (runs 38762512163, 38766161412, 38776157744).

## 5. Limites et suites

- Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : compilation, tests et campagnes faits en CI.
- Incident : une copie du commit livré poussée par erreur sur `cp-sauvegardes/KM2c1-candidat` (arbre avec `.github/`)
  a déclenché le workflow de build APK (run 38777553043, annulé aussitôt, aucune publication) ; la suppression de
  la branche est refusée par le dépôt (403) — branche inerte, à supprimer par le propriétaire s'il le souhaite.
- Critère 1 en écart documenté (C13.11.1), critère 7 bis non tenu sur b3000 et sur la recherche neuve : KM1c3
  (estimation sous notes non fiables) avant la bascule ; critère 10 à la bascule.
- KM3 peut monter de `kalis_adapt` 1.0.0 à 1.0.1 sans changement de code d'intégration (asset de paramètres à
  remplacer, `docs/INTEGRATION_KM3.md`).
- Recommandation au pilotage : valider KM2c1 comme portage de Koach 1.0.2 et lancer KM1c3 (C17.5).
