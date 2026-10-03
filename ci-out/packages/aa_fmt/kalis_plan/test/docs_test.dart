// Les documents générés de docs/ sont ceux que le moteur produit
// aujourd'hui : s'ils diffèrent, relancer
// `dart run bin/kalis_plan_cli.dart --rapport <dossier>` et recopier
// PROFILS_TYPES.md et COMPARAISON_L10.md dans docs/.
import 'dart:io';

import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:test/test.dart';

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
      fail('$path, ligne ${i + 1} :\n  fichier : $left\n  moteur  : $right');
    }
  }
}

void main() {
  final catalog = loadCatalog();
  final fixtures = loadProfiles();

  test('docs/PROFILS_TYPES.md est à jour', () {
    _expectSame(
      'docs/PROFILS_TYPES.md',
      profilsTypesMarkdown(catalog, KalisPlan(), fixtures),
    );
  });

  test('docs/COMPARAISON_L10.md est à jour', () {
    _expectSame(
      'docs/COMPARAISON_L10.md',
      l10ComparisonMarkdown(
        catalog,
        KalisPlan(),
        fixtures,
        readJsonObject('docs/data/l10_sorties.json.gz'),
      ),
    );
  });

  test('PROFILS_TYPES.md : 40 profils, aucune violation', () {
    final text = File('docs/PROFILS_TYPES.md').readAsStringSync();
    expect(RegExp(r'^## \d+\. `', multiLine: true).allMatches(text).length, 40);
    expect(text.contains('**VIOLATIONS**'), isFalse);
  });
}
