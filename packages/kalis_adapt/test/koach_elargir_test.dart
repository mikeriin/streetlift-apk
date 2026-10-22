// Élargissement « rien de spécial » uniforme et borné (Koach 1.0.5, lot
// KM1c4, règle 5 ; portage KM2c3 ; référence `reference/tests/test_rupture.py`,
// `test_elargir_uniforme_vers_l_a_priori`,
// `test_elargir_repete_borne_par_l_a_priori` et
// `test_elargir_bornes_et_branche_mauvais_jour`) : mélange convexe
// P ← (1 − λ) P + λ · diag(v0) sur les composantes de capacité, toutes
// branches. 1.0.4 (KR1) plafonnait chaque composante à son a priori : le
// facteur sur la variance d'une capacité allait de 1,0 à 8,6 selon les
// composantes plafonnées.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

const String _ex = 'mu-back-squat-barre-basse';

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

Koach _koach() => Koach(copieJson(_params), _fiches, <String, Object?>{
  'niveau': 1,
  'sexe': 'male',
  'poids_kg': 80.0,
  'declares': <String, Object?>{},
  'zones_fragiles': <Object?>[],
});

/// Modèle dont l'exercice [_ex] a été « observé » : sa composante propre
/// ramenée bien sous l'a priori (comme `_modele_observe` de la référence).
(Modele, Piste) _observe() {
  final m = _koach().modele;
  final t = m.piste(_ex)!;
  final c = m.cap;
  for (var k = 0; k < 6; k++) {
    for (var j = 0; j < c; j++) {
      m.pm[t.idx * c + j] *= 0.3;
    }
    for (var j = 0; j < c; j++) {
      m.pm[j * c + t.idx] *= 0.3;
    }
  }
  return (m, t);
}

double _lambda() => dbl(jm(_params['rupture'])['elargissement_vers_a_priori']);

void main() {
  test('uniforme vers l\'a priori : (1 − λ) v + λ v0, croisés × (1 − λ)', () {
    final (m, _) = _observe();
    final c = m.cap;
    final lam = _lambda();
    expect(lam, 0.25);
    final p0 = List<double>.of(m.pm);
    final v0s = {for (final (j, v) in m.variancesAPriori()) j: v};
    m.elargir(lam);
    for (var i = 0; i < m.n; i++) {
      for (var j = 0; j < m.n; j++) {
        double attendu;
        if (v0s.containsKey(i) && v0s.containsKey(j)) {
          attendu = (1 - lam) * p0[i * c + j] + (i == j ? lam * v0s[i]! : 0.0);
        } else if (v0s.containsKey(i) || v0s.containsKey(j)) {
          attendu = (1 - lam) * p0[i * c + j];
        } else {
          attendu = p0[i * c + j];
        }
        final tol = 1e-12 * (attendu.abs() > 1.0 ? attendu.abs() : 1.0);
        expect((m.pm[i * c + j] - attendu).abs(), lessThanOrEqualTo(tol));
        expect(m.pm[i * c + j], m.pm[j * c + i]);
      }
    }
    expect(m.elargi, 1);
  });

  test('réponses répétées : convergence vers l\'a priori, jamais au-delà', () {
    final (m, t) = _observe();
    final c = m.cap;
    final sd0 = m.capacite(_ex, brut: true)!.$2;
    final v0s = {for (final (j, v) in m.variancesAPriori()) j: v};
    final lam = _lambda();
    final (idx, co) = m.hCapacite(t, jour: false);
    var v0Cap = 0.0;
    for (var k = 0; k < idx.length; k++) {
      final v0 = v0s[idx[k]];
      if (v0 != null) {
        v0Cap += co[k] * co[k] * v0;
      }
    }
    for (var k = 0; k < 30; k++) {
      m.elargir(lam);
    }
    for (final e in v0s.entries) {
      final v = m.pm[e.key * c + e.key];
      expect(v, lessThanOrEqualTo(e.value * (1 + 1e-12)));
      expect((v - e.value).abs(), lessThanOrEqualTo(1e-3 * e.value));
    }
    final (mu, sd) = m.capacite(_ex, brut: true)!;
    expect(mu.isFinite, isTrue);
    expect(sd, lessThan(1.0));
    expect(sd, greaterThan(sd0));
    final ds = dbl(jm(_params['mesure'])['defaut_modele_sd'] ?? 0.0);
    expect(sd * sd - ds * ds, lessThanOrEqualTo(v0Cap * (1 + 1e-9)));
    expect(m.elargi, 30);
  });

  test('λ borné à [0 ; 1] ; branche « mauvais jour » élargie aussi', () {
    var (m, t) = _observe();
    final c = m.cap;
    final v0s = {for (final (j, v) in m.variancesAPriori()) j: v};
    final p0 = List<double>.of(m.pm);
    m.elargir(-0.3);
    expect(List<double>.of(m.pm), p0);
    m.elargir(1.7);
    for (final e in v0s.entries) {
      final i = e.key;
      expect(
        (m.pm[i * c + i] - e.value).abs(),
        lessThanOrEqualTo(1e-12 * e.value),
      );
      for (var j = 0; j < m.n; j++) {
        if (j != i) {
          expect(m.pm[i * c + j], 0.0);
        }
      }
    }
    // Séance ouverte avec un bilan bas : branche alt présente.
    (m, t) = _observe();
    m.debutSeance(10, <String, Object?>{
      'overall': 1,
      'sleepQuality': 2,
      'energy': 2,
    }, null);
    expect(m.altOuverte, isTrue);
    final lam = _lambda();
    final (idx, co) = m.hCapacite(t, jour: false);
    var v0Cap = 0.0;
    for (var k = 0; k < idx.length; k++) {
      final v0 = v0s[idx[k]];
      if (v0 != null) {
        v0Cap += co[k] * co[k] * v0;
      }
    }
    double variance(Float64List mm, Float64List pp) =>
        Modele.stats(mm, pp, m.cap, idx, co).$2;
    final avant = [variance(m.m, m.pm), variance(m.altM!, m.altP!)];
    m.elargir(lam);
    final apres = [variance(m.m, m.pm), variance(m.altM!, m.altP!)];
    for (var k = 0; k < 2; k++) {
      final attendu = (1 - lam) * avant[k] + lam * v0Cap;
      final tol = 1e-12 * (apres[k] > 1.0 ? apres[k] : 1.0);
      expect((apres[k] - attendu).abs(), lessThanOrEqualTo(tol));
    }
  });
}
