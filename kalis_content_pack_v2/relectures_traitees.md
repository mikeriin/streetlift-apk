# Relectures traitées — pack Kalis Track v2 (L9R)

Lot L9R, 27/09/2026. Étape 1 du prompt : lire toutes les relectures du propriétaire, les classer, indiquer pour chacune la correction appliquée ou la raison argumentée, puis corriger les défauts systémiques sur tout le pack.

## 1. Relectures lues

| Source | Contenu au 27/09/2026 01:30 UTC (relu à 04:40 UTC) |
| --- | --- |
| Artefact https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S, collection `relectures` (outil ArtifactData, `list`, limite 200) | **0 document** |
| Commentaires de l'artefact | aucun |
| Texte joint au lancement | le constat du propriétaire en trois points (repris ci-dessous) ; aucune remarque par exercice |
| Projet claude.ai (documents `LIVRAISON_L9.md`, `prompt_L9R_refonte_pack.txt`) | aucune remarque par exercice |

La collection étant vide, aucune remarque individuelle ne peut être listée ligne à ligne. Le traitement s'est donc fait à partir du constat général, en le vérifiant exercice par exercice contre les sources (étape 2) et contre le rendu (étape 4). Les remarques que le propriétaire déposera dans le nouvel outil (collection `relectures_v2`) seront traitées à la validation de la v2 (étape 6 du prompt).

## 2. Constat du propriétaire (26/09/2026) → défauts systémiques et corrections

### 2.1 « Beaucoup de résultats ne conviennent pas »

Faute de remarques nominatives, le pack v1 a été confronté aux sources publiques archétype par archétype (237 archétypes, 974 URL distinctes, voir `licences.md`). Résultat : **156 archétypes sur 237 portaient au moins une attribution musculaire non confirmée par les sources**. Les erreurs se répartissent en quatre familles, corrigées sur l'ensemble du pack (le détail par archétype est dans `sources/archetypes_sources.json`, champ `v1_erreur`, et dans `validation_register.md` §0) :

| Défaut systémique de la v1 | Archétypes concernés | Correction appliquée partout |
| --- | --- | --- |
| Muscles manquants (ischio-jambiers et mollets des squats, trapèze moyen/inférieur des tirages, dentelé antérieur des poussées, moyen fessier des appuis unipodaux…) | 54 | ajoutés à partir des sources, dans la taxonomie détaillée |
| Stabilisateurs classés « secondaires » (abdominaux des pompes et squats, coiffe des rotateurs des dips aux anneaux, lombaires du rowing…) | 36 | nouveau champ `muscles_stabilisateurs`, distinct des moteurs |
| Muscles « primaires » non confirmés (triceps des pompes standard et des développés, biceps des tirages, deltoïde antérieur des développés inclinés/déclinés, pectoraux de la planche…) | 24 | rétrogradés en secondaires selon l'avis majoritaire ; désaccords conservés dans `sources_meta.desaccord` |
| Groupes trop grossiers (« trapèzes », « avant-bras », « adducteurs », « pectoraux ») | 25 | remplacés par le chef ou le faisceau réellement sollicité (taxonomie de 81 entrées, `muscles.json`) |

Autres corrections de données issues de ce croisement : mode de charge et matériel précisés (ex. « sac lesté » → charge `objet_leste`), unilatéralité du rowing haltère, curl nordique et curl ischio glissé classés en isolation (flexion de genou), good morning avec fessiers moteurs.

### 2.2 « Plusieurs animations sont fausses ; le squelette bâtons n'est pas parlant »

Défauts systémiques identifiés dans les animations v1 et corrigés :

| Défaut de la v1 | Exemples relevés | Correction |
| --- | --- | --- |
| Gabarit d'une autre famille réutilisé | rowing australien dessiné comme une traction ; presse à cuisses comme un développé épaules ; relevés de pointes (tibial) comme des mollets ; kick-back fessiers comme un soulevé unijambe ; ab wheel debout dessiné à genoux ; rows archer / pieds surélevés dessinés comme le rowing de base | gabarits dédiés (`rowing.australien`, `rowing.australien_pieds_hauts`, `rowing.archer`, `assis.leg_press`, `mollets.tibial`, `debout.ab_wheel`…) ; 260 gabarits au total |
| Charge dessinée fausse ou en double | barre pour un rowing haltères, haltère pour une mobilité de poignet sans charge, poulie pour une rotation externe haltère | accessoires de charge substitués par exercice (`accessoires` / `retirer` dans `poses.json`) |
| Mur du mauvais côté | ATR dos au mur et poitrine au mur inversés, HSPU « dos au mur » avec le mur côté visage, wall walk avec le mur derrière la tête | orientation vérifiée numériquement : le personnage debout regarde vers +x ; en ATR la face et les pointes de pied regardent vers −x, les talons vers +x |
| Poses placées à l'œil, contacts approximatifs | pieds flottants, fessiers dans le banc, coude sous le sol | images clés **calculées** par cinématique directe à partir d'une fiche biomécanique (angles de début et de fin de phase) et de contraintes de contact ; 8 contrôles automatiques, 0 défaut sur 260 gabarits |
| Squelette « bâtons » | toutes les démonstrations | silhouette volumétrique (membres en capsules, tronc, mains, pieds, tête) aux proportions de l'atlas ; muscles primaires et secondaires surlignés sur la silhouette et sur l'atlas ; texte toujours présent |
| Gestes impossibles à représenter, pourtant animés | pompes archer, pompe à un bras, clamshell, monster walk, cuban press, manna, 90/90, kipping | statut `indisponible` (18 exercices) : l'application affichera l'atlas et les consignes ; 35 exercices `statique` (position de départ seulement, motif indiqué) |
| Corde à sauter dessinée comme un trait | corde à sauter, double-unders | boucle sagittale passant par les mains |

Contrôle visuel exercice par exercice : les 150 exercices prioritaires (`planches/prioritaires_01..10.png`, liste dans `coverage_report.md` §6) et les 70 exercices ajoutés (`planches/ajouts_l9r_01..03.png`) ont été rendus et regardés ; les défauts trouvés ont été corrigés ou ont conduit au statut `indisponible`.

### 2.3 « Les données doivent s'appuyer sur les bases existantes, sans copier »

- Chaque exercice porte désormais un champ `sources` (URL, date de consultation, type, entrée consultée) ; les muscles sont confirmés par au moins **2 sources concordantes** par archétype (237/237 ; six archétypes n'ont qu'une source directe, complétée par une source de variante proche : décision du propriétaire demandée, `validation_register.md` §0.1).
- Aucun texte n'a été repris : consignes, erreurs fréquentes, respiration, fiches biomécaniques sont rédigées en français par Claude. Aucune base n'a été importée en bloc (au plus quelques dizaines d'entrées consultées par base, réparties sur 237 archétypes).
- Difficultés : quand une source donne un niveau (free-exercise-db, ACE, StrengthLevel), il est conservé dans `sources_meta.difficulte_reference` pour comparaison.

## 3. Remarques attendues et comment elles seront traitées

Le nouvel outil de relecture (même lien) enregistre chaque remarque dans `relectures_v2` avec : exercice, verdict (valider / à corriger), catégorie (données, muscles, difficulté, progression, animation, vocabulaire, autre) et commentaire. À la validation de la v2, ce fichier sera complété d'une ligne par remarque (correction appliquée ou raison), puis l'archive validée sera copiée sous `kalis_content_pack_v1_final.zip` pour déclencher L9b.
