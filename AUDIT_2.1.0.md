# Kalis Track 2.1.0 — STATS unifié

## Résultat

Suivi et Pilotage quittent la navigation principale. Les statistiques, références, historiques, niveaux, badges et objectifs sont regroupés dans STATS, avec quatre rubriques : Aperçu, Parcours, Performances et Historique. Les raccourcis de progression rejoignent le même onglet, y compris depuis une route ouverte au-dessus de l’accueil.

Le parcours devient un arbre interactif à trois branches : Pratique, Rythme et Défis. Ses paliers correspondent aux 16 badges existants et affichent leur état, le progrès vers leur cible et leur bonus. Les critères sont consultables sans attribution supplémentaire de récompense. Les rangs et le détail des XP sont accessibles depuis le niveau.

L’aperçu présente l’activité hebdomadaire, le prochain objectif, huit semaines de régularité et les totaux. Les performances conservent les références de force et d’endurance, leurs cibles, les muscles et les meilleurs résultats WOD. L’historique rassemble les séances et tentatives WOD avec recherche et filtres ; les séances anciennes sans date restent présentes.

La couleur #6C1A1A, le logo historique, les arrondis et le fonctionnement de Programme / séances sont conservés. La navigation comporte quatre onglets : Arsenal, STATS, Programme et Réglages.

## Contrôles effectués

| Contrôle | Résultat |
|---|---|
| Flutter 3.29.3 / Dart 3.7.2 | SDK de validation |
| Analyse Flutter | Aucun problème |
| Tests Flutter | **143 réussis** ; capture optionnelle exécutée séparément |
| Tests Python | **4 réussis** |
| Captures de l’application | **43 rendus**, dont STATS en clair / sombre, 320 px, arbre et références, et aperçu sans données |
| Navigation principale | Quatre destinations, conservation de la semaine et du thème |
| Raccourci de niveau | Ouvre STATS → Parcours sans écran de progression séparé |
| État de STATS | Rubrique, filtre et recherche conservés en changeant d’onglet |
| Historique unifié | Ordre chronologique, tentatives WOD et séances sans date incluses |
| Données et notes | Lecture seule et contenu inchangé après consultation des séances / WOD |
| Références | Modification enregistrée, retour aux performances et valeur actualisée |
| Paliers | Mise à jour après une nouvelle séance ; consultation sans XP supplémentaires |
| Petits écrans | Quatre rubriques à 320 px et texte à 130 %, clair / sombre, avec défilement |
| Lecteur d’écran | Test automatique de nommage des commandes et paliers réussi |
| Programme, séances, WOD, chronos, import / export | Tests de régression existants conservés et réussis |
| Assets et identité Android | `tools/verify_project.py --signing` réussi |

Les rapports sont conservés dans `validation/2.1.0`. Les captures sont produites par le moteur Flutter à partir des widgets de l’application. Leur journal de démonstration vit exclusivement dans les préférences simulées du test et n’est pas ajouté à l’application.

Les tests ont notamment permis de corriger le rafraîchissement des rubriques après un changement de données et l’adaptation du pied de graphique au texte agrandi.

## Données conservées

40 semaines, 280 jours, 1 954 exercices du programme et 172 exercices de la base. Les règles de calcul, stockage, chronomètres, XP, crédits, badges, notifications, dépendances verrouillées, identifiant Android et signature sont préservés.

La comparaison avec l’archive d’origine est documentée dans `core-integrity.json` : 13 des 14 fichiers critiques sont identiques octet pour octet. Dans `training_estimate.dart`, seul le libellé « à partir du Pilotage » devient « à partir de tes références » ; la comparaison confirme que le reste du fichier, donc les calculs, est identique.

Les nouveaux agrégats réutilisent la progression existante. Les journées de repos validées comptent dans l’avancement du programme, sans être présentées comme des entraînements. Le suivi de régularité repose toujours sur deux jours actifs par semaine et n’impose pas d’entraînement quotidien. Aucune courbe de poids ou de 1RM historique n’est créée à partir des seules références actuelles.

## Limites et compilation

Version **2.1.0+42**. Aucun APK n’a été compilé dans cet environnement. La compilation Android avait été bloquée par l’accès réseau de Gradle lors de la livraison 2.0.0 ; le détail de cette limite est conservé dans `AUDIT_2.0.0.md`. Le workflow GitHub habituel et sa signature sont fournis.

Aucun test sur téléphone physique ou avec TalkBack natif n’est revendiqué. Les contrôles d’accessibilité portent ici sur les widgets, leurs libellés et les mises en page agrandies.

## Fichiers livrés

- `streetlift_tracker_v33.zip` : projet complet, code, tests, assets, rapports et workflow.
- `Kalis_Track_2.0_Apercu.png` : aperçu de refonte actualisé en version 2.1.0 avec les écrans STATS ; journal de démonstration signalé.
- `Kalis_Track_Checklist_Refonte_UI.md` : checklist actualisée.
