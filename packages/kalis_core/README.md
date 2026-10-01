# kalis_core

Contrats et modèles partagés des moteurs de Kalis Track (pipeline « Génération et progression », lot
GC, piste « moteurs »). Dart pur : aucun Flutter, aucun stockage, aucune horloge, aucun hasard.

| Contenu | Où |
| --- | --- |
| Catalogue compilé depuis la base d'exercices v1.1 (1 039 exercices + champs calculés par règles) | `data/catalog_v1.json.gz`, `Catalog` |
| Profil d'athlète v2, journal de séances, échelle des flammes | `AthleteProfile`, `TrainingLog`, `Flames` |
| Interfaces et types d'échange des moteurs | `PlanEngine`, `AdaptEngine`, `QuestEngine` |
| Registre des codes de raison | `reasonRegistry`, `ReasonCodes` |
| Jeux de données communs, valeurs aléatoires seedées | `test/fixtures/`, `package:kalis_core/testing.dart` |

Documents : [`CONTRAT.md`](CONTRAT.md) (règles, invariants, justifications, références),
[`docs/TYPES.md`](docs/TYPES.md) (tous les types, champ par champ),
[`INTEGRATION.md`](INTEGRATION.md) (pour l'application),
[`docs/RELECTURE_CATALOGUE.md`](docs/RELECTURE_CATALOGUE.md) (relecture du catalogue par le propriétaire),
[`docs/CONVERSION_JOURNAL.md`](docs/CONVERSION_JOURNAL.md), [`CHANGELOG.md`](CHANGELOG.md).

## Commandes

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart run bin/kalis_core_cli.dart --rapport <dossier>   # kalis_core_rapport.json et .txt
```

Outils (Python 3.11, depuis la racine du dépôt) :

```sh
python3 tools/catalog/compile_catalog.py            # recompile le catalogue et la relecture
python3 packages/kalis_core/tool/gen_contracts.py   # régénère les types depuis tool/contracts_spec.py
python3 packages/kalis_core/tool/gen_fixtures.py    # régénère les jeux de données
python3 -m pytest -q tools/catalog/tests            # outils + fichiers générés à jour
```

Les fichiers `*.g.dart` sont générés puis passés par `dart format` ; `--check` compare sans tenir
compte du formatage. Après GC, toute évolution est **additive** (CONTRAT.md §1).
