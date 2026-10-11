// UI0 (refonte UI) : surfaces du kit — carte, titre de section, bandeau dans
// le flux, état vide (cahier §5.4, C6, C7, R6). UI5 : jauge, tuile chiffrée
// et grille de tuiles de UI3 promues ici.
import 'package:flutter/material.dart';

import '../koach/koach_view.dart' show KoachSurface;
import 'buttons.dart';
import 'tokens.dart';

/// Carte de contenu : `surface`, rayon des cartes (24), aucune ombre.
///
/// Une carte contient des lignes, des champs, des puces, jamais une autre
/// carte (C7). [KCard.day] : carte du jour, aplat `pleine` (dominante exacte)
/// et texte `surPleine`. [accent] teinte légèrement le fond (mise en avant
/// d'un état) ; [outline] trace le contour de l'élément courant.
class KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent, color, outline;
  final double? radius;
  final VoidCallback? onTap, onLongPress;
  final String? semanticsLabel;
  final bool _day;

  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KSpacing.s16),
    this.accent,
    this.color,
    this.outline,
    this.radius,
    this.onTap,
    this.onLongPress,
    this.semanticsLabel,
  }) : _day = false;

  /// Carte du jour : aplat de la dominante, texte posé dessus.
  const KCard.day({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KSpacing.s20),
    this.onTap,
    this.onLongPress,
    this.semanticsLabel,
  }) : _day = true,
       accent = null,
       color = null,
       outline = null,
       radius = null;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final fill = _day
        ? k.pleine
        : color ??
              (accent == null
                  ? k.surface
                  : Color.alphaBlend(
                      accent!.withValues(alpha: .08),
                      k.surface,
                    ));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? KRadius.card),
      side: outline == null
          ? BorderSide.none
          : BorderSide(color: outline!, width: KSize.current),
    );
    Widget body = Padding(padding: padding, child: child);
    if (_day) {
      body = DefaultTextStyle.merge(
        style: TextStyle(color: k.surPleine),
        child: IconTheme.merge(
          data: IconThemeData(color: k.surPleine),
          child: body,
        ),
      );
    }
    final card = Material(
      color: fill,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        // Koach posé sur la carte prend sa couleur pour papier (G5).
        child: KoachSurface(color: fill, child: body),
      ),
    );
    if (semanticsLabel == null) return card;
    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      container: true,
      child: card,
    );
  }
}

/// Titre de section (C6) : 14, graisse 600, `encre`, sans capitales, au-dessus
/// des groupes. [action] : un lien texte à droite (« Modifier », « Tout voir »).
class KSectionTitle extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double top;
  const KSectionTitle(
    this.text, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.top = KSpacing.s14,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(KSpacing.s4, top, KSpacing.s4, KSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              // Correctifs UI (11/10/2026) : titres de section en `encre`.
              child: Text(text, style: KType.section.copyWith(color: k.encre)),
            ),
          ),
          if (actionLabel != null)
            KTextButton(label: actionLabel!, onPressed: onAction, dense: true),
        ],
      ),
    );
  }
}

/// Ton d'un bandeau [KNotice].
enum KTone { info, success, warning, danger }

/// Bandeau dans le flux (C8 : jamais flottant, jamais sous le dock) : icône
/// teintée par le ton, titre facultatif, message, action facultative.
class KNotice extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final KTone tone;
  final String? actionLabel;
  final VoidCallback? onAction, onClose;
  final String closeLabel;

  /// Clés du bouton d'action et du bouton de fermeture (tests).
  final Key? actionKey, closeKey;
  const KNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.title,
    this.tone = KTone.info,
    this.actionLabel,
    this.onAction,
    this.onClose,
    this.closeLabel = 'Fermer',
    this.actionKey,
    this.closeKey,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final ink = switch (tone) {
      KTone.info => k.encre,
      KTone.success => k.validation,
      KTone.warning => k.avertissement,
      KTone.danger => k.danger,
    };
    return Material(
      color: k.surface,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.menuRadius,
        side: BorderSide(color: k.filet),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpacing.s16,
          KSpacing.s14,
          KSpacing.s8,
          KSpacing.s14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s4 / 2),
              child: Icon(icon, color: ink, size: KSize.iconSmall),
            ),
            const SizedBox(width: KSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: KType.corpsFort.copyWith(color: k.texte),
                    ),
                  Text(message, style: KType.corps.copyWith(color: k.texte)),
                  if (actionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: KSpacing.s4),
                      child: KTextButton(
                        key: actionKey,
                        label: actionLabel!,
                        onPressed: onAction,
                        dense: true,
                        alignStart: true,
                      ),
                    ),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                key: closeKey,
                tooltip: closeLabel,
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: k.texte2),
              ),
          ],
        ),
      ),
    );
  }
}

/// État vide ou bloqué (R6) : il dit ce qui manque et propose l'action qui le
/// résout (bouton tonal), jamais un cul-de-sac.
class KEmpty extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final String? action;

  /// Clé du bouton d'action (tests).
  final Key? actionKey;
  final VoidCallback? onAction;
  const KEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.actionKey,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KCard(
      padding: const EdgeInsets.all(KSpacing.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: KSize.menuIcon,
            height: KSize.menuIcon,
            decoration: ShapeDecoration(color: k.haute, shape: KRadius.pill),
            alignment: Alignment.center,
            child: Icon(icon, color: k.texte2, size: KSize.iconSmall),
          ),
          const SizedBox(height: KSpacing.s12),
          Text(title, style: KType.titreCarte.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s4),
          Text(message, style: KType.corps.copyWith(color: k.texte2)),
          if (action != null) ...[
            const SizedBox(height: KSpacing.s16),
            KTonalButton(key: actionKey, label: action!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Jauge en pilule : piste `filet`, remplissage `encre` (ou [color], un
/// état : `validation` pour un objectif atteint). [onFill] : posée sur
/// l'aplat `pleine` (carte du personnage, carte du jour), en `surPleine`.
class KMeter extends StatelessWidget {
  final double value;
  final String label;
  final String? description;
  final Color? color;
  final bool onFill;

  /// Épaisseur (8 par défaut).
  final double height;
  const KMeter({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.color,
    this.onFill = false,
    this.height = KSpacing.s8,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final fill = onFill ? k.surPleine : (color ?? k.encre);
    final track = onFill ? k.surPleine.withValues(alpha: .24) : k.filet;
    return Semantics(
      label: label,
      value: description ?? '${(v * 100).round()} %',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: track, shape: KRadius.pill),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(color: fill, shape: KRadius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tuile chiffrée : grand chiffre (chiffres tabulaires), icône, libellé.
class KStatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const KStatTile(this.value, this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      container: true,
      label: '$label : $value',
      excludeSemantics: true,
      child: KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: KType.chiffre.copyWith(color: k.texte),
                  ),
                ),
                Icon(icon, color: k.encre, size: KSize.iconSmall),
              ],
            ),
            const SizedBox(height: KSpacing.s4),
            Text(label, style: KType.detail.copyWith(color: k.texte2)),
          ],
        ),
      ),
    );
  }
}

/// Grille de tuiles : deux colonnes, une seule à partir de 150 % de texte
/// ou sous 240 dp ; tuiles d'une même rangée à la même hauteur.
class KTileGrid extends StatelessWidget {
  final List<Widget> children;
  const KTileGrid({super.key, required this.children});

  /// Largeur sous laquelle la grille passe à une colonne.
  static const double twoColumnsMin = 240;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
      final count = large || bounds.maxWidth < twoColumnsMin ? 1 : 2;
      const gap = KSpacing.cardGap;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < children.length; r += count) ...[
            if (r > 0) const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = r; c < r + count; c++) ...[
                    if (c > r) const SizedBox(width: gap),
                    Expanded(
                      child: c < children.length
                          ? children[c]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}
