# Contrat de kalis_plan 0.2.1

Moteur statique de Kalis Track (D4) : il crée le programme. Dart pur, sans Flutter, sans stockage, sans
horloge ; tout ce qu'il rend est une valeur du contrat de `kalis_core` (`docs/TYPES.md`) et des codes de
raison, jamais une phrase.

Ce document fixe ce que le moteur garantit (§ 2 et 8), comment il décide (§ 3 à 6), d'où vient chaque
nombre (§ 7), ce qu'il ne sait pas faire (§ 9) et ce qui a été vérifié, par qui (§ 10). Les mesures citées
viennent de `docs/MESURES.md` (relevé du simulateur) ; les 40 programmes types sont dans
`docs/PROFILS_TYPES.md`.

## 1. Vocabulaire

| Terme | Sens |
| --- | --- |
| Semaine type | La passe 1 : pour chaque jour d'entraînement, une liste ordonnée d'exercices (`Pass1Plan`). |
| Emplacement | Un exercice d'un jour (`PlanSlot`). Son identifiant `d<jour>.<n>` porte le rang du jour : un emplacement ne change jamais de jour, et garde son identifiant d'une régénération à l'autre. |
| Vivier | Les exercices du catalogue admissibles pour un profil (contraintes dures, § 3.2). |
| Classe de discipline | Les huit disciplines du profil ; la « forme générale » se lit comme 50 % de renforcement, 35 % de cardio, 15 % de mobilité. |
| Série fractionnaire | Une série compte 1 pour les muscles principaux de l'exercice, 0,5 pour ses muscles secondaires (§ 3.4, volume). |
| Séries de référence | Les séries de la semaine la plus chargée du bloc ; la passe 1 s'en sert pour estimer la durée, la passe 2 les module semaine par semaine. |

## 2. API

`KalisPlan implements PlanEngine` (kalis_core). Toutes les méthodes sont des fonctions pures de leurs
arguments : même requête, même résultat **à l'octet près** (JSON), quelle que soit l'instance ou l'ordre des
appels. L'instance garde en mémoire la dernière suite de propositions (pour un catalogue donné) afin de ne
pas la recalculer ; ce cache ne change aucun résultat (testé).

Portée exacte de cette garantie :

- **Ordre des listes du profil.** Le programme ne dépend pas de l'ordre des disponibilités, du matériel,
  des niveaux déclarés ni des goûts (testé sur 12 profils types, raisons d'en-tête exclues). L'ordre des
  **objectifs** compte : c'est un ordre de priorité, et seuls les 8 premiers objectifs de performance sont
  pris en compte. Un doublon dans les niveaux déclarés ou le matériel par lieu : le dernier l'emporte.
- **Plateforme.** Le moteur n'utilise que des entiers de 64 bits, les quatre opérations et la racine carrée
  des flottants IEEE 754 ; l'exponentielle et le logarithme du recuit sont calculés par le paquet
  (`stableExp`, `stableLn`) et non par la bibliothèque mathématique de la machine. Le résultat doit donc
  être le même sur toute machine native (x64, ARM) ; cela **n'a été vérifié que sur la machine du
  contrôle** (x64). Le Web (JavaScript, entiers de 53 bits) n'est pas pris en charge.

| Méthode | Entrée | Sortie | Rôle |
| --- | --- | --- | --- |
| `createPass1(catalog, PlanRequest)` | profil, graine, date de début, verrous, résumé d'adaptation et bloc précédent éventuels | `Pass1Plan` | Semaine type, note détaillée, raisons par emplacement. Avec `previousBlock`, délègue à la logique du bloc suivant. |
| `review(catalog, ReviewRequest)` | requête d'origine, programme courant, une action | `ReviewResult` | Applique l'action (`can_do`, `cannot_do`, `dislike`, `add`, `remove`, `replace`), régénère à diff minimal, rend le programme, le diff, les verrous et la mise à jour du profil. |
| `variants(catalog, VariantsRequest)` | programme courant, emplacement | `VariantSet` | Trois variantes ciblées (plus facile, équivalente, autre matériel) puis toutes les compatibles, triées par proximité. |
| `createPass2(catalog, Pass2Request)` | passe 1 validée | `Pass2Plan` | Séries, plages, flammes visées, repos, charges de départ, semaine par semaine. |
| `nextBlock(catalog, NextBlockRequest)` | bloc précédent, résumé d'adaptation | `BlockProposal` | Bloc suivant : mouvements principaux gardés, assistance en rotation partielle, progression des exercices maîtrisés. |
| `restructure(catalog, RestructureRequest)` | bloc courant, portée (séance, semaine, fin du bloc), raisons du moteur dynamique | `BlockProposal` | Restructure sans toucher aux semaines passées. |

En plus de l'interface : `reviewTraced` (programme « après l'action seule », pour vérifier le diff minimal),
`applyProfileDelta`, `PlanInspector` (note relue, contraintes dures revérifiées, mesures, « pourquoi pas un
exercice de plus ? »), `PlanParams` (tous les paramètres chiffrés), `planSimilarity`.

**Erreurs.** `ArgumentError` si le profil est invalide (`AthleteProfile.validate`, `Catalog.checkProfile`),
si une action de revue est mal formée, si un emplacement, un jour ou un exercice est inconnu. Aucune autre
exception pour une entrée valide (10 240 profils aléatoires, § 8).

**Graine.** Graine 0 : le meilleur programme trouvé. Graines 1, 2, … : « Autre proposition » (§ 3.7). La
graine est lue modulo 16.

**Ligne de commande.** `dart run kalis_plan:plan --profile <json> --seed <n> --pass 1|2 [--locks <json>]
[--start AAAA-MM-JJ] [--catalog <fichier>]` écrit le programme en JSON sur la sortie standard (`--pass 2` :
le bloc complet).

## 3. Passe 1 : formulation

### 3.1 Données et variables

- Jours d'entraînement `j = 1…J` (disponibilités du profil, triées par jour de la semaine), chacun avec
  ses minutes `T_j`, son lieu et son matériel.
- Vivier `V` : les exercices admissibles ; `V_j ⊂ V` ceux qui sont faisables le jour `j`.
- Variable de décision : pour chaque jour, un ensemble `S_j ⊂ V_j` d'exercices (au plus 12, au plus
  `min(8, T_j / 8 + 1)` hors mobilité, pas de doublon dans la séance). L'ordre dans la séance et les séries
  de référence ne sont pas des variables : ce sont des fonctions de `S_j` (§ 3.3), si bien qu'un programme
  relu donne exactement la durée et la note du programme produit.

Le programme rendu maximise l'objectif du § 3.5 sous les contraintes du § 3.2.

### 3.2 Contraintes dures

Un exercice n'entre dans le vivier que s'il passe **toutes** ces règles ; `PlanInspector.rejectionOf` rend
la première qui l'écarte.

| Code | Règle |
| --- | --- |
| `discipline` | L'exercice appartient à une discipline de la base que les disciplines du profil admettent (table d'affinité `disciplineAffinity`, § 7.6). |
| `excluded` | Il n'est ni détesté, ni déclaré « je ne sais pas faire », ni exclu par un verrou, ni évité par le résumé d'adaptation. |
| `level` | Sa difficulté (1 à 10) ne dépasse pas le niveau du groupe de mouvements (poussée, tirage, jambes, tronc, puissance, cardio, mobilité), sauf exercice déclaré su. |
| `prerequisite` | Aucun de ses prérequis n'est déclaré non acquis ; il n'est pas une variante plus dure d'un exercice non acquis. |
| `reserved` | Haltérophilie, pliométrie et balistique : seulement avec du CrossFit au profil. Souplesse avancée : seulement avec au moins 30 % de mobilité ou de la calisthénie. Travail direct du cou : jamais d'office. Travail direct des avant-bras : seulement avec une discipline de barre. Sauf exercice su, aimé ou lié à un objectif. |
| `too_easy` | Un polyarticulaire ou une figure sans charge réglable n'est pas trois paliers sous le niveau du groupe ; un exercice assisté n'est pas deux paliers sous ce niveau. Sauf exercice su, aimé ou visé par un objectif. |
| `cautious` | Programme prudent (questionnaire santé « prudent » ou sans réponse, 65 ans et plus, moins de 18 ans) : ni impact (sauts, sprints, haltérophilie, corde à sauter, explosif), ni course à pied (cardio sans appui contraignant pour la cheville : marche, vélo, rameur, natation), ni fatigue systémique maximale ; le niveau de chaque groupe baisse d'un palier, sans descendre sous 2 (un niveau de 1 ou 2 ne change pas). Un profil sans référence au questionnaire (`healthScreening` absent) est traité comme « sans réponse ». |
| `joint` | Contrainte forte sur une articulation ou travail direct d'une zone dont la gêne déclarée est d'au moins 4/10 : écarté. Contrainte modérée ou travail indirect : écarté à partir de 7/10. |
| `equipment` | Le matériel et le lieu de l'exercice existent au moins un jour (matériel par lieu si le profil le donne). |
| `time` | Sa dose minimale, échauffement compris, tient dans au moins un jour. |

S'y ajoutent, pour le programme : aucune séance vide ; durée estimée de chaque séance ≤ `T_j` ; verrous
respectés (`keep_slot` : même emplacement, même exercice ; `require_exercise` : présent ; `exclude_exercise` :
absent ; `keep_day` : jour figé en régénération). Ce que l'utilisateur impose lui-même (emplacement
verrouillé, ajout) passe avant ces règles : une séance peut alors dépasser son temps, et le moteur ne le
compense qu'en retirant des exercices libres.

**Niveau.** Le niveau d'un groupe vient des performances déclarées (répétitions maximales : difficulté de
l'exercice + 0 à 3 paliers selon le nombre ; tenue ; 1RM rapporté au poids du corps, seuils du § 7.7) —
toujours la borne **basse** de la fourchette déclarée — sinon de l'expérience déclarée, sinon d'un niveau
débutant. Une tenue sur un exercice d'appoint (suspension, gainage) ne vaut pas plus d'un palier. Un
objectif « première répétition » ou « figure à débloquer » sur un exercice sans niveau déclaré dit que
l'exercice n'est pas acquis : il est préparé par ses paliers, pas programmé.

**Séance de repli.** Si, un jour donné, rien n'est admissible dans les disciplines du profil (cardio seul
avec une gêne de 9/10 à la cuisse, par exemple), ce jour reçoit de la mobilité et de la marche, puis à
défaut tout exercice admissible, avec la raison `plan.joint_limitation` ou `plan.equipment_available` —
plutôt qu'une séance vide.

### 3.3 Séries de référence et durée estimée

Chaque exercice a une prescription de référence (§ 5.1) : séries, plage, repos. La durée d'un exercice est
`transition (45 s) + montée en charge éventuelle + séries × (effort + repos)`, l'effort étant compté à 3 s
par répétition (par côté pour un unilatéral). La séance ajoute un échauffement général (2, 3 ou 5 min selon
sa durée) dès qu'elle contient du renforcement, du conditionnement ou du cardio intense.

Les séries de la séance sont une fonction de la seule liste de ses exercices : séries par défaut ; si la
séance dépasse `T_j`, une série est retirée à la fois, à l'assistance d'abord, aux polyarticulaires en
dernier, jamais sous le minimum d'un exercice ; sinon le temps restant va au cardio continu. Une séance qui
ne tient pas même au minimum est inadmissible.

### 3.4 Note

Quatorze composantes, chacune entre 0 et 1, rendues avec leur poids dans `PlanScore` :

| Code | Poids | Mesure |
| --- | --- | --- |
| **Sécurité** | | |
| `recovery` | 0,65 | 1 − 2 × (séries lourdes d'un même muscle principal placées deux jours séparés de moins de 48 h) / (séries lourdes). Lourd : au moins 2 séries directes dans la séance. |
| `fatigue_balance` | 0,15 | Écart moyen de la fatigue systémique par minute entre les séances ; sans effet sous 30 %. |
| `joint_load` | 0,20 | Part du temps passée sur des exercices qui chargent une zone limitée, pondérée par la gêne. |
| **Qualité** | | |
| `goal_specificity` | 0,16 | Chaque objectif reçoit deux expositions par semaine (une seule pour moins de trois séances), comptées en soutien : l'exercice même 100, un palier de sa chaîne 90 − 6 par palier d'écart, un exercice du même schéma 50 ou 30. Si l'exercice visé est admissible, la moitié de la note demande sa présence. Les quatre mouvements de compétition sont des objectifs implicites du streetlifting. |
| `discipline_dosage` | 0,12 | 1 − demi-somme des écarts entre la part du temps de chaque classe et la part demandée. |
| `muscle_volume` | 0,12 | 70 % : chaque groupe majeur dans sa bande de séries hebdomadaires (sous le bas : proportionnel, moins un supplément sous la dose minimale de 4 séries ; au-dessus du haut : −2 par bande dépassée) ; 30 % : groupes travaillés au moins deux jours. |
| `pattern_balance` | 0,10 | 30 % tirage / poussée entre 1,0 et 1,5 ; 20 % chaîne postérieure / genou entre 0,75 et 1,5 ; 15 % tronc deux jours par semaine ; 35 % schémas de base couverts parmi ceux que le vivier permet. |
| `discipline_structure` | 0,14 | Moitié : affinité moyenne des exercices pour leur discipline. Moitié : structure propre — renforcement : chaque séance attendue s'ancre sur un mouvement de base ; calisthénie : une figure par séance, les figures prioritaires trois jours par semaine ; CrossFit : force ou technique puis pièce de trois mouvements ; cardio : environ 20 % de séances intenses à partir du niveau intermédiaire, jamais chez un débutant ou en mode prudent ; mobilité : régions couvertes et en rapport avec le travail du jour. |
| `time_use` | 0,08 | Moitié : part du temps utilisée (pleine à 90 %), ramenée à 1 quand tous les groupes ont atteint le haut de leur bande ; moitié : séance la moins remplie rapportée à la plus remplie. |
| `variety` | 0,06 | Pénalise deux exercices de la même chaîne dans une séance, plus de deux du même schéma, plus de deux exercices de tronc, et un même exercice répété dans la semaine sans raison (figure, cardio, mobilité, objectif, programme de trois séances ou moins). |
| `exercise_fit` | 0,10 | Moyenne de l'adéquation des exercices : mouvement de base de sa chaîne (racine, chaîne fournie), difficulté proche du niveau, exercice su ; un exercice rogné sous sa dose de référence vaut d'autant moins ; la moyenne porte au moins sur le nombre d'exercices attendu (un par tranche de 12 min). |
| `stimulus_fatigue` | 0,03 | Rapport moyen entre les groupes majeurs travaillés et la fatigue de l'exercice (champs `calc.fatigue` de la base). |
| `preferences` | 0,07 | Moitié : exercices aimés présents (4 au plus) ; moitié : exercices sus présents (6 au plus). |
| `novelty` | 0,02 | Au plus 2 (débutant) ou 3 exercices techniques nouveaux à la fois. |

`sécurité = Σ poids × composante / Σ poids` sur les trois premières, `qualité` de même sur les onze autres,
et `note = 0,3 × sécurité + 0,7 × qualité` (`PlanScore.total`).

**Volume par muscle.** Quatorze groupes majeurs (pectoraux, trois faisceaux du deltoïde, grand dorsal, haut
du dos, biceps, triceps, abdominaux, lombaires, fessiers, quadriceps, ischio-jambiers, mollets) et trois
mineurs sans plancher (avant-bras, adducteurs, trapèzes supérieurs). Une série crédite 1 aux muscles
principaux et 0,5 aux muscles secondaires (comptage fractionnaire) ; le gainage ne crédite que ses muscles
principaux ; le cardio, le conditionnement et la mobilité ne créditent rien ; les séries de **pratique**
— force maximale sur un mouvement d'objectif, figures, puissance : courtes et loin de l'échec — comptent
pour moitié. La bande dépend du niveau (4–10, 8–16, 12–20 séries par semaine), est réduite quand le temps
de renforcement ne permet pas d'atteindre son milieu (0,9 série créditée par minute), suit le résumé
d'adaptation (× 0,85 ou × 1,1), et son haut ne descend jamais sous 5 séries. Un groupe qu'aucun exercice
admissible ne travaille directement n'a ni plancher ni poids.

### 3.5 Objectif de la recherche

`objectif = sécurité + note − 0,01 × (emplacements changés) − pénalité de diversité`

La sécurité compte donc `(0,3 + 1) / 0,7 ≈ 1,86` fois la qualité : elle passe d'abord, sans marche
d'escalier (une priorité strictement lexicographique bloquait la recherche gloutonne sur des paliers, voir
`DECISIONS_GP.md`, G4). La pénalité de changement ne vaut qu'en régénération (§ 4), la pénalité de
diversité que pour « Autre proposition » (§ 3.7).

### 3.6 Recherche

1. **Amorce** : un exercice pour chaque schéma de base (genou, tirages, poussées, charnière, tronc) que le
   vivier permet, au jour où il sert le mieux la note.
2. **Glouton avec anticipation** : parmi une liste courte de candidats (les 6 plus utiles par classe en
   manque et 6 toutes classes confondues, classés par besoin : dosage, volume, schémas, objectifs, goûts),
   l'ajout qui améliore le plus l'objectif, en regardant un ajout plus loin pour les 3 meilleurs ; arrêt
   quand plus aucun ajout n'améliore. Une séance vide est remplie d'abord.
3. **Recuit simulé** (Kirkpatrick et al. 1983) : 12 000 coups — remplacer (55 %), ajouter, au besoin en
   retirant un ou deux exercices pour faire de la place (15 %), retirer (15 %), déplacer vers un autre jour
   (15 %) — acceptés s'ils améliorent, sinon avec la probabilité `exp(Δ / température)`, la température
   décroissant de 0,02 à 0,0004 ; on garde le meilleur état rencontré.
4. **Descente** : pour chaque emplacement, le meilleur remplacement parmi ses 12 plus proches voisins ;
   retraits qui améliorent ; schémas de base encore manquants (avec échange) ; glouton élargi (36 candidats).
   Trois passages au plus.

Le hasard vient d'une suite xorshift32 (Marsaglia 2003) à graine fixe pour la meilleure proposition
(graine 0), dérivée du rang de la proposition pour les suivantes (§ 3.7), de la graine et de l'emplacement
visé pour une revue : à requête égale, la suite est toujours la même. Les candidats sont triés par valeur puis par identifiant, et les égalités restantes sont départagées par
le hachage FNV-1a de l'identifiant de l'exercice : le résultat ne dépend d'aucun ordre d'itération.

**Convergence mesurée** (`docs/MESURES.md`, § 5). L'objectif moyen des 40 profils types passe de 1,9520
(glouton seul) à 1,9552 à 3 000 coups et 1,9572 à 12 000 coups, l'effort retenu ; doubler encore l'effort
améliore 21 profils et en dégrade 17, pour un gain moyen de 0,0004 sur une échelle de 0 à 2. Le recuit ne garantit pas
l'optimum : le programme rendu est le meilleur **trouvé**.

**Sensibilité mesurée** (§ 6 du relevé). Multiplier un poids par 0,8 ou 1,2 change une bonne part des
exercices (recouvrement de Jaccard de 0,39 à 0,52), pour un regret d'environ 0,001 : beaucoup de
programmes sont presque équivalents au sens de la note. Les poids fixent des priorités, pas un classement
fin entre exercices voisins ; c'est ce que « Autre proposition » exploite.

### 3.7 « Autre proposition »

Les graines 1, 2, … d'une même requête forment une suite : la proposition `k` repart de la meilleure,
subit un recuit avec une pénalité de ressemblance aux propositions déjà montrées (les 8 dernières), et
n'est retenue que si elle garde le palier de sécurité de la meilleure (paliers de 0,05) et une note à moins de 3 % de la
sienne ; parmi trois essais de pénalité décroissante, on garde le premier qui atteint un tiers d'exercices
non verrouillés absents de chacune des propositions montrées, sinon le plus différent. Mesuré sur les
profils types : note toujours au-dessus de 97 % de la meilleure (minimum mesuré : 98,1 %) ; le tiers est atteint
pour 92 % des propositions (les viviers étroits — mobilité seule, marche — n'ont pas assez d'exercices).

## 4. Revue, variantes, diff minimal

**Actions.** `can_do` : verrouille l'emplacement, note l'exercice comme su, rien ne bouge. `cannot_do` :
exclut l'exercice (partout), le remplace par une variante plus facile, note l'exercice comme non su.
`dislike` : exclut l'exercice, le remplace, l'ajoute aux exercices non aimés. `remove` : retire
l'emplacement ; l'exercice ne revient pas ce jour-là dans cette régénération (sauf séance qui serait vide).
`replace` : met la variante choisie et la verrouille. `add` : ajoute l'exercice au jour dit, verrouillé,
et le note comme aimé.

**Diff minimal.** Après l'action, le reste est ré-optimisé (réparation des séances devenues trop longues,
500 coups de recuit, descente) sous une pénalité de 0,01 par emplacement changé, puis chaque changement
dont l'annulation ne ferait pas baisser l'objectif est annulé. Garantie testée : l'objectif pénalisé du
résultat n'est jamais inférieur à celui de l'action seule ; ce qui est verrouillé ne bouge pas. Mesuré
(`docs/MESURES.md`, § 3) : trois actions `cannot_do` sur quatre et quatre actions `dislike` sur cinq ne changent rien d'autre ;
après un `remove`, six fois sur dix.

`ReviewResult.diff` décrit exactement les emplacements dont l'exercice a changé (`exercise_replaced`,
`exercise_added`, `exercise_removed`, `exercise_moved`) et les séances réordonnées (`order_changed`), avec
les raisons (`plan.user_*` pour l'emplacement visé, `plan.reoptimized` avec la note avant et après pour
le reste).

**Variantes.** Candidats : exercices du vivier faisables ce jour-là, absents de la séance, qui tiennent
dans son temps. Ciblées : *plus facile* (le parent dans `variante_de`, sinon un ancêtre, sinon la plus
proche de la même chaîne, du même schéma, de la même famille — difficulté strictement inférieure) ;
*équivalente* (même schéma, difficulté à ± 1, la plus proche) ; *autre matériel* (matériel nécessaire
différent, même schéma d'abord). Puis toutes les compatibles de proximité ≥ 0,45, triées. Proximité
(`planSimilarity`, symétrique, 1 pour un exercice et lui-même) : 0,45 × cosinus des vecteurs musculaires
+ 0,20 × schéma + 0,10 × plan + 0,10 × écart de difficulté + 0,10 × même chaîne + 0,05 × même unité.

## 5. Passe 2

### 5.1 Prescription de référence

| Famille | Séries (débutant → élite) | Plage | Repos | RIR visé |
| --- | --- | --- | --- | --- |
| Force, mouvement d'objectif (charge réglable) | 3 → 5 | 3–6 (débutant 5–8) | 180 s (150 s) | 3 → 2 |
| Force, assistance polyarticulaire (disciplines de force) | 3 → 4 | 5–8 (6–10) | 150 s | 3 → 2 |
| Polyarticulaire, charges modérées | 3 → 4 | 6–10 (8–12) | 120 s | 3 → 1,5 |
| Isolation | 2 → 3 | 10–15 | 75 s | 3 → 1 |
| Poids du corps | 3 → 4 (isolation 2 → 3) | moitié à trois quarts du maximum connu ; sinon 3–8 à 12–20 selon la marge | 90 s (75 s) | 3 → 2 |
| Figure tenue | 3 → 5 | 5–10 s ou 10–20 s ; moitié à trois quarts de la tenue connue | 120 s | 3 → 2,5 |
| Figure dynamique | 3 → 5 | 2–5 | 150 s | 3 → 2,5 |
| Haltérophilie | 3 → 5 | 2–3 | 150 s | 3 |
| Pliométrie / balistique | 2 → 4 | 5–8 / 10–15 | 90 s / 75 s | 3 |
| Tronc | 2 → 3 | 10–15, ou tenue 10–20 s / 20–40 s | 60 s | 3 → 2 |
| Conditionnement | 3 → 5 tours | 8–12 (3–6 si difficile), 30–40 s | 15 s | — |
| Cardio continu | 20 → 45 min (marche 20–30, sortie longue 40–90) | — | — | — |
| Fractionné / sprints | 4 → 8 répétitions | 60–90 s, 30/30, distance du nom | égal à l'effort, 180 s au plus | — |
| Étirement tenu / mobilité | 2 (3 en élite) | 20–30 s (30–45 s : souplesse, 65 ans et plus) / 8–12 | 10 s | — |

Programme prudent ou senior : 3 séries au plus par exercice, jamais moins de 3 répétitions en réserve.
Aucun exercice coté en effort ne dépasse sa dose de référence de plus d'une série : le volume vient
d'exercices en plus, pas de séries empilées.

La passe 2 règle d'abord les séries de référence, une à la fois, tant que la note s'améliore et que la
séance tient dans son temps.

### 5.2 Semaines

Bloc de 4, 5 ou 6 semaines (débutant, intermédiaire, avancé et élite), ou `blockWeeks`.

| Semaine | Séries | RIR |
| --- | --- | --- |
| Introduction (la première) | 75 % | +1 |
| Montée | de 85 % à 100 % | de +1 à 0, par demi-point |
| Décharge (la dernière, à partir du niveau intermédiaire, sans objectif de performance) | 60 % | +2 |
| Test (la dernière, s'il y a un objectif de performance et que le programme n'est pas prudent) | 60 %, sauf l'épreuve | +2 |

Flammes visées : `Flames.fromRir` (kalis_core). La dernière semaine de montée abaisse d'une répétition la
plage des mouvements de force. Un débutant sans objectif termine sur une semaine de montée.

**Test (« boss »).** Un par objectif de performance, sur l'exercice de l'objectif s'il est au programme,
sinon sur son meilleur palier (soutien ≥ 70). Objectif de 1RM : montée 3 répétitions à 80 %, 1 à 90 %,
1 à 96 % du 1RM connu (`setTargets`) — une série lourde à une répétition en réserve, jamais une tentative
maximale. Répétitions ou tenue : une série (ou deux tenues) à l'effort maximal. Figure à débloquer : trois
essais. Temps sur une distance : la distance de l'objectif.

### 5.3 Charges de départ

Seulement si un 1RM est connu (déclaré, borne basse, ou estimé par le moteur dynamique après trois
observations, estimation moins une erreur type) et que la série reste dans le domaine de la formule
(répétitions + réserve ≤ 15) :

`charge = arrondi inférieur au pas ( 0,90 × 1RM total / (1 + (répétitions hautes + RIR) / 30) − part du poids du corps )`

(0,95 au lieu de 0,90 quand le 1RM vient du moteur dynamique, déjà prudent). Le 1RM total d'un exercice
lesté comprend la part du poids du corps portée (`fraction_pdc` de la base). Pas et minimum : ceux du
profil (`loadIncrements`), sinon 2,5 kg à partir de 20 kg (barre), 2 kg (haltères), 4 kg (kettlebell),
5 kg (machine), 2,5 kg (poulie), 1,25 kg (lest). Sans 1RM : aucune charge inventée — la part du 1RM visée
est donnée comme repère, et la première semaine porte une série de calibrage (`SetKind.calibration`).
Tout exercice de renforcement dont la capacité n'a pas encore été observée est marqué `toCalibrate`.

## 6. Blocs glissants et restructuration

**Bloc suivant.** (1) Les exercices mal tolérés ou devenus inadmissibles sont remplacés
(`plan.adaptation_applied`). (2) Un exercice sans charge maîtrisé (15 répétitions ou 60 s de tenue, 15 s
pour une figure) passe au palier suivant de sa chaîne s'il est admissible
(`plan.progression_from_previous_block`). (3) 40 % de l'assistance (isolation, tronc, mobilité,
conditionnement) tourne (`plan.variety`), le choix étant fixé par hachage ; les mouvements principaux, les
figures et les exercices d'objectif restent. (4) Ré-optimisation sous pénalité de changement. Les verrous
de la revue du bloc précédent ne gèlent pas le bloc suivant : seuls ceux de la requête comptent. Le volume
suit le résumé d'adaptation : × 0,85 si moins de 60 % des séances ont été faites ou si la fraîcheur est
sous 0,4 ; × 1,1 si au moins 90 % ont été faites, avec une confiance d'au moins 0,5 et une fraîcheur d'au
moins 0,6.

**Restructuration.** Les raisons du moteur dynamique sont lues : douleur signalée (zone et intensité →
limitation), exercice sauté ou en stagnation (écarté), temps réduit (minutes du jour), fatigue ou bilan
bas (volume × 0,85). Portée `session` : un seul jour bouge ; `week` : une seule semaine de la passe 2
bouge, la semaine type reste ; `block` : toutes les semaines à partir de `fromWeekIndex`. Les semaines
d'avant `fromWeekIndex` sont rendues à l'identique, la nature de chaque semaine est conservée (testé).

## 7. Paramètres et références

Chaque valeur est dans `PlanParams` (`lib/src/params.dart`) ou en constante nommée. « Référence » : la
valeur vient d'une publication citée. « Hypothèse » : choix d'ingénierie, sans publication qui le fixe ;
il est alors justifié par une mesure ou signalé comme tel au registre (§ 10).

### 7.1 Volume, fréquence, proximité de l'échec

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Bandes de séries hebdomadaires par groupe | 4–10 (débutant), 8–16 (intermédiaire), 12–20 (avancé, élite) | Référence : relation dose-réponse du volume (Schoenfeld et al. 2017 : moins de 5, 5 à 9, 10 séries et plus par semaine ; +0,37 % par série) ; 12 à 20 séries pour des hommes entraînés (Baz-Valle et al. 2022, sept études) ; 4 séries par semaine comme dose minimale efficace pour l'hypertrophie (Pelland et al. 2026). Hypothèse : le découpage par niveau et le plafond à 20 — la littérature ne montre pas de plateau net (Pelland et al. 2026), le plafond est un choix de prudence. |
| Comptage fractionnaire (1 / 0,5) | — | Référence : Pelland et al. 2026 (le comptage fractionnaire prédit le mieux l'hypertrophie et la force). |
| Séries de pratique comptées pour moitié | 0,5 | Hypothèse, appuyée sur Robinson et al. 2024 (l'hypertrophie croît à l'approche de l'échec, pas la force) : les bandes viennent d'études sur des séries proches de l'échec. Refalo et al. 2023 : pas de supériorité nette de l'échec lui-même. |
| Supplément sous la dose minimale | manque × 1,5 sous 4 séries | Référence pour le seuil (Pelland et al. 2026) ; hypothèse pour le facteur. |
| Fréquence : groupe travaillé deux jours | 30 % de la composante | Référence : deux séances par semaine font mieux qu'une à volume non égalisé (Schoenfeld et al. 2016) ; à volume égal la fréquence compte peu pour l'hypertrophie et davantage pour la force (Pelland et al. 2026). |
| Expositions d'un objectif | 2 par semaine | Référence : même source (force) ; dose minimale d'une série lourde par semaine (Androulakis-Korakakis et al. 2020). |
| Séries par exercice | 2 à 5 | Référence : Ralston et al. 2017, Rhea et al. 2003 ; ACSM 2009. |
| RIR visé (3 → 1 selon le niveau et la famille) | — | Référence : échelle RIR (Zourdos et al. 2016 ; Helms et al. 2016) ; estimation des répétitions restantes sous-estimée d'environ une répétition (Halperin et al. 2022) — d'où un RIR d'au moins 3 pour un débutant. |
| Crédits par minute de renforcement | 0,9 | Mesure : 0,94 en moyenne, 0,97 en médiane sur les profils types (`docs/MESURES.md`, § 7). |

### 7.2 Charges, plages, repos, ordre

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Plages par famille (§ 5.1) | — | Référence : continuum des répétitions (Schoenfeld et al. 2021 ; Schoenfeld et al. 2017, charges lourdes et légères) ; 60–70 % du 1RM pour novices et intermédiaires (ACSM 2009). |
| Repos | 180–150 s (force), 120 s, 75–90 s (isolation, poids du corps) | Référence : plus de 2 min pour la force chez les entraînés, 60–120 s chez les débutants (Grgic et al. 2018) ; repos longs favorables (Schoenfeld et al. 2016) ; pour l'hypertrophie, petit bénéfice au-delà de 60 s, aucun au-delà de 90 s (Singer et al. 2024) ; ACSM 2009. |
| Ordre : figures et puissance, polyarticulaires, isolation, tronc, conditionnement, étirements | — | Référence : l'exercice placé en premier progresse le plus (Simão et al. 2012 ; Nunes et al. 2021) ; grands groupes avant petits (ACSM 2009). Le cardio passe d'abord quand il est la discipline principale. |
| Formule de 1RM | Epley, diviseur 30, jusqu'à 15 répétitions avant l'échec | Référence : Epley 1985 (ouvrage) ; les équations linéaires sont fiables jusqu'à 10 répétitions environ (Reynolds et al. 2006) — hypothèse pour l'extension à 15, compensée par la prudence. |
| Prudence de la charge de départ | 0,90 (0,95 si 1RM estimé) | Hypothèse : marge sur l'erreur de la formule et sur la borne déclarée ; la charge est « à calibrer » et le moteur dynamique la corrige. |
| Durée d'une répétition | 3 s | Hypothèse d'estimation (les tempos usuels vont de 2 à 8 s : Wilk et al. 2021). |
| Transition entre exercices | 45 s | Hypothèse d'estimation. |
| Tenues isométriques | 5–20 s par série | Référence : Lum et Barbosa 2019 (force : contractions de 1 à 5 s proches du maximum, 30 à 90 s par séance ; hypertrophie : 3 à 30 s, 80 à 150 s). Oranchuk et al. 2019 porte sur le tendon, pas sur la force. |
| Étirements | 20–30 s, 30–45 s après 65 ans | Référence : Garber et al. 2011 (10–30 s, 30–60 s chez les plus âgés) ; durée hebdomadaire totale plus que durée par série (Thomas et al. 2018) ; étirements statiques longs en fin de séance (Behm et al. 2016). |

### 7.3 Récupération, semaines, variété

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Délai entre deux sollicitations lourdes d'un muscle | 48 h | Référence : Garber et al. 2011 (48 h) ; récupération de 24 à 48 h après des séries menées à l'échec (Morán-Navarro et al. 2017), jusqu'à 72 h après squat, développé couché ou soulevé de terre lourds (Belcher et al. 2019). Aucune revue systématique ne fixe la valeur : 48 h est la borne basse. |
| Écart de fatigue toléré entre séances | 30 % | Hypothèse (la monotonie de la charge est un facteur de risque : Foster 1998). |
| Décharge | dernière semaine d'un bloc de 5 ou 6 semaines, 60 % des séries, RIR +2 | Référence : consensus d'experts (Bell et al. 2023 : environ une semaine toutes les 4 à 6 semaines) et pratiques déclarées (Rogerson et al. 2024). Réserve : un essai contrôlé ne montre pas de bénéfice d'une semaine d'arrêt (Coleman et al. 2024) ; la décharge est donc une réduction, pas un arrêt, et reste un choix de prudence. |
| Introduction | 75 % des séries, RIR +1 | Hypothèse (montée progressive ; ACSM 2009). |
| Rotation de l'assistance entre deux blocs | 40 % | Référence : varier les exercices aide, un excès de variation nuit (Kassiano et al. 2022 ; Fonseca et al. 2014). Hypothèse pour la valeur. |
| Tirage / poussée | 1,0 à 1,5 | Hypothèse (déséquilibres d'épaule chez les pratiquants : Kolber et al. 2009). |
| Chaîne postérieure / genou | 0,75 à 1,5 | Hypothèse. |
| Cardio intense | 20 % des séances de cardio, à partir du niveau intermédiaire | Référence : répartition 80/20 chez des athlètes d'endurance (Seiler 2010, sportifs de haut niveau — extrapolation) ; le fractionné améliore davantage la VO2max (Milanović et al. 2015). |
| Forme générale | 50 % renforcement, 35 % cardio, 15 % mobilité | Référence : OMS 2020 (Bull et al.) — activité aérobie et renforcement au moins deux jours par semaine ; Garber et al. 2011. Hypothèse pour les parts. |
| Seniors (65 ans et plus), mode prudent | sans impact, un palier plus bas, 3 séries au plus, RIR ≥ 3 | Référence : Fragala et al. 2019 (le renforcement est recommandé et sûr, 1 à 3 séries, progression) ; hypothèse pour le seuil d'âge. |
| Cardio et renforcement dans un même programme | aucune pénalité | Référence : pas d'interférence sur l'hypertrophie et la force maximale (Schumann et al. 2022) ; la force explosive peut en souffrir (Wilson et al. 2012) — non modélisé (§ 9). |
| Échauffement général | 2, 3 ou 5 min | Référence : l'échauffement améliore la performance (Fradkin et al. 2010). Hypothèse pour les durées et pour les séries de montée en charge (90 à 150 s réservées aux mouvements lourds). |

### 7.4 Recherche et régénération

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Coups de recuit (création, autre proposition, revue) | 12 000, 6 000, 500 | Mesure : convergence (`docs/MESURES.md`, § 5) et temps (§ 2). |
| Températures | 0,02 → 0,0004 | Hypothèse : de l'ordre d'un échange d'exercice (0,01) à celui d'un départage. |
| Liste courte, anticipation, voisins | 6, 3, 12 | Hypothèse ; temps mesurés. |
| Pénalité de changement | 0,01 par emplacement | Mesure : diff minimal (`docs/MESURES.md`, § 3). |
| Tolérance et distance d'« Autre proposition » | 3 %, un tiers | D4.2. |
| Palier de sécurité d'« Autre proposition » | 0,05 | Hypothèse : une autre proposition ne perd pas plus d'un palier de sécurité sur la meilleure. |
| Part de la sécurité dans la note, priorité dans l'objectif | 0,3 ; +1,0 | Hypothèse ; aucune contrainte dure violée sur 10 240 profils. |
| Poids de la note | § 3.4 | Hypothèse ; sensibilité mesurée (`docs/MESURES.md`, § 6). |

### 7.5 Limitations

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Gêne à partir de laquelle une contrainte forte est écartée | 4/10 | Hypothèse (l'ancien générateur filtrait au-dessus de 3/10). |
| Gêne à partir de laquelle une contrainte modérée est écartée | 7/10 | Hypothèse. |

### 7.6 Disciplines

`disciplineAffinity` (0 à 100) dit quelles disciplines de la base nourrissent chaque discipline du profil :
0 = hors de la discipline. Hypothèse d'ingénierie.

| Discipline du profil ↓ / de la base → | Musculation | Street workout | Streetlifting | Calisthénie statique | Calisthénie dynamique | CrossFit | Cardio | Mobilité |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Musculation | 100 | 60 | 50 | 0 | 0 | 0 | 0 | 0 |
| Street workout | 40 | 100 | 50 | 30 | 60 | 0 | 0 | 0 |
| Streetlifting | 60 | 60 | 100 | 20 | 30 | 0 | 0 | 0 |
| Calisthénie | 30 | 60 | 30 | 100 | 100 | 0 | 0 | 0 |
| CrossFit | 60 | 50 | 0 | 20 | 40 | 100 | 50 | 0 |
| Cardio | 0 | 0 | 0 | 0 | 0 | 0 | 100 | 0 |
| Mobilité | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 100 |
| Forme générale (renforcement) | 90 | 90 | 0 | 0 | 0 | 0 | 0 | 0 |

Pour le CrossFit, la ligne est corrigée par nature d'exercice hors de sa propre discipline : isolation 20 ;
mouvements de puissance et polyarticulaires à barre, haltères ou kettlebell de la musculation 90 ; street
workout et calisthénie dynamique 70.

### 7.7 Seuils de 1RM

Rapport du 1RM (charge totale) au poids du corps qui fait passer du niveau débutant aux suivants : squat
0,75 / 1,25 / 1,75 ; charnière 1,0 / 1,5 / 2,0 ; développé couché 0,6 / 1,0 / 1,4 ; développé au-dessus
de la tête 0,4 / 0,65 / 0,9 ; traction lestée 1,1 / 1,3 / 1,55 ; dips lesté 1,15 / 1,45 / 1,75 ; muscle-up
lesté 1,02 / 1,1 / 1,2 ; tirage vertical à charge externe 0,6 / 0,9 / 1,2 ; tirage horizontal à charge externe
et haltérophilie 0,5 / 0,8 / 1,1. Seuils multipliés par 0,65 (haut du
corps) ou 0,75 (bas du corps) pour une femme, 0,85 si le sexe n'est pas renseigné (pour un exercice lesté,
le facteur ne porte que sur ce qui dépasse le poids du corps). Hypothèse d'ingénierie, sans publication :
voir le registre (§ 10).

## 8. Invariants testés

Les tests de propriétés jouent 10 240 profils aléatoires seedés (`test/properties*.dart`). Chacun passe par
la création et une action de revue ; une part fixe, choisie par la graine, passe aussi par les variantes
(1 sur 2), la passe 2 (1 sur 2), le bloc suivant (1 sur 8) et la restructuration (1 sur 8).

| Invariant | Test |
| --- | --- |
| Aucune contrainte dure violée (relecture par `PlanInspector.hardViolations`) ; sortie valide au sens du contrat (`validate`) ; identifiants d'exercice du catalogue ; codes de raison du registre | `test/properties*.dart` : création et revue (10 240 profils), bloc suivant et restructuration (1 280 chacun) ; `test/smoke_test.dart` : 40 profils types |
| Note relue = note rendue | idem (`PlanInspector.scoreOf`) |
| Déterminisme à l'octet près sur deux moteurs neufs | `test/properties*.dart` : création et revue (1 profil sur 4), passe 2 (1 sur 12), bloc suivant et restructuration (tous ceux joués) ; `test/engine_test.dart` : 40 profils types, cache |
| Indépendance à l'ordre des disponibilités, du matériel, des niveaux et des goûts | `test/engine_test.dart` (12 profils types) |
| Verrous intacts après régénération (`keep_slot`, `require_exercise`, `exclude_exercise`) | `test/properties*.dart`, `test/engine_test.dart` ; `keep_day` : un cas dans `test/engine_test.dart` |
| Diff minimal : objectif pénalisé du résultat ≥ celui de l'action seule ; le diff décrit exactement les changements | `test/properties*.dart` |
| Variantes : admissibles ce jour-là, absentes de la séance, triées, au plus trois ciblées de natures distinctes | `test/properties*.dart` (1 profil sur 2) |
| « Autre proposition » : note ≥ 97 % de la meilleure, palier de sécurité tenu, contraintes dures ; un tiers d'exercices différents quand le vivier le permet | `test/engine_test.dart` (40 profils types, graines 1 à 3) |
| Passe 2 : nature des semaines, flammes de 1 à 10, charges ≥ 0, part du 1RM entre 0 et 1, aucune séance au-delà du temps | `test/properties*.dart` (1 profil sur 2) |
| Passe 2 : charges ≤ 90 % de la charge d'Epley en haut de plage, multiples du pas déclaré ; épreuves, calibrage | `test/units_test.dart` (40 profils types) |
| Restructuration : contraintes dures, semaines passées intactes, portée respectée, nature des semaines conservée | `test/properties*.dart` (1 profil sur 8) |
| Non-ressemblance au programme du propriétaire | `test/resemblance_test.dart` (40 profils types, 600 profils aléatoires) |

**Ce que la relecture vérifie par un code à part, et ce qu'elle partage.** `hardViolations` recalcule
elle-même, sans passer par le vivier : matériel et lieu du jour, exercices détestés ou exclus, contrainte
articulaire face à la gêne déclarée, doublons, séances vides, verrous, nombre d'exercices. Pour les règles
`discipline`, `level`, `prerequisite`, `reserved`, `too_easy`, `cautious` et pour la durée d'une séance,
elle s'appuie sur le même code d'admission et de durée que le moteur (`PlanContext`, `Scorer.timeOfDay`) :
ces règles-là sont garanties **appliquées** (un exercice refusé par le vivier ne peut pas apparaître), mais
une erreur dans la règle elle-même ne serait pas vue par les tests de propriétés. Le mode prudent et les
exercices réservés sont relus une seconde fois, à partir des seuls champs du catalogue, par
`test/admission_test.dart` (40 profils types, 600 profils aléatoires) ; niveau, prérequis et « trop
facile » ne reposent que sur la lecture des 40 programmes. Les plages de répétitions ne font l'objet d'aucune propriété testée.

## 9. Limites connues

- **Meilleur programme trouvé, pas optimum prouvé** (§ 3.6). Deux programmes très différents peuvent avoir
  presque la même note ; la note ne départage pas finement des exercices voisins.
- **Les durées sont des estimations** (3 s par répétition, 45 s de transition, repos nominaux) : elles ne
  sont pas encore confrontées à des séances réelles. Le moteur dynamique corrigera à l'usage.
- **Volume en fin de bande.** Quand tous les groupes ont atteint le haut de leur bande, les séances restent
  plus courtes que le temps donné (élite en calisthénie 6 × 90 min : environ 55 min par séance). Le plafond
  de 20 séries est un choix de prudence.
- **Comptage du volume.** Les séries de pratique comptent pour moitié : comptées à plein, les disciplines
  de force et de figures dépassent 20 séries par semaine sur plusieurs groupes (`docs/COMPARAISON_L10.md`).
- **Petits groupes souvent sous leur bande** : mollets, lombaires, deltoïde moyen ou ischio-jambiers quand
  le matériel manque (parc, maison) — le moteur ne force pas une isolation que le vivier n'offre pas.
- **Très peu de temps** (une séance de 20 min) : tous les schémas de base ne tiennent pas ; le dosage de la
  forme générale n'est pas atteint (pas de cardio).
- **Mouvement principal.** Le rôle `main` va au premier polyarticulaire dans l'ordre de fatigue : ce n'est
  pas toujours le mouvement qu'un entraîneur mettrait en tête d'affiche.
- **Pas de découpage imposé** (haut/bas, poussée/tirage/jambes) : la règle des 48 h et l'équilibre des
  schémas en tiennent lieu ; les thèmes de séance sont déduits, pas planifiés.
- **CrossFit** : les séances ont une partie de force puis une pièce de conditionnement, mais pas les formats
  codifiés (AMRAP, EMOM, tours chronométrés).
- **Cardio** : pas de plan d'allure ni de progression du kilométrage ; la sortie longue n'est pas réservée
  au jour le plus long.
- **Interférence** entre endurance et force explosive non modélisée.
- **Semaine type unique** : les mêmes exercices toute la durée du bloc (hors restructuration) ; pas
  d'ondulation des charges au sein de la semaine.
- **Seuils de niveau par 1RM** et **table d'affinité** : hypothèses d'ingénierie (§ 7.6, 7.7).
- **Séance de repli** : quand une limitation rend la discipline impraticable, le moteur propose de la
  mobilité et de la marche ; il ne remplace pas un avis médical (règle santé L13, portée par l'application).
- **Diff minimal non garanti petit** : une action `cannot_do` ou `dislike` exclut l'exercice de toute la
  semaine ; dans le pire cas mesuré, 12 autres emplacements changent (`docs/MESURES.md`, § 3).
- **Relecture en partie partagée** : les règles d'admission du vivier ne sont pas revérifiées par un second
  code (§ 8).
- **Déterminisme entre machines** : construit pour être identique sur toute machine native, vérifié sur une
  seule (§ 2) ; le Web n'est pas pris en charge.
- **Catalogue** : le moteur hérite des champs calculés de la base (muscles, contraintes, difficulté) tels
  qu'ils sont ; `kalis_core/docs/RELECTURE_CATALOGUE.md` liste ce qui reste à relire.

**Chemin street (0.2.0, § 12).** Limites constatées dans le code :

- **Programme construit, pas cherché** : le squelette suit des règles fixes par style ; aucune
  optimisation ne le compare à d'autres. La note `PlanScore` rendue est celle du chemin 0.1, relue à
  titre d'information ; elle ne guide aucun choix.
- **Variantes** : `variants` passe toujours par le chemin 0.1 ; une variante proposée peut être
  inadmissible selon les règles du chemin street (seuils de gêne, niveau). Une fois choisie, elle est
  verrouillée et échappe aux règles d'admission.
- **Revue sans ré-optimisation** : l'action est appliquée seule ; un exercice écarté est remplacé par le
  plus proche du même schéma, ou retiré s'il n'y en a pas.
- **Mode prudent** : il écarte les exercices à impact, l'annonce (`plan.cautious_health`), garde 2
  répétitions en réserve au moins, plafonne à 85 % du 1RM les charges calculées par `_loadAt` et
  remplace le test de 1RM par un 3RM ; il ne plafonne pas les séries, et son plancher de réserve (2)
  reste sous celui du chemin 0.1 (3, § 5.1).
- **Restructuration** : la passe 2 est recalculée sans l'historique du bloc précédent ; les repères
  relevés aux tests de ce bloc et la borne de montée du volume entre les deux blocs ne s'appliquent pas.
- **Historique court** : `Prescriber.seed` ne reçoit que les semaines du bloc précédent ; les tests et
  les volumes des blocs plus anciens ne sont pas vus (dates de test, nombre de semaines de tests passées).
- **Échéance en début de semaine** (`_roles`) : une échéance placée avant la première séance de sa
  semaine est portée par la première séance de la semaine, donc après la date réelle ; les séances de
  la semaine précédente ne sont pas allégées.
- **Affûtage de deux semaines et échéance proche** (`shapeBlock`) : si l'échéance tombe dans la
  première semaine du bloc, la semaine d'affûtage prend la place de la semaine de l'échéance, et la
  semaine de compétition vient après.
- **48 h avant un test** : le moteur ne les garantit que pour le tirage vertical (`_eveOfTest`, veille
  d'une semaine de tests) et pour la séance à J−2 d'un test daté ; ailleurs, la note `test_rest` le
  demande sans que le programme le vérifie.
- **Antécédents et excentriques** : aucun filtre n'écarte les excentriques (descentes freinées, nordic)
  quand une zone sollicitée a un antécédent, alors que le texte de la règle (`plan.constraint_history`)
  dit « pas d'excentrique accentué ».
- **Charge minimale** : `_external` remonte au minimum de charge (celui du profil, sinon celui du type
  de charge) une charge calculée plus petite ; la série est alors plus lourde que la part visée.
- **Tenues très courtes** : avec un maintien maximal de 3 à 4 s, la borne basse de 3 s de
  `skill.hold` vaut 75 % à 100 % du maximum, au-delà de la part annoncée.
- **Montée après des semaines légères** (`_limit`) : après trois semaines légères de suite, le
  garde-fou de montée admet le double de la plus chargée d'entre elles.
- **Test daté à 0 répétition** (`athlete.dart`) : un test daté (`benchmarks`) de 0 répétition retire
  l'exercice de la liste des gestes non acquis (et le compte comme su).
- **Course** : au retour d'une semaine allégée (durées × 0,7), la durée des footings remonte de plus
  de 10 % d'un coup, malgré la règle `duration_step`.
- **Sommeil court et stress élevé** : cumulés, ils n'ajoutent qu'une répétition en réserve (les
  facteurs de volume, eux, se cumulent).
- **Code mort** : les notes `push_maintenance` et `reconciled` ont un texte mais ne sont jamais émises ;
  `plannedTrack` (`skeleton.dart`) n'est appelé nulle part et `Method.repsEvent` n'est attribué par
  aucun squelette.
- **Reprise après une coupure** : les répétitions et les charges repartent de repères réduits ; les
  maintiens (secondes) gardent le record déclaré.
- **Gêne du membre supérieur** : une gêne au coude, à l'épaule ou au poignet réduit le plafond du
  tirage (grand dorsal, haut du dos, biceps), pas celui de la poussée.
- **Gel du volume** (sommeil court, stress élevé, perte de poids) : il ne gèle que le nombre de départs
  au chrono ; les autres règles de montée s'appliquent.
- **Figures** : deux figures statiques au plus sont programmées ; l'équilibre et la L-sit ne sont pas
  traitées comme figures principales.
- **Course** : allures seulement si un chrono a été déclaré ; la conversion durée-distance suppose
  2,5 m/s pour tous.
- **Paramètres** : la plupart des seuils sont des « choix raisonnés » (§ 12.10) ; aucun n'a été relu
  par un professionnel diplômé.

## 10. Registre de validation

| Objet | État | Par qui, comment |
| --- | --- | --- |
| Contraintes dures, déterminisme, verrous, diff minimal, variantes, passe 2, blocs | Vérifié, dans la portée dite au § 8 (parts de profils par étape ; règles d'admission partagées avec le moteur) | Tests automatiques sur 10 240 profils aléatoires et 40 profils types (CI `ci-paquets.yml`) |
| Temps de calcul (génération ≤ 1 s, régénération ≤ 300 ms) | Vérifié sur la machine du contrôle | `docs/MESURES.md`, § 2 et 3 ; à remesurer sur téléphone à l'intégration |
| Programmes des 40 profils types | Lus en entier par l'auteur du lot (assistant), plusieurs tours de correction (`docs/VALIDATION.md`, § 2) | **Non relus par un professionnel diplômé** |
| **Contenu sportif** (bandes de volume, plages, repos, semaines, seuils de gêne, seuils de niveau, table d'affinité, choix des exercices) | **Non relu par un professionnel diplômé** | À faire relire avant toute affirmation d'efficacité ou de sécurité ; le moteur ne pose aucun diagnostic et ne remplace pas un avis médical |
| Références bibliographiques | Relevées et relues le 1er octobre 2026 par l'auteur du lot (résumés et textes en ligne) ; les chiffres de Pelland et al. 2026 sont à recontrôler sur le texte intégral | Non relues par un tiers |
| Hypothèses d'ingénierie (§ 7, « Hypothèse ») | Signalées une à une ; sensibilité aux poids mesurée | À arbitrer par le propriétaire ou un professionnel |
| Comparaison au générateur L10 | Mesurée (`docs/COMPARAISON_L10.md`) | La traduction du profil vers les entrées de L10 est celle de l'auteur du lot |
| Non-ressemblance au programme du propriétaire | Mesurée et testée (`docs/VALIDATION.md`, § 4) | — |
| Catalogue | Hérité de kalis_core 0.1.0 | Voir son registre |

## 11. Références

1. American College of Sports Medicine. Progression models in resistance training for healthy adults. *Med Sci Sports Exerc.* 2009;41(3):687-708.
2. Androulakis-Korakakis P, Fisher JP, Steele J. The minimum effective training dose required to increase 1RM strength in resistance-trained men: a systematic review and meta-analysis. *Sports Med.* 2020;50(4):751-765.
3. Baz-Valle E, Balsalobre-Fernández C, Alix-Fages C, Santos-Concejero J. A systematic review of the effects of different resistance training volumes on muscle hypertrophy. *J Hum Kinet.* 2022;81:199-210.
4. Behm DG, Blazevich AJ, Kay AD, McHugh M. Acute effects of muscle stretching on physical performance, range of motion, and injury incidence in healthy active individuals: a systematic review. *Appl Physiol Nutr Metab.* 2016;41(1):1-11.
5. Belcher DJ, Sousa CA, Carzoli JP, et al. Time course of recovery is similar for the back squat, bench press, and deadlift in well-trained males. *Appl Physiol Nutr Metab.* 2019;44(10):1033-1042.
6. Bell L, Strafford BW, Coleman M, Androulakis-Korakakis P, Nolan D. Integrating deloading into strength and physique sports training programmes: an international Delphi consensus approach. *Sports Med Open.* 2023;9:87.
7. Bull FC, Al-Ansari SS, Biddle S, et al. World Health Organization 2020 guidelines on physical activity and sedentary behaviour. *Br J Sports Med.* 2020;54(24):1451-1462.
8. Coleman M, Burke R, Augustin F, et al. Gaining more from doing less? The effects of a one-week deload period during supervised resistance training on muscular adaptations. *PeerJ.* 2024;12:e16777.
9. Epley B. Poundage chart. In: *Boyd Epley Workout.* Lincoln (NE): Body Enterprises; 1985.
10. Fonseca RM, Roschel H, Tricoli V, et al. Changes in exercises are more effective than in loading schemes to improve muscle strength. *J Strength Cond Res.* 2014;28(11):3085-3092.
11. Foster C. Monitoring training in athletes with reference to overtraining syndrome. *Med Sci Sports Exerc.* 1998;30(7):1164-1168.
12. Fradkin AJ, Zazryn TR, Smoliga JM. Effects of warming-up on physical performance: a systematic review with meta-analysis. *J Strength Cond Res.* 2010;24(1):140-148.
13. Fragala MS, Cadore EL, Dorgo S, et al. Resistance training for older adults: position statement from the National Strength and Conditioning Association. *J Strength Cond Res.* 2019;33(8):2019-2052.
14. Garber CE, Blissmer B, Deschenes MR, et al. Quantity and quality of exercise for developing and maintaining cardiorespiratory, musculoskeletal, and neuromotor fitness in apparently healthy adults: guidance for prescribing exercise. *Med Sci Sports Exerc.* 2011;43(7):1334-1359.
15. Grgic J, Schoenfeld BJ, Skrepnik M, Davies TB, Mikulic P. Effects of rest interval duration in resistance training on measures of muscular strength: a systematic review. *Sports Med.* 2018;48(1):137-151.
16. Halperin I, Malleron T, Har-Nir I, et al. Accuracy in predicting repetitions to task failure in resistance exercise: a scoping review and exploratory meta-analysis. *Sports Med.* 2022;52(2):377-390.
17. Helms ER, Cronin J, Storey A, Zourdos MC. Application of the repetitions in reserve-based rating of perceived exertion scale for resistance training. *Strength Cond J.* 2016;38(4):42-49.
18. Kassiano W, Nunes JP, Costa B, Ribeiro AS, Schoenfeld BJ, Cyrino ES. Does varying resistance exercises promote superior muscle hypertrophy and strength gains? A systematic review. *J Strength Cond Res.* 2022;36(6):1753-1762.
19. Kirkpatrick S, Gelatt CD, Vecchi MP. Optimization by simulated annealing. *Science.* 1983;220(4598):671-680.
20. Kolber MJ, Beekhuizen KS, Cheng MS, Hellman MA. Shoulder joint and muscle characteristics in the recreational weight training population. *J Strength Cond Res.* 2009;23(1):148-157.
21. Lum D, Barbosa TM. Brief review: effects of isometric strength training on strength and dynamic performance. *Int J Sports Med.* 2019;40(6):363-375.
22. Marsaglia G. Xorshift RNGs. *J Stat Softw.* 2003;8(14):1-6.
23. Milanović Z, Sporiš G, Weston M. Effectiveness of high-intensity interval training (HIT) and continuous endurance training for VO2max improvements: a systematic review and meta-analysis of controlled trials. *Sports Med.* 2015;45(10):1469-1481.
24. Morán-Navarro R, Pérez CE, Mora-Rodríguez R, et al. Time course of recovery following resistance training leading or not to failure. *Eur J Appl Physiol.* 2017;117(12):2387-2399.
25. Nunes JP, Grgic J, Cunha PM, et al. What influence does resistance exercise order have on muscular strength gains and muscle hypertrophy? A systematic review and meta-analysis. *Eur J Sport Sci.* 2021;21(2):149-157.
26. Oranchuk DJ, Storey AG, Nelson AR, Cronin JB. Isometric training and long-term adaptations: effects of muscle length, intensity, and intent: a systematic review. *Scand J Med Sci Sports.* 2019;29(4):484-503.
27. Pelland JC, Remmert JF, Robinson ZP, Hinson SR, Zourdos MC. The resistance training dose response: meta-regressions exploring the effects of weekly volume and frequency on muscle hypertrophy and strength gains. *Sports Med.* 2026;56(2):481-505.
28. Ralston GW, Kilgore L, Wyatt FB, Baker JS. The effect of weekly set volume on strength gain: a meta-analysis. *Sports Med.* 2017;47(12):2585-2601.
29. Refalo MC, Helms ER, Trexler ET, Hamilton DL, Fyfe JJ. Influence of resistance training proximity-to-failure on skeletal muscle hypertrophy: a systematic review with meta-analysis. *Sports Med.* 2023;53(3):649-665.
30. Reynolds JM, Gordon TJ, Robergs RA. Prediction of one repetition maximum strength from multiple repetition maximum testing and anthropometry. *J Strength Cond Res.* 2006;20(3):584-592.
31. Rhea MR, Alvar BA, Burkett LN, Ball SD. A meta-analysis to determine the dose response for strength development. *Med Sci Sports Exerc.* 2003;35(3):456-464.
32. Robinson ZP, Pelland JC, Remmert JF, et al. Exploring the dose-response relationship between estimated resistance training proximity to failure, strength gain, and muscle hypertrophy: a series of meta-regressions. *Sports Med.* 2024;54(9):2209-2231.
33. Rogerson D, Nolan D, Androulakis-Korakakis P, et al. Deloading practices in strength and physique sports: a cross-sectional survey. *Sports Med Open.* 2024;10:26.
34. Schoenfeld BJ, Grgic J, Ogborn D, Krieger JW. Strength and hypertrophy adaptations between low- vs. high-load resistance training: a systematic review and meta-analysis. *J Strength Cond Res.* 2017;31(12):3508-3523.
35. Schoenfeld BJ, Grgic J, Van Every DW, Plotkin DL. Loading recommendations for muscle strength, hypertrophy, and local endurance: a re-examination of the repetition continuum. *Sports.* 2021;9(2):32.
36. Schoenfeld BJ, Ogborn D, Krieger JW. Dose-response relationship between weekly resistance training volume and increases in muscle mass: a systematic review and meta-analysis. *J Sports Sci.* 2017;35(11):1073-1082.
37. Schoenfeld BJ, Ogborn D, Krieger JW. Effects of resistance training frequency on measures of muscle hypertrophy: a systematic review and meta-analysis. *Sports Med.* 2016;46(11):1689-1697.
38. Schoenfeld BJ, Pope ZK, Benik FM, et al. Longer interset rest periods enhance muscle strength and hypertrophy in resistance-trained men. *J Strength Cond Res.* 2016;30(7):1805-1812.
39. Schumann M, Feuerbacher JF, Sünkeler M, et al. Compatibility of concurrent aerobic and strength training for skeletal muscle size and function: an updated systematic review and meta-analysis. *Sports Med.* 2022;52(3):601-612.
40. Seiler S. What is best practice for training intensity and duration distribution in endurance athletes? *Int J Sports Physiol Perform.* 2010;5(3):276-291.
41. Simão R, de Salles BF, Figueiredo T, Dias I, Willardson JM. Exercise order in resistance training. *Sports Med.* 2012;42(3):251-265.
42. Singer A, Wolf M, Generoso L, et al. Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy. *Front Sports Act Living.* 2024;6:1429789.
43. Thomas E, Bianco A, Paoli A, Palma A. The relation between stretching typology and stretching duration: the effects on range of motion. *Int J Sports Med.* 2018;39(4):243-254.
44. Wilk M, Zajac A, Tufano JJ. The influence of movement tempo during resistance training on muscular strength and hypertrophy responses: a review. *Sports Med.* 2021;51(8):1629-1650.
45. Wilson JM, Marin PJ, Rhea MR, et al. Concurrent training: a meta-analysis examining interference of aerobic and resistance exercises. *J Strength Cond Res.* 2012;26(8):2293-2307.
46. Zourdos MC, Klemp A, Dolan C, et al. Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve. *J Strength Cond Res.* 2016;30(1):267-275.

## 12. Chemin street (0.2.0)

Le lot CP1 ajoute un second chemin de création, réservé au street workout (dossier `lib/src/coach/`). Il
ne cherche pas le programme par optimisation comme le chemin 0.1 (§ 3) : il le **construit** par des
règles fixes, à la manière d'un entraîneur — une saison calée sur l'échéance, un squelette de séances par
style, puis un dosage semaine par semaine selon la méthode de chaque emplacement, contrôlé par des
garde-fous. Les commentaires du code citent, pour chaque règle, le principe du référentiel de
`kalis_bench` (`packages/kalis_bench/docs/REFERENTIEL.md`, identifiants R1-P1 à R6-P30, R4-F*, R4-G*,
R4-H*) ou disent « choix raisonné » ; quelques valeurs renvoient au journal de calibrage
(`docs/CALIBRAGE_CP1.md`). Le tableau du § 12.10 reprend ces sources telles que le code les donne. Les
textes français des notes de coach sont dans `docs/NOTES_COACH.md`.

Ce paragraphe décrit ce que fait le code ; ce qu'il ne fait pas est au § 9 (« Chemin street »).

### 12.1 Quand le chemin street s'applique

`coachEligible(profile)` est vrai si, et seulement si :

- le profil est au schéma 3 (`isSchema3`) et porte l'expérience **et** l'ancienneté d'entraînement
  (questionnaire 0.4) ;
- la discipline principale est le street workout (sets & reps), le streetlifting ou la calisthénie ;
- chaque discipline secondaire est l'une de ces trois, le cardio ou la mobilité ;
- au moins un jour de disponibilité est donné.

Un programme du chemin street se reconnaît à son intention de bloc (`Pass1Plan.intent` non nulle :
`isCoachPlan`). Aiguillage dans `KalisPlan` :

| Méthode | Chemin street si |
| --- | --- |
| `createPass1`, `nextBlock`, `planSeason` | le profil est éligible |
| `review`, `reviewTraced`, `createPass2`, `restructure`, `PlanInspector.hardViolations` | le profil est éligible **et** le programme porte une intention |
| `variants` | jamais : toujours le chemin 0.1 |

Sinon, le chemin 0.1 s'applique, inchangé. `planSeason` d'un profil non éligible rend un plan sans
phase.

La passe 1 du chemin street porte une note `PlanScore` : c'est la note du chemin 0.1
(`PlanInspector.scoreOf`), calculée après coup, à titre d'information. La graine n'est lue que modulo
16, comme décalage des listes d'assistance marquées « en rotation » (tronc, tirage horizontal des
séances courtes, mobilité) : « Autre proposition » change ces choix, pas la structure.

### 12.2 Lecture du profil (`Athlete.read`)

**Jours.** Les disponibilités sont triées par jour de la semaine ; chaque jour garde ses minutes
(remplacées par celles d'une restructuration), son lieu et son matériel (matériel du lieu s'il est
donné, sinon tout le matériel du profil). La passe 1 plafonne le temps d'un jour à 300 minutes.

**Âge et poids.** Âge = année du début du bloc − année de naissance. Poids de corps : celui du profil,
sinon 75 kg.

**Records.** Dans cet ordre, le meilleur l'emporte :

1. niveaux déclarés (`movementLevels`, borne basse) : 1RM, maximum de répétitions, maintien maximal ;
   un maximum de répétitions déclaré à 0 (bornes basse et haute nulles) marque l'exercice comme **non
   acquis** ;
2. tests datés (`benchmarks`) : charge et répétitions → 1RM estimé par `estimateOneRm` (kalis_core) sur
   la charge totale (lest + part du poids de corps), ramené à la charge externe ; répétitions
   maximales et maintien maximal sans lest (la date du test devient la date du record) ; chrono sur
   1 000 m ou plus → temps sur 10 km par la formule de Riegel (exposant 1,06) ;
3. figures (`skills`) : meilleur maintien et meilleures répétitions de l'étape actuelle.

Un record sans date est daté de la dernière mise à jour du profil. Sont **sus** : les exercices
déclarés sus et tous ceux qui ont un record. Sont **écartés** : les exercices non aimés, ceux déclarés
« je ne sais pas faire », ceux exclus par un verrou, ceux évités par le résumé d'adaptation, et (en
restructuration) ceux qu'un motif écarte.

**Niveau.** L'expérience déclarée : 0 débutant, 1 intermédiaire, 2 avancé, 3 élite. (Le code prévoit
de lire l'ancienneté à défaut d'expérience, mais un profil sans expérience n'est pas éligible.)

**Zones à ménager.** Chaque limitation donne une gêne (la plus forte de la gêne du moment et de la
gêne à l'effort) et est **récente** si son ancienneté est inconnue ou de moins de douze mois (ni « plus
de 12 mois », ni « ancien, sans gêne »). Une douleur signalée en restructuration s'ajoute comme zone
récente.

**Mode prudent.** Questionnaire santé absent ou non « standard », 65 ans et plus, ou moins de 18 ans.
Effets : impact écarté (ci-dessous), plancher de réserve de 2 (§ 12.5), charges calculées par `_loadAt`
plafonnées à 85 % du 1RM (§ 12.5), pas de test de 1RM en trois tentatives (§ 12.7).

**Tolérance.** Facteurs de volume (au plus 1) et réserve ajoutée :

| Situation | Effet |
| --- | --- |
| 60 ans et plus | volume × 0,8 |
| 40 ans et plus | montée du volume deux fois plus lente (§ 12.6) |
| Sommeil de moins de 6 h | volume × 0,85 ; +1 répétition en réserve ; volume gelé |
| Stress élevé | volume × 0,9 ; +1 répétition en réserve ; volume gelé |
| Travail physique lourd | tirage × 0,85 ; jambes × 0,85 |
| Objectif de perte de poids | volume gelé |
| 3 séances d'endurance ou plus par semaine (course, vélo, autre endurance, sport collectif ; un cardio secondaire à 30 % ou plus compte pour 3) | jambes × 0,7 |
| Gêne récente d'au moins 2/10 au coude, à l'épaule ou au poignet | tirage × 0,6 (par zone) |
| Gêne récente d'au moins 2/10 au genou, à la hanche, à la cheville ou au bas du dos | jambes × 0,7 (par zone) |
| Cumul | jamais sous 0,6 : volume ≥ 0,6, volume × tirage ≥ 0,6, volume × jambes ≥ 0,6 |

« Volume gelé » ne bloque que la hausse du nombre de départs au chrono (§ 12.5, `reps.density`).

**Coupure.** Semaines d'arrêt lues de `trainingGap` : allégé 1, moins de 3 semaines 2, 3 à 10 semaines
6, 10 à 26 semaines 16, 6 mois à 2 ans 36, plus de 2 ans 104.

**Impact.** Débutant dont l'indice de masse corporelle atteint 30 : sauts, corde, balistique et
haltérophilie écartés. Mode prudent : tout exercice à impact écarté.

**Admission (`Athlete.rejection`).** Un exercice est admis un jour donné s'il passe ces règles, dans
l'ordre (le code rendu est celui de la première qui l'écarte) :

| Code | Règle |
| --- | --- |
| `unknown` | absent du catalogue |
| `excluded` | écarté (voir plus haut) |
| `equipment` | lieu du jour (ou un lieu du profil si le jour n'en impose pas) et matériel du jour |
| `joint` | contrainte forte sur une zone à ménager de gêne ≥ 4, ou contrainte moyenne ou forte avec une gêne ≥ 6 |
| `level` | niveau de la base au-delà du niveau de l'athlète + 1, sauf exercice su |
| `prerequisite` | l'exercice est non acquis, en est une variante non assistée de difficulté au moins égale (même racine), ou l'a pour prérequis |
| `technique` | sous le niveau avancé : identifiants « supramaximal », « partielle-haute », « partiel-haut », « partiel-surcharge », « isometrie-lestee » ; chez le débutant : « chaines » |
| `impact` | règles d'impact ci-dessus |

**Progrès planifié (`plannedGain`).** Gain supposé d'un record de répétitions ou de maintien à une
date : le rythme le plus rapide permis par niveau (répétitions 8 %, 3 %, 2 %, 1,2 % du record par
semaine ; maintien 5 %, 4 %, 3 %, 2 %), au moins une unité toutes les trois semaines ; la moitié de ce
rythme sans objectif chiffré (et 20 % au plus au total) ; avec un objectif, le rythme qui y mène à la
date visée, borné par le rythme permis et par l'objectif lui-même. Le gain part de la date du record ;
il ne sert qu'aux semaines qui suivent un test (§ 12.7).

### 12.3 Plan de saison (`season.dart`)

**Échéance visée.** La première échéance principale à venir, sinon la première échéance à venir, sinon
la date du premier objectif de performance daté (avec tous les objectifs de ce jour-là). Seule une
échéance principale appelle un pic de forme.

**Modèle.**

| Modèle | Quand |
| --- | --- |
| Linéaire | débutant |
| Général | sans échéance, ou échéance qui ne relève pas des deux suivants |
| Pic de force | épreuve de force (compétition de force, ou épreuve avec mouvements, ou objectifs datés tous en 1RM), avec pic de forme ou à partir du niveau avancé |
| Pic d'endurance de force | épreuve de répétitions avec pic de forme |

**Durée du bloc.** `blockWeeks` de la requête s'il est donné. Sinon, sans échéance : 6 semaines pour
le débutant, 6 pour l'intermédiaire, 4 au-delà. Avec échéance à `w` semaines (semaine de l'échéance
comprise) : `w` si `w` vaut de 4 à 6, 4 si `w < 4` ; au-delà, la première durée préférée du niveau
(débutant 6, 5, 4 ; intermédiaire 5, 6, 4 ; avancé et élite 4, 5, 6) qui laisse un reste nul ou d'au
moins 4 semaines différent de 7. Le bloc qui contient la semaine de l'échéance est le **bloc final**.
Le premier bloc d'un athlète qui sort d'une coupure de 3 semaines ou plus est en **reprise**.

**Semaines.** Chaque semaine a une nature (intro, montée `build`, allègement `deload`, test), une
intention, une phase et un **facteur de volume** (1 = semaine la plus chargée). Les séries d'un
emplacement sont `arrondi(séries × facteur × facteur d'adaptation)`, et deux au plus par exercice la
semaine de l'échéance (§ 12.5).

| Modèle | Semaines (facteur de volume) |
| --- | --- |
| Linéaire | 1re semaine du premier bloc : intro (0,9). Montée : 0,9, 0,95 puis 1,0 au premier bloc, 1,0 ensuite. Avant un test daté à 5 semaines ou plus et dans le bloc, la semaine qui précède l'échéance : affûtage (0,75 chez le débutant, 0,6 sinon). Dernière semaine : test (0,7 ; 0,6 si c'est l'échéance). |
| Général | 1re semaine du premier bloc : intro (0,9 ; 0,5 en reprise). Montée : de 0,9 à 1,0 ; en reprise, 0,5 × 1,15 par semaine de montée (0,575, 0,66, 0,76, 0,87), au plus 0,95. Avant un test daté à 5 semaines ou plus et dans le bloc, la semaine qui précède l'échéance : affûtage (0,55). Semaine de l'échéance : test (0,6). Sinon dernière semaine : allègement avec tests (0,55). Phase : réalisation au bloc final, intensification si 6 semaines au plus restent après le bloc (jamais au premier bloc), accumulation sinon. |
| Pic de force, bloc final | Affûtage de 2 semaines (compétition et niveau avancé ou élite), sinon 1. Avant l'affûtage : intensification (0,9 la première au premier bloc, 1,0), puis allègement (0,55) et réalisation, selon le nombre de semaines (≥ 5 : intensification, …, allègement, réalisation ; 4 : 2 intensifications, 2 réalisations ; 3 : 1 et 2 ; moins : réalisation). Réalisation 0,85 puis 0,8. Affûtage 0,6. Semaine de l'échéance : compétition ou test (0,42). Semaines au-delà de l'échéance : transition (0,5). |
| Pic de force, autres blocs | Accumulation si 5 semaines ou plus restent après le bloc, intensification sinon. Intro (0,9) au premier bloc ; montée de 0,92 à 1,0 (accumulation) ou 1,0 (intensification) ; dernière semaine : allègement (0,55), sans test. |
| Pic d'endurance, bloc final | Affûtage de 2 semaines à partir du niveau avancé, sinon 1. Réalisation (1,0), affûtage (0,62), compétition (0,45), transition (0,5) au-delà. |
| Pic d'endurance, autres blocs | Accumulation si 8 semaines ou plus restent après le bloc, intensification sinon. Intro (0,9) au premier bloc ; montée de 0,92 à 1,0 ; dernière semaine : allègement avec tests (0,6). |

Le **rang** d'une semaine (`stage`) compte ses semaines de charge dans sa phase ; il règle la montée des
charges et des plages. Pour les modèles général et linéaire, chaque bloc déjà fait ajoute un cran (trois
au plus).

**Plan de saison (`seasonPlanOf`).** Les blocs sont enchaînés à partir de la date de début jusqu'au bloc
final (deux blocs sans échéance, trente au plus) ; les semaines consécutives de même phase forment une
phase de saison, avec la moyenne de leurs facteurs de volume (arrondie au centième). La phase
d'affûtage et le plan portent `plan.peak_event` quand une échéance est inscrite. Le premier bloc seul
tient compte de la coupure (reprise).

### 12.4 Squelettes (`skeleton.dart`)

**Style.** Débutant (niveau 0) ; figures (calisthénie principale avec au moins une figure visée) ;
streetlifting (streetlifting principal et traction ou dips lesté admissible un jour au moins) ; sets &
reps sinon.

Le squelette donne, pour chaque séance, des emplacements : exercice (le premier admissible d'une liste
de candidats, `tables.dart`), rôle, **méthode** de dosage, séries de la semaine de pointe, jour lourd,
moyen ou léger, exercice de référence, figure visée, groupe enchaîné, point faible, semaines où
l'emplacement est prescrit, et deux marques : `support` (travail d'appoint, il cède ses séries d'abord)
et `keep` (assistance gardée : le tirage horizontal d'équilibre).

**Hybride course** (styles autres que débutant). Avec un cardio secondaire d'au moins 20 % et 3 jours ou
plus : `arrondi(jours × part)` jours de course, entre 2 et jours − 2, sur des jours où le footing est
admis. Sortie longue le jour le plus long ; puis les jours les plus éloignés. À partir de
l'intermédiaire, une séance de qualité au plus (la plus éloignée de la sortie longue), précédée d'un
footing d'échauffement ; avec un objectif chronométré, elle porte aussi des fractions de 1 000 m à
l'allure de l'objectif. Objectif chronométré et moins de trois courses : un footing court de plus en fin
d'une séance de renforcement d'au moins 55 minutes, loin des courses.

**Débutant.** Corps entier à chaque séance : préparation de la suspension ; tirage vertical (traction
dès 5 répétitions ; sinon traction assistée, et descentes freinées deux jours par semaine sauf en
surpoids ; tenue menton au-dessus de la barre les autres jours si la traction est un objectif) ;
poussée (pompe dès 6 répétitions ; pompe complète puis variante facile dès 4 répétitions prévues ;
sinon variante facile et, si la pompe est un objectif, pompe en descente freinée) ; tirage horizontal
(2 ou 3 jours, ou chaque jour dès 5 tractions) ; squat et fente en alternance, hanche dès 40 min ;
appui aux barres parallèles deux jours, les plus espacés, sauf en surpoids (dips assistés à partir du
deuxième bloc dès 6 pompes ; dips chaque jour dès 5 répétitions) ; tronc ; marche en fin de séance pour la perte de poids (35 min et plus) ;
gainage latéral dès 55 min. Deux séries par exercice si 3 jours ou plus et une séance de moins de
55 min, trois sinon ; les deux mouvements principaux prennent une série de plus à partir du deuxième
bloc quand ils n'en ont que deux.

**Sets & reps.** Piliers traction, dips, pompe, muscle-up. Fréquence du tirage : 3 (intermédiaire), 4
(avancé, ou intermédiaire sur 4 jours ou plus), 5 (élite), une de moins pour un profil ménagé (tirage
ou volume réduits, reprise de 10 semaines ou plus sur les trois premiers blocs), bornée par les jours ;
jusqu'à l'intermédiaire, jamais deux jours de tirage consécutifs. Méthode de chaque jour : sous
8 tractions, le cycle force, densité, volume, densité, volume ; sinon jours lourds (série longue, force)
écartés d'au moins 48 h, lendemain d'un jour lourd en densité, les autres jours en alternance densité et
volume. Dips sur les mêmes jours, méthodes décalées ; poussée en entretien (volume) quand l'objectif ne
porte que sur le tirage. La force passe par le lest (8 répétitions et plus, coude non ménagé) ou une
variante dure (10 et plus). Muscle-up : simples propres dès 3 répétitions ; en dessous, muscle-up
assisté ou descente freinée et tirage explosif ; densité dès 6. Quand toutes les séances durent 50 min
ou moins (à partir de l'intermédiaire) : exercices enchaînés. Tirage horizontal deux jours par semaine
(gardé), et les jours sans traction de 60 min et plus ; jambes un ou deux jours (un seul si le facteur
jambes est réduit), de préférence ni un jour de traction ni la veille d'une course ; tronc ; prévention
dès 60 min avec un élastique ; pratique des figures (équilibre) deux jours si la calisthénie compte pour
25 % ou plus. En préparation d'une épreuve de répétitions : une séance lestée par semaine ; si les
pompes ne sont pas à l'épreuve, une seule séance de pompes, en entretien.

**Streetlifting.** Jour léger : le plus court des jours sans course (le plus tard à égalité), dès 4 jours
sans course. Traction lestée lourde et dips de volume le
premier jour lourd ; squat lourd le deuxième ; dips lourd et traction de volume le troisième ; squat de
volume le quatrième (ou le premier avec trois jours lourds) ; muscle-up lesté (niveau avancé, avec un
1RM ou 5 muscle-up) le quatrième ou le deuxième, avec une seconde exposition légère à 48 h ; avec moins
de jours, plusieurs rôles partagent un jour. Variantes de point faible ; au jour léger, traction et dips
légers à partir de l'avancé, dips ou pompes en volume, tirage horizontal et tronc à l'intermédiaire. Spécialisation sur un exercice : la cible gagne une séance de volume, le reste passe
en entretien (`lift.maintain`). Squat en entretien quand un objectif porte ailleurs sans épreuve. Coude
ménagé (gêne récente ≥ 2) : pas de traction lestée ni de muscle-up lesté ; traction au poids du corps
en prise neutre (`pull_return`) et fléchisseurs du poignet légers. Assistance : charnière de hanche et
tronc les jours de squat, tirage horizontal, fléchisseurs du coude (avancé), prévention.

**Figures.** Deux figures statiques au plus (hors équilibre et L-sit), par ordre de priorité : les
figures du profil, puis les objectifs. Étape de travail : celle du profil, sinon la plus haute étape
sue (maintien de 3 s, une répétition, ou déclarée sue). Jours de la première figure : 2 (intermédiaire),
3 (intermédiaire sur 4 jours, avancé et élite), les plus espacés ; sur trois jours, celui du milieu est
léger. La seconde figure prend 2 jours lourds (le premier et le dernier de la première figure à partir
de 5 jours, sinon les autres jours) et, dès 4 jours, une séance légère à 48 h de ses séances lourdes.
Chaque séance de figure : maintiens sur l'étape (`skill.hold`), avec l'étape plus facile en complément
si le maintien est sous 8 s (à partir de l'intermédiaire) ; en séance légère, à partir de l'avancé et
avec un maintien connu, maintiens longs sur l'étape plus facile (`skill.easy_hold`) ; travail dynamique
du même schéma ;
essais de l'étape suivante sous condition (deuxième bloc ou plus, délai de l'étape écoulé, maintien aux
trois quarts du critère), deux séances par semaine au plus. Équilibre dès 20 s de maintien sur les mains.
Force de base deux jours par semaine (traction, dips, lestés à partir de l'avancé), tirage horizontal
gardé, jambes, tronc spécifique, mobilité dès 60 min. Chaque figure reçoit son échelle (`SkillLadder` :
critère de passage de 12, 10 ou 8 s ou 3 répétitions, 3 séries, qualité 4, 3 séances, délai minimal de
12, 8 ou 6 semaines). Une figure complète hors de portée du bloc est annoncée (`skill_horizon`).

**Après la construction, pour tous les styles** : footing de fin de séance éventuel ; nombre de jours
bras tendus par famille (appui, suspension, mixte) ramené à 2, 3, 3 ou 4 selon le niveau (les jours en
trop perdent leur travail bras tendus ; un gainage en appui est remplacé par un gainage sans appui) ;
plafond hebdomadaire de séries dures par groupe (§ 12.6) ; compléments de fin de séance quand plus d'un
cinquième du temps reste libre (gainage latéral, bas du dos, chaîne postérieure, prévention, tronc,
mobilité ; 1, 2 ou 3 au plus selon la durée ; jamais au-delà d'un plafond de groupe) ; de nouveau le
plafond ; mobilité en fin de séance si le profil demande 10 % de mobilité ou plus ; séance de repli
(pompes, squat, tronc, marche) si une séance n'a que de la préparation. Identifiants `d<jour>.<rang>`.
L'intention du bloc porte la phase, l'échéance, les semaines restantes (0 à 104), l'ondulation
(quotidienne, aucune chez le débutant) et la spécialisation.

### 12.5 Méthodes de dosage (`prescribe.dart`)

Règles communes :

- **Séries** (méthodes qui les mettent à l'échelle, `_scaled`) : `arrondi(séries × facteur de la
  semaine × facteur d'adaptation)`, au moins le minimum de la méthode ; deux au plus par exercice la
  semaine de l'échéance. Le facteur d'adaptation vaut 0,85, 1 ou 1,1 (§ 6, `adaptationVolumeScale`).
  Les autres méthodes donnent leurs séries elles-mêmes (ci-dessous).
- **Réserve** (`_rirOf`) : réserve de la méthode + réserve ajoutée du profil ; +1 la semaine d'intro ;
  au moins 3 en allègement, affûtage ou transition ; jamais sous le plancher ; jamais au-dessus de 4.
  Certaines méthodes écrivent directement 5 (travail loin de l'échec, qui ne compte pas comme série
  dure).
- **Plancher de réserve** (`_floorRir`) : 2 sur un mouvement à risque de chute ou de fin d'amplitude
  (figures, équilibre, muscle-up, freestyle, haltérophilie, poussée aux anneaux, squat et développés à
  la barre), chez le débutant, en mode prudent, et sur un exercice qui charge une zone à ménager récente ou gênée à 2/10
  ou plus ; en reprise (premier bloc, 2 semaines d'arrêt ou plus) : 3 la première semaine, les deux
  premières après 4 semaines, tout le bloc après 10, 4 la première semaine après 16 ; après 10 semaines
  d'arrêt, 2 sur les trois premiers blocs.
- **Repères de reprise** : charges et maximums visés × 0,90 (coupure de moins de 4 semaines), 0,82
  (moins de 8), 0,75 (au-delà) ; après un test, à mi-chemin des anciens records (0,92 au plus), puis
  0,95, puis 1.
- **Série d'entrée de reprise** (note `entry_set`) : premier bloc, première semaine, 2 semaines d'arrêt
  ou plus ; écrite sur la ligne de travail (`reps.top`, `reps.strength`, `reps.volume`, `reps.density`)
  d'un mouvement qui a un record de répétitions, à la première séance de la semaine qui le porte :
  première série jusqu'à 3 répétitions de l'échec (4 après 16 semaines d'arrêt ou plus).
- **Décalage de plage** (`_shift`) : +1 répétition toutes les deux semaines de montée (chaque semaine à
  partir de l'avancé), +2 au plus.
- **Part du 1RM et répétitions** (tableau R2-P2) : 1 répétition à 100 %, 2 à 94 %, 3 à 91 %, 5 à 86 %,
  8 à 79 %, 10 à 75 %, 12 à 71 %, par interpolation. `_honest` (séries de travail à moins de 5 en
  réserve, au pourcentage du 1RM) retire des répétitions tant que la série laisserait moins que la plus
  grande de « réserve voulue − 1 » et du plancher, et écrit la réserve que le tableau donne, entre le
  plancher et la réserve voulue. Si même une seule répétition ne laisse pas la réserve plancher, la
  charge descend à la part que le tableau donne pour « 1 + plancher » répétitions (`_pctAt`).
- **Charge** (`_loadAt`) : `charge externe = arrondi inférieur au pas (part × 1RM total − part du poids
  de corps)`, au moins le minimum du type de charge ; pas et minimum du profil, sinon ceux du chemin
  0.1 (§ 5.3, lest : 1,25 kg). Le 1RM est celui de l'exercice, sinon celui de son mouvement de
  référence lesté. Sans 1RM : charge « à calibrer » (`plan.to_calibrate`, note `calibrate`). Mode
  prudent : part plafonnée à 85 %. Série de travail hors pic de force (amplitude partielle mise à part),
  quand le poids de corps fait 78 % ou plus du 1RM total, ou que la part visée tombe sous lui : le lest
  de départ est celui que le tableau R2-P2 (`_pctAt`) donne pour « répétitions + réserve » (haut de la
  plage, 5 par défaut ; réserve arrondie au-dessus, 3 par défaut), soit `arrondi inférieur au pas
  (part × 1RM total − part du poids de corps)` avec cette part, note `small_load` ; s'il est nul ou
  négatif, la charge est « à calibrer » (`plan.to_calibrate`, note `calibrate`). Dans les autres cas où
  la part tombe sous le poids de corps (pic de force, série qui n'est pas de travail) : série au poids
  du corps, répétitions possibles par la formule d'Epley moins la réserve, note `bodyweight_floor`.

Chaque méthode, ci-dessous, donne : répétitions (ou secondes), part du 1RM ou du maximum, réserve
(avant les règles communes), repos.

#### `lift.heavy` — force lestée, séance lourde

Série de tête puis séries allégées (`top_set_backoff`, technique `top_set_backoff`) ; montée en charge
de 3 séries (`ramp_warmup`) ; muscle-up lesté : 3 répétitions au plus. Repos 240 s (avancé, élite) ou
180 s. Séries : `séries × facteur`, au moins 2. Les séries allégées ne descendent pas sous le poids de
corps.

| Semaine | Répétitions | Part du 1RM | Réserve | Baisse des séries allégées |
| --- | --- | --- | --- | --- |
| Intro | 5 | 76 % | 3 | 10 % |
| Accumulation | 5 | 80 % + 1,5 % par rang, 84,5 % au plus | 2 | 10 % |
| Intensification | 3 | 86 % + 1,5 % par rang, 90 % au plus | 2 (3 pendant l'entrée d'une zone ménagée) | 5 % |
| Réalisation (rang dans la phase, sans le cran des blocs) | 2 (intermédiaire : 87 % + 1 % par rang ; avancé, élite, rang 0 : 91 %) ; 1 à partir du rang 1 chez l'avancé et l'élite (93 % à 95 %) | | 2 ; 1 pour les simples | 15 %, séries allégées de 2 |
| Affûtage | mouvement de l'échéance, séance la plus proche de J−8 parmi celles à J−5 et plus : 1 à 90 %, séries allégées de 2 (1 au muscle-up), note `dress_rehearsal` ; autres séances : 2 × 3 à 80 % | | 2 / 3 | 10 % |
| Allègement, test, compétition, transition | 3 (phase d'intensification ou de réalisation) ou 5 | 80 % ou 75 % (transition 65 %) ; 3 séries si la pointe en a 4, sinon 2 | 4 | — |

Zone ménagée au premier bloc : −6 % les deux premières semaines, −3 % la troisième. Dernière semaine de
montée avant un allègement : note `recalibrate` (2,5 %). Semaine d'un test daté sans pic, mouvement visé : rappel
dans une séance ordinaire à J−4 ou plus tôt (simple à 88 %, deux doubles, réserve 3, `opener`) ; séance
facile à J−2 et la veille (2 × 2 à 70 %, réserve 5, `speed_work`). Semaine d'une épreuve avec pic : à J−3 et plus, rappel (simple à 85 %, deux doubles,
réserve 4, `opener`) ; à J−2 et J−1, 2 × 2 à 70 %, réserve 5.

#### `lift.maintain` — force lestée en entretien

Séries de la pointe (2 en semaine allégée), 3 répétitions à 83 % (jour lourd) ou 5 à 76 %, réserve 3,
repos 180 s, note `maintenance`. Semaine de l'échéance ou séance hors ordinaire : 2 × 3 à 75 %,
réserve 4, repos 150 s.

#### `lift.volume` — force lestée, séance de volume

6 répétitions à 72 % + 1,5 % par rang (78 % au plus en accumulation ; intro 70 %) ; intensification 4 à
78 % + 1,5 % par rang (84 % au plus) ; réalisation 3 à 82 % ; affûtage 2 × 3 à 80 % (ou le dernier
lourd) ; allègement et suivantes 2 × 4 à 72 % ou 2 × 6 à 67 % (transition 60 %). Réserve 3 (4 en
allègement), repos 180 s, au moins 2 séries, montée en charge. Règle `load_step` (1,5 %) en semaine de
montée. Rappel à J−3 et plus avant une épreuve avec pic : 2 × 3 à 78 %, réserve 4. Rien à J−2 et J−1
(ni à J−2 d'un test sans pic). Semaine d'un test daté sans pic, mouvement visé, séance à J−4 ou plus
tôt : dosé comme le rappel de `lift.heavy`.

#### `lift.light` — force lestée, séance légère

Seulement les séances ordinaires, hors affûtage et transition. 3 répétitions (2 au muscle-up lesté) à
70 % (65 % en semaine allégée), séries de la pointe (2 en semaine allégée), réserve 5, repos 120 s,
note `speed_work` (part réelle).

#### `lift.variant` — variante de point faible

Seulement les séances ordinaires, hors affûtage, compétition et transition ; raison `plan.weak_point`.
Variante tenue : 15 à 25 s, réserve 3, repos 120 s. Amplitude partielle (identifiant « partiel ») :
95 % + 5 % par bloc fait (deux au plus) + 2,5 % par rang (deux au plus), 110 % au plus (105 % avec un
coude à ménager), aucune en semaine allégée, note `overload`. Autres variantes : 70 % (74 % en
intensification et réalisation) + 1 % par rang, 80 % au plus. −5 % en semaine allégée ; 4 répétitions
(3 en intensification et réalisation) ; 2 séries en semaine allégée ou en réalisation ; réserve 3 ;
repos 150 s. Éducatif du muscle-up sans 1RM propre : 4 à 6 répétitions, charge à calibrer.

#### `reps.top` (et `reps.event`) — série longue au poids du corps

Sous 4 répétitions de maximum : dosé comme `reps.strength`. Semaine allégée (hors intro et affûtage) :
2 séries à 60 % du maximum, réserve 4, repos 150 s. Sinon : une série de tête à `maximum − marge −
réserve ajoutée`, puis des séries à 65 % du maximum. Marge : 4 en intro ; 3 puis 2 (à partir du rang 1)
en montée ; en réalisation 2, ou 1 une semaine sur deux à partir de l'avancé ; au moins 8 % du maximum ;
à l'affûtage, 15 % du maximum et au moins 3 ; au moins 2 sur un mouvement à risque ou chez le débutant,
1 sinon, et au moins le plancher. Réserve écrite = maximum − répétitions, entre ce plancher et 4. Séries
`séries × facteur` (2 à l'affûtage), repos 180 s ; montée de 2 séries (`ramp_bodyweight`) ; règle
`rep_step`. Repos-pause (note `rest_pause`, 3 relances) sur la séance lourde d'un objectif de 15
répétitions ou plus au-dessus du maximum, à partir de l'intermédiaire, au deuxième bloc (ou en
réalisation), rang 1 et plus, hors épreuve de répétitions, hors mouvement à risque et zone ménagée ;
avec deux objectifs de série longue, le tirage les rangs impairs, la poussée les rangs pairs. (`reps.event`
n'est attribué par aucun squelette.)

#### `reps.volume` — volume sous-maximal

Sans maximum connu : 5 à 8 répétitions, réserve 3, règle `double_progression`. Sinon `arrondi(maximum ×
part)` répétitions, part 55 % (60 % dès 12 répétitions) + 3 % par rang, 70 % au plus, 50 % en semaine
allégée et en rappel d'épreuve. Réserve : dès 12 répétitions de maximum, 3 ; en dessous, maximum −
répétitions (au moins le plancher). Repos 120 s (débutant), 90 s (intermédiaire), 60 s (au-delà, et
enchaîné) ; 120 s pour des séries de 20 répétitions et plus et pour le tirage vertical non enchaîné. Au
moins 2 séries (2 en rappel), rien à J−2 et J−1. Règle `rep_step` en montée ; note `pull_return` (2,5 kg)
sur la traction de retour du coude.

#### `reps.density` — départs au chrono

Sous 5 répétitions de maximum, ou en rappel d'épreuve : dosé comme `reps.volume`. Rien en transition ni
à J−2 et J−1. Répétitions par départ : 40 % du maximum (45 % à partir de l'avancé, 30 % sur un mouvement
à risque). Départs : séries de la pointe − 1 + un par bloc fait (deux au plus) ; en montée et en intro,
+1 toutes les deux semaines de charge déjà faites dans le bloc (toutes les trois pour un profil lent,
aucun si le volume est gelé), deux au plus ; dans les autres semaines, × facteur ; entre 4 et 10.
Intervalle : le double de l'effort (3 s par répétition) arrondi aux 30 s supérieures, entre 60 et
180 s. Réserve 5, technique `emom`, note `every_minute`, règle `density_step`.

#### `reps.strength` — force au poids du corps

Repos 180 s (75 s enchaîné), au moins 2 séries (2 en rappel), rien à J−2 et J−1.

- Exercice lesté : 5 répétitions, réserve 3. Sans 1RM mais avec au moins 3 répétitions connues sur le
  geste de référence : charge estimée d'après ce maximum (tableau R2-P2 jusqu'à 12 répétitions, Epley
  borné à 20 au-delà), à 77 % + 1,5 % par rang (quatre au plus), sans dépasser la part que le tableau
  R2-P2 donne pour « 5 + réserve » répétitions, puis −3 % en semaine allégée, note
  `estimated_load` à la toute première semaine. Sinon 78 % du 1RM, ou charge à calibrer. Règle
  `load_step` (1,5 %).
- Poids du corps avec record : `maximum − marge`, marge 2 (+1 en semaine allégée et au rang 0 de
  montée) + réserve ajoutée, au moins le plancher ; plage ouverte d'une répétition à partir du rang 1 ;
  réserve écrite = maximum − répétitions, entre le plancher et 4. Règle `rep_step`.
- Variante dure sans record : haut de plage = 60 % du maximum du geste de base − 2, entre 4 et 12 (6
  sans repère), bas = haut − 2 (au moins 3), + décalage ; réserve 2 ; règle `double_progression`.

#### `reps.technique` — pratique technique

Rien à J−2, J−1 ni après l'échéance ; l'exposition légère de traction saute en semaine de test.
1 répétition (maximum ≤ 3), 2 (≤ 5), sinon la moitié du maximum ; si la réserve ainsi laissée est sous le
plancher, l'emplacement saute. Séries `(séries + 1 si maximum ≤ 3) × facteur`, au moins 2 ; réserve =
maximum − répétitions (4 au plus) ; repos 150 s ; technique `skill_practice` (qualité 4/5), note
`quality_first`.

#### `beginner.main` — double progression du débutant

Séries `séries × facteur` ; les deux premières semaines du premier bloc, 2 au plus. Repos 120 s.
Repli sur `sw-traction-negative` ou `sw-dips-negatifs` (ni élastique ni barre basse admis) : dosé comme
`beginner.negative` (séances ordinaires seulement), jamais en séries de travail ; rien en surpoids
(débutant dont l'indice de masse corporelle atteint 30).

- Exercice tenu : 60 % du maintien connu, entre 8 et 40 s (15 s sans repère), plage de +10 s ;
  réserve 3 ; règle `hold_step` (+5 s).
- Maximum de 1 à 5 : `maximum − 2` (ou le plancher s'il est plus haut), au moins 1 ; plage ouverte de
  +2 + décalage (fermée en semaine allégée) ; à partir du deuxième bloc, séries +1 (+1 au rang 2, +1 au
  rang 4), 4 au plus.
- Maximum de 6 et plus : de 50 % à 70 % du maximum + décalage, jamais au-dessus de maximum − 3 ;
  réserve 3 au premier bloc, 2 ensuite.
- Sans record : 6 à 8 répétitions (8 à 10 pour les jambes) + décalage, réserve 3 ; règle
  `assistance_step` sur un exercice assisté ; note `push_ladder` (6) sur une variante de pompe.

Règle `double_progression` dans les deux derniers cas.

#### `beginner.negative` — descentes freinées

Seulement les séances ordinaires. Descente de 4 s (5 à partir du rang 2) au premier bloc ; ensuite 6 s
(7 à partir du rang 2) après 2 s tenues en haut ; pompe en descente freinée : 3 s (4 à partir du rang
2). 3 descentes (4 à partir du rang 3, sauf pour la traction après le premier bloc), 2 en semaine
allégée. Séries de la pointe (2 en semaine allégée ; aux blocs suivants, 3 le premier jour de descentes
de traction de la semaine). Réserve 5 (pas une
série dure), repos 120 s (90 s pour la pompe). Note `slow_negative` ou `slow_negative_push`.

#### `beginner.hold`, `skill.hold`, `skill.easy_hold` — maintiens

Maintien = part × maintien connu (arrondi inférieur), sinon une valeur par défaut, borné :

| Méthode | Part | Bornes | Sans repère |
| --- | --- | --- | --- |
| `beginner.hold` | 60 % | 8 à 30 s (tenue menton au-dessus de la barre : 3 à 15 s) | 10 s (5 s) |
| `skill.hold` | 60 % ; +5 % la séance lourde d'une figure à partir de l'intermédiaire | 3 à 20 s | 5 s |
| `skill.easy_hold` (séances ordinaires seulement) | 60 % | 5 à 25 s | 10 s |

En montée, avec un repère : +3 % par rang, 70 % au plus (75 % la séance lourde) ; sans repère, +1 s à
partir du rang 2. Séries : 2 en rappel d'épreuve ; sinon, pour `skill.hold` et `skill.easy_hold`, des
secondes cumulées par séance de 30, 45, 50 ou 60 s selon le niveau (× 0,6 quand l'étape plus facile est
travaillée le même jour) × facteur de la semaine × facteur d'adaptation, divisées par le maintien, entre
2 (3 si deux étapes) et 6 ; l'étape plus facile travaillée le même jour : 2 ou 3 séries ; 3 au plus la
semaine de l'échéance et en séance légère. Réserve 5, repos 180 s (avancé, élite) ou 150 s, notes
`submaximal_hold` (0,7) et règle `hold_step` (+1 s). Sans repère, la première semaine du premier bloc
mesure le maintien (`hold_calibrate`). Élite, séance lourde, rangs impairs : premier maintien maximal
(`max_attempt`). Étape dynamique (unité en répétitions) : 2 à 4 répétitions, réserve 3, repos 120 s.

#### `skill.attempt` — étape suivante sous condition

Seulement les séances ordinaires hors semaines allégées. 2 à 3 s, séries de la pointe (+1 après deux
semaines de charge, 3 au plus), réserve 5, repos 180 s ou 150 s, note `step_gate` (critère : 12, 10 ou
8 s ; le texte donne le repère d'ouverture, un maintien maximal d'au moins 0,75 × critère arrondi à la
seconde supérieure, la condition de `ready()` au § 12.4). Une étape en répétitions est dosée comme `skill.dynamic`.

#### `skill.balance` — équilibre

Rien après l'échéance. 50 % + 3 % par rang (trois au plus) du maintien connu, sinon 15 s + 2 s par rang ;
entre 8 et 45 s ; réserve 5 ; repos 90 s ; technique `skill_practice`, note `quality_first`.

#### `skill.dynamic` — dynamique dans le schéma de la figure

Seulement les séances ordinaires, hors affûtage. Tenue : 5 à 8 s, réserve 3. Record de 3 répétitions et
plus : 60 % du maximum, réserve = maximum − répétitions. Sinon 3 à 5 répétitions (descente freinée : 2
à 3, tempo 4 s, note `slow_negative`), +1 dès que le décalage est positif ; réserve 3. Repos 120 s.

#### Assistance (`accessory.*`)

Rien le jour de l'échéance ; hors séance ordinaire, seuls la prévention et le tronc restent. À
l'affûtage et à la compétition : isolation et compléments supprimés, et en pic de force toute
l'assistance hors prévention, tronc et tirage gardé ; 2 séries au plus. En semaine allégée (hors intro),
isolation et compléments supprimés. Jambes × facteur jambes au-delà de 2 séries ; jamais une seule
série (2 au moins) ; en reprise, sous 75 % de volume, une assistance à une série saute (sauf prévention,
tronc, tirage gardé, jambes de genou).

| Méthode | Répétitions | Réserve | Repos |
| --- | --- | --- | --- |
| `accessory.prehab` | 12 à 15 | 5 | 45 s |
| `accessory.isolation` | 10 à 15 | 2 (3 pour les biceps avec un coude à ménager) | 75 s |
| `accessory.core` | 8 à 12 + décalage | 3 | 60 s |
| `accessory.legs` | record ≥ 3 : 65 % du maximum + décalage (maximum − 2 au plus), plage d'une répétition ; sinon 6 à 8 + décalage | maximum − répétitions ; 3 | 90 s |
| `accessory.compound` et autres | 8 à 10 + décalage | 3 (débutant), 2 | 105 s |
| Tenue | 60 % du maintien connu, sinon 8 s (bras tendus) ou 20 s + 5 s par rang ; 5 à 20 s (bras tendus) ou 15 à 45 s | 3 | 60 s |
| Rebonds et corde | 2 × 20 s ou 15 à 20 | 5 | 60 s |

Nordic : 2 séries au plus, 5 répétitions + décalage. Exercice chargé avec un 1RM : 68 % ; sans 1RM :
à calibrer. Fléchisseurs du poignet de la zone ménagée (`tendon`) : 3 séries à partir du rang 2 hors
semaine allégée, sinon 2, réserve 3, note `tendon_load`. Note de rôle (`role_*`) sur les autres.

#### `warmup.prep` et `mobility`

Préparation : séries du squelette, 15 à 20 s ou 8 à 10 répétitions, repos 30 s, nature `warmup`.
Mobilité (rien le jour de l'échéance) : 2 × 30 à 45 s ou 1 × 8 à 10, repos 20 s.

#### `run.easy`, `run.long`, `run.quality` — course

Rien le jour de l'échéance. Facile : 30 min (sortie longue 45) × (1 + 8 % par rang, quatre au plus),
× 0,7 en semaine allégée, 20 min hors séance ordinaire, entre 10 min et le temps du jour − 8 ; marche de
fin de séance 10 min, footing d'échauffement 12, footing de plus 20 ; distance à 2,5 m/s si l'unité est
une distance ; note `easy_pace`, règle `duration_step` (10 %) en montée. Qualité : séries du squelette +
1 toutes les deux semaines de rang (trois au plus), 4 au moins (4 en semaine allégée, 3 en rappel
d'épreuve), récupération en trottinant 90 s, allure des fractions d'après le temps prévu sur 3 km
(`interval_pace`) ; 30/30 : deux fois plus de fractions de 30 s ; autre : 20 min. Objectif chronométré :
une semaine de montée sur deux (rangs impairs), la séance de qualité devient 3 à 6 × 1 000 m à l'allure
de l'objectif (`goal_pace`) ; en semaine de test, la sortie longue devient le test chronométré (moitié de
la distance de l'objectif, la distance entière en semaine de test ou d'échéance ; `time_trial`).

### 12.6 Garde-fous

Ordre dans une semaine : dosage de chaque séance ; enchaînements (même nombre de tours) et **durée** par
séance ; **plancher de la semaine d'échéance** ; **reprise longue** ; **plafond et montée du volume** ;
**allègement** ; enchaînements ; **hausse des charges**.

- **Durée de séance** (`_fitTime`). Durée = Σ (45 s + séries × effort + (séries − 1) × repos + 180 s de
  montée en charge s'il y en a) + échauffement général (15 % de la séance, entre 3 et 8 min) dès qu'il y
  a du renforcement. Effort : 3 s par répétition (par côté en unilatéral), secondes tenues, distance à
  2,5 m/s, sinon 30 s. Tant que la séance dépasse son temps : la marche de fin de séance raccourcit
  (retirée sous 5 min) ; une série de moins là où l'ordre de retrait (`Method.cutOrder`) est le plus bas,
  sans descendre sous 2 ; un emplacement d'assistance en moins ; une série de moins sur le travail
  principal ; le dernier emplacement non fixe ; les durées de course raccourcissent ; la préparation
  saute ; le dernier test attend. En dernier recours, seul le début de la séance reste. Les groupes
  enchaînés prennent un repos de 90 s entre les tours, fixé après ce calcul.
- **Plafond par groupe** (`coachGroupCap`). Séries dures par groupe majeur et par semaine (crédit 1 au
  muscle principal, 0,5 au secondaire ; une série est dure si sa réserve est de 4 au plus) : 12, 16, 20
  ou 25 selon le niveau, × facteur de volume, × facteur tirage (grand dorsal, haut du dos, biceps) ou
  jambes (fessiers, quadriceps, ischio-jambiers, mollets). Appliqué au squelette puis à chaque semaine.
- **Montée du volume** (`_fitVolume`). Pour chaque groupe et pour le total des séries dures : au plus la
  plus chargée des trois semaines précédentes + 20 % ou + 2 séries (le plus grand) ; si ces trois
  semaines sont toutes allégées, la borne est relevée au double de la plus chargée quand c'est plus.
  Profil lent (40 ans et plus, reprise de 10 semaines ou plus sur les trois premiers blocs, hors des cinq
  premières semaines d'une reprise longue) : + 10 % ou + 1 série par groupe (+ 10 % ou + 2 pour le
  total). Pour chaque groupe, sur trois semaines de charge de suite : au plus × 1,3 ou + 4 séries par
  rapport à deux semaines avant. Les semaines du bloc précédent comptent
  (`seed`). Retrait d'une série à la fois (`Method.trimPass` : l'assistance d'abord, puis le travail
  essentiel), l'emplacement qui crédite le plus le groupe à passe égale ; sinon, l'exercice passe à 5 en
  réserve.
- **Tenues bras tendus.** Secondes de maintien par famille (appui, suspension, mixte) : au plus la
  référence ci-dessus + 20 %, 15 %, 10 % ou 10 % selon le niveau, ou + 5 s. Séries retirées, sinon tenue
  la plus longue raccourcie d'une seconde (3 s au moins), sinon le test de maintien de la famille
  attend. Nombre de jours bras tendus : § 12.4.
- **Allègement** (`_fitTaper`). Séries dures au plus 55 % du pic des 6 semaines précédentes la semaine
  de l'échéance, 55 % du pic des 3 précédentes en affûtage, 65 % en allègement et transition ; débutant
  60 % (échéance) et 70 %.
- **Plancher de l'échéance** (`_floorEvent`). Avec pic de forme, la semaine de l'échéance garde au moins
  42 % (37 % en épreuve de répétitions) du pic des 6 semaines précédentes : une série rendue au travail
  essentiel le moins doté (3 séries au plus, 4 en pic de force), si la séance tient dans son temps.
- **Reprise longue** (`_fitReturn`). Premier bloc après 10 semaines d'arrêt ou plus, semaines 1 à 4 :
  séries dures ramenées à 50 %, 57 %, 66 % puis 76 % du total que la semaine aurait sinon.
- **Hausse des charges** (`_fitLoads`). À répétitions égales, la charge totale d'un même emplacement ne
  monte pas de plus de 10 % (débutant) ou 5 % d'une semaine à l'autre.
- **Zones à ménager.** Admission (§ 12.2), plancher de réserve, entrée à −6 % et −3 % sur le lourd,
  plafond de tirage ou de jambes, prise neutre et charge du tendon quand le coude est gêné ; une règle de
  douleur par zone (`plan.pain_rule`, seuils 3, 4, 6), sinon la règle générale (`pain_general`, arrêt à
  6).
- **Veille de test.** La veille (un jour avant) d'une semaine de tests dont la première séance teste un
  tirage vertical, le tirage vertical et le muscle-up de travail sautent. Deux jours avant un test daté
  sans pic : deux séries au plus à 60 % des répétitions prévues, réserve 5 (`easy_before_test`).

### 12.7 Tests et repères

**Où.** Semaine de tests hors échéance (`testWeek`, pas `eventWeek`), sauf une semaine du bloc qui suit
celle de l'échéance (`_eventPassed` : aucun test après l'épreuve) : dans les séances ordinaires, le
travail d'un emplacement principal (`lift.heavy`, `reps.top`, `skill.hold`, `beginner.main` et
`reps.strength` en rôle principal) est remplacé par un test, un par mouvement. En semaine d'allègement
avec tests : trois mouvements au plus, ceux de l'objectif d'abord. En semaine de test (intention
`test`) : tous les emplacements principaux si aucun ne sert un objectif ; sinon ceux de l'objectif, et
d'autres tant que moins de trois sont testés. Une variante dont le
geste visé est acquis teste le geste visé. Débutant sans traction : test de la descente la plus lente
(2 essais de 5 à 10 s, `negative_gate`), précédé de l'essai strict si la traction est un objectif
(`strict_attempt`) ; en surpoids, suspension la plus longue. Les tests se font juste après
l'échauffement.

**Quoi** (`_testOf`) :

| Exercice | Test |
| --- | --- |
| Tenu | maintien maximal, 2 essais, plage du maintien prévu à l'objectif (ou + 5 s) ; figure : `hold_ramp` |
| Lesté avec 1RM, jour de l'échéance, à partir de l'intermédiaire, hors mode prudent | 1RM en 3 tentatives (91 %, 96 %, puis selon la deuxième ; 6 min), `attempts_plan` ; `attempts_goal` si la barre visée est entre 100 % et 107 % du 1RM |
| Lesté avec 1RM, autres cas | 3RM à 88 %, une répétition en réserve |
| Lesté sans 1RM | 5RM à calibrer |
| Poids du corps | série maximale, plage du maximum prévu au maximum + 2 (ou l'objectif) ; réserve 1 sur un mouvement à risque ou chez le débutant, 0 sinon ; `max_set_plan` dès 4 répétitions |

Chaque test porte `plan.test_scheduled` et, hors échéance, le repère attendu sur le chemin de l'objectif
daté (`checkpoint`, progression linéaire depuis la création du profil).

**Semaine de l'échéance** (`_roles`). La séance qui précède ou tombe le jour de l'échéance la porte ;
les suivantes sont de récupération (préparation, mobilité, prévention, assistance polyarticulaire et
tronc à 2 séries au plus et 5 en réserve, course facile ; une séance qui resterait vide reçoit un
travail facile de son premier emplacement, note `recovery`). Avec pic de forme : rappel à J−3 et plus, repos (préparation et
mobilité, `rest_before_event`) à J−2 et J−1, avec à J−2 une activation à 40 % du maximum (épreuve de
répétitions, `activation`) ou deux simples à 65 % (pic de force, `primer`). Sans pic : semaine ordinaire,
séance facile à J−2, repos la veille. Le jour de l'échéance : préparation, puis un test par exercice de
l'échéance (mouvements, ateliers, objectifs liés ; figure : l'étape travaillée ; ordre muscle-up,
traction, dips, squat en streetlifting ; cinq au plus), note `event_day` (jours jusqu'à l'épreuve). En
épreuve de répétitions, phase de réalisation (une semaine sur deux sous l'élite) et affûtage à J−9 et
plus : la première séance à série longue répète l'épreuve (une série par atelier, 300 s,
`event_rehearsal`).

**Le repère ne monte qu'après un test de cet exercice.** Le prescripteur note la date de chaque test
(`_testedOn`) : ceux des semaines du bloc précédent (`seed`), puis ceux du bloc en cours, datés de la fin
de leur semaine (le test de descente date aussi la traction). Le maximum de répétitions (`_maxOf`) et le
maintien (`_holdOf`) de travail restent le record tant que l'exercice n'a pas été testé ; après un test,
ils valent le record × (1 + progrès planifié à la date du test), fixes jusqu'au test suivant. Après une
coupure de 2 semaines ou plus, le maximum de travail est le record × repère de reprise (§ 12.5) : celui
de départ tant que l'exercice n'a pas été testé, puis celui qui correspond au nombre de semaines de
tests déjà passées (le bloc précédent et le bloc en cours) ; le maintien reste le record. Le repère d'un
test est le maximum attendu le jour même.

### 12.8 Notes de coach

Le moteur ne rend aucune phrase : il rend des raisons `plan.coach_note` (`note` : un code de
`CoachNotes`, `value` : un nombre) et `plan.progression_rule` (`rule` : un code de `CoachRules`, `step`,
`unit`). Les textes français sont construits par `coachReasonText` (`texts.dart`) ; la liste complète des
codes, de leurs valeurs et de leurs textes est dans `docs/NOTES_COACH.md`.

**Raisons de l'emplacement (passe 1).** `plan.undulation` (jour lourd, moyen, léger), `plan.weak_point`,
`plan.goal_support`, note `maintenance` sur `lift.maintain`.

**Raisons du bloc** (passes 1 et 2, `blockReasonsOf`) : `plan.cautious_health` en mode prudent,
`plan.season_phase`, `plan.peak_event`, `skill_horizon`, `general_warmup` (8 min), `ambitious`,
`load_adjust` (avec du lesté), `reps_adjust`, `bad_day`, `short_version`, `red_flags`, `missed`,
`test_use` et `test_rest` (si le bloc a des tests), `plan.training_age`, `plan.return_from_gap` et
`reentry_test` (coupure), `plan.recovery_profile` (sommeil, stress, travail, âge), `tolerance_volume`,
`already_applied`, `plan.concurrent_sport`, `plan.specialization`, `band_choice`, `pain_general` ou
`plan.constraint_history` et `plan.pain_rule` par zone, `walking` et `tracking` (perte de poids),
`plan.skill_step`.

**Raisons de la semaine.** `plan.week_kind` sur le premier exercice de travail de chaque séance ;
`plan.taper` (part mesurée des séries dures de la semaine de pointe) en affûtage.

### 12.9 Revue, bloc suivant, restructuration

**Revue** (`CoachEngine.review`). L'action seule, sans ré-optimisation : `can_do` verrouille
l'emplacement et note l'exercice comme su ; `cannot_do` et `dislike` excluent l'exercice et le
remplacent partout par le plus proche du même schéma et de la même unité, admissible ce jour-là (plus
facile ou égal pour `cannot_do`), ou le retirent s'il n'y en a pas ; les exercices que l'action rend
inadmissibles (variante plus dure d'un mouvement non su) sont remplacés de même ; `remove` retire
l'emplacement s'il n'est pas le seul de la séance ; `replace` met l'exercice choisi et le verrouille
(un doublon du même jour disparaît) ; `add` l'ajoute avant la mobilité de fin de séance, verrouillé (ou
verrouille l'emplacement s'il est déjà dans la séance), et le note comme aimé. Le programme « après l'action seule » est le résultat lui-même. La passe 2 d'un
programme revu reconstruit le squelette et le ramène aux emplacements du programme
(`reconcileSkeleton`) : un emplacement remplacé garde sa méthode si l'unité, la nature de charge et le
rang dans la séance concordent, sinon il reçoit la méthode de sa nature (`coachMethodFor`).

**Bloc suivant.** Rang + 1, squelette reconstruit à la date du bloc ; la passe 2 part de l'historique
des semaines du bloc précédent (montée du volume, dates des tests). Le diff donne `plan.variety` aux
exercices remplacés, `plan.season_phase` aux ajouts et retraits ; la proposition porte le plan de
saison.

**Restructuration.** Motifs lus : douleur (zone, intensité → zone à ménager), exercice sauté ou en
stagnation (écarté), temps réduit (minutes du jour visé, 5 au moins), fatigue ou bilan bas (volume ×
0,85 au plus ; jamais au-dessus de 1). Dans les jours non figés (`keep_day`, autres jours d'une portée
`session`), un exercice devenu inadmissible (exclusion, zone, matériel) et non verrouillé est remplacé
par le plus proche du même schéma ou retiré. La passe 2 est recalculée (sans l'historique du bloc
précédent) ; `session` : seul le jour visé change, de `fromWeekIndex` à la fin ; `week` : seule la
semaine `fromWeekIndex` change, la passe 1 rendue reste celle d'avant ; `block` : toutes les semaines à
partir de `fromWeekIndex`. Les semaines d'avant sont rendues telles quelles.

**Contraintes dures** (`CoachEngine.violations`, utilisé par `PlanInspector.hardViolations`) : nombre
de jours, jour de la semaine, séance vide, exercice en double, exercice inadmissible
(`Athlete.rejection`), sauf emplacement verrouillé par la requête.

### 12.10 Paramètres et références

« Source » reprend ce que dit le commentaire du code : un identifiant du référentiel, « choix
raisonné » (le code le dit, ou ne cite rien), ou le journal de calibrage `CALIBRAGE_CP1`.

| Paramètre | Valeur | Source |
| --- | --- | --- |
| **Lecture du profil** | | |
| Poids de corps par défaut | 75 kg | choix raisonné |
| Exposant de la formule de Riegel (chrono → 10 km) | 1,06 | choix raisonné (le code nomme la formule) |
| Rythme maximal planifié, répétitions (par semaine, par niveau) | 8 %, 3 %, 2 %, 1,2 % | R5-P13 (dit « choix raisonné ») |
| Rythme maximal planifié, maintien | 5 %, 4 %, 3 %, 2 % | choix raisonné |
| Plancher du rythme planifié | une unité toutes les 3 semaines | choix raisonné |
| Rythme sans objectif ; plafond sans objectif | moitié ; 20 % | choix raisonné |
| Facteurs de tolérance (60 ans × 0,8 ; sommeil × 0,85 et +1 RIR ; stress × 0,9 et +1 RIR ; travail × 0,85 ; endurance × 0,7 à partir de 3 séances ; gêne × 0,6 tirage, × 0,7 jambes, dès 2/10) | voir § 12.2 | R5-P10, P14, P15, P18, P19, P21 (dits « choix raisonnés ») |
| Cumul des réductions | 0,6 au moins | R5-P21 |
| Profil lent | 40 ans et plus | R5-P21 |
| Semaines d'arrêt par réponse de coupure | 1, 2, 6, 16, 36, 104 | choix raisonné |
| Impact écarté chez le débutant | IMC ≥ 30 | R5-P9 |
| Seuils de gêne de l'admission | forte ≥ 4 ; moyenne ≥ 6 | choix raisonné |
| Écart de niveau admis | niveau + 1 | choix raisonné |
| Mode prudent | moins de 18 ans, 65 ans et plus | choix raisonné |
| Antécédent récent | moins de 12 mois | choix raisonné |
| **Saison** | | |
| Durées de bloc préférées | débutant 6, 5, 4 ; intermédiaire 5, 6, 4 ; ensuite 4, 5, 6 | R3-P9 |
| Bloc de l'intermédiaire sans échéance | 6 semaines | R3-P9 |
| Découpage du reste en blocs | 4 à 6, reste ≠ 7 | choix raisonné |
| Reprise au premier bloc | coupure ≥ 3 semaines | choix raisonné |
| Semaine d'intro | 0,9 | R5-P22 |
| Affûtage avant un test daté (linéaire) | 0,75 (débutant), 0,6 | R3-P9, R3-P21 |
| Affûtage avant un test daté (général) | 0,55 | R3-P21, R4-G7 |
| Reprise : volume de départ, hausse | 0,5 ; × 1,15 par semaine ; 0,95 au plus | R5-P7, R5-P22 |
| Autres facteurs de volume des semaines (0,9 à 1,0 ; 0,92 à 1,0 ; 0,85 et 0,8 ; 0,7 ; 0,62 ; 0,6 ; 0,55 ; 0,45 ; 0,42) | § 12.3 | choix raisonné (modèles : R3-P2, R3-P3, R3-P4, R3-P9, R3-P12 à P14, R3-P20, R3-P21) |
| Transition après l'échéance | 0,5 | R3-P19 |
| Bascule vers l'intensification | 6 semaines (général), 5 (pic de force), 8 (pic d'endurance) restantes | choix raisonné |
| Affûtage de 2 semaines | compétition et avancé (pic de force) ; avancé (pic d'endurance) | choix raisonné (modèles R3-P12 à P14, R3-P21) |
| Crans de rang entre blocs | 1 par bloc, 3 au plus | R3-P3 |
| **Squelettes** | | |
| Délai minimal par étape de figure | 12, 8, 8, 6 semaines | R4-F9 |
| Ancienneté à l'étape | 2, 8, 16, 26 semaines | choix raisonné |
| Séries du débutant | 2 (3 jours et plus, séance < 55 min), 3 ; +1 au 2e bloc | R5-P1, R5-P2 |
| Tirage horizontal du débutant | 2 ou 3 jours | R1-P1 |
| Appui bras tendus du débutant | 2 jours non consécutifs | R4-F10 |
| Descentes freinées du débutant | 2 jours, 2 séries | R5-P8 |
| Pompe adaptée | 6 à 8 répétitions avec 3 en réserve | R5-P9 |
| Seuils du débutant (traction 5, pompe 6 et 4, dips 5, rowing 10 ; 40, 35, 55 min) | | choix raisonné |
| Course : part minimale, nombre de jours | 20 % ; arrondi(jours × part), 2 à jours − 2 | choix raisonné |
| Séance de qualité | une par semaine au plus, dès l'intermédiaire | R6-P15 |
| Footing de plus (objectif chronométré) | séance ≥ 55 min | R6-P14 |
| Fréquence du tirage (sets & reps) | 3, 4, 5 selon le niveau | R4-G8, R4-G5 |
| Pas deux jours de tirage consécutifs (jusqu'à l'intermédiaire) | 48 h | R4-F10, R5-P22 |
| Profil de retour (sets & reps) | coupure ≥ 10 semaines, trois blocs | R5-P6 |
| Bascule force / endurance d'un pilier | 8 répétitions | R4-G2 |
| Lest ; variante dure | 8 ; 10 répétitions | R4-G2, R1-P17 |
| Séries par méthode (série longue 3 ou 4, force 4, densité 6 ou 8, autres 4 ou 5) | | choix raisonné |
| Entretien d'un pilier | 3 séries | R4-H3 |
| Poussée en entretien | objectif sur le seul tirage | R4-H4 |
| Exposition légère de traction | 4 tractions et plus, 3 séries | R4-G5, R4-G8 |
| Densité les jours sans traction | 5 tractions et plus, 7 départs | R4-G6, R4-G8 |
| Muscle-up : simples dès 3, densité dès 6 | | R4-F1, R5-P27 |
| Pratique des figures en sets & reps | calisthénie ≥ 25 % | R4-F1 |
| Mollets et rebonds du coureur | séance ≥ 45 min | R6-P22 |
| Séances enchaînées | 50 min ou moins | choix raisonné |
| Répartition lourd / volume (streetlifting) | | R2-P7, R3-P3 |
| Coude ménagé | gêne récente ≥ 2 | R5-P20, R5-P24 |
| Spécialisation | | R4-H1 à R4-H4 |
| Séries du streetlifting (5 en élite ou sur la cible ; entretien 3 ou 2) | | choix raisonné |
| Jours lourds d'une figure | 2, 2 (3 sur 4 jours), 3, 3 | R4-F10, R4-F1 |
| Critère de passage d'étape | 12, 10, 8 s ; 3 répétitions ; 3 séries ; qualité 4 ; 3 séances | choix raisonné |
| Étape suivante | trois quarts du critère, délai écoulé | R4-F9 |
| Étape plus facile en complément | maintien < 8 s | R4-F7 |
| Équilibre programmé | maintien ≥ 20 s | choix raisonné |
| Jours bras tendus par famille | 2, 3, 3, 4 | R4-F10 |
| Compléments : seuil de temps libre, nombre | 20 % ; 1, 2, 3 (≤ 45, < 75 min, au-delà) ; 3 par semaine, chaîne postérieure 2 (1 en pic) | choix raisonné (but : R1-P1) |
| Mobilité secondaire | 10 % | choix raisonné |
| **Dosage** | | |
| Plafond de séries dures par groupe | 12, 16, 20, 25 | R1-P1, R5-P13 |
| Hausse du volume par semaine | 20 % ou + 2 séries (profil lent : 10 % ou + 1) | R5-P22 |
| Hausse sur deux semaines | × 1,3 ou + 4 | choix raisonné |
| Hausse des tenues bras tendus | 20 %, 15 %, 10 %, 10 % ou + 5 s | R5-P22, R4-F10 |
| Hausse de la charge | 10 %, 5 %, 5 %, 5 % | R5-P3, R5-P22 |
| Série dure | réserve ≤ 4 | choix raisonné |
| Durée d'une répétition, transition, échauffement | 3 s ; 45 s ; 15 % de la séance, 3 à 8 min | R5-P13 |
| Vitesse de course (conversion) | 2,5 m/s | choix raisonné |
| Tableau répétitions / part du 1RM | 1 à 100 % … 12 à 71 % | R2-P2 |
| Plancher : mouvement à risque | 2 | R5-P27 |
| Plancher : débutant | 2 | R5-P4 |
| Mode prudent : plancher, plafond de charge, test | réserve 2 ; 85 % du 1RM ; pas de 1RM en 3 tentatives | choix raisonné |
| Réserve plancher impossible sur une répétition (`_honest`) | part R2-P2 de « 1 + plancher » | R2-P2 |
| Plancher : zone à ménager | 2 | R5-P23 |
| Plancher : reprise | 3 (1, 2 semaines ou le bloc) ; 4 après 16 semaines | R5-P7 |
| Plancher : après 10 semaines d'arrêt | 2 sur trois blocs | R5-P6 |
| Réserve d'intro, d'allègement | + 1 ; ≥ 3 | choix raisonné |
| Repères de reprise | 0,90, 0,82, 0,75 ; 0,92, 0,95, 1 | R5-P7, R5-P6 |
| Série d'entrée de reprise | 3 en réserve ; 4 après 16 semaines d'arrêt | choix raisonné |
| Deux séries au plus la semaine de l'échéance | | R3-P12 |
| Décalage de plage | + 1 toutes les 2 semaines, + 2 au plus | choix raisonné |
| `lift.heavy` accumulation, intensification | 80 à 84,5 % × 5 ; 86 à 90 % × 3 | R3-P4 |
| `lift.heavy` réalisation | 87 à 90 % (intermédiaire) ; 91 %, 93 à 95 % | R3-P4, R2-P1 |
| Séries à 85 % et plus en intensification | baisse des séries allégées 5 % | R2-P8 |
| `lift.heavy` intro | 76 % × 5 | choix raisonné |
| Affûtage du lourd | 2 × 3 à 80 % ; dernier lourd 90 % à J−7 à J−10 | R3-P12, R3-P13, R3-P14 |
| Allègement du lourd | 75 % ou 80 %, réserve 4 | R3-P9 |
| Zone ménagée : entrée | − 6 %, − 3 % | R5-P24 |
| Rappels avant l'échéance | 88 % (test sans pic), 85 % (pic) ; 2 × 2 à 70 % | R3-P13, R3-P14 |
| Entretien | 83 % × 3, 76 % × 5 ; 75 % × 3 | R4-H3 |
| Recalage | 2,5 % | R3-P16, R2-P20 |
| `lift.volume` | 72 à 78 % × 6 ; 78 à 84 % × 4 ; 82 % × 3 ; 67 ou 72 % | choix raisonné |
| `lift.light` | 70 % (65 %) × 3, réserve 5 | R2-P7, R3-P3 |
| Amplitude partielle | 95 % + 5 % par bloc + 2,5 % par semaine ; 110 % (105 % coude) | CALIBRAGE_CP1 (C), R5-P24 |
| Autres variantes | 70 ou 74 % + 1 % ; 80 % au plus | choix raisonné |
| Arrêt des variantes avant l'échéance | | R3-P13, R2-P9 |
| Lest d'un 1RM proche du poids de corps | part R2-P2 de « répétitions + réserve » ; nul ou négatif : à calibrer ; seuil 78 % | R2-P2 (seuil : choix raisonné) |
| Muscle-up lesté | 3 répétitions au plus | R5-P27 |
| `reps.top` : marges, 8 % du maximum, séries à 60-70 % | | R4-G3 |
| `reps.top` à l'affûtage | 15 % du maximum, 3 au moins | R3-P13, R3-P21 |
| Repos-pause | objectif ≥ 15 répétitions ; 3 relances | R4-G6, R4-G7 |
| `reps.volume` | 55 ou 60 % + 3 % ; 70 % au plus ; repos 120, 90, 60 s | R4-G4 |
| Repos du tirage vertical | 120 s | R1-P16 |
| Repos des séries de 20 et plus | 120 s | choix raisonné |
| `reps.density` : part du maximum | 40 %, 45 % ; 30 % à risque | R4-G6 |
| `reps.density` : départs | + 1 toutes les 2 semaines (3 si lent), + 2 au plus | R5-P22 |
| `reps.density` : bornes, intervalle | 4 à 10 départs ; 60 à 180 s | choix raisonné |
| `reps.strength` : marge | 2 (+ 1) | R4-G2 |
| Charge estimée | 77 % + 1,5 %, au plus la part R2-P2 de « 5 + réserve » ; Epley jusqu'à 20 répétitions | R2-P2 |
| Variante dure sans record | 60 % du maximum de base | choix raisonné |
| `reps.technique` | 1, 2 ou moitié du maximum | R4-F1, R5-P27 |
| Débutant : 2 séries les 2 premières semaines | | R5-P1, R5-P22 |
| Débutant : 50 à 70 % du maximum, maximum − 3 | | R5-P2, R5-P4 |
| Débutant : séries qui montent (petit maximum) | | R5-P3 |
| Débutant sans record | 6 à 8 (8 à 10) | R5-P9 |
| Descentes freinées | 3 à 7 s ; 2 à 4 descentes | R5-P10, R5-P8 |
| Appui bras tendus du débutant | 8 à 30 s, part 60 % | CALIBRAGE_CP1 (A-18) |
| Maintiens de figure | 50 à 70 % ; 75 % la séance lourde | R4-F2, R4-F6 |
| Secondes cumulées par séance | 30, 45, 50, 60 | R4-F2 |
| Part de l'étape actuelle (deux étapes) | 0,6 | R4-F6 |
| Repos des isométries dures | 180 ou 150 s | R1-P16 |
| Essai maximal en élite | toutes les 2 semaines | R4-F2 |
| Étape suivante : entrées | 2 à 3 s | R4-F7, R4-F9 |
| Équilibre | 50 % + 3 % ; 8 à 45 s | R4-F2 |
| Dynamique de la figure | 3 à 5 répétitions | R4-F5 |
| Prévention | 12 à 15, réserve 5 | R5-P24 |
| Charge du tendon | 3 séries dès le rang 2 | R5-P24 |
| Nordic | 2 × 5 + 1 toutes les 2 semaines | R5-P22 |
| Coupe de l'assistance à l'affûtage | | R3-P13 |
| Assistance chargée | 68 % du 1RM | choix raisonné |
| Course facile | 30 / 45 min, + 8 % par rang ; règle + 10 % | R6-P14, R6-P20 |
| Séance de qualité | fractions courtes, récupération égale | R6-P15, R6-P16, R6-P20 |
| Allure de l'objectif | fractions de 1 000 m | R6-P14 |
| Tests de 1RM | 91 %, 96 % ; 6 min | R3-P15 |
| Test hors compétition | 3RM à 88 % | R3-P16 |
| Fenêtre de la barre de l'objectif | ≤ 107 % du 1RM | choix raisonné |
| Rôles de la semaine d'échéance | J−3 et plus ; J−2 et J−1 | R3-P14, R2-P10, R3-P21 |
| Activation | 40 % du maximum | R3-P21 |
| Amorçage | 65 % du 1RM | CALIBRAGE_CP1 (G) |
| Répétition de l'épreuve | 300 s ; jusqu'à J−9 | R4-G1, R3-P20, R4-G7 |
| Séance facile à J−2 | 60 % des répétitions, 2 séries | choix raisonné |
| Allègement (garde-fou) | 55 %, 65 % ; débutant 60 %, 70 % | R3-P12, R3-P21, R3-P9 |
| Plancher de l'échéance | 42 %, 37 % | R3-P12, R3-P21 |
| Reprise longue | 50, 57, 66, 76 % | R5-P7, R5-P22 |
| Repos des enchaînements | 90 s | choix raisonné |
| Règle de douleur | 3, 4, 6 | R5-P23 |
| Objectif ambitieux | rythme > 1,5 % (avancé) ou 2 % par semaine ; + 15 % en 12 semaines | R4-G8 |
| Perte de poids : marche | 30 min | CALIBRAGE_CP1 (A-21) |
| Valeurs des notes de bloc (manquée 20 %, version courte 25 ou 15 min, repos avant test 48 h, élastique 8, arrêt 6) | | choix raisonné |
| **Relecture** (`coachAudit`) | | |
| Plafond par groupe | 12, 20, 25, 30 | R1-P1 |
| Niveau minimal des techniques | série de tête 1 ; repos-pause, cluster… 2 | R2-P22 |
| Baisse minimale la semaine de l'échéance | 30 % (40 % dès l'avancé) | R3-P12, R3-P21 |
| Tolérance de durée | + 15 % + 3 min | choix raisonné |

### 12.11 Invariants testés

`test/coach_test.dart` :

| Test | Ce qu'il vérifie |
| --- | --- |
| « profil street au schéma 3 rempli : chemin street » | profil débutant éligible, programme avec intention |
| « schéma 2, ancienneté absente ou discipline non street : 0.1 » | ces profils prennent le chemin 0.1 |
| « les profils aléatoires de 0.1 ne prennent pas le chemin street » | 300 profils de `randomProfile` |
| « les blocs finissent sur l'échéance » | streetlifter avancé, compétition à 12 semaines : 12 semaines, la dernière en compétition, la 11e en affûtage, blocs de 4 à 6 semaines, au plus 5 semaines de charge de suite |
| « épreuve la semaine de l'échéance, volume en baisse » | tests des trois mouvements ; séries dures entre 25 % et 60 % du pic des semaines 6 à 11 |
| « la série de tête monte de l'accumulation à la réalisation » | traction lestée : sous 85 % au début, pic entre 90 et 95 %, 85 % et plus chaque semaine de réalisation |
| « le plan de saison couvre les mêmes semaines » | 12 semaines, dernière phase en compétition |
| « relecture : aucun manquement » | `coachAudit` vide |
| « ni technique, ni échec, ni exercice hors de portée » | débutant, 12 semaines : pas de technique d'intensification, réserve ≥ 2, pas de traction stricte, `coachAudit` vide |
| « un chemin vers la traction à chaque séance » | débutant : traction assistée ou descente chaque jour |
| « coude récent : pas de traction lestée, 2 en réserve au moins » | et une règle de douleur |
| « reprise après une longue coupure : semaine 1 facile » | réserve ≥ 3 les deux premières semaines, volume de la semaine 1 ≤ semaine 4, `coachAudit` vide |
| « un remplacement est gardé par la passe 2 » | et le diff n'a qu'une ligne |
| « chaque note et chaque règle a son texte français » | `CoachNotes.all`, `CoachRules.all` |
| « toutes les raisons rendues sont au registre » | passes 1 et 2 valides, raisons valides |
| « même requête, même JSON » | 12 semaines, deux exécutions |
| « création en moins d'une seconde, régénération en 300 ms » | 40 profils street aléatoires |

`test/coach_properties.dart`, joué par `test/coach_properties_0_test.dart` à `_7_test.dart` (tests
« profils N à M », 160 profils chacun) : **10 240 profils street aléatoires** (`randomCoachRequest`,
« Autre proposition » pour 1 sur 16). Pour chacun : profil valide et éligible ; passe 1 valide au
contrat, exercices du catalogue, aucune contrainte dure (`hardViolations`), intention, nombre de jours,
version, 4 à 6 semaines, note entre 0 et 1 et égale à la note relue, séances non vides, thèmes connus,
identifiants `d<jour>.<n>`, raisons valides ; passe 2 valide, bloc valide, semaines avec intention,
séances non vides, séries de 1 à 20, flammes valides, repos et charges ≥ 0, répétitions de 1 à 100,
secondes ≥ 1 ; `coachAudit` vide. Selon la graine : déterminisme de la création (1 sur 4) ; plan de
saison valide et continu (1 sur 4) ; bloc suivant valide, rang 1, relecture des deux blocs,
déterminisme (1 sur 4) ; une action de revue (1 sur 2) — verrous tenus, effet de l'action, aucun autre
emplacement changé sans raison, passe 2 conforme, admission et séances non vides relues, déterminisme
(1 sur 4) ; restructuration (1 sur 8) — bloc et diff valides, semaines passées identiques, séances non
vides, déterminisme.

**Ce que la relecture partage.** `coachAudit` et `CoachEngine.violations` relisent le programme rendu
sans connaître sa construction (volume, montée, tenues, charges, durée, réserve, affûtage), mais
l'admission d'un exercice y passe par la même fonction que la construction (`Athlete.rejection`) : une
erreur dans une règle d'admission ne serait pas vue. La relecture est plus large que le moteur sur
certains points (plafonds 12, 20, 25, 30 au lieu de 12, 16, 20, 25 ; montée à 20 % sans le cas du profil
lent ; durée tolérée à 115 % + 3 min).

### 12.12 Déterminisme et budgets

Tout est fonction pure de la requête : aucune horloge, aucun hasard ; la graine ne fait que décaler des
listes ; `CoachEngine` ne garde aucun état. Les choix à égalité sont départagés par l'ordre des listes
et des jours, ou par l'identifiant (remplacements). Même requête, même JSON : testé (§ 12.11). Budgets
testés sur 40 profils street aléatoires, sur la machine du contrôle : création (passes 1 et 2) en moins
d'une seconde, passe 2 refaite en moins de 300 ms. Aucune mesure du chemin street n'est encore dans
`docs/MESURES.md`.

### 12.13 Saison complète (0.2.1, lot CX)

Changements du chemin street faits pour une saison entière écrite bloc après bloc d'après ce que
l'athlète a montré (croisement avec `kalis_adapt` 0.2.1, `kalis_bench` 0.2.0, mode saisons). Le chemin
0.1 n'est pas touché (mêmes programmes à l'octet près, version du moteur mise à part). Aucun type ni code
de raison de `kalis_core` n’est ajouté ; trois codes de note de coach (`pain_trend`, `weight_class`,
`event_format` : `docs/NOTES_COACH.md`) s'ajoutent au vocabulaire de `plan.coach_note`.

**Repères du bloc suivant** (`Athlete.read`, paramètres `extraPains` et `estimates`, passés par
`createPass1` et `nextBlock` depuis le résumé d'adaptation) :
- le dernier résultat daté d'un test guidé ou d'une compétition fait foi, même plus bas qu'un record
  déclaré, sauf valeur déclarée plus récente ; un test plus bas que le repère n'abaisse le repère que
  jusqu'à ce que l'estimation du moteur d'évolution montre (6 séries au moins) ;
- aucun gain supposé quand le repère vient d'un test de la semaine précédente (`_measuredAt`) ;
- une estimation (6 observations au moins, erreur ≤ 6 % de la capacité, aucun test plus récent) abaisse
  un repère de plus de 2,5 % (6 % pour un 1RM : l'estimation du moteur d'évolution se tient 3 à 5 % sous le
  1RM réel) ; elle devient le repère d'un exercice qui n'en avait pas (variante jamais
  déclarée ni testée, dosée jusque-là par une plage fixe) ; elle ne monte jamais un repère connu ;
- une douleur du résumé (3/10 et plus) devient une gêne récente du bloc (`CoachLimit.trend`) : une figure
  sur cette zone reste au programme sous 6/10, à 60 % de ses séries, avec la note `pain_trend` ; les autres
  exercices suivent l'admission habituelle.

**Lieu** : l'admission d'un exercice lit `CatalogExercise.feasibleAt` (kalis_core 0.4.2) : pas d'appui au
mur au parc sans mur déclaré ; matériel de remplacement (pompe mains surélevées sur barre basse, box ou
barres parallèles) ; meuble stable à la maison.

**Saison** : semaine de transition (volume 50 %, intention `transition`) puis semaine de reprise (75 %)
quand une épreuve principale a eu lieu dans les dix jours qui précèdent le bloc (`justAfterEvent`).

**Squelettes** : jours de tirage écartés de 48 h autant que les jours d'entraînement le permettent
(répétitions : jours de tirage non consécutifs, la fréquence descend jusqu'à trois chez l'avancé ; avec
trop de jours consécutifs, deux séances de tirage peuvent se suivre ; streetlifting : volume et séance légère loin du tirage lourd et du muscle-up) ;
échelle de poussée du débutant (genoux → mains surélevées → sol) écrite dans `skillLadders`, critère de
passage 12 ou 10 répétitions × 3 sur deux séances, deux semaines au moins ; dès le deuxième bloc, pompe au
sol en séries courtes à chaque séance quand l'objectif est la pompe et que deux pompes au moins sont
acquises ; descentes freinées de traction après la séance de force quand le maximum est sous dix ; test du
chemin vers la traction : tenue menton au-dessus de la barre en secondes, hors du budget des tenues bras
tendus.

**Dosage** : critère de passage d'une figure à environ 75 % du maximum (`coachStepHold`, 12, 11, 9, 7 s),
étape suivante ouverte quand le maximum atteint ce seuil ; tenues à 60-70 % les jours légers, 75-85 % les
jours lourds ; séries allégées −8 % (introduction, accumulation, dernier lourd), −5 % (intensification,
réalisation) ; trois séries lourdes au moins en intensification et réalisation ; hausse hebdomadaire du
volume 15 % au plus ; semaine d'allègement à 65 % au plus de la plus chargée des trois précédentes ;
réalisation d'une échéance de répétitions : séries de volume à 65-75 % du maximum, départs au chrono qui
montent de 5 % par semaine jusqu'à 55 % ; variante facile de l'échelle de poussée plafonnée à 8-12
répétitions ; lest sous le plus petit pas ou sous le poids du corps : série au poids du corps chiffrée
d'après le maximum au poids du corps (jusqu'à 8 répétitions) ; partielles surchargées retirées les quatre
dernières semaines avant l'échéance, entrée à 82,5 % puis +2,5 % par semaine et 95 % au plus quand le coude
a un antécédent.

**Ajouts des boucles 3 à 5** : séries de travail sur le dernier repère mesuré (le repère attendu ne vaut
que pour la cible d'un test) ; figure écartée par le moteur d'évolution pour une douleur relevée sous 6/10 :
gardée au bloc suivant (`pain_trend`) ; 1RM de travail relevé d'après le maximum au poids du corps quand il
le dépasse (table R2-P2, Epley au-delà de 12) ; tenue menton à 60-70 % du maintien, jusqu'à 25 s ; étape plus
facile d'une figure jusqu'à 40 s ; test de l'objectif en tête de séance ; critère de l'échelle de poussée :
2 × 12 sur deux séances ; pompe au sol d'un objectif de pompes en grappes (5 séries courtes) ; négatives de
pompe gardées tant que le maximum est sous six ; une seule règle d'élastique (`assistance_step`) et essais
stricts de traction dès la sixième semaine ; tirage bras tendus à l'élastique les jours de force quand le
front lever est visé ; semaine d'introduction à 80 % chez l'avancé et l'élite qui préparent une échéance de
répétitions ; séries de volume d'introduction une marche sous la semaine suivante.

**Notes** : catégorie de poids et pesée d'une épreuve de force (`weight_class`, règlement FinalRep) ;
format d'épreuve de répétitions à saisir (`event_format`) ; figure gardée sur douleur (`pain_trend`).

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Estimation retenue : observations, erreur, marge (répétitions, maintiens ; 1RM) | 6 ; 6 % ; 2,5 % ; 6 % | choix raisonné (CALIBRAGE_CX) ; Helms et al. 2018 (régler sur la performance mesurée) |
| Douleur relevée retenue | 3/10 et plus | règle de douleur du programme (3-4 : sans progression) |
| Figure sur douleur relevée | 60 % des séries, arrêt à 6/10 | R5-P23 (−30 à −50 %) ; Silbernagel et al. 2007 (suivi de la douleur, ≤ 5/10) |
| Transition après épreuve ; reprise | 50 % ; 75 % du volume | R3-P19 ; R5-P22 (+10 à 20 % par semaine) |
| Critère de passage d'une figure | 12, 11, 9, 7 s × 3, deux séances (≈ 75 % du maximum) | Oranchuk et al. 2019 (isométrie ≥ 70 %) ; panel CX |
| Tenues | 60-70 % léger, 75-85 % lourd | Bohm et al. 2015 (80-90 % pour le tendon) ; R4-F2 |
| Séries allégées | −8 % ; −5 % | R2-P8, R3-P4 |
| Hausse hebdomadaire du volume | 15 % | R5-P22 |
| Allègement | ≤ 65 % du volume récent | R3-P11 (décharge de 40 à 60 %) |
| Réalisation des répétitions | volume 65-75 % ; départs 45-55 % | R3-P20, R4-G3, R4-G6 ; Prestes et al. 2017 |
| Échelle de poussée | genoux, mains surélevées, sol ; 8-12 répétitions | Ebben et al. 2011 ; R5-P9 |
| Partielles, coude à antécédent | 82,5 % puis +2,5 %/semaine, 95 % au plus | R5-P24 |
| Catégories de poids | −66 à +101 kg (hommes), −52 à +70 kg (femmes), pesée 2 h avant, 0,1 kg | règlement FinalRep |
| Tirage | 48 h entre deux séances de tirage quand les jours le permettent | ACSM 2009/2011 (48 h) ; Miranda et al. 2018 |

Invariants ajoutés aux tests (`test/coach_test.dart`, groupe « CX — saison complète ») : pas de traction
deux jours de suite (streetlifting, répétitions avancé) ; catégorie de poids puis transition après une
épreuve ; échelle de poussée du débutant sans pompe ; un test mesuré plus bas que le record déclaré fait
foi.

Limites : la pompe au sol, la traction stricte et l'étape suivante d'une figure ne s'ouvrent dans le
programme écrit qu'à un bloc suivant (le moteur d'évolution sert le jour même) ; le temps de séance
disponible n'est pas rempli d'office ; les athlètes de ces mesures sont simulés.
