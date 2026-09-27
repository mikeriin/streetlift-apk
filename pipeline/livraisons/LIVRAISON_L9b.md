# Livraison L9b — Kalis Track 3.2.0 (base d'exercices v2, démonstrations animées, fiches)

**27 septembre 2026 — lot exécuté par le pipeline automatisé.** Tickets KT-079, KT-080, KT-082 (KT-081 réservé : illustrations de scène reportées).

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 3.1.0+65 (L8), `main` `620752e`, SHA-256 `517f28af…1be5c0` |
| Pack intégré | `kalis_content_pack_v1_final.zip` (branche `content-pack`, `93fad2e`), SHA-256 `5a13a91e3171c303391e00123c24f5cb8e2577e775e4f4be60622351108f9086`, pack 2.0.0 validé le 27/09/2026 |
| ZIP publié | `streetlift_tracker_v33.zip`, 2 031 485 octets, 455 fichiers (5 219 303 octets extraits), SHA-256 `699329b4824b2ceef27355c85a7310de73ec00c6a97d1984c031bed20f578f14`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` |
| Commit `main` | `6015ebc` (le commit précédent `93963d8`, run n° 86, avait un ZIP incomplet — `gradlew` et le wrapper Gradle omis lors de la copie — et s'est arrêté à l'extraction ; contenu applicatif identique) |
| Build signé | Run **n° 87** (id 36305122138) **réussi** le 27/09/2026 08:05-08:20 UTC : contrôle du ZIP et du workflow, formatage, analyse, tests Dart et Python, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés avec le même numéro, artefacts vérifiés. Artefacts : `kalis-track-apk` (28 251 349 octets), `kalis-track-aab` (28 931 250), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36305122138 |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- **Arsenal → Exercices** : 625 exercices, recherche (nom, muscle, matériel, lieu, type) et filtres (type de mouvement, lieu, matériel, difficulté).
- **Fiche exercice** : démonstration animée colorée selon ta couleur dominante (bouton pause), points clés, erreurs fréquentes, respiration, atlas des muscles (principaux pleins, secondaires atténués, stabilisateurs en contour) avec la liste en texte, précautions, prérequis, progressions et régressions sur lesquelles tu peux taper. 34 gestes hors du plan montrent la position de départ ; 18 exercices sans démonstration fidèle montrent l'atlas et les consignes.
- **« Réduire les animations »** (réglage Android) : images clés fixes, numérotées.
- **STATS** : la carte musculaire est redessinée avec l'atlas (51 muscles, face et dos) ; mêmes données, mêmes 11 groupes, même échelle de couleurs.
- **Nouvelle séance** : les 120 nouveaux exercices sont proposés, la recherche porte sur les nouveaux champs, et un bouton ⓘ ouvre la fiche.
- **Tes séances, ton historique, tes records et tes WOD ne changent pas** : aucun nom enregistré n'est réécrit ; ils sont reliés à la nouvelle base à la lecture (vérifié sur un historique complet de 40 semaines + 60 séances personnelles).
- Réglages → À propos → **Sources et licences**.

## 3. Installation (point d'installation conseillé)

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du run ci-dessus ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir l'application : aucun écran nouveau au démarrage.

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Après mise à jour : accueil, semaine en cours, historique, records, séances personnelles et WOD identiques à 3.1.0.
2. STATS : la carte musculaire s'affiche (face et dos) et les groupes les plus travaillés sont les mêmes qu'avant.
3. Arsenal → Exercices : chercher « traction », filtrer « Parc de street workout » puis « Avancé (7 à 10) » ; ouvrir une fiche.
4. Fiche : l'animation est fluide (pas de saccade visible) ; « Mettre en pause » l'arrête ; taper une progression ouvre sa fiche.
5. Changer la couleur dominante (Réglages) puis rouvrir une fiche : muscles et atlas prennent la nouvelle teinte, en clair et en sombre.
6. Activer « Supprimer les animations » d'Android : la fiche montre les images clés fixes.
7. Nouvelle séance → ajouter un exercice : les nouveaux exercices apparaissent, ⓘ ouvre la fiche ; une séance personnelle existante s'ouvre et se lance comme avant.
8. Grand texte (200 %) et TalkBack sur la bibliothèque et une fiche.
9. Réglages → À propos → Sources et licences.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-079, KT-080, KT-082 ; écran de mentions |
| Testé automatiquement | CI `claude/ci-tools` commit `9328da8` : format 0 changement, analyse sans problème, **630 réussis / 12 ignorés** (32 nouveaux, 598 existants inchangés), Python 69/69, `verify_project.py` ; build debug ; concordance du rendu (246 gabarits ; 20 exercices × 5 instants, écart < 1e-9) ; recoloration 6 palettes × 2 modes ; puis rejoués par le run 87 |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; images par seconde en mode profile et mémoire sur téléphone ; registre `docs/CONTRAT_L9b.md` §5 et `validation_register.md` du pack (contenu non relu par un professionnel diplômé) |

## 6. Décisions prises par défaut

Voir `docs/CONTRAT_L9b.md` §4 (D-L9b-01 à D-L9b-09). Les plus visibles : noms enregistrés conservés et reliés à la lecture (aucune migration de données) ; atlas embarqué en code (aucune dépendance ajoutée) ; les 22 doublons de l'ancienne base ne sont pas listés dans la bibliothèque ; pas encore de bouton « fiche » dans l'écran de séance du programme (à décider avec L10).

## 7. Fichiers modifiés

Nouveaux : `lib/atlas.dart`, `lib/atlas_data.dart` (généré), `lib/content_pack.dart`, `lib/exercise_screens.dart`, `lib/pose_engine.dart`, `lib/pose_painter.dart`, `assets/content/` (`index`, `details`, `sources`, `poses`, `progressions` en `.json.gz`, `licences.md`, `pack.json`), `tools/content_pack_import.py`, `tools/tests/test_content_pack.py`, `test/l9b_pose_test.dart`, `test/l9b_content_test.dart`, `test/l9b_perf_test.dart`, `test/fixtures/l9b/` (`exercises_db_v1.json.gz`, `keyframe_joints.json.gz`, `pose_parity.json`), `docs/CONTRAT_L9b.md`. Modifiés : `lib/store.dart`, `lib/muscle_body.dart`, `lib/builder_screen.dart`, `lib/arsenal_screen.dart`, `lib/settings_screen.dart`, `pubspec.yaml` (3.2.0+66), `tools/verify_project.py`, `tools/pack_assets.py`, `tools/tests/test_tools.py`, `test/support/capture_support.dart`, `test/visual_capture_test.dart`, `README.md`, `SUIVI_PROJET.md`. Supprimés : `assets/exercises_db.json.gz` (conservé en fixture), `assets/muscles/` (18 fichiers).
