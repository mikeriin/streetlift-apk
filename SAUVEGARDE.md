# Sauvegarde KM2 (portage Dart de Koach 1.0.1)

Base : `moteurs` 17df8ca. Session Opus 5.5 (tâche moteurs), lancée le 10/10/2026 21:03 UTC.

## Fait
- `packages/kalis_adapt/lib/src/koach/` : bibliothèque `koach.dart` à parts (outils, numerique, modele, moteur écrits par la session ; securite, seance, planification, rupture, adherence, dual écrits par des sous-agents Opus). Conventions : `reference/PORTAGE_DART.md`.
- Pas de SDK Dart dans la session (storage.googleapis.com et pub.dev refusés par le proxy) : compilation et tests seulement en CI (commits « KM2 contrôle (dev) » sur `claude/ci-cp-a`, arbre réduit).

## Parité
- 10/10 21:58 UTC : 27 tests de parité verts en CI (run 38089329164) : numerique, moteur_1 à 10, planification_1 et 2 ; analyse sans remarque. Commit local d2fd62fd (branche moteurs, pas encore poussé).
- Outils : /tmp/claude-0/km2/dev.sh (commit de contrôle réduit sur claude/ci-cp-a, paquet aa_km2 qui formate), ci.sh (lecture de ci-out).

## En cours
- Façade (crochets), validateur, banc Dart.

## Reste
- Façade : crochets d'extension (allègement, modulation, bras, forme), événement `reference`, validateur Dart branché.
- Banc Dart (kalis_bench) : meneur Koach, critères contre 0.3.1, adversaires, temps.
- Docs INTEGRATION_KM3.md, CONTRAT 1.0.0, version 1.0.0, étiquettes, livraison.

## Résultats (11/10, ~01:30 UTC)
- Banc Dart = référence Python : campagne graines 0-1 (1440 saisons, run 38098481488 sur ci-cp-a) redonne exactement les critères 1-4, 6, 7 de criteres_km1.json (3,98 % ; 0,95 % ; 4,856 ; 90,38 % ; 0,9409 ; 0 violation). Critère 5 C13.11.2 sur g0-1 : 13,9 pts ; temps VM Dart : série 30,6 ms max (p95 1,1), replanification 0,20 s max.
- Adversaires KM1 rejoués : Koach sans extension pire 0,798913 (= KM1), Koach complet 0,747 ; témoin 0,0. Recherche 300 : pire Koach 0,7699 ; recherche 3000 et Koach complet 600 en cours (ci-cp-b).
- Campagne graines 0-5 (4320 saisons) : 4 parts calculées (runs sur ci-cp-a/b), copies dans /tmp/claude-0/km2/parts ; assemblage en cours.
- Reste : critère 5 sur g0-5, docs (LIVRAISON_KM2, données de campagne dans le dépôt), contrôle complet, push moteurs, étiquettes kalis_adapt-v1.0.0 et kalis_bench-v0.4.0, ETAT/page/notification.
