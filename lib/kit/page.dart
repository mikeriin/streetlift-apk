// UI0 (refonte UI) : pages et en-têtes (cahier C1, C3, §4.5, §5.0).
//
// - Page racine (onglet) : grand titre et une phrase ; le grand titre se
//   replie dans la barre au défilement (Samsung One UI : zone de lecture en
//   haut).
// - Sous-page : en-tête standard — retour, titre, au plus une action (⋮) —,
//   une phrase, puis le contenu.
// Aucun titre n'est coupé (C3) : il passe à la ligne, et sa taille baisse
// juste assez si un mot seul ne tient pas.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dev/dev_widgets.dart' show HeaderLogo;
import 'tokens.dart';

/// Réserve de défilement des quatre onglets sous le dock flottant (C8) :
/// fournie par la racine de navigation, lue par les listes des onglets.
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

/// Titre qui ne se coupe jamais (C3) : retour à la ligne entre les mots ; si
/// le mot le plus large ne tient pas, la taille baisse juste assez, sans
/// descendre sous celle du texte courant à l'échelle choisie.
class KFitTitle extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  const KFitTitle(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaler = MediaQuery.textScalerOf(context);
      final size = style.fontSize ?? KType.corps.fontSize!;
      final floor = KType.corps.fontSize!;
      var fitted = style;
      if (constraints.maxWidth.isFinite && size > floor) {
        double widest(TextStyle s) {
          var w = 0.0;
          for (final word in text.split(RegExp(r'\s+'))) {
            if (word.isEmpty) continue;
            final p = TextPainter(
              text: TextSpan(text: word, style: s),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            w = math.max(w, p.width);
            p.dispose();
          }
          return w;
        }

        bool fits(TextStyle s) {
          if (widest(s) > constraints.maxWidth) return false;
          if (maxLines == null) return true;
          final p = TextPainter(
            text: TextSpan(text: text, style: s),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: maxLines,
          )..layout(maxWidth: constraints.maxWidth);
          final ok = !p.didExceedMaxLines;
          p.dispose();
          return ok;
        }

        var f = size;
        while (f > floor && !fits(fitted)) {
          f = math.max(floor, f - 1);
          fitted = style.copyWith(fontSize: f);
        }
      }
      return Text(text, style: fitted, textAlign: textAlign, softWrap: true);
    },
  );
}

/// En-tête.
///
/// - [KTopBar.new] : en-tête de marque des destinations principales
///   (historique : « KALIS TRACK » ou contenu de [leading], actions, logo).
/// - [KTopBar.sub] : en-tête de sous-page (C1) — retour, titre (capitales
///   selon U3), sous-titre facultatif, au plus une action.
class KTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget> actions;
  final double height;
  final String? title, subtitle;
  final Widget? action;
  final VoidCallback? onBack;
  final bool _sub;

  const KTopBar({
    super.key,
    this.leading,
    this.actions = const [],
    this.height = KSize.dock + KSpacing.s4 + KSpacing.s4 / 2,
  }) : title = null,
       subtitle = null,
       action = null,
       onBack = null,
       _sub = false;

  /// En-tête de sous-page.
  const KTopBar.sub({
    super.key,
    required String this.title,
    this.subtitle,
    this.action,
    this.onBack,
    this.height = KSize.dock,
  }) : leading = null,
       actions = const [],
       _sub = true;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    if (!_sub) {
      return AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: height,
        titleSpacing: KSpacing.page,
        title:
            leading ??
            Text(
              k.title('Kalis Track'),
              style: KType.micro.copyWith(
                color: k.texte2,
                letterSpacing: KType.capsSpacing * 6,
              ),
            ),
        actions: [
          ...actions,
          const Padding(
            padding: EdgeInsetsDirectional.only(end: KSpacing.page),
            // G1 : gestes du mode dev (build de développement seulement).
            child: HeaderLogo(),
          ),
        ],
      );
    }
    final titleStyle = k.titleStyle(KType.titreEcran.copyWith(color: k.texte));
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      titleSpacing: 0,
      leadingWidth: KSize.target + KSpacing.s8,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: KSpacing.s8),
        child: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: KFitTitle(k.title(title!), style: titleStyle, maxLines: 2),
          ),
          if (subtitle != null)
            Text(subtitle!, style: KType.detail.copyWith(color: k.texte2)),
        ],
      ),
      actions: [
        if (action != null) action!,
        const SizedBox(width: KSpacing.s8),
      ],
    );
  }
}

/// Phrase d'introduction sous un titre de page.
class KLead extends StatelessWidget {
  final String text;
  const KLead(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KSpacing.s4,
      0,
      KSpacing.s4,
      KSpacing.s4,
    ),
    child: Text(
      text,
      style: KType.corps.copyWith(color: KTokens.of(context).texte2),
    ),
  );
}

/// Page du kit.
///
/// [KPage.root] : page d'un onglet — grand titre (30, capitales selon U3) et
/// une phrase, recherche facultative ([search]), contenu ; le grand titre se
/// replie dans la barre au défilement. La réserve basse du dock
/// ([KNavigationInset]) est ajoutée au défilement.
///
/// [KPage.sub] : sous-page — en-tête standard (C1), une phrase, contenu.
class KPage extends StatelessWidget {
  final String title;
  final String? subtitle, lead;
  final Widget? search, trailing, action;
  final List<Widget> children;
  final ScrollController? controller;
  final Widget? bottom;
  final bool _root;
  final double gap;

  const KPage.root({
    super.key,
    required this.title,
    this.lead,
    this.search,
    this.trailing,
    required this.children,
    this.controller,
    this.bottom,
    this.gap = KSpacing.s12,
  }) : subtitle = null,
       action = null,
       _root = true;

  const KPage.sub({
    super.key,
    required this.title,
    this.subtitle,
    this.lead,
    this.action,
    required this.children,
    this.controller,
    this.bottom,
    this.gap = KSpacing.s12,
  }) : search = null,
       trailing = null,
       _root = false;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final inset = KNavigationInset.of(context);
    final safeBottom = inset > 0 ? inset : MediaQuery.paddingOf(context).bottom;
    final body = <Widget>[
      if (lead != null) KLead(lead!),
      if (search != null) search!,
      ...children,
    ];
    final list = SliverPadding(
      padding: EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24 + (bottom == null ? safeBottom : 0),
      ),
      sliver: SliverList.separated(
        itemCount: body.length,
        separatorBuilder: (_, __) => SizedBox(height: gap),
        itemBuilder: (_, i) => body[i],
      ),
    );
    final scroll = CustomScrollView(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [if (_root) _RootTitleBar(title: title, trailing: trailing), list],
    );
    return Scaffold(
      backgroundColor: k.fond,
      appBar: _root
          ? null
          : KTopBar.sub(title: title, subtitle: subtitle, action: action),
      body: SafeArea(
        top: _root,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
            child: scroll,
          ),
        ),
      ),
      bottomNavigationBar: bottom,
    );
  }
}

/// Barre d'un onglet : grand titre qui se replie au défilement.
class _RootTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _RootTitleBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final big = k.titleStyle(KType.titreRacine.copyWith(color: k.texte));
    final small = k.titleStyle(KType.titreEcran.copyWith(color: k.texte));
    final scaler = MediaQuery.textScalerOf(context);
    final width = math.min(
      MediaQuery.sizeOf(context).width,
      KSpacing.maxWidth,
    );
    final painter = TextPainter(
      text: TextSpan(text: k.title(title), style: big),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: width - 2 * KSpacing.page);
    final bigHeight = painter.height;
    painter.dispose();
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: k.fond,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: KSize.dock,
      expandedHeight: KSize.dock + bigHeight + KSpacing.s8,
      titleSpacing: KSpacing.page,
      title: _Collapse(
        visibleWhenCollapsed: true,
        child: Text(
          k.title(title),
          style: small,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: KSpacing.page),
            child: trailing,
          ),
      ],
      flexibleSpace: _Collapse(
        visibleWhenCollapsed: false,
        child: Align(
          alignment: AlignmentDirectional.bottomStart,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpacing.page,
              0,
              KSpacing.page,
              KSpacing.s8,
            ),
            child: Semantics(
              header: true,
              child: KFitTitle(k.title(title), style: big),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fondu selon le repli de la barre ([FlexibleSpaceBarSettings]).
class _Collapse extends StatelessWidget {
  final bool visibleWhenCollapsed;
  final Widget child;
  const _Collapse({required this.visibleWhenCollapsed, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = context
        .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (s == null) return visibleWhenCollapsed ? const SizedBox.shrink() : child;
    final range = s.maxExtent - s.minExtent;
    final t = range <= 0
        ? 1.0
        : ((s.maxExtent - s.currentExtent) / range).clamp(0.0, 1.0);
    // Le petit titre n'apparaît qu'une fois le grand presque replié.
    final opacity = visibleWhenCollapsed
        ? ((t - .7) / .3).clamp(0.0, 1.0)
        : (1 - t / .7).clamp(0.0, 1.0);
    return ExcludeSemantics(
      excluding: opacity < .5,
      child: Opacity(opacity: opacity, child: child),
    );
  }
}

/// Gabarit « menu racine » (cahier §4.5) : grand titre (capitales selon U3)
/// et une phrase, recherche (Réglages, Arsenal), carte d'en-tête facultative
/// (Profil), puis les groupes (`KMenuGroup`, titres de section compris).
/// [root] faux : même gabarit en sous-page (Mon programme, Profil…).
class KMenuPage extends StatelessWidget {
  final String title, lead;
  final Widget? search, header, trailing, action;
  final List<Widget> groups;
  final bool root;
  final ScrollController? controller;
  const KMenuPage({
    super.key,
    required this.title,
    required this.lead,
    required this.groups,
    this.search,
    this.header,
    this.trailing,
    this.action,
    this.root = true,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final children = [if (header != null) header!, ...groups];
    return root
        ? KPage.root(
            title: title,
            lead: lead,
            search: search,
            trailing: trailing,
            controller: controller,
            gap: KSpacing.s8,
            children: children,
          )
        : KPage.sub(
            title: title,
            lead: lead,
            action: action,
            controller: controller,
            gap: KSpacing.s8,
            children: [if (search != null) search!, ...children],
          );
  }
}
