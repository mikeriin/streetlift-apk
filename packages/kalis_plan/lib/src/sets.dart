/// Séries de référence d'une séance en passe 1 : une fonction de la seule
/// liste de ses exercices, pour qu'un programme relu donne exactement la
/// même durée et la même note que le programme produit.
library;

import 'context.dart';
import 'state.dart';
import 'traits.dart';

/// Durée estimée du jour [day] de [state], échauffement compris, en
/// secondes.
int dayTime(PlanContext ctx, PlanState state, int day) {
  final pool = ctx.pool;
  final ex = state.exercise[day];
  final sets = state.sets[day];
  var t = 0;
  var warm = false;
  for (var i = 0; i < state.count[day]; i++) {
    final e = pool[ex[i]];
    t += e.scheme.secondsFor(sets[i]);
    if (e.needsWarmup) {
      warm = true;
    }
  }
  return warm ? t + ctx.days[day].warmupSeconds : t;
}

/// Vrai si la durée de [entry] s'étire pour occuper le temps restant de la
/// séance (cardio continu).
bool fillsRemainingTime(PoolEntry entry) =>
    entry.scheme.continuous && entry.kind.isCardio;

int _shrinkRank(SlotKind kind) {
  switch (kind) {
    case SlotKind.accessory:
      return 6;
    case SlotKind.core:
      return 5;
    case SlotKind.conditioning:
      return 4;
    case SlotKind.mobility:
      return 3;
    case SlotKind.cardioHard:
    case SlotKind.cardioEasy:
      return 2;
    case SlotKind.skillStatic:
    case SlotKind.skillDynamic:
      return 1;
    case SlotKind.compound:
    case SlotKind.power:
      return 0;
  }
}

/// Fixe les séries de référence du jour [day] d'après ses exercices :
///
/// 1. chaque exercice prend ses séries par défaut (un cardio continu, son
///    minimum) ;
/// 2. si la séance dépasse son temps, une série est retirée à la fois, à
///    l'assistance d'abord, aux polyarticulaires en dernier, sans passer
///    sous le minimum d'un exercice ;
/// 3. sinon le temps restant va au cardio continu, tranche par tranche,
///    jusqu'à son maximum.
///
/// Rend faux si la séance ne tient pas même au minimum (les séries sont
/// alors laissées au minimum).
bool normalizeDay(PlanContext ctx, PlanState state, int day) {
  final pool = ctx.pool;
  final ex = state.exercise[day];
  final sets = state.sets[day];
  final n = state.count[day];
  final limit = ctx.days[day].seconds;
  var time = 0;
  var warm = false;
  for (var i = 0; i < n; i++) {
    final e = pool[ex[i]];
    sets[i] = fillsRemainingTime(e)
        ? e.scheme.minSets
        : ctx.defaultSets(e, day);
    time += e.scheme.secondsFor(sets[i]);
    if (e.needsWarmup) {
      warm = true;
    }
  }
  if (warm) {
    time += ctx.days[day].warmupSeconds;
  }
  while (time > limit) {
    var at = -1;
    var bestRank = -1;
    var bestSets = 0;
    for (var i = 0; i < n; i++) {
      final e = pool[ex[i]];
      if (sets[i] <= e.scheme.minSets) {
        continue;
      }
      final rank = _shrinkRank(e.kind);
      if (rank > bestRank ||
          (rank == bestRank &&
              (sets[i] > bestSets ||
                  (sets[i] == bestSets && ex[i] < ex[at])))) {
        at = i;
        bestRank = rank;
        bestSets = sets[i];
      }
    }
    if (at < 0) {
      return false;
    }
    sets[at]--;
    time -= pool[ex[at]].scheme.perSetSeconds;
  }
  var progressed = true;
  while (progressed) {
    progressed = false;
    for (var i = 0; i < n; i++) {
      final e = pool[ex[i]];
      if (!fillsRemainingTime(e) || sets[i] >= e.scheme.maxSets) {
        continue;
      }
      final step = e.scheme.perSetSeconds;
      if (time + step <= limit) {
        sets[i]++;
        time += step;
        progressed = true;
      }
    }
  }
  return true;
}

/// Applique [normalizeDay] à chaque jour de [state].
void normalizeAll(PlanContext ctx, PlanState state) {
  for (var d = 0; d < state.dayCount; d++) {
    normalizeDay(ctx, state, d);
  }
}
