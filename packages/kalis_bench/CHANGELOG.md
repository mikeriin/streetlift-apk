# Journal

## 0.1.1 — 04/10/2026 (lot CP1)

Le banc transmet le profil au schéma 3 et lit le chemin street de `kalis_plan` 0.2.0. Profils types, attentes de coach et grilles du panel inchangés.

- **Adaptateur** (`lib/src/adapter.dart`) : produit le profil d'athlète au **schéma 3** (`schemaVersion: 3`) au lieu du profil v2. Sont maintenant transmis :
  - expérience (niveau du profil) ; ancienneté en tranches (`trainingAge` : moins de 6 mois, 6 à 24 mois, 2 à 5 ans, plus) ; coupure en tranches (`trainingGap` : aucune, moins de 3 semaines, 3 à 10, 11 à 26, 27 à 104 semaines, plus) ;
  - sommeil (durée en tranches : moins de 6 h, 6 à 7 h, 7 h et plus), stress (2 ou moins : bas, 3 : modéré, au-delà : élevé), travail physique lourd (`occupationalLoad`), déficit énergétique (`bodyWeightGoal: lose`), autres sports (course, vélo, natation, escalade ou autre, avec séances, minutes et intensité dure) ;
  - tests datés (`benchmarks`) : 1RM (charge × 1 répétition, 0 en réserve, poids du corps), maximum de répétitions, maintien maximal, chrono sur une distance ; date = début du programme moins l'ancienneté du test ; un record nul n'est pas transmis comme test. Les records restent aussi transmis en fourchette (bas = haut) pour le chemin 0.1 ;
  - échéances (`events`) : test personnel, ou compétition de force (streetlifting, powerlifting), de répétitions (sets & reps), course ou autre ; priorité A, B ou C ; mouvements de force à 3 tentatives avec meilleur 1RM déclaré et cible ; stations en maximum de répétitions ; distance et temps visé d'une course ; objectifs liés ;
  - points faibles d'un mouvement (`weakPoints`), nature lue dans la note : départ bras tendus, verrouillage, transition, bas, sinon milieu du mouvement ;
  - spécialisation : premier mouvement prioritaire, sur les semaines jusqu'à l'échéance principale, le reste en entretien ;
  - toutes les blessures, y compris les antécédents sans gêne actuelle, avec leur ancienneté (`since`).
- Nouvel argument `catalog` de `adaptProfile` (passé par `generateProgram` et par la CLI, `bin/common.dart`) : chaque figure visée (figure à débloquer ou tenue) reçoit son étape actuelle (`skills`), le record non nul le plus difficile de sa chaîne de progression, avec son maintien ou ses répétitions.
- Pertes listées (`AdaptedProfile.lost`) réduites à : points faibles musculaires (sans mouvement), description de la blessure, qualité du sommeil, libellé de l'échéance, liste des mouvements à entretenir.
- **Analyse** (`lib/src/analysis.dart`) : `DayView.stress` (séance lourde, moyenne ou légère) et `WeekView.intent` (intention de la semaine), quand le moteur les donne.
- **Export lisible** (`lib/src/export.dart`) :
  - volume : série de tête puis séries allégées (avec la baisse en %), départs à la minute ou à intervalle fixe, tentatives d'un test de 1RM, série maximale d'un test de répétitions avec son repère, course d'au moins 1 500 m d'une traite écrite en km ;
  - charge : part du 1RM du mouvement de compétition, ou part du maximum de répétitions ou du maintien maximal avec le repère écrit ;
  - effort : en répétitions en réserve seulement (la note sur 10 n'est plus affichée) ; course et cardio en allure (facile, soutenue) ou au chrono ; descente freinée « au contrôle » ; tenues décrites par la marge sur la position ; séries à une part du maximum de répétitions : la réserve écrite est celle de la dernière série quand les premières en laissent nettement plus ;
  - notes : technique de série (tenue isométrique, pratique technique, autres formats), tempo (descente, pause en haut), récupération en trottinant, notes de coach de `kalis_plan` (`coachReasonText`) ; pas de rôle sur une épreuve, pas d'« échauffement » en double ; pas de repos écrit pour les départs à la minute ;
  - nouvelles sections « Saison » (une ligne par bloc, phases par semaines), « Échelles des figures » (étapes, étape actuelle, critère de passage) et « Règles du programme » (règles du bloc et règles communes aux exercices écrites une fois, définition de la réserve), vides pour un moteur 0.1 ;
  - semaines nommées par leur intention et séances par leur charge quand le moteur les donne ; course chronométrée nommée par sa distance ;
  - export JSON : champs `season`, `ladders` et `rules`.
- `tool/panel_export.py` : colonne « notes » dans les tableaux (et dans la détection des séances identiques) ; sections Saison, Échelles des figures et Règles du programme.
- Test de l'adaptateur (`test/profiles_test.dart`) : antécédent sans gêne actuelle transmis avec son ancienneté, sommeil et coupure transmis, profil au schéma 3, description de la blessure dans les pertes.

## 0.1.0 — 03/10/2026 (lot CR)

Première version : référentiel scientifique (145 principes, six chapitres, références vérifiées deux fois, R5 rapproché de la revue du profil v3), mesures agrégées des programmes de référence, 27 profils types avec attentes de coach, adaptateur vers le profil v2, critères de sécurité (15), de qualité (9) et de trajectoire, exports lisibles, rapports, CLI, protocole et grilles du panel de coachs virtuels (gelées après étalonnage), mesure des moteurs 0.1.

Compatible avec `kalis_core` 0.4.0 (techniques structurées et enchaînements lus par les critères), `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0.
