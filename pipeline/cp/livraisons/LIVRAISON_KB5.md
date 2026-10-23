# Livraison KB5 — Koach 1.0.8 et `kalis_plan` 0.4.3 dans l'application (dev7.7.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »). Lancé par le pilotage le 23/10/2026 vers 02:30 UTC (DECISIONS_CP.md C17.48.5) ; session démarrée à 04:36 UTC, statut trouvé « en cours (lancé …) » sans session ni sauvegarde : traité comme le lancement (aucune `cp-sauvegardes/KB5`), ligne passée « en cours depuis 2026-10-23 04:37 UTC ». Délégation (C8) : validation par le pilotage. Outil `add_repo` absent de la session : accès en écriture vérifié par les pushes (`pipeline`, sauvegardes, contrôles).

**Ce lot n'a rien déchiffré, n'a pas lu `cp-references`, n'a reçu aucune clé et n'a manipulé aucune donnée du propriétaire (C17.33.2).** Tous les tests tournent sur des données synthétiques (semaine type `test/fixtures/pr9_semaine.json`, programme embarqué pour l'historique).

- **Base** : `main` ae9d6e1a (dev7.6.0) ; aucune publication du propriétaire pendant le lot.
- **Livré** : dev7.7.0 (7.7.0+152) sur `main` 83a0170e (un commit, avance rapide depuis ae9d6e1a, arbre 31cade4f identique au commit contrôlé 51885773) ; **build signé run 39954106798 vert** (https://github.com/mikeriin/streetlift-apk/actions/runs/39954106798 ; APK : artefact `kalis-track-apk` 12502512401, https://github.com/mikeriin/streetlift-apk/actions/runs/39954106798/artifacts/12502512401 ; AAB 12502029165).
- **Contrôle rapide** `claude/ci-ui-kb5-rapide` : run 39904076619 vert (formatage, analyse, 16 tests KB5 ; verrou respecté). Run 39902923448 (n°1) : 2 tests et un lint corrigés.
- **Contrôle complet `claude/ci-3d`** :
  - run 39919503229 sur l'arbre publié (commit de contrôle 51885773) : contrôles, formatage, analyse, Python, **1 273 tests Dart**, tests du mode dev, paquets, builds debug et profile **verts** ; émulateur : **KB5 a et b verts**, RV2, RV1c1, RV1, KB4, CU, G1 à G10, M7, M8 verts au 1er essai ; perte de la VM de l'émulateur à partir de KB3 b (« No supported devices found ») ; relance des jobs en échec (une fois) : toutes ces cibles vertes sauf KB1 a (« Connection refused » au service de la VM, jamais lancée) et CI1f b (« adb: device offline ») ;
  - run 39905071701 sur le même `lib/` (arbre b619f51c : seule la cible `koach_kb5_test` et un commentaire de `ci3d_drive.sh` diffèrent) : **toutes les cibles vertes dont KB1 a et b et CI1f a et b**, sauf KB5 (assertion de la cible : la raison est dans la feuille ⓘ de la carte compacte PR7, pas sur la carte ; cible corrigée, verte au run 39919503229).
  - Chaque cible est donc verte dans au moins un essai ; KB1 a et CI1f b le sont sur le même `lib/` et les mêmes fichiers de cible, pas sur l'arbre exact publié (règle des lots KB4 et RV2, C17.49.3 : à confirmer par le pilotage).

## 1. Ce qui change pour le propriétaire

- Koach 1.0.8 sert les séances : poulie au pas de 2,5 kg (même sans profil de pas), charges jamais au-dessus d'un plafond, test xRM écrit gardé, groupe et format de l'emplacement gardés pour un exercice remplacé.
- Un enchaînement au chrono (E2MOM, EMOM, intervalles) garde toujours ses tours d'accord avec ses lignes : quand Koach baisse les séries d'un EMOM (bilan bas, douleur), le chrono et le nombre de tours suivent les lignes servies ; les lignes au départ chronométré du programme et les intervalles restent servis tels qu'écrits (C17.44.4).
- Nouvelle phrase quand la modulation de la semaine baisse une ligne sous l'écrit : « Cette semaine, je te propose N séries sur … au lieu des M écrites : je répartis l'effort de la semaine d'après ta récupération prévue. » — en tête de séance et sur la carte de la ligne, toute la séance. Rien n'est retiré (au moins une série) ; sur une ligne au départ chronométré servie telle qu'écrite, la carte dit seulement « Koach aurait fait N séries sur M ».
- Les tractions ne comptent plus comme travail des pectoraux (muscle-up et pull-over haltère pour une demi-série) : volume par groupe de Koach, rapport « séries par groupe » et structure de la semaine des programmes créés.
- Sur le scénario PR2 (lundi de tirage, mardi de poussée) : toutes les lignes servies à leurs séries écrites, aucune raison, aucun retrait (relevé § 4).

## 2. Paquets et empreintes

- `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` copiés à l'octet de `etiquettes/kalis_adapt-v1.0.7` (`moteurs` 25d5bfe6) : 55 fichiers, empreinte `dcf0f322…f9b6` (KB4 : `cebaa39f…`) ; `packages/kalis_plan/` entier copié de `etiquettes/kalis_plan-v0.4.3` (lib + pubspec : 32 fichiers, `0f011641…b258` ; KB4 : `9ce7e5a0…`). Rien d'autre dans `packages/` (`kalis_core` 0.4.4 inchangé).
- Asset `assets/koach/koach_params_1_0_8.json` à la place de `koach_params_1_0_7.json` : `1.0.8-ref.1`, 344 clés, SHA-256 `9d74365e58b84fe0e9db7801dd450c053e4ca870184fca5b480b534b116841d1` (application et paquet) ; fiches `vecteurs_qualites_v1.json` 1.0.1, SHA-256 `99b0cae2d0b29d18d5daa30ee92b91990225124e38e44d522e80e8ae01a196e0` ; déclaration, `kKoachParamsAsset`, tests d'empreinte (`kb5_koach108_test`, `kb1_koach105_test`, `km3_koach_test`, `kb4_koach107_test`).
- `pubspec.lock` : versions des deux paquets de chemin (1.0.7, 0.4.3) ; `flutter pub get --enforce-lockfile` respecté en CI (« verrou=respecte »), aucune autre dépendance changée.

## 3. Intégration

- **Groupes (X2, X7)** — `lib/koach1/koach_groupes.dart` : `koachStartNow` passe les `GroupSpec` de la journée écrite dans `plan({'horizon': 'seance', …, 'groups': […]})` et lit `groups` de la sortie (`koachGroupesDeSortie`). `koachGroupesDeLaSeance` recale chaque groupe par la règle du moteur lui-même (`groupesServis`, exportée par `package:kalis_adapt/koach.dart`, aucune copie à tenir en parité) sur les lignes **réellement servies** : quand le résultat est celui de Koach, c'est le groupe du moteur qui sert ; sinon (ligne au départ chronométré servie telle qu'écrite, intervalles tels qu'écrits, ligne gardée par `koachGardeSeance`, ligne écartée) le groupe recalé sert, identifiant noté dans `groupesRecales` (diagnostic du mode dev). Un groupe sans membre servi n'est plus déclaré (règle de KB3 gardée). La colle de RV1 (intervalles du programme importé servis tels qu'écrits) et celle de RV2 (groupe perdu à l'échange, `exerciseGroupOf`) restent en place, comme filets.
- **Aperçu** (`koachPreview`) : la ligne modulée par la semaine a sa technique recomptée et ses groupes recalés par la même règle (avant : un EMOM modulé gardait `intervals` écrit et rendait l'aperçu invalide).
- **Technique (X3)** : `_koachItemOf` passe l'item servi par `koachTechniqueCoherente` (`techniqueCoherente` du moteur) avant validation, et le repli sur la ligne écrite aussi : sécurité, 1.0.8 rend déjà une technique cohérente (aucun écart vu sur le scénario).
- **Raison `koach.volume_semaine` (X8)** : texte de `koach_textes.dart` 1.0.8 ; ajoutée à `kKoachRaisonsDeSeance` (gardée sur la carte après la première série, quand `plan(serie)` remplace les raisons) ; en tête par `koachSessionReasons` ; jamais un retrait pour `koachGardeSeance` (testé) ; portée par **une ligne** (ses séries écrites `ecrites`) : jamais dite sur une autre ligne du même exercice (tractions en EMOM et en drop set le jeudi) ; sur une ligne au départ chronométré servie telle qu'écrite, pas en tête et la carte dit « Servi tel qu'écrit … Koach aurait fait N séries sur M » (`koachTexteEcartEcrit`). La semaine affichée (MON PROGRAMME, accueil) montre la ligne modulée avec son écrit, inchangé.
- **Crédits « chest »** : rien à coller : `PlanInspector.metrics` (rapport « séries par groupe »), la structure de la semaine et la génération lisent `kalis_plan` 0.4.3 ; Koach lit les fiches 1.0.1 (testé : tractions 0, muscle-up et pull-over haltère 0,5, dips 1).
- **Poulie (X1)** : `LoadGrid.of(cable, null)` vaut 2,5 kg ; la colle `withCableIncrement` de RV1 donne la même valeur (testé) ; extension triceps corde servie à 20 kg (scénario).
- Version 7.7.0+152 (`pubspec.yaml`, `kVersion`, tests de version G2, G3, KS1A, KM3, KB1, Python), `SUIVI_PROJET.md`, `CLAUDE.md` (protocoles : groupes servis par Koach).

## 4. Tests et relevé

- `test/kb5_koach108_test.dart`, 16 tests : empreintes (paramètres, fiches, pubspec, verrou) ; crédits « chest » (`CatalogTraits` de `kalis_plan` et fiches de Koach) ; poulie (X1) ; règles de `groupesServis` (mêmes valeurs que le test du paquet, E2MOM A/B, contre la montre) ; Koach 1.0.8 nu : intervalles recalés (8 → 6 tours au bilan bas), règle de l'application identique ; `koachGroupesDeLaSeance` (ligne remplacée, groupe du moteur, groupe vide) ; technique (EMOM 10 → 9, série de tête, pyramide ; moteur 1.0.8) ; `koach.volume_semaine` (texte, raison de structure, garde) ; scénario PR2 (ci-dessous) ; douleur à l'épaule ; bilan bas mercredi et samedi ; jeudi EMOM ; raison posée (en tête, carte, après la 1re série, ligne PR8) ; poulie servie ; passage depuis dev7.6.0 et export / import à l'identique.
- Tests d'avant mis à jour : empreintes et versions (KB1, KB4, KM3, KS1A, CI1d/f/g, G2, G3, Python).
- **Relevé du scénario** (PR2 synthétique, trois semaines d'historique, Koach 1.0.8) :
  - **J1** (tirage) et **J2** (poussée) servis à toutes leurs séries écrites, aucune raison, aucun retrait, aucune garde ; groupes du moteur tels quels (E2MOM traction + pompes : 960 s, lignes 8 et 8 ; dip + tractions PdC : 960 s, 8 et 8) ; `plan(seance)` 7 à 61 ms (test), 24 ms au plus sur l'émulateur ;
  - **douleur à l'épaule** (mardi) : six lignes retirées par `koach.douleur_retrait`, extension triceps servie à 3 ; groupe E2MOM sans membre, plus déclaré ;
  - **bilan bas** mercredi : intervalles air bike 8 lignes, 8 tours (tels qu'écrits) ; squat E3MOM tel qu'écrit, groupe 1 080 s recalé sur le squat ; samedi : intervalles rameur 6 lignes, 6 tours ;
  - **jeudi** : EMOM muscle-ups 8 lignes (480 s), contraste E2MOM 6 et 6 (720 s), EMOM tractions 10 lignes (600 s) ;
  - **raison posée** : « Cette semaine, je te propose 2 séries sur « Rowing barre buste penché prise pronation » au lieu des 3 écrites … » en tête et sur la carte, gardée après la 1re série ; ligne PR8 (muscle-up lesté) : « Servi tel qu’écrit (départ chronométré du programme). Koach aurait fait 5 séries sur 6 … », pas en tête ;
  - **poulie** : extension triceps corde servie à 20 kg.
- **Cible émulateur** `integration_test/koach_kb5_test.dart` (inscrite dans `tools/ci3d_drive.sh` ; a = sombre, rouge ; b = clair, violet ; build de développement, session perso) : J1 servie et faite ; J2 servie (5 pages capturées, en-tête « E2MOM · 8 tours · 16 min » + Lancer, groupes sans écart) ; jeudi servi : EMOM des muscle-ups 8 lignes, départ toutes les 60 s, « EMOM · 8 min » + Lancer ; raison de la modulation posée sur le rowing : lue dans la feuille ⓘ de la carte (capture), en tête (relevé). Captures `kb5_1_poussee_page1..5`, `kb5_2_emom_minute_par_minute`, `kb5_3_modulation_page`, `kb5_4_modulation_feuille` (deux thèmes) : relues, rien de coupé ni d'illisible.

## 5. Relecture indépendante

Sous-agent Opus (diff de `lib/`, `test/`, `integration_test/`, `tools/`), sans exécution : six points, tous traités avant le contrôle complet :
1. empreintes de `kb1_koach105_test` restées celles de KB4 → recalculées (méthode vérifiée sur `main`) ;
2. type privé dans une API publique (`library_private_types_in_public_api`, vu aussi par l'analyse du contrôle rapide n°1) → `Map<String, Object?>` ;
3. test KB4 « au moins l'écrit » contre la règle KB5 « sous l'écrit seulement avec `volume_semaine` » → aucun écart sur le scénario avec 1.0.8 (relevé), gardé tel quel ;
4. `volume_semaine` sur une carte PR8 ou sur une autre ligne du même exercice → raison portée par ses séries écrites, texte « Koach aurait fait … » sur la ligne PR8, assertion ajoutée ;
5. groupe du moteur repris quand l'application écarte une ligne → toujours recalé sur les lignes servies, groupe du moteur seulement s'il est identique ;
6. symboles du moteur, types, assertions pures, API des tests : vérifiés bons.

## 6. Limites et recommandations au pilotage

1. **Valider dev7.7.0.**
2. X8 (modulation sous l'écrit) : sans réponse du propriétaire au lancement, la raison est affichée (C17.48.4). Sur le scénario PR2 elle ne se déclenche pas (lundi, mardi à l'écrit) ; elle est vérifiée par une raison posée dans la séance (tests et émulateur). Si le propriétaire veut qu'elle ne baisse jamais l'écrit : lot moteur (baisse limitée à l'intensité).
3. Programmes créés par `kalis_plan` (bloc suivant) : un groupe d'intervalles peut désormais être réduit par Koach pour une cause du jour (bilan bas, douleur ; C17.40.3), lignes et tours d'accord ; les intervalles du programme du propriétaire restent tels qu'écrits (C17.44.4). À dire au propriétaire si le bloc suivant est créé.
4. Mercredi au bilan bas, le groupe E3MOM servi ne compte plus que le squat (1 080 s, une ligne de 6) : le dead hang de la pause est retiré par Koach ou servi hors du groupe (le relevé ne le dit pas) ; lignes et chrono restent d'accord. À regarder dans un lot suivant (relevé du dead hang au bilan bas), sans effet sur un jour normal.

## 7. À tester (propriétaire)

- Installer dev7.7.0 ; séance du jour : toutes les lignes, E2MOM avec un chrono et ses tours.
- Un jour de bilan bas : enchaînements au chrono d'accord avec leurs lignes ; intervalles tels qu'écrits.
- Si « Cette semaine, je te propose … » apparaît : la ligne garde au moins une série, la raison reste sur la carte.
