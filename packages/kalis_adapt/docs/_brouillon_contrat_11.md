## 11. Mode coach (0.2.0) : blocs au contrat 0.4.0

Un bloc « porte le contrat 0.4.0 » dès qu'il écrit une intention de bloc ou de semaine, une échelle de
figure, un groupe, une technique, une intensité, une règle d'autorégulation, un test décrit ou une étape de
figure (`blockCoached`). Le moteur le sert alors en **mode coach** : il exécute ce que le programme écrit
et n'en sort que pour protéger l'athlète ou quand le journal montre que le chiffre écrit ne lui va pas. Un
bloc sans aucun de ces champs (programmes de `kalis_plan` 0.1, programme importé du propriétaire) est servi
comme en 0.1.0, à l'octet près (§ 7) ; `KalisAdapt(legacy: true)` sert aussi un bloc 0.4.0 comme en 0.1.0
(comparaisons de `docs/CAMPAGNE_STREET.md`). `KalisAdapt` implémente aussi `EventDayAdvisor`
(`planEventDay`, § 11.7).

Les identifiants « R2-P3 », « R4-F9 »… renvoient au référentiel de `kalis_bench`
(`docs/REFERENTIEL.md`), qui cite ses sources. « Choix raisonné » : aucun chiffre publié, la valeur est un
choix de ce lot, à valider (§ 9).

### 11.1 Ce que la semaine permet

| Intention de la semaine | Ce que le moteur fait |
| --- | --- |
| accumulation, intensification, réalisation, maintien (semaines de charge) | la réserve visée pilote la charge dans un couloir autour de la part écrite (§ 11.2) ; séries au ressenti et série repère possibles (§ 11.4) ; le volume peut être proposé à la hausse par la revue |
| introduction, décharge, affûtage, test, compétition, transition (semaines servies telles quelles) | la séance du bloc est servie telle qu'elle est écrite : aucune hausse au-delà de la charge écrite, aucune série ajoutée, aucune série repère, aucune technique qui mène près de l'échec ; raison `adapt.phase_respected` (et `adapt.taper_no_volume` en affûtage et en compétition : R3-P12, R3-P13) |
| échéance principale à 14 jours ou moins (`coachEventNearDays`) | décisions prudentes : pas de pilotage à la hausse, pas de série au ressenti ; `adapt.event_near` |

Le jour même, le moteur ne sert **jamais plus de séries** que le bloc n'en écrit (invariant C2, § 7) ; le
volume ne monte que par une proposition de la revue, jamais en affûtage ni quand le profil déclare une
récupération réduite (sommeil habituel sous 6 h, stress élevé, métier physique lourd : `adapt.recovery_profile`,
R5-P14, R5-P15, R5-P18).

### 11.2 Exercice chargé écrit en part du 1RM

La charge écrite est `part × 1RM estimé` (le 1RM de l'exercice, ou celui de l'exercice de référence de
l'intensité, corrigé de l'écart appris entre les deux), sur la grille du matériel, charge totale (R2-P4).

- **Semaine de charge, niveau intermédiaire et plus, hors jour léger** : la charge est la plus forte du
  couloir `[part − 5 % ; part + 7,5 %]` du 1RM (`coachCorridorDown`, `coachCorridorUp` : ±2,5 % par point
  d'écart, R2-P3, bornés à deux points vers le bas et trois vers le haut — choix raisonné) qui laisse en
  moyenne la réserve visée sur les séries de tête et, avec la marge de prudence, la réserve visée moins 1,5
  sur la plus dure (`coachWorstSetSlack`). Quand une séance servie au haut du couloir est restée au moins
  2 répétitions plus facile que visé (`coachEasyGapRir`), le haut du couloir monte de 2,5 % (`coachCorridorWiden`),
  jusqu'à +15 % (`coachCorridorUpMax`) ; une séance plus dure que visé le redescend d'un cran.
- **Débutant, jour léger, semaine servie telle quelle, échéance proche, zone douloureuse, bilan bas** : la
  charge écrite, allégée seulement si elle ne laisse pas la réserve visée moins un point (plafond d'effort,
  `adapt.rir_cap`).
- **Garde-fous** (dans cet ordre) : à schéma égal (même emplacement, mêmes répétitions), la charge totale
  ne monte pas de plus de 10 % (débutant) ou 5 % (autres niveaux) d'une séance à la suivante
  (`coachRise` ; moitié sur une zone à antécédent ou à gêne déclarée, `coachHistoryRiseFactor`) — un cran
  de grille reste toujours permis (limite 12 de 0.1 : un lest léger ne double plus) ; au premier passage à
  un schéma, jamais plus que la plus grande de la charge écrite par le bloc et de +10 % de la plus lourde
  barre réussie des six dernières semaines (invariant C1) ; aucune hausse par rapport à la dernière séance
  de l'exercice après un échec non prévu ni sur une zone douloureuse (I2, I3) ; `adapt.load_held` dit la
  cause.
- **Effort affiché** : celui du bloc ; quand la charge servie est retenue sous ce que la réserve visée
  demanderait (couloir, plafond de hausse, semaine servie telle quelle), les flammes affichées sont celles
  de l'effort attendu, jamais plus dures que la cible du bloc.

Un exercice chargé sans part du 1RM (plage et réserve seulement), ou sans suivi encore, suit la règle
générale de 0.1 (§ 4.1), bornée par la plage du bloc en semaine servie telle quelle.

### 11.3 Techniques

Chaque technique est servie avec `sets` = lignes de journal (contrat de `kalis_core`, § 12), et relue dans
le journal par `readLine` :

| Technique | Séance servie | Lecture du journal |
| --- | --- | --- |
| `top_set_backoff` | série de tête pilotée (§ 11.2) ; séries allégées à la baisse écrite, calculées pendant la séance sur la série de tête **réalisée** (`adapt.backoff_from_top_set`), 2,5 % de moins par point de réserve manquant (5 % au plus) | une ligne par série, rôles `top` et `back_off` |
| `cluster` | charge qui tient la réserve visée sur les mini-séries, repos courts comptés | le total de la ligne se compare à la cible ; chaque partie est une borne basse de la capacité |
| `rest_pause`, `myo_reps`, `drop_set` | première partie comme une série classique ; `miniSetsLeft` conseillé | seule la première partie mesure la capacité |
| `accentuated_eccentric` | charge de la descente : part écrite, au plus 110 % du 1RM (R2-P17) ; jamais à 10 jours ou moins d'une échéance (`coachEccentricEventDays`) ni sur une zone à antécédent | la ligne ne mesure pas la capacité du mouvement complet |
| `wave`, `pyramid`, `ladder` | un palier par ligne (rôles `wave`, `rung`) ; la charge ne monte d'une vague à l'autre qu'un jour sans verrou | ligne par ligne |
| `emom`, `density`, `for_time` | intervalles ou bloc au temps ; arrêt quand les répétitions chutent (`stop_on_rep_drop`) | parties : bornes basses |
| `isometric_hold`, `skill_practice` | durée écrite ou part du maintien maximal mesuré (§ 11.5) ; arrêt quand la propreté passe sous le plancher (`stop_on_quality_drop`) | une ligne sous le plancher de propreté compte comme un échec |
| `amrap` | dernière série ouverte | série ouverte |

Une ligne du journal sans technique déclarée ni parties est lue comme une série classique.

**Prérequis** (R2-P22). Niveau d'accès : intermédiaire pour la série de tête, la dégressive, la série au
maximum, la pyramide, l'échelle, la densité et le contre-la-montre ; avancé pour les clusters, le rest-pause,
les myo-reps, la descente accentuée, le contraste et les vagues. Une technique au-dessus du niveau n'est
jamais servie : des séries classiques au même travail approché la remplacent (`standardEquivalent`). Une
technique qui mène près de l'échec ou surcharge n'est servie ni sur une zone douloureuse, ni un jour de
bilan nettement bas, ni en semaine servie telle quelle. Raison : `plan.technique_withheld` (technique,
cause).

**Règles d'autorégulation portées par la prescription** : `stop_at_rir` (une ligne finie au moins un point
sous le plancher allège la suivante de 2,5 à 5 % ; deux de suite arrêtent l'exercice, après `minSets`
lignes), `stop_on_rep_drop`, `stop_on_quality_drop` (avec l'étape plus facile conseillée,
`stepExerciseId`, quand les deux premières lignes sont sales), `backoff_from_top_set`, `hold_from_best`,
`last_set_amrap`. Une ligne qui a dû être allégée le reste jusqu'à la fin de l'exercice.

### 11.4 Notes d'effort : ce qu'elles disent vraiment

- **Loin de l'échec, une note est une borne.** À partir de 3 répétitions en réserve dites
  (`coachCensorRir`), la note se lit « au moins tant en réserve », sans gonflement par le biais : la
  prédiction des répétitions restantes se dégrade loin de l'échec et plafonne (Zourdos et al. 2021 ;
  Halperin et al. 2022). Une note au plafond n'est jamais lue comme « trop dur » ; des répétitions qui
  manquent à la cible, si.
- **Série repère** (`adapt.benchmark_set`). Quand aucune série n'a mesuré la capacité d'un exercice depuis
  14 jours (`coachProbeDays`) — toutes ses notes sont au plafond —, la dernière série classique devient
  ouverte, à 1,5 répétition en réserve (2 pour un débutant), comme dans l'APRE (Mann et al. 2010). Jamais
  en semaine servie telle quelle, près d'une échéance, un jour léger, un jour de bilan bas, sur une zone
  douloureuse ni après un échec.
- **Séries au ressenti.** Une séance notée au plafond alors que la cible était plus dure ouvre, la fois
  suivante, des séries au ressenti (plage étendue, § 4.3) : elles disent ce que la charge ou la plage vaut.
- **Biais de note appris** (limite 4 de 0.1). Un test mené près de l'échec (série de test ou de
  répétitions maximales, pas une tentative) compare ce que les séries notées laissaient prévoir à ce que
  l'athlète montre ; un quart de l'écart, rapporté à trois répétitions, corrige le biais de la personne,
  de 0,1 au plus par test, entre 0 et 0,6 (`biasLearn…`, choix raisonnés).
- **Forme de la courbe.** En mode coach, toute série fraîche notée à moins de 3 en réserve renseigne `k`
  (§ 3.1) : les séries de tête lourdes et les séries plus longues se recoupent.

### 11.5 Exercices sans charge, maintiens, figures

- **Répétitions au poids du corps.** Part d'un test (`percent_benchmark`) : la cible suit le maximum
  estimé, dans les deux sens. Sinon les répétitions écrites sont servies tant qu'il reste, avec la marge
  de prudence, la réserve visée moins un point (2 au plus, `coachDirectGuardRir`) ; en semaine de charge,
  la plage s'étend comme en 0.1 quand elle est devenue trop facile. Un exercice assisté à l'élastique garde
  la plage du bloc : sa progression passe par l'assistance, que le moteur ne règle pas.
- **Maintiens.** La durée écrite (ou la part du maintien maximal mesuré) est servie, au plus 80 % du
  maximum du jour (`coachHoldMaxShare`, R4-F9 : les maintiens se travaillent sous le maximum, la propreté
  d'abord). Bras tendus et appuis : la durée ne monte pas de plus de 20 % (débutant), 15 % (intermédiaire)
  ou 10 % (avancé, élite) d'une séance à la suivante du même emplacement (`coachHoldRise`, R5-P22 ;
  `adapt.tendon_load`).
- **Figures** (`SkillLadder`). Le tableau des figures (`SkillBoard`) suit l'étape en cours : critère de
  passage (maintien ou répétitions, propreté, nombre de séances de suite, semaines minimales à l'étape)
  lu dans le journal. Une étape dont le passage n'est pas acquis n'est pas servie : l'étape en cours la
  remplace (`adapt.skill_hold`). Critère rempli : proposition de passage (`ProposalKind.load`, détail
  `skillStepUp`, `adapt.skill_step_up`). Mauvais jour (deux premières lignes sous le plancher de
  propreté) : l'étape plus facile est conseillée (`adapt.skill_step_down`). États rendus par la revue
  (`skillStates`, `summary.skills`).

### 11.6 Tests

- **Tentatives** (`one_rm`, `attempt_simulation`). Ouverture : la plus lourde barre réussie à 95 % de
  chances au moins (`attemptOpenerProbability`), au plus 93 % du maximum estimé du jour
  (`attemptOpenerShare`) et, quand une barre proche a été réussie dans les six dernières semaines, au plus
  cette barre (R3-P14 : le dernier lourd fixe la première barre). Deuxième : 80 % de chances. Troisième :
  50 % (70 % pour assurer un total, 35 % pour un record, où la barre visée du profil est tentée si elle
  garde 35 %). Jamais décroissantes ; après une barre manquée, la même barre ; saut minimal de la
  compétition respecté ; bilan bas, douleur ou échec récent : maximum du jour réduit de 2 % par cause
  (`adapt.attempt_conservative`). La probabilité est celle d'une loi normale sur le `ln` de la charge,
  d'écart-type celui du maximum du jour (estimation et effet de jour, § 3). Les barres suivantes sont
  recalculées après chaque tentative (`adapt.attempt_next`). Une tentative réussie se lit « au moins une
  fois » ; sa note n'est pas lue comme une réserve mesurée.
- **xRM, série d'estimation, répétitions ou maintien maximal** : charge prévue pour les répétitions dites
  à la réserve du test ; séries ouvertes pour les maxima.
- **Pas de test un jour de bilan nettement bas** (hors jour d'échéance) : le test est retiré de la séance.
- **Résultats.** La revue rend `testResults` (`Benchmark` de source `guided_test`, ou `competition` le
  jour d'une échéance) que l'application reporte au profil, `summary.benchmarks` (tests et meilleures
  séries d'entraînement de moins de 3 en réserve), les estimations avec leur erreur standard
  (`summary.estimates`), la tolérance au volume apprise après trois semaines (`summary.volumeTolerance`)
  et les raisons `adapt.test_result`.

### 11.7 Jour d'échéance (`planEventDay`)

`EventDayPlan` : pour une compétition de force, par mouvement, le maximum estimé et son erreur standard,
l'échauffement (paliers à 40, 55, 70, 80 et 87 % de l'ouverture, `warmupSteps`) et les tentatives (règle
du § 11.6, objectif `secure_total`, `max_total` ou `record`, tentatives déjà faites prises en compte) ;
pour une épreuve de répétitions, l'objectif (`adapt.pacing`) et le rythme : première série à 65 % du
maximum (`pacingFirstShare`), puis des séries de la moitié de la précédente, 15 s de repos (choix
raisonnés, pratique de terrain du format).

### 11.8 Douleur, bilan du jour, récupération

- Douleur (R5-P23, R4-F11 ; limite 11 de 0.1) : de 0 à 3, rien ne change ; au-dessus de 3, aucune hausse
  sur la zone (I3) ; à 5 sur une contrainte moyenne, l'exercice est gardé avec 60 % de ses séries et un
  point de réserve de plus (`coachPainRegress`, `coachPainRegressSets`) ; à 6 et plus, il est retiré
  (`coachPainStop`).
- Bilan nettement bas : une série de moins par exercice, charges réduites (§ 4.5), aucune série à moins
  de 3 répétitions en réserve (`coachLowDayRir`), pas de test, pas de technique qui mène près de l'échec.
- Récupération déclarée réduite (profil v3) : dite dans la séance, aucune hausse de volume proposée.

### 11.9 Paramètres du mode coach

| Paramètre | Valeur | Source |
| --- | --- | --- |
| `coachCorridorDown`, `coachCorridorUp` | 5 % ; 7,5 % | R2-P3 (±2,5 % par point d'écart) ; bornes : choix raisonné |
| `coachCorridorWiden`, `coachCorridorUpMax` | 2,5 % ; 15 % | choix raisonné |
| `coachRise` (par niveau), `coachHistoryRiseFactor` | 10 %, 5 %, 5 %, 5 % ; 0,5 | R5-P22 (garde-fous de progression) ; choix raisonné |
| `coachWorstSetSlack`, `coachBreachRir`, `coachEasyGapRir` | 1,5 ; 1 ; 2 répétitions | R2-P3 (écart d'un point) ; choix raisonné |
| `coachBreachCut`, `coachBreachCutMax` | 2,5 % ; 5 % | R2-P3 |
| `coachCensorRir`, `coachCurveRir` | 3 ; 3 répétitions | Zourdos et al. 2021, Halperin et al. 2022 |
| `coachProbeDays` | 14 jours | choix raisonné (APRE : Mann et al. 2010) |
| `coachHoldMaxShare`, `coachHoldRise` | 80 % ; 20 %, 15 %, 10 %, 10 % | R4-F9, R5-P22 ; choix raisonné |
| `coachDirectGuardRir`, `coachLowDayRir` | 2 ; 3 répétitions | choix raisonné ; règle du programme |
| `coachEventNearDays`, `coachEccentricEventDays` | 14 ; 10 jours | R3-P14 ; R2-P17 |
| `coachPainRegress`, `coachPainStop`, `coachPainRegressSets` | 5 ; 6 ; 0,6 | R5-P23, R4-F11 (seuils raisonnés) |
| `attemptOpenerShare`, probabilités des tentatives | 93 % ; 95 %, 80 %, 50 % (70 %, 35 %) | pratique de terrain de la force athlétique (ouverture qu'on réussit « un mauvais jour ») ; choix raisonné |
| `attemptLowHealthShare`, `attemptRecentDays` | 2 % ; 42 jours | choix raisonné |
| `skillSessions`, `skillDownSessions`, `skillTenureWeeks`, `skillPainMax` | 3 ; 2 ; 2, 8, 18, 30 semaines ; 3 | R4-F9 (délais par levier) ; contrat des échelles |
| `pacingFirstShare`, `pacingNextShare`, `pacingRestSeconds` | 65 % ; 50 % ; 15 s | choix raisonné |
| `biasLearnRate`, `biasLearnRir`, `biasLearnMaxStep`, `biasMin`, `biasMax` | 0,25 ; 3 ; 0,1 ; 0 ; 0,6 | choix raisonné (Halperin et al. 2022 pour l'ordre de grandeur du biais) |
| `toleranceMinWeeks`, `trainingSetMaxReps`, `trainingSetMaxRir` | 3 ; 6 ; 3 | choix raisonné |
