import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/training_estimate.dart';

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
  // Lignes analysées une à une puis additionnées (sans format de séance).
  TrainingEstimate lines(List<String> source, {String scheme = ''}) {
    final out = TrainingEstimate();
    for (final line in source) {
      out.add(TrainingEstimator.parseLine(line, repScheme: scheme));
    }
    return out;
  }

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
  test('ligne : repos inline, durées et charges décimales', () {
    final e = TrainingEstimator.parseLine(
      '10 tractions 2,5 kg · 30" rest · 20 s hollow hold',
    );
    expect(e.volume('rep').low, 10);
    expect(e.volume('s').low, 20);
    expect(e.rest.low, 30);
    expect(e.tonnage.low, 25);
  });
  test('blocs imbriqués et multiplicateurs suffixés', () {
    final e = TrainingEstimator.parseLine(
      '10 dips + (1 pull-up + 1 muscle-up) ×4 + 20 pompes',
    );
    expect(e.volume('rep').low, 38);
    expect(
      TrainingEstimator.parseLine(
        '3 × (10 pompes + 20 squats)',
      ).volume('rep').low,
      90,
    );
  });
  test('échelle : distance par tour et somme des répétitions', () {
    final e = lines(['400 m run', 'burpees', 'sit-ups'], scheme: '21-15-9');
    expect(e.volume('m').low, 1200);
    expect(e.volume('rep').low, 90);
    expect(TrainingEstimator.scheme('1-2-3-…-15').reduce((a, b) => a + b), 120);
  });
  test('EMOM : plages, rotation et récupération dans le temps fixe', () {
    final e = TrainingEstimator.emom(
      ['min 1-5 : 10 burpees', 'min 6-10 : 20 pompes'],
      rounds: 10,
      interval: 60,
    );
    expect(e.volume('rep').low, 150);
    expect(e.elapsed.low, 600);
    final rotated = TrainingEstimator.emom(
      [
        'min 1, 4, 7… : 10 pompes',
        'min 2, 5, 8… : 20 squats',
        'min 3, 6, 9… : repos',
      ],
      rounds: 10,
      interval: 60,
    );
    expect(rotated.volume('rep').low, 100);
    expect(rotated.elapsed.high, 600);
  });
  test('E2MOM respecte la durée des intervalles', () {
    final e = TrainingEstimator.emom(['5 tractions'], rounds: 6, interval: 120);
    expect(e.volume('rep').low, 30);
    expect(e.elapsed.low, 720);
  });
  test('AMRAP fractionné : durée exacte, tous les repos conservés', () {
    final e = lines([
      'AMRAP 3 min : 3 burpees + 3 squats',
      'Repos 2 min',
      'AMRAP 4 min : 6 burpees + 6 squats',
      'Repos 2 min',
      'AMRAP 5 min : 9 burpees + 9 squats',
    ]);
    expect(e.elapsed.low, closeTo(960, .001));
    expect(e.elapsed.high, closeTo(960, .001));
    expect(e.projected, true);
  });
  test('calories et distances ne sont ni des répétitions ni du tonnage', () {
    final e = lines(['20 cal row', '100 m farmer carry 2×24 kg']);
    expect(e.volume('cal').low, 20);
    expect(e.volume('m').low, 100);
    expect(e.volume('rep').high, 0);
    expect(e.hasTonnage, false);
    expect(TrainingEstimator.externalKg('wall ball 4/6/9 kg'), null);
  });
  test('une prescription inconnue est signalée sans inventer un volume', () {
    final e = TrainingEstimator.parseLine('max pull-ups');
    expect(e.partial, true);
    expect(e.volume('rep').high, 0);
    expect(e.durationLabel, 'À préciser');
  });

  test('EMOM : cash in et cash out sont hors des trente créneaux', () {
    final e = TrainingEstimator.emom(
      ['Cash in : 1000 m row', 'min 1-30 : 10 pompes', 'Cash out : 1000 m row'],
      rounds: 30,
      interval: 60,
    );
    expect(e.volume('m').low, 2000);
    expect(e.volume('rep').low, 300);
    expect(e.elapsed.low, greaterThanOrEqualTo(2240));
    expect(e.elapsed.high, lessThan(2500));
  });
  test('blocs répétés avec repos et unités ne perdent pas de distance', () {
    final e = TrainingEstimator.parseLine('3 × 600 m run · repos 3 min');
    expect(e.volume('m').low, 1800);
    expect(e.rest.low, 360);
    final b = TrainingEstimator.parseLine(
      '3 × (500 m lent + 300 m rapide) · repos 3 min',
    );
    expect(b.volume('m').low, 2400);
    expect(b.rest.low, 360);
  });
  test('les prescriptions ouvertes restent explicitement partielles', () {
    final e = lines([
      'AMRAP 5 min : 2-4-6-8-10… squat jumps · push-ups',
      'Repos 2 min',
      'AMRAP 5 min : max burpees',
    ]);
    expect(e.partial, true);
    expect(e.elapsed.low, 720);
    expect(e.elapsed.high, 720);
  });
  test('échelles bornées dans une ligne et consigne sans repos', () {
    expect(
      TrainingEstimator.parseLine('1-2-3-…-15 pompes').volume('rep').low,
      120,
    );
    expect(
      TrainingEstimator.parseLine('10 pompes sans repos').volume('rep').low,
      10,
    );
  });
  test('les efforts courts sont affichés en secondes', () {
    expect(ex('1×5', tempo: '2-0-1-0').durationLabel, '≈ 15 s');
    final e = lines(['5 pompes', 'max tractions']);
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
    test('aucun nombre non fini ou négatif dans les 1812 exercices', () {
      final estimates = [
        for (final w in app.program.weeks)
          for (final d in w.days) app.dayEstimate(d),
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
    });
  });
}
