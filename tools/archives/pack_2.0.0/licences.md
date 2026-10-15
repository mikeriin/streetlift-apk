# Sources et licences — pack de contenu Kalis Track v2 (L9R)

## 0. Base d'exercices v1.1 (depuis dev6.2.0, lot G3)

Les fiches d'Arsenal › Exercices (1 039 exercices, 8 disciplines : nom, alias, discipline, catégorie, niveau, muscles, points clés, erreurs fréquentes, respiration, matériel) viennent de la **base d'exercices v1.1.0 du propriétaire de Kalis Track** (28/09/2026), propriété du propriétaire, intégrée telle quelle. Les champs calculés (type de mouvement, difficulté, lieux, paliers conseillés) sont déduits par des règles documentées (paquet `kalis_core`, `docs/RELECTURE_CATALOGUE.md`). Contenu non relu par un professionnel diplômé. Le pack de contenu v2 décrit ci-dessous reste la source des démonstrations 2D et des données internes des anciens moteurs de programme.

Dates de consultation : 26 et 27/09/2026. Règle appliquée (prompt L9R) : **les faits se vérifient, ils ne se copient pas.** Aucun texte n'a été repris d'une source ; toutes les consignes, erreurs fréquentes, respirations, fiches biomécaniques et notes sont rédigées en français par Claude. Aucune base n'a été importée en bloc ni copiée dans le pack : chaque source a servi à confirmer des faits (muscles sollicités, matériel, type de mouvement, niveau indicatif, angles articulaires de référence), croisés entre elles. Les URL consultées sont listées par archétype dans `sources/archetypes_sources.json` et reprises dans le champ `sources` de chaque exercice ; les références cinématiques sont dans `sources/cinematique_references.json`.

## 1. Contenus du propriétaire et contenus produits

| Source | Licence | Champs concernés | Obligations |
| --- | --- | --- | --- |
| Base d'exercices de l'application v1 (`assets/exercises_db.json.gz`, 505 entrées) | Propriété du propriétaire de Kalis Track | `nom` des 505 exercices d'origine, bloc `v1`, `mapping_v1_to_v2.json` | Aucune |
| Programme de 40 semaines v33 (`assets/programme_v33.json.gz`) | Propriété du propriétaire | intitulés et occurrences dans `mapping_v1_to_v2.json` | Aucune |
| Palettes de l'application (`lib/app_theme.dart`, lot L5-C) et carte musculaire actuelle (`lib/muscle_body.dart`, 11 groupes) | Code du propriétaire | rôles de couleur du moteur de rendu ; champ `groupe` de la taxonomie | Aucune |
| Textes, taxonomie, atlas SVG, fiches biomécaniques, gabarits de pose, exercices ajoutés, scripts (provenance `genere_l9r`) | Produits par Claude pour le propriétaire, sans licence tierce | tout le reste | Marqués comme générés ; relecture recommandée (`validation_register.md`) |
| Valeurs calculées (provenance `calcule`) | Dérivées des lignes ci-dessus | lieux, substitutions, prérequis, progressions, régressions, positions des articulations | Aucune |
| Proportions segmentaires (Drillis & Contini) et masses segmentaires (Winter) | Connaissances scientifiques générales, valeurs numériques publiques | longueurs et masses du modèle corporel | Aucune |

## 2. Sources externes consultées pour vérifier les faits

Nombre d'entrées consultées par source (URL distinctes), usage et licence telle qu'affichée par la source à la date de consultation. Le pack ne contient **aucun extrait** de ces sources : ni texte, ni identifiant, ni structure de données.

| Source | Entrées consultées | Usage | Licence de la source | Position du pack |
| --- | --- | --- | --- | --- |
| free-exercise-db (github.com/yuhonas/free-exercise-db, fichiers JSON lus via raw.githubusercontent.com) | 303 | muscles primaires/secondaires, niveau, matériel, mécanique | Unlicense (domaine public) | vérification de faits ; aucune obligation |
| wger (fixtures publiques du dépôt GitHub `wger-project/wger`, lues localement ; les URL `wger.de/en/exercise/<id>/view` sont citées comme localisation de l'entrée, le site lui-même n'a pas été lu) | 319 | muscles primaires/secondaires, catégorie, matériel | CC-BY-SA 4.0 (base d'exercices) | **vérification de faits seulement** : aucune donnée, aucun texte ni identifiant wger n'est reproduit ; les listes de muscles du pack sont l'avis majoritaire de sources indépendantes. Voir la décision D-L9R-06 ci-dessous. |
| Wikipédia (en.wikipedia.org 65 articles, fr.wikipedia.org 12) | 77 | muscles, description du geste, nomenclature latine | CC-BY-SA 4.0 (texte) | faits seulement, aucun texte repris |
| ACE Fitness, bibliothèque d'exercices (acefitness.org) | 50 | groupes musculaires, matériel, niveau | Tous droits réservés (consultation publique) | faits seulement |
| StrengthLevel (strengthlevel.com) | 60 | standards de force indicatifs (niveau de référence) | Tous droits réservés (consultation publique) | un ordre de grandeur cité en note, pas de table reprise |
| Calixpert, StrengthLog, MuscleWiki, FitnessVolt, Muscle & Strength, dieringe, Kovo Fitness, gymless, GMB, musclesworked, Nike Training, Breaking Muscle, FitCraft, Bret Contreras, BarBend, Hevy, Bodybuilding-Wizard, NASM, PureGym, Healthline, The Movement Athlete, GorNation, Fitbod, calisthenics.com, Hinge Health, Cleveland Clinic, Garage Gym Reviews, RehabHero, Concept2, Peloton, Set for Set, Lift Manual, 1pixelworkout, FitMetrics (et quelques autres, ≤ 3 entrées chacune) | 1 à 23 chacune | muscles pour les figures de street workout et les variantes absentes des bases, angles et consignes de référence | Tous droits réservés (consultation publique) | faits seulement |
| Références cinématiques (angles articulaires) : articles et synthèses publics listés dans `sources/cinematique_references.json` | 47 entrées (patterns, amplitudes, proportions) | angles de début/fin de phase des fiches biomécaniques | variées | valeurs numériques citées comme références, aucun texte |

Sources **non consultées** malgré la liste du prompt : ExRx.net et le site wger.de (robots.txt interdit la lecture automatisée) ; les données wger ont été lues depuis les fixtures du dépôt GitHub public. MuscleWiki n'a été lisible que partiellement (pages sans liste de muscles pour plusieurs exercices).

## 3. Décision D-L9R-06 — exposition à la licence CC-BY-SA de wger

wger représente 319 des 974 URL consultées. Le pack ne reproduit rien de wger ; il s'en est servi comme d'un avis parmi d'autres pour confirmer des faits anatomiques, ce qui ne crée pas d'œuvre dérivée au sens du droit d'auteur. Le droit *sui generis* des producteurs de bases de données (Europe) vise l'extraction ou la réutilisation d'une partie substantielle : ici les données ne sont pas extraites dans le pack, mais la consultation a porté sur une partie notable de la base. Par prudence :

- **Option A (par défaut)** : conserver les références wger dans `sources` (traçabilité), aucun écran de mentions nécessaire puisque rien n'est reproduit.
- **Option B (exposition nulle)** : retirer les références wger du pack. 225 archétypes sur 237 conservent au moins deux autres sources concordantes ; 12 devraient être complétés par une source supplémentaire : pompe_mur, pompe_pseudo, pompe_archer, traction_archer, wall_sit, clamshell, woodchop, foam, jumping_jacks, genoux_hauts, ergo_ski, wall_ball.

Le propriétaire tranche à la relecture ; l'option A est appliquée en attendant. Aucun écran de mentions n'est requis dans l'application pour ce pack.
