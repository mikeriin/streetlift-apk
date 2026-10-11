# Kalis Track — Refonte UI et UX (dev6.12.0)

Mise à jour : 11 octobre 2026. Version **6.12.0+116**, affichée « dev6.12.0 ». Pipeline « Refonte UI et UX » (lots UI0 à UI5) : cahier `pipeline/ui/CAHIER_UI.md` (version 3), décisions `pipeline/ui/DECISIONS_UI.md`, livraisons `pipeline/ui/livraisons/` (branche `pipeline`). L'ancien registre de la refonte L5 (3.0.2, six couleurs) est conservé dans `docs/REFONTE_UI_L5.md`.

Demande du propriétaire (10/10/2026) : « quelque chose de propre qui ne fait pas brouillon », « garder le même principe de l'UI/UX présente mais que ça soit fini », « refonds tous les menus », sans toucher aux illustrations de Koach, du logo et de l'anatomie musculaire. La refonte est donc **une finition** : mêmes écrans, même navigation (dock à 4 onglets, ouverture sur Programme), mêmes parcours et mêmes contenus ; un seul système visuel, des incohérences corrigées et un seul modèle de menus.

Téléphone : **à valider par le propriétaire** (aucun lot n'a été essayé sur un appareil ; contrôles sur émulateur et rendus de test).

## 1. Ce qui a changé, en bref

| Domaine | Avant (dev6.11.1) | Après (dev6.12.0) |
| --- | --- | --- |
| Couleurs | 6 couleurs dominantes (rouge par défaut) | 8 palettes du propriétaire (Bordeaux Performance par défaut, dominantes exactes pour les aplats), « Contraste renforcé » dans Apparence ; anciens choix relus vers la palette la plus proche |
| Police | Police système | Barlow embarquée (texte, titres semi-condensés, chiffres condensés tabulaires) |
| Formes | 12 rayons différents | Cartes 24, menus 20, commandes en pilule ; un élément ne change jamais de forme quand il est choisi |
| En-têtes | Trois sortes | Page racine : grand titre et une phrase ; sous-page : retour, titre jamais coupé, au plus une action |
| Menus | 49 appels sans modèle (menus déroulants, feuilles, dialogues) | Cinq gabarits : menu racine, sous-page, feuille d'actions, feuille de liste, confirmation ; plus une feuille de contenu |
| Arborescence | Mon programme, Ma saison, Évolution dans Réglages › Programme ; Références sous 4 noms ; fonctions en double | « Une place par chose » (cahier §4.1) : ligne « Mon programme » sur l'accueil, carte Profil en tête des Réglages, « Mes références », recherche dans les Réglages et sur les muscles |
| Textes | Chemins écrits (« Réglages › Profil »), libellés internes (« feuille Pilotage ») | Boutons vers la destination, noms de page repris par les libellés |
| Formats | « ≥ 22 min », « 600 s », « 62.5 » | « au moins 22 min », « 10 min », « 62,5 », espace fine avant l'unité |

## 2. Où trouver quoi (arborescence, cahier §4.1)

- **Programme** : accueil (niveau, semaine, barre de saison par blocs, jours, carte du jour, cartes du moment), puis la ligne **« Mon programme »** : Ma saison (› Jour J), Évolution (mode assisté ou libre), Calendrier (Départ du programme, Où j'en suis), Changer de programme (bloc suivant, nouveau programme, revenir à un programme précédent), Aide.
- **Séance** : pages d'exercice, liste des exercices, ⓘ › « Voir la fiche » ; menu ⋮ : consignes, Bilan du jour, temps et lieu, « Douleur ou malaise ? », « Mes références », « Supprimer l'historique de cette séance ».
- **Arsenal** : recherche « Exercice ou muscle », Exercices, Anatomie (liens fiche ⇄ Anatomie).
- **Stats** : Aperçu, Parcours (seule entrée des feuilles de jeu), Performances (Mes références, Records), Historique. Un état vide propose « Ouvrir le programme ».
- **Réglages** : recherche « Rechercher un réglage », carte Profil (Mes références, tests guidés, santé), Apparence, Séance, Notifications, Progression et jeu, Données et confidentialité, Aide et à propos (dont « Compatibilité 3D »).

## 3. Système de design (`lib/kit/`)

Un seul import : `import 'kit/kit.dart';`. Aucun écran n'écrit de valeur de présentation en dur (contrôle `tools/check_ui_tokens.py --zone UI5 --menus` à 0 sur tout `lib/`, hors liste blanche : illustrations, mannequin et moteur 3D, outils du mode dev).

| Couche | Contenu |
| --- | --- |
| Globaux | `palette.dart` (8 palettes, dérivation HCT), `tokens.dart` (`KSpacing`, `KRadius`, `KSize`, `KFont`, `KType`, `KMotion`) |
| Alias | `KTokens.of(context)` : `fond`, `surface`, `haute`, `filet`, `texte`, `texte2`, `texte3`, `pleine`, `surPleine`, `encre`, `second`, `accent`, `validation`, `danger`, `avertissement` |
| Composants | Pages (`KPage.root`, `KPage.sub`, `KMenuPage`, `KTopBar.sub`, `KScaffold`, `KPageList`), menus (`KMenuGroup`, `KMenuRow`, `KSwitchRow`, `KStepperRow`, `KSegmentedRow`), réglages en place (`KSwitch`, `KStepper`, `KSegmented`), actions (`KPrimaryButton`, `KTonalButton`, `KTextButton`, `KIconButton`, `KActionRow`), feuilles (`showKActionSheet`, `showKListSheet`, `showKContentSheet`, `showKConfirm`, `showKChoice`), surfaces (`KCard`, `KNotice`, `KEmpty`, `KChip`, `KMeter`, `KStatTile`, `KTileGrid`), programme (`KDayRow`, `KSeasonBar`, `KTimeline`, `KWhyTile`), séance (`KSessionHeader`, `KProgressDots`, `KSetTable`, `KRestBar`, `KSnack`, `KBottomInset`), recherche (`KSearchField`), dock (`KDock`), formats (`format.dart`) |

Formats (`lib/kit/format.dart`) : nombres à virgule, espace fine insécable avant l'unité, secondes au-delà de 90 s en minutes, « au moins n min », lecture d'une charge saisie avec la virgule ou le point. Le journal enregistre toujours les mêmes nombres.

`lib/app_theme.dart` ne garde que les rôles de couleur lus par les illustrations et les peintres de données (`SL`, `KPalette`, `KAccentSpec`, `buildTheme`), qui ne peuvent pas changer d'API ; l'ancien adaptateur des écrans (`lib/ui.dart`) est supprimé.

## 4. Revenir sur un choix (réglages du système)

Chaque choix pris sans le propriétaire se change à un seul endroit :

| Choix | Où le changer |
| --- | --- |
| Capitales des titres | `kCapsTitles` (`lib/kit/tokens.dart`) |
| Rayons (24 / 20 / pilule) | `KRadius` (`lib/kit/tokens.dart`) |
| Palette par défaut, dérivation | `kDefaultPaletteId`, `KRoles.of` (`lib/kit/palette.dart`) |
| Logo en `encre` en thème clair | rôle du logo dans `lib/app_theme.dart` (`SL`) |
| Dock à 96 % d'opacité avec flou | `lib/kit/dock.dart` |
| Titres de feuille en casse normale | `KSheetHeader` (`lib/kit/sheets.dart`) |
| Pas à pas sous le libellé sous 420 dp | `KSize.stepperRowMin` (`lib/kit/tokens.dart`) |
| Arrondi d'affichage des charges proposées (0,25 kg) | `kAdaptKgDisplayStep` (`lib/adapt/adapt_texts.dart`) |
| Formats (espace fine, minutes au-delà de 90 s) | `lib/kit/format.dart` |

Le récapitulatif complet des décisions est dans `pipeline/ui/livraisons/LIVRAISON_UI5.md` (branche `pipeline`).

## 5. Contrôles

| Contrôle | Outil |
| --- | --- |
| Jetons et menus hors gabarit, tout `lib/` | `python3 tools/check_ui_tokens.py --zone UI5 --menus` (0) ; test `tools/tests/test_ui_illustrations.py` |
| Illustrations intactes (Koach, logo, anatomie) | `python3 tools/check_ui_illustrations.py` : 89 fichiers identiques à dev6.11.1 |
| Kit | `test/ui0_kit_test.dart`, `test/ui5_kit_test.dart` (titres jamais coupés, 48 dp, contraste du dock) |
| Écrans | `test/ui1_*` à `test/ui4_*`, `test/ui5_*` (formats, navigation, installation par-dessus dev6.11.1) |
| Tour sur émulateur | `integration_test/tour_ui_test.dart` (`tools/ci_ui_drive.sh`), parties a à f : sombre et clair, Bordeaux et Neon, sessions personnelle et de test, 320 dp × 200 %, 8 palettes et contraste renforcé ; même tour sur dev6.11.1 pour la colonne « avant » |
| Contrôle complet | `.github/workflows/ci-ui.yml` sur `claude/ci-ui-<lot>` |

## 6. Données

Aucun format de sauvegarde, aucune clé de préférence et aucune logique ne changent. Seul ajout depuis UI0 : le réglage `contrast`, écrit seulement s'il est actif. Une installation par-dessus dev6.11.1 relit la sauvegarde à l'identique, les préférences, et l'ancienne couleur (rouge → Bordeaux, jaune → Neon, vert → Forest, violet → Violet, orange → Solar, turquoise → Arctic) ; preuve : `test/ui5_installation_test.dart`.
