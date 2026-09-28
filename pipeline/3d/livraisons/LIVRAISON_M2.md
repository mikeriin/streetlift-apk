# Livraison M2 — Modèle anatomique 3D et écran Anatomie (Kalis Track 5.1.0)

**Date** : 28/09/2026 · **Version** : 5.1.0+73 · **Commit main** : f29e880 · **Build signé** : run 36366289332 (n° 98) · **CI 3D** : run 36364366340

## Ce que tu vois dans l'appli
- **Arsenal › Référence (en bas) › Anatomie** : mannequin anatomique 3D (gris mat, tête, mains et pieds sombres et lisses, os discrets) ; rotation au doigt ; boutons Face / Dos / Profil / 3/4 avec transition ; un des 11 groupes mis en évidence (rampe bordeaux → rouge, halo en sombre) avec la liste de ses muscles en texte ; toucher un muscle affiche son nom, son côté et son groupe.
- **Réglages › Affichage 3D** : « Nom du muscle au toucher », « Os visibles », « Halo » (activés).
- **Réglages › À propos › Moteur 3D** : la mesure de fluidité porte sur le mannequin en rotation.
- **Sources et licences** : crédits Z-Anatomy / BodyParts3D (CC BY-SA 4.0).
- Téléphone sans Flutter GPU : carte 2D historique.

## Technique
- `tools/anatomy/build_model.py` (Blender sans interface, relançable) depuis fitmitwith-anatomy-atlas (commit 4120ee6, SHA-256 vérifié) : 56 126 triangles, une maille par muscle et par côté, 21 muscles profonds invisibles retirés (des deux côtés), aponévrose des obliques écartée du droit de l'abdomen, volumes sombres pour tête, mains, pieds.
- `assets/anatomy/muscles_map.json` : 180 régions (nom français, côté, groupe, muscles du pack) ; tous les muscles superficiels du pack ont une région.
- Build hook `hook/build.dart` (GLB → .fsceneb) ; widget `Mannequin3D` (`lib/mannequin_3d.dart`), rendu à la demande, toucher par lancer de rayon en Dart ; écran `lib/anatomy_screen.dart`.
- Organisation (a) « une maille par muscle » retenue après mesure contre (b) « maillage fusionné » (détail et chiffres dans `pipeline/3d/DECISIONS_3D.md`).

## Contrôles
- CI 3D (run 36364366340) : formatage, analyse sans remarque, 870 tests Dart réussis (13 ignorés, 0 échec), Python (dont 8 nouveaux sur le modèle), intégrité, ZIP, builds debug et profile.
- Émulateur Android 15 : Anatomie en 4 vues sombre et clair (figure, gris, rouge contrôlés), nom au toucher (« Grand pectoral (chef sterno-costal) (gauche) · Pectoraux »), os masqués, Moteur 3D sur le mannequin ; captures regardées, comparées aux illustrations historiques (même gris mat, tête, mains et pieds sombres).
- Rendus des écrans avant / après : 45 identiques, 2 différents (heure affichée dans le catalogue WOD).
- Build signé n° 98 réussi : APK 37,8 Mo (+2,8 Mo par rapport à 5.0.0, +7,5 Mo depuis 4.3.1 ; objectif ≤ 10 Mo). Modèle converti : 0,9 Mo.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Muscles profonds retirés (sous-scapulaire, rhomboïdes, petit pectoral…) : présents dans les listes en texte, pas sur le mannequin.
- Modèle non relu par un anatomiste ; couleurs = repères d'entraînement.
- Mesures de fluidité de la CI non représentatives (émulateur logiciel, 4 à 8 images par mesure).
- `test/visual_capture_test.dart` échoue toujours comme avant M1 (hors lot).
