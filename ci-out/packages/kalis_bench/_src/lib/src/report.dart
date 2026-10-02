/// Rapport du banc : pour chaque profil, programme généré, critères de
/// sécurité et de qualité, attentes de coach, trajectoire simulée ; puis
/// les fichiers du rapport (JSON et Markdown) et les exports lisibles.
library;

import 'dart:convert';

import 'package:kalis_adapt/kalis_adapt.dart' show kalisAdaptVersion;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show kalisPlanVersion;
import 'package:kalis_plan/report.dart' show OwnerProgram;

import 'adapter.dart';
import 'analysis.dart';
import 'expectations.dart';
import 'export.dart';
import 'profile.dart';
import 'program.dart';
import 'quality.dart';
import 'safety.dart';
import 'trajectory.dart';
import 'version.dart';

/// Ce que le banc fait tourner.
enum BenchMode {
  /// Moteur de création seul : programme, critères, export.
  plan('plan'),

  /// Moteur d'évolution seul : trajectoire simulée.
  adapt('adapt'),

  /// Les deux, et les critères de sécurité relus sur le programme tel que
  /// le moteur d'évolution l'a fait évoluer.
  croisement('croisement');

  const BenchMode(this.code);

  /// Code de la ligne de commande.
  final String code;

  /// Mode d'un code ; [FormatException] s'il est inconnu.
  static BenchMode fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('moteur : plan, adapt ou croisement attendu', code);
  }
}

/// Données d'entrée du banc.
final class BenchInputs {
  /// Entrées.
  const BenchInputs({
    required this.catalog,
    required this.profiles,
    this.owner,
    this.ownerPairs,
  });

  /// Catalogue.
  final Catalog catalog;

  /// Profils du banc.
  final List<BenchProfile> profiles;

  /// Programme du propriétaire (non-ressemblance), ou `null`.
  final OwnerProgram? owner;

  /// Couples exercice × schéma du programme du propriétaire, ou `null`.
  final List<Set<String>>? ownerPairs;
}

/// Résultat du banc pour un profil.
final class ProfileReport {
  /// Résultat.
  ProfileReport({
    required this.profile,
    required this.lost,
    this.view,
    this.safety = const <Finding>[],
    this.quality = const <QualityMeasure>[],
    this.checks = const <CheckResult>[],
    this.trajectory,
    this.realizedSafety,
  });

  /// Profil.
  final BenchProfile profile;

  /// Informations perdues par l'adaptateur.
  final List<String> lost;

  /// Programme lu (modes `plan` et `croisement`).
  final ProgramView? view;

  /// Violations de sécurité du programme créé.
  final List<Finding> safety;

  /// Mesures de qualité.
  final List<QualityMeasure> quality;

  /// Attentes de coach.
  final List<CheckResult> checks;

  /// Trajectoire (modes `adapt` et `croisement`).
  final Trajectory? trajectory;

  /// Violations de sécurité du programme tel qu'il a évolué sous
  /// `kalis_adapt` (mode `croisement`).
  final List<Finding>? realizedSafety;

  /// Moyenne des notes de qualité qui s'appliquent, ou `null`.
  double? get qualityMean {
    var sum = 0.0;
    var n = 0;
    for (final q in quality) {
      final s = q.score;
      if (s != null) {
        sum += s;
        n++;
      }
    }
    return n == 0 ? null : sum / n;
  }

  /// Attentes tenues.
  int get checksOk => checks.where((c) => c.ok).length;
}

/// Fait tourner le banc pour le profil [profile].
ProfileReport evaluateProfile(
  BenchInputs inputs,
  PlanEngine plan,
  BenchProfile profile, {
  BenchMode mode = BenchMode.croisement,
  int seed = 0,
}) {
  final catalog = inputs.catalog;
  ProgramView? view;
  var safety = const <Finding>[];
  var quality = const <QualityMeasure>[];
  var checks = const <CheckResult>[];
  final program = generateProgram(catalog, plan, profile, seed: seed);
  if (mode != BenchMode.adapt) {
    final v = ProgramView(catalog, program);
    view = v;
    safety = safetyFindings(v, profile);
    quality = qualityMeasures(
      v,
      profile,
      owner: inputs.owner,
      ownerPairs: inputs.ownerPairs,
    );
    checks = evaluateChecks(v, profile);
  }
  Trajectory? trajectory;
  List<Finding>? realized;
  if (mode != BenchMode.plan) {
    final t = simulateTrajectory(
      catalog,
      plan,
      profile,
      program.profile,
      seed: seed,
    );
    trajectory = t;
    if (mode == BenchMode.croisement) {
      realized = safetyFindings(
        ProgramView(
          catalog,
          BenchProgram(
            bench: profile,
            adapted: program.adapted,
            request: program.request,
            blocks: t.run.blocks,
            horizonWeeks: program.horizonWeeks,
          ),
        ),
        profile,
      );
    }
  }
  return ProfileReport(
    profile: profile,
    lost: program.adapted.lost,
    view: view,
    safety: safety,
    quality: quality,
    checks: checks,
    trajectory: trajectory,
    realizedSafety: realized,
  );
}

Map<String, int> _countByCode(List<Finding> findings) {
  final out = <String, int>{};
  for (final f in findings) {
    out[f.code] = (out[f.code] ?? 0) + 1;
  }
  return out;
}

String _table(List<String> header, List<List<Object?>> rows) {
  final b = StringBuffer()
    ..writeln('| ${header.join(' | ')} |')
    ..writeln('| ${header.map((_) => '---').join(' | ')} |');
  for (final row in rows) {
    b.writeln('| ${row.join(' | ')} |');
  }
  return b.toString();
}

/// Objet JSON du résultat d'un profil.
Map<String, Object?> profileReportJson(ProfileReport r) {
  final view = r.view;
  final realized = r.realizedSafety;
  final trajectory = r.trajectory;
  return <String, Object?>{
    'key': r.profile.key,
    'group': r.profile.group,
    'title': r.profile.title,
    'level': r.profile.level.code,
    'adapterLost': r.lost,
    if (view != null) ...<String, Object?>{
      'weeks': view.weeks.length,
      'blocks': view.program.blocks.length,
      'generatedWeeks': view.program.generatedWeeks,
      'weekKinds': <String>[for (final w in view.weeks) w.kind.code],
      'hardSetsByWeek': <int>[for (final w in view.weeks) w.hardSets.round()],
      'safetyViolations': r.safety.length,
      'safetyByCode': _countByCode(r.safety),
      'safety': <Object?>[for (final f in r.safety) f.toJson()],
      'quality': <Object?>[for (final q in r.quality) q.toJson()],
      if (r.qualityMean != null)
        'qualityMean': (r.qualityMean! * 1000).roundToDouble() / 1000,
      'checksOk': r.checksOk,
      'checksTotal': r.checks.length,
      'checks': <Object?>[for (final c in r.checks) c.toJson()],
      'exerciseSchemes': <Object?>[
        for (final week in programWeekPairs(view)) (week.toList()..sort()),
      ],
    },
    if (realized != null) ...<String, Object?>{
      'realizedSafetyViolations': realized.length,
      'realizedSafetyByCode': _countByCode(realized),
      'realizedSafety': <Object?>[for (final f in realized) f.toJson()],
    },
    if (trajectory != null) 'trajectory': trajectory.metrics,
  };
}

/// Fichiers du rapport : chemin relatif → contenu. [timingsMs] : temps de
/// calcul mesurés par l'appelant (clé du profil → millisecondes par
/// étape), facultatif — le banc lui-même ne lit aucune horloge.
Map<String, String> renderReport(
  BenchInputs inputs,
  List<ProfileReport> reports, {
  required BenchMode mode,
  required int seed,
  required String scope,
  Map<String, Map<String, double>>? timingsMs,
}) {
  final files = <String, String>{};
  final catalog = inputs.catalog;
  final json = <String, Object?>{
    'benchVersion': kalisBenchVersion,
    'planVersion': kalisPlanVersion,
    'adaptVersion': kalisAdaptVersion,
    'coreVersion': kalisCoreVersion,
    'catalogVersion': catalog.sourceVersion,
    'mode': mode.code,
    'seed': seed,
    'scope': scope,
    'startDate': benchStartDate.iso,
    'profiles': <Object?>[for (final r in reports) profileReportJson(r)],
    if (timingsMs != null) 'timingsMs': timingsMs,
  };
  files['rapport.json'] =
      '${const JsonEncoder.withIndent(' ').convert(json)}\n';

  final md = StringBuffer()
    ..writeln('# Rapport du banc kalis_bench $kalisBenchVersion')
    ..writeln()
    ..writeln(
      'Moteurs : kalis_plan $kalisPlanVersion, kalis_adapt '
      '$kalisAdaptVersion, kalis_core $kalisCoreVersion (catalogue '
      '${catalog.sourceVersion}). Mode `${mode.code}`, profils `$scope`, '
      'graine $seed, ${reports.length} profils. Tout est déterministe, '
      'sauf les temps de calcul.',
    )
    ..writeln();

  if (mode != BenchMode.adapt) {
    var violations = 0;
    final byCode = <String, int>{};
    for (final r in reports) {
      violations += r.safety.length;
      for (final e in _countByCode(r.safety).entries) {
        byCode[e.key] = (byCode[e.key] ?? 0) + e.value;
      }
    }
    md
      ..writeln('## 1. Programmes créés')
      ..writeln()
      ..writeln(
        'Violations de sécurité : **$violations** au total'
        '${byCode.isEmpty ? '' : ' (${(byCode.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${safetyCriteria[e.key] ?? e.key} : ${e.value}').join(' ; ')})'}.',
      )
      ..writeln()
      ..writeln(
        _table(
          <String>[
            'Profil',
            'Niveau',
            'Semaines',
            'Violations de sécurité',
            'Qualité (moyenne)',
            'Attentes tenues',
          ],
          <List<Object?>>[
            for (final r in reports)
              <Object?>[
                '`${r.profile.key}`',
                r.profile.level.label,
                r.view?.weeks.length ?? 0,
                r.safety.length,
                r.qualityMean == null ? '—' : r.qualityMean!.toStringAsFixed(2),
                '${r.checksOk}/${r.checks.length}',
              ],
          ],
        ),
      )
      ..writeln('### Qualité par critère')
      ..writeln()
      ..writeln(
        _table(
          <String>['Profil', for (final c in qualityCriteria.keys) '`$c`'],
          <List<Object?>>[
            for (final r in reports)
              <Object?>[
                '`${r.profile.key}`',
                for (final c in qualityCriteria.keys)
                  () {
                    for (final q in r.quality) {
                      if (q.code == c) {
                        final s = q.score;
                        return s == null ? '—' : s.toStringAsFixed(2);
                      }
                    }
                    return '—';
                  }(),
              ],
          ],
        ),
      );
  }

  if (mode != BenchMode.plan) {
    md
      ..writeln('## 2. Trajectoires simulées')
      ..writeln()
      ..writeln(
        _table(
          <String>[
            'Profil',
            'Séances faites',
            'Échecs non voulus',
            'Écart au RIR visé (cibles atteignables)',
            'Cibles atteignables',
            'Plus forte hausse (principal)',
            'Gain réel (%/sem)',
            'Performance à l\'échéance',
            'Violations (programme évolué)',
          ],
          <List<Object?>>[
            for (final r in reports)
              if (r.trajectory != null)
                <Object?>[
                  '`${r.profile.key}`',
                  '${r.trajectory!.metrics['sessionsDone']}/'
                      '${r.trajectory!.metrics['sessionsPlanned']}',
                  r.trajectory!.metrics['unwantedFailureRate'],
                  r.trajectory!.metrics['rirGapReachable'],
                  r.trajectory!.metrics['reachableShare'],
                  r.trajectory!.metrics['maxMainLoadRise'],
                  r.trajectory!.metrics['meanWeeklyGainPercent'] ?? '—',
                  r.trajectory!.metrics['meanEventPerformance'] ?? '—',
                  r.realizedSafety?.length ?? '—',
                ],
          ],
        ),
      );
  }

  md
    ..writeln('## 3. Détail par profil')
    ..writeln();
  for (final r in reports) {
    md
      ..writeln('### `${r.profile.key}` — ${r.profile.title}')
      ..writeln();
    if (r.lost.isNotEmpty) {
      md
        ..writeln(
          'Non transmis au moteur par le profil actuel : '
          '${r.lost.map((c) => lostFieldLabels[c] ?? c).join(' ; ')}.',
        )
        ..writeln();
    }
    if (r.view != null) {
      if (r.safety.isEmpty) {
        md.writeln('Sécurité : aucune violation.');
      } else {
        md.writeln('Sécurité : ${r.safety.length} violation(s).');
        for (final f in r.safety) {
          md.writeln(
            '- **${safetyCriteria[f.code] ?? f.code}** — ${f.message}',
          );
        }
      }
      md
        ..writeln()
        ..writeln('Qualité :');
      for (final q in r.quality) {
        final s = q.score;
        md.writeln(
          '- ${qualityCriteria[q.code] ?? q.code} : '
          '${s == null ? 'sans objet' : s.toStringAsFixed(2)} — ${q.detail}',
        );
      }
      md
        ..writeln()
        ..writeln('Attentes de coach (${r.checksOk}/${r.checks.length}) :');
      for (final c in r.checks) {
        md.writeln(
          '- ${c.ok ? 'tenue' : '**non tenue**'} — ${c.check.label} '
          '(mesuré : ${c.observed})',
        );
      }
      md.writeln();
    }
    final realized = r.realizedSafety;
    if (realized != null) {
      md.writeln(
        'Programme tel qu\'il a évolué sous le moteur d\'évolution : '
        '${realized.length} violation(s) de sécurité'
        '${realized.isEmpty ? '' : ' (${_countByCode(realized).entries.map((e) => '${safetyCriteria[e.key] ?? e.key} : ${e.value}').join(' ; ')})'}.',
      );
      md.writeln();
    }
  }
  files['RAPPORT.md'] = md.toString();

  for (final r in reports) {
    final view = r.view;
    if (view != null) {
      files['programmes/${r.profile.key}.md'] = programMarkdown(view);
      files['programmes/${r.profile.key}.json'] =
          '${jsonEncode(programJson(view))}\n';
    }
    final t = r.trajectory;
    if (t != null) {
      files['trajectoires/${r.profile.key}.md'] = trajectoryMarkdown(
        t,
        catalog,
      );
    }
  }
  return files;
}
