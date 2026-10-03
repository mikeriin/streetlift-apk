# Décisions du pipeline « Calibrage des programmes » (CP)

Ces décisions **font foi** pour tous les lots CP. Les décisions du pipeline GP (`pipeline/gp/DECISIONS_GP.md`, D0 à D9) restent valables sauf mention contraire ici. Chaque lot écrit **seulement dans sa section** (en bas), sans toucher aux autres.

## C0. Demande du propriétaire (02/10/2026, 21:35)

> « Annule G12 et le prochain, on va faire un calibrage du créateur de programmes et le peaufiner au maximum pour qu'il soit optimisé pour monsieur tout le monde mais aussi pour qu'il soit aussi efficace qu'un coach personnel pour athlète de haut niveau. »

- **C0.1** G12 et G13 (pipeline GP) annulés ; G12 à G15 reprendront plus tard, à la décision du propriétaire (DECISIONS_GP.md D0.14).
- **C0.2** Double exigence, un seul moteur : « monsieur tout le monde » **et** coach personnel d'athlète de haut niveau.

## C1. Questionnaire (02/10/2026, 21:38-21:44)

- **C1.1 Périmètre** : le moteur de création (`kalis_plan`), le parcours de création dans l'application, le moteur d'évolution (`kalis_adapt`).
- **C1.2 Références de qualité** : un panel de coachs virtuels, des programmes de référence, la littérature scientifique.
- **C1.3 Haut niveau — ce qui doit exister** : périodisation avancée (blocs, ondulation, pic de forme et affûtage pour une compétition ou un test), techniques d'intensification (top set + back-off, clusters, rest-pause, séries dégressives, isométrie, excentriques, etc.), figures et skills (progressions, pratique, maintiens), spécialisation (priorité à un mouvement ou une figure, entretien du reste).
- **C1.4 « Monsieur tout le monde »** (texte du propriétaire) : « Monsieur tout le monde comprend les débutants comme les sportifs réguliers qui ont un très bon niveau, donc un peu de tout en fonction du profil. » → le moteur s'adapte à tout le spectre ; ce qui est servi dépend du profil, pas d'un mode.
- **C1.5 Disciplines** : **street d'abord** (streetlifting, sets & reps, calisthénie et figures), puis les autres (musculation, force, cardio, mobilité, CrossFit) **juste après** le street.
- **C1.6 Profil** : tests et records, compétition et échéances, points faibles et historique (blessures), récupération et vie (sommeil, stress, travail physique…). Consigne du propriétaire : « J'ai tout coché mais il faut demander ce qui est vraiment pertinent et qui a un impact réel sur la manière dont le corps supporte les entraînements. » → chaque question du profil doit justifier un effet réel et documenté sur la tolérance à l'entraînement ou sur la programmation ; sinon elle n'est pas posée.
- **C1.7 Panel** : quatre écoles — force et streetlifting ; calisthénie et figures ; hypertrophie et esthétique ; endurance, santé et kiné.
- **C1.8 Relecture du propriétaire** : une page de relecture (programmes générés à noter et commenter).
- **C1.9 Organisation** : « Lots enchaînés Fable et tout ce qui peut être fait en parallèle, alors le faire en parallèle. » → voies A et B (Fable 5.1, effort maximal) en parallèle sur les moteurs, voie App (Opus 5.5) pour l'application (PIPELINE_CP.md §0).
- **C1.10 Seuil** : **9/10 partout** (chaque relecteur du panel, chaque profil type du périmètre du lot).
- **C1.11 Deuxième passage** (autres disciplines) : juste après le street.
- **C1.12 G12 et G13** : « Je déciderai plus tard. »

## C2. Programmes de référence (02/10/2026, 21:46)

- **C2.1** Le propriétaire a transmis le 02/10/2026 à 22:20 six programmes de deux coachs de street workout français (sets & reps : préparations de championnat de France intermédiaire et élite, programmes de tractions, de force et d'endurance), avec ce message : « Voici tous les programmes que j'ai » — la liste est complète (équivaut à « c'est tout »). Noms et inventaire : seulement dans l'archive chiffrée (C2.3).
- **C2.2** Usage : extraire des principes chiffrés et comparer ; **jamais** recopiés, publiés ou nommés dans l'application, la page de suivi, la page de relecture ou le dépôt (PIPELINE_CP.md §2).
- **C2.3** Le dépôt `mikeriin/streetlift-apk` est **public** et ces programmes sont payants et protégés (mentions de copyright) : la conversation de pilotage les a stockés **chiffrés** (GnuPG symétrique AES-256) sur la branche orpheline `cp-references` (commit e9d1818f, `references.tar.gpg`, SHA-256 b27b0105…e8bacbc0). Les deux plus gros documents (images seules, 35 et 60 Mo) y sont rendus en pages JPEG lisibles, avec le texte extrait quand il existe. La clé n'est donnée que dans le message de lancement des lots (CR, puis les lots moteurs qui comparent aux références) ; elle n'est écrite nulle part dans le dépôt.

## C3. Budget d'utilisation (03/10/2026, 07:54-08:00)

> « Tous les lots se sont arrêtés parce que j'ai utilisé tous les crédits d'utilisation. Il faudrait faire en sorte que ça n'arrive plus, sachant quand même que j'ai le plan max. »

Constat : la nuit du 02 au 03/10, les sessions CQ et CR (Fable, effort maximal, en parallèle, sous-agents du panel et des relectures héritant de Fable) et les points de pilotage toutes les 30 min ont épuisé les limites du plan Max ; les deux sessions se sont arrêtées vers 22:15-22:31 UTC en perdant leur travail non poussé (CQ : code conservé sur `claude/ci-cp-b` ; CR : `kalis_bench` conservé sur `claude/ci-cp-a`, analyse des références perdue). Rappel des règles du plan : limite par fenêtre de 5 h et limite hebdomadaire tous modèles ; Fable plafonné à 50 % de la limite hebdomadaire et plus coûteux que les autres modèles.

- **C3.1 Modèles** : choix du propriétaire « Panel sur Opus, lots sur Fable » — tous les sous-agents (panel, relectures, vérifications) sur Opus 5.5 ; les lots moteurs restent sur Fable, effort maximal.
- **C3.2 Parallélisme** : choix du propriétaire « Un lot à la fois » — un seul lot moteur (voie A ou B) tourne à la fois ; la voie App (Opus) peut tourner en même temps.
- **C3.3 Points de pilotage** : choix du propriétaire « Toutes les 2 heures » (au lieu de 30 min) ; les lots notifient eux-mêmes livraison et blocage.
- **C3.4** Mesures de la conversation de pilotage (PIPELINE_CP.md §9) : panel qui ne renote que les couples sous 9/10 entre une passe complète au départ et une à la fin ; sauvegardes toutes les 30 min sur `cp-sauvegardes/<LOT>` (sans workflow) ; reprise depuis la dernière sauvegarde ; relance d'une session arrêtée par les limites après leur remise à zéro.

## Sections des lots

Chaque lot ajoute ici ses décisions techniques numérotées (`CR.1`, `CR.2`…), ses écarts, ses recommandations et, le cas échéant, la question posée au propriétaire.

### CR

### CQ

Lot livré le 03/10/2026 (`kalis_core` 0.4.0, `etiquettes/kalis_core-v0.4.0`). Détail : `pipeline/cp/livraisons/LIVRAISON_CQ.md`, `packages/kalis_core/docs/PROFIL_V3.md`, `PARCOURS_V3.md`, `RELECTURES_CQ.md`.

- **CQ.1 Règle de pose d'une question** (C1.6) : effet démontré ou solidement admis par l'usage **et** décision du programme changée **et** non déductible d'une autre réponse ou du journal ; posée seulement à ceux pour qui elle compte ; toujours passable (sauf champs obligatoires du schéma 2). 17 facteurs posés, 14 questions nouvelles ; le reste est déduit ou écarté, raison dite.
- **CQ.2 Aucun chiffre d'ajustement inventé** : quand la littérature donne une direction sans grandeur (sommeil court, stress, déficit énergétique, antécédent, reprise), le profil porte la réponse et le document dit « choix raisonné » ; les règles chiffrées relèvent du référentiel (CR) et des moteurs calibrés (CP1, CA1), à mesurer au banc.
- **CQ.3 Débutant** : aucune question de récupération à la création (sommeil, stress, charge hors programme, évolution du poids : reportées après la première semaine) ; du schéma 3, seulement ce sans quoi le premier programme ne s'écrit pas (figure visée, orientation en musculation, course préparée et volume de course) : 16 à 18 questions selon la discipline. Aucun test guidé pour un débutant.
- **CQ.4 Énumérations** : celles d'avant 0.4.0 sont fermées (un `switch` exhaustif des moteurs 0.1 doit continuer de compiler) ; celles de 0.4.0 sont ouvertes (lecteurs avec cas par défaut). Un vocabulaire nouveau sur un type ancien passe par un champ optionnel nouveau.
- **CQ.5 Journal** : une série reste une ligne (`SetRecord`) ; mini-séries et paliers sont ses `parts` — les comptes de `kalis_quest` 0.1.0 et `kalis_adapt` 0.1.0 restent justes.
- **CQ.6 Compétition de répétitions** : aucun règlement unifié n'existe ; l'échéance est décrite par des données (postes, tours, temps, séries indivisibles), sans format figé ; les compétitions françaises « Sets and Reps » n'ont pas pu être documentées, leur format se saisit.
- **CQ.7 Priorités entre sources** (pour CP1, CA1) : journal et bilans de séance priment sur les déclarations du profil ; le plan de saison prime sur la spécialisation ; près d'une échéance principale, la phase prime sur le dosage des disciplines secondaires ; un exercice aimé ne déplace jamais un mouvement de compétition.
- **Écart — reprise de session** : la première session s'est arrêtée avant la livraison (C3) ; la seconde, lancée sans la ligne « Lot : … », a repris CQ (seul lot de la voie B qui pouvait tourner, « en cours » depuis plus de 6 h) depuis `claude/ci-cp-b`, en revérifiant les références (9 corrections) et les suites données aux relectures (audit indépendant). Les quatre sous-agents de vérification de la reprise ont été lancés avant que la règle C3.1 (sous-agents sur Opus) soit poussée : ils ont hérité de Fable.
- **Limite** : pas de SDK Dart dans les sessions ; un contrôle de `claude/ci-cp-b` dure environ 45 minutes (les simulateurs des trois moteurs tournent à chaque passe).
- **Recommandations au propriétaire** (aucune n'est bloquante) : (1) autoriser zéro discipline secondaire (D3.2 en impose 1 à 2 ; c'est l'écran où le relecteur « débutant » dit qu'il quitte) ; (2) rendre la taille facultative à la prochaine évolution non additive (aucun effet sur le programme) ; (3) reporter après la première séance, pour un débutant, le choix assisté / libre (D3.7) et les niveaux par mouvement (D3.5) ; (4) ajouter « bras » et « avant-bras » aux zones du corps à la prochaine rupture.

### CP1

### CA1

### CU

### CX

### CP2

### CA2

### CY

### CI
