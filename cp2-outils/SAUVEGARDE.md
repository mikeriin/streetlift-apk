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

## Reprise du 08/10/2026 (session Opus, 16:05 UTC)
- Ligne d'état « en cours depuis 2026-10-08 16:05 UTC » poussée (9b04dc1). add_repo absent ; push vérifié (dry-run).
- Code repris : dernier contrôle de la session du 06/10, f44ada83 (« boucle 5 c »), run 37489327589 (résultats d7f49cc9) : kalis_core/plan/adapt/bench verts (seul `aa_fmt`, outil de formatage du mode dev, en échec sur l'absence de `test` : sans effet) ; formatage d'aa_fmt recopié ; banc : 0 violation sur toutes les saisons street et scénarios (`SECURITE.md`), 23 violations restantes = 10 profils non street sur le chemin 0.1 (partie 1).
- Vérification C9.8 sur les exports b5c : (iv) `street_08` dips S1 ≈ 187 rép. (au lieu de 352), muscle-up arrêté avant la casse → traité ; (i) `street_12` douleur_coude : blocs 2 et 3 « reprise progressive », plus d'affûtage ni de test sur les dips → traité.
- Exports du panel : /tmp/exports_b5c (régénérables : `panel.py build` sur l'archive de d7f49cc9). Changement de lignes vs b2 : 0 % street_04 et street_11, 6 % street_12, 11 à 41 % ailleurs.
- Suite : passe p3 du panel (boucle 3 du panel) sur les couples sous 9 en p2 et les couples à 9 des exports changés de plus de 10 %.
- 08/10 ~17:00 : passe p3 (56 couples) : 15/68, min 4 → aucun gain : arrêt du calibrage de la partie 0 (C9.2). Renote p3b de street_10 et street_12 (exports changés par les corrections) : street_10 6/6,5/7/5,5 ; street_12 8/9/9/9. Final partie 0 : 14/68, min 5, moy 7,62 (`notes/p0_final_comb.json`).
- Relecture indépendante du code (sous-agent) : 12 constats ; corrigés : reprise +10 % (tonnage, séries dures, référence = semaine d'avant), borne de tonnage après une introduction, coude (toutes les limites, départ 67,5 % en 1re semaine), zone sensible ≥ 3/10, poignet arrondi bas, reprise au bloc 0 + durée demandée, nextBlock 0.1 du débutant sans ancienneté, date du repère ≥ 0, commentaire 1RM ; 2 tests ajoutés ; texte de la règle de douleur du poignet unifié. Contrôle dev a4e90d3b : tests verts (formatage synchronisé). Contrôle FULL 152b7c53 en cours (candidat 0.2.3).
- Journal : `packages/kalis_plan/docs/CALIBRAGE_CP2.md` (partie 0 écrite).
- Partie 1 : brouillon appliqué et rebasé sur 0.2.3 dans /home/claude/p1 (branche locale cp2-p1, conflits résolus) — pas encore compilé.
- Reste : publier 0.2.3 (moteurs, étiquette, DECISIONS, ETAT, manche 5 de la page — lecture Artifact OK cette session —, notification) ; puis partie 1.
- 08/10 19:15 : **0.2.3 publié** (moteurs 9b2e9ea3, etiquettes/kalis_plan-v0.2.3, run 37820965364), manche 6 de la page, DECISIONS CP2.1, ETAT « partie 0 publiée », notification envoyée.
- Partie 1 (arbre /home/claude/p1, branche cp2-p1 sur 9b2e9ea3) : contrôles dev ac1b920e, eb2a292e, 5aa0a111. Corrigé : muscle de spécialisation = vocabulaire du catalogue (adaptateur du banc → kalis_bench à monter en version), réserve des WOD en reprise, pas de force athlétique au niveau 0, rameur des WOD hors allure d'endurance, squat du débutant en CrossFit en séries égales ; en attente : éducatifs d'échauffement (unité distance) hors _run, test de mi-parcours à la moitié et borné par le créneau, affûtage des fractions. Fichier de diagnostic temporaire `test/zz_debug_general_test.dart` À RETIRER avant publication.
- 21:50 : partie 1, contrôles successifs ; échecs des propriétés « autres disciplines » ramenés de 64 fichiers à 11 (run 37846013277). En cours : 3cea5767. Banc : `seance_trop_longue` exempte le jour d'épreuve (critère du banc modifié → kalis_bench version suivante, à consigner dans CRITERES.md et la livraison).
- 23:30 : partie 1 — panel a1 (40 couples, exports run 37852402019) : 4/40 à 9, min 3,5, moy 6,15 ; boucle 1 (70fd77e9, run 37856208345 : banc 0 violation sur les 27 profils) ; panel a2 (36 couples) : 6/40, min 5, moy 7,15. Boucle 2 codée (commit local cp2-p1). Sources vérifiées : `notes/sources_p1.md`. Restent 2 échecs de propriété (sortie de 10 min, graines 7770 et 9846) : diagnostic poussé 61ab0bf6.
- 09/10 00:30 : boucle 2 verte (run 37862085855 : paquets verts, banc 0 violation). Rebasé sur moteurs 9f931fbf (CA2 : kalis_core 0.4.3, kalis_adapt 0.3.0, kalis_bench 0.2.3 → ma version du banc : 0.2.4 ou suivante libre). Panel a3 (34 couples) : 8/40, min 5, moy 7,61. Boucle 3 codée et poussée (92aa2f9c).
- 01:50 : panel a4 (16 couples) : 13/40, min 5,5, moy 7,88. Boucle 4 codée (volume musculation, vrais allègements, appui senior). Arrêt du calibrage après la boucle 4 (budget ; la passe finale complète mesure la boucle 4). Relecture indépendante du code de 0.3.0 : 12 constats → corrigés 1-4, 6-9 (+ docs NOTES_COACH, CHANGELOG) ; non corrigés : 10 (espacement 72 h en force à 3 séances, mineur), 11 (adaptateur, latent), 12 (mineurs). Contrôle complet du candidat : 0e216f68.
- Reste : passe finale complète du panel (street 68 couples sur les saisons ; autres 40), relecture documentée (3 sous-agents, sources web), publication (moteurs, étiquettes kalis_plan-v0.3.0 et kalis_bench-v0.2.4), manche 7 de la page, LIVRAISON_CP2.md, DECISIONS CP2.2, ETAT « à valider », page de suivi, notification.
- 2026-10-09 03:39 UTC : passe finale fa (autres) collectée : 15/40 à 9, min 5, moyenne 7,92 (notes/fa_toutes.json). Contrôle dev 3f63f68e en cours.
- 04:05 UTC : relecture documentée faite (notes/relecture_doc) ; contrôle FULL dd6165df (candidat final) poussé.
- 04:10 UTC : non-ressemblance CP2 (max 0,250/0,250), analyse_CP2.tar.gpg sur cp-references 0aa951dd ; livraison en brouillon (LIVRAISON_CP2.md).
