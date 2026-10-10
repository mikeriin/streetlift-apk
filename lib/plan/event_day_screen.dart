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
import '../koach/koach_bubble.dart' show KoachSays;
import '../store.dart';
import '../ui.dart';

const _objectives = <kc.EventObjective, String>{
  kc.EventObjective.secureTotal: 'Assurer un total',
  kc.EventObjective.maxTotal: 'Viser le plus gros total',
  kc.EventObjective.record: 'Tenter un record',
};

String _rest(int s) => s < 120
    ? '$s\u00A0s'
    : s % 60 == 0
    ? '${s ~/ 60}\u00A0min'
    : '${s ~/ 60}\u00A0min ${s % 60}\u00A0s';

class EventDayScreen extends StatefulWidget {
  final kc.SeasonEvent event;
  const EventDayScreen({super.key, required this.event});

  @override
  State<EventDayScreen> createState() => _EventDayScreenState();
}

class _EventDayScreenState extends State<EventDayScreen> {
  final List<kc.AttemptResult> _done = [];
  kc.EventObjective _objective = kc.EventObjective.maxTotal;

  /// Dernier plan calculé et sa clé (objectif, tentatives notées) : le
  /// moteur n'est rappelé que quand l'une change.
  String? _planKey;
  kc.EventDayPlan? _plan;

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
    final k = KTokens.of(context);
    final strength = widget.event.kind == kc.EventKind.strengthCompetition;
    final key =
        '${_objective.code}|${[for (final a in _done) '${a.exerciseId}:${a.index}:${a.success}'].join(',')}';
    if (key != _planKey) {
      _planKey = key;
      _plan = store.evolutionEventDay(
        widget.event.id,
        done: List.unmodifiable(_done),
        objective: strength ? _objective : null,
      );
    }
    final plan = _plan;
    final body = KType.corps.copyWith(color: k.texte);
    final detail = KType.detail.copyWith(color: k.texte2);
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
            style: body,
          ),
        ),
      ),
    ];
    if (strength) {
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KSectionTitle('Objectif du jour', top: 0),
            KSegmented<kc.EventObjective>(
              key: const ValueKey('event-objective'),
              semanticLabel: 'Objectif du jour',
              segments: [
                for (final e in _objectives.entries)
                  KSegment(e.key, e.value),
              ],
              selected: _objective,
              onChanged: (v) => setState(() => _objective = v),
            ),
          ],
        ),
      );
    }
    if (plan == null) {
      children.add(
        KCard(
          child: Text(
            'Je n’ai pas assez d’éléments pour te proposer des tentatives '
            'aujourd’hui : fie-toi à tes derniers lourds.',
            style: body,
          ),
        ),
      );
    } else {
      for (final lift in plan.lifts) {
        final done = [
          for (final a in _done)
            if (a.exerciseId == lift.exerciseId) a,
        ];
        final next = done.isEmpty ? 0 : done.last.index + 1;
        children.add(
          KCard(
            key: ValueKey('event-lift-${lift.exerciseId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _name(lift.exerciseId),
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                if (lift.estimateKg != null)
                  Text(
                    'Maximum du jour estimé : ${adaptKg(lift.estimateKg!)}'
                    '${lift.standardErrorKg == null ? '' : ' (± ${adaptKg(lift.standardErrorKg!)})'}',
                    style: detail,
                  ),
                if ((lift.warmup ?? const <kc.WarmupStep>[]).isNotEmpty &&
                    done.isEmpty) ...[
                  const KSectionTitle('Échauffement', top: KSpacing.s12),
                  for (final w in lift.warmup!)
                    Text(
                      '${adaptKg(w.loadKg)} × ${w.reps}'
                      '${w.restSeconds == null ? '' : ', repos ${_rest(w.restSeconds!)}'}',
                      style: body,
                    ),
                ],
                if (done.isNotEmpty) const SizedBox(height: KSpacing.s8),
                for (final a in done)
                  Row(
                    children: [
                      Icon(
                        a.success
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        size: KSize.iconSmall,
                        color: a.success ? k.validation : k.texte2,
                      ),
                      const SizedBox(width: KSpacing.s8),
                      Expanded(
                        child: Text(
                          'Tentative ${a.index + 1} : ${adaptKg(a.loadKg)}, '
                          '${a.success ? 'réussie' : 'manquée'}',
                          style: KType.corps.copyWith(
                            color: a.success ? k.validation : k.texte2,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: KSpacing.s8),
                for (final s in lift.attempts)
                  if (!done.any((d) => d.index >= s.index))
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: KSize.target,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tentative ${s.index + 1} : ${adaptKg(s.loadKg)}'
                              '${s.successProbability == null ? '' : ', ${(s.successProbability! * 100).round()} % de chances'}',
                              style: s.index == next
                                  ? KType.corpsFort.copyWith(color: k.texte)
                                  : body,
                            ),
                          ),
                          if (s.index == next) ...[
                            KIconButton(
                              key: ValueKey(
                                'event-ok-${lift.exerciseId}-${s.index}',
                              ),
                              tooltip: 'Réussie',
                              icon: Icons.check_circle_outline,
                              color: k.validation,
                              onPressed: () => _mark(
                                lift.exerciseId,
                                s.index,
                                s.loadKg,
                                true,
                              ),
                            ),
                            KIconButton(
                              key: ValueKey(
                                'event-miss-${lift.exerciseId}-${s.index}',
                              ),
                              tooltip: 'Manquée',
                              icon: Icons.cancel_outlined,
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
                    style: KType.titreCarte.copyWith(color: k.texte),
                  ),
                for (final p in pacing)
                  Text(
                    '${_name(p.exerciseId)} : ${p.setReps.join(' – ')}'
                    '${p.restSeconds == null ? '' : ' (${_rest(p.restSeconds!)} entre les séries)'}',
                    style: body,
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
          KCard(child: Text(notes.toSet().join('\n'), style: detail)),
        );
      }
    }
    return KPage.sub(
      key: const ValueKey('event-day'),
      title: widget.event.name ?? 'Jour J',
      subtitle: widget.event.name == null ? null : 'Jour J',
      children: children,
    );
  }
}
