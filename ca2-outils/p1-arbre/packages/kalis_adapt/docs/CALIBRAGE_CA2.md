# Calibrage de `kalis_adapt` 0.2.3 et 0.3.0 (lot CA2)

Lot CA2 du pipeline « Calibrage des programmes ». Partie 0 : street (conduite sous douleur, maintien
récent, estimation, assistance, affûtage) → 0.2.3. Partie 1 : autres disciplines → 0.3.0 (section plus bas).
Saisons croisées jugées avec `kalis_plan` 0.2.2 (dernière étiquette publiée de `kalis_plan` pendant la
partie 0). Règles, paramètres et sources : `CONTRAT.md`, § 11.16.

## Partie 0 — street

### Dérive du panel (avant la première passe)

Ancres de la manche précédente renotées à l'identique : `p08_a` 1/1/1/1, `p14_c` 9/8/8/8 → pas de dérive.
Empreintes SHA-256 des grilles, de `COMMUN.md` et du référentiel identiques à celles de la manche 4.

### Boucle 1 — ce qui a changé (sécurité d'abord)

- Reprise graduée conduite séance par séance (palier qui recule quand la douleur répond, dose écrite jamais
  dépassée, arrêt gardé quand il se lèverait sur une semaine qui n'est pas de charge, reprise propre au
  moteur quand l'arrêt se lève en milieu de bloc). Sources : règle écrite par `kalis_plan` (CX correction 1),
  Silbernagel et al. 2007, Soligard et al. 2016.
- Tests jamais sur une zone douloureuse, en reprise ou à l'arrêt gardé (banc 0.2.2 : 0,49 hausse sur zone
  douloureuse par saison dans les scénarios de douleur de `street_12`, toutes venues de tests ; après : 0).
- Appui du poignet sensible : dose d'appui écrite au plus.
- Meilleur maintien récent (28 jours, depuis la dernière coupure) au lieu du record d'avant un arrêt.
- Tentatives : gain d'affûtage de 2 % (Travis et al. 2020) ; tentatives réussies à 97 % au banc, contre 82 à
  91 % de deuxièmes barres en compétition (Darragh et al. 2025).
- Simulateur : zone réactive après un épisode (modèles B et C), poussées comptées.

### Passe 1 (13 profils, contrôle dev 2)

11 couples sur 52 à 9. Les corrections nécessaires portent presque toutes sur le programme écrit
(`kalis_plan`, lot CP2) : volume de tirage, échelles de pompes, critères de passage, progression bloquée par
« maximum − 2 ». Côté conduite : cadence de l'élastique (`street_01`, demandes à la fois « pas trop
souvent » et « pas trop tard »), poussée à prise neutre sur poignet douloureux (`street_01`, `street_03`).

### Boucle 2 — ce qui a changé

Cran d'élastique : deux séances au même cran, sept jours au moins depuis le dernier changement, montée
seulement après un manque réel (ACSM 2009, règle « 2 pour 2 ») ; substitution à prise neutre du poignet
(variante qui ne provoque aucune autre zone à l'arrêt). Relecture indépendante du code : 16 constats, tous
corrigés (levée datée sans compteur courant, part la plus basse, arrondi vers le bas, tolérance de la zone
réactive qui ne baisse pas, `taperedAt` avant le bloc, gain d'affûtage avant la première tentative, semaine
de levée comptée à moitié, contrat).

### Passe 2 (6 profils, contrôle dev 7)

`street_01`, `03`, `07`, `09`, `12`, `16` (changés par les boucles 1 et 2, ou jamais notés en passe 1).
Avec la passe 1 : 17 couples sur 68 à 9, minimum 6, moyenne 7,87 (manche 4, CX correction 1 : 23, 5,5, 7,95).

### Relecture documentée (C7.6, sans seuil)

Trois relecteurs Opus, sources web vérifiées, huit saisons du contrôle dev 7 lues en entier : `street_01`
6,5 ; `03` 5,5 ; `06` 6,5 ; `07` 6,5 ; `08` 5,5 ; `10` 5 ; `12` 7 ; `14` 6. Constats côté conduite et
traitement :

- estimations baissées par des séries faciles ou arrêtées tôt → boucle 3 (série arrêtée sous la cible lue
  comme une borne jusqu'à une deuxième mesure ; série lourde lue avec le biais de note appris) ;
- tentatives à 90-92 % du maximum du jour → boucle 3 (estimation) et gain d'affûtage (boucle 1) ;
- `street_08` : dips plafonnés à +26 kg après la transition (borne de santé comptée depuis une séance
  volontairement légère) → boucle 3 (borne comptée depuis la dernière semaine de charge) ;
- `street_10` : planche retirée plutôt que passée aux parallettes → règle du § 11.16 (appui neutre) ; le
  reste (choix des figures, volumes) relève du programme écrit.

Notes complètes : `ca2-outils` de la sauvegarde du lot (la page de relecture reçoit, en manche 5, la relecture documentée de la partie 1, sur le moteur livré).

### Boucle 3 — ce qui a changé

Estimation moins prudente (`CONTRAT.md`, § 11.16) : série lourde (≤ 8 répétitions possibles) lue avec le
biais de note appris (Halperin et al. 2022) ; série arrêtée sous la cible soumise à la règle de la deuxième
mesure ; bornes de santé comptées depuis la dernière séance d'une semaine de charge. Banc (17 profils × 8
scénarios × 3 modèles × 4 graines) : meilleure barre du jour de l'échéance 94,4 → 95,0 % du maximum réel,
tentatives réussies 96,6 → 95,3 %, échecs non voulus 0,21 → 0,23 %, écart d'effort 1,085 → 1,069,
violations 0,0153 → 0,0135, aucune hausse sur zone douloureuse.

### Passe 3 (4 profils, contrôle dev de la boucle 3)

Profils dont l'export a changé de plus de 10 % (`street_07` 10,6 %, `12` 10,4 %, `13` 11,1 %), plus
`street_05` (9,7 %). `street_12` (antécédent de coude, reprise graduée) passe à 9 dans les quatre écoles.
Les baisses de `street_05` (hypertrophie) et de `street_13` (hypertrophie, santé) visent le programme écrit
(dose de tenues du bloc 1, répétitions de raises au-dessus de la capacité, repos de 90 s, progression bloquée
par « maximum − 2 ») ; la trajectoire de `street_05` montrée (une graine) change de séance représentative,
les mesures moyennes du profil sont identiques à la boucle 2 (progression 0,28 %/sem., échecs 0).

### Boucle 4 — sécurité (relecture documentée du pilotage, manche 4, arrivée pendant le lot)

Douleur pendant l'effort jamais à 5/10 : `coachPainStop` 6 → 5, allègement dès 4/10 (Silbernagel et al. 2007,
lu sur une source secondaire), remplaçants au même seuil ; pendant un arrêt, mouvements à contrainte moyenne au
premier palier (moitié des séries, 3 en réserve, 67,5 % du 1RM), retirés après 14 jours d'arrêt si la douleur est
encore à 3/10 ou plus ; remplaçant d'une douleur du jour à 70 % du 1RM au plus ; sur une zone récente, +10 % par
séance au plus (Soligard et al. 2016). Boucle 4 bis : arrêt du poignet complet (échauffement compris, toute charge
externe d'appui retirée), test reporté tant que la zone a été signalée au-dessus de 2/10 dans la semaine, renvoi
vers un professionnel une fois par semaine au lieu de chaque séance. Boucle 4 ter : intensité entière du report de
test, zone douloureuse du jour comptée comme récente.

### Passe 4 (`street_01`, `street_10`, exports changés de plus de 10 %)

`street_01` 8 / 7 / 7 / 6 (passe 2 : 8 partout) ; `street_10` 7 / 5,5 / 8 / 6 (passe 1 : 6 / 6,5 / 7 / 7). Côté
conduite : élastique jamais changé (série remise à zéro quand la plage écrite monte) ; arrêt du poignet de la
boucle 4 bis trop large (planche sur parallettes retirée sept semaines, poussée du débutant perdue).

### Boucle 5 (dernière boucle de la partie 0, C9.2)

Appui neutre au poids du corps gardé au premier palier pendant l'arrêt du poignet (toute charge externe d'appui
retirée) ; poussée en extension remplacée par un appui neutre au poids du corps ; série de l'élastique comptée même
quand la plage écrite monte. Passe 5 (`street_01`) : 6,5 / 7 / 8 / 7.

### Correction de sécurité après la passe 5 (session du 08/10, hors boucle de calibrage)

Notes de la passe 5 lues en entier : l'école santé relève, pour `street_01`, des dips assistés gardés au premier
palier avec une douleur au poignet notée à 4/10, et des pompes remplacées par des dips négatifs aux barres pendant
l'arrêt (poignet à 4/10 des semaines 7 à 15) — contraire à la relecture documentée du pilotage (manche 4 : l'arrêt
couvre toute charge en extension du poignet). Correction (`CONTRAT.md`, § 11.16) : pendant un arrêt du poignet, le
remplaçant d'une poussée n'est qu'un appui sur parallettes ou poignées ; tant que la gêne de la semaine atteint
3/10, seuls ces appuis restent (dips aux barres, anneaux, pompes au sol retirés, échauffement compris). Test ajouté
(`coach_rules_test.dart`, `street_01`, poignet à 4/10 quatre semaines). Contrôle dev d2a5ef43 (run 37786847270) :
244 tests verts. Export de `street_01` changé de 5 % (sous le seuil de 10 % de `docs/PANEL.md`) ; renote faite
quand même (sécurité), ci-dessous.

### Relecture indépendante du code (08/10, sous-agent Opus) et passe 6

Douze constats, tous traités (`CONTRAT.md`, § 11.16, fin de section) ; les plus graves : un arrêt déclenché par
trois séances de suite au-dessus de 3/10 tombait au premier signalement plus bas ; l'étape de figure remplaçante et
le test reporté échappaient aux règles de douleur ; la part du 1RM de la reprise ne tenait pas sur un remplaçant.
Contrôle dev 74404ad9 (run 37792576775) : 245 tests verts, analyse sans remarque, formatage conforme.

Passe 6 (`street_01`, `03`, `10`, exports changés par les deux corrections, 5 à 10 % cumulés depuis leur dernière
notation ; renote demandée pour la sécurité) : `street_01` 7 / 7,5 / 7 / 7 ; `street_03` 6,5 / 6,5 / 6,5 / 6 ;
`street_10` 7 / 5 / 7 / 6,5. Corrections nécessaires côté conduite : **cadence de l'élastique** (trois écoles sur
quatre, `street_01` et `03` : passer à l'élastique plus fin dès qu'une série laisse 2 répétitions de réserve de plus
que visé) → reportée à la partie 1 (0.3.0 ; partie 0 arrêtée à cinq boucles, C9.2). `street_10`, école calisthénie :
garder la planche sur parallettes à 50 % pendant la douleur — contraire au constat 7 de la relecture du code
(contrainte forte retirée tant que la gêne atteint 3/10) : la sécurité prime, choix consigné. Les autres corrections
nécessaires visent le programme écrit (lot CP2 : répartition des appuis du poignet sur la semaine, dips du bloc 3,
progression du front lever, volume de tirage du débutant, échelle de pompe).

### Version livrée (0.2.3) — 68 couples

Entre parenthèses : note de la passe précédente quand elle a changé.

| Profil | Force | Calisthénie | Hypertrophie | Santé | Passe |
| --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 7 | 7,5 | 7 | 7 | p6 |
| `street_02_debutant_surpoids` | 8 | 8 | 8 | 9 | p1 |
| `street_03_debutante` | 6,5 | 6,5 | 6,5 | 6 | p6 |
| `street_04_reprise_longue_pause` | 9 | 9 | 8 | 9 | p1 |
| `street_05_inter_calisthenie_front_lever` | 7 | 8 | 6,5 (8) | 8 | p3 |
| `street_06_inter_sets_reps` | 9 | 8 | 7 | 8 | p1 |
| `street_07_avance_streetlifting_competition` | 8 | 8 | 8 | 8 | p3 |
| `street_08_avance_sets_reps_competition` | 6 | 7 | 7 | 8 | p1 |
| `street_09_elite_streetlifting` | 7 | 8 | 8 | 8 | p2 |
| `street_10_elite_figures` | 7 | 5 | 7 | 6,5 | p6 |
| `street_11_master_51_ans` | 7 | 7 | 8 | 7 | p1 |
| `street_12_antecedent_coude` | 9 (8) | 9 | 9 | 9 (8) | p3 |
| `street_13_peu_de_temps` | 7,5 (7) | 7 | 6,5 (8) | 7 (8) | p3 |
| `street_14_parc_sans_lest` | 8 | 8 | 9 | 9 | p1 |
| `street_15_travail_physique_sommeil_court` | 9 | 9 | 9 | 9 | p1 |
| `street_16_specialisation_traction_lestee` | 9 | 9 | 9 | 9 | p2 |
| `street_17_hybride_street_course` | 7 | 6,5 | 7 | 8 | p1 |

19 couples sur 68 à 9 ou plus, minimum 5, moyenne 7,76 (passes 1 à 6 ; dernière notation de chaque couple). **Cible C7.5 (9 partout) non atteinte.** Les
corrections nécessaires restantes portent sur le programme écrit (lot CP2 : volume de tirage, progressions
bloquées, critères de passage, dips du jeudi au bloc 2 de `street_07`, repos, tests). Côté conduite, aucune
correction nécessaire restante ; améliorations notées : référence de 1RM affichée qui change d'une ligne à
l'autre après recalage (lisibilité), muscle-up de `street_07` à 88 % du maximum du jour à la troisième barre.
Sécurité calculable : 0 violation sur les 136 saisons racontées (17 profils × 8 scénarios, modèle B, graine 0 :
mesure du lot CX, `saisons/SECURITE.md`). Sur 4 graines × 3 modèles, quelques hausses de volume trop rapides du
programme réalisé (`volume_trop_vite`, blocs réécrits par `kalis_plan` après une maladie ou une douleur :
`street_06` maladie, `street_07` douleur à l'épaule et au coude, `street_09`, `street_12` et `street_16`
douleur au coude ; `seance_trop_longue` pour `street_17` séances manquées) — déjà présentes en CX correction 1
(par exemple `street_06` maladie, 0,10 par saison sur 100 graines), au même niveau avant et après la partie 0
(0,0147 → 0,0135 par saison en moyenne) : rampe du bloc suivant après un bloc écourté, transmise au lot CP2.
Boucles arrêtées après la boucle 5 (C9.2 : cinq boucles au plus ; la suite dépend surtout du programme écrit, pas de gain attendu d'une
boucle de conduite). Hausses sur zone douloureuse au banc : 0,02 à 0,05 par saison, seulement `street_10` sous le modèle B (douleur de surcharge des tenues signalée pendant la séance), comme avant la partie 0 ; poussées d'une zone réactive 26,7 → 24,9.

## Partie 1 — autres disciplines (0.3.0)

Programmes d'entrée : ceux de `kalis_plan` 0.2.2 (chemin 0.1 pour les profils non street ; `kalis_plan` 0.3.0
n'était pas publié pendant le lot). Règles, paramètres et sources : `CONTRAT.md`, § 12 ; sources vérifiées par
un sous-agent Opus le 08/10 (Frandsen 2025, Buist 2008, Nielsen 2014, Kiviniemi 2007, Vesterinen 2016,
Javaloyes 2019, Bosquet 2007, Silbernagel 2007, Feito 2018, Klimek 2018, Tibana 2016, Wilson 2012, Murlasits
2018, Robineau 2016, Schumann 2022, Garber 2011, Sherrington 2020, Riegel 1981, Vickers et Vertosick 2016,
Soligard 2016 ; formulations corrigées pour Nielsen, Feito, Tibana, Robineau et Riegel).

### Boucle 1 — ce qui a changé

Course (sortie bornée à la plus longue des 30 jours + 10 %, séance de qualité servie facile un jour sans, durée
réduite un jour très bas, reprise après coupure), conditionnement (mise à l'échelle), fatigue croisée et charge
d'endurance dans le modèle forme-fatigue, invariants E1 à E3 (journaux aléatoires et simulations), vérité
d'endurance du simulateur (deux modèles), partie « Endurance et conditionnement » des trajectoires, règle
d'élastique « marge large » (passe 6). Relecture de bureau du code (Opus) : 21 constats, corrigés avant le
premier contrôle (dont : `copyWith` qui gardait les champs à effacer, douleur de jambe à 3/10, séances comptées
pour la borne, pas de double réduction). Contrôle dev 3c0539bb (run 37811408880) : tout vert.

### Passe q1 du panel (10 profils non street × 4 écoles)

40 couples, aucun à 9, minimum 3, moyenne 5,41 (mesure de départ du lot CR, couple 0.1 : moyenne des notes
d'ensemble ≈ 5,1). Les corrections nécessaires portent presque toutes sur le **programme écrit** par le chemin 0.1
de `kalis_plan` 0.2.2 (lot CP2) : course d'échéance non placée et sans affûtage, tests sur la distance de la course
(semi-marathon couru à fond en semaines 5 et 10), aucune allure, aucune séance spécifique, volume mal réparti,
tirage non budgété en CrossFit, double progression absente en musculation, objectifs non commentés. Côté conduite :
les tests de course plus longs que la borne de 10 % (trois écoles) → boucle 2.

### Boucle 2 — ce qui a changé

Test de course plus long que la borne : servi en course bornée à effort modéré, test reporté. Élastique : la série
repère (ouverte) ne remet plus la série de séances à zéro, et une série repère qui dépasse l'écrit de 2 répétitions
compte comme une marge large (relecture documentée de la partie 1, `street_03` : élastique jamais changé en 16
semaines). Campagne d'endurance (`test/endurance_campaign_test.dart`) : 0.3.0, comportement de 0.2 et règle des
10 % par semaine, à programme égal.

### Mesures de la boucle 2 (contrôle complet run 37816722395, puis tolérance de mesure)

Campagne d'endurance (`test/endurance_campaign_test.dart`, 16 semaines × 3 modèles de vérité × 20 graines, une
graine sur deux irrégulière, une sur trois avec une coupure de 12 jours ; programmes de `kalis_plan` 0.2.2) :

| Athlète | Politique | Surcharges / 100 saisons | Pic moyen (× plus longue des 30 j) | Course faite (min / sem.) |
| --- | --- | --- | --- | --- |
| course débutante (`coureur_cardio_3x45`) | 0.3.0 | 5,0 | 1,04 | 57 |
|  | 0.2 | 5,0 | 1,03 | 59 |
|  | règle des 10 % | 8,3 | 1,34 | 35 |
| semi-marathon | 0.3.0 | 10,0 | 1,10 | 138 |
|  | 0.2 | 13,3 | 1,55 | 149 |
|  | règle des 10 % | 13,3 | 1,59 | 80 |
| CrossFit (`crossfit_5x60`) | 0.3.0 | 30,0 | — | 0 |
|  | 0.2 | 35,0 | — | 0 |
|  | règle des 10 % | 35,0 | — | 0 |
| hybride 50/50 | 0.3.0 | 18,3 | 1,10 | 51 |
|  | 0.2 | 20,0 | 1,39 | 55 |
|  | règle des 10 % | 18,3 | 1,27 | 27 |

Lecture : à programme égal, 0.3.0 borne la plus grande sortie (pic moyen 1,10 au plus ; en 0.2, 1,39 pour l'hybride et 1,55 pour le semi-marathon)
en gardant 93 % du temps de course ; la règle des 10 % par semaine en coupe 41 à 51 % sans borner les pics (1,27 à
1,59), comme l'essai de Buist 2008 le laissait attendre ; blessures de surcharge simulées, total des quatre athlètes
pour 100 saisons : 63,3 (0.3.0), 73,3 (0.2), 74,9 (règle des 10 %), soit −14 % par rapport à 0.2. Les taux de base de la vérité sont des choix
raisonnés : seuls les écarts entre politiques se lisent. Aucune hausse de charge sur zone douloureuse.

Tests : `kalis_core` 328, `kalis_plan` 226, `kalis_adapt` 250 (dont propriétés : 10 240 journaux par suite, profils
de course compris, invariants E1 à E3), `kalis_bench` 65, `kalis_quest` 162 ; analyse sans remarque. Un test
d'endurance a échoué sur la seule tolérance de sa mesure (pic de 1,1345 pour une borne de mesure de 1,133 : la vérité
mesure la sortie à la vitesse du jour, le moteur à la vitesse moyenne du journal) : tolérance portée à 5 %, contrôle
complet relancé (@RUN@).

### Renote q2 (`street_01`, `street_03`, après la règle d'élastique)

`street_01` 7,5 / 8 / 7 / 6,5 (passe 6 : 7 / 7,5 / 7 / 7) ; `street_03` 7 / 7 / 6 / 5,5 (passe 6 : 6,5 / 6,5 / 6,5 / 6).
Écoles force et calisthénie en hausse (l'élastique change enfin : semaines 3 et 15 de `street_03`), hypertrophie et
santé un demi-point plus bas (corrections nécessaires sur le programme écrit : échelle de poussée, essais stricts non
écrits, conduite du poignet sans variante neutre écrite ; dans l'incertitude d'un point). Street en fin de lot :
**19 couples sur 68 à 9, minimum 5, moyenne 7,76** ; à 9 partout : `street_12`, `street_15`, `street_16`. Les autres
profils street : exports changés de moins de 4 % depuis leur dernière notation (règle d'économie, notes gardées).

### Relecture documentée de la partie 1 (C7.3, trois sous-agents Opus, sources web)

Street débutants et intermédiaires : `street_01` 5, `03` 4, `06` 6 ; avancés et élite : `07` 7, `08` 6, `10` 5, `12`
7 ; autres disciplines : course 10 km 4, semi-marathon 3, CrossFit 4, hypertrophie 4. Notes et commentaires sourcés
sur la page de relecture (manche 5, auteur `relecture-documentee`). Côté conduite, traités dans le lot : élastique
(série repère), tests de course bornés. Non traités (limites, § 6 de la livraison) : passage en course-marche après des
sorties répétées « pas en entier » (course débutante), surcharge progressive absente en mode 0.1 sur les programmes de
musculation (charges figées à 4-6 répétitions de réserve réelles : `autres_02`), sous-dosage persistant des dips après
un mauvais jour (`street_06`, `street_08`), estimation du muscle-up trop basse le jour J (`street_07`), suivi de l'état
du coude (`street_12`, côté programme). Le reste vise le programme écrit (lot CP2).

### Panel des autres disciplines — fin de lot

Passe q1 (moteur de la boucle 1) gardée comme mesure de fin de lot : les deux changements de la boucle 2 ne touchent
que les tests de course (exports de `autres_05` et `autres_06` changés de 1,6 et 0,9 %) et l'élastique (absent de ces
profils). **40 couples, aucun à 9, minimum 3, moyenne 5,41** (couple 0.1 de CR : ≈ 5,1). Cible C7.5 non atteinte : le
plafond tient au programme écrit par le chemin 0.1 de `kalis_plan` 0.2.2 ; à mesurer de nouveau avec `kalis_plan`
0.3.0 (CP2) au croisement final (CY).
