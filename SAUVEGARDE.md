# Sauvegarde KM2c3 (portage Dart de Koach 1.0.5)

Base : `moteurs` ba1e5093. Session Opus 5.5 (cse_01RgefQJuvkg7SCNCJUPJrgt), démarrée 17/10/2026 23:21 UTC.

## Fait
- securite.dart : episode, sensible, sensibles, geneRecente, règle 4 dans conduite.
- rupture.dart : elargissement_vers_a_priori (défaut, branche « rien », borne) ; `elargissement_rien_de_special` gardée dans défauts/bornes/fichier comme la référence (le fichier de paramètres doit garder son SHA d8a492b7, que les fixtures portent) — écart au texte de PORTAGE_DART à dire dans la livraison.
- modele.dart : elargir(part) 1.0.5 ; test koach_elargir_test.dart réécrit.
- seance.dart : rampe du réalisé, règle 3 bis, budgets du jour, réserve d'échauffement, expoJour.
- parametres.dart + asset koach_params_1_0_5.json ; koach_parametres_test (346 clés, SHA) ; tests repointés ; fix_dart/ et koach_params_d4.json supprimés.
- truth.dart : _painKnown remis à faux (fiche, tendon) + getter painKnown, setForTest ; test km2c3_verite_test.dart.
- Fixtures régénérées : kalis_bench/test/fixtures/km2 (4 changent), kalis_adapt/test/fixtures/km2c2.

## En cours / reste
- Contrôle (dev) sur claude/ci-cp-a : format, analyse, tests.
- Port des tests test_km1c4_douleur.py en Dart ; fixtures complémentaires (couverture du delta).
- Versions (kalis_adapt 1.0.4, kalis_bench 0.5.6), docs, campagne Dart 90 600 saisons, critères, relecture, livraison.
