import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/timers.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_screen.dart' show parseT;

void main() {
  setUp(() {
    store.settings.sound = store.settings.vibration = false;
    store.settings.prepSec = 0;
  });
  test('validation des temps', () {
    expect(parseT('12:34'), 754);
    expect(parseT('1:02:03'), 3723);
    expect(parseT("3'45\""), 225);
    for (final value in ['1:60', '-1', '1:2:3:4', 'abc', '2:-4', '']) {
      expect(parseT(value), null);
    }
  });
  test('un résultat incomplet ou nul ne devient pas un record', () {
    final w = Wod(
      id: 'a',
      name: 'a',
      results: [
        WodResult(at: '', score: '0', seconds: 0),
        WodResult(at: '', score: 'Incomplet', seconds: 10, completed: false),
        WodResult(at: '', score: '2:00', seconds: 120),
      ],
    );
    expect(w.best()!.seconds, 120);
  });
  test('AMRAP : priorité aux rounds, même au-delà de 1000 reps', () {
    final w = Wod(
      id: 'a',
      name: 'a',
      type: 'amrap',
      results: [
        WodResult(at: '', score: 'A', rounds: 2, reps: 2000),
        WodResult(at: '', score: 'B', rounds: 3, reps: 0),
      ],
    );
    expect(w.best()!.score, 'B');
  });
  test('le chronomètre garde les fractions de seconde entre pauses', () {
    fakeAsync((async) {
      final c = WodClock(now: async.getClock(DateTime(2026)).now);
      c.startStopwatch();
      async.elapse(const Duration(milliseconds: 550));
      c.toggle();
      async.elapse(const Duration(seconds: 20));
      c.toggle();
      async.elapse(const Duration(milliseconds: 550));
      c.stop();
      expect(c.elapsed, 1);
      c.dispose();
    });
  });
  test(
    'un lap prend le temps exact, sans dépendre du dernier rafraîchissement',
    () {
      fakeAsync((async) {
        final c = WodClock(now: async.getClock(DateTime(2026)).now);
        c.startStopwatch();
        async.elapse(const Duration(milliseconds: 1999));
        c.lap();
        expect(c.laps, [1]);
        async.elapse(const Duration(milliseconds: 10));
        c.lap();
        expect(c.laps, [1, 2]);
        c.dispose();
      });
    },
  );
  test('AMRAP terminé garde sa durée cible après arrière-plan', () {
    fakeAsync((async) {
      var now = DateTime(2026);
      final c = WodClock(now: () => now);
      c.startCountdown(60);
      now = now.add(const Duration(minutes: 10));
      async.elapse(const Duration(seconds: 1));
      expect(c.elapsed, 60);
      expect(c.finished, true);
      expect(c.remaining, 0);
      c.dispose();
    });
  });
  test('EMOM rattrape les intervalles et ne recommence pas après la fin', () {
    fakeAsync((async) {
      var now = DateTime(2026);
      final c = WodClock(now: () => now);
      c.startEmom(5, 60);
      now = now.add(const Duration(seconds: 135));
      async.elapse(const Duration(seconds: 1));
      expect(c.emomRound, 3);
      expect(c.remaining, 45);
      now = now.add(const Duration(minutes: 10));
      async.elapse(const Duration(seconds: 1));
      expect(c.elapsed, 300);
      expect(c.emomRound, 5);
      expect(c.finished, true);
      c.toggle();
      expect(c.running, false);
      c.dispose();
    });
  });
  test('le repos inter-rounds est figé pendant une pause', () {
    fakeAsync((async) {
      final c = WodClock(now: async.getClock(DateTime(2026)).now);
      c.startStopwatch();
      c.lap(rest: 30);
      async.elapse(const Duration(seconds: 10));
      c.toggle();
      expect(c.restLeft, 20);
      async.elapse(const Duration(seconds: 50));
      c.toggle();
      async.elapse(const Duration(seconds: 1));
      expect(c.restLeft, 19);
      c.dispose();
    });
  });
  test('le bouton Round ne peut pas compter pendant le repos', () {
    fakeAsync((async) {
      final c = WodClock(now: async.getClock(DateTime(2026)).now);
      c.startStopwatch();
      c.lap(rest: 30);
      c.lap(rest: 30);
      expect(c.round, 1);
      c.dispose();
    });
  });
  test(
    'un compte à rebours vide ne plante pas et les repos nuls sont ignorés',
    () {
      fakeAsync((async) {
        final c = TimerCtl(now: async.getClock(DateTime(2026)).now);
        c.emom(0, 60);
        expect(c.running, false);
        c.startInterval(2, 5, 0);
        async.elapse(const Duration(seconds: 5));
        expect(c.label, 'EFFORT 2/2');
        async.elapse(const Duration(seconds: 5));
        expect(c.running, false);
        c.dispose();
      });
    },
  );
  test('le chrono max fige le temps exact au clic Stop', () {
    fakeAsync((async) {
      var now = DateTime(2026);
      final c = TimerCtl(now: () => now);
      c.stopwatch('MAX');
      now = now.add(const Duration(seconds: 12));
      c.stop();
      expect(c.elapsed, 12);
      expect(c.visible, true);
      c.dispose();
    });
  });
  test('le micro-repos ne rajoute pas un décompte de préparation', () {
    fakeAsync((async) {
      store.settings.prepSec = 5;
      final c = TimerCtl(now: async.getClock(DateTime(2026)).now);
      c.single('INTRA', 10, prepare: false);
      expect(c.label, 'INTRA');
      async.elapse(const Duration(seconds: 10));
      expect(c.running, false);
      c.dispose();
    });
  });
}
