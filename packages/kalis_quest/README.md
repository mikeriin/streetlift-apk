# kalis_quest

Moteur de progression de Kalis Track (lot G11 du pipeline « Génération et progression ») : il donne envie
de revenir et de progresser **sans jamais pousser au surentraînement ni punir le repos**. Dart pur —
aucun import de Flutter, aucune horloge, aucun hasard hors de la graine ; `kalis_core` (types, catalogue,
registre des raisons) et `kalis_adapt` (courbe répétitions ↔ charge, règle des records, seuils de
douleur) sont ses seules dépendances. Écrit à partir de zéro : aucune ligne de l'ancien système de
progression n'est reprise.

- **XP et niveaux** : effort réel rapporté au programme (plafonné par séance et par semaine), régularité
  et jours de repos respectés, records, jalons d'objectif, quêtes. Niveaux 1 à 100 puis prestige. Le
  registre d'XP est en ajout seul : le niveau ne redescend jamais.
- **Avancements** : six attributs (Force, Endurance, Puissance, Technique, Mobilité, Régularité) calculés
  depuis les performances du journal, et des rangs par mouvement (Bronze → Élite) sur des standards
  publiés par sexe et poids de corps.
- **Quêtes** : quotidiennes adaptées au jour (un jour de repos ne propose que de la récupération),
  hebdomadaires, campagne liée au programme (chapitre = bloc, boss = séance de test ou fin de bloc),
  quêtes Koach personnalisées. Récompenses en XP et en Krédits.
- **Objectifs** : avancement, jalons découpés selon la courbe prévue, prédiction de la date d'atteinte
  (médiane et intervalle à 80 %), objectif en retard → date ou cible ajustée, objectifs suggérés.
- **Plaisir** : records et premières fois, coffres surprises, série de semaines, fantôme, note de séance
  S/A/B/C, combo, récapitulatif hebdomadaire, comparaisons dans le temps.

Ce que le moteur garantit, ses formules, d'où vient chaque nombre et ce qu'il ne sait pas faire :
[`CONTRAT.md`](CONTRAT.md). Standards de rang : [`docs/STANDARDS.md`](docs/STANDARDS.md) et
[`docs/STANDARDS_SOURCES.md`](docs/STANDARDS_SOURCES.md). Rythme de la progression sur trois ans :
[`docs/RYTHME.md`](docs/RYTHME.md), lu dans [`docs/VALIDATION.md`](docs/VALIDATION.md). **Le contenu
sportif n'a pas été relu par un professionnel diplômé, et aucune donnée réelle n'a servi** (CONTRAT.md,
§ Registre de validation).

## Utilisation

```dart
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';

final engine = KalisQuest();

// Au branchement : état vide. Le registre démarre ce jour-là.
var state = const QuestState(xp: [], kredits: [], quests: [], data: {});

// À chaque ouverture de l'application et après chaque séance.
final outcome = engine.evaluate(
  catalog,
  QuestInput(
    profile: profile,
    log: log, // TrainingLog complet
    block: block, // bloc en cours (kalis_plan), facultatif
    adaptation: review.summary, // résumé de kalis_adapt, facultatif
    state: state, // état rendu par l'appel précédent
    today: CivilDate(2026, 10, 12),
    seed: userSeed, // graine de l'utilisateur (coffres, quêtes du jour)
    claims: claims, // quêtes de récupération déclarées faites, facultatif
  ),
);
state = outcome.state; // à stocker tel quel (registres, quêtes, état opaque)

outcome.level; // niveau, prestige, XP
outcome.events; // ce qui est nouveau : records, coffres, notes, passages de niveau…
outcome.extras; // récapitulatif, comparaisons, fantôme… (docs/EXTRAS.md)
```

L'application renseigne `SessionRecord.plannedWorkSets` (kalis_core 0.3.0) : le nombre de séries de
travail de la séance telle qu'elle a été affichée, après les ajustements du jour. Sans lui, le moteur se
rabat sur le bloc, puis sur le marqueur « séance terminée » (CONTRAT.md, § XP d'effort).

## Outils

Depuis la racine du paquet (`kalis_core`, `kalis_plan` et `kalis_adapt` sont les dossiers voisins) :

```
dart run kalis_quest:simulate --archetype debutant_3x --years 3 --seed 0
dart run kalis_quest:simulate --archetype intermediaire_4x_tricheur --years 1 --seed 4
dart run bin/kalis_quest_cli.dart --rapport <dossier>   # campagne de docs/ (200 graines, 3 ans)
python3 tool/standards_fit.py                            # exposants du poids de corps
```

- `lib/simulation.dart` : archétypes, journaux simulés sur les programmes de `kalis_plan`, déroulement
  semaine par semaine, mesures.
- `lib/report.dart` : documents générés de `docs/`.

## Tests

`dart test` : briques (`units_test`), scénarios (`engine_test`), objectifs et calibrage de la prédiction
(`goals_test`), simulation et triche (`sim_test`), 10 240 journaux aléatoires et les invariants du
contrat (`properties_*_test`), budget de temps (`timing_test`), pureté (`purity_test`), documents générés
à jour (`docs_test`).
