// G5 (D1.5, D6.1 à D6.3) : Koach 2D, rendu des poses vectorisées de
// `kalis_koach` (36 poses, calques encre / papier / yeux).
//
// - Couleurs inversées selon le thème (D6.2, CONTRAT.md de kalis_koach § 2) :
//   thème sombre, encre = texte clair #F4F4F4 et papier = fond du support
//   (le papier et les yeux sont « percés » dans un calque : ils laissent
//   voir exactement le support, carte teintée comprise) ; thème clair, encre
//   quasi-noire #141414 et papier blanc. Aucun contour, aucun effet.
// - Micro-animations (D6.3) : rebond d'entrée, transition entre deux poses
//   (fondu + écrasement puis étirement, 200 ms), clignement des yeux ouverts
//   (intervalle irrégulier seedé), respiration lente et légère (grandes
//   vues). Rendu à la demande : aucune image n'est produite entre deux
//   clignements d'un petit Koach ; la respiration avance à 20 images/s par
//   une horloge partagée ; tout s'arrête hors écran (route cachée, onglet
//   masqué : TickerMode) et quand l'application passe en arrière-plan.
//   « Réduire les animations » : pose fixe, changement de pose immédiat.
// - Les chemins Flutter de chaque pose sont construits une fois puis gardés
//   en mémoire (36 poses, 10 flammes).
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kalis_koach/kalis_koach.dart';

/// Réglages globaux des micro-animations.
abstract final class KoachMotion {
  /// Animations au repos (respiration, clignement). Coupées sous
  /// `flutter test` (sinon aucun écran ne se stabilise), réactivables par
  /// un test qui les vérifie.
  static bool idle = !Platform.environment.containsKey('FLUTTER_TEST');

  /// Durée du rebond d'entrée.
  static const entrance = Duration(milliseconds: 420);

  /// Durée d'une transition entre deux poses (D6.3 : ≤ 200 ms).
  static const transition = Duration(milliseconds: 200);

  /// Durée d'un clignement.
  static const blink = Duration(milliseconds: 150);

  /// Période de la respiration.
  static const breathPeriod = Duration(milliseconds: 3600);

  /// Amplitude verticale de la respiration (fraction de la hauteur).
  static const breathAmplitude = 0.012;

  /// Intervalle entre deux clignements : [blinkMin] + aléa seedé jusqu'à
  /// [blinkMin] + [blinkSpread] ; un clignement sur cinq est double.
  static const blinkMin = Duration(milliseconds: 2200);
  static const blinkSpread = Duration(milliseconds: 4200);

  /// Hauteur à partir de laquelle Koach respire (en dessous, l'amplitude
  /// est inférieure au pixel : aucune image inutile).
  static const breathMinHeight = 64.0;
}

/// Couleurs de Koach sur un support (D6.2).
@immutable
class KoachColors {
  /// Encre (silhouette).
  final Color ink;

  /// Papier (K, yeux, traits intérieurs) ; `null` = percé : laisse voir le
  /// support (thème sombre).
  final Color? paper;
  const KoachColors(this.ink, this.paper);

  /// Encre du thème sombre (texte clair de l'application).
  static const darkInk = Color(0xFFF4F4F4);

  /// Encre du thème clair (quasi-noir des planches de contrôle).
  static const lightInk = Color(0xFF141414);

  /// Support sombre : Koach blanc, yeux et K de la couleur du support.
  static const onDark = KoachColors(darkInk, null);

  /// Support clair : Koach noir, yeux et K blancs.
  static const onLight = KoachColors(lightInk, Color(0xFFFFFFFF));

  /// Couleurs pour un support sombre ou clair.
  static KoachColors forSurface({required bool dark}) =>
      dark ? onDark : onLight;

  /// Couleurs pour un support de couleur [surface] (bulle, message court).
  static KoachColors onColor(Color surface) =>
      forSurface(dark: surface.computeLuminance() < .4);

  /// Couleurs du thème courant.
  static KoachColors of(BuildContext context) =>
      forSurface(dark: Theme.of(context).brightness == Brightness.dark);

  @override
  bool operator ==(Object other) =>
      other is KoachColors && other.ink == ink && other.paper == paper;

  @override
  int get hashCode => Object.hash(ink, paper);
}

class _PathSink implements KoachPathSink {
  final Path path = Path()..fillType = PathFillType.evenOdd;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x, double y) =>
      path.cubicTo(x1, y1, x2, y2, x, y);

  @override
  void close() => path.close();
}

/// Chemin Flutter (pair-impair) d'un calque de commandes `kalis_koach`.
Path koachLayerPath(List<int> cmds) {
  final sink = _PathSink();
  replayKoachPath(cmds, sink);
  return sink.path;
}

Rect _rect(KoachBox b) => Rect.fromLTRB(
  b.left.toDouble(),
  b.top.toDouble(),
  b.right.toDouble(),
  b.bottom.toDouble(),
);

/// Chemins d'une pose, en unités Koach (construits une fois).
class KoachPaths {
  final Path ink, paper, eyes;
  final Rect bounds;
  final List<Rect> eyeBoxes;
  KoachPaths._(this.ink, this.paper, this.eyes, this.bounds, this.eyeBoxes);

  static final Map<KoachPose, KoachPaths> _cache = {};

  /// Chemins de [pose] (cache).
  static KoachPaths of(KoachPose pose) => _cache.putIfAbsent(pose, () {
    final art = pose.art;
    return KoachPaths._(
      koachLayerPath(art.ink),
      koachLayerPath(art.paper),
      koachLayerPath(art.eyes),
      _rect(art.bounds),
      [for (final b in art.eyeBoxes) _rect(b)],
    );
  });

  /// Poses déjà converties (tests).
  static int get cached => _cache.length;
}

/// Cadre de dessin d'une pose.
enum KoachFrame {
  /// Cadre serré de la pose (accessoires compris) ; même échelle du corps
  /// pour toutes les poses à hauteur égale. Pour les petites vues.
  pose,

  /// Cadre commun aux 36 poses (`koachCommonFrame`) : Koach garde sa place
  /// et sa taille quand il change de pose. Pour les grandes vues.
  stage,
}

/// Haut et bas communs du cadre serré : la pose la plus haute (`flag`)
/// monte à −1 156 unités.
const double _poseTop = -1180, _poseBottom = 24, _poseMargin = 24;

/// Cadre (unités Koach) d'une pose.
Rect koachFrameOf(KoachPose pose, KoachFrame frame) {
  if (frame == KoachFrame.stage) return _rect(koachCommonFrame);
  final b = pose.art.bounds;
  return Rect.fromLTRB(
    b.left - _poseMargin,
    _poseTop,
    b.right + _poseMargin,
    _poseBottom,
  );
}

/// Largeur d'une vue de [height] px pour [pose].
double koachWidthFor(KoachPose pose, double height, KoachFrame frame) {
  final r = koachFrameOf(pose, frame);
  return height * r.width / r.height;
}

/// Horloge de respiration partagée (20 images/s), active seulement tant
/// qu'un Koach respire à l'écran.
class _BreathClock extends ChangeNotifier {
  _BreathClock._();
  static final instance = _BreathClock._();

  final Stopwatch _watch = Stopwatch()..start();
  Timer? _timer;
  int _users = 0;

  double get seconds => _watch.elapsedMicroseconds / 1e6;

  void attach(VoidCallback l) {
    addListener(l);
    _users++;
    _timer ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => notifyListeners(),
    );
  }

  void detach(VoidCallback l) {
    removeListener(l);
    _users--;
    if (_users <= 0) {
      _users = 0;
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// État animé lu par le peintre (rebond, transition, clignement,
/// respiration).
class KoachAnimation extends ChangeNotifier {
  double entry = 1, transition = 1, blinkOpen = 1, breath = 0;
  void changed() => notifyListeners();
}

/// Koach dessiné dans une pose (D6.2, D6.3).
class KoachView extends StatefulWidget {
  final KoachPose pose;

  /// Hauteur de la vue ; la largeur suit la pose ([width] pour l'imposer).
  final double height;
  final double? width;
  final KoachFrame frame;

  /// Couleurs imposées (support hors thème : message court, bulle) ; par
  /// défaut celles du thème courant.
  final KoachColors? colors;

  /// Faux : pose fixe (aucune animation).
  final bool animate;

  /// Rebond à la première apparition.
  final bool entrance;

  /// Respiration ; par défaut à partir de [KoachMotion.breathMinHeight].
  final bool? breathe;

  /// Graine du clignement (intervalle irrégulier reproductible).
  final int seed;

  /// Libellé pour TalkBack ; `null` : Koach est décoratif (le texte de sa
  /// bulle porte le sens).
  final String? semanticLabel;

  const KoachView({
    super.key,
    required this.pose,
    this.height = 64,
    this.width,
    this.frame = KoachFrame.pose,
    this.colors,
    this.animate = true,
    this.entrance = true,
    this.breathe,
    this.seed = 0,
    this.semanticLabel,
  });

  @override
  State<KoachView> createState() => KoachViewState();
}

class KoachViewState extends State<KoachView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final KoachAnimation _anim = KoachAnimation();
  // Temps du ticker (s) : temps des images, simulé par `flutter test`.
  double _t = 0;
  late math.Random _rng = math.Random(widget.seed);
  late final double _breathOffset = math.Random(widget.seed + 7).nextDouble();

  KoachPose? _previous;
  double? _entryAt, _transitionAt, _blinkAt;
  Timer? _blinkTimer;
  bool _motion = false, _reduce = false, _resumed = true;
  bool _breathing = false, _started = false;

  /// Animations actives (tests) : rebond, transition ou clignement en cours.
  bool get animating => _ticker.isActive;

  /// Prochain clignement programmé (tests).
  bool get blinkScheduled => _blinkTimer?.isActive ?? false;

  /// Respiration branchée sur l'horloge (tests).
  bool get breathing => _breathing;

  /// Pose précédente pendant une transition (tests).
  KoachPose? get previous => _previous;


  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _resumed = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _motion = widget.animate && !_reduce;
    if (!_started) {
      _started = true;
      if (_motion && widget.entrance) {
        _entryAt = _start();
        _anim.entry = 0;
      }
    } else if (!_motion) {
      _settle();
    }
    _updateIdle();
  }

  @override
  void didUpdateWidget(KoachView old) {
    super.didUpdateWidget(old);
    if (old.seed != widget.seed) _rng = math.Random(widget.seed);
    if (old.animate != widget.animate) {
      _motion = widget.animate && !_reduce;
      if (!_motion) _settle();
    }
    if (old.pose != widget.pose) {
      if (_motion) {
        _previous = old.pose;
        _transitionAt = _start();
        _anim.transition = 0;
      } else {
        _previous = null;
        _anim.transition = 1;
      }
      _anim.changed();
    }
    _updateIdle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _updateIdle();
  }

  /// Fin immédiate de toute animation (« Réduire les animations »).
  void _settle() {
    _entryAt = _transitionAt = _blinkAt = null;
    _previous = null;
    _anim
      ..entry = 1
      ..transition = 1
      ..blinkOpen = 1
      ..breath = 0;
    if (_ticker.isActive) _ticker.stop();
    _anim.changed();
  }

  bool get _idleOn => _motion && _resumed && KoachMotion.idle;

  void _updateIdle() {
    final on = _idleOn;
    final breathe =
        on && (widget.breathe ?? widget.height >= KoachMotion.breathMinHeight);
    if (breathe != _breathing) {
      _breathing = breathe;
      if (breathe) {
        _BreathClock.instance.attach(_onBreath);
      } else {
        _BreathClock.instance.detach(_onBreath);
        _anim.breath = 0;
        _anim.changed();
      }
    }
    if (on && widget.pose.art.eyesOpen) {
      if (!(_blinkTimer?.isActive ?? false) && _blinkAt == null) {
        _scheduleBlink();
      }
    } else {
      _blinkTimer?.cancel();
      _blinkTimer = null;
    }
  }

  void _onBreath() {
    // Hors écran (TickerMode) : aucune image.
    if (_ticker.muted) return;
    final period = KoachMotion.breathPeriod.inMicroseconds / 1e6;
    final t = _BreathClock.instance.seconds / period + _breathOffset;
    _anim.breath = math.sin(2 * math.pi * t);
    _anim.changed();
  }

  void _scheduleBlink([Duration? after]) {
    _blinkTimer?.cancel();
    final wait =
        after ??
        KoachMotion.blinkMin +
            Duration(
              microseconds:
                  (KoachMotion.blinkSpread.inMicroseconds * _rng.nextDouble())
                      .round(),
            );
    _blinkTimer = Timer(wait, () {
      _blinkTimer = null;
      if (!mounted || !_idleOn) return;
      if (_ticker.muted || !widget.pose.art.eyesOpen) {
        _scheduleBlink();
        return;
      }
      _blinkAt = _start();
    });
  }

  /// Démarre le ticker si besoin ; renvoie l'instant de départ d'une
  /// animation dans son temps.
  double _start() {
    if (!_ticker.isActive) {
      _t = 0;
      _ticker.start();
    }
    return _t;
  }

  void _tick(Duration elapsed) {
    _t = elapsed.inMicroseconds / 1e6;
    final now = _t;
    var busy = false;
    double progress(double? start, Duration d) =>
        start == null ? 1 : ((now - start) / (d.inMicroseconds / 1e6));
    final e = progress(_entryAt, KoachMotion.entrance);
    if (e >= 1) {
      _entryAt = null;
      _anim.entry = 1;
    } else {
      _anim.entry = e;
      busy = true;
    }
    final t = progress(_transitionAt, KoachMotion.transition);
    if (t >= 1) {
      _transitionAt = null;
      _previous = null;
      _anim.transition = 1;
    } else {
      _anim.transition = t;
      busy = true;
    }
    final b = progress(_blinkAt, KoachMotion.blink);
    if (b >= 1) {
      if (_blinkAt != null) {
        _blinkAt = null;
        _anim.blinkOpen = 1;
        if (_idleOn) {
          // Un clignement sur cinq est double.
          _scheduleBlink(
            _rng.nextDouble() < .2
                ? const Duration(milliseconds: 120)
                : null,
          );
        }
      }
    } else {
      // Fermeture rapide (40 %), réouverture plus douce.
      _anim.blinkOpen = b < .4 ? 1 - b / .4 : (b - .4) / .6;
      busy = true;
    }
    _anim.changed();
    if (!busy) _ticker.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _blinkTimer?.cancel();
    if (_breathing) _BreathClock.instance.detach(_onBreath);
    _ticker.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? KoachColors.of(context);
    final width =
        widget.width ?? koachWidthFor(widget.pose, widget.height, widget.frame);
    final paint = RepaintBoundary(
      child: CustomPaint(
        size: Size(width, widget.height),
        painter: KoachPainter(
          pose: widget.pose,
          previous: _previous,
          frame: widget.frame,
          colors: colors,
          anim: _anim,
        ),
      ),
    );
    final label = widget.semanticLabel;
    return SizedBox(
      width: width,
      height: widget.height,
      child: label == null
          ? ExcludeSemantics(child: paint)
          : Semantics(image: true, label: label, child: paint),
    );
  }
}

/// Peintre d'une pose (et de la précédente pendant une transition).
class KoachPainter extends CustomPainter {
  final KoachPose pose;
  final KoachPose? previous;
  final KoachFrame frame;
  final KoachColors colors;
  final KoachAnimation? _a;

  KoachPainter({
    required this.pose,
    this.previous,
    this.frame = KoachFrame.pose,
    required this.colors,
    KoachAnimation? anim,
  }) : _a = anim,
       super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final a = _a;
    final entry = a?.entry ?? 1;
    final t = a?.transition ?? 1;
    final prev = t < 1 ? previous : null;
    final ease = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    final target = koachFrameOf(pose, frame);
    final box = prev == null
        ? target
        : Rect.lerp(koachFrameOf(prev, frame), target, ease)!;
    final s = math.min(size.width / box.width, size.height / box.height);
    // Centré horizontalement, pieds en bas de la vue.
    final dx = (size.width - box.width * s) / 2 - box.left * s;
    final dy = size.height - box.bottom * s;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);
    var alpha = 1.0;
    if (entry < 1) {
      // Rebond d'entrée autour des pieds.
      final k = .82 + .18 * Curves.easeOutBack.transform(entry);
      canvas.scale(k);
      alpha = (entry / .35).clamp(0.0, 1.0);
    }
    final breath = (a?.breath ?? 0) * KoachMotion.breathAmplitude;
    if (prev != null) {
      _pose(canvas, prev, alpha * (1 - ease), 1, 1, 1);
    }
    // Transition : écrasement puis étirement (nul aux extrémités).
    final sq = prev == null ? 0.0 : math.sin(2 * math.pi * t);
    _pose(
      canvas,
      pose,
      alpha * (prev == null ? 1 : ease),
      (1 + .04 * sq) * (1 - breath / 2),
      (1 - .06 * sq) * (1 + breath),
      a?.blinkOpen ?? 1,
    );
    canvas.restore();
  }

  void _pose(
    Canvas canvas,
    KoachPose p,
    double alpha,
    double sx,
    double sy,
    double open,
  ) {
    if (alpha <= 0) return;
    final paths = KoachPaths.of(p);
    canvas.save();
    // Échelle autour de l'origine : milieu des yeux, ligne des pieds.
    canvas.scale(sx, sy);
    // Calque propre : le papier percé ne laisse voir que le support.
    canvas.saveLayer(
      paths.bounds.inflate(8),
      Paint()..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.0, 1.0)),
    );
    canvas.drawPath(paths.ink, Paint()..color = colors.ink);
    final paper = colors.paper == null
        ? (Paint()..blendMode = BlendMode.clear)
        : (Paint()..color = colors.paper!);
    canvas.drawPath(paths.paper, paper);
    if (open >= 1 || paths.eyeBoxes.isEmpty) {
      canvas.drawPath(paths.eyes, paper);
    } else if (open > 0) {
      // Clignement : chaque œil écrasé verticalement autour de son centre ;
      // l'encre, remplie sous les yeux, fait la paupière.
      for (final e in paths.eyeBoxes) {
        canvas.save();
        canvas.clipRect(e.inflate(6));
        canvas.translate(0, e.center.dy);
        canvas.scale(1, open);
        canvas.translate(0, -e.center.dy);
        canvas.drawPath(paths.eyes, paper);
        canvas.restore();
      }
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(KoachPainter old) =>
      old.pose != pose ||
      old.previous != previous ||
      old.frame != frame ||
      old.colors != colors ||
      old._a != _a;
}
