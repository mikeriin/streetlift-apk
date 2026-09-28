# Décisions — pipeline mannequin 3D

## Tranchées par le propriétaire (27/09/2026)
Voir `PIPELINE_3D.md` §2 (réponses 1a à 17a). Réglages d'affichage 3D activés par défaut : « Nom du muscle au toucher », « Os visibles ».
Modèle Claude : Opus 5.5 pour tous les lots, effort accru demandé sur M5 (squelette) et M12 (figures).
28/09/2026 : lot M4b ajouté après M4 (tous les muscles remis dans le modèle, transparence à 50 % pour voir les muscles sollicités cachés, filtres en menu déroulant à cocher qui se superposent, petite refonte de l'écran Anatomie). M5 prend 5.3.1 pour prérequis.

## Décisions prises par défaut par les lots
(chaque lot ajoute sa section : décision, raison, réversibilité)

### M1 (27/09/2026) — socle 3D (livré, 5.0.0)
- Flutter 3.47.5 (Dart 3.13.4, dernière stable), flutter_scene 0.23.0. Réversible (version épinglée).
- minSdk 21 → 24 : Flutter 3.47 refuse < 23 et vise 24 (conséquence directe de la décision « Flutter ≥ 3.47 ») ; Android 5 et 6 ne reçoivent plus de mise à jour. `verify_android_artifacts.py` attend désormais 24.
- Gradle 8.13 → 8.14.3, Kotlin 2.2.10 → 2.3.20 (minimums de Flutter 3.47), AGP 8.12.1 gardé (AGP 9 imposerait la nouvelle DSL) ; `android.newDsl=false`, `android.builtInKotlin=false` ajoutés par le migrateur Flutter. Identifiant et signature inchangés.
- Dépendances : versions majeures conservées, verrou régénéré. Dépréciations 3.47 migrées sans changement de comportement (RadioGroup, initialValue, onReorderItem, TickerMode.getValuesNotifier, isSemantics).
- flutter_scene 0.23 : basculer `autoTick` sur une `SceneView` montée provoque une erreur (un seul ticker par vue). L'écran Moteur 3D garde un rendu continu ; les lots à scène fixe devront monter une vue dédiée (ou changer de `key`) pour passer en rendu à la demande.
- Fond de scène dessiné dans la scène (ciel uni) : sur fond transparent le halo disparaît. Mappage des tons « linéaire » pour garder les couleurs de la charte ; halo seulement en thème sombre (en clair, le fond dépasserait le seuil du halo).
- CI : émulateur API 35 x86_64 `-gpu swangle_indirect` (OpenGL ES). Flutter GPU y fonctionne (« Compatible », rendu vérifié), mais le rendu logiciel est très lent (≈ 1 image/s) : les images/s de la CI ne représentent pas un téléphone.
- `test/visual_capture_test.dart` (captures facultatives) échoue déjà sur main avant M1 (onglet STATS réorganisé depuis 2.5.0) : non corrigé, hors lot.

- `integration_test` hors du `pubspec.yaml` livré : Flutter 3.47 le référençait dans le registre des plugins de l'APK release (build signé n° 95 en échec). La CI 3D l'ajoute dans sa copie de travail ; `integration_test/` et `test_driver/` exclus de l'analyse principale (comme `tools/perf_device/`). La CI 3D construit aussi un APK profile (même jeu de plugins que la release).
- Bibliothèques natives compressées dans l'APK (`useLegacyPackaging = true`) : avec minSdk 24, AGP les rangeait non compressées (APK universel 73,5 Mo). APK signé 5.0.0 : 35,0 Mo (4.3.1 : 30,3 Mo), +4,7 Mo, dans l'objectif ≤ 10 Mo.
- Blocage CI du 27/09 (quota Actions) levé par le propriétaire : dépôt rendu public.
- CI 3D : `FLUTTER_BEFORE` = version Flutter du ZIP de main (3.47.5 désormais) pour les rendus de référence.

- Réponse du propriétaire (27/09/2026) : téléphone **compatible, 120 images/s** sur l'écran Moteur 3D → pipeline relancé (M2).

### M2 (27/09/2026) — modèle anatomique d'exécution et écran Anatomie (5.1.0)
- Source : slfresh/fitmitwith-anatomy-atlas, commit 4120ee6, `full-body-male-mobile.glb` (SHA-256 d80bebc4…) et `full-body-map.json` (d1221ef4…), copiés dans `tools/anatomy/source/` avec ATTRIBUTION.txt et les licences. Blender 5.0.1 (bpy, Python 3.11) : l'API utilisée est celle de 4.x. Réversible.
- Muscles profonds retirés selon une mesure, pas une liste a priori : rayons orthographiques depuis 58 directions (pas 5 mm) ; une paire gauche/droite est retirée si aucun des deux côtés n'est touché par 40 rayons. 21 muscles × 2 côtés retirés (liste dans `muscles_map.json`, clé `retirees`). Même règle pour les pièces d'os et de contexte invisibles. Seuil réglable (`VISIBLE_MIN_RAYS`).
- Aponévrose des obliques : au lieu de supprimer ses triangles (bord en dents de scie et trous visibles à l'essai), ses sommets situés devant le droit de l'abdomen passent derrière lui (fondu de 15 mm) ; même rendu que la page de référence, nappe continue.
- Tête, mains, pieds : volumes sombres lisses (remaillage voxel, fermeture morphologique, lissage), même encombrement ; tendons des muscles de l'avant-bras et de la jambe coupés au poignet (z 0,855 m) et à la cheville (z 0,085 m), leur partie distale fondue dans le volume. Mains et pieds sélectionnables (« Muscles de la main / du pied », groupes avant-bras / mollets du pack). Platysma (masquait le sterno-cléido-mastoïdien) et bandelette ilio-tibiale (masquée par défaut sur la page de référence) retirés.
- Budget : 56 126 triangles (muscles 40 758, os 7 000, contexte 2 968, tête 2 600, mains et pieds 4 × 700), GLB 1,1 Mo.
- Groupes : correspondance de la page de référence, sauf quand le muscle du pack correspondant a un autre groupe dans l'application (cohérence avec la liste en texte et STATS) : grand adducteur → ischios, dentelé antérieur → pectoraux, anconé → triceps, iliaque et grand psoas → quadriceps, tenseur du fascia lata → fessiers, poplité → ischios. Muscles du cou (absents de la page) : dos, comme le sterno-cléido-mastoïdien du pack. Réversible (`tools/anatomy/anatomy_data.py`).
- Organisation retenue : (a) une maille par muscle et par côté. Mesures sur émulateur (même scène, même caméra en rotation, 12 s, build debug, rendu logiciel, 4 à 8 images par mesure) : (a) 182-183 appels de dessin, (b) maillage fusionné avec identifiant par sommet, 8 appels. Temps d'image moyen (a) / (b) : 3 256 / 3 614 ms (essai 2), 5 786 / 6 202 ms (essai 6), 6 863 / 6 967 ms (run final 36364366340) ; fil UI 41 / 12, 34 / 11, 80 / 15 ms ; GPU 1 219 / 1 299, 2 361 / 2 435, 2 741 / 2 515 ms. (a) est la plus rapide au total dans les trois mesures (écart 1 à 10 %, dans le bruit de l'émulateur), (b) allège le fil UI. (a) garde aussi le toucher et la modulation d'un muscle par un seul matériau (M7). Le matériau `.fmat` de (b) n'a donc pas été construit (mesure faite avec une couleur par sommet, même coût de dessin). À revoir si le fil UI limite sur téléphone (mesure Réglages › À propos › Moteur 3D, désormais sur le mannequin).
- Matériaux : un matériau par région, attribué avant l'ajout à la scène puis modifié en place (flutter_scene 0.23 ne voit pas le remplacement du matériau d'un nœud monté : essai 1 sans rouge). Maillages clonés par instance.
- Toucher : lancer de rayon en Dart sur les maillages copiés une fois (boîte englobante puis triangles), les os masqués exclus ; `Scene.raycast` de flutter_scene ne renvoyait rien sur le modèle converti (essai 2).
- Rendu à la demande : `SceneView(autoTick: false)`, redessin à chaque reconstruction (caméra, intensités, réglages) ; rotation continue seulement dans l'écran Moteur 3D (mesure).
- Écran Anatomie dans l'Arsenal, section « Référence » en fin de page (à côté de la bibliothèque d'exercices ; en tête, il repoussait le catalogue WOD hors de la liste construite et cassait un test existant).
- Réglages › Affichage 3D : préférences de l'appareil (SharedPreferences `kt3d_*`), hors sauvegarde : le format de sauvegarde ne change pas.
- Build hook `hook/build.dart` (flutter_scene `buildScenes`, liste explicite) ; `flutter_scene_generated/` déclaré dans le pubspec, son contenu n'est jamais livré ; dépendance directe `hooks`.
- CI 3D : la mesure des deux organisations est une seconde cible (`integration_test/mannequin_mesure_test.dart`) : lors de l'essai 1, le processus de test est mort pendant cette mesure et toutes les captures ont été perdues.

### M3 (28/09/2026) — fiche exercice : mannequin fixe (5.2.0)
- Muscles étirés : teinte bleu acier (#5B8DB0 en sombre, #346C92 en clair), intensité 0,25, sans halo ; pastille « Étiré » de la légende dans cette teinte quand le mannequin 3D est affiché (carte 2D : rampe à 0,25 comme avant). Réversible (`mannequinStretch`).
- Étiré prioritaire : dans le pack, les 25 exercices qui ont des étirés (24 de mobilité, kettlebell windmill) listent aussi ces muscles en principal ou secondaire ; en rouge, ils se liraient comme contractés et le bleu n'apparaissait jamais (essai 2 : 0 pixel bleu). Un muscle listé étiré est donc montré étiré ; une région reste rouge si un autre de ses muscles, non étiré, est sollicité. Réversible (`ExerciseMuscleMap.of`).
- Vue de départ : face de chacun des 81 muscles du pack écrite dans `muscleFaces` (antérieur, postérieur, latéral) ; principaux tous postérieurs → Dos, tous antérieurs → Face, mixtes → 3/4 ; latéraux ignorés ; sans principal orienté, les secondaires décident ; sinon 3/4. Catalogue : 341 fiches en 3/4, 151 Face, 133 Dos. La traction (grand dorsal + biceps) part en 3/4 avant, comme la règle le demande.
- 12 muscles du pack sans région, justifiés dans `musclesSansRegion` (9 profonds retirés en M2, 3 internes absents du modèle) ; nommés sous le mannequin (« Profonds, non visibles sur le mannequin : … »), toujours dans la liste en texte.
- Rotation au doigt seulement horizontale dans la fiche (`horizontalDragOnly`) : sinon le glissement vertical sur le mannequin inclinait la vue au lieu de faire défiler la page.
- Cache : modèle chargé une fois par lancement, chaque mannequin en reçoit une copie (`Node.clone`, géométrie partagée) ; mesure émulateur : création 0-1 ms, mannequin prêt dès son arrivée à l'écran, mémoire stable sur 20 fiches (460 → 459 Mo, build debug).
- Repli sans Flutter GPU : `ExerciseAtlas` historique, inchangé (paramètre `fallback` de `Mannequin3D`).
- CI 3D : cible `integration_test/fiche_exercice_test.dart` ; la mesure M2 des organisations n'est plus relancée par défaut (`CI3D_MESURE=1`).

### M4 (28/09/2026) — STATS : résumé hebdomadaire sur le mannequin (5.3.0)
- Chiffres inchangés : `AppStore.weeklyMuscles` non modifié ; la normalisation de la carte 2D (valeur / maximum de la semaine, groupes sous 2 % non colorés) est extraite telle quelle (`heatmapIntensities`, `kHeatmapMinIntensity`) et partagée par la carte et le mannequin ; comparaison chiffrée dans `test/m4_stats_mannequin_test.dart`.
- Chaque région prend l'intensité de son groupe (groupes des régions fixés en M2 ; le groupe Dos inclut les muscles du cou). Mains et pieds (volumes sombres des groupes avant-bras / mollets) restent sombres dans ce résumé : il colore des muscles, pas des extrémités. Réversible (`weeklyRegionIntensities`).
- Légende chiffrée : la carte 2D n'écrivait que les noms ; chaque groupe porte désormais sa valeur (« Dos · 16 », séries pondérées) et une ligne explique le calcul. Option `MuscleLegend(values:)`, le WOD garde sa légende d'avant.
- Bascule Face / Dos : paramètre `views` de `Mannequin3D` (défaut : les 4 vues, autres écrans inchangés). Rotation horizontale seule (page qui défile), comme la fiche.
- Performance : rendu à la demande + `RepaintBoundary` autour du mannequin, sans image figée en cache. Mesure émulateur (debug, rendu logiciel) : défilement de STATS mannequin à l'écran, fil UI médiane 2,4 ms (p90 15,5) sur 46 images ; rotation (scène redessinée) 116 ms. Le défilement ne redessine pas la scène ; l'image en cache n'apporterait rien.
- Hauteur 330 (fiche : 380) ; repli sans Flutter GPU : `MuscleHeatmap` hauteur 220, identique à 5.2.0.
- CI 3D : cible STATS lancée en premier sur l'émulateur. Essai 1 : service VM perdu pendant Moteur 3D puis émulateur injoignable jusqu'au délai du job ; essai 2 : premier lancement de chaque cible perdu (« device offline »), relance réussie pour STATS et Moteur 3D, fiche M3 perdue deux fois (infrastructure ; la fiche n'utilise pas le nouveau paramètre).

## En attente du propriétaire
(aucune)
