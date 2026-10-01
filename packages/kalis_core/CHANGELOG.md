# Journal des versions de kalis_core

## 0.1.0 — 01/10/2026 (lot GC)

Première livraison : les contrats sont figés ; les évolutions suivantes sont additives.

- Catalogue : base d'exercices v1.1.0 (1 039 exercices) compilée avec ses champs calculés par règles
  (schéma de mouvement, famille, plan, articularité, régime, difficulté, lieux, contraintes
  articulaires, prérequis, coûts de fatigue, type de charge, fraction du poids du corps, unité,
  latéralité, vecteur musculaire) ; `Catalog` : chargement, index, graphe `variante_de`, proximité.
- Contrats : profil d'athlète v2, journal de séances, échelle des flammes, types d'échange et
  interfaces de `plan`, `adapt`, `quest` (73 types, 54 enums), registre de 67 codes de raison ; chaque
  méthode de moteur prend une requête versionnée.
- Jeux de données communs : 40 profils types, 12 journaux synthétiques, programme du propriétaire
  normalisé, ancien journal et sa conversion.
- Simulateur `bin/kalis_core_cli.dart --rapport <dossier>`.
