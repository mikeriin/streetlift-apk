# Kalis Track — Suivi du projet

**Passe actuelle : L2 — Sauvegarde et achats (KT-002, KT-013, KT-014, KT-015, KT-005)**  
**Date : 25 septembre 2026, Europe/Paris — version : 2.5.2+53 (versionCode réel fixé par la CI de build)**  
**Statut : L2 implémenté, arbitrages KT-005 (option C) et KT-014 (règle d'usage) appliqués ; formatage, analyse et suite Flutter complète réussis en CI sur branche temporaire (sans build APK). Build signé et essai téléphone L2 en attente. L2b, L3 et la refonte ne sont pas lancés.**

## L2.0 — Base retenue

| Élément | Valeur |
| --- | --- |
| Source | `streetlift_tracker_v33.zip` de `main`, commit `f7f8518` (L1b-R2), **1 277 631 octets**, SHA-256 `53474eabc64cffaeddce571808774cfc5824fb4f4bf206af74447b7e5ebcb0ed`, racine `streetlift_tracker/`, 299 fichiers, version 2.5.1+52 |
| Provenance | Même archive que celle compilée par le run n° 71 (succès, 21 étapes). `SUIVI_PROJET.md` remplacé par la version livrée séparément après L1b (plus récente que la copie interne, écart documenté dans LIVRAISON_L1b) |
| Travail | Copie extraite ; archive source gardée en lecture seule, intacte |
| État L1b | Compilé et contrôlé en CI (run n° 71). **Essai téléphone L1b non encore rapporté** : non compté comme validé. Il est repris dans le protocole L2 |
| Résultats L1 déjà confirmés par le propriétaire | Compilation et ouverture, contrôle du certificat et artefact GitHub, installation en mise à jour sans désinstallation, historique/séances/crédits/WOD acquis/réglages conservés. Conservés tels quels, non transformés en preuve L1b |

## L2.1 — Lecture ciblée (constats vérifiés dans le code L1b-R2)

- **KT-002 confirmé** : `unlockWod` modifiait `unlockedWods`, lançait une écriture non attendue, renvoyait `true` ; `wod_preview.dart` jouait révélation et message aussitôt.
- **KT-013 confirmé, plus grave que l'audit** : chaque sauvegarde ordinaire encodait l'état **au moment de la demande** et s'enchaînait sur `_pendingWrite` ; `importAll` attendait cette file sans s'y inscrire, puis écrivait. Une sauvegarde demandée pendant cet import (état antérieur encodé) pouvait être écrite **après** l'import : mémoire importée, disque ancien. Pas de copie de l'état remplacé. L'import annulait aussi le minuteur de sauvegarde différée.
- **Défaut de test révélé** : la file s'enchaînait sur un `Future` créé dans la zone du démarrage ; dans une zone de test à horloge simulée, la suite n'était jamais exécutée (cause réelle du blocage de test observé en L1b-R2).
- **KT-014 confirmé** : branche d'anciennes préférences (`credits_v < 2`) : `unlockedWods.removeWhere(v == 0)`, suppression définitive. À l'inverse, un import format 1/2 contenant des coûts 0 les gardait comme accès gratuits : deux règles contradictoires.
- **KT-015 confirmé** : `_unpack` décompressait sans plafond ; aucune limite globale de taille, de valeurs ou de collections avant analyse.
- **KT-005 inchangé** : crédits = barème(niveau) + bonus dérivés − achats, plancher 0.

## L2.2 — Changements

| Ticket | Code | Comportement retenu |
| --- | --- | --- |
| KT-002 | `store.dart` : `purchaseWod(w, acceptedCost)` → `PurchaseResult` (`success`, `alreadyOwned`, `pending`, `insufficientCredits`, `priceChanged`, `failed`), `purchasePending`, réservation dans `creditsSpent`, `unlocked()` faux tant que l'écriture n'est pas acceptée. `unlockWod` synchrone supprimé. `wod_preview.dart` : bouton « Achat en cours… », message par état, révélation seulement après succès, message affiché même si la fiche est fermée. | Prix payé = offre affichée, sinon `priceChanged` sans débit. Double appui : `pending`, un seul débit. Achats simultanés : le solde réservé empêche toute dépense excessive. Échec : seul ce droit est retiré de la mémoire (s'il vaut encore ce prix) ; les modifications faites pendant l'attente sont gardées ; le cache SharedPreferences revient au dernier document accepté. Un droit déjà acquis n'est jamais retiré. |
| KT-013 | `store.dart` : file explicite `_serialize` (démarrée par microtâche dans la zone de l'appelant) ; sauvegardes regroupées et encodées **à l'exécution** ; `_writeRaw` rétablit le cache en cas de refus ; compteurs `_changeSeq` / `_acceptedSeq`, `hasUnsavedChanges`, `retrySave()` ; `importBackup` dans la file, copie de récupération préalable (`kalis_recovery_v1`, 3 dernières), application en mémoire seulement après écriture acceptée ; liste de copies illisible → import suspendu, rien écrasé. `main.dart` : alerte d'erreur avec **Réessayer**. `debugWriteHook` (tests uniquement) pour injecter refus et délais. | Distinction explicite : modification en mémoire (`_changeSeq`), écriture acceptée par l'API (`_acceptedSeq`), conservation après relance (vérifiée seulement en relisant le stockage, dans les tests par nouvelle instance ; sur téléphone par le protocole). Aucune garantie de durabilité à l'arrêt brutal n'est déclarée : SharedPreferences 2.5.3 ne la promet pas. Le stockage n'est pas remplacé. |
| KT-014 | `store.dart` : `legacyGrants` (id → origine), exporté/importé (clé optionnelle `legacyGrants`, ignorée par les anciennes versions). Migration `credits_v < 2` et import formats 1-2 : un coût 0 d'un WOD du catalogue **ayant au moins un résultat** reste acquis à coût 0 ; sans résultat, il est archivé dans `legacyGrants` (`credits_v1` / `import_format_N`), sans accès. Format 3 : coûts 0 gardés comme droits établis. | Arbitrage du propriétaire (25/09/2026 : « le plus logique selon toi ») : droit établi par l'usage. Aucune donnée détruite ; aucun accès gratuit au catalogue entier ; aucun débit (coût 0). |
| KT-015 | `persistence.dart` : `ImportLimits` (valeurs standard ci-dessous), `boundedUnpack` (base64 puis gzip par morceaux de 16 Kio vers un tampon qui refuse de dépasser la limite **pendant** le flux), `boundedJsonDecode` (compte valeurs et longueur des textes pendant l'analyse) ; `_checkCollections` avant conversion. `settings_screen.dart` : messages distincts (invalide / trop volumineuse / écriture refusée). | Limites : texte 8 Mio car. ; JSON décompressé 32 Mio ; 2 000 000 valeurs ; texte isolé 100 000 car. ; 20 000 séances ; 500 000 séries ; 100 000 résultats WOD ; 20 000 entrées par autre collection. Mesure représentative (40 semaines entièrement saisies, 60 séances perso dont 20 répétées, 300 résultats, 30 achats) : **1 037 555 octets de JSON, 49 183 caractères compactée, 71 374 valeurs** : marge ≥ 30× sur chaque limite. Le démarrage relit l'état produit par l'application sans ces limites (une grosse histoire légitime ne bloque jamais l'ouverture). |
| KT-005 | `store.dart` : `creditsFromJournal` (calcul actuel), `_earnedMax` (plus haut enregistré, mis à jour à chaque écriture acceptée), `creditsEarned = max(journal, plus haut)`, clé de sauvegarde optionnelle `creditsEarnedMax` (entier 0-1 000 000, sinon import refusé). | **Option C retenue par le propriétaire (25/09/2026)** : crédits gagnés jamais repris, XP et niveau recalculés depuis le journal (le niveau peut redescendre). Refaire une performance supprimée ne redonne rien sous le plus haut. Import = remplacement : le plus haut de la sauvegarde remplace le courant (absent → calcul du journal). Migration : absent au premier lancement → calcul actuel, aucun crédit créé ni retiré. |

## L2.3 — Tests

| Niveau | Résultat |
| --- | --- |
| État initial (L1b-R2, run n° 71 et suite complète) | 202 réussis, 1 ignoré |
| Nouveaux tests | `l2_persistence_test.dart` (41 : 8 achats, 9 écritures/imports, 10 droits historiques, 8 imports bornés, 6 contrat KT-005 option C), `l2_purchase_ui_test.dart` (2 widget à 320 px), jeux `l2_fixtures.dart` (neuf, rempli, perso répétées, achats normaux/remisés, coût 0, formats 1/2/3, dégradés, bombe de compression contrôlée) |
| Tests existants adaptés | `store_test`, `wod_store_test`, `wod_acquisition_test` : appel `unlockWod` → `await purchaseWod`, assertions conservées (un seul débit, prix remisé figé, refus faute de crédits). `reward_flow_test` : son `setUp` vide le journal entre deux cas ; il remet aussi à zéro le plus haut des crédits (`debugResetEarnedCredits`, tests uniquement), sans quoi l'option C garde les crédits du cas précédent. Aucune assertion retirée. |
| CI branche temporaire `claude/ci-tools` (sans secret, sans build), arbre final | Formatage : 76 fichiers, 0 changement ; `flutter analyze` : No issues found ; tests ciblés 84/84 ; **suite complète 245 réussis, 1 ignoré**, sortie 0 |
| Python | 33/33 en local (outils inchangés) |
| Erreurs simulées | Refus d'écriture, cache modifié puis refus, écritures suspendues (Completer) : oui, via `debugWriteHook` |
| Stockage réel / redémarrage réel / arrêt brutal / appareil | **Non exécutés.** « Relance » des tests = nouvelle instance relisant le stockage simulé |
| Build APK/AAB signé L2 | **Non exécuté** : `main` non modifié conformément au lot |

## L2.4 — KT-005 : contrat de conservation des crédits (option C retenue et appliquée)

Décisions déjà prises dans cette conversation : correction d'une séance = XP retiré puis rendu à la revalidation ; suppression = XP et bonus retirés, droits WOD gardés ; `_lastLevel` ne redescend pas. **Aucune décision n'a été prise sur les crédits.**

Barème actuel : niveau atteint à `25 × (n − 1) × (n + 4)` XP (N2 = 150, N3 = 350, N4 = 600, N5 = 900) ; crédits de niveau `1 + 2n + 3⌊n/5⌋` (N4 = 9, N5 = 14) ; bonus chapitre +3, boss +5, semaine complète +1.

**Exemple** : 900 XP (N5 → 14) + 3 semaines complètes (+3) = 17 gagnés ; 15 dépensés ; solde 2. Suppression d'une séance du programme (−100 XP de base, la semaine redevient incomplète) → 800 XP (N4 → 9) + 2 = 11 gagnés.

| Option | Solde affiché après suppression | Gain répété (supprimer puis refaire) | Import | Migration |
| --- | --- | --- | --- | --- |
| **A. Journal seul (actuel, rendu explicite)** | 11 − 15 = **−4**, affiché « dette de 4 » au lieu de 0 ; les 5 crédits du prochain niveau servent d'abord à la combler | Impossible : tout est recalculé | Remplace tout, cohérent | Aucune ; seul l'affichage change |
| **B. Plus haut atteint (« jamais repris »)** : `gagnés = max(calcul actuel, plus haut enregistré)` | 17 − 15 = **2**, inchangé | Impossible : refaire la séance ramène le calcul à 17, sous le plafond | Le plus haut est exporté ; un import le remplace comme le reste | Au premier lancement, plus haut = calcul actuel (aucun crédit créé, aucun retiré) ; nouvelle clé optionnelle |
| **C. Hybride** : B pour les crédits, XP/niveau recalculés comme aujourd'hui | 2 ; niveau affiché N4 | Impossible | Comme B | Comme B |

Décisions : **option C** (propriétaire) ; le niveau redescend ; les droits anciens rendus par l'usage comptent à 0 (aucun débit). Tests : suppression (XP et niveau baissent, crédits et solde inchangés, conservés après relance), refaire une performance supprimée (aucun gain), correction (solde inchangé), migration sans plus haut enregistré, import d'un plus haut supérieur puis inférieur, valeurs invalides refusées. Limite connue : la cérémonie de passage d'un niveau jamais atteint annonce le barème du niveau (« +N crédits ») ; si le plus haut enregistré dépasse déjà le journal, le solde peut augmenter de moins que N.

## L2.5 — Limites et suites

- Import = remplacement complet (droits compris), comme annoncé dans le dialogue ; l'état remplacé est gardé en copie. **Restauration d'une copie : pas d'écran**, prévue en L2b avec l'export/import par fichier.
- Les copies de récupération vivent dans le même stockage SharedPreferences : elles ne protègent pas contre la perte de ce stockage.
- Démarrage avec un document principal illisible : écran d'erreur, données laissées intactes (comportement inchangé) ; reprise depuis une copie en L2b.
- Achat interrompu par la fermeture du processus : seul ce qui a été accepté par l'API peut subsister ; aucun essai sur appareil.
- Arrêt brutal et durabilité disque : non démontrés.

## L1b.0 — État de clôture (remplace les statuts « en attente CI » plus bas)

| Run | Commit | Contenu | Résultat |
| --- | --- | --- | --- |
| n° 68 | `bdc7aef` | L1b initial (2.5.0+51) | **Échec** étape 7 : `sdkmanager: command not found` (code 127) |
| n° 69 | `e0d94bc` | L1b-R1 (2.5.0+51) : chemin SDK + filtres ABI | **Succès**, 21 étapes, 14:36 → 14:48 UTC |
| n° 70 | `adad2b0` | L1b-R2 (2.5.1+52) : corriger/supprimer une séance | **Échec** étape 9 : formatage (1 ligne de test) |
| n° 71 | `f7f8518` | L1b-R2 formaté, nettoyage de test corrigé | **Succès**, 21 étapes, 15:59 → 16:11 UTC |

**Run n° 71, preuves CI (statut des étapes lu via l’API GitHub) :** ZIP et copie du workflow identiques ; `verify_project.py` ; composants Android 36 / build-tools 36.0.0 / NDK r28c installés ; `pub get --enforce-lockfile` ; formatage sans changement ; `flutter analyze` sans problème ; tests Python et Flutter réussis ; icônes ; **5 vrais refus Gradle release sans secrets valides** ; restauration et contrôle obligatoires de la clé existante ; APK et AAB release compilés avec le même numéro ; `verify_android_artifacts.py` réussi (certificat APK et AAB = référence, manifestes finaux identité/versions/min 21/cible 36/non débogable, permissions APK = AAB, `bundletool validate`, configuration AAB `PAGE_ALIGNMENT_16K`, `zipalign -P 16`, ELF 64 bits alignés 16 Ko avec contrôle RELRO, mêmes bibliothèques natives APK/AAB, ABI exactement armeabi-v7a/arm64-v8a/x86_64) ; artefacts publiés.

| Artefact run n° 71 | Taille de l’archive GitHub | Empreinte de l’archive GitHub (SHA-256) | Expiration |
| --- | --- | --- | --- |
| `kalis-track-apk` | 26 348 376 octets | `4f7d752e7d2e0f1aaa8e21ba8e7ec24e68ad0cc1c4af8f5737ca7465f851fbc4` | 25/10/2026 |
| `kalis-track-aab` | 27 018 366 octets | `eaefa5f753468dcdcb978addcfd3efefc89d1b6a43b3a07f722b00719fc91291` | 25/10/2026 |
| `kalis-track-validation` | 23 502 octets | `1679fc9fd5b648ae06edbe0137731731e8acdc4fe1a9333bdd80f66c630c389f` | 25/10/2026 |

Ces empreintes sont celles des archives téléchargeables, pas de l’APK/AAB qu’elles contiennent : les fichiers `kalis-track.apk.sha256`, `kalis-track.aab.sha256`, `build-number.txt` et `android-artifacts.json` sont dans les archives. Le stockage des journaux et artefacts GitHub n’est pas joignable depuis l’environnement de l’assistant : leur contenu n’a pas été relu ici.

Suite Flutter complète exécutée séparément sur le même code (branche temporaire `claude/ci-tools`, sans secrets) : **202 tests réussis, 1 ignoré** (capture optionnelle), sortie 0 ; analyse `No issues found!`. La branche temporaire n’a pas pu être supprimée depuis l’environnement de l’assistant (refus 403) : suppression à faire par le propriétaire, elle ne contient ni secret ni workflow de build.

**Clos par la CI :** KT-010 (cible 36 vérifiée dans le manifeste final), KT-011 (pipeline APK + AAB, contrôles et refus sans secrets démontrés), KT-019 (alignements 16 Ko vérifiés statiquement sur les binaires finaux), gates de formatage/analyse/tests. KT-012 : tests mobiles réussis en CI.

**Restent ouverts :** essai L1b sur téléphone (mise à jour sans désinstallation, données conservées, nouvelle fonction, texte agrandi) ; exécution sur appareil ou émulateur à pages 16 Ko ; autres ABI, Android minimum, grand écran ; KT-005 (solde de crédits qui peut baisser) ; préparation Google Play hors lot ; suppression de la branche temporaire.

## L1b-R2 — Corriger ou supprimer une séance terminée (demande du propriétaire)

Besoin : une fin de séance validée par erreur rendait les valeurs non modifiables ; l’historique est en lecture seule depuis R2, et l’accueil ouvre l’historique pour une journée faite.

| Élément | Changement |
| --- | --- |
| `lib/store.dart` | `correctionPlan(key)` (journée d’entraînement du programme ou séance perso existante ; null pour archive `@`, repos, séance perso supprimée) ; `reopenSession(key)` (terminée → en cours, saisies et `finishedAt` conservés) ; `deleteLog(key)` / `restoreLog(key, log)` (annulation sans écraser une séance reprise). `markSessionDone(done: true)` réutilise `finishedAt` s’il existe : la date d’origine est conservée après correction. « Repasser en à faire » efface toujours la date. |
| `lib/session_history.dart` | Menu ⋮ quand l’entrée existe et est terminée : « Corriger les saisies » (désactivé si non rouvrable) et « Supprimer de l’historique ». Carte « Validée par erreur ? » sur la page Bilan. Confirmations explicites ; suppression suivie d’un message « Annuler ». Consulter reste sans écriture. |
| `test/history_correction_test.dart` | 4 tests store + 5 tests widget (320 px, texte 130 %) : réouverture, date conservée, revalidation, annulation, suppression/restauration, archive, entrée absente. **9/9 réussis en CI**, avec les 4 tests `history_readonly_test.dart` inchangés. |
| `README.md`, `pubspec.yaml`, `lib/settings_screen.dart` | Section 2.5.1 ; version 2.5.1+52 et `kAppVersion`. |

Effets sur la progression : pendant une correction, l’XP de séance est retiré (les séries validées restent comptées) ; il revient à la revalidation, avec un nouveau bilan. Une suppression retire l’XP et les bonus dérivés ; les WODs débloqués restent acquis (`unlockedWods` inchangé) ; le solde affiché peut baisser si le niveau baisse (comportement préexistant de « Repasser en à faire », KT-005 ouvert). `_lastLevel` ne redescend pas : pas de seconde cérémonie de niveau après correction.

Incidents de mise au point : run n° 70 refusé par le formatage d’une assertion de test (corrigé à l’identique du formateur Dart 3.7.2). Un test widget bloquait : `tester.runAsync(store.flush)` attendait une écriture créée dans la zone de temps simulée ; nettoyage limité au démontage de l’arbre. Aucun code de l’application modifié pour ces deux corrections.

## L1b-R1 — Correctif après le premier run CI L1b

Run n° 68, commit `bdc7aef5`, runner `ubuntu-24.04` image 20260920.314.1. Échec à « Installer les composants Android ciblés » : `sdkmanager: command not found`, code 127. Aucune étape Flutter, Gradle, signature ou artefact atteinte ; secrets non lus.

| Problème | Cause | Correction | Preuve |
| --- | --- | --- | --- |
| **R1-A** — `sdkmanager` introuvable | SDK préinstallé dans `$ANDROID_HOME`, mais `cmdline-tools/latest/bin` hors du PATH du runner | Chemin résolu depuis `ANDROID_HOME`/`ANDROID_SDK_ROOT`, outils contrôlés, dossier ajouté à `GITHUB_PATH`, licences acceptées, installation journalisée (`sdkmanager-install.log`), présence d’`apksigner`, `apksigner.jar`, `zipalign`, plateforme 36 et NDK r28c vérifiée | Étape 7 réussie aux runs n° 69 et 71 |
| **R1-B** — ABI x86 hors liste (anticipé) | `shared_preferences_android` 2.4.13 → `androidx.datastore` 1.1.7 embarque `libdatastore_shared_counter.so` en x86 ; Flutter 3.29.3 ne filtre pas les ABI (filtre par défaut depuis Flutter 3.35) ; le contrôleur n’accepte que 3 ABI | `abiFilters` release `armeabi-v7a`, `arm64-v8a`, `x86_64` dans `android/app/build.gradle.kts` ; contrôleur inchangé | Étape 17 réussie aux runs n° 69 et 71 (ABI, ELF 16 Ko et RELRO de toutes les bibliothèques, datastore compris) |

## L1b.1 — Source réellement utilisée

Archive unique : `streetlift_tracker_v33.zip`, livraison L1-R2, **1 238 962 octets**, SHA-256 recalculé :
`9dfd6221954a1acd673804a498f703ed245f14fd4f8540af9f29e769d584e698`.
Identique à la référence demandée ; racine `streetlift_tracker/`, 278 fichiers, version `2.5.0+51`. CRC vérifiés à l’extraction. Le workflow séparé R2 et sa copie interne sont identiques. Aucun retour vers R1 ou A0, aucune source détruite, aucun dépôt distant modifié.

Documents pris en compte : le suivi embarqué, `LIVRAISON_L1.md` R2, le cahier des charges transmis et le workflow R2 utilisé comme référence. La déclaration du propriétaire relie R2 au dernier build réussi ; le journal complet de ce run réussi et son APK ne sont pas disponibles dans cette passe. Les deux journaux visibles sont les runs antérieurs ayant échoué au contrôle final du certificat.

La copie de travail temporaire a dû être reconstruite après nettoyage de l’environnement. L’archive R2 a de nouveau été matérialisée et son empreinte vérifiée ; les contrôles consignés pour cette livraison ont été relancés sur la copie reconstruite. L’empreinte du ZIP L1b figure dans le rapport séparé `LIVRAISON_L1b.md`, pour éviter une référence circulaire.

## L1b.2 — Résultats L1 déclarés et preuves disponibles

| Résultat | Déclaration du propriétaire, enregistrée sans nouvelle demande | Preuve dans les journaux joints |
| --- | --- | --- |
| Compilation du dernier build | Réussie | Les deux anciens runs prouvent déjà une compilation APK réussie ; le run réussi R2 n’est pas joint |
| Contrôle du certificat et artefact GitHub | Réussis | Les anciens runs échouent au contrôle final et ne publient pas ; ils ne prouvent pas ce succès ultérieur |
| Installation comme mise à jour, sans désinstallation | Oui | Pas de journal appareil ; déclaration du propriétaire |
| Ouverture sur téléphone | Réussie | Déclaration du propriétaire |
| Historique, séances, crédits, WOD acquis et réglages après réouverture | Préservés | Déclaration du propriétaire ; pas de comparaison indépendante des données |

La continuité de mise à jour et la conservation des données **L1 sont confirmées par le propriétaire sur son téléphone**. Cette confirmation ne vaut pas validation de tous les parcours, de toute la sécurité, ni de la publication Google Play. Elle ne vaut pas essai du nouvel APK L1b.

La sauvegarde privée de la clé et des accès, la distribution par APK direct, l’absence de Play App Signing et le caractère resté privé du ZIP/dépôt ont déjà été déclarés par le propriétaire. Les deux secrets désormais fonctionnels sont conservés. Aucun secret ni aucune clé n’ont été remplacés ou générés.

**Restent ouverts pour L1 :** preuve effective du refus d’un build release sans secrets valides (nouvelle CI préparée), vérification indépendante de l’exposition passée si elle devient nécessaire. Le caractère privé est une déclaration, pas un audit de l’historique de partage ou du dépôt. Le nettoyage d’un ZIP ne résout pas une exposition antérieure éventuelle ; toute rotation serait une décision distincte. Aucune exposition confirmée nouvelle n’est déduite de ces travaux.

## L1b.3 — Problèmes ciblés et changements

| Identifiant / gravité / catégorie | Fichiers et preuve | Traitement et état restant |
| --- | --- | --- |
| **KT-010 / P1 / écart confirmé de configuration** | `android/app/build.gradle.kts` R2 cible 35 ; exigence mobile API 36 revérifiée le 25/09/2026 dans [S1] du guide | targetSdk 36, compileSdk 36 conservé. Vérification du manifeste final prévue ; build et comportements Android 16 encore à valider |
| **KT-011 / P1 / contrôles incomplets confirmés** | Workflow R2 : APK seul, pas de gate formatage, ni AAB/manifeste final/16 Ko, ni preuve Gradle négative | Pipeline complété, contrôleurs et tests ajoutés. APK/AAB de même base et numéro prévus, signature R2 conservée. Production et contrôle des vrais artefacts : en attente CI |
| **KT-012 / P2 / faiblesse de test confirmée** | `reward_flow_test.dart` utilisait 390×1600 et `wod_store_test.dart` 390×1800 pour accéder aux contenus | Fenêtres 390×844 et 320×720 ; gestes de défilement, actions atteignables, scénarios de texte 130/200 %. Assertions d’origine conservées, aucun test désactivé pour obtenir du vert |
| **KT-012 / P2 / défaut local confirmé par test agrandi** | `lib/wod_store.dart`, `WodHero` : débordements horizontal et vertical à 320 px / 200 % lors des essais ciblés | Badge flexible et hauteur de la carte adaptée au texte. Apparence à échelle normale préservée ; correction locale, sans refonte. Couverture par tests catalogue/fiches et achats fictifs |
| **KT-019 / P1 / risques de compatibilité à vérifier** | NDK 26.3 dans les logs, plugins demandant 27 ; natifs finaux et minimum Android effectif non inspectés sur un artefact disponible | r28c épinglé pour alignement 16 Ko. Vérifications statiques des moteurs Flutter 64 bits réussies ; natifs finaux/ZIP/AAB et exécution sur système 16 Ko encore ouverts. Écart de matrice Kotlin/AGP documenté |

Le guide `docs/VALIDATION_ANDROID_L1b.md` décrit les versions, sources officielles, justifications et étapes GitHub/téléphone. Les modifications sont séparables : cible Android, NDK, contrôle de pipeline, tests mobiles et correction WodHero ; les autres changements Dart sont du formatage et cinq ajouts d’accolades exigés par l’analyse après formatage.

Aucun changement de barème, formule, calendrier, achat, données ou modèle de sauvegarde. `pubspec.yaml`, `pubspec.lock`, assets, wrapper Gradle, empreinte publique du certificat, `tools/signing.py` et `tools/VerifyApkCertificate.java` restent identiques à R2. L’identité de signature attendue reste inchangée.

## L1b.4 — Contrôles réels de cette livraison

Les résultats locaux sont consignés dans `validation/L1b/`. Ils ne constituent pas une compilation Android.

| Contrôle | Résultat réel local |
| --- | --- |
| Base R2 | Taille, SHA-256, CRC et racine conformes |
| Flutter / Dart | SDK officiel 3.29.3 / 3.7.2 téléchargé ; SHA-256 de l’archive vérifié |
| Dépendances | Archives vérifiées contre les lockfiles ; résolution hors ligne avec `--enforce-lockfile` |
| Formatage | 71 fichiers vérifiés, 0 changement demandé |
| Analyse | `No issues found!`, code de sortie 0 |
| Tests Python | 33 réussis, dont refus réel par Java d’une fixture AAB non signée ; les tests de refus Gradle sont simulés ici |
| Tests Flutter | **193 réussis, 1 ignoré** : capture visuelle déjà optionnelle dans R2 ; aucun nouvel ignore |
| Assets | 40 semaines, 280 jours, 1 954 exercices du programme, 505 exercices de la base |
| Workflow | actionlint 1.7.7 réussi (intégration shellcheck désactivée, pas de preuve d’exécution Actions) |
| Moteurs Flutter release précompilés | ARM64 et x86_64 : LOAD à 65536, règles RELRO acceptées ; rapport statique fourni |
| bundletool | Téléchargement 1.18.2 et SHA-256 vérifiés, commande version exécutée ; aucun AAB Kalis local à valider |
| SDK Android / build APK et AAB | SDK absent ; aucun APK/AAB Kalis L1b compilé localement |
| Refus Gradle sans secrets | Non exécuté localement ; cinq cas réels exigés dans le workflow livré |
| Téléphone / système 16 Ko | Aucun essai L1b réalisé ; déclaration L1 conservée séparément |

La première tentative Flutter après reconstruction a été bloquée par le contrôle automatique de sécurité : détection du runner via métadonnées de machine. Après lecture du code officiel du SDK, le mode CI désactivant cette requête a été utilisé, avec télémétrie supprimée. Aucun changement de code applicatif n’a servi à contourner ce blocage.

L’exclusion des secrets du ZIP est vérifiée par `tools/package_release.py --check` et les tests de régression du packaging. Ce contrôle de motifs/conteneurs et de fichiers interdits réduit les risques ; il n’est pas une preuve universelle d’absence de tout secret arbitraire ou obfusqué. Les protections L1 et la copie du workflow sont conservées.

## L1b.5 — Validations encore nécessaires et arrêt du lot

- Nouveau run GitHub : formatage, analyse, tests, **cinq refus Gradle**, builds APK/AAB, signatures réelles, identité, versionnement, manifestes finaux, ABI, alignements ELF/ZIP et configuration AAB, empreintes finales.
- Comparaison du manifeste final : notamment minimum Android des plugins et attributs de sauvegarde/exported. Ne pas modifier la politique de sauvegarde dans L1b pour faire passer une exigence nouvelle.
- Téléphone : mise à jour L1b sans désinstallation, réouverture et conservation des données/droits ; essais de défilement, texte agrandi, bilan et navigation Android 16.
- Compatibilité : exécution sur un véritable système 16 Ko, appareils Android minimum annoncés, grands écrans et autres ABI non couverts par le téléphone du propriétaire.
- Exposition passée : conserver les confirmations du propriétaire sans les transformer en audit indépendant. Aucun remplacement de clé implicite.
- Google Play : l’AAB ne prouve pas l’acceptation du store, Play App Signing ou la conformité de publication ; ces décisions restent pour le lot dédié.

**L1b est livré pour exécution et validation CI/appareil. Il n’est pas présenté comme entièrement validé. L2 et la refonte visuelle ne sont pas lancés.**

---

# Historique conservé — L1-R2 puis audit initial

Les statuts et demandes de confirmation dans les sections historiques ci-dessous décrivent leur date de rédaction. L’état courant ci-dessus les remplace ; ne pas redemander les informations déjà confirmées ni refaire la configuration des secrets.

# Suivi historique L1-R2

**Passe actuelle : L1-R2 — contrôle direct du certificat APK, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative : 2.5.0+51, inchangée**  
**Statut : compilation Android R1 réussie selon le second journal fourni ; publication bloquée par le lecteur de sortie apksigner. Ce lecteur est supprimé dans R2. Contrôle direct testé sur des APK publics déjà signés, exécution sur l’APK Kalis encore requise. L1 non validé par le propriétaire.**

## R2.1 — Références préservées et second journal CI

La source A0 originale a été revérifiée sans modification :
`streetlift_tracker_v33.zip`, **1 190 723 octets**, SHA-256
`50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f`.

La copie de travail R2 est extraite de la livraison R1 de cette conversation :
**1 234 126 octets**, SHA-256
`a6c0581aa14112f12b56e27ce8d2d202ccf40256732141fc1572609e606ef6cc`,
racine `streetlift_tracker/`, 277 fichiers. Taille, empreinte et CRC vérifiés.
Les archives A0, L1 et R1 et leurs copies source restent intactes. Aucun dépôt
distant modifié. La taille et le SHA-256 du nouveau ZIP sont donnés dans le
rapport séparé `LIVRAISON_L1.md`, afin d’éviter une empreinte autoréférente.

Journal transmis par le propriétaire : dépôt `mikeriin/streetlift-apk`, branche
`main`, commit **`ea22cf08fa312e308267e110d4958dccd30a09be`**, le 25 septembre 2026,
08:56–09:06 UTC (10:56–11:06 à Paris). Les 277 fichiers et 2 441 383 octets extraits
sont cohérents avec R1, mais le journal ne contient pas le SHA-256 de son ZIP.
Les résultats CI ci-dessous sont lus dans ce journal, pas exécutés par l’assistant.

| Contrôle du run R1 | Résultat fourni |
| --- | --- |
| ZIP, identité des workflows, assets | Réussis |
| Dépendances verrouillées | `flutter pub get --enforce-lockfile` réussi |
| Analyse Flutter | `No issues found!` |
| Tests Python | **22 réussis** |
| Tests Flutter | **186 réussis, 1 ignoré** ; `All tests passed!` |
| Restauration de la clé | Réussie ; accès privé et certificat local vérifiés à 08:58:53 UTC |
| Build Android release | **Réussi à 09:06:48 UTC**, APK annoncé 26,3 MB ; versionCode **212489931** |
| Contrôle final | **Échec à 09:06:49 UTC** : « Format apksigner non reconnu : aucune empreinte de certificat APK lisible. Aucun APK publié. » |
| Publication de l’artefact | Non exécutée |
| Nettoyage de la clé éphémère | Exécuté après l’échec |

**KT-001 / bug confirmé, bloquant pour la livraison :** `tools/signing.py`,
fonction `apk_certificates` de R1, ne reconnaît aucune empreinte de la sortie du
runner. Le chemin de code atteint implique un retour nul de la vérification
apksigner et un nombre de signataires reconnu égal à 1. Cela ne suffit pas à
valider le certificat attendu : la sortie brute manque toujours. Ne pas conclure
à un mauvais mot de passe ou à une autre clé. Les deux secrets actuels sont à
conserver. R1 était insuffisant ; ses simulations ne couvraient pas la sortie réelle.

## R2.2 — Correction réalisée, sans changement d’identité

Le lecteur des messages de la CLI apksigner est supprimé. Le nouveau source
`tools/VerifyApkCertificate.java` utilise directement `ApkVerifier` dans le
`lib/apksigner.jar` voisin de l’outil sélectionné par le workflow existant.
Java 17 exécute le source sans déposer de `.class` dans le projet. Aucune nouvelle
bibliothèque n’est livrée ou téléchargée par le workflow ; versions inchangées.

La publication exige : `isVerified()` vrai, exactement un certificat signataire
final, pas de signataires multiples en v1/v2, et même SHA-256 du certificat DER
pour toutes les feuilles v1/v2/v3/v3.1 retournées. Les lignées présentes sont
limitées à un certificat identique : aucune rotation autorisée. La plage Android
par défaut du manifeste est conservée, sans réduire les versions vérifiées.
Les chaînes de certification et le Source Stamp ne sont pas comptés comme des
identités de signature APK.

Python exige le code de sortie réussi ET le protocole fixe du contrôleur ET
l’empreinte attendue. Bibliothèque absente, compilation/exécution Java impossible,
API incompatible, réponse absente/malformée, cryptographie invalide, plusieurs
signataires, rotation ou certificat différent bloquent l’artefact. Les sorties
brutes et exceptions des outils ne sont pas reproduites. Les deux secrets sont
retirés de l’environnement transmis au contrôleur APK. Seuls des statuts fixes
et des empreintes publiques validées peuvent apparaître dans les diagnostics.

Référence publique conservée :
`9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`.
Elle n’est ni une clé privée ni une preuve de la signature de l’APK installé.
La restauration du keystore, les mots de passe requis, l’alias, Gradle et le
workflow ne changent pas. Aucune clé créée, remplacée ou tournée.

## R2.3 — Vérifications locales réellement exécutées

- **26 tests Python réussis** : restauration et packaging conservés, 11 tests du
  nouveau protocole/contrôleur Python. Ils couvrent notamment les codes de retour
  contradictoires, empreinte différente, réponses vides/tronquées/répétées,
  absence de fichiers/outils, délai dépassé et suppression des secrets de
  l’environnement. Ces tests unitaires utilisent des sous-processus simulés.
- **8 cas cryptographiques réels** exécutés avec Java 17 et la bibliothèque
  précompilée publique AOSP ; résultats ci-dessous. Aucune clé téléchargée,
  créée ou utilisée pour signer. Seuls des APK publics déjà signés sont vérifiés.
- **4 cas de bout en bout Python → Java → apksig** : APK valide accepté ; APK
  altéré, plusieurs signataires et rotation refusés.
- Contrôle des assets et de l’identifiant réussi sans secrets : 40 semaines,
  280 jours, 1 954 exercices du programme, 505 exercices de la base.
- Contrôle du ZIP livré : CRC, racine, chemins, limite de taille et filtre de
  packaging ; recherche exacte des octets de la clé A0, de son Base64 et du
  mot de passe historique, sans affichage. Comparaison des fichiers préservés
  et de l’identité des deux copies du workflow.
- Environnement local : terminal/Python/Java 17 et module compilateur disponibles.
  Flutter, Dart et Android SDK complets absents. **Aucune compilation Android
  locale ni test sur téléphone.** L’exécution du source Java n’est pas un build Android.

| Cas réel local | Résultat |
| --- | --- |
| `golden-aligned-v1v2v3-out.apk`, certificat attendu | Accepté |
| Même APK, autre empreinte attendue | Refus certificat différent |
| `golden-aligned-v1v2v3-lineage-out.apk` | Refus rotation |
| `two-signers.apk` | Refus plusieurs signataires |
| `empty-unsigned.apk` | Refus fichier non vérifiable |
| `incorrect-v2-block-size.apk` | Refus cryptographique |
| Copie du premier APK avec une entrée ZIP ajoutée | Refus cryptographique |
| `valid-stamp.apk` | Accepté, Source Stamp non compté comme second signataire |

Bibliothèque de validation locale : AOSP `platform/prebuilts/sdk`,
`tools/linux/lib/apksigner.jar`, 1 074 052 octets, SHA-256
`9469c60e5e40fc5c44a2f2338509cb6600cdf065e9b50f9fa3ca6c5be5bae6a9`.
Ce JAR et les APK de test restent hors du ZIP. Le JAR exact du runner n’a pas été
reçu ; l’exécution CI avec son SDK reste nécessaire. Deux téléchargements
supplémentaires de fixtures v3.1/chaîne ont expiré : ces cas ne sont pas revendiqués
comme essais réels locaux. Les branches correspondantes sont compilées et relues.

Sources primaires consultées :
- https://android.googlesource.com/platform/tools/apksig/+/master/src/main/java/com/android/apksig/ApkVerifier.java
- https://android.googlesource.com/platform/tools/apksig/+/master/src/test/resources/com/android/apksig/
- https://android.googlesource.com/platform/prebuilts/sdk/+/refs/heads/main/tools/linux/lib/apksigner.jar

## R2.4 — Fichiers modifiés et actions du propriétaire

Par rapport à R1, quatre fichiers modifiés :

1. `tools/signing.py` — remplacement du lecteur CLI par le contrôle Java direct.
2. `tools/tests/test_release_security.py` — régressions du nouveau protocole.
3. `docs/SIGNATURE_ET_ZIP.md` — reprise R2 depuis le téléphone.
4. `SUIVI_PROJET.md` — preuve du second run, correction, résultats et limites.

Un fichier ajouté : `tools/VerifyApkCertificate.java`.
Les **273 autres fichiers sont identiques à R1**, notamment code métier,
interfaces, assets, tests Dart, application ID `fr.tchoupi.streetlift_tracker`,
versions, dépendances, Gradle, wrapper et certificat de référence. Aucun retrait.
La copie du workflow incluse est identique au `build-apk.yml` livré séparément.

Actions sur téléphone : conserver secrets et workflow ; remplacer seulement le
ZIP à la racine de `main` avec son nom exact ; créer le commit ; suivre son
nouveau run, ou **Actions → Build APK → Run workflow → main**. **Re-run jobs**
sur l’ancien run reprendrait l’ancien commit. Le guide inclus donne le détail.
Une fois l’artefact publié, sauvegarder les données puis installer comme mise à
jour sans désinstaller ; vérifier les données conservées sur le téléphone.

## R2.5 — Validations encore ouvertes

- Exécution du nouveau contrôle R2 dans GitHub Actions, puis publication de l’APK.
- Comparaison du certificat au dernier APK réellement installé : APK non accessible.
- Refus réel d’une release Gradle sans secrets : attendu par le code, pas testé
  par ces runs réussissant la compilation avec des secrets valides.
- Mise à jour sur téléphone sans désinstallation et conservation des données.
- Validation explicite du propriétaire. **L1 n’est pas déclaré validé.**

Les avertissements NDK, Java/Node et surveillance Gradle n’ont pas empêché les
builds reçus ; ils restent consignés pour un lot ultérieur, sans lancer L1b.
Le plafond de 25 000 000 octets concerne le ZIP source, pas l’APK de 26,3 MB.
La sauvegarde privée et la confidentialité passée restent déclarées par le
propriétaire. Aucun audit indépendant d’exposition passée n’a été réalisé ; si
une exposition est découverte ou devient incertaine, elle reste un sujet ouvert.
Nettoyer ce ZIP ne répare pas une exposition passée. Toute rotation éventuelle
reste une décision distincte. Aucun accès ni changement du dépôt distant.

---

# Historique R1 — État avant le second journal CI

# Kalis Track — Suivi du projet

**Passe actuelle : L1-R1 — correctif du contrôle final du certificat, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative : 2.5.0+51, inchangée**  
**Statut : compilation L1 réussie dans le journal CI fourni, livraison bloquée au contrôle d’identité du certificat. Lecteur et diagnostics corrigés dans R1 ; nouvelle exécution CI requise. L1 non validé par le propriétaire.**

## R1.1 — Base et preuve CI reçue

Copie de travail extraite exclusivement de la livraison L1 de cette conversation :
`streetlift_tracker_v33.zip`, **1 228 032 octets**, SHA-256
`454dd1eda13fe730bbe1baad6ab706fab677f589cbaf5591f65df1ae6ac9747e`,
racine `streetlift_tracker/`, 277 fichiers ; empreinte et CRC revérifiés.
Cette archive et la source A0 restent intactes. Le journal ne fournit pas le
SHA-256 du ZIP utilisé dans la CI : ses 277 fichiers et 2 421 728 octets extraits
sont cohérents avec L1, sans constituer une preuve indépendante de l’empreinte.

Journal transmis par le propriétaire, dépôt `mikeriin/streetlift-apk`, branche
`main`, commit `3983b4c3ca0c2b94583fff9912ee348b933d5ae2`, le 25 septembre 2026
entre 08:26 et 08:35 UTC (10:26–10:35 à Paris). Aucun accès au dépôt distant ni
relancement par l’assistant. Les résultats ci-dessous proviennent de ce journal,
ils ne sont pas présentés comme des exécutions locales de l’assistant.

| Étape dans le journal L1 | Résultat observé |
| --- | --- |
| ZIP / identité des workflows / assets | Réussis ; 277 fichiers, 1 954 exercices du programme, 505 exercices de la base |
| Dépendances verrouillées | `flutter pub get --enforce-lockfile` réussi |
| Analyse Flutter | `No issues found!` |
| Tests Python | **16 réussis** |
| Tests Flutter | **186 réussis, 1 ignoré** ; capture visuelle ignorée ; `All tests passed!` |
| Secrets de signature | Deux variables présentes et masquées ; restauration de la clé, accès privé et égalité au certificat local réussis à 08:29:02 UTC |
| Build release | **Réussi à 08:35:23 UTC** ; APK annoncé 26,3 MB ; `versionCode` **212488142** |
| Contrôle final du certificat | **Échec à 08:35:24 UTC**, message générique « Le certificat de l’APK diffère de la référence locale ou est ambigu. » |
| Artefact téléchargeable | Étape de publication non exécutée ; aucun APK fourni à l’assistant |
| Nettoyage de la copie de clé du runner | Commande exécutée après l’échec |

Le code L1 émet ce message après un retour nul d’`apksigner verify` : on peut donc
inférer que sa vérification cryptographique a réussi, mais la comparaison avec
l’identité locale n’est pas validée. Le message réunissait trois causes : zéro
empreinte reconnue, plusieurs empreintes reconnues, ou empreinte différente.
La sortie d’`apksigner` étant capturée et absente du journal, **la cause exacte de
cet échec ne peut pas être déterminée sur ces seuls logs**. Ne pas conclure à une
mauvaise clé ni demander de remplacer les secrets sur cette base.

Les avertissements NDK (26.3.11579264 configuré, 27.0.12077973 demandé par des
plugins), actions Java/Node dépréciées et surveillance de chemin Gradle n’ont pas
empêché cette compilation. Ils sont consignés pour L1b/KT-019 ou le futur examen
des outils ; aucune version n’est changée dans R1. La limite de 25 000 000 octets
concerne le ZIP source, pas la taille de l’APK.

## R1.2 — Défauts confirmés et correction limitée à KT-001

**Bug confirmé dans le contrôleur L1 :** le lecteur acceptait exclusivement une
ligne commençant exactement par `Signer #N`, tandis que l’outil AOSP peut aussi
émettre des identifiants par plage de SDK. Les erreurs de lecture et les vraies
différences de certificat recevaient le même message. Les tests initiaux ne
couvraient qu’une sortie minimale numérotée.

Reproduction locale sur sorties simulées : une plage de SDK au format AOSP et
une ligne indentée avec CRLF sont refusées par L1 malgré une empreinte attendue,
puis acceptées par R1. Cela prouve la fragilité du contrôleur initial, **pas que
l’une de ces deux sorties était effectivement celle du runner**.

R1 demande `apksigner verify --verbose --print-certs`, lit le nombre de signataires
et prend en charge les deux formes connues. La publication reste bloquée si la
vérification cryptographique échoue, si le format est inconnu ou incomplet, si le
nombre de signataires n’est pas exactement un, si les lignes sont répétées ou
incohérentes, ou si une empreinte de certificat diffère du repère local. Toutes
les plages de SDK doivent conserver la même empreinte. Aucune rotation ou
signature alternative n’est acceptée. Les empreintes de **clé publique** et de
**Source Stamp** ne remplacent pas celles du certificat de signature APK.

Les diagnostics distinguent désormais erreur cryptographique, format non reconnu,
ambiguïté et certificat différent. En cas de différence, ils donnent seulement
les SHA-256 publics attendu et observés, sans sortie brute, DN ou secrets.
Un succès affiche également l’empreinte publique contrôlée. La référence publique,
la restauration de la clé, les mots de passe requis et Gradle ne sont pas modifiés.

Source primaire du format :
https://android.googlesource.com/platform/tools/apksig/+/master/src/apksigner/java/com/android/apksigner/ApkSignerTool.java
(fonctions de vérification et `printCertificate`, consultées le 25 septembre 2026).

## R1.3 — Vérifications et fichiers modifiés

- **22 tests Python réussis localement**, dont 6 nouveaux tests couvrant le
  certificat APK. Cas vérifiés : sorties standard et plages de SDK, CRLF,
  indentation, casse hexadécimale, digest de clé publique/Source Stamp distinct,
  vrai désaccord d’empreinte simulé, plusieurs signataires, sortie vide,
  tronquée/inconnue, répétitions et échec cryptographique. Aucun APK réel n’est
  signé ou vérifié par ces fixtures ; aucune clé n’est générée.
- Contrôle des assets et de l’identifiant réussi sans secrets.
- Nouveau ZIP : contrôles de packaging, CRC, chemins et exclusion des secrets
  exécutés. Taille et SHA-256 exacts dans le fichier séparé `LIVRAISON_L1.md`.
- Comparaison avec L1 : seules les quatre entrées ci-dessous sont modifiées ;
  aucun fichier ajouté ou retiré. Tous les autres fichiers sont identiques,
  notamment `lib/`, `test/`, assets, Gradle, dépendances, wrapper, référence
  publique, outil HTML et workflow. La copie séparée du workflow reste identique.
- Flutter, Dart et Android SDK restent absents localement : aucune nouvelle
  compilation Android ni vérification de l’APK de ce run effectuée ici. Les
  succès Flutter/Android du journal L1 ne sont pas attribués rétroactivement au
  nouveau contrôleur R1.

Fichiers modifiés par rapport au ZIP L1 précédent :

1. `tools/signing.py` — lecture des certificats et diagnostics.
2. `tools/tests/test_release_security.py` — régressions du lecteur.
3. `docs/SIGNATURE_ET_ZIP.md` — reprise depuis le téléphone après ce run.
4. `SUIVI_PROJET.md` — résultats CI reçus, correction et limites.

Le périmètre cumulé par rapport à A0 est conservé dans l’historique L1 ci-dessous.
Aucune modification métier ou visuelle, aucun travail L1b ni dépôt distant modifié.
Les déclarations antérieures de sauvegarde privée et de confidentialité restent
des déclarations du propriétaire ; ce run n’audite pas l’exposition passée.

## R1.4 — Reprise depuis le téléphone et critères encore ouverts

1. Garder les deux secrets GitHub actuels : le journal montre qu’ils permettent
   déjà de restaurer et d’utiliser la clé attendue.
2. Remplacer seulement `streetlift_tracker_v33.zip` à la racine de la branche
   `main` par le ZIP R1, via **Code → Add file → Upload files**, puis commit.
   Le workflow n’a pas changé ; son fichier séparé est fourni pour référence.
3. Suivre le **nouveau run** déclenché par ce commit. Si nécessaire, utiliser
   **Actions → Build APK → Run workflow → main**. Ne pas utiliser **Re-run jobs**
   sur l’ancien run pour tester R1 : cette action réutilise l’ancien commit.
4. Attendre le contrôle final et la publication de l’artefact. Si l’étape échoue
   encore, transmettre son nouveau message : il distinguera un problème de
   lecture d’une réelle différence d’empreinte. Les SHA-256 affichés sont publics ;
   ne transmettre aucune clé ni valeur de secret.
5. Après succès complet, conserver une sauvegarde des données et le dernier APK
   fonctionnel, puis installer comme mise à jour sans désinstaller. Vérifier
   historique, séances, crédits, achats et réglages sur le téléphone.

Référence GitHub sur les relances :
https://docs.github.com/fr/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs

**Restent ouverts :** succès du contrôle final R1 dans la CI ; comportement Gradle
réel sans secrets (le run reçu utilise des secrets valides) ; comparaison avec le
dernier APK effectivement installé ; conservation des données lors de la mise à
jour ; validation explicite du propriétaire. Aucun « testé sur appareil », aucune
continuité de mise à jour et aucune validation propriétaire ne sont revendiqués.
L1b n’est pas commencé.

---

# Historique L1 — État avant réception du journal CI

Les mentions de CI non exécutée, secrets encore absents et 16 tests locaux dans
les sections L1 suivantes décrivent la première livraison. L’état R1 ci-dessus
prévaut ; l’historique A0 reste conservé à sa suite.

**Passe actuelle : L1 — Signature et ZIP, KT-001 uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Version applicative conservée : 2.5.0+51**  
**Statut : KT-001 corrigé dans la copie livrée, contrôles Python et Java locaux réussis ; validation Android/CI et continuité sur téléphone encore à effectuer. L1 non validé par le propriétaire.**

## L1.1 — Référence, périmètre et décisions

Source exclusive revérifiée avant les modifications : `streetlift_tracker_v33.zip`,
**1 190 723 octets**, SHA-256
`50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f`,
racine `streetlift_tracker/`, CRC correct, version `2.5.0+51`.
Le workflow source audité était identique à sa copie interne. Le travail a été
réalisé dans une nouvelle copie ; l’archive et l’extraction source sont intactes.

Seul KT-001 a été traité. Aucun audit global repris, aucun travail L1b, métier,
sauvegarde applicative ou visuel. `lib/`, `test/`, tous les assets, `pubspec.yaml`,
`pubspec.lock`, les versions d’outils et le wrapper Gradle sont identiques à la
source. Les formules et fonctionnalités ne sont pas modifiées. L’identifiant
reste `fr.tchoupi.streetlift_tracker` ; compileSdk 36, targetSdk 35 et minSdk 21
restent inchangés. Flutter 3.29.3, Java 17, Gradle 8.13, AGP 8.12.1 et Kotlin 2.2.10
sont conservés.

| Point | État L1, sans dépasser les preuves disponibles |
| --- | --- |
| Copie privée de la clé et moyens d’accès | **Oui**, confirmé par le propriétaire ; sauvegarde externe non inspectée |
| Distribution | **APK installé directement**, déclaration du propriétaire |
| Play App Signing | **Non activé**, déclaration du propriétaire |
| Confidentialité passée du ZIP/dépôt | **Restés privés**, déclaration du propriétaire ; historique distant non inspecté |
| Secrets GitHub | **Absents au début de L1**, déclaration ; à créer par le propriétaire |
| APK de référence | Annoncé joint, mais aucun fichier APK accessible pendant cette passe |
| Matériel du propriétaire | **Téléphone uniquement** : procédure navigateur GitHub et préparation locale hors ligne fournies |
| Clé examinée localement | Clé privée existante utilisable sous l’alias `kalis`, certificat conforme au repère local |
| Validation installée | Non effectuée : le certificat local ne prouve pas celui de l’application du téléphone |

Aucune clé n’a été générée, remplacée par une nouvelle identité ou tournée.
Aucune source n’a été détruite, aucun dépôt distant ni secret GitHub n’a été
modifié par l’assistant. Les copies temporaires créées pour les essais locaux
ont été supprimées après contrôle ; la source et la sauvegarde du propriétaire
ne sont pas concernées. Si une exposition passée est découverte ou devient
incertaine, le sujet reste ouvert : le nettoyage du ZIP ne résout pas une
exposition ancienne. Toute rotation exige une décision séparée.

## L1.2 — KT-001 : correction et preuves

**Identifiant stable : KT-001 ; gravité initiale P0 ; bug de sécurité confirmé dans la source.**

La clé privée et les trois copies connues du mot de passe de secours sont retirées
du nouveau paquet. Les deux variables `KALIS_KEYSTORE_BASE64` et
`KALIS_KEYSTORE_PASSWORD` sont obligatoires pour restaurer et utiliser la clé.
Aucun ancien nom de variable ne sert de repli. La restauration crée les dossiers,
utilise un fichier temporaire privé, vérifie le certificat puis l’accès à la clé
privée et refuse d’écraser une copie locale différente. Les diagnostics ne
reproduisent ni les secrets ni la sortie d’erreur de keytool.

Le certificat public de référence est inchangé :
`9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`.
Cette empreinte n’est ni la clé privée ni une preuve du certificat de l’APK installé.

Gradle garde une configuration release dédiée, sans secours debug. Les tâches
qui produisent ou signent une release vérifient les deux secrets, le fichier
restauré, son mot de passe, la clé privée et le certificat. Les contrôles sans
production release ne déclenchent pas cette exigence. La CI exécute les contrôles
sans secrets avant la restauration ; elle compare le certificat de l’APK produit
au repère local et ne publie que l’APK et son empreinte. Cette configuration CI et
Gradle est livrée mais n’a pas été exécutée ici.

Le packaging filtre les secrets/fichiers locaux/binaires/caches, détecte les
copies reconnues de clés ou mots de passe dans les contenus, puis rescane le ZIP.
Les contrôles de chemins, doublons, liens, CRC et taille sont inclus. Un refus
conserve l’archive précédente. La protection ciblée n’est pas une garantie de
reconnaissance de tout secret arbitraire ou obfusqué.

## L1.3 — Tests exécutés et limites

| Domaine | Résultat réel |
| --- | --- |
| Tests Python | **16 tests réussis** : 4 existants et 12 nouveaux, aucune clé réelle dans les fixtures |
| Contrôles sans secrets | `verify_project.py` : code 0 ; 40 semaines, 280 jours, 1 954 exercices du programme, 505 exercices de la base ; XML et identifiant contrôlés |
| Absence de secrets | `signing.py restore` et `verify_project.py --signing` : **code 1** avec nom du secret obligatoire absent ; aucune valeur affichée |
| Restauration réelle | Clé source existante restaurée dans un dossier privé jetable ; `keytool` a exporté le certificat en mémoire et signé une requête éphémère en mémoire, démontrant l’accès à la clé existante ; égalité du certificat vérifiée |
| Refus réels avec Java | Mot de passe invalide, conteneur invalide et référence de certificat différente refusés ; copie locale existante conservée et temporaires nettoyés |
| Régressions automatisées | Secrets manquants, Base64 invalide, répertoires/permissions, copie différente, liens, erreur externe non divulguée, certificat sans clé privée simulé, certificat APK simulé, exclusions ZIP, contenus sensibles, chemins dangereux et conservation de l’ancienne archive |
| Workflow | YAML lu et structure contrôlée ; secrets limités aux deux étapes concernées ; égalité octet par octet de la copie livrée séparément et de la copie interne |
| Outil pour téléphone | JavaScript testé sous Node avec DOM simulé : conversion, copie Clipboard API/repli, effacement, refus de fichiers invalides, absence d’affichage ; CSP sans réseau inspectée. Aucun navigateur réel disponible : lancement Chromium impossible faute d’exécutable. Aucun essai sur téléphone |
| Exclusion des secrets dans le ZIP final | Scan par le packager et recherche exacte des octets de la clé source, de son Base64 et du mot de passe historique : aucune occurrence ; clé privée exclue, référence publique et wrapper présents |
| Conservation du projet | Comparaison fichier par fichier avec le ZIP source : seules les entrées listées ci-dessous diffèrent ; source originale revérifiée intacte |
| Flutter / Dart / Android | SDK et outils absents : **aucune analyse Flutter, aucun test Dart, aucune compilation APK/AAB, aucune installation** exécutés ici |
| CI et APK installé | Aucun accès distant ou lancement Actions ; APK de référence indisponible, comparaison non effectuée |

**Le succès Python/Java ne constitue pas une compilation Android.** Le refus d’une
release sans secrets est établi pour l’outil Python et prévu dans Gradle ; le
comportement Gradle réel reste à exécuter avec la chaîne Android dans la CI.

## L1.4 — Fichiers livrés et changements exacts

Fichiers modifiés par rapport au ZIP de référence :

- `.gitignore` — exclusions des secrets et artefacts.
- `.github/workflows/build-apk.yml` — contrôles sans secrets, restauration obligatoire, secret limité aux étapes nécessaires, comparaison du certificat APK, nettoyage de la copie du runner.
- `android/app/build.gradle.kts` — mot de passe uniquement via secret, garde de signature release.
- `tools/verify_project.py` — contrôles non signés conservés, signature confiée au vérificateur explicite.
- `tools/package_release.py` — exclusions, inspection des contenus, vérification finale du ZIP et mode `--check`.
- `README.md` — consignes actuelles de signature et renvoi vers la procédure téléphone.

Fichiers ajoutés :

- `SUIVI_PROJET.md` — ce suivi, avec l’audit initial conservé ci-dessous comme historique.
- `docs/SIGNATURE_ET_ZIP.md` — procédure complète, actions GitHub dans l’ordre, limites de validation.
- `tools/signing.py` — restauration et vérifications de clé/certificat/APK.
- `tools/release_security.py` — contrôles de livraison réutilisables.
- `tools/tests/test_release_security.py` — 12 régressions KT-001.
- `tools/preparer_signature.html` — conversion locale hors ligne depuis le téléphone, sans envoi réseau ni mot de passe demandé.

Fichier retiré **uniquement de la copie distribuable** :
`signing/kalis_track.p12`. Il reste dans la source privée intacte ; le propriétaire
conserve sa sauvegarde indépendante. Les **265 autres fichiers source** sont
inchangés, y compris le certificat public et le wrapper Gradle.

Livrables séparés : ZIP complet racine `streetlift_tracker/`, workflow, ce suivi,
outil HTML et guide téléphone. `LIVRAISON_L1.md` donne la taille et le SHA-256 du
ZIP final ainsi que les liens/fichiers à utiliser. Le hash du ZIP n’est pas inscrit
dans le suivi interne, car inclure le hash d’une archive dans elle-même le
modifierait. Les copies séparées du suivi, workflow, guide et HTML sont identiques
aux fichiers correspondants du ZIP. La version applicative n’est pas augmentée.

## L1.5 — À effectuer par le propriétaire

Suivre `docs/SIGNATURE_ET_ZIP.md` dans l’ordre depuis le téléphone. Créer les deux
secrets, remplacer le ZIP et le workflow, puis lancer la CI. Vérifier l’échec
explicite sans secrets dans une exécution contrôlée si nécessaire avant d’activer
la livraison ; ne pas effacer la seule sauvegarde pour faire ce test. Obtenir une
compilation release réussie avec la clé existante, le contrôle du certificat et
les résultats des tests Flutter. Comparer le certificat du dernier APK réellement
utilisé dès qu’il est disponible, puis effectuer la mise à jour sans désinstaller
et contrôler la conservation des données.

**KT-001 : corrigé et partiellement testé automatiquement ; validation CI/Android
et propriétaire en attente. L1 reste non validé. L1b et tous les autres lots
restent non commencés.** Les tickets KT-002 à KT-023 conservent leurs constats et
priorités de l’audit A0 ; ils ne sont pas requalifiés ni corrigés dans cette passe.

---

# Historique A0 — Audit initial conservé

**Toutes les sections ci-dessous décrivent l’état du ZIP source avant L1.**
Leurs mentions « aucun correctif », « tous ouverts », numéros de ligne, anciens
chemins et questions de signature sont historiques. Pour KT-001 et les
confirmations du propriétaire, l’état L1 ci-dessus prévaut.

**Passe : A0 — audit initial et préparation uniquement**  
**Date : 25 septembre 2026, Europe/Paris**  
**Référence applicative : 2.5.0+51**  
**Statut : audit initial livré ; aucun correctif appliqué ; publication non validée.**

Ce document suit exclusivement le ZIP et le workflow joints à cette passe. Le grand prompt constitue le cahier des charges ; la demande du 25 septembre limite cette passe à l'audit et prévaut sur ses instructions de modification immédiate. Aucune ancienne archive n'a été utilisée. Les anciens rapports contenus dans ce ZIP sont des documents historiques, pas des résultats exécutés pendant cet audit.

**Priorités :** sécuriser la signature sans rompre les mises à jour ; fiabiliser la sauvegarde et les achats ; corriger l'essai WOD à minuit et sa stabilité ; préparer le départ personnel du programme. Le ciblage Android et les droits des contenus restent des sujets de publication. La finition visuelle vient après ces protections. Le registre distingue les défauts établis par le code des scénarios encore à reproduire.

## 1. Référence et capacité de travail

| Élément | Vérification réelle |
| --- | --- |
| Archive reçue | `streetlift_tracker_v33.zip` |
| Taille exacte | **1 190 723 octets** |
| SHA-256 | `50d46d24a00cd751c42c6fdd477af26ba03a7bee26c78bc195637d5d8a6d4f8f` |
| Racine unique | `streetlift_tracker/` |
| Contenu | **272 fichiers**, 2 320 919 octets décompressés ; aucune entrée de répertoire explicite |
| Intégrité | Ouverture et `ZipFile.testzip()` réussis : aucune erreur CRC |
| Extraction | Réussie ; vérification préalable des chemins absolus, traversées `..` et liens symboliques : aucun détecté |
| Lecture et écriture | `pubspec.yaml` lu, copié hors du projet, puis modifié dans cette copie jetable uniquement |
| Création de ZIP | Copie jetable réarchivée puis relue : contenu identique au fichier modifié |
| Réarchivage complet | ZIP de contrôle de **272 fichiers**, **1 193 390 octets**, CRC valide et SHA-256 de chaque fichier identique à la source |
| Empreinte du ZIP de contrôle | `7d610cf246bb156539996a54fde14e778604db68ba72fabb040438f5cba98bf1` ; archive technique temporaire, pas une nouvelle version applicative |
| Conservation de la source | Comparaison de tous les fichiers extraits avec leur empreinte dans le ZIP reçu : **0 fichier modifié** |

Le test d'écriture ne touche aucun fichier de la source auditée. La différence d'empreinte entre les deux ZIP ne signifie pas une différence de code : l'ordre et les métadonnées de l'archive reconstruite diffèrent. L'archive source reste la référence de la prochaine passe, sauf fourniture explicite d'un autre ZIP.

| Autre référence fournie | Taille | SHA-256 |
| --- | --- | --- |
| `build-apk.yml.txt` | 3 684 octets | `fa907edc70c23014beed5a28a4416163d80813d63d81ad10edde20c501d6cf80` |
| `prompt_finalisation_kalis_track.txt` | 23 703 octets | `a67515f0167e10c8e44497bfde536ade3bbec49a2db50466ebb726869437cd42` |

La copie `streetlift_tracker/.github/workflows/build-apk.yml` est **identique octet par octet** au workflow joint. Aucune divergence actuelle entre ces deux exemplaires.

### Outils disponibles

| Outil ou capacité | État constaté | Conséquence |
| --- | --- | --- |
| Terminal Bash, `rg`, Git, ZIP/unzip | Disponibles | Inspection, empreintes, extraction et livraison ZIP possibles |
| Python | **3.12.14** | Contrôles et tests Python exécutables |
| Java et `keytool` | **OpenJDK 17.0.20** | Inspection du certificat et du type d'entrée du keystore possible |
| Flutter / Dart | Introuvables dans le PATH et les emplacements usuels inspectés ; `FLUTTER_ROOT` non défini | Analyse, formatage, résolution des dépendances, tests et rendu Flutter non exécutables ici |
| Android SDK / `adb` / `sdkmanager` / `avdmanager` / `apksigner` | Non disponibles ; `ANDROID_HOME` et `ANDROID_SDK_ROOT` non définis | Compilation, signature d'artefacts et installation Android non exécutées |
| Gradle système | Absent | Le wrapper du projet est présent, mais il ne remplace pas les SDK manquants |
| Wrapper Gradle | `android/gradlew`, JAR et propriétés présents | Conservation obligatoire dans les futurs ZIP |
| Émulateur / téléphone | Aucun moyen de test Android disponible dans cet environnement | Aucun parcours vérifié sur appareil |
| Accès à la CI / Play Console | Non utilisé | Aucun workflow distant déclenché ; statut de publication et signatures installées inconnus |

Aucun SDK n'a été installé pendant cette passe. Aucun test Flutter ou build Android n'a été lancé pour être ensuite présenté comme réussi. La présence d'une clé dans l'archive permet l'inspection de signature locale ; elle ne résout pas l'absence des SDK.

## 2. Structure et périmètre réellement inspecté

Le projet comprend **47 fichiers Dart dans `lib/`, totalisant 22 779 lignes**, 23 fichiers Dart sous `test/` dont le support de notifications, 8 fichiers d'outillage Python, 27 assets, 47 fichiers Android, 64 éléments sous `validation/`, ainsi que les documents historiques. Aucun dossier iOS, dossier `integration_test/`, APK, AAB ou cache `build/`, `.dart_tool/`, `.gradle/` n'est présent dans le ZIP.

### Niveau de lecture

« Lecture ciblée » signifie que les fonctions et passages utiles ont été examinés, **pas** que toutes les lignes du fichier ont été auditées. Une recherche de symboles n'est pas une validation du comportement.

| Zone | Lecture effectuée | Reste à examiner |
| --- | --- | --- |
| Références | Grand prompt ; workflow entier ; `pubspec.yaml` ; versions et SDK de `pubspec.lock` ; sections de `README.md` ; `REFONTE_UI.md`, derniers audits 2.5.0 et 2.4.1 ; rapports Python/projet 2.5.0 | Archives documentaires plus anciennes, licences détaillées des dépendances ; pas de reprise automatique de leurs conclusions |
| Android et livraison | Gradle app/projet/settings, wrapper, manifeste principal ; `MainActivity.kt` et `device.dart` ciblés ; `tools/verify_project.py`, `package_release.py`, tests Python | Manifeste fusionné release, bytecode, bibliothèques natives, shrinker, variantes de build et compatibilité effective |
| Données | `store.dart` : initialisation, migration des accès, crédits, sélections WOD, résultats, sérialisation, import, écriture différée, flush, fin et archivage de séance ; `models.dart` : calendrier | Parser d'exercices, toutes les branches d'import historiques, toutes les formules et estimations ; stress de stockage réel |
| Démarrage et navigation | `main.dart` et démarrage ; routes programme/rappel ; structure des quatre onglets et des quatre sous-onglets STATS | Rendu réel, boutons retour, empilement de routes et interruptions |
| Programme et historique | `home_screen.dart`, `session_screen.dart`, `session_history.dart` : entrée, préremplissage, validation, sauvegarde, bilan et copie de l'historique ; pilotage ciblé | Chaque mode de séance et chaque saisie ; toutes les corrections historiques ; fin du programme sur appareil |
| Progression | Calculs ciblés de `progression.dart`, `game.dart` ; consommation du bilan dans `rewards.dart` ; pastille `levelup.dart` | Tous les badges, boss, saisons et classements ; dédoublonnage sous interruptions ; rendu des célébrations |
| WOD | `store.dart`, `wod_screen.dart`, `wod_preview.dart`, modèles, sélection des sources et cas Tabata du générateur ; routes Arsenal/catalogue et tests WOD | Catalogue intégral, toutes les variantes de score, listes/filtres, géométrie et peintres de `wod_store.dart` |
| Réglages | Options, sauvegarde par presse-papiers, dialogue d'import, À propos ; notifications ciblées | Effet réel de chaque option, interactions pendant une séance ouverte |
| Notifications et chronos | `notifications.dart` : planification, permissions, repli approximatif, file de reprogrammation ; `timers.dart` : horloges, pause, rattrapage ; `alerts.dart` | Exécution native, doze, redémarrage, réveil, limites constructeur, destruction du processus |
| UI et STATS | Palette, conteneurs partagés, début du dock, navigation STATS ; recherche des routes des vues Aperçu/Parcours/Performances/Historique | Audit intégral de `stats_*`, `stats_data.dart`, `records_screen.dart`, `training_estimate.dart`, `estimate_view.dart`, `muscle_body.dart`, `motion.dart`, éditeur et recherche ; aucun rendu validé |
| Tests | Tests Python lus et exécutés ; lecture ciblée de `store_test.dart`, `wod_store_test.dart`, `reward_flow_test.dart`, inventaire des scénarios chronos, notifications et historique | Exécution de tous les tests Dart ; examen détaillé du reste ; tests d'intégration à prévoir |

Les assets compressés ont été ouverts, leurs données structurées vérifiées et leurs empreintes calculées. Le contenu sportif complet, les droits et l'apparence de chaque image n'ont pas été validés.

### Cartographie des parcours

| Entrée | Parcours observé dans le code | Données principales |
| --- | --- | --- |
| Démarrage | Chargement assets + préférences → transition → Programme ; écran de récupération si échec | État courant ou anciennes préférences |
| Programme | Semaine/jour → séance ou historique si déjà fait → séries/repos → bilan → récompenses | `logs`, clés `S<semaine>-J<jour>`, dates réelles des séries et de fin |
| Notification | Payload semaine/jour → même fonction `openProgramDay` que l'accueil | Planning calculé sur les dates du programme ; permissions Android |
| Arsenal, séances personnelles | Créer/éditer/dupliquer → exécuter → archiver l'occurrence précédente lors d'une répétition | `custom`, `userExercises`, journaux `S0-J<id>` puis suffixe d'archive |
| Arsenal, boutique | Catalogue/recherche/filtres → fiche → achat en crédits ou essai → chrono → score et résultats | Catalogue embarqué/généré, `unlocked`, `wishlist`, résultats WOD |
| STATS | Aperçu, Parcours, Performances, Historique ; références depuis Performances | XP, niveaux, crédits et défis dérivés ; valeurs de pilotage ; logs et scores |
| Réglages | Thèmes, saisie, chronos, jeu, écran, unités, notifications, export/import, À propos | `settings` ; export compressé ou JSON ; remplacement à l'import |

Il s'agit d'une application locale sans compte obligatoire dans le parcours inspecté. Cela ne suffit pas à conclure à une absence de transmission : sauvegarde système et dépendances restent à vérifier.

### État technique et invariants vérifiés

- `pubspec.yaml` déclare **2.5.0+51**, Dart `>=3.7.0 <4.0.0`, Flutter `>=3.29.3` ; workflow fixé à Flutter **3.29.3** et Java **17**.
- Android : `applicationId` et namespace **`fr.tchoupi.streetlift_tracker`** ; `compileSdk = 36`, `targetSdk = 35`, `minSdk = 21` ; AGP **8.12.1**, Kotlin **2.2.10**, wrapper Gradle **8.13** ; NDK délégué à Flutter. C'est la configuration lue, pas une combinaison compilée pendant cet audit.
- Dépendances verrouillées relevées : `shared_preferences 2.5.3`, backend Android `2.4.13`, `audioplayers 6.6.0`, `flutter_local_notifications 18.0.1`, `wakelock_plus 1.4.0`, `timezone 0.10.1`.
- Programme réellement vérifié : **40 semaines, 280 jours, 1 954 entrées d'exercice**, identifiants uniques ; base **505 exercices**. Ancrage JSON : **2026-07-13**.
- Catalogue : construction prévue jusqu'à 500 WOD dans la première série, puis 500 dans la seconde (`store.dart:1436–1442`, `wod_generator.dart:126,339,432–447`). Les tests attendent 1 000 WOD ; ce total n'a **pas** été recalculé par exécution Dart ici.
- Persistance : clé **`kalis_state_v3`**, format d'export **3**, imports acceptant les formats **1, 2 et 3** ; compression gzip/base64, qui n'est pas un chiffrement.
- Les suggestions préremplissent des champs mais `_prefill` ne coche pas les séries ; l'historique crée une copie et utilise les garde-fous `readOnly`. Points favorables constatés par lecture, à garder sous tests.
- Achat : le montant payé est enregistré par ID ; un second appel sur un WOD déjà possédé ne le redébite pas en mémoire. La persistance reste le défaut KT-002.
- Notifications : mode approximatif déjà implémenté si l'autorisation d'alarme exacte manque ou est révoquée pendant la planification. Il ne faut pas ajouter ce repli comme s'il était absent.

| Fichier invariant | SHA-256 de référence |
| --- | --- |
| `assets/programme_v33.json.gz` | `eb6bc659a74b7636b7ba2deafc7f888e2c8860fd4418cd081ea9c23d1f15f6c0` |
| `assets/exercises_db.json.gz` | `8564ce8205b8c999cc30067254042edfbafc4511c23a0a311a544a7a805cad0d` |
| `pubspec.lock` | `73837d07776f976bb794a64bcdfe71fbd621e8326fcacd1718e73f72a411d546` |

## 3. Registre des problèmes

Les identifiants **KT-001 à KT-023 sont stables** et seront conservés dans les prochaines passes. Tous sont ouverts. Aucun point n'est déclaré corrigé ni testé sur téléphone.

Gravité : **P0** sécurité/perte de données/blocage critique ; **P1** parcours essentiel ou publication ; **P2** finition et qualité ; **P3** amélioration facultative. Pour un risque, la gravité indique l'impact potentiel à traiter, pas un incident démontré.

Une confirmation **statique** repose sur une chaîne de code explicite. Elle ne signifie pas qu'un test Flutter a été exécuté. Les manques de livraison confirmés sont distingués des bugs fonctionnels.

### A. Bugs ou incohérences fonctionnelles confirmés par lecture

#### KT-002 — P1 — Achat annoncé réussi avant confirmation de sauvegarde

- **Preuve :** `lib/store.dart:760–768` modifie `unlockedWods`, déclenche `_persist()` puis renvoie `true`. `2035–2053` lance une écriture non attendue et absorbe l'erreur dans `persistenceError`. `lib/wod_preview.dart:45–62` déclenche immédiatement animation et message de déblocage.
- **Impact :** si l'écriture échoue, l'écran a déjà confirmé l'achat ; l'accès peut disparaître au redémarrage. Une alerte globale existe (`main.dart:210–216`), mais ce n'est pas une transaction d'achat confirmée.
- **Prochaine action :** résultat asynchrone d'achat, état en cours/échec, cohérence mémoire/disque et test d'écriture refusée. Ne modifier ni prix ni dotation.
- **Responsable / lot :** IA, L2.

#### KT-003 — P1 — Essai commencé avant minuit : enregistrement bloqué après expiration

- **Preuve :** `lib/wod_screen.dart:83–93,107–110,171–175` vérifie `store.canRun(w)` au démarrage, à l'ouverture du score et lors de la reconstruction. `store.dart:865–893` recalcule l'essai selon le jour présent ; aucun droit attaché à la session commencée.
- **Scénario déduit :** commencer un essai non acheté à 23 h 59 ; finir après changement d'essai. `_score()` retourne avant d'ouvrir la saisie ; une reconstruction peut présenter la fiche d'achat. Le chrono n'est pas un résultat sauvegardé.
- **Prochaine action :** conserver le droit de terminer une tentative légitimement lancée, sans rendre le WOD définitivement acquis ; test 23 h 59 → 00 h 01 avec horloge contrôlée.
- **Responsable / lot :** IA, L3.

#### KT-004 — P1 — La règle « un essai du jour stable » n'est pas garantie

- **Preuve :** `_pick` ne prend que les WOD verrouillés (`store.dart:824–854`). L'achat retire donc le WOD essayé du pool. `notifyListeners()` invalide `_trialKey` et `_weeklyKey` (`1322–1327`). `trialWod` utilise une préférence, pas un filtre strict : les candidats non frais restent dans `rest` (`845–846,875–883`). La vitrine dépend aussi du niveau cible, recalculé après notification (`903–912`).
- **Scénarios déduits :** terminer puis acheter l'essai peut en faire apparaître un autre le même jour ; sans candidat préféré, un WOD déjà tenté peut être proposé ; une évolution des références/niveau peut modifier les sélections. Aucun ID quotidien persistant n'est exporté (`1736–1771`).
- **Contradiction :** `README.md:10–11`, `AUDIT_2.5.0.md:19–20` promettent un essai unique et une vitrine stable hors achat. Les tests lisent des cas limités, sans garantir ces transitions.
- **Prochaine action :** écrire le contrat de sélection et de consommation, le tester après achat, variation de niveau, redémarrage, minuit et fuseau ; décider explicitement le comportement quand le pool est épuisé.
- **Responsable / lot :** IA, arbitrage propriétaire si choix de comportement, L3.

#### KT-005 — P1 — Crédits recalculés à la baisse malgré la promesse « jamais repris »

- **Preuve :** `store.dart:753–758` calcule gains depuis niveau et bonus actuels, soustrait les achats et borne à zéro. `deleteWodResult` et `clearSession` retirent l'activité (`1654–1657,2747–2749`). `progression.dart:311–357` et `game.dart:705–713,789–790` reconstruisent XP et bonus à partir du journal restant ; aucun registre cumulatif de gains acquis n'est sérialisé.
- **Impact :** effacer des performances peut réduire les gains alors que les achats restent présents ; un écart « dépensé > gagné » est caché par `max(0, ...)`. L'accès acheté n'est pas supprimé par cette formule, mais le solde ne suit pas la promesse du README et de `REFONTE_UI.md`.
- **Prochaine action :** fixer le contrat de correction/suppression des performances et de conservation des crédits ; tests avant/après suppression/import. Toute migration comptable doit préserver les droits et éviter de créer des crédits par simple navigation. Ne pas choisir un nouveau barème pendant un correctif.
- **Responsable / lot :** propriétaire pour la règle, IA pour preuve et migration, L2 puis L3.

#### KT-006 — P1 — Calendrier commun fixé à la date du créateur

- **Preuve :** `assets/programme_v33.json.gz`, `meta.anchorMonday = 2026-07-13` ; `models.dart:242–283` ; accueil initialisé par `weekFor(now)` (`home_screen.dart:41–47`) ; rappels datés par `dateFor` (`notifications.dart:31–58`). Aucun départ utilisateur dans l'état exporté.
- **Impact :** une installation le 25 septembre 2026 s'ouvre sur la semaine calculée **11**, pas automatiquement au début. Le calendrier fixe finit le **18 avril 2027** ; après, l'accueil reste borné à 40 et les rappels du programme deviennent passés. Dates déduites du JSON et de la formule, pas d'un essai UI.
- **Prochaine action :** proposer un départ personnel et une migration séparant calendrier prévu et dates réellement effectuées. Préserver IDs, historiques, récompenses et rappels existants.
- **Responsable / lot :** propriétaire pour le parcours de départ, IA pour migration/tests, L4.

#### KT-007 — P1 — Références initiales traitées comme capacités personnelles

- **Preuve :** `store.dart:637–648` copie les valeurs embarquées dès l'installation ; `game.dart:202–271` les utilise directement pour force/endurance ; `store.dart:819` en déduit le niveau cible WOD. `main.dart:148–163` ouvre la navigation sans étape de validation du profil. Valeurs embarquées, par exemple : poids 71,5 kg, traction lestée 1RM 55 kg.
- **Impact :** suggestions de charge, fiche de personnage et recommandations reposent sur des références non confirmées par le nouvel utilisateur. Cela ne signifie pas que des séries sont automatiquement validées.
- **Prochaine action :** distinguer « référence initiale » et « valeur renseignée » ; onboarding minimal et états inconnus. Préserver les valeurs des utilisateurs existants ; validation sportive séparée du code.
- **Responsable / lot :** IA + propriétaire ; avis sportif sur le contenu, L4.

#### KT-008 — P1 — Tabata : prescription, chrono et score incompatibles

- **Preuve :** `wod_generator.dart:652–663` génère des Tabata 20 s/10 s avec score en répétitions du plus faible intervalle, mais `type: 'routine'`. `wod_models.dart:149–159` traite les routines comme un temps à minimiser. `wod_screen.dart:83–93` lance un chronomètre montant et `577–600` propose un score de temps, pas le score prescrit.
- **Impact :** le score structuré/record ne représente pas la consigne ; les phases Tabata ne sont pas pilotées par ce runner. Le champ de notes ne corrige pas le classement.
- **Prochaine action :** contrat par format, score structuré adapté et compatibilité des résultats anciens. Auditer ensuite les autres variantes du générateur sans réécrire leurs prescriptions.
- **Responsable / lot :** IA, L3b.

#### KT-009 — P1 — Saisies de séries non validées avant la coche

- **Preuve :** `session_screen.dart:1281–1293` stocke directement le texte ; `_checkSet` (`450–461`) bascule `done` sans contrôle des champs. À l'import, `store.dart:1922–1940` vérifie notamment identifiants, dates et nombre de séries, mais pas la validité numérique des chaînes de chaque série.
- **Impact :** valeurs collées invalides, répétitions négatives ou efforts hors domaine peuvent être enregistrés et la série marquée faite. Le clavier numérique seul ne valide pas le contenu. L'effet exact sur chaque statistique reste à tester.
- **Prochaine action :** validation selon le mode : kg, lest/assistance éventuelle, reps, secondes/minutes, RIR/RPE, vitesse ; états de saisie incomplets et virgule française. Ne pas imposer une interdiction globale de charge négative sans vérifier les exercices d'assistance.
- **Responsable / lot :** IA, L4b.

### B. Défauts de sécurité, de livraison ou de validation confirmés

#### KT-001 — P0 — Clé privée de signature et repli de mot de passe inclus

- **Preuve :** `signing/kalis_track.p12` existe ; inspection `keytool` réussie, entrée **PrivateKeyEntry**. `android/app/build.gradle.kts:24–30`, workflow joint (`jobs.build.env`) et `tools/verify_project.py:46–54` comportent un repli de mot de passe en clair. **Aucune valeur secrète n'est reproduite dans ce document.**
- **Propagation :** `tools/package_release.py:23–39` ne filtre pas `signing/` ni les secrets ; le README affirme conserver la signature dans le paquet. La fabrication actuelle recopie donc le problème.
- **Impact :** distribution de matériel permettant de signer. Exposition publique du dépôt/ZIP **inconnue** ; compromission effective **non établie**.
- **Prochaine action :** mettre la clé existante à l'abri, confirmer sa sauvegarde et son rôle, puis retirer les secrets du futur paquet et injecter la même identité par CI avec échec explicite si elle manque. Conserver les vérifications sans secret. Aucune génération, suppression de la seule copie ou rotation automatique.
- **Responsable / lot :** propriétaire pour sauvegarde et statut ; IA pour configuration et packaging, L1.

#### KT-010 — P1 — `targetSdk = 35` inférieur à l'exigence standard actuelle de soumission

- **Preuve locale :** `android/app/build.gradle.kts:9,20` : compilation API 36, cible API 35.
- **Source officielle consultée le 25/09/2026 :** Google Play impose API **36** aux nouvelles applications mobiles et mises à jour depuis le **31/08/2026** ; extension éventuelle jusqu'au **01/11/2026** [S1]. Aucun statut d'extension pour Kalis Track n'est connu.
- **Impact :** blocage de préparation à une soumission standard à cette date ; aucune affirmation de rejet effectif dans une console non consultée. Une application déjà publiée peut relever d'une règle distincte de disponibilité.
- **Prochaine action :** migration cible 36 et validation des changements de comportement, en vérifiant la chaîne native ; ne pas confondre `compileSdk` et `targetSdk`.
- **Responsable / lot :** IA, propriétaire pour statut console, L1b/L7.

#### KT-011 — P1 — Pipeline limité à l'APK, contrôles release incomplets

- **Preuve :** workflow joint entier : build `flutter build apk`, contrôle `apksigner verify`, publication de l'artefact APK ; aucun `flutter build appbundle`, contrôle du manifeste fusionné, test 16 Ko, installation/mise à jour ni `dart format`.
- **Point positif :** extraction, garde sur `build.gradle.kts`, `chmod +x`, lockfile imposé, analyse, Python et Flutter tests sont présents. La copie interne est identique au fichier joint.
- **Limite :** la vérification du certificat du keystore compare à un fichier fourni dans le même ZIP ; elle ne prouve pas la continuité avec un APK installé ou Play App Signing. Le `versionCode` calculé depuis l'heure vise une croissance, sans vérification du maximum déjà publié ni de toutes les branches concurrentes.
- **Prochaine action :** compléter les contrôles et les artefacts APK/AAB, comparer avec la signature de référence indépendante, connaître le dernier `versionCode`, conserver un seul contenu de workflow recopié aux deux emplacements.
- **Responsable / lot :** IA + propriétaire pour les références installées/publiées, L1b puis L7.

#### KT-012 — P2 — Tests de parcours agrandis au lieu de prouver le défilement mobile

- **Preuve :** `test/wod_store_test.dart:213–227` utilise **390 × 1800** pour trouver la vitrine ; `test/reward_flow_test.dart:44–49` définit **390 × 1600**, utilisé notamment ligne 195. L'audit embarqué 2.5.0 décrit cet agrandissement pour le test boutique.
- **Impact :** ces tests ne prouvent pas que toutes les actions restent accessibles sur un téléphone de hauteur courante. Cela ne démontre pas à lui seul un débordement dans l'application.
- **Point positif :** le test WOD `306–320` vérifie aussi l'absence d'exception à 320 × 720 et 130 %, mais ne parcourt pas toutes les actions. Le test récompense garde des assertions de chronologie ; attendre deux frames n'est pas, à lui seul, un contournement.
- **Prochaine action :** dimensions téléphone réalistes, défilement réel jusqu'aux actions, texte 130 % puis 200 %, assertions conservées. Rejouer les deux fichiers prioritaires et la suite complète.
- **Responsable / lot :** IA, L1b puis L5.

### C. Risques à vérifier — incidents non reproduits

| ID / gravité | Fichiers et preuve ou indice | Risque, prochaine action et responsable |
| --- | --- | --- |
| **KT-013 / P1** — Persistance, import concurrent et arrêt brutal | `store.dart:2000–2053,2714–2743` ; `main.dart:219–228`. Écritures normales en file ; import fait une écriture directe après attente de la file, sans y inscrire sa transaction ; timer de logs annulé ; pas de sauvegarde précédente distincte du document v3. Le plugin 2.5.3 ne garantit pas la durabilité disque au retour d'un appel [S2]. | Tester deux imports, import pendant édition/flush, écriture refusée puis redémarrage et mort du processus. Vérifier que le rollback conserve aussi les changements non encore écrits. Le store valide l'import avant application, point positif, mais l'atomicité et la durabilité globales restent non démontrées. **IA, L2.** |
| **KT-014 / P1** — Migration ancienne pouvant retirer des droits offerts | `store.dart:703–707` supprime les entrées de coût zéro si `credits_v < 2` ; la branche v3 retourne auparavant (`655–660`). Le test de migration `store_test.dart:160–178` utilise un achat de coût 1 et `credits_v:2`. | Comportement de suppression confirmé pour ce format ; population réellement touchée inconnue. Construire une fixture avec droits anciens gratuits ; arbitrer la contradiction avec « droits acquis préservés », sans réintroduire la création libre de WOD. **IA + propriétaire, L2.** |
| **KT-015 / P1** — Import très volumineux ou décompression excessive | `_unpack` (`store.dart:1602–1605`) décode gzip sans plafond ; `_parseBackup` (`1777–1963`) limite certains éléments, sans limite globale avant décompression/JSON ; dialogue `settings_screen.dart:350–377`. | Blocage mémoire/interface possible avec une sauvegarde anormale. Tester des fixtures bornées, fixer limites d'entrée, de sortie décompressée et de nombre total d'objets ; préserver les données en cas de rejet. Aucune attaque ou panne mémoire exécutée ici. **IA, L2.** |
| **KT-016 / P1** — Sauvegarde système et information sur les données | Manifeste principal : ni `allowBackup`, ni règles `fullBackupContent`/`dataExtractionRules` ; `settings_screen.dart:173–219` n'offre que presse-papiers et À propos sommaire. Aucune politique de confidentialité trouvée. | Android inclut par défaut les préférences dans Auto Backup lorsque les conditions s'appliquent [S3] ; transmission effective non observée. Décider la politique cloud/transfert local, inspecter le manifeste fusionné, tester restauration ; cartographier les dépendances avant Data Safety. Qualification RGPD/données de santé à examiner selon traitements réels. **Propriétaire + IA, validation spécialisée si nécessaire, L2/L7.** |
| **KT-017 / P1** — Droits des contenus non établis par le ZIP | `wod_models.dart`, mentions `source` notamment lignes 193,205,214,229,246,530,549 ; assets programme/base/images/sons. Aucun fichier de licence ou autorisation identifié dans le paquet. | Sources relevées : `onlinewod`, `caliwodfr`, `calisthenicsworkouts`, `david_invictusphysicalcoaching`, `fitnessinbox`, `entrainement_high_rox`, `ironboundtribe`. Attribution ne prouve pas autorisation. Rassembler provenance et droits du code, programme, base, WOD et médias ; ne pas supprimer/remplacer sans décision. **Propriétaire, spécialiste si besoin ; inventaire IA, L7.** |
| **KT-018 / P1** — Chronos/notifications après suspension ou destruction | `timers.dart:8–161,166–310`, `wod_screen.dart:48–68`, `session_screen.dart:38–59` : chronos en mémoire, sans session chrono dans `_backupJson`. `notifications.dart:174–185,337–397` : repli approximatif et traitement d'erreurs existants. | La reprise du compteur après destruction n'est pas implémentée dans les champs persistés inspectés ; scénario appareil non testé. Définir ce qui doit être repris, distinguer suspension et mort du processus ; tester permissions, fuseau, heure, redémarrage, son/vibration et wakelock. **IA + propriétaire pour la règle de reprise, L4b.** |
| **KT-019 / P1** — Compatibilité native et pages mémoire 16 Ko non vérifiées | `pubspec.lock`, Gradle/settings, `ndkVersion = flutter.ndkVersion`, workflow ; aucun APK/AAB disponible. | Build de la combinaison verrouillée, minimum Android effectif des plugins, ABIs, alignement ELF/ZIP, installation sur appareils ciblés et exigences 16 Ko à vérifier. Ni ancien numéro Flutter ni `compileSdk 36` ne suffisent à conclure. **IA/CI puis propriétaire sur appareil, L1b/L7.** |
| **KT-020 / P2** — Accessibilité et mise en page à confirmer | `nav_bar.dart:89–98` utilise `FittedBox(scaleDown)` pour réduire le libellé ; `ui.dart`, thème, écran de séance ; tests partiels. | Vérifier texte 200 %, 320 px, clavier et gestes, contrastes réellement mesurés, TalkBack, cibles tactiles et annonces de chronos. La réduction de texte entre en tension avec le cahier des charges ; aucune capture/régression visuelle affirmée ici. **IA puis propriétaire, L5.** |

### D. Propositions d'amélioration — pas des bugs démontrés

| ID / priorité | Constat et proposition | Limites, responsable et lot |
| --- | --- | --- |
| **KT-021 / P2** — Maîtrise des sauvegardes | `settings_screen.dart:173–213,314–379` propose un export collé et avertit déjà du remplacement. Ajouter export/import par fichier, aperçu, sauvegarde avant remplacement et suppression locale confirmée. | Choisir le parcours et les dépendances utiles ; distinguer données locales, fichiers exportés et backups système. **Propriétaire + IA, L2b.** |
| **KT-022 / P2** — À propos fiable | `settings_screen.dart:10,214–219` duplique la version en constante et n'affiche ni support, ni accès aux licences/politique. | Source fiable de version/build, contact et identité réels, licences et URL publique à fournir. Ne pas inventer de coordonnées. **Propriétaire + IA, L7.** |
| **KT-023 / P3** — Optimisation mesurée et découpage progressif | `store.dart:1736–1771,2039–2042` sérialise l'état et compare les définitions WOD lors des snapshots ; `nav_bar.dart:56–57` emploie un flou. Le store fait 2 843 lignes. | Mesurer d'abord sur jeux de données représentatifs et appareil profile/release, puis modifier les seuls points coûteux. Pas de changement de framework ni de migration de stockage par réflexe. **IA, L6.** |

## 4. Signature, sauvegardes et données : décisions avant la finition visuelle

Ces questions préparent les lots suivants ; elles ne conditionnent pas la livraison de cet audit.

### Signature — informations à fournir par le propriétaire

1. L'application a-t-elle été publiée sur Google Play ? Play App Signing est-il activé ? La clé incluse sert-elle de clé d'envoi ou de clé de signature des installations directes ?
2. Existe-t-il une copie de la clé et de ses moyens d'accès conservée séparément ? **Ne pas envoyer de mot de passe en clair dans le suivi.** Confirmer son existence avant de retirer la clé des prochaines archives distribuables.
3. Le ZIP ou le dépôt contenant la clé ont-ils été publics ou partagés ? L'audit ne peut pas déduire ce statut de la présence locale du fichier.
4. Quel est le dernier APK réellement installé et son certificat ? Quel est le plus grand `versionCode` déjà diffusé ? Pour la prochaine passe de continuité, fournir l'APK de référence si possible, sans désinstaller l'application du téléphone.

**Certificat local contrôlé :** empreinte SHA-256 `9ecbe2a37799f825374d01cc35db5472a51767c3a9327eef1dbd198227aefba9`, correspondant au fichier `signing/certificate.sha256`. Ce certificat public peut servir de repère, pas de preuve du certificat des installations externes. Aucune clé privée n'a été extraite, générée, tournée ou supprimée.

Les noms de secrets déjà utilisés par la CI sont `KALIS_KEYSTORE_BASE64` et `KALIS_KEYSTORE_PASSWORD` ; `KEYSTORE_PASSWORD` est la variable transmise aux outils. Leur présence/configuration dans le dépôt réel n'a pas été vérifiée. La future CI devra les exiger pour la release, sans repli ni génération automatique ; les tests sans signature doivent rester possibles.

### Sauvegarde — plan de conservation proposé

- Avant toute migration, disposer d'un export réel et de fixtures anonymisées : utilisateur neuf, journal rempli, séances personnelles répétées, achats/remises, wishlist, anciens formats et état dégradé. Préserver aussi la sauvegarde brute en cas d'initialisation en erreur.
- Inventorier puis comparer avant/après : références, IDs et dates de séances, séries/notes, occurrences personnelles, résultats et prescriptions WOD, prix payés, accès acquis, wishlist, réglages et dernier niveau vu.
- À l'import, valider intégralement avant remplacement, borner les tailles, sérialiser la transaction avec les autres écritures et tester les erreurs. Garder une possibilité de récupération qui n'écrase pas l'original corrompu.
- Décider si la correction d'une performance retire de l'XP et/ou des crédits, tout en préservant les droits achetés. Ne pas confondre correction d'historique et nouvel équilibrage.
- Décider le traitement des accès historiques gratuits et le départ personnel du programme avant d'écrire une migration.
- Définir la politique Android : cloud, transfert de téléphone et restauration. La désinstallation n'est ni un protocole de mise à jour ni une preuve de suppression de toutes les sauvegardes externes.

### Carte initiale des données

| Données | Stockage/traitement observé | Point à préserver ou clarifier |
| --- | --- | --- |
| Poids, 1RM, maxima reps, références de charge | `values` dans l'état local et l'export ; calcul des charges et attributs | Valeurs utilisateur vs defaults ; pas d'interprétation médicale automatique |
| Séries, charge, effort, vitesse, notes, dates | `logs` ; historique, progression et estimations | Dates réelles, contenu libre des notes, corrections explicites |
| Exercices/séances personnels | `userExercises`, `custom`, journaux archivés | Noms/IDs et anciennes occurrences indépendantes du modèle courant |
| Résultats WOD, prescription et notes | Catalogue/résultats dans l'état ; records/XP dérivés | Format de score et compatibilité des résultats anciens |
| Droits WOD et envies | `unlocked` avec coût payé ; `wishlist` | Aucun débit non financé ; conservation des acquis |
| Réglages et dernier niveau vu | État local/export | Effet réel, continuité des permissions/canaux Android |
| Exports et récupération | Presse-papiers normal ; copie brute des préférences en écran d'erreur (`main.dart:105–114`) | Le format brut de secours n'est pas l'export habituel importable tel quel ; documenter la récupération |
| Sauvegarde système | Politique implicite du manifeste source | Confirmer contenu final et comportement appareil avant les déclarations de confidentialité |
| Dépendances | Plugins natifs ; présence transitive de `http` dans le lockfile ; aucune API distante appelée repérée dans les routes inspectées | Ne pas déduire une collecte du seul package `http`, ni l'absence de transmission de l'absence de compte ; auditer les dépendances et le manifeste final |

## 5. Lots proposés, limités et ordonnés

Chaque sous-lot doit être livrable et vérifiable séparément. Les validations visuelles significatives arrivent **après** les décisions et protections de signature/données. Tous les lots ci-dessous sont proposés, pas démarrés.

| Ordre / lot | Périmètre limité | Entrée nécessaire | Critère de sortie |
| --- | --- | --- | --- |
| **L0 — Référence** | Audit actuel, empreintes, tests disponibles, suivi | ZIP joint | **Terminé pour cette passe** ; aucun changement applicatif |
| **L1 — Signature et ZIP** | KT-001 : Gradle, vérificateur, packaging, copie du workflow ; pas de changement UI ou métier | Sauvegarde de la clé confirmée, rôle de signature identifié | Aucun secret dans le futur ZIP ; même certificat attendu ; release sans secrets échoue clairement ; tests Python non signés utilisables ; archive ≤ 25 000 000 octets |
| **L1b — Validation et cible Android** | KT-010/011/012/019 : gates CI, cible 36 et compatibilité, tests prioritaires à taille mobile ; séparer chaque correction révélée | Exécuteur Flutter/Android disponible ; APK/versionCode de référence pour continuité | Analyse et tests sur le code livré ; APK/AAB réellement construits ; signature et manifeste inspectés ; chaque échec restant documenté |
| **L2 — Sauvegarde et achats** | KT-002/013/014/015 : écritures, import/migration, erreurs, bornes, fixtures ; contrat KT-005 | Export de secours et arbitrages sur acquis | Import invalide sans mutation ; aucune confirmation d'achat avant résultat ; essais d'échec/reprise ; conservation des données et droits démontrée |
| **L2b — Contrôle utilisateur des données** | KT-016/021 : sauvegarde par fichier, aperçu/remplacement, suppression locale et politique Android | Choix de sauvegarde système ; parcours approuvé si changement important | Aller-retour de sauvegarde, confirmation de remplacement, suppression au périmètre honnête ; restauration système testée |
| **L3 — Économie et essai WOD** | KT-003/004/005 : unicité, jour/semaine/fuseau, droit de finir, stabilité, comptabilité retenue | Persistance fiabilisée et règles tranchées | Achat normal/insuffisant/doublé ; essai terminé/acheté/redémarré ; minuit ; suppression/import ; aucun acquis perdu |
| **L3b — Formats WOD** | KT-008 : Tabata d'abord, puis inventaire précis des autres formats ; scores/records | Contrat de chaque format et compatibilité des scores | Chrono et score concordent avec prescription ; anciens résultats conservés et interprétés explicitement |
| **L4 — Départ du programme** | KT-006/007 : départ personnel et références confirmées ; migration isolée | Choix propriétaire sur onboarding/calendrier | Nouveau venu commence correctement ; ancien calendrier et historique conservés ; rappels/XP cohérents ; contenu 40 semaines inchangé |
| **L4b — Séances et reprise** | KT-009/018 : saisie, chronos, fin/bilan, historique, notifications et destruction de processus | Règle de reprise définie | Scénarios programme/perso/rappel complets, validation numérique, historique non modifié, aucun double résultat/récompense |
| **L5 — Finition visuelle** | KT-012/020, écran par écran, composants existants | Données/signature stabilisées ; proposition validée pour changements importants | Captures réellement rendues clair/sombre ; 320 px, 130/200 %, clavier, TalkBack ; validation propriétaire distincte des tests |
| **L6 — Performance** | KT-023, un coût mesuré à la fois | Mesures de référence sur appareil et jeux de données | Avant/après reproductible, aucun gain inventé, aucune régression fonctionnelle |
| **L7 — Candidate et publication préparée** | KT-010/011/016/017/019/022 : Android, signatures/MAJ, licences, politique, Data Safety, informations éditeur | Droits, coordonnées, URL publique, compte/store identifiés | Checklist de publication documentée ; APK/AAB validés ; limites/blocages ouverts visibles ; aucune publication automatique |

Un défaut technique local pourra être corrigé dans son lot après autorisation de modification. Une migration, une nouvelle règle économique, un retrait de contenu ou une refonte importante conserve son arbitrage explicite. Le périmètre de cette passe reste L0.

## 6. Décisions à préserver

1. **Source unique et échange de ZIP.** Toujours relever nom, taille, SHA-256 et version de la base reçue. Jamais de reprise silencieuse d'une ancienne archive. Aucun dépôt externe n'est adopté comme nouvelle référence.
2. **Identité Android et signature.** Conserver `fr.tchoupi.streetlift_tracker` et la continuité des installations ; retirer les secrets du paquet seulement avec procédure de conservation de la clé. Pas de désinstallation pour mettre à jour.
3. **Contenu métier.** Conserver 40 semaines, 280 jours, 1 954 entrées, 505 exercices, formules et identifiants. Les estimations et programmes ne sont pas une certification de santé ou de niveau physique.
4. **Données.** Aucun reset silencieux, perte d'historique, de séance personnelle, de résultat, de droit WOD ou de réglage. Toute modification de schéma est versionnée et migrée avec fixtures.
5. **Économie.** Pas de changement arbitraire d'XP/niveaux/crédits/prix. Barème actuel : `1 + 2 × niveau + 3 × floor(niveau/5)` ; bonus actuels chapitre +3, boss +5, semaine complète +1 ; prix catalogue de base 1 à 4, remises avec plancher 1. L'incohérence KT-005 exige une décision, pas une retouche discrète du barème.
6. **WOD.** Acquis avec crédits ; essai temporaire comme exception. Pas de création libre de WOD ajoutée. Les séances personnelles et contenus anciens restent compatibles.
7. **Fonctionnement local.** Pas de paiement, abonnement, publicité, compte obligatoire, cloud applicatif ou analytics ajoutés sans validation. La sauvegarde Android est un sujet distinct.
8. **Navigation et identité visuelle.** ARSENAL, STATS, PROGRAMME, RÉGLAGES ; suivi/pilotage/progression regroupés dans STATS. Bordeaux `#6B0C0C`, rouge d'action `#A61717`, anthracites `#121212/#1E1E1E`, thèmes clair/sombre/système.
9. **Choix visuels du cahier des charges.** Titres principaux en majuscules ; marque K sans fond dans les transitions prévues ; indicateur de niveau sans contour ni dégradé, progression à séparation nette ; ne pas réintroduire AVANT/ARRIÈRE. Cette contrainte de dégradé ne s'étend pas automatiquement aux couvertures WOD.
10. **Validation honnête.** Tests à dimensions réalistes, sans retirer d'assertions pour obtenir du vert. Ancien rapport, analyse statique, build, test automatique et essai appareil restent des preuves différentes.

## 7. Tests et contrôles exécutés pendant cette passe

Les commandes suivantes ont donné un résultat réel. Les tests du projet ont été exécutés depuis `streetlift_tracker/`, avec `PYTHONDONTWRITEBYTECODE=1` pour ne pas ajouter de cache au code extrait.

| Contrôle | Résultat réel | Portée |
| --- | --- | --- |
| Python `hashlib.sha256` et `ZipFile.testzip()` sur le ZIP reçu | Succès ; empreinte et taille en section 1 ; `testzip()` renvoie `None` | Intégrité de l'archive, pas fonctionnement de l'app |
| Extraction contrôlée | 272 fichiers extraits | Lecture réelle de la source jointe |
| Copie/édition/réarchivage jetable | Succès, fichier relu identique au contenu modifié | Capacité technique à préparer un futur ZIP |
| Réarchivage complet et comparaison fichier par fichier | 272/272 empreintes identiques ; CRC valide | Capacité à réemballer le projet sans perdre de fichier |
| `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/tests -v` | **Code de sortie 0 ; 4 tests réussis ; 0,027 s** | Arrondi type Excel, parsing des repos, compression reproductible, assets et identité Android |
| `PYTHONDONTWRITEBYTECODE=1 python3 tools/verify_project.py --signing` | **Code de sortie 0** : 40 semaines, 280 jours, 1 954 exercices programme, 505 base ; comparaison certificat réussie | Assets/XML et identité locale ; pas une compilation ni une comparaison à un APK installé |
| `keytool -list` sur l'alias existant, mot de passe fourni par variable temporaire | **Code de sortie 0 ; PrivateKeyEntry présente** | Confirme le matériel privé dans le keystore ; aucune clé extraite |
| `java -version`, Python et recherche d'outils | Versions/disponibilités en section 1 | État de l'environnement |
| Comparaison du workflow interne et joint | Identiques octet par octet | Aucune divergence actuelle |
| Comparaison finale des 272 fichiers source avec le manifeste initial | **0 modification** | Respect du périmètre audit uniquement |

Sortie de la suite Python exécutée :

```text
test_pack_is_reproducible_and_preserves_sources ... ok
test_rest_ranges_and_mixed_units ... ok
test_rounding_matches_excel_half_away_from_zero ... ok
test_shipped_assets_and_android_identity ... ok
Ran 4 tests in 0.027s
OK
```

Le test de compression écrit seulement dans son répertoire temporaire. Les 4 tests réussis ne constituent pas une validation des parcours Flutter. Les rapports `validation/2.5.0/` ont aussi été lus, mais leurs résultats historiques n'ont pas été additionnés aux tests exécutés ici.

## 8. Tests restant à faire

### Commandes non exécutées ici

| Commande/contrôle prévu | Statut et prérequis |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Non exécuté : Dart absent |
| `flutter pub get --enforce-lockfile` | Non exécuté : Flutter absent ; aucun nouveau lockfile produit |
| `flutter analyze --no-pub` | Non exécuté : Flutter absent |
| `TZ=Europe/Paris flutter test --no-pub --timeout 60s --reporter expanded` | Non exécuté : Flutter absent ; totalité de la suite à reprendre |
| Tests ciblés `reward_flow_test.dart`, `wod_store_test.dart`, `store_test.dart`, `notifications_test.dart`, `timers_test.dart` | Lus partiellement/inventoriés, pas exécutés ; ajouter les régressions des constats de cet audit dans les lots concernés |
| `flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart` | Non exécuté ; aucune capture créée ; le test visuel est optionnel dans le projet |
| Tests d'intégration sur appareil | Aucun dossier `integration_test/` dans la source ; protocole à créer |
| `flutter build apk --release --no-pub --build-number=<code_validé>` | Non exécuté : Flutter/Android absents ; secrets et code de version à sécuriser |
| `flutter build appbundle --release --no-pub --build-number=<même_code_validé>` | Non exécuté ; étape absente du workflow actuel |
| Vérifier APK/AAB, manifeste fusionné, certificat attendu, ABIs et 16 Ko | Non exécuté : aucun artefact construit disponible |
| Installation vierge et mise à jour sans désinstallation | Non exécuté : appareil et APK de référence requis |

Les emplacements `<...>` sont des paramètres à renseigner, pas des commandes prêtes à copier telles quelles. La future CI n'a pas été modifiée dans cet audit.

### Matrice de scénarios prioritaires

| Scénario | Preuve attendue | Responsable / lot |
| --- | --- | --- |
| Installation neuve hors date d'origine | Départ et références compris ; pas de performance supposée | IA + propriétaire, L4 |
| Mise à jour avec données existantes | Même application/signature ; comparaison des données avant/après ; zéro désinstallation | IA/CI + propriétaire, L1/L2/L7 |
| Export/import formats 1/2/3, sauvegarde corrompue/tronquée/volumineuse | Conservation de l'original, erreurs compréhensibles, reprise possible | IA, L2 |
| Échec d'écriture, double import, import pendant flush, processus tué | Aucun succès mensonger ; état cohérent au redémarrage | IA + appareil, L2 |
| Séance programme et perso complète | Saisie → repos/pause → reprise → bilan → récompenses → historique exact | IA + propriétaire, L4b |
| Historique en lecture seule | Consultation ne modifie ni champs, ni dates, ni récompenses | IA, L4b |
| Notification à froid/à chaud/journée faite | Bonne séance ou historique ; bilan et récompense une seule fois | IA + appareil, L4b |
| Achats normal, insuffisant, double appui, écriture refusée | Prix payé figé, aucun double débit, conservation après redémarrage | IA, L2/L3 |
| Essai du jour terminé puis acheté ; redémarrage ; minuit et fuseau | Contrat d'unicité respecté ; résultat d'une tentative engagée conservé | IA, L3 |
| Suppression/correction/import d'activité | Solde et droits cohérents avec la règle explicitement choisie | IA + propriétaire, L3 |
| For Time, AMRAP, EMOM, tours, routines, Tabata et variantes | Score et record compatibles avec les consignes ; migration des anciens scores | IA + validation sportive du contenu, L3b |
| Fin des 40 semaines | Navigation, rappels et progression sans date fictive ni perte de journal | IA, L4 |
| Sons/vibration/wakelock/permissions refusées | Effet des options, repli, pas de doublons ; essais appareil | IA + propriétaire, L4b |
| 320 px, 130/200 %, clavier et TalkBack | Actions atteintes par défilement ; pas de masquage par réduction artificielle ; contrastes mesurés | IA + propriétaire, L5 |
| Performance avec historique long et catalogue complet | Appareil/OS/données/protocole documentés ; mesures profile/release avant/après | IA, L6 |

### Checklist de validation visuelle par parcours

Toutes les lignes sont **à rendre et à valider** : la lecture du code n'est pas une validation visuelle du propriétaire.

- [ ] Démarrage et écran de récupération.
- [ ] Navigation principale et clavier ouvert.
- [ ] Programme : semaine, jour, consignes et fin du programme.
- [ ] Séance : chaque mode, saisies, chronos, bilan et récompenses.
- [ ] Historique de séance programme et personnelle.
- [ ] Arsenal : vide/rempli, création/édition/duplication de séance.
- [ ] Boutique : catalogue, recherche, filtres, vitrine, envies et crédits.
- [ ] Fiche WOD : verrouillé, insuffisant, acheté, essai et remise.
- [ ] Runner WOD, score, résultats et records par format.
- [ ] STATS : Aperçu, Parcours, Performances, Historique et références.
- [ ] Réglages : chaque section, permissions, export/import et À propos.

## 9. Préparation de publication encore ouverte

- **Technique :** traiter KT-001/010/011/019, valider les binaires réellement produits et la mise à jour, contrôler le manifeste final et les permissions. Le besoin de `SCHEDULE_EXACT_ALARM` reste à justifier pour ce produit ; le repli approximatif existe déjà.
- **Données :** trancher sauvegarde/effacement/restauration, vérifier flux effectifs et dépendances, préparer politique et déclarations cohérentes. La politique de confidentialité, Data Safety et déclaration des fonctionnalités santé/fitness ne sont pas rédigées/validées dans cette passe.
- **Éditeur :** identité, contact de support, URL publique de confidentialité, type/date du compte développeur et statut de publication à fournir. Aucun texte légal fictif ni lien factice.
- **Droits et sport :** autorisations des contenus et médias, licences des dépendances ; validation compétente des prescriptions si nécessaire. Aucune conclusion juridique ou sportive exhaustive.
- **Distribution :** statut Play App Signing, piste d'essai, exigences de test du compte et dernière version diffusée inconnus. Aucune publication ni dépense effectuée.

### Sources externes limitées à l'appui de cet audit

Consultation : **25 septembre 2026**. Elles complètent les constats du ZIP et ne fournissent aucune autre base de code.

- **[S1] Google Play, Target API level requirements** — [page officielle](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en). Exigence API 36 depuis le 31 août 2026 pour nouvelles applications mobiles/mises à jour ; extension éventuelle à vérifier dans la console concernée. Ne démontre pas le statut de Kalis Track.
- **[S2] Flutter, documentation de `shared_preferences` 2.5.3** — [version verrouillée](https://pub.dev/packages/shared_preferences/versions/2.5.3). La documentation prévient que le retour d'un appel n'assure pas la persistance disque des données critiques. Justifie des tests de durabilité, pas une migration automatique vers un autre stockage.
- **[S3] Android Developers, Auto Backup** — [documentation officielle](https://developer.android.com/identity/data/autobackup). Préférences incluses par défaut, `allowBackup` vrai par défaut ; comportement conditionné par système/réglages et particularités de transfert entre appareils. La sauvegarde effective de Kalis Track n'a pas été observée.

## 10. Journal de cette passe et protocole ZIP

| Élément | État |
| --- | --- |
| Code, tests, assets, dépendances et workflow modifiés | **Aucun** |
| Livrable créé | **`SUIVI_PROJET.md`** |
| Correctifs appliqués | **Aucun : audit uniquement** |
| Tests automatiques applicatifs | **4 tests Python réussis ; Dart/Flutter non exécutés** |
| Build APK / AAB | **Non exécuté** |
| Vérification sur appareil | **Aucune** |
| Validation de publication | **Non obtenue** |

Pour chaque prochaine passe : joindre le ZIP retenu et ce suivi ; annoncer le ou les sous-lots autorisés ; contrôler l'empreinte d'entrée ; livrer le projet complet sous `streetlift_tracker/`, sans caches/binaires/secrets, dans la limite de 25 000 000 octets ; mettre à jour ce document et la liste précise des fichiers changés. Livrer le workflow associé sans divergence si modifié. Fournir les binaires uniquement lorsqu'ils ont réellement été compilés et contrôlés.

Les tickets conservent leur ID et passent distinctement par **ouvert → corrigé dans le code → testé automatiquement → vérifié sur appareil**, avec preuves et limites. Une validation visuelle ou de publication du propriétaire n'est jamais déduite d'un test automatisé.
