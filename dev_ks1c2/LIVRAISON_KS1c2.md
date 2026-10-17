# Livraison KS1c2 — aucun jour sans son principal (`kalis_plan` 0.4.2, `kalis_bench` 0.5.4)

17/10/2026 · session Opus 5.5, effort maximal (tâche « Opus 5.5, effort maximal, moteurs », C17.22) · voie A, contrôle
`claude/ci-cp-b` · validation automatique par le pilotage (C17.21).

## 1. Ce qui est livré

- **`kalis_plan` 0.4.2** (`etiquettes/kalis_plan-v0.4.2`) : chaque jour d'un gabarit typé (`ppl6_q`, `pp_l5`, `ul4`,
  `fb3`, `fb2`) porte un emplacement principal d'un de ses schémas et chacun de ses schémas (deux des trois pour un
  corps entier) — `coach/structure.dart`, `_ensurePrincipal` ; note de coach `reps_calibrate` ; contrat § 12.17 ;
  `docs/STRUCTURE_SEMAINE.md` § 5 ; `CHANGELOG.md`.
- **`kalis_bench` 0.5.4** (`etiquettes/kalis_bench-v0.5.4` ; 0.5.3 réservée à KR1, C17.22) : critère « aucun jour sans
  son principal » au rapport de structure (`principal_criteria.dart`), grille de 576 profils incomplets, profil du
  constat de KS1A (`profiles_ks1c2/ks1a_street_5050.json`), test `test/ks1c2_test.dart`.
- `moteurs` : __MOTEURS__ (rebasé sur 597c10b7, KR1 : `kalis_adapt` 1.0.3, `kalis_bench` 0.5.3) ; contrôle complet `claude/ci-cp-b` run __RUN__ vert.
- Rien dans `kalis_adapt`, `kalis_core` ni l'application.

## 2. Cause (test qui échoue avant)

Profil du constat reproduit au banc (`ks1a_street_5050` : réplique de `sampleStreet5050Profile` de l'application —
avancé, 75 kg, 50 / 50, six séances de 120 min, salle sans haltères ni poulie, questionnaire de santé **non rempli**,
seuls repères traction lestée 35 kg et 13 tractions, compétition principale dans 12 semaines). `kalis_plan` 0.4.1,
gabarit `ppl6_q` : le jour 5 « poussée — endurance de force » = suspension active, relevés de jambes, cat-cow,
étirement du poignet — **aucun exercice de poussée** (17 min estimées sur 120), exactement le constat de KS1A.

Cause dans `_buildTyped` (`coach/structure.dart`) : les briques d'endurance n'ajoutent un exercice que si son
maximum est connu — `pushEndurance` : dips si `dipMax ≥ 1`, pompes si `pushMax ≥ 1` ; `pullEndurance` : tractions si
`pullMax ≥ 1` ; même chose pour les replis de force sans lest (dips, traction au coude ménagé) et pour les jambes sans
squat (secondaires seulement). Les compléments de la brique (pushdown, rotation externe) demandent une poulie, des
haltères ou un élastique : absents du profil. **Le mode prudent n'est pas la cause** : sur la grille, les écarts sont
identiques avec un questionnaire standard, non rempli ou prudent (163 chacun) ; c'est l'absence de repère.

Mesure avant (0.4.1) sur la grille des profils incomplets : **489 jours en défaut** sur 8 928 jours de 576 profils
(tous les blocs) — repères : tous 24 (le profil du constat, qui n'a que des repères de tirage), sans tirage 135, sans
poussée 183, aucun 99, sans jambes 24, sans muscle-up 24 ; niveau : intermédiaire 135, avancé 177, élite 177,
débutant 0 (le débutant ne passe pas par le chemin typé : gabarit `fb_beginner`). Les 34 profils du banc : 0 écart de
schéma (leurs repères sont complets). Tests `kalis_plan/test/ks1c2_test.dart` (rouges sur 0.4.1 : jour poussée E sans
poussée) et `kalis_bench/test/ks1c2_test.dart`.

## 3. Correction à la source

`_ensurePrincipal`, appelé pour chaque jour typé après ses briques, **n'agit que si le jour ne tient pas la règle** :

1. chaque schéma non porté reçoit son **principal de repli**, le travail que le jour aurait reçu avec un repère,
   dosé sans repère par les règles existantes de la passe 2 : traction (prise neutre et note `pull_return` quand le
   coude est à ménager), traction assistée, tirage horizontal au poids du corps, puis chargé ; dips, sinon pompes
   (variantes dures un jour de force) ; jambes unilatérales ou au poids du corps. Force : 4 à 6 répétitions à 2 en
   réserve (`_repsStrength`) ; endurance : 5 à 8 à 3 en réserve (`_repsVolume`), double progression ; **trois séries
   en mode prudent**, quatre sinon (ACSM 2009, *Progression models in resistance training* : une à trois séries au
   début ; volume réduit, schéma tenu) ; en semaine 1 du premier bloc, une **première série de mesure** est proposée
   (note `reps_calibrate` : « première série jusqu'à la réserve écrite, note le total, déclare-le ou fais son test
   guidé ») ;
2. sans principal, le premier travail porteur d'un de ses schémas devient le principal (secondaire : séries de
   répétitions, séries chargées, pompe lestée, jambes d'un jour sans squat ; sinon tirage horizontal d'assistance) ;
3. sinon un principal de repli s'ajoute.

Le principal servi ouvre la séance (après la préparation), est gardé par les plafonds (`keep`) et ne reçoit pas de
note de rôle d'assistance. Si aucun exercice du schéma n'est possible, le jour prend le type déduit de ses emplacements
et la raison suit son `plan.day_type` dans `Pass1Plan.split.reasons` : `plan.joint_limitation` (limitation la plus
gênante parmi celles qui sollicitent le mouvement de base), `plan.equipment_missing` (matériel absent ce jour-là) ou
`plan.prerequisite_missing` — codes existants, rien d'ajouté à `kalis_core`. Exemple mesuré : poignet à 6 ou 8 sur 10
→ les deux jours de poussée deviennent des jours de récupération avec `plan.joint_limitation {poignet, 6}` ; genou à 8
→ les jours de jambes gardent leur schéma par le pont fessier unilatéral (sollicitation faible du genou).

Profil du constat après correction : jour 5 = suspension active, **dips 3 × 5-8 à 3 en réserve** (principal, en tête,
note `reps_calibrate`), relevés de jambes, mobilité ; les cinq autres jours inchangés.

## 4. Critères (prompt, § Banc)

| Critère | Mesure | Tenu |
| --- | --- | --- |
| 0 jour typé sans exercice principal de son schéma, 34 profils | 0 écart de schéma ; 0 jour de gabarit typé sans principal | oui |
| Même critère, grille des profils incomplets (576 profils : 8 bases × 6 états de repères × 3 questionnaires × 4 niveaux, tout l'horizon) | 0 (avant : 489) | oui |
| Aucun recul sur les critères tenus par KS1 et KS1c1 | squelettes des 34 profils identiques à 0.4.1 (signatures comparées) ; __STRUCTURE__ | oui |
| 0 nouvelle violation de sécurité | programmes créés des 34 profils identiques à 0.4.1 ; saisons racontées (graine 0, modèle B, tous les scénarios) : `SECURITE.md` identique à 0.4.1 (banc 0, profils ajoutés 2 — les deux de KS1c1, cause dans `kalis_adapt`) ; seules 4 saisons « douleur à l'épaule » changent (`street_12`, `ks_01`, `ks_03`, `ks_04` : jours de poussée servis autrement) ; campagne des saisons sur toutes les graines : __CAMPAGNE__ ; grille : __GRILLE_SECU__ | __OK_SECU__ |
| Relecture indépendante du code (sous-agent Opus) | 0 bloquant ; 4 majeurs et 10 mineurs traités (§ 5) | oui |

Lecture du critère : un exercice porteur est un emplacement principal, secondaire ou de figure du schéma (le contrat
ne porte pas la méthode). Les gabarits d'avant 0.4.0, figés par le critère d'identité (KS1 : 51 séances), écrivent des
jours de volume en secondaires : ils portent tous leurs schémas et sont comptés à part (« jours figés sans emplacement
principal », __FIGES__). Non-ressemblance aux références : programmes des 34 profils identiques à 0.4.1, mesure de KS1
inchangée (clé non lue). Saisons de référence de Koach (KR1, sept fixtures) : identiques hors la version du moteur
(`km2_banc_test.dart`, version ramenée à 0.4.1 pour la comparaison ; données de `kalis_adapt` non touchées).

## 5. Relecture indépendante (sous-agent Opus)

0 bloquant. Majeurs traités : (1) le principal promu ou ajouté pouvait être retiré par les plafonds (`_fitBudget`) →
`keep` ; (2) un jour de tirage sans barre fixe était déclaré impossible alors qu'un tirage horizontal était faisable →
promotion d'un accessoire polyarticulaire, rowing chargé en dernier recours (test « sans barre fixe ») ; (3) la raison
du changement de type pouvait citer une limitation sans rapport ou un code de schéma → cause lue sur
`Athlete.rejection` du mouvement de base du schéma non tenu, matériel du jour ; (4) tests trop faibles → dosage
vérifié (5-8, trois séries prudentes, valeur de la note), promotion, coude ménagé, gabarits `fb2`/`fb3`, questionnaire
prudent. Mineurs : `referenceId` sur les variantes, pas de note de rôle sur un principal, note de mesure seulement sans
repère de référence, corps entier arrêté à deux schémas portés, paramètre `joint` aligné sur `assemble.dart`, textes
nuancés (le repli consomme du plafond ; `mix_q` et chemins figés mesurés, pas corrigés). Déclarés : `equipment_missing`
n'est pas atteignable sur le catalogue actuel pour un gabarit typé (tirage horizontal aux barres parallèles ou aux
anneaux, pompes au sol) ; le type d'un jour non servi est lu avant les compléments de fin de séance.

## 6. Limites et recommandations (C8)

- **Durée** : le profil du constat reste servi en 20 à 40 min sur 120 (option (a) de C17.15) ; le principal ajouté
  n'est pas un remplissage. L'option (c) (technique et mobilité dans le créneau) reste à faire.
- Le repli ne sert qu'une brique : un jour poussée E sans aucun repère reçoit des dips, pas les pompes en plus.
- Gabarit composite `mix_q` et chemins d'avant 0.4.0 : règle mesurée au banc (0 écart de schéma), pas imposée.
- **Recommandation** : valider `kalis_plan` 0.4.2 et `kalis_bench` 0.5.4 ; l'application les prend par un lot court
  (texte de la note `reps_calibrate` déjà rendu par `coachReasonText` ; les raisons de changement de type peuvent
  s'afficher sur la carte « Structure de la semaine »).
