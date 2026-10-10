# Décisions du pipeline « Refonte UI et UX » (UI)

Elles font foi (PIPELINE_UI.md). Chaque lot n'écrit que dans sa section.

## U0 — Création (conversation de pilotage, 10/10/2026)

- **U0.1 Demande du propriétaire** (10/10/2026, 09:08 à 09:20) : « faire une refonte de l'UI pour avoir quelque chose de propre qui ne fait pas brouillon », « imaginer un nouvel UI et faire un cahier des charges puis lancer la refonte en parallèle » ; « l'UI et l'UX » ; « inspire-toi de ce que font Samsung, Google et Microsoft » ; fichier de 8 palettes (`inputs/palettes_kalis_track.txt`).
- **U0.2 Organisation** : une tâche planifiée Opus 5.5 effort élevé pour tous les lots (`trig_01Fqf4osZzdda75J4DqmoLB1`, créée le 10/10/2026 07:32 UTC) ; UI0 seul, puis UI1 à UI4 en parallèle (sessions de la même tâche, prise de lot par push, PIPELINE_UI.md §1), puis UI5. La conversation de pilotage fusionne `ui/UI1` à `ui/UI4` dans `refonte-ui`.
- **U0.3 Validation** : délégation C8 (DECISIONS_CP.md) — la conversation de pilotage valide les lots ; le propriétaire valide sur téléphone après UI5.
- **U0.4 Ordre** : la refonte passe avant le lot CI final et l'intégration de la base v1.1 (cahier §7) ; KM1 continue en parallèle (aucun fichier commun).
- **U0.5 Choix de conception** : décisions U1 à U9 du cahier version 2 (§9), prises par le pilotage, **à valider par le propriétaire avant tout lancement** (09:32) ; une correction du propriétaire arrive dans `LANCEMENTS.md` et prime.
- **U0.7 Cadrage du propriétaire** (09:32 à 09:50) : rien n'est lancé sans sa validation ; « garder le même principe de l'UI/UX présente mais que ça soit fini et pas brouillon » ; « ne change pas les illustrations de Koach, du logo et de l'anatomie musculaire » ; terminer ce qui est fait, corriger les incohérences entre l'UX et l'UI, refondre tous les menus. Le cahier version 1 (nouvelle navigation, nouveaux parcours) est **remplacé** par la version 2 (finition, incohérences C1 à C14, modèle unique de menus) ; les maquettes montrent chaque écran actuel à côté de sa version finie, avec les vraies illustrations.
- **U0.6 Palettes** : dérivation et tableau de référence `inputs/palettes_roles.json` (script `inputs/palettes_derivation.py`, HCT avec `materialyoucolor`) ; le test de UI0 retrouve ce tableau à l'identique en Dart.
- **U0.8 Couleurs et rayons** (10:11 à 10:52) : dominante de chaque palette utilisée telle quelle pour les aplats (`#551515` pour Bordeaux), seul le texte posé dessus s'adapte (cahier §5.1) ; rayons essayés dans le canevas (plus arrondis, puis « uniformes, que rien ne se détache », puis moins prononcés pour les menus et les cartes) : cartes 24, menus 20, commandes en pilule (cahier §5.3, U13).
- **U0.9 Menus** (11:20 à 11:41) : le dock reste tel quel (« j'aime bien la barre de navigation ») ; demande de menus cohérents, peu nombreux, où l'on trouve vite. Inventaire de l'existant par trois sous-agents en lecture seule (`inputs/inventaire_navigation.md`) ; arborescence « une place par chose » (cahier §4, planche `maquettes/Arbo.dc.html`) ; le propriétaire **valide** l'arborescence, Apparence en sous-page et Records dans Stats (11:41 ; U10 à U12). Cahier en version 3.
- **U0.10 Lancement** (11:46) : « Lance ui0 ». Le feu vert confirme les décisions U1 à U13 du cahier version 3 (capitales des titres, Barlow, 8 palettes à dominantes exactes, contraste renforcé, barre de saison par blocs, modèle unique de menus et arborescence, rayons). UI0 lancé par la tâche `trig_01Fqf4osZzdda75J4DqmoLB1` ; UI1 à UI4 seront lancés en parallèle par le pilotage après validation de UI0.
- **U0.11 Validation de UI0** (pilotage, C8, 10/10/2026 14:55) : livraison relue, contrôle `claude/ci-ui-ui0` run 38050589366 vert (860 tests, palettes 192/192, contrastes des 32 combinaisons, tour avant/après sans contenu sous le dock), captures du kit regardées (menus, séance, réglages, Neon clair) : conformes aux maquettes (rayons 24 / 20 / pilule, dominantes exactes, pilules séparées). Choix UI0.1 à UI0.8 **acceptés**, y compris les fichiers hors liste (`store.dart` : préférence `accent` et `contrast`, ajout sans migration ; `settings_screen.dart` : sélecteur, que UI4 reprend). Deux points présentés au propriétaire sans bloquer : logo teinté en `encre` en thème clair (UI0.4 ; inchangé pour 5 palettes, lisible pour Neon, Obsidian et Solar) et dock à 96 % d'opacité avec flou. UI1 à UI4 lancés en parallèle depuis `refonte-ui` 0e5342df.
- **U0.12 Logo et dock** (15:44, le propriétaire laisse le choix au pilotage : « Choisi tout seul ») : logo teinté en `encre` en thème clair **retenu** (dessin inchangé ; même couleur que la dominante pour 5 palettes, seule teinte lisible pour Neon, Obsidian et Solar sur fond clair) ; dock à 96 % d'opacité avec flou **retenu** (garde l'effet actuel du dock, que le propriétaire aime ; UI5 vérifie le contraste du libellé et des icônes sur la couleur composée, contenu clair ou sombre dessous). Le cahier §5.1 (« le logo garde sa teinte actuelle ») se lit désormais avec cette décision.
- **U0.13 Pause budget** (10/10/2026 17:11, demande du propriétaire : « à 80 % d'utilisation de crédit, mets en pause tout ce qui tourne concernant l'UI ») : interrupteur `pipeline/ui/PAUSE` lu par chaque session UI au démarrage et à chaque sauvegarde (PIPELINE_UI.md §5) ; quand il est posé, la tâche `trig_01Fqf4osZzdda75J4DqmoLB1` est désactivée et les points de pilotage UI ne relancent rien. Le pourcentage n'est lisible par aucun outil : le propriétaire le signale (« pause UI »). Les sessions déjà lancées avant cette règle (UI1 à UI4, 13:42 UTC) ne la relisent pas : elles s'arrêtent depuis leur page de session ; leur travail est sauvegardé toutes les 30 minutes sur `ui-sauvegardes/<LOT>`. KM1 (pipeline CP) n'est pas concerné.
- **U0.13 Délégation des décisions** (18:48, le propriétaire : « Prends les décisions qui doivent être prises en étant pertinent et ouvert à l'amélioration ultérieure ») : la conversation de pilotage tranche seule les choix de conception et de validation des lots UI1 à UI5 (comme C8), sans attendre le propriétaire. Chaque décision est écrite ici avec sa raison, la solution écartée et ce qu'il faudrait pour revenir dessus ; on préfère le choix réversible (un jeton, un réglage, un composant du kit) à celui qui fige ; un récapitulatif des décisions est donné au propriétaire à la livraison de dev6.12.0, pour ajustement sur téléphone. Restent hors délégation : les illustrations (Koach, logo, anatomie), la signature et les secrets, l'historique de `main`.

## UI0

Choix du lot (10/10/2026, session `session_01DfhZd3fMyMGSUKefFeRLGk`), détail dans `livraisons/LIVRAISON_UI0.md`. La conversation de pilotage valide ou corrige.

- **UI0.1 Version** : `pubspec.yaml` et `kVersion` restent à 6.11.1. « dev6.12.0-ui0 » est une étiquette de lot : une version X.Y.Z-ui0 casserait les tests de version et créerait un conflit dans `settings_screen.dart` à chaque lot. dev6.12.0 sera posée par UI5.
- **UI0.2 Rampe de l'anatomie** : elle va de `pleine` à `encre` quand l'encre s'en distingue (2,5:1). Sinon, la dominante est éclaircie (sombre) ou assombrie (clair). Neon sombre va vers sa secondaire. Fichiers d'illustration inchangés.
- **UI0.3 États communs** : la valeur du cahier est gardée, et sa tonalité n'est ajustée (même règle HCT) que si elle passe sous le seuil sur `haute`.
- **UI0.4 Logo en thème clair** : teinte `encre` au lieu de `pleine`. Identique pour 5 palettes, lisible pour Neon, Obsidian et Solar. Dessin inchangé. **À confirmer par le propriétaire.** La frise de semaine historique passe aussi en `encre`.
- **UI0.5 Adaptateur** : les textes Material des écrans historiques gardent leurs métriques (14/20, 15/20) jusqu'à leur lot. Les titres de section passent sans capitales partout (C6). En clair, les commandes posées en `haute` (= `fond`) reçoivent un contour `filet` (jeton `controlSide`).
- **UI0.6 Exceptions de zone** (prompt de UI0) :
  - `store.dart` : identifiants des 8 palettes, relecture des anciens, réglage `contrast` (écrit seulement s'il est actif) ;
  - `settings_screen.dart` : sélecteur, contraste, segments du thème ;
  - `dev/dev_widgets.dart` : poignée DEV de 16 dp, catalogue du kit.
- **UI0.7 Contrôle des lots** :
  - `ci-ui.yml`, sur `claude/ci-ui-<lot>` (complet) et `claude/ci-ui-<lot>-rapide` (formatage, analyse, tests `test/<lot>_*`, captures) ;
  - `tools/check_ui_tokens.py --zone <LOT> --menus` à 0 pour livrer ;
  - relevé de départ `tools/ui_tokens_depart.json` ;
  - tour `integration_test/tour_ui_test.dart`, joué aussi sur b7996b3f.
- **UI0.8 Règle de couleur** : un texte en `encre` ou `accent` ne se pose que sur `fond` ou `surface` (sur `haute`, 3,9:1 pour Bordeaux et Titanium).

## UI1

## UI2

## UI3

Choix du lot (10/10/2026, session `session_01JVF5cveTZDzybGVBq9M1XE`), détail dans `livraisons/LIVRAISON_UI3.md`. La conversation de pilotage valide ou corrige.

- **UI3.1 En-tête de l'onglet** : grand titre « Stats » et une phrase (C1), l'aide « Comprendre les XP » à droite ; rubriques en rangée défilante, rubrique active en pilule `pleine` (mêmes clés `stats-section-0` à `3`). Pas de logo dans l'en-tête (comme `KPage.root`) ; ouvert depuis une autre page (raccourcis de progression), Stats prend l'en-tête de sous-page.
- **UI3.2 Aperçu (§4.1)** : la carte du personnage, le défi, la campagne, le boss et la saison ouvrent l'onglet Parcours, plus aucune feuille. Les tuiles « Défis de la semaine », « Arbre de progression », « Performances et références », « Tout ton historique » deviennent un groupe « Aller plus loin » (Parcours, Performances, Historique : le nom de la destination, R1/R3). La feuille de la série et celle de l'activité restent sur leur carte (une seule entrée).
- **UI3.3 Parcours** : seule entrée des feuilles de jeu ; « Campagne, boss et saisons » devient trois lignes (Campagne, Boss, Saisons) ; les détails d'un chapitre ou d'un boss sont dans leur feuille, plus aucune feuille empilée. Branches Pratique / Rythme en `KSegmented` (la fourche dessinée disparaît, l'arbre des paliers reste).
- **UI3.4 Objectif de la semaine (R2, §4.3)** : réglé sur place dans sa carte de l'Aperçu, segments « Adaptatif, 2, 3, 4, 5, 6 » (valeurs 0, 2 à 6), application immédiate ; une valeur 1 déjà enregistrée reste affichée (« Fixé par toi : 1 jour par semaine », aucun segment allumé), sans migration. L'explication de la feuille passe sous les segments ; la feuille disparaît.
- **UI3.5 Records (U12)** : `records_screen.dart` n'affichait que Stats (aucune donnée de records) ; page refaite dans la zone, qui lit `exerciseBests` (game.dart, calcul des records de fin de séance) sans le modifier : par exercice, meilleure charge (× répétitions, 1RM estimé) et meilleure série au poids de corps, date du premier passage. Branchée dans Performances, à côté de « Mes références » (raccourci R2, ex « Modifier mes références ») ; groupes « Meilleure charge » et « Meilleures répétitions au poids de corps ».
- **UI3.6 Composant nouveau** : `lib/stats/widgets/k_info_sheet.dart` (`KInfoSheet`, `showKInfoSheet`) : feuille d'information au gabarit des feuilles du kit (poignée, titre et contexte, contenu, « Fermer »). À promouvoir dans `lib/kit/` par UI5.
- **UI3.7 Couleurs du jeu** : insigne de rang et radar aux couleurs de la palette (`pleine`, `encre`, `surPleine`) au lieu du rouge fixe ; rareté des badges en puce neutre avec icône (C5) ; données en `encre` / `second`, réussites en `validation` / `accent`.
- **UI3.8 Contournement local** : légende de la carte musculaire refaite dans `stats_performance.dart` (même texte « Dos · 12,6 », pilules qui passent à la ligne) : `MuscleLegend` (muscle_body.dart, intouchable) débordait à 320 dp × 200 %.
- **UI3.9 Références non renseignées** : regroupées en un groupe par section, suivi d'un bandeau « Mes références » (R5 : plus de « à compléter dans Références » sans lien).
- **UI3.10 Logo** : gardé dans l'en-tête de Stats (cahier §1), bien que `KPage.root` n'en ait pas.
- **UI3.11 R9 à l'affichage** : « références Pilotage » / « (Références) » des aides d'attributs (game.dart, hors zone) affichés « Mes références » ; texte source à corriger par UI5.

## UI4

Choix du lot (10/10/2026, session `session_01EcZvt7jo2rPQi194ZGu9FQ`), détail dans `livraisons/LIVRAISON_UI4.md`. La conversation de pilotage valide ou corrige.

- **UI4.1 Ouverture des Réglages** : `SettingsScreen({page, highlight})` et `enum SettingsPage { appearance, session, notifications, progression, data, about }` remplacent `section: int` ; une ligne s'ouvre par `SettingsScreen(page: …, highlight: '<id>')` (index : `lib/settings_search.dart`).
- **UI4.2 « Compatibilité 3D »** au lieu de « Diagnostic 3D » (R9) : le contrôle L13 interdit le mot « diagnostic » dans l'application.
- **UI4.3 « Passer »** du parcours du profil : sur une étape que `stepError` accepte vide ou dont toutes les questions sont du schéma 3 ; jamais sur l'accueil, le récapitulatif ni en modification d'une rubrique.
- **UI4.4 Formulaires** des feuilles et dialogues (profil, import, suppression) : sous-pages `KPage.sub` avec bouton en bas ; feuilles réservées aux actions et aux listes.
- **UI4.5 « Comment marche ton programme ? »** quitte le Profil (R1) : Mon programme et Aide et à propos.
- **UI4.6 Défaut du kit signalé** (bloquant pour UI5) : titres de `KTopBar.sub` tronqués par une ellipse ; correction proposée dans la livraison §7.

## UI5
