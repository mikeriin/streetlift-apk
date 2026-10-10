// UI0 (refonte UI) : gabarits des menus (cahier §4.5) — groupes de lignes,
// lignes de menu, lignes de réglage en place. La page qui les porte est
// `KMenuPage` / `KPage` (`page.dart`).
import 'package:flutter/material.dart';

import 'controls.dart';
import 'surfaces.dart';
import 'tokens.dart';

/// Groupe de lignes : titre de section facultatif au-dessus, conteneur
/// `surface` au rayon des menus (20), séparateurs entre lignes en retrait
/// de la pastille.
class KMenuGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  /// Retrait des séparateurs (par défaut : après la pastille d'icône).
  final double dividerIndent;
  final Color? color;
  const KMenuGroup({
    super.key,
    this.title,
    required this.children,
    this.dividerIndent = KSpacing.s16 + KSize.menuIcon + KSpacing.s14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: dividerIndent,
            endIndent: KSpacing.s16,
            color: k.filet,
          ),
        );
      }
      rows.add(children[i]);
    }
    final group = Material(
      color: color ?? k.surface,
      shape: KRadius.menuShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
    if (title == null) return group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [KSectionTitle(title!), group],
    );
  }
}

/// Pastille d'icône ronde (40 × 40, `haute`) des lignes de menu.
class KIconTile extends StatelessWidget {
  final IconData icon;
  final Color? color, background;
  const KIconTile(this.icon, {super.key, this.color, this.background});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Container(
      width: KSize.menuIcon,
      height: KSize.menuIcon,
      decoration: ShapeDecoration(
        color: background ?? k.haute,
        shape: KRadius.pill,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: KSize.iconSmall, color: color ?? k.texte),
    );
  }
}

/// Cadre commun des lignes de menu et de réglage : hauteur minimale, marges,
/// effet d'appui et mise en évidence d'une ligne ouverte depuis la recherche
/// des réglages (§4.4 : 1,5 s, puis la ligne reprend son fond).
class KRowFrame extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final bool highlight;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  const KRowFrame({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.highlight = false,
    this.minHeight = KSize.menuRow,
    this.padding = const EdgeInsets.symmetric(
      horizontal: KSpacing.s16,
      vertical: KSpacing.s8,
    ),
  });

  /// Durée de la mise en évidence.
  static const highlightDuration = Duration(milliseconds: 1500);

  @override
  State<KRowFrame> createState() => _KRowFrameState();
}

class _KRowFrameState extends State<KRowFrame> {
  bool _lit = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlight) _flash();
  }

  @override
  void didUpdateWidget(KRowFrame old) {
    super.didUpdateWidget(old);
    if (widget.highlight && !old.highlight) _flash();
  }

  void _flash() {
    _lit = true;
    Future<void>.delayed(KRowFrame.highlightDuration, () {
      if (mounted) setState(() => _lit = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final motion = KMotion.effect;
    return AnimatedContainer(
      duration: motion.durationIn(context),
      curve: motion.curve,
      decoration: ShapeDecoration(
        color: _lit ? k.haute : k.haute.withValues(alpha: 0),
        shape: KRadius.menuShape,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

/// Libellé d'une ligne : titre (16, 600) et description (13, `texte2`).
class KRowLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? color;
  const KRowLabel(this.title, {super.key, this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: KType.corpsFort.copyWith(color: color ?? k.texte)),
        if (subtitle != null)
          Text(subtitle!, style: KType.detail.copyWith(color: k.texte2)),
      ],
    );
  }
}

/// Ligne de menu : pastille d'icône, titre (16, 600), une ligne de
/// description (13, `texte2`, retour à la ligne permis), valeur ou chevron.
class KMenuRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle, value;
  final Widget? trailing;
  final VoidCallback? onTap, onLongPress;
  final bool danger, chevron, highlight, enabled;
  final double minHeight;
  const KMenuRow({
    super.key,
    required this.title,
    this.minHeight = KSize.menuRow,
    this.icon,
    this.leading,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.danger = false,
    this.chevron = true,
    this.highlight = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final ink = !enabled ? k.texte3 : (danger ? k.danger : k.texte);
    // Grand texte (≥ 150 %) : la pastille décorative s'efface et la valeur
    // passe sous la description, pour qu'aucun mot ne soit coupé (C3).
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final lead =
        leading ??
        (icon == null || large
            ? null
            : KIconTile(icon!, color: danger ? k.danger : null));
    final tail =
        trailing ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null && !large)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: KSize.valueWidth),
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
            if (chevron && onTap != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: KSpacing.s4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: KSize.icon,
                  color: k.texte2,
                ),
              ),
          ],
        );
    return Semantics(
      button: onTap != null,
      enabled: enabled,
      child: KRowFrame(
        highlight: highlight,
        minHeight: minHeight,
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: KSpacing.s14)],
            Expanded(
              child: KRowLabel(
                title,
                subtitle: large && value != null
                    ? [if (subtitle != null) subtitle!, value!].join(' · ')
                    : subtitle,
                color: ink,
              ),
            ),
            const SizedBox(width: KSpacing.s12),
            tail,
          ],
        ),
      ),
    );
  }
}

/// Ligne de réglage à interrupteur : toute la ligne bascule le réglage
/// (cible pleine largeur), qui s'applique tout de suite (§4.5).
class KSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final bool highlight;
  const KSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: KMenuRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      highlight: highlight,
      minHeight: KSize.settingRow,
      chevron: false,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: KSwitch(value: value, onChanged: onChanged),
    ),
  );
}

/// Ligne de réglage à pas à pas (valeur au centre, − et + séparés de 4) ;
/// sur écran étroit ou en grand texte, le pas à pas passe sous le libellé.
class KStepperRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final VoidCallback? onDecrement, onIncrement;
  final String decrementLabel, incrementLabel;
  final bool highlight;
  const KStepperRow({
    super.key,
    required this.title,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.subtitle,
    this.decrementLabel = 'Diminuer',
    this.incrementLabel = 'Augmenter',
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => KRowFrame(
    highlight: highlight,
    minHeight: KSize.settingRow,
    child: LayoutBuilder(
      builder: (context, c) {
        final stepper = KStepper(
          value: value,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
          decrementLabel: decrementLabel,
          incrementLabel: incrementLabel,
          semanticLabel: title,
        );
        final label = KRowLabel(title, subtitle: subtitle);
        final narrow =
            c.maxWidth <
            KSize.stepperRowMin * MediaQuery.textScalerOf(context).scale(1);
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label,
              const SizedBox(height: KSpacing.s8),
              stepper,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: label),
            const SizedBox(width: KSpacing.s12),
            stepper,
          ],
        );
      },
    ),
  );
}

/// Ligne de réglage à segments : libellé au-dessus, segments pleine largeur.
class KSegmentedRow<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<KSegment<T>> segments;
  final T? selected;
  final ValueChanged<T>? onChanged;
  const KSegmentedRow({
    super.key,
    required this.title,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.subtitle,
    this.highlight = false,
  });

  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return KRowFrame(
      highlight: highlight,
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s12,
        KSpacing.s16,
        KSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KRowLabel(title, subtitle: subtitle),
          const SizedBox(height: KSpacing.s8),
          KSegmented<T>(
            segments: segments,
            selected: selected,
            onChanged: onChanged,
            semanticLabel: title,
          ),
        ],
      ),
    );
  }
}
