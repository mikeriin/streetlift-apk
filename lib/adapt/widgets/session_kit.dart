// UI2 (refonte UI, séance) : composants manquants au kit, créés dans la zone
// du lot (cahier §7.2) et signalés à UI5 pour être promus dans `lib/kit/`
// (LIVRAISON_UI2.md, « Composants à promouvoir »).
//
// - [showKContentSheet] : feuille de contenu (consignes, douleur d'une zone,
//   estimation) — même anatomie que les feuilles du kit (poignée, titre et
//   contexte, contenu, « Fermer »). Les cinq gabarits du cahier (§4.5)
//   couvrent les choix et les actions ; une feuille qui montre un texte ou
//   un petit formulaire n'y entre pas.
// - [KChoiceDialog] / [showKRequiredChoice] : confirmation au gabarit
//   [KConfirm] dont on ne sort que par un des deux boutons (avis médical
//   avant la séance), avec des clés de boutons nommées.
//
// Ces deux fonctions sont les seules de la zone UI2 à ouvrir une route de
// feuille ou de dialogue sans passer par le kit : à déplacer telles quelles
// dans `lib/kit/sheets.dart` (UI5).
import 'package:flutter/material.dart';

import '../../kit/kit.dart';

/// En-tête commun des feuilles : poignée, titre (`titreSeance`) et contexte.
class KSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const KSheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
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
            KSpacing.s8,
          ),
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KType.titreSeance.copyWith(color: k.texte)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: KType.detail.copyWith(color: k.texte2),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Feuille de contenu : poignée, titre et contexte, contenu qui défile,
/// bouton « Fermer » (sauf [closeLabel] nul : le contenu porte sa propre
/// action, « Enregistrer » par exemple). [builder] reçoit le contexte de la
/// feuille : `Navigator.pop(context, valeur)` la referme avec un résultat.
Future<T?> showKContentSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required WidgetBuilder builder,
  String? closeLabel = 'Fermer',
  Key? contentKey,
}) {
  final navigator = Navigator.of(context);
  final loc = MaterialLocalizations.of(context);
  final height = MediaQuery.sizeOf(context).height;
  return navigator.push(
    ModalBottomSheetRoute<T>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      barrierLabel: loc.scrimLabel,
      barrierOnTapHint: loc.scrimOnTapHint(loc.bottomSheetLabel),
      constraints: BoxConstraints(maxHeight: height * .9),
      sheetAnimationStyle: AnimationStyle(
        duration: KMotion.standard.durationIn(context),
        reverseDuration: KMotion.fast.durationIn(context),
        curve: KMotion.standard.curve,
      ),
      builder: (ctx) {
        final k = KTokens.of(ctx);
        return SingleChildScrollView(
          key: contentKey,
          padding: const EdgeInsets.only(
            left: KSpacing.s16,
            right: KSpacing.s16,
            bottom: KSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              KSheetHeader(title: title, subtitle: subtitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
                child: DefaultTextStyle.merge(
                  style: KType.corps.copyWith(color: k.texte),
                  child: builder(ctx),
                ),
              ),
              if (closeLabel != null) ...[
                const SizedBox(height: KSpacing.s8),
                TextButton(
                  key: const ValueKey('sheet-close'),
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: k.texte2,
                    minimumSize: const Size.fromHeight(KSize.search),
                    shape: KRadius.pill,
                    textStyle: KType.corpsFort,
                  ),
                  child: Text(closeLabel),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}

/// Confirmation au gabarit [KConfirm] (titre = question, conséquence,
/// deux boutons), avec un contenu libre ([body]), une icône d'état
/// facultative et des clés de boutons nommées.
class KChoiceDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? body;
  final IconData? icon;
  final Color? iconColor;
  final String confirmLabel, cancelLabel;
  final Key? confirmKey, cancelKey;
  final bool destructive;
  final VoidCallback onConfirm, onCancel;
  const KChoiceDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.message,
    this.body,
    this.icon,
    this.iconColor,
    this.confirmKey,
    this.cancelKey,
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
      key: cancelKey,
      style: style(
        k.haute,
        k.texte,
      ).copyWith(side: WidgetStatePropertyAll(k.controlSide)),
      onPressed: onCancel,
      child: Text(cancelLabel, textAlign: TextAlign.center),
    );
    final confirm = FilledButton(
      key: confirmKey,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(
                  icon,
                  size: KSize.icon,
                  color: iconColor ?? k.encre,
                ),
              ),
              const SizedBox(height: KSpacing.s12),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                style: KType.titreSeance.copyWith(color: k.texte),
              ),
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
            const SizedBox(height: KSpacing.s24),
            LayoutBuilder(
              builder: (context, c) {
                // Libellé long ou grand texte : boutons l'un sous l'autre,
                // le verbe en haut (même règle que KConfirm).
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final long =
                    confirmLabel.length + cancelLabel.length > 24 ||
                    c.maxWidth < 4 * KSize.target * scale;
                if (long) {
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

/// Ouvre [KChoiceDialog] ; [required] : on n'en sort que par un des deux
/// boutons (ni retour système, ni appui à côté). Vrai seulement si le verbe
/// est choisi.
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
  final navigator = Navigator.of(context);
  final ok = await navigator.push<bool>(
    DialogRoute<bool>(
      context: context,
      barrierDismissible: !required,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (ctx) {
        final dialog = KChoiceDialog(
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
    ),
  );
  return ok ?? false;
}
