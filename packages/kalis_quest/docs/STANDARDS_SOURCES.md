# Standards de rang — méthode, sources, limites

Les tables que le moteur applique sont dans [`STANDARDS.md`](STANDARDS.md) (document généré). Cette page
dit d'où elles viennent, comment elles sont mises à l'échelle du sexe et du poids de corps, et ce qu'elles
ne savent pas. **Aucun professionnel diplômé n'a relu ces standards** (voir `CONTRAT.md`, § Registre de
validation).

## 1. Ce qu'un rang veut dire

| Rang | Repère | D'où vient le seuil |
| --- | --- | --- |
| Bronze | plus fort que 5 % des pratiquants | niveau « Beginner » de Strength Level / Running Level |
| Argent | 20 % | « Novice » |
| Or | 50 % | « Intermediate » |
| Platine | 80 % | « Advanced » |
| Diamant | 95 % | « Elite » |
| Élite | environ 98 % | extrapolé : `Diamant × √(Diamant / Platine)` |

Strength Level définit ses niveaux ainsi : Beginner « stronger than 5% of lifters », Novice 20 %,
Intermediate 50 %, Advanced 80 %, Elite 95 % (page « Powerlifting standards »). Running Level reprend la
même échelle pour les coureurs. Ce sont des centiles **parmi les pratiquants qui saisissent leurs
performances**, pas dans la population générale : les rangs sont donc exigeants. Deux recoupements le
montrent : la note « Excellent » du test de pompes ACSM/CSEP pour un homme de 20 à 29 ans (36 pompes et
plus) tombe juste sous l'Or (39) ; le temps médian d'un coureur de 5 km en course (31 min 28 s chez les
hommes, RunRepeat) est plus lent que le Bronze (31 min 29 s à 5 %).

**Rang Élite.** Si le logarithme de la performance suit une loi normale parmi les pratiquants, les
centiles 80 et 95 sont à 0,84 et 1,64 écart-type de la médiane ; un demi-pas de plus (2,05 écarts-types)
est le centile 98. D'où `Élite = Diamant × √(Diamant / Platine)`. Recoupement : pour un homme de 80 kg, le
seuil Élite vaut +87 kg en traction lestée, +128 kg en dips lestés et 228 kg au squat ; les records du
monde FinalRep de la catégorie −80 kg sont +106 kg, +161,25 kg et 270 kg. Le rang Élite reste donc sous
le niveau des records, ce qui est voulu.

## 2. Sources des seuils de référence

Relevées le 01/10/2026. Les pages ont été lues par un outil de synthèse et non recopiées à la main : les
valeurs sont à revérifier une à une avant toute publication hors de l'application.

| Mouvement | Source | Valeurs reprises |
| --- | --- | --- |
| Squat, soulevé de terre, développé couché, développé militaire | Strength Level, « Strength Standards », hommes de 80 kg et femmes de 60 kg — <https://strengthlevel.com/strength-standards/male/kg>, <https://strengthlevel.com/strength-standards/female/kg> | 1RM en kg aux cinq niveaux |
| Traction lestée, dips lestés, muscle-up lesté | Strength Level, pages « Pull Ups », « Dips », « Muscle Ups » (tables par poids de corps, charge ajoutée ; négatif = assistance) — <https://strengthlevel.com/strength-standards/pull-ups/kg>, <https://strengthlevel.com/strength-standards/dips/kg>, <https://strengthlevel.com/strength-standards/muscle-ups/kg> | lest du 1RM en kg aux cinq niveaux, hommes de 80 kg et femmes de 60 kg |
| Pompes, tractions, dips, muscle-ups (répétitions) | Strength Level, mêmes pages et <https://strengthlevel.com/strength-standards/push-ups/lb> (tables par sexe) | répétitions maximales aux cinq niveaux |
| 5 km | Running Level, « 5k Run Times By Age And Ability », 20 à 30 ans — <https://runninglevel.com/running-times/5k-times> | temps aux cinq niveaux |
| Figures (front lever, planche, handstand) | ordre des progressions : Steven Low, *Overcoming Gravity*, 2ᵉ éd., 2016 (tableaux de progression) ; tenue minimale de 2 s pour qu'une figure compte : règlement FIF Calisthenics Challenge 2026 — <https://www.fif.it/images/2026/regolamento-calisthenics-challenge.pdf> | **choix raisonné** : les durées par rang ne viennent d'aucune table publiée |
| Recoupements | FinalRep, records du monde de streetlifting (octobre 2025) — <https://final-rep.com/records/> ; RunRepeat, 35 millions de résultats de course — <https://runrepeat.com/how-do-you-masure-up-the-runners-percentile-calculator> ; normes de pompes CSEP reprises par l'ACSM (lues dans une source secondaire) | aucun seuil n'en dépend |

Tailles d'échantillon annoncées par Strength Level : 10,9 millions de résultats au développé couché,
7,0 millions au squat, 6,4 millions au soulevé de terre, 1,35 million en tractions, 517 000 en dips,
64 000 en muscle-ups (dont 2 995 de femmes : les seuils féminins du muscle-up sont fragiles).

Écartées : les tables de Lon Kilgore publiées par ExRx (non consultables par l'outil, et remplacées
depuis par des tables par âge) ; les formules de points de force athlétique (Wilks, DOTS, IPF GL), faites
pour comparer des compétiteurs entre catégories et non pour situer un pratiquant.

**Répétitions « moins d'une ».** Strength Level donne « < 1 » répétition au Bronze (et parfois à
l'Argent) pour les tractions, les dips et les muscle-ups. Règle retenue : le Bronze est la première
répétition ; quand l'Argent publié ne dépasse pas 1, il est mis à mi-chemin (arrondi au-dessus) entre 1
et l'Or. Sont dans ce cas : tractions des femmes (Argent 4), dips des femmes (5), muscle-ups des femmes
(3) et des hommes (4). C'est un choix raisonné.

**Squat du streetlifting.** `sl-squat-competition` reprend les seuils du back squat.

## 3. Poids de corps

À rang égal, une personne plus lourde soulève plus, mais moins que proportionnellement : la force croît
comme la section du muscle, donc comme la masse à la puissance 2/3 (Jaric, 2002 : exposant 0,67 pour une
force ; Lietzke, 1956 : 0,6748 sur les totaux d'haltérophilie). Les tables de Strength Level montrent
pourtant un exposant qui dépend du niveau : proche de 1,2 chez les débutants (les plus lourds y ont aussi
plus de masse maigre), et qui descend vers 2/3 chez les plus forts. Le moteur reprend ce que les données
montrent :

`seuil(poids) = seuil(référence) × (poids / référence)^b`, sur la **charge totale** (charge externe +
fraction du poids du corps portée, donnée par le catalogue), avec un exposant `b` par rang.

Ajustement (`tool/standards_fit.py` : régression log-log sur trois poids de corps par série) :

| Niveau | Développé couché, hommes | Développé couché, femmes | Traction lestée, hommes | Traction lestée, femmes | Dips lestés, hommes | Dips lestés, femmes | Commun |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Beginner | 1.34 | 1.33 | 1.08 | 1.09 | 1.20 | 1.26 | **1.21** |
| Novice | 1.15 | 1.00 | 0.94 | 0.98 | 1.06 | 1.08 | **1.04** |
| Intermediate | 1.00 | 0.83 | 0.87 | 0.88 | 0.95 | 0.94 | **0.92** |
| Advanced | 0.88 | 0.69 | 0.81 | 0.81 | 0.86 | 0.84 | **0.82** |
| Elite | 0.80 | 0.58 | 0.75 | 0.74 | 0.78 | 0.76 | **0.74** |

Exposants retenus : 1,21 ; 1,04 ; 0,92 ; 0,82 ; 0,74, et 0,67 (théorique) pour le rang Élite, extrapolé.
Avec eux, l'écart à la charge totale publiée est de 2,1 % en moyenne et de 9,2 % au plus sur les 60 cases
relevées. Le squat, le soulevé de terre et le développé militaire reçoivent les mêmes exposants sans
avoir été vérifiés un à un : hypothèse.

Pour les **répétitions au poids du corps**, même forme avec un exposant négatif (plus lourd, moins de
répétitions) :

| Niveau | Pompes, hommes | Pompes, femmes | Tractions, hommes | Tractions, femmes | Dips, hommes | Dips, femmes | Muscle-ups, hommes | Muscle-ups, femmes | Commun |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Intermediate | -0.31 | -0.37 | -0.46 | -0.41 | -0.10 | 0.00 | 0.31 | 0.43 | **-0.11** |
| Elite | -0.49 | -0.52 | -0.54 | -0.69 | -0.37 | -0.46 | -0.24 | -0.17 | **-0.43** |

Exposants retenus : 0 (Bronze, Argent) ; −0,11 (Or) ; −0,27 (Platine, interpolé) ; −0,43 (Diamant) ;
−0,50 (Élite, extrapolé). Les séries sont dispersées (les muscle-ups vont à contresens au niveau
Intermediate) : l'ajustement commun est grossier, et c'est dit.

Le poids de corps est borné à [40 ; 140] kg. Le poids pris en compte est celui de la séance de la
performance, sinon celui du profil, sinon 70 kg (référence de `kalis_adapt`). Les seuils du 5 km et des
figures ne dépendent pas du poids de corps : aucune table publiée ne le permet.

**Sexe non précisé** : moyenne géométrique des deux tables au même poids de corps (choix raisonné).

## 4. De la séance à la performance

- **Charges** : 1RM impliqué par une série de 10 répétitions au plus, notée 8 flammes ou plus — la règle
  des records de `kalis_adapt` (`1RM = charge totale × (1 + (répétitions + RIR − 1) / k)`, k = 30, ou 38
  pour les polyarticulaires du bas du corps).
- **Répétitions** : meilleure série.
- **Figures** : meilleure tenue de chaque progression ; une progression plus dure tenue 2 s vaut les
  échelons plus bas.
- **5 km** : toute série de course de 1,5 à 45 km, ramenée à 5 km par la formule de Riegel
  (`T₂ = T₁ × (D₂ / D₁)^1,06` ; Riegel, 1981).

**Points de rang** : 1 = Bronze … 6 = Élite ; la partie décimale est l'avancement, en logarithme, vers
le seuil suivant ; sous le Bronze, la part du seuil atteinte ; plafond à 7.

## 5. Limites connues

- Standards tirés de sites où les pratiquants saisissent eux-mêmes leurs performances : centiles « parmi
  ceux qui s'entraînent et se mesurent », charges non contrôlées, amplitude inconnue.
- Pas de standard par âge : un senior est jugé sur l'échelle des 20-30 ans (le 5 km surtout).
- Figures : mêmes échelons pour tous, sans sexe, poids ni taille, alors que les leviers pèsent beaucoup.
- Un seul exposant par rang pour tous les mouvements chargés.
- Les variantes (prises, pauses, élastiques) ne font pas avancer le rang du mouvement de référence :
  elles l'affichent seulement.

## 6. Références

- Jaric S. (2002). Muscle strength testing: use of normalisation for body size. *Sports Medicine*,
  32(10), 615-631. doi:10.2165/00007256-200232100-00002.
- Lietzke M. H. (1956). Relation between weight-lifting totals and body weight. *Science*, 124(3220),
  486-487 (volume et pages non revérifiés).
- Vanderburgh P. M., Batterham A. M. (1999). Validation of the Wilks powerlifting formula. *Medicine &
  Science in Sports & Exercise*, 31(12), 1869-1875.
- Riegel P. S. (1981). Athletic records and human endurance. *American Scientist*, 69(3), 285-290.
- Low S. (2016). *Overcoming Gravity: A Systematic Approach to Gymnastics and Bodyweight Strength*,
  2ᵉ éd., Battle Ground Creative.
- Strength Level, <https://strengthlevel.com/strength-standards> ; Running Level,
  <https://runninglevel.com> ; FinalRep, <https://final-rep.com/records/> ; RunRepeat,
  <https://runrepeat.com>.
