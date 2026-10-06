# Contrat de kalis_adapt 0.2.3

Moteur dynamique de Kalis Track (D5) : il suit l'utilisateur et adapte son programme séance après séance.
Dart pur, sans Flutter, sans stockage, sans horloge ; tout ce qu'il rend est une valeur du contrat de
`kalis_core` (`docs/TYPES.md`) et des codes de raison, jamais une phrase.

Ce document fixe ce que le moteur garantit (§ 2 et 7), le modèle qu'il estime (§ 3), comment il décide
(§ 4), d'où vient chaque nombre (§ 5 et 6), ce qu'il ne sait pas faire (§ 8) et ce qui a été vérifié, par
qui (§ 9). Les mesures citées viennent de `docs/MESURES.md` (relevé du simulateur) et sont lues dans
`docs/VALIDATION.md`. **Le contenu sportif n'a pas été relu par un professionnel diplômé** (§ 9).

Les § 1 à 10 décrivent le moteur de 0.1.0, toujours servi tel quel aux blocs sans champ du contrat 0.4.0
de `kalis_core` (programme importé du propriétaire compris). Le § 11 décrit le **mode coach** de 0.2.0
(blocs au contrat 0.4.0), son calibrage au panel (`docs/CALIBRAGE_CA1.md`, puis `docs/CALIBRAGE_CA2.md`) et ses limites.

## 1. Vocabulaire

| Terme | Sens |
| --- | --- |
| RIR | Répétitions en réserve à la fin d'une série. Les flammes le disent : 10 flammes = échec (RIR 0), 9 = RIR 1, puis un demi-point par flamme, 1 flamme = « 5 et plus » (`Flames`, kalis_core). |
| Capacité | Ce qu'un exercice permet aujourd'hui, frais : pour un exercice chargé, la charge **totale** (charge externe + fraction du poids du corps) soulevable un nombre donné de fois ; pour un exercice au poids du corps, le maximum de répétitions ; pour une tenue, le maximum de secondes. |
| Capacité opérationnelle | La capacité là où l'exercice est travaillé : la charge soulevable `n_ref` fois, `n_ref` = milieu de la plage de la séance + RIR visé (le pivot suit la plage, § 3.2). C'est elle que le filtre suit ; le 1RM s'en déduit. |
| Effet de jour | Écart de la capacité d'un jour à sa tendance (sommeil, fatigue, forme) ; remis à zéro à chaque séance. |
| Calibrage | Les trois premières séances au plus d'un exercice dont la capacité est encore incertaine (§ 4.2). |
| Série ouverte | Série dont la cible est une plage, faite « au ressenti » jusqu'aux flammes visées : série repère (§ 4.6), séance notée « 5 et plus » (§ 4.3), test « maximum ». |
| Cible atteignable | Il existe une charge de la grille de l'utilisateur (ou un nombre de répétitions) qui met le RIR visé dans la plage du bloc. Sinon l'exercice est trop facile ou trop dur pour cette plage avec ce matériel (§ 8). |

## 2. API

`KalisAdapt implements AdaptEngine` (kalis_core 0.2.0). Trois méthodes, toutes fonctions pures de leurs
arguments : même requête, même résultat **à l'octet près** (JSON), quelle que soit l'instance ou l'ordre
des appels.

| Méthode | Entrée | Sortie | Rôle |
| --- | --- | --- | --- |
| `prescribeSession(catalog, SessionRequest)` | profil, bloc, journal, « aujourd'hui », séance visée, bilan santé et lieu du jour éventuels | `SessionPlan` | Charges, répétitions et flammes de la séance du jour ; ajustements (bilan, douleur, lieu, temps). |
| `adviseNextSet(catalog, AdviceRequest)` | la même entrée, la séance prescrite, les séries déjà faites, l'emplacement | `IntraSessionAdvice` | Cible de la série suivante. |
| `review(catalog, AdaptInput)` | profil, bloc, journal, « aujourd'hui », état et décisions passées | `AdaptReview` | Résumé d'adaptation (entrée de `PlanEngine.nextBlock`), propositions, records, journal du moteur, état. |

En plus de l'interface : `estimates` (capacités estimées), `applyProposal` (bloc après une proposition),
`AdaptParams` (tous les paramètres chiffrés), `CapacityFilter` et les briques du modèle (inspecteur du mode
dev, simulateur).

**Le journal est rejoué.** Le moteur ne garde rien d'un appel à l'autre : l'état du modèle est recalculé
depuis tout le journal. Une instance retient le dernier rejeu et le prolonge quand le catalogue, le profil,
le bloc et le début du journal sont **les mêmes objets** ; ce cache ne change aucun résultat, y compris
quand le journal est donné en deux fois (testé sur les journaux aléatoires, § 7), et l'ordre des séances
ajoutées est contrôlé comme celui d'un journal neuf. L'`état` opaque rendu par `review` ne sert qu'à numéroter le journal du
moteur et à l'inspecteur ; le perdre ne change aucune décision.

**Ce qui est ignoré du journal** : les séances « reprise » (D4.9), les séries écartées (`excluded`), les
échauffements, les séries sans la mesure de leur exercice, les séries d'un exercice chargé dont la charge
totale est nulle ou négative, les exercices que le moteur ne modélise pas (cardio, conditionnement,
mobilité, récupération, distance, calories : leur prescription est rendue telle que le bloc la donne).

**Séries enchaînées.** Les séries d'un journal sont lues dans l'ordre de réalisation. Quand deux
exercices alternent (superset, tours : A1, B1, A2, B2), chaque exercice garde un seul déroulement par
séance — même effet de jour, même fatigue de séries, même compte d'échecs — repéré par l'emplacement,
l'exercice et son rang (`slotId`, `exerciseId`, `exerciseOrder`). Le conseil d'un emplacement tient compte
de ses séries même si d'autres exercices ont été faits depuis.

**Conseil sans bilan du jour.** `AdviceRequest.healthCheck` (kalis_core 0.2.0) redonne au conseil le bilan
donné à `prescribeSession`. S'il manque, le conseil relit les verrous dans la séance prescrite : le palier
du bilan (raison `adapt.load_held` de cause `health` ou `health_strong` au niveau de la séance), la forme
du jour (`adapt.readiness`) et les zones douloureuses retenues (`adapt.pain_reported` des exercices). Les
garde-fous tiennent dans les deux cas (testé, § 7) ; les cibles peuvent différer d'une demi-répétition.

**Bilan santé.** Seules les réponses données comptent. Une réponse absente n'ajoute aucun terme : un bilan
sans réponse équivaut à l'absence de bilan (testé, § 7). Une liste `pains` absente veut dire « question non
posée » ; une liste vide, « aucune douleur » (les zones suivies sont alors levées).

**Erreurs.** `ArgumentError` si le profil est invalide, si le journal n'est pas chronologique, si la séance
ou l'emplacement demandé n'existe pas dans le bloc. Aucune autre exception sur 10 240 journaux aléatoires
(§ 7).

**Plateforme.** Les quatre opérations, la racine carrée, et l'exponentielle et le logarithme de
`kalis_plan` (`stableExp`, `stableLn`) : même résultat attendu sur toute machine native ; vérifié sur la
seule machine de contrôle (x64). Le Web n'est pas pris en charge.

**Lignes de commande** (depuis la racine du paquet) : `dart run kalis_adapt:simulate --athlete <json|nom>
--weeks 24 --seed <n> [--boucle] [--journal <fichier>]` ; `dart run kalis_adapt:replay --journal <json>
[--cle <clé>] [--semaine <n> --jour <n>]` ; `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (la
campagne de `docs/`).

## 3. Modèle individuel

### 3.1 Courbe répétitions ↔ charge

Part du 1RM soulevable `n` fois : `p(n) = 1 / (1 + (n − 1) / k)` (forme d'Epley généralisée, `p(1) = 1`).
`k = 30` a priori (5 répétitions à 88 %, 10 à 77 %, 15 à 68 %, 20 à 61 %), `k = 38` pour les
polyarticulaires du bas du corps, qui permettent plus de répétitions à un même pourcentage (Nuzzo et al.
2024). `k` varie d'une personne à l'autre : `ln k` a un écart-type a priori de 0,30 et se règle sur les
séries qui le mesurent (§ 3.3).

### 3.2 État et dynamique

Un filtre de Kalman par exercice (Kalman 1960 ; modèle à tendance locale amortie, Harvey 1989, Durbin et
Koopman 2012), état `[c, v, κ, d]` :

- `c` : logarithme de la capacité opérationnelle ;
- `v` : pente de `c` par semaine ;
- `κ = ln k` (exercices chargés) ;
- `d` : effet de jour.

Le 1RM d'un exercice chargé s'en déduit : `ln 1RM = c + ln(1 + (n_ref − 1) / k)`. Paramétrer par la
capacité opérationnelle plutôt que par le 1RM découple `c` de `k` : une erreur sur la forme de la courbe ne
déplace pas la capacité à l'endroit où l'exercice est travaillé.

Entre deux séances distantes de `Δ` semaines, avec `φ = 0,97^Δ` :

```
c ← c + v · (1 − φ) / (−ln 0,97)        v ← φ · v        κ ← κ        d ← 0
Var(c) += q_c² · Δ + q_v² · Δ³ / 3      Cov(c, v) += q_v² · Δ² / 2      Var(v) += q_v² · Δ
```

`q_c = 0,004` et `q_v = 0,0015` par racine de semaine. À l'ouverture d'une séance, `d` repart d'une loi
normale de moyenne `s` (décalage prévu, § 3.5 et 3.6) et d'écart-type 3,5 %, sans corrélation avec le
reste ; à la clôture il est oublié. La moitié de la variance de l'effet de jour est commune aux exercices
d'une même séance : le résidu des exercices déjà commencés renseigne ceux qui s'ouvrent ensuite (moyenne
pondérée par la précision).

**Le pivot suit la plage.** Quand la plage de la séance s'est nettement éloignée du pivot (nouveau bloc,
test, autre emplacement : plus de 2,5 répétitions et plus de 30 % du pivot), le pivot est déplacé avant la
séance : `c' = c + g(n_ref) − g(n_ref')`, avec
`g(n) = ln(1 + (n − 1) / k)`, et la covariance suit la transformation linéaire `c' = c + t·κ`. Le 1RM et
l'incertitude de toute charge prévue sont conservés exactement (testé) ; l'incertitude sur `k` se reporte
sur le nouveau niveau, qui s'apprend ensuite sans dépendre de la forme de la courbe. Mesure (écriture de
référence, 30 séances à 15 répétitions puis passage à 3) : l'écart-type de la charge prévue à 3
répétitions, 7,8 % au changement, restait à 7,9 % après 30 séances avec un pivot fixe — au-dessus du seuil
de calibrage, donc RIR relevé sans fin ; avec le pivot déplacé : 3,4 % après une séance, 2,2 % après
trois, 1,5 % après trente.

### 3.3 Observation d'une série

Une série de `r` répétitions à la charge totale `L`, finie à `RIR` répétitions de l'échec après la perte
relative `f` due aux séries précédentes (§ 3.4), dit que `n = (r + RIR) / (1 − f)` répétitions étaient
possibles, frais, à cette charge :

```
ln L = c + d − ln(1 + (n − 1) / k) + ln(1 + (n_ref − 1) / k) + bruit
```

Filtre de Kalman étendu (jacobien `[1, 0, ∂/∂κ, 1]`), covariance mise à jour sous la forme de Joseph
(valable pour tout gain). Le bruit sur `n` est ramené en bruit sur `ln L` par la pente de la courbe.

| Série | Ce qu'elle dit | Bruit sur `n` (répétitions) |
| --- | --- | --- |
| Notée de 2 à 9 flammes | `n = r + 1,2 × RIR` (le RIR dit est en moyenne sous le RIR réel) | `(0,6 + 0,35 × RIR) × (1 + 0,05 × (n − 12)⁺)`, RIR = le plus grand du RIR dit et du RIR prévu |
| Menée à l'échec (10 flammes, ou cible manquée sans note) | `n = r + 0,5` | 0,5 |
| Ratée sans une répétition | `n ≤ 1` (borne haute) | 0,5 |
| 1 flamme (« 5 et plus ») | `n ≥ r + 6` (borne basse) | 2,35 et plus |
| Sans note, cible atteinte | `n ≥ r` (borne basse) | 0,5 |
| Toute série terminée | `n ≥ r` (borne basse), en plus de sa note | 0,5 |

- **Bornes.** Une borne n'est pas une mesure : la mise à jour prend les moments de la loi normale tronquée
  (Tallis 1961) — rien ne bouge quand la borne est déjà largement satisfaite. « Pas de note » n'est donc
  jamais lu comme une valeur (D5.3).
- **Écarts aberrants.** Pour une série notée de 2 à 9 flammes, au-delà de 2 écarts-types d'innovation, le
  bruit est gonflé pour ramener l'innovation au seuil : plus la note est loin de ce qui était prévu, moins
  elle pèse. Pour une série manquée (échec, zéro répétition), le seuil est de 3 écarts-types et la série
  n'apprend pas `k` : une saisie douteuse — zéro répétition à 20 kg quand le 1RM estimé est de 100 kg — ne
  fait plus chuter l'estimation (mesure, § 6), un échec réel garde tout son poids. Les bornes basses ne
  sont pas écrêtées : une série faite est un fait (§ 8).
- **`k` est tenu pour fixe hors des séries qui le mesurent.** Seules le déplacent les séries fraîches
  (`f < 0,02`) et précises — menées à l'échec, ou séries de test et séries ouvertes notées à 2 répétitions
  de l'échec au plus. Pour toute autre série, `k` quitte le jacobien et son incertitude s'ajoute au bruit
  (`(∂h/∂κ)² · Var(κ)`), nulle au pivot : le niveau ne bouge que dans le sens de ce que la série montre. Ce
  n'est pas un filtre de Schmidt-Kalman (les covariances croisées ne sont pas exploitées) : une série loin
  du pivot informe donc moins qu'elle ne pourrait. Apprendre `k` sur des notes bruitées le fait dériver
  (erreur sur les variables) : mesuré sur le prototype, § 6.
- **Exercices au poids du corps et tenues.** La capacité s'observe directement : `ln(capacité) = c + d`,
  avec `capacité = (r + 1,2 × RIR) / (1 − f)` pour des répétitions, `r / (1 − 0,1 × 1,2 × RIR) / (1 − f)` pour
  une tenue (une répétition en réserve y vaut 10 % de la tenue maximale).

### 3.4 Fatigue dans la séance

Une série finie à `RIR` répétitions de l'échec, suivie de `t` secondes de repos (30 au moins), laisse une
perte relative de répétitions possibles `0,9 · e^(−t / 150) · e^(−RIR / 1,5)` ; il en reste la moitié deux
séries plus tard ; le cumul est plafonné à 0,8. Le RIR utilisé est celui que le modèle estime après la
série, non la note seule. L'incertitude sur cette perte (50 %) entre dans la marge de prudence (§ 4.1).

### 3.5 Forme et fatigue entre les séances

Modèle impulsion-réponse (Banister ; Calvert et al. 1976, Busso 2003), à trois composantes : fatigue
aiguë par groupe musculaire (constante de temps 1,2 jour), fatigue accumulée globale (7 jours), forme
(42 jours, rendue dans le résumé). Chaque série ajoute une impulsion `w × fatigue de l'exercice / 3`
(`fatigue.locale` et `fatigue.systemique` du catalogue, de 1 à 5), avec `w = max(0,3 ; 1 − RIR / 8)`,
plus 0,25 pour un échec.

Effet sur la capacité d'un exercice : `−g × (0,004 × fatigue aiguë de ses muscles + 0,0006 × fatigue
accumulée)`, **compté en écart au niveau habituel de cet exercice** (moyenne glissante, poids 0,2) : la
fatigue ordinaire d'une semaine type est déjà dans la capacité estimée. Le gain individuel `g` (1 a
priori, écart-type 1) est appris par un filtre scalaire sur les résidus d'effet de jour.

### 3.6 Forme du jour

La forme du jour réunit trois sources, toutes en décalage de `ln` capacité :

1. la fatigue modélisée (§ 3.5) ;
2. le bilan santé : `−1,5 %` par point de « Comment tu te sens ? » sous 4 ; les réponses de détail
   (sommeil, énergie, humeur, courbatures, stress, motivation, alimentation, hydratation) ajoutent `−1 %`
   par réponse à 1 ou 2, `−1 %` par heure de sommeil sous 6 (3 au plus), pour moitié quand la réponse
   générale est donnée, en entier sinon ; plancher `−8 %` ;
3. les résidus de performance de la séance en cours (part commune de l'effet de jour, § 3.2).

`readiness = 1 + décalage / 0,10`, bornée à [0 ; 1].

### 3.7 Notes peu informatives

Fenêtre glissante des 40 dernières séries notées face à une cible : une série « confirme » quand elle
reprend exactement les flammes pré-remplies et les répétitions prévues. Jusqu'à 60 % de confirmations
(et tant qu'il y a moins de 12 séries), les notes pèsent plein ; au-delà, le poids d'une note confirmée
décroît linéairement jusqu'à 0,1 (son bruit est divisé par la racine du poids). La borne « série
terminée » garde tout son poids : c'est la performance réelle qui renseigne alors le modèle. Quand le
poids passe sous 0,5, une série repère est prescrite (§ 4.6).

### 3.8 A priori et partage entre exercices

- **Niveau déclaré** (profil) : fourchette lue comme une loi uniforme, plus 10 % d'écart-type.
- **Exercice proche** : sans niveau déclaré, le 1RM d'un exercice de la même chaîne de variantes et du même
  type de charge déjà suivi (proximité `planSimilarity` ≥ 0,6) sert d'a priori, écart-type 25 %.
- **Sinon la première série** : a priori centré sur ce qu'elle implique, écart-type 50 %.
- **Pente a priori** par semaine, par niveau d'expérience : 1,0 %, 0,4 %, 0,15 %, 0,05 %.
- **Après plus de 14 jours sans pratiquer un exercice**, sa pente propre n'est plus extrapolée. Si des
  exercices proches (trois au plus) ont continué, 43 % de leur variation lui est transférée (Spitz et al.
  2023) ; sinon la capacité décroît de 1 % par semaine au-delà de 21 jours (McMaster et al. 2013 ; Bosquet
  et al. 2013). L'incertitude grandit d'autant.

## 4. Décisions

### 4.1 Charge et répétitions d'une séance

Pour chaque exercice suivi, le moteur prévoit les répétitions possibles à une charge, **prudemment** :

```
répétitions prévues = n(L) × (1 − f) − z × σ − RIR visé       z = min(0,65 ; max(0 ; 0,6 − 0,25 × RIR visé))
```

`σ` réunit l'incertitude sur la capacité du jour et sur la fatigue de séance : plus la cible est près de
l'échec, plus la marge est grande.

**Charge de référence.** La charge de la dernière séance est la plus lourde des séries menées à bien,
sans échec (un échauffement non marqué ou une pyramide ne la tirent pas vers le bas) ; après un échec non
prévu, la plus légère des charges échouées : la séance suivante ne la dépasse pas, et le modèle dit s'il
faut descendre. (Repartir de la charge allégée qui a suivi l'échec a été essayé : écart au RIR plus grand
de 0,05 à 0,15, les séances suivantes étant trop faciles — § 6.)

**Charge** (règle à hystérésis, pour qu'elle ne change que quand la plage ne tient plus) : la charge de
référence (ramenée sur la grille) est gardée ; elle monte d'un cran quand les répétitions prévues
dépassent le haut de la plage de 0,5 et que la charge suivante en laisse au moins le bas ; elle descend
quand elles passent sous le bas de 0,5. Première fois : la charge de la grille juste sous celle que le
modèle prévoit pour le milieu de plage.

**Grille du matériel.** Les charges disponibles sont la plus petite charge plus un nombre entier de pas
(barre de 7 kg et disques par 2,5 kg : 7 ; 9,5 ; 12). Incréments du profil ; sinon haltères par 1 kg jusqu'à 10 kg puis par 2 kg, barre
par paire de disques de 1,25 kg (2,5 kg, barre de 20 kg), poulie par 2,5 lb, machine par 5 kg, kettlebell
par 4 kg, lest par 1,25 kg. Un exercice dont toute la charge est externe n'est jamais prescrit à 0 kg.

**Plafonds de hausse** d'une séance à l'autre, en charge totale : +10 % pour un mouvement principal, +20 %
pour un autre exercice, +25 % en calibrage. **Un seul cran** reste permis quand le plus petit cran du
matériel dépasse le plafond (haltères légers, machines à gros crans) : hors calibrage, seulement quand les
répétitions prévues atteignent le haut de plage étendu, ou après une séance notée « 5 et plus » (§ 4.3) ;
en calibrage, quand la charge suivante laisse le milieu de plage. Un test se fait à l'effort demandé, sans
plafond de hausse. **Jamais de hausse après un échec non prévu, sur une zone douloureuse, ni un jour de
bilan bas** — tests compris.

**Sans charge**, les répétitions ou les secondes sont la charge : dans ces trois cas, aucune cible ne
dépasse la plus grande série de la dernière séance de l'exercice (hors test) ; après un échec dans la
séance, aucune cible ne dépasse la dernière série faite.

**Grilles à gros crans.** Quand la charge suivante est trop lourde, la plage s'étend d'un tiers (puis
jusqu'au double, 30 répétitions au plus) et la progression passe par les répétitions (`adapt.increment_coarse`).
Quand la charge du dessous serait bien trop légère, la charge est gardée avec moins de répétitions (jusqu'à
2 sous le bas de plage, jamais moins de 3).

**Répétitions.** Une cible par série, arrondie au plus proche, décroissante avec la fatigue prévue. Sans
charge (poids du corps, tenues), les répétitions ou les secondes sont le seul réglage.

### 4.2 Calibrage

Tant que l'écart-type de la capacité opérationnelle dépasse 6 %, la cible est relevée d'un RIR
(`toCalibrate`, `adapt.calibration`) ; pendant les trois premières séances de cet état, la charge peut
monter jusqu'à +25 % par séance et +10 % par série vers le milieu de plage. Sans aucun a priori, la
première série se fait à la charge du bloc (ou au jugé) ; le moteur ouvre le suivi sur ce qu'elle dit.

### 4.3 Séries notées « 5 et plus »

Une flamme ne dit la capacité que par le bas : après une telle série, le modèle sait seulement « au moins
6 répétitions de plus ». Quand la cible a été atteinte, que la note est d'une flamme et que la cible était
d'au moins 3 flammes (écart de 2 flammes, D5) :

- **dans la séance**, la série suivante monte d'un cran de la grille (si les bornes laissent au moins trois
  répétitions à cette charge), ou d'un cinquième des répétitions sans charge, et se fait au ressenti dans
  la plage ;
- **à la séance suivante**, si la dernière série notée et au moins la moitié des séries notées étaient
  dans ce cas : un cran de plus dans les mêmes limites, séries au ressenti dans la plage étendue
  (`adapt.flames_below_target`).

Sans cette règle, un débutant qui note tout « 1 flamme » voit sa charge monter au rythme des seules bornes :
mesuré, § 6.

### 4.4 Conseil pendant la séance

Après chaque série, le modèle est mis à jour. La cible de la série suivante ne change que si l'écart aux
flammes visées atteint **2 flammes** (D5) ou après un échec non prévu ; sinon la cible prévue est gardée
(à la charge réellement utilisée). Après un échec non prévu, toutes les séries suivantes de l'exercice sont
recalculées, sans hausse. Bornes : −15 % au plus par série (un cran reste toujours permis), +5 % (+10 % en
calibrage, et pour une série sans cible prévue — première séance au jugé, série au-delà du plan). Après deux échecs non prévus sur un exercice : `stop_exercise`. Après un échec, le
repos conseillé augmente d'une minute.

### 4.5 Bilan santé gradué (D5.8, D5.9)

| Palier | Condition | Effet |
| --- | --- | --- |
| 0 | décalage > −2 % et réponse générale ≥ 3 | la capacité prévue baisse du décalage, rien d'autre |
| 1 | décalage ≤ −2 % ou réponse générale à 2 | + 0,5 RIR sur chaque cible, aucune hausse de charge |
| 2 | décalage ≤ −4 % ou réponse générale à 1 | + 1 RIR, aucune hausse, une série de moins par exercice (3 au moins pour un mouvement principal, 2 sinon) |

Le palier 1 ou 2 est écrit dans la séance (`adapt.load_held`, cause `health` ou `health_strong`). Un
exercice de programme importé donné par un pourcentage seul (§ 4.9) suit la lettre du programme : seul
« aucune hausse » s'y applique, pas le RIR ajouté ni la série en moins.

**Temps disponible.** Quand le temps annoncé ne suffit pas, la séance est raccourcie dans cet ordre :
retour au calme et mobilité retirés, une série de moins sur les accessoires (2 au moins), accessoires
retirés, une série de moins sur les mouvements principaux et secondaires (2 au moins), échauffement
retiré, secondaires retirés, puis une seule série par mouvement principal.

### 4.6 Série repère

Quand les notes n'informent plus (§ 3.7), la dernière série d'un exercice devient, une fois tous les six
jours au plus, une série ouverte : autant de répétitions que possible en gardant 1,5 répétition en
réserve, jusqu'à 6 de plus que prévu (principe de l'APRE, Mann et al. 2010). Seulement en semaine de
montée, pour une cible à 3 répétitions de l'échec au plus, hors douleur et bilan bas. Pour un utilisateur
dont les notes informent, la série repère a été essayée puis écartée : gain d'écart au RIR inférieur à
0,15, échecs doublés (mesuré, § 6).

### 4.7 Douleur

Une douleur compte au-dessus de 3/10 (règle santé L13). Tant qu'elle est active (dernier signalement
au-dessus du seuil, de moins de 14 jours, non levé par un bilan), et pour tout exercice qui sollicite la
zone (contrainte articulaire au moins moyenne, ou muscle de la zone) :

- **jamais de charge accrue** — aussi quand la douleur a été signalée depuis la dernière séance de
  l'exercice, même levée depuis ;
- + 1 RIR sur la cible ;
- à partir de 4/10 pour une contrainte forte, 7/10 pour une contrainte moyenne (seuils de `kalis_plan`),
  l'exercice est remplacé par le plus proche qui épargne la zone, ou retiré ;
- deux séances de suite au-dessus du seuil : proposition d'épargner la zone sur la fin du bloc
  (restructuration par `kalis_plan`).

### 4.8 Lieu du jour, charge minimale trop lourde

Un exercice infaisable dans le lieu du jour (matériel, lieu) est remplacé par le plus proche faisable
(`adapt.place_changed`), ou retiré. De même quand la plus petite charge du matériel est encore trop lourde
— dernière séance échouée à cette charge et moins de deux répétitions prévues (`adapt.load_floor`) : la
séance propose le plus proche d'un autre type de charge, et la revue le signale au moteur statique.

Un remplaçant a le même mode de capacité et la même unité, la même discipline ou la même chaîne de
variantes, n'est pas plus difficile, n'est ni détesté ni déclaré non su, et sa proximité est d'au moins
0,45 (`planSimilarity`).

### 4.9 Programme importé et tests

- **Programme du propriétaire (D5.10).** Un bloc de plus de 6 semaines est un programme importé : sa
  structure n'est jamais modifiée (aucune restructuration, aucun échange). Ses séances sont calculées par
  le modèle : un exercice donné par un RIR suit la règle générale dans sa plage ; un exercice donné par un
  pourcentage seul reçoit cette part du 1RM estimé, les flammes pré-remplies étant celles que le modèle
  prévoit. Les propositions de volume et de décharge restent possibles.
- **Tests.** Une prescription de test à cibles série par série (montée de `kalis_plan`) reçoit, pour
  chaque série, la charge que le modèle prévoit pour ses répétitions et ses flammes, sous les mêmes
  plafonds. Un test « maximum » est une série ouverte, la prévision prudente servant de repère bas. Un
  test se fait à l'effort demandé : pas de RIR de calibrage.

### 4.10 Revue et propositions

**Résumé d'adaptation** : semaines de données (semaines civiles avec au moins une série prise en compte),
séances prévues et faites, niveau de déblocage, confiance globale, capacités estimées (valeur,
écart-type, pente, séries), forme et fatigue, zones douloureuses, exercices régulièrement sautés ou
impossibles, faits marquants.

**Déblocage (D5.7).**

| Niveau | Condition | Propositions ouvertes |
| --- | --- | --- |
| `loads_reps` | dès le premier jour | charges, répétitions, épargne d'une zone douloureuse |
| `volume` | 2 semaines de données | volume, décharge anticipée |
| `exercise_swap` | 4 semaines | échange d'exercice |
| `session_restructure` | 1 bloc terminé et 4 semaines | restructuration d'une séance |
| `block_restructure` | 2 blocs terminés et 8 semaines | restructuration du bloc |

**Filtre.** Une proposition n'est émise que si : son niveau est débloqué ; sa confiance atteint le seuil
de son niveau (0,5 ; 0,65 ; 0,75 ; 0,8 ; 0,85) ; son utilité `progrès − risque − fatigue − coût
d'adhésion` est positive ; elle n'a pas été refusée ou annulée depuis moins de 28 jours ; elle n'a pas
déjà été appliquée. Les propositions retenues et écartées sont écrites au journal du moteur avec leurs
termes.

| Proposition | Déclencheur | Confiance |
| --- | --- | --- |
| Décharge anticipée | forme du jour sous 0,4 deux séances de suite, ou performances sous l'attendu (−3 %) avec forme sous 0,6 | 1 − forme récente ; dans le second cas 0,5 + 5 × l'écart de performance |
| Volume + 1 série | pente du groupe musculaire ≤ 0 avec une probabilité ≥ 0,7, performances normales, forme ≥ 0,6, assiduité ≥ 80 %, sous le haut de la bande de `kalis_plan` | probabilité × semaines / 4 |
| Volume − 1 série | performances du groupe sous l'attendu (−2 %) avec forme sous 0,6 | probabilité que l'écart soit réel |
| Échange d'exercice | plateau (pente ≤ 0 avec une probabilité ≥ 0,9, au moins 4 séances sur 4 semaines) d'un exercice non principal, exercice sauté 3 fois, ou charge minimale trop lourde ; pas de nouvel échange dans les 21 jours qui suivent un échange appliqué | probabilité |
| Épargner une zone | douleur au-dessus du seuil deux séances de suite | 0,9 |
| Restructurer une séance | temps insuffisant 3 fois sur les 4 dernières séances de ce jour | part des séances concernées |
| Restructurer le bloc | moins de 60 % des séances faites sur trois semaines | test binomial contre 75 % |

Deux propositions de volume au plus par revue. Les restructurations et les échanges sont demandés à
`kalis_plan` (`PlanEngine.restructure`, D5.1) ; le moteur dynamique ne compose jamais de séance lui-même.
**La portée se juge sur le contenu** : pour un échange d'exercice ou l'épargne d'une zone, tous les autres
emplacements sont verrouillés dans la demande (`keep_slot`), et la proposition est retenue (`scope` au
journal du moteur) si le changement rendu touche un autre emplacement ou fait autre chose que remplacer,
retirer ou re-prescrire. Pour un programme importé, un « bloc terminé » est compté toutes les six semaines
de données.

**Modes (D5.6).** Toute proposition est `autoApplicable` : en mode assisté l'application l'applique et
l'annonce ; en mode libre elle la soumet. Le moteur ne lit pas le mode : il lit les suites données
(`decisions`).

**Records** : meilleures répétitions, meilleure tenue, meilleur 1RM impliqué par une série de 10
répétitions au plus notée 8 flammes ou plus (courbe a priori, pour qu'un record ne dépende pas de l'état
du modèle).

## 5. Paramètres

`AdaptParams.standard`. Source : **R** référence citée (§ 10), **M** mesure du simulateur (§ 6 et
`docs/VALIDATION.md`), **H** hypothèse dite comme telle, à valider (§ 9).

| Paramètre | Valeur | Source |
| --- | --- | --- |
| `kGeneral`, `kLowerBody` | 30 ; 38 | R — Nuzzo et al. 2024 (répétitions par pourcentage, plus nombreuses au bas du corps) ; forme d'Epley |
| `kLogSd`, `kMin`, `kMax` | 0,30 ; 12 ; 80 | R — dispersion entre personnes de Nuzzo et al. 2024 (écart-type de 2,5 à 4,4 répétitions de 80 % à 60 %) |
| `kLearnMaxFatigue` | 0,02 | M — apprendre `k` sur des séries fatiguées le biaise (prototype) |
| `levelNoise`, `trendNoise`, `trendDamping` | 0,004 ; 0,0015 ; 0,97 | H — ordres de grandeur des progressions de Steele et al. 2023 et Latella et al. 2020 ; réglés sur le simulateur |
| `daySd` | 0,035 | R — variation d'un jour à l'autre du 1RM, Grgic et al. 2020 (CV médian 4,2 %, 3,3 % chez les entraînés) |
| `dayCommonShare` | 0,5 | H |
| `rirSdBase`, `rirSdPerRir` | 0,6 ; 0,35 | R — Zourdos et al. 2021, Hackett et al. 2012 et 2017 (erreur d'environ une répétition près de l'échec, croissante loin de l'échec) |
| `rirSdRepsFrom`, `rirSdRepsGain` | 12 ; 0,05 | R — Halperin et al. 2022 (prédiction moins précise sur les séries longues) |
| `rirBias` | 0,2 | R — Halperin et al. 2022 (sous-estimation moyenne d'environ une répétition) |
| `failExtraReps`, `failSd`, `completedSd` | 0,5 ; 0,5 ; 0,5 | H — demi-répétition entamée |
| `openRir` | 5 | contrat — 1 flamme = « 5 et plus » (kalis_core) |
| `huber`, `failOutlier` | 2 ; 3 | H — seuils usuels ; M pour l'effet (§ 6) |
| `observationFloor` | 0,01 | H — plancher de bruit d'une série, en `ln` de charge |
| `trendPriorSd` (par niveau) | 1,0 % ; 0,5 % ; 0,3 % ; 0,2 % par semaine | H |
| `healthNeutral`, `sleepHoursNeutral` | 4 ; 6 h | H — réponse et durée sous lesquelles le bilan compte |
| `lazyWindow`, `lazyMinSets`, `lazyConfirmRate`, `lazyMinWeight` | 40 ; 12 ; 0,6 ; 0,1 | M — profil « notes paresseuses » |
| `setFatigueAtFailure`, `setFatigueRestTau`, `setFatigueRirScale`, `setFatigueRecovery` | 0,9 ; 150 s ; 1,5 ; 0,5 | R — chutes de répétitions selon le repos, Willardson et Burkett et la revue de Salles et al. 2009 ; moindre près de l'échec, Refalo et al. 2023 |
| `fatigueRelSd` | 0,5 | H |
| `priorSdDeclared`, `priorSdNeighbour`, `priorSdFirstSet` | 0,10 ; 0,25 ; 0,5 | H |
| `trendPrior` (par niveau) | 1,0 % ; 0,4 % ; 0,15 % ; 0,05 % par semaine | R — Steele et al. 2023, Latella et al. 2020 |
| `holdReserveShare`, `holdSdBase`, `holdSdPerRir` | 0,1 ; 0,10 ; 0,05 | H |
| `quantileBase`, `quantilePerRir`, `quantileMin`, `quantileMax` | 0,6 ; 0,25 ; 0 ; 0,65 | M — compromis écart au RIR / échecs (§ 6) |
| `calibrationSd`, `calibrationRirBonus`, `calibrationSessions` | 0,06 ; 1 ; 3 | consigne du lot (RIR + 1 tant que l'estimation est incertaine) ; M pour le seuil |
| `upMargin`, `downMargin` | 0,5 ; 0,5 | M — stabilité des charges |
| `maxUpMain`, `maxUpOther`, `maxUpCalibration` | 10 % ; 20 % ; 25 % | R — ACSM 2009 (hausses de 2 à 10 %) pour le mouvement principal ; H pour les autres |
| `maxUpSet`, `maxUpSetCalibration`, `maxDownSet` | 5 % ; 10 % ; 15 % | R — ajustements de l'APRE (Mann et al. 2010) ; H |
| `adviceGapFlames` | 2 | décision D5 |
| `benchmarkWeight`, `benchmarkRir`, `benchmarkExtraReps`, `benchmarkEveryDays`, `benchmarkMaxRir`, `benchmarkEveryDaysRated` | 0,5 ; 1,5 ; 6 ; 6 ; 3 ; 0 | R — APRE (Mann et al. 2010) ; M pour les seuils (§ 6) |
| `tauAcute`, `tauChronic`, `tauFitness` | 1,2 ; 7 ; 42 jours | R — récupération en 24 à 72 h (Morán-Navarro et al. 2017, Belcher et al. 2019, Pareja-Blanco et al. 2019) ; constantes de Calvert et al. 1976 et Busso 2003 (ordre de grandeur, établies hors musculation) |
| `kappaAcute`, `kappaChronic`, `fatigueGainSd`, `fatigueBaselineAlpha` | 0,004 ; 0,0006 ; 1 ; 0,2 | H — échelle fixée pour qu'une séance dure coûte de 2 à 4 % le lendemain ; gain appris par personne |
| `readinessSpan` | 0,10 | H |
| `healthPerPoint`, `sleepPerHour`, `detailPerItem`, `detailShare`, `healthFloor` | 1,5 % ; 1 % ; 1 % ; 0,5 ; −8 % | R — privation de sommeil : −7,6 % en moyenne (Craven et al. 2022), surtout après plusieurs nuits (Knowles et al. 2018) ; bien-être déclaré sensible à la charge (Saw et al. 2016) ; H pour la répartition |
| `healthLevel1`, `healthLevel2`, `healthRirBonus` | −2 % ; −4 % ; 0,5 | H |
| `painThreshold`, `painHard`, `painSevere`, `painRirBonus`, `painClearDays` | 3 ; 4 ; 7 ; 1 ; 14 | règle santé L13 ; seuils de `kalis_plan` ; R — surveillance de la douleur, Silbernagel et al. 2007 (douleur tolérée jusqu'à 5/10 si elle retombe, sans hausse) |
| `transferShare`, `transferMinSimilarity`, `transferNeighbours` | 0,43 ; 0,6 ; 3 | R — Spitz et al. 2023 (gain transféré ≈ 43 % du gain spécifique) |
| `detrainFromDays`, `detrainPerWeek` | 21 ; 1 % | R — McMaster et al. 2013 (force gardée jusqu'à 3 semaines), Bosquet et al. 2013 |
| `plateauProbability`, `plateauMinWeeks`, `plateauMinSessions`, `swapQuietDays` | 0,9 ; 4 ; 4 ; 21 | M — à 0,8 sur 3 semaines, un athlète avancé (pente vraie presque nulle) recevait 6 échanges en 24 semaines (§ 6) |
| `volumeMinWeeks`, `swapMinWeeks`, `sessionRestructureMinWeeks`, `blockRestructureMinWeeks` | 2 ; 4 ; 4 ; 8 | décision D5.7 |
| `confidenceLoads` … `confidenceBlock` | 0,5 ; 0,65 ; 0,75 ; 0,8 ; 0,85 | H — croissants avec la portée (D5.7) |
| `refusalQuietDays`, `deloadReadiness`, `deloadSessions`, `adherenceLow`, `skipTimes`, `timeShortTimes` | 28 ; 0,4 ; 2 ; 0,6 ; 3 ; 3 | H |
| `repSeconds`, `transitionSeconds`, `defaultRestSeconds` | 3 ; 45 ; 120 | valeurs de `kalis_plan` |
| `referenceBodyWeightKg` | 70 | H — n'intervient que sans poids de corps au profil ni à la séance |

Hors `AdaptParams`, des constantes de structure sont écrites dans le code et dites dans ce contrat :
proximité minimale d'un remplaçant (0,45, seuil des variantes de `kalis_plan`), coupure de 14 jours avant
reprise, plafond de 0,8 de la fatigue de séance, bruit de 5 % de la borne « série terminée » sans charge,
repos supposés par nature d'exercice (ceux de `kalis_plan`), termes d'utilité des propositions (§ 4.10).

Les volumes par groupe musculaire s'appuient sur les bandes de `kalis_plan` (Pelland et al. 2026, Ralston
et al. 2017) ; la réponse individuelle au volume varie beaucoup (Hammarström et al. 2020), d'où une
proposition d'une série à la fois.

## 6. Choix de modélisation mesurés

Mesures de mise au point (prototype Python de 16 graines, puis simulateur Dart de 6 graines par athlète) ;
la campagne complète est dans `docs/MESURES.md`.

| Choix | Ce qui a été mesuré |
| --- | --- |
| Suivre la capacité opérationnelle (pivot `n_ref`) plutôt que le 1RM | avec `k` « considéré », le filtre paramétré par le 1RM réagissait trop lentement ; le pivot a levé le défaut |
| `k` appris seulement par des séries fraîches et précises | appris sur toutes les notes, `k` dérivait (erreur sur les variables) et l'erreur de 1RM grandissait de semaine en semaine |
| Bruit d'une note pris au plus grand du RIR dit et du RIR prévu, écrêtage de Huber | une note « 9 flammes » donnée à 4 répétitions de l'échec ne fait plus chuter l'estimation |
| Fatigue comptée en écart au niveau habituel | apprise en valeur absolue, la sensibilité individuelle convergeait vers 0 |
| Biais de note individuel **non** appris | essayé : aucun gain, estimateur biaisé par les mêmes notes qu'il corrige ; le biais moyen (0,2) est gardé |
| Échelle individuelle de la fatigue de séance **non** apprise | essayé : aucun gain |
| Cran de plus après des séries notées « 5 et plus » (§ 4.3) | sans la règle, écart au RIR de 2,4 (débutant) et 5,3 (haltères à la maison) ; avec, 1,3 à 1,5 et 2,4 |
| Vérité « charge trop légère » : charge gardée avec moins de répétitions | supprime les allers-retours entre deux crans d'haltères |
| Série repère pour tous, toutes les deux semaines | écart au RIR −0,05 à −0,15, échecs non prévus de 0,4–0,8 % à 1,1–1,7 % : écartée |
| Pivot déplacé quand la plage change (§ 3.2) | écriture de référence : après un passage de 15 à 3 répétitions, écart-type de la charge prévue 7,9 % après 30 séances à pivot fixe, 1,5 % à pivot déplacé |
| Série manquée douteuse écrêtée à 3 écarts-types (§ 3.3) | écriture de référence, 1RM estimé 100 kg : zéro répétition à 20 kg → 94,4 kg sans écrêtage, 100,0 avec ; échec noté à 5 répétitions à 50 kg → 81,4 kg (et `k` au plafond) sans, 99,8 avec ; échec réel trois répétitions plus tôt que prévu → 99,3 dans les deux cas |
| Marge de prudence `z = 0,6 − 0,25 × RIR` (au lieu de `0,9 − 0,25 × RIR`, plancher 0,15) | écart au RIR −0,1 à −0,25, biais de +0,9 à +0,5, échecs inchangés, quasi-échecs de 1 % à 1,7 % : retenue |

## 7. Invariants testés

Tests de propriétés sur **10 240 journaux aléatoires** seedés (`test/properties.dart` : charges qui
sautent, notes absentes ou extrêmes, séries à zéro répétition, séances libres, séries enchaînées de deux
exercices dans un journal sur cinq, douleurs, bilans partiels, reprises, coupures, jusqu'à 40 séances,
16 profils types, blocs de rang 0 à 2). Les invariants sont vérifiés **depuis le journal et la sortie**,
sans lire l'état du moteur. Les vérifications reprennent quatre briques du moteur — la grille des charges,
la sollicitation d'une zone par un exercice, le calcul du niveau de déblocage, la semaine civile : une
erreur dans ces briques ne serait pas vue par ces tests (elles ont leurs tests unitaires).

| # | Invariant | Vérification |
| --- | --- | --- |
| I1 | Mouvement principal, à partir de la quatrième séance de l'exercice au journal, hors test : jamais plus de +10 % de charge totale d'une séance à l'autre | charge prescrite comparée à la plus forte charge de la dernière séance de l'exercice ; exception : un seul cran de grille quand le plus petit cran dépasse 10 % |
| I2 | Jamais de hausse après une série à l'échec non prévue | séance suivante : aucune charge au-dessus de la plus légère des charges échouées ; série suivante dans la séance, y compris après des séries d'un autre emplacement ; sans charge : aucune cible au-dessus de la plus grande série de la dernière séance, ni de la dernière série faite |
| I3 | Une douleur au-dessus du seuil n'est jamais suivie d'une charge accrue sur la zone (ni, sans charge, d'une cible accrue) ; un exercice exclu par la douleur du jour n'est pas prescrit | zones signalées depuis la dernière séance de l'exercice et au bilan du jour ; conseil avec et sans le bilan redonné |
| I4 | Aucune proposition au-dessus du niveau de déblocage | niveau recalculé depuis les semaines civiles du journal et le rang du bloc ; la portée d'un échange ou d'une épargne de zone est contrôlée par le moteur sur le changement rendu (§ 4.10) |
| I5 | Sorties valides au sens du contrat (codes de raison et paramètres compris) ; charges sur la grille | `validate()` de kalis_core ; bloc encore valide après chaque proposition |
| I6 | Même entrée, même sortie à l'octet près, avec ou sans cache, journal donné en une fois ou prolongé | instance neuve comparée à l'instance en cours ; un journal sur quatre est donné en deux fois |
| I7 | Un bilan sans réponse équivaut à l'absence de bilan ; un jour de bilan bas, le conseil ne monte pas la charge, bilan redonné ou non | séance comparée ; conseils contrôlés |
| I8 | Les séances « reprise » ne changent rien | séance « reprise » ajoutée (une graine sur quatre), séance comparée |

Ce que ces tests ne produisent pas : programme importé au pourcentage, décisions passées et état de la
revue, charges négatives sur un exercice lesté. Le programme importé est exercé par le journal du
propriétaire (`docs/PROPRIETAIRE.md`) ; les erreurs d'entrée par `test/sessions_test.dart`.

S'y ajoutent : la référence croisée du filtre (52 scénarios, plus de 2 400 étapes — séries, bornes, échecs
écrêtés, déplacements de pivot — rejouées contre une seconde écriture en Python, écart relatif ≤ 1e-9 :
`test/reference_test.dart` ; cette écriture suit les mêmes équations, elle garde d'une erreur de
programmation, pas d'une erreur de modèle) ; les scénarios de journal (`test/sessions_test.dart` : séries
enchaînées, charge de référence, verrous, saisie douteuse, journal prolongé, pivot) ; les tests unitaires
des briques (`test/units_test.dart`) ; le bout en bout des huit athlètes simulés en boucle complète
(`test/smoke_test.dart`) ; la pureté (`test/purity_test.dart`) ; les documents générés à jour
(`test/docs_test.dart`).

**Temps de calcul** (cibles du lot : décision de séance ≤ 50 ms, mise à jour après une série ≤ 5 ms sur
une machine modeste) : `docs/MESURES.md`, § 5 — mesurés sur la machine de contrôle, pas sur un téléphone.

## 8. Limites connues

1. **L'écart au RIR visé dépasse la cible d'une répétition** pour la plupart des profils simulés
   (`docs/VALIDATION.md`, § 2). Loin de l'échec, la note en flammes renseigne peu (bruit de deux
   répétitions et plus à 4 RIR), l'effet de jour seul vaut plus d'une répétition sur une série de 12, et
   une grille à gros crans ne laisse pas toujours la bonne charge. L'oracle — qui connaît la vérité — donne
   le plancher de chaque profil.
2. **Cible non atteignable.** Un exercice au poids du corps trop facile ou trop dur pour sa plage, un
   exercice chargé dont le plus petit cran est trop grand : le moteur étend la plage, garde la charge ou
   remplace l'exercice, mais ne peut pas atteindre le RIR visé. La progression vers une variante plus
   dure se fait au bloc suivant, par `kalis_plan`, à partir des capacités du résumé.
3. **Capacité d'un exercice jamais poussé près de l'échec** : connue par le bas seulement (notes d'une
   flamme) ; l'intervalle annoncé est alors trop étroit (couverture mesurée sous 95 %, § 3 de
   `docs/VALIDATION.md`).
4. **Biais de note individuel non appris** : une personne qui sous-estime beaucoup ses répétitions en
   réserve reçoit des séries plus faciles que visé.
5. **Paramètres de fatigue et de bilan santé** : ordres de grandeur tirés d'études de groupe, hors
   musculation pour les constantes de temps longues ; le gain individuel est appris, pas les constantes.
   La forme du jour rendue dans la séance et la revue compte la fatigue en valeur absolue, alors que son
   effet sur une capacité est compté en écart à l'habitude : un gros volume régulier peut tenir la forme
   affichée basse sans baisse de performance (les propositions de décharge et de volume exigent aussi une
   baisse de performance, sauf la décharge « forme sous 0,4 deux séances de suite »).
6. **Exercices non modélisés** : cardio, conditionnement, mobilité, distances, calories — rendus tels que
   le bloc les prescrit.
7. **Unilatéral** : la capacité est suivie par exercice, sans distinguer les côtés.
8. **Séries enchaînées** (supersets, circuits) : chaque exercice garde son déroulement (§ 2), mais la
   fatigue croisée entre exercices d'un même groupe n'est comptée que par le modèle forme-fatigue du
   jour, et un exercice repris après un autre ne relit pas l'effet de jour que cet autre a montré
   entre-temps. Le même exercice à deux emplacements d'une séance compte pour deux déroulements.
9. **Forme de la courbe.** `k` n'est appris que par les séries qui le mesurent ; après un changement de
   plage, la connaissance acquise sur l'ancienne plage ne sert qu'à travers `k` a priori (§ 3.2, 3.3).
10. **Saisies fausses.** Une note fausse ou une série manquée douteuse pèse peu sur l'estimation (§ 3.3),
    mais un échec saisi par erreur reste un échec pour le garde-fou I2 : la séance suivante ne dépasse pas
    la charge saisie, puis remonte dans les plafonds. La série doit être écartée (`excluded`) pour ne plus
    compter. Une série saisie avec trop de répétitions n'est pas écrêtée ; les séries suivantes la
    corrigent.
11. **Douleur de 5 à 6/10 sur une contrainte moyenne** : l'exercice est gardé sans hausse, avec un RIR de
    plus (seuils de `kalis_plan`), alors que la source citée ne tolère la douleur que jusqu'à 5/10. À
    faire trancher par un professionnel (§ 9).
12. **Exercice lesté** : le plafond de +10 % porte sur la charge totale ; pour un lest léger devant le
    poids du corps, le lest lui-même peut presque doubler d'une séance à l'autre (80 kg de poids de corps,
    lest de 10 à 19 kg).
13. **Grille du matériel** : `kalis_plan` compte les charges en multiples du pas à partir de zéro ; ce
    moteur les compte à partir de la plus petite charge. Les deux coïncident pour toutes les grilles par
    défaut ; ils diffèrent quand le profil donne une plus petite charge qui n'est pas un multiple du pas.
14. **Simulateur.** La vérité simulée est un modèle écrit pour ce lot (courbe exponentielle, bruit de
    note, gains selon la dose). Elle n'a pas la courbe du moteur, mais elle en partage plus que les
    sources : sensibilités à la fatigue aiguë et accumulée, forme de la fatigue de séance et son plafond,
    poids d'effort d'une série, désentraînement après 21 jours, effet de jour d'un écart-type de 2 à 3 %
    (le moteur suppose 3,5 %). L'athlète simulé arrête sa série quand il se sent sous la cible, ce qui
    tient les taux d'échec bas pour toutes les politiques. Les mesures sont donc optimistes pour le
    moteur ; les comparaisons entre politiques, faites à aléas égaux, le sont moins. Aucune donnée réelle
    n'a servi (`docs/VALIDATION.md`, § 6).
15. **Temps de calcul** non mesurés sur téléphone.

## 9. Registre de validation

| Élément | État |
| --- | --- |
| Équations du filtre | vérifiées contre une seconde écriture en Python des mêmes équations (vecteurs partagés) |
| Invariants de sécurité I1 à I8 | testés sur 10 240 journaux aléatoires |
| Convergence, écart au RIR, échecs, progression | mesurés sur 8 athlètes simulés × 24 semaines × 200 graines, comparés à la double progression, à l'ancien moteur L7/L11 et à l'oracle |
| Références bibliographiques | relevées par recherche documentaire pour ce lot ; plusieurs vérifiées sur le résumé seulement (§ 10) |
| Paramètres marqués H | hypothèses, non validées sur des données réelles |
| Relecture indépendante du code et des documents | faite avant livraison par un second relecteur automatique, sans exécution du code ; 19 constats, suites données dans `docs/VALIDATION.md`, § 7 |
| Mode coach (0.2.0) : invariants C1 à C4 et I2 à I8 | testés sur 10 240 journaux aléatoires aux champs de 0.4.0, 17 programmes street sous trois modèles de vérité, programmes à techniques injectées (§ 11.10) |
| Mode coach : trajectoires simulées des 17 profils street | jugées par le panel de `kalis_bench` (4 écoles) ; résultat et corrections restantes dans `docs/CALIBRAGE_CA1.md` — cible « 9 partout » **non atteinte** |
| Mode coach : paramètres « choix raisonné » | non validés sur des données réelles (§ 11.11) |
| **Relecture par un professionnel diplômé (préparateur physique, kinésithérapeute)** | **non faite** |
| **Validation sur des journaux réels d'utilisateurs** | **non faite** (aucune donnée réelle n'a servi) |

## 10. Références

Vérifiées sur le texte ou le résumé de l'article ; « (résumé) » : résumé seul ; « (secondaire) » : source
secondaire.

- ACSM (2009). Progression models in resistance training for healthy adults. *Med Sci Sports Exerc* 41(3).
- Belcher D.J. et al. (2019). Time course of recovery is similar for the back squat, bench press, and
  deadlift in well-trained males. *Appl Physiol Nutr Metab* 44(10). (résumé)
- Bosquet L. et al. (2013). Effect of training cessation on muscular performance: a meta-analysis.
  *Scand J Med Sci Sports* 23(3).
- Busso T. (2003). Variable dose-response relationship between exercise training and performance.
  *Med Sci Sports Exerc* 35(7).
- Calvert T.W. et al. (1976). A systems model of the effects of training on physical performance. *IEEE
  Trans Syst Man Cybern* 6(2).
- Craven J. et al. (2022). Effects of acute sleep loss on physical performance: a systematic and
  meta-analytical review. *Sports Med* 52(11).
- Durbin J., Koopman S.J. (2012). *Time Series Analysis by State Space Methods*, 2ᵉ éd., Oxford.
- Grgic J. et al. (2020). Test-retest reliability of the one-repetition maximum (1RM) strength
  assessment: a systematic review. *Sports Med Open* 6:31.
- Hackett D.A. et al. (2012). A novel scale to assess resistance-exercise effort. *J Sports Sci* 30(13).
- Hackett D.A. et al. (2017). Accuracy in estimating repetitions to failure during resistance exercise.
  *J Strength Cond Res* 31(8).
- Halperin I. et al. (2022). Accuracy in predicting repetitions to task failure in resistance exercise: a
  scoping review and exploratory meta-analysis. *Sports Med* 52(2).
- Hammarström D. et al. (2020). Benefits of higher resistance-training volume are related to ribosome
  biogenesis. *J Physiol* 598(3).
- Harvey A.C. (1989). *Forecasting, Structural Time Series Models and the Kalman Filter*, Cambridge.
- Helms E.R. et al. (2018). RPE vs. percentage 1RM loading in periodized programs matched for sets and
  repetitions. *Front Physiol* 9:247.
- Kalman R.E. (1960). A new approach to linear filtering and prediction problems. *J Basic Eng* 82(1).
- Knowles O.E. et al. (2018). Inadequate sleep and muscle strength: implications for resistance training.
  *J Sci Med Sport* 21(9).
- Latella C. et al. (2020). Long-term strength adaptation: a 15-year analysis of powerlifting athletes.
  *J Strength Cond Res* 34(9).
- Mann J.B. et al. (2010). The effect of autoregulatory progressive resistance exercise vs. linear
  periodization on strength improvement in college athletes. *J Strength Cond Res* 24(7).
- McMaster D.T. et al. (2013). The development, retention and decay rates of strength and power in elite
  rugby union, rugby league and American football. *Sports Med* 43(5).
- Morán-Navarro R. et al. (2017). Time course of recovery following resistance training leading or not to
  failure. *Eur J Appl Physiol* 117(12).
- Nuzzo J.L. et al. (2024). Maximal number of repetitions at percentages of the one repetition maximum: a
  meta-regression and moderator analysis. *Sports Med* 54(2).
- Pareja-Blanco F. et al. (2019). Time course of recovery from resistance exercise with different set
  configurations. *J Strength Cond Res*. (résumé)
- Pelland J.C. et al. (2026). The resistance training dose response: meta-regressions exploring the
  effects of weekly volume and frequency on muscle hypertrophy and strength gains. *Sports Med*.
  (prépublication lue)
- Ralston G.W. et al. (2017). The effect of weekly set volume on strength gain: a meta-analysis. *Sports
  Med* 47(12).
- Refalo M.C. et al. (2023). Influence of resistance training proximity-to-failure on skeletal muscle
  hypertrophy: a systematic review with meta-analysis. *Sports Med* 53(3).
- de Salles B.F. et al. (2009). Rest interval between sets in strength training. *Sports Med* 39(9).
- Saw A.E. et al. (2016). Monitoring the athlete training response: subjective self-reported measures
  trump commonly used objective measures. *Br J Sports Med* 50(5).
- Silbernagel K.G. et al. (2007). Continued sports activity, using a pain-monitoring model, during
  rehabilitation in patients with Achilles tendinopathy. *Am J Sports Med* 35(6).
- Spitz R.W. et al. (2023). Strength testing or strength training: considerations for future research.
  *Physiol Meas* 41. (résumé)
- Steele J. et al. (2017). Ability to predict repetitions to momentary failure is not perfectly accurate,
  though improves with resistance training experience. *PeerJ* 5:e4105.
- Steele J. et al. (2023). Long-term time-course of strength adaptation to minimal dose resistance
  training. *Res Q Exerc Sport* 94(4).
- Tallis G.M. (1961). The moment generating function of the truncated multi-normal distribution. *J R
  Stat Soc B* 23(1).
- Zourdos M.C. et al. (2021). Proximity to failure and total repetitions performed in a set influences
  accuracy of intraset repetitions in reserve-based rating of perceived exertion. *J Strength Cond Res*
  35(Suppl 1).

Deux nombres souvent cités n'ont **pas** été retrouvés dans leur source et ne sont pas utilisés : une
table « 40/20/16/10/2 % » attribuée à l'ACSM 2009, et les constantes « 45/15 jours, 1/2 » attribuées à
Morton et al. 1990.

## 11. Mode coach (0.2.0) : blocs au contrat 0.4.0

Un bloc « porte le contrat 0.4.0 » dès qu'il écrit une intention de bloc ou de semaine, une échelle de
figure, un groupe, une technique, une intensité, une règle d'autorégulation, un test décrit ou une étape de
figure (`blockCoached`). Le moteur le sert alors en **mode coach** : il exécute ce que le programme écrit
et n'en sort que pour protéger l'athlète ou quand le journal montre que le chiffre écrit ne lui va pas. Un
bloc sans aucun de ces champs (programmes de `kalis_plan` 0.1, programme importé du propriétaire) est servi
comme en 0.1.0, à l'octet près (§ 7) ; `KalisAdapt(legacy: true)` sert aussi un bloc 0.4.0 comme en 0.1.0
(comparaisons de `docs/CAMPAGNE_STREET.md`). `KalisAdapt` implémente aussi `EventDayAdvisor`
(`planEventDay`, § 11.7).

Les identifiants « R2-P3 », « R4-F9 »… renvoient au référentiel de `kalis_bench`
(`docs/REFERENTIEL.md`), qui cite ses sources. « Choix raisonné » : aucun chiffre publié, la valeur est un
choix de ce lot, à valider (§ 9).

### 11.1 Ce que la semaine permet

| Intention de la semaine | Ce que le moteur fait |
| --- | --- |
| accumulation, intensification, réalisation (semaines de charge) | la réserve visée pilote la charge dans un couloir autour de la part écrite (§ 11.2) ; séries au ressenti et série repère possibles (§ 11.4) ; le volume peut être proposé à la hausse par la revue |
| introduction, décharge, affûtage, test, compétition, transition (semaines servies telles quelles) | la séance du bloc est servie telle qu'elle est écrite : aucune hausse au-delà de la charge écrite, aucune série ajoutée, aucune série repère, aucune technique qui mène près de l'échec ; raison `adapt.phase_respected` (et `adapt.taper_no_volume` en affûtage et en compétition : R3-P12, R3-P13) |
| maintien | la séance du bloc est servie avec les garde-fous (réserve gardée, verrous après échec ou douleur), sans pilotage à la hausse, sans série repère ni série au ressenti |
| échéance principale à 14 jours ou moins (`coachEventNearDays`) | décisions prudentes : pas de pilotage à la hausse, pas de série au ressenti ; `adapt.event_near` |

Le jour même, le moteur ne sert **jamais plus de séries** que le bloc n'en écrit (invariant C2, § 7) ; le
volume ne monte que par une proposition de la revue, jamais en affûtage ni quand le profil déclare une
récupération réduite (sommeil habituel sous 6 h, stress élevé, métier physique lourd : `adapt.recovery_profile`,
R5-P14, R5-P15, R5-P18).

### 11.2 Exercice chargé écrit en part du 1RM

La charge écrite est `part × 1RM estimé` (le 1RM de l'exercice, ou celui de l'exercice de référence de
l'intensité, corrigé de l'écart appris entre les deux), sur la grille du matériel, charge totale (R2-P4).

- **Semaine de charge, niveau intermédiaire et plus, hors jour léger** : la charge est la plus forte du
  couloir `[part − 5 % ; part + 7,5 %]` du 1RM (`coachCorridorDown`, `coachCorridorUp` : ±2,5 % par point
  d'écart, R2-P3, bornés à deux points vers le bas et trois vers le haut — choix raisonné) qui laisse en
  moyenne la réserve visée sur les séries de tête et, avec la marge de prudence, la réserve visée moins 1,5
  sur la plus dure (`coachWorstSetSlack`). Quand une séance servie au haut du couloir est restée au moins
  2 répétitions plus facile que visé (`coachEasyGapRir`), le haut du couloir monte de 2,5 % (`coachCorridorWiden`),
  jusqu'à +15 % (`coachCorridorUpMax`) ; une séance plus dure que visé le redescend d'un cran.
- **Débutant, jour léger, semaine servie telle quelle, échéance proche, zone douloureuse, bilan bas** : la
  charge écrite, allégée seulement si elle ne laisse pas la réserve visée moins un point (plafond d'effort,
  `adapt.rir_cap`).
- **Garde-fous** (dans cet ordre) : à schéma égal (même emplacement, mêmes répétitions), la charge totale
  ne monte pas de plus de 10 % (débutant) ou 5 % (autres niveaux) d'une séance à la suivante
  (`coachRise` ; moitié sur une zone à antécédent ou à gêne déclarée, `coachHistoryRiseFactor`) — un cran
  de grille reste toujours permis (limite 12 de 0.1 : un lest léger ne double plus) ; au premier passage à
  un schéma, jamais plus que la plus grande de la charge écrite par le bloc et de +10 % de la plus lourde
  barre réussie des six dernières semaines (invariant C1) ; aucune hausse par rapport à la dernière séance
  de l'exercice après un échec non prévu ni sur une zone douloureuse (I2, I3) ; `adapt.load_held` dit la
  cause.
- **Effort affiché** : celui du bloc ; quand la charge servie est retenue sous ce que la réserve visée
  demanderait (couloir, plafond de hausse, semaine servie telle quelle), les flammes affichées sont celles
  de l'effort attendu, jamais plus dures que la cible du bloc.

- **Séries allégées** (`top_set_backoff`). En semaine de charge, des séries allégées qui laisseraient
  nettement plus de réserve que visé (un point de plus que la série de tête) sont rapprochées de la série de
  tête : la baisse servie descend jusqu'à la moitié de la baisse écrite, au moins 5 % (`coachBackoffMinDrop` ;
  choix raisonné, R2-P6 : aucun pourcentage n'est validé par un essai). Le conseil d'entre-séries garde cette
  baisse quand il recalcule sur la série de tête réalisée.
- **Répétitions écrites non atteintes** à la dernière séance de l'emplacement : aucune hausse
  (`adapt.load_held`, cause `reps`). Une barre où les répétitions demandées n'ont pas été faites n'est pas une
  « barre réussie ».
- **Exercice écrit en part du 1RM d'un autre mouvement** (variante, amplitude partielle surchargée).
  Première séance : 60 % de la charge écrite (`coachNewExerciseShare`, R5-P22 : un exercice nouveau démarre à
  50–60 %) ; ensuite la charge rejoint la charge écrite par paliers de 10 % au plus d'une séance à la suivante
  (5 % sur une zone à antécédent), et dès la deuxième séance le plafond d'effort se juge sur le suivi propre
  de l'exercice. Sur une zone à antécédent, jamais plus que 100 % du 1RM de référence
  (`coachOverloadFragileMax`).

Un exercice chargé sans part du 1RM (plage et réserve seulement), ou sans suivi encore, suit la règle
générale de 0.1 (§ 4.1), bornée par la plage du bloc en semaine servie telle quelle.

### 11.3 Techniques

Chaque technique est servie avec `sets` = lignes de journal (contrat de `kalis_core`, § 12), et relue dans
le journal par `readLine` :

| Technique | Séance servie | Lecture du journal |
| --- | --- | --- |
| `top_set_backoff` | série de tête pilotée (§ 11.2) ; séries allégées à la baisse écrite, calculées pendant la séance sur la série de tête **réalisée** (`adapt.backoff_from_top_set`), 2,5 % de moins par point de réserve manquant (5 % au plus) | une ligne par série, rôles `top` et `back_off` |
| `cluster` | charge qui tient la réserve visée sur les mini-séries, repos courts comptés | le total de la ligne se compare à la cible ; chaque partie est une borne basse de la capacité |
| `rest_pause`, `myo_reps`, `drop_set` | première partie comme une série classique ; `miniSetsLeft` conseillé | seule la première partie mesure la capacité |
| `accentuated_eccentric` | charge de la descente : part écrite, au plus 110 % du 1RM (R2-P17) ; jamais à 10 jours ou moins d'une échéance (`coachEccentricEventDays`) ni sur une zone à antécédent | la ligne ne mesure pas la capacité du mouvement complet |
| `wave`, `pyramid`, `ladder` | un palier par ligne (rôles `wave`, `rung`) ; la charge ne monte d'une vague à l'autre qu'un jour sans verrou, et la vague la plus lourde est à la charge retenue par les garde-fous (les vagues d'avant sont plus légères d'autant) | ligne par ligne |
| `emom`, `density`, `for_time` | intervalles ou bloc au temps ; arrêt quand les répétitions chutent (`stop_on_rep_drop`) — sauf si la série en baisse est dite facile (au moins 3 en réserve) : ce n'est pas de la fatigue | parties : bornes basses |
| `isometric_hold`, `skill_practice` | durée écrite ou part du maintien maximal mesuré (§ 11.5) ; arrêt quand la propreté passe sous le plancher (`stop_on_quality_drop`) | une ligne sous le plancher de propreté compte comme un échec |
| `amrap` | dernière série ouverte | série ouverte |

Une ligne du journal sans technique déclarée ni parties est lue comme une série classique.

**Prérequis** (R2-P22). Niveau d'accès : intermédiaire pour la série de tête, la dégressive, la série au
maximum, la pyramide, l'échelle, la densité et le contre-la-montre ; avancé pour les clusters, le rest-pause,
les myo-reps, la descente accentuée, le contraste et les vagues. Une technique au-dessus du niveau n'est
jamais servie : des séries classiques au même travail approché la remplacent (`standardEquivalent`). Une
technique qui mène près de l'échec ou surcharge n'est servie ni sur une zone douloureuse, ni un jour de
bilan nettement bas, ni en semaine servie telle quelle. Raison : `plan.technique_withheld` (technique,
cause).

**Règles d'autorégulation portées par la prescription** : `stop_at_rir` (une ligne finie au moins un point
sous le plancher allège la suivante de 2,5 à 5 % ; deux de suite arrêtent l'exercice, après `minSets`
lignes), `stop_on_rep_drop`, `stop_on_quality_drop` (avec l'étape plus facile conseillée,
`stepExerciseId`, quand les deux premières lignes sont sales), `backoff_from_top_set`, `hold_from_best`,
`last_set_amrap`. Une ligne qui a dû être allégée le reste jusqu'à la fin de l'exercice.

### 11.4 Ce qui mesure la capacité

Une note d'effort isolée est peu sûre : erreur de mesure de 2,6 à 3,4 répétitions (Steele et al. 2017),
sous-estimation moyenne d'une répétition, plus grande loin de l'échec et sur les séries longues (Halperin et
al. 2022 ; Zourdos et al. 2021). Aucune étude ne valide une note « 4 en réserve ou plus ». Le mode coach en
tire quatre règles.

- **Une série à cible fixe menée à bien est une borne, quelle que soit sa note** : elle dit « au moins les
  répétitions faites plus la réserve dite » (sans gonflement par le biais). Sa note sert au conseil de la série
  suivante (§ 11.3), pas à l'estimation.
- **Ce que l'athlète fait mesure** : un échec ; des répétitions qui manquent à la cible avec une note sous
  2 en réserve (`coachCensorRir`) ; une série ouverte arrêtée au ressenti avant le haut de sa plage, notée
  2 en réserve ou moins ; un test.
- **Une borne tenue n'apprend rien ; une borne franchie ramène l'estimation vers elle**
  (`CapacityFilter.hinge`). La mise à jour par loi normale tronquée de 0.1, répétée série après série sur des
  bornes qui ne sont pas indépendantes, compte la même information plusieurs fois et pousse l'estimation
  au-delà de la borne (Simon et Simon 2010 ; filtre de Kalman pour mesures censurées : Allik et al. 2016).
- **Le journal des blocs précédents se lit de la même façon** (`SlotSpec.coachRead`) : l'estimation ne
  change pas quand un nouveau bloc commence.

Séries qui mesurent, quand rien n'a mesuré depuis 14 jours (`coachProbeDays`) :

- **Série repère** (`adapt.benchmark_set`) : la dernière série classique devient ouverte, à 1,5 répétition
  en réserve (2 pour un débutant), comme dans l'APRE (Mann et al. 2010) ; sans charge, jusqu'au double du
  haut de la plage.
- **Série de tête repère** : en semaine de charge hors réalisation, la série de tête d'un « série de tête
  puis séries allégées » devient ouverte : les répétitions écrites, et jusqu'à 3 de plus
  (`coachTopProbeReps`) si la réserve visée le permet.
- **Tenue repère** : la première tenue d'un maintien dont le maximum n'est pas connu se fait jusqu'à la
  durée écrite par le bloc, arrêt avant la perte de position ; plus tard, quand l'estimation fait servir
  moins que la durée écrite, la dernière tenue est ouverte jusqu'à cette durée (jamais au-delà ; bras tendus
  et appuis : dans la borne de hausse d'une séance à la suivante, § 11.5).

Jamais en semaine servie telle quelle, près d'une échéance, un jour léger, un jour de bilan bas, sur une zone
douloureuse ni après un échec.

- **Séries au ressenti.** Une séance notée au plafond alors que la cible était plus dure ouvre, la fois
  suivante, des séries au ressenti (plage étendue, § 4.3).
- **Biais de note appris** (limite 4 de 0.1). Un test mené près de l'échec (série de test ou de
  répétitions maximales, pas une tentative) compare ce que les séries laissaient prévoir à ce que l'athlète
  montre ; un quart de l'écart, rapporté à trois répétitions, corrige le biais de la personne, de 0,1 au plus
  par test, entre 0 et 0,6 (`biasLearn…`, choix raisonnés).
- **Forme de la courbe.** Toute série fraîche qui mesure, à moins de 3 en réserve, renseigne `k` (§ 3.1).
- **Pas de bonus de calibrage** : en mode coach, l'effort visé d'un exercice encore mal connu n'est pas
  relevé d'un point (règle de 0.1) ; la dose du bloc et les garde-fous valent.

### 11.5 Exercices sans charge, maintiens, figures

- **Répétitions au poids du corps, part d'un test** (`percent_benchmark`). La cible suit le maximum mesuré,
  dans les deux sens : `part × maximum estimé`, et jamais plus que `maximum du jour − réserve visée` (la
  règle des programmes : « série de tête = maximum mesuré moins la réserve », jamais sur un progrès supposé).
  Au-dessus de ce que le bloc écrit, une répétition de plus que la dernière séance de l'emplacement au plus.
  `adapt.reps_down` ou `adapt.reps_up` dit l'écart au programme.
- **Répétitions au poids du corps, plage** (avec ou sans part de test). Le haut servi garde la réserve du
  bloc sur chaque série, fatigue prévue comprise : jamais plus que `maximum du jour − réserve visée`, sans
  descendre sous le bas de la plage tant qu'il reste sûr (marge de prudence : la réserve visée moins un
  point, 2 au plus, `coachDirectGuardRir`) ; en semaine de charge, une plage sans part de test s'étend
  comme en 0.1 quand elle est devenue trop facile.
- **Plage hors de portée** (semaine de charge : le bas de la plage ne laisse pas la réserve visée ; toute
  semaine : il n'est plus sûr) : séries fractionnées — moins de répétitions par série (chaque série garde
  la réserve du bloc), plus de séries, pour approcher le travail écrit : au plus le double des séries (trois
  au moins permises), un total qui vise le bas de la plage écrite à moins d'une série près
  (`adapt.reps_down`). Aucune série n'est ajoutée en semaine servie telle quelle (§ 11.1), après un échec, sur
  une zone douloureuse, un jour de bilan bas, quand le bloc écrit une technique, ni tant qu'aucune série n'a
  mesuré le maximum de l'exercice (28 jours au plus). La réserve est calculée sur la première série ;
  l'effort affiché des suivantes tient compte de la fatigue prévue. Séries fractionnées
  et séries classiques se valent pour la force (Jukic et al. 2021) ; aucun essai chez des débutants limités
  à 1 à 5 répétitions : choix raisonné.
- **Effort affiché** : celui du bloc ; quand la quantité servie laisse au moins un point de plus ou de moins
  que la cible du bloc, l'effort attendu est affiché à sa place (un maintien : toujours).
- **Exercice assisté** (élastique, appui des pieds, machine : `assiste` du catalogue). La plage du bloc est
  gardée ; la progression passe par l'assistance, que l'athlète note en charge négative. Quand une série
  repère a montré au moins 2 répétitions de réserve de plus que visé au haut de la plage
  (`coachAssistGapRir` ; ACSM 2009 : une à deux répétitions de plus que la cible), le moteur conseille un cran
  d'assistance de moins (`adapt.flames_below_target` sur la prescription) ; un cran de plus
  (`adapt.flames_above_target`) seulement sur ce que l'athlète a fait : échec, ou bas de la plage manqué.
  Quand l'assistance du journal change, la capacité attendue se décale d'un cran (× 0,75,
  `coachAssistStepShare` ; l'assistance d'un élastique ne se lit pas en kg, McMaster et Cronin 2010) et
  l'incertitude grandit.
- **Maintiens.** La durée écrite (ou la part du maintien maximal mesuré) est servie, au plus 75 % du
  maximum du jour (`coachHoldMaxShare` ; R4-F2 : maintiens à 50–70 % du maximum, arrêt à la perte de ligne).
  En semaine de charge, une durée écrite sous 40 % d'un maximum mesuré depuis moins de 28 jours monte vers
  50 % de ce maximum (`coachHoldEasyShare`, `coachHoldUsefulShare`), par les paliers ci-dessous.
  Bras tendus et appuis : la durée d'une tenue ne monte pas de plus de 20 % (débutant), 15 % (intermédiaire)
  ou 10 % (avancé, élite) d'une séance à la suivante du même emplacement, et le temps total sous tension de
  l'emplacement non plus — quand le bloc ajoute une série, les tenues raccourcissent d'autant : un seul
  changement à la fois (`coachHoldRise`, R4-F9, R5-P22 ; `adapt.tendon_load`).
- **Figures** (`SkillLadder`). Le tableau des figures (`SkillBoard`) suit l'étape en cours : critère de
  passage (maintien ou répétitions, propreté, nombre de séances de suite, semaines minimales à l'étape)
  lu dans le journal. Une étape dont le passage n'est pas acquis n'est pas servie : l'étape en cours la
  remplace (`adapt.skill_hold`). Critère rempli : proposition de passage (`ProposalKind.load`, détail
  `skillStepUp`, `adapt.skill_step_up`). Mauvais jour (deux premières lignes sous le plancher de
  propreté) : l'étape plus facile est conseillée (`adapt.skill_step_down`). États rendus par la revue
  (`skillStates`, `summary.skills`).

### 11.6 Tests

- **Tentatives** (`one_rm`, `attempt_simulation`). Ouverture : la plus lourde barre réussie à 95 % de
  chances au moins (`attemptOpenerProbability`), au plus 93 % du maximum estimé du jour
  (`attemptOpenerShare`) et, quand une barre proche a été réussie dans les six dernières semaines, au plus
  cette barre (R3-P14 : le dernier lourd fixe la première barre). Deuxième : 80 % de chances. Troisième :
  50 % (70 % pour assurer un total, 35 % pour un record, où la barre visée du profil est tentée si elle
  garde 35 %). Jamais décroissantes ; après une barre manquée, la même barre ; saut minimal de la
  compétition respecté ; bilan bas, douleur ou échec récent : maximum du jour réduit de 2 % par cause (bilan bas : 2 % par palier du bilan)
  (`adapt.attempt_conservative`). La probabilité est celle d'une loi normale sur le `ln` de la charge,
  d'écart-type celui du maximum du jour (estimation et effet de jour, § 3). Les barres suivantes sont
  recalculées après chaque tentative (`adapt.attempt_next`). Une tentative réussie se lit « au moins une
  fois » ; sa note n'est pas lue comme une réserve mesurée.
- **xRM, série d'estimation, répétitions ou maintien maximal** : charge prévue pour les répétitions dites
  à la réserve du test ; séries ouvertes pour les maxima.
- **Pas de test un jour de bilan nettement bas** (hors jour d'échéance) : le test est retiré de la séance.
- **Résultats.** La revue rend `testResults` (`Benchmark` de source `guided_test`, ou `competition` le
  jour d'une échéance) que l'application reporte au profil, `summary.benchmarks` (tests et meilleures
  séries d'entraînement de moins de 3 en réserve), les estimations avec leur erreur standard
  (`summary.estimates`), la tolérance au volume apprise après trois semaines (`summary.volumeTolerance`)
  et les raisons `adapt.test_result`.

### 11.7 Jour d'échéance (`planEventDay`)

`EventDayPlan` : pour une compétition de force, par mouvement, le maximum estimé et son erreur standard,
l'échauffement (paliers à 40, 55, 70, 80 et 87 % de l'ouverture, `warmupSteps`) et les tentatives (règle
du § 11.6, objectif `secure_total`, `max_total` ou `record`, tentatives déjà faites prises en compte) ;
pour une épreuve de répétitions, l'objectif (`adapt.pacing`) et le rythme : première série à 65 % du
maximum (`pacingFirstShare`), puis des séries de la moitié de la précédente, 15 s de repos (choix
raisonnés, pratique de terrain du format).

### 11.8 Douleur, bilan du jour, récupération

- Douleur (R5-P23, R4-F11 ; limite 11 de 0.1 ; modèle de surveillance de la douleur : Silbernagel et al.
  2007) : de 0 à 3, rien ne change ; au-dessus de 3, aucune hausse sur la zone (I3), ni de charge, ni de
  répétitions, ni de séries (pas plus de lignes que la dernière séance de l'emplacement,
  `adapt.volume_down`) ; à 4 sur une contrainte moyenne, l'exercice est gardé avec 60 % de ses séries et un
  point de réserve de plus (`coachPainRegress`, `coachPainRegressSets`) ; à 5 et plus, il est retiré, et un
  remplaçant qui charge autant la zone aussi (`coachPainStop` ; 0.2.3 : 5 et 6 avant, voir § 11.16).
- Bilan nettement bas : une série de moins par exercice, charges réduites (§ 4.5), aucune série à moins
  de 3 répétitions en réserve (`coachLowDayRir`), pas de test, pas de technique qui mène près de l'échec.
  Sans charge, « pas de hausse » se compte par rapport à la dernière séance du même emplacement (séance
  lourde et séance au chrono d'un même exercice ne se comparent pas) ; après un échec non prévu ou sur une
  zone douloureuse, par rapport à la dernière séance de l'exercice (I2, I3).
- Récupération déclarée réduite (profil v3) : dite dans la séance, aucune hausse de volume proposée.

### 11.9 Alerte de surmenage

Chaque séance d'un mouvement principal qui mesure la capacité (§ 11.4) laisse une performance : la capacité
estimée du jour. Quand deux séances mesurées de suite restent au moins 5 % sous la précédente
(`coachOverreachDrop`), les trois en 21 jours au plus (`coachOverreachSpanDays`), le moteur sert pendant
7 jours (`coachOverreachDays`) 40 % de lignes en moins sur ce mouvement (`coachOverreachCut`, une ligne au
moins retirée, jamais la dernière ; le gel des lignes d'une zone douloureuse s'applique d'abord, § 11.8),
intensité gardée, en semaine de charge seulement (les semaines déjà
allégées et les tests sont servis tels quels) ; raisons `adapt.volume_down` (`sets`) et `adapt.fatigue_high`
(`readiness` : part de la séance de référence tenue par les deux séances de l'alerte). La séance d'alerte
devient la nouvelle référence : pas d'alerte en chaîne.

Sources : la baisse durable de performance est le seul indicateur fiable du surmenage en musculation, sans
seuil publié (Grandou et al. 2020) ; variation test-retest médiane d'un 1RM de 4,2 % (Grgic et al. 2020) ;
décharge d'environ 7 jours par la baisse du volume, intensité gardée, dès que l'athlète est fatigué (Bell et
al. 2023) ; baisse de volume de 41 à 60 % à l'affûtage (Bosquet et al. 2007). Le seuil et la règle des deux
séances sont des choix raisonnés ; aucun essai ne porte sur une décharge déclenchée par la performance.

### 11.10 Invariants du mode coach

Vérifiés depuis le journal, le bloc et la sortie (`checkCoachSession`, `test/support.dart`) sur 10 240
journaux aléatoires aux champs de 0.4.0, les 17 programmes street du banc sous les trois modèles de vérité
et les programmes à techniques injectées ; I2 à I8 (§ 7) valent aussi.

| # | Invariant |
| --- | --- |
| C1 | Hors calibrage et hors test, la charge de tête d'un mouvement principal n'excède jamais la plus grande de : la charge écrite par le bloc ; +10 % (ou un cran) de la plus lourde charge de l'exercice au journal |
| C2 | Jamais plus de séries que le bloc n'en écrit ; seule exception, les séries fractionnées (§ 11.5) : lignes fixes plus courtes que le bas de la plage écrite, au plus le double des séries (trois au moins permises), total sous le bas de la plage écrite plus une série |
| C3 | Une technique n'est servie qu'au niveau d'expérience qui y donne accès |
| C4 | Les tentatives d'un test de maximum ne décroissent jamais |

Tests des règles ajoutées au calibrage (`test/coach_rules_test.dart`) : alerte de surmenage (déclenchement,
retour au niveau, séances trop espacées, deux passages le même jour) ; plage servie à la réserve du bloc
(street_13, boucle complète) ; séries fractionnées (street_03, boucle complète).

### 11.11 Paramètres du mode coach

| Paramètre | Valeur | Source |
| --- | --- | --- |
| `coachCorridorDown`, `coachCorridorUp` | 5 % ; 7,5 % | R2-P3 (±2,5 % par point d'écart) ; bornes : choix raisonné |
| `coachCorridorWiden`, `coachCorridorUpMax` | 2,5 % ; 15 % | choix raisonné |
| `coachRise` (par niveau), `coachHistoryRiseFactor` | 10 %, 5 %, 5 %, 5 % ; 0,5 | R5-P22 (garde-fous de progression) ; choix raisonné |
| `coachWorstSetSlack`, `coachBreachRir`, `coachEasyGapRir` | 1,5 ; 1 ; 2 répétitions | R2-P3 (écart d'un point) ; choix raisonné |
| `coachBreachCut`, `coachBreachCutMax` | 2,5 % ; 5 % | R2-P3 |
| `coachCensorRir`, `coachCurveRir` | 2 ; 3 répétitions | Zourdos et al. 2021, Halperin et al. 2022, Steele et al. 2017 |
| `coachProbeDays`, `coachTopProbeReps` | 14 jours ; 3 répétitions | choix raisonné (APRE : Mann et al. 2010) |
| `coachHoldMaxShare`, `coachHoldRise` | 75 % ; 20 %, 15 %, 10 %, 10 % | R4-F2, R4-F9, R5-P22 ; choix raisonné |
| `coachHoldRiseSlackSeconds` | 1 s | choix raisonné (une tenue courte peut toujours gagner une seconde) |
| `coachStopMinSets`, `coachEasyStepShare` | 2 séries ; 5 % | choix raisonnés |
| `coachHoldEasyShare`, `coachHoldUsefulShare` | 40 % ; 50 % | R4-F2 ; Oranchuk et al. 2019 ; choix raisonné |
| `coachOverreachDrop`, `coachOverreachDays`, `coachOverreachSpanDays`, `coachOverreachCut` | 5 % ; 7 jours ; 21 jours ; 40 % | Grandou et al. 2020, Grgic et al. 2020, Bell et al. 2023, Bosquet et al. 2007 ; seuil : choix raisonné |
| `coachAssistGapRir`, `coachAssistStepShare`, `coachAssistStepSd` | 2 répétitions ; 0,75 ; 0,25 | ACSM 2009 (transposé) ; choix raisonné |
| `coachBackoffMinDrop` | 5 % | choix raisonné (R2-P6) |
| `coachNewExerciseShare`, `coachOverloadFragileMax` | 60 % ; 100 % | R5-P22 ; choix raisonné |
| `coachBreakDays`, `coachBreakSets` | 14 jours ; 80 % | choix raisonné (R5-P7) |
| `coachDirectGuardRir`, `coachLowDayRir` | 2 ; 3 répétitions | choix raisonné ; règle du programme |
| `coachEventNearDays`, `coachEccentricEventDays` | 14 ; 10 jours | R3-P14 ; R2-P17 |
| `coachPainRegress`, `coachPainStop`, `coachPainRegressSets` | 4 ; 5 ; 0,6 | R5-P23, R4-F11 ; Silbernagel et al. 2007 (douleur pendant l'effort sous 5/10, 0.2.3) |
| `attemptOpenerShare`, probabilités des tentatives | 93 % ; 95 %, 80 %, 50 % (70 %, 35 %) | pratique de terrain de la force athlétique (ouverture qu'on réussit « un mauvais jour ») ; choix raisonné |
| `attemptLowHealthShare`, `attemptRecentDays` | 2 % ; 42 jours | choix raisonné |
| `skillSessions`, `skillDownSessions`, `skillTenureWeeks`, `skillPainMax` | 3 ; 2 ; 2, 8, 18, 30 semaines ; 3 | R4-F9 (délais par levier) ; contrat des échelles |
| `pacingFirstShare`, `pacingNextShare`, `pacingRestSeconds` | 65 % ; 50 % ; 15 s | choix raisonné |
| `biasLearnRate`, `biasLearnRir`, `biasLearnMaxStep`, `biasMin`, `biasMax` | 0,25 ; 3 ; 0,1 ; 0 ; 0,6 | choix raisonné (Halperin et al. 2022 pour l'ordre de grandeur du biais) |
| `toleranceMinWeeks`, `trainingSetMaxReps`, `trainingSetMaxRir` | 3 ; 6 ; 3 | choix raisonné |

### 11.12 Limites du mode coach

1. **Le moteur ne réécrit pas le programme.** Volume et fréquence d'un mouvement, répartition dans la
   semaine, choix des exercices, seuils d'ouverture d'une étape de figure, forme du bloc de réalisation :
   il les sert tels que `kalis_plan` les écrit, et n'agit que sur les charges, les répétitions, les durées,
   le nombre de lignes (à la baisse) et les techniques. Les corrections que le panel demande encore portent
   pour l'essentiel sur ce texte (`docs/CALIBRAGE_CA1.md`).
2. **Athlètes simulés.** Tout a été mesuré sur trois modèles de vérité écrits pour ce lot (A, B, C), jamais
   sur des journaux réels ; l'assistance d'un élastique y est un cran abstrait.
3. **Alerte de surmenage** : seuil et durée sans validation publiée (§ 11.9) ; un record déclaré trop haut
   au profil peut ressembler à une baisse pendant les premières séances mesurées.
4. **Séries fractionnées** : extrapolées d'essais avec charges chez des pratiquants entraînés.
5. **Notes d'effort** : loin de l'échec, le moteur ne sait que ce que l'athlète montre (série repère, série
   arrêtée, test) ; un athlète qui ne va jamais près de sa limite reste estimé par défaut, prudemment.
6. **Niveau d'expérience absent du profil** : l'athlète est servi comme un intermédiaire (couloir, techniques
   de ce niveau) ; choix de ce lot, à revoir avec l'application.
7. **Constats de la relecture indépendante non corrigés** (`docs/VALIDATION.md`, § 9) : le conseil
   d'entre-séries ne reprend pas tous les ajustements de la séance un jour de bilan bas ; la règle
   « répétitions écrites non atteintes » ne voit pas un manque sur une série de tête plus courte que les
   séries allégées ; la série repère et la série de tête repère n'ont pas exactement les mêmes verrous ;
   l'intensité rendue d'une variante garde la part écrite quand la charge d'entrée est réduite.
8. **Négatives et tempo** : la durée d'une descente n'est pas pilotée ; une négative écrite à dose fixe est
   servie telle quelle.

### 11.13 Références du mode coach

Vérifiées sur le texte ou le résumé ; « (résumé) » : résumé seul.

- Bell L. et al. (2022). Coaches' perceptions, practices and experiences of deloading in strength and
  physique sports. *Front Sports Act Living* 4:1073223. (résumé)
- Bell L. et al. (2023). Integrating deloading into strength and physique sports training programmes: an
  international Delphi consensus approach. *Sports Med Open* 9:87.
- Bosquet L. et al. (2007). Effects of tapering on performance: a meta-analysis. *Med Sci Sports Exerc*
  39(8). (résumé)
- Coyne J.O. et al. (2015). Reliability of pull up and dip maximal strength tests. *J Aust Strength Cond*
  23(4). (résumé)
- Grandou C. et al. (2020). Overtraining in resistance exercise: an exploratory systematic review and
  methodological appraisal of the literature. *Sports Med* 50(4). (résumé)
- Jukic I. et al. (2021). The effects of set structure manipulation on chronic adaptations to resistance
  training: a systematic review and meta-analysis. *Sports Med* 51(5). (résumé)
- McMaster D.T., Cronin J. (2010). Quantification of rubber and chain-based resistance modes. *J Strength
  Cond Res* 24(8).
- Oranchuk D.J. et al. (2019). Isometric training and long-term adaptations: effects of muscle length,
  intensity, and intent. *Scand J Med Sci Sports* 29(4).
- Robinson Z.P. et al. (2024). Exploring the dose-response relationship between estimated resistance
  training proximity to failure, strength gain, and muscle hypertrophy. *Sports Med* 54(9). (résumé)
- Senna G. et al. (2009). Influence of two different rest interval lengths in resistance training sessions
  for upper and lower body. *J Sports Sci Med* 8(2).
- Willardson J.M., Burkett L.N. (2006). The effect of rest interval length on the sustainability of squat
  and bench press repetitions. *J Strength Cond Res* 20(2). (résumé)

Les autres sources du calibrage (séries repère, lecture des notes, tendons, douleur) sont listées, avec ce
qui a été lu de chacune, dans `docs/CALIBRAGE_CA1.md`.

### 11.14 Simulateur : changement de profil en cours de saison (0.2.1, lot CX)

Une correction en 0.2.1 : `applyProposal` garde les champs du contrat 0.4.0 (intention de semaine, etc.) d'un bloc qui porte une intention ; un bloc de 0.1 est reconstruit comme avant. Le simulateur (`simulation.dart`) prend une liste de
`ProfileChange` (`week`, `apply`, `replan`, `label`) : au début de la semaine `week`, le profil simulé
devient `apply(profil)` (par exemple une échéance avancée de deux semaines) ; si `replan` est vrai, le bloc
en cours s'arrête à la fin de la semaine précédente et le bloc suivant est écrit par `nextBlock` sur le
profil changé, avec le résumé d'adaptation du moment. `SimRun.changes` garde la semaine et le libellé de
chaque changement. Sans changement, la simulation suit celle de 0.2.0 ; seuls diffèrent les blocs au contrat
0.4.0 après une proposition appliquée (correction d'`applyProposal`). Utilisé par le mode saisons de `kalis_bench` 0.2.0.

### 11.15 Mode coach : douleur qui dure, sous-dosage, tests reportés (0.2.2, lot CX correction 1)

Corrections du mode coach faites sur la relecture du pilotage de CX, le panel et une relecture documentée
indépendante (croisement avec `kalis_plan` 0.2.2). Le mode 0.1 est inchangé (mêmes séances à l'octet près,
version du moteur mise à part : la lecture des tests sans mode coach suit 0.2.1).

- **Douleur qui dure ou qui revient** (`PainState`, `model.dart`) : signalements datés par zone ; arrêt
  quand la zone reste à 3/10 ou plus deux semaines (`painPersistMin`, `painPersistDays`), à 5/10 ou plus
  plus d'une semaine (`painStrongMin`, `painStrongDays`), ou revient dans les douze semaines après un
  épisode réel (`painRecurDays`) ; un épisode tolère deux semaines entre deux signalements
  (`painEpisodeGapDays`) ; l'arrêt se lève après deux semaines sans signalement au-dessus de 2/10
  (`painResumeDays`). Pendant l'arrêt, les mouvements qui provoquent la zone (`coachPainStopHits` de
  `kalis_plan`) sont retirés des séances et la séance porte `adapt.pain_persistent` ; la revue le signale
  (en mode coach, seul l'arrêt le fait) ; la douleur affichée est celle du dernier signalement récent.
- **Sous-dosage** : chaque série est jugée contre sa propre réserve visée ; une série au ressenti qui
  suppose moins de 90 % de la prédiction se lit comme une borne basse, et la baisse attend une deuxième
  mesure concordante, une autre séance, dans les quatre semaines (`ExerciseTrack.lowProbeDay` ; une mesure
  conforme efface la borne en attente) ; cran d'élastique retiré après deux séances au haut de la plage à
  charge et plage égales, ou une première série dite deux répétitions plus facile que visé.
- **Tests** : retirés un jour de bilan bas (une baisse de 1 sur 5 ou plus) et refaits à une séance suivante
  de la semaine, 48 h après au moins, un bon jour sans douleur au-dessus du seuil ni zone à l'arrêt, avec le
  matériel du lieu du jour et seulement pour une étape de figure acquise. Hors mode coach, la lecture des
  tests (jours bas, milieu des tentatives) suit 0.2.1.
- **Charges** : tentatives (ouverture 91 %, deuxième +5 % au plus, troisième +3 % au plus, +5 kg de
  charge externe au plus ; la meilleure barre entre la réussie et la manquée est reportée) ; après une
  série manquée non voulue, −7,5 % de charge totale, gardé sur les séries suivantes de la séance ; simple
  d'entraînement à 92 % du maximum estimé au plus (85 % un jour de bilan bas) ; semaine allégée ou de test :
  jamais plus lourd que la charge écrite.
- **Tenues** : la borne de hausse d'une tenue d'une séance à la suivante (et celle du temps total de
  l'emplacement) laisse toujours servir 55 % du meilleur maintien mesuré (`coachHoldMaxFloorShare`) :
  après un test qui saute, la tenue écrite à 55-65 % du test n'est plus servie au niveau des semaines
  d'avant. (Le meilleur maintien est celui du suivi, toutes séries comprises : il ne baisse pas après un
  arrêt ; la tenue servie reste bornée par la cible du programme.)

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Arrêt | 3/10 × 14 jours ; 5/10 × 7 jours ; retour sous 84 jours | Coombes et al. 2015 ; NHS (consulter après deux semaines) ; choix prudents |
| Levée | 14 jours à 2/10 au plus | relecture documentée CX ; Silbernagel et al. 2007 |
| Écart dans un épisode | 14 jours | choix raisonné (durée du seuil de persistance) |
| Borne basse | < 90 % de la prédiction ; deuxième mesure sous 28 jours, autre séance | Zourdos et al. 2021 ; Steele et al. 2017 ; choix raisonné |
| Échec non voulu | −7,5 % de charge totale, séries suivantes comprises | Helms et al. 2018 (autorégulation) |
| Tentatives | 91 % ; +5 % ; +3 % ; +5 kg au plus | Travis, Zourdos, Bazyler 2021 |
| Plancher de la borne des tenues | 55 % du meilleur maintien | R4-F2 (50 à 70 % du maximum) ; relecture documentée CX |

Invariants testés : `test/coach_rules_test.dart` (arrêt durable, fort, retour, levée, douleur affichée,
tenue servie à 55 % du test au moins après le test) ;
`test/coach_test.dart` (sauts de tentatives) ; propriétés (`test/properties.dart`) : aucun exercice exclu
par une douleur du jour n'est prescrit ; un test servi un jour de changement de lieu se fait avec le
matériel de ce lieu.

### 11.16 Mode coach : conduite sous douleur, maintien récent, assistance, affûtage (0.2.3, lot CA2, partie 0)

Croisement avec `kalis_plan` 0.2.2 (reprise graduée écrite par le programme, CX correction 1). Le mode 0.1 est
inchangé (séances identiques à l'octet près ; seul le texte de version change dans `docs/PROPRIETAIRE.md`).

- **Reprise graduée conduite séance par séance** (`lib/src/pain_return.dart`, sécurité). Une zone est en reprise
  quand le bloc l'écrit (notes `pain_return` et `pain_return_item` de `kalis_plan`) ou quand son arrêt s'est
  levé depuis moins de douze semaines (`PainState.liftedOn`). Les mouvements qui la provoquent
  (`coachPainStopHits`) sont servis à la dose écrite au plus (`ExerciseRun.doseCapped` : ni séries
  ajoutées, ni plage étendue, ni tenue allongée, ni série repère), à 3 répétitions en réserve au moins, sans
  hausse dans la séance (conseil d'entre-séries compris : `adapt.load_held`, cause `pain_return`).
  - **Le palier suit la douleur** : il recule d'un cran (−10 % du volume habituel, 40 % au moins ; séries
    réduites d'autant, charge vers 67,5 % + 2,5 % par palier) quand, sur les sept derniers jours, la gêne de
    la zone a dépassé 2/10, ou que les deux derniers signalements montent (pas revenue au niveau d'avant le
    lendemain), ou que la pire gêne de la semaine dépasse celle de la semaine d'avant ; la zone compte
    alors comme douloureuse (aucune hausse, I3). C'est la règle écrite par le programme (« chaque palier se
    garde seulement si la gêne reste à 2 sur 10 au plus pendant la séance et revient à ton état habituel le
    lendemain matin, sans hausse d'une semaine à l'autre ») ; modèle de surveillance de la douleur de
    Silbernagel et al. 2007 (gêne ≤ 5/10 pendant l'effort, disparue le lendemain matin, pas de hausse d'une
    semaine à l'autre : le programme retient 2/10, plus prudent). Une gêne de 3/10 ou plus qui revient
    relance l'arrêt (retour d'un épisode réel, § 11.15).
  - **Jamais de levée sur une semaine qui n'est pas de charge** : un arrêt qui se lèverait pendant un
    allègement, un affûtage, un test, une compétition ou une transition est gardé jusqu'à la première semaine
    de charge ou d'introduction (`PainReturn.held`, `adapt.pain_persistent`) ; une levée ne se fait jamais en
    cours de séance (l'arrêt se décide au début de la séance, le conseil ne rend jamais un mouvement retiré).
  - **Arrêt levé au milieu d'un bloc qui écrit encore les mouvements provocants** (bloc écrit avant l'arrêt) :
    reprise propre au moteur, 50 % des séries écrites à la première semaine de charge, +10 % par semaine de
    charge (une semaine allégée garde la part de la dernière semaine de charge), charge au plus
    67,5 % + 0,25 × (part − 50 %) du 1RM (`returnPct`) : mêmes paliers que `kalis_plan` (Soligard et al. 2016 :
    hausses hebdomadaires sous 10 %). Une semaine compte quand la levée en laisse au moins la moitié ; les
    semaines de charge, d'introduction et de maintien comptent. Un mouvement touché par deux zones prend la
    part la plus basse (celle du bloc ou celle du moteur). Les séries s'arrondissent vers le bas (une au
    moins). Une reprise écrite par le bloc vaut pour tout le bloc (la note `pain_return` code des paliers,
    pas des semaines) : ses tests sur la zone sont reportés au bloc suivant.
  - **Tests reportés** : un test n'est jamais servi sur une zone douloureuse au-dessus du seuil (il est retiré,
    pas remplacé : `adapt.pain_reported`), ni sur une zone en reprise ou dont l'arrêt est gardé ; le report à
    une séance suivante de la semaine (§ 11.15) les exclut aussi (contre-indication d'un test maximal en
    présence de douleur : NSW Agency for Clinical Innovation 2022, guide du test 1RM).
  - **Appui à prise neutre** : un poignet douloureux (sous 5/10, `coachPainStop`) ou à l'arrêt n'efface
    plus la poussée quand une variante en appui neutre existe (barres parallèles, parallettes, poignées,
    anneaux : `coachPainProvokes` de `kalis_plan`), faisable avec le matériel du jour et qui ne provoque
    aucune zone à l'arrêt ni gardée ; sinon le mouvement est retiré. Seul le poignet a cette variante : les
    autres zones à l'arrêt gardent la règle du § 11.15 (retrait).
  - **Appui du poignet** : quand le poignet est sensible (gêne déclarée au profil ou antécédent récent, gêne
    signalée depuis deux semaines, arrêt ou reprise), les appuis qui le provoquent sont servis à la dose
    écrite par le bloc au plus (`doseCapped`) : le moteur n'ajoute ni séries fractionnées, ni tenue allongée
    vers la moitié du maximum, ni répétitions au-delà de l'écrit. Le budget d'appui lui-même est écrit par
    `kalis_plan` (CP2, partie 0) ; principe : limiter la charge d'appui du poignet et la progresser
    graduellement (revue « Wrist pain in gymnasts », Curr Sports Med Rep 2017, résumé).
- **Meilleur maintien récent** (`ExerciseTrack.sessionBests`, `recentBestOf`) : le plancher de la borne de
  hausse des tenues (55 % du meilleur maintien, § 11.15) se calcule sur la meilleure tenue des séances
  depuis la dernière coupure d'au moins 14 jours (arrêt, pause) et dans les 28 jours (`coachHoldBestDays`) ;
  sans séance récente, pas de plancher : le plancher ne vient plus d'un record d'avant un arrêt (la borne de
  hausse d'une séance à la suivante reste comptée depuis la dernière séance de l'emplacement). 28 jours : choix raisonné (perte de force mesurable à l'arrêt de l'entraînement, plus
  marquée avec la durée : Bosquet et al. 2013, résumé ; le seuil en semaines n'y est pas chiffré).
- **Cran d'assistance** (élastique) : un cran de moins seulement après deux séances de suite au même cran
  au haut de la plage (ou première série dite deux répétitions plus facile) — la série compte même quand
  la plage écrite monte d'une semaine à l'autre (panel de la boucle 5, `street_01` : la série repartait à
  zéro à chaque nouvelle plage) —, et sept jours au moins
  après le dernier changement de cran (`coachAssistMinDays`, `ExerciseTrack.assistDay` ; le panel demande
  à la fois de ne pas changer trop souvent et de ne pas attendre trop longtemps) ; un cran de plus seulement
  après un échec ou le bas de la cible servie manqué deux séances de suite au même cran
  (`SlotMark.missed` ; une cible abaissée par un verrou — douleur, bilan bas — puis tenue n'est pas un
  manque). L'élastique ne change plus dans un sens puis dans
  l'autre d'une séance à la suivante (relecture documentée, manche 4, `street_01`). Source : ACSM 2009, règle
  « 2 pour 2 » : hausse de charge quand l'athlète fait une à deux répétitions de plus que visé sur deux
  séances consécutives (texte de l'énoncé de preuve).
- **Tentatives après un affûtage** (`coachTaperGain`, 2 %) : le jour qui suit une semaine d'affûtage ou de
  compétition (ou pendant), le maximum du jour des tentatives compte le gain d'affûtage — le bas de la
  fourchette mesurée chez les powerlifters (Travis et al. 2020 : +1,8 à 6,4 % selon le mouvement). Raison :
  tentatives réussies à 97 % et meilleure barre à 94 % du maximum réel au banc (0.2.2), quand les
  compétitions montrent environ 82 à 91 % de deuxièmes barres et 45 à 68 % de troisièmes réussies (Darragh
  et al. 2025, 93 333 athlètes) ; l'échelle des barres reste celle du § 11.15 (91 % ; +5 % ; +3 % ; Travis,
  Zourdos et Bazyler 2021).
- **Estimation moins prudente** (relecture documentée de la partie 0 : estimations baissées par des séries
  faciles ou arrêtées tôt, tentatives à 90-92 % du maximum du jour) :
  - une série lourde (répétitions faites + réserve dite ≤ 8, `coachHeavyBoundReps`) lue comme une borne
    basse compte la réserve corrigée du biais de note appris, comme une mesure : la réserve se dit mieux
    près de l'échec et sur les séries courtes (Halperin et al. 2022 : sous-estimation moyenne d'environ une
    répétition, prédiction moins juste sur les séries longues) ; une série plus longue garde la réserve dite
    telle quelle ;
  - une série arrêtée sous le bas de sa cible suit la règle de la série au ressenti (§ 11.15, CX
    correction 1) : une seule mesure nettement sous l'estimation (moins de 90 %) se lit comme une borne
    basse, et la baisse attend une deuxième mesure concordante, une autre séance, dans les quatre semaines
    (avant : la baisse était immédiate) ;
  - les bornes de santé (hausse d'une séance à la suivante, § 11.15) se comptent depuis la dernière séance
    d'une semaine de charge de l'emplacement (`SlotMark.loadedTop`, `loadedLoadKg`) : une semaine allégée,
    de test ou d'affûtage ne fait plus repartir la hausse d'une séance volontairement légère (relecture
    documentée, `street_08` : dips plafonnés après la transition).
  Mesure au banc (17 profils × 8 scénarios × 3 modèles × 4 graines) : meilleure barre du jour de
  l'échéance 94,4 → 95,0 % du maximum réel, tentatives réussies 96,6 → 95,3 %, échecs non voulus 0,21 →
  0,23 %, écart d'effort 1,085 → 1,069, violations 0,0153 → 0,0135, aucune hausse sur zone douloureuse.
- **Douleur pendant l'arrêt et après** (relecture documentée du pilotage sur la manche 4 : `street_12`,
  dips au poids du corps servis à 5/10 et remplaçant lourd ; `street_10`, appuis gardés pendant des
  semaines de douleur à 3/10 et plus ; dips passés de 2 × 5 à 2 × 19 en une semaine d'affûtage juste après
  la douleur) :
  - à 5/10 et plus avant la séance, tout mouvement qui charge la zone (contrainte moyenne ou forte) est
    retiré, et un remplaçant n'est retenu que s'il ne la charge pas autant (`coachPainStop` 5, 6 avant ;
    allègement dès 4/10, `coachPainRegress`) : la douleur pendant l'effort ne doit pas atteindre 5/10
    (Silbernagel et al. 2007, modèle de surveillance de la douleur, lu sur une source secondaire) ;
  - pendant un arrêt (ou un arrêt gardé), les mouvements qui chargent la zone sans la provoquer
    (contrainte moyenne, appui à prise neutre) restent au premier palier de la reprise : moitié des séries
    écrites, 3 répétitions en réserve, aucune hausse, 67,5 % du 1RM au plus, jamais de test ; quand la
    douleur est encore à 3/10 ou plus dans la semaine après deux semaines d'arrêt
    (`coachStopEscalateDays`), ils sont retirés aussi (Silbernagel et al. 2007 : douleur jamais en hausse
    d'une semaine à l'autre ; la charge qui reste entretient la douleur) ;
  - poignet à l'arrêt : toute charge en extension du poignet est retirée (appuis au sol, sur les doigts,
    étirements en extension, échauffement compris : `street_01`, pompes sur les poignets à l'échauffement),
    et **toute charge externe d'appui dès le premier jour, prise neutre comprise** (dips lestés : relecture
    documentée du pilotage, `street_10`) ; un appui à prise neutre au poids du corps (parallettes, barres,
    poignées) reste au premier palier de la reprise (règle précédente), et une poussée en extension retirée
    est remplacée par un appui neutre au poids du corps à contrainte moyenne au plus, au premier palier
    (panel de la boucle 5 : la poussée du débutant et la planche sur parallettes disparaissaient pendant
    toute la douleur ; règle écrite par le programme : « parallettes ou poings tant que la gêne dépasse
    2/10 ») ; deux semaines d'arrêt sans baisse retirent aussi ces appuis (règle précédente) ;
  - aucun test tant que la zone a été signalée au-dessus de 2/10 dans la semaine (`coachReturnPain`) ;
  - une zone signalée au-dessus de 2/10 avant la séance compte comme « récente » dès cette séance (règle
    des +10 % ci-dessous), avant que l'arrêt soit inscrit ;
  - le renvoi vers un professionnel (`adapt.pain_persistent` sur la séance) figure à la première séance de
    l'arrêt, puis à la première séance de chaque semaine d'arrêt (suivi hebdomadaire) au lieu de chaque
    séance ; les mouvements retirés gardent leur raison ;
  - un remplaçant choisi pour une douleur du jour est servi loin de l'échec (3 en réserve), sans hausse, à
    70 % du 1RM au plus (`coachPainSubPct`, choix raisonné) ;
  - sur une zone à l'arrêt ou sortie d'un arrêt depuis douze semaines au plus, la quantité par série
    (répétitions ou secondes) d'un mouvement qui la charge monte de 10 % au plus d'une séance à la suivante,
    une unité au moins (`coachRecentRise` ; Soligard et al. 2016 : hausses de moins de 10 % par semaine),
    même quand le bloc écrit davantage (affûtage) ; ni série repère ni plage étendue sur ces mouvements.

| Paramètre | Valeur | Source |
| --- | --- | --- |
| `coachReturnStart`, `coachReturnStep`, `coachReturnFloor` | 50 % ; +10 % par semaine de charge ; 40 % | règle de `kalis_plan` (CX correction 1) ; Soligard et al. 2016 ; plancher : choix raisonné |
| `coachReturnPain` | 2 sur 10 | règle écrite par `kalis_plan` ; Silbernagel et al. 2007 (≤ 5, plus permissif) |
| `coachReturnRir` | 3 répétitions | règle de `kalis_plan` (reprise loin de l'échec) |
| `coachReturnWatchDays` | 84 jours | `painRecurDays` (choix raisonné) |
| `coachHoldBestDays` | 28 jours | choix raisonné (Bosquet et al. 2013) |
| `coachTaperGain` | 2 % | Travis et al. 2020 (bas de la fourchette) ; appliqué avant la première tentative |
| `coachAssistMinDays` | 7 jours | panel ; ACSM 2009 (« 2 pour 2 ») ; choix raisonné |
| `coachHeavyBoundReps` | 8 répétitions | Halperin et al. 2022 ; choix raisonné |
| `coachStopEscalateDays` | 14 jours | Silbernagel et al. 2007 ; durée de la règle d'arrêt de `kalis_plan` ; choix raisonné |
| `coachPainSubPct` | 70 % du 1RM | relecture documentée du pilotage (manche 4) ; choix raisonné |
| `coachRecentRise` | 10 % | Soligard et al. 2016 |

**Simulateur** (modèles de vérité B et C) : après un épisode de douleur réel (3/10 et plus), la zone reste
réactive douze semaines ; sa tolérance part de la plus grande de la moitié de la charge habituelle (séries de
la semaine sur la zone, moyenne mobile) et de la charge tenue la dernière semaine, puis suit la charge tenue
sans poussée ; une semaine au-dessus de 1,5 fois la tolérance (4 séries au moins) ramène une gêne de 2/10
pendant six jours, au-dessus du double une gêne de 3/10 (`SimRun.painFlares` ; choix raisonnés du modèle de
vérité, d'après Cook et Purdam 2009 et Soligard et al. 2016). Une « hausse sur une zone douloureuse »
(`painAggravations`) se compte désormais au-dessus de 3/10 (seuil du moteur, R5-P23). Les séries qui comptent
pour une zone sont celles des mouvements qui la provoquent (`coachPainStopHits`) ; la tolérance ne suit
que des semaines sans gêne et ne baisse jamais. Ces deux changements touchent aussi les mesures du mode 0.1
au banc : elles ne se comparent plus chiffre à chiffre à celles de 0.2.2.

Invariants testés (`test/coach_rules_test.dart`, groupe « reprise graduée conduite séance par séance ») :
levée datée ; maintien récent ; `street_12` avec douleur au coude, quatre graines, 20 semaines : aucun
manquement, aucune hausse sur la zone douloureuse, aucune ligne de reprise qui soit un test ou serve plus de
séries que le bloc ; `street_01` : aucun aller-retour d'élastique d'une séance à la suivante sans échec.

Références ajoutées (vérifiées sur le texte ou le résumé ; « (résumé) » : résumé seul) :

- ACSM (2009). Progression models in resistance training for healthy adults. *Med Sci Sports Exerc*
  41(3):687-708.
- Bosquet L. et al. (2013). Effect of training cessation on muscular performance: a meta-analysis. *Scand J
  Med Sci Sports* 23(3):e140-e149. (résumé)
- Darragh I.A.J. et al. (2025). Predicting a successful attempt in raw powerlifting: a nonlinear mixed
  logistic regression analysis. *J Strength Cond Res* (prépublication).
- NSW Agency for Clinical Innovation (2022). Guide to performing 1 repetition maximum strength assessment.
- Silbernagel K.G. et al. (2007). Continued sports activity, using a pain-monitoring model, during
  rehabilitation in patients with Achilles tendinopathy. *Am J Sports Med* 35(6):897-906. (résumé et
  source secondaire)
- Soligard T. et al. (2016). How much is too much? (Part 1) International Olympic Committee consensus
  statement on load in sport and risk of injury. *Br J Sports Med* 50(17):1030-1041.
- Travis S.K., Mujika I., Gentles J.A., Stone M.H., Bazyler C.D. (2020). Tapering and peaking maximal
  strength for powerlifting performance: a review. *Sports* 8(9):125.
- Travis S.K., Zourdos M.C., Bazyler C.D. (2021). Weight selection attempts of elite classic powerlifters.
  *Percept Mot Skills* 128(1):507-521. (résumé)
- Wrist pain in gymnasts: a review of common overuse wrist pathology in the gymnastics athlete (2017). *Curr
  Sports Med Rep* 16(5):322-329. (résumé)
