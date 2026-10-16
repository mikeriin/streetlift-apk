# Contrat L9b — intégration du pack de contenu (3.2.0)

Lot exécuté par le pipeline automatisé (27/09/2026), sans échange en direct. Tickets : KT-079 (base d'exercices v2), KT-080 (démonstrations animées et atlas), KT-082 (Arsenal, recherche et fiches). KT-081 (illustrations de scène) reste **réservé** : reporté par le propriétaire, rien n'est ajouté.

## 1. Entrées et contradictions relevées

| Élément | Valeur |
| --- | --- |
| Base | `streetlift_tracker_v33.zip` 3.1.0+65 (L8), `main` `620752e`, SHA-256 `517f28af939476851125af74a479f046de7a3bd4e9d7e047ab4d60d3361be5c0`, racine unique `streetlift_tracker/` |
| Pack | `kalis_content_pack_v1_final.zip` de la branche `content-pack` (`93fad2e`), SHA-256 `5a13a91e3171c303391e00123c24f5cb8e2577e775e4f4be60622351108f9086`, dossier `kalis_content_pack_v2/`, pack **2.0.0**, schéma exercice 2.1.0, moteur `kt_pose.js` 2.0.0 ; validé par le propriétaire le 27/09/2026 (`pipeline/DECISIONS_EN_ATTENTE.md`) |

Contradictions (aucune ne change le résultat, aucune n'est bloquante) :
1. Le prompt nomme `kalis_content_pack_v1.zip` (L9) ; l'enchaînement du pipeline livre `kalis_content_pack_v1_final.zip`, copie validée du pack v2 (L9R). C'est ce dernier qui est intégré, avec son empreinte enregistrée dans `assets/content/pack.json`.
2. « Atlas d'environ 90 muscles » : le pack en compte 81 (51 dessinés, 30 profonds en texte) ; décision D-L9R-02 acceptée par le propriétaire.
3. `licences.md` du pack indique qu'aucun écran de mentions n'est requis ; le prompt L9b en demande un : l'écran est ajouté (Réglages → À propos → Sources et licences). Les deux sont compatibles.
4. Le contrat du pack rattache le sterno-cléido-mastoïdien au groupe `gainage`, mais `muscles.json` porte `dos` : la carte de STATS suit le fichier (`groupe`), seule source lue par l'application.

## 2. Règles et formats

### Base d'exercices (KT-079)
- `tools/content_pack_import.py <pack> --zip <archive>` produit, de façon reproductible (gzip sans horodatage) : `assets/content/index.json.gz` (index léger chargé au démarrage : identifiant, nom v2, nom historique `n`, `g`, `eq`, type, lieux, matériel, difficulté, statut de démonstration, groupes et muscles, correspondances `base_v1` et `programme_v33`), `details.json.gz` (fiches), `sources.json.gz`, `poses.json.gz` (gabarits sans les positions calculées), `progressions.json.gz`, `licences.md`, `pack.json` (version, empreinte), `lib/atlas_data.dart` (atlas et taxonomie) et les fixtures `test/fixtures/l9b/`.
- `assets/exercises_db.json.gz` est retiré de l'application ; il est conservé comme fixture de test (`test/fixtures/l9b/exercises_db_v1.json.gz`).
- **Aucune donnée utilisateur n'est réécrite.** Les 505 exercices d'origine gardent exactement leur nom, leurs groupes et leur matériel v1 (`n`, `g`, `eq`), qui restent les clés des séances, de l'historique, des records et de STATS. Les 120 ajouts suivent (`g` = groupes des muscles primaires, `eq` = libellé v1 du premier matériel significatif). La base passe de 505 à 625 entrées.
- Résolution nom → identifiant v2 (`AppStore.exerciseIdFor`, `ContentIndex.idFor`), dans l'ordre : correspondance v1 (identifiant **canonique** pour les 22 doublons signalés), intitulé du programme v33 (79 intitulés, 1 812 lignes), nom ou alias v2 ; `null` pour un exercice personnel.

### Démonstrations et atlas (KT-080)
- `lib/pose_engine.dart` : portage exact de `kt_pose.js` 2.0.0 — cinématique directe, `v = (1 − cos πu)/2`, interpolation linéaire sans repli modulo 360, ancrage partagé ou bassin interpolé, chronologie `hold` puis `dur`, boucles `aller-retour` et `cycle`, cadre commun (`bbox`), formes du corps, zones musculaires (`MUSCLE_ZONE`, `FACE_FRONT`).
- `lib/pose_painter.dart` : `CustomPainter` reproduisant le dessin (sol, accessoires arrière, corps, zones primaires 1 / secondaires 0,45, membres éloignés × 0,6, zones dorsales en contour de face, accessoires avant). Rôles : `PoseRoles.of(palette, mode)` = `roles()` du moteur (accent = `KPalette.accent`, corps #8A8A8A, membres éloignés #5E5E5E / #B4B4B4, accessoires et sol #F4F4F4 / #121212).
- Statuts : `disponible` → animation ; `statique` → position de départ seule, avec le motif ; `indisponible` → atlas et consignes, sans animation.
- Réduction des animations (`MediaQuery.disableAnimations`) → images clés fixes côte à côte, numérotées et légendées. Bouton pause / reprise. Description vocale : exercice, état, étapes.
- Atlas (`lib/atlas.dart`, données générées `lib/atlas_data.dart`) : fiche exercice (primaires en accent plein, secondaires 0,42, stabilisateurs en contour pointillé, étirés en contour) avec légende et liste des muscles en texte. **Carte de STATS** (`lib/muscle_body.dart`) : même API (`MuscleHeatmap`, `MuscleLegend`, `heat`), même agrégation par les 11 groupes, même rampe d'intensité ; chaque région est colorée selon le `groupe` de son muscle. Les 18 calques PNG sont retirés.

### Mentions
Écran « Sources et licences » : rendu du fichier `licences.md` du pack (titres, paragraphes, listes ; tableaux en cartes « colonne : valeur » lisibles à 320 px).

### Arsenal, recherche et fiches (KT-082)
- Arsenal → **Exercices** : recherche plein texte (nom historique, nom v2, alias, groupes, matériel, lieux, type, muscles) et filtres type de mouvement, lieu, matériel, difficulté (1-3, 4-6, 7-10). Les doublons v1 ne sont pas listés (l'exercice canonique l'est).
- Fiche : démonstration, points clés, erreurs fréquentes, respiration, muscles (atlas + texte), précautions, matériel et lieux, prérequis (avec seuil), régressions, progressions et « variante de » **navigables**, sources consultées (texte, sans lien réseau), rappel « repères d'entraînement ».
- Création de séance personnelle : le sélecteur utilise la base v2 (625 exercices) et sa recherche porte sur les nouveaux champs ; bouton « Fiche de l'exercice ». Les séances existantes restent intactes.

## 3. Migration

Aucune migration de schéma : le format de sauvegarde et les clés enregistrées sont inchangés (nom historique). Le rattachement à la base v2 se fait à la lecture. Conséquences : aucune remise à zéro possible, retour arrière vers 3.1.0 sans perte (les noms v1 restent valides ; un exercice ajouté en 3.2.0 et utilisé dans une séance personnelle y apparaîtrait comme un nom sans groupe connu).

## 4. Décisions prises par défaut (réversibles)

| Réf. | Décision |
| --- | --- |
| D-L9b-01 | Clés historiques conservées (aucune réécriture des données) ; identifiant v2 résolu à la lecture. |
| D-L9b-02 | Assets dérivés compacts : index chargé au démarrage (≈ 40 ko), fiches, sources, poses et arbres chargés à l'ouverture d'une fiche. |
| D-L9b-03 | Atlas embarqué en code Dart généré plutôt qu'en SVG : aucune dépendance ajoutée (le verrou `pubspec.lock` ne peut pas être régénéré sans accès à pub.dev) et dessin synchrone. |
| D-L9b-04 | Les 120 ajouts sont proposés dans le sélecteur de séance, avec `g` et `eq` dérivés ; aucun nom ne collisionne avec un nom v1. |
| D-L9b-05 | La bibliothèque masque les 22 doublons v1 ; leur nom mène à l'exercice canonique. |
| D-L9b-06 | Démonstration sans fond propre dans la fiche (fond de la carte) ; le rôle `fond` sert au rendu de référence et aux contrôles de contraste. |
| D-L9b-07 | Sources affichées en texte (URL non cliquables) : l'application reste sans réseau. |
| D-L9b-08 | Tranches de difficulté du filtre : 1-3 « accessible », 4-6 « intermédiaire », 7-10 « avancé ». |
| D-L9b-09 | Accès aux fiches : Arsenal → Exercices et sélecteur de séance. Pas de bouton dans l'écran de séance du programme dans ce lot (écran le plus dense ; à décider avec L10). |

## 5. Registre de validation (relecture par un professionnel diplômé recommandée)

Le contenu sportif n'a pas été relu par un professionnel diplômé (décision du propriétaire). À faire relire, en plus de `validation_register.md` du pack (attributions musculaires, difficultés, seuils de progression, contraintes articulaires, précautions, démonstrations statiques et indisponibles) :
- les tranches de difficulté du filtre (D-L9b-08) ;
- les consignes affichées dans la fiche (points clés, erreurs, respiration, précautions) : textes du pack, repris sans modification ;
- la lisibilité des démonstrations pour un débutant (gestes hors du plan réduits à la position de départ).

## 6. Limites

- Mesure de performance en mode profile sur téléphone et essais sur appareil : **non faits** (aucun téléphone). Coût mesuré dans l'environnement de test : voir `SUIVI_PROJET.md` L9b.3.
- Le générateur de programme (L10) n'utilise pas encore la base v2 ; les champs `generateur`, `substitutions`, `contrainte_articulaire` sont chargés mais pas exploités.
- Les fiches ne sont pas encore accessibles depuis l'écran de séance du programme (D-L9b-09).
