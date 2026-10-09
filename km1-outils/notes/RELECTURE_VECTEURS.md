# Relecture des vecteurs de qualités : Koach 1.0, brique 2 du lot KM1

Relecteur indépendant (préparation physique : musculation, street workout et calisthénie, haltérophilie, CrossFit, course, mobilité). Relecture faite le 9 octobre 2026.

Fichiers relus, sans aucune modification :
- `moteurs/packages/kalis_adapt/reference/qualites/regles.py`, lu en entier (R1 à R7) ;
- `moteurs/packages/kalis_core/data/catalog_v1.json.gz` (1 039 exercices) ;
- `moteurs/packages/kalis_adapt/reference/qualites/vecteurs_qualites_v1.json`. `regles.py --verifier` renvoie 0 : le fichier est à jour par rapport aux règles.

Les scripts de ce rapport (échantillonnage, vérifications globales, simulation des corrections) ont tourné dans un répertoire temporaire. Leur code est reproduit en annexe.

---

## A. Méthode et échantillon

### A.1 Méthode

1. **Tirage aléatoire reproductible.** Script `echantillon.py` (graine 20261009, `random.Random`, exercices triés par id) :
   - 2 exercices par catégorie, soit 56 × 2 = 112 ;
   - puis 1 exercice pour chaque case discipline × niveau, parmi les exercices non encore tirés (30 cases non vides).
   - On obtient **142 exercices**.
2. **Ajout à la main de 80 cas limites** (marqués « * » au tableau B) : figures statiques complètes et assistées (planche, front lever, back lever, croix), équilibres, muscle-up (strict, kipping, sauté, tenue de transition), tractions et dips assistés à l'élastique, négatifs, mouvements lestés (dips au banc, traction scapulaire, négative supramaximale, dead hang, L-sit), haltérophilie complète (arraché, power snatch, muscle snatch, épaulé-jeté, push jerk, snatch balance, arraché à l'haltère), kettlebell balistique, portés (farmer walk, overhead carry, battle rope), pliométrie haut et bas du corps, sprints (piste, côte, rameur), gainages isométriques, dynamiques et lestés, compression (manna), préhension (pince, dead hang), unilatéraux et machines (Smith, poulie, presse unilatérale), WOD (thruster, wall ball, burpee, kipping).
3. **Total : 222 exercices relus**, toutes les catégories (au moins 2 par catégorie), les 8 disciplines et les 4 niveaux.
4. **Grille de jugement par exercice :**
   - (1) le vecteur : qualités dominantes et proportions ;
   - (2) le type de réponse ;
   - (3) la charge tendineuse et sa zone ;
   - (4) le ratio, pour un pratiquant intermédiaire de 75-80 kg (haltères et kettlebell par main ; lest en charge totale, poids de corps compris).
5. **Verdicts :**
   - **C** = correct ;
   - **m** = acceptable, avec une réserve mineure qui ne fausserait pas la prescription ;
   - **X** = à corriger, c'est-à-dire une erreur qui fausserait l'estimation des qualités, le choix de charge ou la gestion tendineuse.
   - L'artefact de zone « coude » sur les exercices à tendon 0,1 (voir D.6) est un défaut global. Il ne fait pas, à lui seul, descendre le verdict d'un exercice.
6. **Simulation des corrections.** Toutes les corrections de règle proposées en C ont été codées dans une copie (`simulation.py`, qui importe `regles.py` sans le modifier). La simulation a vérifié :
   - les sommes à 1 ;
   - l'absence de valeur négative ;
   - le nombre d'exercices touchés ;
   - l'effet sur l'échantillon et sur des exercices témoins, qui ne doivent pas bouger : développé couché, traction, planche, front lever, burpee, squat.

### A.2 Script d'échantillonnage

```python
import gzip, json, random, collections
BASE='/home/claude/moteurs/packages/kalis_'
cat=json.load(gzip.open(BASE+'core/data/catalog_v1.json.gz','rt'))['exercices']
rng=random.Random(20261009)
par_cat=collections.defaultdict(list)
for e in sorted(cat,key=lambda e:e['id']): par_cat[e['categorie']].append(e)
ech=[]
for k in sorted(par_cat):                                  # 1) 2 par catégorie
    ech += rng.sample(par_cat[k], min(2,len(par_cat[k])))
ids={e['id'] for e in ech}
cases=collections.defaultdict(list)                        # 2) 1 par case discipline x niveau
for e in sorted(cat,key=lambda e:e['id']):
    if e['id'] not in ids: cases[(e['discipline'],e['niveau'])].append(e)
for k in sorted(cases):
    if cases[k]: ech.append(rng.choice(cases[k])); ids.add(ech[-1]['id'])
json.dump([e['id'] for e in ech],open('ech_aleatoire.json','w'),ensure_ascii=False)   # 142 ids
# Cas limites ajoutés à la main (80, ceux déjà tirés sont ignorés) :
MANUELS = """cs-planche cs-planche-lean cs-front-lever cs-front-lever-tuck cs-front-lever-assiste-elastique cs-back-lever
cs-back-lever-tuck cs-iron-cross cs-handstand cs-headstand-tripode cd-handstand-walk cd-muscle-up-barre-kipping
cd-muscle-up-anneaux-strict cd-muscle-up-saute cs-tenue-transition-muscle-up-anneaux sw-traction-assistee-elastique
sw-dips-assistes-elastique sw-traction-pronation sw-traction-negative sw-dips-barres-paralleles
mu-traction-assistee-machine-pronation mu-arrache mu-power-snatch mu-muscle-snatch mu-epaule-jete mu-push-jerk
mu-snatch-balance mu-arrache-haltere-unilateral mu-snatch-kettlebell mu-swing-kettlebell-americain mu-turkish-get-up
mu-farmer-walk mu-overhead-carry mu-battle-rope-ondulations mu-box-jump mu-box-jump-unipodal sw-pistol-squat-saute
cd-dips-explosifs ca-sprint ca-sprint-cote ca-rameur-sprint ca-rameur-endurance mu-hollow-body-hold
mu-gainage-ventral-coudes mu-gainage-ventral-leste mu-planche-commando mu-souleve-de-terre-conventionnel
mu-souleve-de-terre-roumain-unilateral mu-back-squat-barre-basse mu-squat-smith-machine mu-developpe-couche-barre
mu-developpe-couche-smith mu-developpe-militaire-barre-debout mu-presse-cuisses-unilaterale mu-nordic-hamstring-curl
mu-reverse-nordic sl-pistol-squat-leste sw-pistol-squat mu-curl-barre-droite-triche mu-curl-poulie-basse-unilateral
mu-rowing-haltere-unilateral-banc mu-tirage-vertical-unilateral mu-wrist-curl-barre mu-pince-de-prehension sw-dead-hang
sl-dead-hang-leste sl-l-sit-leste cf-thruster-barre cf-wall-ball cf-burpee cf-traction-kipping cf-burpee-leste-gilet
mu-jefferson-curl sl-dips-banc-leste sl-traction-scapulaire-lestee sl-traction-negative-lestee-supramaximale
mu-rotation-externe-elastique mo-dislocations-epaules-elastique sw-pompe-pike cs-manna""".split()
```

### A.3 Composition de l'échantillon (222 exercices)

**Discipline**

| Discipline | échantillon | base |
|---|---|---|
| Calisthénie dynamique | 20 | 110 |
| Calisthénie statique | 26 | 100 |
| Cardio | 18 | 47 |
| CrossFit / WOD | 13 | 54 |
| Mobilité | 17 | 110 |
| Musculation | 96 | 448 |
| Street workout | 20 | 109 |
| Streetlifting | 12 | 61 |

**Niveau**

| Niveau | échantillon | base |
|---|---|---|
| Avancé | 49 | 205 |
| Débutant | 75 | 413 |
| Intermédiaire | 83 | 345 |
| Élite | 15 | 76 |

**Catégorie**

| Catégorie | échantillon | base |
|---|---|---|
| Adducteurs / abducteurs | 2 | 11 |
| Auto-massage | 3 | 11 |
| Avant-bras et préhension | 6 | 20 |
| Balistique kettlebell | 5 | 6 |
| Cardio continu | 3 | 10 |
| Cardio fractionné | 3 | 13 |
| Charnière de hanche | 4 | 17 |
| Compression | 6 | 15 |
| Conditionnement métabolique | 6 | 29 |
| Corde à sauter | 4 | 7 |
| Cou | 2 | 8 |
| Extension de genou | 3 | 6 |
| Extension de hanche | 2 | 13 |
| Extension du rachis | 3 | 7 |
| Fente / unilatéral jambes | 5 | 25 |
| Figure dynamique poussée | 4 | 23 |
| Figure dynamique tirage | 3 | 20 |
| Figure statique mixte | 2 | 7 |
| Figure statique poussée | 5 | 22 |
| Figure statique tirage | 9 | 37 |
| Flexion de genou (ischio-jambiers) | 3 | 10 |
| Flexion de hanche / relevés de jambes | 2 | 10 |
| Flexion du tronc | 2 | 16 |
| Freestyle dynamique | 3 | 14 |
| Gainage anti-extension | 5 | 23 |
| Gainage anti-flexion latérale | 3 | 6 |
| Gainage anti-rotation | 3 | 8 |
| Gymnastique CrossFit | 4 | 11 |
| Haltérophilie | 11 | 25 |
| Isolation biceps | 4 | 22 |
| Isolation dos | 2 | 8 |
| Isolation pectoraux | 2 | 11 |
| Isolation triceps | 2 | 22 |
| Isolation épaules | 3 | 29 |
| Marche et portage | 2 | 5 |
| Mobilité articulaire | 2 | 28 |
| Mollets et cheville | 2 | 8 |
| Mouvement de compétition | 2 | 4 |
| Pliométrie | 6 | 23 |
| Portés et strongman | 5 | 12 |
| Poussée horizontale | 7 | 60 |
| Poussée inclinée | 2 | 10 |
| Poussée verticale | 8 | 57 |
| Préparation scapulaire | 3 | 11 |
| Respiration et récupération | 2 | 4 |
| Rotation du tronc | 2 | 16 |
| Souplesse avancée | 5 | 17 |
| Sprint et vitesse | 6 | 12 |
| Squat / dominante genou | 7 | 45 |
| Tirage horizontal | 4 | 40 |
| Tirage vertical | 9 | 56 |
| Transition / muscle-up | 7 | 28 |
| Élévation scapulaire / trapèzes | 2 | 6 |
| Équilibre sur les mains | 5 | 25 |
| Étirement dynamique | 3 | 9 |
| Étirement statique | 2 | 41 |


---

## B. Exercices relus

Verdict : C = correct ; m = correct, réserve mineure ; X = à corriger. « * » = cas limite ajouté à la main.

| id | catégorie | type | vecteur (≥ 0,1) | tendon/zone | ratio | verdict | commentaire |
|---|---|---|---|---|---|---|---|
| mu-marche-laterale-elastique | Adducteurs / abducteurs | reps | jam 0,70 end 0,30 | 0,4/hanche |  | m | end 0,30 donné à un exercice d'élastique léger [R3 élastique=PDC] |
| mu-adduction-hanche-machine | Adducteurs / abducteurs | charge | jam 1,00 | 0,4/hanche | 0,8 | C |  |
| mo-rouleau-ischio-jambiers | Auto-massage | mobilite | mob 1,00 | 0,1/coude |  | C | zone « coude » artefact [R6 zone] |
| mo-foam-roller-routine | Auto-massage | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mu-reverse-wrist-curl-haltere | Avant-bras et préhension | charge | tir 1,00 | 0,8/poignet | 0,2 | X | ratio 0,20/main (16 kg) ≈ 2× trop pour un reverse wrist curl [R7 défaut préhension] ; tendon 0,8 élevé (champ base) |
| mu-finger-curl-barre | Avant-bras et préhension | charge | tir 1,00 | 0,4/poignet | 0,5 | C |  |
| mu-clean-kettlebell | Balistique kettlebell | charge | tir 0,13 jam 0,22 exp 0,40 ana 0,20 | 0,4/epaule | 0,2 | X | ratio 0,20/main (16 kg) trop bas, épaulé KB intermédiaire ≈ 24 kg [R7 balistique absent] |
| mu-swing-kettlebell-russe | Balistique kettlebell | charge | jam 0,30 exp 0,40 ana 0,20 | 0,4/epaule | 0,2 | X | ratio 0,20 (défaut) trop bas (swing courant 24-32 kg) ; zone épaule plutôt que lombaires/hanche [R7, R6 ordre zones] |
| ca-sortie-longue | Cardio continu | cardio | aer 1,00 | 0,4/genou |  | C |  |
| ca-footing-endurance-fondamentale | Cardio continu | cardio | aer 1,00 | 0,4/genou |  | C |  |
| ca-cotes-longues | Cardio fractionné | cardio | aer 0,45 ana 0,55 | 0,4/genou |  | C |  |
| ca-fractionne-long-1000m | Cardio fractionné | cardio | aer 0,45 ana 0,55 | 0,4/genou |  | C |  |
| mu-souleve-de-terre-kettlebell-unijambiste | Charnière de hanche | charge | jam 0,86 tro 0,14 | 0,4/hanche | 0,45 | m | ratio 0,45/main un peu haut en unilatéral |
| mu-windmill-kettlebell | Charnière de hanche | charge | jam 0,42 tro 0,58 | 0,4/hanche | 0,45 | X | ratio 0,45/main (36 kg) ≈ 2× trop : le windmill n'est pas une charnière lourde [R7 schéma] ; pousser absent (champ base) |
| cs-l-sit-sol | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | mob 0,30 excessive, figures 0,20 faible, muscles ignorés [R2 compression] |
| cs-l-sit-barres-paralleles | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | idem L-sit [R2 compression] |
| cf-epaule-medecine-ball | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,4/epaule |  | C |  |
| cf-burpee-tuck-jump | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,8/genou |  | C |  |
| ca-corde-pas-alternes | Corde à sauter | cardio | exp 0,20 aer 0,50 ana 0,30 | 0,8/cheville |  | C |  |
| ca-corde-unipodale | Corde à sauter | cardio | exp 0,20 aer 0,50 ana 0,30 | 0,8/cheville |  | C |  |
| mu-extension-cou-harnais | Cou | charge | tir 0,50 tro 0,50 | 0,1/coude | 0,5 | X | ratio 0,50 (40 kg) ≈ 2× trop ; colonne « barre » utilisée pour type_charge autre [R7] |
| mu-isometries-cou-elastique | Cou | tenue | tir 0,25 tro 0,75 | 0,1/coude |  | C | zone « coude » artefact [R6 zone] |
| sw-sissy-squat | Extension de genou | reps | jam 0,90 end 0,10 | 0,8/genou |  | C |  |
| mu-terminal-knee-extension | Extension de genou | reps | jam 0,70 end 0,30 | 0,4/genou |  | m | end 0,30 pour un exercice de rééducation à l’élastique [R3] |
| mu-hyperextension-90-fessiers | Extension de hanche | reps | jam 0,80 end 0,20 | 0,4/hanche |  | C |  |
| mu-hip-thrust-smith | Extension de hanche | charge | jam 1,00 | 0,4/hanche | 0,8 | X | ratio 0,80 (colonne machine) ; une Smith est une barre guidée ≈ 1,4 [R7 Smith] |
| mu-hyperextension-45-dos | Extension du rachis | reps | tro 0,80 end 0,12 | 0,4/lombaires |  | C |  |
| mu-superman | Extension du rachis | reps | tro 0,78 end 0,12 | 0,4/lombaires |  | C |  |
| mu-fente-arriere-poids-du-corps | Fente / unilatéral jambes | reps | jam 0,79 end 0,21 | 0,4/genou |  | C |  |
| mu-split-squat-bulgare-poids-du-corps | Fente / unilatéral jambes | reps | jam 0,79 end 0,21 | 0,4/genou |  | C |  |
| cd-press-handstand-straddle | Figure dynamique poussée | reps | pou 0,23 tir 0,12 tro 0,12 fig 0,35 exp 0,15 | 0,8/coude |  | X | exp 0,15 sur un mouvement lent de force [R2 figure_dynamique] |
| cd-planche-pushup-tuck-parallettes | Figure dynamique poussée | reps | pou 0,46 fig 0,35 exp 0,15 | 0,8/coude |  | m | exp 0,15 superflue [R2 figure_dynamique] |
| cd-ice-cream-maker | Figure dynamique tirage | reps | tir 0,42 fig 0,35 exp 0,15 | 0,8/coude |  | X | exp 0,15 sur un mouvement lent [R2 figure_dynamique] |
| cd-traction-un-bras-assistee-serviette | Figure dynamique tirage | reps | tir 0,45 fig 0,35 exp 0,15 | 0,8/coude |  | m | exp 0,15 discutable ; tendon non réduit par l’assistance [R2, R6] |
| cs-drapeau-tuck | Figure statique mixte | tenue | pou 0,12 tir 0,15 tro 0,18 fig 0,55 | 1,0/epaule |  | C |  |
| cs-drapeau-straddle | Figure statique mixte | tenue | pou 0,11 tir 0,14 tro 0,17 fig 0,55 | 1,0/epaule |  | C |  |
| cs-planche-half-lay | Figure statique poussée | tenue | pou 0,41 fig 0,55 | 1,0/coude |  | C |  |
| cs-maltese-lean | Figure statique poussée | tenue | pou 0,40 fig 0,55 | 1,0/coude |  | C |  |
| cs-tenue-haute-false-grip-anneaux | Figure statique tirage | tenue | tir 0,42 fig 0,55 | 1,0/coude |  | X | tendon 1,0 via le bonus « bras tendus » alors que la tenue est bras fléchis [R6] |
| cs-iron-cross-pieds-au-sol | Figure statique tirage | tenue | pou 0,22 tir 0,23 fig 0,55 | 1,0/coude |  | X | tendon 1,0 malgré l’assistance des pieds [R6 assisté] |
| mu-curl-ischio-glisse | Flexion de genou (ischio-jambiers) | reps | jam 0,77 end 0,23 | 0,4/genou |  | C |  |
| mu-glute-ham-raise | Flexion de genou (ischio-jambiers) | reps | jam 0,90 end 0,10 | 0,4/genou |  | m | tendon 0,4 un peu bas pour un excentrique ischio (champ base) |
| sw-releve-jambes-tendues-suspendu | Flexion de hanche / relevés de jambes | reps | jam 0,15 tro 0,77 | 0,4/epaule |  | C |  |
| sw-toes-to-bar | Flexion de hanche / relevés de jambes | reps | jam 0,11 tro 0,78 | 0,4/epaule |  | C |  |
| mu-sit-up | Flexion du tronc | reps | tro 0,81 end 0,12 | 0,4/hanche |  | C |  |
| mu-crunch-oblique-poulie | Flexion du tronc | charge | tro 1,00 | 0,4/hanche | 0,4 | C |  |
| cd-swing-changement-prise | Freestyle dynamique | reps | fig 0,50 exp 0,30 | 0,8/coude |  | C |  |
| cd-swing-360 | Freestyle dynamique | reps | tro 0,11 fig 0,50 exp 0,30 | 0,8/coude |  | C |  |
| sw-dragon-flag-straddle | Gainage anti-extension | reps | tir 0,11 tro 0,82 | 0,8/lombaires |  | C |  |
| mu-dead-bug-jambes-tendues | Gainage anti-extension | reps | tro 0,87 | 0,4/epaule |  | C |  |
| mu-gainage-lateral-genoux | Gainage anti-flexion latérale | tenue | tro 0,84 end 0,12 | 0,4/epaule |  | C |  |
| mu-gainage-lateral-abduction | Gainage anti-flexion latérale | reps | jam 0,11 tro 0,80 | 0,4/epaule |  | C |  |
| mu-around-the-world-kettlebell | Gainage anti-rotation | charge | tro 0,96 | 0,4/lombaires | 0,2 | m | ratio 0,20 défaut, peu signifiant |
| mu-bird-dog | Gainage anti-rotation | reps | tro 0,72 end 0,12 | 0,4/lombaires |  | C |  |
| cf-traction-butterfly | Gymnastique CrossFit | wod | tir 0,36 fig 0,30 end 0,20 | 0,8/epaule |  | X | type wod au lieu de reps ; figures 0,30 surévaluées [R5, R2 gymnastique_crossfit] |
| cf-burpee-muscle-up-barre | Gymnastique CrossFit | wod | pou 0,18 tir 0,18 jam 0,11 fig 0,30 end 0,20 | 0,8/epaule |  | m | figures 0,30 un peu haut [R2] |
| mu-high-pull | Haltérophilie | charge | tir 0,17 jam 0,24 exp 0,50 | 0,8/epaule | 0,85 | C |  |
| mu-muscle-clean | Haltérophilie | charge | tir 0,18 jam 0,21 exp 0,50 | 0,8/epaule | 0,85 | X | ratio 0,85 = épaulé ; un muscle clean vaut ≈ 70 % de l’épaulé [R7 haltérophilie] |
| mu-curl-pupitre-barre-ez | Isolation biceps | charge | tir 1,00 | 0,4/coude | 0,45 | C |  |
| mu-spider-curl-halteres | Isolation biceps | charge | tir 1,00 | 0,4/coude | 0,2 | C |  |
| mu-pull-over-poulie-allonge | Isolation dos | charge | pou 0,40 tir 0,60 | 0,4/epaule | 0,4 | C |  |
| mu-pull-over-barre-ez | Isolation dos | charge | pou 0,50 tir 0,50 | 0,4/epaule | 0,5 | C |  |
| mu-pec-deck | Isolation pectoraux | charge | pou 1,00 | 0,4/epaule | 0,6 | C |  |
| mu-ecarte-poulie-haut-vers-bas | Isolation pectoraux | charge | pou 0,90 tir 0,10 | 0,4/epaule | 0,25 | C |  |
| mu-tate-press | Isolation triceps | charge | pou 1,00 | 0,8/coude | 0,15 | C |  |
| mu-pushdown-elastique | Isolation triceps | reps | pou 0,79 end 0,21 | 0,4/coude |  | m | end 0,21 pour un élastique [R3] |
| mu-oiseau-poulie-croisee | Isolation épaules | charge | pou 0,17 tir 0,83 | 0,4/epaule | 0,12 | C |  |
| mu-elevation-laterale-partielle | Isolation épaules | charge | pou 0,72 tir 0,28 | 0,4/epaule | 0,12 | m | coiffe → tirer donne 0,28 tirer à une élévation latérale [R1 coiffe] |
| ca-marche-lestee-denivele | Marche et portage | cardio | aer 1,00 | 0,4/genou |  | C |  |
| ca-marche-rapide | Marche et portage | cardio | aer 1,00 | 0,1/coude |  | C |  |
| mo-table-inversee | Mobilité articulaire | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mo-shin-box-releve | Mobilité articulaire | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mu-mollets-donkey | Mollets et cheville | charge | jam 1,00 | 0,4/cheville | 1,5 | C |  |
| mu-tibial-raise | Mollets et cheville | reps | jam 0,70 end 0,30 | 0,4/cheville |  | C |  |
| sl-dips-leste | Mouvement de compétition | charge | pou 1,00 | 0,9/coude | 1,55 | C | ratio 1,55 un peu haut (1,45 plausible) |
| sl-traction-lestee | Mouvement de compétition | charge | pou 0,15 tir 0,85 | 0,9/coude | 1,4 | m | pousser 0,15 : pectoraux comptés « pousser » dans un tirage [R1] |
| mu-lancer-arriere-medecine-ball | Pliométrie | charge | jam 0,21 exp 0,70 | 0,7/coude | 0,5 | X | type charge + ratio 0,5 sans objet pour un lancer ; plancher tendon 0,7 zone coude [R5, R6 sauts] |
| mu-depth-jump | Pliométrie | reps | jam 0,30 exp 0,70 | 0,8/genou |  | C |  |
| mu-sac-leste-sur-epaule | Portés et strongman | charge | tir 0,25 jam 0,34 tro 0,18 ana 0,20 | 0,4/epaule | 0,5 | m | explosivité absente (extension triple) |
| mu-tirage-traineau-corde | Portés et strongman | autre | tir 0,80 ana 0,20 | 0,4/epaule |  | C |  |
| cd-pompe-un-bras-surelevee | Poussée horizontale | reps | pou 0,83 end 0,17 | 0,8/coude |  | C |  |
| mu-developpe-couche-halteres | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 0,38 | C |  |
| mu-developpe-landmine-debout | Poussée inclinée | charge | pou 0,88 tir 0,12 | 0,4/coude | 0,9 | X | ratio 0,90 (barre bilatérale) pour un unilatéral [R7 unilatéral] |
| sw-pompe-dive-bomber | Poussée inclinée | reps | pou 0,65 end 0,20 | 0,4/coude |  | C |  |
| cd-hspu-libre | Poussée verticale | reps | pou 0,74 tir 0,16 end 0,10 | 0,8/epaule |  | X | figures 0 alors que l’équilibre limite la performance [R2 poussée verticale PDC] |
| cd-hspu-libre-negatif | Poussée verticale | reps | pou 0,79 tir 0,11 end 0,10 | 0,9/epaule |  | X | idem HSPU libre [R2] |
| sw-traction-scapulaire | Préparation scapulaire | reps | tir 0,61 end 0,30 | 0,1/coude |  | m | end 0,30 pour un exercice d’activation [R3] |
| mu-halo-kettlebell | Préparation scapulaire | charge | pou 0,55 tir 0,45 | 0,1/coude | 0,2 | m | mobilité absente pour un exercice de mobilité d’épaule (champ base) |
| mo-soupir-physiologique | Respiration et récupération | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mo-coherence-cardiaque | Respiration et récupération | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| sw-releve-genoux-oblique | Rotation du tronc | reps | tro 0,88 | 0,4/lombaires |  | C |  |
| mu-bicycle-crunch | Rotation du tronc | reps | tro 0,84 end 0,12 | 0,4/lombaires |  | C |  |
| mo-grand-ecart-antero-blocs | Souplesse avancée | mobilite | mob 1,00 | 0,8/hanche |  | m | tendon 0,8 sur un étirement passif [R6 passif] |
| mo-pont-depuis-debout | Souplesse avancée | mobilite | mob 1,00 | 0,8/lombaires |  | C |  |
| ca-sprints-repetes | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,8/cheville |  | C |  |
| ca-educatif-pas-chasses | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,8/cheville |  | X | éducatif cyclique traité en sprint (exp 0,4, tendon 0,8) [R2/R6 sprint sans régime ; champ base] |
| mu-squat-talons-sureleves | Squat / dominante genou | charge | jam 0,97 | 0,4/genou | 1,4 | C |  |
| mu-spanish-squat-elastique | Squat / dominante genou | reps | jam 0,70 end 0,30 | 0,4/genou |  | m | end 0,30 [R3 élastique] |
| mu-rowing-poulie-assis-unilateral | Tirage horizontal | charge | tir 1,00 | 0,4/coude | 0,8 | X | ratio 0,80 (bilatéral) pour un unilatéral [R7 unilatéral] |
| mu-rowing-inverse-smith-pieds-sureleves | Tirage horizontal | reps | tir 0,77 end 0,23 | 0,4/coude |  | C |  |
| mu-tirage-vertical-unilateral-demi-agenouille | Tirage vertical | charge | tir 1,00 | 0,4/coude | 0,9 | X | ratio 0,90 = 72 kg à un bras [R7 unilatéral] |
| sl-traction-isometrie-lestee-haute | Tirage vertical | tenue | tir 0,95 | 0,9/coude |  | C |  |
| cd-muscle-up-barre-lent | Transition / muscle-up | reps | pou 0,29 tir 0,31 fig 0,15 exp 0,25 | 0,8/coude |  | X | exp 0,25 sur un muscle-up lent ; pousser ≈ tirer alors que la traction haute domine [R2 transition, R1] |
| cd-transition-muscle-up-box | Transition / muscle-up | reps | pou 0,36 tir 0,24 fig 0,15 exp 0,25 | 0,8/coude |  | X | exp 0,25 sur un éducatif lent [R2 transition] |
| mu-shrug-smith | Élévation scapulaire / trapèzes | charge | tir 1,00 | 0,1/coude | 0,8 | X | ratio 0,80 trop bas (shrug ≈ 1,3-1,5) [R7 trapèzes + Smith] |
| mu-shrug-trap-bar | Élévation scapulaire / trapèzes | charge | tir 1,00 | 0,1/coude | 1,0 | X | ratio 1,0 trop bas [R7 trapèzes] |
| cs-crane | Équilibre sur les mains | tenue | pou 0,25 tro 0,11 fig 0,60 | 0,8/epaule |  | m | zone épaule ; le poignet est la zone attendue [R6 ordre zones] |
| cs-handstand-poids-decale | Équilibre sur les mains | tenue | pou 0,25 tir 0,10 fig 0,60 | 0,8/coude |  | m | zone coude ; poignet attendu [R6 ordre zones] |
| mo-good-morning-baton | Étirement dynamique | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mo-adducteurs-rocking | Étirement dynamique | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mo-etirement-bas-dips-barres | Étirement statique | mobilite | mob 1,00 | 0,1/coude |  | m | tendon 0,1 bas : étirement en charge sur l’épaule antérieure (champ base) |
| mo-appui-dos-des-mains | Étirement statique | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| cd-press-handstand-tuck | Figure dynamique poussée | reps | pou 0,27 tir 0,12 fig 0,35 exp 0,15 | 0,8/coude |  | X | exp 0,15 sur un mouvement lent [R2] |
| cd-skin-the-cat-groupe | Figure dynamique tirage | reps | pou 0,17 tir 0,17 tro 0,15 fig 0,35 exp 0,15 | 0,8/coude |  | m | exp 0,15 ; mobilité d’épaule absente [R2] |
| cd-press-handstand-straddle-negatif | Figure dynamique poussée | reps | pou 0,22 tir 0,12 tro 0,12 fig 0,35 exp 0,15 | 0,9/coude |  | X | exp 0,15 en excentrique [R2] |
| cd-muscle-up-360 | Freestyle dynamique | reps | fig 0,50 exp 0,30 | 0,8/coude |  | C |  |
| cs-v-sit | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | figures 0,20 trop bas pour une figure avancée [R2 compression] |
| cs-l-sit-tuck | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | mob 0,30 sans exigence de souplesse [R2 compression] |
| cs-suspension-un-bras | Figure statique tirage | tenue | tir 0,45 fig 0,55 | 1,0/coude |  | X | figures 0,55 pour une suspension (préhension) ; zone coude plutôt que poignet/doigts (champ base : schéma figure_statique_tirage) |
| cs-planche-parallettes | Figure statique poussée | tenue | pou 0,41 fig 0,55 | 1,0/coude |  | C |  |
| ca-air-bike-sprints | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,7/genou |  | X | plancher tendon 0,7 sur un ergomètre sans impact [R6 sauts] |
| ca-corde-sauts-simples | Corde à sauter | cardio | exp 0,20 aer 0,50 ana 0,30 | 0,8/cheville |  | C |  |
| ca-velo-intervalles | Cardio fractionné | cardio | aer 0,45 ana 0,55 | 0,4/genou |  | C |  |
| ca-corde-triple-unders | Corde à sauter | cardio | exp 0,20 aer 0,50 ana 0,30 | 0,8/cheville |  | m | même vecteur que les sauts simples (pas de modulation par niveau) |
| cf-cluster | Haltérophilie | charge | pou 0,18 jam 0,29 exp 0,50 | 0,8/epaule | 0,85 | m | ratio 0,85 un peu haut (limité par le thruster) |
| cf-sdhp-kettlebell | Balistique kettlebell | charge | tir 0,11 jam 0,22 exp 0,40 ana 0,20 | 0,4/epaule | 0,2 | m | ratio 0,20 défaut |
| cf-fente-overhead-haltere | Fente / unilatéral jambes | autre | jam 1,00 | 0,8/epaule |  | X | jambes 1,00 : pousser/tronc absents (champ base muscles) ; type autre (distance) |
| cf-hspu-kipping-deficit | Gymnastique CrossFit | wod | pou 0,33 jam 0,13 fig 0,30 end 0,20 | 0,8/epaule |  | m | type wod discutable [R5] |
| mo-pike-assis-actif | Souplesse avancée | mobilite | mob 1,00 | 0,4/hanche |  | C |  |
| mo-rouleau-grand-dorsal | Auto-massage | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| mo-pike-assis-passif | Souplesse avancée | mobilite | mob 1,00 | 0,4/hanche |  | C |  |
| mo-pancake-a-plat | Souplesse avancée | mobilite | mob 1,00 | 0,8/hanche |  | m | tendon 0,8 sur un étirement passif [R6 passif] |
| mu-epaule | Haltérophilie | charge | tir 0,10 jam 0,33 exp 0,50 | 0,8/epaule | 0,85 | C |  |
| mu-presse-cuisses-pieds-hauts | Squat / dominante genou | charge | jam 1,00 | 0,4/genou | 2,2 | C |  |
| mu-developpe-couche-prise-serree | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 1,05 | C |  |
| sw-dips-anneaux | Poussée verticale | reps | pou 0,80 end 0,13 | 0,8/epaule |  | C |  |
| sw-row-australien-barres-paralleles | Tirage horizontal | reps | tir 0,70 end 0,30 | 0,4/coude |  | C |  |
| sw-traction-commando | Tirage vertical | reps | tir 0,78 end 0,20 | 0,4/coude |  | C |  |
| sw-dragon-squat | Squat / dominante genou | reps | jam 0,87 end 0,10 | 0,8/genou |  | C |  |
| sl-pompe-lestee-deficit-parallettes | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 1,15 | C |  |
| sl-pompe-lestee-disque-dos | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 1,15 | C |  |
| sl-muscle-up-leste-pause-transition | Transition / muscle-up | charge | pou 0,35 tir 0,25 fig 0,15 exp 0,25 | 0,9/coude | 1,15 | m | exp 0,25 avec pause [R2 transition] |
| cs-planche * | Figure statique poussée | tenue | pou 0,41 fig 0,55 | 1,0/coude |  | C |  |
| cs-planche-lean * | Figure statique poussée | tenue | pou 0,40 fig 0,55 | 1,0/coude |  | X | tendon 1,0 pour un éducatif débutant [R6 sans modulation par niveau] |
| cs-front-lever * | Figure statique tirage | tenue | tir 0,37 fig 0,55 | 1,0/coude |  | C |  |
| cs-front-lever-tuck * | Figure statique tirage | tenue | tir 0,36 fig 0,55 | 1,0/coude |  | m | tendon 1,0 au niveau intermédiaire [R6 niveau] |
| cs-front-lever-assiste-elastique * | Figure statique tirage | tenue | tir 0,36 fig 0,55 | 1,0/coude |  | X | tendon 1,0 malgré l’élastique [R6 assisté] |
| cs-back-lever * | Figure statique tirage | tenue | pou 0,27 tir 0,18 fig 0,55 | 1,0/coude |  | C |  |
| cs-back-lever-tuck * | Figure statique tirage | tenue | pou 0,29 tir 0,16 fig 0,55 | 1,0/coude |  | m | tendon 1,0 au niveau intermédiaire [R6 niveau] |
| cs-iron-cross * | Figure statique tirage | tenue | pou 0,20 tir 0,25 fig 0,55 | 1,0/coude |  | C |  |
| cs-handstand * | Équilibre sur les mains | tenue | pou 0,29 tir 0,11 fig 0,60 | 0,8/epaule |  | m | tendon 0,8 zone épaule ; poignet attendu, 0,6 suffit [R6] |
| cs-headstand-tripode * | Équilibre sur les mains | tenue | pou 0,36 fig 0,60 | 0,8/epaule |  | X | tendon 0,8 épaule pour un équilibre débutant sur la tête (champ base contraintes) |
| cd-handstand-walk * | Équilibre sur les mains | autre | pou 0,32 fig 0,60 | 0,8/epaule |  | m | type autre (distance) |
| cd-muscle-up-barre-kipping * | Transition / muscle-up | reps | pou 0,26 tir 0,24 fig 0,15 exp 0,25 | 0,8/coude |  | C |  |
| cd-muscle-up-anneaux-strict * | Transition / muscle-up | reps | pou 0,30 tir 0,30 fig 0,15 exp 0,25 | 0,8/coude |  | m | exp 0,25 sur un strict ; pousser = tirer [R2, R1] |
| cd-muscle-up-saute * | Transition / muscle-up | reps | pou 0,28 tir 0,22 fig 0,15 exp 0,25 | 0,8/coude |  | C |  |
| cs-tenue-transition-muscle-up-anneaux * | Transition / muscle-up | tenue | pou 0,50 tir 0,10 fig 0,15 exp 0,25 | 0,8/coude |  | X | exp 0,25 sur une isométrie [R2 transition] |
| sw-traction-assistee-elastique * | Tirage vertical | reps | tir 0,71 end 0,27 | 0,4/coude |  | C |  |
| sw-dips-assistes-elastique * | Poussée verticale | reps | pou 0,71 end 0,27 | 0,8/epaule |  | m | tendon 0,8 identique aux dips libres [R6 assisté] |
| sw-traction-pronation * | Tirage vertical | reps | tir 0,73 end 0,20 | 0,4/coude |  | C |  |
| sw-traction-negative * | Tirage vertical | reps | tir 0,71 end 0,27 | 0,5/coude |  | C |  |
| sw-dips-barres-paralleles * | Poussée verticale | reps | pou 0,74 end 0,20 | 0,8/epaule |  | C |  |
| mu-traction-assistee-machine-pronation * | Tirage vertical | reps | tir 1,00 | 0,4/coude |  | C |  |
| mu-arrache * | Haltérophilie | charge | jam 0,29 exp 0,50 | 0,8/epaule | 0,85 | m | ratio 0,85 un peu haut (≈ 0,75-0,8) |
| mu-power-snatch * | Haltérophilie | charge | jam 0,29 exp 0,50 | 0,8/epaule | 0,85 | X | ratio 0,85 > arraché ; power snatch ≈ 0,65 [R7 haltérophilie] |
| mu-muscle-snatch * | Haltérophilie | charge | pou 0,12 tir 0,14 jam 0,20 exp 0,50 | 0,8/epaule | 0,85 | X | ratio 0,85 ; muscle snatch ≈ 0,5 [R7 haltérophilie] |
| mu-epaule-jete * | Haltérophilie | charge | pou 0,12 jam 0,29 exp 0,50 | 0,8/epaule | 0,85 | C |  |
| mu-push-jerk * | Haltérophilie | charge | pou 0,22 jam 0,23 exp 0,50 | 0,8/epaule | 0,85 | m | ratio 0,85 un peu bas (≈ 0,95) |
| mu-snatch-balance * | Haltérophilie | charge | pou 0,15 jam 0,28 exp 0,50 | 0,8/epaule | 0,85 | C |  |
| mu-arrache-haltere-unilateral * | Haltérophilie | charge | pou 0,10 jam 0,29 exp 0,50 | 0,8/epaule | 0,3 | C |  |
| mu-snatch-kettlebell * | Balistique kettlebell | charge | jam 0,20 exp 0,40 ana 0,20 | 0,4/epaule | 0,2 | m | ratio 0,20 défaut (≈ 0,30) [R7 balistique] |
| mu-swing-kettlebell-americain * | Balistique kettlebell | charge | jam 0,28 exp 0,40 ana 0,20 | 0,4/epaule | 0,2 | m | ratio 0,20 défaut [R7 balistique] |
| mu-turkish-get-up * | Gainage anti-flexion latérale | charge | jam 0,18 tro 0,75 | 0,4/epaule | 0,2 | C |  |
| mu-farmer-walk * | Portés et strongman | autre | tir 0,51 jam 0,17 tro 0,11 ana 0,20 | 0,4/epaule |  | m | type autre : la charge portée n’est pas modélisée [R5] |
| mu-overhead-carry * | Portés et strongman | autre | pou 0,40 tir 0,23 tro 0,17 ana 0,20 | 0,8/epaule |  | m | type autre [R5] |
| mu-battle-rope-ondulations * | Portés et strongman | tenue | pou 0,29 tir 0,51 ana 0,20 | 0,4/epaule |  | X | type tenue (secondes) pour un effort dynamique ; anaérobie 0,20 seulement [R5 ; champ base catégorie] |
| mu-box-jump * | Pliométrie | reps | jam 0,28 exp 0,70 | 0,8/genou |  | C |  |
| mu-box-jump-unipodal * | Pliométrie | reps | jam 0,27 exp 0,70 | 0,8/genou |  | C |  |
| sw-pistol-squat-saute * | Pliométrie | reps | jam 0,28 exp 0,70 | 0,8/genou |  | C |  |
| cd-dips-explosifs * | Pliométrie | reps | pou 0,27 exp 0,70 | 0,8/poignet |  | C |  |
| ca-sprint * | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,8/cheville |  | C |  |
| ca-sprint-cote * | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,8/cheville |  | C |  |
| ca-rameur-sprint * | Sprint et vitesse | cardio | jam 0,20 exp 0,40 ana 0,40 | 0,7/genou |  | X | plancher tendon 0,7 genou sur rameur ; jambes 0,20 fixe et tirage ignoré [R6, R2 sprint] |
| ca-rameur-endurance * | Cardio continu | cardio | aer 1,00 | 0,4/genou |  | C |  |
| mu-hollow-body-hold * | Gainage anti-extension | tenue | tro 0,84 end 0,12 | 0,4/epaule |  | C |  |
| mu-gainage-ventral-coudes * | Gainage anti-extension | tenue | tro 0,88 end 0,12 | 0,4/epaule |  | C |  |
| mu-gainage-ventral-leste * | Gainage anti-extension | tenue | tro 0,96 | 0,4/epaule |  | C |  |
| mu-planche-commando * | Gainage anti-rotation | reps | pou 0,12 tro 0,80 | 0,4/lombaires |  | C |  |
| mu-souleve-de-terre-conventionnel * | Charnière de hanche | charge | jam 0,70 tro 0,30 | 0,8/lombaires | 1,7 | X | tirer 0 : dorsaux, trapèzes et préhension (stabilisateurs) ignorés [R1] |
| mu-souleve-de-terre-roumain-unilateral * | Charnière de hanche | charge | jam 0,85 tro 0,15 | 0,4/hanche | 0,45 | C |  |
| mu-back-squat-barre-basse * | Squat / dominante genou | charge | jam 0,89 tro 0,11 | 0,4/genou | 1,4 | C |  |
| mu-squat-smith-machine * | Squat / dominante genou | charge | jam 0,97 | 0,4/genou | 2,2 | X | ratio 2,2 (colonne presse) pour un squat Smith ≈ 1,3 [R7 Smith] |
| mu-developpe-couche-barre * | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 1,05 | C |  |
| mu-developpe-couche-smith * | Poussée horizontale | charge | pou 1,00 | 0,4/coude | 0,9 | C |  |
| mu-developpe-militaire-barre-debout * | Poussée verticale | charge | pou 0,80 tir 0,20 | 0,8/epaule | 0,68 | C |  |
| mu-presse-cuisses-unilaterale * | Fente / unilatéral jambes | charge | jam 1,00 | 0,4/genou | 0,8 | m | ratio 0,80 bas (≈ 1,1 = moitié de 2,2) |
| mu-nordic-hamstring-curl * | Flexion de genou (ischio-jambiers) | reps | jam 0,90 end 0,10 | 0,4/genou |  | X | tendon 0,4 : excentrique ischio majeur (champ base : régime dynamique, genou moyenne) |
| mu-reverse-nordic * | Extension de genou | reps | jam 0,80 end 0,20 | 0,8/genou |  | C |  |
| sl-pistol-squat-leste * | Fente / unilatéral jambes | charge | jam 1,00 | 0,8/genou | 1,25 | C |  |
| sw-pistol-squat * | Squat / dominante genou | reps | jam 0,81 end 0,10 | 0,8/genou |  | C |  |
| mu-curl-barre-droite-triche * | Isolation biceps | charge | tir 0,69 jam 0,16 | 0,4/coude | 0,45 | C |  |
| mu-curl-poulie-basse-unilateral * | Isolation biceps | charge | tir 1,00 | 0,4/coude | 0,35 | X | ratio 0,35 = celui de la barre à deux mains [R7 unilatéral] |
| mu-rowing-haltere-unilateral-banc * | Tirage horizontal | charge | tir 1,00 | 0,4/coude | 0,42 | C |  |
| mu-tirage-vertical-unilateral * | Tirage vertical | charge | tir 1,00 | 0,4/coude | 0,9 | X | ratio 0,90 à un bras [R7 unilatéral] |
| mu-wrist-curl-barre * | Avant-bras et préhension | charge | tir 1,00 | 0,8/poignet | 0,5 | m | tendon 0,8 poignet élevé (champ base) |
| mu-pince-de-prehension * | Avant-bras et préhension | charge | tir 1,00 | 0,4/poignet | 0,5 | X | type charge + ratio 0,5 sans objet (pince graduée) [R5/R7 autre] |
| sw-dead-hang * | Avant-bras et préhension | tenue | tir 1,00 | 0,4/poignet |  | C |  |
| sl-dead-hang-leste * | Avant-bras et préhension | tenue | tir 1,00 | 0,4/poignet |  | C |  |
| sl-l-sit-leste * | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | compression : mob 0,30 [R2] |
| cf-thruster-barre * | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,4/epaule |  | m | wod sans ratio : la charge n’est pas modélisée |
| cf-wall-ball * | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,4/epaule |  | C |  |
| cf-burpee * | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,4/epaule |  | C |  |
| cf-traction-kipping * | Gymnastique CrossFit | wod | tir 0,38 fig 0,30 end 0,20 | 0,8/epaule |  | X | type wod, figures 0,30 [R5, R2 gymnastique_crossfit] |
| cf-burpee-leste-gilet * | Conditionnement métabolique | wod | end 0,25 aer 0,25 ana 0,50 | 0,4/epaule |  | C |  |
| mu-jefferson-curl * | Extension du rachis | charge | jam 0,11 tro 0,89 | 0,8/lombaires | 0,5 | X | ratio 0,50 trop haut (exercice léger, ≈ 0,25) ; mobilité absente (champ base schéma) |
| sl-dips-banc-leste * | Poussée verticale | charge | pou 1,00 | 0,9/coude | 1,55 | X | ratio 1,55 avec fraction 0,5 → lest implicite 84 kg [R7 lest sans fraction] |
| sl-traction-scapulaire-lestee * | Préparation scapulaire | charge | pou 0,14 tir 0,86 | 0,1/coude | 1,2 | X | ratio 1,2 (défaut) < traction lestée ; tendon 0,1 [R7, R6] |
| sl-traction-negative-lestee-supramaximale * | Tirage vertical | charge | pou 0,15 tir 0,85 | 1,0/coude | 1,4 | m | ratio non majoré pour l’excentrique supramaximal [R7] |
| mu-rotation-externe-elastique * | Isolation épaules | reps | tir 0,79 end 0,21 | 0,4/epaule |  | m | end 0,21 [R3 élastique] |
| mo-dislocations-epaules-elastique * | Étirement dynamique | mobilite | mob 1,00 | 0,1/coude |  | C |  |
| sw-pompe-pike * | Poussée verticale | reps | pou 0,65 tir 0,15 end 0,20 | 0,8/epaule |  | C |  |
| cs-manna * | Compression | tenue | tro 0,50 fig 0,20 mob 0,30 | 0,4/coude |  | X | figure élite classée tronc 0,50 / figures 0,20 [R2 compression] |

Total : 222 exercices ; C = 127, m = 43, X = 52.
Tirage aléatoire seul (142) : C = 84, m = 26, X = 32. Cas limites ajoutés (80) : C = 43, m = 17, X = 20.

---

## C. Constats regroupés par règle et corrections proposées

Pour chaque défaut ci-dessous : la correction, puis l'effet mesuré par `simulation.py` (annexe 3) sur les 1 039 exercices. Les exercices témoins restent inchangés : développé couché barre et haltères, planche, front lever, burpee, back squat ; la traction pronation passe de tirer 0,73 à 0,80. Aucune correction n'est faite exercice par exercice. Les champs de la base qui semblent faux sont listés à part, en C.8.

### C.1 R1 : muscle → qualité

**R1-a. Pectoraux et chef long du triceps comptés « pousser » dans les tirages.**
- **Défaut.**
  - La traction lestée vaut pousser 0,15 / tirer 0,85.
  - 14 tractions (lestées ou explosives) ont pousser ≥ 0,10 ; c'est 0,23 pour la traction explosive hauteur hanches.
  - Le pull-over à l'haltère vaut pousser 0,67, et la catégorie « Isolation dos » a pousser pour qualité dominante dans 2 cas sur 8.
- **Correction.** Nouvelle table contextuelle. Dans les schémas `tirage_vertical`, `tirage_horizontal`, `isolation_dos` et `preparation_scapulaire`, les muscles suivants comptent pour **tirer** :
  - `grand pectoral (faisceau sternal)` ;
  - `grand pectoral (faisceau abdominal)` ;
  - `petit pectoral` ;
  - `triceps brachial (chef long)`.
- **Justification.**
  - Depuis une épaule fléchie, le faisceau sterno-costal du grand pectoral et le chef long du triceps sont extenseurs et adducteurs de l'épaule : ils agissent en synergie avec le grand dorsal (anatomie fonctionnelle classique, par exemple Neumann, *Kinesiology of the Musculoskeletal System*, chapitre épaule).
  - Le petit pectoral abaisse la scapula.
  - La règle ne s'applique **pas** aux figures : dans le back lever, le pectoral travaille en fléchisseur contre l'hyperextension, et « pousser » y est juste.
  - Elle ne s'applique pas non plus au muscle-up, dont la phase de dips est réelle (ce cas est traité en R2-c).
- **Exercices corrigés.** sl-traction-lestee (tirer 1,00), sl-traction-negative-lestee-supramaximale, sl-traction-scapulaire-lestee, pull-over haltère et barre EZ.

**R1-b. Stabilisateurs de préhension et de dos ignorés là où ils limitent la charge.**
- **Défaut.** Le soulevé de terre conventionnel vaut jambes 0,70 / tronc 0,30 / **tirer 0**. Or le grand dorsal, les trapèzes et les fléchisseurs des doigts figurent bien dans `muscles_stabilisateurs`, mais R1 ne lit pas ce champ.
- **Correction.** Dans les schémas `charniere_hanche`, `porte`, `halterophilie` et `balistique`, ajouter les `muscles_stabilisateurs` qui correspondent à **tirer**, avec un poids de **0,25**. Les autres stabilisateurs restent ignorés : avec tous les stabilisateurs, le swing perdait trop de « jambes ».
- **Justification.** En soulevé de terre, la prise et le gainage scapulaire (barre près du corps) font partie des facteurs limitants les plus courants ; c'est pour cela que les sangles existent.
- **Effet.** Soulevé de terre : tirer 0,23 / jambes 0,54 / tronc 0,23. Swing : tirer 0,12. Arraché : tirer 0,14. Farmer walk : tirer 0,55.

**R1-c (non retenue). La coiffe des rotateurs comptée « tirer ».** L'élévation latérale reçoit tirer 0,28. J'ai testé un partage 0,5 pousser / 0,5 tirer. Il dégrade les rotations externes (pousser 0,33), qui sont un travail de coiffe postérieure. Je recommande de **laisser la règle telle quelle**.

### C.2 R2 : parts fixes par schéma

**R2-a. Compression.** La table fixe somme à 1 (tronc 0,5 / mobilité 0,3 / figures 0,2), si bien que les muscles sont ignorés et que tous les exercices de compression reçoivent le même vecteur.
- **Défaut.**
  - Le L-sit tuck (débutant) reçoit mobilité 0,30 alors qu'il ne demande aucune souplesse.
  - Le manna (élite) reste tronc 0,50 / figures 0,20 alors que c'est une figure de force de l'extension d'épaule.
- **Correction.**
  - figures = **0,20 / 0,30 / 0,40 / 0,50** (débutant / intermédiaire / avancé / élite) ;
  - tronc = **0,65 − figures** ;
  - mobilité = **0,15** ;
  - reste **0,20** réparti par les muscles.
- **Effet.**
  - L-sit : tronc 0,44 / figures 0,30 / mobilité 0,15.
  - V-sit : tronc 0,34 / figures 0,40.
  - Manna : figures 0,50 / tronc 0,20 / tirer 0,10 / mobilité 0,15.
- **Exercices corrigés.** cs-l-sit-sol, cs-l-sit-barres-paralleles, cs-l-sit-tuck, cs-v-sit, cs-manna, sl-l-sit-leste.

**R2-b. Figures dynamiques : explosivité 0,15 donnée sans condition.**
- **Défaut.** Les 43 figures dynamiques sur 43 reçoivent explosivité 0,15, y compris les mouvements lents de force (press to handstand, ice cream maker, planche push-up) et les excentriques.
- **Correction.** Si le régime est `explosif` : figures 0,35 + explosivité 0,15 (inchangé). Sinon : **figures 0,45** et explosivité 0.
- **Exercices corrigés.** cd-press-handstand-straddle, cd-press-handstand-tuck, cd-press-handstand-straddle-negatif, cd-ice-cream-maker, cd-planche-pushup-tuck-parallettes, cd-skin-the-cat-groupe, cd-traction-un-bras-assistee-serviette.

**R2-c. Transition / muscle-up.**
- **Défaut.**
  - La qualité dominante de la catégorie est pousser dans 19 cas sur 28.
  - Les 28 ont un maximum inférieur à 0,4.
  - L'explosivité vaut 0,25 même pour le muscle-up lent, les négatifs et une tenue isométrique de transition.
- **Correction.** `{'figures': 0,15, 'tirer': 0,15, 'explosivite': x}`, avec x = **0,25** si le régime est explosif (kipping, sauté), **0,05** s'il est dynamique (strict), **0** s'il est isométrique ou excentrique.
- **Justification.** Le facteur limitant reconnu du muscle-up est la traction haute, jusqu'au sternum, suivie de la transition. La phase de dips est la plus facile. Un strict ou un lent ne comporte, par définition, aucun élan.
- **Effet.**
  - Muscle-up lent : tirer 0,49 / pousser 0,31 / figures 0,15.
  - Kipping : explosivité 0,25 conservée.
  - Dominance de la catégorie : tirer dans 27 cas sur 28.
- **Exercices corrigés.** cd-muscle-up-barre-lent, cd-transition-muscle-up-box, cs-tenue-transition-muscle-up-anneaux, cd-muscle-up-anneaux-strict, sl-muscle-up-leste-pause-transition, ainsi que 6 négatifs.

**R2-d. HSPU libre.**
- **Défaut.** Le schéma `poussee_verticale_haute` est un schéma de force : figures 0, alors que l'équilibre limite la performance du HSPU libre.
- **Correction.** Si le schéma est `poussee_verticale_haute`, la charge le poids du corps et l'exercice un HSPU : **figures 0,25** en libre, **0,10** si `mur` figure dans le matériel.
- **Point à trancher.** Je recommande d'ajouter à la base un champ `calc.equilibre` (booléen). En attendant, on peut repérer ces exercices par le motif `hspu` dans l'id.
- **Exercices corrigés.** cd-hspu-libre (pousser 0,55 / figures 0,25), cd-hspu-libre-negatif, ainsi que les 10 HSPU de la base.

**R2-e. Gymnastique CrossFit** (actuellement figures 0,30 / endurance de force 0,20).
- **Correction.** `{'endurance_force': 0,30, 'anaerobie': 0,15, 'figures': 0,10}`, reste réparti par les muscles.
- **Justification.** Le kipping et le butterfly sont des cycles de balancier, choisis pour leur rendement métabolique. Ils demandent peu de force bras tendus et peu d'équilibre, ce que représente « figures ».
- **Exercices corrigés.** cf-traction-butterfly, cf-traction-kipping, cf-burpee-muscle-up-barre, cf-hspu-kipping-deficit.

**R2-f. Sprint : jambes 0,20 fixe.**
- **Correction.** Supprimer la part fixe `jambes` : `{'explosivite': 0,4, 'anaerobie': 0,4}` et reste 0,20 réparti par les muscles.
- **Effet.** La course ne change pas, puisque ses muscles sont ceux des jambes. Les ergomètres (rameur, SkiErg, air bike) récupèrent la part de tirage et de haut du corps.
- **Exercices corrigés.** ca-rameur-sprint, ca-air-bike-sprints, ca-skierg-sprint.

**R2-g. Haltérophilie non explosive.** L'overhead squat (barre et haltère, régime dynamique) reçoit explosivité 0,50.
- **Correction.** Si le régime n'est pas `explosif` : `{'explosivite': 0,10, 'mobilite': 0,10}`, reste réparti par les muscles.
- **Exercices concernés.** Hors échantillon, repérés par les vérifications de la partie D : mu-overhead-squat, cf-overhead-squat-haltere-unilateral.

**R2-h (amélioration mineure). Conditionnement.** La table fixe somme à 1 : les 29 exercices de conditionnement ont exactement le même vecteur (burpee = thruster = wall ball).
- **Proposition.** `{'anaerobie': 0,40, 'aerobie': 0,20, 'endurance_force': 0,20}` et reste 0,20 réparti par les muscles.
- **Effet attendu.** Le thruster prend jambes et pousser, le burpee pousser et jambes.
- Le défaut n'a pas valu de « X » dans l'échantillon. Cette correction n'a pas été simulée.

### C.3 R3 : endurance de force

**R3-a. L'élastique est traité comme le poids du corps.**
- **Défaut.** 17 exercices à l'élastique reçoivent une part d'endurance de force (0,30 pour 10 d'entre eux, 0,21 pour 7) : marche latérale, extension terminale du genou, spanish squat, pushdown, rotations externes…
- **Correction.** Calculer la part d'endurance sur `('poids_du_corps', 'aucune')` seulement. Les exercices concernés restent de type `reps`.
- **Justification.** L'élastique est une résistance externe réglable, prescrite comme une charge légère, en rééducation ou en isolation. Une série de 20 extensions terminales du genou ne renseigne pas sur l'endurance au poids du corps (pompes, tractions, dips).
- **Exercices corrigés.** mu-marche-laterale-elastique, mu-terminal-knee-extension, mu-spanish-squat-elastique, mu-pushdown-elastique, mu-rotation-externe-elastique.

**R3-b (observation, sans correction).** La part d'endurance dépend du niveau de l'exercice, pas de celui du pratiquant : 0,30 pour un exercice débutant. Le choix est défendable, puisque les exercices faciles se font à répétitions hautes.

### C.4 R4 : part de la racine

Aucun défaut systématique dans l'échantillon. Deux remarques :
- L'héritage traverse les changements de type de charge : mu-russian-twist-leste hérite d'une endurance de 0,036 de sa racine au poids du corps. L'effet est négligeable. Option : ne pas transmettre `endurance_force` quand la variante est sous charge externe.
- Les tables fixes neutralisent R4 sur les variantes de haut niveau : les triple-unders ont le même vecteur que les sauts simples. Option : pour la corde à sauter au niveau élite, anaérobie +0,1, explosivité +0,1, aérobie −0,2. Correction facultative.

### C.5 R5 : type de réponse

1. **R5-a.** `tenue` uniquement si le régime est `isometrique` ou `passif`. Sinon (secondes et régime dynamique ou explosif) → **`wod`**. Corrige mu-battle-rope-ondulations, mu-mountain-climbers, cf-pogo-jumps.
2. **R5-b.** Schéma `gymnastique_crossfit` en répétitions → **`reps`** au lieu de `wod`. La performance se compte en répétitions, pas sur une durée imposée. Corrige les 11 exercices du schéma, dont butterfly, kipping, burpee muscle-up et HSPU kipping.
3. **R5-c.** `type_charge = autre` ne donne `charge` que si la charge se mesure en kilos comparables au poids du corps.
   - Exclure `pliometrie` : les lancers de médecine-ball et le slam se font, par définition, à charge sous-maximale (4 exercices).
   - Exclure le matériel `pince de préhension`, dont la résistance est celle d'un ressort.
   - Ces exercices passent en → **`reps`**. Corrige mu-lancer-arriere-medecine-ball, mu-pince-de-prehension (et 3 autres lancers).
4. **R5-d (à arbitrer).** Les portés en distance sont de type `autre` : la charge portée n'est pas modélisée (farmer walk, suitcase, rack, overhead carry). De même, le thruster est de type `wod`, sans ratio. Si le moteur doit progresser en charge sur ces exercices, il faut un type `charge` avec une distance fixée ; un a priori plausible serait 0,55 par main pour un farmer walk de 20 m.

### C.6 R6 : charge tendineuse

1. **R6-a. Zone sans objet.** Quand la contrainte maximale est « faible » (0,1), mettre la zone à **`None`**. Aujourd'hui, 120 exercices sur 120 de cette sorte affichent « coude » : rouleau des ischios, cohérence cardiaque, shrug…
2. **R6-b. Départage des ex aequo par schéma.** Ordre des zones à tester en premier :
   - `equilibre_mains` : poignet, épaule, coude ;
   - `figure_statique_poussee` : coude, poignet, épaule ;
   - `pliometrie` : genou, cheville ;
   - `sprint` et `corde_a_sauter` : cheville, genou ;
   - `balistique` et `charniere_hanche` : lombaires, hanche ;
   - `halterophilie` : poignet, genou, épaule.

   Corrige cs-crane, cs-handstand, cs-handstand-poids-decale (le poignet est la plainte typique), le swing (épaule → lombaires), l'épaulé (épaule → poignet). R6-a et R6-b ensemble changent 183 zones.
3. **R6-c. Bonus « bras tendus » modulé par niveau** : +0 au niveau débutant, **+0,1** intermédiaire, **+0,2** avancé et élite.
   - **Défaut.** Les 66 figures statiques sur 66 sont à 1,0, dont 10 de niveau débutant (planche lean…).
   - **Justification.** La contrainte sur le tendon distal du biceps et sur l'épaule antérieure croît avec le bras de levier, de la position tuck à la position complète. Le planche lean est l'éducatif de conditionnement tendineux, pas la charge maximale.
   - **Effet.** Répartition : 1,0 pour 37 figures, 0,9 pour 16, 0,8 pour 12, 0,7 pour 1.
4. **R6-d. Assistance.** Si `assiste`, **−0,2**, avec un plancher à 0,4. Aujourd'hui, 15 exercices assistés sont à 0,8 ou plus.
   - Corrige cs-iron-cross-pieds-au-sol (0,8), cs-front-lever-assiste-elastique (0,7), sw-dips-assistes-elastique (0,6), cd-traction-un-bras-assistee-serviette (0,6).
5. **R6-e. Plancher « sauts » à 0,7 seulement en cas d'impact.**
   - Il ne s'applique ni aux ergomètres (`rameur`, `vélo / home-trainer`, `air bike`, `SkiErg`), ni à la pliométrie dont les muscles principaux sont pour moitié au moins hors des jambes (lancers, pompes claquées).
   - Quand la zone trouvée est un membre supérieur et que le plancher s'applique, la zone devient cheville (sprint, corde) ou genou (pliométrie).
   - Corrige ca-air-bike-sprints, ca-rameur-sprint et ca-skierg-sprint (0,7 → 0,4).
   - Le lancer arrière, dominé par les jambes, garde 0,7 mais en zone genou au lieu de coude.
   - Le slam et les lancers à dominante haut du corps passent à 0,4.
6. **R6-f. Régime passif plafonné à 0,4.** Un étirement passif (grand écart, pancake) ne produit pas la charge tendineuse d'une tenue de force. La moyenne du schéma `souplesse` passe de 0,71 à 0,54. Corrige mo-grand-ecart-antero-blocs, mo-pancake-a-plat.

Les autres défauts de tendon de l'échantillon viennent des champs de la base (voir C.8) : nordic, GHR, tête au sol, tenue en false grip, wrist curl, traction scapulaire lestée.

### C.7 R7 : ratio a priori

1. **R7-a. Smith machine → colonne « barre ».**
   - Si `'Smith machine'` figure dans le matériel, utiliser la colonne barre (11 exercices).
   - **Défaut.** Le squat à la Smith prend la colonne « presse à cuisses » : ratio **2,2**, soit 176 kg de 1RM pour un intermédiaire de 80 kg. Le hip thrust et le shrug à la Smith tombent à 0,8.
   - **Effet.** Squat Smith 1,4 ; hip thrust Smith 1,4 ; shrug Smith 1,4 ; développés Smith 1,05, 0,9 et 0,68 ; mollets Smith 1,2.
2. **R7-b. Unilatéral.**
   - Multiplier le ratio par **0,55** si `lateralite = unilateral`, si la colonne est barre, machine ou poulie, et si le schéma n'est ni `fente` (déjà unilatéral par construction), ni `isolation_epaules`, ni `isolation_pectoraux` (dont la valeur poulie est déjà par côté).
   - **Justification.** Déficit bilatéral : la force maximale d'un seul membre vaut un peu plus de la moitié de la force bilatérale (Škarabot et coll., 2016, revue, *Eur J Appl Physiol*).
   - **Exercices corrigés.**
     - Développé landmine : 0,9 → 0,5.
     - Rowing poulie unilatéral : 0,8 → 0,44.
     - Tirage vertical unilatéral (deux exercices) : 0,9 → 0,5.
     - Curl poulie unilatéral : 0,35 → 0,19.
     - Hors échantillon : meadows row, leg curl et leg extension unilatéraux, kickbacks.
3. **R7-c. Lest : ratio = `fraction_pdc` + lest relatif.**
   - Table **LEST_REL** : `tirage_vertical` 0,40 ; `poussee_verticale_basse` 0,50 ; `poussee_horizontale` 0,40 ; `transition_muscle_up` 0,15 ; `fente` 0,30 ; `tirage_horizontal` 0,35.
   - **Défaut.** La colonne « lest » est une charge totale identique quelle que soit la fraction de poids de corps. Pour les dips au banc (fraction 0,5), le ratio de 1,55 suppose un **lest de 84 kg** à 1RM. Pour le row australien (fraction 0,6), le ratio de 1,2 suppose 48 kg de lest.
   - **Effet.** Traction 1,37 (+32 kg) ; dips 1,46 (+40 kg) ; dips au banc **1,00** (+40 kg) ; pompe 1,12 ; muscle-up 1,12 ; pistol 1,24 ; row australien 0,95.
4. **R7-d. Haltérophilie : a priori par racine et par variante.**
   - Racines : `mu-arrache` **0,78** ; `mu-epaule` **1,00** ; `mu-epaule-jete` **0,95** ; `mu-push-press` 0,85 ; `mu-overhead-squat` 0,85 ; `cf-thruster-barre` 0,75 ; `cf-sdhp-barre` 0,85.
   - Facteurs selon l'id : `muscle` ×0,70, `power` ×0,85, `tirage` ×1,10.
   - **Justification.** Ce sont des rapports d'usage chez les entraîneurs, à prendre comme ordres de grandeur et non comme une norme publiée : l'arraché vaut environ 80 % de l'épaulé-jeté ; une variante power environ 80-90 % du mouvement complet ; une variante muscle nettement moins ; un tirage plus que le mouvement complet.
   - **Effet.** Power snatch 0,66 (au lieu de 0,85) ; muscle snatch 0,55 ; muscle clean 0,70 ; arraché 0,78 ; épaulé 1,00 ; push jerk 0,95.
   - **Point à trancher.** Un champ de base `calc.mouvement_haltero` serait plus robuste que les mots de l'id.
5. **R7-e. Lignes de table manquantes.** Ces schémas tombent aujourd'hui sur le défaut (0,50 ; 0,20 ; 0,50 ; 0,40 ; 1,20). Colonnes : barre, haltères ou kettlebell, machine, poulie, lest.
   - `balistique` (0,60 ; **0,35** ; 0,60 ; 0,40 ; 0,60). Un kettlebell de 28 kg est plausible pour un swing ou un épaulé intermédiaire ; le défaut donnait 16 kg.
   - `isolation_trapezes` (**1,40** ; 0,50 ; 1,20 ; 0,80 ; 1,40). Le shrug valait 1,0.
   - `prehension` (0,50 ; 0,15 ; 0,40 ; 0,35 ; 0,50), ×0,6 si `extenseurs du poignet` est un muscle principal. Le reverse wrist curl à l'haltère passe de 0,20 à 0,09.
   - `cou` (**0,25** ; 0,10 ; 0,30 ; 0,20 ; 0,25). L'extension au harnais valait 0,50, soit 40 kg.
   - `extension_rachis` (**0,30** ; 0,15 ; 0,60 ; 0,40 ; 0,30). Jefferson curl : 0,5 → 0,3.
   - `preparation_scapulaire` (0,40 ; 0,20 ; 0,40 ; 0,30 ; **1,60**). La traction scapulaire lestée a une amplitude courte et se charge plus qu'une traction.
6. **R7-f. Excentrique.** Multiplier par **1,25** si le régime est `excentrique` et la charge est un lest, une barre ou une machine. La force excentrique maximale dépasse la concentrique : c'est un fait communément admis, mais l'écart varie selon les études, et 1,25 est une valeur prudente. La traction négative lestée supramaximale passe de 1,40 à 1,71.
7. **R7-g. Fente à la machine.** Passer la colonne machine de `fente` de 0,80 à **1,10** : la presse unilatérale vaut environ la moitié de la presse bilatérale (2,2). Correction non simulée.

### C.8 Champs de la base qui semblent faux (à signaler, sans correction de règle)

| exercice(s) | champ | constat | proposition |
|---|---|---|---|
| cs-tenue-haute-false-grip-anneaux | schéma | tenue bras **fléchis**, classée figure statique, d'où le bonus bras tendus | `transition_muscle_up` ou `tirage_vertical` (isométrie) |
| cs-suspension-un-bras, cs-suspension-active-un-bras | schéma | suspension = préhension, figures 0,55 | `prehension` |
| ca-educatif-pas-chasses | schéma | éducatif cyclique traité en sprint (explosivité 0,4, tendon 0,8) | `cardio_fractionne` ou échauffement |
| mu-battle-rope-ondulations | catégorie | « Portés et strongman » | « Conditionnement métabolique » |
| mu-windmill-kettlebell | schéma, muscles | une charnière donne un ratio de 0,45 par main (36 kg) | `gainage_anti_flexion_laterale` ; ajouter deltoïdes et triceps |
| cf-fente-overhead-haltere, mu-overhead-squat | muscles | aucun muscle d'épaule ni de tronc, alors que la tenue au-dessus de la tête limite | ajouter deltoïdes, trapèzes, dentelé, obliques |
| mu-nordic-hamstring-curl (+ négatif) | régime, contraintes | régime dynamique et genou « moyenne » : tendon 0,4 pour l'excentrique d'ischio le plus dur | régime `excentrique`, genou `forte` |
| mu-glute-ham-raise | contraintes | tendon 0,4 | genou `forte` à discuter |
| cs-headstand-tripode | contraintes | épaule « forte » pour un équilibre débutant sur la tête | épaule `moyenne` ; la charge porte surtout sur la nuque |
| mu-wrist-curl-barre, mu-reverse-wrist-curl-* | contraintes | poignet « forte » sur une charge légère | poignet `moyenne` |
| mu-jefferson-curl | schéma | exercice de mobilité chargée en flexion, mobilité 0 | ajouter une part de mobilité, ou schéma dédié |
| sl-traction-scapulaire-lestee, mo-etirement-bas-dips-barres | contraintes | toutes « faible » : tendon 0,1 | épaule `moyenne` |
| sl-releve-*-leste (3), mu-russian-twist-leste, sl-traction-scapulaire-lestee | fraction_pdc | absente : le ratio lest de 1,20 n'a pas de sens | renseigner la fraction (0,97 pour la traction scapulaire) |
| mu-halo-kettlebell | schéma | exercice de mobilité d'épaule, mobilité 0 | à discuter |

---

## D. Vérifications globales (1 039 exercices)

Script `verifs.py` en annexe 2.

### D.1 Intégrité
- 1 039 fiches, mêmes ids que le catalogue.
- **Somme des vecteurs = 1** : 0 écart.
- **Aucune charge négative** : 0.
- `regles.py --verifier` : le fichier est à jour.

### D.2 Qualité dominante par catégorie

| catégorie | n | qualité dominante (effectif) |
|---|---|---|
| Adducteurs / abducteurs | 11 | jambes 8, tronc 3 |
| Auto-massage | 11 | mobilite 11 |
| Avant-bras et préhension | 20 | tirer 20 |
| Balistique kettlebell | 6 | explosivite 6 |
| Cardio continu | 10 | aerobie 10 |
| Cardio fractionné | 13 | anaerobie 13 |
| Charnière de hanche | 17 | jambes 16, tronc 1 |
| Compression | 15 | tronc 15 |
| Conditionnement métabolique | 29 | anaerobie 29 |
| Corde à sauter | 7 | aerobie 7 |
| Cou | 8 | tronc 5, tirer 3 |
| Extension de genou | 6 | jambes 6 |
| Extension de hanche | 13 | jambes 13 |
| Extension du rachis | 7 | tronc 7 |
| Fente / unilatéral jambes | 25 | jambes 25 |
| Figure dynamique poussée | 23 | pousser 13, figures 10 |
| Figure dynamique tirage | 20 | tirer 15, figures 3, pousser 2 |
| Figure statique mixte | 7 | figures 7 |
| Figure statique poussée | 22 | figures 22 |
| Figure statique tirage | 37 | figures 37 |
| Flexion de genou (ischio-jambiers) | 10 | jambes 10 |
| Flexion de hanche / relevés de jambes | 10 | tronc 10 |
| Flexion du tronc | 16 | tronc 16 |
| Freestyle dynamique | 14 | figures 14 |
| Gainage anti-extension | 23 | tronc 23 |
| Gainage anti-flexion latérale | 6 | tronc 6 |
| Gainage anti-rotation | 8 | tronc 8 |
| Gymnastique CrossFit | 11 | tirer 6, figures 3, pousser 2 |
| Haltérophilie | 25 | explosivite 24, jambes 1 |
| Isolation biceps | 22 | tirer 22 |
| Isolation dos | 8 | tirer 6, pousser 2 |
| Isolation pectoraux | 11 | pousser 11 |
| Isolation triceps | 22 | pousser 22 |
| Isolation épaules | 29 | tirer 15, pousser 14 |
| Marche et portage | 5 | aerobie 5 |
| Mobilité articulaire | 28 | mobilite 28 |
| Mollets et cheville | 8 | jambes 8 |
| Mouvement de compétition | 4 | tirer 2, pousser 1, jambes 1 |
| Pliométrie | 23 | explosivite 23 |
| Portés et strongman | 12 | jambes 5, tirer 4, tronc 2, pousser 1 |
| Poussée horizontale | 60 | pousser 60 |
| Poussée inclinée | 10 | pousser 10 |
| Poussée verticale | 57 | pousser 57 |
| Préparation scapulaire | 11 | tirer 9, pousser 2 |
| Respiration et récupération | 4 | mobilite 4 |
| Rotation du tronc | 16 | tronc 16 |
| Souplesse avancée | 17 | mobilite 17 |
| Sprint et vitesse | 12 | explosivite 12 |
| Squat / dominante genou | 45 | jambes 45 |
| Tirage horizontal | 40 | tirer 40 |
| Tirage vertical | 56 | tirer 56 |
| Transition / muscle-up | 28 | pousser 19, tirer 7, explosivite 2 |
| Élévation scapulaire / trapèzes | 6 | tirer 6 |
| Équilibre sur les mains | 25 | figures 25 |
| Étirement dynamique | 9 | mobilite 9 |
| Étirement statique | 41 | mobilite 41 |

**Anomalies de dominance :**
- **Transition / muscle-up : pousser domine dans 19 cas sur 28.** C'est la principale surprise : le tirage haut est le facteur limitant (R2-c). Après correction : tirer dans 27 cas sur 28.
- **Figure dynamique poussée et tirage : pousser ou tirer domine dans 28 cas sur 43**, figures seulement dans 13. Cela vient de l'explosivité 0,15 qui retire de la part à figures (R2-b). Après correction, les figures s'équilibrent : 11 cas sur 23 côté poussée, 9 sur 20 côté tirage.
- **Compression : tronc domine dans 15 cas sur 15,** même pour le manna et le V-sit haut (R2-a). Après correction : figures dans 6 cas, tronc dans 9.
- **Isolation dos : pousser domine pour 2 exercices** (pull-over haltère et pull-over barre EZ), à cause de R1-a.
- **Charnière de hanche : tronc domine pour 1 exercice** (windmill), à cause du schéma de la base (C.8).
- **Adducteurs / abducteurs : tronc domine pour 3 exercices** (Copenhagen plank, trois variantes). C'est correct : obliques et adducteurs sont bien sollicités. Rien à corriger.
- **Haltérophilie : jambes domine pour 1 exercice** (overhead squat à l'haltère, à 0,5/0,5 avec l'explosivité). Voir R2-g.
- **Cou : tirer domine pour 3 exercices** (trapèze supérieur) ; **isolation épaules : tirer domine pour 15 exercices** (oiseau, face pull, rotations). Acceptable.

### D.3 Exercices dont aucune qualité ne dépasse 0,4 (60 exercices)

Ce sont surtout des exercices réellement mixtes : 27 transitions de muscle-up et 1 muscle-up lesté de compétition, 20 figures dynamiques, 8 exercices de gymnastique CrossFit, 3 portés, 1 exercice du cou. Le seuil n'est pas un défaut en soi. Mais le cas du muscle-up (pousser ≈ tirer ≈ 0,3, explosivité 0,25) révèle le défaut R2-c. Après les corrections simulées, il en reste 21.

- cd-pull-over-barre | Transition / muscle-up | max=0,25 | tire0,23 tron0,23 figu0,15 expl0,25
- cd-kip-swing-barre | Transition / muscle-up | max=0,25 | pous0,16 tire0,20 tron0,21 figu0,15 expl0,25
- cd-muscle-up-barre-kipping | Transition / muscle-up | max=0,26 | pous0,26 tire0,24 figu0,15 expl0,25
- cd-muscle-up-une-main-assiste | Transition / muscle-up | max=0,27 | pous0,26 tire0,27 figu0,15 expl0,25
- cd-muscle-up-une-main | Transition / muscle-up | max=0,28 | pous0,25 tire0,28 figu0,15 expl0,25
- cd-muscle-up-barre-basse-pieds-au-sol | Transition / muscle-up | max=0,28 | pous0,28 tire0,25 figu0,15 expl0,25
- cd-muscle-up-saute | Transition / muscle-up | max=0,28 | pous0,28 tire0,22 figu0,15 expl0,25
- cd-muscle-up-anneaux-kipping | Transition / muscle-up | max=0,29 | pous0,29 tire0,23 figu0,15 expl0,25
- cd-muscle-up-une-main-negatif | Transition / muscle-up | max=0,29 | pous0,28 tire0,29 figu0,15 expl0,25
- cd-muscle-up-anneaux-strict | Transition / muscle-up | max=0,30 | pous0,30 tire0,30 figu0,15 expl0,25
- cd-muscle-up-barre-strict | Transition / muscle-up | max=0,30 | pous0,30 tire0,30 figu0,15 expl0,25
- cf-burpee-muscle-up-barre | Gymnastique CrossFit | max=0,30 | pous0,18 tire0,18 jamb0,11 figu0,30 endu0,20
- cf-knees-to-elbows-kipping | Gymnastique CrossFit | max=0,30 | tire0,13 jamb0,11 tron0,26 figu0,30 endu0,20
- cf-toes-to-bar-kipping | Gymnastique CrossFit | max=0,30 | tire0,11 jamb0,14 tron0,21 figu0,30 endu0,20
- cd-muscle-up-archer | Transition / muscle-up | max=0,30 | pous0,30 tire0,28 figu0,15 expl0,25
- cf-hspu-kipping | Gymnastique CrossFit | max=0,31 | pous0,31 jamb0,15 figu0,30 endu0,20
- cd-hefesto-negatif | Transition / muscle-up | max=0,31 | pous0,31 tire0,29 figu0,15 expl0,25
- cd-muscle-up-barre-lent | Transition / muscle-up | max=0,31 | pous0,29 tire0,31 figu0,15 expl0,25
- sl-muscle-up-negatif-leste | Transition / muscle-up | max=0,32 | pous0,28 tire0,32 figu0,15 expl0,25
- cd-muscle-up-anneaux-negatif | Transition / muscle-up | max=0,32 | pous0,32 tire0,28 figu0,15 expl0,25
- cd-muscle-up-barre-assiste-elastique | Transition / muscle-up | max=0,32 | pous0,32 tire0,28 figu0,15 expl0,25
- cd-muscle-up-barre-l-sit | Transition / muscle-up | max=0,32 | pous0,32 tire0,28 figu0,15 expl0,25
- cd-muscle-up-barre-negatif | Transition / muscle-up | max=0,32 | pous0,32 tire0,28 figu0,15 expl0,25
- cd-muscle-up-barre-prise-serree | Transition / muscle-up | max=0,32 | pous0,32 tire0,28 figu0,15 expl0,25
- cf-hspu-kipping-deficit | Gymnastique CrossFit | max=0,33 | pous0,33 jamb0,13 figu0,30 endu0,20
- cd-hefesto | Transition / muscle-up | max=0,33 | pous0,33 tire0,27 figu0,15 expl0,25
- sl-muscle-up-leste-anneaux | Transition / muscle-up | max=0,33 | pous0,27 tire0,33 figu0,15 expl0,25
- mu-sac-leste-sur-epaule | Portés et strongman | max=0,34 | tire0,25 jamb0,34 tron0,18 anae0,20
- sl-muscle-up-leste-depuis-haut-tirage | Transition / muscle-up | max=0,34 | pous0,34 tire0,26 figu0,15 expl0,25
- sl-muscle-up-leste-false-grip | Transition / muscle-up | max=0,35 | pous0,25 tire0,35 figu0,15 expl0,25
- cd-press-handstand-l-sit | Figure dynamique poussée | max=0,35 | pous0,23 tire0,12 tron0,12 figu0,35 expl0,15
- cd-press-handstand-pike | Figure dynamique poussée | max=0,35 | pous0,23 tire0,12 tron0,12 figu0,35 expl0,15
- cd-press-handstand-straddle | Figure dynamique poussée | max=0,35 | pous0,23 tire0,12 tron0,12 figu0,35 expl0,15
- cd-back-lever-pull-complet | Figure dynamique tirage | max=0,35 | pous0,35 tire0,15 figu0,35 expl0,15
- cd-back-lever-pull-tuck | Figure dynamique tirage | max=0,35 | pous0,35 tire0,15 figu0,35 expl0,15
- cd-planche-to-handstand | Figure dynamique poussée | max=0,35 | pous0,31 tire0,12 figu0,35 expl0,15
- cd-press-handstand-straddle-negatif | Figure dynamique poussée | max=0,35 | pous0,22 tire0,12 tron0,12 figu0,35 expl0,15
- cd-skin-the-cat | Figure dynamique tirage | max=0,35 | pous0,17 tire0,23 tron0,10 figu0,35 expl0,15
- cd-skin-the-cat-groupe | Figure dynamique tirage | max=0,35 | pous0,17 tire0,17 tron0,15 figu0,35 expl0,15
- cd-tuck-planche-to-handstand | Figure dynamique poussée | max=0,35 | pous0,30 tire0,12 figu0,35 expl0,15
- cd-german-hang-pull-out | Figure dynamique tirage | max=0,35 | pous0,27 tire0,13 figu0,35 expl0,15
- cd-press-handstand-anneaux-bras-flechis | Figure dynamique poussée | max=0,35 | pous0,33 figu0,35 expl0,15
- cd-press-handstand-bras-flechis | Figure dynamique poussée | max=0,35 | pous0,33 figu0,35 expl0,15
- cd-press-handstand-straddle-pieds-sureleves | Figure dynamique poussée | max=0,35 | pous0,24 tire0,14 tron0,10 figu0,35 expl0,15
- cd-press-handstand-tuck | Figure dynamique poussée | max=0,35 | pous0,27 tire0,12 figu0,35 expl0,15
- sl-muscle-up-leste | Mouvement de compétition | max=0,35 | pous0,25 tire0,35 figu0,15 expl0,25
- sl-muscle-up-leste-pause-transition | Transition / muscle-up | max=0,35 | pous0,35 tire0,25 figu0,15 expl0,25
- cf-montee-corde-j-hook | Gymnastique CrossFit | max=0,36 | tire0,36 figu0,30 endu0,20
- cd-muscle-up-anneaux-transition-au-sol | Transition / muscle-up | max=0,36 | pous0,36 tire0,24 figu0,15 expl0,25
- cd-transition-muscle-up-box | Transition / muscle-up | max=0,36 | pous0,36 tire0,24 figu0,15 expl0,25
- cf-traction-butterfly | Gymnastique CrossFit | max=0,36 | tire0,36 figu0,30 endu0,20
- mu-suitcase-carry | Portés et strongman | max=0,36 | tire0,34 tron0,36 anae0,20
- cd-front-lever-raise-complet | Figure dynamique tirage | max=0,36 | pous0,14 tire0,36 figu0,35 expl0,15
- cd-front-lever-raise-straddle | Figure dynamique tirage | max=0,36 | pous0,14 tire0,36 figu0,35 expl0,15
- cd-front-lever-raise-tuck | Figure dynamique tirage | max=0,36 | pous0,14 tire0,36 figu0,35 expl0,15
- cd-front-lever-raise-tuck-avance | Figure dynamique tirage | max=0,36 | pous0,14 tire0,36 figu0,35 expl0,15
- mu-epaule-sac-leste | Portés et strongman | max=0,37 | tire0,32 jamb0,37 tron0,11 anae0,20
- cd-pompe-lalanne | Figure dynamique poussée | max=0,38 | pous0,38 tire0,12 figu0,35 expl0,15
- cf-traction-kipping | Gymnastique CrossFit | max=0,38 | tire0,38 figu0,30 endu0,20
- mu-flexion-laterale-cou-main | Cou | max=0,40 | tire0,40 tron0,40 endu0,21


### D.4 Exercices de type « charge » sans ratio, ou de ratio hors de [0,1 ; 2,5]

- **Aucun.** Les 379 exercices de type charge ont tous un ratio compris entre 0,12 et 2,2. Mais l'intervalle ne suffit pas à juger :
- **Ratio par défaut.** 58 exercices de type charge tombent sur `RATIO_DEFAUT`, faute de ligne pour leur schéma :

  | schéma | type de charge | n |
  |---|---|---|
  | balistique | kettlebell | 6 |
  | prehension | barre | 5 |
  | prehension | haltères | 5 |
  | rotation_tronc | poulie | 5 |
  | prehension | autre | 4 |
  | pliometrie | autre | 4 |
  | porte | autre | 3 |
  | cou | autre | 3 |
  | preparation_scapulaire | haltères | 3 |
  | flexion_hanche | lest | 3 |
  | flexion_tronc | poulie | 2 |
  | gainage_anti_rotation | poulie | 2 |
  | autres combinaisons (1 exercice chacune) | | 13 |

  Le type `autre` y est rangé dans la colonne « barre ». Corrections en R7-e et R5-c.
- **Unilatéraux** : 70 exercices de type charge, dont 30 en barre, machine, poulie ou lest prennent la valeur bilatérale (R7-b).
- **Smith** : la valeur aberrante est 2,2 pour le squat Smith (R7-a).
- **Lest** : le lest implicite atteint 1,05 fois le poids du corps pour les dips au banc (R7-c).

### D.5 Charge tendineuse par schéma

| schéma | n | min | moyenne | max |
|---|---|---|---|---|
| figure_statique_poussee | 22 | 1,00 | 1,00 | 1,00 |
| figure_statique_tirage | 37 | 1,00 | 1,00 | 1,00 |
| figure_statique_mixte | 7 | 1,00 | 1,00 | 1,00 |
| poussee_verticale_basse | 29 | 0,80 | 0,86 | 1,00 |
| transition_muscle_up | 29 | 0,40 | 0,82 | 1,00 |
| figure_dynamique_tirage | 20 | 0,80 | 0,81 | 0,90 |
| poussee_verticale_haute | 29 | 0,80 | 0,81 | 0,90 |
| figure_dynamique_poussee | 23 | 0,80 | 0,80 | 0,90 |
| corde_a_sauter | 7 | 0,80 | 0,80 | 0,80 |
| freestyle | 14 | 0,80 | 0,80 | 0,80 |
| equilibre_mains | 25 | 0,80 | 0,80 | 0,80 |
| gymnastique_crossfit | 11 | 0,80 | 0,80 | 0,80 |
| halterophilie | 25 | 0,80 | 0,80 | 0,80 |
| pliometrie | 23 | 0,70 | 0,79 | 0,90 |
| sprint | 12 | 0,70 | 0,78 | 0,80 |
| souplesse | 17 | 0,40 | 0,71 | 0,80 |
| charniere_hanche | 17 | 0,40 | 0,66 | 0,80 |
| extension_genou | 6 | 0,40 | 0,60 | 0,80 |
| tirage_vertical | 57 | 0,40 | 0,58 | 1,00 |
| gainage_anti_extension | 23 | 0,40 | 0,54 | 0,90 |
| squat | 46 | 0,40 | 0,53 | 0,90 |
| isolation_triceps | 22 | 0,40 | 0,51 | 0,80 |
| prehension | 20 | 0,40 | 0,50 | 0,80 |
| poussee_horizontale | 60 | 0,40 | 0,50 | 0,90 |
| fente | 25 | 0,40 | 0,46 | 0,80 |
| extension_rachis | 7 | 0,40 | 0,46 | 0,80 |
| conditionnement | 29 | 0,40 | 0,44 | 0,80 |
| tirage_horizontal | 40 | 0,40 | 0,44 | 0,80 |
| porte | 12 | 0,40 | 0,43 | 0,80 |
| flexion_genou | 10 | 0,40 | 0,41 | 0,50 |
| flexion_hanche | 10 | 0,40 | 0,41 | 0,50 |
| cardio_fractionne | 13 | 0,40 | 0,40 | 0,40 |
| cardio_continu | 10 | 0,40 | 0,40 | 0,40 |
| flexion_tronc | 16 | 0,40 | 0,40 | 0,40 |
| balistique | 6 | 0,40 | 0,40 | 0,40 |
| compression | 15 | 0,40 | 0,40 | 0,40 |
| adducteurs_abducteurs | 11 | 0,40 | 0,40 | 0,40 |
| gainage_anti_rotation | 8 | 0,40 | 0,40 | 0,40 |
| isolation_biceps | 22 | 0,40 | 0,40 | 0,40 |
| rotation_tronc | 16 | 0,40 | 0,40 | 0,40 |
| isolation_epaules | 29 | 0,40 | 0,40 | 0,40 |
| poussee_inclinee | 10 | 0,40 | 0,40 | 0,40 |
| isolation_pectoraux | 11 | 0,40 | 0,40 | 0,40 |
| extension_hanche | 13 | 0,40 | 0,40 | 0,40 |
| gainage_anti_flexion_laterale | 6 | 0,40 | 0,40 | 0,40 |
| mollets | 8 | 0,40 | 0,40 | 0,40 |
| isolation_dos | 8 | 0,40 | 0,40 | 0,40 |
| marche | 5 | 0,10 | 0,22 | 0,40 |
| etirement_statique | 41 | 0,10 | 0,12 | 0,80 |
| mobilite_articulaire | 28 | 0,10 | 0,10 | 0,10 |
| etirement_dynamique | 9 | 0,10 | 0,10 | 0,10 |
| auto_massage | 11 | 0,10 | 0,10 | 0,10 |
| respiration | 4 | 0,10 | 0,10 | 0,10 |
| preparation_scapulaire | 11 | 0,10 | 0,10 | 0,10 |
| cou | 8 | 0,10 | 0,10 | 0,10 |
| isolation_trapezes | 6 | 0,10 | 0,10 | 0,10 |


- **Répartition globale :** 0,1 pour 120 exercices ; 0,4 pour 492 ; 0,5 pour 5 ; 0,7 pour 7 ; 0,8 pour 298 ; 0,9 pour 48 ; 1,0 pour 69.
- **Ce qui est cohérent.** En haut de l'échelle : figures statiques, dips, muscle-up, figures dynamiques, HSPU, pliométrie, sprints, corde. En bas : isolations, gainages, mobilité, respiration.
- **Ce qui ne l'est pas :**
  - `souplesse` en moyenne à 0,71, sur des étirements passifs (R6-f) ;
  - `equilibre_mains` uniformément à 0,8 en zone épaule (R6-b) ;
  - `halterophilie` uniformément à 0,8 en zone épaule (R6-b) ;
  - `balistique` à 0,4 en zone épaule (R6-b) ;
  - `preparation_scapulaire`, `isolation_trapezes` et `cou` à 0,1 même sous lest (base, C.8) ;
  - `flexion_genou` au maximum à 0,5 : nordic à 0,4 (base, C.8).
- **Isolation biceps.** Les 22 exercices sont tous à 0,4, sans distinction entre un curl lourd en triche ou au pupitre et un curl à l'élastique. C'est acceptable, mais un curl lourd mériterait 0,6. Option de règle : +0,2 si le schéma est `isolation_biceps` et le type de charge barre ou poulie au niveau avancé. Correction non simulée.

### D.6 Zones

- **Répartition :** coude 500, épaule 247, genou 127, hanche 57, lombaires 57, poignet 27, cheville 24.
- **« Coude » est surreprésenté** pour deux raisons :
  - Les **120 exercices sur 120 à tendon 0,1 affichent « coude »**. C'est un artefact : premier élément d'`ORDRE_ZONES` dont la contrainte, 0,1, est supérieure à 0 (R6-a).
  - En cas d'égalité, l'ordre fixe coude > épaule > poignet > genou > cheville masque le poignet en équilibre et la cheville en sprint (R6-b).

### D.7 Figures statiques avec tendon < 0,8

- **Aucune.** Les 66 exercices `figure_statique_*` sont **tous à 1,0**, dont 10 de niveau débutant et 17 intermédiaire, exercices assistés compris. Le défaut est l'inverse de celui que le test recherchait : la valeur est saturée.
- Après R6-c et R6-d : 1,0 pour 37, 0,9 pour 16, 0,8 pour 12, 0,7 pour 1.

### D.8 Cohérence type ↔ unité

| type | unité | n |
|---|---|---|
| autre | distance | 16 |
| cardio | calories | 1 |
| cardio | distance | 13 |
| cardio | repetitions | 3 |
| cardio | secondes | 30 |
| charge | repetitions | 379 |
| mobilite | repetitions | 35 |
| mobilite | secondes | 75 |
| reps | repetitions | 313 |
| tenue | secondes | 134 |
| wod | distance | 2 |
| wod | repetitions | 34 |
| wod | secondes | 4 |

- Les couples sont cohérents, avec deux exceptions :
  - **trois exercices de type `tenue` ne sont pas isométriques** : mu-battle-rope-ondulations, mu-mountain-climbers, cf-pogo-jumps (R5-a) ;
  - les 16 exercices `autre`/distance sont les portés et les marches en équilibre sur les mains. Ce n'est pas faux, mais la charge des portés n'est pas modélisée (R5-d).
- Les exercices `cardio` en répétitions (3, dont les triple-unders) et `wod` en distance (2) sont acceptables.
- Aucun exercice de type charge n'a de part d'endurance de force, sauf mu-russian-twist-leste (0,036, par héritage R4).

---

## E. Synthèse

### E.1 Taux d'exercices corrects (222 exercices)

| sous-ensemble | C | m | X | C strict | C + m |
|---|---|---|---|---|---|
| tirage aléatoire (142) | 84 | 26 | 32 | **59 %** | **77 %** |
| cas limites ajoutés (80) | 43 | 17 | 20 | 54 % | 75 % |
| total (222) | 127 | 43 | 52 | **57 %** | **77 %** |

- **Ce qui marche.** Le socle est bon : grandes poussées et grands tirages, squats, isolations, gainages, cardio, mobilité, figures statiques (vecteur), pliométrie du bas du corps, sprints sur piste, mouvements lestés de streetlifting (vecteur, type, tendon). Les sommes, les signes et la reproductibilité sont irréprochables.
- **Où sont les erreurs.** Elles se concentrent sur :
  - (a) quelques tables fixes trop rigides : compression, transition, figures dynamiques, gymnastique CrossFit ;
  - (b) R7, avec Smith, unilatéral, lest sans fraction, haltérophilie et schémas absents de la table ;
  - (c) R6, avec la saturation à 1,0, l'assistance, le plancher des sauts et les zones.
- **Effet des corrections simulées.** Sur les 52 « X » :
  - **43 sont entièrement corrigés** par les règles ;
  - **2 le sont en partie** (Jefferson curl, traction scapulaire lestée) ;
  - **7 relèvent des champs de la base** (C.8) : windmill, suspension à un bras, tenue en false grip, éducatif pas chassés, fente overhead, tête au sol, nordic.
  - Au total, 246 vecteurs bougent de plus de 0,05 avant la retouche de R1-b ; 200 après.

### E.2 Corrections de règles priorisées

1. **R7-a. Smith → colonne barre.** Le squat Smith à 2,2 est l'erreur de charge la plus grosse : 176 kg de 1RM proposés à un intermédiaire.
2. **R7-c. Lest = `fraction_pdc` + LEST_REL** (traction 0,40 ; dips 0,50 ; pompe 0,40 ; muscle-up 0,15 ; fente 0,30 ; row 0,35). Aujourd'hui, les dips au banc supposent 84 kg de lest et le row australien 48 kg.
3. **R7-b. Unilatéral ×0,55** pour la barre, la machine et la poulie, hors fente et hors isolation épaules ou pectoraux.
4. **R6-c + R6-d. Bonus bras tendus par niveau** (0 / +0,1 / +0,2 / +0,2) et **assistance −0,2**, avec un plancher à 0,4 : fin de la saturation des 66 figures à 1,0.
5. **R2-c. Transition / muscle-up :** tirer 0,15 + figures 0,15 + explosivité selon le régime (0,25 / 0,05 / 0).
6. **R2-b. Figures dynamiques :** explosivité 0,15 seulement si le régime est explosif, sinon figures 0,45.
7. **R2-a. Compression :** figures de 0,20 à 0,50 selon le niveau, tronc = 0,65 − figures, mobilité 0,15, reste 0,20 réparti par les muscles.
8. **R7-d + R7-e. Haltérophilie par racine et par variante,** et nouvelles lignes `balistique`, `isolation_trapezes`, `prehension`, `cou`, `extension_rachis`, `preparation_scapulaire`. Ajouter aussi R7-f (excentrique ×1,25).
9. **R5 :**
   - `tenue` réservé à l'isométrie ou au passif, sinon `wod` ;
   - `autre` en pliométrie ou à la pince → `reps` ;
   - gymnastique CrossFit en répétitions → `reps`.
10. **R1-a + R1-b :**
    - pectoraux sternal et abdominal, petit pectoral et chef long du triceps → tirer, dans les tirages ;
    - stabilisateurs de type tirer à 0,25 en charnière, porté, haltérophilie et balistique.
11. **R6-a, b, e, f :**
    - zone `None` à 0,1 ;
    - ordre des zones par schéma ;
    - plancher des sauts seulement en cas d'impact ;
    - régime passif plafonné à 0,4.
12. **R2-d, e, f, g + R3-a :**
    - figures pour le HSPU (0,25 en libre, 0,10 au mur) ;
    - nouvelle table pour la gymnastique CrossFit ;
    - sprint sans part fixe de jambes ;
    - haltérophilie non explosive ;
    - pas d'endurance de force pour l'élastique.

    En complément : les signalements de base de C.8, à commencer par la fraction des exercices lestés et le schéma des suspensions et de la tenue en false grip.

### E.3 Ce que je n'ai pas pu juger

- **L'échelle absolue de la charge tendineuse.** C'est une échelle ordinale sur 4 niveaux (0,1 / 0,4 / 0,8 / 1,0) issue des contraintes du catalogue. On peut en juger la cohérence relative, pas le lien avec une contrainte réelle mesurée.
- **Le ratio des poulies.** Il dépend du mouflage des machines. Pour les poulies doubles (écarté, oiseau), la convention « par côté » ou « total » n'est pas écrite : les valeurs 0,12 à 0,25 ne sont plausibles que par côté.
- **Les qualités absentes du modèle.** La préhension est confondue avec tirer et la mobilité n'a pas de sous-qualités. C'est un choix de structure, hors du périmètre des règles. Les 110 exercices de mobilité à mobilité 1,0 ne peuvent pas se distinguer entre eux.
- **Le calibrage de l'endurance de force** (0,30 / 0,20 / 0,10 selon le niveau de l'exercice) et des parts fixes de conditionnement : il faudrait des données de séances.
- **Les ratios d'haltérophilie et de kettlebell.** Ce sont des ordres de grandeur de pratique, sans norme publiée que je puisse citer avec certitude.
- **Les champs dérivés `difficulte`, `fatigue` et `fraction_pdc`.** Ils ne sont pas relus, sauf leur usage dans R7.

---

## Annexe 1. Code des verdicts

Les verdicts et commentaires du tableau B sont saisis dans `verdicts.py` (dictionnaire id → verdict et commentaire). Le tableau est produit par `rapport_tables.py`, qui vérifie que les 222 ids de l'échantillon ont tous un verdict et qu'il n'y en a aucun en trop.

## Annexe 2. Vérifications globales (`verifs.py`)

```python
import gzip, json, collections, statistics as st
BASE='/home/claude/moteurs/packages/kalis_'
cat={e['id']:e for e in json.load(gzip.open(BASE+'core/data/catalog_v1.json.gz','rt'))['exercices']}
D=json.load(open(BASE+'adapt/reference/qualites/vecteurs_qualites_v1.json'))
Q=D['qualites']; V=D['exercices']
print('N', len(V), 'ids identiques au catalogue:', set(V)==set(cat))
bad=[i for i,v in V.items() if abs(sum(v['vecteur'])-1)>1e-6]; print('somme!=1:', len(bad), bad[:5])
neg=[i for i,v in V.items() if min(v['vecteur'])<0]; print('negatifs:', len(neg))
print('\n## Qualite dominante par categorie')
dom=collections.defaultdict(collections.Counter)
for i,v in V.items():
    k=max(range(10),key=lambda j:v['vecteur'][j]); dom[cat[i]['categorie']][Q[k]]+=1
for c in sorted(dom): print(f"| {c} | {sum(dom[c].values())} | " + ', '.join(f"{q} {n}" for q,n in dom[c].most_common()) + ' |')
print('\n## max < 0.4')
faibles=[(i,max(v['vecteur'])) for i,v in V.items() if max(v['vecteur'])<0.4]
for i,m in sorted(faibles,key=lambda x:x[1]):
    v=V[i]; print(f"  {i} | {cat[i]['categorie']} | max={m:.2f} | "+' '.join(f"{Q[k][:4]}{x:.2f}" for k,x in enumerate(v['vecteur']) if x>=0.1))
print('nb', len(faibles))
print('\n## charge sans ratio / hors [0.1,2.5]')
for i,v in V.items():
    if v['type']=='charge' and (v['ratio'] is None or not 0.1<=v['ratio']<=2.5): print('  ',i,v['ratio'])
print('ratio defaut utilise (schema hors table):')
from collections import Counter
RT={'squat','charniere_hanche','fente','poussee_horizontale','poussee_inclinee','poussee_verticale_haute','poussee_verticale_basse','tirage_vertical','tirage_horizontal','transition_muscle_up','isolation_biceps','isolation_triceps','isolation_epaules','isolation_pectoraux','isolation_dos','isolation_trapezes','extension_genou','flexion_genou','mollets','extension_hanche','adducteurs_abducteurs','halterophilie'}
print('  ',Counter((v['schema'],v['type_charge']) for v in V.values() if v['type']=='charge' and v['schema'] not in RT))
print('charge unilaterales :', Counter((v['type_charge']) for i,v in V.items() if v['type']=='charge' and cat[i]['calc']['lateralite']=='unilateral'))
print('\n## tendon par schema (n, min, moy, max)')
par=collections.defaultdict(list)
for v in V.values(): par[v['schema']].append(v['tendon'])
for s in sorted(par, key=lambda s:-st.mean(par[s])): print(f"| {s} | {len(par[s])} | {min(par[s]):.2f} | {st.mean(par[s]):.2f} | {max(par[s]):.2f} |")
print('distribution globale', sorted(Counter(v['tendon'] for v in V.values()).items()))
print('zones', Counter(v['zone_tendon'] for v in V.values()))
print('zone coude alors que tendon=0.1 :', sum(1 for v in V.values() if v['tendon']==0.1 and v['zone_tendon']=='coude'))
print('\n## figure_statique_* tendon<0.8')
print([ (i,v['tendon']) for i,v in V.items() if v['schema'].startswith('figure_statique') and v['tendon']<0.8])
print('figure_statique tendon=1.0 par niveau:', Counter(cat[i]['niveau'] for i,v in V.items() if v['schema'].startswith('figure_statique') and v['tendon']>=1.0))
print('assistes avec tendon>=0.8:', [i for i,v in V.items() if cat[i]['calc']['assiste'] and v['tendon']>=0.8])
print('\n## type x unite')
print(Counter((v['type'],v['unite']) for v in V.values()))
print('tenue non isometrique:', [i for i,v in V.items() if v['type']=='tenue' and cat[i]['calc']['regime'] not in ('isometrique','passif')])
print('\n## part endurance_force>0 sous charge externe ? ', sum(1 for v in V.values() if v['type']=='charge' and v['vecteur'][5]>0.0))
print('exemples:', [(i,v['vecteur'][5]) for i,v in V.items() if v['type']=='charge' and v['vecteur'][5]>0][:8])
print('explosivite>0 en regime isometrique/lent:', [(i,v['vecteur'][6]) for i,v in V.items() if v['vecteur'][6]>0 and cat[i]['calc']['regime'] in ('isometrique','excentrique')][:20])
print('figures dynamiques non explosives avec exp 0.15:', sum(1 for i,v in V.items() if v['schema'].startswith('figure_dynamique') and cat[i]['calc']['regime']!='explosif'), '/', sum(1 for v in V.values() if v['schema'].startswith('figure_dynamique')))
print('pousser>=0.1 dans tirage_vertical charge:', [(i,v['vecteur'][0]) for i,v in V.items() if v['schema']=='tirage_vertical' and v['vecteur'][0]>=0.1])
print('elastique type reps avec end 0.3:', sum(1 for v in V.values() if v['type_charge']=='elastique'), Counter(round(v['vecteur'][5],2) for v in V.values() if v['type_charge']=='elastique'))
print('sprint/corde/plio plancher hors impact:', [(i,v['tendon'],v['zone_tendon']) for i,v in V.items() if v['schema'] in ('sprint','pliometrie','corde_a_sauter') and v['zone_tendon'] not in ('cheville','genou')])
```

## Annexe 3. Simulation des corrections proposées (`simulation.py`)

Le script importe `regles.py` en lecture seule et réécrit en copie `vecteur_propre`, `type_de`, `tendon_de` et le ratio. Il implémente toutes les corrections de C, sauf R2-g, R2-h, R6 « curl lourd » et R7-g, qui ne sont pas simulées.

```python
"""Simulation des corrections de règles proposées (ne modifie aucun fichier du dépôt)."""
import importlib.util, gzip, json, collections
P='/home/claude/moteurs/packages/kalis_adapt/reference/qualites/regles.py'
spec=importlib.util.spec_from_file_location('regles', P); R=importlib.util.module_from_spec(spec); spec.loader.exec_module(R)
cat=json.load(gzip.open(R.CATALOGUE,'rt')); E={e['id']:e for e in cat['exercices']}
avant=R.generer(cat)['exercices']

ERGO={'rameur','vélo / home-trainer','air bike (assault / echo)','SkiErg'}
TIRAGE_CTX=('tirage_vertical','tirage_horizontal','isolation_dos','preparation_scapulaire')
EXT_EN_TIRAGE={'grand pectoral (faisceau sternal)','grand pectoral (faisceau abdominal)','petit pectoral','triceps brachial (chef long)'}
STAB_CTX=('charniere_hanche','porte','halterophilie','balistique')
FIG_COMPRESSION={'Débutant':0.2,'Intermédiaire':0.3,'Avancé':0.4,'Élite':0.5}
S=R.SCHEMA

def fixe_de(e):
    c=e['calc']; s=c['schema']; f=dict(S[s])
    if s=='compression':
        fg=FIG_COMPRESSION[e['niveau']]; f={'figures':fg,'tronc':0.65-fg,'mobilite':0.15}
    elif s in ('figure_dynamique_poussee','figure_dynamique_tirage'):
        f={'figures':0.35,'explosivite':0.15} if c['regime']=='explosif' else {'figures':0.45}
    elif s=='transition_muscle_up':
        x={'explosif':0.25,'dynamique':0.05}.get(c['regime'],0.0)
        f={'figures':0.15,'tirer':0.15,'explosivite':x}
    elif s=='gymnastique_crossfit':
        f={'endurance_force':0.30,'anaerobie':0.15,'figures':0.10}
    elif s=='sprint':
        f={'explosivite':0.4,'anaerobie':0.4}
    elif s=='poussee_verticale_haute' and c['type_charge']=='poids_du_corps' and 'hspu' in e['id']:
        f={'figures':0.10 if 'mur' in e['materiel'] else 0.25}
    return f

def qual_muscle(m, s):
    if s in TIRAGE_CTX and m in EXT_EN_TIRAGE: return {'tirer':1.0}
    return {R.MUSCLE[m]:1.0}

def vecteur_propre(e):
    c=e['calc']; s=c['schema']; fixe=fixe_de(e)
    v=[0.0]*10
    for q,w in fixe.items(): v[R.Q[q]]+=w
    reste=1-sum(fixe.values())
    if reste>1e-9:
        if s in R.FORCE or s in R.SCHEMAS_TRONC or s=='porte':
            if c['type_charge'] in ('poids_du_corps','aucune'):   # R3 : élastique exclu
                if c['unite']=='repetitions' and c['regime'] in ('dynamique','excentrique','explosif'): part=R.ENDURANCE_PDC[e['niveau']]
                elif c['unite']=='secondes' and s in R.SCHEMAS_TRONC: part=R.ENDURANCE_ISO_TRONC
                else: part=0.0
                v[5]+=reste*part; reste*=1-part
        masses=[0.0]*4
        for poids,liste in ((1.0,e['muscles_principaux']),(0.5,e['muscles_secondaires']),(0.25 if s in STAB_CTX else 0.0,e.get('muscles_stabilisateurs',[]))):
            if not poids: continue
            for m in liste:
                if m not in R.MUSCLE: continue
                if liste is e.get('muscles_stabilisateurs') and R.MUSCLE[m]!='tirer': continue
                for q,w in qual_muscle(m,s).items(): masses[R.Q[q]]+=poids*w
        t=sum(masses) or 1.0
        if sum(masses)==0: masses=[0.25]*4
        for i in range(4): v[i]+=reste*masses[i]/t
    return v

def type_de(e):
    c=e['calc']
    if c['schema']=='gymnastique_crossfit' and c['unite']=='repetitions': return 'reps'
    t=R.type_de(e)
    if t=='tenue' and c['regime'] not in ('isometrique','passif'): return 'wod'
    if t=='charge' and c['type_charge']=='autre' and (c['schema']=='pliometrie' or 'pince de préhension' in e['materiel']): return 'reps'
    return t

ORDRE_SCHEMA={'equilibre_mains':['poignet','epaule','coude'],'figure_statique_poussee':['coude','poignet','epaule'],
              'pliometrie':['genou','cheville'],'sprint':['cheville','genou'],'corde_a_sauter':['cheville','genou'],
              'balistique':['lombaires','hanche'],'charniere_hanche':['lombaires','hanche'],'halterophilie':['poignet','genou','epaule']}
BONUS_BRAS_TENDUS={'Débutant':0.0,'Intermédiaire':0.1,'Avancé':0.2,'Élite':0.2}
def tendon_de(e):
    c=e['calc']; s=c['schema']
    ordre=ORDRE_SCHEMA.get(s,[])+[z for z in R.ORDRE_ZONES if z not in ORDRE_SCHEMA.get(s,[])]
    zone=None; n=0.0
    for z in ordre:
        x=R.NIVEAU_CONTRAINTE[c['contraintes'][z]]
        if x>n+1e-12: n=x; zone=z
    if s in R.SCHEMAS_BRAS_TENDUS: n+=BONUS_BRAS_TENDUS[e['niveau']]
    if c['regime']=='excentrique': n+=0.1
    impact = not (set(e['materiel'])&ERGO) and (s!='pliometrie' or sum(1 for m in e['muscles_principaux'] if R.MUSCLE.get(m)=='jambes')*2>=len(e['muscles_principaux']))
    if s in R.SCHEMAS_SAUTS and impact and n<0.7:
        n=0.7; zone=('cheville' if s!='pliometrie' else 'genou') if zone in (None,'coude','epaule','poignet') else zone
    if c['type_charge']=='lest' and s in ('tirage_vertical','poussee_verticale_basse','transition_muscle_up'): n+=0.1
    if c['assiste']: n=max(0.4,n-0.2)
    if c['regime']=='passif': n=min(n,0.4)
    n=min(n,1.0)
    if n<=0.1+1e-9: zone=None
    return round(n,2), zone

RATIO=dict(R.RATIO)
RATIO.update({'isolation_trapezes':(1.40,0.50,1.20,0.80,1.40),'balistique':(0.60,0.35,0.60,0.40,0.60),
              'prehension':(0.50,0.15,0.40,0.35,0.50),'cou':(0.25,0.10,0.30,0.20,0.25),'extension_rachis':(0.30,0.15,0.60,0.40,0.30),
              'preparation_scapulaire':(0.40,0.20,0.40,0.30,1.60)})
LEST_REL={'tirage_vertical':0.40,'poussee_verticale_basse':0.50,'poussee_horizontale':0.40,'transition_muscle_up':0.15,'fente':0.30,'tirage_horizontal':0.35}
HALTERO_RACINE={'mu-arrache':0.78,'mu-epaule':1.00,'mu-epaule-jete':0.95,'mu-push-press':0.85,'mu-overhead-squat':0.85,'cf-thruster-barre':0.75,'cf-sdhp-barre':0.85}
HALTERO_MOT={'muscle':0.70,'power':0.85,'tirage':1.10,'high-pull':1.0}
UNI_SCHEMAS=('poussee_horizontale','poussee_inclinee','poussee_verticale_haute','tirage_vertical','tirage_horizontal','squat','charniere_hanche','extension_genou','flexion_genou','isolation_biceps','isolation_triceps','isolation_dos','extension_hanche','adducteurs_abducteurs')
def ratio_de(e):
    c=e['calc']; s=c['schema']; tc=c['type_charge']
    col=0 if 'Smith machine' in e['materiel'] else R.COLONNE[tc]
    r=RATIO.get(s,R.RATIO_DEFAUT)[col]
    if s=='halterophilie' and tc=='barre':
        r=HALTERO_RACINE.get(c['racine'],0.85)
        for k,f in HALTERO_MOT.items():
            if k in e['id']: r*=f
    if s=='prehension' and 'extenseurs du poignet' in e['muscles_principaux']: r*=0.6
    if tc=='lest' and c['fraction_pdc'] and s in LEST_REL: r=c['fraction_pdc']['valeur']+LEST_REL[s]
    if c['lateralite']=='unilateral' and col in (0,2,3) and s in UNI_SCHEMAS: r*=0.55
    if c['regime']=='excentrique' and tc in ('lest','barre','machine'): r*=1.25
    return round(r,2)

def generer():
    propres={i:vecteur_propre(e) for i,e in E.items()}; out={}
    for i,e in E.items():
        c=e['calc']; v=propres[i]; rac=c['racine']
        if e['variante_de'] and rac in E and rac!=i and E[rac]['calc']['schema']==c['schema']:
            v=[(1-R.PART_RACINE)*a+R.PART_RACINE*b for a,b in zip(v,propres[rac])]
        s=sum(v); v=[round(x/s,4) for x in v]; k=max(range(10),key=lambda j:(v[j],-j)); v[k]=round(v[k]+1-sum(v),4)
        t=type_de(e); td,z=tendon_de(e)
        out[i]={'type':t,'vecteur':v,'tendon':td,'zone_tendon':z,'ratio':ratio_de(e) if t=='charge' else None,'schema':c['schema']}
    return out
apres=generer()
if __name__=='__main__':
    from verdicts import V as VER
    AB=['pou','tir','jam','tro','fig','end','exp','aer','ana','mob']
    f=lambda x:' '.join(f"{AB[k]}{v:.2f}" for k,v in enumerate(x['vecteur']) if v>=0.1)
    print('sommes ok:', all(abs(sum(x['vecteur'])-1)<1e-6 for x in apres.values()), 'min', min(min(x['vecteur']) for x in apres.values()))
    ch=collections.Counter()
    for i in E:
        a,b=avant[i],apres[i]
        if a['type']!=b['type']: ch['type']+=1
        if max(abs(x-y) for x,y in zip(a['vecteur'],b['vecteur']))>0.05: ch['vecteur(>0,05)']+=1
        if a['tendon']!=b['tendon']: ch['tendon']+=1
        if a['zone_tendon']!=b['zone_tendon']: ch['zone']+=1
        if a['ratio']!=b['ratio']: ch['ratio']+=1
    print('exercices modifiés sur 1039 :', dict(ch))
    for i,(v,c) in VER.items():
        if v in ('X','m'):
            a,b=avant[i],apres[i]
            print(f"{v} {i}\n   avant: {a['type']} [{f(a)}] t={a['tendon']}/{a['zone_tendon']} r={a['ratio']}\n   après: {b['type']} [{f(b)}] t={b['tendon']}/{b['zone_tendon']} r={b['ratio']}")
    for i in ['mu-developpe-couche-barre','sw-traction-pronation','cs-planche','cs-front-lever','cf-burpee','mu-back-squat-barre-basse','mu-epaule','mu-bench' if 'mu-bench' in E else 'mu-developpe-couche-halteres']:
        print('témoin',i,f(avant[i]),'->',f(apres[i]),avant[i]['ratio'],'->',apres[i]['ratio'])
```
