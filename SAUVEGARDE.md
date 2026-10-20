# Sauvegarde KM5 (Koach 1.0.7 : la rampe de volume ne coupe jamais sous l'écrit)

Session Opus 5.5 (20/10/2026, depuis 16:36 UTC). Base : `moteurs` 91d8ea70. Pas de SDK Dart en session (Dart sur la CI `claude/ci-cp-a`).

## Fait
- Référence Python 1.0.7 : `seance.py` (`_ecrites` = sets − koachVolume, `_compter_ecrit`, écrit du programme de la semaine, plafonds max(L, E), `_plan_retour` réécrit : seuls les ajouts de Koach sont bornés, rang puis ligne la plus tardive ; `_retour_gradue` : raison `koach.ajout_borne`, rampe tendineuse inchangée) ; `rupture.appliquer_allegement` et bras A (banc) tiennent `koachVolume` ; paramètres `1.0.7-ref.1`, trois clés `retour_*` retirées.
- Banc Python : `securite_banc.filtrer_volume_ecrit` (nouvelle définition volume_trop_vite : servi > max(limite, écrit)), `securite_saison` (vues de Koach filtrées, `ancienne_definition`), mesure `sous_ecrit_items/series`, `ajouts_bornes(_series)` ; agrégats `securite_campagne.py`, `kalis_bench/tool/kr1_securite.py`.
- Tests Python : `test_km5_rampe.py` (15, scénarios a, b, c), `test_securite_regles.py` (retour gradué réécrits), `test_campagne.py` ; `test_km4_retour.py` retiré.
- Dart en cours : `seance.dart` (porté), `rupture.dart`, `dual.dart` (koachVolume), `parametres.dart` (1.0.7, asset `koach_params_1_0_7.json`, 344 clés), `koach_textes.dart` (`koach.ajout_borne`).

## Reste
- Dart : tests km5 (port de test_km5_rampe.py), banc Dart (filtre de la définition, mesure, `kmSecuriteSaison`), fixtures (generer.py, generer_banc_km2.py, km2c2), docs (CONTRAT, CHANGEMENTS_1_0_7, SOURCES, CHANGELOG, CRITERES_KM5), versions `kalis_adapt` 1.0.6 / `kalis_bench` 0.5.8.
- CI : run tests (part 0) puis campagne complète unique (Dart 34 parts + Python 50 parts + adversaires 6 + comparaison).
- Livraison, étiquettes, ETAT_CP, page de suivi, notification.
