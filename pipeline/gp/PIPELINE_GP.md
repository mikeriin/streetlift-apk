# Pipeline « Génération et progression » (GP) Kalis Track — règles communes

Propriétaire : Gaël (30/09/2026 ; **pistes parallèles depuis le 01/10/2026**, D0.10). Tu es lancé par une tâche planifiée « Kalis Track — pipeline GP … » dans une session neuve. Le message de lancement indique le lot : « Lot : <LOT> ». Ce pipeline refond la création du profil et du programme, crée deux moteurs d'entraînement (statique, dynamique), un moteur de progression (leveling), intègre Koach en mascotte 2D, et retire WOD, séances manuelles et ancien système de progression. **Un lot = une seule action** ; ne fais rien qui appartienne à un autre lot.

Fichiers de référence (branche `pipeline`) : ce fichier, `pipeline/gp/DECISIONS_GP.md` (décisions du propriétaire : **elles font foi**), `pipeline/gp/ETAT_GP.md` (état des lots, tâches planifiées, étiquettes livrées), `pipeline/gp/prompts/<LOT>.txt` (ton lot), `pipeline/gp/inputs/` (entrées fournies par le propriétaire).

## 0. Trois pistes

| Piste | Lots | Branche de travail | Validation | Publication |
| --- | --- | --- | --- | --- |
| **A — application** | G1, G2, G3, G5, G6, G7, G9, G10, G12, G13, G14, G15 | `main` | **propriétaire**, lot par lot | `main` + build signé |
| **M — moteurs** | GC, G4, G8, G11 | `moteurs` | **automatique** (contrôles verts) | étiquette `<paquet>-vX.Y.Z` sur `moteurs` |
| **K — koach** | GK | `koach` | **automatique** | étiquette `kalis_koach-vX.Y.Z` sur `koach` |

- Les pistes M et K **ne touchent jamais `lib/`** ni les fichiers de l'application : seulement `packages/<paquet>/`, leurs outils (`tools/catalog/`, `tools/koach/`) et la documentation de leurs paquets. Les branches `moteurs` et `koach` **ne sont jamais fusionnées dans `main`**.
- Un lot de la piste A qui consomme un paquet le **récupère par étiquette** : `git fetch origin --tags` puis `git checkout <étiquette> -- packages/<paquet>` (et `tools/catalog/` ou `tools/koach/` si son prompt le dit), branche l'application dessus, et lance toute la CI de l'application. C'est lui qui assure l'intégration (tests de contrat compris).
- **« Étiquette » = branche fixe `etiquettes/<paquet>-vX.Y.Z`** (constat du 01/10/2026 : le push d'étiquettes git est refusé aux sessions, 403). Livrer : `git push origin <commit>:refs/heads/etiquettes/<paquet>-vX.Y.Z`. Récupérer : `git fetch origin 'refs/heads/etiquettes/*:refs/remotes/origin/etiquettes/*'` puis `git checkout origin/etiquettes/<paquet>-vX.Y.Z -- packages/<paquet>`. Ces branches ne sont jamais déplacées ni supprimées. Partout où un prompt dit « étiquette », lis « branche `etiquettes/…` » (une vraie étiquette git créée par le propriétaire, comme `kalis_koach-v0.1.0`, a toujours sa branche `etiquettes/` équivalente).
- **Contrats** (GC) : les types partagés et les interfaces entre moteurs et application sont figés dans `kalis_core` par GC. Après GC, toute évolution de `kalis_core` est **additive** (rien de retiré ni de renommé, champs nouveaux optionnels) ; une rupture nécessite une décision du propriétaire (§5 b).

## 1. Démarrage

1. Dépôt `mikeriin/streetlift-apk` : s'il est dans les sources de la session, utilise-le ; sinon `add_repo` (accès push) puis clone. Vérifie tout de suite qu'un push est possible (`git push --dry-run origin pipeline`) ; sinon notifie « Kalis Track GP bloqué — pas d'accès push au dépôt » et arrête-toi sans rien modifier.
2. `git fetch origin pipeline main moteurs koach --tags` ; lis ce fichier, `DECISIONS_GP.md`, `ETAT_GP.md`, puis le prompt de ton lot.
3. Statuts dans `ETAT_GP.md` : « à faire », « en cours depuis … », « à valider » (piste A : publié, en test chez le propriétaire), « validé », « livré » (pistes M et K : étiqueté, contrôles verts), « en attente du propriétaire » (entrée ou décision manquante), « en attente de <lot> » (prérequis d'une autre piste pas encore livré), « remplacé ».
   - **Ton lot est le premier lot de sa piste** (ordre du tableau §8) qui n'est ni « validé », ni « livré », ni « remplacé ». S'il ne correspond pas au lot demandé : arrête-toi sans rien modifier et notifie « Kalis Track GP : lot demandé <X>, lot attendu <Y> ».
   - Si ce lot est « à valider » : si le message contient « Corrections du propriétaire pour <LOT> », fais un **passage de correction** (ces corrections seulement, même exigence, version corrective §7) ; sinon arrête-toi et notifie « Kalis Track <LOT> : en attente de validation du propriétaire ».
   - S'il est « en cours depuis » moins de 6 h, ou « en attente du propriétaire » sans que le message de lancement lève l'attente : **arrête-toi sans rien modifier ni notifier**. En cours depuis plus de 6 h : repars de l'état réel du dépôt (commits, branches, étiquettes) sans refaire ce qui est poussé.
4. **Prérequis** (colonne « Prérequis » du §8) : chacun est « validé » (piste A) ou « livré » (pistes M, K). Sinon : marque ton lot « en attente de <prérequis> », pousse `pipeline`, notifie « Kalis Track <LOT> : en attente de <prérequis> » et arrête-toi (la conversation de pilotage le relancera).
5. Marque ton lot « en cours depuis AAAA-MM-JJ HH:MM UTC » dans `ETAT_GP.md` et pousse `pipeline`.
6. **Écritures concurrentes sur `pipeline`** (trois pistes) : ne modifie que **les lignes et sections de ton lot** (`ETAT_GP.md`, ta section en bas de `DECISIONS_GP.md`, tes fichiers de `livraisons/`). Push refusé : `git fetch origin pipeline`, `git rebase origin/pipeline` (conflit sur une ligne d'un autre lot : garde la sienne), repousse ; jusqu'à 5 essais. Ne réécris jamais l'historique de `pipeline`.

## 2. Architecture (D0.3) — moteurs indépendants de l'application

- Les moteurs vivent dans `packages/` à la racine du dépôt, en **Dart pur** : aucun import de Flutter, `dart:io` seulement dans `bin/` et les tests, aucun stockage, **aucune horloge implicite** (dates et « maintenant » passés en paramètre), aucun hasard non seedé. Entrées et sorties sérialisables en JSON avec un numéro de schéma. Deux appels identiques donnent un résultat identique à l'octet près.
- Paquets : `kalis_core` (GC : modèles et contrats partagés — catalogue d'exercices compilé depuis la base v1.1, profil d'athlète v2, journal de séances, échelle des flammes, interfaces et types d'échange de `plan`, `adapt`, `quest`, jeux de données de test communs), `kalis_plan` (moteur statique, G4), `kalis_adapt` (moteur dynamique, G8), `kalis_quest` (leveling, quêtes, objectifs, G11), `kalis_koach` (GK : poses vectorisées, flammes, choix des répliques de Koach). Dépendances autorisées : `kalis_core` ← `kalis_plan`, `kalis_adapt`, `kalis_quest` ; `kalis_adapt` → `kalis_plan` ; `kalis_quest` → `kalis_adapt` ; `kalis_koach` n'en a aucune. Aucune autre.
- Chaque paquet contient : `pubspec.yaml` (même contrainte SDK que l'application, dépendances limitées à `meta` et `collection` hors tests, dépendances entre paquets par `path: ../<paquet>`), `lib/`, `test/`, `bin/<paquet>_cli.dart` (simulateur : `--rapport <dossier>` écrit JSON + texte lisible, docs/CI_GP.md), `README.md`, `CONTRAT.md` (API publique, invariants, paramètres avec leur justification et leurs références, limites connues, registre de validation), `CHANGELOG.md`, version sémantique propre.
- L'application dépend des paquets par `path:` et ne contient que l'adaptation : lecture/écriture du stockage, horloge, écrans. **Aucune règle d'entraînement ni de progression n'est codée dans `lib/`** une fois le moteur correspondant intégré.
- Budgets (VM Dart, CI ; le téléphone du propriétaire confirme) : génération complète d'un programme ≤ 1 s, régénération après une action de revue ≤ 300 ms, décision de séance ≤ 50 ms, calcul du leveling depuis tout le journal ≤ 200 ms.

## 3. Règles communes à tous les lots

- **Données** : ne perds aucune donnée de l'utilisateur (seule exception : suppression des WOD et séances manuelles, D1.1, après sauvegarde automatique). Tout nouveau contenu de la sauvegarde est une **section versionnée, optionnelle** ; une sauvegarde d'une version antérieure s'importe toujours (sans ses sections retirées). Ne touche ni à l'identifiant Android, ni à la signature (`signing/`), ni aux secrets ; ne régénère aucune clé.
- **Session dev** (G1) : chaque lot de la piste A qui ajoute un écran ou une donnée vérifie qu'ils fonctionnent **dans la session de test** (installation neuve simulée) comme dans la session personnelle, sans fuite de l'une vers l'autre.
- **Programme personnel du propriétaire** (D5.10) : le programme de 40 semaines (instance « template ») reste identique jour pour jour ; aucun lot ne le régénère.
- **Koach parle partout** (D6.4) à partir de G5 : chaque nouvel écran ou changement proposé passe par Koach (pose + bulle courte + « Pourquoi ? » quand utile). Textes en français, tutoiement, courts, sans jargon non expliqué ; aucune allégation médicale, aucune promesse de résultat (règles L13, `lib/wellbeing.dart`). Les moteurs ne produisent **aucun texte français** : des codes de raison et des paramètres, rendus par `kalis_koach` et l'application.
- **Interface** : couleur dominante choisie par l'utilisateur (`SL.accentSpec`), Rouge Kalis #5E1615 par défaut, thèmes clair et sombre, vert réservé à la validation. Lisible à 200 % de texte, libellés d'accessibilité (TalkBack), jamais d'information portée par la couleur seule. « Réduire les animations » respecté partout.
- **Qualité des moteurs** : chaque paramètre chiffré est justifié dans `CONTRAT.md` par une mesure (simulation, données) ou une référence citée (article, ouvrage) ; ce qui n'est qu'un choix raisonné est dit comme tel. Contenu sportif non relu par un professionnel diplômé : le registre de validation du paquet le dit.
- Ne supprime aucune fonctionnalité que ton lot n'a pas pour objet de supprimer ; ne désactive ni ne retire aucun test (un test qui vérifie une fonctionnalité supprimée par ton lot est retiré avec elle, et la livraison le liste).

## 4. Contrôles et CI

- Pas de SDK Flutter local. **Chaque piste a sa propre branche de contrôle** (aucune piste n'annule les contrôles d'une autre) :
  - piste A : `claude/ci-3d`, workflow `ci-3d.yml`, méthode `docs/CI_GP.md` (pose l'arbre du lot sur la tête de la branche par `git commit-tree <arbre> -p origin/claude/ci-3d`, push en avance rapide, résultats recommités dans `ci-out/`) ;
  - piste M : `claude/ci-gp-moteurs` ; piste K : `claude/ci-gp-koach` — workflow `ci-paquets.yml` présent sur les branches `moteurs` et `koach` (paquets Dart + tests Python des outils), méthode `docs/CI_PISTES.md` (sur ces branches). Les branches de piste ne déclenchent aucun build signé.
- Regroupe formatage, analyse, tests, build et captures en **un minimum de passages**.
- **Piste A**, contrôles obligatoires à chaque lot : formatage, `flutter analyze`, suite Dart complète de l'application (dont les tests du mode dev), tâche `packages`, tests Python (`tools/tests`, `verify_project.py`), `package_release.py --check`, `check_release_without_secrets.py --tree`. Captures du vrai rendu sur l'émulateur (tests d'intégration du lot, limités à ses écrans, clair et sombre), que tu **regardes** (outil Read) avant de livrer ; corrige tant qu'un rendu est faux. Délai par test de capture ≤ 5 min, job émulateur ≤ 30 min, jamais de `pumpAndSettle` sur un écran avec une vue 3D.
- **Pistes M et K** : formatage, `dart analyze --fatal-infos`, `dart test` de chaque paquet touché **et de ceux qui en dépendent**, tests de propriétés (au moins 10 000 entrées aléatoires seedées), cas types relus (`docs/` du paquet), simulation de validation décrite dans le prompt, mesure de temps de calcul ; tests Python des outils.
- Aucune assertion retirée, aucun test désactivé. Lis seulement les fichiers utiles au lot ; sous-agents seulement si nécessaire (recherche documentaire, relecture indépendante) ; rapports concis.

## 5. Décisions, blocages, notifications (PushNotification, < 200 caractères, une ligne)

Tranche toi-même tout choix réversible compatible avec `DECISIONS_GP.md` et consigne-le dans sa section de lot (en bas du fichier). Arrête-toi et notifie seulement si : (a) risque de perte de données ; (b) contradiction avec une décision du propriétaire, ou rupture d'un contrat de `kalis_core`, qui change le résultat ; (c) entrée, accès ou outil indispensable manquant (statut « en attente du propriétaire ») ; (d) build ou tests encore en échec après 2 corrections sérieuses.
- Piste A, livraison : `Kalis Track <LOT> prêt à tester — devX.Y.Z. À tester : <quelques mots>. Page : <lien de la page de suivi>` (raccourcis « À tester » plutôt que le lien).
- Pistes M et K, livraison : `Kalis Track <LOT> livré (<paquet> <version>) — <lot suivant de la piste> lancé. Page : <lien>` (fin de piste : « fin de la piste <M|K> »).
- Décision : `Kalis Track <LOT> : décision requise — <question>` (question détaillée dans DECISIONS_GP.md, 2-3 options et ta recommandation).
- Échec : `Kalis Track <LOT> bloqué — <cause courte>`. Attente : `Kalis Track <LOT> : en attente de <prérequis>`.

## 6. Page de suivi

Page claude.ai « Suivi Kalis Track GP » (outil Artifact ; charge d'abord la skill `artifact-design`), créée par G1, **republiée au même lien** par chaque lot (paramètre `url`, lien dans `ETAT_GP.md`). Lis-la d'abord (action `read`), ajoute ta section **en tête de la partie de ta piste** (trois parties : Application, Moteurs, Koach), mets à jour ta ligne du tableau des lots en bas, republie. **Publication refusée parce qu'un autre lot vient de republier** : reprends la version vivante que le refus te donne, réapplique seulement ta section et ta ligne, republie (jusqu'à 3 essais). Contenu d'une section : version (et build signé pour la piste A, n° du run ; étiquette pour M et K), ce qu'il faut regarder (piste A : chemin exact des écrans, session perso et session de test), 2 à 4 captures (piste A) ou rapport de simulation résumé (M, K), résultats des contrôles, limites. Lisible sur téléphone.

## 7. Fin de lot

1. **Version.**
   - Piste A : calculée à la publication à partir de celle de `main` (x.y.z+N) : lot → x.(y+1).0 ; passage de correction → x.y.(z+1) ; N + 1 dans tous les cas. **Nom affiché : « devX.Y.Z »** (D0.9) : Réglages › À propos, `versionName` de l'APK (l'AAB garde « X.Y.Z »), commit, notification, page, livraison, ETAT ; `pubspec.yaml` reste `X.Y.Z+N`. README, SUIVI_PROJET.md (section du lot) à jour.
   - Pistes M et K : version du paquet (0.1.0 à la première livraison, x.y.(z+1) pour une correction, x.(y+1).0 pour une évolution additive) ; CHANGELOG du paquet à jour.
2. **Publication.**
   - Piste A : push sur `main` (avance rapide ; si `main` a bougé, remets-toi à jour et relance les contrôles). Dernier commit poussé : « Kalis Track devX.Y.Z (<LOT>) : <objet> ». Vérifie que le run `build-apk.yml` signé réussit sur ce commit.
   - Pistes M et K : push sur ta branche de piste (avance rapide seulement), dernier commit « Kalis Track moteurs (<LOT>) : <paquet> <version> » (ou « Kalis Track koach (GK) : … »), puis **branche fixe** `etiquettes/<paquet>-v<version>` sur ce commit (§0). Elle n'est jamais déplacée ni supprimée.
3. `LIVRAISON_<LOT>.md` dans le projet claude.ai (outil Projects, `claude/LIVRAISON_<LOT>.md`) et dans `pipeline/gp/livraisons/`.
4. `ETAT_GP.md` : version, commit, run (A) ou étiquette (M, K), date, statut (« à valider » pour la piste A, « livré » pour M et K ; correction : ligne « correction n » sous le lot) ; push de `pipeline` (§1.6 en cas de refus ; jamais de sources de l'application sur cette branche).
5. Page de suivi (§6), puis notification (§5), puis :
   - **piste A** : arrête-toi. Le propriétaire teste et rend compte ; seule la conversation de pilotage passe un lot à « validé » et lance le suivant ;
   - **piste M** : tente **une fois** de lancer le lot suivant de la piste avec `fire_trigger` sur la tâche indiquée pour ce lot dans `ETAT_GP.md` (les tâches Fable A et B alternent : jamais la tâche qui t'a lancé), message « Lot : <lot suivant> ». Constat du 01/10/2026 : ce lancement est refusé aux sessions ; dans ce cas, écris « <lot suivant> à lancer par le pilotage » dans ta ligne d'`ETAT_GP.md` (la conversation de pilotage vérifie l'état environ toutes les heures et lance les lots prêts), puis arrête-toi. G11 est le dernier lot de la piste : aucun lancement ;
   - **piste K** : aucun lancement (G5, piste A, consommera le paquet).
Interdits : créer, modifier ou supprimer une tâche planifiée ; lancer une tâche en dehors du cas « piste M » ci-dessus ; supprimer une branche ou une étiquette (branches `etiquettes/` comprises) ; fusionner `moteurs` ou `koach` dans `main` ; modifier la signature ou l'identifiant ; pousser un secret ; pousser sur `main` des sources dont les contrôles ne sont pas verts ; réécrire l'historique de `main`, `pipeline`, `moteurs` ou `koach` ; ajouter un ZIP du projet.

## 8. Enchaînement

| Lot | Piste | Prompt | Action unique | Prérequis | Validation | Ce que le propriétaire teste | Modèle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G1 | A | G01.txt | Mode dev, CI des paquets, build dev, page de suivi | — | propriétaire | Logo : 5 appuis, session neuve, appui long | Opus 5.5 |
| G2 | A | G02.txt | Suppression des WOD, séances manuelles et de L12 (sauvegarde automatique) ; nommage devX.Y.Z | G1 | propriétaire | Plus de WOD ni de créateur ; copie de sauvegarde | Opus 5.5 |
| G3 | A | G03.txt | Base d'exercices v1.1 dans l'application (`kalis_core` intégré), historique conservé | G2, GC | propriétaire | Arsenal, fiches, historique et records intacts | Opus 5.5 |
| G5 | A | G05.txt | Koach 2D dans l'application (`kalis_koach` intégré, widgets, flammes), Koach 3D retiré | G3, GK | propriétaire | Koach partout, thèmes | Opus 5.5 |
| G6 | A | G06.txt | Création du profil | G5 | propriétaire | Création du profil (test et perso) | Opus 5.5 |
| G7 | A | G07.txt | Création du programme en 2 passes (`kalis_plan` intégré), revue, « Où j'en suis » | G6, G4 | propriétaire | Programme complet en session de test | Opus 5.5 |
| G9 | A | G09.txt | Séance : flammes, bilan santé, charges (`kalis_adapt` intégré) | G7, G8 | propriétaire | Une vraie séance | Opus 5.5 |
| G10 | A | G10.txt | Évolution : propositions, modes, restructurations, outils dev ; L7/L10/L11 retirés | G9 | propriétaire | Simulateur sur plusieurs semaines | Opus 5.5 |
| G12 | A | G12.txt | Leveling et objectifs (`kalis_quest` intégré) ; ancien système retiré | G10, G11 | propriétaire | Niveau, quêtes, attributs, rangs, objectifs | Opus 5.5 |
| G13 | A | G13.txt | Envie de progresser | G12 | propriétaire | Chaque fonction et ses interrupteurs | Opus 5.5 |
| G14 | A | G14.txt | Partage pseudonymisé + recalibrage | G13 | propriétaire | Partage de ses données | Opus 5.5 |
| G15 | A | G15.txt | Nettoyage final, performance, audit, documentation | G14 | propriétaire | Aucune régression | Opus 5.5 |
| GC | M | GC.txt | Contrats et `kalis_core` (catalogue compilé depuis la base v1.1, profil v2, journal, flammes, interfaces, jeux de test) | — | auto → lance G4 | (rapport sur la page) | **Fable 5.1 max** (tâche A) |
| G4 | M | G04.txt | Moteur statique `kalis_plan` | GC | auto → lance G8 | (rapport sur la page) | **Fable 5.1 max** (tâche B) |
| G8 | M | G08.txt | Moteur dynamique `kalis_adapt` | G4 | auto → lance G11 | (rapport sur la page) | **Fable 5.1 max** (tâche A) |
| G11 | M | G11.txt | Moteur de leveling `kalis_quest` | G8 | auto, fin de piste | (rapport sur la page) | **Fable 5.1 max** (tâche B) |
| GK | K | GK.txt | Koach vectorisé (36 poses, 10 flammes) et `kalis_koach` | — | auto, fin de piste | (planche de contrôle sur la page) | Opus 5.5 |

Effort **élevé** (Opus) : raisonne avant chaque choix structurant, vérifie chaque rendu dans les deux thèmes et les deux sessions, corrige avant de livrer. Effort **maximal** (Fable) : chaque décision de modélisation est justifiée par une référence ou une mesure, chaque invariant est testé, chaque résultat de simulation est lu en entier ; rien n'est livré qu'un entraîneur et un statisticien exigeants refuseraient.
