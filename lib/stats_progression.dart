import 'package:flutter/material.dart';
import 'game.dart';
import 'game_widgets.dart';
import 'kit/kit.dart';
import 'progression.dart';
import 'store.dart';
import 'stats_widgets.dart';

/// Carte de niveau (code mort signalé à UI5, cahier §4.6 : conservé, mis
/// aux jetons).
class StatsLevelCard extends StatelessWidget {
  final Progression progress;
  final VoidCallback onTap;
  const StatsLevelCard({
    super.key,
    required this.progress,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final soft = k.surPleine.withValues(alpha: .8);
    return KCard.day(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ton niveau', style: KType.micro.copyWith(color: soft)),
                    const SizedBox(height: KSpacing.s4),
                    Text(
                      progress.rank.title,
                      style: KType.titreEcran.copyWith(color: k.surPleine),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KSpacing.s14),
              Text(
                '${progress.level}',
                style: KType.chiffre.copyWith(color: k.surPleine),
              ),
              const SizedBox(width: KSpacing.s8),
              Icon(
                Icons.chevron_right_rounded,
                color: k.surPleine,
                size: KSize.icon,
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s16),
          StatsBar(
            value: progress.fraction,
            label: 'Progression du niveau',
            description: '${progress.inLevel} sur ${progress.need} XP',
            onFill: true,
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            '${progress.remaining} XP avant le niveau ${progress.level + 1}',
            style: KType.detail.copyWith(color: k.surPleine),
          ),
          Text(
            '${progress.earnedBadges} badges',
            style: KType.detail.copyWith(color: soft),
          ),
        ],
      ),
    );
  }
}

/// Feuille de niveau (code mort signalé à UI5, cahier §4.6).
void showStatsLevel(BuildContext context) {
  final p = store.progression;
  statsSheet(
    context,
    'Ton niveau, tes récompenses',
    subtitle: 'Niveau ${p.level} · ${p.rank.title}',
    [
      StatsBar(
        value: p.fraction,
        label: 'Niveau',
        description: '${p.inLevel} sur ${p.need} XP',
      ),
      StatsText(
        '${p.remaining} XP avant le niveau ${p.level + 1} · ${p.totalXp} XP cumulés.',
      ),
      const KSectionTitle('Tes rangs'),
      StatsSheetGroup(
        children: [
          for (final rank in progressRanks)
            Builder(
              builder: (context) {
                final k = KTokens.of(context);
                return StatsSheetRow(
                  icon: p.level >= rank.level
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                  iconColor: p.level >= rank.level ? k.validation : k.texte2,
                  title: rank.title,
                  subtitle:
                      'Niveau ${rank.level} · ${Progression.xpAtLevel(rank.level)} XP cumulés',
                  trailing: rank == p.rank ? const KChip('Actuel') : null,
                );
              },
            ),
        ],
      ),
      const StatsText('Les rangs décrivent ton parcours dans l’application.'),
      const KSectionTitle('Origine de tes XP'),
      StatsSheetGroup(
        children: [
          for (final entry in <String, int>{
            'Programme': p.programXp,
            'Objectifs hebdomadaires': p.weeklyXp,
            'Badges': p.badgeXp,
          }.entries)
            StatsSheetRow(title: entry.key, value: '${entry.value} XP'),
        ],
      ),
    ],
  );
}

/// Défi de la semaine : titre, consigne, jauge, bonus. [overline] : surtitre
/// (Aperçu) ; [onTap] : ouvre Parcours depuis l'Aperçu ; [inSheet] : posé
/// dans une feuille (`haute`, rayon des menus, jamais une carte dans une
/// carte).
class StatsMissionCard extends StatelessWidget {
  final WeeklyMission mission;
  final String? overline;
  final VoidCallback? onTap;
  final bool inSheet;
  const StatsMissionCard(
    this.mission, {
    super.key,
    this.overline,
    this.onTap,
    this.inSheet = false,
  });
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final done = mission.complete;
    return KCard(
      color: inSheet ? k.haute : null,
      radius: inSheet ? KRadius.menu : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overline != null) ...[
            Text(overline!, style: KType.micro.copyWith(color: k.texte2)),
            const SizedBox(height: KSpacing.s8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.flag_outlined,
                color: done ? k.validation : k.encre,
                size: KSize.icon,
              ),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Text(
                  mission.title,
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: KSpacing.s8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: KSize.icon,
                  color: k.texte2,
                ),
              ],
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          Text(mission.detail, style: KType.detail.copyWith(color: k.texte2)),
          const SizedBox(height: KSpacing.s12),
          StatsBar(
            value: mission.fraction,
            label: mission.title,
            description: '${mission.current} sur ${mission.target}',
            color: done ? k.validation : null,
          ),
          const SizedBox(height: KSpacing.s8),
          Wrap(
            spacing: KSpacing.s12,
            runSpacing: KSpacing.s4,
            children: [
              Text(
                done
                    ? 'Objectif atteint'
                    : '${mission.current} / ${mission.target}',
                style: KType.micro.copyWith(
                  color: done ? k.validation : k.texte,
                ),
              ),
              Text(
                '+${mission.xp} XP${done ? ' inclus' : ''}',
                style: KType.micro.copyWith(color: k.texte2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Feuille « Défis de la semaine » (Parcours).
void showStatsMissions(BuildContext context) {
  final week = store.progression.week;
  statsSheet(
    context,
    'Défis de la semaine',
    subtitle:
        'Du ${statsDate(week.monday)} au ${statsDate(week.monday.add(const Duration(days: 6)))}',
    [
      for (final mission in week.missions)
        StatsMissionCard(mission, inSheet: true),
      const StatsText(
        'Les bonus sont automatiques. Les jours de repos ne cassent pas ta régularité : deux jours actifs dans la semaine suffisent. Les autres défis restent facultatifs.',
        muted: true,
      ),
    ],
  );
}

/// Parcours (UI3, cahier §4.1) : personnage, arbre des badges (Pratique,
/// Rythme), et seule entrée des feuilles de jeu (défis, campagne, boss,
/// saisons, titres).
class StatsProgression extends StatefulWidget {
  const StatsProgression({super.key});
  @override
  State<StatsProgression> createState() => _StatsProgressionState();
}

class _StatsProgressionState extends State<StatsProgression> {
  int _branch = 0;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final p = store.progression;
    final g = store.game;
    final groups = switch (_branch) {
      0 => const {'sessions': 'Séances', 'sets': 'Séries'},
      _ => const {'streak': 'Semaines régulières'},
    };
    final defeated = g.bosses.where((b) => b.defeated).length;
    final boss = g.nextBoss;
    final season = g.currentSeason;
    return StatsList(
      key: const PageStorageKey('stats-journey-scroll'),
      children: [
        const StatsIntro(
          'Ton arbre de progression',
          lead: 'Plusieurs chemins pour avancer. Chaque palier a son objectif.',
        ),
        Column(
          key: const ValueKey('progress-tree'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KCard(
              key: const ValueKey('stats-character'),
              onTap: () => showCharacterSheet(context),
              child: Row(
                children: [
                  RankInsignia(
                    rankIndex: rankIndexOf(p.rank),
                    prestige: GameState.prestigeOf(p.level),
                    size: KSize.menuIcon,
                  ),
                  const SizedBox(width: KSpacing.s14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Niveau ${p.level} · ${p.rank.title}',
                          style: KType.titreCarte.copyWith(color: k.texte),
                        ),
                        Text(
                          'Ta feuille de personnage · ${p.earnedBadges} / ${p.badges.length} badges obtenus',
                          style: KType.detail.copyWith(color: k.texte2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KSpacing.s8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: KSize.icon,
                    color: k.texte2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KSpacing.s16),
            KSegmented<int>(
              semanticLabel: 'Branche de l’arbre',
              segments: const [
                KSegment(0, 'Pratique'),
                KSegment(1, 'Rythme'),
              ],
              selected: _branch,
              onChanged: (b) => setState(() => _branch = b),
            ),
            const SizedBox(height: KSpacing.s20),
            LayoutBuilder(
              builder: (context, bounds) {
                final columns =
                    groups.length > 1 &&
                        bounds.maxWidth >= 300 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.3
                    ? 2
                    : 1;
                const gap = KSpacing.s12;
                return Wrap(
                  spacing: gap,
                  runSpacing: KSpacing.s24,
                  children: [
                    for (final group in groups.entries)
                      SizedBox(
                        width: (bounds.maxWidth - gap * (columns - 1)) / columns,
                        child: _BadgeChain(
                          title: group.value,
                          badges: p.badges
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
        KMenuGroup(
          title: 'Défis et récompenses',
          children: [
            KMenuRow(
              key: const ValueKey('stats-missions'),
              icon: Icons.flag_outlined,
              title: 'Défis de la semaine',
              subtitle:
                  '${p.week.missions.where((m) => m.complete).length} / ${p.week.missions.length} objectifs atteints · bonus XP automatiques',
              onTap: () => showStatsMissions(context),
            ),
            KMenuRow(
              key: const ValueKey('stats-campaign'),
              icon: Icons.map_outlined,
              title: 'Campagne',
              subtitle: campaignSummary(g),
              onTap: () => showCampaign(context),
            ),
            KMenuRow(
              key: const ValueKey('stats-bosses'),
              icon: Icons.sports_martial_arts_rounded,
              title: 'Boss',
              subtitle: boss == null
                  ? 'Tous vaincus · $defeated / ${g.bosses.length}'
                  : '${boss.name} · ${bossHint(g, boss)}',
              onTap: () => showBosses(context),
            ),
            KMenuRow(
              key: const ValueKey('stats-seasons'),
              icon: Icons.calendar_month_rounded,
              title: 'Saisons',
              subtitle: season == null
                  ? 'Hors programme'
                  : 'Saison ${season.index} · ${season.name} · ${(season.fraction * 100).round()} %',
              onTap: () => showSeasons(context),
            ),
            KMenuRow(
              key: const ValueKey('stats-titles'),
              icon: Icons.workspace_premium_rounded,
              title: 'Tes titres',
              subtitle:
                  '${g.earnedTitles.length} / ${g.titles.length} obtenus · ${store.settings.title.isEmpty ? 'le rang est affiché' : 'affiché : ${store.settings.title}'}',
              onTap: () => showTitles(context),
            ),
          ],
        ),
        const StatsText(
          'Chaque badge rapporte son bonus une seule fois. Ton historique compte déjà dans ces objectifs.',
          muted: true,
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
    final k = KTokens.of(context);
    final next = badges.where((b) => !b.earned).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: KSpacing.s12),
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: KType.section.copyWith(color: k.texte2),
            ),
          ),
        ),
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0)
            Center(
              child: Container(
                width: 2,
                height: KSpacing.s16,
                color: badges[i - 1].earned ? k.validation : k.filet,
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
    final k = KTokens.of(context);
    final status = item.earned
        ? 'Obtenu'
        : next
        ? 'Prochain palier'
        : 'À venir';
    final color = item.earned
        ? k.validation
        : next
        ? k.encre
        : k.texte2;
    return Semantics(
      button: true,
      label:
          '${item.badge.title}. $status. ${item.badge.description}. ${item.current} sur ${item.badge.target}. ${item.badge.xp} XP.',
      onTap: () => _detail(context),
      excludeSemantics: true,
      child: KCard(
        key: ValueKey('badge-${item.badge.id}'),
        onTap: () => _detail(context),
        outline: next ? k.encre : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.earned
                      ? Icons.verified_rounded
                      : next
                      ? Icons.radio_button_checked_rounded
                      : Icons.lock_outline_rounded,
                  color: color,
                  size: KSize.icon,
                ),
                const SizedBox(width: KSpacing.s8),
                Expanded(
                  child: Text(status, style: KType.micro.copyWith(color: color)),
                ),
              ],
            ),
            const SizedBox(height: KSpacing.s8),
            Text(
              item.badge.title,
              style: KType.corpsFort.copyWith(color: k.texte),
            ),
            const SizedBox(height: KSpacing.s8),
            RarityChip(rarityOf(item.badge)),
            const SizedBox(height: KSpacing.s12),
            StatsBar(
              value: item.fraction,
              label: item.badge.description,
              color: item.earned ? k.validation : null,
            ),
            const SizedBox(height: KSpacing.s8),
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  '${item.current.clamp(0, item.badge.target)} / ${item.badge.target}',
                  style: KType.detail.copyWith(color: k.texte2),
                ),
                Text(
                  '+${item.badge.xp} XP',
                  style: KType.micro.copyWith(
                    color: item.earned ? k.validation : k.texte,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _detail(BuildContext context) {
    final status = item.earned
        ? 'Obtenu'
        : next
        ? 'Prochain palier'
        : 'À venir';
    statsSheet(context, item.badge.title, subtitle: status, [
      Builder(
        builder: (context) {
          final k = KTokens.of(context);
          return Row(
            children: [
              Icon(
                item.earned
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_outlined,
                size: KSize.target,
                color: item.earned ? k.validation : k.encre,
              ),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.badge.description,
                      style: KType.corpsFort.copyWith(color: k.texte),
                    ),
                    const SizedBox(height: KSpacing.s4),
                    RarityChip(rarityOf(item.badge)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      StatsBar(
        value: item.fraction,
        label: item.badge.title,
        description: '${item.current} sur ${item.badge.target}',
        color: item.earned ? KTokens.of(context).validation : null,
      ),
      StatsText(
        item.earned
            ? 'Objectif atteint · total actuel : ${item.current}'
            : '${item.current} / ${item.badge.target} · encore ${item.badge.target - item.current} pour ce palier',
      ),
      StatsText(
        item.earned
            ? '+${item.badge.xp} XP déjà inclus dans ton total.'
            : '+${item.badge.xp} XP attribués automatiquement quand l’objectif est atteint.',
      ),
      if (item.badge.metric == 'streak')
        const StatsText(
          'Une semaine est régulière à partir de deux jours actifs. Les repos sont compatibles avec cet objectif.',
          muted: true,
        ),
    ]);
  }
}

/// Feuille « Comprendre les XP » (aide de l'en-tête de Stats).
void showStatsRules(BuildContext context) => statsSheet(
  context,
  'Comprendre les XP',
  subtitle: 'Comment progresser',
  closeLabel: 'Compris',
  const [
    StatsText(
      'Le barème de base est conservé : 100 XP pour une journée du programme validée.',
    ),
    StatsText(
      'Les badges et les objectifs hebdomadaires ajoutent des bonus automatiques. Les objectifs se renouvellent le lundi et leurs bonus passés restent calculés depuis le journal. Deux séances le même jour comptent pour un seul jour actif. Les jours de récupération du programme ne comptent pas comme des entraînements pour ces bonus.',
    ),
    StatsText(
      'Une semaine avec 2 jours actifs prolonge la série de régularité. La semaine en cours peut encore être complétée : elle ne casse pas la série avant le lundi suivant. Aucun entraînement quotidien n’est exigé.',
    ),
    StatsText(
      'Les XP sont recalculés depuis tes données : supprimer une séance retire les XP et bonus associés. Réimporter la même sauvegarde ne double aucune récompense. Les anciennes séances sans date utilisent, si possible, la date prévue du programme.',
      muted: true,
    ),
  ],
);
