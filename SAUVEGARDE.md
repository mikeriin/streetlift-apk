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
