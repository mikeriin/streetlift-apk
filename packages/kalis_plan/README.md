# kalis_plan

Moteur statique de Kalis Track (lot G4 du pipeline « Génération et progression ») : il crée le programme
d'entraînement à partir du profil, par optimisation sous contraintes. Dart pur — aucun import de Flutter,
aucune horloge, aucun hasard hors de la graine ; `kalis_core` (types, catalogue, registre des raisons) est
sa seule dépendance.

- **Passe 1** : les exercices de chaque séance, avec une note détaillée et une raison par choix.
- **Revue** : « je sais faire », « je ne sais pas faire », « je n'aime pas », ajouter, retirer, remplacer ;
  variantes d'un exercice ; régénération à diff minimal, verrous respectés.
- **Passe 2** : séries, répétitions, flammes visées, repos, charges de départ prudentes « à calibrer »,
  semaines d'introduction, de montée, de décharge et de test.
- **Blocs glissants** et **restructuration** d'une séance, d'une semaine ou de la fin du bloc.

Ce que le moteur garantit, comment il décide, d'où vient chaque nombre et ce qu'il ne sait pas faire :
[`CONTRAT.md`](CONTRAT.md). **Le contenu sportif n'a pas été relu par un professionnel diplômé** (registre
de validation, CONTRAT.md § 10).

## Utilisation

```dart
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

final engine = KalisPlan();
final request = PlanRequest(
  profile: profile,
  seed: 0, // 1, 2, … : « Autre proposition »
  startDate: CivilDate(2026, 10, 5),
  locks: const <PlanLock>[],
);
final pass1 = engine.createPass1(catalog, request);

// Revue : l'utilisateur ne sait pas faire le deuxième exercice du lundi.
final result = engine.review(
  catalog,
  ReviewRequest(
    request: request,
    current: pass1,
    action: ReviewAction(
      kind: ReviewKind.cannotDo,
      slotId: pass1.days.first.slots[1].slotId,
    ),
  ),
);
// La suite se fait avec le profil et les verrous mis à jour.
final next = request.copyWith(
  profile: applyProfileDelta(request.profile, result.profileDelta),
  locks: result.locks,
);
final pass2 = engine.createPass2(
  catalog,
  Pass2Request(request: next, pass1: result.plan),
);
```

Le catalogue se charge avec `Catalog.fromJsonBytes` (kalis_core). Le moteur ne lit ni fichier ni horloge :
la date de début et la graine viennent de la requête. Les textes de l'interface se construisent à partir
des codes de raison (`ReasonCodes`), jamais du moteur.

`PlanInspector` sert l'inspecteur du mode dev : note relue composante par composante, contraintes dures
revérifiées, mesures de la semaine (volume par groupe, dosage, équilibre), raison pour laquelle un exercice
est écarté (`rejectionOf`), et « pourquoi pas un exercice de plus ? » (`whatIfAdd`).

## Ligne de commande

```
dart run kalis_plan:plan --profile profil.json --seed 0 --pass 1 [--locks verrous.json]
                         [--start 2026-10-05] [--catalog catalog_v1.json.gz]
```

`--pass 1` écrit la passe 1 (JSON) ; `--pass 2` le bloc complet (`ProgramBlock`). Le profil est un
`AthleteProfile` (ou un objet `{"profile": …}`, comme dans les jeux de données de kalis_core).

## Contrôle

```
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart run bin/kalis_plan_cli.dart --rapport /tmp/rapport
```

`dart test` joue 10 240 profils aléatoires de bout en bout (huit fichiers `properties_<n>_test.dart`, en
parallèle : quelques minutes). Le simulateur écrit `PROFILS_TYPES.md`, `COMPARAISON_L10.md`, `MESURES.md` et
`mesures.json` ; les deux premiers sont recopiés dans `docs/` et comparés au moteur par
`test/docs_test.dart` — après tout changement du moteur, relancer le simulateur et les recopier.

## Arborescence

| Chemin | Contenu |
| --- | --- |
| `lib/kalis_plan.dart` | API publique. |
| `lib/src/context.dart` | Lecture du profil : jours, dosage, niveau, vivier et contraintes dures, bandes de volume. |
| `lib/src/traits.dart`, `scheme.dart`, `similarity.dart` | Nature d'un exercice, prescription de référence, proximité. |
| `lib/src/score.dart`, `sets.dart` | Note à 14 composantes ; séries de référence et durée d'une séance. |
| `lib/src/search.dart` | Glouton avec anticipation, recuit simulé, descente, réparation, diff minimal. |
| `lib/src/engine.dart` | `KalisPlan` : création, revue, bloc suivant, restructuration. |
| `lib/src/variants.dart`, `diff.dart`, `pass2.dart`, `assemble.dart` | Variantes, diff, passe 2, mise en forme du programme et raisons. |
| `lib/src/inspect.dart` | `PlanInspector`. |
| `lib/testing.dart` | Profils aléatoires seedés (tests, simulateur, mode dev). |
| `lib/report.dart` | Rapports : profils types, comparaison L10, non-ressemblance. |
| `bin/plan.dart`, `bin/kalis_plan_cli.dart` | Ligne de commande ; simulateur. |
| `docs/` | `VALIDATION.md`, `PROFILS_TYPES.md`, `COMPARAISON_L10.md`, `MESURES.md`, `data/l10_sorties.json.gz`. |
| `tool/` | Extraction des sorties de l'ancien générateur L10 (traçabilité de la comparaison). |

## Intégration (lots suivants)

- Rien dans `lib/` de l'application ne change avec ce lot : le moteur n'est pas encore branché (G8 et
  suivants).
- `createPass1` prend quelques dizaines de millisecondes sur la machine de contrôle (`docs/MESURES.md`) ; à
  remesurer sur téléphone. L'appel est synchrone et sans effet de bord : il peut tourner dans un isolat.
- L'identifiant d'un emplacement (`d<jour>.<n>`) est stable d'une régénération à l'autre : c'est la clé des
  verrous, du diff et des prescriptions de la passe 2.
- `ReviewResult.locks` et `profileDelta` sont à réinjecter dans la requête suivante (exemple ci-dessus).
