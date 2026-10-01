# État du pipeline « Génération et progression » (GP)

Créé le 30/09/2026 par la conversation de pilotage (questionnaire du propriétaire : `DECISIONS_GP.md`).
Remplace le pipeline « Mannequin 3D » (clos le 30/09/2026, `pipeline/3d/ETAT_3D.md`).
**Pistes parallèles depuis le 01/10/2026** (D0.10) : A — application, M — moteurs, K — koach (PIPELINE_GP.md §0 et §8).

## Tâches planifiées (lot indiqué dans le message « Lot : <LOT> »)

| Tâche | Identifiant | Lots |
| --- | --- | --- |
| Opus 5.5, effort élevé | `trig_0114Tz1maKVyK2eEURLXCmWw` | piste A (G1-G3, G5-G7, G9, G10, G12-G15), piste K (GK) |
| Fable 5.1, effort maximal, **A** | `trig_015YmARJsCysbwuP65URNTaU` | GC, G8 |
| Fable 5.1, effort maximal, **B** | `trig_01U6w5JEVp4pdHpZeDkLGuZs` | G4, G11 |

Lancement des lots suivants : piste A par la conversation de pilotage (après validation du propriétaire) ; piste M : GC → G4 (Fable B) → G8 (Fable A) → G11 (Fable B) ; le lancement par le lot précédent est refusé aux sessions (constat du 01/10/2026), **la conversation de pilotage vérifie l'état environ toutes les heures et lance les lots prêts** ; piste K : un seul lot.
Livraisons des pistes M et K : branches fixes `etiquettes/<paquet>-vX.Y.Z` (push d'étiquettes refusé aux sessions, PIPELINE_GP.md §0). Aucun lot ne crée, ne modifie ni ne supprime de tâche.

Page de suivi : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5 (créée par G1 ; trois parties : Application, Moteurs, Koach)
Nom des versions : « devX.Y.Z » (DECISIONS_GP.md D0.9 ; appliqué à partir de G2).
Base de départ : main 5.10.1+93 (commit 601a04d, validée le 30/09/2026).

Branches : `main` (piste A, contrôle `claude/ci-3d`) ; `moteurs` (piste M, contrôle `claude/ci-gp-moteurs`) ; `koach` (piste K, contrôle `claude/ci-gp-koach`). Les branches `moteurs` et `koach` partent de main 6.0.1 (10fed1d) + mise en place de la CI des pistes (`ci-paquets.yml`, `docs/CI_PISTES.md`) et ne sont jamais fusionnées dans `main`.

Entrées du propriétaire (`inputs/`) :
- `base_exercices.json` (base v1.1.0 du 28/09/2026, 1 039 exercices, 8 disciplines, SHA-256 1a44c2b0…c59b01f6) : présent (30/09/2026, 23:30).
- `koach/` (36 poses) et `flammes_difficulte_1_a_10.png` : présents (30/09/2026).

## Étiquettes livrées (pistes M et K)

| Paquet | Dernière étiquette | Lot | Date |
| --- | --- | --- | --- |
| kalis_core | kalis_core-v0.1.0 → branche fixe `etiquettes/kalis_core-v0.1.0` (commit 5327294 ; push d'étiquette refusé par le proxy, 403) | GC | 01/10/2026 |
| kalis_plan | kalis_plan-v0.1.0 → branche fixe `etiquettes/kalis_plan-v0.1.0` (commit bbdb497) | G4 | 01/10/2026 |
| kalis_adapt | — | G8 | — |
| kalis_quest | — | G11 | — |
| kalis_koach | kalis_koach-v0.1.0 (4fa2777 ; étiquette créée par le propriétaire + branche fixe `etiquettes/kalis_koach-v0.1.0`) | GK | 01/10/2026 |

## Piste A — application (validation du propriétaire)

| Lot | Prérequis | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| G1 | — | 6.0.0+94 | b3a3d73 | 36813381709 | 01/10/2026 | validé (01/10/2026, 08:30) |
| G1 correction 1 | — | 6.0.1+95 | 10fed1d | 36823406874 | 01/10/2026 | validé (01/10/2026, 08:30) |
| G2 | G1 | dev6.1.0 (6.1.0+96) | e5cf07f | 36840295689 | 01/10/2026 | validé (01/10/2026, 11:31) |
| G3 | G2, GC | dev6.2.0 (6.2.0+97) | 92fea5a | 36860680819 | 01/10/2026 | validé (01/10/2026, 14:51) |
| G5 | G3, GK | — | — | — | — | en cours depuis 2026-10-01 12:55 UTC |
| G6 | G5 | — | — | — | — | à faire |
| G7 | G6, G4 | — | — | — | — | à faire |
| G9 | G7, G8 | — | — | — | — | à faire |
| G10 | G9 | — | — | — | — | à faire |
| G12 | G10, G11 | — | — | — | — | à faire |
| G13 | G12 | — | — | — | — | à faire |
| G14 | G13 | — | — | — | — | à faire |
| G15 | G14 | — | — | — | — | à faire |

## Piste M — moteurs (automatique)

| Lot | Prérequis | Tâche | Étiquette | Commit moteurs | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| GC | — | Fable A | kalis_core-v0.1.0 (branche fixe `etiquettes/kalis_core-v0.1.0` : push d'étiquette refusé, 403) | 5327294 | 01/10/2026 | livré (run 36833295632 vert) ; G4 lancé par le pilotage le 01/10/2026 à 09:00 UTC |
| G4 | GC | Fable B | kalis_plan-v0.1.0 (branche fixe `etiquettes/kalis_plan-v0.1.0`) | bbdb497 | 01/10/2026 | livré (run 36877967988 vert) ; G8 lancé par G4 sur la tâche Fable A le 01/10/2026 |
| G8 | G4 | Fable A | kalis_adapt-v0.1.0 | — | — | à faire |
| G11 | G8 | Fable B | kalis_quest-v0.1.0 | — | — | à faire |

## Piste K — koach (automatique)

| Lot | Prérequis | Tâche | Étiquette | Commit koach | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| GK | — | Opus | kalis_koach-v0.1.0 | 4fa2777 | 01/10/2026 | livré (run 36831108263 ; étiquette créée par le propriétaire via une release GitHub, le push d’étiquette étant refusé à la session) |
