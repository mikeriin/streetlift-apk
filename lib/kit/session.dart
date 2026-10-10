// UI0 (refonte UI) : composants de la séance (cahier §5.4, C8, C13) —
// tableau des séries, barre de repos flottante, message court.
import 'package:flutter/material.dart';

import 'buttons.dart';
import 'tokens.dart';

/// État d'une ligne du tableau des séries.
enum KSetState { upcoming, current, done }

/// Champ du tableau des séries : pilule de 48 dp, chiffre centré (20,
/// chiffres tabulaires). Sans [onTap], valeur seulement.
class KSetField extends StatelessWidget {
  final String value;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final bool onSurface, dimmed;
  const KSetField(
    this.value, {
    super.key,
    this.semanticLabel,
    this.onTap,
    this.onSurface = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      label: semanticLabel,
      value: value,
      button: onTap != null,
      excludeSemantics: true,
      child: Material(
        color: onSurface ? k.surface : k.haute,
        shape: KRadius.pill,
        child: InkWell(
          customBorder: KRadius.pill,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KSize.target),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: KSpacing.s8),
                // Un nombre reste entier : il se réduit plutôt que de passer
                // à la ligne (cahier §5.2).
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: KType.chiffreMoyen.copyWith(
                      color: dimmed ? k.texte3 : k.texte,
                    ),
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

/// Une ligne du tableau des séries : numéro, champs, action (validation,
/// chrono). La ligne courante a le fond `haute` et le contour `encre`.
class KSetRow extends StatelessWidget {
  final String number;
  final List<Widget> cells;
  final List<Widget> actions;
  final KSetState state;
  final Widget? below;
  const KSetRow({
    super.key,
    required this.number,
    required this.cells,
    this.actions = const [],
    this.state = KSetState.upcoming,
    this.below,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final current = state == KSetState.current;
    final row = Row(
      children: [
        SizedBox(
          width: KSize.target - KSpacing.s4,
          child: Text(
            number,
            style: KType.chiffrePetit.copyWith(
              color: current
                  ? k.texte
                  : state == KSetState.done
                  ? k.texte2
                  : k.texte2,
              fontWeight: current ? FontWeight.w600 : null,
            ),
          ),
        ),
        for (final c in cells) ...[
          Expanded(child: c),
          const SizedBox(width: KSpacing.s8),
        ],
        for (final a in actions)
          SizedBox(
            width: KSize.target,
            child: Center(child: a),
          ),
      ],
    );
    final content = below == null
        ? row
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [row, below!],
          );
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpacing.s8,
        KSpacing.s4,
        KSpacing.s4,
        KSpacing.s4,
      ),
      decoration: current
          ? ShapeDecoration(
              color: k.haute,
              shape: RoundedRectangleBorder(
                borderRadius: KRadius.menuRadius,
                side: BorderSide(color: k.encre, width: KSize.current),
              ),
            )
          : null,
      child: content,
    );
  }
}

/// Tableau des séries : en-tête (N°, colonnes, place des actions), puis les
/// lignes [KSetRow].
class KSetTable extends StatelessWidget {
  final List<String> columns;
  final int actionCount;
  final List<KSetRow> rows;
  final String numberLabel;
  const KSetTable({
    super.key,
    required this.columns,
    required this.rows,
    this.actionCount = 1,
    this.numberLabel = 'N°',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final head = KType.detail.copyWith(color: k.texte2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            KSpacing.s8,
            0,
            KSpacing.s4,
            KSpacing.s4,
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                SizedBox(
                  width: KSize.target - KSpacing.s4,
                  child: Text(numberLabel, style: head),
                ),
                for (final c in columns) ...[
                  Expanded(
                    child: Text(c, style: head, textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: KSpacing.s8),
                ],
                SizedBox(width: KSize.target * actionCount),
              ],
            ),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: KSpacing.s4),
          rows[i],
        ],
      ],
    );
  }
}

/// Barre de repos flottante (C8 : seul élément flottant en bas, le message
/// de Koach se pose au-dessus) : progression, « Repos » et temps restant,
/// groupe −15 s / +15 s (pilules séparées de 4), arrêt.
class KRestBar extends StatelessWidget {
  final String remaining;
  final double progress;
  final String label;
  final VoidCallback? onMinus, onPlus, onStop;
  final String minusLabel, plusLabel, stopLabel;
  const KRestBar({
    super.key,
    required this.remaining,
    required this.progress,
    this.label = 'Repos',
    this.onMinus,
    this.onPlus,
    this.onStop,
    this.minusLabel = '−15 s',
    this.plusLabel = '+15 s',
    this.stopLabel = 'Arrêter le repos',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    Widget small(String text, VoidCallback? onTap) => FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: k.surface,
        foregroundColor: k.texte,
        minimumSize: const Size(KSize.target, KSize.target),
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.s12),
        shape: KRadius.pill,
        textStyle: KType.libelle,
      ),
      child: Text(text),
    );
    final v = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return Material(
      color: k.haute,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.cardRadius,
        side: BorderSide(color: k.filet),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '$label restant',
            value: remaining,
            child: SizedBox(
              height: KSpacing.s4,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: ColoredBox(color: k.encre),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpacing.s20,
              KSpacing.s8,
              KSpacing.s12,
              KSpacing.s12,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final time = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: KType.micro.copyWith(color: k.texte2)),
                    Text(
                      remaining,
                      style: KType.chrono.copyWith(color: k.texte),
                    ),
                  ],
                );
                final stop = Tooltip(
                  message: stopLabel,
                  child: Semantics(
                    button: true,
                    label: stopLabel,
                    excludeSemantics: true,
                    onTap: onStop,
                    child: Material(
                      color: k.pleine,
                      shape: KRadius.pill,
                      child: InkWell(
                        customBorder: KRadius.pill,
                        onTap: onStop,
                        child: SizedBox.square(
                          dimension: KSize.target,
                          child: Icon(
                            Icons.stop_rounded,
                            color: k.surPleine,
                            size: KSize.icon,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                final buttons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    small(minusLabel, onMinus),
                    const SizedBox(width: KSpacing.s4),
                    small(plusLabel, onPlus),
                    const SizedBox(width: KSpacing.s8),
                    stop,
                  ],
                );
                // Grand texte ou écran étroit : les commandes passent sous
                // le temps restant (rien n'est coupé).
                final scale = MediaQuery.textScalerOf(context).scale(1);
                if (c.maxWidth < KSize.restBarMin * scale) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      time,
                      const SizedBox(height: KSpacing.s8),
                      Wrap(
                        spacing: KSpacing.s4,
                        runSpacing: KSpacing.s4,
                        children: [
                          small(minusLabel, onMinus),
                          small(plusLabel, onPlus),
                          stop,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: time),
                    buttons,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Message court (Koach compris) : pilule `texte` sur `fond` inversé,
/// illustration facultative à gauche, action facultative. Posé au-dessus de
/// la barre de repos ou du dock, jamais dessus (C8).
class KSnack extends StatelessWidget {
  final String message;
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;
  const KSnack({
    super.key,
    required this.message,
    this.leading,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: k.texte,
        shape: KRadius.menuShape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.search),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpacing.s16,
              KSpacing.s4,
              KSpacing.s4,
              KSpacing.s4,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: KSpacing.s12),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: KSpacing.s8),
                    child: Text(
                      message,
                      style: KType.libelle.copyWith(
                        color: k.fond,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (actionLabel != null)
                  KTextButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    color: k.fond,
                    dense: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Affiche [KSnack] au-dessus du dock (ou de [bottom], hauteur occupée en
/// bas : barre de repos) pendant [duration].
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showKSnack(
  BuildContext context, {
  required String message,
  Widget? leading,
  String? actionLabel,
  VoidCallback? onAction,
  double bottom = 0,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.fromLTRB(
        KSpacing.s16,
        0,
        KSpacing.s16,
        KSpacing.s12 + bottom,
      ),
      duration: duration,
      content: KSnack(
        message: message,
        leading: leading,
        actionLabel: actionLabel,
        onAction: () {
          messenger.hideCurrentSnackBar();
          onAction?.call();
        },
      ),
    ),
  );
}
