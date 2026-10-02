# Kalis Track — Performance (L6, KT-023)

Version 3.0.3+64. Ce document décrit ce qui a été mesuré, comment le refaire, et ce que les chiffres prouvent ou ne prouvent pas. Les résultats bruts sont dans `validation/3.0.3/`.

## 1. Niveaux de preuve

| Niveau | Où | Utilisé en L6 |
| --- | --- | --- |
| 1. Lecture du code, hypothèse de coût | — | Oui : repérage des coûts, puis mesure |
| 2. Mesure hôte (microbenchmark) | `flutter test` sur un runner GitHub, machine virtuelle Dart **JIT, mode debug**, sans GPU | Oui : banc A/B, 6 manches alternées |
| 3. Mesure dans l'application sur émulateur | APK **profile (AOT) x86_64**, émulateur Android sur runner GitHub, rendu logiciel | Préparée, **non exécutée** (§6) |
| 4. Mesure dans l'application sur téléphone physique, profile/release | — | **Non mesuré** (aucun téléphone relié) |

Une mesure hôte compare deux versions du code sur la même machine. Elle ne donne ni la fluidité sur ton téléphone, ni une consommation de batterie. La documentation Flutter le rappelle : le mode debug et les émulateurs ne sont pas représentatifs du mode release ([Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)). Aucun gain d'autonomie n'est annoncé.

## 2. Jeux de données (fixtures)

`test/support/perf_fixtures.dart`, générateur mulberry32, graine `20260926`, dates fixes (départ lundi 05/01/2026). Chaque série a sa propre heure de validation (toutes les 2 min 30), comme dans l'application. Documents construits par l'application elle-même (import puis écriture), avec le catalogue complet de la version (1 000 WOD).

| Profil | Séances | Séries | Résultats WOD | WOD perso | WOD modifiés | Achats | Séances perso (modèles) | Document stocké |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| neuf | 0 | 0 | 0 | 0 | 0 | 0 | 0 | aucun |
| régulier | 86 | 1 877 | 40 | 0 | 0 | 10 | 20 | 26 315 car. |
| long | 320 | 6 587 | 300 | 0 | 0 | 30 | 60 | 89 539 car. |
| chargé | 840 | 20 347 | 1 500 | 50 | 30 | 150 | 150 | 244 583 car. (JSON exporté : 2,9 Mo) |

Ces totaux sont comptés sur les documents par le banc (ligne `meta` des fichiers JSON Lines), pas repris de l'audit. « Chargé » reste très en deçà des limites d'import (20 000 séances, 100 000 résultats). Données entièrement synthétiques : aucune donnée personnelle.

## 3. Banc hôte (niveau 2)

### Fichiers

- `test/l6_perf_bench_test.dart` : scénarios. **Ignoré sans** `--dart-define=KALIS_PERF=true` ; aucun seuil de durée (une variation de charge du runner ne peut pas faire échouer la CI).
- `tools/perf_compare.py` : synthèse base / candidate (`summary.md`, `summary.csv`), comparaison des empreintes métier. Testé par `tools/tests/test_perf_compare.py`.
- CI temporaire (`claude/ci-tools`, workflow `claude-perf.yml`) : la base 3.0.2 (`baseline/streetlift_tracker`) et la candidate tournent **dans le même job, en alternance** (manche impaire : base puis candidate ; manche paire : l'inverse), avec **le même banc et les mêmes fixtures** (contrôlé par `cmp` dans `environment.txt`).

### Reproduire

```bash
cd streetlift_tracker
flutter pub get --enforce-lockfile
TZ=Europe/Paris flutter test --no-pub --timeout none \
  --dart-define=KALIS_PERF=true --dart-define=KALIS_PERF_N=9 \
  --dart-define=KALIS_PERF_LABEL=cand --dart-define=KALIS_PERF_OUT=$PWD/../perf/cand-r1.jsonl \
  test/l6_perf_bench_test.dart
# même commande dans l'arbre de base avec KALIS_PERF_LABEL=base, en alternant les manches
python3 tools/perf_compare.py ../perf
```

Chaque scénario : 2 exécutions d'échauffement non comptées, puis 9 mesures par manche (5 pour les scénarios d'écran et les imports), 6 manches par côté. Les valeurs brutes sont toutes conservées (aucune « meilleure exécution » retenue).

### Règle de conclusion

Calibrée sur une comparaison **A/A** (même code des deux côtés, `validation/3.0.3/perf-host-AA3/`) : des écarts de médiane jusqu'à 27 % y sont apparus entre processus. « Amélioration » exige donc : au moins 8 observations par côté, médiane candidate ≤ 0,80 × base, intervalles interquartiles disjoints **et** candidate plus rapide dans **chaque** manche. « Régression » : symétrique (≥ 1,25 ×). Sinon : « gain non démontré ». Appliquée au A/A, cette règle ne conclut rien (vérifié). Aucune signification statistique n'est revendiquée.

### Environnement de la mesure finale (AB3)

Commit `ebff3c6` de la branche temporaire ; Flutter 3.29.3, Dart 3.7.2, moteur `cf56914b32` ; Linux x86_64, 2 vCPU Intel Xeon Platinum 8370C, 7,9 Go ; flutter_tester (JIT, debug) ; `TZ=Europe/Paris`. Empreintes : `lib`+`test` base `d3636337…`, candidate `e1469ec2…` ; fixtures `f0eef30a…`, banc `7cde0651…` (identiques des deux côtés). Coût de l'instrumentation : un `Stopwatch` autour de l'opération mesurée, identique des deux côtés.

## 4. Scénarios et résultats hôte (AB3, médiane [min–max], ms, 6 manches)

« Écran » = temps d'une image dans le moteur de test (construction + mise en page + peinture, **sans rastérisation ni GPU**), pas une durée d'affichage sur téléphone.

| Scénario | Profil | Base | Candidate | n (par côté) | Conclusion |
| --- | --- | --- | --- | --- | --- |
| Frappe dans une série, séance ouverte par-dessus les 4 onglets visités (image suivante) | long | 93,3 [56,7–179,2] | 0,079 [0,044–0,157] | 120 | amélioration |
| idem | chargé | 93,3 [82,7–293,9] | 0,035 [0,032–0,072] | 120 | amélioration |
| Validation d'une série (image suivante) | long | 152,2 [104,3–330,9] | 0,079 [0,050–0,149] | 48 | amélioration |
| idem | chargé | 174,8 [158,8–375,2] | 0,039 [0,035–0,070] | 48 | amélioration |
| Retour aux onglets après la séance : **première image** | long | 17,0 [13,0–44,6] | 59,6 [33,5–134,4] | 24 | **régression** |
| idem | chargé | 11,4 [10,3–80,0] | 56,7 [28,0–70,4] | 24 | **régression** |
| Retour : animation complète | long | 56,4 [50,5–104,8] | 75,8 [61,2–122,8] | 24 | **régression** |
| idem | chargé | 132,6 [118,3–274,6] | 137,5 [131,0–242,3] | 24 | gain non démontré |
| STATS affiché (Historique), notification du store | long | 114,4 [97,9–225,2] | 16,0 [14,5–27,7] | 60 | amélioration |
| idem | chargé | 164,9 [153,8–417,0] | 16,6 [14,1–21,3] | 60 | amélioration |
| Estimations des 1 000+ WOD, 2ᵉ passage | long | 10,7 [10,0–22,3] | 0,27 [0,21–0,53] | 54 | amélioration |
| idem (1 050 WOD) | chargé | 116,9 [71,7–271,7] | 0,21 [0,18–0,78] | 54 | amélioration |
| Statistiques de tous les WOD (`wodStats`) | long | 18,2 [17,4–29,0] | 0,74 [0,60–1,36] | 54 | amélioration |
| Classement du catalogue (démarrage, import) | long | 23,0 [22,2–26,5] | 12,2 [11,8–15,1] | 54 | amélioration |
| Encodage de la sauvegarde (`exportAll`) | neuf | 4,00 [3,81–5,25] | 0,45 [0,29–0,94] | 54 | amélioration |
| idem | régulier | 8,77 [8,32–20,7] | 4,73 [4,27–7,19] | 54 | amélioration |
| idem | long / chargé | 24,1 / 81,6 | 19,6 / 73,7 | 54 | gain non démontré |
| Saisie puis écriture attendue (`saveLogs` + `flush`) | neuf / régulier | 4,18 / 13,4 | 0,72 / 9,47 | 54 | amélioration |
| idem | long / chargé | 38,5 / 130,2 | 35,2 / 120,9 | 54 | gain non démontré |
| Validation + progression + écriture attendue | neuf / régulier | 7,59 / 20,1 | 1,21 / 15,8 | 54 | amélioration |
| idem | long / chargé | 66,6 / 214,7 | 60,0 / 196,7 | 54 | gain non démontré |
| Import appliqué | régulier | 113,4 | 79,3 | 30 | amélioration |
| Import (aperçu, appliqué) | long / chargé | — | — | 30 | gain non démontré |
| Démarrage des données (`store.init`) | 4 profils | 63 / 117 / 238 / 403 | 43 / 98 / 205 / 387 | 54 | gain non démontré |
| Progression, jeu, historique STATS, records, carte musculaire | 4 profils | — | — | 54 | gain non démontré (code inchangé) |
| Premier écran, premières visites d'onglets, catalogue (ouverture, recherche, défilement), changement de couleur | long, chargé | — | — | 18 à 60 | gain non démontré |

Tableau complet (toutes les lignes, min/max, ratios) : `validation/3.0.3/perf-host-AB3/summary.md` et `.csv`.

**Mémoire hôte** (RSS du processus flutter_tester après 10 ouvertures/fermetures du catalogue et d'une séance, ramasse-miettes non forcé) : long 494 / 489 Mo, chargé 678 / 680 Mo (base / candidate, médianes, n = 12). Valeurs brutes, sans conclusion : aucune croissance retenue n'est démontrée ni exclue par cette mesure.

**Résultats métier identiques** : pour les 4 profils, l'empreinte de l'export complet, l'XP, le niveau, les crédits, les niveaux des WOD, les estimations et statistiques de chaque WOD, l'historique STATS, les records, la carte musculaire et la sélection « à ta mesure » sont **identiques** entre la base et la candidate, dans les 6 manches (40 comparaisons sur 40).

## 5. Lecture des résultats

- **Frappe et validation** : dans la base, chaque frappe dans une série notifiait le store, et les onglets déjà visités, **masqués sous la séance**, se reconstruisaient (PROGRAMME, STATS avec ses sections, ARSENAL, RÉGLAGES), jusqu'à recalculer la carte musculaire de toute l'histoire. Dans la candidate, aucune image n'est nécessaire : la séance elle-même ne se reconstruisait déjà pas à la frappe (seul son libellé de pilotage est recalculé).
- **Coût déplacé, pas supprimé en entier** : au retour de la séance, l'onglet affiché se met à jour une fois. Cette image coûte environ 40 ms de plus (hôte) dans la candidate. C'est **une** reconstruction au lieu d'une par frappe et par validation. La progression invalidée par une validation est recalculée une fois à l'écriture différée (600 ms) au lieu de l'être dans l'image suivante ; ce coût reste compté dans « validation + progression + écriture attendue ».
- **Catalogue** : la clé d'estimation (JSON de la prescription et des résultats) était reconstruite à chaque lecture ; au-delà de 1 024 WOD (dès 25 WOD perso), le cache évinçait chaque entrée avant sa réutilisation. Les tuiles, filtres et tris par durée en profitent ; les scénarios d'écran du catalogue restent « gain non démontré » (le coût dominant y est la construction de l'écran).
- **Sauvegarde** : l'écart est net quand le journal est petit (neuf, régulier), où la comparaison des 1 000 WOD dominait. Avec un long historique, l'encodage du journal et la compression dominent : gain non démontré.

## 6. Mesures dans l'application (émulateur, niveau 3)

**Non exécutée.** Le banc dans l'application est livré (`tools/perf_device/`) et compile : en CI, les APK **profile x86_64** de l'application (base et candidate) et les APK du banc (point d'entrée `integration_test`) ont été construits, et l'analyse du banc ne signale aucun problème. L'écart de verrouillage de la copie temporaire se limite à des **ajouts** (`integration_test`, `flutter_driver`, `fuchsia_remote_debug_protocol`, `process`, `sync_http`, `webdriver`) ; aucune version existante n'est modifiée, et le projet livré n'a pas ces dépendances.

L'émulateur n'a pas démarré (« Timeout waiting for emulator to boot »), deux tentatives :

| Tentative | Image | Délai de démarrage | Run |
| --- | --- | --- | --- |
| DEV1 | API 34, google_apis, x86_64 | 600 s | claude-device n° 1 (id 36257819565), commit `c13df85` |
| DEV2 | API 30, default, x86_64, 2 cœurs, 3 072 Mo | 1 500 s | claude-device n° 2 (id 36259506410), commit `c09f14c` |

Cause probable, **non vérifiée** : pas d'accélération matérielle utilisable sur les runners 2 vCPU de ce dépôt privé. Aucune durée d'émulateur n'est rapportée. Même réussie, cette mesure serait restée « non représentative d'un téléphone » : Flutter désactive le mode profile sur émulateur pour cette raison ([Build modes](https://docs.flutter.dev/testing/build-modes)) ; le banc le contourne en lançant directement l'APK, ce qui ne change rien à cette réserve.

Lancement du processus (`am start -W`) et mémoire du processus (`dumpsys meminfo`) : **non mesurés**, pour la même raison. Traces : `validation/3.0.3/emulateur/`.

## 7. Taille

Livrables comparés deux à deux, construits dans les mêmes conditions.

| Livrable | Base 3.0.2 | Candidate 3.0.3 | Conditions |
| --- | --- | --- | --- |
| ZIP source | 1 741 593 octets, 377 fichiers | Voir `LIVRAISON_L6.md` (le ZIP ne peut pas contenir sa propre empreinte) | `tools/package_release.py` |
| APK profile x86_64 de l'application | 20 719 036 octets | 20 724 714 octets (+5 678, +0,03 %) | Même job CI (DEV2), même SDK, même commande `flutter build apk --profile --target-platform android-x64` |
| APK universel release signé (3 ABI) et AAB | 27 630 559 et 28 301 410 octets (run n° 83) | Voir `LIVRAISON_L6.md` (build signé après publication) | `build-apk.yml` inchangé |

Les optimisations L6 ne visent pas la taille. La taille téléchargée depuis Google Play n'est pas déduite de l'AAB.

## 8. Protocole sur téléphone (niveau 4, non exécuté)

À faire avec un ordinateur, Flutter 3.29.3, Android SDK et un **téléphone de test** (pas ton téléphone principal : le banc installe un APK de test à la place de l'application).

1. Débogage USB activé, `adb devices` liste le téléphone ; noter modèle, Android, fréquence d'écran (`adb shell dumpsys display | grep -i refresh`).
2. Téléphone branché, écran allumé, luminosité fixe, mode avion, batterie > 50 %, 5 min de repos.
3. Base puis candidate, trois manches alternées :
   `MODE=drive tools/perf_device/run_device_bench.sh <arbre> base-r1 perf-telephone <id>` (ou `MODE=apk ABI=android-arm64`).
   Le script copie le projet, ajoute `integration_test`/`flutter_driver` dans la copie seulement, lance `flutter drive --profile --no-dds` et écrit `<libellé>.json` : Stopwatch et résumés `FrameTiming` (`watchPerformance` : durées de construction et de rastérisation, images hors budget).
4. Lancement du processus (appareil de test seulement, efface les données de l'application) : `tools/perf_device/cold_start.sh app-profile.apk base-r1 perf-telephone 10 <id>`.
5. Comparer les fichiers base / candidate aux mêmes conditions ; ne conclure qu'avec la règle du §3.

Une mesure de batterie exigerait un protocole dédié (Batterystats / Battery Historian sur une session réelle et répétée) : non préparé ici.

## 9. Sources vérifiées (consultées le 26/09/2026)

- Flutter, *Build modes* — le mode profile est désactivé sur émulateur, non représentatif : https://docs.flutter.dev/testing/build-modes
- Flutter, *Flutter performance profiling* — profil sur appareil physique, JIT/AOT, budget d'image : https://docs.flutter.dev/perf/ui-performance
- Flutter, *Measure performance with an integration test* — `traceAction`/`watchPerformance`, `integrationDriver`, `flutter drive --profile`, `--no-dds` : https://docs.flutter.dev/cookbook/testing/integration/profiling
- Flutter API, `TickerMode.getNotifier` — écoute sans dépendance : https://api.flutter.dev/flutter/widgets/TickerMode/getNotifier.html
- Android, *App startup time* — démarrage à froid/tiède/chaud, `am start -W`, TTID : https://developer.android.com/topic/performance/vitals/launch-time

Les API utilisées existent dans Flutter 3.29.3 (version verrouillée) : le code compile, s'analyse et passe les tests avec ce SDK en CI.
