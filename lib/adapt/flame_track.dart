// G9 (D5.3-D5.5), correction 1 du propriétaire : la note de chaque série en
// flammes se donne sous la série, sans fenêtre. Une ligne horizontale porte
// 10 positions : 9 points et la flamme choisie à sa place ; toucher une
// position ou glisser le long de la ligne déplace la flamme (transition
// animée). La coche valide la série avec la flamme visée déjà placée ; la
// ligne reste ouverte pour corriger. « Je ne sais pas », discret : série
// sans note. Les séries plus anciennes que la dernière validée sont
// résumées en une ligne ([SetSummaryLine]).
//
// UI2 (refonte UI) : jetons du kit ; le menu ⋯ de la ligne devient une
// feuille d'actions (C10, une action réversible, donc pas en `danger`) ;
// « Je ne sais pas » en lien texte discret de 48 dp (C13) ; ligne résumée
// sans troncature (C3). Le dessin de la flamme ([FlameIcon]) est inchangé.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalis_core/kalis_core.dart' show Flames;

import '../kit/kit.dart';
import '../koach/flame_icon.dart';
import '../store.dart' show LogSpec, SetEntry;

/// G9 correction 3 : un mot par flamme, du plus léger (1) à l'échec (10).
const kFlameWords = <String>[
  'Léger',
  'Facile',
  'Tranquille',
  'Modéré',
  'Soutenu',
  'Appuyé',
  'Dur',
  'Intense',
  'Limite',
  'Échec',
];

/// Mot de la flamme [f] (1 à 10).
String flameWord(int f) => kFlameWords[f.clamp(1, 10) - 1];

/// « Dur · RIR 2 », « Échec · RIR 0 » : note affichée sur la ligne.
String flameTrackText(int f) => '${flameWord(f)} · RIR ${flameRirText(f)}';

/// « 7 flammes · RIR 2 », « 10 flammes · échec (RIR 0) ».
String flameValueText(int f) {
  if (f == Flames.failure) return '10 flammes · échec (RIR 0)';
  return '$f flamme${f > 1 ? 's' : ''} · RIR ${flameRirText(f)}';
}

/// Note d'une série enregistrée : flammes, sinon ancienne difficulté ou RIR
/// convertis comme le journal du moteur (règle C9).
int? setFlamesOf(SetEntry s) {
  if (s.flames != null) return s.flames;
  if (s.flamesUnknown) return null;
  final rir = s.effort ?? double.tryParse(s.rir.trim().replaceAll(',', '.'));
  if (rir == null || rir < 0) return null;
  return Flames.fromRir(rir);
}

/// Phrase du premier usage : l'échelle en une ligne.
const kFlamesIntro =
    'Note chaque série en flammes : 10 = échec, plus aucune répétition '
    'possible ; 1 = encore 5 répétitions ou plus en réserve. La flamme '
    'visée est déjà placée : touche ou glisse pour corriger.';

/// « 16,25 kg × 8 reps », « 30 s », « 12 reps » : ce qui a été fait.
/// [units] faux (exercice d'archive inconnu du programme) : les valeurs
/// saisies telles quelles, sans unité inventée (« 17 · 0.42 »).
String setDoneText(SetEntry s, LogSpec sp, {bool units = true}) {
  String dec(String v) => v.trim().replaceAll('.', ',');
  final kg = s.kg.trim();
  final reps = s.reps.trim();
  if (!units) {
    return [
      for (final x in [kg, reps, s.v.trim()])
        if (x.isNotEmpty) x,
    ].join(' · ');
  }
  final seconds = sp.kind == 'hold' || sp.kind == 'holdMax';
  final amount = reps.isEmpty
      ? ''
      : seconds
      ? '${dec(reps)} s'
      : sp.kind == 'duration'
      ? '${dec(reps)} min'
      : sp.kind == 'distance'
      ? '${dec(reps)} m'
      : '${dec(reps)} rep${reps == '1' ? '' : 's'}';
  final load = [
    if (kg.isNotEmpty && kg != '0') '${dec(kg)} kg',
    if (amount.isNotEmpty) amount,
  ].join(' × ');
  final v = s.v.trim();
  // CI1f : détail des mini-séries (« 15+4+4+3 »).
  final parts = s.parts;
  final detail = parts == null || parts.length < 2
      ? load
      : '$load (${parts.map((p) => p.value).join('+')})';
  return v.isEmpty ? detail : '$detail · ${dec(v)} m/s';
}

/// Ligne de notation sous une série validée.
class FlameTrack extends StatefulWidget {
  final String setLabel;

  /// Flammes données (null : pas encore de note, ou « Je ne sais pas »).
  final int? value;
  final bool unknown;
  final bool excluded;
  final ValueChanged<int> onChanged;
  final VoidCallback onUnknown;
  final VoidCallback onToggleExcluded;

  /// Première notation : l'échelle expliquée sous la ligne.
  final bool intro;
  const FlameTrack({
    super.key,
    required this.setLabel,
    required this.value,
    required this.onChanged,
    required this.onUnknown,
    required this.onToggleExcluded,
    this.unknown = false,
    this.excluded = false,
    this.intro = false,
  });

  /// Durée de la transition de la flamme.
  static const motion = Duration(milliseconds: 240);

  @override
  State<FlameTrack> createState() => _FlameTrackState();
}

class _FlameTrackState extends State<FlameTrack> {
  /// Position suivie pendant un glissement (validée au lâcher).
  int? _drag;

  int? get _shown => _drag ?? widget.value;

  int _at(double dx, double width) {
    final cell = width / Flames.max;
    return (dx / cell).floor().clamp(0, Flames.max - 1) + 1;
  }

  void _commit(int f) {
    setState(() => _drag = null);
    if (f != widget.value || widget.unknown) widget.onChanged(f);
  }

  void _dragTo(double dx, double width) {
    final f = _at(dx, width);
    if (f != _shown) {
      HapticFeedback.selectionClick();
      setState(() => _drag = f);
    }
  }

  /// Menu de la série (feuille d'actions) : écarter ou réintégrer.
  Future<void> _openMenu() async {
    final value = await showKActionSheet<String>(
      context,
      title: 'Série ${widget.setLabel}',
      groups: [
        [
          KAction(
            icon: widget.excluded ? Icons.undo_rounded : Icons.block_rounded,
            label: widget.excluded
                ? 'Réintégrer la série'
                : 'Écarter la série (incident)',
            value: 'exclude',
          ),
        ],
      ],
    );
    if (value != null && mounted) widget.onToggleExcluded();
  }

  @override
  Widget build(BuildContext context) {
    final v = _shown;
    final k = KTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final motion = reduce ? Duration.zero : FlameTrack.motion;
    final label = widget.unknown && _drag == null
        ? 'Sans note'
        : v == null
        ? 'Note ta série'
        : flameTrackText(v);
    final legend = KType.detail.copyWith(color: k.texte2);
    return Padding(
      key: ValueKey('flame-track-${widget.setLabel}'),
      padding: const EdgeInsetsDirectional.only(
        start: KSpacing.s4,
        end: KSpacing.s4,
        bottom: KSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: motion,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: Text(
                    label,
                    key: ValueKey('flame-track-value-$label'),
                    style: KType.corpsFort.copyWith(
                      color: v == null ? k.texte2 : k.texte,
                      decoration: widget.excluded
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ),
              KIconButton(
                key: const ValueKey('flame-menu'),
                icon: Icons.more_horiz,
                tooltip: 'Plus d’options pour la série ${widget.setLabel}',
                color: k.texte2,
                onPressed: _openMenu,
              ),
            ],
          ),
          Semantics(
            slider: true,
            label: 'Difficulté de la série ${widget.setLabel}',
            value: v == null ? 'aucune' : flameSemanticLabel(v),
            increasedValue: v == null
                ? flameSemanticLabel(Flames.min)
                : v < Flames.max
                ? flameSemanticLabel(v + 1)
                : null,
            decreasedValue: v != null && v > Flames.min
                ? flameSemanticLabel(v - 1)
                : null,
            onIncrease: v == null || v < Flames.max
                ? () => _commit(v == null ? Flames.min : v + 1)
                : null,
            onDecrease: v != null && v > Flames.min
                ? () => _commit(v - 1)
                : null,
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final cell = w / Flames.max;
                double x(int i) => cell * (i - .5);
                const h = 48.0, flame = 34.0, dot = 7.0;
                final fill = v == null
                    ? k.filet
                    : flameColor(v, dark: dark).withValues(alpha: .55);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) {
                    HapticFeedback.selectionClick();
                    _commit(_at(d.localPosition.dx, w));
                  },
                  onHorizontalDragStart: (d) => _dragTo(d.localPosition.dx, w),
                  onHorizontalDragUpdate: (d) => _dragTo(d.localPosition.dx, w),
                  onHorizontalDragEnd: (_) {
                    final f = _drag;
                    if (f != null) _commit(f);
                  },
                  onHorizontalDragCancel: () => setState(() => _drag = null),
                  child: SizedBox(
                    height: h,
                    width: w,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ligne de fond.
                        Positioned(
                          left: x(1),
                          right: cell / 2,
                          top: h / 2 - 1,
                          height: 2,
                          child: ColoredBox(color: k.filet),
                        ),
                        // Partie parcourue jusqu'à la flamme.
                        AnimatedPositioned(
                          duration: motion,
                          curve: Curves.easeOutCubic,
                          left: x(1),
                          width: v == null ? 0 : x(v) - x(1),
                          top: h / 2 - 1.5,
                          height: 3,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              color: fill,
                              shape: KRadius.pill,
                            ),
                          ),
                        ),
                        // Les 9 points (10 sans flamme), une case chacun.
                        for (var i = Flames.min; i <= Flames.max; i++)
                          Positioned(
                            key: ValueKey('flame-pos-$i'),
                            left: cell * (i - 1),
                            width: cell,
                            top: 0,
                            height: h,
                            child: Center(
                              child: AnimatedOpacity(
                                duration: motion,
                                opacity: i == v ? 0 : 1,
                                child: AnimatedContainer(
                                  duration: motion,
                                  width: dot,
                                  height: dot,
                                  decoration: ShapeDecoration(
                                    shape: const CircleBorder(),
                                    color: v != null && i < v
                                        ? flameColor(i, dark: dark)
                                        : k.texte3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // La flamme choisie, à sa place.
                        if (v != null)
                          AnimatedPositioned(
                            key: const ValueKey('flame-thumb'),
                            duration: motion,
                            curve: Curves.easeOutBack,
                            left: x(v) - flame / 2,
                            top: (h - flame) / 2,
                            width: flame,
                            height: flame,
                            child: IgnorePointer(
                              child: AnimatedSwitcher(
                                duration: motion,
                                transitionBuilder: (child, a) =>
                                    ScaleTransition(
                                      scale: Tween(
                                        begin: .6,
                                        end: 1.0,
                                      ).animate(a),
                                      child: FadeTransition(
                                        opacity: a,
                                        child: child,
                                      ),
                                    ),
                                child: FlameIcon(
                                  v,
                                  key: ValueKey('flame-thumb-$v'),
                                  size: flame,
                                  semantics: false,
                                  onBase: true,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '1 · ${flameWord(1).toLowerCase()}',
                    style: legend,
                  ),
                ),
                // « Je ne sais pas », discret (lien texte `texte2`, 48 dp),
                // au centre sous la ligne ; texte agrandi sur écran étroit :
                // à la ligne au lieu de déborder.
                Flexible(
                  flex: 2,
                  child: KTextButton(
                    key: const ValueKey('flame-unknown'),
                    label: 'Je ne sais pas',
                    dense: true,
                    color: k.texte2,
                    onPressed: widget.unknown ? null : widget.onUnknown,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${flameWord(10).toLowerCase()} · 10',
                    textAlign: TextAlign.end,
                    style: legend,
                  ),
                ),
              ],
            ),
          ),
          if (widget.intro) ...[
            const SizedBox(height: KSpacing.s4),
            Text(
              kFlamesIntro,
              key: const ValueKey('flame-intro'),
              style: legend,
            ),
          ],
        ],
      ),
    );
  }
}

/// Série validée résumée en une ligne : numéro, ce qui a été fait, note.
/// Un appui la rouvre pour corriger.
class SetSummaryLine extends StatelessWidget {
  final String setLabel;
  final String done;
  final int? flames;
  final bool unknown;
  final bool excluded;
  final VoidCallback? onTap;
  const SetSummaryLine({
    super.key,
    required this.setLabel,
    required this.done,
    required this.flames,
    this.unknown = false,
    this.excluded = false,
    this.onTap,
  });

  /// Colonne du mot de la flamme : alignée d'une ligne à l'autre, élargie
  /// plutôt que coupée (C3).
  static const double _wordWidth = 80;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final f = flames;
    final spoken = [
      if (done.isNotEmpty) done,
      if (f != null)
        '${flameWord(f)}, ${flameValueText(f)}'
      else if (unknown)
        'sans note',
      if (excluded) 'série écartée',
    ].join(', ');
    final style = KType.corps.copyWith(
      color: excluded ? k.texte2 : k.texte,
      decoration: excluded ? TextDecoration.lineThrough : null,
      fontFeatures: KFont.tabular,
    );
    return Semantics(
      container: true,
      button: onTap != null,
      label: 'Série $setLabel : $spoken${onTap == null ? '' : '. Modifier'}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: ValueKey('set-summary-$setLabel'),
        borderRadius: KRadius.menuRadius,
        onTap: onTap,
        child: ConstrainedBox(
          // C13 : 48 dp quand la ligne se rouvre d'un appui.
          constraints: BoxConstraints(
            minHeight: onTap == null ? KSpacing.s32 : KSize.target,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Row(
              children: [
                SizedBox(
                  width: KSpacing.s32,
                  child: Text(
                    setLabel,
                    style: KType.chiffrePetit.copyWith(color: k.texte2),
                  ),
                ),
                Expanded(child: Text(done.isEmpty ? '—' : done, style: style)),
                if (excluded) ...[
                  Flexible(
                    child: Text(
                      'écartée',
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                  ),
                  const SizedBox(width: KSpacing.s8),
                ],
                // Colonne fixe : la flamme et sa note, alignées d'une ligne
                // à l'autre et centrées sur le texte.
                SizedBox(
                  width: KSize.icon,
                  height: KSize.icon,
                  child: f != null
                      ? FlameIcon(
                          f,
                          size: KSize.icon,
                          semantics: false,
                          centered: true,
                        )
                      : unknown
                      ? Icon(
                          Icons.help_outline,
                          size: KSize.chevron,
                          color: k.texte2,
                        )
                      : null,
                ),
                const SizedBox(width: KSpacing.s4),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: _wordWidth),
                  child: Text(
                    f != null ? flameWord(f) : '',
                    key: ValueKey('set-summary-flames-$setLabel'),
                    style: KType.libelle.copyWith(color: k.texte),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: KSpacing.s4),
                  Icon(Icons.expand_more, size: KSize.chevron, color: k.texte2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
