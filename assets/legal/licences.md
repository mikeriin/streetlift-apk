# Sources et licences — contenus de Kalis Track

## 1. Base d'exercices v1.1

Les fiches d'Arsenal › Exercices (1 039 exercices, 8 disciplines : nom, alias, discipline, catégorie, niveau, muscles, points clés, erreurs fréquentes, respiration, matériel, variantes) viennent de la **base d'exercices v1.1.0 du propriétaire de Kalis Track** (28/09/2026), propriété du propriétaire, intégrée telle quelle. Les champs calculés (type de mouvement, difficulté, lieux, paliers conseillés) sont déduits par des règles documentées (paquet `kalis_core`, `docs/RELECTURE_CATALOGUE.md`). Contenu non relu par un professionnel diplômé.

Depuis dev6.19.0 (lot BV11), c'est la seule source d'exercices de l'application. L'ancien pack de contenu v2 (2.0.0, 625 exercices) n'est plus embarqué : les anciens noms et identifiants de l'historique, des sauvegardes et du programme de 40 semaines sont reliés à la base v1.1 par la table de correspondance (`assets/catalog/correspondance.json`), sans réécrire aucune séance.

## 2. Contenus du propriétaire et contenus produits

| Source | Licence | Usage | Obligations |
| --- | --- | --- | --- |
| Base d'exercices v1.1.0 | Propriété du propriétaire de Kalis Track | fiches, recherche, filtres, ajout et remplacement d'exercices | Aucune |
| Base d'exercices de l'application v1 (505 entrées) et pack de contenu v2 (2.0.0) | Propriété du propriétaire ; textes produits par Claude pour le propriétaire | anciens noms gardés dans l'historique ; groupes musculaires historiques de STATS (`assets/catalog/groupes_historiques.json`) | Aucune |
| Programme de 40 semaines v33 | Propriété du propriétaire | programme personnel | Aucune |
| Taxonomie des muscles et carte musculaire 2D (atlas produit avec le pack v2, lot L9R) | Produits par Claude pour le propriétaire, sans licence tierce | carte des muscles, STATS, fiches | Relecture recommandée |
| Proportions segmentaires (Drillis & Contini) et masses segmentaires (Winter) | Connaissances scientifiques générales, valeurs numériques publiques | modèle corporel | Aucune |

## 3. Sources externes consultées pour vérifier les faits (pack v2, 26 et 27/09/2026)

Règle appliquée : **les faits se vérifient, ils ne se copient pas.** Aucun texte n'a été repris d'une source ; aucune base n'a été importée en bloc. Les sources ont servi à confirmer des faits (muscles sollicités, matériel, type de mouvement, niveau indicatif), croisés entre elles.

| Source | Usage | Licence de la source | Position |
| --- | --- | --- | --- |
| free-exercise-db (github.com/yuhonas/free-exercise-db) | muscles, niveau, matériel | Unlicense (domaine public) | vérification de faits ; aucune obligation |
| wger (fixtures publiques du dépôt GitHub `wger-project/wger`) | muscles, catégorie, matériel | CC-BY-SA 4.0 (base d'exercices) | vérification de faits seulement : aucune donnée, aucun texte ni identifiant reproduit |
| Wikipédia (anglais et français) | muscles, nomenclature | CC-BY-SA 4.0 (texte) | faits seulement, aucun texte repris |
| ACE Fitness, StrengthLevel et autres ressources d'entraîneurs en consultation publique | groupes musculaires, matériel, niveau, ordres de grandeur | Tous droits réservés (consultation publique) | faits seulement |

Le détail des sources de l'ancien pack (URL par exercice, décision D-L9R-06) est archivé dans le dépôt (`tools/archives/pack_2.0.0/`).
