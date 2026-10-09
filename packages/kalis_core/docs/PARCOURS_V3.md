# Parcours de création du profil v3 — pour le lot CU

Fichier généré par `tool/gen_parcours.py` depuis `tool/parcours_spec.py` — ne pas modifier à la main. Données lues par l'application : [`data/parcours_v3.json`](../data/parcours_v3.json) (`ProfileQuestionnaire`, `lib/src/questionnaire.dart`). Pourquoi chaque question existe, à qui elle est posée et ce qui a été écarté : [`PROFIL_V3.md`](PROFIL_V3.md).

## 1. Principe

- Le parcours v3 **reprend l'écran de création du profil du lot G6** (mêmes écrans, mêmes composants, même ton) et y ajoute les questions du schéma 3, **posées seulement à ceux pour qui elles comptent**. Une question = un écran ou un bloc d'écran clair ; Koach présente chaque écran (texte `koach`).
- **Arbre adaptatif** : chaque question porte une condition d'apparition (`when`) évaluée sur le profil en cours de saisie. L'application ne code aucune condition : elle appelle `ProfileQuestionnaire.visibleQuestions(profilJson, todayYear: …)` après chaque réponse. Une réponse absente rend la condition fausse : **sans réponse, on montre le parcours le plus court**.
- **Questions reportées** (`deferWhen`) : une question dont la condition de report est vraie n'est **pas posée à la création** ; l'application la propose après la première semaine (carte discrète de Koach, une fois). `visibleQuestions` ne la rend pas ; `deferredQuestions(profilJson, todayYear: …)` la rend ; `visibleQuestions(…, includeDeferred: true)` rend tout (Réglages › Profil). Un débutant ne voit ainsi à la création **aucune question de récupération** ; des questions du schéma 3, il ne voit que celles que sa discipline rend nécessaires pour écrire son premier programme (§ 2).
- **Obligatoire sous condition** (`requiredWhen`) : `isRequired(question, profilJson, todayYear: …)` dit si la réponse est exigée pour ce profil (le poids de corps pour les disciplines au poids du corps).
- **« Passer »** (`skip`) : le champ reste absent du profil — jamais de valeur par défaut (D5.8). **« Je ne sais pas »** (`unknown`) : même effet, et un test guidé sera proposé (§ 5).
- **Liste vide ≠ champ absent** : `otherSports: []` = « aucun autre sport » ; `events: []` = « aucune échéance » ; champ absent = question non posée ou passée.
- **Santé** : la règle L13 et son questionnaire sont inchangés. Les gênes sont des **contraintes d'entraînement** (zone, côté, gêne perçue, depuis quand, mouvements qui la réveillent), jamais un diagnostic ; elles ne sont écrites qu'avec l'accord santé (G6, KT-042).
- **Valeurs de départ, pas valeurs du jour** : sommeil, stress et charge hors programme du profil sont des habitudes déclarées, qui servent de **valeur de départ** tant que le journal n'en dit pas plus ; la nuit dernière, le stress et les douleurs du jour restent dans le bilan de séance (D5.8-D5.9), qui prime dès qu'il est rempli. Aucun doublon : le bilan de séance n'est pas modifié.
- **Ordre** : les records (`benchmarks`) sont demandés AVANT les fourchettes (`movement_levels`), qui ne portent alors que sur les mouvements sans record ; les points faibles, après les records, sur les mouvements saisis.
- **Remarques des relecteurs** (« débutant pressé », « coach d'élite », relecture du contrat) : chacune est traitée — changée ou expliquée — dans [`RELECTURES_CQ.md`](RELECTURES_CQ.md).

## 2. Nombre de questions vues par profil type

Convention : une question = une entrée de `questions` visible **à la création** (un champ, ou un éditeur de liste compté une fois, quel que soit le nombre d'éléments saisis). Les écrans d'accueil et de récapitulatif ne posent pas de question. « Nouvelles » = questions du schéma 3. « Reportées » = proposées après la première semaine, non comptées. Profils : `test/fixtures/profiles_v3.json` ; les mêmes nombres sont contrôlés par les tests Dart (`test/questionnaire_test.dart`) et Python (`tools/catalog/tests/test_contracts.py`) — CU les revérifie dans l'application.

| Profil type | Questions à la création | dont nouvelles (schéma 3) | Nouvelles questions vues | Reportées |
| --- | ---: | ---: | --- | --- |
| `v3_debutant_forme_generale` — Débutant complet, forme générale, 2 × 30 min à la maison sans matériel ; questions de récupération répondues après la première semaine. | 16 | 0 | — | `sleep`, `stress`, `outside_load` |
| `v3_intermediaire_musculation` — Femme de 34 ans, musculation en salle depuis 3 ans, 4 × 60 min, un footing par semaine. | 27 | 10 | `training_age`, `training_gap`, `benchmarks`, `emphasis`, `events`, `specialization`, `sleep`, `stress`, `outside_load`, `body_weight_goal` | — |
| `v3_competiteur_elite_streetlifting` — Compétiteur élite de streetlifting (catégorie −73 kg), mode street 70/15/15, 5 séances, compétition principale dans 28 semaines. | 29 | 12 | `training_age`, `training_gap`, `benchmarks`, `skills`, `recent_training`, `events`, `specialization`, `weak_points`, `sleep`, `stress`, `outside_load`, `body_weight_goal` | — |
| `v3_coureuse_10km` — Autre discipline : coureuse régulière (cardio 70 %, musculation 20 %, mobilité 10 %), 10 km visé en mars, reprise après deux semaines d'arrêt. | 28 | 11 | `training_age`, `training_gap`, `benchmarks`, `emphasis`, `events`, `specialization`, `running_base`, `sleep`, `stress`, `outside_load`, `body_weight_goal` | — |
| `v3_sets_reps_avance` — Mode street, principale sets & reps (20/60/20), avancé, compétition de répétitions contre la montre, sport de combat deux fois par semaine. | 29 | 12 | `training_age`, `training_gap`, `benchmarks`, `skills`, `recent_training`, `events`, `specialization`, `weak_points`, `sleep`, `stress`, `outside_load`, `body_weight_goal` | — |

Repère : le parcours compte 31 questions en tout — les 17 du schéma 2 (parcours G6, posées alors à tout le monde) et 14 du schéma 3, toutes conditionnelles ou passables. Un profil encore vide voit 16 questions (le parcours le plus court). **Un débutant voit 16 à 18 questions à la création selon sa discipline (tableau ci-dessous) — en forme générale, une de moins qu'avec le parcours G6** (les exercices aimés ou détestés lui sont demandés pendant la revue du programme, D4.5), **sans aucune question de récupération** : celles-ci, à un seul appui chacune, sont reportées après la première semaine. Parcours le plus court possible à information égale : chaque question du schéma 3 retenue change une décision du moteur (ligne « Ce que ça change ») ; celles qui n'en changent aucune sont écartées dans `PROFIL_V3.md`.

**Débutant, selon sa discipline principale** (calculé par ce générateur sur un profil « débutant » dont seule la discipline change) : les seules questions du schéma 3 posées à la création sont celles sans lesquelles le premier programme ne peut pas être écrit — la figure visée, l'orientation en musculation, la course préparée et le volume de course actuel. Toutes sont passables.

| Discipline principale du débutant | Questions à la création | Questions du schéma 3 vues | Reportées |
| --- | ---: | --- | --- |
| Forme générale | 16 | — | `sleep`, `stress`, `outside_load` |
| Mobilité | 16 | — | `sleep`, `stress`, `outside_load` |
| Musculation | 17 | `emphasis` | `sleep`, `stress`, `outside_load` |
| Street workout (sets & reps) | 16 | — | `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| CrossFit | 17 | `skills` | `sleep`, `stress`, `outside_load` |
| Streetlifting | 17 | `skills` | `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| Calisthénie | 17 | `skills` | `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| Cardio | 18 | `events`, `running_base` | `sleep`, `stress`, `outside_load` |

## 3. Écrans et questions, dans l'ordre

### Écran `accueil` — Bienvenue

Koach : « Salut ! Quelques minutes de questions et je te prépare un programme à ta mesure. »

Accueil de Koach et avertissement santé L13 (inchangés).

### Écran `toi` — Toi

Koach : « On commence par toi. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `display_name` | Comment je t'appelle ? | texte ; « Passer » | `displayName` | tous | non | 2 |
| `sex` | Tu es… | un choix | `sex` | tous | oui | 2 |
| `birth_year` | Ton année de naissance ? | nombre | `birthYear` | tous | oui | 2 |
| `height` | Ta taille, en cm ? | nombre | `heightCm` | tous | oui | 2 |
| `body_weight` | Ton poids, en kg ? | nombre ; « Passer » | `bodyWeightKg` | tous | si `streetMode` renseigné OU (`disciplines.primary` ∈ {streetlifting, street_workout, calisthenics} OU `disciplines.secondaries[*].discipline` ∈ {streetlifting, street_workout, calisthenics}) | 2 |

**`display_name`**

- Validation : 40 caractères au plus.

**`sex`**

- Koach : « Ça ne change pas ton programme : ça sert aux repères de classement et aux catégories de compétition. »
- Réponses : Une femme → `female` · Un homme → `male` · Je préfère ne pas le dire → `undisclosed`
- Ce que ça change : Aucun effet sur le programme (mêmes volumes relatifs) ; sert aux repères de rang et aux catégories de compétition. « Je préfère ne pas le dire » : l'éditeur d'échéance propose les catégories des deux listes.
- Justification : `PROFIL_V3.md`, facteur `sexe`.

**`birth_year`**

- Koach : « Il faut avoir 18 ans. Ton âge me sert aussi à rester prudent sur les tests. »
- Validation : 18 ans et plus (règle L13).
- Ce que ça change : Prudence des tests (pas de maximum direct après 65 ans sans expérience) ; attentes de progression.
- Justification : `PROFIL_V3.md`, facteur `age`.

**`height`**

- Validation : 100 à 250 cm.
- Ce que ça change : Aucun effet sur le programme ; champ obligatoire du schéma 2, gardé.
- Justification : `PROFIL_V3.md`, facteur `taille`.

**`body_weight`**

- Koach : « Aux pompes ou aux tractions, c'est ton propre poids que tu soulèves. Si je le connais, je dose mieux. Personne d'autre ne le voit. »
- Validation : 25 à 300 kg.
- Ce que ça change : Charge totale des exercices au poids du corps ou lestés, force relative, catégories de poids.
- Note : Obligatoire en mode street, en streetlifting, en street workout et en calisthénie (`requiredWhen`) : sans lui, ni charge totale, ni pourcentage, ni test lesté. Passable ailleurs, avec un bouton « Passer » aussi visible que « Valider ».
- Justification : `PROFIL_V3.md`, facteur `poids_de_corps`.

### Écran `discipline` — Ta discipline

Koach : « Qu'est-ce qui te fait envie ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `discipline` | Tu veux faire quoi, surtout ? | éditeur de liste | `disciplines.primary`, `streetMode` | tous | oui | 2 |

**`discipline`**

- Note : 8 disciplines (D3.1) ou mode street : principale parmi streetlifting, sets & reps, calisthénie (D3.3). Une ligne d'explication en mots courants sous chaque choix (« Calisthénie : des exercices avec le poids de ton corps », « Musculation : des charges, en salle ou à la maison »…). Le mode street est rangé à part, sous « Je pratique déjà le street workout ». Dernier choix : « Je ne sais pas, choisis pour moi », qui sélectionne la forme générale (`general_fitness`) — une réponse est bien écrite, modifiable ensuite.

### Écran `dosage` — Le reste du programme

Koach : « Choisis une ou deux autres activités à ajouter, et la place que tu leur donnes. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `secondaries` | Une ou deux disciplines en plus, et leur dosage | éditeur de liste | `disciplines.secondaries`, `disciplines.primaryPct` | tous | oui | 2 |

**`secondaries`**

- Note : 1 à 2 secondaires, somme 100 % (D3.2) ; en mode street, le dosage des deux autres styles.

### Écran `experience` — Ton expérience

Koach : « Dis-moi d'où tu pars : je règle la difficulté dessus. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `experience_level` | Globalement, tu te situes où ? | un choix ; « Passer » | `experience` | tous | non | 2 |
| `training_age` | Depuis combien de temps tu pratiques régulièrement ta discipline principale ? | un choix ; « Passer » | `trainingAge` | `experience` ≥ intermediate | non | 3 |
| `training_gap` | En ce moment, tu t'entraînes ? | un choix ; « Passer » | `trainingGap` | `trainingAge` ≥ months_6_to_24 | non | 3 |

**`experience_level`**

- Réponses : Débutant (Je découvre, ou presque) → `beginner` · Intermédiaire (Je connais les mouvements de base et je me suis entraîné régulièrement, même si j'ai arrêté un moment) → `intermediate` · Avancé (Je progresse lentement, je sais ce qui marche pour moi) → `advanced` · Élite (Je fais de la compétition au niveau national ou au-dessus) → `elite`
- Ce que ça change : Ouvre les questions avancées (tests, compétition, points faibles) et borne les techniques servies.
- Note : Un ancien pratiquant qui reprend après un long arrêt ne se dit pas débutant : il choisit son niveau d'avant, et la question `training_gap` dit depuis quand il a arrêté (ses tendons, eux, repartent de plus bas). Passée : le parcours reste celui d'un débutant (le plus court). Le moteur recale ensuite le niveau sur les performances (force rapportée au poids de corps) : le dire au récapitulatif.
- Justification : `PROFIL_V3.md`, facteur `anciennete`.

**`training_age`**

- Koach : « Ne compte pas les périodes où tu as arrêté plusieurs mois. »
- Réponses : Moins de 6 mois → `under_6_months` · 6 mois à 2 ans → `months_6_to_24` · 2 à 5 ans → `years_2_to_5` · Plus de 5 ans → `over_5_years`
- Ce que ça change : Volume et intensité de départ, vitesse de progression attendue, besoin de périodisation, prérequis des techniques avancées et des figures en bras tendus.
- Note : L'ancienneté est celle de la discipline principale (un haltérophile qui commence la planche est récent en bras tendus). Non posée à un débutant : « je découvre » le dit déjà.
- Justification : `PROFIL_V3.md`, facteur `anciennete`.

**`training_gap`**

- Réponses : Oui, régulièrement → `none` · Oui, mais en allégé depuis quelques semaines → `reduced` · J'ai arrêté depuis moins de 3 semaines → `under_3_weeks` · J'ai arrêté depuis 3 à 10 semaines → `weeks_3_to_10` · J'ai arrêté depuis 10 semaines à 6 mois → `weeks_10_to_26` · J'ai arrêté depuis 6 mois à 2 ans → `months_6_to_24` · J'ai arrêté depuis plus de 2 ans → `over_2_years`
- Ce que ça change : Reprise progressive après un arrêt de plus de 3 semaines, d'autant plus longue que l'arrêt l'a été ; figures à forte contrainte tendineuse reprises une étape en dessous après un mois d'arrêt.
- Note : Posée une fois, à la création ; ensuite les coupures se lisent dans le journal (`TrainingLog.breaks`, dates des séances).
- Justification : `PROFIL_V3.md`, facteur `interruption`.

### Écran `niveaux` — Ce que tu sais faire

Koach : « Donne-moi une idée, même vague. Si tu ne sais pas, pas d'examen : on verra tranquillement pendant tes premières séances. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `benchmarks` | Tes meilleures performances récentes | éditeur de liste ; « Passer », « Je ne sais pas » | `benchmarks` | `experience` ≥ intermediate | non | 3 |
| `movement_levels` | Ce que tu fais aujourd'hui sur quelques mouvements | éditeur de liste ; « Je ne sais pas » | `movementLevels` | tous | non | 2 |
| `skills` | Les figures que tu travailles | éditeur de liste ; « Passer » | `skills` | (`disciplines.primary` ∈ {calisthenics, streetlifting, crossfit} OU `disciplines.secondaries[*].discipline` ∈ {calisthenics, streetlifting, crossfit}) OU `streetMode.calisthenicsPct` ≥ 1 | non | 3 |
| `recent_training` | En ce moment, tu fais quoi ? | éditeur de liste ; « Passer » | `recentTraining`, `currentPhase` | `experience` ≥ advanced | non | 3 |

**`benchmarks`**

- Koach : « Un chiffre exact et récent (3 derniers mois de préférence) vaut mieux qu'une fourchette : je calcule tes charges dessus. Sinon, on fera un test ensemble. »
- Ce que ça change : Charges en part du maximum dès le premier bloc, choix des tentatives, séries de test seulement là où il manque une valeur.
- Note : Placée AVANT les fourchettes : les fourchettes (`movement_levels`) ne sont ensuite demandées que pour les mouvements sans record. « Je ne sais pas » : aucun record n'est écrit ; les tests guidés sont proposés (§ tests guidés). Liste vide = aucun record connu. Une barre unique « avec de la réserve » sert aux charges d'entraînement, pas au choix des tentatives.
- Justification : `PROFIL_V3.md`, facteur `tests_records`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `exerciseId` | Quel mouvement ? | exercise | oui | Proposés d'abord : mouvements de compétition de la discipline, puis ses mouvements principaux ; quand le cardio est la discipline principale, la course d'abord (record en `time_trial`). |
  | `kind` | Quel genre de record ? | choice | oui | Une charge soulevée (1 répétition ou plus) → `load_reps` · Un maximum de répétitions → `max_reps` · Un maintien le plus long possible → `max_hold` · Un temps sur une distance → `time_trial` · Une distance en un temps donné → `distance_trial` · Un volume imposé, le plus vite possible → `reps_for_time` |
  | `externalLoadKg` | Quelle charge ? (le lest seul pour un exercice lesté) | number | oui | — |
  | `reps` | Combien de répétitions ? | number | oui | — |
  | `rir` | Il t'en restait combien sous le pied ? | choice | non | Aucune, c'était mon maximum → `0` · 1 → `1` · 2 → `2` · 3 ou plus → `3` — Seulement pour une charge soulevée ; passée : réserve inconnue (absente). |
  | `seconds` | Combien de temps ? | duration | oui | — |
  | `distanceMeters` | Quelle distance ? | number | oui | — |
  | `date` | C'était quand ? | date | non | Raccourcis de saisie : « ce mois-ci », « il y a 1 à 3 mois », ou une date. Sans date, ou à plus de 6 mois : le record est gardé, mais le moteur le reteste avant de s'y fier. Aucune date n'est inventée : un record plus ancien se saisit avec son mois. |
  | `source` | D'où vient ce chiffre ? | choice | oui | Je l'ai fait à l'entraînement → `declared` · En compétition → `competition` |
  | `bodyWeightKg` | Ton poids ce jour-là ? | number | non | Seulement pour un exercice au poids du corps ou lesté ; pré-rempli avec le poids du profil, à confirmer. |
  | `competitionStandard` | C'était au standard de compétition (amplitude complète, arrêts marqués) ? | choice | non | Oui → `true` · Non → `false` — Seulement en streetlifting ou si une compétition de force est déclarée ; « Je ne sais pas » laisse le champ absent. Les tentatives ne se fondent que sur des records au standard. |

**`movement_levels`**

- Note : Fourchettes par mouvement (D3.5). Un seul bouton « Je ne sais pas, on verra ensemble » pour tout l'écran, en haut. Débutant : 4 mouvements au plus ; sinon 9 au plus, choisis selon les disciplines, sans ceux qui ont déjà un record.

**`skills`**

- Koach : « Montre-moi où tu en es sur chaque figure : je reprends juste après. »
- Ce que ça change : Étape de départ de chaque progression, durées de maintien prescrites, critère de passage à l'étape suivante.
- Note : L'ordre de la liste est l'ordre de priorité (« fais glisser la plus importante en haut »). Étapes proposées : `Catalog.progressionCandidates` (variantes de la figure dans l'ordre de la base, puis la figure). Posée aussi en streetlifting et en CrossFit (muscle-up, équilibre, L-sit proposés d'abord).
- Justification : `PROFIL_V3.md`, facteur `figures`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `targetExerciseId` | Quelle figure vises-tu ? | exercise | oui | Figures du catalogue qui ont une chaîne `variante_de` (front lever, planche, équilibre, back lever, L-sit, muscle-up, drapeau…). |
  | `currentExerciseId` | Où en es-tu ? | exercise | oui | Choix parmi les étapes de la chaîne `variante_de` de la figure, dans l'ordre de la base, puis la figure elle-même. |
  | `bestHoldSeconds` | Ton meilleur maintien propre sur cette étape ? | duration | non | — |
  | `bestReps` | Ou ton meilleur nombre de répétitions propres ? | number | non | — |
  | `atStepSince` | Depuis quand tu en es là ? | choice | non | Moins d'un mois → `under_1_month` · 1 à 3 mois → `months_1_to_3` · 3 à 6 mois → `months_3_to_6` · Plus de 6 mois → `over_6_months` — Évite de te faire repartir de zéro sur une étape que tu tiens depuis longtemps ; plus de 6 mois : la méthode change. |

**`recent_training`**

- Koach : « Je cale ton premier bloc sur ce que tu fais vraiment aujourd'hui : ni semaine trop facile, ni marche trop haute. »
- Ce que ça change : Volume et fréquence du premier bloc par mouvement (ni décharge involontaire, ni saut de charge) ; exposition actuelle des coudes et des épaules aux bras tendus.
- Note : « 4 ou plus » écrit 4. Ces réponses datent : elles portent `lifestyleUpdatedOn`, et le journal les remplace dès les premières semaines. Dernière question de l'écran, après les records et les figures, pour que ses lignes soient pré-remplies avec eux.
- Justification : `PROFIL_V3.md`, facteur `charge_actuelle`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `exerciseId` | Mouvement ou figure | exercise | oui | 3 à 4 lignes pré-remplies : mouvements des records saisis (`benchmarks`), mouvements de compétition ou principaux de la discipline, figures saisies juste avant (`skills`). |
  | `sessionsPerWeek` | Combien de fois par semaine tu le travailles ? | choice | oui | Pas en ce moment → `0` · 1 → `1` · 2 → `2` · 3 → `3` · 4 ou plus → `4` |
  | `hardSets` | Combien de séries dures par semaine (à 3 répétitions ou moins de l'échec) ? | choice | non | Moins de 5 → `under_5` · 5 à 9 → `sets_5_to_9` · 10 à 14 → `sets_10_to_14` · 15 à 20 → `sets_15_to_20` · Plus de 20 → `over_20` |
  | `currentPhase` | En ce moment, tu es plutôt… | choice | non | En volume → `volume` · En lourd → `heavy` · Je sors d'un pic ou d'une compétition → `post_peak` · Sans structure → `unstructured` — Une seule fois pour tout l'écran : écrit `currentPhase`. |

### Écran `objectifs` — Tes objectifs

Koach : « Où veux-tu aller ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `goals` | Tes objectifs | éditeur de liste | `goals` | tous | non | 2 |
| `emphasis` | En musculation, tu cherches surtout… | un choix ; « Passer » | `emphasis` | `disciplines.primary` ∈ {musculation} OU `disciplines.secondaries[*].discipline` ∈ {musculation} | non | 3 |
| `events` | Une date en vue (compétition, course, test) ? | éditeur de liste ; « Passer » | `events` | `experience` ≥ intermediate OU `goals[*].kind` ∈ {performance} OU (`disciplines.primary` ∈ {cardio} OU `disciplines.secondaries[*].discipline` ∈ {cardio}) | non | 3 |
| `specialization` | Un mouvement, une figure ou un muscle à faire passer avant tout ? | éditeur de liste ; « Passer » | `specialization` | `experience` ≥ advanced OU (`experience` ≥ intermediate ET (`disciplines.primary` ∈ {musculation} OU `disciplines.secondaries[*].discipline` ∈ {musculation})) | non | 3 |
| `weak_points` | Sur tes mouvements principaux, où est-ce que ça bloque ? | éditeur de liste ; « Passer » | `weakPoints` | `experience` ≥ advanced ET (`disciplines.primary` ∈ {streetlifting, street_workout, calisthenics, musculation, crossfit} OU `disciplines.secondaries[*].discipline` ∈ {streetlifting, street_workout, calisthenics, musculation, crossfit}) | non | 3 |
| `running_base` | Ces 4 dernières semaines, tu cours combien ? | éditeur de liste ; « Passer » | `enduranceBase` | (`disciplines.primary` ∈ {cardio} OU `disciplines.secondaries[*].discipline` ∈ {cardio}) OU `events[*].kind` ∈ {race} | non | 3 |

**`goals`**

- Note : « Laisse Koach proposer » (D3.8) en premier, présélectionné pour un débutant : l'écran se valide en un appui. Puis « M'entraîner régulièrement » (habitude) et « J'ai un chiffre en tête (ex. 10 pompes) » (performance chiffrée datée). Le premier objectif est le principal.

**`emphasis`**

- Réponses : Du muscle → `muscle` · De la force → `strength` · Les deux → `both`
- Ce que ça change : Plages de répétitions, proximité de l'échec et répartition du volume des séances de musculation.
- Note : Un objectif du profil est une performance chiffrée ou une habitude : « prendre du muscle » se dit ici. À partir du niveau intermédiaire, la question suivante (`specialization`) permet de nommer une zone à développer en priorité.
- Justification : `PROFIL_V3.md`, facteur `orientation`.

**`events`**

- Koach : « Si tu as une date, je construis toute ta saison pour que tu arrives en forme ce jour-là. »
- Ce que ça change : Plan de saison (phases, affûtage, pic de forme), travail spécifique des épreuves, tentatives le jour J.
- Note : Réponse « Non » : liste vide (aucune échéance). Passée : champ absent. Plusieurs échéances possibles ; une seule `main` conseillée par saison.
- Justification : `PROFIL_V3.md`, facteur `competition`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `kind` | C'est quoi ? | choice | oui | Compétition de force (streetlifting : une répétition, la plus lourde) → `strength_competition` · Compétition de répétitions (sets & reps, endurance) → `reps_competition` · Compétition de freestyle (figures jugées) → `freestyle_competition` · Une course → `race` · Une autre compétition → `other_competition` · Un test perso à une date précise → `personal_test` |
  | `date` | Quel jour ? | date | oui | Date pas encore fixée : choisir un mois, `dateApproximate: true` et le 15 du mois. |
  | `priority` | Elle compte comment ? | choice | oui | C'est mon objectif principal → `main` · Importante, mais pas la principale → `secondary` · Juste pour m'entraîner à la compétition → `preparation` |
  | `name` | Son nom ? | text | non | — |
  | `ruleset` | Quel règlement ? | choice | non | Préréglages de `rulesetPresets` (ils pré-remplissent mouvements, tentatives et sauts de charge) ou « Autre » ; tout reste modifiable. |
  | `weightClassKg` | Ta catégorie de poids ? | number | non | Compétition de force ; « plus de … » coche `openWeightClass`. Les préréglages listent les catégories des deux sexes quand le sexe n'est pas renseigné. |
  | `plannedBodyWeightKg` | Tu comptes peser combien ce jour-là ? | number | non | Compétition à catégories de poids (force, répétitions lestées) ; pré-rempli avec le poids du profil. Aucune question sur la méthode. |
  | `lifts` | Les mouvements, dans l'ordre | list | oui | Compétition de force : mouvement, tentatives (3 par défaut), meilleure barre, barre visée. |
  | `mode` | Le format | choice | oui | Le plus de répétitions → `max_reps` · Le plus de répétitions en un temps → `max_reps_in_time` · Un volume imposé, le plus vite possible → `for_time` · Le maintien le plus long → `max_hold` — Compétition de répétitions. |
  | `stations` | Les exercices, dans l'ordre | list | non | Compétition de répétitions : exercice, répétitions ou durée imposées, lest, série indivisible, limite de temps et repos imposé du poste. « Le format sera annoncé le jour même » : `formatKnown: false`, aucune liste (préparation générale). |
  | `heats` | Combien de passages dans la journée ? | number | non | Tableau à élimination, manches ; avec le repos attendu entre deux passages (`restBetweenHeatsSeconds`). |
  | `bestSeconds|bestTotalReps` | Tu l'as déjà fait ? Ton meilleur résultat | duration | non | Épreuve de répétitions, test perso, course : meilleur temps ou meilleur total de répétitions, et sa date (`bestDate`). |
  | `distanceMeters` | Quelle distance ? | number | oui | Course. |
  | `targetSeconds` | Ton temps visé ? | duration | non | — |
  | `elements` | Les figures que tu veux présenter | list | non | Freestyle. |

**`specialization`**

- Koach : « Je peux lui donner la priorité pendant quelques semaines et entretenir le reste. »
- Ce que ça change : Cycle de spécialisation : volume et fréquence concentrés sur la cible, reste entretenu à dose réduite.
- Note : Une seule cible. S'il existe une échéance principale, la question devient « Lequel de tes mouvements de compétition est le plus en retard ? », le reste est forcément entretenu (`maintain`) et la priorité n'est servie que loin de l'échéance (phase d'accumulation) : le plan de saison prime. En musculation, dès le niveau intermédiaire, elle se présente comme « Une zone à développer en priorité ? » (groupe musculaire).
- Justification : `PROFIL_V3.md`, facteur `specialisation`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `kind` | Quoi ? | choice | oui | Un mouvement → `exercise` · Une figure → `skill` · Un groupe musculaire → `muscle` · Un type de mouvement (tirage, poussée…) → `pattern` |
  | `exerciseId|muscle|pattern` | Lequel ? | exercise | oui | — |
  | `weeks` | Pendant combien de temps ? | choice | non | 4 semaines → `4` · 8 semaines → `8` · 12 semaines → `12` — Passée : au moteur de la fixer. |
  | `maintenance` | Et le reste ? | choice | non | Je l'entretiens → `maintain` · Le strict minimum → `minimal` · En pause → `pause` |

**`weak_points`**

- Koach : « Par exemple : « je bloque en bas du dips », « je cale à la transition du muscle-up ». »
- Ce que ça change : Choix des exercices d'assistance (pauses, partiels, isométrie à l'angle faible). Usage d'entraîneur : aucun effet démontré sur la progression.
- Note : Posée après les records, sur les mouvements saisis. Les réponses sont filtrées et libellées par mouvement (traction : « au départ, bras tendus », « à mi-hauteur », « en haut, le menton ne passe pas », « la prise lâche » ; muscle-up : « tirage pas assez haut », « transition », « sortie en dips ») ; les codes ne changent pas. Une douleur n'est pas un point faible : elle se déclare à l'écran Santé.
- Justification : `PROFIL_V3.md`, facteur `points_faibles`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `exerciseId` | Quel mouvement ? | exercise | oui | — |
  | `kind` | Où ça bloque ? | choice | oui | En bas → `bottom` · Au milieu → `mid_range` · En fin de mouvement → `lockout` · Au départ arrêté → `dead_start` · À la transition → `transition` · La prise lâche → `grip` · Je m'écroule en fin de série → `late_set_fatigue` · L'équilibre → `balance` · La souplesse → `mobility` · Je manque de vitesse → `speed` |

**`running_base`**

- Ce que ça change : Distance hebdomadaire et sortie longue du premier bloc de course : on repart de ce qui est fait, pas de ce qui est possible.
- Justification : `PROFIL_V3.md`, facteur `base_endurance`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `weeklyVolume` | Par semaine, en tout | choice | oui | Je ne cours pas encore → `none` · Moins de 10 km → `under_10_km` · 10 à 20 km → `km_10_to_20` · 20 à 35 km → `km_20_to_35` · 35 à 50 km → `km_35_to_50` · Plus de 50 km → `over_50_km` |
  | `sessionsPerWeek` | Combien de sorties par semaine ? | choice | oui | Aucune → `0` · 1 → `1` · 2 → `2` · 3 → `3` · 4 ou plus → `4` |
  | `longRun` | Ta plus longue sortie récente ? | choice | non | Moins de 30 min → `under_30_min` · 30 à 60 min → `min_30_to_60` · 60 à 90 min → `min_60_to_90` · Plus de 90 min → `over_90_min` |

### Écran `disponibilites` — Tes disponibilités

Koach : « Quels jours, et combien de temps ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `availability` | Tes jours et ta durée par jour | éditeur de liste | `availability` | tous | oui | 2 |

**`availability`**

- Note : Jours précis + durée par jour (D3.6).

### Écran `lieux` — Lieux et matériel

Koach : « Où t'entraînes-tu, et avec quoi ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `places` | Où t'entraînes-tu ? | plusieurs choix | `places` | tous | oui | 2 |
| `equipment` | Ton matériel | éditeur de liste | `equipment`, `equipmentByPlace` | tous | oui | 2 |

**`places`**

- Réponses : En salle → `salle` · À la maison → `maison` · Dehors → `exterieur`

**`equipment`**

- Note : Vocabulaire de la base, regroupé, préréglages, matériel par lieu (G6). Premier bouton : « Rien du tout », qui valide l'écran en un appui (liste vide).

### Écran `recuperation` — Ta récupération — **nouvel écran**

Koach : « Ton corps récupère aussi en dehors des séances. Quelques questions rapides. »

Nouvel écran (schéma 3). Les trois premières questions tiennent sur un écran ; chacune a « Passer ». Pour un débutant, cet écran n'est pas montré à la création : ses questions (les quatre portent `deferWhen`) sont proposées après la première semaine.

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `sleep` | En général, tu dors combien par nuit ? | un choix ; « Passer » | `sleep` | tous | non | 3 |
| `stress` | En ce moment, tu es stressé ? | un choix ; « Passer » | `stress` | tous | non | 3 |
| `outside_load` | Tes journées, c'est plutôt… | plusieurs choix + éditeur ; « Passer » | `occupationalLoad`, `otherSports` | tous | non | 3 |
| `body_weight_goal` | Ton poids, en ce moment, tu veux… | un choix ; « Passer » | `bodyWeightGoal`, `targetBodyWeightKg` | `experience` ≥ intermediate OU (`streetMode` renseigné OU (`disciplines.primary` ∈ {streetlifting, street_workout, calisthenics} OU `disciplines.secondaries[*].discipline` ∈ {streetlifting, street_workout, calisthenics})) | non | 3 |

**`sleep`**

- Koach : « Si tu dors peu, je dose plus doucement. »
- Réponses : Moins de 6 h → `under_6_hours` · Entre 6 et 7 h → `hours_6_to_7` · Plus de 7 h → `hours_7_plus`
- Reportée après la première semaine si : pas (`experience` ≥ intermediate).
- Ce que ça change : Moins de 6 h : volume proche de l'échec et cardio intense dosés avec prudence, jamais de baisse de charge ; aucune promesse sur les blessures.
- Note : Valeur HABITUELLE, qui sert de valeur de départ. La nuit dernière se dit dans le bilan de séance (D5.8) : pas de doublon. « Plus de 7 h » comprend 7 h juste.
- Justification : `PROFIL_V3.md`, facteur `sommeil`.

**`stress`**

- Koach : « Si tu es très stressé, j'espace un peu plus les séances dures. »
- Réponses : Pas vraiment → `low` · Un peu → `moderate` · Beaucoup → `high`
- Reportée après la première semaine si : pas (`experience` ≥ intermediate).
- Ce que ça change : Stress élevé : séances lourdes d'un même groupe plus espacées, pas de hausse de volume, décharge avancée.
- Note : Valeur des dernières semaines ; redemandée de temps en temps (`lifestyleUpdatedOn`). Le stress du jour reste dans le bilan de séance.
- Justification : `PROFIL_V3.md`, facteur `stress`.

**`outside_load`**

- Réponses : Surtout assis → `seated` · Debout ou en mouvement (ou un peu des deux) → `on_feet` · Physiques : je porte, je soulève → `heavy` · Et je fais déjà un autre sport, en dehors de ce programme → `other_sport`
- Reportée après la première semaine si : pas (`experience` ≥ intermediate).
- Ce que ça change : Autre sport : séances lourdes des mêmes muscles placées à distance (au moins un jour) ; métier physique : départ prudent (choix raisonné, sans preuve directe).
- Note : Une seule question : l'une des trois premières réponses (exclusives entre elles) écrit `occupationalLoad` ; la quatrième s'y ajoute et ouvre sur place l'éditeur d'`otherSports` ; sans elle, `otherSports` est écrit vide (aucun). Les codes des réponses ne sont pas des codes du contrat, sauf les trois premiers. Passée : les deux champs restent absents. « Autre sport » n'est pas une discipline du programme : c'est ce que tu fais déjà ailleurs.
- Justification : `PROFIL_V3.md`, facteur `charge_hors_programme`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `kind` | Quel sport ? | choice | oui | Course à pied → `running` · Vélo → `cycling` · Natation → `swimming` · Autre sport d'endurance → `other_endurance` · Sport collectif → `team_sport` · Sport de combat → `combat_sport` · Escalade → `climbing` · Sport de raquette → `racket_sport` · Autre sport de force → `other_strength` · Autre → `other` |
  | `sessionsPerWeek` | Combien de fois par semaine ? | number | oui | — |
  | `minutesPerSession` | Combien de temps à chaque fois ? | duration | oui | — |
  | `weekdays` | Toujours les mêmes jours ? | multi | non | — |
  | `hard` | C'est intense (matchs, combats, fractionné) ? | choice | non | Oui → `true` · Non → `false` |
  | `mainSport` | C'est ton sport principal ? | choice | non | Oui → `true` · Non → `false` — Si oui : pas de séance lourde des régions concernées la veille de ce sport. |
  | `regions` | Ça fait surtout travailler… | multi | non | Les jambes → `lower_body` · Le tirage (dos, bras) → `upper_pull` · La poussée (épaules, pectoraux) → `upper_push` · Le tronc → `trunk` · Tout le corps → `whole_body` — Pour tous les sports sauf course, vélo, natation et escalade (régions connues) ; sport de combat pré-coché « tout le corps », corrigeable. |

**`body_weight_goal`**

- Réponses : Le faire baisser → `lose` · Le garder → `maintain` · Le faire monter → `gain` · Je n'y pense pas → `no_goal`
- Reportée après la première semaine si : pas (`experience` ≥ intermediate).
- Ce que ça change : En perte de poids : attentes réglées (la force peut monter, pas le muscle), volume gardé, tests moins fréquents ; lest et charge totale recalculés quand le poids change.
- Note : « Baisser » ou « monter » propose « Jusqu'à combien ? » (`targetBodyWeightKg`, facultatif). Aucun conseil alimentaire n'est donné. Le rythme réel se lit dans les pesées. Pour un débutant d'une discipline au poids du corps, la question est reportée après la première semaine, avec les trois autres de l'écran (`deferWhen`) : son premier bloc, prudent par construction, n'en dépend pas.
- Justification : `PROFIL_V3.md`, facteur `bilan_energetique`.

### Écran `sante` — Ta santé

Koach : « Parlons de ta santé : ce que tu me dis ici me sert à te protéger. »

Questionnaire santé L13 inchangé ; les gênes sont des contraintes d'entraînement, jamais un diagnostic.

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `health_screening` | Questionnaire santé | éditeur de liste | `healthScreening` | tous | oui | 2 |
| `limitations` | Tu as mal quelque part, ou une ancienne blessure ? | éditeur de liste | `limitations` | tous | non | 2 |

**`health_screening`**

- Note : Questionnaire L13 inchangé ; seule sa référence est dans le profil (aucune réponse copiée). Koach annonce sa taille avant de commencer (le nombre de questions oui / non du questionnaire du lot G6) : c'est un questionnaire entier, compté ici pour une question.

**`limitations`**

- Koach : « Une ancienne blessure, une articulation sensible : dis-moi ce qui la réveille, je la protège. Je ne pose aucun diagnostic. »
- Ce que ça change : Mouvements qui chargent la zone : départ une variante en dessous, progression plus lente, pas de test maximal tant que la gêne est d'au moins 4/10.
- Note : Premier bouton : « Non, rien », en un appui. Côté : « les deux / au milieu » pour le dos. La carte du corps n'a ni bras ni avant-bras (énumération d'avant 0.4.0, fermée) : libeller « Coude / avant-bras » et « Épaule / bras ». Donnée de santé : écrite seulement avec l'accord santé (G6, KT-042). Une gêne de plus de 5/10, une douleur la nuit, une perte de force ou une aggravation sur deux semaines : Koach oriente vers un professionnel de santé, sans interpréter (règle L13).
- Justification : `PROFIL_V3.md`, facteur `antecedents`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `zone` | Quelle zone ? | body_map | oui | — |
  | `side` | Quel côté ? | choice | oui | — |
  | `discomfort` | La gêne en ce moment, de 0 à 10 ? | slider | oui | « C'est ancien, je ne sens plus rien » écrit 0 sans montrer le curseur. |
  | `effortDiscomfort` | Quand elle se réveille pendant l'effort, elle monte à combien ? | slider | non | Schéma 3. Une tendinopathie est à 0 au repos et à 6 sous charge : c'est cette valeur qui décide des tests maximaux. |
  | `since` | Depuis quand ? | choice | non | Moins de 6 semaines → `under_6_weeks` · 6 semaines à 3 mois → `weeks_6_to_12` · 3 mois à 1 an → `months_3_to_12` · Plus d'un an → `over_12_months` · C'est ancien, je ne sens plus rien → `past_resolved` — Schéma 3. |
  | `aggravatedBy` | Qu'est-ce qui la réveille ? | multi | non | Tirer vers moi en pliant les bras (tractions) → `pull_bent_arm` · Rester suspendu, bras tendus → `hang_straight_arm` · Pousser (pompes, haut du dips) → `push_support` · M'appuyer sur les mains, bras tendus (équilibre, planche) → `straight_arm_support` · Lever les bras au-dessus de la tête → `overhead` · M'accroupir, plier les genoux → `knee_flexion` · Me pencher en avant avec une charge → `hip_hinge` · Serrer fort, ou le poignet plié vers l'arrière → `wrist_extension_grip` · Les anneaux → `rings` · Courir ou sauter → `running_jumping` · Le bas du dips, la transition du muscle-up, le back lever → `deep_shoulder_extension` · Une barre lourde sur le dos → `axial_loading` · Tendre le coude à fond sous charge → `elbow_lockout` · Tirer fort et vite → `explosive_pull` — Schéma 3. « Je ne sais pas » laisse le champ absent. Un débutant ne voit que les six premières réponses et « Courir ou sauter ». |

### Écran `preferences` — Tes préférences

Koach : « Des exercices que tu adores, ou pas du tout ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `preferences` | Exercices aimés, exercices détestés | éditeur de liste ; « Passer » | `likedExerciseIds`, `dislikedExerciseIds` | `experience` ≥ intermediate | non | 2 |

**`preferences`**

- Note : Schéma 3 : masquée pour un débutant, qui dira « je n'aime pas » pendant la revue du programme (D4.5) ; toujours accessible dans Réglages › Profil. Un exercice aimé ne déplace jamais un mouvement de compétition ni son travail d'assistance (règle pour les moteurs, `PROFIL_V3.md` § 6).

### Écran `mode` — Assisté ou libre

Koach : « Si une séance se passe mal ou trop bien, j'adapte la suite. Tu préfères que je le fasse tout seul, ou que je te demande ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `guidance_mode` | Quand ton programme doit bouger, on fait comment ? | un choix | `guidanceMode` | tous | oui | 2 |

**`guidance_mode`**

- Réponses : Assisté : Koach change ton programme tout seul et te dit pourquoi → `assisted` · Libre : Koach te propose le changement, c'est toi qui décides → `free`
- Note : Décision D3.7 : la question reste à la création. Modifiable à tout moment dans les réglages.

### Écran `recap` — Récapitulatif

Koach : « Tout est bon ? Tu peux tout modifier. »

## 4. Échéances : préréglages de règlement

L'éditeur d'échéance propose ces préréglages (`rulesetPresets`) ; ils pré-remplissent mouvements, tentatives et sauts de charge, **que l'utilisateur peut toujours modifier** : les formats varient d'un organisateur à l'autre, et aucun règlement unifié n'existe pour les compétitions de répétitions (sets & reps). Le moteur ne lit que les données de l'échéance (`SeasonEvent`), jamais le code du règlement.

| Code | Libellé | Contenu | Source | État de la vérification |
| --- | --- | --- | --- | --- |
| `final_rep_all4` | Final Rep — 4 mouvements | `sl-muscle-up-leste` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-squat-competition` × 3 tentatives (saut ≥ 2.5 kg) ; catégories femmes 52, 57, 63, 70 kg et plus ; hommes 66, 73, 80, 87, 94, 101 kg et plus | https://final-rep.com/weighted/about ; https://final-rep.com/rulebook/ | Page lue le 02/10/2026 ; règlement VI26.2 non lu en entier (formule de l'indice relatif non relevée). |
| `final_rep_2lift` | Final Rep — traction et dips | `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) ; catégories femmes 52, 57, 63, 70 kg et plus ; hommes 66, 73, 80, 87, 94, 101 kg et plus | https://final-rep.com/weighted/about | Page lue le 02/10/2026. |
| `isf_classic` | ISF — Streetlifting Classic | `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) | https://streetlifting.ru/docs/isf-rules/faq | FAQ de la version 5.2 lue le 02/10/2026 ; texte complet non lu (catégories non relevées). |
| `isf_multirep` | ISF — Multirep (maximum de répétitions lestées) | max_reps_in_time : `sl-traction-lestee` (120 s), `sl-dips-leste` (120 s) | https://streetlifting.ru/docs/isf-rules/faq | FAQ de la version 5.2 lue le 02/10/2026 : une tentative, 2 minutes, lest fixe ; lests par catégorie non relevés (à saisir). |

Formats de compétition de répétitions réellement observés (pour l'éditeur de postes) : maximum de répétitions lestées en 2 minutes (ISF Multirep) ; total de répétitions sur trois exercices lestés (WSWCF « Power ») ; volume imposé au poids du corps contre la montre (WSWCF « Strength ») ; duel à élimination sur une routine imposée différente à chaque tour, avec pyramides, maintiens et séries indivisibles (Calisthenics Cup 2025). D'où un type d'épreuve générique : mode, suite ordonnée de postes (exercice, répétitions ou durée, lest, série indivisible, limite de temps et repos imposé du poste), tours, limite de temps, nombre de passages dans la journée ; format annoncé le jour même : `formatKnown: false`, sans postes (préparation générale). État de la vérification : pages des organisateurs lues le 02/10/2026 à travers un outil de résumé (`PROFIL_V3.md`, § 6).

## 5. Tests guidés

Quand une capacité est inconnue (« Je ne sais pas », ou aucun record pour un mouvement dont le programme a besoin), l'application propose un test guidé. **À la création du profil : uniquement des déclarations, aucun test physique.** Les tests sous-maximaux se font **dans la première séance** (le moteur les prescrit comme séries de rôle `test`, `ExercisePrescription.test`) ; les tests maximaux et de course, **plus tard**, après 3 à 4 séances de familiarisation. Les valeurs des deux à trois premières séances sont « provisoires » : chez un pratiquant qui découvre le test, l'apprentissage du geste fait monter le maximum mesuré d'une séance à l'autre sans gain de force réel (ordre de grandeur de 5 à 10 % d'après `ploutzsnyder2001`, très petits effectifs, chiffres lus sur un résumé secondaire : repère, pas une règle).

Le résultat d'un test est un `Benchmark` (`source: guided_test`, `protocolId`) que l'application ajoute à `AthleteProfile.benchmarks` (ou que le moteur dynamique rend dans `AdaptReview.testResults`). Conversions : `lib/src/estimation.dart`. `ProfileQuestionnaire.eligibleTests(profilJson, todayYear: …)` rend les protocoles **permis** pour un profil ; un test n'est **proposé** que pour un mouvement du programme dont la capacité est inconnue, avec le matériel du profil, et quand son prérequis par mouvement (ligne « Prérequis ») est tenu d'après les niveaux et les records déclarés — ce tri par mouvement est fait par l'application (CU) et les moteurs. Un débutant, ou un profil dont le questionnaire santé n'est pas « standard », n'a que `t8_sans_test`.

### `t1_serie_lourde` — Série lourde d'estimation (barre, haltères, machine)

- **Pour qui** : Pratiquant qui sait exécuter le mouvement ; test par défaut pour un mouvement chargé dont le maximum est inconnu.
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Prérequis** : Le mouvement est au programme et le matériel est dans le profil.
- **Sécurité** : Barres de sécurité ou pareur au squat et au développé couché. Arrêt dès que la technique se dégrade.
- **Déroulé** :
  1. Échauffement général de 5 minutes.
  2. Barre à vide × 8, puis environ 50 % de la charge visée × 5, 70 % × 3, 85 % × 1.
  3. Repos de 2 à 3 minutes.
  4. Série test : une charge que tu penses pouvoir soulever 5 fois ; arrête-toi en gardant 1 à 2 répétitions sous le pied.
- **Arrêt** : 1 à 2 répétitions en réserve, ou la barre ralentit nettement, ou la technique se dégrade. Série valable de 3 à 6 répétitions ; de 7 à 10, valeur gardée avec une incertitude plus large ; au-delà de 10, une seule reprise plus lourde après 3 à 5 minutes.
- **Conversion** : r = répétitions + réserve déclarée ; 1RM = charge × 36 / (37 − r), sur la charge de la barre (squat, développé, soulevé de terre : jamais le poids du corps). Refusé au-delà de r = 10. (`estimateOneRm`)
- **Incertitude** : ±5 % (série au maximum, jusqu'à 6 répétitions) ; ±7,5 % (réserve déclarée, ou 7 à 10 répétitions) ; ±10 % et valeur « provisoire » avant 6 mois de pratique. Calcul de ce lot à partir de la variabilité publiée, pas un chiffre publié.
- Références (`PROFIL_V3.md`, § 5) : brzycki1993, nuzzo2024, reynolds2006, mayhew2008, halperin2022, steele2017.

### `t2_leste` — Série lourde d'estimation lestée (traction, dips)

- **Pour qui** : Pratiquant capable d'au moins 8 répétitions strictes au poids du corps. Pas pour le muscle-up lesté (mouvement technique : aucune estimation par équation).
- **Quand** : première séance ; permis si : (`healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate) ET `bodyWeightKg` renseigné.
- **Prérequis** : Au moins 8 répétitions strictes au poids du corps sur le mouvement (niveau ou record déclaré) ; ceinture de lest et disques au profil.
- **Sécurité** : Ceinture de lest fermée, descente contrôlée, pas de lâcher en bas des dips. Épaules et coudes échauffés.
- **Déroulé** :
  1. Pesée du jour.
  2. Montée : 5 répétitions au poids du corps, puis 3 répétitions à la moitié du lest visé, puis 1 répétition au lest visé moins 5 kg.
  3. Lest visé supérieur à 40 % du poids de corps : montée en quatre marches — poids du corps × 5, 40 % du lest visé × 3, 65 % × 2, 85 % × 1.
  4. Repos de 3 minutes.
  5. Série test visant 3 à 6 répétitions, arrêtée avec 1 répétition sous le pied.
- **Arrêt** : 1 répétition en réserve, ou première répétition hors amplitude (menton sous la barre ; épaule au-dessus du coude en bas des dips).
- **Conversion** : Charge totale = lest + fraction du poids du corps × poids du jour ; 1RM total par Brzycki ; lest maximal = 1RM total − fraction × poids. Seulement pour les exercices qui ont une fraction du poids du corps au catalogue. (`estimateOneRm + externalFromTotal`)
- **Incertitude** : ±5 à ±7,5 % de la charge TOTALE, soit souvent ±15 à ±20 % du lest : la fourchette est affichée en kilos de lest. Extrapolation : aucune étude ne valide l'équation sur ces mouvements. Ne sert pas au choix des tentatives.
- Références (`PROFIL_V3.md`, § 5) : brzycki1993, ortega2021, coyne2015, nuzzo2024.

### `t3_max_direct` — Maximum direct (1 répétition)

- **Pour qui** : Pratiquant confirmé du mouvement (plus de 6 mois), questionnaire santé sans réserve ; jamais après 65 ans sans au moins 2 ans de pratique. Seul test proposé pour le muscle-up lesté.
- **Quand** : plus tard (après familiarisation) ; permis si : (`healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate) ET `trainingAge` ≥ months_6_to_24 ET (pas (âge ≥ 65 ans) OU `trainingAge` ≥ years_2_to_5).
- **Prérequis** : Aucune gêne d'au moins 4/10 (au repos ou à l'effort) sur une zone que le mouvement charge. Muscle-up lesté : au moins 5 muscle-ups stricts au poids du corps, et aucune gêne au coude, à l'épaule ou au sternum.
- **Sécurité** : Pareur ou sécurités ; ceinture fermée. Un échec technique (forme perdue, amplitude manquée) arrête le test ; après un échec de force, une seule reprise plus légère. Muscle-up lesté : tout échec arrête le test ; 4 essais lourds au plus.
- **Déroulé** :
  1. 5 à 10 répétitions légères ; repos 1 minute.
  2. Charge plus lourde × 3 à 5 répétitions ; repos 2 minutes.
  3. Charge plus lourde × 2 à 3 répétitions ; repos 2 à 4 minutes.
  4. Essais d'une répétition, repos de 2 à 4 minutes entre deux essais. Barre (squat, développé) : +5 à 10 % après une réussite, −2,5 à 5 % après un échec de force.
  5. Mouvements lestés : les sauts se comptent en kilos de LEST, pas en pourcentage — +5 kg, puis +2,5 kg, puis +1,25 kg à l'approche du maximum.
- **Arrêt** : Échec technique, deuxième échec de force, ou 5 essais. Le maximum est trouvé en 3 à 5 essais.
- **Conversion** : La meilleure charge réussie est le maximum (réserve 0, 1 répétition).
- **Incertitude** : ±4 % d'un jour à l'autre (coefficient de variation médian du test de 1RM).
- Références (`PROFIL_V3.md`, § 5) : grgic2020, nsca2016, pollock1991, seo2012.

### `t4_reps_max` — Répétitions max au poids du corps (traction, dips, pompes, muscle-up)

- **Pour qui** : Pratiquant qui fait déjà plusieurs répétitions strictes ; qui n'en fait aucune travaille une variante plus facile, sans test.
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Prérequis** : Le mouvement est au programme.
- **Sécurité** : Échauffement ; une seule série test par mouvement et par séance.
- **Déroulé** :
  1. 2 séries d'échauffement à environ un tiers du nombre attendu.
  2. Repos de 3 minutes.
  3. Série maximale, amplitude complète, sans élan.
- **Arrêt** : Première répétition hors amplitude, ou pause de plus de 3 secondes.
- **Conversion** : Valeur brute. Aucune conversion en maximum lesté au-delà de 10 répétitions. Muscle-up : moins de 5 répétitions strictes, pas de lest (usage d'entraîneur).
- **Incertitude** : ±1 répétition jusqu'à 10, ±2 au-delà pour la traction et les dips (estimation de ce lot : aucune étude de fiabilité lue pour ces mouvements) ; pompes : un écart de moins de 4 à 5 répétitions entre deux tests ne prouve pas un changement.
- Références (`PROFIL_V3.md`, § 5) : kardor2023, sanchezmoreno2017, mitter2022.

### `t5_maintien_max` — Maintien max (suspension, gainage, L-sit, étape de figure)

- **Pour qui** : Sur l'étape de progression tenue proprement au moins 5 secondes.
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Prérequis** : L'étape est au programme ; équilibre : au mur tant que la sortie n'est pas acquise.
- **Sécurité** : Poignets et épaules échauffés ; sortie contrôlée. Tapis sous les figures en appui renversé ou en suspension.
- **Déroulé** :
  1. 2 maintiens courts d'échauffement (environ un tiers du temps attendu).
  2. Repos de 2 à 3 minutes.
  3. Maintien long (gainage, suspension) : un seul maintien maximal chronométré.
  4. Maintien court de figure (moins de 15 secondes attendues) : 3 essais, 2 à 3 minutes de repos ; on garde le meilleur essai propre.
- **Arrêt** : Perte de la forme (hanches qui tombent, bras qui fléchissent), pas la chute.
- **Conversion** : Valeur brute. Les durées de travail en sont une part (60 à 70 % : usage d'entraîneur, réglé par les moteurs).
- **Incertitude** : ±5 à 10 % pour un maintien long (gainage) ; ±1 à 2 secondes pour un maintien court de figure, soit jusqu'à ±25 % sur 6 secondes (estimation : aucune étude de fiabilité sur les figures).
- Références (`PROFIL_V3.md`, § 5) : rodriguezperea2025, martinezromero2020, low2016.

### `t6_course_6min` — Course : test de 6 minutes

- **Pour qui** : Personne capable de courir 10 minutes sans s'arrêter.
- **Quand** : plus tard (après familiarisation) ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Prérequis** : La course est au programme.
- **Sécurité** : Terrain plat, pas de forte chaleur. Échauffement de 10 à 15 minutes et 3 accélérations. Arrêt immédiat en cas de douleur dans la poitrine, de vertige ou d'essoufflement anormal.
- **Déroulé** :
  1. Courir la plus grande distance possible en 6 minutes, à allure régulière (première minute prudente).
- **Arrêt** : Fin du chronomètre ; un arrêt avant la fin invalide le test (à refaire un autre jour).
- **Conversion** : Vitesse moyenne = distance / 360 s ; les allures d'entraînement en sont des parts (`speed_fraction`). (`trialSpeed`)
- **Incertitude** : ±5 à 8 % sur la vitesse (estimation ; aucune étude de validation lue).
- Références (`PROFIL_V3.md`, § 5) : mayorgavega2016, cooper1968.

### `t7_course_chrono` — Course : contre-la-montre de 5 km (3 km pour les moins aguerris)

- **Pour qui** : Coureur régulier (30 minutes en continu).
- **Quand** : plus tard (après familiarisation) ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Prérequis** : La course est au programme.
- **Sécurité** : Comme le test de 6 minutes. Échauffement de 15 minutes.
- **Déroulé** :
  1. Distance fixe au meilleur temps, à allure régulière. Le 5 km est préféré pour prédire un 10 km.
- **Arrêt** : Distance terminée.
- **Conversion** : Temps prédit sur une autre distance = temps × (distance voulue / distance du test)^1,06, jusqu'au semi-marathon. Prédiction « provisoire » : elle suppose un volume de course suffisant pour la distance visée. (`riegelSeconds`)
- **Incertitude** : ±2 à 3 % sur le temps du test (coureurs entraînés), davantage chez un coureur qui gère mal son allure ; prédiction d'une distance plus longue : au moins ±4 % à faible volume hebdomadaire (estimation) ; au-delà du semi-marathon la formule est trop optimiste : aucune prédiction.
- Références (`PROFIL_V3.md`, § 5) : laursen2007, riegel1981, vickers2016.

### `t8_sans_test` — Sans test : calage au fil des séances

- **Pour qui** : Débutant (ou niveau non renseigné) ; questionnaire santé en mode prudent ou sans réponse.
- **Quand** : à la création (déclaratif) ; permis si : pas (`healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate).
- **Prérequis** : Rien.
- **Sécurité** : Aucun effort maximal, aucun examen.
- **Déroulé** :
  1. Charges de départ prudentes choisies par le moteur (D4.7).
  2. Calage en 2 à 3 séances d'après les répétitions faites et les flammes (D3.5).
  3. Course : allure de conversation.
- **Conversion** : Aucune valeur n'est écrite dans le profil ; les estimations du moteur dynamique font foi.
- **Incertitude** : Valeur « non mesurée » ; les valeurs des deux à trois premières séances sont provisoires (apprentissage du geste).
- Références (`PROFIL_V3.md`, § 5) : ploutzsnyder2001.

### `t9_reps_temps` — Épreuves de répétitions : maximum en temps limité

- **Pour qui** : Pratiquant de sets & reps ou compétiteur d'une épreuve de répétitions, après familiarisation.
- **Quand** : plus tard (après familiarisation) ; permis si : (`healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate) ET (`streetMode.setsRepsPct` ≥ 1 OU (`disciplines.primary` ∈ {street_workout} OU `disciplines.secondaries[*].discipline` ∈ {street_workout}) OU `events[*].kind` ∈ {reps_competition}).
- **Prérequis** : Au moins 10 répétitions strictes d'une traite sur le mouvement.
- **Sécurité** : Échauffement complet ; amplitude jugée comme en compétition. Arrêt si la technique se dégrade ou si une douleur apparaît.
- **Déroulé** :
  1. Maximum de répétitions en 2 minutes (ou dans la durée de l'épreuve visée), pauses libres.
  2. Noter le total et le découpage (répétitions de chaque série, repos pris).
- **Arrêt** : Fin du chronomètre.
- **Conversion** : Valeur brute : `Benchmark` de nature `max_reps` avec `seconds` ; le découpage se lit dans le journal (`SetRecord.parts`).
- **Incertitude** : Non connue : usage d'entraîneur, aucune étude de fiabilité lue. Un écart de moins de 2 à 3 répétitions entre deux tests ne prouve pas un changement (estimation).
- Références (`PROFIL_V3.md`, § 5) : mitter2022.

### `t10_series_repetees` — Épreuves de répétitions : trois séries maximales

- **Pour qui** : Pratiquant de sets & reps ou compétiteur d'une épreuve de répétitions, après familiarisation.
- **Quand** : plus tard (après familiarisation) ; permis si : (`healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate) ET (`streetMode.setsRepsPct` ≥ 1 OU (`disciplines.primary` ∈ {street_workout} OU `disciplines.secondaries[*].discipline` ∈ {street_workout}) OU `events[*].kind` ∈ {reps_competition}).
- **Prérequis** : Au moins 10 répétitions strictes d'une traite sur le mouvement.
- **Sécurité** : Comme le test précédent.
- **Déroulé** :
  1. 3 séries maximales du même mouvement, 90 secondes de repos entre les séries.
- **Arrêt** : Fin de la troisième série.
- **Conversion** : La première série est le maximum (`max_reps`) ; la chute de la première à la troisième série dit comment découper et espacer les séries (réglage des moteurs).
- **Incertitude** : Non connue : usage d'entraîneur, aucune étude de fiabilité lue.
- Références (`PROFIL_V3.md`, § 5) : mitter2022.

Tests permis par profil type (`expected.testIds`) :

| Profil type | Tests permis |
| --- | --- |
| `v3_debutant_forme_generale` | `t8_sans_test` |
| `v3_intermediaire_musculation` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |
| `v3_competiteur_elite_streetlifting` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono`, `t9_reps_temps`, `t10_series_repetees` |
| `v3_coureuse_10km` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |
| `v3_sets_reps_avance` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono`, `t9_reps_temps`, `t10_series_repetees` |

## 6. Utilisateurs existants, édition, sauvegarde

- **Migration** : `profile.toSchema3()` (ou `migrateAthleteProfileJsonToSchema3`) ne change que `schemaVersion` : aucun champ perdu, aucun inventé — toutes les réponses du schéma 3 restent absentes tant que l'utilisateur ne les a pas données. Le programme en cours n'est pas régénéré ; le programme importé du propriétaire ne l'est jamais (D5.10).
- **« Compléter mon profil »** : montrer les seules questions du schéma 3 visibles pour ce profil — `visibleQuestions(profilJson, todayYear: …, since: 3, includeDeferred: true)` — dans l'ordre du § 3. Invitation discrète de Koach, une seule fois. L'application retient elle-même (hors du profil) quelles questions ont été passées, pour ne pas les reproposer d'office.
- **Édition** : chaque réponse du schéma 3 est modifiable depuis Réglages › Profil, rubrique par rubrique, comme celles du schéma 2. Les réponses de l'écran `recuperation` portent une date (`lifestyleUpdatedOn`) : Koach peut proposer de les revoir quand elles ont plus de 3 mois (choix raisonné : le stress et le sommeil changent).
- **Avant d'enregistrer** : `profile.validate()` et `catalog.checkProfile(profile)` vides. Un profil qui porte un champ du schéma 3 doit être au schéma 3 (`schema3_field` sinon).
- **Sauvegarde, export, import** : le profil se sérialise en entier par `toJson()` ; les champs du schéma 3 y sont, rien d'autre à ajouter. Un profil au schéma 2 relu par `fromJson` se réécrit à l'identique.
- **Application en 0.3.0** : elle refuse un profil au schéma 3 (violation `above_max` sur `schemaVersion`). Ne migrer un profil qu'une fois l'application passée à `kalis_core` 0.4.0 ; une sauvegarde au schéma 3 ne se relit pas sur une version antérieure.
- **Moteurs actuels** : `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0 lisent un profil au schéma 3 sans changement (ils ignorent les champs nouveaux) ; les moteurs calibrés (CP1, CA1) les liront.
