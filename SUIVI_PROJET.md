# Kalis Track — Suivi du projet

**Passe actuelle : pipeline « Mannequin 3D », lot M6b (correctifs du mannequin fixe : affichage, cohérence graphique, usage), version 5.5.5 ; précédent : lot M56 et ses corrections 1 à 4 (5.5.0 → 5.5.4), validé**  
**Date : 29 septembre 2026, Europe/Paris — version : 5.5.5+84 (versionCode réel fixé par la CI de build)**  
**Statut : contrôlé en CI (branche temporaire `claude/ci-3d`, rendu réel sur émulateur Android).**

## M6b — Correctifs du mannequin fixe (version 5.5.5)

Audit (`docs/AUDIT_M6b.md`, une ligne par défaut) puis corrections :

| # | Défaut | Correction |
| --- | --- | --- |
| D1 | Anatomie : « Muscles profonds » sans effet, compté comme filtre actif | Case retirée (`AnatomyFilters` sans `deep`), Affichage = « Os », résumé « Os affichés / masqués » |
| D2 | Fiche traction (et 110 exercices à principaux avant / arrière) : 3/4 avant, dorsal peu visible, halo lu comme un pectoral | `aire` par région (`build_model.py --aires`, calculée sur le GLB) ; `exerciseStartView(…, map)` : face dont la surface des principaux est ≥ 2 × l'autre, sinon 3/4 |
| D3 | Moteur 3D : cadre sombre | Fond de la page |
| D4 | Moteur 3D : aucun halo en rotation | `MannequinHaloPainter.cameraOf` + `repaint` (caméra calculée dans `onTick`, avant le dessin) |
| D5 | Accueil : halo invisible sur la carte du jour (couleur dominante sur couleur dominante) | `haloColor` (`Mannequin3D`, `TargetedMannequin`) = `SL.onBrandSoft` sur cette carte |
| D6 | Légende des rôles en pastilles pleines | `AtlasRoleLegend.haloAlpha` : pastilles halo sur le gris des muscles |
| D7 | « en rouge » au lecteur d'écran (Anatomie) | « mis en évidence par un halo » |
| D8 | « 1 actifs » au lecteur d'écran (menus Filtres) | Accord en nombre |
| D9 | Fiche sur tablette : mannequin petit | Hauteur 45 % de l'écran, 380-600 dp |
| D10 | Crédits : « gris à 50 % » | Texte de `ATTRIBUTION.md` à jour |
| D11 | Rotation possible derrière l'indicateur de chargement | Vue changée sans transition tant que la scène n'est pas affichée |

Non corrigés (raison dans l'audit) : halo sans test d'occlusion, toucher des aponévroses sans bulle (voulu), régions morcelées du modèle (lot de modèle), rendus de test `visual_capture_test` déjà en échec sur main.

## M56.C4 — Correction 4 (retour du propriétaire du 29/09/2026, version 5.5.4)

| Point | Retour | Correction |
| --- | --- | --- |
| Halo | « Je ne veux pas que le mesh soit coloré je veux que tu ajoutes un genre de halo de la zone travaillée » | Matériaux toujours gris (`_applyMaterials` ne change plus que la visibilité ; bloom éteint). `MannequinHaloPainter` (CustomPaint par-dessus la `SceneView`, sous la bulle) : pour chaque région sollicitée (et étirée, teinte froide), triangles tournés vers la caméra projetés à l'écran (`HaloProjection.of(camera, size)` : base caméra reconstruite et étalonnée sur `screenPointToRay` des coins ; sens des faces mesuré une fois sur le droit de l'abdomen, `windingOutward`), union remplie dans `mannequinHeat(v)` à l'opacité 0,24 + 0,40·v, flou 9 px (réglage « Halo » ; net sinon). Pas de halo en rotation continue (Moteur 3D, caméra par image). Une coque 3D retournée a été essayée puis abandonnée (surface ouverte : rien à voir de face). |
| Fond | « Pour tous les affichages 3D, le fond doit être de la même couleur que le support sur lequel il est, on ne doit pas voir de démarcations » | `Mannequin3D.background` (skybox de la scène, boîte de la vue, repli 2D) : carte du thème par défaut (`surfaceContainerLow`), page pour l'Anatomie, `SL.bordeaux` / `SL.card` sur la carte de séance de l'accueil, `SL.surface` dans la feuille de séance, `sceneBackground` sur l'écran Moteur 3D ; `TargetedMannequin.background`. |

Contrôles (CI 3D `claude/ci-3d-fable`, essais 36565820933 : analyse (import de `kMannequinFovY`) et fonction locale du test d'intégration déclarée après usage ; 36567719792 : tests verts, émulateur relancé une fois (image système Android corrompue au téléchargement, avant tout test) puis fiche attendue avant chargement du contenu ; 36571648634 annulé par le suivant ; 36571687956 vert) : formatage et analyse sans remarque, 958 tests Dart, 0 échec (`m56_halo_test` : projection recoupée par `screenPointToRay`, silhouette des faces tournées vers la caméra, opacité) ; 105 tests Python ; émulateur tout passé, captures regardées (fond de la page et de la carte sans démarcation, maillage gris, halo sur les zones travaillées).

## M56.C3 — Correction 3 (retour du propriétaire du 29/09/2026, version 5.5.3)

| Point | Retour | Correction |
| --- | --- | --- |
| Opacité | « plus d'affichage avec 50 % on repasse à 100 % » | `kMuscleOpacity` 1,0 ; tendons opaques aussi ; texte de l'écran Anatomie. |
| Zone ciblée | « pour les groupes musculaires sollicités penche plus pour la zone ciblée en surbrillance plutôt que le groupe en lui-même » | `targetedMuscles` / `targetedRegionIntensities` (`lib/stats_mannequin.dart`) : muscles du pack des fiches des exercices (principaux 1, secondaires 0,6, pondérés par séries / tours / 1), ramenés au maximum, seuil 2 % ; groupe entier seulement pour un exercice sans fiche. `AppStore.weeklyNames` (semaine) et `plannedNames` (séance, WOD) à côté des groupes historiques (repli 2D, légende, STATS). `WeeklyMannequin` devient un `TargetedMannequin`. |
| Images 2D | « Remplace tous les anciens affichages qui utilisent les images en pièces jointes par le modèle » (face, dos, profil de `assets/muscles/`) | Fiche : le mannequin des muscles ciblés remplace la démonstration 2D en découpes (`PoseDemo`) en tête de fiche, section Muscles en texte ; accueil (carte de séance et feuille de séance) et aperçu de WOD : `TargetedMannequin` (compact, sans boutons ni gestes) ; STATS déjà 3D. Les images restent pour le repli sans Flutter GPU. |
| Rotation | « Plus besoin d'avoir de contrôle en glissant du doigt pour tourner la caméra on se fie aux boutons » | `MannequinGestures` sans reconnaisseur de glissement quand `onRotate` est nul (mannequin de l'application) ; pincement (zoom) et toucher (nom) gardés ; `Mannequin3D.interactive` false pour les cartes. |

Contrôles (CI 3D `claude/ci-3d-fable`, 3 essais : 36556945259 analyse (`fallbackHeight` statique / instance, `groups`, import atlas), 36558779220 tests m3 (état du mannequin lu après le défilement) et m4b (toucher translucide à l'opacité par défaut), 36560553169 vert) : formatage et analyse sans remarque, 955 tests Dart, 0 échec ; 105 tests Python ; émulateur (`animations_m56_test` : Anatomie 4 vues + Dos allumé, 3 fiches, carte Koach, préchargement, Moteur 3D), captures regardées (muscles opaques, mannequin en tête de fiche).

## M56.C2 — Correction 2 (retour du propriétaire du 29/09/2026, version 5.5.2)

| Point | Retour | Correction |
| --- | --- | --- |
| Modèle | « C'est ENCORE pas bon. Change le modèle et prend celui que j'ai mis en .zip, je l'ai acheté » (écorché « Ecorche Musclenames Male Anatomy », 168 Mo, déposé dans la release GitHub `modele-achete`) | `tools/anatomy/build_model.py` réécrit : OBJ ZBrush (664 284 triangles, un seul maillage, pose en A) + texture 4096² (une teinte par muscle, abréviation en blanc, os beige, tendons gris) → segmentation de la texture (palette de 16 teintes, texte et dégradés rebouchés, lisérés gris fins rebouchés), régions d'image → composantes du maillage, miettes fusionnées ; 232 étiquettes relevées à la main (position du texte, abréviation lue, légende du vendeur) nomment les composantes ; muscles de même teinte qui se touchent séparés par plus court chemin depuis leurs étiquettes ; composantes à cheval sur la ligne médiane coupées ; composantes sans étiquette nommées par voisinage, par symétrie (triangle par triangle) ou par position ; subdivisions du pack (deltoïde par angle, trapèze par C7 et épine de la scapula, grand pectoral par hauteur, gastrocnémien médial / latéral) ; décimation globale à 59 400 triangles (pas de fissure), normales du maillage entier, H = 1,70 m. 136 régions, `os` 6 800 triangles, `contexte` 13 000, `head` 1 500. |
| Couleurs | « tu remets les muscles en alpha 50 % et la couleur reste la même que ce qu'il y a dans l'application, pour les muscles engagés change la couleur en fonction de la couleur principale choisie par l'utilisateur » | Muscles gris `kMuscleGray` à `kMuscleOpacity` 0,5 (inchangés) ; rampe `mannequinHeat` et `heat` 2D : `SL.accentSpec` (principale → vive), plus de rouge fixe. |
| Animations | « Supprimes toutes les animations et repart de zéro, plus d'animation juste l'affichage des muscles utilisés et je ferai les positions à la main plus tard, à prendre en compte pour les autres M » | Clips, matériel, lecteur, ticker, fiches biomécaniques, `animate.py`, `render_clip.py`, `build_equipment.py` retirés ; fiches : démonstration 2D + mannequin fixe avec ses muscles ; squelette, peau, postures et outils associés retirés (`rig.json`, `mannequin_skin.bin`, `build_rig.py`, `rig_def.py`, `rig_pose.py`, `render_poses.py`, `build_body.py`, `measure_body.py`, `silhouette.py`, `mannequin_base.glb`) ; code de posture de `mannequin_3d.dart` / `mannequin_rig.dart` gardé inactif. Lots M7 et suivants à redéfinir (`pipeline/3d/DECISIONS_3D.md`). |
| Séance | « Enlève les boutons suivant et précédent puisque glisser vers la droite et vers la gauche font déjà le taff » | Barre Précédent / Suivant retirée de la séance et de l'historique ; tests par glissement (`swipePage`). |

Contrôles (CI 3D `claude/ci-3d-fable`, 4 essais : 36542184910 analyse (`_startView`), 36546278876 tests LC1 par boutons et fiche sans défilement, 36549423360 formatage / respiration / préchargement, 36551761380 vert) : Python 105 tests (`test_m2_anatomy.py` réécrit : budget, nœuds ↔ régions, symétrie gauche / droite, étiquettes connues, source hors dépôt), Dart 955 tests, 0 échec (m2, m3, m4b adaptés : plus de couche profonde, 20 muscles du pack en texte), émulateur (`animations_m56_test` : Anatomie 4 vues + Dos allumé, 3 fiches, carte Koach, préchargement), planches des régions regardées (face, dos, profils, gros plans cou, bras, bassin, dos, jambes).

## M56.C1 — Correction 1 (retour du propriétaire du 29/09/2026, version 5.5.1)

| Point | Retour | Correction |
| --- | --- | --- |
| Modèle | « plus musclé mais difforme : cuisses et pecs trop gros par rapport au reste », référence = écorché d'athlète (3 images) | `tools/anatomy/silhouette.py` : largeurs (face) et profondeurs (profil) de la référence en fraction de H, mesurées sur les images ; `build_body.py` réajusté : bras, épaules, cuisses, mollets sur leur largeur ; cuisse anisotrope (plus profonde que large) ; pectoraux fixés à 0,6 (1,6 avant) ; taille à la cible nominale 0,45 H et fessiers à la largeur de hanches de la référence (dilatation radiale autour de la colonne / du bassin) ; érecteurs 0,30. Résultat : bideltoïde, poitrine, taille, hanches, cuisse, genou, mollet dans ± 6 % de la référence ; bras à mi-chemin (−6,5 %, tour 0,222 H = cible nominale) ; 0 pénétration > 1 mm (37 itérations, amincissement des sommets en sandwich corrigé). |
| Traction, position basse | « muscles et omoplates du modèle vont s'arracher », « il faut un V » ; « coudes trop en arrière », « abdos pas assez engagés » | Ailes = coiffe des rotateurs (poids mêlés scapula / bras portés par la chaîne d'aide à 155°) et grand dorsal / grand rond emportés par la rotation du bras : os d'insertion `arm_ins` (position de l'insertion humérale, orientation du tronc → la nappe s'étire en ligne droite, V), coiffe et grand rond sur la scapula (tendon seul collé à la tête humérale), deltoïde tout au bras 4 cm sous la tête (10 avant), sonnette et bascule dans le plan de la scapula (35°). Posture : bras à la verticale (flexion humérale 0), clavicule +20°, sonnette 45°, lombaires fléchies 8° et côtes basses (hollow), hanches 15°, genoux 90° (référence). |
| Dips, position basse | « coudes trop resserrés » | 5.5.0 : coudes serrés derrière le dos (abduction −25°). Extension humérothoracique portée à 75° (glénohumérale 50° + bascule antérieure 20°), bornes par position (`bornes_positions`), coudes ouverts 18-26°, bras à l'horizontale (épaule au niveau du coude ± 3 cm), tronc 23°, hanches 40°, genoux 92°, centre de masse à l'aplomb des prises. |
| Animations | « on fait juste un aperçu position de départ et position de fin » (décision après discussion : plus d'animation complète, GymVisual / `exercises-dataset` comme référence d'exécution seulement, licence des médias non acquise) | Clip : `positions` (départ, fin : nom, clé de la fiche, instant) ; application : `Mannequin3D` sans boucle ni ticker, position de départ affichée, puces Départ / Fin, fondu par `_poseTween` (0,75 s, matériel mobile interpolé), instantané si animations réduites ; `seekClip` gardé pour les captures. |
| Carte Koach | « doit être sur une autre page que la carte du premier exercice, juste avant » | Page « Koach · séance du jour » avant l'exercice 1 quand Koach a quelque chose à dire à l'ouverture (questionnaire, fatigue, adaptation) ; reprise d'une séance entamée : page de l'exercice en cours ; sans page Koach, une indication apparue en cours de séance reste en tête de l'exercice 1 (comme avant). |
| Anatomie | « aussi nul que la dernière fois » → le modèle lui-même | Corrigé par les proportions ci-dessus ; postures recalculées (bras levés : sonnette 50°, clavicule 20°, part glénohumérale 122°). |

Contrôles : Python 126 tests (`test_m56_body.py` réécrit sur les cibles de silhouette), Dart (`m5_rig_test` 56 os, os d'insertion ; `m56_clip_test` positions ; `m56_koach_day_card_test` page à part), émulateur (`animations_m56_test` : départ, mi-fondu, fin, 3/4, animations réduites), planches Blender regardées (avant / après, 12 postures, suspension dos et face, positions des trois exercices).

## M56.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M56.txt` (Fable 5.1, effort maximal) : M5 et M6 refaits avec une précision chirurgicale et crédibles, mannequin plus musclé, préchargé au lancement |
| Base | `main` `b745c41` (5.4.0+78) ; brouillon M6 de la session Opus (`claude/m6-travail`) relu et repris |

## M56.1 — Changements

- **Modèle** : `tools/anatomy/build_body.py` (hypertrophie par muscle : dilatation radiale autour de l'os porteur pour les membres, épaississement des nappes pour le tronc, profil de ventre nul aux tendons, facteurs ajustés par sécante jusqu'aux cibles, interpénétrations résolues jusqu'à 0 > 1 mm), `measure_body.py` (tours au mètre ruban), `mannequin_base.glb` (géométrie M4b de référence). Avant → après : bras 26,8 → 35,4 cm, avant-bras 25,1 → 27,8, poitrine 94,9 → 101,0, taille 68,0 → 69,8 (non épaissie), cuisse 43,1 → 56,8, mollet 33,3 → 35,4, cou 32,4 → 34,0, bideltoïde 47,0 → 48,5 ; épaules / taille 1,73. 62 506 triangles inchangés.
- **Squelette et peau** : os d'aide aux tiers (1/3, 2/3) avec gonflement au pli, os de gonflement de contraction (biceps, quadriceps, grand fessier), axes mesurés sur les os (coude, genou borné à 3° d'inclinaison, cheville bornée à 10°), rotation tibiale, limite glénohumérale 130° mesurée dans le repère de la scapula, partage scapula / bras par la hauteur, insertions collées à l'humérus, nappes sans chaîne d'aide. `lib/mannequin_rig.dart` : échelles des os d'aide et de gonflement recalculées à chaque posture (`withHelpers`, `localMatrix`).
- **Matériel et animations** : `build_equipment.py` (bibliothèque, 163 Ko), `animate.py` (fiche → moindres carrés bornés → clip ; profils de vitesse en trapèze adouci, arrêts tenus à accélération nulle, retournements sans pause à accélération non nulle ; dichotomie robuste ; contrôles d'entraîneur), `render_clip.py` (planches, GIF au tempo réel, planche de boucle), fiches `tools/anatomy/fiches/` (sources, revue). Clips : traction 3,3 Ko, dips 2,0 Ko, back squat 2,2 Ko.
- **Application** : `mannequin_clip.dart` (lecture, interpolation sphérique, registre), `exercise_mannequin.dart` (démonstration animée, repli 2D), `mannequin_3d.dart` (matériel, cadrage du clip, lecture en boucle, pause hors écran, positions clés), `koach_day_card.dart`, `session_screen.dart`, `koach_widgets.dart`, `adapt_screens.dart` (carte du jour), `mannequin_preload.dart` (préchargement, mesures), `engine3d.dart` (carte Préchargement), `main.dart`.
- Version 5.5.0+79.

## M56.2 — Contrôles

- Python (bibliothèque standard, `tools/tests/`) : `test_m56_body.py` (mêmes nœuds et triangles, os, tête, mains et pieds inchangés, déplacements symétriques, mesures dans la tolérance, aucune pénétration), `test_m5_rig.py` (54 os, longueurs constantes, limites, poids, os rigides, déchirures bornées), `test_m56_clips.py` (clips, contacts rejoués, phases, amplitude). Fabrication déterministe.
- Dart : `test/m5_rig_test.dart` (rig, aides aux tiers, gonflement), `m56_clip_test.dart`, `m56_koach_day_card_test.dart`, `m56_preload_test.dart`.
- Émulateur (`integration_test/animations_m56_test.dart`) : écran Anatomie (modèle au repos face et dos, 3 postures en 3/4), 3 pilotes (boucle en 8 images, vue 3/4, pause hors écran, animations réduites), carte Koach ouverte et repliée en sombre et en clair, ouverture d'un mannequin avant / après préchargement, écran Moteur 3D. Captures regardées.
- Revue indépendante des animations (sous-agent entraîneur + anatomiste, 3 tours) : verdict final acceptable pour les trois.

## M56.3 — Limites

- Bras au-dessus de la tête (> 140°) : les insertions du grand dorsal, du grand rond et du dentelé forment des lames sous l'aisselle en gros plan (mélange linéaire, flutter_scene sans formes correctrices) ; discret à l'échelle de l'écran et à 50 % d'opacité.
- Traction : coudes à 55-60° du tronc en haut (géométrie d'une traction menton au-dessus avec une prise à 58 cm) ; menton 4 cm au-dessus de la barre (8 cm inatteignable avec la tête derrière la barre).
- Dips : épaule 1,6 cm sous le coude (limite d'extension d'épaule 60°, AAOS).
- Squat : écrasement quadriceps / adducteurs à l'aine en bas ; vue 3/4 à 45° (60° suggéré par la revue).
- Coloration des muscles du pack (grand adducteur, fléchisseurs du coude) : hors lot.
- Mesure du préchargement sur émulateur (rendu logiciel, processus non relancé entre « avant » et « après », 300 à 900 ms par image) : non représentative ; les chiffres qui comptent sont ceux de la carte Préchargement sur le téléphone.
- Source : « trapèze supérieur / inférieur » inversés dans la carte source (M5) : non corrigé.

# Historique — M5 (5.4.0)

## M5.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M05.txt` (effort accru) : squelette ≤ 40 os posé sur les repères anatomiques, poids de peau automatiques corrigés, contrôles de déformation, sélecteur « Posture » (4 postures) dans l'écran Anatomie |
| Base | `main` `67ec551` (5.3.2+77) |

## M5.1 — Changements

- **Squelette** (`tools/anatomy/build_rig.py`, `rig_def.py`) : 30 os anatomiques (bassin, rachis lombaire, thoracique bas, thoracique haut, cou, tête ; clavicules, scapulas, bras, ulna, radius, mains, 2 os de doigts, cuisses, jambes, pieds, orteils) et 10 os d'aide à mi-angle (épaules, coudes, pronation, hanches, genoux). Centres articulaires tirés du squelette d'appui source (273 pièces rangées par la géométrie : sphères des têtes fémorale et humérale, condyles, malléoles, disques intervertébraux). Degrés de liberté, axes et limites en degrés avec leurs sources (AAOS, Norkin & White, White & Panjabi, Inman, Ludewig, Hemmerich, Kapandji) dans `assets/anatomy/rig.json`.
- **Peau** : poids géodésiques dans le volume du corps (voxels de 5 mm), lissés par muscle, 4 influences ; chaque muscle ne suit que les segments de ses insertions ; os du modèle rigides ; tendons et fascias collés aux muscles voisins ; mains, pieds et tête dans leurs segments. `assets/anatomy/mannequin.glb` (même organisation d'un nœud par région qu'en M2, plus la peau), `mannequin_skin.bin` (influences pour le toucher).
- **Contrôles de déformation** : `tools/anatomy/render_poses.py` (planches Blender face / dos / profil / 3/4 de 12 postures : les 4 de l'application et bras levés, extension arrière maximale, coude 150°, hanche 120° jambe tendue, rachis en flexion / extension / rotation, appui bas de dip).
- **Application** : `lib/mannequin_rig.dart` (rig, postures, interpolation, peau sur le processeur) ; `MannequinScene.applyPose` (articulations, toucher et cadrage sur le modèle déformé, ordre des muscles translucides) ; `Mannequin3D(posture:)` avec transition de 750 ms ; écran Anatomie : puces « Posture » (Debout, Suspendu, Squat bas, Planche) sous les boutons de vue.
- Version 5.4.0+78.

## M5.2 — Contrôles

- Python (`tools/tests/test_m5_rig.py`, bibliothèque standard) : os et parents, longueurs d'os constantes dans les 12 postures, limites respectées (et part glénohumérale ≤ 125°), quaternions = angles anatomiques, poids normalisés (somme 255) et identiques entre GLB et fichier de peau, aucun sommet sans poids, os rigides, repos inchangé, déchirure entre maillages voisins bornée (paires à ≤ 2 mm au repos : 99e centile ≤ 3 cm suspendu, 2,5 cm squat, 2 cm planche). Fabrication déterministe (SHA-256 identiques sur deux passages).
- Dart (`test/m5_rig_test.dart`) : lecture du rig et de la peau, cinématique identique à la fabrication (têtes des 40 os dans chaque posture), transition (os d'aide à mi-angle), sélecteur de l'écran Anatomie.
- Émulateur (`integration_test/postures_m5_test.dart`) : 4 postures × 4 vues, accord du toucher (peau du processeur) et du rendu (peau du GPU), écran Anatomie (transition, toucher d'un quadriceps sur le squat, planche en clair). Captures regardées.

## M5.3 — Limites

- Mélange linéaire (celui de flutter_scene) : aux amplitudes extrêmes (bras au-dessus de la tête, genou à 145°), l'aisselle et le devant du genou restent un peu froissés en gros plan ; à l'échelle de l'écran, pas de déchirure visible.
- Suspension sans barre (matériel 3D : lot M6).
- Source : étiquettes « trapèze supérieur / inférieur » inversées dans la carte source (voir DECISIONS_3D.md, M5) ; non corrigé dans la mise en évidence (hors lot).
- Planche vue de face ou de dos : petite (cadrage par la diagonale du corps).

# Historique — M4c (5.3.2)

## M4c.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M04c.txt` : plus de ZIP, projet structuré à la racine de `main`, CI et outils adaptés ; zoom au pincement ; filtres normalisés dans toute l'application |
| Base | `main` `4531346` (5.3.1+76, ZIP) ; étiquette `archive-zip-5.3.1` créée localement, non poussée (refus du proxy de la session) |

## M4c.1 — Changements

- **Dépôt** : un seul commit de restructuration (`a42f149`) pose le contenu du ZIP 5.3.1 à la racine, octet pour octet (fins de ligne CRLF d'origine gardées pour `gradlew.bat` et deux relevés CSV) ; `.gitignore` complété (tout ce que `release_security.py` refuse), `.gitattributes` (LF, binaires). `tools/compare_tree_with_zip.py` : arbre du commit = ZIP 5.3.1 (578 fichiers identiques par SHA-256) hors `.gitignore` et `.gitattributes`.
- **CI et outils** : `build-apk.yml` construit depuis la racine, déclenché par les chemins du projet sur toute branche et à la demande, étapes de signature et de vérification inchangées ; `ci-3d.yml` sans extraction, référence « avant » prise sur `main` (ZIP ou sources), job émulateur limité à 30 min ; `package_release.py --check` et `check_release_without_secrets.py --tree` contrôlent l'arbre suivi fichier par fichier ; `verify_project.py` vérifie la structure du dépôt et la couverture du `.gitignore` ; nouveaux tests `tools/tests/test_repository_tree.py`.
- **Zoom au pincement** (`lib/mannequin_gestures.dart`, `lib/mannequin_3d.dart`) : deux doigts = zoom de 1× à 4× par réduction de l'angle de champ (la caméra ne s'approche jamais du modèle : pas de traversée), point sous les doigts conservé, déplacement à deux doigts, fenêtre zoomée bornée à la vue d'ensemble ; reconnaisseur de pincement qui ne gagne jamais un geste à un doigt et gagne dès que deux doigts sont posés (la page ne défile pas pendant le zoom) ; double toucher (reconnu seulement une fois zoomé) et boutons de vue = vue par défaut ; lancer de rayon du toucher sur la caméra zoomée ; rendu à la demande conservé.
- **Filtres normalisés** (`lib/filter_menu.dart`) : bouton « Filtres · n », menu par catégorie (repliable, Tout cocher / Tout décocher), Réinitialiser, union dans une catégorie et intersection entre catégories, puces supprimables, fermeture au toucher en dehors. Écrans : voir M4c.4.
- Version 5.3.2+77.

## M4c.2 — Contrôles

- Identité : `python3 tools/compare_tree_with_zip.py --ref a42f149` → 578 fichiers du ZIP 5.3.1 identiques (SHA-256) dans l'arbre du commit de restructuration ; seules différences : `.gitignore` modifié, `.gitattributes` ajouté. Sur la tête livrée, les autres différences sont les fichiers de version, les outils et workflows adaptés, le zoom et les filtres (liste dans la livraison).
- Arbre sans secret : `check_release_without_secrets.py --tree` et `package_release.py --check` (586 fichiers contrôlés un par un) ; `verify_project.py` (structure du dépôt, `.gitignore` qui couvre chaque fichier refusé) ; tests Python dont `test_repository_tree.py` (arbre sain accepté ; clé, mot de passe, fichier local, cache, APK, ZIP, lien symbolique suivis refusés ; comparaison au ZIP).
- CI 3D run 36428956594 (8 essais : axes du zoom, menu en colonne à 200 %, puces, pincement calculé depuis son début) : formatage, analyse sans remarque, 946 tests Dart réussis (13 ignorés, 0 échec), builds debug et profile. (`visual_capture_test.dart` échoue avant comme après, depuis 2.5.0, hors lot.) Rendus des écrans avant / après : seuls le catalogue WOD et l'historique de STATS changent (bouton « Filtres » à la place des puces).
- `test/m4c_zoom_test.dart` : bornes 1× / 4×, point focal stable (y compris doigts qui bougent inégalement), bord de la vue, déplacement à deux doigts, profondeur bornée ; gestes dans une page qui défile : pincement sans défilement, un doigt vertical = défilement, horizontal = rotation, toucher bref immédiat, double toucher une fois zoomé.
- `test/m4c_filter_menu_test.dart` : union / intersection, compteur, puces, réinitialisation, Tout cocher / Tout décocher par catégorie, catégories repliables, accessibilité (bouton, cases lues avec leur catégorie et leur état, cibles ≥ 48 dp), sombre et clair × 6 couleurs dominantes à 320 px et texte 200 % ; bibliothèque, catalogue WOD, choix d'exercice ; historique (`stats_test.dart`) et Anatomie (`m4b_anatomie_test.dart`, `m2_mannequin_test.dart`) adaptés sans assertion retirée.
- Émulateur Android 15 (Flutter GPU) : pincement réel sur un avant-bras (Anatomie) jusqu'à 4×, avant-bras à 2 dp des doigts, nom au toucher une fois zoomé (« Brachio-radial (droit) · Avant-bras »), déplacement à deux doigts, retour 1× par double toucher et par le bouton Dos ; fiche curl poignet (clair) : glisser vertical sur le mannequin = page défilée de 134 dp sans zoom, pincement = zoom 3× sans défilement ; menus « Filtres » de la bibliothèque, du catalogue WOD et de l'Anatomie ouverts puis leurs puces, sombre et clair. Captures regardées.

## M4c.3 — Limites

- Le zoom agrandit l'image (angle de champ) : la perspective ne change pas en zoomant, la caméra ne s'approche pas du modèle.
- Le menu « Filtres » s'ouvre par-dessus le haut de l'écran et le bouton ; il se ferme en touchant en dehors.
- Anatomie : « Muscles profonds » et « Os » ne sont pas mis en puces (cochés par défaut, ils repousseraient les boutons de vue) ; ils restent dans le menu et dans le résumé sous le mannequin.
- `build-apk.yml` se déclenche aussi sur `claude/ci-3d` (build signé de contrôle), comme avec le ZIP.

## M4c.4 — Écrans qui filtraient une liste ou un affichage

| Écran | Avant (5.3.1) | Après (5.3.2) | Mémorisation |
| --- | --- | --- | --- |
| Arsenal › Exercices (bibliothèque et recherche) | 4 listes déroulantes à choix unique (Type de mouvement, Lieu, Matériel, Difficulté ; « Tous ») | Menu : Type de mouvement, Lieu, Matériel, Difficulté (plusieurs choix par catégorie) | aucune → pendant la session |
| Choix d'exercice (séance perso, `pickExercise`) | 2 rangées de puces à choix unique (groupe, matériel) | Menu : Groupe musculaire, Matériel | aucune → pendant la session |
| Arsenal › Catalogue WOD | puces rapides (Abordables, Poids de corps, 5 formats, < 15 min) + panneau en feuille (Accès à choix unique, Format, Mouvements, Difficulté, Durée, Matériel, Source) + puces des filtres actifs | Menu : Accès (Débloqués, Abordables, Verrouillés, à cocher), Format, Mouvements, Difficulté, Durée estimée, Matériel, Source ; puces sous le bouton | aucune → pendant la session |
| STATS › Historique | 3 puces à choix unique (Tout, Séances, WOD) | Menu : Type (Séances, WOD ; aucune case = tout) | état de l'onglet → pendant la session |
| Arsenal › Anatomie | menu de cases (M4b) : 11 groupes, Muscles profonds, Os | Menu commun : Groupes musculaires, Affichage (Muscles profonds, Os) | pendant la session (inchangé) |

Restent tels quels (pas des filtres) : onglets et rubriques de STATS, branches de la progression, semaines de l'accueil, tri du catalogue WOD, vue Face / Dos du mannequin, et les choix qui sont des réglages ou des saisies (durée et motif d'un échange d'exercice, lieu d'une séance adaptée, découpage et mouvement ciblé du générateur de programme, questionnaires du profil, Koach, avis de test, objectif hebdomadaire). Aucun écran n'a gardé de filtre à choix unique : les anciens choix uniques sont devenus des cases (cocher une seule case donne le même résultat).

# Historique — pipeline « Mannequin 3D », lot M4b (5.3.1)

## M4b.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M04b.txt` : tous les muscles remis, rendus à 50 % d'opacité partout, toucher à travers la transparence, filtres à cocher et petite refonte de l'écran Anatomie |
| Base | `main` `acb5034` (5.3.0+75) |

## M4b.1 — Changements

- **`tools/anatomy/build_model.py`** : plus aucun muscle retiré ; la mesure de visibilité de M2 (inchangée) classe les 21 paires cachées au repos (`caches_au_repos`, couche « profond », décimation × 0,85, 80 triangles au moins) ; platysma remis (gauche / droit, groupe Dos). Muscles déjà présents identiques à 5.3.0. Budget 75 000 : 62 506 triangles (muscles 47 138 dont cachés 5 748, os 7 000, contexte 2 968, tête 2 600, mains et pieds 2 800), GLB 1,29 Mo, 227 maillages (183 avant). Couche « profond » : profond selon Z-Anatomy ou caché au repos (76 régions sur 224).
- **`tools/anatomy/render_preview.py`** : `--opacite`, plusieurs groupes, `--regions`.
- **`lib/mannequin_3d.dart`** : `kMuscleOpacity = 0.5` ; muscles en `AlphaMode.blend` (tri arrière → avant par image, sans écriture de profondeur, faces arrière éliminées : rendu natif de flutter_scene 0.23), émission divisée par l'opacité (couleur de la rampe et halo gardés) ; régions masquées (`hidden`) et os imposés (`bones`) ; toucher : premier obstacle opaque, muscle mis en évidence le plus proche sinon le plus proche ; bulle « (profond) ».
- **`lib/anatomy_screen.dart`** : bouton « Filtres · n » et menu de cases à cocher (11 groupes en union, « Muscles profonds », « Os », Tout cocher / Tout décocher), fermeture au toucher en dehors, filtres gardés pendant la session (`AnatomyFilters`, `AnatomyScreen.session`) ; mannequin aussi haut que l'écran le permet, boutons de vue dessous, résumé des groupes cochés (muscles profonds signalés).
- **`lib/exercise_mannequin.dart`** : `musclesSansRegion` réduit aux 3 muscles absents du modèle source.
- **CI 3D** : `integration_test/anatomie_m4b_test.dart` ; émulateur en 540 × 960 ; cibles des lots précédents sur demande (`CI3D_TOUT=1`).
- Version 5.3.1+76.

## M4b.2 — Contrôles

- CI 3D run 36408180487 : formatage, analyse sans remarque, 910 tests Dart réussis (13 ignorés, 0 échec), tests Python (dont `test_m2_anatomy.py` étendu : aucune région retirée, toutes les régions de la source dans le modèle, chaque muscle du pack couvert sauf les 3 absents du modèle, couches, budget), `verify_project.py`, `package_release.py --check`, builds debug et profile. (`visual_capture_test.dart` échoue avant comme après, depuis 2.5.0, hors lot.)
- `test/m4b_anatomie_test.dart` : règle du toucher (rayon synthétique : sollicité caché, arrêt à l'os, os masqués, régions masquées, main opaque, opacité 1), libellé « (profond) », filtres (union, compteur, tout cocher / décocher, muscles profonds, os) à 390 px et à 320 px avec texte à 200 %, cases lues par l'accessibilité (libellé, état coché), filtres gardés pendant la session.
- Émulateur Android 15 (Flutter GPU, OpenGL ES) : muscles profonds seuls allumés (rhomboïdes, vaste intermédiaire, subscapulaire, petit pectoral) visibles à travers les autres sous les 4 vues en sombre, dos et face en clair ; rotation par 6 petits pas sans muscle qui disparaît ni clignote (part de rouge 0,63 à 0,67 %) ; toucher d'un rhomboïde : « Petit rhomboïde (droit) (profond) · Dos » ; Anatomie avec Pectoraux + Dos + Quadriceps, menu ouvert, muscles profonds masqués, résumé, en sombre et en clair ; fiche rowing australien (rhomboïdes principaux) et STATS en transparence, sombre et clair. Captures regardées.
- Temps d'image de l'écran Moteur 3D, émulateur (rendu logiciel, debug), avant (muscles opaques, sans les muscles cachés : rendu 5.3.0) / après : 2 200 / 2 472 ms (run 36403295133), 1 142 / 1 122 ms (run 36406347888), 2 421 / 2 770 ms (run 36408180487) ; écart de 0 à +14 %, dans le bruit de l'émulateur. Le téléphone du propriétaire (120 images/s en 5.0.0) reste la mesure qui compte.
- Rendus des écrans avant / après : identiques sauf l'heure du catalogue WOD (comme depuis M2).

## M4b.3 — Limites

- Tri des surfaces translucides par maille (centre de la maille) : là où deux grands muscles se chevauchent, l'ordre peut être approximatif ; à 50 % d'opacité et en gris, l'écart ne se voit pas sur les captures.
- Muscles profonds allumés seuls : bien visibles en sombre, plus discrets en thème clair (fond clair).
- Écran Anatomie : glisser sur le mannequin le fait tourner ; la page défile en glissant sur les filtres, les boutons de vue ou le texte.
- Fléchisseurs cervicaux profonds, diaphragme et plancher pelvien restent absents (aucune pièce dans le modèle source).

# Historique — pipeline « Mannequin 3D », lot M4 (5.3.0)


**Passe précédente : pipeline « Mannequin 3D », lot M4 (STATS : résumé hebdomadaire sur le mannequin), version 5.3.0**  
**Date : 28 septembre 2026, Europe/Paris — version : 5.3.0+75 (versionCode réel fixé par la CI de build)**  
**Statut : contrôlé en CI (branche temporaire `claude/ci-3d`, rendu réel sur émulateur Android).**

## M4.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M04.txt` : résumé hebdomadaire de STATS sur le mannequin 3D, mêmes chiffres que la carte 2D, bascule Face / Dos, légende chiffrée, STATS fluide au défilement, repli 2D |
| Base | `main` `2fd86d2` (5.2.0+74) |

## M4.1 — Changements

- **`lib/stats_mannequin.dart`** (nouveau) : `WeeklyMannequin` (mannequin de STATS, bascule Face / Dos, rotation horizontale, frontière de dessin, libellé d'accessibilité qui nomme les groupes de la semaine, repli `MuscleHeatmap` identique à 5.2.0) et `weeklyRegionIntensities` (chaque muscle prend l'intensité de son groupe ; mains et pieds restent sombres).
- **`lib/muscle_body.dart`** : normalisation de la carte extraite sans changement (`heatmapIntensities`, seuil `kHeatmapMinIntensity` = 2 %), partagée par la carte 2D et le mannequin ; `MuscleLegend(values: true)` écrit la valeur de chaque groupe (« Dos · 16 », une décimale à la française).
- **`lib/stats_performance.dart`** : `WeeklyMannequin` à la place de `MuscleHeatmap` ; légende chiffrée et ligne d'explication du calcul ; message de semaine vide inchangé.
- **`lib/mannequin_3d.dart`** : boutons de vue au choix (`views`, défaut : les 4 vues ; STATS : Face / Dos).
- **CI 3D** : cible `integration_test/stats_semaine_test.dart`, lancée en premier sur l'émulateur.
- Version 5.3.0+75.

## M4.2 — Contrôles

- CI 3D run 36393809265 (essai 2) : formatage, analyse sans remarque, 894 tests Dart réussis (13 ignorés, 0 échec), tests Python, `verify_project.py`, `package_release.py --check`, builds debug et profile.
- `test/m4_stats_mannequin_test.dart` : intensités par région comparées chiffre à chiffre à la normalisation de 5.2.0 (6 jeux de données, semaine type du store, semaine vide) ; chaque groupe a des muscles sur le mannequin ; mains et pieds sombres ; format de la légende ; onglet Performances sombre / clair, semaine type (carte de repli avec les mêmes données, hauteur 220, légende chiffrée) et semaine vide, sans exception.
- Émulateur Android 15 (`integration_test/stats_semaine_test.dart`) : semaine type (8 groupes, 132 régions allumées) en Face et en Dos, sombre et clair (figure, gris, rouge contrôlés), rotation, légende ; semaine vide sombre et clair (aucun pixel rouge). Captures regardées.
- Défilement de STATS, mannequin à l'écran (émulateur, rendu logiciel, build debug) : 46 images, fil UI médiane 2,4 ms (p90 15,5) ; rotation du mannequin (scène redessinée à chaque image) : fil UI médiane 116 ms, image complète médiane 1,8 s. Le défilement ne redessine donc pas la scène : pas besoin d'image fixe mise en cache.
- Rendus des écrans avant / après : 45 identiques, 2 différents (heure du catalogue WOD, comme en M2-M3).
- Cibles émulateur des lots précédents : Moteur 3D et Anatomie réussis ; fiche exercice (M3) non jouée, émulateur hors ligne (« device offline ») aux deux essais, sans lien avec le code (la fiche n'utilise pas le nouveau paramètre).

## M4.3 — Limites

- Coloration par groupe : tous les muscles d'un groupe prennent la même intensité (ex. groupe Dos : trapèzes, grand dorsal, mais aussi muscles du cou, rattachés au dos depuis M2).
- Après une rotation au doigt, le bouton Face / Dos reste sur la dernière vue choisie.
- Thème clair : rampe bordeaux → rouge peu contrastée entre groupes proches ; la légende chiffrée fait foi.

# Historique — pipeline « Mannequin 3D », lot M3 (5.2.0)

**Passe précédente : pipeline « Mannequin 3D », lot M3 (fiche exercice : mannequin fixe avec les muscles de l'exercice), version 5.2.0**  
**Date : 28 septembre 2026, Europe/Paris — version : 5.2.0+74 (versionCode réel fixé par la CI de build)**  
**Statut : contrôlé en CI (branche temporaire `claude/ci-3d`, rendu réel sur émulateur Android).**

## M3.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M03.txt` : mannequin 3D fixe dans la fiche exercice, muscles du pack par rôle, vue de départ selon les principaux, liste en texte conservée, repli 2D, mesure de 20 ouvertures |
| Base | `main` `f29e880` (5.1.0+73) |

## M3.1 — Changements

- **`lib/exercise_mannequin.dart`** (nouveau) : `ExerciseMannequin` (fiche), `ExerciseMuscleMap` (muscles du pack → régions : principal 1, secondaire 0,62, stabilisateur 0,35 ; étirés à part ; muscles sans région), `exerciseStartView` et `muscleFaces` (face antérieure / postérieure / latérale des 81 muscles du pack), `musclesSansRegion` (12 muscles profonds ou internes, raison pour chacun).
- **Fiche exercice** (`lib/exercise_screens.dart`) : `ExerciseMannequin` à la place de `ExerciseAtlas` ; la carte 2D historique devient le repli sans Flutter GPU (identique) ; légende des rôles et liste en texte inchangées ; démonstration 2D inchangée.
- **`lib/mannequin_3d.dart`** : régions étirées (`stretched`, teinte `mannequinStretch` : #5B8DB0 en sombre, #346C92 en clair, sans halo) ; repli fourni par l'écran (`fallback`) ; rotation au doigt seulement horizontale (`horizontalDragOnly`) ; modèle chargé une fois par lancement puis copié (`Node.clone`) pour chaque mannequin.
- **Légende** (`AtlasRoleLegend`) : pastille « Étiré » dans la teinte du mannequin quand il est affiché.
- **CI 3D** : cible `integration_test/fiche_exercice_test.dart` (6 fiches sombre et clair, étirés, profonds, toucher, rotation, 20 fiches d'affilée) ; la mesure M2 des organisations n'est plus relancée (sur demande : `CI3D_MESURE=1`).
- Version 5.2.0+74.

## M3.2 — Contrôles

- CI 3D run 36381559870 (essai 3) : formatage, analyse sans remarque, 884 tests Dart réussis (13 ignorés, 0 échec), tests Python, `verify_project.py`, `package_release.py --check`, builds debug et profile.
- `test/m3_fiche_mannequin_test.dart` : 625 exercices, plus de 12 000 muscles contrôlés → région ou raison (12 muscles profonds ou internes justifiés) ; chaque exercice montre au moins une région ; étirés prioritaires ; règle de vue (cas et catalogue) ; légende ; fiche sans Flutter GPU (carte 2D) ; échantillon de 50 fiches sombre / clair sans exception.
- Émulateur Android 15 (`integration_test/fiche_exercice_test.dart`) : 6 fiches (traction, dips, soulevé de terre roumain, planche, front lever tuck, curl haltères) sombre et clair, vue de départ conforme à la règle, gris / rouge / halo contrôlés ; étirés en bleu (étirement des fléchisseurs de hanche, sombre et clair) ; muscles profonds listés (rowing australien) ; toucher « Grand dorsal (droit) · Dos », aucune bulle réglage désactivé ; rotation horizontale. Captures regardées.
- 20 fiches d'affilée : mannequin prêt dès qu'il arrive à l'écran (médiane 1 ms, max 5 ms après l'arrivée ; création d'un mannequin 0-1 ms, modèle en mémoire) ; mémoire du processus stable (460 Mo au départ, 459 Mo après 20 fiches, build debug).
- Rendus des écrans avant / après : 45 identiques, 2 différents (heure affichée dans le catalogue WOD, comme en M2).

## M3.3 — Limites

- Muscles profonds (sous-scapulaire, supra-épineux, rhomboïdes, court adducteur, carré des lombes, multifides, petit pectoral, tibial postérieur, supinateur) et internes (fléchisseurs profonds du cou, diaphragme, plancher pelvien) : nommés sous le mannequin, pas colorés.
- Vue de départ par règle simple (face des muscles principaux) : mixte → 3/4 avant, même quand le dos domine (traction) ; l'utilisateur peut tourner le mannequin ou choisir une vue.
- Thème clair : la rampe historique (bordeaux → #A61717) distingue peu principal, secondaire et stabilisateur ; la liste en texte fait foi.

# Historique — pipeline « Mannequin 3D », lot M2 (5.1.0)

**Passe précédente : pipeline « Mannequin 3D », lot M2 (modèle anatomique d'exécution et écran Anatomie), version 5.1.0**  
**Date : 28 septembre 2026, Europe/Paris — version : 5.1.0+73 (versionCode réel fixé par la CI de build)**  
**Statut : contrôlé en CI (branche temporaire `claude/ci-3d`, rendu réel sur émulateur Android).**

## M2.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M02.txt` : modèle anatomique d'exécution, widget `Mannequin3D`, écran Anatomie, Réglages › Affichage 3D, crédits CC BY-SA, écran Moteur 3D sur le mannequin |
| Base | `main` `fe96d19` (5.0.0+72) |
| Source du modèle | slfresh/fitmitwith-anatomy-atlas, commit 4120ee6 (Z-Anatomy / BodyParts3D, CC BY-SA 4.0), SHA-256 vérifié |

## M2.1 — Changements

- **Fabrication du modèle** (`tools/anatomy/build_model.py`, relançable, Blender sans interface ; données dans `anatomy_data.py`, aperçu `render_preview.py`, rapport `build_report.json`) : aponévrose des obliques écartée de devant le droit de l'abdomen ; muscles profonds invisibles retirés par une mesure de visibilité (rayons depuis 58 directions, retrait symétrique : 21 muscles × 2 côtés, liste dans `muscles_map.json`) ; tête, mains et pieds remplacés par des volumes sombres lisses de même encombrement (tendons distaux fondus dans les volumes) ; platysma et bandelette ilio-tibiale retirés ; os et contexte invisibles retirés ; décimation à **56 126 triangles** (budget 60 000), GLB 1,1 Mo.
- **Carte** `assets/anatomy/muscles_map.json` : 180 régions (176 muscles gauche/droite, 2 mains, 2 pieds), nom français, côté, groupe parmi les 11 de l'application, muscles du pack ; tous les muscles superficiels du pack ont une région.
- **Build hook** `hook/build.dart` : conversion du GLB en `.fsceneb` par flutter_scene (`flutter_scene_generated/`, jamais livré) ; dépendance directe `hooks`.
- **`lib/mannequin_3d.dart`** : widget `Mannequin3D` (chargement unique, vues Face / Dos / Profil / 3/4 avec transition, rotation au doigt, rendu à la demande, intensités par région dans la rampe historique, halo en sombre, os et halo selon les réglages, nom au toucher dans une bulle, repli 2D `MuscleHeatmap` sans Flutter GPU) ; carte `MannequinMap` (groupes, muscles du pack, noms) ; réglages `Display3DSettings`.
- **Écran Anatomie** (`lib/anatomy_screen.dart`) : Arsenal › Référence › Anatomie ; 11 groupes à mettre en évidence, vue de départ selon le groupe, liste des muscles en texte.
- **Réglages › Affichage 3D** : « Nom du muscle au toucher », « Os visibles », « Halo » (activés ; préférences de l'appareil, hors sauvegarde).
- **Sources et licences** : `assets/anatomy/ATTRIBUTION.md` (crédits exacts) en tête des mentions.
- **Moteur 3D** : le rendu mesuré est le mannequin (rotation lente, muscles d'une traction).
- **CI 3D** : captures Anatomie sombre / clair / toucher / sans os, cible séparée pour la mesure des organisations, publication sans rebase, délai de l'émulateur 90 min.
- Version 5.1.0+73.

## M2.2 — Contrôles

- CI 3D : voir la livraison M2 (`pipeline/3d/livraisons/LIVRAISON_M2.md`) pour le run final.
- Tests : `test/m2_mannequin_test.dart` (carte, pack, groupes, rampe, repli 2D, écran Anatomie 390 / 320 px et texte 100 / 200 %, Arsenal, Réglages, mentions, intersection rayon-triangle), `tools/tests/test_m2_anatomy.py` (SHA-256, budget, nœuds ↔ régions, groupes, pack, crédits, pubspec), `integration_test/moteur_3d_test.dart` et `mannequin_mesure_test.dart` (émulateur).

## M2.3 — Limites

- Modèle non relu par un spécialiste de l'anatomie ; couleurs = repères d'entraînement.
- Muscles profonds retirés (sous-scapulaire, rhomboïdes, petit pectoral…) : leur nom reste dans les listes en texte, ils ne s'allument pas sur le mannequin.
- Fluidité de la CI non représentative (émulateur logiciel) ; la mesure du téléphone (Réglages › À propos › Moteur 3D) porte désormais sur le mannequin.

# Historique — pipeline « Mannequin 3D », lot M1 (5.0.0)

## M1.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/3d/prompts/M01.txt` : Flutter ≥ 3.47, Flutter GPU, CI 3D avec captures sur émulateur, écran « Moteur 3D » ; application inchangée pour l'utilisateur |
| Base | `main` `7f07e2e` (4.3.1+71) |
| Moteur | flutter_scene 0.23.0 (Flutter GPU sur Impeller), décision du propriétaire du 27/09/2026 |
| Outils | pas de Flutter local : tout passe par `.github/workflows/ci-3d.yml` (voir `docs/CI_3D.md`) |

## M1.1 — Changements

- **Flutter 3.29.3 → 3.47.5** (Dart 3.13.4), dernière stable. `build-apk.yml` : seule la version épinglée change (signature, secrets, contrôles inchangés).
- **Android** : minSdk 21 → **24** (Flutter 3.47 refuse moins de 23 et vise 24 ; `verify_android_artifacts.py` et son test suivent), Gradle 8.13 → 8.14.3 (minimum de Flutter 3.47), Kotlin 2.2.10 → 2.3.20 (minimum 2.2.20) avec `compilerOptions` au lieu de `kotlinOptions`, bibliothèques natives compressées dans l'APK (`useLegacyPackaging`, comme avant M1 : sinon l'APK universel gagnait ~40 Mo), AGP 8.12.1 conservé (minimum 8.11.1 ; AGP 9 imposerait la nouvelle DSL), `gradle.properties` : `android.newDsl=false` et `android.builtInKotlin=false` écrits par le migrateur de Flutter. `ShareProvider.kt` : type explicite demandé par Kotlin 2.3. Identifiant, signature et permissions inchangés.
- **Dépendances** : flutter_scene ^0.23.0, flutter_gpu (SDK), vector_math ^2.1.4 (directe). `integration_test` n'est ajouté que par la CI 3D (sinon Flutter 3.47 le référence dans l'APK release). Verrou régénéré (versions majeures conservées, 29 paquets mis à jour dans leurs contraintes).
- **Adaptations à Flutter 3.47** (dépréciations devenues visibles à l'analyse, sans changement de comportement) : `RadioGroup` pour les choix radio (thème, ton de Koach, WOD terminé/incomplet), `initialValue` des listes déroulantes (même comportement que `value`), `onReorderItem` (index déjà corrigé) dans l'éditeur de séance, `TickerMode.getValuesNotifier`, import de `CupertinoPageTransitionsBuilder` depuis cupertino, `isSemantics` dans deux tests. Formatage Dart 3.13 appliqué (tout le code).
- **Flutter GPU** activé dans le manifeste (`EnableFlutterGPU`), Impeller reste le moteur par défaut (contrôlé par `verify_project.py`).
- **Réglages › À propos › Moteur 3D** (`lib/engine3d.dart`) : rendu test flutter_scene (icosaèdre à facettes, gris mat #8F8B8A, calotte au rouge du haut de la rampe `heat(1)` — #E85959 en sombre, #A61717 en clair —, halo par bloom limité au rouge, fond de scène de la page de référence) ; rotation lente automatique (arrêtée si les animations sont réduites) et rotation au doigt avec élan ; diagnostic « Compatible / Non compatible », Flutter GPU, API graphique réellement choisie par Impeller (lue dans le journal du processus), appareil, version d'Android ; mesure de 10 s (`FrameTiming.totalSpan`) : images/s, moyenne, 99e centile, seuil de fluidité 45 images/s ; sans Flutter GPU, message clair et aucune exception.
- **CI 3D** : `.github/workflows/ci-3d.yml`, `tools/ci3d_drive.sh`, `integration_test/moteur_3d_test.dart`, `test_driver/integration_test.dart`, méthode dans `docs/CI_3D.md`.
- Version 5.0.0+72 (`pubspec.yaml`, `kAppVersion`).

## M1.2 — Contrôles

- CI 3D `claude/ci-3d` (Flutter 3.47.5) : `dart format --set-exit-if-changed` sans changement (lib, test, integration_test, test_driver), `flutter analyze` sans problème, suite Dart complète 856 réussis / 13 ignorés / 0 échec, Python 82/82 (1 ignoré), `verify_project.py`, `package_release.py --check`, build debug.
- Rendu réel sur émulateur Android 15 (API 35, x86_64, `-gpu swangle_indirect`) : « Compatible », Flutter GPU disponible, Impeller en OpenGL ES ; captures regardées (sombre, rotation, mesure, clair, entrée Réglages) : gris mat, calotte rouge de la rampe, halo rouge en sombre, fonds de la page de référence. Contrôles sans référence dans le test (part de la figure, gris, rouge, couleurs).
- Rendus de test avant (3.29.3, main) / après (3.47.5) : 47 paires, 4 identiques, 43 avec de petites différences de tracé (anticrénelage, flou de la barre de navigation, points de suspension, teinte d'un bouton désactivé) ; les plus différentes regardées : aucune régression visible.
- Nouveaux tests : `test/m1_engine3d_test.dart` (mesure, fenêtre sur l'horloge du moteur, repli sans Flutter GPU à 390 et 320 px, texte 100 et 200 %, accès depuis À propos), `integration_test/moteur_3d_test.dart` (émulateur).

## M1.3 — Limites

- Fluidité non représentative en CI : l'émulateur rend en logiciel (≈ 1 image/s en debug) ; la mesure qui compte est celle du téléphone du propriétaire.
- `test/visual_capture_test.dart` (captures facultatives, `KALIS_CAPTURE`) échoue déjà sur main avant M1 (onglet STATS réorganisé depuis 2.5.0) ; non corrigé dans ce lot.
- Android 5 et 6 ne sont plus pris en charge (exigence de Flutter 3.47).
- flutter_scene 0.23 ne permet pas de basculer le rendu continu d'une vue montée ; l'écran Moteur 3D rend en continu (voir `pipeline/3d/DECISIONS_3D.md`).

# Historique — refonte muscles et animations (4.3.1)

## Refonte MA.0 — Base et demande

| Élément | Valeur |
| --- | --- |
| Demande | `pipeline/prompt_REFONTE_MA.txt` (27/09/2026) : carte musculaire en illustrations historiques (STATS inclus), vue de profil tirée de l'image fournie par le propriétaire, toutes les démonstrations refaites avec ces illustrations |
| Base | `main` `1a39f91` (4.3.0+70, L13). Travail commencé sur 4.1.0, remis sur 4.2.0 (4.2.1, build n°92) puis réappliqué sur les **sources** du ZIP 4.3.0 : les 26 fichiers modifiés par L13 sont conservés (seuls README, SUIVI et la version sont communs, fusionnés à la main) |
| Reprise de Codex | branche `codex/retablir-carte-musculaire-et-animations` (`codex_export/`, reconstruit par `reconstruct.py`, SHA-256 vérifiés) : 18 PNG de 3.1.0 (identiques octet pour octet à 3.1.0), carte des fiches agrégée par groupes. **Non repris** : sa vue de profil (blocs polygonaux) et son formatage (autre version de Dart) |
| Outils | pas de Flutter local (proxy) : contrôles et rendus en CI (Flutter 3.29.3) ; outils d'images en Python (numpy, scipy, Pillow) |

## Refonte MA.1 — Changements

- **Carte (STATS, accueil, WOD)** : `lib/muscle_body.dart` revient au rendu 3.1.0 (image de base + calques modulés par `heat()`, halo). Nouveaux paramètres optionnels `views` (défaut face + dos, comme 3.1.0) et `normalize` (défaut vrai). `heatAtlasFills` est **conservée** (atlas vectoriel du pack, testé par `l9b_content_test.dart`) : aucune assertion retirée.
- **Fiche exercice** (`lib/atlas.dart`) : `ExerciseAtlas` affiche face / dos / profil ; les 81 muscles de l'atlas sont agrégés en 11 groupes (principal 1, secondaire 0,62, stabilisateur 0,35, étiré 0,25 ; le plus fort l'emporte), sans normalisation ; légende par la rampe ; liste texte inchangée.
- **Profil** (`tools/muscles_profile.py`, source `tools/sources/profil_source_chatgpt.png`) : alpha opaque dans le corps et bords teintés du noir du contour (aucun liseré), recadrage, 760 px de haut (142 px de large), marges de 8 px comme la face ; niveaux de gris par une courbe monotone passant par des points appariés des histogrammes (noir des contours 49 → 44, muscles q5/q50/q95/q99,5 → face/dos) ; 11 calques par segmentation des pièces claires (points-graines relevés sur la planche de contrôle ; codage des calques identique à la face : gris = 0,877 × base + 89,5). `meta.json` complété.
- **Démonstrations découpées** (`tools/anim_cutout.py` → `assets/muscles/anim/`, `lib/pose_cutout.dart`) : 16 segments de face et de dos, 10 de profil (bras et jambe du côté proche, réutilisés assombris pour le côté éloigné). À chaque articulation, le segment proximal passe dessus avec un chapeau circulaire dégradé et le distal dessous avec un disque plein (pas de trou ni de cassure quand l'articulation plie). Flanc du tronc sous le bras et haut de cuisse sous la main redessinés dans le style de l'illustration (visibles seulement quand le bras bouge). Chaque os de l'illustration est amené sur l'os du modèle (longueur du modèle, largeur à l'échelle de l'illustration) ; tête, mains et pieds rigides. Coudes, poignets, genoux et chevilles tombent exactement sur les articulations du modèle (contacts et accessoires inchangés). Calques de groupes découpés avec leurs segments, colorés par la rampe de la carte. `PosePainter` garde la silhouette vectorielle en secours (atlas absents) ; `PoseRoles` inchangé.
- **Choix de vue** (`cutoutViewOf`) : gabarit de profil → profil ; gabarit de face → **dos** si les muscles principaux postérieurs (trapèzes, dorsaux, érecteurs, carré des lombes, triceps, grand fessier, ischios, mollets…) sont plus nombreux que les antérieurs (muscles latéraux non comptés), sinon face. Résultat : 584 profil, 21 face, 2 dos (side bend, planche latérale avec abduction). La vue de dos rejoue la cinématique de face en miroir avec l'illustration de dos.
- **Revue de toutes les démonstrations** (planches d'images clés de 607 exercices rendues par le vrai code et regardées) : 18 exercices revus (`cutoutReviewOverrides`), le pack validé n'est pas modifié :
  - image fixe « haut » (position basse du pack : barre ou haltères derrière la tête) : développé couché, couché haltères, prise serrée, pause, décliné, incliné, incliné haltères, floor press, JM press, test 1RM développé couché, Tate press ;
  - image fixe (deux images clés identiques, aucun mouvement) : leg curl, leg extension ;
  - sans démonstration (contact essentiel absent) : presse à cuisses (plateau loin des pieds), sled push (mains loin du traîneau), rowing haltère appui poitrine (poitrine hors du banc), transition de muscle-up assistée pieds au sol (pieds en l'air), sauts en contrebas (pas de caisse).
  Le générateur de programme (L10) lit toujours le statut du pack (références figées des tests L10) : ces 18 exercices y restent « animés ».
- Version 4.3.1+71 (`pubspec.yaml`, `kAppVersion`).

## Refonte MA.2 — Contrôles

- CI `claude/ci-refonte` (Flutter 3.29.3) : `dart format --set-exit-if-changed` sans changement, `flutter analyze` sans problème, suite complète 846 réussis / 13 ignorés / 0 échec (4.3.1), Python 82/82 et `verify_project.py`.
- Nouveaux tests (`test/refonte_ma_test.dart`) : PNG et calques présents, calques alignés au pixel et dans la silhouette, profil sans liseré, muscles → groupes et intensités par rôle, **STATS identique au pixel à 3.1.0** (copie conforme du widget 3.1.0 dans `test/support/muscle_body_310.dart`, sombre et clair, avec et sans halo), choix de vue, segments posés exactement sur les articulations, rendu sans exception des 607 animations, exercices revus, coût (≈ 430-620 images/s en test, textures décodées des trois vues 6,3 Mo). `tools/tests/test_refonte_muscles.py` : atlas et gabarits cohérents.
- Rendus de revue et d'aperçu (`test/refonte_ma_capture_test.dart`, seulement avec `KALIS_CAPTURE`).

## Refonte MA.3 — Limites

- Rien n'est vérifié sur téléphone ; le coût mesuré est celui du moteur de test.
- Les zones redessinées sous le bras (profil) sont une interprétation dans le style de l'illustration, pas l'image du propriétaire.
- Les proportions du modèle (bras plus longs que l'illustration) étirent un peu les bras et les cuisses.
- Défauts de contenu du pack relevés pendant la revue (à corriger dans le pack, proposition dans `pipeline/DECISIONS_EN_ATTENTE.md`) : les 18 exercices ci-dessus ; accessoires manquants sans fausser le geste (« banc incliné » des YTW, porte des rowings à la serviette).


# Historique conservé — L13 (4.3.0)

**Passe précédente : L13 — Santé, sécurité, conformité et test fermé (KT-072 à KT-078), version 4.3.0**  
**Date : 27 septembre 2026, Europe/Paris — version : 4.3.0+70 (versionCode réel fixé par la CI de build)**  
**Statut : lot L13 exécuté par le pipeline automatisé (sans échange en direct). Corrigé dans le code et testé automatiquement en CI (voir L13.3) ; build signé : `LIVRAISON_L13.md` ; rien n'est vérifié sur téléphone.**

## L13.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L13.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` ; dernier lot du pipeline | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **4.2.0+69** (L12), `main` `332e292`, 2 254 226 octets, SHA-256 `71f975ab02a7ae3b08593705752c6c8c8cbf8adcbca0e9583d75efa6eb5b6335` (identique à `LIVRAISON_L12.md`), racine unique `streetlift_tracker/` | Recalcul |
| Prérequis | L7 (Koach), L8 (profil, consentement, mode prudent), L9b (pack), L10, L11, L12 livrés | Sections ci-dessous |
| État initial | Arbre identique à celui du build signé L12 (run 90) : format, analyse, 809 réussis / 12 ignorés, Python 72/72, `verify_project.py` ; recherche d'allégations (nouvelle) : 4 occurrences | `LIVRAISON_L12.md`, `CONTRAT_L13.md` §5 |
| Outils | Pas de Flutter local (proxy) ; CI sur la branche temporaire `claude/ci-tools` ; Python 3.11 et Pillow locaux ; recherche web (pages d'aide Google Play, EUR-Lex) ; aucun téléphone | Constaté |

## L13.1 — Contrat

`docs/CONTRAT_L13.md` : base et contradictions (§1 : D26 « jamais l'arrêt » face aux signaux d'alerte, sauvegarde Android KT-016 face aux données de santé, réponses Koach hors consentement L8, allégation dans un asset figé, profil importé d'un mineur, URL de politique non fournie), 10 décisions par défaut (§2), règles (§3), aucune donnée nouvelle (§4), liste des termes interdits (§5), finalité hors règlement (UE) 2017/745 avec source et date (§6), tests (§7), limites (§8). Documents : `CONFIDENTIALITE.md` (cartographie finale), `GOOGLE_PLAY.md`, `REGISTRE_VALIDATION.md`, `TEST_FERME.md`.

## L13.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-072 | `kRecoveryTips` (6 conseils généraux, sans chiffre ni calcul, sans objectif de poids) ; écran « RÉCUPÉRATION » ; sommeil et forme Koach toujours facultatifs |
| KT-073 | `painStreak` / `painNeedsReferral` (purs), `painHistory` / `painReferralMovements` (store, ordre des dates de fin) ; renvoi vers un professionnel au-delà de 2 séances > 3/10 (bilan Koach, Santé et sécurité) ; signaux d'alerte (`kAlertSignals`, `kAlertAdvice`) ; entrée « Douleur ou malaise ? » dans les options de séance ; situations particulières (`kSpecialSituations`) reliées au mode prudent L8 ; écran « SANTÉ ET SÉCURITÉ » |
| KT-074 | `tools/check_claims.py` + test Python ; 4 occurrences corrigées (« Rapport technique » au lieu de « Diagnostic », note d'accessoire reformulée à l'affichage `kWellnessWording`) ; `kWellnessDisclaimer` sur le premier écran du démarrage (sous l'action) et dans « À propos » ; analyse de finalité (`CONTRAT_L13.md` §6) |
| KT-075 | Cartographie finale (`CONFIDENTIALITE.md`) ; politique embarquée `assets/legal/confidentialite.md` (écran « CONFIDENTIALITÉ ») ; libellé de l'export (données de santé comprises) ; `profileIsMinor` + écran « RÉSERVÉE AUX ADULTES » pour un profil importé de moins de 18 ans |
| KT-076 | `tools/generate_brand.py --play` → `docs/play/feature_graphic_1024x500.png` ; réponses Sécurité des données, santé, classification, public cible (`GOOGLE_PLAY.md`, sources datées ou « non vérifié ») |
| KT-077 | `docs/REGISTRE_VALIDATION.md` : 22 éléments, priorités P1-P3, limite V1 (pas de relecture), impact, prochaine action |
| KT-078 | Règle vérifiée (12 testeurs, 14 jours, comptes personnels créés après le 13/11/2023) ; invitation, mode d'emploi, scénarios par profil, tableau de suivi, critères de production (`TEST_FERME.md`) ; écran « DONNER MON AVIS » (formulaire local, aperçu exact, partage `shareText` par le menu Android, rien d'enregistré) |

Fichiers : nouveaux `lib/wellbeing.dart`, `lib/safety_store.dart`, `lib/wellbeing_screens.dart`, `assets/legal/confidentialite.md`, `docs/CONTRAT_L13.md`, `docs/GOOGLE_PLAY.md`, `docs/REGISTRE_VALIDATION.md`, `docs/TEST_FERME.md`, `docs/play/feature_graphic_1024x500.png`, `tools/check_claims.py`, `tools/tests/test_l13_compliance.py`, `test/l13_safety_test.dart`, `test/l13_screens_test.dart` ; modifiés `lib/store.dart` (partie `safety_store`, export de `wellbeing.dart`), `lib/models.dart` (`kWellnessWording`), `lib/profile_screens.dart` (avertissement, blocage des mineurs importés), `lib/settings_screen.dart` (entrées « À propos », libellé de l'export, version 4.3.0), `lib/session_screen.dart` (« Douleur ou malaise ? »), `lib/koach_screens.dart` (renvoi et signaux sous la douleur), `lib/notification_settings.dart` (« Rapport technique »), `android/app/src/main/kotlin/fr/tchoupi/streetlift_tracker/MainActivity.kt` (`shareText`), `tools/generate_brand.py` (`--play`), `docs/CONFIDENTIALITE.md`, `pubspec.yaml` (4.3.0+70, asset de la politique), `README.md`, ce suivi. Workflow `build-apk.yml` **inchangé**. Aucune dépendance, aucune permission ajoutée ; aucun test existant modifié.

## L13.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | Reformatage par la CI repris tel quel ; passage final : 150 fichiers, 0 changé | CI `claude/ci-tools`, commit `162d3a2` |
| Analyse | No issues found | idem |
| Suite complète | **835 réussis, 12 ignorés**, 0 échec (809 existants inchangés + 26 L13) | idem |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L12) | idem |
| Python | 79 tests : 78 réussis, 1 ignoré en CI (régénération du visuel : Pillow absent du runner ; rejouée localement avec Pillow : réussie ; l'en-tête PNG est contrôlé en CI) ; `verify_project.py` : 40 semaines, 1 812 exercices du programme, 625 exercices de la base ; `check_claims.py` : 0 allégation | idem + local |
| Android | `flutter build apk --debug` réussi avec le canal `shareText` (commit CI `67f1b44`) ; build signé : `LIVRAISON_L13.md` | CI |

Tests L13 : série de douleurs et renvoi (purs, puis ordre réel des séances, interruption par une séance sans douleur, affichage dans Santé et sécurité) ; signaux d'alerte ; **mode prudent pour chaque situation particulière** (grossesse, cœur/tension, 65 ans, gêne) ; conseils sans chiffre ; avertissement (finalité, aucun diagnostic, aucun résultat) au démarrage et dans « À propos » ; **consentement refusé → accordé → retiré** (état, mode prudent, export) ; **export puis suppression complète** des données de santé (profil, accord du médecin, stress, douleur Koach), puis suppression totale ; **profil importé de moins de 18 ans** bloqué (2012), accepté à 18 ans dans l'année (2008), déblocage après correction ; **retour de test sans donnée non choisie** (pur et par l'écran, partage simulé) ; écrans à 390 × 844 et 320 × 720, texte 100/130/200 %, clair et sombre, défilement par gestes lents réels ; **aucune allégation** (liste documentée, négations tolérées, concaténation Dart) ; visuel 1024 × 500 sans alpha.

Défauts trouvés par la CI et corrigés : `wellnessWording` non exporté dans le test ; avertissement placé au-dessus de « Commencer » qui cassait deux tests L8 existants → placé sous l'action (tests L8 inchangés) ; gestes rapides qui sautaient des cartes hautes à 200 % → défilement lent chronométré ; politique chargée avec le cache partagé de `rootBundle` (futur lié au test précédent) → chargement sans cache, une fois par écran, avec message d'erreur ; assertion trop large (le journal « profil modifié » garde le nom « clearance ») → contrôle de la section santé.

## L13.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-072 à KT-078 |
| Testé automatiquement | Voir L13.3 |
| Vérifié sur appareil | **Rien** (partage du retour de test, TalkBack compris) |
| Reste à valider | Essais téléphone (`LIVRAISON_L13.md`) ; décisions D-L13-01 à D-L13-10 (`docs/CONTRAT_L13.md` §2) ; registre de validation (lignes P1) ; réponses Google Play à saisir ; **URL publique de la politique** à fournir |

- Analyse « hors dispositif médical » et qualification RGPD non validées par un juriste.
- Classification IARC, public cible et déclaration de `SCHEDULE_EXACT_ALARM` : préparées, non vérifiées (Play Console).
- Captures d'écran du Play Store non produites (à faire sur téléphone).
- Branche temporaire `claude/ci-tools` toujours présente.

---

**Passe précédente : L12 — Motivation et progression visible (KT-065 à KT-071), version 4.2.0**  
**Date : 27 septembre 2026, Europe/Paris — version : 4.2.0+69 (versionCode réel fixé par la CI de build)**  
**Statut : lot L12 exécuté par le pipeline automatisé (sans échange en direct). Corrigé dans le code et testé automatiquement en CI (voir L12.3) ; build signé : `LIVRAISON_L12.md` ; rien n'est vérifié sur téléphone.**

## L12.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L12.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **4.1.0+68** (L11), `main` `b202121`, 2 198 067 octets, SHA-256 `e598e0fc4be71f25a198b324fcd1b25e9eedd5b0138af786621c6cfb6cf0ad78` (identique à `LIVRAISON_L11.md`), racine unique `streetlift_tracker/` | Recalcul |
| Prérequis | L7 (Koach), L8 (profil), L9b (pack), L10 (générateur), L11 (adaptation) livrés | Sections ci-dessous |
| État initial | Arbre identique à celui du build signé L11 (run 89) : format, analyse, 758 réussis / 12 ignorés, Python 72/72, `verify_project.py` | `LIVRAISON_L11.md` |
| Outils | Pas de Flutter local (proxy) ; CI sur la branche temporaire `claude/ci-tools` ; Python 3.11 local ; aucun téléphone | Constaté |

## L12.1 — Contrat

`docs/CONTRAT_L12.md` : base et contradictions (§1 : récompenses face à l'invariant économie, rappels face au réglage « Ignorer les jours de repos », ton du profil jamais utilisé, nom « Ma progression » déjà pris, parcours d'habitude face au générateur L10), 12 décisions par défaut réversibles (§2), règles (§3-7), **barème proposé non appliqué** (§5), format de la section `motiv` et absence de migration (§8), registre de validation (§9), limites (§10).

## L12.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-065 | `detailLevelFor`, `figureCount`, `pickVictories` (purs) ; victoires calculées depuis le journal (progrès depuis le départ, premières fois, étape franchie, semaines régulières) ; écran « MES PROGRÈS » (victoires / records et courbes simples / statistiques de Koach) ; STATS d'un débutant ou novice = victoires ; réglage « Afficher toutes les statistiques » ; poids facultatif, masquable, sans jugement |
| KT-066 | `ChainBook` (pack L9, `progressions.json.gz`), `chainProgress` (critère atteint, lest en % du poids de corps, déduction par étape plus avancée), `chainsForGoals` ; écrans « MES FIGURES » et détail de chaîne (icône et libellé par état, critère de passage) |
| KT-067 | Étapes réelles (records datés, étapes de chaîne, cycles terminés, paliers de régularité) ; `pendingMilestones` (récentes, jamais vues) ; célébration sobre sur l'accueil (fondu unique, immédiat si animations réduites) ; « ÉTAPES FRANCHIES » ; `weekRegularity` / `regularStreak` (jours de repos respectés comptés, pauses exclues) ; barème en crédits **proposé, non appliqué** (`kMilestoneRewardsApproved = false`), registre KT-005 inchangé |
| KT-068 | Bibliothèque `koachLine` (12 contextes × 3 tons × 3 groupes de niveau), sécurité neutre unique ; ton du profil L8 (ou section `motiv` sans profil) réglable dans Réglages → Motivation et progression |
| KT-069 | Bilan hebdomadaire (3 éléments, du lundi au dimanche suivant) et de fin de cycle (progrès, point fort, point à travailler, prochain objectif, projection Koach) sur l'accueil |
| KT-070 | `planReminders` : jamais un jour de repos (quel que soit l'ancien réglage), réglage « Ignorer les jours de repos » retiré de l'écran ; pause et permissions : règles L4/L11 inchangées |
| KT-071 | Image de partage (rendu sur l'appareil, contenu coché, poids décoché, aucune donnée de santé) partagée par le menu Android (`kalis_track/share`, `ShareProvider` en lecture seule, non exporté) ; parcours d'habitude (débutant, novice, 28 jours, compression L11 à 20 min, cible 2 séances, désactivable) ; séance « 10 minutes, ça compte » |

Fichiers : nouveaux `lib/motivation.dart`, `lib/motiv_store.dart`, `lib/motivation_screens.dart`, `android/app/src/main/kotlin/fr/tchoupi/streetlift_tracker/ShareProvider.kt`, `docs/CONTRAT_L12.md`, `test/l12_motivation_test.dart`, `test/l12_store_test.dart`, `test/l12_screens_test.dart` ; modifiés `lib/store.dart` (section `motiv`, chargement des chaînes), `lib/adapt_store.dart` (compression du parcours d'habitude), `lib/notifications.dart` (jamais un jour de repos), `lib/notification_settings.dart` (réglage retiré), `lib/home_screen.dart` (carte), `lib/settings_screen.dart` (entrée, version 4.2.0), `lib/stats_screen.dart` (victoires d'un débutant), `lib/stats_overview.dart` (entrée « Mes progrès »), `android/app/src/main/AndroidManifest.xml` (fournisseur de partage, aucune permission), `MainActivity.kt` (canal de partage), `pubspec.yaml` (4.2.0+69), `README.md`, ce suivi. Workflow `build-apk.yml` **inchangé**. Aucune dépendance ajoutée.

Tests existants adaptés (règle KT-070 voulue par le propriétaire, aucune assertion supprimée) : `test/notifications_test.dart` (changement d'heure contrôlé du samedi 24/10 au lundi 26/10 — 49 h — au lieu du dimanche 25/10 devenu sans rappel, et assertion ajoutée : aucun rappel le 25/10) ; `test/l4_depart_test.dart` (deux décomptes 280 → 240 rappels : les 240 journées d'entraînement des 40 semaines).

## L12.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | Reformatage par la CI repris tel quel ; passage final : aucun changement | CI `claude/ci-tools`, commit `0282f74` |
| Analyse | No issues found | idem |
| Suite complète | **809 réussis, 12 ignorés**, 0 échec (758 existants, dont 3 adaptés, + 51 L12) | idem |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L11) | idem |
| Python | 72/72 ; `verify_project.py` : 40 semaines, 1 812 exercices du programme, 625 exercices de la base | idem |
| Android | `flutter build apk --debug` : réussi (APK debug arm64 compilé, `ShareProvider` et canal de partage compris, commit CI `0282f74`) ; build signé : `LIVRAISON_L12.md` | CI |

Tests L12 : niveau de détail par profil (sans profil, débutant, novice, avancé, réglage) et **au plus 3 chiffres** sur l'écran entier défilé d'un débutant (8 variantes 390/320 px, 130/200 %, clair/sombre) ; poids affiché puis masqué, export sans section `motiv` par défaut ; record et étape de chaîne **célébrés une seule fois**, relance comprise, crédits inchangés, registre des gains sans étape L12 ; étape ancienne non célébrée ; **jour de repos respecté compté**, séance un jour de repos non pénalisée ; **séance de 10 minutes comptée** ; messages de sécurité identiques quel que soit le ton ; bibliothèque sans mot interdit ; bilans aux bornes dimanche 23:59 / lundi 00:01 et au lendemain du dernier jour du cycle ; **rappels jamais un jour de repos** (même avec l'ancien réglage à faux) ; **image de partage sans poids ni donnée de santé par défaut** ; parcours d'habitude (compression, cible, désactivation, fin après 28 jours) ; section `motiv` (relecture, import strict) ; célébration avec et sans réduction des animations ; chaînes mises en avant ; ton réglable ; STATS d'un débutant.

Défauts trouvés par la CI et corrigés : nom `StepState` en conflit avec Flutter (renommé `ChainStepState`) ; écrans constants non reconstruits après un réglage (poids, célébration) → `StoreWidget` ; normalisation du réglage de rappel à la lecture qui changeait l'état après relance (`l4_depart_test` comparaison avant/après) → règle déplacée dans la planification.

## L12.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-065 à KT-071 |
| Testé automatiquement | Voir L12.3 |
| Vérifié sur appareil | **Rien** (partage Android compris) |
| Reste à valider | Essais téléphone (`LIVRAISON_L12.md`) ; décisions D-L12-01 à D-L12-12 (`docs/CONTRAT_L12.md` §2) ; **barème des récompenses** (§5) ; registre de validation (§9) |

- Récompenses en crédits des étapes non appliquées tant que le barème n'est pas validé.
- Étapes de chaîne détectées seulement pour les exercices reconnus par le pack ; une tenue se saisit en secondes dans le champ « répétitions ».
- Branche temporaire `claude/ci-tools` toujours présente.

---

**Passe précédente : L11 — Koach étendu, adaptation au jour le jour (KT-058 à KT-064), version 4.1.0**  
**Date : 27 septembre 2026, Europe/Paris — version : 4.1.0+68 (versionCode réel fixé par la CI de build)**  
**Statut : lot L11 exécuté par le pipeline automatisé (sans échange en direct). Corrigé dans le code et testé automatiquement en CI (voir L11.3) ; build signé : `LIVRAISON_L11.md` ; rien n'est vérifié sur téléphone.**

## L11.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L11.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **4.0.0+67** (L10), `main` `5d38177`, 2 137 835 octets, SHA-256 `2cd7c9a595bc5a3eb293b587db708c26f826865d68d9fe902dee40a94850affc` (identique à `LIVRAISON_L10.md`), racine unique `streetlift_tracker/` | Recalcul |
| Prérequis | L7 (Koach), L8 (profil), L9b (pack), L10 (générateur) livrés | Sections ci-dessous |
| État initial | `lib/`, `test/`, `assets/`, `tools/` identiques à l'arbre du dernier passage CI de L10 (`dc9e3bd`) : format sans changement, analyse sans problème, 689 réussis / 12 ignorés, Python 72/72, `verify_project.py`, build debug | Comparaison de fichiers ; CI L10 |
| Outils | Pas de Flutter local (proxy) ; CI sur la branche temporaire `claude/ci-tools` ; Python 3.11 local ; aucun téléphone | Constaté |

## L11.1 — Contrat

`docs/CONTRAT_L11.md` : base et contradictions (§1 : « le plan glisse » face à la décision L4 « pas de décalage automatique », mode Guidé face à L7 D4, RIR facultatif face à L7 D8, « 2 cycles », séance de plus ou de moins sur le programme de 40 semaines, niveau novice du plateau, rappels pendant une pause), 14 décisions par défaut réversibles (§2), règles et paramètres (§3-8), format de la section `adapt` et absence de migration (§9), registre de validation (§10), limites (§11).

## L11.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-058 | `compressSession` (pur) : échauffement 3 min, prévention 1 série, accessoires enchaînés sans conflit musculaire, retrait des moins prioritaires, principaux vers 2/3 ; durées par exercice de `training_estimate.dart` ; menu de séance « J'ai seulement… minutes » avec aperçu des différences, application pendant la séance (séries validées gardées, journaux vides retirés), « Séance complète » |
| KT-059 | `swapCandidates` (pur) : même type, difficulté ±1, matériel, groupe commun, contrainte articulaire ≤ en cas de douleur, jamais détesté, 3 propositions classées ; charge prudente (`prudentLoad`) ; menus « Échanger un exercice » et « Je m'entraîne ailleurs » ; substitut journalisé `origine~pack` |
| KT-060 | Reprise (`resumeRule`, `resumeEpisode`, `resumeAppliesTo`) appliquée aux charges (`sessionLoad(..., day:)`) et séries des mouvements principaux ; plan qui glisse (`slideProposal`, départ décalé, annulable) ; pauses vacances et maladie (rappels suspendus, glissement au retour, semaine de maladie × 0,7 et RIR +1), séance d'entretien sans matériel ajoutée aux séances perso |
| KT-061 | Taux sur 4 semaines glissantes (`adherenceRate`, `adherenceAdvice`) ; cartes de l'accueil : une séance de moins (programme généré : jours du profil puis régénération L10) ou séances 20 % plus courtes ; une séance de plus |
| KT-062 | Estimation hebdomadaire par mouvement principal, `plateauDetected` (pente, assiduité, fatigue, décharge), intervention par niveau ; décharge programmée la semaine suivante (séries × 0,6, charges −10 %) |
| KT-063 | `autonomyAction`, `safetyApplied` ; Guidé : baisses et hausse nette appliquées après la série avec « Annuler », jour de fatigue appliqué, baisses acceptées au bilan (annulables) ; Expert : suggestion sans bouton ; écran « Adaptation au quotidien » (Réglages) ; profil migré jamais choisi → Assisté |
| KT-064 | Question de difficulté globale (débutant, novice ; Guidé, Assisté) ; charge = difficulté × durée ; prudence > 1,5 × moyenne des 4 semaines précédentes ; allègement de fin de semaine ; RIR facultatif pour ces profils |

Fichiers : nouveaux `lib/koach_adapt.dart`, `lib/adapt_store.dart`, `lib/adapt_screens.dart`, `docs/CONTRAT_L11.md`, `test/l11_adapt_test.dart`, `test/l11_store_test.dart`, `test/l11_screens_test.dart` ; modifiés `lib/store.dart` (section `adapt`, charges de séance, estimation de la séance adaptée), `lib/koach_store.dart` (modes, annulations, RIR facultatif, RIR +1 après maladie), `lib/models.dart` (`Exercise.adapted`, `role`, `exId`, `SetsSpec.withCount`, `DayPlan.adapted`), `lib/session_screen.dart` (séance adaptée, menu, bandeau, mode Guidé, question de fin), `lib/koach_screens.dart` (bilan : baisses appliquées d'office en Guidé), `lib/koach_widgets.dart` (suggestion sans bouton en Expert), `lib/home_screen.dart` (cartes), `lib/settings_screen.dart` (entrée, version 4.1.0), `lib/notifications.dart` (pause), `lib/session_history.dart` (exercices échangés retrouvés), `pubspec.yaml` (4.1.0+68), `README.md`, ce suivi. Workflow `build-apk.yml` **inchangé**. Aucune dépendance ajoutée. Aucun test existant modifié.

## L11.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | Reformatage par la CI repris tel quel ; passage final : aucun changement de code | CI `claude/ci-tools`, commit `57d48f6` |
| Analyse | No issues found | idem |
| Suite complète | **758 réussis, 12 ignorés**, 0 échec (689 existants inchangés + 69 L11) | idem |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L10) | idem |
| Python | 72/72 ; `verify_project.py` : 40 semaines, 1 812 exercices du programme, 625 exercices de la base | idem |
| Android | `flutter build apk --debug` : réussi (APK debug arm64 compilé, commit CI `57d48f6`) ; build signé : `LIVRAISON_L11.md` | CI |

Tests L11 : compression à 20, 30 et 45 minutes (durée respectée, principaux gardés ≥ 2/3, prévention à 1 série, paires sans conflit, monotonie, pendant la séance, durée impossible signalée, déterminisme) ; échange pour douleur sur trois types de mouvement (contrainte articulaire ≤ pour chaque articulation), exercice détesté exclu, charge prudente ; reprises à 7, 14 et 28 jours (bornes, une séance par mouvement, semaine de calibrage) dans le store ; maladie (pause, rappels suspendus, plan qui glisse, × 0,7 la première semaine) et vacances (séance d'entretien sans doublon) ; les trois seuils d'assiduité ; plateau vrai positif et aucun faux positif pendant une décharge, avec fatigue, assiduité faible ou progression ; les trois modes d'autonomie (table, changement, profil migré, annulation d'une baisse acceptée d'office, adaptation de reprise annulée) ; charge de séance et seuil de 1,5 (1,4 → rien, 1,6 → prudence) ; export identique sans adaptation, import strict ; **rejeu déterministe** : après reprise, compression et échange, relance du store → même séance (exercices, séries, charges) ; écrans (séance recomposée, Adaptation au quotidien, carte de pause, question de difficulté) à 390 × 844 et 320 × 720, texte 130 et 200 %, clair et sombre, défilement réel.

Défaut trouvé par la CI et corrigé : le bandeau d'adaptation (reprise proposée) occupait trop de hauteur dans l'en-tête de séance à 320 px et texte 200 % (`l7_koach_screens_test.dart` ne trouvait plus « Valider la série 1 ») → bandeau d'une ligne, détails et boutons dans une feuille. Une remarque d'analyse (accolades) corrigée.

## L11.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-058 à KT-064 |
| Testé automatiquement | Voir L11.3 |
| Vérifié sur appareil | **Rien** |
| Reste à valider | Essais téléphone (`LIVRAISON_L11.md`) ; décisions D-L11-01 à D-L11-14 (`docs/CONTRAT_L11.md` §2) ; registre de validation (§10) |

- Un exercice échangé n'alimente pas l'estimation Koach ; le plateau utilise sa propre estimation hebdomadaire.
- « Nouveau bloc orienté sur le point faible » après une décharge : régénération manuelle (Mon programme).
- Les WOD ne comptent pas comme jours d'entraînement pour la reprise.
- Branche temporaire `claude/ci-tools` toujours présente.

---

**Passe précédente : L10 — Générateur de programme personnalisé (KT-050 à KT-057), version 4.0.0**  
**Date : 27 septembre 2026, Europe/Paris — version : 4.0.0+67 (versionCode réel fixé par la CI de build)**  
**Statut : lot L10 exécuté par le pipeline automatisé (sans échange en direct). Corrigé dans le code et testé automatiquement en CI (voir L10.3) ; build signé : `LIVRAISON_L10.md` ; rien n'est vérifié sur téléphone.**

## L10.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L10.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **3.2.0+66** (L9b), `main` `6015ebc`, 2 031 485 octets, SHA-256 `699329b4824b2ceef27355c85a7310de73ec00c6a97d1984c031bed20f578f14`, racine unique `streetlift_tracker/` | Recalcul |
| Prérequis | L7 (Koach), L8 (profil), L9b (pack intégré) livrés | Sections ci-dessous |
| État initial | Arbre identique (lib, test, assets, tools) à celui du dernier passage CI de L9b : format 0 changement, analyse sans problème, 630 réussis / 12 ignorés, Python 69/69, `verify_project.py`, build debug | Comparaison de fichiers ; CI L9b (`claude/ci-tools`) |
| Outils | Pas de Flutter local (proxy) ; CI sur la branche temporaire `claude/ci-tools` ; Python 3.11 local ; aucun téléphone | Constaté |

## L10.1 — Contrat

`docs/CONTRAT_L10.md` : base et contradictions (§1 : repère du profil L8 et nouveaux seuils, niveau global, durée ±10 % face au plafond de volume, démonstrations animées, retour par muscle absent, D-L9b-09 laissée en attente), 13 décisions par défaut réversibles (§2), format de l'instance et migration (§3), règles et paramètres (§4-6), tests (§7), registre de validation (§8), limites (§9).

## L10.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-050 | `lib/program_generator.dart` : générateur pur (entrées + graine → programme au schéma `programme_v33`, annotations Koach, résumé), départage par hachage FNV-1a ; `assets/program_models.json` 1.0.0 (modèles en données) ; `lib/program_instance.dart` : `ProgramInstance` (persistée, exportée, contrôlée à l'import), fusion d'une régénération (`mergeWeeks`), aperçu (`diffWeeks`) ; `lib/program_store.dart` : instance implicite « Expert streetlifting » pour les installations existantes (programme embarqué inchangé), génération au départ d'un nouvel utilisateur, régénération, annulation, cycle suivant ; `lib/store.dart` : programme matérialisé depuis l'instance, section `programInstance` de la sauvegarde |
| KT-051 | Niveau par mouvement (pompes, tractions, squat, lests, charnière, gainage), niveau global = médiane basse ; calibrage en semaine 1-2, mini-tests en décharge ; points d'entrée et passages d'étape lus dans le journal (`progressFromLogs`) |
| KT-052 | Modèles linéaire, ondulation, blocs, Forme et santé, Expert streetlifting ; macrocycle daté avec simulations, affûtage et jour J ; cycles sans date ; pondération 70/30 |
| KT-053 | Répartition par défaut ou choisie, règle des 48 h, ajustement à la durée disponible (estimation `training_estimate.dart`, échauffement compris) |
| KT-054 | Choix par matériel du lieu, prérequis, chaînes, exercices détestés, gênes, mode prudent, démonstration animée, figures selon l'objectif ; principaux stables, accessoires renouvelés ; couverture des mouvements de l'objectif |
| KT-055 | Séries difficiles par groupe (6 à 14, −2 en santé), plafond +6, ajustement ±2 par cycle |
| KT-056 | Échauffement 5-10 min avec montée en charge, blocs de densité (endurance), circuits à faible impact et mobilité (santé), simulations d'épreuve |
| KT-057 | Ligne « pourquoi » par séance et par exercice (`Exercise.why`, `DayPlan.why`, affichée dans les consignes) ; écran « Mon programme » (Réglages), aperçu « ce qui change », carte de l'accueil, mode Guidé automatique annulable 7 jours |

Fichiers : nouveaux `lib/program_generator.dart`, `lib/program_instance.dart`, `lib/program_store.dart`, `lib/program_screens.dart`, `assets/program_models.json`, `docs/CONTRAT_L10.md`, `docs/PROFILS_TYPES_L10.md`, `test/l10_generator_test.dart`, `test/l10_properties_test.dart`, `test/l10_profiles_test.dart`, `test/l10_store_test.dart`, `test/l10_screens_test.dart`, `test/support/l10_support.dart`, `test/goldens/l10_reference.json`, `test/goldens/l10_profils_types.md`, `tools/tests/test_program_models.py` ; modifiés `lib/store.dart`, `lib/profile_store.dart`, `lib/models.dart`, `lib/session_screen.dart`, `lib/home_screen.dart`, `lib/settings_screen.dart` (entrée Mon programme, version 4.0.0), `pubspec.yaml` (4.0.0+67, asset), `tools/verify_project.py`, `README.md`, ce suivi. Workflow `build-apk.yml` **inchangé**. Aucune dépendance ajoutée. Aucun test existant modifié.

## L10.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | 133 fichiers ; le passage final n'a reformaté qu'un fichier de test (sauts de ligne), repris tel quel dans le ZIP | CI `claude/ci-tools`, commit `dc9e3bd` |
| Analyse | No issues found | idem |
| Suite complète | **689 réussis, 12 ignorés**, 0 échec (630 existants inchangés + 59 L10) | idem (≈ 7 min) |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L9b) | idem |
| Python | 72/72 (69 + 3) ; `verify_project.py` : 40 semaines, 1 812 exercices du programme, 625 exercices de la base, modèles de périodisation contrôlés | idem |
| Propriétés | **10 000 profils aléatoires** (graines 1 à 10 000) : 0 écart ; 2 524 « Forme et santé », 3 678 blocs, 1 513 ondulation, 2 261 linéaire, 24 Expert streetlifting ; 336 519 séances contrôlées dont 154 698 plus courtes que le temps disponible et signalées (tirages de 10 à 240 min : au-delà d'environ 90 min, le plafond de volume limite la séance) ; ≈ 15 s par millier en CI | `test/l10_properties_test.dart` |
| Profils types | 13 profils générés, propriétés respectées, document `docs/PROFILS_TYPES_L10.md`, reproduit au caractère près d'un passage CI à l'autre | `test/l10_profiles_test.dart` |
| Migration du propriétaire | 40 semaines identiques à l'asset (exercice par exercice), départ, historique complet et export inchangés, Koach disponible ; générateur : JSON identique à l'asset et aux annotations | `test/l10_store_test.dart`, `test/l10_generator_test.dart` |
| Déterminisme | Même entrée → même JSON ; entrées sérialisées rejouées à l'identique ; empreintes de 3 programmes figées (`test/goldens/l10_reference.json`) et retrouvées au passage suivant | `test/l10_generator_test.dart` |
| Android | `flutter build apk --debug` : réussi (APK debug arm64 compilé, commit CI `dc9e3bd`) | CI |

Propriétés contrôlées (contrôle indépendant du générateur, `test/support/l10_support.dart`) : matériel du lieu du jour, aucune contre-indication (gêne > 3/10, sauts en mode prudent), prérequis, démonstration animée, durée recalculée avec `training_estimate.dart` ≤ +10 % toujours et ≥ −10 % en semaine de charge sauf séance signalée, échauffement de 5 à 10 min, séries difficiles ≤ plafond, mouvements de l'objectif ≥ 2 séances par semaine (≥ 1 par type en « Forme et santé ») pour des séances de 30 min et plus quand un exercice compatible existe, décharge au moins toutes les 6 semaines, 48 h entre séances lourdes d'une même famille, rejeu identique (1 graine sur 50).

Défauts trouvés par les passages CI et corrigés : 8 remarques d'analyse (accolades, paramètres jamais utilisés) ; le type « fente » absent chaque semaine en « Forme et santé » pour un débutant en mode prudent (difficulté plafonnée à 1) → difficulté relâchée jusqu'à 3 pour le type manquant, prérequis toujours exigés ; séances de 10-15 min trop raccourcies par le retrait forcé → nouvel ajustement vers le temps disponible ; bouton de fiche ajouté dans la feuille de consignes qui repoussait « Fermer » hors écran dans un test existant (`ui_refactor_test.dart`) → retiré (D-L9b-09 reste en attente) ; tests L10 mal écrits (dates calculées avec `Duration` à travers le passage à l'heure d'hiver, cartes non construites hors écran à 200 %, arrondi d'une seconde) → corrigés sans affaiblir d'assertion métier.

Scénarios couverts : nouvel utilisateur (profil du démarrage court → départ → programme généré, persisté, relu, exporté, rejouable) ; régénération au milieu de la semaine 2 après changement de lieu (semaine 1 et journées saisies intactes) ; annulation dans les 7 jours, refusée après une séance du nouveau programme, expirée après 7 jours ; mode Guidé ; cycle suivant depuis le calibrage ; import strict et démarrage tolérant ; écrans « Mon programme », aperçu et carte d'accueil à 390 × 844 et 320 × 720, texte 100/130/200 %, clair et sombre, défilement réel.

## L10.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-050 à KT-057 |
| Testé automatiquement | Voir L10.3 |
| Vérifié sur appareil | **Rien** |
| Reste à valider | Essais téléphone (`LIVRAISON_L10.md`) ; temps de génération sur téléphone ; relecture des 13 profils types (`docs/PROFILS_TYPES_L10.md`) ; registre de validation (`docs/CONTRAT_L10.md` §8) |

- Retour facultatif par muscle du mode Expert non saisi (reporté).
- D-L9b-09 (fiche depuis l'écran de séance) toujours en attente.
- Adaptations de structure Koach bornées à la semaine 40 (contrat L7).
- Branche temporaire `claude/ci-tools` toujours présente.

# Historique conservé — L9b (3.2.0)

## L9b.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L9b.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **3.1.0+65** (L8), `main` `620752e`, 1 990 987 octets, SHA-256 `517f28af939476851125af74a479f046de7a3bd4e9d7e047ab4d60d3361be5c0`, racine unique `streetlift_tracker/` | Recalcul |
| Pack | `kalis_content_pack_v1_final.zip` (branche `content-pack`, `93fad2e`), SHA-256 `5a13a91e3171c303391e00123c24f5cb8e2577e775e4f4be60622351108f9086` (identique à `pipeline/ETAT.md`), pack **2.0.0**, schéma 2.1.0, 625 exercices, 81 muscles, 246 gabarits, 24 arbres ; validé par le propriétaire le 27/09/2026 | Recalcul, `assets/content/pack.json` |
| Prérequis | L8 livré (section L8 ci-dessous) ; pack final présent | Lecture |
| État initial | Celui de L8 sur le même arbre : format 0 changement, analyse sans problème, 598 réussis / 12 ignorés, Python 63/63, `verify_project.py`, build debug | CI L8 (`claude/ci-tools`) |
| Outils | Pas de Flutter local (proxy) ; CI sur la branche temporaire `claude/ci-tools` ; Node 22 et Python 3.11 locaux pour l'import du pack et les fixtures ; aucun téléphone | Constaté |

## L9b.1 — Contrat

`docs/CONTRAT_L9b.md` : entrées et quatre contradictions non bloquantes (§1 : nom de l'archive, 81 muscles au lieu d'environ 90, écran de mentions, groupe du sterno-cléido-mastoïdien), règles et formats (§2), migration (§3 : aucune réécriture, résolution à la lecture), neuf décisions par défaut réversibles (§4), registre de validation (§5), limites (§6).

## L9b.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-079 | `tools/content_pack_import.py` (import reproductible du pack → `assets/content/*`, `lib/atlas_data.dart`, fixtures) ; `lib/content_pack.dart` (index chargé au démarrage, fiches/sources/poses/arbres à la demande, résolution nom → identifiant v2 : correspondance v1 canonique, 79 intitulés du programme, noms et alias) ; `lib/store.dart` : la base embarquée vient de l'index v2 (505 entrées v1 à l'identique + 120 ajouts), `exerciseIdFor`. `assets/exercises_db.json.gz` retiré (conservé en fixture). `tools/verify_project.py` contrôle la base v2 |
| KT-080 | `lib/pose_engine.dart` (portage exact de `kt_pose.js` 2.0.0) ; `lib/pose_painter.dart` (`CustomPainter`, rôles de couleur par palette et mode, `PoseDemo` : animation, pause, réduction des animations → images clés fixes) ; `lib/atlas.dart` (atlas de fiche, légende des rôles) ; `lib/muscle_body.dart` : carte de STATS dessinée avec l'atlas, même API, même agrégation, même rampe ; 18 calques PNG `assets/muscles/` retirés |
| Mentions | `MentionsScreen` (Réglages → À propos → Sources et licences) : rendu de `assets/content/licences.md` |
| KT-081 | Réservé (illustrations de scène reportées) : rien |
| KT-082 | `lib/exercise_screens.dart` : bibliothèque (Arsenal → Exercices : recherche, filtres type, lieu, matériel, difficulté), fiche complète et navigable ; sélecteur de séance (`builder_screen.dart`) : recherche sur les champs v2 et bouton « Fiche de l'exercice » |

Fichiers : nouveaux `lib/atlas.dart`, `lib/atlas_data.dart` (généré), `lib/content_pack.dart`, `lib/exercise_screens.dart`, `lib/pose_engine.dart`, `lib/pose_painter.dart`, `assets/content/` (7 fichiers), `tools/content_pack_import.py`, `tools/tests/test_content_pack.py`, `test/l9b_pose_test.dart`, `test/l9b_content_test.dart`, `test/l9b_perf_test.dart`, `test/fixtures/l9b/` (3 fichiers), `docs/CONTRAT_L9b.md` ; modifiés `lib/store.dart`, `lib/muscle_body.dart`, `lib/builder_screen.dart`, `lib/arsenal_screen.dart`, `lib/settings_screen.dart` (entrée Mentions, version 3.2.0), `pubspec.yaml` (3.2.0+66, assets), `tools/verify_project.py`, `tools/pack_assets.py`, `tools/tests/test_tools.py`, `test/support/capture_support.dart`, `test/visual_capture_test.dart`, `README.md`, ce suivi ; supprimés `assets/exercises_db.json.gz`, `assets/muscles/*` (18). Workflow `build-apk.yml` **inchangé**. Aucune dépendance ajoutée.

Adaptations de tests existants (expliquées, aucune assertion affaiblie) : `tools/tests/test_tools.py` attend 625 exercices dans la base au lieu de 505 (la base s'agrandit, les 505 sont vérifiés un par un par `test_content_pack.py` et `l9b_content_test.dart`) ; les deux utilitaires de captures ne préchargent plus les calques PNG supprimés.

## L9b.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | 123 fichiers, 0 changement | CI `claude/ci-tools`, commit `9328da8` (lib, test, assets identiques au ZIP) |
| Analyse | No issues found | idem |
| Suite complète | **630 réussis, 12 ignorés** (598 existants inchangés + 32 L9b), 0 échec | idem |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L8) | idem |
| Python | 69/69 (63 + 6) ; `verify_project.py` : 40 semaines, 280 jours, 1 812 exercices du programme, 625 exercices de la base | idem |
| Android | `flutter build apk --debug` réussi (commit `d77acc1` ; les passages suivants ne modifient que deux fichiers Dart de l'interface et des tests) | CI |
| Concordance du rendu | 246 gabarits, toutes les images clés : écart max. < 2e-4 (positions du pack arrondies à 4 décimales) ; 20 exercices × 5 instants contre `kt_pose.js` : écart < 1e-9 (exigence : 0,5 % = 0,005) | `test/l9b_pose_test.dart` |
| Coût mesuré (JIT, machine de CI) | Calcul + dessin d'une image de démonstration : **≈ 170-180 µs** en moyenne sur 6 070 images (607 démonstrations × 10 instants ; budget d'une image à 60 i/s : 16 667 µs). Liste la plus longue (625 exercices) : 40 défilements de 400 px, **≈ 25-29 ms** par geste + image en environnement de test | `test/l9b_perf_test.dart` (3 passages) |

Défauts trouvés par les passages CI et corrigés : une méthode `num` masquait le type `num` (erreur de compilation) ; une remarque de style (fonction affectée à une variable) ; trois tests L9b mal écrits (fichier généré formaté par `dart format` puis lu par une expression trop stricte ; future déjà terminée hors de la zone de test — corrigé côté application par un affichage immédiat du contenu déjà chargé ; atlas cherché après défilement hors de la liste construite ; réduction des animations non transmise aux fiches ouvertes par navigation dans le test). Aucune assertion affaiblie. Images par seconde en mode profile et mémoire : **non mesurées** (aucun téléphone) ; le banc sur appareil de L6 (`tools/perf_device/`) n'a pas été relancé.

Nouveaux tests : `test/l9b_pose_test.dart` (8 : concordance de toutes les images clés des 246 gabarits, 20 exercices × 5 instants contre le moteur JavaScript, chronologie et bouclage, calcul des 607 démonstrations, accents 6 palettes × 2 modes et contrastes, rendu de référence pixel par pixel pour les 12 combinaisons, animation et pause, réduction des animations) ; `test/l9b_content_test.dart` (22 : migration v1 → v2, correspondances, doublons, STATS, historique complet rechargé sans perte, recherche et filtres, atlas, fiches 320/390 px × 130/200 % × clair/sombre avec défilement réel, démonstration indisponible, navigation de progression, bibliothèque, mentions) ; `test/l9b_perf_test.dart` (2 mesures) ; `tools/tests/test_content_pack.py` (6).

Scénarios couverts : les 505 exercices v1 gardent nom, groupes et matériel ; les 1 812 lignes du programme et les 505 noms v1 ont un identifiant v2 ; les 22 doublons mènent à l'exercice canonique ; groupes de STATS identiques pour tous les noms v1 et du programme ; historique des 40 semaines + 60 séances personnelles importé, rechargé par une nouvelle instance : `logs`, `custom`, `userExercises` et muscles de la semaine identiques ; recherche par muscle, alias, nom v2 ; filtres combinés ; carte de STATS sur l'atlas avec la même rampe.

## L9b.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-079, KT-080, KT-082 ; écran de mentions |
| Testé automatiquement | Voir L9b.3 |
| Vérifié sur appareil | **Rien** |
| Reste à valider | Essais téléphone (`LIVRAISON_L9b.md`) ; images par seconde en mode profile et mémoire sur téléphone ; lisibilité des démonstrations ; registre de validation (`docs/CONTRAT_L9b.md` §5 et `validation_register.md` du pack) |

- Les fiches ne sont pas encore ouvertes depuis l'écran de séance du programme (D-L9b-09).
- Le générateur L10 exploitera `generateur`, `substitutions`, `contrainte_articulaire`, `precautions` et les arbres de progression, déjà chargés.
- Matériel normalisé du profil L8 pas encore rattaché au vocabulaire `materiel` du pack (à faire avec L10).
- Branche temporaire `claude/ci-tools` toujours présente.

# Historique conservé — L8 (3.1.0)

## L8.0 — Base

| Élément | Valeur | Preuve |
| --- | --- | --- |
| Demande | `pipeline/prompt_L8.txt` (branche `pipeline`), règles `pipeline/PIPELINE.md` | Pipeline du propriétaire |
| Base | `streetlift_tracker_v33.zip` **3.0.3+64** (L6), `main` `8e8f6d1`, 1 941 350 octets, SHA-256 `87b8a6bb06eadd01b5915dea9114e07323427814684a60ea880c5bacf888cf98`, racine unique `streetlift_tracker/` | Recalcul |
| Prérequis | L4 (départ) et L7 (Koach) livrés ; section L6 présente dans ce suivi | Lecture |
| État initial | Celui de L6 sur le même arbre (CI : format 0 changement, analyse sans problème, 570 réussis / 12 ignorés, Python 63/63, `verify_project.py`, build debug). Tests ciblés L5/L6 rejoués sur la candidate : 155 réussis / 11 ignorés, identiques | CI L6 et L8 |
| Outils | Pas de Flutter local ; CI sur la branche temporaire `claude/ci-tools` ; aucun téléphone | Constaté |

## L8.1 — Contrat

`docs/CONTRAT_L8.md` : contradictions relevées (§1), dix décisions par défaut réversibles (§2), format de la section `profile` (§3), démarrage (§4), questionnaire et mode prudent (§5), consentement (§6), questions progressives (§7), migration (§8), registre de validation (§9), limites (§10). Politique préparatoire et cartographie : `docs/CONFIDENTIALITE.md`. **PAR-Q+** : conditions consultées le 26/09/2026 (eparmedx.com, *Terms and Conditions*) — modification et intégration dans un produit interdites sans accord écrit ; formulation **non reprise**, questions équivalentes rédigées et inscrites au registre.

## L8.2 — Changements par ticket

| Ticket | Changement |
| --- | --- |
| KT-038 | `lib/profile.dart` : profil versionné (v1), réponses datées avec source (déclarée / estimée / mesurée), champs V1 (sans sexe ni taille), catalogue d'objectifs extensible (Prise de muscle, Figures, Énergie désactivés), lieux et matériel normalisés, événement « profil modifié ». Section `profile` de la sauvegarde écrite seulement si un profil existe ; import strict, démarrage tolérant |
| KT-039 | `lib/profile_screens.dart` : démarrage en 9 écrans, rien d'écrit avant le récapitulatif ; refus des moins de 18 ans sans écriture ; repère concret (pompes, tractions) ; valeurs par défaut du mode et du ton ; premier écran activé par `main()` (`SLApp(profileGate: true)`) |
| KT-040 | Une question au plus à la fin d'une séance validée (`session_screen.dart`, après le bilan Koach) ; « Plus tard » (7 jours), « Ne plus demander » ; ordre documenté |
| KT-041 | Questionnaire (8 questions), mode prudent : plafond 80 % du 1RM sur B8-B11 (chemins 2.x et Koach, `store.dart`, `koach_store.dart`), consignes « pas de test maximal » et « 3 RIR » dans la séance, conseil médical, levée par accord daté |
| KT-042 | Information préalable, consentement explicite et révocable (effacement), export, suppression des données ; `docs/CONFIDENTIALITE.md` |
| KT-043 | `ownerDraft()` : profil pré-rempli (objectifs L7, programme, historique, feuille Pilotage) ; écran de confirmation au lancement (« Plus tard ») et dans Réglages → Profil ; seule la section `profile` s'ajoute |

Fichiers : nouveaux `lib/profile.dart`, `lib/profile_store.dart`, `lib/profile_screens.dart`, `test/l8_profile_test.dart`, `test/l8_profile_screens_test.dart`, `docs/CONTRAT_L8.md`, `docs/CONFIDENTIALITE.md` ; modifiés `lib/store.dart` (section `profile`, plafond), `lib/koach_store.dart` (plafond), `lib/main.dart` (premier écran), `lib/settings_screen.dart` (Réglages → Profil, version 3.1.0), `lib/session_screen.dart` (consigne prudente, question progressive), `pubspec.yaml` (3.1.0+65), `README.md`, ce suivi. Workflow `build-apk.yml` **inchangé**. Aucune dépendance ajoutée. Aucun test existant modifié.

## L8.3 — Tests et scénarios

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | 114 fichiers, 0 changement | CI `claude/ci-tools`, commit `0facb5d` (lib, test, pubspec identiques au ZIP) |
| Analyse | No issues found | idem |
| Suite complète | **598 réussis, 12 ignorés** (570 existants inchangés + 28 L8), 0 échec | idem |
| Tests ciblés L5/L6 rejoués | 155 réussis, 11 ignorés (identiques à L6) | idem |
| Python | 63/63 ; `verify_project.py` : 40 semaines, 280 jours, 1 812 exercices | idem |
| Android | `flutter build apk --debug` réussi (arbre du commit `e524976` ; les corrections suivantes ne touchent que `const` et une accolade) | CI |
| Démarrage mesuré | **9 écrans, 24 taps, 1 saisie** (parcours type : 3 jours, 8 réponses de santé) ; durée estimée ≈ 75 s | `test/l8_profile_screens_test.dart` |

Défauts trouvés par la première passe CI et corrigés : 3 remarques d'analyse (accolade, `const`, import inutile) ; 4 tests L8 mal écrits (écriture comptée par un `flush()` du test lui-même ; défilement vers une carte déjà dépassée ; texte hors de la zone construite de la liste). Aucun défaut du code applicatif révélé ; aucune assertion affaiblie (l'absence d'écriture est vérifiée par `hasUnsavedChanges` et le compteur d'écritures, après le délai de sauvegarde).

Nouveaux tests : `test/l8_profile_test.dart` (19 : modèle, mode prudent, questions progressives, store, migration, import/export) ; `test/l8_profile_screens_test.dart` (9 : démarrage, mineur, refus du consentement, migration, 3 formats d'écran, Profil, question progressive).

Scénarios couverts : démarrage complet (écrans et taps mesurés) ; refus des moins de 18 ans et de « 18 ans pas encore fêtés » sans écriture ; chaque déclencheur (7 « oui », cœur/tension, grossesse, 65 ans, gêne 4/10 vs 3/10, sans réponse, refus) ; plafond vérifié sur toutes les charges du programme (autres charges identiques) ; levée par accord daté et caducité après une nouvelle gêne ; refus et retrait du consentement (effacement vérifié dans l'export) ; questions progressives (une par séance, ordre, report, refus, santé sans consentement) ; migration sur un état 3.0.0 rempli (export identique hormis `profile`, départ conservé après relance) ; import d'une sauvegarde 3.0.0 sans profil ; import d'un profil hors contrat refusé ; effacement. Écrans à 390 × 844 et 320 × 720, texte 100 / 130 / 200 %, clair et sombre, défilement par gestes.

## L8.4 — Limites et suites

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-038 à KT-043 |
| Testé automatiquement | Voir L8.3 |
| Vérifié sur appareil | **Rien** |
| Reste à valider | Essais téléphone (`LIVRAISON_L8.md`) ; registre de validation (`docs/CONTRAT_L8.md` §9) : questions de santé, seuils du mode prudent, tranches du repère, qualification RGPD ; durée réelle du démarrage |

- Le profil n'a pas encore d'effet sur le programme (régénération : L10) ; seul le mode prudent agit.
- Le mode prudent plafonne la charge affichée ; une série saisie plus lourde n'est pas bloquée.
- Matériel normalisé provisoire, à rattacher au pack L9 (L9b).
- Branche temporaire `claude/ci-tools` toujours présente.

# Historique conservé — L6 (3.0.3)

**Passe actuelle : L6 — Performance (KT-023), version candidate**  
**Date : 26 septembre 2026, Europe/Paris — version : 3.0.3+64 (versionCode réel fixé par la CI de build)**  
**Statut : version candidate L6 : reconstructions des zones masquées différées, caches WOD corrigés, comparaisons de sauvegarde sans JSON. Apparence, données, format de sauvegarde et règles métier inchangés. Testé en CI sur l'arbre livré (format sans changement, analyse sans problème, **570 tests Dart réussis, 12 ignorés** — rendus et banc facultatifs —, Python 63/63, `verify_project.py`, compilation Android debug) ; banc hôte A/B ; rendus L5 rejoués (79/81 identiques au pixel, 2 = horloge). Aucune mesure sur téléphone. Mesures : `docs/PERFORMANCE.md`. ZIP, publication et build signé : `LIVRAISON_L6.md`.**

## L6.0 — Demande, base et outils

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Demande | `prompt_L6_performance_globale_kalis_track.txt` (26/09/2026, 17 h 57) : mesurer, optimiser les coûts justifiés, vérifier ; autorisation d'appliquer les optimisations locales et vérifiables sans validation écran par écran ; une livraison globale ; ne pas refaire L5, ne pas lancer L7 | Déclaration du propriétaire |
| Arbitrages demandés (26/09/2026, 18 h 0x) | 1) Exécution des tests et mesures sur la branche temporaire `claude/ci-tools` : **oui** (le prompt dit « aucun dépôt distant modifié », mais Flutter n'est pas installable ici). 2) Publication : **« Publier sur main + build »** (consigne permanente, confirmée pour L6 malgré le prompt qui la réservait à L7) | Réponses du propriétaire |
| Base | `streetlift_tracker_v33.zip` **L5 3.0.2+63** : 1 741 593 octets, 377 fichiers, racine `streetlift_tracker/`, SHA-256 `95a1578cf35f92e5839f1b3f814e5ea2b4aa7ae6c10e4a2f21f47f8f9061fd0c` (recalculé, identique à `LIVRAISON_L5_GLOBALE.md`), tirée de `main` `6e94618` ; `build-apk.yml` identique à celui de `main` | Recalcul dans cette passe |
| Début de L6 existant | Aucun (ni section L6, ni `docs/PERFORMANCE.md`) | Lecture du suivi |
| Confirmations disponibles | Aucun résultat d'essai sur téléphone transmis pour L5 (ni pour les lots précédents). L'autorisation de passer à L6 ne valide pas L5 : ses vérifications téléphone restent ouvertes | Historique des échanges |
| Blocage préalable | Aucun : la base compile, s'analyse et passe ses tests (état initial ci-dessous) | CI |
| Outils | Pas de Flutter local (proxy : `storage.googleapis.com`, `pub.dev` refusés). Flutter 3.29.3 / Dart 3.7.2 en CI GitHub (runners 2 vCPU). Émulateur Android sur runner : voir L6.3. Aucun téléphone relié | Constaté |
| État initial des tests (base + banc, commit `2f0293c`) | Format 0 changement, analyse sans problème, **564 réussis, 11 ignorés** (4 rendus L5 + 7 tests du banc, facultatifs), Python 58/58, compilation debug | CI run n° 69 |

## L6.1 — Optimisations conservées

| # | Coût initial (preuve) | Cause | Modification | Risque et parade | Résultat |
| --- | --- | --- | --- | --- | --- |
| O1 | Chaque notification du store (une frappe dans une série en est une) reconstruisait les onglets visités même masqués : 93 ms (hôte) par frappe et 152–175 ms par validation, séance ouverte par-dessus les 4 onglets ; STATS affiché : 114–165 ms par notification | IndexedStack et routes gardent les onglets montés ; `ListenableBuilder(store)` ne tient pas compte de la visibilité | `lib/store_widget.dart` : `StoreBuilder` et `StoreWidget` notent la notification quand la zone est masquée (`TickerMode` désactivé : onglet non affiché, section STATS non affichée, route recouverte) et se reconstruisent une fois dès qu'elle redevient visible, avant d'être peinte. Visibilité lue par `TickerMode.getNotifier` (sans dépendance : un changement d'onglet sans modification ne reconstruit rien). Utilisé par PROGRAMME, STATS (par section), ARSENAL, RÉGLAGES et les cartes `StoreWidget` | Zone restée périmée : tests « à jour dès la première image » (onglet, section, retour de séance). Changement de couleur/mode : chemin L5 inchangé (`_refreshDescendants` marque tout), rendus identiques | Frappe et validation : plus d'image nécessaire (0,04–0,08 ms). STATS visible : 16 ms. **Contrepartie** : la première image du retour d'une séance coûte ~40 ms de plus (une reconstruction de l'onglet affiché, au lieu d'une par frappe) |
| O2 | Estimation d'un WOD : clé JSON reconstruite à chaque lecture (10,7 ms pour 1 000 lectures en cache) ; cache FIFO borné à 1 024 : avec 1 050 WOD, chaque passage complet recalcule tout (117 ms) | Clé = `jsonEncode(prescription, résultats)` ; borne inférieure au nombre de WOD | `_EstimateEntry` : copie des mêmes champs, comparée champ à champ (même validité que l'ancienne clé) ; borne = max(1 024, nombre de WOD + 64) ; l'entrée mise à jour passe en fin de file | Estimation périmée : tests de mutation sur place (lignes, intervalle, notes, tours, résultats ajoutés/modifiés/supprimés, intervalles Tabata) ; valeurs = calcul direct | 0,21–0,27 ms le passage complet ; empreintes des estimations identiques |
| O3 | Sauvegarde : 1 000 WOD du catalogue encodés en JSON à chaque écriture pour les comparer à l'original ; `wodStats` : deux encodages par appel (18 ms pour tout le catalogue) | Comparaison par chaîne JSON | `_sameDefinition` : comparaison champ à champ, équivalent exact (textes, entiers, liste de textes) ; `_statsDefinitions` garde une copie de définition au lieu d'un JSON ; `_seedJson` supprimé | Modification non détectée : tests (nom, ligne à nombre constant, intervalle, retour à l'identique) ; export identique (empreintes) | Encodage de sauvegarde : 4,0 → 0,45 ms (neuf), 8,8 → 4,7 ms (régulier) ; `wodStats` : 18 → 0,74 ms |
| O4 | Classement du catalogue (démarrage, import) : 23 ms | Chaque score de WOD calculé deux fois | Score du WOD d'origine réutilisé si la définition est identique | Niveau faux : test « niveau = calcul direct » (WOD modifié, WOD perso) ; empreinte des niveaux identique | 12,2 ms |

Aucune optimisation n'a été retirée après mesure. Aucun changement de schéma, de stockage, de framework d'état, de dépendance ou de chaîne Flutter/Android ; format de sauvegarde 3 inchangé.

## L6.2 — Examinés, conservés tels quels

| Parcours | Constat | Décision |
| --- | --- | --- |
| Chronomètres | `WodClock` (200 ms) ne notifie que si l'affichage change ; `TimerCtl` (1 s) n'est écouté que par la barre du chrono ; règles de temps L4b (horloge monotone, rattrapage) | Rien à gagner démontré ; inchangés |
| Écriture | File unique, regroupement des demandes, accusé de l'API, restauration du document précédent en cas d'échec (L2/L2b) | Inchangée (seule la comparaison des WOD est plus légère). Encodage + compression d'un long journal : 35–121 ms (hôte) par écriture, différée de 600 ms. Le déplacer hors du fil de l'interface demanderait une copie de l'état et une gestion d'ordre ; **proposition** non appliquée |
| Progression / jeu | 13,5 ms (long) à 42 ms (chargé), hôte, après chaque validation | Inchangés ; désormais calculés une fois à l'écriture ou à l'affichage, plus dans les onglets masqués |
| Carte musculaire (`weeklyMuscles`) | 11–35 ms (hôte), lit toute l'histoire | Inchangée ; n'est plus recalculée quand la section Performances est masquée |
| Flou du dock | `BackdropFilter` (σ 20) sous un fond opaque à 94 % | Conservé (effet approuvé). Son coût GPU n'est pas mesurable sans appareil ; le supprimer changerait le rendu : **proposition à mesurer sur téléphone**, non appliquée |
| Démarrage des données | 43–387 ms (hôte) selon le profil ; écart base/candidate non démontré hors classement | Inchangé |
| Catalogue (écran) | Ouverture, recherche, défilement : gain non démontré | Inchangé |

## L6.3 — Mesures

Résumé : `docs/PERFORMANCE.md` §4 à §7. Résultats bruts : `validation/3.0.3/perf-host-AB3/` (12 fichiers JSON Lines, journaux, synthèse), A/A de calibrage : `validation/3.0.3/perf-host-AA3/`, rendus : `validation/3.0.3/rendus-L5-L6.txt`.

**Émulateur (niveau 3) : non exécuté.** Banc dans l'application livré (`tools/perf_device/` : APK profile dont le point d'entrée est un test `integration_test`, résultats `Stopwatch` et `FrameTiming` ; lancement du processus par `am start -W`). APK profile x86_64 de l'application et du banc construits en CI pour la base et la candidate, banc analysé sans problème ; l'émulateur n'a pas démarré (2 tentatives : API 34 en 600 s, API 30 en 1 500 s). Aucune durée d'émulateur rapportée. **Téléphone (niveau 4) : non mesuré** ; protocole : `docs/PERFORMANCE.md` §8.

## L6.4 — Tests

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | 109 fichiers, 0 changement | CI, commit `ebff3c6` (lib, test, pubspec identiques au ZIP) |
| Analyse | No issues found | idem |
| Suite complète | **570 réussis, 12 ignorés** (4 rendus facultatifs, 8 tests du banc), 0 échec | idem |
| Tests ciblés rejoués | 155 réussis, 11 ignorés : `l6_*`, `l5c_*`, `motion`, `ui_refactor`, `level_fill`, `l2b_data_control`, `programme`, `l4_depart`, `reward_flow` | idem |
| Python | 63/63 (dont 5 nouveaux : `test_perf_compare.py`) ; `verify_project.py` : 40 semaines, 280 jours, 1 812 exercices | idem |
| Android | `flutter build apk --debug` (arm64) réussi | idem |
| Rendus L5 rejoués sur la candidate | 81 rendus (rouge avant/après, 13 écrans × clair/sombre, 15 écrans à 320 px × 200 %, **6 couleurs × clair/sombre**, sélecteur) : **79 identiques au pixel** ; 2 diffèrent seulement par le compte à rebours de la boutique (« encore 6 h 51 » / « encore 4 h 21 ») | `tools/compare_renders.py`, CI |
| Résultats métier | 40 empreintes sur 40 identiques (4 profils) | Banc AB3 |

Nouveaux tests (`test/l6_perf_test.dart`, 6) : export (modification à nombre de lignes constant, retour à l'identique, niveau et résultats hors définition) ; estimation WOD (réutilisation, 12 mutations sur place, égalité au calcul direct, nom hors clé) ; plus de 1 024 WOD (second passage réutilisé) ; statistiques et niveaux = calcul direct ; STATS masqué à jour dès la première image ; séance par-dessus les onglets (≥ 40 notifications différées, historique à jour dès la première image du retour, une reconstruction par zone). Aucun test retiré ni affaibli.

Contrats rejoués par la suite complète (non modifiés) : sauvegarde échouée, achats doublés, écritures concurrentes (L2) ; import/export, limites, suppression locale (L2b) ; essai à minuit, sélection stable, résultat unique (L3) ; départ et références (L4) ; brouillons, reprise, chronos (L4b) ; Koach (L7) ; six couleurs, modes, préférence après réouverture, 320 px, texte 200 %, sémantique (L5).

## L6.5 — KT-023

| Volet | État |
| --- | --- |
| Code amélioré | Oui : O1 à O4 |
| Équivalence fonctionnelle testée | Oui : 6 tests L6, suite complète, empreintes métier, rendus L5 |
| Mesures hôte | Oui : banc A/B, 6 manches (JIT, pas un téléphone) |
| Mesures appareil | Non : émulateur non démarré (2 tentatives), aucun téléphone ; banc et protocole livrés |
| Validation utilisateur | Non (à faire, 5 vérifications de `LIVRAISON_L6.md`) |

KT-023 reste **ouvert** : aucune mesure sur téléphone, régression mesurée de la première image au retour de séance à confirmer sur appareil, flou du dock et écriture d'un long journal à mesurer.

## L6.6 — Limites et suites

- Aucune mesure sur téléphone ; aucune mesure de batterie. Le banc hôte tourne en JIT/debug, sans GPU.
- La première image du retour d'une séance est plus lourde (une reconstruction de l'onglet affiché) ; l'animation de retour complète +34 % (long) sur l'hôte.
- Propositions non appliquées : écriture d'un long journal hors du fil de l'interface ; mesure du flou du dock sur téléphone avant toute décision de design.
- Branche temporaire `claude/ci-tools` : à supprimer de ton côté.

# Historique conservé — L5 (3.0.2)

**Passe : L5 — Finition globale et six couleurs dominantes (version candidate 3.0.2, publiée sur `main`, build n° 83)**  
**Date : 26 septembre 2026, Europe/Paris — version : 3.0.2+63 (versionCode réel fixé par la CI de build)**  
**Statut : version candidate globale L5 : six couleurs dominantes (rouge par défaut) et finition des écrans, sans changement de données hors la préférence de couleur. Testé en CI sur l'arbre livré (format sans changement, analyse sans problème, **564 tests Dart réussis, 4 ignorés** — 3 rendus facultatifs et l'ancien rendu 2.5.0 —, Python 58/58, `verify_project.py`, compilation Android debug) ; rendus Flutter de test produits ; aucune vérification sur téléphone. ZIP, publication et build signé : `LIVRAISON_L5_GLOBALE.md`.**

## L5.0 — Demande, base et outils

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Demandes | 1) prompt L5 V2 (proposition L5-A, livrée à 15 h 3x) ; 2) « le bleu → variante jaune ; barre de progression du niveau aussi » (15 h 43) ; 3) validation des six palettes et du sélecteur, L5-C seul (15 h 47) ; 4) « même procédure que d'habitude, valider sur GitHub pour que j'aie mon .apk » (15 h 50) ; 5) `prompt_L5_global_tous_ecrans_kalis_track.txt` : finition de tous les écrans, sans validation écran par écran, une seule version candidate (15 h 58) | Déclarations du propriétaire |
| Arbitrages appliqués sans arrêt | Le prompt global cite « Bleu » : la décision explicite de 15 h 43 (Jaune) est conservée. « Aucun dépôt distant modifié » : la demande de 15 h 50 (publication et build comme d'habitude) prime, comme pour les lots précédents. Indicateur NIV. : barre unie de la dominante (règle « sans dégradé » + « barre du niveau aussi »). Marque K inchangée (question Q2 sans réponse : option proposée) | Choix exposés |
| Base | `streetlift_tracker_v33.zip` **LC1b 3.0.1+62**, 1 705 958 octets, 371 fichiers, racine unique `streetlift_tracker/`, SHA-256 `615bb1b0e97c670581149505b1b16ea9cf01eac9a4b4573d9d207a4e6e7dd38d` (recalculé ; identique à `LIVRAISON_LC1b.md` ; copie tirée de `main` `ec9ca97`). Aucune modification L5 antérieure dans la base (L5-A n'était qu'un document) | Recalcul dans cette passe |
| Outils | Pas de Flutter local (proxy : `storage.googleapis.com` et `pub.dev` refusés). Formatage, analyse, tests Dart, tests Python, compilation Android debug et **rendus Flutter de test** exécutés en CI GitHub sur la branche temporaire `claude/ci-tools` ; build signé par le workflow `build-apk.yml` sur `main` | Constaté |
| État initial | Rendus « avant » de la base (même fixture) : 5 onglets/écrans + 13 écrans × clair/sombre + PROGRAMME 320 px × 200 % | CI (runs de la branche temporaire) |

## L5.1 — Six couleurs dominantes (L5-C)

- `lib/app_theme.dart` : `KAccentSpec` (six palettes, identifiants stables `rouge`, `jaune`, `vert`, `violet`, `orange`, `turquoise`, repli rouge) ; `KPalette(dark, accent)` : rôles de la dominante (`bordeaux` = principale, `action` = vive, `accent`, `accentTint`, `onBrand`/`onBrandSoft`, `onAction`/`onActionSoft`, `decor`, `gauge`, `confetti`) et rôles fixes (`alert`, `redAccent`, `success`, `danger`, `logo`, neutres) ; `buildTheme(dark, accent)` ; `SL.accentSpec`. Le Rouge Kalis reproduit exactement les valeurs historiques (vérifié par test).
- Nuances : voir `REFONTE_UI.md` (tableau). Jaune : texte `#121212` sur la couleur ; en clair, vive et accent en or foncé `#7A5800` (le jaune sur fond clair n'atteint que 1,5 à 1,8:1).
- `lib/main.dart` : `SLApp` écoute le thème **et** la couleur (deux notifiers indépendants), thèmes mis en cache par combinaison (12 au plus), suit la luminosité du téléphone en mode Système ; au changement, tout l'arbre est marqué à reconstruire **sans être recréé** (routes empilées, saisies, séance, chronos, tentative WOD conservés ; aucune nouvelle clé de route).
- `lib/store.dart` : `AppSettings.accent` (défaut `rouge`), `normalizeAccent` (absent, inconnu, mauvais type → rouge, sans refuser l'import), `accentMode`, synchronisé au chargement, à l'import, à la suppression locale et à l'enregistrement des réglages. Export : champ `accent` dans `settings` (format 3 inchangé ; les anciennes versions l'ignorent). **Seule extension de données du lot.**
- `lib/settings_screen.dart` : « Couleur dominante » sous « Thème » : six options nommées (pastille, nom), sélection par coche + contour + gras, sémantique de choix unique (bouton, groupe exclusif, coché) ; grille 2 colonnes sur téléphone, 3 sur grand écran, 1 au-delà de 150 % à 320 px ; cibles ≥ 48 px ; message « Choix affiché, mais les réglages ne sont pas encore enregistrés… » en cas d'échec d'écriture (le message global « Réessayer » existant reste la reprise).
- Répartition des couleurs dans `lib/` : dominante pour les accents d'interface ; **fixes** : confirmations destructrices (`session_screen`, `arsenal_screen`, `session_history` → `SL.alert`), chronos de série et de WOD (`SL.redAccent`, `SL.alert`, dégradé rouge fixe), avertissements écrits (`pilotage_screen`, `data_control`, `wod_store` → `SL.danger`, 2,19 → 7,83:1 en sombre), rareté des badges, radar, carte musculaire, courbe Koach, barres STATS, couvertures WOD. Textes posés sur la couleur (carte du jour, cartes de marque, boutons, bandeaux) → `onBrand`/`onAction` (#121212 sur le Jaune). Puces sélectionnées en sombre : libellé `#F4F4F4` (4,04 → 12,86:1 en rouge).
- Barres de progression du niveau : suivent la dominante ; l'indicateur NIV. de PROGRAMME est une barre **unie**.

## L5.2 — Finition des écrans

| Zone | Résultat | Preuve |
| --- | --- | --- |
| PROGRAMME | **Amélioré** : semaine, dates et bloc dans l'en-tête (« SEMAINE N ▾ », un appui ouvre le choix des 40 semaines ; curseur, glissement et appui long inchangés) ; avec un grand texte (> 130 %), ligne pleine en tête de liste avec le bouton « Semaines » ; titres des journées 1 ligne (référence, la semaine entière reste visible à 390 × 844), 2 lignes (< 360 px ou > 110 %), 3 lignes (> 150 %) ; carte du jour sans texte < 12 px ; « En cours » écrit ; « NIV. » et chiffre suivent la taille de texte (retrait de `TextScaler.noScaling` et `FittedBox`), barre d'en-tête plus haute si besoin | Tests existants (`programme_test.dart` : semaine entière visible à 390 × 844, statuts, 320 px) + rendus |
| Réglages | **Amélioré** : sélecteur de couleur ; sous-titres du Thème sans « bordeaux » ; description « Couleur dominante, clair ou sombre » ; au-delà de 150 % : Thème en trois choix empilés, tuiles de menu sans icône décorative (plus de titre coupé) | Tests + rendus 320 × 200 % |
| Titres de page et de section | **Amélioré** : `KWordFitText` (titres `KPageIntro`, intros STATS, feuilles) garde les mots entiers ; si le mot le plus large ne tient pas, la taille du titre baisse juste assez, jamais sous 15 px × échelle | Rendus 320 × 200 % (« RÉGLAGES », « CHRONOMÈTRES », « d'entraînement ») |
| STATS | **Amélioré** : carte personnage (titre sous l'insigne > 150 %), branches du parcours empilées > 150 %, titres de section 11 px, puce sélectionnée lisible ; graphiques inchangés | Rendus avant/après |
| Références | **Amélioré** : champ « — kg » au lieu du nom tronqué (« Poids de cor… »), nom lu par TalkBack ; « Non renseigné » lisible | Rendus |
| Boutique | **Amélioré** : carte de crédits, « Gagner » sous le solde > 150 % ; sinon **conservé** (rendus identiques en rouge) | Rendus |
| Séance, historique, ARSENAL, éditeur, fiches et chrono WOD, départ du programme, sous-pages de réglages | **Conservés** après vérification (rendus identiques pixel à pixel en rouge à 390 × 844, hors horloge affichée) ; couleurs réparties comme en L5.1 | Comparaison de rendus |
| Démarrage, erreur au lancement, bilan/récompenses, dialogues d'import/suppression, Koach | **Conservés**, couleurs réparties ; non rendus dans cette passe | Suite complète |
| Dock | **Conservé** (libellé actif limité à 115 %, conception validée) | Limite documentée |

## L5.3 — Tests

| Contrôle | Résultat | Où |
| --- | --- | --- |
| État initial (base 3.0.1) | 537 tests Dart réussis, 1 ignoré (LC1b, run n° 81) ; rendus « avant » produits sur la base avec les mêmes tests de rendu | CI, branche temporaire |
| Formatage | 106 fichiers, 0 changement | CI, commit `d5cf393` (arbre identique au ZIP pour `lib/`, `test/`, `pubspec.yaml`) |
| Analyse | No issues found | idem |
| Suite complète | **564 réussis, 4 ignorés** (tests de rendu facultatifs), 0 échec | idem |
| Tests ciblés rejoués | 149 réussis, 3 ignorés : `l5c_*`, `motion_test`, `ui_refactor_test`, `level_fill_test`, `l2b_data_control_test`, `programme_test`, `l4_depart_test`, `reward_flow_test` | idem |
| Python | 58/58 ; `verify_project.py` : 40 semaines, 280 jours, 1 812 exercices, 505 exercices de base | idem |
| Android | `flutter build apk --debug` (arm64) réussi | idem |
| Rendus Flutter de test | 3 fichiers de rendu, tous sans exception : rouge avant/après (5 vues × 2 modes), 13 écrans × 2 modes + PROGRAMME 320 × 200 %, 15 écrans à 320 × 200 %, 6 couleurs × 2 modes × (PROGRAMME, RÉGLAGES), sélecteur et PROGRAMME Jaune à 320 × 200 % | idem ; images livrées à part |

Nouveaux tests (27) :
- `test/l5c_couleur_test.dart` (15) : six familles et repli rouge ; valeurs historiques exactes du rouge ; **12 combinaisons** : contrastes calculés (accent ≥ 4,5 sur 5 fonds, texte sur principale et sur vive ≥ 4,5, puce sélectionnée ≥ 4,5, `onPrimary` ≥ 4,5, vive ≥ 3 sur le fond sauf rouge sombre documenté, jauges visibles) ; rôles fixes identiques dans toutes les palettes ; thème Material par combinaison ; préférence : neuve, réouverture, indépendance du mode, choix rapides, échec d'écriture puis reprise, export, ancienne sauvegarde sans champ, valeur inconnue sans refus, suppression locale, XP/crédits/droits/dates/journal inchangés.
- `test/l5c_selecteur_test.dart` (12) : grille à 320/390/600 px et 100/130/200 % (colonnes, 48 px, pas de débordement), sémantique (bouton, groupe exclusif, coché), choix rapides dans l'écran, message « non enregistrés », changement de couleur avec route de séance empilée et saisie en cours (mêmes objets d'état, texte conservé, composant recoloré, **journal identique**), mode Système (luminosité suivie, couleur conservée), six couleurs × clair/sombre dans l'application.
- Tests existants adaptés : `ui_refactor_test.dart` (« les actions de sauvegarde ») : `ensureVisible` avant deux appuis, la page étant plus courte (titre sans mot coupé). Aucune assertion retirée, aucun test désactivé ; la garantie « semaine entière visible à 390 × 844 » (`programme_test.dart`) est conservée — elle a conduit à placer la semaine dans l'en-tête.


## L5.4 — Limites et suites

- Aucun essai sur téléphone, aucun essai TalkBack réel ; captures = rendus Flutter de test (moteur de test, polices du SDK), pas des captures d'APK.
- Rendus non produits : démarrage, écran d'erreur, bilan et cérémonie, dialogues d'import/suppression, écrans Koach, notifications.
- Libellé du dock limité à 115 % ; grands chiffres (chrono 72 px, charge 28 px) toujours réduits par `FittedBox` s'ils ne tiennent pas (le nombre reste entier).
- À 320 px et 200 %, un titre de ligne d'historique (« ENDURANCE ») peut encore passer à la ligne au milieu du mot.
- Rouge vif historique sur `#121212` : 2,46:1 (sous 3:1), gardé pour l'identité ; les cinq autres couleurs passent 3:1.
- Contrastes = calcul WCAG 2.x (luminance relative) sur les valeurs du code, pas une mesure à l'écran ; pas une certification.
- Branche temporaire `claude/ci-tools` à supprimer de ton côté (droits insuffisants).

# Historique conservé — L5-A (proposition du 26/09/2026, livrée hors ZIP)

### L5-A.0 — Demande, base et capacités

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Demande | Compléter L5 : chaque utilisateur choisit la couleur dominante parmi six (rouge actuel, bleu, vert, violet, orange, turquoise) ; rouge par défaut ; couleur et mode clair/sombre/système indépendants ; proposition seulement, sans code ; prompt `prompt_L5_finition_visuelle_couleurs_kalis_track_v2.txt` qui remplace le précédent prompt L5 | Déclaration du propriétaire (26/09/2026) |
| Base | `streetlift_tracker_v33.zip` **LC1b 3.0.1+62**, 1 705 958 octets, 371 fichiers, racine unique `streetlift_tracker/`, SHA-256 `615bb1b0e97c670581149505b1b16ea9cf01eac9a4b4573d9d207a4e6e7dd38d` | Recalculé dans cette passe ; identique à `LIVRAISON_LC1b.md`. Copie obtenue depuis `main` (commit `ec9ca97`), où cette livraison a été publiée : l'identité est prouvée par l'empreinte, le dépôt n'est pas adopté comme nouvelle référence |
| Validations connues de la base | CI run n° 81 : format, analyse, 537 tests Dart réussis et 1 ignoré, Python 58/58, build signé réussi | Résultat GitHub repris de LC1b, non rejoué ici |
| Essai sur téléphone | Aucun (LC1b, L7, L4b non vérifiés sur appareil) | — |
| État L5 trouvé | Aucune section L5, aucun inventaire L5-A ni sous-lot L5 dans la base ; `REFONTE_UI.md` portait encore la checklist 2.5.0 | Lecture de `SUIVI_PROJET.md`, `REFONTE_UI.md`, `docs/` |
| Rendu Flutter | **Non exécuté.** Flutter absent de l'environnement et non installable : le proxy refuse `storage.googleapis.com` et `pub.dev` (réponse 403). Un rendu par la CI GitHub reste possible mais demande de pousser une branche temporaire : non fait dans une passe de proposition | Commandes exécutées dans cette passe |
| Retour du propriétaire (26/09/2026, 15 h 43) | « Le bleu change le pour une variante jaune, penser à changer la couleur de la barre de progression du niveau aussi » → Bleu remplacé par Jaune ; Q1 tranché en B (les barres de progression du niveau suivent la dominante). Pas encore d'accord global sur L5-C | Déclaration du propriétaire |
| Visuels fournis | **Maquettes HTML** (page « Kalis Track · Couleur dominante »), construites d'après le code ; ni capture de l'APK, ni rendu Flutter | — |

Portée volontairement limitée : l'inventaire L5-A complet des écrans n'existait pas. Il n'est pas refait en entier ici : cette passe couvre l'inventaire des couleurs de toute l'application (nécessaire à L5-C) et l'écran PROGRAMME (pilote). Les autres zones (démarrage, séance, historique, Arsenal, boutique, WOD, STATS, réglages L2b) restent à inventorier au moment de leur sous-lot.

### L5-A.1 — Décisions visuelles retrouvées (conservées)

- Navigation ARSENAL, STATS, PROGRAMME, RÉGLAGES, libellés visibles ; semaine sélectionnée et états conservés (L4b).
- Rouge historique : `#6B0C0C` dominante, `#A61717` accent/actif, `#E85959` accent textuel en sombre (4,8:1 sur `#1E1E1E`, commentaire de `app_theme.dart`), fonds `#121212/#1E1E1E`, vert `#388E3C` réservé à la validation.
- Titres principaux en majuscules ; K sans fond ; pas d'AVANT/ARRIÈRE sur l'accueil.
- Niveau : 1.8.7 « chiffres pleins, sans contour ni dégradé » ; 2.0.1 (décision plus récente) « NIV. » à gauche et barre d'avancement dessous. **Conflit résolu** : la règle « sans dégradé » visait le remplissage des chiffres (aujourd'hui en couleur de texte, sans dégradé) ; la barre ajoutée en 2.0.1 utilise le dégradé de la charte. Rien n'est changé.
- Couvertures WOD : dégradé autorisé (la règle du niveau ne s'y étend pas).
- **Évolution autorisée le 26/09/2026** : la dominante rouge unique devient le choix par défaut parmi six dominantes sélectionnables. Les nuances des cinq alternatives sont une proposition non validée.
- **26/09/2026, 15 h 43** : les six familles deviennent rouge, **jaune**, vert, violet, orange, turquoise (le bleu est retiré) ; les barres de progression du niveau suivent la dominante. L'insigne de rang et la rareté des badges gardent leurs couleurs.

### L5-A.2 — Inventaire des couleurs (inspection statique de `lib/`)

Les couleurs sont centralisées dans `lib/app_theme.dart` : `KPalette` (constantes et rôles), `SL` (accesseurs statiques, mode lu dans `SL.dark`), `ProgrammeColors`, `buildTheme` (thème Material). Une seule couleur écrite en dur ailleurs : `store.dart:589` (`#4FA3C7`, séances perso). Occurrences relevées (hors `app_theme.dart` pour les constantes) : `SL.accent` 98, `SL.success` 52, `SL.action` 22, `SL.bordeaux` 16, constantes `KPalette.burgundy/actionRed/lightRed` 23.

Constat important : `SL.action` (#A61717) sert à la fois d'état actif (sélection, curseur, points de séance) **et** de couleur d'alerte (confirmations de suppression dans `session_screen.dart:127`, `arsenal_screen.dart:364`, `session_history.dart:242` ; chrono d'effort `session_screen.dart:1922-1937` ; avertissements écrits). L5-C doit donc séparer les usages, pas remplacer le rouge partout.

| Groupe | Proposition |
| --- | --- |
| Boutons pleins, bandeaux, carte du jour, cartes de marque, sélection (onglets, dock, segments, interrupteurs, curseur), liens et icônes d'accent, champ actif, puces, boutons d'action WOD, chronos de mode (lancement), records, jauges de missions/envies, décor (flamme, boss, anneau hebdo, confettis) | Suit la dominante |
| Erreurs, suppression, confirmations destructrices | Rouge fixe |
| Avertissements écrits (`pilotage_screen.dart:167`, `data_control.dart:374`, `wod_store.dart:994`) | Rouge « danger » fixe (ajustement, voir L5-A.3) |
| Validation et succès | Vert fixe |
| Chronomètres : phases effort/repos/terminé, time cap, chiffres du chrono WOD | Couleurs actuelles fixes |
| Barres de progression du niveau (barre NIV. `levelup.dart`, jauge d'XP `rewards.dart`, jauge d'XP `wod_store.dart:985`) | Suit la dominante (Q1 tranché : B) |
| Insigne de rang, rareté des badges | Couleurs actuelles fixes |
| Textes et icônes posés sur la dominante (92 occurrences de blanc / `#F4F4F4` à classer, dont une partie sur des surfaces fixes comme les couvertures WOD) | « Texte sur dominante » : `#F4F4F4`, ou `#121212` pour le Jaune |
| Graphiques et données (barres STATS, radar, carte musculaire), couvertures et rubans WOD, couleurs de blocs et de séances perso | Couleurs actuelles fixes |
| Marque K dans l'app et animation d'ouverture | Inchangée (Q2) |
| Icône Android, écran natif | Non touchés |
| Fonds, surfaces, textes, gris | Inchangés, selon clair/sombre |

Risque à vérifier (non reproduit) : les widgets qui lisent `SL.*` sans dépendre de `Theme.of` ne se redessinent pas seuls ; un basculement du mode Système pendant une séance ouverte (route poussée) peut laisser des couleurs mélangées. L5-C prévoit un rafraîchissement de tout l'arbre au changement, sans recréer les états.

### L5-A.3 — Contrastes (calcul WCAG 2.x sur les valeurs du code, pas une mesure sur rendu)

Formule de luminance relative WCAG 2.x ; seuils 4,5:1 (texte) et 3:1 (composants, critère 1.4.11). Ce n'est pas une certification.

| Constat (rouge actuel) | Mesure | Proposition |
| --- | --- | --- |
| Avertissements écrits en `#A61717` sur `#1E1E1E` (sombre) | **2,19:1** | Rôle « danger » fixe : `#F09B9B` (7,83:1) en sombre, inchangé en clair |
| Libellé de puce sélectionnée (`#E85959` sur teinte 14 %), sombre | **4,04:1** | Libellé `#F4F4F4` (12,86:1), coche et fond gardent l'accent |
| `#A61717` comme élément d'interface sur `#121212` | 2,46:1 | Conservé (identité) ; état aussi porté par libellé, position, pouce blanc |

### L5-A.4 — Proposition L5-C : six palettes

| Palette (id) | Principale | Vive | Accent sombre | Texte sur principale | Texte sur vive | Vive sur `#121212` | Accent sur `#1E1E1E` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Rouge Kalis (`rouge`, défaut) | `#6B0C0C` | `#A61717` | `#E85959` | 11,34 | 7,62 | 2,46 | 4,77 |
| Jaune (`jaune`) | `#E6B000` | `#F5C400` (sombre) · `#7A5800` (clair) | `#F5C400` | 9,43 (texte `#121212`) | 11,40 (texte `#121212`, sombre) · 6,51 (blanc, clair) | 11,40 | 10,14 |
| Vert (`vert`) | `#0B4D33` | `#157A4E` | `#4EC08A` | 8,99 | 5,35 | 3,50 | 7,33 |
| Violet (`violet`) | `#44146B` | `#8240C4` | `#B38CF2` | 12,25 | 6,04 | 3,10 | 6,31 |
| Orange (`orange`) | `#6E2E05` | `#A84707` | `#F2924A` | 9,29 | 5,88 | 3,18 | 7,13 |
| Turquoise (`turquoise`) | `#08494F` | `#0E7479` | `#3EC4C4` | 9,20 | 5,54 | 3,38 | 7,86 |

Rôles : principale = rôle du bordeaux (et accent en clair) ; vive = rôle de `#A61717` pour l'état actif ; accent sombre = accent textuel en sombre. Jaune : texte `#121212` sur la principale et sur la vive en sombre ; en clair, vive et accent passent à l'or foncé `#7A5800` (5,92:1 sur `#F4F4F4`, 5,63:1 sur teinte), car le jaune sur fond clair n'atteint que 1,5 à 1,8:1 ; jauge de niveau en clair `#7A5800 → #8A6500` (3,88:1 sur la piste `#DCDCDC`). Jaune séparé de l'Orange (ΔE76 42 à 51). Vert : distinct du vert de validation mais proche (ΔE76 14 à 21) ; la validation garde coche et libellé. Orange : distinct du rouge d'erreur (ΔE 22 à 39).

Sélecteur : RÉGLAGES → Apparence, sous « Thème » ; six options nommées (pastille + nom), grille 3/2/1 colonnes selon largeur et texte, 48 px minimum, sélection marquée par coche, contour 2 px et gras, groupe à choix unique pour TalkBack ; application immédiate sans redémarrage ; en cas d'échec d'écriture, couleur affichée, message existant avec « Réessayer » et mention « Choix non enregistré ». Sous-titres du Thème reformulés sans « bordeaux ».

Données : champ `accent` dans `AppSettings` (`rouge|jaune|vert|violet|orange|turquoise`) ; absent → rouge ; inconnu ou mauvais type → rouge **sans refuser l'import** (contrairement à `theme`, dont une valeur inconnue refuse la sauvegarde aujourd'hui) ; export/import avec les réglages (remplacement complet) ; suppression locale → rouge ; les anciennes versions ignorent le champ. Aucune autre donnée modifiée.

Mise en œuvre prévue (après accord) : palettes et rôles dans `app_theme.dart` (`KPalette(dark, accent)`, rôles « texte sur principale / sur vive » et nuances par mode, nécessaires au Jaune ; rôles fixes nommés pour alerte, rang et données), cache des 12 `ThemeData`, écoute combinée mode + couleur dans `SLApp`, sélecteur dans `settings_screen.dart`, champ dans `store.dart`. Pas de nouvelle dépendance. Pas de flash au démarrage : l'application est construite après la lecture des réglages ; l'animation d'ouverture (avant lecture) reste inchangée.

Tests prévus : rôles de couleur pour les 12 combinaisons ; contrastes calculés en test ; sélecteur à 390/320 px, 130/200 %, sémantique ; changement de couleur pendant une saisie, une séance et un chrono sans perte ni fausse performance ; réouverture ; échec d'écriture ; choix rapides (dernier gagne) ; ancienne sauvegarde sans champ ; valeur inconnue ; export/import ; suppression ; XP, crédits, WOD acquis et dates inchangés ; `reward_flow_test.dart` et `wod_store_test.dart` rejoués ; en rouge, comparaison avant/après limitée aux ajustements annoncés.

**Arbitrages** — Q1 barres de progression du niveau : **tranché B** (suivent la dominante, 26/09/2026). Q2 marque K en clair : ouvert, A (proposé) rester bordeaux, B suivre la nuance principale.

### L5-A.5 — Proposition du pilote PROGRAMME (après L5-C)

Inspection statique de `lib/home_screen.dart` et `lib/levelup.dart` ; aucune capture.

| Réf. | Constat | Changement proposé | Inchangé |
| --- | --- | --- | --- |
| P1 | Dates et bloc de la semaine absents de l'écran ; choisir une semaine demande un appui long ou deux étapes | Ligne « SEMAINE 12 · Bloc 2 — Force · 28/09 → 04/10 » sous le curseur, bouton visible « Semaines » | Curseur, glissement, appui long, feuilles existantes |
| P2 | Titres des journées sur 1 ligne (coupés à 320 px et dès 130 %) | 2 lignes | Ordre, carte du jour, actions |
| P3 | Textes de 10 px sur la carte du jour | 12 px minimum | Contenu de la carte |
| P4 | « En cours » porté par une icône seule | Mot « En cours » à côté de l'icône | Icônes fait/à faire |
| P5 | `LevelProgressNumber` : `TextScaler.noScaling` + `FittedBox` (KT-020) | NIV. et chiffre suivent la taille de texte ; en-tête plus haut | NIV. avant le chiffre, barre dessous (sa couleur relève de L5-C) |

Composants partagés : `LevelProgressNumber` seulement (en-tête PROGRAMME, `level_fill_test.dart`). Hors pilote : `FittedBox` du dock (`nav_bar.dart`), autre sous-lot.

### L5-A.6 — Fichiers de cette passe

Modifiés (livrés séparément, hors ZIP) : `SUIVI_PROJET.md`, `REFONTE_UI.md`. Créés hors projet : `NOTE_L5A.md`, page de proposition (maquettes). Aucun autre fichier du projet modifié ; pas de ZIP, pas d'APK, pas de publication.

## LC1b.0 — Demande, base et décisions

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Demande | « Je veux tester le nouveau format du j6 de la semaine prochaine aujourd'hui (j6 de cette semaine), modifie le programme pour appliquer le changement de la séance d'aujourd'hui. » Aujourd'hui 26/09/2026 = **S11·J6** (départ 13/07/2026, semaine de décharge) ; semaine prochaine = S12·J6 | Déclaration du propriétaire |
| Décisions (questions posées) | Squat : **garder le squat endurance de S11** (3 × 0,9 × max à 70 kg, RIR 3), le test max squat reste en S12·J6 ; S12·J6 : **inchangé** | Réponses du propriétaire |
| Base | `streetlift_tracker_v33.zip` **L7 3.0.0+61** (= `main`, commit `c30c691`), 1 694 580 octets, SHA-256 `36a87190f54ddd56b214fa7671e6a308c4e61c5cfca49f7c501254344a5ce59f`, racine unique `streetlift_tracker/` ; build run n° 80 réussi | Livraison précédente de cette conversation |
| Volumes retenus | Ceux de S12·J6 (MU 4×3, tractions 4×3, leg raises 3×10) : c'est le format que tu veux tester. La décharge porte sur le squat (gardé à 0,9) et sur le volume total de la séance (33 → 15 séries prévues). Le programme applique en décharge du Bloc 2 (S15, S19) des volumes plus bas (MU 3×2, tractions 3×3, leg raises 2×10) : non appliqués ici | Choix exposé |
| Numérotation | « LC2 » est réservé au contenu S20-S25 (feuille de route) : ce lot est **LC1b**, rattaché à KT-037 ; aucun nouveau ticket | Feuille de route |

## LC1b.1 — Changements

**Script** `tools/lc1b_s11_j6.py` (même modèle que LC1) : l'entrée doit être l'asset LC1 (SHA-256 du JSON `399450dc…5328`), une seconde exécution est refusée (« déjà appliquée »), la sortie est comparée à son empreinte (`144869b3d42eb4293f3670f99a23806bc745debbe3ebe54c96b3ad31e5c5c4b2`) avant écriture ; il vérifie que seul S11·J6 change (Pilotage, métadonnées, en-têtes de semaine, 279 autres journées dont S12·J6 identiques) et que les identifiants restent uniques.

**S11·J6** (« SKILL MUSCLE-UP + POINTS FAIBLES » → « PUISSANCE MU + SQUAT ENDURANCE », cycle DELOAD gardé ; conduite : celle des J6 du Bloc 2, sans mention de test ni de GtG, échauffement et collagène inchangés) :

| # | Ligne | Identifiant | Avant | Après |
| --- | --- | --- | --- | --- |
| 1 | Muscle-ups PdC explosifs | `B1-L1b-001` (nouveau) | — | copie exacte de `B2-L1-009` (S12·J6) : 4×3, 2 min, explosif |
| 2 | Tractions explosives poitrine-barre | `B1-521` (gardé) | 5×3 | 4×3, consigne S12 (+5 kg si le sternum touche facilement) — copie de `B2-60` |
| 3 | Squat endurance @ 70 kg | `B1-525` (gardé) | 3 × 0,9 × max, RIR 3 | **inchangé** |
| 4 | Leg raises lestés (suspendu) | `B1-527` (gardé) | 2×10 | 3×10 — copie de `B2-66` |
| 5 | Mobilité épaules + poignets | `B1-529` (gardé) | 10 min | inchangé (= `B2-68`) |

Retirés (identifiants jamais réutilisés) : `B1-519` isométrie transition MU, `B1-520` excentriques de transition lestés, `B1-522` négatifs MU, `B1-523` transitions élastique, `B1-524` isométrie bas de dip, `B1-526` false grip hold, `B1-528` HIIT court. Total : 1 818 − 7 + 1 = **1 812** exercices.

**Journal** : une séance déjà enregistrée avec un identifiant retiré reste lisible à l'identique (noms du journal) ; rien n'est réattribué. Si tu as déjà ouvert la séance S11·J6 avant la mise à jour, les séries saisies sur les anciennes lignes restent dans le journal mais ne s'affichent plus dans la séance au nouveau format.

**Économie** : aucun barème modifié. **Koach** : `assets/koach_program.json.gz` régénéré (`tools/koach_annotate.py`) ; 1 290 exercices annotés, catégories inchangées (accessoire 918, endurance 151, force 136, test d'endurance 19, test 1RM 12), courbes inchangées.

**Attentes figées mises à jour (aucune assertion retirée, aucun test désactivé)** :
- `tools/tests/test_lc1_revision.py` : les contrôles LC1 portent sur l'asset LC1 **reconstruit** (asset livré + S11·J6 d'origine, `tools/tests/fixtures/lc1_s11_j6.json`) ; toutes les valeurs attendues (empreintes LC1, partie intacte `04ffcab8…`, 1 818) sont inchangées ;
- `tools/tests/test_lc1b_s11_j6.py` (**nouveau**, 8 tests) : entrée = sortie LC1, asset livré = sortie attendue, script = asset livré, seul S11·J6 change, contenu ligne par ligne, identifiants, second passage refusé, entrée inattendue refusée, CLI ;
- totaux 1 818 → 1 812 justifiés dans `tools/verify_project.py`, `tools/tests/test_tools.py`, `tools/tests/test_koach_reference.py`, `test/store_test.dart`, `test/lc1_programme_test.dart` (comptes LC1 gardés, compte LC1b ajouté), titre d'un test de `test/training_estimate_test.dart` ;
- `test/lc1_programme_test.dart` : test du contenu S11·J6 (lignes, format identique à S12·J6 hors squat, volume du squat pour des maxima explicites) et test d'écran (journal S11·J6 avec l'identifiant retiré `B1-520` lisible, séance S11·J6 parcourue à 320 px et texte 200 %) ;
- instantané 2.x `test/fixtures/l7_2x_snapshot.json.gz` : dans les 5 jeux, les 11 lignes de S11·J6 sont remplacées par les lignes 2.x déjà capturées des lignes identiques de S12·J6 (identifiant seul changé) et la ligne `B1-525` capturée ; les 1 807 autres lignes sont identiques octet pour octet (vérifié). Le test compare toujours les 5 jeux ligne par ligne.

Version : `pubspec.yaml` et `lib/settings_screen.dart` → **3.0.1+62** ; `README.md` ; ce suivi.

## LC1b.2 — Tests

| Contrôle | Résultat | Où |
| --- | --- | --- |
| Formatage | 1 fichier reformaté par la CI (`test/lc1_programme_test.dart`), recopié ; arbre livré = arbre testé (hors ce suivi) | CI (branche temporaire, commit `e1b5f03`) |
| `flutter analyze` | Aucun problème | CI |
| Tests Dart | **537 réussis, 1 ignoré** (535 + 2 nouveaux LC1b) ; `l7_koach_off_test.dart` : 5 jeux × 1 812 lignes égales à l'instantané | CI |
| Python | **58/58** (50 + 8 `test_lc1b_s11_j6.py`) ; `verify_project.py` : 40 semaines, 280 jours, 1 812 exercices, 505 exercices de la base | CI + local |
| Script LC1b | Appliqué une fois (1 818 → 1 812), second passage refusé proprement | Local |
| Build debug Android | Réussi | CI |

## LC1b.3 — Limites

- Aucune vérification sur téléphone. Avant d'installer : export des données, puis contrôle que l'historique est conservé.
- Classeur Excel du propriétaire désormais aussi désynchronisé pour S11·J6 (l'asset est la référence, comme depuis LC1).
- Si, après la séance, tu veux revenir à l'ancien S11·J6 ou appliquer les volumes de décharge S15/S19, c'est un nouveau passage du même type (script vérifié).

---

**Passe L7 — Koach, moteur d'autorégulation local (KT-024 à KT-036)**  
**Date : 26 septembre 2026, Europe/Paris — version : 3.0.0+61 (versionCode réel fixé par la CI de build)**  
**Statut : Koach (estimation du 1RM et des maxima depuis le journal, suggestions pendant la séance, propositions au bilan, fatigue, douleur, objectifs, structure en option, pesées, matériel, questionnaires facultatifs) corrigé dans le code selon tes décisions D1-D37 du 26/09/2026 et testé automatiquement (moteur Dart = référence Python sur 26 cas, simulations, store, écrans, Koach désactivé = 2.x sur 1 818 exercices) ; compilé. Aucune vérification sur téléphone. Paramètres du modèle à éprouver sur le terrain et à faire valider par un préparateur physique compétent ; qualification juridique des questionnaires non tranchée. Publication et build : `LIVRAISON_L7.md`.**

## L7.0 — Base et état initial

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` **L4b** (= `main`, commit `f71c360`), **1 469 701 octets**, SHA-256 `0e6aa29c61777408fc1819cac48a5b1c7465d18a09b8e325c13a06d33c5467ca`, racine unique `streetlift_tracker/`, **2.5.9+60** | Vérifié (fichier et `main` identiques) ; source intacte, travail sur copie |
| Build 2.5.9 | Run n° 79 réussi (APK/AAB signés) | Résultat GitHub (lecture publique de l'API) |
| État initial | Arbre L4b inchangé, branche temporaire `claude/ci-tools` (commit `3d57246`) : formatage 0 changement, `flutter analyze` sans problème, **442 réussis, 1 ignoré**, build Android debug réussi ; Python 39/39 | CI (sans secret) |
| Instantané 2.x | Charges, libellés, volumes, séries, saisie, reps prévues et repos des 1 818 exercices pour 5 jeux de références et d'unités, capturés sur l'arbre L4b inchangé (commit `71d75dc`) → `test/fixtures/l7_2x_snapshot.json.gz` (générateur temporaire non livré : même calcul que `_row` de `test/l7_koach_off_test.dart`) | CI |
| Défaut bloquant préalable | Aucun | Constat |
| Écarts avec la demande | « 1 954 entrées » : le programme compte **1 818** exercices depuis LC1 (contrôle fait sur 1 818) ; table « Repères RIR ↔ % » de la feuille Pilotage **absente** de l'archive (a priori ajusté sur les couples prescrits par le programme) ; singles « RIR 0 · ~95-97 % » incohérents par définition (écartés de l'ajustement) ; numérotation : ce « L7 » (Koach) n'est pas le « L7 — Candidate et publication » du plan A0 (§5 plus bas), qui reste à planifier | `docs/CONTRAT_L7.md` §1 |
| Essais téléphone L1b → L4b | **Non rapportés** : rien n'est marqué « vérifié sur appareil » | — |

## L7.1 — Décisions appliquées et choix exposés

Les 37 décisions du 26/09/2026 sont appliquées telles quelles ; le tableau complet (règle, choix d'implémentation modifiable) est dans `docs/CONTRAT_L7.md` §2. Choix faits dans ce cadre, exposés et modifiables :

| Point | Choix | Pourquoi |
| --- | --- | --- |
| Interrupteur (D6) | **Désactivé par défaut**, installation neuve comme mise à jour ; explication avant activation | Rien ne change pour un utilisateur 2.x sans action |
| Plafonds D20 | En **masse système** (poids du corps + lest, ou barre), × semaines depuis le dernier changement (max 4) | Un % du lest seul n'a pas de sens au muscle-up (lest proche de 0) |
| Allègement douleur D26 | −20 % des **charges prescrites** du mouvement, temporaire ; ni la valeur de pilotage ni l'estimation ne bougent | Réversible, levé quand la douleur redescend ≤ 3/10 (proposition) ou à la main |
| Décharge anticipée D28 | Séries × 0,6 (min 1), charges −10 %, semaine suivante, couche datée annulable | Paramètres non fixés par la demande |
| Incrément « machine » D23 | 2,5 kg (leg curl, mollets) | Matériel non listé par la demande ; modifiable dans Réglages → Koach → Matériel |
| Sommeil D14 | Saisi par tranche (< 5 h … > 8 h), valeur centrale enregistrée | Saisie en un tap ; seuil D25 « < 5 h » conservé |
| Ajouts justifiés par simulation | Effet de jour 5 %, séance atypique mise en attente, série ratée n = r + 0,5, test + ½ incrément, biais sur 21 jours, σ_k = 4, hystérésis 0,75 incrément | Mesurés un par un (ablation, contrat §8) |
| Cache incrémental | Repris seulement si événements **et contexte** (pesées, références, repères initiaux, paramètres) sont inchangés | Défaut trouvé pendant l'intégration : une pesée rétroactive laissait l'estimation calculée avec l'ancien poids (corrigé, testé en Python et en Dart) |

Décisions manquantes (non bloquantes, choix ci-dessus appliqués) : contrat §12.

## L7.2 — Changements

**Nouveaux fichiers**
- `lib/koach_engine.dart` : moteur (Kalman 1D par mouvement en masse système, courbe %1RM(n), biais de RIR, courbe personnelle ancrée sur les tests, endurance, bornes inférieures, séance atypique, D24, D25, D26, D27, D28, grilles D23, échelle D9, rejeu et cache incrémental).
- `lib/koach_data.dart` (section `koach` de la sauvegarde, bornes, lecture stricte à l'import / tolérante au démarrage), `lib/koach_program.dart` (annotations), `lib/koach_store.dart` (extension du store : entrées du moteur, décisions, pesées, objectifs, structure, charges avec Koach).
- `lib/koach_widgets.dart` (fiche de difficulté, ligne Koach des séries, suggestion, fatigue, questionnaire, calibrage, pesée, rappel d'accueil), `lib/koach_screens.dart` (bilan Koach, écran Koach avec courbe, objectifs, matériel, pesées, informations d'activation et des questionnaires).
- `assets/koach_program.json.gz` (généré par `tools/koach_annotate.py` ; asset du programme inchangé, empreinte LC1 vérifiée).
- `tools/koach_reference.py`, `tools/koach_simulation.py`, `tools/koach_annotate.py`, `tools/tests/test_koach_reference.py` ; `test/fixtures/koach/*.json` (26 cas partagés), `test/fixtures/l7_2x_snapshot.json.gz`.
- `docs/CONTRAT_L7.md`, `docs/CONFIDENTIALITE_KOACH.md` ; `LIVRAISON_L7.md` (publication, build signé, protocole téléphone) est livré à part, hors archive, comme les livraisons précédentes.

**Fichiers modifiés** (chaque branche conditionnée à Koach actif, sinon comportement 2.x)
- `lib/store.dart` : `SetEntry.effort` / `excluded`, `ExerciseLog.prescribed` / `koach` (écrits seulement s'ils existent) ; champs Koach du store ; chargement des annotations ; sauvegarde (`koach` écrit seulement si Koach a servi), import (section stricte, difficulté 0-5 par pas de 0,5), démarrage (tolérant, entrées ignorées comptées), effacement ; `toggleSet(…, exercise:, week:)` (D8, prescription datée) ; `setValue` et `configureStart` (D12, D33) ; `loadFor`, `sessionLoad`, `loadLabel(week:)`, `kgFieldText` (D23, D26, D28) ; `exLog` (D28) ; aperçu d'import (Koach).
- `lib/session_screen.dart` : fiche de difficulté à la validation, lignes Koach sous les séries validées (appui long sur le numéro), suggestion et fiche, fatigue, questionnaire, calibrage, prescription datée en historique, bilan Koach avant le bilan de récompenses, charges de la semaine.
- `lib/settings_screen.dart` (section Koach, 3.0.0), `lib/stats_performance.dart` (tuile Koach), `lib/home_screen.dart` (rappel de pesée), `lib/data_control.dart` (aperçu d'import).
- `pubspec.yaml` (3.0.0+61, asset `koach_program.json.gz`) ; `README.md` ; ce suivi.
- Workflow `build-apk.yml` **inchangé** (copie du projet identique à `.github/workflows/` de `main`). Aucune dépendance ajoutée. Aucun test existant modifié.

## L7.3 — Tests

| Niveau | Résultat |
| --- | --- |
| Python | ****50/50** en CI (39 existants + 11 Koach)** (dont 11 Koach : sorties des 26 fixtures à jour, exemples D24, cache = rejeu, contexte du cache, douleur reportée au bilan et crans en livres, critères de simulation, annotations = libellés sur 1 818 entrées) ; `verify_project.py` réussi |
| CI branche temporaire (sans secret), commit ``d245852` (run n° 53)` | Formatage : **12 fichiers L7 remis en forme par `dart format` (mise en forme seule, vérifiée), reprise telle quelle dans la livraison** ; `flutter analyze` sans problème ; tests L7 ****93/93**** ; **suite complète **535 réussis, 1 ignoré**** (442 existants inchangés + 93 nouveaux ; aucun test existant retiré, désactivé ni modifié) ; **build Android debug réussi**. Arbre livré (sources formatées reprises, commit `aceefcc`, run n° 54) : formatage **0 changement**, analyse sans problème, tests L7 93/93 |
| Défauts trouvés par les tests et corrigés | cache incrémental insensible à une pesée rétroactive (Python et Dart) ; appel d'extension par une variable (erreur d'analyse) ; courbe sans nœud d'accessibilité propre (lecteur d'écran) |
| Revue indépendante (relecture statique par un agent distinct, sans accès au travail en cours) et corrections | progression des poulies en livres bloquée quand la valeur enregistrée au centième de kg tombait sous un cran (Python et Dart, cas ajoutés) ; au bilan, douleur prise sur la seule séance au lieu de la dernière notée (Python et Dart, fixtures `pain_carry`) ; export refusé à la réimportation après activation (clé d'une ancienne sauvegarde historisée, poids du corps hors bornes des pesées) ; réactivation ignorant les valeurs modifiées pendant la désactivation ; allègement douleur impossible à lever sans questionnaire (« Lever » ajouté) ; recalcul complet à chaque frappe (cache sur l'empreinte des séances terminées) ; séance effacée dont les réponses et décisions s'appliquaient à la séance refaite ; horodatages et détails de décision non vérifiés à l'import (risque de plantage) ; liste trop longue jetée entière au démarrage (les plus récentes gardées) ; jour de fatigue sans effet sur les petits exercices (réduction répartie sur la séance, nombre affiché) ; sélecteur de date d'objectif hors bornes ; textes README/LIVRAISON trop affirmatifs. Point laissé à ta décision : D26/D28 appliqués au lest seul (contrat §12) |
| Appareil | **Non exécuté** (protocole dans `LIVRAISON_L7.md`) |

| Fichier | Couverture |
| --- | --- |
| `test/l7_koach_engine_test.dart` | Dart = Python sur les 26 fixtures (±0,01 kg, décisions exactes) ; exemples chiffrés D24 (traction +32,5 → +35 / +37,5 ; muscle-up +5 → +6,25 / +8,75 ; squat 97,5 → 100 / 102,5), baisses, décharge / douleur / verrou / refus ; bandes D25 ; grilles D23 (dont poulies en livres enregistrées au centième) ; échelle D9 et valeurs héritées ; cache = rejeu, correction, pesée rétroactive, repère modifié |
| `test/l7_koach_simulation_test.dart` | Générateur Dart = Python (athlètes identiques) ; critères C1-C7 |
| `test/l7_koach_store_test.dart` | 28 cas : désactivé par défaut et export identique à 2.5.9, état 2.5.x relu sans réécriture, activation (repère initial, pesée, échelle figée), sauvegarde 3.0.0 relue et importée à l'identique, sauvegarde 2.x importée, import strict / démarrage tolérant, effacement, suppression des réponses ; D8, D9, D11, D13, D33, D12, D2, cache du store = rejeu ; D24, D7, D6, D25, D26 ; bilan (valeur acceptée datée, journal inchangé), D27, D28 ; après revue : réimport strict après activation, réactivation, horodatages et détails refusés, séance effacée / suppression annulée, cache non recalculé à la frappe, allègement levé à la main |
| `test/l7_koach_off_test.dart` | Koach jamais activé, puis utilisé (matériel, verrou, allègement, adaptations) et désactivé : 5 jeux × 1 818 exercices identiques à l'instantané 2.x ; journal sans difficulté exigée ni prescription |
| `test/l7_koach_screens_test.dart` | Six boutons à la validation (fiche fermée = non validée), suggestion appliquée / refusée, série écartée, questionnaire et « Passer », jour de fatigue, fin de séance → bilan Koach → retour, activation expliquée, questionnaires après information ; 6 écrans Koach + séance sans débordement à 390 × 844 et 320 × 720, texte 100 / 130 / 200 %, défilement par gestes, libellés d'accessibilité |

Simulations (60 athlètes par cas, graines fixées ; contrat §8) : C1 2,25 % / 3,26 % (p95 / max, seuil 3 %), C2 2,33 % / 3,52 %, C3 0,49 % / 1,08 % (seuil 1 %), C4 0,45 / 0,61 RIR (seuil 0,5), C5 1, C6 0, C7 0 kg. Ces résultats dépendent du modèle simulé : ce ne sont pas des preuves d'efficacité.

## L7.4 — Limites, validations restantes, publication

| Statut | Éléments |
| --- | --- |
| **Corrigé dans le code** | KT-024 à KT-036 selon D1-D37 (tableau §2 du contrat) |
| **Testé automatiquement** | Voir L7.3 (CI sans secret ; build signé : `LIVRAISON_L7.md`) |
| **Vérifié sur appareil** | **Rien** |
| **Reste à valider** | Essais sur téléphone (protocole `LIVRAISON_L7.md`) ; paramètres du modèle par un préparateur physique compétent (σ_jour 5 %, seuil atypique 5 %, bruit des séries, fenêtre du biais, a priori de k tiré des libellés, plafonds D20, bandes D25, allègement D26, décharge D28, incrément machine) ; qualification juridique des questionnaires et du poids (`docs/CONFIDENTIALITE_KOACH.md` §6) ; saisie par toi de tes objectifs finaux (D27, valeurs dans `LIVRAISON_L7.md`) |

- **Identifiabilité** : sans test 1RM, 1RM, courbe et biais de RIR ne sont pas séparables (contrat §4.3) ; la courbe personnelle bouge surtout autour des tests (S1, S25, S39).
- **Incidents non signalés** : dégradent l'estimation (simulation : ≈ 7 % au p95) ; « série écartée » est essentielle.
- **Performance** : l'état est recalculé à chaque changement du journal (cache par révision et par jour, reprise incrémentale) ; non mesuré sur téléphone.
- **Accessibilité** : 320 px, texte 200 %, libellés TalkBack testés en widget ; TalkBack réel non essayé.
- Branche temporaire `claude/ci-tools` toujours présente (suppression par le propriétaire).

**L4b (clos)** — séances fiables et reprise (KT-009, KT-018) corrigées dans le code et testées automatiquement ; publication et build : `LIVRAISON_L4b.md` (2.5.9+60, `main` `f71c360`, run n° 79 réussi). Aucune vérification sur téléphone.

## L4b.0 — Base

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` **L4** (= `main`, commit `ad1bbd4`), **1 436 941 octets**, SHA-256 `66e259b6bb36c8d74338971fe27641bdd9320dc6be0d85a8bcabb2b4f384869a`, racine unique `streetlift_tracker/`, **2.5.8+59** | Vérifié (fichier et `main` identiques) ; source intacte, travail sur copie |
| Build 2.5.8 | Run n° 78 réussi (APK/AAB signés) | Résultat GitHub |
| État initial | Arbre L4 : formatage, analyse sans problème, **411 réussis, 1 ignoré**, build debug réussi ; Python 39/39 | CI (L4) + local |
| Défaut bloquant préalable | Aucun défaut ouvert de compilation, de calendrier ou de conservation : pas de correctif isolé préalable | Constat |
| Essais téléphone L1b → L4 | **Non rapportés** : rien n'est marqué « vérifié sur appareil » | — |

## L4b.1 — Constats A0 et examen ciblé

| Constat | Classement | Scénario / fichiers | Traitement |
| --- | --- | --- | --- |
| Coche d'une série sans validation (KT-009) | **Défaut confirmé** | `session_screen.dart` `_checkSet` basculait `done` sans contrôle : série validée vide ou avec « 8 reps » (sans valeur lisible) ; charge « 1e3 » lue 1 000 kg ou « Infinity » par `double.tryParse` (`game.dart` `_kg`), donc comptée dans les records | Corrigé : `set_validation.dart`, `AppStore.toggleSet/revalidateSet` |
| Import sans validation numérique des séries | Conservé volontairement | `_parseBackup` | Anciennes données lues telles quelles (compatibilité) ; seules les nouvelles coches sont vérifiées |
| Chronos uniquement en mémoire (KT-018) | **Défaut confirmé** pour le WOD (tentative L3 et chrono perdus à la destruction) ; repos : conforme à la décision (non relancé) | `timers.dart`, `wod_screen.dart` | Point sûr WOD persisté (`activeWod`) |
| Séances après destruction | **Déjà partiellement corrigé** (L2) : journal écrit après 600 ms ; pas de repère « en cours », ouverture sur le 1er exercice | `store.dart` `saveLogs`, `session_screen.dart` | État « en cours » dérivé, page de reprise, bandeau |
| Fin de séance annoncée avant l'écriture | **Défaut confirmé** | `_FinishPage` : `markSessionDone` sans attente, retour et bilan immédiats | `finishSession` + « Réessayer l'enregistrement » |
| Rappel touché alors que la séance est ouverte | **Défaut confirmé** | `openProgramDay` empilait toujours une nouvelle route (double appui, rappel à chaud) | Registre des écrans de journée |
| Repos : heure système reculée | **Défaut confirmé** | `TimerCtl` : échéance en heure murale → repos rallongé d'une heure | Durées bornées par l'horloge monotone |
| Repos : bip ancien rejoué au retour | **Défaut confirmé** | `TimerCtl._tick` bipait une fois quelle que soit l'ancienneté de la transition | Alerte seulement si < 1,5 s |
| Repli approximatif si l'alarme exacte est refusée | Déjà présent (A0), testé | `notifications.dart`, `notifications_test.dart` | Inchangé |
| Historique modifié par consultation | Déjà corrigé (L1b-R2 : copie détachée) | `session_history.dart` | Test de non-mutation ajouté |

## L4b.2 — Décisions (tes déclarations du 26/09/2026)

| Arbitrage | Décision |
| --- | --- |
| WOD après destruction / arrêt forcé / redémarrage | Pause au dernier temps sûr ; tentative et droit de finir retrouvés ; « Reprendre » (absence non comptée) ou saisir le score |
| Repos entre séries après destruction | Non relancé ; séance rouverte sur l'exercice en cours ; verrouillage : le repos continue à l'heure réelle |
| Valeur d'une série | Obligatoire pour valider ; kg / RIR-RPE / vitesse facultatifs mais vérifiés ; 0 seulement pour un test max ; lest négatif accepté |
| Séances en cours | Fonctionnement actuel + reprise visible : plusieurs brouillons, quitter ≠ abandonner, fin partielle possible (XP inchangée), badge « En cours », abandon = « Effacer l'historique », un seul WOD chronométré |

Décisions prises par l'IA dans ce cadre (exposées, modifiables) : série validée puis rendue invalide → repasse non validée ; correction depuis l'historique → ouverture sur le 1er exercice (pas la page de reprise) ; un rappel vers une autre journée referme la séance ouverte (brouillon gardé) ; point sûr WOD toutes les 15 s de temps actif ; RIR 0-99 et RPE 1-10 par pas de 0,5 ; |kg| ≤ 10 000 (borne technique déjà utilisée à l'import).

## L4b.3 — Changements

- **`lib/set_validation.dart`** (**nouveau**) : contrat des champs, `parseLoadKg`, `parseWholeNumber`, `parseEffort`, `parseVelocity`, `checkSet` (champ fautif + message).
- **`lib/store.dart`** : `toggleSet` / `revalidateSet` (validation métier, heure de validation = horloge du store) ; `finishSession` (bilan mis de côté jusqu'à l'écriture acceptée) ; `inProgress`, `sessionsInProgress`, `resumePage` ; tentative WOD : `startAttempt(replace:)` (un seul WOD actif), `activeWod` + `checkpointWod` + `_restoreActiveWod` (lecture stricte, illisible → ignoré, reste chargé), `abandonAttempt` efface le point sûr, `recordWodResult` l'efface dans la même écriture, `dataEpoch` (import / effacement) ; document local = export + `activeWod` (`_stateDocument`) ; `finishedAt` suit l'horloge du store ; `realClock`.
- **`lib/timers.dart`** : `ElapsedClock` (heure murale bornée par l'horloge monotone du processus), `TimerCtl` réécrit sur le temps écoulé (rattrapage des phases, alerte récente seulement, recul d'heure sans effet), `WodClock` sur `ElapsedClock`, `checkpoint()` / `resumePaused()`.
- **`lib/wod_screen.dart`** : reprise en pause (carte « Chrono retrouvé… »), WOD modifié → score seul, points sûrs (départ, pause, round, phase, minute EMOM, fin, 15 s), dialogue « Un WOD est déjà en cours », texte de sortie (abandon explicite).
- **`lib/session_screen.dart`** : coche via `toggleSet`, message sous la série (icône + texte, région annoncée), revalidation à la frappe, ouverture sur la page de reprise, page de fin avec attente de l'écriture et « Réessayer l'enregistrement », registre `openDayRoutes`.
- **`lib/home_screen.dart`** : `openProgramDay` sans empilement ; badge « Séance en cours » ; bandeau « À reprendre ». **`lib/resume_banner.dart`** (**nouveau**). **`lib/session_history.dart`** : enregistrement de l'écran, correction ouverte au 1er exercice. **`lib/arsenal_screen.dart`** : étiquette « EN COURS ».
- `pubspec.yaml`, `lib/settings_screen.dart` (2.5.9+60), `README.md`, `docs/SEANCES_ET_REPRISE.md` (**nouveau**), ce suivi. Workflow `build-apk.yml` **inchangé**. Aucun test existant modifié.

## L4b.4 — Tests

| Niveau | Résultat |
| --- | --- |
| Python | **39/39** en local ; `verify_project.py` réussi (1 818 exercices) |
| CI branche temporaire (sans secret), run n° 39, commit `aeb8fde` | Formatage 89 fichiers, **0 changement** ; `flutter analyze` sans problème ; tests L4b **31/31** ; **suite complète 442 réussis, 1 ignoré** (411 + 31 ; aucun test existant retiré, désactivé ni modifié) ; **build Android debug réussi** |
| Défauts trouvés par les tests et corrigés | une correction depuis l'historique ouvrait la page de reprise (test existant `history_correction_test`) → ouverture au 1er exercice |
| Appareil, destruction Android, arrêt forcé, redémarrage | **Non exécutés** (protocoles dans `LIVRAISON_L4b.md`) |

Couverture de `test/l4b_seances_test.dart` (horloges murale et monotone injectées, stockage simulé, données synthétiques ; « relance » = nouvelle instance du store sur le même stockage) :

| Matrice | Tests |
| --- | --- |
| **A. Saisie** | virgule/point, blancs et insécables, assistance « -10 » / « −7,5 », « 1.250 » « 72 5 » « 1e3 » « NaN » « Infinity » « 72,5 kg » refusés ; entiers sans unité ; RIR et RPE sur leurs échelles ; valeur obligatoire, 0 seulement en test max ; coche refusée (texte gardé) puis acceptée ; décocher/recocher sans gain ; série validée modifiée → non validée ; suggestion ≠ performance ; livres sans conversion ; écran : champ nommé, message effacé à la frappe |
| **B. Parcours** | séance en cours retrouvée après relance (même clé, page de reprise, bandeau, badge) ; séance seulement ouverte non « en cours » ; séance perso répétée (archive intacte, modèle renommé) ; reprise après minuit ; historique consulté sans mutation (export et stockage identiques, 2 thèmes, défilement) |
| **C. Temps** | heure reculée d'1 h (monotone), veille (heure murale), rafraîchissements manqués (bonne phase, 0 bip ancien, 1 bip récent), 4 pauses et frontière de phase à la milliseconde, point sûr → nouveau processus 2 h plus tard avec monotone repartie à 0 (en pause, aucune alerte, absence non comptée), tenue terminée ≠ série validée |
| **D. Finalisation** | double demande parallèle (un bilan, XP / registre / date de fin inchangés) ; écriture refusée → pas de bilan, relance = en cours, nouvel essai = un bilan, relance après écriture = aucun gain ni bilan ; écran : « Réessayer l'enregistrement », double appui |
| **E. Navigation** | rappel ×3 (dont 2 dans la même image) → une séance ; autre journée → la première refermée ; journée faite → historique sans écriture ; charge utile invalide / hors programme : test L4 du service |
| **F. Conservation** | export sans chrono ; chrono dans un fichier importé ignoré ; import et effacement l'annulent ; point sûr d'un écran de l'ancien état ignoré ; chrono illisible → ignoré, reste chargé ; ancienne sauvegarde sans chrono → rien de synthétisé ; calendrier L4 inchangé |
| **G. WOD** | Tabata retrouvé en pause (phase, chiffres, aucun bip, 30 min sans effet, « Reprendre », sortie = abandon) ; essai lancé à 23 h 50 terminé après minuit (une tentative, un résultat, aucune acquisition) ; un seul WOD chronométré, abandon explicite |
| **Écrans** | 320 px à 130 % (clavier ouvert) et 200 %, clair/sombre : message d'erreur et bandeau sans débordement ; message annoncé comme région dynamique |

## L4b.5 — Limites et suites

- **Aucun essai sur appareil**, aucune destruction réelle du processus, aucun arrêt forcé ni redémarrage réels : la « relance » des tests est une nouvelle instance du store sur le même stockage simulé. Protocoles dans `LIVRAISON_L4b.md`.
- **Alertes pendant l'absence** : repos, transitions et fin de WOD sont des sons de l'application ; processus suspendu ou détruit → non joués. Seuls les rappels du programme sont des alarmes natives.
- **Horloge monotone** : `Stopwatch` du VM Dart = `CLOCK_MONOTONIC` sur Android (s'arrête en veille profonde) ; l'heure murale reste la mesure principale ; un saut d'heure en avant est compté comme une veille. Une horloge incluant la veille (`SystemClock.elapsedRealtime`) demanderait un canal natif : non ajouté (proposition, non nécessaire aux règles approuvées).
- **Perte possible** : 600 ms de frappes avant une destruction ; pour un WOD, le temps actif depuis le dernier point sûr (≤ 15 s).
- **Célébration** : présentée au plus une fois, en mémoire ; une destruction pendant le bilan ne le rejoue pas (gains conservés).
- **Réglage « écran allumé »** : appliqué à l'ouverture de la séance ou du WOD, pas pendant.
- Séance perso dont le modèle est supprimé : son brouillon reste dans le journal mais n'est pas proposé dans « À reprendre ».
- Branche temporaire `claude/ci-tools` toujours présente (suppression par le propriétaire).

**L4 (clos)** — départ personnel (S1 · J1 = date choisie) et références « non renseignées / renseignées / à vérifier » corrigés dans le code selon tes décisions du 26/09/2026 ; installation existante migrée sans rien déplacer ; testé automatiquement. Publication et build : `LIVRAISON_L4.md` (2.5.8+59, `main` `ad1bbd4`, run n° 78 réussi). Aucune vérification sur téléphone.

## L4.0 — Base

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base retenue | `streetlift_tracker_v33.zip` **LC1** (= `main`, commit `043a1d2`), **1 401 617 octets**, SHA-256 `822ebbd656aedab9b76fa5e347c42dfbbd74ae4db2e912aa2d1865402c867a77`, racine unique `streetlift_tracker/`, 316 fichiers, **2.5.7+58** | Vérifié ; source intacte, travail sur copie |
| Écart avec la demande | La demande cite « la dernière livraison L3b ». LC1 (révision S12-S19) a été livrée **après** L3b dans cette conversation, construite sur L3b, et publiée (run n° 77) : c'est elle qui est installable. Repartir de L3b aurait retiré le contenu S12-S19 révisé. **Divergence signalée** : le programme compte **1 818** exercices (LC1), pas 1 954. | Constat |
| État initial | Arbre LC1 : formatage 0 changement, `flutter analyze` sans problème, **359 réussis, 1 ignoré**, build debug réussi ; Python 39/39 ; `verify_project.py` 1 818 exercices | CI (branche temporaire, LC1) + local |
| Défaut bloquant préalable | Aucun défaut de compilation ou de conservation des données ouvert : aucun correctif isolé nécessaire avant la migration | Constat |
| Essais téléphone L1b → LC1 | **Non rapportés** : rien n'est marqué « vérifié sur appareil » | — |

## L4.1 — Décisions (déclarations du propriétaire, 26/09/2026)

| Arbitrage | Décision | Appliqué |
| --- | --- | --- |
| Date de départ | « Date = S1 · J1, tout jour » | `Program.start`, J1 = jour choisi |
| Bornes | « Passé ≤ 280 j, futur ≤ 1 an, report » | `AppStore.startPastDays = 280`, `startFutureDays = 365`, bouton « Plus tard » |
| Références inconnues | « Inconnu par défaut + « Je ne sais pas » » ; accessoires à compléter plus tard | Aucune valeur embarquée copiée ; `referenceStatus` |
| Installation existante | « Garder + modifiable sans remise à zéro » : départ = 13/07/2026, références gardées « historiques » et utilisées, vérification proposée jamais imposée ; changement de départ dans Réglages avec aperçu ; séances faites gardées (même S·J, mêmes dates réelles) ; rappels replanifiés | Migration + écran « Départ du programme » |

**Arbitrages encore ouverts** : aucun pour L4. Points exposés (non tranchés, comportement antérieur conservé) : §L4.4.

## L4.2 — Changements

**Modèle et calendrier** (`lib/models.dart`) : `Program.start` (date civile, `null` = non démarré) ; `dateFor` refuse sans départ ; `weekFor` / `dayFor` / `containsDate` / `beforeStart` / `afterEnd` / `endDate` / `weekDates` sur jours civils (`civilIndex`) ; `legacyDateFor` (ancrage 13/07/2026) réservé aux anciennes séances sans date. Les dates textuelles de l'asset ne sont plus affichées ; l'asset n'est pas modifié.

**Store** (`lib/store.dart`) :
- Installation neuve (aucune clé d'une version antérieure) : non démarrée, références vides. Installation ≤ 2.5.7 (document unique sans `programStart`, ou anciennes clés) : départ 13/07/2026, origine `migration`, références conservées « historiques ». Les clés écrites au tout premier lancement (catalogue, version des crédits) ne comptent pas : une première ouverture interrompue reste neuve.
- `referenceStatus` (`set` / `historic`), `startOrigin` ; `setValue` (domaine vérifié, « renseignée »), `confirmReference`, `clearReference` (« Je ne sais pas »), `resetPilotage` (toutes non renseignées) ; `loadNeedsReference` / `missingReference` / `referenceLabel`.
- `configureStart(date, references)` : bornes, validation, application, **écriture par la file L2** ; succès seulement après écriture acceptée ; échec → état précédent rétabli, `StartSave.unsaved`.
- Sauvegarde : `programStart` et `referenceStatus` (format 3, champs optionnels) ; import : ancienne sauvegarde migrée, fichier récent restauré tel quel, invalide refusé en entier (§ docs) ; aperçu d'import : départ du fichier et du téléphone, références renseignées / à vérifier ; effacement L2b : état d'installation.
- Charges et volumes : « à renseigner » / « N × ? reps » quand la référence manque ; aucune pré-saisie de répétitions calculée sur 0.

**Calculs dérivés** : `lib/progression.dart` (repli de date des anciennes séances = ancrage d'origine, indépendant du départ) ; `lib/game.dart` (plus de poids de 70 kg par défaut : force indisponible sans poids du corps, calcul partiel signalé ; technique à partir du lest muscle-up) ; `lib/notifications.dart` (aucun rappel sans départ ; départ dans la signature de planification → replanification sans doublon).

**Écrans** : `lib/program_start.dart` (**nouveau** : écran « Départ du programme », bandeau d'accueil) ; `lib/home_screen.dart` (bandeau dans la liste des journées, dates de semaine personnelles, « semaine actuelle » seulement dans le programme) ; `lib/settings_screen.dart` (section « Programme » : départ, références ; 2.5.8) ; `lib/pilotage_screen.dart` (provenance, « C'est bien ma valeur », « Je ne sais pas », champ vide si inconnu, virgule décimale, convention lest / barre) ; `lib/session_screen.dart` (charge / volume sans référence : la référence manquante est nommée — infobulle, lecteur d'écran — et un appui ouvre Références, sans ligne supplémentaire) ; `lib/stats_performance.dart` (cartes « Non renseigné ») ; `lib/game_widgets.dart` (attribut « indisponible », quête principale selon l'état du calendrier) ; `lib/data_control.dart` (aperçu d'import) ; `lib/persistence.dart` (`StartSave`).

**Tests modifiés (sans retrait d'assertion de comportement conservé)** — chaque fois parce qu'une instance de test neuve est désormais une installation neuve (non démarrée, sans référence) :

| Fichier | Modification | Justification |
| --- | --- | --- |
| `test/l2_fixtures.dart` | historique rempli daté par `legacyDateFor` | mêmes dates qu'avant (calendrier d'origine) ; `dateFor` refuse sans départ |
| `test/notifications_test.dart` | `setUp` : départ 13/07/2026 | scénarios d'une installation existante ; cas non démarré ajouté en L4 |
| `test/store_test.dart` | test des changements d'heure : départ 13/07/2026 | idem |
| `test/programme_test.dart` | `setUpAll` : départ 13/07/2026, origine migration | parcours d'accueil en semaine 8 |
| `test/lc1_programme_test.dart` | valeurs du classeur saisies explicitement ; 120 kg vérifié dans l'asset puis saisi | les références ne sont plus copiées ; assertion de l'asset conservée |
| `test/stats_test.dart` | référence B8 renseignée avant de la modifier | scénario « modifier une référence existante » |
| `test/l2_persistence_test.dart` | limite de nœuds : références saisies avant l'export | export de taille comparable à avant L4 |
| `test/l2b_data_control_test.dart` | après effacement : aucune référence, non démarré (au lieu du poids embarqué) | **changement de règle voulu** (KT-007) |

**Autres** : `test/l4_depart_test.dart` (**nouveau**) ; `docs/DEPART_PROGRAMME.md` (**nouveau**) ; `pubspec.yaml` (2.5.8+59) ; `README.md` ; ce suivi. Workflow `build-apk.yml` **inchangé**.

## L4.3 — Tests et comparaisons

| Niveau | Résultat |
| --- | --- |
| Python | **39/39** en local ; `verify_project.py` réussi (1 818 exercices, 280 jours) |
| CI branche temporaire (sans secret) | Formatage 86 fichiers (1 fichier de test remis en forme par la CI, arbre livré = arbre testé) ; `flutter analyze` sans problème ; tests L4 **52/52** ; **suite complète 411 réussis, 1 ignoré** (359 + 52 ; aucun test retiré ni désactivé) ; **build Android debug réussi** (run CI n° 30, commit `88785e0`) |
| Mesure « avant » | code LC1 inchangé + `lc1_snapshot_test.dart` (même état synthétique), exécuté en CI : 1/1 |
| Défauts trouvés par les tests et corrigés | bandeau d'accueil au-dessus de la liste : à 320 px / 200 %, il aurait écrasé les journées (débordement de 103 px) → placé dans la liste ; ligne « référence non renseignée » en séance : repoussait les 5 séries sous le pli à 360 × 760 (test existant) → nommée par infobulle / lecteur d'écran sans ligne supplémentaire ; provenance manquante dans un fichier retouché : refus trop strict → valeur gardée « à vérifier » |
| Appareil | **Aucun essai** |

Couverture de `test/l4_depart_test.dart` (**52 tests**, horloge `storeClock` fixée au 26/09/2026 10 h, stockage simulé, données synthétiques) :

| Exigence | Tests |
| --- | --- |
| Installation neuve à une autre date que l'ancrage ; première ouverture interrompue | non démarrée, références vides, export `pending`, relance identique |
| Départ confirmé / différé / futur / passé ; bornes | −280 et +365 inclus, −281 / +366 refusés ; « Plus tard » ; futur (jeudi 01/10) ; passé (31/08 → S4 · J6 aujourd'hui) ; 20/12/2025 → S40, fin |
| Jour non lundi, limites de semaine | départ mercredi : J1 = mercredi, S2 · J1 le mercredi suivant, 23 h 59 / 0 h 05 |
| Mois, année, 29 février, heure d'été / d'hiver | 29/12/2026 → 01/01/2027 ; 26/02/2028 → 29/02 puis 01/03 ; 31/01 ; 25/10/2026 et 28/03/2027 |
| Début S1, fin S40, avant, après | `endDate` = S40 · J7 ; après : S40, jamais S41 ; bandeau avant / pendant (absent) / après |
| Utilisateur avancé migré ; ancienne installation sans séance ; migration deux fois | état 2.5.7 : S11, dates réelles, références, XP, crédits, droits identiques ; réglages seuls → 13/07/2026 ; relance → même état et même document |
| Sauvegardes anciennes / récentes / invalides / aller-retour | 2.5.8 ↔ 2.5.8 ; non démarré restauré tel quel ; ancienne → 13/07/2026 « à vérifier », aperçu ; 11 fichiers invalides refusés sans rien modifier ; clé inconnue « à vérifier » conservée en aller-retour |
| Références inconnues / partielles / explicites / historiques ; valeur égale à l'ancienne valeur embarquée | « à renseigner », « ? », aucune pré-saisie ; PdC seul insuffisant ; saisie = « renseignée » ; confirmation sans changement de valeur ; « Je ne sais pas » ; tout effacer (calendrier gardé) |
| Unités et saisies locales | virgule, point, vide, texte, `NaN`, `Infinity`, `1e3`, négatif, 3 décimales, 10 000 / 10 000,5 ; livres : valeurs en kg inchangées après 5 bascules |
| Annulation, double confirmation, échec d'écriture puis nouvel essai | magasin et écran : « Plus tard », retour système, double appui, écriture refusée (message, écran gardé, état rétabli), nouvel essai |
| Persistance après relance | départ, origine, références, provenances |
| Rappels | aucun sans départ ; premier le jour de S1 · J1 ; changement → mêmes identifiants, 280, aucun doublon ; échec natif visible, départ conservé, reprise ; ancienne notification → même S · J, à froid et à chaud, hors programme ignorée |
| Aucune création par migration ou changement de date | séances, XP, niveau, crédits, gains, droits identiques ; semaines civiles de progression identiques |
| Sélections L3, résultats L3b | essai du jour et vitrine identiques après changement ; résultat WOD (`tabata/1`, intervalles) identique après migration, relance, changement de départ et import |
| Écrans | premier départ ; installation existante (aperçu « S11 · J6 → S1 · J6 ») ; même date (bouton inactif) ; Références (provenance) ; séance (référence manquante nommée, appui → Références) ; accueil non démarré ; 320 px à 130 % et 200 %, 390 px, clair / sombre, clavier ouvert, libellés accessibles |

**Comparaison avant / après** — même état synthétique (utilisateur avancé : S1 à S10 faites à leur date prévue, une séance ancienne sans date, poids 81,5 kg, traction lestée 32,5 kg, autres références du classeur), le 26/09/2026 10 h, rappels 7 h 30, Europe/Paris. « Avant » = code LC1 2.5.7 **inchangé** exécuté en CI ; « après » = 2.5.8.

| Mesure | Avant (2.5.7, code LC1) | Après migration (2.5.8) | Après relance | Après changement de départ au 21/09/2026 |
| --- | --- | --- | --- | --- |
| Semaine affichée | S11 · J6 | S11 · J6 | S11 · J6 | S1 · J6 (voulu) |
| Départ / origine | ancrage 13/07/2026 | 13/07/2026 · migration | idem | 21/09/2026 · user |
| Dates prévues S11 | 21/09→27/09/2026 | 21/09→27/09/2026 | idem | 30/11→06/12/2026 |
| Séances (clés S·J) | 60 | 60 | 60 | 60, mêmes clés |
| Date réelle S6-J4 | 2026-08-20T19:00 | 2026-08-20T19:00 | idem | 2026-08-20T19:00 |
| Séance S1-J2 sans date | sans date | sans date (repli 14/07/2026) | idem | sans date (repli inchangé) |
| Poids du corps / traction lestée | 81,5 / 32,5 kg | 81,5 / 32,5 kg, « à vérifier » | idem | idem |
| XP / niveau | 7 870 / 16 | 7 870 / 16 | 7 870 / 16 | 7 870 / 16 |
| Crédits disponibles / gains enregistrés | 63 / 63 | 63 / 63 | 63 / 63 | 63 / 63 |
| Droits WOD | 0 | 0 | 0 | 0 |
| Rappels (tous les jours, 7 h 30) | 204, premier S11-J7 le 27/09 | 204, premier S11-J7 le 27/09 | idem | 220, premier S1-J7 le 27/09 (S1-S10 faites : pas de rappel) |

Aucune valeur « après migration » ne diffère de « avant ». Le changement de départ ne modifie que la semaine affichée, les dates prévues et les rappels.

## L4.4 — Limites et points exposés

- **Aucun essai sur appareil** : parcours, rappels natifs, sélecteur de date et migration réelle de ton installation restent à vérifier (protocoles dans `LIVRAISON_L4.md`).
- **Titres de saison** « Touche-à-tout » et « Gardien du repos » : calculés sur la saison **en cours**, ils suivent la position dans le calendrier (comportement antérieur). Aucun crédit n'en dépend. Changer de départ peut les faire passer d'obtenu à non obtenu (ou l'inverse) : effet métier hors contrat L3, **exposé, non tranché**.
- **Objectif hebdomadaire automatique** : plafond = journées de la semaine de programme courante ; suit le calendrier. Crédits de semaine complète (semaine civile) non concernés.
- **Départ avancé avant des séances faites** : ces journées restent faites (clé S·J), leurs rappels ne sont pas recréés — conforme à la décision (« mêmes S·J »).
- **Référence manquante en séance** : nommée par l'infobulle (appui long), le lecteur d'écran et l'écran Références ; pas de ligne visible supplémentaire, pour garder les 5 séries visibles sans défilement à 360 × 760.
- Ancien fichier de sauvegarde avec une clé de référence inconnue : conservée « à vérifier », non affichée.
- Validation générale des séries, reprise après destruction du processus : **L4b** (non lancé).
- Branche temporaire `claude/ci-tools` toujours présente (suppression par le propriétaire).

**LC1 (clos)** — contenu S12-S19 révisé selon les décisions du propriétaire du 26/09/2026 ; reste du programme et feuille Pilotage identiques ; recalcul des volumes pendant une séance corrigé ; testé automatiquement. Publication et build : `LIVRAISON_LC1.md` (2.5.7+58, `main` `043a1d2`, run n° 77 réussi). Aucune vérification sur téléphone.

## LC1.0 — Base

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` L3b (= `main`, commit `d614567`), **1 377 724 octets**, SHA-256 `b471b73a37d27862ed418195a001a8c94429d593e4fdec25d170e539325ff566`, racine unique `streetlift_tracker/`, 313 fichiers, version **2.5.6+57** | Vérifié ; source intacte, travail sur copie |
| Build 2.5.6 | Run n° 76 réussi | Résultat GitHub |
| État initial | Arbre identique à celui testé pour L3b : formatage 0 changement, `flutter analyze` sans problème, **347 réussis, 1 ignoré**, build debug réussi ; Python 33/33 et `verify_project.py` réussis en local sur la base | CI (branche temporaire, L3b) + local |
| Asset d'entrée | `assets/programme_v33.json.gz` : JSON décompressé 815 022 octets, SHA-256 `0330e9a6…d7d4` (1 954 exercices) | Vérifié par le script |
| Essais téléphone L1b → L3b | **Non rapportés** | — |
| Décisions LC1 | Section 3 de la demande du 26/09/2026 (R1 à R6, contenu jour par jour) | Déclaration du propriétaire |

**Version** : la demande indique « 2.5.6 » et une mise à jour « par-dessus 2.5.5 », mais 2.5.6 est déjà publiée (L3b, run n° 76). Pour que « Réglages → À propos » distingue les deux contenus, cette livraison porte **2.5.7+58** ; elle s'installe par-dessus 2.5.6 (ou 2.5.5).

**Classeur du propriétaire désynchronisé** : l'asset est désormais la référence. `tools/xlsx_to_json.py` régénérerait l'ancien contenu S12-S19 : il ne doit plus être lancé sur le classeur actuel. Toute révision passe par un script déterministe sur l'asset (ici `tools/lc1_revision_s12_s19.py`).

## LC1.1 — Changements

**Script** `tools/lc1_revision_s12_s19.py` : vérifie l'empreinte de l'entrée (JSON 2.5.6), refuse une seconde exécution (« Révision LC1 déjà appliquée »), contrôle chaque liste d'origine jour par jour, applique la section 3, vérifie l'empreinte de sortie (SHA-256 du JSON révisé `399450dc…5328`) et l'intégrité du reste, écrit le `.gz` de façon reproductible (niveau 9, horodatage nul). Aucune nouvelle formule ni nouveau type : `text`, `volume`, `barbell`, `acc`, `fixed` existants.

**Identifiants** : lignes conservées ou modifiées → identifiant inchangé ; 202 identifiants retirés ; 66 lignes nouvelles `B2-L1-001` à `B2-L1-066`, attribuées dans l'ordre semaine → jour → position, jamais réutilisées. Total : 1 954 − 202 + 66 = **1 818** exercices.

| Jour | Supprimé (S12-S19) | Modifié (identifiant conservé) | Ajouté (`B2-L1-…`) |
| --- | --- | --- | --- |
| **J1** | Tirage vertical prise neutre, rotations externes, scapular pull-ups | MU lesté et traction lestée (R1-R3) ; rowing 3×8 (2×8) ; curl EZ 2×10 (1×10), RIR 2, 90 s, consigne, charge acc 10 reps ; face pulls 3×18 (2×18) ; poignet (2×15 en décharge) ; conduite sans GtG | — |
| **J2** | Dips à résistance accommodante (absents des décharges), développé couché, YTW, poignet | Dip lesté (R1-R3) ; pompes lestées et développé militaire 3×8 (2×8) ; extension triceps en myo-reps 1×12-15 puis 4×(4) (2×(4)), 10 s intra, consigne ; rotations externes 2×15/bras | — |
| **J3** | Fentes marchées, hip thrust, mollets debout, hollow body hold, pallof press, poignet | Back squat (R1-R3) ; conduite « GtG : 3 × 4 muscle-ups PdC répartis dans la journée. » | Squat pause 2 s (2×4 ; 1×4) ; GtG muscle-up (3×4 ; 2×3), dernière ligne |
| **J4** | Tirage horizontal poulie, scapular pull-ups ; S12 : tractions PdC — clusters | S13-S19 : tractions clusters, coefficient − 0,6, consigne ; rowing haltère 3×10 (2×10) ; curl marteau 2×12 (1×12), RIR 2, 90 s, acc 12 reps ; dead-hang 2× (1×) max effort ; face pulls 3×18 (2×18) | S12 : test max tractions, tractions séries continues (2 × round(1,2 × B17 / 2)) ; S13-S19 : série de référence 1 × round(0,6 × B17) ; toutes : poignet (copie de J1) |
| **J5** | Extension triceps, rotations externes, poignet ; S12 : dips et pompes clusters | S13-S19 : dips et pompes clusters (coef. − 0,6, consigne), pompes renommées « Pompes PdC — clusters » (voir LC1.3) ; conduite GtG | S12 : tests max dips puis pompes (repos 5 min) ; S13-S19 : séries de référence dips (0,6 × B18) et pompes (0,6 × B19) ; toutes : GtG |
| **J6** | Isométrie transition, excentriques lestés, négatifs, transitions à l'élastique, isométrie bas de dip, false grip hold, HIIT court ; S12 : squat endurance | Titre « PUISSANCE MU + SQUAT ENDURANCE » ; conduite ; tractions explosives 4×3 (3×3) + consigne +5 kg | Muscle-ups PdC explosifs 4×3 (3×2) ; S12 : test max squat @ 70 kg |
| **S12** | — | Conduites J1-J6 : « SEMAINE DE RECALAGE — sortie de décharge. » ; J4-J6 : « Test en tête de séance… » | — |

Entre parenthèses : valeurs des décharges S15 et S19. R1 : tempo « Intention maximale », phrase VBT remplacée. R2 : séries classiques S12, S13, S15, S19 (y compris le muscle-up lesté en S15/S19, règle transversale), clusters S14, S16-S18. R3 : calibrage en fin de consigne (S12-S14, S16-S18) ; « Décharge : aucune hausse de charge. » en S15 et S19.

**Application** (`lib/session_screen.dart`, plus petit périmètre) :
- En-tête de séance : le bouton « Exercices » partage la ligne (libellé abrégé si besoin) au lieu de déborder à 320 px / 200 % (défaut préexistant, présent sur toutes les semaines).
- **Constat** : les tests de S2 alimentent la feuille Pilotage par **saisie manuelle** (« Résultat → Pilotage!B17 »), écran RÉFÉRENCES accessible seulement depuis STATS : impossible pendant une séance sans la quitter, et la page d'exercice ne se reconstruisait pas après une modification des maxima (volumes et reps pré-remplies restaient anciens). **Bloquant pour S12 : corrigé.**
- Menu de séance ⋮ → « Références (feuille Pilotage) » : ouvre le **même écran** de saisie (mécanisme de S2 réutilisé).
- La page d'exercice écoute le store : dès qu'un maximum change, séries × reps et charges affichées sont recalculées ; les reps **pré-remplies** des séries non validées suivent le nouveau volume ; une valeur saisie par l'utilisateur n'est jamais écrasée.
- Règle GtG sur la feuille Pilotage : l'écran n'en affiche pas ; rien à ajouter.

**Autres fichiers** : `test/lc1_programme_test.dart` (**nouveau**), `tools/tests/test_lc1_revision.py` (**nouveau**) ; totaux justifiés 1 954 → 1 818 dans `test/store_test.dart`, `tools/verify_project.py`, `tools/tests/test_tools.py` (et le titre d'un test de `test/training_estimate_test.dart`) ; `pubspec.yaml`, `lib/settings_screen.dart` (2.5.7+58) ; `README.md` ; ce suivi.

## LC1.2 — Tests et scénarios

| Niveau | Résultat |
| --- | --- |
| Python | **39/39** en local (33 + 6 nouveaux `test_lc1_revision.py`) ; `verify_project.py` réussi (1 818 exercices) ; script LC1 relancé : échec propre « déjà appliquée » |
| CI branche temporaire (sans secret) | Formatage 84 fichiers, 0 changement ; `flutter analyze` sans problème ; tests ciblés (LC1, store, estimation, historique, programme, jeu, progression, écrans) **109/109** ; **suite complète 359 réussis, 1 ignoré** (347 + 12 nouveaux ; aucun test retiré, un titre mis à jour) ; **build Android debug réussi** |
| Défauts trouvés par les tests et corrigés | En-tête de séance (« Exercice n / N » + « Exercices ») débordant de 18 px à 320 px et texte 200 % — **préexistant** (reproduit sur S8 inchangée), corrigé car il touchait toutes les pages S12 ; tests : retour de page et import hors horloge simulée |
| Appareil | **Aucun essai** |

| Données de départ | Action | Valeur attendue | Valeur observée (test) |
| --- | --- | --- | --- |
| Asset 2.5.6 | Script LC1 | 1 954 → 1 818, SHA-256 du JSON `399450dc…5328` | Conforme |
| Asset révisé | Script relancé | Échec « Révision LC1 déjà appliquée », rien écrit | Conforme |
| Asset révisé | Semaines 1-11, 20-40, Pilotage, méta | SHA-256 canonique `04ffcab8…e89b`, identique à 2.5.6 | Conforme |
| Programme | Identifiants | 202 retirés (liste exacte), 66 ajoutés (liste exacte, noms, semaine, jour) | Conforme |
| Maxima 30 / 70 / 65 / 25 | Volumes | S12 continues 2 × 18 ; réf. tractions 1 × 18 ; clusters S13/S14/S15/S18 5 × 8/10/5/11 ; réf. dips 1 × 42 ; clusters 5 × 20/22/11/25 ; réf. pompes 1 × 39 ; clusters 5 × 10/12/5/14 ; squat 70 S13 3 × 10 | Conforme |
| Maxima 33 / 80 / 70 / 30 | Volumes | 2 × 20 ; 1 × 20 ; 5 × 9/11/5/12 ; 1 × 48 ; 5 × 22/26/13/29 ; 1 × 42 ; 5 × 11/13/5/15 ; 3 × 12 | Conforme |
| 1RM squat 120 kg | Squat pause | 80 kg | Conforme |
| Séance S12 J4, page séries continues (2 × 18, reps 18/18), 1re série corrigée à 17 | Menu → Références → tractions 33 → retour | 2 × 20 affiché, reps 17/20 ; puis 30 → 2 × 18, reps 17/18 | Conforme |
| Journal S12 J1 avec `B2-9` (supprimé) | Export/import, ouverture de l'historique | Nom « Tirage vertical prise neutre », séries 65 kg × 10/9 intactes | Conforme |
| S12 J1-J6 faits | XP, semaine, crédits | +600 XP de séance, semaine complète (gain `week:` enregistré), gains existants inchangés | Conforme |
| S12 J3, J4, J5 | Rendu 390×844 et 320×720, 130 % et 200 %, clair et sombre | Aucune erreur de rendu, toutes les pages parcourues | Conforme |

**XP et économie** : aucun barème modifié. Une séance du programme vaut toujours 100 XP (indépendante du nombre d'exercices) ; semaine complète, chapitres et boss dépendent des journées faites : inchangés. **Changement d'équilibrage** (pas une correction de calcul) : séries planifiées d'une semaine de montée 198 → **117** (S12 : 102), donc le compteur de séries validées (badges « séries », mission hebdomadaire « 20 séries ») progresse moins vite ; la mission reste atteignable.

## LC1.3 — Limites et points signalés

- **Classeur désynchronisé** pour S12-S19 ; contenu **non validé par un préparateur physique extérieur**.
- **Série de référence « fixe pendant tout le bloc »** (R6) : aucun type existant ne fige une valeur à une date ; elle suit le maximum de la feuille Pilotage. Elle reste fixe tant que le maximum n'est pas modifié (seul le test de S12 le met à jour dans le bloc).
- **Calibrage (R3) et charge suggérée** : +5 kg sur le 1RM change la charge suggérée du pourcentage prévu (ex. 82 % : +4,1 kg, arrondi à 2,5), pas forcément de +5 kg ; pour les séries suivantes du jour, saisis la charge à la main comme le dit la règle.
- **Pompes clusters renommées** « Pompes PdC — clusters » (nom de la section 3) : avec l'ancien suffixe « — enchaîné après les dips », l'application aurait enchaîné cette ligne avec la série de référence des pompes (regroupement par nom). Identifiant conservé.
- **Incohérences de texte appliquées telles quelles** (contenu non rediscuté) :
  - S12 J6 : la conduite dit « Test en tête de séance » mais le test de squat est en 3e position (liste de la section 3) ;
  - S15/S19 : la conduite J3/J5 annonce « GtG : 3 × 4 » alors que la ligne GtG de décharge est 2×3 ;
  - test max pompes S12 : la consigne S2 recopiée contient « Ton 60 estimé est probablement faux au vu de tes 80 dips… » (propre à S2), et « comme en S2 » alors que le repos passe de ≥ 20 min à 5 min ;
  - tests S12 dips/pompes/squat : « Résultat → Pilotage!B18 » puis « Résultat → maximum … » (double mention) ;
  - MU lesté : « 1re rep moche → … bascule excentriques » alors que les excentriques de transition sont retirés de J6 ;
  - conduite J3 : « HSR coude » alors que le travail poignet est retiré de J3.
- Extension triceps J2 en myo-reps : référence de charge fixée à 13 reps (comme les autres lignes myo-reps) ; non précisé dans la demande.
- Nouvelles lignes de séries continues et de référence marquées « principales » (comme les clusters qu'elles complètent) ; tests au format de S2 (non principaux).
- Branche temporaire `claude/ci-tools` toujours présente.

## L3b.0 — Base et contrôle préalable

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` de la livraison L3 2.5.5 (= `main`, commit `0b36c56`), **1 344 898 octets**, SHA-256 `76c9ef4987fc98ec130c2e92ad3daac993ab02367b1a58e32f0ca171d6f12f41`, racine unique `streetlift_tracker/`, 308 fichiers, version 2.5.5+56 | Vérifié (identique à l'archive livrée en L3) ; source intacte, travail sur copie |
| Build 2.5.5 | Run n° 75 réussi (APK, AAB, validation) | Résultat GitHub |
| État initial des tests (base) | **306 réussis, 1 ignoré** ; format et analyse sans problème ; build Android debug réussi | Tests automatiques (CI, branche temporaire, commit `29e9c85`) |
| Essais téléphone L1b, L2, L2b, L3 | **Non rapportés** | — |
| Décisions L3b du propriétaire (25/09/2026) | Tabata : repos entre mouvements à la place du 10 s, fin au dernier effort ; score = total des minimums ; routine sans règle = temps noté sans record ; EMOM sans règle = minutes tenues sur N | Déclarations du propriétaire |
| Décisions antérieures conservées | KT-005 option C + registre par gain ; déficit affiché ; essai illimité jusqu'à minuit ; KT-014 ; KT-016 option A ; publication sur `main` à chaque mise à jour | Déclarations du propriétaire |

**Contrôle préalable** : aucun échec bloquant de compilation, de conservation ou de comptabilité dans la base (tests et build verts). La conservation des données après mise à jour **n'est toujours pas constatée sur téléphone** depuis L1 : exporter une sauvegarde avant d'installer 2.5.6 (protocole de `LIVRAISON_L3b.md`). L3b n'écrit aucune migration : les anciens résultats restent tels quels.

## L3b.1 — Contrats

Contrats complets, exemples, règles de comparaison et anciens résultats : **`docs/WOD_FORMATS.md`**. Résumé :

| Format (nombre) | Avant L3b (code) | Règle retenue | Origine de la règle |
| --- | --- | --- | --- |
| For Time (313), rounds (194) | Temps le plus court ; « terminé » coché par défaut | Temps le plus court ; réalisation **choisie explicitement** ; terminé au-delà du cap refusé | Code existant + consigne |
| AMRAP (118) | Rounds + reps ; toujours « terminé » | Rounds + reps ; arrêt anticipé = incomplet | Consigne (« score = rounds + reps ») |
| EMOM (148 génériques) | Rounds + reps, rounds pré-remplis par le temps | Minutes tenues sur N, jamais pré-rempli | Propriétaire |
| E5MOM `seed29` | Rounds + reps | Total de tractions | Consigne (« objectif total tractions ») |
| Death by (21) | Rounds + reps | Dernière minute réussie | Consigne (« score = dernière minute réussie ») |
| **Tabata (40)** | **Routine : chrono montant, temps le plus court = record** | Phases 8 × 20 s / 10 s, 60 s entre mouvements, fin au dernier effort ; saisie par intervalle ; total des minimums | Consigne + propriétaire |
| AMRAP en blocs (40) | Routine au temps | Phases ; total des rounds | Consigne (« score = total des rounds ») |
| Autres routines (125) | Temps le plus court = record | Temps noté, sans record | Propriétaire |

## L3b.2 — Changements

| Ticket / point | Corrigé dans le code | Testé automatiquement | Vérifié sur appareil | En attente d'arbitrage |
| --- | --- | --- | --- | --- |
| KT-008 Tabata (définition, chrono, saisie, score, records, historique) | **Oui** | **Oui** | Non | Non |
| Règles des autres formats (For Time, rounds, AMRAP, EMOM, Death by, E5MOM, AMRAP en blocs, routines) | **Oui** | **Oui** (règle, saisie, record ; runner complet pour Tabata) | Non | Précision EMOM « terminé » à confirmer (voir `docs/WOD_FORMATS.md` §1) |
| Anciens résultats (lecture historique, XP inchangée) | **Oui** | **Oui** (oracle ancienne règle) | Non | Non |

**Code**
- `lib/wod_formats.dart` (**nouveau**) : règles de score versionnées (`ScoreRule`, id `tabata/1`…), règle du WOD (`ruleFor`), lecture d'un résultat (`readRule`), valeur comparable (`performance`, jamais de valeur par défaut), record (`bestResult`, égalité = premier), groupes d'XP de record (`recordGroup`, ancienne règle conservée pour les anciens résultats), phases (`phasesOf`), libellés (règle en clair, phase, détail, texte du score, note historique).
- `lib/wod_models.dart` : `WodFormat` (définition structurée : `tabata`, `amrap-blocks`, `emom-reps`, `death-by`), `Wod.format`, `WodResult.scoring` et `WodResult.intervals` (sérialisés seulement s'ils existent), `best()` délègue à `bestResult` ; `seed29` porte `emom-reps`.
- `lib/wod_generator.dart` : familles 6 (AMRAP en blocs), 10 (Tabata, lignes écrites depuis la définition) et 11 (Death by) portent leur format. Aucune autre valeur ne change.
- `lib/timers.dart` : `WodClock.startPhases` (phase déduite du temps actif, préparation hors durée, alerte seulement si la transition date de moins de 1,5 s, compteurs d'alertes).
- `lib/wod_screen.dart` : runner par phases (nom de la phase annoncé seul, position, temps de phase et total), horloge du store ; `ScoreSheet` selon la règle (cases Tabata, réalisation explicite, bornes, zéro ≠ vide, time cap) ; notes historiques dans la liste des résultats ; `parseCount`.
- `lib/progression.dart` : XP de record par groupe de comparaison.
- `lib/store.dart` : validation d'import (`scoring` connu, `intervals` 0-999, ≤ 20 × 50, `format` cohérent).
- `lib/stats_history.dart`, `lib/wod_preview.dart` : détail du résultat et règle en clair.
- `tools/wod_catalog_snapshot.dart` (**nouveau**) : instantané du catalogue pour comparer avant/après.
- `pubspec.yaml`, `lib/settings_screen.dart` : 2.5.6+57. `docs/WOD_FORMATS.md` (**nouveau**), `README.md`, ce suivi.

**WOD modifiés** : seulement l'ajout de la clé `format` sur 102 WODs (40 Tabata, 40 AMRAP en blocs, 21 Death by, `seed29`). Définitions comparées avant/après : les 1 000 autres champs identiques (instantanés CI, empreinte vérifiée par test).

**Inchangés** : identifiants, prix, barèmes, bonus, XP de tentative, crédits et registre, essai et vitrine, droits, favoris, file d'écritures, export/import (format 3), suppression locale, workflow `build-apk.yml`, identifiant et signature.

## L3b.3 — Tests

| Niveau | Résultat |
| --- | --- |
| État initial | 306 réussis, 1 ignoré (base 2.5.5) |
| Nouveaux tests `l3b_formats_test.dart` | 41 : catalogue (5), phases (3), chrono simulé (6), score Tabata (4), autres formats (8), saisie des nombres (1), store/sauvegarde/XP/L2/L3 (8), écrans (6, dont 320 px, 130 % et 200 %, clavier ouvert) |
| Tests adaptés | `screens_test` « score invalide… » : choix « Terminé en entier » ajouté (un For Time n'est plus supposé terminé), assertion ajoutée sur ce message ; `l3_economy_test` (écran à minuit) : remplissage de la feuille selon le format de l'essai (`test/support/score_sheet.dart`). Aucune assertion retirée |
| Défauts trouvés par les tests et corrigés | Région dynamique qui englobait tout le chrono (annonce à chaque seconde) ; bouton « Valider round » visible avant le départ d'un Tabata |
| CI branche temporaire (sans secret) | Formatage : 83 fichiers, 0 changement restant ; `flutter analyze` sans problème ; tests ciblés (L3b, chrono, écrans, L3, progression, stats, boutique, estimation) **155/155** ; **suite complète 347 réussis, 1 ignoré** (306 + 41 ; aucun test retiré) ; **build Android debug réussi** ; instantané du catalogue : seules les 102 clés `format` diffèrent |
| Python | 33/33 en local ; `verify_project.py` réussi |
| Appareil | **Aucun essai** |

### Cas importants

| Données de départ | Action | Valeur attendue | Valeur observée (test) |
| --- | --- | --- | --- |
| Tabata `genx100` (3 mvts) | Phases | 47 phases, 810 s, dernier = effort 8/8 du 3e mouvement | Conforme |
| Chrono Tabata | 19,8 s → 20,0 s → 29,8 s → 30,2 s | Effort (1 s) → repos (10 s) → repos (1 s) → effort 2/8 ; 2 bips | Conforme |
| Chrono Tabata | Retour après 95 s en un rafraîchissement | Effort 4/8, 15 s restantes, 0 bip rejoué | Conforme |
| Chrono Tabata | 809 s puis 810 s puis +30 s | Fin à 810 s, une alarme, 46 bips au total | Conforme |
| Fin découverte 90 s trop tard | Rafraîchissement | Terminé, 0 alarme, 0 bip | Conforme |
| Runner 320 px | Démarrer, pause 2 min en repos, fin | Phase et chiffres figés en pause ; feuille ouverte vide ; minimums 10 · 6 · 10 → « Total 26 reps » ; record | Conforme |
| Saisie 8/8/8 avec un 0 | Minimum | 0 compté | Conforme |
| Saisie incomplète déclarée terminée | Enregistrer | Refus : « Intervalles non renseignés… » | Conforme |
| Saisie incomplète « Incomplet » (130 %, 200 %, clavier) | Enregistrer | Résultat partiel, minimums « 4 · — · — · — », pas de record | Conforme |
| Cases « -1 », « 2.5 », « abc », « 1000 » | Enregistrer | Refus « 0-999 », rien enregistré | Conforme |
| Deux Tabata 30 et 33, puis 33 | Record | Le premier 33 | Conforme |
| Ancien Tabata au temps (600 s) | Lecture, nouveau Tabata | Conservé tel quel, non comparé ; le nouveau devient record | Conforme |
| Anciens résultats sur 6 familles | Calcul de l'XP | 400 XP de record, égal à l'ancienne règle (oracle) | Conforme |
| Sauvegarde ancienne | Import × 2 | XP, crédits, registre, essai, vitrine et résultats identiques ; aucune récompense | Conforme |
| Nouveau Tabata | Export puis import × 2 | `scoring`, `intervals`, `reps` identiques ; un seul résultat | Conforme |
| Écriture refusée | Réessai | Un résultat, une récompense | Conforme |
| Essai Tabata relancé à 23 h 59 | Validation à 00 h 01 | Enregistré (2e résultat), non acquis, plus de nouvelle tentative | Conforme |
| Import `tabata/9`, intervalle 1000 ou -1, format Tabata sur un EMOM | Import | Refusé, rien modifié | Conforme |
| For Time cap 12 min | 12:30 « terminé » | Refus « Au-delà du time cap » ; 11:40 accepté | Conforme |
| EMOM 15 | Feuille | Champ vide ; 16 refusé ; 0 accepté (« 0/15 minutes tenues ») | Conforme |

## L3b.4 — Limites et suites

- Chrono et tentative non restaurés après destruction du processus (**L4b**). Aucune persistance ajoutée.
- L'estimation de durée affichée sur les tuiles et la fiche (« ~ x min ») reste celle du modèle d'estimation ; la durée exacte du Tabata figure dans l'entête du format.
- Précision EMOM (« terminé » = mené à son terme) à confirmer ; changement simple si tu préfères « terminé = toutes les minutes tenues ».
- Ambiguïtés de texte du catalogue conservées (Death by, HYROX EMOM 30, notes génériques) : `docs/WOD_FORMATS.md` §7.
- Branche temporaire `claude/ci-tools` toujours présente : à supprimer par le propriétaire.

## L3.0 — Base et contrôle préalable

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` de la livraison L2b 2.5.4 (= `main`, commit `83d05d5`), **1 324 959 octets**, SHA-256 `8563cbb5ed3e5e76ebb076957d234b4f13135cc740adb855a32f33a7bb616a53`, racine unique `streetlift_tracker/`, 306 fichiers, version 2.5.4+55 | Vérifié ; archive gardée intacte, travail sur une copie |
| Build 2.5.4 | Run n° 74, réussi | Résultat GitHub |
| Tests L2b | 278 réussis, 1 ignoré ; build Android debug réussi | Tests automatiques (CI, branche temporaire) |
| Essais téléphone L1b, L2, L2b | **Non rapportés** | — |
| Décisions L3 du propriétaire (25/09/2026) | Tentatives d'essai illimitées jusqu'à minuit ; sans candidat : élargir le niveau, sinon pas d'essai ; registre par gain ; déficit affiché | Déclarations du propriétaire (questions posées pendant L3) |
| Décisions antérieures conservées | KT-005 option C ; KT-014 règle d'usage ; KT-016 option A ; publication sur `main` et build à chaque mise à jour | Déclarations du propriétaire |

**Contrôle préalable** : la conservation des données après mise à jour n'a pas été vérifiée sur téléphone depuis L1. L3 ajoute des champs au document interne (`creditGrants`, `trialOfDay`, `weeklyShowcase`, `attempt`) ; les versions antérieures les ignorent. Faire un **export avant d'installer 2.5.5** (protocole de `LIVRAISON_L3.md`).

## L3.1 — Contrat

Le contrat complet (règles approuvées, choix d'implémentation, limites, propositions en attente) est dans **`docs/CONTRAT_L3.md`**. Résumé :

| Sujet | Comportement actuel (avant L3) | Règle approuvée | Décision manquante |
| --- | --- | --- | --- |
| Essai lancé avant minuit | Score refusé après minuit, fiche d'achat affichée | Terminer et enregistrer la tentative engagée, sans acquisition ni accès illimité | Aucune |
| Tentatives d'essai | Illimitées de fait, non écrit | Illimitées jusqu'à minuit | Aucune |
| Essai du jour | Recalculé selon l'état ; pouvait changer après achat ou changement de niveau | Un par jour civil local, jamais tenté, stable ; persisté | Aucune |
| Achat de l'essai | Un autre essai pouvait apparaître | Acquis aussitôt, aucun second essai gratuit | Aucune |
| Plus de candidat | WOD déjà tenté proposé | ±2, puis catalogue, sinon pas d'essai + message | Aucune |
| Vitrine | Dépendait du niveau courant | Lundi-dimanche, stable ; un WOD acheté laisse sa place au suivant (README) | Aucune |
| Crédits (KT-005) | L2 : plus haut total ; une vraie nouvelle semaine sous ce plus haut ne payait rien | Registre par gain : payé une fois, jamais repris | Aucune |
| Dépensé > gagné | Solde borné à 0 | Déficit affiché, achats bloqués, droits gardés | Aucune |
| Import | Remplacement | Remplacement, pas de fusion | Aucune |
| Horloge manipulée | Non traité | — | Limites documentées ; contre-mesure non demandée |
| Tentative après redémarrage | Non | Hors L3 (L4b) | L4b |

## L3.2 — Changements

| Ticket | Corrigé dans le code | Testé automatiquement | Vérifié sur appareil | En attente d'arbitrage |
| --- | --- | --- | --- | --- |
| KT-003 — essai commencé avant minuit | **Oui** | **Oui** (store + écran, horloge contrôlée) | Non | Non (persistance de la tentative : L4b) |
| KT-004 — essai du jour et vitrine stables | **Oui** | **Oui** (jour, semaine, année, heure d'hiver, recul d'horloge, migration) | Non | Non (limites d'horloge documentées) |
| KT-005 — comptabilité des crédits | **Oui** | **Oui** (registre, doublons, paliers, import, migration, déficit) | Non | Non |

**Code**
- `lib/store.dart`
  - **Tentatives** : `startAttempt`, `canFinish`, `abandonAttempt`, `recordWodResult` (renvoie `ResultSave.saved`, `unsaved` ou `denied`). Un résultat porte l'identifiant de sa tentative ; un second envoi ne crée rien et relance seulement l'écriture en attente.
  - **Sélections persistées** : `_trialDay/_trialId` et `_weekOf/_weeklyIdsStored`, établis à la première lecture, écrits dans la file L2, jamais recalculés par une notification. Essai : `_selectTrial` (jamais tenté, ±1 → ±2 → catalogue, hors vitrine), `_migratedTrial` (reprise d'un essai joué aujourd'hui) ; vitrine : `_ensureWeekly` (remplacement d'un WOD acheté). Nouveau choix seulement si la date locale est strictement postérieure.
  - **Registre des gains** : `creditGrants` (`level:N`, `chapter:…`, `boss:…`, `week:<lundi>`, `carry:l2`), `journalGrants`, `creditsEarned` (registre + gains du journal non inscrits), inscription à chaque écriture acceptée et au chargement, `_grantsSnapshot` pour un export identique avant et après écriture, `_migrateGrants` (état sans registre, surplus L2 conservé). `credits` n'est plus borné à 0. Remplace `_earnedMax`.
  - **Sauvegarde** (format 3) : champs optionnels `creditGrants`, `trialOfDay`, `weeklyShowcase`, `attempt` validés à l'import (bornes, clés, dates) ; `creditsEarnedMax` toujours écrit pour les versions 2.5.2-2.5.4 ; l'aperçu d'import donne le total du registre du fichier.
  - `_applyBackup` classe le catalogue avant tout calcul de progression (corrige un calcul possible sur catalogue non classé lors de la migration).
- `lib/wod_screen.dart` : tentative ouverte au démarrage, abandonnée en quittant ; l'écran ne bascule plus sur la fiche d'achat tant que la tentative est ouverte ; score enregistré via `recordWodResult`, récompense après écriture acceptée, message « Réessayer » sinon ; feuille de score protégée contre le double appui, heure = horloge du store.
- `lib/persistence.dart` : `ResultSave`. `lib/wod_models.dart` : `WodResult.attempt`.
- Déficit et essai dans l'interface : `wod_store.dart` (carte de crédits, règles des crédits), `wod_catalog.dart` (message « Pas d'essai du jour »), `arsenal_screen.dart`, `game_widgets.dart`, `stats_progression.dart`, `rewards.dart`, `data_control.dart` (aperçu d'import).
- `pubspec.yaml`, `lib/settings_screen.dart` : 2.5.5+56.
- Documentation : `README.md` (section 2.5.5), `docs/CONTRAT_L3.md`, ce suivi.
- Tests : `test/l3_economy_test.dart` (nouveau) ; `test/l2_persistence_test.dart` et `test/l2b_data_control_test.dart` adaptés (voir L3.3).

**Inchangés** : barème, prix, bonus, remises et plancher ; file d'écritures, copies de secours, bornes d'import, aperçu, conflit, suppression ; workflow `build-apk.yml` ; identifiant et signature.

## L3.3 — Tests

| Niveau | Résultat |
| --- | --- |
| Nouveaux tests `l3_economy_test.dart` | 28 : 27 sur le store (instances isolées, horloge `storeClock` contrôlée), 1 widget (tentative 23 h 59 → 00 h 01 sur l'écran réel) |
| Tests adaptés | `l2_persistence_test` « import d'une sauvegarde L2 : son plus haut remplace le courant » et `l2b_data_control_test` « formats historiques et sauvegarde L2 acceptés » : le fichier simulé retire désormais `creditGrants`, pour rester une vraie sauvegarde L2 (sans registre). Assertions inchangées |
| Défauts trouvés par les tests et corrigés | Export différent avant et après une écriture (le registre n'était complété qu'à l'écriture) : 7 tests L2b en échec au premier passage ; registre vide après suppression des données |
| CI branche temporaire (sans secret) | Formatage : 80 fichiers, 0 changement ; `flutter analyze` sans problème ; tests ciblés (L3, boutique, récompenses, L2, L2b) **127/127** ; **suite complète 306 réussis, 1 ignoré** (278 + 28 nouveaux ; aucun test retiré, un renommé) ; **build Android debug réussi** ; manifeste fusionné : `allowBackup="true"` |
| Build signé 2.5.5 | Voir `LIVRAISON_L3.md` (résultat GitHub) |
| Python | 33/33 en local ; `verify_project.py` réussi |
| Appareil | **Aucun essai** |

### Scénarios

| État initial | Action | Résultat attendu | Résultat observé (test automatique) |
| --- | --- | --- | --- |
| Essai du jour non acheté, 23 h 59 | Démarrer, attendre 00 h 01, terminer, enregistrer (double appui) | Un seul résultat, lié à la tentative ; WOD non acquis ; rouvrir = fiche d'achat | Conforme (test widget) |
| Tentative ouverte puis écran quitté | Revenir après minuit | Aucun score possible, rien d'enregistré | Conforme |
| Écriture refusée au score | Réessayer | Un résultat, une récompense, aucun succès annoncé avant | Conforme |
| Essai du jour choisi | Changer niveau/références, notifier, relancer | Même essai | Conforme |
| Essai terminé | Acheter | Acquis aussitôt, remise d'essai, aucun autre essai ce jour | Conforme |
| Essai choisi le 24/09 | Horloge au 25/09 ; au 23/09 ; 25/10 (heure d'hiver) ; 31/12 → 01/01 | Nouveau choix au jour suivant ; aucun au recul ; jour civil respecté | Conforme |
| Tous les WODs du catalogue tentés | Jour suivant | Pas d'essai ; aucun WOD tenté jouable ; message dans la boutique | Conforme pour le store ; message non testé à l'écran |
| Aucun candidat à ±1 | Ouvrir la boutique | Choix à ±2, puis catalogue | Conforme |
| Sauvegarde sans sélection, WOD joué aujourd'hui | Importer | Ce WOD reste l'essai du jour | Conforme |
| Vitrine de la semaine | Changer niveau, relancer ; acheter un WOD | Stable ; le WOD acheté remplacé par un autre | Conforme |
| Lundi 28/12/2026 | Lundi 04/01/2027 | Nouvelle vitrine | Conforme |
| Semaine complète payée | Supprimer puis refaire les séances | Aucun gain de plus | Conforme |
| Semaine supprimée | Nouvelle semaine complète réelle | +1 | Conforme |
| Palier perdu | Atteint de nouveau | Rien de plus | Conforme |
| Sauvegarde L2 (plus haut 17, journal 3) | Importer deux fois | `level:1 = 3`, `carry:l2 = 14`, identique | Conforme |
| État récent | Importer un état plus ancien | Registre et achats de l'ancien état (remplacement) | Conforme |
| Dépenses 5, gains 3 | Ouvrir la boutique, acheter | « déficit de 2 crédits », achat refusé, WODs gardés | Conforme |
| Données remplies | Supprimer les données, relancer | Registre `level:1 = 3`, sélections refaites | Conforme |

## L3.4 — Limites et suites

- La tentative d'essai vit en mémoire : si Android arrête l'application pendant l'essai, elle est perdue et ne peut plus être terminée après minuit. Chrono et reprise : **L4b**.
- Horloge : avancer la date donne plus tôt l'essai et la vitrine suivants ; la reculer ne les refait pas. Aucun crédit n'en découle. Pas de contre-mesure (application hors ligne).
- Import = remplacement complet, registre et sélections compris ; un fichier ancien peut rendre un autre essai le jour même (en remplaçant toutes les données).
- Le déficit ne se résorbe que par de nouveaux gains ; aucun crédit compensatoire n'a été décidé.
- Aucune vérification sur téléphone ; la mise à jour depuis 2.5.4 avec données réelles reste à constater (protocole de `LIVRAISON_L3.md`).
- Branche temporaire `claude/ci-tools` toujours présente : à supprimer par le propriétaire.

## L2b.0 — Base et résultats repris

| Élément | Valeur | Nature de la preuve |
| --- | --- | --- |
| Base | `streetlift_tracker_v33.zip` de `main`, commit `1013d18` (L2), **1 300 886 octets**, SHA-256 `e252be1bcbce16619712aaf3ebc2388774b2303418f991b85a4772a88f555747`, racine `streetlift_tracker/`, 303 fichiers, version 2.5.2+53 | Vérifié octet pour octet avec la livraison L2 ; archive gardée intacte, travail sur copie |
| Build L2 | Run n° 72, `1013d18`, 21 étapes réussies (tests, refus sans secrets, signature, APK/AAB, contrôles finaux) | Résultat GitHub |
| Tests L2 | 245 réussis, 1 ignoré | Tests automatiques (CI, branche temporaire) |
| Essai téléphone L1b et L2 | **Non rapporté** | — |
| Décisions déjà prises | KT-005 option C ; KT-014 règle d'usage ; publication sur `main` et build à chaque mise à jour ; branche temporaire autorisée pour la CI | Déclarations du propriétaire |
| Résultats L1 confirmés par le propriétaire | Compilation et ouverture, certificat et artefact, mise à jour sans désinstallation, données conservées | Déclaration du propriétaire (inchangée) |

**Contrôle préalable** : la compilation L2 est prouvée (run n° 72) ; la conservation des données après mise à jour **n'a pas encore été vérifiée sur téléphone** pour L2. L2b ne modifie pas le format du document interne (seuls des champs optionnels du *fichier* exporté s'ajoutent). Ordre recommandé : installer L2 (run n° 72) et vérifier les données, puis installer L2b ; ou, au minimum, faire un export avant d'installer L2b (protocole de `LIVRAISON_L2b.md`).

## L2b.1 — Changements

| Élément | Implémenté | Testé automatiquement | Vérifié sur appareil | En attente de décision |
| --- | --- | --- | --- | --- |
| Export par fichier (`ACTION_CREATE_DOCUMENT`) | Oui | Oui (parcours Dart, sélecteur simulé) ; code natif compilé en CI | Non | Non |
| Import par fichier (`ACTION_OPEN_DOCUMENT`) + aperçu + confirmation | Oui | Oui (sélecteur simulé) | Non | Non |
| Sauvegarde proposée avant remplacement | Oui | Oui | Non | Non |
| Conflit si données modifiées pendant l'aperçu | Oui | Oui | Non | Non |
| Presse-papiers conservé, via le même aperçu | Oui | Oui | Non | Non |
| Suppression locale confirmée | Oui | Oui (stockage simulé, relance simulée) | Non | Non |
| Texte « Sauvegarde Android » conforme au comportement | Oui | Présence à l'écran testée | Non | — |
| Politique de sauvegarde Android (KT-016) | Option A déclarée (2.5.4) | Contrôle du manifeste source et des manifestes finaux APK/AAB | Non (restauration à tester) | Non : A décidée |

**Code**
- `android/.../MainActivity.kt` : canal `kalis_track/backup_files`. Création et ouverture par le sélecteur système, **sans permission**. Écriture en mode `wt`, puis relecture et comparaison SHA-256 : réponses `saved`, `unverified`, `cancelled` ou erreur (`denied`, `unavailable`, `io`, `partial`, `interrupted`, `busy`, `noPicker`). Un fichier incomplet est supprimé (`DocumentsContract.deleteDocument`). La lecture est bornée : elle s'arrête au-delà de la limite, sans se fier à la taille annoncée ni à l'extension. Le traitement se fait hors du fil principal, et le contenu n'est jamais journalisé.
- `lib/backup_files.dart` : abstraction `BackupFiles` (remplaçable en test) et nom de fichier `kalis-track-sauvegarde-AAAA-MM-JJ-HHMM.json`.
- `lib/store.dart` :
  - `dataRevision` : ne compte que les vraies modifications. Un simple enregistrement ou un passage en arrière-plan ne la change pas.
  - `previewImport` : aucune mutation ; le document validé est conservé.
  - `applyImport` : transaction L2, avec vérification de révision dans la file (`ImportStatus.conflict`).
  - `importBackup` : repose sur les mêmes fonctions (un seul chemin d'import).
  - `exportForFile` : format 3, plus `exportedAt` et `appVersion` optionnels.
  - `eraseAllData` : passe par la file d'écritures. Il écrit d'abord un état neuf, puis retire toutes les autres clés, et renvoie un statut `success`, `partial` ou `failed` avec la liste des clés restantes (noms seulement).
  - Après un import, ni cérémonie de niveau ni bilan en attente.
- `lib/data_control.dart` : parcours d'export, d'import (fichier et texte) et de suppression ; dialogues `ImportPreviewDialog` et `EraseDataDialog`. Un message remplace le précédent (sans cela, les messages s'empilaient en file : défaut trouvé par les tests).
- `lib/settings_screen.dart` : section Sauvegardes (Exporter, Importer, Copier, Coller, Sauvegarde Android), puis « Zone sensible » séparée avec « Supprimer les données de l'application ».
- `lib/persistence.dart` : `ImportStatus.conflict`, `EraseStatus`, `EraseResult`.

**Format** : le fichier reste au format 3, lisible par les versions précédentes, qui ignorent les champs inconnus. Champs optionnels : `exportedAt`, `appVersion` (L2b), `legacyGrants`, `creditsEarnedMax` (L2). Le document interne est inchangé.

**Traitement des modifications en attente à l'export** : `flush()` est d'abord appelé. Si des modifications ne sont toujours pas acceptées par le stockage, le fichier contient l'état affiché, et le message le dit.

**Inventaire supprimé** : `kalis_state_v3` (remplacé par l'état neuf), `kalis_recovery_v1`, anciennes clés (`pilotage_v1`, `logs_v1`, `settings_v1`, `custom_sessions_v1`, `user_exercises_v1`, `wods_v1`, `wods_user_v2`, `wods_del_v2`, `wods_edit_v2`, `wod_results_v2`, `wods_seed_v`, `level_seen`, `unlocked_wods_v1`, `credits_v`), et **toute autre clé** du fichier de préférences de l'application. En mémoire : caches, achats en cours, bilan en attente, plus haut des crédits. Rappels : replanifiés avec les réglages par défaut (rappels désactivés), donc les rappels de l'application sont annulés. Aucun fichier temporaire n'est créé par l'export ou l'import.

**Reprise** : si l'état neuf n'est pas écrit, rien n'est supprimé (`failed`). S'il est écrit mais que des clés restent, le statut `partial` est annoncé et l'action peut être relancée. Une interruption pendant le retrait des clés laisse au pire des copies internes, jamais d'anciennes données dans le document principal. Les anciennes clés étant retirées, aucune migration ne peut restaurer les données.

## L2b.2 — Politique de sauvegarde Android (KT-016) : option A décidée

**Décision du propriétaire (25/09/2026) : option A**, sauvegarde Android par défaut, rendue explicite. Appliqué en 2.5.4 :
- `android:allowBackup="true"` déclaré dans le manifeste, avec un commentaire ; aucune règle `dataExtractionRules`, `fullBackupContent` ni `backupAgent` ;
- contrôle ajouté à `tools/verify_project.py` (manifeste source) ;
- contrôle ajouté à `tools/verify_android_artifacts.py` sur les manifestes **finaux** de l'APK et de l'AAB (fusion des dépendances comprise). Le build échoue si la politique change ;
- 4 cas ajoutés aux tests Python : attribut absent, `false`, règles ajoutées.

Le comportement ne change pas : le défaut Android s'appliquait déjà. Le texte « Sauvegarde Android » des Réglages décrit ce comportement. Reste ouvert : le test de restauration réelle sur appareil de test (`bmgr`), protocole 2 de `LIVRAISON_L2b.md`.

Analyse ayant servi à la décision :

**Constat** : manifeste principal et **manifeste fusionné** (build debug en CI, `processDebugMainManifest`) sans `allowBackup`, `dataExtractionRules`, `fullBackupContent` ni `backupAgent`. Aucune dépendance n'en ajoute. `targetSdk` est 36, `minSdk` 21. Les données de l'application tiennent dans un seul fichier SharedPreferences, copies de secours comprises.

Sources consultées le 25/09/2026 :
- [\<application\>, mise à jour du 21/08/2026](https://developer.android.com/guide/topics/manifest/application-element) : `allowBackup` vaut `true` par défaut ; `false` désactive la sauvegarde cloud, mais « sur certains appareils, on ne peut pas désactiver la migration d'appareil à appareil » pour les apps ciblant Android 12+.
- [Auto Backup, mise à jour du 26/02/2026](https://developer.android.com/identity/data/autobackup) : les préférences sont incluses par défaut ; la sauvegarde a lieu au plus toutes les 24 h, appareil inactif, en Wi-Fi, si l'utilisateur l'a activée ; 25 Mo par application ; chiffrement côté client sur Android 9+ si un verrouillage d'écran existe ; restauration à l'installation ; `dataExtractionRules` sépare `cloud-backup` et `device-transfer` (section absente : transfert entièrement autorisé).
- [Documents et autres fichiers, mise à jour du 16/09/2026](https://developer.android.com/training/data-storage/shared/documents-files) : `ACTION_CREATE_DOCUMENT` et `ACTION_OPEN_DOCUMENT` ne demandent aucune permission ; pas d'écrasement (numéro ajouté).

**Comportement actuel déduit** (non observé sur appareil) : si l'utilisateur a activé la sauvegarde Google, les données, copies de secours comprises, peuvent être copiées dans le cloud et restaurées à la réinstallation ; le transfert vers un nouveau téléphone les inclut.

| Option | Perte ou vol du téléphone | Nouveau téléphone | Confidentialité | Ce que l'application contrôle |
| --- | --- | --- | --- | --- |
| **A. Défaut actuel, rendu explicite** | Restauration possible si la sauvegarde Google est active | Transfert inclus | Copie chez Google, chiffrée côté client seulement si verrouillage d'écran (Android 9+) ; une copie peut survivre quelques jours à une suppression locale | Rien ; texte d'information seulement |
| **B. `allowBackup="false"`** | Aucune restauration : seul l'export manuel protège | Transfert encore possible sur certains appareils (Android 12+) | Aucune copie cloud | Désactivation cloud seulement |
| **C. Règles explicites** : cloud seulement si chiffrement côté client (`requireFlags="clientSideEncryption"`), transfert d'appareil inclus ; `dataExtractionRules` (Android 12+) et `fullBackupContent` (≤ 11) | Restauration si la sauvegarde Google est active **et** l'écran verrouillé | Transfert inclus | Pas de copie cloud non chiffrée | Filtrage déclaratif ; ni déclenchement, ni vérification, ni effacement |

Aucune option ne permet à l'application de déclencher, vérifier ou effacer une copie cloud. Aucun interrupteur n'est donc ajouté. Recommandation technique : **C**, à valider, puis à tester par restauration sur appareil de test (`bmgr`, protocole de `LIVRAISON_L2b.md`).

## L2b.3 — Tests

| Niveau | Résultat |
| --- | --- |
| Nouveaux tests `l2b_data_control_test.dart` | 33 : 13 sur le store (instances isolées), 20 sur les écrans (320 px ; texte 100, 130, 200 % ; thèmes clair et sombre ; bouton retour) |
| Test adapté | `ui_refactor_test` : les actions presse-papiers s'appellent désormais « Copier / Coller la sauvegarde » ; assertions conservées |
| CI branche temporaire (sans secret) | Formatage : 79 fichiers, 0 changement ; `flutter analyze` sans problème ; tests ciblés 84/84 ; **suite complète 278 réussis, 1 ignoré** ; **build Android debug réussi** (code natif compilé), manifeste fusionné extrait |
| Build signé 2.5.3 | Run n° 73, commit `74ff8e3`, 21 étapes réussies (résultat GitHub) |
| 2.5.4 (option A) | Python 33/33 en local, dont 4 nouveaux cas KT-016 ; résultat du build dans le rapport de livraison |
| Python | 33/33 en local |
| Sélecteur de fichiers | **Simulé** en test ; accès natif **non exécuté** sur appareil |
| Redémarrage | Relance simulée (nouvelle instance) ; redémarrage réel non exécuté |
| Restauration Android (cloud, transfert) | **Non exécutée** |

## L2b.4 — Limites et suites

- Le sélecteur de fichiers, l'écriture relue et la lecture bornée sont compilés mais **pas encore exécutés sur un appareil** : les tests simulent le sélecteur.
- Si Android détruit l'application pendant que le sélecteur est ouvert, l'opération est perdue et doit être refaite (réponse `interrupted` si l'activité se ferme).
- Une relecture impossible donne `unverified`, jamais un succès. Certains fournisseurs cloud écrivent en différé : le fichier relu localement ne prouve pas l'envoi au cloud.
- L'export n'est pas chiffré (JSON lisible) ; aucun chiffrement artisanal n'a été ajouté.
- L'import reste un remplacement complet (contrat L2) : pas de fusion, pas de nouvelle règle de crédits.
- La suppression ne touche ni les fichiers exportés, ni les copies cloud ou de transfert Android, ni les autorisations système. Aucun effacement physique irrécupérable n'est promis.
- Politique de sauvegarde Android : option A appliquée (L2b.2) ; restauration réelle non testée.
- Publication : ZIP sur `main` et build signé à chaque mise à jour, sur instruction du propriétaire. Le résultat du run figure dans `LIVRAISON_L2b.md`, écrit après la publication.

## L2.0 — Base retenue

| Élément | Valeur |
| --- | --- |
| Source | `streetlift_tracker_v33.zip` de `main`, commit `f7f8518` (L1b-R2), **1 277 631 octets**, SHA-256 `53474eabc64cffaeddce571808774cfc5824fb4f4bf206af74447b7e5ebcb0ed`, racine `streetlift_tracker/`, 299 fichiers, version 2.5.1+52 |
| Provenance | Même archive que celle compilée par le run n° 71 (succès, 21 étapes). `SUIVI_PROJET.md` remplacé par la version livrée séparément après L1b (plus récente que la copie interne, écart documenté dans LIVRAISON_L1b) |
| Travail | Copie extraite ; archive source gardée en lecture seule, intacte |
| État L1b | Compilé et contrôlé en CI (run n° 71). **Essai téléphone L1b non encore rapporté** : non compté comme validé. Il est repris dans le protocole L2 |
| Résultats L1 déjà confirmés par le propriétaire | Compilation et ouverture, contrôle du certificat et artefact GitHub, installation en mise à jour sans désinstallation, historique/séances/crédits/WOD acquis/réglages conservés. Conservés tels quels, non transformés en preuve L1b |

## L2.1 — Lecture ciblée (constats vérifiés dans le code L1b-R2)

- **KT-002 confirmé** : `unlockWod` modifiait `unlockedWods`, lançait une écriture non attendue, renvoyait `true` ; `wod_preview.dart` jouait révélation et message aussitôt.
- **KT-013 confirmé, plus grave que l'audit** : chaque sauvegarde ordinaire encodait l'état **au moment de la demande** et s'enchaînait sur `_pendingWrite` ; `importAll` attendait cette file sans s'y inscrire, puis écrivait. Une sauvegarde demandée pendant cet import (état antérieur encodé) pouvait être écrite **après** l'import : mémoire importée, disque ancien. Pas de copie de l'état remplacé. L'import annulait aussi le minuteur de sauvegarde différée.
- **Défaut de test révélé** : la file s'enchaînait sur un `Future` créé dans la zone du démarrage ; dans une zone de test à horloge simulée, la suite n'était jamais exécutée (cause réelle du blocage de test observé en L1b-R2).
- **KT-014 confirmé** : branche d'anciennes préférences (`credits_v < 2`) : `unlockedWods.removeWhere(v == 0)`, suppression définitive. À l'inverse, un import format 1/2 contenant des coûts 0 les gardait comme accès gratuits : deux règles contradictoires.
- **KT-015 confirmé** : `_unpack` décompressait sans plafond ; aucune limite globale de taille, de valeurs ou de collections avant analyse.
- **KT-005 inchangé** : crédits = barème(niveau) + bonus dérivés − achats, plancher 0.

## L2.2 — Changements

| Ticket | Code | Comportement retenu |
| --- | --- | --- |
| KT-002 | `store.dart` : `purchaseWod(w, acceptedCost)` → `PurchaseResult` (`success`, `alreadyOwned`, `pending`, `insufficientCredits`, `priceChanged`, `failed`), `purchasePending`, réservation dans `creditsSpent`, `unlocked()` faux tant que l'écriture n'est pas acceptée. `unlockWod` synchrone supprimé. `wod_preview.dart` : bouton « Achat en cours… », message par état, révélation seulement après succès, message affiché même si la fiche est fermée. | Prix payé = offre affichée, sinon `priceChanged` sans débit. Double appui : `pending`, un seul débit. Achats simultanés : le solde réservé empêche toute dépense excessive. Échec : seul ce droit est retiré de la mémoire (s'il vaut encore ce prix) ; les modifications faites pendant l'attente sont gardées ; le cache SharedPreferences revient au dernier document accepté. Un droit déjà acquis n'est jamais retiré. |
| KT-013 | `store.dart` : file explicite `_serialize` (démarrée par microtâche dans la zone de l'appelant) ; sauvegardes regroupées et encodées **à l'exécution** ; `_writeRaw` rétablit le cache en cas de refus ; compteurs `_changeSeq` / `_acceptedSeq`, `hasUnsavedChanges`, `retrySave()` ; `importBackup` dans la file, copie de récupération préalable (`kalis_recovery_v1`, 3 dernières), application en mémoire seulement après écriture acceptée ; liste de copies illisible → import suspendu, rien écrasé. `main.dart` : alerte d'erreur avec **Réessayer**. `debugWriteHook` (tests uniquement) pour injecter refus et délais. | Distinction explicite : modification en mémoire (`_changeSeq`), écriture acceptée par l'API (`_acceptedSeq`), conservation après relance (vérifiée seulement en relisant le stockage, dans les tests par nouvelle instance ; sur téléphone par le protocole). Aucune garantie de durabilité à l'arrêt brutal n'est déclarée : SharedPreferences 2.5.3 ne la promet pas. Le stockage n'est pas remplacé. |
| KT-014 | `store.dart` : `legacyGrants` (id → origine), exporté/importé (clé optionnelle `legacyGrants`, ignorée par les anciennes versions). Migration `credits_v < 2` et import formats 1-2 : un coût 0 d'un WOD du catalogue **ayant au moins un résultat** reste acquis à coût 0 ; sans résultat, il est archivé dans `legacyGrants` (`credits_v1` / `import_format_N`), sans accès. Format 3 : coûts 0 gardés comme droits établis. | Arbitrage du propriétaire (25/09/2026 : « le plus logique selon toi ») : droit établi par l'usage. Aucune donnée détruite ; aucun accès gratuit au catalogue entier ; aucun débit (coût 0). |
| KT-015 | `persistence.dart` : `ImportLimits` (valeurs standard ci-dessous), `boundedUnpack` (base64 puis gzip par morceaux de 16 Kio vers un tampon qui refuse de dépasser la limite **pendant** le flux), `boundedJsonDecode` (compte valeurs et longueur des textes pendant l'analyse) ; `_checkCollections` avant conversion. `settings_screen.dart` : messages distincts (invalide / trop volumineuse / écriture refusée). | Limites : texte 8 Mio car. ; JSON décompressé 32 Mio ; 2 000 000 valeurs ; texte isolé 100 000 car. ; 20 000 séances ; 500 000 séries ; 100 000 résultats WOD ; 20 000 entrées par autre collection. Mesure représentative (40 semaines entièrement saisies, 60 séances perso dont 20 répétées, 300 résultats, 30 achats) : **1 037 555 octets de JSON, 49 183 caractères compactée, 71 374 valeurs** : marge ≥ 30× sur chaque limite. Le démarrage relit l'état produit par l'application sans ces limites (une grosse histoire légitime ne bloque jamais l'ouverture). |
| KT-005 | `store.dart` : `creditsFromJournal` (calcul actuel), `_earnedMax` (plus haut enregistré, mis à jour à chaque écriture acceptée), `creditsEarned = max(journal, plus haut)`, clé de sauvegarde optionnelle `creditsEarnedMax` (entier 0-1 000 000, sinon import refusé). | **Option C retenue par le propriétaire (25/09/2026)** : crédits gagnés jamais repris, XP et niveau recalculés depuis le journal (le niveau peut redescendre). Refaire une performance supprimée ne redonne rien sous le plus haut. Import = remplacement : le plus haut de la sauvegarde remplace le courant (absent → calcul du journal). Migration : absent au premier lancement → calcul actuel, aucun crédit créé ni retiré. |

## L2.3 — Tests

| Niveau | Résultat |
| --- | --- |
| État initial (L1b-R2, run n° 71 et suite complète) | 202 réussis, 1 ignoré |
| Nouveaux tests | `l2_persistence_test.dart` (41 : 8 achats, 9 écritures/imports, 10 droits historiques, 8 imports bornés, 6 contrat KT-005 option C), `l2_purchase_ui_test.dart` (2 widget à 320 px), jeux `l2_fixtures.dart` (neuf, rempli, perso répétées, achats normaux/remisés, coût 0, formats 1/2/3, dégradés, bombe de compression contrôlée) |
| Tests existants adaptés | `store_test`, `wod_store_test`, `wod_acquisition_test` : appel `unlockWod` → `await purchaseWod`, assertions conservées (un seul débit, prix remisé figé, refus faute de crédits). `reward_flow_test` : son `setUp` vide le journal entre deux cas ; il remet aussi à zéro le plus haut des crédits (`debugResetEarnedCredits`, tests uniquement), sans quoi l'option C garde les crédits du cas précédent. Aucune assertion retirée. |
| CI branche temporaire `claude/ci-tools` (sans secret, sans build), arbre final | Formatage : 76 fichiers, 0 changement ; `flutter analyze` : No issues found ; tests ciblés 84/84 ; **suite complète 245 réussis, 1 ignoré**, sortie 0 |
| Python | 33/33 en local (outils inchangés) |
| Erreurs simulées | Refus d'écriture, cache modifié puis refus, écritures suspendues (Completer) : oui, via `debugWriteHook` |
| Stockage réel / redémarrage réel / arrêt brutal / appareil | **Non exécutés.** « Relance » des tests = nouvelle instance relisant le stockage simulé |
| Build APK/AAB signé L2 | **Non exécuté** : `main` non modifié conformément au lot |

## L2.4 — KT-005 : contrat de conservation des crédits (option C retenue et appliquée)

Décisions déjà prises dans cette conversation : correction d'une séance = XP retiré puis rendu à la revalidation ; suppression = XP et bonus retirés, droits WOD gardés ; `_lastLevel` ne redescend pas. **Aucune décision n'a été prise sur les crédits.**

Barème actuel : niveau atteint à `25 × (n − 1) × (n + 4)` XP (N2 = 150, N3 = 350, N4 = 600, N5 = 900) ; crédits de niveau `1 + 2n + 3⌊n/5⌋` (N4 = 9, N5 = 14) ; bonus chapitre +3, boss +5, semaine complète +1.

**Exemple** : 900 XP (N5 → 14) + 3 semaines complètes (+3) = 17 gagnés ; 15 dépensés ; solde 2. Suppression d'une séance du programme (−100 XP de base, la semaine redevient incomplète) → 800 XP (N4 → 9) + 2 = 11 gagnés.

| Option | Solde affiché après suppression | Gain répété (supprimer puis refaire) | Import | Migration |
| --- | --- | --- | --- | --- |
| **A. Journal seul (actuel, rendu explicite)** | 11 − 15 = **−4**, affiché « dette de 4 » au lieu de 0 ; les 5 crédits du prochain niveau servent d'abord à la combler | Impossible : tout est recalculé | Remplace tout, cohérent | Aucune ; seul l'affichage change |
| **B. Plus haut atteint (« jamais repris »)** : `gagnés = max(calcul actuel, plus haut enregistré)` | 17 − 15 = **2**, inchangé | Impossible : refaire la séance ramène le calcul à 17, sous le plafond | Le plus haut est exporté ; un import le remplace comme le reste | Au premier lancement, plus haut = calcul actuel (aucun crédit créé, aucun retiré) ; nouvelle clé optionnelle |
| **C. Hybride** : B pour les crédits, XP/niveau recalculés comme aujourd'hui | 2 ; niveau affiché N4 | Impossible | Comme B | Comme B |

Décisions : **option C** (propriétaire) ; le niveau redescend ; les droits anciens rendus par l'usage comptent à 0 (aucun débit). Tests : suppression (XP et niveau baissent, crédits et solde inchangés, conservés après relance), refaire une performance supprimée (aucun gain), correction (solde inchangé), migration sans plus haut enregistré, import d'un plus haut supérieur puis inférieur, valeurs invalides refusées. Limite connue : la cérémonie de passage d'un niveau jamais atteint annonce le barème du niveau (« +N crédits ») ; si le plus haut enregistré dépasse déjà le journal, le solde peut augmenter de moins que N.

## L2.5 — Limites et suites

- Import = remplacement complet (droits compris), comme annoncé dans le dialogue ; l'état remplacé est gardé en copie. **Restauration d'une copie : pas d'écran**, prévue en L2b avec l'export/import par fichier.
- Les copies de récupération vivent dans le même stockage SharedPreferences : elles ne protègent pas contre la perte de ce stockage.
- Démarrage avec un document principal illisible : écran d'erreur, données laissées intactes (comportement inchangé) ; reprise depuis une copie en L2b.
- Achat interrompu par la fermeture du processus : seul ce qui a été accepté par l'API peut subsister ; aucun essai sur appareil.
- Arrêt brutal et durabilité disque : non démontrés.

## L1b.0 — État de clôture (remplace les statuts « en attente CI » plus bas)

| Run | Commit | Contenu | Résultat |
| --- | --- | --- | --- |
| n° 68 | `bdc7aef` | L1b initial (2.5.0+51) | **Échec** étape 7 : `sdkmanager: command not found` (code 127) |
| n° 69 | `e0d94bc` | L1b-R1 (2.5.0+51) : chemin SDK + filtres ABI | **Succès**, 21 étapes, 14:36 → 14:48 UTC |
| n° 70 | `adad2b0` | L1b-R2 (2.5.1+52) : corriger/supprimer une séance | **Échec** étape 9 : formatage (1 ligne de test) |
| n° 71 | `f7f8518` | L1b-R2 formaté, nettoyage de test corrigé | **Succès**, 21 étapes, 15:59 → 16:11 UTC |

**Run n° 71, preuves CI (statut des étapes lu via l’API GitHub) :** ZIP et copie du workflow identiques ; `verify_project.py` ; composants Android 36 / build-tools 36.0.0 / NDK r28c installés ; `pub get --enforce-lockfile` ; formatage sans changement ; `flutter analyze` sans problème ; tests Python et Flutter réussis ; icônes ; **5 vrais refus Gradle release sans secrets valides** ; restauration et contrôle obligatoires de la clé existante ; APK et AAB release compilés avec le même numéro ; `verify_android_artifacts.py` réussi (certificat APK et AAB = référence, manifestes finaux identité/versions/min 21/cible 36/non débogable, permissions APK = AAB, `bundletool validate`, configuration AAB `PAGE_ALIGNMENT_16K`, `zipalign -P 16`, ELF 64 bits alignés 16 Ko avec contrôle RELRO, mêmes bibliothèques natives APK/AAB, ABI exactement armeabi-v7a/arm64-v8a/x86_64) ; artefacts publiés.

| Artefact run n° 71 | Taille de l’archive GitHub | Empreinte de l’archive GitHub (SHA-256) | Expiration |
| --- | --- | --- | --- |
| `kalis-track-apk` | 26 348 376 octets | `4f7d752e7d2e0f1aaa8e21ba8e7ec24e68ad0cc1c4af8f5737ca7465f851fbc4` | 25/10/2026 |
| `kalis-track-aab` | 27 018 366 octets | `eaefa5f753468dcdcb978addcfd3efefc89d1b6a43b3a07f722b00719fc91291` | 25/10/2026 |
| `kalis-track-validation` | 23 502 octets | `1679fc9fd5b648ae06edbe0137731731e8acdc4fe1a9333bdd80f66c630c389f` | 25/10/2026 |

Ces empreintes sont celles des archives téléchargeables, pas de l’APK/AAB qu’elles contiennent : les fichiers `kalis-track.apk.sha256`, `kalis-track.aab.sha256`, `build-number.txt` et `android-artifacts.json` sont dans les archives. Le stockage des journaux et artefacts GitHub n’est pas joignable depuis l’environnement de l’assistant : leur contenu n’a pas été relu ici.

Suite Flutter complète exécutée séparément sur le même code (branche temporaire `claude/ci-tools`, sans secrets) : **202 tests réussis, 1 ignoré** (capture optionnelle), sortie 0 ; analyse `No issues found!`. La branche temporaire n’a pas pu être supprimée depuis l’environnement de l’assistant (refus 403) : suppression à faire par le propriétaire, elle ne contient ni secret ni workflow de build.

**Clos par la CI :** KT-010 (cible 36 vérifiée dans le manifeste final), KT-011 (pipeline APK + AAB, contrôles et refus sans secrets démontrés), KT-019 (alignements 16 Ko vérifiés statiquement sur les binaires finaux), gates de formatage/analyse/tests. KT-012 : tests mobiles réussis en CI.

**Restent ouverts :** essai L1b sur téléphone (mise à jour sans désinstallation, données conservées, nouvelle fonction, texte agrandi) ; exécution sur appareil ou émulateur à pages 16 Ko ; autres ABI, Android minimum, grand écran ; KT-005 (solde de crédits qui peut baisser) ; préparation Google Play hors lot ; suppression de la branche temporaire.

## L1b-R2 — Corriger ou supprimer une séance terminée (demande du propriétaire)

Besoin : une fin de séance validée par erreur rendait les valeurs non modifiables ; l’historique est en lecture seule depuis R2, et l’accueil ouvre l’historique pour une journée faite.

| Élément | Changement |
| --- | --- |
| `lib/store.dart` | `correctionPlan(key)` (journée d’entraînement du programme ou séance perso existante ; null pour archive `@`, repos, séance perso supprimée) ; `reopenSession(key)` (terminée → en cours, saisies et `finishedAt` conservés) ; `deleteLog(key)` / `restoreLog(key, log)` (annulation sans écraser une séance reprise). `markSessionDone(done: true)` réutilise `finishedAt` s’il existe : la date d’origine est conservée après correction. « Repasser en à faire » efface toujours la date. |
| `lib/session_history.dart` | Menu ⋮ quand l’entrée existe et est terminée : « Corriger les saisies » (désactivé si non rouvrable) et « Supprimer de l’historique ». Carte « Validée par erreur ? » sur la page Bilan. Confirmations explicites ; suppression suivie d’un message « Annuler ». Consulter reste sans écriture. |
| `test/history_correction_test.dart` | 4 tests store + 5 tests widget (320 px, texte 130 %) : réouverture, date conservée, revalidation, annulation, suppression/restauration, archive, entrée absente. **9/9 réussis en CI**, avec les 4 tests `history_readonly_test.dart` inchangés. |
| `README.md`, `pubspec.yaml`, `lib/settings_screen.dart` | Section 2.5.1 ; version 2.5.1+52 et `kAppVersion`. |

Effets sur la progression : pendant une correction, l’XP de séance est retiré (les séries validées restent comptées) ; il revient à la revalidation, avec un nouveau bilan. Une suppression retire l’XP et les bonus dérivés ; les WODs débloqués restent acquis (`unlockedWods` inchangé) ; le solde affiché peut baisser si le niveau baisse (comportement préexistant de « Repasser en à faire », KT-005 ouvert). `_lastLevel` ne redescend pas : pas de seconde cérémonie de niveau après correction.

Incidents de mise au point : run n° 70 refusé par le formatage d’une assertion de test (corrigé à l’identique du formateur Dart 3.7.2). Un test widget bloquait : `tester.runAsync(store.flush)` attendait une écriture créée dans la zone de temps simulée ; nettoyage limité au démontage de l’arbre. Aucun code de l’application modifié pour ces deux corrections.

## L1b-R1 — Correctif après le premier run CI L1b

Run n° 68, commit `bdc7aef5`, runner `ubuntu-24.04` image 20260920.314.1. Échec à « Installer les composants Android ciblés » : `sdkmanager: command not found`, code 127. Aucune étape Flutter, Gradle, signature ou artefact atteinte ; secrets non lus.

| Problème | Cause | Correction | Preuve |
| --- | --- | --- | --- |
| **R1-A** — `sdkmanager` introuvable | SDK préinstallé dans `$ANDROID_HOME`, mais `cmdline-tools/latest/bin` hors du PATH du runner | Chemin résolu depuis `ANDROID_HOME`/`ANDROID_SDK_ROOT`, outils contrôlés, dossier ajouté à `GITHUB_PATH`, licences acceptées, installation journalisée (`sdkmanager-install.log`), présence d’`apksigner`, `apksigner.jar`, `zipalign`, plateforme 36 et NDK r28c vérifiée | Étape 7 réussie aux runs n° 69 et 71 |
| **R1-B** — ABI x86 hors liste (anticipé) | `shared_preferences_android` 2.4.13 → `androidx.datastore` 1.1.7 embarque `libdatastore_shared_counter.so` en x86 ; Flutter 3.29.3 ne filtre pas les ABI (filtre par défaut depuis Flutter 3.35) ; le contrôleur n’accepte que 3 ABI | `abiFilters` release `armeabi-v7a`, `arm64-v8a`, `x86_64` dans `android/app/build.gradle.kts` ; contrôleur inchangé | Étape 17 réussie aux runs n° 69 et 71 (ABI, ELF 16 Ko et RELRO de toutes les bibliothèques, datastore compris) |

## L1b.1 — Source réellement utilisée

Archive unique : `streetlift_tracker_v33.zip`, livraison L1-R2, **1 238 962 octets**, SHA-256 recalculé :
`9dfd6221954a1acd673804a498f703ed245f14fd4f8540af9f29e769d584e698`.
Identique à la référence demandée ; racine `streetlift_tracker/`, 278 fichiers, version `2.5.0+51`. CRC vérifiés à l’extraction. Le workflow séparé R2 et sa copie interne sont identiques. Aucun retour vers R1 ou A0, aucune source détruite, aucun dépôt distant modifié.

Documents pris en compte : le suivi embarqué, `LIVRAISON_L1.md` R2, le cahier des charges transmis et le workflow R2 utilisé comme référence. La déclaration du propriétaire relie R2 au dernier build réussi ; le journal complet de ce run réussi et son APK ne sont pas disponibles dans cette passe. Les deux journaux visibles sont les runs antérieurs ayant échoué au contrôle final du certificat.

La copie de travail temporaire a dû être reconstruite après nettoyage de l’environnement. L’archive R2 a de nouveau été matérialisée et son empreinte vérifiée ; les contrôles consignés pour cette livraison ont été relancés sur la copie reconstruite. L’empreinte du ZIP L1b figure dans le rapport séparé `LIVRAISON_L1b.md`, pour éviter une référence circulaire.

## L1b.2 — Résultats L1 déclarés et preuves disponibles

| Résultat | Déclaration du propriétaire, enregistrée sans nouvelle demande | Preuve dans les journaux joints |
| --- | --- | --- |
| Compilation du dernier build | Réussie | Les deux anciens runs prouvent déjà une compilation APK réussie ; le run réussi R2 n’est pas joint |
| Contrôle du certificat et artefact GitHub | Réussis | Les anciens runs échouent au contrôle final et ne publient pas ; ils ne prouvent pas ce succès ultérieur |
| Installation comme mise à jour, sans désinstallation | Oui | Pas de journal appareil ; déclaration du propriétaire |
| Ouverture sur téléphone | Réussie | Déclaration du propriétaire |
| Historique, séances, crédits, WOD acquis et réglages après réouverture | Préservés | Déclaration du propriétaire ; pas de comparaison indépendante des données |

La continuité de mise à jour et la conservation des données **L1 sont confirmées par le propriétaire sur son téléphone**. Cette confirmation ne vaut pas validation de tous les parcours, de toute la sécurité, ni de la publication Google Play. Elle ne vaut pas essai du nouvel APK L1b.

La sauvegarde privée de la clé et des accès, la distribution par APK direct, l’absence de Play App Signing et le caractère resté privé du ZIP/dépôt ont déjà été déclarés par le propriétaire. Les deux secrets désormais fonctionnels sont conservés. Aucun secret ni aucune clé n’ont été remplacés ou générés.

**Restent ouverts pour L1 :** preuve effective du refus d’un build release sans secrets valides (nouvelle CI préparée), vérification indépendante de l’exposition passée si elle devient nécessaire. Le caractère privé est une déclaration, pas un audit de l’historique de partage ou du dépôt. Le nettoyage d’un ZIP ne résout pas une exposition antérieure éventuelle ; toute rotation serait une décision distincte. Aucune exposition confirmée nouvelle n’est déduite de ces travaux.

## L1b.3 — Problèmes ciblés et changements

| Identifiant / gravité / catégorie | Fichiers et preuve | Traitement et état restant |
| --- | --- | --- |
| **KT-010 / P1 / écart confirmé de configuration** | `android/app/build.gradle.kts` R2 cible 35 ; exigence mobile API 36 revérifiée le 25/09/2026 dans [S1] du guide | targetSdk 36, compileSdk 36 conservé. Vérification du manifeste final prévue ; build et comportements Android 16 encore à valider |
| **KT-011 / P1 / contrôles incomplets confirmés** | Workflow R2 : APK seul, pas de gate formatage, ni AAB/manifeste final/16 Ko, ni preuve Gradle négative | Pipeline complété, contrôleurs et tests ajoutés. APK/AAB de même base et numéro prévus, signature R2 conservée. Production et contrôle des vrais artefacts : en attente CI |
| **KT-012 / P2 / faiblesse de test confirmée** | `reward_flow_test.dart` utilisait 390×1600 et `wod_store_test.dart` 390×1800 pour accéder aux contenus | Fenêtres 390×844 et 320×720 ; gestes de défilement, actions atteignables, scénarios de texte 130/200 %. Assertions d’origine conservées, aucun test désactivé pour obtenir du vert |
| **KT-012 / P2 / défaut local confirmé par test agrandi** | `lib/wod_store.dart`, `WodHero` : débordements horizontal et vertical à 320 px / 200 % lors des essais ciblés | Badge flexible et hauteur de la carte adaptée au texte. Apparence à échelle normale préservée ; correction locale, sans refonte. Couverture par tests catalogue/fiches et achats fictifs |
| **KT-019 / P1 / risques de compatibilité à vérifier** | NDK 26.3 dans les logs, plugins demandant 27 ; natifs finaux et minimum Android effectif non inspectés sur un artefact disponible | r28c épinglé pour alignement 16 Ko. Vérifications statiques des moteurs Flutter 64 bits réussies ; natifs finaux/ZIP/AAB et exécution sur système 16 Ko encore ouverts. Écart de matrice Kotlin/AGP documenté |

Le guide `docs/VALIDATION_ANDROID_L1b.md` décrit les versions, sources officielles, justifications et étapes GitHub/téléphone. Les modifications sont séparables : cible Android, NDK, contrôle de pipeline, tests mobiles et correction WodHero ; les autres changements Dart sont du formatage et cinq ajouts d’accolades exigés par l’analyse après formatage.

Aucun changement de barème, formule, calendrier, achat, données ou modèle de sauvegarde. `pubspec.yaml`, `pubspec.lock`, assets, wrapper Gradle, empreinte publique du certificat, `tools/signing.py` et `tools/VerifyApkCertificate.java` restent identiques à R2. L’identité de signature attendue reste inchangée.

## L1b.4 — Contrôles réels de cette livraison

Les résultats locaux sont consignés dans `validation/L1b/`. Ils ne constituent pas une compilation Android.

| Contrôle | Résultat réel local |
| --- | --- |
| Base R2 | Taille, SHA-256, CRC et racine conformes |
| Flutter / Dart | SDK officiel 3.29.3 / 3.7.2 téléchargé ; SHA-256 de l’archive vérifié |
| Dépendances | Archives vérifiées contre les lockfiles ; résolution hors ligne avec `--enforce-lockfile` |
| Formatage | 71 fichiers vérifiés, 0 changement demandé |
| Analyse | `No issues found!`, code de sortie 0 |
| Tests Python | 33 réussis, dont refus réel par Java d’une fixture AAB non signée ; les tests de refus Gradle sont simulés ici |
| Tests Flutter | **193 réussis, 1 ignoré** : capture visuelle déjà optionnelle dans R2 ; aucun nouvel ignore |
| Assets | 40 semaines, 280 jours, 1 954 exercices du programme, 505 exercices de la base |
| Workflow | actionlint 1.7.7 réussi (intégration shellcheck désactivée, pas de preuve d’exécution Actions) |
| Moteurs Flutter release précompilés | ARM64 et x86_64 : LOAD à 65536, règles RELRO acceptées ; rapport statique fourni |
| bundletool | Téléchargement 1.18.2 et SHA-256 vérifiés, commande version exécutée ; aucun AAB Kalis local à valider |
| SDK Android / build APK et AAB | SDK absent ; aucun APK/AAB Kalis L1b compilé localement |
| Refus Gradle sans secrets | Non exécuté localement ; cinq cas réels exigés dans le workflow livré |
| Téléphone / système 16 Ko | Aucun essai L1b réalisé ; déclaration L1 conservée séparément |

La première tentative Flutter après reconstruction a été bloquée par le contrôle automatique de sécurité : détection du runner via métadonnées de machine. Après lecture du code officiel du SDK, le mode CI désactivant cette requête a été utilisé, avec télémétrie supprimée. Aucun changement de code applicatif n’a servi à contourner ce blocage.

L’exclusion des secrets du ZIP est vérifiée par `tools/package_release.py --check` et les tests de régression du packaging. Ce contrôle de motifs/conteneurs et de fichiers interdits réduit les risques ; il n’est pas une preuve universelle d’absence de tout secret arbitraire ou obfusqué. Les protections L1 et la copie du workflow sont conservées.

## L1b.5 — Validations encore nécessaires et arrêt du lot

- Nouveau run GitHub : formatage, analyse, tests, **cinq refus Gradle**, builds APK/AAB, signatures réelles, identité, versionnement, manifestes finaux, ABI, alignements ELF/ZIP et configuration AAB, empreintes finales.
- Comparaison du manifeste final : notamment minimum Android des plugins et attributs de sauvegarde/exported. Ne pas modifier la politique de sauvegarde dans L1b pour faire passer une exigence nouvelle.
- Téléphone : mise à jour L1b sans désinstallation, réouverture et conservation des données/droits ; essais de défilement, texte agrandi, bilan et navigation Android 16.
- Compatibilité : exécution sur un véritable système 16 Ko, appareils Android minimum annoncés, grands écrans et autres ABI non couverts par le téléphone du propriétaire.
- Exposition passée : conserver les confirmations du propriétaire sans les transformer en audit indépendant. Aucun remplacement de clé implicite.
- Google Play : l’AAB ne prouve pas l’acceptation du store, Play App Signing ou la conformité de publication ; ces décisions restent pour le lot dédié.

**L1b est livré pour exécution et validation CI/appareil. Il n’est pas présenté comme entièrement validé. L2 et la refonte visuelle ne sont pas lancés.**

---

# Historique conservé — L1-R2 puis audit initial

Les statuts et demandes de confirmation dans les sections historiques ci-dessous décrivent leur date de rédaction. L’état courant ci-dessus les remplace ; ne pas redemander les informations déjà confirmées ni refaire la configuration des secrets.

# Suivi historique L1-R2

**Passe actuelle : L1-R2 — contrôle direct du certificat APK, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative : 2.5.0+51, inchangée**  
**Statut : compilation Android R1 réussie selon le second journal fourni ; publication bloquée par le lecteur de sortie apksigner. Ce lecteur est supprimé dans R2. Contrôle direct testé sur des APK publics déjà signés, exécution sur l’APK Kalis encore requise. L1 non validé par le propriétaire.**

## R2.1 — Références préservées et second journal CI

La source A0 originale a été revérifiée sans modification :
`streetlift_tracker_v33.zip`, **1 190 723 octets**, SHA-256
`50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f`.

La copie de travail R2 est extraite de la livraison R1 de cette conversation :
**1 234 126 octets**, SHA-256
`a6c0581aa14112f12b56e27ce8d2d202ccf40256732141fc1572609e606ef6cc`,
racine `streetlift_tracker/`, 277 fichiers. Taille, empreinte et CRC vérifiés.
Les archives A0, L1 et R1 et leurs copies source restent intactes. Aucun dépôt
distant modifié. La taille et le SHA-256 du nouveau ZIP sont donnés dans le
rapport séparé `LIVRAISON_L1.md`, afin d’éviter une empreinte autoréférente.

Journal transmis par le propriétaire : dépôt `mikeriin/streetlift-apk`, branche
`main`, commit **`ea22cf08fa312e308267e110d4958dccd30a09be`**, le 25 septembre 2026,
08:56–09:06 UTC (10:56–11:06 à Paris). Les 277 fichiers et 2 441 383 octets extraits
sont cohérents avec R1, mais le journal ne contient pas le SHA-256 de son ZIP.
Les résultats CI ci-dessous sont lus dans ce journal, pas exécutés par l’assistant.

| Contrôle du run R1 | Résultat fourni |
| --- | --- |
| ZIP, identité des workflows, assets | Réussis |
| Dépendances verrouillées | `flutter pub get --enforce-lockfile` réussi |
| Analyse Flutter | `No issues found!` |
| Tests Python | **22 réussis** |
| Tests Flutter | **186 réussis, 1 ignoré** ; `All tests passed!` |
| Restauration de la clé | Réussie ; accès privé et certificat local vérifiés à 08:58:53 UTC |
| Build Android release | **Réussi à 09:06:48 UTC**, APK annoncé 26,3 MB ; versionCode **212489931** |
| Contrôle final | **Échec à 09:06:49 UTC** : « Format apksigner non reconnu : aucune empreinte de certificat APK lisible. Aucun APK publié. » |
| Publication de l’artefact | Non exécutée |
| Nettoyage de la clé éphémère | Exécuté après l’échec |

**KT-001 / bug confirmé, bloquant pour la livraison :** `tools/signing.py`,
fonction `apk_certificates` de R1, ne reconnaît aucune empreinte de la sortie du
runner. Le chemin de code atteint implique un retour nul de la vérification
apksigner et un nombre de signataires reconnu égal à 1. Cela ne suffit pas à
valider le certificat attendu : la sortie brute manque toujours. Ne pas conclure
à un mauvais mot de passe ou à une autre clé. Les deux secrets actuels sont à
conserver. R1 était insuffisant ; ses simulations ne couvraient pas la sortie réelle.

## R2.2 — Correction réalisée, sans changement d’identité

Le lecteur des messages de la CLI apksigner est supprimé. Le nouveau source
`tools/VerifyApkCertificate.java` utilise directement `ApkVerifier` dans le
`lib/apksigner.jar` voisin de l’outil sélectionné par le workflow existant.
Java 17 exécute le source sans déposer de `.class` dans le projet. Aucune nouvelle
bibliothèque n’est livrée ou téléchargée par le workflow ; versions inchangées.

La publication exige : `isVerified()` vrai, exactement un certificat signataire
final, pas de signataires multiples en v1/v2, et même SHA-256 du certificat DER
pour toutes les feuilles v1/v2/v3/v3.1 retournées. Les lignées présentes sont
limitées à un certificat identique : aucune rotation autorisée. La plage Android
par défaut du manifeste est conservée, sans réduire les versions vérifiées.
Les chaînes de certification et le Source Stamp ne sont pas comptés comme des
identités de signature APK.

Python exige le code de sortie réussi ET le protocole fixe du contrôleur ET
l’empreinte attendue. Bibliothèque absente, compilation/exécution Java impossible,
API incompatible, réponse absente/malformée, cryptographie invalide, plusieurs
signataires, rotation ou certificat différent bloquent l’artefact. Les sorties
brutes et exceptions des outils ne sont pas reproduites. Les deux secrets sont
retirés de l’environnement transmis au contrôleur APK. Seuls des statuts fixes
et des empreintes publiques validées peuvent apparaître dans les diagnostics.

Référence publique conservée :
`9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`.
Elle n’est ni une clé privée ni une preuve de la signature de l’APK installé.
La restauration du keystore, les mots de passe requis, l’alias, Gradle et le
workflow ne changent pas. Aucune clé créée, remplacée ou tournée.

## R2.3 — Vérifications locales réellement exécutées

- **26 tests Python réussis** : restauration et packaging conservés, 11 tests du
  nouveau protocole/contrôleur Python. Ils couvrent notamment les codes de retour
  contradictoires, empreinte différente, réponses vides/tronquées/répétées,
  absence de fichiers/outils, délai dépassé et suppression des secrets de
  l’environnement. Ces tests unitaires utilisent des sous-processus simulés.
- **8 cas cryptographiques réels** exécutés avec Java 17 et la bibliothèque
  précompilée publique AOSP ; résultats ci-dessous. Aucune clé téléchargée,
  créée ou utilisée pour signer. Seuls des APK publics déjà signés sont vérifiés.
- **4 cas de bout en bout Python → Java → apksig** : APK valide accepté ; APK
  altéré, plusieurs signataires et rotation refusés.
- Contrôle des assets et de l’identifiant réussi sans secrets : 40 semaines,
  280 jours, 1 954 exercices du programme, 505 exercices de la base.
- Contrôle du ZIP livré : CRC, racine, chemins, limite de taille et filtre de
  packaging ; recherche exacte des octets de la clé A0, de son Base64 et du
  mot de passe historique, sans affichage. Comparaison des fichiers préservés
  et de l’identité des deux copies du workflow.
- Environnement local : terminal/Python/Java 17 et module compilateur disponibles.
  Flutter, Dart et Android SDK complets absents. **Aucune compilation Android
  locale ni test sur téléphone.** L’exécution du source Java n’est pas un build Android.

| Cas réel local | Résultat |
| --- | --- |
| `golden-aligned-v1v2v3-out.apk`, certificat attendu | Accepté |
| Même APK, autre empreinte attendue | Refus certificat différent |
| `golden-aligned-v1v2v3-lineage-out.apk` | Refus rotation |
| `two-signers.apk` | Refus plusieurs signataires |
| `empty-unsigned.apk` | Refus fichier non vérifiable |
| `incorrect-v2-block-size.apk` | Refus cryptographique |
| Copie du premier APK avec une entrée ZIP ajoutée | Refus cryptographique |
| `valid-stamp.apk` | Accepté, Source Stamp non compté comme second signataire |

Bibliothèque de validation locale : AOSP `platform/prebuilts/sdk`,
`tools/linux/lib/apksigner.jar`, 1 074 052 octets, SHA-256
`9469c60e5e40fc5c44a2f2338509cb6600cdf065e9b50f9fa3ca6c5be5bae6a9`.
Ce JAR et les APK de test restent hors du ZIP. Le JAR exact du runner n’a pas été
reçu ; l’exécution CI avec son SDK reste nécessaire. Deux téléchargements
supplémentaires de fixtures v3.1/chaîne ont expiré : ces cas ne sont pas revendiqués
comme essais réels locaux. Les branches correspondantes sont compilées et relues.

Sources primaires consultées :
- https://android.googlesource.com/platform/tools/apksig/+/master/src/main/java/com/android/apksig/ApkVerifier.java
- https://android.googlesource.com/platform/tools/apksig/+/master/src/test/resources/com/android/apksig/
- https://android.googlesource.com/platform/prebuilts/sdk/+/refs/heads/main/tools/linux/lib/apksigner.jar

## R2.4 — Fichiers modifiés et actions du propriétaire

Par rapport à R1, quatre fichiers modifiés :

1. `tools/signing.py` — remplacement du lecteur CLI par le contrôle Java direct.
2. `tools/tests/test_release_security.py` — régressions du nouveau protocole.
3. `docs/SIGNATURE_ET_ZIP.md` — reprise R2 depuis le téléphone.
4. `SUIVI_PROJET.md` — preuve du second run, correction, résultats et limites.

Un fichier ajouté : `tools/VerifyApkCertificate.java`.
Les **273 autres fichiers sont identiques à R1**, notamment code métier,
interfaces, assets, tests Dart, application ID `fr.tchoupi.streetlift_tracker`,
versions, dépendances, Gradle, wrapper et certificat de référence. Aucun retrait.
La copie du workflow incluse est identique au `build-apk.yml` livré séparément.

Actions sur téléphone : conserver secrets et workflow ; remplacer seulement le
ZIP à la racine de `main` avec son nom exact ; créer le commit ; suivre son
nouveau run, ou **Actions → Build APK → Run workflow → main**. **Re-run jobs**
sur l’ancien run reprendrait l’ancien commit. Le guide inclus donne le détail.
Une fois l’artefact publié, sauvegarder les données puis installer comme mise à
jour sans désinstaller ; vérifier les données conservées sur le téléphone.

## R2.5 — Validations encore ouvertes

- Exécution du nouveau contrôle R2 dans GitHub Actions, puis publication de l’APK.
- Comparaison du certificat au dernier APK réellement installé : APK non accessible.
- Refus réel d’une release Gradle sans secrets : attendu par le code, pas testé
  par ces runs réussissant la compilation avec des secrets valides.
- Mise à jour sur téléphone sans désinstallation et conservation des données.
- Validation explicite du propriétaire. **L1 n’est pas déclaré validé.**

Les avertissements NDK, Java/Node et surveillance Gradle n’ont pas empêché les
builds reçus ; ils restent consignés pour un lot ultérieur, sans lancer L1b.
Le plafond de 25 000 000 octets concerne le ZIP source, pas l’APK de 26,3 MB.
La sauvegarde privée et la confidentialité passée restent déclarées par le
propriétaire. Aucun audit indépendant d’exposition passée n’a été réalisé ; si
une exposition est découverte ou devient incertaine, elle reste un sujet ouvert.
Nettoyer ce ZIP ne répare pas une exposition passée. Toute rotation éventuelle
reste une décision distincte. Aucun accès ni changement du dépôt distant.

---

# Historique R1 — État avant le second journal CI

# Kalis Track — Suivi du projet

**Passe actuelle : L1-R1 — correctif du contrôle final du certificat, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative : 2.5.0+51, inchangée**  
**Statut : compilation L1 réussie dans le journal CI fourni, livraison bloquée au contrôle d’identité du certificat. Lecteur et diagnostics corrigés dans R1 ; nouvelle exécution CI requise. L1 non validé par le propriétaire.**

## R1.1 — Base et preuve CI reçue

Copie de travail extraite exclusivement de la livraison L1 de cette conversation :
`streetlift_tracker_v33.zip`, **1 228 032 octets**, SHA-256
`454dd1eda13fe730bbe1baad6ab706fab677f589cbaf5591f65df1ae6ac9747e`,
racine `streetlift_tracker/`, 277 fichiers ; empreinte et CRC revérifiés.
Cette archive et la source A0 restent intactes. Le journal ne fournit pas le
SHA-256 du ZIP utilisé dans la CI : ses 277 fichiers et 2 421 728 octets extraits
sont cohérents avec L1, sans constituer une preuve indépendante de l’empreinte.

Journal transmis par le propriétaire, dépôt `mikeriin/streetlift-apk`, branche
`main`, commit `3983b4c3ca0c2b94583fff9912ee348b933d5ae2`, le 25 septembre 2026
entre 08:26 et 08:35 UTC (10:26–10:35 à Paris). Aucun accès au dépôt distant ni
relancement par l’assistant. Les résultats ci-dessous proviennent de ce journal,
ils ne sont pas présentés comme des exécutions locales de l’assistant.

| Étape dans le journal L1 | Résultat observé |
| --- | --- |
| ZIP / identité des workflows / assets | Réussis ; 277 fichiers, 1 954 exercices du programme, 505 exercices de la base |
| Dépendances verrouillées | `flutter pub get --enforce-lockfile` réussi |
| Analyse Flutter | `No issues found!` |
| Tests Python | **16 réussis** |
| Tests Flutter | **186 réussis, 1 ignoré** ; capture visuelle ignorée ; `All tests passed!` |
| Secrets de signature | Deux variables présentes et masquées ; restauration de la clé, accès privé et égalité au certificat local réussis à 08:29:02 UTC |
| Build release | **Réussi à 08:35:23 UTC** ; APK annoncé 26,3 MB ; `versionCode` **212488142** |
| Contrôle final du certificat | **Échec à 08:35:24 UTC**, message générique « Le certificat de l’APK diffère de la référence locale ou est ambigu. » |
| Artefact téléchargeable | Étape de publication non exécutée ; aucun APK fourni à l’assistant |
| Nettoyage de la copie de clé du runner | Commande exécutée après l’échec |

Le code L1 émet ce message après un retour nul d’`apksigner verify` : on peut donc
inférer que sa vérification cryptographique a réussi, mais la comparaison avec
l’identité locale n’est pas validée. Le message réunissait trois causes : zéro
empreinte reconnue, plusieurs empreintes reconnues, ou empreinte différente.
La sortie d’`apksigner` étant capturée et absente du journal, **la cause exacte de
cet échec ne peut pas être déterminée sur ces seuls logs**. Ne pas conclure à une
mauvaise clé ni demander de remplacer les secrets sur cette base.

Les avertissements NDK (26.3.11579264 configuré, 27.0.12077973 demandé par des
plugins), actions Java/Node dépréciées et surveillance de chemin Gradle n’ont pas
empêché cette compilation. Ils sont consignés pour L1b/KT-019 ou le futur examen
des outils ; aucune version n’est changée dans R1. La limite de 25 000 000 octets
concerne le ZIP source, pas la taille de l’APK.

## R1.2 — Défauts confirmés et correction limitée à KT-001

**Bug confirmé dans le contrôleur L1 :** le lecteur acceptait exclusivement une
ligne commençant exactement par `Signer #N`, tandis que l’outil AOSP peut aussi
émettre des identifiants par plage de SDK. Les erreurs de lecture et les vraies
différences de certificat recevaient le même message. Les tests initiaux ne
couvraient qu’une sortie minimale numérotée.

Reproduction locale sur sorties simulées : une plage de SDK au format AOSP et
une ligne indentée avec CRLF sont refusées par L1 malgré une empreinte attendue,
puis acceptées par R1. Cela prouve la fragilité du contrôleur initial, **pas que
l’une de ces deux sorties était effectivement celle du runner**.

R1 demande `apksigner verify --verbose --print-certs`, lit le nombre de signataires
et prend en charge les deux formes connues. La publication reste bloquée si la
vérification cryptographique échoue, si le format est inconnu ou incomplet, si le
nombre de signataires n’est pas exactement un, si les lignes sont répétées ou
incohérentes, ou si une empreinte de certificat diffère du repère local. Toutes
les plages de SDK doivent conserver la même empreinte. Aucune rotation ou
signature alternative n’est acceptée. Les empreintes de **clé publique** et de
**Source Stamp** ne remplacent pas celles du certificat de signature APK.

Les diagnostics distinguent désormais erreur cryptographique, format non reconnu,
ambiguïté et certificat différent. En cas de différence, ils donnent seulement
les SHA-256 publics attendu et observés, sans sortie brute, DN ou secrets.
Un succès affiche également l’empreinte publique contrôlée. La référence publique,
la restauration de la clé, les mots de passe requis et Gradle ne sont pas modifiés.

Source primaire du format :
https://android.googlesource.com/platform/tools/apksig/+/master/src/apksigner/java/com/android/apksigner/ApkSignerTool.java
(fonctions de vérification et `printCertificate`, consultées le 25 septembre 2026).

## R1.3 — Vérifications et fichiers modifiés

- **22 tests Python réussis localement**, dont 6 nouveaux tests couvrant le
  certificat APK. Cas vérifiés : sorties standard et plages de SDK, CRLF,
  indentation, casse hexadécimale, digest de clé publique/Source Stamp distinct,
  vrai désaccord d’empreinte simulé, plusieurs signataires, sortie vide,
  tronquée/inconnue, répétitions et échec cryptographique. Aucun APK réel n’est
  signé ou vérifié par ces fixtures ; aucune clé n’est générée.
- Contrôle des assets et de l’identifiant réussi sans secrets.
- Nouveau ZIP : contrôles de packaging, CRC, chemins et exclusion des secrets
  exécutés. Taille et SHA-256 exacts dans le fichier séparé `LIVRAISON_L1.md`.
- Comparaison avec L1 : seules les quatre entrées ci-dessous sont modifiées ;
  aucun fichier ajouté ou retiré. Tous les autres fichiers sont identiques,
  notamment `lib/`, `test/`, assets, Gradle, dépendances, wrapper, référence
  publique, outil HTML et workflow. La copie séparée du workflow reste identique.
- Flutter, Dart et Android SDK restent absents localement : aucune nouvelle
  compilation Android ni vérification de l’APK de ce run effectuée ici. Les
  succès Flutter/Android du journal L1 ne sont pas attribués rétroactivement au
  nouveau contrôleur R1.

Fichiers modifiés par rapport au ZIP L1 précédent :

1. `tools/signing.py` — lecture des certificats et diagnostics.
2. `tools/tests/test_release_security.py` — régressions du lecteur.
3. `docs/SIGNATURE_ET_ZIP.md` — reprise depuis le téléphone après ce run.
4. `SUIVI_PROJET.md` — résultats CI reçus, correction et limites.

Le périmètre cumulé par rapport à A0 est conservé dans l’historique L1 ci-dessous.
Aucune modification métier ou visuelle, aucun travail L1b ni dépôt distant modifié.
Les déclarations antérieures de sauvegarde privée et de confidentialité restent
des déclarations du propriétaire ; ce run n’audite pas l’exposition passée.

## R1.4 — Reprise depuis le téléphone et critères encore ouverts

1. Garder les deux secrets GitHub actuels : le journal montre qu’ils permettent
   déjà de restaurer et d’utiliser la clé attendue.
2. Remplacer seulement `streetlift_tracker_v33.zip` à la racine de la branche
   `main` par le ZIP R1, via **Code → Add file → Upload files**, puis commit.
   Le workflow n’a pas changé ; son fichier séparé est fourni pour référence.
3. Suivre le **nouveau run** déclenché par ce commit. Si nécessaire, utiliser
   **Actions → Build APK → Run workflow → main**. Ne pas utiliser **Re-run jobs**
   sur l’ancien run pour tester R1 : cette action réutilise l’ancien commit.
4. Attendre le contrôle final et la publication de l’artefact. Si l’étape échoue
   encore, transmettre son nouveau message : il distinguera un problème de
   lecture d’une réelle différence d’empreinte. Les SHA-256 affichés sont publics ;
   ne transmettre aucune clé ni valeur de secret.
5. Après succès complet, conserver une sauvegarde des données et le dernier APK
   fonctionnel, puis installer comme mise à jour sans désinstaller. Vérifier
   historique, séances, crédits, achats et réglages sur le téléphone.

Référence GitHub sur les relances :
https://docs.github.com/fr/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs

**Restent ouverts :** succès du contrôle final R1 dans la CI ; comportement Gradle
réel sans secrets (le run reçu utilise des secrets valides) ; comparaison avec le
dernier APK effectivement installé ; conservation des données lors de la mise à
jour ; validation explicite du propriétaire. Aucun « testé sur appareil », aucune
continuité de mise à jour et aucune validation propriétaire ne sont revendiqués.
L1b n’est pas commencé.

---

# Historique L1 — État avant réception du journal CI

Les mentions de CI non exécutée, secrets encore absents et 16 tests locaux dans
les sections L1 suivantes décrivent la première livraison. L’état R1 ci-dessus
prévaut ; l’historique A0 reste conservé à sa suite.

**Passe actuelle : L1 — Signature et ZIP, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative conservée : 2.5.0+51**  
**Statut : KT-001 corrigé dans la copie livrée, contrôles Python et Java locaux réussis ; validation Android/CI et continuité sur téléphone encore à effectuer. L1 non validé par le propriétaire.**

## L1.1 — Référence, périmètre et décisions

Source exclusive revérifiée avant les modifications : `streetlift_tracker_v33.zip`,
**1 190 723 octets**, SHA-256
`50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f`,
racine `streetlift_tracker/`, CRC correct, version `2.5.0+51`.
Le workflow source audité était identique à sa copie interne. Le travail a été
réalisé dans une nouvelle copie ; l’archive et l’extraction source sont intactes.

Seul KT-001 a été traité. Aucun audit global repris, aucun travail L1b, métier,
sauvegarde applicative ou visuel. `lib/`, `test/`, tous les assets, `pubspec.yaml`,
`pubspec.lock`, les versions d’outils et le wrapper Gradle sont identiques à la
source. Les formules et fonctionnalités ne sont pas modifiées. L’identifiant
reste `fr.tchoupi.streetlift_tracker` ; compileSdk 36, targetSdk 35 et minSdk 21
restent inchangés. Flutter 3.29.3, Java 17, Gradle 8.13, AGP 8.12.1 et Kotlin 2.2.10
sont conservés.

| Point | État L1, sans dépasser les preuves disponibles |
| --- | --- |
| Copie privée de la clé et moyens d’accès | **Oui**, confirmé par le propriétaire ; sauvegarde externe non inspectée |
| Distribution | **APK installé directement**, déclaration du propriétaire |
| Play App Signing | **Non activé**, déclaration du propriétaire |
| Confidentialité passée du ZIP/dépôt | **Restés privés**, déclaration du propriétaire ; historique distant non inspecté |
| Secrets GitHub | **Absents au début de L1**, déclaration ; à créer par le propriétaire |
| APK de référence | Annoncé joint, mais aucun fichier APK accessible pendant cette passe |
| Matériel du propriétaire | **Téléphone uniquement** : procédure navigateur GitHub et préparation locale hors ligne fournies |
| Clé examinée localement | Clé privée existante utilisable sous l’alias `kalis`, certificat conforme au repère local |
| Validation installée | Non effectuée : le certificat local ne prouve pas celui de l’application du téléphone |

Aucune clé n’a été générée, remplacée par une nouvelle identité ou tournée.
Aucune source n’a été détruite, aucun dépôt distant ni secret GitHub n’a été
modifié par l’assistant. Les copies temporaires créées pour les essais locaux
ont été supprimées après contrôle ; la source et la sauvegarde du propriétaire
ne sont pas concernées. Si une exposition passée est découverte ou devient
incertaine, le sujet reste ouvert : le nettoyage du ZIP ne résout pas une
exposition ancienne. Toute rotation exige une décision séparée.

## L1.2 — KT-001 : correction et preuves

**Identifiant stable : KT-001 ; gravité initiale P0 ; bug de sécurité confirmé dans la source.**

La clé privée et les trois copies connues du mot de passe de secours sont retirées
du nouveau paquet. Les deux variables `KALIS_KEYSTORE_BASE64` et
`KALIS_KEYSTORE_PASSWORD` sont obligatoires pour restaurer et utiliser la clé.
Aucun ancien nom de variable ne sert de repli. La restauration crée les dossiers,
utilise un fichier temporaire privé, vérifie le certificat puis l’accès à la clé
privée et refuse d’écraser une copie locale différente. Les diagnostics ne
reproduisent ni les secrets ni la sortie d’erreur de keytool.

Le certificat public de référence est inchangé :
`9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`.
Cette empreinte n’est ni la clé privée ni une preuve du certificat de l’APK installé.

Gradle garde une configuration release dédiée, sans secours debug. Les tâches
qui produisent ou signent une release vérifient les deux secrets, le fichier
restauré, son mot de passe, la clé privée et le certificat. Les contrôles sans
production release ne déclenchent pas cette exigence. La CI exécute les contrôles
sans secrets avant la restauration ; elle compare le certificat de l’APK produit
au repère local et ne publie que l’APK et son empreinte. Cette configuration CI et
Gradle est livrée mais n’a pas été exécutée ici.

Le packaging filtre les secrets/fichiers locaux/binaires/caches, détecte les
copies reconnues de clés ou mots de passe dans les contenus, puis rescane le ZIP.
Les contrôles de chemins, doublons, liens, CRC et taille sont inclus. Un refus
conserve l’archive précédente. La protection ciblée n’est pas une garantie de
reconnaissance de tout secret arbitraire ou obfusqué.

## L1.3 — Tests exécutés et limites

| Domaine | Résultat réel |
| --- | --- |
| Tests Python | **16 tests réussis** : 4 existants et 12 nouveaux, aucune clé réelle dans les fixtures |
| Contrôles sans secrets | `verify_project.py` : code 0 ; 40 semaines, 280 jours, 1 954 exercices du programme, 505 exercices de la base ; XML et identifiant contrôlés |
| Absence de secrets | `signing.py restore` et `verify_project.py --signing` : **code 1** avec nom du secret obligatoire absent ; aucune valeur affichée |
| Restauration réelle | Clé source existante restaurée dans un dossier privé jetable ; `keytool` a exporté le certificat en mémoire et signé une requête éphémère en mémoire, démontrant l’accès à la clé existante ; égalité du certificat vérifiée |
| Refus réels avec Java | Mot de passe invalide, conteneur invalide et référence de certificat différente refusés ; copie locale existante conservée et temporaires nettoyés |
| Régressions automatisées | Secrets manquants, Base64 invalide, répertoires/permissions, copie différente, liens, erreur externe non divulguée, certificat sans clé privée simulé, certificat APK simulé, exclusions ZIP, contenus sensibles, chemins dangereux et conservation de l’ancienne archive |
| Workflow | YAML lu et structure contrôlée ; secrets limités aux deux étapes concernées ; égalité octet par octet de la copie livrée séparément et de la copie interne |
| Outil pour téléphone | JavaScript testé sous Node avec DOM simulé : conversion, copie Clipboard API/repli, effacement, refus de fichiers invalides, absence d’affichage ; CSP sans réseau inspectée. Aucun navigateur réel disponible : lancement Chromium impossible faute d’exécutable. Aucun essai sur téléphone |
| Exclusion des secrets dans le ZIP final | Scan par le packager et recherche exacte des octets de la clé source, de son Base64 et du mot de passe historique : aucune occurrence ; clé privée exclue, référence publique et wrapper présents |
| Conservation du projet | Comparaison fichier par fichier avec le ZIP source : seules les entrées listées ci-dessous diffèrent ; source originale revérifiée intacte |
| Flutter / Dart / Android | SDK et outils absents : **aucune analyse Flutter, aucun test Dart, aucune compilation APK/AAB, aucune installation** exécutés ici |
| CI et APK installé | Aucun accès distant ou lancement Actions ; APK de référence indisponible, comparaison non effectuée |

**Le succès Python/Java ne constitue pas une compilation Android.** Le refus d’une
release sans secrets est établi pour l’outil Python et prévu dans Gradle ; le
comportement Gradle réel reste à exécuter avec la chaîne Android dans la CI.

## L1.4 — Fichiers livrés et changements exacts

Fichiers modifiés par rapport au ZIP de référence :

- `.gitignore` — exclusions des secrets et artefacts.
- `.github/workflows/build-apk.yml` — contrôles sans secrets, restauration obligatoire, secret limité aux étapes nécessaires, comparaison du certificat APK, nettoyage de la copie du runner.
- `android/app/build.gradle.kts` — mot de passe uniquement via secret, garde de signature release.
- `tools/verify_project.py` — contrôles non signés conservés, signature confiée au vérificateur explicite.
- `tools/package_release.py` — exclusions, inspection des contenus, vérification finale du ZIP et mode `--check`.
- `README.md` — consignes actuelles de signature et renvoi vers la procédure téléphone.

Fichiers ajoutés :

- `SUIVI_PROJET.md` — ce suivi, avec l’audit initial conservé ci-dessous comme historique.
- `docs/SIGNATURE_ET_ZIP.md` — procédure complète, actions GitHub dans l’ordre, limites de validation.
- `tools/signing.py` — restauration et vérifications de clé/certificat/APK.
- `tools/release_security.py` — contrôles de livraison réutilisables.
- `tools/tests/test_release_security.py` — 12 régressions KT-001.
- `tools/preparer_signature.html` — conversion locale hors ligne depuis le téléphone, sans envoi réseau ni mot de passe demandé.

Fichier retiré **uniquement de la copie distribuable** :
`signing/kalis_track.p12`. Il reste dans la source privée intacte ; le propriétaire
conserve sa sauvegarde indépendante. Les **265 autres fichiers source** sont
inchangés, y compris le certificat public et le wrapper Gradle.

Livrables séparés : ZIP complet racine `streetlift_tracker/`, workflow, ce suivi,
outil HTML et guide téléphone. `LIVRAISON_L1.md` donne la taille et le SHA-256 du
ZIP final ainsi que les liens/fichiers à utiliser. Le hash du ZIP n’est pas inscrit
dans le suivi interne, car inclure le hash d’une archive dans elle-même le
modifierait. Les copies séparées du suivi, workflow, guide et HTML sont identiques
aux fichiers correspondants du ZIP. La version applicative n’est pas augmentée.

## L1.5 — À effectuer par le propriétaire

Suivre `docs/SIGNATURE_ET_ZIP.md` dans l’ordre depuis le téléphone. Créer les deux
secrets, remplacer le ZIP et le workflow, puis lancer la CI. Vérifier l’échec
explicite sans secrets dans une exécution contrôlée si nécessaire avant d’activer
la livraison ; ne pas effacer la seule sauvegarde pour faire ce test. Obtenir une
compilation release réussie avec la clé existante, le contrôle du certificat et
les résultats des tests Flutter. Comparer le certificat du dernier APK réellement
utilisé dès qu’il est disponible, puis effectuer la mise à jour sans désinstaller
et contrôler la conservation des données.

**KT-001 : corrigé et partiellement testé automatiquement ; validation CI/Android
et propriétaire en attente. L1 reste non validé. L1b et tous les autres lots
restent non commencés.** Les tickets KT-002 à KT-023 conservent leurs constats et
priorités de l’audit A0 ; ils ne sont pas requalifiés ni corrigés dans cette passe.

---

# Historique A0 — Audit initial conservé

**Toutes les sections ci-dessous décrivent l’état du ZIP source avant L1.**
Leurs mentions « aucun correctif », « tous ouverts », numéros de ligne, anciens
chemins et questions de signature sont historiques. Pour KT-001 et les
confirmations du propriétaire, l’état L1 ci-dessus prévaut.

**Passe : A0 — audit initial et préparation uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Référence applicative : 2.5.0+51**  
**Statut : audit initial livré ; aucun correctif appliqué ; publication non validée.**

Ce document suit exclusivement le ZIP et le workflow joints à cette passe. Le grand prompt constitue le cahier des charges ; la demande du 25 septembre limite cette passe à l'audit et prévaut sur ses instructions de modification immédiate. Aucune ancienne archive n'a été utilisée. Les anciens rapports contenus dans ce ZIP sont des documents historiques, pas des résultats exécutés pendant cet audit.

**Priorités :** sécuriser la signature sans rompre les mises à jour ; fiabiliser la sauvegarde et les achats ; corriger l'essai WOD à minuit et sa stabilité ; préparer le départ personnel du programme. Le ciblage Android et les droits des contenus restent des sujets de publication. La finition visuelle vient après ces protections. Le registre distingue les défauts établis par le code des scénarios encore à reproduire.

## 1. Référence et capacité de travail

| Élément | Vérification réelle |
| --- | --- |
| Archive reçue | `streetlift_tracker_v33.zip` |
| Taille exacte | **1 190 723 octets** |
| SHA-256 | `50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f` |
| Racine unique | `streetlift_tracker/` |
| Contenu | **272 fichiers**, 2 320 919 octets décompressés ; aucune entrée de répertoire explicite |
| Intégrité | Ouverture et `ZipFile.testzip()` réussis : aucune erreur CRC |
| Extraction | Réussie ; vérification préalable des chemins absolus, traversées `..` et liens symboliques : aucun détecté |
| Lecture et écriture | `pubspec.yaml` lu, copié hors du projet, puis modifié dans cette copie jetable uniquement |
| Création de ZIP | Copie jetable réarchivée puis relue : contenu identique au fichier modifié |
| Réarchivage complet | ZIP de contrôle de **272 fichiers**, **1 193 390 octets**, CRC valide et SHA-256 de chaque fichier identique à la source |
| Empreinte du ZIP de contrôle | `7d610cf246bb156539996a54fde14e778604db68ba72fabb040438f5cba98bf1` ; archive technique temporaire, pas une nouvelle version applicative |
| Conservation de la source | Comparaison de tous les fichiers extraits avec leur empreinte dans le ZIP reçu : **0 fichier modifié** |

Le test d'écriture ne touche aucun fichier de la source auditée. La différence d'empreinte entre les deux ZIP ne signifie pas une différence de code : l'ordre et les métadonnées de l'archive reconstruite diffèrent. L'archive source reste la référence de la prochaine passe, sauf fourniture explicite d'un autre ZIP.

| Autre référence fournie | Taille | SHA-256 |
| --- | --- | --- |
| `build-apk.yml.txt` | 3 684 octets | `fa907edc70c23014beed5a28a4416163d80813d63d81ad10edde20c501d6cf80` |
| `prompt_finalisation_kalis_track.txt` | 23 703 octets | `a67515f0167e10c8e44497bfde536ade3bbec49a2db50466ebb726869437cd42` |

La copie `streetlift_tracker/.github/workflows/build-apk.yml` est **identique octet par octet** au workflow joint. Aucune divergence actuelle entre ces deux exemplaires.

### Outils disponibles

| Outil ou capacité | État constaté | Conséquence |
| --- | --- | --- |
| Terminal Bash, `rg`, Git, ZIP/unzip | Disponibles | Inspection, empreintes, extraction et livraison ZIP possibles |
| Python | **3.12.14** | Contrôles et tests Python exécutables |
| Java et `keytool` | **OpenJDK 17.0.20** | Inspection du certificat et du type d'entrée du keystore possible |
| Flutter / Dart | Introuvables dans le PATH et les emplacements usuels inspectés ; `FLUTTER_ROOT` non défini | Analyse, formatage, résolution des dépendances, tests et rendu Flutter non exécutables ici |
| Android SDK / `adb` / `sdkmanager` / `avdmanager` / `apksigner` | Non disponibles ; `ANDROID_HOME` et `ANDROID_SDK_ROOT` non définis | Compilation, signature d'artefacts et installation Android non exécutées |
| Gradle système | Absent | Le wrapper du projet est présent, mais il ne remplace pas les SDK manquants |
| Wrapper Gradle | `android/gradlew`, JAR et propriétés présents | Conservation obligatoire dans les futurs ZIP |
| Émulateur / téléphone | Aucun moyen de test Android disponible dans cet environnement | Aucun parcours vérifié sur appareil |
| Accès à la CI / Play Console | Non utilisé | Aucun workflow distant déclenché ; statut de publication et signatures installées inconnus |

Aucun SDK n'a été installé pendant cette passe. Aucun test Flutter ou build Android n'a été lancé pour être ensuite présenté comme réussi. La présence d'une clé dans l'archive permet l'inspection de signature locale ; elle ne résout pas l'absence des SDK.

## 2. Structure et périmètre réellement inspecté

Le projet comprend **47 fichiers Dart dans `lib/`, totalisant 22 779 lignes**, 23 fichiers Dart sous `test/` dont le support de notifications, 8 fichiers d'outillage Python, 27 assets, 47 fichiers Android, 64 éléments sous `validation/`, ainsi que les documents historiques. Aucun dossier iOS, dossier `integration_test/`, APK, AAB ou cache `build/`, `.dart_tool/`, `.gradle/` n'est présent dans le ZIP.

### Niveau de lecture

« Lecture ciblée » signifie que les fonctions et passages utiles ont été examinés, **pas** que toutes les lignes du fichier ont été auditées. Une recherche de symboles n'est pas une validation du comportement.

| Zone | Lecture effectuée | Reste à examiner |
| --- | --- | --- |
| Références | Grand prompt ; workflow entier ; `pubspec.yaml` ; versions et SDK de `pubspec.lock` ; sections de `README.md` ; `REFONTE_UI.md`, derniers audits 2.5.0 et 2.4.1 ; rapports Python/projet 2.5.0 | Archives documentaires plus anciennes, licences détaillées des dépendances ; pas de reprise automatique de leurs conclusions |
| Android et livraison | Gradle app/projet/settings, wrapper, manifeste principal ; `MainActivity.kt` et `device.dart` ciblés ; `tools/verify_project.py`, `package_release.py`, tests Python | Manifeste fusionné release, bytecode, bibliothèques natives, shrinker, variantes de build et compatibilité effective |
| Données | `store.dart` : initialisation, migration des accès, crédits, sélections WOD, résultats, sérialisation, import, écriture différée, flush, fin et archivage de séance ; `models.dart` : calendrier | Parser d'exercices, toutes les branches d'import historiques, toutes les formules et estimations ; stress de stockage réel |
| Démarrage et navigation | `main.dart` et démarrage ; routes programme/rappel ; structure des quatre onglets et des quatre sous-onglets STATS | Rendu réel, boutons retour, empilement de routes et interruptions |
| Programme et historique | `home_screen.dart`, `session_screen.dart`, `session_history.dart` : entrée, préremplissage, validation, sauvegarde, bilan et copie de l'historique ; pilotage ciblé | Chaque mode de séance et chaque saisie ; toutes les corrections historiques ; fin du programme sur appareil |
| Progression | Calculs ciblés de `progression.dart`, `game.dart` ; consommation du bilan dans `rewards.dart` ; pastille `levelup.dart` | Tous les badges, boss, saisons et classements ; dédoublonnage sous interruptions ; rendu des célébrations |
| WOD | `store.dart`, `wod_screen.dart`, `wod_preview.dart`, modèles, sélection des sources et cas Tabata du générateur ; routes Arsenal/catalogue et tests WOD | Catalogue intégral, toutes les variantes de score, listes/filtres, géométrie et peintres de `wod_store.dart` |
| Réglages | Options, sauvegarde par presse-papiers, dialogue d'import, À propos ; notifications ciblées | Effet réel de chaque option, interactions pendant une séance ouverte |
| Notifications et chronos | `notifications.dart` : planification, permissions, repli approximatif, file de reprogrammation ; `timers.dart` : horloges, pause, rattrapage ; `alerts.dart` | Exécution native, doze, redémarrage, réveil, limites constructeur, destruction du processus |
| UI et STATS | Palette, conteneurs partagés, début du dock, navigation STATS ; recherche des routes des vues Aperçu/Parcours/Performances/Historique | Audit intégral de `stats_*`, `stats_data.dart`, `records_screen.dart`, `training_estimate.dart`, `estimate_view.dart`, `muscle_body.dart`, `motion.dart`, éditeur et recherche ; aucun rendu validé |
| Tests | Tests Python lus et exécutés ; lecture ciblée de `store_test.dart`, `wod_store_test.dart`, `reward_flow_test.dart`, inventaire des scénarios chronos, notifications et historique | Exécution de tous les tests Dart ; examen détaillé du reste ; tests d'intégration à prévoir |

Les assets compressés ont été ouverts, leurs données structurées vérifiées et leurs empreintes calculées. Le contenu sportif complet, les droits et l'apparence de chaque image n'ont pas été validés.

### Cartographie des parcours

| Entrée | Parcours observé dans le code | Données principales |
| --- | --- | --- |
| Démarrage | Chargement assets + préférences → transition → Programme ; écran de récupération si échec | État courant ou anciennes préférences |
| Programme | Semaine/jour → séance ou historique si déjà fait → séries/repos → bilan → récompenses | `logs`, clés `S<semaine>-J<jour>`, dates réelles des séries et de fin |
| Notification | Payload semaine/jour → même fonction `openProgramDay` que l'accueil | Planning calculé sur les dates du programme ; permissions Android |
| Arsenal, séances personnelles | Créer/éditer/dupliquer → exécuter → archiver l'occurrence précédente lors d'une répétition | `custom`, `userExercises`, journaux `S0-J<id>` puis suffixe d'archive |
| Arsenal, boutique | Catalogue/recherche/filtres → fiche → achat en crédits ou essai → chrono → score et résultats | Catalogue embarqué/généré, `unlocked`, `wishlist`, résultats WOD |
| STATS | Aperçu, Parcours, Performances, Historique ; références depuis Performances | XP, niveaux, crédits et défis dérivés ; valeurs de pilotage ; logs et scores |
| Réglages | Thèmes, saisie, chronos, jeu, écran, unités, notifications, export/import, À propos | `settings` ; export compressé ou JSON ; remplacement à l'import |

Il s'agit d'une application locale sans compte obligatoire dans le parcours inspecté. Cela ne suffit pas à conclure à une absence de transmission : sauvegarde système et dépendances restent à vérifier.

### État technique et invariants vérifiés

- `pubspec.yaml` déclare **2.5.0+51**, Dart `>=3.7.0 <4.0.0`, Flutter `>=3.29.3` ; workflow fixé à Flutter **3.29.3** et Java **17**.
- Android : `applicationId` et namespace **`fr.tchoupi.streetlift_tracker`** ; `compileSdk = 36`, `targetSdk = 35`, `minSdk = 21` ; AGP **8.12.1**, Kotlin **2.2.10**, wrapper Gradle **8.13** ; NDK délégué à Flutter. C'est la configuration lue, pas une combinaison compilée pendant cet audit.
- Dépendances verrouillées relevées : `shared_preferences 2.5.3`, backend Android `2.4.13`, `audioplayers 6.6.0`, `flutter_local_notifications 18.0.1`, `wakelock_plus 1.4.0`, `timezone 0.10.1`.
- Programme réellement vérifié : **40 semaines, 280 jours, 1 954 entrées d'exercice**, identifiants uniques ; base **505 exercices**. Ancrage JSON : **2026-07-13**.
- Catalogue : construction prévue jusqu'à 500 WOD dans la première série, puis 500 dans la seconde (`store.dart:1436–1442`, `wod_generator.dart:126,339,432–447`). Les tests attendent 1 000 WOD ; ce total n'a **pas** été recalculé par exécution Dart ici.
- Persistance : clé **`kalis_state_v3`**, format d'export **3**, imports acceptant les formats **1, 2 et 3** ; compression gzip/base64, qui n'est pas un chiffrement.
- Les suggestions préremplissent des champs mais `_prefill` ne coche pas les séries ; l'historique crée une copie et utilise les garde-fous `readOnly`. Points favorables constatés par lecture, à garder sous tests.
- Achat : le montant payé est enregistré par ID ; un second appel sur un WOD déjà possédé ne le redébite pas en mémoire. La persistance reste le défaut KT-002.
- Notifications : mode approximatif déjà implémenté si l'autorisation d'alarme exacte manque ou est révoquée pendant la planification. Il ne faut pas ajouter ce repli comme s'il était absent.

| Fichier invariant | SHA-256 de référence |
| --- | --- |
| `assets/programme_v33.json.gz` | `eb6bc659a74b7636b7ba2deafc7f888e2c8860fd4418cd081ea9c23d1f15f6c0` |
| `assets/exercises_db.json.gz` | `8564ce8205b8c999cc30067254042edfbafc4511c23a0a311a544a7a805cad0d` |
| `pubspec.lock` | `73837d07776f976bb794a64bcdfe71fbd621e8326fcacd1718e73f72a411d546` |

## 3. Registre des problèmes

Les identifiants **KT-001 à KT-023 sont stables** et seront conservés dans les prochaines passes. Tous sont ouverts. Aucun point n'est déclaré corrigé ni testé sur téléphone.

Gravité : **P0** sécurité/perte de données/blocage critique ; **P1** parcours essentiel ou publication ; **P2** finition et qualité ; **P3** amélioration facultative. Pour un risque, la gravité indique l'impact potentiel à traiter, pas un incident démontré.

Une confirmation **statique** repose sur une chaîne de code explicite. Elle ne signifie pas qu'un test Flutter a été exécuté. Les manques de livraison confirmés sont distingués des bugs fonctionnels.

### A. Bugs ou incohérences fonctionnelles confirmés par lecture

#### KT-002 — P1 — Achat annoncé réussi avant confirmation de sauvegarde

- **Preuve :** `lib/store.dart:760–768` modifie `unlockedWods`, déclenche `_persist()` puis renvoie `true`. `2035–2053` lance une écriture non attendue et absorbe l'erreur dans `persistenceError`. `lib/wod_preview.dart:45–62` déclenche immédiatement animation et message de déblocage.
- **Impact :** si l'écriture échoue, l'écran a déjà confirmé l'achat ; l'accès peut disparaître au redémarrage. Une alerte globale existe (`main.dart:210–216`), mais ce n'est pas une transaction d'achat confirmée.
- **Prochaine action :** résultat asynchrone d'achat, état en cours/échec, cohérence mémoire/disque et test d'écriture refusée. Ne modifier ni prix ni dotation.
- **Responsable / lot :** IA, L2.

#### KT-003 — P1 — Essai commencé avant minuit : enregistrement bloqué après expiration

- **Preuve :** `lib/wod_screen.dart:83–93,107–110,171–175` vérifie `store.canRun(w)` au démarrage, à l'ouverture du score et lors de la reconstruction. `store.dart:865–893` recalcule l'essai selon le jour présent ; aucun droit attaché à la session commencée.
- **Scénario déduit :** commencer un essai non acheté à 23 h 59 ; finir après changement d'essai. `_score()` retourne avant d'ouvrir la saisie ; une reconstruction peut présenter la fiche d'achat. Le chrono n'est pas un résultat sauvegardé.
- **Prochaine action :** conserver le droit de terminer une tentative légitimement lancée, sans rendre le WOD définitivement acquis ; test 23 h 59 → 00 h 01 avec horloge contrôlée.
- **Responsable / lot :** IA, L3.

#### KT-004 — P1 — La règle « un essai du jour stable » n'est pas garantie

- **Preuve :** `_pick` ne prend que les WOD verrouillés (`store.dart:824–854`). L'achat retire donc le WOD essayé du pool. `notifyListeners()` invalide `_trialKey` et `_weeklyKey` (`1322–1327`). `trialWod` utilise une préférence, pas un filtre strict : les candidats non frais restent dans `rest` (`845–846,875–883`). La vitrine dépend aussi du niveau cible, recalculé après notification (`903–912`).
- **Scénarios déduits :** terminer puis acheter l'essai peut en faire apparaître un autre le même jour ; sans candidat préféré, un WOD déjà tenté peut être proposé ; une évolution des références/niveau peut modifier les sélections. Aucun ID quotidien persistant n'est exporté (`1736–1771`).
- **Contradiction :** `README.md:10–11`, `AUDIT_2.5.0.md:19–20` promettent un essai unique et une vitrine stable hors achat. Les tests lisent des cas limités, sans garantir ces transitions.
- **Prochaine action :** écrire le contrat de sélection et de consommation, le tester après achat, variation de niveau, redémarrage, minuit et fuseau ; décider explicitement le comportement quand le pool est épuisé.
- **Responsable / lot :** IA, arbitrage propriétaire si choix de comportement, L3.

#### KT-005 — P1 — Crédits recalculés à la baisse malgré la promesse « jamais repris »

- **Preuve :** `store.dart:753–758` calcule gains depuis niveau et bonus actuels, soustrait les achats et borne à zéro. `deleteWodResult` et `clearSession` retirent l'activité (`1654–1657,2747–2749`). `progression.dart:311–357` et `game.dart:705–713,789–790` reconstruisent XP et bonus à partir du journal restant ; aucun registre cumulatif de gains acquis n'est sérialisé.
- **Impact :** effacer des performances peut réduire les gains alors que les achats restent présents ; un écart « dépensé > gagné » est caché par `max(0, ...)`. L'accès acheté n'est pas supprimé par cette formule, mais le solde ne suit pas la promesse du README et de `REFONTE_UI.md`.
- **Prochaine action :** fixer le contrat de correction/suppression des performances et de conservation des crédits ; tests avant/après suppression/import. Toute migration comptable doit préserver les droits et éviter de créer des crédits par simple navigation. Ne pas choisir un nouveau barème pendant un correctif.
- **Responsable / lot :** propriétaire pour la règle, IA pour preuve et migration, L2 puis L3.

#### KT-006 — P1 — Calendrier commun fixé à la date du créateur

- **Preuve :** `assets/programme_v33.json.gz`, `meta.anchorMonday = 2026-07-13` ; `models.dart:242–283` ; accueil initialisé par `weekFor(now)` (`home_screen.dart:41–47`) ; rappels datés par `dateFor` (`notifications.dart:31–58`). Aucun départ utilisateur dans l'état exporté.
- **Impact :** une installation le 25 septembre 2026 s'ouvre sur la semaine calculée **11**, pas automatiquement au début. Le calendrier fixe finit le **18 avril 2027** ; après, l'accueil reste borné à 40 et les rappels du programme deviennent passés. Dates déduites du JSON et de la formule, pas d'un essai UI.
- **Prochaine action :** proposer un départ personnel et une migration séparant calendrier prévu et dates réellement effectuées. Préserver IDs, historiques, récompenses et rappels existants.
- **Responsable / lot :** propriétaire pour le parcours de départ, IA pour migration/tests, L4.

#### KT-007 — P1 — Références initiales traitées comme capacités personnelles

- **Preuve :** `store.dart:637–648` copie les valeurs embarquées dès l'installation ; `game.dart:202–271` les utilise directement pour force/endurance ; `store.dart:819` en déduit le niveau cible WOD. `main.dart:148–163` ouvre la navigation sans étape de validation du profil. Valeurs embarquées, par exemple : poids 71,5 kg, traction lestée 1RM 55 kg.
- **Impact :** suggestions de charge, fiche de personnage et recommandations reposent sur des références non confirmées par le nouvel utilisateur. Cela ne signifie pas que des séries sont automatiquement validées.
- **Prochaine action :** distinguer « référence initiale » et « valeur renseignée » ; onboarding minimal et états inconnus. Préserver les valeurs des utilisateurs existants ; validation sportive séparée du code.
- **Responsable / lot :** IA + propriétaire ; avis sportif sur le contenu, L4.

#### KT-008 — P1 — Tabata : prescription, chrono et score incompatibles

- **Preuve :** `wod_generator.dart:652–663` génère des Tabata 20 s/10 s avec score en répétitions du plus faible intervalle, mais `type: 'routine'`. `wod_models.dart:149–159` traite les routines comme un temps à minimiser. `wod_screen.dart:83–93` lance un chronomètre montant et `577–600` propose un score de temps, pas le score prescrit.
- **Impact :** le score structuré/record ne représente pas la consigne ; les phases Tabata ne sont pas pilotées par ce runner. Le champ de notes ne corrige pas le classement.
- **Prochaine action :** contrat par format, score structuré adapté et compatibilité des résultats anciens. Auditer ensuite les autres variantes du générateur sans réécrire leurs prescriptions.
- **Responsable / lot :** IA, L3b.

#### KT-009 — P1 — Saisies de séries non validées avant la coche

- **Preuve :** `session_screen.dart:1281–1293` stocke directement le texte ; `_checkSet` (`450–461`) bascule `done` sans contrôle des champs. À l'import, `store.dart:1922–1940` vérifie notamment identifiants, dates et nombre de séries, mais pas la validité numérique des chaînes de chaque série.
- **Impact :** valeurs collées invalides, répétitions négatives ou efforts hors domaine peuvent être enregistrés et la série marquée faite. Le clavier numérique seul ne valide pas le contenu. L'effet exact sur chaque statistique reste à tester.
- **Prochaine action :** validation selon le mode : kg, lest/assistance éventuelle, reps, secondes/minutes, RIR/RPE, vitesse ; états de saisie incomplets et virgule française. Ne pas imposer une interdiction globale de charge négative sans vérifier les exercices d'assistance.
- **Responsable / lot :** IA, L4b.

### B. Défauts de sécurité, de livraison ou de validation confirmés

#### KT-001 — P0 — Clé privée de signature et repli de mot de passe inclus

- **Preuve :** `signing/kalis_track.p12` existe ; inspection `keytool` réussie, entrée **PrivateKeyEntry**. `android/app/build.gradle.kts:24–30`, workflow joint (`jobs.build.env`) et `tools/verify_project.py:46–54` comportent un repli de mot de passe en clair. **Aucune valeur secrète n'est reproduite dans ce document.**
- **Propagation :** `tools/package_release.py:23–39` ne filtre pas `signing/` ni les secrets ; le README affirme conserver la signature dans le paquet. La fabrication actuelle recopie donc le problème.
- **Impact :** distribution de matériel permettant de signer. Exposition publique du dépôt/ZIP **inconnue** ; compromission effective **non établie**.
- **Prochaine action :** mettre la clé existante à l'abri, confirmer sa sauvegarde et son rôle, puis retirer les secrets du futur paquet et injecter la même identité par CI avec échec explicite si elle manque. Conserver les vérifications sans secret. Aucune génération, suppression de la seule copie ou rotation automatique.
- **Responsable / lot :** propriétaire pour sauvegarde et statut ; IA pour configuration et packaging, L1.

#### KT-010 — P1 — `targetSdk = 35` inférieur à l'exigence standard actuelle de soumission

- **Preuve locale :** `android/app/build.gradle.kts:9,20` : compilation API 36, cible API 35.
- **Source officielle consultée le 25/09/2026 :** Google Play impose API **36** aux nouvelles applications mobiles et mises à jour depuis le **31/08/2026** ; extension éventuelle jusqu'au **01/11/2026** [S1]. Aucun statut d'extension pour Kalis Track n'est connu.
- **Impact :** blocage de préparation à une soumission standard à cette date ; aucune affirmation de rejet effectif dans une console non consultée. Une application déjà publiée peut relever d'une règle distincte de disponibilité.
- **Prochaine action :** migration cible 36 et validation des changements de comportement, en vérifiant la chaîne native ; ne pas confondre `compileSdk` et `targetSdk`.
- **Responsable / lot :** IA, propriétaire pour statut console, L1b/L7.

#### KT-011 — P1 — Pipeline limité à l'APK, contrôles release incomplets

- **Preuve :** workflow joint entier : build `flutter build apk`, contrôle `apksigner verify`, publication de l'artefact APK ; aucun `flutter build appbundle`, contrôle du manifeste fusionné, test 16 Ko, installation/mise à jour ni `dart format`.
- **Point positif :** extraction, garde sur `build.gradle.kts`, `chmod +x`, lockfile imposé, analyse, Python et Flutter tests sont présents. La copie interne est identique au fichier joint.
- **Limite :** la vérification du certificat du keystore compare à un fichier fourni dans le même ZIP ; elle ne prouve pas la continuité avec un APK installé ou Play App Signing. Le `versionCode` calculé depuis l'heure vise une croissance, sans vérification du maximum déjà publié ni de toutes les branches concurrentes.
- **Prochaine action :** compléter les contrôles et les artefacts APK/AAB, comparer avec la signature de référence indépendante, connaître le dernier `versionCode`, conserver un seul contenu de workflow recopié aux deux emplacements.
- **Responsable / lot :** IA + propriétaire pour les références installées/publiées, L1b puis L7.

#### KT-012 — P2 — Tests de parcours agrandis au lieu de prouver le défilement mobile

- **Preuve :** `test/wod_store_test.dart:213–227` utilise **390 × 1800** pour trouver la vitrine ; `test/reward_flow_test.dart:44–49` définit **390 × 1600**, utilisé notamment ligne 195. L'audit embarqué 2.5.0 décrit cet agrandissement pour le test boutique.
- **Impact :** ces tests ne prouvent pas que toutes les actions restent accessibles sur un téléphone de hauteur courante. Cela ne démontre pas à lui seul un débordement dans l'application.
- **Point positif :** le test WOD `306–320` vérifie aussi l'absence d'exception à 320 × 720 et 130 %, mais ne parcourt pas toutes les actions. Le test récompense garde des assertions de chronologie ; attendre deux frames n'est pas, à lui seul, un contournement.
- **Prochaine action :** dimensions téléphone réalistes, défilement réel jusqu'aux actions, texte 130 % puis 200 %, assertions conservées. Rejouer les deux fichiers prioritaires et la suite complète.
- **Responsable / lot :** IA, L1b puis L5.

### C. Risques à vérifier — incidents non reproduits

| ID / gravité | Fichiers et preuve ou indice | Risque, prochaine action et responsable |
| --- | --- | --- |
| **KT-013 / P1** — Persistance, import concurrent et arrêt brutal | `store.dart:2000–2053,2714–2743` ; `main.dart:219–228`. Écritures normales en file ; import fait une écriture directe après attente de la file, sans y inscrire sa transaction ; timer de logs annulé ; pas de sauvegarde précédente distincte du document v3. Le plugin 2.5.3 ne garantit pas la durabilité disque au retour d'un appel [S2]. | Tester deux imports, import pendant édition/flush, écriture refusée puis redémarrage et mort du processus. Vérifier que le rollback conserve aussi les changements non encore écrits. Le store valide l'import avant application, point positif, mais l'atomicité et la durabilité globales restent non démontrées. **IA, L2.** |
| **KT-014 / P1** — Migration ancienne pouvant retirer des droits offerts | `store.dart:703–707` supprime les entrées de coût zéro si `credits_v < 2` ; la branche v3 retourne auparavant (`655–660`). Le test de migration `store_test.dart:160–178` utilise un achat de coût 1 et `credits_v:2`. | Comportement de suppression confirmé pour ce format ; population réellement touchée inconnue. Construire une fixture avec droits anciens gratuits ; arbitrer la contradiction avec « droits acquis préservés », sans réintroduire la création libre de WOD. **IA + propriétaire, L2.** |
| **KT-015 / P1** — Import très volumineux ou décompression excessive | `_unpack` (`store.dart:1602–1605`) décode gzip sans plafond ; `_parseBackup` (`1777–1963`) limite certains éléments, sans limite globale avant décompression/JSON ; dialogue `settings_screen.dart:350–377`. | Blocage mémoire/interface possible avec une sauvegarde anormale. Tester des fixtures bornées, fixer limites d'entrée, de sortie décompressée et de nombre total d'objets ; préserver les données en cas de rejet. Aucune attaque ou panne mémoire exécutée ici. **IA, L2.** |
| **KT-016 / P1** — Sauvegarde système et information sur les données | Manifeste principal : ni `allowBackup`, ni règles `fullBackupContent`/`dataExtractionRules` ; `settings_screen.dart:173–219` n'offre que presse-papiers et À propos sommaire. Aucune politique de confidentialité trouvée. | Android inclut par défaut les préférences dans Auto Backup lorsque les conditions s'appliquent [S3] ; transmission effective non observée. Décider la politique cloud/transfert local, inspecter le manifeste fusionné, tester restauration ; cartographier les dépendances avant Data Safety. Qualification RGPD/données de santé à examiner selon traitements réels. **Propriétaire + IA, validation spécialisée si nécessaire, L2/L7.** |
| **KT-017 / P1** — Droits des contenus non établis par le ZIP | `wod_models.dart`, mentions `source` notamment lignes 193,205,214,229,246,530,549 ; assets programme/base/images/sons. Aucun fichier de licence ou autorisation identifié dans le paquet. | Sources relevées : `onlinewod`, `caliwodfr`, `calisthenicsworkouts`, `david_invictusphysicalcoaching`, `fitnessinbox`, `entrainement_high_rox`, `ironboundtribe`. Attribution ne prouve pas autorisation. Rassembler provenance et droits du code, programme, base, WOD et médias ; ne pas supprimer/remplacer sans décision. **Propriétaire, spécialiste si besoin ; inventaire IA, L7.** |
| **KT-018 / P1** — Chronos/notifications après suspension ou destruction | `timers.dart:8–161,166–310`, `wod_screen.dart:48–68`, `session_screen.dart:38–59` : chronos en mémoire, sans session chrono dans `_backupJson`. `notifications.dart:174–185,337–397` : repli approximatif et traitement d'erreurs existants. | La reprise du compteur après destruction n'est pas implémentée dans les champs persistés inspectés ; scénario appareil non testé. Définir ce qui doit être repris, distinguer suspension et mort du processus ; tester permissions, fuseau, heure, redémarrage, son/vibration et wakelock. **IA + propriétaire pour la règle de reprise, L4b.** |
| **KT-019 / P1** — Compatibilité native et pages mémoire 16 Ko non vérifiées | `pubspec.lock`, Gradle/settings, `ndkVersion = flutter.ndkVersion`, workflow ; aucun APK/AAB disponible. | Build de la combinaison verrouillée, minimum Android effectif des plugins, ABIs, alignement ELF/ZIP, installation sur appareils ciblés et exigences 16 Ko à vérifier. Ni ancien numéro Flutter ni `compileSdk 36` ne suffisent à conclure. **IA/CI puis propriétaire sur appareil, L1b/L7.** |
| **KT-020 / P2** — Accessibilité et mise en page à confirmer | `nav_bar.dart:89–98` utilise `FittedBox(scaleDown)` pour réduire le libellé ; `ui.dart`, thème, écran de séance ; tests partiels. | Vérifier texte 200 %, 320 px, clavier et gestes, contrastes réellement mesurés, TalkBack, cibles tactiles et annonces de chronos. La réduction de texte entre en tension avec le cahier des charges ; aucune capture/régression visuelle affirmée ici. **IA puis propriétaire, L5.** |

### D. Propositions d'amélioration — pas des bugs démontrés

| ID / priorité | Constat et proposition | Limites, responsable et lot |
| --- | --- | --- |
| **KT-021 / P2** — Maîtrise des sauvegardes | `settings_screen.dart:173–213,314–379` propose un export collé et avertit déjà du remplacement. Ajouter export/import par fichier, aperçu, sauvegarde avant remplacement et suppression locale confirmée. | Choisir le parcours et les dépendances utiles ; distinguer données locales, fichiers exportés et backups système. **Propriétaire + IA, L2b.** |
| **KT-022 / P2** — À propos fiable | `settings_screen.dart:10,214–219` duplique la version en constante et n'affiche ni support, ni accès aux licences/politique. | Source fiable de version/build, contact et identité réels, licences et URL publique à fournir. Ne pas inventer de coordonnées. **Propriétaire + IA, L7.** |
| **KT-023 / P3** — Optimisation mesurée et découpage progressif | `store.dart:1736–1771,2039–2042` sérialise l'état et compare les définitions WOD lors des snapshots ; `nav_bar.dart:56–57` emploie un flou. Le store fait 2 843 lignes. | Mesurer d'abord sur jeux de données représentatifs et appareil profile/release, puis modifier les seuls points coûteux. Pas de changement de framework ni de migration de stockage par réflexe. **IA, L6.** |

## 4. Signature, sauvegardes et données : décisions avant la finition visuelle

Ces questions préparent les lots suivants ; elles ne conditionnent pas la livraison de cet audit.

### Signature — informations à fournir par le propriétaire

1. L'application a-t-elle été publiée sur Google Play ? Play App Signing est-il activé ? La clé incluse sert-elle de clé d'envoi ou de clé de signature des installations directes ?
2. Existe-t-il une copie de la clé et de ses moyens d'accès conservée séparément ? **Ne pas envoyer de mot de passe en clair dans le suivi.** Confirmer son existence avant de retirer la clé des prochaines archives distribuables.
3. Le ZIP ou le dépôt contenant la clé ont-ils été publics ou partagés ? L'audit ne peut pas déduire ce statut de la présence locale du fichier.
4. Quel est le dernier APK réellement installé et son certificat ? Quel est le plus grand `versionCode` déjà diffusé ? Pour la prochaine passe de continuité, fournir l'APK de référence si possible, sans désinstaller l'application du téléphone.

**Certificat local contrôlé :** empreinte SHA-256 `9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`, correspondant au fichier `signing/certificate.sha256`. Ce certificat public peut servir de repère, pas de preuve du certificat des installations externes. Aucune clé privée n'a été extraite, générée, tournée ou supprimée.

Les noms de secrets déjà utilisés par la CI sont `KALIS_KEYSTORE_BASE64` et `KALIS_KEYSTORE_PASSWORD` ; `KEYSTORE_PASSWORD` est la variable transmise aux outils. Leur présence/configuration dans le dépôt réel n'a pas été vérifiée. La future CI devra les exiger pour la release, sans repli ni génération automatique ; les tests sans signature doivent rester possibles.

### Sauvegarde — plan de conservation proposé

- Avant toute migration, disposer d'un export réel et de fixtures anonymisées : utilisateur neuf, journal rempli, séances personnelles répétées, achats/remises, wishlist, anciens formats et état dégradé. Préserver aussi la sauvegarde brute en cas d'initialisation en erreur.
- Inventorier puis comparer avant/après : références, IDs et dates de séances, séries/notes, occurrences personnelles, résultats et prescriptions WOD, prix payés, accès acquis, wishlist, réglages et dernier niveau vu.
- À l'import, valider intégralement avant remplacement, borner les tailles, sérialiser la transaction avec les autres écritures et tester les erreurs. Garder une possibilité de récupération qui n'écrase pas l'original corrompu.
- Décider si la correction d'une performance retire de l'XP et/ou des crédits, tout en préservant les droits achetés. Ne pas confondre correction d'historique et nouvel équilibrage.
- Décider le traitement des accès historiques gratuits et le départ personnel du programme avant d'écrire une migration.
- Définir la politique Android : cloud, transfert de téléphone et restauration. La désinstallation n'est ni un protocole de mise à jour ni une preuve de suppression de toutes les sauvegardes externes.

### Carte initiale des données

| Données | Stockage/traitement observé | Point à préserver ou clarifier |
| --- | --- | --- |
| Poids, 1RM, maxima reps, références de charge | `values` dans l'état local et l'export ; calcul des charges et attributs | Valeurs utilisateur vs defaults ; pas d'interprétation médicale automatique |
| Séries, charge, effort, vitesse, notes, dates | `logs` ; historique, progression et estimations | Dates réelles, contenu libre des notes, corrections explicites |
| Exercices/séances personnels | `userExercises`, `custom`, journaux archivés | Noms/IDs et anciennes occurrences indépendantes du modèle courant |
| Résultats WOD, prescription et notes | Catalogue/résultats dans l'état ; records/XP dérivés | Format de score et compatibilité des résultats anciens |
| Droits WOD et envies | `unlocked` avec coût payé ; `wishlist` | Aucun débit non financé ; conservation des acquis |
| Réglages et dernier niveau vu | État local/export | Effet réel, continuité des permissions/canaux Android |
| Exports et récupération | Presse-papiers normal ; copie brute des préférences en écran d'erreur (`main.dart:105–114`) | Le format brut de secours n'est pas l'export habituel importable tel quel ; documenter la récupération |
| Sauvegarde système | Politique implicite du manifeste source | Confirmer contenu final et comportement appareil avant les déclarations de confidentialité |
| Dépendances | Plugins natifs ; présence transitive de `http` dans le lockfile ; aucune API distante appelée repérée dans les routes inspectées | Ne pas déduire une collecte du seul package `http`, ni l'absence de transmission de l'absence de compte ; auditer les dépendances et le manifeste final |

## 5. Lots proposés, limités et ordonnés

Chaque sous-lot doit être livrable et vérifiable séparément. Les validations visuelles significatives arrivent **après** les décisions et protections de signature/données. Tous les lots ci-dessous sont proposés, pas démarrés.

| Ordre / lot | Périmètre limité | Entrée nécessaire | Critère de sortie |
| --- | --- | --- | --- |
| **L0 — Référence** | Audit actuel, empreintes, tests disponibles, suivi | ZIP joint | **Terminé pour cette passe** ; aucun changement applicatif |
| **L1 — Signature et ZIP** | KT-001 : Gradle, vérificateur, packaging, copie du workflow ; pas de changement UI ou métier | Sauvegarde de la clé confirmée, rôle de signature identifié | Aucun secret dans le futur ZIP ; même certificat attendu ; release sans secrets échoue clairement ; tests Python non signés utilisables ; archive ≤ 25 000 000 octets |
| **L1b — Validation et cible Android** | KT-010/011/012/019 : gates CI, cible 36 et compatibilité, tests prioritaires à taille mobile ; séparer chaque correction révélée | Exécuteur Flutter/Android disponible ; APK/versionCode de référence pour continuité | Analyse et tests sur le code livré ; APK/AAB réellement construits ; signature et manifeste inspectés ; chaque échec restant documenté |
| **L2 — Sauvegarde et achats** | KT-002/013/014/015 : écritures, import/migration, erreurs, bornes, fixtures ; contrat KT-005 | Export de secours et arbitrages sur acquis | Import invalide sans mutation ; aucune confirmation d'achat avant résultat ; essais d'échec/reprise ; conservation des données et droits démontrée |
| **L2b — Contrôle utilisateur des données** | KT-016/021 : sauvegarde par fichier, aperçu/remplacement, suppression locale et politique Android | Choix de sauvegarde système ; parcours approuvé si changement important | Aller-retour de sauvegarde, confirmation de remplacement, suppression au périmètre honnête ; restauration système testée |
| **L3 — Économie et essai WOD** | KT-003/004/005 : unicité, jour/semaine/fuseau, droit de finir, stabilité, comptabilité retenue | Persistance fiabilisée et règles tranchées | Achat normal/insuffisant/doublé ; essai terminé/acheté/redémarré ; minuit ; suppression/import ; aucun acquis perdu |
| **L3b — Formats WOD** | KT-008 : Tabata d'abord, puis inventaire précis des autres formats ; scores/records | Contrat de chaque format et compatibilité des scores | Chrono et score concordent avec prescription ; anciens résultats conservés et interprétés explicitement |
| **L4 — Départ du programme** | KT-006/007 : départ personnel et références confirmées ; migration isolée | Choix propriétaire sur onboarding/calendrier | Nouveau venu commence correctement ; ancien calendrier et historique conservés ; rappels/XP cohérents ; contenu 40 semaines inchangé |
| **L4b — Séances et reprise** | KT-009/018 : saisie, chronos, fin/bilan, historique, notifications et destruction de processus | Règle de reprise définie | Scénarios programme/perso/rappel complets, validation numérique, historique non modifié, aucun double résultat/récompense |
| **L5 — Finition visuelle** | KT-012/020, écran par écran, composants existants | Données/signature stabilisées ; proposition validée pour changements importants | Captures réellement rendues clair/sombre ; 320 px, 130/200 %, clavier, TalkBack ; validation propriétaire distincte des tests |
| **L6 — Performance** | KT-023, un coût mesuré à la fois | Mesures de référence sur appareil et jeux de données | Avant/après reproductible, aucun gain inventé, aucune régression fonctionnelle |
| **L7 — Candidate et publication préparée** | KT-010/011/016/017/019/022 : Android, signatures/MAJ, licences, politique, Data Safety, informations éditeur | Droits, coordonnées, URL publique, compte/store identifiés | Checklist de publication documentée ; APK/AAB validés ; limites/blocages ouverts visibles ; aucune publication automatique |

Un défaut technique local pourra être corrigé dans son lot après autorisation de modification. Une migration, une nouvelle règle économique, un retrait de contenu ou une refonte importante conserve son arbitrage explicite. Le périmètre de cette passe reste L0.

## 6. Décisions à préserver

1. **Source unique et échange de ZIP.** Toujours relever nom, taille, SHA-256 et version de la base reçue. Jamais de reprise silencieuse d'une ancienne archive. Aucun dépôt externe n'est adopté comme nouvelle référence.
2. **Identité Android et signature.** Conserver `fr.tchoupi.streetlift_tracker` et la continuité des installations ; retirer les secrets du paquet seulement avec procédure de conservation de la clé. Pas de désinstallation pour mettre à jour.
3. **Contenu métier.** Conserver 40 semaines, 280 jours, 1 954 entrées, 505 exercices, formules et identifiants. Les estimations et programmes ne sont pas une certification de santé ou de niveau physique.
4. **Données.** Aucun reset silencieux, perte d'historique, de séance personnelle, de résultat, de droit WOD ou de réglage. Toute modification de schéma est versionnée et migrée avec fixtures.
5. **Économie.** Pas de changement arbitraire d'XP/niveaux/crédits/prix. Barème actuel : `1 + 2 × niveau + 3 × floor(niveau/5)` ; bonus actuels chapitre +3, boss +5, semaine complète +1 ; prix catalogue de base 1 à 4, remises avec plancher 1. L'incohérence KT-005 exige une décision, pas une retouche discrète du barème.
6. **WOD.** Acquis avec crédits ; essai temporaire comme exception. Pas de création libre de WOD ajoutée. Les séances personnelles et contenus anciens restent compatibles.
7. **Fonctionnement local.** Pas de paiement, abonnement, publicité, compte obligatoire, cloud applicatif ou analytics ajoutés sans validation. La sauvegarde Android est un sujet distinct.
8. **Navigation et identité visuelle.** ARSENAL, STATS, PROGRAMME, RÉGLAGES ; suivi/pilotage/progression regroupés dans STATS. Bordeaux `#6B0C0C`, rouge d'action `#A61717`, anthracites `#121212/#1E1E1E`, thèmes clair/sombre/système. *Évolution du 26/09/2026 (L5, 3.0.2) : ce rouge reste la couleur dominante par défaut ; chaque utilisateur peut en choisir une parmi six (rouge, jaune, vert, violet, orange, turquoise ; le bleu, d'abord prévu, a été remplacé par le jaune le même jour), indépendamment du thème clair/sombre/système.*
9. **Choix visuels du cahier des charges.** Titres principaux en majuscules ; marque K sans fond dans les transitions prévues ; indicateur de niveau sans contour ni dégradé, progression à séparation nette ; ne pas réintroduire AVANT/ARRIÈRE. Cette contrainte de dégradé ne s'étend pas automatiquement aux couvertures WOD.
10. **Validation honnête.** Tests à dimensions réalistes, sans retirer d'assertions pour obtenir du vert. Ancien rapport, analyse statique, build, test automatique et essai appareil restent des preuves différentes.

## 7. Tests et contrôles exécutés pendant cette passe

Les commandes suivantes ont donné un résultat réel. Les tests du projet ont été exécutés depuis `streetlift_tracker/`, avec `PYTHONDONTWRITEBYTECODE=1` pour ne pas ajouter de cache au code extrait.

| Contrôle | Résultat réel | Portée |
| --- | --- | --- |
| Python `hashlib.sha256` et `ZipFile.testzip()` sur le ZIP reçu | Succès ; empreinte et taille en section 1 ; `testzip()` renvoie `None` | Intégrité de l'archive, pas fonctionnement de l'app |
| Extraction contrôlée | 272 fichiers extraits | Lecture réelle de la source jointe |
| Copie/édition/réarchivage jetable | Succès, fichier relu identique au contenu modifié | Capacité technique à préparer un futur ZIP |
| Réarchivage complet et comparaison fichier par fichier | 272/272 empreintes identiques ; CRC valide | Capacité à réemballer le projet sans perdre de fichier |
| `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/tests -v` | **Code de sortie 0 ; 4 tests réussis ; 0,027 s** | Arrondi type Excel, parsing des repos, compression reproductible, assets et identité Android |
| `PYTHONDONTWRITEBYTECODE=1 python3 tools/verify_project.py --signing` | **Code de sortie 0** : 40 semaines, 280 jours, 1 954 exercices programme, 505 base ; comparaison certificat réussie | Assets/XML et identité locale ; pas une compilation ni une comparaison à un APK installé |
| `keytool -list` sur l'alias existant, mot de passe fourni par variable temporaire | **Code de sortie 0 ; PrivateKeyEntry présente** | Confirme le matériel privé dans le keystore ; aucune clé extraite |
| `java -version`, Python et recherche d'outils | Versions/disponibilités en section 1 | État de l'environnement |
| Comparaison du workflow interne et joint | Identiques octet par octet | Aucune divergence actuelle |
| Comparaison finale des 272 fichiers source avec le manifeste initial | **0 modification** | Respect du périmètre audit uniquement |

Sortie de la suite Python exécutée :

```text
test_pack_is_reproducible_and_preserves_sources ... ok
test_rest_ranges_and_mixed_units ... ok
test_rounding_matches_excel_half_away_from_zero ... ok
test_shipped_assets_and_android_identity ... ok
Ran 4 tests in 0.027s
OK
```

Le test de compression écrit seulement dans son répertoire temporaire. Les 4 tests réussis ne constituent pas une validation des parcours Flutter. Les rapports `validation/2.5.0/` ont aussi été lus, mais leurs résultats historiques n'ont pas été additionnés aux tests exécutés ici.

## 8. Tests restant à faire

### Commandes non exécutées ici

| Commande/contrôle prévu | Statut et prérequis |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Non exécuté : Dart absent |
| `flutter pub get --enforce-lockfile` | Non exécuté : Flutter absent ; aucun nouveau lockfile produit |
| `flutter analyze --no-pub` | Non exécuté : Flutter absent |
| `TZ=Europe/Paris flutter test --no-pub --timeout 60s --reporter expanded` | Non exécuté : Flutter absent ; totalité de la suite à reprendre |
| Tests ciblés `reward_flow_test.dart`, `wod_store_test.dart`, `store_test.dart`, `notifications_test.dart`, `timers_test.dart` | Lus partiellement/inventoriés, pas exécutés ; ajouter les régressions des constats de cet audit dans les lots concernés |
| `flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart` | Non exécuté ; aucune capture créée ; le test visuel est optionnel dans le projet |
| Tests d'intégration sur appareil | Aucun dossier `integration_test/` dans la source ; protocole à créer |
| `flutter build apk --release --no-pub --build-number=<code_validé>` | Non exécuté : Flutter/Android absents ; secrets et code de version à sécuriser |
| `flutter build appbundle --release --no-pub --build-number=<même_code_validé>` | Non exécuté ; étape absente du workflow actuel |
| Vérifier APK/AAB, manifeste fusionné, certificat attendu, ABIs et 16 Ko | Non exécuté : aucun artefact construit disponible |
| Installation vierge et mise à jour sans désinstallation | Non exécuté : appareil et APK de référence requis |

Les emplacements `<...>` sont des paramètres à renseigner, pas des commandes prêtes à copier telles quelles. La future CI n'a pas été modifiée dans cet audit.

### Matrice de scénarios prioritaires

| Scénario | Preuve attendue | Responsable / lot |
| --- | --- | --- |
| Installation neuve hors date d'origine | Départ et références compris ; pas de performance supposée | IA + propriétaire, L4 |
| Mise à jour avec données existantes | Même application/signature ; comparaison des données avant/après ; zéro désinstallation | IA/CI + propriétaire, L1/L2/L7 |
| Export/import formats 1/2/3, sauvegarde corrompue/tronquée/volumineuse | Conservation de l'original, erreurs compréhensibles, reprise possible | IA, L2 |
| Échec d'écriture, double import, import pendant flush, processus tué | Aucun succès mensonger ; état cohérent au redémarrage | IA + appareil, L2 |
| Séance programme et perso complète | Saisie → repos/pause → reprise → bilan → récompenses → historique exact | IA + propriétaire, L4b |
| Historique en lecture seule | Consultation ne modifie ni champs, ni dates, ni récompenses | IA, L4b |
| Notification à froid/à chaud/journée faite | Bonne séance ou historique ; bilan et récompense une seule fois | IA + appareil, L4b |
| Achats normal, insuffisant, double appui, écriture refusée | Prix payé figé, aucun double débit, conservation après redémarrage | IA, L2/L3 |
| Essai du jour terminé puis acheté ; redémarrage ; minuit et fuseau | Contrat d'unicité respecté ; résultat d'une tentative engagée conservé | IA, L3 |
| Suppression/correction/import d'activité | Solde et droits cohérents avec la règle explicitement choisie | IA + propriétaire, L3 |
| For Time, AMRAP, EMOM, tours, routines, Tabata et variantes | Score et record compatibles avec les consignes ; migration des anciens scores | IA + validation sportive du contenu, L3b |
| Fin des 40 semaines | Navigation, rappels et progression sans date fictive ni perte de journal | IA, L4 |
| Sons/vibration/wakelock/permissions refusées | Effet des options, repli, pas de doublons ; essais appareil | IA + propriétaire, L4b |
| 320 px, 130/200 %, clavier et TalkBack | Actions atteintes par défilement ; pas de masquage par réduction artificielle ; contrastes mesurés | IA + propriétaire, L5 |
| Performance avec historique long et catalogue complet | Appareil/OS/données/protocole documentés ; mesures profile/release avant/après | IA, L6 |

### Checklist de validation visuelle par parcours

Toutes les lignes sont **à rendre et à valider** : la lecture du code n'est pas une validation visuelle du propriétaire.

- [ ] Démarrage et écran de récupération.
- [ ] Navigation principale et clavier ouvert.
- [ ] Programme : semaine, jour, consignes et fin du programme.
- [ ] Séance : chaque mode, saisies, chronos, bilan et récompenses.
- [ ] Historique de séance programme et personnelle.
- [ ] Arsenal : vide/rempli, création/édition/duplication de séance.
- [ ] Boutique : catalogue, recherche, filtres, vitrine, envies et crédits.
- [ ] Fiche WOD : verrouillé, insuffisant, acheté, essai et remise.
- [ ] Runner WOD, score, résultats et records par format.
- [ ] STATS : Aperçu, Parcours, Performances, Historique et références.
- [ ] Réglages : chaque section, permissions, export/import et À propos.

## 9. Préparation de publication encore ouverte

- **Technique :** traiter KT-001/010/011/019, valider les binaires réellement produits et la mise à jour, contrôler le manifeste final et les permissions. Le besoin de `SCHEDULE_EXACT_ALARM` reste à justifier pour ce produit ; le repli approximatif existe déjà.
- **Données :** trancher sauvegarde/effacement/restauration, vérifier flux effectifs et dépendances, préparer politique et déclarations cohérentes. La politique de confidentialité, Data Safety et déclaration des fonctionnalités santé/fitness ne sont pas rédigées/validées dans cette passe.
- **Éditeur :** identité, contact de support, URL publique de confidentialité, type/date du compte développeur et statut de publication à fournir. Aucun texte légal fictif ni lien factice.
- **Droits et sport :** autorisations des contenus et médias, licences des dépendances ; validation compétente des prescriptions si nécessaire. Aucune conclusion juridique ou sportive exhaustive.
- **Distribution :** statut Play App Signing, piste d'essai, exigences de test du compte et dernière version diffusée inconnus. Aucune publication ni dépense effectuée.

### Sources externes limitées à l'appui de cet audit

Consultation : **25 septembre 2026**. Elles complètent les constats du ZIP et ne fournissent aucune autre base de code.

- **[S1] Google Play, Target API level requirements** — [page officielle](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en). Exigence API 36 depuis le 31 août 2026 pour nouvelles applications mobiles/mises à jour ; extension éventuelle à vérifier dans la console concernée. Ne démontre pas le statut de Kalis Track.
- **[S2] Flutter, documentation de `shared_preferences` 2.5.3** — [version verrouillée](https://pub.dev/packages/shared_preferences/versions/2.5.3). La documentation prévient que le retour d'un appel n'assure pas la persistance disque des données critiques. Justifie des tests de durabilité, pas une migration automatique vers un autre stockage.
- **[S3] Android Developers, Auto Backup** — [documentation officielle](https://developer.android.com/identity/data/autobackup). Préférences incluses par défaut, `allowBackup` vrai par défaut ; comportement conditionné par système/réglages et particularités de transfert entre appareils. La sauvegarde effective de Kalis Track n'a pas été observée.

## 10. Journal de cette passe et protocole ZIP

| Élément | État |
| --- | --- |
| Code, tests, assets, dépendances et workflow modifiés | **Aucun** |
| Livrable créé | **`SUIVI_PROJET.md`** |
| Correctifs appliqués | **Aucun : audit uniquement** |
| Tests automatiques applicatifs | **4 tests Python réussis ; Dart/Flutter non exécutés** |
| Build APK / AAB | **Non exécuté** |
| Vérification sur appareil | **Aucune** |
| Validation de publication | **Non obtenue** |

Pour chaque prochaine passe : joindre le ZIP retenu et ce suivi ; annoncer le ou les sous-lots autorisés ; contrôler l'empreinte d'entrée ; livrer le projet complet sous `streetlift_tracker/`, sans caches/binaires/secrets, dans la limite de 25 000 000 octets ; mettre à jour ce document et la liste précise des fichiers changés. Livrer le workflow associé sans divergence si modifié. Fournir les binaires uniquement lorsqu'ils ont réellement été compilés et contrôlés.

Les tickets conservent leur ID et passent distinctement par **ouvert → corrigé dans le code → testé automatiquement → vérifié sur appareil**, avec preuves et limites. Une validation visuelle ou de publication du propriétaire n'est jamais déduite d'un test automatisé.
