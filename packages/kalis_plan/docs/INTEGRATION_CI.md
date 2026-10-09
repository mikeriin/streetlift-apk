# Intégrer kalis_plan 0.3.1 dans l'application (lot CI)

L'application intègre aujourd'hui `kalis_plan` 0.2.3, `kalis_adapt` 0.2.3 et `kalis_core` 0.4.2 (dev6.9.3,
livraisons CI1 à CI1d). Ce document dit ce qu'il faut faire pour passer à `kalis_plan` 0.3.1 (avec
`kalis_adapt` 0.3.1 et `kalis_core` 0.4.3, livrés ensemble). Le pendant pour le moteur d'évolution est
`packages/kalis_adapt/docs/INTEGRATION_CI.md`.

Sources lues : `CHANGELOG.md`, `CONTRAT.md`, `docs/NOTES_COACH.md`, `docs/CALIBRAGE_CP2.md`,
`lib/src/coach/prescribe.dart`, `general.dart`, `texts.dart`, `athlete.dart`, `lib/src/engine.dart` de ce
paquet ; `kalis_core/CHANGELOG.md`, `CONTRAT.md` (§ 5, 12, 16), `docs/RAISONS_0_4.md`,
`lib/src/generated/reason_codes.g.dart` ; `kalis_adapt/CONTRAT.md` § 11 à 13 et `lib/src/endurance.dart`,
`replay.dart`, `results.dart`, `session.dart` ; décisions C10 et C11 du pipeline. Quand une chose vient
du code et non d'un document, c'est dit (« d'après le code »).

Ce que l'application fait déjà (CI1 à CI1d) n'est pas répété : rôles des lignes (Tête, A1…, M1…, T1…,
Éc1…, P1…, V1…), panneau du coach, textes de `coachReasonText`, chronos d'EMOM technique et de maintiens,
saison, Jour J de force, cartes de douleur, tests reportés, couche d'ajustements.

## 1. Ce qui change entre 0.2.3 et 0.3.1

### 1.1 Contrat

- `kalis_plan` 0.3.0 et 0.3.1 : contrat additif. Aucune API publique retirée.
- `kalis_core` 0.4.3 est exigé. Il ajoute cinq codes de raison d'endurance (§ 3.1). Un JSON de 0.4.2
  se relit et se réécrit à l'identique.
- 10 codes de note de coach en 0.3.0, 2 en 0.3.1 (§ 3.2). Les 7 règles de progression ne changent
  pas ; le texte de `duration_step` change (0.3.1).
- Aucun autre code de raison nouveau émis par `kalis_plan` ou `kalis_adapt` (comparaison du code de
  0.2.3 et de 0.3.1 : seuls les cinq codes d'endurance apparaissent).

### 1.2 0.3.0 — les autres disciplines (lot CP2, partie 1)

| Thème | Changement |
| --- | --- |
| Éligibilité | `coachEligible` accepte un profil au schéma 3 dont la discipline principale est musculation, course et cardio, CrossFit, mobilité ou forme générale, avec n'importe quelles disciplines secondaires. Il faut l'expérience, au moins un jour de disponibilité, et l'ancienneté sauf pour un débutant (d'après `athlete.dart`). |
| Styles | hypertrophie, force (force athlétique, force générale), endurance, conditionnement, santé (`lib/src/coach/general.dart`). Un débutant ne fait pas de force athlétique. |
| Musculation | répartition selon le nombre de séances ; polyarticulaires d'abord ; groupe prioritaire en tête ; charges vers 72 % du 1RM pour 8 à 12 répétitions à 2-3 en réserve ; charge « à calibrer » quand la barre vide dépasse le 1RM estimé. |
| Force | squat 2-3 fois, couché 3-4 fois, soulevé de terre 1-2 fois par semaine ; série de tête et séries allégées ; antécédent lombaire : soulevé de terre en séries égales, sans série de tête ni test. |
| Course | sortie longue le jour le plus long, 110 % au plus de la plus longue des quatre semaines d'avant ; 1 à 2 séances de qualité ; allure des fractions au kilomètre ; allure de l'objectif une semaine sur deux ; débutant : footing seul six semaines ; affûtage à trois fractions ; test de mi-parcours sur la moitié de la distance ; l'épreuve le jour J ; 12 min gardées pour le renforcement du coureur. |
| Conditionnement | pièces AMRAP, EMOM, « pour le temps », suite imposée (chipper), intervalles, ramenées au créneau ; bloc de force à partir de 40 min ; muscle-up visé : pratique, dips à la barre droite, préparation scapulaire. |
| Santé, mobilité, senior | renforcement 2-3 fois par semaine ; équilibre à chaque séance dès 65 ans ; assis-debout de chaise ; étirements ; repos 60 à 75 s ; marche et cardio doux qui prennent le temps restant ; genou gêné : chaise haute. |
| Semaines | semaines « de test » sans test (musculation, santé) écrites comme des allègements ; un mouvement d'épreuve non entraîné ne se teste pas. |
| Mode prudent | questionnaire de santé ou 65 ans et plus : CrossFit écrit en programme de santé ; course sans séance de qualité. |
| Relecture `coachAudit` | le jour d'une course d'épreuve n'est pas compté dans la durée des séances. |

Changements qui touchent aussi le street (0.3.0) : charge écrite au-dessus du 1RM de travail → « à
calibrer » ; `interval_pace` en allure **au kilomètre** (avant : « 400 m ») ; affûtage de course à trois
fractions ; plancher d'une course facile borné par le créneau ; consigne `easy_pace` alignée sur la durée
réduite d'une marche de fin de séance.

### 1.3 0.3.1 — sécurité (lot CY, partie 0)

| Règle | Effet visible |
| --- | --- |
| Avis médical avant la première semaine | note de bloc `clearance_first` (questionnaire de santé « prudent », ou gêne déclarée à 5/10 ou plus). À montrer avant la première séance (§ 5.1). |
| Épaule opérée ou à antécédent | note `shoulder_history` sur la ligne d'un développé au-dessus de la tête. |
| Pas de test maximal sur une articulation douloureuse | gêne relevée au bloc précédent à 3/10 ou plus, gêne déclarée à 4/10 ou plus, ou zone à l'arrêt : tests de fin de bloc et test de l'objectif daté retirés. Une vraie épreuve inscrite reste écrite. |
| Jour de test de tirage | le travail ordinaire de tirage vertical et de muscle-up qui restait après les tests saute. |
| Premier muscle-up | test d’un muscle-up jamais réussi : une répétition propre (avant : 8 à 15). |
| Course | pas de footing écrit le lendemain d'une course d'épreuve ; texte de `duration_step` aligné sur la règle appliquée (plus longue course des quatre dernières semaines + 10 % ; après une course, 70 % de la plus longue puis + 10 % par semaine). |

À signaler : l'arbre de travail de 0.3.1 contient aussi des changements que le `CHANGELOG.md` de 0.3.1
ne cite pas (d'après le code, `skeleton.dart` et `prescribe.dart`) : deux séries assistées de tirage
chaque jour chez le débutant ; archer et typewriter d'abord au plateau dès 12 tractions (dose : environ
un tiers du maximum par côté, 3 à 8) ; plafond de volume de répétitions qui ne compte plus les variantes
plus faciles. Voir « Non déterminé ».

## 2. Prescriptions nouvelles : afficher, journaliser, minuter

### 2.1 Règles communes

**Afficher.** Toute note passe par `coachReasonText` (`lib/src/coach/texts.dart`). Les nouveaux codes ont
tous un texte. Aucun code brut ne doit s'afficher. « Bloc » : la note est dans les raisons du bloc ;
sinon elle est sur une ligne de la séance.

**Journaliser** (contrat de `kalis_core`, § 5 et § 12) :

- une ligne de journal (`SetRecord`) par série ; `ExercisePrescription.sets` = nombre de lignes
  attendues ;
- rôle de la ligne (`top`, `back_off`, `interval`, `wave`, `rung`, `warmup`, `test`, `attempt`) ;
- effort en flammes (1 à 10) ; « pas de note » = champ absent, jamais une valeur par défaut ;
- course et cardio : `seconds` (durée réelle) **et** `distanceMeters` quand ils sont connus. `kalis_adapt`
  convertit une distance seule à 2,6 m/s par défaut (`endurance.dart`) ;
- échauffement avec le rôle `warmup` : il est exclu de la course du jour, de la fatigue et des tests
  (`endurance.dart`, `replay.dart`) ;
- bilan santé : `pains` absent = question non posée ; liste vide = aucune douleur. Les deux ne se valent
  pas : une liste vide efface la douleur de la zone pour le moteur (`replay.dart`, `notePains`).

**Minuter.** Le repos écrit (`restSeconds`) reste ligne par ligne, comme en CI1. Les nouveautés sont les
groupes de conditionnement, les lignes en durée et les fractions de course (§ 2.4, 2.6).

### 2.2 Notes de coach nouvelles

| Code (version) | Où | Afficher | Journaliser | Minuter |
| --- | --- | --- | --- | --- |
| `clearance_first` (0.3.1) | bloc | avant la première séance, étape bloquante à confirmer (§ 5.1). `value` ≥ 5 : texte « Gêne déclarée à n/10… seuls les mouvements qui ne réveillent pas la douleur se font » ; `value` 0 : texte du questionnaire de santé | la réponse de l'utilisateur, dans l'application (aucun champ du contrat ne la porte) | — |
| `shoulder_history` (0.3.1) | ligne : développé au-dessus de la tête, épaule à antécédent | sous l'exercice, avec la règle de douleur : sans douleur (2/10 au plus), amplitude tolérée, feu vert du chirurgien ou du kiné | séries comme d'habitude ; douleur d'épaule dans `pains` si elle apparaît | — |
| `wod_pace` (0.3.0) | ligne d'une pièce de conditionnement ; `value` = effort sur 10 (8) | allure tenable, 2 à 3 en réserve, mise à l'échelle, charges de repère | une ligne par série écrite du membre (`sets`, § 2.4), flammes | chrono du groupe (§ 2.4) |
| `chair_squat` (0.3.0) | squat d'un senior en santé | consigne de la chaise | répétitions | repos écrit (60 à 75 s en santé) |
| `knee_shallow` (0.3.0) | chaise contre le mur, genou gêné ≥ 3/10 ; `value` = gêne déclarée | chaise haute 45-60°, gêne ≤ 3/10 pendant et le lendemain ; avis à 5/10 | secondes tenues ; douleur du genou si elle apparaît | minuteur de tenue |
| `balance_progress` (0.3.0) | marche sur les talons (équilibre) | progression et critère de passage | ce qui est écrit (secondes ou répétitions) | minuteur de tenue sur une jambe (20 à 30 s) |
| `hold_support` (0.3.0) | fente latérale d'un senior | une main sur un appui | répétitions | repos écrit |
| `warmup_run`, `warmup_gym`, `warmup_health` (0.3.0) | bloc, hors street, à la place de `general_warmup` ; `value` en minutes | en tête de séance | lignes d'échauffement avec le rôle `warmup` | minuteur des minutes d'échauffement (comptées dans la durée estimée, d'après le texte) |
| `short_run`, `short_health` (0.3.0) | bloc, hors street, à la place de `short_version` ; `value` en minutes | proposé un jour chargé | — | — |

Codes dont le sens ou le texte change : `interval_pace` (allure au kilomètre depuis 0.3.0), `event_day`
(`value` 0 hors street : la course du jour de l'échéance), règle `duration_step` (texte de 0.3.1).

### 2.3 Techniques de série

Le chemin coach n'écrit que quatre techniques (d'après le code) : `top_set_backoff`, `emom`,
`isometric_hold`, `skill_practice`. Toutes sont déjà rendues par CI1. Hors street, `top_set_backoff`
sert la force (squat, couché, soulevé de terre) : mêmes lignes « Tête, A1… », mêmes rôles au journal.
Le tempo (`tempo`) reste celui du panneau du coach.

### 2.4 Groupes de conditionnement (nouveau)

Une pièce de conditionnement est un **groupe** (`GroupSpec`, `DayPrescription.groups`) dont les membres
portent le même `groupId`. CI1 affichait les groupes comme du texte (LIVRAISON_CI1.md, partie 4) : ici il
faut un vrai minuteur.

| Format (`GroupFormat`) | Paramètres écrits | Membres | Minuter |
| --- | --- | --- | --- |
| `amrap` | `durationSeconds` | 1 ligne par membre | compte à rebours de la durée |
| `emom` | `intervalSeconds`, `durationSeconds` | 1 ligne par membre | bip à chaque intervalle jusqu'à la durée |
| `rounds_for_time` | `rounds`, `timeCapSeconds` | `rounds` lignes par membre | chrono montant, arrêt à la limite |
| `chipper` | `timeCapSeconds` | 1 ligne par membre | chrono montant, arrêt à la limite |
| `intervals` | `rounds`, `intervalSeconds`, `restBetweenRoundsSeconds` | `rounds` lignes par membre | effort puis récupération, `rounds` fois |
| `superset` | `rounds`, `restBetweenRoundsSeconds` (90) | — | repos entre les tours (note `superset`) |

Durées écrites par `kalis_plan` : 12 min (AMRAP), 10 min à 60 s (EMOM), 4 tours en 15 min (« pour le
temps »), 7 × 60 s (intervalles), 25 min (chipper), ramenées au créneau (4 min au moins) ; semaine
allégée : environ deux tiers (`general.dart`, `prescribe.dart`, `_wodGroup`). Repos des membres : 0.

**Journaliser.** Le résultat du groupe va dans `SessionRecord.groupResults` (`GroupResult` : `groupId`,
`completed`, `elapsedSeconds`, `rounds`, `extraReps` ; contrat de `kalis_core`, § 12). Aucun des deux
moteurs ne lit `groupResults` aujourd'hui (d'après le code). Ce que lit `kalis_adapt`, ce sont les
lignes des membres : effort en flammes (8 et plus = jour dur), puis `seconds`, sinon distance, sinon
répétitions × 3 s, pour la fatigue (`replay.dart`). Il faut donc aussi une ligne par membre, avec ses
répétitions (ou secondes, mètres, calories) et des flammes.

### 2.5 Tests et épreuves

| Cas | Afficher | Journaliser | Minuter |
| --- | --- | --- | --- |
| Test retiré sur une articulation douloureuse (0.3.1) | rien à ajouter : le test n'est pas écrit | — | — |
| Jour de test de tirage (0.3.1) | la séance ne contient plus le tirage vertical ni le muscle-up de travail | — | — |
| Premier muscle-up (0.3.1) | test « 1 répétition » (plage 1 à 1) | ligne de rôle `test` | repos écrit (240 s) |
| Test chronométré de course (`time_trial`, 0.2.0, étendu hors street en 0.3.0) | note `time_trial` (distance) ; `goal_pace` au test final | ligne de rôle `test` : `distanceMeters` **et** `seconds` = temps réalisé | chrono montant (contre-la-montre) |
| Jour de l'épreuve de course (0.3.0) | ligne de test sur la première course du jour, notes `time_trial`, `event_day` (0), `goal_pace` | idem | chrono montant |
| Lendemain d'une course d'épreuve (0.3.1) | pas de footing écrit ; marche libre | — | — |
| Semaine « de test » sans test (musculation, santé) | c'est un allègement | — | — |

**Résultat d'un contre-la-montre.** `kalis_adapt` ne le rend pas dans `AdaptReview.testResults` : il ne
traite que les exercices modélisés (charge-répétitions, répétitions max, maintien max ; d'après
`results.dart`). Or `kalis_plan` lit les `Benchmark` de nature `time_trial` du profil pour les allures
(`interval_pace`, ramenée au 10 km par la formule de Riegel) et pour la plus longue course connue (exercice
`ca-footing…`, `ca-sortie…` ou `ca-course…`, d'après `athlete.dart`). Pour que le bloc suivant recale les
allures, l'application doit écrire elle-même ce repère au profil : `kind: time_trial`, `source:
guided_test` (ou `competition` le jour de l'épreuve), `seconds`, `distanceMeters` (1 000 m au moins),
`date`.

Jour J : `planEventDay` (`kalis_adapt`, § 11.7) ne décrit qu'une compétition de force et une épreuve de
répétitions. Pour une course, aucun plan de jour J n'est fourni.

### 2.6 Course : séances et règles de durée

| Ligne | Écrit | Afficher | Journaliser | Minuter |
| --- | --- | --- | --- | --- |
| Footing, sortie longue | 1 ligne en `secondsLow`/`secondsHigh` (ou distance), réserve 5 ; `easy_pace` (minutes) ; `duration_step` en semaine de montée | durée et allure de conversation | `seconds`, `distanceMeters` si connue, flammes | compte à rebours de la durée |
| Fractions en mètres | n lignes de `distanceMeters`, réserve 2, `restMode: jog`, repos 90 s ; `interval_pace` | allure au kilomètre ; récupération en trottinant | une ligne par fraction : `distanceMeters`, `seconds` de la fraction, flammes | chrono par fraction, puis repos trottiné 90 s |
| 30-30 | 2 × n lignes de 30 s, repos 30 s | — | une ligne par effort | 30 s / 30 s |
| Séance de qualité en durée (ni fractions en mètres, ni 30-30) | 1 ligne de 20 min, réserve 2 | — | `seconds`, flammes | compte à rebours |
| Allure de l'objectif | 3 à 6 × 1 000 m, `restMode: jog`, repos 90 s ; `goal_pace` | allure au kilomètre | une ligne par 1 000 m | chrono par fraction, repos trottiné |

Règles de durée : sortie longue ≤ 110 % de la plus longue course des quatre semaines d'avant ; au départ,
jamais au-delà de la plus longue course connue (+10 % dès l'intermédiaire) ; 8 min d'échauffement et 12 min
de renforcement retirées du créneau (`prescribe.dart`). `kalis_plan` compte sur les semaines **écrites**
du bloc précédent. La borne sur ce qui a été **couru** est celle de `kalis_adapt` (30 jours + 10 %) : elle
ne marche que si chaque course est journalisée avec sa durée (voir le document de `kalis_adapt`).

### 2.7 Échauffements

- Hors street, `warmup_run`, `warmup_gym` ou `warmup_health` remplacent `general_warmup` (minutes dans
  `value`). Le texte dit que ces minutes comptent dans la durée estimée.
- Le contenu des lignes d'échauffement (montées 40-60-75-85 %, préparation) ne change pas.
- Journal : rôle `warmup`, toujours (sinon un trot d'échauffement compte comme course pour `kalis_adapt`).

### 2.8 Autres disciplines par le chemin coach

- **Qui.** Décidé par `coachEligible`, sans condition codée dans l'application (règle de CI1). Depuis
  0.3.0, un nouveau programme de musculation, course, CrossFit, mobilité ou forme générale est écrit par
  le coach. MA SAISON (`planSeason`) s'applique aussi à ces profils.
- **Programme 0.1 en cours** de ces disciplines : `nextBlock` passe au chemin coach si le profil est
  éligible et que l'ancienneté est renseignée (ou que le bloc porte déjà une intention ; `engine.dart`).
  Le choix « Passer au moteur calibré / Garder le moteur actuel » de CI1 s'applique donc aussi à eux.
- **Afficher** : panneau du coach et notes comme pour le street ; les groupes de conditionnement comme
  un groupe (§ 2.4) ; la note `superset` pour les enchaînements.
- **Journaliser** : règles du § 2.1 ; pour la course et le conditionnement, durée, distance et flammes à
  chaque ligne.
- **Minuter** : groupes (§ 2.4), lignes de course (§ 2.6), repos de 60 à 75 s en santé.

## 3. Codes

### 3.1 Codes de raison (`kalis_core` 0.4.3)

138 codes au registre (`reason_codes.g.dart`). Nouveaux depuis 0.4.2, tous émis par `kalis_adapt` 0.3.0 :

| Code | Paramètres (type) | Texte proposé (`RAISONS_0_4.md`) |
| --- | --- | --- |
| `adapt.run_capped` | `percent` (entier) | Sortie raccourcie : pas plus de {percent} % au-dessus de ta plus longue sortie du mois. |
| `adapt.easy_instead` | `cause` (texte) | Aujourd'hui, endurance facile à la place de la séance de qualité ({cause}). |
| `adapt.endurance_shortened` | `cause` (texte), `percent` (entier) | On raccourcit : {percent} % de ce qui était prévu ({cause}). |
| `adapt.wod_scaled` | `cause` (texte), `percent` (entier) | WOD mis à l'échelle : {percent} % de ce qui était prévu ({cause}). |
| `adapt.cross_fatigue` | `cause` (texte) | Un peu plus de marge sur les jambes : ta course d'hier était dure. |

Causes : `health`, `health_strong`, `hard_run`, `leg_pain`, `resume_7`, `resume_14`, `hard_streak`
(sens et libellés : document de `kalis_adapt`, § 3.2). `kalis_plan` 0.3.x n'émet aucun code de raison nouveau.

### 3.2 Codes de note de coach (`CoachNotes.all`)

108 codes (0.2.3 : 96). Liste exacte de `CoachNotes.all` (`lib/src/coach/prescribe.dart`), classée par
version d'apparition (comparaison du code aux commits de 0.2.0 à 0.3.0).

| Apparu en | Codes |
| --- | --- |
| **0.3.1 (nouveau)** | `clearance_first`, `shoulder_history` |
| **0.3.0 (nouveau)** | `wod_pace`, `chair_squat`, `knee_shallow`, `balance_progress`, `hold_support`, `warmup_run`, `warmup_gym`, `warmup_health`, `short_run`, `short_health` |
| 0.2.3 (déjà intégré) | `entry_check`, `reps_rehearsal`, `step_criterion`, `pain_reprise`, `wrist_spare`, `safety_pins`, `checkpoint_body`, `checkpoint_hold`, `checkpoint_load`, `checkpoint_ladder`, `push_height` |
| 0.2.2 | `plateau`, `event_zone`, `ramp_muscle_up`, `pain_stop`, `pain_step`, `pain_return`, `pain_return_item`, `slow_tempo` |
| 0.2.1 | `pain_trend`, `weight_class`, `event_format` |
| 0.2.0 | `entry_set`, `slow_negative_push`, `role_forearm`, `role_runner`, `rest_pause`, `ambitious`, `max_set_plan`, `hold_ramp`, `tracking`, `small_load`, `push_ladder`, `dress_rehearsal`, `primer`, `recalibrate`, `step_gate`, `max_attempt`, `hold_calibrate`, `estimated_load`, `reconciled`, `tendon_load`, `pull_return`, `easy_before_test`, `already_applied`, `attempts_goal`, `activation`, `reentry_test`, `bodyweight_floor`, `overload`, `strict_attempt`, `pain_general`, `red_flags`, `short_version`, `band_choice`, `cue`, `interval_pace`, `goal_pace`, `time_trial`, `skill_horizon`, `walking`, `push_maintenance`, `negative_gate`, `rest_before_event`, `bad_day`, `missed`, `checkpoint`, `test_rest`, `ramp_bodyweight`, `load_adjust`, `reps_adjust`, `test_use`, `event_rehearsal`, `role_prehab`, `role_row`, `role_posterior`, `role_legs`, `role_core`, `role_elbow`, `ramp_warmup`, `top_set_backoff`, `speed_work`, `attempts_plan`, `opener`, `maintenance`, `every_minute`, `quality_first`, `submaximal_hold`, `slow_negative`, `event_day`, `recovery`, `calibrate`, `superset`, `easy_pace`, `general_warmup`, `tolerance_volume` |

`push_maintenance` et `reconciled` ont un texte mais ne sont émis nulle part (`NOTES_COACH.md`).
`NOTES_COACH.md` (titre « 0.2.2 ») ne documente pas 12 codes : les 11 de 0.2.3 et `ramp_muscle_up`. Ils
ont un texte dans `texts.dart` et l'application les rend déjà (CI1d).

**Bouclier.** CI1d met le bouclier sur les notes de douleur (`pain_reprise`, `wrist_spare`…). Les notes
nouvelles liées à une gêne ou à un avis médical sont `clearance_first`, `shoulder_history` et
`knee_shallow`. Leur donner le bouclier est un choix de l'application (aucun paquet ne le dit).

### 3.3 Règles de progression (`CoachRules`)

Inchangées : `assistance_step`, `double_progression`, `load_step`, `rep_step`, `hold_step`,
`density_step`, `duration_step`. Seul le texte de `duration_step` change en 0.3.1.

## 4. Migration des programmes en cours

| Cas | Ce qui se passe |
| --- | --- |
| JSON des programmes et du journal | `kalis_core` 0.4.3 relit et réécrit à l'identique un JSON de 0.4.2 ; 0.4.x relit un JSON de 0.3.0 (§ 16). Un programme écrit par `kalis_plan` 0.1 ou 0.2 se relit donc tel quel. Journal : schéma 1 inchangé. |
| Bloc écrit en 0.2.x, en cours | relu et servi tel quel. Ses notes sont celles de 0.2.x : pas de `clearance_first`, pas de `shoulder_history`, pas de retrait des tests sur articulation douloureuse. Les règles de séance de `kalis_adapt` 0.3.1, elles, s'appliquent dès la mise à jour (le bloc est servi en mode coach). |
| Réécriture | au bloc suivant (`nextBlock`), ou plus tôt par une restructuration (`restructure`) : les notes et règles de 0.3.x s'appliquent au bloc réécrit. `kalis_plan` n'expose pas de fonction publique pour recalculer les notes d'un bloc déjà écrit (`blockReasonsOf` n'est pas exportée). |
| Bloc 0.1 en cours (chemin d'avant) | fini tel quel ; à « Préparer le bloc suivant », chemin coach si le profil est éligible et que l'ancienneté est renseignée (§ 2.8). La règle CI1.4 (débutant présenté « moins de 6 mois ») reste en place tant que le lot CI ne la retire pas (CI1d). |
| Programme importé de 40 semaines | voir ci-dessous. |

**Programme importé du propriétaire (DECISIONS C11).** Toutes les fonctionnalités doivent s'y appliquer.
`kalis_plan` n'a aucune branche « programme importé » (recherche dans `lib/`). Il choisit son chemin ainsi
(`CONTRAT.md`, § 12.1) : `review`, `createPass2`, `restructure` prennent le chemin coach seulement si le
profil est éligible **et** que le programme porte une intention (`isCoachPlan`). Le bloc importé n'a pas
d'intention : tant qu'il n'est pas converti, il passe par le chemin 0.1. Donc, tant qu'il n'est pas
converti en blocs au contrat 0.4.0 :

- aucune note de coach (ni `clearance_first`, ni `shoulder_history`, ni aucune autre) ;
- pas de retrait de test sur articulation douloureuse, pas de règle du jour de test de tirage, pas de
  premier muscle-up à une répétition ;
- pas de saison propre au programme : `planSeason` se calcule sur le profil (plan sans phase si le
  profil n'est pas éligible), pas sur les semaines du bloc importé.

Côté `kalis_adapt` (son § 13.3) : pas de mode coach tant que le bloc ne porte pas ces champs ; les
restructurations demandent `KalisAdapt(restructureImported: true)` tant que le bloc fait plus de six
semaines. Après conversion, si le profil du propriétaire est éligible, `review` et `restructure` de
`kalis_plan` prennent le chemin coach. Effet de ce chemin sur un programme converti : non mesuré ici.

## 5. Points imposés par le lot CY

### 5.1 Note de bloc `clearance_first`

Elle doit être montrée **avant la première séance**, comme une étape à confirmer. Deux réponses :
« J'ai eu l'avis d'un médecin ou d'un kiné » et « Pas encore ». Tant que ce n'est pas confirmé, la séance
montre seulement les mouvements qui ne réveillent pas la douleur. Garder simple : afficher un
**avertissement bloquant à confirmer**.

- Texte : `coachReasonText` de la note (deux formes selon `value`, § 2.2).
- La note est recalculée à chaque bloc écrit tant que la condition tient (questionnaire « prudent » ou
  gêne déclarée ≥ 5/10 ; `blockReasonsOf`, d'après le code). Faut-il redemander à chaque bloc ? Les
  paquets ne le disent pas.

### 5.2 Pompe remplacée pour le poignet

Quand `kalis_adapt` remplace une pompe par `sw-pompe-inclinee` avec la raison `adapt.pain_reported`
zone poignet (`zone: wrist_hand`), l'application affiche **« mains serrées sur la barre basse, poignets
droits »**. Détail et cas voisins : document de `kalis_adapt`, § 2.5 et § 6.

## 6. Non déterminé

- Changements de l'arbre 0.3.1 absents du `CHANGELOG.md` (§ 1.3) : font-ils partie de la version à
  intégrer ? À confirmer par le lot CY.
- `kalis_plan` 0.3.x ne documente pas ses règles hors street dans `CONTRAT.md` (titre « 0.2.1 », § 12 à
  12.14). Ce document s'appuie sur le `CHANGELOG.md`, `NOTES_COACH.md` et le code.
- Résultat d'un contre-la-montre : aucun paquet ne le reporte au profil (§ 2.5).
- Jour J d'une course : aucun plan fourni (§ 2.5).
- Fréquence de la confirmation de `clearance_first` d'un bloc à l'autre (§ 5.1).
- Effet du chemin coach de `kalis_plan` sur le programme importé une fois converti (§ 4).
