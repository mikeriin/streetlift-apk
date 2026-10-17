# Sauvegarde KM1c4 (conduite sous douleur et rampe du réalisé, référence Koach 1.0.5)

Session Fable 5.1, lancée le 17/10/2026 06:06 UTC ; ligne « en cours depuis 2026-10-17 06:11 UTC » poussée sur `pipeline`.
Base : `moteurs` bcb8422b (Koach 1.0.4 = `kalis_adapt` 1.0.3, `kalis_plan` 0.4.2, `kalis_bench` 0.5.4). Pas de SDK Dart dans la
session (proxy) : Dart seulement sur la CI (`claude/ci-cp-a`, commits « KM1c4 contrôle (dev) », méthode de KR1 : workflow de
mise au point avec matrice de parts, scripts `DEV_KM1C4.sh`, `DEV_ASSEMBLER.sh`, `DEV_LISTE_C7.py`, résultats recommités dans
`ci-out/`). `add_repo` absent de la session ; accès push vérifié par `git push --dry-run` (nouvelle référence) et par le push de
la ligne « en cours ».

## Fait

- Lecture : PIPELINE_CP, DECISIONS_CP (C13, C17.17, C17.23, C17.25, sections KR1 et KS1c2), CAHIER_KM, LANCEMENTS (section
  KM1c4), prompt KM1c4, LIVRAISON_KR1 en entier, CRITERES_KR1, `test_kr1_violations.py`, code de Koach (securite, seance,
  modele.elargir, rupture) et du modèle de vérité (`banc/verite.py`).
- Run A de mise au point poussé à 06:16 UTC (commit 609a5abd sur `claude/ci-cp-a`, run 39009299479) : PART 0 = export KM1 sur
  `kalis_plan` 0.4.2 (34 profils, témoin), sécurité des blocs, pytest, tests km de kalis_bench avec `_planReference` 0.4.2 ;
  PARTS 1-34 = campagne Dart du couple 0.4.2 × Koach 1.0.4 (100 graines) ; assemblage = sécurité (`kr1_securite.py`), liste
  complète des saisons en violation (`DEV_LISTE_C7.py`), critères Dart du groupe 0-5.
- Mécanismes reproduits (traces locales, `trace.py` dans le scratchpad) :
  1. `autres_08` ref b 47 : surcharge épaule 4/10 au jour 4 (vérité), arrêt Koach jours 5-30, reprise 0.5 ensuite ; **budget
     de reprise absent** (`_budget_reprise` → None : aucune habitude mesurée, douleur en semaine 0) → 7 séries épaule en S5
     pour une tolérance vraie 0 (plancher 4 → 6) ; les poussées (gêne 2) ne sont jamais signalées (zone None dans la vérité).
  2. `ks_01` douleur_epaule b 38 : fin de la reprise (part ≥ 1 à S15) ; semaine 14 sans séance d'épaule (séances manquées) →
     « précédente » = 0 → repli sur 0,6 × habitude = 7 au lieu de la dernière semaine réalisée (3) → 7 > 1,5 × 4,5. Les
     tests de fin de bloc consomment le budget comme le travail.
  3. `street_03` seances_manquees b 19 : arrêt poignet 91-105, budget de départ 8 (0,6 × habitude moyenne 11,5 → 6,9…) contre
     une tolérance vraie 4,8 (moitié de l'habitude lissée) → 8 > 7,2.
  4. `street_10` seances_manquees b 34, 47 (et 64, 10 à vérifier) : **la douleur du poignet (4/10, tendons, fin de la semaine
     10) n'a jamais été signalée à Koach** avant la série aggravante (bilan `{'overall': 3}` sans douleur → Koach note 0) ;
     `_pain_known` du modèle de vérité n'est pas remis à faux quand l'épisode tendineux commence (`end_week`), contrairement à
     `overuse` et aux poussées : défaut du banc (Python et Dart `kalis_adapt/lib/src/sim/truth.dart`), à corriger en Python
     ici et à porter en KM2c3.
- Élargissement (rule 5) mesuré sur `ks_test_ppl6` séances manquées b 2 : 15 diagnostics, 5 à 8 composantes sur 35 déjà
  au-dessus de leur a priori dès le premier ; facteurs de variance des capacités de 1,0 à 8,6 par diagnostic (non uniforme).
  Un facteur uniforme borné par « aucune composante au-dessus de son a priori » vaudrait 1 (rien) : retenu à la place un
  mélange convexe vers l'a priori (P ← (1 − λ) P + λ diag(v0)), uniforme, borné par l'a priori de chaque capacité, SDP.
- Sources vérifiées (web) : Silbernagel et al. 2007 AJSM 35(6):897-906 (modèle de surveillance de la douleur, ≤ 5/10, pas
  d'augmentation d'une semaine à l'autre) ; Gabbett 2016 BJSM 50(5):273-280 (ACWR 0,8-1,3, danger ≥ 1,5, hausses < 10 %) ;
  Nielsen et al. 2014 JOSPT 44(10):739-747 (> 30 % sur deux semaines) ; Malliaras et al. 2015 JOSPT 45(11):887-898 (règle des
  24 h, progression si douleur ≤ 3/10).

## En cours

- Écriture des règles 1 à 5 dans la référence Python (plan : `securite.py` zone sensible et règle 4 ; `seance.py` budget par
  zone sensible fondé sur le réalisé, départ 0,5 × habitude, +20 % ou +1 série par semaine de charge, sans saut en fin de
  fenêtre ; `modele.elargir` mélange vers l'a priori ; `banc/verite.py` remise à faux de `_pain_known`).

## Reste à faire

- Tests, fixtures régénérées, paramètres `1.0.5-ref.1`, CHANGEMENTS_1_0_5.md, SOURCES.md, note au contrat, PORTAGE_DART.md,
  PORTAGE_BANC.md ; copies figées 1.0.4 pour les tests Dart (`reference/fix_dart/`, `params/koach_params_d4.json`).
- Campagnes : Python 100 graines sur la CI (parts), critères 1-8 et 11 (graines 0-5), 7 bis (six jeux), jour J, réalisée
  appariée, athlètes sans douleur ; relecture indépendante (Opus) ; contrôle complet ; livraison.
