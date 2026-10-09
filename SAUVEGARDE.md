# Sauvegarde CI1e

Base : main bd1f0c97 (dev6.9.3). Version visée : dev6.10.0 (6.10.0+112).
Branche CI rapide : claude/ci-ci1e-rapide (essai 3 : suite complète verte ; essai 4 : constats de relecture).

## Fait
- lib/imported_program.dart : annotation 0.4.0 (blocs ≤ 6 sem. `legacy-programme-v33/S<n>`, intentions, BlockIntent, SeasonPlan, échéance fin S40, emplacements stables, RIR, tests max, 1RM (une ligne par tentative), clusters) ; migration des ajustements 6.9.3 (convertLegacyEntries).
- session_adapt_store / evolution_store / plan_store / plan_screens / program_screens / season_view : exclusions levées, bloc suivant calibré à la fin d'un bloc du programme, carte « Ton programme d'origine ».
- lib/program_origin.dart : filets C11.2.
- Tests : test/ci1e_programme_40s_test.dart ; integration_test/koach_ci1e_test.dart (cible émulateur ajoutée à tools/ci3d_drive.sh, ci-3d.yml 55 min).
- Relecture indépendante faite (17 constats ; 1-16 traités sauf 15 (coût) et 17 (profil schéma 2), notés pour la livraison).

## Reste
- Essai 4 vert, puis contrôle complet claude/ci-3d (émulateur), main, build signé, livraison, état, suivi, notification.
