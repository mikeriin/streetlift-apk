# Sauvegarde KM7 (Koach 1.0.9, kalis_adapt 1.0.8)

Session Opus 5.5 lancée le 24/10/2026 vers 15:02 UTC (sans ligne « Lot : » ; KM7 posé « en cours » par le pilotage).
`ETAT_CP.md` : KM7 « en cours depuis 2026-10-24 15:05 UTC » (pipeline 0bc8998).
Base : `moteurs` 25d5bfe6. Environnement : Dart 3.13.7 conda-forge (/tmp/dartpkg/root/bin), cache pub de a74f7710
(ci-out/packages/pubcache/hosted.tar.gz dans /root/.pub-cache, pubspec.lock copiés).

## Décisions
- Point 1 : drapeau `applique: false` DANS le bilan de `seance_debut` (le bilan arrive à `seance_debut`, pas à
  `plan`). Plan servi = plan des seuls faits (`faits_du_bilan` : sans CLES_FORME) ; douleur toujours (garde) ;
  modèle : a priori du jour sans forme jusqu'à la 1re série, puis `_verser_bilan` (état identique au bilan appliqué).
  Pas d'événement de bascule : la méthode de l'application (retour au seance_debut) reste exacte avant la 1re série ;
  après, la forme est déjà versée dans les deux lectures (rien à rejouer).
- Point 2 : `koach/remplacants.py` sur les fiches `catalogue_infos` (Dart : à construire depuis Catalog/ExerciseBook) ;
  étiquettes equivalent / plus_facile / sans_materiel / autre (pas d'« autre » pour main / skill) ; `depart`
  (historique, transfert coachLoadReferences, a_priori, None) ; `remplace` dans les items de plan('seance')
  (`item_remplace`), raison `koach.remplacement`, `koachDepartKg` pour le transfert.

## Fait
- Python : modele.py, moteur.py, seance.py, remplacants.py ; tests/test_km7.py (15 tests verts).

## Reste
- pytest complet ; portage Dart (modele, moteur, seance, remplacants, textes) + test koach_km7_test.dart ;
  infos de remplacement Dart ; mesure banc (variante « garde l'écrit 1 fois sur 2 ») ; campagne CI ; livraison.
