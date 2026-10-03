# Résultats locaux L1b — 25 septembre 2026

Ces journaux concernent la copie reconstruite depuis R2. Flutter 3.29.3, Dart 3.7.2, Java 17, Python 3.12 ; SDK Android absent. Aucun APK/AAB Kalis L1b compilé ici.

- `flutter-tests.log` : suite complète, 193 réussites, 1 capture déjà optionnelle ignorée.
- `python-tests.log` : 33 réussites. Les lignes « refus Gradle attendu observé » proviennent de **mocks de subprocess**, pas d’un build Android ; voir les noms `ReleaseRefusalTests`. Seul le test Java de rejet d’un AAB non signé exécute ici le vrai vérificateur AAB sur une fixture.
- `analyze.log` : transcription de la sortie terminal observée, sans erreur.
- `format-check.log` : vérification sans modification, 71 fichiers.
- `dart-fix.log` : cinq accolades ajoutées, trois fichiers, après formatage.
- `assets.log` : contrôle des ressources et de l’identité du projet.
- `pub-get.log` : résolution hors ligne des dépendances verrouillées ; les archives ont été vérifiées contre les SHA-256 des lockfiles avant mise en cache.
- `flutter-engine-16k.json` : ELF des libflutter.so ARM64/x86_64 du SDK release ; **ne concerne pas encore les bibliothèques finales de Kalis ni l’exécution sur appareil**.
- `bundletool.log` et `actionlint.txt` : outils de préparation réellement exécutés ; aucun AAB Kalis soumis à bundletool dans cet environnement.

Archive officielle du SDK Flutter : SHA-256 `8a908a5add53c1dfc2031da29e58daefd59a6d1d52fb5cb61f5ee52c73e36e15`. SDK, caches, outils téléchargés et binaires d’application exclus du ZIP projet.

Les preuves restantes doivent venir du nouveau run Actions décrit dans `docs/VALIDATION_ANDROID_L1b.md`, puis des essais du propriétaire. Les confirmations de téléphone L1 sont consignées distinctement dans `SUIVI_PROJET.md`.
