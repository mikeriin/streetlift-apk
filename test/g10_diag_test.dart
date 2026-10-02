// Diagnostic temporaire (mise au point de G10, retiré avant livraison).
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final starts = [DateTime(2026, 10, 1), DateTime(2026, 10, 5), DateTime(2026, 11, 2)];
  for (final st in starts) {
    for (final mode in kc.GuidanceMode.values) {
      for (final key in ['intermediaire_salle', 'douleur_et_lieu', 'calisthenie_parc', 'avance_street']) {
        for (final seed in [2, 3]) {
          test('diag ${st.month}-${st.day} ${mode.code} $key $seed', () async {
            SharedPreferences.setMockInitialValues({});
            final s = AppStore()..storeClock = () => st.add(const Duration(hours: 9));
            await s.init();
            s.saveAthleteProfile(
              ProfileDraft.of(
                sampleAthleteProfile(on: kc.CivilDate(st.year, st.month, st.day), guidance: mode),
              )..consent = 'refused',
            );
            final c = PlanStore(s).newPlanCreation(journal: false)!;
            c.start();
            c.createPass2();
            PlanStore(s).applyPlanCreation(c);
            final lines = <String>[];
            var lastW = -1;
            final r = await runDevSimulation(
              s,
              athleteKey: key,
              weeks: 8,
              seed: seed,
              acceptAll: mode == kc.GuidanceMode.free,
              onProgress: (d, tot) {
                if (d ~/ 7 == lastW) return;
                lastW = d ~/ 7;
                final rv = s.lastEvolutionReview;
                if (rv == null) {
                  lines.add('d$d:none');
                  return;
                }
                final sm = rv.review.summary;
                lines.add(
                  'd$d:w${rv.week} blk=${rv.place.blockId} bw=${rv.input.block.pass1.weeks} '
                  'start=${rv.input.block.pass1.startDate.iso} obs=${sm.weeksObserved} '
                  'pl=${sm.sessionsPlanned}/${sm.sessionsCompleted} un=${sm.unlockLevel.code} '
                  'rd=${sm.fatigue.readiness} n=${rv.review.proposals.length} '
                  'logS=${rv.input.log.sessions.length}',
                );
              },
            );
            // ignore: avoid_print
            print(
              'DIAG ${st.month}-${st.day} ${mode.code} $key/$seed done=${r.sessionsDone} blocks=${r.blocksAdded} '
              'pw=${s.program.weeks.length} start=${s.program.start} '
              'entries=${[for (final e in s.planEvolution.entries) '${e.proposal.kind.code}:${e.status}@${e.fromWeek}']} '
              'err=${r.error}\n  ${lines.join('\n  ')}',
            );
            s.dispose();
          });
        }
      }
    }
  }
}
