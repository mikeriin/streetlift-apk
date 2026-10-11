// UI0 (refonte UI) : gabarits de feuilles et de confirmation (cahier §4.5,
// C10, R8) — feuille d'actions (tous les menus ⋮), feuille de liste (liste
// des exercices, choix de semaine, remplacement), confirmation.
// UI5 : feuille de contenu unique (`KContentSheet`, issue de la feuille de
// contenu de la séance, de la feuille d'information de Stats et de la
// feuille du Programme), confirmation à contenu libre et clés par bouton,
// feuille de liste ouverte sur un élément.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../koach/koach_view.dart' show KoachSurface;
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

/// Poignée et en-tête communs des feuilles (actions, liste, contenu) : titre
/// en casse normale (U0.17 : une feuille se lit comme une phrase), contexte
/// facultatif. [inline] : contexte à droite du titre quand la place le
/// permet (feuille de liste).
class KSheetHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final bool inline;
  const KSheetHeader({
    super.key,
    this.title,
    this.subtitle,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final head = title == null
        ? null
        : Text(title!, style: KType.titreSeance.copyWith(color: k.texte));
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
        if (head != null || sub != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpacing.s4,
              KSpacing.s12,
              KSpacing.s4,
              KSpacing.s4,
            ),
            child: Semantics(
              header: true,
              child: inline && head != null && sub != null
                  ? Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: KSpacing.s12,
                      children: [head, sub],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [if (head != null) head, if (sub != null) sub],
                    ),
            ),
          )
        else
          const SizedBox(height: KSpacing.s8),
      ],
    );
  }
}

/// Bouton « Fermer » des feuilles (clé `sheet-close`).
class KSheetCloseButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const KSheetCloseButton({
    super.key,
    required this.onPressed,
    this.label = 'Fermer',
  });

  @override
  Widget build(BuildContext context) => TextButton(
    key: const ValueKey('sheet-close'),
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: KTokens.of(context).texte2,
      minimumSize: const Size.fromHeight(KSize.search),
      shape: KRadius.pill,
      textStyle: KType.corpsFort,
    ),
    child: Text(label),
  );
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
          KSheetHeader(title: title, subtitle: subtitle),
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
          KSheetCloseButton(onPressed: onClose, label: closeLabel),
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
        decoration: ShapeDecoration(
          color: fill,
          shape: current || it.icon != null ? KRadius.pill : k.controlPill,
        ),
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
          KSheetHeader(title: title, subtitle: summary, inline: true),
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
/// [initial] : élément visible à l'ouverture (choix parmi 40 semaines : la
/// semaine affichée apparaît d'emblée, deux lignes de voisinage au-dessus).
Future<int?> showKListSheet(
  BuildContext context, {
  required String title,
  String? summary,
  required List<KListItem> items,
  int initial = 0,
}) {
  ScrollController? controller;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    sheetAnimationStyle: _sheetMotion(context),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (ctx) => LayoutBuilder(
      builder: (ctx, c) {
        controller ??= ScrollController(
          initialScrollOffset: initial > 2
              ? _listOffset(ctx, items, initial - 2, c.maxWidth)
              : 0,
        );
        return KListSheet(
          title: title,
          summary: summary,
          items: items,
          controller: controller,
          onSelected: (i) => Navigator.pop(ctx, i),
        );
      },
    ),
  ).whenComplete(() => controller?.dispose());
}

/// Hauteur des [count] premières lignes d'une feuille de liste (mêmes
/// marges et styles que [KListSheet]) pour une largeur [width].
double _listOffset(
  BuildContext context,
  List<KListItem> items,
  int count,
  double width,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final text =
      width - 2 * KSpacing.s16 - 2 * KSpacing.s14 - KSpacing.s32 - KSpacing.s14;
  double measure(String s, TextStyle style) {
    final p = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: text > 0 ? text : width);
    final h = p.height;
    p.dispose();
    return h;
  }

  var y = 0.0;
  for (var i = 0; i < count && i < items.length; i++) {
    final it = items[i];
    var h = measure(it.title, KType.corpsMoyen) + 2 * KSpacing.s8;
    if (it.detail != null) h += measure(it.detail!, KType.detail);
    y += (h < KSize.primary ? KSize.primary : h) + KSpacing.s4;
  }
  return y;
}

/// Feuille de contenu (UI5 : une seule pour toute l'application, issue des
/// feuilles de contenu de la séance, d'information de Stats et de contenu du
/// Programme) : poignée, titre et contexte, contenu qui défile (consignes,
/// détail d'une semaine, informations de jeu, petit formulaire), bouton
/// « Fermer » toujours visible en bas. Fond `surface` ; Koach posé dessus
/// prend cette couleur pour papier.
class KContentSheet extends StatelessWidget {
  final String? title, subtitle;
  final List<Widget> children;

  /// Libellé du bouton du bas ; nul : pas de bouton (le contenu porte sa
  /// propre action, « Enregistrer » par exemple).
  final String? closeLabel;
  final VoidCallback? onClose;
  final ScrollController? controller;
  final double gap;

  /// Clé de la liste qui défile (tests, défilement jusqu'à un élément).
  final Key? listKey;

  /// Faux dans une feuille qu'on agrandit en la tirant : la liste prend
  /// toute la hauteur donnée.
  final bool shrinkWrap;
  const KContentSheet({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.closeLabel = 'Fermer',
    this.onClose,
    this.controller,
    this.gap = KSpacing.s12,
    this.listKey,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KoachSurface(
      color: k.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s16),
            child: KSheetHeader(title: title, subtitle: subtitle),
          ),
          Flexible(
            child: DefaultTextStyle.merge(
              style: KType.corps.copyWith(color: k.texte),
              child: ListView.separated(
                key: listKey,
                controller: controller,
                shrinkWrap: shrinkWrap,
                padding: EdgeInsets.fromLTRB(
                  KSpacing.page,
                  KSpacing.s8,
                  KSpacing.page,
                  closeLabel == null
                      ? KSpacing.s24 + MediaQuery.paddingOf(context).bottom
                      : KSpacing.s8,
                ),
                itemCount: children.length,
                separatorBuilder: (_, __) => SizedBox(height: gap),
                itemBuilder: (_, i) => children[i],
              ),
            ),
          ),
          if (closeLabel != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                KSpacing.s16,
                0,
                KSpacing.s16,
                KSpacing.s16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: KSheetCloseButton(
                label: closeLabel!,
                onPressed: onClose ?? () => Navigator.maybePop(context),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ouvre une feuille de contenu ([KContentSheet]) ; [builder] (un seul
/// bloc) ou [children] (plusieurs, séparés de [gap]) reçoivent le contexte
/// de la feuille : `Navigator.pop(context, valeur)` la referme avec un
/// résultat. [draggable] : feuille haute qu'on agrandit en la tirant
/// (contenu long). 90 % de l'écran au plus sinon.
Future<T?> showKContentSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  WidgetBuilder? builder,
  List<Widget> Function(BuildContext context)? children,
  String? closeLabel = 'Fermer',
  bool draggable = false,
  double gap = KSpacing.s12,
  Key? contentKey,
}) {
  assert(
    (builder == null) != (children == null),
    'showKContentSheet : builder ou children, l\'un des deux.',
  );
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: KTokens.of(context).surface,
    sheetAnimationStyle: _sheetMotion(context),
    constraints: draggable
        ? null
        : BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    builder: (ctx) {
      List<Widget> items() => builder != null ? [builder(ctx)] : children!(ctx);
      Widget sheet({ScrollController? controller, bool shrink = true}) =>
          KContentSheet(
            title: title,
            subtitle: subtitle,
            closeLabel: closeLabel,
            onClose: () => Navigator.pop(ctx),
            controller: controller,
            gap: gap,
            listKey: contentKey,
            shrinkWrap: shrink,
            children: items(),
          );
      return draggable
          ? DraggableScrollableSheet(
              expand: false,
              initialChildSize: .7,
              maxChildSize: .94,
              builder: (_, controller) =>
                  sheet(controller: controller, shrink: false),
            )
          : sheet();
    },
  );
}

/// Confirmation (R8, §4.5) : titre = question, une phrase de conséquence
/// (et un contenu libre facultatif, qui défile), « Annuler » et le verbe
/// exact (« Supprimer », « Remplacer », « Revenir ») ; verbe en `danger` si
/// l'action est destructrice. Les deux boutons restent toujours visibles en
/// bas (petit écran, grand texte). Clés par bouton : [confirmKey]
/// (`confirm-ok` par défaut) et [cancelKey] (`confirm-cancel`).
class KConfirm extends StatelessWidget {
  final String title, confirmLabel, cancelLabel;
  final String? message;
  final Widget? body;
  final IconData? icon;
  final Color? iconColor;
  final Key? confirmKey, cancelKey;
  final bool destructive;
  final VoidCallback onConfirm, onCancel;
  const KConfirm({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    this.message,
    this.body,
    this.icon,
    this.iconColor,
    this.confirmKey,
    this.cancelKey,
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
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s12,
        vertical: KSpacing.s12,
      ),
      shape: KRadius.pill,
      textStyle: KType.corpsFort,
    );
    final cancel = FilledButton(
      key: cancelKey ?? const ValueKey('confirm-cancel'),
      style: style(
        k.haute,
        k.texte,
      ).copyWith(side: WidgetStatePropertyAll(k.controlSide)),
      onPressed: onCancel,
      child: Text(cancelLabel, textAlign: TextAlign.center),
    );
    final confirm = FilledButton(
      key: confirmKey ?? const ValueKey('confirm-ok'),
      style: destructive
          ? style(k.danger, k.roles.surDanger)
          : style(k.pleine, k.surPleine),
      onPressed: onConfirm,
      child: Text(confirmLabel, textAlign: TextAlign.center),
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Icon(icon, size: KSize.icon, color: iconColor ?? k.encre),
          ),
          const SizedBox(height: KSpacing.s12),
        ],
        Semantics(
          header: true,
          child: Text(title, style: KType.titreSeance.copyWith(color: k.texte)),
        ),
        if (message != null) ...[
          const SizedBox(height: KSpacing.s8),
          Text(message!, style: KType.corps.copyWith(color: k.texte2)),
        ],
        if (body != null) ...[
          const SizedBox(height: KSpacing.s8),
          DefaultTextStyle.merge(
            style: KType.corps.copyWith(color: k.texte2),
            child: body!,
          ),
        ],
      ],
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
            Flexible(child: SingleChildScrollView(child: content)),
            const SizedBox(height: KSpacing.s24),
            LayoutBuilder(
              builder: (context, c) {
                // Libellés longs ou grand texte : boutons l'un sous
                // l'autre, le verbe en haut.
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final stacked =
                    confirmLabel.length + cancelLabel.length > 24 ||
                    c.maxWidth < 4 * KSize.target * scale;
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
  Key? confirmKey,
  Key? cancelKey,
}) => showKChoice(
  context,
  title: title,
  message: message,
  confirmLabel: confirmLabel,
  cancelLabel: cancelLabel,
  destructive: destructive,
  confirmKey: confirmKey,
  cancelKey: cancelKey,
);

/// Ouvre une confirmation [KConfirm] au contenu libre ([body]) et à l'icône
/// d'état facultatifs ; [required] : on n'en sort que par un des deux
/// boutons (ni retour système, ni appui à côté : avis médical avant la
/// séance). Vrai seulement si le verbe est choisi.
Future<bool> showKChoice(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  IconData? icon,
  Color? iconColor,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  Key? dialogKey,
  Key? confirmKey,
  Key? cancelKey,
  bool destructive = false,
  bool required = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: !required,
    builder: (ctx) {
      final dialog = KConfirm(
        key: dialogKey,
        title: title,
        message: message,
        body: body,
        icon: icon,
        iconColor: iconColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmKey: confirmKey,
        cancelKey: cancelKey,
        destructive: destructive,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      );
      return required ? PopScope(canPop: false, child: dialog) : dialog;
    },
  );
  return ok ?? false;
}
