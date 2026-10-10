// Banc adversarial du lot KM2 (`lib/src/km/adversaire.dart`) contre la
// référence Python (`kalis_adapt/reference/banc/adversaire.py`, Python
// 3.13) : valeurs attendues calculées en exécutant la référence sur les
// mêmes entrées (décodage d'un génome, graines valides, hypercube et
// mutation, difficulté et résumé, mesures du témoin, comparaison sans
// rejeu, contrôle des bornes, identifiants et texte JSON des fichiers
// publiés), puis une saison adverse conduite par Koach (Dart, sans
// extension, comme `PolitiqueKoach()` de la référence) comparée à
// `evaluer_saison` de la référence.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_bench/src/km/adversaire.dart';
import 'package:kalis_bench/src/km/criteres_moteur.dart';
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan;
import 'package:test/test.dart';

import 'support.dart';

/// Référence Python de kalis_adapt (paquet voisin).
const String _reference = '../kalis_adapt/reference';

const String _cle = 'street_07_avance_streetlifting_competition';

/// Valeur JSON d'un fichier (décompressé si son nom finit par `.gz`).
Object? _lireJson(String chemin) {
  final bytes = File(chemin).readAsBytesSync();
  return jsonDecode(
    utf8.decode(chemin.endsWith('.gz') ? gzip.decode(bytes) : bytes),
  );
}

String _texte(String chemin) => File(chemin).readAsStringSync();

/// `json.dumps(x, sort_keys=True)` de Python.
String _py(Object? x) => kmJsonPython(x, trier: true);

/// Cadre de `Cadre('street_07_…', 'reference', 'b')` (valeurs lues dans la
/// référence Python).
KmCadreAdversaire _cadreStreet07() => KmCadreAdversaire(
  cle: _cle,
  scenario: 'reference',
  kind: 'b',
  semaines: 16,
  echeances: const <int>[82],
  principaux: const <String>[
    'sl-dips-leste',
    'sl-muscle-up-leste',
    'sl-squat-competition',
    'sl-traction-lestee',
  ],
  specBase: <String, Object?>{
    'key': _cle,
    'level': 2,
    'profileKey': _cle,
    'weeklyGain': 0.0015,
  },
  poidsCorps: const <String>[
    'sl-dips-leste',
    'sl-muscle-up-leste',
    'sl-traction-lestee',
    'sl-traction-lestee-pause-bas',
  ],
);

/// Égalité de deux valeurs JSON, flottants à [tol] près (absolu), types
/// entiers conservés ; renvoie le premier écart ou `null`.
String? _ecart(Object? a, Object? b, String chemin, double tol) {
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    final ka = a.keys.toSet();
    final kb = b.keys.toSet();
    if (ka.length != kb.length || !ka.containsAll(kb)) {
      return '$chemin : clés $ka contre $kb';
    }
    for (final k in ka) {
      final e = _ecart(a[k], b[k], '$chemin.$k', tol);
      if (e != null) {
        return e;
      }
    }
    return null;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return '$chemin : longueurs ${a.length} contre ${b.length}';
    }
    for (var i = 0; i < a.length; i++) {
      final e = _ecart(a[i], b[i], '$chemin[$i]', tol);
      if (e != null) {
        return e;
      }
    }
    return null;
  }
  if (a is double && b is double) {
    return (a - b).abs() <= tol ? null : '$chemin : $a contre $b';
  }
  if (a is int && b is int) {
    return a == b ? null : '$chemin : $a contre $b';
  }
  return a == b ? null : '$chemin : $a (${a.runtimeType}) contre $b';
}

const List<(String, String, String, String)>
_decodages = <(String, String, String, String)>[
  (
    '{"breakDays": 1, "breakFromDay": 11, "daySd": 0.0255, "healthAnswerRate": 0.4468, "illnessDays": 3, "illnessFromDay": 28, "lazy": 0.4091, "missRate": 0.1944, "painDays": 9, "painFromDay": 9, "painIntensity": 4, "painZone": "knee", "ratingNoise": 1.3538, "rirBias": 0.7611, "rirBiasSd": 0.0556, "shortTimeRate": 0.0583, "skipRating": 0.2411}',
    '{"*": {"capacity": 0.8651, "curveB": 0.8629, "fatigueScale": 0.6855, "power": 0.8629, "slope": 0.8629}, "sl-dips-leste": {"capacity": 1.0217, "curveB": 1.2459, "fatigueScale": 1.148, "power": 1.2459, "slope": 1.2459}, "sl-muscle-up-leste": {"capacity": 1.0217, "curveB": 1.2459, "fatigueScale": 1.148, "power": 1.2459, "slope": 1.2459}, "sl-squat-competition": {"capacity": 1.0217, "curveB": 1.2459, "fatigueScale": 1.148, "power": 1.2459, "slope": 1.2459}, "sl-traction-lestee": {"capacity": 1.0217, "curveB": 1.2459, "fatigueScale": 1.148, "power": 1.2459, "slope": 1.2459}, "sl-traction-lestee-pause-bas": {"capacity": 0.92, "curveB": 0.8629, "fatigueScale": 0.6855, "power": 0.8629, "slope": 0.8629}}',
    '{"ratingNoise": 1.3538, "rirBias": 0.7611, "rirBiasSd": 0.0556, "lazy": 0.4091, "skipRating": 0.2411, "missRate": 0.1944, "breakDays": 1, "breakFrom": 0.0624, "illnessDays": 3, "illnessFrom": 0.3195, "painZone": "knee", "painIntensity": 4, "painDays": 9, "painFrom": 0.042, "daySd": 0.0255, "healthAnswerRate": 0.4468, "shortTimeRate": 0.0583, "capaciteTous": 0.8651, "courbeTous": 0.8629, "fatigueTous": 0.6855, "capacitePrincipaux": 1.0217, "courbePrincipaux": 1.2459, "fatiguePrincipaux": 1.148}',
    'adv-dbd31417',
  ),
  (
    '{"breakDays": 9, "breakFromDay": 21, "daySd": 0.0192, "healthAnswerRate": 0.8577, "illnessDays": 9, "illnessFromDay": 17, "lazy": 0.3232, "missRate": 0.0107, "painDays": 18, "painFromDay": 16, "painIntensity": 5, "painZone": "hip", "ratingNoise": 2.383, "rirBias": 0.6417, "rirBiasSd": 0.3095, "shortTimeRate": 0.0667, "skipRating": 0.2872}',
    '{"*": {"capacity": 0.8047, "curveB": 1.114, "fatigueScale": 0.6911, "power": 1.114, "slope": 1.114}, "sl-dips-leste": {"capacity": 1.1744, "curveB": 0.9341, "fatigueScale": 1.1517, "power": 0.9341, "slope": 0.9341}, "sl-muscle-up-leste": {"capacity": 1.1744, "curveB": 0.9341, "fatigueScale": 1.1517, "power": 0.9341, "slope": 0.9341}, "sl-squat-competition": {"capacity": 1.1744, "curveB": 0.9341, "fatigueScale": 1.1517, "power": 0.9341, "slope": 0.9341}, "sl-traction-lestee": {"capacity": 1.1744, "curveB": 0.9341, "fatigueScale": 1.1517, "power": 0.9341, "slope": 0.9341}, "sl-traction-lestee-pause-bas": {"capacity": 0.92, "curveB": 1.114, "fatigueScale": 0.6911, "power": 1.114, "slope": 1.114}}',
    '{"ratingNoise": 2.383, "rirBias": 0.6417, "rirBiasSd": 0.3095, "lazy": 0.3232, "skipRating": 0.2872, "missRate": 0.0107, "breakDays": 9, "breakFrom": 0.2373, "illnessDays": 9, "illnessFrom": 0.1711, "painZone": "hip", "painIntensity": 5, "painDays": 18, "painFrom": 0.1818, "daySd": 0.0192, "healthAnswerRate": 0.8577, "shortTimeRate": 0.0667, "capaciteTous": 0.8047, "courbeTous": 1.114, "fatigueTous": 0.6911, "capacitePrincipaux": 1.1744, "courbePrincipaux": 0.9341, "fatiguePrincipaux": 1.1517}',
    'adv-4a6906ff',
  ),
  (
    '{"breakDays": 4, "breakFromDay": 34, "daySd": 0.0226, "healthAnswerRate": 0.426, "illnessDays": 1, "illnessFromDay": 16, "lazy": 0.2191, "missRate": 0.3012, "painDays": 21, "painFromDay": 48, "painIntensity": 3, "painZone": "shoulder", "ratingNoise": 2.2039, "rirBias": 0.0742, "rirBiasSd": 0.3373, "shortTimeRate": 0.0403, "skipRating": 0.1542}',
    '{"*": {"capacity": 1.0152, "curveB": 1.126, "fatigueScale": 0.7598, "power": 1.126, "slope": 1.126}, "sl-dips-leste": {"capacity": 1.1048, "curveB": 1.3, "fatigueScale": 1.5137, "power": 1.3, "slope": 1.3}, "sl-muscle-up-leste": {"capacity": 1.1048, "curveB": 1.3, "fatigueScale": 1.5137, "power": 1.3, "slope": 1.3}, "sl-squat-competition": {"capacity": 1.1048, "curveB": 1.3, "fatigueScale": 1.5137, "power": 1.3, "slope": 1.3}, "sl-traction-lestee": {"capacity": 1.1048, "curveB": 1.3, "fatigueScale": 1.5137, "power": 1.3, "slope": 1.3}}',
    '{"ratingNoise": 2.2039, "rirBias": 0.0742, "rirBiasSd": 0.3373, "lazy": 0.2191, "skipRating": 0.1542, "missRate": 0.3012, "breakDays": 4, "breakFrom": 0.4222, "illnessDays": 1, "illnessFrom": 0.145, "painZone": "shoulder", "painIntensity": 3, "painDays": 21, "painFrom": 0.8641, "daySd": 0.0226, "healthAnswerRate": 0.426, "shortTimeRate": 0.0403, "capaciteTous": 1.0152, "courbeTous": 1.126, "fatigueTous": 0.7598, "capacitePrincipaux": 1.1048, "courbePrincipaux": 1.3, "fatiguePrincipaux": 1.5137}',
    'adv-834ce945',
  ),
  (
    '{"daySd": 0.0125, "healthAnswerRate": 0.1, "lazy": 0.0, "missRate": 0.0, "ratingNoise": 0.5, "rirBias": -0.15, "rirBiasSd": 0.05, "shortTimeRate": 0.0, "skipRating": 0.0}',
    '{"*": {"capacity": 0.8, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}, "sl-dips-leste": {"capacity": 0.92, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}, "sl-muscle-up-leste": {"capacity": 0.92, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}, "sl-squat-competition": {"capacity": 0.8, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}, "sl-traction-lestee": {"capacity": 0.92, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}, "sl-traction-lestee-pause-bas": {"capacity": 0.92, "curveB": 0.75, "fatigueScale": 0.6, "power": 0.75, "slope": 0.75}}',
    '{"ratingNoise": 0.5, "rirBias": -0.15, "rirBiasSd": 0.05, "lazy": 0.0, "skipRating": 0.0, "missRate": 0.0, "breakDays": 0, "breakFrom": 0.0, "illnessDays": 0, "illnessFrom": 0.0, "painZone": null, "painIntensity": 3, "painDays": 7, "painFrom": 0.0, "daySd": 0.0125, "healthAnswerRate": 0.1, "shortTimeRate": 0.0, "capaciteTous": 0.8, "courbeTous": 0.75, "fatigueTous": 0.6, "capacitePrincipaux": 0.8, "courbePrincipaux": 0.75, "fatiguePrincipaux": 0.6}',
    'adv-4ed09524',
  ),
  (
    '{"breakDays": 14, "breakFromDay": 61, "daySd": 0.0625, "healthAnswerRate": 1.0, "illnessDays": 10, "illnessFromDay": 65, "lazy": 0.5, "missRate": 0.35, "painDays": 35, "painFromDay": 40, "painIntensity": 7, "painZone": "hip", "ratingNoise": 2.5, "rirBias": 0.8, "rirBiasSd": 0.36, "shortTimeRate": 0.3, "skipRating": 0.5}',
    '{"*": {"capacity": 1.2, "curveB": 1.33, "fatigueScale": 1.67, "power": 1.33, "slope": 1.33}, "sl-dips-leste": {"capacity": 1.2, "curveB": 1.33, "fatigueScale": 1.67, "power": 1.33, "slope": 1.33}, "sl-muscle-up-leste": {"capacity": 1.2, "curveB": 1.33, "fatigueScale": 1.67, "power": 1.33, "slope": 1.33}, "sl-squat-competition": {"capacity": 1.2, "curveB": 1.33, "fatigueScale": 1.67, "power": 1.33, "slope": 1.33}, "sl-traction-lestee": {"capacity": 1.2, "curveB": 1.33, "fatigueScale": 1.67, "power": 1.33, "slope": 1.33}}',
    '{"ratingNoise": 2.5, "rirBias": 0.8, "rirBiasSd": 0.36, "lazy": 0.5, "skipRating": 0.5, "missRate": 0.35, "breakDays": 14, "breakFrom": 1.0, "illnessDays": 10, "illnessFrom": 1.0, "painZone": "hip", "painIntensity": 7, "painDays": 35, "painFrom": 1.0, "daySd": 0.0625, "healthAnswerRate": 1.0, "shortTimeRate": 0.3, "capaciteTous": 1.2, "courbeTous": 1.33, "fatigueTous": 1.67, "capacitePrincipaux": 1.2, "courbePrincipaux": 1.33, "fatiguePrincipaux": 1.67}',
    'adv-7911e212',
  ),
  (
    '{"breakDays": 7, "breakFromDay": 38, "daySd": 0.028, "healthAnswerRate": 0.55, "illnessDays": 5, "illnessFromDay": 39, "lazy": 0.25, "missRate": 0.175, "painDays": 21, "painFromDay": 31, "painIntensity": 5, "painZone": "wrist_hand", "ratingNoise": 1.118, "rirBias": 0.325, "rirBiasSd": 0.205, "shortTimeRate": 0.15, "skipRating": 0.25}',
    '{"*": {"capacity": 0.9798, "curveB": 0.9987, "fatigueScale": 1.001, "power": 0.9987, "slope": 0.9987}, "sl-dips-leste": {"capacity": 0.9798, "curveB": 0.9987, "fatigueScale": 1.001, "power": 0.9987, "slope": 0.9987}, "sl-muscle-up-leste": {"capacity": 0.9798, "curveB": 0.9987, "fatigueScale": 1.001, "power": 0.9987, "slope": 0.9987}, "sl-squat-competition": {"capacity": 0.9798, "curveB": 0.9987, "fatigueScale": 1.001, "power": 0.9987, "slope": 0.9987}, "sl-traction-lestee": {"capacity": 0.9798, "curveB": 0.9987, "fatigueScale": 1.001, "power": 0.9987, "slope": 0.9987}}',
    '{"ratingNoise": 1.118, "rirBias": 0.325, "rirBiasSd": 0.205, "lazy": 0.25, "skipRating": 0.25, "missRate": 0.175, "breakDays": 7, "breakFrom": 0.5, "illnessDays": 5, "illnessFrom": 0.5, "painZone": "wrist_hand", "painIntensity": 5, "painDays": 21, "painFrom": 0.5, "daySd": 0.028, "healthAnswerRate": 0.55, "shortTimeRate": 0.15, "capaciteTous": 0.9798, "courbeTous": 0.9987, "fatigueTous": 1.001, "capacitePrincipaux": 0.9798, "courbePrincipaux": 0.9987, "fatiguePrincipaux": 1.001}',
    'adv-b534fbec',
  ),
];

/// Sortie de `evaluer_saison` de la référence (Koach 1.0.1 Python, sans
/// extension) pour l'adversaire `adv-7ee0da71`, graine 0.
const String _evaluationPython =
    '{"aggravations": 0, "codes_violations": {"volume_trop_vite": 3}, '
    '"e1rm6": 0.036998, "e1rm_famille": "loadedMain", "e1rm_n": 4, '
    '"echeance": true, "echecs": 0.004274, "evenements": '
    '[["sl-muscle-up-leste", "loaded", 98.85, 115.944758, 0.852561], '
    '["sl-traction-lestee", "loaded", 121.35, 157.11285, 0.772375], '
    '["sl-dips-leste", "loaded", 145.55, 178.463155, 0.815575]], '
    '"faites": 57, "gain": -0.000558, "perf_a": 0.813503, "plantage": null, '
    '"poussees": 0, "present": true, "prevues": 80, "seed": 0, '
    '"violations": 3}';

void main() {
  final advFichier = '$_reference/donnees/adversaires_v1.json';
  final cmpFichier = '$_reference/donnees/comparaison_adversaires.json';
  final temoinFichier = '$_reference/donnees/adversaires_temoin.json.gz';

  test('espace : 23 dimensions, celles du fichier publié', () {
    expect(kmAdvD, 23);
    final publie = kc.jm(_lireJson(advFichier));
    expect(
      _py(<Object?>[for (final d in kmAdvDimensions) d.toJson()]),
      _py(publie['espace']),
    );
  });

  test('valeur d\'une dimension (bornes, échelles)', () {
    final p = kmAdvParNom;
    expect(p['ratingNoise']!.valeur(-0.2), 0.5);
    expect(p['ratingNoise']!.valeur(1.7), 2.5);
    expect(p['breakDays']!.valeur(1.0), 14);
    expect(p['breakDays']!.valeur(0.999999), 14);
    expect(p['painZone']!.valeur(0.0), isNull);
    expect(p['painZone']!.valeur(1.0), 'hip');
    expect(p['painZone']!.valeur(0.5), 'wrist_hand');
  });

  test('décodage de génomes (référence Python)', () {
    final cadre = _cadreStreet07();
    expect(cadre.finEpisodes, 75);
    expect(cadre.nom, '$_cle|reference|b');
    final rng = kc.Mulberry32(kc.fnv1a32('test|decoder'));
    final us = <List<double>>[
      for (var i = 0; i < 3; i++)
        <double>[for (var j = 0; j < kmAdvD; j++) rng.next()],
      List<double>.filled(kmAdvD, 0.0),
      List<double>.filled(kmAdvD, 1.0),
      List<double>.filled(kmAdvD, 0.5),
    ];
    for (var i = 0; i < us.length; i++) {
      final (spec, surcharges, v) = kmDecoder(us[i], cadre);
      final (attSpec, attSur, attV, attId) = _decodages[i];
      expect(_py(spec), attSpec, reason: 'spec $i');
      expect(_py(surcharges), attSur, reason: 'surcharges $i');
      expect(kmJsonPython(v), attV, reason: 'paramètres $i');
      expect(
        kmIdentifiant(_cle, 'reference', 'b', spec, surcharges),
        attId,
        reason: 'identifiant $i',
      );
      final adv = kmAdversaire(cadre, us[i], 'pire', 2);
      expect(adv['id'], attId);
      expect(kmVerifierBornes(adv), isEmpty, reason: 'bornes $i');
    }
  });

  test('graines valides et présence le jour J (référence Python)', () {
    final cadre = _cadreStreet07();
    expect(
      kmGrainesValides(cadre, <String, Object?>{'missRate': 0.9}, 4),
      <int>[27, 36, 41, 78],
    );
    expect(
      kmGrainesValides(
        cadre,
        <String, Object?>{'missRate': 0.7, 'breakFromDay': 70, 'breakDays': 3},
        3,
        depart: 2,
      ),
      <int>[10, 19, 27],
    );
    expect(
      <bool>[
        for (var g = 0; g < 8; g++)
          kmPresentLeJour(<String, Object?>{'missRate': 0.5}, g, 82),
      ],
      <bool>[true, true, true, false, true, true, true, false],
    );
    expect(
      kmPresentLeJour(
        <String, Object?>{'breakFromDay': 80, 'breakDays': 3},
        0,
        82,
      ),
      isFalse,
    );
    expect(
      kmPresentLeJour(
        <String, Object?>{'breakFromDay': 80, 'breakDays': 2},
        0,
        82,
      ),
      isTrue,
    );
  });

  test('hypercube latin, mutation, réflexion (référence Python)', () {
    final h = kmHypercube(kc.Mulberry32(kc.fnv1a32('7|hc')), 4);
    expect(h[0].sublist(0, 5), <double>[
      0.19670398865127936,
      0.7705215602181852,
      0.3803391606779769,
      0.5856494472245686,
      0.5010477746254764,
    ]);
    expect(h[3].sublist(kmAdvD - 3), <double>[
      0.8132743588648736,
      0.5435611072462052,
      0.2283678301027976,
    ]);
    expect(
      <double>[for (final r in h) r[7]],
      <double>[
        0.3285569013096392,
        0.8084080539410934,
        0.7038505011587404,
        0.08867970312712714,
      ],
    );
    final parent = <Object?>[
      0.1,
      0.95,
      0.5,
      0.0,
      1.0,
      for (var i = 5; i < kmAdvD; i++) 0.3,
    ];
    // `gauss` passe par `normPpfK` (parité 1e-9 du portage) : tolérance.
    final enfant = kmMuter(kc.Mulberry32(12345), parent, 0.2);
    final attenduEnfant = <double>[
      0.0010154643627446475,
      0.8684957339649795,
      0.4215690080251837,
      0.7663964673411101,
      0.8130646955629188,
      0.6211656716347664,
      0.6742468362948439,
      0.16436203694279075,
      0.19801108615650964,
      0.5207736716352025,
      0.4545396772392064,
      0.37864088568246806,
      0.00977141266500925,
      0.13563359849656034,
      0.04494775728520428,
      0.0021405864468087565,
      0.5911936284488685,
      0.14009188463758132,
      0.6812131034675986,
      0.03218256616548082,
      0.4063357532471605,
      0.0574491648236638,
      0.5586112322401107,
    ];
    expect(enfant, hasLength(kmAdvD));
    for (var i = 0; i < kmAdvD; i++) {
      expect(enfant[i], closeTo(attenduEnfant[i], 1e-12), reason: 'u[$i]');
    }
    expect(kmReflechir(-0.3), 0.3);
    expect(kmReflechir(1.25), 0.75);
    expect(kmReflechir(2.6), 0.6000000000000001);
    expect(kmReflechir(-1.7), 0.30000000000000004);
  });

  test('difficulté et résumé (référence Python)', () {
    expect(
      kmDifficulte(<kc.Json>[
        <String, Object?>{'perf_a': null, 'e1rm6': null, 'plantage': 'x'},
        <String, Object?>{'perf_a': null, 'e1rm6': null, 'plantage': null},
      ], 'a'),
      (1.0, 'b'),
    );
    expect(
      kmDifficulte(<kc.Json>[
        <String, Object?>{'perf_a': null, 'e1rm6': 0.1, 'plantage': null},
        <String, Object?>{'perf_a': null, 'e1rm6': 0.25, 'plantage': 'y'},
      ], 'a'),
      (0.175, 'b'),
    );
    expect(
      kmDifficulte(<kc.Json>[
        <String, Object?>{'perf_a': 0.9, 'e1rm6': 0.1, 'plantage': null},
        <String, Object?>{'perf_a': 0.7, 'e1rm6': 0.25, 'plantage': null},
        <String, Object?>{'perf_a': 0.8123456, 'e1rm6': null, 'plantage': null},
      ], 'a'),
      (0.195885, 'a'),
    );
    final advs = kmLireAdversaires(_lireJson(advFichier));
    const attendus = <(String, (double, String), (double, String), String)>[
      (
        'adv-7ee0da71',
        (0.211484, 'a'),
        (0.038028, 'b'),
        '{"aggravations": 0, "e1rm6": 0.038028, "echecs": 0.012639, '
            '"gain": -0.000615, "perf_a": 0.788516, "perf_a_min": 0.772397, '
            '"plantages": [], "poussees": 0, "violations": 3}',
      ),
      (
        'adv-80df39f8',
        (0.134257, 'a'),
        (0.075226, 'b'),
        '{"aggravations": 0, "e1rm6": 0.075226, "echecs": 0.002712, '
            '"gain": 0.000158, "perf_a": 0.865743, "perf_a_min": 0.790904, '
            '"plantages": [], "poussees": 0, "violations": 0}',
      ),
      (
        'adv-1987e7b6',
        (0.100304, 'a'),
        (0.038713, 'b'),
        '{"aggravations": 0, "e1rm6": 0.038713, "echecs": 0.021128, '
            '"gain": -0.00421, "perf_a": 0.899696, "perf_a_min": 0.881107, '
            '"plantages": [], "poussees": 0, "violations": 6}',
      ),
    ];
    for (var i = 0; i < attendus.length; i++) {
      final (id, da, db, resume) = attendus[i];
      final a = advs[i];
      expect(a['id'], id);
      final saisons = <kc.Json>[
        for (final s in kc.jl(kc.jm(a['koach'])['par_graine'])) kc.jm(s),
      ];
      expect(kmDifficulte(saisons, 'a'), da);
      expect(kmDifficulte(saisons, 'b'), db);
      final rk = kmResumeKoach(saisons)..remove('par_graine');
      expect(_py(rk), resume);
    }
  });

  test('fichiers publiés : identifiants, bornes, texte JSON', () {
    final texte = _texte(advFichier);
    final publie = jsonDecode(texte);
    final advs = kmLireAdversaires(publie);
    expect(advs, hasLength(40));
    for (final a in advs) {
      expect(
        kmIdentifiant(
          a['key']! as String,
          a['scenario']! as String,
          a['kind']! as String,
          kc.jm(a['spec']),
          kc.jm(a['surcharges']),
        ),
        a['id'],
      );
      expect(kmVerifierBornes(a), isEmpty, reason: '${a['id']}');
    }
    expect(kmDumpsAdversaires(publie), texte);
    final texteCmp = _texte(cmpFichier);
    expect(kmDumpsAdversaires(jsonDecode(texteCmp)), texteCmp);
    expect(kmEntreesDart(advs), hasLength(95));
  });

  test('contrôle des bornes : écarts (référence Python)', () {
    final a = Map<String, Object?>.of(
      kmLireAdversaires(_lireJson(advFichier)).first,
    );
    a['spec'] = <String, Object?>{
      ...kc.jm(a['spec']),
      'painIntensity': 9,
      'foo': 1,
      'missRate': 0.5,
      'breakDays': 30,
    };
    a['surcharges'] = <String, Object?>{
      ...kc.jm(a['surcharges']),
      'sl-dips-leste': <String, Object?>{
        'capacity': 0.85,
        'curveB': 1.0,
        'holdShare': 1.0,
      },
    };
    expect(kmVerifierBornes(a), <String>[
      'champ de spec inconnu : foo',
      'missRate=0.5 hors [0.0 ; 0.35]',
      'breakDays=30 hors bornes',
      'breakFromDay : épisode [61 ; 91] hors fenêtre [7 ; 75]',
      'painIntensity hors [3 ; 7]',
      'sl-dips-leste : capacité ×0.85 sous le plancher du poids de corps',
      'surcharge inconnue : sl-dips-leste.holdShare',
    ]);
  });

  test('mesures du témoin et comparaison sans rejeu (référence Python)', () {
    final temoin = <kc.Json>[
      for (final e in kc.jl(_lireJson(temoinFichier))) kc.jm(e),
    ];
    expect(
      _py(kmMesuresDart(temoin[0], true, true)),
      '{"aggravations": 0, "codes_violations": {}, "e1rm6": 0.055765, '
      '"e1rm_famille": "loadedMain", "gain": -0.000155, "perf_a": 0.887516, '
      '"poussees": 0, "seed": 0, "violations": 0}',
    );
    expect(kmMesuresDart(temoin[0], true, false)['perf_a'], isNull);
    final advs = kmLireAdversaires(_lireJson(advFichier));
    final cmp = kmComparerAdversaires(advs, temoin);
    expect(
      kmJsonPython(cmp['critere'], ensureAscii: false),
      '{"libelle": "pire cas de Koach >= pire cas du témoin (performance le '
      'jour J, moyenne par adversaire)", "pire_koach": 0.788516, '
      '"pire_temoin": 0.0, "respecte": true, "saisons_temoin_manquantes": 0}',
    );
    expect(
      _py(kc.jm(cmp['groupes'])['tous']),
      '{"e1rm6": {"koach": {"moyenne": 0.087267, "n": 40, "pire": 0.236824}, '
      '"temoin": {"moyenne": 0.115072, "n": 40, "pire": 0.353069}}, "n": 40, '
      '"perf_a": {"koach": {"moyenne": 0.872389, "n": 24, "pire": 0.788516}, '
      '"temoin": {"moyenne": 0.599347, "n": 24, "pire": 0.0}}, '
      '"perf_a_par_saison": {"koach": {"moyenne": 0.83449, "n": 24, '
      '"pire": 0.732583}, "temoin": {"moyenne": 0.54942, "n": 24, '
      '"pire": 0.0}}, "securite": {"koach": {"aggravations": 0, '
      '"plantages": 0, "poussees": 0, "violations_indicatives": 157}, '
      '"temoin": {"aggravations": 0, "poussees": 10, "violations": 18}}}',
    );
    expect(
      _py(kc.jl(cmp['adversaires'])[0]),
      '{"echeance": true, "id": "adv-7ee0da71", "key": '
      '"street_07_avance_streetlifting_competition", "kind": "a", "koach": '
      '{"aggravations": 0, "e1rm6": 0.038028, "echecs": 0.012639, '
      '"perf_a": 0.788516, "perf_a_min": 0.772397, "plantages": [], '
      '"poussees": 0, "violations": 3}, "role": "pire", "scenario": '
      '"reference", "seeds": [0, 1, 2], "temoin": {"aggravations": 0, '
      '"e1rm6": 0.097789, "manquants": [], "perf_a": 0.893672, '
      '"perf_a_min": 0.887516, "poussees": 0, "violations": 0}}',
    );
    expect(kmResumeTexteComparaison(cmp).split('\n').sublist(0, 3), <String>[
      'tous     n=40  jour J koach moy 0.872389 pire 0.788516 | témoin moy '
          '0.599347 pire 0.0',
      'pires    n=32  jour J koach moy 0.857102 pire 0.788516 | témoin moy '
          '0.603271 pire 0.0',
      'temoins  n=8  jour J koach moy 0.918249 pire 0.90614 | témoin moy '
          '0.587577 pire 0.0',
    ]);
  });

  group('saison adverse conduite par Koach (Dart)', () {
    late KmBanc banc;

    setUpAll(() {
      final v = readJsonObject(
        '$_reference/qualites/vecteurs_qualites_v1.json',
      );
      banc = KmBanc(
        catalog: loadCatalog(),
        plan: KalisPlan(),
        parametres: readJsonObject('$_reference/params/koach_params_v1.json'),
        fiches: <String, kc.Json>{
          for (final e in kc.jm(v['exercices']).entries) e.key: kc.jm(e.value),
        },
        profils: <String, Map<String, Object?>>{
          _cle: readJsonObject('profiles/$_cle.json'),
        },
      );
    });

    test('cadre de la saison exportée (référence Python)', () {
      final c = KmCadreAdversaire.deSaison(
        banc.catalog,
        banc.saison(_cle, 'reference'),
        'b',
      );
      final attendu = _cadreStreet07();
      expect(c.nom, attendu.nom);
      expect(c.semaines, attendu.semaines);
      expect(c.echeances, attendu.echeances);
      expect(c.finEpisodes, attendu.finEpisodes);
      expect(c.principaux, attendu.principaux);
      expect(c.poidsCorps, attendu.poidsCorps);
      expect(_py(c.specBase), _py(attendu.specBase));
    });

    test('evaluer_saison : adv-7ee0da71, graine 0', () {
      final a = kmLireAdversaires(_lireJson(advFichier)).first;
      expect(a['id'], 'adv-7ee0da71');
      final travail = kmTravaux(a).first;
      final obtenu = kmEvaluerSaisonAdversaire(banc, travail);
      final e = _ecart(
        jsonDecode(jsonEncode(obtenu)),
        jsonDecode(_evaluationPython),
        'saison',
        2e-6,
      );
      expect(e, isNull, reason: e);
    });
  });
}
