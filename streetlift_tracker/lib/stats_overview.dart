import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'game_widgets.dart';
import 'motivation_screens.dart' show ProgressScreen;
import 'progression.dart';
import 'store.dart';
import 'ui.dart';
import 'stats_navigation.dart';
import 'stats_progression.dart';
import 'stats_widgets.dart';

class StatsOverview extends StatelessWidget {
  final ValueChanged<StatsSection> onSection;
  const StatsOverview({super.key, required this.onSection});
  @override
  Widget build(BuildContext context) {
    final p = store.progression;
    final remaining =
        p.week.missions.where((m) => !m.complete).toList()
          ..sort((a, b) => b.fraction.compareTo(a.fraction));
    final next = remaining.firstOrNull ?? p.week.missions.first;
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
        CharacterCard(onTap: () => showCharacterSheet(context)),
        const KSection('Objectif et série'),
        // Pleine largeur : à 320 px avec texte agrandi, deux colonnes ne
        // laisseraient pas la place aux anneaux et aux boucliers.
        const WeeklyGoalCard(),
        const StreakCard(),
        const KSection(
          'Quêtes',
          subtitle: 'Principale : ta prochaine journée · hebdo : bonus XP',
        ),
        const MainQuestCard(),
        StatsMissionCard(next),
        KSection(
          'Campagne',
          subtitle: 'Chapitres du programme, boss et saison',
          actionLabel: 'Parcours',
          onAction: () => onSection(StatsSection.journey),
        ),
        const CampaignStrip(),
        const BossCard(),
        const SeasonCard(),
        const KSection('Toi contre toi-même'),
        const SelfCompareCard(),
        KSection(
          'Cette semaine',
          subtitle:
              'Du ${statsDate(p.week.monday)} au ${statsDate(p.week.monday.add(const Duration(days: 6)))}',
        ),
        StatsGrid(
          children: [
            StatsMetric(
              '${p.week.sessions + p.week.wods}',
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
              '${p.currentStreak}',
              'Semaines de suite',
              Icons.local_fire_department_outlined,
            ),
          ],
        ),
        KMenuTile(
          icon: Icons.flag_outlined,
          title: remaining.isEmpty ? 'Défis validés' : 'Défis de la semaine',
          subtitle:
              '${p.week.missions.where((m) => m.complete).length} / ${p.week.missions.length} objectifs atteints · bonus XP automatiques',
          onTap: () => showStatsMissions(context),
        ),
        KMenuTile(
          icon: Icons.account_tree_rounded,
          title: 'Arbre de progression',
          subtitle:
              '${p.earnedBadges} badges obtenus · pratique, rythme et défis',
          onTap: () => onSection(StatsSection.journey),
        ),
        const KSection(
          'Ton rythme',
          subtitle: '8 dernières semaines · jours actifs',
        ),
        _ActivityCard(p),
        Text(
          'Deux jours actifs valident une semaine. Les jours de repos font partie du parcours.',
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
            StatsMetric('${p.wods}', 'WOD terminés', Icons.bolt_rounded),
            StatsMetric('${p.sets}', 'Séries au total', Icons.layers_outlined),
            StatsMetric(
              '${p.records}',
              'Records WOD améliorés',
              Icons.emoji_events_outlined,
            ),
          ],
        ),
        KMenuTile(
          icon: Icons.insights_rounded,
          title: 'Performances et références',
          subtitle: 'Force, endurance, muscles et records WOD',
          onTap: () => onSection(StatsSection.performance),
        ),
        KMenuTile(
          icon: Icons.history_rounded,
          title: 'Tout ton historique',
          subtitle: 'Séances, résultats WOD et notes',
          onTap: () => onSection(StatsSection.history),
        ),
        // L12 (KT-065) : victoires, figures, étapes franchies, partage.
        KMenuTile(
          key: const ValueKey('stats-motiv-progress'),
          icon: Icons.emoji_events_outlined,
          title: 'Mes progrès',
          subtitle: 'Victoires, figures, étapes franchies et partage',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ProgressScreen()),
              ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Progression progress;
  const _ActivityCard(this.progress);
  @override
  Widget build(BuildContext context) => KCard(
    key: const ValueKey('stats-activity'),
    onTap:
        () => statsSheet(context, 'Ton activité sur 8 semaines', [
          Text(
            'Meilleure série : ${progress.bestStreak} semaine${progress.bestStreak > 1 ? 's' : ''} · ${progress.activeWeeks} semaines validées',
          ),
          for (final week in progress.recentWeeks.reversed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                week.activeDays.length >= 2
                    ? Icons.check_circle_rounded
                    : Icons.calendar_today_outlined,
                color: week.activeDays.length >= 2 ? SL.success : SL.dim,
              ),
              title: Text('Semaine du ${statsDate(week.monday)}'),
              subtitle: Text(
                '${week.activeDays.length} jours actifs · ${week.sessions} séances · ${week.wods} WOD · ${week.sets} séries',
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
                                    color:
                                        week.activeDays.isEmpty ? SL.dot : null,
                                    gradient:
                                        week.activeDays.isEmpty
                                            ? null
                                            : const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                KPalette.burgundy,
                                                KPalette.actionRed,
                                              ],
                                            ),
                                    border:
                                        week.activeDays.isEmpty
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
