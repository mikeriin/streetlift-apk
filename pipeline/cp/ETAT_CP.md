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
| CP1 | A | CR, CQ | `kalis_plan` 0.2.0, `kalis_bench` 0.1.1, `kalis_core` 0.4.1 (`etiquettes/kalis_plan-v0.2.0`, `etiquettes/kalis_bench-v0.1.1`, `etiquettes/kalis_core-v0.4.1`, commit d0d60018, run 37185013127) ; chemin street, 0 violation de sécurité sur 17 profils, page de relecture (manche 1) | street 0.2.0 : 8/10 (moyenne 8,97, 66 notes sur 68 à 9) ; relecture documentée 7,41 (min 7) | 2026-10-04 | livré — cible non atteinte (les 17 profils street : panel `street_08` et `street_14` à 8, moyennes sous 9,5 ; relecture documentée sous 9 partout) ; voie A retenue par délégation du propriétaire ; cible confirmée le 04/10 : panel à 9 pour l'instant, 10 dans un pipeline ultérieur ; restent deux couples à 8 (DECISIONS_CP.md, section CP1) |
| CA1 | B | CR, CQ | `kalis_adapt` 0.2.0, `kalis_bench` 0.1.2 (`etiquettes/kalis_adapt-v0.2.0`, `etiquettes/kalis_bench-v0.1.2`, commit ccde1ad2, run 37215089957) ; mode coach pour les blocs au contrat 0.4.0, trois modèles de vérité, 0 manquement de sécurité réalisé sur 17 profils, page de relecture (manche 2) | trajectoires street : 7/10 (moyenne 8,35, 34 notes sur 68 à 9) ; relecture documentée 6,1 (min 5), sans seuil | 2026-10-04 | livré — cible non atteinte (14 profils street sur 17 ont au moins une école sous 9 ; à 9 partout : `street_02`, `street_07`, `street_11`) ; les corrections demandées portent sur le programme écrit par `kalis_plan` ; décision requise (DECISIONS_CP.md, section CA1) |
| CU | App | CQ | dev6.8.0 (main 6467bc2, build signé run 37126824436, contrôle ci-3d run 37125421224) | — (lot d'application) | 2026-10-03 | validé (03/10/2026, 17:09) |
| CX | A | CP1, CA1 | `kalis_core` 0.4.2, `kalis_plan` 0.2.1, `kalis_adapt` 0.2.1, `kalis_bench` 0.2.0 (`etiquettes/kalis_core-v0.4.2`, `etiquettes/kalis_plan-v0.2.1`, `etiquettes/kalis_adapt-v0.2.1`, `etiquettes/kalis_bench-v0.2.0`, commits 90f1fc8 et e90e33e, run 37255941742) ; saisons street croisées (17 profils × 8 scénarios × 3 modèles × 100 graines), 0 violation sur les saisons de référence, page de relecture (manche 3) | saisons street : 4/10 (moyenne 8,01, 25 notes sur 68 à 9) ; relecture documentée 6,1 (min 5), sans seuil | 2026-10-05 | en cours depuis 2026-10-05 05:38 UTC (correction 1, tâche Opus moteurs ; livraison du 05/10 non validée par le pilotage, C8.4 ; contexte : LANCEMENTS.md ; sauvegardes : `cp-sauvegardes/CX-c1`) |
| CP2 | A | CX | — | — | — | en attente de CX |
| CA2 | B | CX | — | — | — | en attente de CX |
| CY | A | CP2, CA2 | — | — | — | en attente de CP2, CA2 |
| CI1 | App | CU ; CX (paquets 0.2.1, puis dernières étiquettes, C9.1) | dev6.9.0 (main 938de59, build signé run 37328372801, contrôle ci-3d run 37324228351) ; paquets `kalis_core` 0.4.2, `kalis_plan` 0.2.1, `kalis_adapt` 0.2.1 (0.2.2 pas encore publiés) | — (lot d'application) | 2026-10-05 | validé (pilotage, C8.1, 05/10/2026 15:20 UTC : build signé run 37328372801 et contrôle ci-3d run 37324228351 verts, arbre contrôlé identique à main 938de59) ; mise à jour des paquets 0.2.2 à suivre (CI1b) |
| CI | App | CY, CU | — | — | — | en attente de CY, CU |
