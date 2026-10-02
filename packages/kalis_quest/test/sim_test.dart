// Simulation de rythme : chaque archétype tourne ; le tricheur ne gagne
// rien au-delà du plafond ; les garde-fous tiennent sur la durée.
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final engine = KalisQuest();
  const weeks = 26;

  test('huit archétypes, de 2 à 6 séances par semaine', () {
    expect(archetypes, hasLength(8));
    final perWeek = <int>{
      for (final a in archetypes) profileOf(a.profileKey).availability.length,
    };
    expect(perWeek, containsAll(<int>[2, 3, 4, 5, 6]));
    expect(<int>{for (final a in archetypes) a.level}, <int>{0, 1, 2, 3});
    expect(archetypes.any((a) => a.stops.isNotEmpty), isTrue);
    expect(archetypes.any((a) => a.vacations.isNotEmpty), isTrue);
    expect(archetypes.any((a) => a.illnesses.isNotEmpty), isTrue);
    expect(archetypes.any((a) => a.painRate > 0), isTrue);
  });

  for (final a in archetypes) {
    test('${a.key} : $weeks semaines, garde-fous tenus', () {
      final stage = stageOf(a, weeks);
      final r = simulateRun(
        engine: engine,
        stage: stage,
        a: a,
        seed: 1,
        weeks: weeks,
      );
      expect(r.levels, hasLength(weeks));
      expect(r.levelDropped, isFalse);
      expect(r.levels.last, greaterThan(5));
      expect(r.painXp, 0);
      expect(r.worstWeekShare, lessThanOrEqualTo(1));
      expect(r.paidSessions, lessThanOrEqualTo(r.plannedSessions + weeks));
      expect(r.kredits, greaterThan(0));
      expect(r.questsCreated['daily'], greaterThan(weeks * 7));
      expect(r.questsDone['daily'] ?? 0, greaterThan(0));
      expect(
        r.maxChestGap,
        lessThanOrEqualTo(
          engine.params.chestPity + stage.profile.availability.length,
        ),
      );
      final again = simulateRun(
        engine: engine,
        stage: stage,
        a: a,
        seed: 1,
        weeks: weeks,
      );
      expect(again.xp, r.xp);
      expect(again.kredits, r.kredits);
    });
  }

  test('pauses déclarées : semaines en pause, pas de semaine non réussie '
      'pour autant', () {
    final a = archetypeOf('vacances_5x');
    final r = simulateRun(
      engine: engine,
      stage: stageOf(a, 52),
      a: a,
      seed: 2,
      weeks: 52,
    );
    expect(r.weeksPaused, greaterThanOrEqualTo(3));
  });

  test('douleur déclarée : les séances faites quand même ne rapportent '
      'rien', () {
    final a = archetypeOf('maladie_3x');
    final stage = stageOf(a, 52);
    var through = 0;
    var pain = 0;
    for (var seed = 0; seed < 6; seed++) {
      final log = generateLog(a, stage, seed, 52);
      through += log.through;
      final r = simulateRun(
        engine: engine,
        stage: stage,
        a: a,
        seed: seed,
        weeks: 52,
      );
      pain += r.painSessions;
      expect(r.painXp, 0);
    }
    expect(pain, through);
  });

  test('triche par surentraînement : à assiduité parfaite, le tricheur ne '
      'gagne pas plus d\'XP que l\'honnête', () {
    for (final key in <String>['debutant_3x', 'intermediaire_4x']) {
      final base = archetypeOf(key);
      final honest = Archetype(
        key: base.key,
        profileKey: base.profileKey,
        level: base.level,
        adherence: 1,
        fullRate: 1,
        note: '',
      );
      final stage = stageOf(honest, weeks);
      for (var seed = 0; seed < 4; seed++) {
        final h = simulateRun(
          engine: engine,
          stage: stage,
          a: honest,
          seed: seed,
          weeks: weeks,
        );
        final c = simulateRun(
          engine: engine,
          stage: stage,
          a: cheaterOf(honest),
          seed: seed,
          weeks: weeks,
        );
        expect(c.extraSessions, greaterThan(weeks));
        expect(c.xp.last, lessThanOrEqualTo(h.xp.last), reason: '$key $seed');
        // L'XP d'effort reste sous le plafond du programme.
        final cap =
            weeks *
            stage.profile.availability.length *
            (engine.params.sessionXp + engine.params.comboBonusCap);
        expect(c.xpBySource['effort']!, lessThanOrEqualTo(cap));
        expect(c.paidSessions, lessThanOrEqualTo(h.paidSessions));
        expect(c.worstWeekShare, lessThanOrEqualTo(1));
      }
    }
  });
}
