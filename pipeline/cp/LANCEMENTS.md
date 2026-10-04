# Contexte de lancement des lots CP

Le texte ajouté au lancement d'une tâche n'arrive pas toujours dans la session (constat du 03/10/2026). La conversation de pilotage écrit donc ici, avant chaque lancement, le contexte du lot (reprise, consignes ponctuelles). **Jamais la clé des références** (dépôt public) : elle est dans le document privé `claude/CLE_REFERENCES_CP.md` du projet claude.ai.

## CP1 (lancé le 03/10/2026 à 20:25 UTC, tâche « Fable 5.1, effort maximal, moteurs »)

- Cible C7 (notes proches de 10, deux jurys, jusqu'à 10 boucles guidées par recherche approfondie) : lis `DECISIONS_CP.md` C6 et C7.
- Points de départ : `packages/kalis_bench/docs/BASELINE_0_1.md` (panel : minimum 3, moyenne 4,9 ; 117 violations) et `pipeline/cp/livraisons/RELECTURE_DOCUMENTEE_M0.md` (relecture documentée : moyenne 3,8 ; mêmes notes dans la collection `notes` de la page de relecture).
- Défaut transversal à corriger en premier : % affichés ≠ charges réelles des mouvements lestés (traction +17,5 kg à 80 kg = 70 % du 1RM total, pas 77 %) ; échelle d'effort fausse (« 4 rép. en réserve » affiché 3/10).
- Références privées sur `cp-references` : `references.tar.gpg`, `analyse_CR.tar.gpg`, `transcriptions_pilotage.tar.gpg` (A3 en entier, F3 pages 1-19).
- Si la part Fable s'épuise : la conversation de pilotage reprend le lot sur la tâche Opus moteurs depuis `cp-sauvegardes/CP1` (garde SAUVEGARDE.md à jour).

## CA1 (lancé le 04/10/2026 vers 08:55 UTC, tâche « Fable 5.1, effort maximal, moteurs »)

- Tu es le seul lot « à faire » : CA1 (`prompts/CA1.txt`). CP1 est livré (`kalis_plan` 0.2.0, `kalis_core` 0.4.1, `kalis_bench` 0.1.1, `moteurs` d0d60018) : lis `livraisons/LIVRAISON_CP1.md` (parties 6 et 7) et `DECISIONS_CP.md` (section CP1).
- **Cible en vigueur : C7.5** (pas C7.1) : panel ≥ 9 pour chaque école et chaque profil street, sur les trajectoires, 0 violation de sécurité ; plus de seuil de moyenne. Relecture documentée : faite par tes sous-agents, écrite dans ta manche de la page de relecture, traitée, **sans seuil** (C7.6). Jusqu'à 10 boucles (C7.2) ; arrêt après deux boucles sans gain sur le nombre de couples à 9 et le minimum du panel.
- Programmes d'entrée : `kalis_plan` 0.2.0 existe (`etiquettes/kalis_plan-v0.2.0`) : prends ses programmes street pour les 17 profils, plus des programmes de test pour les techniques qu'il n'écrit pas. Ne touche pas `packages/kalis_plan` (le croisement réel est CX).
- Notes de la page de relecture : manches 0 et 1, auteur `relecture-documentee` (C6) ; lis celles qui touchent l'évolution (repères, tests, bloc suivant d'après le résultat réel, reprise) et traite-les.
- Clé des références : dans le document privé du projet ; passe-la à gpg par un fichier `/tmp` en mode 600 (`--passphrase-file`), **jamais sur une ligne de commande** (C7.8, écart de CP1).
- Recherche web : quota d'environ 200 recherches par session (CP1 l'a épuisé) ; répartis-les entre les boucles, WebFetch sur des adresses déjà repérées ensuite.
- Contrôle : `claude/ci-cp-b`. Sauvegardes : `cp-sauvegardes/CA1`. Si la part Fable s'épuise : la conversation de pilotage reprend le lot sur la tâche Opus moteurs depuis `cp-sauvegardes/CA1` (garde SAUVEGARDE.md à jour).
