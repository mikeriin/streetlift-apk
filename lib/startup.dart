import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'brand.dart';
import 'dev/dev_widgets.dart' show devLogoColor;

/// Le chargement commence pendant les deux secondes d'ouverture. Si les
/// données tardent, la marque reste au centre puis termine son déplacement.
class AppStartup extends StatefulWidget {
  final Future<void> initialization;
  final WidgetBuilder appBuilder;
  final Widget Function(Object error, StackTrace stack) errorBuilder;
  final bool Function() isDark;
  final VoidCallback? onReady;
  const AppStartup({
    super.key,
    required this.initialization,
    required this.appBuilder,
    required this.errorBuilder,
    required this.isDark,
    this.onReady,
  });

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _ready = false;
  bool _holding = false;
  bool _finished = false;
  Widget? _app;
  Object? _error;
  StackTrace? _stack;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      // Le mode "réduire les animations" remplace le mouvement par un fondu,
      // sans accélérer le chargement ni supprimer la durée de lecture.
      animationBehavior: AnimationBehavior.preserve,
    )..addListener(_tick);
    _animation.forward();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await widget.initialization;
      if (!mounted) return;
      _holding = false;
      setState(() => _ready = true);
      if (!_animation.isAnimating) _animation.forward();
    } catch (error, stack) {
      if (!mounted) return;
      _animation.stop();
      setState(() {
        _error = error;
        _stack = stack;
      });
    }
  }

  void _tick() {
    if (!_ready && _animation.value >= .48 && !_holding) {
      _holding = true;
      _animation.stop();
      _animation.value = .48;
      return;
    }
    if (_ready && _animation.value >= 1 && !_finished) {
      _animation.stop();
      setState(() => _finished = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady?.call();
      });
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return widget.errorBuilder(_error!, _stack!);
    if (_ready) _app ??= widget.appBuilder(context);
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        if (_app != null)
          // L'accueil est rendu pour préparer le fondu, sans recevoir de gestes
          // ou exposer sa navigation avant la fin de l'ouverture.
          ExcludeSemantics(
            excluding: !_finished,
            child: AbsorbPointer(absorbing: !_finished, child: _app!),
          ),
        if (!_finished)
          Positioned.fill(
            child: MediaQuery.fromView(
              view: View.of(context),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => _OpeningFrame(
                    progress: _animation.value,
                    dark: !_ready || widget.isDark(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OpeningFrame extends StatelessWidget {
  final double progress;
  final bool dark;
  const _OpeningFrame({required this.progress, required this.dark});

  double _phase(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final palette = KPalette(dark);
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;
    final movement = reduceMotion
        ? 0.0
        : Curves.easeInOutCubic.transform(_phase(.48, .92));
    final reveal = Curves.easeInOut.transform(_phase(.82, 1));
    final nameOpacity = 1 - _phase(.48, .70);
    return Semantics(
      label: 'Ouverture de Kalis Track',
      child: LayoutBuilder(
        builder: (context, bounds) {
          final availableHeight = bounds.maxHeight - media.padding.vertical;
          final center = media.padding.top + availableHeight * .45;
          final target = media.padding.top + 35;
          final logoSize = 104 + (KalisLogo.headerSize - 104) * movement;
          final y = center + (target - center) * movement;
          final centerX = bounds.maxWidth / 2;
          final targetX =
              bounds.maxWidth -
              media.padding.right -
              20 -
              KalisLogo.headerSize / 2;
          final x = centerX + (targetX - centerX) * movement;
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - reveal,
                child: ColoredBox(color: palette.bg),
              ),
              Positioned(
                top: y - logoSize / 2,
                left: x - logoSize / 2,
                child: Opacity(
                  opacity: reduceMotion ? 1 - reveal : 1 - _phase(.95, 1),
                  child: KalisLogo(
                    key: const ValueKey('opening-logo'),
                    size: logoSize,
                    scale: 1,
                    // G1 : rose vif pendant la session de test.
                    color: devLogoColor(palette.logo),
                  ),
                ),
              ),
              Positioned(
                top: center + 57,
                left: 24,
                right: 24,
                child: Opacity(
                  opacity: nameOpacity,
                  child: Text(
                    'KALIS TRACK',
                    key: const ValueKey('opening-name'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      fontFamily: 'Roboto',
                      decoration: TextDecoration.none,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: math.max(media.padding.bottom, 16) + 20,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 1 - _phase(.72, .96),
                  child: Center(
                    child: Image.asset(
                      'assets/icon/splash_flag.png',
                      key: const ValueKey('opening-flag'),
                      width: 36,
                      height: 24,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: 'Drapeau français',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
