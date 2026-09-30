# État du pipeline « Génération et progression » (GP)

Créé le 30/09/2026 par la conversation de pilotage (questionnaire du propriétaire : `DECISIONS_GP.md`).
Remplace le pipeline « Mannequin 3D » (clos le 30/09/2026, `pipeline/3d/ETAT_3D.md`).

Tâches planifiées (lancement manuel par la conversation de pilotage, ou automatique en fin de lot de moteur ; lot indiqué dans le message « Lot : <LOT> ») :
- **Opus 5.5, effort élevé** : `trig_0114Tz1maKVyK2eEURLXCmWw` — lots G1-G3, G5-G7, G9, G10, G12-G15.
- **Fable 5.1, effort maximal** : `trig_015YmARJsCysbwuP65URNTaU` — lots de moteur G4, G8, G11.
Un lot de moteur qui se termine lance le lot suivant sur la tâche **Opus** ; aucun lot ne relance la tâche qui l'a lancé ; aucun lot ne crée, ne modifie ni ne supprime de tâche.

Page de suivi : (créée par G1)
Nom des versions : « devX.Y.Z » (DECISIONS_GP.md D0.9).
Base de départ : main 5.10.1+93 (commit 601a04d, M8 correction 3, validée par le propriétaire le 30/09/2026).

Entrées attendues du propriétaire :
- `inputs/base_exercices.json` (base v1.1.0 du 28/09/2026, 1 039 exercices, 8 disciplines, SHA-256 1a44c2b0…c59b01f6) : **présent** (30/09/2026, 23:30).
- `inputs/koach/` (36 poses) et `inputs/flammes_difficulte_1_a_10.png` : présents (30/09/2026).

| Lot | Validation | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| G1 | propriétaire | dev6.0.0 | — | — | — | en cours depuis 2026-09-30 21:29 UTC |
| G2 | propriétaire | — | — | — | — | à faire |
| G3 | propriétaire | — | — | — | — | à faire |
| G4 | auto → G5 | kalis_plan 0.1.0 | — | — | — | à faire |
| G5 | propriétaire | — | — | — | — | à faire |
| G6 | propriétaire | — | — | — | — | à faire |
| G7 | propriétaire | — | — | — | — | à faire |
| G8 | auto → G9 | kalis_adapt 0.1.0 | — | — | — | à faire |
| G9 | propriétaire | — | — | — | — | à faire |
| G10 | propriétaire | — | — | — | — | à faire |
| G11 | auto → G12 | kalis_quest 0.1.0 | — | — | — | à faire |
| G12 | propriétaire | — | — | — | — | à faire |
| G13 | propriétaire | — | — | — | — | à faire |
| G14 | propriétaire | — | — | — | — | à faire |
| G15 | propriétaire | — | — | — | — | à faire |
