// Records personnels par nom d'exercice (bannière en direct, records d'une
// séance) : repris de game_test.dart (G12 retire l'ancienne couche « jeu »,
// les records restent).
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/records.dart';
import 'package:streetlift_tracker/search.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  test(
    'records : 1RM estimé lesté et reps au poids de corps, séance exclue',
    () {
      final logs = <String, SessionLog>{
        'S1-J1': SessionLog(
          done: true,
          finishedAt: '2026-09-01T10:00:00',
          exerciseNames: {'a': 'Dips lestés', 'b': 'Pompes'},
          ex: {
            'a': ExerciseLog(
              sets: [SetEntry(kg: '20', reps: '5', done: true)],
            ),
            'b': ExerciseLog(sets: [SetEntry(reps: '30', done: true)]),
          },
        ),
        'S2-J1': SessionLog(
          done: true,
          finishedAt: '2026-09-08T10:00:00',
          exerciseNames: {'a': 'Dips lestés'},
          ex: {
            'a': ExerciseLog(
              sets: [SetEntry(kg: '40', reps: '3', done: true)],
            ),
          },
        ),
      };
      final bests = exerciseBests(logs, excludeKey: 'S2-J1');
      expect(
        bests[normalizeText('Dips lestés')]!.bestE1rm,
        closeTo(20 * (1 + 5 / 30), 1e-9),
      );
      expect(recordFor(bests, 'Dips lestés', '40', '3'), isNotNull);
      expect(recordFor(bests, 'Dips lestés', '20', '5'), isNull);
      expect(recordFor(bests, 'Pompes', '', '31')!.weighted, isFalse);
      expect(recordFor(bests, 'Pompes', '', '30'), isNull);
      expect(recordFor(bests, 'Inconnu', '10', '10'), isNull);
      final all = exerciseBests(logs);
      expect(all[normalizeText('Dips lestés')]!.bestKg, 40);
    },
  );

}
