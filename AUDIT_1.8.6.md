# Livraison 1.8.6+38 — Programme / accueil

> Rectificatif 1.8.7 : l’analyse GitHub du ZIP 1.8.6 a échoué sur une règle de style dans `test/level_fill_test.dart`. La mention « aucun problème » de ce rapport ne suffisait donc pas à valider l’archive livrée. Le blocage a été reproduit et corrigé ; voir **AUDIT_1.8.7.md**.

Date : 21 septembre 2026. Base : ZIP 1.8.5+37 fourni. Validation utilisateur : « On valide », après retrait des légendes des silhouettes et du contour / dégradé du niveau.

## Comportement livré

Le niveau réel est représenté par deux aplats dans les mêmes chiffres ; un clip rectangulaire détermine la proportion d'XP colorée. Le niveau ouvre toujours Ma progression. Le logo monochrome passe à droite et le trajet final de l'ouverture rejoint sa nouvelle position.

Le sélecteur affiche une portion pleine, le numéro de semaine et les points restants. Un appui court ouvre la fiche, un glissement change la sélection. Les touches fléchées, Début / Fin et Entrée / Espace ainsi que les actions du lecteur d'écran sont disponibles. Les gestes horizontaux du contenu changent d'une semaine ; les bornes sont 1 et 40. La liste complète reste accessible depuis la fiche semaine.

La séance du jour est développée avec les statistiques réelles et les deux vues musculaires agrandies, sans titres sous les silhouettes. Les autres cartes sont compactes. Les volumes partiels et tonnages connus restent signalés. Un appui ouvre la séance, ou son historique en lecture seule si elle est terminée. Un appui long ouvre le résumé existant.

Les cinq icônes de navigation sont flottantes, avec Programme plus grand. Les noms restent disponibles aux lecteurs d'écran et dans les infobulles. Huit bandes de BackdropFilter, d'intensité croissante, floutent le contenu réel sous la navigation. Une réserve de défilement permet de remonter les derniers éléments au-dessus des boutons. La navigation se masque lorsque le clavier occupe le bas de l'écran. Les animations de sélection respectent la réduction des mouvements.

## Vérifications exécutées

- Flutter 3.29.3, Dart 3.7.2 ; dépendances résolues hors ligne avec le fichier verrouillé inchangé.
- Analyse Flutter : aucun problème.
- Suite Flutter complète : **130 tests réussis**.
- Outils Python : **4 tests réussis**.
- Vérification du projet avec contrôle de signature : 40 semaines, 280 jours, 1 954 exercices du programme et 172 exercices de la base.
- Test du rendu des chiffres : aplats exacts à 0 %, 60 %, 99 % et 100 % ; absence de barre d'XP séparée.
- Gestes : appui court, glissement sans ouverture intempestive, bornes, balayage horizontal, clavier, sélection conservée entre les cinq onglets et changements de thème.
- Séances : ouverture correcte, historique sans mutation des saisies, résumé et récupération.
- Captures issues du moteur Flutter contrôlées en clair / sombre à 390 × 844 px et à 320 × 720 px avec texte à 130 %. Niveau 1 sans XP sur ces captures, faute d'historique dans le jeu de données de contrôle.
- Zone de défilement sous la navigation, accès au dernier jour après défilement et masquage de la navigation pour le clavier vérifiés.

Les résultats actuels et les captures se trouvent dans **validation/1.8.6/**. Les rapports 1.8.5 et antérieurs sont conservés comme historique.

## Périmètre et livraison

Version des sources : **1.8.6+38**. L'archive conserve son nom **streetlift_tracker_v33.zip** et son dossier racine **streetlift_tracker/**, attendus par le workflow fourni. Le workflow, l'identifiant Android, la clé de signature, le fichier de dépendances verrouillées et les données du programme restent identiques à la base. La checklist est incluse dans **REFONTE_UI.md**.

Seul l'écran 3 est validé dans la refonte en cours. La navigation commune et la position finale du logo d'ouverture sont les adaptations partagées nécessaires.

La compilation APK n'a pas été exécutée ici : aucun SDK Android n'est installé dans cet environnement. Le workflow GitHub existant compile et signe l'APK ; l'installation et le comportement sur téléphone restent à confirmer après ce run.
