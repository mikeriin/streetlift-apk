# Livraison M4c — Dépôt en sources, zoom au pincement, filtres normalisés (Kalis Track 5.3.2)

**Date** : 28/09/2026 · **Version** : 5.3.2+77 · **Commit main** : 67ec551 (restructuration a42f149) · **Build signé** : run 36431053547 (n° 112, sur dd50268 ; 67ec551 ne change que README et SUIVI) · **CI 3D** : run 36428956594 (8 essais, de 36415874003 à 36428956594)

## Ce que tu vois
- **GitHub** : `main` montre les dossiers du projet (lib, assets, android, test, tools, docs…) au lieu de `streetlift_tracker_v33.zip`. Le commit de restructuration est identique octet pour octet au ZIP 5.3.1 (578 fichiers, SHA-256), hors `.gitignore` (complété) et `.gitattributes` (ajouté).
- **Zoom au pincement** sur le mannequin (Anatomie, fiche exercice, STATS, Moteur 3D) : de 1× (corps entier) à 4×, centré entre les doigts ; déplacement à deux doigts une fois zoomé ; double toucher ou boutons Face / Dos / Profil / 3/4 = vue d'ensemble ; toucher bref = nom du muscle ; dans les pages qui défilent, glisser verticalement fait toujours défiler.
- **Filtres normalisés** : bouton « Filtres · n », menu par catégorie (repliable, cases à cocher, Tout cocher / Tout décocher, Réinitialiser), union dans une catégorie, intersection entre catégories, puces supprimables sous le bouton (6 au plus, puis « + n »), fermeture au toucher en dehors.

## Écrans qui filtraient (avant → après)
| Écran | Avant (5.3.1) | Après (5.3.2) |
| --- | --- | --- |
| Arsenal › Exercices | 4 listes déroulantes à choix unique (Type, Lieu, Matériel, Difficulté) | Menu : Type de mouvement, Lieu, Matériel, Difficulté (plusieurs choix) |
| Choix d'exercice (séance perso) | 2 rangées de puces à choix unique (groupe, matériel) | Menu : Groupe musculaire, Matériel |
| Arsenal › Catalogue WOD | puces rapides + panneau en feuille (Accès à choix unique, Format, Mouvements, Difficulté, Durée, Matériel, Source) + puces actives | Menu : Accès (à cocher), Format, Mouvements, Difficulté, Durée estimée, Matériel, Source |
| STATS › Historique | 3 puces à choix unique (Tout, Séances, WOD) | Menu : Type (Séances, WOD) |
| Arsenal › Anatomie | menu de cases de M4b | Menu commun : Groupes musculaires, Affichage (Muscles profonds, Os) ; puces des groupes |

Inchangés (pas des filtres) : onglets et rubriques de STATS, branches de progression, semaines de l'accueil, tri du catalogue WOD, vue Face / Dos, saisies et réglages (échange d'exercice, séance adaptée, générateur de programme, profil, Koach, avis de test, objectif hebdomadaire). Mémorisation : pendant la session pour la bibliothèque, le choix d'exercice, le catalogue et l'historique ; Anatomie inchangée.

## Technique
- `tools/compare_tree_with_zip.py` (identité), `release_security.check_tree` (`package_release.py --check`, `check_release_without_secrets.py --tree`), `verify_project.verify_repository`, `tools/tests/test_repository_tree.py`.
- `build-apk.yml` depuis la racine (chemins du projet, toute branche, à la demande) ; `ci-3d.yml` sans extraction, « avant » = main (ZIP ou sources), émulateur limité à 30 min, `ci-out` ajouté avec `-f`.
- `lib/mannequin_gestures.dart` (`MannequinZoom`, `PinchGestureRecognizer`, `MannequinGestures`) ; `lib/mannequin_3d.dart` (caméra zoomée, pincement calculé depuis son début et vérifié par les rayons de la caméra, double toucher, boutons de vue).
- `lib/filter_menu.dart` (`FilterMenu`, `FilterSelection`, `FilterCategory`) ; écrans : `exercise_screens.dart`, `builder_screen.dart`, `wod_catalog.dart`, `stats_history.dart`, `anatomy_screen.dart`.

## Contrôles
- Identité : arbre de a42f149 = ZIP 5.3.1 hors `.gitignore` et `.gitattributes`. Arbre sans secret : 586 fichiers contrôlés un par un.
- CI 3D : formatage, analyse sans remarque, 946 tests Dart réussis (13 ignorés, 0 échec), tests Python, builds debug et profile. Rendus avant / après : seuls le catalogue WOD et l'historique changent (bouton Filtres). `visual_capture_test.dart` échoue avant comme après (depuis 2.5.0).
- Émulateur : pincement réel à 4× sur un avant-bras (resté à 2 dp des doigts), nom au toucher une fois zoomé, déplacement à deux doigts, double toucher et bouton Dos = 1× ; fiche : glisser vertical = 134 dp de défilement sans zoom, pincement = 3× sans défilement ; menus Filtres de la bibliothèque, du catalogue WOD et de l'Anatomie, sombre et clair, puis leurs puces. Captures regardées.
- Build signé n° 112 depuis les sources : APK et AAB signés, identifiant et certificat vérifiés (`verify_android_artifacts.py`), donc installation par-dessus 5.3.1.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Étiquette `archive-zip-5.3.1` créée mais non poussée (le proxy de la session refuse les poussées d'étiquettes) ; le ZIP reste au commit 4531346 de l'historique, que `compare_tree_with_zip.py` utilise par défaut. Pour la créer : `git tag archive-zip-5.3.1 4531346 && git push origin archive-zip-5.3.1`.
- Le zoom agrandit l'image (angle de champ) : la perspective ne change pas.
- Le menu Filtres s'ouvre par-dessus le haut de l'écran.
- Anatomie : « Muscles profonds » et « Os » ne sont pas en puces (ils restent dans le menu et le résumé).
- `build-apk.yml` se déclenche aussi sur `claude/ci-3d` (build signé de contrôle).
