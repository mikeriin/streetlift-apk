// Diagnostic temporaire (mise au point de G10, retiré avant livraison).
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final mode in kc.GuidanceMode.values) {
    for (final key in kSimAthleteLabels.keys) {
      for (final seed in [1, 2, 3, 4, 5]) {
        test('diag ${mode.code} $key $seed', () async {
          SharedPreferences.setMockInitialValues({});
          final s = AppStore()..storeClock = () => DateTime(2026, 11, 2, 9);
          await s.init();
          s.saveAthleteProfile(
            ProfileDraft.of(
              sampleAthleteProfile(on: kc.CivilDate(2026, 11, 2), guidance: mode),
            )..consent = 'refused',
          );
          final c = PlanStore(s).newPlanCreation(journal: false)!;
          c.start();
          c.createPass2();
          PlanStore(s).applyPlanCreation(c);
          final r = await runDevSimulation(
            s,
            athleteKey: key,
            weeks: 8,
            seed: seed,
            acceptAll: mode == kc.GuidanceMode.free,
          );
          s.storeClock = () => DateTime(r.end.year, r.end.month, r.end.day, 9);
          s.evolutionRefresh();
          // ignore: avoid_print
          print(
            'DIAG ${mode.code} $key/$seed done=${r.sessionsDone} end=${r.end} '
            'entries=${[for (final e in s.planEvolution.entries) '${e.proposal.kind.code}:${e.status}@${e.fromWeek}']} '
            'announced=${s.evolutionAnnounced.length} pending=${s.evolutionPending.length} '
            'review=${s.lastEvolutionReview != null} err=${r.error}',
          );
          s.dispose();
        });
      }
    }
  }
}
