# Livraison M5 — Squelette d'animation et peau du mannequin (Kalis Track 5.4.0)

**Date** : 28/09/2026 · **Version** : 5.4.0+78 · **Commit main** : b745c41 · **Build signé** : run 36456576585 (n° 121) · **CI 3D** : run 36454868372 (8 essais, de 36442673769 à 36454868372) · **Effort** : accru

## Ce que tu vois
- **Arsenal › Référence › Anatomie** : sous les boutons Face / Dos / Profil / 3/4, puces **Posture** : Debout, Suspendu (à la barre, scapulas élevées), Squat bas (talons au sol), Planche (gainage sur les avant-bras). Transition douce de 0,75 s (instantanée si les animations sont réduites). Squat bas s'ouvre en 3/4, Planche en Profil. Posture gardée pendant la session. Sur un petit écran, un court défilement mène aux puces.
- Couleurs, halo, transparence, filtres, zoom et nom du muscle au toucher suivent le mannequin déformé.
- Fiches, STATS, Moteur 3D : mannequin au repos, identique à 5.3.2.

## Technique
- `tools/anatomy/build_rig.py` (relançable, déterministe), `rig_def.py` (os, degrés de liberté, axes, limites, sources, postures), `rig_pose.py` (peau en numpy), `render_poses.py` (planches Blender face / dos / profil / 3/4).
- Squelette : 30 os anatomiques + 10 os d'aide (épaules, coudes, pronation, hanches, genoux ; moitié de l'angle) = 40. Centres articulaires tirés des 273 pièces du squelette d'appui source. Scapula : élévation et protraction par la clavicule, sonnette, bascule et rotation à l'acromio-claviculaire ; bras en angles humérothoraciques (part glénohumérale ≤ 125°) ; pronation autour de l'axe radius-ulna.
- Peau : distances géodésiques dans le volume du corps (voxels 5 mm), lissées par muscle, 4 influences ; segments limités aux insertions de chaque muscle ; os du modèle rigides (rotule sur l'aide du genou) ; tendons et fascias collés aux muscles voisins.
- Sorties : `assets/anatomy/mannequin.glb` (mêmes 227 nœuds + 40 articulations + peau, 1,62 Mo ; fsceneb 1,25 Mo dans l'APK), `rig.json`, `mannequin_skin.bin` (246 Ko).
- Application : `lib/mannequin_rig.dart` ; `MannequinScene.applyPose` (articulations, toucher et cadrage sur positions déformées calculées sur le processeur, ordre des muscles translucides, pas d'élimination par le cadre) ; `Mannequin3D(posture:)`.

## Contrôles
- Python `test_m5_rig.py` : os et parents, longueurs constantes (12 postures), limites, quaternions = angles, poids somme 255 identiques GLB / fichier de peau, aucun sommet orphelin, os rigides, repos inchangé, muscles voisins collés (p99 ≤ 3 cm suspendu, 2,5 cm squat, 2 cm planche).
- Planches Blender regardées des 12 postures (4 vues chacune) et gros plans (aisselle, genou, coude, aine, épaule de dip) ; corrections : trapèze (étiquettes inversées de la source), rotule, contexte, muscles en éventail, bras humérothoraciques.
- CI 3D : formatage, analyse, 951 tests Dart réussis (0 échec), tests Python, builds debug et profile ; émulateur : 4 postures × 4 vues, accord toucher / rendu (88 à 100 % des points vides sur le fond, 67 à 100 % des points allumés en rouge), écran Anatomie (transition, toucher « Grand psoas (gauche) (profond) · Quadriceps » sur le squat, planche en clair). Captures regardées.
- Build signé n° 121 réussi sur b745c41.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Mélange linéaire (flutter_scene) : aisselle bras levés et devant du genou en squat un peu froissés en gros plan ; pas de déchirure à l'échelle de l'écran.
- Suspension sans barre (M6).
- Source : « trapèze supérieur / inférieur » inversés dans la carte source ; le rig suit la géométrie, la mise en évidence n'est pas corrigée (hors lot).
- Planche petite en vue Face / Dos.
- `visual_capture_test.dart` échoue avant comme après (depuis 2.5.0).
