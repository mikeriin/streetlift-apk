# Livraison G9 correction 3 — Un mot par flamme

- **Version** : dev6.6.3 (pubspec 6.6.3+105 ; AAB « 6.6.3 »)
- **Commit main** : 111ce6d · **Build signé** : run 37022213889
- **Contrôles** : CI `claude/ci-3d` run 37019042515 — formatage, analyse, tests Dart, tests du mode dev, tests Python, paquets, émulateur G9 a + b, tous verts (rendus `visual_capture` : échec déjà présent sur main). Le propriétaire demandait un build direct sans tests ; le push sur main sans contrôles a été refusé (règle du pipeline), d'où ce passage rapide par la CI.
- **Demande du propriétaire** (02/10/2026) : « trouve 10 mots qui correspondent aux 10 flammes […] Il apparaît aussi dans le résumé des séries au lieu du 1 à 10 ».

## Ce qui change

- Mots : 1 Léger, 2 Facile, 3 Tranquille, 4 Modéré, 5 Soutenu, 6 Appuyé, 7 Dur, 8 Intense, 9 Limite, 10 Échec (`kFlameWords`, `flameWord`, `flameTrackText` dans `lib/adapt/flame_track.dart`).
- Ligne des flammes : « Dur · RIR 2 » au lieu de « 7 flammes · RIR 2 ».
- Séries résumées (séance et « Tes séries ») : le mot à la place du chiffre ; libellé d'accessibilité : mot, puis flammes et RIR.

## Limites

- Sous la ligne, les repères restent « 1 · facile » et « échec · 10 » (le mot de la flamme 1 est « Léger ») : à harmoniser au prochain passage si tu veux.
