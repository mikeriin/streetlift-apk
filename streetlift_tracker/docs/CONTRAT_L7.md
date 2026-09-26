# Kalis Track — Contrat L7 : Koach, moteur d'autorégulation (KT-024 à KT-036)

**Version : 3.0.0+61 — 26 septembre 2026, Europe/Paris.**
Ce document sépare les **règles approuvées** (décisions D1-D37 du propriétaire du 26/09/2026), les **choix d'implémentation** faits dans ce cadre (modifiables), les **ajustements justifiés par simulation** et les **décisions manquantes**. Koach produit des **estimations d'entraînement**, pas des mesures ; il n'est pas validé scientifiquement par ce lot (§11).

Nature des preuves : « simulation » = `tools/koach_simulation.py` et `test/l7_koach_simulation_test.dart` (graines fixées) ; « test » = test automatique (CI) ; « appareil » = aucun essai sur téléphone à ce jour.

## 1. Base, prérequis, contradictions signalées

| Point | Constat | Traitement |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` L4b 2.5.9+60, SHA-256 `0e6aa29c…67ca`, 1 469 701 octets, racine unique, identique à `main` `f71c360` | Travail sur copie, archive intacte |
| L4 (départ, provenance des références) | **Livré** (2.5.8) : `refStatus` `set`/`historic`, départ `Program.start` | Utilisé tel quel (prior σ 10 %, dates) |
| LC1 (S12-S19, KT-037) | **Présent** : 1 818 exercices, empreinte LC1 vérifiée par `test_lc1_revision.py` | Non refait |
| « 1 954 entrées » (demande §4) | Le programme compte **1 818** exercices depuis LC1 | Contrôle d'égalité RIR visé ↔ libellés fait sur les **1 818** entrées |
| Table « Repères RIR ↔ % » de la feuille Pilotage | **Absente de l'archive** : l'asset ne contient que B4, B8-B11, B16-B20, B25-B45 ; le classeur n'est pas fourni et n'est plus à jour (LC1) | A priori ajusté sur les couples (reps, RIR, %) **prescrits par le programme lui-même** dans ses libellés « RIR r · ~p % » (§4.2) |
| Incohérence « 1 rep à RIR 0-1 ≈ 93-95 % » | Présente dans les libellés : singles « RIR 0 · ~95-97 % » (S24, S37, S38) et « RIR 1 · ~93-94 % » (S18, S22, S36). Par définition, 1 rep à RIR 0 = 100 % (n = 1) ; 1 rep à RIR 1 → k ≈ 13-16, hors de la courbe du reste du programme | Traitée comme une **marge de prescription** (single prescrit sous le 1RM de référence), pas comme un point de courbe : écartée de l'ajustement (n ≤ 2) ; en estimation, n = 1 → 100 % |
| RIR cible structuré | L'asset ne peut pas être modifié sans casser l'empreinte LC1 (tests `test_lc1_revision.py` figés sur son SHA-256) | Champ structuré dans un fichier annexe généré **`assets/koach_program.json.gz`** (`tools/koach_annotate.py`), asset d'origine inchangé |
| Champ `rir` existant | Texte libre dont le sens (RIR ou RPE) dépend du réglage au moment de la saisie, non mémorisé | Échelle héritée **figée** à la première activation de Koach (§3.3) |

## 2. Décisions appliquées (D1-D37) et choix d'implémentation

| Décision | Règle appliquée | Choix d'implémentation (modifiable) |
| --- | --- | --- |
| D1 grand public | Aucun paramètre du propriétaire codé en dur ; ses valeurs sont des **données** à saisir | Incréments D23 du propriétaire proposés comme défauts modifiables (demandé) ; objectifs finaux vides par défaut |
| D2 périmètre | Programme 40 semaines seulement ; séances perso et WOD ignorés | Clés `S0-J*` et WOD exclues du rejeu |
| D3 nom | « Koach », jamais « IA », aucun vocabulaire médical, aucune promesse | Textes relus (§7) |
| D4 validation | Aucune valeur de pilotage modifiée sans un tap | Seules `acceptProposal` et la saisie manuelle écrivent une valeur |
| D5 moments | (a) après la série 1 d'un mouvement principal, et aux déclencheurs D24 suivants ; (b) au bilan | Bilan Koach ouvert après la fin enregistrée d'une séance du programme ; propositions retrouvables dans l'écran Koach |
| D6 interrupteur, verrou | Koach désactivé = 2.x ; verrou « Garder ma charge » | **Désactivé par défaut** (installation neuve et mise à jour) jusqu'à activation explicite ; verrou par **référence Pilotage** (B8… / B25…) |
| D7 refus | Refus daté, non reproposé dans la séance ; les séries restent des données | Refus mémorisé par (séance, exercice, sens) : une hausse refusée n'est plus proposée, une baisse de sécurité (série ratée) peut l'être |
| D8 difficulté obligatoire | Série 1 et dernière série des 4 mouvements principaux, Koach actif | Exercices annotés `strength` (séries de travail principales) ; pas les tests, excentriques, dips à élastique ni variantes (squat pause) |
| D9 échelle | Échec 0 · Très dur 1 · Dur 2 · Soutenu 3 · Modéré 4 · Facile 5+ ; libellé + « encore N » ; texte, jamais la couleur seule | Stockée en RIR (champ `effort`) ; mode avancé RIR/RPE conservé (RIR = 10 − RPE) |
| D10 série ratée | RIR 0, haute fiabilité (σ 1,5 %) | Ratée = reps < reps prévues (libellé texte) ; n = r + 0,5 (simulation, §8) |
| D11 série écartée | Reste au journal (validée, XP inchangée), hors estimation | Appui long sur le numéro de série → « Série à écarter (incident) » |
| D12 poids de corps | Pesées datées ; pesée applicable à la date de la série ; rappel hebdomadaire dans l'app | Pesées enregistrées quand Koach est actif ; modifier le poids dans Références = pesée du jour ; première pesée = poids actuel à l'activation |
| D13 repos | Repos réel < 80 % du prescrit → série hors estimation | Mesuré depuis la série validée précédente du même exercice ; sans repos prescrit, pas de contrôle |
| D14 questionnaires | Avant séance : sommeil, forme /10 ; après : douleur 0-10 par mouvement principal ; facultatifs | Désactivés tant que l'information KT-036 n'a pas été acceptée ; « Passer » toujours possible |
| D15 vitesse | Ignorée, champ `v` intact | — |
| D16-D19, D21 modèle | Kalman 1D par mouvement, courbe, biais, endurance | §4 |
| D20 plafonds | +2,5 % / −5 % par semaine | En **masse système** pour les lifts (un % du lest seul n'a pas de sens au MU) ; plafond × semaines écoulées depuis le dernier changement (max 4) ; tests mesurés et accessoires (D22) hors plafond |
| D22 accessoires | Double progression ; `prevention` jamais augmentés | « Deux séances de suite » = cette séance et la précédente contenant la même référence |
| D23 incréments | Haltères 1 kg ≤ 10 kg puis 2 kg ; lest 1,25 kg ; barre 2,5 kg ; poulies 2,5 lb (affichage kg selon réglage) | Type « machine » ajouté (leg curl, mollets) : 2,5 kg par défaut, **à confirmer** |
| D24 prescription | Règles et exemples chiffrés (§5) | RIR **déclaré** (lisible dans la raison affichée) ; base = charge de la dernière série validée ; aucune hausse en semaine de décharge (règle R3 du programme), douleur D26 ni jour de fatigue accepté |
| D25 jour de fatigue | −15 / −25 / −30 % de volume ; charges maintenues ; aucune tentative lourde | Réduction des séries non validées restantes de la séance ; hausses D24 coupées pour la journée |
| D26 douleur | > 3/10 : aucune hausse à la séance suivante ; deux séances de suite : −20 % + isométries 5 × 30-45 s ; jamais l'arrêt ; rappel professionnel de santé | −20 % = **allègement temporaire des charges prescrites** du mouvement (ni la valeur de pilotage ni l'estimation ne changent), levé quand la douleur redescend ≤ 3/10 ou à la main ; isométries = consigne affichée |
| D27 objectifs | Étape = « cible 12 mois » au départ + 12 mois ; final = saisi | Étape par défaut = cibles du programme ; valeurs finales du propriétaire à saisir par lui (LIVRAISON_L7) |
| D28 structure | Désactivée par défaut ; ±1 série / mouvement / semaine ; ±15 % du volume ; jamais décharge/tests/prévention ; ≥ 6 semaines de données | Propositions pour la **semaine suivante** ; (c) = unité des propositions (a) ; décharge anticipée = séries × 0,6 (min 1), charges −10 % ; couche datée, réversible |
| D29 incertitude | σ > 5 % → série de calibrage proposée | Message sur la carte du mouvement (format du jour, difficulté à noter) |
| D30 interface | Carte + raison ; fiche au tap ; section Koach dans STATS | Tuile « Koach » dans STATS › Performances (visible Koach actif) → écran Koach ; aucune notification |
| D31, D34 données | État recalculé ; seules les décisions sont persistées ; correction → rejeu | Cache incrémental égal au rejeu (test) |
| D32 existant / nouveau | Rejouer ce qui a été fait ; S1-S3 = haute fiabilité ; série sans RIR = borne inférieure | Repère initial = valeurs à l'activation (σ 10 %) |
| D33 saisie manuelle | Mesure σ 1 % | Saisies regroupées sur 30 s (frappe « 7 », « 72 », « 72,5 » = une seule mesure) |
| D35-D37 | Référence Python, simulations, une passe, 3.0.0, publication | §8, §9 |

## 3. Données

### 3.1 Série (`SetEntry`, champs optionnels, absents = comportement 2.x)

| Champ | Type | Sens |
| --- | --- | --- |
| `effort` | nombre 0-5, pas de 0,5 | RIR canonique (échelle D9 ; 5 = « 5 ou plus ») ; écrit seulement Koach actif |
| `excluded` | booléen | Série écartée (D11) ; écrit seulement si vrai |

Les versions 2.x ignorent ces clés à l'import. `rir` (texte libre) et `v` sont conservés tels quels.

### 3.2 Journal : prescription datée (KT-029)

`ExerciseLog.prescribed` (texte, Koach actif) : charge et séries affichées à la première validation (« 35 kg · 5×4 »), et `koach` : dernière suggestion appliquée ou refusée. L'historique affiche ce qui était prescrit et réalisé à la date ; il ne relit jamais les valeurs de pilotage actuelles.

### 3.3 Échelle héritée

À la première activation, `koach.legacyScale` = `rpe` si le réglage « RPE » est actif, sinon `rir` (figé). Un texte `rir` sans `effort` est lu : entier ou demi → RIR (RPE : 10 − valeur ; > 5 → 5) ; plage (« 2-3 »), texte, « @8 » → **non interprétable** → la série compte comme une borne inférieure (RIR ≥ 0), jamais comme une mesure.

### 3.4 Décisions Koach (`koach`, section optionnelle de la sauvegarde)

| Clé | Contenu | Bornes à l'import |
| --- | --- | --- |
| `enabled`, `structure`, `advanced` | options | booléens |
| `questionnaires` | `unset` / `on` / `off` | énuméré |
| `legacyScale` | `rir` / `rpe` / absent | énuméré |
| `weighIns` | `[{date: AAAA-MM-JJ, kg}]`, une par jour | 20-400 kg, ≤ 2 000 |
| `history` | `[{at, ref, value, source}]`, source `initial` / `manual` / `koach` / `test` | référence connue, 0-10 000, ≤ 5 000 |
| `decisions` | `[{at, id, kind, status, …}]`, kind `value` / `pain` / `fatigue` / `inSession` / `structure`, status `accepted` / `refused` | ≤ 10 000 |
| `locks` | références verrouillées | références connues |
| `questionnaires` (séances) | `{clé S·J: {sleep 0-24, form 0-10, pain {mouvement: 0-10}}}` | ≤ 400 séances |
| `equipment` | incréments D23 | > 0, ≤ 50 |
| `objectives` | `{réf: {stage: {target, date}, final: {target, date}}}` (modifications seulement) | 0-10 000 ; date AAAA-MM-JJ |
| `adaptations` | `[{id, at, week, kind, movement, exercise?, delta?, sets?, load?, status}]` | semaine 1-40 ; delta ±1 |
| `painRelief` | `{mouvement: {since}}` | mouvements connus |

**Absente** (installation 2.x, Koach jamais activé) : rien n'est écrit, l'export est identique à 2.5.9. Import : section invalide → import refusé (règle L2) ; au démarrage, une entrée illisible est ignorée avec un message, le reste est chargé. Aucune remise à zéro silencieuse ; l'effacement L2b remet `koach` à l'état neuf.

### 3.5 Annotations du programme (`assets/koach_program.json.gz`)

Généré par `tools/koach_annotate.py` depuis l'asset (SHA-256 du JSON source enregistré) : catégorie, référence, mouvement, `rirTarget` (+ `rirTargetMax` pour « RIR 2-3 »), matériel des accessoires, type de semaine (`normal` / `deload` / `test`), k a priori. 1 290 exercices annotés, 1 131 RIR visés. Contrôle d'égalité avec les libellés sur les 1 818 entrées (Python et Dart).

## 4. Modèle (KT-026, KT-027) — paramètres

### 4.1 Grandeurs

- **Masse système** : poids de corps (pesée applicable, D12) + lest pour muscle-up, traction, dip ; charge de la barre pour le squat. Estimation et prescriptions en masse système ; valeur de pilotage = masse − poids du corps actuel (lest) ou barre.
- **Courbe** : %1RM(n) = 1 / (1 + (n − 1) / k) ; n = reps + RIR corrigé ; mesure x̂ = masse / %1RM(n).

### 4.2 A priori de la courbe

Moindres carrés sur les séries classiques du programme (libellé « RIR r · ~p % », « N×R », hors clusters, n ≥ 3) :

| Mouvement | k a priori | Points | Écart quadratique |
| --- | --- | --- | --- |
| Muscle-up lesté | **28,0** | 21 | 0,016 |
| Traction, dip lestés, back squat | **22,4** | 20 chacun | 0,030 |

### 4.3 Filtre et règles de mesure

| Paramètre | Valeur | Origine |
| --- | --- | --- |
| Bruit de processus σ_q | 0,5 % de x par semaine, variance ∝ temps | Demande |
| Bruit d'une série | x × (1,5 % + 1 % × RIR + 0,3 % × max(0, n − 5) + 0,5 % × (rang − 1)) | Demande, **RIR = RIR visé par le programme** (simulation, §8) |
| Effet de jour | les séries d'une séance forment une mesure : moyenne pondérée, variance (Σ 1/σ²)⁻¹ + (5 % × x)² | **Ajout** (simulation) |
| Série ratée | σ 1,5 % (+ rang), n = r + 0,5 | Demande ; +0,5 simulation |
| Test 1RM | σ 0,5 %, meilleure série + ½ incrément | Demande ; +½ incrément simulation |
| Valeur saisie à la main | σ 1 % | Demande (D33) |
| Repère initial | σ 10 % | Demande |
| Séries valides (D18) | RIR ≤ 4, reps + RIR ≤ 12, non écartée, repos ≥ 80 % (D13) | Demande |
| Série sans RIR (D32) | borne x ≥ masse / %1RM(reps) (RIR ≥ 0) | Demande |
| « Facile » (RIR > 4) | borne avec RIR ≥ RIR déclaré − 1 | Choix |
| Clusters | borne x ≥ masse (repos intra-série : relation reps ↔ % non applicable) | Choix |
| Borne inférieure | mise à jour gaussienne d'une contrainte x + ε ≥ L, ε ~ N(0, (5 % x)²) : ne peut que relever, nettement seulement si contredite | Demande (troncature) |
| Séance atypique | écart ≥ 5 % à l'estimation : mise en attente ; comptée seulement si la séance suivante va dans le même sens (≥ 2,5 %), incertitude alors rouverte de l'écart | **Ajout** (simulation) |
| Incertitude trop forte (D29) | σ > 5 % de x | Demande |
| Biais de RIR b (D19) | a priori 0 (σ 1), borné [−2 ; +2] ; ancres : test 1RM, série ratée en série 1, test de max d'endurance ; séries déclarées des **21 jours** précédents | Demande ; fenêtre simulation |
| Courbe personnelle (D17) | ≥ 12 séries valides, écart de n ≥ 3 ; régression n − 1 = k·u + c **ancrée sur les tests 1RM** (u = x_test / masse − 1), rétrécie vers l'a priori (σ_k = 4), bornée [15 ; 45] | Demande ; ancrage et σ_k simulation |
| Endurance (D21) | 1re série d'endurance du jour si RIR ≤ 3 : max = reps + RIR corrigé, σ = 5 % + 2 % × RIR (dips > 30 reps : ×2) ; test mesuré **remplace** (σ 2 %) ; meilleure série = borne | Demande |

**Identifiabilité (limite importante)** : sans test, le 1RM, le k et le biais de RIR ne sont pas séparables à partir des seules séries (une erreur commune de RIR se confond avec une autre courbe). k ne bouge donc qu'autour des tests 1RM (S1, S25, S39 du programme). En simulation, un athlète à k = 28 (a priori 22,4) garde k ≈ 22 après 5 tests : les séries « Faciles » sont écartées par D18 et le biais absorbe une partie de l'écart. L'estimation reste juste aux zones de répétitions pratiquées, mais la courbe personnelle demande un retour terrain.

### 4.4 Valeurs proposées (bilan, D5 b)

Lift : estimation − poids du corps actuel, arrondie au plus proche (lest 1,25 kg ; barre 2,5 kg), bornée par D20 en masse système, proposée si l'écart dépasse 0,75 incrément (hystérésis, simulation) et si σ ≤ 5 % ; test 1RM → sa valeur (source « test »), sans plafond. Endurance : max estimé arrondi à la rep, écart ≥ 1 rep, D20 ; test → sa valeur. Accessoires : D22 sur la grille du matériel. Douleur : D26. Verrou : aucune proposition. Douleur > 3/10 dans la séance : aucune hausse.

## 5. Prescription pendant la séance (D24)

Après validation d'une série, sur la charge de la dernière série validée (masse système), cible = RIR visé du programme :

| Situation | Charge des séries restantes |
| --- | --- |
| Série 1 : RIR ≥ cible + 2 | +6 %, arrondi à l'incrément **inférieur**, plafond +5 kg |
| Série 1 : RIR = cible + 1 | +3 %, arrondi inférieur, plafond +2,5 kg |
| RIR = cible | aucun changement |
| Une seule série à RIR ≤ cible − 1 | aucun changement |
| Deux séries consécutives à RIR ≤ 1, cible ≥ 2 | −3 %, arrondi à l'incrément **supérieur** |
| Série ratée | −3 % (−6 % s'il manque ≥ 2 reps), arrondi supérieur |

Exemples vérifiés par test (poids 71,5 kg) : traction +32,5 → **+35** (cible + 1) ou **+37,5** (cible + 2) ; muscle-up +5 → **+6,25** ou **+8,75** ; squat 97,5 → **100** ou **102,5**. Conformes à la demande : aucune correction. Lest jamais négatif (0 = poids du corps).

## 6. Fatigue, douleur, objectifs, structure

- **D25** : écart du 1RM de la série 1 à l'estimation d'avant séance : ]−7,5 ; −5] % → −15 % ; ]−10 ; −7,5] % → −25 % ; ≤ −10 %, sommeil < 5 h ou forme ≤ 4/10 → −30 % (questionnaire : proposé avant la série 1).
- **D26** : dernière douleur notée > 3/10 → aucune hausse (séance et bilan) ; deux séances notées de suite > 3/10 → proposition d'allègement −20 % + isométries 5 × 30-45 s, avec le rappel « une douleur qui persiste relève d'un professionnel de santé ».
- **D27** : pente observée = régression sur l'estimation de fin de semaine des 6 dernières semaines (≥ 3 points) ; pente requise = (cible − estimation) / semaines restantes ; en retard < 80 %, en avance > 120 % ; sinon « dans les temps » ; « atteint », « échéance passée », « données insuffisantes ».
- **D28** : ±1 série sur l'exercice principal du mouvement pour la semaine suivante selon le statut de l'étape (à défaut l'objectif final), si ≥ 6 semaines de données valides (sinon « données insuffisantes ») ; total ≤ 15 % des séries de la semaine ; décharge anticipée si l'estimation baisse deux semaines de suite avec un signal de fatigue (D25 ou questionnaire) ; jamais en décharge ni en semaine de tests ; accepté = couche datée, « Annuler » la retire.

## 7. Interface (KT-033) et confidentialité (KT-036)

- Réglages → **Koach** : interrupteur (explication au premier usage), difficulté simple ou avancée (RIR/RPE), questionnaires (information préalable), « Koach adapte la structure » (désactivé), matériel, objectifs, pesées.
- Séance : ✓ sur une série qui exige la difficulté → choix en 6 boutons (libellé + « encore N »), un tap valide ; ailleurs, bouton « Difficulté » facultatif ; suggestion + raison en une ligne, « Appliquer » / « Garder ma charge » ; fiche au tap.
- Bilan Koach : douleur (facultatif), propositions « Accepter » / « Refuser » / « Tout accepter ».
- STATS › Performances → Koach : courbe du 1RM estimé (bande d'incertitude, projection vers l'étape et l'objectif final, statut en texte), maxima d'endurance, historique daté des valeurs (manuelle, Koach, test).
- Accessibilité : 320 px, texte 130-200 %, libellés TalkBack ; statut toujours écrit (jamais la couleur seule).
- **Données de santé potentielles** : sommeil, forme, douleur. Information claire avant activation ; strictement facultatifs ; inclus dans l'export et la suppression ; restent sur le téléphone. Documents préparatoires et points à faire valider : `docs/CONFIDENTIALITE_KOACH.md`.

## 8. Simulations (KT-035) — critères et justification des ajustements

Athlète fictif de 71,5 kg, 1RM système 110 kg, une séance de traction lestée par semaine (vague 5×5 RIR 3 / 5×4 RIR 2 / 4×3 RIR 2), RIR déclaré = arrondi(RIR réel + N(0, 1) + biais), incidents 5 % (signalés, D11), graines fixées (mulberry32). Critère évalué au **95e centile** sur 60 athlètes par cas (maximum rapporté) ; C5-C7 sur le maximum.

| Critère | Seuil | Résultat retenu (p95 / max) |
| --- | --- | --- |
| C1 erreur après 6 séances, a priori juste (progression, plateau, baisse) | < 3 % | 2,25 % / 3,26 % |
| C2 erreur après 6 séances, a priori faux ±15 % (Koach actif) | < 3 % | 2,49 % / 5,53 % |
| C3 déplacement par un mauvais jour isolé (−8 %) | < 1 % | 0,49 % / 1,08 % |
| C4 biais de RIR après 2 tests (biais −1, 0, +1) | ±0,5 RIR | 0,45 / 0,61 |
| C5 changements de sens des propositions / 4 séances (plateau) | ≤ 1 | 1 |
| C6 dépassements des plafonds D20 / D24 | 0 | 0 |
| C7 rejeu complet − cache incrémental | < 0,01 kg | 0 |

Ablation (40 athlètes par cas, p95 ; C5 = maximum) — chaque ligne ajoute un élément :

| Variante | C1 | C2 | C3 | C4 | C5 |
| --- | --- | --- | --- | --- | --- |
| a. Modèle de la demande seul | 5,84 % | 4,59 % | 6,03 % | 0,63 | 2 |
| b. + bruit calculé sur le RIR visé | 5,94 % | 4,26 % | 6,70 % | 0,63 | 2 |
| c. + effet de jour 5 % | 2,20 % | 2,44 % | 1,89 % | 0,63 | 2 |
| d. + séance atypique mise en attente | 2,37 % | 2,96 % | 0,49 % | 0,63 | 2 |
| e. + série ratée r + 0,5, test + ½ incrément | 2,37 % | 2,33 % | 0,49 % | 0,50 | 2 |
| f. + biais sur 21 jours, σ_k = 4 | 2,37 % | 2,33 % | 0,49 % | 0,44 | 2 |
| g. **retenu** (+ hystérésis 0,75 incrément) | 2,37 % | 2,40 % | 0,49 % | 0,44 | 1 |

Pourquoi : pondérer par le RIR **déclaré** donne plus de poids aux séries déclarées dures, donc biaise l'estimation vers le bas (−2 % mesuré au plateau) ; sans effet de jour, les 4-5 séries d'une même séance comptent comme indépendantes ; un mauvais jour isolé déplace alors l'estimation de 2-6 % ; la mise en attente l'écarte tant qu'il n'est pas confirmé, et la réouverture de l'incertitude suit une vraie baisse (médiane 1 séance) ; « r + 0,5 » et « + ½ incrément » corrigent les biais d'arrondi (capacité entre r et r + 1, charge suivante non réussie) ; l'hystérésis supprime les allers-retours d'un incrément.

Informatif (dépend du modèle, jamais une preuve d'efficacité) : incidents **non signalés** (10 %) → erreur p95 ≈ 7 % (signaler les incidents compte) ; baisse réelle de 5 % suivie en 1 séance (médiane) ; avec un modèle de progression où seules comptent les séries réellement proches de l'échec, programme fixe +2,6 % contre Koach +6,9 % en 24 séances — résultat entièrement déterminé par ce modèle.

## 9. Référence Python et recoupement

`tools/koach_reference.py` (bibliothèque standard) et `lib/koach_engine.dart` implémentent les mêmes fonctions (rejeu, cache, propositions, D24, D25, D26, D27, D28, grilles, échelle héritée) ; fixtures JSON partagées `test/fixtures/koach/*.json` (entrées + sorties Python) : le test Dart exige ±0,01 kg (et égalité exacte des décisions) ; le test Python vérifie que les sorties attendues sont à jour. Simulations : même générateur (mulberry32 + Box-Muller) dans les deux langages.

## 10. Migration 2.5.x → 3.0.0 (KT-034)

- Aucune donnée réécrite à la mise à jour ; Koach reste désactivé ; export identique tant que Koach n'a jamais été activé.
- Première activation : repère initial daté (valeurs de pilotage actuelles, source `initial`), première pesée (poids actuel), échelle héritée figée, puis rejeu de tout le journal existant (séances faites seulement).
- Import d'une sauvegarde 2.x : lue comme en 2.5.9 (section `koach` absente = Koach désactivé, aucune donnée synthétisée) ; export 3.0.0 ensuite : format 3, champs optionnels.
- Version antérieure lisant une sauvegarde 3.0.0 : clés `koach`, `effort`, `excluded`, `prescribed` ignorées ; données 2.x intactes.

## 11. Limites et points à valider

- **Validation scientifique** : paramètres à éprouver sur le terrain et à faire valider par un préparateur physique compétent : σ_jour 5 %, seuil atypique 5 %, bruit des séries, fenêtre du biais, a priori de k (issu des libellés du programme), plafonds D20, bandes D25, allègement D26, décharge anticipée D28, incréments « machine ».
- Courbe personnelle peu identifiable hors tests (§4.3).
- Incidents non signalés : dégradent l'estimation ; D11 est essentiel.
- Qualification juridique des questionnaires (données de santé ?) : **non tranchée** (§7, `docs/CONFIDENTIALITE_KOACH.md`).
- Aucune vérification sur téléphone.

## 12. Décisions manquantes (non bloquantes, choix appliqués ci-dessus)

1. Valeur par défaut de l'interrupteur (retenu : désactivé, activation explicite).
2. Incrément des machines guidées (retenu : 2,5 kg).
3. Paramètres de la décharge anticipée D28 (retenu : séries × 0,6, charges −10 %).
4. D26 : allègement des charges prescrites (retenu) plutôt qu'une baisse de la valeur de pilotage.
5. Plafond D20 exprimé en masse système (retenu) plutôt qu'en lest.
