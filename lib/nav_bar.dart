import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

/// Dock flottant One UI : quatre destinations stables, libellé porté par
/// l'onglet actif seulement (icône + texte dans une pastille teintée), icônes
/// seules ailleurs. L'onglet actif s'élargit en douceur, les trois autres se
/// resserrent. Les quatre libellés restent dans l'arbre (accessibilité, tests) :
/// ceux des onglets inactifs sont repliés à largeur nulle, pas retirés.
///
/// Une seule animation par onglet (`TweenAnimationBuilder`, progression 0 → 1)
/// pilote la largeur de l'onglet, la révélation du libellé, son opacité et la
/// teinte de la pastille. Aucun `AnimatedSize` : ce widget anime dans la phase
/// de layout et se met en défaut avec une durée nulle (« Réduire les
/// animations »), là où une animation implicite accepte `Duration.zero`.
class HeroNavBar extends StatelessWidget {
  /// Hauteur réservée sous les onglets, marges comprises et hors zone système :
  /// `main.dart` l'ajoute au défilement des quatre onglets.
  static const double extent = _top + _height + _bottom;
  static const double _height = 64, _top = 8, _bottom = 12, _side = 20;
  static const double _pad = 6;
  static const double _radius = _height / 2;
  static const double _itemRadius = (_height - 2 * _pad) / 2;

  /// Largeur de l'onglet actif, en multiples d'un onglet replié.
  static const double _activeWeight = 1.9;
  static const Duration _duration = Duration(milliseconds: 240);
  static const Curve _curve = Curves.easeOutCubic;
  static const List<(IconData, String)> _items = [
    (Icons.grid_view_rounded, 'Arsenal'),
    (Icons.insights_rounded, 'Stats'),
    (Icons.fitness_center_rounded, 'Programme'),
    (Icons.settings_outlined, 'Réglages'),
  ];

  final int index;
  final ValueChanged<int> onTap;
  const HeroNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duration;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: extent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_side, _top, _side, _bottom),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: SL.surface.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(color: SL.line.withValues(alpha: .65)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(_pad),
                      child: Row(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            _item(context, i, duration),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, Duration duration) {
    final (icon, label) = _items[i];
    final selected = index == i;
    // Le libellé est construit une fois ; seule sa largeur visible varie.
    final text = Padding(
      padding: const EdgeInsets.only(left: 8),
      // Réduit le libellé plutôt que le couper sur les écrans étroits ou avec
      // une grande police.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          softWrap: false,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.15),
          style: TextStyle(
            fontSize: 10.5,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
            color: SL.accent,
          ),
        ),
      ),
    );
    // Progression 0 (replié) → 1 (actif). `Expanded` n'accepte qu'un entier,
    // d'où le facteur 1000 (les proportions restent exactes au millième).
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selected ? 1 : 0),
      duration: duration,
      curve: _curve,
      builder: (context, raw, _) {
        final t = raw.clamp(0.0, 1.0);
        final weight = 1 + (_activeWeight - 1) * t;
        final color = Color.lerp(SL.dim, SL.accent, t)!;
        return Expanded(
          flex: (weight * 1000).round(),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            onTap: () => onTap(i),
            excludeSemantics: true,
            child: Tooltip(
              message: label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('nav-$i'),
                  borderRadius: BorderRadius.circular(_itemRadius),
                  onTap: () {
                    if (!selected) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.transparent, SL.accentTint, t),
                      borderRadius: BorderRadius.circular(_itemRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 22, color: color),
                          Flexible(
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: t,
                                child: Opacity(opacity: t, child: text),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
