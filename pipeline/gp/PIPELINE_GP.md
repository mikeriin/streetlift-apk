# Pipeline « Génération et progression » (GP) Kalis Track — règles communes

Propriétaire : Gaël (30/09/2026). Tu es lancé par une des tâches planifiées « Kalis Track — pipeline GP (Fable 5.1, effort maximal) » ou « (Opus 5.5, effort élevé) », dans une session neuve. Le message de lancement indique le lot : « Lot : <LOT> ». Ce pipeline refond la création du profil et du programme, crée deux moteurs d'entraînement (statique, dynamique), un moteur de progression (leveling), intègre Koach en mascotte 2D, et retire WOD, séances manuelles et ancien système de progression. **Un lot = une seule action** ; ne fais rien qui appartienne à un autre lot.

Fichiers de référence (branche `pipeline`) : ce fichier, `pipeline/gp/DECISIONS_GP.md` (décisions du propriétaire : **elles font foi**), `pipeline/gp/ETAT_GP.md` (état des lots), `pipeline/gp/prompts/<LOT>.txt` (ton lot), `pipeline/gp/inputs/` (assets fournis par le propriétaire).

## 1. Démarrage

1. Dépôt `mikeriin/streetlift-apk` : s'il est dans les sources de la session, utilise-le ; sinon `add_repo` (accès push) puis clone. Vérifie tout de suite qu'un push est possible (`git push --dry-run origin pipeline`) ; sinon notifie « Kalis Track GP bloqué — pas d'accès push au dépôt » et arrête-toi sans rien modifier.
2. `git fetch origin pipeline main` ; lis ce fichier, `DECISIONS_GP.md`, `ETAT_GP.md`, puis le prompt de ton lot.
3. Statuts dans `ETAT_GP.md` : « à faire », « en cours depuis … », « à valider » (publié, en test chez le propriétaire), « validé », « en attente du propriétaire » (entrée ou décision manquante), « remplacé ». **Ton lot est le premier lot du tableau §8 qui n'est ni « validé » ni « remplacé »** — sauf pour un lot de moteur (colonne « Validation » = auto), qui est considéré comme validé dès qu'il est « livré ».
   - Si le lot demandé ne correspond pas : arrête-toi sans rien modifier et notifie « Kalis Track GP : lot demandé <X>, lot attendu <Y> ».
   - Si ce lot est « à valider » : si le message contient « Corrections du propriétaire pour <LOT> », fais un **passage de correction** (ces corrections seulement, même exigence, version corrective §7) ; sinon arrête-toi et notifie « Kalis Track <LOT> : en attente de validation du propriétaire ».
   - S'il est « en cours depuis » moins de 6 h, ou « en attente du propriétaire » sans que le message de lancement lève l'attente : **arrête-toi sans rien modifier ni notifier**. En cours depuis plus de 6 h : repars de l'état réel du dépôt (commits, branches) sans refaire ce qui est poussé.
4. Prérequis : tous les lots précédents sont « validé », « remplacé », ou « livré » pour un lot de moteur. Sinon notification d'échec (§5) et arrêt.
5. Marque ton lot « en cours depuis AAAA-MM-JJ HH:MM UTC » dans `ETAT_GP.md` et pousse `pipeline` (push refusé parce qu'une autre session vient de le faire : arrête-toi).

## 2. Architecture (D0.3) — moteurs indépendants de l'application

- Les moteurs vivent dans `packages/` à la racine du dépôt, en **Dart pur** : aucun import de Flutter, `dart:io` seulement dans `bin/` et les tests, aucun stockage, **aucune horloge implicite** (dates et « maintenant » passés en paramètre), aucun hasard non seedé. Entrées et sorties sérialisables en JSON avec un numéro de schéma. Deux appels identiques donnent un résultat identique à l'octet près.
- Paquets prévus : `kalis_core` (modèles partagés : catalogue d'exercices, profil d'athlète, journal de séances, échelle des flammes, schémas JSON ; créé par G3), `kalis_plan` (moteur statique, G4), `kalis_koach` (choix des poses et des messages de Koach, G5), `kalis_adapt` (moteur dynamique, G8), `kalis_quest` (leveling, quêtes, objectifs, G11). Dépendances autorisées entre paquets : `kalis_core` ← tous ; `kalis_adapt` → `kalis_plan` (restructurations) ; `kalis_quest` → `kalis_adapt` (tendances, records). Aucune autre.
- Chaque paquet contient : `pubspec.yaml` (même contrainte SDK que l'application, dépendances limitées à `meta` et `collection` hors tests), `lib/`, `test/`, `bin/<paquet>_cli.dart` (simulateur en ligne de commande : entrée JSON → sortie JSON + rapport lisible), `README.md`, `CONTRAT.md` (API publique, invariants, paramètres avec leur justification et leurs références, limites connues), `CHANGELOG.md`, version sémantique propre.
- L'application dépend des paquets par `path:` et ne contient que l'adaptation : lecture/écriture du stockage, horloge, écrans. **Aucune règle d'entraînement ni de progression n'est codée dans `lib/`** une fois le moteur correspondant livré.
- Rendu mobile : temps de calcul mesuré dans la VM Dart en CI et consigné ; budgets : génération complète d'un programme ≤ 1 s, décision de séance ≤ 50 ms, calcul du leveling depuis tout le journal ≤ 200 ms (sur la CI ; le téléphone du propriétaire confirme au test).

## 3. Règles communes à tous les lots

- **Données** : ne perds aucune donnée de l'utilisateur (seule exception : suppression des WOD et séances manuelles, D1.1, après sauvegarde automatique). Tout nouveau contenu de la sauvegarde est une **section versionnée, optionnelle** ; une sauvegarde d'une version antérieure s'importe toujours (sans ses sections retirées). Ne touche ni à l'identifiant Android, ni à la signature (`signing/`), ni aux secrets ; ne régénère aucune clé.
- **Session dev** (à partir de G1) : chaque lot qui ajoute un écran ou une donnée vérifie qu'ils fonctionnent **dans la session dev** (installation neuve simulée) comme dans la session personnelle, sans fuite de l'une vers l'autre.
- **Programme personnel du propriétaire** (D5.10) : le programme de 40 semaines (instance « template ») reste identique jour pour jour ; aucun lot ne le régénère.
- **Koach parle partout** (D6.4) à partir de G5 : chaque nouvel écran ou changement proposé passe par Koach (pose + bulle courte + « Pourquoi ? » quand utile). Textes en français, tutoiement, courts, sans jargon non expliqué ; aucune allégation médicale, aucune promesse de résultat (règles L13, `lib/wellbeing.dart`).
- **Interface** : couleur dominante choisie par l'utilisateur (`SL.accentSpec`), Rouge Kalis #5E1615 par défaut, thèmes clair et sombre, vert réservé à la validation. Lisible à 200 % de texte, libellés d'accessibilité (TalkBack), jamais d'information portée par la couleur seule. « Réduire les animations » respecté partout.
- **Qualité des moteurs** : chaque paramètre chiffré est justifié dans `CONTRAT.md` par une mesure (simulation, données) ou une référence citée (article, ouvrage) ; ce qui n'est qu'un choix raisonné est dit comme tel. Contenu sportif non relu par un professionnel diplômé : le registre de validation du paquet le dit.
- Ne supprime aucune fonctionnalité que ton lot n'a pas pour objet de supprimer ; ne désactive ni ne retire aucun test (un test qui vérifie une fonctionnalité supprimée par ton lot est retiré avec elle, et la livraison le liste).

## 4. Contrôles et CI

- Pas de SDK Flutter local : même méthode que le pipeline 3D (`docs/CI_3D.md`) — pose l'arbre du lot sur la tête de `claude/ci-3d` (`git commit-tree <arbre> -p origin/claude/ci-3d`, push en avance rapide), lis les résultats recommités dans `ci-out/`. Regroupe formatage, analyse, tests, build et captures en **un minimum de passages**.
- G1 étend `ci-3d.yml` : tâche `packages` (pour chaque dossier de `packages/` : `dart format --output=none --set-exit-if-changed .`, `dart analyze --fatal-infos`, `dart test`, et le rapport du simulateur s'il existe, recommité dans `ci-out/packages/`) ; `build-apk.yml` : chemin `packages/**` ajouté aux déclencheurs, APK construit avec `--dart-define=KALIS_DEV=true`, AAB sans (D2.4). Nommer le fichier de méthode `docs/CI_GP.md` (copie à jour de `CI_3D.md` + ces ajouts).
- Contrôles obligatoires à chaque lot : formatage, `flutter analyze`, suite Dart complète de l'application, tâche `packages`, tests Python (`tools/tests`, `verify_project.py`), `package_release.py --check`, `check_release_without_secrets.py --tree`. Aucune assertion retirée, aucun test désactivé.
- **Lots d'écran** : captures du vrai rendu sur l'émulateur (tests d'intégration du lot, limités à ses écrans, clair et sombre), que tu **regardes** (outil Read) avant de livrer ; corrige tant qu'un rendu est faux. Délai par test de capture ≤ 5 min, job émulateur ≤ 30 min, jamais de `pumpAndSettle` sur un écran avec une vue 3D.
- **Lots de moteur** : tests de propriétés (au moins 10 000 entrées aléatoires seedées), cas types relus (`docs/` du paquet), simulation de validation décrite dans le prompt, mesure de temps de calcul.
- Lis seulement les fichiers utiles au lot ; sous-agents seulement si nécessaire (recherche documentaire des lots de moteur, relecture indépendante) ; rapports concis.

## 5. Décisions, blocages, notifications (PushNotification, < 200 caractères, une ligne)

Tranche toi-même tout choix réversible compatible avec `DECISIONS_GP.md` et consigne-le dans sa section de lot (en bas du fichier). Arrête-toi et notifie seulement si : (a) risque de perte de données ; (b) contradiction avec une décision du propriétaire qui change le résultat ; (c) entrée, accès ou outil indispensable manquant (statut « en attente du propriétaire ») ; (d) build ou tests encore en échec après 2 corrections sérieuses.
- Livraison d'un lot d'écran : `Kalis Track <LOT> prêt à tester — v<version>. À tester : <quelques mots>. Page : <lien de la page de suivi>` (raccourcis « À tester » plutôt que le lien).
- Livraison d'un lot de moteur : `Kalis Track <LOT> livré (moteur <paquet> <version>) — <lot suivant> lancé. Page : <lien>`.
- Décision : `Kalis Track <LOT> : décision requise — <question>` (question détaillée dans DECISIONS_GP.md, 2-3 options et ta recommandation).
- Échec : `Kalis Track <LOT> bloqué — <cause courte>`.

## 6. Page de suivi

Une seule page claude.ai « Suivi Kalis Track GP » (outil Artifact ; charge d'abord la skill `artifact-design`), **créée par G1**, puis **republiée au même lien** par chaque lot (paramètre `url`, lien noté dans `ETAT_GP.md`). Chaque lot y ajoute sa section en tête avant la notification : version et build signé (n° du run), ce qu'il faut regarder dans l'application (chemin exact des écrans, dans la session perso et dans la session dev), 2 à 4 captures du vrai rendu (lots d'écran) ou rapport de simulation résumé (lots de moteur), résultats des contrôles, limites ; le tableau des lots en bas passe le lot à « À valider » ou « Livré ». Lisible sur téléphone.

## 7. Fin de lot

1. **Lot d'écran** : version calculée à la publication à partir de celle de `main` (x.y.z+N) : lot → x.(y+1).0 ; passage de correction → x.y.(z+1) ; G1 → **6.0.0** ; N + 1 dans tous les cas (réglages / À propos à jour). **Lot de moteur** : version du paquet (0.1.0 à la première livraison) ; la version de l'application ne change que si `lib/` change. README, SUIVI_PROJET.md (section du lot) et CHANGELOG des paquets touchés à jour.
2. Publie en poussant sur `main` (avance rapide ; si `main` a bougé, remets-toi à jour et relance les contrôles). **Dernier commit poussé** : « Kalis Track x.y.z (<LOT>) : <objet> » (lot d'écran) ou « Kalis Track moteurs (<LOT>) : <paquet> <version> » (lot de moteur). Vérifie que le run `build-apk.yml` signé réussit sur ce commit.
3. `LIVRAISON_<LOT>.md` dans le projet claude.ai (outil Projects, `claude/LIVRAISON_<LOT>.md`) et dans `pipeline/gp/livraisons/`.
4. Mets à jour `ETAT_GP.md` (version, commit, run, date, statut : « à valider » pour un lot d'écran, « livré » pour un lot de moteur ; pour une correction, ligne « correction n » sous le lot) et pousse `pipeline` (jamais de sources de l'application sur cette branche).
5. Page de suivi (§6), puis notification (§5), puis :
   - **lot d'écran** : arrête-toi. Le propriétaire teste et rend compte ; seul le propriétaire (conversation de pilotage) passe un lot à « validé » et lance le suivant ;
   - **lot de moteur** : lance **le lot suivant du tableau §8** avec `fire_trigger` sur la tâche **de l'autre modèle** indiquée dans `ETAT_GP.md`, message « Lot : <lot suivant> », puis arrête-toi. **Ne relance jamais la tâche qui t'a lancé.**
Interdits : créer, modifier ou supprimer une tâche planifiée ; lancer une tâche en dehors du cas « lot de moteur » ci-dessus ; supprimer une branche ; modifier la signature ou l'identifiant ; pousser un secret ; pousser sur `main` des sources dont les contrôles ne sont pas verts ; réécrire l'historique de `main` ; y ajouter un ZIP du projet.

## 8. Enchaînement

| Lot | Prompt | Action unique | Validation | Ce que le propriétaire teste | Modèle |
| --- | --- | --- | --- | --- | --- |
| G1 | G01.txt | Mode dev (5 appuis, logo rose, appui long 3 s, session isolée, voyage dans le temps), CI des paquets, build dev, page de suivi | propriétaire | Logo : 5 appuis, session neuve, appui long, retour à sa session intacte | Opus 5.5 |
| G2 | G02.txt | Suppression des WOD, séances manuelles et de L12, avec sauvegarde automatique | propriétaire | Plus d'onglet WOD ni de créateur ; sauvegarde présente | Opus 5.5 |
| G3 | G03.txt | Base d'exercices v1.1 : paquet `kalis_core`, catalogue dans l'application, historique conservé | propriétaire | Arsenal, fiches, recherche, historique et records intacts | Opus 5.5 |
| G4 | G04.txt | Moteur statique `kalis_plan` (optimisation sous contraintes, 2 passes, variantes, verrous, blocs glissants) | **auto** → lance G5 | (rien dans l'app ; rapport sur la page) | **Fable 5.1 max** |
| G5 | G05.txt | Koach mascotte 2D (36 poses, flammes, micro-animations, `kalis_koach`), Koach 3D retiré | propriétaire | Koach partout, thèmes clair/sombre | Opus 5.5 |
| G6 | G06.txt | Création du profil (≈ 5 min, disciplines, mode street, niveau, objectifs, disponibilités, mode assisté/libre) | propriétaire | Session dev : création du profil ; session perso : refaire son profil | Opus 5.5 |
| G7 | G07.txt | Création du programme : passe 1, revue et variantes, régénération avec diff, passe 2, « Où j'en suis » | propriétaire | Session dev : programme complet ; reprise | Opus 5.5 |
| G8 | G08.txt | Moteur dynamique `kalis_adapt` (bayésien, flammes, forme/fatigue, bilan santé, modes, déblocage) | **auto** → lance G9 | (rapport de simulation sur la page) | **Fable 5.1 max** |
| G9 | G09.txt | Séance : flammes à chaque série, bilan santé, charges par le moteur dynamique (programme perso compris) | propriétaire | Une vraie séance | Opus 5.5 |
| G10 | G10.txt | Évolution : propositions de Koach, modes assisté/libre, restructurations, simulateur et inspecteur dev ; L7/L10/L11 retirés | propriétaire | Simulateur dev sur plusieurs semaines | Opus 5.5 |
| G11 | G11.txt | Moteur de leveling `kalis_quest` (XP, niveaux 1-100 + prestige, attributs, rangs, quêtes, Krédits, objectifs) | **auto** → lance G12 | (rapport de rythme sur la page) | **Fable 5.1 max** |
| G12 | G12.txt | Leveling et objectifs dans l'application ; ancien système retiré, remise à zéro | propriétaire | Niveau, quêtes, attributs, rangs, objectifs | Opus 5.5 |
| G13 | G13.txt | Envie de progresser : célébrations, coffres, série, fantôme, note S/A/B/C, récap story, comparaisons, prédictions, sons et vibrations | propriétaire | Chaque fonction + ses interrupteurs | Opus 5.5 |
| G14 | G14.txt | Partage pseudonymisé des données d'évolution + script de recalibrage | propriétaire | Réglages › Partager mes données | Opus 5.5 |
| G15 | G15.txt | Nettoyage final, performance, audit, documentation | propriétaire | Aucune régression | Opus 5.5 |

Effort **élevé** (Opus) : raisonne avant chaque choix structurant, vérifie chaque rendu dans les deux thèmes et les deux sessions, corrige avant de livrer. Effort **maximal** (Fable) : chaque décision de modélisation est justifiée par une référence ou une mesure, chaque invariant est testé, chaque résultat de simulation est lu en entier ; rien n'est livré qu'un entraîneur et un statisticien exigeants refuseraient.
