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

- **Règles 1 à 5 écrites** (référence Python) : `securite.py` (`episode`, `sensible`, `gene_recente`, règle 4 dans
  `conduite`) ; `seance.py` (`_budget_zone_semaine`, `_budgets_zone_jour`, `_compter_ecrit_zone`, budget sur tous les
  items échauffement compris, pas de vrai test sous rampe, `rampe_zone` pour la sortie progressive) ; `modele.elargir`
  (mélange convexe vers l'a priori, λ = `rupture.elargissement_vers_a_priori` 0,25) ; `rupture.py` ; `banc/verite.py`
  (`_pain_known` remis à faux au début d'un épisode tendineux ou de la fiche). Paramètres `1.0.5-ref.1` (6 clés nouvelles,
  `reprise_dose_depart` 0,6 → 0,5 ; copie 1.0.4 dans `params/koach_params_d4.json`). Tests : `test_km1c4_douleur.py`
  (12), `test_rupture.py` (élargissement réécrit), `test_kr1_violations.py` réécrit (0 violation sur les 4 saisons, bornes
  d'exposition, vérité). Tests Dart de `kalis_adapt` 1.0.3 repointés sur `reference/fix_dart/` (copies 1.0.4) et
  `koach_params_d4.json` ; `kalis_bench` (tests km2 et CLI km2) sur `koach_params_d4.json`, `_planReference` 0.4.2.
- Run B poussé à 07:32 UTC (84b3afdb, run 39011629136) : export 0.4.2 (PART 0), campagne Python graines 0-5 de la
  référence 1.0.5 préliminaire (PARTS 41-48, saisons 0.4.2 exportées dans la part).

- Affinement : la semaine du signalement ne sert de référence que si c'est la semaine précédente, et sans hausse
  (un 3/10 sans retrait gèle, ne coupe pas) ; la recherche arrière de la dernière semaine exposée reste strictement
  après la semaine du signalement. 12 tests `test_km1c4_douleur.py`, 5 `test_kr1_violations.py` verts ; fixtures
  régénérées. Documents mis à jour (CHANGEMENTS § B, CONTRAT note et § 8.3, PORTAGE_DART).
- Critère 7 bis (six jeux, Python, témoin stocké) : 24/24, 22, 19, 23, 22, 21 ; contre le témoin de KR1 (même
  témoin) : tenus 18, 15, 14, 18 (+1 : adv-433b3b7e), 17, 15 contre 18, 15, 14, 17, 17, 15 ; cas sous le plancher
  identiques ; jour J moyen ±0,003 (fichiers dans le scratchpad `adv/`, à copier dans `donnees/` à la livraison).
- Runs B et C annulés ; **run D** poussé à 07:40 UTC (2316876f, run 39013954817) : PART 0 export 0.4.2 + tests ;
  PARTS 61-80 campagne Python 1.0.5 sur les 100 graines (20 parts) ; assemblage : `banc/securite_campagne.py`
  (nouveau, agrégation en flux), critères Python 0-5.
- En cours (fond, scratchpad `sansdouleur.*`) : comparaison 1.0.4 / 1.0.5 des 34 profils, scénario référence,
  vérités a et b, graine 0 (prescriptions identiques sans douleur ni diagnostic ?).

- Relecture indépendante (Opus) traitée (B1, B2, M1-M5, mineurs) ; 290 tests Python verts (3.13) ; sous 3.11 / numpy 2.4.6
  (CI) 2 tests de `test_fixtures` échouent sur `numerique.json` (derniers chiffres de flottants d'algèbre linéaire) : déjà
  le cas en KR1 (run A, 1.0.4 : mêmes échecs) ; environnement, pas le lot. Run E poussé à 08:20 UTC (f97cb053, run
  39016950696) : PART 0 vert (export 0.4.2, 40 fichiers de données changés, tests km de kalis_bench verts), PARTS 61-80
  (campagne Python 1.0.5, 100 graines) ; les parts 73 et 80 n'ont démarré qu'à 09:07 (limite de 20 jobs : les
  publications `if: always()` des runs B, C, D annulés tournaient encore — assemblage recalculant la campagne — ;
  `force-cancel` fait). Run F (180c1a2c, demi-parts) annulé, inutile. Publication E attendue vers 12:40-13:00 UTC ;
  publication A (point de départ 0.4.2 × 1.0.4, export 0.4.2) dès qu'un slot se libère (~11:50).
- Temps Python 1.0.4 / 1.0.5 (trois mesures, médianes ; scratchpad `temps_python_km1c4.json`) : écarts de −5 à +4 %,
  dans le bruit. Limite du job du contrôle complet relevée à 240 min (`.github/workflows/ci-paquets.yml`, reco KR1 § 8).
- Squelette de `LIVRAISON_KM1c4.md` dans le scratchpad.

## En cours

- Attente des publications des runs E (sécurité 100 graines, critères Python 0-5) et A (export 0.4.2, point de départ).

## Reste à faire

- Intégrer les données 0.4.2 du run A (`donnees/reference`, `temoin`, `securite_dart`, catalogue, traces), régénérer les
  fixtures, relancer pytest ; rejouer les six jeux d'adversaires (scratchpad `adv/run.sh`) et copier dans `donnees/` ;
  `docs/data/km1c4/` (sécurité E et A, critères, temps), `docs/CRITERES_KM1C4.md`, `donnees/criteres_km1c4.json`, README ;
  CHANGEMENTS (mesures) ; commit `moteurs`, rebase, contrôle complet sur `claude/ci-cp-a` (workflow officiel), push
  `moteurs`, étiquette `kalis_bench-v0.5.5` ; LIVRAISON (pipeline + projet), DECISIONS_CP section KM1c4, ETAT_CP « livré »,
  page de suivi, notification.
