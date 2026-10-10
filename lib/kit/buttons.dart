// UI0 (refonte UI) : hiérarchie unique des actions (C2) — un bouton plein au
// plus par écran (action principale, 56 dp), actions secondaires en bouton
// tonal (48 dp), lien texte seulement pour « Pourquoi ? », « Modifier »,
// « Passer ». Toutes les commandes sont en pilule (cahier §5.3).
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Bouton principal : aplat `pleine`, texte `surPleine`, 56 dp, pleine
/// largeur par défaut.
class KPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;

  /// Action destructrice confirmée (verbe « Supprimer ») : aplat `danger`.
  final bool danger;
  const KPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: danger ? k.danger : k.pleine,
      foregroundColor: danger ? k.roles.surDanger : k.surPleine,
      disabledBackgroundColor: k.haute,
      disabledForegroundColor: k.texte3,
      minimumSize: Size(
        expand ? double.infinity : KSize.primary,
        KSize.primary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s24,
        vertical: KSpacing.s14,
      ),
      shape: KRadius.pill,
      textStyle: KType.corpsFort,
    );
    final text = Text(label, textAlign: TextAlign.center);
    return icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: text)
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: KSize.iconSmall),
            label: text,
          );
  }
}

/// Action secondaire : fond `haute`, texte `texte`, 48 dp.
class KTonalButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  const KTonalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final style = FilledButton.styleFrom(
      backgroundColor: k.haute,
      foregroundColor: k.texte,
      disabledBackgroundColor: k.haute,
      disabledForegroundColor: k.texte3,
      minimumSize: Size(expand ? double.infinity : KSize.target, KSize.target),
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s20,
        vertical: KSpacing.s12,
      ),
      shape: KRadius.pill,
      textStyle: KType.corpsFort,
    );
    final text = Text(label, textAlign: TextAlign.center);
    return icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: text)
        : FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: KSize.iconSmall),
            label: text,
          );
  }
}

/// Lien texte : `encre`, cible de 48 dp ([dense] : 48 dp de haut, marges
/// réduites, pour une ligne de texte).
class KTextButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool dense, alignStart;
  final Color? color;
  const KTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.dense = false,
    this.alignStart = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final style = TextButton.styleFrom(
      foregroundColor: color ?? k.encre,
      disabledForegroundColor: k.texte3,
      minimumSize: const Size(KSize.target, KSize.target),
      // Aligné au texte (lien sous un message) : sans marge à gauche.
      padding: alignStart
          ? const EdgeInsetsDirectional.only(end: KSpacing.s8)
          : EdgeInsets.symmetric(
              horizontal: dense ? KSpacing.s8 : KSpacing.s12,
            ),
      alignment: alignStart ? AlignmentDirectional.centerStart : null,
      shape: KRadius.pill,
      textStyle: KType.libelle,
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    final text = Text(label);
    return icon == null
        ? TextButton(style: style, onPressed: onPressed, child: text)
        : TextButton.icon(
            style: style,
            onPressed: onPressed,
            icon: Icon(icon, size: KSize.iconSmall),
            label: text,
          );
  }
}

/// Bouton-icône nommé (C13 : 48 dp, `tooltip` obligatoire pour l'accessibilité).
class KIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;
  const KIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.filled = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled ? k.haute : null,
        foregroundColor: color ?? k.texte,
        disabledForegroundColor: k.texte3,
        minimumSize: const Size(KSize.target, KSize.target),
        shape: KRadius.pill,
      ),
      icon: Icon(icon, size: KSize.icon),
    );
  }
}
