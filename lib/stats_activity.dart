// Statistiques d'activité de STATS › Aperçu (séances, séries, jours actifs
// par semaine), calculées depuis le journal comme avant G12 : même lecture
// des dates et des journées du programme que l'ancien calcul de
// progression (progression.dart, retiré en G12 avec les XP, badges et
// séries de l'ancien système, D1.3). Les statistiques ne changent pas.
import 'models.dart';
import 'store.dart' show SessionLog;

/// Dates civiles UTC : le calcul de semaines ne dépend pas des jours de
/// 23/25 h.
DateTime civilDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
DateTime mondayOf(DateTime date) {
  final day = civilDay(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

class ActivityWeek {
  final DateTime monday;
  final Set<DateTime> activeDays = {};
  int sets = 0, sessions = 0;
  ActivityWeek(this.monday);
}

class ActivityStats {
  final int sessions, sets;
  final ActivityWeek week;

  /// Les 8 dernières semaines, de la plus ancienne à la semaine en cours.
  final List<ActivityWeek> recentWeeks;

  /// Semaines avec au moins une journée d'entraînement.
  final int activeWeeks;

  /// Toutes les semaines ayant une activité (clé : lundi civil UTC).
  final Map<DateTime, ActivityWeek> weeks;

  const ActivityStats({
    required this.sessions,
    required this.sets,
    required this.week,
    required this.recentWeeks,
    required this.activeWeeks,
    this.weeks = const {},
  });

  factory ActivityStats.calculate({
    required Map<String, SessionLog> logs,
    required Program program,
    required DateTime now,
  }) {
    final weeks = <DateTime, ActivityWeek>{};
    ActivityWeek bucket(DateTime at) =>
        weeks.putIfAbsent(mondayOf(at), () => ActivityWeek(mondayOf(at)));
    DateTime? parsePast(String? value) {
      final parsed = value == null ? null : DateTime.tryParse(value)?.toLocal();
      return parsed == null || parsed.isAfter(now) ? null : parsed;
    }

    var sessions = 0, sets = 0;
    for (final entry in logs.entries) {
      final log = entry.value;
      final match = RegExp(r'^S(\d+)-J(\d+)').firstMatch(entry.key);
      DayPlan? plan;
      DateTime? fallback;
      if (match != null) {
        final week = int.parse(match[1]!);
        final day = int.parse(match[2]!);
        if (week >= 1 && week <= program.weeks.length && day >= 1 && day <= 7) {
          plan = program.week(week).day(day);
          // Ancienne séance sans date enregistrée : date prévue par l'ancrage
          // d'origine, indépendante d'un départ modifié ensuite (KT-006).
          fallback = program.legacyDateFor(week, day);
        }
      }
      final at = log.finishedAt == null
          ? (fallback != null && !fallback.isAfter(now) ? fallback : null)
          : parsePast(log.finishedAt);
      final training = plan?.exercises.isNotEmpty == true;
      if (log.done && training && at != null) {
        sessions++;
        bucket(at)
          ..sessions += 1
          ..activeDays.add(civilDay(at));
      }
      for (final exercise in log.ex.values) {
        for (final set in exercise.sets.where((s) => s.done)) {
          final completed = set.completedAt == null
              ? at
              : parsePast(set.completedAt);
          if (set.completedAt != null && completed == null) continue;
          sets++;
          if (completed != null) bucket(completed).sets++;
        }
      }
    }
    final thisMonday = mondayOf(now);
    final current = weeks.putIfAbsent(
      thisMonday,
      () => ActivityWeek(thisMonday),
    );
    return ActivityStats(
      sessions: sessions,
      sets: sets,
      week: current,
      recentWeeks: [
        for (var i = 7; i >= 0; i--)
          weeks[thisMonday.subtract(Duration(days: i * 7))] ??
              ActivityWeek(thisMonday.subtract(Duration(days: i * 7))),
      ],
      activeWeeks: weeks.values.where((w) => w.activeDays.isNotEmpty).length,
      weeks: weeks,
    );
  }
}
