# Livraison M7 — lecteur d'animation, intensité par phase, import des animations Mixamo du propriétaire, animation de test

- **Version** : 5.7.0+86 — `main` 8da6311 (« Kalis Track 5.7.0 (M7) : … »)
- **Build signé** : n° 167 (run 36631585307, `build-apk.yml`)
- **CI 3D** : run 36629784293 (essai C ; A : 36625018336, B : 36628032262), tout vert (rendus `visual_capture_test` en échec aussi sur `main` avant le lot, inchangé)
- **Page de suivi** : https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section M7)
- **Date** : 29/09/2026 — Claude Opus 5.5, effort élevé

## Ce qui change dans l'appli
- Réglages › À propos › Moteur 3D › **Animation de test** : squat lent au poids du corps (descente 3 s, pause 1 s, montée 1 s, pause 1 s), libellé comme test, jamais sur une fiche ; images/s affichées.
- Lecteur : lecture / pause, curseur (glisser = parcourir), phase et tempo (« Descente · 3 s »), vues, zoom, toucher sur le corps en mouvement ; halo vif en concentrique (1), plus doux en excentrique (0,62), pulsation lente en isométrie (0,8 ± 0,07, 2 s), fondus de 0,4 s.
- Animations réduites : pas de lecture, curseur sur les images clés de début et de fin de chaque phase. Pause hors écran, en arrière-plan, après 60 s sans interaction.
- Fiches : lecteur seulement pour un exercice qui a une animation du propriétaire ; aujourd'hui aucune : fiches inchangées.

## À tester (téléphone)
1. Réglages › À propos › Moteur 3D › Animation de test : fluidité (images/s), lecture / pause, curseur, phases.
2. Halo : vif en montée, doux en descente, pulsation en pause, sans clignotement.
3. Vues, zoom, nom au toucher pendant le mouvement.
4. Android « Supprimer les animations » : images clés seulement.

## Import des animations du propriétaire
- Mode d'emploi : `docs/ANIMATIONS_PROPRIETAIRE.md` (Mixamo : Ch36, FBX Binary, Without Skin, 30 i/s, Keyframe Reduction none ; nom = identifiant du pack ; envoi en pièce jointe dans la conversation de pilotage, jamais sur GitHub).
- `tools/anatomy/import_animations.py deposer <fbx…>` puis `importer` (clé `KT_ASSETS_KEY`, Blender sans interface) ; `verifier` sans clé. Réglages : `tools/anatomy/animations.json`.
- Sources chiffrées : `assets_secure/animations/<id>.fbx.enc` (rôle « animation » du manifeste) ; clips `assets/anatomy/clips/<id>.ktclip`, registre `index.json`.

## Fabrication et contrôles
- Mannequin animable `tools/anatomy/build_animated.py` : zones reprises du GLB fixe (écart 0,0001 mm), repos en T, 65 os, peau 4 influences ; GLB 870 Ko chiffré (`assets_secure/mannequin_anime.glb.enc`), `rig_mixamo.json`, `peau_mixamo.bin` ; +720 Ko dans l'APK.
- Animation de test `tools/anatomy/debug_animation.py` : cuisses 88°, chevilles 33°, pieds fixes, tronc 41,7° (centre de masse au-dessus du milieu du pied), bras devant ; FBX « Without Skin » (os `mixamorig:`), aller-retour par l'import 0,003° ; clip 1 982 octets, 16 pistes, écart ≤ 0,2°.
- 989 tests Dart, 129 tests Python (9 sautés sans numpy en CI), formatage et analyse sans remarque ; émulateur : 5 temps en profil, 3 vues au plus bas, toucher, zoom, lecture, pause, clair, animations réduites, 12 images du GIF ; captures regardées.

## Limites
- Phases détectées par la hauteur du centre de masse : mouvements horizontaux (face pull, tirages) à régler à la main dans `animations.json`.
- Halo toujours sans test d'occlusion.
- Images/s sur émulateur (2-3) non représentatives : la mesure qui compte est celle du téléphone.
