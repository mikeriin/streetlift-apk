# Intégrer kalis_adapt 0.3.1 dans l'application (lot CI)

L'application intègre aujourd'hui `kalis_adapt` 0.2.3, `kalis_plan` 0.2.3 et `kalis_core` 0.4.2 (dev6.9.3,
livraisons CI1 à CI1d). Ce document dit ce qu'il faut faire pour passer à `kalis_adapt` 0.3.1 (avec
`kalis_plan` 0.3.1 et `kalis_core` 0.4.3, livrés ensemble). Le pendant pour le programme écrit est
`packages/kalis_plan/docs/INTEGRATION_CI.md`. Ce document est celui que cite `CONTRAT.md`, § 13.3.

Sources lues : `CHANGELOG.md`, `CONTRAT.md` (§ 4.5, 11 à 13), `lib/src/session.dart`, `endurance.dart`,
`replay.dart`, `results.dart`, `review.dart`, `engine.dart`, `params.dart`, `coach.dart` de ce paquet ;
`kalis_core/CHANGELOG.md`, `CONTRAT.md` (§ 4, 5, 12, 16), `docs/RAISONS_0_4.md`,
`data/reason_texts_fr_0_4.json`, `lib/src/generated/reason_codes.g.dart` ; décisions C10 et C11 du
pipeline. Quand une chose vient du code et non d'un document, c'est dit (« d'après le code »).

Ce que l'application fait déjà (CI1 à CI1d) n'est pas répété : séries allégées recalculées, tests
reportés, carte « Arrêt pour douleur », reprise graduée, palier de reprise (`adapt.load_held`, cause
`pain_return`), renvoi vers un professionnel, couche d'ajustements.

## 1. Ce qui change entre 0.2.3 et 0.3.1

### 1.1 Contrat

- 0.3.0 : additif ; `kalis_core` 0.4.3 exigé (cinq codes de raison d'endurance, § 3).
  `AdaptParams.enduranceConduct` (vrai par défaut) rejoue 0.2 au banc.
- 0.3.1 : additif. Trois paramètres (`coachCorridorHeavyShare` 0,85 ; `coachRepLoadShare` 0,025 ;
  `coachRepGapMax` 4) et un argument du constructeur : `KalisAdapt(restructureImported: false)` par
  défaut. Aucun type ni code de raison nouveau (§ 13).

### 1.2 0.3.0 — endurance, conditionnement, hybrides (lot CA2, partie 1)

Les lignes de course, de cardio, de conditionnement et de mobilité étaient servies telles qu'écrites et
ignorées par le modèle de fatigue. Depuis 0.3.0 elles sont conduites d'après le journal, **dans les deux
modes** (0.1 et coach), jamais au-dessus de l'écrit (durée, distance, répétitions, séries, effort, allure ;
invariants E1 à E3). Détail : `CONTRAT.md`, § 12.

| Règle | Déclencheur | Effet | Raison |
| --- | --- | --- | --- |
| Reprise après une coupure | aucune séance depuis 7 jours ; 14 jours | course, cardio, conditionnement à 70 % ; 50 % | `adapt.endurance_shortened` (`resume_7`, `resume_14`) |
| Jour sans | bilan bas (palier 1 ou 2), douleur du bas du corps ≥ 3/10, ou course des 3 derniers jours notée ≥ 2 flammes au-dessus de l'effort visé | séance de qualité → course facile de la durée de travail écrite, à 5 en réserve ; sinon retirée | `adapt.easy_instead` (`health`, `health_strong`, `leg_pain`, `hard_run`) |
| Bilan très bas | palier 2 | durée de course et de cardio à 70 % | `adapt.endurance_shortened` (`health_strong`) |
| Sortie bornée | au moins 3 courses dans les 30 jours | course du jour ≤ plus longue course des 30 jours + 10 % ; un test plus long devient une course bornée | `adapt.run_capped` (`percent` 10) |
| Conditionnement mis à l'échelle | jour sans (hors course dure seule) ou 2 jours durs de suite (effort noté ≥ 8) | 75 % des répétitions ou de la durée, une flamme de moins | `adapt.wod_scaled` (`cause`, `percent` 75) |
| Fatigue croisée | course notée ≥ 8 flammes la veille | une flamme de moins sur les exercices du bas du corps | `adapt.cross_fatigue` (`hard_run`) |
| Mobilité | — | servie telle qu'écrite | — |
| Forme-fatigue | chaque ligne d'endurance faite | 10 min d'effort comptent comme une série de travail (6 au plus), pondérées par l'effort | — |
| Élastique (street, mode coach) | une séance entière dite ≥ 2 répétitions plus facile que visé | élastique plus fin dès la séance suivante (7 jours au moins depuis le dernier changement) | raisons existantes |

### 1.3 0.3.1 — croisement final (lot CY, partie 0)

| Règle | Effet | Raison |
| --- | --- | --- |
| Première gêne du poignet | mode coach, poignet ≥ 3/10 dans les 14 jours, aucun arrêt : une poussée au poids du corps paume à plat passe tout de suite sur un appui neutre faisable (parallettes, poignées, ou `sw-pompe-inclinee` mains sur une barre basse quand le matériel compte `barre basse`) ; sans appui neutre, la poussée reste, dose plafonnée | `adapt.pain_reported` (`zone: wrist_hand`, `intensity` = gêne la plus forte des 14 jours) |
| Arrêt du poignet | la pompe mains sur la barre basse compte comme appui neutre ; un appui neutre à contrainte moyenne reste (dose de l'arrêt) au lieu d'être retiré | raisons de l'arrêt (déjà intégrées) |
| Couloir à 85 % | part écrite ≥ 85 % du 1RM : la charge servie ne dépasse plus l'écrit (elle peut descendre) | aucune nouvelle |
| Borne à schéma changé | même emplacement, schéma différent de la dernière séance : charge totale ≤ dernière charge × (1 + hausse à schéma égal) × (1 + 2,5 % par répétition de moins, 4 au plus) ; un cran au moins | `adapt.load_held`, cause `cap` (d'après le code) |
| Repère de jour bas | une séance faite un jour de bilan bas ne devient plus le repère d'un jour bas suivant | aucune |
| Bloc importé | `KalisAdapt(restructureImported: true)` laisse `review` proposer les restructurations de `kalis_plan` sur un bloc de plus de six semaines | raisons des propositions (existantes) |

## 2. Prescriptions nouvelles : afficher, journaliser, minuter

### 2.1 Règles communes du journal

Les moteurs lisent juste seulement si le journal dit ce qui a été fait (contrat de `kalis_core`, § 5 et
§ 12) :

- une ligne (`SetRecord`) par série ; mini-séries d'un cluster ou d'un rest-pause dans `parts`, `reps`
  = total ;
- rôle de la ligne (`top`, `back_off`, `interval`, `wave`, `rung`, `warmup`, `test`, `attempt`) ;
- flammes de 1 à 10 (8 = 1,5 en réserve) ; « pas de note » = champ absent. Une ligne d'endurance sans
  flammes est lue comme facile (5 en réserve) pour la fatigue (`replay.dart`) ;
- **course et cardio** : `seconds` (durée réelle) et `distanceMeters` si connue. Une distance seule est
  convertie à la vitesse tirée des lignes qui ont les deux, sinon 2,6 m/s (`endurance.dart`) ;
- **échauffement** : rôle `warmup`. Il est exclu de la course du jour, de la borne des 30 jours, des
  jours durs et de la fatigue ;
- **bilan du jour** (`HealthCheck`) enregistré avec la séance : il fixe le palier (§ 4.5 du contrat) et
  le jour bas ;
- **douleurs** : `pains` absent = question non posée ; liste vide = aucune douleur (la zone est
  effacée pour le moteur, `notePains`). Zones du bas du corps lues pour le jour sans : `hip`, `thigh`,
  `knee`, `lower_leg`, `ankle_foot` (14 jours) ; poignet : `wrist_hand`.

### 2.2 Conduite d'endurance (course, cardio)

**Afficher.**
- Chaque changement arrive comme un `SessionAdjustment` : `setsReduced` (raccourci, borné, reprise),
  `exerciseSwapped` (qualité → course facile : `ca-footing-endurance-fondamentale`, ou
  `ca-course-tapis-endurance` pour un tapis), `exerciseRemoved` (qualité retirée).
- Ces `setsReduced` ne portent pas de `setsDelta` (d'après le code) : afficher le texte de la raison
  et la durée servie, pas un nombre de séries en moins.
- Textes : § 3. Causes à rendre en clair (§ 3.2).
- Un test de course plus long que la borne est servi comme une course de nature `work` (plus `test`),
  avec seulement `adapt.run_capped` : l'application peut le dire en comparant à la ligne écrite.

**Journaliser.** Chaque course : une ligne par fraction ou une ligne pour une course continue ; `seconds`,
`distanceMeters`, flammes. Le jour sans et la borne en dépendent : sans durée ni distance, la course ne
compte pas ; il faut au moins trois courses dans les 30 jours pour que la borne joue.

**Minuter.**
- Course continue : compte à rebours de la durée **servie** (`secondsLow`/`secondsHigh` de la ligne
  servie, arrondie vers le bas : minute à partir de 5 min, sinon 5 s ; distance à 100 m), pas de
  l'écrite.
- Course facile de remplacement : une ligne, durée en minutes, sans repos ni allure.
- Fractions : chrono par fraction, repos écrit (`restMode: jog` : trottiné). Une fraction de trop peut
  être retirée par la borne : le nombre de lignes servies fait foi.

### 2.3 Conditionnement

**Afficher.** `adapt.wod_scaled` (75 %) sur les membres de la pièce ; l'effort visé baisse d'une flamme.

**Journaliser.** Une ligne par série écrite de chaque membre : répétitions (ou secondes, mètres,
calories) et flammes. Un jour dur = une ligne de conditionnement notée 8 ou plus. Le résultat du groupe
va aussi dans `SessionRecord.groupResults` (contrat), mais `kalis_adapt` ne le lit pas (d'après le code).
Pour la fatigue, une ligne compte `seconds`, sinon la distance, sinon répétitions × 3 s.

**Minuter.** Le minuteur suit le groupe (`GroupSpec` : AMRAP, EMOM, « pour le temps », chipper,
intervalles ; document de `kalis_plan`, § 2.4). La mise à l'échelle réduit les lignes des membres
(répétitions, secondes, distance, calories, ou nombre de séries d'un fractionné sans répétitions). Elle ne
change pas la durée ni la limite de temps du groupe (d'après le code : seules les lignes sont modifiées).

### 2.4 Fatigue croisée

**Afficher.** La raison `adapt.cross_fatigue` est ajoutée aux raisons de l'exercice du bas du corps,
**sans** `SessionAdjustment` (d'après le code). L'afficher sous l'exercice, avec l'effort visé servi.

**Journaliser.** La course de la veille doit porter ses flammes : 8 et plus = course dure.

**Minuter.** Rien de nouveau.

### 2.5 Première gêne du poignet (et point imposé par CY)

**Afficher.**
- Échange `exerciseSwapped`, `replacementExerciseId` = l'appui neutre, raison `adapt.pain_reported`
  (`zone: wrist_hand`, `intensity`).
- **Point imposé par CY** : quand le remplaçant est `sw-pompe-inclinee` (« Pompe inclinée (mains
  surélevées) ») avec cette raison, l'application affiche **« mains serrées sur la barre basse, poignets
  droits »**.
- Le moteur ne compte cette pompe comme appui neutre que faite mains sur une barre basse : c'est pourquoi
  la consigne compte.

**Journaliser.**
- La gêne du poignet à chaque bilan où elle est présente (`wrist_hand`, intensité). La règle lit les
  signalements des 14 jours.
- Une liste vide quand il n'y a plus de douleur.
- Les séries du remplaçant sous son propre identifiant.

**Minuter.** Repos écrit, comme la ligne d'origine.

### 2.6 Couloir à 85 %, borne à schéma changé, repère de jour bas

- **Afficher** : la charge servie. Le couloir ne donne pas de raison nouvelle ; la borne à schéma changé
  peut donner `adapt.load_held` cause `cap` (texte existant).
- **Journaliser** : charge réelle, répétitions et flammes de chaque ligne, rôle `top` ou `back_off`. La
  borne compare la charge totale à la dernière séance du même emplacement (`slotId`). Le bilan du jour
  doit être enregistré : sans lui, une séance de jour bas peut redevenir un repère.
- **Minuter** : rien de nouveau.

### 2.7 Élastique (street, 0.3.0)

- **Journaliser** l'assistance en charge négative à chaque série, avec les répétitions et les flammes.
  Une série repère (ouverte) compte aussi.
- **Afficher** le cran conseillé (raisons existantes).

### 2.8 Restructuration d'un bloc importé

- **Activer** `KalisAdapt(restructureImported: true)` pour le programme du propriétaire seulement (C11).
  Le défaut ne change rien pour les autres utilisateurs.
- **Afficher** les propositions de restructuration dans Évolution, comme les autres. CI1c refusait une
  proposition « non applicable jour pour jour » ; C11 et le lot CI1e lèvent cette garde.
- **Journaliser** : rien de nouveau. Séances faites et séries validées jamais réécrites (C11.2).

## 3. Codes de raison

### 3.1 Nouveaux codes (`kalis_core` 0.4.3)

138 codes au registre (`reason_codes.g.dart`), dont 5 nouveaux depuis 0.4.2, en fin de registre.
Aucun autre code nouveau n'est émis par `kalis_adapt` 0.3.x ni `kalis_plan` 0.3.x (comparaison du code
avec 0.2.3).

| Code | Paramètres (type) | Texte proposé (`RAISONS_0_4.md`) | Émis par la règle |
| --- | --- | --- | --- |
| `adapt.run_capped` | `percent` (entier) | Sortie raccourcie : pas plus de {percent} % au-dessus de ta plus longue sortie du mois. | sortie bornée |
| `adapt.easy_instead` | `cause` (texte) | Aujourd'hui, endurance facile à la place de la séance de qualité ({cause}). | jour sans |
| `adapt.endurance_shortened` | `cause` (texte), `percent` (entier) | On raccourcit : {percent} % de ce qui était prévu ({cause}). | reprise, bilan très bas |
| `adapt.wod_scaled` | `cause` (texte), `percent` (entier) | WOD mis à l'échelle : {percent} % de ce qui était prévu ({cause}). | conditionnement |
| `adapt.cross_fatigue` | `cause` (texte) | Un peu plus de marge sur les jambes : ta course d'hier était dure. | fatigue croisée |

Code existant réutilisé par 0.3.1 : `adapt.pain_reported` (`zone` texte, `intensity` entier) pour la
première gêne du poignet ; `adapt.load_held` (cause `cap`) pour la borne à schéma changé.

### 3.2 Causes (paramètre `cause`)

Les paquets donnent les codes et leur sens (`CONTRAT.md`, § 12.1 ; `session.dart`), pas de libellé
français. Le libellé est à écrire par l'application.

| Cause | Sens |
| --- | --- |
| `health` | bilan bas (palier 1) |
| `health_strong` | bilan très bas (palier 2) |
| `leg_pain` | douleur du bas du corps à 3/10 ou plus |
| `hard_run` | course des 3 derniers jours notée au moins 2 flammes au-dessus de l'effort visé (`easy_instead`) ; course dure la veille (`cross_fatigue`) |
| `resume_7` | reprise après 7 jours sans séance |
| `resume_14` | reprise après 14 jours ou plus sans séance |
| `hard_streak` | deux jours durs de conditionnement de suite |

### 3.3 Notes de coach

La liste exacte des 108 codes de `CoachNotes.all`, avec ceux apparus après 0.2.3 (`clearance_first`,
`shoulder_history` en 0.3.1 ; `wod_pace`, `chair_squat`, `knee_shallow`, `balance_progress`,
`hold_support`, `warmup_run`, `warmup_gym`, `warmup_health`, `short_run`, `short_health` en 0.3.0), est
dans le document de `kalis_plan`, § 3.2.

## 4. Migration des programmes en cours

| Cas | Ce qui se passe |
| --- | --- |
| JSON | `kalis_core` 0.4.3 relit et réécrit à l'identique un JSON de 0.4.2 ; 0.4.x relit un JSON de 0.3.0. Blocs de `kalis_plan` 0.1 et 0.2 et journal (schéma 1) se relisent tels quels. |
| Bloc écrit par `kalis_plan` 0.2.x, en cours | relu tel quel et servi en mode coach (il porte les champs du contrat 0.4.0). Les règles de séance de 0.3.0 et 0.3.1 s'appliquent **dès la mise à jour** : elles sont décidées à chaque séance, pas écrites dans le bloc. |
| Bloc de `kalis_plan` 0.1 | servi comme en 0.1 ; la conduite d'endurance (§ 1.2) s'y applique aussi. Mode coach au bloc suivant, s'il est écrit par le chemin coach. |
| `KalisAdapt(legacy: true)` | sert tout bloc comme en 0.1.0 (comparaisons au banc). |

**Programme importé de 40 semaines (DECISIONS C11).** Toutes les fonctionnalités doivent s'y appliquer.
`CONTRAT.md`, § 13.3 : le bloc importé n'a aucun champ du contrat 0.4.0, il est donc servi par le moteur
de 0.1 (`blockCoached` faux). Ce n'est pas une exclusion « importé » : les règles lisent des champs
absents.

Tant qu'il n'est pas converti en blocs au contrat 0.4.0, **ne s'appliquent pas** :

- tout le mode coach : couloir (dont le couloir à 85 %), marques d'emplacement (borne à schéma changé,
  repère de jour bas), techniques exécutées et relues, séries repère du mode coach ;
- la conduite sous douleur du mode coach : arrêt, reprise graduée, poignet (première gêne, appuis
  neutres, poignet sensible) ;
- les tests reportés, le jour d'épreuve, l'élastique du mode coach ;
- les restructurations, tant que `restructureImported` est faux.

**S'appliquent quand même** :

- la conduite d'endurance de 0.3.0 (deux modes) sur les lignes de course, cardio, conditionnement ;
- les règles de 0.1 (bilan gradué § 4.5, douleur § 4.7 : au-dessus de 3/10, aucune hausse sur la
  zone, remplacement à 4/10 sous contrainte forte ou 7/10 sous contrainte moyenne ; temps du jour).

**Seule exclusion par la taille** : `BlockView.imported` est vrai pour un bloc de plus de six semaines
(`replay.dart`). Effets :

- restructurations : `restructureImported: true` les permet ;
- niveau de déblocage des propositions : `blocksDone` compté par tranches de six semaines (`review.dart`).

Un bloc converti de six semaines au plus n'est plus « importé » pour le moteur (déduction du code).

**Ce qu'il faut à la conversion** : les champs que lisent ces règles (phase, intention de semaine,
techniques, tests ; § 11 : intention, échelle de figure, groupe, technique, intensité, règle
d'autorégulation, test, étape de figure). C'est l'annotation du lot CI1e (`LANCEMENTS.md`). Au moment de
ce document, aucune livraison de CI1e n'est disponible.

## 5. Points imposés par le lot CY

### 5.1 Note de bloc `clearance_first`

Elle doit être montrée **avant la première séance**, comme une étape à confirmer. Deux réponses :
« J'ai eu l'avis d'un médecin ou d'un kiné » et « Pas encore ». Tant que ce n'est pas confirmé, la séance
montre seulement les mouvements qui ne réveillent pas la douleur. Garder simple : afficher un
**avertissement bloquant à confirmer**. La note vient de `kalis_plan` (raisons du bloc) ; `kalis_adapt`
ne la lit pas. Texte et conditions : document de `kalis_plan`, § 2.2 et § 5.1.

### 5.2 Pompe remplacée pour le poignet

Quand `kalis_adapt` remplace une pompe par `sw-pompe-inclinee` avec la raison `adapt.pain_reported`
zone poignet, l'application affiche **« mains serrées sur la barre basse, poignets droits »** (§ 2.5).

## 6. Non déterminé

- **Pompe inclinée écrite par le bloc.** Si la ligne écrite est déjà `sw-pompe-inclinee` et que le
  matériel compte `barre basse`, le moteur la tient pour neutre et la garde, sans raison. La consigne de
  CY n'est alors pas déclenchée. Faut-il l'afficher aussi ? Non tranché.
- **Remplacement pendant un arrêt.** Pendant un arrêt du poignet, le remplaçant peut aussi être
  `sw-pompe-inclinee`, avec les raisons de l'arrêt et non `adapt.pain_reported`. Même consigne ? Non
  tranché par CY.
- **Test de course borné.** Il est « reporté » selon le `CHANGELOG.md`. Comment il est reservi ensuite :
  non trouvé dans le code lu.
- **Résultat d'un contre-la-montre.** `testResults` ne le rend pas (`results.dart` : exercices
  modélisés seulement). L'application doit l'écrire au profil (document de `kalis_plan`, § 2.5).
- **Libellés des causes d'endurance** : à écrire par l'application (§ 3.2).
- **Restructuration réelle sur le bloc importé.** Restructuration de `kalis_plan` (chemin 0.1 tant que
  le bloc n'a pas d'intention) jamais rejouée sur le programme du propriétaire (LIVRAISON_CI1c.md,
  partie 4).
- **Lot CI1e.** État de l'annotation au contrat 0.4.0 : inconnu ici.
