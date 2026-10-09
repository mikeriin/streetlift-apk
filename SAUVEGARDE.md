# Sauvegarde CI1f

Base : main 238078ee (dev6.10.0). Lot lancé 09/10 ~09:08 UTC.

## Fait
- Paquets kalis_core 0.4.3, kalis_plan 0.3.0, kalis_adapt 0.3.0 copiés des étiquettes (identiques), pubspec.lock (versions), parcours_v3.json recopié.
- Textes Koach des 5 codes d'endurance + causes (reason_texts_0_4.dart).
- CI rapide : branche claude/ci-ci1f-rapide (rapide.yml adapté de CI1e).

## Plan
1. Mini-séries (cluster, rest-pause, myo) : SetEntry.parts, saisie une à une, journal parts+technique (journal_adapter + _adaptDone), conseil mini-séries restantes ; regroupement à la lecture des myo-reps notés en 5 lignes (Act, M1..M4) quand sûr.
2. Groupes : pages de séance par groupId (GroupSpec), en-tête du groupe (format, tours, ordre, chrono), résultat du groupe -> SessionLog.groups -> SessionRecord.groupResults.
3. Annotation 40 semaines : myo -> myo_reps ; durées et HIIT -> prescriptions de cardio ; EMOM -> groupe emom ; contrastes / échelles -> groupes ; « N × ? reps » -> carte Koach (référence) ou estimation journal.
4. Tests Dart, émulateur CI1f, version dev6.11.0, livraison.

## Fait (suite, 09:30)
- Mini-séries : SetPartEntry/SetEntry.parts (store.dart), _MiniSetStrip (session_screen), miniSetPlanFor/MiniSetPlan, journal parts+technique (journal_adapter lineOf, _adaptDone), regroupement myo (myoOf/_groupMyo).
- Groupes : exerciseGroupOf, store.groups(d, week:), _GroupCard (en-tête, chrono, résultat), SessionLog.groups -> groupResults.
- Annotation : _importFormat (myo, durées, HIIT, EMOM, contrastes, échelles, N × ? via estimations), asWritten / exerciseOf ; minutes (prescriptionInMinutes, LogSpec duration moteur).
- Test : test/ci1f_formats_test.dart ; CI1e et CI1d ajustés.

- 09:50 : relecture indépendante (sous-agent Opus, 13 constats) ; traités : asWritten/exerciseOf par semaine, minutes marquées à la saisie (unit=min), myo sans parties garde sa technique, regroupement myo par préfixe validé + repli myo_reps, estimations dans la clé, test de distance exclu, historique groupé, _group recalculé, groupes dans la signature du journal, parts orphelines retirées, enchaîné seulement adjacent, libellé mètres. Distances (LogSpec distance). Version 6.11.0+113. Cible émulateur CI1f (integration_test/koach_ci1f_test.dart), ci3d_drive.sh, ci-3d.yml (70 min), CI_GP.md.
- Essai 1 (ALL) : analyse verte avec 0.3.0 ; échecs attendus ci1d (versions), ci1_street (musculation au chemin calibré) corrigés ; m8_carte_2d délais (environnement rapide).

## En cours
Essai 4 sur claude/ci-ci1f-rapide2 ; puis ALL ; puis claude/ci-3d complet, main, build signé, livraison.
