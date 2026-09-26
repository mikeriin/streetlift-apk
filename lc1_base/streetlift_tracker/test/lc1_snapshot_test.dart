// Mesure « avant » : même état synthétique que test/l4_depart_test.dart
// (groupe « Comparaison »), chargé par le code 2.5.7 (LC1) inchangé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final _today = DateTime(2026, 9, 26, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);
  test('instantané 2.5.7', () async {
    SharedPreferences.setMockInitialValues({
      'settings_v1': jsonEncode(AppSettings().toJson()),
    });
    final base = AppStore()..storeClock = () => _today;
    await base.init();
    final m = jsonDecode(base.exportAll()) as Map<String, dynamic>;
    (m['pilotage'] as Map<String, dynamic>)
      ..['B4'] = 81.5
      ..['B8'] = 32.5;
    final logs = <String, dynamic>{
      'S1-J1': SessionLog(done: true, finishedAt: '2026-07-13T18:10:00.000', title: 'S1 · J1').toJson(),
      'S1-J2': SessionLog(done: true, title: 'S1 · J2').toJson(),
      'S6-J4': SessionLog(done: true, finishedAt: '2026-08-20T19:00:00.000', title: 'S6 · J4').toJson(),
    };
    final p = base.program;
    for (var w = 1; w <= 10; w++) {
      for (final d in p.week(w).days.where((d) => d.exercises.isNotEmpty)) {
        final date = p.dateFor(w, d.j);
        logs.putIfAbsent(
          'S$w-J${d.j}',
          () => SessionLog(
            done: true,
            finishedAt: DateTime(date.year, date.month, date.day, 18).toIso8601String(),
            title: 'S$w · J${d.j}',
          ).toJson(),
        );
      }
    }
    m['logs'] = logs;
    SharedPreferences.setMockInitialValues({'kalis_state_v3': jsonEncode(m)});
    final a = AppStore()..storeClock = () => _today;
    await a.init();
    a.settings
      ..notifOn = true
      ..notifSkipRest = false;
    final plan = planReminders(a, DateTime.utc(2026, 9, 26, 8), location: tz.getLocation('Europe/Paris'));
    String two(int v) => v.toString().padLeft(2, '0');
    final s11a = a.program.dateFor(11, 1), s11b = a.program.dateFor(11, 7);
    // ignore: avoid_print
    print('L4-BEFORE ${jsonEncode({
      'semaine': 'S${a.program.weekFor(_today)} · J${a.program.dayFor(_today)}',
      'datesS11': '${two(s11a.day)}/${two(s11a.month)}→${two(s11b.day)}/${two(s11b.month)}/${s11b.year}',
      'seances': a.logs.length,
      'S6-J4': a.logs['S6-J4']?.finishedAt,
      'S1-J2': a.logs['S1-J2']?.finishedAt,
      'B4': a.values['B4'],
      'B8': a.values['B8'],
      'references': a.values.length,
      'xp': a.xp,
      'niveau': a.level,
      'credits': a.credits,
      'gains': a.creditGrants.values.fold<int>(0, (x, y) => x + y),
      'droitsWod': a.unlockedWods.length,
      'rappels': plan.length,
      'premierRappel': plan.isEmpty ? null : '${plan.first.payload} ${plan.first.at.toIso8601String().substring(0, 16)}',
    })}');
  });
}
