# kalis_core — contrat

Version 0.2.0 (lot GC, 01/10/2026 ; évolution additive du lot G8 : `CHANGELOG.md`). Ce paquet fixe **tout ce que les moteurs et l'application
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
d'enum **en fin de liste**, nouveaux champs **optionnels**, nouveaux codes de raison. Rien n'est
retiré ni renommé ; le sens et l'unité d'un champ ne changent pas. Une rupture demande une décision
du propriétaire et une montée de `schemaVersion`. Une évolution se fait dans
`tool/contracts_spec.py`, puis `python3 tool/gen_contracts.py` (version x.(y+1).0).
Une valeur d'enum ajoutée n'est lisible que par une version du paquet qui la connaît : l'application
embarque toujours `kalis_core` et les moteurs à des versions livrées ensemble.

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
| `lieux` | `places` | intersection, sur le matériel de l'exercice, des lieux où ce matériel est habituellement disponible ou transportable (table `LIEUX_PAR_MATERIEL` ; disques et ceinture de lest sont transportables) | choix raisonné ; le filtre exact reste le matériel du profil (`feasibleWith`, où sol, mur, tapis et magnésie ne bloquent jamais) |
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

## 3. Profil d'athlète v2 (`AthleteProfile`, schéma 2)

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

Registre `reasonRegistry` (75 codes : `plan.*`, `adapt.*`, `quest.*`), constantes `ReasonCodes`, table
dans `docs/TYPES.md`. Un `Reason` valide a un code du registre et exactement les paramètres déclarés,
du bon type (entier, nombre, texte court, booléen, identifiant d'exercice). Un moteur qui a besoin d'un
nouveau code l'ajoute ici (évolution additive).

## 8. Jeux de données communs

`test/fixtures/` (voir son README) : 40 profils types, 12 journaux synthétiques de 4 à 24 semaines avec
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
  `kalis_quest` documentera ; il pourra être typé plus tard par des champs optionnels.
- Contraintes articulaires et coûts de fatigue : échelles ordinales de bon sens, sans valeur médicale.
- `lieux` suppose une salle complète, un parc de street workout et un domicile sans gros matériel.
- La proximité ne tient compte ni du matériel ni des contraintes articulaires (à `kalis_plan` de le faire).
- La conversion de l'ancien journal dépend d'une correspondance noms → identifiants fournie par G3 ;
  celle des jeux de données est indicative.

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
