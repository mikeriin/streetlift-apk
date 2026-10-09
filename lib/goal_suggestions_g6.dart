// G6 — PROVISOIRE, À RETIRER EN G12 (remplacé par `kalis_quest`, D3.8).
//
// « Laisse Koach proposer » (création du profil) : `kalis_quest` n'est pas
// encore livré, ces règles simples en tiennent lieu. Elles sont regroupées
// dans ce seul fichier pour être retirées d'un bloc. Choix raisonné du lot,
// non relu par un professionnel : objectifs prudents, partis de la borne
// BASSE de la fourchette déclarée, échéance à 12 semaines ; une habitude
// réaliste (2 à 4 séances par semaine pendant 8 semaines).
import 'package:kalis_core/kalis_core.dart';

import 'athlete_profile.dart';

/// Échéance des objectifs de performance proposés.
const int kSuggestedGoalWeeks = 12;

double _roundTo(double v, double step) => (v / step).round() * step;

/// Objectif proposé pour un mouvement déclaré (null : rien de sûr à dire).
Goal? _forLevel(LevelMovement m, LevelBand b, CivilDate today, String id) {
  final date = today.addDays(kSuggestedGoalWeeks * 7);
  Goal perf(GoalMetric metric, double target, {double? distance}) => Goal(
    id: id,
    kind: GoalKind.performance,
    origin: GoalOrigin.suggested,
    createdOn: today,
    exerciseId: m.exerciseId,
    metric: metric,
    targetValue: target,
    distanceMeters: distance,
    targetDate: date,
  );
  switch (m.measure) {
    case LevelMeasure.maxReps:
      final low = b.low;
      if (low <= 0) return perf(GoalMetric.maxReps, 1);
      final gain = (low * .25).round();
      return perf(GoalMetric.maxReps, low + (gain < 2 ? 2 : gain));
    case LevelMeasure.oneRmKg:
      final low = b.low;
      if (low <= 0) return null;
      final up = _roundTo(low * 1.075, 2.5);
      return perf(GoalMetric.oneRmKg, up < low + 2.5 ? low + 2.5 : up);
    case LevelMeasure.maxHoldSeconds:
      final low = b.low;
      if (low <= 0) return perf(GoalMetric.maxHoldSeconds, 10);
      final gain = (low * .3).round();
      return perf(GoalMetric.maxHoldSeconds, low + (gain < 5 ? 5 : gain));
    case LevelMeasure.timeSeconds:
      // Temps : la borne prudente est la plus lente (haute).
      final target = (b.high * .95 / 15).floor() * 15.0;
      return perf(GoalMetric.timeSeconds, target, distance: m.distanceMeters);
  }
}

/// Jusqu'à trois objectifs proposés par Koach d'après le brouillon du
/// profil : deux de performance (mouvements déclarés des disciplines
/// choisies, principale d'abord) et une habitude.
List<Goal> provisionalGoalSuggestions(ProfileDraft d, CivilDate today) {
  final out = <Goal>[];
  final taken = <String>{
    for (final g in d.goals)
      if (g.exerciseId != null) g.exerciseId!,
  };
  String nextId() => nextGoalId([...d.goals, ...out]);
  for (final m in d.movements) {
    if (out.length >= 2) break;
    final i = d.levels[m.key];
    if (i == null || i < 0 || i >= m.bands.length) continue;
    if (taken.contains(m.exerciseId)) continue;
    final g = _forLevel(m, m.bands[i], today, nextId());
    if (g != null) {
      out.add(g);
      taken.add(m.exerciseId);
    }
  }
  if (!d.goals.any((g) => g.kind == GoalKind.habit)) {
    final days = d.days.length;
    final beginner =
        d.experience == null || d.experience == ExperienceLevel.beginner;
    var n = days == 0 ? (beginner ? 2 : 3) : days;
    if (n < 2) n = 2;
    if (n > 4) n = 4;
    out.add(
      Goal(
        id: nextId(),
        kind: GoalKind.habit,
        origin: GoalOrigin.suggested,
        createdOn: today,
        sessionsPerWeek: n,
        weeks: 8,
      ),
    );
  }
  return out;
}
