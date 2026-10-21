# Livraison RV1 — revue complète du code (dev7.5.0)

Lot de la voie App du pipeline CP (DECISIONS_CP.md C17.41, C17.43), demande du propriétaire du 20/10/2026 : « passe en revue tout le code pour corriger des bugs de logique, des bugs graphiques et autres ». Base : `main` 0e063fde (dev7.4.0, aucune publication du propriétaire pendant le lot). Données synthétiques seulement (C17.33.2) ; aucune clé, aucune référence, aucune donnée réelle.

- Publication : __MAIN__ ; build signé __BUILD__ ; contrôle complet `claude/ci-3d` __CI3D__.
- Paquets (`kalis_core`, `kalis_plan`, `kalis_adapt`, `kalis_bench`) : **inchangés**, revus en lecture (§ 5).

## 1. Ce qui change pour le propriétaire

- **Charges de poulie au pas de 2,5 kg** : l'extension triceps (et toute poulie) n'est plus servie à « 20,41 kg ». Cause : sans pas de poulie dans le profil, `kalis_adapt` compte la poulie en livres (2,5 lb = 1,134 kg ; 18 crans = 20,41 kg). L'application donne désormais aux moteurs le pas de 2,5 kg (minimum 2,5 kg) quand le profil n'en dit rien — le défaut de `kalis_plan`, donc le programme créé ne change pas.
- **Intervalles « 8× (30 s effort / 30 s repos) »** : une ligne par tour, Koach actif comme arrêté (avant : une ligne sur la séance écrite, une ligne par tour quand Koach servait). Chaque tour est pré-rempli à l'effort (30 s), sans repos ni chrono de tenue par ligne : le chrono des tours (en-tête du groupe, ou « Lancer 8 × 30 s / 30 s ») donne effort et récupération. La ligne importée est servie telle qu'écrite (Koach ne coupe plus de tours, le chrono et les lignes ne divergent plus).
- **Minute d'EMOM ratée** : « Minute ratée : laisse sa ligne non validée. » (« Départ raté » pour une E2MOM, E90s…) sous l'en-tête du départ chronométré, sans refonte.
- **Messages en séance** : la cible de Koach après une série (et son « Annuler ») n'est plus effacée aussitôt par le message du record ou par « Enchaîne ».
- Le reste : voir le tableau (§ 3) ; tout est invisible tant que rien ne casse (données, rappels, thèmes).

## 2. Découpage de la revue

Neuf sous-agents Opus, zones disjointes, chacun avec la consigne du prompt (bugs de logique, graphiques, autres ; fichier, ligne, reproduction, effet, gravité, correctif) ; chaque constat vérifié dans le code par la session avant correction, et couvert par un test.

| Zone | Fichiers |
| --- | --- |
| S — séance, chronomètres, enchaînements, E2MOM/EMOM, drop sets, saisie et flammes | `session_screen.dart`, `kit/session.dart`, `timers.dart`, `set_validation.dart`, `session_host.dart`, `resume_banner.dart`, `session_prefs.dart`, `koach/flame_icon.dart`, `adapt/flame_track.dart` |
| P — programme importé, protocoles, MON PROGRAMME, création | `imported_program.dart`, `program_*.dart`, `kit/program.dart`, `plan/`, `plan_store.dart`, `legacy_week_kinds.dart` |
| K — Koach et prise de main, arrêt d'urgence, réactivation | `koach1_store.dart`, `koach1/`, `koach/`, `koach_data.dart`, `journal_adapter.dart`, `dev/koach_inspector.dart` |
| M — magasin, sauvegarde / import / export / migration, démarrage | `store.dart`, `persistence.dart`, `backup_files.dart`, `data_control.dart`, `startup.dart`, `main.dart`, `retired_*`, `legacy_*`, `models.dart`, `kalis_clock.dart`, `safety_store.dart`, `profile_store.dart`, `evolution_store.dart` |
| A — adaptation 0.x, questionnaires, bilan du jour, douleur, zone rouge | `session_adapt_store.dart`, `adapt/`, `wellbeing*.dart`, `guided_tests.dart`, `training_estimate.dart` |
| H — accueil, historique, statistiques, records, jeu | `home_screen.dart`, `session_history.dart`, `stats_*.dart`, `records_screen.dart`, `progression*.dart`, `rewards.dart`, `game*.dart`, `levelup.dart`, `search.dart`, `nav_bar.dart` |
| R — réglages, kit, thèmes et palettes, notifications, mode dev | `settings_*.dart`, `kit/`, `app_theme.dart`, `notifications.dart`, `notification_settings.dart`, `dev/`, `profile.dart`, `arsenal_screen.dart`, `exercise_screens.dart` |
| F — profil de l'athlète, parcours v1/v3, atlas, carte 2D | `athlete_profile*.dart`, `profile_v3.dart`, `atlas*.dart`, `anatomy_screen.dart`, `muscle_map_2d.dart` |
| X — paquets (lecture seule) | `packages/kalis_core`, `kalis_plan`, `kalis_adapt` |

Puis une relecture indépendante du diff (sous-agent Opus) : six remarques, cinq corrigées avant publication (§ 4).

## 3. Constats et statuts

Statuts : **corrigé** (test de non-régression nommé), **signalé** (vrai mais hors périmètre sûr de ce lot, recommandation), **voulu** (comportement décidé, pas changé), **non confirmé**. Tests : `R` = `test/rv1_revue_test.dart`, `É` = cible émulateur `integration_test/rv1_parcours_test.dart`.

### Signalés par le propriétaire (priorité)

| # | Constat | Fichier | Gravité | Statut | Test |
| --- | --- | --- | --- | --- | --- |
| O1 | Extension triceps poulie servie à 20,41 kg (grille câble en livres par défaut) ; trois affichages différents (20,41 / « 20.41 » / 20,5) | `athlete_profile_store.dart` (`athleteProfileForEngines`, `withCableIncrement`) ; paquet `grid.dart:35` | majeur | corrigé (colle) ; bug de paquet signalé (X1) | R « charges » (scénario PR2 : 20,0 kg servis) |
| O2 | Intervalles : 1 ligne écrite, n lignes servies ; tours du groupe non recalés quand Koach coupe | `store.dart` (`setCount`, `logSpec`, `restAfterSet`, `exLog`), `session_screen.dart`, `imported_program.dart` (`asWritten`), `session_adapt_store.dart` (journal) | majeur | corrigé | R « intervalles », G10 et KB4 mis à jour, É J3 |
| O3 | Minute d'EMOM ratée : rien ne le dit | `session_screen.dart` (`_timingHeader`, `emomMissedHint`, groupes `emom`) | mineur | corrigé | R « écran de séance », É J4 |
| O4 | EMOM « volume » (KB4) : formes voisines | `store.dart` | — | vérifié tenu (8 × 3, 10 × 8, 12 × 18 ; « EMOM montant » inchangé) | KB4, É J4/J5 |

### Majeurs

| # | Constat | Fichier | Statut | Test |
| --- | --- | --- | --- | --- |
| S1 | Message de Koach (et « Annuler ») effacé par le record ou « Enchaîne » | `session_screen.dart` `_checkSet` | corrigé (un seul message : Koach, puis record, puis « Enchaîne ») | KB4/KM3 écran |
| S2 | Repos individuel au milieu d'un tour de groupe (circuit de 3, format au chrono) : remplace le chrono du groupe | `session_screen.dart` `_checkSet` | corrigé | É |
| S3 | Charge du moteur « 22, » (22,000000000000004) refusée à la validation | `adapt_texts.dart` `adaptKgField`, `adaptKg` ; `store.dart` `koachKg` ; `athlete_profile.dart` `_num` | corrigé | R « charges » |
| S5 | En livres, la cible de Koach remplacée par la charge de la 1re série | `session_screen.dart`, `store.dart` `massLabel` | corrigé | R « livres » |
| H1 | Accueil : semaine gardée dans l'état de l'onglet → `StateError` si le programme raccourcit, « Semaine 0 » sous `firstShown`, pas de passage à la nouvelle semaine le lundi (H9) | `home_screen.dart` `_syncWeek` | corrigé | É (accueil) |
| H2 | Records : tenues, durées, distances, intervalles comptés comme répétitions (« 45 reps », 1RM gonflé) ; séries écartées comptées (H11) | `game.dart` `exerciseBests`, `store.dart` `notRepsNames` | corrigé | R « records », G3 mis à jour |
| H3/H4/K9/S8 | Numéros de semaine internes au lieu des affichés (PR2) : résumé du jour, quête, campagne, boss, saisons, récap de Koach, titre du jour de repos | `home_screen.dart`, `game_widgets.dart`, `koach1_widgets.dart`, `session_screen.dart` | corrigé | É |
| P2 | « Départ du programme » ignore `firstShown` : choisir la date de son S1 affiché décalait tout le programme de 14 semaines | `program_start.dart` | corrigé (écran en semaines affichées) | É |
| M1 | Programme personnel illisible remplacé en silence puis effacé à l'écriture suivante | `store.dart` (`_instanceRaw`, import strict) | corrigé | R « sauvegarde » |
| M2 | Résultat d'AMRAP / pour le temps / chipper effacé comme une consultation | `store.dart` `isConsultation`, `inProgress` | corrigé | R « journal » |
| M3 | Copie compressée d'une session de test collée dans la session personnelle sans avertissement | `store.dart` `exportCompact`, `data_control.dart` | corrigé | R « sauvegarde » |
| M4 | Journal de Koach effacé si l'instantané est illisible (ou TypeError au démarrage) | `koach1_store.dart` `KoachEngineData` | corrigé (gardé tel quel, puis sous `illisible`) | R « sauvegarde » |
| K6 | Séance commencée la veille déclarée manquée après minuit, puis faite | `koach1_store.dart` rattrapage | corrigé | R « Koach » |
| K7 | Charge fixe (C15) : « Je te propose 22,5 kg » sur 20 kg fixes | `koach1_store.dart` `_koachFixed` | corrigé | — (lecture du code ; aucune proposition n'est autre qu'une charge) |
| K10 | Arrêt d'urgence pendant un calcul : le calcul réinstalle Koach ; séries versées pendant l'arrêt | `koach1_store.dart` `koachStop`, `koachAfterSet`, `koachEnsureTarget` | corrigé | R « Koach » |
| R1 | « Couleurs » et « Espacements » appliqués seulement au redémarrage | `main.dart` `themeFor` | corrigé | É (réglages) |
| R3 | Rappels au-delà de la semaine 40 jamais annulés | `notifications.dart` | corrigé (60 semaines) | R « sauvegarde » |
| R4 | Champs du thème invisibles en clair (fond = page, sans contour) | `kit/theme.dart` | corrigé (contour `filet`, UI0.5) | É clair |
| R5 | Segment et puce choisis indiscernables en Bordeaux sombre (1,01:1) | `kit/controls.dart` | corrigé (contour `encre`) | É sombre (réglages) |
| F1 | Enregistrer une rubrique du profil remettait une ancienne pesée (B4) | `athlete_profile_store.dart` | corrigé | R « profil » |
| F2 | « Je ne sais pas » effaçait tous les records sans confirmation | `athlete_profile_flow_v3.dart` | corrigé (seulement sans record) | — |
| F3 | Modifier un record d'un test guidé perdait son origine (proposé une seconde fois) | `athlete_profile_flow_v3.dart` | corrigé (même mesure : origine gardée) | — |
| A1 | Douleur ou temps du jour : exercice retiré par le moteur 0.x sans explication | `adapt/health_check.dart` | corrigé (carte « J'ai adapté ta séance ») | — |
| K1 | Lignes d'endurance servies par Koach sans `demand` (sans effet sur le modèle) | `koach1_store.dart` `_koachVerse` | signalé : pour les intervalles, la ligne est maintenant écrite (journal en tenues, comme avant RV1) ; recommandation : verser l'endurance par `koachSerieEndurance` dans un lot Koach | — |
| K3 | Course entre le rattrapage en arrière-plan et une série validée | `koach1_store.dart` | signalé (rare, demande un rejeu des événements ajoutés pendant le calcul) | — |
| K4 | Journal non tronqué si un calcul échoue après versement (doubles versements possibles) | `koach1_store.dart` | signalé (appliquer `couper()` partout ; aucune occurrence connue) | — |
| K5 | Jour 0 de Koach = lundi de la semaine de départ, programme parti un autre jour | `koach1_store.dart` | signalé (sans effet pour le propriétaire : départ un lundi) | — |
| P1 | `firstShownWeek` perdu après « bloc suivant » depuis l'instance générée | `store.dart`, `plan_store.dart` | signalé (décision : garder PR2 dans `PlanProgram` ; lot dédié) | — |
| P3 | Jours J d'un programme créé recalculés si le départ change de jour de semaine | `plan_program.dart`, `plan_store.dart` | signalé | — |
| A2 | Signaler une douleur pendant la séance (moteur 0.x) rétablit un ajustement refusé | `session_adapt_store.dart` | signalé (moteur 0.x, bloc en cours seulement) | — |
| F4 | Baisser son expérience efface records et échéances sans avertir | `profile_v3.dart` `pruneHidden` | voulu (C1.6) ; recommandation : avertir | — |

### Mineurs corrigés

« départ chaque minute » (au lieu de « toutes les 1 min »), « 1 tour » ; bouton « Repos » masqué sans repos (S9) ; popup des flammes fermée au lâcher d'un glissement (S12) ; `setState` après démontage (S14) ; double appui sur le bilan (A6) ; Endurance « indisponible » sans maximum (H6) ; « 1 exercice » (H12, P9) ; recherche de l'historique sans accents (H12) ; échéance de fin masquée par une échéance passée (P7) ; texte de l'écran de suppression exact (M8) ; « Voir l'aperçu » au-dessus du clavier (R9) ; livres à la virgule (R12) ; séparateurs de l'Arsenal (R14) ; séries dures gardées à 0 séance (F10) ; mois de l'échéance dans le passé (F8).

### Mineurs signalés (non corrigés, par gravité)

S6 message posé avant la barre de repos ; S10 récupération des intervalles égale à l'effort quand le programme n'en donne pas ; S11 palier de tenue d'un drop set validé comme des reps ; S13 arrêt d'urgence écran de séance ouvert ; S15 « Repos complet » en capitales ; K8 (couvert par O2) ; M5 « Où j'en suis » illisible perdu ; M6 échecs d'écriture répétés montrés une fois ; M7 export sans les données retirées si leur copie a échoué ; M9 origine périmée après un échec d'écriture ; A3 réglage « lb » ignoré par les textes du moteur 0.x ; A4 renvoi vers un professionnel absent de « Santé et sécurité » ; A5 textes douleur périmés ; A7 « Aucune douleur » perdu ; A8 saisies préparées vidées le lendemain ; A9 « 20,5 au lieu de 20,5 » ; H5 deux séries de semaines ; H7 jauge des journées masquées ; H8 titre « Gardien du repos » ; H10 merci jamais affiché ; P5 « S40 » internes dans quelques textes ; P6 Ma saison à cheval sur `firstShown` ; P8 lignes de course d'un programme créé lues en reps ; P10 cache sans mode prudent ; R6 « prochain rappel » GtG ; R7 signature de replanification ; R8 réglages 3D lus tard ; R10 contraste renforcé sur `haute` ; R13 « Sources et licences » ; F5 poids visé ; F6 messages techniques « $.x » ; F7 priorité en code ; F9 catégorie fantôme ; F11 niveaux perdus au changement de discipline ; F12 calendrier d'une échéance proche ; F13 carte 2D périmée ; F14 contrôleurs non libérés ; F15 saisies ignorées ; F16 test perso sans champs. Voulu : R11 « 2 min 30 » des réglages (format des réglages).

## 4. Relecture indépendante (sous-agent Opus, diff de `lib/`)

1. Intervalles servis tels qu'écrits : le journal des moteurs lisait l'effort (30) comme 30 répétitions de burpees → **corrigé** : un tour = une tenue en secondes, sans technique « densité » (comme quand Koach servait la ligne avant RV1) ; une ancienne séance d'une ligne garde sa lecture. Test R.
2. `{rounds: 0}` laissé par une série validée puis annulée rendait la séance « en cours » → **corrigé** (seul un vrai résultat compte). Test R.
3. Séance abandonnée jamais versée → **corrigé** : seule une séance commencée la veille est épargnée.
4. Journal de Koach illisible perdu dès que Koach repart → **corrigé** (gardé sous `illisible`).
5. Import strict refusant une sauvegarde dont un programme créé remplace l'instance → **corrigé** (contrôle seulement sans programme créé).
6. Historique d'une séance d'intervalles d'avant 7.5.0 relu en secondes → **corrigé** (relue comme avant).

## 5. Bugs de paquets (pour un lot moteur ; non corrigés ici)

| # | Paquet, fichier | Reproduction | Effet | Gravité | Correctif proposé |
| --- | --- | --- | --- | --- | --- |
| X1 | `kalis_adapt` `lib/src/grid.dart:35, 67` | profil sans `loadIncrements`, exercice `cable` | grille 2,5 lb (1,134 kg) ≠ `kalis_plan` 2,5 kg : 19,28 / 20,41 / 21,55 kg | majeur (contourné par l'application) | défaut `cable` à (2,5 ; 2,5) kg, table unique dans `kalis_core` |
| X2 | `kalis_adapt` `seance.dart` 3000-3023, 2626-2632 | « 8× (30/30) » réduit (`wod_echelle`, reprise, séance bornée) | groupe `intervals` resté à l'écrit (8 tours, 6 lignes) | majeur (contourné : ligne servie telle qu'écrite) | renvoyer les tours servis du groupe |
| X3 | `kalis_adapt` `seance.dart` 1679, 1486 | EMOM (`technique.intervals`) dont Koach baisse les séries (douleur, coupure, bilan) | technique incohérente, validation rejetée, cibles de Koach remplacées par l'écrit | majeur | recaler la technique après chaque changement de séries (`coherentTechnique`) |
| X4 | `kalis_adapt` `seance.dart` 4095-4100 | test xRM verrouillé, écrit hors grille | servi sous l'écrit (plancher) | mineur | garder l'écrit hors grille |
| X5 | `kalis_adapt` `seance.dart` 3441 | charge plafonnée (part du 1RM, douleur) puis `proche()` | jusqu'à un demi-cran au-dessus du plafond | mineur | `plancher` après un plafond |
| X6 | `kalis_adapt` `seance.dart` 3452-3463 | test adaptatif série 0 | un cran au-dessus du plafond écrit | mineur | comparer au plafond |

Recommandation : un lot moteur court (`kalis_adapt` 1.0.7 / Koach 1.0.8) pour X1 à X3, avec campagne du banc.

## 6. Tests et contrôles

- `test/rv1_revue_test.dart` : charges (bruit flottant, poulie, livres, scénario PR2 : extension triceps servie à 20 kg, toutes les charges servies au centième), intervalles (formes, ancienne séance d'une ligne, ligne importée servie telle qu'écrite, tours du groupe = lignes, journal en tenues), écran de séance (EMOM et E2MOM ratés, intervalles écrits), journal (AMRAP, `{rounds: 0}`), profil (pesée), Koach (séance commencée non manquée, arrêt d'urgence), sauvegarde (session de test compressée, import strict, journal de Koach illisible, records, rappels).
- Tests d'avant mis à jour pour les changements voulus : G10 (instantané 2.x : intervalles une ligne par tour, livres à la virgule), G3 (records sans tenues ni durées ; historique synthétique d'avant 7.5.0 : intervalles en une ligne), KB4 (intervalles), versions (G2, G3, KS1A, KM3, KB1, Python).
- Contrôle rapide `claude/ci-ui-rv1-rapide` (formatage, analyse, 28 suites touchées) vert, puis contrôle complet `claude/ci-3d` (§ 7).

## 7. Parcours sur l'émulateur

__EMU__

## 8. Limites et recommandations au pilotage

1. Valider dev7.5.0.
2. Lot moteur pour X1-X3 (§ 5) ; l'application contourne X1 et X2.
3. Signalés majeurs à traiter dans un lot application suivant : K3, K4 (robustesse du journal de Koach), P1 (PR2 après un bloc suivant), P3, A2 ; F4 (avertir avant d'effacer).
4. Les intervalles servis tels qu'écrits ne sont plus modulés par Koach (aucune réduction de tours) : choix de cohérence (C17.43.3) ; à changer seulement si le propriétaire veut que Koach raccourcisse ses finishers.

## 9. À tester (propriétaire)

- Installer dev7.5.0.
- Une séance avec poulie : charge à 2,5 kg près.
- Finisher d'intervalles : une ligne par tour, « Lancer » pour le chrono des tours.
- EMOM : l'indication « Minute ratée » sous l'en-tête.
- Réglages › Apparence : changer « Couleurs » s'applique tout de suite.
