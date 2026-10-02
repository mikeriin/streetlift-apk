# Profil d'athlète v3 — revue des facteurs

Lot CQ (pipeline « Calibrage des programmes »), `kalis_core` 0.4.0, 02/10/2026. Décision du propriétaire (C1.6) :
« il faut demander ce qui est vraiment pertinent et qui a un impact réel sur la manière dont le corps supporte les
entraînements ». Ce document passe en revue chaque facteur candidat et rend un verdict : **posée** (à qui, sous quelle
forme), **déduite** (d'une autre réponse ou des séances) ou **écartée** (effet non démontré, ou non actionnable sans
conseil médical ou nutritionnel). Le parcours qui en découle est dans [`PARCOURS_V3.md`](PARCOURS_V3.md).

## 0. Méthode et limites

- **Relectures.** Ce document et le parcours ont été relus par trois relecteurs indépendants (contrat et code ;
  « débutant pressé » ; « coach d'élite »). Chaque remarque est traitée — changée ou expliquée — dans
  [`RELECTURES_CQ.md`](RELECTURES_CQ.md) ; les corrections de fond sont reprises ici.
- **Recherche documentaire du 02/10/2026**, par six recherches indépendantes (sommeil et stress ; âge, sexe,
  ancienneté ; énergie et autres sports ; blessures ; tests ; compétition et techniques). Chaque référence a été
  recherchée sur le site de la revue, un dépôt universitaire, Crossref ou PubMed.
- **Statut de chaque référence** (§ 7) : **V** = notice consultée (titre, auteurs, année, revue, DOI concordants) et
  résultat cité lu dans le résumé ; **P** = notice confirmée, mais le chiffre cité vient d'une source secondaire ou
  n'a pas été relu ; les références qui n'ont pas pu être vérifiées **ne sont pas citées**.
- **Limite à connaître** : PubMed et plusieurs éditeurs étaient inaccessibles depuis la session ; les pages ont été
  lues à travers un outil qui restitue le contenu. **Aucun texte intégral n'a été relu ligne à ligne.** Les chiffres
  sont ceux des résumés ; ils sont à recontrôler avant toute citation publique. Aucun contenu n'a été relu par un
  professionnel de santé ou un entraîneur diplômé (registre de validation, `CONTRAT.md` § 10).
- **Preuve et choix raisonné** : quand la littérature démontre un effet mais ne donne aucune grandeur d'ajustement
  (cas le plus fréquent), le facteur peut être posé, mais ce que le moteur en fait est dit « choix raisonné » — et
  aucun chiffre n'est inventé ici : les règles chiffrées relèvent du référentiel du banc d'essai (lot CR) et des
  moteurs calibrés (lots CP1, CA1).

## 1. Règles de décision

1. Une question n'est **posée** que si (a) un effet sur la tolérance à l'entraînement, la réponse ou le risque est
   démontré ou, à défaut, solidement admis par l'usage et sans coût pour l'utilisateur, **et** (b) la réponse change
   une décision du programme (volume, intensité, fréquence, rythme de progression, choix d'exercices, décharges,
   affûtage, placement des séances), **et** (c) elle ne peut pas être déduite d'une autre réponse ou du journal.
2. Elle n'est posée **qu'à ceux pour qui elle compte** (condition d'apparition) ; elle est toujours passable, sauf les
   champs obligatoires du schéma 2.
3. **Valeur habituelle** (profil) et **valeur du jour** (bilan de séance, D5.8-D5.9) ne font jamais doublon : le
   profil porte l'habitude (sommeil habituel, stress des dernières semaines, métier) ; le bilan de séance porte la
   nuit dernière, le stress et les douleurs du jour. L'habitude déclarée est une **valeur de départ** : dès que les
   bilans de séance existent, ce sont eux qui renseignent le moteur dynamique ; la réponse du profil ne sert alors
   plus qu'au premier bloc et aux semaines sans bilan.
4. **Rien de nouveau n'est demandé à un débutant à la création.** Les questions de récupération (sommeil, stress,
   charge hors programme) lui sont proposées après la première semaine ; les autres questions du schéma 3 ne le
   concernent pas. Son programme de départ est prudent par construction (D4.7) : ces réponses n'y changeraient rien
   la première semaine.
5. **Santé** : la règle L13 tient. Aucune réponse du questionnaire santé n'est copiée dans le profil. Les antécédents
   utiles à la programmation sont des **contraintes d'entraînement** (zone, côté, gêne perçue, depuis quand,
   mouvements qui la réveillent), jamais un diagnostic. Aucun score de risque de blessure n'est calculé : les tests
   de dépistage ne prédisent pas la blessure d'un individu (`bahr2016`).
6. Une réponse absente reste absente (D5.8) : aucune valeur par défaut n'est écrite dans le profil.

## 2. Synthèse des verdicts

| Facteur (clé) | Verdict | À qui | Forme | Preuve | Champ |
| --- | --- | --- | --- | --- | --- |
| Ancienneté dans la discipline (`anciennete`) | **posée** | niveau ≥ intermédiaire (un débutant l'a déjà dit par son niveau) | 4 tranches | forte | `trainingAge` (+ `experience`, schéma 2) |
| Interruption récente (`interruption`) | **posée** une fois, puis **déduite** du journal | ancienneté ≥ 6 mois | 7 choix | modérée | `trainingGap` |
| Charge d'entraînement actuelle (`charge_actuelle`) | **posée**, facultative, puis **déduite** du journal | niveau ≥ avancé | éditeur court (3 à 4 lignes) + 1 choix | usage d'entraîneur | `recentTraining`, `currentPhase` |
| Tests et records (`tests_records`) | **posée** ; sinon **mesurée** par test guidé | niveau ≥ intermédiaire | éditeur de liste | forte (mesure) | `benchmarks` |
| Figures : étape actuelle (`figures`) | **posée** | calisthénie, streetlifting ou CrossFit au programme | éditeur de liste | indirecte (tendon) | `skills` (dont `atStepSince`) |
| Orientation en musculation (`orientation`) | **posée** | musculation au programme | 3 choix | modérée (dose-réponse) | `emphasis` |
| Compétition et échéances (`competition`) | **posée** | niveau ≥ intermédiaire, objectif de performance, ou cardio au programme | éditeur de liste | forte (affûtage, périodisation) | `events` |
| Spécialisation (`specialisation`) | **posée**, facultative | niveau ≥ avancé ; dès l'intermédiaire en musculation | 1 cible | usage | `specialization` |
| Points faibles (`points_faibles`) | **posée**, facultative | niveau ≥ avancé, discipline de force | éditeur de liste | faible | `weakPoints` |
| Volume de course actuel (`base_endurance`) | **posée**, puis **déduite** du journal | cardio au programme, ou course en échéance | 3 choix | usage d'entraîneur | `enduranceBase` |
| Sommeil habituel (`sommeil`) | **posée** comme valeur de départ | tous ; après la première semaine pour un débutant | 3 tranches | forte en aigu, faible en habituel | `sleep` |
| Stress habituel (`stress`) | **posée** comme valeur de départ | tous ; après la première semaine pour un débutant | 3 niveaux | modérée (blessure), faible à modérée (récupération) | `stress` |
| Charge hors programme : métier, autre sport (`charge_hors_programme`) | **posée** (une question) | tous ; après la première semaine pour un débutant | choix multiples + éditeur | modérée à forte (autre sport) ; absente (métier) | `occupationalLoad`, `otherSports` |
| Évolution du poids (`bilan_energetique`) | **posée** | niveau ≥ intermédiaire, ou discipline au poids du corps | 4 choix (+ poids visé, facultatif) | modérée | `bodyWeightGoal`, `targetBodyWeightKg` |
| Antécédents et zones sensibles (`antecedents`) | **posée** (schéma 2), **précisée** | tous | éditeur de liste | forte (principe) | `limitations` + `since`, `aggravatedBy`, `effortDiscomfort` |
| Poids de corps (`poids_de_corps`) | **posée** (schéma 2), expliquée ; **obligatoire** pour les disciplines au poids du corps | tous | nombre | forte (mécanique) | `bodyWeightKg` |
| Âge (`age`) | **posée** (schéma 2) | tous | année | modérée | `birthYear` |
| Sexe (`sexe`) | **posée** (schéma 2), sans effet sur le programme | tous | 3 choix | forte (absence d'effet) | `sex` |
| Taille (`taille`) | gardée (champ obligatoire du schéma 2), **sans effet** | tous | nombre | faible | `heightCm` |
| Qualité du sommeil, sommeil de la veille | **déduite** du bilan de séance | — | — | faible | `HealthCheck` |
| Travail de nuit, horaires décalés | **déduite** du sommeil | — | — | aucune étude directe | — |
| Moment d'entraînement dans la journée | **écartée** (heure de passage en compétition : point ouvert) | — | — | absence d'effet sur les gains | — |
| Fatigabilité selon le sexe | **déduite** des séries réalisées | — | — | dépend de la tâche | — |
| Cycle menstruel, contraception | **écartée** | — | — | effet trivial ou nul | — |
| Longueur des segments | **écartée** | — | — | faible, non actionnable | — |
| Asymétrie gauche / droite | **déduite** des séries unilatérales | — | — | faible | — |
| Mobilité limitante | **déduite** (revue du programme, premières séances) ; auto-contrôles par figure : point ouvert | — | — | usage d'entraîneur | — |
| Hyperlaxité | **écartée** | — | — | faible, auto-déclaration peu fiable | — |
| Nombre de pas, activité quotidienne | **écartée** | — | — | aucune directe | — |
| Protéines, alcool, tabac, médicaments | **écartée** | — | — | hors périmètre (ni conseil nutritionnel ni médical) | — |
| Faible disponibilité énergétique (REDs) | **écartée** | — | — | diagnostic clinique | — |
| Santé cardiovasculaire, métabolique | **non dupliquée** : questionnaire L13 | — | — | consensus | `healthScreening` |

## 3. Facteurs retenus

### `anciennete` — Ancienneté d'entraînement et niveau

- **Effet démontré.** C'est le modérateur le plus constant de la dose-réponse. Gains maximaux à environ 60 % du 1RM
  chez le non-entraîné contre 80 % chez l'entraîné, 4 séries par groupe musculaire dans les deux cas (`rhea2003`,
  méta-analyse de 140 études ; méthode ancienne). Le volume a des rendements décroissants, nettement plus marqués
  pour la force que pour l'hypertrophie (`pelland2026`). Chez l'homme entraîné, 12 à 20 séries par muscle et par
  semaine (`bazvalle2022`). À volume égal, un programme périodisé fait mieux qu'un programme non périodisé sur le 1RM
  (ES 0,31) et l'ondulation ne fait mieux que le linéaire **que chez les sujets entraînés** (ES 0,61 contre 0,06 chez
  les débutants) (`moesgaard2022`). La progression est logarithmique : environ deux fois plus lente dans le quartile
  des compétiteurs les plus forts (`latella2020`) ; plateau pratique vers 1 à 2 ans à dose minimale (`steele2023`).
- **Ce que ça change.** Volume et intensité de départ ; vitesse de progression attendue ; besoin de périodisation
  (blocs, ondulation) ; prérequis des techniques avancées et des figures en bras tendus (le tendon s'adapte en mois,
  voir `figures`).
- **Verdict : posée à partir du niveau intermédiaire**, 4 tranches (moins de 6 mois ; 6 mois à 2 ans ; 2 à 5 ans ;
  plus de 5 ans), en plus du niveau déclaré du schéma 2 (`experience`), qui ouvre les questions avancées. Un débutant
  (« je découvre, ou je reprends de zéro ») l'a déjà dit : la question ne lui est pas posée. **L'ancienneté demandée
  est celle de la discipline principale**, pas de l'entraînement en général : un haltérophile de huit ans qui commence
  la planche a zéro mois de bras tendus ; pour chaque figure, l'ancienneté à l'étape est demandée à part
  (`SkillState.atStepSince`, voir `figures`). Ensuite **déduite** des performances
  rapportées au poids de corps et de la vitesse de progression (moteur dynamique). Les tranches sont un choix
  raisonné : la littérature ne donne pas de seuil en mois ; « 6 mois » sépare le pratiquant qui ne sait pas encore
  estimer sa réserve (`steele2017`) et « 2 ans » la fin du plateau à dose minimale (`steele2023`).

### `interruption` — Interruption récente

- **Effet démontré.** Arrêt : force maximale SMD −0,46, force sous-maximale −0,62, puissance −0,20, avec une relation
  dose-réponse selon la durée de l'arrêt, plus forte après 65 ans (`bosquet2013`, 103 études). Jusqu'à 3 semaines
  d'arrêt sans conséquence sur les gains à 6 mois (`ogasawara2013`, 14 débutants). Dix semaines d'arrêt sont
  rattrapées en 5 semaines environ (`halonen2024`). La raideur du tendon gagnée en 3 mois est perdue en un mois
  d'arrêt (`kubo2012`).
- **Ce que ça change.** Reprise progressive après plus de 3 semaines, d'autant plus longue que l'arrêt l'a été ;
  figures et mouvements à forte contrainte tendineuse repris une étape en dessous après un mois d'arrêt — **choix
  raisonné** : `kubo2012` porte sur le tendon d'Achille de sujets non entraînés, en isométrie ; sa transposition au
  coude et à l'épaule d'un pratiquant de figures est une analogie. **Aucune grandeur de charge de reprise n'est
  justifiable** (aucun essai ne compare des charges de reprise) : choix raisonné, laissé aux moteurs.
- **Verdict : posée une fois**, à qui a au moins 6 mois d'ancienneté (un débutant n'a rien à reprendre) : régulier ;
  en allégé depuis quelques semaines ; arrêt de moins de 3 semaines ; de 3 à 10 semaines ; de 10 semaines à 6 mois ;
  de 6 mois à 2 ans ; de plus de 2 ans. Les bornes de 3 et 10 semaines viennent de `ogasawara2013` et de
  `halonen2024` ; au-delà de 10 semaines, aucune étude lue ne distingue les durées : les bornes de 6 mois et de 2 ans
  sont un choix raisonné (un arrêt de trois mois et un arrêt de trois ans ne se reprennent pas de la même façon), et
  « en allégé » distingue celui qui a continué à dose réduite de celui qui a arrêté. Ensuite **déduite** du journal
  (dates des séances, `TrainingLog.breaks`).

### `charge_actuelle` — Charge d'entraînement actuelle

- **Effet.** Aucune référence vérifiée ne chiffre l'effet d'un écart entre le volume habituel et le volume du premier
  bloc d'un nouveau programme ; les rapports de charge aiguë sur chronique sont contestés (`impellizzeri2020`) et ne
  sont pas utilisés. C'est un **usage d'entraîneur**, solidement admis : un premier bloc très en dessous de ce que
  l'athlète fait déjà est une décharge involontaire, très au-dessus, un saut de charge. Pour les figures, la
  fréquence actuelle dit aussi l'exposition des coudes et des épaules aux bras tendus (voir `figures`).
- **Ce que ça change.** Volume et fréquence du premier bloc, par mouvement ; rien ensuite : le journal remplace ces
  réponses dès les premières semaines.
- **Verdict : posée, facultative, à partir du niveau avancé** — avant, démarrer prudemment et laisser le moteur
  dynamique apprendre la tolérance suffit. Par mouvement principal ou figure (3 à 4 lignes pré-remplies) : séances
  par semaine et, facultativement, tranche de séries dures par semaine ; une fois pour tout l'écran : la phase en
  cours (volume, lourd, sortie de pic, sans structure). Des tranches, pas des chiffres exacts : personne ne compte
  ses séries à l'unité.

### `tests_records` — Tests et records

- **Effet.** Ce n'est pas un facteur de tolérance mais une **mesure** : sans maximum connu, pas de charge en part du
  maximum, pas d'affûtage chiffré, pas de choix de tentatives. Un 1RM mesuré varie d'environ 4 % d'un jour à l'autre
  (`grgic2020`) ; un 1RM estimé à partir de 3 à 6 répétitions, d'environ 5 % (§ 5).
- **Ce que ça change.** Charges exprimées en part du maximum dès le premier bloc ; tests programmés seulement là où
  une valeur manque ou date ; tentatives du jour J.
- **Verdict : posée** à partir du niveau intermédiaire (valeur exacte, nature, date, origine, réserve éventuelle), en
  plus des fourchettes du schéma 2 (D3.5), qui restent la réponse du débutant ; les records sont demandés **avant**
  les fourchettes, qui ne portent alors que sur les mouvements sans record. « Je ne sais pas » : aucun record
  n'est écrit, un **test guidé** est proposé (§ 5). Convention de charge : externe (lest seul pour un exercice lesté),
  comme dans tout le profil. Un record peut être marqué **au standard de compétition** (amplitude complète, arrêts
  marqués ; `competitionStandard`) : seuls ceux-là fondent le choix des tentatives ; un record de plus de 6 mois est
  gardé, mais retesté avant qu'on s'y fie (choix raisonné).

### `figures` — Figures : cible et étape actuelle

- **Effet.** Les blessures de calisthénie touchent à plus de 70 % le membre supérieur, surtout muscles et tendons
  (`kaiser2018`) ; la tendinopathie est le diagnostic le plus rapporté en street workout et le volume d'activité
  vigoureuse le principal facteur associé (OR 4,4 à 5,6 ; enquête transversale, `ngo2021`). La raideur du tendon ne
  change pas en 2 mois d'entraînement et monte nettement au 3e mois (`kubo2012`) ; l'adaptation tendineuse dépend de
  l'intensité de la charge plus que du type de contraction (`bohm2015`). **Aucune étude ne porte sur la planche, le
  front lever ou l'équilibre chez l'adulte** : les échelles de progression et leurs critères de passage sont un usage
  d'entraîneur (`low2016`).
- **Ce que ça change.** Étape de départ de chaque progression ; durée de maintien prescrite ; critère de passage à
  l'étape suivante (paramétrable : `StepCriterion`, dont une durée minimale à l'étape, adossée au délai d'adaptation
  du tendon) ; régression un mauvais jour.
- **Verdict : posée** à qui a de la calisthénie, du streetlifting ou du CrossFit au programme : figure visée, étape
  actuelle (choisie dans la chaîne `variante_de` du catalogue), meilleur maintien ou meilleur nombre de répétitions
  propres, et **depuis quand il en est à cette étape** (4 tranches, `atStepSince`) : c'est l'état de départ du
  critère de passage (durée minimale à l'étape) ; plus de 6 mois à la même étape signale un plateau, pour lequel la
  méthode change (`plan.skill_plateau`). Le délai d'adaptation du tendon qui fonde ces durées est une preuve
  **indirecte** (tendon d'Achille, `kubo2012`) : choix raisonné.

### `orientation` — En musculation : muscle, force, ou les deux

- **Effet.** La dose-réponse n'est pas la même pour la force et pour l'hypertrophie : rendements décroissants du
  volume bien plus marqués pour la force (`pelland2026`), intensité optimale plus haute chez l'entraîné pour la force
  (`rhea2003`). Les plages de répétitions et la proximité de l'échec propres à chaque orientation ne sont pas fixées
  ici (aucune référence vérifiée dans ce lot) : elles relèvent du référentiel du lot CR.
- **Pourquoi une question.** Un objectif du profil est une performance chiffrée datée ou une habitude (D3.8) ;
  « prendre du muscle » ne s'y exprime pas, et ne se déduit de rien d'autre.
- **Verdict : posée** à qui a de la musculation au programme, un seul appui (du muscle, de la force, les deux).
  Avec `specialization` (ouverte dès le niveau intermédiaire en musculation, pour nommer une zone à développer).

### `competition` — Compétition et échéances

- **Effet démontré.** Affûtage : optimum à 2 semaines, volume réduit de 41 à 60 %, intensité et fréquence gardées
  (`bosquet2007`, méta-analyse, surtout sports d'endurance). En force athlétique : volume réduit de 30 à 70 % sur 7 à
  28 jours, intensité gardée à au moins 85 % du 1RM, arrêt complet de 2 à 7 jours sans perte (`travis2020`) ;
  pratiques de champions : volume −50 à −59 %, dernière séance 3 à 4 jours avant (`pritchard2016`, `grgic2017`).
  Tentatives d'élite en force athlétique : ouverture à environ 91 % de la troisième barre visée, puis +5 % et +3 %
  (`travis2021`). **Aucune donnée propre au streetlifting** : la transposition est une hypothèse. **Épreuves de
  répétitions et freestyle** : l'affûtage de force athlétique (intensité d'au moins 85 %, volume réduit de moitié)
  ne se transpose pas tel quel — en endurance de force, c'est la densité spécifique qu'on garde, et l'affûtage est
  plus court ; aucune référence vérifiée : **usage d'entraîneur**, à régler par les moteurs et à mesurer au banc.
- **Formats.** Streetlifting : 3 tentatives par mouvement, charge jamais décroissante, saut minimal de 1,25 kg
  (2,5 kg au squat), 1 à 4 mouvements selon le format (règlements Final Rep et ISF, pages lues le 02/10/2026). Sets &
  reps : **aucun règlement unifié** — maximum de répétitions en temps limité, total de répétitions lestées, volume
  imposé contre la montre, duels sur routine imposée. D'où une échéance décrite par des données (mouvements,
  tentatives, postes, tours, temps), sans format figé (`PARCOURS_V3.md` § 4).
- **Ce que ça change.** Plan de saison (phases, affûtage, pic de forme), travail spécifique des épreuves, tentatives
  et rythme le jour J.
- **Verdict : posée** à partir du niveau intermédiaire, dès qu'un objectif de performance daté existe, ou quand le
  cardio est au programme (une course se prépare à tout niveau) : nature, date (ou mois, si la date n'est pas fixée),
  priorité (principale, secondaire, préparation), format ; plusieurs échéances par saison. Pour un format annoncé le
  jour même, l'échéance se déclare sans postes (`formatKnown: false`) : préparation générale. Pour une épreuve déjà
  disputée, le meilleur résultat (temps ou total de répétitions) se saisit dans l'échéance.

### `specialisation` — Priorité à un mouvement, une figure, un muscle

- **Effet.** Une dose très réduite suffit à **faire progresser** lentement le 1RM d'hommes entraînés : une série de
  6 à 12 répétitions à 70-85 % du 1RM, 2 à 3 fois par semaine (`androulakis2020`). Cette revue porte sur la dose
  minimale pour progresser, pas sur l'entretien, et pas sur des compétiteurs d'élite : qu'une dose réduite
  **entretienne** le reste pendant qu'on concentre le volume sur une cible en est une conséquence plausible, pas un
  résultat lu. Les travaux qui portent directement sur l'entretien à dose réduite n'ont pas pu être vérifiés dans ce
  lot et ne sont pas cités. Niveau de preuve retenu : **usage d'entraîneur**.
- **Verdict : posée, facultative**, à partir du niveau avancé (décision C1.3 du propriétaire), et dès le niveau
  intermédiaire en musculation (« une zone à développer en priorité ? »). Avant, la priorité se **déduit** du premier
  objectif du profil. S'il existe une échéance principale, le plan de saison prime : la priorité n'est servie que
  loin de l'échéance, et le reste est entretenu.

### `points_faibles` — Points faibles

- **Effet.** Le point de blocage d'un mouvement existe, est reproductible et se décrit en mécanique
  (`kompf2017`). **Aucun essai ne montre** qu'un exercice d'assistance choisi d'après le point de blocage fait mieux
  progresser qu'un exercice générique ; rien de publié pour la traction lestée, le dips lesté ou le muscle-up.
- **Verdict : posée, facultative**, aux pratiquants avancés des disciplines de force, en termes simples (« je bloque
  en bas du dips »). Assumée comme une **heuristique d'entraîneur** : elle oriente le choix des exercices
  d'assistance, sans promesse. Une douleur n'est pas un point faible (voir `antecedents`).

### `sommeil` — Sommeil habituel

- **Effet démontré, en aigu.** Perte de sommeil (6 h ou moins) : performance −7,6 % en moyenne ; force maximale
  −2,9 % seulement ; endurance de force −9,9 % ; endurance −5,6 % (`craven2022`, 69 études). Neuf nuits à 5 h : le
  volume réalisé ne baisse presque pas (moins de 1 %), mais l'effort perçu de la séance monte de 11 % et la vitesse
  de barre baisse jusqu'à 15 % sur le bas du corps (`knowles2022`).
- **Effet non démontré, en habituel.** Aucune méta-analyse ne montre qu'un sommeil habituel court réduit les gains à
  long terme ; la seule étude directe trouvée (6 h 17 contre 7 h 47) ne trouve aucune différence sur 16 séances
  (`borba2024`). Le lien avec la blessure n'est établi que chez l'adolescent ; chez l'adulte, les données ne le
  soutiennent pas (`dobrosielski2021`). Le consensus d'experts fixe le sommeil « court » à moins de 7 h et recommande
  de se fier au besoin perçu (`walsh2021`).
- **Ce que ça change.** Jamais de baisse de charge. Sous 6 h : prudence sur le volume proche de l'échec et sur le
  cardio intense, pilotage à l'effort perçu. **Aucune grandeur chiffrée n'est justifiable** ; aucune promesse sur les
  blessures.
- **Verdict : posée à tous comme valeur de départ**, une question, 3 tranches (moins de 6 h ; 6 à 7 h ; plus de
  7 h, 7 h juste compris — seuils de `craven2022` et de `walsh2021`) ; pour un débutant, après la première semaine.
  Preuve forte en aigu, faible en habituel. À strictement parler, la règle (c) du § 1 la condamnerait (le bilan de
  séance finit par dire la même chose) : elle est gardée parce qu'elle coûte un appui, qu'elle règle le premier bloc
  avant tout bilan, et qu'elle distingue le petit dormeur chronique, que le bilan du jour ne voit que les jours où
  il se sent mal — **dès que les bilans existent, ce sont eux qui font foi**. La **qualité** du sommeil et la nuit
  de la veille sont dans le bilan de séance : pas de doublon.

### `stress` — Stress habituel

- **Effet démontré.** Le stress chronique ralentit la récupération de la force, de l'énergie et des courbatures
  jusqu'à 96 h après une séance dure (`stults2014`, 31 étudiants) ; les gains de 1RM sur 12 semaines sont plus faibles
  dans le groupe le plus stressé (`bartholomew2008`, 135 étudiants, sans chiffre publié dans le résumé) ; une seule
  question de stress auto-évalué prédit la réponse à l'entraînement aérobie (`ruuska2012`). Blessure : association
  r = 0,27 avec la réponse au stress (`ivarsson2017`, méta-analyse, intervalles à 80 %).
- **Limite.** Une seule équipe pour la récupération et les gains, petits effectifs d'étudiants, aucune réplication ;
  **aucune grandeur d'ajustement publiée**.
- **Ce que ça change (choix raisonné).** Stress élevé : séances lourdes d'un même groupe plus espacées, pas de hausse
  de volume, décharge avancée.
- **Verdict : posée à tous comme valeur de départ**, 3 niveaux, sur les dernières semaines (pour un débutant, après
  la première semaine) ; **redemandée** de temps en temps (`lifestyleUpdatedOn`), car elle change. Le stress du jour
  reste dans le bilan de séance, qui fait foi dès qu'il existe.

### `charge_hors_programme` — Métier physique et autres sports

- **Autres sports : effet démontré, et précis.** L'endurance ajoutée ne réduit ni la force maximale (SMD −0,06) ni
  l'hypertrophie (SMD −0,01), mais réduit la force explosive (SMD −0,28), surtout quand les deux sont dans la même
  séance (`schumann2022`, 43 études). Chez les sujets entraînés, la force du bas du corps souffre quand force et
  endurance sont dans la même séance (ES −0,66) et pas en séances séparées (ES −0,10) (`petre2021`). L'interférence
  est locale (bas du corps) (`huiberts2024`). Elle croît avec la fréquence et la durée de l'endurance, et y est
  significative avec la course, pas avec le vélo (`wilson2012`) — différence qui n'est pas retrouvée d'une
  méta-analyse à l'autre : la nature du sport sert au **placement** (quelles régions sont fatiguées), pas à un
  coefficient différent.
  Sports collectifs, de combat, escalade : aucune méta-analyse ; raisonnement par analogie.
- **Métier physique : aucune preuve directe.** Les travaux sur le « paradoxe de l'activité physique » portent sur la
  mortalité (`coenen2018`), pas sur la récupération ni sur les gains. Gardé comme **choix raisonné** : c'est une
  charge quotidienne réelle, et la réponse ne coûte rien de plus (même question).
- **Ce que ça change.** Un ajustement de **placement**, pas un coefficient de volume : séances lourdes ou explosives
  des mêmes régions à distance des autres sports. Aucun seuil de rapport de charge aiguë sur chronique n'est utilisé
  (contesté : `impellizzeri2020`). Si l'autre sport est le sport principal de la personne (`mainSport`), pas de
  séance lourde des régions concernées la veille. Métier physique : départ prudent.
- **Verdict : posée à tous, en une seule question** à choix multiples (assis ; debout ou en mouvement ; métier
  physique ; autre sport régulier) ; « autre sport » ouvre un éditeur (sport, séances par semaine, durée, jours,
  intensité, sport principal ou non, régions sollicitées). Pour un débutant, après la première semaine. Le nombre
  de pas est **écarté** (aucune donnée directe).

### `base_endurance` — Volume de course actuel

- **Effet.** Aucune référence vérifiée dans ce lot ne chiffre une règle de progression du volume de course ; les
  rapports de charge aiguë sur chronique ne sont pas utilisés (`impellizzeri2020`). **Usage d'entraîneur** : le
  premier bloc de course repart de ce qui est fait ces dernières semaines, pas de ce qui serait possible. Le volume
  dit aussi la confiance à accorder à une prédiction de temps : la formule de `riegel1981` suppose un coureur
  entraîné pour la distance visée (§ 5).
- **Ce que ça change.** Distance hebdomadaire et sortie longue du premier bloc ; incertitude des allures prédites.
- **Verdict : posée** à qui a le cardio au programme ou une course en échéance : volume hebdomadaire des quatre
  dernières semaines (6 tranches), nombre de sorties, plus longue sortie récente (4 tranches). Ensuite **déduite** du
  journal. La fréquence cardiaque maximale n'est pas demandée : les allures se donnent en part d'une vitesse mesurée
  ou à l'effort perçu ; les prescriptions à la fréquence cardiaque sont laissées au lot CP2 (point ouvert).

### `bilan_energetique` — Évolution voulue du poids de corps

- **Effet démontré.** En déficit énergétique, les gains de masse maigre sont altérés (ES −0,57) mais pas les gains de
  force (ES −0,31, non significatif) ; un déficit d'environ 500 kcal par jour annule le gain de masse maigre
  (`murphy2022`, méta-analyse, surtout des sujets peu entraînés). Une perte lente (0,7 % du poids par semaine)
  préserve mieux la masse maigre qu'une perte rapide (`garthe2011`, 24 athlètes). Chez les pratiquants entraînés en
  restriction, les programmes à volume élevé gardent mieux la masse maigre (`roth2022`, preuve faible). Un surplus
  plus grand n'apporte pas plus de muscle, surtout de la masse grasse (`helms2023`, petit essai).
- **Ce que ça change.** En perte de poids : attentes réglées (la force peut monter, pas le muscle), volume **gardé**,
  charges gardées ; pour les mouvements au poids du corps et lestés, la charge totale change avec le poids. Surplus
  ou maintien : aucun changement de programme. **Aucun conseil alimentaire** n'est donné ; le rythme réel se lit
  dans les pesées.
- **Verdict : posée** à partir du niveau intermédiaire et à tout pratiquant d'une discipline au poids du corps (mode
  street, streetlifting, street workout, calisthénie : catégories de poids, lest) : baisser, garder, monter, pas
  d'objectif ; « baisser » ou « monter » propose un poids visé, facultatif (`targetBodyWeightKg`). Pour une
  compétition à catégories, le poids prévu le jour J se saisit dans l'échéance (`plannedBodyWeightKg`) ; **aucune
  question sur la méthode**, aucun conseil.

### `antecedents` — Antécédents et zones sensibles

- **Effet démontré.** Un antécédent multiplie le risque de blessure par 2 à 3 la saison suivante (HR 2,7 ; football,
  `hagglund2006`) ; en street workout, OR 4,08 (enquête transversale, 93 pratiquants, `ngo2021`). En force
  athlétique, 87 % des pratiquants déclarent une blessure dans l'année, le plus souvent sans arrêter de s'entraîner
  (`stromback2018`) : « blessure » y veut dire « gêne avec laquelle on continue en adaptant ».
- **Conduite.** Continuer en surveillant la douleur donne les mêmes résultats que le repos (`silbernagel2007`) ; une
  douleur tolérée à l'exercice n'est pas un obstacle (`smith2017`) ; c'est la charge progressive qui compte, pas le
  mode de contraction (`beyer2015`) ; le renforcement réduit les blessures (RR 0,34 ; `lauersen2018`). **Aucun
  pourcentage de réduction de charge n'est publié.** Les seuils de douleur de l'application (D5.9, G8) restent ceux
  qui sont en place, plus bas que le modèle clinique : choix raisonné hors soin.
- **Ce que ça change.** Mouvements qui chargent la zone : départ une variante en dessous, progression plus lente, pas
  de test maximal tant que la gêne (au repos ou à l'effort) est d'au moins 4/10 ; fenêtre de vigilance de 12 mois —
  **choix raisonné**, par analogie avec `hagglund2006` (blessures du membre inférieur au football, saison suivante) :
  la durée n'est pas démontrée pour le coude ou l'épaule d'un pratiquant de force.
- **Verdict : posée à tous** (schéma 2 : zone, côté, gêne de 0 à 10), **précisée** en schéma 3 par trois champs
  facultatifs : depuis quand ; **quels mouvements la réveillent** — l'information la plus utile, qui désigne
  directement ce qu'il faut régresser sans interpréter une structure anatomique ; et **la gêne à l'effort**
  (`effortDiscomfort`) : une gêne de tendon est souvent nulle au repos et nette sous charge, et c'est la valeur à
  l'effort qui décide des tests maximaux. Une gêne de plus de 5/10, une douleur la nuit, une perte de force ou une
  aggravation sur deux semaines : Koach oriente vers un professionnel de santé, sans interpréter (règle L13).

### `poids_de_corps`, `age`, `sexe`, `taille` — Questions du schéma 2

- **`poids_de_corps`** : c'est la charge des exercices au poids du corps (pompe : environ 70 % du poids,
  `CONTRAT.md` § 2) et la base de la charge totale d'une traction ou d'un dips lesté. **Gardée**, mieux expliquée,
  et **obligatoire** pour les disciplines au poids du corps (mode street, streetlifting, street workout,
  calisthénie) : sans lui, ni charge totale, ni pourcentage, ni test lesté.
- **`age`** : gain de masse maigre un peu plus faible avec l'âge après 50 ans (β = −0,03 ; `peterson2011`) ; perte
  plus forte à l'arrêt après 65 ans (`bosquet2013`). La récupération plus lente **n'est pas démontrée** (courbatures
  plutôt plus fortes chez les jeunes : `fernandes2025`) : aucune réduction de volume ni allongement du repos sur le
  seul critère de l'âge. Sert à la prudence des tests (pas de maximum direct après 65 ans sans expérience : 19 % de
  blessures chez des septuagénaires non entraînés, `pollock1991`).
- **`sexe`** : gains relatifs de taille musculaire identiques (`refalo2025`) ; pas de différence d'hypertrophie ni
  de force du bas du corps, mais des gains **relatifs** de force du haut du corps plus grands chez les femmes
  (ES −0,60 ; les auteurs évoquent un possible effet de la courte durée des études et du statut non entraîné)
  (`roberts2020`). **Aucun effet sur le programme** (mêmes volumes relatifs) ; l'effet relève des **attentes de
  progression** sur les tractions et les dips, et le sexe sert aux repères de rang (D7.5).
- **`taille`** : corrélations modestes avec la performance entre compétiteurs, aucune étude d'intervention. **Aucun
  effet sur le programme** ; gardée parce que le champ est obligatoire dans le schéma 2 (le rendre facultatif serait
  une rupture de contrat). **Recommandation au propriétaire** (les deux relecteurs du parcours l'ont demandée) :
  rendre la taille facultative ou la retirer à la prochaine évolution non additive du contrat.

## 4. Facteurs écartés ou déduits

- **Moment de la journée** : gains de force et de masse identiques matin ou soir (`grgic2019`). Écarté au profil.
  Pour un compétiteur, placer les séances lourdes des dernières semaines à l'heure de passage est un usage
  d'entraîneur (aucune référence vérifiée ici) : l'heure de passage n'est pas dans l'échéance en 0.4.0 — point
  ouvert pour CP1.
- **Travail de nuit, horaires décalés** : aucune étude directe sur l'entraînement de force ; l'effet plausible passe
  par le sommeil, déjà demandé. Déduit.
- **Cycle menstruel** : effet trivial (ES −0,06 ; `mcnulty2020`) ; « prématuré » de conclure à une influence
  (`colenso2023`). **Contraception** : aucun effet sur l'hypertrophie, la puissance ou la force (`nolan2024`).
  Écartés ; l'autorégulation (flammes) absorbe les variations individuelles.
- **Fatigabilité selon le sexe** : dépend de la tâche (`hunter2016`) ; déduite des séries réalisées.
- **Asymétrie** : preuve faible et limitée au membre inférieur (`helme2021`) ; déduite des séries unilatérales.
- **Hyperlaxité** : association avec les blessures d'épaule (OR 3,25, qualité de preuve faible ; `liaghat2021`),
  auto-déclaration peu fiable sans test ; un épisode de luxation relève des antécédents. Écartée.
- **Mobilité limitante** : la question n'est pas la blessure (aucun dépistage ne la prédit, `bahr2016`) mais
  l'accès à une position (équilibre aligné, squat au standard, L-sit, planche sur les poignets). En 0.4.0 elle se
  constate à la revue du programme (« je ne sais pas faire », D4.5) et aux premières séances : **déduite**. Le
  relecteur « coach d'élite » propose des auto-contrôles par figure (« dos au mur, bras tendus au-dessus de la tête :
  tes bras touchent le mur sans cambrer ? ») : usage d'entraîneur pertinent, non retenu dans ce lot (aucun protocole
  d'auto-contrôle vérifié, et une question de plus par figure) — **point ouvert** pour CP1, qui dira s'il en a
  besoin pour choisir l'étape de départ.
- **Protéines** : effet réel mais petit (+0,30 kg de masse maigre ; `morton2018`), non actionnable sans conseil
  nutritionnel. **Alcool, tabac, médicaments** : hors périmètre. Écartés.
- **Faible disponibilité énergétique (REDs)** : diagnostic clinique (`mountjoy2023`). Écartée.
- **Santé cardiovasculaire et métabolique** : couverte par le questionnaire santé L13 (`riebe2015`). Non dupliquée.
- **Score de risque de blessure** : jamais calculé (`bahr2016`).

## 5. Tests guidés : bases

- **Estimation du 1RM.** Équation de Brzycki, `1RM = charge × 36 / (37 − r)` (`brzycki1993`), la plus proche, entre 3
  et 6 répétitions, de la méta-régression de 952 tests à l'échec : environ 5 répétitions à 90 % du 1RM, 9 à 80 %
  (`nuzzo2024`). Le 5RM prédit mieux que le 10RM et le 20RM ; pas d'estimation au-delà de 10 répétitions
  (`reynolds2006`, `mayhew2008`). Écart-type entre individus de 2,5 répétitions à 80 % (`nuzzo2024`) : d'où une
  incertitude d'environ ±5 % du 1RM (un écart-type) — **calcul de ce lot, pas un chiffre publié**.
- **Réserve déclarée.** Sous-estimation moyenne de 0,95 répétition (`halperin2022`) ; de 4 à 5 répétitions chez les
  tout débutants, de 1 à 2 chez les plus anciens (`steele2017`). Une série arrêtée avec 1 à 2 répétitions en réserve
  ne vaut pas un test à l'échec : on compte répétitions + réserve, l'incertitude passe à ±7,5 % (±10 % avant 6 mois
  de pratique), et le biais est prudent (maximum plutôt sous-estimé).
- **Mouvements lestés.** Les études qui mesurent un 1RM de traction ou de dips l'expriment en poids de corps + lest
  (`ortega2021`, `coyne2015`) ; fiabilité test-retest excellente (ICC 0,96 à 0,99 ; `coyne2015`). L'équation
  s'applique donc à la charge totale. **Aucune étude ne valide l'équation sur ces mouvements** : extrapolation, dont
  l'erreur est amplifiée sur le lest. Muscle-up lesté : aucune estimation par équation.
- **Maximum direct.** Fiable (ICC médian 0,97, coefficient de variation médian 4,2 %, très peu d'incidents ;
  `grgic2020`, `seo2012`) ; protocole de montée de la NSCA (`nsca2016`) ; déconseillé au senior non entraîné
  (`pollock1991`).
- **Répétitions max.** Pompes : changement minimal détectable de 4,7 répétitions (`kardor2023`) ; les répétitions
  max bougent bien plus vite que la force maximale (+15 % contre +3,4 % en 12 semaines ; `sanchezmoreno2017`) ;
  fiabilité du nombre de répétitions : ICC 0,86 à 70 % du 1RM, 0,65 à 90 % (`mitter2022`).
- **Maintiens.** Gainage : ICC supérieur à 0,98, coefficient de variation de 5 à 6 % (`rodriguezperea2025`) ; test
  d'endurance des extenseurs du tronc : ICC 0,88 (`martinezromero2020`). Aucune étude de fiabilité pour la
  suspension, le L-sit, la planche ou le front lever. Séries à 60-70 % du maintien max : usage d'entraîneur
  (`low2016`).
- **Course.** Tests en durée ou en distance fixe : validité de 0,78 à 0,79 pour estimer le VO2max
  (`mayorgavega2016`, `cooper1968`) — on utilise directement la vitesse mesurée. Contre-la-montre de 5 km : erreur
  typique de 2,0 % (`laursen2007`). Prédiction entre distances : `T2 = T1 × (D2 / D1)^1,06` (`riegel1981`), bien
  calibrée jusqu'au semi-marathon, trop optimiste au marathon (`vickers2016`). Elle suppose un volume de course
  suffisant pour la distance visée : à faible volume hebdomadaire (`base_endurance`), la prédiction d'une distance
  plus longue est « provisoire », avec une incertitude élargie (au moins ±4 % : estimation de ce lot, aucune grandeur
  publiée pour le 10 km).
- **Épreuves de répétitions.** Maximum en temps limité et séries maximales répétées (protocoles `t9`, `t10`) :
  usage d'entraîneur, aucune étude de fiabilité lue ; seule la fiabilité du nombre de répétitions à charge donnée
  est documentée (`mitter2022`).
- **Qui peut tester.** Aucun test guidé pour un débutant ni pour un profil dont le questionnaire santé n'est pas
  « standard » : calage au fil des séances. Chaque protocole a un prérequis par mouvement (par exemple 8 répétitions
  strictes au poids du corps avant une série lestée ; 5 muscle-ups stricts avant un maximum de muscle-up lesté) :
  usage d'entraîneur.
- **Quand.** Le 1RM d'un débutant monte par simple apprentissage (3 à 4 séances pour le stabiliser chez la jeune
  adulte, davantage chez la personne âgée ; `ploutzsnyder2001`, très petits effectifs) : déclarations à la création,
  tests sous-maximaux à la première séance, valeurs « provisoires » les deux à trois premières séances.

## 6. Ce que les moteurs doivent en faire

Le profil ne fixe aucune règle chiffrée de programmation : il porte les réponses. Pour les lots CP1 et CA1 :

0. **Ordre de priorité des sources** : le journal et les bilans de séance priment sur les déclarations du profil dès
   qu'ils existent (charge actuelle, volume de course, sommeil, stress, interruption) ; le plan de saison prime sur
   la spécialisation ; près d'une échéance principale (phases de réalisation et d'affûtage), la phase prime aussi sur
   le dosage des disciplines secondaires ; une gêne à l'effort prime sur la gêne au repos.
1. **Preuve chiffrée disponible** (à reprendre du référentiel du lot CR) : affûtage (`bosquet2007`, `travis2020`),
   périodisation selon le niveau (`moesgaard2022`), dose-réponse du volume (`pelland2026`, `bazvalle2022`),
   séparation des séances chez les entraînés (`petre2021`), tentatives (`travis2021`), estimation du 1RM (§ 5).
2. **Direction démontrée, grandeur non publiée** (sommeil court, stress élevé, déficit énergétique, antécédent,
   reprise) : l'ajustement est un **choix raisonné**, à écrire comme tel, à garder modeste et à mesurer au banc.
3. **Aucune preuve directe** (métier physique, points faibles, critères de passage des figures, charge actuelle,
   volume de course, affûtage des épreuves de répétitions et des figures, entretien pendant une spécialisation) : usage
   d'entraîneur, à dire comme tel ; jamais présenté à l'utilisateur comme « démontré ».
4. **Jamais** : déplacer un mouvement de compétition ou son travail d'assistance parce qu'un autre exercice est
   « aimé » (les préférences départagent des exercices équivalents, rien de plus) ; baisser les charges pour un sommeil court ; réduire le volume d'un senior sur le seul critère de
   l'âge ; programmer selon le cycle menstruel ; promettre une réduction du risque de blessure ; calculer un score
   de risque ; inventer une valeur pour une réponse absente.

## 7. Références

Statut : **V** = notice et résultat lus dans le résumé ; **P** = notice confirmée, chiffre lu sur une source
secondaire ou non relu (précisé). Voir les limites du § 0.

| Clé | Référence | DOI | Statut |
| --- | --- | --- | --- |
| `androulakis2020` | Androulakis-Korakakis P., Fisher J. P., Steele J. (2020). The minimum effective training dose required to increase 1RM strength in resistance-trained men. *Sports Med* 50:751-765. | 10.1007/s40279-019-01236-0 | V |
| `bahr2016` | Bahr R. (2016). Why screening tests to predict injury do not work—and probably never will…: a critical review. *Br J Sports Med* 50(13):776-780. | 10.1136/bjsports-2016-096256 | V |
| `bartholomew2008` | Bartholomew J. B., Stults-Kolehmainen M. A., Elrod C. C., Todd J. S. (2008). Strength gains after resistance training: the effect of stressful, negative life events. *J Strength Cond Res* 22(4):1215-1221. | 10.1519/JSC.0b013e318173d0bf | V (aucun chiffre dans le résumé) |
| `bazvalle2022` | Baz-Valle E., Balsalobre-Fernández C., Alix-Fages C., Santos-Concejero J. (2022). A systematic review of the effects of different resistance training volumes on muscle hypertrophy. *J Hum Kinet* 81:199-210. | 10.2478/hukin-2022-0017 | V |
| `beyer2015` | Beyer R., Kongsgaard M., Hougs Kjær B. et al. (2015). Heavy slow resistance versus eccentric training as treatment for Achilles tendinopathy: a randomized controlled trial. *Am J Sports Med* 43(7):1704-1711. | 10.1177/0363546515584760 | V |
| `bohm2015` | Bohm S., Mersmann F., Arampatzis A. (2015). Human tendon adaptation in response to mechanical loading: a systematic review and meta-analysis. *Sports Med Open* 1:7. | 10.1186/s40798-015-0009-9 | V |
| `borba2024` | Borba D. A., Brant V. M., Costa C. M. A. et al. (2024). Could a habitual sleep restriction of one-two hours be detrimental to the benefits of resistance training? *Sleep Sci* 17(3):e244-e254. | 10.1055/s-0044-1787297 | V |
| `bosquet2007` | Bosquet L., Montpetit J., Arvisais D., Mujika I. (2007). Effects of tapering on performance: a meta-analysis. *Med Sci Sports Exerc* 39(8):1358-1365. | 10.1249/mss.0b013e31806010e0 | V |
| `bosquet2013` | Bosquet L., Berryman N., Dupuy O. et al. (2013). Effect of training cessation on muscular performance: a meta-analysis. *Scand J Med Sci Sports* 23(3):e140-e149. | 10.1111/sms.12047 | V |
| `brzycki1993` | Brzycki M. (1993). Strength testing—predicting a one-rep max from reps-to-fatigue. *J Phys Educ Recreat Dance* 64(1):88-90. | 10.1080/07303084.1993.10606684 | P (notice : revue, année, pages, DOI ; titre de mémoire ; formule lue sur deux sources secondaires concordantes) |
| `coenen2018` | Coenen P., Huysmans M. A., Holtermann A. et al. (2018). Do highly physically active workers die early? A systematic review with meta-analysis of data from 193 696 participants. *Br J Sports Med* 52(20):1320-1326. | 10.1136/bjsports-2017-098540 | V |
| `colenso2023` | Colenso-Semple L. M., D'Souza A. C., Elliott-Sale K. J., Phillips S. M. (2023). Current evidence shows no influence of women's menstrual cycle phase on acute strength performance or adaptations to resistance exercise training. *Front Sports Act Living* 5:1054542. | 10.3389/fspor.2023.1054542 | V |
| `cooper1968` | Cooper K. H. (1968). A means of assessing maximal oxygen intake: correlation between field and treadmill testing. *JAMA* 203(3):201-204. | 10.1001/jama.1968.03140030033008 | V |
| `coyne2015` | Coyne J. O. C., Tran T. T., Secomb J. L. et al. (2015). Reliability of pull up and dip maximal strength tests. *J Aust Strength Cond* 23(4):21-27. | — | V |
| `craven2022` | Craven J., McCartney D., Desbrow B. et al. (2022). Effects of acute sleep loss on physical performance: a systematic and meta-analytical review. *Sports Med* 52:2669-2690. | 10.1007/s40279-022-01706-y | V |
| `dobrosielski2021` | Dobrosielski D. A., Sweeney L., Lisman P. J. (2021). The association between poor sleep and the incidence of sport and physical training-related injuries in adult athletic populations: a systematic review. *Sports Med* 51(4):777-793. | 10.1007/s40279-020-01416-3 | V |
| `fernandes2025` | Fernandes J. F. T., Wilson L. J., Dingley A. F. et al. (2025). Advancing age is not associated with greater exercise-induced muscle damage: a systematic review, meta-analysis, and meta-regression. *J Aging Phys Act* 33:606-624. | 10.1123/japa.2024-0165 | V |
| `garthe2011` | Garthe I., Raastad T., Refsnes P. E. et al. (2011). Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes. *Int J Sport Nutr Exerc Metab* 21(2):97-104. | 10.1123/ijsnem.21.2.97 | V |
| `grgic2017` | Grgic J., Mikulic P. (2017). Tapering practices of Croatian open-class powerlifting champions. *J Strength Cond Res* 31(9):2371-2378. | 10.1519/JSC.0000000000001699 | V |
| `grgic2019` | Grgic J., Lazinica B., Garofolini A. et al. (2019). The effects of time of day-specific resistance training on adaptations in skeletal muscle hypertrophy and muscle strength: a systematic review and meta-analysis. *Chronobiol Int* 36(4):449-460. | 10.1080/07420528.2019.1567524 | V |
| `grgic2020` | Grgic J., Lazinica B., Schoenfeld B. J., Pedisic Z. (2020). Test-retest reliability of the one-repetition maximum (1RM) strength assessment: a systematic review. *Sports Med Open* 6:31. | 10.1186/s40798-020-00260-z | V |
| `hagglund2006` | Hägglund M., Waldén M., Ekstrand J. (2006). Previous injury as a risk factor for injury in elite football: a prospective study over two consecutive seasons. *Br J Sports Med* 40(9):767-772. | 10.1136/bjsm.2006.026609 | V |
| `halonen2024` | Halonen E. J., Gabriel I., Kelahaara M. M. et al. (2024). Does taking a break matter—adaptations in muscle strength and size between continuous and periodic resistance training. *Scand J Med Sci Sports* 34(10):e14739. | 10.1111/sms.14739 | V |
| `halperin2022` | Halperin I., Malleron T., Har-Nir I. et al. (2022). Accuracy in predicting repetitions to task failure in resistance exercise: a scoping review and exploratory meta-analysis. *Sports Med* 52:377-390. | 10.1007/s40279-021-01559-x | V |
| `helme2021` | Helme M., Tee J., Emmonds S., Low C. (2021). Does lower-limb asymmetry increase injury risk in sport? A systematic review. *Phys Ther Sport* 49:204-213. | 10.1016/j.ptsp.2021.03.001 | V |
| `helms2023` | Helms E. R., Spence A. J., Sousa C. et al. (2023). Effect of small and large energy surpluses on strength, muscle, and skinfold thickness in resistance-trained individuals. *Sports Med Open* 9:102. | 10.1186/s40798-023-00651-y | V |
| `huiberts2024` | Huiberts R. O., Wüst R. C. I., van der Zwaard S. (2024). Concurrent strength and endurance training: a systematic review and meta-analysis on the impact of sex and training status. *Sports Med* 54(2):485-503. | 10.1007/s40279-023-01943-9 | V |
| `hunter2016` | Hunter S. K. (2016). The relevance of sex differences in performance fatigability. *Med Sci Sports Exerc* 48(11):2247-2256. | 10.1249/MSS.0000000000000928 | V |
| `impellizzeri2020` | Impellizzeri F. M., Tenan M. S., Kempton T. et al. (2020). Acute:chronic workload ratio: conceptual issues and fundamental pitfalls. *Int J Sports Physiol Perform* 15(6):907-913. | 10.1123/ijspp.2019-0864 | V |
| `ivarsson2017` | Ivarsson A., Johnson U., Andersen M. B. et al. (2017). Psychosocial factors and sport injuries: meta-analyses for prediction and prevention. *Sports Med* 47(2):353-365. | 10.1007/s40279-016-0578-x | V |
| `kaiser2018` | Kaiser S., Engeroff T., Niederer D. et al. (2018). The epidemiological profile of calisthenics athletes. *Dtsch Z Sportmed* 69(9):299-304. | 10.5960/dzsm.2018.342 | V |
| `kardor2023` | Kardor M. et al. (2023). Upper extremity physical performance tests in female overhead athletes: a test-retest reliability study. *J Orthop Surg Res*. | 10.1186/s13018-023-03974-4 | V |
| `knowles2022` | Knowles O. E., Drinkwater E. J., Roberts S. S. H. et al. (2022). Sustained sleep restriction reduces resistance exercise quality and quantity in females. *Med Sci Sports Exerc* 54(12):2167-2177. | 10.1249/MSS.0000000000003000 | V |
| `kompf2017` | Kompf J., Arandjelović O. (2017). The sticking point in the bench press, the squat, and the deadlift: similarities and differences, and their significance for research and practice. *Sports Med* 47(4):631-640. | 10.1007/s40279-016-0615-9 | V |
| `kubo2012` | Kubo K., Ikebukuro T., Maki A. et al. (2012). Time course of changes in the human Achilles tendon properties and metabolism during training and detraining in vivo. *Eur J Appl Physiol* 112:2679-2691. | 10.1007/s00421-011-2248-x | V |
| `latella2020` | Latella C., Teo W.-P., Spathis J., van den Hoek D. (2020). Long-term strength adaptation: a 15-year analysis of powerlifting athletes. *J Strength Cond Res* 34(9):2412-2418. | 10.1519/JSC.0000000000003657 | V |
| `lauersen2018` | Lauersen J. B., Andersen T. E., Andersen L. B. (2018). Strength training as superior, dose-dependent and safe prevention of acute and overuse sports injuries: a systematic review, qualitative analysis and meta-analysis. *Br J Sports Med* 52(24):1557-1563. | 10.1136/bjsports-2018-099078 | V |
| `laursen2007` | Laursen P. B., Francis G. T., Abbiss C. R. et al. (2007). Reliability of time-to-exhaustion versus time-trial running tests in runners. *Med Sci Sports Exerc* 39(8):1374-1379. | 10.1249/mss.0b013e31806010f5 | V |
| `liaghat2021` | Liaghat B., Pedersen J. R., Young J. J. et al. (2021). Joint hypermobility in athletes is associated with shoulder injuries: a systematic review and meta-analysis. *BMC Musculoskelet Disord* 22:389. | 10.1186/s12891-021-04249-x | V |
| `low2016` | Low S. (2016). *Overcoming Gravity*, 2e éd., et article « Prilepin tables for bodyweight strength isometric and eccentric exercises » (stevenlow.org). | — | V comme usage de terrain (article lu ; livre non consulté) |
| `martinezromero2020` | Martínez-Romero M. T. et al. (2020). A meta-analysis of the reliability of four field-based trunk extension endurance tests. *Int J Environ Res Public Health* 17(9):3088. | 10.3390/ijerph17093088 | V |
| `mayhew2008` | Mayhew J. L., Johnson B. D., LaMonte M. J. et al. (2008). Accuracy of prediction equations for determining one repetition maximum bench press in women before and after resistance training. *J Strength Cond Res* 22(5):1570-1577. | 10.1519/JSC.0b013e31817b02ad | V |
| `mayorgavega2016` | Mayorga-Vega D., Bocanegra-Parrilla R., Ornelas M., Viciana J. (2016). Criterion-related validity of the distance- and time-based walk/run field tests for estimating cardiorespiratory fitness: a systematic review and meta-analysis. *PLoS One* 11(3):e0151671. | 10.1371/journal.pone.0151671 | V |
| `mcnulty2020` | McNulty K. L., Elliott-Sale K. J., Dolan E. et al. (2020). The effects of menstrual cycle phase on exercise performance in eumenorrheic women. *Sports Med* 50(10):1813-1827. | 10.1007/s40279-020-01319-3 | V |
| `mitter2022` | Mitter B., Csapo R., Bauer P., Tschan H. (2022). Reproducibility of strength performance and strength-endurance profiles: a test-retest study. *PLoS One* 17(5):e0268074. | 10.1371/journal.pone.0268074 | V |
| `moesgaard2022` | Moesgaard L., Beck M. M., Christiansen L. et al. (2022). Effects of periodization on strength and muscle hypertrophy in volume-equated resistance training programs. *Sports Med* 52(7):1647-1666. | 10.1007/s40279-021-01636-1 | V |
| `morton2018` | Morton R. W., Murphy K. T., McKellar S. R. et al. (2018). A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults. *Br J Sports Med* 52(6):376-384. | 10.1136/bjsports-2017-097608 | P (résumé lu ; DOI non relu) |
| `mountjoy2023` | Mountjoy M., Ackerman K. E., Bailey D. M. et al. (2023). 2023 International Olympic Committee's (IOC) consensus statement on Relative Energy Deficiency in Sport (REDs). *Br J Sports Med* 57(17):1073-1097. | 10.1136/bjsports-2023-106994 | V |
| `murphy2022` | Murphy C., Koehler K. (2022). Energy deficiency impairs resistance training gains in lean mass but not strength: a meta-analysis and meta-regression. *Scand J Med Sci Sports* 32(1):125-137. | 10.1111/sms.14075 | V |
| `ngo2021` | Ngo J. K., Solis-Urra P., Sanchez-Martinez J. (2021). Injury profile among street workout practitioners. *Orthop J Sports Med* 9(6):2325967121990926. | 10.1177/2325967121990926 | V |
| `nolan2024` | Nolan D., McNulty K. L., Manninen M., Egan B. (2024). The effect of hormonal contraceptive use on skeletal muscle hypertrophy, power and strength adaptations to resistance exercise training. *Sports Med* 54(1):105-125. | 10.1007/s40279-023-01911-3 | V |
| `nsca2016` | Haff G. G., Triplett N. T. (dir.) (2016). *Essentials of Strength Training and Conditioning*, 4e éd. NSCA, Human Kinetics. | — | P (protocole de 1RM lu dans un autre ouvrage NSCA qui le reprend) |
| `nuzzo2024` | Nuzzo J. L., Pinto M. D., Nosaka K., Steele J. (2024). Maximal number of repetitions at percentages of the one repetition maximum: a meta-regression and moderator analysis of sex, age, training status, and exercise. *Sports Med* 54(2):303-321. | 10.1007/s40279-023-01937-7 | V |
| `ogasawara2013` | Ogasawara R., Yasuda T., Ishii N., Abe T. (2013). Comparison of muscle hypertrophy following 6-month of continuous and periodic strength training. *Eur J Appl Physiol* 113(4):975-985. | 10.1007/s00421-012-2511-9 | V |
| `ortega2021` | Ortega-Rodríguez R., Feriche B., Almeida F. et al. (2021). Effect of the pronated pull-up grip width on performance and power-force-velocity profile. *Res Q Exerc Sport* 92(4):651-658. | 10.1080/02701367.2020.1762835 | V |
| `pelland2026` | Pelland J. C., Remmert J. F., Robinson Z. P., Hinson S. R., Zourdos M. C. (2026). The resistance training dose response: meta-regressions exploring the effects of weekly volume and frequency on muscle hypertrophy and strength gains. *Sports Med* 56(2):481-505 (en ligne le 04/12/2025 ; prépublication SportRxiv 2024, citée dans `CONTRAT.md`). | 10.1007/s40279-025-02344-w | V |
| `peterson2011` | Peterson M. D., Sen A., Gordon P. M. (2011). Influence of resistance exercise on lean body mass in aging adults: a meta-analysis. *Med Sci Sports Exerc* 43(2):249-258. | 10.1249/MSS.0b013e3181eb6265 | V |
| `petre2021` | Petré H., Hemmingsson E., Rosdahl H., Psilander N. (2021). Development of maximal dynamic strength during concurrent resistance and endurance training in untrained, moderately trained, and trained individuals: a systematic review and meta-analysis. *Sports Med* 51(5):991-1010. | 10.1007/s40279-021-01426-9 | V |
| `ploutzsnyder2001` | Ploutz-Snyder L. L., Giamis E. L. (2001). Orientation and familiarization to 1RM strength testing in old and young women. *J Strength Cond Res* 15(4):519-523. | 10.1519/00124278-200111000-00020 | P (notice ; chiffres lus sur un résumé secondaire) |
| `pollock1991` | Pollock M. L. et al. (1991). Injuries and adherence to walk/jog and resistance training programs in the elderly. *Med Sci Sports Exerc*. | — | V (résumé PEDro ; volume et pages non relevés) |
| `pritchard2016` | Pritchard H. J. et al. (2016). Tapering practices of New Zealand's elite raw powerlifters. *J Strength Cond Res* 30(7):1796-1804. | 10.1519/JSC.0000000000001292 | V |
| `refalo2025` | Refalo M. C., Nuckols G., Galpin A. J. et al. (2025). Sex differences in absolute and relative changes in muscle size following resistance training in healthy adults: a systematic review with Bayesian meta-analysis. *PeerJ* 13:e19042. | 10.7717/peerj.19042 | V |
| `reynolds2006` | Reynolds J. M., Gordon T. J., Robergs R. A. (2006). Prediction of one repetition maximum strength from multiple repetition maximum testing and anthropometry. *J Strength Cond Res* 20(3):584-592. | — (non relu) | V (texte lu ; DOI non relevé) |
| `rhea2003` | Rhea M. R., Alvar B. A., Burkett L. N., Ball S. D. (2003). A meta-analysis to determine the dose response for strength development. *Med Sci Sports Exerc* 35(3):456-464. | 10.1249/01.MSS.0000053727.63505.D4 | V |
| `riebe2015` | Riebe D., Franklin B. A., Thompson P. D. et al. (2015). Updating ACSM's recommendations for exercise preparticipation health screening. *Med Sci Sports Exerc* 47(11):2473-2479. | 10.1249/MSS.0000000000000664 | V |
| `riegel1981` | Riegel P. S. (1981). Athletic records and human endurance. *Am Sci* 69(3):285-290. | — | P (formule et domaine de validité lus sur une source secondaire) |
| `roberts2020` | Roberts B. M., Nuckols G., Krieger J. W. (2020). Sex differences in resistance training: a systematic review and meta-analysis. *J Strength Cond Res* 34(5):1448-1460. | 10.1519/JSC.0000000000003521 | V |
| `rodriguezperea2025` | Rodríguez-Perea Á. et al. (2025). Criterion-related validity and reliability of the front plank test in adults: the ADULT-FIT project. *Appl Sci* 15:2722. | 10.3390/app15052722 | V |
| `roth2022` | Roth C., Schoenfeld B. J., Behringer M. (2022). Lean mass sparing in resistance-trained athletes during caloric restriction: the role of resistance training volume. *Eur J Appl Physiol* 122(5):1129-1151. | 10.1007/s00421-022-04896-5 | P (résumé lu ; auteurs non affichés sur la notice consultée) |
| `ruuska2012` | Ruuska P. S., Hautala A. J., Kiviniemi A. M. et al. (2012). Self-rated mental stress and exercise training response in healthy subjects. *Front Physiol* 3:51. | 10.3389/fphys.2012.00051 | V |
| `sanchezmoreno2017` | Sánchez-Moreno M., Rodríguez-Rosell D., Pareja-Blanco F. et al. (2017). Movement velocity as indicator of relative intensity and level of effort attained during the set in pull-up exercise. *Int J Sports Physiol Perform* 12(10):1378-1384. | 10.1123/ijspp.2016-0791 | V |
| `schumann2022` | Schumann M., Feuerbacher J. F., Sünkeler M. et al. (2022). Compatibility of concurrent aerobic and strength training for skeletal muscle size and function: an updated systematic review and meta-analysis. *Sports Med* 52(3):601-612. | 10.1007/s40279-021-01587-7 | V |
| `seo2012` | Seo D. I. et al. (2012). Reliability of the one-repetition maximum test based on muscle group and gender. *J Sports Sci Med* 11(2):221-225. | — | V |
| `silbernagel2007` | Silbernagel K. G., Thomeé R., Eriksson B. I., Karlsson J. (2007). Continued sports activity, using a pain-monitoring model, during rehabilitation in patients with Achilles tendinopathy: a randomized controlled study. *Am J Sports Med* 35(6):897-906. | 10.1177/0363546506298279 | V |
| `smith2017` | Smith B. E., Hendrick P., Smith T. O. et al. (2017). Should exercises be painful in the management of chronic musculoskeletal pain? A systematic review and meta-analysis. *Br J Sports Med* 51(23):1679-1687. | 10.1136/bjsports-2016-097383 | V |
| `steele2017` | Steele J., Endres A., Fisher J., Gentil P., Giessing J. (2017). Ability to predict repetitions to momentary failure is not perfectly accurate, though improves with resistance training experience. *PeerJ* 5:e4105. | 10.7717/peerj.4105 | V |
| `steele2023` | Steele J., Fisher J. P., Giessing J. et al. (2023). Long-term time-course of strength adaptation to minimal dose resistance training through retrospective longitudinal growth modeling. *Res Q Exerc Sport* 94(4):913-930. | 10.1080/02701367.2022.2070592 | V |
| `stromback2018` | Strömbäck E., Aasa U., Gilenstam K., Berglund L. (2018). Prevalence and consequences of injuries in powerlifting: a cross-sectional study. *Orthop J Sports Med* 6(5):2325967118771016. | 10.1177/2325967118771016 | V |
| `stults2014` | Stults-Kolehmainen M. A., Bartholomew J. B., Sinha R. (2014). Chronic psychological stress impairs recovery of muscular function and somatic sensations over a 96-hour period. *J Strength Cond Res* 28(7):2007-2017. | 10.1519/JSC.0000000000000335 | V |
| `travis2020` | Travis S. K., Mujika I., Gentles J. A., Stone M. H., Bazyler C. D. (2020). Tapering and peaking maximal strength for powerlifting performance: a review. *Sports* 8(9):125. | 10.3390/sports8090125 | V |
| `travis2021` | Travis S. K., Zourdos M. C., Bazyler C. D. (2021). Weight selection attempts of elite classic powerlifters. *Percept Mot Skills* 128(1):507-521. | 10.1177/0031512520967608 | V |
| `vickers2016` | Vickers A. J., Vertosick E. A. (2016). An empirical study of race times in recreational endurance runners. *BMC Sports Sci Med Rehabil* 8:26. | 10.1186/s13102-016-0052-y | V |
| `walsh2021` | Walsh N. P., Halson S. L., Sargent C. et al. (2021). Sleep and the athlete: narrative review and 2021 expert consensus recommendations. *Br J Sports Med* 55(7):356-368. | 10.1136/bjsports-2020-102025 | V |
| `wilson2012` | Wilson J. M., Marin P. J., Rhea M. R. et al. (2012). Concurrent training: a meta-analysis examining interference of aerobic and resistance exercises. *J Strength Cond Res* 26(8):2293-2307. | 10.1519/JSC.0b013e31823a3e2d | V |

Règlements de compétition consultés le 02/10/2026 (pages lues à travers un outil de résumé ; règlements complets non
lus) : Final Rep — https://final-rep.com/weighted/about et https://final-rep.com/rulebook/ ; International
Streetlifting Federation — https://streetlifting.ru/docs/isf-rules/faq (version 5.2) ; World Street Workout &
Calisthenics Federation — https://wswcf.org/competitions/competition-types-and-differences/ ; Calisthenics Cup 2025 —
https://www.gornation.com/blogs/news/calisthenics-cup-2025-endurance-routines. Les compétitions françaises nommées
« Sets and Reps » n'ont pas pu être documentées : leur format est à saisir par l'utilisateur.
