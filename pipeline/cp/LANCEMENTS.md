# Contexte de lancement des lots CP

Le texte ajouté au lancement d'une tâche n'arrive pas toujours dans la session (constat du 03/10/2026). La conversation de pilotage écrit donc ici, avant chaque lancement, le contexte du lot (reprise, consignes ponctuelles). **Jamais la clé des références** (dépôt public) : elle est dans le document privé `claude/CLE_REFERENCES_CP.md` du projet claude.ai.

## CP1 (lancé le 03/10/2026 à 20:25 UTC, tâche « Fable 5.1, effort maximal, moteurs »)

- Cible C7 (notes proches de 10, deux jurys, jusqu'à 10 boucles guidées par recherche approfondie) : lis `DECISIONS_CP.md` C6 et C7.
- Points de départ : `packages/kalis_bench/docs/BASELINE_0_1.md` (panel : minimum 3, moyenne 4,9 ; 117 violations) et `pipeline/cp/livraisons/RELECTURE_DOCUMENTEE_M0.md` (relecture documentée : moyenne 3,8 ; mêmes notes dans la collection `notes` de la page de relecture).
- Défaut transversal à corriger en premier : % affichés ≠ charges réelles des mouvements lestés (traction +17,5 kg à 80 kg = 70 % du 1RM total, pas 77 %) ; échelle d'effort fausse (« 4 rép. en réserve » affiché 3/10).
- Références privées sur `cp-references` : `references.tar.gpg`, `analyse_CR.tar.gpg`, `transcriptions_pilotage.tar.gpg` (A3 en entier, F3 pages 1-19).
- Si la part Fable s'épuise : la conversation de pilotage reprend le lot sur la tâche Opus moteurs depuis `cp-sauvegardes/CP1` (garde SAUVEGARDE.md à jour).
