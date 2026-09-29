# Livraison M56 — correction 3 : muscles opaques, zone ciblée, le modèle partout (Kalis Track 5.5.3)

**Date** : 29/09/2026 · **Version** : 5.5.3+82 · **Commit main** : b01bb75 (« Kalis Track 5.5.3 (M56, correction 3) : … ») · **Build signé** : run 36561741052 (n° 146) · **CI 3D** : run 36560553169 (3 essais sur `claude/ci-3d-fable`) · **Modèle** : Fable 5.1, effort maximal · **Base** : main 5aeb2d1 (5.5.2+81) · **Remplace** : 5.5.2

## Tes demandes (29/09/2026, avec les trois images face / dos / profil) et ce qui a été fait
| Demande | Fait |
| --- | --- |
| « plus d'affichage avec 50 % on repasse à 100 % » | `kMuscleOpacity` 1,0 : muscles et tendons opaques partout (Anatomie, fiches, STATS, cartes). |
| « pour les groupes musculaires sollicités penche plus pour la zone ciblée en surbrillance plutôt que le groupe en lui-même » | Nouveau calcul `targetedMuscles` / `targetedRegionIntensities` (`lib/stats_mannequin.dart`) : pour chaque exercice, les muscles de sa fiche du pack (principaux 1, secondaires 0,6), pondérés par ses séries (semaine), ses tours (WOD) ou 1 (séance prévue), ramenés au maximum, seuil 2 % ; une région s'allume au plus fort de ses muscles. Un exercice sans fiche allume ses groupes comme avant. Appliqué à STATS › Muscles sollicités (`AppStore.weeklyNames`), à la séance du jour de l'accueil et à l'aperçu d'un WOD (`AppStore.plannedNames`). Les fiches allumaient déjà les muscles de l'exercice. L'écran Anatomie garde son filtre par groupe (c'est un filtre). |
| « Remplace tous les anciens affichages qui utilisent les images en pièces jointes par le modèle » | Fiche exercice : le mannequin des muscles ciblés ouvre la fiche à la place de la démonstration 2D en découpes (`PoseDemo`, plus affichée ; plus de mention « sans démonstration ») ; section Muscles en texte. Accueil (carte de la séance du jour, feuille de séance) et aperçu de WOD : `TargetedMannequin` (compact, sans boutons ni gestes dans les cartes ; Face / Dos dans l'aperçu). STATS : déjà en 3D. Les images `assets/muscles/` ne servent plus qu'au repli sans Flutter GPU. |
| « Plus besoin d'avoir de contrôle en glissant du doigt pour tourner la caméra on se fie aux boutons » | `MannequinGestures` n'enregistre plus de glissement à un doigt (rotation) pour le mannequin de l'application ; boutons Face / Dos / Profil / 3/4, pincement (zoom) et toucher (nom du muscle) gardés ; `Mannequin3D.interactive` false pour les cartes (le toucher va à la carte). |

## Ce que tu vois
- **Fiche exercice** : mannequin opaque en tête, muscles de l'exercice dans ta couleur, « Absents du mannequin » dessous, liste en texte dans la section Muscles.
- **STATS › Performances › Muscles sollicités** : les muscles des fiches de tes exercices validés cette semaine.
- **Accueil** : petit mannequin de face sur la carte de la séance du jour et sur la feuille de séance ; **Arsenal › WOD › aperçu** : mannequin Face / Dos.
- **Partout** : glisser ne tourne plus le mannequin (la page défile) ; les boutons changent la vue ; pincer zoome.

## Technique
- `lib/stats_mannequin.dart` : `targetedMuscles(lib, names)`, `targetedRegionIntensities(map, targets)`, `TargetedMannequin` (charge carte + fiches du pack si le moteur 3D est disponible ; repli 2D `MuscleHeatmap` par groupe), `WeeklyMannequin` = `TargetedMannequin` de la semaine (`WeeklyMannequinState` = alias).
- `lib/store.dart` : `plannedNames(estimate)`, `weeklyNames([at])` (mêmes règles de date que `weeklyMuscles`, qui en dérive désormais).
- `lib/mannequin_3d.dart` : `kMuscleOpacity` 1, `interactive`, plus de `onRotate` ; `lib/mannequin_gestures.dart` : `enabled`, glissement seulement si `onRotate` fourni (tests).
- `lib/exercise_screens.dart` : plus de `_demo()`, imports `pose_*` retirés ; `lib/home_screen.dart`, `lib/wod_preview.dart` : `TargetedMannequin`.
- Version 5.5.3+82.

## Contrôles
- Python 105 tests, `verify_project`, `package_release --check`, `check_release_without_secrets --tree`.
- Dart : formatage et analyse sans remarque, 955 tests, 0 échec (m3 : état du mannequin lu en tête de fiche ; m4b : règle du toucher translucide testée à 0,5 ; m4 STATS : `groups` ; L9b : plus de `PoseDemo` sur la fiche).
- CI 3D 3 essais (36556945259 : analyse ; 36558779220 : tests m3 / m4b ; 36560553169 : vert) ; émulateur : Anatomie 4 vues + Dos allumé, 3 fiches, carte Koach, préchargement, Moteur 3D ; captures regardées. Build signé n° 146 sur b01bb75.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section « M56 · correction 3 »)

## Limites
- Les cartes de l'accueil, l'aperçu de WOD et STATS ne sont pas capturés par la CI 3D (cible du lot = Anatomie, fiches, Koach, préchargement) : petits mannequins à voir sur le téléphone (une scène 3D par carte, rendu à la demande).
- Zone ciblée = muscles du pack de la fiche ; un exercice sans fiche (nom libre, WOD inconnu) allume encore ses groupes.
- Filtre « Muscles profonds » de l'Anatomie toujours sans effet (M6b).
