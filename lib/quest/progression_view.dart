// G12 (D7, D3.8) — écrans de la progression : niveau et prochain palier,
// série de semaines, quêtes, attributs, rangs par mouvement (standards
// consultables), objectifs (prédiction, jalons, ajustement), Krédits,
// historique des gains (registre d'XP).
//
// Tout vient de `kalis_quest` (store.quest) ; les écrans ne calculent rien
// d'autre que la mise en forme. Koach présente chaque nouveauté la première
// fois (D6.4).
import 'package:flutter/material.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;
import 'package:kalis_quest/kalis_quest.dart' as kq;

import '../app_theme.dart';
import '../athlete_profile.dart' show civilOf, goalText, numText;
import '../athlete_profile_screen.dart' show editAthleteRubric;
import '../koach/flame_icon.dart';
import '../koach/koach_bubble.dart';
import '../stats_navigation.dart';
import '../stats_screen.dart';
import '../store.dart';
import '../store_widget.dart';
import '../ui.dart';
import 'quest_texts.dart';
import 'quest_widgets.dart';

/// Ouvre la progression (onglet STATS › Progression, ou écran seul).
void openProgression(BuildContext context) {
  if (StatsNavigation.open(context, StatsSection.progression)) return;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProgressionScreen()));
}

/// Règles de l'XP (STATS › « Comprendre les XP »).
void showProgressionRules(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => SingleChildScrollView(
    key: const ValueKey('progression-rules'),
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Comment progresser', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text(
          'Une séance faite comme prévue rapporte jusqu’à 100 XP (plus un '
          'petit bonus de combo). Aller plus dur que prévu ne rapporte rien '
          'de plus : une séance allégée par ton bilan et faite en entier '
          'vaut une séance complète.',
        ),
        const SizedBox(height: 10),
        const Text(
          'Chaque semaine close, la régularité rapporte de l’XP, avec une '
          'part pour les jours de repos respectés. Les séances en plus du '
          'programme ne rapportent rien : le repos est récompensé, jamais '
          'puni.',
        ),
        const SizedBox(height: 10),
        const Text(
          'Records, jalons d’objectif et quêtes ajoutent de l’XP et des '
          'Krédits. Une séance faite malgré une douleur déclarée avant la '
          'séance ne rapporte rien.',
        ),
        const SizedBox(height: 10),
        const Text(
          'Chaque gain est écrit une fois et n’est jamais retiré : le niveau '
          'ne redescend jamais, même si tu supprimes une séance. Niveaux 1 à '
          '100, puis prestige.',
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

/// Écran seul (raccourcis hors de la navigation principale).
class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({super.key});
  @override
  Widget build(BuildContext context) => const StatsScreen(
    initialSection: StatsSection.progression,
    standalone: true,
  );
}

kc.CivilDate get _today => civilOf(store.storeClock());

Map<String, Object?> _map(Object? v) =>
    v is Map ? Map<String, Object?>.from(v) : const {};

Map<String, Object?> get _extras => _map(store.quest?.extras);

kc.CivilDate? _parseDay(Object? v) {
  if (v is! String) return null;
  try {
    return kc.CivilDate.parse(v);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

void _push(BuildContext context, Widget page) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => page));

/// Message de Koach quand le moteur ne peut pas tourner.
class _Unavailable extends StatelessWidget {
  const _Unavailable();
  @override
  Widget build(BuildContext context) => KCard(
    key: const ValueKey('progression-unavailable'),
    child: KoachBubble(
      pose: store.questUnreadable ? KoachPose.oops : KoachPose.direction,
      koachHeight: 80,
      text: store.questUnreadable
          ? 'Je n’arrive pas à lire ta progression. Elle est gardée telle '
                'quelle ; rien n’est effacé.'
          : store.questError != null
          ? 'Je n’ai pas pu calculer ta progression cette fois. Tes séances '
                'sont bien enregistrées.'
          : 'Ta progression démarre avec ton profil : crée-le dans '
                'Réglages › Profil, puis fais ta première séance.',
    ),
  );
}

/// « Nouveau départ » (D1.3) : annoncé une fois par Koach.
class QuestResetNotice extends StoreWidget {
  const QuestResetNotice({super.key});
  @override
  Widget build(BuildContext context) {
    if (!store.questResetToAnnounce) return const SizedBox.shrink();
    return KCard(
      key: const ValueKey('quest-reset-notice'),
      child: KoachBubble(
        pose: KoachPose.flag,
        koachHeight: 84,
        text:
            'Nouveau départ : ton entraînement passé reste dans ton '
            'historique, ta progression repart de zéro.',
        why:
            'Le niveau, les quêtes, les attributs et les rangs changent de '
            'système. Tes séances, tes records et tes statistiques ne '
            'bougent pas, et tes records comptent déjà pour tes rangs.',
        actions: [
          KoachBubbleAction(
            'C’est parti',
            store.markQuestResetAnnounced,
            primary: true,
            key: const ValueKey('quest-reset-ok'),
          ),
        ],
      ),
    );
  }
}

/// Contenu de STATS › Progression.
class ProgressionView extends StatelessWidget {
  const ProgressionView({super.key});

  @override
  Widget build(BuildContext context) {
    final o = store.quest;
    final today = _today;
    final children = <Widget>[
      const QuestResetNotice(),
      const KoachIntro(
        code: 'progression',
        pose: KoachPose.progressChart,
        text:
            'Voici ta progression : niveau, quêtes, attributs, rangs et '
            'objectifs. Tout vient de tes vraies séances.',
        why:
            'Tu gagnes de l’XP en faisant tes séances comme prévu (aller '
            'plus dur ne rapporte rien de plus), en gardant tes jours de '
            'repos, avec tes records, tes jalons d’objectif et tes quêtes. '
            'Le niveau ne redescend jamais.',
      ),
      if (o == null) const _Unavailable(),
      const _LevelCard(),
      if (o != null) ...[
        const _StreakCard(),
        KSection(
          'Quêtes du jour',
          actionLabel: 'Toutes',
          onAction: () => _push(context, const QuestsScreen()),
        ),
        ..._todayQuests(context, o, today),
        KMenuTile(
          key: const ValueKey('progression-attributes'),
          icon: Icons.hexagon_outlined,
          title: 'Attributs',
          subtitle: _attributesLine(o),
          onTap: () => _push(context, const AttributesScreen()),
        ),
        KMenuTile(
          key: const ValueKey('progression-ranks'),
          icon: Icons.military_tech_outlined,
          title: 'Rangs par mouvement',
          subtitle: _ranksLine(o),
          onTap: () => _push(context, const RanksScreen()),
        ),
        KMenuTile(
          key: const ValueKey('progression-goals'),
          icon: Icons.flag_outlined,
          title: 'Objectifs',
          subtitle: _goalsLine(),
          onTap: () => _push(context, const GoalsScreen()),
        ),
        KMenuTile(
          key: const ValueKey('progression-kredits'),
          icon: Icons.toll_outlined,
          title: 'Krédits',
          subtitle: 'Solde : ${thousands(o.kreditBalance)}',
          onTap: () => _push(context, const KreditsScreen()),
        ),
        KMenuTile(
          key: const ValueKey('progression-ledger'),
          icon: Icons.receipt_long_outlined,
          title: 'Historique des gains',
          subtitle: 'D’où vient chaque XP',
          onTap: () => _push(context, const LedgerScreen()),
        ),
      ],
    ];
    return KList(
      key: const PageStorageKey('stats-progression-scroll'),
      children: children,
    );
  }

  static List<Widget> _todayQuests(
    BuildContext context,
    kc.QuestOutcome o,
    kc.CivilDate today,
  ) {
    final list = [
      for (final q in o.state.quests)
        if (q.kind == kc.QuestKind.daily && q.startsOn == today) q,
    ];
    if (list.isEmpty) {
      return [
        Text(
          'Pas de quête aujourd’hui.',
          style: TextStyle(color: SL.dim),
        ),
      ];
    }
    return [
      for (final q in list)
        QuestCard(
          q,
          onClaim: store.questClaimable(q)
              ? () => store.questClaim(q.id)
              : null,
        ),
    ];
  }

  static String _attributesLine(kc.QuestOutcome o) {
    if (o.attributes.isEmpty) return 'Force, endurance, puissance…';
    final best = [...o.attributes]..sort((a, b) => b.value.compareTo(a.value));
    final top = best.first;
    return 'Point fort : ${attributeLabel(top.attribute)} '
        '(${top.value.round()}/100)';
  }

  static String _ranksLine(kc.QuestOutcome o) {
    final ranked = [
      for (final r in o.ranks)
        if (r.tier != kc.MovementRankTier.unranked) r,
    ];
    if (ranked.isEmpty) return 'Bronze → Élite, sur des standards publiés';
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return '${plural(ranked.length, 'mouvement')} classé'
        '${ranked.length > 1 ? 's' : ''} · meilleur : '
        '${tierLabel(ranked.first.tier)}';
  }

  static String _goalsLine() {
    final goals = store.athleteProfile?.goals ?? const <kc.Goal>[];
    if (goals.isEmpty) return 'Aucun objectif : crée le tien';
    final done = goals
        .where((g) => store.goalProgressOf(g.id)?.achievedOn != null)
        .length;
    return '${plural(goals.length, 'objectif')}'
        '${done > 0 ? ' · $done atteint${done > 1 ? 's' : ''}' : ''}';
  }
}

class _LevelCard extends StoreWidget {
  const _LevelCard();
  @override
  Widget build(BuildContext context) {
    final l = store.questLevel;
    final tt = Theme.of(context).textTheme;
    final level = _map(_extras['level']);
    final next = _parseDay(level['nextLevelOn']);
    final perWeek = level['xpPerWeek'];
    final remaining = l.xpForNextLevel - l.xpIntoLevel;
    final nextLabel = l.level >= kq.LevelCurve.maxLevel
        ? 'le prestige ${l.prestige + 1}'
        : 'le niveau ${l.level + 1}';
    return KCard(
      key: const ValueKey('progression-level'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Niveau ${l.level}',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (l.prestige > 0)
                KBadge(
                  'Prestige ${l.prestige}',
                  icon: Icons.auto_awesome,
                  color: SL.accent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          KProgressBar(
            value: l.xpForNextLevel == 0
                ? 0
                : l.xpIntoLevel / l.xpForNextLevel,
            height: 8,
            color: SL.accent,
            semanticsLabel: 'XP du niveau',
            semanticsValue:
                '${l.xpIntoLevel} sur ${l.xpForNextLevel} XP',
          ),
          const SizedBox(height: 8),
          Text(
            '${thousands(l.xpIntoLevel)} / ${thousands(l.xpForNextLevel)} XP · '
            'encore ${thousands(remaining)} XP pour $nextLabel',
            style: tt.bodyMedium,
          ),
          if (next != null) ...[
            const SizedBox(height: 4),
            Text(
              'À ton rythme (${perWeek is num ? numText(perWeek.round()) : '…'} '
              'XP par semaine), vers le '
              '${shortCivil(next, today: _today)}.',
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'XP à vie : ${thousands(l.totalXp)}. Le niveau ne redescend '
            'jamais.',
            style: tt.bodySmall?.copyWith(color: SL.dim),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();
  @override
  Widget build(BuildContext context) {
    final s = _map(_extras['streak']);
    final week = _map(s['week']);
    final current = (s['current'] as num?)?.toInt() ?? 0;
    final best = (s['best'] as num?)?.toInt() ?? 0;
    final size = (s['flameSize'] as num?)?.toInt() ?? 0;
    final planned = (week['planned'] as num?)?.toInt() ?? 0;
    final done = (week['done'] as num?)?.toInt() ?? 0;
    final needed = (week['needed'] as num?)?.toInt() ?? 0;
    final tt = Theme.of(context).textTheme;
    return KCard(
      key: const ValueKey('progression-streak'),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 48,
            child: Center(
              child: size <= 0
                  ? Icon(
                      Icons.local_fire_department_outlined,
                      color: SL.dim,
                      size: 32,
                    )
                  : FlameIcon(
                      size.clamp(1, 10),
                      size: 22 + 2.4 * size,
                      semantics: false,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current == 0
                      ? 'Série de semaines : à lancer'
                      : 'Série : ${plural(current, 'semaine')} réussie'
                            '${current > 1 ? 's' : ''}',
                  style: tt.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  planned == 0
                      ? 'Pas de séance prévue cette semaine.'
                      : 'Cette semaine : $done / $needed séance'
                            '${needed > 1 ? 's' : ''} pour la réussir '
                            '($planned prévue${planned > 1 ? 's' : ''}).'
                            '${best > current ? ' Meilleure série : $best.' : ''}',
                  style: tt.bodySmall?.copyWith(color: SL.dim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ quêtes

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Quêtes')),
    body: StoreBuilder(
      builder: (context) {
        final o = store.quest;
        if (o == null) return const KList(children: [_Unavailable()]);
        final today = _today;
        final active = [
          for (final q in o.state.quests)
            if (q.status == kc.QuestStatus.active || q.startsOn == today) q,
        ];
        List<kc.Quest> of(kc.QuestKind k) => [
          for (final q in active)
            if (q.kind == k) q,
        ];
        final recent = [
          for (final q in o.state.quests.reversed)
            if (q.status == kc.QuestStatus.completed && !active.contains(q))
              q,
        ].take(10).toList();
        Widget card(kc.Quest q) => QuestCard(
          q,
          onClaim: store.questClaimable(q) ? () => store.questClaim(q.id) : null,
        );
        return KList(
          key: const ValueKey('quests-screen'),
          children: [
            const KoachIntro(
              code: 'quests',
              pose: KoachPose.checklist,
              text:
                  'Chaque jour, une ou deux quêtes courtes ; chaque semaine, '
                  'deux autres ; et la campagne suit les blocs de ton '
                  'programme.',
              why:
                  'Un jour de repos ne propose que de la récupération, et '
                  'aucune quête ne demande plus que ton programme. Une quête '
                  'non remplie disparaît simplement, sans rien te coûter.',
            ),
            for (final k in const [
              kc.QuestKind.daily,
              kc.QuestKind.weekly,
              kc.QuestKind.koach,
              kc.QuestKind.campaign,
            ])
              if (of(k).isNotEmpty) ...[
                KSection(switch (k) {
                  kc.QuestKind.daily => 'Aujourd’hui',
                  kc.QuestKind.weekly => 'Cette semaine',
                  kc.QuestKind.koach => 'Quête de Koach',
                  kc.QuestKind.campaign => 'Campagne',
                }),
                for (final q in of(k)) card(q),
              ],
            if (active.isEmpty)
              Text(
                'Pas de quête en cours.',
                style: TextStyle(color: SL.dim),
              ),
            if (recent.isNotEmpty) ...[
              const KSection('Réussies récemment'),
              for (final q in recent) QuestCard(q),
            ],
          ],
        );
      },
    ),
  );
}

// ============================================================= attributs

class AttributesScreen extends StatelessWidget {
  const AttributesScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Attributs')),
    body: StoreBuilder(
      builder: (context) {
        final o = store.quest;
        if (o == null) return const KList(children: [_Unavailable()]);
        kc.AttributeScore? of(kc.AthleteAttribute a) {
          for (final s in o.attributes) {
            if (s.attribute == a) return s;
          }
          return null;
        }

        final width = MediaQuery.sizeOf(context).width;
        return KList(
          key: const ValueKey('attributes-screen'),
          children: [
            const KoachIntro(
              code: 'attributes',
              pose: KoachPose.analyze,
              text:
                  'Tes six attributs, de 1 à 100, viennent de tes vraies '
                  'performances. Le contour montre ta meilleure valeur.',
              why:
                  'Une performance compte entière pendant 3 semaines, puis '
                  'un peu moins chaque semaine : la valeur suit ton niveau '
                  'actuel, la meilleure valeur reste.',
            ),
            Center(
              child: AttributeHexagon(
                key: const ValueKey('attribute-hexagon'),
                scores: o.attributes,
                size: (width - 32).clamp(200.0, 320.0),
              ),
            ),
            for (final a in kAttributeOrder)
              _AttributeRow(attribute: a, score: of(a)),
          ],
        );
      },
    ),
  );
}

class _AttributeRow extends StatelessWidget {
  final kc.AthleteAttribute attribute;
  final kc.AttributeScore? score;
  const _AttributeRow({required this.attribute, required this.score});

  @override
  Widget build(BuildContext context) {
    final v = score?.value ?? 0;
    final best = score?.best ?? v;
    final tt = Theme.of(context).textTheme;
    return KCard(
      key: ValueKey('attribute-${attribute.code}'),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) => SingleChildScrollView(
          key: ValueKey('attribute-sheet-${attribute.code}'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${attributeLabel(attribute)} : ${numText(v.round())}/100',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Meilleure valeur atteinte : ${numText(best.round())}/100',
                style: TextStyle(color: SL.dim),
              ),
              const SizedBox(height: 14),
              Text('D’où vient la valeur', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(attributeSource(attribute)),
              const SizedBox(height: 14),
              Text('Comment la faire monter', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(attributeHow(attribute)),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(attributeLabel(attribute), style: tt.titleSmall),
              ),
              Text(
                '${numText(v.round())}/100',
                style: tt.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: SL.dim, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          KProgressBar(
            value: v / 100,
            height: 6,
            color: SL.accent,
            semanticsLabel: attributeLabel(attribute),
            semanticsValue: '${v.round()} sur 100',
          ),
          if (best > v + .5) ...[
            const SizedBox(height: 4),
            Text(
              'Meilleure valeur : ${numText(best.round())}',
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================= rangs

class RanksScreen extends StatelessWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Rangs')),
    body: StoreBuilder(
      builder: (context) {
        final o = store.quest;
        if (o == null) return const KList(children: [_Unavailable()]);
        final details = _map(_extras['ranks']);
        final rankOf = _map(_extras['rankOf']);
        final mine = <String>{
          for (final v in rankOf.values) '$v',
          for (final r in o.ranks)
            if (r.tier != kc.MovementRankTier.unranked) r.exerciseId,
        };
        int order(kc.MovementRank a, kc.MovementRank b) =>
            b.score.compareTo(a.score);
        final first = [
          for (final r in o.ranks)
            if (mine.contains(r.exerciseId)) r,
        ]..sort(order);
        final others = [
          for (final r in o.ranks)
            if (!mine.contains(r.exerciseId)) r,
        ];
        return KList(
          key: const ValueKey('ranks-screen'),
          children: [
            const KoachIntro(
              code: 'ranks',
              pose: KoachPose.flex,
              text:
                  'Ton rang sur chaque mouvement de référence, de Bronze à '
                  'Élite, selon ton sexe et ton poids de corps. Un rang '
                  'acquis ne redescend jamais.',
              why:
                  'Les seuils viennent de standards publiés (Strength Level, '
                  'Running Level) et d’échelles de progressions pour les '
                  'figures. Ils n’ont pas été relus par un professionnel.',
            ),
            if (first.isNotEmpty) ...[
              const KSection('Tes mouvements'),
              for (final r in first) _RankRow(r, _map(details[r.exerciseId])),
            ],
            if (others.isNotEmpty) ...[
              const KSection('Autres mouvements de référence'),
              for (final r in others) _RankRow(r, _map(details[r.exerciseId])),
            ],
            OutlinedButton.icon(
              key: const ValueKey('ranks-standards'),
              onPressed: () => _push(context, const StandardsScreen()),
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Voir les standards'),
            ),
          ],
        );
      },
    ),
  );
}

class _RankRow extends StatelessWidget {
  final kc.MovementRank rank;
  final Map<String, Object?> detail;
  const _RankRow(this.rank, this.detail);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final measure = '${detail['measure'] ?? ''}';
    final value = detail['value'];
    final nextValue = detail['nextValue'];
    final nextEx = detail['nextExerciseId'];
    final next = nextTier(rank.tier);
    String gap = '';
    if (next != null && nextValue is num) {
      if (value is num) {
        final d = measure == 'run' ? value - nextValue : nextValue - value;
        if (d > 0) {
          gap = 'Encore ${rankValueText(measure == 'run' ? 'hold' : measure, d)}'
              '${measure == 'run' ? ' de moins sur 5 km' : ''} pour '
              '${tierLabel(next)} (${rankValueText(measure, nextValue)}).';
        }
      } else {
        gap = '${tierLabel(next)} : ${rankValueText(measure, nextValue)}.';
      }
    } else if (next != null && nextEx != null) {
      gap = '${tierLabel(next)} : tenir ${questExercise(nextEx)}.';
    }
    final valueText = value is num
        ? 'Meilleure performance : ${rankValueText(measure, value)}'
              '${detail['valueExerciseId'] != null && detail['valueExerciseId'] != rank.exerciseId ? ' (${questExercise(detail['valueExerciseId'])})' : ''}'
        : 'Pas encore de performance mesurée';
    final fraction = rank.score - rank.score.floor();
    return KCard(
      key: ValueKey('rank-${rank.exerciseId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  questExercise(rank.exerciseId),
                  style: tt.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              TierBadge(rank.tier),
            ],
          ),
          const SizedBox(height: 6),
          Text(valueText, style: tt.bodySmall),
          if (next != null) ...[
            const SizedBox(height: 8),
            KProgressBar(
              value: rank.tier == kc.MovementRankTier.unranked
                  ? rank.score.clamp(0.0, 1.0)
                  : fraction,
              height: 5,
              color: SL.accent,
              semanticsLabel: 'Vers ${tierLabel(next)}',
            ),
          ],
          if (gap.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(gap, style: tt.bodySmall?.copyWith(color: SL.dim)),
          ],
        ],
      ),
    );
  }
}

/// Standards de rang, pour le sexe et le poids de corps du profil.
class StandardsScreen extends StatelessWidget {
  const StandardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = store.athleteProfile;
    final catalog = store.content.catalog;
    final sex = profile?.sex ?? kc.Sex.undisclosed;
    final bw = profile?.bodyWeightKg ?? 70;
    final book = catalog == null || profile == null
        ? null
        : ka.ExerciseBook(catalog, profile);
    final tiers = kc.MovementRankTier.values.skip(1).toList();
    final tt = Theme.of(context).textTheme;
    return KScreen(
      appBar: AppBar(title: const Text('Standards')),
      body: KList(
        key: const ValueKey('standards-screen'),
        children: [
          Text(
            'Seuils de chaque rang pour '
            '${switch (sex) {
              kc.Sex.male => 'un homme',
              kc.Sex.female => 'une femme',
              kc.Sex.undisclosed => 'toi (moyenne des deux tables)',
            }} de ${numText(bw)} kg. Charge : charge ajoutée sur 1 '
            'répétition (« aide » : élastique ou machine). Sources : '
            'Strength Level, Running Level, échelles de progressions '
            '(détail dans la documentation du moteur). Non relus par un '
            'professionnel.',
            style: tt.bodySmall?.copyWith(color: SL.dim),
          ),
          for (final m in kq.Standards.movements)
            KCard(
              key: ValueKey('standard-${m.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(questExercise(m.id), style: tt.titleSmall),
                  const SizedBox(height: 6),
                  if (m.measure == kq.RankMeasure.hold)
                    for (var i = 0; i < m.rungs.length && i < tiers.length; i++)
                      Text(
                        '${tierLabel(tiers[i])} : '
                        '${m.rungs[i].exerciseIds.map(questExercise).join(' ou ')}'
                        ', ${rankValueText('hold', m.rungs[i].seconds)}',
                        style: tt.bodySmall,
                      )
                  else
                    ...() {
                      final f = book?.find(m.id)?.fraction ??
                          kq.Standards.defaultFraction;
                      final t = kq.Standards.thresholds(m, sex, bw, f);
                      return [
                        for (var i = 0; i < t.length && i < tiers.length; i++)
                          Text(
                            '${tierLabel(tiers[i])} : ${switch (m.measure) {
                              kq.RankMeasure.load => rankValueText('load', t[i] - f * bw),
                              kq.RankMeasure.reps => rankValueText('reps', t[i].ceil()),
                              kq.RankMeasure.run => rankValueText('run', (kq.Standards.runMeters / t[i]).round()),
                              kq.RankMeasure.hold => '',
                            }}',
                            style: tt.bodySmall,
                          ),
                      ];
                    }(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================= objectifs

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Objectifs')),
    body: StoreBuilder(
      builder: (context) {
        final goals = store.athleteProfile?.goals ?? const <kc.Goal>[];
        final suggestions = store.questSuggestedGoals;
        final today = _today;
        return KList(
          key: const ValueKey('goals-screen'),
          children: [
            const KoachIntro(
              code: 'goals',
              pose: KoachPose.flag,
              text:
                  'Tes objectifs, avec des jalons et une date probable '
                  'd’atteinte calculée sur tes progrès.',
              why:
                  'La date est une estimation, pas une promesse : elle bouge '
                  'avec tes séances. Si un objectif prend du retard, je te '
                  'propose une autre date ou une autre cible.',
            ),
            if (store.quest == null) const _Unavailable(),
            if (goals.isEmpty)
              Text(
                'Aucun objectif pour l’instant.',
                style: TextStyle(color: SL.dim),
              ),
            for (var i = 0; i < goals.length; i++)
              _GoalCard(goal: goals[i], main: i == 0, today: today),
            FilledButton.tonalIcon(
              key: const ValueKey('goals-edit'),
              onPressed: () => editAthleteRubric(context, 'goals'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                goals.isEmpty ? 'Créer un objectif' : 'Créer ou modifier',
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const KSection('Koach te propose'),
              for (var i = 0; i < suggestions.length; i++)
                KCard(
                  key: ValueKey('goal-suggested-$i'),
                  child: KoachBubble(
                    pose: KoachPose.idea,
                    koachHeight: 64,
                    text: goalText(suggestions[i], questExercise),
                    why:
                        'D’après tes progrès sur cet exercice : une cible '
                        'que tu atteins avec au moins 6 chances sur 10 à '
                        'ton rythme actuel.',
                    actions: [
                      KoachBubbleAction(
                        'Ajouter',
                        () {
                          if (store.addSuggestedGoal(suggestions[i])) {
                            showKoachToast(context, 'Objectif ajouté.');
                          }
                        },
                        primary: true,
                        key: ValueKey('goal-suggested-add-$i'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );
}

class _GoalCard extends StatelessWidget {
  final kc.Goal goal;
  final bool main;
  final kc.CivilDate today;
  const _GoalCard({required this.goal, required this.main, required this.today});

  @override
  Widget build(BuildContext context) {
    final p = store.goalProgressOf(goal.id);
    final tt = Theme.of(context).textTheme;
    final milestones = p?.milestones ?? const <kc.Milestone>[];
    final reached = milestones.where((m) => m.reachedOn != null).length;
    return KCard(
      key: ValueKey('goal-card-${goal.id}'),
      accent: main ? SL.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              main ? 'Objectif principal' : 'Objectif',
              if (goal.origin == kc.GoalOrigin.suggested) 'proposé par Koach',
            ].join(' · ').toUpperCase(),
            style: TextStyle(
              color: SL.dim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 4),
          Text(goalText(goal, questExercise), style: tt.titleSmall),
          if (p != null) ...[
            const SizedBox(height: 10),
            KProgressBar(
              value: p.fraction,
              height: 6,
              color: p.achievedOn != null ? SL.success : SL.accent,
              semanticsLabel: 'Avancement de l’objectif',
              semanticsValue: '${(p.fraction * 100).round()} %',
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (goal.kind == kc.GoalKind.habit)
                  '${numText(p.current.round())} / ${numText(p.target.round())} séances'
                else
                  'Aujourd’hui : ${goalValueText(goal, p.current)}'
                      '${p.baseline != null ? ' (départ : ${goalValueText(goal, p.baseline!)})' : ''}',
                if (milestones.isNotEmpty)
                  'jalons : $reached / ${milestones.length}',
              ].join(' · '),
              style: tt.bodySmall,
            ),
            if (milestones.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < milestones.length; i++)
                    Expanded(
                      child: Semantics(
                        label:
                            'Jalon ${i + 1} : ${milestones[i].reachedOn == null ? 'pas encore' : 'atteint'}',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            milestones[i].reachedOn == null
                                ? Icons.radio_button_unchecked
                                : Icons.check_circle,
                            size: 18,
                            color: milestones[i].reachedOn == null
                                ? SL.dim
                                : SL.success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              predictionText(goal, p, today),
              key: ValueKey('goal-prediction-${goal.id}'),
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
            if (p.overdue == true && p.achievedOn == null) ...[
              const SizedBox(height: 10),
              KoachBubble(
                key: ValueKey('goal-late-${goal.id}'),
                pose: KoachPose.think,
                koachHeight: 64,
                text:
                    'À ton rythme actuel, ce sera plus long que prévu. Je te '
                    'propose d’ajuster :',
                actions: [
                  if (p.suggestedDate != null)
                    KoachBubbleAction(
                      'Viser le ${shortCivil(p.suggestedDate!, today: today)}',
                      () {
                        if (store.adjustGoal(goal.id, date: p.suggestedDate)) {
                          showKoachToast(context, 'Échéance ajustée.');
                        }
                      },
                      primary: true,
                      key: ValueKey('goal-adjust-date-${goal.id}'),
                    ),
                  if (p.suggestedTarget != null)
                    KoachBubbleAction(
                      'Viser ${goalValueText(goal, p.suggestedTarget!)}',
                      () {
                        if (store.adjustGoal(
                          goal.id,
                          target: p.suggestedTarget,
                        )) {
                          showKoachToast(context, 'Cible ajustée.');
                        }
                      },
                      primary: p.suggestedDate == null,
                      key: ValueKey('goal-adjust-target-${goal.id}'),
                    ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Avancement calculé après ta prochaine séance.',
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
          ],
        ],
      ),
    );
  }
}

// ================================================================ Krédits

class KreditsScreen extends StatelessWidget {
  const KreditsScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Krédits')),
    body: StoreBuilder(
      builder: (context) {
        final o = store.quest;
        if (o == null) return const KList(children: [_Unavailable()]);
        final entries = o.state.kredits.reversed.take(200).toList();
        final tt = Theme.of(context).textTheme;
        return KList(
          key: const ValueKey('kredits-screen'),
          children: [
            KCard(
              key: const ValueKey('kredits-balance'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${thousands(o.kreditBalance)} Krédits',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const KoachBubble(
                    pose: KoachPose.wave,
                    koachHeight: 64,
                    text: 'Garde-les, ils serviront bientôt.',
                    why:
                        'Les Krédits se gagnent avec les quêtes, les '
                        'coffres surprises, les niveaux, les jalons et les '
                        'records. Ils ne s’achètent pas et ne se perdent '
                        'jamais.',
                  ),
                ],
              ),
            ),
            const KSection('Historique'),
            if (entries.isEmpty)
              Text('Aucun Krédit pour l’instant.', style: TextStyle(color: SL.dim)),
            for (final e in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(kreditSourceLabel(e.source)),
                subtitle: Text(shortCivil(e.date, today: _today)),
                trailing: Text(
                  '+${e.amount}',
                  style: tt.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

// ================================================== historique des gains

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('Historique des gains')),
    body: StoreBuilder(
      builder: (context) {
        final o = store.quest;
        if (o == null) return const KList(children: [_Unavailable()]);
        final tt = Theme.of(context).textTheme;
        final today = _today;
        final rows = <Widget>[];
        kc.CivilDate? day;
        var shown = 0;
        for (final e in o.state.xp.reversed) {
          if (shown >= 300) break;
          if (e.amount == 0 &&
              !e.reasons.any(
                (r) =>
                    r.code == 'quest.no_reward_pain' ||
                    r.code == 'quest.xp_capped',
              )) {
            continue;
          }
          if (day != e.date) {
            day = e.date;
            rows.add(KSection(shortCivil(e.date, today: today)));
          }
          rows.add(
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(xpEntryText(e)),
              subtitle: Text(xpSourceLabel(e.source)),
              trailing: Text(
                '+${thousands(e.amount)} XP',
                style: tt.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
          shown++;
        }
        return KList(
          key: const ValueKey('ledger-screen'),
          gap: 0,
          children: [
            Text(
              'Chaque gain est écrit une fois et n’est jamais retiré, même '
              'si une séance est supprimée ensuite.',
              style: tt.bodySmall?.copyWith(color: SL.dim),
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Pas encore de gain : fais ta première séance.',
                  style: TextStyle(color: SL.dim),
                ),
              ),
            ...rows,
          ],
        );
      },
    ),
  );
}
