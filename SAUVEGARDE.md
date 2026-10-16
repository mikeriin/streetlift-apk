# Sauvegarde KS1c2

## Fait
- Lot « en cours » (pipeline dc97cc9).
- Cause : `kalis_plan/lib/src/coach/structure.dart` `_buildTyped` : `pushEndurance`/`pullEndurance` et replis de force n'ajoutent rien sans repère (`dipMax`, `pushMax`, `pullMax` = 0). Reproduit : profil `kalis_bench/profiles_ks1c2/ks1a_street_5050.json` (J4 poussée E : préparation, tronc, mobilité).
- Correction : `_ensurePrincipal` (+ `_principalFallback`, promotion d'un porteur secondaire, changement de type avec `plan.joint_limitation`/`plan.equipment_missing` dans `split.reasons`, `_Builder.dayReasons`), note `reps_calibrate` (prescribe + texts). Version 0.4.2 (pubspec, version.dart, en-têtes docs générés). Docs : CONTRAT § 12.17, STRUCTURE_SEMAINE § 5, NOTES_COACH, CHANGELOG.
- Banc : `lib/src/principal_criteria.dart` (critère deux niveaux, grille 6×3×4 par base, PrincipalMeasure), branché dans `runStructureBench` / `structureReport` ; test `test/ks1c2_test.dart`.
- Runs dev (claude/ci-cp-b) : après correction 0 écart (34 profils, grille 576 profils / 8 928 jours) ; avant 489 jours en défaut ; squelettes des 34 profils identiques à 0.4.1 ; tests kalis_plan (ks1c2, coach, structure, docs, smoke) et banc (ks1c2, structure) verts (run 38983629445).

## Reste
- Tests du changement de type (poignet, genou, sans barre fixe) à vérifier ; format (patch CI) ; version kalis_bench (0.5.3 ou suivante libre, KR1) + CHANGELOG/docs banc ; relecture indépendante (sous-agent Opus) ; contrôle complet sur claude/ci-cp-b ; push moteurs, étiquettes ; livraison, état, page de suivi, notification.
