# Codes de raison ajoutés en 0.4.0 — textes courts de Koach

Les moteurs ne produisent aucun texte : des codes et des paramètres. Voici, pour les 38 codes ajoutés par le lot CQ, un texte court proposé (français, tutoiement, sans promesse de résultat ni allégation médicale, règles L13), à intégrer par l'application avec les textes de `kalis_koach` (lots CU et CI). Données : [`data/reason_texts_fr_0_4.json`](../data/reason_texts_fr_0_4.json). Un paramètre entre accolades est remplacé par sa valeur ; quand c'est un code (phase, technique, cause, facteur), l'application l'affiche avec son libellé français. Un paramètre non utilisé par le texte reste disponible pour « Pourquoi ? ».

| Code | Texte de Koach | Paramètres | Sens |
| --- | --- | --- | --- |
| `plan.season_phase` | On est en phase « {phase} », à {weeksToEvent} semaines de ton échéance. | `phase`, `weeksToEvent` | Le bloc réalise une phase du plan de saison, à tant de semaines de l'échéance. |
| `plan.taper` | Affûtage : moins de volume, mêmes charges. Tu arrives frais dans {daysToEvent} jours. | `volumeFactor`, `daysToEvent` | Affûtage : volume réduit, intensité gardée, avant une échéance. |
| `plan.peak_event` | Toute ta saison est construite pour être en forme ce jour-là. | `eventId` | La saison est construite pour arriver en forme à cette échéance. |
| `plan.undulation` | Aujourd'hui, c'est un jour {stress} : on alterne lourd, moyen et léger dans la semaine. | `stress` | Ondulation : jour lourd, moyen ou léger. |
| `plan.technique` | Technique du jour : {technique}. | `technique` | Technique de série choisie pour cet exercice. |
| `plan.technique_withheld` | Je garde la technique « {technique} » pour plus tard : pas encore le bon moment ({cause}). | `technique`, `cause` | Technique avancée non servie : un prérequis manque (ancienneté, niveau, test, récupération, gêne). |
| `plan.specialization` | Priorité à ta cible pendant {weeks} semaines ; le reste est entretenu. | `target`, `weeks` | Spécialisation : priorité donnée à une cible pendant tant de semaines. |
| `plan.maintenance_volume` | Volume d'entretien pour ce groupe : juste ce qu'il faut pour ne rien perdre. | `muscle`, `weeklySets` | Volume d'entretien du reste pendant une spécialisation ou un affûtage. |
| `plan.skill_step` | C'est ton étape actuelle sur cette figure. | `exerciseId`, `stepIndex` | Étape de la progression d'une figure. |
| `plan.skill_plateau` | Tu es à cette étape depuis longtemps : je change d'approche sur cette figure. | `exerciseId` | Figure bloquée à la même étape depuis longtemps : la méthode change (autre variante, autre dosage). |
| `plan.recent_load` | Premier bloc calé sur ce que tu fais en ce moment : ni trop facile, ni marche trop haute. | `exerciseId`, `sessions` | Premier bloc calé sur la charge d'entraînement actuelle déclarée. |
| `plan.test_scheduled` | Un test est prévu : il me dira où tu en es vraiment. | `testKind` | Test programmé (série d'estimation, maximum, maintien, course). |
| `plan.benchmark_used` | Charge calculée d'après ton test ou ton record. | `exerciseId`, `source` | Charge ou durée calculée d'après un test ou un record du profil. |
| `plan.percent_based` | Charge réglée sur une part de ton maximum. | `pct` | Charge donnée en part du maximum. |
| `plan.recovery_profile` | Je tiens compte de ta récupération ({factor}). | `factor`, `level` | Tient compte d'une réponse de récupération et de vie (sommeil, stress, métier physique, déficit énergétique). |
| `plan.constraint_history` | Zone à ménager : j'avance plus doucement sur les mouvements qui la chargent. | `zone`, `since` | Zone à antécédent : progression plus prudente des mouvements qui la chargent. |
| `plan.concurrent_sport` | Tu fais aussi un autre sport : je place tes séances lourdes à distance. | `sport`, `sessions` | Tient compte d'un autre sport : séances lourdes placées à distance. |
| `plan.training_age` | Volume et rythme réglés sur ton ancienneté d'entraînement. | `band` | Volume, intensité ou techniques réglés sur l'ancienneté d'entraînement. |
| `plan.return_from_gap` | Tu reprends après une coupure : on repart progressivement. | `gap` | Reprise après une interruption : redémarrage progressif. |
| `plan.weak_point` | Exercice choisi pour travailler là où tu bloques. | `exerciseId`, `kind` | Exercice d'assistance choisi pour un point faible déclaré. |
| `plan.event_specific` | Travail spécifique de ton épreuve. | `eventId` | Travail spécifique d'une épreuve (mouvements, enchaînements, durées de la compétition). |
| `adapt.backoff_from_top_set` | Séries allégées calculées sur ta série de tête d'aujourd'hui. | `topLoadKg`, `pct` | Séries allégées calculées sur la série de tête réalisée. |
| `adapt.rir_cap` | Je baisse un peu la charge pour que tu gardes de la réserve. | `rir` | Plafond d'effort atteint : charge abaissée pour garder la réserve prévue. |
| `adapt.test_result` | Test enregistré : ton estimation est à jour. | `exerciseId`, `value`, `standardError` | Résultat d'un test et son incertitude. |
| `adapt.skill_step_up` | Critère tenu : tu passes à l'étape suivante. | `exerciseId` | Critère de passage tenu : étape suivante de la figure. |
| `adapt.skill_step_down` | Aujourd'hui, on revient une étape en dessous pour rester propre. | `exerciseId` | Mauvais jour ou critère perdu : étape plus facile. |
| `adapt.skill_hold` | On reste à cette étape : tes tendons ont besoin de temps. | `exerciseId`, `weeksAtStep` | Étape gardée : critère non tenu, ou durée minimale à l'étape non atteinte (tendons). |
| `adapt.phase_respected` | Je respecte l'intention de la phase en cours. | `phase` | Ajustement limité par l'intention de la phase. |
| `adapt.taper_no_volume` | Affûtage : je n'ajoute rien, on garde les charges. | — | Affûtage : aucun volume ajouté, intensité gardée. |
| `adapt.event_near` | Ton échéance est dans {days} jours : je reste prudent. | `days` | Échéance proche : décisions prudentes. |
| `adapt.attempt_opener` | Ouverture : une barre sûre, pour entrer dans la compétition. | `pct` | Ouverture choisie comme une part du maximum estimé : une barre sûre. |
| `adapt.attempt_next` | Tentative suivante choisie d'après la précédente. | `successProbability` | Tentative suivante choisie d'après la précédente et l'incertitude du maximum. |
| `adapt.attempt_conservative` | Je propose une barre prudente ({cause}). | `cause` | Tentative prudente (incertitude élevée, échec précédent, bilan bas, pesée). |
| `adapt.pacing` | Rythme conseillé pour viser {targetReps} répétitions. | `targetReps` | Stratégie de rythme d'une épreuve de répétitions. |
| `adapt.recovery_profile` | Je tiens compte de ta récupération ({factor}). | `factor`, `level` | Tolérance réglée sur une réponse de récupération et de vie du profil. |
| `adapt.tendon_load` | Je surveille la charge de tes tendons : progression ralentie sur ces appuis. | `zone`, `weeks` | Charge des tendons surveillée : progression en bras tendus ou en appui ralentie. |
| `adapt.technique_executed` | Technique « {technique} » faite comme prévu. | `technique` | Technique de série exécutée telle que prescrite. |
| `adapt.mini_set_stop` | On arrête les mini-séries ici ({cause}). | `cause` | Mini-séries arrêtées (répétitions manquées, plafond atteint, qualité). |

Libellés français des codes passés en paramètre :

- phases (`phase`) : `accumulation` accumulation, `intensification` intensification, `realization` réalisation, `taper` affûtage, `competition` compétition, `transition` transition, `test` test, `deload` décharge, `maintenance` entretien, `reintroduction` reprise progressive ;
- ondulation (`stress`) : `heavy` lourd, `medium` moyen, `light` léger ;
- techniques (`technique`) : `top_set_backoff` série de tête puis séries allégées, `cluster` clusters, `rest_pause` rest-pause, `myo_reps` myo-reps, `drop_set` série dégressive, `isometric_hold` maintien, `accentuated_eccentric` descente accentuée, `contrast` contraste, `wave` vagues, `amrap` maximum de répétitions, `emom` une série par minute, `density` densité, `ladder` échelle, `pyramid` pyramide, `skill_practice` pratique de figure, `for_time` contre la montre ;
- facteurs de récupération (`factor`) : `sleep` sommeil, `stress` stress, `occupational_load` métier physique, `energy_deficit` perte de poids en cours, `other_sport` autre sport ;
- causes d'une technique gardée pour plus tard (`cause`) : `training_age` ancienneté, `level` niveau, `no_benchmark` pas encore de test, `recovery` récupération, `constraint` zone à ménager, `phase` phase en cours ;
- causes d'une tentative prudente (`cause`) : `uncertainty` estimation incertaine, `previous_miss` échec précédent, `readiness` forme du jour, `weigh_in` pesée ;
- causes d'arrêt des mini-séries (`cause`) : `reps_missed` répétitions manquées, `cap` plafond atteint, `quality` propreté.

Ces listes de causes et de facteurs sont des conventions proposées aux moteurs calibrés (CP1, CA1) ; le contrat ne les fige pas (paramètres de type texte).
