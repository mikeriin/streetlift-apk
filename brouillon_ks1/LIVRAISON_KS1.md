# Livraison KS1 — structure de la semaine : `kalis_plan` 0.4.0, `kalis_core` 0.4.4, `kalis_bench` 0.5.0

Lot KS1 du pipeline CP (cahier `CAHIER_KS.md`, décisions C13.3, C15.2, C17), voie A, session Opus 5.5 effort maximal
lancée par la tâche planifiée « moteurs » le 15/10/2026 à 15:30 UTC (message sans « Lot : » ; KM2c1 était déjà pris
à 15:29 par une autre session). Prompt : `prompts/KS1.txt`. Base : `moteurs` 9ac79e40 (`kalis_plan` 0.3.1). Contrôle :
`claude/ci-cp-b`. Validation automatique sur les critères du § 9 (sans panel, sans relecture documentée).

**En une phrase** : le créateur choisit désormais un gabarit de semaine avant les exercices ; les profils qui mêlent
streetlifting et sets & reps reçoivent des jours de force et des jours d'endurance de force (profil de test : `ppl6_q`
à chaque bloc, muscle-up lesté en tête du lundi, chaque schéma deux fois à 72 h, récupération 1,0 au lieu de 0,50,
neuf objectifs portés chaque semaine au lieu de 116 couples sans porteur) ; les 27 profils mono-discipline gardent
leur squelette de 0.3.1 à l'identique ; **deux critères du § 9 ne sont pas tenus** : le temps par séance (séances
de 27 à 47 % du créneau sur le profil de test, comme en 0.3.1 sur tous les profils) et, sur les seuls profils
mono-discipline, que le critère d'identité fige, la récupération d'un profil, les séances sans principal et l'ordre
de rotation.

## 1. Livré

| Paquet | Version | Étiquette | Commit (`moteurs`) |
| --- | --- | --- | --- |
| `kalis_core` | 0.4.4 | `etiquettes/kalis_core-v0.4.4` | COMMIT_CORE |
| `kalis_plan` | 0.4.0 | `etiquettes/kalis_plan-v0.4.0` | COMMIT_PLAN |
| `kalis_bench` | 0.5.0 | `etiquettes/kalis_bench-v0.5.0` | COMMIT_PLAN |

Contrôle complet `claude/ci-cp-b` : RUN_COMPLET (tous les paquets : format, analyse, tests, rapports).
`kalis_adapt` et l'application ne sont pas touchés.

- **`kalis_core` 0.4.4** (commit séparé, additif) : `PlanDay.type` (`DayType` : schémas `pull`, `push`, `legs`,
  `full`, `skill`, `run`, `recovery` ; qualité `force`, `volume`, `endurance`, `power`, `skill`, `conditioning`,
  `run`, `recovery` ; charge), `Pass1Plan.split` (`SplitChoice` : gabarit, raisons), six codes de raison
  (`plan.split_chosen`, `plan.day_type`, `plan.goal_uncovered`, `plan.milestone`, `plan.replaced_disliked`,
  `plan.replaced_cannot_do`, 144 codes au registre). Un plan 0.4.3 se relit et se réécrit à l'identique (test).
- **`kalis_plan` 0.4.0** : bibliothèque de gabarits (`ppl6_q`, `pp_l5`, `ul4`, `fb3`, `fb2`, composite `mix_q` ;
  chemins d'avant pour les profils mono-discipline), qualités au plus fort reste (seuil 25 %, § 11.1), choix
  lexicographique (couverture, récupération ≥ 0,9, spécificité, temps, préférences), placement exhaustif (720 ordres
  au plus), remplissage par type, mouvement le plus exigeant en tête (§ 11.2), couverture des objectifs, jalons,
  quatrième bloc en intensification, note recalée (récupération, répartition de la charge, charge par schéma,
  préférences), corrections de charge du § 8, raisons des remplacements à la revue. API inchangée. Détail et
  justifications : `docs/STRUCTURE_SEMAINE.md`, contrat § 12.15.
- **`kalis_bench` 0.5.0** : critères du § 9 (`lib/src/structure_criteria.dart`, rapport `STRUCTURE.md`), sept
  profils ajoutés (`profiles_ks/`), mesures de 0.3.1 figées (`docs/data/ks1/`), type du jour dans l'export des
  programmes (« tirage, endurance de force »).

## 2. Critères du § 9

Banc : 34 profils (27 du banc, 7 ajoutés), graine 0, horizon du profil (profil de test : 40 semaines). « Avant » :
`kalis_plan` 0.3.1 mesuré par le même module (contrôle `claude/ci-cp-b`, run 38770773654).

| Critère | Seuil | Avant (0.3.1) | Mesuré (0.4.0) | Tenu |
| --- | --- | --- | --- | --- |
| Violations de sécurité, programmes créés (34 profils) | 0 | 0 | 0 | oui |
| Violations de sécurité, saisons du banc (27 profils + 7 ajoutés) | 0 | SAISONS_AVANT | SAISONS_APRES | SAISONS_TENU |
| Couverture des objectifs, semaines de charge | 100 % | 78,4 % (182 couples sans porteur sur 841, tous sur les profils mixtes) | 100 % (0 sur 841) | oui |
| Récupération ≥ 0,9 par bloc, profils à 4 séances et plus | 0 bloc sous le seuil | 64 blocs sur 68 (note 0.1) ; 6 au recalcul du banc | 2 blocs sur 68 (`autres_02`, gabarit inchangé, 0,852) | **non** (profil mono figé) |
| Temps par séance ± 15 % du disponible | 0 séance hors bande | 1176 sur 1329 | 1175 sur 1329 | **non** |
| Séance sans principal | 0 | 112 | 51 (toutes sur des profils mono figés) | **non** (profils mono figés) |
| Squelette des profils mono-discipline identique à 0.3.1 | tous | — | 27 sur 27, à l'octet | oui |
| Mouvement le plus exigeant en tête de séance | 0 séance | 0 sur 167 | 0 sur 149 | oui |
| Son jour en tête de la rotation | 0 bloc (sauf écart dit) | 42 sur 44 | 12 sur 44 (`street_07`, `08`, `09`, `10`, gabarits inchangés) | **non** (profils mono figés) ; mixtes 0 sur 30 |
| Profil de test : gabarit `ppl6_q`, contrôles du § 7 | tous | gabarit `lift_dup`, 116 couples sans porteur, récupération 0,50 | `ppl6_q` à chaque bloc ; 7 contrôles sur 8 (§ 4) | **non** (durée des séances) |
| Non-ressemblance aux références | ≤ 0,30 | 0,231 / 0,250 (CY) | JACCARD | oui |
| Relecture indépendante du code (sous-agent Opus) | 0 bloquant ouvert | — | 3 bloquants trouvés, 3 corrigés (§ 7) | oui |

Sur les sept profils mixtes (les seuls que le lot pouvait changer) : récupération 0 bloc sous 0,9 sur 27 (27 avant),
couverture 100 % (182 couples sans porteur avant), 0 séance sans principal (53 avant), rotation 0 écart sur 30 (30
avant), temps 434 séances hors bande sur 436 (435 avant).

## 3. Écarts : pourquoi trois critères restent « non »

1. **Profils mono-discipline figés.** Le cahier (§ 3.2, § 9) demande à la fois que ces profils gardent leur squelette
   de 0.3.1 « tant qu'un gabarit nouveau ne le bat pas » et que chaque bloc tienne la récupération, le principal et
   la rotation. Le lot ne construit aucun gabarit nouveau pour une seule qualité (`ppl3`, `ul4` mono-qualité,
   gabarits de musculation) : les 27 profils restent identiques, avec leurs défauts de 0.3.1 — `autres_02`
   (musculation, deux jours voisins sur les fessiers : 0,852), séances sans principal de `lift_dup`, `figures`,
   `reps_pillars`, `power_dup`, `wod_week` (jours de figure, de technique, de conditionnement), rotation de
   `street_07` à `street_10`. Ce qu'il faudrait : un lot court « KS2 » de gabarits à une qualité, mesurés contre le
   chemin actuel par la même règle (le banc le permet tel quel).
2. **Temps par séance.** Les séances durent 25 à 75 % du créneau sur presque tous les profils, en 0.3.1 comme en
   0.4.0 : les plafonds de volume par groupe musculaire (R4-F10, R5-P22, garde-fous de CX à CY) bornent le travail
   avant le temps. Sur le profil de test, six séances de 120 min, 46 à 64 séries dures par semaine (35 à 53 min par
   séance) : remplir 100 à 125 min demanderait environ le double de séries dures, au-delà des plafonds hebdomadaires
   que la sécurité fait respecter. La règle lexicographique met la sécurité et la récupération avant le temps ; le
   lot n'a pas relevé les plafonds. **À trancher par le pilotage** : (a) garder les plafonds et afficher la durée
   estimée (l'application la montre déjà) ; (b) autoriser au profil avancé et élite un volume plus haut (lot de
   calibrage, avec le banc de sécurité) ; (c) remplir le créneau par de la technique et de la mobilité, qui ne
   comptent pas comme séries dures.
3. **Rotation des profils mono** : voir 1.

## 4. Profil de test `ks_test_ppl6` (§ 7.1)

`testdebug.json.gpg` n'est pas déposé : profil équivalent construit au banc. Valeurs (choix raisonnés dits comme tels) :
homme avancé, 30 ans, **80 kg** (choix raisonné dans 73 à 85 kg), 48 mois d'entraînement structuré ; street,
streetlifting 50 % / sets & reps 50 % ; lundi à samedi, 120 min, salle équipée (barre, rack, ceinture et disques,
pas de lest de 1,25 kg) ; records relevés il y a deux semaines : traction lestée +48 kg (1RM système 128 kg), muscle-up
lesté +8 kg (1RM système 88 kg), squat 127 kg (e1RM de 120 kg à 2 en réserve), dips lesté +70 kg (choix raisonné :
« environ 70 dips » est lu comme la charge du dips lesté), 22 tractions, 35 dips (choix raisonné), 60 pompes, 10
muscle-ups stricts ; neuf objectifs datés du 30/04/2027 : muscle-up lesté +13 kg (« +5 kg » lu comme 5 kg de plus que
le record), traction lestée +55 kg, dips lesté +77,5 kg, squat 135 kg, 26 tractions, 70 pompes, 42 dips, 13 muscle-ups
stricts, squat 35 × 70 kg ; échéance secondaire (compétition de streetlifting, priorité B) le 15/12/2027 avec quatre
cibles de barre ; points faibles : verrouillage du tirage, bas du dips, bas du squat, prise, fatigue de fin de série ;
stress 2/5 ; douze exercices aimés ; rotation thoracique « n'aime pas », oiseau « ne peut pas faire ».

**Semaine type** (bloc 1, semaine 2, construction) — `ppl6_q`, dimanche repos :

| Jour | Type | Porteurs | Compléments | Durée estimée |
| --- | --- | --- | --- | --- |
| Lundi | tirage · force | muscle-up lesté 4 × 3 (+3,75 kg), traction lestée 4 × 5 (+23,75 kg, 81 %), traction lestée pause en haut 2 × 4 | rowing barre, curl marteau, gainage, row scapulaire | 53 min |
| Mardi | poussée · force | dips lesté 4 × 5 (+38,75 kg, 79 %), dips lesté pause en bas 2 × 4, pompes lestées 2 × 8-10 | face pull, rotation externe, tronc | 46 min |
| Mercredi | jambes · force | squat 3 × 5 (97,5 kg, 77 %), squat pause en bas 2 × 4 (85 kg) | soulevé de terre roumain, tronc | 35 min |
| Jeudi | tirage · endurance | tractions 19 puis 2 × 14, muscle-up strict EMOM 5 × 3, dead hang 5 × 10 s (prise) | rowing, tronc, row scapulaire | 51 min |
| Vendredi | poussée · endurance | dips 31 puis 2 × 23, pompes 5 × 27 au chrono | pushdown, rotation externe, tronc | 50 min |
| Samedi | jambes · endurance (+ puissance) | squat 3 × 21 à 70 kg (charge fixe), traction explosive 2 × 3-5 | fentes, tronc, mobilité | 34 min |

**Saison** (40 semaines) : blocs 1 à 3 accumulation, bloc 4 intensification (quatrième bloc, plus de trois blocs
d'accumulation de suite), bloc 5 accumulation, bloc 6 intensification, bloc 7 réalisation de 6 semaines vers le jalon
du 30/04/2027 (affûtage semaine 29, test semaine 30, `plan.milestone`), puis la saison repart vers l'échéance de
décembre (bloc 8 intensification, blocs 9 et 10 accumulation). `ppl6_q` à chaque bloc ; en intensification vers
l'échéance de force, la répartition déplacée (4 force + 2 endurance) laisserait des objectifs sans porteur en six
jours typés et le composite la porterait à une récupération de 0,30 : la répartition 3 + 3 est retenue par la règle.

**Contrôles du § 7** : `ppl6_q` à chaque bloc — oui ; muscle-up lesté en tête du lundi, qui ouvre la rotation — oui ;
neuf objectifs et quatre cibles de l'échéance portés chaque semaine de charge — oui ; chaque schéma deux fois par
semaine à 72 h — oui ; aucun schéma lourd deux jours de suite — oui ; aucune séance sans principal — oui ; premier
jour tirage · force — oui ; **séances de 100 à 125 min — non** (27 à 47 % du créneau, § 3).

## 5. Écarts mono-discipline et changements de sortie hors squelette

- Squelettes des 27 profils du banc : identiques à l'octet (jour, thème, emplacements). Changent pour tous les
  profils du chemin coach : `PlanDay.type` et `Pass1Plan.split` (nouveaux champs), raisons de bloc
  `plan.goal_uncovered` et `plan.milestone` quand elles s'appliquent, note recalée (quatre composantes, § 8 du
  document de structure), en-têtes de l'export du banc (type du jour au lieu du thème).
- Saison : un objectif daté plus tôt qu'une échéance secondaire devient la cible (jalon) s'il est à quatre semaines
  ou plus ; dans une saison d'échéance, la semaine de charge qui le contient devient une semaine de test (pas dans
  les deux premières semaines d'un bloc ni en reprise) ; le quatrième bloc d'une suite passe en intensification.
  Ces règles valent pour tous les profils ; aucun des 27 profils du banc n'en change de squelette sur son horizon.
- Profils street mixtes du banc qui changent (prévu par le cahier) : `street_11` (gabarit composite à 3 séances) et
  `street_12` (`ul4`) ; récupération 1,0 et 0 séance sans principal tous deux.

## 6. Pour le lot court de l'application (après KS1)

1. Lire `PlanDay.type` (facultatif) et l'afficher dans MON PROGRAMME et en tête de séance (« Tirage — force »,
   « Jambes — endurance de force ») ; libellés : schémas `pull` tirage, `push` poussée, `legs` jambes, `full` corps
   entier, `skill` figures, `run` course, `recovery` récupération ; qualités `force`, `volume`, `endurance`
   (endurance de force), `power` puissance, `skill` technique, `conditioning`, `run`, `recovery`.
2. Textes des six nouveaux codes de raison : `kalis_core/data/reason_texts_fr_0_4.json` (0.4.4) ; `plan.split_chosen`
   et `plan.day_type` sont dans `Pass1Plan.split.reasons`, les autres dans les raisons du bloc ou de la ligne.
3. Notes de coach nouvelles : `minimum_load`, `fixed_load` (`kalis_plan/docs/NOTES_COACH.md`).
4. Charge fixe (`load.type == 'fixed'` côté application, C15.2) : la ligne `squat 35 × 70 kg` arrive déjà avec la
   charge de l'objectif et des répétitions qui montent.
5. Programme de 40 semaines importé (`lib/imported_program.dart`) : annoter ses jours (J1 à J3 force, J4 et J5
   volume/endurance, J6 puissance et endurance) avec le même `DayType`.
6. Monter `kalis_core` 0.4.4 et `kalis_plan` 0.4.0 ; `kalis_adapt` inchangé (Koach 1.0 peut lire `type`, non requis,
   à noter pour KM3).

## 7. Relecture, contrôle, références, limites

- **Relecture indépendante** (sous-agent Opus, lecture du diff et de l'arbre) : 3 bloquants, tous dans les charges,
  corrigés et recontrôlés : (1) pas minimal de lest au-dessus du 1RM ou avec une réserve impossible → seulement si
  le pas laisse au moins trois répétitions à la réserve visée ; (2) pas minimal hors des plafonds de reprise après
  douleur, du mode prudent et des semaines légères → seulement en semaine de charge, hors reprise et hors mode
  prudent ; (3) charge fixe d'objectif à 90 % du 1RM et plus → seulement sous 80 % du 1RM, hors prudent et reprise
  (sinon séance de volume), une répétition de plus toutes les deux semaines, jamais à moins d'une en réserve. Non
  bloquants traités : adjacence circulaire de la récupération, contrôles du profil de test au banc. Non bloquants
  laissés (dits ici) : le jour d'ouverture quand le coude est ménagé suit l'ordre du gabarit ; le squelette canonique
  est reconstruit à chaque relecture de la note (coût, pas d'effet) ; le type d'un jour vidé par le repli reste celui
  du gabarit ; « sans principal » compte la pratique de figure au banc mais pas au choix du gabarit.
- **Contrôle** : mise au point sur `claude/ci-cp-b` (runs 38766406367 à 38779114208 : analyse, formatage, tous les
  tests de `kalis_plan` dont les 20 480 profils de propriétés, test de structure du banc) ; contrôle complet
  RUN_COMPLET.
- **Non-ressemblance** (`tool/reference_jaccard.py`, calculée dans la session avec la clé, sur les 34 programmes
  SAISONS_JACCARD) : JACCARD_DETAIL (seuil 0,30). Détail chiffré sur `cp-references` (`analyse_KS1.tar.gpg`). Clé
  passée à gpg par un fichier `/tmp` en mode 600, supprimé après usage ; rien de déchiffré committé.
- **Limites** : part annoncée du muscle-up lesté du profil de test calculée sur le record (85,5 kg de charge totale)
  quand la charge suit le 1RM de travail relevé d'après les dix muscle-ups (§ 8.1) : « ≈ 95 % » s'affiche pour 3
  répétitions à 2 en réserve ; les gabarits typés ne servent que les profils street mixtes (une seule qualité : chemin
  d'avant) ; un test de répétitions à charge donnée n'est pas écrit (la ligne à charge fixe progresse, le test de fin
  de bloc porte sur le 1RM) ; le quatrième bloc passe en intensification par son rang dans la saison, sans compter
  les blocs d'accumulation qui précèdent après une échéance.
