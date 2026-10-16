# Sauvegarde KS1A (base main dc9cbc55, dev7.0.0)

## Fait
- Paquets : kalis_core 0.4.4 (arbre 8278f8d9) et kalis_plan 0.4.1 (arbre d8b7de66) copiés à l'octet ; kalis_adapt 1.0.2 inchangé (arbre 2d1c0d96, identique à eae158b8). assets/catalog/parcours_v3.json recopié (version 0.4.4).
- Version 7.1.0+130 (pubspec, settings, tests de version), tests ci1d/ci1g : kalis_plan 0.4.1.
- lib/plan/day_type.dart : libellés, importedDayType (titre + J), gabarits.
- DayPlan.type / minutes (models.dart), planWeekJson 'type', PlanStore.dayTypeOf / dayDurationText / dayAvailableMinutes.
- Affichage : accueil (lignes, carte du jour, feuille de la semaine, résumé), en-tête de séance, création (carte du jour, « Structure de la semaine »).
- Textes des six codes (reason_texts_0_4.dart).
- Blocs importés : PlanDay.type (le plus fréquent du bloc) ; Koach : koachBlocJson retire `type` (référence et signature inchangées).
- Échéance changée : PlanProgram.eventsKey, planDeadlineChanged, planNextFirstWeek, troncature servedBlockOf à l'application.
- Mesure CI : claude/ci-ui-ks1a0-rapide (paquets seuls + version, suite Dart complète).

## En cours
- Contrôle complet claude/ci-3d run 38923187864 (4c238816) : tests Dart verts ; émulateur en cours. Brouillon de livraison dans le message de sauvegarde suivant.

## Reste
- Tests test/ks1a_*_test.dart, cible émulateur integration_test/types_ks1a_test.dart, ci3d_drive.sh, docs/CI_GP.md.
- Contrôle complet claude/ci-3d, main, build signé, livraison, ETAT, page de suivi, notification.
