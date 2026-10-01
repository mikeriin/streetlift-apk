import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/timers.dart';

void main() {
  setUp(() {
    store.settings.sound = store.settings.vibration = false;
    store.settings.prepSec = 0;
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
