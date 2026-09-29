# Livraison M56 — correction 1 (Kalis Track 5.5.1)

**Date** : 29/09/2026 · **Version** : 5.5.1+80 · **Commit main** : 786e867 (« Kalis Track 5.5.1 (M56, correction 1) : … ») · **Build signé** : run 36537833401 (n° 137) · **CI 3D** : run 36535840924 (3 essais : 36532238784, 36533912915, 36535840924) · **Modèle** : Fable 5.1, effort maximal, même session que M56 · **Base** : main 7a24fc0 (5.5.0+79)

## Tes retours du 29/09 et ce qui a été fait
| Retour | Correction |
| --- | --- |
| « Le modèle 3D est plus musclé mais ça paraît difforme… cuisses et pecs trop gros par rapport au reste », référence : ton écorché (3 images) | Silhouette de tes images mesurée (largeurs de face, profondeurs de profil, en fraction de la taille : `tools/anatomy/silhouette.py`), mannequin réajusté dessus : cuisses moins larges et plus profondes, pectoraux plats (facteur 1,6 → 0,6), taille et fessiers plus pleins (dilatation radiale autour du tronc ; taille à ta cible nominale 0,45 H), bras et mollets un peu plus forts, épaules à la largeur de la référence. Bideltoïde, poitrine, taille, hanches, cuisse, genou, mollet dans ± 6 % de la référence ; bras à mi-chemin (tour 37,7 cm = ta cible 0,22 H). Tours 5.5.0 → 5.5.1 : bras 35,4 → 37,7 cm, poitrine 101,0 → 97,1, taille 69,8 → 74,5, cuisse 56,8 → 52,0, mollet 35,4 → 37,5, bideltoïde 48,5 → 51,0 ; épaules / taille 1,65 ; 0 interpénétration > 1 mm. |
| « En position basse de tractions on a l'impression que les muscles et omoplates vont s'arracher… il faut que ça fasse un V » | Les « ailes » étaient la coiffe des rotateurs et le grand rond emportés par la rotation du bras à 155° (poids mêlés scapula / bras portés par la chaîne d'aide) et le grand dorsal tiré par la rotation du bras. Os d'insertion `arm_ins` (position de l'insertion humérale, orientation du tronc : le grand dorsal s'étire en ligne droite, V), coiffe et grand rond sur la scapula (tendon seul collé à la tête humérale), deltoïde tout au bras 4 cm sous la tête, sonnette et bascule dans le plan de la scapula (35°). 56 os. Posture Suspendu de l'Anatomie corrigée du même coup. |
| « Les coudes sont trop en arrière et les abdos pas assez engagés » (traction, bas) | Suspension bras à la verticale sous la barre (flexion humérale 0), ceinture scapulaire haussée (clavicule +20°, sonnette 45°), gainage hollow (lombaires fléchies 8°, côtes basses), hanches 15°, genoux 90° comme ta référence. |
| « En position basse des dips, les coudes sont trop resserrés » | 5.5.0 : coudes serrés derrière le dos (adduction 25°). Extension humérothoracique du rig portée à 75° (glénohumérale 50° + bascule scapulaire 20°), bornes par position, coudes ouverts 18-26°, bras à l'horizontale (épaule au niveau du coude ± 3 cm), buste 23°, hanches 40°, genoux 92°, centre de masse au-dessus des prises. Avec des barres à 55 cm et 51 cm d'épaules, 30° d'ouverture rentrerait trop les avant-bras : 18-26° est le compromis. |
| « Soit tu trouves des animations sur internet, soit on fait juste un aperçu position de départ / position de fin » → ta décision : GymVisual / `exercises-dataset` comme référence d'exécution, positions départ / fin en 3D, sans animation | Clip : `positions` (Départ, Fin : clé de la fiche, instant, libellé). Application : plus de boucle ni de ticker ; la fiche s'ouvre sur la position de départ, la puce **Fin** fait un fondu de 0,75 s (matériel mobile interpolé), **Départ** ramène ; instantané si les animations sont réduites ; légende « Départ · Suspension, bras tendus · tempo 2-1-1-1 ». Les animations complètes restent dans la chaîne de calcul (contrôles). Médias Gym visual regardés comme référence seulement (leur reprise dans l'appli demanderait leur licence). |
| « La carte Koach doit être sur une autre page que la carte du premier exercice, juste avant » | Page « Koach · séance du jour » avant l'exercice 1, quand Koach a quelque chose à dire à l'ouverture (questionnaire, jour de fatigue, adaptation) ; « Suivant » ouvre l'exercice 1 ; une séance reprise en cours s'ouvre sur l'exercice en cours ; sans page Koach, une indication apparue en cours de séance reste en tête de l'exercice 1 comme avant. |
| « Arsenal › ref › anatomie c'est aussi nul que la dernière fois » → le modèle lui-même | Corrigé par les proportions ci-dessus ; postures recalculées (bras levés : sonnette 50°, clavicule 20°). |

## Ce que tu vois
- **Arsenal › Référence › Anatomie** : mannequin rééquilibré ; posture Suspendu : dos en V, rien ne dépasse à l'épaule.
- **Arsenal › Exercices › Traction pronation, Dips, Back squat** : position de départ, puce **Fin** → position de fin (fondu), **Départ** ramène ; tourne, zoome, change de vue.
- **Programme › une séance** (Koach actif, questionnaire ou ajustement du jour) : première page « Koach · séance du jour » seule, puis l'exercice 1.

## Contrôles
- Python (126 tests) : `test_m56_body.py` réécrit sur les cibles de silhouette ; `test_m5_rig.py` ; `test_m56_clips.py` (positions) ; `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`.
- Dart : formatage et analyse sans remarque, **966 tests, 0 échec** (`m5_rig_test` : 56 os, os d'insertion ; `m56_clip_test` : positions et libellés ; `m56_koach_day_card_test` : page à part ; `l7_koach_screens_test` : séance S5 avec page Koach).
- Émulateur (Android 15, rendu logiciel) : trois fiches (départ, fondu, fin, 3/4), animations réduites, page Koach sombre et clair, Anatomie (repos face et dos, 3 postures), préchargement, Moteur 3D ; captures regardées.
- Planches Blender regardées : avant / après (4 vues), trunk en gros plan, 12 postures, suspension dos et face, positions des trois exercices (3 vues chacune).
- Build signé n° 137 réussi sur 786e867.

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section « M56 · correction 1 » en tête)

## Limites et suite
- Dips : cuisses un peu plus en avant que sur ta référence (équilibre au-dessus des prises avec les jambes fléchies).
- Fondu sur émulateur : une image peut prendre plus que les 0,75 s du fondu (capture « fondu » = fin).
- Lot M7 (lecteur complet : pause, curseur, tempo, muscles selon la phase) à redéfinir avec toi maintenant qu'il n'y a plus d'animation : positions intermédiaires ? muscles selon la position ? Les lots de conversion M8-M15 deviennent deux positions par exercice (départ, fin), avec les mêmes contrôles.
- Mesures du préchargement : à lire sur ton téléphone (carte Préchargement de Moteur 3D).
