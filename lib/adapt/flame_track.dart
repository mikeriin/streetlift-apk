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
//
// PR5 : la ligne des flammes passe en popup. Une série validée montre sa
// flamme à la place de la coche ([FlameSetButton]) : un appui ouvre la
// popup ([showFlamePopup]), la note est validée au lâcher et la popup se
// ferme ; un appui long annule la validation de la série.
import 'dart:math' as math;

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
/// UI5 (C9) : espace fine insécable avant l'unité ; une tenue de plus de
/// 90 s s'écrit en minutes (« 2 min 30 s »). [units] faux (exercice
/// d'archive inconnu du programme) : les valeurs saisies telles quelles,
/// sans unité inventée (« 17 · 0.42 »).
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
  final held = seconds ? int.tryParse(reps) : null;
  final amount = reps.isEmpty
      ? ''
      : held != null
      ? formatSeconds(held)
      : seconds
      ? unitText(dec(reps), 's')
      : sp.kind == 'duration'
      ? unitText(dec(reps), 'min')
      : sp.kind == 'distance'
      ? unitText(dec(reps), 'm')
      : unitText(dec(reps), 'rep${reps == '1' ? '' : 's'}');
  final load = [
    if (kg.isNotEmpty && kg != '0') unitText(dec(kg), 'kg'),
    if (amount.isNotEmpty) amount,
  ].join(' × ');
  final v = s.v.trim();
  // CI1f : détail des mini-séries (« 15+4+4+3 »).
  final parts = s.parts;
  final detail = parts == null || parts.length < 2
      ? load
      : '$load (${parts.map((p) => p.value).join('+')})';
  return v.isEmpty ? detail : '$detail · ${unitText(dec(v), 'm/s')}';
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

  /// PR5 : appelé à chaque lâcher (toucher, fin de glissement), même sur
  /// la note déjà donnée : la popup se ferme.
  final VoidCallback? onReleased;
  const FlameTrack({
    super.key,
    this.onReleased,
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
    widget.onReleased?.call();
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
                const h = 48.0, flame = 34.0;
                // 6.17.1 : ligne, points et base de la flamme forment une
                // seule forme, union lisse de fonctions distance signées
                // ([FlameTrackPainter]) : la barre se gonfle en douceur dans
                // chaque point et dans la flamme. Couleur des points jusqu'à
                // la flamme, `texte3` après.
                final colors = [
                  for (var i = Flames.min; i <= Flames.max; i++)
                    flameColor(i, dark: dark),
                ];
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
                    child: TweenAnimationBuilder<double>(
                      duration: motion,
                      curve: Curves.easeOutCubic,
                      tween: Tween(end: (v ?? Flames.min).toDouble()),
                      builder: (context, at, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: FlameTrackPainter(
                                at: v == null ? null : at,
                                cell: cell,
                                colors: colors,
                                rest: k.texte3,
                              ),
                            ),
                          ),
                          // Une case par position (cibles et repères).
                          for (var i = Flames.min; i <= Flames.max; i++)
                            Positioned(
                              key: ValueKey('flame-pos-$i'),
                              left: cell * (i - 1),
                              width: cell,
                              top: 0,
                              height: h,
                              child: const SizedBox.expand(),
                            ),
                          // La flamme choisie, à sa place.
                          if (v != null)
                            Positioned(
                              key: const ValueKey('flame-thumb'),
                              left: cell * (at - .5) - flame / 2,
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
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Builder(
              builder: (context) {
                final low = Text(
                  '1 · ${flameWord(1).toLowerCase()}',
                  style: legend,
                );
                final high = Text(
                  '${flameWord(10).toLowerCase()} · 10',
                  textAlign: TextAlign.end,
                  style: legend,
                );
                // « Je ne sais pas », discret (lien texte `texte2`, 48 dp),
                // au centre sous la ligne.
                final unknown = KTextButton(
                  key: const ValueKey('flame-unknown'),
                  label: 'Je ne sais pas',
                  dense: true,
                  color: k.texte2,
                  onPressed: widget.unknown ? null : widget.onUnknown,
                );
                // Les deux bornes de l'échelle aux extrémités, l'action
                // « Je ne sais pas » dessous, à part (ce n'est pas une
                // valeur de l'échelle).
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: low),
                        const SizedBox(width: KSpacing.s8),
                        Expanded(child: high),
                      ],
                    ),
                    unknown,
                  ],
                );
              },
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

/// PR5 : note d'une série validée en popup : la ligne des flammes (même
/// curseur), validée au lâcher ; « Je ne sais pas » et « Écarter la
/// série » ferment aussi la popup.
Future<void> showFlamePopup(
  BuildContext context, {
  required String setLabel,
  required int? value,
  required ValueChanged<int> onChanged,
  required VoidCallback onUnknown,
  required VoidCallback onToggleExcluded,
  bool unknown = false,
  bool excluded = false,
  bool intro = false,
}) => showKDialog<void>(
  context,
  dialogKey: const ValueKey('flame-popup'),
  builder: (ctx) {
    final k = KTokens.of(ctx);
    var closed = false;
    void close() {
      if (closed) return;
      closed = true;
      Navigator.of(ctx).pop();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s16,
        KSpacing.s8,
        KSpacing.s8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Série $setLabel',
                style: KType.titreCarte.copyWith(color: k.texte),
              ),
            ),
            const SizedBox(height: KSpacing.s8),
            FlameTrack(
              setLabel: setLabel,
              value: value,
              unknown: unknown,
              excluded: excluded,
              intro: intro,
              onChanged: onChanged,
              onReleased: close,
              onUnknown: () {
                onUnknown();
                close();
              },
              onToggleExcluded: () {
                onToggleExcluded();
                close();
              },
            ),
          ],
        ),
      ),
    );
  },
);

/// PR5 : bouton d'une série validée, à la place de la coche : sa flamme
/// (sinon « ? », sans note, ou ⊘, série écartée). Un appui : la note en
/// popup ; un appui long : la validation est annulée.
class FlameSetButton extends StatelessWidget {
  final String setLabel;
  final int? value;
  final bool unknown;
  final bool excluded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const FlameSetButton({
    super.key,
    required this.setLabel,
    required this.value,
    required this.onTap,
    required this.onLongPress,
    this.unknown = false,
    this.excluded = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final f = value;
    final note = excluded
        ? 'série écartée'
        : f != null
        ? flameValueText(f)
        : unknown
        ? 'sans note'
        : 'pas encore notée';
    return Semantics(
      button: true,
      label: 'Série $setLabel validée, $note',
      onTapHint: 'noter la série',
      onLongPressHint: 'annuler la validation',
      excludeSemantics: true,
      // Même gabarit que la coche : pastille à la hauteur des champs, zone
      // d'appui de 48 dp hors densité compacte (C13).
      child: SizedBox(
        width: KSize.target,
        height: KDensity.factor < 1 ? KDensity.field(KSize.target) : KSize.target,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Feedback.forTap(context);
            onTap();
          },
          onLongPress: () {
            Feedback.forLongPress(context);
            onLongPress();
          },
          child: Center(
            child: Material(
              color: k.validation.withValues(alpha: .14),
              shape: KRadius.pill,
              child: SizedBox(
                width: KSize.target,
                height: KDensity.field(KSize.target),
                child: Center(
                child: excluded
                    ? Icon(
                        Icons.block_rounded,
                        size: KSize.iconSmall,
                        color: k.texte2,
                      )
                    : f != null
                    ? FlameIcon(
                        f,
                        key: ValueKey('set-flame-value-$setLabel-$f'),
                        size: KSize.icon,
                        semantics: false,
                        centered: true,
                      )
                    : Icon(
                        unknown
                            ? Icons.help_outline
                            : Icons.local_fire_department_outlined,
                        size: KSize.icon,
                        color: k.texte2,
                      ),
              ),
            ),
          ),
        ),
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

/// 6.17.1 : ligne des flammes dessinée comme une seule forme : union lisse
/// (« smooth min » polynomial) des fonctions distance signées d'une ligne
/// (capsule), des points (cercles) et de la base de la flamme (cercle), de
/// sorte que la ligne s'évase en douceur dans chaque point et sous la
/// flamme, sans arête. La forme est symétrique autour de la ligne : pour
/// chaque abscisse, sa demi-hauteur est le zéro de la distance, trouvé par
/// dichotomie (la distance croît avec l'écart à la ligne). Remplissage :
/// couleur du point de chaque position jusqu'à la flamme, [rest] après.
class FlameTrackPainter extends CustomPainter {
  /// Position de la flamme (1 à 10, continue pendant l'animation) ; null :
  /// aucune note.
  final double? at;
  final double cell;
  final List<Color> colors;
  final Color rest;

  /// Rayon des points, demi-épaisseurs de la ligne (parcourue, restante),
  /// rayon de la base de la flamme, rayon de lissage.
  static const double dot = 3.5, line = 1.5, lineRest = 1, base = 5, k = 5;

  const FlameTrackPainter({
    required this.at,
    required this.cell,
    required this.colors,
    required this.rest,
  });

  double _x(double i) => cell * (i - .5);

  static double _smin(double a, double b) {
    final h = math.max(k - (a - b).abs(), 0.0) / k;
    return math.min(a, b) - h * h * k * .25;
  }

  static double _capsule(double px, double py, double a, double b, double r) {
    final dx = px < a ? a - px : (px > b ? px - b : 0.0);
    return math.sqrt(dx * dx + py * py) - r;
  }

  /// Distance signée de la forme au point (px, py), py mesuré depuis la
  /// ligne.
  double _field(double px, double py) {
    final first = _x(1), last = _x(10);
    final split = at == null ? first : _x(at!);
    var d = _capsule(px, py, split, last, lineRest);
    if (at != null) d = _smin(d, _capsule(px, py, first, split, line));
    for (var i = 1; i <= 10; i++) {
      final cx = _x(i.toDouble());
      // Le point sous la flamme s'efface à mesure qu'elle s'en approche.
      final double near = at == null
          ? 1
          : math.min((cx - split).abs() / cell, 1.0);
      final r = dot * near;
      if (r < .2) continue;
      final dx = px - cx;
      d = _smin(d, math.sqrt(dx * dx + py * py) - r);
    }
    if (at != null) {
      final dx = px - split;
      d = _smin(d, math.sqrt(dx * dx + py * py) - base);
    }
    return d;
  }

  /// Demi-hauteur de la forme à l'abscisse [px] (0 : hors de la forme).
  double _half(double px) {
    if (_field(px, 0) >= 0) return 0;
    double lo = 0, hi = base + k;
    for (var n = 0; n < 18; n++) {
      final mid = (lo + hi) / 2;
      if (_field(px, mid) < 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final top = <Offset>[];
    final bottom = <Offset>[];
    final from = _x(1) - base - k, to = _x(10) + base + k;
    for (var px = from; px <= to; px += .5) {
      final hh = _half(px);
      if (hh <= 0) continue;
      top.add(Offset(px, cy - hh));
      bottom.add(Offset(px, cy + hh));
    }
    if (top.length < 2) return;
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final o in top.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    for (final o in bottom.reversed) {
      path.lineTo(o.dx, o.dy);
    }
    path.close();
    // Couleurs : point de chaque position jusqu'à la flamme, puis [rest]
    // (bascule douce sur une demi-case).
    final w = size.width <= 0 ? 1.0 : size.width;
    final stops = <double>[];
    final cs = <Color>[];
    if (at == null) {
      cs.addAll([rest, rest]);
      stops.addAll([0, 1]);
    } else {
      final split = _x(at!);
      for (var i = 1; i <= 10; i++) {
        final cx = _x(i.toDouble());
        if (cx >= split) break;
        cs.add(colors[i - 1]);
        stops.add(math.min(math.max(cx / w, 0.0), 1.0));
      }
      final int lo = math.min(math.max(at!.floor(), 1), 10);
      final int hi = math.min(math.max(at!.ceil(), 1), 10);
      final here = Color.lerp(colors[lo - 1], colors[hi - 1], at! - lo)!;
      cs.add(here);
      stops.add(math.min(math.max(split / w, 0.0), 1.0));
      cs.add(rest);
      stops.add(math.min(math.max((split + cell / 2) / w, 0.0), 1.0));
    }
    final paint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: cs,
        stops: _sorted(stops),
      ).createShader(Rect.fromLTWH(0, 0, w, size.height));
    canvas.drawPath(path, paint);
  }

  /// Arrêts du dégradé croissants (exigé par le moteur de rendu).
  static List<double> _sorted(List<double> s) {
    final out = <double>[];
    for (final v in s) {
      out.add(out.isEmpty ? v : math.max(v, out.last));
    }
    return out;
  }

  @override
  bool shouldRepaint(FlameTrackPainter old) =>
      old.at != at ||
      old.cell != cell ||
      old.rest != rest ||
      !_same(old.colors, colors);

  static bool _same(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
