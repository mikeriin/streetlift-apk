// 6.17.0 : flou progressif sous les blocs flottants du bas (dock, barre de
// repos) : le contenu qui passe dessous se floute par paliers, de net en haut
// de la bande à flou complet au niveau du bloc, avec un voile du fond qui
// s'épaissit dans le même sens.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Flou progressif de ce qui est peint derrière : [fade] en haut, du net au
/// flou [sigma], puis flou complet jusqu'en bas.
class KProgressiveBlur extends StatelessWidget {
  final double fade;
  final double sigma;

  /// Paliers du dégradé de flou.
  static const int steps = 6;

  const KProgressiveBlur({super.key, this.fade = 32, this.sigma = 10});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      // Réduire les animations : voile seul, sans flou (moins coûteux).
      return _veil(k, 0);
    }
    Widget band(double s) => ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: s, sigmaY: s),
        child: const SizedBox.expand(),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                for (var i = 1; i <= steps; i++)
                  SizedBox(
                    height: fade / steps,
                    child: band(sigma * i / steps),
                  ),
                Expanded(child: band(sigma)),
              ],
            ),
            _veil(k, h <= 0 ? 0 : fade / h),
          ],
        );
      },
    );
  }

  /// Voile du fond : transparent en haut, 60 % au bas de la bande, 70 % en
  /// bas.
  Widget _veil(KTokens k, double stop) => DecoratedBox(
    decoration: ShapeDecoration(
      shape: const RoundedRectangleBorder(),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          k.fond.withValues(alpha: 0),
          k.fond.withValues(alpha: .6),
          k.fond.withValues(alpha: .7),
        ],
        stops: [0, stop.clamp(0.0, 1.0), 1],
      ),
    ),
  );
}

/// Bloc flottant du bas (barre de repos, dock) posé sur une bande de flou
/// progressif qui déborde de [fade] au-dessus de lui ; la bande ne prend
/// aucun appui.
class KFloatingBottom extends StatelessWidget {
  final Widget child;
  final double fade;
  const KFloatingBottom({super.key, required this.child, this.fade = 32});

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: -fade,
        bottom: 0,
        child: IgnorePointer(child: KProgressiveBlur(fade: fade)),
      ),
      child,
    ],
  );
}
