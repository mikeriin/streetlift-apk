// G12 — briques d'écran de la progression : pastille de niveau de l'en-tête,
// hexagone des attributs, rang d'un mouvement, carte de quête, présentation
// par Koach d'une nouveauté (D6.4).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../koach/koach_bubble.dart';
import '../store.dart';
import '../store_widget.dart';
import '../ui.dart';
import 'progression_view.dart' show openProgression;
import 'quest_texts.dart';

/// Niveau, prestige et avancement vers le niveau suivant (en-tête de
/// l'accueil). Abonnée au store : elle suit un passage de niveau sans
/// redémarrer l'application.
class LevelPill extends StoreWidget {
  const LevelPill({super.key});
  @override
  Widget build(BuildContext context) {
    final l = store.questLevel;
    final progress = l.xpForNextLevel == 0
        ? 0.0
        : l.xpIntoLevel / l.xpForNextLevel;
    return Semantics(
      button: true,
      label:
          'Niveau ${l.level}${l.prestige > 0 ? ', prestige ${l.prestige}' : ''}',
      value: '${l.xpIntoLevel} sur ${l.xpForNextLevel} XP',
      onTap: () => openProgression(context),
      excludeSemantics: true,
      child: Tooltip(
        message: 'Ouvrir ma progression',
        child: InkWell(
          key: const ValueKey('level-pill'),
          onTap: () => openProgression(context),
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            child: Align(
              widthFactor: 1,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: LevelProgressNumber(
                level: l.level,
                prestige: l.prestige,
                progress: progress,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « NIV. 12 » (+ « P1 » au-delà du niveau 100) et la barre du niveau.
class LevelProgressNumber extends StatelessWidget {
  final int level, prestige;
  final double progress;
  const LevelProgressNumber({
    super.key,
    required this.level,
    required this.progress,
    this.prestige = 0,
  });

  /// Hauteur de barre d'en-tête nécessaire à ce bloc pour une taille de
  /// texte donnée (L5 : le niveau suit la taille de texte du téléphone).
  static double headerHeight(BuildContext context) =>
      math.max(70, MediaQuery.textScalerOf(context).scale(30) + 35);

  @override
  Widget build(BuildContext context) {
    final colors = ProgrammeColors.of(context);
    final label = TextStyle(
      color: colors.muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .8,
    );
    final number = TextStyle(
      color: SL.text,
      fontSize: 30,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final p = prestige > 0 ? 'P$prestige' : '';
    final width = math.max(
      88.0,
      measure('NIV.', label) +
          7 +
          measure('$level', number) +
          (p.isEmpty ? 2 : 6 + measure(p, label) + 2),
    );
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('NIV.', style: label),
              const SizedBox(width: 7),
              Text('$level', style: number),
              if (p.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  p,
                  key: const ValueKey('level-prestige'),
                  style: label.copyWith(color: colors.p.action),
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          KProgressBar(
            value: progress,
            height: 4,
            color: colors.p.action,
            semanticsLabel: 'Progression vers le niveau suivant',
          ),
        ],
      ),
    );
  }
}

/// Hexagone des six attributs : valeur actuelle (surface pleine) et
/// meilleure valeur atteinte (contour).
class AttributeHexagon extends StatelessWidget {
  final List<kc.AttributeScore> scores;
  final double size;
  final bool labels;
  const AttributeHexagon({
    super.key,
    required this.scores,
    this.size = 240,
    this.labels = true,
  });

  double _value(kc.AthleteAttribute a, {bool best = false}) {
    for (final s in scores) {
      if (s.attribute == a) return ((best ? s.best : null) ?? s.value) / 100;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final text = [
      for (final a in kAttributeOrder)
        '${attributeLabel(a)} ${_value(a) * 100 ~/ 1}',
    ].join(', ');
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      label: 'Attributs sur 100 : $text',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _HexPainter(
            values: [for (final a in kAttributeOrder) _value(a)],
            best: [for (final a in kAttributeOrder) _value(a, best: true)],
            labels: labels
                ? [for (final a in kAttributeOrder) attributeLabel(a)]
                : null,
            grid: SL.line,
            fill: SL.accent,
            text: SL.dim,
            scaler: scaler,
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final List<double> values, best;
  final List<String>? labels;
  final Color grid, fill, text;
  final TextScaler scaler;
  _HexPainter({
    required this.values,
    required this.best,
    required this.labels,
    required this.grid,
    required this.fill,
    required this.text,
    required this.scaler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final margin = labels == null ? 4.0 : scaler.scale(11) * 2.6;
    final r = math.max(10.0, size.shortestSide / 2 - margin);
    Offset at(int i, double f) {
      final a = -math.pi / 2 + i * math.pi / 3;
      return c + Offset(math.cos(a), math.sin(a)) * r * f;
    }

    final gridPaint = Paint()
      ..color = grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in const [.25, .5, .75, 1.0]) {
      final path = Path()..moveTo(at(0, f).dx, at(0, f).dy);
      for (var i = 1; i < 6; i++) {
        path.lineTo(at(i, f).dx, at(i, f).dy);
      }
      canvas.drawPath(path..close(), gridPaint);
    }
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(c, at(i, 1), gridPaint);
    }
    Path poly(List<double> v) {
      final p = Path();
      for (var i = 0; i < 6; i++) {
        final o = at(i, v[i].clamp(0.02, 1.0));
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    canvas.drawPath(
      poly(best),
      Paint()
        ..color = text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final value = poly(values);
    canvas.drawPath(value, Paint()..color = fill.withValues(alpha: .28));
    canvas.drawPath(
      value,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    final l = labels;
    if (l == null) return;
    for (var i = 0; i < 6; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: l[i],
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final o = at(i, 1.0) - c;
      final dir = o / o.distance;
      final pos =
          c + o + dir * (tp.height * .9) - Offset(tp.width / 2, tp.height / 2);
      final x = pos.dx.clamp(0.0, math.max(0.0, size.width - tp.width));
      final y = pos.dy.clamp(0.0, math.max(0.0, size.height - tp.height));
      tp.paint(canvas, Offset(x, y));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.values.toString() != values.toString() ||
      old.best.toString() != best.toString() ||
      old.fill != fill ||
      old.text != text ||
      old.grid != grid ||
      old.scaler != scaler;
}

/// Pastille d'un rang : nom écrit (jamais la couleur seule).
class TierBadge extends StatelessWidget {
  final kc.MovementRankTier tier;
  const TierBadge(this.tier, {super.key});

  @override
  Widget build(BuildContext context) {
    final i = kc.MovementRankTier.values.indexOf(tier);
    final icon = i <= 0
        ? Icons.radio_button_unchecked
        : i >= 6
        ? Icons.workspace_premium
        : Icons.military_tech_outlined;
    return KBadge(
      tierLabel(tier),
      icon: icon,
      color: i <= 0 ? SL.dim : SL.accent,
    );
  }
}

/// Carte d'une quête : titre, avancement, récompense, état écrit.
class QuestCard extends StatelessWidget {
  final kc.Quest quest;
  final VoidCallback? onClaim;
  const QuestCard(this.quest, {super.key, this.onClaim});

  @override
  Widget build(BuildContext context) {
    final q = quest;
    final done = q.status == kc.QuestStatus.completed;
    final expired = q.status == kc.QuestStatus.expired;
    final tt = Theme.of(context).textTheme;
    final why = questWhy(q);
    final fraction = q.target <= 0 ? 0.0 : q.progress / q.target;
    return KCard(
      key: ValueKey('quest-${q.id}'),
      accent: done ? SL.success : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10),
                child: Icon(
                  done
                      ? Icons.check_circle_rounded
                      : expired
                      ? Icons.remove_circle_outline
                      : Icons.flag_outlined,
                  color: done ? SL.success : SL.dim,
                  size: 22,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(questTitle(q), style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      [
                        done
                            ? 'Réussie'
                            : expired
                            ? 'Terminée sans être remplie'
                            : questProgressText(q),
                        rewardText(q.rewardXp, q.rewardKredits),
                      ].join(' · '),
                      style: tt.bodySmall?.copyWith(color: SL.dim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!done && !expired && q.params['metric'] != 'claim') ...[
            const SizedBox(height: 10),
            KProgressBar(
              value: fraction,
              height: 5,
              color: SL.accent,
              semanticsLabel: 'Avancement',
              semanticsValue: questProgressText(q),
            ),
          ],
          if (why != null) ...[
            const SizedBox(height: 8),
            Text(why, style: tt.bodySmall?.copyWith(color: SL.dim)),
          ],
          if (onClaim != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: ValueKey('quest-claim-${q.id}'),
                onPressed: onClaim,
                icon: const Icon(Icons.check),
                label: const Text('C’est fait'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Koach présente une nouveauté la première fois (D6.4) ; ensuite rien.
class KoachIntro extends StoreWidget {
  final String code;
  final KoachPose pose;
  final String text;
  final String? why;
  const KoachIntro({
    super.key,
    required this.code,
    required this.pose,
    required this.text,
    this.why,
  });

  @override
  Widget build(BuildContext context) {
    if (store.questIntroSeen(code) || store.questData == null) {
      return const SizedBox.shrink();
    }
    return KoachBubble(
      key: ValueKey('koach-intro-$code'),
      pose: pose,
      text: text,
      why: why,
      koachHeight: 84,
      actions: [
        KoachBubbleAction(
          'Compris',
          () => store.markQuestIntro(code),
          primary: true,
          key: ValueKey('koach-intro-ok-$code'),
        ),
      ],
    );
  }
}
