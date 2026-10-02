# Livraison G11 — moteur de progression `kalis_quest` 0.1.0 (piste M, fin de piste)

02/10/2026 — Fable 5.1, effort maximal (tâche B). Branche `moteurs`, commit `d2ca8b7`
(« Kalis Track moteurs (G11) : kalis_quest 0.1.0 »). Contrôle : run `ci-paquets` n° 36945976432 vert sur
`claude/ci-gp-moteurs` (formatage, `dart analyze --fatal-infos` sans remarque, tests de `kalis_core`,
`kalis_plan`, `kalis_adapt` et `kalis_quest`, campagnes de simulation). Rien ne change dans `lib/` de
l'application.

**Étiquettes** (branches fixes, le push d'étiquettes étant refusé aux sessions) :
`etiquettes/kalis_quest-v0.1.0` et `etiquettes/kalis_core-v0.3.0`, toutes deux sur `d2ca8b7`.
Récupération par un lot de la piste A : `git fetch origin etiquettes/kalis_quest-v0.1.0` puis
`git checkout FETCH_HEAD -- packages/kalis_quest packages/kalis_core` (`kalis_plan` 0.1.0 et
`kalis_adapt` 0.1.0 inchangés).

## Ce qui est livré

| Élément | Où |
| --- | --- |
| `KalisQuest implements QuestEngine` : `evaluate(catalog, QuestInput)` rend l'état à stocker (registres d'XP et de Krédits en ajout seul, quêtes, état opaque), le niveau, les attributs, les rangs, les objectifs, les événements nouveaux, les objectifs suggérés, les records, `extras` — Dart pur, sans horloge ni entrée-sortie, hasard par la graine de l'utilisateur | `packages/kalis_quest/lib/` |
| XP : effort rapporté au programme (réalisation × qualité, combo, plafonds par séance et par semaine), régularité et repos gardé, records, jalons, quêtes ; niveaux 1 à 100 puis prestige ; Krédits | `lib/src/engine.dart`, `ledger.dart`, `level.dart`, `world.dart` |
| Six attributs et seize rangs par mouvement (Bronze → Élite) sur standards par sexe et poids de corps | `lib/src/progress.dart`, `standards.dart`, `docs/STANDARDS.md`, `docs/STANDARDS_SOURCES.md` |
| Quêtes quotidiennes, hebdomadaires, de campagne (chapitre, boss) et Koach | `lib/src/quests.dart` |
| Objectifs : jalons le long de la courbe prévue, prédiction (médiane, intervalle à 80 %), retard, suggestions à 60 % | `lib/src/goals.dart` |
| Plaisir : records, premières fois, coffres, série de semaines, fantôme, note S/A/B/C, combo, récapitulatif, comparaisons | `lib/src/engine.dart`, `extras.dart`, `docs/EXTRAS.md` |
| Simulation de rythme : 8 archétypes, journaux simulés sur les programmes de `kalis_plan` ; `dart run kalis_quest:simulate --archetype <nom> --years 3 --seed <n>` ; campagne `bin/kalis_quest_cli.dart --rapport <dossier>` | `lib/simulation.dart`, `bin/` |
| Contrat : API, formules, invariants testés, paramètres avec leur statut (mesuré, référence, repris, choix raisonné), limites, registre de validation, 20 références | `CONTRAT.md` |
| Validation | `docs/VALIDATION.md` (lecture), `docs/RYTHME.md` (tableaux de la campagne), `docs/CAS_TYPES.md` (les 12 journaux types) |
| `kalis_core` 0.3.0, additif : `SessionRecord.plannedWorkSets`, `QuestInput.claims` (`QuestClaim`), `AttributeScore.best`, champs de retard de `GoalProgress`, 5 natures d'événement, 17 codes de raison (92) | `packages/kalis_core/` |

## Résultats (campagne : 8 archétypes × 200 graines × 156 semaines)

**Le rythme visé est tenu pour 3 et 4 séances par semaine** (médiane, 10ᵉ–90ᵉ centile, en semaines) :

| Repère | Cible | 3 séances prévues (2,7 faites) | 4 séances prévues (3,6 faites) |
| --- | --- | --- | --- |
| Niveau 10 | ≈ 3 semaines | 3 (3–4) | 3 (2–3) |
| Niveau 25 | ≈ 3 mois | 15 (14–17) | 12 (11–13) |
| Niveau 50 | ≈ 1 an | 55 (53–57) | 43 (42–45) |
| Niveau 100 | 3 à 4 ans | 199 (195–202) | 158 (155–161) |

- **Autres archétypes** : 2 séances par semaine, niveau 50 en 69 semaines ; 6 séances, niveau 100 en
  112 semaines (plus vite que la cible : l'XP suit le nombre de séances du programme) ; irrégulière
  (1,6 séance faite), niveau 67 à 3 ans, rien ne lui est retiré.
- **D'où vient l'XP** : entraînement fait (effort + régularité et repos) 64 à 78 % ; quêtes 22 à 36 % ;
  records 0 à 1 % ; jalons proches de 0 dans la simulation.
- **Garde-fous** : l'XP d'effort d'une semaine n'a jamais dépassé `séances prévues × 110` ; le niveau
  n'a jamais baissé ; les séances faites malgré une douleur déclarée ont reçu 0 XP.
- **Triche par surentraînement** : les 314 à 452 séances en plus du jumeau tricheur reçoivent 0 XP. Il
  gagne quand même +2,9 % et +6,9 % d'XP sur 3 ans face à son jumeau honnête, parce que ses séances en
  plus prennent la place de séances prévues qu'il manque ; face au programme fait en entier il perd
  6 600 à 8 400 XP. S'entraîner plus que le programme ne rapporte jamais plus que faire le programme.
- **Coffres** : un toutes les 5 séances, jamais plus de 8 séances sans coffre.
- **Prédiction des objectifs** : couverture de l'intervalle à 80 % mesurée à 79,6 % sur 240 trajectoires
  simulées (calée sur ce même échantillon : à remesurer sur des journaux réels).
- **Temps** (machine de contrôle) : calcul complet depuis 3 ans de journal en 52 à 67 ms au repos, 78 à
  108 ms pendant les tests (une mesure isolée à 192 ms) ; appel courant 9 à 20 ms ; budget 200 ms. La
  marge est faible sous charge : le budget n'est pas acquis sur téléphone, à mesurer en G12.
- **Tests** : 162 tests `kalis_quest` dont 10 240 journaux aléatoires (invariants P1 à P7, aucun
  manquement) ; 183 tests `kalis_core`, 121 tests `kalis_plan`, 131 tests `kalis_adapt`.

## Relecture indépendante

Un second lecteur automatique a relu code, contrat et tests avant la livraison : 19 constats, tous
corrigés ou écrits comme limites (`docs/VALIDATION.md`, § 8). Le plus grave : une séance faite malgré
une douleur réduisait les séances prévues de la semaine, ce qui rendait la semaine plus facile à
réussir — corrigé (la semaine est en pause). Corrigés aussi : performances d'une séance douloureuse ou
en plus du programme comptées dans les rangs et les objectifs ; objectifs faciles à exploiter (doubles,
antidatés, départ à zéro) ; séance abandonnée qui prenait la place d'une séance prévue ; séance comptée
deux fois après un changement de date ; record payé deux fois.

## À faire trancher

1. **Règle des 3/4 pour les petits programmes.** À 2 ou 3 séances prévues, elle exige toutes les
   séances : un débutant qui fait 85 à 90 % de ses séances ne réussit que 72 % de ses semaines (95 % à
   4 séances). Variante possible par paramètre : arrondir en dessous (1 sur 2, 2 sur 3).
2. **Rythme proportionnel au programme.** Un programme de 6 séances atteint le niveau 100 en 2 ans.
   Voulu (on récompense son programme, pas plus), mais à confirmer.

## Limites

- **Aucune donnée réelle** : athlètes simulés, taux de quêtes faites supposé (un quart à un tiers de
  l'XP en dépend). L'échelle de la courbe est le seul paramètre à recaler ; les registres n'y sont pas
  sensibles.
- **Barème, attributs, notes et standards de rang non relus par un professionnel diplômé.** Les valeurs
  des standards ont été relevées par un outil et sont à revérifier à la main.
- **Tout est déclaré** : saisir des séances non faites atteint le plafond du programme ; les plafonds
  bornent, ils ne détectent pas.
- **Notes de séance** : S presque jamais atteinte dans la simulation quand les séries ont une cible de
  flammes, fréquente quand elles n'en ont pas ; seuils à recaler sur des journaux réels (G14).
- **L'application doit renseigner `plannedWorkSets`** (séries de la séance telle qu'affichée) ; sans
  lui, une séance terminée à plus de la moitié compte entière.
- Web non pris en charge (entiers 64 bits) ; registres jamais compactés (500 à 1 000 écritures par an).

## Suite

Fin de la piste M : aucun lot lancé. G12 (piste A) intègre `kalis_quest` après G10.
