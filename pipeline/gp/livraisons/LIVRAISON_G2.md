# LIVRAISON G2 — Suppression des WOD, des séances manuelles et de L12 (dev6.1.0)

Pipeline « Génération et progression », piste A. Modèle : Opus 5.5, effort élevé. Date : 01/10/2026.
Version : **dev6.1.0** (pubspec `6.1.0+96`). Commit `main` : `e5cf07f`. Build signé : run 36840295689 (main), CI 36838077572. Statut : **à valider** par le propriétaire.

## Ce qui change

- **Retiré** : onglet WOD et tout ce qui en dépend (catalogue, générateur, formats, aperçu, chrono et reprise, boutique, essai du jour, vitrine, envies, crédits et droits KT-005/KT-014, estimation des WOD, badges/défis/titres/records WOD, historique WOD de STATS) ; créateur de séances perso et séances perso (modèles, journal `S0-…`, XP, séance d'entretien de vacances L11) ; L12 entier (STATS › Mes progrès et mode « victoires », Réglages › Motivation et progression, carte de l'accueil, chaînes de figures, étapes, bilans, célébrations, parcours d'habitude, image de partage `shareImage`).
- **Copie avant suppression** (D1.1) : au premier lancement, dans chaque session (perso et test), si des données de l'utilisateur sont concernées, le document d'état de 6.0.x est copié tel quel (importable par 6.0.x) dans le stockage de l'application, relu et vérifié (texte, empreinte, contenu, lecture comme une sauvegarde), puis seulement supprimé. Échec : rien supprimé, écrans masqués, nouvel essai au lancement suivant.
- **Écran d'annonce** (une fois) : ce qui est supprimé, ce qui ne change pas, copie (date, taille), « Partager la copie » (menu Android), « Enregistrer dans un fichier », « Compris ». Copie retrouvable dans Réglages › Sauvegardes.
- **Anciennes sauvegardes** : importables ; WOD, séances perso, crédits, « Motivation » ignorés, signalés dans l'aperçu.
- **Navigation** : 4 onglets inchangés ; Arsenal = Exercices + Anatomie.
- **Nommage devX.Y.Z** (D0.9) : `kAppVersion` « dev6.1.0 » dans l'APK, « 6.1.0 » dans l'AAB ; `--build-name=dev<version>` pour l'APK seul ; `verify_android_artifacts.py` vérifie les deux `versionName`.
- **Conservé** : règle des rappels (jamais un jour de repos) dans `lib/notifications.dart` ; EMOM des exercices du programme (`TrainingEstimator.emom`) ; ancien système XP/niveau (jusqu'à G12), sans les WOD ni les séances perso (le niveau peut baisser).

Décisions réversibles : `DECISIONS_GP.md`, section G2.

## À tester par le propriétaire

1. **Avant d'installer** : Réglages › Sauvegardes › Exporter une sauvegarde (6.0.1).
2. Installer l'APK dev6.1.0 par-dessus. Au lancement : écran « Mise à jour » (ce qui est supprimé, copie vérifiée) ; « Partager la copie » ouvre le menu Android ; « Compris ».
3. Plus d'onglet WOD ni de « Nouvelle séance » (Arsenal : Exercices, Anatomie) ; STATS sans « Mes progrès » ; Réglages › Programme sans « Motivation et progression ».
4. Ton programme (S12), l'historique de ses séances et tes records : intacts. Réglages › À propos : « Kalis Track dev6.1.0 ».
5. Réglages › Sauvegardes › « Copie d'avant la suppression des WOD » : la copie reste accessible.

## Fichiers

- Nouveaux : `lib/retired_data.dart`, `lib/retired_notice_screen.dart`, `test/g2_retrait_test.dart`, `test/g2_mode_dev_test.dart`, `test/support/retired_fixtures.dart`, `tools/tests/test_g2_retrait.py`, `integration_test/retrait_g2_test.dart`.
- Supprimés : `lib/wod_catalog.dart`, `wod_formats.dart`, `wod_generator.dart`, `wod_models.dart`, `wod_preview.dart`, `wod_screen.dart`, `wod_store.dart`, `builder_screen.dart`, `motivation.dart`, `motivation_screens.dart`, `motiv_store.dart`, `tools/wod_catalog_snapshot.dart`, `test/support/score_sheet.dart`.
- Android : `MainActivity.kt` (partage de la copie, `shareImage` retiré), `ShareProvider.kt` (PNG L12 retiré, copie ajoutée).

## Tests retirés avec les fonctions supprimées

- Fichiers entiers : `wod_store_test.dart`, `wod_acquisition_test.dart`, `l3_economy_test.dart` (essai du jour, vitrine, crédits), `l3b_formats_test.dart` (formats WOD, WodClock), `l2_purchase_ui_test.dart`, `l12_motivation_test.dart`, `l12_screens_test.dart`, `l12_store_test.dart` (la règle des rappels KT-070 et le test `reminderAllowed` sont déplacés dans `notifications_test.dart`).
- `l2_persistence_test.dart` : groupe KT-002 achats (8 tests), KT-014 droits WOD (migration crédits v1 ×2, format 2 WOD joué/non joué, format 3 droit à coût 0, achats normaux et remisés, droits anciens, séances perso répétées), groupe KT-005 (6 tests).
- `store_test.dart` : achat WOD unique, catalogue de 1 000 WOD classé, séance perso répétée, identifiants de séance perso, cache matériel des WOD, déciles du catalogue ; moitié « chrono WOD » de « versions futures ».
- `l4_depart_test.dart` : groupe « Résultats L3b ». `l4b_seances_test.dart` : séance perso répétée ; WodClock (pauses et frontière de phase, point sûr) ; groupe F/G WOD en cours (4 tests) ; écran « WOD retrouvé en pause ».
- `l6_perf_test.dart` : groupe « caches WOD » (4 tests) ; `l6_perf_bench_test.dart` : scénarios catalogue/WOD (banc désactivé par défaut).
- `timers_test.dart` : 9 tests WodClock et scores WOD (les 3 tests `TimerCtl` restent). `training_estimate_test.dart` : rounds/cap, prescriptions croisées, calibrage par l'historique, cache des estimations WOD (les autres passent par `parseLine` ou `emom`, mêmes valeurs).
- `progression_test.dart` : crédits par palier, records WOD (×2). `reward_flow_test.dart` : solde de crédits de l'Arsenal. `screens_test.dart` : recherche du catalogue, aperçu depuis le chrono, score WOD. `ui_refactor_test.dart` : WOD verrouillé, clavier de l'éditeur de séance. `m4c_filter_menu_test.dart` : filtres du catalogue WOD, choix d'exercice de l'éditeur. `search_test.dart` : 2 tests du générateur de WOD. `history_correction_test.dart` : séance perso rouverte. `l11_store_test.dart`, `l11_adapt_test.dart` : séance d'entretien.
- Adaptés (fonction conservée) : XP et défis recalculés sans WOD ni séances perso (`progression_test` : 215 → 175 XP de défis, 980 → 1 300 XP pour 8 journées du programme à 100 XP), historique et filtres de STATS, imports historiques (WOD ignorés), captures (écrans retirés ôtés).

## Contrôles

Formatage, analyse (0 remarque), 830 tests Dart, 12 tests du mode dev, tests Python, verify_project, package_release --check, sans secrets : verts (run 36838077572). Émulateur G2 a (sombre) + b (clair) : vert, captures regardées. Build signé main : run 36840295689 (APK « dev6.1.0 », AAB « 6.1.0 »). Limite connue : le test de captures `visual_capture_test.dart` échoue déjà sur `main` avant G2 (défilement de STATS), inchangé par ce lot ; il ne fait pas partie des contrôles obligatoires.
