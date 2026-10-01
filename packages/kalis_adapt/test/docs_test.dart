// Les documents générés de docs/ sont ceux que le paquet produit
// aujourd'hui : s'ils diffèrent, relancer
// `dart run bin/kalis_adapt_cli.dart --rapport <dossier>` et recopier
// MESURES.md, PROPRIETAIRE.md (docs/), campagne.json (docs/data/) et
// proprietaire.json (test/fixtures/, compressé).
import 'dart:io';

import 'package:kalis_adapt/report.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:test/test.dart';

import '../tool/owner.dart';
import 'support.dart';

void _expectSame(String path, String generated) {
  final committed = File(path).readAsStringSync();
  if (committed == generated) {
    return;
  }
  final a = committed.split('\n');
  final b = generated.split('\n');
  for (var i = 0; i < a.length || i < b.length; i++) {
    final left = i < a.length ? a[i] : '<fin>';
    final right = i < b.length ? b[i] : '<fin>';
    if (left != right) {
      fail('$path, ligne ${i + 1} :\n  fichier : $left\n  paquet  : $right');
    }
  }
}

void main() {
  final catalog = loadCatalog();

  test('docs/MESURES.md est la mise en tableaux de docs/data/campagne.json', () {
    final campaign = readJsonObject('docs/data/campagne.json');
    _expectSame('docs/MESURES.md', campaignMarkdown(campaign));
    expect(campaign['seeds'], greaterThanOrEqualTo(200));
    expect(campaign['weeks'], greaterThanOrEqualTo(24));
    final athletes = campaign['athletes']! as List<Object?>;
    expect(athletes.length, greaterThanOrEqualTo(6));
    expect(athletes.length, simAthletes.length);
    for (final a in athletes) {
      final athlete = a! as Map<String, Object?>;
      final policies = athlete['policies']! as Map<String, Object?>;
      for (final name in reportPolicies) {
        final metrics = policies[name]! as Map<String, Object?>;
        expect(metrics['runs'], campaign['seeds'], reason: name);
      }
    }
  });

  test('la fixture du propriétaire est celle que le simulateur produit', () {
    final fixture = readJsonObject('test/fixtures/proprietaire.json.gz');
    final generated = ownerFixture(
      catalog,
      profileOf(ownerProfileKey),
      readJsonObject('$corePath/test/fixtures/owner_program_v33.json.gz'),
    );
    expect(jsonText(generated), jsonText(fixture));
  });

  test('docs/PROPRIETAIRE.md est le rejeu de la fixture', () {
    final fixture = readJsonObject('test/fixtures/proprietaire.json.gz');
    _expectSame(
      'docs/PROPRIETAIRE.md',
      ownerReplayMarkdown(catalog, profileOf(ownerProfileKey), fixture),
    );
    final block = fixture['block']! as Map<String, Object?>;
    final pass1 = block['pass1']! as Map<String, Object?>;
    expect(pass1['weeks'], 40);
  });
}
