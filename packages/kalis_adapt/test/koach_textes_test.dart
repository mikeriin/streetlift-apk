// Textes de Koach (lot KM2, pour KM3 ; `docs/INTEGRATION_KM3.md`, § 4) :
// chaque code émis par Koach a une phrase française lisible, jamais un code
// brut. Sources : les raisons attendues des 11 fixtures de parité
// (`reference/fixtures/moteur_*.json`), le tableau du contrat (§ 3.5), les
// causes relevées dans le code, la surveillance (questions, choix, actions
// rendues par `Surveillance.repondre`) et les raisons du contrôle dual.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/koach.dart';
import 'package:kalis_adapt/koach_textes.dart';
import 'package:test/test.dart';

/// Nom affiché d'essai, le même pour tout exercice.
const String _nomEssai = 'Mouvement test';

String? _nom(String id) => _nomEssai;

/// Phrase lisible : non vide, sans code `koach.`, sans accolade, sans
/// identifiant à tiret bas ni `null`.
void _lisible(String texte, String quoi) {
  final r = '$quoi : « $texte »';
  expect(texte.trim(), isNotEmpty, reason: r);
  expect(texte.contains('koach.'), isFalse, reason: r);
  expect(texte.contains('{'), isFalse, reason: r);
  expect(texte.contains('}'), isFalse, reason: r);
  expect(texte.contains('_'), isFalse, reason: r);
  expect(texte.contains('null'), isFalse, reason: r);
}

Json _fixture(int i) {
  final f = File('reference/fix_dart/moteur_$i.json');
  return jm(jsonDecode(f.readAsStringSync()));
}

/// Raisons `koach.*` attendues des 11 fixtures : `plans[].raisons`,
/// `final.raisons` et les `reasons` des items servis.
List<Json> _raisonsDesFixtures() {
  final out = <Json>[];
  for (var i = 1; i <= 11; i++) {
    final attendu = jm(_fixture(i)['attendu']);
    for (final p0 in jl(attendu['plans'])) {
      final p = jm(p0);
      for (final r in listeOuVide(p['raisons'])) {
        out.add(jm(r));
      }
      final sortie = p['sortie'];
      if (sortie is Map<String, Object?>) {
        for (final it in listeOuVide(sortie['items'])) {
          for (final r in listeOuVide(jm(it)['reasons'])) {
            final code = jm(r)['code'];
            if (code is String && code.startsWith('koach.')) {
              out.add(jm(r));
            }
          }
        }
      }
    }
    final fin = attendu['final'];
    if (fin is Map<String, Object?>) {
      for (final r in listeOuVide(fin['raisons'])) {
        out.add(jm(r));
      }
    }
  }
  return out;
}

/// Codes `koach.*` du tableau du contrat 1.0 (§ 3.5).
Set<String> _codesDuContrat() {
  final texte = File('reference/CONTRAT_1_0.md').readAsStringSync();
  final debut = texte.indexOf('**Liste complète des codes `koach.*`**');
  final fin = texte.indexOf('### 3.6');
  expect(debut, greaterThan(0));
  expect(fin, greaterThan(debut));
  final ligne = RegExp(r'^\| `(koach\.[a-z_]+)` \|', multiLine: true);
  return <String>{
    for (final m in ligne.allMatches(texte.substring(debut, fin))) m.group(1)!,
  };
}

void main() {
  final raisons = _raisonsDesFixtures();

  test('les fixtures émettent des raisons koach.*', () {
    expect(raisons.length, greaterThan(1000));
  });

  test('chaque raison des fixtures a un texte lisible', () {
    final vus = <String>{};
    for (final r in raisons) {
      final code = r['code']! as String;
      final p = dictOuVide(r['params']);
      vus.add(code);
      expect(koachCodesRaisons, contains(code), reason: code);
      final cause = p['cause'];
      if (cause != null && koachCausesRaisons.containsKey(code)) {
        expect(koachCausesRaisons[code], contains(cause), reason: code);
      }
      final sans = texteRaisonKoach(r);
      _lisible(sans, '$code $p');
      expect(sans, isNot(texteRaisonKoachGenerique), reason: code);
      final avec = texteRaisonKoach(r, nomExercice: _nom);
      _lisible(avec, '$code $p (avec le nom)');
      final id = p['exercice'];
      if (id is String) {
        expect(sans.contains(id), isFalse, reason: '$code : $sans');
        expect(avec, contains('« $_nomEssai »'), reason: code);
      }
    }
    // 19 des 22 codes apparaissent dans les fixtures.
    expect(vus.length, greaterThanOrEqualTo(19));
  });

  test('tous les codes du contrat (§ 3.5) ont un texte propre', () {
    final contrat = _codesDuContrat();
    expect(contrat, hasLength(22));
    expect(contrat, equals(koachCodesRaisons.toSet()));
    for (final code in koachCodesRaisons) {
      final r = <String, Object?>{
        'code': code,
        'params': <String, Object?>{'exercice': 'mu-exercice-essai'},
      };
      final t = texteRaisonKoach(r);
      _lisible(t, code);
      expect(t, isNot(texteRaisonKoachGenerique), reason: code);
      expect(t.contains('mu-exercice-essai'), isFalse, reason: code);
      // Sans paramètre (l'item de test porte `koach.vrai_test` à vide).
      final vide = texteRaisonKoach(<String, Object?>{'code': code});
      _lisible(vide, '$code sans paramètre');
    }
  });

  test('chaque cause relevée dans le code a sa propre phrase', () {
    for (final e in koachCausesRaisons.entries) {
      final textes = <String>{};
      for (final cause in e.value) {
        final r = <String, Object?>{
          'code': e.key,
          'params': <String, Object?>{
            'exercice': 'mu-exercice-essai',
            'cause': cause,
            'zone': 'knee',
            'part': 70,
          },
        };
        final t = texteRaisonKoach(r, nomExercice: _nom);
        _lisible(t, '${e.key} $cause');
        textes.add(t);
      }
      expect(textes, hasLength(e.value.length), reason: e.key);
    }
  });

  test('paramètres : zones, groupes, techniques, nombres', () {
    for (final (zone, _) in libellesZones) {
      final r = <String, Object?>{
        'code': 'koach.douleur_persistante',
        'params': <String, Object?>{'zone': zone, 'consulter': true},
      };
      final t = texteRaisonKoach(r);
      _lisible(t, zone);
      expect(t.contains('cette zone'), isFalse, reason: zone);
    }
    final params = lireParametresKoach(
      File(koachFichierParametres).readAsStringSync(),
    );
    final groupes = <String>[
      ...jl(jm(params['securite'])['volume_groupes_majeurs']).cast<String>(),
      'allegement',
      'bras_tendus_push',
      'bras_tendus_pull',
      'bras_tendus_mixed',
    ];
    for (final g in groupes) {
      for (final series in const <int>[0, 1, 3]) {
        final r = <String, Object?>{
          'code': 'koach.retour_gradue',
          'params': <String, Object?>{
            'exercice': 'mu-exercice-essai',
            'groupe': g,
            'limite': 14.4,
            'series': series,
            'secondes': null,
          },
        };
        final t = texteRaisonKoach(r);
        _lisible(t, '$g $series');
        expect(t.contains('ce groupe musculaire'), isFalse, reason: g);
      }
    }
    final techniques = jm(jm(params['securite'])['technique_niveau_acces']);
    for (final tech in techniques.keys) {
      final r = <String, Object?>{
        'code': 'koach.technique_retenue',
        'params': <String, Object?>{'technique': tech, 'cause': 'niveau'},
      };
      final t = texteRaisonKoach(r);
      _lisible(t, tech);
      expect(t.contains('cette technique'), isFalse, reason: tech);
    }
    final borne = <String, Object?>{
      'code': 'koach.seance_bornee',
      'params': <String, Object?>{'minutes': 89.25},
    };
    expect(texteRaisonKoach(borne), contains('89 min'));
    final surmenage = <String, Object?>{
      'code': 'koach.surmenage',
      'params': <String, Object?>{'series': 1, 'part': 0.937},
    };
    expect(texteRaisonKoach(surmenage), contains('94 %'));
  });

  test('surveillance : causes, message, actions de repondre', () {
    for (final cause in koachCausesHorsModele) {
      for (final code in <String>[cause, 'surveillance.$cause']) {
        final t = texteRaisonKoach(<String, Object?>{'code': code});
        _lisible(t, code);
        expect(t, isNot(texteRaisonKoachGenerique), reason: code);
      }
    }
    final entree = <String, Object?>{'code': 'surveillance.hors_modele'};
    _lisible(texteRaisonKoach(entree), 'hors_modele');
    final d = jm(_fixture(1)['entrees']);
    final fiches = <String, Json>{
      for (final e in jm(d['fiches']).entries) e.key: jm(e.value),
    };
    final k = Koach(
      copieJson(jm(d['params'])),
      fiches,
      copieJson(jm(d['profil'])),
    );
    final s = Surveillance(k.params);
    k.extensions.add(s);
    final reponses = <Json>[
      <String, Object?>{'cause': 'douleur', 'zone': 'knee', 'intensite': 5},
      <String, Object?>{
        'cause': 'moins_de_temps',
        'seances_par_semaine': 3,
        'duree_max_min': 45,
      },
      <String, Object?>{'cause': 'fatigue'},
      <String, Object?>{'cause': 'rien'},
    ];
    final actions = <String>{};
    for (final rep in reponses) {
      final action = s.repondre(k, rep);
      actions.add(action['action']! as String);
      final t = texteRaisonKoach(action);
      _lisible(t, '$rep');
      expect(t, isNot(texteRaisonKoachGenerique), reason: '$rep');
      final parCode = <String, Object?>{
        'code': 'surveillance.action.${action['action']}',
        'params': action,
      };
      expect(texteRaisonKoach(parCode), t);
    }
    expect(actions, equals(koachActionsHorsModele.toSet()));
  });

  test('diagnostic : questions et choix de Surveillance.questions', () {
    final questions = <Json>[
      questionCause,
      questionZone,
      questionIntensite,
      questionSeances,
      questionDuree,
    ];
    for (final q in questions) {
      final code = q['code']! as String;
      final t = texteQuestionKoach(code);
      _lisible(t, code);
      expect(t, isNot(texteQuestionKoach('inconnue')), reason: code);
      for (final c0 in jl(q['choix'])) {
        final c = jm(c0);
        final choix = texteChoixKoach(code, c['code']);
        _lisible(choix, '$code ${c['code']}');
        expect(choix.startsWith('Autre'), isFalse, reason: '$c');
      }
    }
    for (final (zone, libelle) in libellesZones) {
      expect(texteChoixKoach('zone', zone), libelle);
    }
    expect(texteChoixKoach('cause', 'rien'), 'Rien de spécial');
    expect(texteChoixKoach('duree_max_min', 45), '45 min');
  });

  test('contrôle dual : raisons texte', () {
    const exemples = <String>[
      'essai_demarre:11:',
      'essai_refuse:11:non_calibre,affutage,alerte_hors_modele,douleur',
      'essai_refuse:11:echeance_proche,deja_termine,deja_interrompu',
      'essai_refuse:11:deja_en_cours,temoin_trop_court:3',
      'essai_refuse:11:semaines_insuffisantes:4<8,aucun_lift_principal',
      'essai_refuse:11:lift_inconnu:sl-dips-leste',
      'essai_refuse:11:intervalle_large:sl-dips-leste:0.0712',
      'essai_refuse:11:essai_en_cours',
      'essai_interrompu:douleur',
      'essai_interrompu:alerte_hors_modele',
      'synthetique_impossible:témoins insuffisants',
    ];
    for (final code in exemples) {
      final t = texteRaisonKoach(<String, Object?>{'code': code});
      _lisible(t, code);
      expect(t, isNot(texteRaisonKoachGenerique), reason: code);
      expect(t.contains('sl-dips-leste'), isFalse, reason: code);
      expect(texteRaisonDual(code), t);
    }
    final nomme = texteRaisonDual(
      'essai_refuse:11:intervalle_large:sl-dips-leste:0.0712',
      nomExercice: _nom,
    );
    expect(nomme, contains('« $_nomEssai »'));
    expect(texteRaisonDual('essai_demarre:11:'), contains('semaine 12'));
  });

  test('code inconnu : repli générique, jamais le code', () {
    for (final code in <String>['koach.nouveau_code', 'autre.chose', '']) {
      final t = texteRaisonKoach(<String, Object?>{'code': code});
      expect(t, texteRaisonKoachGenerique);
      _lisible(t, code);
    }
    expect(texteRaisonKoach(<String, Object?>{}), texteRaisonKoachGenerique);
    _lisible(texteQuestionKoach('inconnue'), 'question inconnue');
    _lisible(texteChoixKoach('inconnue', 'x_y'), 'choix inconnu');
  });
}
