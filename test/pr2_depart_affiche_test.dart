// PR2 (dev7.1.2) — programme repris en cours de route : les semaines d'avant
// le départ affiché restent au journal (Koach, progression) mais ne
// s'affichent plus ; la numérotation affichée repart de S1.
// Données synthétiques ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/program_instance.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore();
    await app.init();
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
  });

  test('départ affiché en S3 : S3 devient S1, les semaines d’avant sont '
      'masquées', () async {
    final backup = backupOf(app);
    backup['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test',
      'seed': 0,
      'weeks': [for (var n = 1; n <= 5; n++) restWeek(n)],
      'summary': {'firstShownWeek': 3},
      'cycle': 1,
    };
    expect(await app.importAll(jsonEncode(backup)), isTrue);
    final p = app.program;
    expect(p.weeks.length, 5);
    expect(p.firstShown, 3);
    expect([for (final w in p.shownWeeks) w.n], [3, 4, 5]);
    expect(p.shownNumber(3), 1);
    expect(p.weekLabel(4), 'S2');
    expect(p.weekLabel(2), 'S2 (ancien)');
    expect(p.sessionLabel(5, 2), 'S3 · J2');
  });

  test('sans départ affiché : numérotation d’origine', () {
    final p = app.program;
    expect(p.firstShown, 1);
    expect(p.shownWeeks.length, p.weeks.length);
    expect(p.sessionLabel(12, 3), 'S12 · J3');
  });
}
