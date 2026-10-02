// Le banc sur les moteurs réels : il tourne, il est déterministe, ses
// exports sont lisibles.
import 'dart:convert';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final inputs = loadInputs();
  final catalog = inputs.catalog;

  test('tous les profils : programme créé, critères et attentes rendus', () {
    final engine = KalisPlan();
    for (final p in inputs.profiles) {
      final r = evaluateProfile(inputs, engine, p, mode: BenchMode.plan);
      final view = r.view!;
      expect(view.weeks.length, horizonOf(p), reason: p.key);
      expect(view.weeks.first.days, isNotEmpty, reason: p.key);
      expect(r.quality.length, qualityCriteria.length, reason: p.key);
      expect(r.checks.length, p.checks.length, reason: p.key);
      for (final f in r.safety) {
        expect(safetyCriteria, contains(f.code), reason: p.key);
      }
      for (final q in r.quality) {
        final s = q.score;
        if (s != null) {
          expect(s, inInclusiveRange(0, 1), reason: '${p.key} ${q.code}');
        }
      }
      expect(r.trajectory, isNull);
    }
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('déterminisme : deux exécutions, mêmes fichiers à l\'octet près', () {
    final some = <BenchProfile>[
      benchProfileOf('street_06_inter_sets_reps'),
      benchProfileOf('street_07_avance_streetlifting_competition'),
      benchProfileOf('autres_05_course_10_km_debutante'),
    ];
    Map<String, String> once() => renderReport(
      inputs,
      <ProfileReport>[
        for (final p in some)
          evaluateProfile(inputs, KalisPlan(), p, mode: BenchMode.croisement),
      ],
      mode: BenchMode.croisement,
      seed: 0,
      scope: 'tous',
    );
    final a = once();
    final b = once();
    expect(a.keys.toList(), b.keys.toList());
    for (final key in a.keys) {
      expect(a[key], b[key], reason: key);
    }
    expect(a.keys, contains('rapport.json'));
    expect(a.keys, contains('RAPPORT.md'));
    expect(a.keys, contains('programmes/street_06_inter_sets_reps.md'));
    expect(a.keys, contains('trajectoires/street_06_inter_sets_reps.md'));
    final json = jsonDecode(a['rapport.json']!) as Map<String, Object?>;
    expect(json['benchVersion'], kalisBenchVersion);
    expect((json['profiles']! as List<Object?>).length, 3);
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('une autre graine change le programme', () {
    final p = benchProfileOf('street_06_inter_sets_reps');
    final a = programMarkdown(
      ProgramView(catalog, generateProgram(catalog, KalisPlan(), p)),
    );
    final b = programMarkdown(
      ProgramView(catalog, generateProgram(catalog, KalisPlan(), p, seed: 1)),
    );
    expect(a, isNot(b));
  });

  test('export du programme : français, sans identifiant technique', () {
    final p = benchProfileOf('street_07_avance_streetlifting_competition');
    final view = ProgramView(catalog, generateProgram(catalog, KalisPlan(), p));
    final text = programMarkdown(view);
    expect(text, contains('# Programme — ${p.title}'));
    expect(text, contains('## Profil'));
    expect(text, contains('## Semaine 1'));
    expect(text, contains('## Semaine 12'));
    expect(text, contains('ÉCHÉANCE'));
    expect(text, contains(' × '));
    expect(text, contains('rép. en réserve'));
    // Ni identifiant d'exercice, ni code de raison, ni code de rôle.
    expect(
      RegExp(r'\b(sl|sw|cs|cd|mu|cf|ca|mo)-[a-z]').hasMatch(text),
      isFalse,
    );
    expect(text.contains('plan.'), isFalse);
    expect(text.contains('strength.'), isFalse);
    final json = programJson(view);
    expect((json['weeks']! as List<Object?>).length, 12);
    expect(json['eventWeek'], 12);
  });

  test('trajectoire : mesures et export', () {
    final p = benchProfileOf('street_07_avance_streetlifting_competition');
    final program = generateProgram(catalog, KalisPlan(), p);
    final t = simulateTrajectory(catalog, KalisPlan(), p, program.profile);
    expect(t.weeks, 12);
    expect(t.metrics['sessionsPlanned'], greaterThan(0));
    expect(t.metrics['workSets'], greaterThan(0));
    expect(t.rows, isNotEmpty);
    final rate = t.metrics['unwantedFailureRate']! as num;
    expect(rate, inInclusiveRange(0, 1));
    final text = trajectoryMarkdown(t, catalog);
    expect(text, contains('# Trajectoire simulée'));
    expect(text, contains('## Semaine par semaine'));
    expect(text, contains('## Décisions du moteur'));
    expect(
      RegExp(r'\b(sl|sw|cs|cd|mu|cf|ca|mo)-[a-z]').hasMatch(text),
      isFalse,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('athlète simulé : niveau, gain par défaut, réglages du profil', () {
    final spec = athleteSpecOf(benchProfileOf('street_09_elite_streetlifting'));
    expect(spec.level, 3);
    expect(spec.weeklyGain, defaultWeeklyGain[3]);
    expect(
      athleteSpecOf(benchProfileOf('street_01_debutant_complet')).weeklyGain,
      defaultWeeklyGain[0],
    );
  });
}
