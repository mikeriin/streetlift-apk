# État du pipeline « Calibrage des programmes » (CP)

Créé le 02/10/2026 par la conversation de pilotage (demande et questionnaire du propriétaire : `DECISIONS_CP.md`). Suspend le pipeline GP après G10 (G12 et G13 annulés, `pipeline/gp/DECISIONS_GP.md` D0.14 ; G12 à G15 reprendront à la décision du propriétaire).

## Tâches planifiées (lot indiqué dans le message « Lot : <LOT> »)

| Voie | Tâche | Identifiant | Lots |
| --- | --- | --- | --- |
| A et B (moteurs) | **Fable 5.1, effort maximal, moteurs** (créée le 03/10 22:23 : l'ancienne tâche voie A n'obtenait plus l'accès en écriture au dépôt) | `trig_013zUt5zYSPd9AgCz58HdLYB` | CP1, CA1 (C5.1) |
| A (moteurs) | Fable 5.1, effort maximal, voie A — **désactivée** le 03/10 (accès en écriture refusé à ses sessions) | `trig_01AdGsb14RjjmaqFdrSXsMZX` | CR (historique) |
| B (moteurs) | Fable 5.1, effort maximal, voie B | `trig_01GKJ1jmozMRy6cJYUdyNtMV` | CQ (historique) ; de secours pour CA1 |
| App | Opus 5.5, effort élevé, application | `trig_01ETa7PRUGvnrwMrEchoKcc9` | CU, CI |
| A et B (moteurs) | **Opus 5.5, effort maximal, moteurs** (C5.1) | `trig_01M9KpjaVMDC897vjadunwZP` | CX, CP2, CA2, CY et fins de lot (CR) |

Tous les lots sont lancés par la conversation de pilotage d'après ce fichier (PIPELINE_CP.md §0) ; aucun lot ne lance un autre lot.
**Un seul lot moteur à la fois** depuis le 03/10/2026 (DECISIONS_CP.md C3.2) : ordre CQ → CR → CP1 → CA1 → CX → CP2 → CA2 → CY ; voie App (CU, CI) en parallèle. Sous-agents sur Opus, sauvegardes sur `cp-sauvegardes/<LOT>` (PIPELINE_CP.md §9).

## Liens

- Page de suivi : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5 (partie « Calibrage » créée par le premier lot CP qui livre)
- Page de relecture : https://claude.ai/artifact/48CYFBy75Xykohm674vLNq (publiée par CR le 03/10/2026 ; manche 0 = moteurs 0.1, 10 programmes)
- Actions GitHub : https://github.com/mikeriin/streetlift-apk/actions (contrôles : `claude/ci-cp-a`, `claude/ci-cp-b`, `claude/ci-3d`)

## Entrées du propriétaire

- Références : **reçues — liste complète** (02/10/2026, 22:20 : six programmes de deux coachs de street workout, DECISIONS_CP.md C2) ; **chiffrées** sur la branche orpheline `cp-references` (dépôt public ; clé seulement dans les messages de lancement).

## Base de départ

- `main` : dev6.7.0 (6.7.0+106, commit 9f6b80b, run 37048733703), validée le 02/10/2026.
- `moteurs` : a1933a1e (CI des voies CP). Étiquettes : `kalis_core` 0.3.0, `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0, `kalis_quest` 0.1.0, `kalis_koach` 0.1.0 (`pipeline/gp/ETAT_GP.md`).

## Étiquettes livrées par le pipeline CP

| Paquet | Étiquette (branche fixe) | Lot | Commit | Date |
| --- | --- | --- | --- | --- |
| `kalis_core` 0.4.0 | `etiquettes/kalis_core-v0.4.0` | CQ | ef4c57ae | 03/10/2026 |
| `kalis_bench` 0.1.0 | `etiquettes/kalis_bench-v0.1.0` | CR | 0d219144 | 03/10/2026 |

## Lots

Chaque lot ne modifie que sa ligne (PIPELINE_CP.md §1).

| Lot | Voie | Prérequis | Livré | Panel (min) | Date | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| CR | A | références reçues | `kalis_bench` 0.1.0 (`etiquettes/kalis_bench-v0.1.0`, commit 0d219144, run 37126581234) ; référentiel 145 principes, 27 profils, panel étalonné et gelé, page de relecture (manche 0) | moteurs 0.1 : 3/10 (moyenne 4,9) ; 117 violations de sécurité | 2026-10-03 | livré |
| CQ | B | — | `kalis_core` 0.4.0 (`etiquettes/kalis_core-v0.4.0`, commit ef4c57ae, run 37106401044) ; profil v3 : 16 questions débutant, 29 élite | — (lot sans panel) | 2026-10-03 | livré |
| CP1 | A | CR, CQ | — | — | — | en cours depuis 2026-10-03 20:25 UTC (Fable, C5.1) |
| CA1 | B | CR, CQ | — | — | — | en attente de CP1 (un lot moteur à la fois, C3.2 ; Fable, C5.1) |
| CU | App | CQ | dev6.8.0 (main 6467bc2, build signé run 37126824436, contrôle ci-3d run 37125421224) | — (lot d'application) | 2026-10-03 | validé (03/10/2026, 17:09) |
| CX | A | CP1, CA1 | — | — | — | en attente de CP1, CA1 |
| CP2 | A | CX | — | — | — | en attente de CX |
| CA2 | B | CX | — | — | — | en attente de CX |
| CY | A | CP2, CA2 | — | — | — | en attente de CP2, CA2 |
| CI | App | CY, CU | — | — | — | en attente de CY, CU |
