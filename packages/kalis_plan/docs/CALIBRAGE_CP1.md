# Calibrage CP1 — kalis_plan 0.2.0 (profils street)

Journal du calibrage du lot CP1 : le moteur de création de programmes de street workout `kalis_plan` 0.2.0 (chemin « coach » des profils street) a été réglé en boucles. Chaque boucle a été notée par deux jurys indépendants. Ce document rassemble le résultat, la méthode, les recherches qui ont guidé les corrections, le journal des boucles 0 à 7, les sources de la relecture finale, les demandes non suivies et ce qui reste à faire.

Sources de ce journal : le journal brut des boucles (`SAUVEGARDE.md`), les cinq rapports de recherche et la liste `sources_web.md`, les notes du panel par boucle (`panel/p0` à `panel/p7`, `panel/final.json`, renotations `panel/p8`) et les notes de la relecture documentée finale (`doc_a` à `doc_e`). Tous les chiffres ci-dessous ont été recalculés à partir de ces fichiers.

## 1. Résumé

### Résultat

| | Cible du lot | Résultat final |
| --- | --- | --- |
| Panel (4 écoles × 17 profils = 68 notes) | chaque note ≥ 9, moyenne ≥ 9,5 | minimum 8, moyenne 8,97 ; 66 notes sur 68 à 9 ou plus |
| Relecture documentée (17 notes) | chaque note ≥ 9, moyenne ≥ 9,5 | minimum 7, moyenne 7,41 |
| Banc (17 profils street) | 0 violation de sécurité | 0 violation de sécurité |

Les deux notes du panel restées à 8 sont celles de l'école calisthénie sur street_08 et sur street_14 (une correction nécessaire chacune, voir § 6). Au banc, toutes les attentes de coach sont tenues sauf une : sur street_12, l'attente « aucun exercice à contrainte forte sur le coude » contredit l'objectif de l'athlète (un 1RM de dips lestés). Ce conflit est documenté depuis la boucle 2 et n'a pas été levé.

**Verdict : la cible n'est pas atteinte.** Le panel finit juste sous 9 de moyenne (8,97 contre 9,5 visé). La relecture documentée reste à 7,41, loin de la cible, avec 7 comme note la plus basse.

### Moyenne et minimum par boucle et par jury

| Boucle | Panel : moyenne | Panel : minimum | Notes du panel ≥ 9 | Corrections nécessaires (panel) | Relecture : moyenne | Relecture : minimum | Corrections « haute » (relecture) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | 6,89 | 4 | 4 / 68 | 151 | 5,76 | 4 | 44 |
| 1 | 7,76 | 5 | 14 / 68 | 80 | 6,47 | 5 | 36 |
| 2 | 8,38 | 7 | 30 / 68 | 42 | 6,94 | 6 | 30 |
| 3 | 8,68 | 7 | 47 / 68 | 23 | 7,29 | 6 | 16 |
| 4 | 8,84 | 8 | 56 / 68 | 12 | 7,29 | 7 | 25 |
| 5 | 8,79 | 7,5 | 53 / 68 | 15 | 7,41 | 6 | 18 |
| 6 | 8,90 | 8 | 60 / 68 | 8 | 7,00 | 6 | 25 |
| 7 (passe finale complète) | 8,90 | 8 | 61 / 68 | 7 | 7,41 | 7 | 18 |
| Final (boucle 7 + six couples renotés) | 8,97 | 8 | 66 / 68 | 2 | 7,41 | 7 | 18 |

La relecture documentée n'a pas été refaite après la boucle 7 : ses notes finales sont celles de la boucle 7.

### Pourquoi le calibrage s'est arrêté à la boucle 7

1. **Plateau.** Des boucles 3 à 7, le panel est passé de 8,68 à 8,84, 8,79, 8,90 puis 8,90 (8,97 après la renotation de six couples). Sur les mêmes boucles, la relecture documentée a donné 7,29, 7,29, 7,41, 7,0 puis 7,41. Les quatre dernières boucles n'ont plus fait bouger la relecture documentée de façon mesurable, et le panel gagnait au mieux quelques centièmes par boucle.
2. **Dispersion du jury documenté.** À la boucle 6, trois profils (street_05, street_10, street_11) ont été renotés sur un export inchangé : leur note est passée de 7 à 6 sans aucun changement du programme, puis est revenue à 7 à la boucle 7. Le bruit du jury documenté est donc d'au moins un point par profil, du même ordre que les gains recherchés (de 7,4 vers 9,5 de moyenne).
3. **Demandes contradictoires entre jurys.** Plusieurs corrections demandées par un jury ont été pénalisées par l'autre à la boucle suivante. Exemples tirés des notes :
   - **Volume de tirage du débutant (street_01, street_03).** Le panel (hypertrophie aux boucles 3, 4 et 6, santé à la boucle 5) demande de plafonner le tirage vertical à 10–12 séries par semaine, puis à 8–10, et au plus 6 par séance. La relecture documentée demande au contraire plus de travail excentrique : à la boucle 5, « traction négative seulement 2 × 3 à 3 × 3, deux fois par semaine » est une correction de priorité haute sur street_01 ; à la boucle 7, elle demande encore 2–3 × 5–10 s de tenue menton au-dessus de la barre sur les trois séances.
   - **Affûtage du débutant (street_01, street_03).** À la boucle 5, l'affûtage a été porté à −45 %. L'école force l'a jugé contraire au référentiel (R3-P12 : pour un débutant, 3 à 5 jours allégés à −30 %) et en a fait une correction nécessaire ; la boucle 6 est revenue à un affûtage court à −30 %. À la boucle 7, la relecture documentée demande l'inverse : « réduire de 40–60 % les séries de tous les exercices sur S11–S12 » (méta-analyse de Bosquet 2007).
   - **Repos-pause (street_06, street_14).** À la boucle 5, l'école force demande de ramener le repos-pause « à la dose de R2-P13 : 2 à 3 relances de 20 s au plus après la dernière série de travail, une seule fois par semaine et par mouvement ». La même boucle, la relecture documentée demande sur street_14, en priorité haute, de « passer le repos-pause à deux fois par semaine en bloc 2 ».
   - **Seuil de douleur du coude (street_12).** À la boucle 3, trois écoles demandent un seuil unique à 3/10 et l'école santé un seuil à 2/10. À la boucle 7, l'école force demande 2/10 pour toute progression de charge, tandis que la relecture documentée demande d'« harmoniser sur ≤ 3/10 pendant la séance et retour au niveau de base le lendemain » (modèle de suivi de la douleur qui tolère jusqu'à 5/10). La version à 2/10 a été retenue : le panel l'a notée 9 à la renotation.
   - **Lest proche du poids du corps (street_11 : 10 tractions, 1RM à +15 kg).** À la boucle 4, trois écoles du panel demandent un vrai lest dès la semaine 1 (« environ +5 à +7,5 kg dès S1 », « 4 × 5 à +5 kg »). À la boucle 5, la relecture documentée juge, en priorité haute, que les charges écrites (+3,75, +7,5 puis +10 kg) correspondent à des séries de 2–3 RM et demande le poids du corps au bloc 1 et +0 à +2,5 kg au bloc 2. La solution finale (départ conseillé, puis série de calibrage à la réserve) a été notée 9 par l'école hypertrophie, mais la relecture documentée en reste à 7.

## 2. Méthode

### Les deux jurys

**Le panel.** Quatre écoles notent chaque programme : force/streetlifting, calisthénie/figures, hypertrophie/esthétique, santé/kiné (endurance et santé). Chaque école a sa grille gelée de neuf critères (F1–F9, C1–C9, H1–H9, S1–S9), des règles communes et le référentiel interne (principes cités par identifiant, par exemple R3-P12). Les empreintes des cinq grilles ont été vérifiées au début du lot. La note d'ensemble sur 10 découle du nombre de corrections **nécessaires** : 9 = aucune correction nécessaire (programme que le coach signerait), 8 = une correction nécessaire simple, 7 = deux ou trois, 5–6 = plus de trois. Un risque réel pour la santé plafonne la note à 5 ; un programme qui ignore l'objectif ou l'échéance la plafonne à 6. Les programmes sont répartis par lots de quatre au plus par dossier ; le correcteur ne sait pas qui a écrit le programme.

**La relecture documentée.** Un relecteur indépendant par groupe de profils (cinq groupes à la boucle 7 : street_01–04 ; street_05, 06, 11, 12 ; street_13, 14, 15, 17 ; street_07, 08, 16 ; street_09, 10). Il ne connaît ni les grilles ni le référentiel interne. Il s'appuie seulement sur des sources web qu'il lit lui-même (prises de position d'organismes, méta-analyses, fédérations, ressources d'entraîneurs reconnues), et cite pour chaque correction la source et une priorité (haute, moyenne, basse). Il note six critères de 1 à 10 (ensemble, adapté au profil, progression, volume et intensité, choix d'exercices, faisabilité) ; 9 = ce qu'un entraîneur qualifié signerait selon les sources.

**Le banc.** Le banc `kalis_bench` vérifie à chaque boucle les 17 profils street : violations de sécurité et attentes de coach écrites dans les profils.

### Économie de notation

- Passe complète au début (boucle 0) et à la fin (boucle 7) : 17 profils × 4 écoles, plus la relecture documentée des 17 profils.
- Entre les deux, le panel ne renote que les couples (profil, école) notés sous 9 ou dont l'export a changé de plus de 10 % ; les autres reprennent la note de la boucle précédente. Exemples : boucle 4, dix profils renotés (01, 02, 03, 05, 08, 09, 11, 12, 14, 17) ; boucle 5, huit profils sur les quatre écoles et deux (09, 11) sur trois écoles ; boucle 6, quatre profils sur les quatre écoles et quatre (09, 11, 12, 14) sur deux écoles. Le journal ne précise pas la part renotée aux boucles 1 à 3.
- La relecture documentée a porté sur les 17 profils aux boucles 5, 6 et 7.
- Après la boucle 7, six couples ont été renotés (dossier `p8`) après de petites corrections : street_02 santé, street_11 hypertrophie, street_12 force (deux fois), street_14 calisthénie, street_17 force et street_17 hypertrophie. Ce sont ces renotations qui portent le panel de 8,90 à 8,97.

### Quota de recherche web

Le quota de recherche web (WebSearch) de la session s'est épuisé dès la boucle 0, pendant la relecture documentée (200 recherches sur 200). Les relecteurs documentés des boucles suivantes n'ont donc plus cherché de nouvelles sources : ils ont lu eux-mêmes leurs sources par WebFetch à partir de la liste `sources_web.md`, constituée à la boucle 0 (liste au § 3.6).

## 3. Recherches ciblées

Cinq recherches ciblées ont été faites pendant le lot, chacune sur un point faible relevé par les jurys. Chaque rapport ne cite que des pages réellement ouvertes et marque « non vérifié » les chiffres courants sans source. Ci-dessous, pour chaque rapport : les conclusions retenues dans le moteur (avec la boucle où elles apparaissent, quand le journal la donne), puis les sources web.

Note : les sources qui nomment un programme d'entraînement commercial ou son auteur sont citées par leur site, sans nom de programme ni d'auteur ; deux pages dont l'adresse même nomme un programme ne sont pas reprises (voir la fin du § 5).

### 3.1 Débutant (rapport A)

Conclusions retenues :
- Chemin vers la première traction : traction à l'élastique, descentes freinées (négatives) et tenue menton au-dessus de la barre, tirage vertical à chaque séance (boucles 1 à 3). Les rapports d'organismes militaires et d'entraîneurs mettent la traction assistée, les négatives et les tractions sautées en tête du transfert vers la traction stricte.
- Dose des négatives : 2 à 3 séries de 2 à 3 répétitions, descente de 3 à 7 s, 2 à 3 fois par semaine ; la descente s'allonge de 4–5 s vers 7 s au fil des blocs (boucles 1, 5, 6). Plafond des répétitions excentriques par séance selon le référentiel (R5-P8).
- Élastique : on prend celui qui laisse 8 répétitions propres avec la réserve prévue ; on passe au plus fin quand le haut de la plage passe. Dès que l'élastique le plus fin passe 8 répétitions, 1 à 3 essais isolés de traction stricte en début de séance (repère « 10 répétitions ou plus avec l'élastique léger et une descente de 3–5 s maîtrisée »).
- Essai strict à chaque test, frais, avant la descente chronométrée (boucles 4 à 6).
- Pompes : progression par la pompe inclinée (mains sur la barre basse ou les barres parallèles), plus fine que la pompe sur les genoux (charge d'environ 41 à 55 % du poids du corps selon la hauteur, contre 69–75 % au sol) ; passage au palier suivant vers 12–15 répétitions propres.
- Volume : 1 à 3 séries par exercice au départ (deux séries par exercice les deux premières semaines, boucle 6), chaque grand groupe au moins 2 fois par semaine, 3 séances espacées de 48 h, environ 10 séries par groupe et par semaine comme cible à atteindre progressivement (ACSM 2009 et 2026).
- Effort : pas d'échec ; 3 à 4 répétitions en réserve au début, 2 en fin de cycle (« a few reps short of failure », ACSM 2026 : l'échec n'est pas nécessaire).
- Progression : double progression (haut de la plage atteint sur toutes les séries → variante ou élastique suivant).
- Allègement : optionnel chez le novice (consensus Delphi : toutes les 4 à 6 semaines chez les athlètes de force, non validé chez le novice).
- Débutant en surpoids : la musculation ne fait pas maigrir seule mais garde la masse maigre ; il faut plus d'activité d'endurance. Le moteur ajoute une marche progressive vers 150 puis 200 min par semaine (boucle 5 et renotation finale : départ à deux marches de 15–20 min), un suivi (séances cochées, minutes de marche, poids et tour de taille aux semaines 1, 6 et 12) et un déficit modéré. Pas de sauts ni de pliométrie, peu de transitions au sol.
- Objectif ambitieux annoncé honnêtement (« plusieurs tractions depuis zéro, possible, pas garanti »), le délai d'obtention de la première traction n'étant documenté que par des observations de terrain.

Sources :
1. ACSM, Progression Models in Resistance Training for Healthy Adults, 2009 — https://www.sportgeneeskunde.com/wp-content/uploads/ACSM-Position-Stand-Progression-Models-in-Resistance-Training-for-Healthy-Adults.pdf
2. ACSM, nouvelles recommandations 2026 sur la musculation (communiqué) — https://www.newswise.com/articles/acsm-unveils-landmark-2026-resistance-training-guidelines-first-update-in-17-years
3. ACSM, infographie de la prise de position 2026 — https://acsm.org/wp-content/uploads/2026/03/Resistance-Training-Position-Stand-infographic.pdf
4. Université du Nouveau-Mexique, résumé des recommandations ACSM 2011 — https://www.unm.edu/~lkravitz/Article%20folder/ACSMGuidelinesUNM.pdf
5. Refalo et al. 2024, proximité de l'échec et hypertrophie (méta-analyse, Sports Med) — https://dro.deakin.edu.au/articles/journal_contribution/Influence_of_Resistance_Training_Proximity-to-Failure_on_Skeletal_Muscle_Hypertrophy_A_Systematic_Review_with_Meta-analysis/22030796
6. Ralston et al. 2018, fréquence hebdomadaire et gain de force (Sports Med Open) — https://link.springer.com/article/10.1186/s40798-018-0149-9
7. Corps des Marines des États-Unis (USMC), document d'entraînement à la traction pour débutant — https://www.marines.mil/Portals/1/Docs/PullupTrainingProgramNovice.pdf
8. USMC, document sur la progression en traction — https://www.marines.mil/Portals/1/Docs/SecretToPullupsHowToGoFrom0To20.pdf
9. McGuire et al. 2011, tractions et pompes comme alternatives à la suspension bras fléchis (DTIC) — https://apps.dtic.mil/sti/pdfs/ADA554498.pdf
10. Calisthenics Corner, tractions à l'élastique — https://www.calisthenics-corner.com/articles/band-assisted-pull-ups/
11. Garage Gym Reviews, progression vers la traction — https://www.garagegymreviews.com/pull-up-progression
12. bibleofcalisthenics.substack.com, progression vers la traction — https://bibleofcalisthenics.substack.com/p/pull-up-progression-from-beginner
13. Contreras et al. 2012, biomécanique de la pompe (Strength Cond J) — https://bretcontreras.com/wp-content/uploads/The-Biomechanics-of-the-Push-up-Implications-for-Resistance-Training-Programs.pdf
14. Wurm, Ebben et al. 2010, analyse cinétique de variantes de pompes (ISBS) — https://ojs.ub.uni-konstanz.de/cpa/article/view/4457
15. NASM, fiche de la pompe inclinée — https://www.nasm.org/resource-center/exercise-library/incline-push-up
16. bibleofcalisthenics.substack.com, progression vers la pompe — https://bibleofcalisthenics.substack.com/p/push-up-progression-from-beginner
17. stevenlow.org, bases de l'entraînement de force au poids du corps — https://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/
18. Fiche d'entraîneur sur les dips — https://exercises.kemitchell.com/sources/JTVK-how-to-do-a-perfect-dip
19. Bell et al. 2023, allègement : consensus Delphi (Sports Med Open) — https://shura.shu.ac.uk/32417/1/s40798-023-00633-0.pdf
20. HPRC (département de la Défense des États-Unis), progresser dans son entraînement — https://www.hprc-online.org/physical-fitness/training-performance/guidelines-progress-your-physical-training-over-time
21. Donnelly et al. (ACSM) 2009, activité physique et perte de poids — https://read.qxmd.com/doi/10.1249/MSS.0b013e3181949333
22. Obesity Canada 2020, activité physique et prise en charge de l'obésité — https://obesitycanada.ca/wp-content/uploads/2020/08/Physical-Activity-in-Obesity-Management.pdf
23. ACE, entraîner des personnes en situation d'obésité — https://www.acefitness.org/resources/pros/expert-articles/6459/tips-for-training-clients-impacted-by-obesity/
24. Université George Mason, réduire le risque de blessure chez les personnes obèses — https://cehd.gmu.edu/features/2024/02/23/exercise-tips-for-reducing-risk-of-injury-in-obese-individuals
25. Fradkin et al. 2010, effets de l'échauffement (JSCR) — https://www.bisp-surf.de/Record/PU201102000946

### 3.2 Endurance de force au poids du corps, « sets & reps » (rapport B)

Conclusions retenues :
- Spécificité : les séries longues sous-maximales font progresser le nombre maximal de répétitions ; la charge lourde fait progresser le 1RM (études de 2002 et 2015, méta-analyse de 2017). Le volume au poids du corps reste la méthode principale ; le lest reste un complément minoritaire.
- Fréquence du mouvement visé : 2 à 3 séances par semaine pour l'intermédiaire ; pas de gros volume de traction tous les jours (au plus 10 séries par séance selon une source militaire).
- Séries de tête calées sur le dernier maximum mesuré (série de tête = résultat − 2), jamais sur un progrès supposé (boucles 2 et 3) ; séries au chrono sous-maximales à environ 40–50 % du maximum ; échec réservé aux tests.
- Repos : 1 à 2 min pour les séries de 15 répétitions et plus, plus de 2 min pour le lourd (ACSM 2009, Grgic 2018) ; 1 min entre ateliers dans certains formats de compétition.
- Repos-pause : dose limitée (au plus 3 relances de 20 s, un seul mouvement par semaine, à partir de la 2e semaine du bloc ; boucles 5 et 6).
- Simulations de l'épreuve : dans l'ordre de l'épreuve, la dernière à J−7 ou J−10 ; une série par atelier en répétition générale (boucle 4).
- Affûtage : environ 2 semaines, volume −40 à −60 %, intensité et fréquence gardées (Bosquet 2007, Pritchard 2015) ; séance facile à J−2 du test, 48 h sans travail dur avant un test (boucles 2 et 4).
- Muscle-up : 3 à 5 tentatives de qualité, 2 à 3 min de repos ; pas de passage d'un bras après l'autre ; muscle-up après la traction quand l'objectif est la traction (boucle 3).
- Tests : même barre et mêmes standards que l'épreuve, à plus de 48 h d'une séance à l'échec ; un test intermédiaire par cycle.
- Séances courtes : séries enchaînées tirage/poussée pour gagner du temps à adaptations égales (méta-analyse de 2025).

Sources :
1. Art of Manliness, pratique fréquente et sous-maximale — https://www.artofmanliness.com/health-fitness/fitness/get-stronger-by-greasing-the-groove
2. Contact, plan pour augmenter le nombre de tractions — https://www.contactairlandandsea.com/2017/08/26/tactical-plan-increase-pull-ups
3. Military.com, ce qu'il faut faire et éviter pour maximiser ses tractions — https://military.com/military-fitness/ask-stew-workout-dos-and-donts-those-trying-max-out-pull-ups
4. Military.com, séances pour sortir d'un plateau en traction — https://www.military.com/military-fitness/best-pull-workouts-get-unstuck-your-progression
5. Mountain Tactical Institute 2016, résultats d'une étude sur la progression en traction — https://mtntactical.com/?p=92680
6. Campos et al. 2002 (Eur J Appl Physiol) — https://pubmed.ncbi.nlm.nih.gov/12436270/
7. Schoenfeld et al. 2015 (JSCR, résumé) — https://lida.sport-iat.de/ta/Record/4037869?lng=en
8. Schoenfeld et al. 2017, charges lourdes contre légères (JSCR, résumé) — https://www.cka.ca/en/nlka-current-issues/strength-and-hypertrophy-adaptations-between-low--vs-high-load-resistance-training
9. Refalo et al. 2022, échec et hypertrophie (Sports Med) — https://openrepository.aut.ac.nz/items/78679612-6ff4-4d00-95d1-7920d072a760/full
10. Robinson et al. 2024, proximité de l'échec, force et hypertrophie (Sports Med) — https://lida.sport-iat.de/ta/Record/4089104?lng=en
11. Morán-Navarro et al. 2017, récupération avec ou sans échec (Eur J Appl Physiol) — https://paulogentil.com/pdf/Time%20course%20of%20recovery%20following%20resistance%20training%20leading%20or%20not%20to%20failure.pdf
12. ACSM 2009, prise de position (MSSE) — https://sfu.ca/~ryand/kin343/ACSMresistance.pdf
13. Grgic et al. 2018, durée de repos (Sports Med) — https://lida.sport-iat.de/ta/Record/4047011
14. Zhang, Weakley et al. 2025, séries enchaînées (Sports Med) — https://eprints.leedsbeckett.ac.uk/id/eprint/11908
15. Robbins et al. 2010, séries agoniste-antagoniste (JSCR) — https://vuir.vu.edu.au/6830/
16. Iversen et al. 2021, programmes économes en temps (Sports Med) — https://lida.sport-iat.de/ta/Record/4073965
17. EuroGames Berne 2023, règlement street workout — https://eurogames2023.ch/street-workout-2/
18. Calisthenics World eGames, règlement Strength & Endurance — https://www.sportdata.org/calisthenics/ausschreibungen/10/03.Official%20Rules%20And%20Regulations%20World%20eGames%20-%20Strength&Endurance.pdf
19. FINAL REP, format League of Reps — https://final-rep.com/?p=7871
20. Wikipédia, test physique du corps des Marines — https://en.wikipedia.org/wiki/United_States_Marine_Corps_Physical_Fitness_Test
21. Bosquet et al. 2007, méta-analyse sur l'affûtage (MSSE) — https://pubmed.ncbi.nlm.nih.gov/17762369/
22. Pritchard et al., affûtage des powerlifters élites néo-zélandais (JSCR) — https://researchonline.ljmu.ac.uk/id/eprint/2455/
23. Wiki r/bodyweightfitness, muscle-up (miroir) — https://twt.omada.cafe/r/bodyweightfitness/wiki/exercises/muscle-up
24. BullBarFit, de la traction au muscle-up — https://bullbarfit.com/blogs/q-as/what-training-progression-can-lead-from-standard-pull-ups-to-performing-a-muscle-up
25. Breaking Muscle, préparer ses articulations au muscle-up — https://breakingmuscle.com/prep-your-joints-for-muscle-ups/
26. Coyne et al. 2015, fiabilité des tests de traction et de dips lestés — https://ro.ecu.edu.au/ecuworkspost2013/2422

### 3.3 Streetlifting (rapport C)

Conclusions retenues :
- Base de calcul : pourcentages sur la charge totale (poids du corps + lest) pour le haut du corps, sur la barre pour le squat ; lest arrondi à 1,25 kg, squat à 2,5 kg (règlements ISF et FinalRep).
- Lest proche du poids du corps : la charge ne se calcule plus en pourcentage mais à la réserve ; départ conseillé puis série de calibrage (boucles 4 à 6 et renotation finale).
- Périodisation à rebours sur l'échéance : construction, intensification, réalisation, affûtage ; blocs de 4 à 6 semaines calés pour finir sur l'échéance (ACSM 2009 pour l'avancé : charges de 80 à 100 % du 1RM, 1 à 6 RM).
- Série de tête puis séries allégées (environ −10 % de la charge totale) ; 1RM de travail affiché sur un seul repère (boucle 3) ; pas de simple lourd hors épreuve de force (boucle 3).
- Allègement toutes les 4 à 6 semaines, volume −30 à −50 %, intensité gardée.
- Affûtage : volume −40 à −60 % (−58,9 % chez des powerlifters élites), intensité gardée, dernier lourd à J−7 / J−10, rappel lourd à J−4 / J−6 avant un test daté de 1RM (boucles 2 et 6), accessoires retirés environ 2 semaines avant.
- Tentatives : environ 91 % du 1RM (une barre déjà réussie à l'entraînement), puis 96 %, puis la deuxième + 2,5 à 5 kg selon sa vitesse ; montée 40, 60, 75 puis 85 % avant la première (boucle 2).
- Variantes du point faible (partiels, départs arrêtés) en complément, pas en remplacement ; partiels à 95–105 % (boucle 5).
- Spécialisation : les mouvements non prioritaires gardent environ un tiers du volume avec l'intensité conservée (entretien du squat hors objectif, boucle 2).
- Coude : douleur jusqu'à 3/10 tolérée pendant l'effort, revenue au niveau de base le lendemain matin ; prise neutre ; isométries de 30 à 60 s en phase irritable ; 8 à 12 semaines de progression. Seuil unique de la zone (boucle 7 puis 2/10 à la renotation de street_12).

Sources :
1. ISF, règlement technique v3.1 — https://streetlifting.ru/docs/rules/ISF_EN_Technical_Rules_Book_Ver_3.1.pdf
2. FinalRep, règlement streetlifting 2025 — https://streetworkoutslovenija.si/wp-content/uploads/2025/07/STREETLIFTING-RULEBOOK-2025.pdf
3. Kensui, calculer le 1RM en traction et dips lestés — https://kensui.com/blogs/news/calculate-1rm-for-weighted-pullup-and-dip
4. ACSM 2009, prise de position — https://sfu.ca/~ryand/kin343/ACSMresistance.pdf
5. Androulakis-Korakakis et al. 2021, dose minimale chez les powerlifters (Front Sports Act Living) — doi:10.3389/fspor.2021.713655
6. Pelland et al. 2024, volume et fréquence (préprint SportRxiv) — https://sportrxiv.org/index.php/server/preprint/download/460/967/908
7. Bell et al. 2022, allègement (Front Sports Act Living) — https://shura.shu.ac.uk/31253/1/fspor-04-1073223.pdf
8. Bosquet et al. 2007, méta-analyse sur l'affûtage — https://coachsci.sdsu.edu/csa/vol131/bosquet.htm
9. Travis et al. 2020, affûtage et pic en powerlifting (Sports) — https://www.mdpi.com/2075-4663/8/9/125
10. Pritchard et al., affûtage des powerlifters élites néo-zélandais — https://researchonline.ljmu.ac.uk/id/eprint/2455/
11. Grgic & Mikulic 2017, affûtage de champions croates (JSCR) — https://www.bib.irb.hr:8443/859294
12. Pritchard et al. 2018, arrêt court avant compétition — https://ro.ecu.edu.au/ecuworkspost2013/4566
13. powerliftingtowin.com, choisir ses tentatives — https://www.powerliftingtowin.com/how-to-pick-your-attempts-at-a-powerlifting-meet/
14. Strength Shop 2025, guide d'une première compétition de streetlifting — https://strengthshop.eu/blogs/news/blogs-guides-streetlifting-competition-dip-belt-first-meet-guide
15. Wolf et al. 2023, amplitude complète ou partielle (Int J Strength Cond) — https://journal.iusca.org/index.php/Journal/article/view/182
16. Coombes, Bisset, Vicenzino 2015, épicondylalgie latérale (JOSPT) — https://wikiMSK.org/w/img_auth.php/3/30/Coombes2015_Management_of_Lateral_Elbow_Tendinopathy.pdf
17. Physiotutors, tendinopathie latérale du coude — https://www.physiotutors.com/how-to-assess-and-treat-lateral-elbow-tendinopathy/
18. Silbernagel et al. 2007, modèle de suivi de la douleur (résumé) — https://physicaltherapyfirst.com/blog/continued-sports-activity-using-a-pain-monitoring-model-during-rehabilitation-in-patients-with-achilles-tendinopathy/
19. nielasher.com, épicondylalgie médiale — https://nielasher.com/blogs/treatment-guides/medial-epicondylalgia-golfer-s-elbow-causes-symptoms-treatment-and-evidence-based-rehabilitation
20. HPRC / NSCA, 1RM et échauffement — https://www.hprc-online.org/articles/one-rep-max-for-strength
21. Bickel et al. 2011, dose d'entretien (MSSE) — https://search.pedro.org.au/search-results/record-detail/30166

### 3.4 Figures statiques (rapport D)

Conclusions retenues :
- Dosage des tenues : 60 à 75 % du dernier maintien maximal mesuré (60–70 % dans la source ; plage 60–75 % écrite dans les programmes), environ 40 à 60 s de tenue cumulée par séance.
- Échelles de figures avec critère de passage mesurable (boucle 3) ; étape suivante ouverte sous condition, en tentatives, jamais au calendrier (boucles 2 et 4) ; étape actuelle prioritaire sur l'étape facile (boucle 3).
- Re-test du maximum environ toutes les 2 à 4 semaines et recalage des secondes.
- Honnêteté sur l'échéance : aucune durée sourcée pour obtenir un front lever ou une planche complète ; chaque étape demande au moins 6 semaines (le tendon s'adapte plus lentement que le muscle). La figure complète n'est pas promise dans un programme de 16 semaines.
- Tendons : 2 à 4 séances par semaine par figure, au moins 48 à 72 h entre deux séances lourdes du même tendon (synthèse du collagène élevée jusqu'à 72 h) ; adaptation sur 12 semaines et plus à intensité supérieure à 70 %.
- Poignets : échauffement de 3 à 5 min, parallettes ou poings fermés par défaut quand le poignet est sensible, budget poignet par semaine (boucle 1), travail du poignet en fin de séance (boucle 5).
- Ordre de séance : compétence (handstand) puis figures fraîches, puis force, puis tronc.
- Excentriques de figure : 2–3 séries de 2–3 répétitions de 3–5 s, 3 min de repos.
- Muscle-up : prérequis d'environ 5 tractions explosives et 5 dips ; pas d'élastique.
- Force regroupée et figures élite « un cran au-dessus » en dynamique (boucles 1 et 5).

Sources :
1. stevenlow.org, tables de Prilepin pour le poids du corps, l'isométrie et l'excentrique — https://stevenlow.org/prilepin-tables-for-bodyweight-strength-isometric-and-eccentric-exercises/
2. stevenlow.org, programmer les isométries avancées après un plateau — https://stevenlow.org/how-to-program-for-advanced-isometric-movements-after-a-plateau/
3. stevenlow.org, bases de l'entraînement de force au poids du corps — https://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/
4. stevenlow.org, tendinites — https://stevenlow.org/overcoming-tendonitis/
5. antranik.org, entraînement au poids du corps — https://antranik.org/bodyweight-training/
6. Bohm, Mersmann, Arampatzis 2015, adaptation du tendon à la charge (Sports Med Open) — https://link.springer.com/article/10.1186/s40798-015-0009-9
7. Routine du wiki r/bodyweightfitness (copie GitHub) — https://gist.github.com/sgup/f10f1d57e54b7876495f4bafb6d697eb
8. Miller et al. 2005, synthèse du collagène tendineux après l'exercice (J Physiol) — DOI 10.1113/jphysiol.2005.093690
9. Magnusson, Langberg, Kjaer 2010, pathogenèse de la tendinopathie (Nat Rev Rheumatol) — DOI 10.1038/nrrheum.2010.43
10. Oranchuk et al. 2019, entraînement isométrique (Scand J Med Sci Sports) — DOI 10.1111/sms.13375
11. gmb.io, douleur au poignet — https://gmb.io/wrist-pain/
12. gmb.io, apprendre le handstand — https://gmb.io/handstand/
13. legendarystrength.com, fréquence d'entraînement du handstand — https://legendarystrength.com/bad-handstand-habits-training-frequency-more/
14. gmb.io, muscle-up — https://gmb.io/muscle-up/
15. Bell et al. 2023, allègement : consensus Delphi (Sports Med Open) — https://link.springer.com/article/10.1186/s40798-023-00633-0

### 3.5 Tolérance et contexte (rapport E)

Conclusions retenues :
- Reprise après une longue coupure : la force se perd lentement et revient vite, mais le risque principal est une charge « trop, trop vite, trop tôt ». Le moteur fait la semaine 1 à la moitié des séries dures avec au moins 3 répétitions en réserve, un test d'entrée arrêté à 3 répétitions de l'échec, puis +10 à 15 % de séries par semaine pendant quatre semaines (17 → 19 → 22 → 25 → 29 sur street_04), +20 % au plus ensuite (boucles 2, 6 et 7). La règle « −50 % » est une convention de terrain, non vérifiée dans une source primaire.
- Signes d'alerte de rhabdomyolyse (douleur et faiblesse sévères, urines foncées) : arrêt et avis médical.
- 40 à 60 ans : 2 à 3 séances par semaine, 2 à 3 séries par grand groupe, 6 à 12 répétitions, repos d'au moins 2 min (ACSM, NSCA) ; réserve de 1 à 3 répétitions (choix prudent).
- Sommeil court et stress : performance du lendemain −7,6 % en moyenne ; récupération en 48 h chez les personnes peu stressées contre environ 96 h chez les très stressées. Le moteur garde l'intensité, réduit le volume et ajoute une répétition en réserve ; les réductions sont déjà dans les chiffres (« n'en retire pas davantage »).
- Travail physique lourd : compté comme charge de fond, même règle que le sommeil court.
- Coude : douleur jusqu'à 3/10 pendant l'effort, revenue au niveau de base le lendemain matin, sans hausse d'une semaine à l'autre ; avis médical en cas de signes nerveux ou de douleur au-delà de 7/10. Le moteur écrit une règle de douleur unique (0–2 continuer ; 3–4 finir sans progresser ; 5 variante plus facile et −30 à −50 % du volume de la zone ; 6 ou plus arrêt et avis) et renvoie tous les seuils de zone à cette règle (boucle 7).
- Coude à ménager : dips d'abord, poignet en fin de séance, avant-bras travaillés en cas d'antécédent coude ou poignet (boucle 5).
- Force + course : séances séparées d'au moins 3 h, de préférence des jours différents ; environ 80 % de la course en endurance facile ; intervalles à l'allure visée et allures recalées par un test chronométré (boucles 1, 4 et 5) ; mollets et rebonds en dose fixe pour la coureuse (boucles 5 et 6).
- Séances courtes : au moins 4 séries par groupe et par semaine, viser 10 et plus ; séries enchaînées pour gagner du temps.
- Spécialisation : le reste du corps à environ un tiers du volume habituel, intensité conservée.

Sources :
1. Mujika & Padilla 2000, désentraînement (Sports Med) — https://paulogentil.com/pdf/Detraining%20-%20Loss%20of%20Training-Induced%20Physiological%20and%20Performance%20Adaptations.%20Part%20II.pdf
2. Staron et al. 1991, désentraînement et reprise (J Appl Physiol) — https://paulogentil.com/pdf/Strength%20and%20skeletal%20muscle%20adaptations%20in%20HRT%20women%20after%20detraining%20and%20retraining.pdf
3. Ogasawara et al. 2013, entraînement continu ou périodique (résumé) — https://coachsci.sdsu.edu/csa/vol171/ogasawar.htm
4. CHAMP / USUHS 2025, rhabdomyolyse d'effort (recommandation clinique) — https://champ.usuhs.edu/sites/default/files/2025-09/WHEC_Clinical_Practice_Guidelines_ER.pdf
5. ACSM 2009, prise de position — https://sfu.ca/~ryand/kin343/ACSMresistance.pdf
6. Fragala et al. 2019, NSCA, musculation des adultes âgés — https://pubmed.ncbi.nlm.nih.gov/31343601/ ; résumé : https://www.ideafit.com/resistance-training-for-older-adults-new-nsca-position-stand
7. Bickel, Cross, Bamman 2011, dose d'entretien (MSSE) — https://pubmed.ncbi.nlm.nih.gov/21131862/
8. Craven et al. 2022, manque de sommeil et performance (Sports Med) — https://pmc.ncbi.nlm.nih.gov/articles/PMC9584849
9. Knowles et al. 2018, sommeil insuffisant et force (J Sci Med Sport) — https://paulogentil.com/pdf/Inadequate%20sleep%20and%20muscle%20strength%20-%20Implications%20for%20resistance%20training.pdf
10. Stults-Kolehmainen et al. 2014, stress chronique et récupération (JSCR) — https://pubmed.ncbi.nlm.nih.gov/24343323/ ; chiffres lus dans : https://bretcontreras.com/?p=17448
11. Holtermann et al. 2018, paradoxe de l'activité physique au travail (BJSM) — https://bjsm.bmj.com/content/52/3/149.abstract
12. Coombes, Bisset, Vicenzino 2015, épicondylalgie latérale (JOSPT) — https://wikiMSK.org/w/img_auth.php/3/30/Coombes2015_Management_of_Lateral_Elbow_Tendinopathy.pdf
13. Lucado et al. 2022, douleur latérale du coude, recommandation clinique (JOSPT) — https://www.orthopt.org/uploads/content_files/files/jospt.2022.0302.pdf
14. Wilson et al. 2012, entraînement concurrent (JSCR) — https://search.pedro.org.au/search-results/record-detail/34457
15. Schumann et al. 2022, compatibilité endurance-force (Sports Med) — https://researchonline.jcu.edu.au/71546/1/Schumann2021_Article_CompatibilityOfConcurrentAerob.pdf
16. Petré et al. 2021, force maximale et entraînement concurrent (Sports Med) — https://link.springer.com/article/10.1007/s40279-021-01426-9
17. Stöggl & Sperlich 2015, répartition des intensités (Front Physiol) — https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2015.00295/pdf
18. Knechtle et al. 2024, entraînement des coureurs récréatifs selon la distance (étude NURMI) — https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2023.1269374/full
19. Silbernagel et al. 2007, modèle de suivi de la douleur (AJSM) — https://search.pedro.org.au/search-results/record-detail/18389 ; seuils lus dans : https://physicaltherapyfirst.com/blog/continued-sports-activity-using-a-pain-monitoring-model-during-rehabilitation-in-patients-with-achilles-tendinopathy/
20. Iversen et al. 2021, programmes économes en temps (Sports Med) — https://link.springer.com/article/10.1007/s40279-021-01490-1
21. Schoenfeld, Ogborn, Krieger 2017, dose-réponse du volume (J Sports Sci) — doi:10.1080/02640414.2016.1210197
22. Zhang et al. 2025, séries enchaînées (Sports Med) — https://eprints.leedsbeckett.ac.uk/id/eprint/11908
23. Robinson et al. 2024, proximité de l'échec (Sports Med) — doi:10.1007/s40279-024-02069-2
24. Spiering et al. 2021, dose minimale d'entretien (JSCR) — https://pubmed.ncbi.nlm.nih.gov/33629972/ ; chiffres lus dans : https://www.fisiologiadelejercicio.com/que-dosis-minima-se-necesita-para-mantener-la-fuerza-y-la-resistencia-aerobica-a-traves-del-tiempo/

### 3.6 Sources de la relecture documentée de la boucle 0 (`sources_web.md`)

Liste relue par WebFetch aux boucles suivantes, une fois le quota de recherche épuisé (les doublons d'adresse sont fusionnés) :

1. ACSM 2009, Progression Models in Resistance Training for Healthy Adults — https://www.sportgeneeskunde.com/wp-content/uploads/ACSM-Position-Stand-Progression-Models-in-Resistance-Training-for-Healthy-Adults.pdf ; autres copies : https://sfu.ca/~ryand/kin343/ACSMresistance.pdf et https://www.ideafit.com/progression-models-in-resistance-training-for-healthy-adults
2. ACSM 2026, communiqué — https://www.newswise.com/articles/acsm-unveils-landmark-2026-resistance-training-guidelines-first-update-in-17-years ; synthèse : https://enfaf.com/acsm-2026-posicion-entrenamiento-fuerza/
3. Refalo et al. 2023, proximité de l'échec (synthèse) — https://scienceblog.com/for-bigger-muscles-push-close-to-failure-for-strength-maybe-not/
4. Mountain Tactical Institute, meilleure façon d'améliorer ses tractions (résultats) — https://mtntactical.com/all-articles/the-best-way-to-improve-pull-ups-part-iii-the-results-and-the-verdict/
5. Mountain Tactical Institute, mini-étude : pratique fréquente sous-maximale contre densité — https://mtntactical.com/knowledge/mini-study-grease-the-groove-beats-density-for-push-up-pull-up-improvement/
6. Breaking Muscle, traction du débutant : suspension bras fléchis et rows aux anneaux — https://breakingmuscle.com/the-beginner-pull-up-program-flexed-hang-and-ring-rows/
7. Stronger by Science, affûtage pour la force — https://www.strongerbyscience.com/?p=43142
8. Stronger by Science, rendements décroissants du volume — https://www.strongerbyscience.com/?p=56687
9. Université du Nouveau-Mexique, résumé des recommandations ACSM — https://www.unm.edu/~lkravitz/Article%20folder/ACSMGuidelinesUNM.pdf
10. ACSM, activité physique et perte de poids (synthèse IDEA Fit) — https://www.ideafit.com/acsm-on-weight-loss
11. Physical Activity Guidelines for Americans, 2e édition, les 10 points clés — https://odphp.health.gov/our-work/nutrition-physical-activity/physical-activity-guidelines/current-guidelines/top-10-things-know
12. Murphy & Koehler 2022, déficit énergétique et gains en musculation — https://sci-sport.com/en/impact-of-energy-deficiency-on-resistance-training-gains/
13. Ebben et al. 2011, analyse cinétique des variantes de pompes — https://breakingmuscle.com/kinetic-analysis-of-the-push-up-which-version-is-hardest/
14. Bickel et al. 2011, dose d'entretien — https://paulogentil.com/pdf/Exercise%20Dosing%20to%20Retain%20Resistance%20Training%20Adaptations%20in%20Young%20and%20Older%20Adults.pdf
15. jtsstrength.com, reprendre l'entraînement après une longue coupure — https://www.jtsstrength.com/?p=45954
16. Remmert, Pelland et al., volume par séance et rendements décroissants (préprint SportRxiv) — https://sportrxiv.org/index.php/server/preprint/view/537 ; version téléchargeable : https://sportrxiv.org/index.php/server/preprint/download/537/1148/1071
17. Grgic et al. 2018, fréquence et force (Sports Med Open) — https://link.springer.com/content/pdf/10.1186/s40798-018-0149-9.pdf ; autre adresse : https://link.springer.com/doi/10.1186/s40798-018-0149-9
18. Bell et al. 2023, allègement : consensus Delphi — https://shura.shu.ac.uk/32417/1/s40798-023-00633-0.pdf ; autres adresses : https://shura.shu.ac.uk/32417/ et https://doaj.org/article/599784d71dff41b197ff5cf66a3d11dd
19. Helms et al. 2018, RPE contre pourcentage du 1RM — https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2018.00247/pdf
20. Helms et al., échelle RPE fondée sur les répétitions en réserve — https://openrepository.aut.ac.nz/items/92cefeac-7c32-44f1-bfbc-f48f4a5dd8cf/full
21. Helms et al. 2020, méthodes de régulation et de suivi (J Hum Kinet) — https://johk.pl/wp-content/uploads/2023/03/10078-74-2020-v74-2020-03.pdf
22. Oranchuk et al. 2019, entraînement isométrique (revue systématique) — https://openrepository.aut.ac.nz/items/1a37e689-0027-4a12-9815-07ff2818b768/full ; autre adresse : https://openrepository.aut.ac.nz/handle/10292/12194
23. Bosquet et al. 2007, méta-analyse sur l'affûtage — https://coachsci.sdsu.edu/csa/vol131/bosquet.htm ; autre adresse : https://pubmed.ncbi.nlm.nih.gov/17762369/
24. Wiki r/bodyweightfitness, progression du row et du front lever — https://redlib.hackliberty.org/r/bodyweightfitness/wiki/exercises/row
25. Lettre Street Workout, conseils pour le front lever — https://streetworkout.beehiiv.com/p/daily-newsletter-1
26. Pritchard et al., affûtage des powerlifters élites néo-zélandais — https://researchonline.ljmu.ac.uk/id/eprint/2455/ ; version acceptée : https://researchonline.ljmu.ac.uk/id/eprint/2455/3/Pritchard%20et%20al%20author%20accepted%20version%5B1%5D.pdf
27. NSCA, prise de position sur la musculation des adultes âgés (communiqué) — https://nsca.com/media-room/press-releases/nsca-position-statement-on-resistance-training-for-older-adults
28. E3 Rehab, rééducation de l'épicondylalgie médiale — https://e3rehab.com/blog/golferselbow/
29. Modèle de suivi de la douleur, Pilot and Feasibility Studies 2021 — https://pmc.ncbi.nlm.nih.gov/articles/PMC7905015
30. HPRC, améliorer l'endurance musculaire — https://hprc-online.org/physical-fitness/training-performance/how-improve-muscular-endurance-military-fitness
31. Hackett et al. 2018, étude de 12 semaines à 10 séries par exercice (Sports) — https://pmc.ncbi.nlm.nih.gov/articles/PMC5969184
32. Easow et al. 2025, manque de sommeil et force (revue systématique) — https://pmc.ncbi.nlm.nih.gov/articles/PMC12263768
33. Muñoz et al. 2014, entraînement polarisé chez le coureur récréatif (IJSPP) — https://lida.sport-iat.de/ta/Record/4031233?lng=en
34. Schumann et al. 2022, compatibilité endurance-force — https://researchonline.jcu.edu.au/71546/1/Schumann2021_Article_CompatibilityOfConcurrentAerob.pdf
35. Méta-analyse 2024, musculation et économie de course des coureurs de demi-fond et de fond — https://pmc.ncbi.nlm.nih.gov/articles/PMC11052887
36. Nielsen et al. 2014, progression de la distance hebdomadaire et blessures (JOSPT) — https://vbn.aau.dk/da/publications/excessive-progression-in-weekly-running-distance-and-risk-of-runn
37. Travis et al. 2020, affûtage et pic en powerlifting — https://doaj.org/article/886093729f784abda2365f6ae95125f9
38. FinalRep, présentation et règles du streetlifting — https://final-rep.com/weighted/about
39. FinalRep, règlement du streetlifting — https://files.supersite.aruba.it/media/34071_61cc1b4890859f79cbbe5248b5cf032f517a0b08.pdf
40. Strength Shop, guide d'une première compétition de streetlifting — https://strengthshop.eu/blogs/news/blogs-guides-streetlifting-competition-dip-belt-first-meet-guide
41. Gabbett 2016, paradoxe entraînement-prévention des blessures (BJSM) — https://lida.sport-iat.de/ta/Record/4040728?lng=en
42. rpstrength.com, affûtage pour la force — https://rpstrength.com/blogs/articles/finishing-strong-tapering-for-strength-performance
43. Ralston et al. 2018, fréquence et gain de force — https://doaj.org/article/5a0ee38a0bf847ee9329f9fe72d50f88
44. Ralston et al. 2017, volume hebdomadaire et gain de force (méta-analyse) — https://research-portal.uws.ac.uk/en/publications/the-effect-of-weekly-set-volume-on-strength-gain-a-meta-analysis/
45. powerliftingtechnique.com, verrouillage au développé couché (partiels surchargés) — https://powerliftingtechnique.com/bench-press-lockout/
46. Wolf et al. 2017, douleur au poignet chez les gymnastes — https://lida.sport-iat.de/ta/Record/4046312?lng=en
47. EricFlag, progression vers la planche complète — https://ericflag.com/en/blogs/info/full-planche-calisthenics

## 4. Journal des boucles

Dans chaque tableau, une note en gras a changé depuis la boucle précédente. « Corrections nécessaires » compte les corrections classées nécessaires par les quatre écoles ; « hautes » compte les corrections de priorité haute de la relecture documentée.

### Boucle 0 — passe complète initiale (3 octobre 2026)

Corrections faites : aucune (état de départ du chemin coach : squelette en passe 1, prescription en passe 2, saison calculée à rebours depuis l'échéance, notes de coach en codes de raison).

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 7 | 7 | 8 | 7 | 6 |
| street_02 | 7 | 7 | 7 | 7 | 6 |
| street_03 | 6,5 | 7 | 7 | 8 | 5 |
| street_04 | 5 | 7 | 6,5 | 4,5 | 6 |
| street_05 | 6 | 5,5 | 5 | 5 | 5 |
| street_06 | 7 | 7 | 6,5 | 7 | 6 |
| street_07 | 7,5 | 7 | 9 | 9 | 7 |
| street_08 | 7 | 7 | 8 | 7 | 5 |
| street_09 | 8 | 8 | 9 | 8 | 7 |
| street_10 | 4 | 6,5 | 7,5 | 5,5 | 4 |
| street_11 | 7 | 8 | 7 | 7 | 6 |
| street_12 | 5 | 8 | 9 | 7 | 6 |
| street_13 | 6 | 6 | 7 | 6 | 5 |
| street_14 | 7 | 5,5 | 6 | 6,5 | 6 |
| street_15 | 6,5 | 6,5 | 7 | 6,5 | 6 |
| street_16 | 8 | 8 | 8 | 8 | 7 |
| street_17 | 7 | 7 | 6,5 | 6 | 5 |

Panel : moyenne 6,89, minimum 4, 4 notes sur 68 à 9 ou plus, 151 corrections nécessaires. Relecture documentée : moyenne 5,76, minimum 4, 44 corrections hautes.

Points perdus principaux :
- Débutants (01, 02, 03) : aucun test de traction stricte en semaine 12 alors que c'est l'objectif ; négatives à 1 × 2–3, trop faibles ; pompe sur les genoux pendant 12 semaines sans chemin vers la pompe classique ; épreuve de « négative la plus lente possible » contestée.
- Reprise (04) : montée de volume trop rapide (EMOM de 4 à 8 min), aucun test d'entrée, charges en % de records vieux de 40 semaines, traction et dips à chaque séance.
- Figures (05, 10) : test de la figure complète au lieu de l'étape travaillée, deux règles de progression des tenues contradictoires (+1 s ou +5 s), tenues figées, poignets sollicités six jours sur sept (10).
- Volume de poussée excessif en sets & reps (06, 08, 14, 15) : EMOM de dips jusqu'à 12 × 8 ou 12 × 12, pompes jusqu'à 10 × 16.
- Streetlifting (07, 09, 16) : plan de tentatives qui n'atteint pas l'objectif, aucun test ni compétition simulée (07), muscle-up lesté en séries de 5 trop lourdes.
- Profils de contexte : pistol squat prescrit au-delà du record (14, 15), règle de sommeil court inadaptée (15), traction « lestée » au poids du corps (11), traction lestée absente (12), ligne de course absurde en semaine 12 (« Footing 1 × 5 à 15 s, maintien maximal », 17) et fractionné sans allure.

### Boucle 1

Corrections faites : trajectoire prévue vers l'objectif, densité plafonnée, poussée en entretien, tirage horizontal gardé, tests visés, tentatives vers l'objectif ; course (allures, test chronométré) ; débutant (négatives, tenue menton, marche) ; figures (étapes prévues, budget poignet, force regroupée) ; reprise ; coude ; textes des règles.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 7 | **8** | **7** | **8** | 6 |
| street_02 | **9** | **7,5** | **9** | **8** | **7** |
| street_03 | **7** | 7 | 7 | **7** | **6** |
| street_04 | **7** | **8** | **8** | **5** | **7** |
| street_05 | **8** | **8** | **8** | **8** | **6** |
| street_06 | **9** | **9** | **9** | **8** | **7** |
| street_07 | **8** | 7 | **8** | **8** | 7 |
| street_08 | **8** | 7 | **7** | **8** | **6** |
| street_09 | 8 | 8 | **8** | 8 | 7 |
| street_10 | **5** | **5** | **5** | **5** | **5** |
| street_11 | **8** | 8 | **9** | **9** | **7** |
| street_12 | **9** | **7** | 9 | **9** | 6 |
| street_13 | **8** | **8** | **9** | **9** | **6** |
| street_14 | **8** | **7** | **8** | **8** | **7** |
| street_15 | **9** | **8** | **9** | **8** | **7** |
| street_16 | **7,5** | **7** | 8 | 8 | 7 |
| street_17 | **8** | 7 | **8** | **8** | **6** |

Panel : moyenne 7,76, minimum 5, 14 notes à 9 ou plus, 80 corrections nécessaires. Relecture documentée : moyenne 6,47, minimum 5, 36 corrections hautes.

Points perdus principaux :
- Débutants : toujours pas de test de traction stricte en semaine 12 (01, 03) ; consigne du test de semaine 6 ambiguë ; pompe sur les genoux à remplacer par une pompe inclinée (02, 03).
- Reprise (04) : saut de 11 à 22 séries dures entre S5 et S6 ; aucun travail de figures alors qu'elles font 30 % du profil.
- Figures (05, 10) : étape suivante introduite au calendrier sans critère atteint ; critère de passage jamais travaillé.
- street_10 tombe à 5 dans les quatre écoles : planche complète annoncée sans chemin réaliste, pic de charge des poignets de S8 à S9, 68 séries dures identiques dans les quatre blocs.
- street_08 : séries de tête au maximum connu (« 1 × 28 à 1 RIR » sur un maximum de 28).
- Relecture documentée : séances sous-utilisées (03 : 23 à 42 min sur 60), spécialisation trop timide (16), tentatives au-delà du 1RM (07, 12, 16).

Effet mesuré : panel de 6,89 à 7,76 de moyenne, minimum de 4 à 5 ; relecture de 5,76 à 6,47. Le nombre de corrections nécessaires baisse de 151 à 80.

### Boucle 2 (4 octobre 2026)

Corrections faites : repère calé sur le dernier test (plus de progrès supposé) ; accord répétitions / % / réserve (R2-P2) ; muscle-up lesté en séries de 3 et 2e exposition ; étape suivante des figures sous condition (plus d'avance au calendrier) ; 3e exposition de la seconde figure ; pas deux jours de tirage consécutifs (jusqu'au niveau intermédiaire) ; reprise longue (cycle entier à 2 RIR, montée lente, blocs de 6 semaines) ; tests des variantes et de la première traction à l'échéance ; séance facile à J−2 ; amorçage à J−2 (force) ; dernier lourd à J−7 / J−10 ; tentatives (3e = 2e + 2,5 à 5 kg) ; entretien du squat hors objectif ; compléments limités ; textes des règles.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | **8** | 8 | **9** | **9** | **7** |
| street_02 | **8** | **8** | 9 | **9** | 7 |
| street_03 | 7 | **8** | **8** | **8** | 6 |
| street_04 | **8** | 8 | 8 | **7** | 7 |
| street_05 | 8 | 8 | 8 | 8 | 6 |
| street_06 | 9 | 9 | 9 | **9** | 7 |
| street_07 | **9** | **9** | **9** | **9** | **8** |
| street_08 | 8 | **8** | **8** | 8 | **7** |
| street_09 | **9** | 8 | **9** | **9** | **8** |
| street_10 | **8** | **7** | **8** | **9** | **7** |
| street_11 | 8 | 8 | **8** | **8** | **6** |
| street_12 | **8** | 7 | **8** | 9 | **7** |
| street_13 | 8 | **9** | 9 | 9 | **7** |
| street_14 | **9** | **8** | 8 | 8 | 7 |
| street_15 | 9 | **9** | 9 | **9** | **8** |
| street_16 | **9** | **9** | **9** | **9** | 7 |
| street_17 | 8 | **9** | 8 | 8 | 6 |

Panel : moyenne 8,38, minimum 7, 30 notes à 9 ou plus, 42 corrections nécessaires. Relecture documentée : moyenne 6,94, minimum 6, 30 corrections hautes. Banc : 0 violation street ; attentes tenues sauf street_12 (conflit documenté).

Points perdus principaux :
- Repères qui montent sans test (04, 08, 17) : demande unanime d'un test de dips et de pompes à mi-parcours.
- Débutantes (03) : pompe classique figée à 2 × 2 en bloc 2, repère du test final (6 à 8) sous l'objectif de 10.
- Figures (05, 10) : critère de passage non atteignable avec les doses écrites ; règle des tenues à unifier.
- street_11 : traction lestée calculée sur un 1RM estimé, simple à 99 % en S15.
- street_12 : règle de douleur ambiguë (quels mouvements, quel seuil).
- street_14 : handstand dos au mur et repli sur parallettes impossibles au parc (déjà demandé par deux écoles).
- Relecture documentée : séances courtes (04, 13), absence de travail d'endurance à repos court (14), tirage presque quotidien (09).

Effet mesuré : panel +0,62, minimum de 5 à 7 ; relecture +0,47.

### Boucle 3

Corrections faites : repère relevé seulement après un test de l'exercice (tests de dips et de pompes ajoutés, reprise par paliers aux tests) ; 1RM de travail affiché sur un seul repère ; descentes freinées au contrôle (plafond propre R5-P8) dès la semaine 2 ; tirage assisté en 3 séries ; étape actuelle des figures prioritaire sur l'étape facile ; critère de passage mesurable ; tests en tête de séance et sur le geste visé ; semaine du test à 2 séries ; pas de simple lourd hors épreuve de force ; premier bloc toujours en construction ; muscle-up après la traction quand l'objectif est la traction ; textes (douleur, calibrage, parallettes).

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 8 | **9** | **8** | 9 | 7 |
| street_02 | **9** | **9** | 9 | **8** | 7 |
| street_03 | 7 | 8 | **7** | 8 | 6 |
| street_04 | **9** | **9** | **9** | **9** | **6** |
| street_05 | 8 | **9** | **9** | **9** | **7** |
| street_06 | 9 | 9 | 9 | 9 | **8** |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | 8 | 8 | **9** | **9** | 7 |
| street_09 | 9 | **9** | 9 | **8** | 8 |
| street_10 | **9** | **9** | **9** | 9 | 7 |
| street_11 | 8 | **9** | **9** | 8 | **7** |
| street_12 | 8 | **8** | 8 | **8** | **8** |
| street_13 | **9** | 9 | 9 | 9 | **8** |
| street_14 | 9 | 8 | **9** | **9** | 7 |
| street_15 | 9 | 9 | 9 | 9 | 8 |
| street_16 | **9,5** | 9 | 9 | **9,5** | **8** |
| street_17 | 8 | **8** | 8 | **9** | **7** |

Panel : moyenne 8,68, minimum 7, 47 notes à 9 ou plus, 23 corrections nécessaires. Relecture documentée : moyenne 7,29, minimum 6, 16 corrections hautes.

Points perdus principaux :
- Débutants (01, 03) : « 3 à 5 séries de 1 traction stricte » à remplacer par 2–3 essais propres en début de séance ; l'école hypertrophie demande de plafonner le dos à 10–12 séries directes par semaine et 6 par séance.
- street_03 : chemin vers 10 pompes encore insuffisant (quatre écoles et la relecture).
- street_11 : traction lestée à recaler sur le 1RM déclaré (91 kg de charge totale) ou sur un test de 3 à 5 RM.
- street_12 : contradiction entre le barème général de douleur et la règle de la zone (quatre écoles).
- street_17 : traction sans progression dans le bloc 2.
- Relecture documentée : front lever tenu à 58–71 % du maximum et sans travail dynamique (05) ; volume de dips d'environ 540 répétitions par semaine et tirage lourd deux jours de suite (08) ; jambes et pliométrie absentes pour la coureuse (17).

Effet mesuré : panel +0,29, 47 notes à 9 ou plus (contre 30) ; relecture +0,35.

### Boucle 4

Corrections faites : charge lestée sous le poids du corps calibrée à la réserve (1RM « réconcilié » retiré) ; séance facile à J−2 d'un test ; répétition générale à une série par atelier ; affûtage linéaire avant une échéance datée ; petits records (moins de 6) en double progression ; montée lente des reprises longues ; compléments plafonnés ; rampe du total de séries dures ; étape suivante des figures en tentatives sous condition ; intervalles de course à l'allure visée. Panel renoté pour 01, 02, 03, 05, 08, 09, 11, 12, 14 et 17.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 8 | 9 | 8 | 9 | **8** |
| street_02 | 9 | 9 | 9 | **9** | 7 |
| street_03 | **8** | **9** | **8** | 8 | **7** |
| street_04 | 9 | 9 | 9 | 9 | **7** |
| street_05 | **9** | 9 | 9 | 9 | 7 |
| street_06 | 9 | 9 | 9 | 9 | 8 |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | **9** | **9** | 9 | 9 | 7 |
| street_09 | 9 | **8** | 9 | **9** | 8 |
| street_10 | 9 | 9 | 9 | 9 | 7 |
| street_11 | 8 | **8** | **8** | **9** | 7 |
| street_12 | **9** | 8 | **9** | **9** | **7** |
| street_13 | 9 | 9 | 9 | 9 | **7** |
| street_14 | 9 | 8 | 9 | 9 | 7 |
| street_15 | 9 | 9 | 9 | 9 | 8 |
| street_16 | 9,5 | 9 | 9 | 9,5 | **7** |
| street_17 | **9** | 8 | **9** | 9 | 7 |

Panel : moyenne 8,84, minimum 8, 56 notes à 9 ou plus, 12 corrections nécessaires. Relecture documentée : moyenne 7,29, minimum 7, 25 corrections hautes. Banc : 0 violation street, attentes tenues sauf street_12.

Points perdus principaux :
- Débutants (01, 03) : tentative de traction stricte à placer en premier, fraîche ; tirage à plafonner à 6 séries par séance (hypertrophie).
- street_11 : trois écoles demandent un lest réel dès S1 (+5 à +7,5 kg) au lieu de « 4 × 6 à 4 RIR, à calibrer ».
- street_09 : traction lestée du vendredi trop proche du muscle-up lourd (48 h).
- street_14 : bloc 2 pas assez spécifique aux 25 tractions (calisthénie).
- Relecture documentée : jambes lourdes absentes malgré la salle (11) ; rééducation du coude limitée au wrist curl (12) ; figures à 30 % non servies (04) ; tirage vertical faible pour le front lever (05).

Effet mesuré : panel +0,16 et minimum à 8 pour la première fois ; relecture inchangée (7,29). Le nombre de corrections hautes de la relecture remonte de 16 à 25.

### Boucle 5

Corrections faites : essai strict avant la descente chronométrée (débutant) ; tirage du débutant plafonné (2 séries assistées les jours de descentes, descentes allongées au bloc 2) ; pompes en descente freinée dès la semaine 1 (objectif pompes) ; affûtage à −45 % et note calée sur les séries dures réelles ; étiquette de réserve « sur la dernière série » (export) ; lest réglé sur le lest du 1RM quand il est proche du poids du corps ; coude à ménager (dips d'abord, poignet en fin de séance) ; troisième exposition légère de traction (jour écarté) ; mollets et rebonds (hybride course) ; avant-bras (antécédent coude ou poignet) ; partiels à 95–105 % monotones ; veille de test sans tirage ; repos-pause (objectif de 15 répétitions et plus) ; notes (objectif ambitieux, stratégie de série maximale, montée avant maintien maximal, suivi de la perte de poids, figures élite un cran au-dessus en dynamique). Panel renoté : 01, 03, 04, 06, 10, 12, 14, 17 (quatre écoles), 09 et 11 (force, calisthénie, hypertrophie) ; relecture documentée : 17 profils.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 8 | 9 | **9** | **8** | **7** |
| street_02 | 9 | 9 | 9 | 9 | **8** |
| street_03 | 8 | 9 | **9** | 8 | **8** |
| street_04 | **8** | **8** | **8** | **7,5** | 7 |
| street_05 | 9 | 9 | 9 | 9 | 7 |
| street_06 | **8** | **8** | **8** | 9 | 8 |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | 9 | 9 | 9 | 9 | 7 |
| street_09 | **8** | **9** | 9 | 9 | 8 |
| street_10 | 9 | 9 | 9 | 9 | 7 |
| street_11 | **9** | 8 | **9** | 9 | 7 |
| street_12 | **8** | **9** | 9 | 9 | **8** |
| street_13 | 9 | 9 | 9 | 9 | 7 |
| street_14 | 9 | 8 | 9 | 9 | 7 |
| street_15 | 9 | 9 | 9 | 9 | 8 |
| street_16 | 9,5 | 9 | 9 | 9,5 | **8** |
| street_17 | 9 | **9** | 9 | 9 | **6** |

Panel : moyenne 8,79, minimum 7,5, 53 notes à 9 ou plus, 15 corrections nécessaires. Relecture documentée : moyenne 7,41, minimum 6, 18 corrections hautes. Banc : 0 violation street, attentes tenues sauf street_12.

Points perdus principaux :
- Affûtage des débutants (01, 03) : l'école force demande de revenir à 3–5 jours à −30 % (R3-P12).
- Reprise (04) : la règle « moitié du volume en semaine 1 » est écrite mais pas appliquée dans les chiffres (34 séries dures en S1) ; quatre écoles et la relecture le relèvent.
- street_06 : repos-pause au-delà de la dose du référentiel ; consécution vendredi-samedi sur les mêmes zones.
- street_12 : dernier lourd à placer à J−5 / J−6.
- street_09 : dips à la barre et traction haute dosés en % du 1RM de muscle-up.
- Relecture documentée : charges lestées de street_11 jugées à 2–3 RM ; planche trop légère (10) ; endurance spécifique insuffisante (14) ; bas du corps symbolique (17).

Effet mesuré : panel −0,05 (régressions sur 04, 06, 09 et 12, gains sur 01, 03, 11 et 17) ; relecture +0,12. C'est la première boucle où le panel recule.

### Boucle 6

Corrections faites : reprise longue — semaine 1 à la moitié des séries dures puis hausses de 20 % au plus (plein volume en semaine 5), 3 RIR tout le premier bloc ; débutant — deux séries par exercice les deux premières semaines, descentes freinées en tête de séance, tenue menton à partir de la semaine 3, affûtage court (−30 %), essai strict à chaque test, note « plusieurs tractions depuis zéro » ; repos-pause réécrit (3 relances au plus, un seul mouvement par semaine, à partir de la 2e semaine du bloc) ; lest proche du poids du corps : échelle abaissée ; rappel lourd à J−4 / J−6 avant un test daté de 1RM ; rebonds en dose fixe ; repère affiché sur le bas de la plage. Panel renoté : 01, 03, 04, 06 (quatre écoles) ; 09, 11, 12, 14 (force, calisthénie) ; relecture documentée : 17 profils.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | **9** | 9 | **8** | **9** | **8** |
| street_02 | 9 | 9 | 9 | 9 | 8 |
| street_03 | **9** | 9 | **8** | **9** | **7** |
| street_04 | 8 | 8 | 8 | **8** | 7 |
| street_05 | 9 | 9 | 9 | 9 | **6** |
| street_06 | **9** | 8 | **9** | 9 | **7** |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | 9 | 9 | 9 | 9 | 7 |
| street_09 | **9** | 9 | 9 | 9 | **7** |
| street_10 | 9 | 9 | 9 | 9 | **6** |
| street_11 | 9 | **9** | 9 | 9 | **6** |
| street_12 | 8 | 9 | 9 | 9 | **7** |
| street_13 | 9 | 9 | 9 | 9 | 7 |
| street_14 | 9 | **9** | 9 | 9 | 7 |
| street_15 | 9 | 9 | 9 | 9 | **7** |
| street_16 | 9,5 | 9 | 9 | 9,5 | **7** |
| street_17 | 9 | 9 | 9 | 9 | **7** |

Panel : moyenne 8,90, minimum 8, 60 notes à 9 ou plus, 8 corrections nécessaires. Relecture documentée : moyenne 7,0, minimum 6, 25 corrections hautes. Banc : 0 violation street, attentes tenues sauf street_12.

Points perdus principaux :
- Débutants (01, 03) : l'école hypertrophie demande encore de ramener le tirage vertical direct à 8–10 séries par semaine en S7–S10.
- Reprise (04) : série-test d'entrée à écrire dans la table de la semaine 1 ; hausse à plafonner à +10–15 % par semaine (santé) ; pas de test de pompes en S6.
- street_06 : tirage lourd deux jours de suite.
- street_12 : seuil de douleur encore à unifier pour la troisième barre.
- Relecture documentée : séances quasi vides (04) ; figures et streetlifting non servis (04) ; muscle-up lesté incohérent et règle de barre de l'objectif inatteignable (09) ; accessoires de poussée absents (12) ; allures de course jamais recalées (17).
- **Dispersion** : street_05, street_10 et street_11 passent de 7 à 6 à la relecture documentée avec un export inchangé.

Effet mesuré : panel +0,11 (60 notes à 9) ; relecture −0,41, dont −0,18 dû aux trois profils renotés sans changement.

### Boucle 7 — passe finale complète

Corrections faites : reprise — montée de +10 à 15 % (17 → 19 → 22 → 25 → 29), série d'entrée écrite sur la ligne, repère d'un exercice non testé gelé ; débutant — descentes en 3 séries un seul jour au bloc 2 ; exposition légère de traction jamais le lendemain d'un jour de tirage ; seuils de douleur renvoyés à la règle unique ; textes (approche du test, objectif ambitieux depuis zéro). Passe complète : 17 profils × 4 écoles et relecture documentée des 17 profils.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 9 | 9 | **9** | 9 | 8 |
| street_02 | 9 | 9 | 9 | **8** | 8 |
| street_03 | 9 | 9 | **9** | 9 | 7 |
| street_04 | **9** | **9** | **9** | **9** | 7 |
| street_05 | 9 | 9 | 9 | 9 | **7** |
| street_06 | 9 | **9** | 9 | 9 | 7 |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | 9 | **8** | 9 | 9 | 7 |
| street_09 | 9 | 9 | 9 | 9 | **8** |
| street_10 | 9 | 9 | 9 | 9 | **7** |
| street_11 | 9 | 9 | **8** | 9 | **7** |
| street_12 | 8 | 9 | 9 | 9 | 7 |
| street_13 | 9 | 9 | 9 | 9 | **8** |
| street_14 | 9 | **8** | 9 | 9 | 7 |
| street_15 | 9 | 9 | 9 | 9 | **8** |
| street_16 | **9** | 9 | 9 | **9** | **8** |
| street_17 | **8** | 9 | **8** | 9 | 7 |

Panel : moyenne 8,90, minimum 8, 61 notes à 9 ou plus, 7 corrections nécessaires. Relecture documentée : moyenne 7,41, minimum 7, 18 corrections hautes. Banc : 0 violation street, attentes tenues sauf street_12.

Points perdus principaux (corrections nécessaires du panel) :
- street_02 (santé) : marche hors séance trop forte en semaine 1 ; commencer par 2 marches de 15–20 min.
- street_08 (calisthénie) : série de tête de tractions du lundi placée après 26 muscle-ups.
- street_11 (hypertrophie) : traction lestée à recaler par une série de calibrage à la première séance de chaque bloc.
- street_12 (force) : progression de charge autorisée seulement si la gêne reste à 2/10 au plus.
- street_14 (calisthénie) : repos-pause ambigu (semaines concernées).
- street_17 (force, hypertrophie) : tractions du lundi de la semaine 6 contraires à la règle des 48 h avant le test.
- Relecture documentée : voir les § 6 et 7 (18 corrections hautes).

Effet mesuré : panel stable (8,90, une note de plus à 9) ; relecture +0,41, retour au niveau de la boucle 5. La passe complète a fait redescendre de 9 à 8 six couples notés 9 à la boucle 6 (street_02 santé, street_08 et street_14 calisthénie, street_11 hypertrophie, street_17 force et hypertrophie) ; cinq d'entre eux (tous sauf street_14) reprenaient une note ancienne au titre de l'économie de notation, qui masquait donc une partie des défauts restants. Ce sont ces six couples qui ont été renotés après correction.

### Renotation finale (après la boucle 7)

Corrections faites : marche progressive du débutant en surpoids (deux marches de 15–20 min en semaine 1, puis vers 30 min, 150 min vers la semaine 8) ; traction lestée proche du poids du corps « à la réserve » avec départ conseillé et série de calibrage par paliers de 1,25 à 2,5 kg ; seuil de douleur du coude à 2/10 pour toute progression (règle de zone, puis note du wrist curl alignée) ; repos-pause limité aux semaines où la note figure sur la ligne ; traction retirée la veille du test de mi-parcours (street_14, street_17).

Six couples renotés : street_02 santé 8 → 9 ; street_11 hypertrophie 8 → 9 ; street_12 force 8 → 7 (première renotation : la note du wrist curl gardait l'ancien seuil, ce qui créait deux règles contradictoires sur la zone blessée et une correction nécessaire de plus sur le recalage du bloc 2) puis 9 après alignement de la note ; street_14 calisthénie 8 → 8 (reste le handstand dos au mur, voir § 6) ; street_17 force 8 → 9 ; street_17 hypertrophie 8 → 9.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Relecture documentée |
| --- | --- | --- | --- | --- | --- |
| street_01 | 9 | 9 | 9 | 9 | 8 |
| street_02 | 9 | 9 | 9 | **9** | 8 |
| street_03 | 9 | 9 | 9 | 9 | 7 |
| street_04 | 9 | 9 | 9 | 9 | 7 |
| street_05 | 9 | 9 | 9 | 9 | 7 |
| street_06 | 9 | 9 | 9 | 9 | 7 |
| street_07 | 9 | 9 | 9 | 9 | 8 |
| street_08 | 9 | 8 | 9 | 9 | 7 |
| street_09 | 9 | 9 | 9 | 9 | 8 |
| street_10 | 9 | 9 | 9 | 9 | 7 |
| street_11 | 9 | 9 | **9** | 9 | 7 |
| street_12 | **9** | 9 | 9 | 9 | 7 |
| street_13 | 9 | 9 | 9 | 9 | 8 |
| street_14 | 9 | 8 | 9 | 9 | 7 |
| street_15 | 9 | 9 | 9 | 9 | 8 |
| street_16 | 9 | 9 | 9 | 9 | 8 |
| street_17 | **9** | 9 | **9** | 9 | 7 |

Panel final : moyenne 8,97, minimum 8, 66 notes sur 68 à 9 ou plus, 2 corrections nécessaires. Relecture documentée : notes de la boucle 7.

## 5. Sources de la relecture documentée finale

Sources citées par les cinq relecteurs de la boucle 7, sans doublon d'adresse (46 adresses). Le nombre entre crochets indique combien de fiches de profil (une par profil) la mettent dans leur liste de sources.

1. ACSM 2009, Progression Models in Resistance Training (IDEA Fit) [6] — https://www.ideafit.com/progression-models-in-resistance-training-for-healthy-adults
2. ACSM 2009, Progression Models in Resistance Training (texte complet) [6] — https://sfu.ca/~ryand/kin343/ACSMresistance.pdf
3. ACSM 2026, prise de position sur la musculation (synthèse) [3] — https://enfaf.com/acsm-2026-posicion-entrenamiento-fuerza/
4. ACSM 2026, nouvelles recommandations (communiqué) [2] — https://www.newswise.com/articles/acsm-unveils-landmark-2026-resistance-training-guidelines-first-update-in-17-years
5. Université du Nouveau-Mexique, résumé des recommandations ACSM [4] — https://www.unm.edu/~lkravitz/Article%20folder/ACSMGuidelinesUNM.pdf
6. NSCA, prise de position sur la musculation des adultes âgés [1] — https://nsca.com/media-room/press-releases/nsca-position-statement-on-resistance-training-for-older-adults
7. Physical Activity Guidelines for Americans, 2e édition [1] — https://odphp.health.gov/our-work/nutrition-physical-activity/physical-activity-guidelines/current-guidelines/top-10-things-know
8. ACSM, activité physique et perte de poids (IDEA Fit) [1] — https://www.ideafit.com/acsm-on-weight-loss
9. Murphy & Koehler 2022, déficit énergétique et gains en musculation [1] — https://sci-sport.com/en/impact-of-energy-deficiency-on-resistance-training-gains/
10. HPRC, améliorer l'endurance musculaire [3] — https://hprc-online.org/physical-fitness/training-performance/how-improve-muscular-endurance-military-fitness
11. Mountain Tactical Institute, meilleure façon d'améliorer ses tractions (résultats) [5] — https://mtntactical.com/all-articles/the-best-way-to-improve-pull-ups-part-iii-the-results-and-the-verdict/
12. Mountain Tactical Institute, mini-étude : pratique fréquente sous-maximale contre densité [2] — https://mtntactical.com/knowledge/mini-study-grease-the-groove-beats-density-for-push-up-pull-up-improvement/
13. Breaking Muscle, traction du débutant : suspension bras fléchis et rows aux anneaux [5] — https://breakingmuscle.com/the-beginner-pull-up-program-flexed-hang-and-ring-rows/
14. Ebben et al. 2011, analyse cinétique des variantes de pompes [2] — https://breakingmuscle.com/kinetic-analysis-of-the-push-up-which-version-is-hardest/
15. Refalo et al., proximité de l'échec, force et hypertrophie (synthèse) [2] — https://scienceblog.com/for-bigger-muscles-push-close-to-failure-for-strength-maybe-not/
16. Helms et al., échelle RPE fondée sur les répétitions en réserve [1] — https://openrepository.aut.ac.nz/items/92cefeac-7c32-44f1-bfbc-f48f4a5dd8cf/full
17. Helms et al. 2018, RPE contre pourcentage du 1RM [6] — https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2018.00247/pdf
18. Helms et al. 2020, méthodes de régulation et de suivi (J Hum Kinet) [4] — https://johk.pl/wp-content/uploads/2023/03/10078-74-2020-v74-2020-03.pdf
19. Oranchuk et al. 2019, entraînement isométrique et adaptations à long terme [6] — https://openrepository.aut.ac.nz/items/1a37e689-0027-4a12-9815-07ff2818b768/full
20. Bosquet et al. 2007, méta-analyse sur l'affûtage (résumé) [4] — https://coachsci.sdsu.edu/csa/vol131/bosquet.htm
21. Bosquet et al. 2007, méta-analyse sur l'affûtage (PubMed) [11] — https://pubmed.ncbi.nlm.nih.gov/17762369/
22. Pritchard et al., affûtage des powerlifters élites néo-zélandais [4] — https://researchonline.ljmu.ac.uk/id/eprint/2455/
23. Stronger by Science, affûtage pour la force [1] — https://www.strongerbyscience.com/?p=43142
24. Stronger by Science, rendements décroissants du volume [3] — https://www.strongerbyscience.com/?p=56687
25. Remmert et al., volume par séance et rendements décroissants (préprint SportRxiv) [2] — https://sportrxiv.org/index.php/server/preprint/view/537
26. Bell et al. 2023, allègement : consensus Delphi [12] — https://shura.shu.ac.uk/32417/1/s40798-023-00633-0.pdf
27. Grgic et al. 2018, fréquence et force (PDF) [3] — https://link.springer.com/content/pdf/10.1186/s40798-018-0149-9.pdf
28. Grgic et al. 2018, fréquence et force (DOI) [9] — https://link.springer.com/doi/10.1186/s40798-018-0149-9
29. Bickel et al. 2011, dose d'entretien des adaptations [3] — https://paulogentil.com/pdf/Exercise%20Dosing%20to%20Retain%20Resistance%20Training%20Adaptations%20in%20Young%20and%20Older%20Adults.pdf
30. jtsstrength.com, reprendre l'entraînement après une longue coupure [1] — https://www.jtsstrength.com/?p=45954
31. Gabbett 2016, paradoxe entraînement-prévention des blessures [2] — https://lida.sport-iat.de/ta/Record/4040728?lng=en
32. Easow et al. 2025, manque de sommeil et force [2] — https://pmc.ncbi.nlm.nih.gov/articles/PMC12263768
33. E3 Rehab, rééducation de l'épicondylalgie médiale [2] — https://e3rehab.com/blog/golferselbow/
34. Modèle de suivi de la douleur, Pilot and Feasibility Studies 2021 [3] — https://pmc.ncbi.nlm.nih.gov/articles/PMC7905015
35. Wolf et al. 2017, douleur au poignet chez les gymnastes [2] — https://lida.sport-iat.de/ta/Record/4046312?lng=en
36. Wiki r/bodyweightfitness, progression du row et du front lever [2] — https://redlib.hackliberty.org/r/bodyweightfitness/wiki/exercises/row
37. Lettre Street Workout, conseils pour le front lever [1] — https://streetworkout.beehiiv.com/p/daily-newsletter-1
38. EricFlag, progression vers la planche complète [1] — https://ericflag.com/en/blogs/info/full-planche-calisthenics
39. FinalRep, présentation et règles du streetlifting [1] — https://final-rep.com/weighted/about
40. FinalRep, règlement du streetlifting [1] — https://files.supersite.aruba.it/media/34071_61cc1b4890859f79cbbe5248b5cf032f517a0b08.pdf
41. Strength Shop, guide d'une première compétition de streetlifting [1] — https://strengthshop.eu/blogs/news/blogs-guides-streetlifting-competition-dip-belt-first-meet-guide
42. powerliftingtechnique.com, verrouillage au développé couché (partiels surchargés) [1] — https://powerliftingtechnique.com/bench-press-lockout/
43. Muñoz et al. 2014, entraînement polarisé chez le coureur récréatif [1] — https://lida.sport-iat.de/ta/Record/4031233?lng=en
44. Méta-analyse 2024, musculation et économie de course [1] — https://pmc.ncbi.nlm.nih.gov/articles/PMC11052887
45. Schumann et al. 2022, compatibilité endurance-force [1] — https://researchonline.jcu.edu.au/71546/1/Schumann2021_Article_CompatibilityOfConcurrentAerob.pdf
46. Nielsen et al. 2014, progression de la distance hebdomadaire et blessures [1] — https://vbn.aau.dk/da/publications/excessive-progression-in-weekly-running-distance-and-risk-of-runn

Non reprises ici : une page de présentation d'un programme commercial de calisthénie, citée par trois fiches (street_04, street_05, street_14) dans la relecture finale et présente dans `sources_web.md` ; et, dans le rapport B, un article de presse consacré à un programme nommé de tractions. Leur adresse même nomme le programme.

## 6. Demandes non suivies et pourquoi

Demandes tirées des notes de la dernière boucle (boucle 7 et renotation).

**street_08, calisthénie (seule correction nécessaire restante, note 8).** Le correcteur demande de faire la série de tête de tractions du lundi avant le muscle-up, ou de la recaler sur un maximum « en état de fatigue ». Non suivi : l'ordre de la séance suit celui de l'épreuve visée (muscle-up, puis tractions, puis dips). Le lundi prépare justement l'enchaînement de l'épreuve, où les tractions viennent après le muscle-up. La relecture documentée ne relève pas ce point ; elle demande au contraire d'« entraîner les tractions sous pré-fatigue de muscle-up » si les ateliers s'enchaînent. Le recalage de la série de tête sur un maximum mesuré après muscle-up reste une piste (§ 7).

**street_14, calisthénie (note 8).** Le correcteur demande de remplacer le « handstand dos au mur » et son repli sur parallettes par une variante faisable au parc (tenue en pike, appui pieds surélevés sur la barre basse, poteau si l'athlète en a un). La demande est fondée : le profil ne déclare ni mur ni parallettes. Elle avait déjà été faite à la boucle 2 par les écoles calisthénie et santé. Elle n'a pas été traitée dans le lot : aucune boucle n'a remplacé cet exercice pour ce profil. Elle passe dans le reste à faire (§ 7).

**Demandes de volume supplémentaire contraires aux plafonds du référentiel.** La relecture documentée demande souvent d'ajouter du volume : un bloc de densité de 60 à 80 tractions de plus par semaine (street_14), 2–3 séries de pompes de plus par séance (street_03), 10 à 20 séries par groupe dès S3–S4 pour la reprise (street_04), un bloc muscle-up et des tirages en front lever (street_05), des accessoires de poussée (street_12), un footing de plus (street_17). Le moteur applique les plafonds du référentiel (au-delà de 10, 16, 20 et 25 séries par muscle et par semaine pour le débutant, l'intermédiaire, l'avancé et l'élite, on n'ajoute plus sans raison explicite : R1-P3 et R5-P13), les garde-fous de montée (+10 à 20 % par semaine, R5-P22) et, pour les débutants, les plafonds que l'école hypertrophie a demandés à trois reprises. Ces demandes n'ont pas été suivies telles quelles. Les options de pratique hors séance (séries fréquentes sous-maximales les jours de repos, street_06 et street_14) ne l'ont pas été non plus : elles ajoutent du volume de tirage hors du plan écrit et hors de ces plafonds.

**Demandes contradictoires entre jurys.** Quand les deux jurys demandaient l'inverse, la version conforme au référentiel du panel a été gardée :
- seuil de douleur du coude (street_12) : 2/10 pour toute progression (école force), et non « ≤ 3/10, voire 5/10 si retour au niveau de base le lendemain » (relecture documentée) ;
- affûtage du débutant (street_01, street_03) : affûtage court à −30 % (R3-P12), et non −40 à −60 % sur deux semaines (relecture documentée) ;
- tirage du débutant : plafond de 8 à 10 séries directes par semaine (écoles hypertrophie et santé), et non davantage de négatives et de tenues (relecture documentée) ;
- repos-pause : un seul mouvement par semaine, 3 relances au plus (école force, en s'appuyant sur R2-P13), et non deux fois par semaine (relecture documentée, street_14) ;
- lest proche du poids du corps (street_11) : départ conseillé puis calibrage à la réserve, compromis entre le « lest réel dès S1 » du panel (boucle 4) et le « poids du corps au bloc 1 » de la relecture (boucle 5).

**Autres demandes de la relecture documentée non suivies au moment de l'arrêt.** Les 18 corrections hautes de la boucle 7 sont restées ouvertes ; elles forment l'essentiel du § 7.

## 7. Ce qui reste à faire pour atteindre la cible

Les 18 corrections de priorité haute de la relecture documentée finale se répartissent ainsi : travail spécifique des figures (5), temps de séance sous-utilisé et volume spécifique trop faible (4), compléments manquants (3), charge et fréquence (2), repère et tentative non calés sur le réel (2), échelle de difficulté (1), objectif absent (1). Recommandations concrètes, par ordre d'effet attendu :

1. **Utiliser le temps de séance disponible.** Plusieurs programmes n'occupent que la moitié ou les deux tiers du créneau : 26 à 50 min sur 60 (street_03), 29 à 43 min sur 60 (street_14), 16 à 46 min sur 60 (street_04), 33 à 48 min sur 75 (street_05), 31 à 47 min sur 75 (street_12), samedi de 15 à 23 min sur 90 (street_16), dimanche de 18 min sur 90 (street_10). Il faut une règle qui remplit le temps libre avec du travail spécifique à l'objectif, sous les plafonds de séries dures (séries sous-maximales loin de l'échec, technique, accessoires de l'objectif), plutôt que de laisser la séance courte.
2. **Travail spécifique des figures.** Tenues de 2 séries par séance à 70 % et plus du maintien maximal (et non toutes à 58–71 %) ; travail dynamique bras tendus (tirages en front lever tuck, négatives de front lever, montées en front lever, 3 × 5–8) ; travail assisté sur l'étape suivante (planche half-lay ou complète à l'élastique) ; un seul critère d'ouverture de l'étape suivante, atteignable avec les doses écrites (street_05, street_10) ; servir réellement les disciplines déclarées (figures à 30 % sur street_04).
3. **Recaler les repères sur le test réel.** Aujourd'hui, le plan écrit part du « repère attendu » au test et demande à l'athlète de recalculer s'il fait moins. La relecture le pénalise (street_06 en priorité haute, street_11). Il faut écrire le bloc suivant en fonction du résultat mesuré (série de tête = résultat − 2), ou afficher les deux versions. Même chose pour la première tentative en compétition : elle doit être une charge déjà réussie à l'entraînement (street_12 : ouverture à +37,5 kg alors que le plus lourd simple prévu est à +36,25 kg).
4. **Progression écrite semaine par semaine.** Supprimer les semaines « sans aucun changement » en construction (street_02 : S3, S5, S9 et S11 ; street_04 : S11 = S10) et les blocs d'intensification qui recopient le bloc 1 (street_05, street_11) ; écrire les échelles de difficulté (traction pieds au sol → élastique → négatives, row genoux fléchis → jambes tendues, street_02) ; publier les semaines complètes plutôt que des différences en cascade (demande du panel à la renotation).
5. **Rampe de charge et budget du coude.** Semaine 1 en vraie introduction (70–80 % de la semaine 2) pour les gros volumes de sets & reps (street_08 : environ 300 tractions et 540 dips dès S1) ; pas deux séances de densité de traction sur deux jours consécutifs ; au moins 48 h entre deux séances de tirage lourd chez l'athlète au coude fragile (street_09 : tirage cinq jours sur cinq).
6. **Compléments d'objectif.** Jambes chargées quand le matériel le permet (squat et soulevé de terre roumain à 51 ans, street_11) ; accessoires de poussée pour un objectif de 1RM aux dips (street_12) ; renforcement du coureur et côte (sprints en côte, sauts unipodaux) et volume de course facile progressif (street_17) ; traction plus proche de l'échec pour un gain de +50 % (street_13).
7. **Profil sans objectif.** Proposer une cible chiffrée et datée quand le profil n'en a pas (street_04 : retour vers les anciens records).
8. **Les deux corrections nécessaires du panel.** Handstand faisable au parc sans mur (street_14) ; série de tête de tractions de street_08 recalée sur un maximum mesuré après muscle-up, en gardant l'ordre de l'épreuve.
9. **Méthode de notation.** Avant la prochaine série de boucles : mesurer la dispersion du jury documenté (deux notations du même export) et trancher les conflits connus entre jurys (douleur, affûtage du débutant, tirage du débutant, repos-pause) dans le référentiel, pour qu'une correction ne soit plus pénalisée par l'autre jury. Sans cela, une moyenne de 9,5 à la relecture documentée reste hors de portée : un écart d'un point sur un export inchangé a été observé sur trois profils.
10. **Conflit d'attentes de street_12.** Réécrire l'attente « aucun exercice à contrainte forte sur le coude » pour qu'elle soit compatible avec l'objectif de 1RM de dips lestés (par exemple : contrainte forte autorisée sur le mouvement de l'objectif, sous la règle de douleur), ou changer l'objectif du profil.
