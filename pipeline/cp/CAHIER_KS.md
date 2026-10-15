# Cahier des charges — Structure de la semaine (lot KS1)

11/10/2026 · propriétaire : Gaël · **questions tranchées le 11/10/2026 à 21:17 (§ 11) ; lancé le 15/10/2026 (DECISIONS_CP.md C17)**, en parallèle de KM2c1 (voie A) sur la branche de contrôle `claude/ci-cp-b`.
Origine : test du créateur de programme sur un profil de test sincère (`testdebug.json`, `kalis_plan` 0.3.1, 7 itérations), puis question du propriétaire : « Pourquoi il ne m'a pas créé des séances en PPL sur cycle de 3 jours force/volume et 3 jours endurance/volume ? Un créateur de programme devrait penser directement dans ce type de structure, non ? »

Ce cahier ajoute deux concepts de premier rang au créateur de programme (`kalis_plan`) — le **type de jour** et le **gabarit de semaine** — et les corrections sans lesquelles ils ne serviraient à rien (couverture des objectifs, échéances, charges, contrôle de structure). Il ne touche pas à la méthode Koach (`CAHIER_KM.md`) : il change la structure dont Koach part.

## 1. Constats (lus dans le code de `moteurs` 9ac79e40)

| # | Constat | Où | Effet sur le profil de test |
| --- | --- | --- | --- |
| K1 | **Un seul style par athlète**, tiré de la discipline principale : `styleOf` renvoie `lifting` pour un streetlifter lesté, quel que soit le reste du profil. | `coach/skeleton.dart`, `styleOf` | 50 % de sets & reps déclarés → 0 jour d'endurance. |
| K2 | `_buildLifting` **ne lit jamais les disciplines secondaires** (seuls `_buildReps` et `_buildRuns` les lisent). `streetMode.setsRepsPct` / `streetliftingPct` ne sont lus que par `report.dart` (affichage). | `coach/skeleton.dart`, `report.dart` | La part déclarée n'a aucun effet sur le programme. |
| K3 | **Pas de type de jour** : le focus vaut `strength.upper`, `strength.lower` ou `full_body` ; aucune qualité (force, endurance, puissance…) n'est portée par la journée. L'ondulation est **par mouvement** (lourd, moyen, léger de chaque mouvement de compétition), pas par journée. | `assemble.dart` `FocusCodes`, `buildSkeleton` (`UndulationModel.daily`) | Jours mixtes : jeudi à 14 exercices, vendredi sans exercice principal (rempli par `_fillTime`). |
| K4 | **Objectifs en répétitions sans porteur** dans le style `lifting` : seuls les objectifs de charge reçoivent un `plan.goal_support`. | `coach/skeleton.dart` | 5 objectifs sur 9 sans aucun emplacement (tractions, pompes, dips, MU strict, squat 70 kg). |
| K5 | **L'échéance prime toujours sur les objectifs datés**, même secondaire et plus lointaine : `targetOf` prend la première échéance à venir avant de regarder les dates des objectifs. | `coach/season.dart`, `targetOf` | Saison calée sur le 15/12/2027 (échéance « secondary ») ; aucun jalon au 30/04/2027, date des 9 objectifs ; 14 cycles 3+1 identiques. |
| K6 | **Le score ne choisit rien sur le chemin street** : le squelette est écrit par règles, puis `PlanInspector.scoreOf` calcule la note pour l'affichage et le diff de la revue. La récupération à 0,48 (séances lourdes du même groupe musculaire sur deux jours voisins) est donc vue mais jamais corrigée. | `coach/coach.dart` l. 371-381, `score.dart` | Ce n'est pas l'agrégation qui « laisse passer » le plan ; c'est qu'aucun contrôle de structure ne s'appuie sur la note. |
| K7 | **Koach 1.0 ne modifie jamais la structure** (KM1.3) et reste à ±15 % de volume par qualité de `kalis_plan` (`CAHIER_KM.md`, méthode 6). | `CAHIER_KM.md`, `LIVRAISON_KM1.md` | Sans correction à la source, Koach hériterait de zéro volume d'endurance. |
| K8 | Défauts de charge vus sur le même profil : plancher du poids du corps qui bloque le muscle-up lesté à +0 kg tout le bloc ; traction haute et dips barre fixe référencés sur le 1RM du muscle-up ; charges des variantes pause différentes des pourcentages annoncés (semaines 2 et 3) ; squat pause « à calibrer » malgré un 1RM connu ; raison du remplacé portée par le remplaçant (`plan.user_dislikes`). | `coach/prescribe.dart`, `_weakVariant` | Voir § 8. |

## 2. Faut-il penser d'abord en structure ? Oui — mais pas en PPL partout

Un coach décide de haut en bas : **besoins** (quelles qualités, sur quels schémas de mouvement) → **fréquence** de chaque schéma → **gabarit** de semaine → **type** de chaque jour → **exercices** → **charges**. Le créateur actuel saute les trois étapes du milieu : il place des mouvements avec une intensité, puis remplit le temps. C'est la cause commune de K1 à K4.

Le PPL × 2 (une rotation force, une rotation endurance) n'est pas optimal en soi : c'est **le meilleur gabarit pour un profil donné** quand quatre conditions sont réunies — six séances, deux qualités à poids comparable sur les **mêmes** schémas, chaque schéma vu deux fois par semaine, 72 h entre deux séances du même schéma. C'est exactement le profil de test (et la structure du programme de 40 semaines du propriétaire : J4 tirage volume/endurance, J5 poussée volume/endurance, J6 MU + squat endurance). Pour trois séances, un full body ou un haut/bas vaut mieux ; pour un débutant, un full body ; pour une spécialisation, un gabarit qui monte la fréquence du mouvement visé.

Appuis : fréquence de 2 par semaine au moins par groupe musculaire pour l'hypertrophie (Schoenfeld, Ogborn et Krieger 2016) ; pour la force, le gain de la fréquence passe surtout par le volume et la pratique du geste (Grgic et al. 2018) ; 48 h entre deux charges dures d'une même zone (référentiel R4-F10, R5-P22, déjà appliqué par le code) ; séance lourde et séance de volume d'un mouvement séparées (R2-P7, R3-P3) ; méthodes d'un pilier de répétitions (R4-G1, R4-G2, déjà dans `_repsMethods`). La séparation des qualités par journée et l'ordre force puis endurance dans la semaine sont des **choix raisonnés** : la littérature ne fixe pas de chiffre, le banc les mesure (§ 9).

**Décision** : le gabarit devient une **variable de décision explicite**, choisie dans une bibliothèque, **avant** le choix des exercices ; la règle de choix est écrite, déterministe et expliquée (« j'ai choisi … parce que … »).

## 3. Concepts

### 3.1 Type de jour

`DayType = (schémas, qualité, stress)`.

- **Schémas** : `pull` (tirage vertical et horizontal, muscle-up compté ici), `push` (dips, pompes, poussée verticale), `legs` (squat, charnière, unilatéral), `full` (au moins deux des trois), `skill` (figures), `run`, `recovery`.
- **Qualités** (vocabulaire fermé, additif plus tard) :

| Qualité | Plage visée | Méthodes déjà au code |
| --- | --- | --- |
| `force` | 1-6 répétitions, ≥ 80 % du 1RM, repos 3-5 min | top set + allégées, clusters, simples |
| `volume` | 6-12 répétitions, 65-80 % | séries classiques, double progression |
| `endurance` | séries longues au poids du corps ou charge fixe, densité | série de référence, clusters de volume, échelles, EMOM, repos-pause (`_repsMethods`) |
| `power` | vitesse maximale, loin de l'échec | explosifs, tirage explosif, MU explosifs |
| `skill` | tenues et progressions de figures | `_buildFigures` |
| `conditioning`, `run`, `recovery` | — | chemins existants |

- **Stress** : `heavy`, `medium`, `light` (déjà `DayStress`), dérivé de la qualité et de la phase.

### 3.2 Gabarit de semaine

Un gabarit est une suite ordonnée de types de jour avec ses contraintes : séances (min, max), fréquence par schéma, écart minimal entre deux jours du même schéma, part des qualités. Bibliothèque initiale (codes stables, textes de Koach pour chacun) :

| Code | Séances | Suite (exemple) | Pour qui |
| --- | --- | --- | --- |
| `fb2`, `fb3` | 2-3 | full force / full volume (/ full endurance) | débutant, peu de temps |
| `ul4` | 4 | haut force, bas force, haut volume, bas volume | 4 séances, une qualité dominante |
| `ppl3` | 3 | pull, push, legs (une qualité par semaine, ondulée par bloc) | 3 séances, schémas séparés |
| `ppl6_q` | 6 | pull F, push F, legs F, pull E, push E, legs E (+ power sur legs E quand le MU est visé) | **deux qualités à poids comparable** (streetlifting + sets & reps, force + hypertrophie) |
| `pp_l5` | 5 | pull F, push F, legs, pull E/V, push E/V | 5 séances, jambes secondaires |
| `lift_dup` | 3-6 | l'actuel (un mouvement lourd par jour, ondulation par mouvement) | streetlifting pur, conservé tel quel |
| `reps_pillars` | 3-6 | l'actuel `_buildReps` | sets & reps pur, conservé tel quel |
| `figures` | 3-6 | l'actuel `_buildFigures` | calisthénie |

Les chemins actuels deviennent des gabarits de la bibliothèque : **aucun profil mono-discipline ne change** tant qu'un gabarit nouveau ne le bat pas à la règle du § 3.4 (contrôle d'identité au banc, § 9).

### 3.3 Proportion des qualités

1. Besoins : chaque objectif donne une qualité sur un schéma (`one_rm_kg` → force ; `max_reps`, `max_reps @ charge` → endurance ; `max_hold_seconds`, `skill_unlocked` → skill) ; chaque discipline déclarée donne sa part (`primaryPct`, secondaires, `streetMode`).
2. Phase : la part de la qualité de l'échéance visée monte en intensification et réalisation (65 à 75 % de spécifique pour un objectif de répétitions, règle déjà au contrat § 12.13 ; même logique pour la force).
3. Séances par qualité : répartition au plus fort reste (méthode de Hamilton) sur le nombre de séances, plancher d'une séance pour toute qualité qui porte un objectif.

Profil de test : 6 séances, 50 / 50 → 3 force, 3 endurance → `ppl6_q`.

### 3.4 Choix du gabarit (ordre lexicographique, sans compensation)

Un gabarit est éliminé s'il viole une contrainte dure ; les survivants sont classés dans cet ordre, le suivant ne départageant qu'à égalité :

1. **Sécurité** : règles actuelles (douleur, poignet, coude, reprise), inchangées.
2. **Couverture** : 100 % des objectifs avec au moins un emplacement porteur par semaine hors allègement (§ 4).
3. **Récupération** : aucun schéma chargé lourd deux jours de suite ; 48 h au moins entre deux séances dures du même schéma, quelle que soit la qualité (composante `recovery` du score ≥ 0,9).
4. **Spécificité** : fréquence d'exposition des mouvements visés (≥ 2 par semaine pour un mouvement de compétition hors spécialisation).
5. **Temps** : chaque séance dans ± 15 % du temps disponible, aucune séance sans emplacement principal (sauf type `recovery`).
6. **Préférences** : exercices aimés, connus.

Cet ordre remplace, pour la structure, la moyenne pondérée de `score.dart`, où une composante à 1,0 rachète une récupération à 0,48. Le score reste calculé et affiché ; ses composantes saturées (`joint_load`, `fatigue_balance` à 1,0 avec 23 séries de tirage vertical par semaine) et `preferences` (qui ne récompense pas les exercices aimés) sont recalés dans le même lot.

### 3.5 Placement dans la semaine

Après le choix du gabarit, les types de jour sont placés sur les jours réels par recherche exhaustive (au plus 6! = 720 ordres) sous contraintes : récupération (§ 3.4.3) ; le jour qui porte le mouvement le plus exigeant ouvre la rotation, après le jour de repos (§ 11.2) ; dans chaque séance, ordre décroissant d'exigence ; jour `force` de préférence après un jour de repos ou un jour d'un autre schéma ; jour `endurance` d'un schéma à 72 h de son jour `force` quand c'est possible ; le jour le plus court reçoit le type le moins long. Égalités : ordre le plus régulier (règle de `spreadDays`).

### 3.6 Remplissage

Chaque type de jour appelle le constructeur qui existe déjà pour sa qualité : force (`_buildLifting`, restreint aux schémas du jour), endurance (`_addRepsPillar`, `_repsMethods`), skill (`_buildFigures`), legs (`_addLegs`). Les compléments (`_fillTime`) ne remplissent que les jours déjà porteurs ; un jour sans principal est une erreur d'audit, pas un jour à remplir.

## 4. Couverture des objectifs (contrainte dure)

- Chaque objectif reçoit au moins un emplacement porteur (`plan.goal_support`) par semaine hors allègement et test, avec une méthode de sa qualité.
- Objectif en répétitions à charge donnée (squat 35 × 70 kg) : ligne à **charge fixe** (`load.type == 'fixed'`, règle C15.2 déjà tenue par l'application et par KM3).
- Point faible « prise » (`grip`) : suspension ou dead hang au maximum dans le jour `pull` endurance ; « fatigue de fin de série » : méthode d'endurance de son mouvement.
- L'audit (`coach/audit.dart`) refuse un bloc qui laisse un objectif sans porteur ; la raison est dite.

## 5. Échéances et jalons

- `targetOf` : une échéance **principale** prime ; une échéance **secondaire** ne prime pas sur des objectifs datés plus tôt. Les objectifs datés avant l'échéance retenue deviennent des **jalons** : semaine de test à leur date (mini-pic sans affûtage complet), puis reprise de la saison vers l'échéance.
- Profil de test : jalon de test du 26 au 30/04/2027 (9 objectifs) ; puis saison vers le 15/12/2027.
- La saison n'enchaîne plus plus de trois cycles identiques sans changement de stimulus (plateau, règle de CP2) : alternance accumulation / intensification par bloc de 4 à 6 semaines, conforme à D4.8.

## 6. Contrat (évolution additive)

- `kalis_core` 0.4.4 : `DaySpec.type` facultatif (`{patterns: [...], quality, stress}`) ; `Pass1Plan.split` facultatif (`{templateId, reasons}`) ; codes de raison `plan.split_chosen`, `plan.day_type`, `plan.goal_uncovered` (audit), `plan.milestone`, `plan.replaced_disliked`, `plan.replaced_cannot_do`. Un JSON 0.4.3 se relit et se réécrit à l'identique.
- `kalis_plan` 0.4.0 : bibliothèque de gabarits, choix, placement, remplissage, audit ; API inchangée (`createProgram`, `nextBlock`, revue).
- `kalis_adapt` : rien. Koach 1.0 lit `DaySpec.type` s'il existe (qualité du jour pour la distance de transport par qualité) — à noter pour KM3, pas obligatoire.
- Application (lot court après KS1) : type du jour affiché dans MON PROGRAMME et dans la séance (« Tirage — force ») ; programme de 40 semaines annoté avec ses types de jour (J1 à J3 force, J4 et J5 volume/endurance, J6 puissance et endurance) dans `lib/imported_program.dart`.

## 7. Exemple attendu (profil de test, critère d'acceptation)

`ppl6_q`, lundi à samedi, dimanche repos ; 120 min par séance.

| Jour | Type | Contenu (porteurs en gras) |
| --- | --- | --- |
| Lundi | pull · force | **MU lesté** (lourd), **traction lestée** (lourd), traction pause haut (lockout), rowing barre, curl marteau |
| Mardi | push · force | **dips lesté** (lourd), dips pause bas (bas), pompes lestées, face pull, rotation externe |
| Mercredi | legs · force | **squat** (lourd), squat pause bas (bas), soulevé de terre roumain, gainage |
| Jeudi | pull · endurance | **tractions PdC** (série de référence + clusters), **MU strict** (densité), dead hang max (prise), rowing |
| Vendredi | push · endurance | **dips PdC**, **pompes PdC** (séries longues, échelles), extension triceps, prévention épaule |
| Samedi | legs · endurance + power | **squat 70 kg** (charge fixe, reps), MU explosif ou tirage explosif léger, fentes, mobilité |

Contrôles : muscle-up lesté en tête du lundi et lundi en tête de la rotation (§ 11.2) ; 9 objectifs sur 9 portés ; chaque schéma 2 fois par semaine à 72 h ; aucun schéma lourd deux jours de suite (le lockout du MU lundi et le dips lourd mardi sont deux schémas différents ; à surveiller par la conduite sous douleur du coude) ; séances de 100 à 125 min ; 0 jour sans principal.

### 7.1 Profil de test au banc (`ks_test_ppl6`)

Le fichier `testdebug.json` du propriétaire n'est pas dans le dépôt (pièce jointe d'une conversation). S'il est déposé, il l'est **chiffré** sous `pipeline/cp/inputs/ks1/testdebug.json.gpg` (même clé que les références, C7.8) et sert tel quel. Sinon, le lot construit au banc le profil équivalent `ks_test_ppl6` à partir de ce cahier, valeurs à écrire dans la livraison :
- mode street, streetlifting 50 % / sets & reps 50 %, niveau avancé ; 6 séances (lundi à samedi), 120 min, salle équipée (barre, lest, rack) ;
- capacités : 1RM système de traction 128 kg ; squat 120 kg à RIR 2 (e1RM ≈ 127 kg) ; muscle-up : 1RM système 88 kg (82,5 % × 88 = 72,6 kg, sous le poids du corps : c'est le cas qui bloquait le lest à +0 kg ; poids du corps en choix raisonné entre 73 et 85 kg), 10 muscle-ups stricts au maximum, environ 70 dips aux barres ; moins de 5 séries par mouvement une fois par semaine avant le programme ;
- 9 objectifs datés du 30/04/2027 : muscle-up lesté +5 kg, traction lestée, dips lesté, squat (charge), tractions max, pompes max, dips max, muscle-up strict max, squat 35 × 70 kg ; échéance « secondary » au 15/12/2027 ;
- points faibles : lockout (tirage), bas (dips, squat), prise, fatigue de fin de série ; stress faible ; exercices aimés nombreux, deux exercices rejetés (une rotation thoracique « n'aime pas », un oiseau « ne peut pas faire »).
Les chiffres non écrits ici sont des **choix raisonnés** du lot, dits comme tels.

## 8. Corrections associées (même lot)

1. **Plancher du poids du corps** : quand la part du 1RM tombe sous le poids du corps sur un mouvement lesté visé, prescrire une charge minimale (le plus petit pas de lest du profil) et régler les répétitions par la réserve visée, au lieu de +0 kg et de répétitions qui baissent d'une semaine à l'autre.
2. **Référence des variantes** : traction haute → traction lestée ; dips barre fixe → dips lesté ; coefficient de transfert par variante (table relue, « choix raisonné » si aucune source).
3. **Charges des variantes pause** : charge servie = pourcentage annoncé ; un allègement ne sert jamais plus lourd que la semaine de construction précédente.
4. **Squat pause bas** : dérivé du 1RM du squat comme les dips pause bas.
5. **Raisons des remplacements** : le remplaçant porte `plan.replaced_disliked` / `plan.replaced_cannot_do`, jamais la raison du remplacé.

## 9. Validation (automatique, sans panel — comme C13.3)

| Critère | Seuil |
| --- | --- |
| Violations de sécurité (banc des saisons, 27 profils + nouveaux) | 0 |
| Couverture des objectifs | 100 % des objectifs, toutes semaines hors allègement et test |
| Récupération (composante du score) | ≥ 0,9 sur chaque bloc des profils à 4 séances et plus |
| Temps par séance | ± 15 % du disponible ; 0 séance sans principal |
| Profils mono-discipline | squelette identique à 0.3.1 octet pour octet, sauf si un gabarit nouveau le bat à la règle du § 3.4 (écart listé et justifié) |
| Profil de test (`testdebug.json` ou `ks_test_ppl6`) | gabarit `ppl6_q`, contrôles du § 7 |
| Ordre par exigence (§ 11.2) | mouvement le plus exigeant en tête de chaque séance ; son jour en tête de la rotation, sauf contrainte de récupération (écart dit) |
| Non-ressemblance aux références | ≤ 0,30 (règle CR.8) |
| Relecture indépendante du code (sous-agent Opus) | 0 bloquant ouvert |

Profils ajoutés au banc : streetlifting 50 / sets & reps 50 à 4, 5 et 6 séances ; sets & reps principal avec streetlifting secondaire ; force + hypertrophie (autres disciplines) ; calisthénie avec 30 % de sets & reps.

## 10. Lot, ordre et budget

- **KS1 — structure de la semaine** : `moteurs`, branche de contrôle **`claude/ci-cp-b`** (C17 : KM2c1 tourne en même temps sur `claude/ci-cp-a`). Modèle : **Opus 5.5, effort maximal** (règles et critères écrits ici ; Fable n'est pas nécessaire, C13.9). Contenu dans l'ordre : contrat `kalis_core` 0.4.4 → bibliothèque et choix du gabarit → placement → remplissage → couverture et jalons → corrections du § 8 → banc → relecture → publication `kalis_plan` 0.4.0.
- **Ordre** (C17) : KM2c1 et KS1 en parallèle (paquets différents, rebase avant chaque push) ; puis KM1c3 ; KS1 entre dans l'application par un lot court (types affichés, programme de 40 semaines annoté), **avant KM3** si possible pour que Koach parte d'une structure juste ; sinon par une montée de paquet après KM3. La bascule du 23/11/2026 n'en dépend pas : le programme du propriétaire garde sa structure (déjà en types de jour), seuls les programmes générés changent.
- **Jalon visé** : 25/10/2026.

## 11. Décisions du propriétaire (11/10/2026, 21:17)

1. **Seuil d'une discipline secondaire** : « 25 % c'est bien. » Une discipline secondaire à 25 % ou plus crée ses propres jours ; en dessous, elle reste en compléments.
2. **Ordre par exigence** : « Tirage toujours en premier si c'est le mouvement qui demande le plus de ressources. » Règle générale : dans une séance, le mouvement le plus exigeant ouvre la séance (muscle-up lesté avant la traction lestée sur le jour tirage force) ; dans la semaine, le jour qui porte le mouvement le plus exigeant ouvre la rotation, après le jour de repos. L'exigence se compare par mouvement : intensité relative × part du 1RM système, complexité technique, risque articulaire ; le muscle-up lesté est classé premier des quatre mouvements de compétition. Le muscle-up lesté reste sur le jour tirage force, en tête.
3. **Validation** : « Comme KM, je ferai mes retours plus tard pour une future mise à jour. » Critères automatiques seuls (§ 9) ; les retours du propriétaire iront à une mise à jour ultérieure, pas à KS1.
