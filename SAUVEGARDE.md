# Sauvegarde CI1 (intégration street dans l'application)

Base : main 6467bc2 (dev6.8.0). Paquets : kalis_core 0.4.2, kalis_plan 0.2.1, kalis_adapt 0.2.1 (étiquettes).
Branche de mise au point : claude/ci-ci1-rapide (rapide.yml) ; contrôle complet : claude/ci-3d.

## Fait
- Paquets récupérés par étiquette (packages/).
- lib/plan/coach_texts.dart : textes des prescriptions calibrées (technique, intensité, tempo, rôles des lignes, notes de coach via kalis_plan coachReasonText, règles du programme, échelles de figures).
- Séance : rôles des lignes (Tête, A1…, Éc1, M1…), panneau coach (technique, intensité, douleur visible, notes), chrono EMOM/densité, mini-repos, repos par série ; journal : role/kind des SetRecord (journal_adapter, _adaptDone).
- Saison : PlanProgram.season / keepLegacyEngine ; planSeason à la création et au bloc suivant ; AdaptInput.season ; lib/plan/season_view.dart (carte « Ta saison », écran MA SAISON).
- Migration : choix au bloc suivant (moteur calibré / garder l'actuel) dans openNextBlock.
- Tests : testResults/skillStates du moteur reportés au profil (bloc calibré seulement).
- Textes 0.4 : adaptReasonText → reasonText04 ; paramètres technique/phase/stress/cause en clair.

## Reste
- Essai 7 rapide vert (relecture indépendante traitée : figures fusionnées, records dédoublonnés, « garder » retire l ancienneté, saison effacée). Contrôle complet essai 1 (code avant relecture) en cours sur claude/ci-3d. Brouillon DECISIONS dans la session. Reste : essai 2 complet, captures, main, build signé, livraison.
