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

## Boucle 1, contrôles
- Dérive du panel vérifiée (ancres p14_a / p08_c : 1/0,5/1/1 et 9/8/8/8) : pas de dérive. Empreintes des grilles vérifiées.
- Contrôle dev 45fec01f : compile ; échecs corrigés (jours d'équilibre vides, borne de charge alignée sur la relecture `coachAudit` : même emplacement vs semaine d'avant allégée comprise, profils 0.1 aléatoires au schéma 2 dans `testing.dart`). Contrôle dev 6fd64980 poussé.
- Ajouts suivants (non poussés au moment de la sauvegarde) : tests « CP2 partie 0 » (coude +2,5 kg, poignet, série repère, pompe du débutant), règle de la relecture `coachAudit` à répétitions différentes, lest léger gardé (`street_11`), budget de tirage du coude (`street_09`).

## Boucle 1, panel p1 (exports du contrôle dev 6fd64980)
- 14/68 à 9, min 5, moyenne 7,58 (`notes/p1_toutes.json`, corrections nécessaires `notes/p1_nec.md`). Contrôle dev 4e0f6515 poussé (boucle 1 c).

## Boucle 2 (en cours, non compilée)
- règle du repère réellement appliquée : séance au chrono, sinon séance de volume → surcharge (même si une séance de force existe ; pas en réalisation d'une épreuve) ; descentes freinées aussi en séances courtes ; textes du repère selon le cas (`checkpoint` lest, `checkpoint_body` sans lest, `checkpoint_hold` figure, `checkpoint_load` 1RM, `checkpoint_ladder` pompe du débutant).
- pompe mains surélevées : maximum > 15 → note `push_height` (crans de 10 cm), séries 8-11.
- figure au repère manqué : tenues à 60 %, plus nombreuses, même temps total, 150 s ; tenues courtes nombreuses : repos 120 s.

## Contrôles
- Contrôle dev 4e0f6515 annulé par GitHub (19:44) ; contrôle dev bf4fc74e (boucle 2) en file d'attente depuis 19:57 (aucun exécuteur attribué à 20:27).

## Partie 1 (préparée en parallèle, arbre /home/claude/p1, branche locale cp2-p1 ; copie dans `p1-travail/`)
- `general.dart` installé (part de skeleton), styles hypertrophy/strength/endurance/conditioning/health, `coachEligible` ouvert aux autres disciplines, `Method.wod` (formats AMRAP/EMOM/RFT/chipper/intervalles portés par le code du groupe), sortie longue bornée à 110 % de la plus longue des 4 semaines (`_enduranceMinutes`), cardio à faible impact, banc : point faible musculaire → spécialisation.

## Boucle 2 (contrôle dev 36939513 : paquets verts sauf 2 tests corrigés en 2 e ; banc : 0 violation)
- Panel p2 (54 couples sous 9, exports `exports_b2`) : combiné 27/68 à 9, min 6, moyenne 8,01 (p1 : 14/68, min 5, 7,58 ; départ CX c1 : 23/68, min 5,5). Corrections nécessaires : `notes/p2_nec.md`.
- Étalonnage CR.6 (deux ancres hors street, `a03_c` force athlétique experte, `a05_a` course mauvaise) : 9,5/9/9/9 et 0/0,5/0/0 (`notes/ancres_autres`).

## Boucle 3 (contrôle dev d87d1845 poussé)
- plafond croisé « même exercice, mêmes répétitions » pour un emplacement nouveau seulement ; réserve écrite qui suit une charge baissée ; écart de répétitions compté 4 au plus ; consigne d'appui de la pompe une fois par bloc ; tenues regroupées à 75 % (3 s au moins, 15 tenues au plus) ; sécurités au squat et au couché ≥ 85 %.

## Reste à faire
- Compiler (CI dev), corriger ; tests des nouvelles règles ; version 0.2.3.
- Boucles du panel partie 0 (≤ 5, arrêt après une boucle sans gain) ; relecture documentée (3 sous-agents) ; publication intermédiaire 0.2.3 (contrôle vert, étiquette, DECISIONS, ETAT, manche page, notification).
- Partie 1 : autres disciplines → 0.3.0.


## Reprise du 06/10/2026 (session Opus, 14:49 UTC)
- Ligne d'état « en cours depuis 2026-10-06 14:49 UTC » poussée (34737a3). add_repo absent ; push vérifié.
- État repris : code du dernier contrôle de la session précédente (a4311cc8, « boucle 4 b », run 37385747396 : paquets verts, banc 0 violation sur les programmes street et `saisons/SECURITE.md`), postérieur à la sauvegarde 62bdb9c.
- **Lecture des notes de la page de relecture (ArtifactData) refusée par le contrôle d'autorisations de la session** : constats C9.8 lus dans `livraisons/RELECTURE_DOCUMENTEE_CX_c1.md` (même contenu que les notes `m4_*_pilotage`). La publication de la manche sur la page sera probablement refusée aussi : à signaler.
- Vérification des constats C9.8 sur les exports a4311cc8 : (i) `street_12` douleur_coude : bloc 2 « réalisation, affûtage, test » après la douleur, dips 2 × 5 → 2 × 19 en S11 → NON traité ; (ii) `street_01` : wrist push-ups et pompes paume à plat au bloc 3 → NON traité ; (iii) `street_07` : 1RM de référence 166,5 kg déclarés (estimé ≈ 150) → NON traité ; (iv) `street_08` : 352 dips en S1 → NON traité ; (v) `street_10` : planche 13 séries en S1 (au sol) → partiellement.
- Boucle 5 (code, contrôle dev a04d9ec6) : bloc de reprise (`coachPainReprise`, `coachRepriseWeeks`, note `pain_reprise`) ; 1RM seulement déclaré remplacé par l'estimation nettement plus basse (borne 85 %) ; plafond de la 1re semaine 4 × maximum (`coachFirstWeekRepsShare`) ; poignet déclaré : figures sans prise neutre ×0,5 (`wrist_spare`) ; douleur signalée sur 3 séances au bloc d'avant → zone « sensible » 2/10 ; consigne pompe poignet neutre (cue 12) ; consigne d'arrêt du muscle-up. Version 0.2.3. 5 tests ajoutés.
- Compte des boucles du panel (C9.2) : p1 (boucle 1), p2 (boucle 2) mesurées ; les boucles 3 et 4 de code n'ont pas de passe du panel sauvegardée → la prochaine passe (p3) est la boucle 3 du panel.
