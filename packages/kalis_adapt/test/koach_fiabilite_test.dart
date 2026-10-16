// Fiabilité des notes (Koach 1.0.3, lot KM2c2 ; référence
// `reference/tests/test_fiabilite.py`, contrat § 5.13) : indicateur
// bayésien (φ, part non notée, oubli), élargissement de l'incertitude des
// capacités sans déplacement de leur moyenne. Les cas de la référence qui
// remplacent `elargissement` par une fonction (prudence ciblée, échelle des
// tentatives, jumeau) sont couverts par la parité (`moteur_12.json` : κ
// jusqu'à 1,4, palier et marge des barres, barre suivante après un échec).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

const String _ex = 'mu-back-squat-barre-basse';

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

Koach _koach([Json? params]) =>
    Koach(copieJson(params ?? _params), _fiches, <String, Object?>{
      'niveau': 2,
      'sexe': 'male',
      'poids_kg': 80.0,
      'declares': <String, Object?>{
        _ex: <Object?>['one_rm_kg', 150.0],
      },
      'zones_fragiles': <Object?>[],
    });

Json _serie(
  double charge,
  int reps,
  int? flammes, {
  bool failed = false,
  int? hi,
}) => <String, Object?>{
  'exerciseId': _ex,
  'slotId': 's1',
  'externalLoadKg': charge,
  'reps': reps,
  'flames': flammes,
  'failed': failed,
  'restSeconds': 120,
  'target': <String, Object?>{
    'repsLow': reps,
    'repsHigh': hi ?? reps,
    'flames': 7,
    'role': null,
  },
};

Json _debut(int jour) => <String, Object?>{
  'type': 'seance_debut',
  'jour': jour,
  'contexte': <String, Object?>{'semaine': jour ~/ 7, 'genre': 'accumulation'},
};

/// Huit séances de 4 × 5 à 110 kg ; [notes] : flammes par série (null :
/// non notée).
Modele _journal(Koach k, List<int?> notes) {
  for (final j in const [7, 10, 14, 17, 21, 24, 28, 31]) {
    k.observe(_debut(j));
    for (var i = 0; i < 4; i++) {
      k.observe(<String, Object?>{
        'type': 'serie',
        'serie': _serie(110.0, 5, notes[i % notes.length]),
      });
    }
    k.observe(<String, Object?>{
      'type': 'seance_fin',
      'seance': <String, Object?>{'sets': <Object?>[]},
    });
  }
  return k.modele;
}

Json _avec(void Function(Json mesure) f) {
  final p = copieJson(_params);
  f(jm(p['mesure']));
  return p;
}

double _sommeExp(List<double> lp) {
  var s = 0.0;
  for (final x in lp) {
    s += math.exp(x);
  }
  return s;
}

void main() {
  group('indicateur', () {
    test('a priori centré sur 1 et grille', () {
      final f = Fiabilite(_params);
      final me = jm(_params['mesure']);
      expect(f.phi.length, me['fiabilite_phi_points']);
      expect(
        (f.phi.first - dbl(me['fiabilite_phi_min'])).abs(),
        lessThan(1e-12),
      );
      expect((f.phi.last - dbl(me['fiabilite_phi_max'])).abs(), lessThan(1e-9));
      expect((_sommeExp(f.lp) - 1.0).abs(), lessThan(1e-12));
      expect(f.lnPhiMoyen().abs(), lessThan(1e-9));
      expect(f.phiMoyen(), greaterThan(1.0));
      expect(f.elargissement(), 1.0);
      expect((f.partNonNotee() - 0.2).abs(), lessThan(1e-12));
    });

    test('notes justes abaissent φ, notes fausses et ouvertes contredites '
        'l\'élèvent', () {
      final juste = Fiabilite(_params);
      final faux = Fiabilite(_params);
      final ouverte = Fiabilite(_params);
      for (var i = 0; i < 40; i++) {
        juste.noter(2.0, 0.2, 1.75, 2.25, 1.0, 0.0, 0.95, 0.005, false);
        faux.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, false);
        ouverte.noter(
          0.3,
          0.2,
          3.75,
          double.infinity,
          1.0,
          0.0,
          0.95,
          0.005,
          true,
        );
      }
      expect(juste.phiMoyen(), lessThan(1.0));
      expect(faux.phiMoyen(), greaterThan(2.0));
      expect(ouverte.phiMoyen(), greaterThan(2.0));
      expect(ouverte.notesS, [40, 0]);
    });

    test('l\'oubli réhabilite un athlète qui apprend à noter', () {
      final f = Fiabilite(_params);
      for (var i = 0; i < 40; i++) {
        f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, false);
      }
      final haut = f.phiMoyen();
      for (var i = 0; i < 120; i++) {
        f.noter(2.0, 0.2, 1.75, 2.25, 1.0, 0.0, 0.95, 0.005, false);
      }
      expect(haut, greaterThan(2.0));
      expect(f.phiMoyen(), lessThan(1.2));
    });

    test('une note paresseuse ne dit rien', () {
      final f = Fiabilite(_params);
      final avant = List<double>.of(f.lp);
      f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.0, 1.0, false);
      for (var k = 0; k < avant.length; k++) {
        expect((avant[k] - f.lp[k]).abs(), lessThan(1e-12));
      }
    });

    test('part non notée : Beta avec oubli', () {
      final f = Fiabilite(_params);
      for (var i = 0; i < 50; i++) {
        f.serie(false, false);
      }
      expect(f.partNonNotee(), greaterThan(0.85));
      for (var i = 0; i < 200; i++) {
        f.serie(true, false);
      }
      expect(f.partNonNotee(), lessThan(0.1));
    });

    test('formule de κ et résumé', () {
      final p = _avec((me) {
        me['fiabilite_elargissement_phi'] = 0.5;
        me['fiabilite_elargissement_non_notee'] = 2.0;
      });
      final f = Fiabilite(p);
      for (var i = 0; i < 60; i++) {
        f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, false);
        f.serie(false, false);
        f.serie(true, false);
      }
      final phi = f.phiMoyen();
      final nn = f.partNonNotee();
      final attendu = math.sqrt(
        1.0 + 0.5 * (phi - f.phi0) + 2.0 * math.pow(nn - 0.2, 2),
      );
      expect((f.elargissement() - attendu).abs(), lessThan(1e-12));
      expect(f.elargissement(), greaterThan(1.1));
      expect(f.resume().keys.toSet(), {
        'phi',
        'ln_phi',
        'p_phi_sup_2',
        'notes',
        'part_non_notee',
        'elargissement',
        'par_schema',
      });
    });

    test('P(φ ≥ seuil) inclut le point de grille', () {
      final f = Fiabilite(_params);
      var s = 0.0;
      for (var k = 0; k < f.phi.length; k++) {
        if (f.phi[k] >= 2.0 - 1e-9) {
          s += math.exp(f.lp[k]);
        }
      }
      expect((f.probaPhiSup(2.0) - s).abs(), lessThan(1e-12));
      expect(f.probaPhiSup(2.0), greaterThan(f.probaPhiSup(2.83)));
    });

    test('κ plafonné', () {
      final p = _avec((me) => me['fiabilite_elargissement_non_notee'] = 1000.0);
      final f = Fiabilite(p);
      for (var i = 0; i < 100; i++) {
        f.serie(false, false);
      }
      expect(f.elargissement(), 2.0);
      expect(jm(p['mesure'])['fiabilite_elargissement_max'], 2.0);
    });
  });

  group('dans le moteur', () {
    test('moyenne intacte, incertitude élargie', () {
      final p0 = _avec((me) {
        me['fiabilite_elargissement_phi'] = 0.0;
        me['fiabilite_elargissement_non_notee'] = 0.0;
      });
      final p1 = _avec((me) {
        me['fiabilite_elargissement_phi'] = 1.0;
        me['fiabilite_elargissement_non_notee'] = 3.0;
      });
      const fiable = <int?>[3, 5, 5, 3];
      const douteux = <int?>[10, null, 3, null];
      for (final notes in const [fiable, douteux]) {
        final m0 = _journal(_koach(p0), notes);
        final m1 = _journal(_koach(p1), notes);
        final c0 = m0.capacite(_ex)!;
        final c1 = m1.capacite(_ex)!;
        final j0 = m0.capaciteDuJour(_ex)!;
        final j1 = m1.capaciteDuJour(_ex)!;
        expect((c0.$1 - c1.$1).abs(), lessThan(1e-12));
        expect((j0.$1 - j1.$1).abs(), lessThan(1e-12));
        expect(m0.n, m1.n);
        for (var i = 0; i < m0.n; i++) {
          expect((m0.m[i] - m1.m[i]).abs(), lessThan(1e-12));
          for (var j = 0; j < m0.n; j++) {
            expect((m0.pget(i, j) - m1.pget(i, j)).abs(), lessThan(1e-12));
          }
        }
        expect(m0.elargissement(), 1.0);
        final k1 = m1.elargissement();
        if (identical(notes, fiable)) {
          expect(k1, 1.0);
          expect((c0.$2 - c1.$2).abs(), lessThan(1e-12));
          expect((j0.$2 - j1.$2).abs(), lessThan(1e-12));
        } else {
          expect(k1, greaterThan(1.1));
          expect(c1.$2, greaterThan(c0.$2));
          expect((j1.$2 / j0.$2 - k1).abs(), lessThan(1e-9));
          expect(
            (m1.capacite(_ex, brut: true)!.$2 -
                    m0.capacite(_ex, brut: true)!.$2)
                .abs(),
            lessThan(1e-12),
          );
          expect(
            (m1.capaciteDuJour(_ex, brut: true)!.$2 - j0.$2).abs(),
            lessThan(1e-12),
          );
        }
      }
    });

    test('échauffements et échecs hors de l\'indicateur ; φ contre le bruit '
        'de population ; série lourde selon repsHigh', () {
      final k = _koach();
      k.observe(_debut(7));
      final chauffe = _serie(60.0, 5, null)..['kind'] = 'warmup';
      k.observe(<String, Object?>{'type': 'serie', 'serie': chauffe});
      k.observe(<String, Object?>{
        'type': 'serie',
        'serie': _serie(110.0, 0, 10, failed: true),
      });
      k.observe(<String, Object?>{
        'type': 'serie',
        'serie': _serie(110.0, 3, 10, failed: true),
      });
      final f = k.modele.fiabilite;
      expect(f.notes, 0);
      expect(f.nn, f.nn0);
      expect(f.notesS, [0, 0]);
      k.observe(<String, Object?>{
        'type': 'serie',
        'serie': _serie(110.0, 5, null),
      });
      expect(f.notes, 0);
      expect(f.nn[0], greaterThan(f.nn0[0]));

      final k1 = _koach();
      final k2 = _koach();
      for (final kk in [k1, k2]) {
        kk.observe(_debut(7));
      }
      k2.modele.bruitRir = 2.0;
      for (final kk in [k1, k2]) {
        kk.observe(<String, Object?>{
          'type': 'serie',
          'serie': _serie(110.0, 5, 7),
        });
      }
      for (var i = 0; i < k1.modele.fiabilite.lp.length; i++) {
        expect(
          (k1.modele.fiabilite.lp[i] - k2.modele.fiabilite.lp[i]).abs(),
          lessThan(1e-12),
        );
      }

      final k3 = _koach();
      k3.observe(_debut(7));
      k3.observe(<String, Object?>{
        'type': 'serie',
        'serie': _serie(110.0, 5, 7, hi: 8),
      });
      expect(k3.modele.fiabilite.notesS, [0, 1]);
    });

    test('posterior expose la fiabilité', () {
      final k = _koach();
      _journal(k, const [10, null, 3, null]);
      final r = jm(k.posterior()['fiabilite']);
      expect(r['notes'], 16);
      expect(dbl(r['part_non_notee']), greaterThan(0.3));
      expect(dbl(r['phi']), greaterThan(1.0));
      expect(dbl(r['elargissement']), greaterThanOrEqualTo(1.0));
      expect(jm(r['par_schema']).containsKey('lourd'), isTrue);
    });

    test(
      'import : l\'oubli et les coefficients sont relus, la grille reste',
      () {
        final k = _koach();
        _journal(k, const [10, null, 3, null]);
        final avant = k.modele.elargissement();
        final q = copieJson(_params);
        jm(q['mesure'])['fiabilite_elargissement_non_notee'] = 0.0;
        jm(q['mesure'])['fiabilite_elargissement_phi'] = 0.0;
        expect(validerParametres(k.params, q), isEmpty);
        appliquerParametres(k, q);
        expect(identical(k.modele.fiabilite.p, jm(k.params['mesure'])), isTrue);
        expect(avant, greaterThan(1.0));
        expect(k.modele.elargissement(), 1.0);
      },
    );
  });
}
