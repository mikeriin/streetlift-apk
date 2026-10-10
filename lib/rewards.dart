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

import 'adapt/widgets/session_kit.dart' show showKChoice;
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
      // Message court du kit (réglage « Célébrations » coupé).
      showKSnack(
        context,
        message:
            '+${reward.xpGained} XP · niveau ${reward.levelAfter}${reward.levelUp ? ' · niveau supérieur' : ''}',
        duration: const Duration(seconds: 3),
      );
    }
    return;
  }
  if (up == null) return;
  // Confirmation du kit (zone UI2) : insigne et phrase, « Ma progression »
  // ouvre la même page qu'avant, « Continuer » referme.
  showKChoice(
    context,
    title: 'Niveau ${up.to}',
    body: Row(
      children: [
        RankInsignia(
          rankIndex: rankIndexOf(store.progression.rank),
          prestige: GameState.prestigeOf(up.to),
          size: 36,
        ),
        const SizedBox(width: KSpacing.s12),
        Expanded(
          child: Text(
            'Niveau ${up.from} → ${up.to} · ${store.progression.rank.title}.',
          ),
        ),
      ],
    ),
    confirmLabel: 'Ma progression',
    cancelLabel: 'Continuer',
  ).then((open) {
    if (open && context.mounted) openProgression(context);
  });
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
    final k = KTokens.of(context);
    return Scaffold(
      backgroundColor: k.fond.withValues(alpha: .97),
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
                        // Couleurs de la palette (décor), lues au dessin.
                        [k.pleine, k.encre, k.accent, k.second],
                      ),
                    ),
                  ),
                ),
              ),
            KList(
              children: [
                const SizedBox(height: KSpacing.s12),
                // Surtitre de réussite (`accent`), capitales du système (U3).
                Text(
                  r.heading,
                  textAlign: TextAlign.center,
                  style: KType.section.copyWith(color: k.accent),
                ),
                const SizedBox(height: KSpacing.s8),
                Semantics(
                  header: true,
                  child: Text(
                    k.title(_place(r.title)),
                    textAlign: TextAlign.center,
                    style: k.titleStyle(
                      KType.titreEcran.copyWith(color: k.texte),
                    ),
                  ),
                ),
                const SizedBox(height: KSpacing.s20),
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
                const SizedBox(height: KSpacing.s20),
                for (var i = 0; i < r.lines.length; i++)
                  _Appear(
                    timeline: _timeline,
                    totalMs: _totalMs,
                    fromMs: _linesMs + _lineStepMs * i,
                    child: _LootLine(r.lines[i]),
                  ),
                if (r.levelUp) ...[
                  const SizedBox(height: KSpacing.s14),
                  _Appear(
                    timeline: _timeline,
                    totalMs: _totalMs,
                    fromMs: _ceremonyMs,
                    scale: true,
                    child: _Ceremony(r),
                  ),
                ],
                const SizedBox(height: KSpacing.s24),
                // C2 : un seul bouton plein, l'action secondaire en tonal.
                KPrimaryButton(
                  key: const ValueKey('reward-continue'),
                  label: 'Continuer',
                  onPressed: () => Navigator.pop(context),
                ),
                KTonalButton(
                  label: 'Ma progression',
                  expand: true,
                  onPressed: () {
                    Navigator.pop(context);
                    openProgression(context);
                  },
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
    final rank = progressRanks.lastWhere((r) => r.level <= level);
    final k = KTokens.of(context);
    return Column(
      children: [
        // Chiffre mis en avant (`encre`, lisible sur le fond de la page).
        Text(
          '+$gained XP',
          key: const ValueKey('reward-xp'),
          textAlign: TextAlign.center,
          style: KType.chiffre.copyWith(color: k.encre),
        ),
        const SizedBox(height: KSpacing.s14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Niveau $level',
              style: KType.micro.copyWith(
                color: k.texte2,
                fontFeatures: KFont.tabular,
              ),
            ),
            const SizedBox(width: KSpacing.s8),
            // C3 : le rang passe à la ligne au lieu d'être coupé.
            Expanded(
              child: Text(
                '${inLevel.round()} / $need XP · ${rank.title}',
                textAlign: TextAlign.end,
                style: KType.detail.copyWith(
                  color: k.texte2,
                  fontFeatures: KFont.tabular,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KSpacing.s8),
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
    // Réussites (records, badges, défis, série, objectif) : `accent`.
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpacing.s8),
      child: KCard(
        radius: KRadius.menu,
        padding: const EdgeInsets.symmetric(
          horizontal: KSpacing.s14,
          vertical: KSpacing.s12,
        ),
        child: Row(
          children: [
            Icon(icon, color: k.accent, size: KSize.icon),
            const SizedBox(width: KSpacing.s12),
            // Grand texte : le gain passe sous le libellé au lieu de
            // déborder.
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: KSpacing.s8,
                children: [
                  Text(
                    line.label,
                    style: KType.corpsFort.copyWith(color: k.texte),
                  ),
                  if (line.xp > 0)
                    Text(
                      '+${line.xp} XP',
                      style: KType.chiffrePetit.copyWith(color: k.accent),
                    ),
                ],
              ),
            ),
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
    final rank = progressRanks.lastWhere((p) => p.level <= r.levelAfter);
    final k = KTokens.of(context);
    // Carte de cérémonie : `surface` cernée d'`accent` (réussite) ; un seul
    // aplat `pleine` à l'écran, « Continuer » (C2).
    return KCard(
      outline: k.accent,
      key: const ValueKey('reward-ceremony'),
      child: Column(
        children: [
          RankInsignia(
            rankIndex: rankIndexOf(rank),
            prestige: GameState.prestigeOf(r.levelAfter),
            size: 84,
            light: k.dark,
          ),
          const SizedBox(height: KSpacing.s12),
          Text(
            r.promotion ? 'Promotion' : 'Niveau supérieur',
            textAlign: TextAlign.center,
            style: KType.section.copyWith(color: k.accent),
          ),
          const SizedBox(height: KSpacing.s4),
          Text(
            r.promotion ? rank.title : 'Niveau ${r.levelAfter}',
            textAlign: TextAlign.center,
            style: KType.titreEcran.copyWith(color: k.texte),
          ),
          if (r.promotion)
            Text(
              'Niveau ${r.levelAfter}',
              textAlign: TextAlign.center,
              style: KType.detail.copyWith(color: k.texte2),
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
  final List<Color> _colors;
  const _ConfettiPainter(this.t, this._colors);
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

/// Repère de la journée au format des écrans de séance (« S12, J1 ») ; le
/// titre enregistré dans le journal (« S12 · J1 ») ne change pas.
String _place(String title) => title.replaceFirstMapped(
  RegExp(r'^(S\d+) · (J\d+)$'),
  (m) => '${m[1]}, ${m[2]}',
);
