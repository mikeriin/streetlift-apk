// UI0 (refonte UI) : transitions du kit, ressorts de Material 3 Expressive
// (cahier §5.5). `motion.dart` reste le point d'import historique.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Fondu et léger glissement, sans remplacer l'état du contenu animé.
/// Les IndexedStack conservent ainsi les saisies, filtres et défilements.
class KContentTransition extends StatefulWidget {
  final int position;
  final Widget child;
  const KContentTransition({
    super.key,
    required this.position,
    required this.child,
  });

  @override
  State<KContentTransition> createState() => _KContentTransitionState();
}

class _KContentTransitionState extends State<KContentTransition>
    with SingleTickerProviderStateMixin {
  // Changement d'onglet : ressort spatial par défaut (cahier §5.5).
  late final _controller = AnimationController(
    vsync: this,
    value: 1,
    duration: KMotion.standard.duration,
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: KMotion.standard.curve,
  );
  // Opacité : ressort d'effet (sans dépassement).
  late final _fade = CurvedAnimation(
    parent: _controller,
    curve: KMotion.effect.curve,
  );
  bool _reduceMotion = false;
  double _direction = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(KContentTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position == widget.position) return;
    _direction = widget.position > oldWidget.position ? 1 : -1;
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        textDirection: Directionality.of(context),
        position: Tween<Offset>(
          begin: Offset(.025 * _direction, 0),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    ),
  );
}

/// Même langage de mouvement à l'ouverture et au retour des pages.
/// Le geste natif de retour iOS reste confié à Cupertino.
class KPageTransitionsBuilder extends PageTransitionsBuilder {
  final bool cupertino;
  const KPageTransitionsBuilder({this.cupertino = false});

  // Pages : ressort spatial lent à l'ouverture, par défaut au retour
  // (cahier §5.5).
  @override
  Duration get transitionDuration => KMotion.slow.duration;

  @override
  Duration get reverseTransitionDuration => KMotion.standard.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final primary = reduceMotion ? kAlwaysCompleteAnimation : animation;
    final secondary = reduceMotion
        ? kAlwaysDismissedAnimation
        : secondaryAnimation;
    if (cupertino) {
      return const CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        primary,
        secondary,
        child,
      );
    }
    final eased = primary.drive(CurveTween(curve: KMotion.slow.curve));
    return FadeTransition(
      opacity: primary.drive(CurveTween(curve: KMotion.effect.curve)),
      child: SlideTransition(
        textDirection: Directionality.of(context),
        position: Tween<Offset>(
          begin: const Offset(.045, 0),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}
