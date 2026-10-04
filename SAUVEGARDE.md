# Sauvegarde CA1 (kalis_adapt 0.2.0)

Session Fable lancée le 04/10/2026 à 08:50 UTC. Base : `moteurs` d0d60018.

## Fait
- Démarrage : accès push vérifié, CA1 « en cours » (pipeline 36175e5d).
- Lectures : PIPELINE_CP, DECISIONS_CP, prompt CA1, LANCEMENTS, contrat et code de kalis_adapt 0.1.0, contrat 0.4.0 de kalis_core (§12-15), kalis_bench (trajectoires, panel, grilles, référentiel), LIVRAISON_CP1 §6-7, 189 notes de la page de relecture (manches 0 et 1).
- Mesure « avant » déjà disponible : `claude/ci-cp-a` run 37185013127, `ci-out/packages/kalis_bench/rapport.json` (kalis_adapt 0.1.0 sur les programmes de kalis_plan 0.2.0).

## Décisions de conception
- Le chemin 0.1 est gelé : un bloc sans intention (`pass1.intent`, `week.intent`) est servi à l'identique (campagne et fixture du propriétaire inchangées). Tout le nouveau comportement est sous le « mode coach » (bloc de kalis_plan 0.2 ou programme de test qui porte les champs 0.4.0).
- Mode coach : le RIR pilote la charge dans un couloir autour du pourcentage du bloc (R2-P3) ; hausse bornée à schéma égal (même emplacement) ; phase respectée (affûtage, décharge, test, compétition).
- Simulateur : modèles de vérité B et C indépendants (à écrire), exécution des techniques, tests et jour d'épreuve.
- kalis_bench : seulement des ajouts (export de trajectoire détaillé, blocs bruts, mesures à schéma égal).

## En cours
- Écriture du mode coach (lib/src/coach*.dart), premier contrôle rapide sur claude/ci-cp-b.

## Reste à faire
- Tout le code, les tests, les boucles de calibrage (panel + relecture documentée), relecture indépendante, livraison.
