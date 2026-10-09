# Sauvegarde CI1e

Base : main bd1f0c97 (dev6.9.3). Version visée : dev6.10.0 (6.10.0+112).

## Fait
- lib/imported_program.dart : annotation 0.4.0 du programme importé (blocs ≤ 6 semaines `legacy-programme-v33/S<n>`, intentions de semaine, BlockIntent, SeasonPlan, échéance fin S40, emplacements stables `j<J>-<exercice>`, RIR, tests max, test 1RM, clusters).
- session_adapt_store : adaptPlaceOf par bloc annoté, couche généralisée (journées déplacées), séances d'avant 6.10.0 relues sur le nouveau bloc (_upgradeLegacyAdapt), échéance donnée au moteur (adaptProfile), saison, tests reportés.
- evolution_store : plus de garde jour pour jour, résultats de tests reportés au profil, déblocage par blockIndex.
- plan_store / plan_screens / program_screens : bloc suivant du moteur calibré à la fin d'un bloc importé ; carte « Ton programme d'origine ».
- lib/program_origin.dart : sauvegarde d'origine (section programOrigin + copie locale), retour, export.
- Branche CI rapide : claude/ci-ci1e-rapide (scripts dans la session).

## Reste
- Corriger compilation / tests existants (G9, G10, CI1c, CI1b) qui encodent D5.10.
- Nouveau test test/ci1e_programme_40s_test.dart (tests obligatoires) + émulateur.
- Relecture indépendante, contrôle complet claude/ci-3d, main, build signé, livraison.
