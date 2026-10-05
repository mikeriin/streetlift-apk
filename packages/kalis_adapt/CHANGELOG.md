# Journal des versions de kalis_adapt

## 0.2.2

Lot « CX correction 1 » du pipeline « Calibrage des programmes » (croisement avec `kalis_plan` 0.2.2).
`kalis_core` 0.4.2. Le mode 0.1 est inchangé. Détail et sources : `CONTRAT.md`, § 11.

- **Douleur qui dure ou qui revient (mode coach, sécurité)** : suivi daté des signalements par zone ; arrêt
  quand la douleur reste à 3/10 ou plus deux semaines, à 5/10 ou plus plus d'une semaine, ou revient dans les
  douze semaines après un épisode réel ; levé après deux semaines sans signalement au-dessus de 2/10. Pendant
  l'arrêt, les mouvements qui provoquent la zone sont retirés des séances (`adapt.pain_persistent`) et la
  revue propose de les écarter du bloc ; la douleur montrée dans le journal reste celle du dernier
  signalement récent.
- **Sous-dosage** : chaque série est jugée contre sa propre réserve visée ; une série facile n'est plus lue
  comme « plus dure que prévu » ; une série au ressenti qui suppose moins de 90 % de la prédiction est lue
  comme une borne basse, et la baisse attend une deuxième mesure concordante, une autre séance, dans les
  quatre semaines (une mesure conforme efface la borne en attente) ; cran d'élastique retiré après deux
  séances au haut de la plage à charge et plage égales (ou une première série dite deux répétitions plus
  facile).
- **Douleur, revue** : en mode coach, seul l'arrêt (et sa fin) signale une douleur qui dure ; un épisode
  tolère deux semaines entre deux signalements.
- **Tests** : retirés un jour de bilan bas (1 sur 5 de baisse ou plus) et refaits à une séance suivante de la
  semaine, 48 h après au moins, un bon jour sans douleur, avec le matériel du lieu du jour et seulement pour
  une étape de figure acquise ; jours bas et milieu des tentatives lus comme en 0.2.1 hors mode coach.
- **Charges** : tentatives (ouverture 91 %, deuxième +5 % au plus, troisième +3 % au plus, +5 kg de charge
  externe au plus ; la meilleure barre entre la réussie et la manquée est reportée) ; −7,5 % après une série
  manquée non voulue, gardé sur les séries suivantes de la séance ; simple d'entraînement à 92 % du maximum estimé au plus (85 % un jour de bilan bas) ;
  semaine allégée ou de test : jamais plus lourd que la charge écrite.
- **Tenues** : la borne de hausse d'une tenue laisse toujours servir 55 % du meilleur maintien mesuré.

## 0.2.1

Lot CX du pipeline « Calibrage des programmes » (croisement avec `kalis_plan` 0.2.1). `kalis_core` 0.4.2.

- **Correction : une proposition appliquée gardait le bloc au contrat 0.4.0** (`applyProposal`) : le diff de
  prescriptions reconstruisait les semaines sans leur intention (ni les autres champs du contrat 0.4.0), et le
  bloc repassait au mode 0.1 pour la suite (vu sur les saisons croisées : bloc après une proposition de
  volume servi sans phase). Les semaines et séances d'un bloc qui porte une intention sont maintenant
  copiées (`copyWith`) ; un bloc de 0.1 est reconstruit comme en 0.2.0, à l'octet près.

- **Changement de profil en cours de saison** (`simulation.dart`) : `simulate(changes: …)` applique un
  `ProfileChange` au début d'une semaine (échéance avancée, par exemple) ; s'il le demande, le bloc en
  cours s'arrête et le bloc suivant est écrit sur le profil changé. `SimRun.changes` garde la trace. Sans
  `changes`, la simulation suit 0.2.0 (aux blocs près que la correction d'`applyProposal` garde au contrat 0.4.0).

## 0.2.0

Lot CA1 du pipeline « Calibrage des programmes » : faire évoluer un athlète street comme un coach qui le
suit. `kalis_core` 0.4.1, `kalis_plan` 0.2.0.

- **Mode coach** (`CONTRAT.md`, § 11) pour les blocs qui portent le contrat 0.4.0 (intentions, techniques,
  intensités, règles d'autorégulation, tests, échelles de figures) : la semaine dit ce qui est permis
  (affûtage, décharge, test et compétition servis tels quels, jamais de série ajoutée) ; charge écrite en
  part du 1RM pilotée par la réserve dans un couloir, hausse bornée à schéma égal ; toutes les techniques
  de série exécutées et relues dans le journal (`readLine`), jamais servies sans leurs prérequis ; règles
  d'autorégulation exécutées (séries allégées sur la série de tête réalisée, arrêts) ; tests et
  tentatives (ouverture, deuxième, troisième, d'après le maximum estimé et son incertitude) ; figures
  (étape en cours, critère de passage, étape plus facile un mauvais jour, hausse des maintiens bornée
  pour les tendons) ; douleur à 5 sur 10 (exercice gardé, allégé) ; récupération déclarée du profil v3 ;
  reprise graduelle après une coupure.
- **Notes d'effort** : loin de l'échec, une note se lit comme une borne ; série repère quand les notes
  n'informent plus ; biais de note appris sur les tests (limite 4 de 0.1) ; courbe apprise sur les séries
  proches de l'échec.
- **Sorties** (`kalis_core` 0.4.0) : `SessionPlan.phase`, `weekIntent`, `eventId`, `groups` ;
  `IntraSessionAdvice.miniSetsLeft`, `stepExerciseId` ; `AdaptReview.testResults`, `skillStates` ;
  `AdaptationSummary.benchmarks`, `skills`, `volumeTolerance` ; `EventDayAdvisor.planEventDay`
  (échauffement, tentatives, rythme d'une épreuve de répétitions) ; nouveaux codes de raison `adapt.*`
  de 0.4.0.
- **Règles issues du calibrage au panel** (`docs/CALIBRAGE_CA1.md`, `CONTRAT.md` § 11.4, 11.5, 11.9) :
  seules les séries qui montrent la capacité la mesurent (série au ressenti arrêtée avant le haut de sa
  plage, test, série restée sous sa cible) — les autres ne donnent qu'une borne basse ; séries repère sur
  une plage, une série de tête ou un maintien ; répétitions et maintiens écrits en part d'un test recalés
  sur le maximum mesuré, dans les deux sens ; haut d'une plage servi à la réserve du bloc ; séries
  fractionnées quand la plage est hors de portée ; maintien trop facile remonté vers la moitié du maximum ;
  exercice assisté : cran d'assistance conseillé et lu dans le journal ; exercice jamais fait : entrée à
  60 % de la charge de référence ; séries allégées pilotées sur la série de tête réalisée ; zone
  douloureuse : volume gelé ; alerte de surmenage (deux séances mesurées de suite à −5 % : une semaine à
  40 % de lignes en moins sur le mouvement) ; un test fait un jour de bilan nettement bas ne fait pas
  baisser le repère.
- **0.1 conservé** : un bloc sans champ du contrat 0.4.0 (programmes de `kalis_plan` 0.1, programme
  importé du propriétaire) est servi comme en 0.1.0 ; `KalisAdapt(legacy: true)` sert tout bloc comme en
  0.1.0.
- **Simulateur** : deux modèles de vérité de plus (B et C, `TruthKind`), exécution des techniques, des
  tests et des tentatives, journal aux champs de 0.4.0, résultats de test reportés au profil, programmes
  de test à techniques injectées (`injectTechniques`), coach simple à la note d'effort (`RpeCoachPolicy`),
  mesures du mode coach (`CoachMetrics`).
- **Validation** : invariants I1 à I8 inchangés sur 10 240 journaux aléatoires ; invariants du mode coach
  (C1 à C4, I2 à I8) sur 10 240 journaux aléatoires aux champs de 0.4.0, programmes street du banc et
  programmes à techniques injectées ; campagne street de `kalis_bench` (17 profils, trois modèles de
  vérité, quatre politiques) ; règles du calibrage (`test/coach_rules_test.dart`) ; calibrage au panel
  (`docs/CALIBRAGE_CA1.md`) : 34 couples sur 68 à 9 ou plus, minimum 7 — **cible « 9 partout » non
  atteinte**, les corrections restantes portent sur le programme écrit par `kalis_plan`.

## 0.1.0

Première version (lot G8 du pipeline « Génération et progression »).

- `KalisAdapt` réalise `AdaptEngine` de kalis_core 0.2.0 : `prescribeSession`, `adviseNextSet`,
  `review` ; `estimates`, `applyProposal`.
- Modèle individuel : filtre de Kalman par exercice sur la capacité opérationnelle (tendance locale
  amortie, forme de la courbe répétitions ↔ charge, effet de jour), observation des séries avec bornes
  (notes absentes, « 5 et plus », séries terminées, séries ratées), écrêtage des écarts aberrants,
  fatigue dans la séance, forme et fatigue entre les séances, forme du jour, notes peu informatives,
  partage entre exercices proches, coupures.
- Séries enchaînées (supersets, tours) lues dans l'ordre de réalisation ; pivot de la courbe déplacé
  quand la plage change ; séries manquées douteuses écrêtées.
- Décisions : charge à hystérésis sur la grille réelle du matériel, plafonds de hausse, calibrage,
  séries notées « 5 et plus », conseil pendant la séance (écart de 2 flammes), série repère, bilan santé
  gradué, douleur, lieu et temps du jour, charge minimale trop lourde, programme importé, tests.
- Revue : résumé d'adaptation, propositions (volume, décharge anticipée, échange, épargne d'une zone,
  restructurations par `kalis_plan`) filtrées par déblocage, confiance et utilité ; records ; journal du
  moteur.
- Simulateur d'athlètes à vérité connue (`lib/simulation.dart`), comparaison à la double progression, à
  l'ancien moteur L7/L11 et à l'oracle ; lignes de commande `kalis_adapt:simulate`, `kalis_adapt:replay`,
  `bin/kalis_adapt_cli.dart`.
- Validation : `docs/` (mesures de la campagne, lecture, rejeu du programme importé du propriétaire),
  référence croisée Python, tests de propriétés sur 10 240 journaux aléatoires.
