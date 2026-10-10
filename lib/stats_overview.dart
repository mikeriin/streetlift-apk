import 'package:flutter/material.dart';
import 'game_widgets.dart';
import 'kit/kit.dart';
import 'progression.dart';
import 'store.dart';
import 'stats_navigation.dart';
import 'stats_progression.dart';
import 'stats_widgets.dart';

/// « n jour actif » / « n jours actifs ».
String statsPlural(int n, String one, String many) =>
    '$n ${n > 1 ? many : one}';

/// Aperçu (UI3, cahier §4.1) : le résumé. Ses cartes et ses lignes ouvrent
/// l'onglet concerné, jamais une feuille déjà joignable ailleurs (les
/// feuilles de jeu vivent dans Parcours) ; l'objectif de la semaine se règle
/// sur place (raccourci R2, mêmes segments que Réglages).
class StatsOverview extends StatelessWidget {
  final ValueChanged<StatsSection> onSection;
  const StatsOverview({super.key, required this.onSection});
  @override
  Widget build(BuildContext context) {
    final p = store.progression;
    final remaining = p.week.missions.where((m) => !m.complete).toList()
      ..sort((a, b) => b.fraction.compareTo(a.fraction));
    final next = remaining.firstOrNull ?? p.week.missions.first;
    final validated = p.week.missions.where((m) => m.complete).length;
    void journey() => onSection(StatsSection.journey);
    return StatsList(
      key: const PageStorageKey('stats-overview-scroll'),
      children: [
        CharacterCard(onTap: journey),
        const KSectionTitle('Objectif et série'),
        // Pleine largeur : à 320 px avec texte agrandi, deux colonnes ne
        // laisseraient pas la place aux anneaux et aux boucliers.
        const WeeklyGoalCard(),
        const StreakCard(),
        const KSectionTitle(
          'Quêtes : ta prochaine journée et les défis de la semaine (bonus XP)',
        ),
        const MainQuestCard(),
        StatsMissionCard(
          next,
          overline:
              'Défis de la semaine\u00A0· $validated / ${p.week.missions.length} validés\u00A0· bonus XP automatiques',
          onTap: journey,
        ),
        const KSectionTitle(
          'Campagne : chapitres du programme, boss et saison',
        ),
        CampaignStrip(onTap: journey),
        BossCard(onTap: journey),
        SeasonCard(onTap: journey),
        const KSectionTitle('Toi contre toi-même'),
        const SelfCompareCard(),
        KSectionTitle(
          'Cette semaine, du ${statsDate(p.week.monday)} au ${statsDate(p.week.monday.add(const Duration(days: 6)))}',
        ),
        StatsGrid(
          children: [
            StatsMetric(
              '${p.week.sessions}',
              'Séances terminées',
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
        const KSectionTitle(
          'Ton rythme : jours actifs des 8 dernières semaines',
        ),
        _ActivityCard(p),
        const StatsText(
          'Deux jours actifs valident une semaine. Les jours de repos font partie du parcours.',
          muted: true,
        ),
        const KSectionTitle('Depuis tes débuts'),
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
              'Semaines validées',
              Icons.event_available_rounded,
            ),
            StatsMetric(
              '${p.bestStreak}',
              'Meilleure série (semaines)',
              Icons.local_fire_department_rounded,
            ),
          ],
        ),
        KMenuGroup(
          title: 'Aller plus loin',
          children: [
            KMenuRow(
              key: const ValueKey('stats-open-journey'),
              icon: Icons.account_tree_rounded,
              title: 'Parcours',
              subtitle:
                  '${p.earnedBadges} badges obtenus, défis, campagne, boss, saisons et titres',
              onTap: journey,
            ),
            KMenuRow(
              key: const ValueKey('stats-open-performance'),
              icon: Icons.insights_rounded,
              title: 'Performances',
              subtitle: 'Mes références, records, force, endurance et muscles',
              onTap: () => onSection(StatsSection.performance),
            ),
            KMenuRow(
              key: const ValueKey('stats-open-history'),
              icon: Icons.history_rounded,
              title: 'Historique',
              subtitle: 'Toutes tes séances et leurs notes',
              onTap: () => onSection(StatsSection.history),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Progression progress;
  const _ActivityCard(this.progress);

  void _detail(BuildContext context) {
    final best = progress.bestStreak;
    statsSheet(
      context,
      'Ton activité sur 8 semaines',
      subtitle:
          'Meilleure série : ${statsPlural(best, 'semaine', 'semaines')}\u00A0· ${statsPlural(progress.activeWeeks, 'semaine validée', 'semaines validées')}',
      [
        StatsSheetGroup(
          children: [
            for (final week in progress.recentWeeks.reversed)
              Builder(
                builder: (context) {
                  final k = KTokens.of(context);
                  final ok = week.activeDays.length >= 2;
                  return StatsSheetRow(
                    icon: ok
                        ? Icons.check_circle_rounded
                        : Icons.calendar_today_outlined,
                    iconColor: ok ? k.validation : k.texte2,
                    title: 'Semaine du ${statsDate(week.monday)}',
                    subtitle:
                        '${statsPlural(week.activeDays.length, 'jour actif', 'jours actifs')}\u00A0· ${statsPlural(week.sessions, 'séance', 'séances')}\u00A0· ${statsPlural(week.sets, 'série', 'séries')}',
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final weeks = progress.recentWeeks;
    const chart = KSize.primary + KSpacing.s32;
    return KCard(
      key: const ValueKey('stats-activity'),
      onTap: () => _detail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Une habitude qui se construit',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: KSize.icon,
                color: k.texte2,
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s16),
          Semantics(
            label:
                'Jours actifs, de la semaine la plus ancienne à la plus récente : ${weeks.map((w) => w.activeDays.length).join(', ')}. Appuyer pour le détail.',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < weeks.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KSpacing.s4,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${weeks[i].activeDays.length}',
                              style: KType.micro.copyWith(color: k.texte2),
                            ),
                            const SizedBox(height: KSpacing.s4),
                            SizedBox(
                              height: chart,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: (weeks[i].activeDays.length / 7)
                                      .clamp(.08, 1.0),
                                  widthFactor: .5,
                                  child: DecoratedBox(
                                    decoration: ShapeDecoration(
                                      // Semaine en cours en `encre`, les
                                      // précédentes en `second` (données).
                                      color: weeks[i].activeDays.isEmpty
                                          ? k.filet
                                          : i == weeks.length - 1
                                          ? k.encre
                                          : k.second,
                                      shape: KRadius.pill,
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
          const SizedBox(height: KSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  statsDate(weeks.first.monday),
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              Flexible(
                child: Text(
                  'Cette semaine',
                  textAlign: TextAlign.end,
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
