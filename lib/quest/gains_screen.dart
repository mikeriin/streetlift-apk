// G12 — écran de gains de fin de séance (nouvelle version de l'écran de
// récompenses) : XP par origine, quêtes réussies, Krédits, records et
// événements du moteur de progression, passage de niveau.
//
// Une seule passe d'animation (aucune boucle), qui ne démarre qu'une fois
// l'écran de la séance refermé ; « Réduire les animations » rend tout
// immédiat ; le réglage « Célébrations » remplace l'écran par un message
// court.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../koach/koach_bubble.dart';
import '../store.dart';
import '../ui.dart';
import 'progression_view.dart' show openProgression;
import 'quest_texts.dart';

/// À appeler après une séance terminée : affiche les gains en attente.
/// [after] : fermeture de l'écran d'origine (la séance), que l'animation
/// attend avant de démarrer.
void showGains(BuildContext context, {Future<void>? after}) {
  final gains = store.consumeGains();
  if (gains == null || !context.mounted) return;
  if (!store.settings.celebrations) {
    showKoachToast(context, gainsShortText(gains));
    return;
  }
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      fullscreenDialog: true,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => GainsScreen(gains: gains, after: after),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// Message court (célébrations coupées).
String gainsShortText(QuestGains g) {
  if (g.painNoReward) {
    return 'Séance enregistrée. Pas de gain cette fois : la douleur passe '
        'd’abord.';
  }
  return [
    '+${thousands(g.xp)} XP',
    if (g.kredits > 0) '+${g.kredits} Krédits',
    g.levelUp ? 'niveau ${g.after.level} !' : 'niveau ${g.after.level}',
  ].join(' · ');
}

class GainsScreen extends StatefulWidget {
  final QuestGains gains;
  final Future<void>? after;
  const GainsScreen({super.key, required this.gains, this.after});

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    // Une seule passe, après la fermeture de la séance.
    final after = widget.after ?? Future<void>.value();
    after.whenComplete(() {
      if (!mounted) return;
      if (widget.gains.levelUp && store.settings.vibration) {
        HapticFeedback.mediumImpact();
      }
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _at(double from, double to) => CurvedAnimation(
    parent: _c,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  Widget _appear(double from, Widget child) => FadeTransition(
    opacity: _at(from, (from + .2).clamp(0.0, 1.0)),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final g = widget.gains;
    final tt = Theme.of(context).textTheme;
    final sources = [
      for (final s in kc.XpSource.values)
        if ((g.xpBySource[s] ?? 0) > 0) s,
    ];
    final events = [
      for (final e in g.events)
        if (eventText(e) != null) e,
    ];
    final koach = _koachLine(g);
    final children = <Widget>[
      Text(
        g.painNoReward ? 'Séance enregistrée' : 'Séance validée',
        textAlign: TextAlign.center,
        style: tt.titleLarge,
      ),
      const SizedBox(height: 8),
      AnimatedBuilder(
        animation: _at(0, .45),
        builder: (context, _) {
          final v = (g.xp * _at(0, .45).value).round();
          return Semantics(
            label: '${g.xp} XP gagnés',
            excludeSemantics: true,
            child: Text(
              '+${thousands(v)} XP',
              key: const ValueKey('gains-xp'),
              textAlign: TextAlign.center,
              style: tt.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: SL.accent,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      _LevelBar(gains: g, progress: _at(.1, .6)),
      const SizedBox(height: 16),
      _appear(
        .35,
        KoachBubble(
          key: const ValueKey('gains-koach'),
          pose: koach.pose,
          koachHeight: 84,
          text: koach.text,
        ),
      ),
      if (sources.isNotEmpty) ...[
        const SizedBox(height: 12),
        const KSection('XP gagnés', topPadding: 4),
        for (var i = 0; i < sources.length; i++)
          _appear(
            .45 + i * .06,
            _Line(
              key: ValueKey('gains-source-${sources[i].code}'),
              icon: Icons.bolt_rounded,
              text: xpSourceLabel(sources[i]),
              value: '+${thousands(g.xpBySource[sources[i]]!)} XP',
            ),
          ),
      ],
      if (g.quests.isNotEmpty) ...[
        const SizedBox(height: 8),
        const KSection('Quêtes réussies', topPadding: 4),
        for (final q in g.quests)
          _appear(
            .65,
            _Line(
              key: ValueKey('gains-quest-${q.id}'),
              icon: Icons.check_circle_rounded,
              iconColor: SL.success,
              text: questTitle(q),
              value: rewardText(q.rewardXp, q.rewardKredits),
            ),
          ),
      ],
      if (events.isNotEmpty) ...[
        const SizedBox(height: 8),
        const KSection('À retenir', topPadding: 4),
        for (final e in events)
          _appear(
            .72,
            _Line(
              icon: switch (e.kind) {
                kc.DelightKind.record => Icons.emoji_events_rounded,
                kc.DelightKind.chest => Icons.redeem_rounded,
                kc.DelightKind.rankUp => Icons.military_tech_rounded,
                kc.DelightKind.levelUp => Icons.trending_up_rounded,
                _ => Icons.star_rounded,
              },
              text: eventText(e)!,
            ),
          ),
      ],
      if (g.kredits > 0)
        _appear(
          .8,
          _Line(
            key: const ValueKey('gains-kredits'),
            icon: Icons.toll_rounded,
            text: 'Krédits',
            value: '+${g.kredits}',
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        key: const ValueKey('gains-continue'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Continuer'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const ValueKey('gains-progression'),
        onPressed: () {
          final nav = Navigator.of(context);
          nav.pop();
          openProgression(nav.context);
        },
        child: const Text('Voir ma progression'),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const ValueKey('gains-screen'),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  ({KoachPose pose, String text}) _koachLine(QuestGains g) {
    if (g.painNoReward) {
      return (
        pose: KoachPose.heart,
        text:
            'Ta séance est bien enregistrée. Pas de gain cette fois : tu '
            'avais signalé une douleur avant de commencer, et elle passe '
            'd’abord.',
      );
    }
    if (g.levelUp) {
      return (
        pose: KoachPose.victory,
        text: g.after.prestige > g.before.prestige
            ? 'Prestige ${g.after.prestige} ! Tu repars au niveau 1, avec '
                  'tout ton XP gardé.'
            : 'Niveau ${g.after.level} ! Continue comme ça, à ton rythme.',
      );
    }
    switch (g.cappedScope) {
      case 'week':
        return (
          pose: KoachPose.think,
          text:
              'Séance en plus de ton programme : elle compte dans ton '
              'historique, sans XP. Le repos fait aussi partie du progrès.',
        );
      case 'partial':
        return (
          pose: KoachPose.thumbsUp,
          text: 'Séance écourtée : elle compte pour ce que tu as fait.',
        );
    }
    return (
      pose: KoachPose.cheer,
      text: 'Bien joué ! Chaque séance faite comme prévu te fait avancer.',
    );
  }
}

class _LevelBar extends StatelessWidget {
  final QuestGains gains;
  final Animation<double> progress;
  const _LevelBar({required this.gains, required this.progress});

  @override
  Widget build(BuildContext context) {
    final b = gains.before, a = gains.after;
    final from = gains.levelUp || b.xpForNextLevel == 0
        ? 0.0
        : b.xpIntoLevel / b.xpForNextLevel;
    final to = a.xpForNextLevel == 0 ? 0.0 : a.xpIntoLevel / a.xpForNextLevel;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          gains.levelUp
              ? 'Niveau ${b.level} → ${a.level}'
                    '${a.prestige > 0 ? ' · prestige ${a.prestige}' : ''}'
              : 'Niveau ${a.level}'
                    '${a.prestige > 0 ? ' · prestige ${a.prestige}' : ''}',
          key: const ValueKey('gains-level'),
          textAlign: TextAlign.center,
          style: tt.titleMedium,
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: progress,
          builder: (context, _) => KProgressBar(
            value: from + (to - from) * progress.value,
            height: 8,
            color: SL.accent,
            semanticsLabel: 'XP du niveau',
            semanticsValue: '${a.xpIntoLevel} sur ${a.xpForNextLevel} XP',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${thousands(a.xpIntoLevel)} / ${thousands(a.xpForNextLevel)} XP',
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: SL.dim),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String text;
  final String? value;
  const _Line({
    super.key,
    required this.icon,
    required this.text,
    this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? SL.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
        if (value != null) ...[
          const SizedBox(width: 10),
          Text(
            value!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    ),
  );
}
