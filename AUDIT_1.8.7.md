# Correctif 1.8.7+39 — analyse GitHub

Date : 21 septembre 2026. Base : ZIP 1.8.6+38 livré après validation de l'écran Programme / accueil.

## Cause confirmée et correction

L'analyse GitHub échouait avec `curly_braces_in_flow_control_structures` dans `test/level_fill_test.dart:73:11`. Le bloc `if` qui comptait les pixels colorés était réparti sur deux lignes sans accolades.

Le problème a été reproduit à l'identique en extrayant le ZIP 1.8.6 : une anomalie, même fichier, même ligne. Les trois conditions de ce test utilisent maintenant des blocs avec accolades. Aucune règle d'analyse n'a été désactivée et aucun test n'a été supprimé. Le rapport d'analyse de la livraison 1.8.6 était insuffisant pour garantir la conformité du ZIP ; le rectificatif est indiqué dans son audit.

La version est portée à **1.8.7+39**, affichée **1.8.7** dans Réglages. Le comportement et le rendu de l'accueil validé sont conservés.

## Contrôles sur l'archive reconstruite

Une archive candidate a été extraite dans un nouveau dossier, puis contrôlée avec Flutter **3.29.3** et Dart **3.7.2**. Les dépendances ont été restaurées hors ligne avec `--enforce-lockfile`, à partir d'archives vérifiées contre les empreintes du fichier de dépendances verrouillées.

- `flutter analyze --no-pub` : **aucun problème**, sortie 0.
- `TZ=Europe/Paris flutter test --no-pub --timeout 60s --reporter expanded` : **130 tests réussis**.
- `python3 -m unittest discover -s tools/tests -v` : **4 tests réussis**.
- `python3 tools/verify_project.py --signing` : **réussi**.

Les sorties sont conservées dans **validation/1.8.7/**, y compris la reproduction du blocage de la version précédente. Le ZIP final contient exactement le code, les tests et la configuration vérifiés dans cette extraction ; seuls les documents et les rapports ont été ajoutés ensuite. Son intégrité et cette correspondance ont été vérifiées lors de sa création.

## Livraison

Remplacer **streetlift_tracker_v33.zip** à la racine du dépôt, puis exécuter **Actions → Build APK**. Le workflow fourni est conservé. Le nom de l'archive et le dossier racine `streetlift_tracker/` sont identiques à ceux attendus par le workflow.

L'APK n'a pas été compilé ici, faute de SDK Android local ; sa compilation et son installation sur téléphone restent à exécuter via le workflow habituel. L'écran 3 demeure validé et livré ; ce correctif ne valide pas d'autres écrans de la refonte.
