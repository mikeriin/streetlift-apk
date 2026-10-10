// Briques communes de l'onglet Stats (UI3, refonte UI) : liste des onglets,
// introduction d'un onglet, jauge, tuile chiffrée, grille, paragraphes et
// feuille d'information. Tout passe par les jetons du kit (cahier §5) :
// aucune valeur de présentation écrite ici.
import 'package:flutter/material.dart';

import 'kit/kit.dart';
import 'stats/widgets/k_info_sheet.dart';

String statsNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1).replaceAll('.', ',');
String statsDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

/// Contenu défilant d'un onglet de Stats : marge d'écran, écart entre
/// cartes, réserve du dock en bas (C8).
class StatsList extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  const StatsList({super.key, required this.children, this.controller});

  @override
  Widget build(BuildContext context) => ListView.separated(
    controller: controller,
    padding: EdgeInsets.fromLTRB(
      KSpacing.page,
      KSpacing.s12,
      KSpacing.page,
      KSpacing.s24 + KNavigationInset.of(context),
    ),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    itemCount: children.length,
    separatorBuilder: (_, __) => const SizedBox(height: KSpacing.cardGap),
    itemBuilder: (_, i) => children[i],
  );
}

/// Introduction d'un onglet : titre de carte et une phrase.
class StatsIntro extends StatelessWidget {
  final String title;
  final String? lead;
  const StatsIntro(this.title, {super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: KFitTitle(
              title,
              style: KType.titreCarte.copyWith(color: k.texte),
            ),
          ),
          if (lead != null)
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s4),
              child: Text(
                lead!,
                style: KType.corps.copyWith(color: k.texte2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paragraphe d'une page ou d'une feuille : texte courant ([muted] :
/// `texte2`, pour une précision).
class StatsText extends StatelessWidget {
  final String text;
  final bool muted;
  const StatsText(this.text, {super.key, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
      child: Text(
        text,
        style: (muted ? KType.detail : KType.corps).copyWith(
          color: muted ? k.texte2 : k.texte,
        ),
      ),
    );
  }
}

/// Jauge en pilule : piste `filet`, remplissage `encre` (ou [color], un
/// état : `validation` pour un objectif atteint). [onFill] : posée sur
/// l'aplat `pleine` (carte du personnage), en `surPleine`.
class StatsBar extends StatelessWidget {
  final double value;
  final String label;
  final String? description;
  final Color? color;
  final bool onFill;
  const StatsBar({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.color,
    this.onFill = false,
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
        height: KSpacing.s8,
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
class StatsMetric extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const StatsMetric(this.value, this.label, this.icon, {super.key});

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
/// ou sous 240 dp.
class StatsGrid extends StatelessWidget {
  final List<Widget> children;
  const StatsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
      final count = large || bounds.maxWidth < 240 ? 1 : 2;
      const gap = KSpacing.cardGap;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(
              width: (bounds.maxWidth - gap * (count - 1)) / count,
              child: child,
            ),
        ],
      );
    },
  );
}

/// Groupe de lignes d'une feuille : conteneur `haute` au rayon des menus
/// (la feuille est en `surface`).
class StatsSheetGroup extends StatelessWidget {
  final List<Widget> children;
  const StatsSheetGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) => KMenuGroup(
    color: KTokens.of(context).haute,
    dividerIndent: KSpacing.s16 + KSize.icon + KSpacing.s14,
    children: children,
  );
}

/// Ligne d'une feuille : icône d'état, titre, précision, valeur à droite.
class StatsSheetRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final Color? iconColor;
  final String title;
  final String? subtitle, value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  const StatsSheetRow({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.iconColor,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KMenuRow(
      title: title,
      subtitle: subtitle,
      value: value,
      enabled: enabled,
      chevron: false,
      onTap: onTap,
      minHeight: KSize.primary,
      leading:
          leading ??
          (icon == null
              ? null
              : Icon(
                  icon,
                  size: KSize.icon,
                  color: enabled ? (iconColor ?? k.texte2) : k.texte3,
                )),
      trailing: trailing,
    );
  }
}

/// Feuille d'information de Stats (gabarit de `KInfoSheet`).
Future<void> statsSheet(
  BuildContext context,
  String title,
  List<Widget> children, {
  String? subtitle,
  String closeLabel = 'Fermer',
}) => showKInfoSheet(
  context,
  title: title,
  subtitle: subtitle,
  closeLabel: closeLabel,
  children: children,
);
