# État du pipeline « Refonte UI et UX » (UI)

Créé le 10/10/2026 par la conversation de pilotage. Règles : `PIPELINE_UI.md` ; cahier : `CAHIER_UI.md` ; décisions : `DECISIONS_UI.md`.

## Tâche planifiée

| Tâche | Identifiant | Lots |
| --- | --- | --- |
| Kalis Track — refonte UI (Opus 5.5, effort élevé, approbation automatique) | `trig_01Fqf4osZzdda75J4DqmoLB1` | UI0 à UI5 ; plusieurs sessions en parallèle pour UI1 à UI4 |

## Liens

- Maquettes : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J
- Actions GitHub : https://github.com/mikeriin/streetlift-apk/actions (contrôles : `claude/ci-3d` pour UI0, puis `claude/ci-ui-<lot>`)

## Base de départ

- `main` : dev6.11.1 (6.11.1+114, commit b7996b3f, build signé run 37955793332, contrôle ci-3d run 37946602412).

## Lots

Chaque lot ne modifie que sa ligne (PIPELINE_UI.md §1).

| Lot | Prérequis | Livré | Date | Statut |
| --- | --- | --- | --- | --- |
| UI0 | — | `refonte-ui` 0e5342df ; contrôle `claude/ci-ui-ui0` run 38050589366 (vert) ; [livraison](livraisons/LIVRAISON_UI0.md) | 2026-10-10 | validé (pilotage, C8, 10/10/2026 14:55) |
| UI1 | UI0 livré | — | — | en cours depuis 2026-10-10 13:42 UTC (session session_018ETAYadGCNKByTAfVnsshL) |
| UI2 | UI0 livré | `ui/UI2` ca9a583 ; contrôle `claude/ci-ui-ui2` run 38076888632 (vert, cibles émulateur et tour compris ; rendus historiques en échec comme sur la base) ; [livraison](livraisons/LIVRAISON_UI2.md) | 2026-10-10 | livré |
| UI3 | UI0 livré | `ui/UI3` f7de57c1 ; contrôle `claude/ci-ui-ui3` run 38066918616 (vert côté lot ; tour « avant » partie a : incident émulateur) ; [livraison](livraisons/LIVRAISON_UI3.md) | 2026-10-10 | validé (pilotage, C8, 10/10/2026 20:50) ; fusion dans `refonte-ui` après contrôle `claude/ci-ui-fusion` |
| UI4 | UI0 livré | `ui/UI4` 864dff16 ; contrôle `claude/ci-ui-ui4` run 38067294842 (vert ; rendus historiques en échec comme sur la base) ; [livraison](livraisons/LIVRAISON_UI4.md) | 2026-10-10 | validé (pilotage, C8, 10/10/2026 20:50 ; titres tronqués du kit confiés à UI5, U0.16) ; fusion dans `refonte-ui` après contrôle `claude/ci-ui-fusion` |
| UI5 | UI1, UI2, UI3, UI4 livrés et fusionnés dans `refonte-ui` | — | — | en attente de UI1 à UI4 |
