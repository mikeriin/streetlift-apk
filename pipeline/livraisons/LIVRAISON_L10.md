# Livraison L10 — Kalis Track 4.0.0 (générateur de programme personnalisé)

**27 septembre 2026 — lot exécuté par le pipeline automatisé.** Tickets KT-050 à KT-057.

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 3.2.0+66 (L9b), `main` `6015ebc`, SHA-256 `699329b4…578f14` |
| ZIP publié | `streetlift_tracker_v33.zip`, 2 137 835 octets, 471 fichiers (5 860 865 octets extraits), SHA-256 `2cd7c9a595bc5a3eb293b587db708c26f826865d68d9fe902dee40a94850affc`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` ; `lib/`, `test/` et `assets/` identiques à l'arbre testé en CI |
| Commit `main` | `5d38177` |
| Build signé | Run **n° 88** (id 36311635184) **réussi** le 27/09/2026 10:09-10:25 UTC : contrôle du ZIP et du workflow, formatage, analyse, tests Dart et Python, icônes, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés avec le même numéro, artefacts vérifiés. Artefacts : `kalis-track-apk` (28 662 557 octets), `kalis-track-aab` (29 342 468), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36311635184 |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- **Ton programme actuel de 40 semaines ne change pas.** Il devient le modèle « Expert streetlifting », identique jour pour jour (LC1 comprise) ; départ, historique, records, Koach et sauvegardes restent tels quels. L'export est identique à 3.2.0 tant que tu ne génères rien.
- **Réglages → Mon programme** (nouveau) : modèle et explication. Le bouton « Générer mon programme personnalisé » propose un programme construit depuis ton profil, **à partir d'aujourd'hui**, après un aperçu « ce qui change » ; tes semaines passées restent en place. Tu peux l'essayer et revenir en arrière pendant 7 jours (tant qu'aucune séance du nouveau programme n'est saisie).
- Pour un **nouveau profil** (démarrage court), le programme personnalisé est généré dès le choix de la date de départ : périodisation expliquée, niveau par mouvement, tests légers de calibrage, séances ajustées au temps disponible, échauffement, ligne « pourquoi » par séance et par exercice (dans les consignes).
- **13 profils types** générés pour relecture : `docs/PROFILS_TYPES_L10.md` dans le ZIP.

## 3. Installation

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du run ci-dessus ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir l'application : aucun écran nouveau au démarrage.

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Après mise à jour : accueil, semaine en cours, séances, historique, records, WOD et Koach identiques à 3.2.0.
2. Réglages → **Mon programme** : « Expert streetlifting (40 semaines) » et son explication ; texte lisible à 200 %.
3. « Générer mon programme personnalisé » : l'aperçu s'affiche (séances par semaine, durée, séries par groupe, exercices ajoutés et retirés) ; « Garder mon programme actuel » ne change rien.
4. (Facultatif, annulable 7 jours) Appliquer : les semaines passées sont inchangées ; ouvrir une séance à venir → consignes d'un exercice → ligne « Pourquoi » ; démonstration dans Arsenal → Exercices ; puis « Revenir à la version précédente » (carte de l'accueil ou Mon programme) → programme de 40 semaines rétabli.
5. Temps de génération ressenti (cible : quelques secondes au plus).
6. Nouvelle installation sur un autre appareil ou après effacement (facultatif) : démarrage court → Départ du programme → programme personnalisé ; vérifier les jours choisis et la durée des séances.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-050 à KT-057 |
| Testé automatiquement | CI `claude/ci-tools` commit `dc9e3bd` : format, analyse sans problème, **689 réussis / 12 ignorés** (630 existants inchangés + 59 L10, dont 10 000 profils aléatoires sans écart et 13 profils types), Python 72/72, `verify_project.py`, build debug ; puis rejoués par le run de build signé |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; temps de génération sur téléphone ; relecture des 13 profils types ; registre `docs/CONTRAT_L10.md` §8 (contenu sportif non relu par un professionnel diplômé) |

## 6. Décisions prises par défaut

Voir `docs/CONTRAT_L10.md` §2 (D-L10-01 à D-L10-13). Les plus visibles : installation existante = modèle Expert streetlifting implicite, rien n'est réécrit ; programme personnalisé généré au choix du départ pour un nouveau profil ; seuils de niveau proposés par le prompt appliqués, tranches du profil L8 converties en répétitions « estimées » ; séance plus courte que le temps disponible quand le plafond de volume est atteint (signalée) ; matériel déduit des lieux ; D-L9b-09 laissée en attente.

## 7. Fichiers modifiés

Nouveaux : `lib/program_generator.dart`, `lib/program_instance.dart`, `lib/program_store.dart`, `lib/program_screens.dart`, `assets/program_models.json`, `docs/CONTRAT_L10.md`, `docs/PROFILS_TYPES_L10.md`, `test/l10_generator_test.dart`, `test/l10_properties_test.dart`, `test/l10_profiles_test.dart`, `test/l10_store_test.dart`, `test/l10_screens_test.dart`, `test/support/l10_support.dart`, `test/goldens/l10_reference.json`, `test/goldens/l10_profils_types.md`, `tools/tests/test_program_models.py`. Modifiés : `lib/store.dart`, `lib/profile_store.dart`, `lib/models.dart`, `lib/session_screen.dart`, `lib/home_screen.dart`, `lib/settings_screen.dart`, `pubspec.yaml` (4.0.0+67), `tools/verify_project.py`, `README.md`, `SUIVI_PROJET.md`. Aucun fichier supprimé ; aucun test existant modifié.
