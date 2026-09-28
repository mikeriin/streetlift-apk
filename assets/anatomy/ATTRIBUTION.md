# Mannequin anatomique 3D — sources, licence et modifications

Le mannequin 3D de Kalis Track (`assets/anatomy/mannequin.glb` et `assets/anatomy/muscles_map.json`) est une adaptation du modèle `full-body-male-mobile.glb` et de la carte `full-body-map.json` du dépôt fitmitwith-anatomy-atlas (https://github.com/slfresh/fitmitwith-anatomy-atlas, commit 4120ee68b6604b8f2f69105d6de6166fad4734c4). Ces fichiers sont distribués sous licence Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0) : https://creativecommons.org/licenses/by-sa/4.0/. Seuls ces fichiers du modèle sont sous CC BY-SA ; le reste de l'application relève de sa propre licence.

## Crédits (formulation demandée par les concédants)

"Z-Anatomy - The libre 3D atlas of anatomy - CC-BY-SA 4.0"
https://github.com/Z-Anatomy/Models-of-human-anatomy
Authors: Kousaku Okubo (original model BodyParts3D), Gauthier Kervyn (design, 3D, anatomy), Marcin Zielinski (Blender add-on) and the contributors named in the upstream License.txt.

"BodyParts3D - The Database Center for Life Science - CC-BY-SA 2.1 Japan"
(the license under which Z-Anatomy obtained the geometry)
https://creativecommons.org/licenses/by-sa/2.1/jp/

"BodyParts3D, © The Database Center for Life Science licensed under CC Attribution 4.0 International"
(the credit line the Database Center for Life Science requests today)
https://dbarchive.biosciencedbc.jp/en/bodyparts3d/download.html
https://creativecommons.org/licenses/by/4.0/

Adaptation intermédiaire : fitmitwith-anatomy-atlas (FIT MIT WITH — 3D Anatomy Atlas), CC BY-SA 4.0, notice du 13/09/2026 reprise intégralement dans `tools/anatomy/source/ATTRIBUTION.txt`.

## Modifications faites pour Kalis Track (27/09/2026)

- Muscles profonds invisibles au repos retirés (liste dans `muscles_map.json`, clé `retirees`).
- Aponévrose des obliques écartée de devant le droit de l'abdomen.
- Tête, mains et pieds remplacés par des volumes sombres et lisses de même encombrement ; platysma et bandelette ilio-tibiale retirés.
- Os d'appui invisibles retirés, maillages simplifiés (moins de 60 000 triangles), couleurs de rendu de l'application.
- Noms français, correspondance avec les 11 groupes et les muscles du pack de contenu.

Fabrication reproductible : `tools/anatomy/build_model.py` (Blender sans interface). Le modèle n'a pas été relu par un spécialiste de l'anatomie ; les couleurs affichées sont des repères d'entraînement, pas une mesure de l'activation musculaire.
