// Composants « jeu » : insigne de rang, radar d'attributs, feuille de
// personnage, objectif hebdomadaire, série avec boucliers, quêtes, campagne
// (chapitres), boss, saison, toi contre toi-même, titres, rareté des badges.
//
// Tout se dessine avec la charte (bordeaux, rouge, fonds sombres, vert de
// validation) et supporte 320 px avec texte à 130 % : les lignes longues
// passent en Wrap ou en Flexible, jamais en Row rigide.
//
// Les cartes qui lisent le store étendent `StoreWidget` : l'Aperçu et la
// feuille de campagne les instancient en `const`, elles se reconstruisent
// donc elles-mêmes après une séance, un score ou un réglage.
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'game.dart';
import 'progression.dart';
import 'stats_widgets.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';

Color rarityColor(BadgeRarity r) => switch (r) {
  BadgeRarity.commun => SL.dim,
  BadgeRarity.rare => SL.accent,
  BadgeRarity.epique => KPalette.actionRed,
  BadgeRarity.legendaire => SL.success,
};

/// Puce de rareté d'un badge.
class RarityChip extends StatelessWidget {
  final BadgeRarity rarity;
  const RarityChip(this.rarity, {super.key});
  @override
  Widget build(BuildContext context) => KBadge(
    rarityLabel(rarity),
    color: rarityColor(rarity),
    icon:
        rarity == BadgeRarity.legendaire
            ? Icons.auto_awesome_rounded
            : rarity == BadgeRarity.epique
            ? Icons.diamond_outlined
            : null,
  );
}

// ---------------------------------------------------------------------------
// Insigne de rang
// ---------------------------------------------------------------------------

/// Écusson : chevrons (1 à 3) puis étoiles selon le rang, anneau de prestige
/// au-delà du rang Légende.
class RankInsignia extends StatelessWidget {
  final int rankIndex; // 0 Recrue … 6 Légende
  final int prestige;
  final double size;
  final bool light; // rendu sur fond bordeaux
  const RankInsignia({
    super.key,
    required this.rankIndex,
    this.prestige = 0,
    this.size = 56,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _InsigniaPainter(
          rankIndex: rankIndex,
          prestige: prestige,
          light: light,
        ),
      ),
    ),
  );
}

class _InsigniaPainter extends CustomPainter {
  final int rankIndex, prestige;
  final bool light;
  const _InsigniaPainter({
    required this.rankIndex,
    required this.prestige,
    required this.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shield =
        Path()
          ..moveTo(w * .5, h * .04)
          ..lineTo(w * .92, h * .2)
          ..lineTo(w * .88, h * .62)
          ..quadraticBezierTo(w * .82, h * .84, w * .5, h * .97)
          ..quadraticBezierTo(w * .18, h * .84, w * .12, h * .62)
          ..lineTo(w * .08, h * .2)
          ..close();
    final fill =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KPalette.actionRed, KPalette.burgundy],
          ).createShader(Offset.zero & size);
    canvas.drawPath(shield, fill);
    final edge =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * .035)
          ..color = light ? KPalette.light : KPalette.lightRed;
    canvas.drawPath(shield, edge);
    if (prestige > 0) {
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * .56,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, w * .03)
          ..color = KPalette.light.withValues(alpha: .7),
      );
    }
    final mark =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.6, w * .07)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = KPalette.light;
    final chevrons = math.min(3, rankIndex + 1);
    final stars = math.max(0, rankIndex - 2) + prestige;
    final top = stars > 0 ? h * .42 : h * .34;
    final gap = h * .13;
    for (var i = 0; i < chevrons; i++) {
      final y = top + i * gap;
      canvas.drawPath(
        Path()
          ..moveTo(w * .3, y)
          ..lineTo(w * .5, y + h * .1)
          ..lineTo(w * .7, y),
        mark,
      );
    }
    if (stars > 0) {
      final n = math.min(4, stars);
      final r = w * .055;
      final total = n * r * 2.6;
      for (var i = 0; i < n; i++) {
        final cx = w / 2 - total / 2 + r * 1.3 + i * r * 2.6;
        _star(canvas, Offset(cx, h * .26), r, Paint()..color = KPalette.light);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * .45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        c.dx + radius * math.cos(a),
        c.dy + radius * math.sin(a),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_InsigniaPainter old) =>
      old.rankIndex != rankIndex ||
      old.prestige != prestige ||
      old.light != light;
}

int rankIndexOf(ProgressRank rank) => progressRanks.indexOf(rank);

// ---------------------------------------------------------------------------
// Radar d'attributs
// ---------------------------------------------------------------------------

class AttributeRadar extends StatelessWidget {
  final CharacterSheet sheet;
  final double size;
  final bool light;
  const AttributeRadar({
    super.key,
    required this.sheet,
    this.size = 120,
    this.light = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Attributs : ${sheet.attributes.map((a) => '${a.label} ${a.score} sur 100').join(', ')}.',
    child: ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RadarPainter(sheet, light)),
      ),
    ),
  );
}

class _RadarPainter extends CustomPainter {
  final CharacterSheet sheet;
  final bool light;
  const _RadarPainter(this.sheet, this.light);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 14;
    final grid =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = (light ? KPalette.light : SL.dim).withValues(alpha: .35);
    Offset at(int axis, double f) {
      final a = -math.pi / 2 + axis * math.pi / 2;
      return Offset(c.dx + r * f * math.cos(a), c.dy + r * f * math.sin(a));
    }

    for (final f in [.25, .5, .75, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(at(0, f).dx, at(0, f).dy)
          ..lineTo(at(1, f).dx, at(1, f).dy)
          ..lineTo(at(2, f).dx, at(2, f).dy)
          ..lineTo(at(3, f).dx, at(3, f).dy)
          ..close(),
        grid,
      );
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(c, at(i, 1), grid);
    }
    // Force en haut, Endurance à droite, Régularité en bas, Technique à gauche.
    final order = [
      sheet.force,
      sheet.endurance,
      sheet.regularite,
      sheet.technique,
    ];
    final poly = Path();
    for (var i = 0; i < 4; i++) {
      final p = at(i, math.max(.06, order[i].fraction));
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();
    canvas.drawPath(
      poly,
      Paint()
        ..shader = LinearGradient(
          colors: [
            KPalette.lightRed.withValues(alpha: .55),
            KPalette.actionRed.withValues(alpha: .35),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      poly,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = light ? KPalette.light : KPalette.lightRed,
    );
    final labels = ['F', 'E', 'R', 'T'];
    for (var i = 0; i < 4; i++) {
      final p = at(i, 1.22);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: light ? KPalette.light : SL.dim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.light != light ||
      old.sheet.attributes.map((a) => a.score).join() !=
          sheet.attributes.map((a) => a.score).join();
}

// ---------------------------------------------------------------------------
// Feuille de personnage (carte héros de l'aperçu)
// ---------------------------------------------------------------------------

class CharacterCard extends StoreWidget {
  final VoidCallback onTap;
  const CharacterCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = store.progression;
    final g = store.game;
    final next = p.nextRank;
    return KCard(
      color: SL.bordeaux,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RankInsignia(
                rankIndex: rankIndexOf(p.rank),
                prestige: GameState.prestigeOf(p.level),
                size: 54,
                light: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TON PERSONNAGE',
                      style: TextStyle(
                        color: KPalette.light,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Réduit plutôt que couper : un titre long reste lisible
                    // sur un écran étroit avec une grande police.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        store.displayTitle,
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'NIV.',
                    style: TextStyle(
                      color: KPalette.light,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${p.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          KProgressBar(
            value: p.fraction,
            height: 6,
            color: Colors.white,
            track: Colors.white.withValues(alpha: .2),
            semanticsLabel: 'Progression du niveau',
            semanticsValue: '${p.inLevel} sur ${p.need} XP',
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? '${p.remaining} XP avant le niveau ${p.level + 1} · rang maximal atteint'
                : '${p.remaining} XP avant le niveau ${p.level + 1} · ${next.title} au niveau ${next.level}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, bounds) {
              final wide =
                  bounds.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 17;
              final rows = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in g.sheet.attributes) ...[
                    _AttributeRow(a),
                    const SizedBox(height: 7),
                  ],
                ],
              );
              if (!wide) return rows;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: rows),
                  const SizedBox(width: 10),
                  AttributeRadar(sheet: g.sheet, size: 108, light: true),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              KBadge(
                'Série ${g.streak.weeks} sem.',
                color: KPalette.light,
                icon: Icons.local_fire_department_rounded,
              ),
              KBadge(
                '${g.streak.shields} bouclier${g.streak.shields > 1 ? 's' : ''}',
                color: KPalette.light,
                icon: Icons.shield_outlined,
              ),
              KBadge(
                '${p.earnedBadges} badges · ${store.credits} crédits',
                color: KPalette.light,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final GameAttribute a;
  const _AttributeRow(this.a);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 86,
        child: Text(
          a.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KPalette.light,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(
        child: KProgressBar(
          value: a.fraction,
          height: 5,
          color: Colors.white,
          track: Colors.white.withValues(alpha: .2),
          semanticsLabel: a.label,
          semanticsValue: '${a.score} sur 100, niveau ${a.level}',
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 26,
        child: Text(
          '${a.level}',
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

/// Fiche complète : attributs détaillés, titres, rangs et origine des XP.
void showCharacterSheet(BuildContext context) {
  final p = store.progression;
  final g = store.game;
  statsSheet(context, 'Ta feuille de personnage', [
    Row(
      children: [
        RankInsignia(
          rankIndex: rankIndexOf(p.rank),
          prestige: GameState.prestigeOf(p.level),
          size: 48,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Niveau ${p.level} · ${p.rank.title}${GameState.prestigeOf(p.level) > 0 ? ' · prestige ${GameState.prestigeOf(p.level)}' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ),
    StatsBar(
      value: p.fraction,
      label: 'Niveau',
      description: '${p.inLevel} sur ${p.need} XP',
    ),
    Text(
      '${p.remaining} XP avant le niveau ${p.level + 1} et +${p.nextCredits} crédit${p.nextCredits > 1 ? 's' : ''} WOD.',
    ),
    Text('${store.credits} crédits disponibles · ${p.totalXp} XP cumulés'),
    const KSection('Attributs'),
    Center(child: AttributeRadar(sheet: g.sheet, size: 170)),
    for (final a in g.sheet.attributes) ...[
      Row(
        children: [
          Expanded(
            child: Text(
              '${a.label} · niveau ${a.level}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text('${a.score} / 100'),
        ],
      ),
      StatsBar(
        value: a.fraction,
        label: a.label,
        description: '${a.score} sur 100',
      ),
      Text(a.hint, style: Theme.of(context).textTheme.bodySmall),
    ],
    const Text(
      'Les attributs se recalculent depuis tes références Pilotage, ton journal et tes WODs. Ils décrivent ton parcours, pas une norme.',
    ),
    const KSection('Tes rangs'),
    for (final rank in progressRanks)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: RankInsignia(rankIndex: rankIndexOf(rank), size: 36),
        title: Text(rank.title),
        subtitle: Text(
          'Niveau ${rank.level} · ${Progression.xpAtLevel(rank.level)} XP cumulés',
        ),
        trailing:
            rank == p.rank
                ? const KBadge('Actuel')
                : p.level >= rank.level
                ? Icon(Icons.verified_rounded, color: SL.success)
                : Icon(Icons.lock_outline_rounded, color: SL.dim),
      ),
    const Text(
      'Au-delà du rang Légende, chaque tranche de dix niveaux ajoute une étoile de prestige à ton insigne.',
    ),
    const KSection('Origine de tes XP'),
    for (final entry
        in <String, int>{
          'Programme': p.programXp,
          'Séances personnelles': p.customXp,
          'Tentatives WOD': p.wodXp,
          'Références et records WOD': p.recordXp,
          'Objectifs hebdomadaires': p.weeklyXp,
          'Badges': p.badgeXp,
        }.entries)
      Row(
        children: [
          Expanded(child: Text(entry.key)),
          const SizedBox(width: 12),
          Text(
            '${entry.value} XP',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
  ]);
}

// ---------------------------------------------------------------------------
// Objectif hebdomadaire adaptatif
// ---------------------------------------------------------------------------

class WeeklyGoalCard extends StoreWidget {
  const WeeklyGoalCard({super.key});
  @override
  Widget build(BuildContext context) {
    final w = store.game.weekly;
    final done = w.reached;
    return KCard(
      key: const ValueKey('game-weekly-goal'),
      onTap: () => showWeeklyGoal(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _Ring(
            fraction: w.fraction,
            size: 58,
            color: done ? SL.success : null,
            child: Text(
              '${w.done}/${w.target}',
              style: TextStyle(
                color: SL.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objectif de la semaine',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  done
                      ? 'Atteint · ${w.done} jour${w.done > 1 ? 's' : ''} actif${w.done > 1 ? 's' : ''}'
                      : '${w.target - w.done} jour${w.target - w.done > 1 ? 's' : ''} actif${w.target - w.done > 1 ? 's' : ''} à faire',
                  style: TextStyle(
                    color: done ? SL.success : SL.dim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  w.manual
                      ? 'Fixé par toi · ajustable'
                      : 'Adaptatif · moyenne ${statsNumber(w.history)} j sur 4 sem.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showWeeklyGoal(BuildContext context) {
  final w = store.game.weekly;
  statsSheet(context, 'Objectif de jours actifs par semaine', [
    Text(
      'Proposition adaptative : moyenne des quatre dernières semaines (${statsNumber(w.history)} jour${w.history >= 2 ? 's' : ''}) plus un, entre 2 et le nombre de journées prévues au programme. Tu peux la remplacer.',
    ),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final choice in [0, 2, 3, 4, 5, 6])
          ChoiceChip(
            label: Text(choice == 0 ? 'Adaptatif' : '$choice jours'),
            selected: store.settings.weeklyGoal == choice,
            onSelected: (_) {
              store.settings.weeklyGoal = choice;
              store.saveSettings();
              store.notifyListeners();
              Navigator.pop(context);
            },
          ),
      ],
    ),
    const Text(
      'Deux jours actifs valident toujours la semaine pour la série et les défis. Cet objectif est un cap personnel, sans XP : il sert à te situer, pas à te juger.',
    ),
  ]);
}

class _Ring extends StatelessWidget {
  final double fraction, size;
  final Widget child;
  final Color? color;
  const _Ring({
    required this.fraction,
    required this.size,
    required this.child,
    this.color,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(fraction, color ?? KPalette.actionRed),
          ),
        ),
        child,
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _RingPainter(this.fraction, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = SL.progressTrack,
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ---------------------------------------------------------------------------
// Série avec boucliers
// ---------------------------------------------------------------------------

class StreakCard extends StoreWidget {
  const StreakCard({super.key});
  @override
  Widget build(BuildContext context) {
    final g = store.game;
    final s = g.streak;
    return KCard(
      key: const ValueKey('game-streak'),
      onTap: () => showStreak(context),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: s.weeks > 0 ? KPalette.lightRed : SL.dim,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.weeks} semaine${s.weeks > 1 ? 's' : ''} de suite',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    for (var i = 0; i < 2; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          i < s.shields
                              ? Icons.shield_rounded
                              : Icons.shield_outlined,
                          size: 16,
                          color: i < s.shields ? SL.accent : SL.dim,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        g.deloadWeek
                            ? 'Semaine de deload : récupérer fait partie du plan'
                            : s.currentValidated
                            ? 'Semaine validée · série protégée'
                            : '${(2 - g.weekly.done).clamp(0, 2)} jour${(2 - g.weekly.done).clamp(0, 2) > 1 ? 's' : ''} pour valider la semaine',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

void showStreak(BuildContext context) {
  final s = store.game.streak;
  final p = store.progression;
  statsSheet(context, 'Ta série et tes boucliers', [
    Text(
      '${s.weeks} semaine${s.weeks > 1 ? 's' : ''} validée${s.weeks > 1 ? 's' : ''} d\u2019affilée · ${s.shields} bouclier${s.shields > 1 ? 's' : ''} en réserve · meilleure série : ${p.bestStreak}',
    ),
    const Text(
      'Une semaine est validée à partir de deux jours actifs, repos compris. Un bouclier couvre automatiquement une semaine manquée : tu en gagnes un toutes les trois semaines validées d\u2019affilée, deux en réserve au plus. La semaine en cours ne casse jamais la série avant le lundi suivant.',
    ),
    if (s.shieldedWeeks.isNotEmpty)
      Text(
        'Boucliers utilisés : ${s.shieldedWeeks.map((d) => 'semaine du ${statsDate(d)}').join(', ')}.',
      ),
    const Text(
      'Les semaines de deload du programme comptent comme les autres : une ou deux séances légères suffisent, l\u2019objectif est de récupérer.',
    ),
  ]);
}

// ---------------------------------------------------------------------------
// Quêtes
// ---------------------------------------------------------------------------

/// Quête principale : la prochaine journée du programme (ou celle du jour).
class MainQuestCard extends StoreWidget {
  const MainQuestCard({super.key});
  @override
  Widget build(BuildContext context) {
    final program = store.program;
    final now = DateTime.now();
    final g = store.game;
    if (g.programWeek == 0) {
      return KCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, color: SL.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quête principale : reprendre le programme, ou une séance personnelle depuis l\u2019Arsenal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    final week = program.week(g.programWeek);
    final today = program.dayFor(now);
    final day =
        week.day(today) ??
        week.days.firstWhere(
          (d) => d.exercises.isNotEmpty,
          orElse: () => week.days.first,
        );
    final done = store.isDone(week.n, day.j);
    final rest = day.exercises.isEmpty;
    return KCard(
      key: const ValueKey('game-main-quest'),
      outline: done ? null : SL.accent.withValues(alpha: .45),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : rest
                    ? Icons.bedtime_rounded
                    : Icons.flag_rounded,
                color: done ? SL.success : SL.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quête principale · S${week.n} J${day.j}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(day.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            done
                ? 'Validée · XP et bonus déjà comptés'
                : rest
                ? 'Jour de repos prévu : la série est protégée, la récupération compte.'
                : g.deloadWeek
                ? 'Deload : séance allégée, objectif ≥ ${(g.sessionGoal * 100).round()} % des séries sans forcer.'
                : 'Objectif de séance : valider au moins ${(g.sessionGoal * 100).round()} % des séries.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Quêtes de saison (titres) : exploration des formats et respect des deloads.
class SeasonQuests extends StoreWidget {
  const SeasonQuests({super.key});
  @override
  Widget build(BuildContext context) {
    final titles = store.game.titles.where(
      (t) => t.id == 'explorer' || t.id == 'guardian',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in titles)
          KCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  t.earned ? Icons.verified_rounded : Icons.explore_outlined,
                  color: t.earned ? SL.success : SL.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.source,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        t.earned
                            ? 'Titre obtenu : ${t.name}'
                            : 'Récompense : titre « ${t.name} »',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Campagne, boss, saisons
// ---------------------------------------------------------------------------

class CampaignStrip extends StoreWidget {
  const CampaignStrip({super.key});
  @override
  Widget build(BuildContext context) {
    final chapters = store.game.chapters;
    return SingleChildScrollView(
      key: const ValueKey('game-campaign'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < chapters.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 14,
                  height: 70,
                  child: Center(
                    child: Container(
                      height: 2,
                      color: chapters[i - 1].complete ? SL.success : SL.line,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 168, child: _ChapterCard(chapters[i])),
          ],
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter c;
  const _ChapterCard(this.c);
  @override
  Widget build(BuildContext context) {
    final status =
        c.complete
            ? 'Bouclé'
            : c.current
            ? 'En cours'
            : c.doneDays > 0
            ? '${(c.fraction * 100).round()} %'
            : 'À venir';
    final color =
        c.complete
            ? SL.success
            : c.current
            ? SL.accent
            : SL.dim;
    return KCard(
      padding: const EdgeInsets.all(14),
      outline: c.current ? SL.accent.withValues(alpha: .5) : null,
      onTap: () => showChapter(context, c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                c.complete
                    ? Icons.verified_rounded
                    : c.current
                    ? Icons.play_circle_outline_rounded
                    : Icons.lock_outline_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'S${c.firstWeek} → S${c.lastWeek} · ${c.doneDays}/${c.trainingDays} journées',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          StatsBar(
            value: c.fraction,
            label: c.name,
            description: '${c.doneDays} sur ${c.trainingDays}',
            color: c.complete ? SL.success : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Titre : ${c.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: SL.dim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

void showChapter(BuildContext context, Chapter c) {
  statsSheet(context, c.name, [
    Text(
      'Semaines S${c.firstWeek} à S${c.lastWeek} · ${c.doneDays} journées validées sur ${c.trainingDays}.',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    StatsBar(
      value: c.fraction,
      label: c.name,
      description: '${c.doneDays} sur ${c.trainingDays}',
    ),
    Text(
      c.complete
          ? 'Chapitre bouclé : titre « ${c.title} » obtenu et +${GameState.creditsPerChapter} crédits WOD.'
          : 'À 75 % des journées d\u2019entraînement validées, le chapitre est bouclé : titre « ${c.title} » et +${GameState.creditsPerChapter} crédits WOD. Les imprévus ne bloquent pas la campagne.',
    ),
  ]);
}

class BossCard extends StoreWidget {
  const BossCard({super.key});
  @override
  Widget build(BuildContext context) {
    final g = store.game;
    final boss = g.nextBoss;
    final defeated = g.bosses.where((b) => b.defeated).length;
    if (boss == null) {
      return KCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: SL.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tous les boss sont vaincus : $defeated semaines de tests bouclées.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    final weeksAway = boss.firstWeek - g.programWeek;
    final started =
        boss.done > 0 ||
        (g.programWeek >= boss.firstWeek && g.programWeek <= boss.lastWeek);
    final hint =
        started
            ? '${boss.done}/${boss.tests.length} tests validés · un seul test lourd par jour'
            : weeksAway <= 0
            ? 'Tests à rattraper : ${boss.tests.length} journées'
            : weeksAway == 1
            ? 'La semaine prochaine · deload conseillé avant'
            : 'Dans $weeksAway semaines (S${boss.firstWeek})';
    return KCard(
      key: const ValueKey('game-boss'),
      onTap: () => showBoss(context, boss),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.sports_martial_arts_rounded,
            color: started ? KPalette.lightRed : SL.accent,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BOSS · ${boss.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(hint, style: Theme.of(context).textTheme.bodySmall),
                if (defeated > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '$defeated boss vaincu${defeated > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: SL.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showBoss(BuildContext context, Boss boss) {
  final program = store.program;
  statsSheet(context, 'Boss · ${boss.name}', [
    Text(
      'Semaine${boss.lastWeek > boss.firstWeek ? 's' : ''} S${boss.firstWeek}${boss.lastWeek > boss.firstWeek ? ' à S${boss.lastWeek}' : ''} · ${boss.done} test${boss.done > 1 ? 's' : ''} validé${boss.done > 1 ? 's' : ''} sur ${boss.tests.length}.',
      style: Theme.of(context).textTheme.titleMedium,
    ),
    for (final (week, day) in boss.tests)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          store.isDone(week, day)
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: store.isDone(week, day) ? SL.success : SL.dim,
        ),
        title: Text(program.week(week).day(day)?.title ?? 'Test'),
        subtitle: Text('S$week · J$day'),
      ),
    Text(
      boss.defeated
          ? 'Boss vaincu : titre « ${boss.title} » et +${GameState.creditsPerBoss} crédits WOD.'
          : 'Un seul test lourd par jour, en tête de séance. Le deload qui précède fait partie du combat : arrive reposé. Récompense : titre « ${boss.title} » et +${GameState.creditsPerBoss} crédits WOD.',
    ),
  ]);
}

class SeasonCard extends StoreWidget {
  const SeasonCard({super.key});
  @override
  Widget build(BuildContext context) {
    final g = store.game;
    final s = g.currentSeason;
    if (s == null) {
      return KCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Hors programme : les saisons reprennent avec le calendrier des 40 semaines.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final left = s.lastWeek - g.programWeek + 1;
    return KCard(
      key: const ValueKey('game-season'),
      onTap: () => showSeasons(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: SL.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saison ${s.index} · ${s.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'S${s.firstWeek} → S${s.lastWeek} · $left semaine${left > 1 ? 's' : ''} restante${left > 1 ? 's' : ''} · ${(s.fraction * 100).round()} %',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          StatsBar(
            value: s.fraction,
            label: 'Saison ${s.index}',
            description: '${s.doneDays} sur ${s.trainingDays}',
            color: s.complete ? SL.success : null,
          ),
          const SizedBox(height: 8),
          Text(
            s.complete
                ? 'Saison bouclée : titre « ${s.title} » obtenu'
                : 'À 70 % des journées : titre « ${s.title} »',
            style: TextStyle(color: SL.dim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

void showSeasons(BuildContext context) {
  final g = store.game;
  statsSheet(context, 'Saisons', [
    const Text(
      'Quatre saisons de dix semaines rythment le programme. Chaque saison bouclée à 70 % donne son titre ; la campagne, les boss et les badges continuent d\u2019une saison à l\u2019autre, rien n\u2019est remis à zéro.',
    ),
    for (final s in g.seasons)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          s.complete
              ? Icons.verified_rounded
              : s.current
              ? Icons.play_circle_outline_rounded
              : Icons.lock_outline_rounded,
          color:
              s.complete
                  ? SL.success
                  : s.current
                  ? SL.accent
                  : SL.dim,
        ),
        title: Text('Saison ${s.index} · ${s.name}'),
        subtitle: Text(
          'S${s.firstWeek} → S${s.lastWeek} · ${s.doneDays}/${s.trainingDays} journées · titre « ${s.title} »',
        ),
      ),
  ]);
}

/// Résumé d'une ligne pour la tuile du Parcours (sans nom de rang).
String campaignSummary(GameState g) {
  final done = g.chapters.where((c) => c.complete).length;
  final bosses = g.bosses.where((b) => b.defeated).length;
  final current = g.currentChapter;
  final head = current == null ? 'Hors programme' : current.name;
  return '$head · $done/${g.chapters.length} chapitres bouclés · $bosses/${g.bosses.length} boss vaincus';
}

/// Feuille complète de la campagne : chapitres, boss, saisons et quêtes de
/// saison, pour le Parcours (l'aperçu garde les cartes).
void showCampaign(BuildContext context) {
  final g = store.game;
  statsSheet(context, 'Campagne', [
    const Text(
      'Un chapitre par bloc du programme, bouclé à 75 % des journées d\u2019entraînement : titre et +${GameState.creditsPerChapter} crédits WOD. Les semaines de tests sont les boss (+${GameState.creditsPerBoss} crédits) ; quatre saisons de dix semaines rythment le tout. Rien n\u2019est remis à zéro.',
    ),
    const KSection('Chapitres'),
    const CampaignStrip(),
    const KSection('Boss'),
    const BossCard(),
    for (final b in g.bosses)
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          b.defeated
              ? Icons.verified_rounded
              : Icons.sports_martial_arts_rounded,
          color: b.defeated ? SL.success : SL.dim,
        ),
        title: Text(b.name),
        subtitle: Text(
          'S${b.firstWeek}${b.lastWeek > b.firstWeek ? '-S${b.lastWeek}' : ''} · ${b.done}/${b.tests.length} tests · titre « ${b.title} »',
        ),
        onTap: () => showBoss(context, b),
      ),
    const KSection('Saison'),
    const SeasonCard(),
    const SeasonQuests(),
  ]);
}

// ---------------------------------------------------------------------------
// Toi contre toi-même
// ---------------------------------------------------------------------------

class SelfCompareCard extends StoreWidget {
  const SelfCompareCard({super.key});
  @override
  Widget build(BuildContext context) {
    final c = store.game.compare;
    Widget delta(String label, int now, int diff) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$now',
          style: TextStyle(
            color: SL.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          diff == 0
              ? '= sem. passée'
              : '${diff > 0 ? '+' : ''}$diff vs sem. passée',
          style: TextStyle(
            color:
                diff > 0
                    ? SL.success
                    : diff < 0
                    ? SL.accent
                    : SL.dim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    return KCard(
      key: const ValueKey('game-compare'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toi contre toi-même',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              delta(
                'entraînements',
                c.current.sessions + c.current.wods,
                c.sessionsDelta,
              ),
              delta('séries', c.current.sets, c.setsDelta),
              delta('jours actifs', c.current.activeDays.length, c.daysDelta),
            ],
          ),
          if (c.best != null) ...[
            const SizedBox(height: 10),
            Text(
              'Meilleure semaine : ${c.best!.sets} séries, semaine du ${statsDate(c.best!.monday)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Titres
// ---------------------------------------------------------------------------

void showTitles(BuildContext context) {
  final titles = store.game.titles;
  final earned = titles.where((t) => t.earned).length;
  statsSheet(context, 'Tes titres', [
    Text(
      '$earned titre${earned > 1 ? 's' : ''} obtenu${earned > 1 ? 's' : ''} sur ${titles.length}. Le titre choisi s\u2019affiche sur ta feuille de personnage à la place du rang.',
    ),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        store.settings.title.isEmpty
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: store.settings.title.isEmpty ? SL.success : SL.dim,
      ),
      title: const Text('Afficher mon rang'),
      onTap: () {
        store.settings.title = '';
        store.saveSettings();
        store.notifyListeners();
        Navigator.pop(context);
      },
    ),
    for (final t in titles)
      ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: t.earned,
        leading: Icon(
          !t.earned
              ? Icons.lock_outline_rounded
              : store.settings.title == t.name
              ? Icons.check_circle_rounded
              : Icons.workspace_premium_rounded,
          color:
              !t.earned
                  ? SL.dim
                  : store.settings.title == t.name
                  ? SL.success
                  : SL.accent,
        ),
        title: Text(t.name),
        subtitle: Text(t.source),
        onTap:
            t.earned
                ? () {
                  store.settings.title = t.name;
                  store.saveSettings();
                  store.notifyListeners();
                  Navigator.pop(context);
                }
                : null,
      ),
  ]);
}
