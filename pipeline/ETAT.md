# État du pipeline Kalis Track

| Lot | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- |
| L5 (manuel) | 3.0.2 | 6e94618 | 83 | 26/09/2026 | livré |
| L6 (manuel) | 3.0.3 | 8e8f6d1 | 84 | 26/09/2026 | livré |
| L9 | pack 1.0.0 (app inchangée) | lecture seule de main (6e94618 ou suivant) | — (pas de build) | 26/09/2026 | pack livré sur `content-pack` (14d3952) — **relecture du propriétaire requise** |
| L8 | 3.1.0 | 620752e | 85 | 26/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |
| L9R | pack 2.0.0 (app inchangée) | lecture seule de main (620752e) | — (pas de build) | 27/09/2026 | **validé par le propriétaire** ; `kalis_content_pack_v1_final.zip` = copie du candidat v2 (content-pack 93fad2e, SHA-256 5a13a91e…9086) |
| L9b | 3.2.0 | 6015ebc | 87 | 27/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) — point d'installation conseillé |
| L10 | 4.0.0 | 5d38177 | 88 | 27/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |
| L11 | 4.1.0 | b202121 | 89 | 27/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |
| L12 | 4.2.0 | 332e292 | 90 | 27/09/2026 | livré (build signé réussi ; non vérifié sur téléphone) |
| L13 | 4.3.0 | 1a39f91 | 93 annulé (concurrence) → **94** sur 4.3.1 | 27/09/2026 | livré (build signé réussi sur 4.3.1 qui contient L13 ; non vérifié sur téléphone) — **pipeline terminé** |
| Refonte MA | 4.3.1 | 7f07e2e | 94 | 27/09/2026 | **fusionnée sur main** après L13 (avance rapide, accord écrit du propriétaire) ; build signé réussi ; non vérifié sur téléphone |

Outil de relecture v2 (même lien, version 2 de l'artefact ; collection `relectures_v2`, l'ancienne `relectures` conservée) : https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S
Suite : le propriétaire relit la v2. À la validation : appliquer ses corrections, copier l'archive validée sous `kalis_content_pack_v1_final.zip` sur `content-pack`, puis lancer L9b (trig_01XUb6PZBCvYvNbBvpQokiun ; main est en 3.1.0, condition remplie). La seconde passe L9 (trig_01KyxRKcUDA45rdHQAw4xVGM) est remplacée par L9R.

L9b : livré le 27/09/2026 (pack final `5a13a91e…9086` intégré ; livraison `livraisons/LIVRAISON_L9b.md`). Suite : L10 lancé (trig_018xrtqCs8WgDdpAWTUQ4aHH).

L10 : livré le 27/09/2026 (générateur de programme ; installation existante = modèle Expert streetlifting implicite, programme inchangé ; livraison `livraisons/LIVRAISON_L10.md`, 13 profils types dans `docs/PROFILS_TYPES_L10.md` du ZIP). Suite : L11 lancé (trig_01Edi6HpVLFiW5vfUQFRCsqC).

L11 : livré le 27/09/2026 (adaptation au jour le jour ; installation existante en mode Assisté, rien ne change sans tap ; livraison `livraisons/LIVRAISON_L11.md`). Suite : L12 lancé (trig_01KutrfRsBDMLmAgpQKfUQJc).

L12 : livré le 27/09/2026 (motivation et progression visible ; barème des récompenses proposé, non appliqué ; rappels jamais un jour de repos ; livraison `livraisons/LIVRAISON_L12.md`). Suite : L13 lancé (trig_01CxGPskf5oNyYEkXyiQbpPZ).

Refonte muscles et animations : fusionnée sur main le 27/09/2026 en 4.3.1 (`7f07e2e`, build signé n°94 réussi), réappliquée sur les sources de 4.3.0 (L13 conservé, vérifié par diff). Attention : le push a annulé le build de L13 (run n°93, même groupe de concurrence sur main) ; le build n°94 contient L13 et a réussi. Aperçu https://claude.ai/artifact/XPop5Xkw3SJNmeftWd6zQf ; livraison `livraisons/LIVRAISON_REFONTE_MA.md`.

L13 : livré le 27/09/2026 (santé, sécurité, conformité, test fermé ; livraison `livraisons/LIVRAISON_L13.md`). ZIP 4.3.0 `0ff33144…1a70` publié sur main `1a39f91` ; son build n° 93 a été annulé par la poussée de 4.3.1 (refonte fusionnée par une autre session, construite sur 4.3.0, fichiers L13 identiques). **Version à installer : 4.3.1, run n° 94** (https://github.com/mikeriin/streetlift-apk/actions/runs/36327156905). Dernier lot : aucun lot suivant lancé. À fournir : URL publique de la politique de confidentialité.

Décisions en attente : voir DECISIONS_EN_ATTENTE.md (L13 non bloquant, dont l'URL de la politique ; D-MA-00 fusion de la refonte faite en 4.3.1 ; L12 dont le barème des récompenses, L11, L10 et L9b, non bloquantes ; L9R et L8 tranchées)
