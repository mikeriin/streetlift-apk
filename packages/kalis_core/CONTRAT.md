# kalis_core — contrat

Version 0.4.2 (lot GC, 01/10/2026 ; évolutions additives des lots G8, G11, CQ, CP1 et CX : `CHANGELOG.md`). Ce paquet fixe **tout ce que les moteurs et l'application
échangent**. Référence exhaustive des types, champ par champ : [`docs/TYPES.md`](docs/TYPES.md)
(généré depuis `tool/contracts_spec.py`, source unique des types).

## 1. Règles générales

- **Dart pur** : aucun import de Flutter ni de `dart:io` dans `lib/`, aucun stockage, aucune horloge
  (« aujourd'hui » est un `CivilDate` passé en paramètre), aucun hasard (les graines sont dans les
  requêtes). Vérifié par `test/purity_test.dart`.
- **JSON versionné** : chaque type racine porte `schemaVersion`. Clé JSON = nom du champ. Un champ
  optionnel nul est **absent** du JSON (jamais `null`, jamais de valeur par défaut). `toJson()` écrit
  les clés dans l'ordre du contrat, et celles des objets JSON libres (`Reason.params`, états opaques)
  triées : deux valeurs égales donnent le même texte à l'octet près. Dans un objet libre, un entier
  et un décimal ne sont pas égaux (`2` ≠ `2.0`) puisqu'ils ne s'écrivent pas pareil.
- **Lecture stricte** : `fromJson` lève `FormatException` si un champ obligatoire manque, a un mauvais
  type ou porte un code d'enum inconnu ; les champs inconnus sont ignorés.
- **Validation séparée de la lecture** : `validate()` rend la liste des violations (`Violation` :
  chemin, code, détail) ; liste vide = valeur valide. Les références au catalogue se contrôlent avec
  `Catalog.checkExerciseIds`, `checkEquipment`, `checkProfile`.
- **Unités** : charges en kg ; durées en secondes (minutes pour les disponibilités et la durée de
  séance) ; distances en mètres ; tailles en cm ; parts en pour cent entiers ; dates en jours civils
  `AAAA-MM-JJ` ; jour de la semaine ISO (1 = lundi … 7 = dimanche) ; rangs (`…Index`) à partir de 0.
- **Aucun texte français dans les sorties des moteurs** : des codes de raison (`Reason`) et leurs
  paramètres ; les phrases viennent de `kalis_koach` et de l'application.
- **Codes d'enum** : anglais pour les contrats ; les enums partagés avec le catalogue gardent les
  codes français du catalogue (`LoadType` : `poids_du_corps`, `Place` : `salle`, `Joint` : `epaule`…).

### Évolution (PIPELINE_GP.md §0)

Après 0.1.0, `kalis_core` n'évolue que de façon **additive** : nouveaux types, nouvelles valeurs
d'enum **en fin de liste** (jusqu'à 0.3.0 ; règle des énumérations depuis 0.4.0 ci-dessous), nouveaux champs
**optionnels**, nouveaux codes de raison. Rien n'est
retiré ni renommé ; le sens et l'unité d'un champ ne changent pas. Une rupture demande une décision
du propriétaire et une montée de `schemaVersion`. Une évolution se fait dans
`tool/contracts_spec.py`, puis `python3 tool/gen_contracts.py` (version x.(y+1).0).
Une valeur d'enum ajoutée n'est lisible que par une version du paquet qui la connaît : l'application
embarque toujours `kalis_core` et les moteurs à des versions livrées ensemble.
**Règle des énumérations, depuis 0.4.0** :

- les énumérations **d'avant 0.4.0 sont fermées** : plus aucune valeur ne leur est ajoutée. Un `switch`
  exhaustif d'un moteur ou de l'application ne compilerait plus (c'est le cas de `WeekKind` dans
  `kalis_plan` 0.1.0). Un vocabulaire nouveau sur un type ancien est une énumération nouvelle, portée par
  un champ optionnel nouveau (`WeekPrescription.intent` à côté de `kind`, `Proposal.detail` à côté de
  `kind`) ;
- les énumérations **introduites en 0.4.0 sont ouvertes** : une version mineure pourra leur ajouter des
  valeurs, en fin de liste. Tout code qui les lit prévoit **un cas par défaut** (pas de `switch`
  exhaustif sans `default`).

L'additivité est contrôlée par un test Python : `tools/catalog/tests/test_contracts.py`
(`test_evolution_additive_depuis_0_3_0`) compare la spécification à la surface du contrat 0.3.0
(`tool/contract_surface_0_3_0.json`) — types, champs, bornes, valeurs des énumérations d'avant 0.4.0,
rang et paramètres des codes de raison.

## 2. Catalogue

`data/catalog_v1.json.gz` = la base v1.1.0 du propriétaire (1 039 exercices, 8 disciplines,
SHA-256 `1a44c2b0…c59b01f6`, copie dans `data/source/`) **telle quelle**, plus un objet `calc` par
exercice. Compilation : `python3 tools/catalog/compile_catalog.py` (règles : `tools/catalog/rules.py`,
version `regles_version`). Aucune valeur n'est saisie exercice par exercice : des tables par catégorie
ou par matériel, puis des retouches par mots-clés sur le nom. Relecture : `docs/RELECTURE_CATALOGUE.md`
(distributions, 60 exemples, cas ambigus) et `docs/relecture_catalogue.csv`.

Schéma du fichier (`schema` = 1) : `source`, `regles_version`, `vocabulaires` (ceux de la base + ceux
des champs calculés), `poids_vecteur`, `references_fraction`, `exercices`.

| Champ `calc` | Dart (`CatalogExercise`) | Règle | Statut |
| --- | --- | --- | --- |
| `schema` (56 valeurs) | `pattern` | table catégorie → schéma ; « Poussée verticale » scindée en haute (au-dessus de la tête) et basse (dips) ; « Mouvement de compétition » rattaché au schéma du mouvement | classement usuel poussée / tirage / genou / hanche / tronc (Boyle 2016 ; NSCA 2016, ch. 17) |
| `famille` (18) | `family` | table schéma → famille | choix raisonné |
| `plan` | `plane` | plan du mouvement de l'articulation dominante ; retouches (prise, latéral, rotation) | convention anatomique (NSCA 2016, ch. 2) ; « multiple » quand aucun plan ne domine |
| `articularite` | `articularity` | par schéma ; sans objet pour les tenues, le cardio, la mobilité | définition NSCA 2016 (ch. 17 : exercices poly- et mono-articulaires) |
| `regime` | `contractionMode` | discipline, schéma et mots-clés (négatif, tenue, explosif…) | choix raisonné |
| `difficulte` 1-10 | `difficulty` | niveau (Débutant 2, Intermédiaire 4, Avancé 7, Élite 9) ± 1 selon la catégorie (figures, haltérophilie, compétition : + 1 ; mobilité légère, machine : − 1) ± 1 selon la position dans la chaîne `variante_de` (régression ou progression à niveau égal avec l'exercice de référence), bornée par niveau (1-3, 3-6, 6-8, 8-10) | choix raisonné ; **invariant testé** : la difficulté ne décroît jamais quand le niveau monte |
| `lieux` | `places` | intersection, sur le matériel de l'exercice, des lieux où ce matériel est habituellement disponible ou transportable (table `LIEUX_PAR_MATERIEL` ; disques et ceinture de lest sont transportables) | choix raisonné ; le filtre exact reste le matériel du profil (`feasibleWith`, où sol, mur, tapis et magnésie ne bloquent jamais ; depuis 0.4.2, `feasibleAt` ajoute le lieu : mur sûr à la maison et en salle seulement, matériel de remplacement `equipmentAlternatives`, meuble stable à la maison `homeFurnitureExercises`) |
| `contraintes` (7 articulations) | `jointStress` | table schéma → niveau par articulation, retouches par mots-clés (derrière la nuque, anneaux, un bras, planche, sauts, charnière à la barre…) | choix raisonné d'entraîneur, orienté par Escamilla 2001 (genou au squat), Cholewicki et al. 1991 (lombaires au soulevé de terre), Kolber et al. 2010 (épaule en musculation). **Ce n'est pas un avis médical.** |
| `prerequis` | `prerequisites` | hors lest : jusqu'à 2 exercices de la même famille `variante_de`, de difficulté strictement inférieure, les ancêtres d'abord (du parent vers la racine) puis les plus proches en difficulté ; lest : l'exercice au poids du corps non assisté le plus proche de la même famille de mouvement (muscles, schéma, matériel, nom, latéralité) | choix raisonné ; « paliers conseillés », pas une interdiction |
| `fatigue.systemique`, `fatigue.locale` (1-5) | `systemicFatigue`, `localFatigue` | systémique : table par schéma, + 1 polyarticulaire à la barre ou lesté, 5 pour squats et soulevés de terre lourds et haltérophilie complète, + 1 supramaximal et enchaînements lourds (man maker, devil press), − 1 débutant au poids du corps, machine ou poulie, assisté ; locale : 3, + 1 excentrique ou supramaximal (dommages musculaires plus marqués en excentrique : Proske & Morgan 2001), + 1 isolation d'un seul muscle, + 1 niveau Élite, − 1 conditionnement, portés, préparation scapulaire, équilibre, cou, gainage tenu, assisté (détail exact : `rules.fatigue`) | choix raisonné (échelle ordinale, pas une mesure) |
| `type_charge` | `loadType` | matériel et discipline, par ordre de priorité (lest, machine, poulie, barre, haltères, kettlebell, autre, élastique, poids du corps) | règle |
| `assiste` | `assisted` | nom contenant « assist… » | règle |
| `fraction_pdc` | `bodyweightFraction` | voir ci-dessous | publié, dérivé ou estimé (dit pour chaque valeur) |
| `unite` | `unit` | tenues et étirements : secondes ; sprints, portés, marches en appui : distance ; « aux calories » : calories ; sinon répétitions | règle |
| `lateralite` | `laterality` | mots-clés du nom | règle (cas ambigus listés) |
| `vecteur` | `muscleIndices`, `muscleWeights` | principal 1, secondaire 0,5, stabilisateur 0,2 | 1 et 0,5 : comptage « fractionnaire » des séries (une série indirecte = une demi-série), le mieux ajusté dans la méta-régression de Pelland et al. 2024 ; 0,2 : choix raisonné |
| `racine`, `profondeur` | `rootId`, `depth` | graphe `variante_de` (sans cycle, vérifié au chargement) | calcul |

### Fraction du poids du corps

Part de la masse du corps déplacée ou soutenue par les membres moteurs, pour un exercice au poids du
corps ou lesté ; charge totale = charge externe + fraction × poids de corps. Absente quand la notion n'a
pas de sens (charge externe seule, tenue de levier au poids du corps, gainage, cardio, mobilité) ; les
isométries **lestées** de traction et de dips gardent la fraction du mouvement (0,97 ; 0,96).

| Valeur | Exercices | Origine |
| ---: | --- | --- |
| 0,72 | pompe classique et variantes de prise | **publiée** : moyenne des positions haute (69,16 %) et basse (75,04 %), Suprak et al. 2011 |
| 0,58 | pompe sur les genoux | **publiée** : 53,56 % et 61,80 %, Suprak et al. 2011 |
| 0,81 | pompe pieds surélevés | **dérivée** : rapport (70 % et 74 %) / 64 % d'Ebben et al. 2011, appliqué à 0,72 |
| 0,54 | pompe mains surélevées | **dérivée** : rapport (55 % et 41 %) / 64 % d'Ebben et al. 2011 |
| 0,96 | dips, pompes en appui renversé | **dérivée** : 1 − mains − avant-bras (0,6 % et 1,6 % par côté, Winter 2009, tab. 4.1) |
| 0,97 | tractions, muscle-ups, montées de corde | **dérivée** : 1 − mains − moitié des avant-bras |
| 0,88 ; 0,94 | squats et fentes ; sur une jambe | **dérivée** : 1 − jambes − pieds (4,65 % et 1,45 % par côté) |
| 0,36 ; 0,50 ; 0,60 ; 0,70 ; 0,80 | pompe murale ; dips au banc, row genoux fléchis ; row australien ; pompe pike, row pieds surélevés ; pompe pseudo-planche | **estimée** (statique simple) — à mesurer |

Un exercice assisté porte la fraction du mouvement non assisté (l'assistance n'est pas connue). La
fraction est la part de masse déplacée, pas la charge par membre : une pompe à un bras garde 0,72
(tout porté par un bras ; la latéralité est dans `lateralite`).

### Proximité de base

`Catalog.similarity(a, b)` = 0,55 × cosinus des vecteurs musculaires + 0,20 × schéma (1 même schéma,
0,5 même famille) + 0,15 × même famille `variante_de` + 0,10 × (1 − |écart de difficulté| / 9).
Symétrique, dans [0 ; 1], 1 pour un exercice et lui-même (testé sur 10 000 paires). Les poids sont un
**choix raisonné** : le muscle domine, le schéma départage, la chaîne rapproche les variantes ;
`kalis_plan` peut raffiner.

### API `Catalog`

`Catalog.fromJsonBytes(octets JSON décompressés)`, `fromJson` ; `exercises`, `find`, `exercise`,
`contains` ; index `byLabel` (nom ou alias, sans casse ni accents), `byDiscipline`, `byCategory`,
`byPattern`, `byFamily`, `byEquipment`, `byMuscle(muscle, minWeight)` ; graphe `parentOf`,
`childrenOf`, `rootOf`, `familyOf`, `ancestorsOf` ; `similarity`, `mostSimilar` ; contrôles
`checkExerciseIds`, `checkEquipment`, `checkProfile`. Chargement mesuré ≤ 150 ms (VM, décompression
comprise ; `test/catalog_test.dart`, rapport du simulateur).

## 3. Profil d'athlète (`AthleteProfile`, schémas 2 et 3)

Ce paragraphe décrit le schéma 2 ; le schéma 3 (0.4.0) lui ajoute des champs tous optionnels : § 11.
Décisions D3. Champs dans `docs/TYPES.md`. Invariants : somme des dosages = 100, disciplines
distinctes, principale ≥ secondaires (l'égalité est admise : 50/50) ; **0 à 2 secondaires** (le prompt
du lot admet 0 ; D3.2 en demande 1 à 2 : c'est l'écran de création, G6, qui l'impose) ; mode street = une principale parmi streetlifting / sets & reps /
calisthénie, parts de somme 100, et `disciplines` en est l'image (`StreetMode.toDisciplineMix()` ;
« sets & reps » = discipline `street_workout`) ; niveau déclaré = fourchette ou « je ne sais pas »
(`known: false`, sans valeur) ; objectif de performance (exercice, grandeur, valeur, échéance) ou
d'habitude (séances par semaine × semaines), saisi ou suggéré ; disponibilités = jours précis +
minutes ; matériel dans le vocabulaire de la base ; un incrément par type de charge ; gêne de 0 à 10 ;
aimés ∩ détestés = ∅. Le questionnaire santé L13 n'est que **référencé** (`HealthScreeningRef` :
identifiant, jour, résultat) : aucune réponse de santé n'est copiée dans le profil.
`TrainingDiscipline.catalogDisciplines` relie les 8 disciplines du profil (D3.1) aux 8 de la base.
Champs optionnels : lieu d'un jour (`DaySlot.place`), matériel par lieu (`equipmentByPlace`), exercices
que l'utilisateur a dit savoir ou ne pas savoir faire (`knownExerciseIds`, `cannotDoExerciseIds`, à
reporter depuis `ProfileDelta` après la revue), niveau global d'expérience (`experience`).
**Convention de charge** : dans le profil et les objectifs, `one_rm_kg` est la charge **externe** (lest
seul pour un exercice lesté, comme l'utilisateur la lit) ; dans les estimations et les records des
moteurs, c'est la charge **totale** (externe + fraction × poids de corps).

## 4. Échelle des flammes (`Flames`, D5.3)

| Flammes | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RIR | 0 (échec ou répétition manquée) | 1 | 1,5 | 2 | 2,5 | 3 | 3,5 | 4 | 4,5 | 5 et plus |

`Flames.toRir` est la table exacte ; `Flames.fromRir` en est l'inverse exact sur ces valeurs. Hors
échelle (ancien journal, RIR par pas de 0,5), le RIR est ramené au demi-point le plus proche, égalité
vers la série la plus dure ; **RIR 0,5 → 9 flammes** (choix du lot : une série qui garde une
demi-répétition n'est pas un échec, et 10 flammes déclenche les règles d'échec). « Pas de note » =
champ `flames` absent, **distinct de toute valeur** (`SetRecord.isRated`). L'échelle en RIR par
demi-points suit l'usage de l'échelle RPE fondée sur les répétitions en réserve (Zourdos et al. 2016 ;
Helms et al. 2016) ; la table elle-même est une décision du propriétaire.

## 5. Journal (`TrainingLog`, schéma 1)

Séance (`SessionRecord`) : identifiant unique, **jour civil**, origine, place dans le programme,
marqueur **`resume`** (« reprise », D4.9 : la séance reste au journal mais `countedSessions` l'exclut —
ni XP, ni statistiques, ni série, ni records, ni données pour les moteurs), bilan santé, séries,
douleurs, lieu, pauses déclarées (`TrainingLog.breaks`). Série (`SetRecord`) : exercice, rang, rôle,
charge externe en kg **telle que l'utilisateur la lit** (barre et disques compris ; par haltère ou par
kettlebell ; valeur affichée d'une machine ou d'une poulie ; lest seul — le poids du corps n'y est
jamais ajouté ; négative = assistance), répétitions / secondes / mètres / calories (au moins une
mesure ; par côté pour un exercice unilatéral, une série par côté comptant une fois avec
`side: both`), flammes ou absence, `success` (cible atteinte), `excluded` (incident : gardée, ignorée
des moteurs), emplacement d'origine (`slotId`), cible prescrite. Bilan
santé (`HealthCheck`, D5.8) : **chaque question est facultative ; une réponse absente n'est jamais
remplacée par une valeur** (testé : clés absentes du JSON, `null` à la lecture) ; échelles de 1 à 5 où
5 est toujours l'état le plus favorable ; `pains` absent = question non posée, liste vide = aucune
douleur. Invariants : identifiants uniques, dates croissantes.
Format actuel du journal de l'application et règle de conversion : `docs/CONVERSION_JOURNAL.md`.

## 6. Interfaces des moteurs (`lib/src/engines.dart`)

| Interface | Méthodes | Lot |
| --- | --- | --- |
| `PlanEngine` | `createPass1(catalog, PlanRequest)` → `Pass1Plan` ; `review(catalog, ReviewRequest)` → `ReviewResult` (programme, `PlanDiff`, verrous, `ProfileDelta`) ; `variants(catalog, VariantsRequest)` → `VariantSet` (≤ 3 ciblées + toutes) ; `createPass2(catalog, Pass2Request)` → `Pass2Plan` ; `nextBlock(NextBlockRequest)` et `restructure(RestructureRequest)` → `BlockProposal` | G4 |
| `AdaptEngine` | `prescribeSession(catalog, SessionRequest)` → `SessionPlan` ; `adviseNextSet(catalog, AdviceRequest)` → `IntraSessionAdvice` ; `review(catalog, AdaptInput)` → `AdaptReview` (`AdaptationSummary`, `Proposal`, records, état opaque, `EngineLogEntry`) | G8 |
| `QuestEngine` | `evaluate(catalog, QuestInput)` → `QuestOutcome` (`QuestState`, `LevelState`, attributs, rangs, objectifs, événements) | G11 |
| `SeasonPlanner` (0.4.0) | `planSeason(catalog, SeasonRequest)` → `SeasonPlan` | CP1 |
| `EventDayAdvisor` (0.4.0) | `planEventDay(catalog, EventDayRequest)` → `EventDayPlan` | CA1 |

Chaque méthode prend le catalogue et **une requête versionnée** : un besoin nouveau s'ajoute comme champ
optionnel de la requête, sans casser les implémentations ; ce qui ne tient pas dans une requête passe
par une nouvelle interface, jamais par la modification de celles-ci.

**Bloc de programme.** La passe 1 est la semaine type (jours, emplacements, rôles) ; **la passe 2 fait
foi semaine par semaine** : pour un emplacement, une semaine peut prescrire un autre exercice que la
semaine type (échange en cours de bloc, semaine de test) ou un emplacement qui n'existe que cette
semaine-là. Une restructuration ne réécrit jamais les semaines déjà faites. Une prescription peut être
uniforme (`sets` × plage) ou détaillée série par série (`setTargets`), regroupée (`groupId`, `format`),
exprimée en part du 1RM (`percentOfOneRm`). Un changement de prescription proposé porte l'avant et
l'après (`PlanChange.fromPrescription`, `toPrescription`) : l'appliquer, c'est remplacer la
prescription visée. Les suites données aux propositions reviennent au moteur par
`AdaptInput.decisions`.

**Programme importé** (celui du propriétaire, D5.10 : 40 semaines, conservé jour pour jour). L'application
(G9) le présente au moteur dynamique comme un `ProgramBlock` de 40 semaines (`blockId`
`legacy-programme-v33`) : passe 1 = semaine type minimale, passe 2 = les prescriptions de chaque
semaine telles qu'elles sont (exercices propres à chaque semaine, `percentOfOneRm` quand la charge est
un pourcentage). `kalis_plan`, lui, ne produit que des blocs de 4 à 6 semaines (D4.8) et ne régénère
jamais ce programme.

Obligations de toute implémentation : fonctions pures et déterministes (mêmes entrées → même JSON à
l'octet près) ; toute sortie passe `validate()` ; toute raison est au registre ; ce qui est verrouillé
(`PlanLock`, `PlanSlot.locked`) ne bouge pas ; les séances « reprise » et les séries `excluded` sont
ignorées ; une réponse de bilan absente n'est pas inventée ; les registres de `QuestState` sont en
ajout seul. Les états `AdaptInput.state` et `QuestState.data` sont des objets JSON **opaques**, propriété
du moteur qui les écrit et versionnés par lui : l'application les stocke sans les lire.
Budgets (VM) : programme complet ≤ 1 s, régénération après revue ≤ 300 ms, décision de séance ≤ 50 ms,
leveling depuis tout le journal ≤ 200 ms — mesurés par chaque moteur ; le catalogue se charge en ≤ 150 ms.

## 7. Codes de raison

Registre `reasonRegistry` (133 codes : `plan.*`, `adapt.*`, `quest.*` ; depuis 0.4.1, trois codes de notes de coach en fin de registre — `plan.coach_note`, `plan.progression_rule`, `plan.pain_rule`, lot CP1 ; les 38 codes de 0.4.0 — 21 `plan.*`, dont
`plan.skill_plateau` et `plan.recent_load`, et 17 `adapt.*` — suivent les 92 premiers, dont le rang ne change pas), constantes `ReasonCodes`, table dans `docs/TYPES.md`. Textes
courts de Koach proposés pour les 38 codes de 0.4.0 : `docs/RAISONS_0_4.md` (`data/reason_texts_fr_0_4.json`). Un `Reason` valide a un code du registre et exactement les paramètres déclarés,
du bon type (entier, nombre, texte court, booléen, identifiant d'exercice). Un moteur qui a besoin d'un
nouveau code l'ajoute ici (évolution additive).

## 8. Jeux de données communs

`test/fixtures/` (voir son README) : 40 profils types au schéma 2, 5 profils types au schéma 3
(`profiles_v3.json`, avec les questions du parcours vues par chacun, les questions reportées et les tests guidés
permis), les règles des 7 types à variantes (`variants.json`), 12 journaux synthétiques de 4 à 24 semaines avec
la vérité du modèle simulé, le programme du propriétaire normalisé en lecture seule, un journal au
format actuel de l'application et sa conversion. `package:kalis_core/testing.dart` : lecteurs de ces
fichiers et valeurs aléatoires seedées de chaque type (`contractCodecs`, `arbitrary…`).

## 9. Limites connues

- Champs calculés par règles sur les noms : des cas particuliers sont mal classés ; les cas ambigus
  repérés sont listés dans `docs/RELECTURE_CATALOGUE.md` (une correction = une règle, jamais une valeur).
- Fractions du poids du corps « estimées » : ordre de grandeur statique, non mesuré ; les variantes
  pieds surélevés des dips au banc et de la pompe pike gardent la valeur de la variante de base.
- Les prérequis d'un exercice non lesté restent dans sa famille `variante_de` : le squat de
  compétition, par exemple, ne renvoie pas vers le back squat de musculation.
- `QuestOutcome.extras` (récapitulatif hebdomadaire, comparaisons, fantôme) est un objet libre que
  `kalis_quest` documente (`packages/kalis_quest/docs/EXTRAS.md`) ; il pourra être typé plus tard par des
  champs optionnels.
- Contraintes articulaires et coûts de fatigue : échelles ordinales de bon sens, sans valeur médicale.
- `lieux` suppose une salle complète, un parc de street workout et un domicile sans gros matériel.
- La proximité ne tient compte ni du matériel ni des contraintes articulaires (à `kalis_plan` de le faire).
- La conversion de l'ancien journal dépend d'une correspondance noms → identifiants fournie par G3 ;
  celle des jeux de données est indicative.

- (0.4.0) Les types de 0.4.0 décrivent **ce qui peut être prescrit, journalisé et planifié** ; ils ne
  contiennent aucune règle de programmation. Aucun moteur livré ne les produit encore : `kalis_plan` 0.1.0
  et `kalis_adapt` 0.1.0 les ignorent ; CP1 et CA1 les mettront à l'épreuve, et pourront demander des
  ajouts (additifs).
- (0.4.0) `Catalog.progressionCandidates` liste les variantes d'une figure dans l'ordre de la base : ce
  n'est pas une échelle ordonnée. La difficulté calculée du catalogue (1 à 10) est trop grossière pour
  ordonner les étapes d'une figure (front lever une jambe, straddle et complet ont la même) : l'échelle
  et ses critères (`SkillLadder`) sont à construire par `kalis_plan`.
- (0.4.0) Formats de compétition : relevés sur les pages publiques des organisateurs le 02/10/2026,
  règlements complets non lus (indice relatif de Final Rep, catégories de l'ISF 5.2, lests du Multirep).
  Aucune compétition de « sets & reps » n'a de règlement unifié : l'épreuve est une donnée libre.
- (0.4.0) Le vocabulaire de `VolumeTolerance.muscle` et de `Specialization.muscle` n'est pas le même :
  le premier est celui des groupes de `kalis_plan`, le second celui des muscles de la base.
- (0.4.0) L'étape actuelle d'une figure (`SkillState.currentExerciseId`) n'est pas contrôlée par le
  catalogue : une échelle peut passer par un exercice d'une autre famille. `Catalog.checkProfile` ne
  contrôle, pour le schéma 3, que le groupe musculaire d'une spécialisation (`unknown_muscle`).
- (0.4.0) Plusieurs tests ou records (`Benchmark`) peuvent porter sur le même exercice : aucune unicité
  n'est imposée ; c'est au lecteur de choisir (date, origine, `competitionStandard`).
- (0.4.0) Quand toutes les `parts` d'une série ont des répétitions, leur somme vaut `reps`
  (`parts_mismatch`) ; les durées ne sont pas recoupées. Chaque `GroupSpec` a au moins un membre parmi les
  prescriptions de la séance (`unknown_group`) ; `GroupResult.groupId` (journal) n'est pas recoupé avec
  le programme.
- (0.4.0) Aucune intensité ne s'exprime à la fréquence cardiaque : ni fréquence maximale au profil, ni
  fréquence au journal (laissé au lot CP2). Deux séances par jour, terrain de course, heure de passage en
  compétition et vitesse de barre ne sont pas décrits non plus (`docs/RELECTURES_CQ.md`).
- (0.4.0) Les énumérations de 0.4.0 sont ouvertes (§ 1) : une valeur ajoutée plus tard n'est lue que par
  une version du paquet qui la connaît (`fromJson` lève `FormatException` sur un code inconnu).

## 10. Registre de validation

| Élément | Preuve | État |
| --- | --- | --- |
| Base v1.1.0 : somme de contrôle, vocabulaires fermés, id uniques, un muscle par colonne, `variante_de` sans cycle | `tools/catalog/tests`, `test/catalog_test.dart` | testé |
| Champs calculés : domaines, invariants, 43 cas types, reproductibilité, fichiers à jour | `tools/catalog/tests/test_catalog.py` | testé |
| Distribution des champs calculés, 60 exemples, cas ambigus | `docs/RELECTURE_CATALOGUE.md` | lu par le lot ; **relecture du propriétaire attendue** |
| Conversion flammes ↔ RIR | `test/flames_test.dart` (table, inverse, 10 000 tirages) | testé |
| Aller-retour JSON de chaque type | `test/contracts_roundtrip_test.dart` (10 000 valeurs seedées par type) | testé |
| Invariants croisés | `test/validation_test.dart` | testé |
| Relecture indépendante des contrats, des règles et du catalogue (35 constats, 2 bloquants) | corrections intégrées avant l'étiquette ; constats non retenus dans les limites ci-dessus | fait le 01/10/2026 |
| Jeux de données valides | `test/fixtures_test.dart`, simulateur | testé |
| Chargement du catalogue ≤ 150 ms | `test/catalog_test.dart`, rapport du simulateur | mesuré en CI |
| Valeurs publiées (Suprak 2011, Ebben 2011, Winter 2009) | reprises des résumés et tables publiés | **non revérifiées sur le texte intégral dans ce lot** |
| Contenu sportif (schémas, contraintes, fatigue, prérequis) | — | **non relu par un professionnel diplômé** |
| (0.4.0) Évolution additive depuis 0.3.0 : types, champs, bornes, enums, rang des codes de raison | `tools/catalog/tests/test_contracts.py` (surface 0.3.0) | testé |
| (0.4.0) Rétrocompatibilité : `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0, `kalis_quest` 0.1.0 compilés et testés sans modification avec `kalis_core` 0.4.0 | contrôle `claude/ci-cp-b` (tous les paquets) | contrôlé en CI le 03/10/2026 (tests des trois moteurs verts, sources inchangées) |
| (0.4.0) JSON du schéma 2 relu et réécrit à l'identique ; migration vers le schéma 3 sans perte ni invention | `test/profile_v3_test.dart` (40 profils types, 10 000 profils et 10 000 séances aléatoires) | testé |
| (0.4.0) Types à variantes (7) : chaque variante porte exactement ses paramètres | `test/advanced_test.dart` (jeu généré `test/fixtures/variants.json`), `tools/catalog/tests/test_contracts.py` | testé |
| (0.4.0) Prescriptions avancées : nombre de séries par technique, plages, cohérence des intensités (§ 12) | invariants de `lib/src/custom_validation.dart` ; `test/advanced_test.dart` | testé |
| (0.4.0) Parcours de questions : nombre de questions vues par profil type (5 profils), questions reportées, chaque condition, 10 000 profils aléatoires | `test/questionnaire_test.dart`, `tools/catalog/tests` | testé |
| (0.4.0) Conversions des tests guidés (Brzycki, Riegel) | `test/estimation_test.dart` (valeurs de référence, 10 000 tirages) | testé |
| (0.4.0) Revue des facteurs du profil : références | `docs/PROFIL_V3.md` § 7 (statut de chaque référence) | notices et résumés vérifiés le 02/10/2026, recontrôlés par trois vérificateurs indépendants le 03/10/2026 (9 corrections) ; **textes intégraux non relus, sauf exception dite** |
| (0.4.0) Trois relectures indépendantes : contrat et code, parcours vu par un « débutant pressé », parcours et contrat vus par un « coach d'élite » | chaque constat changé ou expliqué : `docs/RELECTURES_CQ.md` | fait le 02/10/2026 ; seconde passe intégrée ; audit indépendant des suites données le 03/10/2026 |
| (0.4.0) Contenu sportif (questions, protocoles de test, techniques, périodisation) | — | **non relu par un professionnel diplômé** |

## 11. Profil d'athlète v3 (schéma 3, 0.4.0)

**But** (DECISIONS_CP.md C1.6) : ne poser que les questions qui changent réellement la manière dont le
corps supporte l'entraînement ou la programmation, à ceux pour qui elles comptent. Revue des facteurs,
verdicts (posée, déduite, écartée) et références : [`docs/PROFIL_V3.md`](docs/PROFIL_V3.md). Parcours de
questions, écrit pour le lot CU : [`docs/PARCOURS_V3.md`](docs/PARCOURS_V3.md).

- **Schéma.** `AthleteProfile.currentSchemaVersion` vaut 3 ; `schemaVersion` 2 reste lu et valide. Le
  schéma 3 n'ajoute que des champs optionnels : `trainingAge`, `trainingGap`, `sleep`, `stress`,
  `occupationalLoad`, `otherSports`, `bodyWeightGoal`, `benchmarks`, `events`, `skills`, `weakPoints`,
  `specialization`, `recentTraining`, `currentPhase`, `emphasis`, `enduranceBase`, `targetBodyWeightKg`,
  `lifestyleUpdatedOn`, et, dans `Limitation`, `since`, `aggravatedBy` et `effortDiscomfort`. Un profil qui
  en porte un doit être au schéma 3 (`schema3_field` sinon).
- **Migration** : `profile.toSchema3()` et `migrateAthleteProfileJsonToSchema3(json)` ne changent que
  `schemaVersion`. Rien n'est perdu, rien n'est inventé : chaque réponse du schéma 3 reste absente tant
  que l'utilisateur ne l'a pas donnée (D5.8). Un JSON du schéma 2 se relit et se réécrit à l'identique.
  Une application restée en `kalis_core` 0.3.0 refuse un profil au schéma 3 : ne migrer qu'après la mise
  à jour (INTEGRATION.md § 6).
- **Absent ≠ vide** : `otherSports`, `benchmarks`, `events` absents = question non posée ou passée ;
  liste vide = « aucun ».
- **Ancienneté et interruption** : `trainingAge` (4 tranches) ; `trainingGap`, interruption en cours au
  moment de répondre, en 7 tranches — `none`, `reduced` (entraînement allégé), `under_3_weeks`,
  `weeks_3_to_10`, `weeks_10_to_26`, `months_6_to_24`, `over_2_years`. Ensuite, les coupures se lisent
  dans le journal.
- **Charge actuelle** : `recentTraining` (`RecentTraining`, 12 au plus, mouvements distincts : séances par
  semaine et séries dures par semaine, `HardSetsBand`) ; `currentPhase` (du volume, du lourd, sortie de
  pic, sans structure) ; `emphasis` (muscle, force, les deux) ; `enduranceBase` (`EnduranceBase` : volume
  de course par semaine, sorties, plus longue sortie). Ils servent à caler le premier bloc sur ce que la
  personne fait vraiment (`plan.recent_load`).
- **Valeur habituelle, pas valeur du jour** : `sleep`, `stress`, `occupationalLoad` décrivent l'habitude ;
  la nuit dernière, le stress et les douleurs du jour restent dans `HealthCheck` (D5.8-D5.9). Aucun
  doublon ; `lifestyleUpdatedOn` permet de redemander ces réponses de temps en temps.
- **Autres sports** (`OtherSport`) : `mainSport` dit que ce sport est le sport principal de l'utilisateur
  (le programme passe après lui) ; `weekdays` de 1 à 7, distincts ; `regions` distinctes.
- **Poids de corps** : `bodyWeightGoal` ; `targetBodyWeightKg` seulement quand il vaut `lose` ou `gain`
  (`unexpected_field` sinon).
- **Santé (règle L13)** : aucune réponse du questionnaire santé n'est copiée. `Limitation` décrit une
  **contrainte d'entraînement** (zone, côté, gêne perçue, depuis quand, mouvements qui la réveillent),
  jamais un diagnostic. `discomfort` reste la gêne du moment ; `effortDiscomfort` (0 à 10) est la gêne au
  plus fort pendant l'effort. `aggravatedBy` : 14 familles de mouvements, sans doublon.
- **Tests et records** (`Benchmark`, type à variantes) : valeur exacte, datée, avec son origine (déclarée,
  test guidé, compétition, série d'entraînement) ; charge **externe**, comme partout dans le profil. Six
  natures : `load_reps`, `max_reps`, `max_hold`, `time_trial`, `distance_trial`, `reps_for_time` (volume
  imposé au meilleur temps : répétitions et temps). `competitionStandard` dit si le record a été fait au
  standard de compétition ; les tentatives du jour J ne se fondent que sur des records au standard.
  **Aucune unicité** : plusieurs records peuvent porter sur le même exercice. Les fourchettes du schéma 2
  (`movementLevels`, D3.5) restent la réponse du débutant.
- **Invariants du profil** (`validate()`) : identifiants d'`events` distincts ; figures visées de `skills`
  distinctes ; mouvements de `recentTraining` distincts ; couples mouvement / nature de `weakPoints`
  distincts ; les `goalIds` d'une échéance sont des objectifs du profil (`unknown_goal`) ;
  `lifestyleUpdatedOn` jamais avant `createdOn`.
- **Parcours de questions** : `data/parcours_v3.json` (31 questions : 17 du schéma 2, 14 du schéma 3 ;
  10 tests guidés), lu par `ProfileQuestionnaire` (`visibleQuestions`, `deferredQuestions`, `isDeferred`,
  `isRequired`, `eligibleTests`). Les conditions s'évaluent sur le JSON du profil ; une réponse absente
  rend la condition fausse (parcours le plus court). Une question **reportée** (`deferWhen`) n'est pas
  posée à la création mais proposée après la première semaine ; une question peut être **obligatoire sous
  condition** (`requiredWhen` : le poids de corps pour les disciplines au poids du corps). Conversions des
  tests guidés : `estimateOneRm` (Brzycki, sur la charge totale), `totalFromExternal`,
  `externalFromTotal`, `riegelSeconds`, `trialSpeed` (`lib/src/estimation.dart`). L'incertitude de 4 % ne
  vaut que pour un maximum mesuré (1 répétition, réserve nulle), même chez un novice ; `riegelSeconds`
  rend `null` hors de son domaine (contrôlé avant le calcul).
- **Catalogue** : `Catalog.checkProfile` contrôle en plus le groupe musculaire d'une spécialisation
  (`unknown_muscle`). **L'étape actuelle d'une figure n'est pas contrôlée** : une échelle (`SkillLadder`)
  peut passer par un exercice d'une autre famille. `isProgressionStep` et `progressionCandidates` restent
  disponibles pour proposer des étapes.

## 12. Prescriptions avancées (0.4.0)

Une prescription (`ExercisePrescription`) garde son sens de 0.3.0 ; sept champs optionnels la
complètent : `technique`, `tempo`, `intensity`, `autoregulation`, `test`, `unbroken`, `restMode` (et
`dayStress`, § 13 ; `skillTargetId`, § 14). Sans eux, elle s'écrit et se lit comme en 0.3.0. **Le contrat
ne dit pas quand servir une technique** : les prérequis (ancienneté, niveau, tests, récupération) sont
des règles de `kalis_plan`, tirées du référentiel ; une technique refusée se dit par
`plan.technique_withheld`.

**Règle de base : une ligne de journal par série.** `ExercisePrescription.sets` est toujours le
**nombre de lignes de journal attendues** (`SetRecord`), et la plage de répétitions (ou de secondes) est
celle **d'une ligne**. Les mini-séries d'un cluster, d'un rest-pause ou de myo-reps, les paliers d'une
série dégressive et les passages d'un bloc de densité ne sont pas des lignes : ce sont les `parts`
(`SetPart` : répétitions ou secondes, charge si elle change, repos pris avant) de la ligne de leur
série, dont `reps` (ou `seconds`) reste le total. Ainsi `kalis_quest` 0.1.0 et `kalis_adapt` 0.1.0, qui
comptent une série par ligne, gardent des comptes de séries justes.

**Technique de série** (`SetTechnique`, type à variantes : chaque technique porte exactement ses
paramètres ; 17 techniques). Dans la colonne des paramètres, ceux d'avant le point-virgule sont
obligatoires, ceux d'après sont permis. Les contrôles cités entre parenthèses sont ceux de `validate()`.

| Technique | `sets` = lignes de journal | Plage de répétitions (ou de secondes) d'une ligne | Paramètres | Journal (`SetRecord`) |
| --- | --- | --- | --- | --- |
| `standard` | séries | par série | — | une ligne par série (`role` `straight` ou absent) |
| `top_set_backoff` | série de tête **+** séries allégées : `backoffSets` < `sets` (`set_count`) | celle de la série de tête | `backoffSets`, `backoffDropPct` ; `backoffRepsLow`, `backoffRepsHigh` (plage des séries allégées, renseignées ensemble) | une ligne par série ; `role` : `top`, puis `back_off` |
| `cluster` | séries | total d'une série : `miniSets` × `miniSetReps` doit être dans la plage (`reps_mismatch`) | `miniSets`, `miniSetReps`, `intraRestSeconds` | une ligne par série, `reps` = total ; `parts` : une partie par mini-série |
| `rest_pause` | séries | total d'une série (non contrôlé) | `intraRestSeconds` ; `miniSets` (plafond), `totalRepsTarget` | une ligne par série, `reps` = total ; `parts` : une partie par mini-série |
| `myo_reps` | séries | total d'une série (non contrôlé) | `miniSetReps`, `intraRestSeconds` ; `miniSets` (plafond) | une ligne par série, `reps` = total ; `parts` : une partie par mini-série |
| `drop_set` | séries | total d'une série (non contrôlé) | `drops`, `dropPct` | une ligne par série, `reps` = total ; `parts` : une partie par palier, avec sa charge (`externalLoadKg`) |
| `isometric_hold` | séries | secondes par série | — ; `qualityFloor`, `totalSecondsTarget` (angle : choix de l'exercice du catalogue) | une ligne par série : `seconds`, `quality` |
| `accentuated_eccentric` | séries | par série | — ; `eccentricLoadPct`, `eccentricOnly` (le rythme est dans `tempo`) | une ligne par série |
| `contrast` | séries de l'exercice lourd | par série de l'exercice lourd | `pairedSlotId` (emplacement de l'exercice explosif) ; `pairedRestSeconds` | une ligne par série, dans chacun des deux emplacements |
| `wave` | paliers au total : `waves` × longueur de `waveReps` (`set_count`) | du plus petit au plus grand nombre de `waveReps` (`reps_mismatch`) | `waves`, `waveReps` ; `waveStepPct` | une ligne par palier, `role` `wave` |
| `amrap` | séries (ou 1 bloc ; non contrôlé) | par série | — ; `durationSeconds` (absent : une série au maximum) | une ligne par série : `reps`, `rounds`, `elapsedSeconds` |
| `emom` | intervalles : `intervals` (`set_count`) | par intervalle | `intervalSeconds`, `intervals` | une ligne par intervalle, `role` `interval` |
| `density` | 1 (`set_count`) | total du bloc | `durationSeconds` ; `totalRepsTarget` | une ligne : `reps` = total, `elapsedSeconds` ; `parts` : une partie par passage |
| `ladder` | marches au total : `ladderCount` (1 s'il est absent) × nombre de marches, soit (`ladderTop` − `ladderStart`) / `ladderStep` + 1 (`set_count`) | de `ladderStart` à `ladderTop` (`reps_mismatch`) | `ladderStart`, `ladderStep`, `ladderTop` ; `ladderCount` | une ligne par marche, `role` `rung` |
| `pyramid` | paliers : longueur de `pyramidReps` (`set_count`) | du plus petit au plus grand nombre de `pyramidReps` (`reps_mismatch`) | `pyramidReps` (2 paliers au moins) | une ligne par palier, `role` `rung` |
| `skill_practice` | essais prévus (non contrôlé) | secondes ou répétitions par essai | — ; `qualityFloor`, `maxAttempts`, `durationSeconds`, `totalSecondsTarget` | une ligne par essai : `quality` |
| `for_time` | 1 (`set_count`) | total du bloc | `totalRepsTarget` ; `durationSeconds` | une ligne : `reps` = total, `elapsedSeconds` = temps réalisé |

Règles de `SetTechnique` seul : un paramètre d'une autre technique est une violation ; `backoffRepsLow` ≤
`backoffRepsHigh`, renseignées ensemble (`range_incomplete`, `range_inverted`) ; `ladderStart` ≤
`ladderTop` (`range_inverted`) et écart multiple de `ladderStep` (`ladder_step`) ; répétitions de
`waveReps` et de `pyramidReps` de 1 à 100. `lastSetOnly: true` (permis à toute technique) : la technique
ne s'applique qu'à la **dernière** série, les autres sont normales ; `sets` compte alors toutes les
séries et les contrôles `set_count` et `reps_mismatch` du tableau ne s'appliquent pas. Les contrôles de
plage ne jouent que si la prescription porte une plage de répétitions. `sets` est borné à 20 : un EMOM de
plus de 20 intervalles, une vague ou une échelle de plus de 20 paliers ne s'écrivent pas comme une technique
de série mais comme un **groupe** (`GroupSpec`, formats `emom`, `circuit`…), qui n'a pas cette borne.

Autres rôles d'une ligne (`SetRole`) : `warmup` (montée d'échauffement), `test`, `attempt` (tentative de
compétition). `lastSetOnly` ne se met jamais sur `standard`.

**Groupes d'exercices enchaînés** (`GroupSpec`, type à variantes, dans `DayPrescription.groups` et
`SessionPlan.groups`, 20 au plus) : les membres du groupe portent le même `groupId` que lui. **Quand un
groupe est décrit par un `GroupSpec`, il prime sur le texte libre `ExercisePrescription.format`** (0.1.0),
qui reste valable seul pour un superset ou un circuit simple.

| Format | Paramètres obligatoires | Paramètres permis |
| --- | --- | --- |
| `superset` | — | `rounds`, `restBetweenRoundsSeconds` |
| `circuit` | `rounds` | `restBetweenRoundsSeconds` |
| `rounds_for_time` (tours au meilleur temps) | `rounds` | `timeCapSeconds`, `targetSeconds`, `restBetweenRoundsSeconds` |
| `amrap` (maximum de tours en un temps) | `durationSeconds` | — |
| `emom` (un passage par intervalle) | `intervalSeconds`, `durationSeconds` | — |
| `chipper` (suite imposée, une fois, au meilleur temps) | — | `timeCapSeconds`, `targetSeconds` |
| `intervals` (effort, récupération) | `rounds`, `intervalSeconds` | `restBetweenRoundsSeconds` |

`eventId` est libre pour tout format : le groupe répète l'épreuve de cette échéance. Le résultat d'un
groupe se journalise dans `SessionRecord.groupResults` (`GroupResult` : `groupId`, `completed`, temps
total `elapsedSeconds`, tours complets `rounds`, répétitions du tour entamé `extraReps`).

**Série indivisible et récupération** : `ExercisePrescription.unbroken` (aucun repos pendant la série) ;
`restMode` (`RestMode` : `passive`, `walk`, `jog`), nature de la récupération en course.

**Intensité** : `targetFlames` (RIR visé) et `percentOfOneRm` restent les **valeurs simples**.
`IntensityTarget` (type à variantes) ajoute les plages et les intensités relatives. `value` est
**obligatoire** (valeur visée, ou bas de la plage) ; `valueHigh`, facultatif, est le haut de la plage
(`value` ≤ `valueHigh`, `range_inverted` sinon).

| Base (`basis`) | Sens de `value` | Bornes de `value` et `valueHigh` | Paramètres |
| --- | --- | --- | --- |
| `percent_one_rm` | part du 1RM de charge totale | 0 à 1,5 | permis : `referenceExerciseId` |
| `percent_benchmark` | part d'un test de référence (répétitions max, maintien max…) | 0 à 1,5 | obligatoire : `referenceKind` ; permis : `referenceExerciseId` |
| `rir` | répétitions en réserve | 0 à 10 | — |
| `speed_fraction` | part d'une vitesse de référence | 0 à 1,5 | permis : `referenceKind`, `referenceExerciseId`, `eventId` (allure visée de cette course) |
| `bodyweight_fraction` | lest en part du poids de corps | 0 à 1,5 | — |
| `absolute_speed` | vitesse, en mètres par seconde | 0 à 15 | — |

Une part du maintien max s'écrit `percent_benchmark` avec `referenceKind: max_hold` ; une étape de figure
s'écrit par l'exercice de la prescription et `skillTargetId` (§ 14), pas par une intensité. `rirCap`
(permis à toute base) est un **plafond d'effort** : jamais moins de réserve que cette valeur, la charge
est abaissée sinon — c'est lui qui rend une charge en pourcentage autorégulée.

**Préséance et cohérence.** Deux écritures de la même chose doivent s'accorder ; `validate()` rend
`intensity_mismatch` sinon :

- `percentOfOneRm` et `intensity` de base `percent_one_rm` (sans `referenceExerciseId`) : `percentOfOneRm`
  est dans la plage de `intensity` ;
- `targetFlames` et `intensity` de base `rir` : le RIR des flammes est dans la plage (1 flamme, « 5 et
  plus », s'accorde avec toute plage dont le haut est au moins 5) ;
- `technique.backoffDropPct` et le `pct` d'une règle `backoff_from_top_set` : égaux quand les deux sont
  renseignés ; `pct` absent = celui de `technique.backoffDropPct`.

`setTargets`, s'il est renseigné, a exactement `sets` éléments (`set_count`). `test` n'est permis que sur
une prescription dont `kind` vaut `test` (`unexpected_field`).

**Autorégulation portée par la prescription** (`AutoregulationRule`, type à variantes, 3 règles au plus) :

| Règle (`kind`) | Effet | Paramètres obligatoires | Paramètres permis |
| --- | --- | --- | --- |
| `backoff_from_top_set` | séries allégées calculées sur la série de tête **réalisée** | — | `pct`, `rirCeiling`, `minSets`, `maxSets` |
| `load_from_rir` | charge corrigée quand le RIR sort de sa plage | `rirFloor`, `rirCeiling` | `pct` (pas de correction par répétition d'écart) |
| `stop_at_rir` | arrêt des séries quand le RIR passe sous un plancher | `rirFloor` | `minSets`, `maxSets` |
| `stop_on_rep_drop` | arrêt quand les répétitions chutent | `repDrop` | `minSets`, `maxSets` |
| `hold_from_best` | durée de maintien tirée du meilleur maintien du jour | `pct` | — |
| `last_set_amrap` | dernière série ouverte | — | `rirFloor` |
| `stop_on_quality_drop` | arrêt quand la propreté passe sous un plancher | `qualityFloor` (1 à 5) | `minSets`, `maxSets` |

`rirFloor` ≤ `rirCeiling` et `minSets` ≤ `maxSets` (`range_inverted`). Le moteur dynamique exécute ces
règles et rend ses conseils par `IntraSessionAdvice` (`miniSetsLeft`, `stepExerciseId`).

**Tests** : une prescription de rôle `test` (`kind`) porte `test` (`TestSpec` : série d'estimation
sous-maximale, xRM, maximum, répétitions max, maintien max, temps ou distance, simulation de
tentatives ; protocole de `PARCOURS_V3.md` § 5). Le résultat revient par `AdaptReview.testResults`
(`Benchmark`), que l'application reporte dans `AthleteProfile.benchmarks` ; les maxima estimés et leur
incertitude restent dans `AdaptationSummary.estimates` (`ExerciseEstimate.standardError`).

**Journal** : `SetRecord` gagne `technique`, `role`, `parts` (1 à 120 `SetPart`, chacune avec au moins
`reps` ou `seconds`), `restBeforeSeconds`, `elapsedSeconds`, `rounds`, `quality` (propreté de 1 à 5),
`attemptIndex` ; `SessionRecord`, `eventId` et `groupResults` ; `SetTarget`, `role`, `percentOfOneRm`,
`restSeconds`. Une durée de maintien est `seconds` (0.1.0).

## 13. Périodisation (0.4.0)

- **Plan de saison** (`SeasonPlan`) : suite de phases (`SeasonPhase` : nature, début, durée en semaines,
  échéance préparée, facteurs de volume et d'intensité visés). La nature est un `SeasonPhaseKind` —
  accumulation, intensification, réalisation, affûtage, compétition, transition, test, décharge,
  entretien (`maintenance`), reprise progressive après une coupure (`reintroduction`). L'énumération
  s'appelle `SeasonPhaseKind` et non `PhaseKind` : l'application a déjà un `PhaseKind`.
  Invariants : `index` = rang dans `phases` (`index_mismatch`) ; les phases sont **contiguës**, sans trou
  ni chevauchement — chacune commence quand la précédente finit, soit 7 jours × les `weeks` de la
  précédente après son début (`phases_not_contiguous`) ; `eventIds` sans doublon ; l'`eventId` d'une
  phase est dans `eventIds` (`unknown_event`).
  **Phase propre à un mouvement** : `SeasonPhase.overrides` (`PhaseOverride`, 20 au plus, mouvements
  distincts : mouvement, phase, facteurs de volume et d'intensité) — un mouvement peut rester en
  accumulation pendant que les autres s'intensifient.
  C'est le **squelette** : D4.8 est inchangé, les blocs restent de 4 à 6 semaines et sont générés au fil
  de l'eau. Le plan est produit par
  `SeasonPlanner.planSeason` d'après les échéances du profil, passé aux moteurs
  (`PlanRequest.season`, `NextBlockRequest.season`, `RestructureRequest.season`, `AdaptInput.season`),
  et révisable (`BlockProposal.season`, `Proposal.season` avec `detail: season_update`).
- **Intention du bloc** (`Pass1Plan.intent`, `BlockIntent`) : phase réalisée (`SeasonPhaseKind`), rang dans le plan de
  saison, échéance et semaines restantes, modèle d'ondulation, spécialisation servie. Près d'une échéance
  principale (phases `realization` et `taper`), la phase prime sur le dosage des disciplines secondaires
  (`DisciplineMix`, D3.2) : le moteur peut servir un bloc entièrement spécifique sans que le profil change
  (`docs/PROFIL_V3.md` § 6).
- **Intention de la semaine** (`WeekPrescription.intent`, `WeekIntent`) à côté de `kind`, qui reste
  renseigné : une semaine d'affûtage s'écrit `kind: deload` + `intent: taper` ; une semaine de
  compétition, `kind: test` + `intent: competition`. Le moteur dynamique lit l'intention pour ne pas la
  contredire (`SessionPlan.phase`, `weekIntent` ; codes `adapt.phase_respected`,
  `adapt.taper_no_volume`, `adapt.event_near`).
- **Ondulation dans la semaine** : `DayPrescription.stress` (séance lourde, moyenne, légère) et
  `ExercisePrescription.dayStress` (par mouvement : un mouvement peut être lourd un jour où un autre
  est léger).
- **Tolérance apprise** : `AdaptationSummary.volumeTolerance` (plage de séries hebdomadaires bien
  tolérées par groupe musculaire) pour que le bloc suivant monte le volume dans ce que la personne
  supporte.

## 14. Spécialisation et figures (0.4.0)

- **Spécialisation** (`Specialization`) : cible (mouvement, figure, groupe musculaire, schéma), durée,
  sort du reste (`MaintenancePolicy` : entretenu, dose minimale, en pause). Voulue par l'utilisateur
  (`AthleteProfile.specialization`) ou servie par un bloc (`BlockIntent.specialization`).
- **Figures** : l'utilisateur dit où il en est (`SkillState` : figure visée, étape actuelle, meilleur
  maintien ou meilleur nombre de répétitions, et depuis quand il en est à cette étape — `atStepSince`,
  `StepTenure`, qui initialise `SkillProgress.weeksAtStep`). L'étape actuelle est en général une variante
  de la figure (graphe `variante_de`), mais **le catalogue ne l'impose pas** (§ 11). Le moteur statique
  construit l'**échelle** (`SkillLadder` dans `Pass1Plan.skillLadders` : étapes ordonnées, chacune avec
  son critère de passage `StepCriterion` — maintien ou répétitions, nombre de séries, propreté minimale,
  séances de suite, durée minimale à l'étape). Les critères sont **paramétrables** : ce sont des usages
  d'entraîneur, pas des normes. Une prescription d'étape porte `skillTargetId`. Le moteur dynamique suit
  la progression (`AdaptationSummary.skills`, `SkillProgress` ; `AdaptReview.skillStates` à reporter
  dans le profil ; codes `adapt.skill_step_up`, `skill_step_down`, `skill_hold`, `adapt.tendon_load`). Une
  figure bloquée longtemps à la même étape change de méthode : `plan.skill_plateau`.
- **Points faibles** (`WeakPoint`) : mouvement + où ça bloque ; servent au choix des exercices
  d'assistance (`plan.weak_point`).

## 15. Compétition (0.4.0)

- **Échéance** (`SeasonEvent`, type à variantes, dans `AthleteProfile.events`) : nature, priorité
  (principale, secondaire, préparation), date, et son format **en données** — compétition de force :
  mouvements dans l'ordre (`lifts`, obligatoire, mouvements distincts : tentatives, plus petit saut de
  charge, meilleure barre, barre visée, `CompetitionLift`) ; compétition de répétitions : `mode`
  (maximum, maximum en temps limité, volume imposé contre la montre, maintien), **seul champ
  obligatoire** — les postes (`stations`), les tours et la limite de temps s'ajoutent quand le format
  est connu (`stations` renseigné ⇒ `mode` renseigné) ; course : distance (obligatoire), temps visé.
  Rien n'est figé par organisateur ; `ruleset` n'est qu'un code libre.
  Champs ajoutés par la seconde passe : `dateApproximate` (la date n'est pas fixée au jour près),
  `plannedBodyWeightKg` (poids de corps prévu le jour J), `formatKnown` (`false` : format connu le jour
  même), `heats` et `restBetweenHeatsSeconds` (passages dans la journée), `elements` (figures prévues en
  freestyle), `bestSeconds`, `bestTotalReps`, `bestDate` (meilleure performance déjà faite sur l'épreuve).
  Les champs permis à chaque nature sont dans `docs/TYPES.md` et `test/fixtures/variants.json`.
- **Poste** (`EventStation`) : exercice, répétitions imposées **ou** durée imposée (jamais les deux,
  `measure_count`), lest, série indivisible, limite de temps propre au poste (`timeLimitSeconds`), repos
  imposé après le poste (`restAfterSeconds`).
- **Jour J** (`EventDayAdvisor.planEventDay`) : `EventDayRequest` (échéance, pesée, tentatives déjà
  faites, bilan du jour, et pour une compétition de force l'objectif du jour — `objective`,
  `EventObjective` : assurer un total, viser le plus gros total, tenter un record — et le total visé
  `targetTotalKg`) → `EventDayPlan` : pour chaque mouvement, tentatives restantes (`LiftAttempts` :
  maximum du jour estimé et son écart-type, `AttemptSuggestion` avec probabilité de réussite, et la montée
  d'échauffement proposée avant l'ouverture, `warmup` : 12 `WarmupStep` au plus — charge, répétitions,
  repos) ; pour une épreuve de répétitions, objectif et rythme par poste (`PacingSegment` ; `stationIndex`
  dit le rang du poste quand un exercice revient plusieurs fois, `round` le tour concerné, absent = tous
  les tours). Une tentative déjà faite (`AttemptResult`) peut porter la cause de son échec (`failure`,
  `AttemptFailure` : force, technique, décision d'arbitre).
  Invariants : les charges proposées ne décroissent jamais (`attempt_decreasing`) ; les rangs des
  tentatives sont strictement croissants. La séance du jour J se journalise comme une séance
  (`SessionRecord.eventId`, séries de rôle `attempt`, `attemptIndex` ; montées de rôle `warmup`).
- Convention de charge : **externe** (le lest), comme dans le profil et le journal.

## 16. Rétrocompatibilité de 0.4.0

- Par rapport à 0.3.0 : aucun type, champ, code d'enum ni code de raison retiré, renommé ou déplacé ;
  aucune borne changée ; tout champ ajouté est optionnel et en fin de type : un JSON de 0.3.0 se relit et
  se réécrit à l'identique. Aucune valeur ajoutée à une énumération d'avant 0.4.0 ; les énumérations de
  0.4.0 sont ouvertes (§ 1). Contrôlé par le test Python d'additivité (§ 1).
- Seul changement visible sans rien demander : `AthleteProfile()` construit sans `schemaVersion` écrit
  désormais le schéma 3 (au lieu de 2). `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0 et `kalis_quest` 0.1.0
  ne lisent pas ce numéro (contrôle de leurs tests avec `kalis_core` 0.4.0 : `claude/ci-cp-b`).
  Une application restée en `kalis_core` 0.3.0, elle, **refuse un profil au schéma 3** : ne migrer un
  profil qu'une fois l'application passée à 0.4.0.
- `PlanEngine`, `AdaptEngine` et `QuestEngine` ne changent pas : les besoins nouveaux passent par des
  champs optionnels des requêtes existantes ou par deux interfaces nouvelles (`SeasonPlanner`,
  `EventDayAdvisor`).
- Les moteurs 0.1 ignorent les champs nouveaux : un programme qui porte une technique avancée doit être
  suivi par un moteur dynamique qui la connaît (`kalis_plan` 0.2 avec `kalis_adapt` 0.2, intégrés
  ensemble par le lot CI).
- Journal : une série reste **une ligne** (`SetRecord`), quel que soit son découpage (`parts`, § 12).
  `kalis_quest` 0.1.0 et `kalis_adapt` 0.1.0 comptent une série par ligne : leurs comptes de séries
  restent donc justes sur un journal qui porte des techniques avancées.

## Références

- Boyle M. (2016). *New Functional Training for Sports*, 2e éd. Human Kinetics.
- Cholewicki J., McGill S. M., Norman R. W. (1991). Lumbar spine loads during the lifting of extremely heavy weights. *Med Sci Sports Exerc* 23(10):1179-1186.
- Ebben W. P., Wurm B., VanderZanden T. L. et al. (2011). Kinetic analysis of several variations of push-ups. *J Strength Cond Res* 25(10):2891-2894.
- Escamilla R. F. (2001). Knee biomechanics of the dynamic squat exercise. *Med Sci Sports Exerc* 33(1):127-141.
- Haff G. G., Triplett N. T. (dir.) (2016). *Essentials of Strength Training and Conditioning*, 4e éd. NSCA, Human Kinetics.
- Helms E. R., Cronin J., Storey A., Zourdos M. C. (2016). Application of the repetitions in reserve-based rating of perceived exertion scale for resistance training. *Strength Cond J* 38(4):42-49.
- Kolber M. J., Beekhuizen K. S., Cheng M. S., Hellman M. A. (2010). Shoulder injuries attributed to resistance training: a brief review. *J Strength Cond Res* 24(6):1696-1704.
- Pelland J. C., Remmert J. F., Robinson Z. P., Hinson S. R., Zourdos M. C. (2024). The resistance training dose-response: meta-regressions exploring the effects of weekly volume and frequency on muscle hypertrophy and strength gain. Prépublication SportRxiv.
- Proske U., Morgan D. L. (2001). Muscle damage from eccentric exercise: mechanism, mechanical signs, adaptation and clinical applications. *J Physiol* 537(2):333-345.
- Suprak D. N., Dawes J., Stephenson M. D. (2011). The effect of position on the percentage of body mass supported during traditional and modified push-up variants. *J Strength Cond Res* 25(2):497-503.
- Winter D. A. (2009). *Biomechanics and Motor Control of Human Movement*, 4e éd. Wiley (tab. 4.1, données de Dempster 1955).
- Zourdos M. C., Klemp A., Dolan C. et al. (2016). Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve. *J Strength Cond Res* 30(1):267-275.
