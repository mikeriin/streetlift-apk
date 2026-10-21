// PR8 (dev7.1.8) — départ chronométré à reps fixes (« 8×3 · E2MOM ») :
// la ligne est servie telle qu'écrite (charge et reps du programme), dans
// son groupe ; Koach la journalise sans la recalculer.
// Données synthétiques ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/program_instance.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

Map<String, dynamic> _line(
  String id,
  String name,
  String sets,
  Map<String, dynamic> load,
  String catalogId, {
  bool main = false,
}) => {
  'id': id,
  'name': name,
  'sets': {'type': 'text', 'value': sets},
  'intensity': 'RIR 2',
  'load': load,
  'rest': main ? 'Départ toutes les 2 min' : '—',
  'restSec': main ? 120 : null,
  'tempo': '',
  'cue': '',
  'main': main,
  'prevention': false,
  'catalogId': catalogId,
};

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

  test('E2MOM écrit : servi tel qu’écrit, la ligne enchaînée aussi', () async {
    final backup = backupOf(app);
    final week = restWeek(1)..remove('kind');
    (week['days'] as List)[0] = {
      'j': 1,
      'title': 'TIRAGE LOURD',
      'cycle': '',
      'conduite': '',
      'exercises': [
        _line(
          'T-1',
          'TRACTION LESTÉE — lift principal',
          '8×3 · E2MOM',
          {'type': 'system', 'ref': 'B8', 'pct': 0.83},
          'sl-traction-lestee',
          main: true,
        ),
        _line(
          'T-2',
          'Pompes PdC — pause de la traction, enchaîné',
          '8×12 · E2MOM',
          {'type': 'fixed', 'kg': 0.0},
          'sw-pompe',
        ),
      ],
    };
    backup['programStart'] = {
      'status': 'set',
      'date': '2026-10-19',
      'origin': 'migration',
    };
    backup['programInstance'] = {
      'v': 1,
      'kind': 'generated',
      'origin': 'user',
      'createdAt': '2026-10-17T12:00:00',
      'updatedAt': '2026-10-17T12:00:00',
      'generator': 'test',
      'seed': 0,
      'weeks': [week, restWeek(2)],
      'cycle': 1,
    };
    expect(await app.importAll(jsonEncode(backup)), isTrue);
    app.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(app.storeClock()),
        ).copyWith(experience: kc.ExperienceLevel.advanced),
      )..consent = 'refused',
    );
    final pull = app.adaptSlotOf(1, 1, 'T-1');
    final push = app.adaptSlotOf(1, 1, 'T-2');
    expect(pull, isNotNull);
    expect(push, isNotNull);
    expect(app.adaptAsWritten(1, pull), isTrue);
    expect(app.adaptAsWritten(1, push), isTrue);
    // Même groupe au temps : 8 départs toutes les 2 min.
    final day = app.program.week(1).day(1)!;
    final g = app.exerciseGroupOf(1, 1, day.original.exercises.first)!;
    expect(g.format, kc.GroupFormat.emom);
    expect(g.intervalSeconds, 120);
    expect(
      app.exerciseGroupOf(1, 1, day.original.exercises.last)!.groupId,
      g.groupId,
    );
  });
}
