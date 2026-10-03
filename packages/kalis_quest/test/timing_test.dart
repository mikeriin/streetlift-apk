// Budget de temps (PIPELINE_GP.md §2) : calcul du leveling depuis tout le
// journal ≤ 200 ms. Trois ans d'un athlète à six séances par semaine.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('trois ans de journal : calcul complet en 200 ms au plus', () {
    final a = archetypeOf('expert_6x');
    const weeks = 156;
    final stage = stageOf(a, weeks);
    final log = generateLog(a, stage, 3, weeks);
    expect(log.sessions.length, greaterThan(700));
    final engine = KalisQuest();
    final training = TrainingLog(sessions: log.sessions, breaks: log.breaks);
    final start = stage.startDay;
    final end = start + 7 * weeks - 1;
    final first = engine.evaluate(
      stage.catalog,
      QuestInput(
        profile: stage.profile,
        log: const TrainingLog(sessions: <SessionRecord>[]),
        block: stage.blockOn(start),
        state: emptyState,
        today: CivilDate.fromDayNumber(start),
        seed: 3,
      ),
    );
    QuestOutcome full() => engine.evaluate(
      stage.catalog,
      QuestInput(
        profile: stage.profile,
        log: training,
        block: stage.blockOn(end),
        state: first.state,
        today: CivilDate.fromDayNumber(end),
        seed: 3,
      ),
    );
    full();
    final times = <int>[];
    late QuestOutcome outcome;
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      outcome = full();
      watch.stop();
      times.add(watch.elapsedMilliseconds);
    }
    times.sort();
    // ignore: avoid_print
    print('calcul complet depuis 3 ans de journal : $times ms');
    expect(times[2], lessThanOrEqualTo(200));
    expect(outcome.level.totalXp, greaterThan(10000));

    final next = <int>[];
    for (var i = 0; i < 5; i++) {
      final watch = Stopwatch()..start();
      engine.evaluate(
        stage.catalog,
        QuestInput(
          profile: stage.profile,
          log: training,
          block: stage.blockOn(end),
          state: outcome.state,
          today: CivilDate.fromDayNumber(end + 1),
          seed: 3,
        ),
      );
      watch.stop();
      next.add(watch.elapsedMilliseconds);
    }
    next.sort();
    // ignore: avoid_print
    print('appel du lendemain : $next ms');
    expect(next[2], lessThanOrEqualTo(200));
  });
}
