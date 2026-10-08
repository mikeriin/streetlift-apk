import 'package:flutter/material.dart';

/// K historique sur fond transparent, teinté selon le thème par l'appelant.
class KalisLogo extends StatelessWidget {
  static const double headerSize = 48;
  final double size;
  final Color color;
  final double scale;
  const KalisLogo({
    super.key,
    this.size = headerSize,
    required this.color,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Kalis Track',
    child: SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: size * .06),
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            'assets/icon/logo_mark.png',
            color: color,
            colorBlendMode: BlendMode.srcIn,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}
