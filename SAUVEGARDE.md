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
