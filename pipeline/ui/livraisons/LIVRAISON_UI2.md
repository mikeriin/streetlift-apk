# Livraison UI2 — Séance (dev6.12.0-ui2)

Lot UI2 du pipeline « Refonte UI et UX » (UI), lancé par le pilotage le 10/10/2026 à 14:55 (LANCEMENTS.md, section UI2), en parallèle de UI1, UI3 et UI4. La session `session_01UBKNgcL6KGVgMUfEL3Fzdo` l'a pris à 13:43 UTC : le message de lancement n'avait pas de ligne « Lot : », UI2 était le premier lot « à faire ». Validation : conversation de pilotage (C8), recommandation au §10.

| | |
| --- | --- |
| Branche | `ui/UI2` (depuis `refonte-ui` 0e5342df), tête `ca9a583` |
| Contrôle complet | `claude/ci-ui-ui2`, run 38076888632 (commit de résultats d4957c0) |
| Contrôle rapide | `claude/ci-ui-ui2-rapide` (tests `test/ui2_*`, captures ; pendant le lot, des copies des tests de séance y étaient ajoutées pour les jouer vite) |
| Sauvegardes | `ui-sauvegardes/UI2` (arbre sans `.github/`, `SAUVEGARDE.md`) |
| Version interne | dev6.12.0-ui2 (étiquette du lot ; `pubspec.yaml` reste à 6.11.1+114, comme UI0.1) |
| Accès | `add_repo` absent de la session : push vérifié par `git push --dry-run origin pipeline`, puis par la prise du lot |

## 1. Ce qui est livré

Cahier §7.3 « UI2 », règles C1 à C13, §4.1 (ligne « Séance »), §4.3, §4.6, sur les seuls fichiers de UI2 (§7.2) :

1. **En-tête de la séance** (C1, C3) : retour, titre de la séance en capitales par le jeton (U3), jamais coupé (il passe à la ligne), repère « S12, J1 » comme la maquette, une seule action ⋮. Même en-tête pour l'historique d'une séance passée.
2. **Repère de page** : « Exercice 3 sur 7 » (maquette), lien « Exercices » en `encre`, points de progression au système (page courante en pilule `encre`, pages passées `texte2`, suivantes `texte3` ; le rôle historique `action` n'est plus utilisé, point laissé par UI0).
3. **Menu ⋮ en feuille d'actions** (§4.1, C10, R8, R9) : titre « Séance » et contexte ; groupe 1 « Consignes de séance », « Bilan du jour », « J'ai seulement… minutes », « Je m'entraîne ailleurs » ; groupe 2 « Douleur ou malaise ? » (icône en `avertissement`), « Mes références » ; dernier groupe, en `danger`, « Supprimer l'historique de cette séance », confirmé (`showKConfirm`, verbe « Supprimer »). « Références (feuille Pilotage) » et « Effacer l'historique » disparaissent (R9, R8).
4. **« Douleur ou malaise ? »** ouvre le Bilan du jour détaillé **défilé jusqu'à la section Douleur**, avec un lien « Conseils de sécurité » (page Santé et sécurité) ; la douleur enregistrée passe au moteur comme depuis le bilan (`reportSessionPain`, même `store.adaptAnswer`) ; « Passer » n'applique rien. Séance sans moteur : la page Santé et sécurité, comme avant.
5. **ⓘ d'un exercice** : feuille de contenu (consignes, « Pourquoi », estimation) et bouton **« Voir la fiche »** (fiche d'Arsenal existante, `openExerciseSheet`, fichier de UI4 appelé sans modification) quand l'exercice est dans la base.
6. **Liste des exercices en feuille de liste** (`showKListSheet`) : « Dans cette séance », résumé « 6 exercices, 56–64 min », Bilan du jour et Bilan de séance avec icône, exercices numérotés avec leur prescription, page courante cernée d'`encre`, exercices finis cochés en `validation`.
7. **Retour à l'exercice en cours** après un choix de temps ou de lieu (§4.6) : la séance recalculée revient sur la page d'où l'on vient (repérée par l'exercice), et non sur le Bilan du jour.
8. **Carte d'exercice** (maquette « Séance ») : titre `titreSeance` en capitales sans troncature ; charge chiffrée en grand chiffre `encre` (« 62,5 kg ») et volume, ou le volume seul en grand chiffre ; puces neutres sur la même ligne (C5 : plus de puce « Reps » rouge, plus d'intensité colorée) ; consigne de technique : titre en `encre` sans capitales, texte en texte courant (C5) ; lignes de douleur toujours visibles (bouclier `avertissement`) ; **notes du coach et calibrage en deux lignes ouvrables** (groupe `haute`, rayon 20, chevron ; l'appui sur le panneau de consignes ouvre toujours la feuille de Koach, comme avant) ; charge « à renseigner » devenue **un lien visible vers « Mes références »** (R2) ; « S11 : … » avec « Reprendre » en bouton tonal ; chronos de mode en boutons tonaux pleine largeur (le bouton plein reste unique à l'écran, C2).
9. **Tableau des séries** (en-tête `KSetTable`, lignes aux mesures de `KSetRow`) : champs en pilules de 48 dp (C13), chiffre `chiffreMoyen` entier à 200 % (le champ ne grossit plus au-delà de 130 %), ligne courante en `haute` cernée d'`encre` avec champs en `surface`, champ refusé cerné de `danger`, numéro qui se réduit au lieu de se couper, lignes de même rôle numérotées (« Test 1 », « Test 2 »), coche et sablier de 48 dp. Les gestes d'un champ sans focus vont à la pilule : un appui sélectionne tout, **un glissement horizontal parti d'un champ change de page**.
10. **Barre d'outils de série** : −, +, « n séries » (entier, il se réduit), note, colonnes ; tout à 48 dp (C13) ; « Colonnes » devient une feuille d'actions (cases « Charge (kg) », « Vitesse (m/s) »).
11. **Barre de repos** : `KRestBar` du kit pour tout décompte (libellés de phase en texte courant : « Repos », « Effort 2/8 », « Prêt », C4) ; chronomètre montant et décompte terminé : même barre sans −15 s / +15 s (« Fermer » à la fin) ; masquée sur la page Bilan de séance (un seul aplat, C2 ; le chrono continue).
12. **Messages courts** (C8) : message de Koach (avec « Annuler »), record, « Enchaîne : … » passent par `showKSnack`, posés **au-dessus de la barre de repos** (hauteur lue, `SessionBottomInset`).
13. **Bilan du jour** (maquette « BilanJour », sous-agent, relu) : plus de carte dans une carte (C7) : une carte « Comment tu te sens ? » avec « Pourquoi ? » sur place, Koach (même pose) à droite et les 5 tuiles de ressenti (mêmes 5 poses) dedans ; arrêt pour douleur, renvoi, avis médical en cartes au système ; résumé du bilan sans surtitre en capitales ; « Premier exercice » seul bouton plein ; détail du bilan au gabarit (en-tête standard, puces neutres `KChip`, douleurs déclarées en lignes avec « Retirer », feuille de douleur au gabarit de feuille).
14. **Temps et lieu** en feuilles de liste (`showKListSheet`), mêmes valeurs rendues.
15. **Avis médical** : confirmation au gabarit `KConfirm` dont on ne sort que par un bouton (`showKChoice(required: true)`), mêmes clés ; carte de rappel au système.
16. **Fin de séance et récompenses** : page Bilan de séance en carte (« 1 / 21 séries validées » en grand chiffre, objectif, XP), « Terminer la séance » seul bouton plein ; « Repasser en « à faire » » confirmé (R8 : il retire des XP) ; résumé de Koach (« Fin de séance ») au système ; écran des récompenses au système (surtitre sans capitales, gains en `accent`, carte de cérémonie cernée d'`accent` au lieu d'un aplat, repère « S12, J1 », un seul bouton plein « Continuer ») ; dialogue « Niveau N » au gabarit de confirmation.
17. **Historique d'une séance passée** : même en-tête et même repère que la séance ; menu ⋮ en feuille d'actions (« Corriger les saisies », dernier groupe « Supprimer de l'historique » en `danger`) ; confirmations au gabarit ; « Lecture seule » seulement pour une archive sans action (inventaire : incohérence corrigée) ; état « Enregistré » en `validation` (pas une puce) ; notes en lecture dans un groupe.
18. **Ligne des flammes et ligne résumée** : au système (dessin de la flamme inchangé) ; menu ⋯ d'une série en feuille d'actions ; bornes de l'échelle aux extrémités, « Je ne sais pas » à part, dessous ; piste pleine en clair (contraste).
19. **Estimation** (feuille de l'Arsenal et bloc des consignes) : feuille de contenu, « Détail du volume prévu » en titre de section sans capitales, lignes de détail en groupe.
20. **Jour de repos** : carte, titre « Repos complet » en capitales par le jeton, « Marquer comme fait » en bouton plein.

Contrôle de zone : `tools/check_ui_tokens.py --zone UI2 --menus` → **0** (234 au départ : session_screen 127, rewards 25, health_check 22, estimate_view 21, flame_track 20, session_history 10, clearance 5, adapt_summary 4 ; dont 17 menus hors gabarit).

## 2. Contrôles

Run complet 38076888632 sur `ca9a583` (résultats : `ci-out/` du commit d4957c0 de `claude/ci-ui-ui2`) :

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse | vert |
| Jetons de la zone (`check_ui_tokens.py --zone UI2 --menus`) | vert, 0 |
| Tests Python et intégrité | vert |
| Suite Dart | vert (865 tests, 45 ignorés : rendus) |
| Mode dev (`KALIS_DEV=true`) | vert (18) |
| Captures UI (kit et écrans) | vert |
| Rendus historiques (`visual_capture_test`) | rouge, **même échec sur la base** (colonne « avant » du même run, UI0 §2, UI4) |
| Build debug, build profile | vert (APK compressé 61,4 Mo) |
| Paquets Dart (moteurs) | vert (4 paquets, non modifiés) |
| Cibles émulateur des lots précédents (`ci3d_drive.sh`) | vert : CI1g, CI1f, CI1e, CI1c, CI1, CU, G10, G9, G7, G6, G5, G3, G2, G1, M8, M7 à 0 |
| Tour « après » (4 parties) | vert (4 × 0) |
| Tour « avant » (base) | parties a, b, c vertes ; d : délai dépassé sur la base (124, infrastructure) ; colonne « avant » complète au run 38066052559 (4 parties vertes, mêmes valeurs) |

Deux corrections viennent des cibles émulateur, après la relecture : la feuille de liste (CI1, CI1c cherchaient des `ListTile`) et l'appui sur le panneau de consignes du coach, qui ouvre de nouveau la feuille de Koach comme avant (CI1 b : `feuille_coach` vrai). Le tour mesure les parcours depuis la page du premier exercice, même quand le bilan du jour est déjà passé.

Relecture indépendante (sous-agent Opus ; cahier, maquettes et 61 captures avant / après seulement) : verdict « à corriger », 20 constats. Traitement :

| N° | Constat | Suite |
| --- | --- | --- |
| 1 | « 5 sé/ries » coupé à 320 dp × 200 % | Corrigé : le compteur se réduit (jamais coupé). |
| 2 | En-tête et repère hauts à 320 dp × 200 % (titre sur 3 lignes) | En partie : le repère et le lien passent sur deux lignes sans retrait ; le titre reste entier (C3 interdit de le couper). Un en-tête qui se replie au défilement demande de sortir l'en-tête de la page paginée : proposé à UI5 (§8). |
| 3 | « 62.5 » dans les champs, « 62,5 kg » au-dessus | Non changé : la valeur du champ est le texte saisi et enregistré (format du journal, `kgFieldText`, logique interdite au lot). Proposé au lot logique (§8). |
| 4 | Formats multiples (« 8 reps » / « rép. », « 3-4 min », « 5×4 », « ~86 % ») | Hors zone : textes produits par le programme, le moteur et `training_estimate.dart` (logique). Les libellés de la zone suivent C9 (« Exercice 3 sur 7 », « Mini-repos 30 s », « au moins 80 % »). Proposé à UI5 (§8). |
| 5 | « S12 · J1 » aux récompenses | Corrigé : « S12, J1 » à l'affichage (le titre du journal ne change pas). |
| 6 | Capitales hors titres | Corrigé pour les surtitres des récompenses ; les noms en capitales du contexte et de la liste viennent des données du programme du propriétaire (titres saisis en capitales) : non transformés (risque sur les sigles PdC, EMOM, VBT). |
| 7 | Deux aplats sur la page de fin (bouton et arrêt du repos) | Corrigé : barre de repos masquée sur la page de fin. |
| 8 | Récompenses : cérémonie en aplat, lignes en pilule | Corrigé : carte cernée d'`accent`, lignes au rayon 20 ; l'insigne de rang (dessin du jeu, `game_widgets.dart`, UI3) n'est pas teinté par la palette ; l'écart de niveau venait des chiffres synthétiques de la capture. |
| 9 | « feuille Pilotage » dans une consigne, pavé de texte | Hors zone : consigne rédigée dans le programme (données). Proposé au lot contenu (§8). |
| 10 | Ligne des flammes : bornes, « Je ne sais pas » au milieu, contraste | Corrigé (bornes aux extrémités, lien dessous, piste pleine en clair). |
| 11 | Lignes « Test » répétées | Corrigé : « Test 1 », « Test 2 »… |
| 12 | Historique et séance : en-têtes différents | Corrigé : même composant d'en-tête et même marge. |
| 13 | « Reprendre » en lien | Corrigé : bouton tonal. |
| 14 | « REPOS COMPLET » répété dans la description | Données de la séance (texte de conduite) : inchangé. |
| 15 | Lien « Exercices » en retrait à 200 % | Accepté : retrait de l'icône du bouton texte. |
| 16 | « Tempo Intention maximale », sous-titres en anglais | Corrigé pour le préfixe « Tempo » (la puce reprend le texte du programme) ; sous-titres : données. |
| 17 | Fin de séance : retour, bouton en haut | Accepté : page de sous-page standard (C1), bouton sous le contenu court. |
| 18 | « Enregistré » en puce, notes en champ | Corrigé. |
| 19 | Puces de zone de 32 dp | Les puces actives ont une cible de 48 dp (`KChip` avec action). |
| 20 | Écrans sans capture | Ajoutés : message de Koach au-dessus du repos, confirmation de suppression, chrono de mode lancé ; les cartes d'arrêt pour douleur et d'avis médical sont vues par les cibles émulateur (ci1_11, ci1g). |

## 3. Captures clés

Sur `claude/ci-ui-ui2` (commit d4957c0 « CI UI : résultats du run 38076888632 ») :
- `ci-out/captures-ui/ui2_<écran>_<bordeaux|neon>_<sombre|clair>.png`, écrans : `bilan`, `exercice`, `menu`, `liste`, `consignes`, `serie_validee`, `message_koach`, `confirmation`, `fin`, `douleur`, `feuille_douleur`, `resume_koach`, `historique`, `recompenses`, `repos` ; `ui2_chrono_mode_*`, `ui2_chrono_lance_*` ; 320 dp × 200 % : `ui2_*_bordeaux_sombre_320.png` ; densité 360 dp : `ui2_densite_*_360.png`, `ui2_cinq_series_*_360.png`.
- Tour : `ci-out/tour/apres/tour_<a|b|c|d>_<nn>_seance*.png` (séance, exercice, tableau, menu, liste, consignes, fin) et les mêmes noms dans `ci-out/tour/avant/`.
- À regarder en priorité : `ui2_exercice_bordeaux_sombre`, `ui2_menu_bordeaux_sombre`, `ui2_liste_neon_clair`, `ui2_serie_validee_bordeaux_sombre`, `ui2_message_koach_bordeaux_sombre`, `ui2_bilan_bordeaux_sombre`, `ui2_douleur_bordeaux_sombre`.

## 4. Avant → après (aucune information perdue)

| Écran | Avant | Après |
| --- | --- | --- |
| En-tête | `AppBar`, titre coupé « … » sur une ligne, « S1 · J2 », ⋮ menu déroulant | En-tête de séance : titre entier en capitales (U3), « S1, J2 », ⋮ feuille d'actions |
| Repère | « Exercice 3 / 7 », points `action` | « Exercice 3 sur 7 », points `encre` / `texte2` / `texte3` |
| Menu ⋮ | 7 entrées d'un menu déroulant, « Effacer l'historique » sans séparateur, « Références (feuille Pilotage) » | 3 groupes (§4.1), « Mes références », « Supprimer l'historique de cette séance » en `danger` et confirmé ; mêmes actions |
| Douleur | ⋮ › page d'information (5 appuis pour déclarer) | ⋮ › Bilan du jour détaillé sur Douleur (4 appuis), lien « Conseils de sécurité » vers la même page d'information |
| Liste | feuille faite main « Dans cette séance » | feuille de liste : mêmes lignes, plus la prescription, l'état fait et le résumé (nombre, durée) |
| ⓘ | consignes, pourquoi, estimation, « Fermer » | mêmes contenus, plus « Voir la fiche » |
| Carte d'exercice | surtitres rouges en capitales, puces colorées, « Note du coach : touche pour la lire », calibrage en ligne grise, « à renseigner » touchable invisible | titre de consigne en `encre`, puces neutres, lignes ouvrables « n notes du coach » et calibrage (2 premières lignes visibles, tout dans la feuille), lien « À renseigner : … Mes références » ; mêmes textes |
| Tableau | champs de 36 dp, en-têtes « REPS », « S », « MIN » | pilules de 48 dp, en-têtes « Reps », « s », « min », ligne courante cernée ; mêmes saisies, mêmes validations, mêmes messages d'erreur |
| Barre de repos | REPOS, −15 / +15, arrêt ; couleur d'état de phase | `KRestBar` : « Repos », −15 s / +15 s, arrêt ; phase dite par le libellé ; message de Koach au-dessus |
| Fin | icône, titre, compte, objectif, XP, bouton | carte (mêmes informations), « Terminer la séance » ; « Repasser en « à faire » » confirmé |
| Récompenses | surtitre et rang en capitales, cérémonie bordeaux | mêmes informations au système |
| Historique | `AppBar` « … · Lecture seule » + menu déroulant | en-tête de séance, « séance enregistrée », feuille d'actions ; mêmes actions et confirmations |
| Bilan du jour | bulle dans une carte, tuiles hors carte | une carte, « Pourquoi ? » sur place, mêmes 5 poses et libellés |

## 5. Mesures

**Parcours** (§6.3, relevés par le tour, chemins comptés depuis la page du premier exercice) :

| Parcours (depuis le premier exercice) | Avant (base) | Après |
| --- | --- | --- |
| Fiche de l'exercice | impossible (aucun chemin depuis la séance) | **2** : ⓘ › « Voir la fiche » |
| Déclarer une douleur | 5 (⋮ › Bilan du jour › détail › zone › Enregistrer ; le chemin du tour n'aboutit pas sur la base) | **4** : ⋮ › « Douleur ou malaise ? » › zone › Enregistrer |
| Mes références | 2 (⋮ › « Références (feuille Pilotage) ») | **2** : ⋮ › « Mes références » |

Mêmes valeurs dans les 4 parties du tour (sombre et clair, bordeaux et néon, sessions perso et dev) et dans `ui2_seance_test`. Écrans du tour relevés présents : séance, exercice, tableau, menu, liste, consignes, fin (consignes et fin absents de la base sous ces noms).

**Jetons** : zone UI2 234 → 0 ; menus hors gabarit 17 → 0.

**Contrastes** : uniquement des rôles du kit (`texte`, `texte2` sur `fond` / `surface` / `haute` ; `encre` et `accent` sur `fond` ou `surface` seulement, UI0.8 ; états `validation`, `danger`, `avertissement`). Seule couleur hors rôle : la flamme (dessin du kit Koach, inchangé), piste pleine en clair.

**Densité** : à 360 × 760 dp avec barres système, polices réelles, les 5 séries et la barre d'outils du premier exercice tiennent sans défilement (`ui_refactor_test`, capture `ui2_densite_*`).

## 6. Écarts aux maquettes et au cahier

- **Repère sous le titre** : « S12, J1 » comme la maquette ; le titre enregistré dans le journal reste « S12 · J1 » (données).
- **Chronos de mode** en boutons tonaux pleine largeur (et non pleins) : la page d'exercice n'a pas d'action principale unique (C2).
- **Barre de repos** : chronomètre montant et décompte terminé sans −15 s / +15 s (composant de zone qui reprend les mesures de `KRestBar`) ; pas de couleur d'effort : la phase est dite par le libellé.
- **Champs** : chiffre non agrandi au-delà de 130 % de texte, pour rester entier dans la pilule (cahier §5.2).
- **Barre de repos masquée sur la page de fin** (C2).
- **Puce « Reps »** retirée (elle redit l'en-tête de colonne) ; les autres mesures (« Max de reps », « Tenue chronométrée », EMOM…) gardent leur puce.
- **Charge non chiffrée** (« à renseigner », « ? ») : plus en grand chiffre ; elle est dite par le lien vers « Mes références » (ou une puce « Charge : ? »).

## 7. Fichiers touchés hors de la liste de UI2 et pourquoi

| Fichier | Changement | Raison |
| --- | --- | --- |
| `integration_test/tour_ui_test.dart` (UI0) | Section « Séance » : 6 écrans de plus, 3 parcours (fiche, douleur, Mes références) | Mode d'emploi du kit (LIVRAISON_UI0 §7) et prompt (« écrans du tour ajoutés ») |
| `integration_test/street_ci1_test.dart`, `integration_test/koach_ci1c_test.dart` (CI1, CI1c) | Lignes de la liste des exercices cherchées dans `KListSheet` au lieu de `ListTile` | La liste est devenue une feuille de liste (même parcours, mêmes relevés) |
| `lib/adapt/widgets/session_kit.dart` (nouveau, zone UI2) | Feuille de contenu, confirmation à clés nommées | Composants manquants au kit (§9) |
| Tests | voir §8 « Tests » | |

**Tests mis à jour** (aucune assertion retirée sans remplacement) :
- `g9_seance_test`, `g10_seance_sans_moteur_test` : `flame-exclude` → `action-exclude` (menu ⋯ en feuille d'actions) ; g9 : `pumpAndSettle` après `ensureVisible` (carte plus haute, la coche n'était plus à l'écran avant défilement).
- `history_correction_test` : l'entrée indisponible se lit sur la feuille d'actions (`InkWell` sans action) au lieu d'un `PopupMenuItem` ; `ensureVisible` avant l'appui sur la ligne résumée.
- `l4b_seances_test` : « 2 / N » → « 2 sur N ».
- `lc1_programme_test` : « Références (feuille Pilotage) » → « Mes références » (R9).
- `screens_test` : « Chrono 3600 » → « chrono de 3600 » (libellé du bouton).
- `l5c_selecteur_test` : couleur des points lue sur le point courant (`encre`) au lieu de l'ancien paramètre `color` (rôle `action`).
- `ui_refactor_test` (cinq séries visibles) : polices réelles chargées pour la mesure (la police de test, un carré par caractère, coupait titres et puces qui tiennent sur une ligne sur le téléphone).
- Nouveaux : `ui2_seance_test` (menu §4.1, suppression confirmée, Mes références en 2, fiche en 2, douleur en 4, liste, retour à l'exercice après « J'ai seulement… minutes »), `ui2_seance_capture_test`, `ui2_densite_capture_test`.

## 8. Limites et propositions

- **UI5 / kit** : `KConfirm` ne défile pas (débordement sur petit écran avec un long message) ; `KRestBar` gagnerait un mode sans réglage du temps ; `KSetRow` un numéro qui se réduit et l'appui long ; une feuille de contenu manque au kit (§9). En-tête de séance repliable au défilement à 200 % de texte.
- **Lot logique** : saisie et affichage des charges avec la virgule (« 62,5 ») dans les champs ; formats C9 des textes produits par le moteur et l'estimation (« rép. », tirets, « ≈ »).
- **Lot contenu** : consignes qui citent « feuille Pilotage », titres de séance en capitales dans les données.
- **Glissement depuis un champ** : un champ qui a le focus garde ses gestes (curseur) ; il faut le quitter pour glisser.
- **Rendus de test** : glyphes absents de la police de test (« → » dans certaines consignes) et carte anatomique non chargée dans certains rendus : propre au moteur de test.

## 9. Composants à promouvoir (UI5)

| Composant | Fichier | Usage |
| --- | --- | --- |
| `showKContentSheet`, `KSheetHeader` | `lib/adapt/widgets/session_kit.dart` | Feuille de contenu (consignes, douleur d'une zone, estimation) : poignée, titre, contexte, contenu qui défile, « Fermer » ; route de feuille ouverte directement (à déplacer dans `lib/kit/sheets.dart`) |
| `KChoiceDialog`, `showKChoice` | idem | Confirmation au gabarit `KConfirm`, boutons fixés en bas et contenu qui défile, clés nommées, mode obligatoire (avis médical) |
| `SessionHeader` | `lib/session_screen.dart` | En-tête de séance (titre jamais coupé, repère, une action) |
| `SessionProgressDots` | idem | Points de progression d'une suite de pages |
| `SessionBottomInset` | idem | Hauteur occupée en bas, pour poser les messages au-dessus (C8) |
| `_SetField` / `_SetRow` | idem | Champ de série en pilule éditable, ligne de série |
| `KoachWhyHeader` | `lib/adapt/health_check.dart` | Question de Koach avec « Pourquoi ? » sur place, sans bulle |

## 10. Recommandation (C8, le pilotage décide)

**Valider UI2 et fusionner `ui/UI2` dans `refonte-ui`.** La séance, ses feuilles, le bilan du jour, la fin, les récompenses et l'historique sont au système (zone 234 → 0, menus hors gabarit 17 → 0) ; les trois parcours du §6.3 sont tenus et mesurés sur émulateur (fiche 2 appuis, douleur 4, Mes références 2) ; aucune information n'est perdue (§4) ; la suite complète, le mode dev, les paquets et les cibles émulateur des lots précédents sont verts (§2).

Points à reprendre ailleurs, sans bloquer la fusion :
- **UI5** : promouvoir les composants du §9 dans le kit (`showKContentSheet`, `showKChoice`, en-tête et points de séance) ; donner à `KConfirm` un contenu qui défile ; en-tête de séance repliable à 200 % de texte.
- **Lot logique** : virgule décimale dans les champs de charge (« 62,5 ») ; formats C9 des textes du moteur et de l'estimation.
- **Lot contenu** : consignes qui citent « feuille Pilotage », titres de séance saisis en capitales.

Fusion : `ui/UI2` part de `refonte-ui` 0e5342df et ne touche que les fichiers de UI2 (§7.2), plus `integration_test/tour_ui_test.dart` (section Séance) et deux cibles émulateur de CI1 (feuille de liste) ; UI1, UI3 et UI4 ne touchent pas ces fichiers, sauf le tour, où chaque lot ajoute sa section (conflit de fusion attendu, à résoudre en gardant les sections des quatre lots).

