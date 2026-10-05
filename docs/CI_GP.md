# CI GP — méthode de contrôle du pipeline « Génération et progression » (établie par G1)

Copie à jour de `docs/CI_3D.md` (méthode héritée du pipeline Mannequin 3D,
reproduite plus bas) avec les ajouts du pipeline GP. Pas de SDK Flutter
local : chaque lot pose son arbre sur la tête de `claude/ci-3d`
(`git commit-tree <arbre du lot> -p origin/claude/ci-3d`, push en avance
rapide) et lit les résultats recommités dans `ci-out/`.

## Ajouts du pipeline GP (G1)

### Build de développement (D2.4)

- `lib/dev/dev_flags.dart` : `const bool kDevBuild = bool.fromEnvironment('KALIS_DEV');`.
  Tout le code du mode dev est derrière cette constante.
- `build-apk.yml` : l'**APK** (installé par le propriétaire, même signature)
  est construit avec `--dart-define=KALIS_DEV=true` ; l'**AAB** (Play Store)
  sans. `packages/**` fait partie des chemins déclencheurs.
- `tools/verify_android_artifacts.py --dev-apk` : seules les `libapp.so`
  diffèrent entre APK et AAB, et le marqueur du code du mode dev
  (`KALIS-DEV-SESSION-7F3A`, `kDevMarker`) doit être **présent dans l'APK et
  absent de l'AAB** pour les trois ABI (preuve que le compilateur a éliminé
  le mode dev de l'AAB). Test : `tools/tests/test_g1_dev_build.py`.

### Tests Dart en deux passages

- `flutter test` (tâche `checks`, étape « Tests Dart ») : build ordinaire,
  `kDevBuild` faux ; les tests du mode dev vérifient que le logo n'a aucun
  geste.
- `flutter test --dart-define=KALIS_DEV=true test/g1_mode_dev_test.dart`
  (étape « Tests Dart du mode dev », `dart_dev=` dans `ci-out/checks.txt`,
  journal `ci-out/flutter-tests-dev.log`) : parcours complet de la session
  de test. Un lot qui ajoute des tests du mode dev les met dans ce fichier
  ou ajoute son fichier à cette commande (ci-3d.yml et build-apk.yml).

### Tâche `packages` (moteurs, PIPELINE_GP.md §2 et §4)

Pour chaque dossier `packages/<paquet>/` qui contient un `pubspec.yaml` :
`dart pub get`, `dart format --output=none --set-exit-if-changed .`,
`dart analyze --fatal-infos`, `dart test`, puis, si
`bin/<paquet>_cli.dart` existe, **`dart run bin/<paquet>_cli.dart --rapport
<dossier>`** : le simulateur écrit ses rapports (JSON et texte lisible)
dans `<dossier>`, recopié dans `ci-out/packages/<paquet>/`. Journal par
paquet `ci-out/packages/<paquet>.log`, bilan `ci-out/packages/packages.txt`
(`<paquet>=success|failure`, ou « aucun paquet »). Résultat global :
`packages=` dans `ci-out/resultat.txt`. La tâche passe si `packages/` est
vide ou absent.

### Émulateur

- `tools/ci3d_drive.sh` joue par défaut la cible du lot en cours, avec
  `--dart-define=KALIS_DEV=true` (troisième argument `dev` de `cible`).
  G1 : `integration_test/mode_dev_g1_test.dart`, partie `a` (sombre) puis
  partie `b` (clair), deux lancements de l'application : b est un
  **redémarrage à froid** de a (application arrêtée entre les deux ; le
  stockage de l'application et son cache sont conservés par `flutter drive`).
  Relevés `emulateur/g1_releve_<partie>.json`, captures `emulateur/g1_*.png`.
- Les cibles des lots précédents (M8, M7b, M7, moteur 3D) : `CI3D_TOUT=1`.
- Le test d'intégration lance l'application complète par `kalisApp()` (même
  racine que `main`), dans un `RepaintBoundary` pour les captures.
- Un lot d'écran ajoute sa cible (même méthode : relevé JSON + captures,
  regardées avec l'outil Read avant livraison), limitée à ses écrans, clair
  et sombre, délai 5 min par test.

### G2 (dev6.1.0)

- Cible émulateur par défaut : `integration_test/retrait_g2_test.dart`,
  parties `a` (sombre) et `b` (clair), sans le drapeau du mode dev :
  document d'état d'un utilisateur de 6.0.x (WOD, séances perso, crédits,
  L12) → annonce et copie, accueil, Arsenal, STATS, Réglages › Sauvegardes.
  Relevés `emulateur/g2_releve_<partie>.json`, captures
  `emulateur/g2_*_<thème>.png`. G1 passe sous `CI3D_TOUT=1`.
- Tests Dart du mode dev : `test/g1_mode_dev_test.dart` et
  `test/g2_mode_dev_test.dart` (libellé « dev6.1.0 », copie propre à
  chaque session).
- Nommage (D0.9) : `build-apk.yml` passe `--build-name=dev<version du
  pubspec>` à l'APK seulement ; `verify_android_artifacts.py --dev-apk`
  attend ce `versionName` dans l'APK et la version nue dans l'AAB.

### G5 (dev6.3.0)

- Cible émulateur par défaut : `integration_test/koach_g5_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis) et `b` (clair,
  violet) : accueil (carte du jour, proposition dite par Koach), Anatomie ›
  Galerie de Koach (36 poses, flammes, sélecteur, « Pourquoi ? »,
  transition), « Réduire les animations »
  (`platformDispatcher.accessibilityFeaturesTestValue`), session de test
  (message de Koach à l'entrée, galerie, suppression). Relevés
  `emulateur/g5_releve_<partie>.json`, captures `emulateur/g5_*_<thème>.png`.
  G3 passe sous `CI3D_TOUT=1` ; la cible `koach_m7b_test` (animations 3D de
  Koach) est retirée avec elles.
- Sous `flutter test`, les animations au repos de Koach (respiration,
  clignement) sont coupées (`KoachMotion.idle`, variable `FLUTTER_TEST`) :
  aucun écran ne cesserait sinon de produire des images ; les tests qui les
  vérifient les rallument. Rebond et transition restent (durées finies).

### G6 (dev6.4.0)

- Cible émulateur par défaut : `integration_test/profil_g6_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis) et `b` (clair,
  violet) : session personnelle d'avant G6 (programme commencé, profil L8,
  pas de profil v2) → proposition de Koach « Refaire mon profil » et
  « Plus tard » ; session de test (5 appuis) → création complète du profil
  (12 écrans), dont récapitulatif, « Toi » et discipline à 200 % de texte
  (`platformDispatcher.textScaleFactorTestValue`) ; attente du programme ;
  Réglages › Profil ; suppression de la session de test, session
  personnelle identique clé par clé. Relevés `emulateur/g6_releve_<partie>.json`,
  captures `emulateur/g6_*_<thème>.png`. G5 passe sous `CI3D_TOUT=1`.
- APK de test précompilé sur la cible G6.
- Tests Dart du mode dev : `test/g6_mode_dev_test.dart` ajouté à la commande
  (ci-3d.yml et build-apk.yml).
- Tests Dart du lot : `test/g6_profil_test.dart` (modèle, magasin, écrans).

### G7 (dev6.5.0)

- Cible émulateur par défaut : `integration_test/programme_g7_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis) et `b` (clair,
  violet) : session personnelle (Réglages › Mon programme, Où j'en suis sans
  valider) ; session de test (5 appuis) → création du profil, création du
  programme (passe 1, autre proposition, revue avec variantes et diff de
  Koach, récapitulatif, passe 2, ajustement refusé, validation), accueil ;
  suppression de la session de test, session personnelle identique clé par
  clé. Relevés `emulateur/g7_releve_<partie>.json`, captures
  `emulateur/g7_*_<thème>.png`. G6 passe sous `CI3D_TOUT=1`.
- APK de test précompilé sur la cible G7.
- Tests Dart du mode dev : `test/g7_mode_dev_test.dart` ajouté à la commande
  (ci-3d.yml et build-apk.yml). Tests Dart du lot : `test/g7_plan_test.dart`.
- La tâche `packages` contrôle aussi `packages/kalis_plan` (10 240 profils,
  quelques minutes).

### G9 (dev6.6.0)

- Cible émulateur par défaut : `integration_test/seance_g9_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis) et `b` (clair,
  violet) : session personnelle semée avec une copie du programme du
  propriétaire (départ il y a 11 semaines, journal synthétique des semaines
  1 à 11, profil v2 en mode assisté) → séance du jour servie par
  kalis_adapt : bilan (« Comment tu te sens ? »), réponse basse → détail
  (sommeil, énergie, douleur à l'épaule), ajustement de Koach, sélecteur
  des flammes, série à 10 flammes → conseil pour la série suivante, fin de
  séance et résumé ; session de test (5 appuis) → profil et programme
  généré semés, séance complète servie par le moteur ; suppression de la
  session de test, session personnelle identique clé par clé. Relevés
  `emulateur/g9_releve_<partie>.json`, captures `emulateur/g9_*_<thème>.png`.
  G7 passe sous `CI3D_TOUT=1`. APK de test précompilé sur la cible G9.
- Tests Dart du lot : `test/g9_seance_test.dart` (magasin, journal des
  moteurs, bilan, modes, conseil, sauvegarde, écrans).
- G9 correction 1 (dev6.6.1) : même cible ; la note se donne sur la ligne
  des flammes sous la série (`flame-track-<n>`, positions `flame-pos-<i>`),
  séries 1 à 3 validées puis capture `08_series` (séries résumées en une
  ligne, `set-summary-<n>`), fin de séance et capture `12_fin_series`
  (« Tes séries »).

### G10 (dev6.7.0)

- Cible émulateur par défaut : `integration_test/evolution_g10_test.dart`,
  build de développement, parties `a` (sombre, rouge Kalis, mode assisté)
  et `b` (clair, violet, mode libre) : session personnelle (profil v2 et
  programme créé ; Réglages › Mon programme, carte « Évolution », écran
  Évolution : mode modifiable, déblocage) ; session de test (5 appuis) →
  profil et programme semés, écran du simulateur, simulation de 8 semaines
  (`runDevSimulation`, même fonction que le bouton « Simuler » ; si le
  moteur ne propose rien, session de test recréée et graine suivante),
  horloge de la session de test au dernier jour simulé (redémarrage
  logique) ; carte de Koach sur l'accueil (proposition en attente ou
  annoncée), feuille du diff, historique des changements, inspecteur du
  moteur dynamique ; suppression de la session de test, session
  personnelle identique clé par clé. Relevés `emulateur/g10_releve_<partie>.json`,
  captures `emulateur/g10_*_<thème>.png`. G9 passe sous `CI3D_TOUT=1`. APK
  de test précompilé sur la cible G10.
- Tests Dart du mode dev : `test/g10_mode_dev_test.dart` ajouté à la commande
  (ci-3d.yml et build-apk.yml). Tests Dart du lot :
  `test/g10_evolution_test.dart` (modèle, propositions dans les deux modes,
  annulation, refus, sauvegarde, bloc suivant, simulateur déterministe,
  écrans), `test/g10_seance_sans_moteur_test.dart` et
  `test/g10_charges_consigne_test.dart` (repris des tests de L7, retirés).
- Branche de mise au point du lot : `claude/ci-g10-rapide` (workflow
  `rapide.yml` posé seulement sur cette branche : formatage, analyse, tests
  choisis, résultats dans `ci-rapide/`) ; le contrôle complet reste
  `claude/ci-3d`.

### CU (dev6.8.0, pipeline CP, voie App)

- Cible émulateur par défaut : `integration_test/profil_cu_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis) et `b` (clair,
  violet) : session personnelle de dev6.7.0 (profil au schéma 2, programme
  commencé) → profil relu au schéma 3, invitation de Koach, « Compléter mon
  profil » (questions du schéma 3, programme et journal inchangés) ; session
  de test (5 appuis) → parcours d'un débutant (écrans montrés, pas de
  récupération, 4 fourchettes), puis le même profil passé en compétiteur
  élite de streetlifting depuis le récapitulatif (poids obligatoire,
  expérience, record, échéance avec règlement, récupération), deux écrans à
  200 % de texte ; Réglages › Profil, tests guidés ; suppression de la
  session de test, session personnelle intacte. Relevés
  `emulateur/cu_releve_<partie>.json`, captures `emulateur/cu_*_<thème>.png`.
  G10 passe sous `CI3D_TOUT=1`. APK de test précompilé sur la cible CU.
- Tests Dart du lot : `test/cu_profil_v3_test.dart` (parcours, profils types,
  conditions, brouillon, migration, sauvegarde, moteurs actuels, compléter
  son profil, tests guidés, écrans).
- Branche de mise au point du lot : `claude/ci-cu-rapide` (workflow
  `rapide.yml` posé seulement sur cette branche, comme G10) ; le contrôle
  complet reste `claude/ci-3d`.

### CI1 (dev6.9.0, pipeline CP, voie App)

- Cible émulateur par défaut : `integration_test/street_ci1_test.dart`, build
  de développement, parties `a` (sombre, rouge Kalis, compétiteur de
  streetlifting) et `b` (clair, violet, débutant de calisthénie) : session
  personnelle (programme du propriétaire, pas de saison) ; session de test
  (5 appuis, horloge au 1er octobre 2026) → profil street v3
  (`sampleStreetProfile`) et programme du chemin calibré ; carte « Ta
  saison », écran MA SAISON, jour J (partie a) ; séance servie par le mode
  coach (série de tête et séries allégées, ou maintien), panneau du coach,
  notes ; suppression de la session de test, session personnelle intacte.
  Relevés `emulateur/ci1_releve_<partie>.json`, captures
  `emulateur/ci1_*_<thème>.png`. CU passe sous `CI3D_TOUT=1`. APK de test
  précompilé sur la cible CI1.
- Tests Dart du lot : `test/ci1_street_test.dart`.
- Branche de mise au point du lot : `claude/ci-ci1-rapide` (workflow
  `rapide.yml` posé seulement sur cette branche, `build-apk.yml` sans
  déclencheur sur cette branche) ; le contrôle complet reste `claude/ci-3d`.

### Mode dev dans les tests d'intégration

- Données de la session personnelle semées par un `AppStore()` séparé avant
  `kalisApp()` ; la session de test se démarre par 5 appuis sur
  `ValueKey('header-logo')`, les outils par un appui long sur
  `ValueKey('dev-badge')`.
- Isolation : `KalisPrefs(raw, dev: false).snapshot()` (session
  personnelle, clé par clé) avant/après ; `store.exportForFile` avec une date
  fixe ; `raw.getKeys().where(SessionSpace.reserved)` vide après suppression.

---

## (Méthode héritée) CI 3D — méthode de contrôle du mannequin 3D (établie par M1)

Pipeline « Mannequin 3D » : chaque lot contrôle son travail avec cette CI,
sans SDK Flutter local. Moteur : flutter_scene (Flutter GPU sur Impeller).

## Déclenchement

- Workflow `.github/workflows/ci-3d.yml` (M4c : même fichier sur `main` et
  sur `claude/ci-3d`, le projet étant à la racine du dépôt).
- Déclenché **uniquement** par un push sur `claude/ci-3d` (jamais
  `claude/ci-tools`). Cette branche porte les sources à tester (M4c : l'arbre
  du lot, posé sur la tête de la branche par un commit dont le contenu est
  celui du lot, sans réécrire l'historique). `build-apk.yml` se déclenche
  aussi sur ce push (chemins du projet) : un build signé de contrôle, sans
  effet sur `main`.
- Les résultats sont recommités par la CI dans `ci-out/` sur `claude/ci-3d`
  (commit « CI 3D : résultats du run … ») : `git fetch origin claude/ci-3d`
  puis lire les fichiers. Rien à télécharger.

## Ressources sous licence (M6c)

Le mannequin d'exécution (`assets/anatomy/mannequin.glb`) n'est plus suivi en
clair : chaque tâche qui construit ou teste l'application le déchiffre
d'abord depuis `assets_secure/mannequin.glb.enc` (`python3
tools/secure_assets.py decrypt`, secret `KT_ASSETS_KEY` ; la tâche `before`
le fait dans la copie de `main` si elle contient `tools/secure_assets.py`).
Sans le secret, l'étape échoue avec un message explicite. Les clairs ne
sont jamais recopiés dans `ci-out/` ni dans les artefacts. Cible émulateur
du lot : `integration_test/personnage_m6c_test.dart` (parties a, b, c).

## Tâches

| Tâche | Contenu | Résultats dans `ci-out/` |
| --- | --- | --- |
| `checks` | Flutter 3.47.5 : `pub get` (verrou régénéré s'il est périmé), formatage, analyse, tests Python + `verify_project.py` + `package_release.py --check` (M4c : arbre du dépôt) + `check_release_without_secrets.py --tree`, suite Dart complète, rendus de test (`KALIS_CAPTURE`), build debug | `checks.txt` (bilan), `pubspec.lock`, `pub-lock.txt`, `format.patch` (si formatage à corriger), `analyze.log`, `python-tests.log`, `flutter-tests.log`, `build-debug.log`, `flutter-version.txt` |
| `before` | Mêmes rendus de test sur `main`, commit parent du lot (M4c : ZIP extrait si `main` le contient encore, sinon `git archive`) (version Flutter de main, `FLUTTER_BEFORE`, à ajuster si un lot change de version) | comparés dans `captures-comparaison.txt` ; paires différentes dans `captures/` (`avant_*` / `apres_*`) |
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
  `flutter test`) ; rien de généré n'est suivi par git (`flutter_scene_generated/.gitignore`).
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

1. M4c : poser l'arbre du lot sur la tête de `claude/ci-3d` (par exemple
   `git commit-tree <arbre du lot> -p origin/claude/ci-3d`, puis pousser ce
   commit : avance rapide, aucune réécriture), le workflow étant dans l'arbre.
2. Attendre le commit de résultats, lire `ci-out/checks.txt` et
   `ci-out/resultat.txt`, appliquer `format.patch` et `pubspec.lock` si
   fournis, regarder chaque PNG de `ci-out/emulateur/`.
4. Émulateur : seule la cible du lot est jouée (`tools/ci3d_drive.sh`,
   M4c : `integration_test/zoom_filtres_m4c_test.dart`), délai du job 30 min.
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

## Squelette et postures (M5) — retirés en 5.5.2

Le squelette, la peau et les postures (M5) ont été retirés avec l'écorché
acheté (M56 correction 2, 5.5.2) : `rig.json`, `mannequin_skin.bin`,
`build_rig.py`, `rig_def.py`, `rig_pose.py`, `render_poses.py`,
`build_body.py`, `measure_body.py`, `silhouette.py`, `mannequin_base.glb`,
`postures_m5_test.dart`, `m5_rig_test.dart`, `test_m5_rig.py`,
`test_m56_body.py`. Le code de posture de `mannequin_3d.dart` et
`mannequin_rig.dart` reste en place, inactif (aucun rig chargé). Ce qui
suit décrit l'état de 5.5.0 à 5.5.1.

- `integration_test/postures_m5_test.dart`, cible du lot lancée en premier par
  `tools/ci3d_drive.sh` (les cibles des lots précédents sur demande,
  `CI3D_TOUT=1`) : 4 postures (debout, suspendu, squat bas, planche) × 4 vues,
  quadriceps et dos allumés ; écran Anatomie (sélecteur « Posture »,
  transition, toucher d'un quadriceps sur le squat, planche en clair).
- Contrôle d'accord entre la peau du GPU (image) et celle du processeur
  (toucher) : sur une grille de la vue, là où le toucher trouve un muscle
  allumé l'image est rouge, là où il ne trouve rien c'est le fond
  (`m5_releve.json`).
- Planches Blender hors application (même peau, en numpy) :
  `python3 tools/anatomy/render_poses.py dossier [--postures …] [--centre x,y,z
  --echelle s --vues 0,90]`.

## Mannequin musclé, animations, carte Koach, préchargement (M56)

Correction 1 (5.5.1, 29/09/2026) : 3 essais sur `claude/ci-3d-fable`
(36532238784 : formatage, test Koach S5 avec la page Koach, fondu non
garanti à mi-chemin sur émulateur ; 36533912915 vert ; 36535840924 vert,
libellés des positions). `python3 tools/anatomy/silhouette.py` comparait la
silhouette du mannequin à la référence du propriétaire.

Correction 2 (5.5.2, 29/09/2026) : modèle remplacé par l'écorché acheté
(`tools/anatomy/build_model.py --zip Archive.zip`, archive de la release
GitHub `modele-achete`, jamais dans le dépôt), plus d'animation ni de
posture, muscles sollicités dans la couleur dominante, plus de boutons
Précédent / Suivant dans la séance. Correction 3 (5.5.3) : muscles à 100 %,
zone ciblée (muscles du pack des exercices : `TargetedMannequin`), mannequin
à la place des images 2D (fiche, accueil, WOD), plus de rotation au doigt ;
3 essais (36556945259 analyse, 36558779220 tests, 36560553169 vert).
Correction 4 (5.5.4) : maillage gris et halo dessiné par-dessus la vue
(`MannequinHaloPainter`), fond de la scène = couleur du support ; essais
36565820933, 36567719792 (émulateur relancé une fois : image système
corrompue), 36571687956 vert. Correction 2 : 4 essais sur `claude/ci-3d-fable`
(36542184910 : analyse ; 36546278876 : tests LC1 par boutons, fiche sans
défilement jusqu'au mannequin ; 36549423360 : formatage, respiration sans
région, préchargement ; 36551761380 : vert, 955 tests Dart). Planches de
contrôle : `build_model.py --render dossier` (face, dos, profils, une couleur
par nœud, légende).

- Branche CI propre au lot : `claude/ci-3d-fable` (copie de `ci-3d.yml`
  déclenchée sur cette branche, `group: ci-3d-fable`, résultats recommités
  sur la même branche ; script `tools/…` : l'arbre du lot est posé par
  `git commit-tree` avec le workflow réécrit, sans toucher `claude/ci-3d`
  de la session M6).
- `integration_test/animations_m56_test.dart`, seule cible jouée par défaut
  par `tools/ci3d_drive.sh` : écran Anatomie (5.5.2 : écorché au repos dans
  les 4 vues, groupe Dos allumé dans la couleur dominante), fiches des 3
  pilotes (5.5.2 : démonstration 2D et mannequin fixe avec les muscles de
  l'exercice), carte « Koach · séance du
  jour » (page à part avant l'exercice 1 ; ouverte,
  repliée, sombre, clair), ouverture d'un mannequin avant / après le
  préchargement (`MannequinPreload`, première image et images perdues,
  durée du chargement et du préchauffage, mémoire ajoutée), écran Moteur 3D
  (carte Préchargement). Relevé `emulateur/m56_releve.json`, captures
  `emulateur/m56_*.png`.
- Hors application : `python3 tools/anatomy/render_preview.py sortie.png`
  (Blender, rendu du GLB d'exécution) ; `build_model.py --render dossier`
  (planches des régions). Les outils d'animation (`animate.py`,
  `render_clip.py`, `render_poses.py`) ont été retirés en 5.5.2.

## Audit du mannequin fixe (M6b)

- `integration_test/audit_m6b_test.dart`, seule cible jouée par défaut par
  `tools/ci3d_drive.sh` (M56 et les lots précédents : `CI3D_TOUT=1`), en
  **deux parties** (`--dart-define=M6B_PART=a|b`, journaux
  `drive-audit_m6b_test-a.log` / `-b.log`) : l'essai A, 30 captures dans
  un seul lancement, a perdu le service du pilote au renvoi des données
  (« Service has disappeared »). Partie a : Anatomie (repos, menu Filtres,
  groupe Dos, toucher, zoom, clair, grand texte avec animations réduites),
  fiches (traction, dips, squat ; étirement en clair). Partie b : STATS,
  accueil, aperçu de WOD, Moteur 3D, grand écran (`tester.view` à
  1200 × 1920 px, capture à 0,75).
- Relevés `emulateur/m6b_releve_a.json`, `m6b_releve_b.json` : figure, halo
  (pixels saturés du côté de la couleur dominante), gris, **démarcation**
  (écart moyen des pixels de part et d'autre des bords gauche et droit de la
  vue : 0 attendu, fond = support), vue de départ, libellés.
- Aires des régions (vue de départ des fiches) :
  `python3 tools/anatomy/build_model.py --aires` (depuis le GLB, sans
  l'archive) ; `build_model.py --zip` les écrit aussi.

## Lecteur d'animation (M7)

- `integration_test/animation_m7_test.dart`, seule cible jouée par défaut par
  `tools/ci3d_drive.sh` (M6c et les lots précédents : `CI3D_TOUT=1`), en
  trois parties (`--dart-define=M6B_PART=a|b|c`) : a = écran « Animation de
  test » en sombre (5 temps en Profil, 3 vues au plus bas, toucher sur le
  corps déformé, zoom, lecture et images/s, pause) ; b = clair, animations
  réduites (pas de lecture, image clé) ; c = 12 images du GIF (0,5 s
  d'écart, vue Profil). Relevés `emulateur/m7_releve_<partie>.json`
  (temps, phase, gain du halo, bassin, figure, halo, gris, démarcation).
- Le mannequin animable (`assets/anatomy/mannequin_anime.glb`) est déchiffré
  comme le mannequin fixe (rôle « exécution » du manifeste) et converti par
  le hook de build.

## Animations de Koach (M7b)

- `integration_test/koach_m7b_test.dart`, seule cible jouée par défaut par
  `tools/ci3d_drive.sh` (M7 et les lots précédents : `CI3D_TOUT=1`), en
  quatre parties (`--dart-define=M6B_PART=a|b|c|d`) : a = Anatomie ›
  Koach (aperçu) (entrée, puces, lecture), pose forte de chacune des 9
  animations en Face, trois aussi en 3/4 ; b, c, d = 8 images de GIF par
  animation (Face) pour les familles attente, parle, félicite (un test par
  animation, 5 min chacun). Relevés `emulateur/m7b_releve_<partie>.json`
  (temps, part de la vue couverte par la figure).
- Les clips (`assets/anatomy/clips/koach/`) sont fabriqués hors CI :
  `python3 tools/anatomy/koach_animations.py --importer` (Blender sans
  interface, sans clé) ; la CI vérifie le registre
  (`import_animations.py verifier`, tests Python et Dart).
- Aperçu hors application (capsules, sans GPU) :
  `python3 tools/anatomy/koach_preview.py DOSSIER --planche --bande --gif`.
