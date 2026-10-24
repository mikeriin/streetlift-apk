// La rampe de volume ne coupe jamais sous l'écrit du programme (Koach
// 1.0.7, lot KM5, DECISIONS_CP.md C17.40) : port, test pour test, de la
// référence Python `reference/tests/test_km5_rampe.py`
// (CHANGEMENTS_1_0_7.md, contrat § 8.5). Mêmes scénarios, mêmes valeurs
// attendues : le moteur Dart doit se comporter exactement comme la
// référence.
//
// 1. aucune série ni aucun exercice retiré au nom du volume : un programme
//    choisi plus volumineux que les semaines d'avant est servi tel qu'écrit ;
// 2. la rampe borne seulement ce que Koach AJOUTE au-dessus de l'écrit
//    (`koachVolume`) : par groupe et par semaine, servi ≤ max(limite de la
//    rampe, écrit de la semaine) ; raison `koach.ajout_borne` ;
// 3. coupes sous l'écrit gardées pour leurs causes : douleur, rampe
//    tendineuse des tenues bras tendus ;
// 4. scénarios du prompt (C17.40.2) : (a) programme B plus volumineux servi
//    tel qu'écrit ; (b) douleur à l'épaule le mardi ; (c) ajout borné.
//
// Points portés par un équivalent observable (méthodes privées d'une autre
// bibliothèque) :
// - `Seances._limite_volume(g, 3)` : lu dans `retourVol!.limites[g]` après
//   la prescription d'une séance de la semaine 3 (même calcul) ;
// - `Seances._ecrites` : lu dans le paramètre `ecrites` de
//   `koach.ajout_borne` et par l'absence de borne d'une ligne sous son écrit.
//
// Données synthétiques seulement (C17.33).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

final Json _s = jm(_params['securite']);

final List<Object?> _groupes = jl(_s['volume_groupes_majeurs']);

final int _chest = _groupes.indexOf('chest');
final int _dant = _groupes.indexOf('delt_anterior');
final int _tri = _groupes.indexOf('triceps');

const String _mu = 'sl-muscle-up-leste';
const String _tl = 'sl-traction-lestee';
const String _fp = 'mu-face-pull-corde';
const String _cu = 'mu-curl-barre-ez';
const String _rw = 'mu-rowing-pendlay';
const String _dl = 'sl-dips-leste';
const String _tp = 'sw-traction-pronation';
const String _pl = 'sl-pompe-lestee-gilet';
const String _dm = 'mu-developpe-militaire-barre-debout';
const String _re = 'mu-rotation-externe-poulie';
const String _et = 'mu-extension-triceps-poulie-croisee';
const String _el = 'mu-elevation-laterale-halteres';
const String _pp = 'sw-pompe';
const String _pd = 'sw-pompe-declinee';
const String _sq = 'mu-back-squat-barre-basse';

const List<String> _volumeCodes = ['koach.ajout_borne', 'koach.retour_gradue'];

Koach _koach() => Koach(copieJson(_params), _fiches, <String, Object?>{
  'niveau': 2,
  'sexe': 'male',
  'poids_kg': 75.0,
  'declares': <String, Object?>{},
  'zones_fragiles': <Object?>[],
});

Json _it(
  String slot,
  String ex,
  int sets, {
  String? role,
  int? ajout,
  (int, int) reps = (3, 6),
}) => <String, Object?>{
  'slotId': slot,
  'exerciseId': ex,
  'kind': 'work',
  'sets': sets + (ajout ?? 0),
  'repsLow': reps.$1,
  'repsHigh': reps.$2,
  'targetFlames': 7,
  if (role != null) 'role': role,
  if (ajout != null) 'koachVolume': ajout,
};

Json _rolesDe(List<Json> items) => <String, Object?>{
  for (final x in items) x['slotId'] as String: x['role'],
};

const List<String> _clesVolume = [
  'slotId',
  'exerciseId',
  'kind',
  'sets',
  'targetFlames',
  'secondsLow',
  'secondsHigh',
  'role',
];

List<Object?> _volume(List<Json> items) => <Object?>[
  for (final x in items)
    <String, Object?>{for (final k in _clesVolume) k: x[k]},
];

/// Ouvre, sert et ferme la séance [items] du jour [jour] ; renvoie (items
/// servis, raisons).
(List<Json>, List<Json>) _seance(
  Koach k,
  int jour,
  List<Json> items, {
  List<List<Json>> reste = const [],
  List<(int, List<Json>)> manquees = const [],
  List<Object?>? douleurs,
  Map<String, (Json, Set<String>)> zones = const {},
  String genre = 'accumulation',
}) {
  final c = <String, Object?>{
    'semaine': jour ~/ 7,
    'genre': genre,
    'reste_semaine': <Object?>[for (final r in reste) _volume(r)],
    'manquees': <Object?>[
      for (final (w, m) in manquees)
        <String, Object?>{
          'semaine': w,
          'genre': 'accumulation',
          'items': _volume(m),
        },
    ],
  };
  Json? bilan;
  k.garde.avancer(jour);
  if (douleurs != null) {
    bilan = <String, Object?>{'overall': 4, 'pains': douleurs};
    k.garde.noterSeance(jour, douleurs, posee: true);
  }
  k.seances.ouvrir(jour, bilan, c);
  final out = k.seances.prescrire(
    [for (final x in items) copieJson(x)],
    <String, Grille>{},
    zones,
    _rolesDe(items),
  );
  final raisons = List<Json>.of(k.seances.raisons);
  final sets = <Object?>[];
  for (final x in out) {
    for (var i = 0; i < ent(x['sets']); i++) {
      sets.add(<String, Object?>{
        'exerciseId': x['exerciseId'],
        'slotId': x['slotId'],
        'setIndex': i,
        'kind': x['kind'],
        'reps': x['repsHigh'],
        'flames': 7,
        'failed': false,
        'target': <String, Object?>{'flames': 7},
      });
    }
  }
  k.seances.fermer(<String, Object?>{'sets': sets});
  return (out, raisons);
}

int _series(List<Json> out, String slot) {
  for (final x in out) {
    if (x['slotId'] == slot) {
      return ent(x['sets']);
    }
  }
  return 0;
}

List<(int, double)> _credits(String ex) => <(int, double)>[
  for (final gw in jl(_fiches[ex]!['groupes']))
    if ((jl(gw)[0] as num) < _groupes.length)
      (ent(jl(gw)[0]), (dbl(jl(gw)[1]) * 2 + 0.5).floor() / 2.0),
];

double _ecrit(List<List<Json>> seances, int g) {
  var t = 0.0;
  for (final s in seances) {
    for (final x in s) {
      final n = ent(x['sets']) - ent(x['koachVolume'] ?? 0);
      for (final (gi, c) in _credits(x['exerciseId'] as String)) {
        if (gi == g) {
          t += c * n;
        }
      }
    }
  }
  return t;
}

List<Json> _codes(List<Json> raisons, List<String> cs) => <Json>[
  for (final r in raisons)
    if (cs.contains(r['code'])) r,
];

List<(String, int)> _lignes(List<Json> items) => <(String, int)>[
  for (final x in items) (x['slotId'] as String, ent(x['sets'])),
];

// Programmes synthétiques du constat (C17.40.2).
List<List<Json>> _programmeA() => [
  [
    _it('a0.1', _dl, 6, role: 'main'),
    _it('a0.2', _pl, 4, role: 'secondary'),
    _it('a0.3', _et, 1, role: 'accessory'),
  ],
  [
    _it('a1.1', _tl, 8, role: 'main'),
    _it('a1.2', _mu, 5, role: 'main'),
    _it('a1.3', _rw, 4, role: 'secondary'),
    _it('a1.4', _fp, 3, role: 'accessory'),
    _it('a1.5', _cu, 3, role: 'accessory'),
  ],
  [_it('a2.1', _sq, 8, role: 'main')],
  [
    _it('a3.1', _dl, 5, role: 'main'),
    _it('a3.2', _tl, 5, role: 'secondary'),
    _it('a3.3', _rw, 3, role: 'accessory'),
  ],
];

List<List<Json>> _programmeB() => [
  [
    _it('b0.1', _mu, 6, role: 'main', reps: (2, 2)),
    _it('b0.2', _tl, 8, role: 'main', reps: (3, 3)),
    _it('b0.3', _rw, 3, role: 'secondary'),
    _it('b0.4', _fp, 3, role: 'accessory'),
    _it('b0.5', _cu, 3, role: 'accessory'),
  ],
  [
    _it('b1.1', _dl, 8, role: 'main', reps: (3, 3)),
    _it('b1.2', _tp, 8, role: 'secondary', reps: (5, 5)),
    _it('b1.3', _pl, 4, role: 'secondary', reps: (6, 6)),
    _it('b1.4', _dm, 3, role: 'secondary', reps: (8, 8)),
    _it('b1.5', _re, 2, role: 'accessory', reps: (15, 15)),
    _it('b1.6', _et, 3, role: 'accessory', reps: (12, 12)),
    _it('b1.7', _el, 3, role: 'accessory', reps: (15, 15)),
  ],
  [_it('b2.1', _sq, 5, role: 'main')],
  [
    _it('b3.1', _tl, 5, role: 'main'),
    _it('b3.2', _rw, 4, role: 'secondary'),
    _it('b3.3', _fp, 3, role: 'accessory'),
  ],
  [
    _it('b4.1', _dl, 5, role: 'main'),
    _it('b4.2', _pl, 3, role: 'secondary'),
    _it('b4.3', _et, 3, role: 'accessory'),
  ],
  [_it('b5.1', _sq, 5, role: 'main')],
];

void _troisSemainesA(Koach k) {
  for (var w = 0; w < 3; w++) {
    final a = _programmeA();
    for (var i = 0; i < a.length; i++) {
      _seance(k, 7 * w + const [0, 1, 3, 5][i], a[i], reste: a.sublist(i + 1));
    }
  }
}

void _semainesDips(Koach k, int series) {
  for (var w = 0; w < 3; w++) {
    _seance(k, 7 * w, [_it('x$w', _dl, series, role: 'main')]);
  }
}

void main() {
  test('volumes du scénario', () {
    final a = _programmeA();
    final b = _programmeB();
    expect(
      [_ecrit(a, _chest), _ecrit(a, _dant), _ecrit(a, _tri)],
      // 1.0.8 (KM6, C17.47) : crédits « chest » revus (tractions 0,
      // muscle-up 0,5) ; avec ceux de 1.0.7 : 26,5 et 38,0.
      [17.5, 17.5, 21.0],
    );
    expect(
      [_ecrit(b, _chest), _ecrit(b, _dant), _ecrit(b, _tri)],
      [24.5, 27.5, 33.5],
    );
  });

  test('(a) programme plus volumineux servi tel qu’écrit', () {
    final k = _koach();
    _troisSemainesA(k);
    final b = _programmeB();
    for (var i = 0; i < b.length; i++) {
      final (out, raisons) = _seance(k, 21 + i, b[i], reste: b.sublist(i + 1));
      expect(_lignes(out), _lignes(b[i]), reason: 'séance $i');
      expect(_codes(raisons, _volumeCodes), isEmpty, reason: 'séance $i');
      if (i == 1) {
        final rv = k.seances.retourVol!;
        expect(rv.depasse, isEmpty);
        expect(rv.limites[_dant], lessThan(rv.ecrit[_dant]));
        expect(rv.limites[_tri], lessThan(rv.ecrit[_tri]));
        expect(rv.plafonds[_dant], _ecrit(b, _dant));
        expect(rv.plafonds[_tri], _ecrit(b, _tri));
        expect(rv.plan, <String?, int>{
          for (final x in b[1])
            if (_credits(x['exerciseId'] as String).isNotEmpty)
              x['slotId'] as String: ent(x['sets']),
        });
      }
    }
    expect(k.seances.volSemaines[3]![_dant], _ecrit(b, _dant));
  });

  test('programme B de KM4 (C17.37) servi tel qu’écrit', () {
    final k = _koach();
    for (var w = 0; w < 3; w++) {
      final a = [
        [
          _it('a0.1', _dl, 5, role: 'main'),
          _it('a0.2', _pp, 4, role: 'secondary'),
        ],
        [
          _it('a1.1', _tl, 4, role: 'main'),
          _it('a1.2', _rw, 5, role: 'secondary'),
          _it('a1.3', _fp, 4, role: 'accessory'),
        ],
        [_it('a2.1', _sq, 8, role: 'main')],
        [
          _it('a3.1', _dl, 4, role: 'main'),
          _it('a3.2', _pp, 3, role: 'secondary'),
          _it('a3.3', _tl, 4, role: 'secondary'),
          _it('a3.4', _rw, 3, role: 'accessory'),
        ],
      ];
      for (var i = 0; i < a.length; i++) {
        _seance(
          k,
          7 * w + const [0, 1, 3, 5][i],
          a[i],
          reste: a.sublist(i + 1),
        );
      }
    }
    final b = [
      [
        _it('b0.1', _mu, 6, role: 'main'),
        _it('b0.2', _tl, 4, role: 'main'),
        _it('b0.3', 'mu-pull-over-haltere', 3, role: 'accessory'),
        _it('b0.4', _fp, 3, role: 'accessory'),
      ],
      [
        _it('b1.1', _dl, 5, role: 'main'),
        _it('b1.2', _pp, 3, role: 'secondary'),
        _it('b1.3', _pd, 2, role: 'accessory'),
      ],
      [_it('b2.1', _sq, 5, role: 'main')],
    ];
    final (out, raisons) = _seance(k, 21, b[0], reste: b.sublist(1));
    expect([for (final x in out) ent(x['sets'])], [6, 4, 3, 3]);
    expect(_codes(raisons, _volumeCodes), isEmpty);
  });

  test('(b) douleur à l’épaule le mardi : la conduite sous douleur coupe', () {
    final zones = <String, (Json, Set<String>)>{
      for (final ex in const [_dl, _pl, _dm, _el, _re])
        ex: (<String, Object?>{'shoulder': 1.0}, <String>{'shoulder'}),
    };
    final k = _koach();
    _troisSemainesA(k);
    final b = _programmeB();
    _seance(k, 21, b[0], reste: b.sublist(1));
    final (out, raisons) = _seance(
      k,
      22,
      b[1],
      reste: b.sublist(2),
      zones: zones,
      douleurs: <Object?>[
        <String, Object?>{'zone': 'shoulder', 'intensity': 4},
      ],
    );
    expect(_lignes(out), [('b1.2', 8), ('b1.6', 3)]);
    expect(
      [
        for (final r in _codes(raisons, ['koach.douleur_retrait']))
          jm(r['params'])['exercice'],
      ],
      [_dl, _pl, _dm, _re, _el],
    );
    expect(_codes(raisons, _volumeCodes), isEmpty);
  });

  test('(c) ajout de Koach borné', () {
    var k = _koach();
    _semainesDips(k, 10);
    var s = [
      _it('m.1', _dl, 6, role: 'main', ajout: 2),
      _it('m.2', _pp, 4, role: 'secondary', ajout: 1),
      _it('m.3', _pd, 2, role: 'accessory', ajout: 2),
    ];
    var (out, raisons) = _seance(k, 21, s);
    expect(k.seances.retourVol!.limites[_chest], 12.0);
    expect(
      [_series(out, 'm.1'), _series(out, 'm.2'), _series(out, 'm.3')],
      [6, 4, 2],
    );
    expect(
      [
        for (final r in _codes(raisons, ['koach.ajout_borne']))
          () {
            final p = jm(r['params']);
            return [
              p['exercice'],
              p['series'],
              p['ecrites'],
              p['prevues'],
              p['groupe'],
              p['limite'],
              p['ecrit'],
            ];
          }(),
      ],
      [
        [_dl, 6, 6, 8, 'chest', 12.0, 12.0],
        [_pp, 4, 4, 5, 'chest', 12.0, 12.0],
        [_pd, 2, 2, 4, 'chest', 12.0, 12.0],
      ],
    );
    expect(_codes(raisons, ['koach.retour_gradue']), isEmpty);
    k = _koach();
    _semainesDips(k, 10);
    s = [
      _it('m.1', _dl, 6, role: 'main', ajout: 2),
      _it('m.2', _pp, 2, role: 'secondary', ajout: 1),
      _it('m.3', _pd, 1, role: 'accessory', ajout: 2),
    ];
    (out, raisons) = _seance(k, 21, s);
    expect(
      [_series(out, 'm.1'), _series(out, 'm.2'), _series(out, 'm.3')],
      [8, 3, 1],
    );
    expect(
      [
        for (final r in _codes(raisons, ['koach.ajout_borne']))
          ent(jm(r['params'])['prevues']) - ent(jm(r['params'])['series']),
      ],
      [2],
    );
  });

  test('ajout : la ligne la plus tardive d’abord', () {
    final k = _koach();
    _semainesDips(k, 10);
    final (out, _) = _seance(k, 21, [
      _it('m.1', _dl, 5, role: 'main', ajout: 1),
      _it('m.2', _pp, 3, role: 'accessory', ajout: 2),
      _it('m.3', _pd, 3, role: 'accessory', ajout: 2),
    ]);
    expect(
      [_series(out, 'm.1'), _series(out, 'm.2'), _series(out, 'm.3')],
      [6, 3, 3],
    );
  });

  test('jamais sous l’écrit, même au-dessus de la limite', () {
    final k = _koach();
    _semainesDips(k, 2);
    final s = [
      _it('m.1', _dl, 10, role: 'main'),
      _it('m.2', _pp, 6, role: 'secondary'),
      _it('m.3', _pd, 6, role: 'accessory'),
    ];
    final reste = [
      for (var i = 0; i < 4; i++)
        [
          _it('r$i.1', _dl, 10, role: 'main'),
          _it('r$i.2', _pp, 6, role: 'secondary'),
        ],
    ];
    final (out, raisons) = _seance(k, 21, s, reste: reste);
    expect([for (final x in out) ent(x['sets'])], [10, 6, 6]);
    expect(_codes(raisons, _volumeCodes), isEmpty);
    final rv = k.seances.retourVol!;
    expect(rv.depasse, isEmpty);
    expect(rv.limites[_chest], 4.0);
    expect(rv.plafonds[_chest], 22.0 + 4 * 16.0);
    expect(rv.ecrit[_chest], 22.0 + 4 * 16.0);
  });

  test('sans rôle et sans ajout, rien n’est coupé', () {
    final k = _koach();
    for (var w = 0; w < 3; w++) {
      _seance(k, 7 * w, [_it('x$w', _dl, 2)]);
    }
    final (out, raisons) = _seance(k, 21, [
      _it('m.1', _dl, 6),
      _it('m.2', _pp, 4),
      _it('m.3', _pd, 4),
    ]);
    expect([for (final x in out) ent(x['sets'])], [6, 4, 4]);
    expect(_codes(raisons, _volumeCodes), isEmpty);
  });

  test('sans rôle, la première ligne créditée est le principal', () {
    final k = _koach();
    for (var w = 0; w < 3; w++) {
      _seance(k, 7 * w, [_it('x$w', _dl, 10)]);
    }
    final (out, _) = _seance(k, 21, [
      _it('m.1', _dl, 6, ajout: 2),
      _it('m.2', _pp, 6, ajout: 2),
    ]);
    expect([_series(out, 'm.1'), _series(out, 'm.2')], [6, 6]);
  });

  test('séance manquée comptée à l’écrit', () {
    final k = _koach();
    _semainesDips(k, 6);
    final (out, raisons) = _seance(
      k,
      23,
      [_it('m.1', _dl, 8, role: 'main'), _it('m.2', _pp, 4, role: 'accessory')],
      manquees: [
        (3, [_it('q.1', _dl, 8, role: 'main')]),
      ],
    );
    expect([for (final x in out) ent(x['sets'])], [8, 4]);
    expect(_codes(raisons, _volumeCodes), isEmpty);
    expect(k.seances.retourVol!.ecrit[_chest], 20.0);
    expect(k.seances.retourVol!.fait[_chest], 8.0);
  });

  test('ajout négatif : la ligne sous son écrit n’est pas touchée', () {
    final k = _koach();
    _semainesDips(k, 4);
    final (out, raisons) = _seance(k, 21, [
      _it('m.1', _dl, 10, role: 'main', ajout: -1),
    ]);
    expect(_series(out, 'm.1'), 9);
    expect(_codes(raisons, _volumeCodes), isEmpty);
  });

  test('allègement : seuls les ajouts sont bornés', () {
    final k = _koach();
    for (var w = 0; w < 3; w++) {
      _seance(k, 7 * w, [
        _it('x$w', _dl, 10, role: 'main'),
        _it('y$w', _sq, 10, role: 'main'),
      ]);
    }
    final (out, raisons) = _seance(k, 21, [
      _it('m.1', _dl, 4, role: 'main', ajout: 4),
      _it('m.2', _sq, 4, role: 'main', ajout: 4),
    ], genre: 'deload');
    final rv = k.seances.retourVol!;
    expect(rv.limiteDures, dbl(_s['decharge_part']) * 20.0);
    expect(rv.plafondDures, 14.0);
    expect([_series(out, 'm.1'), _series(out, 'm.2')], [8, 6]);
    expect(
      {
        for (final r in _codes(raisons, ['koach.ajout_borne']))
          jm(r['params'])['groupe'],
      },
      {'allegement'},
    );
  });

  test('allègement d’un diagnostic : koachVolume gardé', () {
    final sv = Surveillance(copieJson(_params));
    sv.allegement = (0, 7, 0.6, 1.0);
    final out = sv.appliquerAllegement([
      _it('a', _dl, 5),
      _it('b', _dl, 4, ajout: 1),
    ], 3);
    expect(
      [for (final x in out) (ent(x['sets']), ent(x['koachVolume']))],
      [(3, -2), (3, -1)],
    );
  });

  test('tenues bras tendus : règle tendineuse gardée', () {
    const tenue = 'cs-90-hold';
    final k = _koach();
    for (var w = 0; w < 3; w++) {
      _seance(k, 7 * w, [
        <String, Object?>{
          'slotId': 'h$w',
          'exerciseId': tenue,
          'kind': 'work',
          'sets': 3,
          'secondsLow': 10,
          'secondsHigh': 10,
          'targetFlames': 7,
        },
      ]);
    }
    final (out, raisons) = _seance(k, 21, [
      <String, Object?>{
        'slotId': 'h',
        'exerciseId': tenue,
        'kind': 'work',
        'sets': 8,
        'secondsLow': 20,
        'secondsHigh': 20,
        'targetFlames': 7,
      },
    ]);
    expect(
      [
        for (final x in out)
          (ent(x['sets']), x['secondsLow'], x['secondsHigh']),
      ],
      [(7, 5, 5)],
    );
    expect(
      [
        for (final r in _codes(raisons, ['koach.retour_gradue'])) r['params'],
      ],
      [
        <String, Object?>{
          'exercice': tenue,
          'groupe': 'bras_tendus_push',
          'limite': 35.0,
          'series': 7,
          'secondes': 5,
          'ecrites': 8,
          'douleur': false,
        },
      ],
    );
    expect(_codes(raisons, ['koach.ajout_borne']), isEmpty);
  });

  test('douleur sur une ligne, ajouts sur une autre (relecture M1)', () {
    final zones = <String, (Json, Set<String>)>{
      _dl: (<String, Object?>{'shoulder': 1.0}, <String>{'shoulder'}),
    };
    final k = _koach();
    for (var w = 0; w < 4; w++) {
      _seance(k, 7 * w, [_it('x$w', _dl, 4, role: 'main')], zones: zones);
    }
    final (out, raisons) = _seance(
      k,
      28,
      [
        _it('m.1', _dl, 12, role: 'main'),
        _it('m.2', _pp, 4, role: 'secondary', ajout: 8),
      ],
      zones: zones,
      douleurs: <Object?>[
        <String, Object?>{'zone': 'shoulder', 'intensity': 4},
      ],
    );
    expect(_lignes(out), [('m.2', 6)]);
    final rv = k.seances.retourVol!;
    expect(
      [rv.limites[_chest], rv.ecrit[_chest], rv.plafonds[_chest]],
      [6.0, 4.0, 6.0],
    );
    expect(
      [
        for (final r in _codes(raisons, ['koach.ajout_borne']))
          jm(r['params'])['series'],
      ],
      [6],
    );
    expect(_codes(raisons, ['koach.douleur_retrait']), isNotEmpty);
  });

  test('allègement décidé sur l’écrit du programme (relecture M2)', () {
    final k = _koach();
    _semainesDips(k, 10);
    final (out, raisons) = _seance(k, 21, [
      _it('m.1', _dl, 6, role: 'main', ajout: 3),
    ]);
    final rv = k.seances.retourVol!;
    expect([rv.limiteDures, rv.plafondDures], [7.0, 7.0]);
    expect(_series(out, 'm.1'), 7);
    expect(
      [
        for (final r in _codes(raisons, ['koach.ajout_borne']))
          jm(r['params'])['groupe'],
      ],
      ['allegement'],
    );
  });

  test('deux prescriptions de la même séance (relecture m1)', () {
    final k = _koach();
    _semainesDips(k, 10);
    k.garde.avancer(21);
    k.seances.ouvrir(21, null, <String, Object?>{
      'semaine': 3,
      'genre': 'accumulation',
      'reste_semaine': <Object?>[],
      'manquees': <Object?>[],
    });
    final s = [
      _it('m.1', _dl, 6, role: 'main', ajout: 2),
      _it('m.2', _pp, 6, role: 'secondary', ajout: 4),
    ];
    List<int> servir() => [
      for (final x in k.seances.prescrire(
        [for (final x in s) copieJson(x)],
        <String, Grille>{},
        const {},
        _rolesDe(s),
      ))
        ent(x['sets']),
    ];
    expect(servir(), [6, 6]);
    expect(servir(), [6, 6]);
    expect(k.seances.ecritVol[3]![_chest], 12.0);
  });

  test('paramètres 1.0.7', () {
    expect(_params['version'], '1.0.8-ref.1');
    for (final cle in const [
      'retour_plancher_principal',
      'retour_repartition_semaines',
      'retour_emprunt_plancher',
    ]) {
      expect(_s.containsKey(cle), isFalse, reason: cle);
    }
    expect(
      jm(_params['rupture']).containsKey('elargissement_rien_de_special'),
      isFalse,
    );
  });
}
