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

## Étape : mode coach écrit, vérités B et C (truth.dart)
- Moteur : coach.dart, coach_advice.dart, skills.dart, results.dart, event_day.dart écrits ; session/advise/review/replay/engine branchés.
- CI rapide « mode coach, compilation 2 » (be3f539b) poussée, résultat à lire (ci_get.sh fmt).
- truth.dart : TruthKind a/b/c écrit, pas encore compilé.
- Reste : runner (exécution des techniques, rôles, qualité, profil mis à jour par testResults), policy (RpeCoachPolicy, legacy), injecteur de techniques, bench (trajectoires A/B/C, export riche), tests, docs, calibrage, fin de lot.

## Étape : simulateur riche, export des trajectoires
- CI « compilation 2 » : tout vert sauf la ligne de version de PROPRIETAIRE.md (régénérée) → le chemin 0.1 est identique.
- Écrit : runner (exécution des techniques, rôles, parties, propreté, tentatives, résultats de test reportés au profil), policy (CoachAwarePolicy, RpeCoachPolicy), sim/coach_metrics.dart, truth B/C ; kalis_bench : trajectory.dart (vérité, mesures coach), trajectory_export.dart (export riche), report.dart (trajectoire racontée = vérité B, A et C mesurées à côté).
- Moteur : couloir élargi (SlotMark.easy, coachCorridorWiden 0,025, max 0,15) ; premier passage à un schéma ≤ charge écrite ou +10 % ; douleur/échec : aucune hausse vs dernière séance.
- Reste : lire les trajectoires, corriger ; tests (invariants coach, propriétés), injecteur de techniques, campagne street (CLI), docs, calibrage, fin de lot.
