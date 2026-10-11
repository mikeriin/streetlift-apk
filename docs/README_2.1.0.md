# Kalis Track 2.1.0 — STATS

Le suivi, le pilotage et la progression sont réunis dans **STATS**. La navigation principale compte quatre onglets : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

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

La dominante **#6C1A1A**, le logo historique recoloré et les arrondis de 2.0.1 sont conservés. Programme garde les sept jours dans leur ordre, les gestes du slider et les résumés sur appui long. Son indicateur de niveau mène à STATS → Parcours.

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

Elles sont écrites dans `validation/2.1.0`. Le test de captures reste désactivé lors de la commande habituelle. Pour charger les polices dans les rendus, définir `FLUTTER_ROOT` sur le SDK utilisé.

Le masque original du logo est `assets/icon/logo_mask.png`. `tools/generate_brand.py` régénère ses déclinaisons ; les ressources Android sont déjà fournies.

Voir `REFONTE_UI.md` pour la checklist et `AUDIT_2.1.0.md` pour les vérifications et les limites de validation. Les documents antérieurs sont conservés dans `docs` et les audits précédents.
