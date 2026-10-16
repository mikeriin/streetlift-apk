// Campagne KM2 (`lib/src/km/campagne.dart`, `criteres_moteur.dart`) :
// agrégation des critères sur de petites entrées construites à la main,
// comparée aux valeurs de la référence Python (`reference/banc/campagne.py`,
// `criteres_moteur.py`, Python 3.13) calculées sur les mêmes entrées :
// somme et arrondi de Python, déciles, moyenne des vérités, premier passage,
// couverture, classement des constats, calibration par cible (mesure de
// KM1 et mesure fixée par C13.11.2).
import 'dart:math' as math;

import 'package:kalis_bench/src/km/campagne.dart';
import 'package:kalis_bench/src/km/criteres_moteur.dart';
import 'package:test/test.dart';

typedef _Json = Map<String, Object?>;

List<List<double>> _rows(List<double> r6, [List<double>? r3]) {
  final rs = <List<double>>[
    for (var k = 0; k < 25; k++) List<double>.filled(7, 0.0),
  ];
  rs[6] = List<double>.of(r6);
  if (r3 != null) {
    rs[3] = List<double>.of(r3);
  }
  return rs;
}

List<_Json> _saisonsEstimees() {
  final def = <(List<Object?>, int, List<double>, List<double>?, List<int>)>[
    (
      <Object?>['p1', 'reference', 'a', 0],
      1,
      <double>[3, 0.091, -0.02, 0.0031, 1, 3, 0.15],
      <double>[2, 0.07, 0.01, 0.003, 1, 2, 0.2],
      <int>[0, 3, 5],
    ),
    (
      <Object?>['p1', 'reference', 'b', 0],
      1,
      <double>[2, 0.105, 0.04, 0.0063, 0, 1, 0.11],
      null,
      <int>[2, 0],
    ),
    (
      <Object?>['p2', 'reference', 'c', 1],
      2,
      <double>[4, 0.0812, 0.0105, 0.0024, 3, 4, 0.2],
      <double>[5, 0.21, -0.03, 0.02, 2, 4, 0.5],
      <int>[1, 1, 0, 7],
    ),
    (
      <Object?>['p2', 'reference', 'a', 1],
      2,
      <double>[1, 0.0133, 0.0133, 0.00017689, 1, 1, 0.05],
      null,
      <int>[4],
    ),
  ];
  return <_Json>[
    for (final (s, niveau, r6, r3, fu) in def)
      <String, Object?>{
        'saison': s,
        'niveau': niveau,
        'estimations': <String, Object?>{
          for (final m in kmModes)
            m: <String, Object?>{
              'rows': _rows(r6, r3),
              'first_under': List<int>.of(fu),
            },
        },
      },
  ];
}

_Json _c(
  String code, {
  int? week,
  int? day,
  String? ex,
  double? value,
  double? limit,
}) => <String, Object?>{
  'code': code,
  'message': 'm',
  'week': week,
  'dayIndex': day,
  'exerciseId': ex,
  'value': value,
  'limit': limit,
};

/// Saisons à unités de calibration (même générateur que le script Python
/// qui a donné les valeurs attendues).
List<_Json> _saisonsCalibration() {
  final out = <_Json>[];
  const dates = <String>['debut', 'mi_saison', 'moins_4_semaines'];
  for (var i = 0; i < 420; i++) {
    final g = i % 7;
    final p1 = const <double>[0.05, 0.13, 0.62, 0.91][i % 4] + 0.0007 * (i % 5);
    final p2 = const <double>[0.21, 0.47][i % 2] + 0.0011 * (i % 3);
    final ok1 = (i * 13) % 7 < 3;
    final ok2 = (i * 11) % 5 < 2;
    final prev = <String, Object?>{};
    for (var k = 0; k < dates.length; k++) {
      final date = dates[k];
      if (date == 'moins_4_semaines' && i % 10 == 9) {
        prev[date] = null;
        continue;
      }
      final q1 = math.min(1.0, p1 + 0.01 * k);
      final q2 = math.min(1.0, p2 + 0.02 * k);
      prev[date] = <String, Object?>{
        'semaine': 4 * k,
        'p_tout': q1 * q2,
        'p': <String, Object?>{'ex1': q1, 'ex2': q2},
      };
    }
    final u = <String, Object?>{
      'echeance': 70,
      'cibles': <String, Object?>{'ex1': 100.0, 'ex2': 50.0},
      'reussite': ok1 && ok2,
      'reussite_capacite': ok1,
      'reussite_par_cible': <String, Object?>{'ex1': ok1, 'ex2': ok2},
      'capacite_par_cible': <String, Object?>{'ex1': ok1, 'ex2': true},
      'previsions': prev,
    };
    out.add(<String, Object?>{
      'saison': <Object?>['p${i % 3}', 'reference', 'abc'[i % 3], g],
      'calibration': <String, Object?>{
        'unites': <Object?>[u],
        'exclus': <String, Object?>{'sans_echeance': i % 2},
      },
    });
  }
  return out;
}

void main() {
  test('somme de Python 3.13 (Neumaier) et arrondi round(x, n)', () {
    expect(kmSommePy(List<double>.filled(10, 0.1)), 1.0);
    expect(kmSommePy(<num>[1e16, 1.0, 1, -1e16]), 1.0);
    final entiers = kmSommePy(<int>[1, 2, 3]);
    expect(entiers, 6);
    expect(entiers, isA<int>());
    expect(kmSommePy(<double>[0.1, 0.2, 0.3]), 0.6);
    expect(kmSommePy(<num>[1, 0.1, 0.2, 0.3]), 1.6);
    expect(kmSommePy(<double>[1e100, 1.0, -1e100]), 1.0);
    const arrondis = <(double, double)>[
      (0.0078125, 0.007812),
      (0.0234375, 0.023438),
      (2.675, 2.675),
      (0.1234565, 0.123456),
      (-4e-07, -0.0),
      (1.0000005, 1.000001),
      (123.4567895, 123.456789),
      (0.5, 0.5),
      (1e-07, 0.0),
      (3.9999995, 3.999999),
      (0.05078125, 0.050781),
    ];
    for (final (x, attendu) in arrondis) {
      expect(kmArrondiPy(x), attendu, reason: '$x');
    }
    expect(kmArrondiPy(-4e-07).isNegative, isTrue);
    expect(kmArrondiPy(2.675, 2), 2.67);
    expect(kmR(double.nan), isNull);
    expect(kmR(3), 3);
  });

  test('déciles (campagne._deciles)', () {
    const paires = <(double, bool)>[
      (0.03, false),
      (0.07, true),
      (0.12, false),
      (0.15, true),
      (0.19, false),
      (0.55, true),
      (0.58, true),
      (0.95, true),
      (1.0, false),
      (0.999, true),
      (0.31, false),
    ];
    final (dec, pire) = kmDeciles(paires, 2);
    expect(pire, 0.45);
    expect(dec, <Object?>[
      <String, Object?>{
        'decile': 0,
        'n': 2,
        'p_prevue': 0.05,
        'observee': 0.5,
        'ecart': 0.45,
      },
      <String, Object?>{
        'decile': 1,
        'n': 3,
        'p_prevue': 0.15333333333333332,
        'observee': 0.3333333333333333,
        'ecart': 0.18,
      },
      <String, Object?>{'decile': 2, 'n': 0, 'signal': 'vide'},
      <String, Object?>{
        'decile': 3,
        'n': 1,
        'p_prevue': 0.31,
        'observee': 0.0,
        'ecart': 0.31,
        'signal': 'n < 2',
      },
      <String, Object?>{'decile': 4, 'n': 0, 'signal': 'vide'},
      <String, Object?>{
        'decile': 5,
        'n': 2,
        'p_prevue': 0.565,
        'observee': 1.0,
        'ecart': 0.43500000000000005,
      },
      <String, Object?>{'decile': 6, 'n': 0, 'signal': 'vide'},
      <String, Object?>{'decile': 7, 'n': 0, 'signal': 'vide'},
      <String, Object?>{'decile': 8, 'n': 0, 'signal': 'vide'},
      <String, Object?>{
        'decile': 9,
        'n': 3,
        'p_prevue': 0.983,
        'observee': 0.6666666666666666,
        'ecart': 0.31633333333333336,
      },
    ]);
  });

  test('critères 1, 3 et 4 : moyenne des vérités, premier passage, '
      'couverture', () {
    final ok = _saisonsEstimees();
    final a = kmAgregerEstimations(ok, const {}, (c, s) => null);
    final c1 = kmCritereE1rm(a);
    expect(c1['mesure'], 0.03295833333333333);
    expect(c1['n'], 10);
    expect(c1['respecte'], isFalse);
    final d1 = c1['detail']! as _Json;
    expect(d1['koach'], <String, Object?>{
      'n': 10,
      'mae': 0.02905,
      'biais': 0.00438,
      'rmse': 0.03460764366436987,
      'sous3': 0.5,
      'couverture': 0.9,
      'sd': 0.051000000000000004,
    });
    expect(d1['temoin'], isNull);
    expect(d1['par_niveau'], <String, Object?>{
      '1': <String, Object?>{
        'koach': <String, Object?>{
          'n': 5,
          'mae': 0.0392,
          'biais': 0.004,
          'rmse': 0.0433589667773576,
          'sous3': 0.2,
          'couverture': 0.8,
          'sd': 0.052000000000000005,
        },
        'temoin': null,
      },
      '2': <String, Object?>{
        'koach': <String, Object?>{
          'n': 5,
          'mae': 0.0189,
          'biais': 0.00476,
          'rmse': 0.022701938243242577,
          'sous3': 0.8,
          'couverture': 1.0,
          'sd': 0.05,
        },
        'temoin': null,
      },
    });
    final c3 = kmCritereConvergence(a);
    final d3 = c3['detail']! as _Json;
    expect(d3['koach'], <String, Object?>{
      'n': 10,
      'moyenne_censuree': 9.8,
      'moyenne_atteints': 3.2857142857142856,
      'mediane_censuree': 4.5,
      'part_jamais': 0.30000000000000004,
    });
    expect(d3['par_verite'], <String, Object?>{
      'a': <String, Object?>{
        'koach': <String, Object?>{
          'n': 4,
          'moyenne_censuree': 9.25,
          'moyenne_atteints': 4.0,
          'mediane_censuree': 4.5,
          'part_jamais': 0.25,
        },
        'temoin': null,
      },
      'b': <String, Object?>{
        'koach': <String, Object?>{
          'n': 2,
          'moyenne_censuree': 13.5,
          'moyenne_atteints': 2.0,
          'mediane_censuree': 13.5,
          'part_jamais': 0.5,
        },
        'temoin': null,
      },
      'c': <String, Object?>{
        'koach': <String, Object?>{
          'n': 4,
          'moyenne_censuree': 8.5,
          'moyenne_atteints': 3.0,
          'mediane_censuree': 4.0,
          'part_jamais': 0.25,
        },
        'temoin': null,
      },
    });
    final c4 = kmCritereCouverture(a, 0.015);
    expect(c4['mesure'], 0.8823529411764706);
    expect(c4['n'], 17);
    expect(
      (c4['detail']! as _Json)['tous_modes_rangs_3_et_plus'],
      <String, Object?>{'n': 51, 'couverture': 0.8823529411764706},
    );
  });

  test('premier passage, statistiques, médiane, erreur-type', () {
    expect(kmPremierPassage(<int>[3, 0, 5, 2]), <String, Object?>{
      'n': 4,
      'moyenne_censuree': 8.75,
      'moyenne_atteints': 3.3333333333333335,
      'mediane_censuree': 4.0,
      'part_jamais': 0.25,
    });
    expect(kmStats(<double>[0.3, 0.1, 0.25, 0.7, 0.05]), <String, Object?>{
      'n': 5,
      'moyenne': 0.27999999999999997,
      'mediane': 0.25,
      'p95': 0.7,
      'max': 0.7,
    });
    expect(kmStats(<double>[0.3, 0.1, 0.25, 0.7]), <String, Object?>{
      'n': 4,
      'moyenne': 0.33749999999999997,
      'mediane': 0.275,
      'p95': 0.7,
      'max': 0.7,
    });
    final m = kmMediane(<int>[3, 1, 2]);
    expect(m, 2);
    expect(m, isA<int>());
    expect(kmMediane(<int>[3, 1, 2, 8]), 2.5);
    expect(kmMediane(<double?>[0.5, null, 0.25]), 0.375);
    expect(
      kmErreurType(<double>[0.013, -0.004, 0.021, 0.0071]),
      0.005262346593171783,
    );
    expect(kmMoyenne(<double?>[0.013, -0.004, null, 0.021]), 0.01);
  });

  test('classement des constats (campagne.classer_constats)', () {
    final initial = <_Json>[
      _c('volume_trop_vite', week: 3, value: 12.0, limit: 10.0),
      _c('plafond_volume', week: 1, value: 18.0, limit: 12.0),
      _c('tendon_figures', week: 2, day: 1, ex: 'ex_b', value: 4.0, limit: 3.0),
      _c('plafond_volume', value: 5.0, limit: 4.0),
    ];
    final servi = <_Json>[
      _c('volume_trop_vite', week: 3, value: 12.0, limit: 10.0),
      _c('plafond_volume', week: 1, value: 21.0, limit: 12.0),
      _c('plafond_volume', week: 1, value: 19.0, limit: 12.0),
      _c('tendon_figures', week: 2, day: 1, ex: 'ex_b', value: 4.0, limit: 3.0),
      _c('tendon_figures', week: 2, day: 0, ex: "ex'a", value: 5.0, limit: 3.0),
      _c('charge_trop_vite', week: 4, day: 2, ex: 'ex_c', limit: 0.1),
      _c('plafond_volume', value: 6.0, limit: 4.0),
      _c('rir_trop_bas', week: 10, day: 3, ex: 'ex_d', value: 0.0, limit: 1.0),
    ];
    final (out, exemples) = kmClasserConstats(initial, servi);
    expect(out, <String, Object?>{
      'aggrave': <String, Object?>{'plafond_volume': 2},
      'deja_initial': <String, Object?>{
        'tendon_figures': 1,
        'volume_trop_vite': 1,
      },
      'introduit': <String, Object?>{
        'charge_trop_vite': 1,
        'plafond_volume': 1,
        'rir_trop_bas': 1,
        'tendon_figures': 1,
      },
    });
    expect(exemples, <Object?>[
      <String, Object?>{
        'categorie': 'introduit',
        'code': 'charge_trop_vite',
        'semaine': 4,
        'jour': 2,
        'exercice': 'ex_c',
        'valeur': null,
        'limite': 0.1,
      },
      <String, Object?>{
        'categorie': 'aggrave',
        'code': 'plafond_volume',
        'semaine': 1,
        'jour': null,
        'exercice': null,
        'valeur': 19.0,
        'limite': 12.0,
      },
      <String, Object?>{
        'categorie': 'introduit',
        'code': 'plafond_volume',
        'semaine': 1,
        'jour': null,
        'exercice': null,
        'valeur': 21.0,
        'limite': 12.0,
      },
    ]);
    expect(kmReprPy("ex'a"), '"ex\'a"');
    expect(kmReprPy(null), 'None');
    expect(kmReprPy(1e-05), '1e-05');
    expect(kmReprPy(12.0), '12.0');
  });

  test(
    'critère 5 : calibration par cible, mesure de KM1 et mesure C13.11.2',
    () {
      final ok = _saisonsCalibration();
      final c5 = kmCritereCalibration(ok, false);
      // Mesure fixée (C13.11.2) : graines 0 à 5, une prévision par cible.
      expect(c5['mesure'], 0.5977166666666667);
      expect(c5['n'], 648);
      expect(c5['respecte'], isFalse);
      final d = c5['detail']! as _Json;
      final k2 = d['mesure_km2']! as _Json;
      expect(k2['deciles_peuples'], 6);
      expect(k2['graines_completes'], isTrue);
      expect(k2['graines_presentes'], <int>[0, 1, 2, 3, 4, 5]);
      expect(d['mesurable'], isTrue);
      final dec = k2['deciles']! as List<Object?>;
      expect(dec[9], <String, Object?>{
        'decile': 9,
        'n': 72,
        'p_prevue': 0.93105,
        'observee': 0.3333333333333333,
        'ecart': 0.5977166666666667,
      });
      expect(dec[2], <String, Object?>{
        'decile': 2,
        'n': 180,
        'p_prevue': 0.2511,
        'observee': 0.4,
        'ecart': 0.14890000000000003,
      });
      // Mesure de KM1 et compléments, comme la référence.
      final k1 = d['mesure_km1']! as _Json;
      expect(k1['mesure'], 0.4920142857142857);
      expect(k1['n'], 2436);
      final pc = d['par_cible']! as _Json;
      expect(pc['ecart_max'], 0.4920142857142857);
      expect(pc['deciles_peuples'], 7);
      expect(pc['erreur_ponderee_tous_cas'], 0.22627413793103449);
      expect(pc['part_des_cas_juges'], 1.0);
      final une = pc['une_prevision_par_cible']! as _Json;
      expect(une['n'], 756);
      expect(une['ecart_max'], 0.5024785714285716);
      final tc = d['toutes_les_cibles']! as _Json;
      expect(tc['ecart_max_deciles_n20'], 0.28107096857142855);
      expect(tc['dates_insuffisantes'], <String, Object?>{});
      final debut = (tc['par_date']! as _Json)['debut']! as _Json;
      expect(debut['p_moyenne'], 0.15832279);
      expect(debut['reussite_observee'], 0.17142857142857143);
      expect(d['exclusions'], <String, Object?>{'sans_echeance': 210});
      expect(d['unites_sans_prevision_a_la_date'], <String, Object?>{
        'moins_4_semaines': 42,
      });
    },
  );
}
