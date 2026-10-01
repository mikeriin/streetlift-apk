# kalis_quest 0.1.0 — validation

Lecture des mesures de `RYTHME.md` (campagne de simulation, 8 archétypes × 200 graines × 3 ans), des cas
types (`CAS_TYPES.md`) et des tests. Écrit à la main après lecture complète des résultats ; les tableaux
de `RYTHME.md`, `STANDARDS.md` et `CAS_TYPES.md` sont générés, et un test vérifie qu'ils sont à jour.

**Ce que cette validation ne dit pas.** Aucune donnée réelle n'a servi : les athlètes sont simulés (§ 7).
Le barème, les attributs, les notes et les standards de rang n'ont pas été relus par un professionnel
diplômé. La simulation dit que la mécanique est cohérente et que ses garde-fous tiennent ; elle ne dit
pas que de vraies personnes s'entraîneront mieux, plus longtemps ou plus prudemment grâce à elle. La
littérature sur ce point est modeste : la ludification augmente un peu l'activité physique à court
terme, et l'effet faiblit après l'intervention (Mazeas et coll., 2022) ; une récompense attendue et
contingente peut réduire la motivation propre (Deci, Koestner et Ryan, 1999) — raison pour laquelle le
moteur récompense le programme fait et le repos gardé, jamais « plus ».

## 1. Protocole

- **Programmes** : ceux de `kalis_plan`, bloc après bloc, pour le profil type de chaque archétype
  (`SimProgram` de `kalis_adapt`).
- **Journal simulé** (`lib/src/sim/generator.dart`) : chaque séance prévue est faite avec la probabilité
  d'assiduité de l'archétype ; une séance faite l'est en partie (réalisation tirée), avec des notes de
  flammes bruitées autour de la cible, des notes parfois absentes, un bilan santé parfois rempli, une
  progression des charges à tendance amortie, des arrêts non déclarés, des pauses déclarées, des
  douleurs déclarées (archétype `maladie_3x`).
- **Moteur** : appelé à la fin de chaque semaine avec le bloc en cours, l'état rendu par l'appel
  précédent, sans résumé d'adaptation. Les quêtes de récupération sont déclarées avec une probabilité
  propre à l'archétype.
- **200 graines par archétype, 156 semaines** ; les deux archétypes de repère sont prolongés à
  208 semaines (50 graines), et ont un jumeau tricheur et un jumeau à assiduité parfaite, aux mêmes aléas.
- Médiane et 10ᵉ–90ᵉ centiles entre graines.

Reproduire : `dart run bin/kalis_quest_cli.dart --rapport <dossier>` (environ 20 minutes sur 4 cœurs) ;
une simulation : `dart run kalis_quest:simulate --archetype debutant_3x --years 3 --seed 0`.

## 2. Rythme : la cible est tenue pour 3 et 4 séances par semaine

Cible du lot, pour une personne à 3 ou 4 séances par semaine : niveau 10 en 3 semaines environ, 25 en
3 mois, 50 en 1 an, 100 en 3 à 4 ans.

| Repère | Cible | `debutant_3x` (2,7 séances faites / sem.) | `intermediaire_4x` (3,6 / sem.) |
| --- | --- | --- | --- |
| Niveau 10 | ≈ 3 semaines | 3 (3–4) | 3 (2–3) |
| Niveau 25 | ≈ 3 mois (13 sem.) | 15 (14–17) | 12 (11–13) |
| Niveau 50 | ≈ 1 an (52 sem.) | 55 (53–57) | 43 (42–45) |
| Niveau 100 | 3 à 4 ans (156 à 208 sem.) | 199 (195–202) | 158 (155–161) |

Les deux repères encadrent chaque cible : le débutant à 3 séances est un peu en dessous du rythme visé
(niveau 25 à 3 mois et demi, niveau 50 à 55 semaines), l'intermédiaire à 4 séances un peu au-dessus
(niveau 50 à 10 mois). La dispersion entre graines est faible (± 1 à 3 semaines) : à assiduité donnée,
le rythme ne dépend presque pas de la chance (coffres et tirages de quêtes ne donnent pas d'XP au-delà
des quêtes elles-mêmes).

**Comment la courbe a été calée.** Un seul paramètre d'échelle `K` et un exposant : coût du niveau
`n` = `K × n^p`. Trois passes de mesure : `54 × n^0,75` (écartée : les quatre repères ne
tenaient pas ensemble), `33 × n^0,875` (24 graines : niveaux 10, 25, 50 en 4, 17, 60 semaines pour le débutant), puis
`32 × n^0,875` avec des quêtes hebdomadaires à 40 XP (mesures ci-dessus). L'exposant fixe le rapport entre le temps du
niveau 50 et celui du niveau 100 ; l'échelle, tout le reste. Ce calage est fait **sur la simulation** :
si les habitudes réelles diffèrent (§ 7), seul `K` (`QuestParams.levelScale`) est à recaler, sans
toucher aux registres — le niveau est une fonction de la somme d'XP.

**Hors des repères** (lu, pas visé) :

- `debutant_2x` : niveau 50 en 69 semaines, niveau 77 à 3 ans. Deux séances par semaine avancent à
  78 % du rythme du repère à 3 séances : la régularité et les quêtes (60 % de son XP) compensent en
  partie le moindre volume, ce qui est voulu (ne pas punir un petit programme).
- `expert_6x` : niveau 100 en 112 semaines (2 ans et 2 mois), premier prestige compris à 3 ans (niveau
  global 160). **Plus rapide que la cible**, parce que l'XP d'effort suit le nombre de séances du
  programme. C'est un choix : un programme à 6 séances rapporte plus qu'un programme à 3. Il ne pousse
  pas à s'entraîner plus que *son* programme (§ 4), mais il rend un gros programme plus payant ; c'est le
  programme de `kalis_plan`, bâti sur les disponibilités, qui porte la prudence. À faire trancher si le
  propriétaire préfère un rythme indépendant du nombre de séances.
- `irregulier_3x` (1,56 séance faite par semaine, arrêts non déclarés) : niveau 25 en 24 semaines,
  niveau 67 à 3 ans. Il avance toujours ; rien ne lui est retiré.
- `vacances_5x`, `maladie_3x` : les pauses déclarées ne coûtent que les semaines non faites (niveau 50
  en 39 et 55 semaines).

## 3. D'où vient l'XP

| | Effort | Régularité et repos | Quêtes | Records | Jalons |
| --- | --- | --- | --- | --- | --- |
| 2 séances / sem. | 40 % | 24 % | 36 % | 0 % | 0 % |
| 3 séances / sem. | 50 % | 20 % | 29 % | 1 % | 0 % |
| 4 séances / sem. | 56 % | 17 % | 26 % | 0 à 1 % | 0 % |
| 6 séances / sem. | 65 % | 13 % | 22 % | 0 % | 0 % |

- L'entraînement fait (effort + régularité) pèse **64 à 78 %** de l'XP ; les quêtes, 22 à 36 %. Les
  quêtes de récupération déclarées sur l'honneur valent 5 XP, 2 au plus par jour de repos : au plus
  50 XP par semaine pour un programme de 2 séances (13 % de son rythme), 40 XP pour 3 séances (8 %).
  C'est la part que la triche par déclaration peut atteindre, et elle est bornée.
- **Records : 0 à 1 %.** Le progrès lui-même ne pèse presque rien dans le niveau. C'est cohérent avec le
  principe (le niveau récompense l'assiduité, les rangs et les attributs disent la performance), mais
  c'est aussi un effet de la simulation : les records n'y sont payés que dans le volume prévu et avec
  des notes de 8 flammes ou plus pour un 1RM. Le journal type du propriétaire (`CAS_TYPES.md`, j16)
  donne 9 % d'XP de records sur 16 semaines : l'ordre de grandeur réel est sans doute entre les deux.
- **Jalons : 0 %** parce que les archétypes simulés n'ont que les objectifs de leur profil type, créés
  une fois. Le plafond de 100 XP par semaine borne leur part à 17 à 21 % du rythme hebdomadaire d'un
  repère dans le pire cas (objectifs enchaînés toutes les semaines).

## 4. Garde-fous

Mesurés sur les 1 600 simulations et testés sur 10 240 journaux aléatoires (`CONTRAT.md`, § 9).

- **Plafond de la semaine** : l'XP d'effort d'une semaine n'a jamais dépassé `séances prévues × 110`
  (pire semaine : 96 à 100 % du plafond). Le niveau n'a jamais baissé.
- **Douleur** : `maladie_3x` fait en moyenne 2,8 séances malgré une douleur en 3 ans ; elles ont reçu
  0 XP ; ses semaines non réussies touchées par une maladie déclarée ou par une de ces séances sont en
  pause (9,7 en moyenne), pas manquées.
- **Surentraînement** (jumeau tricheur : moitié de séries en plus à chaque séance, une séance en plus
  quatre jours de repos sur cinq) :
  - ses 314 à 452 séances en plus reçoivent 0 XP ;
  - il gagne pourtant **+2 148 XP (+2,9 %) et +6 513 XP (+6,9 %)** sur 3 ans face à son jumeau honnête.
    Cause lue dans les traces : ses séances en plus tombent dans des semaines où il manque une séance
    prévue, et prennent sa place — son XP d'effort monte jusqu'au plafond du programme, pas au-delà. Ce
    n'est pas du surentraînement payé : c'est une séance déplacée payée. Le gain vaut un à quatre
    niveaux au bout de 3 ans ;
  - face au même programme **fait en entier**, il perd 6 638 à 8 373 XP dans le cas qui lui est le plus
    favorable. Causes, d'après le barème (non décomposées par la campagne) : les jours de repos non
    gardés coûtent la part « repos » de la régularité (jusqu'à 40 XP par semaine), et une séance en plus
    faite tôt dans la semaine prend la place d'une séance prévue, qui ne fait alors plus avancer les
    quêtes de son jour. S'entraîner plus que le programme ne rapporte jamais plus que faire le
    programme.
- **Limite de ce test** : le tricheur simulé fait de vraies séances. Un utilisateur qui *saisit* des
  séances non faites atteint le plafond du programme sans s'entraîner ; rien dans un journal déclaré ne
  peut l'empêcher (`CONTRAT.md`, § 11).

## 5. Mécaniques de plaisir

- **Coffres** : un coffre toutes les 4,9 à 5,1 séances, jamais plus de 8 séances sans coffre (la
  garantie), 2 au plus par semaine. Krédits sur 3 ans : 5 300 à 12 000, dont 60 à 78 % viennent des
  quêtes et 12 à 25 % des coffres.
- **Série de semaines — point à faire trancher.** À 4 séances et plus, 95 % des semaines sont réussies
  (meilleure série médiane : 44 à 59 semaines). À 2 et 3 séances, la règle des 3/4 exige *toutes* les
  séances : `debutant_2x` et `debutant_3x`, qui font 85 à 90 % de leurs séances, ne réussissent que
  72 à 73 % de leurs semaines (meilleure série : 12 à 13 semaines). La règle est une décision du propriétaire
  et le moteur l'applique ; mais elle est plus dure pour les petits programmes, ceux des débutants. Une
  variante (arrondir à l'entier inférieur : 1 sur 2, 2 sur 3) est un paramètre
  (`streakNumerator`/`streakDenominator`) ; elle n'a pas été retenue sans décision.
- **Notes de séance** : la note S est rare (0 à 1 %, sauf deux archétypes) et B domine (58 à 94 %),
  sauf pour `expert_6x` (75 % de A). La justesse des flammes (30 points) est faible dans la simulation :
  l'erreur de note simulée est de 0,7 répétition en réserve (1,4 flamme), à quoi s'ajoute l'écart entre
  la charge prescrite et la capacité du jour — des hypothèses, pas une mesure sur de vrais utilisateurs.
  `irregulier_3x` et `vacances_5x` ont 19 % et 10 % de S parce qu'une partie de leurs séances n'a aucune
  série notée ayant une cible de flammes : la justesse vaut alors la réalisation, et une séance complète
  est notée S. La note n'est donc pas comparable d'un programme à l'autre. Les seuils (90, 70, 50) sont donc **à recaler sur des
  journaux réels** (lot G14) ; en l'état, un A demande une séance complète et un tiers des notes à la
  cible.
- **Attributs** : ils séparent bien les profils (Force 12 à 57, Puissance 2 à 51, Mobilité 1 à 99) mais
  certains restent au plancher pour des raisons de structure, pas de niveau : Endurance 1 pour
  `expert_6x` (aucun cardio ni mouvement d'endurance de référence dans son programme), Technique 1 pour
  `debutant_2x` et `maladie_3x` (aucune figure, peu de séries à cible). Un attribut bas dit « pas
  pratiqué », pas « mauvais » : l'application devra le présenter ainsi.

## 6. Prédiction des objectifs

Test `goals_test.dart`, « calibrage » : 240 trajectoires de 1RM à tendance amortie (départ 60 à 100 kg,
0,4 à 2 kg par semaine, bruit de mesure de 0,6 à 1,4 %), prédiction faite après 8 semaines, date réelle
d'atteinte lue ensuite.

- **Couverture de l'intervalle à 80 % : 79,6 %** (191 sur 240) ; 24 atteintes avant `earliestOn`,
  25 après `latestOn` : les erreurs sont équilibrées des deux côtés.
- Écart absolu moyen entre la date médiane prédite et la date réelle : 16,7 jours, pour des échéances de
  12 à 24 semaines.
- **Ce calage est fait sur l'échantillon qui le mesure** : l'incertitude de la tendance (20 %) et le
  plancher d'erreur (1 %) ont été choisis après une première mesure à 99 % de couverture (intervalle trop
  large). Et les trajectoires ont la forme que le modèle suppose (tendance amortie de 3 % par semaine).
  La couverture dit donc que le calcul est cohérent, pas que la forme est vraie : un plateau, une
  blessure, une reprise sortent du modèle. À remesurer sur des journaux réels (lot G14).
- **Objectifs suggérés** : la cible est arrondie en dessous du quantile à 60 % ; la probabilité d'atteinte
  calculée est donc d'au moins 60 % (test), sous les mêmes réserves.

Sur les journaux types (`CAS_TYPES.md`), 8 des 14 objectifs écrits à la main dans les profils sont jugés
en retard, ceux de performance avec une confiance proche de 0 : ils sont ambitieux pour leur échéance et
la tendance lue sur 4 à 16 semaines ne les porte pas. Le moteur propose alors une date ou une cible ; il
ne dit pas que l'objectif est mauvais.

## 7. Ce que la simulation suppose

- **Assiduité tirée au hasard, indépendante d'une semaine à l'autre** (hors arrêts programmés). De vraies
  personnes décrochent par périodes ; les séries de semaines réelles seront plus courtes et plus
  inégales.
- **Quêtes faites à un taux fixe** par archétype (38 à 69 % des quotidiennes, 27 à 44 % des quêtes
  Koach). Personne ne sait ce que sera ce taux ; il porte un quart à un tiers de l'XP. C'est la première
  cause possible d'écart au rythme visé.
- **Les programmes sont ceux de `kalis_plan`, suivis tels quels**, sans résumé d'adaptation : les quêtes
  Koach sur l'exercice évité et les objectifs suggérés ne sont pas exercés par la campagne (ils le sont
  par les tests).
- **`plannedWorkSets` est toujours renseigné** dans la simulation. Sans lui, le moteur se rabat sur le
  bloc ou sur les habitudes (`CONTRAT.md`, § 4.2), et une séance terminée à plus de la moitié compte
  entière : le rythme serait un peu plus rapide.
- **Le simulateur a été écrit pour ce lot**, par le même auteur que le moteur : il ne peut pas révéler une
  hypothèse fausse que les deux partagent.

## 8. Relecture indépendante

Avant livraison, le paquet a été relu par un second agent qui n'avait pas écrit le code, avec la consigne
de chercher ce qu'un entraîneur et un statisticien refuseraient. 19 constats ; tous corrigés ou écrits
comme limites.

| Constat | Suite |
| --- | --- |
| Une séance faite malgré une douleur réduisait les séances prévues de la semaine : la semaine devenait plus facile à réussir | corrigé : la semaine garde ses séances prévues ; non réussie, elle est en pause (test) |
| Les performances d'une séance douloureuse ou en plus du programme nourrissaient rangs, attributs et objectifs | corrigé : seules comptent les performances du volume prévu d'une séance récompensée (test) |
| Objectifs faciles à exploiter : départ à 0 pour des répétitions, objectifs en double, objectif antidaté, 200 XP par semaine | corrigé : départ = première mesure, un seul objectif payé par grandeur, jalons antérieurs non payés, plafond 100 XP, Krédits au prorata (tests) |
| Une séance abandonnée après quelques séries prenait la place d'une séance prévue | corrigé : payée pour ce qui est fait, sans prendre de place ; plafond d'XP de la semaine ajouté (test) |
| Une séance libre sans `programRef` était toujours comptée complète | corrigé : rapportée à la séance prévue ce jour-là, sinon aux habitudes |
| Une séance dont la date change de semaine après son règlement comptait deux fois | corrigé : le registre fait foi pour la semaine d'une séance (test) |
| La quête « exercice évité » pouvait proposer un exercice évité à cause d'une douleur | corrigé : jamais sous douleur persistante ni pour une zone douloureuse suivie |
| Tests manquants sur ces cas ; documents générés absents | ajoutés |
| Un record pouvait être payé deux fois après suppression puis nouvelle saisie | corrigé : dernier record payé gardé dans l'état |
| Un record établi par une série au-delà du volume prévu était payé | corrigé (test) |
| La figure la plus dure « maîtrisée » était lue sans tenir compte de la date | corrigé |
| Rotation de la quête de point faible bloquée sur le même attribut | corrigé |
| Une quête « séries dans la cible » pouvait demander plus que la séance allégée du jour | corrigé : une séance entièrement dans la cible la remplit |
| Un objectif en retard pouvait n'avoir aucune proposition | corrigé : cible à mi-chemin ou même cible plus tard |
| Journal non trié, date illisible dans l'état, séance en cours réglée trop tôt | corrigés |
| Prédiction : calage sur l'échantillon, forme supposée | écrit (§ 6) |
| Noter « à la cible » plutôt que son ressenti est payé | réduit (tolérance de 2 flammes, plancher 0,7) et écrit (`CONTRAT.md`, § 11) |
| Simulation optimiste (assiduité indépendante, taux de quêtes fixe) | écrit (§ 7) |
| Le plafond suit les disponibilités déclarées ; « sans les recopier » était inexact pour la règle des records | écrit (`CONTRAT.md`, § 1 et § 11) |

Après ces corrections, la campagne a été relancée en entier : le rythme n'a pas bougé (les archétypes
honnêtes ne déclenchaient aucun de ces cas), et le gain du jumeau tricheur est resté celui du § 4.

## 9. Temps de calcul

VM Dart de la machine de contrôle (pas un téléphone), journal de 895 séances sur 3 ans : calcul complet
depuis un état vide en 52 ms (médiane ; 71 ms au plus dans la campagne, 61 à 123 ms dans le test), appel
du lendemain en 9 ms. Budget : 200 ms. Un téléphone d'entrée de gamme est plusieurs fois plus lent ; la
marge (un facteur 4 sur le calcul complet, qui n'a lieu qu'après une perte de l'état) est à vérifier à
l'intégration (lot G12).

## 10. Ce qui reste à faire trancher ou à mesurer

1. Règle des 3/4 pour les programmes de 2 et 3 séances (§ 5).
2. Rythme proportionnel au nombre de séances du programme (§ 2, `expert_6x`).
3. Seuils des notes S/A/B/C, taux réel de quêtes faites, échelle `K` : à recaler sur des journaux réels
   (lot G14).
4. Standards de rang et barème : relecture par un professionnel diplômé (`CONTRAT.md`, § 12).
