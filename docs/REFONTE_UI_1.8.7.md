# Kalis Track — Checklist de refonte UI

Dernière mise à jour : 21 septembre 2026.

Base examinée : streetlift_tracker_v33.zip — application 1.8.5+37.

Version livrée : **1.8.7+39** — **1 écran sur 15 validé et livré**.

## Fonctionnement convenu

- Le travail avance écran par écran.
- Pour chaque écran : consignes et croquis → prototype → ajustements → validation explicite de l’utilisateur → intégration → vérification → livraison d’un ZIP mis à jour.
- La checklist est actualisée à chaque validation et à chaque livraison. Elle sera incluse dans les ZIP successifs.
- L’ancien fonctionnement consistant à attendre toutes les demandes avant de modifier l’application est remplacé par ce fonctionnement progressif.
- Une case « Validé » correspond à une validation explicite du nouvel écran. Une case « Livré » correspond à une intégration vérifiée effectivement livrée.
- Les anciennes validations de la version 1.8.5 ne valent pas validation des nouveaux prototypes de cette refonte.

## Écrans

| Nº | Écran | Statut | Validé | Livré |
|---|---|---|---|---|
| 1 | Arsenal | À définir | ☐ | ☐ |
| 2 | Suivi | À définir | ☐ | ☐ |
| 3 | Programme / accueil | Livré — 1.8.7+39 | ☑ | ☑ |
| 4 | Pilotage | À définir | ☐ | ☐ |
| 5 | Réglages | À définir | ☐ | ☐ |
| 6 | Exécution d’une séance | À définir | ☐ | ☐ |
| 7 | Historique d’une séance | À définir | ☐ | ☐ |
| 8 | Création / modification d’une séance personnelle | À définir | ☐ | ☐ |
| 9 | Catalogue WOD | À définir | ☐ | ☐ |
| 10 | Aperçu WOD | À définir | ☐ | ☐ |
| 11 | Création / modification WOD | À définir | ☐ | ☐ |
| 12 | Exécution WOD et résultats | À définir | ☐ | ☐ |
| 13 | Ma progression : Parcours et Badges | À définir | ☐ | ☐ |
| 14 | Lancement Android et ouverture animée | À définir | ☐ | ☐ |
| 15 | Problème au démarrage | À définir | ☐ | ☐ |

## Écran 3 — Programme / accueil

Source de la demande : croquis 1789961905513.jpeg.

### Demandes en vigueur : croquis et corrections

- [x] Niveau actuel en haut à gauche.
- [x] Le nombre du niveau lui-même représente la progression des XP : chiffres pleins, sans contour ni dégradé ; la couleur active avance proportionnellement comme une barre de progression, avec une séparation nette.
- [x] Logo existant en haut à droite, en couleur uniforme.
- [x] Sélecteur de semaines sous l’en-tête, présenté comme une progression avec une portion parcourue, un repère Sx et des points pour les autres semaines.
- [x] Appui court sur la barre / le repère : détails de la semaine sélectionnée.
- [x] Glissement du curseur : changement de semaine.
- [x] Glissement horizontal du contenu : semaine précédente / suivante.
- [x] Carte ordinaire compacte et arrondie : statut, Jx, titre.
- [x] Carte de la séance du jour développée : même ligne d’en-tête, statistiques à gauche et muscles sollicités de face et de dos à droite.
- [x] Aucun libellé visible « AVANT » ou « ARRIÈRE » sous les silhouettes.
- [x] Barre de navigation flottante à cinq icônes.
- [x] Icône Programme centrale légèrement plus grande que les autres.
- [x] Onglet sélectionné en surbrillance ; autres icônes grisées.
- [x] Fond des icônes plein ; flou progressif du contenu qui défile derrière la navigation.

### Choix validés sur le prototype révisé

- Présentation sombre et titres des séances en majuscules.
- Chiffres du niveau pleins : base grise et couleur active de gauche à droite selon les XP, à bord net. Le contour et le dégradé du premier prototype sont retirés à la demande de l’utilisateur.
- Chiffre du niveau sans barre d’XP séparée.
- Logo monochrome clair ; accent bleu pour le niveau, le curseur et la sélection de navigation.
- Cercles de navigation compacts, pictogrammes relativement grands, sans libellés visibles sous les icônes.
- Les cartes autres que celle du jour restent compactes, y compris dans une autre semaine.
- Le sélecteur prend la place de l’accès calendrier de l’ancien en-tête ; le logo occupe le côté droit.
- Le prototype utilise des données de démonstration : niveau 10 à 60 %, semaine 10 et journée J4 développée. Les titres, volumes et durées ne constituent pas une modification du programme réel.
- Les clics sur les icônes de navigation illustrent leur état sélectionné ; ils ne représentent pas une refonte des quatre autres écrans.

### Comportements existants à conserver lors de l’intégration

- Accès à Ma progression depuis le niveau.
- Appui sur une carte : séance à exécuter, ou historique en lecture seule si elle est terminée.
- Appui long sur une carte : résumé de la séance / de la récupération.
- Données, calculs, progression, historique et sauvegardes existants.
- Préservation de la semaine sélectionnée lors d’un changement d’onglet.
- Adaptation aux thèmes clair / sombre / système, aux petits écrans, au texte agrandi et à la réduction des animations.
- Zones tactiles et interactions accessibles.

### Vérifications de l’intégration 1.8.6

- [x] Validation explicite du prototype reçue.
- [x] Code Flutter intégré.
- [x] Affichage d’un niveau à 0 %, partiellement rempli et proche du niveau suivant.
- [x] Chiffres pleins, sans contour ni dégradé ; progression par changement de couleur à bord net.
- [x] Aucun libellé « AVANT » ou « ARRIÈRE » affiché.
- [x] Appui court distingué du glissement du sélecteur.
- [x] Navigation entre semaines par curseur et geste horizontal.
- [x] Bornes de navigation : semaines 1 et 40.
- [x] Carte du jour, autres jours, récupération, semaines passée / future.
- [x] Ouverture des séances et de l’historique.
- [x] Défilement sous la navigation et flou progressif.
- [x] Vérification de la navigation partagée dans les cinq onglets.
- [x] Vérification clair / sombre, taille d’écran et taille du texte.
- [x] Version et checklist actualisées.
- [x] ZIP vérifié et livré.

## Interfaces secondaires à suivre avec chaque écran

| Écran / zone | Panneaux, menus ou variantes associés |
|---|---|
| Programme | Sélection et détail des semaines ; résumés de séances et de récupération ; estimations de durée et de volume. |
| Arsenal | Actions des séances ; duplication ; confirmation de suppression ; séance déjà terminée ; actions Aperçu / Lancer des WOD. |
| Séance | Exercices simples et enchaînés ; bilan ; récupération ; choix d’exercice ; consignes ; colonnes ; notes ; suppression d’historique ; chronomètres. |
| Historique | Pages d’exercices, consignes disponibles, bilan et séance sans séries ; lecture seule. |
| Éditeur de séance | Recherche / création d’exercice ; filtres musculaires ; paramètres ; huit modes d’exécution ; réorganisation et état vide. |
| Catalogue WOD | Recherche ; filtres par accès, format, difficulté, durée, matériel et source ; aucun résultat. |
| Aperçu WOD | Verrouillé, abordable, débloqué, crédits insuffisants ; détail des mouvements ; retour au chrono. |
| Éditeur WOD | Cinq formats et leurs champs conditionnels ; validation des saisies. |
| Exécution WOD | Chrono arrêté, en cours, en pause, repos, fin et limite ; score temps ou rounds/reps ; quitter ; supprimer un résultat ; historique vide. |
| Progression | Parcours ; badges ; explication des XP ; passage de niveau ; objectifs et récompenses. |
| Pilotage | Références numériques et confirmation de restauration. |
| Réglages | Thèmes ; séries ; chronos ; séance ; notifications et états d’autorisation ; heure ; options Android ; export ; import ; À propos. |
| Lancement / secours | Animation, attente de chargement, réduction des mouvements, erreur, détails et copies de récupération. |
| Commun | En-têtes ; navigation ; cartes ; boutons ; formulaires ; muscles ; confirmations ; messages de réussite / d’erreur ; états vides. |

## Journal des validations et livraisons

| Date | Étape | Résultat |
|---|---|---|
| 21/09/2026 | Changement de méthode | Livraison progressive après validation de chaque écran. |
| 21/09/2026 | Écran 3 — premier croquis | Demandes transcrites ; premier prototype proposé ; aucune validation de cet écran reçue à ce stade. |
| 21/09/2026 | Écran 3 — correction du prototype | Suppression des libellés AVANT / ARRIÈRE. Niveau en chiffres pleins, sans contour ni dégradé, avec progression de couleur à bord net. Validation globale de l’écran toujours attendue. |
| 21/09/2026 | Écran 3 — validation | Prototype corrigé validé explicitement ; intégration autorisée. |
| 21/09/2026 | Écran 3 — livraison 1.8.6+38 | Accueil intégré ; 130 tests Flutter et 4 tests Python réussis ; ZIP livré. Blocage de l’analyse GitHub signalé ensuite, corrigé en 1.8.7. |
| 21/09/2026 | Correctif 1.8.7+39 | Blocage GitHub reproduit puis corrigé : accolades du test de niveau. Analyse sans problème, 130 tests Flutter et 4 tests Python réussis sur une extraction propre du ZIP ; écran 3 toujours validé. |

Écran 3 validé explicitement (« On valide ») et livré. Les autres écrans attendent leurs consignes et leur validation.

La navigation partagée des cinq onglets et l’arrivée du logo d’ouverture sont adaptées au nouvel accueil. Cela ne vaut pas validation des écrans 1, 2, 4, 5 ou 14.

Contrôles visuels : thèmes clair et sombre, 390 × 844 px, 320 × 720 px avec texte à 130 %. Remplissage des chiffres testé à 0 %, 60 %, 99 % et 100 %. Workflow Android existant et données du programme conservés. La compilation APK et la vérification sur téléphone restent à exécuter via le workflow habituel.

Contrôle du correctif 1.8.7 : analyse et tests exécutés sur une archive reconstruite extraite à neuf ; code et configuration identiques dans le ZIP final. Voir AUDIT_1.8.7.md.
