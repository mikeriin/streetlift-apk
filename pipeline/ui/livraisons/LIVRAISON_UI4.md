# Livraison UI4 — Menus : Réglages, Arsenal, profil, parcours d'entrée, données et aide (dev6.12.0-ui4)

Lot UI4 du pipeline « Refonte UI et UX » (UI), lancé le 10/10/2026 par le pilotage (LANCEMENTS.md, section UI4), en parallèle de UI1, UI2 et UI3. La session `session_01EcZvt7jo2rPQi194ZGu9FQ` a d'abord tenté de prendre UI3 (pris entre-temps par une autre session, PIPELINE_UI.md §1), puis a pris UI4. Validation : conversation de pilotage (délégation C8), recommandation au §10.

| | |
| --- | --- |
| Branche | `ui/UI4` (depuis `refonte-ui` 0e5342df), tête `864dff16` |
| Contrôle complet | `claude/ci-ui-ui4`, run 38067294842 : formatage, analyse, jetons de zone, tests Python, **919 tests Dart** (31 ignorés : rendus) et 18 du mode dev, captures UI, builds debug et profile, paquets, tour avant et après (4 parties chacune) et cibles émulateur : **verts** ; seuls les rendus historiques (`visual_capture_test`) échouent, exactement comme sur la base b7996b3f (même échec dans la colonne « avant », UI0 §2) |
| Contrôle rapide | `claude/ci-ui-ui4-rapide` (formatage, analyse, tests `test/ui4_*`, captures) |
| Sauvegardes | `ui-sauvegardes/UI4` (arbre sans `.github/`, avec `SAUVEGARDE.md`) |
| Version interne | dev6.12.0-ui4, étiquette du lot (`pubspec.yaml` reste à 6.11.1+114, UI0.1) |
| Accès | `add_repo` absent de la session ; push vérifié par `git push --dry-run origin pipeline` puis par la prise du lot. Flutter n'est pas téléchargeable dans la session (stockage Google refusé par le proxy) : toute compilation et tout test passent par la CI. |

## 1. Ce qui est livré

Cahier §7.3 « UI4 », fichiers de UI4 au §7.2 seulement (plus les tests et la section UI4 du tour).

1. **Réglages à l'arborescence §4.1** (`settings_screen.dart`, refait)
   - Racine au gabarit `KMenuPage` : grand titre « Réglages », phrase, recherche « Rechercher un réglage », **carte Profil** (pastille `pleine` à l'initiale du prénom, « Profil, mes références, tests guidés, santé » et l'état : à créer, à refaire avec Koach, mode prudent), groupe **Application** (Apparence, Séance, Notifications, Progression et jeu) et groupe **Plus** (Données et confidentialité, Aide et à propos). Logo des gestes du mode dev gardé.
   - `SettingsScreen({page, highlight})` et `enum SettingsPage` remplacent `section: int` (index fragile). `highlight` met une ligne en évidence 1,5 s et l'amène à l'écran.
   - Six sous-pages `KMenuPage(root: false)` titrées du libellé (R3, plus de surtitre « RÉGLAGES »), réglages en place (`KSwitchRow`, `KStepperRow`, `KSegmentedRow`), appliqués tout de suite.
   - Plus aucune entrée « Programme », « Mon programme », « Départ du programme », « Références », « Koach », « Affichage 3D », « Préférences » sur la racine (déplacées selon §4.3).
2. **Recherche des réglages** (`settings_search.dart`, nouveau, §4.4) : index écrit à la main de 37 entrées (chaque réglage et chaque page d'aide ou destination : Profil, Mes références, Tests guidés, Santé et sécurité, Récupération, guide, galerie, avis, licences, compatibilité 3D), libellé, description, mots proches (repos / récup / pause ; kg / livres / unité ; son / bip ; vibration / vibreur ; thème / sombre / clair ; couleur / palette ; rappel / notification ; sauvegarde / export / import ; profil / poids / taille ; références / 1RM / max…), chemin affiché (« Séance › Chronomètres »), destination. Règle de `search.dart` (`SearchQuery`, `SearchDoc`), tri par score. Résultats groupés « Réglages » puis « Aide », valeur actuelle à droite, « N résultats » ; aucun résultat : message et « Effacer la recherche ». Une entrée dont la ligne n'existe pas (heure du rappel sans rappel, copie WOD absente) est cachée.
3. **Profil** (`athlete_profile_screen.dart`) : sous-page « Profil » au gabarit menu ; groupe « Mon suivi » (Compléter mon profil, **Mes références**, Tests guidés), « Rubriques du profil » (11, **sans « Mode assisté ou libre »**, qui vit dans Évolution ; le parcours de création garde la question), « Santé et accords » ; confirmations au gabarit, dont les deux qui manquaient (R8).
4. **Mes références** (`pilotage_screen.dart`) : titre « Mes références » (R3, R9 : plus de « Pilotage »), mêmes champs, « Effacer toutes mes références » devenu une ligne visible en `danger`, confirmée.
5. **Notifications, Données** (`notification_settings.dart`, `data_control.dart`) : lignes du kit, `highlight` pour la recherche ; aperçu de l'import et suppression des données en **sous-pages** (aperçu complet, interrupteur « Sauvegarder d'abord », champ « Tape SUPPRIMER », boutons en bas), confirmations simples en `showKConfirm`.
6. **Arsenal** (`arsenal_screen.dart`, `exercise_screens.dart`, `anatomy_screen.dart`, `atlas.dart`) : racine `KMenuPage` avec recherche directe **« Exercice ou muscle »** (résultats « Exercices » — même moteur — puis « Muscles » — 17 groupes et 77 muscles de l'atlas) ; bibliothèque « Exercices » (« Rechercher un exercice », état vide avec action, filtre par groupe) ; fiche titrée du nom de l'exercice, **puces de groupe musculaire qui ouvrent l'Anatomie sur ce groupe** ; Anatomie : `initialGroup` branché (coché et défilé), bouton **« Exercices pour ce muscle »** par groupe, renvoi au réglage « nom au toucher » devenu un bouton ; **galerie de Koach retirée de l'Anatomie** (→ Aide et à propos).
7. **Parcours de création du profil** (`athlete_profile_flow*.dart`) : mêmes 12 étapes, mêmes questions, réponses, validations, reprise et effets ; en-tête standard, **progression en segments** (une pilule par étape montrée), **bouton principal fixé en bas**, **« Passer »** sur les étapes facultatives (expérience, ce que tu sais faire, récupération, préférences ; objectifs dans « Compléter mon profil »), puces du kit, accord santé en segments ; 9 feuilles-formulaires devenues des sous-pages, durée « Autre » en pas à pas en place, menus déroulants en segments ou feuille de liste.
8. **Pages** (`plan/plan_screens.dart`, `program_start.dart`, `startup.dart`, `retired_notice_screen.dart`, `wellbeing_screens.dart`, `guided_tests.dart`, `profile_completion.dart`) : gabarits, titres R3, culs-de-sac R6 résolus, chemins écrits R5 remplacés, libellés R9.
9. **Tour** : section UI4 enrichie (arsenal, recherche d'Arsenal, Anatomie sur un groupe, réglages, Apparence, Séance, recherche, Données, Aide, Profil, Mes références) et parcours avec saisie (`reglage_repos_recherche`, `exercices_muscle_recherche`) ; captures de zone `test/ui4_ecrans_capture_test.dart`.

## 2. Réglages : avant → après, réglage par réglage (inventaire partie 1, aucun perdu)

| Avant (rubrique, libellé, contrôle) | Après (page › section, libellé, contrôle) |
| --- | --- |
| Racine, « Thème », segments | Apparence, « Thème », `KSegmentedRow` (description = phrase du thème choisi) |
| Racine, « Couleur dominante », grille | Apparence, « Palette », `KPalettePicker` (8 palettes) + résumé + message « non enregistrés » |
| Racine, « Contraste renforcé » | Apparence, même libellé, interrupteur |
| Affichage 3D, « Nom du muscle au toucher » | Apparence › Anatomie et 3D, interrupteur |
| Affichage 3D, « Halo » | Apparence › Anatomie et 3D, interrupteur |
| Chronomètres, « Repos par défaut », pas à pas 0-300 / 15 | Séance › Chronomètres, pas à pas, format C9 (« 90 s », « 2 min 30 ») |
| Chronomètres, « Décompte « Prêt » » 0-10 | Séance › Chronomètres, pas à pas |
| Chronomètres, « Lancer le repos à la validation d’une série » | Séance › Chronomètres, interrupteur |
| Chronomètres, « Son en fin de chrono » | Séance › Fin du repos, interrupteur |
| Chronomètres, « Vibration en fin de chrono » | Séance › Fin du repos, description corrigée « Fin de chrono, validation et records ; pré-signal léger 3 s avant la fin » (§4.6, comportement inchangé) |
| Saisie des séries, « Colonne vitesse (m/s) sur les lifts » | Séance › Saisie des séries, interrupteur |
| Saisie des séries, « Pré-remplir charge suggérée et reps prévues » | Séance › Saisie des séries, interrupteur |
| Pendant la séance, « Garder l’écran allumé » | Séance › Écran et unités, interrupteur |
| Pendant la séance, « Charges suggérées en livres (lb) » | Séance › Écran et unités, interrupteur |
| Progression et jeu, « Célébrations » | Progression et jeu, interrupteur |
| Progression et jeu, « Objectif de jours actifs par semaine », pas à pas 0-6 | Progression et jeu, **« Objectif de la semaine »**, segments Adaptatif, 2 à 6 (mêmes valeurs que Stats, §4.3) ; une valeur 1 enregistrée : aucun segment choisi, « Actuellement : 1 jour par semaine », sans migration |
| Notifications, « Rappels de séance », « Heure du rappel » (dialogue horaire), prochain rappel, Options Android, erreurs | Notifications, mêmes lignes et états ; heure par le sélecteur système ; Options Android en section |
| Sauvegardes, Exporter / Importer / Copier / Coller | Données et confidentialité › Sauvegardes ; « Coller » ouvre une sous-page (champ + « Voir l’aperçu ») ; « pilotage » → « références » |
| Sauvegardes, Copie d’avant la suppression des WOD (si présente) | même section, même clé |
| Sauvegardes, « Sauvegarde Android » | `KNotice` sous le groupe, texte entier |
| Sauvegardes › Zone sensible, « Supprimer les données de l’application » | Données › Zone sensible (dernier groupe, `danger`), page de confirmation |
| Koach, « Ancien Koach et adaptations au quotidien », « Données Koach partiellement relues » | Données › Anciennes données de Koach : bandeaux sans libellé interne (R9), même information |
| Koach, « Supprimer mes réponses aux anciens questionnaires » (dialogue) | Données › Zone sensible, `showKConfirm` destructif, mêmes textes |
| Koach, carte « Confidentialité » | Données › Confidentialité, bandeau |
| À propos, « Politique de confidentialité » | Données › Confidentialité (§4.1) |
| À propos, version (deux fois : carte et pied de page) | Aide et à propos › Version, **une seule fois** |
| À propos, Build de développement, avertissement | Aide et à propos › Version / Avertissement |
| À propos, Santé et sécurité ; Récupération (doublon) | Aide et à propos › Santé et sécurité (qui contient Récupération) ; la recherche trouve Récupération |
| À propos, Donner mon avis, Sources et licences | Aide et à propos |
| À propos, « Moteur 3D » | Aide et à propos, **« Compatibilité 3D »** (voir §6) |
| — | Aide et à propos : « Comment marche ton programme ? », « Galerie de Koach » (déplacée d'Arsenal) |
| Programme › Profil | carte Profil en tête de la racine (R+1) |
| Programme › Références | Profil › Mes références (R+2) ; dans la recherche |
| Programme › Mon programme ; Départ du programme | retirés des Réglages : onglet Programme (UI1 : ligne « Mon programme », Calendrier) |
| Mode assisté / libre (rubrique du profil) | retiré du Profil : Évolution (UI1) ; question gardée dans le parcours de création |
| Accord santé, accord du médecin | Profil › Santé et accords, confirmés |
| 11 rubriques du profil | Profil › Rubriques du profil, inchangées (3 appuis, R4) |

Chaque réglage est à 2 appuis au plus de la racine (R4), vérifié par `test/ui4_settings_test.dart`.

## 3. Autres écrans : avant → après (aucune information perdue)

**Profil** : AppBar « PROFIL » → « Profil » ; création / refaire, bulle de Koach (le chemin « Réglages › Mon programme » devient un bouton « Ouvrir Mon programme »), Compléter, Tests guidés, **Mes références** (nouveau, ouvre la page des références), 11 rubriques (titre, résumé ; clés `profile-rubric-*` et `profile-edit-*` gardées), mode prudent (« J'ai l'accord de mon médecin » → `showKConfirm`), « Retirer l'accord déclaré » **désormais confirmé**, données de santé (« Retirer ton accord ? » et « Supprimer tes réponses de santé ? » confirmés, destructifs), feuille « Ton programme » → confirmation « Refaire ton programme ? ». « Comment marche ton programme ? » quitte le Profil (R1 : Mon programme et Aide et à propos).

**Mes références** : mêmes 4 sections et champs (poids de corps, 1RM de travail, répétitions, accessoires), « C'est bien ma valeur » et « Je ne sais pas », « Non renseigné » en `texte2` (un état prévu, pas une erreur, C5), « À vérifier » en `avertissement`, « Effacer toutes mes références » (icône seule ⟲ dans l'en-tête avant) en ligne `danger` en bas, confirmée.

**Arsenal** : racine (recherche ajoutée, deux entrées gardées, mêmes clés `arsenal-exercises` / `arsenal-anatomy`) ; bibliothèque (AppBar « EXERCICES » → « Exercices », « Nom, muscle, matériel, discipline… » → « Rechercher un exercice », compteur, filtres inchangés, état vide avec action) ; fiche (« FICHE EXERCICE » → nom de l'exercice ; badges → puces neutres ; mêmes sections ; liens de variantes en groupe) ; Anatomie (mêmes filtres et carte ; « Exercices pour ce muscle » ; galerie retirée).

**Parcours du profil** : AppBar → en-tête standard ; barre linéaire + « n / N » → segments (lecteur d'écran « Étape n sur N ») ; bouton en bas ; « Passer » ; formulaires en sous-pages (Ajouter un record, une figure, une date, un sport, un objectif, une blessure, « Choisir ta priorité », « Laisse Koach proposer ») ; « Chercher dans les 1 039 exercices » → « Rechercher un exercice ».

**Création du programme, bloc suivant, départ, aide, tests guidés** : titres R3 (« Créer mon programme » avec « Étape n sur 4 », « Bloc suivant », « Départ du programme », « Santé et sécurité », « Récupération », « Politique de confidentialité », « Donner mon avis », « Tests guidés », « Copie d’avant la suppression des WOD ») ; « Remplacer ton programme ? » et « Quitter la création ? » en `KConfirm` ; « moteur calibré » → « nouvelle méthode » (R9) ; « S1 · J1 » → « semaine 1, jour 1 » dans le texte courant ; « Tes références (facultatif) » → « Mes références (facultatif) ».

**Culs-de-sac résolus (R6)** : création sans profil → « Créer mon profil » ; bloc suivant indisponible → « Revenir à Mon programme » ; programme terminé (bandeau) → « Créer un nouveau programme » ; tests guidés sans proposition → action selon le cas ; bibliothèque vide → « Effacer la recherche » / « Réinitialiser les filtres » ; recherches sans résultat → « Effacer la recherche ».

## 4. Menus, feuilles et dialogues convertis (§4.5)

| Avant | Après |
| --- | --- |
| `settings_screen` : `showDialog` collage, `AlertDialog` réponses | sous-page « Coller une sauvegarde » ; `showKConfirm` destructif |
| `data_control` : 4 `showDialog` (session de test, aperçu d'import, conflit, suppression) | `showKConfirm` ×2 ; sous-pages « Importer une sauvegarde » et « Supprimer les données de l’application » |
| `athlete_profile_screen` : 2 `showDialog`, feuille « Ton programme » | `showKConfirm` ×5 (dont 2 confirmations nouvelles, R8) |
| `pilotage_screen` : `showDialog` « Effacer tes références ? » | `showKConfirm` destructif |
| `athlete_profile_flow*` : 9 `showModalBottomSheet`, 1 `showDialog`, 2 menus déroulants | 9 sous-pages ; pas à pas en place ; segments ; `showKListSheet` (muscle) |
| `plan_screens` : feuilles « Remplacer… », « Quitter » (sans titre) | `showKConfirm` ×2 |

Contrôle `python3 tools/check_ui_tokens.py --zone UI4 --menus` : **0** (131 au départ), 0 menu hors gabarit.

## 5. Mesures

| Mesure | Avant (b7996b3f) | Après (UI4) |
| --- | --- | --- |
| Valeurs de style en dur et menus hors gabarit, zone UI4 (`check_ui_tokens.py --zone UI4 --menus`) | 131 dans 18 fichiers | **0** |
| Entrées de la racine des Réglages | 11 rubriques + Apparence en place | recherche, carte Profil, 6 rubriques |
| Réglages à plus de 2 appuis de la racine (R4) | — | 0 (test `ui4_settings_test`) |
| Entrées de l'index de recherche des réglages | — | 37, chacune trouvée par son libellé et un mot proche, chaque destination existe (test) |

**Parcours (tour sur émulateur, 4 parties, mêmes valeurs dans les 4 ; l'appui sur l'onglet est compté)** :

| Parcours | Avant | Après | Cible du cahier |
| --- | --- | --- | --- |
| Un réglage précis (« Repos par défaut ») par les rubriques | 2 (Réglages › Chronomètres) | **2** (Réglages › Séance) | 2 |
| Le même par la recherche | impossible | **3** (onglet, champ, résultat ; 2 depuis la racine) | 2 depuis la racine |
| Mes références | 3 (Réglages › Programme › Références) | **3** (Réglages › carte Profil › Mes références ; 2 depuis la racine) | 2 depuis Réglages |
| Exercices d'un muscle | impossible | **4** (onglet, champ « pectoraux », Pectoraux, « Exercices pour ce muscle ») ; un exercice cherché directement : 2 depuis la racine | recherche directe ou 3 |
| Mon programme, Ma saison, Évolution | 1, 2, 2 | 1, 2, 2 (inchangés, zone UI1) | — |

Aucun parcours ne gagne d'appui. Mes références garde le même nombre d'appuis qu'avant (2 depuis la racine), mais n'a plus qu'un nom et une page (R1, R2) ; la cible « 3 au départ » de LANCEMENTS.md comptait l'appui sur l'onglet.

**Contenu sous le dock** : aucun texte en bas d'Arsenal et des Réglages, dans les 4 parties (`sous_le_dock` vide).

**Captures** : `test/ui4_ecrans_capture_test.dart`, 26 vues (23 écrans, 2 recherches, 1 mise en évidence) × sombre / clair × `bordeaux` / `neon` (page entière, 390 dp), mise en évidence d'une ligne ouverte par la recherche, et 10 écrans denses à 320 dp × 200 % ; toutes regardées. Contrastes : rôles du kit seulement (UI0 §4), règle UI0.8 respectée (texte `encre` / `accent` jamais sur `haute`).

**Poids** : APK profile 61,5 Mo compressés, aucun fichier ni police ajoutés par le lot.

**Captures clés** (branche `claude/ci-ui-ui4`, commit 3e00568d) :
- `ci-out/captures-ui/ui4_reglages_<palette>_<thème>.png`, `ui4_reglages_recherche_*`, `ui4_reglages_apparence_*`, `ui4_reglages_seance_*`, `ui4_reglages_seance_evidence_*`, `ui4_reglages_donnees_*`, `ui4_reglages_aide_*`, `ui4_profil_*`, `ui4_mes_references_*`, `ui4_arsenal_*`, `ui4_arsenal_recherche_*`, `ui4_fiche_*`, `ui4_anatomie_pectoraux_*`, `ui4_parcours_profil_*`, `ui4_supprimer_donnees_*`, `ui4_320_*` ;
- tour : `ci-out/tour/apres/tour_<a|b|c|d>_<09…21>_<écran>.png` et la même chose dans `ci-out/tour/avant/`.

## 6. Écarts au cahier et aux maquettes, et pourquoi

- **« Compatibilité 3D » au lieu de « Diagnostic 3D »** (R9) : le test de conformité L13 (`tools/tests/test_l13_compliance.py`) interdit le mot « diagnostic » dans les textes de l'application (aucune allégation médicale). La page garde son titre « MOTEUR 3D » (`engine3d.dart`, hors zone, R3 à finir par UI5).
- **Section « Fin du repos »** : « Lancer le repos à la validation » reste dans Chronomètres (c'est un départ de chrono), son et vibration en Fin du repos.
- **« Passer »** : la règle appliquée est « étape acceptée vide par `stepError`, ou toutes ses questions du schéma 3 » ; jamais sur l'accueil, le récapitulatif ni en modification d'une rubrique.
- **Clés perdues, imposées par le kit** : `showKConfirm` n'a que `confirm-ok` / `confirm-cancel`, `KSegmented` que `segment-<valeur>`, `KNotice` aucune clé d'action : `clearance-confirm`, `withdraw-confirm`, `plan-replace-*`, `flow-consent-*`, `test-rir-N`, `feedback-rating-N`, `program-start-open` remplacées (tests adaptés, aucune assertion retirée).
- **Retenue d'un test guidé** : `KSegmented` ne permet pas de désélectionner ; la note de l'avis a gagné un segment « Aucune ».
- **Durée « Autre »** : pas à pas de 5 min (10 à 300) au lieu d'une saisie libre.
- **Recherche des muscles** : un muscle non dessiné ouvre l'Anatomie sur le groupe le plus proche, annoncé (« Muscle non dessiné · voir Deltoïdes »).
- **Bibliothèque filtrée** : titre « Exercices » avec le groupe en sous-titre (R3 partiel) ; liste en lignes à plat (1 039 lignes paresseuses).
- **Feuilles « Ton prochain bloc »** : gardées en feuille de Koach (`showKoachSheet`, fichier de UI1), textes R5/R9 corrigés.

## 7. Besoins hors de ma zone (pour UI5 et le pilotage)

Par ordre d'importance :

1. **Kit, bloquant (C3)** : `KTopBar.sub` tronque le titre par une ellipse dès qu'il dépasse une ligne (« SUPPRIMER LES DONNÉES DE L’AP… » à 390 dp et 100 % ; « PROGRESSION ET J… », « DONNÉES ET CONFI… » à 320 dp × 200 % ; les noms d'exercices longs de la fiche). Cause : `AppBar` pose un `DefaultTextStyle(overflow: ellipsis)` ; avec une ellipse et `maxLines` nul, Flutter limite le texte à une ligne. Correction proposée dans `lib/kit/page.dart` : `overflow: TextOverflow.visible` et `maxLines` explicite dans le `Text` de `KFitTitle`, et hauteur de barre qui suit le titre sur 2 lignes (3 au-delà de 150 %). Touche tous les lots.
2. **Kit (C3, C13)** : `KSwitchRow`/`KMenuRow` à 320 dp × 200 % coupent un mot (« Célébration / s ») : passer l'interrupteur sous le libellé quand la largeur manque, comme `KStepperRow`. `KSegmented` donne la largeur au prorata des libellés : « 2 3 4 5 6 » à côté d'« Adaptatif » font ≈ 36 dp (largeur minimale de 48 dp par segment). `KStepperRow` reste à côté du libellé à 390 dp et serre « Décompte « Prêt » » sur 2 lignes (seuil à relever vers 420 dp). Phrase de `KPage.root` à 24 dp quand le titre est à 20 dp (aligner). Étiquette des champs (`InputDecoration`) posée sur le bord de la pilule et colorée avant toute erreur.
3. **`lib/wellbeing.dart`** (hors zones, UI5) : textes de Santé et sécurité avec chemins écrits et faux (« Réglages → Programme → Profil », « Options de séance → Échanger un exercice », « bilan Koach ») : R5, R1. À remplacer par « depuis ton profil, rubrique Santé, blessures et gênes » et « Bilan du jour ».
4. **UI1** : `program_explainer.dart` écrit encore « Réglages › Profil » ; `ProgramExplainerButton` en bouton à contour ; `koach_bubble.dart` (`showKoachSheet`) encore en `showModalBottomSheet` direct ; `program_screens.dart` : « programme du moteur », « révisions LC1 ». Le retrait de « Mon programme » et « Départ du programme » des Réglages suppose la ligne « Mon programme » de l'accueil et le groupe Calendrier de UI1 : à fusionner ensemble.
5. **UI2** : « Références (feuille Pilotage) » dans `session_screen.dart` → « Mes références » (R1, R9).
6. **UI3** : « Modifier mes références » dans `stats_performance.dart` → « Mes références » ; `test/stats_test.dart` a reçu une ligne (`BackButton` → infobulle « Retour ») pour suivre le nouvel en-tête du Profil : conflit possible à la fusion.
7. **Kit** : clé par bouton de `KConfirm`, clé d'action de `KNotice`, clé par segment, paramètre de retour masqué et clé du bouton retour de `KTopBar.sub`, libellé lu de `KSearchField`.
8. **Fusion du tour** : `integration_test/tour_ui_test.dart` a été modifié dans la section UI4 et en fin de fichier (parcours avec saisie) ; les autres lots modifient leurs sections : fusion manuelle simple.
9. **`athlete_profile.dart`** : nombres séparés de leur unité par une espace normale dans les résumés de rubriques (« 75 kg » coupé en fin de ligne) : espace fine insécable (C9) — à faire avec UI5 (formateurs partagés).

## 8. Fichiers touchés

Zone UI4 (cahier §7.2) : `settings_screen.dart`, `settings_search.dart` (nouveau), `notification_settings.dart`, `data_control.dart`, `pilotage_screen.dart`, `wellbeing_screens.dart`, `retired_notice_screen.dart`, `startup.dart`, `arsenal_screen.dart`, `exercise_screens.dart`, `atlas.dart`, `anatomy_screen.dart`, `athlete_profile.dart` (seulement le `toUpperCase` d'un titre de jour), `athlete_profile_flow.dart`, `athlete_profile_flow_v3.dart`, `athlete_profile_screen.dart`, `profile_completion.dart`, `guided_tests.dart`, `program_start.dart`, `plan/plan_screens.dart`, `koach/koach_gallery_screen.dart` (conteneur). `plan/plan_creation.dart` : rien à changer (modèle sans présentation). Aucun fichier hors zone dans `lib/`.

Tests : nouveaux `test/ui4_settings_test.dart`, `ui4_settings_search_test.dart`, `ui4_profil_test.dart`, `ui4_arsenal_test.dart`, `ui4_parcours_profil_test.dart`, `ui4_pages_test.dart`, `ui4_ecrans_capture_test.dart` ; adaptés (même assertion, nouveau chemin ou composant ; aucune retirée) : `g1_mode_dev`, `g2_retrait`, `g3_catalogue`, `g5_koach`, `g6_profil`, `l13_screens`, `l2b_data_control`, `l4_depart`, `l5c_ecrans_capture`, `l5c_palettes_capture`, `l5c_selecteur`, `m1_engine3d`, `m2_mannequin`, `m3_fiche_mannequin`, `m6b_correctifs`, `cu_profil_v3`, `progression_screens`, `redesign`, `stats_test` (une ligne), `ui_refactor`, `visual_capture` ; intégration : `koach_g5`, `moteur_3d`, `profil_cu`, `profil_g6`, `programme_g7`, `retrait_g2`, `tour_ui_test` (section UI4).

## 9. Relecture indépendante

Sous-agent Opus, qui n'a vu que le cahier, les maquettes et les captures avant / après : 23 constats, verdict « à corriger ».

| N° | Constat | Suite |
| --- | --- | --- |
| 1, 2 | Titres d'en-tête tronqués (« SUPPRIMER LES DONNÉES DE L’AP… » à 100 % ; deux autres à 320 dp × 200 %) ; « Célébration / s » coupé à 200 % | **Non corrigé dans le lot : défaut du kit** (`KTopBar.sub`, `KSwitchRow`, fichiers de UI0/UI5). Cause et correctif décrits au §7.1–7.2. À faire avant la publication. |
| 3 | Chemins écrits et faux dans Santé et sécurité | Textes dans `lib/wellbeing.dart`, hors zone (§7.3). |
| 4 | Action ⟲ des références disparue ? | Non : c'était « Effacer toutes mes références », devenue une ligne `danger` en bas de page, confirmée (§3). |
| 5 | « Non renseigné » en rouge (C5) | Corrigé : `texte2`. |
| 6 | Segments de l'objectif et de la note sous 48 dp | Défaut du kit (`KSegmented`, §7.2). |
| 7 | Mise en évidence absente des captures | Corrigé : capture prise pendant les 1,5 s (ligne sur `haute`), test d'existence dans `ui4_settings_search_test`. |
| 8 | Séparateurs en retrait d'une pastille absente | Corrigé : `dividerIndent` au texte dans tous les groupes sans pastille. |
| 9 | Pas à pas serré à 390 dp | Seuil du kit (`KStepperRow`, §7.2). |
| 10 | Aide et à propos : rubriques sous un long avertissement | Corrigé : rubriques d'abord (section « Aide »), puis « Avertissement », puis « Version ». |
| 11 | Textes longs en lignes de menu, libellé interne | Corrigé : descriptions d'une phrase, informations en bandeaux, libellé R9 retiré ; la copie WOD n'apparaît que si elle existe. |
| 12 | « Comment marche ton programme ? » en double dans le Profil | Corrigé : retiré du Profil. |
| 13 | « Filtres · 0 » avec un groupe actif ; 385 contre 437 | Laissé : le filtre par groupe n'est pas un filtre de `filter_menu.dart` (autre lot) ; « Voir les 385 exercices » ouvre exactement ces 385 (recherche « pector ») ; la liste du groupe Pectoraux compte les exercices qui sollicitent un muscle dessiné du groupe (437). Deux questions différentes, deux comptes. |
| 14 | Étiquette des champs sur le bord de la pilule, colorée | Thème des champs du kit (§7.2). |
| 15 | Nombre séparé de son unité | Formateurs partagés (§7.9). |
| 16 | Boutons du bas de hauteurs différentes ; ordre de Supprimer | Corrigé : même hauteur, « Annuler » puis le verbe (en `danger`). |
| 17 | Phrase de la racine décalée de 4 dp | Kit (`KPage.root`, §7.2). |
| 18, 19 | Sous-titre de la bibliothèque filtrée ; lignes à plat | Laissés (liste de 1 039 lignes paresseuse) ; la ligne « Voir les N exercices » n'a plus de pastille. |
| 20 | Détails de Mes références | « Non renseigné » corrigé ; « reps » gardé (tests et moteur) ; libellés « Poids du corps » / « Poids de corps » laissés (texte d'origine). |
| 21 | Lignes de Notifications à pastille | Corrigé : plus de pastilles. Rendu avec le rappel actif : à ajouter par UI5 (permission de notification simulée). |
| 22 | Profil : écart, titre du premier groupe, styles du mode prudent | Corrigé : 12 dp, « Mon suivi », un seul style. |
| 23 | « Réinitialiser » de l'Anatomie en lien texte ; bouton à contour du guide ; piste d'interrupteur à 1,6:1 | `filter_menu.dart` (UI0), `program_explainer.dart` (UI1), kit : signalés. |

## 10. Recommandation (C8, le pilotage décide)

**Valider UI4 et le fusionner dans `refonte-ui` avec UI1** (la ligne « Mon programme » de l'accueil et le groupe Calendrier de UI1 remplacent les entrées retirées des Réglages), **à une condition avant UI5 et la publication** : corriger dans le kit le titre d'en-tête tronqué (`KTopBar.sub`/`KFitTitle`, §7.1) — un changement de quelques lignes dans `lib/kit/page.dart`, qui concerne tous les lots et qu'un lot d'écrans n'a pas le droit de faire — et, au même passage, `KSwitchRow` et `KSegmented` à 320 dp × 200 % (§7.2). Le texte de `lib/wellbeing.dart` (§7.3) est à corriger par UI5.

Le reste est conforme : arborescence §4.1 (recherche, carte Profil, 6 rubriques ; Arsenal avec recherche « Exercice ou muscle » et liens fiche ⇄ Anatomie), mêmes réglages qu'avant (tableau §2, aucun perdu, tous à 2 appuis au plus), gabarits §4.5 partout (0 valeur en dur, 0 menu hors gabarit), parcours du profil fini (segments, bouton en bas, « Passer ») avec les mêmes questions et effets, suite complète verte, tour vert sans contenu sous le dock, aucun parcours qui gagne un appui.

Point à présenter au propriétaire : « Compatibilité 3D » à la place de « Diagnostic 3D » (le mot « diagnostic » est interdit par la conformité L13).
