// UI0 (refonte UI) : réglages en place (C12) — interrupteur, pas à pas,
// segments — et puce neutre (C5). Commandes en pilule, cibles de 48 dp ; un
// élément ne change jamais de forme quand il est choisi, seule sa couleur
// change (cahier §5.3).
import 'dart:math' as math;

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
      // UI5 : rail actif en `encre` (lisible sur `surface` dans les 8
      // palettes ; la dominante Bordeaux y était à 1,1:1), pouce `surEncre`.
      activeTrackColor: k.encre,
      activeThumbColor: k.roles.surEncre,
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

  /// Préfixe des clés des boutons (`<préfixe>-minus`, `<préfixe>-plus`) et
  /// de la valeur (`<préfixe>-value`) ; nul : pas de clé.
  final String? keyPrefix;
  const KStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementLabel = 'Diminuer',
    this.incrementLabel = 'Augmenter',
    this.semanticLabel,
    this.keyPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    Widget button(
      IconData icon,
      String label,
      VoidCallback? onTap,
      String role,
    ) => Tooltip(
      key: keyPrefix == null ? null : ValueKey('$keyPrefix-$role'),
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
      key: keyPrefix == null ? null : ValueKey('$keyPrefix-value'),
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
          button(Icons.remove_rounded, decrementLabel, onDecrement, 'minus'),
          const SizedBox(width: KSpacing.s4),
          if (c.maxWidth.isFinite) Flexible(child: valueBox) else valueBox,
          const SizedBox(width: KSpacing.s4),
          button(Icons.add_rounded, incrementLabel, onIncrement, 'plus'),
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
/// (même forme choisi ou non). Chaque segment offre au moins 48 dp de zone
/// touchable, en largeur comme en hauteur (C13, UI5) ; la largeur suit le
/// libellé (« Adaptatif » face à « 2 »). Quand un libellé ne tient pas
/// (écran étroit, grand texte), les choix passent l'un sous l'autre :
/// jamais de mot coupé.
class KSegmented<T> extends StatelessWidget {
  final List<KSegment<T>> segments;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  /// Préfixe des clés de segment (`<préfixe>-<valeur>`, `segment` par
  /// défaut) : deux groupes de segments d'une même page restent distincts.
  final String keyPrefix;
  const KSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
    this.keyPrefix = 'segment',
  });

  /// Largeur du mot le plus long d'un libellé.
  double _widest(BuildContext context, String label) {
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final w in label.split(' ')) {
      if (w.isEmpty) continue;
      final p = TextPainter(
        text: TextSpan(text: w, style: KType.libelle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (p.width > widest) widest = p.width;
      p.dispose();
    }
    return widest;
  }

  /// Largeur de chaque segment sur une rangée de [width] : part selon le
  /// libellé, avec un plancher de 48 dp et de quoi loger le plus long mot ;
  /// null si la rangée ne peut pas tout loger (choix en colonne).
  List<double>? _widths(BuildContext context, double width) {
    final n = segments.length;
    if (n == 0 || !width.isFinite || n * KSize.target > width) return null;
    final floor = [
      for (final s in segments)
        math.max(
          KSize.target,
          _widest(context, s.label) + 2 * KSpacing.s8 + 2 * KSpacing.s4,
        ),
    ];
    final flex = [for (final s in segments) (s.label.length + 2).toDouble()];
    final w = List<double>.filled(n, 0);
    final fixed = List<bool>.filled(n, false);
    var room = width;
    while (true) {
      final free = [
        for (var i = 0; i < n; i++)
          if (!fixed[i]) i,
      ];
      if (free.isEmpty) break;
      final total = free.fold<double>(0, (a, i) => a + flex[i]);
      var changed = false;
      for (final i in free) {
        if (room * flex[i] / total < floor[i]) {
          w[i] = floor[i];
          fixed[i] = true;
          room -= floor[i];
          changed = true;
        }
      }
      if (!changed) {
        for (final i in free) {
          w[i] = room * flex[i] / total;
        }
        room = 0;
        break;
      }
      if (room < 0) return null;
    }
    if (room < 0) return null;
    if (room > 0) {
      // Tous au plancher : le reste se partage selon le libellé.
      final total = flex.fold<double>(0, (a, f) => a + f);
      for (var i = 0; i < n; i++) {
        w[i] += room * flex[i] / total;
      }
    }
    return w;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final widths = _widths(context, c.maxWidth);
      return widths == null ? _column(context) : _row(context, widths);
    },
  );

  VoidCallback? _tap(KSegment<T> s) => onChanged == null || s.value == selected
      ? null
      : () {
          HapticFeedback.selectionClick();
          onChanged!(s.value);
        };

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
                    key: ValueKey('$keyPrefix-${s.value}'),
                    customBorder: KRadius.pill,
                    onTap: _tap(s),
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

  /// Rangée : rail en pilule ; chaque segment est une zone touchable d'au
  /// moins 48 × 48 dont la pilule du choix est en retrait de 4.
  Widget _row(BuildContext context, List<double> widths) {
    final k = KTokens.of(context);
    final motion = KMotion.fast;
    final duration = motion.durationIn(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: k.haute, shape: k.controlPill),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < segments.length; i++)
                _Slot(
                  // Le dernier prend le reste exact (arrondis).
                  width: i == segments.length - 1 ? null : widths[i],
                  child: Semantics(
                    inMutuallyExclusiveGroup: true,
                    selected: segments[i].value == selected,
                    button: true,
                    label: segments[i].semanticLabel ?? segments[i].label,
                    excludeSemantics: true,
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(segments[i].value),
                    child: InkWell(
                      key: ValueKey('$keyPrefix-${segments[i].value}'),
                      customBorder: KRadius.pill,
                      onTap: _tap(segments[i]),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: KSize.target,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(KSpacing.s4),
                          child: AnimatedContainer(
                            duration: duration,
                            curve: motion.curve,
                            padding: const EdgeInsets.symmetric(
                              horizontal: KSpacing.s8,
                              vertical: KSpacing.s4,
                            ),
                            decoration: ShapeDecoration(
                              color: segments[i].value == selected
                                  ? k.pleine
                                  : k.haute.withValues(alpha: 0),
                              shape: KRadius.pill,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              segments[i].label,
                              textAlign: TextAlign.center,
                              style: KType.libelle.copyWith(
                                color: segments[i].value == selected
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Case d'une rangée de segments : largeur fixe, ou le reste de la rangée.
class _Slot extends StatelessWidget {
  final double? width;
  final Widget child;
  const _Slot({required this.width, required this.child});

  @override
  Widget build(BuildContext context) => width == null
      ? Expanded(child: child)
      : SizedBox(width: width, child: child);
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
