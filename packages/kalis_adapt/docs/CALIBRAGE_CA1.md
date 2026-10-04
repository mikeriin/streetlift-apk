# Calibrage de `kalis_adapt` 0.2.0 (lot CA1)

Journal des boucles de calibrage du mode coach : ce que le panel de `kalis_bench` (quatre écoles, relecteurs
Opus, `docs/PANEL.md`) a noté sur les trajectoires simulées des 17 profils street, ce que chaque boucle a
changé dans le moteur, et les sources consultées pour le décider. Les notes portent sur le fichier remis aux
relecteurs : le programme de départ (export concis de `kalis_plan` 0.2.0) suivi de la trajectoire simulée
(athlète simulé du modèle B). Les grilles, les profils et les modèles de vérité ne sont jamais modifiés pour
gagner une note.

## Dérive du panel (avant la première boucle)

Ancres publiques `p08_a` et `p14_c`, un appel par école : variante (a) notée 1 / 1 / 1 / 1, variante (c) notée
8 (force) / 8 (calisthénie) / 9 (hypertrophie) / 8 (santé). Règle : (a) ≤ 2 et (c) ≥ 8 → pas de dérive.
Empreintes des cinq grilles identiques à `docs/PANEL.md`.

## Passe 0 (complète, 68 couples) — avant calibrage

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| street_01 | 8 | 8 | 8 | 8 |
| street_02 | 9 | 9 | 9 | 9 |
| street_03 | 6 | 6 | 6 | 7 |
| street_04 | 8 | 8 | 9 | 8 |
| street_05 | 9 | 7 | 7 | 8 |
| street_06 | 8 | 8 | 8 | 7,5 |
| street_07 | 9 | 9 | 9 | 9 |
| street_08 | 9 | 8 | 9 | 8 |
| street_09 | 9 | 8 | 7 | 8 |
| street_10 | 8 | 7,5 | 8 | 9 |
| street_11 | 9 | 8 | 8 | 8 |
| street_12 | 9 | 9 | 9 | 9 |
| street_13 | 9 | 8 | 9 | 8 |
| street_14 | 9 | 9 | 9 | 9 |
| street_15 | 8 | 8 | 7,5 | 9 |
| street_16 | 8 | 9 | 9 | 9 |
| street_17 | 7 | 8 | 7 | 8 |

Couples à 9 ou plus : 29 sur 68 ; minimum 6 ; moyenne 8,23.

Corrections nécessaires relevées (toutes lues), par famille :

1. **Assistance jamais réglée** (street_01, street_03 ; quatre écoles) : la traction à l'élastique reste à 8–11
   répétitions en réserve réelles pendant douze semaines. → moteur (boucle 1 : réglage de l'assistance).
2. **Chiffres écrits sur un progrès supposé** (street_05, 06, 08, 10, 11) : les tableaux du programme partent
   d'un repère attendu, pas du test. → le moteur doit servir d'après le test réel et le montrer (boucle 1) ; le
   texte du programme relève de `kalis_plan`.
3. **Prescription infaisable ou variante trop facile** (street_03 : pompe classique 3–5 à 2 en réserve pour un
   maximum de 3 ; pompe sur les genoux à 7–15 en réserve). → moteur : séries fractionnées (boucle 1) ; l'échelle
   de variantes relève de `kalis_plan`.
4. **Maintiens bras tendus** (street_04 : +66 % de temps d'appui renversé en une semaine, douleur au poignet
   persistante et volume de dips qui continue de monter ; street_05, street_10 : tenues à 83–100 % du maximum
   mesuré). → moteur (boucle 1 : part du maximum, hausse du temps total, gel du volume sur zone douloureuse).
5. **Exercice partiel surchargé** (street_09 : 98 → 105 % sans calibrage, coude à antécédent). → moteur
   (boucle 1 : entrée graduée, plafond sur zone à antécédent).
6. **Séries allégées trop légères, trop peu de lourd** (street_09, street_16). → moteur (boucle 1 : séries
   allégées pilotées) ; la part de séries à 85 % et plus relève du programme.
7. **Structure du programme** (street_13 : pas d'excentrique ; street_15 : aucune série près du maximum ;
   street_17 : traction lundi puis mardi, version courte de 15 min ; street_06 : rest-pause sur les mouvements
   du test, volume de poussée ; street_08 : trois jours de poussée de suite ; street_10 : pas de surcharge de
   levier) : hors de portée du moteur d'évolution (structure écrite par `kalis_plan`).

Constat de mise au point (séries exportées, `series/<profil>.json`) : l'estimation dérivait vers le haut quand
toutes les notes étaient des bornes (loi normale tronquée appliquée série après série), puis s'effondrait
quand l'athlète, à qui le moteur annonçait « 5 en réserve et plus », arrêtait ses séries avant la cible.

## Boucle 1 — sources consultées

Recherche ciblée (deux sous-agents Opus, recherche web ; « vérifié » : notice ou résumé lu en ligne pendant le
lot ; les autres références sont à contrôler avant toute citation hors de ce journal).

**Notes d'effort loin de l'échec, bornes.**
- Halperin et al. 2022, Sports Med 52:377–390, doi:10.1007/s40279-021-01559-x (vérifié) : sous-estimation
  moyenne de 0,95 répétition ; précision meilleure près de l'échec ; erreur plus grande au-delà de 12
  répétitions.
- Steele et al. 2017, PeerJ 5:e4105, doi:10.7717/peerj.4105 (vérifié) : erreur de mesure de 2,6 à 3,4
  répétitions ; débutants : 4 à 5 répétitions de sous-estimation.
- Zourdos et al. 2021, J Strength Cond Res 35:S158–S165 : notes plus justes à 0–1 en réserve qu'à 3 et plus.
- Aucune étude ne valide une note « 4 en réserve ou plus » : à lire comme une borne peu informative.
- Mesures censurées : Tobin 1958 (Econometrica 26:24–36) ; Amemiya 1984 (J Econom 24:3–61) ; Allik et al.
  2016 (IEEE Trans Control Syst Technol 24:365–371, filtre de Kalman Tobit) ; Simon et Simon 2010 (Int J Syst
  Sci 41:159–171). Biais connus : traiter une borne comme une mesure sous-estime ; appliquer la troncature à
  répétition à des bornes corrélées compte l'information deux fois et pousse la moyenne au-delà de la borne.
  → **Décision** : en mode coach, une borne tenue n'apprend rien ; une borne franchie ramène l'estimation vers
  elle (`CapacityFilter.hinge`).

**Séries allégées.** Rodriguez et al. 2021, Strength Cond J 43(5):65–76 (vérifié) : aucun pourcentage validé
par un essai. Tables charge–répétitions : 2 à 3 % du 1RM par répétition près du maximum ; une baisse de 10 %
ajoute 3 à 4 répétitions en réserve. Androulakis-Korakakis et al. 2021, Front Sports Act Living 3:713655
(vérifié) : consensus d'experts, 3 à 6 séries de 1 à 5 répétitions par semaine à plus de 80 %, séries allégées
après un simple lourd. Peterson et al. 2004, J Strength Cond Res 18:377–382 (vérifié) : effet maximal vers
85 % du 1RM chez l'athlète. → **Décision** : choix raisonné, voir CONTRAT § 11.

**Répétitions maximales au poids du corps.** Aucune étude sur la règle « maximum moins 2 » ni sur la vitesse de
progression hebdomadaire. Sánchez-Moreno et al. 2020, J Strength Cond Res 34:911–917 (tractions : s'arrêter
tôt, moins de volume, gains semblables) ; Campos et al. 2002, Eur J Appl Physiol 88:50–60 (spécificité de la
zone de répétitions, vérifié) ; Robinson et al. 2024, Sports Med 54:2209–2231 (la force dépend peu de la
proximité de l'échec). Repos : de Salles et al. 2009, Sports Med 39:765–777 (vérifié) : 3 à 5 min préservent
les répétitions ; aucune donnée propre au poids du corps ni aux plus de 50 ans.

**Assistance à l'élastique.** McMaster et Cronin 2010, J Strength Cond Res 24:2056–2064 (vérifié) : tension
non linéaire, 8 à 19 % d'écart entre élastiques de même couleur — pas de table en kg, chaque élastique
s'étalonne. Aucune étude sur le critère de réduction de l'assistance ; règle transposée (ACSM 2009, Med Sci
Sports Exerc 41:687–708) : 1 à 2 répétitions au-dessus de la cible deux séances de suite → charge +2 à 10 %.
→ **Décision** : le moteur conseille un cran d'assistance de moins quand la série repère montre nettement plus
de réserve que visé ; choix raisonné.

**Maintiens et tendons.** Bohm et al. 2015, Sports Med Open 1:7 ; Oranchuk et al. 2019, Scand J Med Sci
Sports 29:484–503 (vérifié) ; Kubo et al. 2012, Eur J Appl Physiol 112:2679–2691 (vérifié) : raideur du
tendon inchangée avant le troisième mois, perdue dès un mois d'arrêt. Aucune étude sur la part du maintien
maximal ni sur la hausse du temps sous tension des figures bras tendus ; Buist et al. 2008 (Am J Sports Med
36:33–39) : la règle des 10 % ne protège pas. → **Décision** : choix raisonnés (référentiel R4-F2, R5-P22).

**Douleur.** Silbernagel et al. 2007, Am J Sports Med 35:897–906 (vérifié) ; Smith et al. 2017, Br J Sports
Med 51:1679–1687 (vérifié) : douleur tolérée jusqu'à 5/10 si elle est revenue au niveau habituel le lendemain
et n'augmente pas d'une semaine à l'autre. Aucune étude ne chiffre la conduite à tenir quand une douleur de
3–4/10 persiste deux semaines : gel de la progression et baisse de 30 à 50 % sont de la pratique de terrain.

**Amplitude partielle surchargée.** Wolf et al. 2023, Int J Strength Cond 3(1) ; Pallarés et al. 2021, Scand J
Med Sci Sports 31:1866–1881 : gains spécifiques à l'amplitude ; aucune donnée sur la charge de départ ni sur
le risque pour le coude. → **Décision** : choix raisonné (R5-P22 : exercice nouveau gradué).

## Boucle 1 — ce qui a changé

Moteur (détail et paramètres : CONTRAT § 11) :

- bornes « charnière » (`CapacityFilter.hinge`) ; seul ce que l'athlète fait mesure (échec, répétitions
  manquantes, série ouverte arrêtée avant le haut de sa plage, test) ; le journal des blocs précédents se lit
  en mode coach (`SlotSpec.coachRead`) ;
- séries repères : aussi sur les plages (au-delà du haut de la plage), sur la série de tête (hors
  réalisation), sur les maintiens (jusqu'à la durée écrite) ;
- répétitions au poids du corps recalées sur le maximum mesuré (part du test, jamais plus que le maximum
  moins la réserve ; +1 répétition par séance au plus au-dessus de l'écrit) ; effort attendu affiché dans les
  deux sens ; plus de bonus de calibrage ; séries fractionnées quand la plage est hors de portée ;
- assistance : un cran de moins sur série repère, un cran de plus sur faits ;
- maintiens à 75 % du maximum du jour au plus, temps total sous tension borné comme la durée d'une tenue ;
- zone douloureuse : pas plus de séries que la dernière séance de l'emplacement ;
- séries allégées rapprochées de la série de tête (baisse d'au moins 5 %) ; pas de hausse après des
  répétitions écrites non atteintes ; exercice calé sur un autre mouvement : entrée à 60 %, paliers de 10 %,
  plafond à 100 % sur zone à antécédent ; départs au chrono non arrêtés sur une chute dite facile.

Simulateur (ajouts, sans toucher aux modèles de vérité existants) : crans d'assistance des exercices assistés
(programmes au contrat 0.4.0 seulement), auparavant « non simulés ».

Banc : colonne « Servi par le moteur » dans les trajectoires ; `series/<profil>.json` (mise au point).

Mesures (campagne rapide, 2 graines, moyenne des 17 profils) :

| Modèle | Écart d'effort avant → après | Échéance / maximum du jour avant → après | Échecs non voulus après |
| --- | --- | --- | --- |
| A | 0,95 → 1,01 | 96,4 % → 96,3 % | 0,10 % |
| B | 1,20 → 1,19 | 95,2 % → 95,5 % | 0,06 % |
| C | 1,79 → 1,85 | 95,6 % → 95,3 % | 0,39 % |

(« Avant » : version de la passe 0, dont l'estimation dérivait vers le haut ; les moyennes sont proches, mais
l'estimation ne s'effondre plus en cours de bloc et ne change plus à chaque nouveau bloc.)

## Passe 1 (complète : tous les exports ont changé)

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| street_01 | 8 | 9 | 8 | 8 |
| street_02 | 9 | 9 | 9 | 9 |
| street_03 | 6,5 | 7 | 6,5 | 7 |
| street_04 | 9 | 9 | 9 | 9 |
| street_05 | 8 | 8 | 8 | 8 |
| street_06 | 9 | 9 | 8 | 9 |
| street_07 | 9 | 9 | 9 | 9 |
| street_08 | 8 | 7 | 7,5 | 9 |
| street_09 | 8 | 6,5 | 8 | 9 |
| street_10 | 8 | 7 | 6 | 8 |
| street_11 | 7 | 7 | 8 | 8 |
| street_12 | 8 | 9 | 9 | 9 |
| street_13 | 8 | 8 | 8 | 8 |
| street_14 | 9 | 7 | 8 | 9 |
| street_15 | 8 | 8 | 8 | 9 |
| street_16 | 9 | 9 | 9 | 9 |
| street_17 | 9 | 7 | 8 | 8 |

Couples à 9 ou plus : 29 sur 68 ; minimum 6 ; moyenne 8,21 → **pas de gain** (passe 0 : 29, minimum 6).
Treize couples montent d'au moins un point (street_04 passe à 9 partout, street_06 à 9 sur trois écoles),
quinze baissent ; l'incertitude du panel est d'un point (docs/PANEL.md).

Lecture des corrections nécessaires de la passe 1 : presque toutes portent sur le **programme écrit**
(`kalis_plan`), que ce lot ne modifie pas — tableaux écrits sur un repère attendu (street_05, 06, 08, 10, 11,
14, 15), seuil d'ouverture d'une étape de figure (street_05, street_10), prescription de pompe hors de portée
et absence d'échelle de poussée (street_03), volume et répartition dans la semaine (street_08, street_10,
street_14, street_17), bloc de réalisation non spécifique (street_11, street_15, street_17), séries allégées
écrites à −15 % (street_09, street_12), charge « à calibrer » (street_11), négatives à dose fixe (street_01).
Les relecteurs relèvent que le moteur recale (« la règle de recalcul compense », « recalé par le moteur »),
mais notent le texte du programme et l'absence de progrès de l'athlète simulé. Corrections encore à la
portée du moteur : haut de plage servi au-dessus du maximum moins la réserve (street_13), maintien servi très
loin sous le maximum mesuré (street_10).

## Boucle 2 — sources consultées

Recherche ciblée (un sous-agent Opus, recherche web).

- **Répétitions d'une série à l'autre.** Aucune étude au poids du corps à réserve fixée. Séries à l'échec avec
  charges : les répétitions de la première série ne sont jamais tenues sur les suivantes, quel que soit le
  repos (Willardson et Burkett 2006, J Strength Cond Res 20:400–403 et 20:396–399, résumés vérifiés) ; 71
  répétitions par séance avec 2 min de repos contre 84 avec 5 min (Senna et al. 2009, J Sports Sci Med
  8:197–202, vérifié). Ordre de grandeur déduit, non validé : −1 répétition en série 2, −1 à −2 en série 3.
  → **Décision** : le haut d'une plage servie garde la réserve du bloc sur chaque série, fatigue prévue
  comprise (`maximum du jour − réserve`) ; choix raisonné.
- **Maintiens.** Oranchuk et al. 2019 (Scand J Med Sci Sports 29:484–503, vérifié) : gains de force à toute
  intensité, adaptation du tendon à 70 % de la force maximale et plus. Aucune étude ne fixe de seuil en part
  de la durée maximale de maintien. → **Décision** : choix raisonné (R4-F2) — une durée écrite sous 40 % du
  maximum mesuré monte vers 50 %, par les paliers de hausse des tendons.
- **Fréquence et volume.** Grgic et al. 2018 (Sports Med 48:1207–1220) ; Ralston et al. 2018 (Sports Med Open
  4:36) : à volume égal la fréquence compte peu. Aucune étude sur la pratique distribuée des tractions ni sur
  le passage de 6 à 9 tractions.
