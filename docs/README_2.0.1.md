# Kalis Track 2.0.1 — Bordeaux

Refonte de l'interface Flutter et des menus, à partir de la version 1.8.7+39.

## Nouveautés

- Identité bordeaux sombre **#6C1A1A**, fonds chauds, cartes davantage arrondies et typographie commune aux thèmes sombre, clair et système.
- Dock flottant avec cinq destinations identifiées : Arsenal, Suivi, Programme, Pilotage et Réglages. L'onglet et la semaine restent en mémoire pendant la navigation.
- Programme : sept jours dans leur ordre, jours compacts avec leur statut et séance du jour détaillée. Slider simple : appui court pour les détails, appui long pour choisir une semaine, glissement pour changer. Appui sur un jour pour ouvrir ; appui long pour son résumé.
- « NIV. » et barre de progression explicite sous le niveau, avec accès à la progression par un appui.
- Réglages organisés en pages : saisie des séries, chronomètres, pendant la séance, notifications, sauvegardes et À propos. Le choix du thème reste directement accessible.
- Historique complet accessible depuis Suivi ; les vingt derniers résultats restent dans le tableau de bord.
- Formulaires, éditeurs, catalogue, filtres, WOD, progression, dialogues et panneaux harmonisés.
- Silhouette historique du logo recolorée en bordeaux, icônes Android classiques, adaptatives et monochromes, icône de notification et ouverture animée assorties.

## Séances et données

Les 40 semaines, 280 journées et 1 954 exercices du programme sont conservés. Les huit modes d'exécution, séries, charges, RIR/RPE, vitesse, notes, chronomètres, WOD, crédits, XP et sauvegardes gardent leur fonctionnement. L'historique reste en lecture seule. Aucun exemple des captures n'est injecté dans les données utilisateur.

L'identifiant Android et la clé de signature d'origine sont conservés. Pour installer une mise à jour au-dessus d'une version compilée par GitHub, utiliser le workflow fourni : il produit un `versionCode` croissant. Ne pas désinstaller l'application pour la mettre à jour.

## Compilation habituelle depuis le ZIP

1. Remplacer `streetlift_tracker_v33.zip` dans le dépôt habituel.
2. Conserver `.github/workflows/build-apk.yml` (la copie fournie utilise toujours Flutter 3.29.3).
3. Lancer **Build APK**, puis télécharger l'artefact `kalis-track-apk`.

Si le téléchargement ajoute un suffixe au nom, renommer l’archive en `streetlift_tracker_v33.zip` avant de remplacer celle du dépôt.

Le workflow exécute l'analyse, les tests, la génération des icônes et la compilation signée. Les certificats et réglages de signature préexistants sont inchangés.

## Développement local

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
python3 tools/verify_project.py --signing
python3 -m unittest discover -s tools/tests -v
flutter test --no-pub
```

Les rendus de la vraie application sont reproductibles avec :

```sh
flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart
```

Ils sont écrits dans `validation/2.0.1`. Les tests habituels ignorent cette capture sur disque. Le masque exact du logo historique est `assets/icon/logo_mask.png`. Le script `tools/generate_brand.py` (Pillow) régénère ses déclinaisons ; les ressources compilables sont déjà incluses.

## Gestes et accessibilité

| Commande | Action |
|---|---|
| Jour : appui court | Ouvrir la séance ; si terminée, consulter son historique |
| Jour : appui long | Consulter le résumé sans modifier la séance |
| Slider : appui court / Entrée / Espace | Détails de la semaine |
| Slider : appui long / F2 | Choisir une semaine |
| Slider : glissement / flèches du clavier | Changer de semaine |
| Slider : Début / Fin | Première / dernière semaine |
| Contenu : balayage gauche / droite | Semaine suivante / précédente |
| Niveau : appui court | Ouvrir la progression |

Les lecteurs d’écran disposent des actions correspondantes. Les textes agrandis et les écrans très courts peuvent nécessiter un défilement. Les cibles des jours compacts mesurent au moins 44 px de haut.

## Direction visuelle

Les choix de hiérarchie, de grandes surfaces arrondies et d'accès à une main s'inspirent des [principes One UI de Samsung](https://design.samsung.com/global/contents/one-ui/). Le dock, les listes de réglages et la sobriété des contrôles reprennent des repères familiers des interfaces Apple. Les composants et le logo sont propres à Kalis Track.

Voir `REFONTE_UI.md` pour le périmètre, `AUDIT_2.0.1.md` pour les vérifications et `docs/README_1.8.7.md` pour la documentation historique.
