// CI1 (dev6.9.0, pipeline CP) : jour de compétition. Pour une compétition
// de force, `kalis_adapt` propose pour chaque mouvement l'échauffement et
// les tentatives (avec leur chance de réussite), recalculées après chaque
// tentative notée ici ; pour une épreuve de répétitions, l'objectif et le
// rythme. Les tentatives notées restent sur cet écran (la séance du jour se
// journalise comme d'habitude) ; aucune règle ici, seulement l'affichage.
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../adapt/adapt_texts.dart' show adaptKg, adaptReasonText;
import '../app_theme.dart';
import '../koach/koach_bubble.dart' show KoachSays;
import '../store.dart';
import '../ui.dart';

const _objectives = <kc.EventObjective, String>{
  kc.EventObjective.secureTotal: 'Assurer un total',
  kc.EventObjective.maxTotal: 'Viser le plus gros total',
  kc.EventObjective.record: 'Tenter un record',
};

class EventDayScreen extends StatefulWidget {
  final kc.SeasonEvent event;
  const EventDayScreen({super.key, required this.event});

  @override
  State<EventDayScreen> createState() => _EventDayScreenState();
}

class _EventDayScreenState extends State<EventDayScreen> {
  final List<kc.AttemptResult> _done = [];
  kc.EventObjective _objective = kc.EventObjective.maxTotal;

  String _name(String id) => store.adaptExerciseName(id);

  void _mark(String exerciseId, int index, double kg, bool ok) {
    setState(() {
      _done.removeWhere((a) => a.exerciseId == exerciseId && a.index >= index);
      _done.add(
        kc.AttemptResult(
          exerciseId: exerciseId,
          index: index,
          loadKg: kg,
          success: ok,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final strength = widget.event.kind == kc.EventKind.strengthCompetition;
    final plan = store.evolutionEventDay(
      widget.event.id,
      done: List.unmodifiable(_done),
      objective: strength ? _objective : null,
    );
    final children = <Widget>[
      KCard(
        child: KoachSays(
          pose: KoachPose.determined,
          child: Text(
            strength
                ? 'Jour J. Échauffe-toi par paliers, ouvre sur une barre que '
                      'tu réussis à coup sûr ; je recalcule la suite après '
                      'chaque tentative.'
                : 'Jour J. Pars au rythme conseillé : les premières séries '
                      'paraissent faciles, c’est voulu.',
          ),
        ),
      ),
    ];
    if (strength) {
      children.add(
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final e in _objectives.entries)
              ChoiceChip(
                key: ValueKey('event-objective-${e.key.code}'),
                label: Text(e.value),
                selected: _objective == e.key,
                onSelected: (_) => setState(() => _objective = e.key),
              ),
          ],
        ),
      );
    }
    if (plan == null) {
      children.add(
        const KCard(
          child: Text(
            'Je n’ai pas assez d’éléments pour te proposer des tentatives '
            'aujourd’hui : fie-toi à tes derniers lourds.',
          ),
        ),
      );
    } else {
      for (final lift in plan.lifts) {
        final done = [
          for (final a in _done)
            if (a.exerciseId == lift.exerciseId) a,
        ];
        children.add(
          KCard(
            key: ValueKey('event-lift-${lift.exerciseId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_name(lift.exerciseId), style: t.titleMedium),
                if (lift.estimateKg != null)
                  Text(
                    'Maximum du jour estimé : ${adaptKg(lift.estimateKg!)}'
                    '${lift.standardErrorKg == null ? '' : ' (± ${adaptKg(lift.standardErrorKg!)})'}',
                    style: t.bodySmall,
                  ),
                if ((lift.warmup ?? const <kc.WarmupStep>[]).isNotEmpty &&
                    done.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Échauffement', style: t.titleSmall),
                  for (final w in lift.warmup!)
                    Text(
                      '${adaptKg(w.loadKg)} × ${w.reps}'
                      '${w.restSeconds == null ? '' : ' · repos ${w.restSeconds! ~/ 60} min'}',
                    ),
                ],
                for (final a in done)
                  Text(
                    'Tentative ${a.index + 1} : ${adaptKg(a.loadKg)} — '
                    '${a.success ? 'réussie' : 'manquée'}',
                    style: t.bodyMedium?.copyWith(
                      color: a.success ? SL.success : SL.dim,
                    ),
                  ),
                const SizedBox(height: 8),
                for (final s in lift.attempts)
                  if (!done.any((d) => d.index >= s.index))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tentative ${s.index + 1} : ${adaptKg(s.loadKg)}'
                              '${s.successProbability == null ? '' : ' · ${(s.successProbability! * 100).round()} % de chances'}',
                              style: t.titleSmall,
                            ),
                          ),
                          if (s.index ==
                              (done.isEmpty ? 0 : done.last.index + 1)) ...[
                            IconButton(
                              key: ValueKey(
                                'event-ok-${lift.exerciseId}-${s.index}',
                              ),
                              tooltip: 'Réussie',
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _mark(
                                lift.exerciseId,
                                s.index,
                                s.loadKg,
                                true,
                              ),
                            ),
                            IconButton(
                              key: ValueKey(
                                'event-miss-${lift.exerciseId}-${s.index}',
                              ),
                              tooltip: 'Manquée',
                              icon: const Icon(Icons.cancel_outlined),
                              onPressed: () => _mark(
                                lift.exerciseId,
                                s.index,
                                s.loadKg,
                                false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
              ],
            ),
          ),
        );
      }
      final pacing = plan.pacing ?? const <kc.PacingSegment>[];
      if (pacing.isNotEmpty || plan.targetTotalReps != null) {
        children.add(
          KCard(
            key: const ValueKey('event-pacing'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (plan.targetTotalReps != null)
                  Text(
                    'Objectif : ${plan.targetTotalReps} répétitions',
                    style: t.titleMedium,
                  ),
                for (final p in pacing)
                  Text(
                    '${_name(p.exerciseId)} : ${p.setReps.join(' – ')}'
                    '${p.restSeconds == null ? '' : ' (${p.restSeconds} s entre les séries)'}',
                  ),
              ],
            ),
          ),
        );
      }
      final notes = <String>[
        for (final r in plan.reasons)
          if (adaptReasonText(r, exerciseName: _name) case final s?) s,
      ];
      if (notes.isNotEmpty) {
        children.add(
          KCard(child: Text(notes.toSet().join('\n'), style: t.bodySmall)),
        );
      }
    }
    return KScreen(
      appBar: AppBar(
        title: Text((widget.event.name ?? 'Jour J').toUpperCase()),
      ),
      body: KList(key: const ValueKey('event-day'), children: children),
    );
  }
}
