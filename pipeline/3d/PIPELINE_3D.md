# Pipeline « Mannequin 3D » Kalis Track — règles communes (propriétaire : Gaël, 27/09/2026)

Tu es lancé par la tâche planifiée « Kalis Track — pipeline mannequin 3D », dans une session neuve, **sans personne pour répondre en direct**. Ce pipeline remplace progressivement l'affichage des muscles et les démonstrations 2D par un mannequin anatomique 3D animé. **Un lot = une seule action**, dont le résultat se constate dans l'application après la mise à jour. Concentre-toi sur ton lot : ne fais rien qui appartienne à un autre lot.

## 1. Démarrage
(Depuis M4c, 5.3.2, `main` contient directement les sources du projet Flutter à sa racine : plus de ZIP. Le dernier état livré en ZIP est au commit 4531346 de `main`.)
1. `add_repo` mikeriin/streetlift-apk en accès `push`, puis clone (commande donnée par l'outil).
2. `git fetch origin pipeline` ; lis ce fichier, `pipeline/3d/ETAT_3D.md` et `pipeline/3d/DECISIONS_3D.md`.
3. Ton lot est le **premier lot du tableau §8 dont le statut n'est pas « livré »** dans `ETAT_3D.md`. Lis son prompt `pipeline/3d/prompts/M<NN>.txt` (numéro sur 2 chiffres : M1 → `M01.txt`, M4b → `M04b.txt`, M4c → `M04c.txt`) et exécute-le intégralement. Si ce lot est marqué « en cours » depuis plus de 6 h, repars de l'état réel du dépôt (commits, branches) sans refaire ce qui est poussé.
4. Base : les sources sur `main` (`version:` de `pubspec.yaml`). Vérifie la version prérequise (§8). Si elle ne correspond pas : notification d'échec (§5) et arrêt.
5. Marque ton lot « en cours » dans `ETAT_3D.md` et pousse `pipeline`.

## 2. Décisions du propriétaire (27/09/2026) — ne pas remettre en cause
- Moteur : **flutter_scene** (Flutter GPU, Impeller), Flutter ≥ 3.47 stable. Pas d'autre moteur sans son accord.
- Modèle : `models/full-body-male-mobile.glb` du dépôt github.com/slfresh/fitmitwith-anatomy-atlas (Z-Anatomy / BodyParts3D, 218 régions, CC BY-SA 4.0), carte `maps/full-body-map.json`. Un seul mannequin homme. Page de référence validée par le propriétaire : https://claude.ai/artifact/AT93ttC1hE5WCTDBmbRCcZ (lis-la avec l'outil Artifact, action read : couleurs, éclairage, halo, correspondance des groupes, retrait de l'aponévrose des obliques devant le droit de l'abdomen).
- Tête sombre et lisse (comme `front_base.png` historique), musculature grise mate. Os visibles en gris sombre discret, réglage utilisateur « Os visibles » activé par défaut.
- Mise en évidence : rampe historique bordeaux → rouge (`heat()` de `lib/muscle_body.dart` : `Color.lerp(burgundy #6B0C0C, haut, .15 + .85·v)`, haut = #E85959 en sombre, #A61717 en clair), indépendante de la couleur dominante ; principal 1, secondaire 0,62, stabilisateur 0,35 ; halo (bloom limité aux muscles sollicités). La liste des muscles en texte reste toujours affichée (jamais l'information par la couleur seule).
- (28/09/2026) Anatomie complète : tous les muscles, profonds compris, sont affichés à 50 % d'opacité, pour voir les muscles sollicités cachés. Filtres de l'écran Anatomie : menu déroulant de cases à cocher qui se superposent (lot M4b).
- Toucher un muscle affiche son nom, si le réglage « Nom du muscle au toucher » est activé (activé par défaut).
- Manipulation : rotation libre au doigt + boutons Face / Dos / Profil / 3/4. Zoom au pincement ajouté le 28/09/2026 (lot M4c). Vue de départ d'une animation choisie automatiquement selon le plan du mouvement.
- Matériel simplifié à l'échelle réelle, cohérent avec le style (gris neutres, sans texture criarde) ; lest visible quand l'exercice est lesté.
- Intensité des muscles modulée par la phase (concentrique plus vive, excentrique plus douce, pulsation lente en isométrie). Vitesse = tempo de l'exercice (pack).
- Emplacements : fiche exercice, séance en cours, STATS, écran Anatomie, aperçu au choix / remplacement d'un exercice.
- Ordre de conversion : exercices du programme du propriétaire d'abord, puis par familles.
- Téléphone incompatible : repli sur la carte 2D historique et postures fixes du mannequin.
- Poids ajouté à l'APK : objectif ≤ 10 Mo, tolérance 20 Mo.
- Erreurs fréquentes montrées en « fantôme » : lot dédié après les conversions.
- Mode : chaque lot passe sur `main` dès que les contrôles sont verts, puis lance le suivant (exception : M1, voir son prompt).

## 3. Règles techniques communes
- **Jamais d'animation fausse** : un exercice dont l'animation 3D ne passe pas ses contrôles garde son affichage actuel (démonstration 2D existante, ou posture fixe) et est listé dans la livraison.
- Tant que la conversion n'est pas finie, les exercices non convertis gardent la démonstration 2D actuelle (`lib/pose_cutout.dart`, `pose_engine.dart`) ; aucun écran ne doit perdre son contenu.
- Rendu économe : on ne dessine que ce qui est visible ; scène fixe = rendu à la demande (pas de boucle continue) ; animations en pause hors écran et en arrière-plan ; réduction des animations Android = images clés fixes.
- Budgets de référence : 60 images/s visées ; mannequin d'exécution ≤ 60 000 triangles ; clip ≤ 5 Ko compressé ; mémoire des textures mesurée et consignée.
- Blender sans interface : `pip install bpy --break-system-packages` (version 4.x compatible Python 3.11). Tous les scripts de fabrication des ressources sont dans les sources (`tools/anatomy/`), relançables, et leurs sorties vérifiées par des tests.
- Licence : ressources dérivées du modèle sous CC BY-SA 4.0, crédits exacts (texte de `ATTRIBUTION.txt` du dépôt source) dans `assets/anatomy/ATTRIBUTION.md` et l'écran « Sources et licences » ; le code reste sous sa licence.
- Ne supprime aucune fonctionnalité, ne touche ni aux données de l'utilisateur, ni au format de sauvegarde, ni à l'identifiant Android, ni à la signature (`signing/`) ; ne reproduis aucun secret.

## 4. Contrôles, CI et économie de crédits
- Pas de SDK Flutter local (proxy) : regroupe formatage, analyse, tests, build et captures en **un minimum de passages** sur la branche temporaire `claude/ci-3d` (workflow `.github/workflows/ci-3d.yml`, créé en M1 ; jamais `claude/ci-tools`). Depuis M4c : pose l'arbre du lot sur la tête de `claude/ci-3d` (`git commit-tree <arbre> -p origin/claude/ci-3d`, puis push de ce commit : avance rapide, sans réécriture), méthode dans `docs/CI_3D.md` ; le push déclenche aussi un build signé de contrôle (`build-apk.yml`). Les captures d'écran sont recommitées sur cette branche par la CI (pas d'artefacts à télécharger).
- Contrôles obligatoires à chaque lot : `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, suite Dart complète, tests Python (`tools/tests`, `verify_project.py`), `package_release.py --check` et `check_release_without_secrets.py --tree` (arbre suivi, fichier par fichier, avant chaque push). Aucune assertion retirée, aucun test désactivé.
- Contrôle visuel obligatoire : captures du vrai rendu (émulateur en CI, méthode établie par M1), que tu **regardes** (outil Read) avant de livrer. Corrige tant qu'un rendu est faux.
- Lis seulement les fichiers utiles au lot ; pas de sous-agents sauf nécessité réelle ; rapports concis.
- Émulateur sans GPU (rendu 3D sur processeur, 3 à 7 s par image) : garde le rendu court. Jamais de `pumpAndSettle` ni d'attente « jusqu'à stabilité » sur un écran qui contient une vue 3D (nombre fixe de `pump`) ; délai par test de capture ≤ 5 min et délai du job émulateur ≤ 30 min, pour qu'un blocage échoue vite au lieu d'user 90 min ; captures limitées aux écrans du lot (pas de re-capture des lots précédents) ; résolution d'émulateur réduite (par exemple 480 × 854) si la lisibilité des captures reste bonne. La première passe CI d'un lot qui touche `ci-3d.yml` applique ces règles.

## 5. Décisions, blocages, notifications (PushNotification, < 200 caractères, une ligne)
Tranche toi-même tout choix réversible compatible avec le §2, et consigne-le dans `pipeline/3d/DECISIONS_3D.md` (section de ton lot). Arrête-toi et notifie seulement si : (a) risque de perte de données ; (b) contradiction avec une décision du §2 qui change le résultat ; (c) accès ou outil indispensable manquant ; (d) build ou tests encore en échec après 2 corrections sérieuses ; (e) impasse avérée de flutter_scene (version, message, essais faits).
- Livraison : `Kalis Track <LOT> livré — v<version>. À voir : <ce que le propriétaire constate, en une phrase>`
- Décision : `Kalis Track <LOT> : décision requise — <question>` (question détaillée dans DECISIONS_3D.md avec 2-3 options et ta recommandation ; attends la réponse dans cette session).
- Échec : `Kalis Track <LOT> bloqué — <cause courte>`

## 6. Page de suivi
Une seule page claude.ai « Suivi mannequin 3D » (outil Artifact ; charge d'abord la skill artifact-design), créée par M1, puis **republiée au même lien** par chaque lot (paramètre `url`, lien noté dans `ETAT_3D.md`). Chaque lot y ajoute sa section en tête : version, ce qu'il faut regarder dans l'appli (chemin exact des écrans), 2 à 4 captures ou GIF du vrai rendu, résultats des contrôles, limites. Lisible sur téléphone.

## 7. Fin de lot
1. Version : celle du tableau §8 (pubspec `version: x.y.z+N` avec N = N précédent + 1, réglages / À propos), README et SUIVI_PROJET.md complétés (section du lot).
2. Publie en poussant tes commits de sources sur `main` (avance rapide uniquement ; si `main` a bougé, remets-toi à jour puis relance les contrôles) ; vérifie que le run `build-apk.yml` signé réussit sur le commit poussé.
3. `LIVRAISON_<LOT>.md` dans le projet claude.ai (outil Projects, `claude/LIVRAISON_<LOT>.md`) et dans `pipeline/3d/livraisons/`.
4. Mets à jour `ETAT_3D.md` (lot, version, commit, run, date, statut « livré », lien de la page) et pousse `pipeline` (jamais de sources du projet sur cette branche).
5. Relance la tâche planifiée du pipeline (`fire_trigger`, identifiant en tête de `ETAT_3D.md`) pour le lot suivant, sauf si le prompt de ton lot dit d'attendre ; puis notifie la livraison. Après M19 : notification « Pipeline mannequin 3D terminé — installer v<version> ».
Interdits : modifier ou créer une tâche planifiée (seulement `fire_trigger` sur celle d'ETAT_3D.md), supprimer une branche, modifier la signature ou l'identifiant, régénérer une clé, pousser un secret, pousser sur `main` des sources dont les contrôles ne sont pas verts, réécrire l'historique de `main` (pas de force-push), y ajouter un ZIP du projet.

## 8. Enchaînement
| Lot | Prérequis sur main | Version | Action unique | Constat du propriétaire | Effort |
| --- | --- | --- | --- | --- | --- |
| M1 | 4.3.1 | 5.0.0 | Socle : Flutter ≥ 3.47, Flutter GPU, CI 3D + captures émulateur, écran « Moteur 3D » | Appli identique ; Réglages › À propos › Moteur 3D : rendu test + compatibilité du téléphone | normal |
| M2 | 5.0.0 | 5.1.0 | Modèle anatomique d'exécution + écran Anatomie + réglages 3D + licences | Écran Anatomie : rotation, vues, nom du muscle au toucher | normal |
| M3 | 5.1.0 | 5.2.0 | Fiche exercice : mannequin fixe avec les muscles de l'exercice | Chaque fiche montre le mannequin coloré + la liste | normal |
| M4 | 5.2.0 | 5.3.0 | STATS : résumé hebdomadaire sur le mannequin | STATS montre les groupes de la semaine sur le mannequin | normal |
| M4b | 5.3.0 | 5.3.1 | Tous les muscles remis, transparence à 50 %, filtres à cocher, petite refonte de l'écran Anatomie | Muscles sollicités visibles à travers les autres ; menu « Filtres » à cocher | normal |
| M4c | 5.3.1 | 5.3.2 | Dépôt en sources : plus de ZIP, projet structuré à la racine, CI et outils adaptés ; zoom au pincement ; filtres normalisés (menu déroulant à cocher par catégorie) | Sur GitHub, les dossiers du projet au lieu du ZIP ; zoom au pincement ; mêmes filtres partout | normal |
| M5 | 5.3.2 | 5.4.0 | Squelette d'animation et peau du modèle | Anatomie : 4 postures de référence sans déchirure | **accru** |
| M6 | 5.4.0 | 5.5.0 | Matériel 3D + chaîne de calcul des animations + 3 pilotes | Traction, dips, squat animés dans leur fiche | normal |
| M7 | 5.5.0 | 5.6.0 | Lecteur complet + intensité par phase | Lecture/pause, curseur, tempo, phases, muscles qui « respirent » avec la phase | normal |
| M8 | 5.6.0 | 5.7.0 | Conversion : exercices du programme du propriétaire | Tout son programme animé en 3D | normal |
| M9 | 5.7.0 | 5.8.0 | Conversion : tirages (vertical, horizontal) | Famille animée | normal |
| M10 | 5.8.0 | 5.9.0 | Conversion : poussées (verticale, horizontale) | Famille animée | normal |
| M11 | 5.9.0 | 5.10.0 | Conversion : jambes (squat, charnière de hanche, fente) | Famille animée | normal |
| M12 | 5.10.0 | 5.11.0 | Conversion : figures statiques et dynamiques | Figures animées ou posées | **accru** |
| M13 | 5.11.0 | 5.12.0 | Conversion : gainage (3 types), flexion du tronc, mobilité | Famille animée | normal |
| M14 | 5.12.0 | 5.13.0 | Conversion : isolation, portés | Famille animée | normal |
| M15 | 5.13.0 | 5.14.0 | Conversion : conditionnement, locomotion, hors catégorie | Tout le catalogue traité | normal |
| M16 | 5.14.0 | 5.15.0 | Fantôme des erreurs fréquentes | Bouton « Erreur fréquente » sur les fiches concernées | normal |
| M17 | 5.15.0 | 5.16.0 | Séance en cours : animation de l'exercice actuel | Écran de séance animé | normal |
| M18 | 5.16.0 | 5.17.0 | Aperçu au choix / remplacement d'un exercice | Aperçu animé dans les listes de choix | normal |
| M19 | 5.17.0 | 5.18.0 | Nettoyage : repli appareils incompatibles, suppression du moteur 2D, fluidité, poids | Appli plus légère, aucune régression | normal |

Effort **accru** : raisonne en profondeur avant chaque choix de squelette, de poids de peau ou de cinématique ; vérifie chaque rendu deux fois sous plusieurs vues ; privilégie l'exactitude au volume.
