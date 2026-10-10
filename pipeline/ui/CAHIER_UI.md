# Cahier des charges — Refonte UI et UX de Kalis Track (lots UI0 à UI5)

10/10/2026 · propriétaire : Gaël · rédigé par la conversation de pilotage à la demande du propriétaire (« faire une refonte de l'UI pour avoir quelque chose de propre qui ne fait pas brouillon », « l'UI et l'UX »).
Maquettes de référence (canevas, 8 écrans, les 8 palettes réglables par l'onglet de réglages de chaque écran) : https://claude.ai/artifact/2YmgbXjKpPzX75sPccDN3J — en cas d'écart entre une maquette et ce cahier, ce cahier tranche ; `DECISIONS_UI.md` tranche sur les deux.

## 1. Constat

Relevé sur `main` b7996b3f (dev6.11.1) : 72 captures émulateur de `claude/ci-3d` (run 37946602412) et mesure du code de `lib/`.

| Symptôme | Mesure ou exemple |
| --- | --- |
| Pas d'échelle typographique | 27 tailles de police littérales différentes (177 occurrences), 5 graisses, 9 valeurs d'interlettrage |
| Pas d'échelle de formes ni d'espacement | 12 rayons d'angle différents, 231 `EdgeInsets` littéraux |
| Couleurs hors thème | 83 `Color(0x…)` littéraux hors `app_theme.dart` |
| Composants contournés | 98 `Card(` bruts à côté de 175 `KCard(` ; 34 `BoxDecoration` faites main |
| Murs de texte | « Mon programme » : 3 cartes de 4 à 6 lignes chacune avant toute action ; séance : 5 types d'information au-dessus de la saisie (puces, titre rouge en capitales, consigne, notes du coach, ligne de calibrage) |
| Capitales et troncatures | titres en capitales (`MON PROGRAMME`, `CORPS ENTIER`), 28 `toUpperCase()` ; titres coupés (`TEST MAX TRACTIONS A…`, `PUISSANCE MU + SQUAT ENDURAN`, `Bloc …`) |
| Hiérarchie plate | tout a le même poids : liens rouges, puces cerclées, cartes dans des cartes (page « Bilan du jour ») |
| Navigation | l'écran principal est le 3e onglet sur 4 ; « Arsenal » ne contient que deux tuiles ; « Réglages » occupe un onglet entier ; « Mon programme », « Ma saison », « Évolution » et « Ton programme d'origine » sont rangés dans Réglages |
| Recouvrements | dock flottant posé sur le contenu (bandeau « Nouveau : 11 questions pour… » coupé derrière lui) ; poignée « DEV » sur le bord droit de chaque écran |
| Bruit visuel | frise de 40 points de semaines sur l'accueil ; mascotte de Koach répétée en décoration dans plusieurs cartes d'un même écran |

Ce qui marche et reste : le thème clair/sombre/système, le choix de couleur par l'utilisateur (L5, désormais sur les 8 palettes du propriétaire, §4.1), le tableau des séries, les chronos de mode, les contrôles de taille de texte (L5 : 320 px, 200 %).

## 2. Objectifs

1. **Propre** : un seul système de design appliqué partout, aucun style écrit à la main dans un écran.
2. **Lisible à bout de bras, entre deux séries** : chiffres grands, une information par ligne, les explications derrière un appui.
3. **Rapide** : moins d'appuis pour faire une séance (§5.4).
4. **Une seule voix pour Koach** : une phrase à la fois, au bon endroit.
5. **Grand public** : un débutant comprend chaque écran sans connaître le vocabulaire du street ; l'expert garde toute l'information, un appui plus loin.

Hors périmètre : les moteurs (`packages/`), les données (`store.dart`, sauvegarde, migrations — aucun changement de format), le contenu des programmes, la base d'exercices v1.1 (lot à part, qui s'appuiera sur ce système), le mannequin 3D et les animations (chantiers suspendus), le système XP/niveau/Krédits (G11-G15 suspendus : on garde ce qui s'affiche aujourd'hui, restylé).

## 3. Architecture de l'application (UX)

### 3.1 Navigation

Barre du bas fixe (plus de dock flottant), quatre onglets, l'application s'ouvre sur **Aujourd'hui** :

| Onglet | Contenu | Vient de |
| --- | --- | --- |
| **Aujourd'hui** | séance du jour, semaine en cours, mot de Koach, suite de la semaine | onglet Programme actuel (`home_screen.dart`) |
| **Programme** | saison et blocs, semaines, échéance, évolution (propositions de Koach et historique), programme d'origine, bloc suivant | `program_screens.dart`, `plan/*`, Réglages › Mon programme |
| **Progrès** | objectifs et e1RM, records, endurance, historique des séances, charge | onglet Stats, `records_screen.dart`, `session_history.dart` |
| **Exercices** | bibliothèque d'exercices, anatomie | onglet Arsenal |

**Profil et réglages** : bouton rond en haut à droite d'Aujourd'hui (avatar), écran poussé. Contient : profil athlète, références, apparence (thème, palette, contraste renforcé), séance (repos par défaut, décompte), notifications, données (export, import, suppression), santé et sécurité, confidentialité, avis, licences, à propos, **mode dev** (builds de dev seulement : la poignée « DEV » disparaît des écrans et devient une entrée ici, plus un appui long sur le numéro de version).

Indicateur de niveau (« NIV. 1 ») : retiré de l'en-tête d'Aujourd'hui, montré dans Progrès (G11-G15 décideront de sa place définitive).

### 3.2 Aujourd'hui

Ordre fixe (maquette « Aujourd'hui ») :
1. Date du jour, « Semaine N » (appui : choisir une semaine), bloc et position (« Bloc force, semaine 2 sur 8 »), bouton Profil.
2. Bande des 7 jours de la semaine du programme : jour, date, état (faite ✓, prévue ○, repos —, aujourd'hui en couleur pleine). Appui sur un jour : sa séance.
3. Carte du jour : titre de la séance, 3 chiffres (exercices, séries, durée estimée en minutes entières), les 3 premiers exercices avec leur prescription, « et N autres exercices », bouton **Commencer la séance** (ou **Reprendre la séance** si elle est en cours, ou carte de repos les jours sans séance).
4. Une ligne de Koach au plus (la plus importante : proposition en attente, changement appliqué, alerte de douleur), qui ouvre son détail.
5. « Ensuite » : les séances restantes de la semaine.

Disparaissent de l'accueil : frise des 40 semaines (→ Programme), bandeaux empilés (une seule bannière à la fois, dans le flux, jamais sous la barre).

### 3.3 Séance

Parcours : **Avant** → **Exercice** ⇄ **Repos** → … → **Fin**.

- **Avant** (une page, plus de carte dans une carte) : « Comment tu te sens ? » en 5 choix d'un appui + « Passer » ; « Une gêne ? » ouvre les questions de douleur existantes ; changements de Koach pour cette séance en une ligne qui ouvre la feuille Koach. L'étape bloquante `clearance_first` (CI1g) reste bloquante et passe avant.
- **Exercice** (maquette « Séance ») : barre haute (quitter, « Exercice 3 sur 7 », liste des exercices) ; segments de progression ; nom de l'exercice ; trois chiffres (séries × reps, effort, repos) ; **bloc de charge** (chiffre géant, masse totale pour les exercices lestés, disques à charger) ; une ligne « Pourquoi cette charge ? » / « Consignes » qui ouvre une feuille (notes du coach, calibrage, technique, tempo, règle de douleur : tout le texte actuel, rien de perdu) ; tableau des séries (faites, en cours en surbrillance avec champs, à venir en gris) ; bouton bas **Valider la série N**.
- **Repos** (maquette « Repos ») : plein écran, compte à rebours géant, barre qui se vide, heure de fin, −15 s / +15 s / Passer ; **la saisie du RIR se fait ici** (6 boutons 0 à 5+, un appui, pré-sélection = RIR visé) ; « Ensuite : série 3, 5 reps à +32,5 kg ». Fin du repos : vibration et retour à l'exercice. Les exercices au temps, EMOM, intervalles, groupes et mini-séries (CI1f) gardent leurs chronos, dans le même style plein écran.
- **Koach propose** (maquette « Koach propose ») : feuille du bas, avant → après en grands chiffres, raison en une phrase, « Comment Koach a calculé » repliable, **Appliquer 115 kg** / **Garder 112,5 kg** ; au refus, raison facultative en un appui (trop lourd, trop léger, matériel, temps, autre — prévu par CAHIER_KM, codée ici, transmise seulement si le moteur la lit).
- **Fin** (maquette « Fin de séance ») : record éventuel en tête, 4 chiffres (durée, séries faites, tonnage, RIR moyen et cible), ressenti en 5 choix, séance suivante, Krédits gagnés si affichés aujourd'hui, **Terminer**.

### 3.4 Programme

Maquette « Programme » : titre, nom du programme ; position « S13 / 40 » et semaines avant l'échéance ; **barre de saison** (blocs proportionnels à leur durée, bloc en cours en couleur, repère de la semaine) ; liste des blocs (nom, semaines, état) ; semaine en cours jour par jour ; puis entrées vers : Évolution (Koach), Échéance et jour J, Programme d'origine, Bloc suivant, Changer de programme. Chaque bloc et chaque semaine s'ouvrent.

### 3.5 Progrès

Maquette « Progrès » : objectifs avec e1RM actuel, objectif, barre de progression depuis le point de départ et écart en kg ; endurance au poids de corps (actuel / objectif) ; puis records, historique des séances (liste par semaine, ouverture d'une séance), courbes par exercice, carte musculaire. Graphiques en couleurs fixes de données (§4.1).

### 3.6 Exercices

Bibliothèque en liste directe (recherche en haut, filtres en puces), fiche d'exercice restylée, anatomie en entrée secondaire. Le lot de la base v1.1 refera le contenu : ici, seulement le passage au système de design.

### 3.7 Profil, parcours d'entrée, réglages

Parcours de création du profil v3 et départ du programme : une question par écran, bouton bas « Continuer », progression en segments, « Passer » quand la question est facultative. Réglages : listes groupées, une ligne = un titre + au plus une ligne de valeur, aucun paragraphe hors des écrans d'aide.

## 4. Système de design

Le système vit dans `lib/kit/` (nouveau dossier, remplace `ui.dart` et la partie présentation de `app_theme.dart` ; `ui.dart` reste comme ré-export le temps de la migration et disparaît à UI5).

### 4.0 Références : Samsung, Google, Microsoft

Demande du propriétaire (10/10/2026) : s'inspirer de Samsung, Google et Microsoft. Ce que chacun apporte ici, et où il s'applique :

| Source | Principe repris | Application dans Kalis Track |
| --- | --- | --- |
| **Samsung One UI** | L'écran se partage entre une zone de lecture en haut et une zone d'interaction en bas, pour que les commandes restent à portée du pouce même sur grand écran ; parcours aussi courts que possible ; mode sombre et tailles de texte variables pour le confort | Grands titres en haut, bouton principal et choix d'un appui dans le bas de l'écran (`KBottomAction`, `KChoice`) ; **grand titre qui se replie au défilement** (`KPage` étendue) sur Programme, Progrès, Profil ; réglages groupés dans des conteneurs arrondis ; une tâche par écran |
| **Google Material 3 (Expressive)** | Rôles de couleur avec paires « couleur / texte sur la couleur » au contraste garanti, calculés dans l'espace HCT ; couleur, forme, taille, mouvement et contenant pour hiérarchiser ; mouvement à ressorts. Google annonce 46 études et plus de 18 000 participants, des éléments clés repérés jusqu'à 4 fois plus vite, et des 45 ans et plus aussi rapides que les plus jeunes | Dérivation des palettes (§4.1) avec `material_color_utilities` (déjà dépendance de Flutter) ; rôle `surPleine` toujours calculé ; une forme différente pour l'élément courant (§4.3) ; groupe de boutons reliés (−15 s / +15 s / Passer) ; ressorts M3 (§4.5) ; chiffres « mis en avant » en Condensed 600 |
| **Microsoft Fluent 2** | Jetons en couches : jetons globaux (valeurs brutes) puis jetons d'alias nommés par leur fonction, qui couvrent clair, sombre, contraste élevé et variantes de marque | Trois couches : **globaux** (hex des palettes, échelles), **alias** (`fond`, `surface`, `encre`…), **composants** (`kit.bouton.fond` → alias) ; aucun écran n'utilise un global ; **mode « Contraste renforcé »** (Apparence) qui recalcule tous les alias pour 7:1 |

Sources : [Samsung One UI, vue d'ensemble](https://developer.samsung.com/one-ui/overview.html) ; [Fluent 2, design tokens](https://fluent2.microsoft.design/design-tokens) ; [Android Authority, détails de Material 3 Expressive](https://www.androidauthority.com/google-material-3-expressive-details-3554486/) ; [Material 3 Expressive, Android Developers](https://developer.android.com/design/ui/wear/guides/get-started/apply).

### 4.1 Couleurs

**Palettes du propriétaire** (fichier `palettes_kalis_track.txt`, 10/10/2026) : elles **remplacent** les six couleurs de L5. Chaque palette fournit cinq valeurs (dominante, secondaire, accent, fond sombre, fond clair) ; les thèmes clair, sombre et système restent indépendants du choix de palette.

**Dérivation des rôles** (à coder dans `lib/kit/palette.dart`, avec test qui recalcule le tableau ci-dessous à l'identique) : la valeur du propriétaire est gardée **telle quelle** quand elle passe le contraste exigé par son rôle ; sinon on garde sa teinte et sa chroma (HCT) et on ne déplace que sa tonalité, du plus petit pas (0,5) qui satisfait le contraste.
- `fond` = fond du propriétaire. Sombre : `surface`, `haute`, `filet` = même teinte, chroma ≤ 16, tonalité du fond + 5, + 10, + 15. Clair : `surface` = blanc, `haute` = fond, `filet` = tonalité du fond − 10.
- `texte` (tonalité 95 en sombre, 10 en clair), `texte2` (70 / 40), `texte3` (50 / 60, inactif seulement), teinte du fond, chroma ≤ 6.
- `pleine` (bouton principal, jour courant, sélection pleine) = dominante ; en sombre, tonalité relevée à 35 au moins pour rester visible. `surPleine` = blanc ou `#121212`, celui qui contraste le plus, ≥ 4,5:1 ; si c'est `#121212` mais qu'un assombrissement de 6 points de tonalité au plus permet le blanc, on assombrit (texte blanc sur les boutons partout où c'est possible).
- `encre` (icône active, repère, chiffre mis en avant, contour de l'élément courant) = dominante ajustée à ≥ 4,5:1 sur `surface` (et sur `fond` en clair).
- `second` (graphiques, séries de données, barres secondaires) = secondaire ajustée à ≥ 3:1 sur `surface`.
- `accent` (records, Koach, Krédits, réussites) = accent ajusté à ≥ 4,5:1 sur `surface`.
- **Contraste renforcé** : mêmes règles avec 7:1 au lieu de 4,5:1 et 4,5:1 au lieu de 3:1.

Résultat (calculé le 10/10/2026, tous les contrastes vérifiés) :

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

Préférence enregistrée `accent` : identifiants nouveaux ci-dessus ; un ancien identifiant est relu ainsi (sans refuser l'import) : `rouge` → `bordeaux`, `jaune` → `neon`, `vert` → `forest`, `violet` → `violet`, `orange` → `solar`, `turquoise` → `arctic` ; absent ou inconnu → `bordeaux`.

Couleurs d'état, communes à toutes les palettes : `validation` `#5CB860` (sombre) / `#2E7D32` (clair), `danger` `#EF6B6B` / `#B3261E`, `avertissement` `#E6A23C` / `#8A5300` ; contrôlées à ≥ 4,5:1 sur la `surface` de chaque palette (ajustées par la même règle sinon).

Règles d'usage :
- `pleine` sert à **une** action par écran (le bouton principal) et au jour courant ; `encre` à l'élément courant ; `accent` à ce qui se fête (record, objectif atteint) et à la voix de Koach ; `second` aux données. Jamais de texte courant, de lien de paragraphe ou de décor dans ces couleurs.
- Plus de liens colorés dans le texte : une action est un bouton, une ligne avec chevron ou une ligne d'action de feuille.
- Couleurs fixes conservées (liste L5) : phases de chrono, rareté, marque K, icône Android ; les graphiques passent à `second` / `encre` / `accent` de la palette.
- Disques à charger : gris neutres (`#E8E8E8`, `#BDBDBD`, `#8F8F8F`, du plus lourd au plus léger), hauteur proportionnelle au poids, jamais les couleurs de compétition (elles se battraient avec la palette).
- Contraste : vérifié par test pour les 32 combinaisons (8 palettes × clair/sombre × normal/renforcé).

### 4.2 Typographie

Famille **Barlow** (SIL Open Font License 1.1), embarquée dans `assets/fonts/` avec sa licence (aucune permission INTERNET, aucun téléchargement à l'exécution ; source : dépôt GitHub `google/fonts`, dossiers `ofl/barlow`, `ofl/barlowsemicondensed`, `ofl/barlowcondensed`, empreintes SHA-256 consignées) :
- **Barlow** 400, 500, 600 : texte.
- **Barlow Semi Condensed** 600 : titres.
- **Barlow Condensed** 500, 600 : chiffres (charges, chronos, statistiques), toujours en chiffres tabulaires.

Échelle (taille / interligne, en dp) — **seules valeurs autorisées** :

| Style | Police | Taille / interligne | Usage |
| --- | --- | --- | --- |
| `titreEcran` | Semi Condensed 600 | 30 / 36 | un par écran |
| `titreSection` | Semi Condensed 600 | 22 / 28 | sections, feuilles |
| `corpsFort` | Barlow 500 | 17 / 24 | boutons, lignes importantes |
| `corps` | Barlow 400 | 15 / 22 | texte courant, lignes de liste |
| `detail` | Barlow 400 | 13 / 18 | valeurs secondaires, légendes |
| `micro` | Barlow 500 | 12 / 16 | barre de navigation, jours de la bande |
| `chiffre` | Condensed 600 | 30 / 34 | statistiques, prescriptions |
| `chiffreGrand` | Condensed 600 | 44 / 48 | records, avant → après |
| `chiffreGeant` | Condensed 600 | 64 / 64 | charge de l'exercice |
| `chrono` | Condensed 600 | 120 / 116 | repos et chronos |

Règles : phrases en minuscule (majuscule initiale seulement) partout, titres compris ; aucune capitale de mise en forme ; un titre ne se coupe jamais par des points de suspension : il passe à la ligne (2 lignes, 3 au-delà de 150 % de texte) ; nombres au format français (virgule décimale, espace fine insécable avant l'unité et entre les milliers : « 6 840 kg », « 112,5 kg ») ; durées en `m:ss` pour les chronos, « 45 min » ailleurs ; les grands chiffres restent entiers à 200 % de texte (`FittedBox` conservé).

### 4.3 Espacements, formes, élévation

- Espacements : 4, 8, 12, 16, 20, 24, 32, 48 — **seules valeurs** ; marge d'écran 20 ; écart entre sections 24 ; entre cartes 10.
- Rayons : 8 (puces, petits éléments), 14 (champs, lignes actives, choix), 16 (boutons, cartes secondaires), 28 (carte principale de l'écran, feuilles) — **seules valeurs**.
- Aucune ombre portée ; profondeur par la couleur de surface (`fond` < `surface` < `haute`). Contour seulement pour l'élément courant (1,5 dp, `encre`).
- Forme qui porte l'état (Material 3 Expressive) : un choix sélectionné (`KChoice`, jour courant, onglet actif) passe du rayon 14 à la forme pilule, avec un ressort ; un choix non sélectionné garde 14. L'état ne repose jamais sur la seule couleur.
- Une carte ne contient jamais une carte. Listes = lignes séparées par un `filet`, pas des cartes empilées.
- Cibles tactiles ≥ 48 dp ; bouton principal 56 dp de haut, pleine largeur, ancré en bas d'écran (zone du pouce).

### 4.4 Composants (`lib/kit/`)

| Composant | Rôle |
| --- | --- |
| `KTokens` | couleurs par rôle, styles de texte, espacements, rayons (une seule source ; `Theme.of` les expose par une extension `ThemeExtension`) |
| `KPage` | page : marge 20, titre d'écran, sous-titre, défilement, réserve de la barre basse |
| `KTopBar` | barre haute : retour ou fermer, titre court centré ou absent, une action |
| `KNavBar` | barre de navigation fixe à 4 onglets |
| `KPrimaryButton`, `KSecondaryButton`, `KTextButton` | boutons (56 / 48 dp) |
| `KBottomAction` | zone basse fixe avec le bouton principal |
| `KCard` (2 niveaux : `principale` rayon 28, `secondaire` rayon 16) | conteneur de surface |
| `KListRow` | ligne : titre, détail, valeur à droite, chevron ou interrupteur |
| `KSectionHeader` | titre de section + action facultative |
| `KStat` / `KStatRow` | chiffre + légende ; rangée de 2 à 4 |
| `KLoad` | bloc de charge : chiffre géant, masse totale, disques (`KPlates`) |
| `KSetTable` | tableau des séries (états fait, en cours, à venir) |
| `KChoice` | choix d'un appui (RIR, ressenti, segments) |
| `KWeekStrip` | bande des 7 jours |
| `KSeasonBar` | barre de saison proportionnelle |
| `KProgressLine` | barre de progression (objectif, repos) |
| `KSheet` | feuille du bas (poignée, titre, contenu, actions) |
| `KKoachLine`, `KKoachSheet` | la voix de Koach : une ligne, une feuille |
| `KNotice` | message dans le flux (info, avertissement, danger) |
| `KEmpty` | état vide : une phrase, une action |
| `KChip` | puce de filtre |

Mascotte de Koach (2D) : seulement dans `KKoachSheet`, les états vides et la cérémonie de fin ; ailleurs, l'icône flamme dans `KKoachLine`.

### 4.5 Mouvement

Ressorts de Material 3 Expressive (`SpringDescription` de Flutter, amortissement / raideur) : spatial rapide 0,9 / 1 400 (choix, boutons), spatial par défaut 0,9 / 700 (feuilles, cartes), spatial lent 0,9 / 300 (pages) ; effets (opacité, couleur) 1,0 / 3 800, 1 600, 800. Transitions de page par glissement horizontal dans la séance, fondu ailleurs. Réglage système « réduire les animations » respecté. Un seul moment orchestré : le record en fin de séance. Retour haptique : validation de série, fin de repos.

### 4.6 Textes de l'interface

Tutoiement, phrases courtes, verbes d'action sur les boutons (« Valider la série 2 », « Appliquer 115 kg ») ; une action garde son nom de bout en bout ; un écran principal n'a aucun paragraphe de plus de 2 lignes : le reste va dans une feuille « Pourquoi ? » ou « Consignes » ; textes de Koach : une phrase, le chiffre d'abord ; erreurs : ce qui s'est passé et quoi faire, sans excuse.

## 5. Exigences mesurables (critères d'acceptation)

### 5.1 Code

| Critère | Seuil | Vérifié par |
| --- | --- | --- |
| `fontSize`, `fontWeight`, `letterSpacing`, `Color(0x…)`, `BorderRadius.circular(n)`, `EdgeInsets` littéraux hors `lib/kit/` et hors liste blanche (peintres de données, mannequin, outils dev) | 0 | `tools/check_ui_tokens.py`, en CI |
| `Card(`, `BoxDecoration(` bruts hors `lib/kit/` et liste blanche | 0 | idem |
| `toUpperCase()` sur un texte affiché | 0 | idem |
| Tests de comportement (`store`, moteurs, journal, sauvegarde, migrations) modifiés | 0 | revue du diff de `test/` |
| Assertion de test retirée sans remplacement équivalent | 0 | revue du diff, justification par test dans la livraison |
| Format de sauvegarde, schémas, clés de préférences | inchangés (sauvegarde d'avant UI0 relue à l'identique) | test de relecture |

### 5.2 Rendu

| Critère | Seuil | Vérifié par |
| --- | --- | --- |
| Contraste texte / fond | ≥ 4,5:1 (≥ 3:1 au-delà de 24 dp ; 7:1 en contraste renforcé), 32 combinaisons | test calculé |
| Titres coupés par « … » | 0 à 360 et 320 dp, texte 100 %, 130 %, 200 % | tour de captures + test de débordement |
| Débordements (bandes jaunes et noires, `RenderFlex overflowed`) | 0 | tour de captures |
| Cibles tactiles | ≥ 48 dp | `meetsGuideline(androidTapTargetGuideline)` sur chaque écran du tour |
| Libellés TalkBack | chaque bouton-icône nommé | `meetsGuideline(labeledTapTargetGuideline)` |
| Contenu sous la barre de navigation | 0 | tour de captures |

### 5.3 Performance

Temps d'image de la séance et d'Aujourd'hui ≤ ceux de dev6.11.1 (relevé `docs/PERFORMANCE.md`, même émulateur) ; taille de l'APK : +600 Ko au plus (polices comprises).

### 5.4 Parcours (comptés sur l'émulateur, journal de test)

| Parcours | dev6.11.1 | Cible |
| --- | --- | --- |
| Ouvrir l'app → première série saisissable | à mesurer par UI0 | ≤ 3 appuis (Commencer, ressenti ou Passer, et c'est tout) |
| Série faite comme prescrite → enregistrée avec son RIR | à mesurer | 2 appuis (Valider, RIR) |
| Accepter une proposition de Koach | à mesurer | 2 appuis depuis l'écran où elle apparaît |
| Voir la saison | à mesurer | 1 appui depuis n'importe quel onglet |
| Changer de palette | à mesurer | ≤ 3 appuis |

## 6. Organisation des lots

### 6.1 Principe

Un lot de fondations, quatre lots d'écrans **en parallèle** sur des fichiers disjoints, un lot d'intégration. Tout se fait sur la branche d'intégration `refonte-ui` (créée depuis `main` b7996b3f) ; `main` ne reçoit la refonte qu'à UI5. Chaque lot travaille sur sa branche `ui/<LOT>` et sa branche de contrôle `claude/ci-ui-<lot>` (workflow ajouté par UI0, une concurrence par branche, pour que les contrôles parallèles ne s'annulent pas).

### 6.2 Propriété des fichiers

Un fichier n'appartient qu'à un lot. Un lot ne modifie aucun fichier d'un autre lot. Les fichiers partagés (`lib/kit/`, `app_theme.dart`, `ui.dart`, `main.dart`, `nav_bar.dart`, `pubspec.yaml`, workflows, outils de contrôle) n'appartiennent qu'à UI0 puis UI5. Un composant qui manque à un lot d'écrans est créé dans son dossier `lib/<zone>/widgets/` et signalé dans sa livraison ; UI5 le promeut dans `lib/kit/` si deux zones en ont besoin. Fichiers de logique (`store.dart`, `*_store.dart`, `models.dart`, `persistence.dart`, `packages/`) : interdits à tous les lots UI, sauf ajout d'accesseur de lecture justifié dans la livraison.

| Lot | Fichiers (et leurs tests `test/` et `integration_test/` dédiés) |
| --- | --- |
| UI0 | `lib/kit/**` (nouveau), `app_theme.dart`, `ui.dart`, `main.dart`, `nav_bar.dart`, `brand.dart`, `motion.dart`, `filter_menu.dart`, `search.dart`, `alerts.dart`, `store_widget.dart`, `pubspec.yaml`, `assets/fonts/`, `.github/workflows/`, `tools/check_ui_tokens.py`, `integration_test/tour_ui_test.dart` (squelette) |
| UI1 Aujourd'hui et Programme | `home_screen.dart`, `program_screens.dart`, `program_explainer.dart`, `program_origin.dart` (présentation), `resume_banner.dart`, `levelup.dart`, `plan/season_view.dart`, `plan/event_day_screen.dart`, `plan/evolution_widgets.dart`, `plan/plan_sheets.dart`, `plan/program_position.dart`, `koach/**` |
| UI2 Séance | `session_screen.dart`, `session_host.dart`, `session_history.dart` (écran d'une séance passée), `set_validation.dart` (présentation), `estimate_view.dart`, `rewards.dart`, `adapt/**` |
| UI3 Progrès | `stats_*.dart`, `progression_screen.dart`, `records_screen.dart`, `game_widgets.dart`, `muscle_map_2d.dart`, `muscle_body.dart` |
| UI4 Profil, parcours, Exercices | `settings_screen.dart`, `athlete_profile*.dart`, `profile_completion.dart`, `guided_tests.dart`, `data_control.dart`, `notification_settings.dart`, `pilotage_screen.dart`, `retired_notice_screen.dart`, `startup.dart`, `program_start.dart`, `plan/plan_screens.dart`, `plan/plan_creation.dart`, `wellbeing_screens.dart`, `arsenal_screen.dart`, `exercise_screens.dart`, `atlas.dart`, `anatomy_screen.dart` |
| UI5 Intégration | tout, en fin de parcours |

Fichiers non listés (`dev/**`, `plan/plan_inspector.dart`, `animation_test_screen.dart`, `mannequin_*.dart`, `exercise_mannequin.dart`, `engine3d.dart`, `pose_painter.dart` : outils dev, mannequin, moteur 3D, peintres de pose) : passage aux jetons par UI5 seulement là où le contrôle l'exige, sinon liste blanche.

### 6.3 Contenu des lots

**UI0 — Fondations** (séquentiel, prérequis des quatre suivants)
- Branche `refonte-ui` ; workflow de contrôle parallèle `claude/ci-ui-*` (copie de `ci-3d.yml` : concurrence par branche, `ci-out/` recommité sur la branche de contrôle du lot, rendus « avant » pris sur `main` b7996b3f).
- Polices Barlow embarquées (§4.2) ; jetons en trois couches (§4.0) : `KTokens` et `ThemeExtension` ; `lib/kit/palette.dart` (dérivation de §4.1, `material_color_utilities`) ; `buildTheme(dark, palette, contrasteRenforcé)` réécrit sur les jetons ; sélecteur de palette dans Apparence (8 palettes, aperçu de chacune en clair et sombre) et interrupteur « Contraste renforcé » ; relecture des anciens identifiants ; tests de contraste des 32 combinaisons et test qui retrouve le tableau de §4.1 à l'identique.
- Tous les composants de §4.4, chacun avec un test de widget et une capture de référence (sombre et clair, palettes `bordeaux` et `neon` : la plus sombre et la seule à texte foncé sur bouton) ; page de catalogue des composants en mode dev (Profil › Mode dev › Composants).
- Nouvelle navigation (§3.1) : `KNavBar` fixe, ordre des onglets, ouverture sur Aujourd'hui, Profil en écran poussé depuis Aujourd'hui, mode dev déplacé ; les écrans existants sont branchés tels quels dans les nouveaux onglets (Programme : écran actuel de Mon programme ; Progrès : Stats ; Exercices : Arsenal), pour que chaque lot parte d'une app qui fonctionne.
- `tools/check_ui_tokens.py` (§5.1) avec le relevé de départ par fichier, mode « zone » (`--zone UI2` échoue si un fichier de la zone contient un littéral) ; branché en CI, non bloquant pour les zones non encore passées.
- Tour de captures `integration_test/tour_ui_test.dart` : squelette qui ouvre chaque écran principal (sombre et clair) et chaque lot complète pour sa zone ; mesure des parcours de §5.4 sur dev6.11.1 (colonne « dev6.11.1 » du tableau).
- Livrable : `refonte-ui` à jour, `LIVRAISON_UI0.md`, catalogue des composants en captures.

**UI1 — Aujourd'hui et Programme** (parallèle) : §3.2, §3.4, Koach sur l'accueil (§3.2 point 4), écrans Saison, Jour J, Évolution, Programme d'origine, Bloc suivant (présentation) ; déplacement de « Mon programme » de Réglages vers l'onglet Programme (l'entrée de Réglages devient un renvoi, retirée par UI5).

**UI2 — Séance** (parallèle) : §3.3 en entier (Avant, Exercice, Repos avec saisie du RIR, Koach propose, Fin), chronos de mode, groupes et mini-séries, historique d'une séance passée, cérémonie de récompense, cartes de douleur et d'avis médical (CI1b à CI1g : même logique, même ordre, même blocage).

**UI3 — Progrès** (parallèle) : §3.5, graphiques et carte musculaire restylés (couleurs fixes de données), records, historique.

**UI4 — Profil, parcours, Exercices** (parallèle) : §3.1 (écran Profil et réglages), §3.6, §3.7, démarrage et erreurs de lancement, écrans d'aide (santé, récupération, confidentialité, licences).

**UI5 — Intégration** (séquentiel, après les quatre)
- Fusion des quatre branches dans `refonte-ui` (aucun conflit attendu, fichiers disjoints) ; promotion des composants communs ; suppression de `ui.dart`, de l'ancien dock et des renvois provisoires.
- Contrôle de jetons bloquant sur tout `lib/` (§5.1) ; tour de captures complet : chaque écran × sombre/clair × `bordeaux` et `neon`, plus 320 dp × 200 % de texte, plus les 8 palettes et le contraste renforcé sur Aujourd'hui et Séance ; mesures de §5.2 à §5.4.
- Relecture indépendante (sous-agent Opus qui ne voit que le cahier, les maquettes et les captures) ; corrections.
- Publication : `refonte-ui` → `main` en avance rapide, **dev6.12.0**, build signé, run vérifié, installation par-dessus dev6.11.1 sans perte (clé inchangée).
- `LIVRAISON_UI5.md` avec avant/après par écran, mesures, limites.

### 6.4 Exigences communes à tous les lots

- Maquettes et ce cahier comme cible ; tout écart est écrit dans la livraison avec sa raison.
- Aucune information perdue : chaque texte, chiffre ou action d'aujourd'hui existe encore, au même endroit ou un appui plus loin (tableau de correspondance « avant → après » dans la livraison).
- Tests : la suite complète passe ; tests d'écran mis à jour avec les nouveaux textes (chaque changement justifié) ; contrôle de jetons à 0 sur la zone ; tour de captures de la zone vert, relu image par image par le lot (sombre et clair, sessions perso et dev).
- Sauvegardes toutes les 30 minutes sur `ui-sauvegardes/<LOT>` (arbre sans `.github/`, `SAUVEGARDE.md`) ; sous-agents sur Opus.
- Version interne `dev6.12.0-<lot>` sur les branches ; seul UI5 publie sur `main`.

## 7. Ordre avec le reste du projet

- **KM1** (voie moteurs, `packages/` sur `moteurs`) continue en parallèle : aucun fichier commun.
- **Lot CI final et intégration de la base v1.1** : repoussés après UI5, et faits sur le nouveau système (la bibliothèque d'exercices de la base v1.1 sera directement construite avec `lib/kit/`). KM3 garde son jalon (APK le 16/11/2026).
- **CI1g** (dev6.11.1, « à valider ») : base de départ de la refonte.

## 8. Calendrier

| Étape | Dates |
| --- | --- |
| UI0 Fondations | 10/10 → 11/10/2026 |
| UI1 à UI4 en parallèle | 11/10 → 13/10/2026 |
| UI5 Intégration et publication (dev6.12.0) | 14/10 → 15/10/2026 |
| Lot CI final, puis base v1.1 | à partir du 16/10/2026 |

Budget : quatre sessions Opus en parallèle pendant que KM1 tourne sur Fable consomment vite la limite hebdomadaire du plan Max ; si la limite approche, le pilotage passe UI1 à UI4 en deux vagues de deux (UI2 et UI1 d'abord : ce sont les écrans de tous les jours).

## 9. Décisions prises par le pilotage (à confirmer ou corriger par le propriétaire)

| N° | Décision |
| --- | --- |
| U1 | Quatre onglets : Aujourd'hui, Programme, Progrès, Exercices ; Profil et réglages derrière l'avatar d'Aujourd'hui. |
| U2 | Police Barlow (trois largeurs), embarquée. |
| U3 | Charge affichée en grand avec les disques à charger, en gris neutres. |
| U4 | Saisie du RIR sur l'écran de repos, pré-sélectionnée sur le RIR visé. |
| U5 | Plus de capitales de mise en forme, plus de titres tronqués. |
| U6 | Niveau retiré de l'en-tête d'Aujourd'hui, montré dans Progrès. |
| U7 | Refonte avant le lot CI final et la base v1.1. |
| U8 | Version publiée : dev6.12.0. |
| U9 | Les 8 palettes du propriétaire remplacent les 6 couleurs de L5 ; Bordeaux Performance par défaut ; anciens choix relus (§4.1). |
| U10 | Valeurs du propriétaire gardées telles quelles quand le contraste passe, tonalité HCT ajustée sinon (cas ajustés : Bordeaux en sombre, Obsidian et Solar d'une nuance pour le texte blanc, accents et encres sur fond clair). |
| U11 | Références One UI, Material 3 Expressive, Fluent 2 (§4.0) ; mode « Contraste renforcé » ajouté. |
