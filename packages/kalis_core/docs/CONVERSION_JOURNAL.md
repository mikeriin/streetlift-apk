# Ancien journal de l'application → `TrainingLog`

Spécification de la conversion (lot GC). **Le code de la conversion est côté application** (G3 pour la
correspondance des exercices, G9 pour le journal) ; ici : le format lu, les règles, et un exemple
avant / après (`test/fixtures/legacy_journal.json`, produit par la conversion de référence de
`tool/gen_fixtures.py`, vérifié par `test/fixtures_test.dart`).

## Format actuel (lecture de `lib/store.dart`, version 6.0.1)

Section `logs` de l'état et de la sauvegarde : un objet `clé de séance → SessionLog`.

- Clé : `S<semaine>-J<jour>` pour le programme (semaine 1 à 40, jour 1 à 7) ; `S0-J<id>` (et
  `S0-J<id>@…`) pour une séance manuelle.
- `SessionLog` : `done` (bool), `finishedAt` (horodatage ISO local ou nul), `title`, `customId`,
  `exerciseNames` (identifiant d'exercice du programme → nom affiché), `ex` (identifiant → `ExerciseLog`).
- `ExerciseLog` : `sets` (liste de `SetEntry`), `note` (texte libre), `showKg`, `showRir`, `showV`,
  `prescribed`, `koach`.
- `SetEntry` : `kg`, `reps`, `rir`, `v` (**textes** saisis, virgule décimale possible, vides si non
  saisis), `done`, `completedAt`, `effort` (RIR de 0 à 5 par pas de 0,5, optionnel, Koach L7),
  `excluded` (optionnel).
- Départ du programme : `programStart` (`status`, `date` en jour civil).
- Réponses facultatives par séance : `koach.answers[clé]` = `sleep` (heures), `form` (0 à 10), `pain`
  (mouvement → 0 à 10).

## Règles

| N° | Règle |
| --- | --- |
| C1 | Une séance du programme donne un `SessionRecord` : `id` = `legacy-<clé>`, `origin` = `imported`, `resume` = false, `completed` = `done`, `programRef` = (`legacy-programme-v33`, semaine − 1, jour − 1). |
| C2 | Les séances manuelles (`S0-…`) ne sont **pas converties** : D1.1 les supprime (après la sauvegarde automatique du lot G2). |
| C3 | `date` = jour civil de `finishedAt` (ses 10 premiers caractères) ; à défaut, jour prévu = départ + 7 × (semaine − 1) + (jour − 1) ; sans départ, l'ancrage d'origine du programme (`Program.legacyDateFor`). |
| C4 | Seules les séries `done` sont converties. Une séance sans aucune série convertie est écartée. |
| C5 | Les exercices sont pris dans l'ordre de la journée du programme ; `exerciseOrder` = rang parmi les exercices convertis, `setIndex` = rang parmi les séries faites. |
| C6 | L'exercice est retrouvé par son nom (`exerciseNames`) dans la correspondance noms → identifiants du catalogue (lot G3). Sans correspondance, ses séries sont **écartées et comptées** dans le rapport ; aucun identifiant n'est inventé. |
| C7 | `externalLoadKg` = `kg` lu comme un nombre (virgule ou point) ; absent si le texte est vide ou illisible. |
| C8 | La mesure (`reps` de l'ancien format) va dans `seconds` si l'unité de l'exercice au catalogue est la seconde, sinon dans `reps` ; vide ou illisible : 0. |
| C9 | `flames` = `Flames.fromRir(effort)` ; à défaut `Flames.fromRir(rir)` si `rir` est un nombre ; sinon **absent** (« pas de note »). RIR 0,5 → 9 flammes. |
| C10 | `success` = mesure > 0 ; `excluded` repris ; `kind` = `work` ; pas de cible (`target` absent : l'ancienne prescription est un texte). |
| C11 | Bilan : `form` (0 à 10) → `overall` = plafond(`form` / 2), borné de 1 à 5 ; `sleep` → `sleepHours` ; une réponse absente reste absente. Les douleurs par mouvement (`pain`) ne désignent pas une zone du corps : **non converties**, comptées dans le rapport. |
| C12 | Les séances converties sont triées par date puis par identifiant. Les notes libres ne sont pas reprises. |

La vitesse (`v`), les textes `prescribed` et `koach`, et les préférences d'affichage ne sont pas repris.
Le rapport de conversion compte : séances lues, converties, manuelles écartées, vides écartées ; séries
converties, non faites, d'exercice sans correspondance (avec les noms) ; réponses de douleur écartées.
Rien n'est perdu côté application : la conversion ne supprime pas l'ancien journal (D1.1 mise à part).
