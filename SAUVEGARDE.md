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

## 13:25 UTC
- Publication du run B bloquée (assemblage Python sans parts, jusqu'à 120 min) : run C annulé par un run vide D (même groupe) ; run E (38906984200, groupe de concurrence propre `ci-kr1-<sha>`) lancé avec tout le travail. DEV_ASSEMBLER gardé (Python seulement si ≥ 5 400 saisons, timeouts).
- Au contrôle complet final : remettre ci-paquets.yml de moteurs (groupe ci-paquets-ref : attendra D).
- Docs : README référence (1.0.4), note dans CRITERES_KM2C2.md.

## 14:17 UTC
- Run E : P0 → parité Dart OK (kalis_adapt 345 tests dont parité, seule docs PROPRIETAIRE.md (version) en échec → corrigé) ; kalis_bench km 126 OK (égalité stricte saison vivante, fixture ks_test_ppl6). Patches de formatage : 31 lignes adapt, 14 bench (à appliquer depuis ci-out).
- Campagne en cours.

## 16:07 UTC — run E encore en cours (groupes 5 et 17 partis à 14:09).

## 16:35 UTC
- Run E : --partie 1/1 = campagne entière → pas de parts (seulement critères par groupe). Témoin lu limité à 16 graines (critère 6 apparié seulement graines 0-15).
- Run F poussé (eff6083c) : 17 groupes × 2 parts (saisons gardées), adversaires (P40), Python 1/8 et 2/8 (P41-42), critères 34 et 27 profils (DEV_FILTRE.py), parité saison par saison.

## 17:27 UTC — E (publication en file) et F en cours.

## 18:27 UTC
- Relecture (sous-agent Opus) : 0 bloquant, 3 majeurs, 13 mineurs. Traités : M2 (vue realise_apparie = contre le plan écrit aux mêmes manquées, Python+Dart), M3 (securite dans les fixtures du banc + test Dart ; test Python vider_manquees), M1 (docs corrigées + test a posteriori réel ; élargissement uniforme recommandé au pilotage), mineurs docs (CONTRAT K.5, README, koach.dart, PORTAGE_DART, INTEGRATION_KM3, docstring), outils (comparer NaN/inf/doublons ; securite v2 : critère 7, réalisée appariée, retour à l'écrit, réalisée vs initial).
- Run E (bc06f78) : Dart g0-5 34 profils = Python (critères 1-4, 6, 7, secondaires identiques), 0 plantée ; formatage appliqué.
- F en cours (sans realise_apparie) → il faudra un run G (100 graines) avec la vue appariée + contrôle complet.

## 18:58 UTC — G (6f8ce32) et contrôle préalable (6d1e71d, workflow standard) poussés ; F en cours. Scripts : /tmp/kr1/ctrlcommit.sh (kr1_dev/).

## 19:54 UTC — GitHub Actions bloqué ~19:00-19:45 (tout en file). Saisons figées 0.3.1 déplacées dans kalis_bench/docs/data/kr1/saisons_figees_0_3_1 (C17.19.3 : arbre de kalis_adapt +1,4 Mo seulement) ; docs mises à jour.

## 20:14 UTC — Run F publié (136793c) : 90 600 saisons, 0 plantée ; critère 7 = 72 sur 100 graines (4 aggravations, 59 poussées de douleur, 9 volume_trop_vite introduits) — 0 sur graines 0-5 ; adversaires 7 tenu partout, 7 bis 24/22/22/21/22/20 (≥ figé) ; critères par groupe (bruit) calculés ; parité saison par saison : seuls écarts first_under (ordre d'un set Python) → comparer corrigé (multiensemble). À faire : causes des 72 (run G liste les saisons).

## 20:28 UTC — Cause des 9 volume_trop_vite introduits (100 graines) : retirer_retours_a_l_ecrit indexait les semaines sans tronquer les blocs interrompus (blockWeeks) → corrigé Python+Dart (bench), test test_retour_a_l_ecrit_apres_un_bloc_interrompu ; les 9 deviennent retour_ecrit (vérifié en Python sur les 9). Restent : 59 poussées, 4 aggravations (saisons à identifier par G).

## 21:21 UTC
- Run G lu (f8abee6) : critère 7 = 72 (= 63 après reclassement des 9 volumes) ; réalisée appariée 259 646 (fluctuations du volume servi) ; P0 : 346 + 132 tests verts.
- Causes établies (tests reference/tests/test_kr1_violations.py : 4 mécanismes) : poussées (tendon réactif, gêne 2-3 < douleur_seuil 3, exposition remontée : fin de reprise 84 j, retour après manquées, pas de reprise sans arrêt) ; aggravations (hausse de charge des dips sous douleur 5 au poignet, contrainte seulement à 5).
- Décision : pas de correction de méthode de la conduite sous douleur dans KR1 (remesure + méthode → lot Koach) ; livrer « critère dur non tenu » + recommandation.
- Parité saison par saison (échantillon 20 saisons Python local vs parts Dart G) : 20/20 identiques.
- Fixture banc 7 (autres_08 changement a 87) ; pytest 270 OK.

## 21:23 UTC — docs CRITERES_KR1.md + docs/data/kr1/ ; README référence ; attente du contrôle préalable avant le contrôle final.

## 21:52 UTC
- Contrôle préalable : paquets verts (1 h 53).
- Commit local moteurs 597c10b (arbre 11de449e) ; contrôle complet final poussé (ba88acd5, workflow standard).
- Brouillon de livraison : kr1_dev/LIVRAISON_KR1_brouillon.md.
- Reste : attendre le contrôle ; rebase/push moteurs ; étiquettes kalis_adapt-v1.0.3, kalis_bench-v0.5.3 ; livraison (pipeline + projet), DECISIONS (section KR1), ETAT (livré — critère dur non tenu), page de suivi, notification.

- 21:58 UTC : contrôle final run 38972216385 (ba88acd5) en cours ; brouillons DECISIONS (decisions_kr1.md) et section de page (page_section.html) prêts.

- 00:54 UTC (17/10) : LOT TERMINÉ. Contrôle final run 38972216385 vert (arbre identique à moteurs 597c10b7). moteurs poussé (eae158b8..597c10b7), étiquettes kalis_adapt-v1.0.3 et kalis_bench-v0.5.3 créées. Pipeline da4fa5e8 (livraison, DECISIONS § KR1, ETAT livré — critère dur non tenu). Projet claude/LIVRAISON_KR1.md écrit. Page de suivi version 55.
