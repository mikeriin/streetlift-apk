# CI des pistes parallèles du pipeline GP (01/10/2026)

Le pipeline « Génération et progression » a trois pistes (PIPELINE_GP.md §8) :
**application** (lots d'écran, sur `main`, CI `claude/ci-3d` : `docs/CI_GP.md`),
**moteurs** (branche `moteurs`) et **koach** (branche `koach`). Les deux
dernières ne touchent jamais `lib/` : elles construisent des paquets Dart purs
(`packages/<paquet>/`) et leurs outils (`tools/catalog/`, `tools/koach/`).

## Branches

| Piste | Branche de travail | Branche de contrôle | Groupe de concurrence |
| --- | --- | --- | --- |
| moteurs | `moteurs` | `claude/ci-gp-moteurs` | `ci-paquets-refs/heads/claude/ci-gp-moteurs` |
| koach | `koach` | `claude/ci-gp-koach` | `ci-paquets-refs/heads/claude/ci-gp-koach` |

- Les deux branches partent de `main` 6.0.1+95 (10fed1d) + ce commit de mise en
  place (ce fichier, `.github/workflows/ci-paquets.yml`, et `build-apk.yml`
  limité par `branches-ignore` pour qu'aucun build signé ne parte de ces
  branches). Elles **ne sont jamais fusionnées dans `main`** : le lot d'écran
  qui consomme un paquet récupère seulement son dossier, par étiquette
  (`git checkout <étiquette> -- packages/<paquet>`), puis lance toute la CI de
  l'application.
- Un lot de piste pousse ses commits sur sa branche de travail (avance rapide
  seulement ; jamais de réécriture), puis **étiquette** chaque livraison :
  `kalis_core-v0.1.0`, `kalis_plan-v0.1.0`, `kalis_adapt-v0.1.0`,
  `kalis_quest-v0.1.0`, `kalis_koach-v0.1.0` (une correction : `-v0.1.1`…).

## Contrôle

1. Pose l'arbre du lot sur la tête de la branche de contrôle de ta piste
   (`git commit-tree <arbre> -p origin/claude/ci-gp-<piste>`, push en avance
   rapide ; si la branche n'existe pas encore, crée-la depuis ton commit).
2. Le workflow `ci-paquets.yml` contrôle chaque paquet (`dart pub get`,
   formatage, `dart analyze --fatal-infos`, `dart test`, simulateur
   `dart run bin/<paquet>_cli.dart --rapport <dossier>` s'il existe) et les
   tests Python de `tools/koach/tests` et `tools/catalog/tests`
   (`requirements.txt` du dossier installé d'abord).
3. Résultats recommités dans `ci-out/` sur la branche de contrôle
   (`git fetch origin claude/ci-gp-<piste>`, puis lire `ci-out/resultat.txt`,
   `ci-out/packages/packages.txt`, `ci-out/packages/<paquet>.log`,
   `ci-out/packages/<paquet>/` pour les rapports, `ci-out/packages/python.txt`).

Durées : délai du job 90 min. Un simulateur long découpe son rapport (graines
moins nombreuses en CI, campagne complète décrite et lancée en local dans la
session si nécessaire, résultats commités dans `docs/` du paquet).

Mise en place contrôlée par la conversation de pilotage le 01/10/2026 : run 36826528447 vert (« aucun paquet », « aucun outil »), résultats recommités sans relancer le workflow.

Piège constaté : un push qui **crée** la branche de contrôle sur un commit déjà présent dans le dépôt ne déclenche aucun run. La méthode `git commit-tree` crée toujours un commit nouveau, donc elle n'est pas concernée ; ne pousse jamais une branche existante telle quelle sur la branche de contrôle.

## Pipeline de calibrage (CP, 02/10/2026)

Le pipeline « Calibrage des programmes » (`pipeline/cp/PIPELINE_CP.md`) fait
travailler **deux voies en parallèle** sur la branche `moteurs`. Chaque voie a
sa branche de contrôle et donc son groupe de concurrence :

| Voie | Branche de contrôle | Groupe de concurrence |
| --- | --- | --- |
| A | `claude/ci-cp-a` | `ci-paquets-refs/heads/claude/ci-cp-a` |
| B | `claude/ci-cp-b` | `ci-paquets-refs/heads/claude/ci-cp-b` |

Même méthode que ci-dessus (`git commit-tree <arbre> -p origin/claude/ci-cp-<voie>`,
push en avance rapide, résultats dans `ci-out/`). Si la branche n'existe pas
encore, crée-la depuis un **commit neuf** (jamais depuis un commit déjà présent
dans le dépôt : aucun run ne partirait). Rappel : un commit qui ne change que
`ci-out/` ne déclenche aucun run (`paths-ignore`).
