# Critères calculables du banc (kalis_bench 0.1.0)

Trois familles : **sécurité** (exigé : 0 violation), **qualité** (mesurée, non bloquante), **trajectoires** (moteur d'évolution). Chaque seuil cite le principe du référentiel (`REFERENTIEL.md`) qui le fonde. « Choix raisonné » : le référentiel donne une règle de prudence, pas un fait établi — c'est le cas de presque tous les garde-fous de sécurité (R5-P22 : la règle des 10 % elle-même n'a pas montré d'effet protecteur). Le banc les applique comme des bornes d'excès : un programme qui les franchit doit le justifier, un programme qui les respecte n'est pas pour autant bon (c'est le rôle des critères de qualité, des attentes de coach et du panel).

Vocabulaire : **série dure** = série de renforcement à 4 répétitions en réserve ou moins (une série sans cible compte) ; **séries fractionnées** = 1 par série pour un muscle principal de l'exercice, 0,5 pour un muscle secondaire (R1-P2) ; **semaine allégée** = volume ≤ 70 % du plus haut des trois semaines précédentes ; niveaux : débutant, intermédiaire, avancé, élite.

## 1. Sécurité (`lib/src/safety.dart`)

| Code | Ce qui est signalé | Seuils (débutant / intermédiaire / avancé / élite) | Fondement | Statut |
|---|---|---|---|---|
| `charge_trop_vite` | Charge totale (lest + part du poids de corps) d'un exercice en hausse d'une semaine à la suivante, à schéma de répétitions égal | +10 % / +5 % / +5 % / +5 % | R5-P3 (+2 à 10 % débutant, +2 à 5 % intermédiaire, ≤ 2,5 % par palier ensuite), R5-P22 (+5 à 10 %) | choix raisonné ; borne large pour l'avancé et l'élite (R5-P3 dit 2,5 %) |
| `volume_trop_vite` | Séries dures fractionnées d'un grand groupe au-dessus de la plus large de « référence × 1,20 » et « référence + 2 séries » (référence : plus haut des trois semaines précédentes) ; ou, sur deux semaines de charge de suite, au-dessus de la plus large de « × 1,30 » et « + 4 séries » | identiques à tous les niveaux | R5-P22 (+10 à +20 % ou +1 à 2 séries par semaine, +30 % au plus sur deux semaines) ; retour à la pleine charge admis après une semaine allégée (départ à 50 % : R5-P7, R5-P22) | choix raisonné |
| `plafond_volume` | Séries dures fractionnées d'un grand groupe au-dessus du plafond hebdomadaire ; en élite, plus de 2 groupes au-dessus du plafond avancé | 12 / 20 / 25 / 30 | R1-P1 | traduction de coach d'une méta-régression |
| `technique_sans_prerequis` | Technique d'intensification sous son niveau d'accès (format libre des moteurs 0.1 ou `technique.kind` de `kalis_core` 0.4.0), ou exercice qui est par nature une technique avancée (supramaximal, partielles surchargées, isométrie lestée, chaînes) | top set + back-off, série dégressive, AMRAP : intermédiaire ; cluster, rest-pause, myo-reps, excentrique accentué, contraste, vague : avancé | R2-P22 (matrice d'accès), R2-P12 à P19 | choix raisonné. Le référentiel ouvre clusters et rest-pause au second palier de l'intermédiaire (N2) ; le banc ne distingue pas N1 et N2 et retient le niveau avancé : un moteur qui sert un cluster à un intermédiaire confirmé sera signalé — à examiner au cas par cas par les lots de calibrage, pas à contourner |
| `exercice_trop_avance` | Exercice classé plus de un niveau au-dessus du profil, non déclaré connu | — | R5-P4, R4-F7 | choix raisonné |
| `exercice_non_acquis` | Exercice (ou palier plus dur de sa chaîne, ou exercice qui l'a en prérequis) que le profil déclare ne pas savoir faire | — | R5-P8, R4-F7 | règle logique |
| `contre_indication` | Contrainte forte sur une articulation à gêne ≥ 4/10 ; contrainte modérée à gêne ≥ 6/10 ; contrainte forte menée à moins de 1 répétition en réserve sur une zone fragile (antécédent de moins de 12 mois ou gêne ≥ 2) | identiques | R5-P23 (plafond de travail 3–4/10, arrêt à ≥ 6), R4-F11, R5-P20 | choix raisonné (seuils de douleur non validés hors patients suivis). Limite : les zones sans articulation du catalogue (cou, haut du dos, poitrine, abdomen, cuisse, bas de la jambe) ne sont pas contrôlées |
| `tendon_figures` | Tenues bras tendus d'une famille (poussée : planche et back lever ; tirage : front lever ; mixte : drapeau) plus de N jours par semaine ; ou secondes de tenue hebdomadaires au-dessus de la plus large de « référence × (1 + h) » et « référence + 5 s » | jours : 2 / 3 / 3 / 4 ; hausse h : 20 % / 15 % / 10 % / 10 % | R4-F10 (budget commun planche – back lever), R5-P22 (+5 à 10 % par semaine en bras tendus pour l'avancé et l'élite) | choix raisonné. Limite : une famille qui apparaît en cours de programme n'a pas de référence et n'est pas contrôlée la première semaine |
| `levier_trop_tot` | Palier plus dur d'une même chaîne de figure introduit avant le délai du niveau | 12 / 8 / 8 / 6 semaines | R4-F9 | choix raisonné (un essai transposé). Limite : le délai part de la première apparition dans le programme, pas de l'historique de l'athlète |
| `echec_risque` | Moins de 2 répétitions en réserve sur un mouvement à risque élevé (équilibres, muscle-up, figures, haltérophilie, poussée aux anneaux, squat et développés à la barre), à tout niveau ; toute série à l'échec chez le débutant ; 2 séries ou plus par semaine à 1 répétition en réserve ou moins sur des mouvements à risque chez le débutant | identiques | R5-P27 (risque élevé : échec interdit, RIR ≥ 2), R5-P4 (débutant : jamais d'échec) | choix raisonné (classes de risque non validées) |
| `seance_trop_longue` | Durée estimée au-dessus du temps donné + 15 % + 3 min (jour de l'épreuve exclu depuis 0.2.4 : sa durée est celle de l'épreuve) | identiques | décision D3 du pipeline GP (temps du profil) | la durée est une estimation (3 s par répétition, repos prescrits, 45 s de transition, 5 min d'échauffement) ; les enchaînements sont comptés comme des séries isolées (surestimation) |
| `decharge_absente` | Plus de N semaines de charge de suite sans semaine allégée (allégée = volume mesuré ≤ 70 % du plus haut des trois semaines précédentes ; l'étiquette du moteur ne suffit pas) | 12 / 7 / 6 / 6 | R3-P9 (réactive chez le débutant ; toutes les 5–6 semaines, puis 4–5), une semaine de tolérance | consensus d'experts et enquêtes ; 70 % est le seuil large (R3-P9 : séries −40 à −50 %) |
| `affutage_absent` | Semaine de l'échéance prioritaire : volume moins de x % sous le pic des six semaines précédentes (séries dures ; minutes d'effort hors renforcement quand le programme n'en contient pas) | −30 % / −30 % / −40 % / −40 % | R3-P12, R3-P21 | méta-analyse d'endurance transposée + enquêtes. Limite : la durée de l'affûtage (2 semaines en élite) n'est pas contrôlée ici, elle l'est par les attentes de coach du profil |
| `reprise_trop_dure` | Après ≥ 2 semaines d'arrêt, série de renforcement de la première semaine à moins de 3 répétitions en réserve | identiques | R5-P7 | choix raisonné. Limite : les baisses de charge et de volume du barème ne sont pas contrôlées (pas de programme antérieur à comparer) |
| `impact_deconseille` | Sauts, pliométrie, corde, balistique, haltérophilie pour un débutant d'IMC ≥ 30 ; tout exercice à impact à partir de 65 ans ou en mode prudent du questionnaire santé | identiques | R5-P9 ; R5-P25, P26 | choix raisonné (IMC 30 et 65 ans sont des bornes de prudence) |

Le rapport compte les violations par profil et au total. La CLI sort toujours à 0 : le banc mesure, il ne refuse pas — c'est le lot de calibrage qui doit atteindre 0 violation (PIPELINE_CP.md §2), contre la mesure de départ de `BASELINE_0_1.md`.

## 2. Qualité (`lib/src/quality.dart`) — notes de 0 à 1, « sans objet » quand le critère ne s'applique pas

| Code | Mesure | Repère | Fondement |
|---|---|---|---|
| `volume_bande` | Part des grands groupes travaillés dont les séries dures fractionnées moyennes (semaines de charge) sont dans la bande du niveau | 4–12 / 8–20 / 10–25 / 12–30 | R1-P1 |
| `frequence_prioritaires` | Séances par semaine des mouvements prioritaires (cibles de l'échéance, spécialisation) | au moins 2 | R1-P9, R2-P7 |
| `specificite` | Part des séries dures sur les mouvements de l'échéance dans les quatre dernières semaines | au moins 40 % | R2-P9 (≥ 80 % du mouvement exact en fin de préparation de force), R4-G1 (≥ 50 % dans la zone de l'épreuve) ; 40 % est un seuil large, choix raisonné |
| `progression_planifiee` | Part des exercices suivis dont la prescription progresse dans le bloc (charge, répétitions, séries ou secondes) | — | R5-P3, R1-P18 |
| `equilibre_poussee_tirage` | Rapport tirage / poussée du haut du corps (séries dures) | entre 1 et 2 | R5-P27 (tirage au moins égal à la poussée) ; borne haute : choix raisonné |
| `points_faibles` | Points faibles déclarés qui reçoivent un travail dédié | tous | R4-H2 |
| `affutage_aligne` | Baisse du volume placée sur la semaine de l'échéance (et non avant ou après) | — | R3-P12 à P14 |
| `variete_utile` | Diversité des exercices sans dispersion (indice de Jaccard entre semaines et entre séances) | — | R6-P4 ; repères de `kalis_plan` |
| `non_ressemblance_proprietaire` | Plus fort indice de Jaccard « exercice × schéma » entre une semaine générée et une semaine du programme personnel du propriétaire | < 0,30 | PIPELINE GP (G4), PIPELINE_CP §2 |

**Non-ressemblance aux programmes de référence privés.** Elle ne peut pas être calculée dans le paquet (les références sont chiffrées hors dépôt). Chaque lot qui a la clé la calcule dans sa session avec `tool/reference_jaccard.py` (couples « exercice × schéma » par semaine, exercices ramenés à leur famille ; lecture exacte, et lecture tolérante où les répétitions de la référence tombent dans la plage générée) et ne publie que le résultat par profil. Exigé : < 0,30 pour les deux lectures.

## 3. Attentes de coach (`lib/src/expectations.dart`)

Chaque profil porte 3 à 6 attentes écrites et 4 à 10 contrôles calculables (`docs/PROFILS.md`), tirés du référentiel et des mesures de référence. Le rapport donne, par profil, les contrôles tenus et non tenus. Ce sont des attentes, pas un programme : elles ne prescrivent aucun exercice × schéma.

## 4. Trajectoires (`lib/src/trajectory.dart`)

Un athlète simulé à vérité connue (simulateur de `kalis_adapt`, appelé tel quel) suit le programme sous le moteur d'évolution, boucle complète. Mesures et repères de verdict (tous des choix raisonnés ; ils servent à comparer deux versions d'un moteur, pas à certifier) :

| Mesure | Repère | Fondement |
|---|---|---|
| Échecs non voulus (part des séries de travail) | ≤ 5 % | R4-G3, R5-P27 : l'échec non planifié est un défaut de calibrage |
| Écart absolu moyen au RIR visé (cibles atteignables) | ≤ 1 répétition | cible de la validation de `kalis_adapt` (`docs/VALIDATION.md`) ; R1-P12 |
| Hausses de plus de 10 % d'un mouvement principal | 0 | R5-P3, R5-P22 |
| Performance à l'échéance ÷ meilleure série des semaines précédentes | ≥ 1 | R3-P12 : l'affûtage doit amener au meilleur niveau le jour dit |
| Déblocages non respectés (proposition appliquée d'office avant que son niveau soit débloqué) | 0 | décision D5.7 du pipeline GP |
| Aggravations de douleur | 0 | R5-P23 |
| Progression simulée (% par semaine, par exercice suivi) | comparée entre versions | — |

Le programme tel qu'il a évolué sous le moteur est repassé aux critères de sécurité (« violations, programme évolué »).

**Programmes au contrat 0.4.0 (0.1.2, lot CA1).** Un programme écrit en parts du 1RM, avec des jours lourds et des jours légers, des tests et des tentatives, ne se lit pas avec les deux premiers repères de hausse et d'écart tels quels : la charge change d'une séance à l'autre parce que le programme l'écrit, et une cible « 5 répétitions en réserve et plus » n'a pas de borne haute. Les repères de 0.1.0 restent calculés et publiés ; trois mesures s'y ajoutent pour ces programmes, sous chacun des trois modèles de vérité du simulateur (A, celui de 0.1 ; B et C, ajoutés par `kalis_adapt` 0.2.0, `docs/VALIDATION.md` de ce paquet) :

| Mesure | Repère | Fondement |
|---|---|---|
| Écart absolu moyen entre l'effort affiché par le moteur et l'effort réel, sur les cibles atteignables (cible « 5 et plus » : seul un effort plus dur compte ; un exercice assisté à l'élastique, réglé par l'assistance, n'est pas compté) | ≤ 1 répétition | même cible que 0.1.0 |
| Hausses de plus de 10 % d'un mouvement principal d'une séance à la suivante **du même emplacement, à répétitions égales**, faites de plusieurs crans | 0 | R5-P3, R5-P22 |
| Ouvertures réussies (première tentative d'un test de maximum) | toutes | R3-P14 : la première barre se réussit un mauvais jour |
| Tentatives réussies ; meilleure performance du jour de l'échéance ÷ maximum réel du jour | comparées entre versions et politiques | — |

La campagne street (`CAMPAGNE_STREET.md` du rapport) donne ces mesures sur plusieurs graines et les compare à `kalis_adapt` en comportement 0.1, à un coach simple à la note d'effort et à l'oracle.

### 4.1 Saisons croisées (0.2.0, lot CX)

Chaque profil street sur sa saison entière (`saisons.json`, `SAISONS.md`), sous le couple `kalis_plan` 0.2 ×
`kalis_adapt` 0.2 et, pour la saison de référence, sous les moteurs 0.1. Mesures ajoutées aux mesures de
trajectoire :

| Mesure | Lecture | Fondement |
|---|---|---|
| Écart écrit ↔ servi | écart relatif moyen entre les répétitions (ou secondes) que le bloc écrit et celles que le moteur d'évolution sert, mouvements prioritaires, hors tests : plus il est petit, plus le programme écrit est réaliste pour l'athlète réel | LANCEMENTS CX (cohérence plan ↔ évolution) |
| Retirés sans raison | mouvement prioritaire présent dans un bloc et absent du suivant, sans exercice écarté par le résumé d'adaptation ni bloc de transition (une étape de figure compte pour sa figure) | « rien de défait d'un bloc à l'autre sans raison » |
| Violations de la saison réalisée | les critères de sécurité (§ 1) sur les blocs tels qu'ils ont été servis (un bloc arrêté par un changement de profil est réduit à ses semaines servies) | § 1 |
| Stabilité | écart type, entre graines, de la performance du jour de l'échéance et de la progression | LANCEMENTS CX |

Scénarios imposés (`SeasonScenario`) : séances manquées (une sur quatre, et dix jours d'arrêt), semaine de
maladie, douleur au coude ou à l'épaule (5/10 pendant trois semaines), parc seulement (trois semaines),
échéance avancée de deux semaines (apprise six semaines avant), deuxième échéance (six semaines après la
première). Tenue menton au-dessus de la barre (bras fléchis) : hors des tenues bras tendus de
`tendon_figures` depuis 0.2.0 (le catalogue la range avec les figures statiques de tirage).

## 5. Ce que les critères ne voient pas

L'ordre des exercices dans la séance, la cohérence d'une séance pour un humain, la pertinence d'un exercice pour un objectif, la qualité des consignes, le réalisme d'un enchaînement, la place d'une technique dans un bloc : c'est le rôle du panel de coachs virtuels (`PANEL.md`) et de la relecture du propriétaire.
