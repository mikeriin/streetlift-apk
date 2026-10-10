# Livraison UI1 — Programme (dev6.12.0-ui1)

Lot UI1 du pipeline « Refonte UI et UX » (UI), lancé le 10/10/2026 à 14:55 par la conversation de pilotage (LANCEMENTS.md, section UI1), en parallèle de UI2, UI3 et UI4. La session `session_018ETAYadGCNKByTAfVnsshL` l'a pris à 13:42 UTC : le message de lancement n'avait pas de ligne « Lot : », UI1 était le premier lot « à faire ». Validation : conversation de pilotage (délégation C8), recommandation au §9.

| | |
| --- | --- |
| Branche | `ui/UI1` (depuis `refonte-ui` 0e5342df), tête `6ef33ad` |
| Contrôle complet | `claude/ci-ui-ui1`, run 38074505171 (commit de contrôle 80e5628, résultats 44eb639) |
| Contrôle rapide | `claude/ci-ui-ui1-rapide`, run 38074033149 : formatage, analyse, jetons de zone, tests `ui1_*` et captures verts |
| Sauvegardes | `ui-sauvegardes/UI1` (arbre sans `.github/`, `SAUVEGARDE.md`) |
| Version interne | dev6.12.0-ui1 (étiquette du lot ; `pubspec.yaml` reste à 6.11.1+114, décision UI0.1) |
| Accès | `add_repo` n'existe pas dans la session ; push vérifié par `git push --dry-run origin pipeline`, puis par la prise du lot. Pas de SDK Flutter dans la session (domaines de téléchargement refusés par le proxy) : compilation, formatage, tests et captures passent par le contrôle rapide. |

## 1. Ce qui est livré

Cahier §7.3 « UI1 », §4.1 (onglet Programme), §4.3 (déplacements de la zone), §4.6 (récompenses), R4 à R8, C1 à C13 ; tous les fichiers de la zone au kit (`check_ui_tokens.py --zone UI1 --menus` : **0**, contre 92 au départ).

1. **Accueil** (`home_screen.dart`, maquette « Accueil »)
   - En-tête dans la page : niveau (« Niv. », chiffre, barre `encre`), semaine (« SEMAINE 8 ▾ » en `titreEcran`, dates, bloc et rang dans le bloc « Bloc 1 — Hypertrophie, semaine 5 sur 8 »), logo (gestes du mode dev gardés). Aucune troncature : la semaine passe à la ligne ; au-delà de 130 % de texte, niveau et logo sur la première ligne, semaine dessous.
   - **Barre de saison par blocs** (`KSeasonBar`, U7) à la place de la frise de 40 points : mêmes gestes (appui : détail ; appui long : choix ; glisser ; clavier : flèches, début, fin, Entrée, F2), cible de 48 dp, contour `encre` au focus clavier.
   - Lignes de jour (48 dp, 56 pour un titre sur deux lignes, rayon 20, état écrit « En cours » / « Reprise » et icône), carte du jour `KCard.day` (dominante exacte, surtitre et état sur une ligne de texte, titre jamais coupé, durée en `chiffre` qui se réduit plutôt que de se couper, volume au format C9 ; Koach et carte des muscles inchangés, sous les textes au-delà de 130 %).
   - **Ligne permanente « Mon programme »** (`KMenuRow`, « Saison, évolution, calendrier, changer de programme »), juste après les jours ; cartes du moment ensuite, toutes dans le flux (C8), réserve du dock en bas de liste.
   - Choix de semaine en **feuille de liste** (`KListSheet`), ouverte sur la semaine affichée ; détail de la semaine en feuille de contenu avec, par jour, appui (ouvrir) et **bouton ⓘ (résumé, R7)**, « Revenir à la semaine actuelle », « Choisir une semaine ».
   - **Récompenses après « Fin de séance » (§4.6)** : `openProgramDay` attend la fin de la fermeture de la séance et ne vérifie le niveau que si rien n'a été ouvert par-dessus ; la fin de séance de Koach (`AdaptSummaryScreen`, ouverte à la fermeture) présente elle-même les récompenses quand on la quitte. Prouvé par `test/ui1_programme_test.dart` (« §4.6 : les récompenses viennent après « Fin de séance » », qui reproduit l'enchaînement de `_finish` ; échouait avant : la récompense passait sous la fin de séance) et par le cas inverse (sortie sans fin de séance : la vérification a toujours lieu).
2. **Mon programme** (`program_screens.dart`, maquette « Mon programme ») au gabarit de menu : en-tête « Mon programme » et une phrase (le programme en place, sans « révisions LC1 » ni « programme du moteur », R9) ; carte **Ma saison** (compte à rebours en grand, échéance, phase, prochaine semaine particulière ; toute la carte ouvre Ma saison) ; carte **Évolution** (mode, déblocage, propositions et historique) ; groupes **Calendrier** (« Départ du programme » avec sa date, « Où j'en suis » avec la position), **Changer de programme** (« Préparer le bloc suivant » quand il est proposé, programme importé compris ; « Créer un nouveau programme », sa raison écrite dessous s'il est indisponible, R6 ; « Créer mon profil » sans profil ; **« Revenir à un programme précédent »**), **Aide** (« Comment marche ton programme ? ») ; outils de test en groupe de menu (session de test).
3. **« Revenir à un programme précédent »** (§4.3, R8) : feuille d'actions listant les retours possibles (ancien programme pendant 7 jours ; programme d'origine, désactivé avec sa raison s'il ne peut plus être rendu) et, quand la sauvegarde d'origine existe, « Exporter la sauvegarde d'origine » ; chaque retour est confirmé (`KConfirm`, verbe « Revenir »). La carte d'accueil « Revenir à l'ancien programme » passe aussi par la confirmation.
4. **Ma saison** (`season_view.dart`) : carte d'échéance (nom, date en grand, compte à rebours, bouton tonal « Jour J : tentatives / rythme »), **frise des phases** (`KTimeline`, phase en cours écrite « en cours »), « Bloc n, semaine par semaine » (groupe de lignes), figures et règles en groupes ; vide : `KEmpty` avec l'action qui donne une saison (R6). Dates de phase calculées au jour civil (un passage à l'heure d'hiver décalait la fin d'une phase d'un jour).
5. **Jour J** (`event_day_screen.dart`) : titre « Jour J » (R3), l'échéance et sa date en phrase ; objectif en segments (`KSegmented`, libellés courts, phrase complète dessous) ; tentatives avec boutons-icônes nommés de 48 dp ; « Poids du corps » au lieu de « 0 kg ».
6. **Évolution** (`evolution_widgets.dart`) : mode en **segments** (`KSegmented`, seul réglage du mode, §4.3), déblocage, propositions, historique (état en puce neutre, « Annuler ce changement » tonal) ; sans profil : « Créer mon profil » (R6). Feuille « ce qui change » et carte de séance au gabarit ; carte de l'accueil sans teinte.
7. **Où j'en suis** (`program_position.dart`) : semaine au pas à pas (boutons ronds nommés), séances en groupe de lignes à choix unique, bouton principal fixé en bas.
8. **Comment marche ton programme ?** (`program_explainer.dart`) : feuille de contenu ; les deux chemins écrits (« Réglages › Profil », R5) deviennent des liens « Ouvrir Évolution », « Ouvrir mon profil ». Écran « Ton programme » d'un nouveau profil : grand titre, logo, bouton principal, raison écrite s'il est indisponible (R6).
9. **Feuilles de la création** (`plan_sheets.dart`) : variantes, ajout (puces des jours, `KSearchField` « Rechercher un exercice » sans nombre écrit, §4.4), « ce que j'ai changé » (lignes « Pourquoi ? » dépliables), réglage d'un exercice en `KStepperRow` ; titres ajoutés aux feuilles qui n'en avaient pas.
10. **Bulle de Koach** (`koach_bubble.dart`, conteneur seulement) : `haute` en sombre, `surface` bordée en clair, rayon des menus avec la pointe vers Koach, actions du kit ; `KoachSays` met Koach au-dessus du texte à 150 % et plus ; `showKoachSheet` au gabarit de feuille ; en-tête `KoachHeader` sans capitales (C4). Poses, dessins et répliques inchangés.
11. **Reprendre** (`resume_banner.dart`) et **niveau** (`levelup.dart`) au kit.

## 2. Avant → après, écran par écran (aucune information perdue)

| Écran | Avant (dev6.11.1) | Après |
| --- | --- | --- |
| Accueil, en-tête | barre d'outils : « NIV. n » + barre de la couleur secondaire ; « SEMAINE n ▾ » 15 px, « dates · bloc » coupé par « … » ; logo | dans la page : « Niv. n » + barre `encre` ; « SEMAINE n ▾ » 22 ; dates ; bloc et rang dans le bloc (ajout) ; logo ; rien de coupé |
| Accueil, frise | 40 points + pastille « Sn » ; appui, appui long, glisser, clavier | barre par blocs (6 blocs du programme), pastille « Sn » ; mêmes gestes, mêmes annonces TalkBack |
| Accueil, jours | lignes 13 px coupées à 1–3 lignes ; état icône, « En cours »/« Reprise » écrits ; appui long caché | lignes de jour 15 en capitales, jamais coupées ; mêmes états ; appui long gardé + ⓘ dans la feuille de la semaine (R7) |
| Carte du jour | « J4 · AUJOURD'HUI », titre 2 lignes max, durée 25 px, « Estimé · repos inclus », « n exercices · n séries », volume ; Koach ; carte des muscles | mêmes informations, durée en `chiffre` 36, « n exercices, n séries, volume » (C9) ; Koach et carte inchangés |
| Accueil, bas | cartes du moment ; « Mon programme » seulement sur la carte du programme (conditionnelle) | ligne permanente « Mon programme » ; mêmes cartes du moment |
| Feuille « Choisir une semaine » | liste Material (n°, « Semaine n · dates », bloc, « Semaine actuelle », « fait / total ») | feuille de liste : n°, « Semaine n », dates, bloc, semaine actuelle, « x / y journées validées », semaine affichée en contour, semaines faites cochées ; ouverte sur la semaine affichée |
| Feuille de la semaine | titre, dates, bloc, cycle, « x / y journées validées », jours (Jn, titre, « n exercices · durée »), « Revenir à la semaine actuelle », « Choisir une semaine », « Fermer » | mêmes éléments + ⓘ par jour (résumé) |
| Résumé d'un jour de repos | feuille sans gabarit | feuille de contenu, mêmes textes |
| Mon programme | page « MON PROGRAMME » : carte modèle, « Ta saison » + « Voir la saison », programme d'origine (texte, « Revenir à mon programme d'origine » par dialogue, « Exporter cette sauvegarde »), « Évolution de ton programme » + « Mode, historique, déblocage », carte « Revenir à l'ancien programme » (sans confirmation), « Où j'en suis », « Préparer le bloc suivant », « Mon profil » / « Créer mon programme », outils de test | gabarit de menu (§4.1) : phrase du modèle ; cartes Ma saison et Évolution (cartes entières) ; Calendrier (Départ du programme — ajouté ici, §4.3 —, Où j'en suis) ; Changer de programme (bloc suivant, nouveau programme, revenir : feuille + confirmations, export dans la feuille) ; Aide (ajoutée) ; outils de test. Tous les textes du programme d'origine sont dans la feuille et la confirmation |
| Ma saison | « MA SAISON » : carte d'échéance (accent), « Jour J : … » en lien, phases en lignes à icônes, semaines du bloc, figures et règles en cartes | « Ma saison » : carte d'échéance, Jour J en bouton tonal, frise des phases, groupes ; même contenu (le nom de l'échéance n'est plus répété sur chaque phase : il est en tête) |
| Jour J | titre = nom de l'épreuve en capitales ; puces d'objectif ; tentatives | titre « Jour J », nom et date en phrase ; segments ; mêmes tentatives, échauffement, rythme, raisons |
| Évolution | « ÉVOLUTION » : `SegmentedButton` Material, déblocage, propositions, historique (badge coloré) ; sans profil : texte sans action | « Évolution » : `KSegmented`, mêmes cartes, puce neutre ; sans profil : « Créer mon profil » |
| Où j'en suis | flèches à contour, cartes à cocher, bouton dans la liste | pas à pas, groupe à choix unique, bouton fixé en bas ; mêmes textes |
| Comment marche ton programme | feuille Material, 8 étapes, « Compris » | feuille de contenu, 8 étapes, liens vers Évolution et Profil (R5), « Compris » |
| Feuilles de la création | variantes (sans titre), ajout (« 1 039 exercices » écrit), diff (sans titre), réglage (± à contour) | titres ajoutés, mêmes choix et clés, recherche du kit, pas à pas du kit |
| Bulle de Koach | gris `#2B2B2B` / blanc, rayon 16 + pointe 4, boutons Material | `haute` / `surface` bordée, rayon 20 + pointe, boutons du kit ; mêmes poses et répliques |

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Jetons de zone (`--zone UI1 --menus`) | **0** (92 au départ) ; `lib/plan/widgets/program_widgets.dart` (à promouvoir) compte 1 `showModalBottomSheet` dans la colonne UI5 |
| Formatage, analyse | verts |
| Tests `ui1_*` | 15 tests dans `test/ui1_programme_test.dart`, verts (rapide et complet) |
| Suite complète, tests du mode dev | verte : 877 tests passés, 31 ignorés (captures hors mode capture) ; mode dev : 18 passés, 1 ignoré ; paquets Dart (moteurs) verts ; build debug et profile verts (APK profile 61,5 Mo compressés) |
| Captures `ui1_*` (rendus de test) | 64 PNG : accueil (haut, bas, feuille de la semaine, choix de semaine), Mon programme (haut, bas), « Revenir… » et sa confirmation, explication, Ma saison (haut, bas), Jour J, Évolution, Où j'en suis × sombre/clair × bordeaux/neon ; 320 dp × 200 % : accueil (haut, bas, feuille de la semaine), Mon programme, Ma saison, Jour J, Évolution, Où j'en suis |
| Tour sur émulateur | vert : avant et après, quatre parties (a à d) à 0 ; captures `ci-out/tour/avant|apres/` |
| Cibles émulateur des lots précédents | vertes : les 16 cibles (CI1g, CI1f, CI1e, CI1c, CI1, CU, G10, G9, G7, G6, G5, G3, G2, G1, M8, M7) passent. Au run 38074505171, CI1c b et CI1g b sont tombées avant tout test (service VM injoignable, « device offline »). Une relance des tâches échouées a fait passer CI1c ; CI1g b est encore morte au démarrage (« Service has disappeared », pression mémoire de l'émulateur, `lowmemorykiller`). Diagnostic sur le même arbre (run 38083944297, commit de contrôle 2f583b4, script réduit à CI1g, journal complet) : **b sur émulateur neuf 0, a 0, b de nouveau 0**. Échec d'émulateur, pas de UI1. Sur la branche de contrôle seulement : `ui/UI1` n'est pas touchée. |
| Rendus de test historiques (`captures=failure`) | rouge **comme sur la base et à UI0** : `visual_capture_test` (échoue déjà sur dev6.11.1) ; `l5c_ecrans_capture_test` vert mais signale « historique_seance 320 200 % : débordement de 18 px », déjà présent sur `claude/ci-ui-ui0` (écran de UI2, `session_history.dart`, hors zone, non touché) |
| 320 dp et 200 % sans débordement (accueil sombre et clair ; Mon programme, Ma saison, Jour J, Évolution, Où j'en suis, haut et bas) | vert (tests) |
| Cibles 48 dp et boutons nommés (`androidTapTargetGuideline`, `labeledTapTargetGuideline`) : accueil, Mon programme | vert |

Relecture indépendante (sous-agent Opus : cahier, maquettes, captures avant / après) : 21 constats, verdict « à corriger ». Traitement :

| N° | Constat | Suite |
| --- | --- | --- |
| 1 | C9 : « ≥ 38 min », volume « · », secondes | Volume composé « n exercices, n séries, 438 rép., 135 s d'effort » (C9). « ≥ » et les secondes viennent de `training_estimate.dart` (logique, hors zone) : écart écrit, à traiter par UI5 avec le propriétaire du format (§5). |
| 2 | Dates de phase décalées d'un jour (heure d'hiver) | Corrigé : jour civil. |
| 3 | « Exporter la sauvegarde » absent de la feuille | Présent quand la sauvegarde d'origine existe (cas non capturé dans les rendus : programme créé dans un test, sans origine) ; vérifié par l'intégration `koach_ci1e` (programme du propriétaire). |
| 4 | R3 sur Jour J | Corrigé : titre « Jour J », échéance en phrase. |
| 5 | Barre de niveau | Barre du kit (`KProgressBar`, `filet` / `encre`) ; à 0 % la barre est vide (profil neuf des rendus). Gardé. |
| 6 | État orphelin à 320 dp | Corrigé : surtitre et état sur une ligne de texte avec gluon de mots. |
| 7 | Couverture | 320 dp × 200 % ajoutés pour la feuille de la semaine, Jour J, Évolution, Où j'en suis ; tour sur émulateur complété (§5). Cartes du moment des autres zones (tests guidés, profil à compléter) : fichiers de UI4. |
| 8 | Segments de Jour J serrés | Corrigé : libellés courts, phrase complète dessous. |
| 9 | Place de la ligne « Mon programme » | Gardée juste après les jours : place fixe quelles que soient les cartes du moment (§4.1 : « toujours visible après la liste des jours »). Écart écrit. |
| 10 | « Plus tard » en lien coloré | Corrigé : lien neutre `texte2`. |
| 11 | Phase en cours seulement par la couleur | Corrigé : « en cours » écrit. Repère `accent` de l'échéance : non (composant du kit). |
| 12 | Hiérarchie de la carte Ma saison | Phase en `detail`, quatre niveaux. |
| 13 | Textes à zéro | Corrigés (« Aucun changement pour l'instant », « Aucune semaine de séances suivie pour l'instant »). |
| 14 | Libellés de la semaine différents | Corrigé : « x / y journées validées » partout, virgules. |
| 15 | Mode assisté décrit deux fois | Même phrase des deux côtés. |
| 16 | « ? » du titre de l'explication | Corrigé. |
| 17 | Conséquence du retour | Précisée (« Ton nouveau programme est retiré… »). Retour non destructeur (le programme se recrée) : verbe sans `danger`. |
| 18 | Chevrons dissymétriques | Bouton-icône du kit : l'état désactivé n'a pas de fond. Signalé à UI5. |
| 19 | Précision des kg, « 0 kg » | « Poids du corps » ; arrondi des kg : `adapt_texts.dart` (UI2), signalé. |
| 20 | Apostrophe droite | Texte des règles écrit par le moteur (`kalis_plan`), hors zone. |
| 21 | Jeux de données différents | Voulu : programme du propriétaire pour l'accueil, programme créé avec Koach (saison, Jour J) pour Mon programme ; le tour sur émulateur utilise un seul profil. |

## 4. Captures clés

Sur `claude/ci-ui-ui1`, commit f35648c « CI UI : résultats du run 38074505171 » (les résultats du diagnostic 38083944297 qui le suivent portent les mêmes captures, l'arbre de l'application étant identique) :
- rendus du lot : `ci-out/captures-ui/ui1_<écran>_<bordeaux|neon>_<sombre|clair>.png` (écrans : `accueil`, `accueil_bas`, `semaine`, `choix_semaine`, `mon_programme`, `mon_programme_bas`, `revenir`, `revenir_confirmation`, `explication`, `ma_saison`, `ma_saison_bas`, `jour_j`, `evolution`, `ou_j_en_suis`) et `ui1_320_*` ;
- tour : `ci-out/tour/apres/tour_<a|b|c|d>_<nn>_<écran>.png` (a = sombre bordeaux perso ; b = clair neon perso ; c = sombre neon session de test ; d = clair bordeaux session de test), mêmes noms dans `ci-out/tour/avant/`. À regarder : `accueil`, `accueil_bas`, `mon_programme`, `mon_programme_bas`, `ma_saison`, `evolution`, `ou_j_en_suis`, `jour_j`.

## 5. Mesures

**Parcours** (§6.3, tour, profil d'exemple avec une compétition dans 12 semaines ; « Mon programme » mesuré sans carte du moment, la proposition « Où j'en suis » remise à demain, LANCEMENTS.md) :

| Parcours (appuis depuis l'accueil) | Avant | Après |
| --- | --- | --- |
| Mon programme | 3 | **1** |
| Ma saison | 4 | **2** |
| Évolution | 4 | **2** |
| Jour J | 5 | **3** |
| Mes références (UI3) | 3 | 3 |
| Réglage du repos (UI4) | 2 | 2 |

Mêmes valeurs dans les quatre parties du tour (sombre bordeaux perso, clair neon perso, sombre neon session de test, clair bordeaux session de test).

**Contrastes** : aucune couleur hors rôles ; textes `encre` et `accent` seulement sur `fond` ou `surface` (UI0.8) ; texte sur la carte du jour en `surPleine` (≥ 4,79:1, UI0).

**Contenu sous le dock** : aucun élément sous le dock (accueil, stats, arsenal, réglages), dans les quatre parties, avant comme après ; `carte_du_moment` = faux pendant la mesure.

## 6. Écarts aux maquettes et au cahier

- **Ligne de jour** : composant de zone `ProgramDayRow` plutôt que `KDayRow` : le kit ne porte ni « En cours » / « Reprise » écrits (L5), ni l'état dans le libellé TalkBack, ni le ⓘ à côté de l'état (R7). Icônes d'état de la maquette (cercle coché, cercle vide). À fusionner dans `KDayRow` (UI5).
- **Lignes de jour à 48 dp** (56 pour un titre sur deux lignes) au lieu des 52 de la maquette, en-tête sur deux lignes (semaine ; « dates · bloc, semaine x sur y ») et écarts resserrés : avec les vraies polices, la semaine entière doit rester visible à 390 × 844 au-dessus du dock (test L5, assertion gardée ; le test charge désormais les polices de l'application au lieu de la police de test Ahem, qui faussait les mesures).
- **Carte du jour** : titre en `titreSeance` (20) et marges de 16 pour que la semaine entière tienne à l'écran (L5) ; la maquette, plus haute (960), montrait 24.
- **Place de la ligne « Mon programme »** : juste après les jours, avant les cartes du moment (place fixe).
- **« ≥ n min » et secondes d'effort** : format de `training_estimate.dart` (logique) inchangé.
- **Bulle de Koach** : rayon 20 et pointe de 4 (la forme de bulle est gardée, §1).
- **Mon programme** : `KPage.sub` + groupes plutôt que `KMenuPage(root: false)` : la phrase du modèle porte la clé `program-model` (tests d'intégration).
- **Choix de semaine** : ouvert sur la semaine affichée (`showProgramListSheet`), `showKListSheet` s'ouvrant toujours en haut d'une liste de 40.

## 7. Fichiers touchés hors de la liste de UI1 (§7.2) et pourquoi

| Fichier | Changement | Raison |
| --- | --- | --- |
| `lib/plan/widgets/program_widgets.dart` (nouveau) | `showProgramSheet`, `ProgramSheetHeader`, `ProgramDayRow`, `WhyTile`, `showProgramListSheet` | Composants manquants au kit, créés « dans `lib/<zone>/widgets/` et signalés » (§7.2) ; à promouvoir par UI5 |
| `test/programme_test.dart` | polices réelles chargées ; lignes ≤ 56 dp ; « Niv. » ; « Semaine 9 » choisie dans la feuille de liste (ouverte près de la semaine affichée) ; défilement dans la feuille de la semaine | Maquette ; mêmes comportements et assertions |
| `test/level_fill_test.dart` | « Niv. » | Maquette (C4) |
| `test/l5c_selecteur_test.dart`, `test/ui_refactor_test.dart` | pastille « Sn » lue dans la barre de saison | U7 ; même assertion |
| `test/g7_plan_test.dart`, `integration_test/programme_g7_test.dart` | « + » des séries trouvé par son nom (« Séries : plus ») | pas à pas du kit (boutons sans clé) ; même parcours |
| `integration_test/koach_ci1e_test.dart` | retour à l'origine par « Revenir à un programme précédent » › « Revenir à mon programme d'origine » › « Revenir » ; état relu dans la feuille | §4.3 ; mêmes relevés et attentes |
| `integration_test/tour_ui_test.dart` | profil d'exemple avec une compétition ; Mon programme mesuré sans carte du moment ; écrans `mon_programme_bas`, `ou_j_en_suis`, `jour_j` | LANCEMENTS.md (UI1) |
| `test/ui1_programme_test.dart`, `test/ui1_programme_capture_test.dart` (nouveaux) | tests et rendus du lot | PIPELINE_UI.md §3 |

Aucune assertion retirée sans remplacement.

## 8. Composants à promouvoir (UI5) et besoins signalés

- `showProgramSheet` (feuille de contenu : la moitié des feuilles de l'application n'est ni d'actions ni de liste) ; `ProgramDayRow` → `KDayRow` (états écrits, ⓘ) ; `WhyTile` (« Pourquoi ? » dépliable) ; `showKListSheet` avec élément initial.
- Kit : `KIconButton(filled)` sans fond une fois désactivé ; `KStepper` sans clé de boutons ; repère `accent` d'échéance dans `KTimeline`.
- UI4 : bandeau « Nouveau : 11 questions… » (`profile_completion.dart`) et carte des tests guidés (`guided_tests.dart`) à passer au kit (`KNotice`) ; ils sont déjà dans le flux de l'accueil, au-dessus du dock.
- UI2 : arrondi des kg de `adaptKg` ; format « ≥ » des durées partielles (`training_estimate.dart`, logique).

## 9. Limites

- Pas de SDK Flutter dans la session : tout a été vérifié par le contrôle rapide puis complet.
- Émulateur de la CI instable en fin de série (pression mémoire) : deux cibles relancées, une confirmée par un diagnostic (§3). Le dernier commit de `claude/ci-ui-ui1` est ce diagnostic (script d'émulateur réduit), jamais reporté sur `ui/UI1`.
- Temps d'image non mesurés (mesure de UI5, `docs/PERFORMANCE.md`).

## 10. Recommandation (C8, le pilotage décide)

**Valider UI1 et fusionner `ui/UI1` (6ef33ad) dans `refonte-ui`.**

- L'onglet Programme est au kit dans toute la zone (jetons 0) ; aucune information n'est perdue (§2).
- Les quatre parcours de la zone raccourcissent : Mon programme de 3 à 1 appui, Ma saison et Évolution de 4 à 2, Jour J de 5 à 3. Rien n'est sous le dock.
- Les récompenses arrivent après « Fin de séance » (§4.6, prouvé par un test qui échouait avant).
- Contrôles verts : suite Dart, mode dev, paquets, tour avant et après, cibles émulateur (diagnostic ci-dessus).

À suivre par UI5 :

- promouvoir `program_widgets.dart` (§8) ;
- décider du format « ≥ n min » avec le propriétaire de `training_estimate.dart` ;
- corriger le débordement de `historique_seance` à 320 dp × 200 % (UI2, présent depuis UI0).
