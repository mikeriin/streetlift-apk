# Livraison M7b correction 2 — Tous les fonds 3D de la couleur du support (5.8.2)

Retour du propriétaire (30/09/2026) : « TOUS les fonds de la couleur du support. »

## Correction
- Audit des 13 constructions de vues 3D des sources : fond explicite partout (`kPageColor(context)` / `kCardColor(context)`, `lib/ui.dart`).
- Cartes-cadres retirées : **fiche exercice** (mannequin fixe ou animé posé sur la page) et **Réglages › À propos › Moteur 3D › Animation de test** (lecteur posé sur la page). Koach (aperçu), Anatomie, Moteur 3D : page.
- Aperçu de WOD et STATS : le mannequin reste dans la carte « Muscles sollicités » (titre, légende), fond = couleur de cette carte, désormais explicite. Accueil : couleur de sa carte (inchangé).
- `test/fonds_3d_test.dart` : toute vue 3D des sources reçoit un fond ; aucune carte ne sert seulement de cadre à une vue 3D (tout nouvel écran est couvert).
- Règle étendue en tête du §3 de `PIPELINE_3D.md`.

## Contrôles
- CI 3D run 36674308561 (essai A vert) : 999 tests Dart, 140 tests Python, formatage et analyse sans remarque, builds debug et profile.
- Émulateur : démarcation 0,0 sur Anatomie (sombre, clair, zoom, grand texte), 4 fiches, STATS sombre et clair, accueil sombre et clair, aperçu de WOD, Moteur 3D, grand écran, les 9 animations de Koach ; animation de test : fond uniforme sur toute la capture (écart mesuré au bord haut dû à la barre de titre).
- main 528afc3 ; build signé n° 176 (36675932390).
