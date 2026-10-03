# Sauvegarde CR

Session de reprise du 03/10/2026 (lancée 11:14 UTC).

## Fait
- ETAT_CP : CR « en cours ».
- `packages/kalis_bench` repris de `claude/ci-cp-a` f0195e34, posé sur `moteurs` ef4c57ae (pas encore committé sur moteurs). Contrôle lancé 11:53 UTC (commit 7bc71e7c de claude/ci-cp-a).
- Références déchiffrées ; lues : A1, A2, F1, F2 en entier, F3 pages 20-37. **A3 et F3 pages 1-19 non lus** : la délégation de leur transcription a été refusée par le contrôle d'autorisations de la session (ne pas contourner ; à signaler au propriétaire).
- Analyse détaillée chiffrée poussée sur `cp-references` (analyse_CR.tar.gpg, commit 724c42bb) : ANALYSE_CR.md + transcriptions.
- MESURES_REFERENCES.md (première session, six programmes) recontrôlé par sondage sur A1, A2, F1, F2, F3 fin : cohérent.
- Relecture indépendante du code (Opus) reçue. À corriger : B1 supprimer test/dev_format_test.dart avant livraison ; I1 techniques lues aussi dans `technique.kind.code` et `groups` (codes réels `wave`, `accentuated_eccentric`) ; I2 échec : < 2 RIR sur mouvement à risque élevé, aucun échec débutant ; I3 loadRise [0.10,0.05,0.05,0.05] + comparer à schéma égal ; I4 rampLimit = max(ref×(1+h), ref+tol) + borne 2 semaines ; I5 tenues bras tendus par niveau [0.20,0.15,0.10,0.10], tol 5 s ; I6 back lever → famille poussée ; I7 gêne modérée 6 ; I8 affûtage [0.30,0.30,0.40,0.40] ; I9 affûtage mesuré en minutes de cardio s'il n'y a pas de renforcement ; I10 semaine allégée reconnue à la mesure ; I11 verdicts de trajectoire + respect des déblocages ; I13 écrire CRITERES.md, PROFILS.md, CONTRAT.md, README, CHANGELOG ; M2 bande tirage/poussée [1 ; 2].
- Comparaison PROFIL_V3 (CQ) ↔ R5 (Opus, web partiel) reçue. À faire dans R5 : corriger le signe Huiberts 2024 (femmes SMD +0,08 [−0,34 ; 0,49], pas de différence de sexe sur le haut du corps P = 0,67) en P11 et P19 ; ajouter Fernandes 2025, Pollock 1991, Bosquet 2013, Kubo 2012, Rhea 2003 (MSSE), Steele 2023, Borba 2024, Dobrosielski 2021, Knowles 2022, Ruuska 2012, Garthe 2011, Mountjoy 2023, Nolan 2024, Coenen 2018, Refalo 2025 ; lever « à relire » sur Hägglund 2006. Divergences à consigner dans DECISIONS_CP (CR) : volume après 60 ans, sommeil habituel, stress, métier physique, autres sports, antécédents, bornes de reprise.

## En cours
- Corrections du code et des docs d'après les deux relectures.

## Reste à faire
- tool/panel_export.py (export concis pour le panel), PANEL.md + 4 grilles + étalonnage (4 profils × 4 variantes × 4 écoles + répétabilité), gel + SHA-256.
- BASELINE_0_1.md : critères + passe complète du panel (4 écoles × 27 profils) sur les exports du contrôle.
- Jaccard programmes générés ↔ références (dans la session, clé) ; ancres et couples à rajouter chiffrés sur cp-references.
- Page de relecture (Artifact, capacité db), manche 0, 10 profils.
- Contrôle vert, commit sur moteurs, étiquette etiquettes/kalis_bench-v0.1.0, LIVRAISON_CR.md, ETAT_CP, page de suivi (partie Calibrage), notification.

## Décisions
- Pas de SDK Dart dans la session : contrôles par `claude/ci-cp-a` uniquement ; `test/dev_format_test.dart` sert à récupérer les sources formatées par la CI (`ci-out/packages/kalis_bench/_src`) et doit être supprimé avant livraison.
- Export concis du panel en Python (`tool/panel_export.py`) à partir des JSON du rapport.
