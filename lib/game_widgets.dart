// Composants « jeu » : insigne de rang, radar d'attributs, feuille de
// personnage, objectif hebdomadaire, série avec boucliers, quêtes, campagne
// (chapitres), boss, saison, toi contre toi-même, titres, rareté des badges.
//
// UI3 (refonte UI) : tout passe par les jetons du kit (cahier §5) et suit la
// palette choisie ; les feuilles de jeu ne s'ouvrent que depuis Parcours
// (cahier §4.1) et n'en ouvrent jamais une autre (plus de feuille empilée).
// Supporte 320 dp et 200 % de texte : rien n'est coupé, les lignes longues
// passent à la ligne.
//
// Les cartes qui lisent le store étendent `StoreWidget` : l'Aperçu et les
// feuilles les instancient en `const`, elles se reconstruisent donc
// elles-mêmes après une séance, un score ou un réglage.
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'game.dart';
import 'kalis_clock.dart';
import 'kit/kit.dart';
import 'progression.dart';
import 'stats_widgets.dart';
import 'store.dart';
import 'store_widget.dart';

String _plural(int n, String one, String many) => '$n ${n > 1 ? many : one}';

/// R9 : les textes d'aide des attributs (game.dart, hors zone) nomment
/// encore l'ancienne page ; affichés sous le nom de sa destination.
String _r9(String text) => text
    .replaceAll('références Pilotage', 'Mes références')
    .replaceAll('(Références)', '(Mes références)');

/// Puce de rareté d'un badge : neutre (C5), l'icône distingue les raretés.
class RarityChip extends StatelessWidget {
  final BadgeRarity rarity;
  const RarityChip(this.rarity, {super.key});
  @override
  Widget build(BuildContext context) => KChip(
    rarityLabel(rarity),
    icon: switch (rarity) {
      BadgeRarity.commun => null,
      BadgeRarity.rare => Icons.star_outline_rounded,
      BadgeRarity.epique => Icons.diamond_outlined,
      BadgeRarity.legendaire => Icons.auto_awesome_rounded,
    },
  );
}

// ---------------------------------------------------------------------------
// Insigne de rang
// ---------------------------------------------------------------------------

/// Écusson : chevrons (1 à 3) puis étoiles selon le rang, anneau de prestige
/// au-delà du rang Légende. Aplat de la dominante (`pleine`), marques en
/// `surPleine` ; [light] : posé sur l'aplat `pleine` (carte du personnage,
/// récompenses), contour en `surPleine`.
class RankInsignia extends StatelessWidget {
  final int rankIndex; // 0 Recrue … 6 Légende
  final int prestige;
  final double size;
  final bool light;
  const RankInsignia({
    super.key,
    required this.rankIndex,
    this.prestige = 0,
    this.size = 56,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _InsigniaPainter(
            rankIndex: rankIndex,
            prestige: prestige,
            fill: k.pleine,
            edge: light ? k.surPleine : k.encre,
            mark: k.surPleine,
          ),
        ),
      ),
    );
  }
}

/// Peintre de l'insigne (liste blanche : dessin de données, proportions
/// relatives à la taille ; couleurs reçues des jetons).
class _InsigniaPainter extends CustomPainter {
  final int rankIndex, prestige;
  final Color fill, edge, mark;
  const _InsigniaPainter({
    required this.rankIndex,
    required this.prestige,
    required this.fill,
    required this.edge,
    required this.mark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shield = Path()
      ..moveTo(w * .5, h * .04)
      ..lineTo(w * .92, h * .2)
      ..lineTo(w * .88, h * .62)
      ..quadraticBezierTo(w * .82, h * .84, w * .5, h * .97)
      ..quadraticBezierTo(w * .18, h * .84, w * .12, h * .62)
      ..lineTo(w * .08, h * .2)
      ..close();
    canvas.drawPath(shield, Paint()..color = fill);
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * .035)
        ..color = edge,
    );
    if (prestige > 0) {
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * .56,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, w * .03)
          ..color = edge.withValues(alpha: .7),
      );
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, w * .07)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = mark;
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
        stroke,
      );
    }
    if (stars > 0) {
      final n = math.min(4, stars);
      final r = w * .055;
      final total = n * r * 2.6;
      for (var i = 0; i < n; i++) {
        final cx = w / 2 - total / 2 + r * 1.3 + i * r * 2.6;
        _star(canvas, Offset(cx, h * .26), r, Paint()..color = mark);
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
      old.fill != fill ||
      old.edge != edge ||
      old.mark != mark;
}

int rankIndexOf(ProgressRank rank) => progressRanks.indexOf(rank);

// ---------------------------------------------------------------------------
// Radar d'attributs
// ---------------------------------------------------------------------------

/// Radar des quatre attributs : polygone en `encre` (en `surPleine` sur
/// l'aplat de la carte du personnage, [light]).
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
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final ink = light ? k.surPleine : k.encre;
    return Semantics(
      label:
          'Attributs : ${sheet.attributes.map((a) => a.available ? '${a.label} ${a.score} sur 100' : '${a.label} indisponible').join(', ')}.',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RadarPainter(
              sheet,
              ink: ink,
              grid: (light ? k.surPleine : k.texte2).withValues(alpha: .35),
              label: KType.micro.copyWith(
                color: light ? k.surPleine : k.texte2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Peintre du radar (liste blanche : dessin de données ; couleurs et style
/// de texte reçus des jetons).
class _RadarPainter extends CustomPainter {
  final CharacterSheet sheet;
  final Color ink, grid;
  final TextStyle label;
  const _RadarPainter(
    this.sheet, {
    required this.ink,
    required this.grid,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 14;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid;
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
        gridPaint,
      );
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(c, at(i, 1), gridPaint);
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
    canvas.drawPath(poly, Paint()..color = ink.withValues(alpha: .3));
    canvas.drawPath(
      poly,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
    final labels = ['F', 'E', 'R', 'T'];
    for (var i = 0; i < 4; i++) {
      final p = at(i, 1.22);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.ink != ink ||
      old.grid != grid ||
      old.label != label ||
      old.sheet.attributes.map((a) => a.score).join() !=
          sheet.attributes.map((a) => a.score).join();
}

// ---------------------------------------------------------------------------
// Feuille de personnage (carte héros de l'aperçu)
// ---------------------------------------------------------------------------

/// Carte du personnage : aplat de la dominante (`pleine`), texte
/// `surPleine`. Dans l'Aperçu, elle ouvre Parcours (seule entrée de la
/// feuille de personnage, cahier §4.1).
class CharacterCard extends StoreWidget {
  final VoidCallback onTap;
  const CharacterCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final p = store.progression;
    final g = store.game;
    final next = p.nextRank;
    final ink = k.surPleine;
    final soft = k.surPleine.withValues(alpha: .8);
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final insignia = RankInsignia(
      rankIndex: rankIndexOf(p.rank),
      prestige: GameState.prestigeOf(p.level),
      size: KSize.primary,
      light: true,
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ton personnage', style: KType.micro.copyWith(color: soft)),
        const SizedBox(height: KSpacing.s4 / 2),
        // C3 : le titre passe à la ligne, jamais coupé.
        Text(store.displayTitle, style: KType.titreEcran.copyWith(color: ink)),
      ],
    );
    final level = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Niveau', style: KType.micro.copyWith(color: soft)),
        Text('${p.level}', style: KType.chiffre.copyWith(color: ink)),
      ],
    );
    return KCard.day(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Au-delà de 150 % de texte, le titre passe sous l'insigne et le
          // niveau, sur toute la largeur (plus de mot coupé).
          if (large) ...[
            Row(children: [insignia, const Spacer(), level]),
            const SizedBox(height: KSpacing.s8),
            title,
          ] else
            Row(
              children: [
                insignia,
                const SizedBox(width: KSpacing.s14),
                Expanded(child: title),
                const SizedBox(width: KSpacing.s8),
                level,
              ],
            ),
          const SizedBox(height: KSpacing.s16),
          StatsBar(
            value: p.fraction,
            label: 'Progression du niveau',
            description: '${p.inLevel} sur ${p.need} XP',
            onFill: true,
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            next == null
                ? '${p.remaining} XP avant le niveau ${p.level + 1}\u00A0· rang maximal atteint'
                : '${p.remaining} XP avant le niveau ${p.level + 1}\u00A0· ${next.title} au niveau ${next.level}',
            style: KType.detail.copyWith(color: ink),
          ),
          const SizedBox(height: KSpacing.s16),
          LayoutBuilder(
            builder: (context, bounds) {
              final wide = bounds.maxWidth >= 300 && !large;
              final rows = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final a in g.sheet.attributes) ...[
                    _AttributeRow(a),
                    const SizedBox(height: KSpacing.s8),
                  ],
                ],
              );
              if (!wide) return rows;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: rows),
                  const SizedBox(width: KSpacing.s12),
                  AttributeRadar(
                    sheet: g.sheet,
                    size: KSize.primary * 2,
                    light: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: KSpacing.s4),
          Wrap(
            spacing: KSpacing.s16,
            runSpacing: KSpacing.s4,
            children: [
              _OnFillFact(
                Icons.local_fire_department_rounded,
                'Série de ${_plural(g.streak.weeks, 'semaine', 'semaines')}',
              ),
              _OnFillFact(
                Icons.shield_outlined,
                _plural(g.streak.shields, 'bouclier', 'boucliers'),
              ),
              _OnFillFact(
                Icons.verified_outlined,
                _plural(p.earnedBadges, 'badge', 'badges'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fait court posé sur l'aplat : icône et texte en `surPleine`.
class _OnFillFact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _OnFillFact(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final ink = KTokens.of(context).surPleine;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KSpacing.s32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: KSize.chevron, color: ink),
          const SizedBox(width: KSpacing.s4),
          Flexible(
            child: Text(text, style: KType.detail.copyWith(color: ink)),
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
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final label = Text(
      a.label,
      style: KType.micro.copyWith(color: k.surPleine.withValues(alpha: .8)),
    );
    final value = Text(
      a.available ? '${a.level}' : '—',
      textAlign: TextAlign.end,
      style: KType.chiffrePetit.copyWith(color: k.surPleine),
    );
    final bar = StatsBar(
      value: a.fraction,
      label: a.label,
      description: a.available
          ? '${a.score} sur 100, niveau ${a.level}'
          : 'indisponible',
      onFill: true,
    );
    // Grand texte : le libellé au-dessus de la jauge, jamais coupé.
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: label),
              value,
            ],
          ),
          const SizedBox(height: KSpacing.s4),
          bar,
        ],
      );
    }
    return Row(
      children: [
        SizedBox(width: KSize.valueWidth * .6, child: label),
        Expanded(child: bar),
        const SizedBox(width: KSpacing.s8),
        SizedBox(width: KSpacing.s24, child: value),
      ],
    );
  }
}

/// Fiche complète : attributs détaillés, rangs et origine des XP.
void showCharacterSheet(BuildContext context) {
  final p = store.progression;
  final g = store.game;
  final prestige = GameState.prestigeOf(p.level);
  statsSheet(
    context,
    'Ta feuille de personnage',
    subtitle:
        'Niveau ${p.level}\u00A0· ${p.rank.title}${prestige > 0 ? ' · prestige $prestige' : ''}',
    [
      Builder(
        builder: (context) {
          final k = KTokens.of(context);
          return Row(
            children: [
              RankInsignia(
                rankIndex: rankIndexOf(p.rank),
                prestige: prestige,
                size: KSize.target,
              ),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatsBar(
                      value: p.fraction,
                      label: 'Niveau',
                      description: '${p.inLevel} sur ${p.need} XP',
                    ),
                    const SizedBox(height: KSpacing.s8),
                    Text(
                      '${p.remaining} XP avant le niveau ${p.level + 1}\u00A0· ${p.totalXp} XP cumulés.',
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      const KSectionTitle('Attributs'),
      Center(
        child: AttributeRadar(sheet: g.sheet, size: KSize.primary * 3),
      ),
      for (final a in g.sheet.attributes) _AttributeDetail(a),
      const StatsText(
        'Les attributs se recalculent depuis Mes références et ton journal. Ils décrivent ton parcours, pas une norme.',
        muted: true,
      ),
      const KSectionTitle('Tes rangs'),
      StatsSheetGroup(
        children: [
          for (final rank in progressRanks)
            Builder(
              builder: (context) {
                final k = KTokens.of(context);
                return StatsSheetRow(
                  leading: RankInsignia(
                    rankIndex: rankIndexOf(rank),
                    size: KSpacing.s32,
                  ),
                  title: rank.title,
                  subtitle:
                      'Niveau ${rank.level}\u00A0· ${Progression.xpAtLevel(rank.level)} XP cumulés',
                  trailing: rank == p.rank
                      ? const KChip('Actuel')
                      : Icon(
                          p.level >= rank.level
                              ? Icons.verified_rounded
                              : Icons.lock_outline_rounded,
                          size: KSize.icon,
                          color: p.level >= rank.level
                              ? k.validation
                              : k.texte2,
                        ),
                );
              },
            ),
        ],
      ),
      const StatsText(
        'Au-delà du rang Légende, chaque tranche de dix niveaux ajoute une étoile de prestige à ton insigne.',
        muted: true,
      ),
      const KSectionTitle('Origine de tes XP'),
      StatsSheetGroup(
        children: [
          for (final entry in <String, int>{
            'Programme': p.programXp,
            'Objectifs hebdomadaires': p.weeklyXp,
            'Badges': p.badgeXp,
          }.entries)
            StatsSheetRow(title: entry.key, value: '${entry.value} XP'),
        ],
      ),
    ],
  );
}

/// Attribut détaillé de la feuille de personnage.
class _AttributeDetail extends StatelessWidget {
  final GameAttribute a;
  const _AttributeDetail(this.a);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  a.available
                      ? '${a.label}\u00A0· niveau ${a.level}'
                      : '${a.label}\u00A0· indisponible',
                  style: KType.corpsFort.copyWith(color: k.texte),
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              Text(
                a.available ? '${a.score}\u00A0/\u00A0100' : '—',
                style: KType.corps.copyWith(color: k.texte),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          StatsBar(
            value: a.available ? a.fraction : 0,
            label: a.label,
            description: a.available ? '${a.score} sur 100' : 'indisponible',
          ),
          const SizedBox(height: KSpacing.s8),
          Text(_r9(a.hint), style: KType.detail.copyWith(color: k.texte2)),
          if (a.note != null)
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s4),
              child: Text(
                _r9(a.note!),
                key: ValueKey('attribute-note-${a.id}'),
                style: KType.detail.copyWith(color: k.texte),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Objectif hebdomadaire adaptatif
// ---------------------------------------------------------------------------

/// Valeurs de l'objectif de la semaine (cahier §4.3) : mêmes segments que
/// Réglages › Progression et jeu ; 0 = adaptatif.
const kWeeklyGoalChoices = [0, 2, 3, 4, 5, 6];

/// Carte « Objectif de la semaine » : anneau de la semaine, état, et le
/// réglage en place (raccourci R2 : même contrôle et mêmes valeurs que
/// Réglages). Une valeur 1 déjà enregistrée reste affichée telle quelle
/// jusqu'au prochain choix (aucun segment allumé), sans migration.
class WeeklyGoalCard extends StoreWidget {
  const WeeklyGoalCard({super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final w = store.game.weekly;
    final goal = store.settings.weeklyGoal;
    final done = w.reached;
    final left = w.target - w.done;
    return KCard(
      key: const ValueKey('game-weekly-goal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Ring(
                fraction: w.fraction,
                size: KSize.primary,
                color: done ? k.validation : k.encre,
                child: Text(
                  '${w.done}/${w.target}',
                  style: KType.chiffrePetit.copyWith(color: k.texte),
                ),
              ),
              const SizedBox(width: KSpacing.s14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectif de la semaine',
                      style: KType.titreCarte.copyWith(color: k.texte),
                    ),
                    Text(
                      done
                          ? 'Atteint\u00A0· ${_plural(w.done, 'jour actif', 'jours actifs')}'
                          : '${_plural(left, 'jour actif', 'jours actifs')} à faire',
                      style: KType.corpsFort.copyWith(
                        color: done ? k.validation : k.texte,
                      ),
                    ),
                    Text(
                      w.manual
                          ? 'Fixé par toi : ${_plural(goal, 'jour', 'jours')} par semaine'
                          : 'Adaptatif : moyenne de ${statsNumber(w.history)} j sur 4 semaines, plus un',
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s16),
          KSegmented<int>(
            semanticLabel: 'Objectif de la semaine',
            segments: [
              for (final c in kWeeklyGoalChoices)
                KSegment(
                  c,
                  c == 0 ? 'Adaptatif' : '$c',
                  semanticLabel: c == 0
                      ? 'Adaptatif'
                      : '$c jours actifs par semaine',
                ),
            ],
            selected: goal,
            onChanged: (choice) {
              store.settings.weeklyGoal = choice;
              store.saveSettings();
              store.notifyListeners();
            },
          ),
          const SizedBox(height: KSpacing.s12),
          Text(
            'Adaptatif : la moyenne de tes quatre dernières semaines plus un, entre 2 et le nombre de journées prévues au programme. Deux jours actifs valident toujours la semaine pour la série et les défis ; cet objectif est un cap personnel, sans XP.',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double fraction, size;
  final Widget child;
  final Color color;
  const _Ring({
    required this.fraction,
    required this.size,
    required this.child,
    required this.color,
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
            painter: _RingPainter(fraction, color, KTokens.of(context).filet),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Peintre de l'anneau (liste blanche : dessin de données).
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color, track;
  const _RingPainter(this.fraction, this.color, this.track);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = KSpacing.s4 * 1.5;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

// ---------------------------------------------------------------------------
// Série avec boucliers
// ---------------------------------------------------------------------------

class StreakCard extends StoreWidget {
  const StreakCard({super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final g = store.game;
    final s = g.streak;
    final missing = (2 - g.weekly.done).clamp(0, 2);
    return KCard(
      key: const ValueKey('game-streak'),
      onTap: () => showStreak(context),
      child: Row(
        children: [
          KIconTile(
            Icons.local_fire_department_rounded,
            color: s.weeks > 0 ? k.accent : k.texte2,
          ),
          const SizedBox(width: KSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_plural(s.weeks, 'semaine', 'semaines')} de suite',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                const SizedBox(height: KSpacing.s4),
                Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      label: _plural(s.shields, 'bouclier', 'boucliers'),
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 2; i++)
                              Icon(
                                i < s.shields
                                    ? Icons.shield_rounded
                                    : Icons.shield_outlined,
                                size: KSize.chevron,
                                color: i < s.shields ? k.encre : k.texte3,
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      g.deloadWeek
                          ? 'Semaine de deload : récupérer fait partie du plan'
                          : s.currentValidated
                          ? 'Semaine validée\u00A0· série protégée'
                          : '${_plural(missing, 'jour', 'jours')} pour valider la semaine',
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: KSpacing.s8),
          Icon(Icons.chevron_right_rounded, size: KSize.icon, color: k.texte2),
        ],
      ),
    );
  }
}

void showStreak(BuildContext context) {
  final s = store.game.streak;
  final p = store.progression;
  statsSheet(
    context,
    'Ta série et tes boucliers',
    subtitle:
        '${_plural(s.weeks, 'semaine validée', 'semaines validées')} d’affilée\u00A0· ${_plural(s.shields, 'bouclier', 'boucliers')} en réserve\u00A0· meilleure série : ${p.bestStreak}',
    [
      const StatsText(
        'Une semaine est validée à partir de deux jours actifs, repos compris. Un bouclier couvre automatiquement une semaine manquée : tu en gagnes un toutes les trois semaines validées d’affilée, deux en réserve au plus. La semaine en cours ne casse jamais la série avant le lundi suivant.',
      ),
      if (s.shieldedWeeks.isNotEmpty)
        StatsText(
          'Boucliers utilisés : ${s.shieldedWeeks.map((d) => 'semaine du ${statsDate(d)}').join(', ')}.',
        ),
      const StatsText(
        'Les semaines de deload du programme comptent comme les autres : une ou deux séances légères suffisent, l’objectif est de récupérer.',
        muted: true,
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Quêtes
// ---------------------------------------------------------------------------

/// Quête principale : la prochaine journée du programme (ou celle du jour).
class MainQuestCard extends StoreWidget {
  const MainQuestCard({super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final program = store.program;
    final now = KalisClock.now();
    final g = store.game;
    if (g.programWeek == 0) {
      // G2 : plus de séance personnelle depuis l'Arsenal ; aucun chemin
      // écrit (R5).
      return KCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.flag_rounded, color: k.encre, size: KSize.icon),
            const SizedBox(width: KSpacing.s12),
            Expanded(
              child: Text(
                !program.scheduled
                    ? 'Quête principale : ton programme commence dès que tu choisis ta date de départ.'
                    : program.beforeStart(now)
                    ? 'Quête principale : ton programme démarre le ${civilDateLabel(program.start!)}.'
                    : program.afterEnd(now)
                    ? 'Programme terminé : ton historique reste consultable.'
                    : 'Quête principale : reprendre ton programme.',
                style: KType.corps.copyWith(color: k.texte),
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
    final goal = (g.sessionGoal * 100).round();
    return KCard(
      key: const ValueKey('game-main-quest'),
      outline: done ? null : k.encre,
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
                color: done ? k.validation : k.encre,
                size: KSize.icon,
              ),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Text(
                  'Quête principale\u00A0· S${week.n} J${day.j}',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          Text(day.title, style: KType.corpsFort.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s4),
          Text(
            done
                ? 'Validée\u00A0· XP et bonus déjà comptés'
                : rest
                ? 'Jour de repos prévu : la série est protégée, la récupération compte.'
                : g.deloadWeek
                ? 'Deload : séance allégée, objectif ≥ $goal\u00A0% des séries sans forcer.'
                : 'Objectif de séance : valider au moins $goal\u00A0% des séries.',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
}

/// Quêtes de saison (titres) : exploration des formats et respect des
/// deloads ; lignes d'un groupe de feuille.
class SeasonQuests extends StoreWidget {
  const SeasonQuests({super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final titles = store.game.titles.where(
      (t) => t.id == 'explorer' || t.id == 'guardian',
    );
    return StatsSheetGroup(
      children: [
        for (final t in titles)
          StatsSheetRow(
            icon: t.earned ? Icons.verified_rounded : Icons.explore_outlined,
            iconColor: t.earned ? k.validation : k.texte2,
            title: t.source,
            subtitle: t.earned
                ? 'Titre obtenu : ${t.name}'
                : 'Récompense : titre « ${t.name} »',
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Campagne, boss, saisons
// ---------------------------------------------------------------------------

/// État d'un chapitre ou d'une saison : libellé, icône, couleur.
({String label, IconData icon, Color color}) _stage(
  KTokens k, {
  required bool complete,
  required bool current,
  required String done,
  required String percent,
  required bool started,
}) => (
  label: complete
      ? done
      : current
      ? 'En cours'
      : started
      ? percent
      : 'À venir',
  icon: complete
      ? Icons.verified_rounded
      : current
      ? Icons.play_circle_outline_rounded
      : Icons.lock_outline_rounded,
  color: complete
      ? k.validation
      : current
      ? k.encre
      : k.texte2,
);

/// Bande des chapitres (Aperçu) : une carte par bloc du programme, reliées
/// par un trait. [onTap] : ouvre Parcours.
class CampaignStrip extends StoreWidget {
  final VoidCallback? onTap;
  const CampaignStrip({super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final chapters = store.game.chapters;
    final width =
        KSize.valueWidth *
        1.2 *
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SingleChildScrollView(
      key: const ValueKey('game-campaign'),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < chapters.length; i++) ...[
              if (i > 0)
                SizedBox(
                  width: KSpacing.s16,
                  child: Center(
                    child: Container(
                      height: 2,
                      color: chapters[i - 1].complete ? k.validation : k.filet,
                    ),
                  ),
                ),
              SizedBox(
                width: width,
                child: _ChapterCard(chapters[i], onTap: onTap),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final Chapter c;
  final VoidCallback? onTap;
  const _ChapterCard(this.c, {this.onTap});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final s = _stage(
      k,
      complete: c.complete,
      current: c.current,
      done: 'Bouclé',
      percent: '${(c.fraction * 100).round()}\u00A0%',
      started: c.doneDays > 0,
    );
    return KCard(
      outline: c.current ? k.encre : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.icon, color: s.color, size: KSize.iconSmall),
              const SizedBox(width: KSpacing.s8),
              Expanded(
                child: Text(
                  s.label,
                  style: KType.micro.copyWith(color: s.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          Text(c.name, style: KType.corpsFort.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s4),
          Text(
            'S${c.firstWeek} à S${c.lastWeek}\u00A0· ${c.doneDays}/${c.trainingDays} journées',
            style: KType.detail.copyWith(color: k.texte2),
          ),
          const Spacer(),
          const SizedBox(height: KSpacing.s12),
          StatsBar(
            value: c.fraction,
            label: c.name,
            description: '${c.doneDays} sur ${c.trainingDays}',
            color: c.complete ? k.validation : null,
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            'Titre : ${c.title}',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
}

/// Carte du prochain boss (Aperçu). [onTap] : ouvre Parcours.
class BossCard extends StoreWidget {
  final VoidCallback? onTap;
  const BossCard({super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final g = store.game;
    final boss = g.nextBoss;
    final defeated = g.bosses.where((b) => b.defeated).length;
    if (boss == null) {
      return KCard(
        onTap: onTap,
        child: Row(
          children: [
            KIconTile(Icons.emoji_events_rounded, color: k.validation),
            const SizedBox(width: KSpacing.s14),
            Expanded(
              child: Text(
                'Tous les boss sont vaincus : ${_plural(defeated, 'semaine de tests bouclée', 'semaines de tests bouclées')}.',
                style: KType.corps.copyWith(color: k.texte),
              ),
            ),
          ],
        ),
      );
    }
    final started =
        boss.done > 0 ||
        (g.programWeek >= boss.firstWeek && g.programWeek <= boss.lastWeek);
    return KCard(
      key: const ValueKey('game-boss'),
      onTap: onTap,
      child: Row(
        children: [
          KIconTile(
            Icons.sports_martial_arts_rounded,
            color: started ? k.accent : k.encre,
          ),
          const SizedBox(width: KSpacing.s14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boss\u00A0· ${boss.name}',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                const SizedBox(height: KSpacing.s4),
                Text(
                  bossHint(g, boss),
                  style: KType.detail.copyWith(color: k.texte2),
                ),
                if (defeated > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpacing.s4),
                    child: Text(
                      '$defeated boss vaincu${defeated > 1 ? 's' : ''}',
                      style: KType.micro.copyWith(color: k.validation),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Où en est un boss : tests validés, ou semaines avant ses tests.
String bossHint(GameState g, Boss boss) {
  final weeksAway = boss.firstWeek - g.programWeek;
  final started =
      boss.done > 0 ||
      (g.programWeek >= boss.firstWeek && g.programWeek <= boss.lastWeek);
  return started
      ? '${boss.done}/${boss.tests.length} tests validés\u00A0· un seul test lourd par jour'
      : weeksAway <= 0
      ? 'Tests à rattraper : ${boss.tests.length} journées'
      : weeksAway == 1
      ? 'La semaine prochaine\u00A0· deload conseillé avant'
      : 'Dans $weeksAway semaines (S${boss.firstWeek})';
}

/// Feuille « Boss » (Parcours) : chaque semaine de tests, ses journées et
/// sa récompense, sans feuille empilée.
void showBosses(BuildContext context) {
  final g = store.game;
  final defeated = g.bosses.where((b) => b.defeated).length;
  statsSheet(
    context,
    'Boss',
    subtitle: '$defeated / ${g.bosses.length} vaincus',
    [
      const StatsText(
        'Les semaines de tests du programme sont les boss. Un seul test lourd par jour, en tête de séance. Le deload qui précède fait partie du combat : arrive reposé.',
      ),
      for (final b in g.bosses) _BossDetail(b, next: b == g.nextBoss),
    ],
  );
}

/// Ancien point d'entrée (une feuille par boss) : ouvre la feuille « Boss ».
void showBoss(BuildContext context, Boss boss) => showBosses(context);

class _BossDetail extends StatelessWidget {
  final Boss boss;
  final bool next;
  const _BossDetail(this.boss, {required this.next});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final program = store.program;
    final weeks =
        'S${boss.firstWeek}${boss.lastWeek > boss.firstWeek ? ' à S${boss.lastWeek}' : ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KSectionTitle(
          '${boss.name}\u00A0· $weeks${!next ? '' : boss.done > 0 ? '\u00A0· en cours' : '\u00A0· prochain boss'}',
          top: KSpacing.s4,
        ),
        StatsSheetGroup(
          children: [
            for (final (week, day) in boss.tests)
              StatsSheetRow(
                icon: store.isDone(week, day)
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                iconColor: store.isDone(week, day) ? k.validation : k.texte2,
                title: program.week(week).day(day)?.title ?? 'Test',
                subtitle: 'S$week\u00A0· J$day',
              ),
          ],
        ),
        const SizedBox(height: KSpacing.s8),
        StatsText(
          boss.defeated
              ? 'Boss vaincu : titre « ${boss.title} ».'
              : '${boss.done}\u00A0/\u00A0${boss.tests.length} tests validés. Récompense : titre « ${boss.title} ».',
          muted: true,
        ),
      ],
    );
  }
}

/// Carte de la saison en cours (Aperçu). [onTap] : ouvre Parcours.
class SeasonCard extends StoreWidget {
  final VoidCallback? onTap;
  const SeasonCard({super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final g = store.game;
    final s = g.currentSeason;
    if (s == null) {
      return KCard(
        onTap: onTap,
        child: Text(
          'Hors programme : les saisons reprennent avec le calendrier des 40 semaines.',
          style: KType.corps.copyWith(color: k.texte),
        ),
      );
    }
    final left = s.lastWeek - g.programWeek + 1;
    return KCard(
      key: const ValueKey('game-season'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: k.encre,
                size: KSize.icon,
              ),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Text(
                  'Saison ${s.index}\u00A0· ${s.name}',
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            'S${s.firstWeek} à S${s.lastWeek}\u00A0· ${_plural(left, 'semaine restante', 'semaines restantes')}\u00A0· ${(s.fraction * 100).round()}\u00A0%',
            style: KType.detail.copyWith(color: k.texte2),
          ),
          const SizedBox(height: KSpacing.s12),
          StatsBar(
            value: s.fraction,
            label: 'Saison ${s.index}',
            description: '${s.doneDays} sur ${s.trainingDays}',
            color: s.complete ? k.validation : null,
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            s.complete
                ? 'Saison bouclée : titre « ${s.title} » obtenu'
                : 'À 70\u00A0% des journées : titre « ${s.title} »',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
}

/// Feuille « Saisons » (Parcours) : les quatre saisons et leurs quêtes.
void showSeasons(BuildContext context) {
  final g = store.game;
  statsSheet(
    context,
    'Saisons',
    subtitle: g.currentSeason == null
        ? 'Hors programme'
        : 'Saison ${g.currentSeason!.index} en cours',
    [
      const StatsText(
        'Quatre saisons de dix semaines rythment le programme. Chaque saison bouclée à 70\u00A0% donne son titre ; la campagne, les boss et les badges continuent d’une saison à l’autre, rien n’est remis à zéro.',
      ),
      StatsSheetGroup(
        children: [
          for (final s in g.seasons)
            Builder(
              builder: (context) {
                final st = _stage(
                  KTokens.of(context),
                  complete: s.complete,
                  current: s.current,
                  done: 'Bouclée',
                  percent: '',
                  started: false,
                );
                return StatsSheetRow(
                  icon: st.icon,
                  iconColor: st.color,
                  title: 'Saison ${s.index}\u00A0· ${s.name}',
                  subtitle:
                      'S${s.firstWeek} à S${s.lastWeek}\u00A0· ${s.doneDays}/${s.trainingDays} journées\u00A0· titre « ${s.title} »',
                );
              },
            ),
        ],
      ),
      const KSectionTitle('Quêtes de saison'),
      const SeasonQuests(),
    ],
  );
}

/// Résumé d'une ligne pour la ligne « Campagne » du Parcours.
String campaignSummary(GameState g) {
  final done = g.chapters.where((c) => c.complete).length;
  final current = g.currentChapter;
  final head = current == null ? 'Hors programme' : current.name;
  return '$head\u00A0· $done/${g.chapters.length} chapitres bouclés';
}

/// Feuille « Campagne » (Parcours) : chaque chapitre en détail, sans
/// feuille empilée.
void showCampaign(BuildContext context) {
  final g = store.game;
  final done = g.chapters.where((c) => c.complete).length;
  statsSheet(
    context,
    'Campagne',
    subtitle: '$done / ${g.chapters.length} chapitres bouclés',
    [
      const StatsText(
        'Un chapitre par bloc du programme, bouclé à 75\u00A0% des journées d’entraînement : un titre à la clé. Les semaines de tests sont les boss ; quatre saisons de dix semaines rythment le tout. Rien n’est remis à zéro. Les imprévus ne bloquent pas la campagne.',
      ),
      for (final c in g.chapters) _ChapterDetail(c),
    ],
  );
}

class _ChapterDetail extends StatelessWidget {
  final Chapter c;
  const _ChapterDetail(this.c);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final s = _stage(
      k,
      complete: c.complete,
      current: c.current,
      done: 'Bouclé',
      percent: '${(c.fraction * 100).round()}\u00A0%',
      started: c.doneDays > 0,
    );
    return Material(
      color: k.haute,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.menuRadius,
        side: c.current
            ? BorderSide(color: k.encre, width: KSize.current)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(KSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(s.icon, color: s.color, size: KSize.iconSmall),
                const SizedBox(width: KSpacing.s8),
                Expanded(
                  child: Text(
                    c.name,
                    style: KType.corpsFort.copyWith(color: k.texte),
                  ),
                ),
                const SizedBox(width: KSpacing.s8),
                Text(s.label, style: KType.detail.copyWith(color: k.texte2)),
              ],
            ),
            const SizedBox(height: KSpacing.s4),
            Text(
              'Semaines S${c.firstWeek} à S${c.lastWeek}\u00A0· ${c.doneDays} journées validées sur ${c.trainingDays}',
              style: KType.detail.copyWith(color: k.texte2),
            ),
            const SizedBox(height: KSpacing.s12),
            StatsBar(
              value: c.fraction,
              label: c.name,
              description: '${c.doneDays} sur ${c.trainingDays}',
              color: c.complete ? k.validation : null,
            ),
            const SizedBox(height: KSpacing.s8),
            Text(
              c.complete
                  ? 'Chapitre bouclé : titre « ${c.title} » obtenu.'
                  : 'À 75\u00A0% des journées d’entraînement validées : titre « ${c.title} ».',
              style: KType.detail.copyWith(color: k.texte),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toi contre toi-même
// ---------------------------------------------------------------------------

/// Cette semaine face à la précédente (le titre est celui de la section).
class SelfCompareCard extends StoreWidget {
  const SelfCompareCard({super.key});
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final c = store.game.compare;
    Widget delta(String label, int now, int diff) => Semantics(
      container: true,
      label:
          '$label : $now, ${diff == 0 ? 'comme la semaine passée' : '${diff > 0 ? '+' : ''}$diff par rapport à la semaine passée'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$now', style: KType.chiffre.copyWith(color: k.texte)),
          Text(label, style: KType.detail.copyWith(color: k.texte)),
          Text(
            diff == 0
                ? '= sem. passée'
                : '${diff > 0 ? '+' : ''}$diff vs sem. passée',
            style: KType.micro.copyWith(
              color: diff > 0 ? k.validation : k.texte2,
            ),
          ),
        ],
      ),
    );
    return KCard(
      key: const ValueKey('game-compare'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, bounds) {
              final items = [
                delta('séances', c.current.sessions, c.sessionsDelta),
                delta('séries', c.current.sets, c.setsDelta),
                delta('jours actifs', c.current.activeDays.length, c.daysDelta),
              ];
              final columns = MediaQuery.textScalerOf(context).scale(1) >= 1.5
                  ? 1
                  : 3;
              const gap = KSpacing.s12;
              return Wrap(
                spacing: gap,
                runSpacing: KSpacing.s12,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: (bounds.maxWidth - gap * (columns - 1)) / columns,
                      child: item,
                    ),
                ],
              );
            },
          ),
          if (c.best != null) ...[
            const SizedBox(height: KSpacing.s12),
            Text(
              'Meilleure semaine : ${c.best!.sets} séries, semaine du ${statsDate(c.best!.monday)}.',
              style: KType.detail.copyWith(color: k.texte2),
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

/// Feuille « Tes titres » (Parcours) : choisir le titre affiché ; un choix
/// s'applique et ferme la feuille.
void showTitles(BuildContext context) {
  final titles = store.game.titles;
  final earned = titles.where((t) => t.earned).length;
  void choose(BuildContext context, String title) {
    store.settings.title = title;
    store.saveSettings();
    store.notifyListeners();
    Navigator.pop(context);
  }

  statsSheet(
    context,
    'Tes titres',
    subtitle:
        '$earned titre${earned > 1 ? 's' : ''} obtenu${earned > 1 ? 's' : ''} sur ${titles.length}',
    [
      const StatsText(
        'Le titre choisi s’affiche sur ta feuille de personnage à la place du rang.',
      ),
      Builder(
        builder: (context) {
          final k = KTokens.of(context);
          final shown = store.settings.title;
          return StatsSheetGroup(
            children: [
              StatsSheetRow(
                icon: shown.isEmpty
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                iconColor: shown.isEmpty ? k.validation : k.texte2,
                title: 'Afficher mon rang',
                onTap: () => choose(context, ''),
              ),
              for (final t in titles)
                StatsSheetRow(
                  enabled: t.earned,
                  icon: !t.earned
                      ? Icons.lock_outline_rounded
                      : shown == t.name
                      ? Icons.check_circle_rounded
                      : Icons.workspace_premium_rounded,
                  iconColor: shown == t.name ? k.validation : k.texte2,
                  title: t.name,
                  subtitle: t.source,
                  onTap: t.earned ? () => choose(context, t.name) : null,
                ),
            ],
          );
        },
      ),
    ],
  );
}
