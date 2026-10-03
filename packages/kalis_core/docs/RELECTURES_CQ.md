# Relectures du lot CQ — remarques et suites données

`kalis_core` 0.4.0, lot CQ, 02/10/2026 ; mis à jour le 03/10/2026 après l'audit des suites données.

Trois relecteurs indépendants ont relu le lot : un relecteur du **contrat et du code** (remarques R1 à R29), un
« **débutant pressé** » qui a suivi le parcours de création du profil (D1 à D37), et un « **coach d'élite** » qui a
relu le parcours, la revue des facteurs et le contrat (E1 à E74). Chaque remarque est soit **changée** (le fichier,
le champ ou la question modifié est cité), soit **expliquée** (la raison de ne pas changer est donnée). « Changé en
partie » : une partie est faite, la raison de ne pas faire le reste est dite dans la même ligne. Aucune remarque
n'est laissée sans suite.

Le 03/10/2026, un quatrième relecteur indépendant a **audité ce document contre l'arbre** : il a vérifié, remarque
par remarque, que chaque changement annoncé est bien dans les sources (et que les comptes des documents sont
exacts). Ses constats sont traités : `body_weight_goal` reportée pour un débutant, `recent_training` placée après
`skills`, limites du `CONTRAT.md` § 9 alignées sur le code (`parts_mismatch`, `unknown_group`), `PacingSegment.setReps`
non vide, borne de `sets` dite au § 12, tableau du débutant par discipline (`PARCOURS_V3.md` § 2), et ce document
remis à jour (il était en retard sur la seconde passe).

Les numéros sont ceux des rapports. Le rapport du coach numérote E10bis (entre E9 et E11), E33bis et E47bis (pas de
E33 ni de E47 simples) : 75 remarques, renvois compris.

## Synthèse

| Relecteur | Remarques | Changé | Changé en partie | Expliqué |
| --- | ---: | ---: | ---: | ---: |
| Contrat et code (R) | 29 | 27 | 1 | 1 |
| « Débutant pressé » (D) | 37 | 29 | 5 | 3 |
| « Coach d'élite » (E) | 75 | 49 | 14 | 12 |
| **Total** | **141** | **105** | **20** | **16** |

## 1. Relecture du contrat et du code (R1 à R29)

| N° | Remarque | Suite | Ce qui a été fait, ou pourquoi non |
| --- | --- | --- | --- |
| R1 | Fichiers écrits à la main non formatés (la CI lance `dart format`), et `test/zz_dev_test.dart` ne doit pas être livré. | **Changé** | Tout le paquet passe par `dart format` (sources formatées reprises du contrôle de la CI, faute de SDK Dart sur le poste de travail) et `test/zz_dev_test.dart` est retiré de l'arbre livré ; le contrôle final de `claude/ci-cp-b` vérifie le formatage. |
| R2 | Le profil type `v3_sets_reps_avance` est écrit hors de l'ordre des champs du contrat : le test de réécriture à l'octet près échouera. | **Changé** | `tool/gen_parcours.py` : nouvelle fonction `ordonner`, qui réordonne chaque objet selon `contracts_spec.py`, à tous les niveaux ; `controle()` refuse un profil type dont les clés sont hors de l'ordre du contrat. `test/fixtures/profiles_v3.json` est régénéré. |
| R3 | L'unicité des records (exercice, nature, origine, jour) rejette deux records sans date sur le même mouvement. | **Changé** | `lib/src/custom_validation.dart` : l'invariant d'unicité de `benchmarks` est retiré. |
| R4 | `skill_step_outside_progression` rend invalide un profil dont l'étape de figure est hors de la famille `variante_de`, alors que `SkillLadder` ne l'exige pas. | **Changé** | `lib/src/catalog.dart` : `checkProfile` ne contrôle plus l'étape actuelle d'une figure (il n'ajoute plus que `unknown_muscle`). Une échelle peut passer par un exercice d'une autre famille. |
| R5 | `riegelSeconds` : boucle sans fin si le rapport des distances vaut 0 ou l'infini. | **Changé** | `lib/src/estimation.dart` : le domaine de `seconds` est contrôlé avant le calcul ; le résultat est `null` si le rapport n'est pas fini ou sort de 0,001 à 1 000. |
| R6 | `novice` donne 10 % d'erreur même pour un maximum mesuré (1 répétition, réserve 0). | **Changé** | `lib/src/estimation.dart`, `estimateOneRm` : 4 % pour 1 répétition à réserve 0, novice ou non ; les 10 % ne valent que pour une série de plusieurs répétitions ou avec réserve. |
| R7 | `evaluate` lève une erreur de type nul au lieu de `FormatException` pour une échelle inconnue. | **Changé** | `lib/src/questionnaire.dart` : `FormatException('Parcours : échelle inconnue')`. |
| R8 | Invariants croisés absents : `PacingSegment.setReps`, `SeasonPhase.eventId`, `SeasonEvent.goalIds`, distance de 0 m. | **Changé** | `custom_validation.dart` : `setReps` de 1 à 1 000 par élément ; `unknown_event` si l'`eventId` d'une phase n'est pas dans `SeasonPlan.eventIds` ; `unknown_goal` si un `goalIds` n'est pas un objectif du profil. `contracts_spec.py` : `distanceMeters` ≥ 1 sur `Benchmark` et `SeasonEvent`. |
| R9 | Une ligne de journal par mini-série fausse les comptes de `kalis_quest` 0.1.0 et de `kalis_adapt` 0.1.0. | **Changé** | `contracts_spec.py` : une ligne `SetRecord` par série ; le détail est dans `SetRecord.parts` (liste de `SetPart`), qui remplace `miniSetIndex`. `CONTRAT.md` § 12 (« Règle de base : une ligne de journal par série ») et § 16 le disent ; la somme des répétitions des `parts` est recoupée avec `reps` (`parts_mismatch`, `CONTRAT.md` § 9). |
| R10 | L'application a déjà un `enum PhaseKind` : conflit de nom à venir. | **Changé** | `contracts_spec.py` : l'énumération s'appelle `SeasonPhaseKind` (`SeasonPhase.kind`, `PhaseOverride.kind`, `BlockIntent.phase`, `SessionPlan.phase`). |
| R11 | Les valeurs aléatoires des tests grossissent : la durée de `contracts_roundtrip_test` va à peu près doubler. | **Expliqué** | Aucun type n'explose (constat du relecteur). La durée ne peut pas être mesurée sans SDK Dart : elle se lit au passage de la CI, contre son délai. |
| R12 | Une sauvegarde au schéma 3 relue par une application restée en 0.3.0 est invalide : à dire. | **Changé** | `docs/PARCOURS_V3.md` § 6, ligne « Application en 0.3.0 », `INTEGRATION.md` § 6 et `CONTRAT.md` § 16 : ne migrer un profil qu'une fois l'application passée à 0.4.0. |
| R13 | Aucun paramètre au niveau du groupe d'exercices : un circuit contre la montre, un AMRAP ou un EMOM à plusieurs exercices ne s'écrivent pas. | **Changé** | Nouveaux types `GroupSpec` (variantes par `format` : tours, durée, limite, intervalle, repos entre tours, temps visé, `eventId`) et `GroupResult` ; champs `DayPrescription.groups`, `SessionPlan.groups`, `SessionRecord.groupResults`, `ExercisePrescription.unbroken` ; valeur `for_time` dans `SetTechniqueKind`. |
| R14 | La règle « plus aucune valeur ajoutée » ferme les énumérations nouvelles avec des valeurs manquantes. | **Changé** | Valeurs ajoutées avant livraison : `SetRole` (`warmup`, `rung`, `interval`), `SetTechniqueKind` (`for_time`), `BenchmarkKind` (`reps_for_time`), `SeasonPhaseKind` (`maintenance`, `reintroduction`), `IntensityBasis` (`bodyweight_fraction`, `absolute_speed`), `AutoregulationKind` (`stop_on_quality_drop`). Règle revue (en-tête de `contracts_spec.py`, `CONTRAT.md` § 1) : les énumérations d'avant 0.4.0 sont fermées, celles de 0.4.0 sont ouvertes (leurs lecteurs prévoient un cas par défaut). |
| R15 | Plusieurs écritures de la même chose, sans priorité ni contrôle (`percentOfOneRm` et `intensity`, `targetFlames` et `rir`, baisse des séries allégées, `format` et technique…). | **Changé** | Doublons retirés de `IntensityBasis` : `hold_fraction`, `progression_step` (et `stepExerciseId`). `custom_validation.dart` : violation `intensity_mismatch` si `percentOfOneRm` sort de la plage de `intensity` (`percent_one_rm`), si `targetFlames` sort de celle de `intensity` (`rir`), ou si le `pct` d'une règle `backoff_from_top_set` diffère de `technique.backoffDropPct`. `GroupSpec` prime sur le texte libre `format`. La règle de priorité est écrite dans `CONTRAT.md` § 12 (« Préséance et cohérence »). |
| R16 | Le sens de `sets` par technique et les doublons avec la plage de répétitions ne sont pas validés. | **Changé** | `sets` est toujours le nombre de lignes de journal attendues (invariant d'`ExercisePrescription`). `custom_validation.dart`, `_validateTechniqueInPrescription` : `set_count` et `reps_mismatch` pour vagues, pyramide, échelle, EMOM, densité, volume au temps, clusters ; `ladder_step` si l'écart de l'échelle n'est pas un multiple du pas. Paramètres redondants retirés : `repsPerInterval`, `activationRepsLow`, `activationRepsHigh`. |
| R17 | Figures : `skill_practice` sans `durationSeconds`, `isometric_hold` sans `qualityFloor`. | **Changé** | `SetTechnique` : `skill_practice` admet `durationSeconds` et `totalSecondsTarget` ; `isometric_hold` admet `qualityFloor` et `totalSecondsTarget`. |
| R18 | Compétition de répétitions : `stations` exigé alors que le parcours le dit facultatif ; pas de limite de temps par poste. | **Changé** | `SeasonEvent`, variante `reps_competition` : seul `mode` est exigé. `EventStation.timeLimitSeconds` ajouté. Préréglage `isf_multirep` : 120 s sur chaque poste. |
| R19 | Une technique s'applique à toutes les séries : « la dernière en dégressive » ne s'écrit pas. | **Changé** | `SetTechnique.lastSetOnly`. |
| R20 | Course : allure cible de l'échéance non référençable, nature de la récupération absente, `heart_rate_fraction` sans fréquence au profil. | **Changé** | `IntensityTarget.eventId` (base `speed_fraction`), `ExercisePrescription.restMode` (`RestMode` : `passive`, `walk`, `jog`) ; `heart_rate_fraction` retiré d'`IntensityBasis`. |
| R21 | `AttemptResult` sans cause d'échec ; `EventDayRequest.done` ne porte pas les tours déjà faits d'une épreuve de répétitions. | **Changé en partie** | `AttemptResult.failure` (`AttemptFailure` : `strength`, `technique`, `judging`). Les tours déjà faits d'une épreuve de répétitions ne sont pas ajoutés à `EventDayRequest` : le relecteur classe ce point « peut attendre », et le conseil du jour J d'une épreuve de répétitions (rythme, `PacingSegment`) se calcule avant l'épreuve, pas entre deux tours. Point ouvert pour CA1, qui ajoutera le champ (additif) s'il en a besoin. |
| R22 | `INTEGRATION.md` : `copyWith(otherSports: const [])` lève une erreur de type à l'exécution. | **Changé** | `INTEGRATION.md` § 6 : `const <OtherSport>[]` et `const <SeasonEvent>[]`. |
| R23 | Affirmations non étayées : `docs/RELECTURES_CQ.md` cité mais absent ; rétrocompatibilité dite « vérifiée en CI ». | **Changé** | Ce document existe. `CONTRAT.md` § 10 et `CHANGELOG.md` ne disent « contrôlé en CI » que pour ce que le contrôle de `claude/ci-cp-b` a réellement passé (tests des trois moteurs 0.1 avec `kalis_core` 0.4.0, tests du paquet). |
| R24 | Le débutant sans matériel se voit « permettre » `t1_serie_lourde` et `t2_leste`. | **Changé** | `tool/parcours_spec.py` : condition commune `TESTABLE` (questionnaire santé « standard » ET niveau ≥ intermédiaire) ; un débutant n'a que `t8_sans_test`. `PARCOURS_V3.md` § 5 dit que « permis » n'est pas « proposé » ; chaque test a une ligne « Prérequis » (`requires`). |
| R25 | `PARCOURS_V3.md` dit les étapes proposées « de la plus facile à la figure », le code dit l'inverse (ordre de la base). | **Changé** | Note de la question `skills` et note du champ `currentExerciseId` : « variantes de la figure dans l'ordre de la base, puis la figure elle-même ». |
| R26 | « On pose moins » alors que le débutant voyait 20 questions ; « Trois questions rapides » pour 4 ; le code `other_sport` n'est pas un code du contrat. | **Changé** | `PARCOURS_V3.md` § 2 : un débutant voit 16 à 18 questions à la création selon sa discipline (16 en forme générale, une de moins qu'avec le parcours G6) ; le tableau par discipline est calculé par le générateur. Écran `recuperation` : « Quelques questions rapides ». `questionnaire.dart` (`QuestionOption.code`) et note de `outside_load` : les codes d'une question composite ne sont pas tous des codes du contrat. |
| R27 | Chiffres sans source : « 5 à 10 % » de gain par apprentissage ; « ±1 répétition jusqu'à 10, ±2 au-delà ». | **Changé** | `PARCOURS_V3.md` § 5 : « 5 à 10 % » est rattaché à `ploutzsnyder2001` et dit « repère, pas une règle » ; `t4_reps_max` : « estimation de ce lot : aucune étude de fiabilité lue ». |
| R28 | Série d'estimation : « 2 à 6 répétitions » à un endroit, « 3 à 6 » à un autre. | **Changé** | `t1_serie_lourde` : la série test vise 3 à 6 répétitions ; l'incertitude de ±5 % vaut pour une série au maximum « jusqu'à 6 répétitions » (ce que calcule `estimateOneRm`). Les deux phrases ne se contredisent plus. |
| R29 | L'en-tête de `contracts_spec.py` annonce encore « nouvelles valeurs d'enum en fin de liste ». | **Changé** | En-tête réécrit : énumérations d'avant 0.4.0 fermées, énumérations de 0.4.0 ouvertes. |

## 2. Relecture « débutant pressé » (D1 à D37)

Le relecteur n'a lu que `docs/PARCOURS_V3.md`. Sauf mention contraire, les changements sont dans
`tool/parcours_spec.py`, d'où `docs/PARCOURS_V3.md` et `data/parcours_v3.json` sont générés. Résultat d'ensemble : un
débutant voit 16 à 18 questions à la création selon sa discipline (20 avant) : aucune de récupération, et du schéma 3
seulement celles que sa discipline rend nécessaires (`PARCOURS_V3.md` § 2).

| N° | Remarque | Suite | Ce qui a été fait, ou pourquoi non |
| --- | --- | --- | --- |
| D1 | L'accueil promet « quelques questions » alors qu'il y en a 20. | **Changé en partie** | Écran `accueil` : « Quelques minutes de questions… ». Un débutant voit 16 questions à la création au lieu de 20. La barre de progression n'est pas décrite dans le parcours : affichage à la charge du lot CU. |
| D2 | `height` : obligatoire, sans effet sur le programme, unité non dite. | **Changé en partie** | Texte : « Ta taille, en cm ? ». La question reste obligatoire : `heightCm` est un champ obligatoire du schéma 2, le rendre facultatif serait une rupture de contrat. Recommandation au propriétaire (`PROFIL_V3.md`, facteur `taille`). |
| D3 | `secondaries` : obligatoire, avec des pourcentages ; c'est l'écran où le débutant quitte. | **Expliqué** | Décision du propriétaire D3.2 : 1 à 2 disciplines secondaires. Autoriser 0 secondaire est une recommandation au propriétaire. |
| D4 | `training_age` répète `experience_level` et n'a pas de case « je commence ». | **Changé** | `training_age` n'est plus posée à un débutant (condition `experience` ≥ intermediate). |
| D5 | `movement_levels` : niveau demandé sur des mouvements jamais faits. | **Changé en partie** | Question gardée (décision D3.5), 4 mouvements au plus pour un débutant. Un seul bouton en haut : « Je ne sais pas, on verra ensemble ». |
| D6 | `sleep`, `stress`, `outside_load` : trois questions de vie privée avant le premier exercice. | **Changé** | Les trois questions portent `deferWhen` : pour un débutant, elles ne sont pas posées à la création mais proposées après la première semaine (`deferredQuestions`). |
| D7 | `guidance_mode` : choix demandé avant d'avoir un programme. | **Expliqué** | Décision du propriétaire D3.7 : la question reste à la création. |
| D8 | `health_screening` compte pour une question mais c'est un questionnaire entier ; sa taille n'est pas annoncée. | **Changé** | Le questionnaire L13 est inchangé (`PARCOURS_V3.md` § 1). La convention de compte est écrite au § 2 : un éditeur compte une fois. Note de `health_screening` : Koach annonce la taille du questionnaire avant de commencer. |
| D9 | `discipline` : « discipline », « mode street », « streetlifting », « calisthénie » sont incompris. | **Changé** | Note de `discipline` : une ligne d'explication en mots courants sous chaque choix ; le mode street est rangé à part, sous « Je pratique déjà le street workout ». Texte : « Tu veux faire quoi, surtout ? ». |
| D10 | `secondaries` : la phrase de Koach a l'air facultative, « dosage » fait penser à un médicament. | **Changé en partie** | Écran `dosage`, Koach : « Choisis une ou deux autres activités à ajouter, et la place que tu leur donnes. » La réponse « rien d'autre » suppose 0 secondaire : décision D3.2 (voir D3), recommandation au propriétaire. Le titre de la question garde le mot « dosage », qui est celui de l'application depuis G6. |
| D11 | Écran `experience` : « volume » de quoi ? | **Changé** | Koach : « Dis-moi d'où tu pars : je règle la difficulté dessus. » |
| D12 | `training_age` : « sans compter les longues coupures » est flou. | **Changé** | Koach : « Ne compte pas les périodes où tu as arrêté plusieurs mois. » |
| D13 | Le mot « niveau » sert trois fois de suite pour trois choses. | **Changé** | L'écran `niveaux` s'intitule « Ce que tu sais faire » ; `experience_level` : « Globalement, tu te situes où ? » ; `movement_levels` : « Ce que tu fais aujourd'hui sur quelques mouvements ». Le mot « niveau » ne sert plus qu'une fois. |
| D14 | Écran `niveaux` : « fourchette » est flou, « on mesurera » fait craindre un examen. | **Changé** | Koach : « Donne-moi une idée, même vague. Si tu ne sais pas, pas d'examen : on verra tranquillement pendant tes premières séances. » |
| D15 | `body_weight` : « dips », « ta charge », « avec lui » sont obscurs. | **Changé** | Texte : « Ton poids, en kg ? ». Koach : « Aux pompes ou aux tractions, c'est ton propre poids que tu soulèves. Si je le connais, je dose mieux. Personne d'autre ne le voit. » |
| D16 | `outside_load` : « ton corps travaille déjà ? » ne se comprend qu'avec les réponses. | **Changé** | Texte : « Tes journées, c'est plutôt… ». L'autre sport reste dans la même question (quatrième réponse), pas dans une question à part : une seule question, comme le veut `PROFIL_V3.md` (`charge_hors_programme`). |
| D17 | `stress` : « ta vie hors entraînement » et « Chargée, mais ça va » sont confus. | **Changé** | Texte : « En ce moment, tu es stressé ? » ; réponses : Pas vraiment / Un peu / Beaucoup. |
| D18 | `sleep` : 7 h tombe dans deux réponses. | **Changé** | Réponses : Moins de 6 h / Entre 6 et 7 h / Plus de 7 h (7 h juste compris, dit la note). |
| D19 | `guidance_mode` : « Je décide, ou je propose ? » et « ajustements » sont abstraits. | **Changé** | `guidance_mode` : « Quand ton programme doit bouger, on fait comment ? » ; réponses : « Assisté : Koach change ton programme tout seul et te dit pourquoi », « Libre : Koach te propose le changement, c'est toi qui décides ». |
| D20 | `limitations` : la liste « Qu'est-ce qui la réveille ? » est du jargon. | **Changé** | Réponses d'`aggravatedBy` réécrites en gestes simples (« Lever les bras au-dessus de la tête », « M'accroupir, plier les genoux »…). Un débutant ne voit que les six premières réponses et « Courir ou sauter ». Pas de dessin décrit : affichage à la charge du lot CU. |
| D21 | `limitations` : « ménager » fait vieillot, et l'écran répète la question. | **Changé** | Écran `sante`, Koach : « Parlons de ta santé : ce que tu me dis ici me sert à te protéger. » Question : « Tu as mal quelque part, ou une ancienne blessure ? » |
| D22 | `sex` : obligatoire sans effet sur le programme, et on ne dit pas pourquoi on demande. | **Changé** | Champ obligatoire du schéma 2 ; la réponse « Je préfère ne pas le dire » existe. Koach dit maintenant pourquoi : « Ça ne change pas ton programme : ça sert aux repères de classement et aux catégories de compétition. » |
| D23 | `body_weight` : question gênante, explication hors sujet. | **Changé** | « Personne d'autre ne le voit. » ; « Passer » aussi visible que « Valider » (note de la question). La question n'est obligatoire que pour les disciplines au poids du corps. |
| D24 | `stress` : on ne voit pas le rapport avec l'entraînement. | **Changé** | Koach : « Si tu es très stressé, j'espace un peu plus les séances dures. » |
| D25 | `sleep` : même gêne, plus légère. | **Changé** | Koach : « Si tu dors peu, je dose plus doucement. » |
| D26 | Santé : rien ne dit ce que deviennent ces données. | **Changé en partie** | `limitations`, Koach : « … Je ne pose aucun diagnostic. » La phrase « Ça reste sur ton téléphone » n'est pas écrite ici : `kalis_core` ne sait pas où l'application stocke ni sauvegarde ses données (le relecteur la demande « si c'est vrai »). C'est au lot CU de l'écrire, d'après le stockage réel et l'accord santé de G6 (KT-042) ; consigne portée dans `LIVRAISON_CQ.md`. |
| D27 | `birth_year` : on ne dit pas pourquoi. | **Changé** | `birth_year`, Koach : « Il faut avoir 18 ans. Ton âge me sert aussi à rester prudent sur les tests. » |
| D28 | `discipline` : obligatoire, sans « Je ne sais pas, choisis pour moi ». | **Changé** | `discipline`, dernier choix : « Je ne sais pas, choisis pour moi », qui sélectionne la forme générale (`general_fitness`) — une réponse est bien écrite, modifiable ensuite. |
| D29 | `training_age` : aucune case pour « jamais ». | **Changé** | Voir D4 : la question n'est plus posée à un débutant. |
| D30 | `goals` répète l'écran `discipline`, n'a pas de « Passer », et « performance » mène à `events`. | **Changé** | Note de `goals` : « Laisse Koach proposer » (D3.8) en premier, présélectionné pour un débutant — l'écran se valide en un appui ; puis « M'entraîner régulièrement » et « J'ai un chiffre en tête (ex. 10 pompes) ». Texte d'`events` : « Une date en vue (compétition, course, test) ? ». |
| D31 | `availability` : le débutant sait « 2 fois par semaine », pas quels jours. | **Expliqué** | Décision D3.6 : jours précis et durée par jour (note de la question). Question inchangée. |
| D32 | `equipment` : il faut un premier bouton « Rien du tout ». | **Changé** | `equipment` : premier bouton « Rien du tout », qui valide l'écran en un appui (liste vide). |
| D33 | `outside_load` : aucune case pour « un peu des deux », et confusion avec `secondaries`. | **Changé** | Réponse « Debout ou en mouvement (ou un peu des deux) » ; la note dit que « autre sport » n'est pas une discipline du programme. |
| D34 | `limitations` : pas de « non, rien », curseur obligatoire même si c'est ancien, « quel côté ? » pour le dos. | **Changé** | Note de la question : premier bouton « Non, rien » ; « C'est ancien, je ne sens plus rien » écrit 0 sans montrer le curseur ; côté « les deux / au milieu » ; « Je ne sais pas » laisse `aggravatedBy` absent. |
| D35 | `movement_levels` : « Je ne sais pas » mouvement par mouvement, c'est quatre appuis de trop. | **Changé** | Un seul bouton pour tout l'écran, en haut. |
| D36 | Ordre des écrans : santé évoquée deux fois, `recuperation` arrive quand on croit avoir fini. | **Changé** | Pour un débutant, l'écran `recuperation` n'est plus montré à la création (ses quatre questions portent `deferWhen`, dont `body_weight_goal` depuis l'audit du 03/10/2026), ni `preferences`. L'ordre des autres écrans est inchangé (santé avant `mode`). |
| D37 | « On mesurera ensemble » cache un test à la première séance, jusqu'à une série lourde. | **Changé** | Koach : « pas d'examen ». Un débutant n'a que `t8_sans_test` (calage au fil des séances, aucun effort maximal). |

## 3. Relecture « coach d'élite » (E1 à E74)

Les champs cités sont ceux de `tool/contracts_spec.py` (bloc 0.4.0), décrits dans `docs/TYPES.md` ; les questions et
les tests, ceux de `docs/PARCOURS_V3.md` ; les facteurs, ceux de `docs/PROFIL_V3.md`. L'ordre est celui du rapport
(E10bis et E11 y précèdent E10).

| N° | Remarque | Suite | Ce qui a été fait, ou pourquoi non |
| --- | --- | --- | --- |
| E1 | Aucune question sur la charge d'entraînement actuelle. | **Changé** | Question `recent_training` (niveau ≥ avancé) : `recentTraining` (type `RecentTraining` : `exerciseId`, `sessionsPerWeek`, `hardSets`) et `currentPhase`. Code de raison `plan.recent_load`. Facteur `charge_actuelle` dans `PROFIL_V3.md`. Forme réduite pour l'intermédiaire : voir E18. |
| E2 | `training_age` porte sur l'entraînement en général, pas sur la discipline. | **Changé** | Texte : « Depuis combien de temps tu pratiques régulièrement ta discipline principale ? » ; documentation de `TrainingAge` et facteur `anciennete` alignés. |
| E3 | Les records ne disent pas s'ils sont au standard de compétition. | **Changé** | `Benchmark.competitionStandard` (oui / non / absent), demandé en streetlifting ou si une compétition de force est déclarée. Les tentatives ne se fondent que sur des records au standard. |
| E4 | Poids de corps prévu le jour de la compétition inconnu. | **Changé** | `SeasonEvent.plannedBodyWeightKg`, pré-rempli avec le poids du profil ; aucune question sur la méthode. Le parcours le propose pour une compétition de force. |
| E5 | Historique de tentatives : rien à demander. | **Expliqué** | Aucune demande : les tentatives se lisent dans le journal (`SessionRecord.eventId`, `SetRecord.attemptIndex`). |
| E6 | Deux séances par jour non exprimables (`DaySlot`). | **Expliqué** | Non retenu ; le relecteur propose lui-même de laisser en l'état pour la v3. Point ouvert. |
| E7 | `secondaries` impose 1 à 2 disciplines ; à 8 semaines d'une compétition on veut 100 % spécifique. | **Changé** | Décision du propriétaire D3.2 gardée pour le profil ; recommandation au propriétaire (voir D3). La règle « près d'une échéance principale, la phase prime sur le dosage des disciplines secondaires » est écrite dans `CONTRAT.md` § 13 et `PROFIL_V3.md` § 6. |
| E8 | Pas de performance de référence sur l'épreuve de répétitions elle-même. | **Changé** | `SeasonEvent.bestSeconds`, `bestTotalReps`, `bestDate` (épreuve de répétitions, test perso, course) ; `Benchmark` `max_reps` admet `seconds` et `externalLoadKg` ; nouvelle nature `reps_for_time`. |
| E9 | Format d'épreuve : repos entre postes, manches, règle de coupure, format révélé le jour même. | **Changé en partie** | `EventStation.restAfterSeconds`, `SeasonEvent.heats`, `restBetweenHeatsSeconds`, `formatKnown`. `EventStation.breakRule` n'est pas ajouté : `unbroken` dit le cas qui change la préparation (série indivisible) ; les autres règles de coupure (pénalité, reprise au début) varient d'un organisateur à l'autre et aucun règlement lu ne les fixe (`PROFIL_V3.md`, `competition`). Point ouvert pour CA1 (conseil de rythme du jour J). |
| E10bis | Profil de fatigue : à mesurer, pas à demander (renvoi à E43). | **Changé** | Test `t10_series_repetees` (voir E43). |
| E11 | Sport de combat, collectif, raquette : régions sollicitées non demandées. | **Changé** | Question `outside_load`, champ `regions` : posé pour tous les sports sauf course, vélo, natation et escalade ; sport de combat pré-coché « tout le corps ». |
| E10 | `SkillState` ne dit pas depuis quand l'athlète est à l'étape. | **Changé** | `SkillState.atStepSince` (`StepTenure`, 4 tranches), qui initialise `SkillProgress.weeksAtStep` ; code de raison `plan.skill_plateau` pour plus de 6 mois à la même étape. |
| E12 | Exposition actuelle en bras tendus inconnue. | **Changé** | Couverte par `recent_training`, déplacée en fin d'écran `niveaux`, après `benchmarks` et `skills` : ses lignes pré-remplies comprennent les figures qui viennent d'être saisies ; « Pas en ce moment » écrit 0. |
| E13 | Support de la figure (sol, parallettes, barre, anneaux) non précisé. | **Expliqué** | Le relecteur ne le demande que si le catalogue n'a pas un exercice par support. Il en a (`cs-planche-parallettes`, `cs-planche-anneaux`, `cs-front-lever-anneaux`) : le support se choisit avec l'étape. Aucun champ ajouté. |
| E14 | Priorité entre figures non déclarée. | **Changé** | L'ordre de `skills` est l'ordre de priorité (documentation du champ dans le contrat, note de la question). |
| E15 | Mobilité prérequise des figures (renvoi à E55). | **Expliqué** | Voir E55 : auto-contrôles non retenus dans ce lot, point ouvert pour CP1. |
| E16 | `BodyZone` n'a ni bras ni avant-bras. | **Expliqué** | Énumération d'avant 0.4.0, fermée. Libellés à l'écran : « Coude / avant-bras », « Épaule / bras » (note de `limitations`). L'ajout de valeurs est une décision du propriétaire. |
| E17 | L'objectif « prendre du muscle » ne s'exprime pas. | **Changé** | Question `emphasis` (`TrainingEmphasis` : `muscle`, `strength`, `both`), posée dès que la musculation est au programme ; `specialization` ouverte dès le niveau intermédiaire en musculation (« Une zone à développer en priorité ? »). |
| E18 | Volume actuel de l'intermédiaire (forme réduite de E1). | **Expliqué** | `recent_training` n'est posée qu'à partir du niveau avancé : avant, démarrer prudemment et laisser le moteur dynamique apprendre la tolérance suffit (`PROFIL_V3.md`, `charge_actuelle`). Le relecteur juge lui-même ce choix acceptable. |
| E19 | Volume de course actuel inconnu. | **Changé** | Question `running_base` : `enduranceBase` (type `EnduranceBase` : `weeklyVolume`, `sessionsPerWeek`, `longRun`), posée si le cardio est au programme ou si une course est en échéance. Pas de saisie en minutes. |
| E20 | `events` est cachée au débutant qui prépare son premier 10 km. | **Changé en partie** | Condition élargie au cardio (principal ou secondaire) ; texte : « Une date en vue (compétition, course, test) ? » ; « Non » écrit une liste vide. La question n'est pas posée à tous : un débutant sans cardio ni objectif de performance ne la voit pas. |
| E21 | Profil du parcours de course (plat, vallonné, trail). | **Expliqué** | Non retenu dans ce lot ; aucun champ ajouté. Point ouvert. |
| E22 | Montre, fréquence cardiaque : le moteur ne sait pas à quoi prescrire. | **Expliqué** | `heart_rate_fraction` est retiré d'`IntensityBasis`. La fréquence cardiaque maximale n'est pas demandée : allures en part d'une vitesse mesurée ou à l'effort perçu ; prescriptions à la fréquence cardiaque laissées au lot CP2 (`PROFIL_V3.md`, `base_endurance`). Point ouvert. |
| E23 | Vérifier que l'éditeur de records propose la course en premier quand le cardio est principal. | **Changé** | Note du champ `exerciseId` de `benchmarks` : mouvements de compétition de la discipline d'abord ; quand le cardio est la discipline principale, la course d'abord (record en `time_trial`). |
| E24 | `experience_level` : critères mélangés pour « Avancé » et « Élite ». | **Changé** | Élite : « Je fais de la compétition au niveau national ou au-dessus ». Note : le moteur recale ensuite le niveau sur les performances, à dire au récapitulatif. |
| E25 | `training_gap` : tranche haute trop large, cas « allégé » absent, condition trop étroite. | **Changé** | `TrainingGap` : `none`, `reduced`, `under_3_weeks`, `weeks_3_to_10`, `weeks_10_to_26`, `months_6_to_24`, `over_2_years`. Libellé du débutant : « Je découvre, ou presque » (plus de « je reprends de zéro ») ; note d'`experience_level` : un ancien pratiquant qui reprend choisit son niveau d'avant, et `training_gap` dit depuis quand il a arrêté. |
| E26 | « Tes records » appelle le record de toujours ; la date est souvent oubliée. | **Changé en partie** | Texte : « Tes meilleures performances récentes » (3 derniers mois de préférence) ; `bodyWeightKg` pré-rempli, à confirmer ; raccourcis de saisie de la date (« ce mois-ci », « il y a 1 à 3 mois ») ; un record sans date ou de plus de 6 mois est gardé mais retesté. La date reste facultative : l'exiger ferait inventer une date à qui l'a oubliée (D5.8), et le moteur traite l'absence comme « ancien ». |
| E27 | `body_weight` passable en mode street. | **Changé** | `requiredWhen` : obligatoire en mode street, streetlifting, street workout et calisthénie (`isRequired`). |
| E28 | `limitations.discomfort` « en ce moment » : une tendinopathie est à 0 au repos. | **Changé** | `Limitation.effortDiscomfort` (0 à 10) : « Quand elle se réveille pendant l'effort, elle monte à combien ? ». `discomfort` (schéma 2) reste. Le prérequis de `t3_max_direct` lit la gêne au repos ou à l'effort. |
| E29 | `aggravatedBy` : il manque les familles du streetlifting. | **Changé** | `AggravatingMovement` : `deep_shoulder_extension`, `axial_loading`, `elbow_lockout`, `explosive_pull` ; `push_support` libellé « Pousser (pompes, haut du dips) » ; `aggravatedBy` : 14 au plus. |
| E30 | `weak_points.kind` : libellés ambigus selon le mouvement. | **Changé** | Note de `weak_points` : réponses filtrées et libellées par mouvement, codes inchangés. Libellés écrits pour la traction et le muscle-up ; ceux du dips et du squat sont à écrire par CU sur le même modèle. |
| E31 | `specialization` entre en conflit avec une échéance principale ; « 1 cible » ou liste ? | **Changé en partie** | Note de `specialization` : une seule cible ; avec une échéance principale, la question devient « Lequel de tes mouvements de compétition est le plus en retard ? », le reste est entretenu (`maintain`), et le plan de saison prime. La durée « jusqu'à nouvel ordre » n'est pas ajoutée : passer la durée laisse le moteur la fixer. |
| E32 | `skills` n'apparaît que si la calisthénie est au profil. | **Changé** | Condition élargie au streetlifting et au CrossFit (muscle-up, équilibre, L-sit proposés d'abord). |
| E33bis | `events` : date exacte obligatoire, alors qu'elle n'est souvent pas publiée. | **Changé** | `SeasonEvent.dateApproximate` : choisir un mois, la date est fixée au 15. |
| E34 | `body_weight_goal` : pas de grandeur, condition incomplète. | **Changé** | `targetBodyWeightKg` (seulement avec `lose` ou `gain`, contrôlé dans `custom_validation.dart`) ; condition élargie au streetlifting, au street workout et à la calisthénie. |
| E35 | `outside_load` : on ne sait pas si l'autre sport passe en premier. | **Changé** | `OtherSport.mainSport` : si oui, pas de séance lourde des régions concernées la veille. |
| E36 | `movement_levels` puis `benchmarks` : double saisie (renvoi à E50). | **Changé** | Voir E50. |
| E37 | `sex` : « aucun effet » alors qu'il fixe les catégories de compétition. | **Changé** | Note de `weightClassKg` : les préréglages listent les catégories des deux sexes quand le sexe n'est pas renseigné. La ligne « Ce que ça change » de `sex` cite les repères de rang et les catégories de compétition. |
| E38 | Maximum direct au muscle-up lesté : sauts trop grands, règle d'arrêt contradictoire, pas de prérequis. | **Changé** | `t3_max_direct` : prérequis de 5 muscle-ups stricts et aucune gêne coude, épaule, sternum ; sauts en kilos de lest (+5, +2,5, +1,25 kg) pour tous les mouvements lestés ; muscle-up : tout échec arrête le test, 4 essais lourds au plus ; un échec technique arrête toujours le test. |
| E39 | `t2_leste` : deux marches d'échauffement, trop peu pour un lest lourd. | **Changé** | Lest visé supérieur à 40 % du poids de corps : montée en quatre marches (poids du corps × 5, 40 % × 3, 65 % × 2, 85 % × 1). |
| E40 | Squat : l'équation ne doit pas s'appliquer à la charge totale. | **Changé** | `t1_serie_lourde` : l'équation porte sur la charge de la barre (squat, développé, soulevé de terre : jamais le poids du corps). `t2_leste` : charge totale seulement pour les exercices qui ont une fraction du poids du corps au catalogue (`sl-squat-competition` n'en a pas). |
| E41 | `t2` et `t1` : prérequis absents de la condition machine. | **Changé en partie** | Les tests exigent le niveau intermédiaire (`TESTABLE`). Le prérequis par mouvement est écrit (`requires` : 8 répétitions strictes, matériel au profil), mais `eligibleTests` ne lit ni `movementLevels` ni le matériel : ce tri par mouvement est laissé à l'application et aux moteurs (`PARCOURS_V3.md` § 5). |
| E42 | Une seule répétition avec réserve : maximum sous-estimé. | **Changé** | Note de `benchmarks` : une barre unique « avec de la réserve » sert aux charges d'entraînement, pas au choix des tentatives. `PROFIL_V3.md` § 5 dit le biais prudent. |
| E43 | Tests manquants : répétitions en temps limité et séries répétées. | **Changé** | `t9_reps_temps` et `t10_series_repetees`, permis en sets & reps, en street workout ou avec une compétition de répétitions ; plus tard, jamais pour un débutant ; classés « usage d'entraîneur ». |
| E44 | Test manquant : muscle-up au poids du corps. | **Changé** | `t4_reps_max` couvre le muscle-up : série maximale sans élan ; moins de 5 répétitions strictes, pas de lest. |
| E45 | `t5_maintien_max` : un seul essai sur un maintien court ; équilibre. | **Changé en partie** | Maintien court (moins de 15 s) : 3 essais, on garde le meilleur essai propre ; équilibre au mur tant que la sortie n'est pas acquise ; incertitude « jusqu'à ±25 % sur 6 secondes ». La règle d'étape à afficher (moins de 5 s, plus de 20 à 30 s) n'est pas écrite : réglage laissé aux moteurs. |
| E46 | Course : un 3 km prédit un 10 km trop rapide à faible volume. | **Changé en partie** | `t7_course_chrono` : 5 km préféré ; prédiction « provisoire », au moins ±4 % à faible volume hebdomadaire (`PROFIL_V3.md` § 5). `t6_course_6min` est inchangé : rien n'y est dit sur la vitesse maximale aérobie. |
| E47bis | `height` : aucun effet, obligatoire. | **Expliqué** | Champ obligatoire du schéma 2. Recommandation au propriétaire : le rendre facultatif à la prochaine évolution non additive (voir D2). |
| E48 | `sleep` et `stress` au profil font doublon avec le bilan de séance. | **Changé en partie** | Gardées comme valeurs de départ (`PROFIL_V3.md` § 1 règle 3, facteurs `sommeil` et `stress`) : dès que les bilans existent, ce sont eux qui font foi. Le nombre de bilans (6 à 8) et la règle « ne redemander qu'à ceux qui ne remplissent pas le bilan » ne sont pas écrits : réglages des moteurs. |
| E49 | `weak_points` : à poser après les records, sur les mouvements saisis. | **Changé** | Note de `weak_points` : posée après les records, sur les mouvements saisis. |
| E50 | L'avancé saisit des fourchettes, puis ses valeurs exactes sur les mêmes mouvements. | **Changé** | `benchmarks` est placée avant `movement_levels`, qui ne demande plus que les mouvements sans record ; la note du champ `exerciseId` ne renvoie plus à `movementLevels`. |
| E51 | `specialization` quand une échéance principale existe (renvoi à E31). | **Changé en partie** | Voir E31. |
| E52 | `preferences` : « aimés » ne doit jamais déplacer un mouvement de compétition. | **Changé** | Note de `preferences` et `PROFIL_V3.md` § 6 point 4 : un exercice aimé ne déplace jamais un mouvement de compétition ni son travail d'assistance ; les préférences départagent des exercices équivalents. |
| E53 | Revue des facteurs : la charge d'entraînement actuelle n'est pas examinée. | **Changé** | `PROFIL_V3.md` : facteurs `charge_actuelle` et `base_endurance` ajoutés (§ 2 et § 3). |
| E54 | Revue des facteurs : standard d'exécution absent. | **Changé** | `PROFIL_V3.md`, facteur `tests_records` : `competitionStandard`. |
| E55 | Mobilité : verdict « déduite » fondé sur le mauvais critère ; proposer des auto-contrôles. | **Changé en partie** | `PROFIL_V3.md` § 4 : le critère est corrigé (accès à une position, pas prédiction de blessure). Les auto-contrôles par figure ne sont pas retenus dans ce lot (aucun protocole vérifié, une question de plus par figure) : point ouvert pour CP1. |
| E56 | Sexe : `roberts2020` rapporté de façon incomplète. | **Changé** | `PROFIL_V3.md`, `sexe` : gains relatifs de force du haut du corps plus grands chez les femmes ; effet rangé dans les attentes de progression, pas dans le programme. |
| E57 | `androulakis2020` ne dit pas ce qu'on lui fait dire ; citer Bickel 2011 et Spiering 2021. | **Changé en partie** | `PROFIL_V3.md`, `specialisation` : texte corrigé (dose minimale pour progresser, pas entretien) ; niveau de preuve « usage d'entraîneur ». Les deux références proposées ne sont pas citées : non vérifiées dans ce lot. |
| E58 | Antécédents : « fenêtre de 12 mois (durée démontrée) » vient du football. | **Changé** | `PROFIL_V3.md`, `antecedents` : « choix raisonné, par analogie avec `hagglund2006` ». |
| E59 | Reprise des figures après un mois d'arrêt : transposition du tendon d'Achille. | **Changé** | `PROFIL_V3.md`, `interruption` : règle marquée « choix raisonné » (analogie avec `kubo2012`). |
| E60 | Moment de la journée : utile au compétiteur (heure de passage). | **Expliqué** | Écarté au profil ; l'heure de passage n'est pas dans l'échéance en 0.4.0 (`PROFIL_V3.md` § 4). Point ouvert pour CP1. |
| E61 | `wilson2012` : interférence plus marquée avec la course qu'avec le vélo. | **Changé** | `PROFIL_V3.md`, `charge_hors_programme` : ajouté ; la nature du sport sert au placement, pas à un coefficient. |
| E62 | `sommeil`, `stress` gardés contre la règle (c) (renvoi à E48). | **Changé en partie** | Voir E48 : le verdict est « posée comme valeur de départ » ; `PROFIL_V3.md` dit que la règle (c) la condamnerait à strictement parler. |
| E63 | Affûtage des épreuves de répétitions et du freestyle : réserve absente. | **Changé** | `PROFIL_V3.md`, `competition` : réserve ajoutée, classée « usage d'entraîneur ». |
| E64 | Périodisation par mouvement impossible. | **Changé** | `SeasonPhase.overrides` (type `PhaseOverride` : `exerciseId`, `kind`, `volumeFactor`, `intensityFactor`), mouvements distincts. Non recopié dans `BlockIntent`, qui renvoie à la phase par `seasonPhaseIndex`. |
| E65 | Jour J : pas de montée d'échauffement ni d'objectif de classement. | **Changé** | `LiftAttempts.warmup` (type `WarmupStep`) ; `EventDayRequest.objective` (`secure_total`, `max_total`, `record`) et `targetTotalKg`. |
| E66 | `PacingSegment` identifié par l'exercice seul : ambigu dans un circuit. | **Changé** | `PacingSegment.stationIndex` et `round`. |
| E67 | Épreuve de répétitions : champs manquants (renvoi à E8 et E9). | **Changé en partie** | Voir E8 (changé) et E9 (`breakRule` non ajouté). |
| E68 | Circuit prescrit à l'entraînement : pas d'objet de groupe. | **Changé** | `GroupSpec` (`groupId`, `format`, `rounds`, `timeCapSeconds`, `targetSeconds`, `restBetweenRoundsSeconds`…) dans `DayPrescription.groups` et `SessionPlan.groups` ; « sans lâcher » : `ExercisePrescription.unbroken`. |
| E69 | Maintiens : pas de temps total à accumuler. | **Changé** | `SetTechnique.totalSecondsTarget` (`skill_practice`, `isometric_hold`). |
| E70 | Freestyle : échéance vide. | **Changé en partie** | `SeasonEvent.elements` (figures prévues), `heats`. Ni tours du passage, ni format de groupe `flow` : le freestyle est jugé sur un enchaînement libre, dont la préparation relève de la pratique de figure (`skill_practice`, `totalSecondsTarget`) et des groupes existants (`circuit`) ; aucun règlement lu ne fixe la durée ou le nombre de tours. Point ouvert pour CP1, qui ajoutera un format (énumération de 0.4.0, ouverte) s'il en a besoin. |
| E71 | `StepCriterion` : pas d'état de départ. | **Changé** | Voir E10 : `SkillState.atStepSince`. |
| E72 | Deux séances par jour (renvoi à E6). | **Expliqué** | Voir E6 : non retenu, point ouvert. |
| E73 | Course : récupération active et allure cible de l'échéance. | **Changé** | `ExercisePrescription.restMode` ; `IntensityTarget.eventId` avec `speed_fraction`. |
| E74 | Vitesse de barre non exprimable. | **Expliqué** | Non retenu : peu d'utilisateurs équipés (le relecteur propose lui-même de laisser). |

## 4. Points ouverts et recommandations au propriétaire

### Recommandations au propriétaire (décisions en place, non modifiées par ce lot)

- **Taille** (D2, E47bis) : `heightCm` est obligatoire dans le schéma 2 et n'a aucun effet sur le programme. La
  rendre facultative, ou la retirer, à la prochaine évolution non additive du contrat.
- **Zéro discipline secondaire** (D3, D10, E7) : la décision D3.2 impose 1 à 2 secondaires. Les deux relecteurs du
  parcours demandent de pouvoir répondre « rien d'autre » ; c'est l'écran où le débutant dit qu'il quitte. En
  attendant, la phase prime sur le dosage près d'une échéance principale (`CONTRAT.md` § 13).
- **Mode assisté ou libre** (D7) et **niveaux par mouvement du débutant** (D5) : décisions D3.7 et D3.5 gardées. Le
  débutant demande de les reporter après la première séance.
- **Jours d'entraînement** (D31) : décision D3.6 gardée (jours précis). Le débutant demande « combien de fois »
  d'abord, puis « peu importe, propose-moi ».
- **Bras et avant-bras** (E16) : `BodyZone` est une énumération d'avant 0.4.0, fermée. Y ajouter des valeurs est une
  rupture pour les moteurs 0.1 : décision du propriétaire.

### Points laissés aux lots suivants (ajouts additifs possibles, à leur initiative)

- **CP1** : auto-contrôles de mobilité par figure (E15, E55) ; heure de passage en compétition (E60) ; format de
  groupe pour un enchaînement de freestyle (E70).
- **CA1** : tours déjà faits le jour d'une épreuve de répétitions (R21) ; règle de coupure d'un poste (E9).
- **CP2** : fréquence cardiaque — ni fréquence maximale au profil, ni prescription à la fréquence cardiaque, ni
  question « montre, cardiofréquencemètre » dans le matériel (E22) ; profil du parcours de course (E21).
- **CU** : phrase sur le lieu de stockage des données de santé (D26) ; barre de progression (D1) ; dessin de la
  carte du corps (D20) ; libellés des points faibles du dips et du squat sur le modèle de la traction (E30).
- **Non retenus** : deux séances par jour (E6, E72), vitesse de barre (E74).
- **Réglages des moteurs**, non écrits dans le contrat : règle d'étape à afficher pour un maintien (E45), nombre
  de bilans de séance à partir duquel ils remplacent le sommeil et le stress déclarés (E48), vitesse maximale
  aérobie du test de 6 minutes (E46).
- **Références proposées par le coach** (E57, et E1 pour l'individualisation du volume) : non citées, car non
  vérifiées. `PROFIL_V3.md` s'en tient à « usage d'entraîneur ».
- **Durée des tests de propriétés** (R11) : lue au contrôle de la CI (paquet entier : moins de 3 minutes, pour
  un délai de 90).
