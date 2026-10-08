# Kalis Track 2.2.3 — Chrono de fin d'exercice et palette appliquée

Le suivi, le pilotage et la progression sont réunis dans **STATS**. La navigation principale compte quatre onglets : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Nouveautés 2.2.3

- Le repos se lance aussi après la dernière série d'un exercice (transition vers le suivant). Myo-reps : micro-repos entre séries, repos complet en fin, valeur affichée dans la puce « Repos final ».
- Palette appliquée à tous les écrans : bordeaux #6B0C0C pour les actions principales et les jauges, rouge #A61717 pour les états actifs, les records et les alertes de chrono, vert réservé à la validation, chiffres du chrono en blanc cassé. En sombre, les textes et icônes accentués utilisent #E85959, teinte du rouge d'action lisible sur #1E1E1E (4,8:1).
- Jauges en dégradé bordeaux → rouge sur piste neutre (`KProgressBar`), carte musculaire en rampe bordeaux → rouge.
- Boutons de mode et de suppression lisibles, sous-titre du réglage Thème exact, sous-pages Réglages sans titre doublé.

## Palette 2.2.2

Cette mise à jour applique la palette bordeaux fournie. Le mode sombre est choisi par défaut pour une nouvelle installation ; les choix Clair et Système restent disponibles et les préférences existantes sont conservées.

## Présentation et fonctions

- Palette demandée : **#CB2957 · #000000 · #DDDDDD · #EEEEEE**, déclinée en thèmes clair et sombre avec des nuances lisibles.
- Le K historique apparaît seul, sur fond transparent, dans l’en-tête et à l’ouverture : blanc cassé en sombre, bordeaux en clair. La forme originale est conservée.
- Transitions courtes en fondu et glissement entre onglets, rubriques STATS, semaines et pages. Les filtres, saisies et positions de lecture sont conservés. Les mouvements ajoutés respectent « Réduire les animations ».
- Les nouveaux WOD s’acquièrent uniquement dans le catalogue avec les crédits gagnés en progressant. Le prix est affiché avant l’achat ; un achat donne un accès durable, sans nouveau débit à chaque tentative.
- Création, modification et duplication de WOD retirées. Les WOD acquis, anciens WOD personnels et tous leurs résultats restent disponibles. Les séances personnelles restent composables.

Palette fournie directement dans la demande : bordeaux, rouge d’action, anthracite, blanc cassé, gris et vert de validation.

## Un suivi clair, avec des paliers motivants

| Rubrique STATS | Contenu |
|---|---|
| Aperçu | Niveau et XP, activité de la semaine, prochain objectif, huit semaines d’activité et totaux |
| Parcours | Arbre de badges : Pratique, Rythme et Défis ; paliers obtenus, prochain objectif, bonus et règles |
| Performances | Force, endurance, références modifiables, avancement du programme, muscles et records WOD |
| Historique | Séances et tentatives WOD, recherche dans les titres et notes, filtres, détails en lecture seule |

Les badges et missions utilisent les séances, séries et résultats déjà enregistrés. Les récompenses restent automatiques et ne sont pas attribuées à nouveau en ouvrant leur fiche. Les règles de régularité autorisent les repos : deux jours actifs suffisent pour valider une semaine.

L’arbre présente les chemins parallèles des 16 badges existants. Il ne bloque aucun entraînement et ne change pas les critères d’obtention. Les rangs sont ceux de l’application. Les cibles de force et d’endurance reprennent les références du programme ; aucune courbe historique de poids ou de 1RM n’est inventée.

## Continuité des séances

Les arrondis et la silhouette historique du logo sont conservés ; leurs couleurs suivent désormais la nouvelle palette. Programme garde les sept jours dans leur ordre, les gestes du slider et les résumés sur appui long. Son indicateur de niveau mène à STATS → Parcours.

Les 40 semaines, 280 journées et 1 954 exercices du programme, ainsi que les huit modes de séance, charges, séries, notes, RIR/RPE, vitesse, chronos, WOD, XP et sauvegardes gardent leur fonctionnement. Les anciennes séances sans date restent consultables. Les formulaires de références enregistrent toujours automatiquement leurs valeurs.

Les données des captures sont simulées uniquement dans les tests. L’application livrée n’ajoute aucune activité de démonstration à ton historique.

## Compilation habituelle depuis le ZIP

1. Remplacer `streetlift_tracker_v33.zip` dans le dépôt habituel. Si le téléchargement ajoute un suffixe, renommer d’abord l’archive avec ce nom exact.
2. Conserver `.github/workflows/build-apk.yml`, également fourni dans le projet.
3. Lancer **Build APK**, puis télécharger `kalis-track-apk`.

Le workflow restaure les dépendances verrouillées, analyse le code, exécute les tests, génère les icônes et compile l’APK signé. L’identifiant Android et la clé d’origine sont conservés ; le numéro de compilation GitHub reste croissant. Ne pas désinstaller l’application pour effectuer la mise à jour.

## Développement et vérification

```sh
flutter pub get --enforce-lockfile
flutter analyze --no-pub
python3 tools/verify_project.py --signing
python3 -m unittest discover -s tools/tests -v
TZ=Europe/Paris flutter test --no-pub --timeout 90s --reporter expanded
```

Captures reproductibles de l’application :

```sh
flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart
```

Elles sont écrites dans `validation/2.2.3`. Le test de captures reste désactivé lors de la commande habituelle. Pour charger les polices dans les rendus, définir `FLUTTER_ROOT` sur le SDK utilisé.

Le masque original du logo est `assets/icon/logo_mask.png`. `tools/generate_brand.py` régénère ses déclinaisons ; les ressources Android sont déjà fournies.

Voir `REFONTE_UI.md` pour la checklist et `AUDIT_2.2.3.md` pour les vérifications et les limites de validation. Les documents antérieurs sont conservés dans `docs` et les audits précédents.

## Archive de livraison sous 25 Mo

```sh
python3 tools/package_release.py ../streetlift_tracker_v33.zip
```

Le paquet conserve intégralement le code, les ressources, les tests, la signature et le workflow. Il inclut les captures de la version actuelle, quand elles ont été générées, et les rapports textuels historiques. Les images de validation des anciennes versions sont exclues pour éviter leur accumulation. Le script refuse de remplacer l’archive si le ZIP ou son contenu extrait atteint 25 000 000 octets. Cette règle ne réduit ni la résolution ni la qualité des ressources de l’application.
