import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/training_estimate.dart';
import 'package:streetlift_tracker/wod_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TrainingEstimate ex(
    String sets, {
    String name = 'Pompes',
    String rest = '60 s',
    String tempo = '',
    double? kg,
  }) => TrainingEstimator.exercise(
    Exercise.manual(
      id: 'e',
      name: name,
      setsText: sets,
      rest: rest,
      tempo: tempo,
    ),
    prescription: sets,
    kg: kg,
  );
  TrainingEstimate wod(
    List<String> lines, {
    String type = 'fortime',
    int rounds = 0,
    int rest = 0,
    int minutes = 0,
    String scheme = '',
  }) => TrainingEstimator.wod(
    Wod(
      id: 'w',
      name: 'Test',
      lines: lines,
      type: type,
      rounds: rounds,
      restSec: rest,
      minutes: minutes,
      scheme: scheme,
    ),
  );

  test('séries, tempo exact et repos uniquement entre les séries', () {
    final e = ex('3×5', tempo: '3-0-1-0', kg: 10);
    expect(e.volume('rep').low, 15);
    expect(e.work.low, 60);
    expect(e.rest.low, 120);
    expect(e.elapsed.low, 180);
    expect(e.tonnage.low, 150);
  });
  test('repos composé et fourchettes sont conservés', () {
    expect(TrainingEstimator.duration('2 min 30')!.low, 150);
    final e = ex('3×8-12', rest: '2-3 min');
    expect(e.volume('rep').low, 24);
    expect(e.volume('rep').high, 36);
    expect(e.rest.low, 240);
    expect(e.rest.high, 360);
  });
  test('unilatéral : deux côtés ; charge par haltère explicitée', () {
    final e = ex('3×10/jambe', name: 'Fentes marchées (par haltère)', kg: 10);
    expect(e.volume('rep').low, 60);
    expect(e.tonnage.low, 1200);
    expect(
      ex('3×12', name: 'Rowing unilatéral (par haltère)', kg: 10).tonnage.low,
      720,
    );
  });
  test('tenues ne deviennent pas des répétitions', () {
    final e = ex('3×30 s', tempo: 'Isométrie');
    expect(e.volume('s').low, 90);
    expect(e.volume('rep').high, 0);
    expect(e.elapsed.low, 210);
  });
  test('myo et clusters comptent chaque micro-repos', () {
    final myo = ex('1×12-15 puis 4×(4)', rest: '10 s intra');
    expect(myo.volume('rep').low, 28);
    expect(myo.volume('rep').high, 31);
    expect(myo.rest.low, 40);
    final cluster = ex('4×(3×2) · 20 s intra', rest: '2 min');
    expect(cluster.volume('rep').low, 24);
    expect(cluster.rest.low, 520);
  });
  test('HIIT : même durée que le chrono, sans dernier repos', () {
    final e = ex('8× (30 s effort / 30 s repos)');
    expect(e.elapsed.low, 450);
    expect(e.work.low, 240);
    expect(e.rest.low, 210);
  });
  test('WOD : repos inline, durées et charges décimales', () {
    final e = wod(['10 tractions 2,5 kg · 30" rest · 20 s hollow hold']);
    expect(e.volume('rep').low, 10);
    expect(e.volume('s').low, 20);
    expect(e.rest.low, 30);
    expect(e.tonnage.low, 25);
  });
  test('blocs imbriqués et multiplicateurs suffixés', () {
    final e = wod(['10 dips + (1 pull-up + 1 muscle-up) ×4 + 20 pompes']);
    expect(e.volume('rep').low, 38);
    expect(wod(['3 × (10 pompes + 20 squats)']).volume('rep').low, 90);
  });
  test('échelle : distance par tour et somme des répétitions', () {
    final e = wod(['400 m run', 'burpees', 'sit-ups'], scheme: '21-15-9');
    expect(e.volume('m').low, 1200);
    expect(e.volume('rep').low, 90);
    expect(TrainingEstimator.scheme('1-2-3-…-15').reduce((a, b) => a + b), 120);
  });
  test('EMOM : plages, rotation et récupération dans le temps fixe', () {
    final e = wod(
      ['min 1-5 : 10 burpees', 'min 6-10 : 20 pompes'],
      type: 'emom',
      rounds: 10,
    );
    expect(e.volume('rep').low, 150);
    expect(e.elapsed.low, 600);
    final rotated = wod(
      [
        'min 1, 4, 7… : 10 pompes',
        'min 2, 5, 8… : 20 squats',
        'min 3, 6, 9… : repos',
      ],
      type: 'emom',
      rounds: 10,
    );
    expect(rotated.volume('rep').low, 100);
    expect(rotated.elapsed.high, 600);
  });
  test('E2MOM respecte la durée des intervalles', () {
    final e = TrainingEstimator.wod(
      Wod(
        id: 'e2',
        name: 'E2',
        type: 'emom',
        rounds: 6,
        interval: 120,
        lines: ['5 tractions'],
      ),
    );
    expect(e.volume('rep').low, 30);
    expect(e.elapsed.low, 720);
  });
  test('AMRAP fractionné : durée exacte, tous les repos conservés', () {
    final e = wod(
      [
        'AMRAP 3 min : 3 burpees + 3 squats',
        'Repos 2 min',
        'AMRAP 4 min : 6 burpees + 6 squats',
        'Repos 2 min',
        'AMRAP 5 min : 9 burpees + 9 squats',
      ],
      type: 'routine',
      rest: 120,
    );
    expect(e.elapsed.low, closeTo(960, .001));
    expect(e.elapsed.high, closeTo(960, .001));
    expect(e.projected, true);
  });
  test('rounds : n moins un repos ; cap distinct du temps de complétion', () {
    final e = wod(['10 pompes'], type: 'rounds', rounds: 3, rest: 120);
    expect(e.volume('rep').low, 30);
    expect(e.rest.low, 240);
    final capped = wod(['500 burpees'], minutes: 10);
    expect(capped.elapsed.low, greaterThan(600));
    expect(capped.capSeconds, 600);
  });
  test('calories et distances ne sont ni des répétitions ni du tonnage', () {
    final e = wod(['20 cal row', '100 m farmer carry 2×24 kg']);
    expect(e.volume('cal').low, 20);
    expect(e.volume('m').low, 100);
    expect(e.volume('rep').high, 0);
    expect(e.hasTonnage, false);
    expect(TrainingEstimator.externalKg('wall ball 4/6/9 kg'), null);
  });
  test('une prescription inconnue est signalée sans inventer un volume', () {
    final e = wod(['max pull-ups']);
    expect(e.partial, true);
    expect(e.volume('rep').high, 0);
    expect(e.durationLabel, 'À préciser');
  });

  test('EMOM : cash in et cash out sont hors des trente créneaux', () {
    final e = wod(
      ['Cash in : 1000 m row', 'min 1-30 : 10 pompes', 'Cash out : 1000 m row'],
      type: 'emom',
      rounds: 30,
    );
    expect(e.volume('m').low, 2000);
    expect(e.volume('rep').low, 300);
    expect(e.elapsed.low, greaterThanOrEqualTo(2240));
    expect(e.elapsed.high, lessThan(2500));
  });
  test('prescriptions croisées et distances dans les consignes', () {
    final e = wod([
      '20 push-ups · 1 sit-up',
      '19 push-ups · 2 sit-ups',
      '… jusqu’à 1 push-up · 20 sit-ups',
    ], scheme: '20/1 → 1/20');
    expect(e.volume('rep').low, 420);
    expect(e.partial, false);
    final run = TrainingEstimator.wod(
      Wod(
        id: 'run',
        name: 'Run',
        scheme: '27-21-15-12-9',
        lines: ['burpees', 'sit-ups'],
        notes: '400 m run entre chaque round.',
      ),
    );
    expect(run.volume('m').low, 1600);
  });
  test('blocs répétés avec repos et unités ne perdent pas de distance', () {
    final e = wod(['3 × 600 m run · repos 3 min'], type: 'routine');
    expect(e.volume('m').low, 1800);
    expect(e.rest.low, 360);
    final b = wod([
      '3 × (500 m lent + 300 m rapide) · repos 3 min',
    ], type: 'routine');
    expect(b.volume('m').low, 2400);
    expect(b.rest.low, 360);
  });
  test('les prescriptions ouvertes restent explicitement partielles', () {
    final e = wod([
      'AMRAP 5 min : 2-4-6-8-10… squat jumps · push-ups',
      'Repos 2 min',
      'AMRAP 5 min : max burpees',
    ], type: 'routine');
    expect(e.partial, true);
    expect(e.elapsed.low, 720);
    expect(e.elapsed.high, 720);
  });
  test(
    'les historiques anciens et les prescriptions modifiées ne calibrent pas',
    () {
      final w = Wod(id: 'h', name: 'History', lines: ['100 pompes']);
      for (final seconds in [300, 320, 340]) {
        w.results.add(
          WodResult(
            at: '2026-09-20T12:00:00',
            score: 'Fini',
            seconds: seconds,
            prescription: w.prescriptionKey,
          ),
        );
      }
      w.results.add(
        WodResult(
          at: '2026-09-20T13:00:00',
          score: 'Abandon',
          seconds: 15,
          completed: false,
          prescription: w.prescriptionKey,
        ),
      );
      w.results.add(
        WodResult(at: '2026-09-20T13:00:00', score: 'Ancien', seconds: 20),
      );
      final e = TrainingEstimator.wod(w);
      expect(e.historyCount, 3);
      expect(e.observed!.low, 272);
      expect(e.observed!.high, closeTo(368, .001));
      final restored = Wod.fromJson(w.toJson());
      expect(TrainingEstimator.wod(restored).historyCount, 3);
      restored.lines = ['200 pompes'];
      expect(TrainingEstimator.wod(restored).observed, null);
      expect(WodResult.fromJson({'at': '2026-01-01'}).prescription, null);
    },
  );
  test('échelles bornées dans une ligne et consigne sans repos', () {
    expect(wod(['1-2-3-…-15 pompes']).volume('rep').low, 120);
    expect(wod(['10 pompes sans repos']).volume('rep').low, 10);
  });
  test('les efforts courts sont affichés en secondes', () {
    expect(ex('1×5', tempo: '2-0-1-0').durationLabel, '≈ 15 s');
    final e = wod(['5 pompes', 'max tractions']);
    expect(e.partial, true);
    expect(e.durationLabel, endsWith(' s'));
  });
  test('une échelle gigantesque est bornée avant itération', () {
    expect(TrainingEstimator.scheme('1-2-…-1000000000').length, 1000);
  });

  group('intégration programme', () {
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
    test('le cache se renouvelle après modification ou résultat', () {
      expect(
        app
            .difficultyScore(
              Wod(
                id: 'bounded',
                name: 'Bounded',
                scheme: '1-2-…-1000000000',
                lines: ['pompes'],
              ),
            )
            .isFinite,
        true,
      );
      final w = Wod(id: 'cache', name: 'Cache', lines: ['10 pompes']);
      final first = app.wodEstimate(w);
      expect(identical(first, app.wodEstimate(w)), true);
      w.lines = ['20 pompes'];
      expect(app.wodEstimate(w).volume('rep').low, 20);
      for (var i = 0; i < 3; i++) {
        app.addWodResult(
          w,
          WodResult(at: '2026-09-20T10:00:00', score: 'Fini', seconds: 90),
        );
      }
      expect(app.wodEstimate(w).historyCount, 3);
      w.results.clear();
      expect(app.wodEstimate(w).historyCount, 0);
    });
    test('les supersets partagent leur repos et les EMOM leur horloge', () {
      DayPlan day(String text) => DayPlan.manual(
        j: 1,
        title: 'Test',
        exercises: [
          Exercise.manual(id: 'a', name: 'Dips', setsText: text, rest: '90 s'),
          Exercise.manual(
            id: 'b',
            name: 'Pompes enchaînées',
            setsText: text,
            rest: '90 s',
          ),
        ],
      );
      expect(app.dayEstimate(day('4×10')).rest.low, 270);
      expect(app.dayEstimate(day('EMOM 12 min × 5 reps')).elapsed.high, 720);
    });
    test('le repos 2 min 30 corrige aussi le chrono automatique', () {
      final e = Exercise.manual(
        id: 'e',
        name: 'Tractions',
        setsText: '3×10',
        rest: '2 min 30',
        restSec: 120,
      );
      expect(app.restAfterSet(e, app.logSpec(e), 0, 3), 150);
      // La dernière série lance aussi son repos (transition vers la suite).
      expect(app.restAfterSet(e, app.logSpec(e), 2, 3), 150);
      expect(app.exerciseEstimate(e).rest.low, 300);
    });
    test(
      'aucun nombre non fini ou négatif dans les 1812 exercices et 1 000 WODs',
      () {
        final estimates = [
          for (final w in app.program.weeks)
            for (final d in w.days) app.dayEstimate(d),
          for (final w in app.wods) app.wodEstimate(w),
        ];
        for (final e in estimates) {
          for (final span in [
            e.elapsed,
            e.work,
            e.rest,
            e.transitions,
            e.tonnage,
          ]) {
            expect(span.low.isFinite && span.high.isFinite, true);
            expect(span.low, greaterThanOrEqualTo(0));
            expect(span.high, greaterThanOrEqualTo(span.low));
          }
        }
      },
    );
  });
}
