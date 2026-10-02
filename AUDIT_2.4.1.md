# Audit 2.4.1 — Récompenses et niveau après une séance

Date : 24 septembre 2026. Version 2.4.1+50 (2.4.0+49 précédente).

## Périmètre

- Nouveaux : `lib/store_widget.dart`, `test/reward_flow_test.dart`.
- Modifiés : `lib/rewards.dart`, `lib/session_screen.dart` (page Bilan), `lib/home_screen.dart` (`openProgramDay`), `lib/main.dart` (ouverture par rappel), `lib/arsenal_screen.dart`, `lib/levelup.dart`, `lib/game_widgets.dart`, `lib/store.dart` (cache `game`, `_seedJson`), version (`pubspec.yaml`, `kAppVersion`, `test/visual_capture_test.dart`), documents.
- Inchangés : barème d'XP, données, dépendances, workflow, identité de signature (`tools/verify_project.py --signing` : OK, certificat identique).

## Diagnostic

1. **Animation d'XP absente « parfois ».** Le bilan de fin de séance n'était affiché que par l'écran d'origine, après le retour (`if (mounted) checkLevelUp(context)`). L'ouverture par la notification de rappel (`Notif.onOpen`, `main.dart`) poussait la séance sans rien faire au retour : aucun écran de récompenses, bilan conservé en mémoire et affiché plus tard hors contexte. Le même mécanisme dépendait du contexte d'une tuile (Arsenal) reconstruite pendant la séance. Facteur aggravant : le compteur (`TweenAnimationBuilder`, 1,1 s) démarrait dès la construction de l'écran, alors que la fermeture de la séance déclenchait encore la destruction de l'écran, une sauvegarde complète synchrone (`flush` → `exportAll`, un millier de définitions de WOD encodées deux fois) et la reconstruction des onglets ; sur téléphone, ces images longues avalaient le décompte.
2. **Niveau non mis à jour sans relancer l'app.** `appBar: const KTopBar(leading: LevelPill())` : `LevelPill` lit `store.level` sans s'abonner ; instance `const`, jamais reconstruite par le `ListenableBuilder` parent (`Element.updateChild` retrouve le même widget). Même défaut pour `const _Credits()` (Arsenal) et les cartes `const` de l'Aperçu (`WeeklyGoalCard`, `StreakCard`, `MainQuestCard`, `CampaignStrip`, `BossCard`, `SeasonCard`, `SelfCompareCard`). Défaut annexe : `store.game` restait celui de la veille si `progression` était lue en premier après minuit (jour civil partagé).

## Correctifs

- `checkLevelUp(BuildContext, {Future<void>? after})` : inchangé dans son rôle, appelé avec le contexte du navigateur (`NavigatorState.context`, résolu par `Navigator.of`). La page Bilan referme la séance puis l'appelle elle-même avec `ModalRoute.completed` ; le bilan étant consommé une seule fois, les appels au retour de l'accueil et de l'Arsenal restent des filets (niveau gagné hors bilan).
- `openProgramDay(nav, week, day)` partagé par l'accueil et le rappel : historique si fait, séance sinon, vérification au retour par le navigateur.
- `RewardScreen` : chronologie unique sur un `AnimationController` (`_timeline`) ; `_stage()` dérive chaque étape (compteur 0-1 100 ms, bonus dès 500 ms puis +110 ms, cérémonie à 1 000 ms, confettis 0-2 600 ms). Départ après `Future.wait([fin de la transition d'entrée, fermeture de la séance])` puis `endOfFrame`. « Réduire les animations » : valeur 1 immédiate. Aucun `Timer` ; un élément révélé par défilement s'affiche à l'état courant de la chronologie.
- `StoreWidget` : `StatelessWidget` dont l'élément écoute le store (`mount` → `addListener(markNeedsBuild)`, `unmount` → `removeListener`). Aucun widget ajouté à l'arbre : les recherches par type et les clés des tests existants sont intactes.
- `store.game` : recalculé quand l'instance de `progression` change (`_gameSource`). `_backupJson` : définitions des WODs préchargés mémorisées (`_seedJson`).

## Invariants vérifiés par relecture

- `consumeReward` / `consumeLevelUp` consommés une seule fois : aucun double écran quand la page Bilan et l'écran d'origine appellent tous deux `checkLevelUp`.
- Réglage **Célébrations** désactivé : la confirmation SnackBar passe par le `ScaffoldMessenger` racine, atteignable depuis le contexte du navigateur.
- Écran de récompenses fermé avant le départ de la chronologie : `mounted` vérifié après chaque attente ; l'écouteur de statut est retiré à la fin de la transition, dans les deux sens.
- `game_test` (`markSessionDone`, `consumeReward`), `store_test`, `persistence_screen_test` (page Bilan atteinte sans la valider), `ui_refactor_test` (« Terminer la séance » affiché) : chemins inchangés.
- Contrôle syntaxique de tous les fichiers Dart (grammaire tree-sitter) : aucune erreur, avant comme après modification.

## Tests ajoutés (`test/reward_flow_test.dart`)

Pastille de l'accueil, solde de crédits de l'Arsenal, carte d'objectif hebdo et sonde `StoreWidget` (reconstruction puis désabonnement) après un passage de niveau ; bilan affiché après une séance ouverte sans vérification au retour, compteur à +0 XP tant que la séance se referme, décompte réel puis valeur finale ; rappel → séance puis historique ; décompte de zéro au gain complet ; « Réduire les animations » → état final immédiat.

## Passages du workflow

- `python3 tools/verify_project.py --signing` : OK (`validation/2.4.1/project.txt`).
- `python3 -m unittest discover -s tools/tests -v` : 4 tests OK (`validation/2.4.1/python-tests.txt`).

## Non vérifié dans l'environnement de livraison

- `flutter analyze`, `flutter test`, compilation Android : pas de SDK ici ; le workflow reste le point de contrôle.
- Rendu et fluidité du décompte sur téléphone : à vérifier après compilation, séance ouverte depuis l'accueil puis depuis un rappel.
