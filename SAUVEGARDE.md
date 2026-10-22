# Sauvegarde RV2

Reprise 22/10 17:55 UTC (session 012ahWYqqvxV3C5XoT248gh7). Branche rv2 (tête 28af7175, aussi sur claude/ci-ui-rv2-rapide) = 21419df0 (six zones) + 6a988df6 (cible émulateur) + ca1b2641 (P3 migration jWeekday) + 28af7175.

28af7175 corrige les deux rouges du contrôle complet ci-3d run 39771709972 (sur b6a99725) :
- dart_dev : g7_mode_dev_test — la sauvegarde d'origine (C11.2) partageait les tables vivantes du magasin (pilotage) ; le réalignement M9 réécrivait la session perso au démarrage. Correctif : copie profonde à la prise (program_origin.dart) + test rv2_m_donnees_test.
- émulateur : rv2_parcours_test « montage » — magasin global déjà initialisé (late final _prefs) ; partie 2 sur un magasin neuf.

BLOCAGE : pushes git de cette session acceptés (claude/ci-3d aeb92f92, claude/ci-ui-rv2-rapide 28af7175) mais AUCUN workflow déclenché (outil add_repo absent de la session ; identité de push sans déclenchement). Reste : contrôle complet ci-3d sur 28af7175 (re-pousser avec une identité qui déclenche les workflows), publication main dev7.6.0, build signé, livraison (tableau : tous les majeurs et les 19 mineurs prioritaires corrigés + S15, A4, H7, D1 ; restent P10, R6-R8, R10, R13, F5-F7, F9, F11-F16).
