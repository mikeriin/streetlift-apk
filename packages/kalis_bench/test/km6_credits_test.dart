// Lot KM6 (Koach 1.0.8, kalis_plan 0.4.3, DECISIONS_CP.md C17.47) :
// 1. crédits de groupes changés ENSEMBLE dans les trois tables — crédits de
//    `kalis_plan` (`CatalogTraits`, lus par les validateurs Dart du banc et
//    de `kalis_adapt`), fiches exportées pour la référence Python
//    (`kmCatalogInfos` ; fichier `donnees/catalogue_infos.json.gz` lu par le
//    validateur Python) et fiches de Koach (`vecteurs_qualites_v1.json`,
//    champ `groupes`, référence et asset) : aucun écart de comptage
//    possible, exercice par exercice et groupe par groupe ;
// 2. table avant / après de la livraison (tractions « chest » 0, muscle-up
//    0,5, pull-over 0,5 ; dips, pompes, rowing inchangés) ;
// 3. grilles de charge par défaut (X1 de RV1) : `kalis_adapt` et
//    `kalis_plan` ont la même poulie (2,5 kg, minimum 2,5 kg) et les mêmes
//    pas ; les haltères de `kalis_adapt` (1 kg jusqu'à 10 kg puis 2 kg)
//    contiennent toutes les charges de `kalis_plan` (2 kg, minimum 2 kg).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart' show LoadGrid;
import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

const String _reference = '../kalis_adapt/reference';

Object? _lire(String chemin) {
  final bytes = File(chemin).readAsBytesSync();
  return jsonDecode(
    utf8.decode(chemin.endsWith('.gz') ? gzip.decode(bytes) : bytes),
  );
}

/// Crédits d'une fiche de Koach (`groupes` : [[indice, part]]) en
/// demi-séries, indexés par `MuscleGroup.index`.
List<int> _creditsFiche(Map<String, Object?> fiche) {
  final out = List<int>.filled(MuscleGroup.values.length, 0);
  for (final g in fiche['groupes']! as List<Object?>) {
    final paire = g! as List<Object?>;
    out[(paire[0]! as num).toInt()] = ((paire[1]! as num) * 2).round();
  }
  return out;
}

void main() {
  final catalog = loadCatalog();
  final traits = CatalogTraits.of(catalog);

  group('crédits de groupes : trois tables identiques', () {
    final fichesRef =
        (_lire('$_reference/qualites/vecteurs_qualites_v1.json')!
                as Map<String, Object?>)['exercices']!
            as Map<String, Object?>;
    final fichesAsset =
        (_lire('../kalis_adapt/assets/koach/vecteurs_qualites_v1.json')!
                as Map<String, Object?>)['exercices']!
            as Map<String, Object?>;
    final export =
        kmCatalogInfos(catalog)['exercises']! as List<Object?>;
    final exportParId = <String, Map<String, Object?>>{
      for (final e in export)
        (e! as Map<String, Object?>)['id']! as String: e as Map<String, Object?>,
    };
    final donnees =
        (_lire('$_reference/donnees/catalogue_infos.json.gz')!
                as Map<String, Object?>)['exercises']!
            as List<Object?>;
    final donneesParId = <String, Map<String, Object?>>{
      for (final e in donnees)
        (e! as Map<String, Object?>)['id']! as String: e as Map<String, Object?>,
    };

    test('kalis_plan = fiches de Koach (référence et asset), partout', () {
      var vus = 0;
      for (final t in traits.all) {
        final id = t.exercise.id;
        final f = fichesRef[id] as Map<String, Object?>?;
        expect(f, isNotNull, reason: id);
        expect(_creditsFiche(f!), t.groupCredits, reason: id);
        expect(fichesAsset[id], f, reason: id);
        vus++;
      }
      expect(vus, catalog.exercises.length);
      expect(fichesRef.length, catalog.exercises.length);
    });

    test('kalis_plan = fiches exportées pour le validateur Python', () {
      for (final t in traits.all) {
        final id = t.exercise.id;
        final e = exportParId[id];
        if (e == null) {
          continue;
        }
        expect(e['groupCredits'], t.groupCredits, reason: id);
        final d = donneesParId[id];
        expect(d, isNotNull, reason: id);
        expect(d!['groupCredits'], t.groupCredits, reason: '$id (données)');
      }
      expect(donneesParId.length, exportParId.length);
    });
  });

  group('table avant / après (KM6)', () {
    int chest(String id) => traits.of(id).creditOf(MuscleGroup.chest);
    const attendu = <String, int>{
      // Tractions et tirages verticaux : 0 (avant : 1).
      'sl-traction-lestee': 0,
      'sl-traction-lestee-prise-serree': 0,
      'sl-chin-up-leste': 0,
      'sw-traction-pronation': 0,
      'sw-traction-supination': 0,
      'sw-traction-neutre': 0,
      'cd-traction-un-bras': 0,
      'cf-traction-kipping': 0,
      'cd-traction-explosive-hanches': 0,
      // Muscle-ups : une demi-série (avant : 2).
      'sl-muscle-up-leste': 1,
      'cd-muscle-up-barre-strict': 1,
      'cd-muscle-up-anneaux-strict': 1,
      // Pull-over haltère : une demi-série (avant : 2).
      'mu-pull-over-haltere': 1,
      // Inchangés.
      'sl-dips-leste': 2,
      'sw-pompe': 2,
      'mu-developpe-couche-barre': 2,
      'mu-pull-over-machine': 1,
      'mu-rowing-pendlay': 0,
      'cs-back-lever': 2,
      'cs-front-lever': 1,
      'cd-hefesto': 1,
    };
    for (final e in attendu.entries) {
      test(e.key, () => expect(chest(e.key), e.value));
    }

    test('aucun tirage vertical ne crédite le groupe « chest »', () {
      for (final t in traits.all) {
        if (t.exercise.pattern == MovementPattern.tirageVertical) {
          expect(t.creditOf(MuscleGroup.chest), 0, reason: t.exercise.id);
        }
        if (t.exercise.pattern == MovementPattern.transitionMuscleUp) {
          expect(
            t.creditOf(MuscleGroup.chest),
            lessThanOrEqualTo(1),
            reason: t.exercise.id,
          );
        }
      }
    });

    test('seul le groupe « chest » change (règle chestCreditRule)', () {
      expect(chestCreditRule('x', MovementPattern.tirageVertical, 2), 0);
      expect(chestCreditRule('x', MovementPattern.transitionMuscleUp, 2), 1);
      expect(chestCreditRule('x', MovementPattern.transitionMuscleUp, 0), 0);
      expect(
        chestCreditRule('cd-traction-un-bras', MovementPattern.freestyle, 1),
        0,
      );
      expect(chestCreditRule('cf-burpee', MovementPattern.conditionnement, 2), 2);
      expect(chestCreditRule('mu-pull-over-x', MovementPattern.isolationDos, 2), 1);
      expect(
        chestCreditRule('mu-pompe', MovementPattern.pousseeHorizontale, 2),
        2,
      );
    });
  });

  group('grilles de charge par défaut (X1)', () {
    test('mêmes pas que kalis_plan ; haltères : grille plus fine', () {
      for (final type in LoadType.values) {
        final (pas, minimum) = defaultIncrement(type);
        final g = LoadGrid.of(type, null);
        if (type == LoadType.dumbbells) {
          for (var kg = minimum; kg <= 60 + 1e-9; kg += pas) {
            expect(g.floor(kg), closeTo(kg, 1e-9), reason: '$kg kg');
          }
          continue;
        }
        expect(g.step, pas, reason: type.code);
        expect(g.minimum, minimum, reason: type.code);
      }
    });

    test('poulie : 2,5 kg (extension triceps à 20 kg, pas 20,41)', () {
      final g = LoadGrid.of(LoadType.cable, null);
      expect(g.nearest(20.41), 20);
      expect(g.next(20, up: true), 22.5);
    });
  });
}
