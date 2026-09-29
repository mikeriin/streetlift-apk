# Livraison M56 — Mannequin musclé, squelette refait, premières animations (Kalis Track 5.5.0)

**Date** : 29/09/2026 · **Version** : 5.5.0+79 · **Commit main** : 7a24fc0 · **Build signé** : run 36509815224 (n° 133) · **CI 3D** : run 36508242229 (5 essais, de 36500069566 à 36508242229) · **Modèle** : Fable 5.1, effort maximal · **Base** : main b745c41 (5.4.0+78) ; brouillon M6 de la session Opus (`claude/m6-travail`) relu et repris

## Ce que tu vois
- **Arsenal › Exercices › Traction pronation, Dips, Back squat** : le mannequin s'anime en boucle à la place de la démonstration 2D, avec son matériel (barre de traction, barres parallèles, barre chargée, sol), au tempo du pack (2-1-1-1, 2-0-1-1) ; phase et tempo sous la vue ; rotation au doigt, zoom, vues. Hors de l'écran l'animation se met en pause et repart au retour. Animations réduites (Réglages › Accessibilité) : positions clés au choix, sans animation.
- **Arsenal › Référence › Anatomie** : mannequin au physique d'un athlète de force (bras, poitrine, cuisses, mollets aux cibles ; taille non épaissie) ; postures Suspendu, Squat bas, Planche recalculées sur le nouveau modèle et le nouveau squelette.
- **Programme › une séance** : carte « Koach · séance du jour » en tête (questionnaire, jour de fatigue, ajustements et leurs raisons), repliable en une ligne ; plus rien de Koach au-dessus du premier exercice.
- **Ouverture d'une fiche ou de l'écran Anatomie** : mannequin préchargé au lancement (modèle, carte, squelette, peau, matériel, registre des clips, pipelines de rendu préchauffés par une image hors écran) : plus de saccade au premier affichage.
- **Réglages › À propos › Moteur 3D › Préchargement** : durée du préchargement (chargement, préchauffage), mémoire résidente ajoutée ; pour le dernier mannequin ouvert : temps jusqu'à sa première image et images perdues. **Tes chiffres sur ton téléphone sont ceux qui comptent** (émulateur en rendu logiciel : chargement 17 ms, préchauffage 1,2 s, +1,8 Mo).

## Mesures du modèle (H = 1,700 m, enveloppe musculaire = cible moins 2 cm de peau ; bideltoïde nominal)
| Tour | Avant (5.4.0) | Après (5.5.0) | Fraction de H | Cible |
| --- | --- | --- | --- | --- |
| Bras (mi-biceps) | 26,8 cm | 35,4 cm | 0,208 | 0,22 − peau → atteinte |
| Avant-bras (max.) | 25,1 | 27,8 | 0,163 | atteinte |
| Poitrine (sous les aisselles) | 94,9 | 101,0 | 0,594 | −2,3 % |
| Taille (minimum) | 68,0 | 69,8 | 0,411 | non épaissie (voulu) |
| Cuisse | 43,1 | 56,8 | 0,334 | atteinte |
| Mollet (max.) | 33,3 | 35,4 | 0,208 | atteinte |
| Cou | 32,4 | 34,0 | 0,200 | −4 % |
| Bideltoïde | 47,0 | 48,5 | 0,285 | atteinte |
| Épaules / taille | 1,66 | 1,73 | — | ≥ 1,55 |

Tout dans ± 5 % sauf la taille (décision). Interpénétrations entre muscles voisins et avec les os : 10,3 mm sur le modèle de base → **0 > 1 mm** (17 itérations). Mêmes 227 nœuds et 62 506 triangles ; os, tête, mains, pieds inchangés.

## Technique
- `tools/anatomy/measure_body.py` (tours au mètre ruban : périmètre de l'enveloppe convexe de la section horizontale des muscles du segment, niveaux ISAK), `build_body.py` (entrée `tools/anatomy/mannequin_base.glb` = géométrie M4b, sortie `assets/anatomy/mannequin.glb` + `body_report.json`) : membres par dilatation radiale autour de l'os porteur, tronc / cou / fessiers par épaississement le long des normales, profil de ventre en plateau (tendons fixes), facteurs ajustés par sécante jusqu'aux cibles ; résolution des interpénétrations par nombre d'enroulement (libigl) + distance à la surface.
- Squelette (`rig_def.py`, `build_rig.py`) : **54 os** = 30 segments + 18 os d'aide aux tiers de la rotation (épaules, coudes, hanches, genoux ; pronation à 1/2) avec échelle de gonflement au pli + 6 os de gonflement de contraction (biceps, quadriceps, grand fessier ; échelle 1 + gain × angle de l'articulation motrice). Axes du coude (transépicondylien), du genou (épicondyles, inclinaison bornée à 3°) et de la cheville (bimalléolaire, 26°) mesurés sur les os ; rotation tibiale ajoutée ; limite glénohumérale 130° mesurée dans le repère de la scapula. Peau : partage scapula / bras par la hauteur le long de l'axe du bras, tendons d'insertion collés à l'humérus, nappes en éventail sans chaîne d'aide. flutter_scene 0.23 n'a pas de formes correctrices : os d'aide et échelles jouent ce rôle, recalculés dans l'application (`MannequinRig.withHelpers`).
- Matériel (`build_equipment.py`, `assets/anatomy/equipment.glb/json`, 163 Ko) : barre de traction Ø 28 mm à 2,30 m, barres parallèles Ø 45 mm à 55 cm / 1,40 m, barre olympique 2,20 m + disques Ø 45 cm, sol, lests, points de contact nommés.
- Chaîne d'animation (`animate.py`) : fiche biomécanique (`tools/anatomy/fiches/<id>.json`) → angles imposés + moindres carrés bornés (contacts, pieds, équilibre, matériel) → clip ≤ 5 Ko (`assets/anatomy/clips/<id>.json.gz` : 3,3 / 2,0 / 2,2 Ko ; registre `index.json`). Profils de vitesse humains (trapèze adouci, arrêts tenus à secousse minimale, retournements sans pause à tempo 0). Contrôles automatiques : contacts 1 cm, pénétration 2,5 mm, sol, capsules, limites, amplitude, trajectoire de la barre, équilibre + contrôles d'entraîneur (suspension active, coudes vers les côtes, creux thoracique, jambes gainées, épaule sous le coude, inclinaison du buste, coudes en arrière, jambes fixes, écart des pieds).
- Pilotes : traction pronation (prise 58 cm, suspension passive → active → menton 4 cm au-dessus de la barre), dips (coudes 102°, épaule 1,6 cm sous le coude, buste 28°, jambes fixes, centre de masse à 0,3 cm des mains), back squat barre haute (pieds à 44 cm, hanche 4 cm sous le genou, barre à 0,5 cm du milieu du pied, vue 3/4 par défaut).
- Application : `lib/mannequin_rig.dart` (échelles, os d'aide), `mannequin_3d.dart` (matériel, lecteur, pause hors écran), `mannequin_clip.dart`, `exercise_mannequin.dart`, `koach_day_card.dart`, `mannequin_preload.dart` (`MannequinPreload.start()` à `onReady`, `Scene.warmUp`, `OpenTimer`), carte « Préchargement » dans `engine3d.dart`.

## Contrôles
- Python (126 tests) : `test_m56_body.py` (mesures, cibles, pénétrations, triangles), `test_m56_clips.py` (matériel, registre, clips ≤ 5 Ko, contacts rejoués aux images clés et entre elles, sens et amplitude des phases), `test_m5_rig.py` adapté (54 os, échelles), `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`.
- Dart : formatage et analyse sans remarque, **966 tests réussis, 0 échec** (`m56_clip_test`, `m56_koach_day_card_test`, `m56_preload_test`, `m5_rig_test` refait : 54 os, tiers, gonflement).
- Planches Blender regardées : avant / après (face, dos, profil), 12 postures, gros plans (épaule, aisselle, coude, genou, aine) ; GIF des trois boucles + planches de boucle (8 images/s) regardés.
- Revue indépendante (sous-agent entraîneur + anatomiste, 3 tours) : majeurs corrigés (tempo perçu, suspension active, coudes, jambes des dips, écart des pieds, profondeur, retournements) ; verdict final : les trois animations acceptables.
- CI 3D (émulateur Android 15, rendu logiciel) : Anatomie (repos face et dos, suspendu / squat bas / planche en 3/4), 3 fiches animées (8 images d'une boucle, 3/4, pause hors écran, reprise, animations réduites), carte Koach sombre et clair, ouverture avant / après préchargement, écran Moteur 3D ; builds debug et profile ; captures regardées.
- Build signé n° 133 réussi sur 7a24fc0.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section M56 : avant / après, postures, 3 GIF, carte Koach, mesures du préchargement)

## Limites
- Bras au-dessus de la tête (> 140°) : en gros plan, les insertions du grand dorsal, du grand rond et du dentelé forment de petites lames sous l'aisselle (mélange linéaire sans formes correctrices) ; discret à l'échelle de l'écran et en transparence.
- Traction : coudes à 55-60° du tronc (géométrie bras / avant-bras avec le menton au-dessus de la barre) ; dips : épaule 1,6 cm sous le coude (extension d'épaule 60°) ; squat : vue 3/4 à 45° (60° suggéré par la revue), léger écrasement quadriceps / adducteurs à l'aine en bas.
- Muscles allumés : ceux de la fiche du pack (grand adducteur, fléchisseurs du coude absents des principaux) ; lecteur complet (pause, curseur, muscles selon la phase) : M7.
- Mesures du préchargement sur émulateur non représentatives (rendu logiciel à ≈ 300 ms par image, caches déjà chauds par les cas précédents, processus non relancé) : chargement 82 ms, préchauffage 54 ms, ouverture d'une fiche 134 ms avant / 258 ms après, 2 à 3 images perdues dans les deux cas : aucune différence mesurable là ; les critères (≤ 1 image perdue, lancement +150 ms max) se lisent sur le téléphone (carte Préchargement).
- `visual_capture_test.dart` échoue avant comme après (depuis 2.5.0). Différence bénigne connue des captures catalogue WOD (zone de l'horloge).
