# Pack de contenu Kalis Track v1

Base d'exercices enrichie, arbres de progression et démonstrations animées par données de posture, produits par le lot L9 sans modifier l'application. Les schémas, conventions et décisions sont dans `CONTRAT_L9.md`.

## Contenu

| Fichier | Rôle |
| --- | --- |
| `exercises_v2.json` | 555 exercices au schéma v2 (505 de la base v1 + 50 ajouts) et vocabulaires |
| `progressions.json` | 24 arbres de progression, seuils de passage, prérequis transverses |
| `poses.json` | squelette, 200 gabarits de mouvement, pose de chaque exercice |
| `mapping_v1_to_v2.json` | ancien nom → identifiant ; intitulés du programme v33 → identifiant + méthodes |
| `coverage_report.md` | contrôles, matrice de couverture, liste prioritaire des 150 exercices |
| `validation_register.md` | points à faire valider par le propriétaire |
| `licences.md` | sources et obligations |
| `review_tool.html` | outil de relecture autonome (ouvrir dans un navigateur) |
| `renderer_reference/` | moteur de rendu de référence (`kt_pose.js`) et page de démonstration |
| `tools/` | scripts de construction et de validation, tests unitaires |

## Reconstruire et valider

```sh
python3 tools/build_pack.py <exercises_db.json.gz> <programme_v33.json.gz> .
python3 tools/validate.py . --v1 <exercises_db.json.gz> --programme <programme_v33.json.gz>
python3 tools/build_register.py .
python3 tools/build_html.py .
KT_V1_DB=<exercises_db.json.gz> KT_PROGRAMME=<programme_v33.json.gz> python3 -m unittest discover -s tools/tests -v
```

Résultats de la première passe : 25 tests réussis sur 25 ; tous les contrôles de `validate.py` OK ; 79 manques de couverture signalés (non bloquants).

## Relecture

La relecture se fait dans `review_tool.html` (ou dans sa version publiée, qui enregistre les relectures dans une base partagée) : filtres, fiche complète, animation, arbres cliquables, boutons « Valider » / « À corriger » avec commentaire, export JSON. La seconde passe (L9-passe2) lit ces relectures, corrige les bases de connaissances `tools/kb_*.py` et `tools/pose_templates.py`, reconstruit, puis livre `kalis_content_pack_v1_final.zip`.

## Intégration prévue en L9b

1. Copier `exercises_v2.json`, `progressions.json`, `poses.json` et `mapping_v1_to_v2.json` compressés en `.json.gz` dans `assets/`.
2. Migration des données utilisateur : conserver les noms v1 dans l'historique ; résoudre un nom en identifiant par `mapping_v1_to_v2.json` (`canonique` pour les doublons). Aucune donnée supprimée.
3. Moteur Flutter des démonstrations : porter `renderer_reference/kt_pose.js` (cinématique, interpolation, chronologie, accessoires) dans un `CustomPainter` ; les rôles de couleur viennent de `KPalette` (accent de la couleur dominante, `#8A8A8A` pour le corps, couleur du texte pour les accessoires). Respecter le réglage de réduction des animations avec la version à images fixes.
4. Test de parité : réutiliser les positions `joints` de `poses.json` comme valeurs attendues (écart < 0,002).
5. Fiche exercice : points clés, erreurs, respiration, précautions, muscles en texte, prérequis et progressions cliquables.
6. Le générateur L10 filtre sur `generateur = true`, `lieux`, `materiel`, `difficulte`, `contrainte_articulaire` et `precautions`, puis utilise `substitutions` et `progressions`.
