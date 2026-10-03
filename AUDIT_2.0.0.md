# Kalis Track 2.0.0 — Refonte bordeaux

## Résultat

Les quinze familles d'écrans et les composants partagés utilisent la nouvelle identité. L'accueil met la séance du jour en avant. La navigation nomme ses cinq destinations et conserve leur état. Les réglages sont organisés en pages ; le suivi donne accès à l'historique complet. Le logo K est décliné pour l'interface, le démarrage, les notifications et les lanceurs Android.

Les zones de saisie des séries restent compactes : cinq séries avec charge et effort ainsi que l'accès aux notes restent visibles à 360 × 760 px. Les boutons de navigation et les formulaires ont des zones tactiles plus généreuses. Les composants s'adaptent au clavier, à la rotation et au texte agrandi.

## Vérifications effectuées

| Contrôle | Résultat |
|---|---|
| Flutter 3.29.3 / Dart 3.7.2, dépendances verrouillées | Restauration réussie |
| `flutter analyze --no-pub` | Aucun problème |
| Tests Flutter | **132 réussis** ; test de captures ignoré dans cette commande puis exécuté séparément |
| Tests Python | **4 réussis** |
| Captures Flutter | Test réussi ; **30 captures** en clair / sombre, 390 px et accueil 320 px |
| Petits écrans et texte à 130 % | Parcours de navigation, formulaires, séances, WOD et progression vérifiés |
| Saisie / notes / navigation | Valeurs conservées, y compris après changement de page et retour |
| Historique | Lecture seule et données inchangées |
| Chronos / WOD | Tests de pause, reprise, durées longues, scores et absence de doublons réussis |
| Menus de réglages | Paramètres conservés après aller-retour ; export et import accessibles |
| Assets / Android / signature | Vérification `tools/verify_project.py --signing` réussie |
| Logique métier et ressources | 14 fichiers critiques identiques octet pour octet à l'archive fournie |

Les rapports sont dans `validation/2.0.0`. Les tests de la précédente présentation ont été adaptés aux libellés visibles, aux nouvelles rubriques et au défilement des cartes ; les assertions de persistance, de navigation et de lecture seule sont conservées.

## Données préservées

Les 40 semaines, 280 journées, 1 954 exercices du programme et 172 exercices de la base sont inchangés. Le stockage, les calculs, les chronomètres, la progression, les modèles WOD, les notifications, le fichier de dépendances verrouillées, l'identifiant Android et le certificat de signature sont conservés. Le fichier `core-integrity.json` documente cette comparaison.

Les exemples du test de captures vivent uniquement dans les données simulées des tests. Aucune donnée de démonstration n'est ajoutée à l'application livrée.

## Limites de compilation et de validation

**Aucun APK n'a été produit dans cet environnement.** La compilation Android s'arrête au téléchargement de Gradle avec `java.net.SocketException: Network is unreachable`. Le workflow GitHub habituel est conservé dans l'archive et reste la voie de compilation à utiliser.

Un essai complémentaire de `flutter build bundle --release` s'est arrêté à la copie du manifeste natif généré (`native_assets.json` absent) ; il n'est pas présenté comme une compilation réussie. Le rapport est conservé dans `flutter-bundle.txt`. L'analyse, les tests et les captures ci-dessus sont les vérifications effectivement réussies.

Aucun test n'a été réalisé sur un téléphone physique. Le rendu du lanceur, les notifications Android et les performances en séance nécessitent cette vérification après compilation. Les anciennes validations esthétiques ne sont pas assimilées à une validation de la nouvelle refonte.

## Livraison

- `streetlift_tracker_v33.zip` : projet Flutter complet, ressources, tests, documentation, checklist et workflow.
- `Kalis_Track_2.0_Apercu.png` : aperçu composé de captures de la vraie interface.
- Checklist actualisée ; détails historiques préservés dans `docs/REFONTE_UI_1.8.7.md`.
