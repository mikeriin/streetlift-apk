# Livraison M56 — correction 4 : halo des zones travaillées, fond sans démarcation (Kalis Track 5.5.4)

**Date** : 29/09/2026 · **Version** : 5.5.4+83 · **Commit main** : 9826982 (« Kalis Track 5.5.4 (M56, correction 4) : … ») · **Build signé** : run 36574123441 (n° 152) · **CI 3D** : run 36571687956 (essais 36565820933, 36567719792 dont une relance d'infrastructure, 36571648634 annulé, 36571687956) · **Modèle** : Fable 5.1 puis Opus 5.5 (même session) · **Base** : main b01bb75 (5.5.3+82) · **Remplace** : 5.5.3

## Tes demandes (29/09/2026) et ce qui a été fait
| Demande | Fait |
| --- | --- |
| « Je ne veux pas que le mesh soit coloré je veux que tu ajoutes un genre de halo de la zone travaillée » | Les matériaux du mannequin restent gris (plus de rampe ni d'émission, plus de bloom). `MannequinHaloPainter` dessine par-dessus la vue, pour chaque muscle sollicité, la silhouette écran de ses faces tournées vers la caméra, remplie dans ta couleur principale (principal plus intense : opacité 0,24 + 0,40 × intensité), floutée (réglage « Halo » ; nette s'il est désactivé). Étirés : même halo en teinte froide. |
| « Pour tous les affichages 3D, le fond doit être de la même couleur que le support sur lequel il est, on ne doit pas voir de démarcations » | `Mannequin3D.background` : fond de la scène (skybox), de la vue et du repli 2D. Par défaut la couleur des cartes du thème ; page pour l'Anatomie ; bordeaux ou gris de la carte de la séance du jour ; fond de la feuille de séance ; écran Moteur 3D inchangé. |

## Technique
- `lib/mannequin_3d.dart` : `_applyMaterials` gris seulement ; `haloIntensities`, `haloStretched`, `restMesh`, `windingOutward` (sens des faces mesuré sur le droit de l'abdomen) ; `MannequinHaloPainter` et `HaloProjection` (base caméra reconstruite et étalonnée sur `screenPointToRay` du centre et d'un coin) ; `configure(background:)`, `Mannequin3D.background`.
- `lib/stats_mannequin.dart` (`TargetedMannequin.background`), `home_screen.dart`, `anatomy_screen.dart`, `engine3d.dart` : couleur du support.
- Essai abandonné : coque 3D retournée autour de chaque muscle (surface ouverte : invisible de face) ; le modèle est inchangé depuis 5.5.2.

## Contrôles
- Dart 958 tests, 0 échec (`test/m56_halo_test.dart` : projection recoupée par les rayons, faces avant / arrière, opacité) ; Python 105 ; format et analyse sans remarque.
- CI 3D émulateur : Anatomie (4 vues, Dos allumé), 3 fiches, page Koach, préchargement, Moteur 3D ; captures regardées : fond sans cadre sur la page et dans la carte, maillage gris, halo sur les zones travaillées. Build signé n° 152 sur 9826982.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section « M56 · correction 4 »)

## Limites
- Halo calculé sur la forme du muscle vue de la caméra, sans test d'occlusion : un muscle caché par un bras garde un halo discret au travers.
- Pas de halo en rotation continue (écran Moteur 3D).
- Cartes de l'accueil, aperçu de WOD et STATS non capturés par la CI 3D.
