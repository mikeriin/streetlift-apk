# Pipeline « Calibrage des programmes » (CP) Kalis Track — règles

Propriétaire : Gaël. Créé le 02/10/2026 par la conversation de pilotage (questionnaire du propriétaire : `pipeline/cp/DECISIONS_CP.md`). Il **suspend** le pipeline GP après G10 (G12 et G13 annulés, `pipeline/gp/DECISIONS_GP.md` D0.14).

**But** : que le créateur de programmes et le moteur d'évolution de Kalis Track soient optimisés pour « monsieur tout le monde », du débutant au sportif régulier de très bon niveau, **et** aussi efficaces qu'un coach personnel d'athlète de haut niveau. Ordre : disciplines street d'abord (streetlifting, sets & reps, calisthénie), puis les autres (musculation, force, cardio, mobilité, CrossFit) juste après.

Tu es lancé par une tâche planifiée « Kalis Track — calibrage CP … » dans une session neuve. Le message de lancement indique le lot : « Lot : <LOT> ». **Un lot = une seule action** ; ne fais rien qui appartienne à un autre lot.

Fichiers de référence (branche `pipeline`) : ce fichier, `pipeline/cp/DECISIONS_CP.md` (décisions du propriétaire : **elles font foi**), `pipeline/cp/ETAT_CP.md` (état des lots, tâches, étiquettes, liens), `pipeline/cp/prompts/<LOT>.txt` (ton lot), `pipeline/cp/inputs/` (entrées du propriétaire). Programmes de référence : branche `cp-references`, **chiffrés** (§2). Règles héritées : `pipeline/gp/PIPELINE_GP.md` §2 (architecture), §3 (règles communes), §4 (contrôles), §6 (page de suivi), §7.1-7.2 (versions, publication, branches fixes `etiquettes/`) et `pipeline/gp/DECISIONS_GP.md` (D0 à D9 restent valables sauf mention contraire ici).

## 0. Voies et branches

| Voie | Tâche planifiée | Lots | Branche de travail | Branche de contrôle | Validation |
| --- | --- | --- | --- | --- | --- |
| **A** (moteurs) | Fable 5.1 max, voie A | CR, CP1, CX, CP2, CY | `moteurs` | `claude/ci-cp-a` | automatique (contrôles verts + seuils §2-3), sauf CX et CY (propriétaire, page de relecture) |
| **B** (moteurs) | Fable 5.1 max, voie B | CQ, CA1, CA2 | `moteurs` | `claude/ci-cp-b` | automatique (contrôles verts + seuils §3) |
| **App** | Opus 5.5 élevé, application | CU, CI | `main` | `claude/ci-3d` | **propriétaire** |

- **Un seul lot moteur à la fois** (DECISIONS_CP.md C3.2) : la conversation de pilotage ne lance jamais un lot de la voie A pendant qu'un lot de la voie B tourne, ni l'inverse ; un lot de la voie App (Opus) peut tourner en même temps qu'un lot moteur. Les deux voies gardent leurs tâches et leurs branches de contrôle. Par prudence, avant chaque push sur `moteurs` : `git fetch origin moteurs`, `git rebase origin/moteurs`, relance des tests des paquets touchés si le rebase a apporté des changements, push en avance rapide ; jusqu'à 5 essais. Jamais de réécriture de l'historique de `moteurs`.
- **`kalis_core`** : seul CQ le fait évoluer (0.4.0, additif). Un lot qui a absolument besoin d'un ajout le fait dans un commit séparé « kalis_core x.y.z (<LOT>) : … », additif, versionné, étiqueté, consigné dans sa section de `DECISIONS_CP.md` ; en cas de conflit, garder les deux ajouts.
- Livraison des paquets : branches fixes `etiquettes/<paquet>-vX.Y.Z` (PIPELINE_GP.md §0) ; récupération par l'application comme en GP.
- Voie App : comme la piste A de GP (`main`, `claude/ci-3d`, `docs/CI_GP.md`, version devX.Y.Z, build signé). Les lots de la voie App **ne touchent pas `packages/`** sauf pour y récupérer une étiquette.
- **Aucun lot ne lance un autre lot** (pas de `fire_trigger`) : la conversation de pilotage lance tout, d'après `ETAT_CP.md`.

## 1. Démarrage

1. Dépôt `mikeriin/streetlift-apk` (sources de la session, sinon `add_repo` accès push, puis clone). `git push --dry-run origin pipeline` ; sinon notifie « Kalis Track CP bloqué — pas d'accès push au dépôt » et arrête-toi.
2. `git fetch origin pipeline main moteurs` et les branches `etiquettes/*` ; lis ce fichier, `DECISIONS_CP.md`, `ETAT_CP.md`, ton prompt, puis les parties utiles de `PIPELINE_GP.md` et `DECISIONS_GP.md`.
3. Statuts : « à faire », « à faire (reprise) » (posé par la conversation de pilotage après un arrêt de session : repars de la dernière sauvegarde, §9), « en cours depuis … », « livré » (voies A, B), « à valider » / « validé » (voie App, CX, CY), « en attente du propriétaire », « en attente de <lot> », « correction n », « remplacé ».
   - Le lot demandé doit être « à faire » ou « à faire (reprise) » (ou « en cours depuis » plus de 6 h : repars de l'état réel du dépôt sans refaire ce qui est poussé ; ou « à valider » avec « Corrections du propriétaire pour <LOT> » dans le message : passage de correction). Sinon : arrête-toi sans rien modifier et notifie « Kalis Track CP : <LOT> n'est pas à faire (<statut>) ».
   - « En cours depuis » moins de 6 h : arrête-toi sans rien modifier ni notifier.
4. Prérequis (§8) : chacun « livré » ou « validé ». Sinon : « en attente de <prérequis> », push de `pipeline`, notification, arrêt.
5. Marque ton lot « en cours depuis AAAA-MM-JJ HH:MM UTC » et pousse `pipeline`. Écritures concurrentes : ne modifie que ta ligne d'`ETAT_CP.md`, ta section de `DECISIONS_CP.md`, tes fichiers de `pipeline/cp/livraisons/` ; push refusé → fetch, rebase (garde les lignes des autres), repousse, jusqu'à 5 essais.

## 2. Banc d'essai, panel, relecture du propriétaire

- **Banc d'essai** : paquet Dart pur `kalis_bench` (créé par CR, branche `moteurs`) : profils types, programmes de référence encodés, critères calculables, export lisible des programmes et des trajectoires simulées, rapports. Tout lot moteur mesure sa version **avant / après** sur le banc et publie le rapport.
- **Panel de coachs virtuels** (protocole écrit par CR dans `packages/kalis_bench/docs/PANEL.md`) : quatre relecteurs indépendants, un par école — **force et streetlifting**, **calisthénie et figures**, **hypertrophie et esthétique**, **endurance, santé et kiné**. Chacun est un sous-agent (outil Agent) qui reçoit **seulement** le profil, l'export lisible du programme (ou de la trajectoire), la grille de son école et le référentiel ; il ne voit ni le code, ni les notes des autres, ni les versions précédentes. Il note de 0 à 10 chaque critère de sa grille et le programme dans son ensemble, et justifie chaque point perdu. Note retenue par relecteur et par profil : la note d'ensemble. Le lot corrige le moteur (jamais la grille ni le profil pour « faire passer ») et refait noter.
- **Seuil (DECISIONS_CP.md, Q « seuil ») : 9/10 partout** — chaque relecteur, chaque profil du périmètre du lot, **et** 0 violation de sécurité aux critères calculables. **Au plus 6 boucles de calibrage** par lot : si le seuil n'est pas atteint, livre la meilleure version avec le tableau des écarts restants, marque ta ligne « livré — seuil non atteint (<profils>) » et notifie « Kalis Track <LOT> : décision requise — seuil 9/10 non atteint » (détail et recommandation dans ta section de `DECISIONS_CP.md`).
- **Page de relecture du propriétaire** (créée par CR ; outil Artifact, skills `artifact-design` puis `artifact-capabilities`, base partagée) : une sélection de programmes générés (du débutant à l'élite street, puis les autres disciplines), lisibles sur téléphone, que le propriétaire note (1 à 10, par critère et d'ensemble) et commente. Chaque lot qui la republie ajoute une **manche** (version du moteur, date) sans effacer les précédentes. Les notes et commentaires du propriétaire **priment sur ceux du panel** : chaque lot moteur lit d'abord toutes les notes reçues (outil ArtifactData) et traite chaque commentaire (corrigé, ou expliqué dans sa livraison). Lien dans `ETAT_CP.md`.
- **Références privées** (programmes payants, protégés par le droit d'auteur ; **le dépôt est public**) : chiffrées sur la branche orpheline `cp-references` (`references.tar.gpg`, mode d'emploi dans son `README.md`). La **clé** n'est donnée que dans le message de lancement des lots qui en ont besoin (« Clé des références : … ») ; elle n'est **jamais** écrite dans un fichier, un commit, un journal de CI, une page, une notification ou une livraison. Déchiffrement dans `/tmp/cp-references` (hors du dépôt) ; tout ce qui contient une partie des programmes (analyse détaillée, séances, schémas, ancres du panel, ensembles exercices × schémas pour la non-ressemblance) reste dans `/tmp` ou est rajouté sur `cp-references` **chiffré avec la même clé** (`analyse_<LOT>.tar.gpg`), jamais en clair sur aucune branche. Les références servent à extraire des principes chiffrés (structure, volumes, intensités, progressions, tests, affûtage) et à comparer ; elles ne sont **jamais** recopiées dans un programme généré (indice de Jaccard des exercices × schémas < 0,30 par profil, calculé dans la session avec la clé, seul le résultat est publié ; même règle pour le programme du propriétaire, PIPELINE G4), ni publiées, ni **nommées** (aucun nom d'auteur ou de programme hors de l'archive chiffrée : ni dans `packages/`, ni dans les livraisons, `DECISIONS_CP.md`, les messages de commit, la page de suivi, la page de relecture ou l'application). Dans `packages/`, seulement des mesures agrégées et anonymes (fourchettes). Un lot qui a besoin des références et n'a pas reçu la clé : « en attente du propriétaire », notification « Kalis Track <LOT> bloqué — clé des références absente », arrêt.

## 3. Exigence

- **Effort maximal (Fable)** : chaque règle ou paramètre chiffré vient d'une référence citée (méta-analyse, étude, ouvrage de référence) ou d'une mesure (banc, simulation) ; ce qui n'est qu'un choix raisonné est dit comme tel. Chaque invariant est testé. Chaque rapport est lu en entier. Relecture indépendante (sous-agent) du code et du contrat avant livraison, comme G4 et G8.
- **Deux publics, un moteur** : chaque règle dit comment elle se comporte du débutant à l'élite ; aucune technique avancée n'est servie à un profil qui ne peut pas la supporter (prérequis explicites : ancienneté, niveau, tests, récupération).
- Budgets (PIPELINE_GP.md §2) inchangés : génération ≤ 1 s, régénération ≤ 300 ms, décision de séance ≤ 50 ms (VM Dart, CI).
- Contrats : additifs seulement (PIPELINE_GP.md §0) ; les versions 0.1 des moteurs restent lisibles par l'application tant que CI n'a pas intégré les nouvelles.
- Le programme personnel de 40 semaines du propriétaire n'est jamais régénéré (D5.10).

## 4. Contrôles et CI

- Voies A et B : `ci-paquets.yml` sur `claude/ci-cp-a` / `claude/ci-cp-b` (`docs/CI_PISTES.md`, section CP) : formatage, `dart analyze --fatal-infos`, `dart test` des paquets touchés **et de ceux qui en dépendent**, propriétés (≥ 10 000 entrées seedées), banc complet, temps de calcul. Un commit de contrôle qui ne touche que `ci-out/` ne déclenche aucun run.
- Voie App : comme la piste A de GP (`docs/CI_GP.md`) ; `pubspec.lock` régénéré si une dépendance change (`flutter pub get --enforce-lockfile` en CI).

## 5. Notifications (PushNotification, < 200 caractères)

- Voies A, B : `Kalis Track <LOT> livré (<paquet> <version>, panel <min>/10). Page : <lien>`.
- CX, CY : `Kalis Track <LOT> : programmes prêts à relire (<disciplines>). Page de relecture : <lien>`.
- Voie App : `Kalis Track <LOT> prêt à tester — devX.Y.Z. À tester : <quelques mots>. Page : <lien>`.
- Décision : `Kalis Track <LOT> : décision requise — <question>` ; blocage : `Kalis Track <LOT> bloqué — <cause>`.

## 6. Page de suivi

La page « Suivi Kalis Track GP » (lien dans `ETAT_CP.md`) reçoit une **quatrième partie « Calibrage »** (créée par le premier lot CP qui livre) : section par lot en tête de la partie, ligne dans le tableau des lots. Mêmes règles de republication que PIPELINE_GP.md §6. Aucun extrait des programmes de référence.

## 7. Fin de lot

1. Version : paquets 0.(y+1).0 pour une évolution (correction : x.y.(z+1)) ; voie App : devX.Y.Z (PIPELINE_GP.md §7.1).
2. Publication : voies A, B → push sur `moteurs` (§0) puis branche fixe `etiquettes/<paquet>-v<version>` ; voie App → `main` + build signé réussi.
3. `LIVRAISON_<LOT>.md` dans `pipeline/cp/livraisons/` et dans le projet claude.ai (`claude/LIVRAISON_<LOT>.md`) : ce qui est livré, rapport du banc avant/après, notes du panel par relecteur et par profil, notes du propriétaire traitées, limites, ce qui reste.
4. `ETAT_CP.md` (ta ligne) ; page de suivi ; notification ; **arrête-toi** (aucun `fire_trigger`).

Interdits : ceux de PIPELINE_GP.md §7 ; plus : lancer un lot ; publier ou committer en clair un extrait, un nom d'auteur ou la clé des programmes de référence ; modifier la grille du panel ou un profil type pendant un calibrage pour atteindre le seuil.

## 8. Enchaînement

| Lot | Voie | Prompt | Action unique | Prérequis | Validation |
| --- | --- | --- | --- | --- | --- |
| CR | A | CR.txt | Référentiel scientifique, banc d'essai `kalis_bench` (profils types, références encodées, critères), protocole et grilles du panel, page de relecture, mesure des moteurs actuels (0.1) | références du propriétaire reçues (« c'est tout ») | auto |
| CQ | B | CQ.txt | Profil v3 (questions qui changent vraiment la tolérance à l'entraînement et la programmation) et contrats `kalis_core` 0.4.0 (prescriptions avancées, périodisation, spécialisation) | — | auto |
| CP1 | A | CP1.txt | `kalis_plan` 0.2.0 — street au niveau coach d'élite, calibré au banc et au panel (≥ 9/10) | CR, CQ | auto |
| CA1 | B | CA1.txt | `kalis_adapt` 0.2.0 — street : nouvelles prescriptions, affûtage, tests, récupération, calibré (≥ 9/10) | CR, CQ | auto |
| CU | App | CU.txt | Parcours de création v3 dans l'application (questions du profil v3, `kalis_core` 0.4.0) | CQ | propriétaire |
| CX | A | CX.txt | Croisement `kalis_plan` 0.2 ↔ `kalis_adapt` 0.2 sur macrocycles street (compétition, tests), panel des trajectoires, manche street de la page de relecture | CP1, CA1 | **propriétaire** (page de relecture) |
| CP2 | A | CP2.txt | `kalis_plan` 0.3.0 — musculation, force, cardio, mobilité, CrossFit au niveau coach (≥ 9/10), street inchangé ou meilleur | CX | auto |
| CA2 | B | CA2.txt | `kalis_adapt` 0.3.0 — mêmes disciplines (cardio, conditionnement, mobilité désormais modélisés), calibré (≥ 9/10), street inchangé ou meilleur | CX | auto |
| CY | A | CY.txt | Croisement final `kalis_plan` 0.3 ↔ `kalis_adapt` 0.3, toutes disciplines, panel des trajectoires, manche finale de la page de relecture | CP2, CA2 | **propriétaire** (page de relecture) |
| CI | App | CI.txt | Intégration des moteurs calibrés dans l'application (nouvelles prescriptions en séance et dans le programme, périodisation, affûtage, tests) | CY, CU | propriétaire |

Ordre (un seul lot moteur à la fois, C3.2) : CQ → CR → CP1 → CA1 → CX → CP2 → CA2 → CY ; voie App en parallèle d'un lot moteur : CU dès que CQ est livré, CI après CY et CU. G12 à G15 (pipeline GP) : reprise décidée plus tard par le propriétaire.

## 9. Budget d'utilisation (DECISIONS_CP.md C3)

Le pipeline tourne sur le plan Max du propriétaire : une limite par fenêtre de 5 h et une limite hebdomadaire pour tous les modèles réunis ; **Fable ne peut consommer que 50 % de la limite hebdomadaire et la consomme plus vite que les autres modèles**. Le 02/10 au soir, les limites ont été épuisées et les deux sessions se sont arrêtées en perdant leur travail non poussé. Règles :

1. **Sous-agents sur Opus** : chaque appel de l'outil Agent (relecteurs du panel, relectures indépendantes, vérification des références, recherches) passe explicitement `model: "opus"` (Opus 5.5) ; aucun sous-agent n'hérite de Fable. Le lot lui-même reste sur Fable, effort maximal.
2. **Panel économe** : chaque boucle de calibrage recalcule les critères calculables sur **tous** les profils (sans coût de modèle), mais ne fait renoter par le panel que les couples (école, profil) **sous 9/10** à la boucle précédente et ceux dont l'export a changé de plus de 10 % des lignes ; une **passe complète** du panel (toutes les écoles, tous les profils du périmètre) est faite seulement au départ (mesure avant) et à la fin (avant livraison) — une régression trouvée par la passe finale ouvre une boucle de plus (dans la limite des 6). Jusqu'à 4 profils d'une même école par appel ; exports concis (pas de redite d'une semaine identique à la précédente : « comme semaine N, sauf … »).
3. **Sauvegardes** : au moins toutes les 30 minutes de travail et à chaque étape importante, pousse l'état complet de ton travail sur la branche `cp-sauvegardes/<LOT>` par un commit dont l'arbre **ne contient pas `.github/`** (aucun workflow ne se déclenche ; `git commit-tree` sur l'arbre de travail sans `.github`, message « Sauvegarde <LOT> : <étape> ») ; ce qui contient une partie des références va chiffré sur `cp-references` (§2). Avant chaque sauvegarde, écris aussi l'avancement dans `cp-sauvegardes/<LOT>:SAUVEGARDE.md` (fait, en cours, reste à faire, décisions prises) : c'est ce que lit une session de reprise.
4. **Reprise** : une session lancée avec « à faire (reprise) » ou « en cours depuis » plus de 6 h lit d'abord `cp-sauvegardes/<LOT>` (et `SAUVEGARDE.md`), puis la branche de contrôle de sa voie et `cp-references`, et repart de là sans refaire ce qui est fait — en vérifiant ce qu'elle reprend.
5. **Sobriété** : pas de lecture répétée de gros fichiers déjà lus ; recherches web ciblées ; attendre un contrôle de CI sans le surveiller en boucle (une vérification toutes les 10 minutes au plus).

