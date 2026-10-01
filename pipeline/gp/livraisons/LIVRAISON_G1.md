# LIVRAISON G1 — Mode dev, session de test isolée, CI des paquets (6.0.0+94)

- **main** : b3a3d73 (avance rapide depuis 601a04d, fusion de `claude/g1-6.0.0` demandée par le propriétaire le 01/10/2026).
- **Build signé** : run 36813381709 sur main (même commit déjà construit et signé : run 36792378355).
- **CI GP** (claude/ci-3d) : run 36791220317 — formatage, analyse, 1 019 tests Dart, 10 tests du mode dev (KALIS_DEV=true), Python, `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`, tâche `packages` (aucun paquet), émulateur G1 a (sombre) + b (clair, redémarrage à froid réel) verts. `visual_capture_test` en échec comme sur main 5.10.1 (préexistant).
- **Page de suivi** : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5

## Livré
- Drapeau `kDevBuild` (`lib/dev/dev_flags.dart`) ; APK avec `--dart-define=KALIS_DEV=true`, AAB sans ; `verify_android_artifacts.py --dev-apk` exige le code du mode dev dans l'APK et son absence dans l'AAB.
- 5 appuis (≤ 2 s entre deux) sur le logo de l'en-tête → session de test vierge (installation neuve), logo rose #FF1493 (ouverture comprise), étiquette DEV au bord droit (TalkBack : « Session de test active »).
- Appui long de 3 s sur le logo rose (anneau, relâcher ou glisser annule, durée préservée avec « Réduire les animations ») → suppression directe, vibration, « Session de test supprimée », retour à la session personnelle identique.
- Isolation : `KalisPrefs` (clés personnelles inchangées, clés de test préfixées), `SessionHost` (redémarrage logique), rappels rattachés au magasin actif, export marqué `sessionDeTest`, avertissement à l'import en session personnelle, Affichage 3D par session.
- `KalisClock` : horloge unique ; voyage dans le temps en jours civils (outils de test : +1 jour, +1 semaine, date au choix, aujourd'hui), export JSON par le menu de partage, emplacements du simulateur et de l'inspecteur (G10).
- CI : tâche `packages`, tests du mode dev, `docs/CI_GP.md`, cible émulateur `mode_dev_g1_test`.
- Réglages › À propos : « Build de développement ».

## Tests retirés
Aucun. `wod_acquisition_test.dart` : horloge de la vitrine fixée (échec selon le jour), aucune assertion retirée.

## À tester
Accueil › 5 appuis sur le logo → installation neuve, logo rose ; quelques écrans ; fermer/rouvrir → toujours en test ; DEV (appui long) › Outils de test › Avancer d'une semaine ; appui long 3 s sur le logo → retour à ta session, rien n'a bougé (séances, historique, réglages, couleur).

## Limites
Chronos et rappels Android à l'heure réelle ; 5 appuis pendant une session de test ne font rien ; simulateur et inspecteur en G10.
