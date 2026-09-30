# Livraison M7b correction 1 — Koach sans cadre (5.8.1)

Retour du propriétaire (30/09/2026) : « C'est passable, le fond doit suivre les mêmes règles que le reste et être de couleur identique au support, ça doit être une règle de base pour la suite. »

## Correction
- Arsenal › Anatomie › Koach (aperçu) : le lecteur n'est plus dans une carte ; il est posé sur la page, fond de la vue 3D = couleur de la page, sans démarcation (comme l'écran Anatomie).
- Règle de base inscrite en tête du §3 de `pipeline/3d/PIPELINE_3D.md` : fond de tout affichage 3D = couleur de son support ; vérifié à chaque lot par un test Dart et par la mesure de démarcation sur émulateur.

## Contrôles
- Test Dart : fond de la vue = couleur de la page, aucune `KCard` autour du lecteur.
- Émulateur : démarcation 0,0 pour les 9 animations (CI 3D run 36670659752, essais A et B).
- 997 tests Dart, 140 tests Python, formatage et analyse sans remarque ; main 9e6d654 ; build signé n° 174.

## Non modifié
- L'écran « Animation de test » (M7) garde son lecteur dans une carte (fond = couleur de la carte) : à aligner sur la page si le propriétaire le souhaite.
