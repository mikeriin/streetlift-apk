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
