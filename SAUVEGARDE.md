# Sauvegarde RV1c1

## Fait (21/10 ~20:50 UTC)
- ETAT « en cours depuis 2026-10-21 20:12 UTC » (pipeline 3e4c09b).
- Base : claude/ci-3d e0337102 (arbre RV1 1676c9ee). Branche locale rv1c1 ; code commit 09bbdab.
- TimerCtl : `groupClock` / `groupRunning` (emom, startInterval, AMRAP group:true, CHRONO group:true) ; `startRest`, `add` sans effet pendant un groupe ; `solo` / `soloStopwatch` : tenue, durée, mini-repos → chrono secondaire `side` pendant un groupe, chrono principal sinon.
- Barre : chrono de groupe en `_ClockBar` (sans ±15 s) ; `_SideClock` au-dessus (clé `side-clock`).
- `hasTimer` : pas de sablier dans un groupe d'intervalles (groupe de l'exercice, chemins B/C/D du sous-agent).
- SessionScreen(timer:) pour les tests. Tests `test/rv1c1_chronos_test.dart`, cible `integration_test/rv1c1_chronos_test.dart` inscrite dans `tools/ci3d_drive.sh`.
- Contrôle rapide poussé sur `claude/ci-ui-rv1c1-rapide`.

## Décision
- Solution : chrono de tenue secondaire (au-dessus de la barre du groupe), le groupe n'est jamais remplacé ; hors groupe, inchangé.

## Reste
- Résultat du rapide (format.patch, analyse, tests) ; ci-3d après le run RV1 ; publication après dev7.5.0 (version 7.5.1 : pubspec, kVersion, tests de version) ; build ; livraison ; ETAT ; page ; notification.
- Limite à signaler : chemin C sans groupId (échange moteur hors bloc importé) : sablier par tour possible, pas de « Lancer » (paquet).

## Avancement 20:40 UTC
- Contrôle rapide vert (run 39671097026, 8 tests rv1c1, format, analyse) ; version 7.5.1+150 et tests de version faits (commit 09d7f2d).
- Run RV1 sur ci-3d fini vert (39660495300) ; contrôle complet RV1c1 poussé sur `claude/ci-3d` 61718d87 à 20:39 UTC (RV1 ne relancera pas : son run est vert).
- Reste : résultat ci-3d (checks + émulateur, captures rv1c1_*), attendre dev7.5.0 sur main, rebase, publier, build, livraison, ETAT, page, notification.

## Avancement 21:02 UTC
- Run ci-3d 39672136872 (61718d87) : contrôles verts sauf python (jeton : `EdgeInsets.only(bottom: … : 0)` dans `_TimerBar`) ; corrigé (a51bac9, SizedBox conditionnel), contrôle complet relancé sur ci-3d 40665505 à 21:01 (l'ancien run annulé par la concurrence).
- SUIVI_PROJET.md à jour (commit local). Brouillon de livraison : /tmp/claude-0/LIVRAISON_RV1_correction1.md (copié ici dans LIVRAISON_brouillon.md).
- main encore à dev7.4.0 (0e063fd) : attendre dev7.5.0 de RV1.
