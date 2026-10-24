# Audit et corrections — Kalis Track 1.5.0

Livraison préparée le 13 septembre 2026 à partir de `streetlift_tracker_v33.zip` et `build-apk.yml.txt` fournis. Les 19 fichiers Dart d'origine, les trois scripts Python, les assets et le workflow ont été examinés. L'archive livrée contient les sources corrigées et le projet Android complet.

## Principales corrections

| Zone | Problème constaté | Correction |
| --- | --- | --- |
| Classement WOD | Expression régulière `(?i)` invalide pour Dart ; exception avalée lors du classement | Drapeau `caseSensitive: false`, classement avant utilisation du catalogue |
| Atlas musculaire | Tentative de charger chaque groupe sur les deux faces, alors que plusieurs masques n'existent pas | Liste explicite des masques disponibles par face |
| Import | Les valeurs et les logs étaient modifiés avant validation de toute la sauvegarde | Construction et validation complètes avant tout remplacement ; formats non reconnus refusés |
| Persistance | Données réparties sur plusieurs clés, écrites sans attendre ; textes de série et notes sans déclenchement systématique de sauvegarde | Snapshot compact unique, écritures séquencées, autosauvegarde à la saisie, signalement d'un échec d'écriture |
| Compatibilité | Risque de perdre les anciennes données pendant une migration | Lecture des anciens formats et conservation des clés d'origine lors de la migration |
| Séances perso | Refaire un modèle réutilisait et écrasait son unique journal | Archivage de l'occurrence terminée avant de préparer une nouvelle séance |
| Identifiants | Identifiants de séance basés sur un timestamp tronqué ; collisions possibles | Identifiants complets et vérification des collisions ; identifiants d'exercice distincts même à création rapprochée |
| Suivi | Les séances perso augmentaient le numérateur de l'avancement du programme | Décompte limité aux jours réels du programme |
| Carte hebdomadaire | Exécution d'une autre semaine non comptée au bon moment ; dates futures comptées | Date de validation par série ; filtrage par semaine réelle et exclusion des dates futures |
| Chrono WOD | Fractions de seconde perdues pendant les pauses ; laps basés sur un affichage potentiellement périmé | Accumulation en millisecondes et lecture au moment du clic |
| Reprise d'EMOM | Rejeu de tous les bips d'intervalles manqués ; temps final dépassant la durée programmée | Rattrapage direct de la phase, un signal de transition au maximum, temps final borné |
| Scores | Temps mal formés acceptés, contrôleurs non libérés, risque de double ouverture du score | Formulaire validé, cycle de vie autonome, garde contre les ouvertures simultanées |
| Records | Résultat nul ou incomplet susceptible d'être un meilleur temps ; comparaison AMRAP par formule `rounds × 1000 + reps` | Résultats chronométrés complets et positifs ; comparaison lexicographique rounds puis reps |
| Navigation WOD | Lancer depuis l'aperçu d'un chrono actif créait un second runner | Bouton de retour au même chrono ; confirmation avant sortie avec résultat non enregistré |
| Paramètres de séance | Zéro, négatifs ou pyramides invalides possibles ; modes modifiés par référence | Validation avant application, copie des objets dans les éditeurs |
| Séries spéciales | « Montée en singles puis… » reconnue comme myo-reps ; repos personnalisé myo ignoré | Détection plus précise et utilisation du micro-repos défini |
| Cache WOD | Matériel calculé avec une clé fondée seulement sur l'identifiant et le nombre de lignes | Cache fondé sur le contenu ; statistiques comparées à la définition réelle |
| Estimations WOD | Numéros de minutes, virgules décimales et blocs multipliés mal interprétés | Normalisation des préfixes, lecture de blocs et prise en compte de MU ; barème stable sur le catalogue complet |
| Interface | Bouton de recherche effaçant le filtre mais pas le texte ; boutons de fin/repos ne se rafraîchissant pas | Contrôleur de recherche, vues reliées aux notifications du store |
| Petits écrans | Débordements sur les crédits, les statistiques et les chronos longs | Texte flexible et réduction adaptée des grands chiffres |
| Thème | Propriétés du thème mises en cache mais dépendant encore de la palette globale | Capture des couleurs du schéma de thème et synchronisation avec le thème effectif |
| Rappels | Replanifications concurrentes et absence d'ouverture de la séance au clic | File d'exécution, payload de navigation, icône dédiée conservée par R8, actualisation à la reprise |
| Build | Flutter stable flottant, absence de lock livré, patchs Gradle via chaînes de texte, aucun test dans Actions | Versions fixées, lockfile, projet Android inclus et contrôles bloquants |
| Scripts | Arrondi Python différent d'Excel, fichier image fixé à un chemin absent, compression supprimant les sources | Fonctions testées, arguments CLI, compression déterministe conservant les JSON |

## Améliorations de performances vérifiables dans le code

- Calcul du meilleur score en un parcours, sans trier une copie de tous les résultats.
- Calcul de l'XP une seule fois dans la boucle de recherche du niveau.
- Index de correspondance exercice/groupe musculaire au lieu d'un parcours de la base pour chaque série.
- Définition d'un WOD sérialisée sans construire sa liste de résultats pour comparer un cache.
- Reconstruction du cadre du runner à son démarrage/réinitialisation ; les mises à jour du chrono restent dans leur zone d'affichage.
- Catalogue de base non dupliqué dans les nouveaux exports : conservation des différences, suppressions et résultats, avec compression des données volumineuses.
- Suppression de la dépendance `flutter_displaymode` et des modifications de son cache ; sélection du taux de rafraîchissement par un pont Android ciblé.

Ces changements n'ont pas fait l'objet d'un benchmark sur le téléphone : aucun gain chiffré de vitesse, d'autonomie ou de taille d'APK n'est annoncé.

## Vérifications réalisées

- **Analyse statique sans anomalie** avec Flutter 3.29.3 / Dart 3.7.2 : résultat final consigné dans `validation/analyze.txt`.
- **41 tests Flutter réussis** : résultat final consigné dans `validation/flutter-tests.txt`. Couverture fonctionnelle des imports, migrations, archives, compteurs, chronos, parsing, caches, rendus de la carte, recherche, saisie, score et petits écrans, dans les thèmes clair et sombre. Les calculs calendaires sont exécutés avec `TZ=Europe/Paris`.
- Quatre tests Python : arrondis Excel, repos, compression reproductible, intégrité des assets et identité Android.
- Programme fourni vérifié : 40 semaines, 280 jours, 1 954 identifiants d'exercice distincts ; base de 172 exercices.
- XML Android analysés ; certificat de signature comparé à l'empreinte de la clé d'origine.
- Sources gzip du programme et de la base, images d'origine, sons et clé `.p12` conservés à l'identique dans la livraison.
- Workflow YAML et commandes shell vérifiés localement ; les tests font partie des étapes bloquantes avant le build release.

## Ce qui reste à confirmer

Le SDK Android est absent de l'environnement de travail. La tentative de build n'a donc pas fourni d'APK validé ; l'exécution sur GitHub Actions et l'essai sur téléphone n'ont pas été réalisés ici. Les versions natives, la signature de l'APK produit, les permissions Android, les notifications après redémarrage et la mise à jour sur l'installation existante doivent être confirmées par cette compilation et l'appareil.

Le classeur et l'illustration source n'étaient pas fournis : les assets conservés ont été vérifiés, mais leur régénération complète n'a pas été comparée aux originaux. Les estimations WOD restent heuristiques. Le fonctionnement des alertes pendant une suspension Android et le renouvellement des rappels après sept jours restent soumis aux limites décrites dans README.md.

## Installation dans le dépôt

Remplacer le zip à la racine et le workflow `.github/workflows/build-apk.yml` ensemble, puis laisser **Build APK** s'exécuter. Conserver une sauvegarde de l'application avant l'installation. Le détail de la procédure est dans README.md.
