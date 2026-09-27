# Livraison — refonte muscles et animations (Kalis Track 4.3.1)

**Statut : fusionnée sur `main` le 27/09/2026 en 4.3.1 (`7f07e2e`), build signé n°94 réussi. Rien n'est vérifié sur téléphone.**

| Élément | Valeur |
| --- | --- |
| Branche | `refonte/muscles-animations`, commit `f4d7d70` (contient `main` `332e292`, 4.2.0 / L12 ; première version `a1159c3` sur 4.1.0, main étant passé en 4.2.0 deux minutes avant ce push) |
| Version | 4.2.1+70 (`pubspec.yaml`, `kAppVersion`) — correctif suivant main 4.2.0 |
| ZIP | `streetlift_tracker_v33.zip`, 531 fichiers, 3 769 575 octets, SHA-256 `fa81b8a74ab08797fb8be6dec23134ce2a4e5bb4ee3b45ae6b67eb659dfe0ae4`, `package_release.py --check` OK ; seul fichier différent de `main` |
| Build | run n°92 `Build APK et AAB` (4.2.1) : réussi (format, analyse, suite, APK + AAB signés avec la clé existante, artefacts vérifiés) — https://github.com/mikeriin/streetlift-apk/actions/runs/36322578521 ; run n°91 (4.1.1 sur 4.1.0) : réussi |
| Contrôles CI (`claude/ci-refonte`) | 4.1.1 : format sans changement, analyse sans problème, suite 769 réussis / 13 ignorés / 0 échec, tests refonte 11/11, Python 75/75, `verify_project.py` OK. 4.2.1 : format sans changement, analyse sans problème, suite 820 réussis / 13 ignorés / 0 échec, tests refonte 11/11, captures OK (le SUIVI du ZIP 4.2.1 cite encore 769, chiffre de 4.1.1 ; corrigé à la fusion) |
| Aperçu (téléphone) | https://claude.ai/artifact/XPop5Xkw3SJNmeftWd6zQf |

## Changements
- STATS / accueil / WOD : carte anatomique 3.1.0 restaurée ; test pixel à pixel contre une copie conforme du widget 3.1.0 (sombre, clair, avec et sans halo).
- Fiche exercice : carte face / dos / profil, intensités par rôle (1 / 0,62 / 0,35 / 0,25), liste texte conservée. `heatAtlasFills` conservée (test L9b intact).
- Vue de profil depuis l'image du propriétaire (`tools/muscles_profile.py`) : 142 × 760 px, 11 calques, `meta.json` complété.
- Démonstrations découpées (`tools/anim_cutout.py`, `lib/pose_cutout.dart`) : face 16 segments, dos 16, profil 10 ; articulations exactes ; muscles surlignés avec la rampe de la carte ; vue de dos en miroir de la cinématique de face (584 profil, 21 face, 2 dos).
- Revue des 607 démonstrations (planches regardées une à une) : 18 exercices revus (11 développés en image fixe haute, leg curl / leg extension fixes, 5 sans démonstration). Détail : `SUIVI_PROJET.md` du ZIP.

## Aperçu (graine 20260927, exercices animés)
Face : jumping jacks ; dos : side bend haltère ; profil : rowing aux anneaux. GIF, images clés, STATS, fiche, planche face / dos / profil et calques de profil sur la page d'aperçu.

## Décisions prises par défaut
D-MA-01 à D-MA-04 dans `pipeline/DECISIONS_EN_ATTENTE.md` (règle de vue de dos, 18 exercices revus sans toucher au pack, générateur inchangé, flanc redessiné).

## Suite
À l'accord écrit (« ok fusion ») : mise à jour avec le dernier `main`, contrôles relancés, fusion, build signé vérifié, notification. Sans accord : rien de plus. Branche temporaire `claude/ci-refonte` à supprimer par le propriétaire s'il le souhaite (aucune suppression faite).

## Consigne du propriétaire (27/09/2026, dans la session)
Accord de fusion sous conditions : attendre « Kalis Track 4.3.0 (L13) » sur main, réappliquer la refonte sur les SOURCES du ZIP 4.3.0 (jamais en remplaçant le ZIP), vérifier par diff que tous les fichiers de L13 sont conservés, version 4.3.1, relancer format, analyse, suite complète et captures, pousser sur main en avance rapide uniquement, vérifier le build signé, notifier.

## Fusion (27/09/2026)
- `main` contenait « Kalis Track 4.3.0 (L13) » (`1a39f91`). ZIP 4.3.0 extrait ; refonte réappliquée sur les sources (fusion à trois voies depuis 4.2.0), jamais en remplaçant le ZIP.
- Diff : les 26 fichiers modifiés par L13 sont présents ; 22 identiques à 4.3.0 ; les 4 communs (README, SUIVI, `pubspec.yaml`, `settings_screen.dart`) gardent tout L13, seuls la version, deux lignes d'assets et les en-têtes de documentation changent. Le ZIP 4.3.1 ne diffère de 4.3.0 que par les fichiers de la refonte.
- Version 4.3.1+71. CI `claude/ci-refonte` : format sans changement, analyse sans problème, suite complète 846 réussis / 13 ignorés / 0 échec, tests refonte 11/11, captures OK, Python 82/82, `verify_project.py` OK.
- ZIP : 544 fichiers, 3 832 030 octets, SHA-256 `7682fd44a7c74b651c3ef2acb2009b2fad4a952a830a9a31e378a96c02d6ca89`, `--check` OK.
- Push sur `main` en avance rapide (`1a39f91..7f07e2e`, sans --force). Build signé : run n°94 réussi — https://github.com/mikeriin/streetlift-apk/actions/runs/36327156905
- **Effet de bord** : ce push a annulé le build de L13 (run n°93, même groupe de concurrence `kalis-apk-refs/heads/main`). Le build n°94 contient tout L13 et a réussi ; la livraison L13 doit citer le run n°94 (4.3.1) comme build signé.
