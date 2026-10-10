# Cahier des charges — Refonte UI et UX de Kalis Track : finition, cohérence et menus (lots UI0 à UI5)

10/10/2026 · propriétaire : Gaël · rédigé par la conversation de pilotage · **version 3** (11:41) : ajoute l'arborescence des menus (§4, validée par le propriétaire) et les rayons définitifs (§5.3) à la version 2 (finition sans changer la navigation ; la version 1, qui la changeait, a été écartée).
Maquettes de référence (canevas : chaque écran actuel à côté de sa version finie, palettes, capitales et rayons réglables ; planche « Où trouver quoi ») : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J — sources dans `pipeline/ui/maquettes/`. En cas d'écart entre une maquette et ce cahier, ce cahier tranche ; `DECISIONS_UI.md` tranche sur les deux.

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
| 10:11 | La dominante de la première palette est `#551515` : à respecter exactement (§5.1) |
| 10:26 à 10:52 | Angles plus arrondis, « uniformes, que rien ne se détache du reste » ; puis moins prononcés pour les menus en liste et pour les cartes (§5.3) |
| 11:20 | Le dock lui convient tel quel. « Que les menus soient cohérents, qu'il n'y en ait pas 400 000, et que quand on cherche quelque chose on arrive assez facilement à s'y rendre » (§4) |
| 11:41 | Valide l'arborescence (§4.1), Apparence en sous-page, Records branché dans Stats |

Ce cahier décrit donc **une finition**, pas une nouvelle application : mêmes écrans, même navigation, mêmes parcours, mêmes contenus, mêmes illustrations ; un seul système visuel appliqué partout, des incohérences corrigées, et un modèle unique pour tous les menus.

## 1. Ce qui ne change pas

- **Navigation** : dock flottant à 4 onglets (Arsenal, Stats, Programme, Réglages), ouverture sur Programme, ordre et noms inchangés, libellé sur l'onglet actif seulement (choix du propriétaire, 11:20).
- **Écrans et parcours** (seules les entrées des menus bougent, selon §4.1 et §4.3) : accueil (niveau, semaine, liste des jours, carte du jour), Mon programme, Ma saison, Jour J, Évolution, programme d'origine, bloc suivant ; séance (Bilan du jour, pages d'exercices, chronos, fin de séance, récompenses) ; Stats (onglets) ; Arsenal ; Réglages ; parcours de création du profil et départ du programme. Même ordre des étapes, mêmes actions, mêmes textes sur le fond (seules la forme et la clarté changent).
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
| C11 | Réglages : « Apparence » réglée sur la racine, les autres rubriques en sous-pages ; sous-pages sans titre en page | Modèle de menu unique (§4) : la racine liste toutes les rubriques (recherche, carte Profil, deux groupes) ; « Apparence » devient une rubrique comme les autres, en tête du groupe Application (U11) ; chaque sous-page porte son titre (R3). |
| C12 | Valeurs simples réglées par dialogue | Réglage en place : interrupteur, pas à pas, segments ; dialogue seulement pour confirmer une action destructrice ou irréversible. |
| C13 | Cibles tactiles sous 48 dp (icônes de la barre d'outils de série, puces) | ≥ 48 dp partout. |
| C14 | Placement de la mascotte | Rien à corriger (§1) : placements et poses conservés. |

## 4. Menus : une place par chose, un seul modèle

Demande du propriétaire (11:20) : « que les menus soient cohérents, qu'il n'y en ait pas 400 000, et que quand on cherche quelque chose on arrive assez facilement à s'y rendre » ; le dock lui convient tel quel. Arborescence validée le 10/10/2026 à 11:41 (U10 à U12). Planche de référence : « Où trouver quoi » (`maquettes/Arbo.dc.html`). Inventaire complet de l'existant, avec fichier:ligne de chaque entrée, doublon et incohérence : `inputs/inventaire_navigation.md` (lu par chaque lot pour sa zone).

### 4.0 Constat (main b7996b3f)

Plus de 90 pages, environ 60 feuilles, plus de 25 dialogues, 8 menus déroulants ; une trentaine de fonctions joignables à plusieurs endroits sous des noms différents (Références : 5 entrées, 4 noms ; mode assisté / libre : 2 endroits, 2 formes ; objectif de la semaine : 2 contrôles aux valeurs différentes) ; Mon programme, Ma saison et Évolution rangés dans Réglages › Programme (3 à 5 appuis) ; 7 textes qui écrivent un chemin sans lien, souvent faux (« Réglages › Profil ») ; aucune recherche dans les réglages ni sur les muscles ; fiche d'exercice injoignable depuis la séance ; 6 culs-de-sac.

### 4.1 Arborescence cible

Les 4 onglets, leur ordre, leurs noms et l'ouverture sur Programme ne changent pas. Les écrans existants restent ; seul l'endroit d'où on les ouvre change quand ce tableau le dit.

| Onglet | Contenu (dans l'ordre d'affichage) |
| --- | --- |
| **Programme** | Accueil : en-tête (niveau, semaine), barre de saison, jours, carte du jour, cartes du moment (reprendre, évolution, tests guidés, profil à compléter). **Ligne « Mon programme »** (gabarit `KMenuRow`, toujours visible après la liste des jours, sous-titre « Saison, évolution, calendrier, changer de programme »). Mon programme : en-tête « Mon programme » et une phrase (modèle de programme) ; carte **Ma saison** (› Jour J) ; carte **Évolution** (mode assisté ou libre, historique) ; groupe **Calendrier** : « Départ du programme » (page actuelle de `program_start.dart`), « Où j'en suis » ; groupe **Changer de programme** : « Préparer le bloc suivant » (quand il est proposé, programme importé compris), « Créer un nouveau programme », « Revenir à un programme précédent » ; groupe **Aide** : « Comment marche ton programme ? ». |
| **Séance** (ouverte depuis un jour) | Pages d'exercice ; liste des exercices (feuille de liste) ; ⓘ d'un exercice : consignes **et bouton « Voir la fiche »** (fiche d'Arsenal). Menu ⋮ (feuille d'actions) : groupe 1 « Consignes de séance », « Bilan du jour », « J'ai seulement… minutes », « Je m'entraîne ailleurs » ; groupe 2 « Douleur ou malaise ? » (ouvre le Bilan du jour détaillé **sur la section Douleur**, avec un lien « Conseils de sécurité »), « Mes références » ; groupe 3 (danger) « Supprimer l'historique de cette séance » (confirmation). Fin de séance › récompenses. |
| **Arsenal** | Recherche directe « Exercice ou muscle » : résultats groupés « Exercices » puis « Muscles » ; « Exercices » (filtres, liste, fiche) ; « Anatomie » (groupes, carte, vues). Fiche › section Muscles : chaque groupe ouvre l'Anatomie sur ce groupe (`AnatomyScreen.initialGroup`) ; Anatomie › groupe : bouton « Exercices pour ce muscle » (liste filtrée). La galerie de Koach quitte l'Anatomie (→ Aide et à propos). |
| **Stats** | Aperçu (résumé ; ses tuiles ouvrent l'onglet concerné, jamais une feuille déjà joignable ailleurs) ; Parcours (seule entrée des feuilles personnage, défis, campagne, boss, saisons, titres) ; Performances (« Mes références », raccourci ; **« Records »**, page `records_screen.dart` branchée) ; Historique (recherche ; séance › ⋮ « Corriger les saisies », « Supprimer de l'historique »). |
| **Réglages** | Grand titre et phrase ; **recherche « Rechercher un réglage »** ; **carte Profil** (prénom, « Profil, mes références, tests guidés, santé ») ; groupe **Application** : « Apparence » (thème, palette, contraste renforcé ; section « Anatomie et 3D » : nom du muscle au toucher, halo), « Séance » (sections Chronomètres, Fin du repos, Saisie des séries, Écran et unités), « Notifications » (rappel et son heure, options Android), « Progression et jeu » (célébrations, objectif de la semaine) ; groupe **Plus** : « Données et confidentialité » (sauvegardes, copie d'avant la suppression des WOD, anciennes réponses Koach, politique de confidentialité, supprimer les données), « Aide et à propos » (santé et sécurité avec récupération, comment marche ton programme, galerie de Koach, donner mon avis, sources et licences, diagnostic 3D, version une seule fois). |

Profil (page actuelle, `athlete_profile_screen.dart`) : rubriques du profil (sans « Mode assisté ou libre », qui vit dans Évolution ; le parcours de création garde sa question), **« Mes références »** (page actuelle de `pilotage_screen.dart`, renommée), « Tests guidés », « Compléter mon profil » (si des questions restent), santé et accords.

### 4.2 Règles de rangement

| N° | Règle |
| --- | --- |
| R1 | Une seule place par fonction (§4.1). Un raccourci n'est permis que dans la liste R2, porte **le même nom** que sa destination et ouvre **la même page**, dont « Retour » ramène au point de départ. |
| R2 | Raccourcis permis : Mon programme (cartes du moment de l'accueil) ; Mes références (menu ⋮ de la séance, Stats › Performances, charge « à renseigner » de la séance, devenue un lien visible) ; Évolution (carte du moment « tout voir ») ; Tests guidés et Compléter mon profil (cartes du moment) ; Départ du programme (bandeau de l'accueil) ; Objectif de la semaine (carte de Stats, même contrôle et mêmes valeurs que Réglages) ; Santé et sécurité (lien du Bilan du jour) ; fiche d'exercice (ⓘ de la séance, revue de la création, liens de fiche). Tout autre doublon est supprimé. |
| R3 | Le titre d'une page reprend le libellé qui y mène (« Ma saison » partout ; « Politique de confidentialité » ; plus de surtitre « RÉGLAGES » sur les 10 sous-pages). |
| R4 | Tout réglage à 2 appuis au plus de la racine des Réglages (rubriques du profil : 3) ; toute page de Mon programme à 2 appuis au plus de l'accueil ; toute action ⋮ à 2 appuis. |
| R5 | Aucun chemin écrit en toutes lettres : chaque « Réglages › … », « dans Références » devient un bouton vers la destination de §4.1 (liste : inventaire, « Chemins faux »). |
| R6 | Aucun cul-de-sac : chaque état vide ou bloqué propose l'action qui le résout (création sans profil → « Créer mon profil » ; Évolution sans profil ; Ma saison vide ; Bloc suivant indisponible → « Revenir à Mon programme » ; programme terminé → « Créer un nouveau programme » ; « Créer mon programme » désactivé → la raison écrite dessous). |
| R7 | Aucun geste caché sans équivalent visible : résumé d'un jour (appui long) aussi dans la feuille de la semaine (bouton ⓘ par jour) ; choix de semaine (appui long sur le curseur) aussi par « SEMAINE n ▾ ». |
| R8 | Mêmes verbes partout : **Supprimer** (définitif, toujours confirmé, `danger`), **Retirer** (d'une liste), **Annuler** (une action récente). « Revenir à l'ancien programme » et « Revenir à un programme précédent » demandent confirmation (`KConfirm`). |
| R9 | Libellés internes remplacés (§5.6) : « feuille Pilotage », « Pilotage », « révisions LC1 », « programme du moteur », « moteur calibré », « Ancien Koach et adaptations au quotidien », « Données Koach partiellement relues », page « Moteur 3D » (devient « Diagnostic 3D » dans Aide et à propos). Les termes d'entraînement (RIR, 1RM, EMOM, GtG…) restent. |

### 4.3 Déplacements et fusions

| Fonction | Aujourd'hui | Après | Lot |
| --- | --- | --- | --- |
| Mon programme | Réglages › Programme › Mon programme (R+2) ; bouton texte de la carte du moment | ligne permanente de l'accueil (P+1) | UI1 (accueil, Mon programme), UI4 (retrait des Réglages) |
| Départ du programme | Réglages › Programme | Mon programme › Calendrier (même page) ; bandeau de l'accueil inchangé | UI1, UI4 |
| Revenir (ancien programme, programme d'origine) | deux entrées, une sans confirmation | une ligne « Revenir à un programme précédent » : feuille d'actions listant les retours possibles, chacun confirmé ; « Exporter la sauvegarde » dans cette feuille | UI1 |
| Profil | Réglages › Programme › Profil (R+2) | carte en tête des Réglages (R+1) | UI4 |
| Références | Réglages › Programme › Références ; 4 autres entrées, 4 noms | Profil › « Mes références » ; raccourcis R2 | UI4, UI2, UI3 |
| Mode assisté / libre | Évolution (segments) et rubrique du profil (cartes) | Évolution seulement ; textes d'aide corrigés | UI1, UI4 |
| Objectif de la semaine | Réglages (pas à pas 0 à 6) et Stats (puces Adaptatif, 2 à 6) | même contrôle aux deux endroits : segments « Adaptatif, 2, 3, 4, 5, 6 » (une valeur 1 déjà enregistrée est affichée telle quelle jusqu'au prochain choix, sans migration) | UI4, UI3 |
| Saisie des séries, Chronomètres, Pendant la séance | 3 rubriques | rubrique « Séance », 4 sections | UI4 |
| Thème, palette, Affichage 3D | racine des Réglages ; rubrique « Affichage 3D » | sous-page « Apparence » | UI4 |
| Sauvegardes, Koach | 2 rubriques | « Données et confidentialité » | UI4 |
| À propos | fourre-tout, « Récupération » en double, version en double | « Aide et à propos » | UI4 |
| Galerie de Koach | Arsenal › Anatomie (A+2) | Aide et à propos | UI4 |
| Feuilles de jeu de Stats | jusqu'à 3 entrées chacune | Parcours seulement | UI3 |
| Records | promis, page non branchée | Stats › Performances › « Records » | UI3 |
| Douleur en séance | page d'information, déclaration à 5 appuis | Bilan du jour détaillé ouvert sur Douleur (4 appuis) | UI2 |
| Fiche d'exercice en séance | injoignable | ⓘ › « Voir la fiche » (2 appuis) | UI2 |
| Recherche des réglages | — | champ en tête des Réglages | UI0 (composant), UI4 (index) |
| Recherche Arsenal | exercices seulement, depuis Exercices | « Exercice ou muscle », sur la racine d'Arsenal | UI4 |

### 4.4 Recherche

Un seul composant `KSearchField` (UI0) et une seule règle de correspondance, celle de `search.dart` (sans accents ni majuscules, tous les mots, débuts de mots, synonymes).
- **Réglages** : index écrit à la main dans `lib/settings_search.dart` (nouveau, UI4) : pour chaque réglage et chaque page d'aide, libellé, description, mots proches (au moins : repos / récup / pause ; kg / livres / unité ; son / bip ; vibration / vibreur ; thème / sombre / clair ; couleur / palette ; rappel / notification ; sauvegarde / export / import ; profil / poids / taille ; références / 1RM / max), chemin affiché (« Séance › Chronomètres ») et destination. Un résultat ouvre la page et met le réglage en évidence 1,5 s. Test : chaque réglage de §4.1 est trouvé par son libellé et par au moins un mot proche ; aucun résultat ne mène à une page inexistante.
- **Arsenal** : « Exercice ou muscle » ; résultats groupés « Exercices » (moteur actuel) puis « Muscles » (noms et groupes de l'atlas) ; un muscle ouvre l'Anatomie sur son groupe.
- Textes d'aide : « Rechercher un exercice » partout ailleurs, sans nombre écrit en dur.

### 4.5 Gabarits

Toutes les surfaces de choix ou d'action suivent l'un de ces cinq gabarits (maquettes « Réglages », « Réglages › Séance », « Réglages › Apparence », « Réglages › recherche », « Arsenal », « Mon programme », « Menu ⋮ de la séance », « Exercices de la séance »).

| Gabarit | Anatomie | Remplace |
| --- | --- | --- |
| **Menu racine** (`KMenuPage`) | grand titre (capitales selon U3) et une phrase ; recherche (Réglages, Arsenal) ; titres de section ; groupes (rayon `menu`, 20) ; lignes `KMenuRow` : pastille d'icône ronde 40 × 40 (`haute`), titre (16, 600), une ligne de description (13, `texte2`, retour à la ligne permis), valeur ou chevron ; séparateurs entre lignes, en retrait de la pastille | racine des Réglages, Arsenal, Mon programme |
| **Sous-page de menu** | en-tête standard (C1), une phrase, groupes ; réglages en place : interrupteur (`KSwitch`), pas à pas (−, valeur, + séparés de 4), segments | sous-pages des Réglages, Profil, Notifications, Données |
| **Feuille d'actions** (`KActionSheet`) | poignée, titre et contexte (« Séance — Corps entier, S1, J2 »), groupes d'actions (icône + verbe), dernier groupe = actions destructrices en `danger`, bouton « Fermer » | tous les menus ⋮ et `PopupMenuButton` |
| **Feuille de liste** (`KListSheet`) | poignée, titre et résumé (« 7 exercices, 22 min »), lignes numérotées, élément courant en contour `encre`, éléments faits cochés en `validation` | liste des exercices de la séance, choix de semaine, choix d'exercice de remplacement |
| **Confirmation** (`KConfirm`) | titre = question, une phrase de conséquence, « Annuler » et le verbe exact (« Supprimer », « Remplacer », « Revenir ») ; verbe en `danger` si destructeur | dialogues de suppression, import, remplacement et retour de programme |

Inventaire à convertir (49 appels, 23 fichiers) : chaque lot convertit ceux de ses fichiers (§7.2) avec les composants de UI0 et les liste dans sa livraison ; UI5 vérifie qu'il n'en reste aucun hors gabarit (`tools/check_ui_tokens.py --menus`).

Règles de parcours des menus : « Retour » ramène toujours à l'écran d'où l'on vient, à la même position de défilement ; un changement de réglage s'applique tout de suite, sans bouton « Enregistrer » (les rubriques du profil gardent leur « Enregistrer », qui déclenche un recalcul).

### 4.6 Défauts relevés en passant (à corriger dans la zone indiquée)

- **Récompenses sous « Fin de séance »** (probable, lecture du code) : `openProgramDay` appelle `checkLevelUp` dès la fermeture de la séance (`home_screen.dart:68`), avant que `_finish` attende la fin de la transition (`session_screen.dart:3190`). UI1 corrige l'ordre (récompenses après « Fin de séance ») et le prouve par un test d'intégration ; UI2 vérifie dans son tour.
- Choisir un temps ou un lieu dans le ⋮ renvoie à la page 0 au lieu de l'exercice en cours (`session_screen.dart:300,314`) : retour à la page d'où l'on vient (UI2).
- « Vibration en fin de chrono » commande aussi le retour haptique de validation et de record : description corrigée (« Fin de chrono, validation et records »), sans changer le comportement (UI4).
- Descriptions de rubriques fausses ou obsolètes (« effort », « os », « Estimations et propositions de charge ») : réécrites avec l'arborescence (UI4).
- Code mort `StatsLevelCard`, `showStatsLevel` : signalé à UI5, non supprimé par les lots.

## 5. Système de design

Le système vit dans `lib/kit/` (nouveau dossier ; `ui.dart` et la présentation de `app_theme.dart` deviennent des adaptateurs pendant la migration et disparaissent à UI5).

### 5.0 Références : Samsung, Google, Microsoft

| Source | Principe repris | Application |
| --- | --- | --- |
| **Samsung One UI** | Zone de lecture en haut, zone d'interaction en bas, à portée du pouce ; parcours courts ; confort (sombre, tailles de texte) | Grands titres des pages racines ; actions principales et choix en bas ; menus groupés dans des conteneurs arrondis ; grand titre qui se replie au défilement sur les pages racines |
| **Google Material 3 (Expressive)** | Rôles de couleur avec paires « couleur / texte sur la couleur » au contraste garanti (HCT) ; forme, taille et couleur pour hiérarchiser ; mouvement à ressorts. Google annonce 46 études, plus de 18 000 participants, des éléments clés repérés jusqu'à 4 fois plus vite, et des 45 ans et plus aussi rapides que les plus jeunes | Dérivation des palettes (§5.1) avec `material_color_utilities` ; forme pilule pour l'élément sélectionné ; groupes de boutons voisins (−15 s / +15 s, pas à pas : pilules séparées) ; ressorts (§5.5) |
| **Microsoft Fluent 2** | Jetons en couches (globaux, puis alias nommés par leur fonction) qui couvrent clair, sombre, contraste élevé et variantes de marque | Trois couches : globaux (hex des palettes, échelles), alias (`fond`, `surface`, `encre`…), composants ; aucun écran n'utilise un global ; mode « Contraste renforcé » |

Sources : [Samsung One UI](https://developer.samsung.com/one-ui/overview.html) ; [Fluent 2, design tokens](https://fluent2.microsoft.design/design-tokens) ; [Android Authority, Material 3 Expressive](https://www.androidauthority.com/google-material-3-expressive-details-3554486/) ; [Material 3 Expressive, Android Developers](https://developer.android.com/design/ui/wear/guides/get-started/apply).

### 5.1 Couleurs

**Les 8 palettes du propriétaire remplacent les 6 couleurs de L5.** Chaque palette : dominante, secondaire, accent, fond sombre, fond clair. Thème clair / sombre / système indépendant de la palette.

**Dérivation** (`lib/kit/palette.dart`, test qui retrouve `inputs/palettes_roles.json` à l'identique) : la valeur du propriétaire est gardée telle quelle quand elle passe le contraste de son rôle ; sinon on garde sa teinte et sa chroma (HCT) et on ne déplace que sa tonalité, du plus petit pas (0,5) suffisant.
- `fond` = fond du propriétaire. Sombre : `surface`, `haute`, `filet` = même teinte, chroma ≤ 16, tonalité + 5, + 10, + 15. Clair : `surface` blanc, `haute` = fond, `filet` = tonalité − 10.
- `texte` (tonalité 95 / 10), `texte2` (70 / 40), `texte3` (50 / 60, inactif seulement), teinte du fond, chroma ≤ 6.
- `pleine` (bouton principal, jour courant, onglet actif, carte du jour, pastille de semaine) = **dominante exacte du propriétaire, en clair comme en sombre, jamais ajustée** (décision du 10/10/2026, 10:11). Seul le texte posé dessus s'adapte : `surPleine` = blanc ou `#121212`, le plus contrasté (≥ 4,5:1 vérifié pour les 8 palettes).
- La dominante n'est **jamais** utilisée comme couleur de texte ou d'icône sur fond sombre quand elle y est illisible (`#551515` sur `#222223` : 1,6:1) ; ce rôle est celui d'`encre`.
- `encre` (élément courant, repère, chiffre mis en avant, lien) = dominante ajustée à ≥ 4,5:1 sur `surface` (et sur `fond` en clair).
- `second` (données, barres secondaires) = secondaire ajustée à ≥ 3:1. `accent` (records, réussites, Jour J) = accent ajusté à ≥ 4,5:1.
- **Contraste renforcé** : mêmes règles à 7:1 (et 4,5:1 au lieu de 3:1).

| Palette (identifiant) | Source : dominante / secondaire / accent / fond sombre / fond clair | Sombre : pleine / texte sur pleine / encre / second / accent / surface | Clair : pleine / texte sur pleine / encre / second / accent |
| --- | --- | --- | --- |
| Bordeaux Performance (`bordeaux`, **défaut**) | `#551515` / `#8E3030` / `#D9A66C` / `#181819` / `#F6F2EF` | `#551515` / `#FFFFFF` / `#CA6F6A` / `#B24B49` / `#D9A66C` / `#222223` | `#551515` / `#FFFFFF` / `#551515` / `#8E3030` / `#916632` |
| Obsidian Energy (`obsidian`) | `#E5484D` / `#FF8566` / `#FFC857` / `#121316` / `#F2F3F5` | `#E5484D` / `#121212` / `#EA4C50` / `#FF8566` / `#FFC857` / `#1C1D20` | `#E5484D` / `#121212` / `#CD363D` / `#E67254` / `#906800` |
| Arctic Motion (`arctic`) | `#2563EB` / `#4F9CF9` / `#14B8A6` / `#152238` / `#F5F8FC` | `#2563EB` / `#FFFFFF` / `#668EFF` / `#4F9CF9` / `#14B8A6` / `#242D3D` | `#2563EB` / `#FFFFFF` / `#2563EB` / `#4795F2` / `#008073` |
| Neon Athlete (`neon`) | `#B4F044` / `#67D8C0` / `#8C72FF` / `#101510` / `#F2F9EA` | `#B4F044` / `#121212` / `#B4F044` / `#67D8C0` / `#8C72FF` / `#1A1F1A` | `#B4F044` / `#121212` / `#567B00` / `#2BA690` / `#7458E4` |
| Titanium Pro (`titanium`) | `#4C6474` / `#8A9DA8` / `#D5A24C` / `#171E24` / `#E8EDF0` | `#4C6474` / `#FFFFFF` / `#7992A3` / `#8A9DA8` / `#D5A24C` / `#21282F` | `#4C6474` / `#FFFFFF` / `#4C6474` / `#8396A1` / `#8E6310` |
| Violet Momentum (`violet`) | `#7546DB` / `#AC8CFA` / `#29BFB0` / `#181427` / `#F5F1FF` | `#7546DB` / `#FFFFFF` / `#986CFF` / `#AC8CFA` / `#29BFB0` / `#221E31` | `#7546DB` / `#FFFFFF` / `#7546DB` / `#A181EE` / `#007D71` |
| Forest Endurance (`forest`) | `#236B50` / `#7BAC81` / `#D7B374` / `#17251D` / `#F4F5EE` | `#236B50` / `#FFFFFF` / `#5CA283` / `#7BAC81` / `#D7B374` / `#213027` | `#236B50` / `#FFFFFF` / `#236B50` / `#6FA076` / `#886B32` |
| Solar Sprint (`solar`) | `#D95A27` / `#FF9760` / `#E8BC49` / `#211B1A` / `#FFF6ED` | `#D95A27` / `#121212` / `#E86531` / `#FF9760` / `#E8BC49` / `#2C2524` | `#D95A27` / `#121212` / `#C34A17` / `#DC7B46` / `#8F6D00` |

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
- Rayons (choix du propriétaire, 10:26 à 10:52 : uniformes, que rien ne se détache ; ni trop ni trop peu prononcés) — trois familles, seules valeurs :
  - **cartes** 24 : cartes de contenu, carte du jour, tuiles de ressenti, barre de repos, haut des feuilles ;
  - **menus** 20 : groupes de lignes (menus, réglages, phases, tableau des séries, lignes de jour) et lignes surlignées qu'ils contiennent ;
  - **commandes** pilule (moitié de la hauteur) : boutons, champs, puces, segments et leur choix, interrupteurs, recherche, dock et onglet actif, barres de progression, pastilles, tuiles d'icône (rondes) ; un groupe de boutons voisins (−15 s / +15 s, −, valeur, +) = pilules séparées de 4, jamais de coins intérieurs carrés ;
  - un élément ne change jamais de forme quand il est sélectionné (seule la couleur change).
- Aucune ombre ; profondeur par la surface (`fond` < `surface` < `haute`) ; contour 1,5 dp `encre` pour l'élément courant.
- Cibles ≥ 48 dp ; bouton principal 56 dp.

### 5.4 Composants (`lib/kit/`)

`KTokens` (jetons, `ThemeExtension`), `KPage` (racine à grand titre ou sous-page), `KTopBar` (C1), `KDock` (dock flottant actuel, fini : hauteur 64, pilule de l'onglet actif en `pleine`, libellé de l'onglet actif seulement), `KCard` (principale rayon 24, carte du jour pleine), `KDayRow` (ligne de jour : numéro, titre, état), `KSeasonBar` (barre de saison par blocs, repère de la semaine), `KMenuGroup` / `KMenuRow`, `KSwitch`, `KStepper`, `KSegmented`, `KActionSheet`, `KListSheet`, `KConfirm`, `KChip` (neutre), `KPrimaryButton` / `KTonalButton` / `KTextButton`, `KSetTable` (tableau des séries : en-tête, ligne courante, champs, validation), `KRestBar` (barre de repos flottante, groupe −15 s / +15 s, arrêt), `KSnack` (message court, Koach compris), `KSearchField` (§4.4), `KNotice` (bandeau dans le flux), `KTimeline` (frise des phases), `KEmpty`. Les widgets d'illustration (`KalisLogo`, `KoachView`, `MuscleBody`, carte 2D, mannequin) sont **utilisés tels quels**.

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

Aucun parcours ne gagne d'appui (relevé avant / après par le tour de captures) ; règles R4 (§4.2). Cibles relevées par le tour :

| Pour… | Avant | Cible |
| --- | --- | --- |
| Ouvrir Mon programme depuis l'accueil | 3 (par Réglages) | 1 |
| Ma saison, Évolution | 4 | 2 |
| Jour J | 5 | 3 |
| Un réglage précis | rubrique à deviner | 2 par la recherche ; 2 par les rubriques |
| Fiche d'exercice pendant la séance | impossible | 2 |
| Exercices d'un muscle | impossible | recherche directe ou 3 |
| Signaler une douleur pendant la séance | 5 | 4 |
| Mes références | 2 à 4 selon l'entrée, 4 noms | 2 depuis Réglages, 2 depuis la séance, même page |

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
| UI4 Menus | `settings_screen.dart`, `notification_settings.dart`, `data_control.dart`, `pilotage_screen.dart`, `wellbeing_screens.dart`, `retired_notice_screen.dart`, `startup.dart`, `arsenal_screen.dart`, `exercise_screens.dart`, `atlas.dart`, `anatomy_screen.dart` (conteneur), `athlete_profile*.dart`, `profile_completion.dart`, `settings_search.dart` (nouveau), `guided_tests.dart`, `program_start.dart`, `plan/plan_screens.dart`, `plan/plan_creation.dart`, `koach/koach_gallery_screen.dart` (conteneur) |
| UI5 Intégration | tout, en fin de parcours |

Non listés (`dev/**`, `plan/plan_inspector.dart`, `animation_test_screen.dart`, mannequin, moteur 3D, peintres de pose, `koach/koach_view.dart`, `koach/flame_icon.dart`) : intouchables ou liste blanche ; UI5 traite ce qui reste.

### 7.3 Contenu des lots

**UI0 — Fondations** (seul, prérequis des quatre suivants) : branche et workflow de contrôle parallèle ; polices ; jetons trois couches, palettes (§5.1) et contraste renforcé, sélecteur de palette et interrupteur dans Apparence, relecture des anciens identifiants ; tous les composants de §5.4 avec test et captures (sombre, clair, `bordeaux`, `neon`), catalogue en mode dev ; dock fini (C8, sans changer les onglets) ; adaptateurs pour que tous les écrans compilent et prennent déjà palettes et polices ; `check_ui_tokens.py` (`--zone`, `--menus`, relevé de départ) ; tour de captures (squelette, tous les écrans principaux) et relevé des parcours sur dev6.11.1 ; mode d'emploi du kit dans la livraison.

**UI1 — Programme** (parallèle) : accueil (maquette « Accueil ») : en-tête niveau / semaine / logo sans troncature, barre de saison par blocs à la place de la frise de points, lignes de jour, carte du jour (Koach et anatomie inchangés), bandeaux dans le flux, **ligne « Mon programme »** ; Mon programme au gabarit de menu racine (§4.1 : Ma saison, Évolution, Calendrier, Changer de programme, Aide ; « Revenir à un programme précédent » confirmé), Ma saison (frise des phases), Jour J, Évolution (segments, seul réglage du mode), bloc suivant, position dans le programme ; culs-de-sac de la zone (R6), gestes cachés (R7), chemins écrits (R5), ordre des récompenses (§4.6) ; leurs feuilles et menus au gabarit de §4.

**UI2 — Séance** (parallèle) : Bilan du jour (plus de carte dans une carte, Koach et les 5 poses du ressenti inchangés), pages d'exercices (en-tête, puces neutres, consigne, notes et calibrage en deux lignes ouvrables, tableau des séries, barre d'outils de série ≥ 48 dp), série validée et barre de repos, message de Koach au-dessus, chronos de mode (EMOM, intervalles, tenues, groupes, mini-séries), fin de séance et récompenses, historique d'une séance passée, cartes de douleur et d'avis médical (même logique, même blocage) ; menu ⋮ de la séance en feuille d'actions (§4.1 : « Mes références », « Douleur ou malaise ? » ouvert sur la section Douleur, « Supprimer l'historique de cette séance »), ⓘ avec « Voir la fiche », charge « à renseigner » en lien visible, retour à l'exercice en cours après un choix de temps ou de lieu (§4.6) ; liste des exercices en feuille de liste.

**UI3 — Stats** (parallèle) : onglets, cartes et graphiques au système (données en `second` / `encre` / `accent`), historique, carte musculaire dans son conteneur ; une seule entrée par feuille de jeu (Parcours) ; « Records » branché dans Performances ; « Mes références » et objectif de la semaine en raccourcis R2 ; menus et feuilles au gabarit.

**UI4 — Menus** (parallèle) : Réglages à l'arborescence de §4.1 (recherche et son index `settings_search.dart`, carte Profil, rubriques Apparence, Séance, Notifications, Progression et jeu, Données et confidentialité, Aide et à propos ; mêmes réglages qu'aujourd'hui, aucun perdu : tableau réglage par réglage avant → après), Profil (Mes références, tests guidés, santé ; sans la rubrique du mode), Arsenal (recherche « Exercice ou muscle », Exercices, Anatomie, liens fiche ⇄ Anatomie), bibliothèque et fiche d'exercice, profil et parcours de création (une question par écran, « Continuer » en bas, segments de progression, « Passer »), départ du programme, données (export, import, suppression : confirmations au gabarit), écrans d'aide, démarrage et erreurs de lancement, galerie de Koach (conteneur).

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

## 9. Décisions

| N° | Décision |
| --- | --- |
| U1 | Navigation, écrans, parcours et contenus inchangés ; finition seulement. |
| U2 | Illustrations de Koach, logo et anatomie intouchables (§1). |
| U3 | Capitales conservées pour les titres (style actuel), appliquées uniformément par le style ; réglable en un jeton si le propriétaire préfère les minuscules (interrupteur « capitales » des maquettes). |
| U4 | Police Barlow, embarquée. |
| U5 | Les 8 palettes du propriétaire remplacent les 6 couleurs ; Bordeaux Performance par défaut ; **dominantes exactes partout pour les aplats** (correction du propriétaire, 10:11) ; texte noir sur les boutons d'Obsidian, Solar et Neon (le blanc y serait illisible) ; seules les couleurs de texte et d'icône dérivées (`encre`, `second`, `accent`) sont ajustées en tonalité quand le contraste l'exige. |
| U6 | Mode « Contraste renforcé » ajouté dans Apparence. |
| U7 | Frise de 40 points de l'accueil remplacée par une barre de saison par blocs (même information). |
| U8 | Un seul modèle pour tous les menus (§4) ; menus ⋮ en feuilles d'actions. |
| U9 | Refonte avant le lot CI final et la base v1.1 ; version publiée dev6.12.0. |
| U10 | Arborescence des menus de §4 : une place par chose, raccourcis limités à R2, recherche dans les Réglages et sur les muscles ; rubrique « Programme » des Réglages répartie entre Mon programme (onglet Programme) et Profil (tête des Réglages). **Validée par le propriétaire (11:41).** |
| U11 | Thème et palette dans la sous-page « Apparence » (1 appui de plus, racine plus simple, retrouvés par la recherche). **Validée (11:41).** |
| U12 | « Records » branché dans Stats › Performances (page existante). **Validée (11:41).** |
| U13 | Rayons : cartes 24, menus 20, commandes en pilule (§5.3). Retenus par le propriétaire après essais (10:26 à 10:52). |

U1 à U9 : choix du pilotage présentés dans les maquettes depuis 09:50 ; le propriétaire les confirme en donnant le feu vert du lancement (LANCEMENTS.md). U5 (dominante exacte) est déjà sa correction (10:11).
