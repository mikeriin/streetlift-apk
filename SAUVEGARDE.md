# Sauvegarde KM2c2 (portage Dart de Koach 1.0.3, kalis_adapt 1.0.2)

Base : `moteurs` 2d3a5766. Session Opus 5.5 lancée le 16/10/2026 (message sans « Lot : », KM2c2 seul lot moteur « à faire »).
Pas de SDK Dart (proxy) : mise au point sur la CI `claude/ci-cp-a` (commits de contrôle « KM2c2 contrôle (dev) »).

## Fait
- Delta porté (non compilé) : modele.dart (classe Fiabilite, appels dans _serieForce, capacite/capaciteDuJour(brut), elargissement), planification.dart (tirer : S ← DSD), seance.dart (probaReussite(brut), _cibleCharge, _bornesHausse, _rampe, _palierBarres, _tentative), rupture.dart (bornes, figées, fiabilite.p), moteur.dart (posterior.fiabilite).
- Asset koach_params_1_0_3.json, parametres.dart (1.0.3-ref.1, 338 clés, SHA d129a4e9…), version 1.0.2.
- Tests repointés (fixtures/, koach_params_v1.json), 12 fixtures moteur, test koach_fiabilite_test.dart, test des bornes 1.0.3 ; fix_dart et d2 supprimés.
- kalis_bench : fixtures km2 régénérées (generer_banc_km2.py, 1.0.3) ; _evaluationPython 1.0.3.

## Reste
- Contrôle dev (format, analyse, tests), corrections ; campagne Dart 6 graines ; 6 jeux d'adversaires ; relecture Opus ; docs (CHANGELOG, CONTRAT, INTEGRATION_KM3, PORTAGE) ; kalis_bench version/doc ; push moteurs, étiquettes, contrôle complet ; livraison.
