# Inventaire de la navigation de Kalis Track (main b7996b3f, dev6.11.1)

Relevé le 10/10/2026 par trois sous-agents Opus en lecture seule, pour la conversation de pilotage de la refonte UI. Sert de base à l'arborescence du cahier (`CAHIER_UI.md` §4) : chaque lot y retrouve, pour sa zone, chaque entrée (libellé exact, fichier:ligne), chaque doublon et chaque incohérence à traiter. Les numéros de ligne datent de b7996b3f. En cas d'écart avec le cahier, le cahier tranche.

Comptes d'ensemble : plus de 90 pages, environ 60 feuilles, plus de 25 dialogues, 8 menus déroulants (certaines destinations, comme Références, sont comptées dans plusieurs parties).

## Partie 1 — Onglet Réglages et ce qui en part

### Audit d'architecture d'information : onglet Réglages de Kalis Track (main, b7996b3)

Je n'ai rien modifié dans le dépôt.

**Conventions**
- **prof.** = nombre d'appuis depuis la page racine de l'onglet Réglages, qui vaut 0.
- **« en place »** = un contrôle sur la page elle-même.
- Sans précision de fichier, `settings_screen.dart` est sous-entendu.
- **Sélecteur système** = sélecteur de fichiers, partage Android ou réglages Android. Je les cite, mais je ne les compte pas.

**Fichiers de départ sans destination dans ce périmètre**
- `koach_gallery_screen.dart` ne s'atteint pas depuis Réglages. Le seul chemin est Arsenal › Anatomie › « Galerie de Koach » (`anatomy_screen.dart:271-277`).
- `startup.dart` ne contient que l'animation d'ouverture, sans destination.
- `plan_creation.dart` est un modèle de données, sans écran.

**Ce qui n'existe qu'en build dev :**
- la carte « Build de développement » (:419) et le préfixe « dev » de la version ;
- 5 appuis sur le logo de la barre du haut (`dev_widgets.dart:112`) ;
- la rubrique « Outils de test » dans Mon programme (`program_screens.dart:274-345`) : « Simulateur de séances », « Inspecteur du moteur dynamique », « Inspecteur du moteur », « Exporter le journal du moteur (JSON) » ;
- l'icône « Inspecteur du moteur » de la création de programme (`plan_screens.dart:487`).

---

#### 1. Arbre des destinations

**RÉGLAGES (racine)**
- Page, :556. Barre du haut « KALIS TRACK », intro « Réglages / L'application à ta façon. ».
- Bloc **Apparence** en place (prof. 0) :
  - « Thème » : boutons segmentés Système / Sombre / Clair (:76). Au-delà de 150 % de texte, ce sont des boutons radio (:50).
  - « Couleur dominante » : grille de 6 couleurs (:97, :682).
- Titre **« Préférences »** (:562), puis 10 lignes de menu (:564-574). Chacune ouvre une page de section, prof. 1. La barre du haut de ces pages affiche « RÉGLAGES » pour toutes ; le vrai titre est dans le corps (:536-553).
- Pied de page « KALIS TRACK • version » (:578).

#### Sections à réglages simples (prof. 1)

| Ligne (sous-titre affiché) | Contenu, tout en place |
|---|---|
| « Saisie des séries » (« Colonnes, effort et pré-remplissage ») | Interrupteurs « Colonne vitesse (m/s) sur les lifts » (:109) et « Pré-remplir charge suggérée et reps prévues » (:118) |
| « Chronomètres » (« Repos, décompte et signaux ») | Compteur « Repos par défaut », 0-300 s par pas de 15 (:125) ; interrupteur « Lancer le repos à la validation d'une série » (:138) ; compteur « Décompte « Prêt » », 0-10 s (:147) ; interrupteurs « Son en fin de chrono » (:160) et « Vibration en fin de chrono » (:164) |
| « Progression et jeu » (« Célébrations et objectif de la semaine ») | Interrupteur « Célébrations » (:174) ; compteur « Objectif de jours actifs par semaine », 0-6 (:183) |
| « Pendant la séance » (« Écran et unités de charge ») | Interrupteurs « Garder l'écran allumé » (:199) et « Charges suggérées en livres (lb) » (:208) |
| « Affichage 3D » (« Mannequin 3D : nom au toucher, os, halo ») | Interrupteurs « Nom du muscle au toucher » (:855) et « Halo » (:864) |

#### « Notifications » (« Rappels et alertes »), prof. 1, `notification_settings.dart`

- Interrupteur « Rappels de séance » (:63).
- Si les rappels sont activés :
  - ligne « Heure du rappel » (:79), qui ouvre un **dialogue** sélecteur d'heure « Heure du rappel » (:106), prof. 2 ;
  - texte « Prochain rappel : … » ;
  - dépliant « Options Android » (:198), prof. 2. Il contient « Autoriser l'heure précise » (si l'heure précise n'est pas autorisée), « Notifications » et « Batterie », qui mènent tous aux réglages système.
- En cas de blocage ou d'erreur : « Ouvrir les réglages Android », « Réessayer », « Copier le rapport technique » (:158-190).

#### « Sauvegardes » (« Exporter, restaurer ou supprimer tes données »), prof. 1

- « Exporter une sauvegarde » (:220) : sélecteur système de fichiers.
- « Importer une sauvegarde » (:228) : sélecteur système, puis enchaînement de **dialogues** dans `data_control.dart` :
  - « Sauvegarde d'une session de test » (:146), seulement si le fichier vient d'une session de test ;
  - **« Importer cette sauvegarde ? »** (:169), prof. 2. Il contient la case « Sauvegarder d'abord mes données actuelles dans un fichier (recommandé) », puis « Annuler » et « Sauvegarder puis remplacer » ou « Remplacer sans sauvegarde » ;
  - en cas de conflit, « Tes données ont changé » (:192), prof. 3, avec « Revoir l'aperçu ».
- « Copier la sauvegarde » (:236) : action directe, message en bas d'écran.
- « Coller une sauvegarde » (:268) : **dialogue** titré « Importer une sauvegarde » (:595/:645), prof. 2, bouton « Voir l'aperçu ». Il mène au même aperçu (prof. 3) et au même conflit (prof. 4).
- « Copie d'avant la suppression des WOD » (:278), seulement si cette copie existe : **page** titrée « Copie de sécurité » (`retired_notice_screen.dart:142`), prof. 2, avec « Partager la copie » (partage système), « Enregistrer dans un fichier » (sélecteur système) et « Fermer ».
- Carte d'information sans action « Sauvegarde Android » (:292).
- Sous-titre « Zone sensible » (:297), puis « Supprimer les données de l'application » (:298) : **dialogue** « Supprimer les données de l'application ? » (`data_control.dart:220/474`), prof. 2. Il contient la case « Exporter d'abord une sauvegarde (recommandé) », le champ « Tape SUPPRIMER pour confirmer », puis « Annuler » et « Supprimer ».

#### « Programme » (« Date de départ et références »), prof. 1

##### « Profil » (:309) : page « PROFIL » (`athlete_profile_screen.dart:102`), prof. 2

Le sous-titre de la ligne varie : « À créer », « À refaire avec Koach », « … · mode prudent » ou « Disciplines, niveau, … ».

- **Si aucun profil :** « Créer mon profil » ou « Refaire mon profil » (:124) ouvre une **page** de parcours en plusieurs étapes (`athlete_profile_flow.dart`), prof. 3.
- **Sinon :**
  - bulle de Koach ;
  - « Comment marche ton programme ? » (`program_explainer.dart:145`) : **feuille** (:92), prof. 3, bouton « Compris » ;
  - « Compléter mon profil » (:177), seulement s'il reste des questions facultatives : **page** « COMPLÉTER MON PROFIL » (`profile_completion.dart:24`), prof. 3 ;
  - « Tests guidés » (:207) : **page** « TESTS GUIDÉS » (`guided_tests.dart:448`), prof. 3. Chaque proposition ouvre une **page** « TEST GUIDÉ » (:507/:638), prof. 4, avec les champs de résultat, les puces « Aucune » / 1 / 2 / 3, « Ton poids du jour (kg) » et « Enregistrer le résultat ».
  - 12 rubriques (:215, titres dans `athlete_profile.dart:1000`). Chacune ouvre une **page** d'édition titrée du nom de la rubrique (:326), prof. 3, avec un bouton « Enregistrer ». Le détail est dans le tableau ci-dessous.
  - Après un enregistrement qui touche le programme : **feuille** de Koach « Ton programme » (:335), prof. 4, avec « Créer un nouveau programme » (qui ouvre la Création du programme décrite plus bas) et « Plus tard ».
- **Si un profil existe (nouveau ou ancien) :**
  - carte du mode prudent avec « J'ai l'accord de mon médecin » : **dialogue** « Accord du médecin » (:364), prof. 3, bouton « Je confirme » ;
  - « Retirer l'accord déclaré » (:263) : sans confirmation ;
  - carte « Données de santé » : « Donner mon accord » ou « Retirer mon accord ». Le retrait ouvre un **dialogue** « Retirer ton accord ? » (:391), prof. 3, bouton « Retirer et effacer ». « Supprimer mes réponses de santé » (:307) agit sans confirmation.

**Les 12 rubriques du profil (pages prof. 3)**

| Rubrique | Contenu (fichier:ligne) |
|---|---|
| « Toi » | Prénom ou pseudo, Sexe, Année de naissance, Taille (cm), Poids (kg) (flow:710-836) |
| « Discipline principale » | Interrupteur « Mode street », cartes d'options, « Je ne sais pas, choisis pour moi », poids si nécessaire (:916-983) |
| « Disciplines secondaires » | Puces et curseurs de dosage en % (:1013-1120) |
| « Ton expérience » | Niveau, ancienneté, durée de l'arrêt (v3:226) |
| « Ce que tu sais faire » | « Ajouter un record » (**feuille** v3:340, prof. 4, avec un **dialogue** date v3:1314, prof. 5) ; « Je ne sais pas » ; « Je ne sais pas, on verra ensemble » ; « Ajouter une figure » (**feuille** v3:489, prof. 4) ; « Un autre mouvement » (v3:277-607) |
| « Objectifs » | « Laisse Koach proposer » (**feuille** :1239, prof. 4) ; « Objectif de performance » (**feuille** :1415, prof. 4, avec « Autre exercice… » qui ouvre la **page** « CHOISIR UN EXERCICE » :2832, prof. 5, et « D'ici le … » qui ouvre un **dialogue** date :2801, prof. 5) ; « Objectif d'habitude » (**feuille** :1332, prof. 4) ; « Ajouter une date » (**feuille** échéance v3:712, prof. 4, avec un dialogue date v3:2393, prof. 5) ; spécialisation « Choisir » (**feuille** v3:808, prof. 4, qui contient le **menu déroulant** « Muscle » v3:1910, prof. 5) ; points faibles ; base course |
| « Disponibilités » | Jours ; puces de minutes ; « Autre » ouvre le **dialogue** « Durée du <jour> » (:1515), prof. 4 |
| « Lieux et matériel » | Lieux, « Matériel de quel lieu ? », « Partir de… », matériel, **menus déroulants** « Lieu de chaque jour » (:1679, un par jour), prof. 4 |
| « Ta récupération » | Sommeil, stress, « Ajouter un sport » (**feuille** v3:1092, prof. 4), objectif de poids « Jusqu'à combien ? » (v3:981-1125) |
| « Santé, blessures et gênes » | « Avant de continuer » avec J'accepte / Je refuse ; « Questionnaire d'aptitude » (Oui/Non) ; « Blessures et gênes » avec carte du corps, zone qui ouvre une **feuille** (:1895), prof. 4 (:1712-2044) |
| « Exercices aimés et détestés » | Recherche, J'aime / Je n'aime pas (:2071) |
| « Mode assisté ou libre » | 2 cartes d'option et « Comment marche ton programme ? » (:2191) |

##### « Mon programme » (:326) : page « MON PROGRAMME » (`program_screens.dart:347`), prof. 2

Les sous-titres de la ligne sont conditionnels (:331-337).

- Carte du modèle de programme, sans action.
- « Ta saison », si une saison existe : la carte ou « Voir la saison » ouvre la **page** « MA SAISON » (`season_view.dart:326/360/385`), prof. 3. Pour une compétition, « Jour J : tentatives » ou « Jour J : rythme » ouvre une **page** titrée du nom de l'échéance (`season_view.dart:427` ; titre défini dans `event_day_screen.dart:241`), prof. 4.
- « Ton programme d'origine », si une restauration est possible (:454) :
  - « Revenir à mon programme d'origine » : **dialogue** (:531), prof. 3, bouton « Revenir à l'origine » ;
  - « Exporter cette sauvegarde » : sélecteur système.
- « Évolution de ton programme », si un profil existe : la carte ou « Mode, historique, déblocage » ouvre la **page** « ÉVOLUTION » (`evolution_widgets.dart:369/473`), prof. 3. Elle contient :
  - en place, les boutons segmentés « Assisté » / « Libre » (:498) ;
  - les actions « Accepter », « Refuser », « Plus tard », « Compris », « Annuler » et « Annuler ce changement » ;
  - « Voir le changement » ou un appui sur l'historique, qui ouvre la **feuille** « ce qui change » (:185), prof. 4, avec des dépliants « Pourquoi ? ».
- « Revenir à l'ancien programme » (:416), seulement pendant les 7 jours qui suivent un remplacement : action directe, sans confirmation.
- « Où j'en suis » (:190), si une date de départ existe : **page** « OÙ J'EN SUIS » (`program_position.dart:103`), prof. 3, avec le choix de semaine par flèches, le choix du jour et « C'est là que j'en suis ».
- « Préparer le bloc suivant » (:200), en fin de bloc : **feuilles** de Koach « Ton prochain bloc » (`plan_screens.dart:40` ou `:70`), prof. 3, puis Création du programme (prof. 4) ou la **page** « BLOC SUIVANT » sans action (:111).
- **Sans profil :** « Mon profil » (:231) rouvre la page Profil, prof. 3.
- **Avec profil :** « Créer mon programme » ou « Créer un nouveau programme » (:256) ouvre la **page** Création du programme (`plan_screens.dart:136`), prof. 3.

**Création du programme** (pas de titre fixe ; il change selon l'étape : « TES EXERCICES », « BLOC SUIVANT », « REVUE », « RÉCAPITULATIF », « SÉRIES ET CHARGES »). Depuis cette page, prof. 4 :
- « Autre proposition » et « Proposition précédente » (en place) ;
- « Passer les exercices en revue » : « Je sais faire » ; « Je ne sais pas faire » ou « Je n'aime pas », qui ouvrent la **feuille** Variantes (`plan_sheets.dart:61`) ; « Retirer » ; « Ajouter » (**feuille** :188) ; une **feuille** de changement (:342) ; « Fiche et démonstration », qui ouvre une **page** fiche (`exercise_screens.dart:22`) ;
- « Valider les exercices » ;
- appui sur une ligne : **feuille** Ajuster, avec Séries / Répétitions / Repos (:418) ;
- « Valider mon programme » : **feuille** « Remplacer ton programme ? » (`plan_screens.dart:411`) ;
- retour arrière : **feuille** sans titre « Continuer la création / Quitter » (:245).

##### « Départ du programme » (:343) : page « DÉPART DU PROGRAMME » (`program_start.dart:204`), prof. 2

- « Choisir une autre date » : **dialogue** sélecteur de date « DATE DE S1 · J1 » (:120), prof. 3.
- Au premier départ seulement : « Tes références (facultatif) », avec les champs poids, 1RM et max.
- Boutons « Plus tard » ou « Annuler », et « Confirmer le départ » ou « Changer la date ».

##### « Références » (:361) : page « RÉFÉRENCES » (`pilotage_screen.dart:15`), prof. 2

- Champs « Poids de corps », « Force · 1RM de travail », « Endurance · répétitions », « Charges des accessoires ».
- Pour chaque champ : « C'est bien ma valeur » et « Je ne sais pas ».
- Icône seule, infobulle « Effacer toutes mes références » : **dialogue** « Effacer tes références ? » (:20), prof. 3.

#### « Koach » (« Estimations et propositions de charge »), prof. 1

- Carte « Ancien Koach et adaptations au quotidien » (:376), seulement si des anciennes données existent.
- Carte « Données Koach partiellement relues » (:386), seulement s'il y a des erreurs de lecture.
- « Supprimer mes réponses aux anciens questionnaires » (:395), seulement s'il reste des réponses : **dialogue** « Supprimer tes réponses ? » (:606), prof. 2.
- Carte d'information « Confidentialité » (:404), toujours visible.

#### « À propos » (« Version, sécurité, confidentialité, avis »), prof. 1

- Carte « Kalis Track <version> » (:412).
- Carte d'avertissement (:429).
- « Santé et sécurité » (:430) : **page** « SANTÉ ET SÉCURITÉ » (`wellbeing_screens.dart:48`), prof. 2. Elle contient une ligne « Récupération » qui ouvre une **page** (:116), prof. 3.
- « Récupération » (:440) : **page** « RÉCUPÉRATION », intro « Récupérer », prof. 2.
- « Politique de confidentialité » (:450) : **page** « CONFIDENTIALITÉ », prof. 2.
- « Donner mon avis » (:460) : **page** « DONNER MON AVIS », intro « Ton avis », prof. 2. Puces, note de 1 à 5, 3 champs texte, 3 cases à cocher, « Partager mon avis » (partage système), « Copier le texte ».
- « Sources et licences » (:472) : **page**, prof. 2.
- « Moteur 3D » (:482) : **page** « MOTEUR 3D », prof. 2. « Mesurer (10 s) » en place ; « Animation de test » ouvre une **page** (`engine3d.dart:455`), prof. 3.

---

#### 2. Doublons et chevauchements

| Fonction | Entrées (libellé, fichier:ligne) |
|---|---|
| Références | Réglages « Références » (:361) ; Stats › Performance « Modifier mes références » (`stats_performance.dart:28`) ; menu de séance « Références (feuille Pilotage) » (`session_screen.dart:428`) ; appui sur une charge manquante, infobulle « Touche pour ouvrir Références » (`session_screen.dart:742-755`) ; premier départ « Tes références (facultatif) » (`program_start.dart:313`) |
| Poids du corps (5 saisies) | « Poids de corps » (`pilotage_screen.dart:71`) ; « Poids du corps » (`program_start.dart:61`, `store.dart:2147`) ; profil « Poids (kg) » (flow:821/836) ; « Ton poids du jour (kg) » (`guided_tests.dart:738`) ; feuille record (v3:350) |
| 1RM et max | Références ; profil « Ce que tu sais faire » › « Ajouter un record » (v3:316) ; Tests guidés › « Enregistrer le résultat », qui enregistre dans le profil (`guided_tests.dart:588`) |
| Mode assisté / libre | Profil › « Mode assisté ou libre » : cartes d'option (flow:2191) ; Mon programme › Évolution : boutons segmentés « Assisté / Libre » (`evolution_widgets.dart:498`). Le texte d'aide n'indique que Profil (`program_explainer.dart:79`) |
| Accord santé | Profil « Donner mon accord » / « Retirer mon accord » (`athlete_profile_screen.dart:298-313`) ; rubrique Santé « J'accepte / Je refuse » (flow:1737) |
| Effacer des réponses | « Supprimer mes réponses de santé » (`athlete_profile_screen.dart:307`, sans confirmation) ; « Supprimer mes réponses aux anciens questionnaires » (:398, avec dialogue) |
| Objectif de jours actifs | Compteur Réglages 0-6, valeur 1 comprise (:183) ; Stats › « Objectif de la semaine », feuille à puces {Adaptatif, 2, 3, 4, 5, 6}, sans 1 (`game_widgets.dart:694-714`, `stats_overview.dart:34`) |
| Départ du programme | Réglages (:343) ; bandeau de l'accueil « Choisir mon départ » / « Modifier » (`program_start.dart:429/435`, `home_screen.dart:386`) |
| Position dans le programme | « Départ du programme » (date S1·J1) ; « Où j'en suis » dans Mon programme (`program_screens.dart:193`) et sur la carte de l'accueil (:407) |
| Mon programme | Réglages (:330) ; carte de l'accueil « Mon programme » (`program_screens.dart:440`) |
| Bloc suivant | « Préparer le bloc suivant » (`program_screens.dart:204`) ; « Voir le bloc suivant » (:401, accueil) |
| Créer un programme | « Créer mon programme » ou « Créer un nouveau programme » (`program_screens.dart:261-262`) ; onglet Programme (`program_explainer.dart:192`) ; fin du parcours profil (flow:2301) ; feuille après édition « Créer un nouveau programme » (`athlete_profile_screen.dart:345`) |
| Revenir en arrière | « Revenir à l'ancien programme » (`program_screens.dart:429`, sans confirmation) ; « Revenir à mon programme d'origine » (:516, avec dialogue) |
| Évolution | Mon programme, carte et « Mode, historique, déblocage » ; accueil « Et N autres changements : tout voir » (`evolution_widgets.dart:307`) |
| Tests guidés | Profil (`athlete_profile_screen.dart:207`) ; accueil « Voir les tests » (`guided_tests.dart:820`) |
| Compléter mon profil | Profil (:177) ; accueil, Koach « Compléter mon profil » (`profile_completion.dart:71`) |
| Refaire le profil | Profil « Refaire mon profil » (:138) ; écran de démarrage « Refaire mon profil » / « Reprendre mon profil » (flow:127) |
| « Comment marche ton programme ? » | Profil ; parcours profil, étapes accueil / mode / récapitulatif / fin (flow:705, 2214, 2259, 2315) ; onglet Programme (`program_explainer.dart:197`) |
| Exporter une copie (3 objets différents) | « Exporter une sauvegarde » (:223) ; « Exporter cette sauvegarde » (`program_screens.dart:521`) ; « Enregistrer dans un fichier » (`retired_notice_screen.dart:228`). S'y ajoutent les cases « Sauvegarder d'abord… » (`data_control.dart:399`) et « Exporter d'abord… » (:513), même fonction sous deux verbes |
| Supprimer les données | Réglages (:302) ; écran de blocage des mineurs (`wellbeing_screens.dart:469`) |
| Santé et sécurité | À propos (:433) ; séance « Douleur ou malaise ? » (`session_screen.dart:425`) |
| Récupération | À propos (:443) ; Santé et sécurité (`wellbeing_screens.dart:118`). Le mot est aussi utilisé par la rubrique « Ta récupération » du profil, avec un autre contenu |
| Confidentialité | Carte Koach « Confidentialité » (:405) ; « Politique de confidentialité » (:453) ; carte « Sauvegarde Android » (:293) |
| Avertissement | À propos (:429) ; Santé et sécurité (`wellbeing_screens.dart:125`) ; accueil du parcours profil (flow:552) |
| Version | Carte « Kalis Track <version> » (:413) ; pied de page « KALIS TRACK • <version> » (:578) |
| 3D | « Moteur 3D » (À propos, :485) ; section « Affichage 3D » (:493) |
| Repos | « Repos par défaut » (:126) ; « Repos » dans la feuille Ajuster (`plan_sheets.dart:511`) |
| Exercice que je n'aime pas | Profil « Je n'aime pas » (flow:2186) ; création du programme « Je n'aime pas » (`plan_screens.dart:982`) |

---

#### 3. Incohérences

**Mêmes choix, formes différentes**
- **Choix unique :**
  - boutons segmentés pour le thème (:76) et le mode d'évolution (`evolution_widgets.dart:498`) ;
  - cartes d'option pour le même mode dans le profil (flow:2197) ;
  - grille sur mesure pour la couleur (:682) ;
  - puces pour l'accord santé (flow:1737) ;
  - boutons pour ce même accord dans le Profil.
- **Nombre :**
  - compteur pour l'objectif hebdomadaire (Réglages) contre des puces (Stats) ;
  - flèches pour la semaine (`program_position.dart:128`) ;
  - champ de saisie pour les références.
- **Durée :** puces, plus un dialogue « Autre » (flow:1501/1515).
- **Lieu par jour :** menu déroulant (flow:1679).
- **Navigation, sous 6 formes visuelles :**
  - ligne de menu avec pastille (racine, À propos) ;
  - ligne avec chevron, sans pastille (Sauvegardes, Programme) ;
  - carte cliquable sur mesure (Profil) ;
  - carte doublée d'un bouton texte (Évolution :143+:173, Saison :326+:358) ;
  - bouton contour (« Où j'en suis ») ;
  - bouton plein (« Préparer le bloc suivant »).
- **Confirmations des actions destructrices** : saisie du mot SUPPRIMER (`data_control.dart:515`) ; dialogue simple (:606, `pilotage_screen.dart:20`, `athlete_profile_screen.dart:391`, `program_screens.dart:531`) ; aucune confirmation (`athlete_profile_screen.dart:262`, `:306`, `program_screens.dart:418`).
- « Effacer toutes mes références » n'est qu'une icône « restore » dans la barre du haut (`pilotage_screen.dart:17-19`).

**Libellés jargonneux ou internes**
- « pilotage » (:225, :612, `data_control.dart:486`) ; « Références (feuille Pilotage) » (`session_screen.dart:428`).
- « S1 · J1 » (:349-352, `program_start.dart`) ; « 1RM de travail » ; « RIR » (`plan_sheets.dart:572`).
- « Cible 12 mois … ajuste les jours 4 à 6 » (`pilotage_screen.dart:82,91`), propre au programme de 40 semaines.
- « v3.3, révisions LC1 comprises » (`program_screens.dart:37`) ; « programme du moteur » (:115, :483) ; « moteur calibré » (`plan_screens.dart:45-90`).
- « WOD » (:282) ; « Ancien Koach et adaptations au quotidien » (:379) ; « Données Koach partiellement relues » (:388).
- « Canal « Rappel quotidien » désactivé » (`notification_settings.dart:149`).
- Page Moteur 3D : « Flutter GPU », « API graphique », « Impeller », « 99e centile », « Préchargement », « Désactivé (mesure de référence) » (`engine3d.dart:393-577`). C'est un diagnostic de développeur visible en production.

**Titres qui se contredisent**
- Le titre « Préférences » (:562) regroupe Sauvegardes, Programme, Koach et À propos, qui ne sont pas des préférences.
- La section « Programme » porte le même nom que l'onglet Programme (`nav_bar.dart:33`).

**Descriptions de section obsolètes ou fausses**
- « Colonnes, effort et pré-remplissage » (:517) : le réglage d'effort RIR/RPE a été retiré.
- « Estimations et propositions de charge » (:524) : la section Koach ne contient rien de tel.
- « Date de départ et références » (:523) : omet Profil et Mon programme.
- « Rappels et alertes » (:521) : il n'y a qu'un rappel.
- « nom au toucher, os, halo » (:526) : le réglage « Os » a été retiré (:862).

**Chemins faux dans les textes de l'app**
- « Réglages › Profil » alors que le vrai chemin est Réglages › Programme › Profil : `athlete_profile_screen.dart:29`, `program_explainer.dart:79,84`, flow:702 et :1752, `plan_screens.dart:462`, `profile_completion.dart:68`.
- « Réglages › Mon programme » : `athlete_profile_screen.dart:155`, `plan_screens.dart:46`, flow:2274.

**Rubriques fourre-tout**
- « À propos » mélange version, avertissement, santé, récupération, confidentialité, avis, licences et diagnostic 3D.
- « Programme » réunit les fonctions centrales (profil, programme), enfouies à 2 appuis.
- « Koach » ne contient que de l'ancien et de l'information.
- « Pendant la séance » contient l'unité en livres, qui n'est pas propre à la séance.

**Rubriques à un ou deux réglages**
- Saisie des séries (2), Progression et jeu (2), Pendant la séance (2), Affichage 3D (2), Notifications (1 et son heure).
- Koach : 0 réglage. Pour un nouvel utilisateur, seule la carte « Confidentialité » s'affiche.

**Réglages enfouis à plus de 3 appuis**
- Prof. 4 :
  - les feuilles et dialogues des rubriques du profil : record, figure, objectifs, échéance, spécialisation, autre sport, blessure, « Durée du <jour> », « Lieu de chaque jour » ;
  - « Enregistrer le résultat » d'un test guidé ;
  - la feuille « ce qui change » de l'Évolution ;
  - la page « Jour J » ;
  - toutes les feuilles de la création du programme.
- Prof. 5 : dates d'objectif, d'échéance et de record ; « CHOISIR UN EXERCICE » ; menu déroulant « Muscle ».

**Titres de page**
- Les 10 sous-pages ont la même barre « RÉGLAGES » (:539).
- « Copie de sécurité » n'est pas en majuscules (`retired_notice_screen.dart:142`), contrairement aux autres titres.
- La feuille « Quitter » n'a pas de titre (`plan_screens.dart:245`).
- Titres qui ne reprennent pas le libellé d'entrée :

| Libellé d'entrée | Titre affiché |
|---|---|
| « Politique de confidentialité » | « CONFIDENTIALITÉ » |
| « Copie d'avant la suppression des WOD » | « Copie de sécurité » |
| « Récupération » | « RÉCUPÉRATION » + intro « Récupérer » |
| « Donner mon avis » | intro « Ton avis » |
| « Ta saison » / « Voir la saison » | « MA SAISON » |
| « Mode, historique, déblocage » | « ÉVOLUTION » |
| « Créer mon programme » | « TES EXERCICES » |

**Culs-de-sac (texte sans aucune action)**
- Tests guidés sans proposition (`guided_tests.dart:461`).
- « BLOC SUIVANT » quand il est indisponible (`plan_screens.dart:111`).
- Création du programme sans profil, qui renvoie à un chemin faux (`plan_screens.dart:451-468`).
- Évolution sans profil (`evolution_widgets.dart:477`).
- « MA SAISON » vide (`season_view.dart:386`).
- Boucle Mon programme › « Mon profil » › Profil › « Créer un nouveau programme » : les pages s'empilent.

---

#### 4. Comptes (hors dev et hors sélecteurs système)

| Élément | Nombre | Détail |
|---|---|---|
| **Pages** | **47** | Racine + 10 sous-pages de section + 12 rubriques du profil qui partagent un même écran ; 36 écrans distincts |
| **Feuilles** | **20** | 2 côté Profil, 9 dans les rubriques, 6 dans la création du programme, 2 pour le bloc suivant, 1 pour l'Évolution |
| **Dialogues** | **16** | Dont 5 sélecteurs (1 heure, 4 dates) |
| **Menus déroulants** | **2** | « Lieu de chaque jour » et « Muscle ». Aucun menu contextuel dans ce périmètre ; le menu de séance est hors périmètre |
| Dépliants en place | 4 | « Options Android » et 3 « Pourquoi ? » |
| **Réglages distincts** | **33** | Voir le détail ci-dessous |

Détail des 33 réglages :
- 17 préférences de l'app : thème, couleur, vitesse, pré-remplissage, repos par défaut, repos automatique, décompte, son, vibration, célébrations, objectif hebdomadaire, écran allumé, livres, rappels, heure du rappel, nom au toucher, halo ;
- 5 réglages de programme et de santé : départ, références (en groupe), mode assisté/libre, accord santé, accord du médecin ;
- 11 rubriques du profil, sans compter « Mode assisté ou libre » déjà compté.

Le mode assisté/libre est réglable à 2 endroits, l'objectif hebdomadaire à 2, l'accord santé à 2 et le poids du corps à 5.

## Partie 2 — Onglets Programme et Arsenal

### Audit d'architecture d'information : onglets Programme et Arsenal

Commit b7996b3, lecture seule, aucun fichier modifié. Notation : **P+n** veut dire n appuis depuis l'onglet Programme affiché, **A+n** depuis l'onglet Arsenal, **R+n** depuis l'onglet Réglages. Les chemins sont relatifs à `/home/claude/streetlift-apk/`.

**Cadre.** La barre du bas (`lib/nav_bar.dart:30-35`) a quatre onglets dans cet ordre : Arsenal, Stats, Programme, Réglages. L'onglet ouvert au lancement est Programme (`lib/main.dart:289`). Seul l'onglet actif affiche son libellé. Avant le premier affichage, deux écrans peuvent passer devant :
- `ProfileGate` (`main.dart:271`) ;
- une fois seulement, la page « Mise à jour » (`retired_notice_screen.dart:142`, déclenchée en `main.dart:303`).

---

#### 1. Arbre des destinations

#### 1.A Onglet Programme (`HomeScreen`, `lib/home_screen.dart:297`)

**État « sans programme »** (nouveau profil, condition en `program_explainer.dart:155-159`). La page `ProgramPendingView` remplace tout l'onglet (`home_screen.dart:301`). Elle n'a ni semaines ni pastille de niveau.
- En-tête « TON PROGRAMME » (`program_explainer.dart:171`), puis une bulle de Koach.
- **« Créer mon programme »** (bouton plein, `program_explainer.dart:189-196`), P+1. Il ouvre la création du programme (voir P-CRE plus bas). Il est désactivé sans explication si `planCanCreate` est faux.
- **« Comment marche ton programme ? »** (bouton contour, `program_explainer.dart:197`, puis `:141-151`), P+1. Il ouvre une feuille du bas (`:91-138`) :
  - titre « Comment marche ton programme » ;
  - 8 paragraphes, de « 1. Les exercices de chaque séance » à « 8. Ton profil » ;
  - bouton « Compris ».

**État normal.** La barre du haut est `KTopBar` : à gauche la pastille de niveau, avec l'en-tête de semaine en taille de texte courante ; à droite le logo. La page n'a pas de titre « Programme ».

**Pastille de niveau** « NIV. n » (`levelup.dart:18-50`, infobulle « Ouvrir ma progression »), P+1. Ce n'est pas une page : elle **change d'onglet**. Elle referme toutes les pages ouvertes, puis affiche Stats › section « Parcours » (`progression_screen.dart:5-10`, `stats_navigation.dart:21-27`).

**En-tête de semaine**
- Version compacte : « SEMAINE n ▾ » avec « dates · bloc » dessous (`home_screen.dart:440-487`). Un appui ouvre F1, P+1.
- En grand texte : bouton texte **« Semaines »** (`home_screen.dart:508-513`), qui ouvre aussi F1, P+1.

**F1 – Feuille « Choisir une semaine »** (`home_screen.dart:115-155`)
- Liste de lignes « Semaine n · dates ». Sous-titre : le bloc, plus « · Semaine actuelle » pour la semaine en cours. À droite : « fait / total ».
- Un appui sur une ligne ferme la feuille et affiche la semaine choisie.

**Curseur de semaines** (pastille « Sn », `home_screen.dart:520-701`). Il n'a aucun libellé visible.
- Appui court : ouvre F2, P+1 (`:610-613`).
- Appui long : ouvre F1 (`:614-617`).
- Glisser : change de semaine.
- La liste défile aussi d'une semaine par glissement horizontal (`:357-367`). Au clavier : F2 ouvre F1, Entrée ouvre F2.

**F2 – Feuille « détail de la semaine »** (`home_screen.dart:158-224`)
- Contenu : « Semaine n », les dates, le bloc, le cycle, « x / y journées validées », la section « Séances de la semaine ».
- Une ligne par jour : « Jn », le titre, « n exercices · durée » ou « Récupération ». Un appui ferme la feuille et ouvre la journée, P+2 (`:194-197`).
- « Revenir à la semaine actuelle », seulement si une autre semaine est affichée (`:200-208`).
- « Choisir une semaine » (`:209-216`) ferme F2 puis ouvre F1, P+2.
- « Fermer ».

**Bandeau de départ** `ProgramStartBanner` (`home_screen.dart:385-386`, puis `program_start.dart:405-475`). Il est visible si le départ n'est pas choisi, avant le départ, ou après la fin.
- « Programme non démarré », bouton texte **« Choisir mon départ »**.
- « Départ le … », bouton texte **« Modifier »**.
- « Programme terminé le … » : **aucune action**.
- Les deux boutons ouvrent la page P-START, P+1 (`:443-445`).

**P-START – Page « DÉPART DU PROGRAMME »** (`program_start.dart:204`)
- Cartes : explication, « Départ actuel », « Date de S1 · J1 » ou « Nouvelle date de S1 · J1 », « Fin prévue (Sn · J7) : … », « Effet du changement ».
- **« Choisir une autre date »** (`:256-261`), P+2. Il ouvre le calendrier système (`showDatePicker`, `:120-128`) : titre « DATE DE S1 · J1 », boutons « Annuler » et « Choisir ».
- Avant le premier départ seulement : section « Tes références (facultatif) » avec les champs « Poids du corps », « {mouvement} · 1RM » et « {nom} · max » (`:312-331`).
- Barre du bas : « Plus tard » ou « Annuler », puis « Confirmer le départ » ou « Changer la date » (`:342-357`).

**Bandeau « À reprendre »** (`resume_banner.dart:42-48`). Il est visible si une séance est commencée.
- Une ligne par séance (3 au plus) : « {titre} · x/y séries validées », bouton texte **« Reprendre »**. P+1, ouvre l'écran de séance.

**Cartes des journées** `_DayCard` (`home_screen.dart:388` puis `:703-998`). La carte du jour est grande et colorée ; les autres sont des lignes compactes.
- **Appui** (`:808`), P+1, via `openProgramDay` (`:37-69`) :
  - journée faite : historique de la séance, page avec le titre de la séance et « Sn · Jn · Lecture seule » (`session_history.dart:345-376`) ;
  - sinon : **écran de séance** `SessionScreen` (`home_screen.dart:58`). C'est là que l'audit s'arrête.
  - Au retour : soit la page plein écran de récompense, soit le dialogue « Niveau n » (`rewards.dart:29-97`) avec « Ma progression » et « Continuer ».
- **Appui long** (`:809`), P+1. Rien à l'écran ne l'indique ; seule l'aide d'accessibilité dit « Afficher le résumé ». Il ouvre :
  - jour de repos : feuille « Résumé · Sn · Jn » (`:265-284`) ;
  - jour de séance : feuille `showEstimate` (`estimate_view.dart:5-64`). Contenu : titre, résumé, carte des muscles, « Temps estimé » ou « Durée prévue », « Séries / passages », effort, repos, transitions, puis la liste « DÉTAIL DU VOLUME PRÉVU ». Chaque élément de cette liste rouvre la même feuille par-dessus (`:37`), P+2 ou plus, sans limite de profondeur.
- Statuts affichés : « Séance effectuée », « Séance en cours » ou « En cours », « Reprise : séance neutre » ou « Reprise », « Séance à faire ».

**Carte d'évolution** `EvolutionHomeCard` (`home_screen.dart:391`, puis `evolution_widgets.dart:262-316`). Elle est visible s'il y a une proposition en attente (mode libre) ou un changement annoncé (mode assisté).
- Titre « Koach · {type} », bulle de Koach avec un dépliant « Pourquoi ? ».
- Actions (`evolution_widgets.dart:105-180`) :
  - proposition en attente : « Accepter », « Refuser », « Plus tard » ;
  - changement déjà appliqué : « Compris », « Annuler » ;
  - toujours : **« Voir le changement »**, qui ouvre F-EVO, P+1.
- **« Et n autre(s) changement(s) : tout voir »** (bouton texte, `:300-311`) ouvre P-EVO, P+1.

**F-EVO – Feuille d'un changement** (`evolution_widgets.dart:185-256`)
- Titre : le type de changement. Bulle de Koach avec les mêmes actions que ci-dessus.
- Section « Ce qui change (n) » : lignes dépliables « Pourquoi ? ».

**Carte « Compléter mon profil »** (`home_screen.dart:394`, puis `profile_completion.dart:42-88`). Elle ne s'affiche qu'une fois.
- Bulle « Nouveau : n questions… » ou « Ta première semaine est passée… », avec « Pourquoi ? ».
- **« Compléter mon profil »** ouvre la page « COMPLÉTER MON PROFIL » (`athlete_profile_flow.dart:493`), P+1.
- « Plus tard ».

**Carte des tests guidés** (`home_screen.dart:396`, puis `guided_tests.dart:789-838`). Elle est visible après le départ quand un test non vu est proposé.
- **« Voir les tests »** ouvre P-TESTS, P+1.
- « Plus tard ».

**P-TESTS – Page « TESTS GUIDÉS »** (`guided_tests.dart:448`)
- Bulle de Koach, puis une carte par test : nom de l'exercice et titre du test.
- Appui sur une carte : page « TEST GUIDÉ » (`:638`), P+2. Cartes « Sécurité », « Déroulé », « Quand t'arrêter », « Ton résultat » (champs, pastilles de choix « Aucune », « 1 », « 2 », « 3 »), bouton **« Enregistrer le résultat »**.

**Carte programme** `ProgramHomeCard` (`home_screen.dart:401`, puis `program_screens.dart:356-449`). Elle n'est visible que dans trois cas : retour possible à l'ancien programme, fin de bloc d'un programme créé avec Koach, ou saisie absente depuis un moment (`:360-363`).
- **« Voir le bloc suivant »** (fin de bloc) lance N-BLOC, P+1.
- **« Où j'en suis »** ouvre P-POS, P+1 ; à côté, « Plus tard ».
- **« Revenir à l'ancien programme »** : action directe, avec un message court de confirmation.
- **« Mon programme »** (bouton texte, `:431-441`) ouvre P-PROG, P+1.

**P-PROG – Page « MON PROGRAMME »** (`program_screens.dart:347`)
- Carte modèle : « Programme créé avec Koach », ou « Expert streetlifting (40 semaines) », ou le libellé du modèle généré. Aucune action.
- **Carte « Ta saison »** (`season_view.dart:315-372`), si une saison existe. La carte entière et le bouton « Voir la saison » ouvrent P-SAISON.
- **Carte « Ton programme d'origine »** (`program_screens.dart:454-591`), si le programme d'origine peut être restauré :
  - « Revenir à mon programme d'origine » ouvre un **dialogue** (`:531-556`) : « Revenir à ton programme d'origine ? », boutons « Annuler » et « Revenir à l'origine » ;
  - « Exporter cette sauvegarde » ouvre le sélecteur de fichier système.
- **Carte « Évolution de ton programme »** (`:140-183`), si un profil existe. La carte entière et le bouton « Mode, historique, déblocage » ouvrent P-EVO.
- La carte programme ci-dessus, recopiée dans la page (`:186`), avec seulement « Revenir à l'ancien programme ».
- **« Où j'en suis »** (bouton contour, `:188-196`) ouvre P-POS.
- **« Préparer le bloc suivant »** (bouton plein, `:198-208`) lance N-BLOC. Il s'affiche aussi en fin de bloc du programme importé de 40 semaines.
- Sans profil : bouton « Mon profil » (`:224-232`), qui ouvre la page « PROFIL » (`athlete_profile_screen.dart:102`).
- Avec profil : **« Créer mon programme »** ou **« Créer un nouveau programme »** (`:256-267`), qui ouvre P-CRE.
- Build dev seulement : section « Outils de test » (`:274-345`).

**P-SAISON – Page « MA SAISON »** (`season_view.dart:385`)
- Carte de l'échéance : nom, date, compte à rebours.
- Pour une compétition seulement : **« Jour J : tentatives »** ou **« Jour J : rythme »** (`:416-433`), qui ouvre P-JOURJ.
- Sections « Phases », « Bloc n, semaine par semaine », « Figures », « Règles de ton programme ». Lecture seule.

**P-JOURJ – Page Jour J** (`event_day_screen.dart:240-242`). Titre : le nom de l'épreuve en majuscules, ou « JOUR J ».
- Pastilles de choix (force seulement) : « Assurer un total », « Viser le plus gros total », « Tenter un record ».
- Par mouvement : maximum estimé, échauffement, tentatives avec les icônes « Réussie » et « Manquée ».
- Carte « Objectif : n répétitions » et rythme conseillé.

**P-EVO – Page « ÉVOLUTION »** (`evolution_widgets.dart:473`)
- Carte « Quand je vois qu'un changement t'aiderait » : sélecteur **« Assisté » / « Libre »** (`:498-512`).
- Carte de déblocage (`:374-443`), lecture seule.
- Section « Propositions en attente » : bulles avec les mêmes actions que la carte d'évolution.
- Cartes « J'ai repéré un changement possible… » (sans action).
- Section « Historique des changements » : un appui sur une carte ouvre F-EVO ; bouton « Annuler ce changement » (`:625`).

**P-POS – Page « OÙ J'EN SUIS »** (`program_position.dart:103`)
- Flèches « Semaine précédente » / « Semaine suivante ».
- Section « Ta séance d'aujourd'hui » : cartes à cocher « Jn · titre ».
- Bouton **« C'est là que j'en suis »**.

**N-BLOC – Bloc suivant** (`plan/plan_screens.dart:34-107`)
- Programme importé : feuille de Koach « Ton prochain bloc » (`:40-63`), choix « Voir le bloc du moteur calibré » ou « Plus tard » / « Garder mon programme ».
- Ancien moteur : feuille de Koach « Ton prochain bloc » (`:70-93`), choix « Passer au moteur calibré » ou « Garder le moteur actuel ».
- Ensuite, soit P-CRE en mode bloc suivant, soit la page « BLOC SUIVANT » `NextBlockUnavailable` (`:111-131`), qui est un **cul-de-sac**.

**P-CRE – Création du programme** `PlanCreationScreen`. C'est une seule page dont le titre change selon l'étape (`plan_screens.dart:480-485`). Sans profil, elle affiche « TON PROGRAMME » avec un simple message (`:452-467`).
- Le retour système recule d'une étape (`:472-476`). À la première étape, il ouvre une feuille de Koach sans titre (`:245-266`) : « Continuer la création » / « Quitter ».
- **Étape 1, « TES EXERCICES »** ou « BLOC SUIVANT » : cartes par jour, carte « Ta semaine », puis :
  - « Proposition suivante (i/n) » ou « Autre proposition » ;
  - « Proposition précédente (i/n) » ;
  - **« Passer les exercices en revue »**, « Reprendre la revue », « Passer les nouveaux exercices en revue (n) » ou « Voir le récapitulatif » (`:785-812`, `:740-751`).
- **Étape 2, « REVUE »** (fiches qu'on fait défiler une à une) :
  - en haut : « Exercice i / n · n vus », bouton texte « Récapitulatif » ;
  - par fiche : « Fiche et démonstration » (`:946-951`, ouvre FICHE), « Je sais faire », « Je ne sais pas faire », « Je n'aime pas », « Retirer », « Suivant » ;
  - « Je ne sais pas faire » et « Je n'aime pas » ouvrent la feuille des variantes (`plan_sheets.dart:61-183`) : bulle sans titre, cartes de variantes, « Laisse Koach choisir », « Voir tout (n) », « Afficher plus » ;
  - barre du bas : « Ajouter », qui ouvre la feuille d'ajout (`plan_sheets.dart:188-283`) : « Ajouter un exercice que tu aimes », « Quel jour ? » en pastilles, champ de recherche. Puis « Annuler » ;
  - après chaque action, une feuille de résultat sans titre (`plan_sheets.dart:342-413`) : « OK », « Annuler ce changement », section « Ce qui a bougé (n) ».
- **Étape 3, « RÉCAPITULATIF »** : « Valider les exercices », « Revenir à la revue ».
- **Étape 4, « SÉRIES ET CHARGES »** :
  - pastilles « Sn · {type} », une par semaine ;
  - un appui sur un exercice ouvre la feuille de réglage (`plan_sheets.dart:418-558`) : titre = nom, réglages « Séries », « Répétitions », « Repos » avec boutons moins/plus, « Revenir à ma proposition », « OK » ;
  - **« Valider mon programme »**. Si un programme existe déjà, une feuille de Koach demande « Remplacer ton programme ? » (`plan_screens:411-432`) avec « Remplacer mon programme » / « Garder mon programme actuel ».
  - « Revenir aux exercices ».
- **FICHE** = page « FICHE EXERCICE » (voir Arsenal).

**Ce qui n'apparaît qu'en build dev :**
- le logo (5 appuis ou appui de 3 s, `dev/dev_widgets.dart:112-128`) ;
- la section « Outils de test » de P-PROG, avec « Simulateur de séances », « Inspecteur du moteur dynamique », « Inspecteur du moteur », « Exporter le journal du moteur (JSON) » ;
- l'icône d'inspecteur dans la barre de P-CRE (`plan_screens.dart:487-497`).

#### 1.B Onglet Arsenal (`lib/arsenal_screen.dart:10-50`)

- Barre du haut : « KALIS TRACK » et le logo. Intro « ARSENAL » / « Tes exercices. Tes muscles. Ta technique. ».

**« Exercices »**, ligne de menu avec le sous-titre « Fiches, démonstrations, muscles et progressions » (`:24-33`), A+1. Elle ouvre la page « EXERCICES » (`exercise_screens.dart:231`) :
- intro et texte « Base d'exercices : 8 disciplines… » ;
- champ de recherche « Nom, muscle, matériel, discipline… » avec bouton « Effacer la recherche » (`:205-209`) ;
- bouton **« Filtres · n »**, qui ouvre un **menu déroulant** (`filter_menu.dart:197-220`), A+2 :
  - titre « Filtres » et bouton « Réinitialiser » ;
  - catégories qui se replient : « Discipline », « Type de mouvement », « Niveau », « Lieu », « Matériel », « Difficulté » (« Accessible (1 à 3) », « Intermédiaire (4 à 6) », « Avancé (7 à 10) ») ;
  - dans chaque catégorie : « Tout cocher », « Tout décocher », cases à cocher ;
  - sous le bouton : pastilles des filtres actifs, « + n », « Réinitialiser » ;
- compteur « n exercices », état vide « Aucun exercice » ;
- une ligne par exercice : nom, « discipline · niveau · difficulté n/10 ». Un appui ouvre la FICHE, A+2.

**Page « FICHE EXERCICE »** (`exercise_screens.dart:290`)
- Nom, « Aussi : … », étiquettes (discipline, niveau, difficulté, type de charge).
- Démonstration 3D si elle existe, avec « Lecture » / « Pause » et un curseur (`mannequin_player.dart:449-460`).
- Sections « Points clés », « Erreurs fréquentes », « Respiration », « Muscles » (carte et listes), « Matériel et lieux ».
- Sections de liens : « Paliers conseillés avant », « Variante de », « Variantes ». Chaque lien rouvre une FICHE (`:336-357`), A+3 et plus, sans limite.

**« Anatomie »**, ligne de menu avec le sous-titre « Muscles, groupes et vues » (`arsenal_screen.dart:36-45`), A+1. Elle ouvre la page « ANATOMIE » (`anatomy_screen.dart:206`) :
- bouton **« Filtres · n »** : menu déroulant avec une seule catégorie, « Groupes musculaires » (17 cases), A+2 ;
- carte des muscles : toucher un muscle affiche son nom. Si le réglage est coupé, le texte renvoie à « Réglages › Affichage 3D » ;
- liste des groupes cochés avec leurs muscles ;
- carte **« Galerie de Koach »** (« 36 poses animées et 10 flammes de difficulté », `:262-279`), A+2. Elle ouvre la page « GALERIE DE KOACH » (`koach/koach_gallery_screen.dart:84`) :
  - grille des poses (un appui affiche la pose, `:216`) et sélecteur de flammes (`:124`) ;
  - bulle de démonstration ;
  - « Feuille de Koach » (`:169`) ouvre une feuille « Les flammes » avec « OK », A+3 ;
  - « Message court » (`:182`) affiche un message court en bas d'écran.

---

#### 2. Doublons et chevauchements

| Fonction | Entrées (libellé, fichier:ligne) |
|---|---|
| Mon programme | « Mon programme » sur la carte programme, conditionnelle (`program_screens.dart:440`) ; Réglages › Programme › « Mon programme » (`settings_screen.dart:330-340`, R+2) |
| Créer un programme | « Créer mon programme » (`program_explainer.dart:192`) ; « Créer mon programme » / « Créer un nouveau programme » (`program_screens.dart:259-265`) ; feuille de Koach du profil « Créer un nouveau programme » (`athlete_profile_screen.dart:345,357`) ; fin du parcours de profil (`athlete_profile_flow.dart:2298`) |
| Bloc suivant | « Voir le bloc suivant » (`program_screens.dart:401`) et « Préparer le bloc suivant » (`:203`) |
| Où j'en suis | `program_screens.dart:407` (carte) et `:193` (page) |
| Revenir en arrière dans le programme | « Revenir à l'ancien programme » (`:429`, sur l'accueil et recopié dans la page) ; « Revenir à mon programme d'origine » (`:516`) : deux notions voisines, libellés proches |
| Évolution (page) | « Et n autres changements : tout voir » (`evolution_widgets.dart:305`) ; carte « Évolution de ton programme » (`program_screens.dart:143`) et, dans la même carte, « Mode, historique, déblocage » (`:175`) |
| Voir un changement | « Voir le changement » (`evolution_widgets.dart:174`, `:351` dans la séance) ; appui sur une carte de l'historique (`:568`) |
| Annuler un changement | « Annuler » (`evolution_widgets.dart:158`) et « Annuler ce changement » (`:625`) ; dans la création : « Annuler ce changement » (`plan_sheets.dart:383`) et « Annuler » (`plan_screens.dart:877`) |
| Mode assisté / libre | Sélecteur dans « ÉVOLUTION » (`evolution_widgets.dart:498-511`) ; rubrique du profil (`athlete_profile_flow.dart:2200-2212`). Le texte d'explication dit « Réglages › Profil » (`program_explainer.dart:79`) ; la ligne de Réglages dit « Mon programme : mode assisté ou libre » (`settings_screen.dart:381`) |
| Saison | « Ta saison » / « Voir la saison » (`season_view.dart:326,360`) ; homonyme côté Stats › Aperçu : « Saison n · nom » (`game_widgets.dart:1255-1273`), une autre notion (le jeu) |
| Départ du programme | « Choisir mon départ » / « Modifier » (`program_start.dart:429,435`) ; Réglages › Programme › « Départ du programme » (`settings_screen.dart:347-357`) |
| Références | Réglages › Programme › « Références » (`settings_screen.dart:364`) ; Stats › Performances « Modifier mes références » (`stats_performance.dart:30`) ; menu ⋮ de la séance « Références (feuille Pilotage) » (`session_screen.dart:429`) ; référence manquante dans la séance, « Touche pour ouvrir Références » (`session_screen.dart:742-754`) ; formulaire recopié dans « DÉPART DU PROGRAMME » (`program_start.dart:312-331`) |
| Profil | Réglages › Programme › « Profil » (`settings_screen.dart:313`) ; « Mon profil » (`program_screens.dart:231`) |
| Compléter mon profil | Carte de l'accueil (`profile_completion.dart:71`) ; carte dans « PROFIL » (`athlete_profile_screen.dart:167`) |
| Tests guidés | « Voir les tests » (`guided_tests.dart:820`) ; carte « Tests guidés » dans « PROFIL » (`athlete_profile_screen.dart:195`, R+3) |
| Comment marche ton programme ? | Écran sans programme (`program_explainer.dart:197`) ; « PROFIL » (`athlete_profile_screen.dart:161`) ; parcours de profil (`athlete_profile_flow.dart:705, 2214, 2259, 2315`). Absent de l'onglet Programme normal et de « MON PROGRAMME » |
| Fiche d'exercice | Bibliothèque (`exercise_screens.dart:266`) ; liens de la fiche (`:353`) ; « Fiche et démonstration » dans la création (`plan_screens.dart:950`). Introuvable depuis les cartes des journées, la séance et l'Anatomie |
| Ouvrir une journée | Carte du jour (`home_screen.dart:808`) ; ligne de F2 (`:194`) ; « Reprendre » (`resume_banner.dart:47`) ; notification (`main.dart:88`) ; historique Stats (`stats_history.dart:104`) |
| Choisir une semaine | En-tête « SEMAINE n ▾ » (`home_screen.dart:440`) ; « Semaines » (`:508`) ; appui long sur le curseur (`:614`) ; « Choisir une semaine » dans F2 (`:209`) ; touche F2 du clavier (`:597`) |
| Progression | Pastille de niveau, infobulle « Ouvrir ma progression » (`levelup.dart:30`) ; « Ma progression » (`rewards.dart:89`, `:316`) ; Stats « Arbre de progression » (`stats_overview.dart:91`) et « Parcours » (`:45`). La destination s'appelle « Parcours » |
| Recherche d'exercices | Voir section 5 : 4 champs, 4 textes d'aide différents |

---

#### 3. Incohérences

**Fonctions enfouies (plus de 3 appuis)**
- Hors des trois cas qui affichent la carte programme, « MON PROGRAMME » ne s'ouvre que par Réglages : P+3.
  - Saison : P+4.
  - Jour J : P+5.
  - Évolution : P+4, sauf si la carte d'évolution affiche « tout voir ».
- Programme importé de 40 semaines : « Préparer le bloc suivant » n'existe que dans « MON PROGRAMME » (`program_screens.dart:198-199`). La condition d'affichage de la carte (`:360-363`) n'inclut pas `planImportedNextBlockOffered`. → Une ligne : proposer aussi ce cas sur l'accueil.
- Feuille de réglage d'un exercice dans la création : au mieux P+6 (Mon programme, Créer, revue, Récapitulatif, Valider les exercices, appui sur l'exercice).
- Tests guidés et « Compléter mon profil », une fois leur carte écartée : R+3.
- Galerie de Koach : A+2, rangée sous « Anatomie » alors qu'elle n'a pas de lien avec ce sujet. Elle contient des démonstrations techniques (« Feuille de Koach », « Message court »).

**Gestes cachés**
- Appui long sur une journée = résumé, sans aucun signe visible (`home_screen.dart:809`).
- Curseur : appui court = détail, appui long = choix de semaine (`:610-617`).
- Glissement horizontal sur la liste = semaine suivante ou précédente.

**Même type de choix, formes différentes**
- Choisir une semaine :
  - liste en feuille (F1) ;
  - flèches et cartes à cocher (P-POS) ;
  - pastilles de choix (`plan_screens.dart:1092`).
- Mode assisté / libre : sélecteur (`evolution_widgets.dart:498`) contre cartes de choix dans le profil.
- « Plus tard » sert à cinq choses différentes : reporter d'un jour, écarter définitivement, garder le programme, etc.

**Importance mal rendue**
- « Mon programme », qui mène au hub, est un simple bouton texte (`program_screens.dart:432`).
- Les cartes « Ta saison » et « Évolution » s'ouvrent à la fois par la carte entière et par un bouton texte à l'intérieur (`season_view.dart:326/360`, `program_screens.dart:143/175`).
- « Exporter cette sauvegarde » est un bouton texte à côté d'un bouton contour.

**Libellés incohérents**
- Tutoiement et possessifs mélangés : « MON PROGRAMME », « TON PROGRAMME » (`program_explainer.dart:171`, `plan_screens.dart:453`, `athlete_profile_flow.dart:2278`), carte « Ta saison » qui ouvre « MA SAISON ».
- Le sous-titre de la section Réglages › Programme dit « Date de départ et références » (`settings_screen.dart:519`), alors qu'elle contient aussi Profil et Mon programme.
- « Revenir aux exercices » mène au récapitulatif (`plan_screens.dart:1210`).

**Jargon**
- Sur l'accueil : « GtG suspendu » (`home_screen.dart:243, 887`), « Reprise : séance neutre » (`:734`).
- Dans le résumé : « Séries / passages », « kg·rép. externes connus » (`estimate_view.dart:86, 99`).
- Dans la création : « RIR » (`plan_sheets.dart:572`), « moteur calibré » (`plan_screens.dart:50, 83`).
- Dans « MON PROGRAMME » : « révisions LC1 » et « programme du moteur » (`program_screens.dart:37, 115-117`).
- Dans la séance : « Références (feuille Pilotage) ».

**Culs-de-sac**
- Page « BLOC SUIVANT » quand le bloc ne peut pas être préparé (`plan_screens.dart:111-131`).
- Création sans profil : le texte dit « Réglages › Profil » sans bouton (`plan_screens.dart:462`).
- « Programme terminé » : bandeau sans action (`program_start.dart:436-440`).
- « ÉVOLUTION » sans profil : pas de bouton (`evolution_widgets.dart:477-486`), alors que « MON PROGRAMME » en propose un.
- « Créer mon programme » désactivé sans explication (`program_explainer.dart:193`, `program_screens.dart:264`).

**Chemins écrits en texte, sans lien, parfois faux**
- « Réglages › Mon programme › Revenir… » (`plan_screens.dart:46-47`). Le vrai chemin passe par la section « Programme ».
- « Réglages › Profil » (`program_explainer.dart:79, 84`).
- « Réglages › Profil › Compléter mon profil » (`profile_completion.dart:68`).
- « …dans Références » (`program_start.dart:319`).

**Retour ambigu**
- La pastille de niveau, et « Ma progression » dans le dialogue ou la page de récompense, referment toutes les pages ouvertes et basculent sur Stats (`stats_navigation.dart:24`). Pour revenir, il faut repasser par l'onglet Programme.
- La création tient en une seule page à quatre titres, et le retour système est détourné vers l'étape précédente.
- Les feuilles de résumé s'empilent les unes sur les autres (`estimate_view.dart:37`).

**Pages et feuilles sans titre**
- L'onglet Programme lui-même : pas de titre de page.
- Feuilles des variantes et du résultat d'une action (`plan_sheets.dart:128, 358`).
- Feuille de confirmation pour quitter la création (`plan_screens.dart:245`).

**Autres**
- Arsenal est une page d'index à deux entrées : un appui de plus pour toute consultation.
- Aucun lien entre une fiche et l'Anatomie, ni dans l'autre sens.

---

#### 4. Comptes (périmètre, hors build dev)

- **Pages : 16.** P-START, Compléter mon profil, TESTS GUIDÉS, TEST GUIDÉ, ÉVOLUTION, MON PROGRAMME, MA SAISON, Jour J, OÙ J'EN SUIS, création (4 étapes), BLOC SUIVANT, PROFIL, FICHE EXERCICE, EXERCICES, ANATOMIE, GALERIE DE KOACH.
  - S'y ajoutent l'écran sans programme (variante de l'onglet) et 3 sorties non auditées : séance, historique de séance, page de récompense.
- **Feuilles du bas : 15.**
  - Accueil : 4 (F1, F2, résumé de repos, résumé de séance qui peut s'empiler).
  - Explication du programme : 1.
  - Changement d'évolution : 1.
  - Feuilles de Koach : 4 (2 × « Ton prochain bloc », quitter la création, « Remplacer ton programme ? »).
  - Création : 4 (variantes, ajout, résultat d'une action, réglage d'un exercice).
  - Arsenal : 1 (« Les flammes »).
- **Dialogues : 3.** Retour à l'origine (`program_screens.dart:531`), calendrier (`program_start.dart:120`), niveau supérieur (`rewards.dart:63`). Plus le sélecteur de fichier système.
- **Menus déroulants : 2.** « Filtres » d'EXERCICES et « Filtres » d'ANATOMIE. Aucun menu ⋮ dans les deux onglets. Hors périmètre : un ⋮ « Options de l'historique » (`session_history.dart:362`) et un ⋮ dans la séance.

---

#### 5. Recherche

Il n'existe **aucun champ de recherche** dans l'onglet Programme ni dans Réglages. On ne peut pas chercher un muscle ni un réglage : l'Anatomie n'a que des filtres.

Tous les champs ci-dessous, sauf celui de Stats, cherchent avec le même moteur (`searchExercises`, `exercise_screens.dart:145-168`, et `search.dart`) :
- sans tenir compte des majuscules ni des accents ;
- tous les mots doivent être trouvés ;
- avec des synonymes français/anglais et des débuts de mots.

Champs pris en compte, par ordre de poids (`content_pack.dart:478-493`) :
- nom (×3) ;
- discipline, catégorie et famille (×2) ;
- matériel et lieux (×1) ;
- alias, puis muscles **principaux et secondaires** (×0,5). Les stabilisateurs et les noms de groupes (« Dos », « Pectoraux ») ne sont pas pris en compte.

| Champ | Texte d'aide | Accès |
|---|---|---|
| Arsenal › Exercices (`exercise_screens.dart:205`) | « Nom, muscle, matériel, discipline… » | A+1. Le seul champ avec filtres |
| Feuille d'ajout de la création (`plan_sheets.dart:249`) | « Rechercher dans la base (1 039 exercices) », nombre écrit en dur | P+4 au moins (Mon programme, Créer, revue, Ajouter) |
| Préférences du profil (`athlete_profile_flow.dart:2122`) | « Chercher dans les 1 039 exercices » | Réglages › Profil › rubrique |
| Page « CHOISIR UN EXERCICE » (`athlete_profile_flow.dart:2880`) | « Chercher un exercice » | Dans le parcours de profil |
| Hors moteur : Stats › Historique (`stats_history.dart:38`) | « Rechercher dans l'historique » / « Séance ou note » | Cherche dans le texte des séances terminées |

À noter :
- Le paramètre `AnatomyScreen.initialGroup` (`anatomy_screen.dart:136`) n'est appelé nulle part : rien n'ouvre l'Anatomie sur un groupe précis.
- `program_origin.dart`, `alerts.dart` et `atlas.dart` n'ont aucune interface.
- `koach_home_card.dart` ne sert qu'à choisir la pose de Koach sur la carte du jour.

## Partie 3 — Séance et onglet Stats

Audit en lecture seule terminé, sans aucune modification du dépôt (`/home/claude/streetlift-apk`, main, b7996b3). Les chemins sont relatifs à `/home/claude/streetlift-apk/lib/`.

Les deux constats les plus importants :
- **Douleur en cours de séance :** l'entrée « Douleur ou malaise ? » ouvre une page d'information. Déclarer une douleur demande de revenir au Bilan du jour : 5 appuis.
- **Récompenses mal ordonnées (probable) :** sur une séance ouverte depuis l'accueil, l'écran de récompenses semble passer sous l'écran « Fin de séance ». C'est déduit de la lecture du code, à vérifier sur un appareil (détail en 3.f).

**Conventions de profondeur**
- **Pn** = n appuis depuis l'écran de séance (A) ou depuis l'onglet Stats déjà affiché (B).
- **PE** = la page d'un exercice. On y arrive en 1 appui (« C'est parti » / « Premier exercice »), en 2 appuis (« Exercices » puis ligne), ou en k glissements. Il n'y a plus de boutons Précédent / Suivant (`session_screen.dart:527`).

---

#### 1. Arbre des destinations

#### Onglets racine (`nav_bar.dart:30-35`, `main.dart:289,376-384`)
Pastille flottante à 4 entrées. Seule l'entrée active affiche son libellé, avec une infobulle `label` :
- « Arsenal » (index 0)
- « Stats » (index 1)
- « Programme » (index 2, onglet par défaut, `main.dart:289`)
- « Réglages » (index 3)

La pastille est masquée quand le clavier est ouvert (`main.dart:413`).

#### A. Séance — `SessionScreen` (page), ouverte par `home_screen.dart:56-58` (`openProgramDay`) ou par une correction (`session_history.dart:226`)

**Barre du haut** (`session_screen.dart:350-437`)
- Titre : `d.title` ou « Récupération » ; sous-titre « S{n} · J{j} » ou le nom du bloc.
- **⋮ menu déroulant**, infobulle « Options de séance » (`:369`), P1. Ses entrées, toutes en P2 :
  - « Consignes de séance » (`:401-405`, si `conduite` non vide) → **feuille** `:317-341`. Titre « Consignes de séance », texte de conduite, bouton « Fermer ».
  - « Bilan du jour » (`:406-410`, si `adaptOn`) → saut à la page 0 (`:374`).
  - « J'ai seulement… minutes » (`:414-417`, si `adaptOn`, semaine ≥ 1, pas un jour de repos) → **feuille** `adapt/health_check.dart:865-905`.
    - Titre « Combien de temps as-tu ? », texte « Koach raccourcit la séance en gardant l'essentiel. »
    - Puces « 20 min » à « 90 min » et « Le temps prévu ». Un choix ferme la feuille (P3) puis renvoie sur la page 0 (`:300`).
  - « Je m'entraîne ailleurs » (`:418-421`, mêmes conditions) → **feuille** `health_check.dart:909-956`.
    - Titre « Où t'entraînes-tu aujourd'hui ? »
    - Puces « En salle », « À la maison », « Dehors », « Le lieu prévu » (P3), puis retour sur la page 0 (`:314`).
  - « Douleur ou malaise ? » (`:423-426`, toujours) → **page** `SafetyScreen` (`wellbeing_screens.dart:39-131`), titre « SANTÉ ET SÉCURITÉ ».
    - Contenu en lecture seule : carte « Signal d'alerte », section « Douleur » (conseil + renvoi tiré des anciennes réponses L7, `:91-99`), « Situations particulières », avertissement.
    - Tuile « Récupération » → **page** `RecoveryScreen` « RÉCUPÉRATION » (`:116-124`, P3).
  - « Références (feuille Pilotage) » (`:427-430`, toujours) → **page** `PilotageScreen` « RÉFÉRENCES » (`pilotage_screen.dart`).
    - Champs « Poids de corps », sections « Force · 1RM de travail », « Endurance · répétitions », « Charges des accessoires ».
    - Boutons par ligne « C'est bien ma valeur » / « Je ne sais pas » (`:172-183`).
    - Icône « restaurer » (infobulle « Effacer toutes mes références », `:17-43`, P3) → **dialogue** « Effacer tes références ? » avec « Annuler » / « Effacer » (P4).
  - « Effacer l'historique » (`:431-434`, toujours, dernière entrée sans séparateur) → **dialogue** `:196-225` « Supprimer l'historique ? ».
    - Texte « … Action irréversible. », boutons « Annuler » / « Supprimer » (rouge, P3).
    - Ensuite : SnackBar « Historique de X supprimé. » et fermeture de la séance.

**Bandeau sous la barre** (`:443-486`)
- Repère « Bilan du jour » / « Exercice i / N » / « Enchaînement i / N » / « Bilan de séance ».
- Bouton « Exercices » (icône liste, `:466-476`, P1) → **feuille** `:243-289` titrée « Dans cette séance ».
  - Lignes « Bilan du jour » (si `koachPage`), « 1… N » (sous-titre « Exercices enchaînés » si groupe), « Bilan de séance » (P2).
- Points de progression (`:479`).

**Avis médical, au lancement** (`:166-169` → `adapt/clearance.dart:38-89`)
- **Dialogue bloquant** (`barrierDismissible:false`, `PopScope canPop:false`) titré « Avis médical d'abord ».
- Texte du bloc, puis « Tu as eu cet avis ? », boutons « Pas encore » / « J'ai eu l'avis d'un médecin ou d'un kiné ».
- Condition : séance du moteur, non commencée, avis demandé et non confirmé. Profondeur P0 (s'impose).

**Page 0 « Bilan du jour »** (si `adaptOn`) — `HealthCheckPage` (`health_check.dart:50-472`)
- Carte d'évolution (`plan/evolution_widgets.dart:319-364`) : « Ce qui change dans cette séance : … ».
  - Bouton « Voir le changement » (ou un bouton par type) → **feuille d'évolution** (`:185-256`, P1).
  - Contenu : bulle de Koach avec « Pourquoi ? » ↔ « Compris » sur place, actions « Compris » / « Annuler » (`:146,158`), section « Ce qui change (n) » avec des volets dépliants « Pourquoi ? » (P2).
- Carte d'avis médical (`clearance.dart:93-137`), visible après « Pas encore » : « Avis médical pas encore confirmé », bouton « J'ai l'avis » (P1).
- Carte de douleur (`health_check.dart:158-218`) : « Arrêt pour douleur » / « Reprise graduée ». Information seule.
- Avant réponse (`:220-268`) :
  - Bulle « Comment tu te sens ? » avec « Pourquoi ? » sur place (`koach_bubble.dart:210-214`).
  - 5 tuiles « Pas bien », « Bof », « Correct », « Bien », « En forme » (`adapt_texts.dart:590-596`), P1.
  - « Passer » (`:261-267`).
  - Une réponse basse ouvre la **page** `HealthDetailScreen` (voir plus bas).
- Après réponse (`:270-348`) :
  - Carte d'ajustement (`:353-471`), selon l'état : « C'est parti », « Annuler », « Rétablir l'ajustement », « Accepter », « Garder ma séance », « Accepter l'ajustement ».
  - « Pourquoi ? » (`:455-463`) → **feuille Koach** « Pourquoi ? » avec « OK » (P1).
  - Carte de renvoi vers un professionnel, si besoin (`:278-291`).
  - Carte « Bilan du jour » avec lignes de résumé, « Refaire le bilan » (`:318-323`) et « Préciser (douleur, temps…) » (`:324-329`) → **page** `HealthDetailScreen` (P1).
  - « Premier exercice » (`:335-345`, si aucun ajustement).
- **Page** `HealthDetailScreen` « Bilan du jour » (`:564-861`) :
  - Puces à 5 niveaux pour « Sommeil », « Énergie », « Humeur », « Courbatures », « Stress », « Motivation », « Alimentation », « Hydratation ».
  - Section « Douleur » : puce « Aucune douleur », carte du corps touchable, puces de zones.
    - Une zone ouvre une **feuille de douleur** (`:627-683`, P2) : nom de la zone, puces de côté, curseur « Douleur aujourd'hui : n/10 », bouton « Enregistrer » (P3).
    - Liste des zones déclarées, chacune avec une croix « Retirer ».
  - « Temps disponible aujourd'hui » : puces 20 à 90 min.
  - « Valider mon bilan » / « Passer ».

**Page exercice** (`SessionExercisePage`, `:579-2075`)
- Carte « ENCHAÎNEMENT » (`:2537-2791`, si groupe) : bouton « Lancer l'EMOM » / « Lancer l'AMRAP » / « Lancer les intervalles » / « Lancer le chrono » / « Récupération entre deux tours ».
  - « Résultat du groupe » : compteurs « Tours faits (sur N) » ou « Tours complets », « Répétitions du tour entamé », champ « Temps (min:s) ».
- Par exercice (`_block`, `:1431-1984`) :
  - Pastille « ENCHAÎNÉ · A/B ».
  - Icône ⓘ, infobulle « Consignes de l'exercice » (`:1553-1567`, PE+1) → **feuille** « Consignes · {nom} » (`:1344-1386`) : consigne, « Pourquoi : … », estimation, « Fermer ».
  - Charge et séries. Appui invisible sur « à renseigner » / « ? » → page « Références » (`:737-760`, infobulle « Référence non renseignée : … Touche pour ouvrir Références. »).
  - Pastilles de type, intensité, tempo, « Repos … », « Repos final … » ; note de prudence (`:1631`).
  - Panneau du coach (`:1027-1181`) : libellés de technique en majuscules, lignes de douleur avec icône de bouclier, « Note du coach : touche pour la lire ».
    - Appui → **feuille Koach** (`:1102`, PE+1) si au moins une note ou deux lignes.
    - Bouton « Mini-repos n s » (`:1169-1179`).
  - Notes du moteur (`:1185-1243`) → **feuille Koach** (`:1211`, PE+1).
  - Ligne « S{n} · … » avec « Reprendre » (`:1687-1722`).
  - Boutons de chrono de mode (`:1727-1766`, `:2001-2040`) : « Lancer r× w s / r s », « Lancer EMOM n min », « Lancer n min », « Intra-cluster n s », « Lancer EMOM r × i s », « Lancer AMRAP n min », « Chrono n s ».
  - Lignes de série (`_SetRow`, `:2170-2475`) :
    - Champs kg / reps / s / m / m/s.
    - Icône sablier ou chrono, infobulle « Compte à rebours » / « Chrono montant » (`:2360-2379`).
    - Coche, infobulle « Valider la série N » / « Annuler la série N » (`:2405-2426`).
    - Appui long sur le numéro (`:2326-2343`).
    - Erreur sous la ligne (`:2430`).
  - Série validée et fermée : ligne résumée (`adapt/flame_track.dart:413-532`), appui = rouvrir (PE+1).
  - Série validée et ouverte : ligne des flammes (`flame_track.dart:96-409`, appui ou glissement).
    - « Je ne sais pas » (`:362-386`).
    - **Menu déroulant ⋯**, infobulle « Plus d'options pour la série N » (`:193-209`) avec une seule entrée : « Écarter la série (incident) » / « Réintégrer la série » (PE+2, ou PE+3 si la série était résumée).
  - Mini-séries (`:2798-2992`) : −, +, « Noter », « Retirer la dernière mini-série ».
  - Proposition du moteur (`:964-1021`) : « Je te propose pour la série suivante : … », boutons « Accepter » / « Garder ».
  - Rangée du bas (`:1878-1957`) :
    - − « Retirer une série »
    - + « Ajouter une série »
    - « n séries »
    - icône note : « Ajouter une note » / « Afficher la note » / « Masquer la note », qui ouvre le champ « Notes » (« Sensations, ajustements… »)
    - **menu déroulant** « Colonnes » (`:1931-1954`) : « Charge (kg) », « Vitesse (m/s) ».
- SnackBars de la page :
  - « Enchaîne : X » (`:886-897`)
  - « Koach : … » avec « Annuler » (`:928-959`)
  - « RECORD · X · … » (`:1258-1280`)

**Barre de chrono** (`:2996-3119`, visible quand un chrono tourne)
- Libellés de phase : REPOS, PRÊT, EFFORT i/n, MINUTE i/n, TENUE, MAX, INTRA, DURÉE, AMRAP, CHRONO, TERMINÉ (`timers.dart`).
- Boutons « −15 », « +15 », arrêt / fermeture (infobulle « Arrêter » / « Fermer »).

**Dernière page « Bilan de séance »** (`_FinishPage`, `:3123-3311`)
- « n / N séries validées », « Objectif de séance : ≥ x % … », « +100 XP de base + bonus éventuels ».
- « Terminer la séance » (`:3280-3304`).
  - Échec d'écriture : SnackBar `:3172-3180` et bouton « Réessayer l'enregistrement » (`:3265-3278`).
  - Variante « Repasser en « à faire » » (`:3292`), sans confirmation.
- Ensuite, séance du moteur → **page** `AdaptSummaryScreen` « Fin de séance » (`adapt/adapt_summary_screen.dart:85`) :
  - bulle avec « Pourquoi ? » sur place, sections « Calibrage », « Ce qui a progressé », « La prochaine fois », « Tes séries », renvoi ;
  - bouton « Terminer » (`:162-167`).
- Puis `checkLevelUp` (`rewards.dart:29-98`) :
  - **page plein écran** `RewardScreen` (titre « Séance validée », boutons « Continuer » / « Ma progression », `:298-317`) ;
  - ou SnackBar « +n XP · niveau … » si les célébrations sont coupées ;
  - ou **dialogue** « Niveau N » avec « Ma progression » / « Continuer ».
  - « Ma progression » fait `popUntil` jusqu'à la racine puis ouvre Stats › Parcours (`progression_screen.dart:5-10`).

**Jour de repos** (`_RestDay`, `:3313-3367`)
- « REPOS COMPLET », texte de conduite ou « … GtG suspendu. Note ta HRV et ta FC de repos. »
- Bouton « Marquer comme fait » / « Marqué fait ».
- Le menu ⋮ reste proposé.

#### B. Onglet Stats — `StatsScreen` (`stats_screen.dart`)
- En-tête « STATS ». Icône ⓘ, infobulle « Comprendre les XP » (`:92-96`, P1) → **feuille** « Comment progresser » (`stats_progression.dart:609-647`), bouton « Compris ».
- Onglets internes (`:120-131`), P1 : « Aperçu », « Parcours », « Performances », « Historique ».

**Aperçu** (`stats_overview.dart`)
- Carte « TON PERSONNAGE » (`:30`) → **feuille** « Ta feuille de personnage » (`game_widgets.dart:529-626`) : niveau, « Attributs », « Tes rangs », « Origine de tes XP ».
- « Objectif et série » :
  - « Objectif de la semaine » (`game_widgets.dart:632`) → **feuille** « Objectif de jours actifs par semaine » (`:694-721`), puces « Adaptatif », « 2 jours » à « 6 jours » ; un choix ferme la feuille (P2).
  - « n semaines de suite » (`:793`) → **feuille** « Ta série et tes boucliers » (`:855`).
- « Quêtes » :
  - « Quête principale · S J » (`:880-964`), **non touchable**.
  - Carte de défi (`stats_progression.dart:145`), **non touchable**.
- « Campagne » :
  - action « Parcours » → onglet Parcours ;
  - bande de chapitres → **feuille** du chapitre (`game_widgets.dart:1132`) ;
  - « BOSS · X » → **feuille** « Boss · X » (`:1228`) ;
  - « Saison i · X » → **feuille** « Saisons » (`:1315`).
- « Toi contre toi-même » (`:1390`), non touchable.
- « Cette semaine » : 4 indicateurs non touchables.
- Tuile « Défis de la semaine » / « Défis validés » (`stats_overview.dart:82-88`) → **feuille** « Défis de la semaine » (`stats_progression.dart:207`).
- Tuile « Arbre de progression » → onglet Parcours.
- « Ton rythme » : carte « Une habitude qui se construit » → **feuille** « Ton activité sur 8 semaines » (`stats_overview.dart:148`).
- « Depuis tes débuts » : 4 indicateurs.
- Tuile « Performances et références » → onglet Performances.
- Tuile « Tout ton historique » → onglet Historique.

**Parcours** (`stats_progression.dart:220-421`)
- Carte « NIV. n · rang » (`:303`) → même feuille de personnage.
- Bascule « Pratique » / « Rythme » (`:352-362`).
- Paliers → **feuille** du badge (`:546`). Profondeur P2, ou P3 côté Rythme.
- Tuile « Campagne, boss et saisons » (`:394-399`) → **feuille** « Campagne » (`game_widgets.dart:1355`), qui contient chapitres, carte boss, liste des boss et carte saison. Chacun ouvre une feuille empilée par-dessus (P3).
- Tuile « Tes titres » (`:400-406`) → **feuille** « Tes titres » (`game_widgets.dart:1461`) : « Afficher mon rang », titres obtenus ; un choix ferme la feuille (P3).
- Tuile « Défis de la semaine » (`:407-413`) → même feuille que dans l'Aperçu.

**Performances** (`stats_performance.dart`)
- Tuile « Modifier mes références » (`:28-36`) → **page** « RÉFÉRENCES » (P2), puis icône d'effacement (P3) et **dialogue** de confirmation (P4).
- Carte « Programme · x / y journées », « Force », « Endurance » (« Non renseigné · à compléter dans Références… », `:147`, sans lien), « Muscles sollicités » (carte non touchable).

**Historique** (`stats_history.dart`)
- Champ « Rechercher dans l'historique » (« Séance ou note »), croix « Effacer la recherche », « n résultats ».
- Une ligne de séance (`:100`) → **page** `SessionHistoryScreen` (P2), sous-titre « … Lecture seule » avec un cadenas :
  - **Menu ⋮** « Options de l'historique » (`session_history.dart:362`, P3) :
    - « Corriger les saisies » → **dialogue** « Corriger cette séance ? » (Annuler / Corriger, P5) → remplace la page par `SessionScreen` (arbre A).
    - « Supprimer de l'historique » → **dialogue** « Supprimer de l'historique ? » (P5) → fermeture et SnackBar « Séance supprimée de l'historique. » avec « Annuler ».
  - « Exercices » → **feuille** sans titre (`:161`).
  - Icône ⓘ → « Consignes · X ».
  - Page finale « SÉANCE EFFECTUÉE » avec la carte « Validée par erreur ? » et « Corriger les saisies » (`:316-338`).

**Uniquement en build dev :** la tuile « Build de développement » (`settings_screen.dart:419-426`) et le panneau de test ouvert par 5 appuis sur le logo de l'accueil. Rien dans la séance ni dans Stats.

---

#### 2. Doublons et chevauchements

| Fonction | Endroits (libellés) |
|---|---|
| Références | « Références (feuille Pilotage) » (`session_screen.dart:429`) ; appui caché sur « à renseigner » (`:752`) ; « Modifier mes références » (`stats_performance.dart:30`) ; « Références » (`settings_screen.dart:364`) ; « références Pilotage » (`game_widgets.dart:589`) |
| Bilan du jour | page 0 ; ⋮ « Bilan du jour » (`:409`) ; feuille Exercices (`:264`) ; carte « Bilan du jour » (`health_check.dart:298`) ; page « Bilan du jour » (`:711`) |
| Temps disponible | ⋮ « J'ai seulement… minutes » (feuille) et « Temps disponible aujourd'hui » (`health_check.dart:823`) : même donnée, deux formes |
| Santé et sécurité | « Douleur ou malaise ? » (`:425`) et « Santé et sécurité » (`settings_screen.dart:433`) ; « Récupération » sur `wellbeing_screens.dart:118` et `settings_screen.dart:443` |
| Douleur et renvoi | carte d'arrêt, lignes de bouclier par exercice, carte de renvoi, renvoi en fin de séance, renvoi de SafetyScreen calculé depuis les anciennes réponses L7 (`safety_store.dart:43`) : sources différentes |
| Rappel d'avis médical | dialogue (`clearance.dart:44`), carte (`:93`), ligne sous chaque exercice (`session_screen.dart:1075`) |
| Historique d'une séance | accueil (`home_screen.dart:57`) et Stats › Historique (`stats_history.dart:104`) : même page |
| Suppression d'une séance | « Effacer l'historique » (irréversible, `session_screen.dart:433`) et « Supprimer de l'historique » (annulable, `session_history.dart:373`) |
| Correction | ⋮ « Corriger les saisies » et carte « Corriger les saisies » (`session_history.dart:369,334`) |
| Feuille de personnage | carte de l'Aperçu (`stats_overview.dart:30`) et carte du Parcours (`stats_progression.dart:304`) |
| Défis de la semaine | carte Quêtes, tuile de l'Aperçu (`stats_overview.dart:82`), tuile du Parcours (`stats_progression.dart:407`) |
| Campagne, boss, saisons | cartes de l'Aperçu et feuille « Campagne » qui reprend les mêmes cartes |
| Objectif hebdomadaire | feuille Stats (0, 2-6) et réglage pas à pas (0-6, `settings_screen.dart:183-196`), qui autorise 1 |
| Explication des XP | « Comment progresser », « Origine de tes XP », écran de fin de séance |
| Colonne vitesse | menu « Colonnes » (par exercice) et réglage global (`settings_screen.dart:109`) |
| Ma progression | `RewardScreen:316`, dialogue de niveau (`:87`), pastille de niveau de l'accueil (`levelup.dart:27`) |
| Liste des exercices | feuille de la séance (titrée, numéros en pastille) et feuille de l'historique (sans titre, numéros en texte) |

**Ce qui n'existe nulle part :**
- **Fiche d'exercice** : jamais accessible depuis la séance. L'icône ⓘ n'ouvre que les consignes. On ne l'atteint que par Arsenal ou par « Fiche et démonstration » (`plan_screens.dart:949`).
- **Remplacement d'exercice** : pas d'action dans la séance (seulement indirectement via le lieu). Il existe dans Programme (`plan_screens.dart:319`).
- **Records** : la tuile promet des « records » (`stats_overview.dart:128`) mais il n'y a aucune vue des records. `RecordsScreen` (`records_screen.dart:5`) n'est référencé nulle part.
- **Réglages de chrono** : uniquement dans Réglages › Chronomètres, pas depuis la barre de chrono.

---

#### 3. Incohérences

**a. Un même type de choix sous des formes différentes**
- Choix unique :
  - feuilles à puces qui se ferment au choix (minutes, lieu, objectif, titres) ;
  - puces à bascule sur page (détail du bilan) ;
  - tuiles (forme du jour) ;
  - boutons encadrés en guise de segments (Pratique / Rythme) ;
  - menu à cases cochées (Colonnes) ;
  - réglage pas à pas (objectif dans Réglages).
- « Pourquoi ? » : dépliant sur place (`koach_bubble.dart:214`), feuille (`health_check.dart:457`), volet dépliant (`evolution_widgets.dart:236`).
- Même composant de tuile pour trois effets : changer d'onglet (« Arbre de progression »…), ouvrir une feuille (« Défis… »), ouvrir une page (« Modifier mes références »).
- Consignes dispersées sur 4 surfaces : menu ⋮, icône ⓘ, feuille Koach, ligne de prudence.
- Feuilles empilées sur feuilles (Campagne › chapitre / boss / saisons).

**b. Actions destructrices mêlées aux autres**
- « Effacer l'historique » est la dernière entrée du ⋮, sans séparateur, à côté de « Références » (`session_screen.dart:431`).
- « Effacer » (références) est un bouton plein de couleur normale, pas rouge (`pilotage_screen.dart:33`).
- « Repasser en « à faire » » retire de l'XP sans confirmation (`session_screen.dart:3298`). Cet état est en pratique quasi inatteignable.
- « Retirer une série » ne fait rien, sans message, si la dernière série est validée (`store.dart:229`).
- Verbes incohérents : menu « Effacer » / dialogue « Supprimer » ; « Lecture seule » affiché avec un menu qui modifie (`session_history.dart:351,362`).

**c. Libellés jargonneux ou internes**
- « Références (feuille Pilotage) », « Intra-cluster », « Clusters · intra », « Myo-reps », « Act. / M1 / R1 ».
- « Dur · RIR 2 » (le RIR revient après la suppression de la colonne).
- « GtG », « HRV », « FC », « deload », « Chipper », « PdC », « kg·rép. externes connus », « Séries / passages », « Prescrit ce jour-là ».
- « Écarter la série (incident) », « prestige ».
- « Colonnes, effort et pré-remplissage » : « effort » est obsolète (`settings_screen.dart`).
- « Vibration en fin de chrono » commande aussi le retour haptique à la validation et pour les records (`session_screen.dart:843,874`).
- Bilans : « Bilan du jour » (début), « Bilan de séance » (fin), « Fin de séance », « Séance validée ».
- « Comprendre les XP » ouvre « Comment progresser ».
- « Toi contre toi-même » est répété (section + titre de carte).
- « Entraînements » / « Séances » pour la même mesure.

**d. Fonctions enfouies (plus de 3 appuis, ou geste caché)**
- Déclarer une douleur en cours de séance : ⋮ › Bilan du jour › Préciser › zone › Enregistrer = **5 appuis**.
- Corriger ou supprimer une séance depuis Stats : **5 appuis**.
- Effacer les références : **4 appuis**.
- Écarter une série résumée : 3 appuis.
- Saisons depuis le Parcours : 3 appuis. Titre affiché : 3 appuis.
- Gestes ou affordances cachés : appui long sur le numéro de série (redondant), appui sur « à renseigner » (rien de visible), panneau du coach touchable seulement dans certains cas.

**e. Culs-de-sac**
- « Douleur ou malaise ? » : page d'information, aucune action.
- La quête principale n'ouvre pas la séance.
- La carte de défi de l'Aperçu n'est pas touchable alors que la tuile juste en dessous l'est.
- « à compléter dans Références » : pas de lien.
- Textes de quête renvoyant à une « séance personnelle depuis l'Arsenal », supprimée en G2 (`game_widgets.dart:897-902`). Le commentaire `session_screen.dart:3184` cite lui aussi Arsenal.
- Records promis mais introuvables.

**f. Retours ambigus**
- Choisir un temps ou un lieu renvoie sur la page 0 au lieu de l'exercice en cours (`session_screen.dart:300,314`).
- « Ma progression » vide toute la pile et quitte l'onglet Programme.
- **Probable, d'après la lecture du code** : depuis l'accueil, `openProgramDay` appelle `checkLevelUp` dès la fermeture de la séance (`home_screen.dart:68`), avant que `_finish` attende la fin de la transition (`session_screen.dart:3190`).
  - Conséquence : l'écran de récompenses est poussé d'abord (sans attente, son décompte part tout de suite), et « Fin de séance » s'affiche par-dessus.
  - Le second `checkLevelUp` ne trouve plus rien. À vérifier sur un appareil.
- Dans le détail du bilan, le retour système vaut « Passer », et « Passer » garde quand même la réponse basse.
- « Pas encore » : la question d'avis médical revient à chaque lancement.

---

#### 4. Comptes

| | Pages | Feuilles | Dialogues | Menus déroulants | SnackBars |
|---|---|---|---|---|---|
| A (séance) | 7 : Séance, Détail du bilan, Santé et sécurité, Récupération, Références, Fin de séance, Récompenses (+ pages internes : Bilan du jour, N exercices, Bilan de séance ; variante repos) | 10 apparitions, 8 composants (Exercices, Consignes de séance, Consignes · X, feuille Koach ×3, Minutes, Lieu, Douleur, Évolution) | 4 (Avis médical, Supprimer l'historique, Effacer tes références, Niveau N) | 3 (Options de séance, Colonnes, ⋯ série) | 6 |
| B (Stats) | onglet + 4 sous-onglets ; 2 pages poussées (Historique de séance, Références) + la séance en correction (comptée en A) | 14 (11 feuilles Stats + « Comment progresser » + Exercices et Consignes de l'historique) | 3 (Corriger, Supprimer de l'historique, Effacer tes références) | 1 (Options de l'historique) ; filtres : 1 recherche, 1 bascule | 1 |

**Code mort :** `StatsLevelCard` et `showStatsLevel` (`stats_progression.dart:10,94`), `RecordsScreen` (`records_screen.dart:5`). `ProgressionScreen` ne sert que si la navigation Stats n'est pas branchée.
