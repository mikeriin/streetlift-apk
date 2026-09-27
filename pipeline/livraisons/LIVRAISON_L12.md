# Livraison L12 — Kalis Track 4.2.0 (Motivation et progression visible)

**27 septembre 2026 — lot exécuté par le pipeline automatisé.** Tickets KT-065 à KT-071.

## 1. Publication

| Élément | Valeur |
| --- | --- |
| Base | 4.1.0+68 (L11), `main` `b202121`, SHA-256 `e598e0fc…cf0ad78` |
| ZIP publié | `streetlift_tracker_v33.zip`, 2 254 226 octets, 486 fichiers (6 252 591 octets extraits), SHA-256 `71f975ab02a7ae3b08593705752c6c8c8cbf8adcbca0e9583d75efa6eb5b6335`, racine `streetlift_tracker/`, contrôlé par `tools/package_release.py --check` ; `lib/`, `test/` identiques à l'arbre testé en CI (`claude/ci-tools` `0282f74`) |
| Commit `main` | `332e292` |
| Build signé | Run **n° 90** (id 36320483043) **réussi** le 27/09/2026 12:53-13:10 UTC : contrôle du ZIP et du workflow, formatage, analyse, tests de régression, icônes, refus sans secrets, clé existante restaurée et contrôlée, APK et AAB signés avec le même numéro, artefacts vérifiés. Artefacts : `kalis-track-apk` (29 199 441 octets), `kalis-track-aab` (29 880 837), `kalis-track-validation` — https://github.com/mikeriin/streetlift-apk/actions/runs/36320483043 |
| Workflow `build-apk.yml` | Inchangé (copie du projet identique à `.github/workflows/`) |

## 2. Ce qui change pour toi

- **STATS → « Mes progrès »** (ou Réglages → **Motivation et progression**) : ton installation est au niveau intermédiaire par défaut (pas de profil généré) → victoires, records récents, courbes simples, assiduité, poids (bouton « Masquer »). « Afficher toutes les statistiques » ajoute les statistiques de Koach.
- **Mes figures** : chaînes de progression (étape atteinte, en cours avec son critère, suivante).
- **Étapes franchies** : records, étapes de chaîne, cycles terminés, semaines régulières. Une célébration apparaît en bas de l'accueil pour une étape de moins de 7 jours, une seule fois (« Continuer »). Ton historique ancien n'est pas célébré en rafale.
- **Crédits : rien ne change** — le barème de récompenses des étapes est seulement proposé (voir §6).
- **Bilan de la semaine** en bas de l'accueil chaque lundi (« Vu » pour le ranger) ; **bilan de fin de cycle** le lendemain de la fin d'un bloc.
- **Rappels** : plus jamais un jour de repos (le réglage « Ignorer les jours de repos » a disparu, il est toujours actif).
- **Ton de Koach** réglable (Bienveillant, Exigeant, Neutre) dans Motivation et progression.
- **Partager ma progression** (depuis Mes progrès) : image créée sur le téléphone, poids décoché par défaut, menu de partage Android.
- Aucune donnée migrée ; export identique à 4.1.0 tant que tu ne touches à aucun de ces réglages.

## 3. Installation

1. **Avant** : Réglages → Sauvegardes → « Exporter une sauvegarde » (fichier gardé hors du téléphone).
2. Télécharger l'artefact `kalis-track-apk` du run ci-dessus ; installer **par-dessus** la version actuelle (même signature, pas de désinstallation).
3. Ouvrir l'application : aucun écran nouveau au démarrage.

## 4. Vérifications sur téléphone (à faire, rien n'est vérifié sur appareil)

1. Réglages → version 4.2.0 ; accueil, séances, historique, records, WOD, Koach identiques.
2. STATS → Aperçu → tout en bas « Mes progrès » : victoires, records, courbes ; « Masquer » le poids ; texte lisible à 200 %.
3. Mes progrès → Mes figures → une chaîne → étapes avec libellés « atteinte / en cours / suivante » et critère.
4. Mes progrès → Partager ma progression → cocher/décocher → « Partager » → le menu Android s'ouvre avec l'image (tester l'envoi vers une messagerie ou « Enregistrer »).
5. Réglages → Motivation et progression → ton « Exigeant » : l'exemple change.
6. Réglages → Rappels de séance : plus d'interrupteur « Ignorer les jours de repos » ; le prochain rappel tombe un jour de séance.
7. Lundi prochain : carte « Bilan de la semaine » en bas de l'accueil ; « Vu ».

## 5. Statut

| Statut | Éléments |
| --- | --- |
| Corrigé dans le code | KT-065 à KT-071 |
| Testé automatiquement | CI `claude/ci-tools` `0282f74` : format, analyse sans problème, **809 réussis / 12 ignorés** (758 existants dont 3 adaptés à la règle des rappels + 51 L12), tests ciblés L5/L6 155/155, Python 72/72, `verify_project.py`, build debug ; puis rejoués par le build signé |
| Vérifié sur appareil | Rien |
| Reste à valider | §4 ; décisions D-L12-01 à D-L12-12 (`docs/CONTRAT_L12.md` §2) ; **barème des récompenses** (§5 du contrat) ; registre de validation (§9, contenu sportif non relu par un professionnel diplômé) |

## 6. Décisions prises par défaut

Voir `docs/CONTRAT_L12.md` §2. Les plus visibles : barème en crédits proposé (étape de chaîne 2, cycle 3, régularité 4/8/12/26/52 semaines : 1/1/2/3/5, record 0) **non appliqué** ; semaine régulière = 3/4 des séances prévues, jours de repos respectés comptés ; célébration seulement pour une étape de moins de 7 jours ; parcours d'habitude des débutants par compression à 20 minutes (désactivable) ; rappels jamais un jour de repos (3 tests existants adaptés : 280 → 240 rappels, contrôle du changement d'heure déplacé au lundi 26/10).

## 7. Fichiers modifiés

Nouveaux : `lib/motivation.dart`, `lib/motiv_store.dart`, `lib/motivation_screens.dart`, `android/app/src/main/kotlin/fr/tchoupi/streetlift_tracker/ShareProvider.kt`, `docs/CONTRAT_L12.md`, `test/l12_motivation_test.dart`, `test/l12_store_test.dart`, `test/l12_screens_test.dart`. Modifiés : `lib/store.dart`, `lib/adapt_store.dart`, `lib/notifications.dart`, `lib/notification_settings.dart`, `lib/home_screen.dart`, `lib/settings_screen.dart`, `lib/stats_screen.dart`, `lib/stats_overview.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/fr/tchoupi/streetlift_tracker/MainActivity.kt`, `test/notifications_test.dart`, `test/l4_depart_test.dart`, `pubspec.yaml` (4.2.0+69), `README.md`, `SUIVI_PROJET.md`. Aucun fichier supprimé ; aucune dépendance ni permission ajoutée.
