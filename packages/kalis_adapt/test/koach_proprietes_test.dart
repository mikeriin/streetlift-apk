// Tests de propriétés seedés de Koach (lot KM2, PIPELINE_CP § 4 : au moins
// 10 000 entrées). Tout le hasard vient de Mulberry32 (graines fixes) ;
// chaque propriété a été vérifiée d'abord sur la référence Python
// (`reference/koach/`), avec les mêmes générateurs et les mêmes graines.
//
// - numerique : Φ∘Φ⁻¹ ≈ id, Φ⁻¹ croissante, erfc (symétrie, bornes,
//   monotonie), appariement de moments (variance a posteriori ≤ a priori et
//   > 0, moyenne entre l'a priori et l'intervalle observé), quadrature à
//   bruit constant, Cholesky semi-définie (L·Lᵀ = S), arrondi, mulberry32 ;
// - modele : courbe répétitions-charge (g croissante, g(1) = 0, inverse en
//   forme fermée), intervalles des flammes, covariance symétrique à
//   diagonale ≥ 0 et état fini après des séries aléatoires, a posteriori
//   lisible cohérent ;
// - seance : garde-fous (contrat § 8) sur les dix journaux de parité
//   perturbés au hasard (douleurs, bilans bas) : jamais plus de séries
//   servies qu'écrites ; test retiré sur une zone douloureuse sollicitée ;
//   retrait (A1.3) et allègement × 0,6 (A1.4) ; pas de test un jour de
//   bilan bas (A5.2) ; aucune charge au-dessus du dernier passage sous
//   douleur ou bilan bas (A1.2, I3) ; semaine verrouillée : charge jamais
//   au-dessus de la part écrite, au cran de la grille près (A6.5).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

/// Entrées vérifiées, toutes propriétés confondues.
int _entrees = 0;

double _u(Mulberry32 r, double lo, double hi) => lo + (hi - lo) * r.next();

int _i(Mulberry32 r, int n) => (r.next() * n).floor();

bool _fini(double x) => x.isFinite;

/// Relevé des échecs d'une propriété (les 20 premiers).
class _Releve {
  final List<String> echecs = [];
  int n = 0;

  void entree() {
    n++;
    _entrees++;
  }

  void verifier(bool ok, String Function() quoi) {
    if (!ok && echecs.length < 20) {
      echecs.add(quoi());
    }
  }

  void fin(int minimum) {
    expect(echecs, isEmpty, reason: echecs.join('\n'));
    expect(n, greaterThanOrEqualTo(minimum));
  }
}

Json _lireFixture(String nom) =>
    jm(jsonDecode(File('reference/fix_dart/$nom').readAsStringSync()));

Map<String, Json> _fiches(Object? v) => <String, Json>{
  for (final e in jm(v).entries) e.key: jm(e.value),
};

const List<String> _zonesDouleur = [
  'neck',
  'shoulder',
  'elbow',
  'wrist_hand',
  'upper_back',
  'lower_back',
  'chest',
  'abdomen',
  'hip',
  'thigh',
  'knee',
  'lower_leg',
  'ankle_foot',
];

num _nb(Object? v) => v == null ? 0 : v as num;

void main() {
  group('numerique', () {
    test('normCdfK(normPpfK(p)) ≈ p (2 000)', () {
      final rel = _Releve();
      final r = Mulberry32(101);
      for (var i = 0; i < 2000; i++) {
        final e = -10 * r.next();
        var p = r.next() < 0.5
            ? math.pow(10.0, e).toDouble()
            : 1 - math.pow(10.0, e).toDouble() * 0.5;
        if (p <= 0 || p >= 1) {
          p = 0.5;
        }
        final q = normCdfK(normPpfK(p));
        final m = math.min(p, 1 - p);
        rel.entree();
        rel.verifier((q - p).abs() <= 1e-9 * m, () => 'p=$p q=$q');
      }
      rel.fin(2000);
    });

    test('normPpfK croissante (1 000)', () {
      final rel = _Releve();
      final r = Mulberry32(102);
      for (var i = 0; i < 1000; i++) {
        final p1 = r.next();
        final p2 = r.next();
        if (p1 == 0 || p2 == 0) {
          continue;
        }
        final a = math.min(p1, p2);
        final b = math.max(p1, p2);
        rel.entree();
        rel.verifier(normPpfK(a) <= normPpfK(b), () => 'a=$a b=$b');
      }
      rel.fin(990);
    });

    test('erfcK : bornes, symétrie, monotonie (2 000)', () {
      final rel = _Releve();
      final r = Mulberry32(103);
      for (var i = 0; i < 2000; i++) {
        final x = i.isOdd ? _u(r, -30, 30) : _u(r, -4, 4);
        final e1 = erfcK(x);
        final e2 = erfcK(-x);
        rel.entree();
        rel.verifier(e1 >= 0 && e1 <= 2, () => 'bornes x=$x $e1');
        rel.verifier((e1 + e2 - 2).abs() <= 1e-12, () => 'symétrie x=$x');
        final y = _u(r, -6, 6);
        final a = math.min(x, y);
        final b = math.max(x, y);
        rel.verifier(erfcK(a) >= erfcK(b), () => 'monotonie $a $b');
      }
      rel.fin(2000);
    });

    test('intervalMoments : variance réduite, moyenne encadrée (2 000)', () {
      final rel = _Releve();
      final r = Mulberry32(104);
      for (var i = 0; i < 2000; i++) {
        final m = _u(r, -5, 5);
        final v = math.exp(_u(r, -8, 2));
        final s2 = math.exp(_u(r, -8, 2));
        final k = _i(r, 4);
        var a = _u(r, -8, 8);
        var b = a + math.exp(_u(r, -6, 2));
        if (k == 1) {
          a = -inf;
        }
        if (k == 2) {
          b = inf;
        }
        final (lz, m2, v2) = intervalMoments(m, v, s2, a, b);
        String quoi() => 'm=$m v=$v s2=$s2 a=$a b=$b -> $lz $m2 $v2';
        rel.entree();
        rel.verifier(_fini(lz) && _fini(m2) && _fini(v2), quoi);
        rel.verifier(v2 > 0, quoi);
        rel.verifier(v2 <= v * (1 + 1e-12), quoi);
        final lo = math.min(m, a);
        final hi = math.max(m, b);
        rel.verifier(
          lo - 1e-9 * (1 + lo.abs()) <= m2 && m2 <= hi + 1e-9 * (1 + hi.abs()),
          quoi,
        );
        rel.verifier(lz <= 1e-12, quoi);
      }
      rel.fin(2000);
    });

    test('categoryMoments : finie ; bruit constant : variance réduite, '
        'moyenne encadrée (2 000)', () {
      final rel = _Releve();
      final r = Mulberry32(105);
      for (var i = 0; i < 2000; i++) {
        final m = _u(r, -3, 6);
        final v = math.exp(_u(r, -6, 1));
        final c0 = _u(r, 0.1, 1.0);
        final constant = i.isEven;
        final c1 = constant ? 0.0 : _u(r, 0, 0.4);
        final ex = _u(r, 0, 0.3);
        double nv(double u) {
          final rr = clampD(u, 0.0, 8.0);
          final sd = c0 + c1 * rr;
          return sd * sd + ex;
        }

        final k = _i(r, 3);
        var a = _u(r, -1, 6);
        var b = a + _u(r, 0.25, 1.5);
        if (k == 1) {
          a = -inf;
          b = _u(r, -1, 2);
        }
        if (k == 2) {
          b = inf;
        }
        final gross = constant ? 0.0 : _u(r, 0.0, 0.1);
        final gsd = _u(r, 1, 3);
        final (lz, m2, v2) = categoryMoments(
          m,
          v,
          a,
          b,
          nv,
          gross: gross,
          grossSd: gsd,
        );
        String quoi() => 'i=$i m=$m v=$v a=$a b=$b -> $lz $m2 $v2';
        rel.entree();
        rel.verifier(v2 > 0 && _fini(lz) && _fini(m2) && _fini(v2), quoi);
        rel.verifier(lz <= 1e-9, quoi);
        if (constant) {
          rel.verifier(v2 <= v * (1 + 1e-6), quoi);
          final lo = math.min(m, a);
          final hi = math.max(m, b);
          rel.verifier(lo - 1e-9 <= m2 && m2 <= hi + 1e-9, quoi);
        }
      }
      rel.fin(2000);
    });

    test('choleskySemi : L triangulaire, diagonale ≥ 0, L·Lᵀ = S (1 000)', () {
      final rel = _Releve();
      final r = Mulberry32(106);
      for (var it = 0; it < 1000; it++) {
        final kk = 1 + _i(r, 8);
        final rk = 1 + _i(r, kk);
        final a = [
          for (var i = 0; i < kk; i++)
            [for (var q = 0; q < rk; q++) _u(r, -2, 2)],
        ];
        if (r.next() < 0.3) {
          final z = _i(r, kk);
          a[z] = List<double>.filled(rk, 0.0);
        }
        final s = [
          for (var i = 0; i < kk; i++)
            [
              for (var j = 0; j < kk; j++)
                somme([for (var q = 0; q < rk; q++) a[i][q] * a[j][q]]),
            ],
        ];
        final l = choleskySemi(s);
        var mx = 0.0;
        var err = 0.0;
        var forme = true;
        for (var i = 0; i < kk; i++) {
          if (l[i][i] < 0) {
            forme = false;
          }
          for (var j = 0; j < kk; j++) {
            mx = math.max(mx, s[i][j].abs());
            if (j > i && l[i][j] != 0) {
              forme = false;
            }
            var x = 0.0;
            for (var q = 0; q < kk; q++) {
              x += l[i][q] * l[j][q];
            }
            err = math.max(err, (x - s[i][j]).abs());
          }
        }
        rel.entree();
        rel.verifier(forme, () => 'forme k=$kk r=$rk');
        rel.verifier(
          err <= 1e-9 * math.max(mx, 1.0),
          () => 'k=$kk r=$rk err=$err max=$mx',
        );
      }
      rel.fin(1000);
    });

    test('arrondi : écart ≤ ½·10⁻ⁿ, idempotent (1 000)', () {
      final rel = _Releve();
      final r = Mulberry32(107);
      for (var i = 0; i < 1000; i++) {
        final x = _u(r, -1000, 1000);
        final n = _i(r, 4);
        final y = arrondi(x, n);
        rel.entree();
        rel.verifier(
          (y - x).abs() <= 0.5 * math.pow(10.0, -n).toDouble() + 1e-9,
          () => 'x=$x n=$n y=$y',
        );
        rel.verifier(arrondi(y, n) == y, () => 'idempotence x=$x n=$n');
      }
      rel.fin(1000);
    });

    test('Mulberry32 : [0, 1), état sur 32 bits, déterministe (1 000)', () {
      final rel = _Releve();
      final r = Mulberry32(108);
      for (var i = 0; i < 1000; i++) {
        final s = (r.next() * 4294967296.0).floor();
        final g = Mulberry32(s);
        final g2 = Mulberry32(s);
        rel.entree();
        for (var j = 0; j < 5; j++) {
          final a = g.next();
          final b = g2.next();
          rel.verifier(a >= 0 && a < 1 && a == b, () => 'graine $s');
          rel.verifier(g.state >= 0 && g.state <= m32, () => 'état $s');
        }
        rel.verifier(
          fnv1a32('koach:$s') >= 0 && fnv1a32('koach:$s') <= m32,
          () => 'fnv $s',
        );
      }
      rel.fin(1000);
    });
  });

  group('modele', () {
    test('courbe : g(1) = 0, g croissante, repsDe inverse de gK (2 000)', () {
      final rel = _Releve();
      final r = Mulberry32(109);
      for (var i = 0; i < 2000; i++) {
        final forme = _u(r, lamMin, lamMax);
        final k = _u(r, -1, 1);
        final reps = 1 + math.exp(_u(r, -6, math.log(150)));
        final g = Modele.gK(forme, k, reps);
        final reps2 = Modele.repsDe(forme, k, g);
        String quoi() => 'forme=$forme k=$k R=$reps -> g=$g R2=$reps2';
        rel.entree();
        if (reps2 < 200) {
          rel.verifier((reps2 - reps).abs() <= 1e-9 * reps, quoi);
        }
        final reps3 = reps + _u(r, 0.01, 5);
        rel.verifier(Modele.gK(forme, k, reps3) > g, quoi);
        rel.verifier(g > 0, quoi);
        rel.verifier(Modele.gK(forme, k, 1.0) == 0.0, quoi);
        rel.verifier(Modele.dgK(forme, k, reps) >= 0.004, quoi);
      }
      rel.fin(2000);
    });

    test('bornesFlammes : bas ≤ centre ≤ haut, centre décroissant (1 000)', () {
      final d = jm(_lireFixture('moteur_1.json')['entrees']);
      final k = Koach(
        copieJson(jm(d['params'])),
        _fiches(d['fiches']),
        copieJson(jm(d['profil'])),
      );
      final m = k.modele;
      final rel = _Releve();
      final r = Mulberry32(110);
      for (var i = 0; i < 1000; i++) {
        m.notesDemi = _i(r, 20);
        m.notesEntieres = _i(r, 20);
        final o = 2 + 4 * r.next();
        final f = 1 + _i(r, 10);
        final g = 1 + _i(r, 10);
        final (lo, hi, c) = m.bornesFlammes(f.toDouble(), o);
        final (_, _, c2) = m.bornesFlammes(g.toDouble(), o);
        rel.entree();
        rel.verifier(lo <= c && c <= hi && lo < hi, () => 'f=$f o=$o');
        rel.verifier(f >= g || c > c2, () => 'f=$f g=$g o=$o');
      }
      rel.fin(1000);
    });

    test('séries aléatoires : covariance symétrique, diagonale ≥ 0, état '
        'fini, a posteriori cohérent (40 saisons)', () {
      final d = jm(_lireFixture('moteur_1.json')['entrees']);
      final fiches = _fiches(d['fiches']);
      final ids = [
        for (final e in fiches.entries)
          if (const ['charge', 'reps', 'tenue'].contains(e.value['type']))
            e.key,
      ]..sort();
      final rel = _Releve();
      for (var graine = 0; graine < 40; graine++) {
        final r = Mulberry32(1000 + graine);
        final k = Koach(
          copieJson(jm(d['params'])),
          fiches,
          copieJson(jm(d['profil'])),
        );
        var jour = 0;
        for (var sea = 0; sea < 8; sea++) {
          jour += 1 + _i(r, 3);
          k.observe(<String, Object?>{
            'type': 'seance_debut',
            'jour': jour,
            'bilan': <String, Object?>{'overall': 1 + _i(r, 5)},
            'contexte': <String, Object?>{},
          });
          final sets = <Object?>[];
          final nEx = 1 + _i(r, 3);
          for (var e = 0; e < nEx; e++) {
            final ex = ids[_i(r, ids.length)];
            final typ = fiches[ex]!['type'];
            final nS = 1 + _i(r, 4);
            for (var si = 0; si < nS; si++) {
              final reps = 1 + _i(r, 15);
              final int? fl = r.next() < 0.1 ? null : 1 + _i(r, 10);
              final double? charge = typ == 'charge'
                  ? (_u(r, 0, 120) / 2.5).roundToDouble() * 2.5
                  : null;
              final int? sec = typ == 'tenue' ? 5 + _i(r, 60) : null;
              final s = <String, Object?>{
                'exerciseId': ex,
                'slotId': 's$e',
                'kind': 'work',
                'reps': typ == 'tenue' ? null : reps,
                'seconds': sec,
                'externalLoadKg': charge,
                'flames': fl,
                'failed': r.next() < 0.08,
                'restSeconds': 60 + _i(r, 180),
                'role': null,
                'repere': false,
                'setIndex': si,
                'technique': null,
                'target': <String, Object?>{
                  'flames': 1 + _i(r, 10),
                  'loadKg': charge,
                  'repsLow': reps,
                  'repsHigh': reps,
                  'role': null,
                  'secondsLow': sec,
                  'secondsHigh': sec,
                },
              };
              k.observe(<String, Object?>{'type': 'serie', 'serie': s});
              sets.add(s);
              final m = k.modele;
              final n = m.n;
              rel.entree();
              for (var i = 0; i < n; i++) {
                final pii = m.pget(i, i);
                rel.verifier(pii >= 0, () => 'diag $graine $i $pii');
                rel.verifier(_fini(m.m[i]), () => 'm $graine $i');
                for (var j = i + 1; j < n; j++) {
                  final a = m.pget(i, j);
                  final b = m.pget(j, i);
                  final sc = math.sqrt((m.pget(i, i) * m.pget(j, j)).abs());
                  rel.verifier(_fini(a), () => 'P fini $graine $i $j');
                  rel.verifier(
                    (a - b).abs() <= 1e-9 * math.max(sc, 1e-12),
                    () => 'symétrie $graine $i $j $a $b',
                  );
                }
              }
            }
          }
          k.observe(<String, Object?>{
            'type': 'seance_fin',
            'seance': <String, Object?>{'sets': sets},
            'douleurs': <Object?>[],
          });
          if (sea % 3 == 2) {
            k.observe(<String, Object?>{
              'type': 'semaine_fin',
              'jour': jour,
              'semaine': sea ~/ 3,
            });
          }
          final po = jm(k.posterior()['exercices']);
          for (final e in po.entries) {
            final v = jm(e.value);
            final iv = jld(v['intervalle_90']);
            final sd = dbl(v['ecart_type']);
            rel.entree();
            rel.verifier(
              sd > 0 &&
                  _fini(sd) &&
                  iv[0] > 0 &&
                  iv[0] <= iv[1] &&
                  iv[1] <= iv[2],
              () => 'posterior $graine ${e.key} $v',
            );
          }
        }
      }
      rel.fin(3000);
    });
  });

  group('seance', () {
    test('garde-fous sur les journaux de parité perturbés '
        '(10 fixtures × 8 graines)', () {
      final rel = _Releve();
      for (var nf = 1; nf <= 10; nf++) {
        final d = jm(_lireFixture('moteur_$nf.json')['entrees']);
        final fiches = _fiches(d['fiches']);
        for (var rep = 0; rep < 8; rep++) {
          _seance(rel, nf, rep, d, fiches);
        }
      }
      rel.fin(4000);
    });
  });

  test('au moins 10 000 entrées au total', () {
    expect(_entrees, greaterThanOrEqualTo(10000));
  });
}

/// Rejoue le journal de la fixture [nf] perturbé par la graine [rep] et
/// vérifie les garde-fous de séance à chaque appel de `plan`.
void _seance(_Releve rel, int nf, int rep, Json d, Map<String, Json> fiches) {
  final r = Mulberry32(fnv1a32('koach-proprietes:$nf:$rep'));
  final k = Koach(
    copieJson(jm(d['params'])),
    fiches,
    copieJson(jm(d['profil'])),
  );
  final s = jm(k.params['securite']);
  final seuil = dbl(s['douleur_seuil']);
  final forte = dbl(s['douleur_forte_contrainte']);
  final moyenne = dbl(s['douleur_moyenne_contrainte']);
  final allegement = dbl(s['douleur_allegement']);
  final allegementSeries = dbl(s['douleur_allegement_series']);
  var douleurs = <String, int>{};
  var bas = false;
  var evenement = false;
  var verrou = false;
  var servis = <String, Json>{};
  var sansHausse = <String, bool>{};
  var grilles = <String, Object?>{};
  final chargeDerniere = <String, double>{};
  // (emplacement, haut de plage) -> charge de la première série de la
  // dernière séance (`Memoire.schemas`).
  final premieres = <String, double>{};
  // Emplacement -> charge de la dernière série versée au journal dans la
  // séance en cours (`plan['charge_item']`).
  var chargeItem = <String, double>{};
  String ctx(String quoi) => 'fixture $nf graine $rep : $quoi';

  for (final e0 in jl(d['journal'])) {
    final e = copieJson(jm(e0));
    final typ = e['type'];
    if (typ == 'seance_debut') {
      var b = jmOu(e['bilan']);
      if (r.next() < 0.6) {
        b = Map<String, Object?>.of(b ?? <String, Object?>{});
        final pl = List<Object?>.of(listeOuVide(b['pains']));
        final nP = 1 + _i(r, 2);
        for (var i = 0; i < nP; i++) {
          final zone = _zonesDouleur[_i(r, 13)];
          pl.add(<String, Object?>{'zone': zone, 'intensity': _i(r, 11)});
        }
        b['pains'] = pl;
      }
      if (r.next() < 0.25) {
        b = Map<String, Object?>.of(b ?? <String, Object?>{});
        b['overall'] = 1 + _i(r, 2);
      }
      e['bilan'] = b;
      douleurs = <String, int>{};
      for (final p in listeOuVide(b?['pains'])) {
        final pm = jm(p);
        final z = pm['zone']! as String;
        final i = ent(pm['intensity']);
        if (i > (douleurs[z] ?? -1)) {
          douleurs[z] = i;
        }
      }
      bas = b != null && b['overall'] != null && dbl(b['overall']) <= 2;
      evenement = vrai(dictOuVide(e['contexte'])['jour_evenement']);
      chargeItem = <String, double>{};
      k.observe(e);
      verrou = k.seances.verrouillee();
      continue;
    }
    if (typ == 'seance_fin') {
      if (r.next() < 0.2) {
        final dl = List<Object?>.of(listeOuVide(e['douleurs']));
        final zone = _zonesDouleur[_i(r, 13)];
        dl.add(<String, Object?>{'zone': zone, 'intensity': _i(r, 11)});
        e['douleurs'] = dl;
      }
      k.observe(e);
      // Charge la plus lourde du dernier passage de chaque exercice
      // (groupes exercice × emplacement dans l'ordre des séries).
      final groupes = <(String, Object?), List<Json>>{};
      for (final x in listeOuVide(dictOuVide(e['seance'])['sets'])) {
        final xm = jm(x);
        groupes
            .putIfAbsent((xm['exerciseId']! as String, xm['slotId']), () => [])
            .add(xm);
      }
      for (final g in groupes.entries) {
        double? der;
        for (final x in g.value) {
          final c = dblOu(x['externalLoadKg']);
          if (c != null && c >= 0 && (der == null || c > der)) {
            der = c;
          }
        }
        if (der != null) {
          chargeDerniere[g.key.$1] = der;
        }
        for (final x in g.value) {
          if (x['kind'] != 'warmup' &&
              x['externalLoadKg'] != null &&
              dictOuVide(x['target'])['role'] == null) {
            final hiP = dictOuVide(x['target'])['repsHigh'];
            premieres['${g.key.$1}|${g.key.$2}|${hiP == null ? null : dbl(hiP)}'] =
                dbl(x['externalLoadKg']);
            break;
          }
        }
      }
      continue;
    }
    if (typ == 'serie') {
      final se = jm(e['serie']);
      final cs = dblOu(se['externalLoadKg']);
      if (cs != null && cs >= 0 && se['slotId'] != null) {
        chargeItem[se['slotId']! as String] = cs;
      }
    }
    if (typ != 'plan') {
      k.observe(e);
      continue;
    }
    final c = jm(e['contraintes']);
    if (c['horizon'] == 'seance') {
      final out = jm(k.plan(c));
      final items = [for (final x in jl(out['items'])) jm(x)];
      final ecrits = <String, Json>{
        for (final w in jl(c['items'])) jm(w)['slotId']! as String: jm(w),
      };
      final zones = dictOuVide(c['zones']);
      servis = <String, Json>{for (final x in items) x['slotId']! as String: x};
      grilles = dictOuVide(c['grilles']);
      rel.entree();
      for (final x in items) {
        final sl = x['slotId']! as String;
        // Pas de test un jour de bilan bas, hors jour d'épreuve (A5.2).
        rel.verifier(
          !(bas && !evenement && x['kind'] == 'test'),
          () => ctx('test servi un jour de bilan bas ($sl)'),
        );
        if (sl.endsWith('.t')) {
          continue;
        }
        final w = ecrits[sl];
        rel.verifier(w != null, () => ctx('emplacement inconnu $sl'));
        if (w == null) {
          continue;
        }
        // Koach n'ajoute jamais de séries (A9.4).
        rel.verifier(
          _nb(x['sets']) <= _nb(w['sets']),
          () => ctx('séries $sl ${x['sets']} > ${w['sets']}'),
        );
      }
      final sh = <String, bool>{};
      for (final w in ecrits.values) {
        final ex = w['exerciseId']! as String;
        final z0 = zones[ex];
        final niv = z0 == null ? <String, Object?>{} : jm(jl(z0)[0]);
        final ft = fiches[ex]?['type'];
        final x = servis[w['slotId']];
        var douloureux = false;
        for (final dz in douleurs.entries) {
          final iz = dz.value;
          if (iz <= seuil) {
            continue;
          }
          final n = dbl(niv[dz.key] ?? 0.0);
          if (n < 0.5) {
            continue;
          }
          douloureux = true;
          final quoi = '${w['slotId']} zone ${dz.key} $iz niveau $n';
          // Test retiré sur une zone douloureuse sollicitée (A1.6, A2.2).
          rel.verifier(
            !(w['kind'] == 'test' && x != null),
            () => ctx('test gardé $quoi'),
          );
          // Retrait (A1.3), hors arrêt (premier palier de reprise, A2.2).
          if (!k.garde.arret(dz.key) &&
              ((n >= 1 && iz >= forte) || iz >= moyenne)) {
            rel.verifier(x == null, () => ctx('non retiré $quoi'));
          }
          // Allègement des séries (A1.4).
          if (iz >= allegement &&
              w['kind'] != 'warmup' &&
              w['kind'] != 'test' &&
              const ['charge', 'reps', 'tenue'].contains(ft) &&
              x != null) {
            final lim = math.max(
              1,
              (_nb(w['sets']) * allegementSeries + 1e-9).floor(),
            );
            rel.verifier(
              _nb(x['sets']) <= lim,
              () => ctx('allègement $quoi : ${x['sets']} > $lim'),
            );
          }
        }
        sh[w['slotId']! as String] = douloureux;
      }
      sansHausse = sh;
    } else if (c['horizon'] == 'serie') {
      final it = jm(c['item']);
      final sl = it['slotId']! as String;
      final ex = it['exerciseId']! as String;
      final out = jmOu(k.plan(c));
      final x = servis[sl];
      if (x == null ||
          sl.endsWith('.t') ||
          x['kind'] != 'work' ||
          fiches[ex]?['type'] != 'charge') {
        continue;
      }
      if (out == null || out['loadKg'] == null) {
        continue;
      }
      final charge = dbl(out['loadKg']);
      final g = jmOu(grilles[ex]);
      final mini = g == null ? 0.0 : dbl(g['minimum']);
      rel.entree();
      // Sous douleur : jamais plus lourd que le dernier passage de
      // l'exercice (A1.2, invariant I3 de 0.3.1).
      final cd = chargeDerniere[ex];
      if ((sansHausse[sl] ?? false) && cd != null) {
        rel.verifier(
          charge <= math.max(cd, mini) + 1e-9,
          () => ctx('hausse $sl : $charge > $cd'),
        );
      }
      // Bilan bas sans douleur (1.0.2, comme 0.3.1) : la première série ne
      // dépasse pas celle de la dernière séance du même schéma (emplacement,
      // haut de plage).
      // D'une série à l'autre, la charge reste gelée (au plus celle de la
      // dernière série faite).
      final hiI = it['repsHigh'] ?? it['repsLow'];
      final avant = premieres['$ex|$sl|${hiI == null ? null : dbl(hiI)}'];
      final ci = chargeItem[sl];
      if (bas && !(sansHausse[sl] ?? false)) {
        if (ent(c['index']) == 0 && avant != null) {
          rel.verifier(
            charge <= math.max(avant, mini) + 1e-9,
            () => ctx('hausse (bilan bas) $sl : $charge > $avant'),
          );
        }
        if (ent(c['index']) >= 1 && ci != null) {
          rel.verifier(
            charge <= math.max(ci, mini) + 1e-9,
            () => ctx('hausse (bilan bas, série) $sl : $charge > $ci'),
          );
        }
      }
      // Semaine verrouillée : la part écrite du 1RM borne la charge (A6.5),
      // au cran le plus proche de la grille.
      final part = x['percentOfOneRm'];
      final tech = dictOuVide(x['technique'])['kind'];
      final index = ent(c['index']);
      if (verrou &&
          part != null &&
          !(tech == 'top_set_backoff' && index >= 1) &&
          g != null) {
        final bw = k.modele.pistes[ex]!.fraction * k.modele.poidsKg;
        final haut = k.seances.chargeDePart(ex, dbl(part)) - bw;
        final grille = Grille(
          dbl(g['pas']),
          dbl(g['minimum']),
          vrai(g['halteres']),
        );
        final borne = math.max(grille.proche(math.max(haut, mini)), mini);
        rel.verifier(
          charge <= borne + 1e-9,
          () => ctx('verrou $sl index $index : $charge > $borne'),
        );
      }
    } else {
      k.plan(c);
    }
  }
}
