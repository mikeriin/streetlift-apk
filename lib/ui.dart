import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'koach/koach_view.dart' show KoachSurface;

/// Règles partagées par tous les écrans : espacements, surfaces et actions.
class KSpace {
  static const double page = 20, gap = 12, radius = 32, maxWidth = 840;
  static const content = EdgeInsets.fromLTRB(page, 8, page, 24);
}

/// Réserve de défilement pour les quatre onglets sous la navigation flottante.
/// Les routes ouvertes au-dessus des onglets gardent leur SafeArea habituelle.
class KNavigationInset extends InheritedWidget {
  final double bottom;
  const KNavigationInset({
    super.key,
    required this.bottom,
    required super.child,
  });

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KNavigationInset>()?.bottom ??
      0;

  @override
  bool updateShouldNotify(KNavigationInset oldWidget) =>
      bottom != oldWidget.bottom;
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
Color kCardColor(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerLow;

/// Couleur de la page : fond d'une vue 3D posée directement sur la page.
Color kPageColor(BuildContext context) =>
    Theme.of(context).scaffoldBackgroundColor;

class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent, color, outline;
  final double? radius;
  final VoidCallback? onTap, onLongPress;
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.accent,
    this.color,
    this.outline,
    this.radius,
    this.onTap,
    this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlighted = accent != null || color != null;
    final fill =
        color ??
        (accent == null
            ? c.surfaceContainerLow
            : Color.alphaBlend(
                accent!.withValues(alpha: .05),
                c.surfaceContainerLow,
              ));
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius ?? KSpace.radius),
        side: outline != null
            ? BorderSide(color: outline!)
            : dark || highlighted
            ? BorderSide.none
            : BorderSide(color: c.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        // G5 : Koach posé sur la carte prend sa couleur pour papier.
        child: KoachSurface(
          color: fill,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

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
    this.topPadding = 12,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: topPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .7,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: TextButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class KBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const KBadge(this.text, {super.key, this.color, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: c),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: c,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KEmpty extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  const KEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Material(
      color: c.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KSpace.radius),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: c.onSurfaceVariant, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(message, style: Theme.of(context).textTheme.bodySmall),
                    if (action != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        action!,
                        style: TextStyle(
                          color: c.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onAction != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.chevron_right, color: c.primary, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      );
}

/// Les actions voisines partagent largeur et axe central. Elles passent en colonne
/// seulement lorsque la largeur ou la taille du texte l'exige.
class KActionRow extends StatelessWidget {
  final List<Widget> children;
  final double minButtonWidth;
  const KActionRow({
    super.key,
    required this.children,
    this.minButtonWidth = 140,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = (MediaQuery.textScalerOf(context).scale(13) / 13).clamp(
        1.0,
        double.infinity,
      );
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
      final scale = (MediaQuery.textScalerOf(context).scale(15) / 15).clamp(
        1.0,
        double.infinity,
      );
      final paired =
          children.length > 1 &&
          constraints.maxWidth >= 296 * scale + KControl.gap;
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

/// Jauge de la charte : remplissage principale → vive de la couleur
/// dominante (L5-C), piste neutre, extrémités arrondies. `color` impose un
/// remplissage uni (validation en vert, blanc sur bordeaux) ; `gradient`
/// impose un dégradé fixe (chronos : rouge historique).
class KProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color, track;
  final List<Color>? gradient;
  final String? semanticsLabel, semanticsValue;
  const KProgressBar({
    super.key,
    required this.value,
    this.height = 5,
    this.color,
    this.track,
    this.gradient,
    this.semanticsLabel,
    this.semanticsValue,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height);
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue ?? '${(v * 100).round()} %',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: track ?? SL.progressTrack,
            borderRadius: radius,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  gradient: color == null
                      ? LinearGradient(colors: gradient ?? SL.gradient)
                      : null,
                  borderRadius: radius,
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
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KSpace.maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.page,
              10,
              KSpace.page,
              12,
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

/// Surface de marque en bordeaux soutenu, identique dans les deux thèmes.
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final base = color == null
        ? SL.bordeaux
        : Color.lerp(color!, Colors.black, .5)!;
    return Material(
      color: c.surfaceContainerLow,
      borderRadius: BorderRadius.circular(32),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(color: base),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// En-tête de marque, identique dans les quatre destinations principales.
class KTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget> actions;

  /// Hauteur de la barre : 70 par défaut ; l'appelant l'agrandit quand son
  /// contenu suit la taille de texte du téléphone (niveau de PROGRAMME).
  final double height;
  const KTopBar({
    super.key,
    this.leading,
    this.actions = const [],
    this.height = 70,
  });
  @override
  Size get preferredSize => Size.fromHeight(height);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: height,
    titleSpacing: KSpace.page,
    title:
        leading ??
        Text(
          'KALIS TRACK',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
            color: SL.dim,
          ),
        ),
    actions: [
      ...actions,
      const Padding(
        padding: EdgeInsets.only(right: 20),
        // G1 : gestes du mode dev (build de développement seulement).
        child: HeaderLogo(),
      ),
    ],
  );
}

class KPageIntro extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const KPageIntro(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KWordFitText(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: SL.dim, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

/// Titre qui garde ses mots entiers (L5). Sur écran étroit avec un grand
/// texte, si le mot le plus large ne tient pas sur une ligne, la taille de
/// ce titre baisse juste assez pour le loger, sans descendre sous celle du
/// texte courant à l'échelle choisie (15 px × échelle). Le titre reste sur
/// plusieurs lignes : rien n'est coupé ni masqué.
class KWordFitText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  const KWordFitText(this.text, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final base = DefaultTextStyle.of(context).style.merge(style);
      final size = base.fontSize ?? 14;
      final scaler = MediaQuery.textScalerOf(context);
      var fitted = base;
      if (constraints.maxWidth.isFinite && size > 15) {
        var widest = 0.0;
        for (final word in text.split(RegExp(r'\s+'))) {
          if (word.isEmpty) continue;
          final painter = TextPainter(
            text: TextSpan(text: word, style: base),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          widest = math.max(widest, painter.width);
          painter.dispose();
        }
        if (widest > constraints.maxWidth) {
          final factor = math.max(
            15 / size,
            constraints.maxWidth / widest * .98,
          );
          fitted = base.copyWith(fontSize: size * factor);
        }
      }
      return Text(text, style: fitted, textAlign: textAlign);
    },
  );
}

/// Ligne de menu avec repère visuel et destination explicite.
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
  Widget build(BuildContext context) => KCard(
    padding: EdgeInsets.zero,
    child: ListTile(
      minVerticalPadding: 14,
      onTap: onTap,
      // L5 : repère décoratif retiré au-delà de 150 % de texte, pour que le
      // titre ne soit pas coupé au milieu d'un mot sur écran étroit.
      leading: MediaQuery.textScalerOf(context).scale(10) > 15
          ? null
          : Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: SL.accentTint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: SL.accent, size: 22),
            ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: SL.dim),
    ),
  );
}
