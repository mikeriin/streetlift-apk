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
final pass1 = plan.createPass1(catalog, PlanRequest(profile: p, seed: 0, startDate: today, locks: const []));
```

- Tout ce qui vient d'un moteur se stocke par `toJson()` et se relit par `fromJson()`.
- `AdaptInput.state` (rendu par `AdaptReview.state`) et `QuestState` sont à stocker et à repasser tels
  quels ; l'application ne les interprète pas.
- Les raisons (`Reason`) se rendent en phrases par `kalis_koach` : code → modèle de phrase, paramètres
  → valeurs. Un code inconnu de l'application s'affiche avec un texte générique (ne plante jamais).
- Test de contrat à écrire dans l'application pour chaque intégration : sérialise la requête et la
  réponse, relis-les, vérifie l'égalité et `validate()` vide.

## 5. Tests

`package:kalis_core/testing.dart` donne les profils types et les journaux
(`readProfileFixtures`, `readJournalFixtures` sur `packages/kalis_core/test/fixtures/`) : sers-t'en
pour les tests d'intégration et le simulateur du mode dev.
