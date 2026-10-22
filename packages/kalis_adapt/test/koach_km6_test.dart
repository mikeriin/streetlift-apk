// Koach 1.0.8 (lot KM6, DECISIONS_CP.md C17.47) : port, test pour test, de
// la référence Python `reference/tests/test_km6.py` (CHANGEMENTS_1_0_8.md).
// Mêmes cas, mêmes valeurs attendues : bugs X1 à X8 de la revue RV1
// (LIVRAISON_RV1.md § 5, RV1c1 § 4, C17.43.4) et crédits « chest » des
// tirages. Les cas du banc (grille du carnet, mesure de la modulation) sont
// dans `kalis_bench` (`test/km6_credits_test.dart`, campagne).
//
// Données synthétiques seulement (C17.33).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart' show LoadGrid;
import 'package:kalis_adapt/koach.dart';
import 'package:kalis_core/kalis_core.dart' show LoadType;
import 'package:test/test.dart';

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

const String _et = 'mu-extension-triceps-poulie-croisee';
const String _sq = 'mu-back-squat-barre-basse';
const String _ep = 'mu-epaule-haltere-unilateral';
const String _dl = 'sl-dips-leste';

Koach _koach({int niveau = 2, Json? declares}) =>
    Koach(copieJson(_params), _fiches, <String, Object?>{
      'niveau': niveau,
      'sexe': 'male',
      'poids_kg': 75.0,
      'declares': declares ?? <String, Object?>{},
      'zones_fragiles': <Object?>[],
    });

void _ouvrir(Koach k, int jour, {String genre = 'accumulation'}) {
  k.garde.avancer(jour);
  k.seances.ouvrir(jour, null, <String, Object?>{
    'semaine': jour ~/ 7,
    'genre': genre,
  });
}

void _debut(Koach k, Json? bilan) {
  k.observe(<String, Object?>{
    'type': 'seance_debut',
    'jour': 0,
    'bilan': bilan,
    'contexte': <String, Object?>{},
  });
}

Json _plan(Koach k, Json c) => jm(k.plan(c));

List<Object?> _codes(Json r) => [
  for (final x in jl(r['raisons'])) jm(x)['code'],
];

/// Modulation fixée d'avance (test de `appliquer`).
class _PlanificationFixe extends Planification {
  _PlanificationFixe()
    : super(copieJson(_params), _fiches, null, <String, Object?>{
        'sans_validateur': true,
      });

  @override
  Map<(int, String), (int, double)> itemsModules(int semaine) => {
    (1, 'a'): (2, 0.0),
    (1, 'b'): (4, 0.02),
    (1, 'c'): (3, 0.0),
  };
}

/// Une ligne modulée de 4 à 5 séries (test du cumul de `koachVolume`).
class _PlanificationUne extends Planification {
  _PlanificationUne()
    : super(copieJson(_params), _fiches, null, <String, Object?>{
        'sans_validateur': true,
      });

  @override
  Map<(int, String), (int, double)> itemsModules(int semaine) => {
    (1, 'a'): (5, 0.0),
  };
}

void main() {
  group('X1 : poulie par 2,5 kg', () {
    test(
      'extension triceps poulie servie à 2,5 kg près sans profil de pas',
      () {
        final g = LoadGrid.of(LoadType.cable, null);
        expect([g.step, g.minimum], [2.5, 2.5]);
        final k = _koach(
          declares: <String, Object?>{
            _et: <Object?>['one_rm_kg', 33.0],
          },
        );
        _debut(k, null);
        final r = _plan(k, <String, Object?>{
          'horizon': 'seance',
          'items': <Object?>[
            <String, Object?>{
              'slotId': 's1',
              'exerciseId': _et,
              'kind': 'work',
              'sets': 3,
              'repsLow': 12,
              'repsHigh': 12,
              'targetFlames': 7,
            },
          ],
          'grilles': <String, Object?>{
            _et: <String, Object?>{
              'pas': g.step,
              'minimum': g.minimum,
              'halteres': false,
            },
          },
          'zones': <String, Object?>{},
          'roles': <String, Object?>{'s1': 'accessory'},
        });
        final item = jm(jl(r['items'])[0]);
        final charges = [
          for (var i = 0; i < 3; i++)
            jm(
              k.plan(<String, Object?>{
                'horizon': 'serie',
                'item': item,
                'index': i,
                'faites': <Object?>[],
              }),
            )['loadKg'],
        ];
        expect(charges, [22.5, 22.5, 22.5]);
      },
    );
  });

  group('X2 : groupe d’intervalles recalé', () {
    Json intervalles(Json? bilan, {bool groupes = true}) {
      final k = _koach();
      _debut(k, bilan);
      return _plan(k, <String, Object?>{
        'horizon': 'seance',
        'items': <Object?>[
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': 'cf-burpee',
            'kind': 'work',
            'sets': 8,
            'secondsLow': 30,
            'secondsHigh': 30,
            'restSeconds': 30,
            'groupId': 'g1',
            'format': 'intervals',
          },
        ],
        'grilles': <String, Object?>{},
        'zones': <String, Object?>{},
        'roles': <String, Object?>{'s1': 'accessory'},
        if (groupes)
          'groups': <Object?>[
            <String, Object?>{
              'groupId': 'g1',
              'format': 'intervals',
              'rounds': 8,
              'intervalSeconds': 30,
              'restBetweenRoundsSeconds': 30,
            },
          ],
      });
    }

    test('intervalles réduits : tours du groupe = lignes servies', () {
      final r = intervalles(<String, Object?>{'overall': 1});
      expect(_codes(r), ['koach.wod_echelle']);
      expect(jm(jl(r['items'])[0])['sets'], 6);
      expect(r['groups'], [
        <String, Object?>{
          'groupId': 'g1',
          'format': 'intervals',
          'rounds': 6,
          'intervalSeconds': 30,
          'restBetweenRoundsSeconds': 30,
        },
      ]);
    });

    test('sans groupes reçus : pas de clé `groups`', () {
      final r = intervalles(null, groupes: false);
      expect(r.keys.toSet(), {'items', 'raisons'});
      final r2 = intervalles(null);
      expect(jm(jl(r2['groups'])[0])['rounds'], 8);
    });

    test('règles de groupesServis', () {
      final ecrits = <Object?>[
        <String, Object?>{'slotId': 'a', 'groupId': 'c', 'sets': 4},
        <String, Object?>{'slotId': 'b', 'groupId': 'c', 'sets': 4},
        <String, Object?>{'slotId': 'e', 'groupId': 'e', 'sets': 1},
        <String, Object?>{'slotId': 'm1', 'groupId': 'm', 'sets': 5},
        <String, Object?>{'slotId': 'm2', 'groupId': 'm', 'sets': 5},
        <String, Object?>{'slotId': 'x', 'groupId': 'x', 'sets': 3},
        <String, Object?>{
          'slotId': 'k',
          'groupId': 'k',
          'sets': 6,
          'koachVolume': 2,
        },
      ];
      final servis = <Json>[
        <String, Object?>{'slotId': 'a', 'groupId': 'c', 'sets': 3},
        <String, Object?>{'slotId': 'b', 'groupId': 'c', 'sets': 2},
        <String, Object?>{'slotId': 'e', 'groupId': 'e', 'sets': 1},
        <String, Object?>{'slotId': 'm1', 'groupId': 'm', 'sets': 4},
        <String, Object?>{'slotId': 'm2', 'groupId': 'm', 'sets': 5},
        <String, Object?>{'slotId': 'k', 'groupId': 'k', 'sets': 5},
      ];
      final groupes = <Object?>[
        <String, Object?>{'groupId': 'c', 'format': 'circuit', 'rounds': 4},
        <String, Object?>{
          'groupId': 'e',
          'format': 'amrap',
          'durationSeconds': 600,
        },
        <String, Object?>{
          'groupId': 'm',
          'format': 'emom',
          'intervalSeconds': 60,
          'durationSeconds': 600,
        },
        <String, Object?>{'groupId': 'x', 'format': 'superset', 'rounds': 3},
        <String, Object?>{
          'groupId': 'k',
          'format': 'intervals',
          'rounds': 4,
          'intervalSeconds': 60,
        },
        <String, Object?>{
          'groupId': 'r',
          'format': 'rounds_for_time',
          'rounds': 5,
        },
      ];
      expect(groupesServis(groupes, ecrits, servis), [
        <String, Object?>{'groupId': 'c', 'format': 'circuit', 'rounds': 3},
        <String, Object?>{
          'groupId': 'e',
          'format': 'amrap',
          'durationSeconds': 600,
        },
        <String, Object?>{
          'groupId': 'm',
          'format': 'emom',
          'intervalSeconds': 60,
          'durationSeconds': 540,
        },
        <String, Object?>{
          'groupId': 'k',
          'format': 'intervals',
          'rounds': 5,
          'intervalSeconds': 60,
        },
      ]);
      final deux = groupesServis(
        <Object?>[
          <String, Object?>{'groupId': 'c', 'format': 'circuit', 'rounds': 2},
        ],
        ecrits,
        servis,
      );
      expect(deux[0]['rounds'], 2);
    });
  });

  group('X3 : technique recalée', () {
    test('EMOM dont Koach baisse les séries', () {
      final k = _koach();
      _debut(k, <String, Object?>{'overall': 1});
      final ecrit = <String, Object?>{
        'slotId': 's1',
        'exerciseId': _dl,
        'kind': 'work',
        'sets': 10,
        'repsLow': 3,
        'repsHigh': 3,
        'targetFlames': 6,
        'restSeconds': 0,
        'technique': <String, Object?>{
          'kind': 'emom',
          'intervalSeconds': 60,
          'intervals': 10,
        },
      };
      final r = _plan(k, <String, Object?>{
        'horizon': 'seance',
        'items': <Object?>[ecrit],
        'grilles': <String, Object?>{},
        'zones': <String, Object?>{},
        'roles': <String, Object?>{'s1': 'main'},
      });
      final it = jm(jl(r['items'])[0]);
      expect(it['sets'], 9);
      expect(it['technique'], <String, Object?>{
        'kind': 'emom',
        'intervalSeconds': 60,
        'intervals': 9,
      });
      expect(jm(ecrit['technique'])['intervals'], 10);
    });

    test('règles de techniqueCoherente', () {
      Json t(int sets, Json? tech, [Json extra = const {}]) {
        final it = <String, Object?>{'sets': sets, 'technique': tech}
          ..addAll(extra);
        techniqueCoherente(it);
        return it;
      }

      expect(
        t(3, <String, Object?>{
          'kind': 'top_set_backoff',
          'backoffSets': 3,
          'backoffDropPct': 0.1,
        })['technique'],
        <String, Object?>{
          'kind': 'top_set_backoff',
          'backoffSets': 2,
          'backoffDropPct': 0.1,
        },
      );
      final seul = t(
        1,
        <String, Object?>{'kind': 'top_set_backoff', 'backoffSets': 2},
        <String, Object?>{
          'autoregulation': <Object?>[
            <String, Object?>{'kind': 'backoff_from_top_set', 'pct': 0.1},
            <String, Object?>{'kind': 'rir_floor', 'rirFloor': 1},
          ],
        },
      );
      expect(seul['technique'], isNull);
      expect(seul['autoregulation'], [
        <String, Object?>{'kind': 'rir_floor', 'rirFloor': 1},
      ]);
      expect(
        jm(
          t(6, <String, Object?>{'kind': 'emom', 'intervals': 8})['technique'],
        )['intervals'],
        6,
      );
      final vague = <String, Object?>{
        'kind': 'wave',
        'waves': 2,
        'waveReps': <Object?>[3, 2, 1],
      };
      expect(t(5, vague)['technique'], isNull);
      expect(t(6, vague)['technique'], isNotNull);
      expect(
        t(4, <String, Object?>{
          'kind': 'pyramid',
          'pyramidReps': <Object?>[8, 6, 4],
        })['technique'],
        isNull,
      );
      final echelle = <String, Object?>{
        'kind': 'ladder',
        'ladderStart': 1,
        'ladderStep': 1,
        'ladderTop': 5,
      };
      expect(t(5, echelle)['technique'], isNotNull);
      expect(t(4, echelle)['technique'], isNull);
      final densite = <String, Object?>{
        'kind': 'density',
        'durationSeconds': 600,
      };
      expect(t(2, densite)['technique'], isNull);
      expect(t(1, densite)['technique'], isNotNull);
      expect(
        t(2, <String, Object?>{'kind': 'cluster', 'miniSets': 3})['technique'],
        <String, Object?>{'kind': 'cluster', 'miniSets': 3},
      );
      expect(
        jm(
          t(2, <String, Object?>{
            'kind': 'emom',
            'intervals': 8,
            'lastSetOnly': true,
          })['technique'],
        )['intervals'],
        8,
      );
      expect(
        t(2, null, <String, Object?>{
          'setTargets': <Object?>[
            <String, Object?>{'loadKg': 1},
            <String, Object?>{'loadKg': 2},
            <String, Object?>{'loadKg': 3},
          ],
        })['setTargets'],
        [
          <String, Object?>{'loadKg': 1},
          <String, Object?>{'loadKg': 2},
        ],
      );
      expect(
        t(3, null, <String, Object?>{
          'setTargets': <Object?>[
            <String, Object?>{'loadKg': 1},
          ],
        })['setTargets'],
        isNull,
      );
    });
  });

  group('X4 à X6 : charges', () {
    Object? test1(String genre, double ecrite) {
      final k = _koach();
      _ouvrir(k, 10, genre: genre);
      k.modele.piste(_sq)!.mesures = 1;
      final s = k.seances;
      final servi = s.prescrire(
        [
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': _sq,
            'kind': 'test',
            'sets': 1,
            'repsLow': 3,
            'repsHigh': 3,
            'startLoadKg': ecrite,
            'test': <String, Object?>{'kind': 'rep_max', 'targetRir': 1},
          },
        ],
        {_sq: Grille(2.5, 20.0)},
        {_sq: (<String, Object?>{}, <String>{})},
        <String, Object?>{'s1': 'main'},
      );
      return s.cible(servi[0], 0, const [])!['loadKg'];
    }

    test('X4 : test xRM verrouillé, écrit hors grille gardé', () {
      expect(test1('test', 61.0), 61.0);
      expect(test1('test', 60.0), 60.0);
      expect((test1('accumulation', 61.0)! as num) > 61.0, isTrue);
    });

    (Object?, double?) premiere(
      String ex,
      double? part,
      String genre,
      Grille grille,
    ) {
      final k = _koach();
      _ouvrir(k, 10, genre: genre);
      final t = k.modele.piste(ex)!;
      t.mesures = 1;
      t.seances = 2;
      final (reps, flammes) = ex == _sq ? (5, 10) : (3, 7);
      final s = k.seances;
      final servi = s.prescrire(
        [
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': ex,
            'kind': 'work',
            'sets': 3,
            'repsLow': reps,
            'repsHigh': reps,
            'targetFlames': flammes,
            if (part != null) 'percentOfOneRm': part,
          },
        ],
        {ex: grille},
        {ex: (<String, Object?>{}, <String>{})},
        <String, Object?>{'s1': 'main'},
      );
      final c = s.cible(servi[0], 0, const [])!;
      double? cap;
      for (final x in listeOuVide(c['trace'])) {
        final l = x! as String;
        if (l.startsWith('part ecrite') && cap == null) {
          cap = double.parse(l.split('-> ')[1]);
        }
      }
      return (c['loadKg'], cap);
    }

    test('X5 : charge plafonnée arrondie vers le bas', () {
      final (charge, plafond) = premiere(_sq, 0.70, 'test', Grille(2.5, 20.0));
      expect(plafond, closeTo(91.9, 1e-9));
      expect(charge, 90.0);
    });

    test('X6 : test adaptatif sous le plafond', () {
      for (final part in const [0.62, 0.63, 0.64]) {
        final (charge, plafond) = premiere(
          _ep,
          part,
          'accumulation',
          Grille(5.0, 5.0),
        );
        expect(charge, 20.0, reason: '$part');
        expect((charge! as num) <= plafond! + 0.05, isTrue, reason: '$part');
      }
    });

    test('sans plafond : inchangé', () {
      final (charge, _) = premiere(
        _sq,
        null,
        'accumulation',
        Grille(2.5, 20.0),
      );
      expect(charge, 100.0);
    });
  });

  group('X7 : groupe de l’emplacement gardé', () {
    test('course facile dans le groupe', () {
      final k = _koach(niveau: 1);
      _debut(k, <String, Object?>{'overall': 1});
      final r = _plan(k, <String, Object?>{
        'horizon': 'seance',
        'items': <Object?>[
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': 'ca-fractionne-400m',
            'kind': 'work',
            'sets': 6,
            'distanceMeters': 400,
            'targetFlames': 8,
            'restSeconds': 90,
            'groupId': 'g1',
            'format': 'intervals',
          },
        ],
        'grilles': <String, Object?>{},
        'zones': <String, Object?>{},
        'roles': <String, Object?>{},
        'groups': <Object?>[
          <String, Object?>{
            'groupId': 'g1',
            'format': 'intervals',
            'rounds': 6,
            'intervalSeconds': 90,
          },
        ],
      });
      final it = jm(jl(r['items'])[0]);
      expect(it['exerciseId'], 'ca-footing-endurance-fondamentale');
      expect([it['groupId'], it['format'], it['sets']], ['g1', 'intervals', 1]);
      expect(_codes(r), contains('koach.course_facile'));
      expect(r['groups'], [
        <String, Object?>{
          'groupId': 'g1',
          'format': 'intervals',
          'rounds': 1,
          'intervalSeconds': 90,
        },
      ]);
    });

    test('vrai test hors du groupe', () {
      final k = _koach();
      _ouvrir(k, 10);
      final servi = k.seances.prescrire(
        [
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': _sq,
            'kind': 'work',
            'sets': 4,
            'repsLow': 5,
            'repsHigh': 5,
            'targetFlames': 7,
            'groupId': 'g1',
          },
        ],
        {_sq: Grille(2.5, 20.0)},
        {_sq: (<String, Object?>{}, <String>{})},
        <String, Object?>{'s1': 'main'},
      );
      for (final it in servi) {
        if (it['koach'] == 'vrai_test') {
          expect(it['groupId'], isNull);
        } else {
          expect(it['groupId'], 'g1');
        }
      }
    });
  });

  group('X8 : baisse hebdomadaire dite', () {
    test('raison koach.volume_semaine', () {
      final k = _koach();
      _ouvrir(k, 10);
      final s = k.seances;
      s.prescrire(
        [
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': _sq,
            'kind': 'work',
            'sets': 3,
            'repsLow': 5,
            'repsHigh': 5,
            'targetFlames': 7,
            'koachVolume': -1,
            'koachModule': -1,
          },
          <String, Object?>{
            'slotId': 's2',
            'exerciseId': _dl,
            'kind': 'work',
            'sets': 5,
            'repsLow': 5,
            'repsHigh': 5,
            'targetFlames': 7,
            'koachVolume': 1,
            'koachModule': 1,
          },
          <String, Object?>{
            'slotId': 's3',
            'exerciseId': _sq,
            'kind': 'warmup',
            'sets': 1,
            'repsLow': 5,
            'repsHigh': 5,
            'targetFlames': 3,
            'koachVolume': -1,
            'koachModule': -1,
          },
        ],
        {_sq: Grille(2.5, 20.0), _dl: Grille(1.25, 0.0)},
        {},
        <String, Object?>{'s1': 'main', 's2': 'main'},
      );
      expect(
        [
          for (final r in s.raisons)
            if (r['code'] == 'koach.volume_semaine') r,
        ],
        [
          <String, Object?>{
            'code': 'koach.volume_semaine',
            'params': <String, Object?>{
              'exercice': _sq,
              'ecrites': 4,
              'series': 3,
              'cause': 'planification',
            },
          },
        ],
      );
    });

    test('Planification.appliquer pose koachModule', () {
      final items = <Json>[
        <String, Object?>{'slotId': 'a', 'sets': 3},
        <String, Object?>{'slotId': 'b', 'sets': 3},
        <String, Object?>{'slotId': 'c', 'sets': 3},
        <String, Object?>{'slotId': 'd', 'sets': 3},
      ];
      final out = _PlanificationFixe().appliquer(0, 1, items);
      expect(
        [
          for (final x in out) [x['sets'], x['koachVolume'], x['koachModule']],
        ],
        [
          [2, -1, -1],
          [4, 1, 1],
          [3, null, null],
          [3, null, null],
        ],
      );
      expect(out[1]['koachIntensite'], 0.02);
      expect(items[0].containsKey('koachModule'), isFalse);
    });
  });

  group('crédits « chest » des tirages', () {
    double chest(String ex) {
      for (final g in jl(_fiches[ex]!['groupes'])) {
        if (jl(g)[0] == 0) {
          return dbl(jl(g)[1]);
        }
      }
      return 0.0;
    }

    test('table avant / après', () {
      const attendu = <String, double>{
        'sl-traction-lestee': 0.0,
        'sl-traction-lestee-prise-serree': 0.0,
        'sl-chin-up-leste': 0.0,
        'sw-traction-pronation': 0.0,
        'sw-traction-supination': 0.0,
        'sw-traction-neutre': 0.0,
        'cd-traction-un-bras': 0.0,
        'cf-traction-kipping': 0.0,
        'cd-traction-explosive-hanches': 0.0,
        'sl-muscle-up-leste': 0.5,
        'cd-muscle-up-barre-strict': 0.5,
        'cd-muscle-up-anneaux-strict': 0.5,
        'mu-pull-over-haltere': 0.5,
        'sl-dips-leste': 1.0,
        'sw-pompe': 1.0,
        'mu-developpe-couche-barre': 1.0,
        'mu-pull-over-machine': 0.5,
        'mu-rowing-pendlay': 0.0,
        'cs-back-lever': 1.0,
        'cs-front-lever': 0.5,
        'cd-hefesto': 0.5,
      };
      for (final e in attendu.entries) {
        expect(chest(e.key), e.value, reason: e.key);
      }
      for (final e in _fiches.entries) {
        if (e.value['schema'] == 'tirage_vertical') {
          expect(chest(e.key), 0.0, reason: e.key);
        }
        if (e.value['schema'] == 'transition_muscle_up') {
          expect(chest(e.key), lessThanOrEqualTo(0.5), reason: e.key);
        }
      }
    });
  });

  group('relecture indépendante', () {
    test(
      'groupes : contre la montre au moins, EMOM aux tours, membres à 0',
      () {
        final ecrits = <Object?>[
          <String, Object?>{'slotId': 'a', 'groupId': 'r', 'sets': 5},
          <String, Object?>{'slotId': 'b', 'groupId': 'r', 'sets': 5},
          <String, Object?>{'slotId': 'c', 'groupId': 'e', 'sets': 8},
          <String, Object?>{'slotId': 'd', 'groupId': 'e', 'sets': 8},
          <String, Object?>{'slotId': 'z', 'groupId': 'z', 'sets': 3},
        ];
        final servis = <Json>[
          <String, Object?>{'slotId': 'a', 'groupId': 'r', 'sets': 5},
          <String, Object?>{'slotId': 'b', 'groupId': 'r', 'sets': 3},
          <String, Object?>{'slotId': 'c', 'groupId': 'e', 'sets': 6},
          <String, Object?>{'slotId': 'd', 'groupId': 'e', 'sets': 6},
          <String, Object?>{'slotId': 'z', 'groupId': 'z', 'sets': 0},
        ];
        final groupes = <Object?>[
          <String, Object?>{
            'groupId': 'r',
            'format': 'rounds_for_time',
            'rounds': 5,
            'timeCapSeconds': 900,
          },
          <String, Object?>{
            'groupId': 'e',
            'format': 'emom',
            'rounds': 8,
            'intervalSeconds': 120,
            'durationSeconds': 960,
          },
          <String, Object?>{'groupId': 'z', 'format': 'circuit', 'rounds': 3},
        ];
        expect(groupesServis(groupes, ecrits, servis), [
          <String, Object?>{
            'groupId': 'r',
            'format': 'rounds_for_time',
            'rounds': 3,
            'timeCapSeconds': 900,
          },
          <String, Object?>{
            'groupId': 'e',
            'format': 'emom',
            'rounds': 6,
            'intervalSeconds': 120,
            'durationSeconds': 720,
          },
        ]);
      },
    );

    test('volume_semaine sur l’exercice écrit seulement', () {
      final k = _koach(niveau: 1);
      _debut(k, <String, Object?>{'overall': 1});
      final r = _plan(k, <String, Object?>{
        'horizon': 'seance',
        'items': <Object?>[
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': 'ca-fractionne-400m',
            'kind': 'work',
            'sets': 5,
            'distanceMeters': 400,
            'targetFlames': 8,
            'restSeconds': 90,
            'koachVolume': -1,
            'koachModule': -1,
          },
        ],
        'grilles': <String, Object?>{},
        'zones': <String, Object?>{},
        'roles': <String, Object?>{},
      });
      expect(_codes(r), contains('koach.course_facile'));
      expect(_codes(r), isNot(contains('koach.volume_semaine')));
    });

    test('koachVolume cumulé', () {
      final out = _PlanificationUne().appliquer(0, 1, [
        <String, Object?>{'slotId': 'a', 'sets': 4, 'koachVolume': 1},
      ]);
      expect(
        [out[0]['sets'], out[0]['koachVolume'], out[0]['koachModule']],
        [5, 2, 1],
      );
    });
  });
}
