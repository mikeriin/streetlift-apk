// UI0 (refonte UI) : dock flottant fini (cahier §1, §5.4, C8). Mêmes quatre
// onglets, même ordre, libellé sur l'onglet actif seulement (choix du
// propriétaire, 11:20) ; hauteur 64, pilule de l'onglet actif en `pleine` ;
// réserve basse pour que rien ne passe dessous.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Un onglet du dock.
@immutable
class KDockItem {
  final IconData icon;
  final String label;
  const KDockItem(this.icon, this.label);
}

/// Dock flottant : quatre destinations stables ; l'onglet actif s'élargit
/// en pilule `pleine` (icône et libellé `surPleine`), les autres gardent
/// leur icône seule (`texte2`). Les libellés restent dans l'arbre
/// (accessibilité, tests) : ceux des onglets inactifs sont repliés à
/// largeur nulle, pas retirés. Une seule animation par onglet pilote
/// largeur, révélation du libellé et couleur (ressort spatial rapide) ;
/// « réduire les animations » la ramène à zéro.
class KDock extends StatelessWidget {
  /// Marge sous le dock et marges latérales.
  static const double bottomMargin = KSpacing.s16, side = KSpacing.s16;

  /// Écart minimal entre le contenu et le haut du dock (C8).
  static const double gap = KSpacing.s16;

  /// Hauteur occupée par le dock (hors zone système).
  static const double height = KSize.dock + bottomMargin;

  /// Réserve de défilement : le contenu s'arrête à [gap] au-dessus du dock.
  static const double reserve = height + gap;

  /// Largeur de l'onglet actif, en multiples d'un onglet replié.
  static const double activeWeight = 2.4;

  static const double _pad = (KSize.dock - KSize.dockItem) / 2;

  final List<KDockItem> items;
  final int index;
  final ValueChanged<int> onTap;

  /// Préfixe des clés des onglets (`nav-0`…).
  final String keyPrefix;
  const KDock({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    this.keyPrefix = 'nav',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final motion = KMotion.fast;
    final duration = motion.durationIn(context);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(side, 0, side, bottomMargin),
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: KRadius.pill),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: KSpacing.s20,
                    sigmaY: KSpacing.s20,
                  ),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: k.haute.withValues(alpha: .96),
                      shape: StadiumBorder(side: BorderSide(color: k.filet)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(_pad),
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _item(context, k, i, duration, motion.curve),
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

  Widget _item(
    BuildContext context,
    KTokens k,
    int i,
    Duration duration,
    Curve curve,
  ) {
    final item = items[i];
    final selected = index == i;
    final text = Padding(
      padding: const EdgeInsetsDirectional.only(start: KSpacing.s8),
      // Écran étroit ou grand texte : le libellé se réduit, il n'est jamais
      // coupé.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          k.title(item.label),
          maxLines: 1,
          softWrap: false,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.15),
          style: k.titleStyle(
            KType.libelle.copyWith(
              fontFamily: KFont.title,
              color: k.surPleine,
            ),
          ),
        ),
      ),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: selected ? 1 : 0),
      duration: duration,
      curve: curve,
      builder: (context, raw, _) {
        final t = raw.clamp(0.0, 1.0);
        final weight = 1 + (activeWeight - 1) * t;
        final ink = Color.lerp(k.texte2, k.surPleine, t)!;
        return Expanded(
          flex: (weight * 1000).round(),
          child: Semantics(
            button: true,
            selected: selected,
            label: item.label,
            onTap: () => onTap(i),
            excludeSemantics: true,
            child: Tooltip(
              message: item.label,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('$keyPrefix-$i'),
                  customBorder: KRadius.pill,
                  onTap: () {
                    if (!selected) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: Color.lerp(
                        k.pleine.withValues(alpha: 0),
                        k.pleine,
                        t,
                      ),
                      shape: KRadius.pill,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KSpacing.s12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: KSize.icon, color: ink),
                          Flexible(
                            child: ClipRect(
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
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
