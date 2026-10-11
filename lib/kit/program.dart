// UI0 (refonte UI) : composants du programme (cahier §5.4, U7) — ligne de
// jour, barre de saison par blocs, frise des phases. UI5 : ligne de jour de
// UI1 (états écrits, ⓘ) et ligne « Pourquoi ? » dépliable promues ici.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// État d'une journée du programme (ligne de jour, carte du jour).
enum KDayState {
  /// Séance à faire.
  todo,

  /// Séance enregistrée.
  done,

  /// Séance commencée, pas encore finie (« En cours »).
  inProgress,

  /// Séance neutre de reprise (« Reprise »).
  resume,
}

/// Ligne de jour (accueil, feuille de la semaine ; UI5 : issue de la ligne
/// de jour de UI1) : numéro, titre (capitales selon U3, jamais coupé),
/// détail facultatif, état écrit (« En cours », « Reprise ») et icône,
/// lus par TalkBack. Appui : ouvrir ; appui long : résumé ; [onInfo] :
/// bouton ⓘ, équivalent visible de l'appui long (R7). Rayon des menus (20),
/// fond `surface` (`haute` dans une feuille, [color]).
class KDayRow extends StatelessWidget {
  final int day;
  final String title;
  final String? detail;
  final KDayState state;
  final VoidCallback? onTap, onLongPress, onInfo;

  /// Fond de la ligne (`surface` sur la page, `haute` dans une feuille).
  final Color? color;
  const KDayRow({
    super.key,
    required this.day,
    required this.title,
    this.detail,
    this.state = KDayState.todo,
    this.onTap,
    this.onLongPress,
    this.onInfo,
    this.color,
  });

  /// État lu par TalkBack.
  static String stateLabel(KDayState state) => switch (state) {
    KDayState.done => 'Séance effectuée',
    KDayState.inProgress => 'Séance en cours',
    KDayState.resume => 'Reprise : séance neutre',
    KDayState.todo => 'Séance à faire',
  };

  /// État écrit à côté de l'icône (L5), nul pour « à faire » et « fait ».
  static String? stateText(KDayState state) => switch (state) {
    KDayState.inProgress => 'En cours',
    KDayState.resume => 'Reprise',
    _ => null,
  };

  /// Icône d'état.
  static IconData stateIcon(KDayState state) => switch (state) {
    KDayState.done => Icons.check_circle_rounded,
    KDayState.inProgress => Icons.timelapse_rounded,
    KDayState.resume => Icons.fast_forward_rounded,
    KDayState.todo => Icons.radio_button_unchecked_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final done = state == KDayState.done;
    final ink = switch (state) {
      KDayState.done => k.validation,
      KDayState.inProgress => k.encre,
      KDayState.resume => k.texte2,
      KDayState.todo => k.texte3,
    };
    final written = stateText(state);
    final statusLabel = stateLabel(state);
    final statusIcon = Icon(
      stateIcon(state),
      key: ValueKey('day-status-$day'),
      semanticLabel: statusLabel,
      size: KSize.icon,
      color: ink,
    );
    final main = Semantics(
      button: true,
      label: 'Jour $day · $title. $statusLabel',
      value: detail,
      onTap: onTap,
      onLongPress: onLongPress,
      onTapHint: done
          ? 'Afficher l’historique'
          : state == KDayState.inProgress
          ? 'Reprendre la séance'
          : 'Ouvrir la séance',
      onLongPressHint: onLongPress == null ? null : 'Afficher le résumé',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.target),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              KSpacing.s14,
              KSpacing.s8,
              onInfo == null ? KSpacing.s14 : KSpacing.s4,
              KSpacing.s8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: KSpacing.s32,
                  child: Text(
                    'J$day',
                    style: KType.chiffrePetit.copyWith(color: k.texte2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        k.title(title),
                        style: k.titleStyle(
                          KType.ligneJour.copyWith(
                            color: done ? k.texte2 : k.texte,
                          ),
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          style: KType.detail.copyWith(color: k.texte2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: KSpacing.s8),
                if (written != null) ...[
                  Text(
                    written,
                    key: ValueKey(
                      state == KDayState.inProgress
                          ? 'day-in-progress-$day'
                          : 'day-resume-$day',
                    ),
                    style: KType.micro.copyWith(color: ink),
                  ),
                  const SizedBox(width: KSpacing.s4),
                ],
                statusIcon,
              ],
            ),
          ),
        ),
      ),
    );
    return Material(
      color: color ?? k.surface,
      shape: KRadius.menuShape,
      clipBehavior: Clip.antiAlias,
      child: onInfo == null
          ? main
          : Row(
              children: [
                Expanded(child: main),
                IconButton(
                  key: ValueKey('day-info-$day'),
                  tooltip: 'Résumé du jour $day',
                  onPressed: onInfo,
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: KSize.iconSmall,
                    color: k.texte2,
                  ),
                ),
                const SizedBox(width: KSpacing.s4),
              ],
            ),
    );
  }
}

/// Ligne d'un changement avec son « Pourquoi ? » dépliable (feuilles de
/// Koach : ce qui change, ce qui a bougé). Cible de 48 dp, état lu par
/// TalkBack ; se range dans un `KMenuGroup`.
class KWhyTile extends StatefulWidget {
  final String title;
  final List<String> reasons;
  const KWhyTile({super.key, required this.title, required this.reasons});

  @override
  State<KWhyTile> createState() => _KWhyTileState();
}

class _KWhyTileState extends State<KWhyTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final can = widget.reasons.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: can,
          expanded: can ? _open : null,
          child: InkWell(
            onTap: can ? () => setState(() => _open = !_open) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KSize.target),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpacing.s16,
                  vertical: KSpacing.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: KType.corps.copyWith(color: k.texte),
                          ),
                          if (can)
                            Text(
                              'Pourquoi ?',
                              style: KType.detail.copyWith(color: k.texte2),
                            ),
                        ],
                      ),
                    ),
                    if (can)
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: KMotion.fast.durationIn(context),
                        curve: KMotion.fast.curve,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: KSize.icon,
                          color: k.texte2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(
              left: KSpacing.s16,
              right: KSpacing.s16,
              bottom: KSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in widget.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KSpacing.s4),
                    child: Text(
                      r,
                      style: KType.corps.copyWith(color: k.texte2),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Un bloc de la saison (barre de saison).
@immutable
class KSeasonBlock {
  final int weeks;
  final String? label;
  const KSeasonBlock(this.weeks, {this.label});
}

/// Barre de saison par blocs (U7) : un segment par bloc (largeur ∝ semaines,
/// écart de 3), blocs passés en `texte3`, bloc en cours rempli en `encre`
/// jusqu'à la semaine courante, blocs à venir en `filet` ; pastille
/// « S13 » (`pleine`) au-dessus de la semaine courante. Même information que
/// l'ancienne frise de points.
class KSeasonBar extends StatelessWidget {
  final List<KSeasonBlock> blocks;

  /// Semaine courante, de 1 au nombre total de semaines.
  final int week;
  final String Function(int week)? weekLabel;
  const KSeasonBar({
    super.key,
    required this.blocks,
    required this.week,
    this.weekLabel,
  });

  int get total => blocks.fold(0, (a, b) => a + b.weeks);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final n = math.max(1, total);
    final w = week.clamp(1, n);
    final label = weekLabel?.call(w) ?? 'S$w';
    const barHeight = KSpacing.s4 + KSpacing.s4 / 2;
    const blockGap = KSpacing.s4 - 1;
    return Semantics(
      label: 'Semaine $w sur $n',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final usable = width - blockGap * (blocks.length - 1);
          // Position du centre de la semaine courante.
          var x = 0.0, start = 0;
          for (final b in blocks) {
            final bw = usable * b.weeks / n;
            if (w <= start + b.weeks) {
              x += bw * ((w - start) - .5) / b.weeks;
              break;
            }
            x += bw + blockGap;
            start += b.weeks;
          }
          final pill = Text(
            label,
            style: KType.chiffrePetit.copyWith(color: k.surPleine),
          );
          final painter = TextPainter(
            text: TextSpan(text: label, style: KType.chiffrePetit),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final pillWidth = painter.width + 2 * KSpacing.s8;
          final pillHeight = painter.height + KSpacing.s4;
          painter.dispose();
          final left = (x - pillWidth / 2)
              .clamp(0.0, math.max(0.0, width - pillWidth))
              .toDouble();
          final starts = <int>[];
          var acc = 0;
          for (final b in blocks) {
            starts.add(acc);
            acc += b.weeks;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: pillHeight + KSpacing.s4,
                child: Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: 0,
                      child: Container(
                        width: pillWidth,
                        height: pillHeight,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: k.pleine,
                          shape: KRadius.pill,
                        ),
                        child: pill,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < blocks.length; i++) ...[
                      if (i > 0) const SizedBox(width: blockGap),
                      Expanded(
                        flex: math.max(1, blocks[i].weeks),
                        child: Builder(
                          builder: (_) {
                            final b0 = starts[i];
                            final end = b0 + blocks[i].weeks;
                            final past = w > end;
                            final current = w > b0 && w <= end;
                            final fill = current
                                ? (w - b0) / blocks[i].weeks
                                : (past ? 1.0 : 0.0);
                            return ClipPath(
                              clipper: const ShapeBorderClipper(
                                shape: KRadius.pill,
                              ),
                              child: ColoredBox(
                                color: past ? k.texte3 : k.filet,
                                child: current
                                    ? Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: FractionallySizedBox(
                                          widthFactor: fill,
                                          heightFactor: 1,
                                          child: ColoredBox(color: k.encre),
                                        ),
                                      )
                                    : const SizedBox.expand(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// État d'une phase de la frise.
enum KPhaseState { past, current, upcoming }

/// Une phase de la saison.
@immutable
class KPhase {
  final String name;
  final String? dates, length;
  final KPhaseState state;
  const KPhase(
    this.name, {
    this.dates,
    this.length,
    this.state = KPhaseState.upcoming,
  });
}

/// Frise des phases (Ma saison) : repère et trait à gauche, nom, dates,
/// durée ; la phase en cours en `encre`.
class KTimeline extends StatelessWidget {
  final List<KPhase> phases;
  const KTimeline({super.key, required this.phases});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Material(
      color: k.surface,
      shape: KRadius.menuShape,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpacing.s16,
          vertical: KSpacing.s8,
        ),
        child: Column(
          children: [
            for (var i = 0; i < phases.length; i++)
              _phase(k, phases[i], first: i == 0, last: i == phases.length - 1),
          ],
        ),
      ),
    );
  }

  Widget _phase(
    KTokens k,
    KPhase p, {
    required bool first,
    required bool last,
  }) {
    final current = p.state == KPhaseState.current;
    final past = p.state == KPhaseState.past;
    const node = KSpacing.s12;
    return Semantics(
      label: [
        p.name,
        if (p.dates != null) p.dates!,
        if (p.length != null) p.length!,
        if (current) 'en cours',
      ].join(', '),
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: KSpacing.s20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: KSpacing.s4 / 2,
                          color: first ? Colors.transparent : k.filet,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: KSpacing.s4 / 2,
                          color: last ? Colors.transparent : k.filet,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: current ? node + KSpacing.s4 : node,
                    height: current ? node + KSpacing.s4 : node,
                    decoration: ShapeDecoration(
                      color: current
                          ? k.encre
                          : past
                          ? k.texte3
                          : k.surface,
                      shape: CircleBorder(
                        side: current || past
                            ? BorderSide.none
                            : BorderSide(color: k.texte3, width: KSize.current),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KSpacing.s12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: KSize.primary),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.name,
                        style: (current ? KType.corpsFort : KType.corpsMoyen)
                            .copyWith(
                              color: current
                                  ? k.encre
                                  : past
                                  ? k.texte2
                                  : k.texte,
                            ),
                      ),
                      // Dates et durée sur une ligne de détail (rien ne se
                      // tasse à droite en grand texte).
                      if (p.dates != null || p.length != null)
                        Text(
                          [
                            if (p.dates != null) p.dates!,
                            if (p.length != null) p.length!,
                          ].join(' · '),
                          style: KType.detail.copyWith(color: k.texte2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
