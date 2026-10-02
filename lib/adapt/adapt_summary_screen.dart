// G9 (§4 du lot) : fin de séance servie par `kalis_adapt`. Koach résume ce
// qui a été calibré, ce qui a progressé (capacité estimée par le moteur
// avant et après la séance) et ce qui changera la prochaine fois (première
// série de la prochaine séance où l'exercice revient). Les propositions de
// structure arrivent en G10.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachUsage;

import '../app_theme.dart';
import '../koach/koach_bubble.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'adapt_texts.dart';
import 'flame_track.dart';

String _goalText(SetGoal g) {
  final amount = adaptAmount(g.low, g.high, seconds: g.seconds);
  return [
    if (g.kg != null && g.kg! > 0) adaptKg(g.kg!),
    if (amount.isNotEmpty) amount,
  ].join(' × ');
}

/// « (aujourd'hui : 60 kg × 8) » quand la cible du jour était une valeur
/// unique et différente.
String _todayText(AdaptExerciseSummary e) {
  final t = e.today, n = e.next;
  if (t == null || n == null) return '';
  if (t.low != null && t.high != null && t.low != t.high) return '';
  final a = _goalText(t);
  if (a.isEmpty || a == _goalText(n)) return '';
  return ' (aujourd’hui : $a)';
}

/// Résumé de Koach en fin de séance.
class AdaptSummaryScreen extends StatefulWidget {
  final WeekPlan week;
  final DayPlan base;
  const AdaptSummaryScreen({super.key, required this.week, required this.base});

  /// Un résumé est disponible pour cette séance.
  static bool available(int week, DayPlan base) =>
      store.sessionAdapt(week, base.j) != null;

  @override
  State<AdaptSummaryScreen> createState() => _AdaptSummaryScreenState();
}

class _AdaptSummaryScreenState extends State<AdaptSummaryScreen> {
  late final AdaptSessionSummary? _s = store.adaptSummary(
    widget.week.n,
    widget.base,
  );

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final calibrating = [
      for (final e in s?.exercises ?? const <AdaptExerciseSummary>[])
        if (e.calibrating) e,
    ];
    final progressed = [
      for (final e in s?.exercises ?? const <AdaptExerciseSummary>[])
        if (e.progressed) e,
    ];
    final next = [
      for (final e in s?.exercises ?? const <AdaptExerciseSummary>[])
        if (e.next != null) e,
    ];
    final headline = s == null || s.exercises.isEmpty
        ? 'Séance terminée. Merci pour tes notes : elles règlent tes '
              'prochaines charges.'
        : [
            'Séance terminée !',
            if (calibrating.isNotEmpty)
              '${calibrating.length} exercice${calibrating.length > 1 ? 's' : ''} '
                  'en calibrage.',
            if (progressed.isNotEmpty)
              '${progressed.length} en progrès selon mon estimation.',
            if (progressed.isEmpty && calibrating.isEmpty)
              'Tes charges sont calées, on continue.',
          ].join(' ');
    return KScreen(
      appBar: AppBar(title: const Text('Fin de séance')),
      body: KList(
        key: const ValueKey('adapt-summary'),
        children: [
          KCard(
            child: KoachBubble(
              pose: koachPose(KoachUsage.sessionEnd),
              text: headline,
              why:
                  'J’estime ce que tu peux faire sur chaque exercice à partir '
                  'de tes séries et de tes flammes. Une estimation bouge peu '
                  'd’une séance à l’autre : c’est la tendance qui compte.',
              koachHeight: 96,
            ),
          ),
          if (calibrating.isNotEmpty)
            _section('summary-calibration', 'Calibrage', [
              for (final e in calibrating)
                '${e.name} : je cale encore la charge sur ce que tu fais.',
            ]),
          if (s != null && s.exercises.isNotEmpty)
            _section(
              'summary-progress',
              'Ce qui a progressé',
              progressed.isEmpty
                  ? [
                      'Rien de net aujourd’hui : il faut quelques séances pour '
                          'le voir.',
                    ]
                  : [
                      for (final e in progressed)
                        '${e.name} : ${capacityText(e.before!)} → '
                            '${capacityText(e.after!)}.',
                    ],
            ),
          if (next.isNotEmpty)
            _section('summary-next', 'La prochaine fois', [
              for (final e in next)
                '${e.name} : ${_goalText(e.next!)}'
                    '${_todayText(e)}.',
            ]),
          if (_sets() case final sets? when sets.isNotEmpty)
            KCard(
              key: const ValueKey('summary-sets'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tes séries',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final (i, (name, lines)) in sets.indexed) ...[
                    Padding(
                      padding: EdgeInsets.only(top: i == 0 ? 6 : 12, bottom: 2),
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    ...lines,
                  ],
                ],
              ),
            ),
          if (s != null && s.painReferralZones.isNotEmpty)
            KCard(
              key: const ValueKey('summary-referral'),
              accent: SL.accent,
              child: KoachSays(
                pose: koachPose(KoachUsage.care),
                child: Text(
                  '${s.painReferralZones.join(', ')} : $kPainReferral',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          FilledButton(
            key: const ValueKey('summary-done'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(KControl.buttonHeight),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  /// G9 correction 1 : toutes les séries de la séance, une ligne chacune.
  List<(String, List<Widget>)>? _sets() {
    final w = widget.week.n, j = widget.base.j;
    final log = store.logs[store.sessionKey(w, j)];
    if (log == null) return null;
    final a = store.sessionAdapt(w, j);
    final day = a == null ? widget.base : store.adaptDay(w, widget.base, a);
    return [
      for (final e in day.exercises)
        if (log.ex[e.id] case final x? when x.sets.any((s) => s.done))
          (
            store.splitName(e.name).$1,
            [
              for (var i = 0; i < x.sets.length; i++)
                if (x.sets[i].done)
                  SetSummaryLine(
                    setLabel: store.setLabel(store.logSpec(e), i),
                    done: setDoneText(x.sets[i], store.logSpec(e)),
                    flames: setFlamesOf(x.sets[i]),
                    unknown: x.sets[i].flamesUnknown,
                    excluded: x.sets[i].excluded,
                  ),
            ],
          ),
    ];
  }

  Widget _section(String key, String title, List<String> lines) => KCard(
    key: ValueKey(key),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final l in lines)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(l)),
      ],
    ),
  );
}
