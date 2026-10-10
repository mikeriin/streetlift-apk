// UI0 (refonte UI) : composants du programme (cahier §5.4, U7) — ligne de
// jour, barre de saison par blocs, frise des phases.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// État d'une ligne de jour.
enum KDayState {
  /// Jour à venir.
  upcoming,

  /// Jour fait (séance enregistrée).
  done,

  /// Jour passé sans séance.
  missed,

  /// Jour de repos.
  rest,

  /// Jour choisi dans la liste (contour `encre`) ; le jour courant lui-même
  /// est la carte du jour (`KCard.day`).
  current,
}

/// Ligne de jour (accueil) : numéro, titre (capitales selon U3, jamais
/// coupé), état. Groupe au rayon des menus (20).
class KDayRow extends StatelessWidget {
  final String number, title;
  final String? detail;
  final KDayState state;
  final VoidCallback? onTap, onLongPress;

  /// Bouton d'information du jour (R7 : équivalent visible de l'appui long).
  final VoidCallback? onInfo;
  final String infoLabel;
  const KDayRow({
    super.key,
    required this.number,
    required this.title,
    this.detail,
    this.state = KDayState.upcoming,
    this.onTap,
    this.onLongPress,
    this.onInfo,
    this.infoLabel = 'Résumé du jour',
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final quiet = state == KDayState.done || state == KDayState.missed;
    final (IconData icon, Color iconColor, String stateLabel) = switch (state) {
      KDayState.done => (Icons.check_rounded, k.validation, 'fait'),
      KDayState.missed => (Icons.remove_rounded, k.texte3, 'passé'),
      KDayState.rest => (Icons.bedtime_outlined, k.texte2, 'repos'),
      KDayState.current => (Icons.chevron_right_rounded, k.encre, 'choisi'),
      KDayState.upcoming => (Icons.chevron_right_rounded, k.texte2, 'à venir'),
    };
    return Semantics(
      button: onTap != null,
      label: '$number, $title, $stateLabel',
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: k.surface,
        shape: RoundedRectangleBorder(
          borderRadius: KRadius.menuRadius,
          side: state == KDayState.current
              ? BorderSide(color: k.encre, width: KSize.current)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KSize.search),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                KSpacing.s14,
                KSpacing.s8,
                KSpacing.s4,
                KSpacing.s8,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: KSpacing.s32,
                    child: Text(
                      number,
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
                              color: quiet ? k.texte2 : k.texte,
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
                  if (onInfo != null)
                    IconButton(
                      tooltip: infoLabel,
                      onPressed: onInfo,
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: KSize.iconSmall,
                        color: k.texte2,
                      ),
                    )
                  else
                    SizedBox(
                      width: KSize.target,
                      height: KSize.target,
                      child: Icon(
                        icon,
                        size: KSize.iconSmall,
                        color: iconColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                      if (p.dates != null)
                        Text(
                          p.dates!,
                          style: KType.detail.copyWith(color: k.texte2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (p.length != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: KSpacing.s8),
                child: Center(
                  child: Text(
                    p.length!,
                    style: KType.detail.copyWith(color: k.texte2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
