// Les documents générés de docs/ sont ceux que le paquet produit
// aujourd'hui : s'ils diffèrent, relancer
// `dart run bin/kalis_quest_cli.dart --rapport <dossier>` et recopier
// RYTHME.md, STANDARDS.md, CAS_TYPES.md (docs/) et campagne.json
// (docs/data/).
import 'dart:io';

import 'package:kalis_quest/report.dart';
import 'package:kalis_quest/simulation.dart';
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
      fail('$path, ligne ${i + 1} :\n  fichier : $left\n  paquet  : $right');
    }
  }
}

void main() {
  final catalog = loadCatalog();

  test('docs/RYTHME.md est la mise en tableaux de docs/data/campagne.json', () {
    final campaign = readJsonObject('docs/data/campagne.json');
    _expectSame('docs/RYTHME.md', rhythmMarkdown(campaign));
    expect(campaign['seeds'], greaterThanOrEqualTo(200));
    expect(campaign['weeks'], greaterThanOrEqualTo(156));
    final list = campaign['archetypes']! as List<Object?>;
    expect(list, hasLength(archetypes.length));
    for (final item in list) {
      final a = item! as Map<String, Object?>;
      expect(a['runs'], campaign['seeds']);
      final guards = a['guards']! as Map<String, Object?>;
      expect(guards['xpForPainOrExtra'], 0, reason: '${a['key']}');
      expect(guards['levelDropped'], isFalse, reason: '${a['key']}');
      expect(guards['worstWeekShare']! as num, lessThanOrEqualTo(1));
    }
    final timing = campaign['timing']! as Map<String, Object?>;
    expect(timing['fullMedianMs']! as num, lessThanOrEqualTo(200));
  });

  test('docs/STANDARDS.md est la table que le moteur applique', () {
    _expectSame('docs/STANDARDS.md', standardsMarkdown(catalog));
  });

  test(
    'docs/CAS_TYPES.md est ce que le moteur rend pour les journaux types',
    () {
      _expectSame(
        'docs/CAS_TYPES.md',
        casesMarkdown(catalog, loadProfiles(), loadJournals()),
      );
    },
  );
}
