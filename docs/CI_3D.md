# CI 3D — méthode de contrôle du mannequin 3D (établie par M1)

Pipeline « Mannequin 3D » : chaque lot contrôle son travail avec cette CI,
sans SDK Flutter local. Moteur : flutter_scene (Flutter GPU sur Impeller).

## Déclenchement

- Workflow `.github/workflows/ci-3d.yml` (copie dans ce ZIP ; l'original est
  à la racine de la branche `claude/ci-3d`).
- Déclenché **uniquement** par un push sur `claude/ci-3d` (jamais
  `claude/ci-tools`). Cette branche porte le ZIP à tester et `ci-3d.yml`,
  **sans** `build-apk.yml` (pas de build signé sur la branche de test).
- Les résultats sont recommités par la CI dans `ci-out/` sur `claude/ci-3d`
  (commit « CI 3D : résultats du run … ») : `git fetch origin claude/ci-3d`
  puis lire les fichiers. Rien à télécharger.

## Tâches

| Tâche | Contenu | Résultats dans `ci-out/` |
| --- | --- | --- |
| `checks` | Flutter 3.47.5 : `pub get` (verrou régénéré s'il est périmé), formatage, analyse, tests Python + `verify_project.py` + `package_release.py --check`, suite Dart complète, rendus de test (`KALIS_CAPTURE`), build debug | `checks.txt` (bilan), `pubspec.lock`, `pub-lock.txt`, `format.patch` (si formatage à corriger), `analyze.log`, `python-tests.log`, `flutter-tests.log`, `build-debug.log`, `flutter-version.txt` |
| `before` | Mêmes rendus de test sur le ZIP de `main` (version Flutter de main, `FLUTTER_BEFORE`, à ajuster si un lot change de version) | comparés dans `captures-comparaison.txt` ; paires différentes dans `captures/` (`avant_*` / `apres_*`) |
| `emulator` | Émulateur Android API 35 x86_64 (pixel_7), `-gpu swangle_indirect` (OpenGL ES via ANGLE sur SwiftShader Vulkan, build d'émulateur 13823996 comme la CI de flutter_scene), `flutter drive` de `integration_test/moteur_3d_test.dart` puis (M2) de `integration_test/mannequin_mesure_test.dart` par `tools/ci3d_drive.sh` | `emulateur/*.png`, `emulateur/m1_releve.json`, `emulateur/m2_releve.json`, `emulateur/m2_mesure.json`, `emulateur/impeller.txt`, `emulateur/logcat.txt`, `emulateur/drive.log`, `emulateur/drive-mesure.log`, `emulateur/drive-code.txt` |
| `publish` | Assemble et recommite `ci-out/` | `resultat.txt` |

## Dépendance de test

`integration_test` n'est **pas** dans le `pubspec.yaml` livré : Flutter 3.47
référence les plugins des dépendances de développement dans le registre
Android de l'APK release (échec du build signé). La tâche `emulator` l'ajoute
dans sa copie de travail (`flutter pub add 'dev:integration_test:{"sdk":"flutter"}'`),
puis analyse `integration_test/` et `test_driver/` (exclus de l'analyse
principale dans `analysis_options.yaml`, comme `tools/perf_device/`).

## Captures du vrai rendu Flutter GPU

- `flutter test` n'a **pas** Flutter GPU (moteur de test sans Impeller) : il
  sert au repli « Non compatible » (`test/m1_engine3d_test.dart`), pas au
  rendu 3D.
- Le rendu réel se capture **sur l'émulateur** : le test d'intégration
  entoure l'application d'un `RepaintBoundary`, attend la stabilisation, puis
  `toImage(pixelRatio: 1.5)` ; le PNG passe en Base64 par
  `binding.reportData` et `test_driver/integration_test.dart` l'écrit dans
  `build/ci3d/` côté hôte (même méthode que la CI de flutter_scene).
- `binding.framePolicy = fullyLive` : vraies images produites par le moteur
  (rotation, mesure). Ne pas utiliser `pumpAndSettle` une fois la scène
  affichée (le rendu animé ne se stabilise jamais) : `pump(durée)`.
- Contrôle sans référence dans le test : part de la vue couverte par la
  figure, présence du gris et du rouge historique, nombre de couleurs.
  Les captures doivent **aussi être regardées** (outil Read) avant livraison.
- Le moteur de rendu choisi par Impeller est lu dans le journal
  (`Using the Impeller rendering backend (…)`) : `emulateur/impeller.txt`.

## Temps d'image

- L'écran Moteur 3D mesure 10 s de `FrameTiming.totalSpan` (début de
  construction → fin du rendu GPU) : images/s, moyenne, 99e centile.
- Sur émulateur (rendu logiciel, build debug), ces valeurs ne représentent
  pas un téléphone : elles servent à détecter une régression d'un lot à
  l'autre. La mesure qui compte est celle du téléphone du propriétaire
  (Réglages › À propos › Moteur 3D).

## Mannequin (M2)

- Le modèle `assets/anatomy/mannequin.glb` est converti par le build hook
  (`hook/build.dart`) dans `flutter_scene_generated/` à chaque build (et à
  `flutter test`) ; rien de généré n'est livré dans le ZIP.
- `integration_test/moteur_3d_test.dart` : écran Anatomie, groupe Dos,
  vues Face / Dos / Profil / 3/4 en sombre (via l'application) et en clair
  (MaterialApp claire : un `SLApp` déjà monté ne relit pas le thème), nom au
  toucher (grand pectoral), os masqués ; contrôles sans référence dans la vue
  `mannequin-view` (part de la figure, gris, rouge, couleurs).
- `integration_test/mannequin_mesure_test.dart` : mesure des organisations
  (a) une maille par muscle / (b) maillage fusionné, cible séparée : un
  plantage de la mesure ne fait pas perdre les captures du premier passage.
- Tests d'écran sans GPU : remplir les caches globaux (`engine3DSupport()`,
  `MannequinMap.load()`) dans `setUpAll`, hors des zones de temps simulé
  (un futur créé dans la zone d'un test ne se termine plus ensuite).
- Publication : `ci-out` est commité sur la tête actuelle de la branche
  (`git reset FETCH_HEAD`, sans rebase) ; un run annulé qui a publié entre-temps
  ne bloque plus la publication.
- Aperçu hors application pendant la fabrication du modèle :
  `python3 tools/anatomy/render_preview.py sortie.png [--groupe dos]` (Blender,
  Cycles CPU) ; le rendu qui fait foi reste la capture Flutter GPU.

## Pour un lot suivant

1. Construire le ZIP (`python3 tools/package_release.py …`), le copier à la
   racine de `claude/ci-3d` avec `ci-3d.yml`, pousser.
2. Attendre le commit de résultats, lire `ci-out/checks.txt` et
   `ci-out/resultat.txt`, appliquer `format.patch` et `pubspec.lock` si
   fournis, regarder chaque PNG de `ci-out/emulateur/`.
3. Ajouter ses propres écrans au test d'intégration (nouvelle fonction de
   capture, mêmes contrôles sans référence).

## Fiche exercice (M3)

- `integration_test/fiche_exercice_test.dart`, lancé par `tools/ci3d_drive.sh`
  après `moteur_3d_test.dart` (cible séparée) : 6 fiches (tirage, poussée,
  jambes, gainage, figure, isolation) en sombre (via l'application) et en
  clair, fiche avec muscles étirés (bleu acier), fiche avec muscles profonds
  (M4b : muscles absents du modèle listés à part), nom au toucher activé puis désactivé, rotation
  horizontale, ouverture de 20 fiches d'affilée (temps jusqu'au mannequin
  prêt, mémoire du processus). Relevé `emulateur/m3_releve.json`, captures
  `emulateur/m3_*.png`.
- La mesure M2 des organisations (`mannequin_mesure_test.dart`) n'est plus
  relancée par défaut : `CI3D_MESURE=1` la réactive.


## STATS (M4)

- `integration_test/stats_semaine_test.dart`, lancé par `tools/ci3d_drive.sh`
  après la fiche exercice (cible séparée) : STATS › Performances › Muscles
  sollicités, semaine type (séries des trois premières journées validées) en
  Face puis Dos, rotation, légende chiffrée, semaine vide, en sombre et en
  clair. Intensités comparées à `weeklyRegionIntensities` (même calcul que la
  carte 2D). Temps des images pendant le défilement de STATS (mannequin à
  l'écran) et pendant la rotation du mannequin (scène redessinée à chaque
  image). Relevé `emulateur/m4_releve.json`, captures `emulateur/m4_*.png`.

## Anatomie complète en transparence (M4b)

- `integration_test/anatomie_m4b_test.dart`, seule cible jouée par défaut par
  `tools/ci3d_drive.sh` (les cibles des lots précédents : `CI3D_TOUT=1`) :
  muscles profonds seuls allumés sous les 4 vues (sombre) et 2 vues (clair),
  rotation par petits pas (tri des surfaces translucides), toucher d'un
  rhomboïde (bulle « (profond) »), écran Anatomie (plusieurs filtres, menu
  ouvert, muscles profonds masqués, résumé), fiche et STATS en transparence,
  temps d'image de l'écran Moteur 3D avant (muscles opaques, sans les muscles
  cachés : `MannequinScene.debugOpacity` / `debugHidden`) et après. Relevé
  `emulateur/m4b_releve.json`, captures `emulateur/m4b_*.png`.
- Émulateur passé en 540 × 960 (240 ppp) par `tools/ci3d_drive.sh` : rendu
  logiciel plus court, captures lisibles (écran de 360 × 640 dp).
- Aperçu hors application : `render_preview.py --opacite 0.5 --regions …`.
