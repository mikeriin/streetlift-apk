# État du pipeline « Mannequin 3D »

Tâches planifiées (lancement manuel par la conversation de pilotage, lot indiqué dans le message « Lot : <LOT> ») : **Fable 5.1 effort maximal** trig_01Vzab2sFaAoMFNcNepFhEGX (M56, M12) ; **Opus 5.5 effort élevé** trig_01GMgdzWoZ9At48KZ6PUZxSk (tous les autres lots). Aucun lot ne relance, ne modifie ni ne crée de tâche. Validation manuelle de chaque lot par le propriétaire avant le suivant (statut « à valider » → « validé »).
Page de suivi : https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA
Base de départ : main 4.3.1+71 (commit 7f07e2e, L13 + refonte muscles 2D fusionnés).
Le prompt `pipeline/prompt_POC3D.txt` (prototype isolé) est remplacé par ce pipeline et ne doit pas être lancé.

| Lot | Version | Commit main | Run | Date | Statut |
| --- | --- | --- | --- | --- | --- |
| M1 | 5.0.0 | fe96d19 | build n° 97 (36351752086) ; CI 3D 36350581902 | 2026-09-27 | livré |
| M2 | 5.1.0 | f29e880 | build n° 98 (36366289332) ; CI 3D 36364366340 | 2026-09-28 | livré |
| M3 | 5.2.0 | 2fd86d2 | build n° 99 (36382919900) ; CI 3D 36381559870 | 2026-09-28 | livré |
| M4 | 5.3.0 | acb5034 | build n° 100 (36398571739) ; CI 3D 36393809265 | 2026-09-28 | livré |
| M4b | 5.3.1 | 4531346 | build n° 101 (36409875811) ; CI 3D 36408180487 | 2026-09-28 | livré |
| M4c | 5.3.2 | 67ec551 | build n° 112 (36431053547) ; CI 3D 36428956594 | 2026-09-28 | livré |
| M5 | 5.4.0 | b745c41 | build n° 121 (36456576585) ; CI 3D 36454868372 | 2026-09-28 | livré |
| M6 | — | — | — | 2026-09-28 | remplacé par M56 (session Opus lancée à 18:05 UTC, plus pilotée ; son travail sert de brouillon) |
| M56 | 5.5.0 | 7a24fc0 | build n° 133 (36509815224) ; CI 3D 36508242229 (5 essais) | 2026-09-29 | validé (avec ses corrections 1 à 4) — `livraisons/LIVRAISON_M56.md` |
| M56 correction 1 | 5.5.1 | 786e867 | build n° 137 (36537833401) ; CI 3D 36535840924 (3 essais) | 2026-09-29 | remplacé par 5.5.2 — `livraisons/LIVRAISON_M56_correction1.md` |
| M56 correction 2 | 5.5.2 | 5aeb2d1 | build n° 142 (36554048481) ; CI 3D 36551761380 (4 essais) | 2026-09-29 | remplacé par 5.5.3 — `livraisons/LIVRAISON_M56_correction2.md` |
| M56 correction 3 | 5.5.3 | b01bb75 | build n° 146 (36561741052) ; CI 3D 36560553169 (3 essais) | 2026-09-29 | remplacé par 5.5.4 — `livraisons/LIVRAISON_M56_correction3.md` |
| M56 correction 4 | 5.5.4 | 9826982 | build n° 152 ; CI 3D 36571687956 | 2026-09-29 | validé (29/09/2026, 17:00) — [page de suivi](https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA), `livraisons/LIVRAISON_M56_correction4.md` ; halo des zones travaillées (maillage gris), fond sans démarcation ; remplace 5.5.3 |
| M6b | 5.5.5 | 019fa08 | build n° 159 (36601660192) ; CI 3D 36599218965 (essais A à E) | 2026-09-29 | à valider — [page de suivi](https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA), `livraisons/LIVRAISON_M6b.md`, `docs/AUDIT_M6b.md` ; 11 défauts corrigés |
| M6c | — | — | — | — | à faire (ajouté le 29/09 : personnage Mixamo Ch36, source chiffrée `pipeline/3d/inputs/character_mixamo_ch36.fbx.enc`) |
| M7 | — | — | — | — | à faire (redéfini le 29/09 : lecteur, import des animations du propriétaire, animation de débogage) |
| M8 | 5.7.0 | — | — | — | à redéfinir (plus d'animation) |
| M9 | 5.8.0 | — | — | — | à redéfinir (plus d'animation) |
| M10 | 5.9.0 | — | — | — | à redéfinir (plus d'animation) |
| M11 | 5.10.0 | — | — | — | à redéfinir (plus d'animation) |
| M12 | 5.11.0 | — | — | — | à redéfinir (plus d'animation) |
| M13 | 5.12.0 | — | — | — | à redéfinir (plus d'animation) |
| M14 | 5.13.0 | — | — | — | à redéfinir (plus d'animation) |
| M15 | 5.14.0 | — | — | — | à redéfinir (plus d'animation) |
| M16 | 5.15.0 | — | — | — | à redéfinir (plus d'animation) |
| M17 | 5.16.0 | — | — | — | à redéfinir (plus d'animation) |
| M18 | 5.17.0 | — | — | — | à redéfinir (plus d'animation) |
| M19 | 5.18.0 | — | — | — | à faire |

Compatibilité du téléphone du propriétaire (réponse attendue après M1) : **Compatible, 120 images/s** (réponse du propriétaire, 27/09/2026, sur 5.0.0) → pipeline relancé pour M2.
