// CIF (dev6.18.0, pipeline CP, lot CI final, point 6) — test reporté exercé
// par un cas réel : profil street à 5 ou 6 séances par semaine où un jour
// de test est suivi d'une séance sans test 48 h après au moins. Un bilan
// bas le jour du test le retire ; la séance suivante de la semaine le sert
// (raison « reporté »), avant le travail, et sa série est journalisée en
// test à son emplacement d'origine. CI1b le déclarait « sauté » faute de
// semaine qui s'y prête dans les fixtures (tests en fin de semaine) : ici
// plusieurs jours de départ et disponibilités sont essayés, et le test
// échoue si aucun ne donne le cas.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/store.dart';

kc.AthleteProfile _street(String primary) {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return [
    for (final p in raw['profiles']! as List)
      kc.AthleteProfile.fromJson(
        ((p as Map)['profile'] as Map).cast<String, Object?>(),
      ),
  ].firstWhere((p) => p.disciplines.primary.code == primary);
}

DateTime _dateOf(AppStore app, int week, int j) {
  final s = app.program.start!;
  return DateTime(s.year, s.month, s.day + (week - 1) * 7 + j - 1, 9);
}

/// Valide la première série du premier exercice servi (séance au journal).
void _logOneSet(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  final day = app.adaptDay(week, base, a);
  for (final e in day.exercises) {
    final log = app.exLog(week, j, e);
    if (log.sets.isEmpty) continue;
    app.adaptPrefill(week, j, e, log);
    final s = log.sets.first;
    if (s.reps.isEmpty) s.reps = '5';
    s.flames = 7;
    if (app.toggleSet(log, 0, app.logSpec(e)).ok) {
      app.adaptAfterSet(week, day, e, 0);
      break;
    }
  }
  app.saveLogs();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '6 : test retiré un jour de bilan bas, servi 48 h après au moins dans la '
    'même semaine (profil à 5-6 séances), journalisé à son emplacement',
    () async {
      // Disponibilités (jours ISO) et jours de départ essayés.
      const weeks = <List<int>>[
        [1, 2, 3, 4, 5, 6],
        [1, 2, 3, 4, 5],
        [1, 2, 4, 5, 6],
        [1, 3, 4, 5, 6, 7],
      ];
      final starts = [
        DateTime(2026, 10, 5, 9), // lundi
        DateTime(2026, 10, 6, 9),
        DateTime(2026, 10, 7, 9),
        DateTime(2026, 10, 1, 9), // jeudi
      ];
      var tried = 0, cases = 0;
      for (final key in ['streetlifting', 'street_workout']) {
        for (final days in weeks) {
          for (final start in starts) {
            SharedPreferences.setMockInitialValues({});
            var clock = start;
            final s = AppStore()..storeClock = () => clock;
            await s.init();
            try {
              final p = _street(key).copyWith(
                availability: [
                  for (final d in days) kc.DaySlot(weekday: d, minutes: 90),
                ],
                events: const <kc.SeasonEvent>[],
              );
              final r = s.saveAthleteProfile(
                ProfileDraft.of(p)..consent = 'refused',
              );
              if (r == null) continue;
              final c = PlanStore(s).newPlanCreation(journal: false);
              if (c == null) continue;
              c.start();
              c.createPass2();
              PlanStore(s).applyPlanCreation(c);
              for (var w = 1; w <= 12; w++) {
                for (var j = 1; j <= 7; j++) {
                  final it = s
                      .adaptPlaceOf(w, j)
                      ?.day
                      ?.items
                      .where((x) => x.kind == kc.SetKind.test)
                      .firstOrNull;
                  if (it == null) continue;
                  int? k;
                  for (var x = j + 2; x <= 7 && k == null; x++) {
                    final items = s.adaptPlaceOf(w, x)?.day?.items;
                    if (items == null || items.isEmpty) continue;
                    if (items.any((y) => y.kind == kc.SetKind.test)) continue;
                    k = x;
                  }
                  final d = k;
                  if (d == null) continue;
                  cases++;
                  final slot = it.slotId;
                  clock = _dateOf(s, w, j);
                  final base = s.program.week(w).day(j)!;
                  s.adaptOpen(w, base);
                  final low = s.adaptAnswer(
                    w,
                    base,
                    const kc.HealthCheck(
                      overall: 1,
                      sleepQuality: 1,
                      energy: 1,
                    ),
                  )!;
                  if (low.plan.items.any((x) => x.slotId == slot)) continue;
                  _logOneSet(s, w, j);
                  clock = _dateOf(s, w, d);
                  final later = s.program.week(w).day(d)!;
                  final a = s.adaptOpen(w, later)!;
                  tried++;
                  if (!a.active.items.any((x) => x.slotId == slot)) continue;
                  final day = s.adaptDay(w, later, a);
                  final e = day.exercises.firstWhere((x) => x.slotId == slot);
                  expect(e.id, planExerciseId(w, d, slot));
                  expect(e.engine, isTrue);
                  expect(e.why, contains('reporté'));
                  expect(s.adaptItemFor(w, d, e)?.kind, kc.SetKind.test);
                  expect(
                    day.exercises.indexOf(e),
                    lessThanOrEqualTo(
                      day.exercises.indexWhere(
                        (x) =>
                            s.adaptItemFor(w, d, x)?.kind != kc.SetKind.warmup,
                      ),
                    ),
                  );
                  final log = s.exLog(w, d, e);
                  s.adaptPrefill(w, d, e, log);
                  if (log.sets.first.reps.isEmpty) log.sets.first.reps = '8';
                  log.sets.first.flames = 9;
                  expect(s.toggleSet(log, 0, s.logSpec(e)).ok, isTrue);
                  s.saveLogs();
                  final journal = s.adaptTrainingLog(
                    today: kc.CivilDate(clock.year, clock.month, clock.day),
                  );
                  final rows = [
                    for (final x in journal.sessions)
                      for (final r in x.sets)
                        if (r.slotId == slot && r.kind == kc.SetKind.test) r,
                  ];
                  expect(rows, isNotEmpty);
                  expect(journal.validate(), isEmpty);
                  // ignore: avoid_print
                  print(
                    'CIF6|$key|jours ${days.join(',')}|départ '
                    '${start.weekday}|S$w·J$j → J$d|${it.exerciseId}|'
                    '${e.why}',
                  );
                  return;
                }
              }
            } finally {
              await s.flush();
              s.dispose();
            }
          }
        }
      }
      fail('aucun test reporté par le moteur ($cases cas, $tried servis)');
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
