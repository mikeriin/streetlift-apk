# Pack de contenu Kalis Track v2 (L9R)

Base d'exercices sourcée, taxonomie et atlas musculaire détaillés, arbres de progression et démonstrations calculées par cinématique, produits par le lot L9R sans modifier l'application. Schémas, conventions et décisions : `CONTRAT_L9.md`.

## Contenu

| Fichier | Rôle |
| --- | --- |
| `exercises_v2.json` | 625 exercices au schéma 2.1.0 (505 de la base v1, 50 ajouts L9, 70 ajouts L9R), muscles sourcés, vocabulaires |
| `muscles.json`, `atlas.svg` | taxonomie de 81 muscles/chefs et atlas original (face, dos, une région par muscle superficiel) |
| `progressions.json` | 24 arbres de progression, seuils de passage, prérequis transverses |
| `poses.json` | modèle corporel, 246 gabarits calculés (fiches biomécaniques, images clés), statut de démonstration par exercice |
| `mapping_v1_to_v2.json` | ancien nom → identifiant ; intitulés du programme v33 → identifiant + méthodes |
| `sources/` | sources consultées par archétype, références cinématiques |
| `planches/` | planches PNG de contrôle visuel (atlas, 150 prioritaires, 70 ajouts) |
| `coverage_report.md` | contrôles, matrice de couverture et manques justifiés, liste des 150 prioritaires |
| `validation_register.md` | points à faire valider par le propriétaire |
| `relectures_traitees.md`, `licences.md` | traitement des relectures ; sources et licences |
| `review_tool.html` | outil de relecture autonome (ouvrir dans un navigateur ; publié aussi comme artefact claude.ai avec base partagée) |
| `renderer_reference/` | moteur de rendu de référence `kt_pose.js` 2.0.0 et page de démonstration `index.html` |
| `tools/` | scripts de construction, de validation et de rendu ; tests unitaires |

## Reconstruire et valider

```sh
python3 tools/atlas_build.py .                                   # atlas.svg + muscles.json (shapely)
python3 tools/build_pack.py <exercises_db.json.gz> <programme_v33.json.gz> .
python3 tools/validate.py . --v1 <exercises_db.json.gz> --programme <programme_v33.json.gz>
python3 tools/build_register.py .
python3 tools/build_html.py .
python3 tools/pose_checks.py                                     # 260 gabarits, 0 défaut
python3 tools/planche.py exercices poses.json exercises_v2.json planches/x.png <id> ...   # planches (playwright + Chromium)
KT_V1_DB=<exercises_db.json.gz> KT_PROGRAMME=<programme_v33.json.gz> python3 -m unittest discover -s tools/tests -v
```

Résultats du candidat v2 : 36 tests réussis sur 36 ; tous les contrôles de `validate.py` OK ; 22 manques de couverture justifiés.

## Relecture

La relecture se fait dans l'outil publié (même lien que la v1) : filtres (type, lieu, non relus, démonstration indisponible, 150 prioritaires), fiche complète, atlas avec les muscles de l'exercice, animation et images clés, fiche biomécanique, sources, arbres, boutons « Valider » / « À corriger » avec catégorie et commentaire, enregistrés dans la collection partagée `relectures_v2` (export JSON de secours). Quand le propriétaire valide la v2, ses corrections sont appliquées, l'archive validée est copiée sous `kalis_content_pack_v1_final.zip` (nom attendu par l'enchaînement, contenu v2) et L9b est lancé.

## Intégration prévue en L9b

1. Copier `exercises_v2.json`, `muscles.json`, `progressions.json`, `poses.json`, `mapping_v1_to_v2.json` compressés en `.json.gz` et `atlas.svg` dans `assets/`.
2. Migration des données utilisateur : conserver les noms v1 dans l'historique ; résoudre un nom en identifiant par `mapping_v1_to_v2.json`. Aucune donnée supprimée.
3. Atlas : afficher `atlas.svg` avec les rôles de couleur (`KPalette` : accent de la couleur dominante, #8A8A8A pour le corps) ; colorer les régions `data-muscle` des muscles primaires, atténuer les secondaires, contourer les stabilisateurs ; lister les muscles en texte (dont les profonds). Le champ `groupe` de `muscles.json` relie chaque muscle à la carte actuelle à 11 groupes.
4. Démonstrations : porter `renderer_reference/kt_pose.js` (silhouette, interpolation, chronologie, accessoires) dans un `CustomPainter` ; respecter `statut` (`indisponible` → atlas + consignes ; `statique` → image fixe) et la réduction des animations (`staticStrip`).
5. Test de parité : positions `joints` de `poses.json` comme valeurs attendues (écart < 0,002).
6. Fiche exercice : points clés, erreurs, respiration, précautions, muscles (primaires, secondaires, stabilisateurs), fiche biomécanique, sources, prérequis et progressions cliquables.
7. Le générateur L10 filtre sur `generateur = true`, `lieux`, `materiel`, `difficulte`, `contrainte_articulaire` et `precautions`, puis utilise `substitutions` et `progressions`.
