// UI0 (refonte UI) : réglages en place (C12) — interrupteur, pas à pas,
// segments — et puce neutre (C5). Commandes en pilule, cibles de 48 dp ; un
// élément ne change jamais de forme quand il est choisi, seule sa couleur
// change (cahier §5.3).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Interrupteur du kit (piste 52 × 32, `pleine` quand il est actif).
class KSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;
  const KSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final sw = Switch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: k.pleine,
      activeThumbColor: k.surPleine,
      inactiveTrackColor: k.haute,
      // Éteint : pouce et contour `texte2` (≥ 4,5:1, critère 1.4.11).
      inactiveThumbColor: k.texte2,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : k.texte2,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    return semanticLabel == null
        ? sw
        : Semantics(label: semanticLabel, child: sw);
  }
}

/// Pas à pas : « − », valeur, « + », trois pilules séparées de 4 (jamais de
/// coins intérieurs carrés). Les boutons se désactivent aux bornes.
class KStepper extends StatelessWidget {
  final String value;
  final VoidCallback? onDecrement, onIncrement;
  final String decrementLabel, incrementLabel;

  /// Nom lu par le lecteur d'écran avec la valeur (« Repos par défaut »).
  final String? semanticLabel;
  const KStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementLabel = 'Diminuer',
    this.incrementLabel = 'Augmenter',
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    Widget button(IconData icon, String label, VoidCallback? onTap) => Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: k.haute,
          shape: k.controlPill,
          child: InkWell(
            customBorder: KRadius.pill,
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
            child: SizedBox.square(
              dimension: KSize.target,
              child: Icon(
                icon,
                size: KSize.iconSmall,
                color: onTap == null ? k.texte3 : k.texte,
              ),
            ),
          ),
        ),
      ),
    );
    final valueBox = Semantics(
      label: semanticLabel,
      value: value,
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: KSize.target + KSpacing.s24 + KSpacing.s4,
          minHeight: KSize.target,
        ),
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.s12),
        decoration: ShapeDecoration(color: k.haute, shape: k.controlPill),
        alignment: Alignment.center,
        // Un nombre reste entier : il se réduit plutôt que de passer à la
        // ligne (cahier §5.2).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: KType.chiffreMoyen.copyWith(color: k.texte),
          ),
        ),
      ),
    );
    // Place bornée : la valeur se réduit plutôt que de déborder.
    return LayoutBuilder(
      builder: (context, c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, decrementLabel, onDecrement),
          const SizedBox(width: KSpacing.s4),
          if (c.maxWidth.isFinite) Flexible(child: valueBox) else valueBox,
          const SizedBox(width: KSpacing.s4),
          button(Icons.add_rounded, incrementLabel, onIncrement),
        ],
      ),
    );
  }
}

/// Un segment de [KSegmented].
@immutable
class KSegment<T> {
  final T value;
  final String label;
  final String? semanticLabel;
  const KSegment(this.value, this.label, {this.semanticLabel});
}

/// Segments : choix exclusif en place (thème, mode d'évolution, objectif de
/// la semaine). Rail `haute` en pilule ; le choix est une pilule `pleine`
/// (même forme choisi ou non). Chaque segment occupe 48 dp de haut ; un
/// libellé trop long passe à la ligne, jamais coupé.
class KSegmented<T> extends StatelessWidget {
  final List<KSegment<T>> segments;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;
  const KSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  /// Vrai si chaque libellé tient sur sa largeur sans couper un mot.
  bool _fits(BuildContext context, double width) {
    if (!width.isFinite) return true;
    final scaler = MediaQuery.textScalerOf(context);
    const need = 2 * KSpacing.s4;
    var total = 0;
    for (final s in segments) {
      total += s.label.length + 2;
    }
    for (final s in segments) {
      var widest = 0.0;
      for (final w in s.label.split(' ')) {
        final p = TextPainter(
          text: TextSpan(text: w, style: KType.libelle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (p.width > widest) widest = p.width;
        p.dispose();
      }
      // Largeur donnée au segment (flex) contre largeur de son plus long mot.
      final share = (width - need) * (s.label.length + 2) / total;
      if (share < widest + 2 * KSpacing.s8) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) =>
        _fits(context, c.maxWidth) ? _row(context) : _column(context),
  );

  /// Libellés trop longs (écran étroit, grand texte) : choix l'un sous
  /// l'autre, mêmes pilules, rien n'est coupé.
  Widget _column(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in segments)
            Padding(
              padding: const EdgeInsets.only(bottom: KSpacing.s4),
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                selected: s.value == selected,
                button: true,
                label: s.semanticLabel ?? s.label,
                excludeSemantics: true,
                onTap: onChanged == null ? null : () => onChanged!(s.value),
                child: Material(
                  color: s.value == selected ? k.pleine : k.haute,
                  shape: s.value == selected ? KRadius.pill : k.controlPill,
                  child: InkWell(
                    key: ValueKey('segment-${s.value}'),
                    customBorder: KRadius.pill,
                    onTap: onChanged == null || s.value == selected
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onChanged!(s.value);
                          },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: KSize.target,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KSpacing.s16,
                          vertical: KSpacing.s8,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: 1,
                          child: Text(
                            s.label,
                            style: KType.libelle.copyWith(
                              color: s.value == selected
                                  ? k.surPleine
                                  : k.texte2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context) {
    final k = KTokens.of(context);
    final motion = KMotion.fast;
    final duration = motion.durationIn(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: k.haute, shape: k.controlPill),
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.s4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in segments)
                  // Largeur selon le libellé (« Adaptatif » face à « 2 ») :
                  // aucun mot coupé.
                  Expanded(
                    flex: s.label.length + 2,
                    child: Semantics(
                      inMutuallyExclusiveGroup: true,
                      selected: s.value == selected,
                      button: true,
                      label: s.semanticLabel ?? s.label,
                      excludeSemantics: true,
                      onTap: onChanged == null
                          ? null
                          : () => onChanged!(s.value),
                      child: InkWell(
                        key: ValueKey('segment-${s.value}'),
                        customBorder: KRadius.pill,
                        onTap: onChanged == null || s.value == selected
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onChanged!(s.value);
                              },
                        child: AnimatedContainer(
                          duration: duration,
                          curve: motion.curve,
                          constraints: const BoxConstraints(
                            minHeight: KSize.target - 2 * KSpacing.s4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: KSpacing.s8,
                            vertical: KSpacing.s4,
                          ),
                          decoration: ShapeDecoration(
                            color: s.value == selected
                                ? k.pleine
                                : k.haute.withValues(alpha: 0),
                            shape: KRadius.pill,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.label,
                            textAlign: TextAlign.center,
                            style: KType.libelle.copyWith(
                              color: s.value == selected
                                  ? k.surPleine
                                  : k.texte2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puce neutre (C5) : information ou filtre, jamais colorée sans état. Une
/// puce choisie (filtre) prend l'aplat `pleine`, même forme.
class KChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final String deleteLabel;
  const KChip(
    this.label, {
    super.key,
    this.icon,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.deleteLabel = 'Retirer',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final fg = selected ? k.surPleine : k.texte2;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: KSpacing.s32),
      padding: EdgeInsetsDirectional.only(
        start: KSpacing.s12,
        end: onDeleted == null ? KSpacing.s12 : KSpacing.s4,
      ),
      decoration: ShapeDecoration(
        color: selected ? k.pleine : k.haute,
        shape: selected ? KRadius.pill : k.controlPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: KSize.chevron, color: fg),
            const SizedBox(width: KSpacing.s4),
          ],
          Flexible(
            child: Text(label, style: KType.detail.copyWith(color: fg)),
          ),
          if (onDeleted != null)
            SizedBox(
              width: KSpacing.s32,
              height: KSpacing.s32,
              child: IconButton(
                tooltip: '$deleteLabel $label',
                padding: EdgeInsets.zero,
                iconSize: KSize.chevron - KSpacing.s4,
                onPressed: onDeleted,
                icon: Icon(Icons.close_rounded, color: fg),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return chip;
    // Cible de 48 dp autour d'une puce de 32 dp.
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        customBorder: KRadius.pill,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.target),
          child: Align(widthFactor: 1, heightFactor: 1, child: chip),
        ),
      ),
    );
  }
}
