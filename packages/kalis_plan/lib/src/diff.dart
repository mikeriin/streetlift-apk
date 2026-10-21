/// Diff structuré entre deux programmes de passe 1 (D4.6) : ce qui a
/// bougé, par emplacement, dans un ordre stable.
library;

import 'package:kalis_core/kalis_core.dart';

/// Donne les raisons d'un changement.
typedef ChangeReasons =
    List<Reason> Function(
      ChangeKind kind,
      String? slotId,
      String? fromExerciseId,
      String? toExerciseId,
    );

final class _Placed {
  const _Placed(this.dayIndex, this.exerciseId, this.rank);

  final int dayIndex;
  final String exerciseId;
  final int rank;
}

Map<String, _Placed> _index(Pass1Plan plan) {
  final out = <String, _Placed>{};
  for (final day in plan.days) {
    for (var i = 0; i < day.slots.length; i++) {
      final s = day.slots[i];
      out[s.slotId] = _Placed(day.dayIndex, s.exerciseId, i);
    }
  }
  return out;
}

/// Changements pour passer de [before] à [after].
///
/// Un emplacement présent des deux côtés avec un autre exercice est un
/// remplacement ; un emplacement nouveau dont l'exercice vient d'un
/// emplacement disparu d'un autre jour est un déplacement ; sinon ajout ou
/// retrait. Un jour dont les emplacements communs changent d'ordre porte
/// un seul `order_changed`. [weekIndex], s'il est donné, est recopié dans
/// chaque changement (restructuration d'une seule semaine).
PlanDiff diffPlans(
  Pass1Plan before,
  Pass1Plan after, {
  required ChangeReasons reasons,
  int? weekIndex,
}) {
  final a = _index(before);
  final b = _index(after);
  final changes = <PlanChange>[];
  final consumed = <String>{};

  for (var d = after.days.length; d < before.days.length; d++) {
    changes.add(
      PlanChange(
        kind: ChangeKind.dayRemoved,
        dayIndex: d,
        weekIndex: weekIndex,
        reasons: reasons(ChangeKind.dayRemoved, null, null, null),
      ),
    );
  }
  for (var d = before.days.length; d < after.days.length; d++) {
    changes.add(
      PlanChange(
        kind: ChangeKind.dayAdded,
        dayIndex: d,
        weekIndex: weekIndex,
        reasons: reasons(ChangeKind.dayAdded, null, null, null),
      ),
    );
  }

  final removedIds = <String>[
    for (final id in a.keys)
      if (!b.containsKey(id)) id,
  ]..sort();

  for (final day in after.days) {
    for (final slot in day.slots) {
      final old = a[slot.slotId];
      if (old != null) {
        if (old.exerciseId != slot.exerciseId) {
          changes.add(
            PlanChange(
              kind: ChangeKind.exerciseReplaced,
              dayIndex: day.dayIndex,
              weekIndex: weekIndex,
              slotId: slot.slotId,
              fromExerciseId: old.exerciseId,
              toExerciseId: slot.exerciseId,
              reasons: reasons(
                ChangeKind.exerciseReplaced,
                slot.slotId,
                old.exerciseId,
                slot.exerciseId,
              ),
            ),
          );
        }
        continue;
      }
      String? source;
      for (final id in removedIds) {
        final p = a[id]!;
        if (!consumed.contains(id) &&
            p.exerciseId == slot.exerciseId &&
            p.dayIndex != day.dayIndex) {
          source = id;
          break;
        }
      }
      if (source != null) {
        consumed.add(source);
        changes.add(
          PlanChange(
            kind: ChangeKind.exerciseMoved,
            dayIndex: day.dayIndex,
            weekIndex: weekIndex,
            slotId: slot.slotId,
            fromExerciseId: slot.exerciseId,
            toExerciseId: slot.exerciseId,
            fromDayIndex: a[source]!.dayIndex,
            reasons: reasons(
              ChangeKind.exerciseMoved,
              slot.slotId,
              slot.exerciseId,
              slot.exerciseId,
            ),
          ),
        );
      } else {
        changes.add(
          PlanChange(
            kind: ChangeKind.exerciseAdded,
            dayIndex: day.dayIndex,
            weekIndex: weekIndex,
            slotId: slot.slotId,
            toExerciseId: slot.exerciseId,
            reasons: reasons(
              ChangeKind.exerciseAdded,
              slot.slotId,
              null,
              slot.exerciseId,
            ),
          ),
        );
      }
    }
  }
  for (final id in removedIds) {
    if (consumed.contains(id)) {
      continue;
    }
    final p = a[id]!;
    changes.add(
      PlanChange(
        kind: ChangeKind.exerciseRemoved,
        dayIndex: p.dayIndex,
        weekIndex: weekIndex,
        slotId: id,
        fromExerciseId: p.exerciseId,
        reasons: reasons(ChangeKind.exerciseRemoved, id, p.exerciseId, null),
      ),
    );
  }
  // Ordre des emplacements communs d'un jour.
  for (final day in after.days) {
    var last = -1;
    var reordered = false;
    for (final slot in day.slots) {
      final old = a[slot.slotId];
      if (old == null || old.dayIndex != day.dayIndex) {
        continue;
      }
      if (old.rank < last) {
        reordered = true;
      }
      last = old.rank;
    }
    if (reordered) {
      changes.add(
        PlanChange(
          kind: ChangeKind.orderChanged,
          dayIndex: day.dayIndex,
          weekIndex: weekIndex,
          reasons: reasons(ChangeKind.orderChanged, null, null, null),
        ),
      );
    }
  }

  changes.sort((x, y) {
    final dx = x.dayIndex ?? -1;
    final dy = y.dayIndex ?? -1;
    if (dx != dy) {
      return dx.compareTo(dy);
    }
    if (x.kind != y.kind) {
      return x.kind.index.compareTo(y.kind.index);
    }
    return (x.slotId ?? '').compareTo(y.slotId ?? '');
  });
  return PlanDiff(changes: changes);
}
