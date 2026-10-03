# État du pipeline « Calibrage des programmes » (CP)

Créé le 02/10/2026 par la conversation de pilotage (demande et questionnaire du propriétaire : `DECISIONS_CP.md`). Suspend le pipeline GP après G10 (G12 et G13 annulés, `pipeline/gp/DECISIONS_GP.md` D0.14 ; G12 à G15 reprendront à la décision du propriétaire).

## Tâches planifiées (lot indiqué dans le message « Lot : <LOT> »)

| Voie | Tâche | Identifiant | Lots |
| --- | --- | --- | --- |
| A (moteurs) | Fable 5.1, effort maximal, voie A | `trig_01AdGsb14RjjmaqFdrSXsMZX` | CR, CP1, CX, CP2, CY |
| B (moteurs) | Fable 5.1, effort maximal, voie B | `trig_01GKJ1jmozMRy6cJYUdyNtMV` | CQ, CA1, CA2 |
| App | Opus 5.5, effort élevé, application | `trig_01ETa7PRUGvnrwMrEchoKcc9` | CU, CI |

Tous les lots sont lancés par la conversation de pilotage d'après ce fichier (PIPELINE_CP.md §0) ; aucun lot ne lance un autre lot.
**Un seul lot moteur à la fois** depuis le 03/10/2026 (DECISIONS_CP.md C3.2) : ordre CQ → CR → CP1 → CA1 → CX → CP2 → CA2 → CY ; voie App (CU, CI) en parallèle. Sous-agents sur Opus, sauvegardes sur `cp-sauvegardes/<LOT>` (PIPELINE_CP.md §9).

## Liens

- Page de suivi : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5 (partie « Calibrage » créée par le premier lot CP qui livre)
- Page de relecture : à créer par CR
- Actions GitHub : https://github.com/mikeriin/streetlift-apk/actions (contrôles : `claude/ci-cp-a`, `claude/ci-cp-b`, `claude/ci-3d`)

## Entrées du propriétaire

- Références : **reçues — liste complète** (02/10/2026, 22:20 : six programmes de deux coachs de street workout, DECISIONS_CP.md C2) ; **chiffrées** sur la branche orpheline `cp-references` (dépôt public ; clé seulement dans les messages de lancement).

## Base de départ

- `main` : dev6.7.0 (6.7.0+106, commit 9f6b80b, run 37048733703), validée le 02/10/2026.
- `moteurs` : a1933a1e (CI des voies CP). Étiquettes : `kalis_core` 0.3.0, `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0, `kalis_quest` 0.1.0, `kalis_koach` 0.1.0 (`pipeline/gp/ETAT_GP.md`).

## Étiquettes livrées par le pipeline CP

| Paquet | Étiquette (branche fixe) | Lot | Commit | Date |
| --- | --- | --- | --- | --- |

## Lots

Chaque lot ne modifie que sa ligne (PIPELINE_CP.md §1).

| Lot | Voie | Prérequis | Livré | Panel (min) | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| CR | A | références reçues | — | — | — | en cours depuis 2026-10-03 05:52 UTC (reprise) |
| CQ | B | — | — | — | — | en cours depuis 2026-10-03 05:51 UTC (reprise ; premier passage du 2026-10-02 20:03 UTC interrompu) |
| CP1 | A | CR, CQ | — | — | — | en attente de CR, CQ |
| CA1 | B | CR, CQ | — | — | — | en attente de CR, CQ |
| CU | App | CQ | — | — | — | en attente de CQ |
| CX | A | CP1, CA1 | — | — | — | en attente de CP1, CA1 |
| CP2 | A | CX | — | — | — | en attente de CX |
| CA2 | B | CX | — | — | — | en attente de CX |
| CY | A | CP2, CA2 | — | — | — | en attente de CP2, CA2 |
| CI | App | CY, CU | — | — | — | en attente de CY, CU |
