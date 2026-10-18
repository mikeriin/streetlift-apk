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

- Run A (39079886275) : parité 15 fixtures + km2c2 + banc 7 saisons verts. Run B (39080305867) : analyse OK, 119 tests koach verts dont les 23 de test_km1c4_douleur portés.
- Nombre de clés réel : 345 (6+339) ; docs de référence corrigées (346 par erreur).
- Relecture indépendante (Opus) : 0 bloquant ; M2 textes neutres faits ; m1 journal `appelsVraiTest` ajouté ; docs, CHANGELOG kalis_adapt 1.0.4 ; versions 1.0.4 / 0.5.6.
- 3 fixtures du banc ajoutées (autres_08 ref b47, ks_01 douleur_epaule b38, street_03 manquées b57).
- Run C (commit a2f7d170 sur claude/ci-cp-a) : campagne Dart 34 parts + 6 jeux d'adversaires, comparaison saison par saison au run Python 39041787498 (outil kalis_bench/tool/km2c3_comparer.py). Scripts de dev : /tmp/claude-0/dev (DEV_KM2C3.sh, DEV_ASSEMBLER.sh, ci-paquets.yml) — copies dans SAUVEGARDE_DEV/.

## Reste
- Lire run C ; run D : format + analyse + tous tests (kalis_adapt, kalis_bench km2 avec 10 fixtures).
- docs/CRITERES_KM2C3.md, docs/data/km2c3/, CHANGELOG kalis_bench 0.5.6.
- Push moteurs, étiquettes kalis_adapt-v1.0.4 et kalis_bench-v0.5.6, contrôle complet ci-cp-a, livraison, ETAT_CP, page de suivi, notification.

## Point au 18/10 ~03:00 UTC
- Run C (39080556198) : 90 600 saisons Dart, critère 7 = 0, 0 plantée ; run E (39090980389) : 90 600/90 600 saisons identiques au Python (run 39041787498), 6 jeux d'adversaires identiques à la référence Python recalculée.
- Commit local moteurs 9c81a201 (pas encore poussé) ; contrôle complet poussé sur claude/ci-cp-a (d4a30303).
- Reste : contrôle vert → push moteurs (rebase), étiquettes, livraison (pipeline + projet), ETAT_CP, page de suivi, notification.

## Terminé (18/10) : moteurs 9c81a201, étiquettes kalis_adapt-v1.0.4 et kalis_bench-v0.5.6, contrôle complet 39091818772 vert, livraison (pipeline + projet), ETAT_CP livré, page de suivi v58. Reste : notification.
