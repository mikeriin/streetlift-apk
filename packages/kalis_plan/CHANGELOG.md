# Journal des versions de kalis_plan

## 0.1.0

Première version (lot G4 du pipeline « Génération et progression »).

- `KalisPlan` réalise `PlanEngine` de kalis_core 0.1.0 : `createPass1`, `review`, `variants`,
  `createPass2`, `nextBlock`, `restructure`.
- Passe 1 : optimisation sous contraintes dures, note explicite à 14 composantes (sécurité puis
  qualité), construction gloutonne avec anticipation, recuit simulé seedé, descente, départage par
  hachage FNV-1a ; « Autre proposition » par la graine.
- Revue, variantes (plus facile, équivalente, autre matériel, toutes les compatibles triées par
  proximité) et régénération à diff minimal avec verrous.
- Passe 2 : séries, plages, flammes visées, repos, charges de départ prudentes « à calibrer »,
  semaines d'introduction, de montée, de décharge et de test.
- Blocs glissants (`nextBlock`) et restructuration d'une séance, d'une semaine ou de la fin du bloc.
- `PlanInspector` (note relue, contraintes dures revérifiées, mesures), `lib/testing.dart` (profils
  aléatoires seedés), `lib/report.dart` (rapports), ligne de commande `dart run kalis_plan:plan`,
  simulateur `bin/kalis_plan_cli.dart`.
- Validation : `docs/` (profils types, comparaison au générateur L10, non-ressemblance, mesures).
