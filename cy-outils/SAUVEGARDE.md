# Sauvegarde CY (croisement final)

Session Opus 5.5 lancée le 09/10/2026 vers 06:00 UTC (pas de ligne « Lot : » : CY seul lot moteur « à faire »). Ligne d'état « en cours depuis 2026-10-09 06:10 UTC » poussée sur `pipeline` (8b04eda). add_repo absent de la session ; push vérifié. Base : `moteurs` 1ca7475f. Outils : `cy-outils/` (ci.sh dev/full, fmtsync.py, panel.py, save.sh, aa_fmt), arbre de travail = worktree de `moteurs` (/home/claude/mot, branche locale cy).

## Fait
- Lectures : PIPELINE_CP, DECISIONS_CP (tout), LANCEMENTS (CY), prompt CY, LIVRAISON_CP2, LIVRAISON_CA2, notes de la page (714, manches 0 à 8 ; aucune du propriétaire), constats de sécurité de la relecture documentée de CP2 (notes/relecture_doc).
- Référence de départ street : panel final CP2 (notes/fs_toutes_comb.json, 19/68, min 5) ; autres (programmes écrits) : notes/fa_toutes_comb.json (15/40, min 5).
- Partie 0 codée (non compilée au moment de la sauvegarde) :
  - kalis_adapt 0.3.1 : première gêne du poignet → appui neutre (pompe mains sur barre basse comptée comme neutre, aussi pendant l'arrêt) ; couloir plafonné à l'écrit à ≥ 85 % ; borne de charge à schéma changé (2,5 %/rép.) ; jour bas exclu des repères de jour bas ; 3 paramètres ; tests (coach_rules_test).
  - kalis_plan 0.3.1 : note `clearance_first` (questionnaire prudent ou gêne déclarée ≥ 5), note `shoulder_history` (développé au-dessus de la tête, épaule à antécédent), pas de test maximal sur articulation douloureuse (trend ≥ 3, déclarée ≥ 4, arrêt ; objectif daté), tirage retiré après un test de tirage le même jour, premier muscle-up testé sur 1 répétition, pas de course le lendemain d'une course d'épreuve, texte de la règle de durée ; tests (coach_test, groupe « CY partie 0 »).

## Reste
- Contrôle dev, corrections, recopie des docs générés (PROFILS_TYPES etc.) ; vérif. des exports (street_01/03/07/08/10/12, autres_05/06/08/10) ; publication intermédiaire 0.3.1 (contrôle full, moteurs, étiquettes) ; DECISIONS CY.1.
- Croisement final : saisons toutes disciplines (kalis_bench 0.3.0), panel, boucles ≤ 5, relecture documentée, manche finale, INTEGRATION_CI, livraison.
- Non traités en partie 0 (conduite, pas de sécurité) : estimation du muscle-up le jour J (street_07), course-marche (autres_05).
