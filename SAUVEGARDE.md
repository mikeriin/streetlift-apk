# Sauvegarde KB2 (2e session, 18/10/2026)

Fait :
- `lib/koach1_store.dart` : `kKoachBasculeAutorisee = true`, `kKoachCritere10`, `KoachEngineData.openedOn` (clé `kb2_ouverture_v1`), `koachTakeoverPlanned()` / `koachTakeoverWeek()` (semaine de la première séance non faite ≥ max(firstShown, firstWeek du plan, semaine du jour, semaine d'ouverture) ; prise de main quand son lundi est passé) ; dates 23/11 retirées (`koachBasculeDate`, `kKoachInstallLimite`…).
- Carte Koach (textes), inspecteur (ligne bascule + critère 10), écran d'attente `KoachTakeoverDialog` / `awaitKoachTakeover` appelé par `openProgramDay` (45 s puis « Ouvrir la séance »).
- Tests : `test/kb2_prise_de_main_test.dart`, `test/flutter_test_config.dart` (bascule fermée par défaut pour les tests d'avant), tests de version 7.2.1, KM3/KB1 mis à jour ; cible `integration_test/koach_kb2_test.dart` ajoutée à `tools/ci3d_drive.sh` ; cibles d'avant jouées bascule fermée.
- Version 7.2.1+141.

En cours : formatage distant (claude/fmt-kb2), puis contrôle complet claude/ci-3d.
Reste : CI verte, SUIVI_PROJET.md, publication main, build signé, livraison, ETAT_CP, page de suivi, notification.
