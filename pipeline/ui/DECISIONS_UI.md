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

## UI4

## UI5
