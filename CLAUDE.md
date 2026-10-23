# Kalis Track — consignes pour Claude Code

Application Flutter (Android) de suivi d'entraînement street workout /
streetlifting du propriétaire (Gaël). Toutes les réponses, commits, docs et
textes de l'app sont **en français**.

## Organisation du dépôt

- `lib/` : application (magasin `store.dart` et ses `part`, écrans, Koach).
- `packages/` : moteurs indépendants — `kalis_core` (contrats, catalogue),
  `kalis_plan` (création de programme), `kalis_adapt` (séance du jour,
  Koach), `kalis_koach` (mascotte 2D).
- `assets/programme_v33.json.gz` : programme 40 semaines d'origine.
  `assets/koach_program.json.gz` : annotations Koach de ce programme.
- `tools/` : scripts Python (contrôles, tests `tools/tests`).
- `.github/workflows/build-apk.yml` : build signé APK + AAB (artefact
  `kalis-track-apk`).
- `SUIVI_PROJET.md`, `AUDIT_*.md`, `docs/` : suivi et décisions.

## Captures d'écran (sans SDK local)

Push sur une branche `claude/shots-*` → workflow « Captures d'écran »
(`.github/workflows/captures.yml`) : lance les tests listés dans
`tools/shots.txt` avec `--dart-define=KALIS_CAPTURE=true` et pousse les PNG
dans `shots/` sur la même branche (récupérer avec `git archive`). Ne jamais
fusionner `shots/` dans `main`. Formatage à distance : branche
`claude/fmt-*` (`format.yml`).

## Outils

Flutter **3.47.5 stable**, Java 17, Python 3. Commandes de contrôle (les mêmes
que la CI, à lancer avant tout push) :

```
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
python -m unittest discover -s tools/tests
```

Les tests se lancent avec le fuseau `Europe/Paris` (variable `TZ` en CI).

Ressources chiffrées (`assets_secure/`) : `python tools/secure_assets.py
decrypt` avec la variable d'environnement `KT_ASSETS_KEY`. Ne jamais
committer les fichiers déchiffrés.

## Règles qui ne se discutent pas

- **Signature** : ne jamais régénérer `signing/kalis_track.p12` ni la clé des
  secrets GitHub ; sinon l'APK ne s'installe plus par-dessus l'app existante.
- **Version** : `pubspec.yaml` (`X.Y.Z+N`) et `kVersion` de
  `lib/settings_screen.dart` changent ensemble, avec les tests qui la
  vérifient (`test/g2_*`, `test/g3_mode_dev_test.dart`,
  `test/ks1a_types_test.dart`, `test/km3_koach_test.dart`,
  `tools/tests/test_g2_retrait.py`). L'APK s'appelle `devX.Y.Z`.
- **Livraison** : push sur `main` → workflow « Build APK et AAB » → vérifier
  que le run est vert → donner le lien du run et de l'artefact APK.
- **Données** : tests avec des données synthétiques uniquement, jamais la
  sauvegarde réelle du propriétaire.
- Les sauvegardes de l'app sont du JSON (ou `gz:` + base64). Le programme
  personnel du propriétaire passe par la section `programInstance`
  (`kind: generated`, semaines au schéma `programme_v33`). Son
  `summary.firstShownWeek` (PR2) masque les semaines d'avant : elles restent
  au journal et pour Koach, la numérotation affichée repart de S1
  (`Program.weekLabel`, `shownWeeks`, `shownNumber`).

## Façon de travailler (préférences du propriétaire)

- Pipelines : ne pas demander d'autorisation ni de validation à chaque étape ;
  décider, enchaîner, informer aux points d'avancement avec les liens
  (runs GitHub, APK).
- Petites mises à jour : un seul passage, build rapide, pas de travail
  inutile.
- Code de qualité production, complet, testé ; garder le style du dépôt
  (commentaires en français, identifiants de lots en tête des blocs).

## Protocoles reconnus dans le texte des séries (programme)

- `8×3` séries classiques · `1×15 puis 4×(4)` myo-reps ·
  `6×3 en clusters (30 s intra)` clusters.
- `8×3 · E2MOM`, `6×2 · E90s`, `12×6 · EMOM` : départ chronométré, une ligne
  par série (PR1). Une ligne dont le nom contient « enchaîné » rejoint le
  groupe de la ligne précédente. Une page de plusieurs exercices enchaînés
  tient dans une seule carte (PR4) : l'en-tête compact du groupe (« E2MOM
  16 min · départ toutes les 2 min », chrono, tours), la prescription de
  chaque exercice (« A · NOM »), puis les séries tour par tour (A·1, B·1,
  espace, A·2…). Des exercices au même départ chronométré n'ont qu'un
  chrono et un libellé de format (« E2MOM · départ toutes les 2 min »,
  PR6). Une ligne au départ chronométré à reps fixes est servie telle
  qu'écrite (PR8, `asWritten` de l'import) : charge et reps du programme,
  Koach la journalise sans la recalculer. Un départ raté se note en
  laissant sa ligne non validée, dit sous l'en-tête (RV1). (Les annotations Koach du
  programme ne décident pas du service : l'import passe par le catalogue.)
- Carte d'exercice compacte en séance (PR7) : une seule carte par page,
  en-tête du groupe ou du départ chronométré dedans (« E2MOM · 8 tours ·
  16 min », Lancer ; tours comptés sur les séries validées, jamais
  saisis) ; titre, charge, volume, cible ; rôle, repères, consigne du
  coach et notes de Koach dans la feuille ⓘ ; séance précédente, note et
  colonnes dans le menu ⋯ ; nombre de séries fixé par le programme.
- Notation (PR5) : une série validée montre sa flamme à la place de la
  coche ; un appui ouvre le curseur en popup (note validée au lâcher), un
  appui long annule la validation. En lecture, séries résumées en une ligne.
- `EMOM 12 min × 18 reps par minute` : une ligne par minute, départ toutes
  les 60 s, servie telle qu'écrite (KB4, comme `12×6 · EMOM`) ·
  `EMOM 20 min · 10 reps, +1 rep/min jusqu'à l'échec` (EMOM montant, PR1,
  une ligne).
- `1×max puis 2×max (15 s intra) · rest-pause` (PR1).
- `2 tours × 4 paliers` : drop set mécanique, une ligne par palier (PR1).
- `8× (30 s effort / 30 s repos)` intervalles : une ligne par tour (effort
  pré-rempli, ni repos ni chrono de tenue par ligne, chrono des tours),
  servie telle qu'écrite, Koach actif comme arrêté (RV1) · `3×30 s` tenues ·
  `10 min` durée · `1 × maximum` test · `Montée en singles puis 3
  tentatives` test de 1RM.
- Groupes servis par Koach (KB5, Koach 1.0.8) : les `GroupSpec` écrits
  passent à `plan(seance)`, tours et durée d'un EMOM au temps suivent les
  lignes servies (`groups` de la sortie ; une ligne remplacée par
  l'application fait recaler son groupe par `groupesServis`).
