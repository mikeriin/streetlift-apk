import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'quest/progression_view.dart' show QuestResetNotice;
import 'quest/quest_texts.dart' show thousands;
import 'quest/quest_widgets.dart' show LevelProgressNumber;
import 'kalis_clock.dart';
import 'stats_activity.dart';
import 'store.dart';
import 'ui.dart';
import 'stats_navigation.dart';
import 'stats_widgets.dart';

class StatsOverview extends StatelessWidget {
  final ValueChanged<StatsSection> onSection;
  const StatsOverview({super.key, required this.onSection});
  @override
  Widget build(BuildContext context) {
    final p = ActivityStats.calculate(
      logs: store.logs,
      program: store.program,
      now: KalisClock.now(),
    );
    final o = store.quest;
    final streak = o?.extras?['streak'];
    final best = streak is Map ? (streak['best'] as num?)?.toInt() : null;
    final current = o?.weekStreak;
    return KList(
      key: const PageStorageKey('stats-overview-scroll'),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(
            'Chaque effort construit la suite.',
            style: TextStyle(color: SL.dim, fontSize: 14),
          ),
        ),
        const QuestResetNotice(),
        _ProgressionSummary(
          onTap: () => onSection(StatsSection.progression),
        ),
        KSection(
          'Cette semaine',
          subtitle:
              'Du ${statsDate(p.week.monday)} au ${statsDate(p.week.monday.add(const Duration(days: 6)))}',
        ),
        StatsGrid(
          children: [
            StatsMetric(
              '${p.week.sessions}',
              'Entraînements terminés',
              Icons.fitness_center_rounded,
            ),
            StatsMetric(
              '${p.week.sets}',
              'Séries validées',
              Icons.done_all_rounded,
            ),
            StatsMetric(
              '${p.week.activeDays.length}',
              'Jours actifs',
              Icons.calendar_today_rounded,
            ),
            StatsMetric(
              current == null ? '—' : '$current',
              'Semaines réussies de suite',
              Icons.local_fire_department_outlined,
            ),
          ],
        ),
        const KSection(
          'Ton rythme',
          subtitle: '8 dernières semaines · jours actifs',
        ),
        _ActivityCard(p),
        Text(
          'Les jours de repos font partie du parcours.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const KSection('Depuis tes débuts'),
        StatsGrid(
          children: [
            StatsMetric(
              '${p.sessions}',
              'Séances terminées',
              Icons.task_alt_rounded,
            ),
            StatsMetric('${p.sets}', 'Séries au total', Icons.layers_outlined),
            StatsMetric(
              '${p.activeWeeks}',
              'Semaines actives',
              Icons.event_available_rounded,
            ),
            StatsMetric(
              best == null ? '—' : '$best',
              'Meilleure série (semaines)',
              Icons.local_fire_department_rounded,
            ),
          ],
        ),
        KMenuTile(
          icon: Icons.insights_rounded,
          title: 'Performances et références',
          subtitle: 'Force, endurance, muscles et records',
          onTap: () => onSection(StatsSection.performance),
        ),
        KMenuTile(
          icon: Icons.history_rounded,
          title: 'Tout ton historique',
          subtitle: 'Séances et notes',
          onTap: () => onSection(StatsSection.history),
        ),
      ],
    );
  }
}

/// Niveau et XP (G12) : ouvre STATS › Progression.
class _ProgressionSummary extends StatelessWidget {
  final VoidCallback onTap;
  const _ProgressionSummary({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final l = store.questLevel;
    final tt = Theme.of(context).textTheme;
    return KCard(
      key: const ValueKey('stats-progression-card'),
      onTap: onTap,
      child: Row(
        children: [
          LevelProgressNumber(
            level: l.level,
            prestige: l.prestige,
            progress: l.xpForNextLevel == 0
                ? 0
                : l.xpIntoLevel / l.xpForNextLevel,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ma progression', style: tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${thousands(l.xpIntoLevel)} / ${thousands(l.xpForNextLevel)} XP · '
                  'quêtes, attributs, rangs, objectifs',
                  style: tt.bodySmall?.copyWith(color: SL.dim),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: SL.dim),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityStats progress;
  const _ActivityCard(this.progress);
  @override
  Widget build(BuildContext context) => KCard(
    key: const ValueKey('stats-activity'),
    onTap: () => statsSheet(context, 'Ton activité sur 8 semaines', [
      Text(
        '${progress.activeWeeks} semaine${progress.activeWeeks > 1 ? 's' : ''} avec au moins une séance',
      ),
      for (final week in progress.recentWeeks.reversed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            week.activeDays.isNotEmpty
                ? Icons.event_available_rounded
                : Icons.calendar_today_outlined,
            color: SL.dim,
          ),
          title: Text('Semaine du ${statsDate(week.monday)}'),
          subtitle: Text(
            '${week.activeDays.length} jours actifs · ${week.sessions} séances · ${week.sets} séries',
          ),
        ),
    ]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Une habitude qui se construit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          label:
              'Jours actifs, de la semaine la plus ancienne à la plus récente : ${progress.recentWeeks.map((w) => w.activeDays.length).join(', ')}. Appuyer pour le détail.',
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final week in progress.recentWeeks)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          Text(
                            '${week.activeDays.length}',
                            style: TextStyle(color: SL.dim, fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 64,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (week.activeDays.length / 7)
                                    .clamp(.045, 1.0),
                                widthFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: week.activeDays.isEmpty
                                        ? SL.dot
                                        : null,
                                    gradient: week.activeDays.isEmpty
                                        ? null
                                        : const LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              KPalette.burgundy,
                                              KPalette.actionRed,
                                            ],
                                          ),
                                    border: week.activeDays.isEmpty
                                        ? null
                                        : Border.all(color: SL.dim),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                statsDate(progress.recentWeeks.first.monday),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Cette sem.',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
