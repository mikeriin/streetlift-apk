# Kalis Track 5.5.3 — Mannequin anatomique 3D

## 5.5.3 — Muscles opaques, zone ciblée, le modèle partout (correction 3 du lot M56)

- **Muscles à 100 %** : plus de transparence (`kMuscleOpacity` 1) ; l'écorché n'a pas de couche profonde à voir par transparence.
- **Zone ciblée** : sur le mannequin, les muscles qui s'allument sont ceux des fiches du pack des exercices (principaux 1, secondaires 0,6, pondérés par les séries), plus le groupe entier (`TargetedMannequin`, `targetedRegionIntensities`) : semaine de STATS (`AppStore.weeklyNames`), séance du jour sur l'accueil, aperçu d'un WOD. Un exercice sans fiche allume ses groupes comme avant ; la carte 2D par groupe reste le repli sans Flutter GPU.
- **Le modèle remplace les images 2D** partout où elles servaient d'affichage : fiche exercice (le mannequin des muscles ciblés en tête, plus de démonstration 2D en découpes), cartes de séance de l'accueil, aperçu de WOD, STATS. Les images `assets/muscles/` ne servent plus qu'au repli 2D.
- **Plus de rotation au doigt** : les boutons Face / Dos / Profil / 3/4 tournent le mannequin ; le zoom au pincement reste ; les mannequins de carte ne captent aucun geste.

Détail : `SUIVI_PROJET.md` (M56, correction 3).

## 5.5.2 — Écorché acheté, plus d'animation (correction 2 du lot M56)

- **Nouveau modèle** : l'écorché « Ecorche Musclenames Male Anatomy » acheté par le propriétaire (29/09/2026) remplace le mannequin Z-Anatomy : un seul maillage sculpté, chaque muscle repéré par une plage de couleur de sa texture et son abréviation ; `tools/anatomy/build_model.py --zip Archive.zip` (archive dans la release GitHub `modele-achete`, jamais dans le dépôt) segmente la texture, nomme 136 régions (68 muscles × 2 côtés, dont deltoïde, trapèze, grand pectoral et gastrocnémien subdivisés comme dans le pack), regroupe os (`os`), tendons et aponévroses (`contexte`), tête, mains et pieds, et décime le tout à 59 400 triangles sans fissure.
- **Affichage** : muscles gris à 50 % d'opacité (inchangé) ; les muscles sollicités s'allument dans la **couleur dominante** choisie dans Réglages › Apparence (rampe de la teinte principale vers sa nuance vive), sur le mannequin comme sur la carte 2D.
- **Plus d'animation ni de posture** : fiches avec la démonstration 2D historique et le mannequin fixe portant les muscles de l'exercice ; écran Anatomie sans sélecteur « Posture » (squelette, peau, matériel, clips et outils d'animation retirés : `rig.json`, `mannequin_skin.bin`, `animate.py`…). Les positions des exercices seront faites à la main par le propriétaire plus tard.
- **Séance** : plus de boutons Précédent / Suivant (glisser à droite et à gauche suffit) ; carte « Koach · séance du jour » sur sa page.
- **Muscles profonds** : l'écorché ne montre que la couche superficielle ; 20 muscles profonds du pack (petit pectoral, subscapulaire, vaste intermédiaire, rotateurs de la hanche, transverse…) restent en texte sur les fiches (« Absents du mannequin »).

Détail : `SUIVI_PROJET.md` (M56, correction 2). Tests : `tools/tests/test_m2_anatomy.py` (réécrit), `test/m2_mannequin_test.dart`, `m3_fiche_mannequin_test.dart`, `m4b_anatomie_test.dart` (adaptés), `integration_test/animations_m56_test.dart`.

## 5.5.1 — Corrections du propriétaire sur M56 (correction 1 du lot M56)

- **Proportions du mannequin** recalées sur la référence du propriétaire (écorché d'athlète, trois vues) : largeurs de face et profondeurs de profil mesurées sur les images (`tools/anatomy/silhouette.py`) ; cuisses moins larges et plus profondes, pectoraux plats (plus de « plaques »), taille et fessiers plus pleins (dilatation radiale autour du tronc), bras et mollets un peu plus forts, épaules à la largeur de la référence. Tours : bras 37,7 cm, avant-bras 27,8, poitrine 97,1, taille 74,5, cuisse 52,0, mollet 37,5, cou 34,0, bideltoïde 51,0 ; 0 interpénétration > 1 mm.
- **Peau bras levés** : plus d'« omoplates arrachées » ni de boucles sous les aisselles en suspension — os d'insertion (position de l'insertion humérale, orientation du tronc) pour le grand dorsal, le grand rond et les pectoraux, coiffe des rotateurs portée par la scapula (tendon seul collé à la tête humérale), deltoïde tout au bras 4 cm sous la tête, sonnette et bascule de la scapula dans son plan (35°) ; 56 os.
- **Fiches Traction pronation, Dips, Back squat** : plus d'animation en boucle ; le mannequin montre la **position de départ**, puis la **position de fin** (puces sous la vue), avec un fondu doux (instantané si les animations sont réduites). Positions reprises des références d'exécution fournies par le propriétaire (dataset `exercises-dataset`, médias Gym visual, utilisés comme référence seulement) : traction en suspension bras à la verticale, ceinture scapulaire haussée, gainage hollow, genoux fléchis ; dips coudes ouverts (18-26°), bras à l'horizontale en bas, tronc incliné ≈ 23°, cuisses verticales et tibias derrière ; back squat inchangé.
- **Carte « Koach · séance du jour »** sur sa propre page, avant l'exercice 1 (quand Koach a quelque chose à dire à l'ouverture de la séance) ; l'exercice 1 commence page suivante.

Détail : `SUIVI_PROJET.md` (M56, correction 1).

## 5.5.0 — Mannequin musclé, squelette refait, premières animations (lot M56 du pipeline « Mannequin 3D »)

- **Mannequin plus musclé** : physique d'athlète de streetlifting (cibles du propriétaire en fraction de la taille : bras 0,22 H, avant-bras 0,175 H, poitrine 0,62 H, cuisse 0,345 H, mollet 0,22 H, cou 0,22 H, bideltoïde 0,285 H ; tours mesurés au mètre ruban sur l'enveloppe musculaire, moins 2 cm de peau et de graisse ; taille non épaissie). Hypertrophie muscle par muscle (`tools/anatomy/build_body.py`, mesures `measure_body.py`), aucune interpénétration > 1 mm, os, tête, mains et pieds inchangés.
- **Squelette et peau refaits** (`build_rig.py`, `rig_def.py`) : 54 os (30 segments, 18 os d'aide aux tiers de la rotation avec gonflement au pli, 6 os de gonflement de contraction : biceps, quadriceps, grand fessier), axes du coude, du genou et de la cheville mesurés sur les os, rotation tibiale, insertions collées à l'humérus, partage scapula / bras par la hauteur.
- **Fiches Traction pronation, Dips et Back squat** : la démonstration 2D est remplacée par le mannequin animé en boucle au tempo du pack, avec le matériel (barre de traction, barres parallèles, barre olympique et disques, sol), les muscles de l'exercice mis en évidence, la vue de départ automatique, rotation et zoom conservés ; phase et tempo sous la vue ; pause hors de l'écran ; animations réduites : positions clés fixes au choix. Chaîne relançable : `tools/anatomy/animate.py` (fiche biomécanique → cinématique inverse → clip `assets/anatomy/clips/<id>.json.gz` ≤ 5 Ko, contrôles automatiques), `build_equipment.py`, `render_clip.py` (planches et GIF) ; registre `assets/anatomy/clips/index.json` (3D si l'exercice y figure, sinon 2D).
- **Carte « Koach · séance du jour »** en tête de la séance (repliable, ajustements du jour et leurs raisons, actions Koach conservées) ; plus rien de Koach au-dessus du premier exercice.
- **Préchargement au lancement** : modèle, squelette, peau, matériel et registre chargés en tâche de fond une fois l'application prête, pipelines de rendu préchauffés hors écran (`Scene.warmUp`) ; mesures dans Réglages › À propos › Moteur 3D (préchargement, dernier mannequin : première image, images perdues).
- Écran Anatomie : postures de référence recalculées sur le nouveau modèle.

Détail : `SUIVI_PROJET.md` (M56). Tests : `tools/tests/test_m56_body.py`, `test_m56_clips.py`, `test_m5_rig.py`, `test/m5_rig_test.dart`, `m56_clip_test.dart`, `m56_koach_day_card_test.dart`, `m56_preload_test.dart`, `integration_test/animations_m56_test.dart`.


# Historique — Kalis Track 5.4.0 — Mannequin anatomique 3D

## 5.4.0 — Squelette d'animation et peau du mannequin (lot M5 du pipeline « Mannequin 3D »)

- **Arsenal › Anatomie › Posture** : sous les boutons de vue, quatre postures de référence — **Debout**, **Suspendu** (à la barre, scapulas élevées), **Squat bas** (talons au sol) et **Planche** (gainage sur les avant-bras). Le mannequin passe de l'une à l'autre par une transition douce (instantanée si les animations sont réduites) ; la vue s'adapte (Squat bas : 3/4, Planche : Profil) ; la posture est gardée pendant la session.
- Mise en évidence, halo, transparence, filtres, zoom au pincement et **nom du muscle au toucher** restent justes sur le mannequin déformé.
- Fiches, STATS et Moteur 3D : mannequin au repos, identique à 5.3.2.
- Fabrication : `tools/anatomy/build_rig.py` (squelette de 40 os posé sur le squelette d'appui du modèle, poids de peau géodésiques corrigés muscle par muscle), `tools/anatomy/render_poses.py` (planches de contrôle), sorties `assets/anatomy/mannequin.glb`, `rig.json`, `mannequin_skin.bin`.

Détail : `SUIVI_PROJET.md` (M5). Tests : `tools/tests/test_m5_rig.py`, `test/m5_rig_test.dart`, `integration_test/postures_m5_test.dart`.


# Historique — Kalis Track 5.3.2 — Mannequin anatomique 3D

## 5.3.2 — Dépôt en sources, zoom au pincement, filtres normalisés (lot M4c du pipeline « Mannequin 3D »)

- **Dépôt GitHub en sources** : `main` contient directement le projet Flutter (dossiers `lib`, `assets`, `android`, `test`, `tools`…) au lieu de `streetlift_tracker_v33.zip`. Contenu identique octet pour octet au ZIP 5.3.1 (dernier commit qui le contient : `4531346` ; preuve par `tools/compare_tree_with_zip.py`).
- **Zoom au pincement** sur le mannequin 3D (Anatomie, fiche exercice, STATS, Moteur 3D) : deux doigts zooment de 1× (corps entier) à 4×, centré sur le point entre les doigts, et déplacent la vue une fois zoomé ; un doigt tourne le mannequin ; toucher bref = nom du muscle ; double toucher ou boutons Face / Dos / Profil / 3/4 = vue d'ensemble. Dans les fiches et STATS, glisser verticalement fait toujours défiler la page.
- **Mêmes filtres partout** : bibliothèque d'exercices, choix d'exercice (séance perso), catalogue WOD, historique de STATS et écran Anatomie ont un bouton **Filtres · n** qui ouvre un menu par catégorie (cases à cocher, catégories repliables, Tout cocher / Tout décocher, Réinitialiser) ; les filtres actifs s'affichent en puces supprimables sous le bouton.

Détail : `SUIVI_PROJET.md` (M4c). Tests : `test/m4c_zoom_test.dart`, `test/m4c_filter_menu_test.dart`, `tools/tests/test_repository_tree.py`, `integration_test/zoom_filtres_m4c_test.dart`.


# Historique — Kalis Track 5.3.1 — Mannequin anatomique 3D

## 5.3.1 — Anatomie complète en transparence, filtres à cocher (lot M4b du pipeline « Mannequin 3D »)

- **Tous les muscles sont de retour**, profonds compris (rhomboïdes, subscapulaire, supra-épineux, petit pectoral, carré des lombes, multifides, rotateurs de hanche, tibial postérieur… et le platysma) : 21 paires remises dans le modèle.
- **Muscles transparents à 50 %** partout où le mannequin s'affiche (Anatomie, fiche exercice, STATS, Moteur 3D) : un muscle sollicité caché derrière d'autres se voit à travers eux, avec sa couleur et son halo. Os, tête, mains et pieds restent opaques.
- **Toucher** : le muscle sollicité le plus proche sur le trajet du doigt, sinon le plus proche ; la bulle indique « (profond) » pour un muscle profond.
- **Arsenal › Anatomie** : un bouton **Filtres** (nombre de filtres actifs) ouvre un menu de cases à cocher : les 11 groupes (qui s'allument ensemble), « Muscles profonds » (affichés ou masqués) et « Os » ; « Tout cocher » / « Tout décocher » ; le menu se ferme en touchant en dehors ; les filtres restent pendant la session. Mannequin agrandi, boutons Face / Dos / Profil / 3/4 dessous, résumé des groupes cochés et de leurs muscles en dessous.
- Fiche exercice : seuls les muscles absents du modèle (fléchisseurs cervicaux profonds, diaphragme, plancher pelvien) restent listés à part.
- Modèle : 62 506 triangles (≤ 75 000), 1,29 Mo.

Détail : `SUIVI_PROJET.md` (M4b). Tests : `test/m4b_anatomie_test.dart`, `tools/tests/test_m2_anatomy.py`, `integration_test/anatomie_m4b_test.dart`.


# Historique — Kalis Track 5.3.0 — Mannequin anatomique 3D

## 5.3.0 — STATS : résumé hebdomadaire sur le mannequin (lot M4 du pipeline « Mannequin 3D »)

- **STATS › Performances › Muscles sollicités** : le mannequin anatomique 3D remplace la carte 2D face / dos. Chaque muscle prend la couleur de son groupe dans la rampe historique bordeaux → rouge (halo en thème sombre), avec **les mêmes chiffres qu'avant** : séries pondérées de la semaine, ramenées au groupe le plus travaillé, groupes sous 2 % non colorés.
- Bascule **Face / Dos** sous la vue ; rotation au doigt **horizontale** (le glissement vertical fait défiler STATS).
- **Légende chiffrée** : chaque groupe travaillé avec sa valeur (« Dos · 16 »), classés, et une ligne qui explique le calcul (1 pour le groupe principal de l'exercice, 0,6 pour les autres, WOD 0,5 par tour et par mouvement). Semaine vide : mannequin gris et invitation à valider ses séries.
- Rendu à la demande, isolé du reste de la page : le défilement de STATS ne redessine pas la scène.
- Téléphone sans Flutter GPU : carte 2D historique, inchangée.

Détail : `SUIVI_PROJET.md` (M4). Tests : `test/m4_stats_mannequin_test.dart`, `integration_test/stats_semaine_test.dart`.


# Historique — Kalis Track 5.2.0 — Mannequin anatomique 3D

## 5.2.0 — Fiche exercice : mannequin 3D (lot M3 du pipeline « Mannequin 3D »)

- **Fiche exercice › Muscles** : le mannequin anatomique 3D remplace la carte 2D face / dos / profil. Muscles de l'exercice mis en évidence dans la rampe historique bordeaux → rouge : **principal 1, secondaire 0,62, stabilisateur 0,35** (halo en thème sombre) ; **muscles étirés en bleu acier** (0,25, teinte distincte, rappelée dans la légende).
- **Vue de départ** choisie pour montrer les muscles principaux : tous postérieurs → **Dos**, tous antérieurs → **Face**, mixtes → **3/4** (muscles latéraux ignorés ; à défaut, les secondaires décident). Boutons Face / Dos / Profil / 3/4 sous la vue ; rotation au doigt **horizontale** (le glissement vertical fait défiler la fiche).
- **Liste des muscles en texte** conservée sous le mannequin ; les muscles profonds absents du mannequin (sous-scapulaire, rhomboïdes…) sont nommés sous la vue. Toucher un muscle affiche son nom si « Nom du muscle au toucher » est activé.
- La **démonstration animée 2D** reste à sa place (inchangée).
- Ouverture fluide : modèle chargé une fois par lancement et copié pour chaque fiche, rendu à la demande.
- Téléphone sans Flutter GPU : carte 2D historique de la fiche, inchangée.

Détail : `SUIVI_PROJET.md` (M3). Tests : `test/m3_fiche_mannequin_test.dart`, `integration_test/fiche_exercice_test.dart`.


# Historique — Kalis Track 5.1.0 — Mannequin anatomique 3D

## 5.1.0 — Modèle anatomique et écran Anatomie (lot M2 du pipeline « Mannequin 3D »)

- **Arsenal › Référence › Anatomie** (nouveau) : mannequin anatomique en 3D (musculature gris mat, tête, mains et pieds sombres et lisses, os discrets), à tourner au doigt ; boutons **Face / Dos / Profil / 3/4** avec transition ; choix d'un des **11 groupes** (mis en évidence dans la rampe historique bordeaux → rouge, halo en thème sombre) et **liste des muscles du groupe en texte** ; **toucher un muscle affiche son nom** (côté et groupe).
- **Réglages › Affichage 3D** (nouveau) : « Nom du muscle au toucher », « Os visibles », « Halo », activés par défaut (préférences du téléphone, hors sauvegarde).
- **Réglages › À propos › Moteur 3D** : la mesure de fluidité porte désormais sur le mannequin (rotation lente, muscles d'une traction allumés).
- **Sources et licences** : crédits du modèle 3D (écorché acheté, licence commerciale ; Z-Anatomy / BodyParts3D CC BY-SA 4.0 jusqu'à 5.5.1).
- Téléphone sans Flutter GPU : l'écran Anatomie montre la carte 2D historique.
- Technique : modèle fabriqué par `tools/anatomy/build_model.py` (Blender sans interface) depuis fitmitwith-anatomy-atlas, 56 126 triangles, une maille par muscle et par côté ; converti au build par le hook de flutter_scene (`hook/build.dart`) ; widget réutilisable `Mannequin3D` (`lib/mannequin_3d.dart`), rendu à la demande.

Détail : `SUIVI_PROJET.md` (M2). Tests : `test/m2_mannequin_test.dart`, `tools/tests/test_m2_anatomy.py`, `integration_test/moteur_3d_test.dart`, `integration_test/mannequin_mesure_test.dart`.


# Historique — Kalis Track 5.0.0 — Socle du moteur 3D

## 5.0.0 — Moteur 3D (lot M1 du pipeline « Mannequin 3D »)

- **Application identique** pour l'entraînement : aucun écran, aucune donnée ni sauvegarde modifiés.
- **Réglages › À propos › Moteur 3D** (nouveau) : rendu test en 3D (figure grise mate dont le sommet rayonne dans le rouge historique, halo lumineux), à faire tourner au doigt ; diagnostic lisible : **Compatible / Non compatible**, Flutter GPU, API graphique utilisée, modèle du téléphone, version d'Android ; **fluidité mesurée sur 10 s** (images par seconde, temps d'image moyen et 99e centile), bouton « Mesurer à nouveau ». Sans Flutter GPU, l'écran l'indique et l'application garde ses illustrations 2D.
- Cet écran servira à vérifier le mannequin anatomique 3D des prochaines versions.
- Technique : Flutter 3.47.5 (Dart 3.13.4), moteur flutter_scene 0.23.0 sur Flutter GPU / Impeller ; **Android 7.0 minimum** (exigence de Flutter 3.47 ; Android 5 et 6 ne sont plus pris en charge) ; Gradle 8.14.3, Kotlin 2.3.20 ; CI 3D avec rendu réel sur émulateur (`docs/CI_3D.md`).

Détail : `SUIVI_PROJET.md` (M1). Tests : `test/m1_engine3d_test.dart`, `integration_test/moteur_3d_test.dart`.


# Historique — Kalis Track 4.3.1 — Muscles et démonstrations en illustrations anatomiques

## 4.3.1 — Refonte muscles et animations (branche `refonte/muscles-animations`)

- **Carte des muscles d'origine** : STATS, accueil et WOD retrouvent les illustrations anatomiques de 3.1.0 (face / dos, un calque par groupe, rampe bordeaux → rouge avec halo), rendu identique à 3.1.0 avec tes données actuelles.
- **Fiche exercice** : carte face / dos / **profil** (nouvelle vue, dessinée à partir de l'illustration de profil validée par le propriétaire), muscles principaux, secondaires, stabilisateurs et étirés en intensités distinctes, légende et liste en texte conservées.
- **Démonstrations refaites avec ces illustrations** : le personnage est découpé en segments (tête, cou, tronc, bassin, bras, avant-bras, mains, cuisses, jambes, pieds) animés par la cinématique du pack ; les muscles travaillés s'allument pendant le mouvement. Vue de profil pour les mouvements d'avant en arrière, de face pour les mouvements latéraux, **de dos** quand les muscles principaux sont surtout postérieurs. Membre éloigné légèrement assombri de profil. Réduction des animations du système respectée (images fixes).
- **Revue de toutes les démonstrations** : 18 exercices dont l'animation aurait été fausse passent en image fixe juste (développés couchés et inclinés : position haute) ou sans démonstration (contact avec le matériel absent) ; liste dans `SUIVI_PROJET.md` (refonte).
- Aucune donnée modifiée, aucune migration. Contenu sportif **non relu par un professionnel diplômé**.

Détail : `SUIVI_PROJET.md` (refonte muscles et animations). Outils : `tools/muscles_profile.py`, `tools/anim_cutout.py`. Tests : `test/refonte_ma_test.dart`, `tools/tests/test_refonte_muscles.py`.


# Historique — Kalis Track 4.3.0 — S'entraîner en sécurité

## 4.3.0 — Santé, sécurité, conformité et test fermé (lot L13)

- **Avertissement clair** dès le premier écran et dans Réglages → À propos : Kalis Track est une application d'entraînement et de bien-être, pas un dispositif médical ; aucun diagnostic, aucune promesse de résultat.
- **Santé et sécurité** (À propos, et « Douleur ou malaise ? » dans les options de séance) : signaux d'alerte (douleur dans la poitrine, malaise, essoufflement anormal, douleur qui irradie) → arrêter l'effort, 15 ou 112 ; parcours de la douleur ; situations particulières (grossesse, tension ou cœur, 65 ans et plus, reprise après blessure) → mode prudent et avis médical conseillé.
- **Douleur qui dure** : au-delà de 2 séances de suite au-dessus de 3/10 sur un mouvement, Koach te conseille de consulter un professionnel de santé (en plus de l'absence de hausse et de l'allègement déjà en place).
- **Récupération** : conseils généraux (protéines réparties, hydratation, sommeil, régularité) ; aucun calcul de calories, aucun objectif de poids.
- **Politique de confidentialité** consultable dans l'application ; l'export signale qu'il contient tes données de santé. Un profil importé de moins de 18 ans bloque l'application jusqu'à correction.
- **Donner mon avis** (test fermé) : formulaire local, aperçu exact, partage par le menu Android seulement si tu le choisis ; rien d'autre que ce que tu coches.
- Textes relus automatiquement (aucune allégation médicale) ; la note « anti-blessure » d'un accessoire est reformulée.
- Préparation Google Play : visuel 1024 × 500, réponses Sécurité des données et santé, plan du test fermé (`docs/GOOGLE_PLAY.md`, `docs/TEST_FERME.md`).
- Aucune donnée migrée, aucune permission ni dépendance ajoutée. Contenu sportif **non relu par un professionnel diplômé** : `docs/REGISTRE_VALIDATION.md`.

Détail : `docs/CONTRAT_L13.md`, `SUIVI_PROJET.md` (L13). Tests : `test/l13_*_test.dart`, `tools/tests/test_l13_compliance.py`.


# Historique — Kalis Track 4.2.0 — Tes progrès, visibles

## 4.2.0 — Motivation et progression visible (lot L12)

- **« MES PROGRÈS »** (STATS → Mes progrès, ou Réglages → Motivation et progression) : le détail suit ton niveau. Débutant ou novice : des victoires concrètes (« +6 répétitions en pompes depuis ton départ », « Première traction ! », « 5 semaines régulières »), au plus 3 chiffres par écran ; intermédiaire : records récents et courbes simples ; avancé et expert : statistiques complètes de Koach. Réglage **« Afficher toutes les statistiques »** pour tous. Le poids est facultatif, masquable, jamais jugé.
- **« MES FIGURES »** : les chaînes de progression du pack (pompes, tractions, dips, squat, muscle-up, front lever…) — étapes atteintes, étape en cours avec son critère de passage, étape suivante. Les chaînes utiles à ton objectif sont en tête.
- **Étapes franchies** : record, étape de chaîne, cycle terminé, régularité (les jours de repos respectés comptent). Une célébration sobre sur l'accueil, une seule fois, qui respecte la réduction des animations. Récompenses en crédits : barème proposé, en attente de validation (rien n'est modifié dans ton économie).
- **Ton de Koach** : Bienveillant, Exigeant (« entraînement difficile, guerre facile ») ou Neutre, par défaut selon ton niveau. Les messages de sécurité restent toujours neutres.
- **Bilans** : chaque lundi, le bilan de la semaine (une victoire, l'assiduité, le cap) ; à la fin d'un cycle, progrès, point fort, point à travailler, prochain objectif et projection de Koach.
- **Rappels** : à l'heure choisie, uniquement les jours d'entraînement prévus, jamais un jour de repos ni pendant une pause.
- **Partager ma progression** : image créée sur le téléphone, contenu au choix, sans poids ni donnée de santé par défaut, via le menu de partage Android. Aucun serveur.
- **Débutant ou novice** : parcours d'habitude les 4 premières semaines (2 séances de 20 minutes suffisent, désactivable) et séance **« 10 minutes, ça compte »** toujours disponible.
- Aucune donnée migrée. Contenu sportif **non relu par un professionnel diplômé** : des repères d'entraînement, aucune promesse de résultat.

Détail : `docs/CONTRAT_L12.md`, `SUIVI_PROJET.md` (L12). Tests : `test/l12_*_test.dart`.


# Historique — Kalis Track 4.1.0 — Koach s'adapte à ta journée

## 4.1.0 — Adaptation au jour le jour (lot L11)

- **« J'ai seulement… minutes »** (menu de la séance, avant ou pendant) : Koach recompose la séance — échauffement de 3 minutes, mouvements principaux gardés avec au moins 2/3 de leurs séries, accessoires enchaînés deux par deux sans conflit musculaire, prévention à 1 série (jamais supprimée), exercices les moins prioritaires retirés. Aperçu des différences avant de valider ; « Séance complète » pour revenir.
- **Échanger un exercice** (machine prise, gêne, envie) : 3 propositions classées, même type de mouvement, difficulté proche, matériel disponible, jamais un exercice que tu détestes ; en cas de douleur, contrainte articulaire égale ou moindre. La première série sert de calibrage. **Je m'entraîne ailleurs** : toute la séance adaptée au matériel d'un autre lieu.
- **Le plan glisse** : une séance manquée n'est jamais doublée ; Koach propose de reprendre là où tu t'es arrêté (annulable). **Vacances** et **maladie** : calendrier et rappels en pause ; séances d'entretien facultatives en vacances ; au retour de maladie, une semaine plus légère.
- **Reprise après un arrêt** : 7-13 jours → charges −10 % et une série de moins ; 14-27 jours → −20 % et série de calibrage ; 28 jours et plus → −30 % et semaine de calibrage.
- **Assiduité** : sous 60 % des séances faites sur 4 semaines, Koach propose d'alléger (une séance de moins ou des séances 20 % plus courtes) ; au-dessus de 90 % avec progression, une séance de plus si tu le souhaites. **Palier** détecté (moins de +0,5 % par semaine pendant 3 semaines) : conseil selon ton niveau.
- **Modes de Koach** (Réglages → Adaptation au quotidien) : Guidé (Koach applique les baisses et adaptations de sécurité, avec « Annuler »), Assisté (tu valides d'un tap, comme avant), Expert (tout est manuel, suggestions visibles). **Ton installation reste en Assisté** tant que tu n'as rien choisi.
- **Débutant ou novice** : une seule question en fin de séance, la difficulté globale sur 10 ; une semaine nettement plus chargée que d'habitude donne un message de prudence (un simple repère).
- Rien n'est réécrit dans ton historique ; aucune donnée n'est migrée. Contenu sportif **non relu par un professionnel diplômé** : des repères d'entraînement, aucune promesse de résultat.

Détail : `docs/CONTRAT_L11.md`, `SUIVI_PROJET.md` (L11). Tests : `test/l11_*_test.dart`.


# Historique — Kalis Track 4.0.0 — Programme personnalisé

## 4.0.0 — Générateur de programme personnalisé (lot L10)

- **Ton programme est généré pour toi** (nouveau profil) dès que tu choisis ta date de départ : objectifs, jours, durée des séances, lieux et matériel, gênes déclarées, mode prudent. Tous les calculs se font sur le téléphone, sans réseau.
- **Périodisation expliquée** : débutant et novice → progression linéaire ; intermédiaire → séances lourdes, de volume et légères qui alternent ; avancé et expert → blocs accumulation, intensification, réalisation ; « Forme et santé » → corps entier à chaque séance, jamais jusqu'à l'échec, circuit à faible impact et mobilité. Une décharge au moins toutes les 6 semaines. Objectif daté : cycles jusqu'à la date, simulations, affûtage et jour J.
- **Niveau par mouvement** (poussée, tirage, squat, charnière, gainage), qui ne sert qu'à choisir la périodisation et les valeurs de départ ; **tests légers de calibrage** les premières semaines (jamais d'échec, jamais de maximum).
- **Séances ajustées à ton temps** (estimation, échauffement compris, dans ±10 %), échauffement de 5 à 10 minutes avec montée en charge, 48 h entre deux séances lourdes d'un même mouvement, exercices choisis selon le matériel du lieu du jour, tes prérequis et tes gênes, chacun avec une démonstration animée.
- **Une ligne « pourquoi »** pour chaque séance et chaque exercice, simple pour un débutant, technique pour un expert.
- **Réglages → Mon programme** : modèle et explication, niveaux, répartition (Koach décide, corps entier, haut/bas, poussée/tirage/jambes), mouvement ciblé en endurance, séries par groupe, régénération de la suite **après un aperçu « ce qui change »**. Profil modifié : proposition sur l'accueil (mode Guidé : appliquée tout de suite, annulable 7 jours). **Ton historique n'est jamais modifié.**
- **Installation existante (programme de 40 semaines)** : rien ne change. Ton programme devient le modèle « Expert streetlifting », identique jour pour jour ; tu peux générer un programme personnalisé quand tu veux, tes semaines passées restent en place.
- Contenu sportif **non relu par un professionnel diplômé** : des repères d'entraînement, aucune promesse de résultat.

Détail : `docs/CONTRAT_L10.md`, `docs/PROFILS_TYPES_L10.md` (13 profils types), `SUIVI_PROJET.md` (L10). Tests : `test/l10_*_test.dart`, `tools/tests/test_program_models.py`.


# Historique — Kalis Track 3.2.0 — Exercices, démonstrations et atlas

## 3.2.0 — Base d'exercices v2, démonstrations animées et fiches (lot L9b)

- **625 exercices** (505 d'origine + 120 ajoutés par le pack de contenu validé) : types de mouvement, lieux, matériel, difficulté, muscles principaux, secondaires et stabilisateurs, précautions, prérequis, progressions et régressions.
- **Arsenal → Exercices** : recherche (nom, muscle, matériel, lieu, type) et filtres type de mouvement, lieu, matériel, difficulté.
- **Fiche exercice** : démonstration animée (silhouette calculée, muscles colorés selon ta couleur dominante), points clés, erreurs fréquentes, respiration, atlas des muscles avec liste en texte, précautions, prérequis, progressions et régressions sur lesquelles tu peux naviguer. Un geste impossible à montrer fidèlement affiche la position de départ, ou l'atlas et les consignes.
- **Réduction des animations** du téléphone respectée : images clés fixes, numérotées. Bouton pause.
- **Carte musculaire de STATS** redessinée avec l'atlas (51 muscles, face et dos) ; mêmes données, mêmes 11 groupes, même échelle d'intensité.
- **Nouvelle séance** : le choix des exercices utilise la nouvelle base et un bouton ouvre la fiche. **Tes séances, ton historique et tes records ne changent pas** : les noms enregistrés restent valables et sont reliés à la nouvelle base à la lecture.
- Réglages → À propos → **Sources et licences**.
- Contenu rédigé et vérifié sur des sources publiques, **non relu par un professionnel diplômé** : ce sont des repères d'entraînement, pas des conseils médicaux.

Détail : `docs/CONTRAT_L9b.md`, `SUIVI_PROJET.md` (L9b). Tests : `test/l9b_pose_test.dart`, `test/l9b_content_test.dart`, `test/l9b_perf_test.dart`, `tools/tests/test_content_pack.py`. Import du pack : `tools/content_pack_import.py`.


## 3.1.0 — Profil, démarrage court et questionnaire de santé (lot L8)

- **Démarrage court** (installation neuve, 2 minutes au plus) : bienvenue → âge → objectifs → disponibilités → lieux et matériel → repère de niveau (« Combien de pompes d'affilée ? ») → santé → mode et ton → récapitulatif. Rien n'est enregistré avant le récapitulatif.
- **Réservée aux 18 ans et plus** : en dessous, un message l'explique et aucune donnée n'est enregistrée.
- **Objectifs V1** : Forme et santé (proposé en premier), Force, Endurance en répétitions, Préparer un test ou une compétition (épreuves, cibles et date). Objectif secondaire facultatif, répartition 70/30 réglable par pas de 10.
- **Questionnaire de santé** (8 questions, rédaction propre à Kalis Track) après une information claire et ton accord explicite. Une réponse « oui », une gêne au-dessus de 3/10, 65 ans et plus, une grossesse, un problème de cœur ou de tension, un refus ou une absence de réponse → **mode prudent** : pas de test maximal, au moins 3 répétitions en réserve et charges plafonnées à 80 % du 1RM sur les mouvements principaux, conseil de demander l'avis d'un médecin. « J'ai l'accord de mon médecin » (déclaration datée) le lève.
- **Tes données de santé** restent sur le téléphone, figurent dans l'export et sont effacées avec les données de l'application ; accord révocable à tout moment (Réglages → Profil), ce qui les efface.
- **Questions progressives** : une seule question au plus, à la fin d'une séance validée (jamais pendant), avec « Plus tard » et « Ne plus demander ».
- **Installation existante** : ton profil est pré-rempli (feuille Pilotage, objectifs Koach, programme, historique) ; tu le vérifies et le confirmes (ou « Plus tard »). **Aucune date, valeur ni séance n'est modifiée**, et tant que tu n'as pas confirmé, l'application se comporte exactement comme 3.0.3.
- Réglages → **Profil** : consultation, modification, origine de chaque réponse (déclarée, estimée, mesurée), historique « profil modifié ».

Détail : `docs/CONTRAT_L8.md`, `docs/CONFIDENTIALITE.md`, `SUIVI_PROJET.md` (L8). Tests : `test/l8_profile_test.dart`, `test/l8_profile_screens_test.dart`.


## 3.0.3 — Performance (lot L6)

- **Onglets masqués** : pendant une séance (ou sur un autre onglet), une saisie ne reconstruit plus PROGRAMME, STATS, ARSENAL et RÉGLAGES cachés derrière. Chaque zone masquée se met à jour une seule fois, dès qu'elle réapparaît. Une section STATS masquée fait de même.
- **Catalogue WOD** : durées estimées, difficultés et niveaux réutilisés tant que le WOD ne change pas (le cache couvrait mal plus de 1 024 WOD, et chaque lecture réencodait le WOD).
- **Sauvegarde** : la comparaison des 1 000 WOD du catalogue avec leur version d'origine ne réencode plus chacun en JSON à chaque écriture. Même document écrit, mêmes garanties (file d'écriture, accusé, erreurs).
- Rien ne change à l'écran ni dans les données : mêmes couleurs, mêmes textes, même format de sauvegarde, mêmes résultats (vérifié par empreintes sur quatre jeux de données).

Détail et mesures : `docs/PERFORMANCE.md`, `SUIVI_PROJET.md` (L6). Tests : `test/l6_perf_test.dart` ; banc : `test/l6_perf_bench_test.dart` (avec `--dart-define=KALIS_PERF=true`), `tools/perf_compare.py`, `tools/perf_device/`.


## 3.0.2 — Finition globale et six couleurs (lot L5)

- **Couleur dominante au choix** : Réglages → Apparence → « Couleur dominante ». Six couleurs gratuites, hors ligne : Rouge Kalis (par défaut, inchangé), Jaune, Vert, Violet, Orange, Turquoise. Le choix s'applique tout de suite, sans redémarrer, et reste enregistré. Il est indépendant du thème Clair / Sombre / Système.
- **Ce qui change de couleur** : boutons, sélection, liens, jauges (dont la barre de niveau), carte du jour, décor. **Ce qui ne change pas** : erreurs et suppressions, validations, phases des chronos, rangs et rareté des badges, graphiques, couvertures WOD, logo et icône de l'application.
- **PROGRAMME** : semaine, bloc et dates affichés sous le curseur, avec un bouton « Semaines » ; « En cours » écrit sur une séance commencée ; textes de la carte du jour agrandis ; titres complets sur petit écran et grand texte ; « NIV. » suit la taille de texte du téléphone.
- **Grand texte (jusqu'à 200 %)** : titres de page sans mot coupé, choix du thème empilés, cartes du personnage et des crédits réorganisées, branches du parcours empilées, champs des références lisibles.
- Sauvegardes : la couleur fait partie des réglages exportés. Une ancienne sauvegarde (sans couleur) ou une couleur inconnue donne le rouge, sans refuser l'import. Aucune autre donnée n'est modifiée.

Détail : `SUIVI_PROJET.md` (L5), `REFONTE_UI.md`. Tests : `test/l5c_couleur_test.dart`, `test/l5c_selecteur_test.dart` ; rendus : `test/l5c_*_capture_test.dart` (avec `--dart-define=KALIS_CAPTURE=true`).

## 3.0.1 — S11·J6 au nouveau format du J6 (lot LC1b)

À ta demande du 26/09/2026, la séance **S11·J6** (semaine de décharge) prend dès aujourd'hui le format du J6 du Bloc 2 (« PUISSANCE MU + SQUAT ENDURANCE ») :

1. Muscle-ups PdC explosifs — 4×3, 2 min (nouvelle ligne `B1-L1b-001`)
2. Tractions explosives poitrine-barre — 4×3 (5×3 auparavant), consigne du Bloc 2
3. Squat endurance @ 70 kg — **inchangé** : 3 × (0,9 × ton max à 70 kg), RIR 3 ; le test max squat reste en S12·J6
4. Leg raises lestés (suspendu) — 3×10 (2×10 auparavant)
5. Mobilité épaules + poignets — 10 min

Retirés de S11·J6 : isométries transition MU et bas de dip, excentriques de transition lestés, négatifs de muscle-up, transitions à l'élastique, false grip hold, HIIT court. Séries prévues de la séance : 33 → 15. **S12·J6 et le reste du programme ne changent pas.** Le programme compte 1 812 exercices (1 818 − 7 + 1). Un journal déjà enregistré avec un exercice retiré reste lisible tel quel.

Détail : `SUIVI_PROJET.md` (LC1b), script `tools/lc1b_s11_j6.py`.

## 3.0.0 — Koach (lot L7)

**Koach** (Kalis Coach) suit tes séries du programme de 40 semaines et te propose des ajustements de charge. Il est **désactivé par défaut** : active-le dans Réglages → Koach (une explication s'affiche d'abord). Désactivé, charges, séries, séances et journal sont ceux de 2.5.9 ; seules s'ajoutent la section Réglages → Koach et la mention de Koach dans les textes de sauvegarde.

- **Difficulté de la série** : six niveaux, d'« Échec » à « Facile », chacun avec « encore N » (répétitions encore possibles). Koach actif, elle est demandée sur la première et la dernière série des quatre mouvements principaux (muscle-up, traction, dip lestés, back squat) : un tap choisit et valide. Mode avancé : RIR ou RPE dans la colonne habituelle. Sous chaque série validée, la difficulté notée reste modifiable, et une série peut être **écartée** (incident) : elle reste au journal, XP comprise, sans compter dans les estimations.
- **Pendant la séance** : si la série 1 était plus facile que le RIR visé, Koach propose une charge plus lourde pour les séries restantes ; après une série ratée ou deux séries très dures de suite, une charge plus légère. La raison tient en une ligne (« +2,5 kg — série 1 à Soutenu, visé Dur ») : « Appliquer » ou « Garder ma charge ». Jamais de hausse en semaine de décharge, avec une douleur notée au-dessus de 3/10 ou un jour de fatigue accepté.
- **Jour de fatigue** : si la série 1 est nettement sous ton niveau habituel (ou sommeil court, forme basse), Koach propose de retirer 15 à 30 % des séries de la séance parmi celles qui restent (le nombre exact est affiché), charges maintenues.
- **Fin de séance** : bilan Koach avant le bilan de récompenses. Les valeurs de la feuille Pilotage (1RM, maxima, charges des accessoires) ne changent **jamais sans ton accord** : chaque proposition s'accepte ou se refuse d'un tap, avec sa raison ; une valeur peut être verrouillée (« Garder ma valeur »).
- **STATS › Performances → Koach** : 1RM estimés avec leur incertitude, courbe, projection vers ton étape (cible 12 mois du programme) et ton objectif final (à saisir), statut écrit (« dans les temps », « en retard »…), maxima d'endurance, historique daté des valeurs, pesées.
- **Pesées datées** : ton poids du jour sert au calcul des mouvements lestés ; rappel sur l'accueil après 7 jours sans pesée.
- **Matériel** : incréments de tes haltères, disques, barre, poulies (en livres) et machines, modifiables ; les charges suivent ta grille.
- **Options** : questionnaires facultatifs (sommeil, forme, douleur), après une information claire, supprimables à tout moment ; « Koach adapte la structure » (désactivé par défaut) : ±1 série par mouvement ou décharge anticipée pour la semaine suivante, annulable.
- **Tes données** : tout est calculé et conservé sur ton téléphone, sans compte ni connexion. Les données Koach sont dans l'export de sauvegarde et effacées avec les données de l'application. Mise à jour depuis 2.5.x : rien n'est réécrit, Koach reste désactivé jusqu'à ce que tu l'actives.

Koach produit des **estimations d'entraînement**, sans garantie de résultat ; ses paramètres restent à éprouver sur le terrain (voir `docs/CONTRAT_L7.md` §11). Détail : `docs/CONTRAT_L7.md`, `docs/CONFIDENTIALITE_KOACH.md`, `SUIVI_PROJET.md` (L7), `LIVRAISON_L7.md`. Tests : `test/l7_*_test.dart`, `tools/tests/test_koach_reference.py`.

## 2.5.9 — Séances fiables et reprise (lot L4b)

- **Séries validées pour de vrai** : une série ne se coche qu'avec une valeur valide (reps, secondes ou minutes ; 0 seulement pour un test max). Charge avec virgule ou point, négative pour une assistance ; RIR et RPE vérifiés chacun sur son échelle. Si quelque chose ne va pas, le champ est nommé sous la série et ta saisie reste. Une série modifiée avec une valeur invalide repasse « non validée ».
- **Suggestion ≠ performance** : les reps et charges pré-remplies, comme un chrono de tenue terminé, ne comptent qu'une fois la série cochée.
- **Reprise** : une séance commencée est marquée « En cours » et proposée dans « À reprendre » sur l'accueil ; elle rouvre sur l'exercice où tu en étais, avec tes séries. Le repos n'est pas relancé.
- **WOD interrompu** (application tuée, arrêt forcé, redémarrage) : la tentative est retrouvée, chrono en pause au dernier temps enregistré ; « Reprendre » ou « Terminer » pour saisir le score. Un essai commencé avant minuit peut toujours être terminé. Un seul WOD chronométré à la fois.
- **Fin de séance** : le bilan ne s'affiche qu'une fois la séance enregistrée ; en cas d'échec, « Réessayer l'enregistrement », sans double gain.
- **Rappels** : toucher un rappel ramène à la séance déjà ouverte au lieu d'en empiler une seconde ; une journée faite ouvre son historique.
- Chronos : un changement d'heure en arrière ne fait plus remonter un repos ; au retour dans l'application, aucune rafale de bips anciens.

Détail : `docs/SEANCES_ET_REPRISE.md`, `SUIVI_PROJET.md` (L4b). Tests : `test/l4b_seances_test.dart`.

## 2.5.8 — Ton départ, tes références (lot L4)

- **Nouvelle installation** : le programme n'est plus calé sur la date du créateur. L'accueil propose « Choisir mon départ » : la date choisie devient ta séance S1 · J1, quel que soit le jour (jusqu'à 280 jours en arrière pour une reprise, jusqu'à un an à l'avance). « Plus tard » est possible ; tant que le départ n'est pas choisi, les semaines restent consultables et aucun rappel n'est envoyé.
- **Références** : aucune valeur n'est inventée. Poids du corps, 1RM et maxima sont « non renseignés » tant que tu ne les saisis pas (« Je ne sais pas » accepté, aucun test maximal exigé) ; les charges et volumes concernés affichent « à renseigner », les attributs « indisponible » ou « calcul partiel ».
- **Installation existante** : rien ne bouge. Ton calendrier (départ du 13/07/2026), ta semaine en cours, tes séances et leurs dates, tes crédits, tes WODs et tes résultats sont conservés ; tes références restent utilisées, marquées « à vérifier » (« C'est bien ma valeur » quand tu veux).
- **Changer de départ** : Réglages → Programme → Départ du programme, avec l'effet affiché avant de confirmer (« S11 · J6 → S1 · J6 ») ; les séances faites gardent leur semaine, leur jour et leur date réelle ; les rappels sont replanifiés.
- **Fin du programme** : après S40 · J7, « Programme terminé » ; aucun nouveau cycle.
- Sauvegardes : le départ et la provenance des références sont exportés et restaurés ; une ancienne sauvegarde garde le calendrier du 13/07/2026.

Détail : `docs/DEPART_PROGRAMME.md`, `SUIVI_PROJET.md` (L4). Tests : `test/l4_depart_test.dart`.

## 2.5.7 — Bloc 2 (S12-S19) révisé (lot LC1)

Contenu d'entraînement des semaines 12 à 19 révisé selon tes décisions du 26/09/2026 ; le reste du programme et la feuille Pilotage ne changent pas.

- **Sans capteur de vitesse** : tempo « Intention maximale » sur muscle-up, traction, dip et squat lestés ; la série s'arrête quand une rep ralentit nettement ou que la marge passe sous le RIR visé.
- **Séries classiques** en S12, S13, S15 et S19 ; clusters en S14, S16, S17 et S18.
- **Série de calibrage** (série 1) sur les 4 mouvements principaux, avec la règle d'ajustement de charge et du 1RM ; décharges S15 et S19 : aucune hausse.
- **Séances resserrées** : 6 lignes par jour au lieu de 9 à 11 (202 lignes retirées, 66 ajoutées). Nouveautés : squat pause 2 s, GtG muscle-up enregistrable en J3 et J5, muscle-ups PdC explosifs en J6, séries de référence d'endurance (0,6 × ton max) suivies des clusters du reste du volume.
- **S12 = semaine de recalage** : tests max tractions (J4), dips puis pompes (J5), squat 70 kg (J6), en tête de séance. Reporte chaque résultat dans la feuille Pilotage **sans quitter la séance** : menu ⋮ → « Références (feuille Pilotage) ». En revenant, les volumes des lignes suivantes sont déjà recalculés (les reps pré-remplies non validées suivent ; ce que tu as saisi n'est pas écrasé).

Détail : `SUIVI_PROJET.md` (LC1). Tests : `test/lc1_programme_test.dart`, `tools/tests/test_lc1_revision.py`.

## 2.5.6 — Formats WOD fiables (lot L3b)

- **Tabata de bout en bout.** Les 40 Tabata du catalogue ont un vrai déroulement : 8 efforts de 20 s séparés par 10 s de repos, 1 min entre deux mouvements, fin au dernier effort (3 mouvements : 13 min 30 s ; 4 : 18 min 20 s). L'écran nomme la phase en toutes lettres (« EFFORT », « REPOS », « REPOS ENTRE MOUVEMENTS »), le mouvement et l'intervalle ; pause et reprise figent la phase ; pas de rafale de bips au retour dans l'application.
- **Score Tabata conforme à la consigne.** Tu saisis tes reps de chaque intervalle ; l'application prend le plus faible de chaque mouvement (0 compte) et additionne ces minimums. Case vide = non renseignée, jamais zéro ; un Tabata incomplet reste dans l'historique sans devenir un record.
- **Une règle de score par format, affichée.** For Time et rounds : temps le plus court, et tu indiques toi-même si le WOD est terminé (un arrêt rapide ne devient plus un record) ; au-delà du time cap, résultat incomplet. AMRAP : rounds + reps. EMOM : minutes tenues sur N (plus de valeur pré-remplie). Death by : dernière minute réussie. E5MOM tractions : total de tractions. AMRAP en blocs : total des rounds, avec un chrono par blocs. Routines sans règle écrite : temps noté, sans record.
- **Anciens résultats intacts.** Rien n'est converti ni supprimé ; un ancien temps de Tabata ou un ancien score d'EMOM reste dans l'historique avec son explication, sans être comparé aux nouveaux. L'XP déjà gagnée ne bouge pas.

Contrats détaillés : `docs/WOD_FORMATS.md`. Tests : `test/l3b_formats_test.dart`.

## 2.5.5 — Essai du jour, vitrine et crédits fiabilisés (lot L3)

- **Essai commencé avant minuit : il se termine.** Un essai lancé à 23 h 59 peut être fini et son score enregistré après minuit. Le droit vaut pour cette tentative seulement : quitter l’écran l’abandonne, et le WOD ne devient pas acquis. Un score n’est enregistré qu’une fois, même en appuyant deux fois ou en réessayant après une erreur d’écriture ; la récompense n’apparaît qu’une fois le score sauvegardé.
- **Un seul essai par jour, qui ne change plus.** L’essai du jour est fixé à la première ouverture de la journée et enregistré (il fait partie de la sauvegarde). Tentatives illimitées jusqu’à minuit. L’acheter le rend acquis tout de suite, sans faire apparaître un autre essai gratuit. Toujours un WOD jamais tenté : au niveau ±1, sinon ±2, sinon dans tout le catalogue ; s’il n’en reste aucun, pas d’essai ce jour-là (message dans la boutique).
- **Vitrine fixée pour la semaine.** Choisie le premier affichage de la semaine et enregistrée ; seul un WOD acheté laisse sa place au suivant. Reculer l’horloge ne refait ni l’essai ni la vitrine.
- **Crédits : chaque gain payé une fois.** Chaque gain (palier de niveau, chapitre, boss, semaine complète) est inscrit dans un registre sauvegardé. Corriger ou supprimer une activité ne retire rien ; la refaire ne repaie rien ; une vraie nouvelle semaine complète rapporte bien son crédit. Les prix payés et les WODs acquis ne changent jamais.
- **Déficit affiché.** Si une ancienne sauvegarde dépense plus qu’elle n’a gagné, le solde indique « déficit de N crédits » au lieu de 0 ; les achats attendent de nouveaux gains, les WODs acquis restent acquis.
- **Anciennes sauvegardes.** Registre reconstruit depuis le journal, surplus L2 conservé ; aucun crédit créé ni retiré. L’import reste un remplacement complet.

Contrat détaillé : `docs/CONTRAT_L3.md`. Tests : `test/l3_economy_test.dart`.

## 2.5.4 — Sauvegarde Android : choix explicite

Choix retenu : la **sauvegarde Android par défaut** est conservée et désormais déclarée (`android:allowBackup="true"`, sans règle de filtrage). Si la sauvegarde Google est activée sur le téléphone, Android peut copier les données de l’application et les restaurer à la réinstallation ; le transfert vers un nouveau téléphone les inclut. Le comportement ne change pas ; il est maintenant contrôlé à chaque build sur le manifeste final (aucune dépendance ne peut le modifier en silence). L’export par fichier reste la copie que tu contrôles.


## Nouveautés 2.5.3 — tes données sous ton contrôle (lot L2b)

Dans **Réglages → Sauvegardes** :

- **Exporter une sauvegarde** : le sélecteur de fichiers d’Android s’ouvre, tu choisis l’emplacement (téléphone, carte, Drive…). Nom proposé : `kalis-track-sauvegarde-AAAA-MM-JJ-HHMM.json`, sans nom ni donnée sportive. Aucun fichier existant n’est écrasé (Android ajoute un numéro). Le succès n’est annoncé qu’après écriture **et relecture identique** du fichier ; annulation, accès refusé, emplacement indisponible ou écriture incomplète sont signalés (un fichier incomplet est supprimé). Le fichier est du JSON **non chiffré** : garde-le en lieu sûr.
- **Importer une sauvegarde** : choisis un fichier ; il est lu dans les limites de L2 (8 Mio), validé, puis un **aperçu** montre ce qu’il contient réellement (format, date d’export si le fichier l’indique, séances, résultats, WODs débloqués, niveau calculé) face à tes données actuelles. Rien ne change avant ta confirmation. Par défaut, tes données actuelles sont d’abord exportées dans un fichier ; si cet export est annulé ou échoue, l’import n’a pas lieu. « Remplacer sans sauvegarde » est un choix explicite. Si tes données changent pendant l’aperçu, une nouvelle confirmation est demandée.
- **Copier / Coller une sauvegarde** : le presse-papiers reste disponible et passe par le même aperçu.
- **Sauvegarde Android** : explication du comportement réel (l’application ne désactive pas la sauvegarde du système, qu’elle ne peut ni déclencher ni vérifier).
- **Zone sensible → Supprimer les données de l’application** : liste précise de ce qui est supprimé et de ce qui ne l’est pas, export préalable proposé, confirmation en tapant `SUPPRIMER`. L’application revient à son état d’installation (journal, séances perso, références, résultats, crédits, WODs débloqués, envies, réglages, copies internes, anciennes clés de migration, rappels) ; le programme et le catalogue restent. Une suppression incomplète est signalée comme telle.

Aucune permission de stockage n’est ajoutée : le sélecteur système donne accès au seul fichier choisi. Tests : `test/l2b_data_control_test.dart`.


## Correctifs 2.5.2 — sauvegarde et achats (lot L2)

- **Achat confirmé seulement une fois enregistré.** Le bouton passe en « Achat en cours… », le prix est réservé sur le solde, puis le déblocage (révélation, message) n’est annoncé qu’après l’écriture acceptée. Écriture refusée : message explicite, aucun crédit débité, WOD toujours verrouillé, nouvelle tentative possible. Double appui : un seul débit. Deux achats rapprochés : jamais au-delà du solde. Prix changé entre l’affichage et l’appui : rien n’est débité.
- **Une seule file d’écritures.** Sauvegardes ordinaires, achats et imports passent dans le même ordre ; chaque écriture encode l’état au moment où elle s’exécute : un état ancien ne peut plus être écrit après un plus récent. Après une erreur, les modifications restent en mémoire, l’alerte propose **Réessayer**.
- **Import plus sûr.** Validation complète avant tout changement ; l’état courant est d’abord gardé en copie de secours (les trois dernières sont conservées) ; import appliqué seulement après son écriture. Messages distincts : sauvegarde invalide, trop volumineuse, écriture refusée.
- **Imports bornés.** Texte ≤ 8 Mio de caractères, JSON décompressé ≤ 32 Mio (contrôlé pendant la décompression), ≤ 2 millions de valeurs, textes ≤ 100 000 caractères, ≤ 20 000 séances, ≤ 500 000 séries, ≤ 100 000 résultats de WOD, ≤ 20 000 entrées par autre collection. Une sauvegarde représentative (40 semaines entièrement saisies, 60 séances perso, 300 résultats) pèse 1 037 555 octets de JSON et 49 183 caractères compactée.
- **Crédits gagnés jamais repris.** Corriger ou supprimer une séance, un score ou une semaine fait varier l’XP et le niveau, mais plus le total de crédits gagnés : l’application retient le plus haut total atteint (`creditsEarnedMax`, exporté avec la sauvegarde). Refaire une performance supprimée ne redonne rien tant que ce plus haut n’est pas dépassé. Au premier lancement, ce plus haut part du calcul actuel : aucun crédit créé ni retiré. *Remplacé en 2.5.5 par le registre des gains.*
- **Droits WOD anciens.** Les accès « coût 0 » de l’ancienne migration ne sont plus effacés. Un WOD déjà joué (au moins un résultat) reste acquis, gratuitement ; les autres sont archivés à part (`legacyGrants`), sans accès, pour ne pas rendre tout le catalogue gratuit. Même règle pour un import au format 1 ou 2 ; un droit à coût 0 d’une sauvegarde format 3 reste acquis.

Tests : `test/l2_persistence_test.dart`, `test/l2_purchase_ui_test.dart`, jeux de données `test/l2_fixtures.dart`.


## Nouveauté 2.5.1 — corriger ou supprimer une séance terminée

Une séance validée par erreur ou avec une valeur fausse n’est plus figée. Depuis son historique (accueil sur une journée faite, ou STATS → Historique), le menu **⋮** propose :

- **Corriger les saisies** (aussi sur la page **Bilan** de l’historique) : la séance repasse en cours avec toutes ses séries, charges, notes et coches, dans l’écran d’exécution habituel. Son XP de séance est retiré le temps de la correction puis rendu quand tu la termines de nouveau. **Sa date d’origine est conservée** : semaine, série de jours et historique ne se déplacent pas au jour de la retouche.
- **Supprimer de l’historique** : efface séries, notes et statut « fait » après confirmation. L’XP et les bonus de la séance sont retirés ; les WODs déjà débloqués restent acquis. Le message qui suit propose **Annuler** et restaure la séance à l’identique, sans jamais écraser une séance recommencée entre-temps.

Les archives de séances perso répétées et les séances perso supprimées ne peuvent pas être rouvertes (leur modèle a pu changer) : seule la suppression est proposée. Tests : `test/history_correction_test.dart`.


Le suivi, le pilotage et la progression sont réunis dans **STATS**. La navigation principale compte quatre onglets : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Nouveautés 2.5.0 — le WOD Store, façon boutique de jeu

Le catalogue devient une vitrine, sans rien de ce qui agace dans les boutiques de jeux : pas de tirage payant, pas de faux compte à rebours, rien qui se retire. Tout repose sur des sélections déterministes (la date et ton journal) et sur des crédits gagnés à l'entraînement.

- **Crédits plus généreux, jamais repris.** 3 crédits offerts au niveau 1, +2 par niveau, +3 de plus tous les 5 niveaux ; +3 par chapitre bouclé, +5 par boss vaincu, +1 par semaine complète (trois entraînements). Tout solde existant est recalculé à la hausse au premier lancement. Les prix ne bougent pas : 1 à 4 crédits selon le palier (Standard 1-3, Avancé 4-6, Élite 7-8, Légende 9-10).
- **À l'affiche : l'essai du jour.** Un WOD verrouillé, hors vitrine, à ton niveau (±1) et jamais tenté, jouable gratuitement jusqu'à minuit. Le score et l'XP restent ; terminé, il coûte 1 crédit de moins. Un seul essai par jour : le terminer n'en fait pas apparaître un autre.
- **Vitrine de la semaine.** Trois WODs de formats différents à −1 crédit, du lundi au dimanche, autour de ton niveau (jusqu'à deux crans au-dessus). Un WOD acheté laisse sa place au suivant ; le prix payé est figé à l'achat.
- **À ta mesure.** Huit WODs verrouillés autour de ton niveau, renouvelés chaque jour.
- **Liste d'envies et prochain objectif.** Un cœur sur chaque fiche (et dans le menu des tuiles). Le WOD souhaité le moins cher s'affiche en tête de boutique avec sa jauge de crédits : « Plus que 1 crédit · niveau 8 dans 120 XP (+2 crédits) ». La liste est sauvegardée et exportée avec le reste.
- **Couvertures procédurales.** Chaque WOD a une couverture dessinée à la volée : un motif par famille (lignes de vitesse For Time, anneaux AMRAP, cadran EMOM, tours empilés, barreaux d'échelle, escalier de chipper, blocs Tabata, rampe Death by), une intensité par palier, des chevrons de palier toujours doublés d'un libellé.
- **Fiche façon page produit.** Couverture, accroche, mouvements, « pourquoi ça compte » (cible musculaire, qualité travaillée), volume et durée, muscles, ton record. Le déblocage joue un reflet sur la couverture, avec un retour haptique, sans écran modal ; « Réduire les animations » affiche directement l'état final.
- **Arsenal.** Les tuiles de WOD portent leur couverture, leur palier et leur état (possédé et record, essai offert, prix remisé barré, « plus que 1 crédit », cadenas) ; la bannière de crédits annonce le prochain objectif ou l'essai du jour.
- **Règles à portée de main.** « Gagner » dans la carte de crédits ouvre le détail des gains ; les textes de campagne (chapitres, boss) suivent le nouveau barème.

Tests ajoutés : `test/wod_store_test.dart` (paliers et plancher de prix, essai du jour stable et remise après essai, vitrine hebdomadaire déterministe, sélection « à ta mesure », achat au prix figé, liste d'envies persistée et exportée, vitrine du catalogue puis recherche, essai lancé sans achat, achat avec révélation, rendu 320 px / 130 %). Barème mis à jour dans `progression_test` et `game_test`.

## Correctifs 2.4.1 — récompenses et niveau

Deux anomalies signalées après une séance terminée.

- **L’écran de récompenses ne s’affichait pas toujours.** Il n’était déclenché que par l’écran qui avait ouvert la séance, au retour ; une séance ouverte depuis la **notification de rappel** ne le montrait jamais, et le bilan restait en attente jusqu’à un moment sans rapport (fermeture d’un historique, séance suivante). Désormais la page **Bilan de séance** affiche elle-même le bilan dès qu’elle referme la séance, quel que soit le point d’entrée (accueil, Arsenal, rappel). Le rappel ouvre en outre l’historique si la journée est déjà faite, comme l’accueil.
- **Le décompte partait pendant la fermeture de la séance.** Destruction de l’écran, sauvegarde complète et reconstruction des onglets tombaient au milieu des 1,1 s de comptage : sur un téléphone chargé, le compteur sautait à sa valeur finale ou semblait ne pas démarrer. L’écran repose maintenant sur une chronologie unique (`AnimationController`) qui ne démarre qu’une fois l’écran entièrement affiché **et** la séance refermée, une image plus tard. Le compteur part toujours de +0 XP ; « Réduire les animations » affiche directement l’état final. La sauvegarde compare le catalogue à ses définitions d’origine sans les réencoder à chaque écriture.
- **Le niveau, la jauge et les crédits ne se mettaient pas à jour** après un passage de niveau tant que l’application n’était pas relancée. La pastille de niveau de l’accueil, le solde de crédits de l’Arsenal et les cartes de l’Aperçu (objectif, série, quête, campagne, boss, saison, comparaison) étaient instanciés en `const` sans écouter le store : Flutter retrouve la même instance et ne les reconstruit jamais. Ces widgets étendent désormais `StoreWidget` (`lib/store_widget.dart`), dont l’élément s’abonne au store et se reconstruit à chaque notification, où qu’il soit placé. La couche jeu (`store.game`) est en outre recalculée dès que la progression l’est, y compris après minuit.

Tests ajoutés : `test/reward_flow_test.dart` (pastille, crédits, carte hebdo et sonde `StoreWidget` qui suivent un passage de niveau puis se désabonnent ; bilan affiché après une séance ouverte sans vérification au retour, décompte lancé après la fermeture de la séance ; ouverture par rappel ; décompte de zéro au gain complet ; état final immédiat avec « Réduire les animations »).

## Nouveautés 2.4.0 — la couche « jeu »

Douze mécaniques issues d’une revue des preuves sur la gamification de l’activité physique (méta-analyses 2022-2025 : effet réel mais modeste, porté par le feedback, les objectifs adaptatifs et les séries avec pardon ; classements globaux et séries punitives écartés). Le barème d’XP est **inchangé** ; tout ce qui suit se recalcule depuis le journal, comme les XP, et une sauvegarde réimportée redonne le même état.

- **Écran de récompenses** après une séance validée ou un score de WOD (`lib/rewards.dart`) : compteur d’XP qui défile, jauge qui se remplit et passe le niveau, bonus affichés un à un (badge avec sa rareté, défi, semaine validée, record, objectif de séance, crédits), cérémonie de niveau avec insigne, confettis et retour haptique ; « Promotion » quand le rang change. Une seule passe d’animations ; « Réduire les animations » rend tout immédiat ; le réglage **Célébrations** le remplace par une confirmation discrète.
- **Records en direct** pendant la séance : une série validée qui bat le meilleur 1RM estimé (Epley) ou le maximum de reps au poids de corps de cet exercice déclenche une bannière « RECORD » et une vibration.
- **Feuille de personnage** (STATS → Aperçu) : insigne de rang dessiné (chevrons puis étoiles, anneau de prestige au-delà de Légende), titre affiché, niveau, jauge, quatre attributs 0-100 avec niveau 1-10 et radar : **Force** (lest relatif au poids de corps sur tractions, dips, muscle-up, squat, depuis les références Pilotage), **Endurance** (maxima de reps + WODs terminés), **Technique** (familles de skills travaillées, niveau au muscle-up, formats de WOD), **Régularité** (série, semaines actives).
- **Objectif hebdomadaire adaptatif** : moyenne des quatre dernières semaines + 1 jour, entre 2 et les journées prévues au programme, remplaçable dans Réglages ou d’un appui (2 à 6 jours, 0 = adaptatif). Sans XP : un cap personnel. **Objectif de séance** : part de séries à valider (moyenne des trois dernières + 5 points, entre 75 et 100 %), affiché sur le bilan et dans la quête principale.
- **Série avec boucliers** : deux jours actifs valident toujours la semaine ; un bouclier couvre une semaine manquée, gagné toutes les trois semaines validées d’affilée (deux en réserve), consommé automatiquement. La semaine en cours ne casse jamais la série ; les deloads du programme sont présentés comme faisant partie du plan.
- **Quêtes** : quête principale = prochaine journée du programme avec son objectif ; défis hebdomadaires existants présentés comme quêtes (bonus XP inchangés) ; quêtes de saison à titres : « Touche-à-tout » (trois formats de WOD dans la saison) et « Gardien du repos » (chaque deload de la saison honoré).
- **Badges à rareté** : Commun, Rare, Épique, Légendaire selon le bonus, affichés dans l’arbre et la fiche ; les légendaires donnent un titre.
- **Campagne** : un chapitre par bloc du programme (Prologue · Tests, Chapitre 1 · Hypertrophie… Chapitre 5 · Peaking) avec progression, bouclé à 75 % des journées d’entraînement → titre + 1 crédit WOD.
- **Boss** : les semaines de tests (S1-2, S25, S31, S39-40) sont des boss ; vaincus quand tous leurs tests sont validés → titre + 1 crédit WOD ; rappel du deload qui précède.
- **Saisons** : quatre saisons de dix semaines calées sur le programme, titre à 70 % ; rien n’est remis à zéro. **Prestige** : au-delà du niveau 60, une étoile par tranche de dix niveaux.
- **Toi contre toi-même** : semaine en cours contre la précédente (entraînements, séries, jours actifs) et meilleure semaine. Aucun classement ni comparaison à d’autres : l’application est hors ligne, et les preuves défavorisent les classements globaux.
- **Titres** : gagnés par chapitres, boss, saisons, quêtes et badges légendaires ; le titre choisi s’affiche sur la feuille de personnage à la place du rang.
- **Économie** : crédits gagnés = barème par niveau (inchangé) + crédits dérivés de la campagne et des boss ; les WODs déjà débloqués restent acquis.

Nouveaux fichiers : `lib/game.dart` (modèle dérivé, testé dans `test/game_test.dart`), `lib/game_widgets.dart` (insigne, radar, cartes), `lib/rewards.dart` (écran de récompenses). Réglages : **Célébrations** et **Objectif de jours actifs par semaine**.

## Nouveautés 2.3.0

- **1 000 WODs au catalogue** (500 auparavant) : la sélection et la première série générée (`gen0`…`gen448`) sont conservées à l’identique, achats et résultats compris. La deuxième série (`genx0`…) ajoute 500 WODs en douze familles : couplet + distance, triplet, chipper décroissant, échelles 21-15-9 / 15-12-9 / 10-8-6-4-2, échelles montantes 1 → 10, AMRAP, 3 × AMRAP avec repos, EMOM en rotation, EMOM par blocs de 5 min, force lestée puis metcon, Tabata par mouvement et Death by. Noms descriptifs (format + mouvements), notes de mise à l’échelle, vocabulaire élargi (chest-to-bar, muscle-ups lestés, HSPU en déficit, pistols lestés, thrusters, 800 m, front lever raises…). Les niveaux 1-10 restent calculés par déciles sur tout le catalogue ; le coût déjà payé d’un WOD débloqué ne change pas.
- **Quinze modes d’exécution** pour les séances personnelles (huit auparavant) : Classique, Myo-reps, Cluster, EMOM, AMRAP, Isométrie, Intervalles, Pyramide, plus **Tabata** (8 × 20 / 10 s, chrono d’intervalles), **Death by** (reps croissantes à chaque minute, chrono EMOM), **Séries au max**, **Tenues au max** (saisie chronométrée), **Tempo** (cadence 3-1-1-0 affichée dans la séance), **Drop set** (paliers loggés séparément) et **Densité** (chrono AMRAP, séries de N reps). Chaque mode applique ses propres valeurs par défaut au changement de mode.
- **Base d’exercices : 505 entrées** (172 auparavant). Tractions et dips en variantes de prise, tempo, pause, cluster, singles lourds, excentriques lestés ; muscle-ups stricts / kipping / anneaux ; leviers avant et arrière, drapeau, essuie-glaces, L-sit, V-sit, manna ; pompes et HSPU ; haltères, barre, poulies, kettlebell, sac lesté, médecine-ball, box, corde, ergomètres, sangles, battle rope ; jambes, gainage, bras, prévention, mobilité et tests.
- **Recherche tolérante** (`lib/search.dart`), commune au catalogue de WODs et au sélecteur d’exercices : sans distinction d’accents ni de casse, plusieurs termes (tous requis), préfixes (« trac » trouve « tractions »), synonymes français / anglais (traction ↔ pull-up / chin-up, pompe ↔ push-up, fente ↔ lunge, course ↔ run, corde ↔ double-unders, abdos ↔ sit-ups / hollow / toes-to-bar…), formats (amrap, emom, chipper, tabata, death by). Résultats classés par pertinence (titre > format > mouvements > notes).
- **Filtres du catalogue** : puces rapides sous la recherche (Abordables, Poids de corps, For Time, AMRAP, EMOM, Rounds, Routine, < 15 min), nouvelle section **Mouvements** (tractions, dips, muscle-ups, pompes, squats / fentes, burpees, gainage, course, erg, corde, HSPU, kettlebell, box, skills), menu de **tri** (débloqués puis niveau, pertinence, niveau, durée, nom, nouveautés). Le compteur du bouton « Voir N WODs » tient compte de la recherche en cours.
- **Sélecteur d’exercices** : puces par groupe musculaire et par matériel, compteur de résultats, section « Récents » (huit derniers choix de la session), entrée « Créer « … » » conservée, message quand rien ne correspond.
- Champs de recherche sans autocorrection ni suggestions clavier.

## Nouveautés 2.2.4

- Dock de navigation redessiné dans l’esprit One UI : quatre icônes dans une capsule floutée de 64 px, le libellé n’apparaît que sur l’onglet actif, dans une pastille teintée (accent #E85959 en sombre, bordeaux #6B0C0C en clair). L’onglet actif s’élargit en 240 ms, les autres se resserrent ; « Réduire les animations » supprime la transition.
- Les quatre libellés restent présents pour les lecteurs d’écran et les tests ; ceux des onglets inactifs sont repliés, pas retirés. Clés `nav-0` à `nav-3`, sémantique, retour haptique et largeur maximale de 560 px conservés.
- Hauteur réservée sous les onglets ramenée de 100 à 84 px.

## Palette

Bordeaux **#6B0C0C** pour les actions principales et les jauges, rouge **#A61717** pour les états actifs, les records et les alertes de chrono, fonds #121212 / #1E1E1E, textes #F4F4F4 / #8A8A8A, vert #388E3C réservé à la validation. En sombre, les textes et icônes accentués utilisent #E85959. Jauges en dégradé bordeaux → rouge (`KProgressBar`), carte musculaire en rampe bordeaux → rouge. Le mode sombre est choisi par défaut pour une nouvelle installation ; Clair et Système restent disponibles.

## Présentation et fonctions

- Le K historique apparaît seul, sur fond transparent, dans l’en-tête et à l’ouverture : blanc cassé en sombre, bordeaux en clair.
- Transitions courtes en fondu et glissement entre onglets, rubriques STATS, semaines et pages. Les filtres, saisies et positions de lecture sont conservés. Les mouvements respectent « Réduire les animations ».
- Les nouveaux WOD s’acquièrent uniquement dans le catalogue avec les crédits gagnés en progressant. Le prix est affiché avant l’achat ; un achat donne un accès durable, sans nouveau débit à chaque tentative.
- Création, modification et duplication de WOD retirées. Les WOD acquis, anciens WOD personnels et tous leurs résultats restent disponibles. Les séances personnelles restent composables.

## Un suivi clair, avec des paliers motivants

| Rubrique STATS | Contenu |
|---|---|
| Aperçu | Niveau et XP, activité de la semaine, prochain objectif, huit semaines d’activité et totaux |
| Parcours | Arbre de badges : Pratique, Rythme et Défis ; paliers obtenus, prochain objectif, bonus et règles |
| Performances | Force, endurance, références modifiables, avancement du programme, muscles et records WOD |
| Historique | Séances et tentatives WOD, recherche dans les titres et notes, filtres, détails en lecture seule |

Les badges et missions utilisent les séances, séries et résultats déjà enregistrés. Les récompenses restent automatiques. Les règles de régularité autorisent les repos : deux jours actifs suffisent pour valider une semaine.

## Continuité des séances

Programme garde les sept jours dans leur ordre, les gestes du slider et les résumés sur appui long. Les 40 semaines, 280 journées et 1 812 exercices du programme (1 954 avant la révision LC1 du Bloc 2, 1 818 avant LC1b), les quinze modes de séance, charges, séries, notes, RIR/RPE, vitesse, chronos, WOD, XP et sauvegardes gardent leur fonctionnement. Les anciennes séances sans date restent consultables.

Les données des captures sont simulées uniquement dans les tests. L’application livrée n’ajoute aucune activité de démonstration à ton historique.

## Structure du dépôt

Depuis 5.3.2 (lot M4c), le dépôt contient les sources du projet à sa racine :

| Dossier ou fichier | Contenu |
| --- | --- |
| `lib/` | Code de l'application (Flutter) |
| `assets/` | Programme, base d'exercices, mannequin 3D (`assets/anatomy/`), sons, polices, icônes |
| `android/` | Projet Android (identifiant `fr.tchoupi.streetlift_tracker`, wrapper Gradle) |
| `hook/` | Build hook de flutter_scene (conversion du mannequin, sortie dans `flutter_scene_generated/`, jamais suivie) |
| `test/`, `integration_test/`, `test_driver/` | Tests Dart, tests sur émulateur (CI 3D) |
| `tools/` | Scripts Python de contrôle, de signature, de fabrication des ressources, et leurs tests (`tools/tests`) |
| `docs/`, `validation/`, `AUDIT_*.md` | Documentation, contrats et relevés historiques |
| `signing/certificate.sha256` | Empreinte publique du certificat de signature (la clé n'est jamais dans le dépôt) |
| `.github/workflows/` | `build-apk.yml` (APK et AAB signés), `ci-3d.yml` (CI du mannequin, branche `claude/ci-3d`) |

`.gitignore` exclut tout ce que les contrôles de livraison refusent (caches, `build/`, fichiers locaux, clés, mots de passe, APK/AAB, ZIP) ; `.gitattributes` impose les fins de ligne LF et déclare les binaires. Le dernier état livré en ZIP reste dans l'historique, au commit `4531346` (étiquette prévue : `archive-zip-5.3.1`).

## Construire l'application

Le workflow **Build APK et AAB** (`.github/workflows/build-apk.yml`) construit depuis la racine du dépôt, sans extraction : à chaque push qui touche le projet (`lib/`, `assets/`, `android/`, `test/`, `tools/`, `hook/`, `integration_test/`, `pubspec.*`, workflows), sur toute branche, ou à la demande (Actions › Build APK et AAB › Run workflow). Il contrôle l'arbre du dépôt sans secret (fichier par fichier), l'intégrité des données, le formatage, l'analyse et les tests, restaure la clé depuis les deux secrets GitHub habituels, produit un APK et un AAB avec le même numéro de build, puis contrôle signatures, identité, manifestes et alignements 16 Ko avant de publier l'artefact `kalis-track-apk`. Identifiant et signature inchangés : chaque APK s'installe par-dessus la version précédente sans perte de données.

La procédure de validation sur téléphone reste [Validation Android L1b](docs/VALIDATION_ANDROID_L1b.md). Ne pas refaire la préparation de clé décrite dans les consignes historiques L1.

En local (SDK Flutter 3.47.5) :

```sh
flutter pub get --enforce-lockfile
flutter build apk --debug
```

Un build release exige les secrets `KALIS_KEYSTORE_BASE64` et `KALIS_KEYSTORE_PASSWORD` (voir `docs/SIGNATURE_ET_ZIP.md`) ; sans eux, il est refusé.

## Développement et vérification

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
python3 tools/verify_project.py
python3 tools/package_release.py --check
python3 tools/check_release_without_secrets.py --tree
python3 -m unittest discover -s tools/tests -v
TZ=Europe/Paris flutter test --no-pub --timeout 90s --reporter expanded
```

Captures reproductibles de l’application :

```sh
flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart
```

Elles sont écrites dans `validation/2.5.0`. Le test de captures reste désactivé lors de la commande habituelle. Pour charger les polices dans les rendus, définir `FLUTTER_ROOT` sur le SDK utilisé.

`assets/exercises_db.json.gz` (505 exercices) et `assets/programme_v33.json.gz` sont compressés de façon reproductible (`tools/pack_assets.py`, gzip niveau 9, mtime 0). Le masque original du logo est `assets/icon/logo_mask.png` ; `tools/generate_brand.py` régénère ses déclinaisons.

Voir `REFONTE_UI.md` pour la checklist et `AUDIT_2.5.0.md` pour les vérifications et les limites de validation. Les documents antérieurs sont conservés dans `docs` et les audits précédents ; leurs consignes historiques de signature sont remplacées par `docs/SIGNATURE_ET_ZIP.md`. L’état courant et les validations restantes figurent dans `SUIVI_PROJET.md`.

## Contrôle de l'arbre et archive facultative

```sh
python3 tools/package_release.py --check                # arbre suivi, fichier par fichier
python3 tools/check_release_without_secrets.py --tree   # même contrôle, avant chaque push
python3 tools/compare_tree_with_zip.py                  # identité avec le ZIP 5.3.1 (M4c)
```

Le contrôle refuse tout fichier suivi qui serait une clé privée (même renommée ou encodée en Base64), un mot de passe littéral, un fichier local, un cache, un APK/AAB ou un ZIP, et un arbre de plus de 25 000 000 octets. Une archive du projet reste possible comme artefact (`python3 tools/package_release.py ../kalis_track.zip`, relue avec `--check ../kalis_track.zip`) ; elle n'est plus poussée dans le dépôt.
