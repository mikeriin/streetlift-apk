/// Partie « endurance et conditionnement » d'une trajectoire simulée (lot
/// CA2, partie 1) : chaque ligne de course, de cardio ou de
/// conditionnement — ce que le programme écrit, ce que le moteur sert, ce
/// que l'athlète simulé fait, et pourquoi le moteur a changé la ligne.
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

String _n(double v, [int digits = 1]) {
  final text = v.toStringAsFixed(digits);
  final trimmed = text.contains('.')
      ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : text;
  return trimmed.replaceAll('.', ',');
}

bool _endurance(CatalogExercise? e) =>
    e != null &&
    (e.family == MovementFamily.cardio ||
        e.family == MovementFamily.conditionnement);

String _amount(int? seconds, double? meters, int? reps) {
  if (meters != null) {
    return meters >= 1000 ? '${_n(meters / 1000, 2)} km' : '${_n(meters, 0)} m';
  }
  if (seconds != null) {
    return seconds >= 120 ? '${_n(seconds / 60)} min' : '$seconds s';
  }
  if (reps != null) {
    return '$reps rép.';
  }
  return '—';
}

String _line(ExercisePrescription it) {
  final amount = _amount(
    it.secondsHigh ?? it.secondsLow,
    it.distanceMeters,
    it.repsHigh ?? it.repsLow,
  );
  final b = StringBuffer(it.sets > 1 ? '${it.sets} × $amount' : amount);
  final f = it.targetFlames;
  if (f != null) {
    b.write(', effort $f/10');
  }
  final i = it.intensity;
  if (i != null) {
    b.write(
      i.basis == IntensityBasis.absoluteSpeed
          ? ', allure ${_n(1000 / i.value / 60, 2)} min/km'
          : ', allure visée',
    );
  }
  if (it.kind == SetKind.test) {
    b.write(', test');
  }
  return b.toString();
}

String _done(List<SetRecord> sets) {
  if (sets.isEmpty) {
    return 'non fait';
  }
  var seconds = 0;
  var meters = 0.0;
  var reps = 0;
  int? flames;
  for (final s in sets) {
    seconds += s.seconds ?? 0;
    meters += s.distanceMeters ?? 0;
    reps += s.reps ?? 0;
    final f = s.flames;
    if (f != null && (flames == null || f > flames)) {
      flames = f;
    }
  }
  final parts = <String>[
    if (meters > 0) _amount(null, meters, null),
    if (seconds > 0) _amount(seconds, null, null),
    if (meters == 0 && seconds == 0 && reps > 0) '$reps rép.',
  ];
  return '${parts.isEmpty ? 'fait' : parts.join(' en ')}'
      '${flames == null ? '' : ', effort noté $flames/10'}'
      '${sets.any((s) => !s.success) ? ', pas en entier' : ''}';
}

String _cause(String code) => switch (code) {
  'health' => 'bilan bas',
  'health_strong' => 'bilan très bas',
  'hard_run' => 'course récente bien plus dure que prévu',
  'leg_pain' => 'douleur du bas du corps',
  'resume_7' => 'reprise après une semaine sans séance',
  'resume_14' => 'reprise après deux semaines sans séance',
  'hard_streak' => 'jours durs de suite',
  _ => code,
};

/// Texte d'une raison d'endurance, ou `null`.
String? enduranceReasonText(Reason r) {
  final cause = '${r.params['cause'] ?? ''}';
  final percent = r.params['percent'];
  switch (r.code) {
    case ReasonCodes.adaptRunCapped:
      return 'raccourcie : pas plus de $percent % au-dessus de la plus '
          'longue course des 30 jours';
    case ReasonCodes.adaptEasyInstead:
      return 'course facile à la place de la séance de qualité '
          '(${_cause(cause)})';
    case ReasonCodes.adaptEnduranceShortened:
      return 'ramenée à $percent % de l\'écrit (${_cause(cause)})';
    case ReasonCodes.adaptWodScaled:
      return 'mise à l\'échelle à $percent % (${_cause(cause)})';
    case ReasonCodes.adaptCrossFatigue:
      return 'une répétition de réserve de plus sur les jambes (course dure '
          'la veille)';
    case ReasonCodes.adaptTimeShort:
      return 'temps réduit';
    case ReasonCodes.adaptPainReported:
      return 'douleur signalée';
  }
  return null;
}

ExercisePrescription? _written(SimRun run, SimSession s, String slotId) {
  ProgramBlock? block;
  for (var i = 0; i < run.blocks.length; i++) {
    if (i < run.blockWeeks.length && run.blockWeeks[i] <= s.week) {
      block = run.blocks[i];
    }
  }
  if (block == null) {
    return null;
  }
  for (final w in block.pass2.weeks) {
    if (w.weekIndex != s.weekInBlock) {
      continue;
    }
    for (final d in w.days) {
      if (d.dayIndex != s.plan.dayIndex) {
        continue;
      }
      for (final it in d.items) {
        if (it.slotId == slotId) {
          return it;
        }
      }
    }
  }
  return null;
}

/// Partie « endurance et conditionnement » de la trajectoire [run] en
/// Markdown, ou chaîne vide si le programme n'en a pas.
String enduranceMarkdown(SimRun run, Catalog catalog) {
  final profile = run.finalProfile;
  if (profile == null) {
    return '';
  }
  final book = ExerciseBook(catalog, profile);
  // Vitesse de course lue sur le journal (lignes qui disent distance et
  // durée), sinon celle du moteur.
  var meters = 0.0;
  var timed = 0.0;
  for (final s in run.sessions) {
    for (final set in s.sets) {
      final m = set.distanceMeters;
      final t = set.seconds;
      if (m != null && t != null && m > 0 && t > 0) {
        meters += m;
        timed += t;
      }
    }
  }
  final speed = timed > 0
      ? meters / timed
      : AdaptParams.standard.enduranceRunSpeed;
  final rows = <String>[];
  final writtenRun = <int, double>{};
  for (final s in run.served) {
    // Lignes écrites ce jour (retirées comprises).
    final servedSlots = <String, ExercisePrescription>{
      for (final it in s.plan.items) it.slotId: it,
    };
    final slots = servedSlots.keys;
    final block = <String, ExercisePrescription>{};
    for (final it in s.plan.items) {
      final w = _written(run, s, it.slotId);
      if (w != null) {
        block[it.slotId] = w;
      }
    }
    // Lignes retirées : retrouvées par l'ajustement.
    for (final a in s.plan.adjustments) {
      if (a.kind != AdjustmentKind.exerciseRemoved) {
        continue;
      }
      final id = a.exerciseId;
      final e = id == null ? null : catalog.find(id);
      if (!_endurance(e)) {
        continue;
      }
      final text = a.reasons
          .map(enduranceReasonText)
          .whereType<String>()
          .join(' ; ');
      rows.add(
        '| ${s.week + 1} | ${s.record.date.iso} | ${e!.name} | — | retirée | '
        '— | ${text.isEmpty ? 'retirée' : text} |',
      );
    }
    for (final slot in slots) {
      final it = servedSlots[slot];
      if (it == null || it.kind == SetKind.warmup) {
        continue;
      }
      final e = catalog.find(it.exerciseId);
      if (!_endurance(e)) {
        continue;
      }
      final w = block[slot];
      final done = <SetRecord>[
        for (final r in s.record.sets)
          if (r.slotId == slot && r.exerciseId == it.exerciseId) r,
      ];
      final reasons = <String>{
        for (final r in it.reasons) ?enduranceReasonText(r),
        for (final a in s.plan.adjustments)
          if (a.exerciseId == (w?.exerciseId ?? it.exerciseId))
            for (final r in a.reasons) ?enduranceReasonText(r),
      };
      final writtenName = w == null || w.exerciseId == it.exerciseId
          ? ''
          : '${catalog.find(w.exerciseId)?.name ?? w.exerciseId} → ';
      rows.add(
        '| ${s.week + 1} | ${s.record.date.iso} | $writtenName${e!.name} | '
        '${w == null ? '—' : _line(w)} | ${_line(it)} | ${_done(done)} | '
        '${reasons.isEmpty ? 'tel qu\'écrit' : reasons.join(' ; ')} |',
      );
      final wInfo = w == null ? null : book.find(w.exerciseId);
      if (w != null &&
          wInfo != null &&
          enduranceKindOf(wInfo) == EnduranceKind.run &&
          w.kind != SetKind.warmup) {
        writtenRun[s.week] =
            (writtenRun[s.week] ?? 0) + prescribedSeconds(w, w.sets, speed);
      }
    }
  }
  if (rows.isEmpty) {
    return '';
  }
  final b = StringBuffer()
    ..writeln()
    ..writeln('## Endurance et conditionnement, séance par séance')
    ..writeln()
    ..writeln(
      'Course, cardio et pièces de conditionnement : ce que le programme '
      'écrit, ce que le moteur sert ce jour-là, ce que l\'athlète simulé '
      'fait (effort noté de 1 à 10) et la raison de chaque changement. '
      'Blessures de surcharge simulées : ${run.enduranceOveruse} ; plus '
      'forte course rapportée à la plus longue des 30 jours précédents : '
      '${run.worstRunSpike == 0 ? '—' : '× ${_n(run.worstRunSpike, 2)}'}.',
    )
    ..writeln()
    ..writeln('| Semaine | Date | Exercice | Écrit | Servi | Fait | Décision |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final r in rows) {
    b.writeln(r);
  }
  final weeks = run.runSecondsByWeek.keys.toList()..sort();
  if (weeks.isNotEmpty) {
    b
      ..writeln()
      ..writeln(
        'Course faite et écrite par semaine (minutes, échauffement exclu) :',
      )
      ..writeln()
      ..writeln('| Semaine | Faite | Écrite |')
      ..writeln('| --- | --- | --- |');
    for (final w in weeks) {
      final written = writtenRun[w];
      b.writeln(
        '| ${w + 1} | ${_n(run.runSecondsByWeek[w]! / 60, 0)} | '
        '${written == null ? '—' : _n(written / 60, 0)} |',
      );
    }
  }
  return b.toString();
}
