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
| UI2 | UI0 livré | — | — | en cours depuis 2026-10-10 13:43 UTC (session session_01UBKNgcL6KGVgMUfEL3Fzdo) |
| UI3 | UI0 livré | — | — | en cours depuis 2026-10-10 13:43 UTC (session session_01JVF5cveTZDzybGVBq9M1XE) |
| UI4 | UI0 livré | — | — | en cours depuis 2026-10-10 13:43 UTC (session session_01EcZvt7jo2rPQi194ZGu9FQ) |
| UI5 | UI1, UI2, UI3, UI4 livrés et fusionnés dans `refonte-ui` | — | — | en attente de UI1 à UI4 |
