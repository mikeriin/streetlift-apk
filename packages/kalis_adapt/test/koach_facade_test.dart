// Façade de Koach 1.0.0 (KM2) : forme d'adhérence (`proposition`) et
// journal robuste. Les journaux des fixtures de parité sont rejoués avec une
// extension `Adherence` : la forme ne change aucune charge servie, ne vise
// que les séries de travail et ne présente jamais une baisse imposée par la
// sécurité comme une suggestion.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

Json _lire(String nom) =>
    jsonDecode(File('reference/fixtures/$nom').readAsStringSync()) as Json;

void main() {
  test('proposition : charges inchangées, travail seulement, pas de baisse '
      'de sécurité', () {
    var propositions = 0;
    for (var n = 1; n <= 11; n++) {
      final f = _lire('moteur_$n.json');
      final e = jm(f['entrees']);
      final fiches = <String, Json>{
        for (final x in jm(e['fiches']).entries) x.key: jm(x.value),
      };
      final params = copieJson(jm(e['params']));
      final temoin = Koach(params, fiches, copieJson(jm(e['profil'])));
      final k = Koach(copieJson(params), fiches, copieJson(jm(e['profil'])));
      k.extensions.add(Adherence(params));
      for (final ev0 in jl(e['journal'])) {
        final ev = copieJson(jm(ev0));
        if (ev['type'] != 'plan') {
          temoin.observe(copieJson(ev));
          k.observe(ev);
          continue;
        }
        final c = jm(ev['contraintes']);
        final a = temoin.plan(copieJson(c));
        final b = k.plan(copieJson(c));
        if (c['horizon'] != 'serie') {
          expect(jsonEncode(b), jsonEncode(a), reason: 'moteur_$n');
          continue;
        }
        if (b == null) {
          expect(a, isNull);
          continue;
        }
        final bm = Map<String, Object?>.of(jm(b));
        final p = bm.remove('proposition');
        expect(jsonEncode(bm), jsonEncode(a), reason: 'moteur_$n');
        if (p == null) {
          continue;
        }
        propositions++;
        final pm = jm(p);
        final item = jm(c['item']);
        expect(item['kind'] ?? 'work', 'work');
        expect(ent(c['index']), 0);
        expect(jm(b)['role'], isNull);
        expect(dbl(pm['cible']), dbl(jm(b)['loadKg']));
        expect(pm['type'], anyOf('charge_plus', 'charge_moins'));
        if (pm['type'] == 'charge_moins') {
          expect(k.garde.actives(), isEmpty, reason: 'moteur_$n');
          expect(k.seances.palier, 0, reason: 'moteur_$n');
        }
        final paliers = jl(pm['paliers']);
        expect(dbl(paliers.last), dbl(pm['cible']));
      }
      // L'extension ne change pas l'estimation.
      expect(
        jsonEncode(k.posterior()),
        jsonEncode(temoin.posterior()),
        reason: 'moteur_$n',
      );
    }
    expect(propositions, greaterThan(0));
  });

  test('un événement qui échoue ne reste pas au journal', () {
    final f = _lire('moteur_1.json');
    final e = jm(f['entrees']);
    final fiches = <String, Json>{
      for (final x in jm(e['fiches']).entries) x.key: jm(x.value),
    };
    final k = Koach(
      copieJson(jm(e['params'])),
      fiches,
      copieJson(jm(e['profil'])),
    );
    expect(
      () => k.plan(<String, Object?>{'horizon': 'inconnu'}),
      throwsArgumentError,
    );
    expect(k.journal, isEmpty);
    expect(
      () => k.observe(<String, Object?>{'type': 'cran', 'facteur': 1.2}),
      throwsA(anything),
    );
    expect(k.journal, isEmpty);
  });
}
