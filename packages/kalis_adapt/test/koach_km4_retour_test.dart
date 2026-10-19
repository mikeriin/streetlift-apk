// Retour gradué au volume réparti sur la semaine et priorisé par rôle
// (Koach 1.0.6, lot KM4) : port, test pour test, de la référence Python
// `reference/tests/test_km4_retour.py` (CHANGEMENTS_1_0_6.md, contrat
// § 8.5). Mêmes scénarios, mêmes valeurs attendues (séries servies,
// réalisé de la semaine, raisons) : le moteur Dart doit se comporter
// exactement comme la référence.
//
// 1. répartition : sans séance manquée récente, la réduction d'un groupe se
//    répartit sur toutes les séances de la semaine qui le créditent ;
// 2. priorité de rôle : accessoires d'abord, secondaires ensuite, principaux
//    en dernier ; sans rôle, la première ligne dure de la séance est le
//    principal ;
// 3. plancher des principaux : jamais 0 série par la rampe sans douleur ;
//    max(1, ⌈écrit × 0,5⌉) avant de couper un secondaire à 0 ; la conduite
//    sous douleur garde la main ;
// 4. mode prudent (séance manquée dans les quatre dernières semaines) : la
//    séance du jour paie d'abord jusqu'au plancher de ses principaux ;
// 5. scénario dédié (C17.37) : trois semaines d'un programme A, puis un
//    programme B de six séances par semaine en PPL, +40 % de volume
//    « chest », séance de tirage en premier (muscle-up lesté E2MOM 6 × 2,
//    traction lestée, accessoires) : muscle-up lesté et traction lestée
//    servis, les accessoires réduits avant eux, limite de la semaine tenue.
//
// Points portés par un équivalent observable (un test ne peut pas appeler
// une méthode privée d'une autre bibliothèque) :
// - `test_scenario_c17_37_reparti` lit `Seances._limite_volume(CHEST, 3)`
//   avant la semaine 3 : ici, la limite est lue dans
//   `retourVol!.limites[_chest]` après l'ouverture et la prescription du
//   lundi de la semaine 3 (`_budgetsRetour` la calcule par
//   `_limiteVolume(gi, 3)`, et le réalisé de la semaine 3 est encore vide :
//   même valeur, 24, vérifiée sur la référence).
// - `test_principal_sous_douleur_sans_plancher` appelle
//   `Seances._douleur_unite` : ici, le drapeau `douleur` des raisons
//   `koach.retour_gradue` (calculé par `_douleurUnite`) sur deux scénarios
//   vérifiés sur la référence : sans douleur, `douleur` faux et le principal
//   à la limite ; zone sensible sous la rampe du réalisé (épisode d'épaule
//   puis semaine suivante), `douleur` vrai sur les dips lestés seuls, servis
//   sous leur plancher (4 < ⌈10 × 0,5⌉) : la conduite sous douleur garde la
//   main.
// Tests non portés : aucun.
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

const String _mu = 'sl-muscle-up-leste'; // chest 1,0
const String _tl = 'sl-traction-lestee'; // chest 0,5
const String _po = 'mu-pull-over-haltere'; // chest 1,0 (accessoire)
const String _fp = 'mu-face-pull-corde'; // aucun crédit chest
const String _dl = 'sl-dips-leste'; // chest 1,0
const String _pp = 'sw-pompe'; // chest 1,0
const String _pd = 'sw-pompe-declinee'; // chest 1,0
const String _sq = 'mu-back-squat-barre-basse';
const String _rw = 'mu-rowing-pendlay'; // aucun crédit chest

const String _sh = 'shoulder';

int _n(String k) => ent(_s[k]);

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
  int flames = 7,
  String kind = 'work',
  String? role,
}) => <String, Object?>{
  'slotId': slot,
  'exerciseId': ex,
  'kind': kind,
  'sets': sets,
  'repsLow': 3,
  'repsHigh': 6,
  'targetFlames': flames,
  if (role != null) 'role': role,
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

/// Ouvre, sert et ferme la séance [items] du jour [jour] ; [reste] :
/// séances restantes de la semaine (écrit) ; [manquees] : semaines des
/// séances manquées versées au contexte ; [douleurs] signalées au bilan ;
/// [zones] : id -> (niveaux de zone, zones provoquées) ; renvoie (items
/// servis, raisons).
(List<Json>, List<Json>) _seance(
  Koach k,
  int jour,
  List<Json> items, {
  List<List<Json>> reste = const [],
  List<int> manquees = const [],
  bool roles = true,
  List<Object?>? douleurs,
  Map<String, (Json, Set<String>)> zones = const {},
}) {
  final c = <String, Object?>{
    'semaine': jour ~/ 7,
    'genre': 'accumulation',
    'reste_semaine': <Object?>[for (final r in reste) _volume(r)],
    'manquees': <Object?>[
      for (final m in manquees)
        <String, Object?>{
          'semaine': m,
          'genre': 'accumulation',
          'items': <Object?>[],
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
    roles ? _rolesDe(items) : <String, Object?>{},
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

double _chestDe(Koach k, int semaine) {
  final v = k.seances.volSemaines[semaine];
  return (v == null || v.isEmpty) ? 0.0 : v[_chest];
}

/// Crédits de groupes de l'exercice [ex] (indices < 14), arrondis à la
/// demi-série.
List<(int, double)> _credits(String ex) => [
  for (final p in jl(_fiches[ex]!['groupes']))
    if (ent(jl(p)[0]) < 14)
      (ent(jl(p)[0]), (dbl(jl(p)[1]) * 2 + 0.5).floor() / 2.0),
];

double _ecritChest(List<List<Json>> seances) {
  var t = 0.0;
  for (final s in seances) {
    for (final x in s) {
      for (final (g, c) in _credits(x['exerciseId'] as String)) {
        if (g == _chest) {
          t += c * ent(x['sets']);
        }
      }
    }
  }
  return t;
}

// ----------------------------------------------------------------------
// Programmes synthétiques (scénario C17.37)
// ----------------------------------------------------------------------

/// Programme A, quatre séances par semaine (haut poussée, tirage, jambes,
/// haut) : 20 séries « chest », tirage et jambes au niveau de B.
List<List<Json>> _programmeA() => [
  [_it('a0.1', _dl, 5, role: 'main'), _it('a0.2', _pp, 4, role: 'secondary')],
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

/// Programme B, six séances par semaine en PPL, séance de tirage en
/// premier : 28 séries « chest » (+40 %).
List<List<Json>> _programmeB() => [
  [
    _it('b0.1', _mu, 6, role: 'main'),
    _it('b0.2', _tl, 4, role: 'main'),
    _it('b0.3', _po, 3, role: 'accessory'),
    _it('b0.4', _fp, 3, role: 'accessory'),
  ], // 6 + 2 + 3 = 11
  [
    _it('b1.1', _dl, 5, role: 'main'),
    _it('b1.2', _pp, 3, role: 'secondary'),
    _it('b1.3', _pd, 2, role: 'accessory'),
  ], // 10
  [_it('b2.1', _sq, 5, role: 'main')], // 0
  [_it('b3.1', _tl, 4, role: 'main'), _it('b3.2', _fp, 3, role: 'accessory')],
  [_it('b4.1', _dl, 3, role: 'main'), _it('b4.2', _pd, 2, role: 'accessory')],
  [_it('b5.1', _sq, 4, role: 'main')], // 0
];

int _troisSemainesA(Koach k) {
  var jour = 0;
  for (var w = 0; w < 3; w++) {
    final a = _programmeA();
    for (var i = 0; i < a.length; i++) {
      _seance(k, 7 * w + const [0, 1, 3, 5][i], a[i], reste: a.sublist(i + 1));
    }
    jour = 7 * (w + 1);
  }
  return jour;
}

/// Trois semaines d'une séance de dips lestés à [sets] séries (jours 0, 7,
/// 14).
void _troisSemainesDips(Koach k, int sets, {bool roles = true}) {
  for (var w = 0; w < 3; w++) {
    _seance(k, 7 * w, [
      _it('x$w', _dl, sets, role: roles ? 'main' : null),
    ], roles: roles);
  }
}

List<Json> _retourGradue(List<Json> raisons) {
  final rg = <Json>[];
  for (final r in raisons) {
    if (r['code'] == 'koach.retour_gradue') {
      rg.add(r);
    }
  }
  return rg;
}

Json _p(Json r) => jm(r['params']);

void main() {
  test('écrit « chest » du scénario : 20 (A) et 28 (B)', () {
    expect(_ecritChest(_programmeA()), 20.0);
    expect(_ecritChest(_programmeB()), 28.0);
  });

  test('scénario C17.37 réparti : muscle-up et traction lestés servis, '
      'accessoires réduits, limite tenue', () {
    final k = _koach();
    final j0 = _troisSemainesA(k);
    expect([for (var w = 0; w < 3; w++) _chestDe(k, w)], [20.0, 20.0, 20.0]);
    final b = _programmeB();
    final jours = [for (var d = 0; d < 6; d++) j0 + d];
    final servis = <List<Json>>[];
    double? limite;
    for (var i = 0; i < b.length; i++) {
      final (out, _) = _seance(k, jours[i], b[i], reste: b.sublist(i + 1));
      servis.add(out);
      if (i == 0) {
        expect(k.seances.retourVol!.repartie, isTrue);
        // Équivalent observable de `_limite_volume(CHEST, 3)` (en-tête).
        limite = k.seances.retourVol!.limites[_chest];
      }
    }
    // max(20 × 1,2 ; 20 + 2) ; deux semaines : 26.
    expect(limite, 24.0);
    final lundi = servis[0];
    // Muscle-up lesté et traction lestée servis à leur écrit : la réduction
    // (4 séries) est portée par les accessoires de la semaine.
    expect(_series(lundi, 'b0.1'), 6);
    expect(_series(lundi, 'b0.2'), 4);
    // Pull-over (accessoire) réduit.
    expect(_series(lundi, 'b0.3'), lessThan(3));
    // Face pull : aucun crédit chest.
    expect(_series(lundi, 'b0.4'), 3);
    expect(_chestDe(k, 3), lessThanOrEqualTo(limite! + 1e-9));
    // Répartition : le lundi ne paie pas tout (pull-over pas retiré seul).
    expect(_series(lundi, 'b0.3'), greaterThanOrEqualTo(1));
    final accessoires =
        _series(lundi, 'b0.3') +
        _series(servis[1], 'b1.3') +
        _series(servis[4], 'b4.2');
    expect(accessoires, lessThanOrEqualTo(7 - 4));
    for (final out in servis) {
      for (final x in out) {
        final slot = x['slotId'] as String;
        if (slot.endsWith('.1')) {
          final ecrit = _series([for (final s in b) ...s], slot);
          expect(ent(x['sets']), ecrit, reason: slot);
        }
      }
    }
  });

  test('scénario C17.37, ancien comportement pour mémoire : même lundi en '
      'mode prudent, accessoires d\'abord puis principaux au plancher', () {
    // 1.0.5 réservait tout l'écrit restant (17 séries) : budget du lundi =
    // 24 − 0 − 17 = 7 séries, coupées dans l'ordre de la séance (muscle-up
    // 6, puis traction 0,5 × 2 = 1 → 2 séries, pull-over 0) ; avec plus de
    // volume « chest » ailleurs dans la semaine, muscle-up et traction
    // tombaient à 0.
    final k = _koach();
    final j0 = _troisSemainesA(k);
    final b = _programmeB();
    // Plus de chest sur les séances de poussée : 36 séries écrites.
    b[1][0]['sets'] = 8;
    b[4][0]['sets'] = 6;
    b[4][1]['sets'] = 4;
    expect(_ecritChest(b), 36.0);
    // Séance manquée en semaine 2 : prudent.
    final (out, raisons) = _seance(
      k,
      j0,
      b[0],
      reste: b.sublist(1),
      manquees: const [2],
    );
    expect(k.seances.retourVol!.repartie, isFalse);
    // Écrit restant 25 ; budget 24 − 25 < 0 : le lundi paie jusqu'aux
    // planchers.
    expect(_series(out, 'b0.3'), 0); // accessoire coupé d'abord
    expect(_series(out, 'b0.1'), 3); // muscle-up : ⌈6 × 0,5⌉
    expect(_series(out, 'b0.2'), 2); // traction lestée : ⌈4 × 0,5⌉
    expect(_series(out, 'b0.4'), 3);
    final rg = _retourGradue(raisons);
    expect({for (final r in rg) _p(r)['exercice']}, {_mu, _tl, _po});
    for (final r in rg) {
      expect(_p(r)['groupe'], 'chest');
      expect(dbl(_p(r)['limite']), 24.0);
      expect(_p(r)['douleur'], isFalse);
    }
    expect([for (final r in rg) _p(r)['ecrites']], [6, 4, 3]);
  });

  test('jamais zéro pour un principal sans douleur', () {
    // Budget très négatif (semaine de reprise basse puis écrit énorme) :
    // principaux à 1 série au moins, secondaires et accessoires à 0.
    final k = _koach();
    _troisSemainesDips(k, 2);
    const jour = 21;
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
    final (out, _) = _seance(k, jour, s, reste: reste);
    expect(_series(out, 'm.1'), 1);
    expect(_series(out, 'm.2'), 0);
    expect(_series(out, 'm.3'), 0);
    // Limite 4 (max(2 × 1,2 ; 2 + 2)) : cinq principaux à 1 série dépassent
    // encore ; le dépassement est dit (`depasse`), aucun principal n'est
    // retiré (règle C17.37 ; le banc mesure qu'il n'arrive jamais).
    expect(k.seances.retourVol!.depasse, [
      _chest,
      _groupes.indexOf('delt_anterior'),
      _groupes.indexOf('triceps'),
    ]);
  });

  test('priorité de rôle dans la séance', () {
    var k = _koach();
    _troisSemainesDips(k, 10);
    final s = [
      _it('m.1', _dl, 6, role: 'main'),
      _it('m.2', _pp, 4, role: 'secondary'),
      _it('m.3', _pd, 4, role: 'accessory'),
    ];
    var (out, _) = _seance(k, 21, s);
    // 14 écrites pour 12 admises : l'accessoire paie les deux séries.
    expect(
      (_series(out, 'm.1'), _series(out, 'm.2'), _series(out, 'm.3')),
      (6, 4, 2),
    );
    k = _koach();
    _troisSemainesDips(k, 5);
    (out, _) = _seance(k, 21, s);
    // Limite 7 : accessoire 0, secondaire 1, principal ⌈6/2⌉ = 3 → 4 ;
    // reste 3 de trop… secondaire à 0, principal à 1 seulement en dernier.
    expect(_series(out, 'm.3'), 0);
    expect(_series(out, 'm.1'), greaterThanOrEqualTo(_series(out, 'm.2')));
  });

  test('sans rôle, la première ligne dure est le principal', () {
    final k = _koach();
    _troisSemainesDips(k, 2, roles: false);
    final s = [_it('m.1', _dl, 6), _it('m.2', _pp, 4), _it('m.3', _pd, 4)];
    final (out, _) = _seance(k, 21, s, roles: false);
    // Traitée comme principal (plancher).
    expect(_series(out, 'm.1'), greaterThanOrEqualTo(3));
    expect(_series(out, 'm.2'), 0);
    expect(_series(out, 'm.3'), 0);
  });

  test('principal sous douleur sans plancher (équivalent observable de '
      '`_douleur_unite`, voir l\'en-tête)', () {
    // Sans douleur : `douleur` faux.
    var k = _koach();
    _troisSemainesDips(k, 2);
    var (out, raisons) = _seance(k, 21, [_it('m.1', _dl, 10, role: 'main')]);
    var rg = _retourGradue(raisons);
    expect(rg, hasLength(1));
    expect(_p(rg[0])['exercice'], _dl);
    expect(_p(rg[0])['ecrites'], 10);
    expect(_p(rg[0])['douleur'], isFalse);
    expect(_series(out, 'm.1'), 4);
    // Zone sensible sous la rampe du réalisé : épisode d'épaule (gêne 4) en
    // semaine 4, puis semaine 5 avec un excès « chest ».
    final zones = <String, (Json, Set<String>)>{
      _dl: (<String, Object?>{_sh: 1.0, 'wrist_hand': 0.5}, {_sh, 'elbow'}),
    };
    k = _koach();
    for (var w = 0; w < 4; w++) {
      _seance(k, 7 * w, [_it('x', _dl, 10, role: 'main')], zones: zones);
    }
    (out, _) = _seance(
      k,
      28,
      [_it('x', _dl, 10, role: 'main')],
      zones: zones,
      douleurs: <Object?>[
        <String, Object?>{'zone': _sh, 'intensity': 4},
      ],
    );
    expect(_series(out, 'x'), 0);
    (out, raisons) = _seance(
      k,
      35,
      [
        _it('x', _dl, 10, role: 'main'),
        _it('p', _pp, 10, role: 'secondary'),
        _it('q', _pd, 10, role: 'accessory'),
      ],
      zones: zones,
      douleurs: <Object?>[],
    );
    rg = _retourGradue(raisons);
    expect(
      [
        for (final r in rg)
          (_p(r)['exercice'], dbl(_p(r)['limite']), _p(r)['douleur']),
      ],
      [(_dl, 12.0, true), (_pp, 12.0, false), (_pd, 12.0, false)],
    );
    // Le principal sous douleur passe sous son plancher (⌈10 × 0,5⌉ = 5).
    expect(
      (_series(out, 'x'), _series(out, 'p'), _series(out, 'q')),
      (4, 8, 0),
    );
  });

  test('répartition au prorata entre séances', () {
    // Deux séances identiques, 8 séries d'accessoires de trop : 4 + 4, pas
    // 8 sur la première.
    final k = _koach();
    _troisSemainesDips(k, 10);
    final s1 = [
      _it('p.1', _dl, 5, role: 'main'),
      _it('p.2', _pd, 6, role: 'accessory'),
    ];
    final s2 = [
      _it('q.1', _dl, 5, role: 'main'),
      _it('q.2', _pd, 6, role: 'accessory'),
    ];
    final (out1, _) = _seance(k, 21, s1, reste: [s2]);
    expect(k.seances.retourVol!.repartie, isTrue);
    final (out2, _) = _seance(k, 23, s2);
    // 22 séries « chest » écrites pour 12 admises : 10 de trop, portées par
    // les deux accessoires à parts égales (5 + 5), principaux intacts.
    expect((_series(out1, 'p.2'), _series(out2, 'q.2')), (1, 1));
    expect((_series(out1, 'p.1'), _series(out2, 'q.1')), (5, 5));
    expect(_chestDe(k, 3), lessThanOrEqualTo(12.0 + 1e-9));
  });

  test('mode prudent après une séance manquée', () {
    final k = _koach();
    _troisSemainesDips(k, 10);
    final s1 = [
      _it('p.1', _dl, 5, role: 'main'),
      _it('p.2', _pd, 6, role: 'accessory'),
    ];
    final s2 = [
      _it('q.1', _dl, 5, role: 'main'),
      _it('q.2', _pd, 6, role: 'accessory'),
    ];
    final (out1, _) = _seance(k, 21, s1, reste: [s2], manquees: const [0]);
    expect(k.seances.retourVol!.repartie, isFalse);
    // La séance du jour paie d'abord : son accessoire à 0 (6 séries), puis
    // le principal du jour vers son plancher (2 séries de plus).
    expect(_series(out1, 'p.2'), 0);
    expect(_series(out1, 'p.1'), 3);
  });

  test('fenêtre d\'assiduité', () {
    final k = _koach();
    _troisSemainesDips(k, 10);
    // Hors fenêtre.
    k.seances.semainesManquees.add(3 - _n('retour_repartition_semaines'));
    final s1 = [
      _it('p.1', _dl, 5, role: 'main'),
      _it('p.2', _pd, 6, role: 'accessory'),
    ];
    _seance(k, 21, s1, reste: [s1]);
    expect(k.seances.retourVol!.repartie, isTrue);
  });

  test('lignes restantes sans rôle non coupées d\'avance (relecture M2)', () {
    final k = _koach();
    _troisSemainesDips(k, 10);
    final s1 = [
      _it('p.1', _dl, 5, role: 'main'),
      _it('p.2', _pd, 6, role: 'accessory'),
    ];
    final s2 = [_it('q.1', _dl, 5), _it('q.2', _pd, 6)];
    final (out1, _) = _seance(k, 21, s1, reste: [s2]);
    expect(k.seances.retourVol!.repartie, isTrue);
    // 22 écrites pour 12, dont 11 réservées au reste : le jour coupe son
    // accessoire à 0 (6), son principal à son plancher 3 (2), puis à 1 (2).
    expect(_series(out1, 'p.2'), 0);
    expect(_series(out1, 'p.1'), 1);
  });

  test('sans rôle, une première ligne sans crédit ne prend pas la place du '
      'principal (relecture, mineur 4)', () {
    final sans = <String>[
      for (final e in _fiches.entries)
        if (e.value['renforcement'] == true && _credits(e.key).isEmpty) e.key,
    ];
    expect(sans, isNotEmpty);
    final k = _koach();
    _troisSemainesDips(k, 2, roles: false);
    final s = [
      _it('m.0', sans.first, 3),
      _it('m.1', _dl, 6),
      _it('m.2', _pp, 4),
    ];
    final (out, _) = _seance(k, 21, s, roles: false);
    expect(_series(out, 'm.1'), greaterThanOrEqualTo(3));
    expect(_series(out, 'm.2'), 0);
  });

  test('paramètres 1.0.6', () {
    expect(_params['version'], '1.0.6-ref.1');
    expect(dbl(_s['retour_plancher_principal']), 0.5);
    expect(_n('retour_repartition_semaines'), 4);
    expect(
      jm(_params['rupture']).containsKey('elargissement_rien_de_special'),
      isFalse,
    );
  });
}
