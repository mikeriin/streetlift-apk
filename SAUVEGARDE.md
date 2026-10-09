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

## En cours
Essai 1 de la CI rapide (compilation avec 0.3.0, suite complète).
