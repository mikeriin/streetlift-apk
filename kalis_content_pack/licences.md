# Sources et licences — pack de contenu Kalis Track v1 (KT-049)

Date de consultation : 26/09/2026.

| Source | Licence | Champs concernés | Obligations |
| --- | --- | --- | --- |
| Base d'exercices de l'application v1 (`assets/exercises_db.json.gz`, 505 entrées) | Propriété du propriétaire de Kalis Track | `nom` des 505 exercices d'origine, bloc `v1` | Aucune |
| Programme de 40 semaines v33 (`assets/programme_v33.json.gz`) | Propriété du propriétaire | intitulés et occurrences dans `mapping_v1_to_v2.json` | Aucune |
| Contenu généré par Claude pour le lot L9 (provenance `genere_l9`) | Produit pour le propriétaire, sans licence tierce | tout le reste : types, muscles, difficultés, contraintes, précautions, consignes, arbres, seuils, gabarits de pose, exercices ajoutés | Marqué comme généré ; relecture recommandée (voir `validation_register.md`) |
| Valeurs calculées (provenance `calcule`) | Dérivées des lignes ci-dessus | lieux, substitutions, prérequis, progressions, régressions | Aucune |
| Proportions segmentaires et masses (anthropométrie de Winter) | Connaissances scientifiques générales, aucune donnée copiée | longueurs et masses du squelette | Aucune |
| Palette des 6 couleurs dominantes | Code de l'application (`lib/app_theme.dart`, lot L5-C) | rôles de couleur du moteur de rendu | Aucune |

## Sources externes

Aucune donnée externe n'a été importée. Le propriétaire autorisait des sources sous licence, mais la licence de chaque source doit être vérifiée à la source et datée ; l'environnement d'exécution de ce lot ne permettait pas de consulter les sites des bases d'exercices ouvertes. Conformément à la règle « sans vérification possible, n'importe pas la donnée », rien n'a été repris.

Pour une passe ultérieure, les critères restent :
- domaine public, CC0 ou Unlicense : utilisables sans obligation ;
- CC-BY : utilisable avec un écran de mentions dans l'application ;
- CC-BY-SA : **ne pas utiliser sans décision du propriétaire** (partage à l'identique de la base dérivée).

Aucun écran de mentions n'est donc nécessaire pour ce pack.
