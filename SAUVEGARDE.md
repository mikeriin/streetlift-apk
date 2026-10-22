# Sauvegarde KM6 (Koach 1.0.8)

Session Opus 5.5 lancée le 22/10/2026 vers 09:05 UTC (sans ligne « Lot : » ; KM6 posé « en cours » par le pilotage).
`ETAT_CP.md` : KM6 « en cours depuis 2026-10-22 09:10 UTC » (pipeline ea49b729).

## Fait
- Lecture : PIPELINE_CP, C17.37-C17.47, prompt KM6, LIVRAISON_RV1 § 5, RV1c1 § 4, KB4 § 8, KM4 § 5/§ 9, KM5.
- Pas de SDK Dart (proxy) : Dart compilé et testé sur `claude/ci-cp-a` (commits « KM6 contrôle (dev) »), comme KM5.

## Décisions
- X1 : défaut poulie 2,5 kg (min 2,5) dans `grid.dart` et `banc/verite.py` ; table non déplacée dans kalis_core
  (dite et alignée : test de kalis_bench qui compare les défauts de `kalis_plan` et de `kalis_adapt`).
- X2 : `plan('seance')` accepte `groups` (GroupSpec JSON) et renvoie `groups` recalés (tours = max des séries servies).
- X3/X7 : passe finale de `prescrire` : technique recalée (port de `coherentTechnique`), groupe de l'emplacement gardé.
- X4/X5/X6 : `_cible_charge` / test xRM (seance.py ~2290-2370, ~2750).
- X8 : `Planification.appliquer` pose `koachModule` ; raison `koach.volume_semaine` ; mesure dans `mesure_rampe`.
- Crédits : règles dans `kalis_plan` traits.dart ET `qualites/regles.py` (R8) ; tirage vertical et tractions chest 0,
  muscle-ups chest 0,5, pull-over haltère 0,5.

## Fait (suite, 10:20 UTC)
- Python : X1-X8 et crédits (regles.py R8-a, fiches 1.0.1) codés ; tests/test_km6.py (20 tests, 1 attend les
  données régénérées) ; test_km5_rampe.py mis à jour (volumes chest 17,5 / 24,5).
- Dart : grid.dart, traits.dart (chestCreditRule, kalis_plan 0.4.3), seance.dart (techniqueCoherente,
  groupesServis, _coherence, X4-X6, creditsGroupes), moteur.dart (groups), planification.dart (koachModule),
  koach_textes.dart (koach.volume_semaine), parametres.dart (1.0.8-ref.1, asset koach_params_1_0_8.json) ;
  tests koach_km6_test.dart, kalis_bench km6_credits_test.dart ; mesure X8 (mesure_module / _kmMesureModule,
  agrégats kr1_securite.py et securite_campagne.py).
- Run A (CI 39755953616) : export km1 sur kalis_plan 0.4.3, témoins adversaires, tests Dart.

## Reste
Intégrer les données du run A (donnees/reference, temoin, catalogue_infos, traces, securite_dart, témoins
adversaires) ; régénérer les fixtures Python (fixtures/generer.py, generer_banc_km2.py) ; pytest complet ;
run B (tests Dart, campagne Dart 34 parts + Python 50 parts + adversaires) ; docs ; livraison.

## Fait (suite, 12:00 UTC)
- SDK Dart 3.13.6 de conda-forge dans /opt/dart (+ /opt/dart/version), cache pub du run B0 (39758174959) dans
  /root/.pub-cache : tests et analyse Dart en local (hors ligne).
- Données du run A intégrées (reference, temoin, catalogue_infos, traces_verite, securite_dart, 6 témoins
  d'adversaires). kalis_plan : test au-dessus de la rampe (_fitVolume) pour le profil 3770 ; banc identique.
- Relecture indépendante faite (M1, M2, m3, m4, m6 corrigés ; m5, m7 dits) ; docs régénérés (PROFILS_TYPES,
  COMPARAISON_L10, MESURES, PROPRIETAIRE, campagne.json, proprietaire.json.gz) ; SOURCES § 4 (sources vérifiées :
  muscle-up et pull-over = choix raisonnés, dits).
## Reste
fixtures régénérées + pytest + tests Dart locaux ; run B (campagne) ; livraison.
