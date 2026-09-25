// Vitrine du catalogue de WODs, façon boutique de jeu : couvertures
// procédurales (un motif par format, une teinte par palier), cartes de rail,
// WOD à l'affiche (essai du jour), prochain objectif de la liste d'envies,
// solde de crédits et règles de gain, révélation au déblocage.
//
// Aucune boucle d'animation : chaque effet est joué une fois, et « Réduire les
// animations » affiche directement l'état final. Les sélections (essai,
// vitrine, « à ta mesure ») viennent du store et ne dépendent que de la date.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'stats_widgets.dart' show statsSheet;
import 'store.dart';
import 'training_estimate.dart';
import 'ui.dart';
import 'wod_models.dart';
import 'wod_preview.dart';
import 'wod_screen.dart' show WodRunScreen;

// ---------------------------------------------------------------------------
// Paliers
// ---------------------------------------------------------------------------

/// Palier 1-4 d'un niveau de WOD : 1-3 Standard, 4-6 Avancé, 7-8 Élite,
/// 9-10 Légende. Même découpage que les prix (1 à 4 crédits).
int tierOf(int level) =>
    level <= 3
        ? 1
        : level <= 6
        ? 2
        : level <= 8
        ? 3
        : 4;

const tierNames = ['Standard', 'Avancé', 'Élite', 'Légende'];

String tierLabel(int level) => tierNames[tierOf(level) - 1];

/// Chevrons du palier : un par cran, toujours accompagnés d'une couleur et
/// jamais seuls porteurs de l'information (le libellé reste disponible).
class TierChevrons extends StatelessWidget {
  final int level;
  final double size;
  final Color? color;
  const TierChevrons(this.level, {super.key, this.size = 12, this.color});
  @override
  Widget build(BuildContext context) {
    final tier = tierOf(level);
    final c = color ?? (tier >= 3 ? SL.accent : SL.dim);
    return Semantics(
      label: 'Palier ${tierLabel(level)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tier; i++)
            Icon(Icons.keyboard_arrow_up_rounded, size: size, color: c),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Couverture procédurale
// ---------------------------------------------------------------------------

/// Motif d'une couverture : lisible d'un coup d'œil, un par famille de WOD.
enum CoverMotif {
  speed,
  stack,
  rings,
  ticks,
  rungs,
  stairs,
  blocks,
  ramp,
  ladder,
}

CoverMotif motifOf(Wod w) {
  final n = w.name.toLowerCase();
  if (n.contains('tabata')) return CoverMotif.blocks;
  if (n.contains('death by')) return CoverMotif.ramp;
  if (n.contains('chipper')) return CoverMotif.stairs;
  if (w.scheme.isNotEmpty || n.contains('échelle')) return CoverMotif.ladder;
  switch (w.type) {
    case 'amrap':
      return CoverMotif.rings;
    case 'emom':
      return CoverMotif.ticks;
    case 'rounds':
      return CoverMotif.stack;
    case 'routine':
      return CoverMotif.rungs;
    default:
      return CoverMotif.speed;
  }
}

int coverSeed(Wod w) {
  var h = 0x811C9DC5;
  for (final c in w.id.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Couverture d'un WOD : dégradé bordeaux, motif du format, intensité du
/// palier. Dessinée une fois par taille (RepaintBoundary), sans image.
class WodCover extends StatelessWidget {
  final Wod wod;
  final double radius;
  final bool dim;
  final Widget? child;
  const WodCover({
    super.key,
    required this.wod,
    this.radius = 16,
    this.dim = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _CoverPainter(
              seed: coverSeed(wod),
              motif: motifOf(wod),
              tier: tierOf(wod.level),
              rounds: wod.rounds,
              dim: dim,
            ),
          ),
        ),
        if (child != null) child!,
      ],
    ),
  );
}

class _CoverPainter extends CustomPainter {
  final int seed;
  final CoverMotif motif;
  final int tier;
  final int rounds;
  final bool dim;
  const _CoverPainter({
    required this.seed,
    required this.motif,
    required this.tier,
    required this.rounds,
    required this.dim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    // Fond : dégradé bordeaux → plus clair ou plus sombre selon le palier.
    final angle = rng.nextDouble() * math.pi;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final end =
        Color.lerp(
          KPalette.burgundy,
          tier >= 3 ? KPalette.actionRed : KPalette.black,
          tier >= 3 ? .55 : .45,
        )!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-dir.dx, -dir.dy),
          end: Alignment(dir.dx, dir.dy),
          colors: [KPalette.burgundy, end],
        ).createShader(rect),
    );
    final ink =
        Paint()
          ..color = KPalette.light.withValues(alpha: tier >= 3 ? .20 : .14)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2, w / 48);
    final fill =
        Paint()
          ..color = KPalette.light.withValues(alpha: tier >= 3 ? .16 : .11);
    switch (motif) {
      case CoverMotif.speed:
        {
          for (var i = 0; i < 7; i++) {
            final y = h * (0.15 + 0.7 * i / 6) + rng.nextDouble() * h * .04;
            final len = w * (0.25 + rng.nextDouble() * 0.45);
            final x0 = -w * .1 + rng.nextDouble() * w * .5;
            canvas.drawLine(
              Offset(x0, y + h * .08),
              Offset(x0 + len, y - h * .08),
              ink,
            );
          }
        }
      case CoverMotif.stack:
        {
          final n = rounds.clamp(3, 8);
          final bw = w * .38, bh = h * .075;
          for (var i = 0; i < n; i++) {
            final y = h * .12 + i * (h * .76) / n;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(w * .52, y, bw * (0.7 + 0.3 * ((i + 1) / n)), bh),
                Radius.circular(bh),
              ),
              fill,
            );
          }
        }
      case CoverMotif.rings:
        {
          final c = Offset(w * .68, h * .58);
          for (var i = 1; i <= 4; i++) {
            canvas.drawCircle(c, math.min(w, h) * .11 * i, ink);
          }
        }
      case CoverMotif.ticks:
        {
          final c = Offset(w * .62, h * .55);
          final r = math.min(w, h) * .38;
          for (var i = 0; i < 12; i++) {
            final a = i * math.pi / 6;
            final major = i % 3 == 0;
            canvas.drawLine(
              c +
                  Offset(math.cos(a), math.sin(a)) *
                      (major ? r * .72 : r * .84),
              c + Offset(math.cos(a), math.sin(a)) * r,
              ink,
            );
          }
          canvas.drawCircle(c, math.max(2, w / 40), fill);
        }
      case CoverMotif.rungs:
        {
          for (var i = 0; i < 5; i++) {
            final y = h * (0.2 + 0.15 * i);
            canvas.drawLine(
              Offset(w * .12, y),
              Offset(w * (.88 - .12 * i), y),
              ink,
            );
          }
        }
      case CoverMotif.stairs:
        {
          final path = Path()..moveTo(w * .1, h * .18);
          var x = w * .1, y = h * .18;
          for (var i = 0; i < 5; i++) {
            x += w * .16;
            path.lineTo(x, y);
            y += h * .14;
            path.lineTo(x, y);
          }
          canvas.drawPath(path, ink);
        }
      case CoverMotif.blocks:
        {
          final unit = w * .8 / 12;
          var x = w * .1;
          for (var i = 0; i < 8; i++) {
            final work = i.isEven;
            final bw = work ? unit * 2 : unit;
            if (work) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, h * .38, bw - 3, h * .24),
                  const Radius.circular(3),
                ),
                fill,
              );
            }
            x += bw;
          }
        }
      case CoverMotif.ramp:
        {
          final path = Path()..moveTo(w * .08, h * .8);
          for (var i = 1; i <= 6; i++) {
            final x = w * (.08 + .14 * i);
            path.lineTo(x, h * (.8 - .11 * i));
            path.lineTo(x, h * .8);
            path.moveTo(x, h * (.8 - .11 * i));
          }
          canvas.drawPath(path, ink);
        }
      case CoverMotif.ladder:
        {
          final tilt = w * .1;
          final left = Offset(w * .32 + tilt, h * .1),
              leftB = Offset(w * .32, h * .9);
          final right = Offset(w * .68 + tilt, h * .1),
              rightB = Offset(w * .68, h * .9);
          canvas.drawLine(left, leftB, ink);
          canvas.drawLine(right, rightB, ink);
          for (var i = 1; i <= 5; i++) {
            final t = i / 6;
            canvas.drawLine(
              Offset.lerp(left, leftB, t)!,
              Offset.lerp(right, rightB, t)!,
              ink,
            );
          }
        }
    }
    // Reflet des paliers Élite et Légende, puis vignette.
    if (tier >= 3) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KPalette.light.withValues(alpha: tier == 4 ? .12 : .06),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0, .45, 1],
          ).createShader(rect),
      );
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.3, -.4),
          radius: 1.3,
          colors: [Colors.transparent, KPalette.black.withValues(alpha: .38)],
        ).createShader(rect),
    );
    if (dim) {
      canvas.drawRect(
        rect,
        Paint()..color = KPalette.black.withValues(alpha: .42),
      );
    }
  }

  @override
  bool shouldRepaint(_CoverPainter old) =>
      old.seed != seed ||
      old.motif != motif ||
      old.tier != tier ||
      old.rounds != rounds ||
      old.dim != dim;
}

// ---------------------------------------------------------------------------
// Étiquettes de prix et d'état
// ---------------------------------------------------------------------------

String creditsLabel(int n) => '$n crédit${n > 1 ? 's' : ''}';

/// État d'achat d'un WOD, tel que le voit la boutique.
enum StoreState { owned, trial, affordable, close, locked }

StoreState storeStateOf(Wod w) {
  if (store.unlocked(w)) return StoreState.owned;
  if (store.isTrial(w)) return StoreState.trial;
  final missing = store.missingFor(w);
  if (missing == 0) return StoreState.affordable;
  return missing == 1 ? StoreState.close : StoreState.locked;
}

/// Pastille de prix : « Possédé », « Essai offert », prix (barré si remise),
/// « Plus que 1 crédit » ou cadenas. Le rouge sert de fond, jamais de texte.
class WodPriceTag extends StatelessWidget {
  final Wod wod;
  const WodPriceTag({super.key, required this.wod});

  @override
  Widget build(BuildContext context) {
    final state = storeStateOf(wod);
    final cost = store.wodCost(wod);
    final base = store.basePrice(wod);
    switch (state) {
      case StoreState.owned:
        final best = wod.best();
        return KBadge(
          best == null ? 'Possédé' : 'Record ${best.score}',
          color: SL.success,
          icon: Icons.check_rounded,
        );
      case StoreState.trial:
        return KBadge(
          'Essai offert',
          color: SL.accent,
          icon: Icons.bolt_rounded,
        );
      case StoreState.affordable:
      case StoreState.close:
      case StoreState.locked:
        final missing = store.missingFor(wod);
        final c =
            state == StoreState.affordable
                ? SL.accent
                : state == StoreState.close
                ? SL.text
                : SL.dim;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: c.withValues(
              alpha: state == StoreState.affordable ? .16 : .10,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state == StoreState.affordable
                    ? Icons.toll_rounded
                    : Icons.lock_outline_rounded,
                size: 14,
                color: c,
              ),
              const SizedBox(width: 5),
              if (base > cost) ...[
                Text(
                  '$base',
                  style: TextStyle(
                    color: c.withValues(alpha: .7),
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  state == StoreState.close
                      ? 'Plus que 1 crédit'
                      : state == StoreState.locked
                      ? '${creditsLabel(cost)} · manque $missing'
                      : creditsLabel(cost),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Navigation
// ---------------------------------------------------------------------------

void openWod(BuildContext context, Wod w) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => WodPreviewScreen(wodId: w.id)),
);

void runWod(BuildContext context, Wod w) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => WodRunScreen(wodId: w.id)),
);

// ---------------------------------------------------------------------------
// Textes
// ---------------------------------------------------------------------------

/// Accroche d'une fiche, selon la famille du WOD.
String storeTagline(Wod w) {
  final n = w.name.toLowerCase();
  if (n.contains('death by')) {
    return 'Une rep de plus chaque minute. Jusqu\u2019où ?';
  }
  if (n.contains('tabata')) {
    return '20 s à fond, 10 s de repos. Huit fois, sans négocier.';
  }
  if (n.contains('chipper')) {
    return 'Une longue liste. Tu la descends, sans revenir en arrière.';
  }
  if (w.scheme.isNotEmpty || n.contains('échelle')) {
    return 'Une échelle : chaque barreau compte, le dernier surtout.';
  }
  switch (w.type) {
    case 'amrap':
      return '${w.minutes} minutes. Autant de tours que tu peux.';
    case 'emom':
      return 'Chaque minute compte. Ne prends jamais de retard.';
    case 'rounds':
      return '${w.rounds} tours. Tiens le rythme jusqu\u2019au dernier.';
    case 'routine':
      return 'À ton rythme, sans chrono. La qualité d\u2019abord.';
    default:
      return 'Contre la montre. Un seul chiffre à battre.';
  }
}

/// « Pourquoi ça compte » : cible musculaire et qualité travaillée.
String storeWhy(Wod w, TrainingEstimate estimate, Map<String, double> muscles) {
  final focus = [
    for (final e in muscles.entries.where((e) => e.value > 0).take(3))
      '${e.key[0].toUpperCase()}${e.key.substring(1)}',
  ];
  final minutes =
      estimate.elapsed.high > 0 ? estimate.elapsed.midpoint / 60 : 0;
  final quality =
      minutes >= 25
          ? 'ton endurance'
          : minutes >= 12
          ? 'ta capacité de travail'
          : 'ta puissance sous fatigue';
  final target = focus.isEmpty ? '' : 'Cible : ${focus.join(', ')}. ';
  final tier = tierOf(w.level);
  return '${target}Travaille $quality'
      '${tier >= 3 ? ' — palier ${tierLabel(w.level)}, arrive reposé.' : '.'}';
}

String _hours(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60;
  if (h <= 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m';
}

/// Fin de l'essai du jour, en temps réel (aucun minuteur qui se réinitialise).
String trialCountdown() =>
    'Essai offert jusqu\u2019à minuit · encore ${_hours(store.untilMidnight)}';

String weeklyCountdown() {
  final d = store.daysUntilNewWeek;
  return d <= 1
      ? 'Nouvelle vitrine lundi'
      : 'Nouvelle vitrine lundi · dans $d j';
}

// ---------------------------------------------------------------------------
// Cartes
// ---------------------------------------------------------------------------

/// Carte de rail : couverture 5:4, format, palier, nom, spécification, état.
class WodStoreCard extends StatelessWidget {
  final Wod wod;
  final double width;
  final String? ribbon;
  const WodStoreCard({
    super.key,
    required this.wod,
    this.width = 164,
    this.ribbon,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !store.canRun(wod);
    return SizedBox(
      width: width,
      child: KCard(
        padding: EdgeInsets.zero,
        radius: 20,
        onTap: () => openWod(context, wod),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 5 / 4,
              child: WodCover(
                wod: wod,
                radius: 0,
                dim: locked && storeStateOf(wod) == StoreState.locked,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              wod.typeLabel.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: KPalette.light,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                            ),
                          ),
                          TierChevrons(wod.level, color: KPalette.light),
                        ],
                      ),
                      const Spacer(),
                      if (ribbon != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: KPalette.light,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ribbon!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: KPalette.burgundy,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wod.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SL.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.wodEstimate(wod).durationLabel} · Niv. ${wod.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: SL.dim, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                  WodPriceTag(wod: wod),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rail horizontal : titre de section, sous-titre, cartes. Les cartes gardent
/// leur hauteur naturelle (pas de hauteur fixe, donc pas de débordement
/// quand le texte est agrandi).
class StoreRail extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> cards;
  const StoreRail({
    super.key,
    required this.title,
    this.subtitle,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KSection(title, subtitle: subtitle, topPadding: 0),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              cards[i],
            ],
          ],
        ),
      ),
    ],
  );
}

/// À l'affiche : l'essai du jour. Couverture 16:9, nom, accroche, chips,
/// « Essayer » (offert jusqu'à minuit) et « Voir la fiche ».
class WodHero extends StatelessWidget {
  final Wod wod;
  const WodHero({super.key, required this.wod});

  @override
  Widget build(BuildContext context) {
    final cost = store.wodCost(wod);
    return KCard(
      padding: EdgeInsets.zero,
      radius: 24,
      onTap: () => openWod(context, wod),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            // La couverture suit le texte agrandi, sans réduire sa lisibilité.
            aspectRatio:
                16 /
                (9 *
                    math.max(
                      1.0,
                      MediaQuery.textScalerOf(context).scale(20) / 20,
                    )),
            child: WodCover(
              wod: wod,
              radius: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: KPalette.light,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'À L\u2019AFFICHE',
                                style: TextStyle(
                                  color: KPalette.burgundy,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TierChevrons(
                          wod.level,
                          size: 16,
                          color: KPalette.light,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      wod.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: KPalette.light,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeTagline(wod),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: SL.text, fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    KBadge(wod.typeLabel, color: SL.accent),
                    KBadge('Niv. ${wod.level} · ${tierLabel(wod.level)}'),
                    KBadge(store.wodEstimate(wod).durationLabel),
                    KBadge(
                      store.triedAndDone(wod)
                          ? 'Essai terminé · ${creditsLabel(cost)} pour le garder'
                          : 'Après l\u2019essai : ${creditsLabel(math.max(1, store.basePrice(wod) - 1))}',
                      icon: Icons.toll_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  trialCountdown(),
                  style: TextStyle(color: SL.dim, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: SL.action,
                        foregroundColor: KPalette.light,
                      ),
                      onPressed: () => runWod(context, wod),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Essayer · offert'),
                    ),
                    OutlinedButton(
                      onPressed: () => openWod(context, wod),
                      child: const Text('Voir la fiche'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Prochain objectif : le WOD souhaité le moins cher, jauge de crédits et
/// distance en crédits ou en XP (goal-gradient, jamais truqué).
class WishGoalCard extends StatelessWidget {
  final Wod wod;
  const WishGoalCard({super.key, required this.wod});

  @override
  Widget build(BuildContext context) {
    final cost = store.wodCost(wod);
    final missing = store.missingFor(wod);
    final lp = store.levelProgress;
    final next = store.progression.nextCredits;
    return KCard(
      accent: SL.bordeaux,
      onTap: () => openWod(context, wod),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KSection('Prochain objectif', topPadding: 0),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                height: 64,
                child: WodCover(wod: wod, radius: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wod.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SL.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${wod.typeLabel} · Niv. ${wod.level} · ${creditsLabel(cost)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: SL.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          KProgressBar(
            value: cost == 0 ? 1.0 : store.credits / cost,
            height: 7,
            color: missing == 0 ? SL.success : SL.accent,
            semanticsLabel: 'Crédits pour ${wod.name}',
            semanticsValue: '${math.min(store.credits, cost)} sur $cost',
          ),
          const SizedBox(height: 6),
          Text(
            missing == 0
                ? 'À ta portée. Débloque-le maintenant.'
                : 'Plus que ${creditsLabel(missing)} · niveau ${store.level + 1} dans ${lp.need - lp.inLevel} XP (+$next crédit${next > 1 ? 's' : ''})',
            style: TextStyle(
              color: missing == 0 ? SL.success : SL.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Solde de crédits, prochain gain et rappel de la règle du jeu.
class CreditsCard extends StatelessWidget {
  const CreditsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = store.levelProgress;
    final next = store.progression.nextCredits;
    final credits = store.credits;
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SL.accentTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.toll_rounded, color: SL.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$credits crédit${credits > 1 ? 's' : ''} WOD',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Niveau ${store.level + 1} dans ${lp.need - lp.inLevel} XP : +$next crédit${next > 1 ? 's' : ''}',
                      style: TextStyle(color: SL.dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showCreditRules(context),
                child: const Text('Gagner'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          KProgressBar(
            value: lp.need == 0 ? 0 : lp.inLevel / lp.need,
            semanticsLabel: 'Progression vers le niveau ${store.level + 1}',
            semanticsValue: '${lp.inLevel} sur ${lp.need} XP',
          ),
          const SizedBox(height: 8),
          Text(
            'Gagne des crédits en progressant. Achète un WOD, rejoue-le à volonté : rien n\u2019est jamais retiré.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Future<void> showCreditRules(BuildContext context) {
  Widget rule(IconData icon, String title, String text) => KCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SL.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: SL.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(text, style: TextStyle(color: SL.dim, fontSize: 12.5)),
            ],
          ),
        ),
      ],
    ),
  );
  return statsSheet(context, 'Gagner des crédits', [
    rule(
      Icons.trending_up_rounded,
      '+2 crédits par niveau',
      '+3 de plus tous les 5 niveaux. 3 crédits offerts au départ.',
    ),
    rule(
      Icons.flag_rounded,
      '+3 par chapitre bouclé, +5 par boss vaincu',
      'La campagne du programme paie : 75 % des journées d\u2019un bloc, ou une semaine de tests réussie.',
    ),
    rule(
      Icons.event_available_rounded,
      '+1 par semaine complète',
      'Trois entraînements dans la semaine, séances ou WODs. Une semaine manquée ne retire rien.',
    ),
    rule(
      Icons.bolt_rounded,
      'Essai du jour offert',
      'Un WOD à l\u2019affiche, jouable jusqu\u2019à minuit. Terminé, il coûte 1 crédit de moins.',
    ),
    rule(
      Icons.storefront_rounded,
      'Vitrine de la semaine',
      'Trois WODs à −1 crédit, du lundi au dimanche. Pas de stock limité, pas de compte à rebours truqué.',
    ),
    rule(
      Icons.lock_open_rounded,
      'Un WOD débloqué le reste',
      'Rejoue-le à volonté, garde tes records. Le prix payé ne bouge jamais.',
    ),
  ]);
}

// ---------------------------------------------------------------------------
// Révélation au déblocage
// ---------------------------------------------------------------------------

/// Reflet qui balaie la couverture une fois, avec une légère respiration
/// d'échelle. Piloté par un contrôleur externe (0 → 1), sans boucle.
class UnlockReveal extends StatelessWidget {
  final Animation<double> progress;
  final Widget child;
  const UnlockReveal({super.key, required this.progress, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, c) {
      final t = progress.value;
      return Transform.scale(
        scale: 1 + .035 * math.sin(t * math.pi),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            c!,
            if (t > 0 && t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _SheenPainter(t)),
                ),
              ),
          ],
        ),
      );
    },
    child: child,
  );
}

class _SheenPainter extends CustomPainter {
  final double t;
  const _SheenPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final band = w * .45;
    final x = -band - w * .2 + t * (w + band + w * .4);
    final path =
        Path()
          ..moveTo(x, h)
          ..lineTo(x + band * .55, 0)
          ..lineTo(x + band * .55 + band, 0)
          ..lineTo(x + band, h)
          ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            KPalette.light.withValues(alpha: .38),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(x, 0, band + band * .55, h)),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}
