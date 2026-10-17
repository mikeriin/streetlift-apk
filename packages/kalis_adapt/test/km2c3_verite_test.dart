// Modèle de vérité du banc (lot KM2c3, portage de la correction de KM1c4,
// `reference/banc/verite.py` ; `reference/tests/test_kr1_violations.py`,
// `test_douleur_tendineuse_inconnue_tant_que_non_signalee`) : un épisode de
// douleur qui commence — imposé par la fiche (`advance`) ou tendineux du
// poignet (`endWeek`, modèle b, tolérance de tenue dépassée) — n'est connu du
// moteur qu'une fois signalé. Avant la correction, le drapeau restait vrai
// depuis un épisode antérieur et une hausse de charge sur une douleur jamais
// signalée comptait comme aggravation (4 cas de KR1, `street_10`).
import 'package:kalis_adapt/kalis_adapt.dart' show ExerciseBook;
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final key = streetKeys().first;
  final profile = streetProfile(key);
  final book = ExerciseBook(loadCatalog(), profile);

  test('épisode de la fiche : inconnu tant qu\'il n\'est pas signalé', () {
    const spec = AthleteSpec(
      key: 'test',
      profileKey: 'test',
      level: 1,
      weeklyGain: 0.01,
      painZone: BodyZone.elbow,
      painFromDay: 10,
      painDays: 7,
      painIntensity: 5,
    );
    final a = SimAthlete(spec, profile, book, 1, kind: TruthKind.b);
    a.setForTest(painKnown: true);
    expect(a.painKnown, isTrue);
    a.advance(10);
    expect(a.inPain, isTrue);
    expect(a.painKnown, isFalse);
    // Signalé en fin de séance : connu.
    expect(a.sessionPains(), isNotEmpty);
    expect(a.painKnown, isTrue);
  });

  test('épisode tendineux (modèle b) : inconnu tant qu\'il n\'est pas '
      'signalé', () {
    const spec = AthleteSpec(
      key: 'test',
      profileKey: 'test',
      level: 1,
      weeklyGain: 0.01,
    );
    final b = SimAthlete(spec, profile, book, 2, kind: TruthKind.b);
    b.setForTest(painKnown: true, tendon: 10.0, holdWeek: 10.0 * 1.3 + 11);
    b.endWeek();
    expect(b.inPain, isTrue);
    expect(b.painZone, BodyZone.wristHand);
    expect(b.painKnown, isFalse);
  });
}
