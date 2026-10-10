/// Campagne de mesure des critères chiffrés du cahier KM sur le moteur Dart
/// (lot KM2) : portage de `reference/banc/campagne.py` et
/// `reference/banc/mesures.py`.
///
/// Koach 1.0 complet (planification, surveillance, contrôle dual,
/// adhérence) contre le témoin `kalis_adapt` 0.3.1 (`kmWitnessSeason`), sur
/// la matrice du banc (profils × scénarios × modèles de vérité × graines).
/// Un bloc par critère (`mesure`, `seuil`, `respecte`, `n`, `detail`,
/// `methode`), même schéma que `reference/donnees/criteres_km1.json`, plus
/// une section `temoin` (chaque critère mesuré aussi pour 0.3.1 là où c'est
/// comparable).
///
/// Écart voulu avec KM1 (DECISIONS_CP.md C13.11.2) : le critère 5 est jugé
/// sur les graines 0 à 5, une prévision par cible (4 semaines avant
/// l'échéance), déciles d'au moins 30 cibles ; la mesure de KM1 (toutes les
/// dates) est gardée à côté (`detail.mesure_km1`).
///
/// Fonctions pures : l'exécution (matrice, isolats, fichiers, horloge) est
/// dans `bin/km2.dart`.
library;

import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart' as kc;

import 'criteres_moteur.dart';
import 'meneur.dart' show KmTour, kmSimuler;
import 'politique_koach.dart' show PolitiqueKoach;

/// Schéma de la sortie.
const String kmSchemaCriteres = 'kalis_bench/criteres_km2/1';

/// Modes d'estimation mesurés.
const List<String> kmModes = <String>['loadedMain', 'loaded', 'reps', 'hold'];

/// Rang de séance du critère 1.
const int kmRang = 6;

/// Rangs rapportés.
const List<int> kmRangs = <int>[1, 3, 6, 12, 24];

/// Premier rang compté dans la couverture.
const int kmRangCouverture = 3;

/// Séances d'un exercice suivies (`mesures.K_MAX`).
const int kmKMax = 24;

/// Premier passage censuré (« jamais » sous 3 %).
const int kmJamais = kmKMax + 1;

/// Seuil du critère 1.
const double kmSeuilE1rm = 0.03;

/// Bornes du critère 4.
const List<double> kmSeuilCouverture = <double>[0.88, 0.92];

/// Seuil du critère 5.
const double kmSeuilCalibration = 0.05;

/// Effectif minimal d'un décile (P(toutes les cibles), rapporté).
const int kmNMinDecile = 20;

/// Effectif minimal d'un décile de la calibration par cible.
const int kmNMinDecileCible = 30;

/// Déciles peuplés exigés pour juger.
const int kmDecilesMin = 2;

/// Prévision lue 4 semaines avant l'échéance.
const int kmSemainesAvant = 4;

/// Graines de la mesure du critère 5 (C13.11.2).
const List<int> kmGrainesCalibration = <int>[0, 1, 2, 3, 4, 5];

/// Vues de sécurité.
const List<String> kmVuesSecurite = <String>[
  'plan_module',
  'servi',
  'servi_tests_faits',
];

const double _eps = 1e-9;

/// Saison de la matrice : (profil, scénario, vérité, graine).
typedef KmJob = (String, String, String, int);

/// Nom d'une saison (`campagne._nom`).
String kmNomJob(KmJob j) => '${j.$1}__${j.$2}__${j.$3}__${j.$4}';

/// Saison de la matrice relue d'une liste JSON `[cle, scen, v, g]`.
KmJob kmJobDe(Object? x) {
  final l = kc.jl(x);
  return (l[0]! as String, l[1]! as String, l[2]! as String, kc.ent(l[3]));
}

/// Options de la campagne qui changent le résultat d'une saison.
final class KmOptionsCampagne {
  /// Options.
  const KmOptionsCampagne({
    this.sansPlanificateur = false,
    this.trajectoires = 1000,
    this.defautModele,
    this.semaines,
    this.rapide = false,
  });

  /// Relues de [json] ([toJson]).
  factory KmOptionsCampagne.fromJson(Map<String, Object?> json) =>
      KmOptionsCampagne(
        sansPlanificateur: json['sans_planificateur'] == true,
        trajectoires: kc.ent(json['trajectoires']),
        defautModele: kc.dblOu(json['defaut_modele']),
        semaines: json['semaines'] == null ? null : kc.ent(json['semaines']),
        rapide: json['rapide'] == true,
      );

  /// Moteur seul, sans extension.
  final bool sansPlanificateur;

  /// Trajectoires du jumeau.
  final int trajectoires;

  /// Surcharge de `params['mesure']['defaut_modele_sd']`.
  final double? defautModele;

  /// Saisons tronquées (essais).
  final int? semaines;

  /// Campagne rapide.
  final bool rapide;

  /// Export.
  Map<String, Object?> toJson() => <String, Object?>{
    'sans_planificateur': sansPlanificateur,
    'trajectoires': trajectoires,
    'defaut_modele': defautModele,
    'semaines': semaines,
    'rapide': rapide,
  };

  /// Ce qui change le résultat d'une saison (`campagne.config_de`).
  Map<String, Object?> config() => <String, Object?>{
    'planificateur': !sansPlanificateur,
    'trajectoires': trajectoires,
    'defaut_modele_sd': defautModele,
    'semaines': semaines,
  };
}

/// Paramètres de Koach (copie), défaut de modèle surchargé si demandé
/// (`campagne.parametres`).
kc.Json kmParametres(kc.Json base, double? defautModele) {
  final p = kc.copieJson(base);
  if (defautModele != null) {
    kc.jm(p['mesure'])['defaut_modele_sd'] = defautModele;
  }
  return p;
}

// ----------------------------------------------------------------------
// Outils
// ----------------------------------------------------------------------

/// `_r` : flottant arrondi à [n] décimales comme Python (NaN, infinis →
/// null) ; autre valeur inchangée.
Object? kmR(Object? x, [int n = 6]) {
  if (x == null) {
    return null;
  }
  if (x is double) {
    if (x.isNaN || x.isInfinite) {
      return null;
    }
    return kmArrondiPy(x, n);
  }
  return x;
}

/// `_moy` : moyenne des valeurs non nulles, ou null.
double? kmMoyenne(Iterable<num?> xs) {
  final ys = <num>[
    for (final x in xs)
      if (x != null) x,
  ];
  return ys.isNotEmpty ? kmSommePy(ys) / ys.length : null;
}

/// `_mediane` : médiane des valeurs non nulles (élément central pour un
/// effectif impair, entier conservé), ou null.
num? kmMediane(Iterable<num?> xs) {
  final ys = <num>[
    for (final x in xs)
      if (x != null) x,
  ]..sort();
  final n = ys.length;
  if (n == 0) {
    return null;
  }
  return n % 2 == 1 ? ys[n ~/ 2] : 0.5 * (ys[n ~/ 2 - 1] + ys[n ~/ 2]);
}

/// `_se` : erreur-type de la moyenne, ou null (moins de deux valeurs).
double? kmErreurType(Iterable<num?> xs) {
  final ys = <num>[
    for (final x in xs)
      if (x != null) x,
  ];
  if (ys.length < 2) {
    return null;
  }
  final m = kmSommePy(ys) / ys.length;
  return math.sqrt(
    kmSommePy(<double>[for (final x in ys) math.pow(x - m, 2).toDouble()]) /
        (ys.length - 1) /
        ys.length,
  );
}

/// `_arrondir` : flottants arrondis (`_r`), clés en texte, récursivement.
Object? kmArrondir(Object? o) {
  if (o is Map<Object?, Object?>) {
    return <String, Object?>{
      for (final e in o.entries) '${e.key}': kmArrondir(e.value),
    };
  }
  if (o is Iterable<Object?>) {
    return <Object?>[for (final v in o) kmArrondir(v)];
  }
  if (o is bool || o == null || o is int || o is String) {
    return o;
  }
  if (o is double) {
    return kmR(o);
  }
  return o;
}

/// Valeur JSON triée par clés, récursivement (`json.dump(...,
/// sort_keys=True)`).
Object? kmTrierCles(Object? o) {
  if (o is Map<Object?, Object?>) {
    final cles = <String>[for (final k in o.keys) '$k']..sort();
    final parCle = <String, Object?>{
      for (final e in o.entries) '${e.key}': e.value,
    };
    return <String, Object?>{for (final k in cles) k: kmTrierCles(parCle[k])};
  }
  if (o is Iterable<Object?>) {
    return <Object?>[for (final v in o) kmTrierCles(v)];
  }
  return o;
}

/// `repr` de Python d'une valeur simple (texte, entier, flottant, None,
/// booléen) : sert à reproduire `str(tuple)`.
String kmReprPy(Object? x) {
  if (x == null) {
    return 'None';
  }
  if (x is bool) {
    return x ? 'True' : 'False';
  }
  if (x is int) {
    return '$x';
  }
  if (x is double) {
    return _reprFlottant(x);
  }
  if (x is String) {
    final guillemet = x.contains("'") && !x.contains('"') ? '"' : "'";
    final b = StringBuffer(guillemet);
    for (final r in x.runes) {
      if (r == 0x5c) {
        b.write(r'\\');
      } else if (String.fromCharCode(r) == guillemet) {
        b.write('\\$guillemet');
      } else if (r == 0x09) {
        b.write(r'\t');
      } else if (r == 0x0a) {
        b.write(r'\n');
      } else if (r == 0x0d) {
        b.write(r'\r');
      } else if (r < 0x20 || (r >= 0x7f && r < 0xa0)) {
        b.write('\\x${r.toRadixString(16).padLeft(2, '0')}');
      } else {
        b.writeCharCode(r);
      }
    }
    b.write(guillemet);
    return b.toString();
  }
  return '$x';
}

String _reprFlottant(double x) {
  if (x.isNaN) {
    return 'nan';
  }
  if (x.isInfinite) {
    return x > 0 ? 'inf' : '-inf';
  }
  if (x == 0.0) {
    return x.isNegative ? '-0.0' : '0.0';
  }
  // Chiffres les plus courts (comme repr) : mantisse et exposant.
  final s = x.toStringAsExponential();
  final neg = s.startsWith('-');
  final corps = neg ? s.substring(1) : s;
  final iE = corps.indexOf('e');
  final mant = corps.substring(0, iE).replaceAll('.', '');
  final e = int.parse(corps.substring(iE + 1));
  final signe = neg ? '-' : '';
  final decpt = e + 1;
  if (decpt <= -4 || decpt > 16) {
    final m = mant.length == 1 ? mant : '${mant[0]}.${mant.substring(1)}';
    final ea = e.abs().toString().padLeft(2, '0');
    return '$signe${m}e${e < 0 ? '-' : '+'}$ea';
  }
  if (decpt <= 0) {
    return '${signe}0.${'0' * (-decpt)}$mant';
  }
  if (decpt >= mant.length) {
    return '$signe$mant${'0' * (decpt - mant.length)}.0';
  }
  return '$signe${mant.substring(0, decpt)}.${mant.substring(decpt)}';
}

int _cmpNum(num a, num b) => a < b ? -1 : (a > b ? 1 : 0);

// ----------------------------------------------------------------------
// Mesures d'une saison (`mesures.py`)
// ----------------------------------------------------------------------

/// Erreurs d'estimation par rang de séance de l'exercice, plus la
/// couverture de l'intervalle à 90 % (`mesures.Estimations`). Colonnes :
/// n, Σ|err|, Σerr, Σerr², n sous 3 %, n couverts, Σ écart-type relatif.
final class KmEstimations {
  /// Accumulateur vide ; [temoin] : export 0.3.1 (sans écart-type).
  KmEstimations({this.temoin = false});

  /// Lignes de l'export du témoin (`sd` omis par [ligneJson]).
  final bool temoin;

  /// Par rang (0 à [kmKMax]).
  final List<List<double>> rows = <List<double>>[
    for (var k = 0; k <= kmKMax; k++) List<double>.filled(7, 0.0),
  ];

  /// Premier rang sous 3 % par exercice et par saison (0 : jamais).
  final List<int> firstUnder = <int>[];

  /// Ajoute les estimations de [tour] retenues par [keep].
  void add(KmTour tour, bool Function(kc.Json e) keep) {
    final seen = <String, int>{};
    final ids = <String>{};
    final parJour = <(String, int), kc.Json>{};
    final ordre = <(String, int)>[];
    for (final e in tour.estimates) {
      if (!keep(e) || kc.dbl(e['truth']) <= 0) {
        continue;
      }
      final cle = (e['exerciseId']! as String, kc.ent(e['simDay']));
      if (!parJour.containsKey(cle)) {
        ordre.add(cle);
      }
      parJour[cle] = e;
    }
    final rang = <String, int>{};
    for (final cle in ordre) {
      final e = parJour[cle]!;
      final ex = e['exerciseId']! as String;
      rang[ex] = (rang[ex] ?? 0) + 1;
      ids.add(ex);
      final k = rang[ex]!;
      final truth = kc.dbl(e['truth']);
      final err = kc.dbl(e['capacity']) / truth - 1;
      final a = err.abs();
      if (a < 0.03) {
        seen.putIfAbsent(ex, () => k);
      }
      if (k < 1 || k > kmKMax) {
        continue;
      }
      final r = rows[k];
      r[0] += 1;
      r[1] += a;
      r[2] += err;
      r[3] += err * err;
      if (a < 0.03) {
        r[4] += 1;
      }
      final relSd = kc.dbl(e['relSd']);
      if (e['low'] != null) {
        if (kc.dbl(e['low']) <= truth && truth <= kc.dbl(e['high'])) {
          r[5] += 1;
        }
      } else if (a <= 1.6449 * relSd) {
        r[5] += 1;
      }
      r[6] += relSd;
    }
    for (final i in ids) {
      firstUnder.add(seen[i] ?? 0);
    }
  }

  /// Ajoute les lignes [rows] et premiers passages [firstUnder] d'une
  /// saison mesurée (`campagne._cumul`).
  void cumuler(Object? rowsJson, Object? firstUnderJson) {
    final rs = kc.jl(rowsJson);
    for (var k = 0; k < rs.length; k++) {
      final r = kc.jl(rs[k]);
      for (var c = 0; c < r.length; c++) {
        rows[k][c] += kc.dbl(r[c]);
      }
    }
    for (final x in kc.jl(firstUnderJson)) {
      firstUnder.add(kc.ent(x));
    }
  }

  /// Ajoute l'export d'estimations du témoin (`ajouter_temoin`).
  void ajouterTemoin(kc.Json j) {
    final by = kc.jl(j['bySession']);
    for (var k = 0; k <= kmKMax; k++) {
      final r = kc.jl(by[k]);
      for (var c = 0; c < 6; c++) {
        rows[k][c] += kc.dbl(r[c]);
      }
    }
    for (final x in kc.jl(j['firstUnder3'])) {
      firstUnder.add(kc.ent(x));
    }
  }

  /// Ligne du rang [k] (`ligne`), ou null.
  Map<String, Object?>? ligne(int k) {
    final r = rows[k];
    final n = r[0];
    if (n == 0) {
      return null;
    }
    return <String, Object?>{
      'n': n.truncate(),
      'mae': r[1] / n,
      'biais': r[2] / n,
      'rmse': math.sqrt(r[3] / n),
      'sous3': r[4] / n,
      'couverture': r[5] / n,
      'sd': r[6] / n,
    };
  }

  /// Ligne du rang [k] aux clés publiées (`campagne._ligne`) : sans `sd`
  /// pour le témoin.
  Map<String, Object?>? ligneJson(int k) {
    final l = ligne(k);
    if (l == null) {
      return null;
    }
    const cles = <String>[
      'n',
      'mae',
      'biais',
      'rmse',
      'sous3',
      'couverture',
      'sd',
    ];
    return <String, Object?>{
      for (final x in temoin ? cles.sublist(0, cles.length - 1) : cles)
        if (l.containsKey(x)) x: l[x],
    };
  }

  /// Agrégat des rangs >= [k0] (`apres`), ou null.
  Map<String, Object?>? apres(int k0) {
    final tot = List<double>.filled(7, 0.0);
    for (var k = k0; k <= kmKMax; k++) {
      for (var c = 0; c < 7; c++) {
        tot[c] += rows[k][c];
      }
    }
    final n = tot[0];
    if (n == 0) {
      return null;
    }
    return <String, Object?>{
      'n': n.truncate(),
      'mae': tot[1] / n,
      'biais': tot[2] / n,
      'sous3': tot[4] / n,
      'couverture': tot[5] / n,
    };
  }

  /// Premier rang où l'erreur absolue moyenne passe sous [seuil]
  /// (`premier_rang_sous`), ou null.
  int? premierRangSous([double seuil = 0.03]) {
    for (var k = 1; k <= kmKMax; k++) {
      final n = rows[k][0];
      if (n > 0 && rows[k][1] / n < seuil) {
        return k;
      }
    }
    return null;
  }
}

bool _filtre(String mode, kc.Json e) => switch (mode) {
  'loadedMain' => e['mode'] == 'loaded' && kc.vrai(e['main']),
  'loaded' => e['mode'] == 'loaded',
  'reps' => e['mode'] == 'reps',
  _ => e['mode'] == 'hold',
};

/// Jour de l'échéance : [exercice, mode, meilleure valeur, charge externe
/// de la meilleure, max du jour, capacité de départ] par exercice testé
/// (`mesures.evenements`).
List<List<Object?>> kmEvenements(KmTour tour) {
  final best = <String, double>{};
  final bestExt = <String, double>{};
  final dayMax = <String, double>{};
  final modes = <String, Object?>{};
  for (final s in tour.sets) {
    if (!(kc.vrai(s['eventDay']) && kc.vrai(s['test']))) {
      continue;
    }
    final mx = s['dayMax'];
    if (mx == null || kc.dbl(mx) <= 0) {
      continue;
    }
    final ex = s['exerciseId']! as String;
    dayMax[ex] = kc.dbl(mx);
    modes[ex] = s['mode'];
    final ok = !(kc.vrai(s['failed']) || kc.dbl(s['amount']) < 1);
    final double value;
    if (s['mode'] == 'loaded') {
      value = ok ? (kc.vrai(s['totalKg']) ? kc.dbl(s['totalKg']) : 0.0) : 0.0;
    } else {
      value = kc.dbl(s['amount']);
    }
    if (value > (best[ex] ?? 0)) {
      best[ex] = value;
      if (s['mode'] == 'loaded') {
        bestExt[ex] = kc.vrai(s['loadKg']) ? kc.dbl(s['loadKg']) : 0.0;
      }
    }
    best.putIfAbsent(ex, () => 0.0);
  }
  return <List<Object?>>[
    for (final ex in best.keys)
      <Object?>[
        ex,
        modes[ex],
        best[ex],
        bestExt[ex],
        dayMax[ex],
        tour.cap0[ex],
      ],
  ];
}

/// Écart d'effort, échecs non voulus, tentatives réussies, hausses trop
/// fortes (`mesures.effort`).
Map<String, Object?> kmEffort(KmTour tour) {
  var gapSum = 0.0;
  var n = 0;
  var work = 0;
  var failed = 0;
  var tries = 0;
  var good = 0;
  var hausses = 0;
  for (final s in tour.sets) {
    if (kc.vrai(s['attempt'])) {
      tries += 1;
      if (!kc.vrai(s['failed']) && kc.dbl(s['amount']) >= 1) {
        good += 1;
      }
    }
    if (kc.vrai(s['test']) || s['role'] == 'warmup') {
      continue;
    }
    final rise = s['schemeRise'];
    if (rise != null &&
        kc.vrai(s['main']) &&
        kc.dbl(rise) > 0.10 + 1e-9 &&
        kc.ent(s['schemeSteps']) > 1) {
      hausses += 1;
    }
    if (kc.ent(s['exerciseSession']) < 3) {
      continue;
    }
    work += 1;
    if (kc.vrai(s['failed']) && !kc.vrai(s['plannedFailure'])) {
      failed += 1;
    }
    if (kc.vrai(s['plannedFailure']) || !kc.vrai(s['reachable'])) {
      continue;
    }
    final diff = kc.dbl(s['trueRir']) - kc.dbl(s['wantRir']);
    final gap = kc.vrai(s['openTarget'])
        ? (diff < 0 ? -diff : 0.0)
        : diff.abs();
    gapSum += gap;
    n += 1;
  }
  return <String, Object?>{
    'ecart_effort': n > 0 ? gapSum / n : null,
    'echecs': work > 0 ? failed / work : null,
    'tentatives': tries > 0 ? good / tries : null,
    'hausses_trop_fortes': hausses,
    'series': work,
  };
}

/// Gain hebdomadaire moyen (`mesures.gain_moyen`), ou null.
double? kmGainMoyen(KmTour tour) {
  if (tour.gain.isEmpty) {
    return null;
  }
  return kmSommeD(tour.gain.values) / tour.gain.length;
}

// ----------------------------------------------------------------------
// Calibration
// ----------------------------------------------------------------------

/// {jour: {exercice: [meilleure valeur réussie, maximum vrai du jour,
/// mode]}} des tests des jours d'épreuve (`campagne.epreuves_par_jour`).
Map<int, Map<String, List<Object?>>> kmEpreuvesParJour(KmTour tour) {
  final out = <int, Map<String, List<Object?>>>{};
  for (final s in tour.sets) {
    if (!(kc.vrai(s['eventDay']) && kc.vrai(s['test']))) {
      continue;
    }
    final mx = s['dayMax'];
    if (mx == null || kc.dbl(mx) <= 0) {
      continue;
    }
    final ok = !(kc.vrai(s['failed']) || kc.dbl(s['amount']) < 1);
    final double v;
    if (s['mode'] == 'loaded') {
      v = ok ? (kc.vrai(s['totalKg']) ? kc.dbl(s['totalKg']) : 0.0) : 0.0;
    } else {
      v = kc.dbl(s['amount']);
    }
    final e = out
        .putIfAbsent(kc.ent(s['simDay']), () => <String, List<Object?>>{})
        .putIfAbsent(
          s['exerciseId']! as String,
          () => <Object?>[0.0, kc.dbl(mx), s['mode']],
        );
    e[1] = kc.dbl(mx);
    if (v > kc.dbl(e[0])) {
      e[0] = v;
    }
  }
  return out;
}

/// Une unité par (saison, échéance) : prévisions de P(réussite) faites
/// pour cette échéance et réussite observée le jour J ; (unités,
/// exclusions {raison: n}) (`campagne.unites_calibration`).
(List<kc.Json>, Map<String, int>) kmUnitesCalibration(
  kc.Json saison,
  KmTour tour,
  List<kc.Json> previsions,
) {
  final exclus = <String, int>{};
  final joursEpreuve = <int>{};
  for (final jours in kc.listeOuVide(saison['eventDaysByWeek'])) {
    for (final j in kc.jl(jours)) {
      joursEpreuve.add(kc.ent(j));
    }
  }
  if (joursEpreuve.isEmpty) {
    return (<kc.Json>[], <String, int>{'sans_echeance': 1});
  }
  final prev = <kc.Json>[
    for (final p in previsions)
      if (p['echeance'] != null) p,
  ];
  if (prev.isEmpty) {
    return (<kc.Json>[], <String, int>{'sans_cible': 1});
  }
  final epreuves = kmEpreuvesParJour(tour);
  final unites = <kc.Json>[];
  final echeances = <int>{for (final p in prev) kc.ent(p['echeance'])}.toList()
    ..sort();
  for (final e in echeances) {
    final ps = kmTriStable(<kc.Json>[
      for (final p in prev)
        if (kc.ent(p['echeance']) == e) p,
    ], (a, b) => _cmpNum(kc.dbl(a['semaine']), kc.dbl(b['semaine'])));
    final cibles = kc.dictOuVide(ps.last['cibles']);
    final semE = kc.divEnt(e, 7);
    if (!joursEpreuve.contains(e)) {
      exclus['echeance_deplacee'] = (exclus['echeance_deplacee'] ?? 0) + 1;
      continue;
    }
    final obs = epreuves[e];
    if (obs == null || obs.isEmpty) {
      exclus['aucun_test_le_jour_j'] =
          (exclus['aucun_test_le_jour_j'] ?? 0) + 1;
      continue;
    }
    if (cibles.isEmpty || cibles.keys.any((ex) => !obs.containsKey(ex))) {
      exclus['cible_non_testee'] = (exclus['cible_non_testee'] ?? 0) + 1;
      continue;
    }
    final reussi = <String, Object?>{
      for (final ex in cibles.keys)
        ex: kc.dbl(obs[ex]![0]) >= kc.dbl(cibles[ex]) - _eps,
    };
    final capable = <String, Object?>{
      for (final ex in cibles.keys)
        ex: kc.dbl(obs[ex]![1]) >= kc.dbl(cibles[ex]) - _eps,
    };
    final d0 = ps.first;
    final miCible = 0.5 * (kc.dbl(d0['semaine']) + semE);
    var mi = ps.first;
    for (final p in ps.skip(1)) {
      final a = (kc.dbl(p['semaine']) - miCible).abs();
      final b = (kc.dbl(mi['semaine']) - miCible).abs();
      if (a < b || (a == b && kc.dbl(p['semaine']) < kc.dbl(mi['semaine']))) {
        mi = p;
      }
    }
    final m4 = <kc.Json>[
      for (final p in ps)
        if (kc.dbl(p['semaine']) == semE - kmSemainesAvant) p,
    ];
    final dates = <String, kc.Json?>{
      'debut': d0,
      'mi_saison': mi,
      'moins_4_semaines': m4.isNotEmpty ? m4.first : null,
    };
    unites.add(<String, Object?>{
      'echeance': e,
      'cibles': cibles,
      'reussite': reussi.values.every((x) => x == true),
      'reussite_capacite': capable.values.every((x) => x == true),
      'reussite_par_cible': reussi,
      'capacite_par_cible': capable,
      'previsions': <String, Object?>{
        for (final d in dates.entries)
          d.key: d.value == null
              ? null
              : <String, Object?>{
                  'semaine': d.value!['semaine'],
                  'p_tout': d.value!['p_tout'],
                  'p': d.value!['p'],
                },
      },
    });
  }
  return (unites, exclus);
}

// ----------------------------------------------------------------------
// Sécurité d'une saison
// ----------------------------------------------------------------------

/// Validateur de sécurité d'une saison : constats des blocs donnés
/// (`securite_banc.constats_saison(saison, infos, blocs)`).
typedef KmConstats = List<kc.Json> Function(List<Object?> blocs);

/// Blocs de référence où chaque séance faite est remplacée par les items
/// servis par Koach, tels que prescrits ; [testsFaits] : un test ajouté par
/// Koach compte pour ses tentatives faites, un exercice arrêté avant la fin
/// pour ses séries faites (`campagne.blocs_servis_prescrits`).
List<Object?> kmBlocsServisPrescrits(
  kc.Json saison,
  KmTour tour, {
  bool testsFaits = false,
}) {
  final faites = <(int, Object?), int>{};
  final toutes = <(int, Object?), int>{};
  if (testsFaits) {
    for (final x in tour.sets) {
      final k = (kc.ent(x['simDay']), x['slotId']);
      toutes[k] = (toutes[k] ?? 0) + 1;
    }
    for (final x in tour.sets) {
      // Série dure au sens du validateur : flammes >= 3 ; les paliers
      // faciles d'une montée de test sont des séries d'approche.
      if (x['flames'] != null &&
          kc.dbl(x['flames']) < 3 &&
          !kc.vrai(x['failed'])) {
        continue;
      }
      final k = (kc.ent(x['simDay']), x['slotId']);
      faites[k] = (faites[k] ?? 0) + 1;
    }
  }
  final jourDe = <(int, int, int, int), int>{};
  for (final s in kc.jl(saison['sessions'])) {
    final l = kc.jl(s);
    jourDe[(kc.ent(l[0]), kc.ent(l[1]), kc.ent(l[2]), kc.ent(l[3]))] = kc.ent(
      l[4],
    );
  }
  final blocs = kc.jl(kc.copieProfonde(saison['blocks']));
  for (final (g, bi, wb, di, items) in tour.servi) {
    for (final w in kc.jl(kc.jm(kc.jm(blocs[bi])['pass2'])['weeks'])) {
      final wm = kc.jm(w);
      if (wm['weekIndex'] != wb) {
        continue;
      }
      for (final d in kc.jl(wm['days'])) {
        final dm = kc.jm(d);
        if (dm['dayIndex'] != di) {
          continue;
        }
        final ecrits = <Object?>{
          for (final i in kc.jl(dm['items'])) kc.jm(i)['slotId'],
        };
        final nouveaux = <Object?>[];
        for (final i0 in items) {
          final i = kc.copieJson(i0);
          final jour = jourDe[(g, bi, wb, di)];
          if (testsFaits &&
              i['kind'] == 'test' &&
              !ecrits.contains(i['slotId'])) {
            final n = jour == null ? 0 : (faites[(jour, i['slotId'])] ?? 0);
            if (n == 0) {
              continue;
            }
            i['sets'] = n;
          } else if (testsFaits &&
              kc.vrai(i['sets']) &&
              i['kind'] != 'warmup') {
            final n = jour == null ? null : toutes[(jour, i['slotId'])];
            if (n != null && n < kc.dbl(i['sets'])) {
              i['sets'] = n;
            }
          }
          nouveaux.add(i);
        }
        dm['items'] = nouveaux;
      }
    }
  }
  return blocs;
}

/// Clé d'un constat (code, semaine, jour, exercice).
(Object?, Object?, Object?, Object?) kmCleConstat(kc.Json c) =>
    (c['code'], c['week'], c['dayIndex'], c['exerciseId']);

String _texteCle((Object?, Object?, Object?, Object?) k) =>
    '(${kmReprPy(k.$1)}, ${kmReprPy(k.$2)}, ${kmReprPy(k.$3)}, '
    '${kmReprPy(k.$4)})';

num _valeurOuZero(kc.Json c) {
  final v = c['value'];
  return kc.vrai(v) ? v! as num : 0.0;
}

/// Constats de [servi] classés contre ceux du plan initial : `deja_initial`
/// (même code, semaine, jour, exercice, valeur pas plus haute), `aggrave`
/// (même clé, valeur plus haute), `introduit` (absent du plan initial) ;
/// (comptes par catégorie et code, trois exemples au plus)
/// (`campagne.classer_constats`).
(Map<String, Object?>, List<kc.Json>) kmClasserConstats(
  List<kc.Json> initial,
  List<kc.Json> servi,
) {
  final reste = <(Object?, Object?, Object?, Object?), List<kc.Json>>{};
  for (final c in initial) {
    reste.putIfAbsent(kmCleConstat(c), () => <kc.Json>[]).add(c);
  }
  final out = <String, Map<String, int>>{
    'deja_initial': <String, int>{},
    'aggrave': <String, int>{},
    'introduit': <String, int>{},
  };
  final exemples = <kc.Json>[];
  final tries = kmTriStable(servi, (a, b) {
    final c = _texteCle(kmCleConstat(a)).compareTo(_texteCle(kmCleConstat(b)));
    return c != 0 ? c : _cmpNum(_valeurOuZero(a), _valeurOuZero(b));
  });
  for (final c in tries) {
    final k = kmCleConstat(c);
    final String cat;
    final r = reste[k];
    if (r != null && r.isNotEmpty) {
      final c0 = r.removeAt(0);
      final v = c['value'];
      final v0 = c0['value'];
      cat = (v != null && v0 != null && kc.dbl(v) > kc.dbl(v0) + 1e-9)
          ? 'aggrave'
          : 'deja_initial';
    } else {
      cat = 'introduit';
    }
    final code = c['code']! as String;
    out[cat]![code] = (out[cat]![code] ?? 0) + 1;
    if (cat != 'deja_initial' && exemples.length < 3) {
      exemples.add(<String, Object?>{
        'categorie': cat,
        'code': code,
        'semaine': c['week'],
        'jour': c['dayIndex'],
        'exercice': c['exerciseId'],
        'valeur': c['value'],
        'limite': c['limit'],
      });
    }
  }
  return (Map<String, Object?>.of(out), exemples);
}

/// Nombre de constats par code (`securite_banc.comptes`).
Map<String, Object?> kmComptes(List<kc.Json> found) {
  final out = <String, Object?>{};
  for (final f in found) {
    final code = f['code']! as String;
    out[code] = ((out[code] as int?) ?? 0) + 1;
  }
  return out;
}

/// {code: n} des constats de [serv] absents du plan initial qui
/// disparaissent quand chaque séance manquée de [blocsS] est vidée
/// (diagnostic, `campagne.constats_dus_aux_manquees`).
Map<String, Object?> kmConstatsDusAuxManquees(
  kc.Json saison,
  KmConstats constats,
  KmTour tour,
  List<kc.Json> initial,
  List<kc.Json> serv,
  List<Object?> blocsS,
) {
  final faites = <(int, int, int, int)>{
    for (final (g, bi, wb, di, _) in tour.servi) (g, bi, wb, di),
  };
  final vide = kc.jl(kc.copieProfonde(blocsS));
  for (final s in kc.jl(saison['sessions'])) {
    final l = kc.jl(s);
    final g = kc.ent(l[0]);
    final bi = kc.ent(l[1]);
    final wb = kc.ent(l[2]);
    final di = kc.ent(l[3]);
    if (faites.contains((g, bi, wb, di))) {
      continue;
    }
    for (final w in kc.jl(kc.jm(kc.jm(vide[bi])['pass2'])['weeks'])) {
      final wm = kc.jm(w);
      if (wm['weekIndex'] == wb) {
        for (final d in kc.jl(wm['days'])) {
          final dm = kc.jm(d);
          if (dm['dayIndex'] == di) {
            dm['items'] = <Object?>[];
          }
        }
      }
    }
  }
  final clesIni = <(Object?, Object?, Object?, Object?)>{
    for (final c in initial) kmCleConstat(c),
  };
  final restent = <(Object?, Object?, Object?, Object?)>{
    for (final c in constats(vide)) kmCleConstat(c),
  };
  final out = <String, int>{};
  for (final c in serv) {
    final k = kmCleConstat(c);
    if (!clesIni.contains(k) && !restent.contains(k)) {
      final code = c['code']! as String;
      out[code] = (out[code] ?? 0) + 1;
    }
  }
  final cles = out.keys.toList()..sort();
  return <String, Object?>{for (final k in cles) k: out[k]};
}

/// Reclasse en `retour_ecrit` les constats « introduits » d'une semaine w
/// qui disparaissent quand les semaines avant w sont celles de l'écrit et
/// que la semaine w reste celle servie (`campagne.retirer_retours_a_l_ecrit`).
(Map<String, Object?>, List<kc.Json>) kmRetirerRetoursALEcrit(
  kc.Json saison,
  KmConstats constats,
  List<kc.Json> initial,
  List<kc.Json> serv,
  List<Object?> blocsS,
) {
  final clesIni = <(Object?, Object?, Object?, Object?), int>{};
  for (final c in initial) {
    final k = kmCleConstat(c);
    clesIni[k] = (clesIni[k] ?? 0) + 1;
  }
  final position = <int, (int, Object?)>{};
  var g = 0;
  final blocsSaison = kc.jl(saison['blocks']);
  for (var bi = 0; bi < blocsSaison.length; bi++) {
    for (final w in kc.jl(kc.jm(kc.jm(blocsSaison[bi])['pass2'])['weeks'])) {
      position[g] = (bi, kc.jm(w)['weekIndex']);
      g += 1;
    }
  }
  final restants = <kc.Json>[];
  final retours = <String, Object?>{};
  final cache = <int, Set<(Object?, Object?, Object?, Object?)>>{};
  for (final c in serv) {
    final w = c['week'];
    final k = kmCleConstat(c);
    if ((clesIni[k] ?? 0) != 0 ||
        w == null ||
        !position.containsKey(kc.ent(w))) {
      restants.add(c);
      continue;
    }
    final wi0 = kc.ent(w);
    if (!cache.containsKey(wi0)) {
      final hyb = kc.jl(kc.copieProfonde(saison['blocks']));
      final (bi, wi) = position[wi0]!;
      final semaines = kc.jl(kc.jm(kc.jm(hyb[bi])['pass2'])['weeks']);
      for (var j = 0; j < semaines.length; j++) {
        if (kc.jm(semaines[j])['weekIndex'] == wi) {
          for (final semS in kc.jl(
            kc.jm(kc.jm(blocsS[bi])['pass2'])['weeks'],
          )) {
            if (kc.jm(semS)['weekIndex'] == wi) {
              semaines[j] = kc.copieProfonde(semS);
            }
          }
        }
      }
      cache[wi0] = <(Object?, Object?, Object?, Object?)>{
        for (final x in constats(hyb)) kmCleConstat(x),
      };
    }
    if (cache[wi0]!.contains(k)) {
      restants.add(c);
    } else {
      final code = c['code']! as String;
      retours[code] = ((retours[code] as int?) ?? 0) + 1;
    }
  }
  final (cl, ex) = kmClasserConstats(initial, restants);
  cl['retour_ecrit'] = retours;
  return (cl, ex);
}

/// Sécurité d'une saison (`campagne.securite_saison`) : constats du plan
/// initial ; s'il y a une planification, constats de ses blocs modulés
/// [blocsModules] ; vues servies.
Map<String, Object?> kmSecuriteSaison(
  kc.Json saison,
  KmConstats constats,
  KmTour tour, {
  List<kc.Json>? blocsModules,
}) {
  final initial = constats(kc.jl(saison['blocks']));
  final out = <String, Object?>{'initial': kmComptes(initial)};
  if (blocsModules != null) {
    final mod = constats(blocsModules);
    final (cl, ex) = kmClasserConstats(initial, mod);
    out['plan_module'] = cl;
    out['plan_module_exemples'] = ex;
  }
  for (final (vue, sans) in const <(String, bool)>[
    ('servi', false),
    ('servi_tests_faits', true),
  ]) {
    final blocsS = kmBlocsServisPrescrits(saison, tour, testsFaits: sans);
    final serv = constats(blocsS);
    var (cl, ex) = kmClasserConstats(initial, serv);
    if (sans && (kc.vrai(cl['introduit']) || kc.vrai(cl['aggrave']))) {
      (cl, ex) = kmRetirerRetoursALEcrit(
        saison,
        constats,
        initial,
        serv,
        blocsS,
      );
      // Diagnostic seulement : constats dus au seul volume écrit des
      // séances manquées.
      out['${vue}_dus_aux_manquees'] = kmConstatsDusAuxManquees(
        saison,
        constats,
        tour,
        initial,
        serv,
        blocsS,
      );
    }
    out[vue] = cl;
    out['${vue}_exemples'] = ex;
  }
  return out;
}

int? _alertesDe(PolitiqueKoach pol) {
  final j = pol.journaux();
  final s = j.containsKey('SurveillanceBanc')
      ? j['SurveillanceBanc']
      : j['Surveillance'];
  if (s is! List<Object?>) {
    return null;
  }
  var n = 0;
  for (final x in s) {
    if (x is Map<String, Object?> && x['type'] == 'alerte') {
      n++;
    }
  }
  return n;
}

/// Ce que les critères lisent d'une saison simulée (sérialisable)
/// (`campagne.mesurer_saison`, après la simulation).
Map<String, Object?> kmMesureDeSaison(
  KmJob job,
  kc.Json saison,
  KmTour tour, {
  required KmConstats constats,
  required List<kc.Json> previsions,
  required int? alertes,
  required List<kc.Json>? blocsModules,
  required bool sansPlanificateur,
}) {
  final est = <String, Object?>{};
  for (final m in kmModes) {
    final e = KmEstimations()..add(tour, (x) => _filtre(m, x));
    est[m] = <String, Object?>{'rows': e.rows, 'first_under': e.firstUnder};
  }
  final (unites, exclus) = sansPlanificateur
      ? (<kc.Json>[], <String, int>{})
      : kmUnitesCalibration(saison, tour, previsions);
  final (cle, scen, v, g) = job;
  return <String, Object?>{
    'saison': <Object?>[cle, scen, v, g],
    'niveau': saison['level'],
    'echeance': kc
        .listeOuVide(saison['eventDaysByWeek'])
        .any((x) => kc.vrai(x)),
    'estimations': est,
    'evenements': kmEvenements(tour),
    'effort': kmEffort(tour),
    'gain': kmGainMoyen(tour),
    'aggravations': tour.painAggravations,
    'poussees': tour.painFlares,
    'seances': tour.sessionsDone,
    'prevues': tour.sessionsPlanned,
    'alertes': alertes,
    'calibration': <String, Object?>{'unites': unites, 'exclus': exclus},
    'securite': kmSecuriteSaison(
      saison,
      constats,
      tour,
      blocsModules: blocsModules,
    ),
  };
}

/// Simule une saison de la matrice et en tire tout ce que les critères
/// lisent (`campagne.mesurer_saison`). [banc] porte les paramètres de la
/// campagne (défaut de modèle surchargé s'il y a lieu).
Map<String, Object?> kmMesurerSaison(
  KmBanc banc,
  KmJob job,
  KmOptionsCampagne opts,
) {
  final (cle, scenario, verite, graine) = job;
  final saison = banc.saison(cle, scenario, semaines: opts.semaines);
  final pol = opts.sansPlanificateur
      ? banc.politique()
      : banc.politique(
          graine: graine,
          briques: kmBriquesCompletes,
          trajectoires: opts.trajectoires,
        );
  final tour = kmSimuler(banc.catalog, saison, pol, verite, graine);
  final cs = banc.constatsDe(saison);
  return kmMesureDeSaison(
    job,
    saison,
    tour,
    constats: cs.constats,
    previsions: pol.previsions,
    alertes: _alertesDe(pol),
    blocsModules: pol.planification?.blocsModules(),
    sansPlanificateur: opts.sansPlanificateur,
  );
}

// ----------------------------------------------------------------------
// Matrice
// ----------------------------------------------------------------------

/// Saisons de la matrice (`campagne.matrice`) : [scenariosDe] donne les
/// scénarios exportés d'un profil, dans l'ordre ; [scenarios] `['tous']`
/// ou une liste ; [verites] une suite de lettres ; [graines] les graines.
List<KmJob> kmMatrice(
  List<String> profils,
  List<String> Function(String cle) scenariosDe,
  List<String> scenarios,
  String verites,
  List<int> graines,
) {
  final jobs = <KmJob>[];
  final tous = scenarios.length == 1 && scenarios.first == 'tous';
  for (final cle in profils) {
    for (final s in scenariosDe(cle)) {
      if (!tous && !scenarios.contains(s)) {
        continue;
      }
      for (final v in verites.split('')) {
        for (final g in graines) {
          jobs.add((cle, s, v, g));
        }
      }
    }
  }
  return jobs;
}

/// Saisons du critère 2 (`campagne.jobs_mj`).
List<(String, String, int)> kmJobsMauvaisJourCampagne(
  List<String> profils,
  String verites,
  List<int> graines,
  bool rapide,
) {
  if (rapide) {
    return const <(String, String, int)>[
      ('street_16_specialisation_traction_lestee', 'a', 0),
    ];
  }
  final cles0 = <String>[
    for (final c in profils)
      if (kmProfilsCharges.contains(c)) c,
  ];
  final cles = cles0.isNotEmpty ? cles0 : List<String>.of(kmProfilsCharges);
  final nG = math.max(1, math.min(graines.length, 2));
  final gs = graines.length >= nG ? graines.sublist(0, nG) : graines;
  return kmJobsMauvaisJour(cles: cles, verites: verites, graines: gs);
}

/// Résumé d'une mesure du mauvais jour pour la campagne
/// (`campagne.mesure_mauvais_jour`) : lignes retirées, nombre de saisons,
/// plantages réduits à la fin de leur trace.
Map<String, Object?> kmResumeMauvaisJour(kc.Json r, int jobs) {
  final out = Map<String, Object?>.of(r)..remove('mesures');
  out['jobs'] = jobs;
  out['plantages'] = <Object?>[
    for (final p in kc.listeOuVide(r['plantages']))
      () {
        final t = '${kc.jm(p)['trace'] ?? ''}';
        return t.length > 300 ? t.substring(t.length - 300) : t;
      }(),
  ];
  return out;
}

// ----------------------------------------------------------------------
// Témoin 0.3.1
// ----------------------------------------------------------------------

/// Triplet (profil, scénario, vérité).
typedef KmTriplet = (String, String, String);

int _cmpTriplet(KmTriplet a, KmTriplet b) {
  var c = a.$1.compareTo(b.$1);
  if (c != 0) {
    return c;
  }
  c = a.$2.compareTo(b.$2);
  return c != 0 ? c : a.$3.compareTo(b.$3);
}

/// Saisons du témoin des triplets de [jobs] (`campagne.charger_temoin`) :
/// [temoins] donne, par profil, ses saisons `kmWitnessSeason` (null : pas
/// de fichier) ; rend les mesures par vérité (`truths[v]`), clés triées.
Map<KmTriplet, kc.Json> kmChargerTemoin(
  List<KmJob> jobs,
  Map<String, List<kc.Json>?> temoins,
) {
  final triplets = <KmTriplet>{
    for (final j in jobs) (j.$1, j.$2, j.$3),
  }.toList()..sort(_cmpTriplet);
  final parCle = <String, Map<String, kc.Json>>{};
  final out = <KmTriplet, kc.Json>{};
  for (final (cle, scen, v) in triplets) {
    final pc = parCle.putIfAbsent(cle, () {
      final l = temoins[cle];
      return <String, kc.Json>{
        if (l != null)
          for (final s in l) s['scenario']! as String: s,
      };
    });
    final s = pc[scen];
    if (s == null) {
      continue;
    }
    final truths = kc.jm(s['truths']);
    if (!truths.containsKey(v)) {
      continue;
    }
    out[(cle, scen, v)] = kc.jm(truths[v]);
  }
  return out;
}

// ----------------------------------------------------------------------
// Agrégation
// ----------------------------------------------------------------------

/// Estimations agrégées de Koach (par mode, par vérité, par niveau) et du
/// témoin (`campagne.agreger_estimations`).
final class KmAgregats {
  KmAgregats._();

  /// Koach par mode.
  final Map<String, KmEstimations> k = <String, KmEstimations>{
    for (final m in kmModes) m: KmEstimations(),
  };

  /// Koach par vérité (principaux chargés).
  final Map<String, KmEstimations> kv = <String, KmEstimations>{};

  /// Koach par niveau (principaux chargés).
  final Map<String, KmEstimations> kn = <String, KmEstimations>{};

  /// Témoin par mode.
  final Map<String, KmEstimations> t = <String, KmEstimations>{
    for (final m in kmModes) m: KmEstimations(temoin: true),
  };

  /// Témoin par vérité.
  final Map<String, KmEstimations> tv = <String, KmEstimations>{};

  /// Témoin par niveau.
  final Map<String, KmEstimations> tn = <String, KmEstimations>{};
}

String _strPy(Object? x) => x == null ? 'None' : '$x';

/// Agrège les estimations des saisons [ok] et du témoin [temoin] ;
/// [niveauDe] : niveau de la saison de référence (`campagne.niveau_de`).
KmAgregats kmAgregerEstimations(
  List<kc.Json> ok,
  Map<KmTriplet, kc.Json> temoin,
  Object? Function(String cle, String scenario) niveauDe,
) {
  final a = KmAgregats._();
  for (final r in ok) {
    final s = kc.jl(r['saison']);
    final v = s[2]! as String;
    final est = kc.jm(r['estimations']);
    for (final m in kmModes) {
      final e = kc.jm(est[m]);
      a.k[m]!.cumuler(e['rows'], e['first_under']);
    }
    final lm = kc.jm(est['loadedMain']);
    a.kv
        .putIfAbsent(v, KmEstimations.new)
        .cumuler(lm['rows'], lm['first_under']);
    a.kn
        .putIfAbsent(_strPy(r['niveau']), KmEstimations.new)
        .cumuler(lm['rows'], lm['first_under']);
  }
  final cles = temoin.keys.toList()..sort(_cmpTriplet);
  for (final tr in cles) {
    final (cle, scen, v) = tr;
    final t = temoin[tr]!;
    final est = kc.jm(t['estimates']);
    for (final m in kmModes) {
      a.t[m]!.ajouterTemoin(kc.jm(est[m]));
    }
    a.tv
        .putIfAbsent(v, () => KmEstimations(temoin: true))
        .ajouterTemoin(kc.jm(est['loadedMain']));
    a.tn
        .putIfAbsent(
          _strPy(niveauDe(cle, scen)),
          () => KmEstimations(temoin: true),
        )
        .ajouterTemoin(kc.jm(est['loadedMain']));
  }
  return a;
}

List<String> _triees(Iterable<String> xs) => xs.toList()..sort();

/// Critère 1 : erreur d'e1RM au rang 6, moyenne des modèles de vérité
/// (`campagne.critere_e1rm`).
Map<String, Object?> kmCritereE1rm(KmAgregats a) {
  final k = a.k['loadedMain']!.ligneJson(kmRang);
  final t = a.t['loadedMain']!.ligneJson(kmRang);
  final parV = <double>[
    for (final v in _triees(a.kv.keys))
      if (a.kv[v]!.ligneJson(kmRang)?['mae'] != null)
        kc.dbl(a.kv[v]!.ligneJson(kmRang)!['mae']),
  ];
  final mesure = parV.isNotEmpty ? kmSommeD(parV) / parV.length : null;
  return <String, Object?>{
    'mesure': mesure,
    'seuil': kmSeuilE1rm,
    'n': k != null ? k['n'] : 0,
    'respecte': mesure != null && mesure < kmSeuilE1rm,
    'methode':
        "MAE relative |e1RM estimé / e1RM vrai − 1| au rang 6 (6e jour "
        "d'entraînement de l'exercice, dernière estimation du jour, "
        '`KmEstimations`) sur les mouvements principaux chargés, moyenne des '
        'modèles de vérité du banc (C13.10.2.a) ; témoin : `kmWitnessSeason` '
        '0.3.1 (16 graines) sur les mêmes saisons. Écart documenté accepté '
        '(C13.11.1) : ne bloque pas la bascule, ne doit pas reculer.',
    'detail': <String, Object?>{
      'toutes_estimations': k?['mae'],
      'koach': k,
      'temoin': t,
      'par_verite': <String, Object?>{
        for (final v in _triees(a.kv.keys))
          v: <String, Object?>{
            'koach': a.kv[v]!.ligneJson(kmRang),
            'temoin': a.tv.containsKey(v) ? a.tv[v]!.ligneJson(kmRang) : null,
          },
      },
      'par_niveau': <String, Object?>{
        for (final n in _triees(<String>{...a.kn.keys, ...a.tn.keys}))
          n: <String, Object?>{
            // La référence suppose chaque niveau du témoin présent chez
            // Koach (KeyError sinon) : ici null.
            'koach': a.kn[n]?.ligneJson(kmRang),
            'temoin': a.tn.containsKey(n) ? a.tn[n]!.ligneJson(kmRang) : null,
          },
      },
      'autres_modes_rang_6': <String, Object?>{
        for (final m in const <String>['loaded', 'reps', 'hold'])
          m: <String, Object?>{
            'koach': a.k[m]!.ligneJson(kmRang),
            'temoin': a.t[m]!.ligneJson(kmRang),
          },
      },
    },
  };
}

/// Premier passage sous 3 % : effectif, moyennes censurée et des atteints,
/// médiane censurée, part jamais atteinte (`campagne._premier_passage`).
Map<String, Object?> kmPremierPassage(List<int> f) {
  final atteints = <int>[
    for (final x in f)
      if (x > 0) x,
  ];
  final cens = <int>[for (final x in f) x > 0 ? x : kmJamais];
  return <String, Object?>{
    'n': f.length,
    'moyenne_censuree': kmMoyenne(cens),
    'moyenne_atteints': kmMoyenne(atteints),
    'mediane_censuree': kmMediane(cens),
    'part_jamais': f.isNotEmpty ? 1 - atteints.length / f.length : null,
  };
}

/// Critère 3 : vitesse de convergence contre le témoin
/// (`campagne.critere_convergence`).
Map<String, Object?> kmCritereConvergence(KmAgregats a) {
  final pk = kmPremierPassage(a.k['loadedMain']!.firstUnder);
  final pt = kmPremierPassage(a.t['loadedMain']!.firstUnder);
  final mk = kc.dblOu(pk['moyenne_censuree']);
  final mt = kc.dblOu(pt['moyenne_censuree']);
  return <String, Object?>{
    'mesure': mk,
    'seuil': mt,
    'n': pk['n'],
    'respecte': mk != null && mt != null && mk <= mt + _eps,
    'methode':
        'Par exercice principal chargé et par saison, premier rang de séance '
        'où |erreur| < 3 % (`first_under`) ; moyenne avec « jamais » compté '
        '$kmJamais (censure), à comparer au témoin 0.3.1 sur les mêmes '
        '(profil, scénario, vérité) ; seuil = valeur du témoin.',
    'detail': <String, Object?>{
      'koach': pk,
      'temoin': pt,
      'premier_rang_mae_sous_3': <String, Object?>{
        'koach': a.k['loadedMain']!.premierRangSous(),
        'temoin': a.t['loadedMain']!.premierRangSous(),
      },
      'par_verite': <String, Object?>{
        for (final v in _triees(a.kv.keys))
          v: <String, Object?>{
            'koach': kmPremierPassage(a.kv[v]!.firstUnder),
            'temoin': a.tv.containsKey(v)
                ? kmPremierPassage(a.tv[v]!.firstUnder)
                : null,
          },
      },
    },
  };
}

Map<String, Object?>? _nCouverture(Map<String, Object?>? x) => x == null
    ? null
    : <String, Object?>{'n': x['n'], 'couverture': x['couverture']};

Map<String, Object?> _tousModes(KmAgregats a) {
  var n = 0.0;
  var cov = 0.0;
  for (final m in const <String>['loaded', 'reps', 'hold']) {
    final x = a.k[m]!.apres(kmRangCouverture);
    if (x != null) {
      n += kc.ent(x['n']);
      cov += kc.dbl(x['couverture']) * kc.ent(x['n']);
    }
  }
  return <String, Object?>{
    'n': n.truncate(),
    'couverture': n != 0 ? cov / n : null,
  };
}

/// Critère 4 : couverture de l'intervalle à 90 % (rangs >= 3)
/// (`campagne.critere_couverture`). [defautModeleSd] : valeur en vigueur.
Map<String, Object?> kmCritereCouverture(KmAgregats a, Object? defautModeleSd) {
  final x = a.k['loadedMain']!.apres(kmRangCouverture);
  final c = x == null ? null : kc.dbl(x['couverture']);
  final lo = kmSeuilCouverture[0];
  final hi = kmSeuilCouverture[1];
  return <String, Object?>{
    'mesure': c,
    'seuil': <double>[lo, hi],
    'n': x != null ? x['n'] : 0,
    'respecte': c != null && lo - _eps <= c && c <= hi + _eps,
    'methode':
        "Part des estimations (principaux chargés, rangs >= 3) dont "
        "l'intervalle à 90 % de Koach [exp(mu ∓ 1,645 sd)] contient la "
        'capacité vraie (à frais).',
    'detail': <String, Object?>{
      'defaut_modele_sd': defautModeleSd,
      'par_rang': <String, Object?>{
        for (final k in kmRangs)
          '$k': () {
            final l = a.k['loadedMain']!.ligneJson(k);
            return l == null
                ? null
                : <String, Object?>{
                    'n': l['n'],
                    'couverture': l['couverture'],
                    'sd': l['sd'],
                  };
          }(),
      },
      'par_mode_rangs_3_et_plus': <String, Object?>{
        for (final m in kmModes)
          m: _nCouverture(a.k[m]!.apres(kmRangCouverture)),
      },
      'tous_modes_rangs_3_et_plus': _tousModes(a),
      'par_verite': <String, Object?>{
        for (final v in _triees(a.kv.keys))
          v: _nCouverture(a.kv[v]!.apres(kmRangCouverture)),
      },
    },
  };
}

/// Déciles de probabilité prévue (`campagne._deciles`) : lignes et écart
/// maximal sur les déciles d'au moins [nMin] cas (null s'il n'y en a pas).
(List<Map<String, Object?>>, double?) kmDeciles(
  List<(double, bool)> paires, [
  int nMin = kmNMinDecile,
]) {
  final out = <Map<String, Object?>>[];
  double? pire;
  for (var d = 0; d < 10; d++) {
    final sel = <(double, bool)>[
      for (final x in paires)
        if (math.min(9, (x.$1 * 10).floor()) == d) x,
    ];
    final n = sel.length;
    if (n == 0) {
      out.add(<String, Object?>{'decile': d, 'n': 0, 'signal': 'vide'});
      continue;
    }
    final pm = kmSommeD(<double>[for (final x in sel) x.$1]) / n;
    final om =
        kmSommePy(<double>[
          for (final x in sel)
            if (x.$2) 1.0,
        ]) /
        n;
    final e = (pm - om).abs();
    final ligne = <String, Object?>{
      'decile': d,
      'n': n,
      'p_prevue': pm,
      'observee': om,
      'ecart': e,
    };
    if (n < nMin) {
      ligne['signal'] = 'n < $nMin';
    } else if (pire == null || e > pire) {
      pire = e;
    }
    out.add(ligne);
  }
  return (out, pire);
}

int _peuples(List<Map<String, Object?>> dec, int nMin) =>
    dec.where((x) => kc.ent(x['n']) >= nMin).length;

double? _erreurPonderee(List<Map<String, Object?>> dec, int n) => n > 0
    ? kmSommeD(<double>[
            for (final x in dec)
              if (kc.ent(x['n']) > 0) kc.ent(x['n']) * kc.dbl(x['ecart']),
          ]) /
          n
    : null;

List<(double, bool)> _paires(kc.Json? p, kc.Json parCible) => <(double, bool)>[
  if (p != null && kc.vrai(p['p']))
    for (final ex in _triees(kc.jm(p['p']).keys))
      if (parCible.containsKey(ex))
        (kc.dbl(kc.jm(p['p'])[ex]), parCible[ex] == true),
];

/// Critère 5 : calibration de P(réussite) par cible
/// (`campagne.critere_calibration`), jugée par la mesure fixée par
/// C13.11.2 (graines 0 à 5, une prévision par cible 4 semaines avant
/// l'échéance, déciles d'au moins 30 cibles) ; la mesure de KM1 (toutes
/// les dates) reste dans `detail.mesure_km1`.
Map<String, Object?> kmCritereCalibration(
  List<kc.Json> ok,
  bool sansPlanificateur,
) {
  if (sansPlanificateur) {
    return <String, Object?>{
      'mesure': null,
      'seuil': kmSeuilCalibration,
      'n': 0,
      'respecte': false,
      'methode':
          'non mesuré : campagne sans planificateur (aucune prévision de '
          'P(réussite)).',
      'detail': <String, Object?>{},
    };
  }
  final exclus = <String, int>{};
  final unites = <(List<Object?>, kc.Json)>[];
  for (final r in ok) {
    final cal = kc.jm(r['calibration']);
    for (final e in kc.jm(cal['exclus']).entries) {
      exclus[e.key] = (exclus[e.key] ?? 0) + kc.ent(e.value);
    }
    for (final u in kc.jl(cal['unites'])) {
      unites.add((kc.jl(r['saison']), kc.jm(u)));
    }
  }
  final parDate = <String, Object?>{};
  final pires = <double?>[];
  final manque = <String, Object?>{};
  final insuffisant = <String, Object?>{};
  for (final date in const <String>['debut', 'mi_saison', 'moins_4_semaines']) {
    final paires = <(double, bool)>[];
    final pairesCap = <(double, bool)>[];
    for (final (_, u) in unites) {
      final p = kc.jmOu(kc.jm(u['previsions'])[date]);
      if (p == null || p['p_tout'] == null) {
        manque[date] = ((manque[date] as int?) ?? 0) + 1;
        continue;
      }
      paires.add((kc.dbl(p['p_tout']), u['reussite'] == true));
      pairesCap.add((kc.dbl(p['p_tout']), u['reussite_capacite'] == true));
    }
    final (dec, pire) = kmDeciles(paires);
    final (decCap, pireCap) = kmDeciles(pairesCap);
    final mes = _peuples(dec, kmNMinDecile);
    if (mes < kmDecilesMin) {
      insuffisant[date] = mes;
    }
    parDate[date] = <String, Object?>{
      'n': paires.length,
      'deciles': dec,
      'ecart_max_deciles_n20': pire,
      'deciles_mesurables': mes,
      'p_moyenne': kmMoyenne(<double>[for (final x in paires) x.$1]),
      'reussite_observee': kmMoyenne(<double>[
        for (final x in paires) x.$2 ? 1.0 : 0.0,
      ]),
      'variante_capacite_du_jour': <String, Object?>{
        'deciles': decCap,
        'ecart_max_deciles_n20': pireCap,
        'reussite_observee': kmMoyenne(<double>[
          for (final x in pairesCap) x.$2 ? 1.0 : 0.0,
        ]),
      },
    };
    pires.add(pire);
  }
  // Mesure de KM1 : calibration marginale par cible, toutes dates.
  final marg = <(double, bool)>[];
  final margCap = <(double, bool)>[];
  for (final (_, u) in unites) {
    final prevs = kc.jm(u['previsions']);
    for (final date in _triees(prevs.keys)) {
      final p = kc.jmOu(prevs[date]);
      if (p == null || !kc.vrai(p['p'])) {
        continue;
      }
      final pp = kc.jm(p['p']);
      final rpc = kc.jm(u['reussite_par_cible']);
      final cpc = kc.dictOuVide(u['capacite_par_cible']);
      for (final ex in _triees(pp.keys)) {
        if (rpc.containsKey(ex)) {
          marg.add((kc.dbl(pp[ex]), rpc[ex] == true));
        }
        if (cpc.containsKey(ex)) {
          margCap.add((kc.dbl(pp[ex]), cpc[ex] == true));
        }
      }
    }
  }
  final (decM, pireM) = kmDeciles(marg, kmNMinDecileCible);
  final (decMc, pireMc) = kmDeciles(margCap, kmNMinDecileCible);
  final peuples = _peuples(decM, kmNMinDecileCible);
  final nJuges = kmSommePy(<int>[
    for (final x in decM)
      if (kc.ent(x['n']) >= kmNMinDecileCible) kc.ent(x['n']),
  ]);
  final ece = _erreurPonderee(decM, marg.length);
  // Une seule prévision par cible (4 semaines avant), toutes graines
  // (rapportée en KM1).
  final une = <(double, bool)>[
    for (final (_, u) in unites)
      ..._paires(
        kc.jmOu(kc.jm(u['previsions'])['moins_4_semaines']),
        kc.jm(u['reussite_par_cible']),
      ),
  ];
  final (decU, pireU) = kmDeciles(une, kmNMinDecileCible);
  final mesurable = pireM != null && peuples >= kmDecilesMin;
  final piresTout = <double>[
    for (final x in pires)
      if (x != null) x,
  ];
  // Mesure fixée par C13.11.2 : graines 0 à 5, une prévision par cible.
  final presentes = <int>{};
  var unitesK2 = 0;
  final k2 = <(double, bool)>[];
  for (final (s, u) in unites) {
    final g = kc.ent(s[3]);
    if (!kmGrainesCalibration.contains(g)) {
      continue;
    }
    presentes.add(g);
    unitesK2++;
    k2.addAll(
      _paires(
        kc.jmOu(kc.jm(u['previsions'])['moins_4_semaines']),
        kc.jm(u['reussite_par_cible']),
      ),
    );
  }
  for (final r in ok) {
    final g = kc.ent(kc.jl(r['saison'])[3]);
    if (kmGrainesCalibration.contains(g)) {
      presentes.add(g);
    }
  }
  final (decK2, pireK2) = kmDeciles(k2, kmNMinDecileCible);
  final peuplesK2 = _peuples(decK2, kmNMinDecileCible);
  final nJugesK2 = kmSommePy(<int>[
    for (final x in decK2)
      if (kc.ent(x['n']) >= kmNMinDecileCible) kc.ent(x['n']),
  ]);
  final complete = kmGrainesCalibration.every(presentes.contains);
  final mesurableK2 = pireK2 != null && peuplesK2 >= kmDecilesMin;
  return <String, Object?>{
    'mesure': pireK2,
    'seuil': kmSeuilCalibration,
    'n': k2.length,
    'respecte':
        pireK2 != null &&
        mesurableK2 &&
        complete &&
        pireK2 <= kmSeuilCalibration + _eps,
    'methode':
        "Calibration PAR CIBLE, mesure fixée par C13.11.2 : P(cible atteinte "
        "à l'échéance) prévue par la planification (`p_cibles` de la "
        'replanification, `Planification.previsions`) 4 semaines avant '
        "l'échéance (une seule prévision par cible), saisons des graines 0 à "
        '5, contre la réussite observée de la cible (meilleure barre réussie, '
        'ou valeur faite, au test du jour J >= cible) ; déciles de '
        'probabilité prévue, écart |prévu − observé| max sur les déciles '
        "d'au moins $kmNMinDecileCible cibles ; mesurable avec au moins "
        '$kmDecilesMin déciles peuplés et les six graines présentes. Mesure '
        'de KM1 (toutes les dates, toutes les graines) dans '
        '`detail.mesure_km1` ; P(toutes les cibles) par date dans '
        '`detail.toutes_les_cibles`.',
    'detail': <String, Object?>{
      'mesure_km2': <String, Object?>{
        'graines_demandees': kmGrainesCalibration,
        'graines_presentes': presentes.toList()..sort(),
        'graines_completes': complete,
        'unites': unitesK2,
        'n': k2.length,
        'deciles': decK2,
        'deciles_peuples': peuplesK2,
        'ecart_max': pireK2,
        'mesurable': mesurableK2,
        'part_des_cas_juges': k2.isNotEmpty ? nJugesK2 / k2.length : null,
        'erreur_ponderee_tous_cas': _erreurPonderee(decK2, k2.length),
      },
      'mesure_km1': <String, Object?>{
        'mesure': pireM,
        'n': marg.length,
        'mesurable': mesurable,
        'respecte':
            pireM != null && mesurable && pireM <= kmSeuilCalibration + _eps,
        'methode':
            'KM1 (C13.10.2.c) : toutes les prévisions (début, mi-saison, 4 '
            'semaines avant) de toutes les graines, déciles de '
            '$kmNMinDecileCible cas au moins.',
      },
      'par_cible': <String, Object?>{
        'n': marg.length,
        'unites': unites.length,
        'deciles': decM,
        'deciles_peuples': peuples,
        'ecart_max': pireM,
        'part_des_cas_juges': marg.isNotEmpty ? nJuges / marg.length : null,
        'erreur_ponderee_tous_cas': ece,
        'une_prevision_par_cible': <String, Object?>{
          'n': une.length,
          'deciles': decU,
          'ecart_max': pireU,
        },
        'variante_capacite_du_jour': <String, Object?>{
          'n': margCap.length,
          'deciles': decMc,
          'ecart_max': pireMc,
        },
      },
      'toutes_les_cibles': <String, Object?>{
        'par_date': parDate,
        'dates_insuffisantes': insuffisant,
        'ecart_max_deciles_n20': piresTout.isNotEmpty
            ? piresTout.reduce(math.max)
            : null,
      },
      'exclusions': <String, Object?>{
        for (final k in _triees(exclus.keys)) k: exclus[k],
      },
      'unites_sans_prevision_a_la_date': manque,
      'mesurable': mesurableK2,
    },
  };
}

List<double> _ratios(Object? evs, String mode, int iBest, int iMax) => <double>[
  for (final e0 in kc.jl(evs))
    if (kc.jl(e0)[1] == mode && kc.vrai(kc.jl(e0)[iMax]))
      kc.dbl(kc.jl(e0)[iBest]) / kc.dbl(kc.jl(e0)[iMax]),
];

Map<(String, String, String, int), kc.Json> _runsTemoin(
  Map<KmTriplet, kc.Json> temoin,
) {
  final out = <(String, String, String, int), kc.Json>{};
  for (final e in temoin.entries) {
    final (cle, scen, v) = e.key;
    for (final run in kc.jl(e.value['runs'])) {
      final r = kc.jm(run);
      out[(cle, scen, v, kc.ent(r['seed']))] = r;
    }
  }
  return out;
}

/// Critère 6 : performance le jour J contre le témoin, saisons appariées
/// (`campagne.critere_jour_j`).
Map<String, Object?> kmCritereJourJ(
  List<kc.Json> ok,
  Map<KmTriplet, kc.Json> temoin,
) {
  final runsT = _runsTemoin(temoin);
  final parMode = <String, Map<String, Object?>>{};
  for (final mode in const <String>['loaded', 'reps', 'hold']) {
    final ek = <double>[];
    final et = <double>[];
    final diffs = <double>[];
    final parScen = <String, List<List<double>>>{};
    final parVer = <String, List<List<double>>>{};
    final sans = <String, int>{
      'koach_sans_test': 0,
      'temoin_sans_test': 0,
      'aucun_test': 0,
      'temoin_absent': 0,
    };
    var nSaisons = 0;
    for (final r in ok) {
      if (!kc.vrai(r['echeance'])) {
        continue;
      }
      final (cle, scen, v, g) = kmJobDe(r['saison']);
      final run = runsT[(cle, scen, v, g)];
      final rk = _ratios(r['evenements'], mode, 2, 4);
      if (run == null) {
        sans['temoin_absent'] = sans['temoin_absent']! + 1;
        continue;
      }
      final rt = _ratios(run['events'], mode, 3, 5);
      if (rk.isEmpty && rt.isEmpty) {
        if (mode == 'loaded') {
          sans['aucun_test'] = sans['aucun_test']! + 1;
        }
        continue;
      }
      if (rk.isEmpty) {
        sans['koach_sans_test'] = sans['koach_sans_test']! + 1;
        continue;
      }
      if (rt.isEmpty) {
        sans['temoin_sans_test'] = sans['temoin_sans_test']! + 1;
        continue;
      }
      nSaisons += 1;
      ek.addAll(rk);
      et.addAll(rt);
      diffs.add(kmMoyenne(rk)! - kmMoyenne(rt)!);
      for (final (d, cleD) in <(Map<String, List<List<double>>>, String)>[
        (parScen, scen),
        (parVer, v),
      ]) {
        final x = d.putIfAbsent(
          cleD,
          () => <List<double>>[<double>[], <double>[]],
        );
        x[0].addAll(rk);
        x[1].addAll(rt);
      }
    }
    Map<String, Object?> parCle(Map<String, List<List<double>>> d) =>
        <String, Object?>{
          for (final s in _triees(d.keys))
            s: <String, Object?>{
              'koach': kmMoyenne(d[s]![0]),
              'temoin': kmMoyenne(d[s]![1]),
              'n': <int>[d[s]![0].length, d[s]![1].length],
            },
        };
    parMode[mode] = <String, Object?>{
      'saisons_appariees': nSaisons,
      'tests': <int>[ek.length, et.length],
      'koach': kmMoyenne(ek),
      'temoin': kmMoyenne(et),
      'ecart_apparie_moyen': kmMoyenne(diffs),
      'ecart_apparie_se': kmErreurType(diffs),
      'saisons_sans_test': sans,
      'par_scenario': parCle(parScen),
      'par_verite': parCle(parVer),
    };
  }
  // Témoin sur toutes ses graines (référence, non apparié).
  final tous = <double>[];
  for (final t in temoin.values) {
    for (final run in kc.jl(t['runs'])) {
      tous.addAll(_ratios(kc.jm(run)['events'], 'loaded', 3, 5));
    }
  }
  final l = parMode['loaded']!;
  final mk = kc.dblOu(l['koach']);
  final mt = kc.dblOu(l['temoin']);
  return <String, Object?>{
    'mesure': mk,
    'seuil': mt,
    'n': l['saisons_appariees'],
    'respecte': mk != null && mt != null && mk >= mt - _eps,
    'methode':
        "Jour de l'échéance, mouvements chargés testés : meilleure charge "
        'totale réussie / maximum vrai du jour (`kmEvenements`, ligne '
        '`events` de `kmRunSummary` pour le témoin), moyenne sur les tests '
        'des saisons appariées (même profil, scénario, vérité et graine) où '
        'Koach et le témoin ont tous deux un test ; seuil = moyenne du '
        'témoin.',
    'detail': <String, Object?>{
      'par_mode': parMode,
      'temoin_toutes_graines': <String, Object?>{
        'n': tous.length,
        'moyenne': kmMoyenne(tous),
      },
    },
  };
}

Map<String, Object?> _sommeDicts(Iterable<Object?> dicts) {
  final out = <String, int>{};
  for (final d in dicts) {
    if (!kc.vrai(d)) {
      continue;
    }
    for (final e in kc.jm(d).entries) {
      out[e.key] = (out[e.key] ?? 0) + kc.ent(e.value);
    }
  }
  return <String, Object?>{for (final k in _triees(out.keys)) k: out[k]};
}

int _sommeValeurs(Object? d) {
  var s = 0;
  for (final v in kc.dictOuVide(d).values) {
    s += kc.ent(v);
  }
  return s;
}

/// Critère 7 : sécurité (`campagne.critere_securite`).
Map<String, Object?> kmCritereSecurite(
  List<kc.Json> ok,
  Map<KmTriplet, kc.Json> temoin,
  bool sansPlanificateur,
) {
  var agg = 0;
  var fl = 0;
  var hausses = 0;
  for (final r in ok) {
    agg += kc.ent(r['aggravations']);
    fl += kc.ent(r['poussees']);
    hausses += kc.ent(kc.jm(r['effort'])['hausses_trop_fortes']);
  }
  final sec = <String, Map<String, Object?>>{};
  for (final vue in kmVuesSecurite) {
    if (sansPlanificateur && vue == 'plan_module') {
      continue;
    }
    final cats = <String, Object?>{};
    final exemples = <Object?>[];
    for (final cat in const <String>[
      'deja_initial',
      'aggrave',
      'introduit',
      'retour_ecrit',
    ]) {
      cats[cat] = _sommeDicts(<Object?>[
        for (final r in ok)
          kc.dictOuVide(kc.jm(kc.jm(r['securite'])[vue])[cat]),
      ]);
    }
    var nIntro = 0;
    for (final r in ok) {
      final s = kc.jm(kc.jm(r['securite'])[vue]);
      if (kc.vrai(s['introduit']) || kc.vrai(s['aggrave'])) {
        nIntro += 1;
        if (exemples.length < 8) {
          exemples.add(<String, Object?>{
            'saison': r['saison'],
            'constats': kc.jm(r['securite'])['${vue}_exemples'],
          });
        }
      }
    }
    cats['saisons_touchees'] = nIntro;
    cats['exemples'] = exemples;
    if (vue == 'servi_tests_faits') {
      cats['dont_dus_aux_manquees'] = _sommeDicts(<Object?>[
        for (final r in ok)
          kc.dictOuVide(kc.jm(r['securite'])['${vue}_dus_aux_manquees']),
      ]);
    }
    sec[vue] = cats;
  }
  final initial = _sommeDicts(<Object?>[
    for (final r in ok) kc.jm(r['securite'])['initial'],
  ]);
  final runsT = _runsTemoin(temoin);
  final app = <kc.Json>[
    for (final r in ok)
      if (runsT.containsKey(kmJobDe(r['saison']))) runsT[kmJobDe(r['saison'])]!,
  ];
  final tous = <kc.Json>[
    for (final t in temoin.values)
      for (final run in kc.jl(t['runs'])) kc.jm(run),
  ];
  var haussesT = 0;
  for (final t in temoin.values) {
    haussesT += kc.ent(kc.jm(t['coach'])['schemeRisesOverLimit'] ?? 0);
  }
  Map<String, Object?> resume(List<kc.Json> runs) {
    var a = 0;
    var p = 0;
    var v = 0;
    for (final x in runs) {
      a += kc.ent(x['painAggravations']);
      p += kc.ent(x['painFlares']);
      v += kc.ent(x['violations']);
    }
    return <String, Object?>{
      'saisons': runs.length,
      'aggravations': a,
      'poussees': p,
      'violations': v,
      'codes': _sommeDicts(<Object?>[
        for (final x in runs) x['violationCodes'],
      ]),
    };
  }

  int intro(String vue) {
    final s = sec[vue];
    if (s == null) {
      return 0;
    }
    return _sommeValeurs(s['introduit']) + _sommeValeurs(s['aggrave']);
  }

  final total =
      agg + fl + hausses + intro('plan_module') + intro('servi_tests_faits');
  return <String, Object?>{
    'mesure': total,
    'seuil': 0,
    'n': ok.length,
    'respecte': total == 0,
    'mesure_avec_rampes_de_test':
        agg + fl + hausses + intro('plan_module') + intro('servi'),
    'methode':
        "Somme (a) des aggravations et poussées de douleur de l'athlète "
        'simulé, (b) des constats du validateur de sécurité du banc '
        '(`safetyFindings`) introduits ou aggravés par Koach par rapport au '
        'plan initial de kalis_plan (sur `blocsModules` de la planification '
        'et sur les séances servies telles que prescrites, tests ajoutés par '
        'Koach comptés pour leurs tentatives faites), (c) des hausses de '
        'charge > 10 % sur plusieurs crans (`kmEffort`). La vue `servi` '
        '(rampes de test comprises) est rapportée à part : '
        '`mesure_avec_rampes_de_test`.',
    'detail': <String, Object?>{
      'a_douleur': <String, Object?>{'aggravations': agg, 'poussees': fl},
      'b_validateur': <String, Object?>{
        'plan_initial': initial,
        'vues': sec,
        'note':
            '`plan_module` = blocs de référence + plan de la planification '
            '(`Planification.blocsModules`) ; `servi` = blocs de référence '
            'où chaque séance faite est remplacée par les items servis par '
            'Koach (séries prescrites, contrôle dual et allègement compris) ; '
            '`servi_tests_faits` = idem, tests ajoutés par Koach comptés pour '
            'leurs tentatives faites (le validateur compte chaque tentative '
            "prescrite d'une rampe de test comme une série dure)",
      },
      'c_hausses_trop_fortes': hausses,
      'temoin_apparie': resume(app),
      'temoin_toutes_graines': resume(tous),
      'temoin_hausses_trop_fortes': haussesT,
    },
  };
}

Map<String, Object?> _horizonsMj(kc.Json mj) {
  final ea = kc.jm(mj['ecart_abs']);
  final sg = kc.jm(mj['ecart_signe_moyen']);
  return <String, Object?>{
    for (final k in kmHorizons)
      k: <String, Object?>{
        'moyenne_abs': kc.jm(ea[k])['moyenne'],
        'mediane_abs': kc.jm(ea[k])['mediane'],
        'p95_abs': kc.jm(ea[k])['p95'],
        'max_abs': kc.jm(ea[k])['max'],
        'n': kc.jm(ea[k])['n'],
        'signe_moyen': sg[k],
      },
  };
}

double? _maxMoyennes(Map<String, Object?> h) {
  final moy = <double>[
    for (final x in h.values)
      if (kc.jm(x)['moyenne_abs'] != null) kc.dbl(kc.jm(x)['moyenne_abs']),
  ];
  return moy.isNotEmpty ? moy.reduce(math.max) : null;
}

/// Critère 2 : mauvais jour isolé (`campagne.critere_mauvais_jour`) :
/// [mj] contrefactuel apparié (critère), [divergent] mesure de KM1.
Map<String, Object?> kmCritereMauvaisJour(kc.Json mj, [kc.Json? divergent]) {
  final h = _horizonsMj(mj);
  final detail = <String, Object?>{
    'horizons': h,
    'saisons': mj['saisons'],
    'plantages': kc.listeOuVide(mj['plantages']).length,
    'jobs': mj['jobs'],
    'erreurs': mj['erreurs'] ?? 0,
  };
  if (divergent != null) {
    final hd = _horizonsMj(divergent);
    detail['saisons_divergentes'] = <String, Object?>{
      'horizons': hd,
      'mesure': _maxMoyennes(hd),
      'note':
          'mesure de KM1 : les deux saisons divergent après le mauvais jour',
    };
  }
  return <String, Object?>{
    'mesure': _maxMoyennes(h),
    'seuil': kmSeuilMauvaisJour,
    'n': mj['saisons_mesurees'],
    'respecte': mj['respecte'] == true,
    'methode':
        '`kmAgregerMauvaisJour(apparie: true)` : contrefactuel apparié '
        '(C13.10.2.b). Le journal de la saison est rejoué deux fois dans un '
        'moteur neuf : tel quel, puis avec la séance du mauvais jour (−6 % de '
        'capacité, 2e moitié, après 6 séances) à la place de la séance du '
        'même jour, les séances suivantes restant celles de la saison telle '
        'quelle ; écart relatif des e1RM des principaux chargés juste après, '
        '+1 et +2 séances ; mesure = pire moyenne absolue des trois horizons.',
    'detail': detail,
  };
}

/// Critère 8 : temps de calcul (`campagne.critere_temps`) sur la VM Dart ;
/// mise à jour après une série = `observe` + `plan` de la série suivante.
Map<String, Object?> kmCritereTemps(kc.Json t, String source) {
  final serie = kc.jm(t['observe_serie_ms']);
  final rs = kc.jm(t['replanification_s']);
  final maj = kc.jmOu(t['mise_a_jour_serie_ms']);
  return <String, Object?>{
    'mesure': <String, Object?>{
      'observe_serie_ms_max': serie['max'],
      'replanification_s_max': rs['max'],
      'mise_a_jour_serie_ms_max': maj?['max'],
    },
    'seuil': <String, Object?>{
      'serie_ms': kmSeuilSerieMs,
      'replanification_s': kmSeuilReplanificationS,
    },
    'n': serie['n'],
    'respecte': t['respecte'] == true,
    'methode':
        '`kmMesurerTemps` : `observe` série, `plan` de la série suivante et '
        '`plan` de séance sur une saison complète, puis chaque '
        'replanification (validateur compris), VM Dart ; critère série = '
        'mise à jour après une série (observe + plan de la série suivante).',
    'detail': <String, Object?>{
      'source': source,
      'observe_serie_ms': serie,
      'plan_serie_ms': t['plan_serie_ms'],
      'plan_seance_ms': t['plan_seance_ms'],
      'mise_a_jour_serie_ms': maj,
      'replanification_s': rs,
      'replanification': t['replanification'],
      'saison': t['saison'],
    },
  };
}

/// Critère 9 : rappels lus sans recalcul (`campagne.critere_rappels`) :
/// [adversaires] contenu de `comparaison_adversaires.json`, [rejeu] de
/// `rejeu_journal_agregats.json` (null : fichier absent).
Map<String, Object?> kmCritereRappels(
  kc.Json? adversaires,
  kc.Json? rejeu, {
  String fichierAdversaires = 'donnees/comparaison_adversaires.json',
  String fichierRejeu = 'donnees/rejeu_journal_agregats.json',
}) {
  final detail = <String, Object?>{};
  final out = <String, Object?>{
    'methode': 'lecture seule des fichiers existants, sans recalcul',
    'detail': detail,
  };
  if (adversaires != null) {
    final c = kc.dictOuVide(adversaires['critere']);
    detail['pire_cas_adversarial'] = <String, Object?>{
      'fichier': fichierAdversaires,
      'critere': c,
      'pires': kc.dictOuVide(adversaires['groupes'])['pires'],
    };
  } else {
    detail['pire_cas_adversarial'] = null;
  }
  if (rejeu != null) {
    detail['rejeu_journal'] = <String, Object?>{
      'fichier': fichierRejeu,
      'objectif_brique_8': rejeu['objectif_brique_8'],
      'rejeu': rejeu['rejeu'],
      'une_seance_d_avance': kc.dictOuVide(
        rejeu['A_une_seance_d_avance'],
      )['total'],
      'series_fiables': kc.dictOuVide(
        rejeu['A_series_fiables_1_5_en_reserve_ou_moins'],
      )['total'],
      'tests_reels': kc.dictOuVide(rejeu['B_tests_reels'])['total'],
    };
  } else {
    detail['rejeu_journal'] = null;
  }
  final respecte = <String, Object?>{};
  if (adversaires != null &&
      kc.dictOuVide(adversaires['critere']).containsKey('respecte')) {
    respecte['pire_cas_adversarial'] = kc.vrai(
      kc.jm(adversaires['critere'])['respecte'],
    );
  }
  out['rapporte_seulement'] = <String>['rejeu_journal'];
  out['respecte'] = respecte;
  return out;
}

/// Mesures secondaires (`campagne.secondaires`).
Map<String, Object?> kmSecondaires(
  List<kc.Json> ok,
  KmAgregats a,
  Map<KmTriplet, kc.Json> temoin,
) {
  final ee = <kc.Json>[
    for (final r in ok)
      if (kc.jm(r['effort'])['ecart_effort'] != null) kc.jm(r['effort']),
  ];
  final gains = <num>[
    for (final r in ok)
      if (r['gain'] != null) r['gain']! as num,
  ];
  var seances = 0;
  for (final r in ok) {
    seances += kc.ent(r['seances']);
  }
  final alertes = <int>[
    for (final r in ok)
      if (r['alertes'] != null) kc.ent(r['alertes']),
  ];
  final gapT = <num?>[
    for (final t in temoin.values)
      if (kc.vrai(kc.jm(kc.jm(t['coach'])['effortGap'])['n']))
        kc.jm(kc.jm(t['coach'])['effortGap'])['mean'] as num?,
  ];
  final failT = <num?>[
    for (final t in temoin.values)
      kc.jm(kc.jm(t['coach'])['failRate'])['mean'] as num?,
  ];
  final gainT = <num?>[
    for (final t in temoin.values)
      for (final run in kc.jl(t['runs']))
        if (kc.jm(run)['gainMean'] != null) kc.jm(run)['gainMean'] as num?,
  ];
  final sommeAlertes = kmSommePy(alertes);
  return <String, Object?>{
    'mae_rang_6': <String, Object?>{
      for (final m in const <String>['reps', 'hold'])
        m: <String, Object?>{
          'koach': a.k[m]!.ligneJson(kmRang),
          'temoin': a.t[m]!.ligneJson(kmRang),
        },
    },
    'ecart_effort': <String, Object?>{
      'koach': kmMoyenne(<num?>[for (final e in ee) e['ecart_effort'] as num?]),
      'temoin': kmMoyenne(gapT),
    },
    'echecs': <String, Object?>{
      'koach': kmMoyenne(<num?>[for (final e in ee) e['echecs'] as num?]),
      'temoin': kmMoyenne(failT),
    },
    'tentatives_reussies': <String, Object?>{
      'koach': kmMoyenne(<num?>[
        for (final e in ee)
          if (e['tentatives'] != null) e['tentatives'] as num?,
      ]),
    },
    'gain_moyen_hebdo': <String, Object?>{
      'koach': kmMoyenne(gains),
      'temoin': kmMoyenne(gainT),
    },
    'alertes_rupture_par_100_seances': <String, Object?>{
      'koach': (alertes.isNotEmpty && seances != 0)
          ? 100.0 * sommeAlertes / seances
          : null,
      'alertes': sommeAlertes,
      'seances': seances,
    },
    'seances_faites_sur_prevues': kmMoyenne(<double>[
      for (final r in ok)
        if (kc.vrai(r['prevues'])) kc.ent(r['seances']) / kc.dbl(r['prevues']),
    ]),
  };
}

/// Section `temoin` (KM2) : chaque critère, Koach et témoin 0.3.1 côte à
/// côte là où la mesure est comparable.
Map<String, Object?> kmSectionTemoin(
  Map<String, Map<String, Object?>> criteres,
  KmAgregats a,
) {
  Object? d(String c, List<String> chemin) {
    Object? x = criteres[c]!['detail'];
    for (final k in chemin) {
      if (x is! Map<String, Object?>) {
        return null;
      }
      x = x[k];
    }
    return x;
  }

  final c7 = kc.jm(criteres['7_securite']!['detail']);
  final ta = kc.jm(c7['temoin_apparie']);
  final cov = a.t['loadedMain']!.apres(kmRangCouverture);
  final adv = kc.jmOu(d('9_rappels', <String>['pire_cas_adversarial']));
  final advC = adv == null ? null : kc.jmOu(adv['critere']);
  return <String, Object?>{
    'version': '0.3.1',
    'source': '`kmWitnessSeason` (mêmes profils, scénarios et vérités)',
    'criteres': <String, Object?>{
      '1_erreur_e1rm_rang_6': <String, Object?>{
        'comparable': true,
        'koach': criteres['1_erreur_e1rm_rang_6']!['mesure'],
        'temoin': kc.jmOu(
          d('1_erreur_e1rm_rang_6', <String>['temoin']),
        )?['mae'],
        'temoin_par_verite': <String, Object?>{
          for (final v in _triees(a.tv.keys))
            v: a.tv[v]!.ligneJson(kmRang)?['mae'],
        },
      },
      '2_mauvais_jour_isole': <String, Object?>{
        'comparable': false,
        'note':
            "contrefactuel apparié : rejeu du journal de Koach, sans "
            'équivalent dans 0.3.1',
      },
      '3_convergence_sous_3': <String, Object?>{
        'comparable': true,
        'koach': criteres['3_convergence_sous_3']!['mesure'],
        'temoin': criteres['3_convergence_sous_3']!['seuil'],
      },
      '4_couverture_90': <String, Object?>{
        'comparable': true,
        'koach': criteres['4_couverture_90']!['mesure'],
        'temoin': cov?['couverture'],
        'n_temoin': cov?['n'],
        'note':
            "intervalle annoncé par 0.3.1 (|erreur| <= 1,6449 × sd relatif)",
      },
      '5_calibration_p_reussite': <String, Object?>{
        'comparable': false,
        'note': '0.3.1 ne prévoit pas P(réussite)',
      },
      '6_performance_jour_j': <String, Object?>{
        'comparable': true,
        'koach': criteres['6_performance_jour_j']!['mesure'],
        'temoin': criteres['6_performance_jour_j']!['seuil'],
      },
      '7_securite': <String, Object?>{
        'comparable': true,
        'koach': criteres['7_securite']!['mesure'],
        'temoin':
            kc.ent(ta['aggravations']) +
            kc.ent(ta['poussees']) +
            kc.ent(ta['violations']),
        'note':
            'témoin apparié : aggravations + poussées + violations du '
            'programme réalisé (`realizedFindings`)',
      },
      '8_temps_calcul': <String, Object?>{
        'comparable': false,
        'note': 'critère propre à Koach (seuils absolus)',
      },
      '9_rappels': <String, Object?>{
        'comparable': advC != null,
        'koach': advC?['pire_koach'],
        'temoin': advC?['pire_temoin'],
      },
    },
  };
}

/// Résultat de la campagne (`campagne.campagne`, après l'exécution) :
/// critères, secondaires, bilan, section témoin, arrondis (`_arrondir`).
///
/// [resultats] : résultat de chaque saison de [jobs] par [kmNomJob]
/// (`{'plantage', 'trace'}` pour une saison qui a planté) ; [temoin] :
/// [kmChargerTemoin] ; [mauvaisJour], [mauvaisJourDivergent] :
/// [kmResumeMauvaisJour] des deux mesures ; [temps] : [kmMesurerTemps].
Map<String, Object?> kmCampagne({
  required KmOptionsCampagne opts,
  required kc.Json parametres,
  required kc.Json configuration,
  required String empreinteSources,
  required List<KmJob> jobs,
  required Map<String, kc.Json> resultats,
  required Map<KmTriplet, kc.Json> temoin,
  required Object? Function(String cle, String scenario) niveauDe,
  required kc.Json mauvaisJour,
  required kc.Json? mauvaisJourDivergent,
  required kc.Json temps,
  required String sourceTemps,
  kc.Json? adversaires,
  kc.Json? rejeu,
  kc.Json? determinisme,
}) {
  final ok = <kc.Json>[];
  final plantes = <Object?>[];
  for (final j in jobs) {
    final r = resultats[kmNomJob(j)];
    if (r == null) {
      throw StateError('saison sans résultat : ${kmNomJob(j)}');
    }
    if (r.containsKey('plantage')) {
      plantes.add(<String, Object?>{
        'saison': <Object?>[j.$1, j.$2, j.$3, j.$4],
        'erreur': r['plantage'],
        'trace': r['trace'],
      });
    } else {
      ok.add(r);
    }
  }
  final a = kmAgregerEstimations(ok, temoin, niveauDe);
  final defautSd =
      opts.defautModele ??
      kc.dictOuVide(parametres['mesure'])['defaut_modele_sd'];
  final criteres = <String, Map<String, Object?>>{
    '1_erreur_e1rm_rang_6': kmCritereE1rm(a),
    '2_mauvais_jour_isole': kmCritereMauvaisJour(
      mauvaisJour,
      mauvaisJourDivergent,
    ),
    '3_convergence_sous_3': kmCritereConvergence(a),
    '4_couverture_90': kmCritereCouverture(a, defautSd),
    '5_calibration_p_reussite': kmCritereCalibration(
      ok,
      opts.sansPlanificateur,
    ),
    '6_performance_jour_j': kmCritereJourJ(ok, temoin),
    '7_securite': kmCritereSecurite(ok, temoin, opts.sansPlanificateur),
    '8_temps_calcul': kmCritereTemps(temps, sourceTemps),
    '9_rappels': kmCritereRappels(adversaires, rejeu),
  };
  final bilan = <String, Object?>{
    'respectes': _triees(<String>[
      for (final e in criteres.entries)
        if (e.value['respecte'] == true) e.key,
    ]),
    'non_respectes': _triees(<String>[
      for (final e in criteres.entries)
        if (e.value['respecte'] == false) e.key,
    ]),
  };
  final sortie = <String, Object?>{
    'schema': kmSchemaCriteres,
    'configuration': configuration,
    'empreinte_sources': empreinteSources,
    'saisons': <String, Object?>{
      'prevues': jobs.length,
      'mesurees': ok.length,
      'plantees': plantes.length,
      'plantages': plantes,
      'temoin_triplets': temoin.length,
    },
    'criteres': criteres,
    'secondaires': kmSecondaires(ok, a, temoin),
    'bilan': bilan,
    'temoin': kmSectionTemoin(criteres, a),
    if (determinisme != null) 'determinisme': determinisme,
  };
  return kc.jm(kmArrondir(sortie));
}

/// Couverture (rangs >= 3, principaux chargés) des saisons [resultats]
/// (`campagne.couverture_de`).
double? kmCouverture(Iterable<kc.Json> resultats) {
  final e = KmEstimations();
  for (final r in resultats) {
    if (r.containsKey('plantage')) {
      continue;
    }
    final lm = kc.jm(kc.jm(r['estimations'])['loadedMain']);
    e.cumuler(lm['rows'], lm['first_under']);
  }
  final x = e.apres(kmRangCouverture);
  return x == null ? null : kc.dbl(x['couverture']);
}

// ----------------------------------------------------------------------
// Résumé lisible (`campagne.resume`)
// ----------------------------------------------------------------------

String _g4(double x) {
  if (x == 0) {
    return '0';
  }
  final s = x.toStringAsExponential(3);
  final iE = s.indexOf('e');
  final e = int.parse(s.substring(iE + 1));
  String sansZeros(String t) {
    if (!t.contains('.')) {
      return t;
    }
    var u = t.replaceAll(RegExp(r'0+$'), '');
    if (u.endsWith('.')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  if (e < -4 || e >= 4) {
    final m = sansZeros(s.substring(0, iE));
    return '${m}e${e < 0 ? '-' : '+'}${e.abs().toString().padLeft(2, '0')}';
  }
  return sansZeros(x.toStringAsFixed(3 - e));
}

String _f(Object? x, [bool pct = false]) {
  if (x == null) {
    return '—';
  }
  final v = kc.dbl(x);
  return pct ? '${(100 * v).toStringAsFixed(2)} %' : _g4(v);
}

/// Résumé lisible de la sortie [s] de [kmCampagne].
String kmResume(Map<String, Object?> s) {
  final c = kc.jm(s['criteres']);
  final lignes = <String>[];
  String ok(String k) {
    final r = kc.jm(c[k])['respecte'];
    return r == true ? 'OK ' : (r == false ? 'NON' : ' ? ');
  }

  Object? g(Object? m, String k) => m is Map<String, Object?> ? m[k] : null;
  final sa = kc.jm(s['saisons']);
  lignes.add(
    'saisons : ${sa['prevues']} prévues, ${sa['mesurees']} mesurées, '
    '${sa['plantees']} plantées',
  );
  var d = kc.jm(c['1_erreur_e1rm_rang_6']);
  final dd = kc.jm(d['detail']);
  lignes.add(
    '[${ok('1_erreur_e1rm_rang_6')}] 1 e1RM rang 6 : Koach '
    '${_f(d['mesure'], true)} (n=${d['n']}), témoin '
    '${_f(g(dd['temoin'], 'mae'), true)} ; seuil < 3 %',
  );
  final pv = kc.jm(dd['par_verite']);
  lignes.add(
    '      par vérité : ${[for (final v in _triees(pv.keys)) '$v ${_f(g(g(pv[v], 'koach'), 'mae'), true)}/${_f(g(g(pv[v], 'temoin'), 'mae'), true)}'].join(', ')}',
  );
  d = kc.jm(c['2_mauvais_jour_isole']);
  final h = kc.jm(kc.jm(d['detail'])['horizons']);
  lignes.add(
    '[${ok('2_mauvais_jour_isole')}] 2 mauvais jour : |écart| moyen '
    '${_f(g(h['apres'], 'moyenne_abs'), true)} (après) '
    '${_f(g(h['plus_1'], 'moyenne_abs'), true)} (+1) '
    '${_f(g(h['plus_2'], 'moyenne_abs'), true)} (+2), médian après '
    '${_f(g(h['apres'], 'mediane_abs'), true)}, signé '
    '${_f(g(h['apres'], 'signe_moyen'), true)} ; seuil < 1 %',
  );
  d = kc.jm(c['3_convergence_sous_3']);
  final k3 = kc.jm(kc.jm(d['detail'])['koach']);
  final t3 = kc.jm(kc.jm(d['detail'])['temoin']);
  lignes.add(
    '[${ok('3_convergence_sous_3')}] 3 convergence : premier passage '
    '(censuré) Koach ${_f(k3['moyenne_censuree'])}, témoin '
    '${_f(t3['moyenne_censuree'])} ; atteints ${_f(k3['moyenne_atteints'])} '
    '/ ${_f(t3['moyenne_atteints'])} ; jamais ${_f(k3['part_jamais'], true)} '
    '/ ${_f(t3['part_jamais'], true)}',
  );
  d = kc.jm(c['4_couverture_90']);
  final pr = kc.jm(kc.jm(d['detail'])['par_rang']);
  final rangs = pr.keys.toList()
    ..sort((x, y) => int.parse(x).compareTo(int.parse(y)));
  lignes.add(
    '[${ok('4_couverture_90')}] 4 couverture 90 % (rangs >= 3) : '
    '${_f(d['mesure'], true)} (n=${d['n']}) ; par rang '
    '${[for (final r in rangs) '$r:${_f(g(pr[r], 'couverture'), true)}'].join(', ')} ; '
    'seuil 88–92 %',
  );
  d = kc.jm(c['5_calibration_p_reussite']);
  final d5 = kc.jm(d['detail']);
  if (d5.isNotEmpty) {
    final k2 = kc.jm(d5['mesure_km2']);
    lignes.add(
      '[${ok('5_calibration_p_reussite')}] 5 calibration P(réussite) par '
      'cible (C13.11.2) : écart max ${_f(d['mesure'], true)} (déciles de n '
      '>= $kmNMinDecileCible) ; n=${d['n']} ; graines '
      '${k2['graines_presentes']} ; '
      '${[for (final x in kc.jl(k2['deciles']))
        if (kc.ent(g(x, 'n')) > 0) 'd${g(x, 'decile')} n=${g(x, 'n')} p=${_f(g(x, 'p_prevue'), true)} obs=${_f(g(x, 'observee'), true)}'].join(', ')}',
    );
    final k1 = kc.jm(d5['mesure_km1']);
    lignes.add(
      '      mesure de KM1 (toutes dates) : écart max '
      '${_f(k1['mesure'], true)} (n=${k1['n']})',
    );
    lignes.add('      exclusions : ${_jsonTexte(d5['exclusions'])}');
  } else {
    lignes.add(
      '[${ok('5_calibration_p_reussite')}] 5 calibration : ${d['methode']}',
    );
  }
  d = kc.jm(c['6_performance_jour_j']);
  final l6 = kc.jm(kc.jm(kc.jm(d['detail'])['par_mode'])['loaded']);
  lignes.add(
    '[${ok('6_performance_jour_j')}] 6 jour J (chargé, best/max) : Koach '
    '${_f(d['mesure'])}, témoin ${_f(d['seuil'])} '
    '(${l6['saisons_appariees']} saisons appariées, écart '
    '${_f(l6['ecart_apparie_moyen'])} ± ${_f(l6['ecart_apparie_se'])}) ; '
    'sans test ${_jsonTexte(l6['saisons_sans_test'])}',
  );
  d = kc.jm(c['7_securite']);
  final d7 = kc.jm(d['detail']);
  final vues = kc.jm(kc.jm(d7['b_validateur'])['vues']);
  lignes.add(
    '[${ok('7_securite')}] 7 sécurité : douleur ${_jsonTexte(d7['a_douleur'])}, '
    'hausses ${d7['c_hausses_trop_fortes']}, validateur '
    '${_jsonTexte(<String, Object?>{
      for (final v in vues.entries) v.key: <String, Object?>{'introduit': g(v.value, 'introduit'), 'aggrave': g(v.value, 'aggrave'), 'deja_initial': g(v.value, 'deja_initial')},
    })} ; témoin apparié '
    '${_jsonTexte(<String, Object?>{
      for (final k in const <String>['aggravations', 'poussees', 'violations']) k: g(d7['temoin_apparie'], k),
    })}',
  );
  d = kc.jm(c['8_temps_calcul']);
  final m8 = kc.jm(d['mesure']);
  lignes.add(
    '[${ok('8_temps_calcul')}] 8 temps : mise à jour série max '
    '${_f(m8['mise_a_jour_serie_ms_max'])} ms (observe seul '
    '${_f(m8['observe_serie_ms_max'])} ms), replanification max '
    '${_f(m8['replanification_s_max'])} s '
    '(${g(d['detail'], 'source')})',
  );
  d = kc.jm(c['9_rappels']);
  lignes.add('      9 rappels : ${_jsonTexte(d['respecte'])}');
  final sc = kc.jm(s['secondaires']);
  final mae = kc.jm(sc['mae_rang_6']);
  lignes.add(
    'secondaires : MAE6 reps ${_f(g(g(mae['reps'], 'koach'), 'mae'), true)}/'
    '${_f(g(g(mae['reps'], 'temoin'), 'mae'), true)}, tenues '
    '${_f(g(g(mae['hold'], 'koach'), 'mae'), true)}/'
    '${_f(g(g(mae['hold'], 'temoin'), 'mae'), true)}, écart effort '
    '${_f(g(sc['ecart_effort'], 'koach'))}/'
    '${_f(g(sc['ecart_effort'], 'temoin'))}, échecs '
    '${_f(g(sc['echecs'], 'koach'), true)}/'
    '${_f(g(sc['echecs'], 'temoin'), true)}, gain '
    '${_f(g(sc['gain_moyen_hebdo'], 'koach'))}/'
    '${_f(g(sc['gain_moyen_hebdo'], 'temoin'))}, alertes/100 séances '
    '${_f(g(sc['alertes_rupture_par_100_seances'], 'koach'))}',
  );
  final b = kc.jm(s['bilan']);
  lignes.add(
    'bilan : respectés ${_jsonTexte(b['respectes'])} ; NON respectés '
    '${_jsonTexte(b['non_respectes'])}',
  );
  return lignes.join('\n');
}

/// Texte JSON compact (clés triées) d'une valeur, pour le résumé.
String _jsonTexte(Object? x) => kmTexteCanonique(x);
