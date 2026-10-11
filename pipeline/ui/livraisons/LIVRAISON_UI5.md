# Livraison UI5 — Intégration et publication de la refonte UI et UX (dev6.12.0)

Lot UI5 du pipeline « Refonte UI et UX » (UI), lancé par le pilotage le 11/10/2026 à 01:15 (LANCEMENTS.md, section UI5). Le message de lancement n'avait pas de ligne « Lot : » : UI5 était le premier lot « à faire » dont les prérequis étaient remplis. Session `session_014wA1B8bKecW5barqcLhDf9`, lot pris à 05:11 UTC. Validation : conversation de pilotage (délégation C8, U0.13), puis le propriétaire sur téléphone.

| | |
| --- | --- |
| Base | `refonte-ui` 0bc6237 (UI1 à UI4 fusionnés), avancé en avance rapide sur 48bda98 (fusion de `main` dev6.11.2, CI1h, faite par le pilotage ; contrôle run 38094241871 entièrement vert : tests, builds, 8 tâches du tour, 16 cibles émulateur à 0) |
| Publication | **dev6.12.0 sur `main`** : `refonte-ui` et `main` avancés en avance rapide sur caf5589 (« Kalis Track dev6.12.0 (UI5) : refonte UI et UX publiée », depuis e351f27 dev6.11.3) ; build signé « Build APK et AAB » run 38134737676 vert (tests de régression, refus sans secrets, clé existante restaurée et contrôlée, signature apksig vérifiée, APK et AAB au numéro 213880916) |
| Contrôle complet | `claude/ci-ui-ui5`, run 38127114476 (commit 23dc12f, arbre publié) ; run 38123734037 (commit c574f14, seule différence : `search_field.dart`) |
| Contrôle rapide | `claude/ci-ui-ui5-rapide`, run 38120925185 (formatage, analyse, jetons, tests `ui5_*`, captures : verts) |
| Sauvegardes | `ui-sauvegardes/UI5` (arbre sans `.github/`, `SAUVEGARDE.md`) |
| Version | **6.12.0+117**, affichée « dev6.12.0 » |
| Accès | `add_repo` n'est pas disponible dans la session ; push vérifié par `git push --dry-run origin pipeline` puis par la prise du lot |

## 1. Ce qui est livré

**1. Corrections du kit (U0.16), dans l'ordre demandé**

1. **Titre de sous-page jamais coupé (bloquant)** : `KTopBar.sub` n'est plus une `AppBar` Material (dont le `DefaultTextStyle` à ellipse limitait le titre à une ligne). L'en-tête est rendu par le kit : retour (clé `topbar-back`, masquable par `showBack: false`), titre par `KFitTitle` (`overflow: visible`, 2 lignes, 3 au-delà de 150 % de texte, taille réduite juste assez avant de passer à la ligne), au plus une action. La barre prend la hauteur de son titre (l'échafaudage réserve 400 dp au plus et n'en garde que la hauteur réelle). Vérifié par test à 320 et 390 dp × 100, 130 et 200 % (« Supprimer les données de l'application », « Progression et jeu », « Données et confidentialité », nom d'exercice long) et sur émulateur à 320 dp × 200 % (partie e du tour).
2. `KSwitchRow` : l'interrupteur passe sous le libellé quand le mot le plus long du libellé ne tient pas à côté (mesure réelle, plus de « Célébration / s ») ; `KSegmented` : chaque segment offre au moins 48 × 48 dp touchables (le choix est une pilule en retrait de 4 dans sa case), largeur selon le libellé avec un plancher de 48 dp, choix en colonne quand un libellé ne tient pas ; `KStepperRow` : seuil de passage sous le libellé relevé de 300 à 420 dp ; phrase de `KPage.root` alignée sur le grand titre ; étiquette des champs **dans** la pilule (`KFieldBorder`), neutre (`texte2`) tant qu'il n'y a pas d'erreur, `danger` en erreur ; `KConfirm` : contenu qui défile, boutons toujours visibles ; `KIconButton` désactivé sans fond ; clés de test : boutons de `KConfirm` (`confirmKey`, `cancelKey`), action et fermeture de `KNotice`, action de `KEmpty`, segments (`keyPrefix`), boutons et valeur de `KStepper` (`keyPrefix`), retour de `KTopBar.sub`.
3. **Une seule feuille de contenu** (`KContentSheet` / `showKContentSheet`), issue de `showKContentSheet` (UI2), `KInfoSheet` (UI3) et `showProgramSheet` (UI1) : poignée, titre et contexte, contenu qui défile, « Fermer » toujours visible en bas (sauf quand le contenu porte sa sortie : feuilles de Koach et « Ce que j'ai changé »), version qu'on agrandit en la tirant, fond `surface` et papier de Koach assorti. Promus aussi : `showKChoice` (fondu dans `KConfirm`, mode obligatoire de l'avis médical), `KSessionHeader`, `KProgressDots`, `KBottomInset` (UI2), `KDayRow` (ligne de jour de UI1 : états écrits, ⓘ), `KWhyTile`, `showKListSheet(initial:)` (UI1), `KMeter`, `KStatTile`, `KTileGrid` (UI3), `KActionRow`, `KScaffold`, `KPageList`. Les trois fichiers de zone (`program_widgets.dart`, `session_kit.dart`, `k_info_sheet.dart`) sont supprimés.
4. Titres de feuille sans capitales (U0.17) : cahier §5.2 corrigé (branche `pipeline`).

**2. Reliquats signalés par les lots**

- Textes hors zones : `wellbeing.dart` (chemins écrits remplacés : « depuis ton profil, rubrique Santé, blessures et gênes », « Bilan du jour », « pendant la séance, touche le menu ⋮ puis « Douleur ou malaise ? » ») ; `game.dart` (« (Mes références) » au lieu de « références Pilotage » / « (Références) ») et contournement `_r9` de UI3 retiré ; « Compatibilité 3D » en titre de `engine3d.dart` (au lieu de « MOTEUR 3D ») ; `retired_notice_screen.dart`, `imported_program.dart`, `data_control.dart`, `animation_test_screen.dart` (R5, R9, C1) ; consignes du programme qui citent « la feuille Pilotage » affichées « Mes références » (`contentText`, données inchangées).
- Formats (C9, U0.19, U0.23 « formats de durée ») : `lib/kit/format.dart` (nombres à virgule, espace fine insécable U+202F avant l'unité, secondes au-delà de 90 s en minutes, « au moins n min », lecture d'une charge saisie avec la virgule ou le point) ; champs de charge en virgule à l'écran, nombre au point au journal (même valeur) ; estimations, résumés du profil, Jour J, conseils de Koach ; charges proposées arrondies **au quart de kilo** à l'affichage (pas commun des grilles du moteur ; voir §6).
- Changement d'onglet depuis une page : `openTab(context, AppTab.program)` (`nav_bar.dart`, réexporté par `main.dart`) ; « Ouvrir le programme » sur les états vides de l'Historique, des Records et de la quête principale.
- Débordement de `historique_seance` à 320 dp × 200 % : cause trouvée (état « Enregistré » non flexible dans la relecture d'une séance, `session_screen.dart`), corrigé ; test à 320 × 640 dp et 200 %.
- En-tête de séance repliable à 200 % : **non fait** (voir §8).
- `KNotice` pour le bandeau « Nouveau : … questions » et la carte des tests guidés : **non appliqué**, volontairement (voir §6).
- Contraste du dock translucide (U0.12) : vérifié par calcul sur les 8 palettes × 2 thèmes × 2 contrastes, contenu blanc, noir, aplat, texte ou fond dessous : icônes ≥ 4,5:1 ; dock opaque en contraste renforcé.
- Code mort `StatsLevelCard`, `showStatsLevel` : retiré (aucun appel).
- Carte des muscles de la carte du jour : présente sur toutes les captures émulateur (8 palettes, clair et sombre).

**3. Intégration et publication**

- Adaptateurs retirés : `lib/ui.dart` supprimé (tous les écrans importent `kit/kit.dart`) ; `app_theme.dart` réduit aux rôles de couleur lus par les illustrations (`SL`, `KPalette`, `KAccentSpec`, `buildTheme`), qui ne peuvent pas changer d'API ; métriques de texte d'avant la refonte (14/20, 15/20) retirées : le texte courant suit partout le cahier (corps 15/22).
- Contrôles du §6 bloquants sur tout `lib/` : `check_ui_tokens.py --zone UI5 --menus` à 0 (zone UI5 = tout `lib/`) ; illustrations intactes : nouveau `tools/check_ui_illustrations.py` et son relevé (89 fichiers identiques à dev6.11.1 : Koach, logo, anatomie, paquet `kalis_koach`), test Python bloquant `tools/tests/test_ui_illustrations.py`.
- Tour complet : 6 parties (a à d comme avant ; **e** = 320 dp × 200 % ; **f** = 8 palettes en sombre et en clair, puis contraste renforcé, sur l'accueil et la séance), avant et après.
- Installation par-dessus dev6.11.1 : `test/ui5_installation_test.dart` (voir §5).
- `REFONTE_UI.md` réécrit (l'ancien registre L5 dans `docs/REFONTE_UI_L5.md`), `README.md` et `SUIVI_PROJET.md` à jour.

## 2. Avant → après (UI5 ; les tableaux écran par écran des lots UI1 à UI4 restent valables)

| Écran ou élément | Avant (refonte-ui 48bda98) | Après (dev6.12.0) | Information perdue |
| --- | --- | --- | --- |
| En-tête de toute sous-page | titre coupé par « … » au-delà d'une ligne | titre entier sur 2 lignes (3 à 200 %), barre qui suit | aucune |
| Interrupteurs (Réglages, Données) | coupés en grand texte ; rail actif en dominante (1,1:1 en Bordeaux sombre) | sous le libellé quand il le faut ; rail actif en `encre` | aucune |
| Segments (objectif, thème, note) | cases de 36 à 40 dp | ≥ 48 × 48 dp | aucune |
| Pas à pas (Séance) | à côté d'un libellé serré | sous le libellé sur téléphone | aucune |
| Champs | étiquette sur le bord, colorée | étiquette dans la pilule, neutre | aucune |
| Feuilles de contenu (semaine, jour, évolution, explication, Stats, consignes) | trois modèles, « Fermer » absent des feuilles du Programme | un modèle, « Fermer » en bas | aucune |
| Confirmations | `KConfirm` (sans défilement) et `KChoiceDialog` | `KConfirm` unique, qui défile | aucune |
| Santé et sécurité | chemins faux écrits | formulations sans chemin, vraies | aucune |
| Aides des attributs de jeu | « références Pilotage » | « Mes références » | aucune |
| Page 3D | « MOTEUR 3D » | « COMPATIBILITÉ 3D » | aucune |
| Durées, charges | « ≥ 22 min », « 600 s », « 62.5 » | « au moins 22 min », « 10 min », « 62,5 » | aucune (journal identique) |
| États vides de Stats | sans action | « Ouvrir le programme » | aucune |
| Recherche (Réglages, Arsenal) à 200 % | saisie calée en haut | saisie centrée | aucune |
| Rubriques de Stats | pilule à 12 dp du bord, sans marge intérieure | pilule à 20 dp, 16 de marge | aucune |
| Bulle de Koach (sombre) | boutons secondaires invisibles (`haute` sur `haute`) | fond `filet` | aucune |

## 3. Contrôles

Contrôle complet sur l'arbre publié : run 38127114476 sur le commit 23dc12f (arbre identique à celui publié). Tour : 12 tâches sur 12 vertes (après et avant, parties a à f). Suite Dart : trois tests de `m8_carte_2d_test` y ont dépassé le délai de 10 min (lenteur du runner : ce fichier n'importe rien de la refonte et l'arbre ne diffère du run 38123734037, entièrement vert, que par `search_field.dart`) ; la même suite complète est verte sur ce même commit dans le build signé « Build APK et AAB » run 38127114392 (délai de 60 s par test). Cibles émulateur relancées une fois : 16 cibles à 0 (tentative 2 du même run).

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse | verts |
| Jetons et menus hors gabarit, **tout `lib/`** (`check_ui_tokens.py --zone UI5 --menus`) | 0 (7 au départ du lot : 4 `toUpperCase`, 3 feuilles hors kit) |
| Illustrations intactes (`check_ui_illustrations.py`, test Python bloquant) | 89 fichiers identiques à dev6.11.1 |
| Tests Python et intégrité (162 tests, `verify_project`, `package_release --check`, arbre sans secret, ressources chiffrées) | verts |
| Tests Dart, suite complète (1025 tests, 52 ignorés : rendus de capture lancés à part) et mode dev (18) | verts |
| Nouveaux tests | `ui5_kit_test` (titres entiers à 320/390 dp × 100/130/200 %, interrupteur et pas à pas, segments 48 dp et `androidTapTargetGuideline`, confirmation qui défile, feuille de contenu, feuille de liste ouverte sur l'élément, bouton désactivé, champs, contraste du dock sur 32 combinaisons), `ui5_format_test`, `ui5_navigation_test` (11 tests), `ui5_installation_test` (4 tests), `ui5_texte_test` |
| Captures du kit et des écrans (`ui*_capture_test`) | vertes |
| Rendus de test historiques (`visual_capture_test`) | en échec, comme sur la base b7996b3f (hors refonte, déjà relevé par UI0 à UI4) |
| Builds debug et profile | verts ; APK profile 61,6 Mo |
| Build signé « Build APK et AAB » sur l'arbre candidat (branche de contrôle) | vert, run 38123734055 |
| Paquets (moteurs) | inchangés, verts |
| Cibles émulateur des lots précédents (16, CI1g à M7) | toutes à 0 |
| Tour sur émulateur, 6 parties après et avant (a à f) | après : 6 sur 6 ; avant : voir run 38127114476 : 6 sur 6 |
| Relecture indépendante (sous-agent Opus : cahier, maquettes, 152 paires de captures avant / après et 20 planches) | « publiable après corrections mineures » ; aucun défaut bloquant ; suite donnée ci-dessous |

**Relecture indépendante, suite donnée**

| N° | Constat | Suite |
| --- | --- | --- |
| 1 | Carte du jour « 34–49 min », feuille de la séance « 44–49 min » | Non corrigé : deux calculs sur deux jours différents (programme et séance servie), hors présentation ; à trancher (§8) |
| 2 | Boutons secondaires invisibles dans la bulle de Koach en sombre | Corrigé : fond `filet` (`KTonalButton(onHaute:)`) |
| 3 | Interrupteur actif illisible en Bordeaux sombre (1,1:1) | Corrigé : rail `encre`, pouce `surEncre` |
| 4 | Rubriques de Stats : pilule collée au texte, à 12 dp du bord | Corrigé : 16 de marge intérieure, rangée à 20 dp ; la pilule reste l'indicateur de la rubrique choisie (comme le dock) |
| 5 | Recherche à 200 % : saisie calée en haut d'un champ haut | Corrigé : champ d'une ligne dès la saisie, saisie centrée |
| 6 | « feuille Pilotage » dans les consignes | Corrigé à l'affichage (`contentText`), données inchangées |
| 7 | « (Mes références) » sans lien dans la feuille de personnage | Laissé : une feuille de jeu n'ouvre pas de page (UI3) ; c'est le nom exact de la page |
| 8 | Action ⟲ de Mes références disparue ; ordre ; « Poids du corps / de corps » | Action non perdue : « Effacer toutes mes références » est en bas de page, confirmée (UI4 §3) ; textes laissés (données) |
| 9 à 16 | Mineurs (capitales des titres de séance des données, titres de rubrique de Stats, « Calibrage » sur 3 lignes, liste « Où j'en suis », bouton d'Anatomie à 200 %, contrastes hors texte, accords) | Bouton d'Anatomie pleine largeur corrigé ; les autres laissés et listés (§8) |

## 4. Captures clés

Sur `claude/ci-ui-ui5` (dernier commit « CI UI : résultats du run … »), `ci-out/tour/apres/` et `ci-out/tour/avant/` :
- `tour_a_01_accueil`, `tour_a_12_seance_menu`, `tour_a_29_reglages`, `tour_a_35_reglages_donnees` (sombre Bordeaux) ;
- `tour_b_31_reglages_apparence`, `tour_b_33_reglages_seance` (clair Neon) ;
- `tour_e_35_reglages_donnees`, `tour_e_38_references`, `tour_e_03_mon_programme` (320 dp × 200 % : titres sur deux lignes, sans ellipse) ;
- `tour_f_*_p_<palette>_<thème>_accueil` et `_seance` (8 palettes), `tour_f_*_r_*` (contraste renforcé).

## 5. Mesures

**Parcours (cahier §6.3, tour sur émulateur, partie a ; mêmes valeurs en b, c, d)**

| Parcours | Avant (dev6.11.1) | Après | Cible |
| --- | --- | --- | --- |
| Mon programme depuis l'accueil | 3 | **1** | 1 |
| Ma saison, Évolution | 4 | **2** | 2 |
| Jour J | 5 | **3** | 3 |
| Fiche d'exercice pendant la séance | impossible | **2** | 2 |
| Douleur pendant la séance | impossible par ce chemin (5 dans le cahier) | **4** | 4 |
| Mes références depuis la séance | 2 (« Références (feuille Pilotage) ») | **2** (« Mes références ») | 2 |
| Mes références depuis Réglages | 3 onglet compris | 3 onglet compris, soit 2 depuis la racine des Réglages | 2 |
| Un réglage précis (« Repos par défaut ») | 2 | 2 par les rubriques ; 2 par la recherche depuis la racine (3 onglet compris) | 2 |
| Exercices d'un muscle | impossible | recherche directe : 3 depuis la racine d'Arsenal (4 onglet compris) | recherche directe ou 3 |
| Records | page non branchée | 3 onglet compris | — |
| Objectif de la semaine (Stats) | 3 | 2 | — |

Aucun parcours ne gagne d'appui. Contenu sous le dock : aucun texte, dans les 6 parties. Partie e (320 dp × 200 %) : mêmes parcours, sauf la fiche en séance (le script de capture ne fait pas défiler le bilan jusqu'à « Passer » à 200 %, voir §8).

**Contrastes** : texte sur aplat (`surPleine` sur `pleine`) ≥ 4,5:1 dans les 8 palettes ; icônes du dock ≥ 4,5:1 sur tout contenu, en contraste normal comme renforcé (test) ; interrupteur actif en `encre`, ≥ 4,5:1 sur `surface` par construction. Les 32 combinaisons de UI0 restent vertes.

**Poids** : APK profile 61,6 Mo ; polices +337 Ko depuis UI0 (budget 600 Ko). Temps d'image : non mesurés (§8).

## 6. Écarts au cahier et aux maquettes, et pourquoi

- **Feuilles du Programme avec « Fermer »** : la feuille de contenu unique porte « Fermer » en bas (comme les feuilles d'actions et de liste) ; seules les feuilles où Koach porte la sortie (« OK », « Annuler ce changement ») n'en ont pas, pour ne pas mettre deux sorties côte à côte.
- **Pas à pas sous le libellé sur tous les téléphones** : conséquence du seuil de 420 dp décidé (U0.16 point 4) ; la valeur prend la largeur de la ligne (pilules −, valeur, + séparées de 4).
- **Interrupteur actif en `encre`** (et non en dominante `pleine`) : la relecture a mesuré 1,1:1 pour le rail Bordeaux sur `surface` en sombre (Titanium et Forest sous 3:1) ; `encre` est la dominante dans 5 palettes en clair, et lisible partout.
- **Dock opaque en contraste renforcé** : à 96 % d'opacité, un contenu blanc passant dessous faisait tomber les icônes sous 7:1 ; à 100 %, elles sont à 6,1:1 au moins (≥ 4,5:1 exigé pour un élément graphique en contraste renforcé). Le dock reste translucide avec flou en contraste normal (U0.12).
- **Charges proposées arrondies au quart de kilo** (et non au demi-kilo demandé par UI1) : c'est le pas commun des grilles du moteur (lest 1,25, barre 2,5, haltères 1 ou 2) ; au demi-kilo, l'écran afficherait 36,5 kg quand le moteur sert 36,25 kg et que le champ est pré-rempli à 36,25. Le texte enregistré au journal (`log.prescribed`) ne change pas.
- **Bandeau « Nouveau : … questions » et carte des tests guidés** : gardés en bulles de Koach (avec leurs poses) dans le flux de l'accueil, au-dessus du dock (C8 tenu) ; les passer en `KNotice` retirerait Koach d'un placement existant, ce que le cahier interdit (§1, C14).
- **« (Mes références) » dans la feuille de personnage** : nom de la page, sans lien ; un bouton ouvrirait une page depuis une feuille de jeu, ce que UI3 a exclu (une feuille n'en ouvre jamais une autre, test `ui3_stats_test`).
- **En-tête de séance non repliable** à 200 % de texte : l'en-tête est hors de la vue paginée ; le replier au défilement d'une page demanderait de lier chaque page à l'en-tête (risque sur la pagination et les cibles émulateur). Le titre y reste entier (`KFitTitle`).
- **Titres de séance des données** en capitales (« SQUAT + GAINAGE ») jusque dans le contexte des feuilles : donnée du programme (UI2.3), non retouchée.

## 7. Récapitulatif des décisions prises sans le propriétaire (pour ajuster après essai)

Chaque ligne : la décision, puis ce qu'il faut changer pour revenir dessus.

| N° | Décision (source) | Pour revenir dessus |
| --- | --- | --- |
| U0.4 | Refonte avant le lot CI final et la base v1.1 | Ordre des pipelines (pilotage) |
| U0.12 | Logo teinté en `encre` en thème clair (Neon, Obsidian, Solar lisibles) | Rôle du logo dans `lib/app_theme.dart` (`SL`) : `pleine` au lieu d'`encre` |
| U0.12 | Dock à 96 % d'opacité avec flou | `lib/kit/dock.dart` : `alpha` du fond |
| U0.13 | Pause budget à 80 % (`pipeline/ui/PAUSE`) | Règle du pipeline |
| U0.14 | Feuille d'information pour les feuilles de jeu de Stats | Devenue la feuille de contenu unique (`showKContentSheet`) |
| U0.15 | « Compatibilité 3D » au lieu de « Diagnostic 3D » (mot interdit par L13) | Libellé de la ligne (`settings_screen.dart`) et titre (`engine3d.dart`) |
| U0.16 | Corrections du kit confiées à UI5 | — (faites) |
| U0.17 | Titres de feuille en casse normale | `KSheetHeader` (`lib/kit/sheets.dart`) : `k.title(...)` |
| U0.18 | Chronos de mode en boutons tonaux ; barre de repos masquée en fin de séance ; chiffre des champs plafonné à 130 % | `session_screen.dart` (boutons), `KRestBar` |
| U0.19 | Virgule dans les champs de charge, nombre au point au journal | `decimalFieldText` / `decimalStoredText` (`lib/kit/format.dart`) |
| U0.20, U0.22 | Tour en tâches parallèles, 3 essais | `ci-ui.yml`, `tools/ci_ui_drive.sh` |
| U0.21, U0.25 | `main` fusionné dans `refonte-ui` avant publication (CI1h) | — |
| U0.23 (formats de durée) | « au moins n min », secondes au-delà de 90 s en minutes | `atLeastText`, `formatSeconds` (`lib/kit/format.dart`) |
| UI1.1 | Ligne « Mon programme » juste après les jours | `home_screen.dart` (ordre des éléments) |
| UI1.4 | Lignes de jour à 48 dp, carte du jour compacte (semaine visible à 390 × 844) | `KDayRow` (`lib/kit/program.dart`), carte du jour (`home_screen.dart`) |
| UI1.5 | « Revenir » sans `danger` (retour non destructeur) | `showKConfirm(destructive: true)` dans `program_screens.dart` |
| UI2.1 | Douleur depuis la séance → Bilan du jour sur la section Douleur (4 appuis) | `session_screen.dart` (menu ⋮) |
| UI2.4 | Aucun bouton plein sur la page d'exercice | `session_screen.dart` |
| UI3.1 | Rubriques de Stats en rangée défilante, pilule `pleine` sur la rubrique active | `stats_screen.dart` (`TabBar`) ou `KSegmented` |
| UI3.4 | Objectif de la semaine réglé sur place dans Stats | `stats_overview.dart` |
| UI3.10 | Logo gardé dans l'en-tête de Stats | `stats_screen.dart` |
| UI4.1 | Réglages en 6 rubriques, recherche avec index écrit à la main | `settings_screen.dart`, `settings_search.dart` |
| UI4.3 | « Passer » dans le parcours du profil sur les étapes facultatives | `athlete_profile_flow*.dart` |
| UI4.4 | Formulaires en sous-pages (pas en feuilles) | — |
| UI5.1 | En-tête de sous-page rendu par le kit (plus d'`AppBar`) | `KTopBar.sub` (`lib/kit/page.dart`) |
| UI5.2 | Pas à pas sous le libellé sous 420 dp | `KSize.stepperRowMin` |
| UI5.3 | Segments : 48 dp par segment, largeur selon le libellé | `KSegmented._widths` |
| UI5.4 | Étiquette des champs dans la pilule, neutre | `KFieldBorder`, `inputDecorationTheme` (`lib/kit/theme.dart`) |
| UI5.5 | Interrupteur actif en `encre` | `KSwitch` (`lib/kit/controls.dart`) |
| UI5.6 | Dock opaque en contraste renforcé | `lib/kit/dock.dart` |
| UI5.7 | Feuille de contenu unique avec « Fermer » en bas | `KContentSheet` (`closeLabel`) |
| UI5.8 | Confirmations : boutons empilés quand les libellés dépassent 24 caractères | `KConfirm` (`lib/kit/sheets.dart`) |
| UI5.9 | Texte courant à 15 / 22 partout (métriques d'avant retirées) | `textTheme` (`lib/kit/theme.dart`) |
| UI5.10 | Charges proposées arrondies au quart de kilo à l'affichage | `kAdaptKgDisplayStep` (`lib/adapt/adapt_texts.dart`) |
| UI5.11 | Espace fine insécable avant les unités | `kUnitSpace` (`lib/kit/format.dart`) |
| UI5.12 | « 2 min 30 s » au-delà de 90 s (minutes et secondes) | `formatSeconds` |
| UI5.13 | Bulles de Koach de l'accueil gardées (pas de `KNotice`) | `profile_completion.dart`, `guided_tests.dart` |
| UI5.14 | « Ouvrir le programme » sur les états vides de Stats | `stats_history.dart`, `records_screen.dart`, `stats_overview.dart` |
| UI5.15 | Boutons secondaires de la bulle de Koach sur fond `filet` en sombre | `KTonalButton(onHaute:)` |
| UI5.16 | « feuille Pilotage » des consignes affichée « Mes références » | `contentText` (`lib/kit/format.dart`) |

## 8. Limites

- Pas de SDK Flutter dans la session : tout a été vérifié par les contrôles en CI (rapide puis complet) ; aucun essai sur téléphone.
- **Durées différentes entre la carte du jour et la feuille « Dans cette séance »** (relecture, constat 1) : la carte estime le jour du programme, la feuille la séance du jour telle que le moteur l'a servie (calibrage) ; c'est le calcul (`store.dayEstimate` sur deux jours différents), hors du périmètre d'une refonte de présentation. À trancher par le pilotage : même source, ou libellé qui dit la différence.
- Constats mineurs de la relecture laissés (§3) : « 0 / 19 séries validées » en barre oblique, titres d'onglet de Stats de 18 dp au-dessus des groupes, ligne « Calibrage » sur 3 lignes, liste « Où j'en suis » qui ne s'ouvre pas sur la séance choisie, « Poids du corps » / « Poids de corps », « 0 badge » / « 0 badges », nom des pastilles de palette lu seulement par TalkBack.
- Tour, partie e (320 dp × 200 %) : les écrans de séance après le bilan restent sur la page « Bilan du jour » (le script ne parvient pas à toucher « Passer » à 200 %) ; ces écrans sont couverts à 320 dp × 200 % par les rendus de test de UI2 (`ui2_seance_capture_test`, `ui2_densite_capture_test`) et par `ui5_navigation_test` (relecture d'une séance).
- Tests de rendu avec la police de test (un carré par caractère) : à 200 %, certaines pages y sont bien plus longues qu'à l'écran (test d'effacement : défilement porté à 120 pas).
- Temps d'image non mesurés (`docs/PERFORMANCE.md`) : le contrôle ne les mesure pas ; APK profile 61,7 Mo (polices +337 Ko depuis UI0, sous le budget de 600 Ko).

## 9. Recommandation (C8, le pilotage décide)

**Valider UI5 et dev6.12.0.** La refonte est intégrée et publiée en avance rapide sur `main` : kit corrigé (titre de sous-page jamais coupé, vérifié jusqu'à 320 dp × 200 % sur émulateur), composants promus et adaptateurs retirés, contrôles du §6 bloquants sur tout `lib/` (0 valeur en dur, 0 menu hors gabarit, illustrations identiques à dev6.11.1), suite complète et 16 cibles émulateur vertes, tour en 6 parties sans contenu sous le dock, parcours du §6.3 tous à la cible, installation par-dessus dev6.11.1 prouvée par test, relecture indépendante traitée.

À présenter au propriétaire pour l'essai sur téléphone : le récapitulatif du §7 (chaque choix se change à un seul endroit), en particulier l'interrupteur en `encre`, le pas à pas sous le libellé, la feuille de contenu avec « Fermer », l'arrondi au quart de kilo, et la différence de durée entre la carte du jour et la feuille de la séance (§8).

Gel des lancements (C16, U0.23 « gel ») : aucune suite n'est lancée par ce lot ; les suites ci-dessous sont des propositions pour la reprise du 15/10.

Suites proposées hors refonte : un lot « contenu » pour les textes des données (titres de séance en capitales, consignes à préfixes en capitales) ; une décision sur la durée affichée (même estimation partout) ; la mesure des temps d'image (`docs/PERFORMANCE.md`).
