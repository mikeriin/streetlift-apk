# Livraison M6c — nouveau mannequin : personnage Mixamo « Ch36 », zones musculaires sur la peau, ressources sous licence chiffrées

- **Version** : 5.6.0+85 — `main` 66a167c (« Kalis Track 5.6.0 (M6c) : … »)
- **Build signé** : n° 163 (run 36618366444, `build-apk.yml`)
- **CI 3D** : run 36615305716 (essai C ; A : 36608701592, B : 36611540108), tout vert (rendus `visual_capture_test` en échec aussi sur `main` avant le lot, inchangé)
- **Page de suivi** : https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section M6c)
- **Date** : 29/09/2026 — Claude Opus 5.5, effort élevé

## Ce qui change dans l'appli
- Le personnage Mixamo « Ch36 » remplace l'écorché partout (Anatomie, fiches, séance, accueil, aperçu de WOD, choix d'exercice, STATS, Moteur 3D) : un peu plus fit, gris mat, tête / mains / pieds sombres, bras abaissés, coutures lissées.
- Zones musculaires sur la peau : 126 zones symétriques projetées depuis l'écorché acheté ; même mise en évidence (maillage gris, halo), toucher, zoom, vues, préchargement.
- Réglage « Os visibles » et filtre « Os » (catégorie « Affichage ») retirés ; l'écran Anatomie a 11 cases (les groupes).
- Vue de départ des fiches : surfaces vues de face / de dos, seuil 1,65 (traction : Dos ; dips, squat, muscle-up : 3/4).
- Crédits : Mixamo (Adobe) pour le personnage, écorché pour les zones.

## À tester (téléphone)
1. Arsenal › Référence › Anatomie : 4 vues ; coche Pectoraux, Épaules, Dos, Quadriceps, Ischios ; zoome ; touche un muscle.
2. Fiches traction pronation (dos), dips, back squat (3/4).
3. Accueil (carte du jour), aperçu d'un WOD, STATS › Performances, Réglages › À propos › Moteur 3D.
4. Réglages › Affichage 3D : plus de « Os visibles ».

## Fabrication et contrôles
- `tools/anatomy/build_character.py` (Blender sans interface + numpy / scipy), rapport `tools/anatomy/character_report.json` ; squelette `assets/anatomy/squelette_mixamo.json` + `lib/mixamo_skeleton.dart`.
- Fit : bras 28,0 → 30,5 cm (+8,9 %), avant-bras +6,2 %, cuisse +6,1 %, mollet +8,9 %, poitrine +5,7 %, taille 0 %, épaules +2,4 % ; 6 poses extrêmes vérifiées avant / après.
- Sources des zones comparées : écorché retenu (9 % de peau nue) contre Z-Anatomy (16 %, zones morcelées).
- 971 tests Dart, 116 tests Python, formatage et analyse sans remarque ; émulateur : Anatomie 4 vues sombre / clair, 5 gros plans du halo, toucher, 4 fiches, STATS, accueil, WOD, Moteur 3D.
- Mannequin : 28 880 triangles, GLB 679 Ko (535 Ko compressé dans l'APK).

## Ressources chiffrées
- `assets_secure/` : `character_mixamo_ch36.fbx.enc`, `mannequin.glb.enc`, `ecorche_mannequin.glb.enc`, `manifest.json` ; `tools/secure_assets.py` ; la CI déchiffre avec le secret `KT_ASSETS_KEY` (étape en échec explicite sans lui) ; aucun modèle 3D en clair dans l'arbre (`check_release_without_secrets.py --tree` le refuse).

## Pour le propriétaire
- Supprimer l'asset public `Archive.zip` de la release `modele-achete` : github.com › mikeriin/streetlift-apk › Releases › modele-achete › Edit › croix à côté de `Archive.zip` › Update release (l'outil GitHub de cette session ne sait pas supprimer un asset de release).
- L'historique git de `main` garde les anciennes versions en clair du modèle décimé (écorché 5.5.2-5.5.5) : réécriture non faite (interdite sans accord) ; décision en attente dans DECISIONS_3D.md (recommandation : laisser).

## Limites
- 4 muscles du pack passent en texte (rhomboïdes, élévateur de la scapula, coraco-brachial, extenseurs cervicaux) : sous d'autres muscles sur une peau.
- Halo toujours sans test d'occlusion.
- Frontières des zones à la maille du personnage (~1,5 cm), adoucies par le flou du halo.
