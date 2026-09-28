# État du pipeline « Mannequin 3D »

Tâche planifiée du pipeline : **trig_01XQEhzWVVib4xQR5bGnTpyn** (« Kalis Track — pipeline mannequin 3D (v4) », depuis le 28/09 13:05). Ne plus relancer v1 (trig_018sJFdjtWKnTBU2BzWjBzFb), v2 (trig_018MeUFjYtNVBWKVjkgRUPWg) ni v3 (trig_01Sa99tJfHPgGirxHQgx1mgs) : une tâche modifiée après sa création (approbation automatique ou autre réglage) perd l'accès push au dépôt et ses lancements s'arrêtent au bout d'environ 30 s. Aucun lot ne modifie ni ne crée de tâche planifiée.
Activation : **manuelle par le propriétaire** (premier lancement de M1 seulement sur son ordre).
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
| M5 | 5.4.0 | — | — | — | à faire |
| M6 | 5.5.0 | — | — | — | à faire |
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
