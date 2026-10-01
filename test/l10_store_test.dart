// L10 — instance de programme branchée sur le store (KT-050, KT-057) :
// migration du propriétaire (programme de 40 semaines identique, export
// inchangé) et, depuis le retrait du générateur L10 par G7, compatibilité
// des instances « generated » existantes : relues, affichées telles
// quelles, exportées à l'identique, import strict. Les tests de génération,
// régénération, annulation, mode Guidé et cycle suivant sont retirés avec
// le générateur (G7). Stockage simulé, horloge injectée.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/program_instance.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/l10_support.dart';

Map<String, dynamic> _asset() => readGz('assets/programme_v33.json.gz');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 5, 9);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 5, 9);
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
      for (final o in others) {
        o.dispose();
      }
      others.clear();
    });

    Future<AppStore> relaunch() async {
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      return next;
    }

    test(
      'migration du propriétaire : instance implicite, 40 semaines '
      'identiques au programme actuel, historique et export inchangés',
      () async {
        final filled = filledBackup(app);
        expect(await app.importAll(jsonEncode(filled)), isTrue);
        final before = app.exportAll();
        final next = await relaunch();
        expect(next.programInstance, isNull);
        expect(next.programGenerated, isFalse);
        expect(next.programModel, 'expert_streetlifting');
        final asset = _asset();
        final weeks = asset['weeks'] as List;
        expect(next.program.weeks, hasLength(40));
        for (var w = 0; w < 40; w++) {
          final aw = weeks[w] as Map;
          final pw = next.program.weeks[w];
          expect(pw.n, aw['n']);
          expect(pw.block, aw['block']);
          for (var d = 0; d < 7; d++) {
            final ad = (aw['days'] as List)[d] as Map;
            final pd = pw.days[d];
            expect(pd.title, ad['title']);
            expect(
              [
                for (final e in pd.exercises)
                  '${e.id}|${e.name}|${e.sets.value}|${e.intensity}',
              ],
              [
                for (final e in ad['exercises'] as List)
                  '${(e as Map)['id']}|${e['name']}|${(e['sets'] as Map)['value']}|${e['intensity']}',
              ],
            );
          }
        }
        expect(next.program.start, app.program.start);
        expect(next.exportAll(), before);
        expect(backupOf(next).containsKey('programInstance'), isFalse);
        expect(next.koachProgram.available, isTrue);
      },
    );

    test('instance L10 existante : relue, affichée telle quelle, exportée à '
        'l\'identique ; section invalide refusée à l\'import, ignorée au '
        'démarrage', () async {
      final doc = backupOf(app);
      final weeks = copyWeeks((_asset()['weeks'] as List).take(3).toList());
      doc['programStart'] = {
        'status': 'set',
        'date': '2026-10-05',
        'origin': 'user',
      };
      doc['programInstance'] = {
        'v': 1,
        'kind': 'generated',
        'origin': 'onboarding',
        'createdAt': '2026-10-01T10:00:00',
        'updatedAt': '2026-10-01T10:00:00',
        'generator': '1.0.0',
        'seed': 42,
        'weeks': weeks,
        'summary': {'model': 'linear', 'modelLabel': 'Linéaire'},
        'cycle': 0,
      };
      expect(await app.importAll(jsonEncode(doc)), isTrue);
      expect(app.programGenerated, isTrue);
      expect(app.program.weeks, hasLength(3));
      expect(
        [for (final e in app.program.week(2).day(1)!.exercises) e.name],
        [
          for (final e in ((weeks[1]['days'] as List)[0] as Map)['exercises']
              as List)
            (e as Map)['name'],
        ],
      );
      final exported = app.exportAll();
      final other = await relaunch();
      expect(other.programGenerated, isTrue);
      expect(other.exportAll(), exported);
      final broken = jsonDecode(exported) as Map<String, dynamic>;
      (broken['programInstance'] as Map)['weeks'] = [
        {'n': 3, 'days': []},
      ];
      expect(await other.importAll(jsonEncode(broken)), isFalse);
      expect(
        () => ProgramInstance.fromJson(broken['programInstance'], strict: true),
        throwsFormatException,
      );
      final issues = <String>[];
      expect(
        ProgramInstance.fromJson(broken['programInstance'], issues: issues),
        isNull,
      );
      expect(issues, isNotEmpty);
    });
  });
}
