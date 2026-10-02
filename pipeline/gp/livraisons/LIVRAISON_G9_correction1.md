# Livraison G9 correction 1 — Flammes sous la série, séries résumées

- **Version** : dev6.6.1 (pubspec 6.6.1+103 ; AAB « 6.6.1 »)
- **Commit main** : 99e4b89 · **Build signé** : run 37001536807
- **Contrôles** : CI `claude/ci-3d` run 36999089701 — formatage, analyse, 858 tests Dart, 16 tests du mode dev, tests Python, paquets, émulateur G9 a (sombre, rouge) + b (clair, violet). Rendus `visual_capture` : échec déjà présent sur main.
- **Corrections du propriétaire** (02/10/2026) : flamme mal alignée avec le texte ; pas de fenêtre pour la note mais une ligne sous la série (9 points et la flamme à sa place, petite transition) ; série n − 2 résumée en une ligne au fil de la séance, toutes résumées en fin de séance. Choix demandés : « coche = validée » et « les deux » (séance et résumé de fin).

## Ce qui change

1. **Ligne des flammes sous la série** (plus de fenêtre) : la coche valide la série avec la flamme visée déjà placée. Sous la série : la note (« 7 flammes · RIR 2 »), une ligne horizontale avec 9 points et la flamme à sa place ; toucher un point ou glisser déplace la flamme (transition animée, vibration légère) ; sous la ligne « 1 · facile », « Je ne sais pas » (discret), « échec · 10 » ; « … » : écarter / réintégrer la série. Accessibilité : curseur (« Difficulté de la série n »), augmenter / diminuer.
2. **Conseil recalculé** : corriger la note de la dernière série validée d'un exercice servi par le moteur retire le conseil qu'elle avait produit et le recalcule avec la nouvelle note (assisté : appliqué avec « Annuler » ; libre : proposé).
3. **Flamme alignée** : `FlameIcon(centered: true)` centre la flamme sur son propre dessin (taille relative gardée) ; dans les lignes résumées, colonne fixe flamme + nombre.
4. **Séries résumées** : la dernière série validée reste ouverte (n − 1), les précédentes (n − 2 et avant) passent en une ligne : « 2 · 16,25 kg × 8 reps · 🔥 7 » ; un appui la rouvre. Exercice fini (en revenant dessus), séance relue ou rouverte pour correction : toutes en une ligne, plus d'en-tête de colonnes.
5. **Fin de séance** : section « Tes séries » dans le résumé de Koach, une ligne par série, exercice par exercice.

## Tests

`test/g9_seance_test.dart` : coche → série validée avec la flamme visée, ligne ouverte, explication au premier usage, correction à 8 flammes (conseil jamais doublé), « Je ne sais pas », série 2 → série 1 résumée, réouverture ; ligne des flammes seule (10 positions, flamme centrée sur sa position, toucher, glisser de 2 à 9, « Je ne sais pas », écarter, clair et sombre) ; ligne résumée (flamme et texte alignés à 1 px, flammes 1, 5, 10). Adaptés : `l7_koach_screens_test` (dont texte 200 % à 320 px), `l4b_seances_test`, `ui_refactor_test`, `history_readonly_test`, `history_correction_test`. Émulateur : séries 1 à 3 validées, captures `08_series` (séries résumées) et `12_fin_series` (« Tes séries »).

## À tester par le propriétaire

Une séance : coche une série, corrige la flamme en touchant ou en glissant sur la ligne ; enchaîne 3 séries et vérifie que la série n − 2 passe en une ligne ; touche une ligne résumée pour la rouvrir ; fin de séance : « Tes séries ».

## Limites

- La ligne ouverte reste celle de la dernière série validée jusqu'à la sortie de l'exercice ; en revenant sur un exercice fini, tout est résumé.
- Sans flamme visée (consigne sans RIR, hors moteur), la série est validée sans note : la ligne affiche « Note ta série ».
- Contenu sportif non relu par un professionnel diplômé.
