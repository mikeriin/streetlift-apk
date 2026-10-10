// Banc adversarial de Koach sur le moteur Dart (lot KM2) : exécution de
// `lib/src/km/adversaire.dart`, portage de `reference/banc/adversaire.py`
// (`chercher`, `comparer`, `main`).
//
//   dart run bin/km2_adversaire.dart --rejouer <adversaires_v1.json>
//       [--temoin-lu adversaires_temoin.json.gz] [--sans-rejeu]
//       [--sortie comparaison_adversaires_km2.json] [--coeurs 2]
//       [--briques aucune|toutes|liste] [--trajectoires N]
//       [--reference comparaison_adversaires.json]
//       [--parametres fichier] [--fiches fichier]
//   dart run bin/km2_adversaire.dart --chercher [--budget 300] [--graines 2]
//       [--objectif a|b] [--n-pires 32] [--temoins 8] [--profils a,b,…]
//       [--scenario reference] [--modeles abc] [--graine 20261009]
//       [--coeurs 2] [--sortie adversaires_km2.json]
//       [--rapport comparaison_adversaires_km2.json]
//       [--sortie-temoin adversaires_km2_temoin.json.gz]
//       [--entree-dart adversaires.json] [--briques …] [--trajectoires N]
//       [--parametres fichier] [--fiches fichier]
//   (ou `dart run bin/km2.dart adversaires …`, mêmes options)
//
// --rejouer : les adversaires d'un fichier lisible (`adversaires_v1.json`
// de KM1, ou la sortie d'une recherche) sont rejoués par Koach (Dart) et par
// le témoin 0.3.1 (`kmAdversaryRun`, même exécution ; `--temoin-lu` relit
// une sortie existante du témoin à la place) ; sortie au schéma de
// `comparaison_adversaires.json` (critère 7 : pire cas de Koach >= pire cas
// du témoin). `--sans-rejeu` : mesures de Koach stockées dans le fichier
// (`rejouer_koach=False` de la référence).
//
// --chercher : nouvelle recherche (μ+λ) contre Koach (Dart), mêmes aléas que
// la référence ; puis le témoin est mesuré sur chaque adversaire retenu (une
// saison par graine) et comparé. Sorties : fichier lisible (schéma de
// `adversaires_v1.json`), comparaison (schéma de
// `comparaison_adversaires.json`), sortie brute du témoin (schéma de
// `adversaires_temoin.json.gz`), et à la demande l'entrée de l'outil Dart
// (`adversaires.json`).
//
// Koach est monté SANS extension par défaut (`--briques aucune`), comme
// `PolitiqueKoach()` de `adversaire.py` (mesure publiée de KM1) ;
// `--briques toutes` monte la planification, la surveillance, le contrôle
// dual et l'adhérence (graine du banc = graine de la saison).
//
// Lancer depuis la racine de kalis_bench (comme bin/km2.dart). Seul ce
// fichier lit le disque et l'horloge.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_bench/src/km/adversaire.dart';
import 'package:kalis_bench/src/km/criteres_moteur.dart';
import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'common.dart';

const String _reference = '../kalis_adapt/reference';
const String _parametresDefaut = '$_reference/params/koach_params_v1.json';
const String _fichesDefaut = '$_reference/qualites/vecteurs_qualites_v1.json';
const String _comparaisonKm1 =
    '$_reference/donnees/comparaison_adversaires.json';

const String _usage =
    'usage : dart run bin/km2_adversaire.dart --rejouer <adversaires.json> '
    '[--temoin-lu fichier] [--sans-rejeu] [--sortie fichier] [--coeurs N] '
    '[--briques aucune|toutes|liste] [--trajectoires N] '
    '[--reference fichier] [--parametres fichier] [--fiches fichier]\n'
    '        dart run bin/km2_adversaire.dart --chercher [--budget N] '
    '[--graines N] [--objectif a|b] [--n-pires N] [--temoins N] '
    '[--profils liste] [--scenario s] [--modeles abc] [--graine N] '
    '[--coeurs N] [--sortie fichier] [--rapport fichier] '
    '[--sortie-temoin fichier] [--entree-dart fichier] [--briques …] '
    '[--trajectoires N] [--parametres fichier] [--fiches fichier]';

Future<void> main(List<String> args) => km2Adversaires(args);

/// Point d'entrée (aussi `bin/km2.dart adversaires …`).
Future<void> km2Adversaires(List<String> args) async {
  try {
    final rejouer = option(args, '--rejouer');
    final chercher = args.contains('--chercher');
    if ((rejouer == null) == !chercher) {
      throw const FormatException('--rejouer <fichier> ou --chercher');
    }
    if (chercher) {
      await _chercher(args);
    } else {
      await _rejouer(args, rejouer!);
    }
  } on FormatException catch (e) {
    stderr
      ..writeln(
        'km2 adversaires : ${e.message}'
        '${e.source == null ? '' : ' (${e.source})'}',
      )
      ..writeln(_usage);
    exitCode = 64;
  } on ArgumentError catch (e) {
    stderr
      ..writeln('km2 adversaires : ${e.message}')
      ..writeln(_usage);
    exitCode = 64;
  }
}

// ----------------------------------------------------------------------
// Options communes
// ----------------------------------------------------------------------

int _entier(List<String> args, String nom, int defaut) {
  final t = option(args, nom);
  if (t == null) {
    return defaut;
  }
  final v = int.tryParse(t);
  if (v == null) {
    throw FormatException('$nom : entier attendu', t);
  }
  return v;
}

List<String> _briques(List<String> args) {
  final t = option(args, '--briques') ?? 'aucune';
  if (t == 'aucune') {
    return const <String>[];
  }
  if (t == 'toutes') {
    return kmBriquesCompletes;
  }
  final demandees = <String>[
    for (final x in t.split(','))
      if (x.trim().isNotEmpty) x.trim(),
  ];
  for (final b in demandees) {
    if (!kmBriquesCompletes.contains(b)) {
      throw FormatException(
        '--briques : aucune, toutes ou parmi ${kmBriquesCompletes.join(',')}',
        b,
      );
    }
  }
  return <String>[
    for (final b in kmBriquesCompletes)
      if (demandees.contains(b)) b,
  ];
}

Map<String, Object?> _config(List<String> args) => <String, Object?>{
  'parametres': option(args, '--parametres') ?? _parametresDefaut,
  'fiches': option(args, '--fiches') ?? _fichesDefaut,
};

Map<String, Object?> _moteur(
  List<String> briques,
  int? trajectoires,
  String temoin,
) => <String, Object?>{
  'koach': 'package:kalis_adapt/koach.dart (Dart)',
  'politique': 'PolitiqueKoach (kmSimuler)',
  'briques': briques,
  'trajectoires': trajectoires,
  'temoin': temoin,
};

// ----------------------------------------------------------------------
// Fichiers
// ----------------------------------------------------------------------

Object? _lireJson(String chemin) {
  final f = File(chemin);
  if (!f.existsSync()) {
    throw FormatException('fichier absent', chemin);
  }
  final bytes = f.readAsBytesSync();
  return jsonDecode(
    utf8.decode(chemin.endsWith('.gz') ? gzip.decode(bytes) : bytes),
  );
}

void _ecrireTexte(String chemin, String texte) {
  final f = File(chemin);
  f.parent.createSync(recursive: true);
  final tmp = File('$chemin.tmp$pid');
  if (chemin.endsWith('.gz')) {
    tmp.writeAsBytesSync(gzip.encode(utf8.encode(texte)));
  } else {
    tmp.writeAsStringSync(texte);
  }
  tmp.renameSync(chemin);
}

String _sansExtension(String chemin) {
  for (final ext in const <String>['.json.gz', '.json']) {
    if (chemin.endsWith(ext)) {
      return chemin.substring(0, chemin.length - ext.length);
    }
  }
  return chemin;
}

String _voisin(String chemin, String prefixe) {
  final f = File(chemin);
  final nom = f.uri.pathSegments.last;
  return '${f.parent.path}/$prefixe$nom';
}

// ----------------------------------------------------------------------
// Entrées (banc)
// ----------------------------------------------------------------------

KmBanc _banc(Map<String, Object?> config) {
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final parametres = kc.jm(
    jsonDecode(File(config['parametres']! as String).readAsStringSync()),
  );
  final vecteurs = kc.jm(
    kc.jm(
      jsonDecode(File(config['fiches']! as String).readAsStringSync()),
    )['exercices'],
  );
  return KmBanc(
    catalog: catalog,
    plan: KalisPlan(),
    parametres: parametres,
    fiches: <String, kc.Json>{
      for (final e in vecteurs.entries) e.key: kc.jm(e.value),
    },
    profils: <String, Map<String, Object?>>{
      for (final j in readSeasonJson()) j['key']! as String: j,
    },
  );
}

// ----------------------------------------------------------------------
// Isolats de travail (équipe persistante : les entrées sont chargées une
// fois par isolat pour toute la recherche)
// ----------------------------------------------------------------------

String _erreurCourte(Object e, StackTrace st) {
  final t = '${e.runtimeType}: $e\n$st';
  return t.length > 1200 ? t.substring(0, 1200) : t;
}

/// Une tâche : saison de Koach (`koach`) ou saison du témoin (`temoin`).
Object? _executer(KmBanc banc, Map<String, Object?> t) {
  final type = t['type'];
  if (type == 'koach') {
    final tr = t['trajectoires'];
    return kmEvaluerSaisonAdversaire(
      banc,
      kc.jm(t['travail']),
      briques: <String>[for (final b in kc.jl(t['briques'])) b! as String],
      trajectoires: tr == null ? null : kc.ent(tr),
    );
  }
  if (type == 'temoin') {
    final entree = kc.jm(t['entree']);
    try {
      return kmNormaliserJson(
        kmAdversaryRun(
          banc.catalog,
          KalisPlan(),
          banc.profils[entree['key']! as String]!,
          entree,
        ),
      );
    } catch (e, st) {
      return <String, Object?>{
        'id': entree['id'],
        'plantage': _erreurCourte(e, st),
      };
    }
  }
  throw StateError('tâche inconnue : $type');
}

void _ouvrier(List<Object?> args) {
  final vers = args[0]! as SendPort;
  final config = args[1]! as Map<String, Object?>;
  final rp = ReceivePort();
  vers.send(rp.sendPort);
  KmBanc? banc;
  rp.listen((Object? m) {
    if (m == null) {
      rp.close();
      return;
    }
    final t = m as Map<String, Object?>;
    Object? resultat;
    String? erreur;
    try {
      final b = banc ??= _banc(config);
      resultat = _executer(b, t);
    } catch (e, st) {
      erreur = _erreurCourte(e, st);
    }
    vers.send(<String, Object?>{
      'id': t['id'],
      'resultat': resultat,
      'erreur': erreur,
    });
  });
}

/// Équipe de [n] isolats ; [executer] répartit un lot de tâches et rend
/// les résultats dans l'ordre des tâches.
final class _Equipe {
  _Equipe._();

  final List<SendPort> _vers = <SendPort>[];
  final List<ReceivePort> _ports = <ReceivePort>[];
  List<Map<String, Object?>> _taches = const <Map<String, Object?>>[];
  List<Object?> _resultats = const <Object?>[];
  int _prochaine = 0;
  int _faites = 0;
  Completer<void>? _fin;
  bool _fermee = false;
  void Function(int faites, int total)? _auFil;

  static Future<_Equipe> demarrer(int n, Map<String, Object?> config) async {
    final e = _Equipe._();
    for (var w = 0; w < n; w++) {
      final rp = ReceivePort();
      final erreurs = ReceivePort();
      final sortie = ReceivePort();
      final pret = Completer<SendPort>();
      final indice = w;
      rp.listen((Object? m) {
        if (m is SendPort) {
          pret.complete(m);
          return;
        }
        e._recu(indice, m! as Map<String, Object?>);
      });
      erreurs.listen((Object? x) => e._echec(StateError('isolat : $x')));
      sortie.listen((Object? _) {
        rp.close();
        erreurs.close();
        sortie.close();
        if (!e._fermee) {
          e._echec(StateError('isolat $indice arrêté'));
        }
      });
      e._ports.add(rp);
      await Isolate.spawn<List<Object?>>(
        _ouvrier,
        <Object?>[rp.sendPort, config],
        onError: erreurs.sendPort,
        onExit: sortie.sendPort,
      );
      e._vers.add(await pret.future);
    }
    return e;
  }

  void _echec(Object erreur) {
    final f = _fin;
    if (f != null && !f.isCompleted) {
      f.completeError(erreur);
    }
  }

  void _envoyer(int w) {
    if (_prochaine < _taches.length) {
      final id = _prochaine++;
      _vers[w].send(<String, Object?>{..._taches[id], 'id': id});
    }
  }

  void _recu(int w, Map<String, Object?> m) {
    final f = _fin;
    if (f == null || f.isCompleted) {
      return;
    }
    final erreur = m['erreur'];
    if (erreur != null) {
      f.completeError(StateError('tâche ${m['id']} : $erreur'));
      return;
    }
    _resultats[m['id']! as int] = m['resultat'];
    _faites += 1;
    _auFil?.call(_faites, _taches.length);
    if (_faites == _taches.length) {
      f.complete();
    } else {
      _envoyer(w);
    }
  }

  Future<List<Object?>> executer(
    List<Map<String, Object?>> taches, {
    void Function(int faites, int total)? auFil,
  }) async {
    if (taches.isEmpty) {
      return <Object?>[];
    }
    _taches = taches;
    _resultats = List<Object?>.filled(taches.length, null);
    _prochaine = 0;
    _faites = 0;
    _auFil = auFil;
    final fin = Completer<void>();
    _fin = fin;
    for (var w = 0; w < _vers.length; w++) {
      _envoyer(w);
    }
    await fin.future;
    return _resultats;
  }

  void fermer() {
    _fermee = true;
    for (final v in _vers) {
      v.send(null);
    }
  }
}

void Function(int, int) _progression(String quoi) {
  final w = Stopwatch()..start();
  var dernier = -1;
  return (int faites, int total) {
    final pas = math.max(1, total ~/ 10);
    if (faites == total || faites ~/ pas != dernier) {
      dernier = faites ~/ pas;
      stderr.writeln(
        '  $quoi : $faites/$total (${(w.elapsedMilliseconds / 1000).toStringAsFixed(0)} s)',
      );
    }
  };
}

Future<List<kc.Json>> _koach(
  _Equipe equipe,
  List<Map<String, Object?>> travaux,
  List<String> briques,
  int? trajectoires,
) async {
  final r = await equipe.executer(<Map<String, Object?>>[
    for (final t in travaux)
      <String, Object?>{
        'type': 'koach',
        'travail': t,
        'briques': briques,
        'trajectoires': trajectoires,
      },
  ], auFil: _progression('saisons de Koach'));
  return <kc.Json>[for (final x in r) kc.jm(x)];
}

/// Témoin 0.3.1 sur [entrees] (`kmEntreesDart`) : sorties valides, et
/// identifiants des saisons qui ont planté (comptées manquantes).
Future<(List<kc.Json>, List<kc.Json>)> _temoin(
  _Equipe equipe,
  List<Map<String, Object?>> entrees,
) async {
  final r = await equipe.executer(<Map<String, Object?>>[
    for (final e in entrees) <String, Object?>{'type': 'temoin', 'entree': e},
  ], auFil: _progression('saisons du témoin'));
  final ok = <kc.Json>[];
  final ko = <kc.Json>[];
  for (final x in r) {
    final m = kc.jm(x);
    (m.containsKey('run') ? ok : ko).add(m);
  }
  return (ok, ko);
}

// ----------------------------------------------------------------------
// --rejouer
// ----------------------------------------------------------------------

Future<void> _rejouer(List<String> args, String fichier) async {
  final watch = Stopwatch()..start();
  final briques = _briques(args);
  final trajectoires = option(args, '--trajectoires') == null
      ? null
      : _entier(args, '--trajectoires', 1000);
  final coeurs = _entier(args, '--coeurs', 2);
  final sansRejeu = args.contains('--sans-rejeu');
  final temoinLu = option(args, '--temoin-lu');
  final sortie =
      option(args, '--sortie') ?? 'comparaison_adversaires_km2.json';
  final adversaires = kmLireAdversaires(_lireJson(fichier));
  var horsBornes = 0;
  for (final a in adversaires) {
    if (a.containsKey('fin_episodes') && kmVerifierBornes(a).isNotEmpty) {
      horsBornes += 1;
    }
  }
  final travaux = <Map<String, Object?>>[
    for (final a in adversaires) ...kmTravaux(a),
  ];
  stdout.writeln(
    '${adversaires.length} adversaires, ${travaux.length} saisons '
    '(${sansRejeu ? 'Koach : mesures stockées' : 'Koach rejoué en Dart'}, '
    'briques : ${briques.isEmpty ? 'aucune' : briques.join(',')}) ; '
    'hors bornes : $horsBornes.',
  );
  final equipe = await _Equipe.demarrer(
    math.max(1, math.min(coeurs, travaux.length)),
    _config(args),
  );
  try {
    List<kc.Json>? saisonsKoach;
    if (!sansRejeu) {
      saisonsKoach = await _koach(equipe, travaux, briques, trajectoires);
    }
    List<kc.Json> temoin;
    var plantagesTemoin = <kc.Json>[];
    if (temoinLu != null) {
      temoin = <kc.Json>[for (final e in kc.jl(_lireJson(temoinLu))) kc.jm(e)];
    } else {
      (temoin, plantagesTemoin) = await _temoin(
        equipe,
        kmEntreesDart(adversaires),
      );
    }
    final cmp = kmComparerAdversaires(
      adversaires,
      temoin,
      saisonsKoach: saisonsKoach,
    );
    cmp['moteur'] = _moteur(
      briques,
      trajectoires,
      temoinLu == null
          ? 'kmAdversaryRun (kalis_adapt 0.3.1), même exécution'
          : 'lu dans $temoinLu',
    );
    _ecrireTexte(sortie, kmDumpsAdversaires(cmp));
    stdout.writeln(kmResumeTexteComparaison(cmp));
    for (final p in plantagesTemoin) {
      stdout.writeln('TÉMOIN EN ÉCHEC : ${p['id']} ${p['plantage']}');
    }
    _rappelKm1(option(args, '--reference') ?? _comparaisonKm1);
    stdout.writeln(
      'écrit : $sortie (${(watch.elapsedMilliseconds / 1000).toStringAsFixed(0)} s)',
    );
  } finally {
    equipe.fermer();
  }
}

void _rappelKm1(String chemin) {
  if (!File(chemin).existsSync()) {
    return;
  }
  final ref = _lireJson(chemin);
  if (ref is! Map<String, Object?>) {
    return;
  }
  final c = kc.dictOuVide(ref['critere']);
  stdout.writeln(
    'référence ($chemin) : pire Koach ${c['pire_koach']}, pire témoin '
    '${c['pire_temoin']}, respecté ${c['respecte']}',
  );
}

// ----------------------------------------------------------------------
// --chercher
// ----------------------------------------------------------------------

Future<void> _chercher(List<String> args) async {
  final watch = Stopwatch()..start();
  final briques = _briques(args);
  final trajectoires = option(args, '--trajectoires') == null
      ? null
      : _entier(args, '--trajectoires', 1000);
  final coeurs = _entier(args, '--coeurs', 2);
  final budget = _entier(args, '--budget', 300);
  final graines = _entier(args, '--graines', 2);
  final objectif = option(args, '--objectif') ?? 'a';
  final nPires = _entier(args, '--n-pires', 32);
  final nTemoins = _entier(args, '--temoins', 8);
  final profils = (option(args, '--profils') ?? kmAdvProfilsDefaut.join(','))
      .split(',')
      .where((x) => x.trim().isNotEmpty)
      .map((x) => x.trim())
      .toList();
  final scenario = option(args, '--scenario') ?? kmAdvScenarioDefaut;
  final modeles = option(args, '--modeles') ?? kmAdvModelesDefaut;
  final graine = _entier(args, '--graine', 20261009);
  final sortie = option(args, '--sortie') ?? 'adversaires_km2.json';
  final rapport =
      option(args, '--rapport') ?? _voisin(sortie, 'comparaison_');
  final sortieTemoin =
      option(args, '--sortie-temoin') ??
      '${_sansExtension(sortie)}_temoin.json.gz';
  final entreeDart = option(args, '--entree-dart');
  if (modeles.isEmpty || modeles.split('').any((v) => !'abc'.contains(v))) {
    throw FormatException('--modeles : lettres parmi a, b, c', modeles);
  }
  final config = _config(args);
  final banc = _banc(config);
  for (final p in profils) {
    if (!banc.profils.containsKey(p)) {
      throw FormatException('profil inconnu', p);
    }
  }
  final equipe = await _Equipe.demarrer(math.max(1, coeurs), config);
  try {
    final res = await kmChercherAdversaires(
      cadreDe: (cle, scen, kind) => KmCadreAdversaire.deSaison(
        banc.catalog,
        banc.saison(cle, scen),
        kind,
      ),
      evaluer: (travaux) => _koach(equipe, travaux, briques, trajectoires),
      budget: budget,
      profils: profils,
      scenario: scenario,
      modeles: modeles,
      graines: graines,
      objectif: objectif,
      nPires: nPires,
      nTemoins: nTemoins,
      graine: graine,
      journal: (vus) => stderr.writeln('  $vus saisons simulées'),
    );
    final adversaires = kmLireAdversaires(res);
    final entrees = kmEntreesDart(adversaires);
    // Témoin mesuré dans la même exécution, sur chaque adversaire retenu.
    final (temoin, plantagesTemoin) = await _temoin(equipe, entrees);
    final cmp = kmComparerAdversaires(adversaires, temoin);
    final moteur = _moteur(
      briques,
      trajectoires,
      'kmAdversaryRun (kalis_adapt 0.3.1), même exécution',
    );
    res['moteur'] = moteur;
    cmp['moteur'] = moteur;
    _ecrireTexte(sortie, kmDumpsAdversaires(res));
    _ecrireTexte(rapport, kmDumpsAdversaires(cmp));
    _ecrireTexte(sortieTemoin, jsonEncode(temoin));
    if (entreeDart != null) {
      _ecrireTexte(entreeDart, kmDumpsAdversaires(entrees));
    }
    stdout.writeln(kmResumeTexteRecherche(res));
    final plantages = kc.jl(res['plantages']);
    if (plantages.isNotEmpty) {
      stdout.writeln(
        'PLANTAGES DE KOACH : ${plantages.length} saison(s), voir '
        '« plantages » dans $sortie',
      );
    }
    stdout.writeln(kmResumeTexteComparaison(cmp));
    for (final p in plantagesTemoin) {
      stdout.writeln('TÉMOIN EN ÉCHEC : ${p['id']} ${p['plantage']}');
    }
    stdout.writeln(
      'écrit : $sortie, $rapport, $sortieTemoin'
      '${entreeDart == null ? '' : ', $entreeDart'} '
      '(${(watch.elapsedMilliseconds / 1000).toStringAsFixed(0)} s)',
    );
  } finally {
    equipe.fermer();
  }
}
