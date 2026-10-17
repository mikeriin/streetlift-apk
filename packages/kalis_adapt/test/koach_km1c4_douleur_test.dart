// Conduite sous douleur et rampe du réalisé (Koach 1.0.5, lot KM1c4 ;
// portage lot KM2c3) : port, test pour test, de la référence Python
// `reference/tests/test_km1c4_douleur.py` (CHANGEMENTS_1_0_5.md, contrat
// § 8.4 bis). Mêmes scénarios, mêmes valeurs attendues (séries servies,
// budgets, raisons) : le moteur Dart doit se comporter exactement comme la
// référence.
//
// 1. zone sensible douze semaines après un épisode, avec ou sans arrêt ;
//    budget hebdomadaire d'exposition de la zone (échauffement compris) ;
// 2. sortie progressive : la rampe continue après la fenêtre tant que le
//    permis n'atteint pas l'écrit ;
// 3. rampe du réalisé : référence = dernière semaine de charge fermée
//    exposée, +1 série ou +20 % ; départ à la moitié de l'habitude, quatre
//    séries sans habitude ; pas de hausse si la zone a été signalée dans la
//    semaine ; répartition au prorata des séances restantes ; pas de vrai
//    test sur la zone ;
// 3 bis. rampe du réalisé après une coupure (séances manquées) ;
// 4. aucune hausse de charge sur un exercice qui sollicite (≥ 0,5) une zone
//    signalée au-dessus du seuil dans les sept derniers jours.
//
// Points portés par un équivalent observable (un test ne peut ni appeler ni
// remplacer une méthode privée d'une autre bibliothèque) :
// - `test_budget_sans_habitude_quatre_series` appelle
//   `Seances._budget_zone_semaine(SH)` juste après la séance de l'épisode :
//   ici, un second Koach rejoue la même séance puis rouvre le même jour (même
//   contexte de semaine) ; `ouvrir` pose `budgetSemaine[z]` à partir de
//   `_budgetZoneSemaine(z)` (fonction pure de l'état), le permis lu est donc
//   le premier membre du couple attendu (`reprise_dose_sans_habitude`, 4).
// - `test_pas_de_vrai_test_sur_une_zone_sous_rampe` et
//   `test_le_vrai_test_reste_possible_sous_la_rampe_de_retour` remplacent
//   `Seances._vrai_test` pour compter ses appels (avec `roles = {}`, il
//   renvoie toujours None : l'appel n'a aucun effet visible). Ici, on vérifie
//   la porte qui décide de l'appel (`prescrire`), entre `prescrire` et
//   `fermer` : ligne de travail servie, plan de l'emplacement présent, et
//   aucune zone provoquée dans `budgetZone` hors `retourZone` (appel attendu)
//   ou une zone provoquée dans `budgetZone` hors `retourZone` (pas d'appel) ;
//   plus aucune ligne `vrai_test` servie.
// Tests non portés : aucun (le point 5, élargissement « rien de spécial »,
// est dans `koach_elargir_test.dart`).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

final Json _s = jm(_params['securite']);

const String _sh = 'shoulder';

final Map<String, (Json, Set<String>)> _zones = {
  'sw-dips-barres-paralleles': (
    <String, Object?>{_sh: 1.0, 'elbow': 0.5},
    {_sh},
  ),
  'sw-pompe': (<String, Object?>{_sh: 0.5, 'wrist_hand': 0.5}, {'wrist_hand'}),
  'sl-dips-leste': (
    <String, Object?>{_sh: 1.0, 'wrist_hand': 0.5},
    {_sh, 'elbow'},
  ),
};

int _n(String k) => ent(_s[k]);

Koach _koach() => Koach(copieJson(_params), _fiches, <String, Object?>{
  'niveau': 1,
  'sexe': 'male',
  'poids_kg': 75.0,
  'declares': <String, Object?>{},
  'zones_fragiles': <Object?>[],
});

Json _dips(
  String slot,
  int sets, {
  String kind = 'work',
  String ex = 'sw-dips-barres-paralleles',
}) => <String, Object?>{
  'slotId': slot,
  'exerciseId': ex,
  'kind': kind,
  'sets': sets,
  'repsLow': 6,
  'repsHigh': 10,
  'targetFlames': 7,
};

List<Object?> _douleur(String zone, int intensite) => <Object?>[
  <String, Object?>{'zone': zone, 'intensity': intensite},
];

Json _bilan(List<Object?> douleurs) => <String, Object?>{
  'overall': 4,
  'pains': douleurs,
};

void _ouvrir(
  Koach k,
  int jour,
  Json? bilan, {
  String genre = 'accumulation',
  Json contexte = const <String, Object?>{},
}) {
  final c = <String, Object?>{
    'semaine': jour ~/ 7,
    'genre': genre,
    ...contexte,
  };
  k.garde.avancer(jour);
  if (bilan != null && bilan['pains'] != null) {
    k.garde.noterSeance(jour, jl(bilan['pains']), posee: true);
  }
  k.seances.ouvrir(jour, bilan, c);
}

/// Ouvre, sert et ferme une séance ; [douleurs] signalées au bilan ;
/// [faitesMax] : séries faites au plus (le reste non fait) ; [avantFermer]
/// lit l'état entre `prescrire` et `fermer` ; renvoie les items servis.
List<Json> _seance(
  Koach k,
  int jour,
  List<Json> items, {
  List<Object?>? douleurs,
  int? faitesMax,
  String genre = 'accumulation',
  Json contexte = const <String, Object?>{},
  void Function(List<Json> out)? avantFermer,
}) {
  final bilan = douleurs != null ? _bilan(douleurs) : null;
  _ouvrir(k, jour, bilan, genre: genre, contexte: contexte);
  final out = k.seances.prescrire(
    [for (final x in items) copieJson(x)],
    <String, Grille>{},
    _zones,
    <String, Object?>{},
  );
  if (avantFermer != null) {
    avantFermer(out);
  }
  final sets = <Object?>[];
  for (final it in out) {
    for (var i = 0; i < ent(it['sets']); i++) {
      if (faitesMax != null && sets.length >= faitesMax) {
        break;
      }
      sets.add(<String, Object?>{
        'exerciseId': it['exerciseId'],
        'slotId': it['slotId'],
        'setIndex': i,
        'kind': it['kind'],
        'reps': it['repsHigh'],
        'flames': 7,
        'failed': false,
        'target': <String, Object?>{'flames': 7},
      });
    }
  }
  k.seances.fermer(<String, Object?>{'sets': sets});
  return out;
}

int _expo(List<Json> out, [String zone = _sh]) {
  var n = 0;
  for (final it in out) {
    final zz = _zones[it['exerciseId']];
    if (zz != null && zz.$2.contains(zone)) {
      n += ent(it['sets']);
    }
  }
  return n;
}

/// Quatre semaines de charge (une séance par semaine) de [sets] séries.
void _quatreSemaines(
  Koach k,
  int sets, {
  String ex = 'sw-dips-barres-paralleles',
}) {
  for (var w = 0; w < 4; w++) {
    _seance(k, 7 * w + 1, [_dips('d', sets, ex: ex)]);
  }
}

List<Json> _manquees(Iterable<int> semaines, Json item) => [
  for (final w in semaines)
    <String, Object?>{
      'semaine': w,
      'genre': 'accumulation',
      'items': <Object?>[copieJson(item)],
    },
];

void main() {
  // --------------------------------------------------------------------
  // Zone sensible
  // --------------------------------------------------------------------
  test('zone sensible douze semaines après un épisode, avec ou sans arrêt', () {
    final g = Gardefous(_params, 1);
    g.noterSeance(10, _douleur(_sh, 2));
    expect(g.sensible(_sh), isFalse); // gêne sous le seuil : pas d'épisode
    g.noterSeance(12, _douleur(_sh, 4));
    g.avancer(12);
    expect(g.sensible(_sh), isTrue);
    expect(g.episode(_sh), (12, 12));
    expect(g.zones[_sh]!.arretDepuis, isNull); // un seul signalement
    g.avancer(12 + _n('sensible_j'));
    expect(g.sensible(_sh), isTrue);
    g.avancer(13 + _n('sensible_j'));
    expect(g.sensible(_sh), isFalse);
    // Un nouveau signalement fort prolonge la fenêtre (même épisode à moins
    // de `arret_levee_j` jours, sinon nouvel épisode).
    g.noterSeance(13 + _n('sensible_j'), _douleur(_sh, 3));
    expect(g.sensible(_sh), isTrue);
    expect(g.episode(_sh)!.$1, 13 + _n('sensible_j'));
  });

  test('gêne récente', () {
    final g = Gardefous(_params, 1);
    g.noterSeance(10, _douleur(_sh, 4));
    g.noterSeance(11, <Object?>[]);
    g.avancer(10 + _n('douleur_hausse_j') - 1);
    expect(g.geneRecente(_sh), 4);
    g.avancer(10 + _n('douleur_hausse_j'));
    expect(g.geneRecente(_sh), 0);
  });

  // --------------------------------------------------------------------
  // Règle 4 : aucune hausse de charge dans la semaine qui suit une gêne
  // --------------------------------------------------------------------
  test('pas de hausse de charge après une gêne dans la semaine', () {
    final g = Gardefous(_params, 1);
    g.noterSeance(10, _douleur('wrist_hand', 4));
    g.noterSeance(12, <Object?>[]); // « plus rien » au bilan
    g.avancer(12);
    expect(g.active('wrist_hand'), 0);
    // Exercice jamais fait (`depuisJour` nul).
    var cond = g.conduite(<String, Object?>{'wrist_hand': 0.5}, <String>{});
    expect(cond['sans_hausse'], isTrue);
    expect(cond['retire'], isFalse);
    expect(cond['raison'], 'douleur');
    expect(
      dbl(cond['rir']),
      greaterThanOrEqualTo(dbl(_s['douleur_rir_bonus'])),
    );
    // Sollicitation faible.
    cond = g.conduite(<String, Object?>{'wrist_hand': 0.4}, <String>{});
    expect(cond['sans_hausse'], isFalse);
    g.avancer(10 + _n('douleur_hausse_j'));
    cond = g.conduite(<String, Object?>{'wrist_hand': 0.5}, <String>{});
    expect(cond['sans_hausse'], isFalse);
  });

  // --------------------------------------------------------------------
  // Règles 1 et 3 : budget de la zone sensible, rampe du réalisé
  // --------------------------------------------------------------------
  test('budget sans arrêt : départ à la moitié de l\'habitude', () {
    final k = _koach();
    // Quatre semaines de charge à 8 séries d'épaule : habitude 8.
    _quatreSemaines(k, 8);
    // Douleur 4 au bilan : dips retirés (sollicitation 1 ≥ contrainte forte).
    expect(
      _expo(_seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4))),
      0,
    );
    // Un signalement, pas d'arrêt ; la semaine suivante la zone est
    // sensible → départ : floor(0,5 × 8) = 4 séries.
    expect(k.garde.zones[_sh]!.arretDepuis, isNull);
    expect(k.garde.sensible(_sh), isTrue);
    final out = _seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(_expo(out), 4);
    expect(
      k.seances.raisons.any((r) => r['code'] == 'koach.reprise_dose'),
      isTrue,
    );
    // Puis +1 ou +20 % par semaine de charge sur le réalisé : 5, 6, 7.
    for (final (j, attendu) in [(43, 5), (50, 6), (57, 7)]) {
      expect(
        _expo(_seance(k, j, [_dips('d', 10)], douleurs: <Object?>[])),
        attendu,
      );
    }
  });

  test('budget : départ quand la zone n\'a pas été exposée depuis '
      'l\'épisode', () {
    final k = _koach();
    _quatreSemaines(k, 8);
    // Semaine 4 fermée sans exposition (dips retirés).
    var out = _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    expect(_expo(out), 0);
    // Semaine 5 : exposition faite à 2 séries seulement ; semaine 6 :
    // référence = réalisé 2 → 3, pas le départ (4) ni l'écrit.
    out = _seance(k, 36, [_dips('d', 2)], douleurs: <Object?>[]);
    expect(_expo(out), 2);
    out = _seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(_expo(out), 3);
  });

  test('épisode dès la première semaine : aucune habitude mesurée → départ '
      'à `reprise_dose_sans_habitude` (4) ; le plus bas des deux permis '
      'tient', () {
    final k = _koach();
    var out = _seance(k, 1, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    expect(_expo(out), 0);
    // Équivalent observable de `_budget_zone_semaine(SH)` dès l'épisode :
    // second Koach identique, rouvert le même jour (voir l'en-tête).
    final jumeau = _koach();
    _seance(jumeau, 1, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    _ouvrir(jumeau, 1, null);
    expect(jumeau.seances.budgetSemaine[_sh], _n('reprise_dose_sans_habitude'));
    _ouvrir(k, 8, _bilan(<Object?>[]));
    expect(k.seances.budgetSemaine[_sh], _n('reprise_dose_sans_habitude'));
    out = _seance(k, 8, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(_expo(out), greaterThan(0));
    expect(_expo(out), lessThanOrEqualTo(_n('reprise_dose_sans_habitude')));
  });

  test('référence réalisée, pas l\'écrit, après des séances manquées', () {
    final k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    expect(_expo(_seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[])), 4);
    // Semaine 6 : séance servie mais rien de fait (écrit 10, réalisé 0).
    _ouvrir(k, 43, _bilan(<Object?>[]));
    k.seances.prescrire(
      [_dips('d', 10)],
      <String, Grille>{},
      _zones,
      <String, Object?>{},
    );
    k.seances.fermer(<String, Object?>{'sets': <Object?>[]});
    // Semaine 7 : renvoi à la dernière semaine exposée (5 : 4 séries) → 5.
    final out = _seance(k, 50, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(_expo(out), 5);
    // Quatre semaines de plus sans exposition : fenêtre de recherche
    // dépassée → départ (4).
    for (final j in [57, 64, 71, 78]) {
      _ouvrir(k, j, _bilan(<Object?>[]));
      k.seances.prescrire(
        [_dips('d', 10)],
        <String, Grille>{},
        _zones,
        <String, Object?>{},
      );
      k.seances.fermer(<String, Object?>{'sets': <Object?>[]});
    }
    expect(_expo(_seance(k, 85, [_dips('d', 10)], douleurs: <Object?>[])), 4);
  });

  test('pas de hausse si la zone a été signalée dans la semaine', () {
    final k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    // Semaine 5 : départ 4.
    expect(_expo(_seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[])), 4);
    // Gêne 3 signalée au jour 40.
    _seance(k, 40, <Json>[], douleurs: _douleur(_sh, 3));
    // Semaine 6, trois jours après cette gêne : pas de hausse (4, pas 5).
    expect(_expo(_seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[])), 4);
    // Semaine 7 : la rampe reprend.
    expect(_expo(_seance(k, 50, [_dips('d', 10)], douleurs: <Object?>[])), 5);
  });

  test('la semaine du signalement ne sert de référence que si c\'est la '
      'semaine précédente, et sans hausse ; jamais par la fenêtre de '
      'recherche', () {
    var k = _koach();
    _quatreSemaines(k, 8);
    expect(_expo(_seance(k, 29, [_dips('d', 8)])), 8);
    _seance(k, 33, <Json>[], douleurs: _douleur(_sh, 3));
    expect(_expo(_seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[])), 8);
    expect(_expo(_seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[])), 9);
    k = _koach();
    _quatreSemaines(k, 8);
    expect(_expo(_seance(k, 29, [_dips('d', 8)])), 8);
    _seance(k, 33, <Json>[], douleurs: _douleur(_sh, 3));
    // Semaine 5 fermée sans exposition de la zone (autre séance).
    _seance(k, 36, [
      <String, Object?>{
        'slotId': 'r',
        'exerciseId': 'mu-rowing-barre-pronation',
        'kind': 'work',
        'sets': 3,
        'repsLow': 8,
        'repsHigh': 10,
        'targetFlames': 7,
      },
    ], douleurs: <Object?>[]);
    expect(_expo(_seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[])), 4);
  });

  test('budget réparti au prorata des séances restantes, échauffement '
      'compris', () {
    var k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    // Semaine 5 : permis 4 ; deux séances écrites à 5 séries (dont une
    // d'échauffement) : 2 aujourd'hui, 2 à la suivante ; l'échauffement
    // retiré (zone épuisée).
    var items = [_dips('e', 1, kind: 'warmup'), _dips('d', 4)];
    var out = _seance(
      k,
      36,
      items,
      douleurs: <Object?>[],
      contexte: <String, Object?>{
        'reste_semaine': <Object?>[items],
      },
    );
    expect(_expo(out), 2);
    expect(out.length, 1);
    expect(out[0]['kind'], 'work');
    expect(ent(out[0]['sets']), 2);
    expect(
      k.seances.raisons.any((r) {
        final p = dictOuVide(r['params']);
        return r['code'] == 'koach.douleur_retrait' &&
            p['cause'] == 'reprise_dose' &&
            p['zone'] == _sh &&
            p['exercice'] == 'sw-dips-barres-paralleles';
      }),
      isTrue,
    );
    out = _seance(k, 38, items, douleurs: <Object?>[]);
    expect(_expo(out), 2);
    // Plus rien : retrait, avec la raison.
    out = _seance(k, 40, items, douleurs: <Object?>[]);
    expect(_expo(out), 0);
    // Permis 5 sur deux séances à 1 + 2 : l'échauffement a sa place.
    k = _koach();
    _quatreSemaines(k, 10);
    _seance(k, 29, [_dips('d', 10)], douleurs: _douleur(_sh, 4));
    items = [_dips('e', 1, kind: 'warmup'), _dips('d', 2)];
    out = _seance(
      k,
      36,
      items,
      douleurs: <Object?>[],
      contexte: <String, Object?>{
        'reste_semaine': <Object?>[items],
      },
    );
    expect(
      [for (final it in out) (it['kind'] as String, ent(it['sets']))],
      [('warmup', 1), ('work', 2)],
    );
  });

  test('pas de vrai test sur une zone sous rampe', () {
    final k = _koach();
    const ex = 'sl-dips-leste';
    _quatreSemaines(k, 6, ex: ex);
    _seance(k, 29, [_dips('d', 6, ex: ex)], douleurs: _douleur(_sh, 4));
    final s = k.seances;
    var porte = true;
    _seance(
      k,
      36,
      [_dips('d', 6, ex: ex)],
      douleurs: <Object?>[],
      avantFermer: (out) {
        // `_vraiTest` n'est pas consulté : une zone provoquée est sous
        // permis du jour hors rampe de retour.
        porte = !_zones[ex]!.$2.any(
          (z) => s.budgetZone.containsKey(z) && !s.retourZone.containsKey(z),
        );
        expect(out.any((x) => x['koach'] == 'vrai_test'), isFalse);
      },
    );
    expect(s.budgetSemaine.containsKey(_sh), isTrue);
    expect(porte, isFalse);
  });

  // --------------------------------------------------------------------
  // Règle 2 : sortie progressive
  // --------------------------------------------------------------------
  test('sortie progressive après la fenêtre', () {
    final k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    // Pendant la fenêtre, l'athlète ne fait que 4 séries par semaine ;
    // l'écrit est à 12.
    var j = 36;
    while (j <= 29 + _n('sensible_j')) {
      final out = _seance(
        k,
        j,
        [_dips('d', 12)],
        douleurs: <Object?>[],
        faitesMax: 4,
      );
      expect(_expo(out), inInclusiveRange(4, 5), reason: 'jour $j');
      j += 7;
    }
    expect(!k.garde.sensible(_sh) || j - 29 > _n('sensible_j'), isTrue);
    // Fenêtre finie : la rampe continue depuis le réalisé jusqu'à l'écrit,
    // jamais un retour d'un coup à 12.
    var attendu = 4;
    while (attendu < 12) {
      attendu = math.max(
        attendu + 1,
        (attendu * (1 + dbl(_s['reprise_dose_hausse']))).truncate(),
      );
      final out = _seance(k, j, [_dips('d', 12)], douleurs: <Object?>[]);
      expect(k.garde.sensible(_sh), isFalse);
      expect(_expo(out), math.min(attendu, 12), reason: 'jour $j');
      j += 7;
    }
    expect(k.seances.rampeZone.contains(_sh), isFalse);
    final finale = _seance(k, j, [_dips('d', 12)], douleurs: <Object?>[]);
    expect(_expo(finale), 12);
  });

  // --------------------------------------------------------------------
  // Relecture KM1c4 (B1, B2, M1, m1, m10)
  // --------------------------------------------------------------------
  test('B1 : après un arrêt levé, rien d\'avant l\'arrêt ne sert de '
      'référence : la zone repart de la moitié de l\'habitude', () {
    final k = _koach();
    _quatreSemaines(k, 8);
    final g = k.garde;
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 3));
    _seance(k, 36, [_dips('d', 10)], douleurs: _douleur(_sh, 3));
    _seance(k, 43, [_dips('d', 10)], douleurs: _douleur(_sh, 3));
    expect(g.zones[_sh]!.arretDepuis, 43);
    // À l'arrêt : dips retirés.
    expect(_expo(_seance(k, 50, [_dips('d', 10)], douleurs: <Object?>[])), 0);
    // Levée au jour 57 : départ floor(0,5 × 8) = 4.
    final out = _seance(k, 57, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(k.garde.arret(_sh), isFalse);
    expect(k.seances.budgetSemaine[_sh], 4);
    expect(_expo(out), inInclusiveRange(1, 4));
    expect(_expo(_seance(k, 64, [_dips('d', 10)], douleurs: <Object?>[])), 5);
  });

  test('B2 : une semaine sans séance fermée mais versée comme manquée est '
      'une semaine de charge à exposition 0 ; au-delà de '
      '`rampe_zone_semaines_max` semaines manquées, départ (4)', () {
    var k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    expect(_expo(_seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[])), 4);
    expect(_expo(_seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[])), 5);
    // Semaines 7 à 10 manquées (versées à la séance du jour 78).
    var out = _seance(
      k,
      78,
      [_dips('d', 10)],
      douleurs: <Object?>[],
      contexte: <String, Object?>{
        'manquees': _manquees([7, 8, 9, 10], _dips('d', 10)),
      },
    );
    expect(_expo(out), 4);
    // Une seule semaine manquée : la dernière exposée (5) sert → 6.
    k = _koach();
    _quatreSemaines(k, 8);
    _seance(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    _seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[]);
    _seance(k, 43, [_dips('d', 10)], douleurs: <Object?>[]);
    out = _seance(
      k,
      57,
      [_dips('d', 10)],
      douleurs: <Object?>[],
      contexte: <String, Object?>{
        'manquees': _manquees([7], _dips('d', 10)),
      },
    );
    expect(_expo(out), 6);
  });

  test('M1 : l\'habitude et les semaines connues ne dépendent pas des 20 '
      'derniers jours de séance (24 séances, habitude 12 → départ 6)', () {
    final k = _koach();
    for (var w = 0; w < 4; w++) {
      for (var j = 0; j < 6; j++) {
        _seance(k, 7 * w + 1 + j, [_dips('d', 2)]);
      }
    }
    _seance(k, 29, [_dips('d', 2)], douleurs: _douleur(_sh, 4));
    _seance(k, 36, [_dips('d', 10)], douleurs: <Object?>[]);
    expect(k.seances.budgetSemaine[_sh], 6);
  });

  test('deux zones sous permis : chaque mouvement est borné par la plus '
      'stricte ; `reprise_dose_min` : jamais sous 1', () {
    final k = _koach();
    const ex = 'sl-dips-leste'; // provoque épaule et coude
    _quatreSemaines(k, 2, ex: ex);
    _seance(
      k,
      29,
      [_dips('d', 2, ex: ex)],
      douleurs: <Object?>[
        <String, Object?>{'zone': _sh, 'intensity': 4},
        <String, Object?>{'zone': 'elbow', 'intensity': 4},
      ],
    );
    final out = _seance(k, 36, [_dips('d', 10, ex: ex)], douleurs: <Object?>[]);
    // Habitude 2 → floor(1) = 1 pour chacune ; plancher 1.
    expect(k.seances.budgetSemaine, <String, int>{_sh: 1, 'elbow': 1});
    expect(_expo(out), 1);
    expect(_expo(out, 'elbow'), 1);
  });

  test('déterminisme : `rejouer` redonne `budgetSemaine`, `rampeZone`, '
      '`ecritZone`, `doseZone`, le permis du jour et la réserve de '
      'l\'échauffement', () {
    List<Json> jouer(
      Koach k,
      int jour,
      List<Json> items, {
      List<Object?>? douleurs,
      List<Object?>? reste,
    }) {
      final bilan = douleurs != null ? _bilan(douleurs) : null;
      k.observe(<String, Object?>{
        'type': 'seance_debut',
        'jour': jour,
        'bilan': bilan,
        'poids_kg': null,
        'contexte': <String, Object?>{
          'semaine': jour ~/ 7,
          'genre': 'accumulation',
          'reste_semaine': reste ?? <Object?>[],
        },
      });
      final r = jm(
        k.plan(<String, Object?>{
          'horizon': 'seance',
          'items': items,
          'grilles': <String, Object?>{},
          'zones': _zones,
          'roles': <String, Object?>{},
        }),
      );
      final servis = [for (final x in jl(r['items'])) jm(x)];
      final sets = <Object?>[];
      for (final it in servis) {
        for (var i = 0; i < ent(it['sets']); i++) {
          sets.add(<String, Object?>{
            'exerciseId': it['exerciseId'],
            'slotId': it['slotId'],
            'setIndex': i,
            'kind': it['kind'],
            'reps': it['repsHigh'],
            'flames': 7,
            'failed': false,
            'target': <String, Object?>{'flames': 7},
          });
        }
      }
      k.observe(<String, Object?>{
        'type': 'seance_fin',
        'jour': jour,
        'douleurs': <Object?>[],
        'seance': <String, Object?>{'sets': sets},
      });
      return servis;
    }

    final k = _koach();
    for (var w = 0; w < 4; w++) {
      jouer(k, 7 * w + 1, [_dips('d', 8)]);
    }
    jouer(k, 29, [_dips('d', 8)], douleurs: _douleur(_sh, 4));
    final items = [_dips('e', 1, kind: 'warmup'), _dips('d', 4)];
    jouer(k, 36, items, douleurs: <Object?>[], reste: <Object?>[items]);
    final out = jouer(k, 38, items, douleurs: <Object?>[]);
    expect(_expo(out), 2);
    final journal = [
      for (final e in jl(jsonDecode(jsonEncode(k.journal)))) jm(e),
    ];
    final r = rejouer(copieJson(_params), _fiches, k.profil, journal);
    final a = k.seances;
    final b = r.seances;
    expect(a.budgetSemaine, <String, int>{_sh: 4});
    expect(a.rampeZone, <String>{_sh});
    expect(b.budgetSemaine, a.budgetSemaine);
    expect(b.budgetZone, a.budgetZone);
    expect(b.rampeZone.toList()..sort(), a.rampeZone.toList()..sort());
    expect(b.ecritZone, a.ecritZone);
    expect(b.doseZone, a.doseZone);
    expect(b.reserveEchauffement, a.reserveEchauffement);
  });

  test('règle 4 de bout en bout : charge servie ≤ dernier passage sur un '
      'exercice chargé qui sollicite la zone, après une gêne 4 signalée '
      'puis 0', () {
    final k = _koach();
    const ex = 'sl-dips-leste';
    final s = k.seances;
    final item = <String, Object?>{
      'slotId': 'd',
      'exerciseId': ex,
      'kind': 'work',
      'sets': 3,
      'repsLow': 5,
      'repsHigh': 5,
      'targetFlames': 7,
      'loadBasis': 'external',
    };
    final grilles = <String, Grille>{ex: Grille(1.25, 0.0, false)};
    // Trois séances à 20 kg (passages), puis gêne 4 à l'épaule un jour sans
    // séance de l'exercice, puis 0.
    for (final j in [1, 4, 8]) {
      _ouvrir(k, j, _bilan(<Object?>[]));
      s.prescrire([item], grilles, _zones, <String, Object?>{'d': 'main'});
      s.fermer(<String, Object?>{
        'sets': <Object?>[
          for (var i = 0; i < 3; i++)
            <String, Object?>{
              'exerciseId': ex,
              'slotId': 'd',
              'setIndex': i,
              'kind': 'work',
              'reps': 5,
              'externalLoadKg': 20.0,
              'flames': 7,
              'failed': false,
              'target': <String, Object?>{'flames': 7},
            },
        ],
      });
    }
    expect(dbl(s.mem(ex).chargeDerniere), 20.0);
    _ouvrir(k, 10, _bilan(_douleur(_sh, 4)));
    s.fermer(<String, Object?>{'sets': <Object?>[]});
    _ouvrir(k, 12, _bilan(<Object?>[]));
    final servi = s.prescrire(
      [item],
      grilles,
      _zones,
      <String, Object?>{'d': 'main'},
    );
    expect(servi, isNotEmpty);
    expect(jm(s.plans['d']!['cond'])['sans_hausse'], isTrue);
    for (var i = 0; i < 3; i++) {
      final cible = s.cible(servi[0], i, <Object?>[])!;
      final charge = cible['externalLoadKg'];
      if (charge != null) {
        expect(dbl(charge), lessThanOrEqualTo(20.0 + 1e-9));
      }
    }
  });

  // --------------------------------------------------------------------
  // Règle 3 bis : rampe du réalisé après une coupure (séances manquées)
  // --------------------------------------------------------------------
  test(
    'retour après une coupure sans douleur connue : moitié de '
    'l\'habitude (5), puis +1 ou +20 % par semaine jusqu\'à l\'écrit (10)',
    () {
      final k = _koach();
      _quatreSemaines(k, 10);
      final manquees = _manquees([4, 5], _dips('d', 10));
      final out = _seance(
        k,
        43,
        [_dips('d', 10)],
        contexte: <String, Object?>{'manquees': manquees},
      );
      expect(_expo(out), 5);
      expect(k.seances.budgetSemaine[_sh], 5);
      expect(k.seances.retourZone[_sh], (6, 5));
      expect(
        [
          for (final j in [50, 57, 64, 71])
            _expo(_seance(k, j, [_dips('d', 10)])),
        ],
        [6, 7, 8, 9],
      );
      final fin = _seance(k, 78, [_dips('d', 10)]);
      expect(_expo(fin), 10);
      expect(k.seances.retourZone.containsKey(_sh), isFalse);
      expect(k.seances.budgetSemaine.containsKey(_sh), isFalse);
    },
  );

  test('pas de rampe de retour sans coupure ni séance manquée', () {
    var k = _koach();
    _quatreSemaines(k, 10);
    var out = _seance(
      k,
      29,
      [_dips('d', 10)],
      contexte: <String, Object?>{
        'manquees': _manquees([3], _dips('d', 10)),
      },
    );
    expect(_expo(out), 10);
    expect(k.seances.retourZone, isEmpty);
    k = _koach();
    _quatreSemaines(k, 10);
    out = _seance(k, 43, [_dips('d', 10)]);
    expect(k.seances.retourZone, isEmpty);
    expect(k.seances.budgetSemaine.containsKey(_sh), isFalse);
    expect(_expo(out), 8); // A6.1
  });

  test('retour sans habitude ; une zone jamais exposée n\'entre pas dans '
      'la rampe', () {
    var k = _koach();
    _seance(k, 1, [_dips('d', 1)]);
    var out = _seance(
      k,
      36,
      [_dips('d', 10)],
      contexte: <String, Object?>{
        'manquees': _manquees([1, 2, 3, 4], _dips('d', 10)),
      },
    );
    // Habitude 1/1 = 1 → floor(0,5) = 0 → `reprise_dose_min` 1.
    expect(_expo(out), 1);
    expect(k.seances.retourZone[_sh]!.$2, 1);
    k = _koach();
    _seance(k, 1, [_dips('p', 4, ex: 'sw-pompe')]);
    out = _seance(
      k,
      22,
      [_dips('d', 10)],
      contexte: <String, Object?>{
        'manquees': _manquees([1, 2], _dips('d', 10)),
      },
    );
    expect(k.seances.retourZone.containsKey(_sh), isFalse);
    expect(_expo(out), greaterThanOrEqualTo(8));
  });

  test('la zone sensible l\'emporte sur la rampe de retour', () {
    final k = _koach();
    _quatreSemaines(k, 10);
    final manquees = _manquees([4, 5], _dips('d', 10));
    expect(
      _expo(
        _seance(
          k,
          43,
          [_dips('d', 10)],
          contexte: <String, Object?>{'manquees': manquees},
        ),
      ),
      5,
    );
    final out = _seance(k, 50, [_dips('d', 10)], douleurs: _douleur(_sh, 3));
    expect(k.seances.retourZone.containsKey(_sh), isFalse);
    expect(k.seances.budgetSemaine[_sh], 5);
    expect(_expo(out), 5);
  });

  test('la rampe de retour (sans douleur connue) n\'interdit pas le vrai '
      'test', () {
    final k = _koach();
    const ex = 'sl-dips-leste';
    _quatreSemaines(k, 6, ex: ex);
    _seance(
      k,
      43,
      [_dips('d', 6, ex: ex)],
      contexte: <String, Object?>{
        'manquees': _manquees([4, 5], _dips('d', 6, ex: ex)),
      },
    );
    final s = k.seances;
    expect(s.retourZone.containsKey(_sh), isTrue);
    var porte = false;
    _seance(
      k,
      51,
      [_dips('d', 6, ex: ex)],
      avantFermer: (out) {
        // `_vraiTest` est consulté : ligne de travail servie, plan présent,
        // aucune zone provoquée sous permis du jour hors rampe de retour.
        porte =
            s.plans['d'] != null &&
            out.any((x) => x['exerciseId'] == ex && x['kind'] == 'work') &&
            !_zones[ex]!.$2.any(
              (z) =>
                  s.budgetZone.containsKey(z) && !s.retourZone.containsKey(z),
            );
      },
    );
    expect(s.budgetSemaine.containsKey(_sh), isTrue);
    expect(s.retourZone.containsKey(_sh), isTrue);
    expect(porte, isTrue);
  });

  test('la rampe de retour est suspendue en semaine verrouillée', () {
    var k = _koach();
    _quatreSemaines(k, 10);
    final manquees = _manquees([4, 5], _dips('d', 10));
    final out = _seance(
      k,
      43,
      [_dips('d', 10)],
      genre: 'competition',
      contexte: <String, Object?>{'manquees': manquees},
    );
    expect(k.seances.retourZone, isEmpty);
    expect(k.seances.budgetSemaine.containsKey(_sh), isFalse);
    expect(_expo(out), 8); // A6.1 seule (semaine du retour)
    // A6.1 (fenêtre de 7 jours).
    expect(_expo(_seance(k, 50, [_dips('d', 10)])), 8);
    expect(k.seances.retourZone, isEmpty);
    expect(_expo(_seance(k, 57, [_dips('d', 10)])), 10);
    expect(k.seances.retourZone, isEmpty);
    k = _koach();
    _quatreSemaines(k, 10);
    expect(
      _expo(
        _seance(
          k,
          43,
          [_dips('d', 10)],
          contexte: <String, Object?>{'manquees': manquees},
        ),
      ),
      5,
    );
    final affutage = _seance(k, 50, [_dips('d', 10)], genre: 'taper');
    expect(k.seances.retourZone.containsKey(_sh), isTrue);
    expect(k.seances.budgetSemaine.containsKey(_sh), isFalse);
    expect(_expo(affutage), 8); // A6.1 seule
    // Reprise de la rampe : référence = dernière semaine de charge (5), pas
    // l'affûtage (allégé, 8) → 6.
    expect(_expo(_seance(k, 57, [_dips('d', 10)])), 6);
    expect(k.seances.retourZone.containsKey(_sh), isTrue);
  });
}
