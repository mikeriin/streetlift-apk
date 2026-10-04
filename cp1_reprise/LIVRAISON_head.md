# Livraison CP1 — `kalis_plan` 0.2.0 : le street au niveau d'un coach

Lot moteur du pipeline « Calibrage des programmes » (voie A, Fable 5.1), exécuté du 03/10/2026 20:27 UTC au 04/10/2026.

**État : livré — cible non atteinte.** Le moteur est publié et sûr (0 violation de sécurité sur les 17 profils street), le panel est à 9 sur 66 notes sur 68, mais ni le panel (moyenne 8,97 pour 9,5 visés, deux notes à 8) ni la relecture documentée (moyenne 7,41, minimum 7, pour 9 visés) n'atteignent la cible C7. Une décision du propriétaire est demandée (dernière partie).

## 1. Ce qui est livré

| Élément | Valeur |
| --- | --- |
| Paquets | `kalis_plan` 0.2.0, `kalis_bench` 0.1.1, `kalis_core` 0.4.1 |
| Branche | `moteurs`, commit @MOTEURS@ |
| Étiquettes | `etiquettes/kalis_plan-v0.2.0`, `etiquettes/kalis_bench-v0.1.1`, `etiquettes/kalis_core-v0.4.1` |
| Contrôle | `claude/ci-cp-a`, run @RUN@ (mode complet), commit @COMMIT@ : vert |
| Sauvegardes | `cp-sauvegardes/CP1` |

`kalis_plan` 0.2.0 ajoute un **chemin street** (`lib/src/coach/`) pour les profils au schéma 3 dont la discipline principale est le streetlifting, le sets & reps ou la calisthénie. Les autres profils gardent le chemin 0.1, inchangé.

Ce que le moteur sait faire maintenant, pour ces profils :

- un **plan de saison** calé à rebours sur l'échéance : introduction, construction, intensification, réalisation, allègements, tests, affûtage, semaine de l'épreuve ;
- quatre **styles de programme** : débutant (chemin vers la première traction, échelle de pompes, descentes freinées), sets & reps (série de tête, volume sous-maximal, départs au chrono, répétition de l'épreuve), streetlifting (pourcentages du 1RM en charge totale, série de tête et séries allégées, variantes de point faible, dernier lourd, plan de tentatives), figures (étape actuelle, étape suivante sous condition, dynamique au niveau de l'étape, budget du poignet) ; plus l'hybride avec la course ;
- la **variation dans la semaine** (jours lourd, moyen, léger) et d'une semaine à l'autre ;
- les **repères** : le repère d'un exercice ne monte qu'après un test de cet exercice, jamais sur un progrès supposé ;
- les **garde-fous** : plafonds de volume par groupe et par niveau, hausse de volume et de charge bornée, tenues bras tendus, durée de séance, reprise après coupure (demi-volume puis +10 à 15 % par semaine), zones à ménager, 48 h avant un test de tirage ;
- des **notes de coach** courtes (74 codes, `docs/NOTES_COACH.md`) : pourquoi ce bloc, comment progresser, quoi faire un jour sans, règle de douleur, stratégie de test.

`kalis_bench` 0.1.1 : adaptateur des profils types vers le profil v3 et export lisible enrichi (saison, échelles de figures, règles du programme). Profils types, attentes de coach et grilles du panel **inchangés** (empreintes des cinq grilles revérifiées en fin de lot, identiques à `docs/PANEL.md`).

`kalis_core` 0.4.1 : évolution additive, trois codes de raison pour les notes de coach (`plan.coach_note`, `plan.progression_rule`, `plan.pain_rule`) ; un JSON de 0.4.0 se relit et se réécrit à l'identique.

Documentation : `packages/kalis_plan/CONTRAT.md` § 12 (comportement, tableau de tous les paramètres chiffrés avec leur source, invariants testés) et § 9 (limites connues) ; `docs/NOTES_COACH.md` ; `docs/CALIBRAGE_CP1.md` (journal des 8 passes de notation, recherches ciblées et leurs sources).

## 2. Banc d'essai, avant et après

Profils street (17) :

| Mesure | Moteurs 0.1 (lot CR) | `kalis_plan` 0.2.0 |
| --- | --- | --- |
| Violations de sécurité (programmes créés) | 94 | **0** |
| Attentes de coach tenues | @ATT_BASE@ | **@ATT_NOW@** |
| Panel, moyenne (minimum) | 4,9 (3,0) | **8,97 (8)** |
| Panel, notes à 9 ou plus | 0 sur 68 | **66 sur 68** |
| Relecture documentée, moyenne (minimum) | 3,9 (3) sur les 8 profils relus en manche 0 | **7,41 (7)** sur les 17 profils |
| Non-ressemblance au programme du propriétaire (seuil 0,30) | 0,000 exact | @OWNER@ |
| Non-ressemblance aux six références (seuil 0,30) | 0,014 exact, 0,222 tolérant (cinq références et demie) | **0,130 exact, 0,231 tolérant** (les six, en entier) |

La seule attente non tenue : `street_12_antecedent_coude`, « aucun exercice à contrainte forte sur le coude ». Elle contredit l'objectif déclaré du même profil (un 1RM de dips lestés) : le moteur garde le dips lesté, retire la traction lestée, charge le coude par paliers et renvoie au professionnel qui suit la zone. Le profil et l'attente n'ont pas été modifiés.

Profils des autres disciplines (10) : chemin 0.1 inchangé, mêmes chiffres qu'à la mesure de départ (23 violations, qualité et attentes identiques ligne à ligne).

Détail par profil :

