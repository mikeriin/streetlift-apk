# Intégrer kalis_core dans l'application (piste A)

Pour les lots G3, G7, G9, G12. Le paquet se récupère **par étiquette** :

```sh
git fetch origin --tags
git checkout kalis_core-v0.1.0 -- packages/kalis_core
```

puis, dans `pubspec.yaml` de l'application : `kalis_core: { path: packages/kalis_core }`. Le paquet n'a
aucune dépendance hors tests. Ne récupère pas `tools/catalog/` sauf si le prompt du lot le demande (il
ne sert qu'à recompiler le catalogue).

## 1. Charger le catalogue

Déclare l'asset `packages/kalis_core/data/catalog_v1.json.gz` (ou copie-le dans `assets/`), puis :

```dart
import 'dart:io' show gzip;
import 'package:kalis_core/kalis_core.dart';

final data = await rootBundle.load('packages/kalis_core/data/catalog_v1.json.gz');
final catalog = Catalog.fromJsonBytes(gzip.decode(data.buffer.asUint8List()));
```

`dart:io` reste dans l'application : le paquet reçoit des octets **décompressés**. Charge-le une fois
(≤ 150 ms en VM ; hors du fil d'interface si le téléphone est plus lent) et garde l'instance : elle
est non modifiable. Textes des fiches : `name`, `aliases`, `keyPoints`, `commonMistakes`, `breathing`,
muscles et matériel (libellés de la base). `byLabel` retrouve un exercice par nom ou alias pour la
correspondance anciens noms → identifiants (D4.10).

## 2. Profil

`AthleteProfile` (schéma 2) se stocke tel quel : `jsonEncode(profile.toJson())` dans une **section
versionnée et optionnelle** de la sauvegarde ; relecture par `AthleteProfile.fromJson`. Avant
d'enregistrer : `profile.validate()` et `catalog.checkProfile(profile)` doivent être vides. Modifie par
`copyWith` (un champ optionnel se remet à `null` en passant `null`). Mode street : construis
`StreetMode`, puis `disciplines: streetMode.toDisciplineMix()`.

## 3. Journal

- Écris une `SessionRecord` par séance ; `flames` absent = « pas de note » ; chaque réponse du bilan
  santé non donnée reste absente ; `resume: true` pour les séances marquées « reprise » (D4.9).
- Dates : `CivilDate` (jour civil de l'horloge de l'application, voyage dans le temps du mode dev
  compris) — les moteurs ne lisent jamais l'horloge.
- Ancien journal : `docs/CONVERSION_JOURNAL.md` (règles C1 à C12, exemple avant / après dans
  `test/fixtures/legacy_journal.json`). Reprends cet exemple comme test de ta conversion.

## 4. Moteurs

Chaque moteur est une classe qui réalise une interface de `kalis_core` :

```dart
final PlanEngine plan = KalisPlan();        // kalis_plan (G4)
final request = PlanRequest(profile: p, seed: 0, startDate: today, locks: const []);
final pass1 = plan.createPass1(catalog, request);
final after = plan.review(catalog, ReviewRequest(request: request, current: pass1, action: action));
final pass2 = plan.createPass2(catalog, Pass2Request(request: request, pass1: after.plan));
```

- Tout ce qui vient d'un moteur se stocke par `toJson()` et se relit par `fromJson()`.
- `AdaptInput.state` (rendu par `AdaptReview.state`) et `QuestState` sont à stocker et à repasser tels
  quels ; l'application ne les interprète pas.
- Après une revue, reporte `ReviewResult.profileDelta` dans le profil (`knownExerciseIds`,
  `cannotDoExerciseIds`, aimés, détestés) et repasse `ReviewResult.locks` dans la requête suivante.
- Chaque suite donnée à une proposition (appliquée, acceptée, refusée, annulée) s'ajoute à
  `AdaptInput.decisions`.
- Programme du propriétaire (D5.10) : présente-le au moteur dynamique comme un `ProgramBlock` importé
  de 40 semaines (CONTRAT.md §6) ; aucun moteur ne le régénère.
- Les raisons (`Reason`) se rendent en phrases par `kalis_koach` : code → modèle de phrase, paramètres
  → valeurs. Un code inconnu de l'application s'affiche avec un texte générique (ne plante jamais).
- Test de contrat à écrire dans l'application pour chaque intégration : sérialise la requête et la
  réponse, relis-les, vérifie l'égalité et `validate()` vide.

## 5. Tests

`package:kalis_core/testing.dart` donne les profils types et les journaux
(`readProfileFixtures`, `readJournalFixtures` sur `packages/kalis_core/test/fixtures/`) : sers-t'en
pour les tests d'intégration et le simulateur du mode dev.

## 6. Profil v3 et parcours de création (0.4.0, lot CU)

Récupère le paquet : `git fetch origin 'refs/heads/etiquettes/*:refs/remotes/origin/etiquettes/*'` puis
`git checkout origin/etiquettes/kalis_core-v0.4.0 -- packages/kalis_core`. `kalis_plan` 0.1.0, `kalis_adapt`
0.1.0 et `kalis_quest` 0.1.0 fonctionnent sans changement avec 0.4.0 (aucune valeur d'enum ajoutée aux
énumérations existantes : aucun `switch` de l'application n'est à compléter).

- **Tout est dans [`docs/PARCOURS_V3.md`](docs/PARCOURS_V3.md)** : écrans, ordre, textes, réponses,
  validations, conditions d'apparition, tests guidés, utilisateurs existants.
- **Parcours** : déclare l'asset `packages/kalis_core/data/parcours_v3.json`, puis
  `final parcours = ProfileQuestionnaire.fromJson(jsonDecode(texte) as Map<String, Object?>);`. Après
  chaque réponse : `parcours.visibleQuestions(brouillonJson, todayYear: annee)` rend les questions à
  montrer, dans l'ordre (`since: 3` pour « Compléter mon profil »). Le brouillon est le JSON du profil en
  cours de saisie (il peut être incomplet). L'application ne code aucune condition.
- **Écrire une réponse** : par `copyWith` sur le profil (les champs du schéma 3 sont optionnels) ;
  « Passer » et « Je ne sais pas » laissent le champ absent ; « aucun autre sport » s'écrit
  `otherSports: const []` ; « aucune échéance », `events: const []`.
- **Utilisateurs existants** : `profile.toSchema3()` (seul `schemaVersion` change). Le programme en
  cours n'est pas régénéré ; le programme importé du propriétaire ne l'est jamais (D5.10).
- **Avant d'enregistrer** : `profile.validate()` et `catalog.checkProfile(profile)` vides.
- **Figures** : `catalog.progressionCandidates(figureId)` donne les étapes à proposer pour « Où en
  es-tu ? ».
- **Tests guidés** : `parcours.eligibleTests(profilJson, todayYear: annee)` ; un résultat s'écrit comme
  un `Benchmark` (`source: BenchmarkSource.guidedTest`, `protocolId`) ajouté à `profile.benchmarks`.
  Conversions : `estimateOneRm(loadKg: chargeTotale, reps: r, rir: reserve)` puis
  `externalFromTotal(...)` pour un exercice lesté (la fraction du poids du corps est
  `CatalogExercise.bodyweightFraction`) ; `riegelSeconds(...)`, `trialSpeed(...)` pour la course.
  Affiche toujours la fourchette (`lowKg` à `highKg`), pas une valeur seule.
- **Tests à écrire dans l'application** : nombre de questions vues pour chaque profil de
  `test/fixtures/profiles_v3.json` (`expected.questionIds`), chaque condition d'apparition, migration du
  schéma 2 vers le schéma 3, aller-retour de sauvegarde, création d'un programme avec les moteurs actuels
  pour chaque profil type.
- **Textes de Koach des nouveaux codes de raison** : `docs/RAISONS_0_4.md` (utiles au lot CI ; les
  moteurs 0.1 ne les émettent pas).
