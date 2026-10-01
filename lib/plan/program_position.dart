// G7 (D4.8, D4.9) : « Où j'en suis » et fin de bloc.
//
// « Où j'en suis » : l'utilisateur choisit sa semaine et sa séance ; la
// séance choisie devient celle d'aujourd'hui et les séances d'avant sans
// journal sont marquées « reprise » (neutres : ni XP, ni statistiques, ni
// série, ni records, ni données pour les moteurs). Fonctionne pour tout
// programme, celui du propriétaire compris.
//
// Fin de bloc (écran minimal, enrichi en G10) : le moteur propose le bloc
// suivant ; Koach montre ce qui change ; l'utilisateur le valide.
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart' show KoachSurface;
import '../models.dart' show WeekPlan;
import '../store.dart';
import '../ui.dart';
import 'plan_sheets.dart';
import 'plan_texts.dart';

class ProgramPositionScreen extends StatefulWidget {
  const ProgramPositionScreen({super.key});

  @override
  State<ProgramPositionScreen> createState() => _ProgramPositionScreenState();
}

class _ProgramPositionScreenState extends State<ProgramPositionScreen> {
  late int _week;
  int? _day;

  @override
  void initState() {
    super.initState();
    final pos = PlanStore(store).programPosition;
    _week = (pos?.week ?? 1).clamp(1, store.program.weeks.length);
    final w = store.program.week(_week);
    final today = pos?.day;
    _day = today != null && (w.day(today)?.exercises.isNotEmpty ?? false)
        ? today
        : _firstTraining(w);
  }

  int? _firstTraining(WeekPlan w) {
    for (final d in w.days) {
      if (d.exercises.isNotEmpty) return d.j;
    }
    return null;
  }

  void _setWeek(int w) {
    final n = w.clamp(1, store.program.weeks.length);
    setState(() {
      _week = n;
      _day = _firstTraining(store.program.week(n));
    });
  }

  int get _resumeCount {
    final day = _day;
    if (day == null) return 0;
    final at = (_week - 1) * 7 + day - 1;
    var n = 0;
    for (final w in store.program.weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        if ((w.n - 1) * 7 + d.j - 1 >= at) continue;
        final l = store.logs[store.sessionKey(w.n, d.j)];
        final logged =
            l != null &&
            (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done)));
        if (!logged) n++;
      }
    }
    return n;
  }

  Future<void> _confirm() async {
    final day = _day;
    if (day == null) return;
    final nav = Navigator.of(context);
    final colors = KoachToastColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    PlanStore(store).setProgramPosition(_week, day);
    messenger.showSnackBar(
      koachSnackBar(
        colors,
        'C’est noté : aujourd’hui, semaine $_week, séance J$day.',
        pose: KoachPose.thumbsUp,
      ),
    );
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final w = store.program.week(_week);
    final count = _resumeCount;
    final dim = Theme.of(context).textTheme.bodySmall;
    return KScreen(
      appBar: AppBar(title: const Text('OÙ J’EN SUIS')),
      body: KList(
        key: const ValueKey('position-list'),
        children: [
          KoachSurface(
            color: SL.bg,
            child: const KoachBubble(
              key: ValueKey('position-koach'),
              pose: KoachPose.direction,
              koachHeight: 110,
              text:
                  'Dis-moi où tu en es dans ton programme : la séance '
                  'choisie devient celle d’aujourd’hui.',
              why:
                  'Utile après un changement de téléphone ou une sauvegarde '
                  'restaurée. Les séances d’avant que tu n’as pas saisies '
                  'sont marquées « reprise » : elles ne comptent ni en XP, ni '
                  'dans tes statistiques, ni dans ta série, ni pour tes '
                  'records. Ton niveau ne bouge pas. Ce que tu as déjà saisi '
                  'reste tel quel.',
            ),
          ),
          KCard(
            child: Row(
              children: [
                IconButton.outlined(
                  key: const ValueKey('position-week-minus'),
                  tooltip: 'Semaine précédente',
                  onPressed: _week > 1 ? () => _setWeek(_week - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Semaine $_week',
                        key: const ValueKey('position-week'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(w.block, style: dim, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                IconButton.outlined(
                  key: const ValueKey('position-week-plus'),
                  tooltip: 'Semaine suivante',
                  onPressed: _week < store.program.weeks.length
                      ? () => _setWeek(_week + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const KSection('Ta séance d’aujourd’hui'),
          for (final d in w.days)
            if (d.exercises.isNotEmpty)
              KCard(
                key: ValueKey('position-day-${d.j}'),
                outline: _day == d.j ? SL.accent : null,
                onTap: () => setState(() => _day = d.j),
                child: Row(
                  children: [
                    Icon(
                      _day == d.j
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _day == d.j ? SL.accent : SL.dim,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('J${d.j} · ${d.title}'),
                          Text(
                            '${d.exercises.length} exercices'
                            '${store.isDone(_week, d.j) ? ' · déjà faite' : ''}',
                            style: dim,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (_day != null)
            Text(
              count == 0
                  ? 'Aucune séance ne sera marquée « reprise ».'
                  : '$count séance${count > 1 ? 's' : ''} d’avant '
                        '${count > 1 ? 'seront marquées' : 'sera marquée'} '
                        '« reprise » (neutre).',
              key: const ValueKey('position-count'),
            ),
          FilledButton(
            key: const ValueKey('position-confirm'),
            onPressed: _day == null ? null : _confirm,
            child: const Text('C’est là que j’en suis'),
          ),
        ],
      ),
    );
  }
}

/// Fin de bloc : bloc suivant proposé par le moteur.
class NextBlockScreen extends StatefulWidget {
  const NextBlockScreen({super.key});

  @override
  State<NextBlockScreen> createState() => _NextBlockScreenState();
}

class _NextBlockScreenState extends State<NextBlockScreen> {
  late final _proposal = PlanStore(store).proposeNextBlock();

  @override
  Widget build(BuildContext context) {
    final p = _proposal;
    if (p == null) {
      return KScreen(
        appBar: AppBar(title: const Text('BLOC SUIVANT')),
        body: KList(
          children: [
            KoachSurface(
              color: SL.bg,
              child: const KoachBubble(
                pose: KoachPose.oops,
                koachHeight: 100,
                text:
                    'Je n’arrive pas à préparer le bloc suivant pour '
                    'l’instant.',
              ),
            ),
          ],
        ),
      );
    }
    final block = p.proposal.block;
    final before = store.planProgram!.blocks.last.block.pass1;
    final changes = p.proposal.diff.changes;
    return KScreen(
      appBar: AppBar(title: const Text('BLOC SUIVANT')),
      body: KList(
        key: const ValueKey('next-block-list'),
        children: [
          KoachSurface(
            color: SL.bg,
            child: KoachBubble(
              key: const ValueKey('next-block-koach'),
              pose: KoachPose.progressChart,
              koachHeight: 110,
              text:
                  'Ton bloc se termine. Je te propose le suivant : '
                  '${block.pass1.weeks} semaines, '
                  '${changes.isEmpty ? 'mêmes exercices' : '${changes.length} changement${changes.length > 1 ? 's' : ''}'}.',
              why:
                  'Je garde tes mouvements principaux, je fais tourner une '
                  'partie des exercices de complément et je fais progresser '
                  'ce que tu maîtrises.',
            ),
          ),
          for (final c in changes)
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(changeLine(c, before, block.pass1)),
                  for (final r in c.reasons)
                    Text(
                      planReason(r),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final w in block.pass2.weeks)
                Chip(
                  label: Text('S${w.weekIndex + 1} ${kWeekKindLabels[w.kind]}'),
                ),
            ],
          ),
          FilledButton(
            key: const ValueKey('next-block-validate'),
            onPressed: () {
              PlanStore(store).applyNextBlock(p.proposal, p.request.seed);
              Navigator.of(context).pop(true);
            },
            child: const Text('Valider le bloc suivant'),
          ),
        ],
      ),
    );
  }
}

/// Raccourci : jour civil lisible « lundi 05/10 ».
String civilShort(kc.CivilDate d) =>
    '${weekdayLabel(d.weekday).toLowerCase()} '
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
