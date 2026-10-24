// Koach 1.0.9 (lot KM7, DECISIONS_CP.md C17.54) : parité une à une avec la
// référence Python (`reference/tests/test_km7.py`, fixture
// `reference/fixtures/km7.json` de `generer_km7.py`) : bilan versé sans
// être appliqué (plan des seuls faits, forme apprise à la première série,
// douleur toujours appliquée), remplaçants classés et étiquetés, remplaçant
// versé servi à l'emplacement avec ses cibles, transfert de charge. Plus les
// fiches de remplacement construites depuis le catalogue (identiques au
// fichier lu par la référence).
//
// Données synthétiques seulement (C17.33).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart' show koachInfosRemplacement;
import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

import 'koach_parite_test.dart' show comparer, lireFixture;
import 'support.dart' show loadCatalog;

final Json _params =
    jsonDecode(File(koachFichierParametres).readAsStringSync()) as Json;

final Map<String, Json> _fiches = lireFichesKoach(
  File(koachFichierFiches).readAsStringSync(),
);

final List<Json> _infos = [
  for (final x in jl(
    jm(
      jsonDecode(
        utf8.decode(
          gzip.decode(
            File('reference/donnees/catalogue_infos.json.gz').readAsBytesSync(),
          ),
        ),
      ),
    )['exercises'],
  ))
    jm(x),
];

void main() {
  group('KM7 : parité avec la référence (fixtures/km7.json)', () {
    final fx = lireFixture('km7.json');
    for (final sc in jl(fx['scenarios'])) {
      final s = jm(sc);
      test('${s['nom']}', () {
        final k = Koach(
          copieJson(_params),
          _fiches,
          copieJson(jm(s['profil'])),
        );
        final ecarts = <String>[];
        var i = 0;
        for (final et0 in jl(s['etapes'])) {
          final et = jm(et0);
          final op = et['op'];
          if (op == 'observe') {
            k.observe(copieJson(jm(et['e'])));
          } else if (op == 'plan') {
            final r = k.plan(copieJson(jm(et['c'])));
            comparer(r, et['sortie'], 'etape[$i].plan', ecarts);
            comparer(k.explain(), et['raisons'], 'etape[$i].raisons', ecarts);
          } else if (op == 'remplacants') {
            final avant = jsonEncode(k.posterior());
            final r = k.remplacants(_infos, copieJson(jm(et['demande'])));
            comparer(r, et['sortie'], 'etape[$i].remplacants', ecarts);
            // Lecture seule.
            expect(jsonEncode(k.posterior()), avant);
          } else if (op == 'posterior') {
            comparer(
              k.posterior(),
              et['sortie'],
              'etape[$i].posterior',
              ecarts,
            );
          }
          i++;
        }
        expect(ecarts, isEmpty, reason: ecarts.join('\n'));
        // Le journal se rejoue à l'identique.
        final k2 = rejouer(
          copieJson(_params),
          _fiches,
          copieJson(jm(s['profil'])),
          k.journal,
        );
        final e2 = <String>[];
        comparer(
          k2.posterior(),
          jsonDecode(jsonEncode(k.posterior())),
          'rejeu',
          e2,
        );
        expect(e2, isEmpty, reason: e2.join('\n'));
      });
    }
  });

  group('KM7 : bilan versé sans être appliqué', () {
    test('drapeau et faits du bilan', () {
      expect(koachBilanApplique(null), isTrue);
      expect(koachBilanApplique(<String, Object?>{'overall': 2}), isTrue);
      expect(koachBilanApplique(<String, Object?>{'applique': true}), isTrue);
      expect(
        koachBilanApplique(<String, Object?>{'overall': 2, 'applique': false}),
        isFalse,
      );
      expect(
        koachFaitsDuBilan(<String, Object?>{
          'overall': 1,
          'sleepHours': 5,
          'energy': 2,
          'pains': <Object?>[],
          'applique': false,
          'minutesAvailable': 45,
        }),
        <String, Object?>{'pains': <Object?>[], 'minutesAvailable': 45},
      );
      expect(koachFaitsDuBilan(null), isNull);
    });

    test('plan non appliqué = plan des faits, bilan appliqué différent', () {
      final fx = lireFixture('km7.json');
      Json planJour11(String nom) {
        final s = jm(
          jl(fx['scenarios']).firstWhere((x) => jm(x)['nom'] == nom),
        );
        // Premier plan de séance du jour 11.
        var debut = false;
        for (final et0 in jl(s['etapes'])) {
          final et = jm(et0);
          if (et['op'] == 'observe' &&
              jm(et['e'])['type'] == 'seance_debut' &&
              jm(et['e'])['jour'] == 11) {
            debut = true;
          }
          if (debut &&
              et['op'] == 'plan' &&
              jm(et['c'])['horizon'] == 'seance') {
            return jm(et['sortie']);
          }
        }
        throw StateError(nom);
      }

      final non = planJour11('bilan_non_applique');
      final faits = planJour11('bilan_faits');
      final app = planJour11('bilan_applique');
      expect(jsonEncode(non), jsonEncode(faits));
      expect(jsonEncode(non) == jsonEncode(app), isFalse);
      expect([for (final it in jl(non['items'])) jm(it)['sets']], [6, 4]);
      expect([for (final it in jl(app['items'])) jm(it)['sets']], [5, 3]);
    });
  });

  group('KM7 : remplaçants', () {
    test('transferts, plages et unités', () {
      expect(koachTransfert('sl-dips-leste', 'sl-dips-barre-fixe-leste'), 0.9);
      expect(koachTransfert('sl-dips-barre-fixe-leste', 'sl-dips-leste'), 1.0);
      expect(
        koachTransfert('sl-dips-leste', 'mu-back-squat-barre-basse'),
        isNull,
      );
      expect(koachPlageConvertie(20.7), (16, 20));
      expect(koachPlageConvertie(0.4), (1, 1));
      expect(koachUniteFiche(_fiches['sl-dips-leste']!), 'charge_ajoutee');
      expect(koachUniteFiche(_fiches['sw-dips-barres-paralleles']!), 'reps');
      expect(koachUniteFiche(_fiches['cs-handstand']!), 'secondes');
    });

    test('table de transfert identique à celle de kalis_plan', () {
      // `coachLoadReferences` de kalis_plan 0.4.3 (tables.dart) : mêmes
      // couples, mêmes facteurs.
      final src = File(
        '../kalis_plan/lib/src/coach/tables.dart',
      ).readAsStringSync();
      expect(
        src,
        contains("'sl-traction-haute-lestee': (Ids.weightedPull, 0.85)"),
      );
      expect(
        src,
        contains("'sl-dips-barre-fixe-leste': (Ids.weightedDip, 0.9)"),
      );
      expect(
        src,
        contains("static const String weightedPull = 'sl-traction-lestee';"),
      );
      expect(
        src,
        contains("static const String weightedDip = 'sl-dips-leste';"),
      );
      expect(koachTransferts.length, 2);
    });

    test('fiches de remplacement du catalogue = fichier de la référence', () {
      final construites = {
        for (final x in koachInfosRemplacement(loadCatalog()))
          x['id'] as String: x,
      };
      final lues = {for (final x in _infos) x['id'] as String: x};
      expect(construites.keys.toSet(), lues.keys.toSet());
      final ecarts = <String>[];
      for (final e in construites.entries) {
        final lu = lues[e.key]!;
        final sous = <String, Object?>{for (final k in e.value.keys) k: lu[k]};
        comparer(e.value, sous, e.key, ecarts);
      }
      expect(ecarts, isEmpty, reason: ecarts.join('\n'));
    });
  });
}
