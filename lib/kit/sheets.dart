// UI0 (refonte UI) : gabarits de feuilles et de confirmation (cahier §4.5,
// C10, R8) — feuille d'actions (tous les menus ⋮), feuille de liste (liste
// des exercices, choix de semaine, remplacement), confirmation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Une action d'une feuille d'actions : icône et verbe.
@immutable
class KAction<T> {
  final IconData icon;
  final String label;
  final T value;
  final String? detail;
  final bool danger, enabled;

  /// Couleur d'icône d'un état (douleur : `avertissement`) ; null : `texte`.
  final KActionTone tone;
  const KAction({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.danger = false,
    this.enabled = true,
    this.tone = KActionTone.normal,
  });
}

/// Teinte d'icône d'une action.
enum KActionTone { normal, warning }

AnimationStyle _sheetMotion(BuildContext context) => AnimationStyle(
  duration: KMotion.standard.durationIn(context),
  reverseDuration: KMotion.fast.durationIn(context),
  curve: KMotion.standard.curve,
);

/// Poignée et en-tête communs des feuilles.
class _SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool inline;
  const _SheetHeader({required this.title, this.subtitle, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final head = Text(title, style: KType.titreSeance.copyWith(color: k.texte));
    final sub = subtitle == null
        ? null
        : Text(subtitle!, style: KType.detail.copyWith(color: k.texte2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KSpacing.s12),
        Center(
          child: Container(
            width: KSize.handleWidth,
            height: KSize.handleHeight,
            decoration: ShapeDecoration(color: k.texte3, shape: KRadius.pill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpacing.s4,
            KSpacing.s12,
            KSpacing.s4,
            KSpacing.s4,
          ),
          child: Semantics(
            header: true,
            child: inline && sub != null
                ? Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: KSpacing.s12,
                    children: [head, sub],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [head, if (sub != null) sub],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Feuille d'actions (C10) : poignée, titre et contexte (« Séance — Corps
/// entier, S1, J2 »), groupes d'actions (icône + verbe), dernier groupe =
/// actions destructrices en `danger`, bouton « Fermer ».
class KActionSheet<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<List<KAction<T>>> groups;
  final String closeLabel;
  final ValueChanged<T> onSelected;
  final VoidCallback onClose;
  const KActionSheet({
    super.key,
    required this.title,
    required this.groups,
    required this.onSelected,
    required this.onClose,
    this.subtitle,
    this.closeLabel = 'Fermer',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    Widget row(KAction<T> a, bool last) {
      final ink = !a.enabled
          ? k.texte3
          : a.danger
          ? k.danger
          : k.texte;
      final iconInk = !a.enabled
          ? k.texte3
          : a.danger
          ? k.danger
          : a.tone == KActionTone.warning
          ? k.avertissement
          : k.texte;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: ValueKey('action-${a.value}'),
            onTap: a.enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onSelected(a.value);
                  }
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KSize.primary),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpacing.s16,
                  vertical: KSpacing.s8,
                ),
                child: Row(
                  children: [
                    Icon(a.icon, size: KSize.icon, color: iconInk),
                    const SizedBox(width: KSpacing.s14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            a.label,
                            style: KType.corpsMoyen.copyWith(color: ink),
                          ),
                          if (a.detail != null)
                            Text(
                              a.detail!,
                              style: KType.detail.copyWith(color: k.texte2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!last)
            Divider(
              height: 1,
              thickness: 1,
              indent: KSpacing.s16 + KSize.icon + KSpacing.s14,
              endIndent: KSpacing.s16,
              color: k.filet,
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        0,
        KSpacing.s16,
        KSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: title, subtitle: subtitle),
          for (final g in groups)
            if (g.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Material(
                  color: k.haute,
                  shape: KRadius.menuShape,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < g.length; i++)
                        row(g[i], i == g.length - 1),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: KSpacing.s8),
          TextButton(
            key: const ValueKey('sheet-close'),
            onPressed: onClose,
            style: TextButton.styleFrom(
              foregroundColor: k.texte2,
              minimumSize: const Size.fromHeight(KSize.search),
              shape: KRadius.pill,
              textStyle: KType.corpsFort,
            ),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}

/// Ouvre une feuille d'actions ; rend la valeur de l'action choisie, null si
/// la feuille est fermée sans choix.
Future<T?> showKActionSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<List<KAction<T>>> groups,
  String closeLabel = 'Fermer',
}) {
  assert(
    groups.length < 2 ||
        groups
            .sublist(0, groups.length - 1)
            .every((g) => g.every((a) => !a.danger)),
    'Les actions destructrices vont dans le dernier groupe (C10).',
  );
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    sheetAnimationStyle: _sheetMotion(context),
    builder: (ctx) => SingleChildScrollView(
      child: KActionSheet<T>(
        title: title,
        subtitle: subtitle,
        groups: groups,
        closeLabel: closeLabel,
        onSelected: (v) => Navigator.pop(ctx, v),
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

/// État d'un élément d'une feuille de liste.
enum KListState { todo, current, done }

/// Élément d'une feuille de liste : numéroté, sauf s'il porte une icône
/// (« Bilan du jour »).
@immutable
class KListItem {
  final String title;
  final String? detail;
  final KListState state;
  final IconData? icon;
  final bool enabled;
  const KListItem(
    this.title, {
    this.detail,
    this.state = KListState.todo,
    this.icon,
    this.enabled = true,
  });
}

/// Feuille de liste : poignée, titre et résumé (« 7 exercices, 22 min »),
/// lignes numérotées, élément courant en contour `encre`, éléments faits
/// cochés en `validation`.
class KListSheet extends StatelessWidget {
  final String title;
  final String? summary;
  final List<KListItem> items;
  final ValueChanged<int> onSelected;
  final ScrollController? controller;
  const KListSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
    this.summary,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    var n = 0;
    final numbers = [for (final i in items) i.icon == null ? ++n : 0];
    Widget badge(KListItem it, int number) {
      final current = it.state == KListState.current;
      final done = it.state == KListState.done;
      final Color fill = current
          ? k.pleine
          : (it.icon != null ? Colors.transparent : k.haute);
      final Color ink = current
          ? k.surPleine
          : done
          ? k.validation
          : (it.icon != null ? k.encre : k.texte2);
      return Container(
        width: KSpacing.s32,
        height: KSpacing.s32,
        decoration: ShapeDecoration(color: fill, shape: KRadius.pill),
        alignment: Alignment.center,
        child: done && !current
            ? Icon(Icons.check_rounded, size: KSize.iconSmall, color: ink)
            : it.icon != null
            ? Icon(it.icon, size: KSize.iconSmall, color: ink)
            : Text('$number', style: KType.chiffrePetit.copyWith(color: ink)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        0,
        KSpacing.s16,
        KSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHeader(title: title, subtitle: summary, inline: true),
          const SizedBox(height: KSpacing.s8),
          Flexible(
            child: ListView.separated(
              controller: controller,
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: KSpacing.s4),
              itemBuilder: (context, i) {
                final it = items[i];
                final current = it.state == KListState.current;
                return Semantics(
                  selected: current,
                  child: Material(
                    color: current || it.icon != null
                        ? k.haute
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: KRadius.menuRadius,
                      side: current
                          ? BorderSide(color: k.encre, width: KSize.current)
                          : BorderSide.none,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('list-item-$i'),
                      onTap: it.enabled ? () => onSelected(i) : null,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: KSize.primary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KSpacing.s14,
                            vertical: KSpacing.s8,
                          ),
                          child: Row(
                            children: [
                              badge(it, numbers[i]),
                              const SizedBox(width: KSpacing.s14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      it.title,
                                      style:
                                          (current
                                                  ? KType.corpsFort
                                                  : KType.corpsMoyen)
                                              .copyWith(
                                                color: it.enabled
                                                    ? k.texte
                                                    : k.texte3,
                                              ),
                                    ),
                                    if (it.detail != null)
                                      Text(
                                        it.detail!,
                                        style: KType.detail.copyWith(
                                          color: k.texte2,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ouvre une feuille de liste ; rend l'index choisi, null sans choix.
Future<int?> showKListSheet(
  BuildContext context, {
  required String title,
  String? summary,
  required List<KListItem> items,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  sheetAnimationStyle: _sheetMotion(context),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * .85,
  ),
  builder: (ctx) => KListSheet(
    title: title,
    summary: summary,
    items: items,
    onSelected: (i) => Navigator.pop(ctx, i),
  ),
);

/// Confirmation (R8) : titre = question, une phrase de conséquence,
/// « Annuler » et le verbe exact (« Supprimer », « Remplacer », « Revenir ») ;
/// verbe en `danger` si l'action est destructrice.
class KConfirm extends StatelessWidget {
  final String title, message, confirmLabel, cancelLabel;
  final bool destructive;
  final VoidCallback onConfirm, onCancel;
  const KConfirm({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.cancelLabel = 'Annuler',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    ButtonStyle style(Color bg, Color fg) => FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      minimumSize: const Size(0, KSize.target),
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.s12),
      shape: KRadius.pill,
      textStyle: KType.corpsFort,
    );
    final cancel = FilledButton(
      key: const ValueKey('confirm-cancel'),
      style: style(k.haute, k.texte),
      onPressed: onCancel,
      child: Text(cancelLabel, textAlign: TextAlign.center),
    );
    final confirm = FilledButton(
      key: const ValueKey('confirm-ok'),
      style: destructive
          ? style(k.danger, k.roles.surDanger)
          : style(k.pleine, k.surPleine),
      onPressed: onConfirm,
      child: Text(confirmLabel, textAlign: TextAlign.center),
    );
    return Dialog(
      backgroundColor: k.surface,
      shape: KRadius.cardShape,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s24,
        vertical: KSpacing.s24,
      ),
      child: Padding(
        padding: const EdgeInsets.all(KSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: KType.titreSeance.copyWith(color: k.texte),
              ),
            ),
            const SizedBox(height: KSpacing.s8),
            Text(message, style: KType.corps.copyWith(color: k.texte2)),
            const SizedBox(height: KSpacing.s24),
            LayoutBuilder(
              builder: (context, c) {
                // Grand texte : boutons l'un sous l'autre, le verbe en haut.
                final stacked =
                    c.maxWidth <
                    2 *
                        KSize.valueWidth *
                        MediaQuery.textScalerOf(context).scale(1);
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      confirm,
                      const SizedBox(height: KSpacing.s8),
                      cancel,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(child: confirm),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre une confirmation ; vrai seulement si le verbe est choisi.
Future<bool> showKConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => KConfirm(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onConfirm: () => Navigator.pop(ctx, true),
      onCancel: () => Navigator.pop(ctx, false),
    ),
  );
  return ok ?? false;
}
