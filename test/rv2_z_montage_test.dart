// Provisoire (diagnostic de la cible émulateur rv2, ne pas publier).
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart' show bootSession;
import 'package:streetlift_tracker/store.dart';

import '../integration_test/kb2c1_semaine.dart';
import 'l2_fixtures.dart';

Future<Map<String, dynamic>> _asset(String name) async {
  final bytes = await rootBundle.load('assets/$name');
  return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
      as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('diagnostic montage rv2', () async {
    KalisClock.setOffsetDays(0);
    SharedPreferences.setMockInitialValues({});
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    await store.init();
    store.settings.defaultRest = 90;
    store.saveSettings();
    await store.flush();
    store.dispose();
    store = AppStore();

    await raw.clear();
    final seed = AppStore();
    await seed.init();
    final b = filledBackup(seed);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    logs.removeWhere((k, _) {
      final w = int.parse(k.substring(1, k.indexOf('-')));
      return w < 12 || w > 14;
    });
    final base = await _asset('programme_v33.json.gz');
    final koach = await _asset('koach_program.json.gz');
    b['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test-rv2',
      'seed': 0,
      'weeks': [
        for (final w in (base['weeks'] as List).take(14))
          (w as Map).cast<String, dynamic>(),
        for (var n = 15; n <= 24; n++)
          (jsonDecode(kKb2c1Semaine) as Map<String, dynamic>)
            ..['n'] = n
            ..['blockKey'] = n <= 19 ? 'NA' : 'NB',
      ],
      'koach': {
        'exercises': koach['exercises'],
        'weeks': {
          for (final e in (koach['weeks'] as Map).entries)
            if (int.parse('${e.key}') <= 14) '${e.key}': e.value,
        },
      },
      'summary': {'firstShownWeek': 15},
      'cycle': 1,
    };
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    final ok = await seed.importAll(jsonEncode(b));
    // ignore: avoid_print
    print('DIAG import=$ok seedStart=${seed.program.start} '
        'issues=${seed.programLoadIssues}');
    await seed.flush();
    // ignore: avoid_print
    print('DIAG keys=${raw.getKeys()}');
    seed.dispose();

    await bootSession();
    // ignore: avoid_print
    print('DIAG start=${store.program.start} '
        'issues=${store.programLoadIssues} first=${store.program.firstShown}');
    expect(store.program.start, isNotNull);
  });
}
