# Livraison M4 — STATS : résumé hebdomadaire sur le mannequin 3D (Kalis Track 5.3.0)

**Date** : 28/09/2026 · **Version** : 5.3.0+75 · **Commit main** : acb5034 · **Build signé** : run 36398571739 (n° 100) · **CI 3D** : run 36393809265

## Ce que tu vois dans l'appli
- **STATS › Performances › Muscles sollicités** : le mannequin anatomique 3D remplace les silhouettes 2D face / dos. Chaque muscle prend la couleur de son groupe (rampe bordeaux → rouge, halo en sombre), avec les **mêmes chiffres qu'avant** : séries pondérées de la semaine ramenées au groupe le plus travaillé, groupes sous 2 % non colorés.
- Bascule **Face / Dos** ; rotation au doigt horizontale (le glissement vertical fait défiler STATS).
- **Légende chiffrée** : « Dos · 16 », « Triceps · 5,4 »… et une ligne qui explique le calcul (1 pour le groupe principal de l'exercice, 0,6 pour les autres, WOD 0,5 par tour et par mouvement).
- Semaine vide : mannequin gris et « Valide tes séries pour voir ta répartition musculaire. »
- Téléphone sans Flutter GPU : carte 2D historique, inchangée.

## Technique
- `lib/stats_mannequin.dart` : `WeeklyMannequin`, `weeklyRegionIntensities` (mains et pieds restent sombres).
- `lib/muscle_body.dart` : normalisation extraite sans changement (`heatmapIntensities`, `kHeatmapMinIntensity`) ; `MuscleLegend(values: true)`.
- `lib/mannequin_3d.dart` : paramètre `views` (boutons de vue au choix).
- CI 3D : `integration_test/stats_semaine_test.dart`, lancé en premier sur l'émulateur.

## Contrôles
- CI 3D (run 36393809265) : formatage, analyse sans remarque, 894 tests Dart réussis (13 ignorés, 0 échec), Python, intégrité, ZIP, builds debug et profile.
- Intensités comparées chiffre à chiffre à la normalisation de 5.2.0 (6 jeux de données, semaine type du store, semaine vide).
- Émulateur Android 15 : semaine type (8 groupes, 132 régions) Face et Dos, sombre et clair, rotation, légende ; semaine vide sombre et clair (aucun rouge). Captures regardées.
- Défilement de STATS mannequin à l'écran : fil UI médiane 2,4 ms (p90 15,5 ms, 46 images) contre 116 ms pendant la rotation : la scène n'est pas redessinée au défilement, pas d'image en cache nécessaire.
- Rendus des écrans avant / après : 45 identiques, 2 différents (heure du catalogue WOD).
- Build signé n° 100 réussi.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Couleur par groupe : tous les muscles d'un groupe ont la même intensité (le groupe Dos inclut les muscles du cou, choix de M2).
- Après une rotation au doigt, le bouton Face / Dos reste sur la dernière vue choisie.
- CI émulateur instable (« device offline ») : la cible fiche exercice de M3 n'a pas pu être rejouée dans ce lot (code de la fiche inchangé) ; Moteur 3D et Anatomie rejoués avec succès.
