# Kalis Track 2.0.1 — Note Programme et arrondis

## Modifications réalisées

La semaine affiche J1 à J7 dans leur ordre. Les jours autres qu'aujourd'hui sont des lignes compactes de 44 px minimum, avec un cercle vide ou une coche. Le jour actuel garde le titre, la durée estimée, les exercices, séries, volume et muscles. Un jour de récupération affiche les informations adaptées. Les jours terminés ouvrent toujours l'historique en lecture seule.

Le slider reste seul en haut : appui court pour les détails, appui long pour choisir une semaine, glissement pour la sélectionner. Les balayages du contenu passent à la semaine voisine. Les flèches, commandes « Détails », boutons d'ouverture et de résumé redondants ont été retirés de l'accueil. L'appui sur un jour ouvre sa séance ; l'appui long ouvre son résumé. Le clavier et le lecteur d'écran proposent les mêmes actions.

« NIV. » précède le niveau ; une barre séparée affiche l'avancement réel en XP. Le logo reprend exactement le masque de la silhouette originale. Sa couleur et les surfaces dominantes sont **#6C1A1A**, accompagnées de fonds chauds et de teintes lisibles pour les textes. Les arrondis ont été augmentés sur les cartes, saisies, boutons, menus, panneaux, dialogues et le dock.

## Vérifications

| Contrôle | Résultat |
|---|---|
| Flutter 3.29.3 / Dart 3.7.2 | Environnement de validation utilisé |
| `flutter analyze --no-pub` | Aucun problème |
| Tests Flutter | **134 réussis**, capture optionnelle ignorée puis exécutée séparément |
| Tests Python | **4 réussis** |
| Captures de la vraie application | **32 images**, test réussi ; clair / sombre, 390 × 844, Programme 320 × 844 et 390 × 760 |
| Semaine complète et ordonnée | Test de visibilité des sept jours à 390 × 844 ; captures réelles à 390 × 760 également contrôlées |
| Gestes | Appuis court / long, glissement du slider et balayage des semaines vérifiés |
| Niveau | Libellé NIV., position et valeur de la barre à 0 %, 60 % et 100 % vérifiés |
| Historique et saisies | Lecture seule, notes et séries conservées après navigation |
| Petits écrans | Parcours à 320 px et texte à 130 % ; défilement conservé quand nécessaire |
| Séries en séance | Cinq séries et accès aux notes restent visibles à 360 × 760 |
| Chronos, WOD, import / export | Tests de régression conservés et réussis |
| Assets / signature | `tools/verify_project.py --signing` réussi |
| Logique et données | 14 fichiers critiques identiques octet pour octet à l'archive d'origine |
| Logo | Masque alpha original strictement identique ; foreground recoloré exactement en RGB(108, 26, 26) |

Les rapports et images sont dans `validation/2.0.1`. Les tests de présentation du niveau ont été adaptés à la nouvelle barre demandée ; les tests de conservation des données et de fonctionnement restent en place. Les exemples des captures sont uniquement dans les préférences simulées du test et ne sont pas ajoutés à l'application.

## Données et compilation

Les 40 semaines, 280 jours, 1 954 exercices du programme et 172 exercices de la base sont conservés, ainsi que les calculs, modes de séance, chronos, progression, stockage, notifications, dépendances verrouillées et signature Android. `core-integrity.json` et `brand-integrity.json` documentent les comparaisons.

Version : **2.0.1+41**. Le workflow GitHub d'origine reste fourni avec son numéro de compilation croissant et la même clé de signature.

**Aucun nouvel APK n'a été compilé dans cet environnement.** La compilation Android avait été bloquée par l'accès réseau de Gradle lors de la livraison 2.0.0 ; les détails sont conservés dans `AUDIT_2.0.0.md`. Cette révision a été analysée, testée et rendue avec Flutter, mais les ressources natives restent à vérifier sur téléphone après compilation par le workflow habituel. Aucun essai sur un appareil physique n'est revendiqué.

## Livraison

- `streetlift_tracker_v33.zip` : projet complet, tests, ressources, documentation et workflow.
- `Kalis_Track_2.0_Apercu.png` : aperçu actualisé en version 2.0.1, composé des captures réelles de Programme en clair / sombre et de la séance.
- `Kalis_Track_Checklist_Refonte_UI.md` : checklist actualisée avec chaque point de la note.
