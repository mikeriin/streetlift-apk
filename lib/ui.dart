// Adaptateur de la refonte UI (UI0, cahier §5) : les composants historiques
// partagés par les écrans gardent leur API mais sont rendus par le kit
// (`lib/kit/`, réexporté ici) : jetons de couleur des 8 palettes, polices
// Barlow, rayons des trois familles, titres de section sans capitales (C6).
// Les lots d'écrans remplacent ces composants par ceux du kit ; ce fichier
// disparaît à UI5.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'kit/kit.dart';

export 'kit/kit.dart';

/// Règles partagées par tous les écrans : espacements, surfaces et actions.
class KSpace {
  static const double page = KSpacing.page, gap = KSpacing.cardGap;
  static const double radius = KRadius.card, maxWidth = KSpacing.maxWidth;
  static const content = EdgeInsets.fromLTRB(
    page,
    KSpacing.s8,
    page,
    KSpacing.s24,
  );
}

class KContent extends StatelessWidget {
  final Widget child;
  const KContent({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: KNavigationInset.of(context) == 0,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: KSpace.maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class KScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body, bottomNavigationBar, floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  const KScreen({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: body == null ? null : KContent(child: body!),
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
    floatingActionButtonLocation: floatingActionButtonLocation,
  );
}

class KList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final double gap;
  const KList({
    super.key,
    required this.children,
    this.padding = KSpace.content,
    this.controller,
    this.gap = KSpace.gap,
  });
  @override
  Widget build(BuildContext context) => ListView.separated(
    controller: controller,
    padding: padding.add(EdgeInsets.only(bottom: KNavigationInset.of(context))),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    itemCount: children.length,
    separatorBuilder: (_, __) => SizedBox(height: gap),
    itemBuilder: (_, i) => children[i],
  );
}

/// Couleur d'une carte [KCard] sans couleur imposée : fond d'une vue 3D
/// posée dans une carte (règle du propriétaire, 30/09/2026 : fond de tout
/// affichage 3D = couleur de son support).
Color kCardColor(BuildContext context) => KTokens.of(context).surface;

/// Couleur de la page : fond d'une vue 3D posée directement sur la page.
Color kPageColor(BuildContext context) =>
    Theme.of(context).scaffoldBackgroundColor;

/// Titre de section (C6 depuis UI0 : 14, graisse 600, `texte2`, sans
/// capitales), sous-titre et action facultatifs.
class KSection extends StatelessWidget {
  final String title;
  final String? subtitle, actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final double topPadding;
  const KSection(
    this.title, {
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.chevron_right,
    this.topPadding = KSpacing.s12,
  });
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: KType.section.copyWith(color: k.texte2),
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: KSpacing.s8),
                Flexible(
                  child: KTextButton(
                    label: actionLabel!,
                    icon: actionIcon,
                    onPressed: onAction,
                    dense: true,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: KSpacing.s4),
            Text(subtitle!, style: KType.detail.copyWith(color: k.texte2)),
          ],
        ],
      ),
    );
  }
}

/// Pastille d'état historique : texte et icône de la couleur d'état sur sa
/// teinte, en pilule.
class KBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const KBadge(this.text, {super.key, this.color, this.icon});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final c = color ?? k.texte2;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s8,
        vertical: KSpacing.s4 / 2,
      ),
      decoration: ShapeDecoration(
        color: color == null ? k.haute : c.withValues(alpha: .16),
        shape: KRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: KSize.chevron - KSpacing.s4 / 2, color: c),
            const SizedBox(width: KSpacing.s4),
          ],
          Flexible(
            child: Text(text, style: KType.micro.copyWith(color: c)),
          ),
        ],
      ),
    );
  }
}

/// Champ de recherche historique : [KSearchField] du kit.
class KSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const KSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) =>
      KSearchField(controller: controller, hint: hint, onChanged: onChanged);
}

/// Les actions voisines partagent largeur et axe central. Elles passent en colonne
/// seulement lorsque la largeur ou la taille du texte l'exige.
class KActionRow extends StatelessWidget {
  final List<Widget> children;
  final double minButtonWidth;
  const KActionRow({
    super.key,
    required this.children,
    this.minButtonWidth = KSize.valueWidth,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1.0, double.infinity);
      final stacked =
          constraints.maxWidth <
          children.length * minButtonWidth * scale +
              (children.length - 1) * KControl.gap;
      if (stacked) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: KControl.gap),
              children[i],
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: KControl.gap),
            Expanded(child: children[i]),
          ],
        ],
      );
    },
  );
}

/// Une grille de formulaire : deux colonnes égales, ou une sur écran étroit.
class KFieldGrid extends StatelessWidget {
  final List<Widget> children;
  const KFieldGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(
        context,
      ).scale(1).clamp(1.0, double.infinity);
      final paired =
          children.length > 1 &&
          constraints.maxWidth >=
              2 * KSize.valueWidth * scale + KSpacing.s16 + KControl.gap;
      final width = paired
          ? (constraints.maxWidth - KControl.gap) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: KControl.gap,
        runSpacing: KControl.formGap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Jauge : remplissage de la palette, piste `filet`, extrémités en pilule.
/// `color` impose un remplissage uni (validation, texte sur aplat) ;
/// `gradient` un dégradé fixe (chronos : rouge historique).
class KProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color, track;
  final List<Color>? gradient;
  final String? semanticsLabel, semanticsValue;
  const KProgressBar({
    super.key,
    required this.value,
    this.height = KSpacing.s4,
    this.color,
    this.track,
    this.gradient,
    this.semanticsLabel,
    this.semanticsValue,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(v * 100).round()} %',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: KRadius.pill),
          child: ColoredBox(
            color: track ?? SL.progressTrack,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: v,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: color,
                    gradient: color == null
                        ? LinearGradient(colors: gradient ?? SL.gradient)
                        : null,
                    shape: KRadius.pill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KBottomActions extends StatelessWidget {
  final Widget child;
  const KBottomActions({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Material(
    color: KTokens.of(context).fond,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KSpace.maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.page,
              KSpacing.s12,
              KSpace.page,
              KSpacing.s12,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KControl.height),
              child: Align(
                heightFactor: 1,
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Surface de marque : aplat `pleine` (dominante exacte), texte posé dessus.
class KBanner extends StatelessWidget {
  final Color? color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const KBanner({
    super.key,
    this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(KSpacing.s16),
  });
  @override
  Widget build(BuildContext context) {
    final base = color == null
        ? KTokens.of(context).pleine
        : Color.lerp(color!, Colors.black, .5)!;
    return Material(
      color: base,
      shape: KRadius.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Grand titre d'un onglet (capitales selon U3) et sa phrase.
class KPageIntro extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const KPageIntro(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.s8, bottom: KSpacing.s14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: KFitTitle(
                    k.title(title),
                    style: k.titleStyle(
                      KType.titreRacine.copyWith(color: k.texte),
                    ),
                  ),
                ),
                const SizedBox(height: KSpacing.s4),
                Text(subtitle, style: KType.corps.copyWith(color: k.texte2)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: KSpacing.s12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Titre qui garde ses mots entiers (L5, C3) : [KFitTitle] du kit.
class KWordFitText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  const KWordFitText(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) => KFitTitle(
    text,
    style: DefaultTextStyle.of(context).style.merge(style),
    textAlign: textAlign,
  );
}

/// Ligne de menu isolée historique : une [KMenuRow] dans son groupe.
class KMenuTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const KMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => KMenuGroup(
    children: [
      KMenuRow(icon: icon, title: title, subtitle: subtitle, onTap: onTap),
    ],
  );
}
