// Diagnostic temporaire (mise au point de G10, retiré avant livraison).
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final key in kSimAthleteLabels.keys) {
   for (final seed in [1, 2, 3, 4, 5, 6]) {
    test('diag $key $seed', () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await s.init();
      s.saveAthleteProfile(
        ProfileDraft.of(
          sampleAthleteProfile(
            on: kc.CivilDate(2026, 10, 1),
            guidance: kc.GuidanceMode.assisted,
          ),
        )..consent = 'refused',
      );
      final c = PlanStore(s).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(s).applyPlanCreation(c);
      final sw = Stopwatch()..start();
      final r = await runDevSimulation(
        s,
        athleteKey: key,
        weeks: 8,
        seed: seed,
      );
      sw.stop();
      final kinds = [
        for (final e in s.planEvolution.entries)
          '${e.proposal.kind.code}:${e.status}@${e.fromWeek}',
      ];
      // ignore: avoid_print
      print(
        'DIAG $key/$seed ms=${sw.elapsedMilliseconds} done=${r.sessionsDone} '
        'missed=${r.sessionsMissed} sets=${r.sets} blocks=${r.blocksAdded} '
        'unlock=${s.evolutionUnlock.level.code} '
        'weeksObs=${s.evolutionUnlock.weeksObserved} '
        'pending=${s.evolutionPending.length} entries=$kinds '
        'err=${r.error}',
      );
      final log = s.lastEvolutionReview?.review.log ?? const [];
      for (final l in log) {
        if (l.event.startsWith('proposal')) {
          // ignore: avoid_print
          print('DIAG $key   ${l.event} ${l.data}');
        }
      }
      s.dispose();
    }, timeout: const Timeout(Duration(minutes: 8)));
   }
  }
}
