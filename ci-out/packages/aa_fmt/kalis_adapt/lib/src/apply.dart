/// Application d'une proposition au bloc en cours (mode assisté, D5.6).
library;

import 'package:kalis_core/kalis_core.dart';

/// Bloc obtenu en appliquant [proposal] à [block].
///
/// - Une restructuration porte son bloc résultant : il est rendu tel quel.
/// - Une proposition de volume ou de décharge porte un diff de
///   prescriptions : chaque changement `prescription_changed` remplace la
///   prescription de (`weekIndex`, `dayIndex`, `slotId`).
/// - Sinon le bloc est rendu inchangé (même objet).
///
/// La passe 1 n'est pas touchée par un diff de prescriptions : la passe 2
/// fait foi semaine par semaine.
ProgramBlock applyProposal(ProgramBlock block, Proposal proposal) {
  final result = proposal.block;
  if (result != null) {
    return result;
  }
  final diff = proposal.diff;
  if (diff == null) {
    return block;
  }
  final replaced = <String, ExercisePrescription>{};
  for (final change in diff.changes) {
    final to = change.toPrescription;
    final week = change.weekIndex;
    final day = change.dayIndex;
    final slot = change.slotId;
    if (change.kind != ChangeKind.prescriptionChanged ||
        to == null ||
        week == null ||
        day == null ||
        slot == null) {
      continue;
    }
    replaced['$week|$day|$slot'] = to;
  }
  if (replaced.isEmpty) {
    return block;
  }
  var touched = false;
  final weeks = <WeekPrescription>[];
  for (final week in block.pass2.weeks) {
    final days = <DayPrescription>[];
    for (final day in week.days) {
      final items = <ExercisePrescription>[];
      for (final item in day.items) {
        final to = replaced['${week.weekIndex}|${day.dayIndex}|${item.slotId}'];
        if (to != null) {
          touched = true;
          items.add(to);
        } else {
          items.add(item);
        }
      }
      days.add(DayPrescription(dayIndex: day.dayIndex, items: items));
    }
    weeks.add(
      WeekPrescription(weekIndex: week.weekIndex, kind: week.kind, days: days),
    );
  }
  if (!touched) {
    return block;
  }
  return ProgramBlock(
    pass1: block.pass1,
    pass2: Pass2Plan(
      blockId: block.pass2.blockId,
      engineVersion: block.pass2.engineVersion,
      weeks: weeks,
      reasons: block.pass2.reasons,
    ),
  );
}
