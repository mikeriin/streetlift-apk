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

## Étape : campagne street, corrections du moteur d'après les premières trajectoires
- kalis_bench : campaign.dart (campagne street : 17 profils × graines × 3 vérités × 4 politiques, isolats ; campaign_seeds.txt pour les essais), profils/<clé>.json exportés (fixtures de kalis_adapt : test/fixtures/street_profiles.json.gz).
- Moteur (mode coach) : notes ≥ 3 en réserve lues comme bornes (coachCensorRir 3, sans gonflement par le biais) ; biais de note appris sur les tests (RatingModel.learn) ; maintiens servis à la part écrite, plafonnés à 80 % du maximum du jour (_holdSafe) ; répétitions sans charge : garde à 2 en réserve (_repsSafe), plage étendue et séries au ressenti quand c'est trop facile ; plafond d'effort : une note au plafond ne compte pas comme trop dure, des répétitions manquantes si ; allègement gardé le reste de l'exercice ; effort affiché = effort attendu quand la charge est retenue ; premier passage à un schéma ≤ max(charge écrite, +10 % de la plus lourde barre récente) ; tentatives lues comme bornes ; troisième barre à la cible seulement pour l'objectif « record ».
- Simulateur : sim/techniques.dart (injecteur), SimProgram.transform.
- Mesures rapides (2 graines) : échéance 97 % du maximum du jour (0.1 : 90 %, coach RPE : 92 %) ; écart d'effort 1,6 à 2,3 (0.1 : 1,1 à 2,3) → à améliorer en A et C.
- Reste : tests coach (fixtures prêtes), docs, calibrage panel, fin de lot.

## Étape : tests du mode coach, dérive du panel
- Empreintes des cinq grilles vérifiées (identiques à docs/PANEL.md, concaténation 7d337a2e…).
- Dérive du panel (ancres p08_a et p14_c, un appel Opus par école) : (a) = 1 / 1 / 1 / 1 ; (c) = 8 (force) / 8 (calisthénie) / 9 (hypertrophie) / 8 (santé) → pas de dérive.
- Tests : test/coach_test.dart, coach_properties_{0..3}_test.dart (10 240 journaux coach), fixtures street_profiles.json.gz, invariants C1 à C4 (support.dart).
- Moteur : plafond des notes appris (RatingModel.topSaid), courbe apprise sur les séries ≤ 3 en réserve, série repère (coachProbeDays 14), techniques au-dessus du niveau → séries classiques (standardEquivalent), coherentTechnique, clampLocked, pas de test un jour de bilan nettement bas, exercices à l'élastique : plage gardée.
- Outil panel : /home/claude/wt/tools/panel.py (prepare / collect).

## Étape : invariants coach presque tous tenus, réglage des notes
- Propriétés coach : 10 240 journaux, 1 cas restant (vagues après échec) corrigé, à confirmer.
- coachCensorRir = 2 retenu (essai) : écart d'effort A 0,91 / B 1,16 / C 1,75 (0.1 : 1,18 / 2,43 / 1,72) ; échéance 96 / 95 / 96 % du maximum du jour (0.1 : 91 / 89 / 90) ; mesures rapides à 2 graines.
- Ajouts : effort attendu affiché (maintiens dans les deux sens), séries repères chargées, reprise graduelle (coachBreakDays 14, −20 % de séries la semaine du retour), étapes de figure dans le tableau de la figure, journal des décisions allégé.
- Brouillon du § 11 du contrat : /home/claude/wt/tools/contrat_11.md (dans la sauvegarde ci-dessous, à reporter dans CONTRAT.md).
- Prochaine étape : première passe complète du panel (20 appels Opus), boucles, docs, fin de lot.

## Étape : avant la première passe du panel
- Export des trajectoires : tableau d'une figure visée travaillée par ses seules étapes (planche) ; note « marge prévue » seulement quand la garde a réduit la série.
- kalis_bench 0.1.2 (CHANGELOG, CONTRAT, CRITERES).
- Prochaine étape : passe 0 complète du panel, boucles de calibrage.

## Étape : passe 0 du panel faite, boucle 1 en cours
- Passe 0 (68 couples) : 29 à 9 ou plus, minimum 6 (street_03), moyenne 8,23 ; notes dans tools/panel_p0_notes.json et packages/kalis_adapt/docs/CALIBRAGE_CA1.md (tableau, familles de corrections, sources de la boucle 1).
- Mise au point : bin de kalis_bench exporte series/<profil>.json (séances servies, faites, effort réel) ; outil /tmp/dbg/show.py.
- Boucle 1 (code écrit, CI en cours) : bornes « charnière » en mode coach (CapacityFilter.hinge), plus de bonus de calibrage en mode coach, répétitions recalées sur le test (maximum mesuré moins la réserve), effort attendu affiché dans les deux sens, séries fractionnées quand la plage est hors de portée, maintiens à 75 % du maximum et temps total borné, gel des séries sur zone douloureuse, séries allégées rapprochées (coachBackoffMinDrop), entrée graduée d'un exercice calé sur un autre mouvement (coachNewExerciseShare) et plafond à 100 % sur zone à antécédent, assistance à l'élastique (conseil d'un cran, simulateur : crans), séries ouvertes notées ≤ 2 lues comme mesures, série repère même quand l'estimation est incertaine ; export : colonne « Servi par le moteur ».
- À faire ensuite : lire le CI, corriger les tests, renoter les couples sous 9, boucles suivantes ; docs (CONTRAT § 11 à mettre à jour avec ces règles), fin de lot.

## Étape : boucle 1 presque close (avant passe 1 du panel)
- Constats (series/<profil>.json) : (1) bornes tronquées répétées → dérive vers le haut ; (2) notes « 1 en réserve » fausses (modèle B) lues comme mesures → effondrement ; (3) séances des blocs précédents relues hors mode coach (replay.specOf : item null) → estimation différente à chaque nouveau bloc ; (4) séries d'une plage (ouvertes) menées au haut de la plage lues comme mesures ; (5) benchmarkDay posé par toute série ouverte → plus de série repère sur les plages.
- Corrections : CapacityFilter.hinge ; _asBound (seul ce que l'athlète fait mesure : échec, répétitions manquantes, série ouverte arrêtée avant le haut de sa plage, test) ; SlotSpec.coachRead (blocs précédents lus en mode coach) ; série repère = série ouverte au-delà du haut de la plage du bloc ; série de tête repère (coachTopProbeReps 3, hors réalisation) ; tenue repère (première tenue d'un maintien inconnu jusqu'à la durée écrite ; dernière tenue ouverte quand l'estimation fait servir moins que l'écrit) ; ExerciseTrack.probeCapacity ; assistance (e.assisted) : un cran de moins quand la série repère montre ≥ 2 de réserve de plus, un cran de plus seulement sur échec ou bas de plage manqué ; simulateur : crans (−10 kg par cran au journal, capacité × 0,75 ± 12 %), seulement blocs 0.4.0 ; EMOM non arrêté sur une chute dite facile ; exercice calé sur un autre mouvement : entrée à 60 %, +10 %/séance (5 % zone fragile), garde sur son propre suivi dès la 2e séance, plafond 100 % sur zone à antécédent.
- Mesures rapides (2 graines), CI 26cff16 : écart d'effort A 1,04 / B 1,23 / C 1,85 (0.1 : 1,11 / 2,27 / 1,63) ; échéance 96,4 / 95,6 / 95,4 % (0.1 : 90,9 / 89,2 / 89,6) ; échecs 0,11 / 0,06 / 0,38 %.
- Ensuite : passe 1 du panel (complète : tous les exports ont changé), boucle 2, docs (CONTRAT § 11 : reprendre tools/contrat_11.md et y écrire les règles ci-dessus), fin de lot.


## État au contrôle complet (04/10, 15:40 UTC)

- Calibrage arrêté après la boucle 3 (passe 3 complète : 34/68 à 9, minimum 7) ; boucle 4 = corrections de la relecture documentée et de la relecture indépendante (non renotées, < 10 % des lignes).
- Contrôle complet lancé (`claude/ci-cp-b`, commit deeefff9) ; à sa fin : copier `ci-out` → docs générés (MESURES, PROPRIETAIRE, CAMPAGNE_STREET), remplir `docs/VALIDATION.md` § 9.2 (repères MESURES_CAMPAGNE, MESURES_TEMPS), relancer un contrôle complet, puis fin de lot.
- Fin de lot prête : `/tmp/decisions_ca1.md` (section DECISIONS), `tools/manche2.sh` (manche 2 de la page de relecture), `tools/relecture_documentee_ca1.json` (notes à écrire dans la page, auteur relecture-documentee), `tools/panel_p3_notes.json`.


## Lot livré (04/10, 17:10 UTC)

`moteurs` ccde1ad2, étiquettes `kalis_adapt-v0.2.0` et `kalis_bench-v0.1.2`, contrôle complet run 37215089957, pipeline 1b08ac58, pages republiées, notification envoyée. Rien à reprendre.
