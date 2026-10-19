# tools/catalog — compilation du catalogue de kalis_core

- `compile_catalog.py` : base v1.1.0 (`packages/kalis_core/data/source/`) → `data/catalog_v1.json.gz`,
  `docs/RELECTURE_CATALOGUE.md`, `docs/relecture_catalogue.csv` ; `--check` vérifie qu'ils sont à jour.
- `rules.py` : les règles des champs calculés (une table ou une règle par champ ; justification dans
  `packages/kalis_core/CONTRAT.md` §2). Modifier une règle : changer `RULES_VERSION`, recompiler,
  relire la relecture, ajuster les cas types de `tests/test_catalog.py`.
- `tests/` : schéma de la base, règles, cas types, reproductibilité, fichiers générés à jour (catalogue,
  types du contrat, jeux de données).

Python 3.11, bibliothèque standard seulement (pytest pour les tests).
