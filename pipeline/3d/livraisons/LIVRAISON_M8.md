# Livraison M8 — Carte 2D des groupes musculaires (5.9.0)

Demande du propriétaire (30/09/2026) : « les animations 3D seront uniquement pour la démonstration des exercices et pour le Koach. En ce qui concerne les groupes musculaires travaillés, je veux que tu affiches l'image en pièce jointe (réadaptée pour l'application). Les groupes non travaillés sont grisés et pour les autres tu choisis un code couleur pertinent. »
Réponses : partout sauf la démonstration ; couleurs par rôle ; les 15 groupes de l'image ; rien en tête de fiche sans animation.

## Réalisation
- **Carte** (`tools/muscles2d/build_map.py`, source `tools/muscles2d/source_carte.png`) : pixels classés par la couleur de la légende de l'image, règles de position pour les couleurs voisines (trapèzes / quadriceps / ischios, biceps / triceps, fessiers / adducteurs, mollets / tibial), un masque alpha par groupe et par vue (face, dos, profil), calques peau et extrémités, carte des étiquettes pour le toucher → `assets/muscles2d/` (316 Ko). Traits et fond transparents : la carte prend la couleur de son support.
- **Couleurs** : non travaillé gris (thème sombre / clair) ; travaillé dans la couleur dominante choisie, principal vif (1), secondaire atténué (0,62), stabilisateur pâle (0,35) ; intensité continue pour la semaine, la séance, le WOD (ramenée au plus fort, seuil 2 %). Carte du jour de l'accueil : teintée de la couleur du texte.
- **Écrans** : fiche (section Muscles : carte, légende des rôles, liste en texte ; tête 3D seulement si l'exercice a une animation — aucune aujourd'hui), STATS › Performances, accueil (carte du jour, résumé d'une séance), aperçu de WOD, Anatomie (15 filtres, nom du groupe au toucher, muscles par groupe coché, Koach (aperçu) conservé).
- **Code** : `lib/muscle_map_2d.dart` (`MuscleMap2D`, correspondance des 81 muscles du pack — 7 profonds du tronc et du cou sans groupe, listés en texte —, intensités, légende) ; `TargetedMuscleMap` (`lib/stats_mannequin.dart`) ; widgets 3D remplacés retirés (`TargetedMannequin`, `WeeklyMannequin`, mannequin fixe de fiche).

## Contrôles
- CI 3D : essais A (débordement des noms de vue sous le profil étroit, formatage), B (légende en grand texte, mesure de démarcation), C vert (run 36708412158) : 1010 tests Dart, 147 Python, formatage et analyse sans remarque, builds debug et profile.
- Émulateur (`integration_test/carte_2d_m8_test.dart`, sombre et clair) : couleur lue au cœur du grand dorsal = couleur dominante attendue, pectoraux = gris attendu (écart 0) ; toucher → « Dorsaux » ; démarcation 0,0 sur Anatomie, 2 fiches, STATS, accueil, WOD ; aucune vue 3D sur ces écrans. Koach (aperçu) et animation de test relancés : verts.
- Cibles d'émulateur des écrans passés à la carte (M3, M4, M4b, M4c, M56, M6b, M6c) supprimées.
- main decf806 ; build signé n° 180 (36710169365).

## À tester
- Arsenal › Exercices › une fiche › section Muscles (sombre et clair, autre couleur dominante).
- Arsenal › Anatomie : filtres, toucher d'un groupe, Koach (aperçu).
- STATS › Performances, Accueil, aperçu d'un WOD.
