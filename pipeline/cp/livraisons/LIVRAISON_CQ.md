# Livraison CQ — profil v3 et contrats `kalis_core` 0.4.0

Lot CQ du pipeline « Calibrage des programmes » (voie B, Fable 5.1, effort maximal). Livré le 03/10/2026.
Validation : automatique (contrôles verts).

| | |
| --- | --- |
| Paquet | `kalis_core` **0.4.0** (évolution additive depuis 0.3.0) |
| Branche de travail | `moteurs`, commit `ef4c57ae` — « Kalis Track moteurs (CQ) : kalis_core 0.4.0 » |
| Étiquette (branche fixe) | `etiquettes/kalis_core-v0.4.0` |
| Contrôle | `claude/ci-cp-b`, run 37106401044 : `kalis_core`, `kalis_plan`, `kalis_adapt`, `kalis_quest` et `tools/catalog` verts |
| Profil v3 | **16 questions pour un débutant** (16 à 18 selon la discipline), **29 pour un compétiteur élite** |

## Déroulement

Le lot a tourné en deux sessions. La première (02/10, 20:03 UTC) a écrit la revue des facteurs, le parcours, les
contrats, les tests, fait faire les trois relectures et intégré leurs remarques ; elle s'est arrêtée (limites
d'utilisation, DECISIONS_CP.md C3) avant la livraison, son travail conservé sur `claude/ci-cp-b`. La seconde
(03/10, 05:51 UTC) a repris cet arbre **en le vérifiant** : recontrôle indépendant des 84 références (9 corrections),
audit indépendant des suites données aux 141 remarques des relecteurs (constats traités), formatage, contrôle final,
publication. Le message de lancement de la seconde session ne portait pas la ligne « Lot : … » : CQ était le seul
lot de la voie B qui pouvait tourner (« en cours » depuis plus de 6 h, PIPELINE_CP.md §1.3) ; c'est lui qui a été
repris.

## 1. Revue des facteurs — `packages/kalis_core/docs/PROFIL_V3.md`

Règle (C1.6) : une question n'est posée que si un effet sur la tolérance, la réponse ou le risque est démontré (ou
solidement admis par l'usage, sans coût), **et** si la réponse change une décision du programme, **et** si elle ne
se déduit pas d'une autre réponse ou du journal. Elle n'est posée qu'à ceux pour qui elle compte.

**Posées** (17 facteurs, 14 questions nouvelles) :

| Facteur | À qui | Preuve | Ce que ça change |
| --- | --- | --- | --- |
| Ancienneté dans la discipline | niveau ≥ intermédiaire | forte | volume et intensité de départ, rythme, périodisation, prérequis des techniques |
| Interruption récente | ancienneté ≥ 6 mois | modérée | reprise progressive ; figures reprises une étape en dessous (choix raisonné) |
| Charge d'entraînement actuelle | niveau ≥ avancé | usage d'entraîneur | volume et fréquence du premier bloc |
| Tests et records | niveau ≥ intermédiaire | forte (mesure) | charges en part du maximum, tentatives, tests seulement là où il manque une valeur |
| Figures : cible, étape, ancienneté à l'étape | calisthénie, streetlifting, CrossFit | indirecte (tendon) | étape de départ, maintiens, critère de passage |
| Orientation en musculation | musculation au programme | modérée | plages de répétitions, répartition du volume |
| Compétition et échéances | intermédiaire, objectif de performance, ou cardio | forte | plan de saison, affûtage, tentatives |
| Spécialisation | avancé (intermédiaire en musculation) | usage | volume concentré, reste entretenu |
| Points faibles | avancé, disciplines de force | faible | choix de l'assistance (heuristique assumée) |
| Volume de course actuel | cardio ou course en échéance | usage | premier bloc de course, confiance des allures |
| Sommeil habituel, stress habituel | tous (débutant : après la 1re semaine) | forte en aigu, faible en habituel ; modérée | valeurs de départ ; jamais de baisse de charge pour le sommeil |
| Métier physique, autres sports | tous (débutant : après la 1re semaine) | modérée à forte (autre sport), absente (métier) | **placement** des séances, pas un coefficient |
| Évolution voulue du poids | intermédiaire, ou discipline au poids du corps (débutant : après la 1re semaine) | modérée | attentes, lest et charge totale |
| Antécédents (précisés) | tous | forte (principe) | variante en dessous, pas de test maximal si gêne ≥ 4/10 |
| Poids, âge, sexe, taille | tous (schéma 2) | — | poids : charge ; âge : prudence des tests ; sexe et taille : aucun effet sur le programme |

**Déduites** : qualité du sommeil et nuit de la veille (bilan de séance), travail de nuit (sommeil), fatigabilité
selon le sexe (séries réalisées), asymétrie (séries unilatérales), mobilité limitante (revue du programme,
premières séances), interruption et charge après la création (journal).

**Écartées** : moment de la journée (aucun effet sur les gains), cycle menstruel et contraception (effet trivial ou
nul), longueur des segments, hyperlaxité (auto-déclaration peu fiable), nombre de pas, protéines, alcool, tabac,
médicaments (hors périmètre), faible disponibilité énergétique (diagnostic clinique), tout score de risque de
blessure (les dépistages ne prédisent pas la blessure d'un individu).

Valeur habituelle (profil) et valeur du jour (bilan de séance, D5.8-D5.9) ne font pas doublon ; règle L13 tenue
(aucune réponse du questionnaire santé dans le profil ; les antécédents sont des contraintes d'entraînement) ;
une réponse absente reste absente.

**Références** : 84, chacune avec son statut (notice et résultat lus dans le résumé, ou source secondaire dite).
Recontrôle indépendant du 03/10 : 9 corrections (une progression « deux fois plus lente » vraie chez les hommes
seulement ; « 2 ans » = entrée en plateau et non fin ; affûtage sur 1 à 2 semaines et non 7 à 28 jours ;
interférence du bas du corps chez les hommes seulement ; attribution de l'exposant 1,06 de la formule de Riegel ;
quatre notices). Limites dites dans le document : Crossref, doi.org et PubMed inaccessibles depuis les sessions
(DOI lus sur les pages des éditeurs, non résolus) ; aucun texte intégral relu ligne à ligne ; aucun contenu relu
par un professionnel de santé ou un entraîneur diplômé. Quand la littérature donne une direction sans grandeur
(sommeil, stress, déficit, antécédent, reprise), le document dit « choix raisonné » et ne chiffre rien : les
règles chiffrées relèvent du référentiel de CR et des moteurs calibrés.

## 2. Parcours de questions — `docs/PARCOURS_V3.md`, `data/parcours_v3.json`

Arbre adaptatif : 31 questions (17 du schéma 2, 14 du schéma 3), 14 écrans, conditions d'apparition (`when`),
questions reportées après la première semaine (`deferWhen`), obligatoires sous condition (`requiredWhen`),
« Passer » et « Je ne sais pas ». L'application ne code aucune condition : elle appelle `ProfileQuestionnaire`.

| Profil type | Questions à la création | dont schéma 3 | Reportées |
| --- | ---: | ---: | --- |
| Débutant, forme générale | **16** | 0 | sommeil, stress, charge hors programme |
| Intermédiaire, musculation | 27 | 10 | — |
| Compétiteur élite, streetlifting | **29** | 12 | — |
| Coureuse, 10 km | 28 | 11 | — |
| Sets & reps, avancé | 29 | 12 | — |

Débutant selon la discipline : 16 (forme générale, mobilité, street workout), 17 (musculation : orientation ;
CrossFit, streetlifting, calisthénie : figure visée), 18 (cardio : course préparée et volume actuel). Aucune
question de récupération à la création pour un débutant ; un débutant en forme générale voit une question de moins
qu'avec le parcours G6.

Tests guidés (10 protocoles, avec sécurité, consignes, prérequis, moment et conversion) : série lourde
d'estimation (Brzycki, 3 à 6 répétitions), série lestée (charge totale), maximum direct, répétitions max, maintien
max, course 6 minutes, contre-la-montre de 5 km (Riegel jusqu'au semi-marathon), sans test (seul permis au
débutant), répétitions en temps limité, séries maximales répétées. Compétition : streetlifting (mouvements,
tentatives, sauts, catégories ; préréglages Final Rep et ISF), sets & reps (postes, tours, temps, séries
indivisibles, format annoncé le jour même), freestyle, course, test perso ; date exacte ou mois ; priorité ;
plusieurs échéances.

## 3. Contrats 0.4.0 — `CONTRAT.md` § 11 à 16, `docs/TYPES.md`

35 types nouveaux (109), 38 énumérations nouvelles (92), 38 codes de raison (130) avec un texte court de Koach.

- **Profil v3 (schéma 3)** : champs optionnels issus du parcours ; migration v2 → v3 sans perte ni invention.
- **Prescriptions avancées** : 17 techniques de série (normale, top set + back-off, clusters, rest-pause,
  myo-reps, dégressive, isométrie, excentrique accentuée, contraste, vagues, pyramide, AMRAP, EMOM, densité,
  échelle, contre la montre, pratique de figure) ; intensité en part du 1RM, d'un test, en RIR, en part d'une
  vitesse, en lest relatif au poids de corps ; 7 règles d'autorégulation (dont back-off à −x % de la top set
  réalisée, plafond de RIR) ; séries de test ; groupes d'exercices enchaînés (7 formats) ; journal : une ligne par
  série, détail dans `parts` (les comptes des moteurs 0.1 restent justes).
- **Périodisation** : plan de saison (10 natures de phase) au-dessus des blocs de 4 à 6 semaines (D4.8
  inchangé), intention du bloc et de la semaine, ondulation (jour lourd, moyen, léger), périodisation par mouvement.
- **Spécialisation, figures** : cible, durée, entretien ; échelle de progression (`variante_de` + critères de
  passage), état actuel.
- **Compétition** : échéance, épreuves, tentatives ; interface `EventDayAdvisor` (tentatives, montée
  d'échauffement, rythme) ; interface `SeasonPlanner`.
- **Interfaces** : seulement des champs optionnels ajoutés aux requêtes et résultats existants, ou des
  interfaces nouvelles. Énumérations d'avant 0.4.0 fermées ; celles de 0.4.0 ouvertes (cas par défaut).

## 4. Rétrocompatibilité (vérifiée)

- `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0 et `kalis_quest` 0.1.0, **sources inchangées**, compilent et passent tous
  leurs tests avec `kalis_core` 0.4.0 (run 37106401044).
- JSON du schéma 2 relu et réécrit à l'identique (40 profils types) ; tests de propriétés sur 10 000 valeurs
  seedées par type (aller-retour, migration, `validate()`), 10 000 profils et 10 000 séances aléatoires.
- Additivité contrôlée par un test Python contre la surface du contrat 0.3.0.
- Seul changement visible : `AthleteProfile()` construit sans `schemaVersion` écrit le schéma 3. **Une
  application restée en 0.3.0 refuse un profil au schéma 3** : ne migrer qu'après la mise à jour.

## 5. Relectures

Trois relectures indépendantes (contrat et code : 29 remarques ; « débutant pressé » : 37 ; « coach d'élite » :
75), puis un audit indépendant des suites données. Bilan : 105 changées, 20 changées en partie (raison dite), 16
expliquées, aucune sans suite — `docs/RELECTURES_CQ.md`.

## 6. Consignes pour CU

1. Récupérer `packages/kalis_core` par `etiquettes/kalis_core-v0.4.0` ; lire `INTEGRATION.md` § 6 et
   `docs/PARCOURS_V3.md` (écrans, ordre, textes, validations : écrit pour être implémenté tel quel).
2. Ne coder aucune condition : `visibleQuestions`, `deferredQuestions`, `isRequired`, `eligibleTests`.
3. Proposer les questions reportées après la première semaine (carte discrète de Koach, une fois).
4. « Compléter mon profil » pour les utilisateurs existants : `since: 3, includeDeferred: true`.
5. Ne migrer un profil au schéma 3 qu'une fois l'application en 0.4.0 ; le programme personnel du propriétaire
   n'est jamais régénéré (D5.10).
6. À la charge de CU (demandes des relecteurs) : barre de progression ; dessin de la carte du corps ; libellés des
   points faibles du dips et du squat sur le modèle de la traction ; la phrase sur le lieu de stockage des données
   de santé (à écrire d'après le stockage réel, D26).
7. Revérifier dans l'application les nombres de questions par profil type (`test/fixtures/profiles_v3.json`).

## 7. Limites et suites

- Recommandations au propriétaire (décisions en place, non modifiées) : taille obligatoire sans effet (à rendre
  facultative à la prochaine rupture) ; 1 à 2 disciplines secondaires obligatoires (D3.2), alors que les deux
  relecteurs du parcours demandent « rien d'autre » ; mode assisté ou libre et niveaux par mouvement demandés au
  débutant dès la création (D3.7, D3.5) ; `BodyZone` sans bras ni avant-bras (énumération fermée).
- Laissé aux lots suivants (ajouts additifs à leur initiative) : CP1 — auto-contrôles de mobilité par figure,
  heure de passage, format de freestyle ; CA1 — tours déjà faits le jour d'une épreuve de répétitions, règle de
  coupure d'un poste ; CP2 — fréquence cardiaque, profil du parcours de course.
- Pas de SDK Dart dans les sessions : formatage, analyse et tests Dart sont ceux de la CI.
- Contenu sportif non relu par un professionnel diplômé.
