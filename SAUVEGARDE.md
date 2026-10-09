# Sauvegarde KM1 (méthode Koach : référence Python et banc)

Session Fable 5.1 lancée le 09/10/2026 vers 16:10 UTC (pas de ligne « Lot : » : KM1 seul lot moteur « à faire »). Ligne d'état « en cours depuis 2026-10-09 16:14 UTC » poussée sur `pipeline` (9c9420fa). `add_repo` absent de la session et de ses sous-agents ; push vérifié (pipeline poussé). Base : `moteurs` aacbe054. Arbre de travail : worktree `/home/claude/moteurs` (branche locale `moteurs`). Outils de session : `km1-outils/` (save.sh, ci.sh).

## Constats de démarrage
- **Pas de SDK Dart dans la session** (storage.googleapis.com refusé par la politique de sortie) : tout ce qui est Dart passe par le contrôle `claude/ci-cp-a` (comme CY : `ci.sh`), résultats dans `ci-out/`.
- Journal du propriétaire : `journal_proprietaire.tar.gpg` **absent** de `cp-references` au démarrage (brique 8 en attente, C13.6).
- Témoin 0.3.1 déjà mesuré par le contrôle complet de CY (run 37922562342, `ci-out/packages/kalis_bench/SAISONS.md`, 100 graines) : échéance (meilleure barre / max du jour) 94,4 % en saison de référence, progression 0,313 %/sem., écart d'effort 1,45.

## Architecture décidée (voir packages/kalis_adapt/reference/CONCEPTION.md quand il existe)
- Dart (ajouts dans kalis_bench seulement, `bin/km1.dart` + `lib/src/km/`) : export JSON des modèles de vérité (profils × scénarios × modèles A/B/C × graines), des programmes de référence kalis_plan, traces de parité du modèle de vérité, mesures du témoin par saison, témoin sur athlètes adversariaux, critères de sécurité du banc sur des blocs exportés par Python.
- Python (`packages/kalis_adapt/reference/`) : portage du modèle de vérité (vérifié contre les traces Dart), meneur de saison, moteur Koach 1.0, banc adversarial, critères.
- 10 qualités : pousser, tirer, jambes, tronc, figures (bras tendus, équilibre), endurance_force, explosivite, aerobie, anaerobie, mobilite.

## Fait
- Lectures : PIPELINE_CP, CAHIER_KM, prompt KM1, LANCEMENTS (KM1), DECISIONS C11-C13, truth.dart, runner.dart, endurance_truth.dart, season.dart, coach_metrics.dart, policy.dart, common.dart, book.dart, grid.dart, Flames.

## En cours
- Outil d'export Dart `km1` (brique 0).

## Reste
- Briques 1 à 7, critères, fixtures, relecture indépendante, fin de lot ; brique 8 dès que le journal est déposé.

## 09/10 17:25 UTC — brique 0 faite
- Export Dart `km1` (packages/kalis_bench/lib/src/km/km_export.dart, bin/km_common.dart, bin/km1.dart) : analysé et formaté par le contrôle dev (run 37964997316), exports dans `packages/kalis_adapt/reference/donnees/` (catalogue_infos, reference/, temoin/ 16 graines, traces_verite, traces_endurance).
- Portage Python du modèle de vérité (`reference/banc/verite.py`, `verite_endurance.py`) : **3 tests de parité verts à 1e-9** (traces force > 20 000 séries, endurance, tirages de départ de toutes les saisons).
- Notes : `km1-outils/notes/SECURITE_0_3_1.md` (règles de sécurité 0.3.1 et critères du banc), `SOURCES_RECHERCHE.md` (sources vérifiées).
- Fichier de paramètres v1 ébauché (`reference/params/koach_params_v1.json`), `koach/numerique.py` (erfc 1e-13, moments d'intervalle = réponse graduée ogive normale).
- Conception de l'estimation : état gaussien (10 qualités, réponse ρ + 5 classes, sensibilités fatigue, biais RIR additif et proportionnel, courbe c1·ln R + c2·(R−1) avec échelle par exercice, fatigue intra-séance, part de tenue, effet de jour séance + exercice ; par exercice δ et échelle de courbe), mises à jour par appariement de moments sur intervalles (catégories de flammes), deux branches par séance (jour normal / mauvais jour) fusionnées en fin de séance.
