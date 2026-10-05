# Mannequin anatomique 3D — sources, licences et modifications

## Personnage (depuis 5.6.0)

Le mannequin 3D de Kalis Track (`assets/anatomy/mannequin.glb`, `assets/anatomy/muscles_map.json`, `assets/anatomy/squelette_mixamo.json`) est dérivé du personnage « Ch36 » d'Adobe Mixamo (mixamo.com), fourni par le propriétaire de l'application le 29/09/2026, avec son squelette Mixamo (`mixamorig1:`, 65 os). Il est utilisé selon les conditions d'utilisation d'Adobe pour Mixamo, qui permettent d'intégrer les personnages et animations dans une application ; il n'est pas redistribué séparément : le FBX source et le modèle d'exécution sont chiffrés dans le dépôt (`assets_secure/`, clé détenue par le propriétaire) et n'existent en clair que dans l'application compilée. Mixamo est une marque d'Adobe.

## Zones musculaires

Les zones musculaires dessinées sur la peau du personnage sont projetées depuis l'écorché « Ecorche Musclenames Male Anatomy » (maillage ZBrush `male_ecorche.OBJ`, texture `diffuse.jpeg`, légende `BonesMusclesFibers.pdf`), acheté par le propriétaire le 29/09/2026 sous la licence commerciale du vendeur, qui autorise son usage dans l'application mais pas sa redistribution. Sa conversion (136 régions nommées) est elle aussi chiffrée dans le dépôt. De 5.5.2 à 5.5.5, cet écorché était le mannequin affiché. Jusqu'à 5.5.1, le mannequin était une adaptation de Z-Anatomy / BodyParts3D (CC BY-SA 4.0) ; comparé en 5.6.0 comme source des zones, il n'a pas été retenu.

## Modifications faites pour Kalis Track (29/09/2026, 5.6.0)

- Personnage « un peu plus fit » : léger gain de volume sur le maillage de repos (épaules et deltoïdes, pectoraux, haut du dos et grand dorsal, bras, avant-bras, cuisses, mollets ; +6 à +9 % de tour sur les membres, taille inchangée), sans toucher aux os ni aux poids de peau ; coutures du mannequin (taille, épaules, cou, poignets, chevilles) lissées.
- Textures d'origine retirées : matériau gris mat de l'application, tête, mains et pieds en gris sombre. Bras abaissés pour l'affichage fixe (pose de repos en T conservée dans le squelette).
- Zones : régions de l'écorché recalées sur le personnage (pose des bras, hauteurs des articulations, recalage non rigide), projetées sur la peau, frontières lissées, zones symétriques ; noms français, correspondance avec les 11 groupes et les muscles du pack de contenu. Les muscles profonds, invisibles sous la peau, restent en texte sur les fiches.

Fabrication reproductible : `tools/anatomy/build_character.py` (après `tools/secure_assets.py decrypt --tout`). Le modèle n'a pas été relu par un spécialiste de l'anatomie ; les zones affichées sont des repères d'entraînement, pas une mesure de l'activation musculaire.
