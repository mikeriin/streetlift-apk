# Livraison BV11 — base d'exercices v1.1 dans l'application (dev6.19.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé par le pilotage le 15/10/2026 vers 19:08 UTC (DECISIONS_CP.md C12.1, C17.9, C17.10). Délégation (C8) : validation par le pilotage. Consigne : au plus pragmatique (C15.7).

- **Base** : `main` 6e32cdf6 (dev6.18.0). **Livré** : dev6.19.0 (6.19.0+128) sur `main` 72596f38, build signé run 38816375578, contrôle complet `claude/ci-3d` run 38810176268 (arbre eb6cfdfc identique à `main`).
- **Paquets inchangés** (`kalis_core` 0.4.3, `kalis_plan` / `kalis_adapt` 0.3.1) ; rien dans `packages/` ni `tools/catalog/` (KS1 et KM1c3 tournent sur `moteurs`). Aucun changement de moteur ni de comportement C15 ; aucun écran refait (composants du kit seulement).
- **Programme de 40 semaines (C11.2)** : aucune séance faite réécrite, sauvegarde d'origine intacte ; chaque ligne reliée à son id v1.1 à la lecture, contenu inchangé.

## 1. État de départ (constat)

Le lot G3 (dev6.2.0) avait déjà basculé l'essentiel sur la base v1.1 : Arsenal, recherche, filtres (discipline, type de mouvement, niveau, lieu, matériel, difficulté), fiches (points clés, erreurs « erreur → conséquence », respiration, muscles principaux / secondaires / stabilisateurs / étirés, matériel, variantes par `variante_de`, paliers), ajout d'exercice (plan), remplacements (moteurs, ids v1.1), résolution des noms enregistrés par `correspondance.json`. Le pack 2.0.0 restait pourtant **embarqué et lu au démarrage**, et six fichiers d'assets restaient déclarés.

## 2. Inventaire des lectures du pack 2.0.0 et des anciens noms / ids (avant BV11)

| Endroit | Ce qui lisait le pack ou un ancien nom / id | Traitement BV11 |
| --- | --- | --- |
| `lib/store.dart` (`init`) | `assets/content/index.json.gz` lu à chaque lancement : `LegacyPackIndex` (jamais lu ensuite, code mort) et `dbExercises` (625 × `n`, `g`, `eq`, `id`) | Pack retiré. `dbExercises` lu dans `assets/catalog/groupes_historiques.json` : copie figée du seul champ `g` (nom → groupes), contrôlée égale au pack (test Python et Dart) |
| `AppStore.groupsFor` → STATS (séries par groupe, carte), carte « séance du jour », repli de la carte ciblée | Groupes `g` des anciens noms, puis mots-clés, puis muscles principaux v1.1 | Inchangé (même table, même ordre) : statistiques identiques |
| `lib/exercise_screens.dart` (`MentionsScreen`) | `assets/content/licences.md` | `assets/legal/licences.md`, réécrit pour la base v1.1 (sources de l'ancien pack résumées, détail dans l'archive) |
| `pubspec.yaml` | `index`, `details`, `sources`, `poses`, `progressions`, `licences` (`details`, `sources`, `poses`, `progressions` jamais lus par l'application) | Retirés ; `groupes_historiques.json` et `assets/legal/licences.md` déclarés |
| `lib/pose_engine.dart`, `pose_painter.dart`, `pose_cutout.dart` | Démonstrations 2D du pack (`PoseAnimation.fromPack`, 18 réglages par ancien id) ; plus affichées depuis M8 (aucun écran ne les utilisait) | Retirées ; `dashPath` (seul usage, carte de l'atlas) déplacé dans `lib/atlas.dart` |
| `lib/content_pack.dart` | `LegacyPackIndex`, `toLegacy()`, `entryFor()` (sans appelant) | Retirés |
| `lib/athlete_profile_store.dart` | `athleteDislikedLegacyIds` (ids de l'ancien pack, sans appelant depuis G10) | Retiré |
| `lib/legacy_pack.dart` | Vocabulaires du pack (matériel, familles, zones), `genHash`, `lowerMedian` (sans appelant) | Retirés ; reste la lecture stricte d'une ancienne instance L10 (`GenInputs`, lieux) |
| `ClipRegistry.legacyIds` (`lib/mannequin_clip.dart`) | Animations enregistrées sous un ancien id → id v1.1 | Gardé (lit `correspondance.json`, pas le pack) |
| `ContentIndex.idFor` | Ancien nom exact, nom sans précision, nom / alias normalisé, id v1.1, ancien id (`correspondance.json`) | Gardé : c'est la migration (ids stables, rien réécrit) |
| Séance (fiche, conseils), journal des moteurs (`convertLegacyJournal`), programme de 40 semaines (`_adaptImportItem`, formats, spéciaux), tests guidés (`exId` d'une instance L10) | `catalogId ?? content.idFor(nom)` | Déjà v1.1 (G3, CI1 à CIF), inchangé |
| Historique, records, meilleures performances, compétences du personnage, estimations | Nom enregistré (texte), jamais résolu | Inchangé : l'ancien nom reste affiché tel quel |
| Recherche Arsenal, bibliothèque, ajout (plan « Ajouter un exercice que tu aimes »), préférences et sélecteur du profil, fiche | `searchExercises` sur la base v1.1 | Déjà v1.1 ; filtres **Catégorie** (56) et **Muscle principal** (54 utilisés sur 56) ajoutés |
| Remplacement d'exercice | Moteurs seulement (`kalis_plan` « Je ne sais pas faire », échanges `kalis_adapt`), ids v1.1 ; pas de remplacement manuel en séance | Inchangé |
| Koach (`lib/koach/`, `koach_data.dart`) | Aucune résolution d'exercice (texte opaque) | Inchangé |
| Sauvegardes et exports | Noms enregistrés ; `userExercises` (`n`, `g`, `eq`) | Format inchangé : une ancienne sauvegarde reste importable (test) |
| Animations M8 | `assets/anatomy/clips/index.json` : un seul clip, de test (`debug_squat`, sans exercice) ; aucune animation d'exercice n'a été livrée (prompt M10 non exécuté) | Rien à perdre ; le rattachement par ancien id via `correspondance.json` reste en place pour de futurs clips |
| Outils Python | `verify_project.py`, `content_pack_import.py`, `content_corrections.py`, `correspondance/build_correspondance.py`, `anatomy/import_animations.py`, tests | Repointés vers l'archive `tools/archives/pack_2.0.0/` (git mv, hors de l'APK) ; `verify_project.py` contrôle désormais la base v1.1 (1 039), la correspondance, les groupes historiques (625) et l'absence du pack |

## 3. Exercices sans correspondance

Aucun ne disparaît : un nom sans id v1.1 reste affiché tel quel, compté dans l'historique et les records, ses groupes historiques gardés.

- **Programme de 40 semaines** : 1 812 lignes, 1 806 reliées ; seule « BILAN — report des résultats » (bilan de phase, pas un exercice) reste sans id.
- **Journal S1 à S14** (test) : tous les noms reliés sauf le bilan.
- **Anciens exercices du pack sans équivalent** (relus en G3, `docs/G3_CORRESPONDANCE.md`) : Around the world (suspendu), Bilan, Contraste français, Kettlebell clean & press, Rice bucket (seau de riz), Tirage isométrique à la serviette, Rowing à la serviette à une main (porte), Planche superman (tenue), Planche avec passage d'objet sous le corps, Planche à un bras. Les cinq premiers sont des noms de la base v1 de l'application ; aucun n'est dans le programme de 40 semaines.
- Exercices personnels (`userExercises`) : jamais reliés, gardés avec leurs groupes.

## 4. Tests

- `test/bv11_base_test.dart` (7 tests) : plus aucune lecture de `assets/content` ; groupes historiques = champ `g` du pack (625) et `groupsFor` identique ; **migration** : sauvegarde du propriétaire (programme commencé le 13/07/2026, S1 à S14, format de dev6.18.0) importée puis relue par un nouveau magasin : mêmes séances, séries validées, records par séance, meilleures performances et séries par groupe de S1 à S14, journal et départ exportés identiques, sauvegarde d'origine identique, ids v1.1 (relevés `BV11|journal|…`, `BV11|programme|…`) ; **ancienne sauvegarde** (exercice personnel, nom du pack, ancien id) importée sans perte ; filtres catégorie et muscle principal ; bibliothèque → filtres → fiche en **sombre et clair**.
- `test/l9b_content_test.dart` adapté (table nom → groupes ; doublons v1 lus dans l'archive ; menu Filtres à 8 catégories). Le test de régression chiffré `test/g3_historique_test.dart` (relevé d'avant G3) reste vert sans changement.
- Retirés avec leur code (démonstrations 2D du pack, jamais affichées) : `test/l9b_pose_test.dart`, `test/refonte_ma_capture_test.dart`, groupe « démonstrations découpées » de `test/refonte_ma_test.dart`, mesure des démonstrations de `test/l9b_perf_test.dart`. Aucun autre test sauté ni désactivé.
- Cible émulateur `integration_test/base_bv11_test.dart` (build de développement ; a sombre rouge, b clair violet) : session **perso** avec le journal jusqu'à la veille, relevé identique au lancement, sauvegarde d'origine, STATS, historique S1·J1 (ancien nom lisible), bibliothèque (filtres Catégorie « Tirage vertical » et Muscle principal « grand dorsal », fiche) ; session **dev** (5 appuis sur le logo) : même parcours ; session perso intacte. Relevés : 68 noms au journal, seul le bilan sans id ; relevé du journal identique ; catégorie « Tirage vertical » 56 exercices, avec « grand dorsal » 56 ; fiche « Chin-up lesté » ; historique S1·J1 lisible (« TEST 1RM MUSCLE-UP LESTÉ ») ; perso intacte après la session de test.
- Versions : tests `g2_mode_dev`, `g3_mode_dev`, `g2_retrait`, `test_g2_retrait.py` à 6.19.0.

## 5. Contrôles

- Mise au point : `claude/ci-ui-bv11-rapide` (formatage, analyse, `test/bv11_*`), 3 essais : 1er rouge (apostrophe dans trois titres de tests de version, import inutile, formatage), puis verts (7 tests).
- Contrôle complet `claude/ci-3d` : essai 1 (run 38796267986) vert sauf l'émulateur : la cible BV11 cherchait l'onglet STATS par `nav-1` alors que l'invitation au profil v3 couvrait l'accueil (profil non semé) ; trois cibles anciennes (CI1f, CI1e, CI1c) perdues par l'émulateur (service VM disparu, connexion refusée), passées à l'essai suivant. Essai 2 annulé (suivi du projet ajouté à l'arbre). **Essai 3 (run 38810176268) entièrement vert** : formatage, analyse, 1 044 tests Dart (51 ignorés, comme avant), tests du mode dev, Python et intégrité (`verify_project.py` sur la base v1.1), paquets, rendus de test, builds debug et profile, cibles émulateur BV11, CIF, CI1g, CI1f, CI1e, CI1c et CI1 (sombre et clair). Arbre eb6cfdfc identique à `main` 72596f38.
- Build signé APK + AAB : run 38816375578 (sur `main`).
- Relecture indépendante (sous-agent Opus) : aucun défaut bloquant ; équivalence de `groupsFor` vérifiée (table égale au pack, même ordre, noms uniques) ; réserves reprises en limites (§ 6).
- Captures regardées (sombre et clair, perso et dev) : menu Filtres (muscles principaux), liste filtrée (puces « Tirage vertical », « Grand dorsal »), fiche, STATS, historique.

## 6. Limites et suites

- `assets/muscles/anim/` (calques des démonstrations découpées, 656 Ko) reste déclaré dans `pubspec.yaml` alors que son seul lecteur est retiré : à retirer dans un lot UI (les fichiers servent encore à `tools/anim_cutout.py` et à ses tests).
- Le format des sauvegardes garde `userExercises` (`n`, `g`, `eq`) : aucun écran ne crée plus d'exercice personnel depuis G2 ; les anciens restent lus.
- La respiration de la base v1.1 est un texte unique par exercice (les phases y sont décrites) : affichée telle quelle, aucune règle du catalogue à corriger relevée.
- Le workflow `ci-ui.yml` (refonte UI) joue aussi `tools/ci3d_drive.sh` avec un délai de 80 min : à relever s'il resert (non utilisé par ce lot).

## 7. À tester (propriétaire)

1. Installer dev6.19.0 par-dessus dev6.18.0 : historique, records et STATS comme avant ; une ancienne séance montre les noms d'origine.
2. Arsenal › Exercices › Filtres : « Catégorie » et « Muscle principal », puis une fiche.
3. Réglages › À propos › Sources et licences : texte de la base v1.1.
