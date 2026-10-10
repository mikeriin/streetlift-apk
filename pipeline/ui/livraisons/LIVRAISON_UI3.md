# Livraison UI3 — Stats (dev6.12.0-ui3)

Lot UI3 du pipeline « Refonte UI et UX » (UI), lancé par le pilotage le 10/10/2026 à 14:55 (C8), en parallèle de UI1, UI2 et UI4. La session `session_01JVF5cveTZDzybGVBq9M1XE` l'a pris à 13:43 UTC (premier lot « à faire », pas de ligne « Lot : »). Validation : conversation de pilotage, recommandation au §9.

| | |
| --- | --- |
| Branche | `ui/UI3` (depuis `refonte-ui` 0e5342df), tête `f7de57c1` |
| Contrôle complet | `claude/ci-ui-ui3`, run 38066918616 (résultats : commit 32e12c9f) |
| Contrôle rapide | `claude/ci-ui-ui3-rapide`, run 38066258981 (format, analyse, jetons, tests `ui3_*`, captures) |
| Sauvegardes | `ui-sauvegardes/UI3` (sans `.github/`, `SAUVEGARDE.md`, captures « avant » dans `captures-avant/`) |
| Version interne | dev6.12.0-ui3, étiquette du lot (`pubspec.yaml` reste à 6.11.1, UI0.1) |
| Accès | `add_repo` absent de la session ; push vérifié par `git push --dry-run origin pipeline` puis par la prise du lot |

## 1. Ce qui est livré

Fichiers touchés : ceux de UI3 (§7.2) — `stats_screen.dart`, `stats_overview.dart`, `stats_progression.dart`, `stats_performance.dart`, `stats_history.dart`, `stats_widgets.dart`, `records_screen.dart`, `game_widgets.dart` — plus un composant nouveau `lib/stats/widgets/k_info_sheet.dart` (§7.2 : composant manquant dans `lib/<zone>/widgets/`), le tour (`integration_test/tour_ui_test.dart`, section Stats et 3 parcours), les tests (`test/ui3_stats_test.dart`, `test/ui3_stats_capture_test.dart` nouveaux ; finders adaptés dans `stats_test.dart` et `progression_screens_test.dart`). `stats_data.dart`, `stats_navigation.dart`, `stats_mannequin.dart`, `progression_screen.dart` : inchangés. Aucune logique, aucun moteur, aucune donnée enregistrée modifiés.

1. **En-tête racine (C1)** : grand titre « STATS » (capitales U3), une phrase, l'aide « Comprendre les XP » et le logo à leur place. Rubriques en rangée défilante, rubrique active en pilule `pleine` (dominante exacte, texte `surPleine`), 48 dp, fondu sur les bords quand la rangée défile. Depuis une autre page (pastille de niveau de l'accueil, récompenses) : en-tête de sous-page.
2. **Aperçu = résumé (§4.1)** : la carte du personnage, le défi de la semaine, les chapitres, le boss et la saison ouvrent l'onglet Parcours (plus aucune feuille de jeu ici). Groupe « Aller plus loin » : Parcours, Performances, Historique. Objectif de la semaine réglé sur place (segments).
3. **Parcours** : carte « Niveau n · rang » (feuille de personnage), segments Pratique / Rythme, arbre des paliers, groupe « Défis et récompenses » : Défis de la semaine, Campagne, Boss, Saisons, Tes titres — seule entrée de chaque feuille ; aucune feuille n'en ouvre une autre (détails d'un chapitre et d'un boss dans leur feuille).
4. **Performances** : « Mes références » (raccourci R2, même page `PilotageScreen`) et **« Records »** (U12) en tête ; programme, force, endurance (références non renseignées regroupées, bouton tonal « Mes références », R5), muscles de la semaine (carte 2D inchangée, dans sa carte).
5. **Records** (`records_screen.dart`) : la page n'affichait que Stats, sans aucun record. Refaite dans la zone, elle lit `exerciseBests` (game.dart, le calcul déjà utilisé pour annoncer les records) sans le modifier : par exercice, meilleure charge (charge × répétitions, 1RM estimé) et meilleure série au poids de corps, avec la date du premier passage. Testée sur des données réelles (série non validée ignorée, journal inchangé).
6. **Historique** : `KSearchField`, séances groupées par mois (KMenuGroup), date et heure, nombre de notes ; la relecture d'une séance (`session_history.dart`, UI2) inchangée.
7. **Jeu aux couleurs de la palette** : insigne de rang (`pleine`, contour `encre` ou `surPleine`), radar (`encre`, `surPleine` sur l'aplat), anneau, barres (`encre`, réussite `validation`), activité (`second`, semaine en cours `encre`) ; rareté des badges en puce neutre avec icône (C5). L'insigne suit donc la palette aussi dans les récompenses (UI2 l'utilise tel quel).
8. **Feuilles** : `KInfoSheet` (poignée, titre, contexte, contenu qui défile, « Fermer ») pour les 10 feuilles de la zone.
9. **Menus de la zone au gabarit** : 2 `showModalBottomSheet` directs → 0 ; 0 `PopupMenuButton`, 0 `showDialog` (la seule feuille de choix, « Tes titres », applique le choix et se ferme).

## 2. Avant → après (aucune information perdue)

| Écran | Avant | Après |
| --- | --- | --- |
| En-tête | « STATS » 27 px gras, ⓘ, logo | Grand titre 30 (titreRacine), phrase « Chaque effort construit la suite. » (venue de l'Aperçu), ⓘ, logo |
| Rubriques | Onglets Material, soulignés | Mêmes 4 rubriques, mêmes clés, pilule `pleine` |
| Aperçu › personnage | Carte bordeaux fixe → feuille de personnage | Aplat `pleine`, mêmes infos (titre, niveau, XP, rang suivant, 4 attributs, radar, série, boucliers, badges) → onglet Parcours |
| Aperçu › objectif | Carte → feuille à puces « Adaptatif, 2 jours… 6 jours » | Carte avec segments « Adaptatif, 2, 3, 4, 5, 6 » sur place ; texte de la feuille sous les segments ; valeur 1 affichée telle quelle |
| Aperçu › série | Carte → feuille « Ta série et tes boucliers » | Idem (une seule entrée), chevron visible |
| Aperçu › quêtes | Sous-titre « Principale : ta prochaine journée · hebdo : bonus XP » ; quête ; défi non touchable ; tuile « Défis de la semaine » → feuille | Titre de section « Quêtes : ta prochaine journée et les défis de la semaine (bonus XP) » ; quête (textes sans l'Arsenal retiré en G2) ; défi avec surtitre « Défis de la semaine · n / m validés · bonus XP automatiques » → Parcours |
| Aperçu › campagne | Sous-titre, lien « Parcours », chapitres/boss/saison → 3 feuilles | Titre « Campagne : chapitres du programme, boss et saison » ; mêmes cartes → Parcours ; lien retiré (C2) |
| Aperçu › toi contre toi-même | Section + carte au même titre | Section seule ; « entraînements » → « séances » |
| Aperçu › cette semaine, depuis tes débuts | 8 tuiles | 8 tuiles, mêmes valeurs, hauteurs alignées par rangée ; « Entraînements terminés » → « Séances terminées » |
| Aperçu › rythme | Barres en dégradé rouge fixe, « Cette sem. » | Barres `second`, semaine en cours `encre`, « Cette semaine » ; unité dans le titre ; feuille identique |
| Aperçu › tuiles du bas | Défis (feuille), Arbre de progression, Performances et références, Tout ton historique | Groupe « Aller plus loin » : Parcours, Performances, Historique (onglets) ; les défis restent dans Parcours |
| Parcours › en-tête | « Ton arbre de progression », phrase | Idem |
| Parcours › niveau | « NIV. 11 · Challenger », badges | « Niveau 11 · Challenger », « Ta feuille de personnage · 4 / 9 badges obtenus » |
| Parcours › branches | 2 boutons encadrés et fourche dessinée | Segments Pratique / Rythme (la fourche, décorative, disparaît) |
| Parcours › paliers | Cartes (statut coloré, rareté colorée, jauge en dégradé) | Mêmes cartes et chaînes ; rareté en puce neutre avec icône ; jauges `encre` / `validation` |
| Parcours › tuiles | Campagne, boss et saisons (feuille empilant 3 autres) ; Tes titres ; Défis | Défis de la semaine ; Campagne ; Boss (n / m vaincus, prochain) ; Saisons ; Tes titres |
| Feuille personnage | Rangs, attributs, origine des XP ; « références Pilotage » | Mêmes contenus en groupes ; « Mes références » (R9, à l'affichage, voir §8) |
| Feuille campagne | Chapitres (bande touchable → feuille), carte boss + liste (→ feuille), saison, quêtes | Chapitres en détail (semaines, journées, jauge, titre, chapitre courant au contour `encre`) ; boss et saisons dans leurs feuilles |
| Feuille boss | Une feuille par boss | Une feuille « Boss » : chaque boss, ses journées de test, sa récompense |
| Feuille saisons | Saisons | Saisons et quêtes de saison (venues de la campagne) |
| Feuille titres | Liste à choix | Idem, au gabarit ; le choix ferme la feuille |
| Feuille XP | « Comment progresser », « Compris » | Titre « Comprendre les XP » (libellé du bouton, R3), contexte « Comment progresser », mêmes 4 paragraphes, « Compris » |
| Performances › références | « Modifier mes références » | « Mes références » (R1/R2) |
| Performances › records | Promis par une tuile, introuvables | Ligne « Records » → page Records |
| Performances › non renseignés | Une carte par référence « Non renseigné · à compléter dans Références… » (chemin écrit) | Groupe « Non renseigné » par section + phrase + bouton tonal « Mes références » |
| Performances › cibles | Puces colorées valeur / cible | Valeur en chiffres (`validation` si atteinte), cible avec drapeau, jauge, départ |
| Performances › muscles | Carte 2D, légende | Carte 2D inchangée ; légende identique en pilules qui passent à la ligne |
| Historique | Champ « Rechercher dans l'historique » (« Séance ou note »), cartes « Séance terminée · n notes » | `KSearchField` « Séance ou note », groupes par mois, phrase « Tes séances terminées, avec leurs notes. », notes seulement quand il y en a |
| Records | Copie de Stats | Page Records (§1.5) |

## 3. Captures clés

Sur `claude/ci-ui-ui3` (dernier commit « CI UI : résultats du run … ») : `ci-out/captures-ui/ui3_<page>_<bordeaux|neon>_<sombre|clair>.png` (pages `apercu`, `parcours`, `performances`, `historique`, `records`), `ui3_feuille_<personnage|serie|defis|campagne|saisons|titres|xp|boss>_*.png`, `ui3_320_*.png` (320 dp × 200 %). Colonne « avant » (même test, même journal, sur 0e5342df) : `ui-sauvegardes/UI3:captures-avant/ui3_avant_*.png`. Tour émulateur : `ci-out/tour/apres/tour_<a|b|c|d>_<nn>_stats*.png` et `…_records.png`, mêmes noms dans `ci-out/tour/avant/`.

À regarder en priorité : `ui3_apercu_bordeaux_sombre`, `ui3_parcours_neon_clair`, `ui3_performances_bordeaux_clair`, `ui3_records_neon_sombre`, `ui3_feuille_campagne_neon_clair`, `ui3_320_apercu`.

## 4. Mesures

**Contrôles** (run complet 38066918616) : formatage, analyse, jetons de la zone, tests Python, suite Dart complète, tests du mode dev, captures UI, rendus historiques, build debug et profile, paquets, rendus « avant », tour (8 parties) et cibles émulateur précédentes : tout vert (suite Dart : 872 tests, 32 ignorés ; mode dev : 18 ; tour « après » : 4 parties à 0 ; cibles émulateur : vertes), sauf **une partie de la colonne « avant »** : `tour_a` sur la base b7996b3f n'a pas pu se connecter à l'émulateur (VM Service, deux essais, code 124), un incident d'infrastructure sans lien avec le lot (parties b, c, d « avant » vertes ; le run complet précédent 38062051447, même tour, avait ses 8 parties vertes et sert de colonne « avant » pour la partie a).

| Mesure | Avant (0e5342df) | Après |
| --- | --- | --- |
| `check_ui_tokens.py --zone UI3 --menus` | 101 | **0** |
| Menus hors gabarit dans la zone (`showModalBottomSheet`) | 2 | 0 |
| Couleurs fixes dans la zone (`KPalette.*`, `SL.*`) | insigne, radar, activité, rareté en rouge fixe | 0 : tout par `KTokens` |
| Tests de la zone | — | `ui3_stats_test.dart` : 13 tests (arborescence, objectif, feuilles non empilées, titres, Records sur données réelles, journal intact, 320 dp × 200 % sombre et clair, 320 dp × 130 % avec références, cibles nommées, 48 dp) |
| Captures | 60 « avant » | 60 « après » (5 pages et 8 feuilles × 4 variantes, 8 à 320 dp × 200 %) + tour (4 parties × 10 écrans Stats) |

**Parcours** (tour émulateur, depuis l'accueil, identiques dans les 4 parties, sessions perso et dev) :

| Parcours | Avant | Après |
| --- | --- | --- |
| Records | impossible | 3 (Stats › Performances › Records) |
| Mes références par Stats | 3 (« Modifier mes références ») | 3 (« Mes références ») ; 2 depuis l'onglet Stats |
| Objectif de la semaine (réglage visible) | 3 (carte › feuille) | 2 (réglé dans la carte) |
| Une feuille de jeu | 2 à 3 selon l'entrée (Aperçu ou Parcours), feuilles empilées jusqu'à 3 | 3 depuis l'accueil, une seule entrée (Parcours), jamais empilée |

**Sous le dock** : aucun texte en bas des 4 rubriques (relevé `sous_le_dock`, 4 parties).

**Contrastes** : seulement des rôles du kit ; texte `encre` / `accent` jamais sur `haute` (UI0.8) — dans les feuilles (`surface`), les groupes `haute` portent du `texte` / `texte2` et des icônes ; texte sur aplat en `surPleine` (≥ 4,79:1, UI0).

**Relecture indépendante** (sous-agent Opus : cahier et captures avant / après seulement) : 17 constats, verdict « à corriger ». Traitement :

| N° | Constat | Suite |
| --- | --- | --- |
| 1 | « références Pilotage », « (Références) » dans la feuille de personnage (R9) | Corrigé à l'affichage (`_r9`) ; texte source dans `game.dart`, signalé à UI5 |
| 2 | Logo disparu de l'en-tête | Corrigé : logo rétabli à sa place (cahier §1) |
| 3 | Records : groupes « Avec charge » / « Au poids de corps » trompeurs | Corrigé : « Meilleure charge », « Meilleures répétitions au poids de corps » ; date sur sa ligne |
| 4 | Liens texte « Mes références » et « Parcours » (C2) | Corrigé : bouton tonal « Mes références » ; lien « Parcours » retiré (les cartes ouvrent Parcours) |
| 5 | Nombres coupés (« 100 » / « % », « 4 » / « / 9 ») | Corrigé : espaces insécables avant « % », autour de « / » et avant « · » |
| 6 | Aide de recherche tronquée à 200 % | Corrigé : « Séance ou note » |
| 7 | Rubriques coupées sans indice à 320 dp | Corrigé : fondu sur les bords ; marges réduites, les 4 rubriques tiennent à 360 dp |
| 8 | Chapitre en cours non signalé dans la feuille | Corrigé : contour 1,5 dp `encre` |
| 9 | Informations perdues (sous-titres Quêtes, Campagne, unité du rythme, « n / m boss vaincus », « prochain ») | Corrigé : titres de section complets, compte des boss sur la ligne Boss, « en cours » / « prochain boss » |
| 10 | Une seule entrée par feuille | Vérifié par test (`ui3_stats_test` : les cartes de l'Aperçu ouvrent Parcours, aucune feuille) |
| 11 | Capitales des titres de feuille | Laissé comme le kit (UI0) ; à trancher par UI5 (§5) |
| 12 | « Comprendre les XP » / « Comment progresser » | Titre = libellé du bouton (R3) ; contexte gardé (§5) |
| 13 | Finitions de l'Aperçu | Tuiles alignées par rangée ; « Séance terminée » répété retiré de l'Historique ; signe moins non changé (glyphe non vérifié dans Barlow) ; « Aller plus loin » gardé (raccourci vers les rubriques en bas d'un long résumé) |
| 14 | Segments empilés à 320 dp × 200 % | Comportement du kit (`KSegmented`, rien de coupé) |
| 15 | Feuilles longues à 320 dp | Le contenu défile au-dessus de « Fermer » (85 % de l'écran) ; pas de fondu ajouté |
| 16 | Carte musculaire vide en sombre | Dessin intouchable (§1), inchangé ; message gardé sous la carte |
| 17 | Noms d'exercice en capitales | Données du programme, hors UI |

## 5. Écarts aux maquettes et au cahier

- Pas de maquette dédiée à Stats : le style suit les maquettes Réglages et Accueil (grand titre, groupes à 20, cartes à 24, pilules), l'arborescence suit la planche Arbo.
- **Feuilles de jeu** : nouveau gabarit de feuille d'information (`KInfoSheet`), faute de gabarit « information » au §4.5 ; mêmes poignée, en-tête et « Fermer » que `KActionSheet`.
- **Titres de feuille sans capitales** : comme les feuilles du kit (`_SheetHeader` de UI0) ; §5.2 cite « feuille » parmi les `titreSeance` en capitales — à trancher par UI5 pour tout le kit.
- **Feuille XP** : titre « Comprendre les XP » (le bouton), « Comment progresser » en contexte (texte attendu par un test existant).
- **Segments du kit à 40 dp de zone touchable** dans leur rail de 48 (C13) : `KSegmented` (Aperçu, Parcours) ; signalé à UI5, le test de cibles 48 dp de la zone porte sur Performances et Historique.
- **Logo** : gardé à sa place dans l'en-tête (cahier §1), alors que `KPage.root` n'en a pas.

## 6. Composants à promouvoir (UI5)

- `lib/stats/widgets/k_info_sheet.dart` : `KInfoSheet`, `showKInfoSheet` → `lib/kit/sheets.dart`.
- `StatsBar` (jauge en pilule, variante sur aplat), `StatsMetric` / `StatsGrid` (tuiles chiffrées alignées), `StatsSheetGroup` / `StatsSheetRow` (groupe `haute` dans une feuille) de `stats_widgets.dart` : candidats `KProgress`, `KStatTile`.

## 7. Besoins hors zone (signalés, non modifiés)

- `game.dart` (UI5) : textes d'aide des attributs « références Pilotage », « (Références) » (R9) ; remplacés à l'affichage dans `game_widgets.dart` en attendant (`_r9`).
- `muscle_body.dart` (intouchable) : `MuscleLegend` déborde à 320 dp × 200 % (texte non flexible, couleurs fixes) ; contournement local dans `stats_performance.dart`.
- `KSegmented` (kit) : zone touchable 40 dp.
- Code mort `StatsLevelCard`, `showStatsLevel` (§4.6) : gardés, mis aux jetons.
- Retour à l'onglet Programme depuis Stats (quête principale, historique vide) : aucune API de changement d'onglet (`main.dart`, UI0) ; les états vides sont sans action.

## 8. Limites

- Le tour part d'un profil sans séance : les captures émulateur montrent Stats vide ; les captures de rendu (journal de 24 séances) montrent l'écran rempli.
- `KSegmented` (kit) : zone touchable de 40 dp dans un rail de 48 (Aperçu, Parcours).
- États vides de l'Historique et des Records sans action (aucun moyen d'ouvrir l'onglet Programme depuis Stats).
- Textes d'aide des attributs corrigés à l'affichage seulement (R9, `game.dart` hors zone).
- `tour_ui_test.dart` : lignes ajoutées dans la section Stats et 3 parcours en fin de fichier ; risque de conflit textuel simple avec les autres lots à la fusion.

## 9. Recommandation (C8, le pilotage décide)

Valider UI3 et fusionner `ui/UI3` (f7de57c1) dans `refonte-ui`. La zone est à 0 au contrôle de jetons et de menus, l'arborescence du §4.1 est en place (Aperçu résumé, feuilles de jeu dans Parcours seulement et jamais empilées, Records branché sur des données réelles, Mes références et objectif de la semaine en raccourcis R2), aucune information n'est perdue (§2), les illustrations et la logique sont intactes, et le contrôle complet est vert côté lot.

Points pour la fusion et UI5 :
1. `integration_test/tour_ui_test.dart` : conflit textuel probable avec les autres lots (section Stats et 3 parcours ajoutés en fin de tour).
2. Promouvoir `KInfoSheet` dans le kit ; trancher les capitales des titres de feuille (§5).
3. `KSegmented` : zone touchable à 48 dp ; `game.dart` : textes R9 ; `MuscleLegend` : débordement en grand texte.
