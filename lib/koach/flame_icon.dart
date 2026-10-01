// G5 (D5.3, D5.5) : flammes de difficulté (1 à 10) de `kalis_koach`.
//
// - Tailles relatives des flammes fournies : chaque flamme est dessinée dans
//   le cadre commun des 10 (`koachFlameFrame`), même ligne de base.
// - Couleur : dégradé de la couleur dominante, du clair (1) au vif (10)
//   (`koachFlameTint`). L'information ne passe jamais par la seule couleur :
//   la taille croît avec le niveau et le libellé d'accessibilité dit
//   « Difficulté n sur 10, RIR … » (conversion de `kalis_core`).
// - [FlamePicker] : sélecteur des 10 flammes, prêt pour la séance (G9) ;
//   il n'est branché à aucune séance dans ce lot (Galerie de Koach).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' show Flames;
import 'package:kalis_koach/kalis_koach.dart';

import '../app_theme.dart';
import 'koach_view.dart' show koachLayerPath;

/// Chemins des flammes (cache).
final Map<int, Path> _flamePaths = {};

Path _flamePath(int level) =>
    _flamePaths.putIfAbsent(level, () => koachLayerPath(koachFlame(level).ink));

final Rect _flameFrame = Rect.fromLTRB(
  koachFlameFrame.left.toDouble(),
  koachFlameFrame.top.toDouble(),
  koachFlameFrame.right.toDouble(),
  koachFlameFrame.bottom.toDouble(),
);

/// RIR écrit à la française (« 1,5 »).
String flameRirText(int level) {
  final rir = Flames.toRir(level);
  final t = rir == rir.roundToDouble()
      ? rir.toInt().toString()
      : rir.toString().replaceAll('.', ',');
  return Flames.isOpenEnded(level) ? '$t et plus' : t;
}

/// Libellé d'accessibilité : « Difficulté 8 sur 10, RIR 1,5 ».
String flameSemanticLabel(int level) {
  final base = koachFlameLabel(level);
  if (level == Flames.failure) return '$base, échec, RIR 0';
  return '$base, RIR ${flameRirText(level)}';
}

/// Couleur de la flamme [level] : dégradé de la couleur dominante, clair
/// (1) → vif (10) (D5.5).
Color flameColor(int level, {required bool dark, KAccentSpec? accent}) {
  final a = accent ?? SL.accentSpec;
  final vivid = dark ? a.bright : (a.vividLight ?? a.vivid);
  // Le clair reste visible sur le fond : mélangé au blanc en thème sombre,
  // moins éclairci en thème clair (fond quasi blanc).
  final pale = Color.lerp(vivid, Colors.white, dark ? .62 : .5)!;
  return Color.lerp(pale, vivid, koachFlameTint(level))!;
}

/// Une flamme de difficulté.
class FlameIcon extends StatelessWidget {
  final int level;

  /// Hauteur du cadre commun (celle de la flamme 10).
  final double size;

  /// Couleur imposée (sinon : dégradé de la couleur dominante).
  final Color? color;

  /// Faux : décorative (le libellé est porté ailleurs).
  final bool semantics;

  const FlameIcon(
    this.level, {
    super.key,
    this.size = 28,
    this.color,
    this.semantics = true,
  }) : assert(level >= 1 && level <= 10);

  /// Largeur pour une hauteur [size].
  static double widthFor(double size) =>
      size * _flameFrame.width / _flameFrame.height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paint = CustomPaint(
      size: Size(widthFor(size), size),
      painter: _FlamePainter(level, color ?? flameColor(level, dark: dark)),
    );
    return semantics
        ? Semantics(image: true, label: flameSemanticLabel(level), child: paint)
        : ExcludeSemantics(child: paint);
  }
}

class _FlamePainter extends CustomPainter {
  final int level;
  final Color color;
  _FlamePainter(this.level, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = _flameFrame;
    final s = math.min(size.width / r.width, size.height / r.height);
    canvas.save();
    canvas.translate(
      (size.width - r.width * s) / 2 - r.left * s,
      size.height - r.bottom * s,
    );
    canvas.scale(s);
    canvas.drawPath(_flamePath(level), Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlamePainter old) =>
      old.level != level || old.color != color;
}

/// Sélecteur de difficulté : 10 flammes de taille croissante (D5.3, D5.4).
/// Prêt pour la séance (G9) ; ici seulement dans la Galerie de Koach.
class FlamePicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  final double size;
  const FlamePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            // 10 cases égales ; la flamme garde sa taille relative.
            final cell = c.maxWidth / Flames.max;
            final h = math.min(size, cell / FlameIcon.widthFor(1) * .92);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = Flames.min; i <= Flames.max; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: v == i,
                      label: flameSemanticLabel(i),
                      excludeSemantics: true,
                      child: InkWell(
                        key: ValueKey('flame-pick-$i'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onChanged(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: v == i ? SL.text : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FlameIcon(
                                i,
                                size: h,
                                semantics: false,
                                color: v != null && i > v ? SL.dot : null,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$i',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: v == i
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: v == i ? SL.text : SL.dim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          v == null
              ? 'Touche une flamme pour noter la difficulté.'
              : v == Flames.failure
              ? 'Difficulté 10 sur 10 : échec, aucune répétition en réserve.'
              : Flames.isOpenEnded(v)
              ? 'Difficulté $v sur 10 : 5 répétitions ou plus en réserve.'
              : 'Difficulté $v sur 10 : encore ${flameRirText(v)} '
                    'répétition${Flames.toRir(v) >= 2 ? 's' : ''} en réserve.',
          key: const ValueKey('flame-pick-caption'),
          textAlign: TextAlign.center,
          style: TextStyle(color: SL.dim, fontSize: 13),
        ),
      ],
    );
  }
}
