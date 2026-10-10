# Sauvegarde CI1h

Base : main b7996b3f (dev6.11.1). Branche de mise au point : claude/ci-ci1h-rapide (workflow rapide.yml).

## Fait
- Défaut 1 : `ImportedProgram.fixedLoad` (« semaine|emplacement » → (exercice, kg)), `importedFixedLoadKg` (exception « lesté ou PdC ») ; `fixedLoadItem` / `fixedLoadAdvice` (lib/adapt/session_adapt.dart) ; contrainte dans `_adaptPrescribe` (`_fixedConstrain`) et `adaptAfterSet`.
- Défaut 2 : `adaptPlanDay`, `adaptPlannedSession` (un seul calcul ouverture/prévision) ; `_adaptReprescribe` au jour prévu sans bilan ; `_adaptNextGoal` → séance visée (S, J, date) ; écran de fin : ligne « Prévision… » et « — S14 · J6, samedi 17/10 ».
- Textes : `adapt.load_held` causes `program`, `program_bodyweight`.
- Test : test/ci1h_charge_fixe_test.dart.

## En cours
- Run rapide essai 1.

## Reste
- Corriger jusqu'au vert, version 6.11.2, docs, contrôle complet claude/ci-3d, main, build signé, livraison, état, page de suivi, notification.
