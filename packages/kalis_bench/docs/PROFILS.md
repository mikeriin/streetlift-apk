# Profils types du banc

27 profils dans `profiles/` (17 street, 10 des autres disciplines), générés par `tool/gen_profiles.py` (`--check` vérifie qu'ils sont à jour). Un profil est **gelé pendant un calibrage** : on ne le modifie pas pour faire passer un programme (PIPELINE_CP.md §7).

## Format (schéma 1 du banc)

Sur-ensemble du profil d'athlète de `kalis_core` :

| Champ | Contenu |
|---|---|
| `key`, `group` (`street` ou `autres`), `title`, `summary` | identité du profil, résumé en une phrase lisible par un coach |
| `level` | `beginner`, `intermediate`, `advanced`, `elite` |
| `trainingAgeMonths` | ancienneté d'entraînement structuré |
| `core` | objet du profil `kalis_core` (sexe, année de naissance, taille, poids, disciplines, disponibilités, lieux, matériel, pas de charge, exercices aimés ou non, questionnaire santé, exercices connus ou impossibles) |
| `records` | tests et records exacts (`exerciseId`, `measure`, `value`, distance, ancienneté du test) ; valeur 0 = mouvement non acquis |
| `events` | échéances (`kind` compétition ou test, `weeksOut`, `priority` A/B, `format`, cibles par mouvement) |
| `goals` | objectifs datés hors échéance |
| `weakPoints` | points faibles (mouvement ou groupe, note) |
| `injuries` | gênes et antécédents (zone, côté, gêne sur 10, statut `current` ou `history`, ancienneté en mois) |
| `recovery` | sommeil (heures, qualité), stress, travail physique, déficit énergétique, autres sports (séances, minutes, intensité) |
| `break` | semaines d'arrêt avant le programme |
| `specialization` | mouvements prioritaires, mouvements à entretenir |
| `simulation` | réglages de l'athlète simulé (champs d'`AthleteSpec` de `kalis_adapt`) |
| `expectations.text` | attentes de coach, en phrases, avec les principes du référentiel |
| `expectations.checks` | contrôles calculables (types ci-dessous) |

Types de contrôle : `min_frequency`, `max_frequency`, `has_taper`, `test_at_event`, `relief_every`, `min_group_sets`, `max_group_sets`, `min_weekly_minutes`, `max_session_minutes`, `pattern_present`, `forbid_patterns`, `forbid_exercises`, `forbid_joint_stress`, `format_present` (codes de technique ou de format d'enchaînement : `top_set_backoff`, `cluster`, `rest_pause`, `drop_set`, `wave`, `emom`, `amrap`, `rounds`, `ladder`, `superset`, `circuit`…), `load_prescribed`, `heavy_exposure`, `min_rir_first_weeks`, `max_exercise_level`, `priority_share`, `weekly_sets_between`, `short_rest_share`, `straight_arm_days_max`, `distinct_week_types`, `weeks_kind_present`.

Le profil élite de streetlifting porte des chiffres anonymes, différents de ceux du propriétaire (test `profiles_test.dart`).

## Adaptateur (`lib/src/adapter.dart`)

Seul endroit qui connaît le schéma du profil des moteurs. En 0.1.0 il produit le profil **v2** (celui que lisent `kalis_plan` 0.1.0 et `kalis_adapt` 0.1.0) et liste ce qu'il perd (`AdaptedProfile.lost`) : valeur exacte et date des records, ancienneté, nature et format de l'échéance, points faibles, antécédents sans gêne actuelle, sommeil, stress, travail physique, déficit énergétique, autres sports, coupure, spécialisation. Le rapport affiche ces pertes par profil : c'est une partie de ce que les moteurs 0.1 ne peuvent pas prendre en compte.

`kalis_core` 0.4.0 (lot CQ) sait porter presque tout cela dans le profil v3 (`trainingAge`, `trainingGap`, `sleep`, `stress`, `occupationalLoad`, `otherSports`, `events`, `weakPoints`, `specialization`, `Limitation.since` : `packages/kalis_core/docs/PROFIL_V3.md`). **Branchement par CP1 et CA1** : réécrire `adaptProfile` pour produire le profil v3 quand le moteur le lit, vider `lost` des champs transmis, garder le reste du banc inchangé. Les profils eux-mêmes ne changent pas.
