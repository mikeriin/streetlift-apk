# Livraison M1 — Socle du moteur 3D (Kalis Track 5.0.0)

**Date** : 27/09/2026 · **Version** : 5.0.0+72 · **Commit main** : fe96d19 · **Build signé** : run 36351752086 (n° 97)

## Ce que tu vois dans l'appli
- Rien ne change pour l'entraînement (écrans, données, sauvegardes identiques).
- **Réglages › À propos › Moteur 3D** : figure 3D grise dont le sommet rayonne dans le rouge historique (halo en thème sombre), à tourner au doigt ; « Compatible / Non compatible », Flutter GPU, API graphique, appareil, version d'Android ; mesure de fluidité sur 10 s (images/s, temps moyen, 99e centile).
- Android 7.0 minimum (exigence de Flutter 3.47).

## À faire
Installe 5.0.0, ouvre Réglages › À propos › Moteur 3D, attends la fin de la mesure et réponds dans la session : compatible ou non, et les images/s. Le pipeline reprend (M2) si « Compatible » avec au moins 45 images/s.

## Technique
- Flutter 3.29.3 → 3.47.5 (Dart 3.13.4) ; flutter_scene 0.23.0 ; Flutter GPU activé dans le manifeste (Impeller par défaut).
- Android : minSdk 24, Gradle 8.14.3, Kotlin 2.3.20, AGP 8.12.1 ; bibliothèques natives compressées dans l'APK.
- Dépréciations de Flutter 3.47 migrées sans changement de comportement ; formatage Dart 3.13.
- CI 3D : `.github/workflows/ci-3d.yml` (branche `claude/ci-3d`), rendu réel sur émulateur, méthode dans `docs/CI_3D.md`.

## Contrôles
- CI 3D (run 36350581902) : formatage, analyse sans remarque, 856 tests Dart réussis (13 ignorés, 0 échec), Python 82/82, intégrité, ZIP, builds debug et profile.
- Émulateur Android 15 : « Compatible », Impeller OpenGL ES ; captures regardées (sombre avec halo, rotation, mesure, clair, entrée Réglages).
- Rendus de test avant / après la mise à jour de Flutter : petites différences de tracé seulement.
- Build signé `build-apk.yml` : run 36351752086 (n° 97) réussi ; APK 35,0 Mo, soit +4,7 Mo (4.3.1 : 30,3 Mo).

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Fluidité de la CI non représentative (émulateur logiciel) ; la mesure du téléphone décide.
- `test/visual_capture_test.dart` (captures facultatives) échouait déjà avant M1 ; non corrigé.
- Build signé n° 95 en échec (`integration_test` référencé en release) puis n° 96 réussi mais APK de 73,5 Mo (bibliothèques natives non compressées avec minSdk 24) ; corrigés, build n° 97 livré.
- Mise en pause de la CI (quota GitHub Actions) jusqu'au passage du dépôt en public par le propriétaire.
