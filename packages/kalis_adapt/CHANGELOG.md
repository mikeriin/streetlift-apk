# Journal des versions de kalis_adapt

## 1.0.7

Lot KM6 (DECISIONS_CP.md C17.47) : **Koach 1.0.8** (référence Python et portage Dart dans le même lot,
`reference/CHANGEMENTS_1_0_8.md`) — bugs X1 à X8 de la revue RV1 et crédits de groupes des tirages. API et schéma du
journal inchangés ; champ additif `groups` des contraintes de séance (sortie `groups` quand il est reçu) ; raison
nouvelle `koach.volume_semaine` ; champ additif `koachModule` (planification).

- **X1** (`grid.dart`) : poulie par défaut 2,5 kg, minimum 2,5 kg (le défaut de `kalis_plan`), au lieu de 2,5 lb.
- **X2** (`moteur.dart`, `groupesServis`) : groupes de la séance recalés sur les lignes servies (tours, durée d'un EMOM).
- **X3, X7, X8** (`seance.dart`, `_coherence`, `techniqueCoherente`) : technique recalée sur les séries servies
  (`backoffSets`, `intervals`, paliers, blocs au temps, `setTargets`) ; groupe et format de l'emplacement gardés par un
  item servi qui les perdait (course facile) ; baisse de la modulation hebdomadaire sous l'écrit dite
  (`koach.volume_semaine`, `planification.dart` pose `koachModule`).
- **X4 à X6** (`_cibleCharge`, test xRM) : charge plafonnée arrondie vers le bas, test adaptatif jamais au-dessus du
  plafond, charge écrite hors grille d'un test verrouillé gardée.
- **Fiches** : `assets/koach/vecteurs_qualites_v1.json` version `1.0.1` (crédits « chest » des tirages, règle R8-a :
  tractions 0, muscle-ups 0,5, pull-over 0,5), SHA-256 `99b0cae2d0b29d18d5daa30ee92b91990225124e38e44d522e80e8ae01a196e0`.
- **Paramètres** : asset `assets/koach/koach_params_1_0_8.json` (`1.0.8-ref.1`, 344 clés, aucune valeur changée,
  SHA-256 `9d74365e58b84fe0e9db7801dd450c053e4ca870184fca5b480b534b116841d1`).
- **Textes** : `koach.volume_semaine` (« Cette semaine, je te propose N séries sur … au lieu des M écrites… »).
- `Seances.creditsGroupes` (lecture du banc, mesure de KM6).
- **Tests** : `test/koach_km6_test.dart` (port de `reference/tests/test_km6.py`) ; fixtures régénérées.

## 1.0.6

Lot KM5 (DECISIONS_CP.md C17.40) : **Koach 1.0.7** (référence Python et portage Dart dans le même lot,
`reference/CHANGEMENTS_1_0_7.md`) — **la rampe de volume ne coupe jamais sous l'écrit du programme**. API et schéma du
journal inchangés ; une raison nouvelle (`koach.ajout_borne`) ; `koachVolume` lu par la séance (écrit = `sets −
koachVolume`).

- **Rampe de volume** (`seance.dart`, `_planRetour`, `_retourGradue`) : aucun exercice, aucune série retirés au nom du
  volume, tous rôles, toutes semaines ; seules les séries ajoutées par Koach (planification, bras A) sont bornées, par
  groupe majeur et par semaine, à max(limite de la rampe, écrit servi de la semaine) (accessoires d'abord, puis la ligne
  la plus tardive) ; écrit servi compté une fois par séance (`ecritVol`, `ecritDures`, `ecritCompte`) ; un allègement se
  décide sur l'écrit du programme. Rampe tendineuse des tenues bras tendus inchangée (seule raison `koach.retour_gradue`
  restante). Planchers, répartition et emprunt de 1.0.6 retirés.
- `rupture.dart` (semaine allégée d'un diagnostic) et `dual.dart` (bras A) tiennent `koachVolume` à jour.
- **Paramètres** : asset `assets/koach/koach_params_1_0_7.json` (`1.0.7-ref.1`, 344 clés, SHA-256 `2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c`) ; trois clés
  `securite.retour_*` retirées.
- **Textes** : `koach.ajout_borne` (« Je garde les N séries écrites de ton programme sur … »).
- `Seances.entree` (items reçus par le dernier `prescrire`, lecture du banc).
- **Tests** : `test/koach_km5_rampe_test.dart` (port de `reference/tests/test_km5_rampe.py`) ;
  `test/koach_km4_retour_test.dart` retiré ; fixtures régénérées.

## 1.0.5

Lot KM4 (DECISIONS_CP.md C17.37) : **Koach 1.0.6** (référence Python et portage Dart dans le même lot,
`reference/CHANGEMENTS_1_0_6.md`) — retour gradué au volume réparti sur la semaine et priorisé par rôle. API et schéma
du journal inchangés ; champ additif `role` des items de `contexte['reste_semaine']` ; paramètres additifs `ecrites`
et `douleur` de la raison `koach.retour_gradue`.

- **Plan de la semaine** (`seance.dart`, `_planRetour`) : la limite de la rampe par groupe majeur (et le total d'une
  semaine d'allègement) est tenue par des coupes planifiées sur la séance du jour et les séances restantes de la
  semaine, par étapes de priorité (accessoires d'abord, secondaires ensuite, principaux en dernier), au prorata ; un
  principal n'est jamais ramené à 0 série par la rampe sans douleur (plancher `max(1, ⌈écrit × 0,5⌉)` avant qu'un
  secondaire tombe à 0) ; la répartition des coupes sur les séances restantes est programmée mais **désactivée**
  (`retour_repartition_semaines` 0 : 40 constats introduits sur 90 600 saisons) : la séance du jour paie d'abord, les
  séances restantes ne cèdent que pour les planchers. `prescrire` en deux passes. Tenues bras tendus inchangées.
- **Paramètres** : asset `assets/koach/koach_params_1_0_6.json` (`1.0.6-ref.1`, 347 clés, SHA-256 `4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a`) ; trois
  clés nouvelles (`securite.retour_plancher_principal`, `securite.retour_repartition_semaines`, `securite.retour_emprunt_plancher`),
  `rupture.elargissement_rien_de_special` retirée (fichier, défauts, bornes).
- **Textes** : « N séries au lieu de M » pour `koach.retour_gradue` quand les séries écrites sont dites.
- **Tests** : `test/koach_km4_retour_test.dart` (port des 11 tests de `reference/tests/test_km4_retour.py`), fixtures
  régénérées.

## 1.0.4

Lot KM2c3 (KM2 correction 3, DECISIONS_CP.md C13.9, C17.23, C17.26) : **portage Dart de la référence Koach 1.0.5**
(lot KM1c4, `reference/CHANGEMENTS_1_0_5.md`), ligne pour ligne. API, schéma du journal, codes de raison et façade
inchangés ; une valeur de paramètre change (`securite.reprise_dose_depart` 0,6 → 0,5) et sept clés sont nouvelles
(une application intégrée sur 1.0.x monte de version et remplace l'asset de paramètres).

- **Conduite sous douleur** (`securite.dart`, `seance.dart`) : zone sensible douze semaines après tout épisode, avec ou
  sans arrêt (`Gardefous.episode`, `sensible`, `sensibles`, `geneRecente`) ; rampe hebdomadaire de l'exposition
  RÉALISÉE de la zone (+1 série ou +20 %, départ à la moitié de la charge chronique, séances manquées à zéro, sortie
  progressive jusqu'à l'écrit), répartie par séance au prorata de l'écrit, échauffement compris (réserve) ; même
  rampe au retour d'une coupure sans douleur connue (règle 3 bis, suspendue en semaine verrouillée) ; pas de vrai test
  sur une zone sensible sous rampe ; aucune hausse de charge sous une gêne > seuil des sept derniers jours (règle 4).
  `_budgetReprise` disparaît. Journal public `Seances.appelsVraiTest` (tests).
- **Élargissement « rien de spécial »** (`modele.dart`, `rupture.dart`) : `Modele.elargir(part)`, mélange convexe vers
  l'a priori (`rupture.elargissement_vers_a_priori` 0,25, borne [0 ; 1]) sur toutes les branches ; l'action du
  diagnostic porte `part`. `elargissement_rien_de_special` n'est plus lue (gardée dans le fichier, les défauts et les
  bornes, comme la référence).
- **Paramètres** : asset `assets/koach/koach_params_1_0_5.json` (`1.0.5-ref.1`, 345 clés, SHA-256 `d8a492b7…f26d`, copie
  à l'octet près de `reference/params/koach_params_v1.json`) à la place de `koach_params_1_0_4.json`.
- **Textes** (`koach_textes.dart`) : `koach.reprise_dose` et le retrait `reprise_dose` ont un texte neutre (la rampe vaut
  aussi au retour d'une coupure, sans douleur).
- **Banc** (`lib/src/sim/truth.dart`) : une douleur qui commence (fiche, épisode tendineux) n'est connue du moteur qu'une
  fois signalée (`_painKnown` remis à faux, comme `reference/banc/verite.py`) ; `SimAthlete.painKnown`, `setForTest`.
- **Tests** : repointés sur `reference/fixtures/` et `reference/params/koach_params_v1.json` (copies figées `fix_dart/` et
  `koach_params_d4.json` supprimées) ; parité sur les 15 fixtures et les 3 complémentaires (`test/fixtures/km2c2/`,
  régénérées) ; `test/koach_km1c4_douleur_test.dart` (les 23 tests de `reference/tests/test_km1c4_douleur.py`, mêmes
  valeurs) ; `test/koach_elargir_test.dart` (1.0.5) ; `test/km2c3_verite_test.dart`.

## 1.0.3

Lot KR1 (DECISIONS_CP.md C17.17.3, C17.18 : Koach sur `kalis_plan` 0.4.1, campagne du couple) : **portage Dart de
la référence Koach 1.0.4** (`reference/CHANGEMENTS_1_0_4.md`), à l'identique. API, schéma du journal, façade et
valeurs des paramètres inchangés (une application intégrée sur 1.0.x monte de version et remplace l'asset de
paramètres).

- **Élargissement plafonné à l'a priori** (`modele.dart`, `Modele.elargir`, `Modele.variancesAPriori`, contrat
  § 4.4) : la réponse « rien de spécial » au diagnostic multiplie la variance de chaque composante de capacité par le
  facteur, sans jamais dépasser son a priori de population (variance nouvelle = min(facteur·v ; max(v ; v0)),
  P ← D P D). Avant : réponses répétées sans borne (écart-type de 20 en ln, `NaN` dans `Seances._cibleTenue`, 8
  saisons plantées de `ks_test_ppl6` sur la campagne du couple, lot KR1).
- **Paramètres** : asset `assets/koach/koach_params_1_0_4.json` (`1.0.4-ref.1`, 338 clés, mêmes valeurs, SHA-256
  `2d023854…9016`) à la place de `koach_params_1_0_3.json`.
- **Référence** (`reference/`) : moteur 1.0.4 ; données de référence régénérées sur `kalis_plan` 0.4.1 et étendues
  aux 34 profils (saisons figées sur 0.3.1 gardées dans `kalis_bench/docs/data/kr1/saisons_figees_0_3_1/`) ;
  campagne : vues « réalisée » et « réalisée appariée » de la sécurité (séances manquées vidées, rapportées), classement
  « retour à l'écrit » corrigé après un bloc interrompu ; fixtures régénérées ; `tests/test_kr1_violations.py` :
  mécanismes des violations restantes du couple sur cent graines (59 poussées, 4 aggravations : conduite sous
  douleur, non corrigée ici, `pipeline/cp/livraisons/LIVRAISON_KR1.md`).
- **Tests** : parité sur les 15 fixtures régénérées et les 3 complémentaires (`test/fixtures/km2c2/`, régénérées),
  traces comprises ; `test/koach_elargir_test.dart` (plafond, comportement inchangé sous l'a priori).

## 1.0.2

Lot KM2c2 (KM2 correction 2, DECISIONS_CP.md C13.13.2, C17.13) : **portage Dart de la référence Koach 1.0.3**
(KM1 correction 3, `reference/CHANGEMENTS_1_0_3.md`), à l'identique. API, schéma du journal et façade inchangés ;
`posterior()` gagne la clé `fiabilite` (une application intégrée sur 1.0.0 ou 1.0.1 monte de version et remplace
l'asset de paramètres).

- **Fiabilité des notes** (`modele.dart`, classe `Fiabilite`, contrat § 5.13) : grille a posteriori sur ln φ, part
  des séries de force non notées (Beta), oubli λ, grilles par schéma rapportées ; mise à jour dans `_serieForce`
  (séries de force faites, hors échauffement et échec, après la sonde et avant la porte des séries sans note) ;
  `elargissement()` = κ ≥ 1 (plafonné à 2), appliqué à l'écart-type de `capacite` et `capaciteDuJour` (sauf
  `brut`) et aux tirages du jumeau (`Planification.tirer` : S ← D S D sur les capacités) ; la moyenne des capacités
  ne change jamais.
- **Tentatives** (`seance.dart`) : échelle sur l'écart-type brut (`capaciteDuJour(brut: true)`,
  `probaReussite(…, brut)`) ; palier des barres prouvées réduit et marge sur les barres réussies quand κ > 1
  (`_palierBarres`) ; après un échec hors semaine de compétition, barre suivante sur l'estimation mise à jour, au plus
  `tentative_echec_baisse_part` sous la barre ratée (en compétition : la même barre, A8.2).
- **Règles** : `_bornesHausse` applique `securite.echec_sans_hausse_tout_schema` (1 : aucune hausse après un échec
  non prévu, quel que soit le schéma, règle de 0.3.1) ; `_cibleCharge` : prudence des séries lourdes
  (`planification.prudence_charge_fiabilite`, 0 dans le fichier livré) ; `_rampe` : borne large sur σ brut.
- **Import** (`rupture.dart`) : `mesure.defaut_modele_sd` ∈ [0,001 ; 0,1] (relecture KM2c1, m3), six bornes
  nouvelles, cinq clés de grille et d'a priori de la fiabilité figées ; `appliquerParametres` repointe
  `modele.fiabilite.p`.
- **Paramètres** : asset `assets/koach/koach_params_1_0_3.json` (`1.0.3-ref.1`, 338 clés, SHA-256
  `d129a4e9…1aa0`) à la place de `koach_params_1_0_2.json`.
- **Tests** : parité sur les 15 fixtures de la référence 1.0.3 (`moteur_12` : notes peu fiables) et trois fixtures
  complémentaires produites par la référence sans la modifier (`test/fixtures/km2c2/`, `generer_km2c2.py` :
  tentative ratée hors compétition et en compétition, jumeau avec κ > 1), traces comprises ;
  `test/koach_fiabilite_test.dart` (indicateur, moyenne intacte, élargissement, import) ; bornes et clés figées de
  1.0.3 dans `koach_parametres_test.dart` ; copies figées de 1.0.2 (`reference/fix_dart/`, `koach_params_d2.json`)
  supprimées.

## 1.0.1

Lot KM2c1 (KM2 correction 1, DECISIONS_CP.md C13.12, C13.13, C17) : **portage Dart de la référence Koach 1.0.2**
(KM1 correction 2, `reference/CHANGEMENTS_1_0_2.md`), à l'identique. API, schéma du journal et façade inchangés
(une application intégrée sur 1.0.0 monte de version et remplace l'asset de paramètres).

- **Reprise par paliers mesurés** (`seance.dart`) : la semaine du retour d'une coupure, une ligne chargée part de la
  dernière séance du même schéma (ou des barres réussies des 42 jours ; repli sur le dernier passage sans barre
  récente) et ne monte d'une série à l'autre qu'après un palier franchi (série réussie, notée, dite au plus aussi
  dure que visé), jamais au-delà de la borne de séance A7.2 (`reprise_plafond`) ; l'ancre « dernier passage de
  l'exercice » ne vaut plus que sous douleur ; un jour de bilan bas sans douleur est borné par la dernière séance
  du même schéma, comme en 0.3.1.
- **Tentatives** : ouverture plafonnée par le palier des barres récentes selon la note (`_palierBarres`,
  `securite.tentative_palier_par_rir`, `tentative_palier_bande`) au lieu de « +10 % sur toute barre » et du
  dernier passage en semaine de retour ; un cran permis après une barre dite facile quand le saut en pourcentage
  vaut zéro sur la grille ; test xRM du jour d'épreuve en reprise sous le même palier.
- **P(réussite) du jour J** (`planification.dart`) : dispersion des trajectoires des cibles chargées ramenée à
  `planification.dispersion_echeance` (0,62) sur les `dispersion_echeance_semaines` (4) premières semaines de
  journal ; `Planification.previsions` porte aussi `prevu_jour`.
- **Intervalle à 90 %** (`modele.dart`) : `capacite(…, brut:)`, variance du filtre recalée par
  `mesure.intervalle_echelle` (0,9), `mesure.defaut_modele_sd` 0,015 → 0,010 ; le contrôle dual lit la variance
  brute (`dual.dart`). Quatre bornes d'import de plus (`rupture.dart`).
- **Paramètres** : asset `assets/koach/koach_params_1_0_2.json` (`1.0.2-ref.1`, 322 clés, SHA-256
  `211c9361…f5da`) à la place de `koach_params_1_0_1.json`.
- **Tests** : parité sur les 14 fixtures de la référence 1.0.2 (`moteur_11` : reprise et tentatives après 12 jours
  de coupure), traces comprises ; tests repointés vers `reference/fixtures/` et `reference/params/koach_params_v1.json`,
  copies figées de 1.0.1 (`reference/fix_dart/`, `koach_params_d1.json`) supprimées.

## 1.0.0

Lot KM2 (méthode Koach, `pipeline/cp/CAHIER_KM.md`, décisions C13) : **Koach 1.0**, portage Dart à l'identique
de la référence Python validée par KM1 (`reference/koach/`, version 1.0.1, contrat `reference/CONTRAT_1_0.md`).
Contrat **non additif** (seul écart permis à « contrats additifs », C13.5) : l'API de Koach est nouvelle ; le code
de 0.3.1 reste dans le paquet, inchangé, pour l'application jusqu'à KM3 et comme témoin du banc.

- **`package:kalis_adapt/koach.dart`** : `Koach(params, fiches, profil)` avec `observe`, `posterior`, `plan`
  (horizons `seance`, `serie`, `semaine`), `explain`, `rejouer` ; estimation (IRT multidimensionnelle sur 10
  qualités, mesure du RIR, courbe de Box-Cox, fatigue, branche « mauvais jour »), prescription, garde-fous de
  0.3.1 en contraintes dures, extensions `Planification` (jumeau numérique, entropie croisée, plafonds ±15 % /
  ±5 %), `Surveillance` (BOCPD, secours, diagnostic), `Adherence` (probit), `ControleDual` (Thompson, N-of-1,
  contrôle synthétique). Parité avec la référence : les 13 fixtures de KM1 (`test/koach_parite_test.dart`),
  traces comprises, écart nul en pratique (tolérance 1e-9).
- **Façade (constats M6, M7 de KM1)** : les crochets d'extension sont appliqués par `plan` lui-même — modulation
  de la planification, semaine allégée, bras de volume et d'intensité d'un essai, forme d'adhérence (clé
  `proposition` d'une cible de série) ; la référence de planification est un événement du journal
  (`reference`, `cibles`) : le rejeu reconstruit aussi la planification. `CONTRAT.md`, § K.
- **Paramètres en asset versionné** : `assets/koach/koach_params_1_0_1.json` (`1.0.1-ref.1`, 317 clés) et
  `assets/koach/vecteurs_qualites_v1.json` (1 039 fiches), lus par `lireParametresKoach`, `lireFichesKoach`.
- **Validateur de sécurité** (`package:kalis_adapt/validateur.dart`) : copie fidèle des critères de sécurité du
  banc (`kalis_bench` `safetyFindings`), obligatoire pour `Planification` ; `ProfilValidation.depuisProfil`
  pour l'application. Parité avec le banc testée dans `kalis_bench` (`test/km2_validateur_test.dart`).
- Tests de propriétés seedés (`test/koach_proprietes_test.dart`, plus de 20 000 entrées).
- **Textes de Koach** (`package:kalis_adapt/koach_textes.dart`) : une phrase française par code de raison
  (`texteRaisonKoach` : les 22 codes `koach.*` et leurs causes, causes et actions de la surveillance, raisons du
  contrôle dual ; `texteQuestionKoach`, `texteChoixKoach` pour le diagnostic), jamais un code brut
  (`test/koach_textes_test.dart`).
- Intégration : `docs/INTEGRATION_KM3.md`. Mesures des critères du cahier : `kalis_bench` 0.4.0
  (`bin/km2.dart`).

## 0.3.1

Lot CY, partie 0 (sécurité) du pipeline « Calibrage des programmes ». Contrat additif (cinq paramètres, un argument du constructeur).

- **Première gêne du poignet** (3/10 ou plus dans les deux semaines, avant tout arrêt) : la poussée paume à plat
  passe tout de suite sur un appui neutre faisable (parallettes, poignées, pompe mains serrées sur une barre
  basse). Pendant un arrêt du poignet, seuls les parallettes et les poignées comptent (C10.8 (a)).
- **Couloir de charge** : à 85 % du 1RM écrit ou plus, la charge servie ne dépasse plus l'écrit
  (`coachCorridorHeavyShare`).
- **Schéma changé d'une séance à l'autre du même emplacement** : charge totale bornée par la hausse à schéma
  égal, corrigée de 2,5 % par répétition de moins (`coachRepLoadShare`, `coachRepGapMax`).
- **Jour de bilan bas** : il ne devient plus le repère d'un jour bas suivant (sous-dosage qui se reconduisait).
- **Double progression** (règle « 2 pour 2 » de la NSCA, `coachTwoForTwo`) : deux séances de suite au haut de
  la plage, ou nettement plus faciles que visé, font monter la charge d'un cran (sous le garde-fou de réserve,
  jamais à 85 % du 1RM écrit ou plus, jamais un jour sans hausse).
- **Propositions de volume** : une série de plus n'est proposée que si chaque groupe musculaire de l'exercice
  reste sous le plafond hebdomadaire du niveau (12, 20, 25, 30 séries).
- **Programme importé** (C11) : `KalisAdapt(restructureImported: true)` permet les restructurations.
- **Douleur qui dure au bas du corps** (mode coach) : la course est retirée tant que l'arrêt tient (cardio sans
  impact gardé), puis revient par paliers (part de reprise bornée par `enduranceResumeLong`) ; un mouvement retiré
  par un arrêt n'est plus compté comme sauté dans le résumé (il disparaissait du bloc suivant).
- Relecture indépendante du code : la règle « 2 pour 2 » ne joue ni en bloc verrouillé, ni en semaine légère ou
  proche d'une échéance, ni pendant un retour ou une douleur ; la charge repère à schéma changé prend la charge
  lestée ; le plafond des propositions de volume est vérifié sur toutes les semaines modifiées.
- Relecture documentée de CY : pendant un arrêt du poignet, la règle C10.8 (a) reste entière (parallettes et
  poignées seulement) ; la règle « 2 pour 2 » ne prend pas un cran de plus de 10 % ; à schéma changé, aucune part
  en plus pour une zone à antécédent.

## 0.3.0

Lot CA2, partie 1 du pipeline « Calibrage des programmes » : course, cardio, conditionnement, mobilité et profils
hybrides conduits d'après le journal (`CONTRAT.md`, § 12). Contrats additifs ; `kalis_core` 0.4.3 (cinq codes de
raison d'endurance).

- **Course** : sortie du jour bornée à la plus longue course des 30 jours + 10 % (Frandsen et al. 2025) ; jour sans
  (bilan bas, douleur du bas du corps, course récente trop dure) : séance de qualité servie en course facile, ou
  retirée ; bilan très bas : durée à 70 % ; reprise après 7 jours sans séance à 70 %, après 14 jours à 50 %.
- **Test de course** plus long que la borne : servi en course bornée, test reporté.
- **Conditionnement** : pièce mise à l'échelle (75 %) un jour sans ou après deux jours durs de suite.
- **Élastique (street)** : une séance entière dite au moins 2 répétitions plus facile que visé fait passer à l'élastique
  plus fin à la séance suivante (sept jours au moins depuis le dernier changement).
- **Hybrides** : fatigue croisée — course dure la veille, une répétition de réserve de plus sur le bas du corps ;
  lignes d'endurance comptées dans le modèle forme-fatigue.
- **Jamais au-dessus de l'écrit** (durée, distance, répétitions, séries, effort, allure) : invariants E1 à E3,
  vérifiés à chaque séance des simulations et des journaux aléatoires (profils de course ajoutés).
- Simulateur : vérité d'endurance (course, conditionnement ; deux modèles, risques de surcharge) ;
  `AdaptParams.enduranceConduct` rejoue 0.2.

## 0.2.3

Lot CA2, partie 0 (street) du pipeline « Calibrage des programmes ». Mode 0.1 inchangé. Détail et sources :
`CONTRAT.md`, § 11.16.

- **Reprise graduée conduite séance par séance (sécurité)** : palier qui recule quand la douleur répond
  (gêne au-dessus de 2/10, pas revenue au niveau d'avant, en hausse d'une semaine à l'autre) ; dose écrite
  jamais dépassée, 3 répétitions en réserve, aucune hausse dans la séance ; arrêt gardé quand il se lèverait
  sur une semaine qui n'est pas de charge ; reprise propre au moteur (50 %, +10 % par semaine de charge,
  67,5 % du 1RM) quand l'arrêt se lève au milieu d'un bloc qui écrit encore les mouvements provocants.
- **Tests reportés** : jamais sur une zone douloureuse, en reprise ou à l'arrêt gardé (retirés, pas remplacés).
- **Appui du poignet sensible** : dose d'appui écrite par le bloc au plus.
- **Meilleur maintien récent** : le plancher des tenues ne vient plus d'un record d'avant un arrêt.
- **Élastique** : deux séances au même cran avant d'en changer, jamais d'aller-retour sans échec.
- **Tentatives après un affûtage** : maximum du jour +2 %.
- **Appui à prise neutre** : un poignet douloureux ou à l'arrêt garde la poussée par une variante neutre.
- **Estimation moins prudente** : série lourde (8 répétitions possibles au plus) lue avec le biais de note
  appris ; une série arrêtée sous la cible ne fait baisser l'estimation qu'à la deuxième mesure concordante ;
  bornes de santé comptées depuis la dernière séance d'une semaine de charge (jamais depuis une séance
  volontairement légère).
- **Douleur pendant l'arrêt et après (sécurité, relecture documentée du pilotage)** : à 5/10 avant la séance,
  tout mouvement qui charge la zone est retiré (6/10 avant ; allègement dès 4/10), remplaçants compris ;
  pendant un arrêt, les mouvements qui chargent la zone sans la provoquer restent au premier palier de la
  reprise (moitié des séries, 3 en réserve, 67,5 % du 1RM au plus), puis sont retirés si la douleur est
  encore à 3/10 après deux semaines d'arrêt ; remplaçant d'une douleur du jour à 70 % du 1RM au plus ; sur
  une zone à l'arrêt ou sortie d'un arrêt depuis douze semaines, répétitions ou secondes par série +10 % au
  plus d'une séance à la suivante.
- **Suivi de l'arrêt (sécurité, relecture documentée du pilotage, manche 4)** : renvoi vers un professionnel à
  la première séance de l'arrêt puis une fois par semaine ; aucun test tant que la zone a été signalée au-dessus
  de 2/10 dans la semaine ; échauffement compris dans l'arrêt ; poignet à l'arrêt : toute charge externe d'appui
  retirée d'emblée (dips lestés), appui neutre au poids du corps gardé au premier palier, poussée en extension
  remplacée par un appui neutre au poids du corps ; zone douloureuse du jour comptée comme récente (+10 % au
  plus) dès la séance.
- **Poignet encore à 3/10 pendant l'arrêt (sécurité, panel de la passe 5)** : tant que la gêne de la semaine
  atteint 3/10, seuls les appuis sur parallettes ou poignées restent (dips aux barres, anneaux, pompes au sol
  retirés, échauffement compris) ; pendant tout l'arrêt du poignet, le remplaçant d'une poussée est un appui sur
  parallettes ou poignées, jamais des dips aux barres.
- **Élastique** : la série de séances au haut de la plage compte même quand la plage écrite monte.
- **Relecture indépendante du code (sécurité)** : arrêt gardé jusqu'aux deux semaines à 2/10 (plus de chute au
  premier signalement plus bas), étape de figure et test reporté filtrés par les règles de douleur et d'arrêt,
  plafond de la reprise et des remplaçants sur toute ligne chargée, arrêt gardé sur l'échauffement, remplaçant de
  douleur du jour obéissant aux arrêts, aucune hausse au-delà du plan en reprise, ni tenue repère sur zone récente,
  manques de l'élastique comptés à plage montante, gain d'affûtage avant la première barre seulement.
- Simulateur : zone réactive après un épisode de douleur (modèles B et C), poussées comptées ; une hausse
  sur zone douloureuse se compte au-dessus de 3/10 (les mesures du mode 0.1 au banc ne se comparent plus
  chiffre à chiffre à celles de 0.2.2).

## 0.2.2

Lot « CX correction 1 » du pipeline « Calibrage des programmes » (croisement avec `kalis_plan` 0.2.2).
`kalis_core` 0.4.2. Le mode 0.1 est inchangé. Détail et sources : `CONTRAT.md`, § 11.

- **Douleur qui dure ou qui revient (mode coach, sécurité)** : suivi daté des signalements par zone ; arrêt
  quand la douleur reste à 3/10 ou plus deux semaines, à 5/10 ou plus plus d'une semaine, ou revient dans les
  douze semaines après un épisode réel ; levé après deux semaines sans signalement au-dessus de 2/10. Pendant
  l'arrêt, les mouvements qui provoquent la zone sont retirés des séances (`adapt.pain_persistent`) et la
  revue propose de les écarter du bloc ; la douleur montrée dans le journal reste celle du dernier
  signalement récent.
- **Sous-dosage** : chaque série est jugée contre sa propre réserve visée ; une série facile n'est plus lue
  comme « plus dure que prévu » ; une série au ressenti qui suppose moins de 90 % de la prédiction est lue
  comme une borne basse, et la baisse attend une deuxième mesure concordante, une autre séance, dans les
  quatre semaines (une mesure conforme efface la borne en attente) ; cran d'élastique retiré après deux
  séances au haut de la plage à charge et plage égales (ou une première série dite deux répétitions plus
  facile).
- **Douleur, revue** : en mode coach, seul l'arrêt (et sa fin) signale une douleur qui dure ; un épisode
  tolère deux semaines entre deux signalements.
- **Tests** : retirés un jour de bilan bas (1 sur 5 de baisse ou plus) et refaits à une séance suivante de la
  semaine, 48 h après au moins, un bon jour sans douleur, avec le matériel du lieu du jour et seulement pour
  une étape de figure acquise ; jours bas et milieu des tentatives lus comme en 0.2.1 hors mode coach.
- **Charges** : tentatives (ouverture 91 %, deuxième +5 % au plus, troisième +3 % au plus, +5 kg de charge
  externe au plus ; la meilleure barre entre la réussie et la manquée est reportée) ; −7,5 % après une série
  manquée non voulue, gardé sur les séries suivantes de la séance ; simple d'entraînement à 92 % du maximum estimé au plus (85 % un jour de bilan bas) ;
  semaine allégée ou de test : jamais plus lourd que la charge écrite.
- **Tenues** : la borne de hausse d'une tenue laisse toujours servir 55 % du meilleur maintien mesuré.

## 0.2.1

Lot CX du pipeline « Calibrage des programmes » (croisement avec `kalis_plan` 0.2.1). `kalis_core` 0.4.2.

- **Correction : une proposition appliquée gardait le bloc au contrat 0.4.0** (`applyProposal`) : le diff de
  prescriptions reconstruisait les semaines sans leur intention (ni les autres champs du contrat 0.4.0), et le
  bloc repassait au mode 0.1 pour la suite (vu sur les saisons croisées : bloc après une proposition de
  volume servi sans phase). Les semaines et séances d'un bloc qui porte une intention sont maintenant
  copiées (`copyWith`) ; un bloc de 0.1 est reconstruit comme en 0.2.0, à l'octet près.

- **Changement de profil en cours de saison** (`simulation.dart`) : `simulate(changes: …)` applique un
  `ProfileChange` au début d'une semaine (échéance avancée, par exemple) ; s'il le demande, le bloc en
  cours s'arrête et le bloc suivant est écrit sur le profil changé. `SimRun.changes` garde la trace. Sans
  `changes`, la simulation suit 0.2.0 (aux blocs près que la correction d'`applyProposal` garde au contrat 0.4.0).

## 0.2.0

Lot CA1 du pipeline « Calibrage des programmes » : faire évoluer un athlète street comme un coach qui le
suit. `kalis_core` 0.4.1, `kalis_plan` 0.2.0.

- **Mode coach** (`CONTRAT.md`, § 11) pour les blocs qui portent le contrat 0.4.0 (intentions, techniques,
  intensités, règles d'autorégulation, tests, échelles de figures) : la semaine dit ce qui est permis
  (affûtage, décharge, test et compétition servis tels quels, jamais de série ajoutée) ; charge écrite en
  part du 1RM pilotée par la réserve dans un couloir, hausse bornée à schéma égal ; toutes les techniques
  de série exécutées et relues dans le journal (`readLine`), jamais servies sans leurs prérequis ; règles
  d'autorégulation exécutées (séries allégées sur la série de tête réalisée, arrêts) ; tests et
  tentatives (ouverture, deuxième, troisième, d'après le maximum estimé et son incertitude) ; figures
  (étape en cours, critère de passage, étape plus facile un mauvais jour, hausse des maintiens bornée
  pour les tendons) ; douleur à 5 sur 10 (exercice gardé, allégé) ; récupération déclarée du profil v3 ;
  reprise graduelle après une coupure.
- **Notes d'effort** : loin de l'échec, une note se lit comme une borne ; série repère quand les notes
  n'informent plus ; biais de note appris sur les tests (limite 4 de 0.1) ; courbe apprise sur les séries
  proches de l'échec.
- **Sorties** (`kalis_core` 0.4.0) : `SessionPlan.phase`, `weekIntent`, `eventId`, `groups` ;
  `IntraSessionAdvice.miniSetsLeft`, `stepExerciseId` ; `AdaptReview.testResults`, `skillStates` ;
  `AdaptationSummary.benchmarks`, `skills`, `volumeTolerance` ; `EventDayAdvisor.planEventDay`
  (échauffement, tentatives, rythme d'une épreuve de répétitions) ; nouveaux codes de raison `adapt.*`
  de 0.4.0.
- **Règles issues du calibrage au panel** (`docs/CALIBRAGE_CA1.md`, `CONTRAT.md` § 11.4, 11.5, 11.9) :
  seules les séries qui montrent la capacité la mesurent (série au ressenti arrêtée avant le haut de sa
  plage, test, série restée sous sa cible) — les autres ne donnent qu'une borne basse ; séries repère sur
  une plage, une série de tête ou un maintien ; répétitions et maintiens écrits en part d'un test recalés
  sur le maximum mesuré, dans les deux sens ; haut d'une plage servi à la réserve du bloc ; séries
  fractionnées quand la plage est hors de portée ; maintien trop facile remonté vers la moitié du maximum ;
  exercice assisté : cran d'assistance conseillé et lu dans le journal ; exercice jamais fait : entrée à
  60 % de la charge de référence ; séries allégées pilotées sur la série de tête réalisée ; zone
  douloureuse : volume gelé ; alerte de surmenage (deux séances mesurées de suite à −5 % : une semaine à
  40 % de lignes en moins sur le mouvement) ; un test fait un jour de bilan nettement bas ne fait pas
  baisser le repère.
- **0.1 conservé** : un bloc sans champ du contrat 0.4.0 (programmes de `kalis_plan` 0.1, programme
  importé du propriétaire) est servi comme en 0.1.0 ; `KalisAdapt(legacy: true)` sert tout bloc comme en
  0.1.0.
- **Simulateur** : deux modèles de vérité de plus (B et C, `TruthKind`), exécution des techniques, des
  tests et des tentatives, journal aux champs de 0.4.0, résultats de test reportés au profil, programmes
  de test à techniques injectées (`injectTechniques`), coach simple à la note d'effort (`RpeCoachPolicy`),
  mesures du mode coach (`CoachMetrics`).
- **Validation** : invariants I1 à I8 inchangés sur 10 240 journaux aléatoires ; invariants du mode coach
  (C1 à C4, I2 à I8) sur 10 240 journaux aléatoires aux champs de 0.4.0, programmes street du banc et
  programmes à techniques injectées ; campagne street de `kalis_bench` (17 profils, trois modèles de
  vérité, quatre politiques) ; règles du calibrage (`test/coach_rules_test.dart`) ; calibrage au panel
  (`docs/CALIBRAGE_CA1.md`) : 34 couples sur 68 à 9 ou plus, minimum 7 — **cible « 9 partout » non
  atteinte**, les corrections restantes portent sur le programme écrit par `kalis_plan`.

## 0.1.0

Première version (lot G8 du pipeline « Génération et progression »).

- `KalisAdapt` réalise `AdaptEngine` de kalis_core 0.2.0 : `prescribeSession`, `adviseNextSet`,
  `review` ; `estimates`, `applyProposal`.
- Modèle individuel : filtre de Kalman par exercice sur la capacité opérationnelle (tendance locale
  amortie, forme de la courbe répétitions ↔ charge, effet de jour), observation des séries avec bornes
  (notes absentes, « 5 et plus », séries terminées, séries ratées), écrêtage des écarts aberrants,
  fatigue dans la séance, forme et fatigue entre les séances, forme du jour, notes peu informatives,
  partage entre exercices proches, coupures.
- Séries enchaînées (supersets, tours) lues dans l'ordre de réalisation ; pivot de la courbe déplacé
  quand la plage change ; séries manquées douteuses écrêtées.
- Décisions : charge à hystérésis sur la grille réelle du matériel, plafonds de hausse, calibrage,
  séries notées « 5 et plus », conseil pendant la séance (écart de 2 flammes), série repère, bilan santé
  gradué, douleur, lieu et temps du jour, charge minimale trop lourde, programme importé, tests.
- Revue : résumé d'adaptation, propositions (volume, décharge anticipée, échange, épargne d'une zone,
  restructurations par `kalis_plan`) filtrées par déblocage, confiance et utilité ; records ; journal du
  moteur.
- Simulateur d'athlètes à vérité connue (`lib/simulation.dart`), comparaison à la double progression, à
  l'ancien moteur L7/L11 et à l'oracle ; lignes de commande `kalis_adapt:simulate`, `kalis_adapt:replay`,
  `bin/kalis_adapt_cli.dart`.
- Validation : `docs/` (mesures de la campagne, lecture, rejeu du programme importé du propriétaire),
  référence croisée Python, tests de propriétés sur 10 240 journaux aléatoires.
