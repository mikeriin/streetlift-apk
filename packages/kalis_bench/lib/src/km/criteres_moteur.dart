/// Critères du cahier KM mesurés sur le moteur Dart (lot KM2) : portage de
/// `reference/banc/criteres_moteur.py`.
///
/// 1. **temps** : `observe` d'une série, `plan` (série, séance) et
///    replanification (jumeau, plans évalués, validateur de sécurité du
///    banc) ; la mesure de l'horloge est faite par `bin/` : les fonctions de
///    ce fichier reçoivent un chronomètre [KmChrono] ;
/// 2. **mauvais jour isolé** : contrefactuel apparié (mesure du critère,
///    C13.10.2.b) et saisons divergentes (mesure de KM1, rapportée) ;
/// 3. **déterminisme** : empreintes d'une exécution complète, comparées
///    entre deux isolats par `bin/`.
///
/// Fonctions pures (aucun accès disque, aucune horloge) ; outils communs à
/// `campagne.dart` : somme de Python ([kmSommePy]), arrondi de Python
/// ([kmArrondiPy]), statistiques ([kmStats]), tri stable ([kmTriStable]),
/// texte canonique ([kmTexteCanonique]).
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kalis_adapt/kalis_adapt.dart' show ExerciseBook;
import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_core/kalis_core.dart';

import '../adapter.dart' show benchStartDate;
import '../analysis.dart' show ProgramView;
import '../profile.dart' show benchObject;
import '../program.dart' show BenchProgram;
import '../safety.dart' show safetyFindings;
import '../season.dart' show SeasonScenario, seasonScenarioApplies;
import 'km_export.dart'
    show KmSeason, kmReferenceSeason, kmScenarioOf, kmServedBlocks;
import 'meneur.dart' show KmContexte, KmPolitique, KmTour, kmSimuler;
import 'politique_koach.dart' show PolitiqueKoach;

/// Seuil du cahier : mise à jour après une série (ms).
const double kmSeuilSerieMs = 50.0;

/// Seuil du cahier : replanification hebdomadaire (s).
const double kmSeuilReplanificationS = 10.0;

/// Seuil du cahier : effet d'un mauvais jour isolé.
const double kmSeuilMauvaisJour = 0.01;

/// Baisse de capacité de toute la séance du mauvais jour.
const double kmMauvaisJour = 0.06;

/// Séances de l'exercice avant le mauvais jour.
const int kmSeancesAvant = 6;

/// Horizons de lecture de l'effet du mauvais jour.
const List<String> kmHorizons = <String>['apres', 'plus_1', 'plus_2'];

/// Saison chronométrée (profil, scénario, vérité, graine).
const (String, String, String, int) kmSaisonTemps = (
  'street_07_avance_streetlifting_competition',
  'reference',
  'a',
  0,
);

/// Saison du contrôle de déterminisme.
const (String, String, String, int) kmSaisonDeterminisme = (
  'street_07_avance_streetlifting_competition',
  'douleur_coude',
  'b',
  1,
);

/// Profils dont les mouvements principaux sont chargés.
const List<String> kmProfilsCharges = <String>[
  'street_07_avance_streetlifting_competition',
  'street_09_elite_streetlifting',
  'street_16_specialisation_traction_lestee',
  'autres_02_hypertrophie_intermediaire',
  'autres_03_powerlifter_competition',
  'autres_04_force_generale_46_ans',
];

/// Extensions de Koach montées par la campagne, dans l'ordre.
const List<String> kmBriquesCompletes = <String>[
  'planification',
  'surveillance',
  'dual',
  'adherence',
];

// ----------------------------------------------------------------------
// Outils de portage (sémantique de Python 3.13)
// ----------------------------------------------------------------------

/// `sum(xs)` de CPython 3.13 (départ 0) : entiers additionnés exactement
/// tant qu'il n'y a que des entiers ; au premier flottant, somme compensée
/// de Neumaier (les entiers qui suivent sont ajoutés sans compensation),
/// compensation ajoutée à la fin si elle est non nulle et finie. Rend un
/// `int` si [xs] ne contient que des entiers.
num kmSommePy(Iterable<num> xs) {
  var i = 0;
  final it = xs.iterator;
  while (it.moveNext()) {
    final x = it.current;
    if (x is int) {
      i += x;
      continue;
    }
    var f = i.toDouble() + x.toDouble();
    var c = 0.0;
    while (it.moveNext()) {
      final y = it.current;
      if (y is int) {
        f += y.toDouble();
        continue;
      }
      final yd = y.toDouble();
      final t = f + yd;
      if (f.abs() >= yd.abs()) {
        c += (f - t) + yd;
      } else {
        c += (yd - t) + f;
      }
      f = t;
    }
    if (c != 0.0 && c.isFinite) {
      f += c;
    }
    return f;
  }
  return i;
}

/// Somme de Python d'une liste de doubles (rend un double).
double kmSommeD(Iterable<double> xs) => kmSommePy(xs).toDouble();

/// `round(x, n)` de Python : arrondi décimal correct de la valeur binaire
/// exacte de [x], égalité au pair, relu au double le plus proche.
double kmArrondiPy(double x, [int n = 6]) {
  if (n < 0) {
    throw ArgumentError('kmArrondiPy : n >= 0 attendu');
  }
  if (x.isNaN || x.isInfinite || x == 0.0) {
    return x;
  }
  final neg = x < 0;
  final a = neg ? -x : x;
  final bd = ByteData(8)..setFloat64(0, a, Endian.big);
  final hi = bd.getUint32(0, Endian.big);
  final lo = bd.getUint32(4, Endian.big);
  final expBits = (hi >> 20) & 0x7ff;
  var mant =
      BigInt.from(hi & 0xfffff) * BigInt.from(0x100000000) + BigInt.from(lo);
  int e;
  if (expBits == 0) {
    e = -1074;
  } else {
    mant += BigInt.one << 52;
    e = expBits - 1075;
  }
  final scaled = mant * BigInt.from(10).pow(n);
  BigInt q;
  if (e >= 0) {
    q = scaled << e;
  } else {
    final d = BigInt.one << (-e);
    q = scaled ~/ d;
    final r = scaled - q * d;
    final deux = r * BigInt.two;
    if (deux > d || (deux == d && q.isOdd)) {
      q += BigInt.one;
    }
  }
  return double.parse('${neg ? '-' : ''}${q}e-$n');
}

/// Tri stable (comme `sorted` de Python) : à égalité, l'ordre d'origine.
List<T> kmTriStable<T>(Iterable<T> xs, int Function(T a, T b) compare) {
  final indexes = <(int, T)>[];
  var i = 0;
  for (final x in xs) {
    indexes.add((i++, x));
  }
  indexes.sort((a, b) {
    final c = compare(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return <T>[for (final x in indexes) x.$2];
}

/// Moyenne, médiane, 95e centile (rang le plus proche), maximum
/// (`criteres_moteur.stats`).
Map<String, Object?> kmStats(Iterable<double> xs) {
  final ys = List<double>.of(xs)..sort();
  final n = ys.length;
  if (n == 0) {
    return <String, Object?>{
      'n': 0,
      'moyenne': null,
      'mediane': null,
      'p95': null,
      'max': null,
    };
  }
  final med = n % 2 == 1 ? ys[n ~/ 2] : 0.5 * (ys[n ~/ 2 - 1] + ys[n ~/ 2]);
  return <String, Object?>{
    'n': n,
    'moyenne': kmSommeD(ys) / n,
    'mediane': med,
    'p95': ys[math.max(0, (0.95 * n).ceil() - 1)],
    'max': ys[n - 1],
  };
}

/// Copie normalisée d'une valeur JSON (comme un fichier relu) : objets
/// `Map<String, Object?>`, listes `List<Object?>`, nombres tels que
/// `jsonEncode` les écrit.
Object? kmNormaliserJson(Object? x) => jsonDecode(jsonEncode(x));

/// Texte canonique d'une valeur (clés triées, comme
/// `json.dumps(x, sort_keys=True)`) : sert aux comparaisons de journaux et
/// aux empreintes. NaN et infinis écrits comme Python (`NaN`, `Infinity`).
String kmTexteCanonique(Object? x) {
  final b = StringBuffer();
  _ecrireCanonique(b, x);
  return b.toString();
}

void _ecrireCanonique(StringBuffer b, Object? x) {
  if (x == null) {
    b.write('null');
  } else if (x is bool) {
    b.write(x ? 'true' : 'false');
  } else if (x is int) {
    b.write(x);
  } else if (x is double) {
    if (x.isNaN) {
      b.write('NaN');
    } else if (x.isInfinite) {
      b.write(x > 0 ? 'Infinity' : '-Infinity');
    } else {
      b.write(x);
    }
  } else if (x is String) {
    b.write(jsonEncode(x));
  } else if (x is Map<Object?, Object?>) {
    final cles = <String>[for (final k in x.keys) '$k']..sort();
    final parCle = <String, Object?>{
      for (final e in x.entries) '${e.key}': e.value,
    };
    b.write('{');
    var premier = true;
    for (final k in cles) {
      if (!premier) {
        b.write(', ');
      }
      premier = false;
      b
        ..write(jsonEncode(k))
        ..write(': ');
      _ecrireCanonique(b, parCle[k]);
    }
    b.write('}');
  } else if (x is Iterable<Object?>) {
    b.write('[');
    var premier = true;
    for (final v in x) {
      if (!premier) {
        b.write(', ');
      }
      premier = false;
      _ecrireCanonique(b, v);
    }
    b.write(']');
  } else {
    b.write(jsonEncode('$x'));
  }
}

/// Empreinte FNV-1a 64 bits (hexadécimal) des unités de code de [texte].
String kmEmpreinteTexte(String texte) {
  var h = -3750763034362895579; // 0xcbf29ce484222325
  const p = 0x100000001b3;
  for (final cu in texte.codeUnits) {
    h ^= cu;
    h *= p;
  }
  return BigInt.from(h).toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

// ----------------------------------------------------------------------
// Entrées du banc
// ----------------------------------------------------------------------

/// Entrées communes des mesures : catalogue, moteur de plan, paramètres de
/// Koach (défaut de modèle déjà surchargé s'il y a lieu), fiches des
/// exercices (`vecteurs_qualites_v1.json`, champ `exercices`) et profils
/// bruts du banc par clé. Les saisons de référence (`kmReferenceSeason`,
/// normalisées comme un fichier relu) sont calculées à la demande et
/// gardées.
final class KmBanc {
  /// Entrées du banc.
  KmBanc({
    required this.catalog,
    required this.plan,
    required this.parametres,
    required this.fiches,
    required this.profils,
  });

  /// Catalogue.
  final Catalog catalog;

  /// Moteur de plan (`kalis_plan`).
  final PlanEngine plan;

  /// Paramètres de Koach.
  final kc.Json parametres;

  /// Fiches des exercices (vecteurs de qualités).
  final Map<String, kc.Json> fiches;

  /// Profils bruts du banc, par clé.
  final Map<String, Map<String, Object?>> profils;

  final Map<String, List<kc.Json>> _saisons = <String, List<kc.Json>>{};

  /// Clés des profils, triées (`donnees.profils`).
  List<String> get cles => profils.keys.toList()..sort();

  /// Saisons de référence du profil [cle], une par scénario applicable
  /// (`donnees.saisons_reference`).
  List<kc.Json> saisonsReference(String cle) {
    final deja = _saisons[cle];
    if (deja != null) {
      return deja;
    }
    final json = profils[cle];
    if (json == null) {
      throw ArgumentError('profil inconnu : $cle');
    }
    final out = <kc.Json>[
      for (final s in SeasonScenario.values)
        if (seasonScenarioApplies(json, s))
          kc.jm(
            kmNormaliserJson(
              kmReferenceSeason(catalog, plan, json, s, truthSeeds: 0),
            ),
          ),
    ];
    _saisons[cle] = out;
    return out;
  }

  /// Codes des scénarios applicables au profil [cle], dans l'ordre de
  /// l'export (sans calculer les saisons).
  List<String> scenariosDe(String cle) {
    final json = profils[cle];
    if (json == null) {
      throw ArgumentError('profil inconnu : $cle');
    }
    return <String>[
      for (final s in SeasonScenario.values)
        if (seasonScenarioApplies(json, s)) s.code,
    ];
  }

  /// Saison [scenario] du profil [cle] (`criteres_moteur._saison`),
  /// tronquée à [semaines] si c'est moins que sa durée.
  kc.Json saison(String cle, String scenario, {int? semaines}) {
    kc.Json? s;
    for (final x in saisonsReference(cle)) {
      if (x['scenario'] == scenario) {
        s = x;
        break;
      }
    }
    if (s == null) {
      throw ArgumentError('saison absente : $cle, $scenario');
    }
    if (semaines != null && semaines < kc.ent(s['weeks'])) {
      s = Map<String, Object?>.of(s);
      s['weeks'] = semaines;
    }
    return s;
  }

  /// Validateur de sécurité de la saison [saison]
  /// (`securite_banc.constats_saison`).
  KmConstatsSaison constatsDe(kc.Json saison) =>
      KmConstatsSaison(catalog, profils[saison['key']! as String]!, saison);

  /// Trajectoires du jumeau des paramètres.
  int get trajectoiresParDefaut {
    final p = kc.dictOuVide(parametres['planification']);
    return p['trajectoires'] == null ? 1000 : kc.ent(p['trajectoires']);
  }

  /// Politique Koach (`politique_koach.PolitiqueKoach`), extensions
  /// [briques] montées dans l'ordre de la campagne.
  PolitiqueKoach politique({
    int graine = 0,
    List<String> briques = const <String>[],
    int? trajectoires,
  }) => PolitiqueKoach(
    catalog: catalog,
    parametres: parametres,
    fiches: fiches,
    graine: graine,
    briques: briques,
    trajectoires: trajectoires ?? trajectoiresParDefaut,
  );
}

/// Constats de sécurité de blocs pour une saison exportée
/// (`securite_banc.constats_saison(saison, infos, blocs)`) : même lecture
/// que `kmSafetyOfBlocks` (profil du banc du scénario, profil des moteurs,
/// blocs interrompus tronqués par `blockWeeks`, horizon `weeks` de la
/// saison), la saison du banc construite une fois.
final class KmConstatsSaison {
  /// Validateur de [saison] (profil brut [profil]).
  KmConstatsSaison(this.catalog, Map<String, Object?> profil, this.saison)
    : _season = KmSeason(
        catalog,
        profil,
        kmScenarioOf(saison['scenario']! as String),
      );

  /// Catalogue.
  final Catalog catalog;

  /// Saison exportée.
  final kc.Json saison;

  final KmSeason _season;

  /// Constats des blocs [blocs] (ceux de la saison sans argument), objets
  /// JSON de `Finding.toJson`.
  List<kc.Json> constats([List<Object?>? blocs]) {
    final blocksJson = blocs ?? kc.jl(saison['blocks']);
    final blocks = <ProgramBlock>[
      for (final b in blocksJson)
        ProgramBlock.fromJson(benchObject(b, 'blocks')),
    ];
    final bw = saison['blockWeeks'] == null
        ? null
        : <int>[for (final w in kc.jl(saison['blockWeeks'])) kc.ent(w)];
    final view = ProgramView(
      catalog,
      BenchProgram(
        bench: _season.bench,
        adapted: _season.adapted,
        request: PlanRequest(
          profile: _season.adapted.profile,
          seed: 0,
          startDate: benchStartDate,
          locks: const <PlanLock>[],
        ),
        blocks: kmServedBlocks(blocks, bw),
        horizonWeeks: kc.ent(saison['weeks']),
      ),
    );
    return <kc.Json>[
      for (final f in safetyFindings(view, _season.bench)) f.toJson(),
    ];
  }

  /// Validateur de la planification (`kc.Validateur`).
  List<kc.Json> validateur(List<kc.Json> blocs) => constats(blocs);
}

// ----------------------------------------------------------------------
// Politique déléguée (enveloppe)
// ----------------------------------------------------------------------

/// Politique qui délègue tout à [interne] ; les mesures en dérivent.
base class KmPolitiqueDeleguee extends KmPolitique {
  /// Enveloppe de [interne].
  KmPolitiqueDeleguee(this.interne);

  /// Politique Koach enveloppée.
  final PolitiqueKoach interne;

  @override
  String get nom => interne.nom;

  @override
  void debut(kc.Json saison, kc.Json profil, ExerciseBook livre) =>
      interne.debut(saison, profil, livre);

  @override
  void changementProfil(int semaine, kc.Json profil) =>
      interne.changementProfil(semaine, profil);

  @override
  void debutSemaine(int semaine) => interne.debutSemaine(semaine);

  @override
  void seanceManquee(int semaine, int simDay) =>
      interne.seanceManquee(semaine, simDay);

  @override
  kc.Json planifier(KmContexte ctx) => interne.planifier(ctx);

  @override
  kc.Json? prochaineSerie(
    KmContexte ctx,
    kc.Json item,
    int index,
    List<kc.Json> done,
  ) => interne.prochaineSerie(ctx, item, index, done);

  @override
  void cranChange(String exId, int change) => interne.cranChange(exId, change);

  @override
  void terminer(KmContexte ctx, kc.Json record) =>
      interne.terminer(ctx, record);

  @override
  List<double>? estimer(String exId, double n) => interne.estimer(exId, n);

  @override
  void finSemaine(int semaine, KmTour tour) =>
      interne.finSemaine(semaine, tour);

  @override
  void fin(KmTour tour) => interne.fin(tour);
}

// ----------------------------------------------------------------------
// 1. Temps
// ----------------------------------------------------------------------

/// Chronomètre fourni par `bin/` : durée (secondes) de l'exécution de
/// [action].
typedef KmChrono = double Function(void Function() action);

/// `Koach` qui chronomètre `observe` (séries) et `plan` (série, séance)
/// (`criteres_moteur.KoachChrono`). En plus de la référence : la mise à
/// jour après une série (`observe` de la ou des séries versées depuis le
/// dernier `plan` de série, plus ce `plan` de la série suivante).
class KoachChrono extends kc.Koach {
  /// Moteur chronométré par [chrono].
  KoachChrono(super.params, super.fiches, super.profil, this.chrono);

  /// Chronomètre.
  final KmChrono chrono;

  /// Durées (s) : `observe_serie`, `plan_serie`, `plan_seance`,
  /// `mise_a_jour_serie`.
  final Map<String, List<double>> temps = <String, List<double>>{
    'observe_serie': <double>[],
    'plan_serie': <double>[],
    'plan_seance': <double>[],
    'mise_a_jour_serie': <double>[],
  };

  double _attente = 0.0;
  int _enAttente = 0;

  void _solder() {
    if (_enAttente > 0) {
      temps['mise_a_jour_serie']!.add(_attente);
    }
    _attente = 0.0;
    _enAttente = 0;
  }

  @override
  void observe(kc.Json e) {
    if (e['type'] != 'serie') {
      _solder();
      super.observe(e);
      return;
    }
    final t = chrono(() => super.observe(e));
    temps['observe_serie']!.add(t);
    _attente += t;
    _enAttente++;
  }

  @override
  Object? plan(kc.Json c) {
    final cle = 'plan_${c['horizon']}';
    Object? r;
    final t = chrono(() {
      r = super.plan(c);
    });
    if (cle == 'plan_serie' || cle == 'plan_seance') {
      temps[cle]!.add(t);
    }
    if (cle == 'plan_serie') {
      if (_enAttente > 0) {
        temps['mise_a_jour_serie']!.add(_attente + t);
      }
      _attente = 0.0;
      _enAttente = 0;
    }
    return r;
  }
}

/// Politique Koach sans extension dont le moteur est remplacé, juste après
/// `debut`, par un [KoachChrono] (`criteres_moteur.PolitiqueChrono`) : le
/// journal déjà versé par `debut` est rejoué dans le nouveau moteur.
final class PolitiqueChrono extends KmPolitiqueDeleguee {
  /// Politique chronométrée.
  PolitiqueChrono(super.interne, this.chrono);

  /// Chronomètre.
  final KmChrono chrono;

  /// Moteur chronométré (après `debut`).
  late KoachChrono koach;

  @override
  void debut(kc.Json saison, kc.Json profil, ExerciseBook livre) {
    interne.debut(saison, profil, livre);
    final k = interne.koach;
    // Comme la référence : moteur neuf sans extension (la politique
    // chronométrée n'en monte aucune) ; ce que `debut` a déjà versé au
    // journal est rejoué.
    final c = KoachChrono(k.params, k.fiches, k.profil, chrono);
    for (final e in List<kc.Json>.of(k.journal)) {
      c.observe(e);
    }
    c.ciblesTentatives = Map<String, Object?>.of(k.ciblesTentatives);
    for (final l in c.temps.values) {
      l.clear();
    }
    interne.koach = c;
    koach = c;
  }
}

/// Planification de Koach qui chronomètre chaque replanification qui a
/// évalué des plans (`criteres_moteur.PlanificationChrono`).
class PlanificationChrono extends kc.Planification {
  /// Planification chronométrée par [chrono].
  PlanificationChrono(
    super.params,
    super.fiches,
    super.validateur,
    super.options,
    this.chrono,
  );

  /// Chronomètre.
  final KmChrono chrono;

  /// (durée en s, plans évalués) par replanification.
  final List<(double, int)> temps = <(double, int)>[];

  @override
  kc.Json replanifier(kc.Koach koach, int semaine) {
    late kc.Json ligne;
    final t = chrono(() {
      ligne = super.replanifier(koach, semaine);
    });
    if (kc.vrai(ligne['plans'])) {
      temps.add((t, kc.ent(ligne['plans'])));
    }
    return ligne;
  }
}

/// Temps d'un `observe` série et des `plan` (ms) sur une saison, puis des
/// replanifications (s) sur la même saison avec la planification
/// ([options] : surcharge de `params['planification']`)
/// (`criteres_moteur.mesurer_temps`).
///
/// Écart de mise en œuvre : la référence chronomètre les
/// replanifications pendant la saison ; ici la saison est simulée avec la
/// planification seule, puis son journal est rejoué dans un moteur neuf
/// dont la planification est chronométrée (mêmes replanifications, le
/// rejeu du journal étant exact, M7).
Map<String, Object?> kmMesurerTemps(
  KmBanc banc, {
  required KmChrono chrono,
  (String, String, String, int) saison = kmSaisonTemps,
  int? semaines,
  kc.Json? options,
}) {
  final (cle, scenario, verite, graine) = saison;
  final s = banc.saison(cle, scenario, semaines: semaines);
  final pol = PolitiqueChrono(banc.politique(), chrono);
  kmSimuler(banc.catalog, s, pol, verite, graine);
  final t = pol.koach.temps;
  final ms = <String, Map<String, Object?>>{
    for (final e in t.entries)
      e.key: kmStats(<double>[for (final x in e.value) 1000.0 * x]),
  };
  final traj = options == null || options['trajectoires'] == null
      ? null
      : kc.ent(options['trajectoires']);
  final pol2 = banc.politique(
    briques: const <String>['planification'],
    trajectoires: traj,
  );
  kmSimuler(banc.catalog, s, pol2, verite, graine);
  final k2 = pol2.koach;
  final cs = banc.constatsDe(s);
  final pc = PlanificationChrono(
    k2.params,
    k2.fiches,
    cs.validateur,
    options,
    chrono,
  );
  final kr = kc.Koach(k2.params, k2.fiches, k2.profil);
  kr.extensions.add(pc);
  for (final e in k2.journal) {
    kr.observe(kc.copieJson(e));
  }
  final replan = List<(double, int)>.of(pc.temps);
  final p = Map<String, Object?>.of(kc.jm(banc.parametres['planification']));
  p.addAll(options ?? const <String, Object?>{});
  final serie = ms['observe_serie']!;
  final maj = ms['mise_a_jour_serie']!;
  final rs = kmStats(<double>[for (final x in replan) x.$1]);
  final plans = <int>{for (final x in replan) x.$2}.toList()..sort();
  final serieMax = kc.dblOu(serie['max']);
  final majMax = kc.dblOu(maj['max']);
  final rsMax = kc.dblOu(rs['max']);
  return <String, Object?>{
    'saison': <String, Object?>{
      'profil': cle,
      'scenario': scenario,
      'verite': verite,
      'graine': graine,
      'semaines': s['weeks'],
    },
    'observe_serie_ms': serie,
    'plan_serie_ms': ms['plan_serie'],
    'plan_seance_ms': ms['plan_seance'],
    'mise_a_jour_serie_ms': maj,
    'replanification_s': rs,
    'replanification': <String, Object?>{
      'trajectoires': kc.ent(p['trajectoires']),
      'plans_max': kc.ent(p['plans_max']),
      'plans_evalues': plans,
      'validateur': true,
    },
    'critere_serie_ms': kmSeuilSerieMs,
    'critere_replanification_s': kmSeuilReplanificationS,
    'respecte_observe_seul':
        serieMax != null &&
        serieMax <= kmSeuilSerieMs &&
        rsMax != null &&
        rsMax <= kmSeuilReplanificationS,
    'respecte':
        majMax != null &&
        majMax <= kmSeuilSerieMs &&
        rsMax != null &&
        rsMax <= kmSeuilReplanificationS,
    'note':
        'VM Dart : mise à jour après une série = observe de la série + plan '
        'de la série suivante (critère) ; observe seul rapporté comme en KM1',
  };
}

// ----------------------------------------------------------------------
// 2. Mauvais jour isolé
// ----------------------------------------------------------------------

/// Politique Koach (sans extension) dont l'athlète est, le jour [jour], à
/// (1 − baisse) de sa capacité sur toute la séance
/// (`criteres_moteur.classe_mauvais_jour`) : l'effet de jour de chaque
/// exercice (`TruthExercise.day`, tiré par `beginExercise`) est décalé de
/// ln(1 − baisse). La référence dérive l'athlète ; ici le décalage est posé
/// au premier appel de `prochaineSerie` d'un item (le meneur l'appelle
/// juste après `beginExercise`, avant toute lecture de l'effet de jour).
/// Aucun autre tirage ne change.
final class PolitiqueMauvaisJour extends KmPolitiqueDeleguee {
  /// Mauvais jour [jour], baisse [baisse].
  PolitiqueMauvaisJour(super.interne, this.jour, double baisse)
    : decalage = math.log(1.0 - baisse);

  /// Jour du mauvais jour.
  final int jour;

  /// Décalage de l'effet de jour.
  final double decalage;

  @override
  kc.Json? prochaineSerie(
    KmContexte ctx,
    kc.Json item,
    int index,
    List<kc.Json> done,
  ) {
    if (index == 0 && ctx.simDay == jour) {
      final t = ctx.athlete.truthOf(item['exerciseId']! as String);
      if (t != null) {
        t.day += decalage;
      }
    }
    return interne.prochaineSerie(ctx, item, index, done);
  }
}

/// Saison simulée par Koach (sans extension) avec un mauvais jour isolé
/// (`criteres_moteur.simuler_mauvais_jour`).
KmTour kmSimulerMauvaisJour(
  KmBanc banc,
  kc.Json saison,
  String verite,
  int graine,
  int jour, {
  double baisse = kmMauvaisJour,
}) => kmSimuler(
  banc.catalog,
  saison,
  PolitiqueMauvaisJour(banc.politique(), jour, baisse),
  verite,
  graine,
);

/// Première séance de la seconde moitié de la saison où un mouvement
/// principal chargé a déjà au moins [seancesAvant] séances : (jour,
/// exercice) ou null (`criteres_moteur.choisir_jour`).
(int, String)? kmChoisirJour(
  kc.Json saison,
  KmTour tour, {
  int seancesAvant = kmSeancesAvant,
}) {
  final milieu = kc.divEnt(kc.ent(saison['weeks']), 2);
  for (final s in tour.sets) {
    if (kc.ent(s['week']) >= milieu &&
        kc.vrai(s['main']) &&
        s['mode'] == 'loaded' &&
        kc.ent(s['exerciseSession']) >= seancesAvant) {
      return (kc.ent(s['simDay']), s['exerciseId']! as String);
    }
  }
  return null;
}

/// Exercice → [(jour, e1RM estimé)] : une entrée par séance (dernière ligne
/// du jour), mouvements principaux chargés (`criteres_moteur._par_jour`).
Map<String, List<(int, double)>> kmParJour(KmTour tour) {
  final out = <String, List<(int, double)>>{};
  for (final e in tour.estimates) {
    if (!(kc.vrai(e['main']) && e['mode'] == 'loaded')) {
      continue;
    }
    final lst = out.putIfAbsent(
      e['exerciseId']! as String,
      () => <(int, double)>[],
    );
    final jour = kc.ent(e['simDay']);
    final cap = kc.dbl(e['capacity']);
    if (lst.isNotEmpty && lst.last.$1 == jour) {
      lst[lst.length - 1] = (jour, cap);
    } else {
      lst.add((jour, cap));
    }
  }
  return out;
}

/// Paires (sans, avec) : séance du jour [jour] puis les [n] − 1 séances
/// suivantes de l'exercice dans [base], lues le même jour dans [autre]
/// (`criteres_moteur._suite`).
(List<(double?, double?)>, List<int>) _suite(
  List<(int, double)> base,
  List<(int, double)> autre,
  int jour,
  int n,
) {
  final dAutre = <int, double>{for (final (j, v) in autre) j: v};
  final jours = <(int, double)>[
    for (final x in base)
      if (x.$1 >= jour) x,
  ].take(n).toList();
  final out = <(double?, double?)>[for (final (j, v) in jours) (v, dAutre[j])];
  while (out.length < n) {
    out.add((null, null));
  }
  return (out, <int>[for (final (j, _) in jours) j]);
}

List<double?> _ecarts(List<(double?, double?)> paires) => <double?>[
  for (final (x, y) in paires)
    if (x == null || y == null) null else y / x - 1.0,
];

/// Une saison, deux fois (telle quelle, puis avec le mauvais jour), les
/// deux saisons divergeant ensuite (mesure de KM1,
/// `criteres_moteur.mauvais_jour_saison`).
Map<String, Object?> kmMauvaisJourSaison(
  KmBanc banc,
  String cle,
  String verite,
  int graine, {
  String scenario = 'reference',
  double baisse = kmMauvaisJour,
}) {
  final s = banc.saison(cle, scenario);
  final base = kmSimuler(banc.catalog, s, banc.politique(), verite, graine);
  final choix = kmChoisirJour(s, base);
  final ligne = <String, Object?>{
    'profil': cle,
    'scenario': scenario,
    'verite': verite,
    'graine': graine,
  };
  if (choix == null) {
    ligne['jour'] = null;
    return ligne;
  }
  final (jour, exercice) = choix;
  final mauvais = kmSimulerMauvaisJour(
    banc,
    s,
    verite,
    graine,
    jour,
    baisse: baisse,
  );
  final eb = kmParJour(base);
  final em = kmParJour(mauvais);
  final ecarts = <String, Object?>{};
  final joursSuivants = <String, Object?>{};
  final n = kmHorizons.length;
  for (final ex in eb.keys.toList()..sort()) {
    final lst = eb[ex]!;
    if (!lst.any((x) => x.$1 == jour)) {
      continue;
    }
    final (paires, jours) = _suite(lst, em[ex] ?? <(int, double)>[], jour, n);
    ecarts[ex] = _ecarts(paires);
    joursSuivants[ex] = jours;
  }
  ligne.addAll(<String, Object?>{
    'jour': jour,
    'semaine': kc.divEnt(jour, 7),
    'exercice_declencheur': exercice,
    'ecarts': ecarts,
    'jours': joursSuivants,
  });
  return ligne;
}

/// (tour, moteur) d'une saison simulée par Koach sans extension, mauvais
/// jour [jour] s'il est donné (`criteres_moteur._saison_et_journal`).
(KmTour, kc.Koach) _saisonEtJournal(
  KmBanc banc,
  kc.Json saison,
  String verite,
  int graine, {
  int? jour,
  double baisse = kmMauvaisJour,
}) {
  final interne = banc.politique();
  final KmPolitique pol = jour == null
      ? interne
      : PolitiqueMauvaisJour(interne, jour, baisse);
  final tour = kmSimuler(banc.catalog, saison, pol, verite, graine);
  return (tour, interne.koach);
}

/// (i0, i1) : indices du `seance_debut` et du `seance_fin` de la séance du
/// jour [jour] dans [journal], ou null (`criteres_moteur._seance_du_jour`).
(int, int)? kmSeanceDuJour(List<kc.Json> journal, int jour) {
  int? i0;
  for (var i = 0; i < journal.length; i++) {
    final e = journal[i];
    if (e['type'] == 'seance_debut' && e['jour'] == jour) {
      i0 = i;
    } else if (e['type'] == 'seance_fin' && e['jour'] == jour && i0 != null) {
      return (i0, i);
    }
  }
  return null;
}

/// Rejoue [journal] dans un moteur neuf (paramètres, fiches et profil de
/// [koach]) : exercice → [(jour, e1RM estimé à frais)] à chaque fin de
/// séance où l'exercice a été entraîné
/// (`criteres_moteur._rejouer_en_suivant`).
Map<String, List<(int, double)>> kmRejouerEnSuivant(
  kc.Koach koach,
  List<kc.Json> journal,
  List<String> exercices,
) {
  final k = kc.Koach(koach.params, koach.fiches, koach.profil);
  final out = <String, List<(int, double)>>{
    for (final ex in exercices) ex: <(int, double)>[],
  };
  for (final e in journal) {
    k.observe(e);
    if (e['type'] == 'seance_fin') {
      final jour = kc.ent(e['jour']);
      for (final ex in exercices) {
        final t = k.modele.pistes[ex];
        if (t != null && t.jourSeance == jour) {
          out[ex]!.add((jour, math.exp(k.modele.capacite(ex)!.$1)));
        }
      }
    }
  }
  return out;
}

/// Contrefactuel apparié (C13.10.2.b,
/// `criteres_moteur.mauvais_jour_apparie_saison`) : journal de la saison
/// telle quelle jusqu'à la veille, séance du mauvais jour telle que Koach
/// l'a servie à l'athlète affaibli, puis les séances suivantes de la saison
/// telle quelle ; les deux journaux rejoués dans deux moteurs neufs.
Map<String, Object?> kmMauvaisJourAppareSaison(
  KmBanc banc,
  String cle,
  String verite,
  int graine, {
  String scenario = 'reference',
  double baisse = kmMauvaisJour,
}) {
  final s = banc.saison(cle, scenario);
  final (base, kBase) = _saisonEtJournal(banc, s, verite, graine);
  final choix = kmChoisirJour(s, base);
  final ligne = <String, Object?>{
    'profil': cle,
    'scenario': scenario,
    'verite': verite,
    'graine': graine,
  };
  if (choix == null) {
    ligne['jour'] = null;
    return ligne;
  }
  final (jour, exercice) = choix;
  final (_, kMauvais) = _saisonEtJournal(
    banc,
    s,
    verite,
    graine,
    jour: jour,
    baisse: baisse,
  );
  final jb = <kc.Json>[for (final e in kBase.journal) kc.copieJson(e)];
  final jmv = <kc.Json>[for (final e in kMauvais.journal) kc.copieJson(e)];
  final sb = kmSeanceDuJour(jb, jour);
  final sm = kmSeanceDuJour(jmv, jour);
  if (sb == null ||
      sm == null ||
      sb.$1 != sm.$1 ||
      kmTexteCanonique(jb.sublist(0, sb.$1)) !=
          kmTexteCanonique(jmv.sublist(0, sm.$1))) {
    ligne.addAll(<String, Object?>{
      'jour': jour,
      'erreur': 'journaux différents avant le mauvais jour',
    });
    return ligne;
  }
  final contrefactuel = <kc.Json>[
    ...jb.sublist(0, sb.$1),
    ...jmv.sublist(sm.$1, sm.$2 + 1),
    ...jb.sublist(sb.$2 + 1),
  ];
  final exercices = <String>[
    for (final e in kmParJour(base).entries)
      if (e.value.any((x) => x.$1 == jour)) e.key,
  ]..sort();
  final eb = kmRejouerEnSuivant(kBase, jb, exercices);
  final ec = kmRejouerEnSuivant(kBase, contrefactuel, exercices);
  final ecarts = <String, Object?>{};
  final joursSuivants = <String, Object?>{};
  final n = kmHorizons.length;
  for (final ex in exercices) {
    final (paires, jours) = _suite(eb[ex]!, ec[ex]!, jour, n);
    ecarts[ex] = _ecarts(paires);
    joursSuivants[ex] = jours;
  }
  ligne.addAll(<String, Object?>{
    'jour': jour,
    'semaine': kc.divEnt(jour, 7),
    'exercice_declencheur': exercice,
    'ecarts': ecarts,
    'jours': joursSuivants,
    'series_du_jour': <int>[sb.$2 - sb.$1, sm.$2 - sm.$1],
  });
  return ligne;
}

/// Saisons du mauvais jour : (profil, vérité, graine)
/// (`criteres_moteur.jobs_mauvais_jour`).
List<(String, String, int)> kmJobsMauvaisJour({
  List<String> cles = kmProfilsCharges,
  String verites = 'abc',
  List<int> graines = const <int>[0, 1],
}) => <(String, String, int)>[
  for (final cle in cles)
    for (final v in verites.split(''))
      for (final g in graines) (cle, v, g),
];

/// Agrégation des lignes [lignes] (résultats de
/// [kmMauvaisJourAppareSaison] ou [kmMauvaisJourSaison], dans l'ordre des
/// saisons) et des [plantages] (`criteres_moteur.mesurer_mauvais_jour`,
/// après l'exécution parallèle). [saisons] : nombre de saisons demandées.
Map<String, Object?> kmAgregerMauvaisJour(
  List<kc.Json> lignes,
  List<kc.Json> plantages,
  int saisons, {
  bool apparie = false,
  double baisse = kmMauvaisJour,
}) {
  final par = <String, List<double>>{for (final h in kmHorizons) h: <double>[]};
  for (final ligne in lignes) {
    for (final vals in kc.dictOuVide(ligne['ecarts']).values) {
      final vs = kc.jl(vals);
      for (var i = 0; i < kmHorizons.length && i < vs.length; i++) {
        final v = vs[i];
        if (v != null) {
          par[kmHorizons[i]]!.add(kc.dbl(v));
        }
      }
    }
  }
  final ecartAbs = <String, Map<String, Object?>>{
    for (final h in kmHorizons)
      h: kmStats(<double>[for (final v in par[h]!) v.abs()]),
  };
  final signe = <String, Object?>{
    for (final h in kmHorizons)
      h: par[h]!.isNotEmpty ? kmSommeD(par[h]!) / par[h]!.length : null,
  };
  final moyennes = <double>[
    for (final h in kmHorizons)
      if (ecartAbs[h]!['moyenne'] != null) kc.dbl(ecartAbs[h]!['moyenne']),
  ];
  final erreurs = lignes.where((x) => kc.vrai(x['erreur'])).length;
  return <String, Object?>{
    'baisse': baisse,
    'seances_avant': kmSeancesAvant,
    'saisons': saisons,
    'saisons_mesurees': lignes
        .where((x) => x['jour'] != null && !kc.vrai(x['erreur']))
        .length,
    'apparie': apparie,
    'erreurs': erreurs,
    'ecart_abs': ecartAbs,
    'ecart_signe_moyen': signe,
    'critere': kmSeuilMauvaisJour,
    'respecte':
        moyennes.isNotEmpty &&
        moyennes.every((m) => m < kmSeuilMauvaisJour) &&
        plantages.isEmpty &&
        erreurs == 0,
    'mesures': lignes,
    'plantages': plantages,
    'note':
        'écart relatif e1RM (mauvais jour / sans) − 1 par mouvement principal '
        'chargé entraîné le jour du mauvais jour ; même graine, même '
        'calendrier, même bilan de santé',
  };
}

// ----------------------------------------------------------------------
// 3. Déterminisme
// ----------------------------------------------------------------------

/// Koach avec la planification et les trois extensions
/// (`criteres_moteur.politique_complete`).
PolitiqueKoach kmPolitiqueComplete(
  KmBanc banc,
  int graine, {
  int? trajectoires,
}) => banc.politique(
  graine: graine,
  briques: kmBriquesCompletes,
  trajectoires: trajectoires,
);

/// Empreintes (FNV-1a 64 bits des textes canoniques) d'une exécution
/// complète (`criteres_moteur.empreinte` ; la référence prend le SHA-256).
Map<String, Object?> kmEmpreinte(
  KmBanc banc,
  String cle,
  String scenario,
  String verite,
  int graine, {
  int? semaines,
  int? trajectoires,
}) {
  final s = banc.saison(cle, scenario, semaines: semaines);
  final pol = kmPolitiqueComplete(banc, graine, trajectoires: trajectoires);
  final tour = kmSimuler(banc.catalog, s, pol, verite, graine);
  final textes = <String, String>{
    'servi': kmTexteCanonique(<Object?>[
      for (final (g, bi, wb, di, items) in tour.servi)
        <Object?>[g, bi, wb, di, items],
    ]),
    'series': kmTexteCanonique(tour.sets),
    'estimations': kmTexteCanonique(tour.estimates),
    'posterior': kmTexteCanonique(pol.koach.posterior()),
    'extensions': kmTexteCanonique(pol.etats()),
    'journal': kmTexteCanonique(pol.koach.journal),
  };
  final out = <String, Object?>{
    for (final e in textes.entries) e.key: kmEmpreinteTexte(e.value),
  };
  out['seances'] = tour.sessionsDone;
  out['series_n'] = tour.sets.length;
  return out;
}

/// Comparaison de deux empreintes calculées dans deux isolats
/// (`criteres_moteur.mesurer_determinisme`).
Map<String, Object?> kmDeterminisme(
  kc.Json e1,
  kc.Json e2, {
  (String, String, String, int) saison = kmSaisonDeterminisme,
  int? semaines,
  int? trajectoires,
}) {
  final (cle, scenario, verite, graine) = saison;
  final identiques = <String, Object?>{
    for (final k in e1.keys) k: kc.egalJson(e1[k], e2[k]),
  };
  return <String, Object?>{
    'saison': <String, Object?>{
      'profil': cle,
      'scenario': scenario,
      'verite': verite,
      'graine': graine,
      'semaines': semaines,
      'trajectoires': trajectoires,
    },
    'extensions': <String>[
      'Planification',
      'Surveillance',
      'ControleDual',
      'Adherence',
    ],
    'processus': 'deux isolats Dart',
    'identiques': identiques,
    'empreintes': <Object?>[e1, e2],
    'respecte': identiques.values.every((v) => v == true),
  };
}
