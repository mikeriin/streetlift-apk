// 6.17.0 : fondu sous les blocs flottants du bas (dock, barre de repos).
// 6.17.3 : le flou progressif (6 puis 32 paliers de BackdropFilter) coûtait
// trop cher et montait trop haut ; il est remplacé par un fondu vers la
// couleur du fond, sur une bande courte : un seul dégradé, aucun filtre,
// donc aucune capture de l'arrière-plan. Le dock garde son propre flou
// derrière sa pilule.
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Fondu vers le fond : transparent en haut de la bande [fade], 85 % du fond
/// au bas de la bande, 95 % jusqu'en bas.
class KProgressiveBlur extends StatelessWidget {
  final double fade;
  const KProgressiveBlur({super.key, this.fade = 24});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final stop = h <= 0 ? 1.0 : (fade / h).clamp(0.0, 1.0);
        // Courbe douce (plusieurs arrêts) : pas de bord visible en haut.
        return DecoratedBox(
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                k.fond.withValues(alpha: 0),
                k.fond.withValues(alpha: .25),
                k.fond.withValues(alpha: .6),
                k.fond.withValues(alpha: .85),
                k.fond.withValues(alpha: .95),
              ],
              stops: [0, stop * .35, stop * .7, stop, 1],
            ),
          ),
        );
      },
    );
  }
}

/// Bloc flottant du bas (barre de repos, dock) posé sur un fondu qui
/// déborde de [fade] au-dessus de lui ; le fondu ne prend aucun appui.
class KFloatingBottom extends StatelessWidget {
  final Widget child;
  final double fade;
  const KFloatingBottom({super.key, required this.child, this.fade = 24});

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
