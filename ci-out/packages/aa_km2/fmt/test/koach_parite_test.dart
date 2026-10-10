// Parité Python ↔ Dart de Koach 1.0.1 (lot KM2) : chaque fixture de
// `reference/fixtures/` (générée par la référence Python, `generer.py`) est
// rejouée par le moteur Dart. Comparaison : nombres à
// |a − b| ≤ 1e-9 · max(1, |a|, |b|), le reste à l'identique.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

const double tolerance = 1e-9;

Json lireFixture(String nom) =>
    jsonDecode(File('reference/fixtures/$nom').readAsStringSync()) as Json;

/// Valeur JSON pure (comme `propre` de la référence).
Object? propre(Object? x) {
  if (x == null || x is bool || x is String || x is num) {
    return x;
  }
  if (x is Grille) {
    return <String, Object?>{
      'pas': x.pas,
      'minimum': x.minimum,
      'halteres': x.halteres,
    };
  }
  if (x is Map) {
    return <String, Object?>{
      for (final e in x.entries) '${e.key}': propre(e.value),
    };
  }
  if (x is Set) {
    final l = [for (final v in x) propre(v)];
    l.sort((a, b) => '$a'.compareTo('$b'));
    return l;
  }
  if (x is Iterable) {
    return [for (final v in x) propre(v)];
  }
  if (x is (Object?, Object?)) {
    return [propre(x.$1), propre(x.$2)];
  }
  if (x is (Object?, Object?, Object?)) {
    return [propre(x.$1), propre(x.$2), propre(x.$3)];
  }
  if (x is (Object?, Object?, Object?, Object?)) {
    return [propre(x.$1), propre(x.$2), propre(x.$3), propre(x.$4)];
  }
  if (x is (Object?, Object?, Object?, Object?, Object?, Object?)) {
    return [
      propre(x.$1),
      propre(x.$2),
      propre(x.$3),
      propre(x.$4),
      propre(x.$5),
      propre(x.$6),
    ];
  }
  throw ArgumentError('valeur non codable : ${x.runtimeType}');
}

double? _nombre(Object? v) {
  if (v is num) return v.toDouble();
  if (v == 'inf') return double.infinity;
  if (v == '-inf') return double.negativeInfinity;
  if (v == 'nan') return double.nan;
  return null;
}

/// Compare [obtenu] (Dart) à [attendu] (fixture) ; ajoute les écarts à
/// [ecarts] (au plus [max]).
void comparer(
  Object? obtenu,
  Object? attendu,
  String chemin,
  List<String> ecarts, {
  int max = 40,
}) {
  if (ecarts.length >= max) return;
  final o = propre(obtenu);
  final a = attendu;
  if (o is num && a is! bool) {
    final na = _nombre(a);
    if (na == null) {
      ecarts.add('$chemin : obtenu $o, attendu $a');
      return;
    }
    final od = o.toDouble();
    if (od.isNaN && na.isNaN) return;
    if (od == na) return;
    final m = [1.0, od.abs(), na.abs()].reduce((x, y) => x > y ? x : y);
    if ((od - na).abs() > tolerance * m || od.isInfinite || na.isInfinite) {
      ecarts.add('$chemin : obtenu $od, attendu $na (écart ${od - na})');
    }
    return;
  }
  if (o is Map<String, Object?> && a is Map<String, Object?>) {
    final cles = {...o.keys, ...a.keys}.toList()..sort();
    for (final k in cles) {
      if (k == 'trace') {
        // Texte de diagnostic hors contrat (§ 3.3) : non comparé.
        continue;
      }
      if (!o.containsKey(k)) {
        ecarts.add('$chemin.$k : absent (attendu ${_court(a[k])})');
      } else if (!a.containsKey(k)) {
        ecarts.add('$chemin.$k : en trop (${_court(o[k])})');
      } else {
        comparer(o[k], a[k], '$chemin.$k', ecarts, max: max);
      }
      if (ecarts.length >= max) return;
    }
    return;
  }
  if (o is List && a is List) {
    if (o.length != a.length) {
      ecarts.add(
        '$chemin : longueur ${o.length}, attendu ${a.length} '
        '(obtenu ${_court(o)} ; attendu ${_court(a)})',
      );
      return;
    }
    for (var i = 0; i < o.length; i++) {
      comparer(o[i], a[i], '$chemin[$i]', ecarts, max: max);
      if (ecarts.length >= max) return;
    }
    return;
  }
  if (o != a) {
    ecarts.add('$chemin : obtenu ${_court(o)}, attendu ${_court(a)}');
  }
}

String _court(Object? v) {
  final t = jsonEncode(propre(v));
  return t.length > 300 ? '${t.substring(0, 300)}…' : t;
}

Map<String, Json> fichesDe(Object? v) => <String, Json>{
  for (final e in jm(v).entries) e.key: jm(e.value),
};

Json diagnosticDe(Koach k) {
  final m = k.modele;
  return <String, Object?>{
    'n': m.n,
    'm': [for (var i = 0; i < m.n; i++) m.m[i]],
    'P_diag': [for (var i = 0; i < m.n; i++) m.pget(i, i)],
    'ordre': List<String>.of(m.ordre),
  };
}

void echouerSi(List<String> ecarts, String titre) {
  if (ecarts.isNotEmpty) {
    fail('$titre\n${ecarts.join('\n')}');
  }
}

void testerMoteur(String nom) {
  test(nom, () {
    final f = lireFixture(nom);
    final e = jm(f['entrees']);
    final params = copieJson(jm(e['params']));
    final fiches = fichesDe(e['fiches']);
    final profil = copieJson(jm(e['profil']));
    final journal = [for (final x in jl(e['journal'])) jm(x)];
    final att = jm(f['attendu']);
    final plans = <int, Json>{
      for (final p in jl(att['plans'])) ent(jm(p)['indice']): jm(p),
    };
    final instantanes = <int, Json>{
      for (final p in jl(att['instantanes'])) ent(jm(p)['indice']): jm(p),
    };
    final k = Koach(params, fiches, profil);
    final ecarts = <String>[];
    for (var i = 0; i < journal.length; i++) {
      final ev = copieJson(journal[i]);
      try {
        if (ev['type'] == 'plan') {
          final sortie = k.plan(jm(ev['contraintes']));
          final p = plans[i];
          if (p == null) {
            fail('$nom : plan $i absent des attendus');
          }
          comparer(sortie, p['sortie'], 'plan[$i].sortie', ecarts);
          comparer(k.explain(), p['raisons'], 'plan[$i].raisons', ecarts);
        } else {
          k.observe(ev);
        }
      } catch (err, pile) {
        fail(
          '$nom : exception à l\'événement $i (${ev['type']}) : $err\n'
          '${_court(journal[i])}\n$pile',
        );
      }
      final inst = instantanes[i];
      if (inst != null) {
        comparer(k.posterior(), inst['posterior'], 'posterior[$i]', ecarts);
        if (inst['diagnostic'] != null) {
          comparer(
            diagnosticDe(k),
            inst['diagnostic'],
            'diagnostic[$i]',
            ecarts,
          );
        }
      }
      if (ecarts.isNotEmpty) {
        fail(
          '$nom : premier écart à l\'événement $i (${ev['type']}) :\n'
          '${_court(journal[i])}\n${ecarts.join('\n')}',
        );
      }
    }
    final fin = jm(att['final']);
    comparer(k.posterior(), fin['posterior'], 'final.posterior', ecarts);
    comparer(k.explain(), fin['raisons'], 'final.raisons', ecarts);
    comparer(diagnosticDe(k), fin['diagnostic'], 'final.diagnostic', ecarts);
    comparer(
      k.journal.length,
      fin['longueur_journal'],
      'final.longueur',
      ecarts,
    );
    comparer(k.journal, journal, 'journal', ecarts);
    echouerSi(ecarts, '$nom : état final');
    // Rejeu : le journal seul redonne le même état.
    final k2 = rejouer(
      copieJson(jm(e['params'])),
      fiches,
      copieJson(jm(e['profil'])),
      [for (final x in journal) copieJson(x)],
    );
    comparer(k2.posterior(), fin['posterior'], 'rejeu.posterior', ecarts);
    comparer(diagnosticDe(k2), fin['diagnostic'], 'rejeu.diagnostic', ecarts);
    echouerSi(ecarts, '$nom : rejeu');
  });
}

void testerPlanification(String nom) {
  test(nom, () {
    final f = lireFixture(nom);
    final e = jm(f['entrees']);
    final fiches = fichesDe(e['fiches']);
    final journal = [for (final x in jl(e['journal'])) copieJson(jm(x))];
    final k = rejouer(
      copieJson(jm(e['params'])),
      fiches,
      copieJson(jm(e['profil'])),
      journal,
    );
    final att = jm(f['attendu']);
    final ecarts = <String>[];
    comparer(k.posterior(), att['posterior_avant'], 'posterior_avant', ecarts);
    echouerSi(ecarts, '$nom : rejeu du journal');
    final pc = jm(f['planification']);
    final ref = jm(pc['reference']);
    final pl = Planification(
      k.params,
      fiches,
      null,
      copieJson(jm(pc['options'])),
    );
    final cibles = <String, num>{
      for (final c in dictOuVide(ref['cibles']).entries) c.key: c.value! as num,
    };
    pl.chargerReference(
      [for (final b in jl(ref['blocs'])) jm(b)],
      [for (final w in listeOuVide(ref['block_weeks'])) ent(w)],
      ent(ref['horizon']),
      cibles: cibles,
      echeanceJour: ref['echeance_jour'] == null
          ? null
          : ent(ref['echeance_jour']),
      principaux: [
        for (final p in listeOuVide(ref['principaux'])) p! as String,
      ],
      poidsCorps: ref['poids_corps'] as num?,
    );
    final semaine = ent(pc['semaine']);
    final n = ent(pl.p['trajectoires']);
    final tirage = pl.tirer(k, semaine, n);
    final attTirage = jm(att['tirage']);
    for (final c in attTirage.keys) {
      comparer(tirage[c], attTirage[c], 'tirage.$c', ecarts);
    }
    comparer(pl.suivis, att['suivis'], 'suivis', ecarts);
    comparer(
      pl.hypotheseThompson,
      att['hypothese_thompson'],
      'hypothese_thompson',
      ecarts,
    );
    final (blocsD, qualites) = pl.dimensions(semaine);
    comparer(
      <String, Object?>{'blocs': blocsD, 'qualites': qualites},
      att['dimensions'],
      'dimensions',
      ecarts,
    );
    echouerSi(ecarts, '$nom : tirage du jumeau');
    final tables = <String, Object?>{};
    for (var w = semaine; w < pl.horizon; w++) {
      final t = pl.table(w);
      if (t != null) {
        tables['$w'] = t.versJson();
      }
    }
    comparer(tables, att['tables'], 'tables', ecarts);
    echouerSi(ecarts, '$nom : tables');
    final d = blocsD.length * (qualites.length + 1);
    final (v0, p0, dist0, det0) = pl.evaluer(
      [List<double>.filled(d, 0.0)],
      tirage,
      semaine,
      blocsD,
      qualites,
      detail: true,
    );
    comparer(
      <String, Object?>{
        'valeur': v0,
        'p_cibles': p0,
        'distance': dist0,
        'J': det0!['J'],
        'penal': det0['penal'],
        'fatigue_fin': det0['fatigue_fin'],
        'fatigue_echeance': det0['fatigue_echeance'],
        'gains': det0['gains'],
      },
      att['evaluation_reference'],
      'evaluation_reference',
      ecarts,
    );
    echouerSi(ecarts, '$nom : évaluation de la référence');
    final ligne = pl.replanifier(k, semaine);
    comparer(ligne, att['ligne'], 'ligne', ecarts);
    comparer(
      <String, Object?>{for (final e in pl.plan.entries) '${e.key}': e.value},
      att['plan'],
      'plan',
      ecarts,
    );
    final modules = <String, Object?>{};
    final fin = semaine + 4 < pl.horizon ? semaine + 4 : pl.horizon;
    for (var w = semaine; w < fin; w++) {
      final mods = pl.itemsModules(w);
      final cles = mods.keys.toList()
        ..sort((a, b) {
          final c = a.$1.compareTo(b.$1);
          return c != 0 ? c : a.$2.compareTo(b.$2);
        });
      modules['$w'] = [
        for (final c in cles) [c.$1, c.$2, mods[c]!.$1, mods[c]!.$2],
      ];
    }
    comparer(modules, att['items_modules'], 'items_modules', ecarts);
    comparer(k.posterior(), att['posterior_apres'], 'posterior_apres', ecarts);
    echouerSi(ecarts, '$nom : replanification');
  });
}

double Function(double) bruitDe(Json b) => (double u) {
  var r = u * (1.0 + dbl(b['bp'])) + dbl(b['ba']);
  if (r < 0.0) r = 0.0;
  if (r > 8.0) r = 8.0;
  final sd = dbl(b['c0']) + dbl(b['c1']) * r;
  return sd * sd + dbl(b['extra']);
};

double _d(Object? v) => _nombre(v)!;

void main() {
  group('numerique.json', () {
    final cas = jm(lireFixture('numerique.json')['cas']);
    void un(String nom, Object? Function(List<Object?> e) f) {
      test(nom, () {
        final ecarts = <String>[];
        final l = jl(cas[nom]);
        for (var i = 0; i < l.length; i++) {
          final c = jl(l[i]);
          comparer(f(c), c[1], '$nom[$i] ${c[0]}', ecarts);
        }
        echouerSi(ecarts, nom);
      });
    }

    un('erfc', (c) => erfcK(_d(c[0])));
    un('norm_cdf', (c) => normCdfK(_d(c[0])));
    un('norm_sf', (c) => normSfK(_d(c[0])));
    un('norm_pdf', (c) => normPdfK(_d(c[0])));
    un('norm_ppf', (c) => normPpfK(_d(c[0])));
    un('interval_moments', (c) {
      final x = jl(c[0]).map(_d).toList();
      final r = intervalMoments(x[0], x[1], x[2], x[3], x[4]);
      return [r.$1, r.$2, r.$3];
    });
    final bruits = [for (final b in jl(cas['category_moments_bruits'])) jm(b)];
    un('category_moments', (c) {
      final x = jl(c[0]);
      final r = categoryMoments(
        _d(x[0]),
        _d(x[1]),
        _d(x[2]),
        _d(x[3]),
        bruitDe(bruits[ent(x[4])]),
        steps: ent(x[5]),
        span: _d(x[6]),
        gross: _d(x[7]),
        grossSd: _d(x[8]),
      );
      return [r.$1, r.$2, r.$3];
    });
    un('category_mass', (c) {
      final x = jl(c[0]).map(_d).toList();
      return categoryMassK(x[0], x[1], x[2], x[3]);
    });
    un('point_moments', (c) {
      final x = jl(c[0]).map(_d).toList();
      final r = pointMoments(x[0], x[1], x[2], x[3]);
      return [r.$1, r.$2, r.$3];
    });
    un('dart_round', (c) => dartRound(_d(c[0])));
    un('clamp', (c) {
      final x = jl(c[0]).map(_d).toList();
      return clampD(x[0], x[1], x[2]);
    });
    un('arrondi', (c) {
      final x = jl(c[0]);
      return arrondi(_d(x[0]), ent(x[1]));
    });
    un('fnv1a32', (c) => fnv1a32(c[0]! as String));
    un('cholesky_semi', (c) {
      final x = jl(c[0]);
      final s = [for (final r in jl(x[0])) jl(r).map(_d).toList()];
      return x[1] == null ? choleskySemi(s) : choleskySemi(s, tol: _d(x[1]));
    });
    test('mulberry32', () {
      final ecarts = <String>[];
      for (final g in jl(cas['mulberry32'])) {
        final m = jm(g);
        final r = Mulberry32(ent(m['graine']));
        final next = [for (var i = 0; i < 40; i++) r.next()];
        comparer(next, m['next'], 'next ${m['graine']}', ecarts);
        comparer(r.state, m['etat_apres_next'], 'etat ${m['graine']}', ecarts);
        final r2 = Mulberry32(ent(m['graine']));
        final gs = [for (var i = 0; i < 40; i++) r2.gauss()];
        comparer(gs, m['gauss'], 'gauss ${m['graine']}', ecarts);
        comparer(
          r2.state,
          m['etat_apres_gauss'],
          'etat g ${m['graine']}',
          ecarts,
        );
      }
      echouerSi(ecarts, 'mulberry32');
    });
  });

  group('moteur', () {
    for (var n = 1; n <= 10; n++) {
      testerMoteur('moteur_$n.json');
    }
  });

  group('planification', () {
    testerPlanification('planification_1.json');
    testerPlanification('planification_2.json');
  });
}
