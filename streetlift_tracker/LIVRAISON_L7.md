# Kalis Track 3.0.0 — Livraison L7 (Koach)

**26 septembre 2026, Europe/Paris — version 3.0.0+61 (versionCode réel fixé par le build).**
Lot L7 : Koach, moteur d'autorégulation local (KT-024 à KT-036), selon tes décisions D1-D37 du 26/09/2026. Détail : `docs/CONTRAT_L7.md`, `SUIVI_PROJET.md` (L7), `docs/CONFIDENTIALITE_KOACH.md`.

## 1. Publication et build signé

| Élément | Valeur |
| --- | --- |
| Archive | `streetlift_tracker_v33.zip`, racine `streetlift_tracker/`, {ZIP_SIZE} octets, SHA-256 `{ZIP_SHA}` ; contrôle `tools/package_release.py --check` : {ZIP_CHECK} |
| Dépôt | `mikeriin/streetlift-apk`, branche `main`, commit `{MAIN_COMMIT}` (seule l'archive change ; `.github/workflows/build-apk.yml` inchangé, identique à la copie du projet) |
| Build signé | {RUN_LINE} |
| Étapes | {RUN_STEPS} |
| Artefacts | {RUN_ARTIFACTS} |
| Manifeste final (APK signé) | {RUN_MANIFEST} |

## 2. Installation (mise à jour par-dessus 2.5.x)

1. **Avant d'installer** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier à garder hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du build ci-dessus, vérifier l'empreinte (`kalis-track.apk.sha256`), installer **par-dessus** la version actuelle, **sans désinstaller** (même identifiant, même signature).
3. Au premier lancement : tes séances, références, crédits, WODs et réglages sont là ; **Koach est désactivé** ; les charges, séries et séances sont ceux de 2.5.9 (seules s'ajoutent la section Réglages → Koach et la mention de Koach dans les textes de sauvegarde).

En cas de problème : ne pas désinstaller ; réinstaller le build 2.5.9 (run n° 79) n'est pas prévu par Android (rétrogradation refusée) — garder le fichier d'export et me transmettre le problème.

## 3. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

| # | Action | Attendu |
| --- | --- | --- |
| 1 | Ouvrir l'application après la mise à jour | Données intactes ; Réglages → Koach : « Désactivé » ; aucune carte Koach en séance |
| 2 | Ouvrir une séance du programme, Koach désactivé | Charges et séries identiques à 2.5.9 ; aucune difficulté demandée |
| 3 | Réglages → Koach → activer | Explication, puis « Activer Koach » ; STATS › Performances : tuile « Koach » |
| 4 | Séance avec un mouvement principal : valider la série 1 | Fiche de six boutons (libellé + « encore N ») ; un tap valide ; ligne « Dur · encore 2 » sous la série |
| 5 | Série 1 notée plus facile que le RIR visé | Carte Koach : « X kg au lieu de Y kg » + raison ; « Appliquer » remplit les séries restantes ; « Garder ma charge » : plus reproposé dans la séance |
| 6 | Appui long sur le numéro d'une série validée | Même fiche, « Série écartée (incident) » ; la série reste validée |
| 7 | Terminer la séance | Bilan Koach (si propositions ou questionnaires), puis bilan de récompenses ; « Accepter » change la valeur de pilotage (Références), « Refuser » non |
| 8 | Réglages → Koach → Questionnaires | Information préalable, puis activation ; avant la série 1 : sommeil et forme (« Passer » possible) ; au bilan : douleur ; au-dessus de 3/10 : rappel « professionnel de santé », aucune hausse à la séance suivante |
| 9 | Sommeil « moins de 5 h » | Carte « jour de fatigue probable » : « Retirer N séries non validées (−30 % de volume) » ou continuer |
| 9 bis | Deux douleurs > 3/10 de suite sur un mouvement, accepter l'allègement | Carte de l'exercice : « allègement en cours » et « Lever » ; écran Koach : « Allègements en cours » |
| 10 | STATS › Performances → Koach | 1RM estimés avec incertitude, courbe, statut des objectifs en texte, historique daté, pesées ; « Garder ma valeur » |
| 11 | Pesées ; accueil 7 jours après la dernière pesée | Rappel « Pesée de la semaine » ; la pesée la plus récente devient le poids du corps |
| 12 | Réglages → Koach → Matériel | Incréments modifiables ; poulies en livres ; les charges suivent la grille |
| 13 | Exporter, puis importer ce fichier | Aperçu « Koach : activé · N pesée(s) · N séance(s) avec questionnaire » ; données identiques |
| 14 | Désactiver Koach | Retour au comportement 2.5.9 ; données Koach conservées |
| 15 | Texte agrandi à 200 %, TalkBack | Cartes et fiche lisibles, états annoncés en toutes lettres |

## 4. Tes valeurs à saisir (D1 : rien n'est codé en dur)

Réglages → Koach → Objectifs → « Objectif final », date **31/12/2027** :

| Référence | Cible |
| --- | --- |
| Traction lestée (1RM) | +75 kg |
| Dip lesté (1RM) | +100 kg |
| Muscle-up lesté (1RM) | +25 kg |
| Back squat (1RM) | 150 kg |
| Muscle-ups (max) | 20 reps |
| Tractions (max) | 50 reps |
| Dips (max) | 110 reps |
| Pompes (max) | 100 reps |
| Squat 70 kg (max) | 45 reps |

L'étape (cible 12 mois du programme, 12 mois après ton départ) est remplie par défaut et modifiable. Tes incréments de matériel (D23 : haltères 1 kg jusqu'à 10 kg puis 2 kg ; lest 1,25 kg ; barre 2,5 kg ; poulies 2,5 lb) sont les valeurs par défaut ; « machines guidées » 2,5 kg est un choix à confirmer.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| **Corrigé dans le code** | KT-024 à KT-036 (D1-D37) |
| **Testé automatiquement** | CI sans secret : analyse, suite complète, build debug (`SUIVI_PROJET.md` L7.3) ; build signé (§1) |
| **Vérifié sur appareil** | Rien |
| **Reste à valider** | §3 sur téléphone ; paramètres du modèle par un préparateur physique compétent (`docs/CONTRAT_L7.md` §11) ; qualification juridique des questionnaires et du poids (`docs/CONFIDENTIALITE_KOACH.md` §6) ; tes objectifs finaux (§4) |

## 6. Fichiers

Nouveaux : `lib/koach_engine.dart`, `lib/koach_data.dart`, `lib/koach_program.dart`, `lib/koach_store.dart`, `lib/koach_widgets.dart`, `lib/koach_screens.dart`, `assets/koach_program.json.gz`, `tools/koach_reference.py`, `tools/koach_simulation.py`, `tools/koach_annotate.py`, `tools/tests/test_koach_reference.py`, `test/l7_koach_engine_test.dart`, `test/l7_koach_simulation_test.dart`, `test/l7_koach_store_test.dart`, `test/l7_koach_off_test.dart`, `test/l7_koach_screens_test.dart`, `test/fixtures/koach/*.json` (26), `test/fixtures/l7_2x_snapshot.json.gz`, `docs/CONTRAT_L7.md`, `docs/CONFIDENTIALITE_KOACH.md`, `LIVRAISON_L7.md`.

Modifiés : `lib/store.dart`, `lib/session_screen.dart`, `lib/settings_screen.dart`, `lib/stats_performance.dart`, `lib/home_screen.dart`, `lib/data_control.dart`, `pubspec.yaml`, `README.md`, `SUIVI_PROJET.md`.

Inchangés : `.github/workflows/build-apk.yml` (identique à `main`), identifiant Android, chaîne de signature, dépendances, tests existants.
