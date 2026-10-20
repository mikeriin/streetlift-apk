// Paramètres de Koach en assets JSON versionnés (lot KM2) : les assets
// `assets/koach/` sont des copies à l'octet près des fichiers de la
// référence Python, avec le SHA-256, la version et le nombre de clés du
// contrat (CONTRAT_1_0.md, en-tête et § 7) ; un moteur construit depuis les
// assets rejoue la fixture `moteur_1.json`.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:kalis_adapt/koach.dart';
import 'package:test/test.dart';

import 'koach_parite_test.dart' show comparer, diagnosticDe, lireFixture;

const String _referenceParametres = 'reference/params/koach_params_v1.json';
const String _referenceFiches = 'reference/qualites/vecteurs_qualites_v1.json';

List<int> _octets(String chemin) => File(chemin).readAsBytesSync();

String _texte(String chemin) => File(chemin).readAsStringSync();

/// Égalité stricte de deux valeurs JSON (mêmes doubles, NaN égal à NaN).
bool _identiques(Object? a, Object? b) {
  if (a is double && b is double && a.isNaN && b.isNaN) {
    return true;
  }
  if (a is num && b is num) {
    return a == b;
  }
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !_identiques(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (!_identiques(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  return a == b;
}

void main() {
  group('assets', () {
    test('copies à l\'octet près de la référence', () {
      expect(_octets(koachFichierParametres), _octets(_referenceParametres));
      expect(_octets(koachFichierFiches), _octets(_referenceFiches));
    });

    test('SHA-256 attendus', () {
      expect(
        sha256.convert(_octets(koachFichierParametres)).toString(),
        koachParametresSha256,
      );
      expect(
        sha256.convert(_octets(koachFichierFiches)).toString(),
        koachFichesSha256,
      );
      // En-tête du contrat 1.0.7 (CONTRAT_1_0.md).
      expect(
        koachParametresSha256,
        '2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c',
      );
    });

    test('clés des assets Flutter et chemins du paquet', () {
      expect(
        koachAssetParametres,
        'packages/kalis_adapt/$koachFichierParametres',
      );
      expect(koachAssetFiches, 'packages/kalis_adapt/$koachFichierFiches');
    });
  });

  group('lireParametresKoach', () {
    final p = lireParametresKoach(_texte(koachFichierParametres));

    test('version, schéma, nombre de clés (344 : 6 + 338)', () {
      expect(p['schema'], koachParametresSchema);
      expect(p['version'], koachParametresVersion);
      expect(koachParametresVersion, koachVersion);
      expect(koachVersion, '1.0.7-ref.1');
      final racine = [
        for (final e in p.entries)
          if (e.value is! Map<String, Object?>) e.key,
      ];
      final sections = [
        for (final e in p.entries)
          if (e.value is Map<String, Object?>) e.key,
      ];
      expect(racine, koachParametresRacine);
      expect(sections, koachParametresSections);
      var cles = racine.length;
      for (final s in sections) {
        cles += jm(p[s]).length;
      }
      expect(racine.length, 6);
      expect(cles - racine.length, 338);
      expect(cles, koachParametresCles);
      expect(cles, 344);
    });

    test('identique au fichier de référence décodé', () {
      final ref = jsonDecode(_texte(_referenceParametres)) as Json;
      expect(_identiques(p, ref), isTrue);
    });

    test('mêmes paramètres que les fixtures de parité', () {
      final f = lireFixture('moteur_1.json');
      expect(_identiques(p, jm(jm(f['entrees'])['params'])), isTrue);
      expect(f['version_parametres'], koachParametresVersion);
      expect(f['sha256_fichier_parametres'], koachParametresSha256);
      expect(f['version_moteur'], koachVersion);
    });

    Json modifie(void Function(Json p) f) {
      final q = copieJson(p);
      f(q);
      return q;
    }

    void refuse(Json q, String motif) {
      expect(
        () => lireParametresKoach(jsonEncode(q)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains(motif),
          ),
        ),
      );
    }

    test('refus : JSON invalide, racine, schéma, majeure, sections', () {
      expect(() => lireParametresKoach('{'), throwsA(isA<FormatException>()));
      expect(() => lireParametresKoach('[]'), throwsA(isA<FormatException>()));
      refuse(modifie((q) => q['schema'] = 2), 'schema');
      refuse(modifie((q) => q['version'] = '2.0.0-ref.1'), 'version');
      refuse(modifie((q) => q['version'] = 1), 'version');
      refuse(modifie((q) => q['note'] = 3), 'type: note');
      refuse(modifie((q) => q.remove('rupture')), 'section_absente: rupture');
      refuse(
        modifie((q) => q['autre'] = <String, Object?>{}),
        'section_inconnue',
      );
      refuse(
        modifie((q) => q['qualites'] = jl(q['qualites']).sublist(1)),
        'qualites',
      );
    });

    test('refus : bornes et positivité de la validation d\'import', () {
      refuse(
        modifie((q) => jm(q['rupture'])['alerte'] = 1.5),
        'borne: rupture.alerte',
      );
      refuse(
        modifie((q) => jm(q['mesure'])['note_aberrante'] = 0.0),
        'borne: mesure.note_aberrante',
      );
      final sd = jm(p['a_priori']).keys.firstWhere(
        (k) => k.endsWith('_sd') && jm(p['a_priori'])[k] is num,
      );
      refuse(
        modifie((q) => jm(q['a_priori'])[sd] = 0.0),
        'borne: a_priori.$sd',
      );
    });

    test(
      'refus : bornes et garde-fous de 1.0.3 (CHANGEMENTS_1_0_3.md § D)',
      () {
        refuse(
          modifie((q) => jm(q['mesure'])['defaut_modele_sd'] = 0.0),
          'borne: mesure.defaut_modele_sd',
        );
        refuse(
          modifie((q) => jm(q['mesure'])['fiabilite_oubli'] = 1.0),
          'borne: mesure.fiabilite_oubli',
        );
        refuse(
          modifie((q) => jm(q['mesure'])['fiabilite_elargissement_max'] = 0.5),
          'borne: mesure.fiabilite_elargissement_max',
        );
        refuse(
          modifie((q) => jm(q['mesure'])['fiabilite_schema_reps'] = 31),
          'borne: mesure.fiabilite_schema_reps',
        );
        refuse(
          modifie(
            (q) => jm(q['planification'])['prudence_charge_fiabilite'] = 6.0,
          ),
          'borne: planification.prudence_charge_fiabilite',
        );
        // Grille et a priori de la fiabilité : figés à l'import (validation
        // contre les paramètres en cours).
        for (final (cle, v) in <(String, Object?)>[
          ('fiabilite_phi_min', 0.25),
          ('fiabilite_phi_max', 4.0),
          ('fiabilite_phi_points', 15),
          ('fiabilite_ln_phi_sd', 0.6),
          ('fiabilite_non_notee_a_priori', <Object?>[2.0, 4.0]),
        ]) {
          final q = modifie((x) => jm(x['mesure'])[cle] = v);
          expect(
            validerParametres(p, q),
            contains('fige: mesure.$cle (garde-fou, modification interdite)'),
            reason: cle,
          );
        }
        final q = modifie((x) => jm(x['mesure'])['fiabilite_oubli'] = 0.95);
        expect(validerParametres(p, q), isEmpty);
      },
    );

    test('1.0.5 (KM1c4, règle 5) : part vers l\'a priori bornée à [0 ; 1], '
        'ancien facteur retiré (1.0.6)', () {
      expect(jm(p['rupture'])['elargissement_vers_a_priori'], 0.25);
      refuse(
        modifie((q) => jm(q['rupture'])['elargissement_vers_a_priori'] = 1.5),
        'borne: rupture.elargissement_vers_a_priori',
      );
      refuse(
        modifie((q) => jm(q['rupture'])['elargissement_vers_a_priori'] = -0.1),
        'borne: rupture.elargissement_vers_a_priori',
      );
      // `elargissement_rien_de_special` retirée en 1.0.6 (KM4, C17.29.2).
      expect(
        jm(p['rupture']).containsKey('elargissement_rien_de_special'),
        isFalse,
      );
    });

    test('une version mineure différente est admise', () {
      final q = modifie((x) => x['version'] = '1.7.0-ref.3');
      expect(lireParametresKoach(jsonEncode(q))['version'], '1.7.0-ref.3');
    });
  });

  group('lireFichesKoach', () {
    final fiches = lireFichesKoach(_texte(koachFichierFiches));

    test('1 039 fiches, identiques aux fiches des fixtures', () {
      expect(fiches.length, 1039);
      final ref = jm(jm(jsonDecode(_texte(_referenceFiches)))['exercices']);
      expect(fiches.keys.toList(), ref.keys.toList());
      for (var n = 1; n <= 10; n++) {
        final f = jm(jm(lireFixture('moteur_$n.json')['entrees'])['fiches']);
        for (final e in f.entries) {
          expect(_identiques(fiches[e.key], e.value), isTrue, reason: e.key);
        }
      }
    });

    test('refus : racine, schéma, exercices', () {
      expect(() => lireFichesKoach('[]'), throwsA(isA<FormatException>()));
      expect(
        () => lireFichesKoach('{"schema": 2, "exercices": {}}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => lireFichesKoach('{"schema": 1, "exercices": []}'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => lireFichesKoach(
          '{"schema": 1, "exercices": {"x": {"type": "reps", "vecteur": [1]}}}',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('un moteur construit depuis les assets rejoue moteur_1.json', () {
    final params = lireParametresKoach(_texte(koachFichierParametres));
    final fiches = lireFichesKoach(_texte(koachFichierFiches));
    final f = lireFixture('moteur_1.json');
    final e = jm(f['entrees']);
    final journal = [for (final x in jl(e['journal'])) jm(x)];
    final att = jm(f['attendu']);
    final plans = <int, Json>{
      for (final x in jl(att['plans'])) ent(jm(x)['indice']): jm(x),
    };
    final instantanes = <int, Json>{
      for (final x in jl(att['instantanes'])) ent(jm(x)['indice']): jm(x),
    };
    // Témoin : le moteur construit depuis les entrées de la fixture
    // (fiches réduites aux exercices lus).
    final fichesFixture = <String, Json>{
      for (final x in jm(e['fiches']).entries) x.key: jm(x.value),
    };
    final k = Koach(params, fiches, copieJson(jm(e['profil'])));
    final t = Koach(
      copieJson(jm(e['params'])),
      fichesFixture,
      copieJson(jm(e['profil'])),
    );
    final ecarts = <String>[];
    for (var i = 0; i < journal.length; i++) {
      final ev = journal[i];
      if (ev['type'] == 'plan') {
        final sortie = k.plan(copieJson(jm(ev['contraintes'])));
        final temoin = t.plan(copieJson(jm(ev['contraintes'])));
        expect(_identiques(sortie, temoin), isTrue, reason: 'plan $i');
        comparer(sortie, plans[i]!['sortie'], 'plan[$i].sortie', ecarts);
        comparer(k.explain(), plans[i]!['raisons'], 'plan[$i].raisons', ecarts);
      } else {
        k.observe(copieJson(ev));
        t.observe(copieJson(ev));
      }
      final inst = instantanes[i];
      if (inst != null) {
        expect(
          _identiques(k.posterior(), t.posterior()),
          isTrue,
          reason: 'posterior $i',
        );
        comparer(k.posterior(), inst['posterior'], 'posterior[$i]', ecarts);
      }
      if (ecarts.isNotEmpty) {
        fail('événement $i (${ev['type']}) :\n${ecarts.join('\n')}');
      }
    }
    final fin = jm(att['final']);
    comparer(k.posterior(), fin['posterior'], 'final.posterior', ecarts);
    comparer(k.explain(), fin['raisons'], 'final.raisons', ecarts);
    comparer(diagnosticDe(k), fin['diagnostic'], 'final.diagnostic', ecarts);
    comparer(k.journal, journal, 'journal', ecarts);
    expect(ecarts, isEmpty, reason: ecarts.join('\n'));
    expect(_identiques(diagnosticDe(k), diagnosticDe(t)), isTrue);
    expect(_identiques(k.journal, t.journal), isTrue);
  });
}
