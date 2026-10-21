// PR1 (dev7.1.1) — protocoles du programme dans le journal : séries au
// départ chronométré (E2MOM, E90s), EMOM montant jusqu'à l'échec,
// rest-pause, drop set mécanique noté palier par palier.
// Données synthétiques ; stockage simulé.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

Exercise _line(String sets, {String rest = '—', int? restSec}) =>
    Exercise.fromJson({
      'id': 'x',
      'name': 'Traction lestée',
      'sets': {'type': 'text', 'value': sets},
      'load': {'type': 'fixed', 'kg': 0.0},
      'rest': rest,
      'restSec': restSec,
    });

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

  test('E2MOM, E90s, EMOM : une ligne par série, départ au chrono', () {
    final e = _line('8×3 · E2MOM', rest: 'Départ toutes les 2 min');
    final sp = app.logSpec(e);
    expect(sp.kind, 'reps');
    expect(sp.every, 120);
    expect(app.setCount(e), 8);
    expect(app.plannedReps(e, sp, 8), List.filled(8, 3));
    expect(app.restAfterSet(e, sp, 0, 8), isNull);
    expect(app.logSpec(_line('6×2 · E90s')).every, 90);
    expect(app.logSpec(_line('12×6 · EMOM')).every, 60);
    expect(app.logSpec(_line('5×3')).every, isNull);
  });

  test('EMOM montant jusqu’à l’échec : pas de cible calculée', () {
    final e = _line('EMOM 20 min · 10 reps, +1 rep/min jusqu’à l’échec');
    final sp = app.logSpec(e);
    expect(sp.kind, 'emom');
    expect(sp.seconds, 1200);
    expect(app.setCount(e), 1);
    expect(app.plannedReps(e, sp, 1), [null]);
  });

  test('rest-pause : activation puis relances, libellé propre', () {
    final e = _line('1×max puis 2×max (15 s intra) · rest-pause');
    final sp = app.logSpec(e);
    expect(sp.myo, isTrue);
    expect(sp.restPause, isTrue);
    expect(sp.intra, 15);
    expect(app.setCount(e), 3);
  });

  test('drop set mécanique : une ligne par palier, repos en fin de tour', () {
    final e = _line('2 tours × 4 paliers', rest: '3 min', restSec: 180);
    final sp = app.logSpec(e);
    expect(sp.rowPrefix, 'D');
    expect(sp.stages, 4);
    expect(app.setCount(e), 8);
    expect(app.setLabel(sp, 0), '1.1');
    expect(app.setLabel(sp, 5), '2.2');
    expect(app.restAfterSet(e, sp, 0, 8), isNull);
    expect(app.restAfterSet(e, sp, 3, 8), 180);
  });
}
