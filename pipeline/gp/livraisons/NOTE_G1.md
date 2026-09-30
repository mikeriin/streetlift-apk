# G1 — état au 01/10/2026 (Opus 5.5)

Lot terminé, contrôles verts, **publication sur `main` refusée** par les permissions de la session (push bloqué).

- Commit prêt : `b3a3d73` sur la branche `claude/g1-6.0.0`, parent = `main` 601a04d (avance rapide possible).
- Build signé sur ce commit : run 36792378355 (APK de développement + AAB, `--dev-apk` vérifié).
- CI GP (claude/ci-3d) : run 36791220317 — formatage, analyse, 1 019 tests Dart, 10 tests du mode dev, Python, paquets (aucun), émulateur G1 a (sombre) + b (clair, redémarrage à froid réel) verts ; rendus `visual_capture_test` en échec comme sur main.
- Page de suivi : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5
- Pour clore G1 : fusionner `claude/g1-6.0.0` dans `main`, puis (conversation de pilotage ou relance de G1) : `LIVRAISON_G1.md`, statut « à valider », notification « prêt à tester ».
