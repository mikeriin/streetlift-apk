# Pipeline « Refonte UI et UX » (UI) de Kalis Track — règles

Propriétaire : Gaël. Créé le 10/10/2026 par la conversation de pilotage, à la demande du propriétaire. Cahier : `pipeline/ui/CAHIER_UI.md` (il fait foi sur le contenu) ; décisions : `pipeline/ui/DECISIONS_UI.md` (elles font foi sur tout) ; état : `pipeline/ui/ETAT_UI.md` ; contexte de lancement : `pipeline/ui/LANCEMENTS.md` ; prompts : `pipeline/ui/prompts/<LOT>.txt` ; entrées du propriétaire : `pipeline/ui/inputs/`. Maquettes : lien dans le cahier.

Règles héritées, sauf écart écrit ici : `pipeline/cp/PIPELINE_CP.md` §1 (démarrage), §5 (notifications), §9 (budget, sauvegardes, reprise) et, pour tout ce qui touche à `main`, `pipeline/gp/PIPELINE_GP.md` comme pour la piste A (jamais toucher à la signature, à l'identifiant Android ni aux secrets ; jamais réécrire l'historique de `main` ni de `refonte-ui`). Délégation totale (DECISIONS_CP.md C8) : un lot ne pose aucune question au propriétaire ; il écrit sa recommandation dans sa livraison, la conversation de pilotage décide.

## 1. Lancement et choix du lot

Tu es lancé par la tâche planifiée « Kalis Track — refonte UI (Opus 5.5, effort élevé) ». Plusieurs sessions de cette tâche peuvent tourner **en même temps** (UI1 à UI4).
1. Ton lot est celui de la ligne « Lot : <LOT> » de ton message de lancement. Sans cette ligne (le texte ajouté au lancement n'arrive pas toujours), ton lot est le **premier lot « à faire »** d'`ETAT_UI.md` dont les prérequis sont remplis.
2. **Prise du lot** : passe sa ligne à « en cours depuis AAAA-MM-JJ HH:MM UTC (session <id>) » et pousse `pipeline` **sans forcer**. Push refusé → `git fetch origin pipeline`, `git rebase`, relis la ligne : si une autre session a pris ce lot entre-temps, reprends l'étape 1 avec le lot « à faire » suivant ; sinon repousse (5 essais). Aucun lot « à faire » : arrête-toi sans rien modifier ni notifier.
3. Ne modifie que ta ligne d'`ETAT_UI.md`, ta section de `DECISIONS_UI.md` et tes fichiers de `pipeline/ui/livraisons/`.

## 2. Branches

| Branche | Rôle |
| --- | --- |
| `refonte-ui` | intégration ; créée par UI0 depuis `main` b7996b3f ; seuls UI0 et UI5 y poussent, et le pilotage pour fusionner UI1 à UI4 |
| `ui/<LOT>` | travail d'un lot d'écrans, créée depuis `refonte-ui` après UI0 |
| `claude/ci-ui-<lot>` (minuscules : `ui0`, `ui1`…) | contrôle complet d'un lot (workflow `ci-ui.yml` ajouté par UI0) ; UI0 utilise `claude/ci-3d` tant que `ci-ui.yml` n'existe pas |
| `ui-sauvegardes/<LOT>` | sauvegardes (§9 de PIPELINE_CP.md, arbre sans `.github/`, `SAUVEGARDE.md`) |
| `main` | reçoit la refonte à UI5 seulement |

Un lot d'écrans ne touche **que** les fichiers que le cahier (§6.2) lui attribue. Besoin d'un fichier partagé : écris le besoin dans ta livraison ; contournement local dans ta zone si nécessaire ; jamais de modification du fichier d'un autre lot.

## 3. Contrôles

- Suite complète de tests, analyse, formatage, `tools/check_ui_tokens.py --zone <LOT>` à 0, tour de captures de ta zone vert (sombre et clair, palettes `bordeaux` et `neon`, sessions perso et dev), parcours de §5.4 mesurés pour ta zone.
- Tu regardes **chaque capture** de ta zone et tu corriges avant de livrer (alignements, débordements, titres coupés, contrastes, cohérence avec les maquettes).
- Relecture indépendante par un sous-agent Opus qui ne voit que le cahier, les maquettes (lien) et tes captures avant / après ; chaque constat traité ou expliqué.
- Attendre la CI sans boucle serrée (une vérification toutes les 10 minutes au plus).

## 4. Fin de lot

1. Version interne `dev6.12.0-<lot>` (UI0 à UI4) ; UI5 : **dev6.12.0** sur `main`, build signé réussi, run vérifié.
2. UI0 : pousse `refonte-ui`. UI1 à UI4 : poussent `ui/<LOT>` (la conversation de pilotage fusionne dans `refonte-ui`). UI5 : `refonte-ui` → `main` en avance rapide. Push sur `main` refusé par la session : commit gardé sur `ui-sauvegardes/UI5-candidat`, recommandation écrite, aucun contournement.
3. `LIVRAISON_<LOT>.md` dans `pipeline/ui/livraisons/` et dans le projet claude.ai (`claude/LIVRAISON_<LOT>.md`, outil Projects) : ce qui est livré, tableau « avant → après » par écran (aucune information perdue), captures clés (chemins sur la branche de contrôle), écarts aux maquettes et leur raison, composants à promouvoir, mesures (jetons, parcours, contrastes), limites, recommandation.
4. Ligne d'`ETAT_UI.md` (« livré » + liens) ; notification `Kalis Track <LOT> livré (<résumé>). À voir : <captures>` ; **arrête-toi** (aucun `fire_trigger`, aucune tâche planifiée créée, modifiée ou supprimée).

Interdits : modifier `packages/`, les moteurs, le format de sauvegarde, les migrations, la signature ; retirer une assertion de test sans remplacement équivalent ; publier sur `main` avant UI5 ; lancer un lot.

## 5. Pause budget (DECISIONS_UI.md U0.13)

Le propriétaire met en pause toute la refonte UI quand son utilisation atteint **80 %** (page « Utilisation » de claude.ai ; aucun outil de session ne lit ce pourcentage, c'est lui qui le signale). La pause est marquée par le fichier **`pipeline/ui/PAUSE`** sur la branche `pipeline` (date, heure, raison).
1. **Au démarrage** d'une session (avant la prise du lot, §1) et **à chaque sauvegarde** (§9 de PIPELINE_CP.md) : `git fetch origin pipeline` puis `git cat-file -e origin/pipeline:pipeline/ui/PAUSE`. S'il existe : sauvegarde complète sur `ui-sauvegardes/<LOT>` (SAUVEGARDE.md à jour : fait, en cours, reste à faire), ligne d'`ETAT_UI.md` → « en pause depuis AAAA-MM-JJ HH:MM UTC (sauvegarde <commit>) », notification `Kalis Track <LOT> en pause (budget)`, puis **arrête-toi** sans livrer ni lancer de contrôle CI.
2. Pendant la pause, la conversation de pilotage ne lance, ne relance et ne fusionne rien ; la tâche planifiée de la refonte UI est désactivée.
3. **Reprise** sur demande du propriétaire seulement : le pilotage supprime `PAUSE`, réactive la tâche, passe chaque lot « en pause » à « à faire (reprise) » et le relance ; la session repart de `ui-sauvegardes/<LOT>`.

