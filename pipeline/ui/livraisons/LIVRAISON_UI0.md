# Livraison UI0 — Fondations de la refonte UI et UX (dev6.12.0-ui0)

Lot UI0 du pipeline « Refonte UI et UX » (UI). Le propriétaire l'a lancé le 10/10/2026 à 11:46, heure de Paris (« Lance ui0 », LANCEMENTS.md, section UI0). La session `session_01DfhZd3fMyMGSUKefFeRLGk` l'a pris à 09:48 UTC : le message de lancement n'avait pas de ligne « Lot : », c'était donc le premier lot « à faire ». Validation : conversation de pilotage (délégation C8), recommandation au §9.

| | |
| --- | --- |
| Branche | `refonte-ui` (créée depuis `main` b7996b3f, dev6.11.1), tête `0e5342df (arbre 7e63edaf, identique au commit contrôlé 592d54a9)` |
| Contrôle complet | `claude/ci-ui-ui0`, workflow `ci-ui.yml`, run 38050589366 : contrôles, paquets, rendus avant, tour (8 parties) et cibles émulateur verts |
| Contrôle rapide | `claude/ci-ui-ui0-rapide` (formatage, analyse, tests et captures du lot) |
| Sauvegardes | `ui-sauvegardes/UI0` (arbre sans `.github/`, avec `SAUVEGARDE.md`) |
| Version interne | dev6.12.0-ui0. C'est une étiquette du lot : `pubspec.yaml` reste à 6.11.1+114 (voir §8). |
| Accès | `add_repo` n'est pas disponible dans la session. Le push a été vérifié par `git push --dry-run origin pipeline`, puis par la prise du lot. |

## 1. Ce qui est livré

Le cahier (§7.3) en neuf points, tous faits :

1. **Branche et contrôle parallèle**
   - `refonte-ui` est créée depuis b7996b3f.
   - `.github/workflows/ci-ui.yml` est une copie de `ci-3d.yml`. Il se déclenche sur `claude/ci-ui-*`, avec une concurrence par branche, ce qui permet à UI1, UI2, UI3 et UI4 de contrôler en même temps.
   - `ci-out/` est recommité sur la branche du lot.
   - Les rendus « avant » et le tour « avant » sont pris sur b7996b3f, épinglé (`UI_BASE`).
   - Avec le suffixe `-rapide`, le contrôle se limite au formatage, à l'analyse, aux tests `test/<lot>_*` et aux captures, en 5 à 6 minutes.
2. **Polices**
   - Barlow 400, 500 et 600, Barlow Semi Condensed 600, Barlow Condensed 500 et 600, dans `assets/fonts/`.
   - La licence est fournie (`OFL.txt`, affichée dans la page des licences par `registerFontLicences`), avec la source (google/fonts au commit bd8f81dd, version 1.408) et les empreintes SHA-256 (`EMPREINTES.sha256`).
   - Poids : +337 Ko compressés dans l'APK, pour un budget de 600 Ko.
3. **`lib/kit/` : jetons en trois couches** (à la manière de Fluent 2)
   - Globaux : `palette.dart` (les 8 palettes du propriétaire) et les échelles de `tokens.dart` (`KSpacing`, `KRadius`, `KSize`, `KFont`, `KType`, `KSprings`).
   - Alias : `KRoles`, portés par `KTokens` (`ThemeExtension`).
   - Composants : les fichiers du kit.
   - Dérivation HCT avec `material_color_utilities` 0.13.0 (dépendance directe, même version que celle de Flutter).
   - Le contraste renforcé est assuré par `KRoles.of(id, dark:, contrast: true)`.
   - Le jeton `kCapsTitles` (U3) est appliqué par `KTokens.title()`, seul endroit où un texte passe en capitales.
   - `kitTheme()` est réécrit sur les jetons, et `buildTheme` en devient l'adaptateur.
   - Ressorts de Material 3 Expressive : `KSpringCurve` et `KMotion` (`fast`, `standard`, `slow`, `effect`), qui respectent « réduire les animations ». Ils animent les transitions de page et d'onglet (`kit/transitions.dart`), le dock, les segments et les feuilles.
   - Tous les composants du §5.4 sont dans le kit, chacun avec son test de widget et ses captures (§3).
   - Le catalogue (`KitCatalogScreen`) est accessible en mode dev : Outils de test › « Catalogue du kit ». La palette, le thème et le contraste se choisissent localement, sans toucher aux réglages de l'utilisateur.
4. **Préférence `accent` et sélecteur**
   - 8 identifiants (`bordeaux` par défaut).
   - Les anciens identifiants sont relus vers la palette la plus proche : rouge → bordeaux, jaune → neon, vert → forest, violet → violet, orange → solar, turquoise → arctic.
   - Un identifiant inconnu donne Bordeaux, et l'import ne refuse jamais une sauvegarde pour ça.
   - Nouveau réglage `contrast` : absent de l'export tant qu'il est éteint, donc l'export reste identique à 6.11.1.
   - Dans Apparence : sélecteur `KPalettePicker` (8 pastilles de 56 dp, nom de la palette, aperçu), segments du thème `KSegmented` et interrupteur « Contraste renforcé ».
5. **Dock fini** (C8)
   - Mêmes 4 onglets, même ordre, même ouverture sur Programme, mêmes clés `nav-0` à `nav-3`.
   - `KDock` : hauteur 64, fond `haute` avec filet, pilule `pleine` et libellé `surPleine` en capitales sur l'onglet actif seulement.
   - Réserve basse = hauteur du dock + 16 dp (`HeroNavBar.extent` = 96).
   - La poignée DEV passe de 24 à 16 dp et tient dans la marge de 20 dp.
6. **Adaptateurs**
   - `app_theme.dart` : `KAccentSpec`, `KPalette`, `SL`, `ProgrammeColors` et `KControl` lisent maintenant les jetons.
   - `ui.dart` réexporte le kit. `KCard`, `KEmpty`, `KTopBar` et `KNavigationInset` sont ceux du kit. `KSection`, `KBadge`, `KSearch`, `KProgressBar`, `KBanner`, `KPageIntro`, `KWordFitText` et `KMenuTile` sont rendus par le kit.
   - `nav_bar.dart` rend désormais `KDock`, et `motion.dart` réexporte les transitions.
   - Tous les écrans compilent et prennent déjà palettes, polices et rayons.
   - Les textes Material historiques gardent leurs métriques (14/20 et 15/20) pour que les écrans pas encore refaits ne bougent pas.
7. **`tools/check_ui_tokens.py`**
   - Options `--zone <LOT>`, `--menus`, `--baseline` et `--compare`.
   - Relevé de départ par fichier : `tools/ui_tokens_depart.json` (main b7996b3f).
   - Branché en CI : relevé complet non bloquant, zone du lot résumée dans `checks.txt` par `ui_tokens_zone`.
   - Tests : `tools/tests/test_ui_tokens.py`.
8. **Tour de captures** (`integration_test/tour_ui_test.dart` et `tools/ci_ui_drive.sh`)
   - 14 écrans principaux en 4 parties : a = sombre bordeaux, perso ; b = clair neon, perso ; c = sombre neon, session de test ; d = clair bordeaux, session de test.
   - Relevé des parcours du §6.3, textes passés sous le dock, même tour sur b7996b3f pour la colonne « avant ».
9. **Mode d'emploi du kit** : §7.

## 2. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse | vert |
| Tests Dart (suite complète, 860 tests, 29 ignorés : rendus de capture, lancés à part) et tests du mode dev | vert (860 + 18 du mode dev) |
| Tests Python (dont `test_ui_tokens.py`), intégrité, arbre sans secret | vert |
| Jetons, zone UI0 (`--zone UI0 --menus`) | 0, contre 149 au départ (app_theme 103 → 0, ui 30 → 0, nav_bar 7 → 0, filter_menu 8 → 0, main 2 → 0) |
| Palettes : `palettes_roles.json` retrouvé à l'identique en Dart | 192 valeurs sur 192, 0 écart (`test/ui0_palette_test.dart`). L'algorithme avait aussi été vérifié avec la bibliothèque TypeScript de référence : 0 écart. |
| Contrastes sur 32 combinaisons (8 palettes × 2 thèmes × 2 contrastes) | Tous au seuil du §5.1 (test), voir §4 |
| Captures du kit (`test/ui0_kit_capture_test.dart`) | 101 PNG : 11 sections × sombre/clair × bordeaux/neon, jetons et sélecteur dans les 8 palettes, contraste renforcé, 320 dp × 200 % |
| Aucun débordement : 11 sections × 360 dp 100 % et 130 %, 320 dp 200 %, sombre et clair | vert |
| Cibles ≥ 48 dp, boutons-icônes nommés (`androidTapTargetGuideline`, `labeledTapTargetGuideline`) sur ligne de menu, pas à pas, barre de repos, dock, sélecteur | vert |
| Cibles émulateur des lots précédents (`ci3d_drive.sh`, CI1g) | vert (CI1g à M7 : tous les codes à 0) |
| Tour émulateur : 4 parties « après » et 4 « avant » | vert (4 + 4 parties, 14 captures chacune) |
| Build debug et build profile | verts |
| Paquets (moteurs) | inchangés, verts |
| Rendus de test historiques (`visual_capture_test`) | en échec, comme sur la base b7996b3f (même test en échec dans la colonne « avant ») : hors de ce lot |

Relecture indépendante par un sous-agent Opus, qui n'a vu que le cahier, les maquettes et les captures avant et après. Il a fait 17 constats, et son verdict était « à corriger ». Traitement :

| N° | Constat | Suite donnée |
| --- | --- | --- |
| 1, 2, 4 | Mots coupés à 320 dp × 200 % (ligne de menu, frise, nom de palette, recherche) | Corrigé. À 150 % et au-delà, la pastille s'efface et la valeur passe dans la description. La frise met dates et durée sur une seule ligne. Le nom de la palette a sa propre ligne. La recherche accepte 2 lignes d'indication. |
| 3 | Feuille de liste rognée | C'était la capture (hauteur fixe dans le catalogue). La feuille réelle défile, à 85 % de l'écran au plus. La hauteur de l'échantillon suit maintenant la taille du texte. |
| 5 | Boutons de la confirmation à 43 dp en grand texte | Corrigé : marge intérieure de 12, 48 dp au moins. |
| 6 | En clair, `haute` = `fond` : commandes invisibles sur la page | Corrigé. Nouveau jeton `controlSide` / `controlPill` : contour `filet` en clair (bouton tonal, puce, segments, pas à pas, champs, pastilles). |
| 7 | `encre` sous 4,5:1 sur `haute` | Accepté et documenté : `encre` et `accent` restent ceux du tableau de référence (§5.1 : seuil sur `surface`). Règle du kit : texte `encre` ou `accent` seulement sur `fond` ou `surface`. L'aperçu de palette suit cette règle. |
| 8 | Neon en clair : logo et frise de semaine illisibles | Corrigé dans l'adaptateur. Le logo prend `encre` en clair (= dominante quand elle est lisible, donc inchangé pour Bordeaux, Arctic, Titanium, Violet et Forest). La frise de semaine et sa pastille prennent `encre`. Le dessin du logo ne change pas. |
| 9 | `SegmentedButton` historique : choix rectangulaire | Corrigé dans Apparence (segments du kit). Ailleurs (Évolution, etc.), le composant Material ne permet pas de pilules séparées par le thème : ces écrans passent à `KSegmented` dans leur lot (UI1, UI4). |
| 10 | Carte dans une carte (aperçu) | Corrigé : l'aperçu n'a plus de cadre. |
| 11 | Interrupteur « Contraste renforcé » absent des captures | Ajouté au tour (`reglages_contraste`) et au test `l5c_selecteur_test.dart`. |
| 12 | Barre de progression du repos rognée | Corrigé : pilule en retrait de 20 dp. |
| 13 | Segments empilés en 200 % | Voulu : aucun mot coupé. Six pilules de 48 dp, aux cibles conformes. |
| 14 | Rampe d'une seule couleur dans la planche des jetons | Normal : la rampe va de `pleine` à `rampe`, et la planche montre la couleur d'arrivée. |
| 15 | Séries validées en `texte3` | Corrigé (`texte2`). |
| 16 | Indicateur de page de la séance en `second` | Laissé à UI2. Le rôle historique `action` reste la secondaire ajustée, parce que du texte clair posé dessus doit rester lisible (test `motion_test`). UI2 passera à `encre`. |
| 17 | Pied de page « dev6.11.1 » | Voulu (§8). |

## 3. Captures clés

Elles sont sur `claude/ci-ui-ui0` (dernier commit « CI UI : résultats du run … »).

- Kit : `ci-out/captures-ui/ui0_<section>_<bordeaux|neon>_<sombre|clair>.png`. Sections : `menus`, `reglages`, `cartes`, `feuilles`, `seance`, `programme`, `palettes`, `dock`, `boutons`, `jetons`, `typo`.
- 8 palettes : `ci-out/captures-ui/ui0_8p_jetons_<palette>_<thème>[_renforce].png` et `ui0_8p_palette_<palette>_<thème>.png`.
- 320 dp × 200 % : `ci-out/captures-ui/ui0_320_<section>_bordeaux_sombre.png`.
- Tour : `ci-out/tour/apres/tour_<a|b|c|d>_<nn>_<écran>.png`, et les mêmes noms dans `ci-out/tour/avant/`. À regarder en priorité : `tour_a_01_accueil`, `tour_a_11_reglages_apparence`, `tour_a_12_reglages_contraste`, `tour_b_01_accueil` (Neon clair), `tour_c_10_reglages` (session de test, poignée DEV), `tour_d_13_reglages_bas` (réserve du dock).

## 4. Mesures

**Contrastes** (WCAG, calcul) :

| Rôle | Seuil (normal / renforcé) | Résultat |
| --- | --- | --- |
| `texte` et `texte2` sur `fond`, `surface`, `haute` | 4,5 / 7 | 32 combinaisons vertes |
| `encre`, `accent` et `second` sur `surface` (et `fond` en clair) | 4,5 / 7 ; `second` 3 / 4,5 | tableau du propriétaire retrouvé |
| `validation`, `danger`, `avertissement` sur les 3 surfaces | 4,5 / 7 | vert |
| Texte sur aplats (`surPleine` sur `pleine`, etc.) | 4,5 | de 4,79 (Obsidian) à 13,96 (Bordeaux) |

États : la valeur commune du cahier est gardée, et sa tonalité n'est ajustée que là où elle passerait sous le seuil sur `haute`. C'est le cas d'Arctic, Titanium, Forest et Solar en sombre (`danger` #FC7575 à #F46F6F), et de Titanium en clair (`validation` #2B7A30). Même règle HCT que les palettes. Écart au cahier, qui donnait des valeurs fixes.

**Parcours** (§6.3, tour, même valeur avant et après, comme attendu pour UI0 qui ne déplace aucune entrée) :

| Parcours | Avant | Après |
| --- | --- | --- |
| Ouvrir Mon programme depuis l'accueil | 1 (bouton de la carte du moment) | 1 |
| Ma saison | 2 | 2 |
| Évolution | 2 | 2 |
| Jour J | impossible sur le profil d'exemple (aucun évènement) | idem |
| Mes références | 3 (Réglages › Programme › Références) | 3 |
| Un réglage précis (Repos par défaut) | 2 (Réglages › Chronomètres) | 2 |
| Fiche d'exercice pendant la séance, exercices d'un muscle, douleur | non relevés (parcours créés par UI2, UI4) | — |

Mon programme, Ma saison et Évolution passent déjà par le bouton « Mon programme » de la carte du moment de l'accueil, ce qui donne 1 et 2 appuis. Jour J : aucun évènement dans le profil d'exemple. UI1 ajoutera un profil avec compétition.

**Contenu sous le dock** : aucun texte en bas de l'accueil, de Stats, d'Arsenal et des Réglages, dans les 4 parties, avant comme après.

**Poids** : polices +337 Ko compressés.

**Temps d'image** : non mesurés. Ce lot ne touche ni la séance ni l'accueil au-delà du thème. Mesure à UI5 (`docs/PERFORMANCE.md`).

## 5. Écarts aux maquettes et au cahier

- **Dock** : fond `haute` à 96 % d'opacité, avec flou, pour garder l'effet actuel qui plaît au propriétaire, plutôt que `haute` opaque. Marge latérale et marge basse de 16 dp. Les onglets repliés gardent une cible de 57 dp sur un écran de 360 dp.
- **Cibles** : les boutons du pas à pas font 48 dp, contre 44 dans la maquette (C13).
- **Interrupteur éteint** : pouce et contour en `texte2` (et non `texte3`), pour atteindre 3:1 (critère 1.4.11).
- **Rampe de l'anatomie** : de `pleine` à `encre` quand elle s'en distingue (2,5:1). Sinon, la dominante est éclaircie (sombre) ou assombrie (clair) juste assez. Neon sombre, déjà très clair, va vers sa secondaire. Sans cette règle, la rampe serait plate pour 6 palettes sur 8 (`encre` = `pleine`). Les fichiers d'illustration ne sont pas modifiés, seules les couleurs fournies changent.
- **Logo en clair** : `encre` à la place de `pleine` (même couleur pour 5 palettes ; Neon, Obsidian et Solar prennent leur encre, lisible). Le dessin n'est pas modifié. **À confirmer par le propriétaire.**
- **Métriques de texte des écrans historiques** : 14/20 et 15/20 dans l'adaptateur, pour ne pas changer leur mise en page avant leur lot. Les composants du kit suivent le §5.2 (corps 15/22).
- **Titres de section** : sans capitales partout dès UI0 (C6), par l'adaptateur `KSection`. Trois tests cherchaient l'ancien texte en capitales et ont été mis à jour (§6).
- **États communs** : tonalité ajustée par palette quand le seuil l'exige (§4).

## 6. Fichiers touchés hors de la liste de UI0 (§7.2) et pourquoi

| Fichier | Changement | Raison |
| --- | --- | --- |
| `lib/store.dart` (logique, interdit) | `kAccentIds` (8 identifiants), `normalizeAccent` (relecture des anciens), défaut `bordeaux`, réglage `contrast` (écrit seulement s'il est actif), notificateur `contrastMode` | Imposé par le prompt de UI0 (« préférence `accent` : 8 palettes, relecture des anciens identifiants, import ancien accepté ; interrupteur Contraste renforcé ») : la préférence vit dans `AppSettings`. Ajout seulement, sans migration. Le format reste lisible par 6.11.1 (identifiant inconnu → rouge). |
| `lib/settings_screen.dart` (UI4) | `_AccentPicker` remplacé par `KPalettePicker`, interrupteur « Contraste renforcé », thème en `KSegmented` | Prompt de UI0 : « sélecteur de palette avec aperçu et interrupteur dans Apparence ». UI4 part de cette version (aucun conflit : UI0 tourne seul). |
| `lib/dev/dev_widgets.dart` (mode dev) | Poignée DEV à 16 dp, entrée « Catalogue du kit » | Prompt de UI0 : « poignée DEV dans la marge », « catalogue en mode dev ». |
| Tests | `l5c_couleur`, `l5c_selecteur`, `l5c_palettes_capture` : 6 couleurs → 8 palettes, mêmes comportements, plus la relecture des anciens identifiants et le contraste. `l9b_pose` : tableau d'accents de référence = `encre` des 8 palettes. `g1_mode_dev`, `g2_retrait` : identifiants ; `g2_retrait` compare les réglages hors `accent`, relu vert → forest. `l9b_content`, `l2b_data_control` : titres de section sans capitales (C6). | Aucune assertion retirée sans remplacement équivalent. |

## 7. Mode d'emploi du kit (UI1 à UI4)

**Où trouver quoi** : `lib/kit/kit.dart` exporte tout (`import 'kit/kit.dart';`, ou `ui.dart` pendant la migration).

| Besoin | Composant ou jeton |
| --- | --- |
| Couleur | `final k = KTokens.of(context);` puis `k.fond`, `k.surface`, `k.haute`, `k.filet`, `k.texte`, `k.texte2`, `k.texte3` (inactif), `k.pleine` / `k.surPleine` (aplat principal), `k.encre` (repère, chiffre, lien : texte sur `fond` ou `surface` seulement), `k.second` (données), `k.accent` (records, Jour J), `k.validation`, `k.danger`, `k.avertissement`, `k.roles.rampe` |
| Texte | `KType.titreRacine`, `titreEcran`, `titreSeance`, `titreCarte`, `ligneJour`, `corpsFort`, `corpsMoyen`, `corps`, `detail`, `libelle`, `section`, `micro`, `chiffre`, `chiffreMoyen`, `chiffrePetit`, `chrono` ; titres en capitales par `k.title(texte)` et `k.titleStyle(style)`, jamais `toUpperCase()` |
| Espaces, rayons, tailles | `KSpacing.s4` à `s32`, `page`, `cardGap` ; `KRadius.card` (24), `menu` (20), `pill`, `cardShape`, `menuShape`, `sheetRadius` ; `KSize.target` (48), `primary` (56), `menuIcon`, `menuRow`, `settingRow`, `search`, `current` (1,5) ; `k.controlPill` (commande en `haute`, contour en clair) |
| Page | `KPage.root(title:, lead:, search:, trailing:, children:)` (grand titre qui se replie) ; `KPage.sub(title:, subtitle:, lead:, action:, children:)` ; `KTopBar.sub(...)` comme `appBar` ; `KTopBar()` (barre de marque) ; `KFitTitle` (titre jamais coupé) |
| Menus (§4.5) | `KMenuPage(title:, lead:, search:, header:, groups:, root:)` ; `KMenuGroup(title:, children:)` ; `KMenuRow(icon:, title:, subtitle:, value:, onTap:, danger:, highlight:)` ; `KSwitchRow`, `KStepperRow`, `KSegmentedRow` ; `KSectionTitle` ; `KIconTile` |
| Réglages en place | `KSwitch`, `KStepper(value:, onDecrement:, onIncrement:, decrementLabel:, incrementLabel:)`, `KSegmented<T>(segments: [KSegment(v, 'Libellé')], selected:, onChanged:)` |
| Actions | `KPrimaryButton` (un seul par écran, `danger:` pour « Supprimer »), `KTonalButton`, `KTextButton` (« Pourquoi ? », « Modifier », « Passer »), `KIconButton(tooltip:)` |
| Feuilles | `showKActionSheet<T>(context, title:, subtitle:, groups: [[KAction(icon:, label:, value:)], …, [KAction(…, danger: true)]])` (le dernier groupe porte les actions destructrices, ce qui est vérifié) ; `showKListSheet(context, title:, summary:, items: [KListItem(…, state: KListState.current)])` ; `showKConfirm(context, title:, message:, confirmLabel: 'Supprimer', destructive: true)` |
| Surfaces | `KCard`, `KCard.day`, `KNotice` (bandeau dans le flux), `KEmpty` (avec l'action qui résout, R6), `KChip` |
| Programme | `KDayRow(number:, title:, state:, onInfo:)` (R7), `KSeasonBar(blocks: [KSeasonBlock(8)…], week:)` (U7), `KTimeline(phases: [KPhase(…)])` |
| Séance | `KSetTable(columns:, rows: [KSetRow(number:, cells: [KSetField('5')], actions:, state:)])`, `KRestBar(remaining:, progress:, onMinus:, onPlus:, onStop:)`, `showKSnack(context, message:, bottom: hauteurBarreDeRepos)` |
| Recherche | `KSearchField(hint: 'Rechercher un réglage', onChanged:)`, avec la règle de correspondance de `search.dart` |
| Mouvement | `KMotion.fast` / `standard` / `slow` / `effect` : `.curve`, `.durationIn(context)` (zéro si les animations sont réduites) |
| Dock | `KDock` (déjà branché), réserve `KDock.reserve` et `KNavigationInset.of(context)` |

**Gabarits de menus** :
- racine des Réglages, Arsenal et Mon programme : `KMenuPage` + `KMenuGroup` + `KMenuRow` ;
- sous-pages : `KPage.sub` + groupes de `KSwitchRow` / `KStepperRow` / `KSegmentedRow` ;
- tout menu ⋮ : `showKActionSheet` ;
- listes : `showKListSheet` ;
- toute confirmation : `showKConfirm` ;
- jamais de `showDialog`, `showModalBottomSheet` ni `PopupMenuButton` direct (`--menus`).

**Contrôle de zone** :
- `python3 tools/check_ui_tokens.py --zone UI1 --menus` doit rendre 0.
- `python3 tools/check_ui_tokens.py --compare tools/ui_tokens_depart.json` donne l'écart au départ, fichier par fichier.
- Contrôle rapide : push sur `claude/ci-ui-ui1-rapide` (tests `test/ui1_*`, en 5 à 6 minutes) ; contrôle complet sur `claude/ci-ui-ui1`.

**Ajouter un écran au tour** :
- dans `integration_test/tour_ui_test.dart`, une ligne `await screen(tester, 'nom', open: const MonEcran(), check: find.byType(MonEcran));` dans la section de la zone ;
- un parcours : une entrée `route(...)`, avec le chemin court du lot en tête ;
- le test doit compiler aussi sur b7996b3f (colonne « avant ») : utiliser des écrans et des textes qui existent dans les deux, ou des finders par texte.

**Captures de zone** : `test/<lot>_*_capture_test.dart` avec `support/ui_capture.dart` (`loadUiFonts`, `saveUiPng` vers `validation/UI/<lot>_*.png`). Elles sont recopiées dans `ci-out/captures-ui/`.

**Composants à promouvoir** : un lot qui crée un composant le met dans `lib/<zone>/widgets/` et le signale. UI5 le promeut dans `lib/kit/`.

## 8. Limites

- **Version** : `pubspec.yaml` et `kVersion` restent à 6.11.1. Une version « 6.12.0-ui0 » casserait 4 tests de version (Python et Dart, qui exigent X.Y.Z) et créerait un conflit dans `settings_screen.dart` (UI4) à chaque lot. dev6.12.0 sera posée par UI5.
- **`SegmentedButton` Material ailleurs dans l'application** : le choix reste rectangulaire au milieu de la pilule (Évolution, etc.) jusqu'au passage des écrans concernés à `KSegmented` (UI1, UI4).
- **Rôle historique `action`** : il reste la secondaire ajustée (indicateurs et curseurs des écrans existants). Les lots utiliseront `encre` ou `pleine` selon le cas.
- **Bandeau « Nouveau : 11 questions… »** : il reste sous le dock (C8). Il relève de l'écran d'accueil (UI1), qui passera à `KNotice` dans le flux.
- **Capitales des titres** : le jeton `kCapsTitles` est une constante (U3). Un interrupteur utilisateur n'a pas été demandé.
- **Captures 320 dp × 200 %** : le catalogue est rendu dans une marge supplémentaire de 20 dp. La feuille de liste y coupe « Échauffement », un mot long, alors qu'elle a 40 dp de plus en usage réel.

## 9. Recommandation (C8, le pilotage décide)

Valider UI0 et lancer UI1 à UI4 en parallèle depuis `refonte-ui`. Le kit couvre tous les composants et gabarits du §5.4 et du §4.5, les 8 palettes retrouvent le tableau du propriétaire à l'identique, l'adaptateur ne fait régresser aucun écran (suite complète et cibles émulateur vertes, tour avant et après sans contenu sous le dock), et le contrôle de zone est prêt.

Deux points à faire confirmer par le propriétaire au passage :
1. Logo teinté en `encre` en thème clair : identique pour 5 palettes, lisible pour Neon, Obsidian et Solar.
2. Dock légèrement translucide.
