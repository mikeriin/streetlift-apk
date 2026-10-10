# Contrat de kalis_quest

Version 0.1.0 (lot G11, 02/10/2026). Ce document dit ce que le moteur de progression garantit, comment il
calcule, d'où vient chaque nombre et ce qu'il ne sait pas faire. Décisions du propriétaire appliquées :
D1.3, D3.8, D4.9, D7, D8 (`pipeline/gp/DECISIONS_GP.md`).

## 1. Rôle et dépendances

`KalisQuest` réalise `QuestEngine` (kalis_core 0.3.0). Dart pur : aucun import de Flutter ni de `dart:io`
dans `lib/`, aucune horloge (« aujourd'hui » est dans l'entrée), aucun hasard hors de la graine de
l'utilisateur, aucun stockage. Deux appels identiques rendent un résultat identique à l'octet près. Le
moteur ne produit aucun texte : des codes de raison du registre de `kalis_core`, des identifiants du
catalogue, des nombres.

Dépendances : `kalis_core` (types, catalogue, raisons) et `kalis_adapt`, dont il utilise directement la
lecture du catalogue (`ExerciseBook` : mode de capacité, fraction du poids du corps, zones sollicitées,
exercice écarté par une douleur) et les constantes (`AdaptParams.standard` : courbe répétitions ↔
charge, seuils de douleur, rétention, amortissement de la tendance). La règle des records est réécrite
ici (il faut la chronologie, que `kalis_adapt` ne rend pas) et testée égale à celle de `kalis_adapt`
sur les journaux types. Aucune ligne de l'ancien système de
progression de l'application n'est reprise.

## 2. API

| Méthode | Entrée | Sortie |
| --- | --- | --- |
| `evaluate(catalog, QuestInput)` | profil, journal complet, bloc en cours (facultatif), résumé d'adaptation de `kalis_adapt` (facultatif), état précédent, « aujourd'hui », graine de l'utilisateur, déclarations (facultatif) | `QuestOutcome` : état à stocker, niveau, attributs, rangs, objectifs, événements nouveaux, solde de Krédits, série de semaines, objectifs suggérés, records, `extras` |

**État** (`QuestState`, à stocker tel quel et à repasser à l'appel suivant) : registre d'XP et registre de
Krédits en ajout seul, quêtes en cours et récentes (35 jours), `lastEvaluatedOn`, et `data`, objet opaque
versionné (jour de démarrage, dernier jour clos, compteur de coffres, série, semaines closes, meilleure
valeur des attributs, meilleur rang, dernier record payé par exercice, jour où chaque objectif a été vu
pour la première fois, compteurs). Un état vide démarre le registre le jour de l'appel.

**Quand appeler** : à l'ouverture de l'application et après chaque séance. Le moteur traite tous les jours
écoulés depuis le dernier appel ; il n'a pas besoin d'être appelé chaque jour (§ 9, P5).

**Champs que l'application renseigne** (kalis_core 0.3.0) :

- `SessionRecord.plannedWorkSets` : séries de travail de la séance telle qu'elle a été affichée, après
  les ajustements du jour (bilan santé, douleur, lieu, temps). C'est la référence de la réalisation.
- `QuestInput.claims` : quêtes de récupération que l'utilisateur déclare faites aujourd'hui.
- `QuestInput.seed` : graine fixe par utilisateur (coffres, choix des quêtes).

**Séances comptées** : toutes sauf les séances « reprise » (D4.9), qui ne changent rien à aucun résultat.

## 3. Déroulement d'un appel

Le moteur lit le journal jusqu'à « aujourd'hui », puis traite un par un les jours qui suivent le dernier
jour clos :

1. il crée les quêtes qui commencent ce jour-là (§ 6) ;
2. il prend en compte les déclarations du jour ;
3. il **règle** les séances du jour : une séance est réglée quand elle est terminée, ou dès que son jour
   est passé ; elle ne l'est qu'une fois (son écriture d'effort au registre en fait foi) ;
4. il mesure l'avancement des quêtes et paie celles qui sont finies, puis les jalons d'objectif atteints
   ce jour-là, puis les passages de niveau ;
5. si le jour est passé, il le clôt : les quêtes échues expirent sans bruit ; le dimanche, la semaine est
   close (régularité, série de semaines).

Une séance ajoutée après la clôture de son jour est réglée à l'appel suivant (effort, records, coffre),
sans rouvrir les quêtes ni la semaine de ce jour-là. Une séance dont la date précède le démarrage du
registre n'est jamais réglée.

Les rangs, les attributs, les records, l'avancement des objectifs et `extras` sont recalculés à chaque
appel depuis tout le journal : ils ne dépendent pas de l'état, sauf les « meilleures valeurs » gardées.

## 4. XP, niveaux, Krédits

### 4.1 Registre

Chaque gain est une écriture datée, jamais négative, avec sa raison et une clé stable (séance, quête,
record, jalon, semaine). Une clé n'est écrite qu'une fois ; aucune écriture n'est modifiée ni retirée,
même si la séance qui l'a causée est supprimée ensuite. Le niveau est une fonction de la somme du
registre : **il ne redescend jamais** (D7.3).

**Remise à zéro** (D1.3) : le registre démarre vide au branchement. L'historique d'entraînement ne donne
aucun XP rétroactif — décision du lot : pas de « bonus de départ » (le paramètre existe, il vaut 0). En
revanche l'historique compte pour les records connus, les rangs et les attributs : refaire une ancienne
performance n'est pas un record, et les rangs acquis sont là dès le premier jour, sans événement.

### 4.2 Effort réel, rapporté au programme

`XP d'effort = arrondi(100 × réalisation × qualité) + bonus de combo`

- **Série de travail** : série non écartée, hors échauffement, avec une mesure non nulle. Le volume est
  compté en séries (Baz-Valle et coll., 2021 : le nombre de séries proches de l'échec est une mesure
  adéquate du volume).
- **Réalisation** = séries de travail faites / séries prévues, au plus 1. Séries prévues :
  `plannedWorkSets` s'il est renseigné. Sinon la référence est la séance du bloc que la séance désigne
  (`programRef`) ; pour une séance libre, la séance du bloc prévue ce jour-là ; à défaut, les séries
  habituelles (médiane des 8 dernières séances d'entraînement, à partir de 3 séances). Une séance
  terminée est rapportée à la moitié de cette référence (une séance allégée par le bilan santé et faite
  en entier vaut une séance complète), une séance inachevée à la référence entière (à défaut, 8). Sans
  aucune référence, une séance terminée est rapportée aux séries faites.
- **Qualité** = moyenne, sur les séries prévues, de la qualité de chaque série : 1 si la note est à la
  cible, au-dessus, ou jusqu'à 2 flammes en dessous ; 0,1 de moins par flamme supplémentaire sous la
  cible, plancher 0,7 ; 0,7 pour une série sans note alors qu'une cible existe ; 1 sans cible de
  flammes. La tolérance de 2 flammes (une répétition en réserve) est l'erreur ordinaire d'estimation
  des répétitions en réserve (Halperin et coll., 2022) : une note honnête un peu basse ne coûte rien, et
  noter plus haut que le ressenti ne rapporte presque rien (au plus 30 % d'une série).
  L'intensité est donc celle des flammes **rapportée à la cible du jour** : aller plus dur que prescrit
  ne rapporte rien de plus, une semaine de décharge ou une séance allégée rapporte autant qu'une semaine
  dure. C'est voulu : la proximité de l'échec n'améliore pas la force (Robinson et coll., 2024) et
  l'échec lui-même n'est pas supérieur pour l'hypertrophie (Refalo et coll., 2023 ; Grgic et coll.,
  2022) ; récompenser l'intensité absolue pousserait à dépasser la prescription.
- **Combo** : plus longue suite de séries consécutives dans la cible (note à ±1 flamme de la cible et
  série réussie), parmi les séries prévues ; à partir de 3, 1 XP par série, 10 au plus.

**Plafonds.** Une séance rapporte au plus 110 XP d'effort. Les séries au-delà du volume prévu ne comptent
ni pour la réalisation, ni pour la qualité, ni pour le combo, ni pour un record payé. Dans une semaine
civile, seules les premières séances, jusqu'au nombre de séances prévues au calendrier (jours du bloc,
sinon disponibilités du profil), sont récompensées ; les suivantes reçoivent une écriture à 0 XP
(`quest.xp_capped`, portée `week`) et ne donnent ni record payé, ni coffre, ni note, ni avancement de
quête ; leurs performances ne comptent ni pour les rangs, ni pour les objectifs. Une séance en plus peut
donc remplacer une séance manquée, jamais s'y ajouter.

**Séance écourtée** (réalisation sous 0,5) : payée pour ce qui est fait (`quest.xp_capped`, portée
`partial`), sans note ni coffre, et sans prendre la place d'une séance prévue : une séance abandonnée
après l'échauffement n'empêche pas de faire la séance du jour suivant. Dans tous les cas, l'XP d'effort
d'une semaine ne dépasse pas `séances prévues × 110` (portée `week_xp` quand ce plafond rogne une
séance).

**Séance de récupération** : une séance hors programme faite seulement de mobilité, de récupération ou de
marche ne reçoit pas d'XP d'effort et ne prend la place d'aucune séance prévue ; elle compte pour les
quêtes de mobilité et l'attribut Mobilité.

**Douleur.** Si le bilan santé de début de séance déclare une douleur, et que la séance contient un
exercice que la règle de `kalis_adapt` écarte pour cette douleur (contrainte forte ou travail direct de
la zone à partir de 4/10, contrainte moyenne à partir de 7/10), la séance est « faite malgré la
douleur » : écriture à 0 XP (`quest.no_reward_pain`), ni record payé, ni coffre, ni note, ni combo, ni
avancement de quête ; ses performances ne comptent ni pour les rangs, ni pour les attributs, ni pour les
objectifs (le record reste connu : c'est un fait). Elle ne compte pas parmi les séances faites de la
semaine, qui garde toutes ses séances prévues ; si la semaine n'est pas réussie sans elle, elle est en
pause, pas manquée (§ 8). La même douleur,
zone épargnée — ce que `kalis_adapt` prescrit —, donne la récompense entière. Une douleur signalée
pendant ou après la séance ne retire rien : la signaler ne doit rien coûter, sinon elle ne le serait
plus.

### 4.3 Régularité

À la clôture de chaque semaine :
`XP = arrondi(prévues / calendrier × faites / prévues × (60 + 40 × repos gardés / repos prévus))`

- **Calendrier** : jours prévus dans la semaine (jours du bloc, sinon disponibilités). **Prévues** : les
  mêmes, hors jours de pause déclarée ; une semaine en partie en pause paie donc au prorata.
  **Faites** : séances que le registre a réglées et comptées dans cette semaine (réalisation d'au moins
  0,5, ni douloureuses, ni en plus), au plus les prévues ; le jour de la semaine n'importe pas (une
  séance déplacée avant d'être faite compte). Le registre fait foi : une séance supprimée, ou dont la
  date est changée après son règlement, reste comptée dans sa semaine d'origine et nulle part ailleurs.
- **Jours de repos gardés** : jours sans séance d'entraînement, au plus les jours de repos prévus. Qui
  s'entraîne tous les jours perd cette part : le repos est récompensé, jamais puni.
- Semaine sans séance prévue (pause, pas de programme) : aucune écriture.
- Jalons de série (4, 8, 12, 26, 52, 78, 104, 156 semaines de suite) : 50 à 400 XP et 10 à 100 Krédits,
  une fois chacun par série.

### 4.4 Records

Mêmes records que `kalis_adapt` (meilleures répétitions, meilleure tenue, meilleur 1RM impliqué par une
série de 10 répétitions au plus notée 8 flammes ou plus), plus le temps équivalent sur 5 km et la plus
longue distance des séries de course. Par séance et par (exercice, nature), seule la meilleure valeur
compte. Un record paie `10 + 4 × gain en %`, au plus 30 XP, au plus 40 XP de records par séance, s'il
gagne au moins 0,5 % et s'il est établi dans le volume prévu d'une séance récompensée ; le gain est
mesuré depuis le dernier record payé (une séance supprimée puis refaite ne paie pas deux fois) ; le
premier record payé d'une séance donne 3 Krédits. Une première fois (aucune valeur avant) n'est pas un record : elle donne un événement, pas
d'XP.

### 4.5 Jalons d'objectif

Quatre jalons par objectif (§ 7). XP `30, 30, 30, 100` et Krédits `5, 5, 5, 25`, multipliés par
l'ambition de l'objectif : `écart relatif entre départ et cible / 10 %`, borné à [0,2 ; 1] (habitude :
`semaines / 8` ; compétence à débloquer : 0,5). Ne paient pas : un objectif déjà atteint à sa création ;
un objectif de performance de moins de 14 jours ; un jalon atteint avant que le moteur ait vu l'objectif
(objectif antidaté) ; les objectifs en double — un seul objectif paie par grandeur (exercice et mesure)
et un seul objectif d'habitude, le premier de la liste du profil. Plafond : 100 XP de jalons par semaine
civile, les Krédits suivant la même proportion.

### 4.6 Quêtes

Récompenses fixes par famille (§ 6), payées une fois quand la cible est atteinte.

### 4.7 Niveaux et prestige

Passer du niveau `n` au suivant coûte `5 × arrondi(32 × n^0,875 / 5)` XP (`n^0,875 = √√√(n⁷)`, calculé
avec la seule racine carrée : la table est la même sur toute machine). Niveaux 1 à 100 ; franchir le
niveau 100 fait passer un prestige : le niveau affiché repart à 1, la marque de prestige augmente, l'XP
total est gardé. Le rang global `prestige × 100 + niveau` ne baisse jamais.

### 4.8 Krédits (D7.7)

Gagnés, jamais repris, aucun usage dans ce pipeline. Origines : quêtes, coffres, niveaux (5 par niveau,
20 de plus à chaque dizaine, 200 pour un prestige), jalons (objectifs et série), records.

## 5. Avancements

### 5.1 Rangs par mouvement

Seize mouvements de référence, six rangs (Bronze, Argent, Or, Platine, Diamant, Élite), standards par
sexe et poids de corps : tables dans `docs/STANDARDS.md`, méthode et sources dans
`docs/STANDARDS_SOURCES.md`. `MovementRank.score` est en **points de rang** : 1 = Bronze … 6 = Élite, la
partie décimale mesure l'avancement vers le rang suivant ; `nextTierAt` est l'entier suivant. Le rang
vient de la meilleure performance qui compte (historique compris) — faite dans le volume prévu d'une
séance ni douloureuse ni en plus du programme — et **ne redescend jamais** (le meilleur rang atteint
est gardé dans l'état). Un passage de rang donne un événement `rank_up`. Les valeurs
lisibles (kg, répétitions, secondes, seuil suivant) sont dans `extras.ranks`, l'héritage des variantes
dans `extras.rankOf`.

### 5.2 Attributs

Six valeurs de 1 à 100, arrondies au dixième. `value` reflète le niveau actuel ; `best` est la plus
haute valeur rendue par un appel et ne baisse jamais. « Points » = points de rang du niveau **actuel**,
ramenés sur 100 (6 points = 100) : chaque performance est diminuée par la rétention — entière pendant
21 jours, puis 1 % de moins par semaine, plancher 70 % (constantes de `kalis_adapt` ; McMaster et coll.,
2013 : la force se maintient jusqu'à 3 semaines d'arrêt, puis décline). « Deux meilleurs » = moyenne des
deux meilleurs, ou 85 % du seul disponible.

| Attribut | Formule |
| --- | --- |
| Force | le plus grand de : deux meilleurs points des mouvements chargés de référence ; 60 % des deux meilleurs points de pompes, tractions, dips ; difficulté démontrée (poussée, tirage, jambes, porté) |
| Endurance | 70 % × le plus grand de (deux meilleurs points de pompes, tractions, dips et 5 km ; difficulté démontrée en cardio et conditionnement) + 30 % × cardio des 28 derniers jours rapporté à 150 min par semaine |
| Puissance | 50 % × le plus grand de (points du muscle-up, lesté ou non ; difficulté démontrée en explosif et figures dynamiques) + 20 % × Force + 30 % × séries explosives des 56 derniers jours rapportées à 10 par semaine |
| Technique | 60 % × le plus grand de (deux meilleurs points de front lever, planche, handstand, muscle-up ; 8 × difficulté de la figure la plus dure maîtrisée) + 40 % × justesse des flammes des 56 derniers jours (part des séries notées à ±1 flamme de la cible, pondérée sous 20 séries) |
| Mobilité | 50 % × jours de mobilité par semaine rapportés à 3 + 50 % × secondes de mobilité par semaine rapportées à 1 800, sur 28 jours |
| Régularité | 80 % × moyenne de faites / prévues sur les 12 dernières semaines closes hors pause + 20 % × série de semaines rapportée à 12 |

**Difficulté démontrée** : 6 points par niveau de difficulté du catalogue (1 à 10) de l'exercice le plus
dur pratiqué avec succès à dose suffisante (3 répétitions ou 5 secondes ; cardio : 10 répétitions,
5 minutes ou 1 km), diminués par la rétention ; au plus 60. Elle donne un attribut à qui ne pratique
aucun mouvement de référence. Une figure est maîtrisée à 2 secondes de tenue ou 3 répétitions. Une
séance faite malgré une douleur ne nourrit aucun attribut.

## 6. Quêtes

Génération déterministe : mêmes entrées et même graine, mêmes quêtes. Les quêtes d'un jour ne dépendent
que du journal antérieur à ce jour.

| Famille | Quand | Modèles | Récompense |
| --- | --- | --- | --- |
| Quotidiennes, jour d'entraînement | chaque jour prévu au calendrier, hors pause : la séance du jour, plus 1 ou 2 parmi les autres | `daily.session`, `daily.rated`, `daily.health_check`, `daily.in_target`, `daily.combo` | 10 XP, 2 Krédits |
| Quotidiennes, jour de repos | 1 ou 2 quêtes de récupération | `rest.sleep`, `rest.hydration`, `rest.walk`, `rest.mobility`, `rest.breathing` | 5 XP, 1 Krédit |
| Quotidiennes, jour de pause déclarée | 1 quête : récupération ; maladie ou blessure : récupération passive (`rest.sleep`, `rest.hydration`) | | 5 XP, 1 Krédit |
| Hebdomadaires | du lundi (ou du premier jour traité) au dimanche, s'il reste une séance prévue : 2 quêtes | `weekly.sessions`, plus `weekly.rated`, `weekly.health_checks` ou `weekly.mobility` | 40 XP, 10 Krédits |
| Koach | 1 par semaine, à tour de rôle : point faible, exercice écourté, jour le moins régulier | `koach.mobility`, `koach.accuracy`, `koach.full_sessions`, `koach.lagging_exercise`, `koach.weekday` | 30 XP, 10 Krédits |
| Campagne | par bloc : chapitre (les 3/4 des séances du bloc qui restent) et boss (une séance de la semaine de test, sinon la dernière séance du bloc, faite à 80 %) ; 7 jours de grâce après le bloc | `campaign.chapter`, `campaign.boss` | 100 XP et 40 Krédits ; 60 XP et 25 Krédits |

**Adaptées à l'utilisateur, jamais impossibles** : « séries dans la cible » demande 60 % de ses séries
habituelles (médiane des 8 dernières séances), au moins 3, au plus les séries à cible de flammes
prévues ce jour-là ; le combo demandé est son combo habituel ; les cibles hebdomadaires valent une de
plus que son habitude des quatre dernières semaines, sans jamais dépasser le programme. Une séance qui
met toutes ses séries prévues dans la cible remplit `daily.in_target` et `daily.combo`, même si la
cible de la quête dépassait le programme du jour (séance allégée). La quête de point faible prend à
tour de rôle l'un des trois attributs les plus bas pour lesquels une action existe. La quête
`koach.lagging_exercise` ne propose jamais un exercice qui sollicite une zone douloureuse suivie par
`kalis_adapt` : l'éviter est peut-être la bonne décision.

**Repos** : un jour de repos ou de pause ne propose que les modèles `rest.*` ; aucune quête ne demande
plus de séances ou de séries que le programme. Quand le résumé d'adaptation signale une douleur
persistante (3 séances de suite au-dessus du seuil, règle santé L13), les quêtes de performance
(`daily.in_target`, `daily.combo`, `koach.accuracy`, `koach.lagging_exercise`) ne sont plus proposées.

**Déclaratives** : les quêtes `rest.*` se déclarent (`QuestInput.claims`) le jour même ; `rest.mobility`
est aussi lue dans le journal (300 secondes de mobilité). Une quête d'entraînement ne se déclare pas.

**Avancement** : lu dans les séances récompensées de la fenêtre de la quête, dans la semaine où le
registre les a réglées. Une séance faite malgré une douleur ou au-delà du programme ne fait avancer
aucune quête ; une séance écourtée fait avancer les quêtes de séries, pas les quêtes de séances. Une quête échue expire sans événement ;
une quête terminée le reste.

## 7. Objectifs (D3.8)

**Performance** (`one_rm_kg`, `max_reps`, `max_hold_seconds`, `skill_unlocked`, `time_seconds`,
`distance_meters`) : la valeur suit les mêmes observations que les records (charge externe pour un 1RM ;
répétitions à une charge donnée par la courbe de `kalis_adapt` ; temps et distance par la formule de
Riegel). `baseline` : meilleure valeur connue à la création, faits bruts compris ; sans mesure, la
première mesure qui suit sert de départ (elle ne paie donc aucun jalon) ; une compétence jamais réussie
part de 0. Après la création, seules comptent les performances faites dans le volume prévu d'une
séance ni douloureuse ni en plus du programme. `fraction` : part de l'écart parcourue.

**Habitude** : séances faites depuis la création, au plus `sessionsPerWeek` par semaine civile ; cible
`sessionsPerWeek × weeks`.

**Jalons** : quatre étapes d'égale durée le long de la courbe prévue entre la création et l'échéance —
une tendance amortie de 3 % par semaine (celle de `kalis_adapt`). Les progrès ralentissent : les parts
de l'écart à atteindre sont donc au-dessus de 25, 50 et 75 % (29, 55, 78 % pour 12 semaines ; 41, 69,
87 % pour un an). Habitude : 25, 50, 75, 100 %. Découper en étapes proches suit Bandura et Schunk
(1981) : les sous-objectifs proches soutiennent la progression, les objectifs lointains seuls non.

**Prédiction** (`Prediction`) : niveau, erreur et tendance viennent de `kalis_adapt` quand le résumé
d'adaptation suit l'exercice (`adapt_damped_trend`), sinon du journal (`journal_damped_trend` :
meilleure valeur par semaine sur 12 semaines, pente de Theil–Sen, erreur par l'écart absolu médian, au
moins 3 semaines). La valeur à `h` semaines suit une loi normale de moyenne
`niveau + tendance × G(h)`, `G(h) = 0,97 × (1 − 0,97^h) / 0,03`, et d'écart-type
`√(erreur² + (σ_tendance × G(h))²)`, avec `σ_tendance = max(20 % de la tendance, erreur / 26)`.
`expectedOn` est le premier jour où la probabilité d'atteinte passe 50 %, `earliestOn` et `latestOn`
ceux où elle passe 10 % et 90 % (intervalle à 80 %) ; `latestOn` vaut l'horizon (3 ans) quand 90 %
n'est jamais atteint. `confidence` est la probabilité d'atteindre la cible à l'échéance. Habitude
(`habit_rate`) : rythme des 4 dernières semaines ; `confidence` y est la part des séances restantes
faisable d'ici l'échéance à ce rythme (1 quand il suffit), pas une probabilité.

**Retard** (`overdue`) : la médiane dépasse l'échéance, ou la cible est hors d'atteinte. Le moteur
propose alors la première date où la probabilité atteint 60 % (`suggestedDate`) et la cible atteinte à
60 % à l'échéance (`suggestedTarget`), avec la raison `quest.goal_late`. Quand la tendance ne donne ni
l'une ni l'autre (pas de tendance, tendance nulle ou négative), il propose une cible à mi-chemin si
l'échéance est à venir, sinon la même cible 8 semaines plus tard : un objectif en retard a toujours une
proposition.

**Suggestions** (`suggestedGoals`) : pour les deux exercices les mieux suivis par `kalis_adapt` (au moins
12 séries, tendance positive, pas déjà d'objectif), échéance à 8 semaines, cible = valeur atteinte avec
60 % de chances, arrondie en dessous au pas du matériel (la probabilité est donc d'au moins 60 %),
bornée par le gain plausible du niveau déclaré (15 %, 8 %, 5 %, 2 %), et au-dessus du record connu.
Sans résumé d'adaptation : aucune suggestion.

## 8. Mécaniques de plaisir (D8.1)

Événements `DelightEvent` rendus une fois, à l'appel qui règle la séance ou clôt la semaine.

| Mécanique | Règle |
| --- | --- |
| Record (`record`) | type, valeur, valeur précédente ; un par (exercice, nature) et par séance |
| Première fois (`first_time`) | exercice jamais fait avant ; 3 au plus par séance |
| Coffre (`chest`) | à chaque séance récompensée et faite : probabilité 15 %, garantie à la 8ᵉ séance sans coffre, 2 au plus par semaine civile ; contenu 10, 20, 50 ou 100 Krédits (60 %, 30 %, 9 %, 1 %) ; tirage déterminé par la graine et l'identifiant de la séance ; aucun achat, aucune perte |
| Série de semaines (`week_streak`) | semaine réussie : faites × 4 ≥ prévues × 3 ; semaine sans séance prévue, ou non réussie et touchée par une pause déclarée ou par une séance faite malgré une douleur : en pause, la série ne bouge pas (`quest.streak_paused`) ; sinon la série en cours repart de 0, la meilleure série est gardée ; aucun événement ne signale une semaine non réussie |
| Flamme | taille 0 à 10 selon la série (`extras.streak.flameSize`) |
| Fantôme (`ghost`) | par exercice, dernière et meilleure séance, série par série (`extras.ghost`) ; événement quand la séance fait mieux que la dernière fois |
| Note de séance (`session_grade`) | score = 60 × réalisation + 30 × justesse des flammes + 10 si un record ; S ≥ 90, A ≥ 70, B ≥ 50, C sinon ; séance allégée faite en entier = réalisation complète |
| Combo (`combo`) | séries consécutives dans la cible, à partir de 3 |
| Niveau, rang, jalon, quête | `level_up`, `rank_up`, `goal_milestone`, `quest_completed` |
| Récapitulatif, comparaisons, prédictions | `extras` (`docs/EXTRAS.md`) |

## 9. Invariants (testés)

Sur 10 240 journaux aléatoires (`test/properties.dart`) et dans les scénarios :

- **P1 — rien n'est retiré.** Le niveau global, l'XP total, le solde de Krédits, la meilleure série, la
  meilleure valeur des attributs et les rangs ne baissent jamais ; les registres rendus prolongent ceux
  reçus sans en toucher une écriture, même après la suppression d'une séance ; une quête terminée le
  reste.
- **P2 — déterminisme.** Même suite d'appels, même résultat à l'octet près.
- **P3 — export et import.** L'état relu depuis son JSON donne la même suite.
- **P4 — garde-fous.** XP d'effort ≤ 110 par séance et ≤ séances prévues × 110 par semaine, séances
  comptées ≤ séances prévues ; XP de jalons ≤ 100 par semaine ; 0 XP et aucune récompense pour une séance
  faite malgré une douleur ; un jour de repos ou de pause ne propose
  que de la récupération ; aucune quête ne demande plus que le programme.
- **P5 — cadence.** À entrées constantes (profil, bloc, graine) et séances terminées le jour même,
  appeler le moteur chaque jour ou une seule fois à la fin donne les mêmes registres, les mêmes quêtes
  et le même état (hors meilleure valeur des attributs, qui dépend des jours d'appel).
- **P6 — reprises.** Les séances « reprise » ne changent rien.
- **P7 — sorties valides** au sens de `kalis_core`, exercices cités présents au catalogue, codes de raison
  du registre.
- **Aucun message culpabilisant** : aucun événement ni aucune écriture pour une quête échue, une semaine
  non réussie ou une série qui repart.
- **Temps** : calcul complet depuis 3 ans de journal ≤ 200 ms en médiane sur la machine de contrôle
  (`test/timing_test.dart`, `docs/RYTHME.md`) ; non mesuré sur téléphone (`docs/VALIDATION.md`, § 9).

## 10. Paramètres

Tous dans `QuestParams`. Statut : **mesuré** (simulation de rythme ou ajustement), **référence** (source
citée), **repris** (constante d'un autre moteur), **choix raisonné** (ni mesuré ni publié : à faire
relire).

| Paramètre | Valeur | Statut et justification |
| --- | --- | --- |
| Courbe des niveaux | `32 × n^0,875` | mesuré : calée pour que les deux archétypes de repère (3 et 4 séances par semaine) soient en moyenne au niveau 10 en 3 semaines, 25 en 3 à 4 mois, 50 en 1 an, 100 en 3 ans et demi (`docs/VALIDATION.md`) |
| XP d'une séance | 100 (+ 10 de combo) | choix raisonné : unité de compte |
| Volume compté en séries | — | référence : Baz-Valle et coll., 2021 |
| Qualité relative à la cible, sans prime à l'échec | 1 jusqu'à −2 flammes, −0,1 par flamme, plancher 0,7 | référence pour le principe (Robinson 2024, Refalo 2023, Grgic 2022) et pour la tolérance (Halperin 2022) ; pente et plancher : choix raisonné, pour qu'une note gonflée ne rapporte presque rien |
| Série sans note | 0,7 | choix raisonné : la note sert à `kalis_adapt` |
| Tolérance « dans la cible » | ±1 flamme | choix raisonné (une demi-répétition en réserve ; Zourdos et coll., 2016 : l'estimation du RIR est fiable près de l'échec) |
| Régularité | 60 + 40 XP par semaine | choix raisonné ; part du repos : Meeusen et coll., 2013 (au moins un jour de repos par semaine, prévention du surentraînement) |
| Semaine réussie | 3/4 des séances | décision du propriétaire (lot G11) |
| Pause sans perte | — | décision du propriétaire ; Silverman et Barasch, 2023 (une série réparable démotive moins) ; Sharif et Shu, 2017 (une réserve de secours augmente la persévérance) |
| Records | 10 + 4 par %, ≤ 30, ≤ 40 par séance | choix raisonné |
| Jalons | 30, 30, 30, 100 ; ≤ 100 par semaine ; compétence 0,5 | choix raisonné ; principe : Locke et Latham, 2002 (objectifs précis et difficiles) ; Bandura et Schunk, 1981 |
| Quêtes | 10 / 5 / 40 / 30 / 100 / 60 XP | mesuré : les quêtes pèsent environ un quart à un tiers de l'XP, l'entraînement réel le reste (`docs/RYTHME.md`, § 3) |
| Coffres | 15 %, garantie à 8, 2 par semaine | choix raisonné ; taux variable : Ferster et Skinner, 1957 ; ni achat ni perte : Zendle et Cairns, 2018 (ce sont les coffres payants qui sont liés au jeu problématique) ; mesuré : un coffre toutes les 4,5 à 5 séances |
| Note de séance | 60 / 30 / 10 ; S 90, A 70, B 50 | choix raisonné ; distribution mesurée dans `docs/RYTHME.md`, § 5 |
| Rétention | 21 jours, −1 % par semaine, plancher 70 % | repris de `kalis_adapt` ; référence : McMaster et coll., 2013 ; plancher : choix raisonné |
| Mobilité | 3 jours et 1 800 s par semaine | référence : Garber et coll., 2011 (ACSM : souplesse 2 à 3 jours par semaine, 60 s par étirement) ; 1 800 s : choix raisonné (10 étirements × 60 s × 3 jours) |
| Cardio | 150 min par semaine | référence : Garber et coll., 2011 |
| Travail explosif | 10 séries par semaine | choix raisonné |
| Tendance amortie | 0,97 par semaine | repris de `kalis_adapt` ; forme : Gardner et McKenzie, 1985 |
| Incertitude de la tendance | 20 % de la tendance, plancher erreur / 26 ; erreur de niveau ≥ 1 % | mesuré : couverture de l'intervalle à 80 % sur trajectoires simulées (`docs/VALIDATION.md`, § 4) |
| Suggestion | 60 % à 8 semaines | décision du propriétaire (60 %) ; 8 semaines : choix raisonné |
| Gain plausible | 15 %, 8 %, 5 %, 2 % | choix raisonné, d'après les ordres de grandeur de la prise de force selon l'ancienneté (position ACSM 2002, citée par Kraemer et coll., 2002 : environ 40 % chez les non-entraînés à 2 % chez l'élite, sur des durées de 4 semaines à 2 ans) |
| Riegel | exposant 1,06, de 1,5 à 45 km | référence : Riegel, 1981 |
| Standards de rang | `docs/STANDARDS.md` | référence et mesuré : `docs/STANDARDS_SOURCES.md` |
| Poids de corps de référence | 70 kg | repris de `kalis_adapt` |

## 11. Limites connues

- **Aucune donnée réelle.** Le rythme est mesuré sur des athlètes simulés ; les habitudes réelles (taux de
  quêtes faites, régularité) le déplaceront. La courbe a un seul paramètre d'échelle à recaler.
- **`plannedWorkSets` absent** : une séance terminée de plus de la moitié des séries du bloc est comptée
  complète ; sans bloc, toute séance terminée l'est.
- **Séance modifiée après son règlement** : son XP ne change plus (ni à la hausse ni à la baisse) ; si sa
  date change de semaine, elle reste comptée dans sa semaine d'origine.
- **Tout est déclaré.** Le journal est saisi par l'utilisateur : rien n'empêche de saisir des séries non
  faites. Les plafonds bornent ce que cela rapporte (au plus le programme), ils ne le détectent pas. De
  même, noter « à la cible » plutôt que son ressenti rapporte au plus 30 % d'une série et le combo.
- **Plafond et disponibilités** : sans bloc, le plafond de la semaine suit les jours de disponibilité du
  profil ; les augmenter augmente le plafond (et les séances attendues pour la série de semaines).
- **Objectifs** : supprimer un objectif puis en créer un autre sur le même exercice paie de nouveaux
  jalons ; le plafond de 100 XP par semaine borne ce gain.
- **Séance laissée inachevée** : réglée le lendemain pour ce qui est fait ; les quêtes de son jour sont
  encore ouvertes à ce moment-là.
- **Quêtes déclaratives** : sur l'honneur (5 XP, 2 par jour au plus).
- **Douleur** : seule la douleur déclarée avant la séance retire la récompense ; une douleur tue ne peut
  pas être vue.
- **Séances en plus** : une séance hors programme faite tôt dans la semaine prend la place d'une séance
  prévue plus tard (le plafond compte les séances, pas leur origine).
- **Attributs** : Force, Endurance et Puissance s'appuient sur seize mouvements de référence ; ailleurs,
  la difficulté du catalogue plafonne à 60. Endurance et Puissance mêlent performance et pratique.
- **Rangs** : voir `docs/STANDARDS_SOURCES.md`, § 5 (pas d'âge, figures sans sexe ni poids).
- **Prédiction** : loi normale et tendance amortie ; l'intervalle n'est calé que sur des trajectoires
  simulées de même forme (la couverture mesurée dit que le calcul est cohérent, pas que la forme est
  vraie). Sans `kalis_adapt`, il faut 3 semaines de mesures. Les objectifs de compétence n'ont pas de
  prédiction.
- **Objectif suggéré** : seulement avec le résumé d'adaptation.
- **Registres** : environ 500 à 1 000 écritures d'XP par an ; ils ne sont jamais compactés.
- **Quêtes passées** : gardées 35 jours dans l'état ; au-delà, seuls leurs gains restent au registre.
- **Web** : entiers 64 bits de la VM Dart (hachage des tirages) ; le Web n'est pas pris en charge.
- **Régularité de 2 ou 3 séances par semaine** : la règle des 3/4 exige alors toutes les séances ; une
  seule séance manquée rend la semaine non réussie.

## 12. Registre de validation

| Élément | Validé par | État |
| --- | --- | --- |
| Invariants P1 à P7 | tests de propriétés (10 240 journaux), scénarios | vert en CI |
| Rythme sur 3 ans | simulation (8 archétypes × 200 graines), `docs/RYTHME.md`, lue dans `docs/VALIDATION.md` | simulé, aucune donnée réelle |
| Triche par surentraînement | simulation, test | vert |
| Temps de calcul | test et simulateur | vert |
| Standards de rang | sources publiées, ajustement reproductible | **non relu par un professionnel diplômé** ; valeurs relevées par un outil, à revérifier à la main |
| Barème d'XP, attributs, notes, quêtes | — | **choix raisonnés, non relus par un professionnel diplômé** |
| Règle de la douleur | reprise de `kalis_adapt` | **non relue par un professionnel de santé** ; aucune allégation médicale |
| Prédiction | couverture mesurée sur trajectoires simulées | à recaler sur données réelles (lot G14) |

## Références

- Bandura A., Schunk D. H. (1981). Cultivating competence, self-efficacy, and intrinsic interest through
  proximal self-motivation. *Journal of Personality and Social Psychology*, 41(3), 586-598.
- Baz-Valle E., Fontes-Villalba M., Santos-Concejero J. (2021). Total number of sets as a training volume
  quantification method for muscle hypertrophy: a systematic review. *Journal of Strength and
  Conditioning Research*, 35(3), 870-878.
- Deci E. L., Koestner R., Ryan R. M. (1999). A meta-analytic review of experiments examining the effects
  of extrinsic rewards on intrinsic motivation. *Psychological Bulletin*, 125(6), 627-668.
- Ferster C. B., Skinner B. F. (1957). *Schedules of Reinforcement*. Appleton-Century-Crofts.
- Garber C. E. et coll. (2011). Quantity and quality of exercise for developing and maintaining
  cardiorespiratory, musculoskeletal, and neuromotor fitness in apparently healthy adults. *Medicine &
  Science in Sports & Exercise*, 43(7), 1334-1359 (détail des prescriptions lu dans une source
  secondaire).
- Gardner E. S., McKenzie E. (1985). Forecasting trends in time series. *Management Science*, 31(10),
  1237-1246 (référence non revérifiée en ligne).
- Halperin I., Malleron T., Har-Nir I. et coll. (2022). Accuracy in predicting repetitions to task
  failure in resistance exercise: a scoping review and exploratory meta-analysis. *Sports Medicine*,
  52(2), 377-390 (référence non revérifiée en ligne).
- Grgic J., Schoenfeld B. J., Orazem J., Sabol F. (2022). Effects of resistance training performed to
  repetition failure or non-failure on muscular strength and hypertrophy. *Journal of Sport and Health
  Science*, 11(2), 202-211.
- Kraemer W. J., Ratamess N. A., French D. N. (2002). Resistance training for health and performance.
  *Current Sports Medicine Reports*, 1, 165-171.
- Locke E. A., Latham G. P. (2002). Building a practically useful theory of goal setting and task
  motivation. *American Psychologist*, 57(9), 705-717.
- Mazeas A., Duclos M., Pereira B., Chalabaev A. (2022). Evaluating the effectiveness of gamification on
  physical activity: systematic review and meta-analysis of randomized controlled trials. *Journal of
  Medical Internet Research*, 24(1), e26779.
- McMaster D. T., Gill N., Cronin J., McGuigan M. (2013). The development, retention and decay rates of
  strength and power in elite rugby union, rugby league and American football. *Sports Medicine*, 43(5),
  367-384.
- Meeusen R. et coll. (2013). Prevention, diagnosis, and treatment of the overtraining syndrome: joint
  consensus statement of the ECSS and the ACSM. *Medicine & Science in Sports & Exercise*, 45(1),
  186-205.
- Refalo M. C., Helms E. R., Trexler E. T., Hamilton D. L., Fyfe J. J. (2023). Influence of resistance
  training proximity-to-failure on skeletal muscle hypertrophy: a systematic review with meta-analysis.
  *Sports Medicine*, 53(3), 649-665.
- Riegel P. S. (1981). Athletic records and human endurance. *American Scientist*, 69(3), 285-290.
- Robinson Z. P. et coll. (2024). Exploring the dose-response relationship between estimated resistance
  training proximity to failure, strength gain, and muscle hypertrophy: a series of meta-regressions.
  *Sports Medicine*, 54(9), 2209-2231.
- Sharif M. A., Shu S. B. (2017). The benefits of emergency reserves: greater preference and persistence
  for goals that have slack with a cost. *Journal of Marketing Research*, 54(3).
- Silverman J., Barasch A. (2023). On or off track: how (broken) streaks affect consumer decisions.
  *Journal of Consumer Research*, 49(6), 1095-1117.
- Zendle D., Cairns P. (2018). Video game loot boxes are linked to problem gambling: results of a
  large-scale survey. *PLoS ONE*, 13(11), e0206767.
- Zourdos M. C. et coll. (2016). Novel resistance training-specific rating of perceived exertion scale
  measuring repetitions in reserve. *Journal of Strength and Conditioning Research*, 30(1), 267-275.
