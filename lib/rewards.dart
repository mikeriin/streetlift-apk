// Écran de récompenses : après une séance validée, les XP gagnés défilent,
// la jauge se remplit (et passe le niveau s'il y a lieu), les bonus
// s'affichent un à un (badge, défi, semaine validée, record),
// puis la cérémonie de niveau montre l'insigne. Une seule passe d'animations
// (aucune boucle infinie), « Réduire les animations » rend tout immédiat, et
// le réglage « Célébrations » remplace l'écran par une simple confirmation.
//
// Toute l'animation suit une chronologie unique qui ne démarre qu'une fois
// l'écran entièrement affiché et l'écran d'origine refermé (séance détruite,
// sauvegarde écrite, onglets reconstruits) : ce travail ne peut plus figer le
// décompte ni le faire sauter à sa valeur finale, qui part toujours de zéro.
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'game.dart';
import 'game_widgets.dart';
import 'progression.dart';
import 'progression_screen.dart';
import 'store.dart';
import 'ui.dart';

/// À appeler après une séance terminée : affiche
/// le bilan en attente, sinon la cérémonie de niveau seule si le niveau a
/// monté (import, suppression…). `after` : fermeture de l'écran d'origine
/// (la séance), que le décompte attend avant de démarrer.
void checkLevelUp(BuildContext context, {Future<void>? after}) {
  final reward = store.consumeReward();
  final up = store.consumeLevelUp();
  if (!context.mounted) return;
  if (reward != null) {
    if (store.settings.celebrations) {
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          fullscreenDialog: true,
          opaque: false,
          transitionDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) =>
              RewardScreen(reward: reward, after: after),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            content: Text(
              '+${reward.xpGained} XP · niveau ${reward.levelAfter}${reward.levelUp ? ' · niveau supérieur' : ''}',
            ),
          ),
        );
    }
    return;
  }
  if (up == null) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          RankInsignia(
            rankIndex: rankIndexOf(store.progression.rank),
            prestige: GameState.prestigeOf(up.to),
            size: 36,
          ),
          const SizedBox(width: 10),
          Text(
            'Niveau ${up.to}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        'Niveau ${up.from} → ${up.to} · ${store.progression.rank.title}.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            openProgression(context);
          },
          child: const Text('Ma progression'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
}

// Chronologie de l'écran, en millisecondes depuis le départ du décompte.
const _countMs = 1100; // XP qui défilent, jauge qui se remplit
const _linesMs = 500; // premier bonus
const _lineStepMs = 110; // bonus suivants
const _ceremonyMs = 1000; // cérémonie de niveau
const _revealMs = 420; // apparition d'un bonus ou de la cérémonie
const _confettiMs = 2600; // une seule descente de confettis

/// Avancement 0-1 (courbe appliquée) de l'étape qui commence à `fromMs` et
/// dure `lengthMs`, dans une chronologie de `totalMs` avancée à `value`.
double _stage(
  double value,
  int totalMs,
  int fromMs,
  int lengthMs, [
  Curve curve = Curves.easeOutCubic,
]) {
  final t = ((value * totalMs - fromMs) / lengthMs).clamp(0.0, 1.0);
  return curve.transform(t);
}

class RewardScreen extends StatefulWidget {
  final RewardSummary reward;

  /// Fermeture de l'écran d'origine (la séance) : le décompte l'attend.
  final Future<void>? after;
  const RewardScreen({super.key, required this.reward, this.after});
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  /// Une seule chronologie : décompte des XP et jauge, bonus un à un,
  /// cérémonie puis confettis.
  late final AnimationController _timeline;
  late final int _totalMs;
  bool _armed = false;

  RewardSummary get r => widget.reward;

  @override
  void initState() {
    super.initState();
    final lines = r.lines.isEmpty
        ? 0
        : _linesMs + _lineStepMs * (r.lines.length - 1) + _revealMs;
    _totalMs = math.max(math.max(_countMs, lines), r.levelUp ? _confettiMs : 0);
    _timeline = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed) return;
    _armed = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _timeline.value = 1;
      _feedback();
      return;
    }
    unawaited(_startWhenSettled(ModalRoute.of(context)?.animation));
  }

  /// Le décompte part une fois cette page entièrement affichée et l'écran
  /// d'origine refermé, puis une image plus tard : la fermeture de la séance
  /// (destruction, sauvegarde, onglets reconstruits en dessous) est terminée
  /// et ne peut plus avaler l'animation.
  Future<void> _startWhenSettled(Animation<double>? entrance) async {
    final after = widget.after;
    // Pendant la première image d'une page poussée, le contrôleur de héros
    // la garde hors scène et fait passer son animation pour terminée : on
    // laisse cette image s'écouler avant de lire l'état réel de l'entrée.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Future.wait<void>([_shown(entrance), if (after != null) after]);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _feedback();
    _timeline.forward();
  }

  /// Fin de la transition d'entrée de cette page : tout de suite si elle est
  /// déjà finie, et aussi si la page repart avant, pour ne rien laisser en
  /// attente.
  static Future<void> _shown(Animation<double>? entrance) {
    final animation = entrance;
    if (animation == null || animation.status == AnimationStatus.completed) {
      return Future<void>.value();
    }
    final shown = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.forward ||
          status == AnimationStatus.reverse) {
        return;
      }
      animation.removeStatusListener(onStatus);
      if (!shown.isCompleted) shown.complete();
    }

    animation.addStatusListener(onStatus);
    return shown.future;
  }

  void _feedback() {
    if (!store.settings.vibration) return;
    if (r.levelUp) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SL.bg.withValues(alpha: .97),
      body: SafeArea(
        child: Stack(
          children: [
            if (r.levelUp)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _timeline,
                    builder: (_, __) => CustomPaint(
                      painter: _ConfettiPainter(
                        _stage(
                          _timeline.value,
                          _totalMs,
                          0,
                          _confettiMs,
                          Curves.linear,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            KList(
              children: [
                const SizedBox(height: 12),
                Text(
                  r.heading.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SL.accent,
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _timeline,
                  builder: (context, _) => _XpMeter(
                    total:
                        r.xpBefore +
                        (r.xpAfter - r.xpBefore) *
                            _stage(_timeline.value, _totalMs, 0, _countMs),
                    reward: r,
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < r.lines.length; i++)
                  _Appear(
                    timeline: _timeline,
                    totalMs: _totalMs,
                    fromMs: _linesMs + _lineStepMs * i,
                    child: _LootLine(r.lines[i]),
                  ),
                if (r.levelUp) ...[
                  const SizedBox(height: 14),
                  _Appear(
                    timeline: _timeline,
                    totalMs: _totalMs,
                    fromMs: _ceremonyMs,
                    scale: true,
                    child: _Ceremony(r),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  key: const ValueKey('reward-continue'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SL.bordeaux,
                    foregroundColor: SL.onBrand,
                    minimumSize: const Size(220, KControl.buttonHeight),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continuer'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openProgression(context);
                  },
                  child: const Text('Ma progression'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// XP en cours de comptage, jauge du niveau atteint à cet instant : quand le
/// total franchit un niveau, la jauge repart et le numéro change.
class _XpMeter extends StatelessWidget {
  final double total;
  final RewardSummary reward;
  const _XpMeter({required this.total, required this.reward});
  @override
  Widget build(BuildContext context) {
    var level = 1;
    while (total >= Progression.xpAtLevel(level + 1)) {
      level++;
    }
    final inLevel = total - Progression.xpAtLevel(level);
    final need = Progression.needFor(level);
    final gained = (total - reward.xpBefore).round();
    final rank = progressRanks.lastWhere((k) => k.level <= level);
    return Column(
      children: [
        Text(
          '+$gained XP',
          key: const ValueKey('reward-xp'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SL.text,
            fontSize: 44,
            height: 1,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              'NIV. $level',
              style: TextStyle(
                color: SL.dim,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${inLevel.round()} / $need XP · ${rank.title}',
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SL.dim,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KProgressBar(
          value: need == 0 ? 0 : inLevel / need,
          height: 8,
          semanticsLabel: 'Progression du niveau',
          semanticsValue: '${inLevel.round()} sur $need XP',
        ),
      ],
    );
  }
}

class _LootLine extends StatelessWidget {
  final RewardLine line;
  const _LootLine(this.line);
  @override
  Widget build(BuildContext context) {
    final icon = switch (line.kind) {
      'badge' => Icons.workspace_premium_rounded,
      'mission' => Icons.flag_rounded,
      'streak' => Icons.local_fire_department_rounded,
      'record' => Icons.emoji_events_rounded,
      'goal' => Icons.track_changes_rounded,
      _ => Icons.fitness_center_rounded,
    };
    final color = switch (line.kind) {
      'record' || 'goal' || 'streak' => SL.success,
      _ => SL.accent,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                line.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (line.xp > 0) ...[
              const SizedBox(width: 8),
              Text(
                '+${line.xp} XP',
                style: TextStyle(
                  color: SL.accent,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Ceremony extends StatelessWidget {
  final RewardSummary r;
  const _Ceremony(this.r);
  @override
  Widget build(BuildContext context) {
    final rank = progressRanks.lastWhere((k) => k.level <= r.levelAfter);
    return KCard(
      key: const ValueKey('reward-ceremony'),
      color: SL.bordeaux,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          RankInsignia(
            rankIndex: rankIndexOf(rank),
            prestige: GameState.prestigeOf(r.levelAfter),
            size: 84,
            light: true,
          ),
          const SizedBox(height: 12),
          Text(
            r.promotion ? 'PROMOTION' : 'NIVEAU SUPÉRIEUR',
            style: TextStyle(
              color: SL.onBrandSoft,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            r.promotion ? rank.title : 'Niveau ${r.levelAfter}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SL.onBrand,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (r.promotion)
            Text(
              'Niveau ${r.levelAfter}',
              style: TextStyle(color: SL.onBrandSoft, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// Apparition en fondu et glissement (échelle optionnelle) à un instant de la
/// chronologie de l'écran : une seule fois, sans minuteur. Un élément révélé
/// plus tard par le défilement s'affiche directement à son état final.
class _Appear extends StatelessWidget {
  final Animation<double> timeline;
  final int totalMs, fromMs;
  final bool scale;
  final Widget child;
  const _Appear({
    required this.timeline,
    required this.totalMs,
    required this.fromMs,
    required this.child,
    this.scale = false,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: timeline,
    builder: (context, child) {
      final t = _stage(timeline.value, totalMs, fromMs, _revealMs);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: scale
              ? Transform.scale(scale: .9 + .1 * t, child: child)
              : child,
        ),
      );
    },
    child: child,
  );
}

/// Confettis dans la charte, une seule descente.
class _ConfettiPainter extends CustomPainter {
  final double t;
  const _ConfettiPainter(this.t);
  // Couleurs de la dominante (décor), lues au dessin.
  static List<Color> get _colors => SL.confetti;
  @override
  void paint(Canvas canvas, Size size) {
    // Les 36 premiers pour cent laissent la jauge se remplir d'abord.
    final t = ((this.t - .36) / .64);
    if (t <= 0 || t >= 1) return;
    final rnd = math.Random(42);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final x0 = rnd.nextDouble() * size.width;
      final drift = (rnd.nextDouble() - .5) * 80;
      final speed = .6 + rnd.nextDouble() * .8;
      final y = -20 + (size.height + 40) * math.min(1, t * speed);
      final x = x0 + drift * t + math.sin((t * 6 + i) * 1.3) * 8;
      final w = 4 + rnd.nextDouble() * 4, h = 6 + rnd.nextDouble() * 6;
      paint.color = _colors[i % _colors.length].withValues(alpha: 1 - t * .6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 4 + i) * .8);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
