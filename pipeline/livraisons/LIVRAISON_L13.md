# Livraison L13 — Kalis Track 4.3.0 (Santé, sécurité, conformité et test fermé)

**27 septembre 2026 — lot exécuté par le pipeline automatisé ; dernier lot du pipeline.** Tickets KT-072 à KT-078.

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 4.2.0+69 (L12), `main` `332e292`, SHA-256 `71f975ab…cf6eb5b6335` |
| ZIP publié | `streetlift_tracker_v33.zip`, 2 316 535 octets, 499 fichiers (6 388 517 octets extraits), SHA-256 `0ff331448aeff6e94d60e41fd7168012e22654f36f93bc759179309e077f1a70`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` ; `lib/`, `test/`, `tools/`, `assets/`, `android/` identiques à l'arbre testé en CI (`claude/ci-tools` `162d3a2`) |
| Commit `main` | `1a39f91` |
| Build signé | Run **n° 93** (id 36326404501) du commit `1a39f91` **annulé** à 14:47 UTC (après format, analyse et début des tests) par la règle de concurrence du workflow : la session de la refonte a poussé **4.3.1** sur `main` (`7f07e2e`, fusion autorisée par écrit par le propriétaire, construite sur 4.3.0). Contrôle : les fichiers L13 de 4.3.1 sont identiques à 4.3.0 (écrans, règles, tests, politique, contrat ; 0 allégation). **Build signé à installer : run n° 94** (id 36327156905) **réussi** le 27/09/2026 14:46-15:08 UTC sur 4.3.1 (L13 + refonte) : contrôle du ZIP, formatage, analyse, tests de régression (dont ceux de L13), icônes, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés, artefacts vérifiés. Artefacts : `kalis-track-apk` (30 304 826 octets), `kalis-track-aab` (30 974 126), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36327156905 . Aucun nouveau build de 4.3.0 seul relancé (il aurait annulé celui de 4.3.1). |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- **Avertissement** (application d'entraînement, pas un dispositif médical, aucun diagnostic ni promesse) : sous « Commencer » au premier écran d'une installation neuve, et dans Réglages → **À propos**.
- Réglages → À propos : **Santé et sécurité** (signaux d'alerte, douleur, grossesse / tension / 65 ans / reprise), **Récupération** (conseils généraux, aucun calcul), **Politique de confidentialité**, **Donner mon avis** (retour de test partagé seulement si tu le choisis).
- Pendant une séance : options (⋮) → **« Douleur ou malaise ? »**.
- Bilan Koach : sous une douleur > 3/10, rappel des signaux d'alerte ; après **3 séances de suite** > 3/10 sur un mouvement, conseil de consulter un professionnel.
- Export : le libellé précise qu'il contient le profil et les données de santé.
- Notifications : « Copier le diagnostic » s'appelle maintenant « Copier le rapport technique ».
- Rien d'autre ne change : aucune donnée migrée, crédits et programme identiques, aucune permission ajoutée.

## 3. Installation

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du **run n° 94 (4.3.1, qui contient L13)** ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir l'application : aucun écran nouveau au démarrage pour ton installation (profil déjà confirmé).

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Réglages → À propos : version 4.3.1 (L13 + refonte), carte d'avertissement, quatre nouvelles entrées ; ouvrir chacune (texte à 200 % : rien de coupé).
2. Politique de confidentialité : texte complet jusqu'à « Modifications ».
3. Donner mon avis → écrire une ligne → décocher « Version » → l'aperçu change → « Partager mon avis » ouvre le menu Android (tester une messagerie).
4. Une séance du programme → ⋮ → « Douleur ou malaise ? » → écran Santé et sécurité.
5. Bilan Koach d'une séance : noter une douleur 5/10 → le rappel des signaux d'alerte apparaît.
6. Réglages → Sauvegardes : libellé de l'export mentionnant les données de santé.
7. Accueil, séances, historique, records, WOD, Koach, Mes progrès : identiques à 4.2.0.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-072 à KT-078 |
| Testé automatiquement | CI `claude/ci-tools` `162d3a2` : format (0 changé), analyse sans problème, **835 réussis / 12 ignorés** (809 existants inchangés + 26 L13), tests ciblés L5/L6 155/155, Python 79 (78 réussis, 1 ignoré faute de Pillow sur le runner, rejoué localement), `verify_project.py`, 0 allégation ; build debug avec le partage texte ; puis rejoués par le build signé |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; **URL de la politique** à fournir ; décisions D-L13-01 à D-L13-10 ; registre de validation (22 éléments, 11 en P1 ; pas de relecture professionnelle en V1, ta décision) ; déclarations Google Play à saisir (`docs/GOOGLE_PLAY.md`, dont classification et public cible non vérifiés) |

## 6. Préparation de la publication (dans le ZIP)

- `docs/GOOGLE_PLAY.md` : visuel 1024 × 500 (`docs/play/feature_graphic_1024x500.png`), Sécurité des données (« aucune collecte »), déclaration santé (Activité et remise en forme ; aucune catégorie médicale), classification, public 18 ans et plus — sources consultées le 27/09/2026.
- `docs/TEST_FERME.md` : règle vérifiée (**12 testeurs pendant 14 jours consécutifs**, comptes personnels créés après le 13/11/2023), message d'invitation, mode d'emploi, scénarios par profil, tableau de suivi, critères de production.
- `docs/CONTRAT_L13.md` §6 : pourquoi Kalis Track reste hors du règlement (UE) 2017/745 (considérant 19, art. 2.1), avec source et date.
- `docs/CONFIDENTIALITE.md` : cartographie finale ; `assets/legal/confidentialite.md` : politique prête à héberger.

## 7. Décisions prises par défaut

Voir `docs/CONTRAT_L13.md` §2. Les plus visibles : avertissement sous l'action sans case à cocher (D-L13-01) ; renvoi à la 3ᵉ séance douloureuse (D-L13-02) ; profil importé de moins de 18 ans bloqué (D-L13-04) ; réponses Koach par séance hors consentement L8, non effacées par le retrait de l'accord (D-L13-05, à faire valider) ; note « anti-blessure » reformulée à l'affichage, asset du programme inchangé (D-L13-06) ; sauvegarde Android inchangée (KT-016).

## 8. Fichiers modifiés

Nouveaux : `lib/wellbeing.dart`, `lib/safety_store.dart`, `lib/wellbeing_screens.dart`, `assets/legal/confidentialite.md`, `docs/CONTRAT_L13.md`, `docs/GOOGLE_PLAY.md`, `docs/REGISTRE_VALIDATION.md`, `docs/TEST_FERME.md`, `docs/play/feature_graphic_1024x500.png`, `tools/check_claims.py`, `tools/tests/test_l13_compliance.py`, `test/l13_safety_test.dart`, `test/l13_screens_test.dart`. Modifiés : `lib/store.dart`, `lib/models.dart`, `lib/profile_screens.dart`, `lib/settings_screen.dart`, `lib/session_screen.dart`, `lib/koach_screens.dart`, `lib/notification_settings.dart`, `android/app/src/main/kotlin/fr/tchoupi/streetlift_tracker/MainActivity.kt`, `tools/generate_brand.py`, `docs/CONFIDENTIALITE.md`, `pubspec.yaml` (4.3.0+70), `README.md`, `SUIVI_PROJET.md`. Aucun fichier supprimé ; aucune dépendance ni permission ajoutée ; aucun test existant modifié.

## 9. Branche de refonte muscles/animations

`refonte/muscles-animations` (4.2.1) est basée sur 4.2.0 : main est désormais en 4.3.0. Si tu donnes ton accord de fusion (D-MA-00), elle devra d'abord être remise à jour sur 4.3.0 (correctif suivant).
