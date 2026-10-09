# Notes de coach du chemin street (kalis_plan 0.2.2)

Le chemin street (`CONTRAT.md`, § 12) ne rend aucune phrase. Il rend deux sortes de raisons :

- `plan.coach_note`, avec `note` (un code de `CoachNotes`, `lib/src/coach/prescribe.dart`) et `value`
  (un nombre décimal) ;
- `plan.progression_rule`, avec `rule` (un code de `CoachRules`), `step` (un nombre) et `unit`.

Le texte français est construit par `coachReasonText` (`lib/src/coach/texts.dart`) à partir du code et
de la valeur. Ce document donne, pour chaque code : ce que porte `value`, quand le moteur émet la note
(d'après le code), et le texte rendu, résumé en une phrase. « Bloc » veut dire que la note fait partie
des raisons du bloc (`blockReasonsOf`, passes 1 et 2) ; sinon elle est portée par une ligne de la
passe 2.

Deux codes existent, ont un texte, mais ne sont émis nulle part : `push_maintenance` et `reconciled`.

## 1. Raisons du bloc

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `general_warmup` | minutes (8) | toujours | Chaque séance commence par 8 min d'échauffement au plus (mobilité des épaules, poignets et hanches, tirages et pompes scapulaires, répétitions faciles du premier mouvement). |
| `ambitious` | résultat probable codé : `1000 + n` pour un objectif de première traction (n = 2 si l'objectif est d'au moins 3 tractions, sinon 1) ; `bas × 1000 + haut` sinon | objectif de 2 tractions ou plus sans traction acquise ; ou, à partir de l'intermédiaire, objectif daté de répétitions (record d'au moins 4, échéance à 4 semaines ou plus) dont le rythme demandé dépasse 2 % par semaine (1,5 % dès l'avancé), quand la fourchette probable reste sous l'objectif | Objectif ambitieux : possible mais pas garanti ; un résultat de « bas » à « haut » (ou une première traction propre, ou une ou deux) au test final serait déjà un bon cycle, sans forcer la forme ; pour un objectif de répétitions, si le repère de mi-parcours n'est pas atteint, le plan garde ses volumes et l'objectif se joue au cycle suivant. |
| `load_adjust` | pas en % (2,5) | le squelette porte du lesté (`lift.heavy`, `lift.volume`, `lift.maintain`) | Si la série de tête laisse moins de réserve que prévu, baisse les séries suivantes de 2,5 à 5 % ; si elle en laisse deux de plus, ajoute le plus petit pas la semaine suivante. |
| `reps_adjust` | séances (2) | toujours | Si les répétitions prévues ne passent pas, garde les mêmes chiffres ; 2 séances de suite en dessous, retire une série. |
| `bad_day` | 2 si le sommeil habituel est sous 6 h, sinon 1 | toujours | Baisse du jour (mauvaise nuit, courbatures, journée éprouvante) : une série de moins par exercice, au moins 3 en réserve, pas de test ; avec un sommeil court habituel, seulement sur une nuit de moins de 5 h. |
| `short_version` | minutes (25 si la séance la plus courte dure 50 min ou plus, sinon 15) | toujours | Jour chargé : version courte de 25 (ou 15) min, échauffement puis les deux ou trois premiers exercices. |
| `red_flags` | 0 | toujours | Arrêt immédiat et avis médical en cas de douleur dans la poitrine, d'essoufflement anormal, de malaise ou de vertige ; souffler pendant l'effort. |
| `missed` | baisse de volume en % (20) | toujours | Une séance manquée ne se rattrape pas ; une semaine manquée se refait ; deux semaines ou plus : deux semaines en arrière avec 20 % de volume en moins. |
| `test_use` | 0 | le bloc a une semaine de tests | Les tests recalent les charges, répétitions et secondes du bloc suivant, jamais sur un progrès supposé ; série de tête = résultat − 2, tenues = 60 à 85 % du maintien mesuré ; un test fait un jour de bilan bas se reporte de 48 à 72 h. |
| `test_rest` | heures (48) | le bloc a une semaine de tests | 48 h sans travail dur du mouvement avant un test. |
| `reentry_test` | réserve (3) | coupure de 3 semaines ou plus (`gapWeeks` ≥ 4) | Test d'entrée de reprise : en semaine 1, une première série arrêtée à 3 répétitions de l'échec sur chaque mouvement principal ; déclarer ces repères, les anciens records ne sont pas des charges de travail. |
| `tolerance_volume` | facteur de volume général (0,6 à moins de 1) | le facteur de volume du profil est sous 1 | Volume réglé à tant % du volume type du niveau, au vu de la récupération. |
| `already_applied` | 0 | un facteur de volume, de tirage ou de jambes sous 1, une réserve ajoutée, ou 40 ans et plus | Les réductions liées au profil habituel sont déjà dans les chiffres : ne pas les retirer deux fois ; la baisse du jour s'applique en plus (CX). |
| `band_choice` | répétitions visées (8) | le squelette porte un exercice assisté à l'élastique (identifiant contenant « assiste » et « elastique ») | Prends l'élastique qui permet 8 répétitions propres avec la réserve prévue, noté à chaque séance ; pieds en appui si le plus fort ne suffit pas ; changement d'élastique : règle `assistance_step` ; dès la sixième semaine, 1 à 3 essais isolés de traction stricte deux séances par semaine (sinon traction sautée et descente de 5 s). |
| `pain_general` | seuil d'arrêt sur 10 (6) | aucune zone à ménager | Règle de douleur générale : 0 à 2 continuer, 3 ou 4 ne rien ajouter, 5 variante plus facile et −30 à −50 % de volume, 6 et plus arrêter et consulter. |
| `walking` | minutes (30) | objectif de perte de poids | Marches en plus des séances, de 15 à 20 min vers 30 min, +10 min par semaine au total vers 150 puis 200 min d'endurance par semaine. |
| `tracking` | séances par semaine (nombre de jours) | objectif de perte de poids | Coche chaque séance (objectif : tant par semaine), note les minutes de marche, relève poids et tour de taille aux semaines 1, 6 et 12, le matin à jeun ; déficit modéré (500 kcal par jour au plus), protéines à chaque repas, 7 h de sommeil visées ; alimentation avec un professionnel de santé. |
| `pain_trend` | douleur relevée sur 10 | figure sur une zone douloureuse au bloc précédent (douleur du résumé d'adaptation, sous 6/10, CX) | Figure gardée, environ 40 % de volume en moins, variante la plus douce pour la zone, pas de hausse tant que la gêne ne reste pas sous 2/10 deux semaines ; arrêt et consultation à 6/10. |
| `weight_class` | limite de la catégorie en kg (négative : catégorie ouverte « plus de ») | épreuve de force (streetlifting) : catégorie déclarée, sinon celle du poids actuel (règlement FinalRep, CX) | Catégorie de poids, pesée 2 h avant la première vague (tolérance 0,1 kg, à vérifier pour la compétition), pesée hebdomadaire ; changer de catégorie plutôt que couper du poids à la fin ; charges recalculées si le poids change. |
| `event_format` | repos entre les ateliers supposé, en s | épreuve de répétitions dont le format n'est pas saisi (CX) | Aucun règlement unique : saisir ordre, temps limite, repos, pauses permises, standard ; en attendant, ordre muscle-up, tractions, dips et le repos supposé. |
| `skill_horizon` | semaines minimales par étape (12, 8 ou 6 selon le niveau) | une des deux figures statiques n'est pas à sa dernière étape (style figures) ; placée en tête des notes du bloc | La figure complète n'est pas atteignable dans ce programme : chaque étape demande au moins tant de semaines ; le test final porte sur l'étape actuelle. |
| `maintenance` | séries de l'emplacement | passe 1 : raison de l'emplacement `lift.maintain` (voir aussi § 2) | En entretien : volume réduit, charge gardée, le volume va à l'objectif. |

## 2. Charges lestées

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `ramp_warmup` | séries de montée (3) | toute série de tête lestée (`lift.heavy` et ses rappels, dernier lourd) | Montée en charge : 3 séries progressives (40 %, 60 %, puis 75 à 80 % de la charge du jour) avant la série de tête. |
| `top_set_backoff` | baisse des séries allégées, en % (15, 10, 5, ou moins pour rester au-dessus du poids de corps) | série de tête suivie d'au moins une série allégée | Une série de tête, puis des séries allégées dont la baisse (en % de la charge totale) est écrite sur la ligne. |
| `speed_work` | part du 1RM (0,7 ; pour `lift.light`, la part réelle) | `lift.light` ; `lift.heavy` à J−2 et J−1 d'une épreuve avec pic, à J−2 et la veille d'un test sans pic | Séance légère à tant % du 1RM : chaque répétition rapide et propre, très loin de l'échec. |
| `opener` | part du 1RM (0,88 avant un test sans pic, 0,85 avant une épreuve avec pic) | rappel lourd de la semaine de l'échéance (`lift.heavy`, `lift.volume` du mouvement visé) | Rappel avant l'échéance : tant % du 1RM, une série de tête rapide et facile, sans forcer. |
| `maintenance` | séries de l'emplacement (2 la semaine de l'échéance) | `lift.maintain` | En entretien : volume réduit, charge gardée, le volume va à l'objectif. |
| `recalibrate` | pas en % (2,5) | `lift.heavy`, dernière semaine de montée avant un allègement, séance ordinaire, charge connue | Série de recalage : note charge, répétitions et réserve réelle ; une répétition de réserve en plus, le 1RM de travail monte de 2,5 % ; une de moins, il baisse de 2,5 %. |
| `dress_rehearsal` | jours avant l'épreuve (8 si inconnu) | dernier lourd de la semaine d'affûtage (J−5 et plus, au plus près de J−8) | Dernier lourd avant l'épreuve (J−n) : dans les conditions du jour J, amplitude jugée, filme-toi de profil. |
| `calibrate` | réserve visée (celle de la ligne, 3 par défaut) | charge lestée sans 1RM (`_loadAt`), ou lest proche du poids de corps impossible à calculer | Charge à régler à la première séance : monte par paliers jusqu'à une série qui laisse tant de répétitions en réserve. |
| `small_load` | lest de départ en kg | série de travail lestée (`_loadAt`) hors pic de force, quand le poids de corps fait 78 % ou plus du 1RM total ou que la part visée tombe sous lui : lest = part que la table R2-P2 donne pour « répétitions écrites + réserve », moins la part du poids de corps, arrondi au pas ; s'il est nul ou négatif, la ligne passe « à calibrer » (`calibrate`) et cette note n'est pas émise | Le 1RM lesté est proche du poids de corps : la charge se règle à la réserve, départ conseillé de tant de kg de lest ; à la première séance du bloc, série de calibrage (paliers de 1,25 à 2,5 kg jusqu'à la série qui laisse la réserve écrite), puis le plus petit pas quand toutes les séries passent ; réserve non tenue : −2,5 kg dans la séance. |
| `bodyweight_floor` | part réelle du 1RM (poids de corps / 1RM total) | charge visée sous le poids de corps, en pic de force ou sur une série qui n'est pas de travail | Série sans lest, à tant % du 1RM (poids du corps compris), avec moins de répétitions pour garder la réserve. |
| `overload` | part du 1RM complet | variante en amplitude partielle (`lift.variant`, identifiant « partiel ») | Amplitude partielle (10 à 15 cm de fin de mouvement) à tant % du 1RM complet, toujours avec butées ou parade ; retire l'exercice si le coude ou l'épaule dépasse le seuil de douleur. |
| `estimated_load` | lest de départ en kg | `reps.strength` lesté sans 1RM, avec au moins 3 répétitions connues sur le geste de base ; première semaine du premier bloc | Charge de départ estimée d'après le maximum au poids du corps : tant de kg de lest, à ajuster à la première séance. |
| `pull_return` | pas en kg (2,5) | traction de retour du coude (`reps.volume`, emplacement marqué `pull_return`, coude ménagé en streetlifting) | Retour au tirage lesté : quand le coude reste à 2/10 ou moins deux semaines, ajoute 2,5 kg (3 × 5), puis 2,5 kg toutes les deux semaines au plus. |
| `attempts_plan` | part du 1RM de la première barre (0,91) | test de 1RM en trois tentatives, le jour de l'échéance (intermédiaire et plus, 1RM connu) | Trois tentatives : 91 %, 96 %, puis la deuxième + 2,5 à 5 kg ; 6 min entre deux ; pas de troisième barre si une zone dépasse le seuil de douleur. |
| `attempts_goal` | charge externe visée, en kg | même test, si la barre visée (échéance ou objectif de 1RM) vaut plus de 100 % et au plus 107 % du 1RM total | La barre de l'objectif (tant de kg) est au-dessus du 1RM de départ : à tenter seulement si les simples lourds sont montés vite, après recalcul du 1RM. |
| `primer` | part du 1RM (0,65) | J−2 d'une épreuve de force avec pic, mouvement de l'épreuve avec 1RM | Amorçage à l'avant-veille : deux simples à 65 % du 1RM par mouvement, dans l'ordre de l'épreuve. |
| `entry_set` | réserve (3 ; 4 après 16 semaines d'arrêt ou plus) | premier bloc, semaine 1, coupure déclarée « moins de 3 semaines » ou plus longue (`gapWeeks` ≥ 2) : série de travail `reps.top`, `reps.strength`, `reps.volume` ou `reps.density` d'un mouvement qui a un record de répétitions, à la première séance de la semaine qui le porte | Série d'entrée de reprise, ce jour-là seulement : la première série de la ligne va jusqu'à tant de répétitions de l'échec, à la place du chiffre écrit (départs au chrono : une série avant, puis 3 min de repos) ; maximum de reprise = total + tant ; s'il est sous le repère écrit, recalculer les séries de la semaine sur lui, aux mêmes pourcentages. |

## 3. Répétitions au poids du corps

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `ramp_bodyweight` | séries de montée (2) | série de tête de `reps.top` | Avant la série de tête : 2 séries faciles (un tiers, puis la moitié des répétitions prévues). |
| `rest_pause` | relances (3) | `reps.top`, objectif de série longue (15 répétitions ou plus) au-dessus du maximum, conditions du CONTRAT § 12.5 | Repos-pause, seulement les semaines où la note figure : la dernière série se prolonge par 3 relances au plus de 3 à 4 répétitions après 20 s de pause, une répétition en réserve chacune ; elles comptent pour une série dure ; pas de relance si le coude ou l'épaule dépasse le seuil de la règle de douleur. |
| `every_minute` | intervalle en secondes (60 à 180) | `reps.density` | Départs au chrono : une série toutes les tant de secondes ; arrête quand les répétitions ne passent plus. |
| `quality_first` | qualité minimale sur 5 (4) | `reps.technique`, `skill.balance` | À faire frais, en début de séance ; arrête dès que la qualité passe sous 4 sur 5. |
| `easy_before_test` | part des répétitions habituelles (0,6) | séance à J−2 d'un test daté sans pic : travail au poids du corps et lesté hors `lift.heavy` et `lift.maintain` | À deux jours du test : deux séries au plus à 60 % des répétitions habituelles, très loin de l'échec. |
| `activation` | part du maximum (0,4) | J−2 d'une épreuve avec pic : `reps.top`, `reps.volume` ou `reps.density` d'un exercice de l'épreuve, maximum d'au moins 5 | Activation à l'avant-veille : deux séries faciles à 40 % du maximum par atelier. |
| `event_rehearsal` | repos entre ateliers, en secondes (300) | épreuve de répétitions : première séance à série longue des semaines de réalisation (une sur deux sous l'élite) et d'affûtage jusqu'à J−9 | Répétition de l'épreuve : une série longue par atelier, dans l'ordre, 300 s entre les ateliers, pauses bras tendus prévues, filme-toi. |
| `push_maintenance` | séries par séance | jamais émise | Poussée en entretien : l'objectif porte sur le tirage, la poussée garde tant de séries par séance. |
| `reconciled` | charge totale retenue, en kg | jamais émise | Le maximum au poids du corps indique un 1RM plus haut que celui déclaré : charges calculées sur un seul repère de tant de kg. |

## 4. Débutant

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `slow_negative` | secondes de descente (4 à 7 ; 4 en `skill.dynamic`) | `beginner.negative` sur la traction ; repli de `beginner.main` sur `sw-traction-negative` ou `sw-dips-negatifs` (dosé comme une descente freinée) ; descente freinée en `skill.dynamic` | Descente freinée en tant de secondes, sans à-coup ; arrête dès qu'une descente passe sous 3 s ; sinon élastique ou 2 à 3 s. |
| `slow_negative_push` | secondes de descente (3 ; 4 à partir du rang 2) | `beginner.negative` sur la pompe en descente freinée (`sw-pompe-negative`) | Pompe complète en descente freinée de tant de secondes, corps gainé de la tête aux talons, poitrine au sol ; remonte en posant les genoux ; arrête dès qu'une descente passe sous 2 s ou que le bassin s'affaisse. |
| `push_ladder` | répétitions du bas de la plage (6) | `beginner.main` sans record, sur une variante de la pompe | Échelle de poussée (mur, mains surélevées, genoux, sol) : prends le cran qui permet 6 répétitions avec 3 à 4 en réserve. |
| `negative_gate` | secondes repères ; négative (−10) quand l'essai strict la précède | test de la tenue menton au-dessus de la barre, comptée en secondes (débutant sans traction, semaine de tests ; jour de l'échéance d'un objectif de traction non acquise) — CX : remplace la descente freinée, comptée en répétitions par le catalogue | Test : la tenue menton au-dessus de la barre la plus longue, deux essais chronométrés ; le temps mesure la position haute d'un test à l'autre (pas un critère d'accès à la traction) ; avec la valeur négative, seulement si aucune traction n'est passée. |
| `strict_attempt` | répétitions de l'objectif de traction (1 sans valeur) | même test, quand la traction est un objectif | Test, d'abord l'essai strict, frais : jusqu'à 3 essais séparés de 3 min ; si une traction passe, la déclarer. |

## 5. Figures et maintiens

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `submaximal_hold` | 0,7 (toujours) | maintiens en secondes de `beginner.hold`, `skill.hold`, `skill.easy_hold` | Tenues sous-maximales à 60 à 75 % du dernier maintien maximal mesuré ; chaque tenue reste propre. |
| `hold_calibrate` | part du maximum à travailler (0,6) | même maintien sans repère, première semaine du premier bloc | Première séance : mesure ton maintien maximal propre, puis travaille à 60 % de ce temps. |
| `max_attempt` | semaines entre deux essais (2) | élite, séance lourde d'une figure, semaines de montée de rang impair, maintien connu | Toutes les 2 semaines, la première tenue est un maintien maximal propre ; les semaines suivantes valent 60 à 75 % de ce repère. |
| `step_gate` | secondes du critère de passage (12, 10 ou 8) | `skill.attempt` (essais de l'étape suivante) | Étape suivante sous condition : maintien d'au moins 0,75 × critère (arrondi à la seconde supérieure) au dernier test, puis 3 × critère sur une séance lourde par semaine, propres 3 séances de suite, avant d'ouvrir les entrées de 2 à 3 s. |
| `hold_ramp` | minutes de repos avant l'essai (3) | test de maintien maximal d'un exercice bras tendus (famille appui, suspension ou mixte) | Avant le maintien maximal : préparation habituelle des poignets et des épaules, 2 tenues de montée (une étape plus facile 5 s, puis l'étape du test 2 à 3 s), 3 min de repos ; jamais à froid. |
| `cue` | consigne : 1 traction, 2 dips, 3 muscle-up, 4 front lever, 5 planche, 6 pompe, 7 squat, 8 équilibre, 9 traction poitrine à la barre, 10 pompe sur les genoux | travail des méthodes principales (`lift.heavy`, `lift.volume`, `reps.top`, `reps.strength`, `reps.volume`, `reps.technique`, `skill.hold`, `skill.balance`, `beginner.main`), hors préparation et hors emplacement d'appoint, quand l'exercice entre dans une de ces familles | Une consigne d'exécution par geste (par exemple, traction : départ bras tendus, épaules basses, menton au-dessus de la barre, sans élan). |

## 6. Tests et échéance

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `max_set_plan` | répétition repère à mi-série (moitié du maximum prévu s'il atteint 12, sinon 0) | test de série maximale d'un exercice dont le record est d'au moins 4 | Avant la série maximale, 2 séries faciles (un quart, puis un tiers du maximum) et 2 à 3 min de repos ; pendant, rythme régulier dès le départ, souffle en haut de chaque répétition, pauses courtes en position de repos si le standard de l'épreuve les autorise ; répétition repère à mi-série si la valeur est positive. |
| `checkpoint` | valeur attendue (répétitions, secondes, ou kg arrondis au 2,5 inférieur) | test hors échéance d'un exercice qui a un objectif de performance daté et chiffré au-dessus du record | Repère sur le chemin de l'objectif : tant ; s'il n'est pas atteint, garder les volumes du bloc. |
| `event_day` | jours entre la séance et l'épreuve (0 pour un objectif daté sans épreuve inscrite) | chaque test du jour de l'échéance | Avec une valeur positive, la séance se déplace au jour de l'épreuve ; sinon c'est le test de l'objectif, après 48 h sans travail dur. |
| `rest_before_event` | jours (2) | préparations des séances à J−2 et J−1 d'une épreuve avec pic, et de la veille d'un test sans pic | Repos avant l'échéance : mobilité et préparation articulaire seulement. |
| `recovery` | 0 | séance qui n'aurait que de la préparation (surtout après l'échéance) : travail facile du premier emplacement | Récupération : facile, sans chercher la performance. |

## 7. Assistance

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `role_forearm` | 0 | assistance dont l'identifiant contient « wrist-curl » (fléchisseurs ou extenseurs du poignet), hors emplacement `tendon` | Avant-bras en charge légère, loin de la limite : tolérance du coude et du poignet au volume de tirage et aux appuis. |
| `role_runner` | 0 | assistance : mollets (identifiant contenant « mollets »), rebonds (`cf-pogo-jumps`), corde (`ca-corde…`) | Renforcement du coureur : mollets en charge lente, rebonds courts et élastiques, pour le tendon d'Achille et l'économie de course ; retire les rebonds à 3/10 de douleur au tibia, au tendon d'Achille ou au pied. |
| `role_prehab` | 0 | `accessory.prehab` | Prévention : coiffe et fixateurs des omoplates. |
| `role_row` | 0 | tirage horizontal | Équilibre des épaules face à la poussée et au tirage vertical. |
| `role_posterior` | 0 | charnière de hanche, flexion du genou, extension de hanche | Chaîne postérieure : ischio-jambiers et fessiers. |
| `role_elbow` | 0 | isolation des biceps | Fléchisseurs du coude en charge légère : tolérance du coude au tirage lourd. |
| `role_core` | 0 | `accessory.core` (autre cas) | Tronc : le gainage qui tient la position à la barre. |
| `role_legs` | 0 | `accessory.legs` (autre cas) | Jambes : force utile, sans fatigue excessive. |
| `tendon_load` | douleur à partir de laquelle la charge ne monte plus (3) | fléchisseurs du poignet de l'emplacement `tendon` (coude ménagé, streetlifting) | Charge progressive du tendon, à faire valider par le professionnel qui suit le coude ; à 3 ou 4 sur 10, charge inchangée. |

Les notes de rôle sont choisies dans l'ordre du tableau : la première qui convient.

## 8. Course

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `easy_pace` | minutes | footing, sortie longue, marche de fin de séance | Allure de conversation, tant de minutes. |
| `interval_pace` | secondes pour une fraction (temps prévu sur 3 km ramené à la distance de la fraction) | séance de qualité à fractions en mètres, avec un chrono connu | Allure des fractions : 400 m en tant de min et s, récupération en trottinant. |
| `goal_pace` | secondes au kilomètre (temps visé ÷ distance) | fractions de 1 000 m à l'allure de l'objectif ; test chronométré final | Allure de l'objectif : tant de min et s au kilomètre, régulière. |
| `time_trial` | distance en mètres | test chronométré sur la sortie longue d'une semaine de test (moitié de la distance de l'objectif, ou distance entière) | Test chronométré sur tant de km après 10 à 15 min d'échauffement ; il recale les allures. |

## 9. Séance

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `superset` | repos entre les tours, en secondes (90) | premier exercice de chaque groupe enchaîné (deux membres ou plus) | Enchaîné avec l'exercice suivant ; 90 s de repos entre les tours. |

## 10. Règles de progression (`CoachRules`)

| Code | `step`, `unit` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `assistance_step` | 1, `cran` | `beginner.main` sans record sur un exercice assisté | Une seule règle pour changer d'élastique : toutes les séries au haut de la plage avec la réserve prévue, deux séances de suite → élastique plus fin (ou appui des pieds allégé) dès la séance suivante, retour au bas de la plage ; réserve non tenue → élastique précédent. |
| `double_progression` | 1, `reps` | `beginner.main` (sans record ou maximum de 6 et plus), `reps.volume` sans maximum, `reps.strength` sur variante sans record, assistance en répétitions | Quand toutes les séries atteignent le haut de la plage avec la réserve prévue, passer à la variante ou à la charge suivante et repartir du bas. |
| `load_step` | 1,5, `pct` | `lift.volume` en semaine de montée (charge connue) ; `reps.strength` lesté avec charge connue ou estimée | Les charges suivent les pourcentages écrits ; si la série de tête ne laisse pas la réserve prévue, garder la charge de la semaine précédente. |
| `rep_step` | 1, `reps` | `reps.top` ; `reps.volume` en semaine de montée ; `reps.strength` au poids du corps avec record | Répétitions calées sur le dernier maximum mesuré ; une de plus par série si toutes passent avec une réserve de plus, sans dépasser maximum − 2 ; après un test, série de tête = résultat − 2. |
| `hold_step` | 5, `s` (gainage et tenues d'appoint, tenues de `beginner.main`) ; 1, `s` (figures, tenues bras tendus d'appoint) | maintiens | Avec 5 et plus : +5 s par tenue quand toutes sont propres ; sinon : +1 s par tenue, l'étape suivante seulement au critère de passage. |
| `density_step` | 1, `min` | `reps.density` | Un départ de plus toutes les deux semaines au plus ; les répétitions par départ ne montent qu'après un test. |
| `duration_step` | 10, `pct` | course facile et sortie longue en semaine de montée (hors marche et footings courts) | Durée +10 % par semaine au plus. |

## 11. Autres raisons qui ont un texte du chemin street

`coachReasonText` rend aussi un texte pour ces raisons du registre : `plan.progression_rule` (§ 10),
`plan.pain_rule` (règle de douleur de la zone, seuil d'arrêt `stopAt`), `plan.weak_point`,
`plan.test_scheduled` (selon `testKind`), `plan.event_specific`, `plan.taper` (`volumeFactor`,
`daysToEvent`), `plan.to_calibrate`, `plan.season_phase`, `plan.peak_event`, `plan.training_age`,
`plan.return_from_gap`, `plan.recovery_profile` (sommeil, stress, travail, âge), `plan.concurrent_sport`,
`plan.specialization`, `plan.constraint_history`, `plan.skill_step`, `plan.cautious_health`. Pour toute
autre raison, il rend `null` : le texte générique de `kalis_core` s'applique.

## Ajouts de 0.2.2 (lot CX, correction 1)

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `pain_stop` | rang de la zone (`BodyZone.values`) | bloc : une douleur qui dure ou qui revient met la zone à l'arrêt ; ligne : figure gardée sur prise neutre pendant l'arrêt | mouvements qui provoquent la zone retirés, consulter, reprise après deux semaines à 2/10 au plus |
| `pain_return` | zone × 100 + palier de départ × 10 + dernier palier | bloc qui suit un arrêt | reprise graduée : 50 % puis +10 % par semaine, 3 en réserve |
| `pain_return_item` | part du volume habituel | ligne d'un mouvement en reprise | part du volume de la semaine |
| `pain_step` | 0 | ligne : étape plus facile d'une figure servie parce que la douleur écarte l'étape de travail | raison, retour après deux semaines à 2/10 au plus, test remis à ce retour |
| `plateau` | dernier résultat de test | bloc : test sans progrès sur le mouvement visé | le bloc change de méthode (variante plus dure du tirage) |
| `slow_tempo` | durée de la descente (s) | ligne : traction au tempo excentrique (plateau) | montée sans élan, 2 s en haut, descente freinée, arrêt quand la montée ralentit |
| `event_zone` | part du maximum écrite (%) | ligne : séries de la zone de l'épreuve en réalisation d'un objectif de répétitions | séries vers cette part, repos court, réserve sur la dernière |

## Autres disciplines (kalis_plan 0.3.0)

Depuis 0.3.0, le coach écrit aussi les autres disciplines (`lib/src/coach/general.dart`). Les notes ci-dessous
s'ajoutent ; aucune valeur existante ne change de sens.

- `general_warmup` et `short_version` portent un paramètre **additif** `family` hors street : `run` (course),
  `gym` (musculation, force, conditionnement), `health` (santé, mobilité, senior). `value` reste en minutes. Le
  texte décrit l'échauffement et la version courte de la discipline. Sans `family` : texte du street.

| Code | `value` | Émise quand | Texte rendu (résumé) |
| --- | --- | --- | --- |
| `wod_pace` | effort visé sur 10 (8) | ligne d'une pièce de conditionnement | Allure tenable du premier au dernier passage, 2 à 3 répétitions en réserve, mise à l'échelle, charges de repère. |
| `chair_squat` | 0 | squat d'un senior (65 ans et plus) en santé | Squat en assis-debout d'une chaise, mains en appui puis bras croisés, chaise plus basse ensuite. |
| `knee_shallow` | gêne déclarée du genou | chaise contre le mur, genou gêné à 3/10 ou plus | Chaise haute à 45-60°, gêne à 3/10 au plus pendant et le lendemain ; avis médical ou kiné à 5/10 et plus. |
| `balance_progress` | 0 | marche sur les talons d'un programme de santé (équilibre) | Appui sur une jambe près d'un appui, puis marche talon-pointe, puis tête tournée, avec un critère de passage. |
| `hold_support` | 0 | fente latérale d'un senior | Une main sur un appui, amplitude courte, transfert de poids si l'équilibre manque. |
| `interval_pace` | allure en secondes **au kilomètre** (0.3.0 ; avant : sur la fraction, texte « 400 m ») | fractions de course | Allure des fractions au kilomètre, tirée de l'allure estimée sur 3 km. |
| `event_day` | 0 | hors street : la course du jour de l'échéance (test chronométré) | Le jour J. |
