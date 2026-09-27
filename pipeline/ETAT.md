# État du pipeline Kalis Track

| Lot | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- |
| L5 (manuel) | 3.0.2 | 6e94618 | 83 | 26/09/2026 | livré |
| L6 (manuel) | 3.0.3 | 8e8f6d1 | 84 | 26/09/2026 | livré |
| L9 | pack 1.0.0 (app inchangée) | lecture seule de main (6e94618 ou suivant) | — (pas de build) | 26/09/2026 | pack livré sur `content-pack` (14d3952) — **relecture du propriétaire requise** |
| L8 | 3.1.0 | 620752e | 85 | 26/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |
| L9R | pack 2.0.0 (app inchangée) | lecture seule de main (620752e) | — (pas de build) | 27/09/2026 | **validé par le propriétaire** ; `kalis_content_pack_v1_final.zip` = copie du candidat v2 (content-pack 93fad2e, SHA-256 5a13a91e…9086) |
| L9b | 3.2.0 | 6015ebc | 87 | 27/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) — point d'installation conseillé |
| L10 | 4.0.0 (attendu) | — | — | 27/09/2026 | lancé |

Outil de relecture v2 (même lien, version 2 de l'artefact ; collection `relectures_v2`, l'ancienne `relectures` conservée) : https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S
Suite : le propriétaire relit la v2. À la validation : appliquer ses corrections, copier l'archive validée sous `kalis_content_pack_v1_final.zip` sur `content-pack`, puis lancer L9b (trig_01XUb6PZBCvYvNbBvpQokiun ; main est en 3.1.0, condition remplie). La seconde passe L9 (trig_01KyxRKcUDA45rdHQAw4xVGM) est remplacée par L9R.

L9b : livré le 27/09/2026 (pack final `5a13a91e…9086` intégré ; livraison `livraisons/LIVRAISON_L9b.md`). Suite : L10 lancé (trig_018xrtqCs8WgDdpAWTUQ4aHH).

Décisions en attente : voir DECISIONS_EN_ATTENTE.md (L9b, non bloquantes ; L9R et L8 tranchées)
