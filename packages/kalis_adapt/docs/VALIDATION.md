# kalis_adapt 0.1.0 — validation

Lecture des mesures de `MESURES.md` (campagne du simulateur), du rejeu du programme importé
(`PROPRIETAIRE.md`) et des tests. Écrit à la main après lecture complète des résultats ; les tableaux de
`MESURES.md` et `PROPRIETAIRE.md` sont générés, et un test vérifie qu'ils sont à jour.

**Ce que cette validation ne dit pas.** Aucune donnée réelle n'a servi : les athlètes sont simulés, et la
vérité simulée partage des hypothèses avec le moteur (§ 6). Le contenu sportif n'a pas été relu par un
professionnel diplômé. Les temps de calcul viennent d'une machine de contrôle, pas d'un téléphone.

## 1. Protocole

- **8 athlètes simulés** (le lot en demandait 6) : débutant en salle, intermédiaire en salle, avancé de
  street lifting, notes paresseuses (reprend les flammes pré-remplies), irrégulier (séances manquées,
  coupures), haltères à la maison (gros crans), calisthénie au parc (sans charge), douleur et changement
  de lieu. Chacun a une capacité vraie par exercice, une courbe répétitions ↔ charge propre, un bruit et
  un biais de note, un effet de jour, une réponse à l'entraînement et à la fatigue.
- **24 semaines × 200 graines × 4 politiques** à programme égal (les blocs de `kalis_plan`, les mêmes pour
  toutes) : `kalis_adapt` ; la double progression simple ; l'ancien moteur L7/L11 (copie figée dans
  `tool/l7/`) ; l'**oracle**, qui connaît la vérité et donne le plancher que la grille des charges et
  l'arrondi des répétitions imposent. Les politiques reçoivent les mêmes aléas : les différences sont
  appariées, graine par graine.
- **Boucle complète** : 40 graines par athlète où la revue de fin de semaine est appliquée (mode assisté)
  et où `kalis_plan` construit le bloc suivant à partir du résumé.
- Mesures après calibrage (à partir de la quatrième séance d'un exercice), hors semaines de test.
  Intervalles : ± 1,96 erreur standard entre graines.

Reproduire : `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` (6 minutes sur 4 cœurs) ; une
simulation : `dart run kalis_adapt:simulate --athlete avance_street --weeks 24 --seed 3`.

## 2. Écart au RIR visé : la cible d'une répétition n'est pas tenue

Cible du lot : écart absolu moyen au RIR visé ≤ 1 après calibrage.

| Athlète | kalis_adapt | Double progression | L7/L11 | Oracle | Séries à cible atteignable |
| --- | --- | --- | --- | --- | --- |
| débutant en salle | 1,30 ± 0,03 | 1,96 | 3,48 | 0,25 | 96 % |
| intermédiaire en salle | 1,21 ± 0,03 | 2,67 | 3,93 | 0,26 | 92 % |
| avancé street lifting | 1,03 ± 0,02 | 2,03 | 2,59 | 0,24 | 82 % |
| notes paresseuses | 1,34 ± 0,04 | 2,59 | 4,46 | 0,29 | 93 % |
| irrégulier | 1,19 ± 0,03 | 2,53 | 3,57 | 0,28 | 96 % |
| haltères à la maison | 1,72 ± 0,06 | 3,37 | 6,18 | 0,32 | 91 % |
| calisthénie au parc | 1,20 ± 0,06 | 3,54 | 3,54 | 0,32 | 49 % |
| douleur et lieu | 1,19 ± 0,03 | 2,12 | 3,33 | 0,27 | 90 % |

**La cible n'est atteinte pour aucun profil** ; l'avancé en est à 0,03. Le moteur divise l'écart par 1,5 à
3 face à la double progression et par 2,5 à 3,6 face à L7/L11 (différences appariées toutes hors de
l'intervalle, de −0,66 à −2,34 et de −1,56 à −4,46), mais il reste à une répétition de l'oracle.

Pourquoi, d'après les traces série par série :

- **Le biais est positif partout** (+0,1 à +1,1 : séries plus faciles que visé). C'est voulu en partie —
  la marge de prudence — et subi pour le reste : une note d'une flamme (« 5 et plus ») ne dit la capacité
  que par le bas, et un débutant ou un utilisateur d'haltères passe des semaines à des charges que la
  grille ne permet pas d'ajuster finement.
- **Haltères à la maison** (1,72 ; biais +1,12) : entre deux haltères, la charge change de 10 à 50 % ; la
  progression passe par les répétitions, jusqu'à 30, et l'écart au RIR se creuse en haut de plage.
- **Notes paresseuses** : sans charge 1,75, chargé 1,24. Les notes n'apprennent rien ; la série repère ne
  s'applique pas aux tenues et pèse peu sur les exercices sans charge.
- **Loin de l'échec, la note elle-même est bruitée** d'environ deux répétitions à 4 RIR (Zourdos et al.
  2021 ; Halperin et al. 2022), et l'effet de jour vaut plus d'une répétition sur une série de 12 : une
  seule série ne peut pas être prescrite à mieux qu'une répétition près sans la connaître d'avance.

**Séries à cible non atteignable.** Sur toutes les séries, l'écart monte (1,35 à 1,84, et 3,11 en
calisthénie) : un exercice au poids du corps trop facile pour sa plage ne peut pas être mis au RIR visé
par les répétitions seules. L'oracle lui-même est à 2,93 en calisthénie. C'est au bloc suivant, par
`kalis_plan`, de proposer une variante plus dure.

**Boucle complète** (40 graines) : 1,04 à 1,50 ; même lecture.

## 3. Capacité : convergence et intervalles

Erreur relative de la capacité opérationnelle (celle qui sert à prescrire), tous exercices :

| Athlète | Séance 1 | Séance 3 | Séance 6 | Séance 12 | Couverture de l'intervalle à 95 % |
| --- | --- | --- | --- | --- | --- |
| débutant en salle | 12,7 % | 6,2 % | 5,9 % | 4,3 % | 86 % |
| intermédiaire en salle | 12,3 % | 5,7 % | 4,6 % | 3,7 % | 89 % |
| avancé street lifting | 10,4 % | 6,6 % | 5,6 % | 4,9 % | 84 % |
| notes paresseuses | 12,2 % | 7,3 % | 5,0 % | 2,4 % | 88 % |
| irrégulier | 10,4 % | 5,6 % | 4,8 % | 2,2 % | 90 % |
| haltères à la maison | 15,5 % | 9,5 % | 8,5 % | 7,5 % | 77 % |
| calisthénie au parc | 24,8 % | 20,6 % | 18,7 % | 15,4 % | 56 % |
| douleur et lieu | 11,9 % | 4,6 % | 3,8 % | 3,8 % | 89 % |

- **Mouvements principaux** : 1,5 à 3,7 % à la sixième séance (9,0 % en calisthénie), 1,3 à 3,1 % à la
  douzième (7,8 % en calisthénie). L7/L11, qui part d'un niveau déclaré et n'apprend presque pas, reste à 5 à 12 %.
- **À la première séance, L7/L11 n'est pas moins bon** sur les mouvements principaux, les seuls qu'il
  estime : 5,8 à 13,7 %, contre 2,8 à 13,9 % (meilleur pour le débutant et l'athlète douloureux, moins bon
  pour l'intermédiaire et l'avancé). Les deux partent du niveau déclaré. Dès la troisième séance
  `kalis_adapt` est devant partout (1,7 à 5,2 % contre 5,4 à 12,1 %).
- **Le 1RM converge moins bien que la capacité opérationnelle** (4,5 à 9,4 % à la douzième séance) : la
  forme de la courbe d'une personne n'est apprise que par les séries qui la mesurent. C'est sans effet
  sur les prescriptions, qui se font à la plage travaillée ; cela compte pour l'affichage d'un 1RM estimé
  et après un changement de plage.
- **Les intervalles annoncés sont trop étroits** : 77 à 90 % de couverture pour 95 % annoncés, 56 % en
  calisthénie. Les exercices jamais poussés près de l'échec ne sont connus que par le bas (bornes), et le
  filtre resserre quand même son intervalle. Conséquence pratique : la confiance affichée est optimiste
  pour ces exercices. Défaut connu, non corrigé dans cette version (limite 3 du contrat).

## 4. Sécurité, échecs, stabilité, progression

- **Échecs non prévus** : 0,06 à 0,97 % des séries, contre 0 à 6,7 % (double progression) et 0 à 7,2 %
  (L7/L11). Pour les deux athlètes qui notent mal ou s'entraînent peu (notes paresseuses, irrégulier),
  les deux références échouent moins (0,2 à 0,6 %) parce qu'elles prescrivent beaucoup plus facile (écart
  au RIR de 2,5 à 4,5) : moins d'échecs, pas plus de justesse.
- **Quasi-échecs** (série finie à moins d'une demi-répétition de l'échec quand la cible en laissait deux) :
  0,08 à 2,3 %.
- **Hausses de charge des mouvements principaux** : aucune hausse de plus de 10 % franchissant plus d'un
  cran sur les 1 600 simulations de `kalis_adapt` ; les hausses de plus de 10 % en un seul cran (409 chez
  le débutant, 962 aux haltères) sont l'exception écrite au contrat — le plus petit cran du matériel
  dépasse 10 %. Depuis cette version la mesure est faite sur le journal seul, de la même façon pour
  toutes les politiques : L7/L11 franchit plusieurs crans jusqu'à 352 fois selon l'athlète ; l'oracle aussi
  (il n'a pas de plafond) ; la double progression jamais, par construction.
- **Douleur** : aucune charge accrue sur une zone signalée (0,00 par simulation), contre 15,5 (double
  progression) et 12,8 (L7/L11).
- **Stabilité** : 27 à 62 changements de charge de première série en 24 semaines, moins que les
  références (39 à 121) ; 41 à 64 % défont le précédent. C'est élevé : sur une grille à crans, la charge
  « juste » oscille entre deux crans, et l'oracle lui-même en défait 65 à 74 %.
- **Progression** : pas de différence utile. Le gain hebdomadaire de capacité vraie est le même à 0,01
  point près pour toutes les politiques (0,04 en calisthénie, où le moteur étend les répétitions). Le
  simulateur récompense le volume fait près de l'échec de façon douce ; il ne peut pas montrer qu'un
  écart au RIR plus petit fait progresser plus vite, et ce lot ne le prétend pas.

**Invariants** : `CONTRAT.md`, § 7 — 10 240 journaux aléatoires, aucun manquement.

## 5. Boucle complète, programme importé, temps

**Déblocage** : volume à la semaine 2, échange à la semaine 4, restructuration de séance aux semaines 5 à
7, de bloc aux semaines 10 à 13 (40 simulations sur 40 par athlète).

**Propositions émises** en 24 semaines, par simulation : volume 0,1 à 4,5 ; décharge 0 à 1,5 (avancé) ;
échange 0,3 à 2,9 ; proposition de volume inversée dans les six semaines : 0 à 1,7 %.

**Ce qui n'est jamais émis dans la campagne, et pourquoi** (tableau « candidates retenues ») :

- restructuration d'une séance : son déclencheur — temps insuffisant trois fois sur quatre — n'existe pas
  chez les athlètes simulés ; ce chemin n'est exercé que par les journaux aléatoires ;
- restructuration du bloc : candidate chez l'irrégulier (6 par simulation), retenue 1,6 fois faute de
  déblocage et 4,5 fois parce que `kalis_plan` rend un bloc inchangé pour ce motif ;
- épargne d'une zone : candidate 3 fois par simulation chez l'athlète douloureux, retenue parce que
  `kalis_plan` ne trouve rien à changer (2,9) ou déborde de la zone (0,1). La douleur est traitée séance
  par séance (exercice remplacé ou retiré, aucune hausse) ; la proposition durable reste à exercer ;
- échange d'exercice : 0,1 à 1,5 candidate par simulation est retenue parce que le changement rendu
  touchait d'autres emplacements (`scope`).

**Programme importé du propriétaire** (`PROPRIETAIRE.md`) : programme de 40 semaines importé sans changer
sa structure, journal simulé de 11 semaines (athlète avancé, graine 0 — ce n'est pas un vrai journal).
Relu : 39 capacités estimées, aucune proposition de restructuration, séance de la semaine 12 prescrite
avec ses charges. À relever dans ce rejeu :

- la traction lestée passe de 27,5 à 36,25 kg de lest d'une séance à l'autre : +8,8 % de charge totale
  pour 71,5 kg de poids de corps (dans le plafond) mais +32 % de lest (limite 12 du contrat) ;
- la forme du jour rendue vaut de 0,43 à 0,71 sur les huit dernières séances, pour des résidus de
  performance de −2 % à 0 : le gros volume régulier de ce programme tient la forme affichée basse
  (limite 5 du contrat) ;
- 223 exercices du programme ne sont pas portés dans la fixture (sans correspondance au catalogue, ou
  format hors plage : montées en singles, tours, EMOM) ; ils seraient rendus tels quels.

**Temps de calcul** (machine de contrôle Linux, 4 cœurs, code compilé à la volée) :

| Opération | Médiane | 99ᵉ centile | Maximum | Cible du lot |
| --- | --- | --- | --- | --- |
| Décision de séance | 0,06 ms | 5,1 ms | 8,4 ms | ≤ 50 ms |
| Mise à jour après une série | 0,05 ms | 0,13 ms | 1,8 ms | ≤ 5 ms |
| Décision de séance à froid (117 séances rejouées) | 10 ms | 20 ms | 20 ms | — |

Les cibles sont tenues avec une marge de 6 à 40 sur cette machine ; un téléphone modeste est plusieurs
fois plus lent, et un journal de plusieurs années rallonge le rejeu à froid (linéaire en séances). À
mesurer sur l'appareil au lot d'intégration.

## 6. Ce que vaut le simulateur

La vérité simulée a été écrite pour ce lot, par le même auteur que le moteur.

- **Différent du moteur** : courbe répétitions ↔ charge exponentielle (celle du moteur est hyperbolique),
  note en flammes arrondie avec bruit et biais propres à l'athlète, gains selon la dose et la proximité de
  l'échec, séances manquées, douleurs, lieux.
- **Partagé avec le moteur** : sensibilités à la fatigue aiguë et accumulée, forme de la fatigue entre
  les séries et son plafond, poids d'effort d'une série, désentraînement après 21 jours, part commune de
  l'effet de jour. L'effet de jour simulé (écart-type de 2 à 3 %) est plus petit que celui que le moteur
  suppose (3,5 %).
- **Biais connus des mesures** : l'athlète simulé arrête sa série quand il se sent 1,5 répétition sous la
  cible, ce qui tient les échecs bas pour toutes les politiques ; « cible atteignable » reprend les
  règles d'extension de plage du moteur et dépend du RIR affiché par chaque politique ; la double
  progression est comparée sur la cible du bloc, `kalis_adapt` sur la cible qu'il affiche (relevée en
  calibrage, douleur et bilan bas).

Lecture prudente : les écarts entre politiques (facteur 1,5 à 3,6 sur l'écart au RIR, facteur 3 à 10 sur
les échecs en salle) sont assez grands pour survivre à ces biais ; les valeurs absolues de `kalis_adapt`
sont optimistes. La première vraie mesure sera le journal du propriétaire.

## 7. Relecture indépendante

Un second relecteur automatique a relu le code, le contrat et les tests avant la livraison, sans pouvoir
exécuter le code. 19 constats ; suites données :

| # | Constat | Suite |
| --- | --- | --- |
| 1 | Documents cités absents au moment de la relecture | écrits et générés ; test `docs_test` |
| 2 | Séries enchaînées : le rejeu comptait une séance par série et le conseil oubliait un échec après un autre exercice (manquement à I2) | **corrigé** : un déroulement par exercice et par séance ; journaux enchaînés ajoutés aux tests de propriétés ; `test/sessions_test.dart` |
| 3 | Conseil sans le bilan du jour : verrous de douleur et de bilan perdus | **corrigé** : verrous relus dans la séance prescrite ; testé |
| 4 | Aucun garde-fou pour les exercices sans charge | **corrigé** : plafond à la plus grande série de la dernière séance ; ajouté aux invariants |
| 5 | Pivot figé : incertitude bloquée après un changement de plage | **corrigé** : pivot déplacé (transformation exacte, mesurée) |
| 6 | Saisies aberrantes sur les échecs et les bornes | **corrigé** pour les séries manquées (mesuré) ; bornes basses laissées, limite 10 |
| 7 | Journal prolongé : ordre des dates non contrôlé avec le cache | **corrigé** ; propriété « journal donné en deux fois » |
| 8 | Charge de référence = première série ; tests plafonnés | **corrigé** : plus lourde série menée à bien ; tests sans plafond de hausse. Repartir de la charge allégée après un échec a été mesuré et écarté (écart au RIR +0,05 à +0,15) |
| 9 | I1 vérifié avec une sortie du moteur ; briques partagées | **corrigé** pour I1 (calibrage compté au journal) et I2 (charge échouée) ; briques partagées dites au contrat |
| 10 | Échange ou épargne de zone : portée « bloc » sous une étiquette plus basse | **corrigé** : autres emplacements verrouillés, changement rendu contrôlé |
| 11 | Simulateur optimiste | écrit ici (§ 6) et au contrat (limite 14) ; mesure des hausses refaite sur le journal seul |
| 12 | Grille ancrée sur zéro | **corrigé** dans ce moteur ; écart avec `kalis_plan` écrit (limite 13) |
| 13 | Programme importé au pourcentage : ajustements du jour partiels | gardé (la lettre du programme du propriétaire), écrit au contrat § 4.5 |
| 14 | Écarts entre contrat et code (sept points) | contrat aligné sur le code ; séries à charge nulle sorties du compte |
| 15 | Première série sans note | écrit (a priori large centré sur le RIR visé) |
| 16 | La référence Python suit les mêmes équations | dit au contrat (§ 7, § 9) |
| 17 | Trois détails statistiques | reprise après coupure comptée une fois (**corrigé**) ; les deux autres laissés, sans effet mesurable |
| 18 | Quatre remarques sportives | écrites en limites 5, 11, 12 ; ordre de coupe de l'échauffement gardé (il part après les accessoires, avant les mouvements secondaires) — à faire relire |
| 19 | Commentaire faux dans les mesures | corrigé |

La relecture n'a pas vérifié : les références bibliographiques, la fidélité de la copie de L7/L11,
l'ampleur des changements rendus par `kalis_plan`.

## 8. Essais écartés

Mesurés pendant la mise au point (6 à 200 graines), non retenus : série repère pour tous les
utilisateurs (échecs doublés pour 0,05 à 0,15 d'écart au RIR) ; apprentissage du biais de note individuel
(aucun gain) ; échelle individuelle de la fatigue de séance (aucun gain) ; `k` appris sur toutes les
notes (dérive) ; pivot déplacé à chaque séance (écart au RIR +0,1 à +0,2) ; charge de référence abaissée
après un échec ou une série sous la cible (+0,05 à +0,25). Détail : `CONTRAT.md`, § 6.
