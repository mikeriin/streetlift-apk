# Kalis Track 2.2.0 — Palette, transitions et acquisition des WOD

Version **2.2.0+43**, 21 septembre 2026.

## Changements livrés

La palette de référence est désormais **#6D0808 / #2D0000 / #757D6F / #EEEAD7**. Les thèmes clair et sombre utilisent des nuances de surface et de texte adaptées à la lisibilité. Le K historique conserve exactement son masque ; il s’affiche sans fond dans l’interface et pendant l’ouverture, crème sur sombre et bordeaux sur clair. Les ressources Android suivent les nouvelles couleurs.

Les changements d’onglet, de rubrique STATS et de semaine reçoivent un fondu et un glissement de 240 ms. Les pages Android s’ouvrent en 280 ms et reviennent en 220 ms. Les pages iOS conservent la transition Cupertino. Les mouvements ajoutés respectent le réglage système de réduction des animations. Les sous-arbres de widgets restent montés : recherches, filtres, semaine, notes et positions de lecture sont conservés. Le changement du réglage d’accessibilité pendant une ouverture de page conserve également une saisie en cours.

Les nouveaux WOD s’obtiennent exclusivement dans le catalogue avec les crédits de progression. Les écrans et commandes de création, modification et duplication ont été retirés. La fiche affiche le prix, la commande « Acheter », l’état « Acquis », puis permet de lancer le chrono. Une route de chrono ouverte directement sur un WOD verrouillé affiche sa fiche d’achat. Le solde insuffisant empêche l’acquisition. Le catalogue propose ses 500 WOD ; les WOD personnels des anciennes versions restent disponibles dans l’arsenal avec leurs résultats.

Les acquisitions existantes restent valides. Le tarif et la distribution des crédits ne changent pas ; il n’y a aucun paiement monétaire ni débit par tentative. L’édition des séances personnelles reste disponible.

## Vérifications

| Contrôle | Résultat |
|---|---|
| Flutter 3.29.3 / Dart 3.7.2 | SDK de validation |
| Analyse Flutter | Aucun problème |
| Suite Flutter | **152 tests réussis**, un test de captures optionnel exécuté séparément |
| Tests Python | **4 tests réussis** |
| Captures Flutter | **43 rendus réels**, thèmes clair / sombre, vues principales, STATS, programme, séances, achat et chrono WOD |
| Achat WOD | Débit unique même avec deux activations de la commande ; acquisition persistante après rechargement |
| WOD verrouillé | Aucun démarrage avant achat, y compris en ouvrant directement la route chrono |
| WOD hérités | Conservés avec scores, jouables, sans éditeur ; absents de l’offre du catalogue |
| Transitions | États préservés lors de changements rapides d’onglet ; ouverture et retour de route vérifiés |
| Réduction des animations | Contenu immédiat, sélecteur STATS adapté ; saisie préservée lors d’un changement en cours de transition |
| Petits écrans | Tests à 320 px avec texte à 130 % ; rotation et grands écrans couverts |
| Contraste de la palette | Rôles de texte testés à au moins 4,5:1 sur les surfaces principales et champs des deux thèmes |
| Logo | Alpha identique au masque original recadré, transparence conservée, couleur source #6D0808 |
| Programme et signature | Vérification des assets et de l’identité Android réussie |

Les rapports et les captures sont dans `validation/2.2.0`. Les données illustrées sont générées uniquement dans le test de capture et ne sont jamais ajoutées à l’application livrée. Les rendus ont été inspectés après correction du libellé d’acquisition sur écran étroit. Une revue supplémentaire du code a porté sur la préservation d’état, les animations réduites et les chemins d’acquisition des WOD.

## Continuité des données

Le programme contient toujours 40 semaines, 280 jours et 1 954 exercices ; la base d’exercices contient 172 entrées. Les règles de séance, charges, chronos, XP, badges, résultats, import/export et notifications sont conservées.

`core-integrity.json` compare les fichiers critiques à l’archive d’origine. Douze des quatorze fichiers contrôlés restent identiques octet pour octet. Dans `training_estimate.dart`, seul le libellé « Pilotage » est remplacé par « tes références », changement de la livraison précédente. Dans `store.dart`, seules des méthodes WOD désormais inutilisées ont été retirées et des commentaires / annotations ont changé ; calculs, acquisition, stockage et résultats restent identiques. Le détail est dans `store-scope.diff`.

L’identifiant Android, la clé et le certificat de signature ainsi que les dépendances verrouillées sont préservés. Le workflow GitHub habituel est fourni avec le projet.

## Limites de validation

Aucun APK n’a été compilé dans cet environnement. La compilation Android y avait été bloquée par l’accès réseau de Gradle lors de la livraison initiale ; le workflow GitHub reste le chemin de compilation fourni. Aucun test sur téléphone physique, avec TalkBack natif ou sur iOS n’est revendiqué. Le contrôle de contraste porte sur les rôles de la palette, et ne constitue pas une certification d’accessibilité de toute l’application.

## Livraison

- `streetlift_tracker_v33.zip` : projet complet, code, assets, tests, rapports et workflow.
- `Kalis_Track_2.0_Apercu.png` : fichier d’aperçu existant, actualisé avec les écrans de la version 2.2.0.
- `Kalis_Track_Checklist_Refonte_UI.md` : checklist actualisée, avec l’historique des versions précédentes conservé dans le projet.

Renommer l’archive en `streetlift_tracker_v33.zip` si le téléchargement ajoute un suffixe, puis l’utiliser dans le workflow **Build APK** habituel. Installer ensuite la mise à jour sans désinstaller l’application existante.
