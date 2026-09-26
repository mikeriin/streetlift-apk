# État du pipeline Kalis Track

| Lot | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- |
| L5 (manuel) | 3.0.2 | 6e94618 | 83 | 26/09/2026 | livré |
| L6 (manuel) | 3.0.3 | 8e8f6d1 | 84 | 26/09/2026 | livré |
| L9 | pack 1.0.0 (app inchangée) | lecture seule de main (6e94618 ou suivant) | — (pas de build) | 26/09/2026 | pack livré sur `content-pack` (14d3952) — **relecture du propriétaire requise** |
| L8 | 3.1.0 | 620752e | 85 | 26/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |

Outil de relecture L9 (base partagée des relectures, collection `relectures`) : https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S
Suite : après la relecture, lancer la seconde passe (tâche trig_01KyxRKcUDA45rdHQAw4xVGM) ; elle lit la collection `relectures` avec ArtifactData.

L9b : non lancé par L8 — `kalis_content_pack_v1_final.zip` absent de `content-pack` (26/09/2026 19:40 UTC) ; il sera lancé après validation du pack (L9R).

Décisions en attente : voir DECISIONS_EN_ATTENTE.md (L9 et L8, toutes non bloquantes)
