# Sauvegarde KM2c1 (portage Dart de Koach 1.0.2, kalis_adapt 1.0.1)

Base : `moteurs` 9ac79e40. Session Opus 5.5 lancée le 15/10/2026 ~15:29 UTC.

## Fait
- Delta 1.0.2 porté dans `packages/kalis_adapt/lib/src/koach/` : seance.dart (reprise par paliers, `_palierBarres`, tentatives, test xRM jour d'épreuve, Memoire.barres/barresRatees, serieFaite palier_franchi, ancre douleur seulement), modele.dart (`capacite(brut:)`, intervalle_echelle), dual.dart (brut: true x2), planification.dart (dispersion_echeance ; previsions.prevu_jour), rupture.dart (4 bornes).
- Asset renommé `assets/koach/koach_params_1_0_2.json` (= reference/params/koach_params_v1.json, 1.0.2-ref.1, 322 clés, SHA 211c9361…), parametres.dart à jour.
- Tests repointés vers `reference/fixtures/` et `koach_params_v1.json` ; moteur_11 ajouté aux boucles ; copies `fix_dart/` et `koach_params_d1.json` supprimées.
- kalis_bench : `kmCritereApparie` (critère 7 bis) dans `kmComparerAdversaires` + test ; fixtures km2 régénérées (generer_banc_km2.py) ; _evaluationPython (1.0.2) mis à jour.
- Versions : kalis_adapt 1.0.1, kalis_bench 0.4.2.

## En cours
- Contrôle (dev) sur claude/ci-cp-a (outil packages/aa_km2c1, arbre réduit).

## Reste
- Corriger la compilation / parité ; formatage.
- Campagne Dart six graines (4 parties) + assemblage ; adversaires (7 bis) ; temps.
- Relecture indépendante (sous-agent Opus).
- Docs (CHANGELOG, CONTRAT.md, INTEGRATION_KM3.md, PORTAGE_DART.md, README référence), contrôle complet, push moteurs, étiquettes, livraison, état, page de suivi, notification.
