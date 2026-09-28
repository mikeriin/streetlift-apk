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
| M56 | — | — | — | — | à faire |
| M6b | — | — | — | — | à faire |
| M7 | 5.6.0 | — | — | — | à faire |
| M8 | 5.7.0 | — | — | — | à faire |
| M9 | 5.8.0 | — | — | — | à faire |
| M10 | 5.9.0 | — | — | — | à faire |
| M11 | 5.10.0 | — | — | — | à faire |
| M12 | 5.11.0 | — | — | — | à faire |
| M13 | 5.12.0 | — | — | — | à faire |
| M14 | 5.13.0 | — | — | — | à faire |
| M15 | 5.14.0 | — | — | — | à faire |
| M16 | 5.15.0 | — | — | — | à faire |
| M17 | 5.16.0 | — | — | — | à faire |
| M18 | 5.17.0 | — | — | — | à faire |
| M19 | 5.18.0 | — | — | — | à faire |

Compatibilité du téléphone du propriétaire (réponse attendue après M1) : **Compatible, 120 images/s** (réponse du propriétaire, 27/09/2026, sur 5.0.0) → pipeline relancé pour M2.
