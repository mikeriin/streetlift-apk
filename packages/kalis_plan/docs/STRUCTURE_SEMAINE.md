# Structure de la semaine — gabarits, types de jour, règle de choix (`kalis_plan` 0.4.0, lot KS1)

Cahier des charges : `pipeline/cp/CAHIER_KS.md` (décisions du propriétaire au § 11). Code :
`lib/src/coach/structure.dart` (partie de `skeleton.dart`), `buildSkeleton`, `season.dart` (`targetOf`, jalons),
`prescribe.dart` (charges du § 8), `coach.dart` (note recalée, raisons des remplacements). Contrat : `kalis_core`
0.4.4 (`PlanDay.type`, `Pass1Plan.split`, six codes de raison).

Ce qui suit est dit comme **référence** quand une source le fonde, comme **choix raisonné** sinon.

## 1. Décision de haut en bas

1. **Besoins** : les disciplines déclarées donnent leurs parts ; les objectifs, leurs mouvements.
2. **Qualités** : un profil street qui déclare le streetlifting et le sets & reps à 25 % ou plus chacun reçoit deux
   qualités qui créent leurs jours — force lestée et endurance de force (décision du propriétaire, § 11.1 : « 25 %
   c'est bien ») ; en dessous, la discipline reste en compléments. Conditions (choix raisonnés) : niveau
   intermédiaire et plus (le débutant garde le corps entier, R5-P3), lest possible (sans lest, la force passe par les
   variantes du chemin sets & reps), pas de spécialisation (R4-H1 à H4 : la cible monte en fréquence, son chemin
   l'organise). La calisthénie secondaire reste servie par les jours de pratique de figure du chemin sets & reps
   (blocs courts en tête de deux séances) : une figure demande des expositions courtes et fréquentes (R4-F1, R4-F8),
   pas une séance entière par semaine — **choix raisonné, écart au § 11.1 assumé pour la calisthénie seulement**.
3. **Fréquence** : séances de chaque qualité au plus fort reste (méthode de Hamilton), à égalité la qualité de la
   discipline principale, une séance au moins pour chacune. En intensification et en réalisation, la qualité de
   l'échéance prend 20 points (§ 3.3.2 : 65 à 75 % de spécifique pour un objectif de répétitions, contrat § 12.13 ;
   même logique pour la force ; vingt points : choix raisonné).
4. **Gabarit** : choisi dans la bibliothèque (§ 2) par la règle du § 3.
5. **Types de jour**, placés sur les jours réels (§ 4), puis **exercices** (§ 5) et **charges** (passe 2).

## 2. Bibliothèque

| Code | Séances | Suite | Pour qui |
| --- | --- | --- | --- |
| `ppl6_q` | 6 | tirage, poussée, jambes, tirage, poussée, jambes ; à 3 + 3 : F, F, F, E, E, E (+ puissance) | deux qualités à poids comparable |
| `pp_l5` | 5 | tirage, poussée, tirage, poussée, jambes de la qualité dominante | cinq séances |
| `ul4` | 4 | haut, bas, haut, bas ; à 2 + 2 : F, F, E, E | quatre séances |
| `fb3` | 3 | corps entier, qualités au plus fort reste | trois séances |
| `fb2` | 2 | corps entier F, corps entier E | deux séances |
| `mix_q` | toutes | jours de force du chemin streetlifting, jours d'endurance du chemin sets & reps | toute répartition |
| `lift_dup`, `reps_pillars`, `figures`, `fb_beginner`, `gym_split`, `power_dup`, `run_week`, `wod_week`, `health_week` | — | chemins d'avant 0.4.0 | profils mono-discipline |

F : force (1 à 6 répétitions, 80 % du 1RM et plus), E : endurance de force (séries longues, densité).

Le gabarit fixe la suite des schémas ; la répartition au plus fort reste fixe les qualités : les premières
positions de la suite, dans l'ordre d'exigence, sont de force, les autres d'endurance. Ainsi `ppl6_q` à 4 + 2
(intensification vers une échéance de force) : tirage F, poussée F, jambes F, tirage F, poussée E, jambes E ; `ul4`
à 1 + 3 (sets & reps principal, streetlifting secondaire) : haut F, bas E, haut E, bas E.

Appuis : fréquence de deux par semaine au moins par groupe musculaire (Schoenfeld, Ogborn et Krieger 2016) ; pour la
force, le gain de la fréquence passe par le volume et la pratique du geste (Grgic et al. 2018) ; 48 h entre deux
charges dures d'une même zone (R4-F10, R5-P22) ; séance lourde et séance de volume d'un mouvement séparées (R2-P7,
R3-P3). La séparation des qualités par journée et l'ordre force puis endurance dans la semaine sont des choix
raisonnés (§ 2 du cahier), mesurés au banc.

`ppl3` (une qualité par semaine) et les gabarits à une seule qualité ne sont pas construits : aucun profil du banc où
ils départageraient ; les gabarits typés de la musculation (force + hypertrophie) non plus — le profil
`ks_05_force_hypertrophie` garde le chemin de la force.

## 3. Règle de choix (§ 3.4)

Les gabarits qui réalisent la répartition des séances — le gabarit typé quand la bibliothèque en a un, toujours le
gabarit composite — sont construits en entier (réglages communs compris), pour la répartition de la phase et, quand
elle en diffère, pour celle des disciplines (une répartition déplacée qu'aucun gabarit ne réalise sans laisser un
objectif sans emplacement ou sans casser la récupération ne passe pas devant : profil de test en intensification
vers l'échéance de force, 4 + 2 ne porte pas les neuf objectifs en six jours typés, le composite 4 + 2 les porte à
une récupération de 0,30, le `ppl6_q` 3 + 3 les porte à 1,0). Ils sont comparés dans cet ordre, le suivant ne
départageant qu'à égalité (sans compensation) :

1. **Sécurité** : règles actuelles (douleur, poignet, coude, reprise), identiques pour tous les candidats.
2. **Couverture** : objectifs sans emplacement porteur (moins).
3. **Récupération** : note de la semaine ≥ 0,9 d'abord, puis moins de paires de jours consécutifs qui chargent
   lourdement le même schéma.
4. **Spécificité** : mouvements visés exposés deux jours par semaine au moins (plus).
5. **Temps** : séances hors de ± 15 % du temps disponible et séances sans principal (moins).
6. **Préférences** : exercices aimés présents (plus).

À égalité, l'ordre d'essai : la répartition de la phase d'abord, le gabarit typé avant le composite. Cet ordre remplace, pour la structure, la moyenne pondérée de la note, où une composante
à 1,0 rachetait une récupération à 0,48 (constat K6).

## 4. Placement (§ 3.5)

Recherche exhaustive des ordres (720 au plus pour six séances), clés comparées dans l'ordre : paires de jours
consécutifs (le dimanche précède le lundi) qui chargent le même schéma ; le jour le plus exigeant (le premier du
gabarit : muscle-up lesté, sinon traction lestée) ouvre la rotation, c'est-à-dire suit le plus long repos de la
semaine (§ 11.2) ; jours de force et d'endurance d'un même schéma à moins de 72 h ; types longs (corps entier, haut
du corps) sur les jours longs ; à égalité, l'ordre le plus proche du gabarit. Profil de test (lundi à samedi) :
tirage F lundi, poussée F mardi, jambes F mercredi, tirage E jeudi, poussée E vendredi, jambes E samedi — chaque
schéma deux fois, à 72 h.

## 5. Remplissage (§ 3.6) et ordre par exigence (§ 11.2)

Chaque type appelle le travail de sa qualité sur ses schémas, le mouvement le plus exigeant en tête de séance
(muscle-up lesté, traction lestée, dips lesté, squat — le muscle-up lesté est classé premier par le propriétaire ;
pour les trois autres, choix raisonné : à part du 1RM égale, le tirage lesté et le dips engagent le coude et l'épaule
en fin d'amplitude, R5-P20, R5-P27) :

- **tirage F** : muscle-up lesté (lourd), traction lestée (lourd), variante du point faible, tirage horizontal,
  curl marteau ;
- **poussée F** : dips lesté (lourd), variante du point faible, pompes lestées, prévention de l'épaule ;
- **jambes F** : squat (lourd), variante du point faible, charnière de hanche, tronc ;
- **tirage E** : tractions (série de référence puis séries allégées), muscle-up strict (densité ou pratique),
  suspension longue pour le point faible « prise », tirage horizontal ;
- **poussée E** : dips (série de référence), pompes (densité), triceps, coiffe ;
- **jambes E** : squat à charge fixe pour un objectif de répétitions à une charge (« 35 × 70 kg » : la charge de
  l'objectif, les répétitions à la réserve de la phase, table R2-P2 puis formule d'Epley, une de plus toutes les deux
  semaines de charge), sinon squat de volume ; tirage explosif léger quand le muscle-up est visé ; fentes ; tronc ;
  mobilité ;
- **haut**, **bas**, **corps entier** : les mêmes briques, réunies.

Les réglages communs suivent (bras tendus, plafonds de volume par groupe, compléments de fin de séance). Un jour sans
principal est une erreur d'audit, pas un jour à remplir.

## 6. Type du jour

`PlanDay.type` : schémas (`pull`, `push`, `legs`, `full`, `skill`, `run`, `recovery`), qualité (`force`, `volume`,
`endurance`, `power`, `skill`, `conditioning`, `run`, `recovery`), charge (`heavy`, `medium`, `light`). Celui du gabarit
quand il le fixe ; sinon déduit des emplacements (`coachDerivedType`) : schémas du travail dur (corps entier dès que
deux des trois sont chargés), qualité de la méthode qui domine, charge la plus haute.

## 7. Couverture, échéances, jalons

- Chaque objectif reçoit un emplacement porteur (même lien que `plan.goal_support` : exercice, figure visée,
  mouvement de référence) ; sinon `plan.goal_uncovered` au bloc. Le banc contrôle chaque semaine de charge.
- `targetOf` : une échéance principale prime ; une échéance secondaire ou de préparation ne prime plus sur des
  objectifs datés plus tôt, qui deviennent la cible (`plan.milestone`) ; la saison repart ensuite vers l'échéance.
  Dans une saison d'échéance principale, la semaine de charge qui contient un objectif daté plus tôt devient une
  semaine de test (mini-pic sans affûtage complet).
- Pas plus de trois blocs d'accumulation de suite : le quatrième passe en intensification (constat K5 : quatorze
  cycles 3 + 1 identiques ; D4.8 ; R3-P3, R3-P9).

## 8. Note recalée (§ 3.4)

La note de 0.1 reste calculée et affichée ; quatre composantes sont recalculées sur le squelette du chemin street :

| Composante | 0.1 | 0.4.0 |
| --- | --- | --- |
| `recovery` | tout renforcement d'un même groupe deux jours voisins (prévention et assistance comprises) | schémas chargés : un jour est dur sur un schéma à partir d'un travail lourd ou de deux moyens ; la pratique technique, les tenues faciles, la prévention et la mobilité ne comptent pas (§ 3.4.3 du cahier) |
| `fatigue_balance` | fatigue systémique par minute, tolérance 30 % (à 1,0 presque toujours) | séries dures par séance : une séance légère à la moitié de la plus lourde est une ondulation voulue, en dessous la note baisse (choix raisonné ; R2-P7, R3-P3) |
| `joint_load` | articulations limitées seulement (à 1,0 sans gêne, même à 23 séries de tirage vertical) | le plus bas de 0.1 et de la part des séances dures d'un schéma au-delà de R4-F10 (2, 3, 3, 4 du débutant à l'élite) |
| `preferences` | exercices aimés du vivier de recherche | exercices aimés (quatre au plus attendus) et sus (six au plus) placés dans le programme |

La note globale est recalculée avec les mêmes poids.

## 9. Charges (§ 8 du cahier)

1. Muscle-up lesté : 1RM de travail relevé d'après le maximum au poids du corps, comme la traction et le dips (dix
   muscle-ups stricts à 80 kg : 80 / 0,75 = 107 kg de 1RM de travail, au lieu des 88 kg déclarés) ; mouvement lesté
   visé dont la part tombe encore sous le poids du corps : le plus petit pas de lest du profil et les répétitions que
   cette charge laisse à la réserve visée (note `minimum_load`), au lieu de +0 kg et de répétitions qui baissent.
2. Traction haute et dips à la barre fixe (rangés sous le muscle-up lesté au catalogue) : réglés sur la traction et le
   dips lestés, coefficients 0,85 et 0,9 (`coachLoadReferences`, choix raisonnés : aucune source ne chiffre ces
   transferts) ; la part annoncée est celle de la vraie référence.
3. Variante dont le garde-fou baisse la charge : la part annoncée suit la charge servie ; une semaine allégée n'est
   jamais plus lourde que la dernière semaine de construction.
4. Squat pause bas : réglé sur le 1RM du squat (variante à la barre de la même chaîne), comme les dips pause bas.
5. Revue : le remplaçant porte `plan.replaced_disliked` ou `plan.replaced_cannot_do` avec l'exercice remplacé.
