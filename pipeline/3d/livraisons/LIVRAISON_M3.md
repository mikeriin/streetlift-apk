# Livraison M3 — Fiche exercice : mannequin 3D (Kalis Track 5.2.0)

**Date** : 28/09/2026 · **Version** : 5.2.0+74 · **Commit main** : 2fd86d2 · **Build signé** : run 36382919900 (n° 99) · **CI 3D** : run 36381559870

## Ce que tu vois dans l'appli
- **Arsenal › Exercices › une fiche › Muscles** : le mannequin anatomique 3D remplace la carte 2D face / dos / profil. Muscles de l'exercice dans la rampe historique : principal 1, secondaire 0,62, stabilisateur 0,35 (halo en sombre) ; **muscles étirés en bleu acier** (0,25), rappelé dans la légende.
- Vue de départ : principaux tous postérieurs → Dos, tous antérieurs → Face, mixtes → 3/4 (latéraux ignorés ; à défaut, les secondaires décident). Boutons Face / Dos / Profil / 3/4 ; rotation au doigt horizontale (le glissement vertical fait défiler la fiche).
- Liste des muscles en texte conservée ; muscles profonds absents du mannequin nommés sous la vue ; nom au toucher selon le réglage.
- Démonstration animée 2D inchangée. Téléphone sans Flutter GPU : carte 2D historique de la fiche, inchangée.

## Technique
- `lib/exercise_mannequin.dart` : `ExerciseMannequin`, `ExerciseMuscleMap` (pack → régions, étirés prioritaires), `exerciseStartView` + `muscleFaces` (81 muscles), `musclesSansRegion` (12 muscles justifiés).
- `lib/mannequin_3d.dart` : régions étirées (`mannequinStretch`), repli fourni par l'écran, rotation horizontale seule, modèle chargé une fois puis copié (`Node.clone`).
- CI 3D : `integration_test/fiche_exercice_test.dart` (cible séparée dans `tools/ci3d_drive.sh`).

## Contrôles
- CI 3D (run 36381559870) : formatage, analyse sans remarque, 884 tests Dart réussis (13 ignorés, 0 échec), Python, intégrité, ZIP, builds debug et profile.
- Correspondance pack → régions pour les 625 exercices (12 muscles profonds / internes justifiés) ; règle de vue ; 50 fiches sans exception (sombre / clair).
- Émulateur Android 15 : 6 fiches (traction, dips, soulevé de terre roumain, planche, front lever tuck, curl haltères) sombre et clair, vue conforme à la règle ; étirés en bleu (sombre et clair) ; profonds listés ; toucher « Grand dorsal (droit) · Dos », aucune bulle réglage coupé ; rotation. Captures regardées.
- 20 fiches d'affilée : mannequin prêt dès son arrivée à l'écran (médiane 1 ms, max 5 ms), création 0-1 ms, mémoire stable (460 → 459 Mo, debug).
- Rendus des écrans avant / après : 45 identiques, 2 différents (heure du catalogue WOD).
- Build signé n° 99 réussi : APK 37,8 Mo (identique à 5.1.0).

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Étirements : le pack classe aussi les muscles étirés en principaux ; ils sont montrés étirés (bleu).
- Mixte → 3/4 avant, même quand le dos domine (traction).
- Thème clair : rampe peu contrastée entre rôles ; la liste en texte fait foi.
- 12 muscles profonds ou internes non colorés (nommés sous la vue).
