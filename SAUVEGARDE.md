# Sauvegarde KR1

Base : `moteurs` eae158b8. Arbre = `moteurs` modifié (sans `.github`) ; `kr1_dev/` = workflow et scripts de mise au point (claude/ci-cp-a).

## Fait
- 12:00 UTC ligne « en cours » poussée (pipeline d3b3b7d).
- kalis_bench : `readSeasonJsonAll()` (34 profils) pour km1/km2/adversaires ; `tool/kr1_securite.py` (agrégat sécurité des parts).
- Mesure sur les saisons figées 0.3.1 (parts KM2c2, run 38853167917) : critère 7 = 0 ; « retour_ecrit » 1 330 (C13.10.1 : classés à part).
- Run A poussé (79a26ae5) : export KM1 34 profils, campagne vivante 6 graines (6 parts), adversaires vivants (6 jeux).

## En cours / reste
- Lire run A ; régénérer fixtures Python (generer.py, generer_banc_km2.py) sur les données neuves ; parité Dart ; campagne 100 graines ; corrections si violations ; relecture ; publication.

## Décisions
- Critère dur KR1 = violations réalisées hors « retour_ecrit » (C13.10.1) : servi_tests_faits {deja_initial, aggrave, introduit} + plan_module {aggrave, introduit} + douleurs + hausses ; retour_ecrit publié à part.

## 13:10 UTC
- Run A lu (run 38898708985) : export 34 profils OK (937 s) ; campagne vivante 6 graines : 8 saisons plantées (ks_test_ppl6, séances manquées : élargissement « rien » répété sans borne → sd 20, NaN/Overflow, Python aussi) ; critère 7 = 0 ; retour_ecrit 2 242 ; plan initial 0.4.1 : 0.
- Correction Koach 1.0.4 (Python + Dart) : `elargir` plafonné à l'a priori (`variances_a_priori`) ; tests Python (test_rupture), Dart (koach_elargir_test.dart) ; params version 1.0.4-ref.1 (SHA 2d023854…), asset koach_params_1_0_4.json ; CONTRAT note 16/10, SOURCES.
- Données : donnees/reference et temoin régénérés (34), anciens → reference_0_3_1, temoin_0_3_1 ; securite_dart régénéré ; EXCEPTIONS_CONNUES vidé ; fixtures Python + km2c2 + banc km2 (avec ks_test_ppl6 séances manquées) régénérées ; pytest local 263 OK.
- km2_banc_test : égalité stricte saison vivante = saison Python.
- Run B poussé : P0 tests, P1-17 campagne Dart 100 graines (groupes de 6), P21-24 campagne Python 0-5.

## 13:20 UTC
- Vue « réalisée » (séances manquées vidées) ajoutée Python (`vider_manquees`, `securite_saison`) + Dart (`kmViderManquees`, `kmSecuriteSaison`) ; outils kr1_securite (vue realise), kr1_comparer (parité saison par saison).
- Run B annulé ; run C poussé (1536d03f) : P0 tests, P1-17 campagne 100 graines, P21-24 Python 0-5, assemblage + parité.
- Versions : kalis_adapt 1.0.3, kalis_bench 0.5.3 ; CHANGELOG des deux ; CONTRAT K ; INTEGRATION_KM3 ; CHANGEMENTS_1_0_4.md.
- Reste : lire run C ; adversaires (6 jeux) sur Koach 1.0.4 ; critères 27 profils (parts filtrées) ; README référence ; contrôle complet ; relecture ; publication.
