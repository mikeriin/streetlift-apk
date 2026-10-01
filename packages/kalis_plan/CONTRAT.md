# Contrat de kalis_plan 0.1.0

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
une erreur dans la règle elle-même ne serait pas vue par les tests de propriétés. Elles sont couvertes par
des cas écrits à la main (`test/engine_test.dart`, `test/units_test.dart`) et par la lecture des 40
programmes. Les plages de répétitions ne font l'objet d'aucune propriété testée.

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
