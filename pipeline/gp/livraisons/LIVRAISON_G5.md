# Livraison G5 — Koach 2D dans l'application (dev6.3.0)

- **Version** : dev6.3.0 (`pubspec` 6.3.0+98), commit `main` b89d11e, build signé `build-apk.yml` run 36884596929.
- **Contrôles** : CI `claude/ci-3d` run 36882261714 (essai 7) — formatage, analyse, 878 tests Dart, 14 tests du build de dev, 160 tests Python, `verify_project`, `package_release --check`, `check_release_without_secrets --tree`, tâche `packages` (`kalis_core`, `kalis_koach`), émulateur `koach_g5_test` a (sombre, rouge) et b (clair, violet) : vert. Rendus `visual_capture_test` : échec identique avant et après (préexistant sur `main`).
- **Paquet** : `packages/kalis_koach` et `tools/koach` repris tels quels de la branche fixe `etiquettes/kalis_koach-v0.1.0` (4fa2777).
- **Page de suivi** : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5

## Fait

- `lib/koach/` : `KoachView` (36 poses en `Path` mis en cache ; couleurs inversées selon le thème, papier = couleur du support annoncée par `KoachSurface`/`KCard` ; rebond, transition 200 ms, clignement seedé, respiration ; rendu à la demande ; « Réduire les animations » = pose fixe), `KoachBubble` (+ `.line` sur `KoachDirector`, « Pourquoi ? »), `KoachSays`, `KoachHeader`, `showKoachSheet`, `showKoachToast`/`koachSnackBar`, `FlameIcon` (tailles relatives, dégradé de la couleur dominante, « Difficulté n sur 10, RIR … »), `FlamePicker` (prêt pour G9), Galerie de Koach, `KoachToday`.
- Koach parle : carte du jour de l'accueil, propositions L11 et pause (accueil), carte « profil modifié » L10, carte « Koach · séance du jour », suggestion de charge, calibrage, pesée, bilan de fin de séance, propositions et structure du bilan, messages courts de ces écrans, messages de la session de test (entrée, suppression, voyage dans le temps).
- Anatomie › « Galerie de Koach » remplace « Koach (aperçu) ».
- Retiré (Koach 3D, M7b) : 9 clips `assets/anatomy/clips/koach/`, entrées « mascotte » du registre, `lib/koach_preview_screen.dart`, `kKoachFamilies` et champs `mascot`/`family`/`loop` de `ClipEntry`, `tools/anatomy/koach_animations.py`, `koach_rig.py`, `koach_preview.py`, `import_koach`. Tests retirés avec la fonctionnalité : `test/m7b_koach_test.dart`, `tools/tests/test_m7b_koach.py`, `integration_test/koach_m7b_test.dart`. Démonstration 3D des exercices inchangée.
- Poids de l'APK (profil) : 55 902 704 → 56 398 741 octets (+0,9 %).

## À tester par le propriétaire

Anatomie › Galerie de Koach (36 poses, animations, flammes, sélecteur, bulle « Pourquoi ? ») ; accueil (Koach sur la carte du jour, propositions) ; thèmes clair et sombre, une autre couleur dominante ; « Supprimer les animations » d'Android ; session de test (5 appuis, appui long 3 s).

## Décisions

Voir `DECISIONS_GP.md`, section G5 (lot déduit, papier = couleur du support, Koach sur la carte du jour sans bulle, textes existants gardés, pas de stockage des répliques, animations sous `flutter test`, messages courts au grand texte, couleurs des flammes, retrait M7b).

## Limites

- Les répliques de `kalis_koach` ne servent encore qu'à la galerie ; les écrans existants gardent leurs textes.
- Émulateur de la CI : le premier lancement perd parfois le service du pilote (essais 1, 2, 5) ; `ci3d_drive.sh` refait alors un essai.
