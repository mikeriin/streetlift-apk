# Cahier des charges — Refonte UI et UX de Kalis Track : finition, cohérence et menus (lots UI0 à UI5)

10/10/2026 · propriétaire : Gaël · rédigé par la conversation de pilotage · **version 2** (remplace la version 1 du même jour, qui changeait la navigation : écartée par le propriétaire).
Maquettes de référence (canevas : chaque écran actuel à côté de sa version finie, palettes et capitales réglables) : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J — sources dans `pipeline/ui/maquettes/`. En cas d'écart entre une maquette et ce cahier, ce cahier tranche ; `DECISIONS_UI.md` tranche sur les deux.

## 0. Demande du propriétaire

| Heure (10/10/2026) | Demande |
| --- | --- |
| 09:08 | « Une refonte de l'UI pour avoir quelque chose de propre qui ne fait pas brouillon » ; cahier des charges puis refonte en parallèle |
| 09:17 | « L'UI et l'UX » |
| 09:19 | « Inspire-toi de ce que font Samsung, Google et Microsoft » |
| 09:20 | Fichier de 8 palettes (`inputs/palettes_kalis_track.txt`) |
| 09:32 | « Lance pas tout de suite, il faut que je valide avant » |
| 09:36 | « Garder le même principe de l'UI/UX présente mais que ça soit fini et pas brouillon » |
| 09:50 | « Ne change pas les illustrations de Koach, du logo et de l'anatomie musculaire. Termine correctement ce qui est déjà fait, corrige les incohérences entre l'UX et l'UI, refonds tous les menus pour une cohérence UI/UX avec une expérience utilisateur plaisante » |

Ce cahier décrit donc **une finition**, pas une nouvelle application : mêmes écrans, même navigation, mêmes parcours, mêmes contenus, mêmes illustrations ; un seul système visuel appliqué partout, des incohérences corrigées, et un modèle unique pour tous les menus.

## 1. Ce qui ne change pas

- **Navigation** : dock flottant à 4 onglets (Arsenal, Stats, Programme, Réglages), ouverture sur Programme, ordre et noms inchangés.
- **Écrans et parcours** : accueil (niveau, semaine, liste des jours, carte du jour), Mon programme, Ma saison, Jour J, Évolution, programme d'origine, bloc suivant ; séance (Bilan du jour, pages d'exercices, chronos, fin de séance, récompenses) ; Stats (onglets) ; Arsenal ; Réglages ; parcours de création du profil et départ du programme. Même ordre des étapes, mêmes actions, mêmes textes sur le fond (seules la forme et la clarté changent).
- **Illustrations intouchables** :
  - **Koach** : les 36 poses de `kalis_koach` (dessins, calques encre / papier / yeux, couleurs `KoachColors`), leurs placements actuels (carte du jour, Bilan du jour avec les 5 poses du ressenti, cartes Saison et Évolution, messages, bulles), les répliques et l'animation.
  - **Logo** : `assets/icon/logo_mark.png` (K à la silhouette en ATR) teinté par `KalisLogo`, icône Android, écran de démarrage.
  - **Anatomie musculaire** : `assets/muscles/*`, `assets/muscles2d/*`, `MuscleBody`, la carte 2D et le mannequin 3D, leur rampe d'intensité (qui suit la couleur choisie, décision du 29/09/2026).
  - Un lot peut seulement changer **le conteneur** d'une illustration (marge, alignement, taille dans une grille) ; jamais le dessin, ses couleurs internes ni son placement dans le parcours.
- **Moteurs, données, sauvegarde** : aucun changement de format, de logique, de calcul ni de migration.

## 2. Constat

Relevé sur `main` b7996b3f (dev6.11.1) : 72 captures émulateur de `claude/ci-3d` (run 37946602412) et mesure du code de `lib/`.

| Mesure | Valeur |
| --- | --- |
| Tailles de police littérales | 27 valeurs différentes, 177 occurrences ; 5 graisses ; 9 interlettrages |
| Rayons d'angle | 12 valeurs différentes |
| `EdgeInsets` littéraux | 231 |
| `Color(0x…)` hors `app_theme.dart` | 83 |
| `Card(` bruts / `KCard(` | 98 / 175 ; 34 `BoxDecoration` faites main |
| `toUpperCase()` | 28 |
| Menus, feuilles et dialogues | 49 appels (`PopupMenuButton`, `showModalBottomSheet`, `showDialog`) dans 23 fichiers, sans modèle commun |

## 3. Incohérences à corriger (UI ↔ UX)

Chaque ligne est une règle que tous les lots appliquent.

| N° | Incohérence relevée | Règle |
| --- | --- | --- |
| C1 | Trois en-têtes différents : `KTopBar` avec titre en capitales, `AppBar` avec surtitre « RÉGLAGES » en 12 px, `AppBar` « EXERCICES » / « FICHE EXERCICE » | Un seul en-tête de sous-page : retour, titre, au plus une action (⋮). Les pages racines (onglets) ont un grand titre et une phrase. |
| C2 | Même importance, trois formes : liens colorés (« Voir le changement », « Pourquoi ? », « Passer », « Voir la saison »), boutons pleins, boutons à contour | Hiérarchie unique : un bouton plein au plus par écran (l'action principale) ; actions secondaires = bouton tonal ou ligne avec chevron ; lien texte seulement pour « Pourquoi ? », « Modifier », « Passer ». |
| C3 | Titres coupés par « … » (« TEST MAX TRACTIONS A… », « PUISSANCE MU + SQUAT ENDURAN », « Bloc … ») | Jamais de troncature d'un titre ou d'une information : retour à la ligne (2 lignes, 3 au-delà de 150 % de texte). |
| C4 | Capitales appliquées au hasard (titres d'écran, de séance, de jours, surtitres, libellé du dock, mais pas les sous-pages) | Les capitales restent le style des titres (écran, séance, jour, onglet actif) — option de style unique (`KTokens.capsTitles`, décision U3) ; jamais dans le texte courant, les puces, les boutons, les sections. |
| C5 | Couleur sans signification (puce « Reps » en rouge, surtitres rouges « SÉRIE DE TÊTE… », liens rouges) | La couleur porte un état ou l'action principale (§5.1) ; puces neutres ; consignes en texte normal, leur titre en `encre` sans capitales. |
| C6 | Titres de section de trois sortes (surtitre « PHASES », titre de carte, `KSection`) | Un seul titre de section (14, graisse 600, `texte2`, sans capitales) au-dessus des groupes. |
| C7 | Cartes dans des cartes (page Bilan du jour) | Interdit : une carte contient des lignes, des champs, des puces, jamais une autre carte. |
| C8 | Recouvrements : bandeau « Nouveau : 11 questions… » sous le dock, message de Koach sur la barre de chrono, poignée « DEV » sur le contenu | Zones réservées : le contenu défile au-dessus du dock (marge basse = hauteur du dock + 16) ; un seul élément flottant en bas à la fois (barre de chrono, au-dessus le message de Koach) ; poignée DEV (builds de dev) dans la marge, jamais sur un texte ou un bouton. |
| C9 | Formats différents pour la même chose (« 34–49 min », « ≥ 22 min », « ≈ 162 rép. · 600 s d'effort + non chiffré ») | Un format par grandeur : durée estimée « 34–49 min » ; volume « 6 exercices, 19 séries, 136 rép. » ; secondes au-delà de 90 s écrites en minutes ; nombres français (virgule, espace fine avant l'unité). |
| C10 | Menus contextuels de trois sortes (menu déroulant, feuille, dialogue) ; action destructrice « Effacer l'historique » mêlée aux autres | Feuille d'actions unique (§4) ; actions destructrices dans le dernier groupe, en `danger`, avec confirmation. |
| C11 | Réglages : « Apparence » réglée sur la racine, les autres rubriques en sous-pages ; sous-pages sans titre en page | Modèle de menu unique (§4) : la racine liste toutes les rubriques ; « Apparence » reste en tête de la racine (réglage le plus fréquent), dans un groupe comme les autres. |
| C12 | Valeurs simples réglées par dialogue | Réglage en place : interrupteur, pas à pas, segments ; dialogue seulement pour confirmer une action destructrice ou irréversible. |
| C13 | Cibles tactiles sous 48 dp (icônes de la barre d'outils de série, puces) | ≥ 48 dp partout. |
| C14 | Placement de la mascotte | Rien à corriger (§1) : placements et poses conservés. |

## 4. Refonte des menus : un seul modèle

Toutes les surfaces de choix ou d'action suivent l'un de ces cinq gabarits (maquettes « Réglages », « Réglages › Chronomètres », « Arsenal », « Menu ⋮ de la séance », « Exercices de la séance »).

| Gabarit | Anatomie | Remplace |
| --- | --- | --- |
| **Menu racine** (`KMenuPage`) | grand titre (capitales selon U3) et une phrase ; recherche quand le contenu s'y prête (Arsenal) ; titres de section ; groupes arrondis (rayon 24) ; lignes `KMenuRow` : pastille d'icône 40 × 40 (rayon 12, `haute`), titre (16, 600), une ligne de description (13, `texte2`, retour à la ligne permis), valeur ou chevron ; séparateurs entre lignes, en retrait de la pastille | racine des Réglages, Arsenal, menus d'entrée de Stats et du programme |
| **Sous-page de menu** | en-tête standard (C1), une phrase, groupes ; réglages en place : interrupteur (`KSwitch`), pas à pas relié (−, valeur, +), segments | sous-pages des Réglages, Profil, Notifications, Données |
| **Feuille d'actions** (`KActionSheet`) | poignée, titre et contexte (« Séance — Corps entier, S1, J2 »), groupes d'actions (icône + verbe), dernier groupe = actions destructrices en `danger`, bouton « Fermer » | tous les menus ⋮ et `PopupMenuButton` |
| **Feuille de liste** (`KListSheet`) | poignée, titre et résumé (« 7 exercices, 22 min »), lignes numérotées, élément courant en contour `encre`, éléments faits cochés en `validation` | liste des exercices de la séance, choix de semaine, choix d'exercice de remplacement |
| **Confirmation** (`KConfirm`) | titre = question, une phrase de conséquence, « Annuler » et le verbe exact (« Effacer », « Remplacer ») ; verbe en `danger` si destructeur | dialogues de suppression, import, remplacement de programme |

Inventaire à convertir (49 appels, 23 fichiers) : chaque lot convertit ceux de ses fichiers (§7.2) avec les composants de UI0 et les liste dans sa livraison ; UI5 vérifie qu'il n'en reste aucun hors gabarit (`tools/check_ui_tokens.py --menus`).

Règles de parcours des menus : tout réglage à 3 appuis au plus depuis son onglet ; toute action ⋮ à 2 appuis au plus ; « Retour » ramène toujours à l'écran d'où l'on vient, à la même position de défilement ; un changement de réglage s'applique tout de suite, sans bouton « Enregistrer ».

## 5. Système de design

Le système vit dans `lib/kit/` (nouveau dossier ; `ui.dart` et la présentation de `app_theme.dart` deviennent des adaptateurs pendant la migration et disparaissent à UI5).

### 5.0 Références : Samsung, Google, Microsoft

| Source | Principe repris | Application |
| --- | --- | --- |
| **Samsung One UI** | Zone de lecture en haut, zone d'interaction en bas, à portée du pouce ; parcours courts ; confort (sombre, tailles de texte) | Grands titres des pages racines ; actions principales et choix en bas ; menus groupés dans des conteneurs arrondis ; grand titre qui se replie au défilement sur les pages racines |
| **Google Material 3 (Expressive)** | Rôles de couleur avec paires « couleur / texte sur la couleur » au contraste garanti (HCT) ; forme, taille et couleur pour hiérarchiser ; mouvement à ressorts. Google annonce 46 études, plus de 18 000 participants, des éléments clés repérés jusqu'à 4 fois plus vite, et des 45 ans et plus aussi rapides que les plus jeunes | Dérivation des palettes (§5.1) avec `material_color_utilities` ; forme pilule pour l'élément sélectionné ; groupes de boutons reliés (−15 s / +15 s, pas à pas) ; ressorts (§5.5) |
| **Microsoft Fluent 2** | Jetons en couches (globaux, puis alias nommés par leur fonction) qui couvrent clair, sombre, contraste élevé et variantes de marque | Trois couches : globaux (hex des palettes, échelles), alias (`fond`, `surface`, `encre`…), composants ; aucun écran n'utilise un global ; mode « Contraste renforcé » |

Sources : [Samsung One UI](https://developer.samsung.com/one-ui/overview.html) ; [Fluent 2, design tokens](https://fluent2.microsoft.design/design-tokens) ; [Android Authority, Material 3 Expressive](https://www.androidauthority.com/google-material-3-expressive-details-3554486/) ; [Material 3 Expressive, Android Developers](https://developer.android.com/design/ui/wear/guides/get-started/apply).

### 5.1 Couleurs

**Les 8 palettes du propriétaire remplacent les 6 couleurs de L5.** Chaque palette : dominante, secondaire, accent, fond sombre, fond clair. Thème clair / sombre / système indépendant de la palette.

**Dérivation** (`lib/kit/palette.dart`, test qui retrouve `inputs/palettes_roles.json` à l'identique) : la valeur du propriétaire est gardée telle quelle quand elle passe le contraste de son rôle ; sinon on garde sa teinte et sa chroma (HCT) et on ne déplace que sa tonalité, du plus petit pas (0,5) suffisant.
- `fond` = fond du propriétaire. Sombre : `surface`, `haute`, `filet` = même teinte, chroma ≤ 16, tonalité + 5, + 10, + 15. Clair : `surface` blanc, `haute` = fond, `filet` = tonalité − 10.
- `texte` (tonalité 95 / 10), `texte2` (70 / 40), `texte3` (50 / 60, inactif seulement), teinte du fond, chroma ≤ 6.
- `pleine` (bouton principal, jour courant, onglet actif, carte du jour) = dominante ; en sombre, tonalité relevée à 35 au moins. `surPleine` = blanc ou `#121212`, le plus contrasté (≥ 4,5:1) ; texte blanc retenu si 6 points de tonalité au plus suffisent.
- `encre` (élément courant, repère, chiffre mis en avant, lien) = dominante ajustée à ≥ 4,5:1 sur `surface` (et sur `fond` en clair).
- `second` (données, barres secondaires) = secondaire ajustée à ≥ 3:1. `accent` (records, réussites, Jour J) = accent ajusté à ≥ 4,5:1.
- **Contraste renforcé** : mêmes règles à 7:1 (et 4,5:1 au lieu de 3:1).

| Palette (identifiant) | Source : dominante / secondaire / accent / fond sombre / fond clair | Sombre : pleine / texte sur pleine / encre / second / accent / surface | Clair : pleine / texte sur pleine / encre / second / accent |
| --- | --- | --- | --- |
| Bordeaux Performance (`bordeaux`, **défaut**) | `#551515` / `#8E3030` / `#D9A66C` / `#181819` / `#F6F2EF` | `#873B38` / `#FFFFFF` / `#CA6F6A` / `#B24B49` / `#D9A66C` / `#222223` | `#551515` / `#FFFFFF` / `#551515` / `#8E3030` / `#916632` |
| Obsidian Energy (`obsidian`) | `#E5484D` / `#FF8566` / `#FFC857` / `#121316` / `#F2F3F5` | `#D73E44` / `#FFFFFF` / `#EA4C50` / `#FF8566` / `#FFC857` / `#1C1D20` | `#D73E44` / `#FFFFFF` / `#CD363D` / `#E67254` / `#906800` |
| Arctic Motion (`arctic`) | `#2563EB` / `#4F9CF9` / `#14B8A6` / `#152238` / `#F5F8FC` | `#2563EB` / `#FFFFFF` / `#668EFF` / `#4F9CF9` / `#14B8A6` / `#242D3D` | `#2563EB` / `#FFFFFF` / `#2563EB` / `#4795F2` / `#008073` |
| Neon Athlete (`neon`) | `#B4F044` / `#67D8C0` / `#8C72FF` / `#101510` / `#F2F9EA` | `#B4F044` / `#121212` / `#B4F044` / `#67D8C0` / `#8C72FF` / `#1A1F1A` | `#B4F044` / `#121212` / `#567B00` / `#2BA690` / `#7458E4` |
| Titanium Pro (`titanium`) | `#4C6474` / `#8A9DA8` / `#D5A24C` / `#171E24` / `#E8EDF0` | `#4C6474` / `#FFFFFF` / `#7992A3` / `#8A9DA8` / `#D5A24C` / `#21282F` | `#4C6474` / `#FFFFFF` / `#4C6474` / `#8396A1` / `#8E6310` |
| Violet Momentum (`violet`) | `#7546DB` / `#AC8CFA` / `#29BFB0` / `#181427` / `#F5F1FF` | `#7546DB` / `#FFFFFF` / `#986CFF` / `#AC8CFA` / `#29BFB0` / `#221E31` | `#7546DB` / `#FFFFFF` / `#7546DB` / `#A181EE` / `#007D71` |
| Forest Endurance (`forest`) | `#236B50` / `#7BAC81` / `#D7B374` / `#17251D` / `#F4F5EE` | `#236B50` / `#FFFFFF` / `#5CA283` / `#7BAC81` / `#D7B374` / `#213027` | `#236B50` / `#FFFFFF` / `#236B50` / `#6FA076` / `#886B32` |
| Solar Sprint (`solar`) | `#D95A27` / `#FF9760` / `#E8BC49` / `#211B1A` / `#FFF6ED` | `#CA4F1C` / `#FFFFFF` / `#E86531` / `#FF9760` / `#E8BC49` / `#2C2524` | `#CA4F1C` / `#FFFFFF` / `#C34A17` / `#DC7B46` / `#8F6D00` |

Préférence `accent` : anciens identifiants relus `rouge` → `bordeaux`, `jaune` → `neon`, `vert` → `forest`, `violet` → `violet`, `orange` → `solar`, `turquoise` → `arctic` ; absent ou inconnu → `bordeaux` ; import d'une ancienne sauvegarde jamais refusé pour ça.

États communs : `validation` `#5CB860` / `#2E7D32`, `danger` `#EF6B6B` / `#B3261E`, `avertissement` `#E6A23C` / `#8A5300` (sombre / clair), contrôlés à ≥ 4,5:1 sur chaque `surface`.

Illustrations (§1) : Koach garde `KoachColors` (encre claire et papier = support en sombre, encre `#141414` et papier blanc en clair, `onColor` sur la carte du jour) ; le logo garde sa teinte actuelle (texte en sombre, `pleine` en clair) ; la rampe de l'anatomie va de `pleine` à `encre` de la palette, comme aujourd'hui avec la couleur dominante.

### 5.2 Typographie

**Barlow** (SIL OFL 1.1), embarquée dans `assets/fonts/` avec sa licence et ses empreintes (source : `google/fonts`, `ofl/barlow`, `ofl/barlowsemicondensed`, `ofl/barlowcondensed` ; aucune permission INTERNET) : Barlow 400 / 500 / 600 (texte), Barlow Semi Condensed 600 (titres), Barlow Condensed 500 / 600 (chiffres, en chiffres tabulaires).

| Style | Police | Taille / interligne (dp) | Usage |
| --- | --- | --- | --- |
| `titreRacine` | Semi Condensed 600 | 30 / 36 | titre d'un onglet (Arsenal, Réglages, Stats) |
| `titreEcran` | Semi Condensed 600 | 22 / 28 | titre d'une sous-page ; semaine de l'accueil |
| `titreSeance` | Semi Condensed 600 | 20 / 24 | séance, exercice, feuille |
| `titreCarte` | Semi Condensed 600 | 18 / 24 | titre de carte ; ligne de jour (15 / 20) |
| `corpsFort` | Barlow 600 | 16 / 22 | titre de ligne de menu, boutons |
| `corps` | Barlow 400 | 15 / 22 | texte courant |
| `detail` | Barlow 400 | 13 / 18 | description, valeur secondaire |
| `section` | Barlow 600 | 14 / 20 | titre de section (`texte2`) |
| `micro` | Barlow 600 | 12 / 16 | surtitre de la carte du jour, légende |
| `chiffre` | Condensed 600 | 36 / 38 | prescription (« 4 × 5 »), durée estimée |
| `chiffreMoyen` | Condensed 600 | 20 / 24 | champs de saisie, pas à pas |
| `chrono` | Condensed 600 | 34 / 36 | barre de repos |

Capitales : appliquées par le style (`textTransform`) aux titres `titreRacine`, `titreEcran`, `titreSeance`, lignes de jour et onglet actif, quand `KTokens.capsTitles` est vrai (U3) ; jamais par `toUpperCase()` dans le code. Nombres au format français ; les grands chiffres restent entiers à 200 % de texte.

### 5.3 Espacements, formes, élévation

- Espacements : 4, 8, 12, 14, 16, 20, 24, 32 — seules valeurs ; marge d'écran 20 ; écart entre cartes 12.
- Rayons : 8 (puces), 14 (champs, segments, ligne courante), 16 (lignes de jour, boutons, groupes de feuille), 24 (cartes, groupes de menu), 28 (feuilles), pilule (dock, onglet actif, choix sélectionné) — seules valeurs.
- Aucune ombre ; profondeur par la surface (`fond` < `surface` < `haute`) ; contour 1,5 dp `encre` pour l'élément courant.
- Cibles ≥ 48 dp ; bouton principal 56 dp.

### 5.4 Composants (`lib/kit/`)

`KTokens` (jetons, `ThemeExtension`), `KPage` (racine à grand titre ou sous-page), `KTopBar` (C1), `KDock` (dock flottant actuel, fini : hauteur 64, pilule de l'onglet actif en `pleine`, libellé de l'onglet actif seulement), `KCard` (principale rayon 24, carte du jour pleine), `KDayRow` (ligne de jour : numéro, titre, état), `KSeasonBar` (barre de saison par blocs, repère de la semaine), `KMenuGroup` / `KMenuRow`, `KSwitch`, `KStepper`, `KSegmented`, `KActionSheet`, `KListSheet`, `KConfirm`, `KChip` (neutre), `KPrimaryButton` / `KTonalButton` / `KTextButton`, `KSetTable` (tableau des séries : en-tête, ligne courante, champs, validation), `KRestBar` (barre de repos flottante, groupe −15 s / +15 s, arrêt), `KSnack` (message court, Koach compris), `KNotice` (bandeau dans le flux), `KTimeline` (frise des phases), `KEmpty`. Les widgets d'illustration (`KalisLogo`, `KoachView`, `MuscleBody`, carte 2D, mannequin) sont **utilisés tels quels**.

### 5.5 Mouvement

Ressorts de Material 3 Expressive (amortissement / raideur) : spatial rapide 0,9 / 1 400 (choix, boutons), par défaut 0,9 / 700 (feuilles), lent 0,9 / 300 (pages) ; effets 1,0 / 3 800, 1 600, 800. Animations de Koach inchangées. Réglage système « réduire les animations » respecté.

### 5.6 Textes de l'interface

Mêmes textes sur le fond ; corrections de forme seulement : tutoiement, verbe exact sur les boutons, une action garde son nom de bout en bout, plus de mot en capitales dans une phrase, formats de C9. Les répliques de Koach ne changent pas.

## 6. Exigences mesurables

### 6.1 Code

| Critère | Seuil | Vérifié par |
| --- | --- | --- |
| `fontSize`, `fontWeight`, `letterSpacing`, `Color(0x…)`, `BorderRadius.circular(n)`, `EdgeInsets` littéraux hors `lib/kit/` et hors liste blanche (illustrations, peintres de données, mannequin, outils dev) | 0 | `tools/check_ui_tokens.py`, en CI |
| `Card(`, `BoxDecoration(` bruts hors `lib/kit/` et liste blanche | 0 | idem |
| `toUpperCase()` sur un texte affiché | 0 | idem |
| Menus hors gabarit (`PopupMenuButton`, `showModalBottomSheet`, `showDialog` directs hors `lib/kit/`) | 0 | `check_ui_tokens.py --menus` |
| Fichiers d'illustration modifiés (`brand.dart`, `koach/**` sauf placement, `muscle_body.dart`, `muscle_map_2d.dart`, `assets/icon/`, `assets/muscles*/`, `packages/kalis_koach/`) | 0 ligne de dessin modifiée | revue du diff |
| Tests de comportement modifiés ; assertion retirée sans remplacement | 0 ; 0 | revue du diff de `test/` |
| Format de sauvegarde, schémas, clés de préférences | inchangés (sauvegarde d'avant UI0 relue à l'identique) | test de relecture |

### 6.2 Rendu

Contraste ≥ 4,5:1 (≥ 3:1 au-delà de 24 dp ; 7:1 en contraste renforcé) sur les 32 combinaisons, par test ; 0 titre tronqué et 0 débordement à 360 et 320 dp, texte 100 %, 130 %, 200 % ; cibles ≥ 48 dp et boutons-icônes nommés (`androidTapTargetGuideline`, `labeledTapTargetGuideline`) ; 0 contenu sous le dock, la barre de repos ou un message (tour de captures).

### 6.3 Parcours

Aucun parcours ne gagne d'appui (relevé avant / après par le tour de captures) ; menus : tout réglage à 3 appuis au plus de son onglet, toute action ⋮ à 2 appuis au plus.

### 6.4 Performance

Temps d'image de la séance et de l'accueil ≤ ceux de dev6.11.1 (`docs/PERFORMANCE.md`) ; APK : + 600 Ko au plus (polices comprises).

## 7. Organisation des lots

### 7.1 Principe

Un lot de fondations, quatre lots d'écrans **en parallèle** sur des fichiers disjoints, un lot d'intégration. Branche d'intégration `refonte-ui` (depuis `main` b7996b3f) ; chaque lot sur `ui/<LOT>` ; contrôle sur `claude/ci-ui-<lot>` (workflow ajouté par UI0, une concurrence par branche).

### 7.2 Propriété des fichiers

Un fichier n'appartient qu'à un lot ; les fichiers partagés n'appartiennent qu'à UI0 puis UI5 ; un composant manquant est créé dans `lib/<zone>/widgets/` et signalé, UI5 le promeut ; logique (`store.dart`, `*_store.dart`, `models.dart`, `persistence.dart`, `packages/`) et illustrations (§1) interdites à tous.

| Lot | Fichiers (et leurs tests dédiés) |
| --- | --- |
| UI0 | `lib/kit/**` (nouveau), `app_theme.dart`, `ui.dart`, `main.dart` (thème, polices, réserve du dock), `nav_bar.dart` (finition du dock, sans changer les onglets), `motion.dart`, `filter_menu.dart`, `search.dart`, `alerts.dart`, `store_widget.dart`, `pubspec.yaml`, `assets/fonts/`, `.github/workflows/`, `tools/check_ui_tokens.py`, `integration_test/tour_ui_test.dart` (squelette) |
| UI1 Programme | `home_screen.dart`, `program_screens.dart`, `program_explainer.dart`, `program_origin.dart` (présentation), `resume_banner.dart`, `levelup.dart`, `plan/season_view.dart`, `plan/event_day_screen.dart`, `plan/evolution_widgets.dart`, `plan/plan_sheets.dart`, `plan/program_position.dart`, `koach/koach_home_card.dart`, `koach/koach_bubble.dart` (conteneurs seulement) |
| UI2 Séance | `session_screen.dart`, `session_host.dart`, `session_history.dart`, `set_validation.dart` (présentation), `estimate_view.dart`, `rewards.dart`, `adapt/**` (y compris le Bilan du jour) |
| UI3 Stats | `stats_*.dart`, `progression_screen.dart`, `records_screen.dart`, `game_widgets.dart` (conteneurs et graphiques ; `muscle_body.dart` et `muscle_map_2d.dart` intouchables) |
| UI4 Menus | `settings_screen.dart`, `notification_settings.dart`, `data_control.dart`, `pilotage_screen.dart`, `wellbeing_screens.dart`, `retired_notice_screen.dart`, `startup.dart`, `arsenal_screen.dart`, `exercise_screens.dart`, `atlas.dart`, `anatomy_screen.dart` (conteneur), `athlete_profile*.dart`, `profile_completion.dart`, `guided_tests.dart`, `program_start.dart`, `plan/plan_screens.dart`, `plan/plan_creation.dart`, `koach/koach_gallery_screen.dart` (conteneur) |
| UI5 Intégration | tout, en fin de parcours |

Non listés (`dev/**`, `plan/plan_inspector.dart`, `animation_test_screen.dart`, mannequin, moteur 3D, peintres de pose, `koach/koach_view.dart`, `koach/flame_icon.dart`) : intouchables ou liste blanche ; UI5 traite ce qui reste.

### 7.3 Contenu des lots

**UI0 — Fondations** (seul, prérequis des quatre suivants) : branche et workflow de contrôle parallèle ; polices ; jetons trois couches, palettes (§5.1) et contraste renforcé, sélecteur de palette et interrupteur dans Apparence, relecture des anciens identifiants ; tous les composants de §5.4 avec test et captures (sombre, clair, `bordeaux`, `neon`), catalogue en mode dev ; dock fini (C8, sans changer les onglets) ; adaptateurs pour que tous les écrans compilent et prennent déjà palettes et polices ; `check_ui_tokens.py` (`--zone`, `--menus`, relevé de départ) ; tour de captures (squelette, tous les écrans principaux) et relevé des parcours sur dev6.11.1 ; mode d'emploi du kit dans la livraison.

**UI1 — Programme** (parallèle) : accueil (maquette « Accueil ») : en-tête niveau / semaine / logo sans troncature, barre de saison par blocs à la place de la frise de points, lignes de jour, carte du jour (Koach et anatomie inchangés), bandeaux dans le flux ; Mon programme, Ma saison (frise des phases), Jour J, Évolution (segments), programme d'origine, bloc suivant, position dans le programme ; leurs feuilles et menus au gabarit de §4.

**UI2 — Séance** (parallèle) : Bilan du jour (plus de carte dans une carte, Koach et les 5 poses du ressenti inchangés), pages d'exercices (en-tête, puces neutres, consigne, notes et calibrage en deux lignes ouvrables, tableau des séries, barre d'outils de série ≥ 48 dp), série validée et barre de repos, message de Koach au-dessus, chronos de mode (EMOM, intervalles, tenues, groupes, mini-séries), fin de séance et récompenses, historique d'une séance passée, cartes de douleur et d'avis médical (même logique, même blocage) ; menu ⋮ de la séance en feuille d'actions, liste des exercices en feuille de liste.

**UI3 — Stats** (parallèle) : onglets, cartes et graphiques au système (données en `second` / `encre` / `accent`), records, historique, carte musculaire dans son conteneur ; menus et feuilles au gabarit.

**UI4 — Menus** (parallèle) : Réglages (racine au gabarit « Menu racine », Apparence en tête, 10 rubriques, sous-pages au gabarit « Sous-page de menu », réglages en place), Arsenal (recherche directe, Exercices, Anatomie), bibliothèque et fiche d'exercice, profil et parcours de création (une question par écran, « Continuer » en bas, segments de progression, « Passer »), départ du programme, données (export, import, suppression : confirmations au gabarit), écrans d'aide, démarrage et erreurs de lancement, galerie de Koach (conteneur).

**UI5 — Intégration** (seul, après les quatre) : fusion ; promotion des composants ; suppression des adaptateurs ; contrôles de §6 bloquants sur tout `lib/` ; tour de captures complet (chaque écran × sombre / clair × `bordeaux` / `neon`, 320 dp × 200 %, les 8 palettes et le contraste renforcé sur l'accueil et la séance) ; relecture indépendante (sous-agent Opus : cahier, maquettes, captures) ; installation par-dessus dev6.11.1 sans perte ; publication **dev6.12.0** sur `main`, build signé, run vérifié ; `REFONTE_UI.md` réécrit.

### 7.4 Exigences communes

Maquettes et cahier comme cible, écarts écrits ; aucune information perdue (tableau avant → après par écran dans la livraison) ; suite de tests complète verte, tests d'écran mis à jour et justifiés ; contrôle de jetons et de menus à 0 sur la zone ; tour de captures de la zone relu image par image (sombre et clair, sessions perso et dev) ; sauvegardes toutes les 30 minutes sur `ui-sauvegardes/<LOT>` ; sous-agents sur Opus ; version interne `dev6.12.0-<lot>`, seul UI5 publie sur `main`.

## 8. Ordre avec le reste du projet et calendrier

KM1 continue en parallèle (voie moteurs, aucun fichier commun). Le lot CI final et l'intégration de la base v1.1 passent après UI5 et utilisent `lib/kit/`. KM3 garde son jalon (APK le 16/11/2026). Base de départ : CI1g (dev6.11.1).

| Étape | Dates (après validation du propriétaire) |
| --- | --- |
| UI0 | J à J + 1 |
| UI1 à UI4 en parallèle | J + 1 à J + 3 |
| UI5 et publication dev6.12.0 | J + 4 à J + 5 |

Si la limite hebdomadaire du plan Max approche (KM1 tourne sur Fable), UI1 à UI4 passent en deux vagues : UI2 et UI1, puis UI4 et UI3.

## 9. Décisions (pilotage, à confirmer ou corriger par le propriétaire avant lancement)

| N° | Décision |
| --- | --- |
| U1 | Navigation, écrans, parcours et contenus inchangés ; finition seulement. |
| U2 | Illustrations de Koach, logo et anatomie intouchables (§1). |
| U3 | Capitales conservées pour les titres (style actuel), appliquées uniformément par le style ; réglable en un jeton si le propriétaire préfère les minuscules (interrupteur « capitales » des maquettes). |
| U4 | Police Barlow, embarquée. |
| U5 | Les 8 palettes du propriétaire remplacent les 6 couleurs ; Bordeaux Performance par défaut ; valeurs gardées sauf contraste insuffisant (tonalité HCT ajustée : Bordeaux en sombre, Obsidian et Solar d'une nuance pour le texte blanc, accents et encres en clair). |
| U6 | Mode « Contraste renforcé » ajouté dans Apparence. |
| U7 | Frise de 40 points de l'accueil remplacée par une barre de saison par blocs (même information). |
| U8 | Un seul modèle pour tous les menus (§4) ; menus ⋮ en feuilles d'actions. |
| U9 | Refonte avant le lot CI final et la base v1.1 ; version publiée dev6.12.0. |
