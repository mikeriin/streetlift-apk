# Livraison M8 correction 3 — Carte du jour aux couleurs de l'Anatomie (5.10.1)

Retour du propriétaire (30/09/2026) : « Sur la carte de la séance du jour, il est trop clair et flashy, je veux les mêmes couleurs que dans le menu anatomie. »

## Correction
- Accueil, carte du jour (fond de la couleur dominante) : la carte des muscles n'est plus teintée de la couleur du texte (`tint` retiré, `lib/home_screen.dart`) ; mêmes couleurs que l'écran Anatomie : muscles non travaillés en gris, travaillés dans la couleur dominante selon leur intensité, traits et modelé de l'image. Fond transparent : la carte reste posée sur la carte du jour.
- Test Dart (`test/programme_test.dart`) : la carte de l'accueil n'est pas teintée.

## Contrôles
- CI 3D run 36749218651 (essai A vert) : 1013 tests Dart, formatage et analyse sans remarque ; émulateur : accueil sombre et clair regardés.
- main 601a04d ; build signé n° 193 (36751438374).
