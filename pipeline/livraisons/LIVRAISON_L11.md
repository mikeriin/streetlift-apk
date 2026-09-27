# Livraison L11 — Kalis Track 4.1.0 (Koach étendu : adaptation au jour le jour)

**27 septembre 2026 — lot exécuté par le pipeline automatisé.** Tickets KT-058 à KT-064.

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 4.0.0+67 (L10), `main` `5d38177`, SHA-256 `2cd7c9a5…50affc` |
| ZIP publié | `streetlift_tracker_v33.zip`, 2 198 067 octets, 478 fichiers (6 068 993 octets extraits), SHA-256 `e598e0fc4be71f25a198b324fcd1b25e9eedd5b0138af786621c6cfb6cf0ad78`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` ; `lib/`, `test/`, `assets/`, `tools/` identiques à l'arbre testé en CI (`claude/ci-tools` `57d48f6`) |
| Commit `main` | `b202121` |
| Build signé | Run **n° 89** (id 36315965310) **réussi** le 27/09/2026 11:30-11:43 UTC : contrôle du ZIP et du workflow, formatage, analyse, tests de régression, icônes, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés avec le même numéro, artefacts vérifiés. Artefacts : `kalis-track-apk` (28 963 682 octets), `kalis-track-aab` (29 643 603), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36315965310 |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- **Ton installation reste en mode Assisté** (fonctionnement de Koach en 3.x/4.0) tant que tu ne choisis rien : aucune charge ne change sans ton tap. Mode modifiable dans **Réglages → Adaptation au quotidien** (Guidé, Assisté, Expert).
- **Menu ⋮ de la séance** : « J'ai seulement… minutes » (aperçu puis application ; « Séance complète » pour revenir), « Échanger un exercice » (3 propositions, première série = calibrage), « Je m'entraîne ailleurs ».
- **Après un arrêt de 7 jours ou plus** : un bandeau d'une ligne en haut de la séance propose l'allègement (−10 / −20 / −30 % sur les mouvements principaux) ; touche-le pour « Appliquer » ou « Garder le prévu ».
- **Séances manquées** : carte en bas de l'accueil « Reprendre là où tu t'es arrêté » (le départ est décalé, annulable dans l'historique d'Adaptation au quotidien). Rien n'est doublé, l'historique ne bouge pas.
- **Vacances / maladie** : Réglages → Adaptation au quotidien ; rappels suspendus pendant la pause ; « Je reprends » fait glisser le programme jusqu'à aujourd'hui.
- Assiduité, palier (plateau) et charge de la semaine : cartes en bas de l'accueil, uniquement quand c'est pertinent.
- Aucune donnée migrée ; export identique à 4.0.0 tant que tu n'utilises aucune de ces fonctions.

## 3. Installation

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du run ci-dessus ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir l'application : aucun écran nouveau au démarrage.

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Accueil, semaine, séances, historique, records, WOD, Koach, Mon programme identiques à 4.0.0 ; Réglages → version 4.1.0.
2. Réglages → **Adaptation au quotidien** : « Assisté (actuel) » ; texte lisible à 200 %.
3. Ouvrir une séance à venir → ⋮ → « J'ai seulement… minutes » → 30 min : aperçu (durée avant → après, séries, exercices enchaînés, retirés) → Appliquer → bandeau « 30 min » ; ⋮ → « J'ai seulement… » → « Séance complète » : tout revient.
4. ⋮ → « Échanger un exercice » → un accessoire → motif → choisir → le nom change ; rouvrir → « Exercice d'origine ».
5. Si tu n'as pas fait de séance depuis 7 jours ou plus : le bandeau « Reprise… allègement proposé » apparaît ; « Garder le prévu » ne change rien.
6. (Facultatif) Je pars en vacances → carte de pause sur l'accueil → « Je reprends » : la prochaine séance tombe aujourd'hui ; l'annuler via l'historique si tu ne le voulais pas.

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-058 à KT-064 |
| Testé automatiquement | CI `claude/ci-tools` `57d48f6` : format, analyse sans problème, **758 réussis / 12 ignorés** (689 existants inchangés + 69 L11), tests ciblés L5/L6 155/155, Python 72/72, `verify_project.py`, build debug ; puis rejoués par le build signé |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; décisions D-L11-01 à D-L11-14 (`docs/CONTRAT_L11.md` §2) ; registre de validation (§10, contenu sportif non relu par un professionnel diplômé) |

## 6. Décisions prises par défaut

Voir `docs/CONTRAT_L11.md` §2. Les plus visibles : le plan glisse **sur proposition** (décision L4 « pas de décalage automatique » respectée hors pause) ; installation existante et profil migré jamais choisi → mode Assisté ; « une séance de moins / de plus » seulement pour un programme généré (programme de 40 semaines : séances 20 % plus courtes) ; novice traité comme débutant pour le plateau ; décharge programmée mais nouveau bloc à régénérer à la main.

## 7. Fichiers modifiés

Nouveaux : `lib/koach_adapt.dart`, `lib/adapt_store.dart`, `lib/adapt_screens.dart`, `docs/CONTRAT_L11.md`, `test/l11_adapt_test.dart`, `test/l11_store_test.dart`, `test/l11_screens_test.dart`. Modifiés : `lib/store.dart`, `lib/koach_store.dart`, `lib/models.dart`, `lib/session_screen.dart`, `lib/koach_screens.dart`, `lib/koach_widgets.dart`, `lib/home_screen.dart`, `lib/settings_screen.dart`, `lib/notifications.dart`, `lib/session_history.dart`, `pubspec.yaml` (4.1.0+68), `README.md`, `SUIVI_PROJET.md`. Aucun fichier supprimé ; aucun test existant modifié.
