# Livraison CX correction 1 — saisons street croisées : `kalis_plan` 0.2.2 × `kalis_adapt` 0.2.2

Passe de correction du lot CX (pipeline « Calibrage des programmes », voie A, Opus 5.5 effort maximal), exécutée le 05/10/2026 de 05:38 à 16:30 UTC. Base : `moteurs` e90e33e9. Décision qui l'a lancée : DECISIONS_CP.md C8.4.

**État : à valider — cible non atteinte.** Les paquets sont publiés et leur contrôle complet est vert. Sécurité calculable : **0 violation** sur les saisons de référence et de scénario des 17 profils street (`saisons/SECURITE.md`, modèle B, graine 0) et 0 au rapport des programmes créés. La cible C7.5 (9 au moins pour chaque école × chaque profil) **n'est pas atteinte** : 23 couples sur 68 à 9 (passe complète p7, complétée par la renote p8 des neuf profils changés ensuite), minimum 5,5, moyenne 7,95 (passe finale de CX : 25 sur 68, minimum 4, moyenne 8,01). C7.7 non plus (`street_08` : 6 à 8 ; `street_14` : 7 à 8). Les trois points de sécurité que la passe devait corriger (douleur qui dure, montée de volume du premier bloc, figures de l'élite) sont corrigés dans le moteur ; trois constats de charge restent ouverts (partie 7). Ma recommandation est en partie 8 (C8 : le pilotage décide).

Page de relecture : https://claude.ai/artifact/48CYFBy75Xykohm674vLNq (manche 4, « street complet (CX correction 1, 05/10/2026) »).

## 1. Ce qui est livré

| Élément | Valeur |
| --- | --- |
| Paquets | `kalis_plan` 0.2.2, `kalis_adapt` 0.2.2, `kalis_bench` 0.2.1 (`kalis_core` 0.4.2 inchangé) |
| Branche | `moteurs`, commit 9526ac47 |
| Étiquettes | `etiquettes/kalis_plan-v0.2.2`, `etiquettes/kalis_adapt-v0.2.2`, `etiquettes/kalis_bench-v0.2.1` |
| Contrôle | `claude/ci-cp-a`, run 37330259003 (mode complet), commit dc819ddf (même arbre de `packages/`, à deux fichiers Markdown près : la fin de `docs/CALIBRAGE_CX.md` et `kalis_plan/docs/NOTES_COACH.md`, lus par aucun test) : vert |
| Sauvegardes | `cp-sauvegardes/CX-c1` |
| Contrat | additif ; aucun type ni code de raison de `kalis_core` ajouté ; nouvelles notes de coach `pain_stop`, `pain_return`, `pain_return_item`, `pain_step`, `plateau`, `slow_tempo`, `event_zone` |

Détail des règles, paramètres et sources : `packages/kalis_plan/CONTRAT.md` § 12.14, `packages/kalis_adapt/CONTRAT.md` § 11.15, journal `packages/kalis_bench/docs/CALIBRAGE_CX.md` (section « Correction 1 »).

**`kalis_plan` 0.2.2 (programme écrit), dans l'ordre des points de la passe :**

1. **Douleur qui dure (sécurité).** Une zone à 3/10 ou plus deux semaines, 5/10 plus d'une semaine, ou qui revient : tout mouvement qui la provoque est retiré du bloc (poignet : tous les appuis en extension mains à plat ; coude : aussi le tirage en pronation), consigne de consulter, reprise après deux semaines à 2/10 au plus, à 50 % puis +10 % par semaine, 3 en réserve, lestés vers 67,5 % du 1RM. Une restructuration garde l'arrêt déjà noté. Une figure gardée sur prise neutre porte la note d'arrêt, jamais deux consignes contraires. Pompes sur poignets retirées de l'échauffement si le poignet est douloureux ; recul d'étape de figure écrit avec son critère de retour (`pain_step`).
2. **Repères et tests.** Tests à partir du troisième jour de la semaine, jamais pendant une reprise, jours faciles avant. Un test plus bas de 15 % au plus fait foi ; plus bas, il fait foi confirmé par le test d'avant, et seul il ne fait baisser un repère récent qu'à 85 %. Une série de plusieurs répétitions ne fait pas tomber un 1RM sous 85 % ; un 1RM testé fait foi, un 1RM déclaré ou estimé est relevé par le maximum au poids du corps.
3. **Plateau** : test sans progrès → le bloc suivant change de méthode sur la traction (tempo excentrique, archer, typewriter).
4. **Répétitions** : +15 % par semaine au plus ; répétitions + réserve jamais au-dessus du repère ; zone de l'épreuve (72-80 %, repos court) en réalisation d'un objectif de répétitions ; densité sous 10 de maximum par les départs seuls ; repos-pause réservé à l'avancé et à l'élite.
5. **Charges et tentatives** : hausse bornée d'une semaine à l'autre, aussi d'un bloc à l'autre ; 2,5 % par répétition d'écart après une transition ; ouverture ≥ 98 % du dernier lourd ; affûtage en doubles à 86 %.
6. **Figures** : tenues à 60/65/70 % (75 % au plus) arrondies au plus proche ; tenues longues gardées quand l'objectif est une durée ; étape de travail jamais écartée parce qu'elle a été sautée.
7. **Débutant** : préparation des poignets, tenues +15 % par semaine mais jamais sous 55 % du test, essais stricts seulement sans traction acquise.

**`kalis_adapt` 0.2.2 (séance servie)** : arrêt pour douleur qui dure dans la séance ; sous-dosage corrigé (chaque série jugée contre sa propre réserve, borne basse confirmée par une deuxième mesure, cran d'élastique retiré) ; tests reportés un jour de bilan bas ; tentatives 91 % / +5 % / +3 % ; −7,5 % après un échec non voulu ; simple d'entraînement ≤ 92 % ; jamais plus lourd que l'écrit en allègement ou en test ; la borne de hausse d'une tenue laisse servir 55 % du meilleur maintien.

**`kalis_bench` 0.2.1** : export des saisons (1RM de référence écrit, réserve « sur la dernière série » expliquée), trajectoires. Profils types, seuils et grilles du panel **inchangés**.

Le programme de 40 semaines du propriétaire n'est pas régénéré.

## 2. Banc des saisons, avant et après

Banc `kalis_bench` 0.2.1, contrôle complet (100 graines par modèle de vérité). Moyennes des 17 profils street sur les trois modèles de vérité (`ci-out/packages/kalis_bench/SAISONS.md`). « cx c1 » : `kalis_plan` 0.2.2 × `kalis_adapt` 0.2.2 ; « cx » : la livraison précédente (0.2.1) ; « 0.1 » : les moteurs 0.1 sur la même saison.

| Saison | Couple | Écart d'effort (rép.) | Échecs non voulus | Progression / sem. | Tentatives réussies | Jour J ÷ maximum du jour | Écrit ↔ servi | Violations par saison |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| référence | 0.1 | 1,49 | 0,63 % | 0,174 % | — | — | 6,8 % | 9,93 |
| référence | cx | 1,12 | 0,30 % | 0,278 % | 87 % | 95,6 % | 12,5 % | 0,03 |
| référence | **cx c1** | **1,03** | 0,32 % | 0,252 % | **95 %** | 94,0 % | 12,4 % | **0,01** |
| séances manquées | cx c1 | 1,06 | 0,37 % | 0,122 % | 96 % | 94,2 % | 13,3 % | 0,01 |
| maladie | cx c1 | 1,05 | 0,33 % | 0,251 % | 97 % | 93,1 % | 12,3 % | 0,02 |
| douleur au coude | cx c1 | 1,11 | 0,27 % | 0,167 % | 98 % | 87,7 % | 14,2 % | 0,06 |
| douleur à l'épaule | cx c1 | 1,12 | 0,30 % | 0,171 % | 97 % | 89,3 % | 15,0 % | 0,06 |
| parc seulement | cx c1 | 1,03 | 0,30 % | 0,231 % | 95 % | 94,1 % | 12,5 % | 0,01 |
| échéance avancée | cx c1 | 1,03 | 0,33 % | 0,260 % | 97 % | 93,9 % | 12,2 % | 0,01 |
| deuxième échéance | cx c1 | 0,99 | 0,30 % | 0,229 % | 95 % | 94,9 % | 11,7 % | 0,00 |

Lecture :

- **Plus juste et plus sûr** : effort affiché plus proche du réel (1,03 répétition d'écart contre 1,12), tentatives réussies 95 % contre 87 %, violations du programme tel qu'il a évolué presque nulles (0,01 par saison).
- **Un peu moins de progression simulée** (0,252 % contre 0,278 % par semaine) et un jour J un peu plus prudent (94,0 % contre 95,6 % du maximum du jour) : c'est l'effet attendu des règles de sécurité (repères recalés sur le test, réserve jamais au-dessus du repère, tentatives plus prudentes, arrêt pour douleur). Les scénarios de douleur perdent le plus (coude 0,167 %, épaule 0,171 %) : le moteur arrête vraiment les mouvements qui provoquent la zone.
- **Saisons racontées** (modèle B, graine 0, `saisons/SECURITE.md`) : **0 violation** sur les 136 saisons street (référence et 7 scénarios × 17 profils) ; la livraison précédente en avait 6 dans 4 saisons de scénario.
- **Programmes créés** (`RAPPORT.md`) : 0 violation sur les 17 profils street ; les 23 du rapport viennent des 10 profils des autres disciplines (moteur 0.1, hors périmètre, inchangés).

## 3. Panel (passe complète p7 + renote p8) et relecture documentée

Protocole inchangé (`docs/PANEL.md`) : quatre relecteurs Opus indépendants par passe, un par école, qui ne voient que le profil, l'export concis de la saison, leur grille et le référentiel. Dérive vérifiée avant la première boucle (ancres : 1/1/1/1 et 8/8/8/8, pas de dérive).

**Notes d'ensemble finales** (passe complète p7 sur le contrôle de la boucle 7 ; les neuf profils que la boucle 8 a changés renotés en p8 sur le contrôle de la boucle 8, la dernière notation fait foi) :

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 9 | 8 | 8 | 9 |
| `street_02_debutant_surpoids` | 9 | 8 | 9 | 9 |
| `street_03_debutante` | 7,5 | 7 | 7 | 8 |
| `street_04_reprise_longue_pause` | 9 | 9 | 7 | 8 |
| `street_05_inter_calisthenie_front_lever` | 6 | 8 | 7,5 | 9 |
| `street_06_inter_sets_reps` | 5,5 | 9 | 7,5 | 9 |
| `street_07_avance_streetlifting_competition` | 9 | 9 | 9 | 9 |
| `street_08_avance_sets_reps_competition` | 6 | 8 | 8 | 8 |
| `street_09_elite_streetlifting` | 9 | 8 | 8 | 8 |
| `street_10_elite_figures` | 7 | 6 | 5,5 | 7 |
| `street_11_master_51_ans` | 7 | 7 | 7 | 8 |
| `street_12_antecedent_coude` | 9 | 9 | 8 | 8 |
| `street_13_peu_de_temps` | 7 | 7 | 7,5 | 7,5 |
| `street_14_parc_sans_lest` | 8 | 7 | 8 | 8 |
| `street_15_travail_physique_sommeil_court` | 8 | 7 | 8 | 9 |
| `street_16_specialisation_traction_lestee` | 9 | 9 | 9 | 9 |
| `street_17_hybride_street_course` | 8 | 7 | 8 | 9 |

23 couples sur 68 à 9, minimum 5,5, moyenne 7,95. À 9 partout : `street_07`, `street_16`. Par école : force 7 couples à 9, calisthénie 5, hypertrophie 3, santé 8.

**Évolution des passes** (détail : `docs/CALIBRAGE_CX.md`) : passe 0 (CX, 0.2.1) 24/68, min 4 ; p1 14 ; p2 15 ; p3 (complète) 23, min 6 ; p4 et p5 (partielles, combinées) 35 puis 39 ; p7 (complète) 23, min 5,5 ; p8 (9 profils) sans gain net. Sur des exports proches, le panel varie d'environ un point par couple (C9) : les passes partielles combinées surestiment, la passe complète fait foi. Le gain réel de la passe se lit surtout dans la sécurité et le banc, pas dans le nombre de couples à 9.

**Relecture documentée** (C7.3, sans seuil, C7.6) : trois relecteurs Opus, sources du web seulement, sur les sept profils de la manche 3, au contrôle de la boucle 6. Notes écrites dans la manche 4 de la page (collection `notes`, auteur `relecture-documentee`).

| Profil | Ensemble | Adapté | Progression | Volume | Exercices | Faisable | Manche 3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `street_01` | 7 | 7,5 | 6,5 | 7 | 7 | 8 | 6,5 |
| `street_06` | 6 | 6 | 5 | 6,5 | 6 | 8 | 6 |
| `street_07` | 7,5 | 8 | 7,5 | 7,5 | 8 | 8,5 | 7 |
| `street_08` | 6,5 | 6,5 | 5,5 | 6 | 7 | 7,5 | 6 |
| `street_10` | 5,5 | 5 | 4,5 | 6 | 5,5 | 6 | 5 |
| `street_12` | 7,5 | 8 | 6,5 | 7,5 | 7,5 | 8,5 | 6 |
| `street_14` | 6 | 7 | 5 | 6,5 | 6,5 | 8,5 | 6 |

Moyenne 6,6 (manche 3 : 6,1).

## 4. Relectures traitées

Toutes les notes du panel (p3 à p8) et de la relecture documentée ont été lues en entier ; la page de relecture ne porte aucune note du propriétaire (seulement la relecture documentée, manches 0 à 3, et celle du pilotage, manche 3). La relecture du pilotage (`livraisons/RELECTURE_DOCUMENTEE_CX.md`) a fixé les sept points de la passe (LANCEMENTS.md) :

| Point de la passe | Fait |
| --- | --- |
| 1. Douleur qui dure (sécurité) | Corrigé : arrêt, consultation, reprise graduée, prise neutre pour le coude, lesté vers 67,5 %, variante poignet ; arrêt gardé en restructuration. `street_10` n'a plus la contradiction « figure gardée à 4/10 » + « arrêt » ; 0 violation sur les scénarios de douleur. |
| 2. Moteur qui sous-dose | Corrigé dans `kalis_adapt` (chaque série contre sa réserve, borne basse confirmée, cran d'élastique, tenue servie à 55 % du test au moins). |
| 3. Tests | Corrigé : jours faciles avant, report un jour de bilan bas, repère qui baisse sur un test (borné sans confirmation). |
| 4. Plateau | En partie : changement de méthode écrit pour la traction (maximum ≥ 10) ; ailleurs, renvoyé à CP2 (constat récurrent du panel : bloc de réalisation qui ressemble au bloc de construction). |
| 5. Hausses brutales et tentatives | Corrigé : +15 %/semaine, une série quasi maximale par atelier et par semaine, tentatives 91/+5/+3 %, −7,5 % après un échec, jamais plus lourd que l'écrit en allègement ; borne de charge aussi d'un bloc à l'autre. `street_08` : volume du premier bloc borné ; restent des sauts de charge lestée (partie 7). |
| 6. Figures de l'élite | En partie : tenues 60-70 % arrondies juste, tenues longues gardées pour une durée, planche gardée au dernier bloc ; progression vers 15 s de front lever et budget d'appui du poignet → CP2. |
| 7. Échauffement | Corrigé : montée 40-60-75-85 % avant chaque mouvement lourd et le muscle-up, amplitude progressive des dips du débutant. |

Relecture documentée de cette passe (manche 4), remarque par remarque : tenue servie sous l'écrit et pompes sur poignet douloureux (`street_01`) → corrigés (boucle 7) ; planche retirée du dernier bloc (`street_10`) → corrigé (étape de travail jamais écartée pour sauts) ; 1RM du bloc 3 de `street_12` → non retenu, le relecteur a compté 100 % du poids du corps (115 kg = 36,25 kg + 96 % de 82 kg, le simple du test) ; records déclarés au-dessus du niveau du jour (`street_06`, 07, 08, 12) → test d'entrée en CP2, la série de tête et l'autorégulation recalent en attendant ; lest pour un objectif de répétitions et affûtage de deux semaines (`street_06`), muscle-up après l'échéance et volume de poussée (`street_08`), changement de méthode des figures (`street_10`), volume au chrono (`street_14`) → CP2.

Relecture indépendante du code (sous-agent Opus) : 14 points ; 6 corrigés avant le contrôle complet, les autres écrits au contrat comme limites (`kalis_plan` § 12.14).

## 5. Calibrage

Huit boucles sur dix (C7.2 ; C9.2 « cinq au plus » ne s'applique qu'à partir de CP2 et à une correction 2). Pour chaque boucle : génération sur tout le banc (contrôle `dev` sur `claude/ci-cp-a`), critères calculables, lecture de toutes les notes, corrections du moteur, nouvelle génération, renote des couples sous 9 (passes complètes au départ et à la fin). Recherche ciblée au départ (sous-agent Opus, sources vérifiées, tableau dans `docs/CALIBRAGE_CX.md`) ; chaque paramètre est sourcé ou dit « choix raisonné » au contrat.

Arrêt après la boucle 8 : deux passes sans gain net (p7 au niveau de p3, p8 sans gain), et les constats restants demandent des changements de méthode qui dépassent une correction (partie 8). Grilles, profils types et seuils inchangés.

## 6. Contrôles et non-ressemblance

- Contrôle complet `claude/ci-cp-a`, run 37330259003 (commit dc819ddf) : formatage, `dart analyze --fatal-infos`, tests (propriétés ≥ 10 000 profils seedés) de `kalis_core`, `kalis_plan`, `kalis_adapt`, `kalis_bench`, `kalis_quest`, banc complet, temps de calcul : **vert**.
- Invariants ajoutés aux tests (`kalis_plan` : `test/coach_test.dart` groupe « CX correction 1 », `test/coach_properties.dart` ; `kalis_adapt` : `test/coach_rules_test.dart`, `test/properties.dart`) : arrêt et reprise graduée (poignet, coude), pas de pompes sur poignets à l'arrêt, test plus bas qui fait foi (borné sans confirmation), 1RM non abaissé sous 85 % par une série de plusieurs répétitions, répétitions + réserve ≤ repère (propriété sur tous les profils), recul d'étape jamais sur l'étape de travail (propriété), étape sautée gardée, tests après le premier jour, hausse de répétitions ≤ 15 %, charge lestée bornée d'une semaine et d'un bloc à l'autre à répétitions égales, affûtage ≥ 85 %, tenue du débutant (+15 %, 55 % du test), poignet sous contrainte forte écarté, tests servis avec le matériel du lieu, tenue servie à 55 % du test après le test.
- **Non-ressemblance** (C7.8) : `tool/reference_jaccard.py` sur les 17 saisons écrites du contrôle complet, calculé dans la session avec la clé : maximum exact **0,158**, tolérant **0,188** (seuil 0,30). Détail chiffré ajouté à `cp-references` (`analyse_CXc1.tar.gpg`, commit 8fc968c0). Clé passée à gpg par un fichier `/tmp` en mode 600 (`--passphrase-file`), jamais sur une ligne de commande, fichier supprimé après usage ; aucun nom ni extrait des références dans un fichier, un commit, la page ou cette livraison.
- Sauvegardes toutes les 30 minutes environ sur `cp-sauvegardes/CX-c1`.

## 7. Limites et constats ouverts

**Constats ouverts touchant la charge (aucune violation calculable, mais signalés « nécessaires » par au moins une école) :**

1. **`street_10` (élite figures) — appui du poignet** : la dose d'appui en extension (planche, planche push-up, handstand, HSPU les mêmes jours) part haut sur un poignet déjà gêné ; dans la saison simulée la douleur monte à 3-4/10 vers la semaine 6-10 et l'arrêt se déclenche, comme prévu. Le moteur arrête bien (sécurité tenue), mais il ne prévient pas : budget hebdomadaire d'appui et rampe de départ à écrire (CP2, en tête). Le HSPU à 1 × 11 au retour de reprise (semaine 16) est une incohérence de dosage à corriger avec.
2. **`street_08` — charges lestées après l'échéance** : sauts de 67 à 79 % du 1RM d'une semaine à l'autre en fin de saison ; la borne d'un bloc à l'autre (boucle 8) les limite désormais à +5 % à répétitions égales, mais les sauts à répétitions différentes restent possibles (2,5 % par répétition d'écart).
3. **`street_12` — antécédent de coude** : dips lestés +8,5 % de charge totale entre deux semaines (répétitions différentes), alors que l'antécédent demande des paliers de 2,5 kg.

**Limites de méthode (constats récurrents du panel, renvoyés à CP2 / CA2)** : bloc de réalisation d'un objectif de répétitions qui ressemble au bloc de construction (pas de série longue, de repos-pause ni de simulation à J−10 sous 10 de maximum ; `street_06`, 11, 13, 14, 15, 17) ; progression des tenues de figure jusqu'au critère de passage et exposition à l'étape suivante (`street_05`, 10) ; test d'entrée sur des records déclarés (06, 07, 08, 12) ; échelle de poussée et volume de tirage du débutant (`street_01`, 03) ; troisième exposition de traction (`street_17`) ; variante lourde au parc sans lest (`street_14`) ; jambes et chaîne postérieure ; créneau horaire et temps disponible inutilisé ; profils hors street. Limites du code relevées par la relecture indépendante : `kalis_plan` CONTRAT § 12.14 (fin).

**Restes de la livraison CX non traités ici, comme demandé** (LANCEMENTS.md) : créneau horaire, volume de poussée, jambes, profils hors street, échelle de poussée du débutant, volume de tirage du débutant, troisième exposition de traction → CP2 et CA2.

## 8. Recommandation et suite

Le pilotage décide (C8). Ma recommandation :

1. **Accepter les paquets 0.2.2 comme base** de CP2, de CA2 et de la mise à jour de l'application (CI1 a été validé sur 0.2.1 ; CI1b peut passer sur `etiquettes/kalis_plan-v0.2.2` et `etiquettes/kalis_adapt-v0.2.2`, même contrat, additif). Raisons : la sécurité calculable est à 0 partout (136 saisons street, contre 6 violations avant), les trois points de sécurité de la passe sont corrigés et testés, l'effort affiché et les tentatives sont plus justes ; le panel est au même niveau que CX (23 contre 25 couples à 9, dans l'incertitude d'un point), avec un minimum meilleur (5,5 contre 4).
2. **Ne pas lancer de correction 2 de CX** : les couples sous 9 tiennent à des changements de méthode (point précédent), pas à des réglages ; une passe de plus ferait tourner le panel dans son bruit (C9). Les mettre **en tête de CP2**, dans cet ordre : (a) budget d'appui du poignet et rampe de départ sur les figures d'appui (`street_10`, constat ouvert 1) ; (b) bloc de réalisation d'un objectif de répétitions (série longue, repos-pause, simulation à J−10, variante lourde au parc) ; (c) progression des tenues de figure vers le critère et chevauchement d'étape ; (d) test d'entrée quand les records sont déclarés ; (e) sauts de charge lestée à répétitions différentes et paliers de 2,5 kg pour un antécédent (constats 2 et 3).
3. **CA2** : conduite sous douleur (arrêt et reprise côté séance sont en place) ; meilleur maintien qui ne baisse pas après un arrêt (relecture du code).
