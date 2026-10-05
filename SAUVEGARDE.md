# Sauvegarde CP2 (kalis_plan 0.2.3 puis 0.3.0)

Session Opus 5.5 lancée le 05/10/2026 vers 18:14 UTC (pas de ligne « Lot : » : CP2 seul lot moteur « à faire »). Ligne d'état « en cours depuis 2026-10-05 18:15 UTC » poussée sur `pipeline` (6715658). Base : `moteurs` 9526ac47. Contrôle : `claude/ci-cp-a` (outils : `cp2-outils/ci.sh` quick/dev/full, `fmtsync.py`, `panel.py`, `aa_fmt`). add_repo indisponible dans la session (outil absent) ; push vérifié (dry-run puis push réel de la ligne d'état).

## Fait
- Lectures : PIPELINE_CP, DECISIONS_CP (tout), LANCEMENTS (CP2), prompt CP2, LIVRAISON_CX_correction1, notes de la page (manches 3 et 4 ; aucune note `m4_*_pilotage` au démarrage), corrections nécessaires du panel final de CX c1 (`notes/cxc1_necessaires.md`, 70 corrections sur 45 couples sous 9).
- Référence de départ partie 0 : panel final CX c1 (même version 0.2.2) : 23/68 à 9, min 5,5 (`notes/cxc1_final_comb.json`).
- Code partie 0, boucle 1 (non compilé au moment de la sauvegarde ; contrôle dev poussé 45fec01f) :
  - charges : borne à répétitions différentes (2 rép. d'écart au plus hors pic), référence = dernière semaine de charge (pas l'allègement), coude : +2,5 kg/semaine (5 en pic), tonnage par exercice lesté ≤ +15 % (`_fitLoads`).
  - poignet (`street_10`) : variantes parallettes/anneaux d'abord, une seule grosse séance d'appui, pas de dynamique la séance légère, HSPU sur prise neutre la séance légère, wrist push-ups retirés dès 2/10.
  - tenues vers le critère de passage en réalisation (note `step_criterion`), règle « +1 s » bornée à 75 %.
  - série repère (note `entry_check`) à la première séance sur record non testé récemment.
  - réalisation d'un objectif de répétitions : variante de surcharge gardée, repos-pause aussi pour l'intermédiaire en réalisation, repos de la zone de l'épreuve −15 s/semaine, simulation du test à J−10 (`reps_rehearsal`), plateau → une séance de départs au chrono devient surcharge (traction et dips), texte du repère de mi-parcours : une seule règle.
  - débutant : pompe complète seulement à 3 de maximum, un seul critère pour l'échelle de poussée (2 × 12), tirage du débutant plafonné (assistée 2 séries, tenue 2).
  - `coachEligible` : débutant sans ancienneté accepté.

## Reste à faire
- Compiler (CI dev), corriger ; tests des nouvelles règles ; version 0.2.3.
- Boucles du panel partie 0 (≤ 5, arrêt après une boucle sans gain) ; relecture documentée (3 sous-agents) ; publication intermédiaire 0.2.3 (contrôle vert, étiquette, DECISIONS, ETAT, manche page, notification).
- Partie 1 : autres disciplines → 0.3.0.
