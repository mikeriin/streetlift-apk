// Banc Koach du lot KM2 (`lib/src/km/meneur.dart`,
// `lib/src/km/politique_koach.dart`) contre la référence Python
// (`kalis_adapt/reference/banc/meneur.py`, politique complète de
// `campagne.py`) : chaque fixture de `test/fixtures/km2/` (écrite par
// `kalis_adapt/reference/fixtures/generer_banc_km2.py`) est rejouée avec
// `kmSimuler` + `PolitiqueKoach` (mêmes paramètres) et comparée à 1e-9
// relatif (`|a - b| <= 1e-9 · max(1, |a|, |b|)`), les entiers des lignes
// `tour.sets` / `tour.estimates` devant rester des entiers.
//
// La saison de `kmReferenceSeason` est d'abord comparée, à l'identique, à
// celle que Python a lue (`kalis_adapt/reference/donnees/reference/`).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_bench/src/km/meneur.dart';
import 'package:kalis_bench/src/km/politique_koach.dart';
import 'package:kalis_core/kalis_core.dart' show Catalog;
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan;
import 'package:test/test.dart';

import 'support.dart';

/// Référence Python de kalis_adapt (paquet voisin).
const String _reference = '../kalis_adapt/reference';

/// Fixtures du lot KM2.
const String _dossier = 'test/fixtures/km2';

/// Tolérance relative de la comparaison.
const double _tolerance = 1e-9;

/// Écarts rapportés au plus, par comparaison.
const int _ecartsMax = 25;

/// Valeur JSON d'un fichier (décompressé si son nom finit par `.gz`).
Object? _lireJson(String chemin) {
  final bytes = File(chemin).readAsBytesSync();
  return jsonDecode(
    utf8.decode(chemin.endsWith('.gz') ? gzip.decode(bytes) : bytes),
  );
}

/// Valeur JSON pure, codée comme la référence Python : non-finis en
/// chaînes, ensembles triés, itérables en listes.
Object? _pur(Object? x) {
  if (x == null || x is bool || x is String || x is int) {
    return x;
  }
  if (x is double) {
    if (x.isNaN) {
      return 'nan';
    }
    if (x.isInfinite) {
      return x > 0 ? 'inf' : '-inf';
    }
    return x;
  }
  if (x is Map<Object?, Object?>) {
    return <String, Object?>{
      for (final e in x.entries) '${e.key}': _pur(e.value),
    };
  }
  if (x is Set<Object?>) {
    final l = <Object?>[for (final v in x) _pur(v)];
    l.sort((a, b) => '$a'.compareTo('$b'));
    return l;
  }
  if (x is Iterable<Object?>) {
    return <Object?>[for (final v in x) _pur(v)];
  }
  throw ArgumentError.value(x, 'x', 'valeur non codable (${x.runtimeType})');
}

String _court(Object? v) {
  final s = jsonEncode(v);
  return s.length > 160 ? '${s.substring(0, 160)}…' : s;
}

/// Champs des lignes du meneur lus sur la vérité simulée : la vérité Python
/// (`banc/verite.py`) y laisse un entier quand une capacité est bornée
/// (`clamp(x, 2, 60)` rend la borne entière), la vérité Dart un double
/// (`clampDouble`) ; seul le type diffère, jamais la valeur.
const Set<String> _champsVerite = <String>{
  'capacity',
  'truth',
  'truthOperational',
};

/// Premiers écarts entre [attendu] (référence Python) et [obtenu] (Dart),
/// avec leur chemin. [typesStricts] : un entier attendu doit être un entier
/// (et un flottant un flottant), sauf sous les clés de [typesSouples]. Les
/// clés de [ignorer] ne sont pas comparées.
List<String> kmEcarts(
  Object? attendu,
  Object? obtenu, {
  double tolerance = _tolerance,
  bool typesStricts = false,
  Set<String> typesSouples = _champsVerite,
  Set<String> ignorer = const <String>{},
  int max = _ecartsMax,
}) {
  final out = <String>[];
  void comparer(Object? a, Object? b, String chemin, [bool souple = false]) {
    if (out.length >= max) {
      return;
    }
    if (a is num && b is num) {
      if (typesStricts && !souple && ((a is int) != (b is int))) {
        out.add(
          '$chemin : ${a is int ? 'entier' : 'flottant'} $a attendu, '
          '${b is int ? 'entier' : 'flottant'} $b obtenu',
        );
        return;
      }
      final d = (a - b).abs();
      var m = 1.0;
      if (a.abs() > m) {
        m = a.abs().toDouble();
      }
      if (b.abs() > m) {
        m = b.abs().toDouble();
      }
      if (!(d <= tolerance * m)) {
        out.add('$chemin : $a attendu, $b obtenu (écart $d)');
      }
      return;
    }
    if (a is Map<String, Object?> && b is Map<String, Object?>) {
      for (final k in a.keys) {
        if (ignorer.contains(k)) {
          continue;
        }
        if (!b.containsKey(k)) {
          out.add('$chemin.$k : absent (attendu ${_court(a[k])})');
          if (out.length >= max) {
            return;
          }
        }
      }
      for (final k in b.keys) {
        if (ignorer.contains(k)) {
          continue;
        }
        if (!a.containsKey(k)) {
          out.add('$chemin.$k : en trop (${_court(b[k])})');
          if (out.length >= max) {
            return;
          }
        }
      }
      for (final k in a.keys) {
        if (!ignorer.contains(k) && b.containsKey(k)) {
          comparer(a[k], b[k], '$chemin.$k', typesSouples.contains(k));
        }
      }
      return;
    }
    if (a is List<Object?> && b is List<Object?>) {
      if (a.length != b.length) {
        out.add('$chemin : ${a.length} éléments attendus, ${b.length} obtenus');
      }
      final n = a.length < b.length ? a.length : b.length;
      for (var i = 0; i < n; i++) {
        comparer(a[i], b[i], '$chemin[$i]');
        if (out.length >= max) {
          return;
        }
      }
      return;
    }
    if (a != b) {
      out.add('$chemin : ${_court(a)} attendu, ${_court(b)} obtenu');
    }
  }

  comparer(attendu, obtenu, r'$');
  return out;
}

void _pareil(List<String> ecarts, String quoi) {
  expect(
    ecarts,
    isEmpty,
    reason:
        '$quoi : premiers écarts (attendu = Python, obtenu = Dart)\n'
        '${ecarts.join('\n')}',
  );
}

/// Saison de référence que Python a lue : blocs d'un scénario qui renvoie
/// à la saison de base (`blocksAs`) recopiés comme `donnees.saisons_reference`.
Map<String, Object?> _saisonPython(String cle, String scenario) {
  final saisons =
      _lireJson('$_reference/donnees/reference/$cle.json.gz')! as List<Object?>;
  Map<String, Object?>? base;
  Map<String, Object?>? cible;
  for (final s0 in saisons) {
    final s = s0! as Map<String, Object?>;
    if (s['scenario'] == 'reference') {
      base = s;
    }
    if (s['scenario'] == scenario) {
      cible = s;
    }
  }
  final out = Map<String, Object?>.of(cible!);
  if (out['blocks'] == null && out['blocksAs'] != null) {
    out['blocks'] = base!['blocks'];
  }
  out.remove('blocksAs');
  return out;
}

/// Paramètres de Koach (fichier décodé).
Map<String, Object?> _parametres() =>
    readJsonObject('$_reference/params/koach_params_v1.json');

/// Fiches de Koach (`vecteurs_qualites_v1.json`, champ `exercices`).
Map<String, Map<String, Object?>> _fiches() {
  final v = readJsonObject('$_reference/qualites/vecteurs_qualites_v1.json');
  return <String, Map<String, Object?>>{
    for (final e in (v['exercices']! as Map<String, Object?>).entries)
      e.key: e.value! as Map<String, Object?>,
  };
}

void main() {
  final fichiers = <String>[
    for (final f in Directory(_dossier).listSync())
      if (f is File &&
          (f.path.endsWith('.json') || f.path.endsWith('.json.gz')))
        f.path,
  ]..sort();

  test('fixtures du lot KM2 présentes', () {
    expect(fichiers, isNotEmpty);
  });

  for (final chemin in fichiers) {
    final nom = chemin.split('/').last.split('.').first;
    group(nom, () {
      late Catalog catalog;
      late Map<String, Object?> attendu;
      late Map<String, Object?> config;
      late Map<String, Object?> saisonDart;
      late Map<String, Object?> saisonPython;
      late Map<String, Object?> saison;
      late KmTour tour;
      late PolitiqueKoach politique;
      late Map<String, Object?> obtenu;

      setUpAll(() {
        catalog = loadCatalog();
        attendu = _lireJson(chemin)! as Map<String, Object?>;
        config = attendu['config']! as Map<String, Object?>;
        final cle = config['cle']! as String;
        final scenario = config['scenario']! as String;
        saisonDart =
            jsonDecode(
                  jsonEncode(
                    kmReferenceSeason(
                      catalog,
                      KalisPlan(),
                      readJsonObject('profiles/$cle.json'),
                      kmScenarioOf(scenario),
                    ),
                  ),
                )
                as Map<String, Object?>;
        saisonPython = _saisonPython(cle, scenario);
        saison = Map<String, Object?>.of(saisonDart);
        final semaines = config['semaines'];
        if (semaines != null && (semaines as int) < (saison['weeks']! as int)) {
          saison['weeks'] = semaines;
        }
        final graine = config['graine']! as int;
        politique = PolitiqueKoach(
          catalog: catalog,
          parametres: _parametres(),
          fiches: _fiches(),
          graine: graine,
          briques: <String>[
            for (final b in config['briques']! as List<Object?>) b! as String,
          ],
          trajectoires: config['trajectoires']! as int,
        );
        tour = kmSimuler(
          catalog,
          saison,
          politique,
          config['verite']! as String,
          graine,
        );
        obtenu =
            _pur(<String, Object?>{
                  'tour': <String, Object?>{
                    'sets': tour.sets,
                    'estimates': tour.estimates,
                    'servi': <Object?>[
                      for (final (g, bi, wb, di, items) in tour.servi)
                        <Object?>[g, bi, wb, di, items],
                    ],
                    'sessions_planned': tour.sessionsPlanned,
                    'sessions_done': tour.sessionsDone,
                    'pain_aggravations': tour.painAggravations,
                    'pain_flares': tour.painFlares,
                    'endurance_overuse': tour.enduranceOveruse,
                    'worst_run_spike': tour.worstRunSpike,
                    'gain': tour.gain,
                    'cap0': tour.cap0,
                    'cap_fin': tour.capFin,
                    'extra': tour.extra,
                  },
                  'previsions': politique.previsions,
                  'posterior': politique.koach.posterior(),
                  'journaux': politique.journaux(),
                  'etats': politique.etats(),
                })!
                as Map<String, Object?>;
      });

      Map<String, Object?> tourAttendu() =>
          attendu['tour']! as Map<String, Object?>;
      Map<String, Object?> tourObtenu() =>
          obtenu['tour']! as Map<String, Object?>;

      test('kmReferenceSeason redonne la saison lue par Python', () {
        _pareil(
          kmEcarts(
            saisonPython,
            saisonDart,
            tolerance: 0,
            typesStricts: true,
            typesSouples: const <String>{},
          ),
          'saison de référence',
        );
        final s = attendu['saison']! as Map<String, Object?>;
        expect(saison['weeks'], s['weeks']);
        expect((saison['sessions']! as List<Object?>).length, s['sessions']);
      });

      test('tour.sets : clés, valeurs et types (hors traces)', () {
        _pareil(
          kmEcarts(
            tourAttendu()['sets'],
            tourObtenu()['sets'],
            typesStricts: true,
            ignorer: const <String>{'trace'},
          ),
          'tour.sets',
        );
      });

      test('tour.sets : traces des cibles', () {
        List<Object?> traces(Object? sets) => <Object?>[
          for (final s in sets! as List<Object?>)
            (s! as Map<String, Object?>)['trace'],
        ];
        _pareil(
          kmEcarts(traces(tourAttendu()['sets']), traces(tourObtenu()['sets'])),
          'tour.sets[].trace',
        );
      });

      test('tour.estimates : clés, valeurs et types', () {
        _pareil(
          kmEcarts(
            tourAttendu()['estimates'],
            tourObtenu()['estimates'],
            typesStricts: true,
          ),
          'tour.estimates',
        );
      });

      test('séances servies', () {
        _pareil(
          kmEcarts(tourAttendu()['servi'], tourObtenu()['servi']),
          'tour.servi',
        );
      });

      test('compteurs, gains et capacités', () {
        final a = Map<String, Object?>.of(tourAttendu())
          ..remove('sets')
          ..remove('estimates')
          ..remove('servi');
        final b = Map<String, Object?>.of(tourObtenu())
          ..remove('sets')
          ..remove('estimates')
          ..remove('servi');
        _pareil(kmEcarts(a, b), 'compteurs');
      });

      test('prévisions de la planification', () {
        _pareil(
          kmEcarts(attendu['previsions'], obtenu['previsions']),
          'previsions',
        );
      });

      test('journal du moteur : longueur et types', () {
        // La façade Dart verse en plus les événements `reference` (début)
        // et `cibles` (changements de profil).
        final types = <Object?>[
          for (final e in politique.koach.journal)
            if (e['type'] != 'reference' && e['type'] != 'cibles') e['type'],
        ];
        final j = attendu['journal_moteur']! as Map<String, Object?>;
        expect(types.length, j['longueur']);
        _pareil(kmEcarts(j['types'], types), 'journal_moteur.types');
        expect(politique.koach.journal.first['type'], 'reference');
      });

      test('posterior final', () {
        _pareil(
          kmEcarts(attendu['posterior'], obtenu['posterior']),
          'posterior',
        );
      });

      test('journaux des extensions du banc', () {
        _pareil(kmEcarts(attendu['journaux'], obtenu['journaux']), 'journaux');
      });

      test('états des extensions', () {
        _pareil(kmEcarts(attendu['etats'], obtenu['etats']), 'etats');
      });
    }, timeout: const Timeout(Duration(minutes: 10)));
  }

  test('comparateur : chemins, tolérance et types', () {
    expect(
      kmEcarts(
        <String, Object?>{'a': 1.0},
        <String, Object?>{'a': 1.0 + 1e-12},
      ),
      isEmpty,
    );
    expect(
      kmEcarts(<String, Object?>{'a': 1.0}, <String, Object?>{'a': 1.001}),
      hasLength(1),
    );
    expect(
      kmEcarts(<Object?>[1], <Object?>[1.0], typesStricts: true).single,
      contains(r'$[0]'),
    );
    expect(kmEcarts(<Object?>[1], <Object?>[1.0]), isEmpty);
    expect(
      kmEcarts(
        <String, Object?>{
          'x': <Object?>[1, 2],
        },
        <String, Object?>{
          'x': <Object?>[1],
          'y': null,
        },
      ),
      hasLength(2),
    );
  });
}
