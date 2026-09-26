import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'game.dart';
import 'game_widgets.dart';
import 'progression.dart';
import 'store.dart';
import 'ui.dart';
import 'stats_widgets.dart';

class StatsLevelCard extends StatelessWidget {
  final Progression progress;
  final VoidCallback onTap;
  const StatsLevelCard({
    super.key,
    required this.progress,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => KCard(
    color: SL.bordeaux,
    onTap: onTap,
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TON NIVEAU',
                    style: TextStyle(
                      color: SL.onBrandSoft,
                      fontSize: 10,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progress.rank.title,
                    style: TextStyle(
                      color: SL.onBrand,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${progress.level}',
              style: TextStyle(
                color: SL.onBrand,
                fontSize: 46,
                height: 1,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: SL.onBrand, size: 20),
          ],
        ),
        const SizedBox(height: 18),
        KProgressBar(
          value: progress.fraction,
          height: 5,
          color: SL.onBrand,
          track: SL.onBrand.withValues(alpha: .2),
          semanticsLabel: 'Progression du niveau',
          semanticsValue: '${progress.inLevel} sur ${progress.need} XP',
        ),
        const SizedBox(height: 9),
        Text(
          '${progress.remaining} XP avant le niveau ${progress.level + 1}',
          style: TextStyle(color: SL.onBrand, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          '${progress.earnedBadges} badges · ${store.credits >= 0 ? '${store.credits} crédits WOD' : creditDeficitLabel(store.credits)}',
          style: TextStyle(color: SL.onBrandSoft, fontSize: 11),
        ),
      ],
    ),
  );
}

void showStatsLevel(BuildContext context) {
  final p = store.progression;
  statsSheet(context, 'Ton niveau, tes récompenses', [
    Text(
      'Niveau ${p.level} · ${p.rank.title}',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    StatsBar(
      value: p.fraction,
      label: 'Niveau',
      description: '${p.inLevel} sur ${p.need} XP',
    ),
    Text(
      '${p.remaining} XP avant le niveau ${p.level + 1} et +${p.nextCredits} crédit${p.nextCredits > 1 ? 's' : ''} WOD.',
    ),
    Text(
      '${store.credits >= 0 ? '${store.credits} crédits disponibles' : creditDeficitLabel(store.credits)} · ${p.totalXp} XP cumulés',
    ),
    const KSection('Tes rangs'),
    for (final rank in progressRanks)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          p.level >= rank.level
              ? Icons.verified_rounded
              : Icons.lock_outline_rounded,
          color: p.level >= rank.level ? SL.success : SL.dim,
        ),
        title: Text(rank.title),
        subtitle: Text(
          'Niveau ${rank.level} · ${Progression.xpAtLevel(rank.level)} XP cumulés',
        ),
        trailing: rank == p.rank ? const KBadge('Actuel') : null,
      ),
    const Text('Les rangs décrivent ton parcours dans l’application.'),
    const KSection('Origine de tes XP'),
    for (final entry
        in <String, int>{
          'Programme': p.programXp,
          'Séances personnelles': p.customXp,
          'Tentatives WOD': p.wodXp,
          'Références et records WOD': p.recordXp,
          'Objectifs hebdomadaires': p.weeklyXp,
          'Badges': p.badgeXp,
        }.entries)
      Row(
        children: [
          Expanded(child: Text(entry.key)),
          const SizedBox(width: 12),
          Text(
            '${entry.value} XP',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
  ]);
}

class StatsMissionCard extends StatelessWidget {
  final WeeklyMission mission;
  const StatsMissionCard(this.mission, {super.key});
  @override
  Widget build(BuildContext context) => KCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              mission.complete
                  ? Icons.check_circle_rounded
                  : Icons.flag_outlined,
              color: mission.complete ? SL.success : SL.accent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mission.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(mission.detail, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        StatsBar(
          value: mission.fraction,
          label: mission.title,
          description: '${mission.current} sur ${mission.target}',
          color: mission.complete ? SL.success : null,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              mission.complete
                  ? 'Objectif atteint'
                  : '${mission.current} / ${mission.target}',
              style: TextStyle(
                color: mission.complete ? SL.success : SL.text,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              '+${mission.xp} XP${mission.complete ? ' inclus' : ''}',
              style: TextStyle(color: SL.dim, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

void showStatsMissions(BuildContext context) {
  final week = store.progression.week;
  statsSheet(context, 'Défis de la semaine', [
    Text(
      'Du ${statsDate(week.monday)} au ${statsDate(week.monday.add(const Duration(days: 6)))}',
    ),
    for (final mission in week.missions) StatsMissionCard(mission),
    const Text(
      'Les bonus sont automatiques. Les jours de repos ne cassent pas ta régularité : deux jours actifs dans la semaine suffisent. Les autres défis restent facultatifs.',
    ),
  ]);
}

class StatsProgression extends StatefulWidget {
  const StatsProgression({super.key});
  @override
  State<StatsProgression> createState() => _StatsProgressionState();
}

class _StatsProgressionState extends State<StatsProgression> {
  int _branch = 0;
  @override
  Widget build(BuildContext context) {
    final p = store.progression;
    final groups = switch (_branch) {
      0 => const {'sessions': 'Séances', 'sets': 'Séries'},
      1 => const {'streak': 'Semaines régulières'},
      _ => const {
        'wods': 'WOD terminés',
        'variety': 'Exploration',
        'records': 'Records WOD',
      },
    };
    return KList(
      key: const PageStorageKey('stats-journey-scroll'),
      children: [
        const SizedBox(height: 4),
        Text(
          'Ton arbre de progression',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Plusieurs chemins pour avancer. Chaque palier a son objectif.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Column(
          key: const ValueKey('progress-tree'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KCard(
              onTap: () => showCharacterSheet(context),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  RankInsignia(
                    rankIndex: rankIndexOf(p.rank),
                    prestige: GameState.prestigeOf(p.level),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NIV. ${p.level} · ${p.rank.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${p.earnedBadges} / ${p.badges.length} badges obtenus',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
            SizedBox(
              height: 24,
              child: CustomPaint(painter: _TreeFork(SL.line, 3)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, label, icon) in [
                  (0, 'Pratique', Icons.fitness_center_rounded),
                  (1, 'Rythme', Icons.event_repeat_rounded),
                  (2, 'Défis', Icons.bolt_rounded),
                ])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: index == 1 ? 4 : 0,
                      ),
                      child: Semantics(
                        selected: _branch == index,
                        child: OutlinedButton(
                          key: ValueKey('stats-branch-$index'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                            backgroundColor:
                                _branch == index ? SL.action : SL.card,
                            foregroundColor:
                                _branch == index ? SL.onAction : SL.dim,
                            side: BorderSide(
                              color: _branch == index ? SL.action : SL.line,
                            ),
                          ),
                          onPressed: () => setState(() => _branch = index),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 21),
                              const SizedBox(height: 5),
                              Text(label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, bounds) {
                final columns =
                    groups.length > 1 &&
                            bounds.maxWidth >= 330 &&
                            MediaQuery.textScalerOf(context).scale(14) <= 16
                        ? 2
                        : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 24,
                  children: [
                    for (final group in groups.entries)
                      SizedBox(
                        width: (bounds.maxWidth - 12 * (columns - 1)) / columns,
                        child: _BadgeChain(
                          title: group.value,
                          badges:
                              p.badges
                                  .where((b) => b.badge.metric == group.key)
                                  .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        KMenuTile(
          icon: Icons.map_outlined,
          title: 'Campagne, boss et saisons',
          subtitle: campaignSummary(store.game),
          onTap: () => showCampaign(context),
        ),
        KMenuTile(
          icon: Icons.workspace_premium_rounded,
          title: 'Tes titres',
          subtitle:
              '${store.game.earnedTitles.length} / ${store.game.titles.length} obtenus · ${store.settings.title.isEmpty ? 'le rang est affiché' : 'affiché : ${store.settings.title}'}',
          onTap: () => showTitles(context),
        ),
        KMenuTile(
          icon: Icons.flag_outlined,
          title: 'Défis de la semaine',
          subtitle:
              '${p.week.missions.where((m) => m.complete).length} / ${p.week.missions.length} objectifs atteints',
          onTap: () => showStatsMissions(context),
        ),
        Text(
          'Chaque badge rapporte son bonus une seule fois. Ton historique compte déjà dans ces objectifs.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BadgeChain extends StatelessWidget {
  final String title;
  final List<BadgeProgress> badges;
  const _BadgeChain({required this.title, required this.badges});
  @override
  Widget build(BuildContext context) {
    final next = badges.where((b) => !b.earned).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SL.dim,
              fontSize: 11,
              letterSpacing: .8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0)
            Center(
              child: Container(
                width: 2,
                height: 18,
                color:
                    badges[i - 1].earned
                        ? SL.success.withValues(alpha: .6)
                        : SL.line,
              ),
            ),
          _BadgeNode(badges[i], next: badges[i] == next),
        ],
      ],
    );
  }
}

class _BadgeNode extends StatelessWidget {
  final BadgeProgress item;
  final bool next;
  const _BadgeNode(this.item, {required this.next});
  @override
  Widget build(BuildContext context) {
    final status =
        item.earned
            ? 'Obtenu'
            : next
            ? 'Prochain palier'
            : 'À venir';
    final color =
        item.earned
            ? SL.success
            : next
            ? SL.accent
            : SL.dim;
    return Semantics(
      button: true,
      label:
          '${item.badge.title}. $status. ${item.badge.description}. ${item.current} sur ${item.badge.target}. ${item.badge.xp} XP.',
      onTap: () => _detail(context),
      excludeSemantics: true,
      child: KCard(
        key: ValueKey('badge-${item.badge.id}'),
        onTap: () => _detail(context),
        outline: next ? SL.accent.withValues(alpha: .55) : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.earned
                  ? Icons.verified_rounded
                  : next
                  ? Icons.radio_button_checked_rounded
                  : Icons.lock_outline_rounded,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              item.badge.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            RarityChip(rarityOf(item.badge)),
            const SizedBox(height: 5),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            StatsBar(
              value: item.fraction,
              label: item.badge.description,
              // Palier en cours : dégradé de la charte ; obtenu : vert.
              color: next ? null : color,
            ),
            const SizedBox(height: 7),
            Text(
              '${item.current.clamp(0, item.badge.target)} / ${item.badge.target}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 3),
            Text(
              '+${item.badge.xp} XP',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _detail(BuildContext context) => statsSheet(context, item.badge.title, [
    Icon(
      item.earned ? Icons.verified_rounded : Icons.workspace_premium_outlined,
      size: 54,
      color: item.earned ? SL.success : SL.accent,
    ),
    Text(
      item.badge.description,
      style: Theme.of(context).textTheme.titleMedium,
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: RarityChip(rarityOf(item.badge)),
    ),
    StatsBar(
      value: item.fraction,
      label: item.badge.title,
      description: '${item.current} sur ${item.badge.target}',
    ),
    Text(
      item.earned
          ? 'Objectif atteint · total actuel : ${item.current}'
          : '${item.current} / ${item.badge.target} · encore ${item.badge.target - item.current} pour ce palier',
    ),
    Text(
      item.earned
          ? '+${item.badge.xp} XP déjà inclus dans ton total.'
          : '+${item.badge.xp} XP attribués automatiquement quand l’objectif est atteint.',
    ),
    if (item.badge.metric == 'streak')
      const Text(
        'Une semaine est régulière à partir de deux jours actifs. Les repos sont compatibles avec cet objectif.',
      ),
  ]);
}

class _TreeFork extends CustomPainter {
  final Color color;
  final int branches;
  const _TreeFork(this.color, this.branches);
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    for (var i = 0; i < branches; i++) {
      final x = size.width * (i + .5) / branches;
      final path =
          Path()
            ..moveTo(size.width / 2, 0)
            ..lineTo(size.width / 2, size.height / 2)
            ..lineTo(x, size.height / 2)
            ..lineTo(x, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TreeFork old) =>
      old.color != color || old.branches != branches;
}

void showStatsRules(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder:
      (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Comment progresser',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Le barème de base est conservé : 100 XP pour une journée du programme validée, 60 XP pour une séance personnelle et 80 XP par tentative WOD enregistrée. Une première performance WOD valide rapporte 40 XP, puis chaque amélioration stricte de ce record rapporte 40 XP supplémentaires. Une égalité ou un WOD inachevé ne rapporte pas de bonus de record.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Les badges et les objectifs hebdomadaires ajoutent des bonus automatiques. Les objectifs se renouvellent le lundi et leurs bonus passés restent calculés depuis le journal. Deux séances le même jour comptent pour un seul jour actif. Les jours de récupération du programme ne comptent pas comme des entraînements pour ces bonus.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Une semaine avec 2 jours actifs prolonge la série de régularité. La semaine en cours peut encore être complétée : elle ne casse pas la série avant le lundi suivant. Aucun entraînement quotidien n’est exigé.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Chaque niveau donne 2 crédits WOD, et 3 de plus tous les 5 niveaux (3 offerts au départ). Chapitre bouclé : +3, boss vaincu : +5, semaine complète : +1. Les WODs déjà débloqués restent accessibles.',
            ),
            const SizedBox(height: 14),
            const Text(
              'Les XP sont recalculés depuis tes données : supprimer un résultat ou une séance retire les XP et bonus associés. Réimporter la même sauvegarde ne double aucune récompense. Les anciennes séances sans date utilisent, si possible, la date prévue du programme ; une séance personnelle sans date ne compte pas pour les bonus de régularité.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      ),
);
