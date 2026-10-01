import 'dart:math' as math;
import 'models.dart';
import 'store.dart' show SessionLog;

// Ces rangs expriment la progression dans l'application, pas une mesure physique.
class ProgressRank {
  final int level;
  final String title;
  const ProgressRank(this.level, this.title);
}

const progressRanks = [
  ProgressRank(1, 'Recrue'),
  ProgressRank(5, 'Régulier'),
  ProgressRank(10, 'Challenger'),
  ProgressRank(20, 'Vétéran'),
  ProgressRank(30, 'Expert'),
  ProgressRank(45, 'Élite'),
  ProgressRank(60, 'Légende'),
];

class BadgeDefinition {
  final String id, title, metric, description;
  final int target, xp;
  const BadgeDefinition(
    this.id,
    this.title,
    this.metric,
    this.target,
    this.xp,
    this.description,
  );
}

const progressionBadges = [
  BadgeDefinition(
    'session1',
    'Premier pas',
    'sessions',
    1,
    40,
    'Terminer 1 séance d’entraînement',
  ),
  BadgeDefinition(
    'session10',
    'Dans le rythme',
    'sessions',
    10,
    120,
    'Terminer 10 séances d’entraînement',
  ),
  BadgeDefinition(
    'session50',
    'Solide habitude',
    'sessions',
    50,
    300,
    'Terminer 50 séances d’entraînement',
  ),
  BadgeDefinition(
    'session100',
    'Centurion',
    'sessions',
    100,
    600,
    'Terminer 100 séances d’entraînement',
  ),
  BadgeDefinition(
    'sets100',
    'Fondations',
    'sets',
    100,
    120,
    'Valider 100 séries',
  ),
  BadgeDefinition(
    'sets500',
    'Bâtisseur',
    'sets',
    500,
    300,
    'Valider 500 séries',
  ),
  BadgeDefinition(
    'sets2000',
    'Longue distance',
    'sets',
    2000,
    600,
    'Valider 2 000 séries',
  ),
  BadgeDefinition(
    'streak4',
    'Régularité',
    'streak',
    4,
    160,
    '4 semaines de suite avec au moins 2 jours actifs',
  ),
  BadgeDefinition(
    'streak12',
    'Au long cours',
    'streak',
    12,
    400,
    '12 semaines de suite avec au moins 2 jours actifs',
  ),
];

class BadgeProgress {
  final BadgeDefinition badge;
  final int current;
  const BadgeProgress(this.badge, this.current);
  bool get earned => current >= badge.target;
  double get fraction => (current / badge.target).clamp(0.0, 1.0);
}

class WeeklyMission {
  final String id, title, detail;
  final int current, target, xp;
  const WeeklyMission(
    this.id,
    this.title,
    this.detail,
    this.current,
    this.target,
    this.xp,
  );
  bool get complete => current >= target;
  double get fraction => (current / target).clamp(0.0, 1.0);
}

/// Dates civiles UTC : le calcul de semaines ne dépend pas des jours de 23/25h.
DateTime civilDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
DateTime mondayOf(DateTime date) {
  final day = civilDay(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

class TrainingWeek {
  final DateTime monday;
  final Set<DateTime> activeDays = {};
  int sets = 0, sessions = 0;
  TrainingWeek(this.monday);
  List<WeeklyMission> get missions => [
    WeeklyMission(
      'days2',
      'Trouver son rythme',
      '2 jours d’entraînement distincts',
      activeDays.length,
      2,
      75,
    ),
    WeeklyMission(
      'days3',
      'Garder le cap',
      '3 jours d’entraînement distincts',
      activeDays.length,
      3,
      50,
    ),
    WeeklyMission(
      'sets20',
      'Tenir son journal',
      '20 séries validées dans la semaine',
      sets,
      20,
      50,
    ),
  ];
  int get bonusXp =>
      missions.where((m) => m.complete).fold(0, (sum, m) => sum + m.xp);
}

class Progression {
  final int programXp, weeklyXp, badgeXp;
  final int sessions, sets;
  final int currentStreak, bestStreak, activeWeeks;
  final TrainingWeek week;
  final List<TrainingWeek> recentWeeks;
  final List<BadgeProgress> badges;
  final DateTime? lastActivity;

  /// Toutes les semaines ayant une activité (clé : lundi civil UTC), pour la
  /// couche jeu (série avec boucliers, meilleure semaine).
  final Map<DateTime, TrainingWeek> weeks;
  const Progression({
    required this.programXp,
    required this.weeklyXp,
    required this.badgeXp,
    required this.sessions,
    required this.sets,
    required this.currentStreak,
    required this.bestStreak,
    required this.activeWeeks,
    required this.week,
    required this.recentWeeks,
    required this.badges,
    this.lastActivity,
    this.weeks = const {},
  });

  int get activityXp => programXp;
  int get totalXp => activityXp + weeklyXp + badgeXp;
  static int needFor(int level) => 150 + 50 * (level - 1);
  static int xpAtLevel(int level) => 25 * (level - 1) * (level + 4);
  int get level {
    var value = 1;
    while (totalXp >= xpAtLevel(value + 1)) {
      value++;
    }
    return value;
  }

  int get inLevel => totalXp - xpAtLevel(level);
  int get need => needFor(level);
  int get remaining => need - inLevel;
  double get fraction => inLevel / need;
  ProgressRank get rank => progressRanks.lastWhere((r) => r.level <= level);
  ProgressRank? get nextRank {
    for (final r in progressRanks) {
      if (r.level > level) return r;
    }
    return null;
  }

  int get earnedBadges => badges.where((b) => b.earned).length;

  /// Récompenses dérivées du journal : aucun bouton ne peut les réclamer deux
  /// fois. Les mêmes données importées produisent les mêmes XP. G2 : seules
  /// les journées du programme comptent (WOD et séances manuelles retirés).
  factory Progression.calculate({
    required Map<String, SessionLog> logs,
    required Program program,
    required DateTime now,
  }) {
    final weeks = <DateTime, TrainingWeek>{};
    TrainingWeek bucket(DateTime at) =>
        weeks.putIfAbsent(mondayOf(at), () => TrainingWeek(mondayOf(at)));
    DateTime? parsePast(String? value) {
      final parsed = value == null ? null : DateTime.tryParse(value)?.toLocal();
      return parsed == null || parsed.isAfter(now) ? null : parsed;
    }

    var programXp = 0;
    var sessions = 0, sets = 0;
    DateTime? lastActivity;
    void active(DateTime at) {
      bucket(at).activeDays.add(civilDay(at));
      if (lastActivity == null || at.isAfter(lastActivity!)) lastActivity = at;
    }

    for (final entry in logs.entries) {
      final log = entry.value;
      if (log.done) programXp += 100;
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
      // Une vieille sauvegarde sans date peut utiliser la date du programme.
      // Une date future explicite ne doit jamais donner de bonus anticipé.
      final at = log.finishedAt == null
          ? (fallback != null && !fallback.isAfter(now) ? fallback : null)
          : parsePast(log.finishedAt);
      final training = plan?.exercises.isNotEmpty == true;
      if (log.done && training && at != null) {
        sessions++;
        bucket(at).sessions++;
        active(at);
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
      () => TrainingWeek(thisMonday),
    );
    final qualifying =
        weeks.values
            .where((w) => w.activeDays.length >= 2)
            .map((w) => w.monday)
            .toList()
          ..sort();
    var bestStreak = 0, streak = 0;
    DateTime? previous;
    for (final date in qualifying) {
      streak = previous != null && date.difference(previous).inDays == 7
          ? streak + 1
          : 1;
      bestStreak = math.max(bestStreak, streak);
      previous = date;
    }
    var currentStreak = 0;
    var cursor = current.activeDays.length >= 2
        ? thisMonday
        : thisMonday.subtract(const Duration(days: 7));
    final qualified = qualifying.toSet();
    while (qualified.contains(cursor)) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    final metrics = {
      'sessions': sessions,
      'sets': sets,
      'streak': bestStreak,
    };
    final badges = [
      for (final badge in progressionBadges)
        BadgeProgress(badge, metrics[badge.metric]!),
    ];
    return Progression(
      programXp: programXp,
      sessions: sessions,
      sets: sets,
      weeklyXp: weeks.values.fold(0, (sum, w) => sum + w.bonusXp),
      badgeXp: badges
          .where((b) => b.earned)
          .fold(0, (sum, b) => sum + b.badge.xp),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      activeWeeks: qualifying.length,
      week: current,
      recentWeeks: [
        for (var i = 7; i >= 0; i--)
          weeks[thisMonday.subtract(Duration(days: i * 7))] ??
              TrainingWeek(thisMonday.subtract(Duration(days: i * 7))),
      ],
      badges: badges,
      lastActivity: lastActivity,
      weeks: weeks,
    );
  }
}
