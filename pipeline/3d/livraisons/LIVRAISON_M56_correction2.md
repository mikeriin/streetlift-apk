# Livraison M56 — correction 2 : écorché acheté, plus d'animation (Kalis Track 5.5.2)

**Date** : 29/09/2026 · **Version** : 5.5.2+81 · **Commit main** : 5aeb2d1 (« Kalis Track 5.5.2 (M56, correction 2) : … ») · **Build signé** : run 36554048481 (n° 142) · **CI 3D** : run 36551761380 (4 essais sur `claude/ci-3d-fable`) · **Modèle** : Fable 5.1, effort maximal · **Base** : main 786e867 (5.5.1+80) · **Remplace** : 5.5.1

## Tes demandes (29/09/2026) et ce qui a été fait
| Demande | Fait |
| --- | --- |
| « Change le modèle et prend celui que j'ai mis en .zip, je l'ai acheté » | L'écorché « Ecorche Musclenames Male Anatomy » (archive `Archive.zip` de ta release GitHub `modele-achete`, 168 Mo, jamais dans le dépôt) remplace le mannequin Z-Anatomy partout : Anatomie, fiches, STATS, aperçus. Un seul maillage sculpté (664 284 triangles) dont chaque muscle est une plage de couleur de la texture avec son abréviation : `tools/anatomy/build_model.py` segmente la texture, lit les 232 étiquettes (relevées à la main, légende du vendeur), nomme 136 régions (68 muscles × 2 côtés), regroupe les os (`os`), les tendons et aponévroses (44 nœuds gris translucides), la tête, les mains et les pieds, subdivise comme le pack (deltoïde antérieur / moyen / postérieur, trapèze supérieur / moyen / inférieur, grand pectoral claviculaire / sterno-costal / abdominal, gastrocnémien médial / latéral) et décime le tout à 59 400 triangles sans fissure (1,4 Mo). |
| « tu remets les muscles en alpha 50 % et la couleur reste la même que ce qu'il y a dans l'application » | Muscles gris `kMuscleGray` à 50 % d'opacité, comme avant ; tendons dans le même gris translucide ; os en gris sombre (filtre « Os »), tête, mains et pieds en volumes sombres. |
| « pour les muscles engagés change la couleur en fonction de la couleur principale choisie par l'utilisateur » | La rampe des muscles sollicités (3D et carte 2D) part de la couleur principale de Réglages › Apparence vers sa nuance vive (claire en sombre) : Rouge Kalis, Jaune, Turquoise… Principal 1, secondaire 0,62, stabilisateur 0,35, halo inchangés. |
| « Supprimes toutes les animations et repart de zéro, plus d'animation juste l'affichage des muscles utilisés et je ferai les positions à la main plus tard, à prendre en compte pour les autres M » | Plus aucune animation ni posture : fiches = démonstration 2D historique + mannequin fixe avec les muscles de l'exercice ; écran Anatomie sans sélecteur « Posture » ; clips, matériel, fiches biomécaniques, squelette, peau et leurs outils retirés (le code de posture de `mannequin_3d.dart` reste inactif pour tes positions à venir). Lots M6b et M7 à M18 à redéfinir (DECISIONS_3D.md, « En attente »). |
| « Enlève les boutons suivant et précédent puisque glisser vers la droite et vers la gauche font déjà le taff » | Barre Précédent / Suivant retirée de la séance et de l'historique ; les points de progression et le glissement restent. |

## Ce que tu vois
- **Arsenal › Référence › Anatomie** : l'écorché acheté, gris à 50 %, Face / Dos / Profil / 3/4, rotation et zoom au doigt, nom du muscle au toucher, filtres par groupe (chaque groupe s'allume dans ta couleur principale). Plus de puces « Posture ».
- **Arsenal › Exercices › une fiche** : démonstration 2D, puis le mannequin fixe avec les muscles de l'exercice dans ta couleur ; les muscles profonds que l'écorché ne montre pas (20 muscles du pack : petit pectoral, subscapulaire, vaste intermédiaire, rotateurs de la hanche, transverse…) sont listés dessous (« Absents du mannequin »).
- **Programme › une séance** : glisse à droite / à gauche entre la page Koach, les exercices et le bilan ; plus de boutons.
- **Réglages › Apparence › couleur principale** : change-la, les muscles sollicités suivent (fiches, Anatomie, STATS, carte 2D).

## Technique
- `tools/anatomy/build_model.py --zip Archive.zip [--render dossier]` (numpy, scipy, Pillow, fast_simplification ; 15 s) : lecture de l'OBJ, classification de la texture sur une palette de 16 teintes relevée à la main (texte blanc, dégradés et lisérés gris fins rebouchés par le plus proche voisin), régions d'image → régions de triangles (UV du centre) → composantes du maillage, miettes (< 150 triangles) fusionnées ; étiquettes (`LABELS`, texel du texte → triangle → composante) ; deux muscles de même teinte qui se touchent (grand pectoral / dentelé, etc.) séparés par plus court chemin (Dijkstra sur le graphe des triangles) depuis leurs étiquettes ; composantes bilatérales coupées à x = 0 ; composantes plus grossières que leur symétrique recoupées d'après le côté opposé ; composantes sans étiquette nommées par voisinage de même teinte, par symétrie triangle par triangle, ou par position (tête, cou, mains, pieds) ; décimation globale (`fast_simplification`) puis report des régions par plus proche centre ; tendons en composantes connexes (`tendon_<k>`, tri de transparence par nœud) ; GLB sans squelette ; carte `muscles_map.json` (schéma 2, `muscles_sans_region`).
- `tools/anatomy/anatomy_data.py` : nouvelles clés (biceps et triceps d'un seul tenant, extenseur / fléchisseur ulnaire du carpe, fléchisseur superficiel des doigts, rond pronateur, rhomboïdes, semi-épineux de la tête, érecteurs du rachis, ilio-psoas, muscles hyoïdiens) ; `GROUP_OF_KEY` pour les muscles sans muscle du pack.
- Application : `MannequinScene` sans rig (`_loadRig` → null), matériau des tendons, `musclesSansRegion` (20 muscles, raison), `anatomy_screen.dart` sans posture, crédits (`ATTRIBUTION.md` : licence d'achat, non redistribuable), version 5.5.2+81.
- Retirés : `assets/anatomy/rig.json`, `mannequin_skin.bin`, `tools/anatomy/build_rig.py`, `rig_def.py`, `rig_pose.py`, `render_poses.py`, `build_body.py`, `measure_body.py`, `silhouette.py`, `mannequin_base.glb`, `source/` (Z-Anatomy), `tools/tests/test_m5_rig.py`, `test_m56_body.py`, `test/m5_rig_test.dart`, `integration_test/postures_m5_test.dart` (et en 5.5.2 déjà : clips, matériel, `animate.py`, `render_clip.py`, `build_equipment.py`, `fiches/`).

## Contrôles
- Python (105 tests) : `test_m2_anatomy.py` réécrit (budget ≤ 60 000, nœuds ↔ régions, deux côtés par clé, symétrie gauche / droite ≤ 2 ×, muscles du pack couverts sauf les 20 justifiés, étiquettes connues, source hors dépôt, crédits, pubspec), `verify_project`, `package_release --check`, `check_release_without_secrets --tree`.
- Dart : formatage et analyse sans remarque, 955 tests, 0 échec (m2, m3, m4b adaptés ; LC1 par glissement).
- Planches regardées : régions colorées (face, dos, profils, légende), gros plans cou / bras / bassin / dos / jambes avec les noms, rendu Blender à 50 % (4 vues), pectoraux allumés.
- CI 3D (émulateur Android 15) : Anatomie (4 vues, Dos allumé), 3 fiches, carte Koach, préchargement, Moteur 3D ; captures regardées. Build signé n° 142 sur 5aeb2d1.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section « M56 · correction 2 »)

## Limites
- L'écorché ne montre que la couche superficielle : 20 muscles profonds du pack n'ont plus de région (texte sur les fiches) ; le filtre « Muscles profonds » de l'écran Anatomie n'a plus d'effet (à retirer ou réaffecter avec M6b).
- Muscles hyoïdiens et scalènes : régions « Muscles hyoïdiens » / « Scalène moyen » un peu asymétriques (étiquettes du vendeur d'un seul côté pour certaines pièces) ; sans muscle du pack, jamais allumés.
- Deltoïde, trapèze, grand pectoral et gastrocnémien sont subdivisés géométriquement (angle, hauteur, côté), pas par des cloisons anatomiques.
- Les zones grises de la texture (fascia thoraco-lombaire, bandelette ilio-tibiale, aponévroses) sont des « tendons » gris translucides non sélectionnables ; les érecteurs du rachis (gris dans la texture) sont une région.
- Pas de posture : le mannequin est en A partout ; positions d'exercice à faire à la main (à toi), à prendre en compte pour les prochains lots.
