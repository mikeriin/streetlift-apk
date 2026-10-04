# Contrat de kalis_bench 0.1.2

Banc d'essai du calibrage des programmes (pipeline CP). Dart pur : ni Flutter, ni `dart:io` dans `lib/`, ni horloge, ni hasard hors des graines. Il **lit et appelle** `kalis_core`, `kalis_plan`, `kalis_adapt` par chemin, sans les modifier.

## Ce que le paquet fournit

| Élément | Où | Rôle |
|---|---|---|
| Référentiel scientifique | `docs/REFERENTIEL.md`, `docs/referentiel/R1..R6.md` | 145 principes chiffrés, références vérifiées, traduction du débutant à l'élite |
| Mesures des programmes de référence | `docs/MESURES_REFERENCES.md` | fourchettes agrégées et anonymes |
| Profils types | `profiles/*.json`, `docs/PROFILS.md` | 17 street + 10 autres, avec attentes de coach |
| Critères calculables | `lib/src/safety.dart`, `quality.dart`, `expectations.dart`, `trajectory.dart`, `docs/CRITERES.md` | sécurité (0 violation exigé), qualité, attentes, trajectoires |
| Exports lisibles | `lib/src/export.dart`, `tool/panel_export.py` | programme et trajectoire en français ; export concis pour le panel |
| Rapports | `lib/src/report.dart`, `bin/` | `RAPPORT.md`, `rapport.json`, `programmes/`, `trajectoires/` |
| Panel de coachs virtuels | `docs/PANEL.md`, `docs/grilles/`, `docs/ETALONNAGE_PANEL.md` | protocole, quatre grilles gelées, étalonnage |
| Mesure de départ | `docs/BASELINE_0_1.md`, `docs/baseline/CORRECTIONS_PANEL_0_1.md` | moteurs 0.1 sur tout le banc, défauts priorisés, corrections demandées par le panel |
| Non-ressemblance aux références | `tool/reference_jaccard.py` | à lancer dans une session qui a la clé ; seul le résultat est publié |
| Page de relecture du propriétaire | `tool/relecture/` | source de la page et préparation d'une manche (`docs/PANEL.md`) |

## Entrées et sorties

- `generateProgram(catalog, plan, profil)` → `BenchProgram` (blocs enchaînés jusqu'à l'horizon du profil : échéance, objectif daté, sinon 12 semaines ; 16 au plus).
- `ProgramView` → semaines, séances, exercices avec les grandeurs mesurées.
- `safetyFindings`, `qualityMeasures`, `evaluateChecks` → constats, notes, contrôles.
- `simulateTrajectory` → trajectoire sous `kalis_adapt` (boucle complète), mesures et verdicts ; modèle de vérité A, B ou C (0.1.2).
- `streetCampaignOf`, `streetCampaignMarkdown` → campagne street (0.1.2) : profils street × graines × modèles de vérité × politiques.
- `programMarkdown`, `programJson`, `trajectoryMarkdown`, `coachTrajectoryMarkdown` (programmes au contrat 0.4.0, 0.1.2) → exports.
- CLI : `dart run bin/kalis_bench_cli.dart --rapport <dossier>` (CI) ; `dart run kalis_bench:run --moteur plan|adapt|croisement --profils street|autres|tous --graine <n> --sortie <dossier>`.

## Invariants (testés)

1. Déterminisme : mêmes entrées et même graine → mêmes fichiers à l'octet près (`bench_test.dart`).
2. Pureté : pas d'horloge, de hasard non seedé ni de plateforme dans `lib/` ; dépendances par chemin ; aucun fichier hors du paquet modifié (`purity_test.dart`).
3. Chaque critère de sécurité a un cas construit à la main qui doit être signalé et un cas voisin qui ne doit pas l'être (`safety_test.dart`) ; propriétés sur 10 000 programmes seedés : codes connus, notes entre 0 et 1, aucun critère de hausse sur un programme constant (`properties_test.dart`).
4. Exports en français, sans identifiant technique (`bench_test.dart`).
5. Aucun nom ni extrait des programmes de référence dans le paquet (`purity_test.dart`) ; le profil élite de streetlifting diffère de celui du propriétaire (`profiles_test.dart`).
6. Les 27 profils sont valides pour le contrat de `kalis_core` et connus du catalogue ; chacun a au moins 3 attentes écrites et 4 contrôles (`profiles_test.dart`).

## Évolution

Additive seulement. Les grilles du panel et les profils sont gelés pendant un calibrage ; toute évolution du banc entre deux lots est versionnée (0.y.z) et dite dans `CHANGELOG.md`, avec une nouvelle mesure de départ si un seuil change.
