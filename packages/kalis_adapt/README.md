# kalis_adapt

Moteur dynamique de Kalis Track (lot G8 du pipeline « Génération et progression ») : il suit l'utilisateur
séance après séance et adapte son programme. Dart pur — aucun import de Flutter, aucune horloge, aucun
hasard ; `kalis_core` (types, catalogue, registre des raisons) et `kalis_plan` (moteur statique, appelé
pour les restructurations) sont ses seules dépendances.

- **Modèle individuel** : un filtre de Kalman par exercice (capacité, tendance, forme de la courbe
  répétitions ↔ charge, effet de jour), observé par chaque série — charge, répétitions, flammes — avec un
  bruit qui croît loin de l'échec ; fatigue dans la séance ; forme et fatigue entre les séances ; forme du
  jour (fatigue, bilan santé, performances de la séance) ; notes peu informatives détectées.
- **Séance du jour** : charges arrondies aux incréments réels du matériel, répétitions et flammes par
  série, calibrage prudent, ajustement gradué au bilan santé, zones douloureuses épargnées, lieu et temps
  du jour.
- **Pendant la séance** : mise à jour après chaque série, cible de la série suivante ajustée quand l'écart
  aux flammes visées atteint 2 flammes.
- **Revue** : résumé d'adaptation pour le bloc suivant, propositions (volume, décharge anticipée, échange
  d'exercice, restructurations demandées à `kalis_plan`) filtrées par niveau de déblocage, confiance et
  utilité, records, journal du moteur.

Ce que le moteur garantit, le modèle et ses équations, d'où vient chaque nombre et ce qu'il ne sait pas
faire : [`CONTRAT.md`](CONTRAT.md). Ce que la simulation montre, et ce qu'elle ne montre pas :
[`docs/VALIDATION.md`](docs/VALIDATION.md). **Le contenu sportif n'a pas été relu par un professionnel
diplômé, et aucune donnée réelle n'a servi** (CONTRAT.md § 9).

## Utilisation

```dart
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_core/kalis_core.dart';

final engine = KalisAdapt();
final input = AdaptInput(
  profile: profile,
  block: block, // ProgramBlock de kalis_plan, ou programme importé
  log: log, // TrainingLog complet : le moteur le rejoue
  today: CivilDate(2026, 10, 12),
);

// Avant la séance : charges, répétitions, flammes du jour.
final session = engine.prescribeSession(
  catalog,
  SessionRequest(
    input: input,
    weekIndex: 1,
    dayIndex: 0,
    healthCheck: const HealthCheck(overall: 3, sleepQuality: 2),
  ),
);

// Après chaque série : la cible de la suivante.
final advice = engine.adviseNextSet(
  catalog,
  AdviceRequest(
    input: input,
    session: session,
    done: doneSets, // SetRecord de la séance en cours
    slotId: session.items.first.slotId,
    healthCheck: const HealthCheck(overall: 3, sleepQuality: 2),
  ),
);

// En fin de séance ou de semaine : résumé, propositions, records.
final review = engine.review(catalog, input);
for (final proposal in review.proposals) {
  final next = applyProposal(block, proposal); // mode assisté
}
```

Garder la même instance d'un appel à l'autre évite de rejouer tout le journal : le dernier rejeu est
prolongé tant que le catalogue, le profil, le bloc et le début du journal sont les mêmes objets. Les
textes de l'interface se construisent à partir des codes de raison (`ReasonCodes`), jamais du moteur.

## Outils

Depuis la racine du paquet (`kalis_core` et `kalis_plan` sont les dossiers voisins) :

```
dart run kalis_adapt:simulate --athlete avance_street --weeks 24 --seed 3 [--boucle] [--journal j.json]
dart run kalis_adapt:simulate --athlete mon_athlete.json --weeks 24 --seed 0
dart run kalis_adapt:replay --journal test/fixtures/proprietaire.json.gz
dart run kalis_adapt:replay --journal ../kalis_core/test/fixtures/journals.json.gz --cle j20_plateau
dart run bin/kalis_adapt_cli.dart --rapport <dossier>   # campagne de docs/ (200 graines)
```

- `lib/simulation.dart` : athlètes simulés à vérité connue, politiques comparées (`kalis_adapt`, double
  progression, oracle), mesures. L'ancien moteur L7/L11 est branché depuis `tool/l7/` (copie figée).
- `tool/reference/` : seconde écriture du filtre, en Python, et générateur des vecteurs partagés.
- `tool/owner.dart` : fixture du programme importé du propriétaire.

## Tests

`dart test` : briques (`units_test`), scénarios de journal (`sessions_test`), référence croisée Python
(`reference_test`), huit athlètes en boucle complète (`smoke_test`), 10 240 journaux aléatoires et les invariants de sécurité (`properties_*_test`),
pureté (`purity_test`), documents générés à jour (`docs_test`).
