# Sauvegarde BV11

## Fait
- Inventaire (sous-agent) ; pack 2.0.0 archivé dans tools/archives/pack_2.0.0/ (git mv), retiré de pubspec.
- assets/catalog/groupes_historiques.json (625 noms → g, copie figée) : groupsFor inchangé.
- assets/legal/licences.md (mentions réécrites) ; MentionsScreen pointé dessus.
- Code mort retiré : LegacyPackIndex, legacyPack, athleteDislikedLegacyIds, toLegacy, entryFor, vocabulaires de legacy_pack.dart, pose_* (démonstrations 2D du pack) + tests l9b_pose, refonte_ma_capture, groupe « démonstrations découpées », test perf des démos.
- Filtres : Catégorie (56) et Muscle principal (54) ajoutés.
- Outils Python repointés vers l'archive ; verify_project sur la base v1.1 ; tests Python OK (3 échecs d'environnement identiques à main).
- Version 6.19.0+128.

## Reste
- test/bv11_base_test.dart (migration S1-S14, sauvegarde ancienne, filtres, fiche) ; cible émulateur integration_test/lot_bv11_test.dart + ci3d_drive.sh + ci-3d.yml.
- CI rapide puis complet, main, build signé, livraison, ETAT, suivi, notification.
