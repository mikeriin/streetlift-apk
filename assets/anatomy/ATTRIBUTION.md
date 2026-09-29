# Mannequin anatomique 3D — source, licence et modifications

Le mannequin 3D de Kalis Track (`assets/anatomy/mannequin.glb` et `assets/anatomy/muscles_map.json`) est dérivé de l'écorché « Ecorche Musclenames Male Anatomy » (maillage ZBrush `male_ecorche.OBJ`, texture `diffuse.jpeg`, légende `BonesMusclesFibers.pdf`), acheté par le propriétaire de l'application le 29/09/2026 sous la licence commerciale du vendeur. Cette licence autorise l'usage du modèle dans l'application ; elle n'autorise pas sa redistribution : le fichier source n'est pas dans le dépôt public et le modèle d'exécution (décimé, sans texture, régions nommées) n'est fourni qu'en tant que composant de l'application.

Jusqu'à la version 5.5.1, le mannequin était une adaptation du modèle Z-Anatomy / BodyParts3D (CC BY-SA 4.0) ; cette source n'est plus utilisée à partir de 5.5.2.

## Modifications faites pour Kalis Track (29/09/2026)

- Régions : chaque muscle de la texture (plage de couleur portant son abréviation) devient une région nommée par côté ; os (beige) regroupés dans `os`, tendons et aponévroses (gris) dans `contexte`, tête, mains et pieds en volumes sombres.
- Subdivisions du pack de contenu : deltoïde (antérieur, moyen, postérieur), trapèze (supérieur, moyen, inférieur), grand pectoral (claviculaire, sterno-costal, abdominal), gastrocnémien (médial, latéral).
- Maillage simplifié à moins de 60 000 triangles (décimation globale, sans fissure), sans texture : couleurs de rendu de l'application (muscles gris opaques ; muscles sollicités signalés par un halo dans la couleur dominante, depuis 5.5.4). Aire de chaque région calculée sur ce maillage (choix de la vue de départ des fiches, 5.5.5).
- Noms français, correspondance avec les 11 groupes et les muscles du pack de contenu ; les muscles profonds absents de l'écorché restent en texte sur les fiches.

Fabrication reproductible : `tools/anatomy/build_model.py --zip Archive.zip`. Le modèle n'a pas été relu par un spécialiste de l'anatomie ; les couleurs affichées sont des repères d'entraînement, pas une mesure de l'activation musculaire.
