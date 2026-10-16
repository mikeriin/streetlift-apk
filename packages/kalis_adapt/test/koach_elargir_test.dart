// Élargissement « rien de spécial » plafonné à l'a priori (Koach 1.0.4, lot
// KR1 ; référence `reference/tests/test_rupture.py`,
// `test_elargir_multiplie_sous_l_a_priori` et
// `test_elargir_repete_plafonne_a_l_a_priori`) : variance nouvelle
// = min(facteur · v ; max(v ; v0)). Avant 1.0.4, des réponses répétées
// multipliaient la variance par le facteur à chaque diagnostic (écart-type de
// 20 en ln, `NaN` dans `Seances._cibleTenue` : 8 saisons plantées du banc sur
// `ks_test_ppl6`, séances manquées).
import 'dart:convert';
import 'dart:io';

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
(Modele, int) _observe() {
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
  return (m, t.idx);
}

double _v0(Modele m, int i) =>
    {for (final (j, v) in m.variancesAPriori()) j: v}[i]!;

void main() {
  test('sous l\'a priori : variance multipliée par le facteur', () {
    final (m, i) = _observe();
    final c = m.cap;
    final avant = m.pm[i * c + i];
    expect(4.0 * avant, lessThan(_v0(m, i)));
    m.elargir(4.0);
    expect((m.pm[i * c + i] - 4.0 * avant).abs(), lessThan(1e-12 * avant));
    for (var a = 0; a < m.n; a++) {
      for (var b = 0; b < m.n; b++) {
        expect(m.pm[a * c + b], m.pm[b * c + a]);
      }
    }
  });

  test('exercice jamais observé : variance à l\'a priori, inchangée', () {
    final m = _koach().modele;
    final t = m.piste(_ex)!;
    final c = m.cap;
    final avant = m.pm[t.idx * c + t.idx];
    final v0 = _v0(m, t.idx);
    m.elargir(4.0);
    final attendu = 4.0 * avant < v0 ? 4.0 * avant : (avant > v0 ? avant : v0);
    expect((m.pm[t.idx * c + t.idx] - attendu).abs(), lessThan(1e-12));
  });

  test('réponses répétées : plafond à l\'a priori, écart-type borné', () {
    final (m, i) = _observe();
    final c = m.cap;
    final sd0 = m.capacite(_ex)!.$2;
    final v0s = {for (final (j, v) in m.variancesAPriori()) j: v};
    final f = jm(_params['rupture'])['elargissement_rien_de_special'] as num;
    for (var k = 0; k < 30; k++) {
      m.elargir(f.toDouble());
    }
    for (final e in v0s.entries) {
      expect(m.pm[e.key * c + e.key], lessThanOrEqualTo(e.value * (1 + 1e-12)));
    }
    final (mu, sd) = m.capacite(_ex)!;
    expect(mu.isFinite, isTrue);
    expect(sd, lessThan(1.0));
    expect(sd, greaterThan(sd0));
    expect(m.elargi, 30);
    expect(i, isNonNegative);
  });
}
