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
0.1.0 et `kalis_quest` 0.1.0 n'ont pas à changer avec 0.4.0 (aucune valeur d'enum ajoutée aux
énumérations d'avant 0.4.0 : aucun `switch` existant de l'application n'est à compléter).

- **Énumérations de 0.4.0 : toujours un cas par défaut.** Elles sont ouvertes (CONTRAT.md § 1) : une
  version mineure pourra leur ajouter des valeurs. Un `switch` sur `SetTechniqueKind`, `SeasonPhaseKind`,
  `GroupFormat`… porte donc un `default` (ou un `_ =>`).
- **Nom à connaître** : la phase de saison s'appelle `SeasonPhaseKind`, pas `PhaseKind` (l'application a
  déjà un `PhaseKind`).
- **Tout est dans [`docs/PARCOURS_V3.md`](docs/PARCOURS_V3.md)** : écrans, ordre, textes, réponses,
  validations, conditions d'apparition, questions reportées, tests guidés, utilisateurs existants.
- **Parcours** : déclare l'asset `packages/kalis_core/data/parcours_v3.json`, puis lis-le une fois. Le
  brouillon est le JSON du profil en cours de saisie (il peut être incomplet). L'application ne code
  aucune condition : elle redemande la liste après chaque réponse.

  ```dart
  final parcours = ProfileQuestionnaire.fromJson(jsonDecode(texte) as Map<String, Object?>);

  // Création du profil : les questions reportées ne sont pas rendues.
  final List<ProfileQuestion> aPoser = parcours.visibleQuestions(brouillonJson, todayYear: annee);

  // Réponse obligatoire pour ce profil ? (`required`, ou `requiredWhen` vraie :
  // le poids de corps pour les disciplines au poids du corps).
  final bool obligatoire = parcours.isRequired(aPoser.first, brouillonJson, todayYear: annee);
  ```

- **Questions reportées** : une question dont la condition `deferWhen` est vraie n'est pas posée à la
  création ; propose-la après la première semaine (carte discrète de Koach, une fois). Un débutant ne
  voit ainsi aucune question du schéma 3 à la création.

  ```dart
  final Map<String, Object?> profilJson = profile.toJson();

  // Après la première semaine : les questions reportées pour ce profil.
  final List<ProfileQuestion> reportees = parcours.deferredQuestions(profilJson, todayYear: annee);

  // « Compléter mon profil » d'un utilisateur existant : les questions du schéma 3, reportées comprises.
  final List<ProfileQuestion> aCompleter =
      parcours.visibleQuestions(profilJson, todayYear: annee, since: 3, includeDeferred: true);

  // Réglages › Profil : tout le parcours visible, reportées comprises.
  final List<ProfileQuestion> toutes =
      parcours.visibleQuestions(profilJson, todayYear: annee, includeDeferred: true);

  // Une question donnée est-elle reportée pour ce profil ?
  final bool plusTard = parcours.isDeferred(toutes.first, profilJson, todayYear: annee);
  ```

  `visibleQuestions` prend `since` (2 par défaut : tout le parcours ; 3 : les seules questions du
  schéma 3) et `includeDeferred` (`false` par défaut). `deferredQuestions` ne prend que le profil et
  `todayYear`.
- **Écrire une réponse** : par `copyWith` sur le profil (les champs du schéma 3 sont optionnels) ;
  « Passer » et « Je ne sais pas » laissent le champ absent. « Aucun autre sport » et « aucune échéance »
  s'écrivent par une **liste constante typée** :

  ```dart
  profile = profile.copyWith(otherSports: const <OtherSport>[]);
  profile = profile.copyWith(events: const <SeasonEvent>[]);
  ```

  Un `const []` non typé est une `List<dynamic>` : `copyWith` le transtype en `List<OtherSport>?` et
  lève une erreur de transtypage à l'exécution. La règle vaut pour toute liste passée à `copyWith`
  (`const <Benchmark>[]`, `const <SkillState>[]`…).
- **Utilisateurs existants** : `profile.toSchema3()` (seul `schemaVersion` change). Le programme en
  cours n'est pas régénéré ; le programme importé du propriétaire ne l'est jamais (D5.10).
- **Ne migrer qu'après la mise à jour** : une application restée en `kalis_core` 0.3.0 **refuse un
  profil au schéma 3** (`validate()` rend une violation sur `schemaVersion`). Ne passe un profil au
  schéma 3 qu'une fois l'application livrée avec `kalis_core` 0.4.0 ; une sauvegarde au schéma 3 ne se
  relit pas sur une version antérieure. Attention : `AthleteProfile()` construit sans `schemaVersion`
  écrit déjà le schéma 3.
- **Avant d'enregistrer** : `profile.validate()` et `catalog.checkProfile(profile)` vides.
- **Figures** : `catalog.progressionCandidates(figureId)` donne les étapes à proposer pour « Où en
  es-tu ? ». Ce n'est qu'une aide à la saisie : l'étape choisie n'est pas contrôlée par le catalogue.
- **Tests guidés** : `parcours.eligibleTests(profilJson, todayYear: annee)` (10 protocoles, `t1` à `t10` ;
  un débutant n'a que `t8_sans_test`) ; un résultat s'écrit comme un `Benchmark`
  (`source: BenchmarkSource.guidedTest`, `protocolId`) ajouté à `profile.benchmarks`. Plusieurs records
  peuvent porter sur le même exercice.
  Conversions : `estimateOneRm(loadKg: chargeTotale, reps: r, rir: reserve)` puis
  `externalFromTotal(...)` pour un exercice lesté (la fraction du poids du corps est
  `CatalogExercise.bodyweightFraction`) ; `riegelSeconds(...)`, `trialSpeed(...)` pour la course.
  `estimateOneRm` et `riegelSeconds` rendent `null` hors de leur domaine. Affiche toujours la fourchette
  (`lowKg` à `highKg`), pas une valeur seule.
- **Journal** : une série reste une `SetRecord`, même découpée ; les mini-séries et les paliers vont dans
  `SetRecord.parts` (CONTRAT.md § 12). Les moteurs 0.1 n'émettent aucune technique avancée.
- **Tests à écrire dans l'application** : nombre de questions vues pour chaque profil de
  `test/fixtures/profiles_v3.json` (`expected.questionIds` à la création, `expected.deferredIds` pour les
  questions reportées, `expected.testIds` pour les tests guidés), chaque condition d'apparition,
  migration du schéma 2 vers le schéma 3, aller-retour de sauvegarde, création d'un programme avec les
  moteurs actuels pour chaque profil type.
- **Textes de Koach des nouveaux codes de raison** : `docs/RAISONS_0_4.md` (38 textes, utiles au lot CI ;
  les moteurs 0.1 ne les émettent pas).
