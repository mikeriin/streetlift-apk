# Validation de kalis_plan 0.1.0

Ce document dit ce qui a été vérifié, comment, ce que les vérifications ont fait corriger, et ce qui
reste à valider. Les chiffres viennent de `docs/MESURES.md` (relevé du simulateur, catalogue 1.1.0,
règles 1.1.0) ; les programmes sont dans `docs/PROFILS_TYPES.md` et la comparaison à l'ancien générateur
dans `docs/COMPARAISON_L10.md`. Ces trois fichiers sont produits par le moteur ; `test/docs_test.dart`
échoue si les deux premiers ne correspondent plus au moteur.

**Ce que cette validation n'est pas.** Aucun professionnel diplômé (entraîneur, kinésithérapeute, médecin
du sport) n'a relu le contenu sportif ni les programmes. La lecture des programmes a été faite par
l'auteur du lot, un assistant, avec les références citées dans `CONTRAT.md` § 11. Les temps sont ceux de
la machine du contrôle (un cœur d'un serveur d'intégration), pas ceux d'un téléphone.

## 1. Méthode

Le paquet n'a pas pu être exécuté sur le poste de travail du lot (pas de SDK Dart, téléchargements
bloqués). Tout a tourné dans le contrôle `ci-paquets.yml` : formatage, analyse statique sans aucune
remarque tolérée, tests, puis simulateur (`dart run bin/kalis_plan_cli.dart --rapport <dossier>`).

Quatre vérifications se complètent :

1. **Tests de propriétés** sur 10 240 profils aléatoires seedés (huit fichiers `test/properties_<n>_test.dart`
   de 1 280 profils, `lib/testing.dart` pour le tirage) : contraintes dures, déterminisme, verrous, diff
   minimal, variantes, passe 2, blocs.
2. **Profils types** : les 40 profils de kalis_core, chacun déroulé en entier (passe 1, les quatre actions
   de revue, variantes, « Autre proposition », passe 2, bloc suivant, restructuration) et **lu**.
3. **Mesures** : temps, convergence de la recherche, sensibilité aux poids, non-ressemblance au programme
   du propriétaire.
4. **Comparaison** à l'ancien générateur (L10) sur les mêmes 40 profils.

Chaque contrainte dure est vérifiée deux fois par deux codes différents : par le moteur quand il
construit, puis par `PlanInspector.hardViolations`, qui relit le programme rendu sans rien savoir de la
recherche. Les tests n'utilisent que le second.

## 2. Lecture des 40 profils types

Résultat final : **0 contrainte dure violée**, note de 0,918 à 0,976 (moyenne 0,958), aucune séance plus
longue que le temps donné. La lecture a porté sur les exercices de chaque séance, leur ordre, les séries
de la passe 2 et les raisons affichées. Elle a fait corriger la note à plusieurs reprises, parce qu'un
optimiseur exploite toute faille de la note qu'on lui donne :

| Constat à la lecture | Cause | Correction |
| --- | --- | --- |
| Séances de renforcement sans mouvement de base, faites de gainage et d'isolation | L'exigence d'un mouvement de base exemptait les séances « de tronc » et les séances courtes | Un mouvement de base est attendu sur un nombre de séances fixé par la part de renforcement, sans exemption |
| Bandes de volume « remplies » par des planches | Le gainage créditait ses muscles secondaires | Aucun crédit secondaire pour les exercices de tronc |
| Programmes courts arrêtés très tôt | Le haut de bande, réduit au temps disponible, devenait minuscule | Plancher de 5 séries pour le haut de bande |
| Une séance vidée au profit des autres une fois le volume atteint | Le temps utilisé ne regardait que la moyenne | Terme d'équilibre entre la séance la plus courte et la plus longue |
| Refus d'ajouter un exercice utile | La moyenne d'adéquation baissait à chaque ajout | Dénominateur : le nombre d'emplacements attendu pour la durée |
| Volume gonflé par le conditionnement et le cardio | Ils créditaient des séries aux muscles | Aucun crédit de volume hors renforcement |
| Figures et mouvements lourds dépassant 20 séries sur plusieurs groupes | Les séries de pratique (technique, loin de l'échec) comptaient comme des séries dures | Séries de pratique comptées pour moitié — hypothèse signalée, `CONTRAT.md` § 9 |
| Flexions de poignet chez des pratiquants de musculation ou de forme générale | Rien ne réservait le travail direct des avant-bras | Réservé aux disciplines de barre, sauf exercice su, aimé ou lié à un objectif |
| Course à pied proposée en mode prudent | Seul l'impact « explosif » était exclu | Mode prudent : cardio sans appui contraignant pour la cheville |
| Exercices assistés proposés à quelqu'un qui fait la version complète | La règle « trop facile » ne s'appliquait pas à tous | Appliquée à tous les profils |

Ce qui reste discutable après lecture est écrit comme limite dans `CONTRAT.md` § 9 : choix du mouvement
« principal », absence de découpage imposé, formats du CrossFit, petits groupes sous leur bande quand le
matériel manque, séance unique de 20 minutes sans tous les schémas de base, séances de l'élite en
calisthénie plus courtes que le temps donné (62 % du temps utilisé).

## 3. Tests de propriétés

10 240 profils aléatoires, 0 échec à la livraison. Les propriétés : aucune contrainte dure violée
(discipline, exclusions, niveau, prérequis, exercices réservés, mode prudent, matériel, gêne
articulaire, temps, aucune séance vide, verrous) ; même requête, même programme, octet pour octet, sur deux moteurs neufs ; la note relue par
l'inspecteur égale la note annoncée ; une action de revue ne fait jamais moins bien que l'action seule ;
ce qui est verrouillé ne bouge pas ; les variantes sont admissibles et triées ; la passe 2 respecte
plages, charges (multiples du pas, au plus 90 % de la charge d'Epley), flammes de 1 à 10 ; le bloc
suivant et la restructuration restent valides.

Défauts trouvés par ces tests et corrigés avant livraison :

| Défaut | Correction |
| --- | --- |
| Après `can_do`, la note annoncée différait de la note relue | Note recalculée avec le profil mis à jour |
| Un `remove` pouvait faire pire que le retrait seul : l'exclusion valait pour toute la semaine et la réparation dépouillait d'autres jours | Exclusion limitée au jour visé |
| Séances vides quand une limitation rend la discipline impraticable ; division par zéro en aval | Séance de repli (mobilité et marche, puis tout exercice admissible), signalée dans le programme |
| Exercices de repli vus comme inadmissibles par l'inspecteur | Le repli fait partie du vivier, en dernier recours |
| Charge de 0 kg refusée par le test | Erreur du test : 0 kg est une charge valide (poids du corps) |
| Le test du diff comptait un déplacement comme deux changements | Erreur du test, corrigée |

Sur une population distincte de 1 000 profils (`docs/MESURES.md`, § 3) : 0 programme invalide, 2 avec une
séance de repli. La note va de 0,734 à 0,977 (médiane 0,932) ; les notes basses sont des profils que le
tirage rend presque impossibles (une discipline, peu de matériel, plusieurs gênes fortes) : l'erreur de
dosage y atteint 100 points quand aucune séance de la discipline demandée n'est admissible. Ce cas est
couvert par la séance de repli, pas résolu.

## 4. Non-ressemblance au programme du propriétaire

**Règle (D4.1).** Le programme personnel du propriétaire n'est lu par aucun moteur ; il ne sert qu'à ce
test. Un programme généré ne doit pas lui ressembler, y compris pour le profil du propriétaire lui-même.

**Mesure.** Indice de Jaccard entre les exercices de la semaine type générée et ceux de la semaine du
propriétaire la plus proche (40 semaines, 45 exercices du catalogue).

**Seuil : 0,30, justifié par une mesure.** Le programme du propriétaire comparé à lui-même, entre
semaines de blocs différents, donne un minimum de 0,21, un premier décile de 0,30 et une médiane de 0,60.
Le seuil est ce premier décile : un programme généré doit ressembler au sien moins que neuf fois sur dix
ses propres blocs ne se ressemblent entre eux. Un seuil nul serait absurde — tout programme de
streetlifting partage tractions, dips et squat.

**Résultats** (`docs/MESURES.md`, § 8 ; testé par `test/resemblance_test.dart`) :

| Programmes générés | Nombre | Médiane | Maximum |
| --- | --- | --- | --- |
| Profil du propriétaire, graines 0 à 3 | 4 | 0,151 | 0,154 |
| Profils types street, graines 0 à 3 | 52 | 0,067 | 0,167 |
| Profils types sans street, graines 0 à 3 | 104 | 0,065 | 0,196 |
| Population aléatoire | 1 000 | 0,038 | 0,227 |

Tous sous 0,30. Séance par séance, le maximum est 0,40 (médiane 0,09) : une séance générée de quatre ou
cinq exercices peut en partager deux avec une séance du propriétaire ; aucune ne la reproduit.

**Accessoires.** Seconde question : le moteur favorise-t-il les accessoires du propriétaire chez des
gens qui ne font pas de street ? Sur les 328 profils aléatoires sans discipline street, chaque accessoire
du propriétaire est comparé à l'exercice le plus choisi de la même catégorie hors de son programme ;
« sur-représenté » veut dire choisi dans plus de 5 % des programmes et plus de deux fois plus que ce
pair. Accessoires **propres** au propriétaire (exercices des disciplines street) sur-représentés : **0**.
Un accessoire du fonds commun de la musculation dépasse la règle : `mu-mollets-debout-machine` (18,1 %
contre 4,9 % pour le meilleur pair). La cause est le catalogue, pas le programme du propriétaire : c'est
l'exercice de mollets de référence dès qu'une salle est disponible, et la catégorie offre peu de pairs
chargés. Le constat est laissé visible dans le relevé plutôt que masqué par un réglage.

## 5. Comparaison au générateur L10

**Comment.** L'ancien générateur ne tourne que sous Flutter. Il a été exécuté une fois dans le contrôle
sur les 40 profils types (test d'export archivé dans `tool/l10_export_test.dart.txt`, 0 erreur) ; ses
sorties, réduites par `tool/extraire_l10.py`, sont dans `docs/data/l10_sorties.json.gz`. Les deux côtés
sont ensuite mesurés par le même code (`lib/report.dart`) : durées estimées par chaque générateur,
séries recomptées de la même façon simple (muscle principal 1, secondaire 0,5), semaine 3 de L10 face à
la dernière semaine de montée.

**Résultat.**

| Critère | L10 | kalis_plan | Lecture |
| --- | --- | --- | --- |
| Profils dont chaque discipline a un programme | 9 sur 40 | 40 sur 40 | Mieux |
| Erreur de dosage, moyenne (34 profils) | 23,8 points | 0,4 point | Mieux |
| Profils à 10 points ou moins de leur dosage | 14 sur 34 | 34 sur 34 | Mieux |
| Séances plus longues que le temps donné | 33 sur 143 | 0 sur 143 | Mieux |
| Temps donné utilisé | 91 % | 95 % | Mieux |
| Tirage et poussée équilibrés | 21 sur 27 | 24 sur 27 | Mieux |
| Chaîne postérieure et genou équilibrés | 13 sur 27 | 26 sur 27 | Mieux |
| Exercices à contrainte maximale sur une articulation gênée | 0 | 0 | Égal |
| Groupes majeurs sous 4 séries par semaine, par profil | 0,7 | 0,8 | **Écart, expliqué ci-dessous** |
| Groupes majeurs au-dessus de 20 séries par semaine, par profil | 1,5 | 2,3 | **Écart, expliqué ci-dessous** |

**Écart 1 — groupes sous 4 séries (0,8 contre 0,7).** kalis_plan fait moins bien sur dix profils et
mieux sur huit (détail par profil dans `docs/COMPARAISON_L10.md`). Les profils où il fait moins bien sont
ceux sans salle (parc, maison, kettlebell), ceux de figures, le mode prudent (5 groupes contre 2 : trois
séries au plus par exercice, deux séances) et un profil où L10 dépasse le temps donné deux séances sur
trois. À la lecture des programmes, les groupes en cause sont surtout les mollets, les lombaires et les
ischio-jambiers quand le vivier admissible n'offre pas d'exercice qui les cible ; le relevé ne les
détaille pas groupe par groupe. kalis_plan ne dépasse jamais le temps donné, alors que L10 obtient une
partie de son volume dans des séances trop longues (33 sur 143). L'écart est réel, petit, et assumé : ne
pas forcer une isolation que le matériel ne permet pas. C'est une limite (`CONTRAT.md` § 9).

**Écart 2 — groupes au-dessus de 20 séries (2,3 contre 1,5).** Il se concentre sur les profils de
calisthénie et de street (élite en calisthénie : 9 groupes contre 0, L10 n'y utilisant que 43 % du
temps). Deux causes : kalis_plan utilise davantage le temps donné ; et ce comptage simple compte à plein
les séries de pratique (tenues de figures, mouvements lourds loin de l'échec) que le moteur compte pour
moitié ; avec ce comptage-là, tout dépassement de 20 séries est pénalisé par la note. Ce choix de comptage est une
hypothèse d'ingénierie, pas un fait établi : **c'est le premier point à faire relire par un
professionnel**. Si les séries de pratique devaient compter à plein, le paramètre se change en un endroit
(`PlanParams`) et les programmes de figures raccourciraient.

**Limites de la comparaison.** La traduction du profil vers les entrées de L10 est celle de l'auteur du
lot ; L10 ne lit ni les gênes articulaires par articulation, ni le dosage, ni les goûts. Les durées sont
celles que chaque générateur estime, non mesurées en séance. La comparaison dit que kalis_plan respecte
mieux ce que l'utilisateur a demandé ; elle ne dit pas que ses programmes font davantage progresser.

## 6. Temps de calcul

Budget : génération en 1 s au plus, régénération en 300 ms au plus. Sur la machine du contrôle :

| Opération | Profils types (médiane / maximum) | 1 000 profils aléatoires (maximum) |
| --- | --- | --- |
| Passe 1 | 56,1 ms / 115,6 ms | 253,9 ms |
| Génération complète (passes 1 et 2) | 57,4 ms / 117,6 ms | — |
| Régénération après une action de revue | 8,5 ms / 20,9 ms | 42,2 ms |
| Autre proposition | 23,6 ms / 59,8 ms | — |

La marge est d'un facteur 4 sur la génération et 7 sur la régénération dans le pire cas mesuré. Un
téléphone d'entrée de gamme est plus lent que cette machine d'un facteur inconnu : **à remesurer à
l'intégration** (G8). Si le budget était dépassé, `annealIterations` se réduit sans autre changement.

## 7. Convergence et sensibilité

**Convergence** (`docs/MESURES.md`, § 5). Objectif moyen des profils types : 1,9520 sans recuit, 1,9552
à 3 000 coups, 1,9572 à 12 000 (retenu), 1,9575 à 24 000 — où 21 profils s'améliorent et 17 se
dégradent. Au-delà de 12 000 coups le gain est de l'ordre du bruit de la recherche. Le moteur rend le
meilleur programme **trouvé** ; rien ne prouve qu'il est optimal.

**Sensibilité** (§ 6). Un poids multiplié par 0,8 ou 1,2 change plus de la moitié des exercices
(recouvrement de 0,39 à 0,52) pour un regret inférieur à 0,001 sur 2. Lecture honnête : la note définit
un large plateau de programmes à peu près équivalents ; elle garantit les propriétés mesurées (dosage,
temps, équilibre, volume), pas le choix de tel exercice plutôt que son voisin. C'est ce plateau qui
permet « Autre proposition » (92 % des propositions changent au moins un tiers des exercices pour une
note à moins de 2 % de la meilleure ; les viviers étroits — mobilité seule, marche — n'y arrivent pas
toujours), et c'est aussi pourquoi le réglage fin des poids ne mérite pas
d'effort avant une relecture professionnelle des programmes.

**Diff minimal** (§ 3). Hors de l'emplacement visé, rien d'autre ne change dans 75 % des `cannot_do`,
80 % des `dislike` et 59 % des `remove` ; en moyenne 0,5 à 0,6 changement. Le maximum observé est de 12
changements : l'exclusion d'un exercice vaut pour toute la semaine et peut obliger à rééquilibrer
plusieurs séances. Ce cas extrême est rare mais visible ; il est noté comme limite.

## 8. Ce qui reste à valider

1. Relecture du contenu sportif et d'un échantillon de programmes par un professionnel diplômé, en
   commençant par le comptage des séries de pratique (§ 5), les bandes de volume par niveau et les seuils
   de gêne articulaire.
2. Temps de calcul sur téléphone.
3. Durées de séance estimées face à des séances réelles.
4. Chiffres de Pelland et al. 2026 à recontrôler sur le texte intégral (`CONTRAT.md` § 10).
5. Traduction du profil vers L10 à faire relire si la comparaison doit être publiée.
