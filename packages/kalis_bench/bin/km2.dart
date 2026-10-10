// Campagne de mesure des critères du cahier KM sur le moteur Dart (lot
// KM2) : portage de l'exécution de `reference/banc/campagne.py`
// (`options_de`, `executer`, `campagne`, `caler_couverture`, `main`).
//
//   dart run bin/km2.dart [--profils tous|fichier|liste] [--scenarios tous|liste]
//       [--verites abc] [--graines N|a,b,c|a-b] [--trajectoires 1000]
//       [--coeurs 2] [--sortie criteres_km2.json] [--sans-planificateur]
//       [--defaut-modele x] [--rapide] [--temps-existants [fichier]]
//       [--semaines N] [--travail dossier] [--temoin dossier]
//       [--graines-temoin 16] [--sans-determinisme] [--caler-couverture]
//       [--partie i/n] [--parametres fichier] [--fiches fichier]
//       [--adversaires fichier] [--rejeu fichier]
//   dart run bin/km2.dart assembler --sortie criteres_km2.json <parties…|dossier>
//   dart run bin/km2.dart adversaires (--rejouer <adversaires_v1.json> | --chercher …)
//       (voir bin/km2_adversaire.dart)
//
// Sans --partie : la campagne entière, sortie JSON au schéma
// `kalis_bench/criteres_km2/1` (même schéma que criteres_km1.json, plus la
// section `temoin` et le déterminisme). Avec --partie i/n (i de 1 à n) :
// la i-ème part de la matrice (saisons d'indice ≡ i − 1 mod n, de même
// pour les saisons du témoin et du mauvais jour ; temps mesurés par la
// part 1 seule, avant toute autre tâche ; déterminisme par la part n),
// écrite dans --sortie (défaut `km2_partie_<i>_sur_<n>.json.gz`) ; la
// sous-commande `assembler` fusionne les parts et écrit les critères.
//
// Lecture des entrées comme bin/km1.dart (lancer depuis la racine de
// kalis_bench) : catalogue de kalis_core, profils du banc, paramètres et
// vecteurs de qualités de la référence (`../kalis_adapt/reference/`).
// Seul ce fichier lit le disque et l'horloge.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_bench/src/km/campagne.dart';
import 'package:kalis_bench/src/km/criteres_moteur.dart';
import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'common.dart';
import 'km2_adversaire.dart' show km2Adversaires;

const String _reference = '../kalis_adapt/reference';
const String _parametresDefaut = '$_reference/params/koach_params_v1.json';
const String _fichesDefaut = '$_reference/qualites/vecteurs_qualites_v1.json';
const String _adversairesDefaut =
    '$_reference/donnees/comparaison_adversaires.json';
const String _rejeuDefaut = '$_reference/donnees/rejeu_journal_agregats.json';
const String _tempsExistantsDefaut = '$_reference/donnees/criteres_moteur.json';
const String _schemaPartie = 'kalis_bench/km2_partie/1';

const String _usage =
    'usage : dart run bin/km2.dart [--profils tous|fichier|liste] '
    '[--scenarios tous|liste] [--verites abc] [--graines N|a,b,c|a-b] '
    '[--trajectoires N] [--coeurs N] [--sortie fichier] '
    '[--sans-planificateur] [--defaut-modele x] [--rapide] '
    '[--temps-existants [fichier]] [--semaines N] [--travail dossier] '
    '[--temoin dossier] [--graines-temoin N] [--sans-determinisme] '
    '[--caler-couverture] [--partie i/n] [--parametres fichier] '
    '[--fiches fichier] [--adversaires fichier] [--rejeu fichier]\n'
    '        dart run bin/km2.dart assembler --sortie fichier '
    '<parties…|dossier>';

Future<void> main(List<String> args) async {
  try {
    if (args.isNotEmpty && args.first == 'adversaires') {
      await km2Adversaires(args.sublist(1));
      return;
    }
    if (args.isNotEmpty && args.first == 'assembler') {
      await _assembler(args.sublist(1));
    } else {
      await _campagne(args);
    }
  } on FormatException catch (e) {
    stderr
      ..writeln('km2 : ${e.message}${e.source == null ? '' : ' (${e.source})'}')
      ..writeln(_usage);
    exitCode = 64;
  }
}

// ----------------------------------------------------------------------
// Options (`campagne.options_de`)
// ----------------------------------------------------------------------

final class _Options {
  _Options(List<String> args)
    : profils = option(args, '--profils') ?? 'tous',
      scenarios = option(args, '--scenarios') ?? 'tous',
      verites = option(args, '--verites') ?? 'abc',
      graines = _graines(option(args, '--graines') ?? '1'),
      grainesTexte = option(args, '--graines') ?? '1',
      rapide = args.contains('--rapide'),
      coeurs = int.parse(option(args, '--coeurs') ?? '2'),
      sansPlanificateur = args.contains('--sans-planificateur'),
      defautModele = option(args, '--defaut-modele') == null
          ? null
          : double.parse(option(args, '--defaut-modele')!),
      caler = args.contains('--caler-couverture'),
      semaines = option(args, '--semaines') == null
          ? null
          : int.parse(option(args, '--semaines')!),
      travail = option(args, '--travail'),
      temoinDossier = option(args, '--temoin'),
      grainesTemoin = int.parse(option(args, '--graines-temoin') ?? '16'),
      determinisme = !args.contains('--sans-determinisme'),
      parametres = option(args, '--parametres') ?? _parametresDefaut,
      fiches = option(args, '--fiches') ?? _fichesDefaut,
      adversaires = option(args, '--adversaires') ?? _adversairesDefaut,
      rejeu = option(args, '--rejeu') ?? _rejeuDefaut,
      tempsExistants = _tempsExistants(args),
      partie = _partie(option(args, '--partie')) {
    final t = option(args, '--trajectoires');
    trajectoires = t != null ? int.parse(t) : (rapide ? 100 : 1000);
    final (i, n) = partie;
    sortie =
        option(args, '--sortie') ??
        (n > 1 ? 'km2_partie_${i + 1}_sur_$n.json.gz' : 'criteres_km2.json');
    if (verites.isEmpty || verites.split('').any((v) => !'abc'.contains(v))) {
      throw FormatException('--verites : lettres parmi a, b, c', verites);
    }
  }

  final String profils;
  final String scenarios;
  final String verites;
  final List<int> graines;
  final String grainesTexte;
  final bool rapide;
  final int coeurs;
  final bool sansPlanificateur;
  final double? defautModele;
  final bool caler;
  final int? semaines;
  final String? travail;
  final String? temoinDossier;
  final int grainesTemoin;
  final bool determinisme;
  final String parametres;
  final String fiches;
  final String adversaires;
  final String rejeu;
  final String? tempsExistants;
  final (int, int) partie;
  late final int trajectoires;
  late final String sortie;

  KmOptionsCampagne get campagne => KmOptionsCampagne(
    sansPlanificateur: sansPlanificateur,
    trajectoires: trajectoires,
    defautModele: defautModele,
    semaines: semaines,
    rapide: rapide,
  );

  /// Graines telles que la configuration les publie : un entier pour la
  /// forme `N` (comme la référence), la liste sinon.
  Object get grainesConfig {
    final n = int.tryParse(grainesTexte);
    return n ?? graines;
  }
}

List<int> _graines(String texte) {
  final n = int.tryParse(texte);
  if (n != null) {
    return <int>[for (var g = 0; g < n; g++) g];
  }
  final tiret = RegExp(r'^(\d+)-(\d+)$').firstMatch(texte);
  if (tiret != null) {
    final a = int.parse(tiret.group(1)!);
    final b = int.parse(tiret.group(2)!);
    return <int>[for (var g = a; g <= b; g++) g];
  }
  return <int>[
    for (final x in texte.split(','))
      if (x.trim().isNotEmpty) int.parse(x.trim()),
  ];
}

(int, int) _partie(String? texte) {
  if (texte == null) {
    return (0, 1);
  }
  final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(texte);
  if (m == null) {
    throw FormatException('--partie i/n attendu', texte);
  }
  final i = int.parse(m.group(1)!);
  final n = int.parse(m.group(2)!);
  if (n < 1 || i < 1 || i > n) {
    throw FormatException('--partie : 1 <= i <= n', texte);
  }
  return (i - 1, n);
}

String? _tempsExistants(List<String> args) {
  final at = args.indexOf('--temps-existants');
  if (at < 0) {
    return null;
  }
  if (at + 1 < args.length && !args[at + 1].startsWith('--')) {
    return args[at + 1];
  }
  return _tempsExistantsDefaut;
}

/// Profils de la campagne (`campagne.lire_profils`).
List<String> _lireProfils(String arg, List<String> tous) {
  if (arg == 'tous') {
    return tous;
  }
  final f = File(arg);
  final texte = f.existsSync() ? f.readAsStringSync() : arg;
  return <String>[
    for (final c in texte.replaceAll('\n', ',').split(','))
      if (c.trim().isNotEmpty) c.trim(),
  ];
}

// ----------------------------------------------------------------------
// Entrées
// ----------------------------------------------------------------------

Map<String, Map<String, Object?>> _profilsBruts() =>
    <String, Map<String, Object?>>{
      for (final j in readSeasonJson()) j['key']! as String: j,
    };

List<String> _scenariosDe(Map<String, Object?> json) => <String>[
  for (final s in SeasonScenario.values)
    if (seasonScenarioApplies(json, s)) s.code,
];

Object? _lireJson(String chemin) {
  final f = File(chemin);
  if (!f.existsSync()) {
    return null;
  }
  try {
    final bytes = f.readAsBytesSync();
    final texte = utf8.decode(
      chemin.endsWith('.gz') ? gzip.decode(bytes) : bytes,
    );
    return _depuisJsonSur(jsonDecode(texte));
  } on FormatException {
    return null;
  }
}

void _ecrireJson(String chemin, Object? valeur, {bool indente = false}) {
  final f = File(chemin);
  f.parent.createSync(recursive: true);
  final texte = indente
      ? '${const JsonEncoder.withIndent(' ').convert(kmTrierCles(valeur))}\n'
      : jsonEncode(_versJsonSur(valeur));
  final tmp = File('$chemin.tmp$pid');
  if (chemin.endsWith('.gz')) {
    tmp.writeAsBytesSync(gzip.encode(utf8.encode(texte)));
  } else {
    tmp.writeAsStringSync(texte);
  }
  tmp.renameSync(chemin);
}

/// NaN et infinis en marqueurs (JSON n'en a pas), relus par
/// [_depuisJsonSur] ; enregistrements en listes.
Object? _versJsonSur(Object? x) {
  if (x is double) {
    if (x.isNaN) {
      return '__nan__';
    }
    if (x.isInfinite) {
      return x > 0 ? '__inf__' : '__-inf__';
    }
    return x;
  }
  if (x is Map<Object?, Object?>) {
    return <String, Object?>{
      for (final e in x.entries) '${e.key}': _versJsonSur(e.value),
    };
  }
  if (x is Iterable<Object?>) {
    return <Object?>[for (final v in x) _versJsonSur(v)];
  }
  if (x is (int, int, int, int, List<kc.Json>)) {
    return <Object?>[x.$1, x.$2, x.$3, x.$4, _versJsonSur(x.$5)];
  }
  return x;
}

Object? _depuisJsonSur(Object? x) {
  if (x == '__nan__') {
    return double.nan;
  }
  if (x == '__inf__') {
    return double.infinity;
  }
  if (x == '__-inf__') {
    return double.negativeInfinity;
  }
  if (x is Map<String, Object?>) {
    return <String, Object?>{
      for (final e in x.entries) e.key: _depuisJsonSur(e.value),
    };
  }
  if (x is List<Object?>) {
    return <Object?>[for (final v in x) _depuisJsonSur(v)];
  }
  return x;
}

// ----------------------------------------------------------------------
// Empreintes (SHA-256, comme la référence)
// ----------------------------------------------------------------------

const List<int> _k256 = <int>[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const int _m32 = 0xffffffff;

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & _m32;

List<int> _sha256(List<int> message) {
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final bitLen = message.length * 8;
  final p = <int>[...message, 0x80];
  while (p.length % 64 != 56) {
    p.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    p.add((bitLen >> (8 * i)) & 0xff);
  }
  final w = List<int>.filled(64, 0);
  for (var c = 0; c < p.length; c += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] =
          (p[c + 4 * i] << 24) |
          (p[c + 4 * i + 1] << 16) |
          (p[c + 4 * i + 2] << 8) |
          p[c + 4 * i + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _m32;
    }
    var a = h[0];
    var b = h[1];
    var cc = h[2];
    var d = h[3];
    var e = h[4];
    var f = h[5];
    var g = h[6];
    var hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & _m32) & g);
      final t1 = (hh + s1 + ch + _k256[i] + w[i]) & _m32;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & cc) ^ (b & cc);
      final t2 = (s0 + maj) & _m32;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _m32;
      d = cc;
      cc = b;
      b = a;
      a = (t1 + t2) & _m32;
    }
    final v = <int>[a, b, cc, d, e, f, g, hh];
    for (var i = 0; i < 8; i++) {
      h[i] = (h[i] + v[i]) & _m32;
    }
  }
  return <int>[
    for (final x in h) ...<int>[
      (x >> 24) & 0xff,
      (x >> 16) & 0xff,
      (x >> 8) & 0xff,
      x & 0xff,
    ],
  ];
}

String _hex(List<int> octets) =>
    octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();

/// SHA-256 du fichier de paramètres, des sources du moteur
/// (`kalis_adapt/lib/src/koach/*.dart`) et du banc Koach
/// (`kalis_bench/lib/src/km/*.dart`) (`campagne.empreinte_sources`).
String _empreinteSources(String parametres) {
  final fichiers = <String>[parametres];
  for (final d in const <String>[
    '../kalis_adapt/lib/src/koach',
    'lib/src/km',
  ]) {
    final dir = Directory(d);
    if (!dir.existsSync()) {
      continue;
    }
    fichiers.addAll(
      <String>[
        for (final f in dir.listSync())
          if (f is File && f.path.endsWith('.dart')) f.path,
      ]..sort(),
    );
  }
  final tout = <int>[];
  for (final chemin in fichiers) {
    tout
      ..addAll(utf8.encode(chemin))
      ..addAll(_sha256(File(chemin).readAsBytesSync()));
  }
  return _hex(_sha256(tout));
}

// ----------------------------------------------------------------------
// Isolats de travail
// ----------------------------------------------------------------------

/// Entrées d'un isolat (chargées une fois).
final class _Contexte {
  _Contexte(Map<String, Object?> config)
    : opts = KmOptionsCampagne.fromJson(kc.jm(config['options'])),
      grainesTemoin = kc.ent(config['graines_temoin']) {
    final catalog = Catalog.fromJsonBytes(
      gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
    );
    final base = kc.jm(
      jsonDecode(File(config['parametres']! as String).readAsStringSync()),
    );
    final vecteurs = kc.jm(
      kc.jm(
        jsonDecode(File(config['fiches']! as String).readAsStringSync()),
      )['exercices'],
    );
    banc = KmBanc(
      catalog: catalog,
      plan: KalisPlan(),
      parametres: kmParametres(base, opts.defautModele),
      fiches: <String, kc.Json>{
        for (final e in vecteurs.entries) e.key: kc.jm(e.value),
      },
      profils: _profilsBruts(),
    );
  }

  final KmOptionsCampagne opts;
  final int grainesTemoin;
  late final KmBanc banc;
}

List<String> _traceCourte(StackTrace st, int n) {
  final l = <String>[
    for (final x in st.toString().trim().split('\n'))
      if (x.trim().isNotEmpty) x.trim(),
  ];
  return l.length > n ? l.sublist(0, n) : l;
}

String _erreurCourte(Object e) {
  final t = '$e';
  return '${e.runtimeType}: ${t.length > 300 ? t.substring(0, 300) : t}';
}

double _chrono(void Function() action) {
  final w = Stopwatch()..start();
  action();
  w.stop();
  return w.elapsedMicroseconds / 1e6;
}

/// Une tâche dans un isolat : saison de la matrice, saison du témoin,
/// mauvais jour, empreinte.
Object? _executer(_Contexte c, Map<String, Object?> t) {
  final type = t['type'];
  if (type == 'saison') {
    final job = kmJobDe(t['job']);
    final w = Stopwatch()..start();
    Map<String, Object?> r;
    try {
      r = kmMesurerSaison(c.banc, job, c.opts);
    } catch (e, st) {
      r = <String, Object?>{
        'saison': <Object?>[job.$1, job.$2, job.$3, job.$4],
        'plantage': _erreurCourte(e),
        'trace': _traceCourte(st, 7),
      };
    }
    r['duree_s'] = w.elapsedMicroseconds / 1e6;
    return r;
  }
  if (type == 'temoin') {
    final cle = t['cle']! as String;
    final scen = t['scenario']! as String;
    return kmNormaliserJson(
      kmWitnessSeason(
        c.banc.catalog,
        KalisPlan(),
        c.banc.profils[cle]!,
        kmScenarioOf(scen),
        seeds: c.grainesTemoin,
      ),
    );
  }
  if (type == 'mj') {
    final cle = t['cle']! as String;
    final v = t['verite']! as String;
    final g = kc.ent(t['graine']);
    final apparie = t['apparie'] == true;
    try {
      return apparie
          ? kmMauvaisJourAppareSaison(c.banc, cle, v, g)
          : kmMauvaisJourSaison(c.banc, cle, v, g);
    } catch (e, st) {
      final trace = '${_erreurCourte(e)}\n$st';
      return <String, Object?>{
        'plantage': <String, Object?>{
          'appel': apparie
              ? 'mauvais_jour_apparie_saison'
              : 'mauvais_jour_saison',
          'args': <Object?>[cle, v, g],
          'trace': trace.length > 800
              ? trace.substring(trace.length - 800)
              : trace,
        },
      };
    }
  }
  if (type == 'empreinte') {
    final (cle, scen, v, g) = kmSaisonDeterminisme;
    try {
      return kmEmpreinte(
        c.banc,
        cle,
        scen,
        v,
        g,
        semaines: t['semaines'] == null ? null : kc.ent(t['semaines']),
        trajectoires: t['trajectoires'] == null
            ? null
            : kc.ent(t['trajectoires']),
      );
    } catch (e, st) {
      return <String, Object?>{
        'plantage': _erreurCourte(e),
        'trace': _traceCourte(st, 7),
      };
    }
  }
  throw StateError('tâche inconnue : $type');
}

void _travailleur(List<Object?> args) {
  final vers = args[0]! as SendPort;
  final config = args[1]! as Map<String, Object?>;
  final rp = ReceivePort();
  vers.send(rp.sendPort);
  _Contexte? ctx;
  rp.listen((Object? m) {
    if (m == null) {
      rp.close();
      return;
    }
    final t = m as Map<String, Object?>;
    final c = ctx ??= _Contexte(config);
    vers.send(<String, Object?>{
      'id': t['id'],
      'resultat': _versJsonSur(_executer(c, t)),
    });
  });
}

/// Exécute [taches] sur [coeurs] isolats (entrées chargées une fois par
/// isolat) ; résultats dans l'ordre des tâches.
Future<List<Object?>> _executerTaches(
  List<Map<String, Object?>> taches,
  Map<String, Object?> config,
  int coeurs, {
  void Function(int faites, Object? resultat)? auFil,
}) async {
  final resultats = List<Object?>.filled(taches.length, null);
  if (taches.isEmpty) {
    return resultats;
  }
  final n = math.max(1, math.min(coeurs, taches.length));
  var prochaine = 0;
  var faites = 0;
  final fin = Completer<void>();
  for (var w = 0; w < n; w++) {
    final rp = ReceivePort();
    final sortie = ReceivePort();
    final erreurs = ReceivePort();
    SendPort? vers;
    int? enCours;
    void envoyer() {
      if (prochaine < taches.length) {
        final id = prochaine++;
        enCours = id;
        vers!.send(<String, Object?>{...taches[id], 'id': id});
      } else {
        enCours = null;
        vers!.send(null);
      }
    }

    rp.listen((Object? m) {
      if (m is SendPort) {
        vers = m;
        envoyer();
        return;
      }
      final r = m! as Map<String, Object?>;
      final id = r['id']! as int;
      final res = _depuisJsonSur(r['resultat']);
      resultats[id] = res;
      faites++;
      auFil?.call(faites, res);
      if (faites == taches.length && !fin.isCompleted) {
        fin.complete();
      }
      envoyer();
    });
    erreurs.listen((Object? e) {
      if (!fin.isCompleted) {
        fin.completeError(StateError('isolat : $e'));
      }
    });
    sortie.listen((Object? _) {
      rp.close();
      sortie.close();
      erreurs.close();
      if (enCours != null && !fin.isCompleted) {
        fin.completeError(
          StateError('isolat arrêté pendant la tâche $enCours'),
        );
      }
    });
    await Isolate.spawn<List<Object?>>(
      _travailleur,
      <Object?>[rp.sendPort, config],
      onExit: sortie.sendPort,
      onError: erreurs.sendPort,
    );
  }
  await fin.future;
  return resultats;
}

Map<String, Object?> _config(_Options o) => <String, Object?>{
  'options': o.campagne.toJson(),
  'graines_temoin': o.grainesTemoin,
  'parametres': o.parametres,
  'fiches': o.fiches,
};

// ----------------------------------------------------------------------
// Matrice
// ----------------------------------------------------------------------

final class _Matrice {
  _Matrice(this.profils, this.scenarios, this.jobs, this.paires, this.jobsMj);

  final List<String> profils;
  final List<String> scenarios;
  final List<KmJob> jobs;
  final List<(String, String)> paires;
  final List<(String, String, int)> jobsMj;
}

_Matrice _matrice(
  Map<String, Map<String, Object?>> bruts,
  List<String> profils,
  List<String> scenarios,
  String verites,
  List<int> graines,
  bool rapide,
) {
  for (final p in profils) {
    if (!bruts.containsKey(p)) {
      throw FormatException('profil inconnu', p);
    }
  }
  final jobs = kmMatrice(
    profils,
    (cle) => _scenariosDe(bruts[cle]!),
    scenarios,
    verites,
    graines,
  );
  final paires = <(String, String)>{for (final j in jobs) (j.$1, j.$2)}.toList()
    ..sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });
  final jobsMj = kmJobsMauvaisJourCampagne(profils, verites, graines, rapide);
  return _Matrice(profils, scenarios, jobs, paires, jobsMj);
}

Map<String, Object?> _configuration(
  _Options o,
  _Matrice m,
) => <String, Object?>{
  'profils': m.profils,
  'scenarios': m.scenarios,
  'verites': o.verites,
  'graines': o.grainesConfig,
  'trajectoires': o.trajectoires,
  'planificateur': !o.sansPlanificateur,
  'extensions': o.sansPlanificateur
      ? <String>[]
      : <String>['Planification', 'Surveillance', 'ControleDual', 'Adherence'],
  'defaut_modele_sd': o.defautModele,
  'rapide': o.rapide,
  'semaines': o.semaines,
  'graines_temoin': o.grainesTemoin,
  'temoin': o.temoinDossier == null
      ? 'kmWitnessSeason (calculé)'
      : 'lu dans ${o.temoinDossier}',
  'moteur': 'kalis_adapt 1.0.0 (Dart)',
};

// ----------------------------------------------------------------------
// Campagne (une part ou entière)
// ----------------------------------------------------------------------

Future<void> _campagne(List<String> args) async {
  final o = _Options(args);
  final bruts = _profilsBruts();
  final tous = bruts.keys.toList()..sort();
  if (o.caler) {
    await _calerCouverture(o, bruts, tous);
    return;
  }
  final total = Stopwatch()..start();
  final profils = _lireProfils(o.profils, tous);
  final scenarios = o.scenarios == 'tous'
      ? <String>['tous']
      : o.scenarios.split(',');
  final m = _matrice(bruts, profils, scenarios, o.verites, o.graines, o.rapide);
  final (ip, np) = o.partie;
  final sources = _empreinteSources(o.parametres);
  final config = _config(o);

  // Temps (part 1 seule), mesurés avant toute autre tâche, isolat unique.
  Map<String, Object?>? temps;
  String? sourceTemps;
  if (ip == 0) {
    (temps, sourceTemps) = _mesureTemps(o, config);
  }

  // Saisons de la matrice : cache du dossier de travail, puis calcul.
  final mesJobs = <KmJob>[
    for (var i = 0; i < m.jobs.length; i++)
      if (i % np == ip) m.jobs[i],
  ];
  String? dossier;
  if (o.travail != null) {
    final texte = kmTexteCanonique(<String, Object?>{
      'sources': sources,
      'config': o.campagne.config(),
    });
    dossier =
        '${o.travail}/${_hex(_sha256(utf8.encode(texte))).substring(0, 16)}';
    Directory(dossier).createSync(recursive: true);
  }
  final resultats = <String, Object?>{};
  final aFaire = <KmJob>[];
  for (final j in mesJobs) {
    final r = dossier == null
        ? null
        : _lireJson('$dossier/${kmNomJob(j)}.json');
    if (r is Map<String, Object?> &&
        kc.egalJson(r['saison'], <Object?>[j.$1, j.$2, j.$3, j.$4])) {
      resultats[kmNomJob(j)] = r;
    } else {
      aFaire.add(j);
    }
  }
  final paires = o.temoinDossier != null
      ? <(String, String)>[]
      : <(String, String)>[
          for (var i = 0; i < m.paires.length; i++)
            if (i % np == ip) m.paires[i],
        ];
  final mj = <(int, (String, String, int))>[
    for (var i = 0; i < m.jobsMj.length; i++)
      if (i % np == ip) (i, m.jobsMj[i]),
  ];
  final taches = <Map<String, Object?>>[
    for (final j in aFaire)
      <String, Object?>{
        'type': 'saison',
        'job': <Object?>[j.$1, j.$2, j.$3, j.$4],
      },
    for (final (cle, scen) in paires)
      <String, Object?>{'type': 'temoin', 'cle': cle, 'scenario': scen},
    for (final apparie in const <bool>[true, false])
      for (final (_, (cle, v, g)) in mj)
        <String, Object?>{
          'type': 'mj',
          'cle': cle,
          'verite': v,
          'graine': g,
          'apparie': apparie,
        },
    if (o.determinisme && ip == np - 1)
      for (var k = 0; k < 2; k++)
        <String, Object?>{
          'type': 'empreinte',
          'semaines': o.rapide ? 6 : null,
          'trajectoires': o.rapide ? 200 : null,
        },
  ];
  stdout.writeln(
    'campagne KM2${np > 1 ? ' (part ${ip + 1}/$np)' : ''} : '
    '${m.jobs.length} saisons dans la matrice, ${mesJobs.length} pour cette '
    'part, ${mesJobs.length - aFaire.length} en cache, ${aFaire.length} à '
    'calculer ; ${paires.length} saisons du témoin ; ${mj.length} × 2 '
    'mauvais jours ; ${taches.length} tâches sur ${o.coeurs} isolat(s)',
  );
  final t0 = Stopwatch()..start();
  var plantees = 0;
  final pas = taches.length > 100
      ? 50
      : math.max(1, math.min(50, taches.length ~/ 4));
  final sortieTaches = await _executerTaches(
    taches,
    config,
    o.coeurs,
    auFil: (faites, r) {
      if (r is Map<String, Object?> && r.containsKey('plantage')) {
        plantees++;
      }
      if (faites % pas == 0 || faites == taches.length) {
        final dt = t0.elapsedMilliseconds / 1000;
        stdout.writeln(
          '  $faites/${taches.length} tâches ($plantees plantée(s)) — '
          '${dt.toStringAsFixed(0)} s, reste ~'
          '${(dt / faites * (taches.length - faites)).toStringAsFixed(0)} s',
        );
      }
    },
  );
  var k = 0;
  for (final j in aFaire) {
    final r = kc.jm(sortieTaches[k++]);
    resultats[kmNomJob(j)] = r;
    if (dossier != null) {
      _ecrireJson('$dossier/${kmNomJob(j)}.json', r);
    }
  }
  final temoins = <String, Object?>{};
  for (final (cle, scen) in paires) {
    temoins['$cle|$scen'] = sortieTaches[k++];
  }
  final mauvais = <String, Object?>{
    'apparie': <String, Object?>{},
    'divergent': <String, Object?>{},
  };
  for (final cle in const <String>['apparie', 'divergent']) {
    for (final (i, _) in mj) {
      kc.jm(mauvais[cle])['$i'] = sortieTaches[k++];
    }
  }
  List<Object?>? empreintes;
  if (o.determinisme && ip == np - 1) {
    empreintes = <Object?>[sortieTaches[k++], sortieTaches[k++]];
  }
  final partie = <String, Object?>{
    'schema': _schemaPartie,
    'partie': <int>[ip + 1, np],
    'configuration': _configuration(o, m),
    'options': _versJsonSur(config),
    'empreinte_sources': sources,
    'saisons': resultats,
    'temoin': temoins,
    'mauvais_jour': mauvais,
    'temps': temps,
    'source_temps': sourceTemps,
    'empreintes': empreintes,
  };
  if (np > 1) {
    _ecrireJson(o.sortie, partie);
    stdout.writeln(
      'part ${ip + 1}/$np écrite dans ${o.sortie} '
      '(${total.elapsed.inSeconds} s).',
    );
    return;
  }
  final s = _assemblerParties(<Map<String, Object?>>[partie], o);
  _ecrireJson(o.sortie, s, indente: true);
  stdout
    ..writeln(kmResume(s))
    ..writeln('durée : ${total.elapsed.inSeconds} s ; sortie ${o.sortie}');
}

/// Critère 8 (`campagne.mesure_temps`) : fichier existant (lu), ou mesure
/// sur la VM Dart (`kmMesurerTemps`) dans l'isolat principal, seul.
(Map<String, Object?>, String) _mesureTemps(
  _Options o,
  Map<String, Object?> config,
) {
  final existant = o.tempsExistants;
  if (existant != null) {
    final d = _lireJson(existant);
    if (d is Map<String, Object?> && kc.vrai(d['temps'])) {
      return (kc.jm(d['temps']), '$existant (lu, non remesuré)');
    }
  }
  stdout.writeln('critère 8 (temps) ...');
  final c = _Contexte(config);
  final rapide = o.rapide;
  final t = kmMesurerTemps(
    c.banc,
    chrono: _chrono,
    semaines: rapide ? 4 : null,
    options: <String, Object?>{'trajectoires': o.trajectoires},
  );
  return (
    t,
    rapide
        ? 'mesuré sur la VM Dart (kmMesurerTemps, saison tronquée à 4 semaines)'
        : 'mesuré sur la VM Dart (kmMesurerTemps)',
  );
}

// ----------------------------------------------------------------------
// Assemblage
// ----------------------------------------------------------------------

Future<void> _assembler(List<String> args) async {
  final sortie = option(args, '--sortie') ?? 'criteres_km2.json';
  final chemins = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (const <String>[
      '--sortie',
      '--temoin',
      '--adversaires',
      '--rejeu',
    ].contains(args[i])) {
      i++;
      continue;
    }
    if (args[i].startsWith('--')) {
      continue;
    }
    final d = Directory(args[i]);
    if (d.existsSync()) {
      chemins.addAll(
        <String>[
          for (final f in d.listSync())
            if (f is File &&
                RegExp(
                  r'km2_partie_\d+_sur_\d+\.json(\.gz)?$',
                ).hasMatch(f.path))
              f.path,
        ]..sort(),
      );
    } else {
      chemins.add(args[i]);
    }
  }
  if (chemins.isEmpty) {
    throw const FormatException('assembler : aucune part');
  }
  final parties = <Map<String, Object?>>[];
  for (final c in chemins) {
    final p = _lireJson(c);
    if (p is! Map<String, Object?> || p['schema'] != _schemaPartie) {
      throw FormatException('part illisible', c);
    }
    parties.add(p);
  }
  // Options de la campagne relues de la première part (fichiers lus à
  // l'assemblage remplaçables par la ligne de commande).
  final o = _Options(<String>[
    for (final f in const <String>['--temoin', '--adversaires', '--rejeu'])
      if (option(args, f) != null) ...<String>[f, option(args, f)!],
    ..._argsDe(parties.first),
  ]);
  final s = _assemblerParties(parties, o);
  _ecrireJson(sortie, s, indente: true);
  stdout
    ..writeln(kmResume(s))
    ..writeln('${parties.length} part(s) assemblée(s) ; sortie $sortie');
}

/// Arguments équivalents à la configuration d'une part (pour relire les
/// options à l'assemblage).
List<String> _argsDe(Map<String, Object?> partie) {
  final c = kc.jm(partie['configuration']);
  final cfg = kc.jm(partie['options']);
  final opts = kc.jm(cfg['options']);
  final graines = c['graines'];
  return <String>[
    '--profils',
    kc.jl(c['profils']).join(','),
    '--scenarios',
    kc.jl(c['scenarios']).join(','),
    '--verites',
    c['verites']! as String,
    '--graines',
    // Liste : toujours une virgule (une liste d'un élément n'est pas un
    // nombre de graines).
    graines is int ? '$graines' : '${kc.jl(graines).join(',')},',
    '--trajectoires',
    '${c['trajectoires']}',
    '--graines-temoin',
    '${c['graines_temoin']}',
    '--parametres',
    cfg['parametres']! as String,
    '--fiches',
    cfg['fiches']! as String,
    if (opts['sans_planificateur'] == true) '--sans-planificateur',
    if (opts['rapide'] == true) '--rapide',
    if (opts['defaut_modele'] != null) ...<String>[
      '--defaut-modele',
      '${opts['defaut_modele']}',
    ],
    if (opts['semaines'] != null) ...<String>[
      '--semaines',
      '${opts['semaines']}',
    ],
    if (c['temoin'] is String &&
        (c['temoin']! as String).startsWith('lu dans ')) ...<String>[
      '--temoin',
      (c['temoin']! as String).substring('lu dans '.length),
    ],
  ];
}

Map<String, Object?> _assemblerParties(
  List<Map<String, Object?>> parties,
  _Options o,
) {
  final bruts = _profilsBruts();
  final config0 = kc.jm(parties.first['configuration']);
  final np = kc.ent(kc.jl(parties.first['partie'])[1]);
  final vues = <int>{};
  for (final p in parties) {
    if (!kc.egalJson(p['configuration'], config0)) {
      throw const FormatException('parts de configurations différentes');
    }
    if (kc.ent(kc.jl(p['partie'])[1]) != np) {
      throw const FormatException('parts de découpages différents');
    }
    vues.add(kc.ent(kc.jl(p['partie'])[0]));
  }
  final manquantes = <int>[
    for (var i = 1; i <= np; i++)
      if (!vues.contains(i)) i,
  ];
  if (manquantes.isNotEmpty) {
    throw FormatException('parts manquantes : $manquantes');
  }
  final profils = <String>[
    for (final x in kc.jl(config0['profils'])) x! as String,
  ];
  final scenarios = <String>[
    for (final x in kc.jl(config0['scenarios'])) x! as String,
  ];
  final m = _matrice(bruts, profils, scenarios, o.verites, o.graines, o.rapide);
  final resultats = <String, kc.Json>{};
  final temoinsParPaire = <String, kc.Json>{};
  final mjA = <int, kc.Json>{};
  final mjD = <int, kc.Json>{};
  Map<String, Object?>? temps;
  String? sourceTemps;
  List<Object?>? empreintes;
  for (final p in parties) {
    for (final e in kc.jm(p['saisons']).entries) {
      resultats[e.key] = kc.jm(e.value);
    }
    for (final e in kc.jm(p['temoin']).entries) {
      temoinsParPaire[e.key] = kc.jm(e.value);
    }
    final mj = kc.jm(p['mauvais_jour']);
    for (final e in kc.jm(mj['apparie']).entries) {
      mjA[int.parse(e.key)] = kc.jm(e.value);
    }
    for (final e in kc.jm(mj['divergent']).entries) {
      mjD[int.parse(e.key)] = kc.jm(e.value);
    }
    if (p['temps'] != null) {
      temps = kc.jm(p['temps']);
      sourceTemps = p['source_temps'] as String?;
    }
    if (p['empreintes'] != null) {
      empreintes = kc.jl(p['empreintes']);
    }
  }
  final absents = <String>[
    for (final j in m.jobs)
      if (!resultats.containsKey(kmNomJob(j))) kmNomJob(j),
  ];
  if (absents.isNotEmpty) {
    throw FormatException(
      'saisons sans résultat : ${absents.length} (${absents.first}…)',
    );
  }
  if (temps == null) {
    throw const FormatException('temps absents (part 1 manquante ?)');
  }
  // Témoin : par profil, ses saisons (`donnees.temoin`).
  final temoins = <String, List<kc.Json>?>{};
  final cles = <String>{for (final j in m.jobs) j.$1};
  for (final cle in cles) {
    if (o.temoinDossier != null) {
      final x =
          _lireJson('${o.temoinDossier}/$cle.json.gz') ??
          _lireJson('${o.temoinDossier}/$cle.json');
      temoins[cle] = x is List<Object?>
          ? <kc.Json>[for (final s in x) kc.jm(s)]
          : null;
    } else {
      temoins[cle] = <kc.Json>[
        for (final e in temoinsParPaire.entries)
          if (e.key.startsWith('$cle|')) e.value,
      ];
    }
  }
  final temoin = kmChargerTemoin(m.jobs, temoins);
  Object? niveauDe(String cle, String scen) {
    final b = bruts[cle];
    if (b == null || !_scenariosDe(b).contains(scen)) {
      return null;
    }
    return BenchProfile.fromJson(b).level.index;
  }

  // Critère 2 : lignes dans l'ordre des saisons, plantages à part.
  kc.Json mesureMj(Map<int, kc.Json> lignes, bool apparie) {
    final ok = <kc.Json>[];
    final ko = <kc.Json>[];
    for (var i = 0; i < m.jobsMj.length; i++) {
      final l = lignes[i];
      if (l == null) {
        throw FormatException('mauvais jour sans résultat : saison $i');
      }
      if (l.containsKey('plantage')) {
        ko.add(kc.jm(l['plantage']));
      } else {
        ok.add(l);
      }
    }
    return kmResumeMauvaisJour(
      kmAgregerMauvaisJour(ok, ko, m.jobsMj.length, apparie: apparie),
      m.jobsMj.length,
    );
  }

  final base = kc.jm(jsonDecode(File(o.parametres).readAsStringSync()));
  final parametres = kmParametres(base, o.defautModele);
  Map<String, Object?>? determinisme;
  if (empreintes != null && empreintes.length == 2) {
    final e1 = kc.jm(empreintes[0]);
    final e2 = kc.jm(empreintes[1]);
    if (e1.containsKey('plantage') || e2.containsKey('plantage')) {
      determinisme = <String, Object?>{
        'respecte': false,
        'plantage': e1['plantage'] ?? e2['plantage'],
        'trace': e1['trace'] ?? e2['trace'],
      };
    } else {
      determinisme = kmDeterminisme(
        e1,
        e2,
        semaines: o.rapide ? 6 : null,
        trajectoires: o.rapide ? 200 : null,
      );
    }
  }
  final adv = _lireJson(o.adversaires);
  final rej = _lireJson(o.rejeu);
  return kmCampagne(
    opts: o.campagne,
    parametres: parametres,
    configuration: config0,
    empreinteSources: parties.first['empreinte_sources']! as String,
    jobs: m.jobs,
    resultats: resultats,
    temoin: temoin,
    niveauDe: niveauDe,
    mauvaisJour: mesureMj(mjA, true),
    mauvaisJourDivergent: mesureMj(mjD, false),
    temps: temps,
    sourceTemps: sourceTemps ?? '',
    adversaires: adv is Map<String, Object?> ? adv : null,
    rejeu: rej is Map<String, Object?> ? rej : null,
    determinisme: determinisme,
  );
}

// ----------------------------------------------------------------------
// Calage de la couverture (`campagne.caler_couverture`)
// ----------------------------------------------------------------------

Future<void> _calerCouverture(
  _Options o,
  Map<String, Map<String, Object?>> bruts,
  List<String> tous,
) async {
  final set9 =
      Platform.environment['KM2_SET9'] ??
      Platform.environment['KM1_SET9'] ??
      '';
  final profils = _lireProfils(
    set9.isNotEmpty && File(set9).existsSync() ? set9 : o.profils,
    tous,
  );
  final jobs = kmMatrice(
    profils,
    (cle) => _scenariosDe(bruts[cle]!),
    const <String>['reference'],
    o.verites,
    const <int>[0, 1, 2, 3],
  );
  const cible = 0.90;
  const iterations = 7;
  final essais = <double, double?>{};
  Future<double?> cov(double x) async {
    final cfg = _config(o);
    final opts = Map<String, Object?>.of(kc.jm(cfg['options']));
    opts['defaut_modele'] = x;
    cfg['options'] = opts;
    final r = await _executerTaches(
      <Map<String, Object?>>[
        for (final j in jobs)
          <String, Object?>{
            'type': 'saison',
            'job': <Object?>[j.$1, j.$2, j.$3, j.$4],
          },
      ],
      cfg,
      o.coeurs,
    );
    final c = kmCouverture(<kc.Json>[for (final x in r) kc.jm(x)]);
    essais[x] = c;
    stdout.writeln(
      '  defaut_modele_sd = ${x.toStringAsFixed(5)} -> couverture '
      '${c == null ? 'nan' : c.toStringAsFixed(4)}',
    );
    return c;
  }

  bool atteint(double? c) => c != null && c >= cible;
  double? resultat;
  var lo = 0.0;
  if (atteint(await cov(lo))) {
    resultat = lo;
  } else {
    var hi = 0.02;
    var introuvable = false;
    while (!atteint(await cov(hi))) {
      lo = hi;
      hi *= 2;
      if (hi > 0.64) {
        introuvable = true;
        break;
      }
    }
    if (!introuvable) {
      for (var i = 0; i < iterations; i++) {
        final mid = 0.5 * (lo + hi);
        if (atteint(await cov(mid))) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      resultat = hi;
    }
  }
  stdout.writeln(
    'defaut_modele_sd calé : '
    '${resultat == null ? 'introuvable (> 0,64)' : resultat.toStringAsFixed(5)}'
    ' (couverture >= 0,90 ; fichier de paramètres non modifié)',
  );
  for (final x in essais.keys.toList()..sort()) {
    final c = essais[x];
    stdout.writeln(
      '  ${x.toStringAsFixed(5)} -> ${c == null ? 'nan' : c.toStringAsFixed(4)}',
    );
  }
}
