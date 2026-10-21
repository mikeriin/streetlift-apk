# L1b — Validation Android et procédure depuis un téléphone

Date de consultation des sources : **25 septembre 2026**. Périmètre : KT-010, KT-011, KT-012, KT-019 et preuves techniques L1 restantes. Aucun déploiement Google Play automatique.

## Base et décisions

Base unique : livraison L1-R2, `streetlift_tracker_v33.zip`, 1 238 962 octets, SHA-256 `9dfd6221954a1acd673804a498f703ed245f14fd4f8540af9f29e769d584e698`. Empreinte recalculée et identique. Aucune substitution par R1 ou A0. Le suivi et le workflow embarqués dans R2 servent de référence ; les corrections R2 de signature sont conservées.

| Élément | R2 → L1b | Motif / limite |
| --- | --- | --- |
| Flutter / Dart | 3.29.3 / 3.7.2, conservés | Analyse et tests locaux disponibles ; pas de migration générale |
| Java | 17, conservé | Version attendue par AGP |
| Gradle / AGP | 8.13 / 8.12.1, conservés | AGP 8.12 prend en charge API 36 et demande Gradle 8.13 / JDK 17 [S3] |
| Kotlin | 2.2.10, conservé | Combinaison déjà compilée dans les logs R1. AGP 8.12.1 dépasse toutefois la plage entièrement testée publiée par JetBrains pour Kotlin 2.2.10 (jusqu’à AGP 8.10) : risque documenté, nouvelle compilation CI requise [S4] |
| compileSdk / targetSdk | 36 / 35 → 36 / 36 | Cible mobile standard actuelle de soumission [S1] |
| minSdk | 21, conservé | Le manifeste final doit aussi annoncer 21 ; un minimum imposé par un plugin fera échouer le contrôle, sans augmentation silencieuse |
| NDK | défaut Flutter 26.3.11579264 → r28c 28.2.13676358 | Les logs signalent des plugins demandant r27 ; r28 ajoute l’alignement 16 Ko par défaut pour les bibliothèques recompilées [S2, S5] |
| Build Tools | 36.0.0 explicitement sélectionnés | apksigner et zipalign connus, sans dépendre du dernier outil préinstallé |
| bundletool | 1.18.2, nouvel outil de contrôle CI | Structure/manifeste/configuration AAB ; téléchargement officiel avec SHA-256 épinglé [S6] |
| Dépendances Dart / desugaring | pubspec.lock inchangé / 2.1.4 inchangé | Aucun renouvellement de dépendances par principe |

L’identifiant reste `fr.tchoupi.streetlift_tracker`, version déclarée `2.5.0+51`. Le wrapper Gradle et les assets restent identiques à R2. L’empreinte du certificat public reste `9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`. Elle identifie la référence du projet ; elle ne constitue pas à elle seule une preuve du certificat de l’APK installé.

## Exigences vérifiées et limites de compatibilité

Google Play exige API 36 pour les nouvelles applications et mises à jour mobiles depuis le 31 août 2026. Une prolongation au 1er novembre est mentionnée, mais aucune prolongation propre à ce projet n’est présumée [S1].

La documentation Android consultée exige la prise en charge des pages 16 Ko pour les applications ciblant API 35+ sur les appareils 64 bits et annonce le blocage des mises à jour non compatibles à partir du **1er février 2027** [S2]. Cette date remplace, pour cette passe, toute échéance reprise de l’ancien audit. La cible et le NDK seuls ne prouvent pas cette compatibilité : les bibliothèques précompilées et les artefacts finaux sont contrôlés séparément.

Le contrôle ELF examine LOAD et RELRO. Pour RELRO, il suit les règles préfixe/suffixe et le cas où RELRO couvre les mêmes sections que le LOAD, publiés dans le code Android [S7]. Ce cas est utile aux moteurs Flutter précompilés ; un simple modulo sur la fin de RELRO serait insuffisant. Ce contrôle statique ne remplace pas un lancement sur un système 16 Ko.

Avec cible 36 sur Android 16, vérifier aussi le contenu sous les barres système, le retour gestuel/prédictif et les grands écrans [S8, S9]. Flutter reste volontairement inchangé tant qu’une incompatibilité concrète n’est pas démontrée. Aucun ajustement global d’apparence, orientation ou sauvegarde Android n’est inclus.

## Contrôles livrés dans GitHub Actions

Les étapes exécutées, dans cet ordre, sont les suivantes :

1. Extraire le ZIP, contrôler son contenu, comparer les deux workflows, vérifier les assets ; enregistrer empreintes d’entrée et commit.
2. Installer API 36, Build Tools 36.0.0 et NDK r28c ; télécharger bundletool vérifié ; enregistrer les versions disponibles.
3. Résoudre les dépendances avec le lockfile, contrôler `dart format`, lancer l’analyse, les tests Python et Flutter. Une erreur dans une commande transmise à `tee` reste bloquante (`bash -e -o pipefail`).
4. Générer les icônes avec l’outil existant.
5. Tenter réellement cinq builds release sans secrets valides : APK et AAB sans les deux secrets ; APK sans mot de passe ; AAB sans conteneur ; APK avec base64 invalide. La commande doit échouer **avec le diagnostic Gradle de signature attendu**. Une erreur SDK/réseau ne vaut pas réussite. Les seules valeurs injectées sont des fixtures synthétiques, aucune clé n’est créée.
6. Calculer une seule fois `BUILD_NUMBER`, selon la formule R2 (secondes depuis 2020, avec plancher lié au numéro de run). Restaurer la clé existante à partir des deux secrets déjà configurés.
7. Compiler APK et AAB depuis cette même extraction, sans mise à jour des sources ou dépendances entre les deux builds et avec le même numéro.
8. Vérifier les deux vrais artefacts comme décrit ci-dessous. Copier et publier les binaires seulement si tous ces contrôles passent.
9. Conserver le rapport de validation même en cas d’échec, puis supprimer seulement la copie temporaire de clé du runner.

Aucun test Python simulant ces cinq refus ne prouve une exécution Gradle. La preuve attendue est `without-secrets/release-sans-secrets.json` accompagné de ses cinq journaux dans l’artefact de validation du nouveau run.

## Vérification des artefacts finaux

| Contrôle | APK | AAB |
| --- | --- | --- |
| Signature | Contrôleur Java R2 inchangé utilisant `ApkVerifier` ; vérification cryptographique et certificat exact, sans rotation | Vérification JAR du JDK 17, lecture intégrale de chaque entrée utile ; toutes signées par une seule identité correspondant à la référence |
| Structure et manifeste | `apkanalyzer manifest print` | `bundletool validate`, puis `dump manifest --module=base` |
| Identité et versions | Application ID attendu, versionName 2.5.0, versionCode commun, minSdk 21, targetSdk 36, non débogable | Mêmes exigences |
| Manifeste conservé | XML final, permissions, attributs application et composants/exported dans le rapport | XML final, mêmes permissions que l’APK ; pas d’arbitrage implicite sur la sauvegarde système |
| Pages mémoire | `zipalign -v -c -P 16 4` et analyse ELF de toutes les `.so` 64 bits | Configuration `PAGE_ALIGNMENT_16K`, analyse ELF ; même liste et mêmes SHA-256 des bibliothèques natives que l’APK |
| ABI | arm64-v8a, x86_64 et armeabi-v7a attendues, avec libflutter.so et libapp.so | Mêmes ABI ; les règles 16 Ko ne sont pas attribuées à l’ABI 32 bits |
| Traçabilité | Taille et SHA-256 du fichier final | Taille et SHA-256 du fichier final |

Fichiers attendus dans `kalis-track-validation` : `inputs.sha256`, `commit.txt`, `build-number.txt`, versions d’outils, journaux analyse/tests/refus, `android-artifacts.json`, `apk-manifest.xml`, `aab-manifest.xml`, `aab-config.json`, `apk-zipalign.txt`.

Un AAB ne s’installe pas directement sur un téléphone. Sa présence dans les artefacts GitHub prépare une future publication ; elle ne valide ni Play App Signing, ni les règles de publication, ni tous les APK fractionnés qui seront générés par Google Play.

## Actions du propriétaire — ordre exact, depuis le téléphone

1. Conserver le ZIP/APK L1 fonctionnel et un export des données de l’application hors de son stockage. Ne pas désinstaller l’application.
2. Conserver les deux secrets GitHub existants et la sauvegarde privée de la clé. Aucune nouvelle saisie ou conversion de secret n’est nécessaire pour L1b.
3. Dans le navigateur du téléphone, ouvrir le dépôt, onglet **Actions**, workflow de compilation, menu **… → Disable workflow**. Cela évite une compilation entre les deux remplacements si l’interface mobile les réalise en deux commits. Utiliser l’affichage « version ordinateur » si nécessaire.
4. À la racine du dépôt, remplacer `streetlift_tracker_v33.zip` par celui de L1b via **Add file → Upload files**, puis enregistrer le commit. Ne pas charger un ZIP GitHub enveloppant ce fichier.
5. Ouvrir `.github/workflows/build-apk.yml`, utiliser **Edit**, remplacer son contenu par le `build-apk.yml` livré séparément et enregistrer le commit. Ce fichier est identique à la copie interne du nouveau ZIP.
6. Réactiver le workflow dans **Actions**, puis **Run workflow** sur la branche contenant ces deux nouveaux fichiers. Ne pas choisir « Re-run jobs » sur un ancien commit.
7. Attendre tous les contrôles. Télécharger `kalis-track-validation`, `kalis-track-apk` et `kalis-track-aab` depuis le résumé du même run. En cas d’échec, transmettre le journal de l’étape concernée et le rapport de validation disponible, sans secret. Ne pas contourner le contrôle ayant échoué.
8. Extraire `kalis-track-apk`, ouvrir `kalis-track.apk` et accepter l’installation **comme mise à jour**. Si Android refuse, conserver l’application et ses données, relever le message exact et arrêter cette installation ; ne pas désinstaller pour contourner le refus.
9. Ouvrir, fermer puis rouvrir l’application ; vérifier historique, séances, crédits, WOD acquis et réglages. Cette validation doit être répétée pour L1b, même si elle est déjà confirmée pour L1.
10. Tester une fin de séance et son bilan, le bouton Continuer après défilement, le catalogue et l’essai du jour. Vérifier textes et actions avec taille de police habituelle puis agrandie (environ 130 % et 200 % si disponibles), clavier ouvert, navigation par gestes et boutons, portrait et paysage. Les achats sont testés automatiquement avec des données fictives ; un essai manuel d’achat sur les données réelles doit rester une action volontaire du propriétaire.
11. Noter modèle du téléphone, version Android, réglages de texte et résultat observé. Sous Android 16, contrôler particulièrement barres système, Retour depuis séance/bilan et boutons en bas de page. Rétablir ensuite les réglages de texte/navigation souhaités.
12. Conserver l’AAB et son SHA-256 pour la préparation de publication. Ne pas activer Play App Signing ni publier sur Google Play dans ce lot. Transmettre les résultats du run et du téléphone pour compléter les validations ouvertes.

## Essai 16 Ko restant

Le lancement sur le téléphone déclaré pour L1 ne prouve pas une taille de pages 16 Ko. Une preuve technique de `getconf PAGE_SIZE` égale à **16384**, puis lancement à froid et essais (navigation, sons/notifications, séances, chronos, sauvegarde) sur ce système reste requise. Si le téléphone dispose d’un mode développeur 16 Ko pris en charge par son fabricant, utiliser la procédure officielle [S2] en conservant la sauvegarde préalable. Sinon, cet essai nécessite ultérieurement un appareil ou un émulateur 16 Ko ; aucune commande de terminal n’est imposée au propriétaire disposant seulement de son téléphone. Statut : **non exécuté**. Le workflow livré fait les contrôles statiques, pas cet essai d’exécution.

## Sources officielles consultées le 25 septembre 2026

- [S1 — Exigences de cible Google Play](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- [S2 — Android, pages mémoire 16 Ko](https://developer.android.com/guide/practices/page-sizes).
- [S3 — AGP 8.12, compatibilité Gradle/JDK/API](https://developer.android.com/build/releases/agp-8-12-0-release-notes).
- [S4 — Kotlin Gradle Plugin, matrice de compatibilité](https://kotlinlang.org/docs/gradle-configure-project.html) et [support Kotlin Android](https://developer.android.com/build/kotlin-support).
- [S5 — Révisions du NDK](https://developer.android.com/ndk/downloads/revision_history).
- [S6 — bundletool](https://developer.android.com/tools/bundletool) et [version 1.18.2](https://github.com/google/bundletool/releases/tag/1.18.2).
- [S7 — Source Android PageAlignUtils, révision 7765a1e4](https://android.googlesource.com/platform/tools/base/+/7765a1e4385997e1919311925a88cbd12218f818/sdk-common/src/main/java/com/android/ide/common/pagealign/PageAlignUtils.kt).
- [S8 — Changements Android 16 pour cible 36](https://developer.android.com/about/versions/16/behavior-changes-16).
- [S9 — Flutter, comportement edge-to-edge](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge).
