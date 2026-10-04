/// Export lisible d'une saison croisée (lot CX, 0.2.0) : le plan de saison
/// tel que les blocs l'ont réalisé (chaque bloc, sa phase, ses semaines,
/// ce qui l'a nourri : résultats de test, résumé d'adaptation, changement
/// d'échéance), puis la trajectoire semaine par semaine (export des
/// trajectoires au contrat 0.4.0). Français, sans identifiant technique.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show coachPhaseLabel;

import 'season.dart';
import 'trajectory.dart';
import 'trajectory_export.dart';

String _value(Benchmark b, Catalog catalog) {
  final name = catalog.find(b.exerciseId)?.name ?? b.exerciseId;
  final load = b.externalLoadKg;
  final reps = b.reps;
  final seconds = b.seconds;
  if (seconds != null) {
    return '$name : $seconds s';
  }
  if (load != null && load > 0 && reps != null) {
    final kg = load == load.roundToDouble()
        ? load.toStringAsFixed(0)
        : load.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');
    return '$name : $reps × +${kg.replaceAll('.', ',')} kg';
  }
  if (reps != null) {
    return '$name : $reps répétitions';
  }
  return name;
}

/// Section « Plan de saison et blocs » de la saison [t].
String seasonBlocksMarkdown(Trajectory t, Catalog catalog) {
  final run = t.run;
  final b = StringBuffer()
    ..writeln('## Plan de saison et blocs')
    ..writeln()
    ..writeln(
      'Chaque bloc est écrit par le moteur de création au moment où il '
      'commence, d\'après le profil à jour (résultats de test reportés) et '
      'le point de fin de bloc du moteur d\'évolution (maxima estimés, '
      'assiduité, douleurs, exercices écartés).',
    )
    ..writeln()
    ..writeln('| Bloc | Semaines | Phase | Semaines du bloc | Écrit d\'après |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (var k = 0; k < run.blocks.length; k++) {
    final block = run.blocks[k];
    final start = k < run.blockWeeks.length ? run.blockWeeks[k] : 0;
    final next = k + 1 < run.blockWeeks.length
        ? run.blockWeeks[k + 1]
        : t.weeks;
    if (start >= t.weeks) {
      break;
    }
    final end = next > t.weeks ? t.weeks : next;
    final phase = block.pass1.intent?.phase;
    final weeks = <String>[
      for (final w in block.pass2.weeks)
        if (start + w.weekIndex < end)
          w.intent == null ? '—' : coachPhaseLabel(w.intent!.code),
    ];
    final sources = <String>[];
    if (k == 0) {
      sources.add('le profil de départ');
    } else {
      final previous = run.blockWeeks[k - 1];
      final tests = <String>[];
      for (final (week, review) in run.reviews) {
        if (week < previous || week >= start) {
          continue;
        }
        for (final r in review.testResults ?? const <Benchmark>[]) {
          tests.add(_value(r, catalog));
        }
      }
      sources.add(
        tests.isEmpty
            ? 'le point de fin du bloc $k'
            : 'les tests du bloc $k (${tests.join(' ; ')}) et son point de '
                  'fin de bloc',
      );
    }
    for (final (week, label) in run.changes) {
      if (week == start) {
        sources.add('changement : $label');
      }
    }
    b.writeln(
      '| ${k + 1} | ${start + 1} à $end | '
      '${phase == null ? '—' : coachPhaseLabel(phase.code)} | '
      '${weeks.join(', ')} | ${sources.join(' ; ')} |',
    );
  }
  return b.toString();
}

/// Saison [t] (scénario [scenario]) en Markdown : la trajectoire au
/// contrat 0.4.0, titrée comme une saison, avec le plan de saison et ses
/// blocs avant le bilan. [others] : la même saison sous les autres modèles
/// de vérité.
String seasonMarkdown(
  Trajectory t,
  Catalog catalog, {
  List<Trajectory> others = const <Trajectory>[],
  SeasonScenario scenario = SeasonScenario.base,
}) {
  var text = coachTrajectoryMarkdown(t, catalog, others: others);
  text = text.replaceFirst(
    '# Trajectoire simulée — ',
    '# Saison simulée — ',
  );
  final scenarioLine = scenario == SeasonScenario.base
      ? ''
      : '**Scénario** : ${scenario.label}.\n\n';
  final blocks = seasonBlocksMarkdown(t, catalog);
  final at = text.indexOf('## Bilan');
  if (at < 0) {
    return '$text\n$scenarioLine$blocks';
  }
  return '${text.substring(0, at)}$scenarioLine$blocks\n'
      '${text.substring(at)}';
}
