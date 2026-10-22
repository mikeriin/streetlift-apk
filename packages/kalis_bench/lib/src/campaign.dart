/// Campagne street : chaque profil street du banc, simulé sur plusieurs
/// graines et sous chaque modèle de vérité, avec `kalis_adapt` (boucle
/// complète), `kalis_adapt` en comportement 0.1 (boucle complète), un coach
/// simple à la note d'effort et l'oracle (programme égal).
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';
import 'program.dart';
import 'trajectory.dart';

/// Politiques de la campagne street, dans l'ordre des tableaux.
const List<String> streetCampaignPolicies = <String>[
  'kalis_adapt',
  'kalis_adapt_0_1',
  'coach_rpe',
  'oracle',
];

/// Semaines minimales d'une simulation de la campagne street pour un
/// profil sans échéance.
const int streetCampaignMinWeeks = 16;

/// Semaines simulées pour le profil [bench] : jusqu'à son échéance quand
/// il en a une, sinon au moins [streetCampaignMinWeeks].
int streetCampaignWeeks(BenchProfile bench) {
  final horizon = horizonOf(bench);
  if (bench.mainEvent != null) {
    return horizon;
  }
  return horizon < streetCampaignMinWeeks ? streetCampaignMinWeeks : horizon;
}

double _round(double v) => (v * 100000).roundToDouble() / 100000;

double _adherence(List<SimRun> runs) {
  var done = 0;
  var planned = 0;
  for (final r in runs) {
    done += r.sessionsDone;
    planned += r.sessionsPlanned;
  }
  return planned == 0 ? 0 : done / planned;
}

/// Campagne du profil [bench] (profil des moteurs : [profile]) sur [seeds]
/// graines par modèle de vérité et par politique.
Map<String, Object?> streetCampaignOf(
  Catalog catalog,
  PlanEngine plan,
  BenchProfile bench,
  AthleteProfile profile, {
  required int seeds,
}) {
  final weeks = streetCampaignWeeks(bench);
  final spec = athleteSpecOf(bench);
  final truths = <String, Object?>{};
  for (final truth in TruthKind.values) {
    final byPolicy = <String, List<SimRun>>{
      for (final name in streetCampaignPolicies) name: <SimRun>[],
    };
    final unlock = <String, int>{
      for (final name in streetCampaignPolicies) name: 0,
    };
    for (var seed = 0; seed < seeds; seed++) {
      for (final name in streetCampaignPolicies) {
        final engine = name == 'kalis_adapt'
            ? KalisAdapt()
            : (name == 'kalis_adapt_0_1' ? KalisAdapt(legacy: true) : null);
        final SimPolicy policy = engine != null
            ? KalisAdaptPolicy(engine)
            : (name == 'coach_rpe' ? RpeCoachPolicy() : OraclePolicy());
        final run = simulate(
          catalog: catalog,
          spec: spec,
          profile: profile,
          seed: seed,
          policy: policy,
          program: SimProgram(catalog, plan, profile, seed: 0),
          weeks: weeks,
          loop: engine,
          truthKind: truth,
        );
        for (final p in run.proposals) {
          final need = requiredUnlock[p.kind];
          if (need != null) {
            final at = run.unlockWeek[need];
            if (at == null || p.week < at) {
              unlock[name] = unlock[name]! + 1;
            }
          }
        }
        run.sessions.clear();
        run.blocks.clear();
        run.served.clear();
        run.reviews.clear();
        byPolicy[name]!.add(run);
      }
    }
    truths[truth.name] = <String, Object?>{
      for (final name in streetCampaignPolicies)
        name: <String, Object?>{
          ...CoachMetrics(byPolicy[name]!).toJson(),
          'unlockViolations': unlock[name],
          'painAggravations': _round(
            byPolicy[name]!.fold<int>(0, (a, r) => a + r.painAggravations) /
                (seeds == 0 ? 1 : seeds),
          ),
          'adherence': _round(_adherence(byPolicy[name]!)),
        },
    };
  }
  return <String, Object?>{
    'key': bench.key,
    'title': bench.title,
    'level': bench.level.code,
    'weeks': weeks,
    'seeds': seeds,
    'truths': truths,
  };
}

String _f(Object? stat, {int digits = 2, bool percent = false}) {
  if (stat is! Map<String, Object?>) {
    return '—';
  }
  final n = stat['n'];
  final mean = stat['mean'];
  if (n is! int || n == 0 || mean is! num) {
    return '—';
  }
  final v = percent ? mean * 100 : mean.toDouble();
  return '${v.toStringAsFixed(digits).replaceAll('.', ',')}${percent ? ' %' : ''}';
}

String _truthTitle(String code) => switch (code) {
  'a' => 'Modèle A (celui de 0.1 : courbe exponentielle, notes continues)',
  'b' =>
    'Modèle B (courbe linéaire, notes entières plafonnées, récupération '
        'hyperbolique, tendons)',
  'c' =>
    'Modèle C (courbe en puissance, forme et fatigue, mauvais jours, '
        'désentraînement)',
  _ => code,
};

/// La campagne street [profiles] (une entrée par profil, voir
/// [streetCampaignOf]) en Markdown.
String streetCampaignMarkdown(List<Map<String, Object?>> profiles) {
  final b = StringBuffer()
    ..writeln('# Campagne street — `kalis_adapt` sur les profils du banc')
    ..writeln()
    ..writeln(
      'Document généré par `dart run bin/kalis_bench_cli.dart --rapport '
      '<dossier>` (fichier `campagne_street.json`). Chaque profil street du '
      'banc est simulé jusqu\'à son échéance (au moins '
      '$streetCampaignMinWeeks semaines sans échéance), sur '
      '${profiles.isEmpty ? 0 : profiles.first['seeds']} graines par modèle '
      'de vérité et par politique : `kalis_adapt` (boucle complète), '
      '`kalis_adapt` en comportement 0.1 sur les mêmes programmes (boucle '
      'complète), un coach simple à la note d\'effort (4 % de charge par '
      'point d\'écart) et l\'oracle, ces deux derniers à programme égal.',
    )
    ..writeln()
    ..writeln(
      'Colonnes : écart absolu moyen entre l\'effort affiché et l\'effort '
      'réel (répétitions en réserve, cibles atteignables) ; part des séries '
      'au moins 2 répétitions plus dures que visé ; échecs non voulus ; '
      'progression réelle par semaine ; plus forte hausse à schéma égal '
      '(mouvement principal) et nombre de hausses de plus de 10 % en '
      'plusieurs crans ; tentatives réussies ; performance du jour de '
      'l\'échéance rapportée au maximum réel du jour ; hausses sur une zone '
      'douloureuse (moyenne par simulation).',
    );
  for (final truth in const <String>['a', 'b', 'c']) {
    b
      ..writeln()
      ..writeln('## ${_truthTitle(truth)}')
      ..writeln()
      ..writeln(
        '| Profil | Politique | Écart d\'effort | Plus dures | Échecs | '
        'Progression / sem. | Hausse max | Pics | Tentatives | Échéance | '
        'Douleur |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
      );
    for (final p in profiles) {
      final truths = p['truths'];
      if (truths is! Map<String, Object?>) {
        continue;
      }
      final t = truths[truth];
      if (t is! Map<String, Object?>) {
        continue;
      }
      for (final name in streetCampaignPolicies) {
        final m = t[name];
        if (m is! Map<String, Object?>) {
          continue;
        }
        final rise = m['maxSchemeRise'];
        b.writeln(
          '| ${name == streetCampaignPolicies.first ? p['key'] : ''} | '
          '`$name` | ${_f(m['effortGap'])} | '
          '${_f(m['harderRate'], digits: 1, percent: true)} | '
          '${_f(m['failRate'], digits: 2, percent: true)} | '
          '${_f(m['weeklyGain'], digits: 3, percent: true)} | '
          '${rise is num ? '${(rise * 100).toStringAsFixed(1).replaceAll('.', ',')} %' : '—'} | '
          '${m['schemeRisesOverLimit']} | '
          '${_f(m['attemptRate'], digits: 0, percent: true)} | '
          '${_f(m['eventPerformance'], digits: 1, percent: true)} | '
          '${m['painAggravations']} |',
        );
      }
    }
  }
  // Moyennes par politique et par modèle.
  b
    ..writeln()
    ..writeln('## Moyennes sur les profils')
    ..writeln()
    ..writeln(
      '| Modèle | Politique | Écart d\'effort | Plus dures | Échecs | '
      'Progression / sem. | Tentatives | Échéance |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final truth in const <String>['a', 'b', 'c']) {
    for (final name in streetCampaignPolicies) {
      final sums = <String, double>{};
      final counts = <String, int>{};
      for (final p in profiles) {
        final truths = p['truths'];
        final t = truths is Map<String, Object?> ? truths[truth] : null;
        final m = t is Map<String, Object?> ? t[name] : null;
        if (m is! Map<String, Object?>) {
          continue;
        }
        for (final key in const <String>[
          'effortGap',
          'harderRate',
          'failRate',
          'weeklyGain',
          'attemptRate',
          'eventPerformance',
        ]) {
          final stat = m[key];
          if (stat is Map<String, Object?> &&
              stat['n'] is int &&
              (stat['n']! as int) > 0 &&
              stat['mean'] is num) {
            sums[key] = (sums[key] ?? 0) + (stat['mean']! as num).toDouble();
            counts[key] = (counts[key] ?? 0) + 1;
          }
        }
      }
      String mean(String key, {int digits = 2, bool percent = false}) {
        final n = counts[key] ?? 0;
        if (n == 0) {
          return '—';
        }
        final v = sums[key]! / n * (percent ? 100 : 1);
        return '${v.toStringAsFixed(digits).replaceAll('.', ',')}'
            '${percent ? ' %' : ''}';
      }

      b.writeln(
        '| ${truth.toUpperCase()} | `$name` | ${mean('effortGap')} | '
        '${mean('harderRate', digits: 1, percent: true)} | '
        '${mean('failRate', digits: 2, percent: true)} | '
        '${mean('weeklyGain', digits: 3, percent: true)} | '
        '${mean('attemptRate', digits: 0, percent: true)} | '
        '${mean('eventPerformance', digits: 1, percent: true)} |',
      );
    }
  }
  return b.toString();
}
