// G9 (D5.3-D5.5) : note de chaque série en flammes, à la validation.
//
// Le sélecteur s'ouvre pré-rempli avec la flamme visée : un appui sur
// « Valider » (ou sur la flamme visée) confirme ; un appui sur une autre
// flamme la choisit et valide ; glisser le long de la rangée change la
// flamme choisie sans valider. « Je ne sais pas », discret, valide la série
// sans note (le moteur la traite comme telle). Fermer la feuille : rien ne
// change, la série reste non validée.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' show Flames;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../koach/flame_icon.dart';
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart' show KoachSurface;

/// Choix fait dans la feuille.
class FlameChoice {
  /// Flammes (1 à 10) ; null avec [unknown].
  final int? flames;
  final bool unknown;

  /// Série écartée (incident), en modification seulement.
  final bool excluded;
  const FlameChoice({this.flames, this.unknown = false, this.excluded = false});
}

/// « 7 flammes · RIR 2 », « 10 flammes · échec ».
String flameValueText(int f) {
  if (f == Flames.failure) return '10 flammes · échec (RIR 0)';
  return '$f flamme${f > 1 ? 's' : ''} · RIR ${flameRirText(f)}';
}

/// Phrase du premier usage : l'échelle en une ligne.
const kFlamesIntro =
    'Note chaque série en flammes : 10 = échec, plus aucune répétition '
    'possible ; 1 = encore 5 répétitions ou plus en réserve. La flamme '
    'visée est déjà choisie : un appui pour confirmer.';

Future<FlameChoice?> showFlameSheet(
  BuildContext context, {
  required String title,
  int? target,
  int? current,
  bool editing = false,
  bool excluded = false,
  bool intro = false,
}) => showModalBottomSheet<FlameChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => KoachSurface(
    color:
        Theme.of(context).bottomSheetTheme.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerLow,
    child: _FlameSheet(
      title: title,
      target: target,
      current: current ?? target,
      editing: editing,
      excluded: excluded,
      intro: intro,
    ),
  ),
);

class _FlameSheet extends StatefulWidget {
  final String title;
  final int? target;
  final int? current;
  final bool editing;
  final bool excluded;
  final bool intro;
  const _FlameSheet({
    required this.title,
    required this.target,
    required this.current,
    required this.editing,
    required this.excluded,
    required this.intro,
  });

  @override
  State<_FlameSheet> createState() => _FlameSheetState();
}

class _FlameSheetState extends State<_FlameSheet> {
  int? _value;
  late bool _excluded;
  final GlobalKey _rowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _value = widget.current;
    _excluded = widget.excluded;
  }

  void _pick(int f) =>
      Navigator.of(context).pop(FlameChoice(flames: f, excluded: _excluded));

  void _dragTo(Offset global) {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(global);
    final cell = box.size.width / Flames.max;
    final f = (local.dx / cell).floor().clamp(0, Flames.max - 1) + 1;
    if (f != _value) setState(() => _value = f);
  }

  @override
  Widget build(BuildContext context) {
    final v = _value;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      key: const ValueKey('flame-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.title, style: text.titleLarge),
          const SizedBox(height: 8),
          if (widget.intro)
            KoachSays(
              key: const ValueKey('flame-intro'),
              pose: KoachPose.explainBoard,
              koachHeight: 64,
              child: Text(kFlamesIntro, style: text.bodyMedium),
            )
          else if (widget.target != null)
            Text(
              'Visée : ${flameValueText(widget.target!)}',
              key: const ValueKey('flame-target'),
              style: TextStyle(color: SL.dim),
            ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (v != null) FlameIcon(v, size: 48, semantics: false),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    v == null ? 'Choisis une flamme' : flameValueText(v),
                    key: const ValueKey('flame-sheet-value'),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _dragTo(d.globalPosition),
            onHorizontalDragUpdate: (d) => _dragTo(d.globalPosition),
            child: LayoutBuilder(
              builder: (context, c) {
                final cell = c.maxWidth / Flames.max;
                final h = math.min(40.0, cell / FlameIcon.widthFor(1) * .9);
                return Row(
                  key: _rowKey,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = Flames.min; i <= Flames.max; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: v == i,
                          label: flameSemanticLabel(i),
                          excludeSemantics: true,
                          child: InkWell(
                            key: ValueKey('flame-pick-$i'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _pick(i),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: v == i ? SL.text : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FlameIcon(
                                    i,
                                    size: h,
                                    semantics: false,
                                    color: v != null && i > v ? SL.dot : null,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$i',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: v == i
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: v == i ? SL.text : SL.dim,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Glisse le long des flammes pour corriger.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SL.dim, fontSize: 12.5),
          ),
          if (widget.editing) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('flame-exclude'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Série écartée (incident)'),
              subtitle: const Text(
                'Gardée au journal, ignorée pour régler les charges.',
              ),
              value: _excluded,
              onChanged: (x) => setState(() => _excluded = x),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const ValueKey('flame-confirm'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(KControl.buttonHeight),
            ),
            onPressed: v == null ? null : () => _pick(v),
            child: Text(
              v == null
                  ? 'Choisis une flamme'
                  : widget.editing
                  ? 'Enregistrer · $v flamme${v > 1 ? 's' : ''}'
                  : 'Valider · $v flamme${v > 1 ? 's' : ''}',
            ),
          ),
          Align(
            child: TextButton(
              key: const ValueKey('flame-unknown'),
              onPressed: () => Navigator.of(
                context,
              ).pop(FlameChoice(unknown: true, excluded: _excluded)),
              child: Text(
                'Je ne sais pas',
                style: TextStyle(color: SL.dim, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne sous une série validée : sa note (flamme et RIR), « sans note »
/// ou « série écartée » ; un appui la modifie.
class FlameSetLine extends StatelessWidget {
  final String setLabel;
  final int? flames;
  final bool unknown;
  final bool excluded;
  final VoidCallback? onTap;
  const FlameSetLine({
    super.key,
    required this.setLabel,
    required this.flames,
    this.unknown = false,
    this.excluded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final f = flames;
    final label = [
      if (f != null) flameValueText(f) else 'sans note',
      if (excluded) 'série écartée',
    ].join(' · ');
    return Semantics(
      container: true,
      button: onTap != null,
      label: 'Série $setLabel : $label${onTap == null ? '' : '. Modifier'}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: ValueKey('flame-line-$setLabel'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap == null ? 24 : 44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 2, 4, 2),
            child: Row(
            children: [
              if (f != null)
                FlameIcon(f, size: 18, semantics: false)
              else
                Icon(Icons.help_outline, size: 16, color: SL.dim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: SL.dim,
                    fontSize: 12.5,
                    decoration: excluded ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (onTap != null) Icon(Icons.edit, size: 14, color: SL.dim),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
