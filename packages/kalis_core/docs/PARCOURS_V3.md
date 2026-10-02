# Parcours de création du profil v3 — pour le lot CU

Fichier généré par `tool/gen_parcours.py` depuis `tool/parcours_spec.py` — ne pas modifier à la main. Données lues par l'application : [`data/parcours_v3.json`](../data/parcours_v3.json) (`ProfileQuestionnaire`, `lib/src/questionnaire.dart`). Pourquoi chaque question existe, à qui elle est posée et ce qui a été écarté : [`PROFIL_V3.md`](PROFIL_V3.md).

## 1. Principe

- Le parcours v3 **reprend l'écran de création du profil du lot G6** (mêmes écrans, mêmes composants, même ton) et y ajoute les questions du schéma 3, **posées seulement à ceux pour qui elles comptent**. Une question = un écran ou un bloc d'écran clair ; Koach présente chaque écran (texte `koach`).
- **Arbre adaptatif** : chaque question porte une condition d'apparition (`when`) évaluée sur le profil en cours de saisie. L'application ne code aucune condition : elle appelle `ProfileQuestionnaire.visibleQuestions(profilJson, todayYear: …)` après chaque réponse. Une réponse absente rend la condition fausse : **sans réponse, on montre le parcours le plus court**.
- **« Passer »** (`skip`) : le champ reste absent du profil — jamais de valeur par défaut (D5.8). **« Je ne sais pas »** (`unknown`) : même effet, et un test guidé sera proposé (§ 5).
- **Liste vide ≠ champ absent** : `otherSports: []` = « aucun autre sport » ; `events: []` = « aucune échéance » ; champ absent = question non posée ou passée.
- **Santé** : la règle L13 et son questionnaire sont inchangés. Les gênes sont des **contraintes d'entraînement** (zone, côté, gêne perçue, depuis quand, mouvements qui la réveillent), jamais un diagnostic ; elles ne sont écrites qu'avec l'accord santé (G6, KT-042).
- **Valeurs habituelles, pas valeurs du jour** : sommeil, stress et charge hors programme du profil sont des habitudes ; la nuit dernière, le stress et les douleurs du jour restent dans le bilan de séance (D5.8-D5.9). Aucun doublon : le bilan de séance n'est pas modifié.

## 2. Nombre de questions vues par profil type

Convention : une question = une entrée de `questions` visible (un champ, ou un éditeur de liste compté une fois, quel que soit le nombre d'éléments saisis). Les écrans d'accueil et de récapitulatif ne posent pas de question. « Nouvelles » = questions du schéma 3. Profils : `test/fixtures/profiles_v3.json` ; les mêmes nombres sont vérifiés en Dart (`test/questionnaire_test.dart`) — CU les revérifie dans l'application.

| Profil type | Questions vues | dont nouvelles (schéma 3) | Nouvelles questions vues |
| --- | ---: | ---: | --- |
| `v3_debutant_forme_generale` — Débutant complet, forme générale, 2 × 30 min à la maison sans matériel. | 20 | 4 | `training_age`, `sleep`, `stress`, `outside_load` |
| `v3_intermediaire_musculation` — Femme de 34 ans, musculation en salle depuis 3 ans, 4 × 60 min, un footing par semaine. | 25 | 8 | `training_age`, `training_gap`, `benchmarks`, `events`, `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| `v3_competiteur_elite_streetlifting` — Compétiteur élite de streetlifting (catégorie −73 kg), mode street 70/15/15, 5 séances, compétition principale dans 28 semaines. | 28 | 11 | `training_age`, `training_gap`, `benchmarks`, `skills`, `events`, `specialization`, `weak_points`, `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| `v3_coureuse_10km` — Autre discipline : coureuse régulière (cardio 70 %, musculation 20 %, mobilité 10 %), 10 km visé en mars, reprise après deux semaines d'arrêt. | 25 | 8 | `training_age`, `training_gap`, `benchmarks`, `events`, `sleep`, `stress`, `outside_load`, `body_weight_goal` |
| `v3_sets_reps_avance` — Mode street, principale sets & reps (20/60/20), avancé, compétition de répétitions contre la montre, sport de combat deux fois par semaine. | 28 | 11 | `training_age`, `training_gap`, `benchmarks`, `skills`, `events`, `specialization`, `weak_points`, `sleep`, `stress`, `outside_load`, `body_weight_goal` |

Repère : le parcours G6 (schéma 2) posait 17 questions à tout le monde. Le parcours v3 en pose **moins de schéma 2 à un débutant** (les exercices aimés ou détestés lui sont demandés pendant la revue du programme, D4.5) et lui ajoute 4 questions à un seul appui. Parcours le plus court possible à information égale : chaque question du schéma 3 retenue change une décision du moteur (colonne « Ce que ça change ») ; celles qui n'en changent aucune sont écartées dans `PROFIL_V3.md`.

## 3. Écrans et questions, dans l'ordre

### Écran `accueil` — Bienvenue

Koach : « Salut ! Quelques questions et je te prépare un programme à ta mesure. »

Accueil de Koach et avertissement santé L13 (inchangés).

### Écran `toi` — Toi

Koach : « On commence par toi. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `display_name` | Comment je t'appelle ? | texte ; « Passer » | `displayName` | tous | non | 2 |
| `sex` | Tu es… | un choix | `sex` | tous | oui | 2 |
| `birth_year` | Ton année de naissance ? | nombre | `birthYear` | tous | oui | 2 |
| `height` | Ta taille ? | nombre | `heightCm` | tous | oui | 2 |
| `body_weight` | Ton poids ? | nombre ; « Passer » | `bodyWeightKg` | tous | non | 2 |

**`display_name`**

- Validation : 40 caractères au plus.

**`sex`**

- Réponses : Une femme → `female` · Un homme → `male` · Je préfère ne pas le dire → `undisclosed`
- Ce que ça change : Aucun effet sur le programme (gains relatifs identiques) ; sert aux repères de rang.
- Justification : `PROFIL_V3.md`, facteur `sexe`.

**`birth_year`**

- Validation : 18 ans et plus (règle L13).
- Ce que ça change : Prudence des tests (pas de maximum direct après 65 ans sans expérience) ; attentes de progression.
- Justification : `PROFIL_V3.md`, facteur `age`.

**`height`**

- Validation : 100 à 250 cm.
- Ce que ça change : Aucun effet sur le programme ; champ obligatoire du schéma 2, gardé.
- Justification : `PROFIL_V3.md`, facteur `taille`.

**`body_weight`**

- Koach : « C'est ta charge sur les tractions, les dips, les pompes : avec lui, je calcule juste. »
- Validation : 25 à 300 kg.
- Ce que ça change : Charge totale des exercices au poids du corps ou lestés, force relative, catégories de poids.
- Note : En mode street ou en calisthénie, Koach explique que sans le poids les charges lestées ne peuvent pas être calculées ; la question reste passable.
- Justification : `PROFIL_V3.md`, facteur `poids_de_corps`.

### Écran `discipline` — Ta discipline

Koach : « Qu'est-ce qui te fait envie ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `discipline` | Ta discipline principale (ou le mode street) | éditeur de liste | `disciplines.primary`, `streetMode` | tous | oui | 2 |

**`discipline`**

- Note : 8 disciplines (D3.1) ou mode street : principale parmi streetlifting, sets & reps, calisthénie (D3.3).

### Écran `dosage` — Le dosage

Koach : « Un peu d'autre chose à côté ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `secondaries` | Une ou deux disciplines en plus, et leur dosage | éditeur de liste | `disciplines.secondaries`, `disciplines.primaryPct` | tous | oui | 2 |

**`secondaries`**

- Note : 1 à 2 secondaires, somme 100 % (D3.2) ; en mode street, le dosage des deux autres styles.

### Écran `experience` — Ton expérience

Koach : « Dis-moi d'où tu pars : je règle le volume et le rythme là-dessus. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `experience_level` | Ton niveau aujourd'hui ? | un choix ; « Passer » | `experience` | tous | non | 2 |
| `training_age` | Depuis combien de temps tu t'entraînes régulièrement ? | un choix ; « Passer » | `trainingAge` | tous | non | 3 |
| `training_gap` | En ce moment, tu t'entraînes ? | un choix ; « Passer » | `trainingGap` | `trainingAge` ≥ months_6_to_24 | non | 3 |

**`experience_level`**

- Réponses : Débutant (Je découvre, ou je reprends de zéro) → `beginner` · Intermédiaire (Je m'entraîne régulièrement et je connais les mouvements de base) → `intermediate` · Avancé (Je progresse lentement, je sais ce qui marche pour moi) → `advanced` · Élite (Je fais de la compétition à bon niveau) → `elite`
- Ce que ça change : Ouvre les questions avancées (tests, compétition, points faibles) et borne les techniques servies.
- Note : Passée : le parcours reste celui d'un débutant (le plus court).
- Justification : `PROFIL_V3.md`, facteur `anciennete`.

**`training_age`**

- Koach : « Sans compter les longues coupures. »
- Réponses : Moins de 6 mois → `under_6_months` · 6 mois à 2 ans → `months_6_to_24` · 2 à 5 ans → `years_2_to_5` · Plus de 5 ans → `over_5_years`
- Ce que ça change : Volume et intensité de départ, vitesse de progression attendue, besoin de périodisation, prérequis des techniques avancées et des figures en bras tendus.
- Justification : `PROFIL_V3.md`, facteur `anciennete`.

**`training_gap`**

- Réponses : Oui, régulièrement → `none` · J'ai arrêté depuis moins de 3 semaines → `under_3_weeks` · J'ai arrêté depuis 3 à 10 semaines → `weeks_3_to_10` · J'ai arrêté depuis plus de 10 semaines → `over_10_weeks`
- Ce que ça change : Reprise progressive après un arrêt de plus de 3 semaines ; figures à forte contrainte tendineuse reprises une étape en dessous après un mois d'arrêt.
- Note : Posée une fois, à la création ; ensuite les coupures se lisent dans le journal (`TrainingLog.breaks`, dates des séances).
- Justification : `PROFIL_V3.md`, facteur `interruption`.

### Écran `niveaux` — Ton niveau

Koach : « Une fourchette me suffit. Si tu ne sais pas, on mesurera ensemble. »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `movement_levels` | Ton niveau sur quelques mouvements | éditeur de liste ; « Je ne sais pas » | `movementLevels` | tous | non | 2 |
| `benchmarks` | Tu connais tes records précis ? | éditeur de liste ; « Passer », « Je ne sais pas » | `benchmarks` | `experience` ≥ intermediate | non | 3 |
| `skills` | Les figures que tu travailles | éditeur de liste ; « Passer » | `skills` | (`disciplines.primary` ∈ {calisthenics} OU `disciplines.secondaries[*].discipline` ∈ {calisthenics}) OU `streetMode.calisthenicsPct` ≥ 1 | non | 3 |

**`movement_levels`**

- Note : Fourchettes par mouvement (D3.5), « Je ne sais pas » toujours possible. Débutant : 4 mouvements au plus ; sinon 9 au plus, choisis selon les disciplines.

**`benchmarks`**

- Koach : « Un chiffre exact vaut mieux qu'une fourchette : je calcule tes charges dessus. Sinon, on fera un test ensemble. »
- Ce que ça change : Charges en part du maximum dès le premier bloc, choix des tentatives, séries de test seulement là où il manque une valeur.
- Note : « Je ne sais pas » : aucun record n'est écrit ; les tests guidés sont proposés à la première séance (§ tests guidés). Liste vide = aucun record connu.
- Justification : `PROFIL_V3.md`, facteur `tests_records`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `exerciseId` | Quel mouvement ? | exercise | oui | Proposés d'abord : mouvements de compétition de la discipline, puis ceux de `movementLevels`. |
  | `kind` | Quel genre de record ? | choice | oui | Une charge soulevée (1 répétition ou plus) → `load_reps` · Un maximum de répétitions → `max_reps` · Un maintien le plus long possible → `max_hold` · Un temps sur une distance → `time_trial` · Une distance en un temps donné → `distance_trial` |
  | `externalLoadKg` | Quelle charge ? (le lest seul pour un exercice lesté) | number | oui | — |
  | `reps` | Combien de répétitions ? | number | oui | — |
  | `rir` | Il t'en restait combien sous le pied ? | choice | non | Aucune, c'était mon maximum → `0` · 1 → `1` · 2 → `2` · 3 ou plus → `3` — Seulement pour une charge soulevée ; passée : réserve inconnue (absente). |
  | `seconds` | Combien de temps ? | duration | oui | — |
  | `distanceMeters` | Quelle distance ? | number | oui | — |
  | `date` | C'était quand ? | date | non | Un record de plus de 6 mois est gardé, mais le moteur le reteste avant de s'y fier. |
  | `source` | D'où vient ce chiffre ? | choice | oui | Je l'ai fait à l'entraînement → `declared` · En compétition → `competition` |
  | `bodyWeightKg` | Ton poids ce jour-là ? | number | non | Seulement pour un exercice au poids du corps ou lesté. |

**`skills`**

- Koach : « Montre-moi où tu en es sur chaque figure : je reprends juste après. »
- Ce que ça change : Étape de départ de chaque progression, durées de maintien prescrites, critère de passage à l'étape suivante.
- Justification : `PROFIL_V3.md`, facteur `figures`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `targetExerciseId` | Quelle figure vises-tu ? | exercise | oui | Figures du catalogue qui ont une chaîne `variante_de` (front lever, planche, équilibre, back lever, L-sit, muscle-up, drapeau…). |
  | `currentExerciseId` | Où en es-tu ? | exercise | oui | Choix parmi les étapes de la chaîne `variante_de` de la figure, de la plus facile à la figure elle-même. |
  | `bestHoldSeconds` | Ton meilleur maintien propre sur cette étape ? | duration | non | — |
  | `bestReps` | Ou ton meilleur nombre de répétitions propres ? | number | non | — |

### Écran `objectifs` — Tes objectifs

Koach : « Où veux-tu aller ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `goals` | Tes objectifs | éditeur de liste | `goals` | tous | non | 2 |
| `events` | Une compétition ou un test daté en vue ? | éditeur de liste ; « Passer » | `events` | `experience` ≥ intermediate OU `goals[*].kind` ∈ {performance} | non | 3 |
| `specialization` | Un mouvement, une figure ou un muscle à faire passer avant tout ? | éditeur de liste ; « Passer » | `specialization` | `experience` ≥ advanced | non | 3 |
| `weak_points` | Sur tes mouvements principaux, où est-ce que ça bloque ? | éditeur de liste ; « Passer » | `weakPoints` | `experience` ≥ advanced ET (`disciplines.primary` ∈ {streetlifting, street_workout, calisthenics, musculation, crossfit} OU `disciplines.secondaries[*].discipline` ∈ {streetlifting, street_workout, calisthenics, musculation, crossfit}) | non | 3 |

**`goals`**

- Note : Performance chiffrée datée, habitude, ou « Laisse Koach proposer » (D3.8) ; le premier est le principal.

**`events`**

- Koach : « Si tu as une date, je construis toute ta saison pour que tu arrives en forme ce jour-là. »
- Ce que ça change : Plan de saison (phases, affûtage, pic de forme), travail spécifique des épreuves, tentatives le jour J.
- Note : Réponse « Non » : liste vide (aucune échéance). Passée : champ absent. Plusieurs échéances possibles ; une seule `main` conseillée par saison.
- Justification : `PROFIL_V3.md`, facteur `competition`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `kind` | C'est quoi ? | choice | oui | Compétition de force (streetlifting : une répétition, la plus lourde) → `strength_competition` · Compétition de répétitions (sets & reps, endurance) → `reps_competition` · Compétition de freestyle (figures jugées) → `freestyle_competition` · Une course → `race` · Une autre compétition → `other_competition` · Un test perso à une date précise → `personal_test` |
  | `date` | Quel jour ? | date | oui | — |
  | `priority` | Elle compte comment ? | choice | oui | C'est mon objectif principal → `main` · Importante, mais pas la principale → `secondary` · Juste pour m'entraîner à la compétition → `preparation` |
  | `name` | Son nom ? | text | non | — |
  | `ruleset` | Quel règlement ? | choice | non | Préréglages de `rulesetPresets` (ils pré-remplissent mouvements, tentatives et sauts de charge) ou « Autre » ; tout reste modifiable. |
  | `weightClassKg` | Ta catégorie de poids ? | number | non | Compétition de force ; « plus de … » coche `openWeightClass`. |
  | `lifts` | Les mouvements, dans l'ordre | list | oui | Compétition de force : mouvement, tentatives (3 par défaut), meilleure barre, barre visée. |
  | `mode` | Le format | choice | oui | Le plus de répétitions → `max_reps` · Le plus de répétitions en un temps → `max_reps_in_time` · Un volume imposé, le plus vite possible → `for_time` · Le maintien le plus long → `max_hold` — Compétition de répétitions. |
  | `stations` | Les exercices, dans l'ordre | list | non | Compétition de répétitions : exercice, répétitions ou durée imposées, lest, série indivisible. « Je ne connais pas encore le format » : liste d'une épreuve générique que l'utilisateur complétera. |
  | `distanceMeters` | Quelle distance ? | number | oui | Course. |
  | `targetSeconds` | Ton temps visé ? | duration | non | — |

**`specialization`**

- Koach : « Je peux lui donner la priorité pendant quelques semaines et entretenir le reste. »
- Ce que ça change : Cycle de spécialisation : volume et fréquence concentrés sur la cible, reste entretenu à dose réduite.
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
- Note : Une douleur n'est pas un point faible : elle se déclare à l'écran Santé.
- Justification : `PROFIL_V3.md`, facteur `points_faibles`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `exerciseId` | Quel mouvement ? | exercise | oui | — |
  | `kind` | Où ça bloque ? | choice | oui | En bas → `bottom` · Au milieu → `mid_range` · En fin de mouvement → `lockout` · Au départ arrêté → `dead_start` · À la transition → `transition` · La prise lâche → `grip` · Je m'écroule en fin de série → `late_set_fatigue` · L'équilibre → `balance` · La souplesse → `mobility` · Je manque de vitesse → `speed` |

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

- Note : Vocabulaire de la base, regroupé, préréglages, matériel par lieu (G6).

### Écran `recuperation` — Ta récupération — **nouvel écran**

Koach : « Ton corps récupère aussi en dehors des séances. Trois questions rapides. »

Nouvel écran (schéma 3). Les trois premières questions tiennent sur un écran ; chacune a « Passer ».

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `sleep` | En général, tu dors combien par nuit ? | un choix ; « Passer » | `sleep` | tous | non | 3 |
| `stress` | En ce moment, ta vie hors entraînement est… | un choix ; « Passer » | `stress` | tous | non | 3 |
| `outside_load` | En dehors de ce programme, ton corps travaille déjà ? | plusieurs choix + éditeur ; « Passer » | `occupationalLoad`, `otherSports` | tous | non | 3 |
| `body_weight_goal` | Ton poids, en ce moment, tu veux… | un choix ; « Passer » | `bodyWeightGoal` | `experience` ≥ intermediate OU `streetMode` renseigné | non | 3 |

**`sleep`**

- Réponses : Moins de 6 h → `under_6_hours` · 6 à 7 h → `hours_6_to_7` · 7 h ou plus → `hours_7_plus`
- Ce que ça change : Moins de 6 h : volume proche de l'échec et cardio intense dosés avec prudence, jamais de baisse de charge ; aucune promesse sur les blessures.
- Note : Valeur HABITUELLE. La nuit dernière se dit dans le bilan de séance (D5.8) : pas de doublon.
- Justification : `PROFIL_V3.md`, facteur `sommeil`.

**`stress`**

- Réponses : Plutôt tranquille → `low` · Chargée, mais ça va → `moderate` · Très stressante → `high`
- Ce que ça change : Stress élevé : séances lourdes d'un même groupe plus espacées, pas de hausse de volume, décharge avancée.
- Note : Valeur des dernières semaines ; redemandée de temps en temps (`lifestyleUpdatedOn`). Le stress du jour reste dans le bilan de séance.
- Justification : `PROFIL_V3.md`, facteur `stress`.

**`outside_load`**

- Réponses : Non : je suis surtout assis → `seated` · Je suis debout ou je marche toute la journée → `on_feet` · J'ai un métier physique (je porte, je soulève) → `heavy` · Je fais un autre sport régulièrement → `other_sport`
- Ce que ça change : Autre sport : séances lourdes des mêmes muscles placées à distance (au moins un jour) ; métier physique : départ prudent (choix raisonné, sans preuve directe).
- Note : Une seule question, plusieurs réponses possibles : une des trois premières écrit `occupationalLoad` (la première est exclusive des deux suivantes) ; « un autre sport » ouvre sur place l'éditeur d'`otherSports` ; sans cette réponse, `otherSports` est écrit vide (aucun). Passée : les deux champs restent absents.
- Justification : `PROFIL_V3.md`, facteur `charge_hors_programme`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `kind` | Quel sport ? | choice | oui | Course à pied → `running` · Vélo → `cycling` · Natation → `swimming` · Autre sport d'endurance → `other_endurance` · Sport collectif → `team_sport` · Sport de combat → `combat_sport` · Escalade → `climbing` · Sport de raquette → `racket_sport` · Autre sport de force → `other_strength` · Autre → `other` |
  | `sessionsPerWeek` | Combien de fois par semaine ? | number | oui | — |
  | `minutesPerSession` | Combien de temps à chaque fois ? | duration | oui | — |
  | `weekdays` | Toujours les mêmes jours ? | multi | non | — |
  | `hard` | C'est intense (matchs, combats, fractionné) ? | choice | non | Oui → `true` · Non → `false` |
  | `regions` | Ça fait surtout travailler… | multi | non | Les jambes → `lower_body` · Le tirage (dos, bras) → `upper_pull` · La poussée (épaules, pectoraux) → `upper_push` · Le tronc → `trunk` · Tout le corps → `whole_body` — Seulement pour « Autre sport de force » et « Autre ». |

**`body_weight_goal`**

- Réponses : Le faire baisser → `lose` · Le garder → `maintain` · Le faire monter → `gain` · Je n'y pense pas → `no_goal`
- Ce que ça change : En perte de poids : attentes réglées (la force peut monter, pas le muscle), volume gardé, tests moins fréquents ; lest et charge totale recalculés quand le poids change.
- Note : Aucun conseil alimentaire n'est donné. Le rythme réel se lit dans les pesées.
- Justification : `PROFIL_V3.md`, facteur `bilan_energetique`.

### Écran `sante` — Ta santé

Koach : « Une zone à ménager ? Je la protège. »

Questionnaire santé L13 inchangé ; les gênes sont des contraintes d'entraînement, jamais un diagnostic.

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `health_screening` | Questionnaire santé | éditeur de liste | `healthScreening` | tous | oui | 2 |
| `limitations` | Une zone à ménager ? | éditeur de liste | `limitations` | tous | non | 2 |

**`health_screening`**

- Note : Questionnaire L13 inchangé ; seule sa référence est dans le profil (aucune réponse copiée).

**`limitations`**

- Koach : « Une ancienne blessure, une articulation sensible : dis-moi ce qui la réveille, je la protège. »
- Ce que ça change : Mouvements qui chargent la zone : départ une variante en dessous, progression plus lente, pas de test maximal tant que la gêne est d'au moins 4/10.
- Note : Donnée de santé : écrite seulement avec l'accord santé (G6, KT-042). Une gêne de plus de 5/10, une douleur la nuit, une perte de force ou une aggravation sur deux semaines : Koach oriente vers un professionnel de santé, sans interpréter (règle L13).
- Justification : `PROFIL_V3.md`, facteur `antecedents`.
- Champs d'un élément :

  | Champ | Texte | Forme | Obligatoire | Réponses / note |
  | --- | --- | --- | --- | --- |
  | `zone` | Quelle zone ? | body_map | oui | — |
  | `side` | Quel côté ? | choice | oui | — |
  | `discomfort` | La gêne en ce moment, de 0 à 10 ? | slider | oui | — |
  | `since` | Depuis quand ? | choice | non | Moins de 6 semaines → `under_6_weeks` · 6 semaines à 3 mois → `weeks_6_to_12` · 3 mois à 1 an → `months_3_to_12` · Plus d'un an → `over_12_months` · C'est ancien, je ne sens plus rien → `past_resolved` — Schéma 3. |
  | `aggravatedBy` | Qu'est-ce qui la réveille ? | multi | non | Tirer bras fléchis (tractions, rowing) → `pull_bent_arm` · Être suspendu ou tirer bras tendus → `hang_straight_arm` · Pousser en appui (dips, pompes) → `push_support` · L'appui bras tendus (planche, équilibre) → `straight_arm_support` · Les bras au-dessus de la tête → `overhead` · Plier les genoux (squat, fentes) → `knee_flexion` · Se pencher en avant avec une charge → `hip_hinge` · La prise, ou le poignet en extension → `wrist_extension_grip` · Les anneaux → `rings` · Courir ou sauter → `running_jumping` — Schéma 3. |

### Écran `preferences` — Tes préférences

Koach : « Des exercices que tu adores, ou pas du tout ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `preferences` | Exercices aimés, exercices détestés | éditeur de liste ; « Passer » | `likedExerciseIds`, `dislikedExerciseIds` | `experience` ≥ intermediate | non | 2 |

**`preferences`**

- Note : Schéma 3 : masquée pour un débutant, qui dira « je n'aime pas » pendant la revue du programme (D4.5) ; toujours accessible dans Réglages › Profil.

### Écran `mode` — Assisté ou libre

Koach : « Je décide, ou je propose ? »

| Question (`id`) | Texte | Forme | Champ(s) | Posée à | Obligatoire | Schéma |
| --- | --- | --- | --- | --- | --- | ---: |
| `guidance_mode` | Assisté ou libre ? | un choix | `guidanceMode` | tous | oui | 2 |

**`guidance_mode`**

- Réponses : Assisté : Koach applique ses ajustements → `assisted` · Libre : Koach propose, tu décides → `free`

### Écran `recap` — Récapitulatif

Koach : « Tout est bon ? Tu peux tout modifier. »

## 4. Échéances : préréglages de règlement

L'éditeur d'échéance propose ces préréglages (`rulesetPresets`) ; ils pré-remplissent mouvements, tentatives et sauts de charge, **que l'utilisateur peut toujours modifier** : les formats varient d'un organisateur à l'autre, et aucun règlement unifié n'existe pour les compétitions de répétitions (sets & reps). Le moteur ne lit que les données de l'échéance (`SeasonEvent`), jamais le code du règlement.

| Code | Libellé | Contenu | Source | État de la vérification |
| --- | --- | --- | --- | --- |
| `final_rep_all4` | Final Rep — 4 mouvements | `sl-muscle-up-leste` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-squat-competition` × 3 tentatives (saut ≥ 2.5 kg) ; catégories femmes 52, 57, 63, 70 kg et plus ; hommes 66, 73, 80, 87, 94, 101 kg et plus | https://final-rep.com/weighted/about ; https://final-rep.com/rulebook/ | Page lue le 02/10/2026 ; règlement VI26.2 non lu en entier (formule de l'indice relatif non relevée). |
| `final_rep_2lift` | Final Rep — traction et dips | `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) ; catégories femmes 52, 57, 63, 70 kg et plus ; hommes 66, 73, 80, 87, 94, 101 kg et plus | https://final-rep.com/weighted/about | Page lue le 02/10/2026. |
| `isf_classic` | ISF — Streetlifting Classic | `sl-traction-lestee` × 3 tentatives (saut ≥ 1.25 kg) ; `sl-dips-leste` × 3 tentatives (saut ≥ 1.25 kg) | https://streetlifting.ru/docs/isf-rules/faq | FAQ de la version 5.2 lue le 02/10/2026 ; texte complet non lu (catégories non relevées). |
| `isf_multirep` | ISF — Multirep (maximum de répétitions lestées) | max_reps_in_time, 120 s : `sl-traction-lestee`, `sl-dips-leste` | https://streetlifting.ru/docs/isf-rules/faq | FAQ de la version 5.2 lue le 02/10/2026 : une tentative, 2 minutes, lest fixe ; lests par catégorie non relevés (à saisir). |

Formats de compétition de répétitions réellement observés (pour l'éditeur de postes) : maximum de répétitions lestées en 2 minutes (ISF Multirep) ; total de répétitions sur trois exercices lestés (WSWCF « Power ») ; volume imposé au poids du corps contre la montre (WSWCF « Strength ») ; duel à élimination sur une routine imposée différente à chaque tour, avec pyramides, maintiens et séries indivisibles (Calisthenics Cup 2025). D'où un type d'épreuve générique : mode, suite ordonnée de postes (exercice, répétitions ou durée, lest, série indivisible), tours, limite de temps.

## 5. Tests guidés

Quand une capacité est inconnue (« Je ne sais pas », ou aucun record pour un mouvement dont le programme a besoin), l'application propose un test guidé. **À la création du profil : uniquement des déclarations, aucun test physique.** Les tests sous-maximaux se font **dans la première séance** (le moteur les prescrit comme séries de rôle `test`, `ExercisePrescription.test`) ; les tests maximaux et de course, **plus tard**, après 3 à 4 séances de familiarisation. Les valeurs des deux à trois premières séances sont « provisoires » : l'apprentissage du geste fait monter un maximum de 5 à 10 % sans gain de force réel.

Le résultat d'un test est un `Benchmark` (`source: guided_test`, `protocolId`) que l'application ajoute à `AthleteProfile.benchmarks` (ou que le moteur dynamique rend dans `AdaptReview.testResults`). Conversions : `lib/src/estimation.dart`. `ProfileQuestionnaire.eligibleTests(profilJson, todayYear: …)` rend les protocoles permis pour un profil.

### `t1_serie_lourde` — Série lourde d'estimation (barre, haltères, machine)

- **Pour qui** : Toute personne qui sait exécuter le mouvement ; test par défaut pour un mouvement chargé dont le maximum est inconnu.
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard}.
- **Sécurité** : Barres de sécurité ou pareur au squat et au développé couché. Arrêt dès que la technique se dégrade.
- **Déroulé** :
  1. Échauffement général de 5 minutes.
  2. Barre à vide × 8, puis environ 50 % de la charge visée × 5, 70 % × 3, 85 % × 1.
  3. Repos de 2 à 3 minutes.
  4. Série test : une charge que tu penses pouvoir soulever 5 fois ; arrête-toi en gardant 1 à 2 répétitions sous le pied.
- **Arrêt** : 1 à 2 répétitions en réserve, ou la barre ralentit nettement, ou la technique se dégrade. Série valable de 3 à 6 répétitions ; de 7 à 10, valeur gardée avec une incertitude plus large ; au-delà de 10, une seule reprise plus lourde après 3 à 5 minutes.
- **Conversion** : r = répétitions + réserve déclarée ; 1RM = charge × 36 / (37 − r). Refusé au-delà de r = 10. (`estimateOneRm`)
- **Incertitude** : ±5 % (série au maximum, 2 à 6 répétitions) ; ±7,5 % (réserve déclarée, ou 7 à 10 répétitions) ; ±10 % et valeur « provisoire » avant 6 mois de pratique.
- Références (`PROFIL_V3.md`, § 5) : brzycki1993, nuzzo2024, reynolds2006, mayhew2008, halperin2022, steele2017.

### `t2_leste` — Série lourde d'estimation lestée (traction, dips)

- **Pour qui** : Personne capable d'au moins 8 répétitions strictes au poids du corps. Pas pour le muscle-up lesté (mouvement technique : aucune estimation par équation).
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard} ET `bodyWeightKg` renseigné.
- **Sécurité** : Ceinture de lest fermée, descente contrôlée, pas de lâcher en bas des dips. Épaules et coudes échauffés.
- **Déroulé** :
  1. Pesée du jour.
  2. 5 répétitions au poids du corps, 3 répétitions à la moitié du lest visé, 1 répétition au lest visé moins 5 kg.
  3. Repos de 3 minutes.
  4. Série test visant 3 à 6 répétitions, arrêtée avec 1 répétition sous le pied.
- **Arrêt** : 1 répétition en réserve, ou première répétition hors amplitude (menton sous la barre ; épaule au-dessus du coude en bas des dips).
- **Conversion** : Charge totale = lest + fraction du poids du corps × poids du jour ; 1RM total par Brzycki ; lest maximal = 1RM total − fraction × poids. (`estimateOneRm + externalFromTotal`)
- **Incertitude** : ±5 à ±7,5 % de la charge TOTALE, soit souvent ±15 à ±20 % du lest : la fourchette est affichée en kilos de lest. Extrapolation : aucune étude ne valide l'équation sur ces mouvements.
- Références (`PROFIL_V3.md`, § 5) : brzycki1993, ortega2021, coyne2015, nuzzo2024.

### `t3_max_direct` — Maximum direct (1 répétition)

- **Pour qui** : Pratiquant confirmé du mouvement (plus de 6 mois), questionnaire santé sans réserve ; jamais après 65 ans sans au moins 2 ans de pratique. Seul test proposé pour le muscle-up lesté.
- **Quand** : plus tard (après familiarisation) ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate ET `trainingAge` ≥ months_6_to_24 ET (pas (âge ≥ 65 ans) OU `trainingAge` ≥ years_2_to_5).
- **Sécurité** : Pareur ou sécurités ; ceinture fermée. 5 essais au plus ; aucune tentative après un échec technique. Jamais sur une zone dont la gêne est d'au moins 4/10.
- **Déroulé** :
  1. 5 à 10 répétitions légères ; repos 1 minute.
  2. +5 à 10 % × 3 à 5 répétitions ; repos 2 minutes.
  3. +5 à 10 % × 2 à 3 répétitions ; repos 2 à 4 minutes.
  4. Essais d'une répétition : +5 à 10 % après une réussite, −2,5 à 5 % après un échec ; repos 2 à 4 minutes entre les essais.
- **Arrêt** : Échec, défaut technique, ou 5 essais. Le maximum est trouvé en 3 à 5 essais.
- **Conversion** : La meilleure charge réussie est le maximum (réserve 0, 1 répétition).
- **Incertitude** : ±4 % d'un jour à l'autre (coefficient de variation médian du test de 1RM).
- Références (`PROFIL_V3.md`, § 5) : grgic2020, nsca2016, pollock1991, seo2012.

### `t4_reps_max` — Répétitions max au poids du corps (traction, dips, pompes)

- **Pour qui** : Tous ; qui ne fait aucune répétition passe sur une variante plus facile ou sur un maintien (test suivant).
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard}.
- **Sécurité** : Échauffement ; une seule série test par mouvement et par séance.
- **Déroulé** :
  1. 2 séries d'échauffement à environ un tiers du nombre attendu.
  2. Repos de 3 minutes.
  3. Série maximale, amplitude complète, sans élan.
- **Arrêt** : Première répétition hors amplitude, ou pause de plus de 3 secondes. Débutant : arrêt quand la technique se dégrade, sans aller à l'échec.
- **Conversion** : Valeur brute. Aucune conversion en maximum lesté au-delà de 10 répétitions.
- **Incertitude** : ±1 répétition jusqu'à 10, ±2 au-delà (traction, dips) ; pompes : un écart de moins de 4 à 5 répétitions entre deux tests ne prouve pas un changement.
- Références (`PROFIL_V3.md`, § 5) : kardor2023, sanchezmoreno2017, mitter2022.

### `t5_maintien_max` — Maintien max (suspension, gainage, L-sit, étape de figure)

- **Pour qui** : Tous, sur l'étape de progression tenue proprement au moins 5 secondes.
- **Quand** : première séance ; permis si : `healthScreening.outcome` ∈ {standard}.
- **Sécurité** : Poignets et épaules échauffés ; sortie contrôlée. Tapis sous les figures en appui renversé ou en suspension.
- **Déroulé** :
  1. 2 maintiens courts d'échauffement (environ un tiers du temps attendu).
  2. Repos de 2 à 3 minutes.
  3. Un seul maintien maximal chronométré.
- **Arrêt** : Perte de la forme (hanches qui tombent, bras qui fléchissent), pas la chute.
- **Conversion** : Valeur brute. Les durées de travail en sont une part (60 à 70 % : usage d'entraîneur, réglé par les moteurs).
- **Incertitude** : ±5 à 10 % pour un maintien long (gainage) ; ±1 à 2 secondes pour un maintien court de figure (estimation : aucune étude de fiabilité sur les figures).
- Références (`PROFIL_V3.md`, § 5) : rodriguezperea2025, martinezromero2020, low2016.

### `t6_course_6min` — Course : test de 6 minutes

- **Pour qui** : Personne capable de courir 10 minutes sans s'arrêter.
- **Quand** : plus tard (après familiarisation) ; permis si : `healthScreening.outcome` ∈ {standard}.
- **Sécurité** : Terrain plat, pas de forte chaleur. Échauffement de 10 à 15 minutes et 3 accélérations. Arrêt immédiat en cas de douleur dans la poitrine, de vertige ou d'essoufflement anormal.
- **Déroulé** :
  1. Courir la plus grande distance possible en 6 minutes, à allure régulière (première minute prudente).
- **Arrêt** : Fin du chronomètre ; un arrêt avant la fin invalide le test (à refaire un autre jour).
- **Conversion** : Vitesse moyenne = distance / 360 s ; les allures d'entraînement en sont des parts (`speed_fraction`). (`trialSpeed`)
- **Incertitude** : ±5 à 8 % sur la vitesse (estimation ; aucune étude de validation lue).
- Références (`PROFIL_V3.md`, § 5) : mayorgavega2016, cooper1968.

### `t7_course_chrono` — Course : contre-la-montre de 3 ou 5 km

- **Pour qui** : Coureur régulier (30 minutes en continu) ; 3 km pour les moins aguerris.
- **Quand** : plus tard (après familiarisation) ; permis si : `healthScreening.outcome` ∈ {standard} ET `experience` ≥ intermediate.
- **Sécurité** : Comme le test de 6 minutes. Échauffement de 15 minutes.
- **Déroulé** :
  1. Distance fixe au meilleur temps, à allure régulière.
- **Arrêt** : Distance terminée.
- **Conversion** : Temps prédit sur une autre distance = temps × (distance voulue / distance du test)^1,06, jusqu'au semi-marathon. (`riegelSeconds`)
- **Incertitude** : ±2 à 3 % sur le temps du test (coureurs entraînés), davantage chez un coureur qui gère mal son allure ; au-delà du semi-marathon la formule est trop optimiste : aucune prédiction.
- Références (`PROFIL_V3.md`, § 5) : laursen2007, riegel1981, vickers2016.

### `t8_sans_test` — Sans test : calage au fil des séances

- **Pour qui** : Questionnaire santé en mode prudent ou sans réponse ; débutant complet qui ne veut pas de test.
- **Quand** : à la création (déclaratif) ; permis si : pas (`healthScreening.outcome` ∈ {standard}).
- **Sécurité** : Aucun effort maximal.
- **Déroulé** :
  1. Charges de départ prudentes choisies par le moteur (D4.7).
  2. Calage en 2 à 3 séances d'après les répétitions faites et les flammes (D3.5).
  3. Course : allure de conversation.
- **Conversion** : Aucune valeur n'est écrite dans le profil ; les estimations du moteur dynamique font foi.
- **Incertitude** : Valeur « non mesurée » ; un premier test est proposé après 3 à 4 séances de familiarisation si le questionnaire santé le permet.
- Références (`PROFIL_V3.md`, § 5) : ploutzsnyder2001.

Tests permis par profil type (`expected.testIds`) :

| Profil type | Tests permis |
| --- | --- |
| `v3_debutant_forme_generale` | `t1_serie_lourde`, `t2_leste`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min` |
| `v3_intermediaire_musculation` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |
| `v3_competiteur_elite_streetlifting` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |
| `v3_coureuse_10km` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |
| `v3_sets_reps_avance` | `t1_serie_lourde`, `t2_leste`, `t3_max_direct`, `t4_reps_max`, `t5_maintien_max`, `t6_course_6min`, `t7_course_chrono` |

## 6. Utilisateurs existants, édition, sauvegarde

- **Migration** : `profile.toSchema3()` (ou `migrateAthleteProfileJsonToSchema3`) ne change que `schemaVersion` : aucun champ perdu, aucun inventé — toutes les réponses du schéma 3 restent absentes tant que l'utilisateur ne les a pas données. Le programme en cours n'est pas régénéré ; le programme importé du propriétaire ne l'est jamais (D5.10).
- **« Compléter mon profil »** : montrer les seules questions du schéma 3 visibles pour ce profil — `visibleQuestions(profilJson, todayYear: …, since: 3)` — dans l'ordre du § 3. Invitation discrète de Koach, une seule fois. L'application retient elle-même (hors du profil) quelles questions ont été passées, pour ne pas les reproposer d'office.
- **Édition** : chaque réponse du schéma 3 est modifiable depuis Réglages › Profil, rubrique par rubrique, comme celles du schéma 2. Les réponses de l'écran `recuperation` portent une date (`lifestyleUpdatedOn`) : Koach peut proposer de les revoir quand elles ont plus de 3 mois (choix raisonné : le stress et le sommeil changent).
- **Avant d'enregistrer** : `profile.validate()` et `catalog.checkProfile(profile)` vides. Un profil qui porte un champ du schéma 3 doit être au schéma 3 (`schema3_field` sinon).
- **Sauvegarde, export, import** : le profil se sérialise en entier par `toJson()` ; les champs du schéma 3 y sont, rien d'autre à ajouter. Un profil au schéma 2 relu par `fromJson` se réécrit à l'identique.
- **Moteurs actuels** : `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0 lisent un profil au schéma 3 sans changement (ils ignorent les champs nouveaux) ; les moteurs calibrés (CP1, CA1) les liront.
