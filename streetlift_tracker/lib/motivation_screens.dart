// L12 (KT-065 à KT-071) — écrans de la motivation et de la progression
// visible : « MES PROGRÈS » (détail selon le niveau), « MES FIGURES »
// (chaînes de progression), « ÉTAPES FRANCHIES », carte de l'accueil
// (célébration sobre, bilan hebdomadaire, bilan de fin de cycle, parcours
// d'habitude), « MOTIVATION ET PROGRESSION » (ton de Koach, statistiques,
// poids, parcours), image de partage générée sur l'appareil et séance
// « 10 minutes, ça compte ». Contrat : docs/CONTRAT_L12.md.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'motivation.dart';
import 'program_generator.dart' show GenCatalog;
import 'rewards.dart' show checkLevelUp;
import 'session_screen.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';

String _date(int day) {
  final d = DateTime.fromMillisecondsSinceEpoch(day * 86400000, isUtc: true);
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

const _toneLabels = {
  'kind': 'Bienveillant',
  'demanding': 'Exigeant',
  'neutral': 'Neutre',
};

String _plural(int n, String one, String many) => n > 1 ? many : one;

// ============================================ séance de 10 minutes (KT-071)

/// Ouvre la séance « 10 minutes, ça compte » (créée au besoin dans les
/// séances perso ; une séance déjà terminée repart de zéro, l'ancienne
/// reste dans l'historique).
Future<void> openMinimalSession(BuildContext context) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  GenCatalog catalog;
  try {
    catalog = await store.adaptCatalog();
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Base d’exercices illisible.')),
    );
    return;
  }
  final session = store.ensureMinimalSession(catalog);
  if (session.items.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Aucun exercice sans matériel trouvé.')),
    );
    return;
  }
  final id = int.tryParse(session.id);
  if (id != null && store.isDone(0, id)) store.restartCustomSession(session);
  final wp = session.toWeekPlan();
  final root = nav.context;
  await nav.push(
    MaterialPageRoute<void>(
      builder: (_) => SessionScreen(week: wp, day: wp.days.first),
    ),
  );
  if (root.mounted) checkLevelUp(root);
}

// ================================================== carte de l'accueil

/// Carte de l'accueil : célébration des étapes réelles (vue une fois),
/// parcours d'habitude, bilan hebdomadaire et bilan de fin de cycle.
/// Affichée seulement quand elle a quelque chose à dire.
class MotivHomeCard extends StatelessWidget {
  const MotivHomeCard({super.key});

  static bool get visible =>
      store.motivPending.isNotEmpty ||
      store.motivHabitActive ||
      store.motivWeekReview != null ||
      store.motivCycleReview != null;

  @override
  Widget build(BuildContext context) {
    final pending = store.motivPending;
    final review = store.motivWeekReview;
    final cycle = store.motivCycleReview;
    return Column(
      key: const ValueKey('motiv-home-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isNotEmpty) _Celebration(pending: pending),
        if (store.motivHabitActive) const _HabitCard(),
        if (cycle != null) _CycleCard(review: cycle),
        if (review != null) _WeekReviewCard(review: review),
      ],
    );
  }
}

/// Célébration sobre : une seule apparition en fondu (immédiate si les
/// animations sont réduites), sans boucle ni son.
class _Celebration extends StatelessWidget {
  final List<Milestone> pending;
  const _Celebration({required this.pending});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final shown = pending.reversed.take(3).toList();
    final kind = shown.first.kind;
    final context0 = switch (kind) {
      'record' => 'record',
      'chain' => 'chain_step',
      'cycle' => 'cycle_done',
      _ => 'regular_week',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder:
            (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: .96 + .04 * t, child: child),
            ),
        child: KCard(
          key: const ValueKey('motiv-celebration'),
          accent: SL.accent,
          child: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: SL.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pending.length > 1
                            ? 'NOUVELLES ÉTAPES'
                            : 'NOUVELLE ÉTAPE',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final m in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(m.title),
                  ),
                if (pending.length > shown.length)
                  Text(
                    'et ${pending.length - shown.length} autre${pending.length - shown.length > 1 ? 's' : ''} dans Étapes franchies',
                    style: TextStyle(color: SL.dim),
                  ),
                const SizedBox(height: 6),
                Text(
                  store.motivLine(context0),
                  style: TextStyle(color: SL.dim),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      key: const ValueKey('motiv-celebration-ok'),
                      onPressed: () => store.acknowledgeMilestones(pending),
                      child: const Text('Continuer'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        store.acknowledgeMilestones(pending);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const MilestonesScreen(),
                          ),
                        );
                      },
                      child: const Text('Mes étapes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard();

  @override
  Widget build(BuildContext context) {
    final minutes = store.motivHabitMinutes;
    final w = store.motivThisWeek;
    final target = regularTarget(w.planned, habit: true);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KCard(
        key: const ValueKey('motiv-habit-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PARCOURS D’HABITUDE · SEMAINE ${store.motivHabitWeek} / 4',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              target == 0
                  ? 'Pas de séance prévue cette semaine : une séance de 10 minutes compte aussi.'
                  : '$target séance${target > 1 ? 's' : ''} de $minutes minutes cette semaine suffisent'
                      '${w.planned > target ? ' ; les autres sont en bonus' : ''}.'
                      ' Fait : ${w.done} / $target.',
            ),
            const SizedBox(height: 4),
            Text(store.motivLine('habit'), style: TextStyle(color: SL.dim)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey('motiv-minimal'),
                onPressed: () => openMinimalSession(context),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('10 minutes, ça compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekReviewCard extends StatelessWidget {
  final WeekReview review;
  const _WeekReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final w = store.motivWeek(review.monday);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KCard(
        key: const ValueKey('motiv-week-review'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'BILAN DE LA SEMAINE',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Du ${_date(review.monday)} au ${_date(review.monday + 6)}',
              style: TextStyle(color: SL.dim),
            ),
            const SizedBox(height: 6),
            for (final (i, item) in review.items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      [
                        Icons.emoji_events_outlined,
                        Icons.event_available_outlined,
                        Icons.flag_outlined,
                      ][review.victory == null ? i + 1 : i],
                      size: 18,
                      color: SL.dim,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            Text(
              store.motivLine(w.regular ? 'week_good' : 'week_low'),
              style: TextStyle(color: SL.dim),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('motiv-week-review-ok'),
                onPressed: () => store.dismissWeekReview(review.monday),
                child: const Text('Vu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleCard extends StatelessWidget {
  final CycleReview review;
  const _CycleCard({required this.review});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: KCard(
      key: const ValueKey('motiv-cycle-card'),
      accent: SL.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BILAN DE FIN DE CYCLE',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(review.cycle.label, style: TextStyle(color: SL.dim)),
          const SizedBox(height: 4),
          Text(store.motivLine('cycle_done')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('motiv-cycle-open'),
                onPressed: () => showCycleReview(context, review),
                child: const Text('Voir le bilan'),
              ),
              OutlinedButton(
                onPressed: () => store.dismissCycleReview(review.cycle),
                child: const Text('Plus tard'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Bilan de fin de cycle (feuille).
Future<void> showCycleReview(
  BuildContext context,
  CycleReview review,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder:
      (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .94,
        builder:
            (context, controller) => KList(
              key: const ValueKey('motiv-cycle-sheet'),
              controller: controller,
              children: [
                Text(
                  'BILAN DE FIN DE CYCLE',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(review.cycle.label, style: TextStyle(color: SL.dim)),
                for (final (title, text) in review.lines)
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(text),
                      ],
                    ),
                  ),
                Text(
                  'Des repères d’entraînement, pas une promesse de résultat.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                FilledButton(
                  key: const ValueKey('motiv-cycle-done'),
                  onPressed: () {
                    store.dismissCycleReview(review.cycle);
                    Navigator.pop(sheet);
                  },
                  child: const Text('Compris'),
                ),
              ],
            ),
      ),
);

// ============================================ « MES PROGRÈS » (KT-065)

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('MES PROGRÈS')),
    body: StoreBuilder(builder: (_) => const ProgressBody()),
  );
}

/// Contenu de « MES PROGRÈS » : victoires (débutant et novice, au plus 3
/// chiffres), records et courbes simples (intermédiaire), statistiques
/// complètes de Koach (avancé, expert, ou sur demande).
class ProgressBody extends StatelessWidget {
  const ProgressBody({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = store.motivDetail;
    final simple = detail == DetailLevel.victories;
    // Le bouton « 10 minutes, ça compte » porte un chiffre : les victoires
    // se partagent les autres (au plus 3 par écran).
    final victories =
        simple
            ? pickVictories(
              store.motivVictories(),
              maxFigures: kMaxVictoryFigures - 1,
            )
            : store.motivTopVictories;
    return KList(
      key: const ValueKey('motiv-progress'),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            store.motivLine('progress'),
            style: TextStyle(color: SL.dim),
          ),
        ),
        const KSection('Victoires'),
        for (final v in victories)
          KCard(
            key: ValueKey('motiv-victory-${v.id}'),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: SL.accent),
                const SizedBox(width: 12),
                Expanded(child: Text(v.text)),
              ],
            ),
          ),
        if (!simple) ..._records(context),
        if (!simple) ..._curves(context, detail == DetailLevel.full),
        if (!simple) ..._regularity(context),
        if (detail == DetailLevel.full) ..._koach(context),
        if (!simple) ..._body(context),
        const KSection('Aller plus loin'),
        KMenuTile(
          key: const ValueKey('motiv-open-chains'),
          icon: Icons.account_tree_outlined,
          title: 'Mes figures',
          subtitle: 'Étapes atteintes, en cours et suivantes',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const ChainsScreen()),
              ),
        ),
        KMenuTile(
          key: const ValueKey('motiv-open-milestones'),
          icon: Icons.emoji_events_outlined,
          title: 'Étapes franchies',
          subtitle: 'Records, étapes, cycles et régularité',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MilestonesScreen(),
                ),
              ),
        ),
        KMenuTile(
          key: const ValueKey('motiv-open-share'),
          icon: Icons.ios_share_rounded,
          title: 'Partager ma progression',
          subtitle: 'Image créée sur le téléphone, contenu au choix',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ShareProgressScreen(),
                ),
              ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('motiv-minimal-progress'),
          onPressed: () => openMinimalSession(context),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('10 minutes, ça compte'),
        ),
        SwitchListTile.adaptive(
          key: const ValueKey('motiv-show-all'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Afficher toutes les statistiques'),
          value: store.motiv.showAll,
          onChanged: store.setShowAllStats,
        ),
      ],
    );
  }

  List<Widget> _records(BuildContext context) {
    final records = store.motivRecords().reversed.take(5).toList();
    return [
      const KSection('Records récents'),
      if (records.isEmpty)
        const Text('Tes records apparaîtront ici dès qu’une série fera mieux.'),
      for (final r in records)
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(r.exercise, style: Theme.of(context).textTheme.titleSmall),
              Text('${r.label} · le ${_date(r.milestone.day)}'),
            ],
          ),
        ),
    ];
  }

  List<Widget> _curves(BuildContext context, bool full) {
    final est = store.adaptWeeklyEstimates();
    final keys = est.keys.where((k) => est[k]!.length >= 2).toList()..sort();
    return [
      if (keys.isNotEmpty) const KSection('Courbes', subtitle: 'Repères'),
      for (final k in keys.take(full ? 8 : 4))
        _CurveCard(name: store.motivMovementName(k), weekly: est[k]!),
    ];
  }

  List<Widget> _regularity(BuildContext context) {
    final w = store.motivThisWeek;
    final streak = store.motivRegularStreak;
    return [
      const KSection('Assiduité'),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$streak ${_plural(streak, 'semaine régulière', 'semaines régulières')} d’affilée',
            ),
            Text(
              w.counted
                  ? 'Cette semaine : ${w.plannedDone} sur ${w.planned} ${_plural(w.planned, 'séance prévue', 'séances prévues')}, '
                      '${w.restRespected} ${_plural(w.restRespected, 'jour de repos respecté', 'jours de repos respectés')}.'
                  : 'Cette semaine : pas de séance prévue.',
            ),
            Text(
              'Les jours de repos respectés comptent pour la régularité.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _koach(BuildContext context) {
    final out = <Widget>[];
    if (store.koachOn) {
      out.add(const KSection('Statistiques de Koach'));
      final objs = store.koachObjectives();
      for (final l in store.program.pilotage.mainLifts) {
        final o = objs[l.ref] as Map?;
        final slope = (o?['slope'] as num?)?.toDouble();
        out.add(
          KCard(
            key: ValueKey('motiv-koach-${l.key}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.name, style: Theme.of(context).textTheme.titleSmall),
                Text(store.koachEstimateText(l.key)),
                if (slope != null)
                  Text(
                    'Rythme observé : ${slope >= 0 ? '+' : '−'}${koachKg(double.parse(slope.abs().toStringAsFixed(2)))} kg par semaine (repère).',
                  ),
              ],
            ),
          ),
        );
      }
    }
    final p = store.progression;
    out
      ..add(const KSection('Depuis tes débuts'))
      ..add(
        KCard(
          child: Text(
            '${p.sessions} ${_plural(p.sessions, 'séance terminée', 'séances terminées')} · '
            '${p.sets} ${_plural(p.sets, 'série validée', 'séries validées')} · '
            '${store.motivMilestones.length} ${_plural(store.motivMilestones.length, 'étape franchie', 'étapes franchies')}',
          ),
        ),
      );
    return out;
  }

  List<Widget> _body(BuildContext context) {
    final bw = store.motivBodyweight;
    if (bw == null) return const [];
    final hidden = store.motiv.hideBody;
    return [
      const KSection('Poids (facultatif)'),
      KCard(
        key: const ValueKey('motiv-body'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hidden
                    ? 'Poids masqué.'
                    : 'Poids de corps enregistré : ${koachKg(bw)} kg.',
              ),
            ),
            TextButton(
              key: const ValueKey('motiv-body-toggle'),
              onPressed: () => store.setHideBody(!hidden),
              child: Text(hidden ? 'Afficher' : 'Masquer'),
            ),
          ],
        ),
      ),
    ];
  }
}

/// Courbe simple d'un mouvement (estimation hebdomadaire, repère). Le texte
/// donne les mêmes informations (lecteur d'écran, jamais la couleur seule).
class _CurveCard extends StatelessWidget {
  final String name;
  final Map<int, double> weekly;
  const _CurveCard({required this.name, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final weeks = weekly.keys.toList()..sort();
    final first = weekly[weeks.first]!, last = weekly[weeks.last]!;
    final text =
        'de ${koachKg(double.parse(first.toStringAsFixed(1)))} à '
        '${koachKg(double.parse(last.toStringAsFixed(1)))} '
        '(semaines ${weeks.first} à ${weeks.last})';
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Semantics(
            label: 'Courbe de $name : $text',
            excludeSemantics: true,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: CustomPaint(
                painter: _Spark(
                  [for (final w in weeks) weekly[w]!],
                  SL.redAccent,
                  SL.dim.withValues(alpha: .35),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimation $text.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Spark extends CustomPainter {
  final List<double> values;
  final Color line, grid;
  _Spark(this.values, this.line, this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.reduce((a, b) => a < b ? a : b);
    var hi = values.reduce((a, b) => a > b ? a : b);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()..color = grid,
    );
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height - 4 - (size.height - 8) * (values[i] - lo) / (hi - lo);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = line);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _Spark old) =>
      old.values != values || old.line != line;
}

// ============================================== « MES FIGURES » (KT-066)

class ChainsScreen extends StatelessWidget {
  const ChainsScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('MES FIGURES')),
    body: FutureBuilder<ChainBook>(
      future: ChainBook.load(),
      initialData: ChainBook.loaded,
      builder: (context, snap) {
        if (snap.data == null) {
          return snap.hasError
              ? const Center(child: Text('Chaînes de progression illisibles.'))
              : const Center(child: CircularProgressIndicator());
        }
        return StoreBuilder(builder: (_) => const _ChainsBody());
      },
    ),
  );
}

class _ChainsBody extends StatelessWidget {
  const _ChainsBody();

  @override
  Widget build(BuildContext context) {
    final all = store.motivChains();
    final goal = store.motivGoalChains;
    final featured = [
      for (final id in goal)
        for (final c in all)
          if (c.chain.id == id) c,
    ];
    final others = [
      for (final c in all)
        if (!goal.contains(c.chain.id)) c,
    ];
    return KList(
      key: const ValueKey('motiv-chains'),
      children: [
        const KSection(
          'Pour ton objectif',
          subtitle: 'Les chaînes utiles à ton objectif',
        ),
        for (final c in featured) _ChainTile(progress: c),
        ExpansionTile(
          key: const ValueKey('motiv-chains-others'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Autres chaînes'),
          children: [for (final c in others) _ChainTile(progress: c)],
        ),
      ],
    );
  }
}

class _ChainTile extends StatelessWidget {
  final ChainProgress progress;
  const _ChainTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    final step = progress.currentStep;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KCard(
        key: ValueKey('motiv-chain-${progress.chain.id}'),
        padding: EdgeInsets.zero,
        child: ListTile(
          title: Text(progress.chain.title),
          subtitle: Text(
            progress.complete
                ? 'Chaîne terminée'
                : 'En cours : ${store.motivStepName(step!.id)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ChainDetailScreen(chainId: progress.chain.id),
                ),
              ),
        ),
      ),
    );
  }
}

class ChainDetailScreen extends StatelessWidget {
  final String chainId;
  const ChainDetailScreen({super.key, required this.chainId});

  @override
  Widget build(BuildContext context) => StoreBuilder(
    builder: (_) {
      final p =
          store.motivChains().where((c) => c.chain.id == chainId).firstOrNull;
      return KScreen(
        appBar: AppBar(title: Text(p?.chain.title ?? 'CHAÎNE')),
        body:
            p == null
                ? const Center(child: Text('Chaîne indisponible.'))
                : KList(
                  key: const ValueKey('motiv-chain-detail'),
                  children: [
                    for (var i = 0; i < p.chain.steps.length; i++)
                      _StepRow(progress: p, index: i),
                  ],
                ),
      );
    },
  );
}

class _StepRow extends StatelessWidget {
  final ChainProgress progress;
  final int index;
  const _StepRow({required this.progress, required this.index});

  @override
  Widget build(BuildContext context) {
    final step = progress.chain.steps[index];
    final state = progress.stateOf(index);
    final (icon, label) = switch (state) {
      StepState.reached => (Icons.check_circle_outline, 'atteinte'),
      StepState.current => (Icons.radio_button_checked, 'en cours'),
      StepState.next => (Icons.arrow_circle_right_outlined, 'suivante'),
      StepState.locked => (Icons.lock_outline, 'à venir'),
    };
    final t = step.threshold;
    final day = progress.reached[index];
    return KCard(
      key: ValueKey('motiv-step-${step.id}'),
      accent: state == StepState.current ? SL.accent : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: state == StepState.reached ? SL.success : SL.dim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  store.motivStepName(step.id),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  state == StepState.reached && day != null
                      ? 'Étape $label le ${_date(day)}'
                      : 'Étape $label',
                ),
                if (state == StepState.current && t != null)
                  Text('Pour passer : ${t.text}'),
                if (state == StepState.next && t != null)
                  Text(
                    'Critère ensuite : ${t.text}',
                    style: TextStyle(color: SL.dim),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================= « ÉTAPES FRANCHIES » (KT-067)

class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('ÉTAPES FRANCHIES')),
    body: StoreBuilder(
      builder: (_) {
        final all = store.motivMilestones;
        return KList(
          key: const ValueKey('motiv-milestones'),
          children: [
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Tes records, étapes de figures, cycles terminés et semaines '
                  'régulières apparaîtront ici.',
                ),
              ),
            for (final m in all)
              KCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(switch (m.kind) {
                    'record' => Icons.trending_up_rounded,
                    'chain' => Icons.account_tree_outlined,
                    'cycle' => Icons.flag_outlined,
                    _ => Icons.event_available_outlined,
                  }),
                  title: Text(m.title),
                  subtitle: Text('le ${_date(m.day)}'),
                ),
              ),
          ],
        );
      },
    ),
  );
}

// ================================= « MOTIVATION ET PROGRESSION » (réglages)

class MotivSettingsScreen extends StatelessWidget {
  const MotivSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('MOTIVATION ET PROGRESSION')),
    body: StoreBuilder(
      builder: (_) {
        final tone = store.koachTone;
        return KList(
          key: const ValueKey('motiv-settings'),
          children: [
            KMenuTile(
              key: const ValueKey('motiv-settings-progress'),
              icon: Icons.insights_rounded,
              title: 'Mes progrès',
              subtitle: 'Victoires, figures, étapes et partage',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProgressScreen(),
                    ),
                  ),
            ),
            const KSection(
              'Ton de Koach',
              subtitle: 'Les messages de sécurité restent toujours neutres',
            ),
            for (final t in kToneIds)
              KCard(
                padding: EdgeInsets.zero,
                child: RadioListTile<String>(
                  key: ValueKey('motiv-tone-$t'),
                  value: t,
                  groupValue: tone,
                  onChanged: (v) {
                    if (v != null) store.setKoachTone(v);
                  },
                  title: Text(_toneLabels[t]!),
                  subtitle: Text(
                    '« ${koachLine('session_done', t, store.motivLevel)} »',
                  ),
                ),
              ),
            const KSection('Affichage'),
            SwitchListTile.adaptive(
              key: const ValueKey('motiv-settings-show-all'),
              title: const Text('Afficher toutes les statistiques'),
              subtitle: const Text(
                'Sinon, le détail suit ton niveau : victoires, records, '
                'statistiques complètes.',
              ),
              value: store.motiv.showAll,
              onChanged: store.setShowAllStats,
            ),
            SwitchListTile.adaptive(
              key: const ValueKey('motiv-settings-hide-body'),
              title: const Text('Masquer le poids'),
              subtitle: const Text(
                'Poids et mensurations sont facultatifs ; jamais partagés '
                'sans ton choix.',
              ),
              value: store.motiv.hideBody,
              onChanged: store.setHideBody,
            ),
            if (store.motivHabitEligible)
              SwitchListTile.adaptive(
                key: const ValueKey('motiv-settings-habit'),
                title: const Text('Parcours d’habitude'),
                subtitle: Text(
                  'Les 4 premières semaines : 2 séances de '
                  '${store.motivHabitMinutes} minutes suffisent.',
                ),
                value: !store.motiv.habitOff,
                onChanged: (v) => store.setHabitOff(!v),
              ),
            const KSection('Rappels'),
            const Text(
              'Réglages → Rappels de séance : à l’heure choisie, uniquement les '
              'jours d’entraînement prévus, jamais un jour de repos ni pendant '
              'une pause.',
            ),
          ],
        );
      },
    ),
  );
}

// ================================================ partage (KT-071)

/// Partage par le menu Android (fichier temporaire de l'application, aucun
/// serveur).
class ShareChannel {
  static const _channel = MethodChannel('kalis_track/share');

  /// Hook de test : remplace l'appel natif.
  static Future<String> Function(Uint8List png, String text)? debugHook;

  static Future<String> shareImage(Uint8List png, String text) async {
    final hook = debugHook;
    if (hook != null) return hook(png, text);
    try {
      final r = await _channel.invokeMethod<String>('shareImage', {
        'bytes': png,
        'text': text,
      });
      return r ?? 'error';
    } on MissingPluginException {
      return 'unsupported';
    } on PlatformException {
      return 'error';
    }
  }
}

class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({super.key});

  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  final _options = ShareOptions();
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final obj = _boundary.currentContext?.findRenderObject();
      if (obj is! RenderRepaintBoundary) return;
      final image = await obj.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final lines = shareLines(store.motivShareData, _options);
      final result = await ShareChannel.shareImage(
        data.buffer.asUint8List(),
        'Ma progression Kalis Track\n${lines.join('\n')}',
      );
      if (!mounted) return;
      if (result != 'shared') {
        _snack(context, 'Partage indisponible sur cet appareil.');
      }
    } catch (_) {
      if (mounted) _snack(context, 'Image impossible à créer.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = store.motivShareData;
    final lines = shareLines(data, _options);
    Widget option(
      String key,
      String title,
      bool value,
      void Function(bool) set, {
      bool enabled = true,
    }) => CheckboxListTile(
      key: ValueKey('motiv-share-$key'),
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: enabled ? (v) => setState(() => set(v ?? false)) : null,
    );
    return KScreen(
      appBar: AppBar(title: const Text('PARTAGER')),
      body: KList(
        key: const ValueKey('motiv-share'),
        children: [
          RepaintBoundary(key: _boundary, child: _ShareCard(lines: lines)),
          const KSection(
            'Contenu',
            subtitle:
                'Aucune donnée de santé ; le poids seulement si tu le coches',
          ),
          option(
            'victories',
            'Victoires',
            _options.victories,
            (v) => _options.victories = v,
          ),
          option(
            'records',
            'Records',
            _options.records,
            (v) => _options.records = v,
          ),
          option(
            'regularity',
            'Régularité',
            _options.regularity,
            (v) => _options.regularity = v,
          ),
          option(
            'chain',
            'Dernière étape de figure',
            _options.chain,
            (v) => _options.chain = v,
          ),
          option(
            'bodyweight',
            'Poids de corps',
            _options.bodyweight,
            (v) => _options.bodyweight = v,
            enabled: data.bodyweight != null,
          ),
          FilledButton.icon(
            key: const ValueKey('motiv-share-send'),
            onPressed: _busy || lines.isEmpty ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Partager'),
          ),
          Text(
            'L’image est créée sur ton téléphone et partagée par le menu '
            'Android. Rien n’est envoyé à un serveur.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Image de partage : couleurs fixes de la marque (fond sombre, bordeaux),
/// typographie existante.
class _ShareCard extends StatelessWidget {
  final List<String> lines;
  const _ShareCard({required this.lines});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('motiv-share-card'),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF6B0C0C), width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'MA PROGRESSION',
          style: TextStyle(
            color: Color(0xFFF4F4F4),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 10),
        if (lines.isEmpty)
          const Text(
            'Coche au moins un élément.',
            style: TextStyle(color: Color(0xFF8A8A8A)),
          ),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFFA61717),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l,
                    style: const TextStyle(color: Color(0xFFF4F4F4)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'KALIS TRACK',
          style: TextStyle(
            color: Color(0xFFA61717),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}
