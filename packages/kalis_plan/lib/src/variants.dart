/// Variantes d'un exercice du programme (D4.5) : trois ciblées — plus
/// facile, équivalente, autre matériel — puis toutes les compatibles,
/// triées par proximité. Définitions : `CONTRAT.md`, § Variantes.
library;

import 'package:kalis_core/kalis_core.dart';

import 'assemble.dart';
import 'context.dart';
import 'score.dart';
import 'similarity.dart';
import 'state.dart';
import 'traits.dart';

/// Candidat au remplacement d'un exercice.
final class VariantCandidate {
  /// Candidat [entry], de proximité [similarity] avec l'exercice remplacé.
  const VariantCandidate(this.entry, this.similarity);

  /// Exercice proposé.
  final PoolEntry entry;

  /// Proximité avec l'exercice remplacé.
  final double similarity;
}

double _round3(double v) => (v * 1000).roundToDouble() / 1000;

Set<String> _blockingEquipment(CatalogExercise e) => <String>{
  for (final item in e.equipment)
    if (!alwaysAvailableEquipment.contains(item)) item,
};

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// Exercices admissibles à la place de l'emplacement de rang [at] du jour
/// [day] : choisissables, faisables ce jour-là (matériel, lieu), absents de
/// la séance, et tenant dans le temps du jour. Triés par proximité
/// décroissante puis par identifiant.
List<VariantCandidate> admissibleReplacements(
  PlanContext ctx,
  Scorer scorer,
  PlanState state,
  int day,
  int at,
) {
  final old = state.exercise[day][at];
  final oldSets = state.sets[day][at];
  final current = ctx.pool[old];
  final wasWork = current.kind != SlotKind.mobility;
  var work = 0;
  for (var i = 0; i < state.count[day]; i++) {
    if (ctx.pool[state.exercise[day][i]].kind != SlotKind.mobility) {
      work++;
    }
  }
  final out = <VariantCandidate>[];
  for (final e in ctx.pool) {
    if (e.index == old ||
        !e.selectable ||
        !e.feasibleOn(day) ||
        state.dayHas(day, e.index)) {
      continue;
    }
    if (e.kind != SlotKind.mobility &&
        !wasWork &&
        work >= ctx.days[day].maxWorkSlots) {
      continue;
    }
    state.exercise[day][at] = e.index;
    state.sets[day][at] = ctx.defaultSets(e, day);
    final fits = scorer.timeOfDay(state, day) <= ctx.days[day].seconds;
    state.exercise[day][at] = old;
    state.sets[day][at] = oldSets;
    if (!fits) {
      continue;
    }
    out.add(VariantCandidate(e, planSimilarity(current.exercise, e.exercise)));
  }
  out.sort((a, b) {
    final by = b.similarity.compareTo(a.similarity);
    return by != 0 ? by : a.entry.id.compareTo(b.entry.id);
  });
  return out;
}

/// La variante plus facile de [current] parmi [candidates] : le parent
/// dans `variante_de`, sinon un ancêtre, sinon la plus proche de la même
/// chaîne, du même schéma, puis de la même famille — toujours de
/// difficulté strictement inférieure.
VariantCandidate? easierVariant(
  Catalog catalog,
  PoolEntry current,
  List<VariantCandidate> candidates,
) {
  final e = current.exercise;
  final easier = <VariantCandidate>[
    for (final c in candidates)
      if (c.entry.exercise.difficulty < e.difficulty) c,
  ];
  if (easier.isEmpty) {
    return null;
  }
  for (final ancestor in catalog.ancestorsOf(e.id)) {
    for (final c in easier) {
      if (c.entry.id == ancestor.id) {
        return c;
      }
    }
  }
  for (final c in easier) {
    if (c.entry.exercise.rootId == e.rootId &&
        c.entry.exercise.pattern == e.pattern) {
      return c;
    }
  }
  for (final c in easier) {
    if (c.entry.exercise.pattern == e.pattern) {
      return c;
    }
  }
  for (final c in easier) {
    if (c.entry.exercise.family == e.family) {
      return c;
    }
  }
  return null;
}

/// La variante équivalente : même schéma, difficulté à ± 1, la plus proche.
VariantCandidate? equivalentVariant(
  PoolEntry current,
  List<VariantCandidate> candidates,
  Set<String> taken,
) {
  final e = current.exercise;
  for (final c in candidates) {
    final x = c.entry.exercise;
    if (!taken.contains(x.id) &&
        x.pattern == e.pattern &&
        (x.difficulty - e.difficulty).abs() <= 1) {
      return c;
    }
  }
  return null;
}

/// La variante avec un autre matériel : la plus proche dont le matériel
/// nécessaire diffère (du même schéma d'abord, de la même famille ensuite).
VariantCandidate? otherEquipmentVariant(
  PoolEntry current,
  List<VariantCandidate> candidates,
  Set<String> taken,
) {
  final e = current.exercise;
  final own = _blockingEquipment(e);
  for (final samePattern in const <bool>[true, false]) {
    for (final c in candidates) {
      final x = c.entry.exercise;
      if (taken.contains(x.id) || _sameSet(own, _blockingEquipment(x))) {
        continue;
      }
      if (samePattern ? x.pattern == e.pattern : x.family == e.family) {
        return c;
      }
    }
  }
  return null;
}

String _equipmentLabel(PoolEntry entry) =>
    entry.traits.mainEquipment ?? 'aucun (sol)';

Variant _variant(PoolEntry current, VariantCandidate c, VariantKind kind) {
  final x = c.entry.exercise;
  final similarity = _round3(c.similarity);
  List<Reason> reasons;
  switch (kind) {
    case VariantKind.easier:
      reasons = <Reason>[
        reason(ReasonCodes.planVariantEasier, <String, Object?>{
          'difficultyDelta': x.difficulty - current.exercise.difficulty,
        }),
      ];
    case VariantKind.equivalent:
      reasons = <Reason>[
        reason(ReasonCodes.planVariantEquivalent, <String, Object?>{
          'similarity': similarity,
        }),
      ];
    case VariantKind.otherEquipment:
      reasons = <Reason>[
        reason(ReasonCodes.planVariantOtherEquipment, <String, Object?>{
          'equipment': _equipmentLabel(c.entry),
        }),
      ];
    case VariantKind.other:
      reasons = <Reason>[
        reason(ReasonCodes.planLevelMatch, <String, Object?>{
          'difficulty': x.difficulty,
        }),
      ];
  }
  return Variant(
    exerciseId: x.id,
    kind: kind,
    similarity: similarity,
    reasons: reasons,
  );
}

/// Variantes de l'emplacement [slotId], de rang [at] dans le jour [day].
VariantSet computeVariants(
  PlanContext ctx,
  Scorer scorer,
  PlanState state,
  int day,
  int at,
  String slotId,
) {
  final current = ctx.pool[state.exercise[day][at]];
  final e = current.exercise;
  final admissible = admissibleReplacements(ctx, scorer, state, day, at);
  final targeted = <Variant>[];
  final taken = <String>{};
  final kindOf = <String, VariantKind>{};

  final easier = easierVariant(ctx.catalog, current, admissible);
  if (easier != null) {
    targeted.add(_variant(current, easier, VariantKind.easier));
    taken.add(easier.entry.id);
    kindOf[easier.entry.id] = VariantKind.easier;
  }
  final equivalent = equivalentVariant(current, admissible, taken);
  if (equivalent != null) {
    targeted.add(_variant(current, equivalent, VariantKind.equivalent));
    taken.add(equivalent.entry.id);
    kindOf[equivalent.entry.id] = VariantKind.equivalent;
  }
  final other = otherEquipmentVariant(current, admissible, taken);
  if (other != null) {
    targeted.add(_variant(current, other, VariantKind.otherEquipment));
    taken.add(other.entry.id);
    kindOf[other.entry.id] = VariantKind.otherEquipment;
  }

  final own = _blockingEquipment(e);
  final floor = ctx.params.variantMinSimilarity;
  final all = <Variant>[];
  for (final c in admissible) {
    final x = c.entry.exercise;
    var kind = kindOf[x.id];
    if (kind == null) {
      if (c.similarity < floor) {
        continue;
      }
      if (x.pattern == e.pattern && x.difficulty < e.difficulty) {
        kind = VariantKind.easier;
      } else if (x.pattern == e.pattern &&
          (x.difficulty - e.difficulty).abs() <= 1) {
        kind = VariantKind.equivalent;
      } else if (!_sameSet(own, _blockingEquipment(x))) {
        kind = VariantKind.otherEquipment;
      } else {
        kind = VariantKind.other;
      }
    }
    all.add(_variant(current, c, kind));
  }
  return VariantSet(slotId: slotId, targeted: targeted, all: all);
}
