# Livraison KM2 — portage Dart : `kalis_adapt` 1.0.0 (Koach 1.0)

Lot KM2 du pipeline CP (méthode Koach, `CAHIER_KM.md`, décisions C13.9 à C13.11), voie A, session Opus 5.5 effort
maximal, du 10/10/2026 21:03 UTC au 11/10/2026. Prompt : `prompts/KM2.txt` ; contexte : `LANCEMENTS.md`, section KM2.

**En une phrase** : Koach 1.0.1 tourne en Dart à l'identique de la référence Python (parité 1e-9 sur les 13 fixtures,
traces comprises ; le banc Dart redonne à la décimale près les critères de KM1 sur 1 440 saisons), avec les crochets
d'extension dans la façade, la référence de planification au journal, le validateur de sécurité côté Dart, les
paramètres en asset versionné et les textes des raisons ; **7 critères du cahier sur 11** tenus sur la mesure élargie à
six graines (8 sur 11 sur les graines de KM1), 0 violation de sécurité, temps très sous les budgets ; deux points
de méthode à trancher par le pilotage (critère 5 à 15,3 points ; banc adversarial élargi).

## 1. Livré

| Paquet | Version | Étiquette | Contenu |
| --- | --- | --- | --- |
| `kalis_adapt` | 1.0.0 | `etiquettes/kalis_adapt-v1.0.0` | Koach 1.0 (`package:kalis_adapt/koach.dart`), validateur (`package:kalis_adapt/validateur.dart`), textes (`package:kalis_adapt/koach_textes.dart`), assets `assets/koach/`, `docs/INTEGRATION_KM3.md`, `CONTRAT.md` § K ; le moteur 0.3.1 reste inchangé dans le paquet |
| `kalis_bench` | 0.4.0 | `etiquettes/kalis_bench-v0.4.0` | meneur et politique Koach, campagne des critères (`bin/km2.dart`), banc adversarial, `docs/CRITERES_KM2.md`, données `docs/data/km2/` |

Contrat de `kalis_adapt` **non additif** (C13.5, seul écart permis) ; `kalis_core` et `kalis_plan` inchangés.

### 1.1 Portage

- `lib/src/koach/` : une bibliothèque à parts (`outils`, `numerique`, `modele`, `securite`, `seance`, `moteur`,
  `planification`, `rupture`, `adherence`, `dual`, `parametres`), noms du Python en `lowerCamelCase`, mêmes clés JSON,
  mêmes opérations flottantes dans le même ordre (`**` → `pow` de la libc ; réductions numpy reproduites :
  sommation par paires, noyau `einsum` à deux voies ; produits BLAS en sommes séquentielles). Conventions :
  `reference/PORTAGE_DART.md`.
- Parité (`test/koach_parite_test.dart`, 27 tests) : `numerique.json` (16 familles), `moteur_1` à `moteur_10` (sortie
  et raisons de chaque `plan`, `posterior()` après chaque fin de séance, de semaine et — `moteur_1` — de série,
  vecteur d'état et diagonale de la covariance, état final, rejeu par `rejouer`), `planification_1` et `_2` (tirages
  du jumeau, tables, évaluation de la référence, ligne de replanification, plan, items modulés). Tous verts à la
  tolérance de 1e-9 ; en pratique les sorties sont identiques, y compris les textes de trace (`fixe` reproduit
  `'%.nf'` de Python, arrondi au pair sur une égalité exacte).
- Mesure de bout en bout : la campagne Dart sur les graines 0 et 1 (1 440 saisons, Koach complet) redonne
  exactement les critères 1, 2, 3, 4, 6 et 7 de `reference/donnees/criteres_km1.json` (3,98 % ; 0,95 % ; 4,856 ;
  90,38 % ; 0,9409 ; 0) ; cinq saisons complètes sont comparées ligne par ligne à la référence (`kalis_bench`
  `test/km2_banc_test.dart`) ; le rejeu des 40 adversaires de KM1 redonne le pire cas publié (0,798913).

### 1.2 Ce que la façade fait de plus (constats M6 et M7 de KM1)

- Crochets appliqués par `plan` lui-même, dans l'ordre des extensions : modulation de la planification, semaine
  allégée, bras de volume d'un essai (interface `AvecItemsDuJour`), bras d'intensité sous `borneExterne`
  (`AvecCibleSerie`), `koachCible` des tentatives, forme d'adhérence (`proposition` d'une cible de série, sans
  changer la charge ; jamais pour une baisse imposée par la sécurité).
- Référence de planification au journal : événements `reference` et `cibles` ; le rejeu reconstruit la
  planification (testé sur 5 saisons du banc : posterior, états des quatre extensions, prévisions, état propre à
  la façade, identiques après un aller-retour JSON du journal).
- `contexte.jour_index` dans `seance_debut` ; `ControleDual.contexteEssai` (contexte d'une proposition d'essai) ;
  un événement qui échoue ne reste pas au journal.
- Sans extension, rien ne change (les fixtures le vérifient).

### 1.3 Autres livrables

- Validateur de sécurité côté Dart (`package:kalis_adapt/validateur.dart`) : copie fidèle des critères calculables de
  `kalis_bench` (`safetyFindings`), `ProfilValidation.depuisProfil` pour l'application ; identique au banc sur les
  27 profils × tous leurs scénarios et sur des blocs modulés aux plafonds (`kalis_bench`
  `test/km2_validateur_test.dart`). La planification du banc est branchée sur le validateur du banc.
- Paramètres : `assets/koach/koach_params_1_0_1.json` (`1.0.1-ref.1`, 317 clés, SHA-256 `c8aa09eb…57f`) et
  `assets/koach/vecteurs_qualites_v1.json` (1 039 fiches), `lireParametresKoach`, `lireFichesKoach`.
- Textes de toutes les raisons (22 codes `koach.*` et leurs causes, surveillance, diagnostic, contrôle dual),
  `texteRaisonKoach` (tutoiement, Koach dit « je »).
- Tests de propriétés seedés (`test/koach_proprietes_test.dart`, environ 23 000 entrées : numérique, modèle,
  garde-fous de séance sur les journaux de parité perturbés) ; test de façade (`test/koach_facade_test.dart`).
- `docs/INTEGRATION_KM3.md` : API, correspondance du journal, paramètres, textes, comportement unique, retraits,
  migration du programme de 40 semaines comme plan initial, vigilance, liste de contrôle, questions ouvertes.

## 2. Critères du cahier mesurés en Dart contre `kalis_adapt` 0.3.1

Matrice du banc : 27 profils, tous leurs scénarios, vérités a, b et c, Koach complet (planification à 1 000
trajectoires, surveillance, contrôle dual, adhérence). Mesure principale sur les **graines 0 à 5** (4 320 saisons,
C13.11.2), colonne de contrôle sur les graines 0 et 1 (= KM1). Détail : `kalis_bench` `docs/CRITERES_KM2.md`.

| # | Critère | Seuil | Koach (g0-5) | Koach (g0-1) | Témoin 0.3.1 | Tenu |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Erreur d'e1RM au rang 6 | < 3 % | 3,95 % | 3,98 % | 7,11 % | non — écart documenté (C13.11.1), ne recule pas |
| 2 | Mauvais jour isolé (apparié) | < 1 % | 0,95 % | 0,95 % | — | oui |
| 3 | Convergence sous 3 % (séances) | ≤ témoin | 5,25 | 4,86 | 11,98 | oui |
| 4 | Couverture à 90 % | 88-92 % | **93,2 %** | 90,4 % | 83,4 % | non sur 6 graines |
| 5 | Calibration de P(réussite) (C13.11.2) | ≤ 5 points | **15,3 points** | 13,9 | — | non |
| 6 | Jour J (meilleure barre / maximum) | ≥ témoin | 0,9459 | 0,9409 | 0,9324 | oui |
| 7 | Pire cas adversarial | ≥ témoin | 0,226 (nouvelle recherche) ; 0,799 (adversaires de KM1) | | 0,0 | oui, au sens du cahier |
| 8 | Violations de sécurité | 0 | 0 | 0 | 111 | oui |
| 9 | Parité Python / Dart | ≤ 1e-9 | 13 fixtures, 5 saisons, 1 440 saisons | | | oui |
| 10 | Rejeu du journal réel | bascule | non mesuré (C13.11.3 : juste avant la bascule, export de KM3) | | | — |
| 11 | Temps, VM Dart de la CI | ≤ 10 s ; ≤ 50 ms | 0,21 s ; 21,5 ms (p95 ≈ 1,3 ms) | 0,20 s ; 30,6 ms | — | oui |

Temps : saison de 16 semaines, après une saison de chauffe JIT (la première est rapportée à part) ; la mise à
jour après une série est `observe` de la série plus `plan` de la série suivante. Python (KM1) : 0,49 s et 14,3 ms.
Sécurité : la vue qui compte les tentatives d'une rampe de test comme des séries dures reste publiée à part, comme en
KM1 (KM1.5 accepté).

## 3. Ce que le pilotage doit trancher

1. **Critère 5 (15,3 points > 5)** : C13.11.2 prévoit dans ce cas une passe courte « KM1 correction 2 » limitée au
   modèle de réussite du jumeau. Déciles (graines 0-5, une prévision par cible à 4 semaines) : 10-20 % prédit 14,1 %
   pour 3,7 % observés (n 192) ; 50-60 % : 53,6 / 68,9 (n 45). Koach Dart en porte l'écart ; la correction se fera
   dans la référence puis par un portage court (mêmes fixtures régénérées).
2. **Critère 4 sur six graines (93,2 %)** : sur les graines de KM1, 90,4 % ; sur les graines 2 à 5, l'intervalle est
   trop large : `mesure.defaut_modele_sd` (0,015) a été calé sur deux graines. Recalage à faire sur six graines
   (paramètre seulement, même passe que le point 1). Recommandation : l'inclure dans la correction 2.
3. **Banc adversarial élargi** : une recherche de 3 000 saisons (au lieu de 300) trouve des athlètes sur lesquels
   Koach fait nettement moins bien que 0.3.1 sur le **même** athlète (Koach ≥ témoin sur 9 adversaires appariés sur
   24) : pire Koach 0,226 contre 0,823 pour le témoin (`adv-31c45cfb`, powerlifter, vérité b, coupure de 12 jours à
   J−19, douleur lombaire 3/10, notes peu fiables) ; Koach complet, même constat (0,248). Mécanisme (vu sur la
   référence Python, identique en Dart) : après coupure et douleur, charges servies très basses (« pas de hausse »,
   « hausse bornée » ancrée sur les derniers passages légers), ouverture des tentatives bornée par les barres réussies
   des 42 derniers jours (+10 %), tentatives qui ne montent pas malgré des barres dites faciles (37,5 kg × 3 pour un
   maximum de 165 kg). Le critère du cahier reste tenu (le pire cas du témoin vaut 0), mais c'est une faiblesse de
   méthode des règles « plus prudentes que 0.3.1 » de KM1 (KM1.4). Recommandation : l'ajouter à la correction 2
   (Fable, méthode), avec un critère apparié (Koach ≥ témoin sur le même adversaire) en plus du pire cas global.
4. **Questions ouvertes pour KM3** (`docs/INTEGRATION_KM3.md`, § 10) : bloc en cours avant la bascule (0.3.1 ou
   programme écrit), profil hors journal, refus du récapitulatif de fin de bloc, « moins de temps » sans changement
   de structure, crans d'élastique, corrections de saisies passées, échéance et cibles du programme importé.

## 4. Relecture indépendante (sous-agent Opus)

0 bloquant, 7 majeurs, une dizaine de mineurs. Traités : forme d'adhérence (mémoire par emplacement, séries de
travail seulement, aucune baisse de sécurité présentée comme suggestion, `pas` et `ampleur` ajoutés, test) ;
sémantique d'`echeances_par_semaine` (doc) ; validateur à lecture tardive de l'horizon et des débuts de bloc (doc et
exemple) ; rejeu avec extensions testé (5 saisons) ; journal robuste aux exceptions ; contexte d'essai
(`ControleDual.contexteEssai`) ; bras de volume idempotent si une séance est prescrite deux fois ; notes de
prévision chaque lundi ; textes (accords, promesse de « moins de temps ») ; docs. Laissés, avec la raison : bras
d'intensité sans raison dans `explain()` (le banc compare `explain` à la référence) ; contrôle par clé du fichier de
paramètres (SHA-256 vérifié) ; `fixe` exact pour les traces seulement.

## 5. Limites

- Celles de la référence (contrat § 10, annexe A) sauf M6 et M7 : structure jamais modifiée, contrôle dual rarement
  calibré (M5), « résidu d'e1RM » du secours qui n'est pas un résidu (M8), critère 1 en écart documenté.
- Produits matriciels de la planification en sommes séquentielles au lieu de BLAS : écarts de l'ordre de 1e-16 ; aucune
  décision n'a basculé sur les fixtures ni sur les 1 440 saisons comparées.
- Temps mesurés sur la VM Dart de la CI ; l'émulateur et le téléphone restent à mesurer en KM3.
- Pas de SDK Dart dans la session (téléchargements refusés par le proxy) : compilation, tests et campagnes faits en CI
  (commits « KM2 contrôle (dev) » sur `claude/ci-cp-a` et `claude/ci-cp-b`, arbre réduit).

## 6. Contrôle

Contrôle complet `claude/ci-cp-a` : voir la ligne KM2 d'`ETAT_CP.md` (run, commit). Sauvegardes :
`cp-sauvegardes/KM2`.
