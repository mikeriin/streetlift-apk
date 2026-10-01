# Livraison G8 — moteur dynamique `kalis_adapt` 0.1.0 (piste M)

01/10/2026 — Fable 5.1, effort maximal (tâche A). Branche `moteurs`, commit `78c131a`
(« Kalis Track moteurs (G8) : kalis_adapt 0.1.0 »). Contrôle : run `ci-paquets` n° 36921102890 vert sur
`claude/ci-gp-moteurs` (formatage, `dart analyze --fatal-infos` sans remarque, tests de `kalis_core`,
`kalis_plan` et `kalis_adapt`, campagne de simulation). Rien ne change dans `lib/` de l'application.

**Étiquettes** (branches fixes, le push d'étiquettes étant refusé aux sessions) :
`etiquettes/kalis_adapt-v0.1.0` et `etiquettes/kalis_core-v0.2.0`, toutes deux sur `78c131a`.
Récupération par un lot de la piste A : `git fetch origin etiquettes/kalis_adapt-v0.1.0` puis
`git checkout FETCH_HEAD -- packages/kalis_adapt packages/kalis_core` (`kalis_plan` 0.1.0 inchangé).

## Ce qui est livré

| Élément | Où |
| --- | --- |
| `KalisAdapt implements AdaptEngine` : `prescribeSession`, `adviseNextSet`, `review` ; `estimates`, `applyProposal` — Dart pur, sans horloge ni entrée-sortie, le journal est rejoué à chaque appel | `packages/kalis_adapt/lib/` |
| Modèle individuel : un filtre de Kalman par exercice (capacité à la plage travaillée, tendance, forme de la courbe répétitions ↔ charge, effet de jour), séries lues comme mesures ou comme bornes, fatigue dans la séance, forme et fatigue entre les séances, forme du jour, notes peu informatives, partage entre exercices proches | `lib/src/filter.dart`, `model.dart`, `fatigue.dart`, `rater.dart` |
| Décisions : charge à hystérésis sur la grille réelle du matériel, plafonds de hausse, calibrage, séries notées « 5 et plus », conseil pendant la séance (écart de 2 flammes), série repère, bilan santé gradué, douleur, lieu et temps du jour, programme importé, tests | `lib/src/session.dart`, `advise.dart` |
| Revue : résumé d'adaptation, propositions (volume, décharge, échange, épargne d'une zone, restructurations par `kalis_plan`) filtrées par déblocage, confiance et utilité, records, journal du moteur | `lib/src/review.dart` |
| Simulateur d'athlètes à vérité connue, quatre politiques (kalis_adapt, double progression, L7/L11, oracle) | `lib/simulation.dart`, `tool/l7/` |
| Lignes de commande `dart run kalis_adapt:simulate --athlete <json\|nom> --weeks 24 --seed <n>` et `dart run kalis_adapt:replay --journal <json>` ; campagne `bin/kalis_adapt_cli.dart --rapport <dossier>` | `bin/` |
| Contrat : API, modèle et équations, décisions, les paramètres (51 lignes) avec leur source (référence, mesure ou hypothèse), invariants testés, 15 limites, registre de validation, 33 références | `CONTRAT.md` |
| Validation | `docs/VALIDATION.md` (lecture), `docs/MESURES.md` (tableaux de la campagne), `docs/PROPRIETAIRE.md` (rejeu de ton programme importé sur un journal simulé) |
| `kalis_core` 0.2.0, additif : `AdviceRequest.healthCheck` (optionnel), 8 codes de raison ajoutés (75) | `packages/kalis_core/` |

## Résultats (campagne : 8 athlètes simulés × 24 semaines × 200 graines × 4 politiques)

**La cible « écart au RIR visé ≤ 1 » n'est pas atteinte.** Elle est approchée pour l'athlète avancé
(1,03) et manquée pour les autres ; le moteur fait 1,5 à 3,6 fois mieux que les deux références et reste
à une répétition de l'oracle (qui connaît la vérité).

| Athlète simulé | Écart au RIR, kalis_adapt | Double progression | L7/L11 | Oracle | Échecs non prévus, kalis_adapt | Double progression | L7/L11 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| débutant en salle | 1,30 | 1,96 | 3,48 | 0,25 | 0,97 % | 6,67 % | 7,23 % |
| intermédiaire en salle | 1,21 | 2,67 | 3,93 | 0,26 | 0,86 % | 3,70 % | 4,14 % |
| avancé street lifting | 1,03 | 2,03 | 2,59 | 0,24 | 0,65 % | 4,74 % | 5,64 % |
| notes paresseuses | 1,34 | 2,59 | 4,46 | 0,29 | 0,93 % | 0,21 % | 0,37 % |
| irrégulier | 1,19 | 2,53 | 3,57 | 0,28 | 0,48 % | 0,25 % | 0,60 % |
| haltères à la maison | 1,72 | 3,37 | 6,18 | 0,32 | 0,84 % | 2,34 % | 2,76 % |
| calisthénie au parc | 1,20 | 3,54 | 3,54 | 0,32 | 0,06 % | 0,00 % | 0,00 % |
| douleur et lieu | 1,19 | 2,12 | 3,33 | 0,27 | 0,62 % | 4,82 % | 5,15 % |

- **Capacité des mouvements principaux** : erreur de 2,8 à 13,9 % à la première séance, 1,7 à 5,2 % à la
  troisième, 1,5 à 3,7 % à la sixième (L7/L11 : 5 à 12 % à tout moment). Calisthénie : 9 % à la sixième.
- **Sécurité** : aucune hausse de plus de 10 % franchissant plus d'un cran sur un mouvement principal ;
  aucune charge accrue sur une zone douloureuse (15,5 et 12,8 par simulation pour les références).
- **Progression** : la même que les références à 0,01 point par semaine près. Le simulateur ne permet pas
  de montrer qu'un meilleur dosage fait progresser plus vite.
- **Deux profils où les références échouent moins** (notes paresseuses, irrégulier) : elles y prescrivent
  beaucoup plus facile (écart au RIR de 2,5 à 4,5).
- **Intervalles annoncés trop étroits** : 77 à 90 % de couverture pour 95 % annoncés (56 % en
  calisthénie).
- **Déblocage** : volume semaine 2, échange semaine 4, séance semaines 5 à 7, bloc semaines 10 à 13.
- **Temps** (machine de contrôle) : décision de séance 0,06 ms en médiane, 8,4 ms au pire (cible 50 ms) ;
  mise à jour après une série 0,05 ms, 1,8 ms au pire (cible 5 ms) ; à froid, 117 séances rejouées en
  10 à 20 ms. À remesurer sur téléphone.
- **Tests** : 131 tests `kalis_adapt` dont 10 240 journaux aléatoires (invariants I1 à I8, aucun
  manquement), référence croisée du filtre (52 scénarios contre une seconde écriture en Python), huit
  athlètes en boucle complète ; 182 tests `kalis_core`, 121 tests `kalis_plan`.

## Relecture indépendante

Un second lecteur automatique a relu code, contrat et tests avant la livraison, sans pouvoir exécuter :
19 constats. Le plus grave : sur des séries enchaînées (superset A1, B1, A2…), le rejeu comptait une
séance par série et le conseil pouvait proposer une hausse après un échec — corrigé, et ces journaux sont
maintenant dans les tests de propriétés. Corrigés aussi : garde-fous des exercices sans charge, conseil
sans le bilan du jour, pivot de la courbe après un changement de plage, saisies douteuses, journal
prolongé, charge de référence, portée des échanges. Le reste est écrit comme limite
(`docs/VALIDATION.md`, § 7).

## Limites

- **Aucune donnée réelle** : les athlètes sont simulés, et le simulateur partage des hypothèses avec le
  moteur ; les valeurs absolues sont optimistes. Ton journal sera la première vraie mesure.
- **Contenu sportif non relu par un professionnel diplômé.** À faire relire en premier : la douleur de 5
  à 6/10 sur une contrainte moyenne (exercice gardé sans hausse), les paliers du bilan santé, l'ordre de
  coupe quand le temps manque.
- Exercice au poids du corps trop facile pour sa plage : le moteur étend les répétitions mais ne peut pas
  atteindre le RIR visé ; la variante plus dure vient au bloc suivant.
- Exercice lesté : +10 % de charge totale peut être +30 % de lest.
- Un échec saisi par erreur reste un échec pour le garde-fou : il faut écarter la série.
- La forme du jour affichée peut rester basse sous un gros volume régulier sans baisse de performance.
- Restructuration de séance et épargne durable d'une zone : jamais émises dans la campagne (déclencheur
  absent du simulateur, ou `kalis_plan` ne trouve rien à changer) ; exercées seulement par les journaux
  aléatoires.
- Grille des charges : comptée à partir de la plus petite charge ici, à partir de zéro dans `kalis_plan`
  0.1.0 (sans effet avec les grilles par défaut).

## Pour les lots suivants

- **G9** (séance dans l'application) : redonner le bilan du jour à `adviseNextSet`
  (`AdviceRequest.healthCheck`) ; enregistrer les séries dans l'ordre de réalisation avec `slotId` et
  `exerciseOrder` ; garder la même instance du moteur d'un appel à l'autre ; mesurer les temps sur
  téléphone ; les textes viennent des codes de raison.
- **G10** : `review` rend propositions, records et journal du moteur ; `applyProposal` applique.
- **G11** (`kalis_quest`) : les capacités estimées et les records sont dans `AdaptReview`.

## Suite

G11 (`kalis_quest`) : lancé par ce lot sur la tâche Fable B le 01/10/2026.
