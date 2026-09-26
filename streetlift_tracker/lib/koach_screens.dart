// Koach (L7, KT-028 à KT-033, KT-036) — écrans : bilan de séance (D5 b,
// D26), écran Koach de STATS › Performances (D30), matériel (D23),
// objectifs (D27), pesées (D12), informations d'activation et des
// questionnaires. Koach propose, l'utilisateur décide (D4) ; les états sont
// écrits en toutes lettres (jamais la couleur seule).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'koach_engine.dart' as ke;
import 'koach_widgets.dart';
import 'set_validation.dart' show parseLoadKg;
import 'store.dart';
import 'ui.dart';

String _two(int v) => v.toString().padLeft(2, '0');

/// 26/09/2026
String koachDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String _statusText(String? status) => switch (status) {
  'reached' => 'atteint',
  'past' => 'échéance passée',
  'insufficient' => 'données insuffisantes',
  'late' => 'en retard',
  'ahead' => 'en avance',
  'onTrack' => 'dans les temps',
  _ => 'non défini',
};

String _sourceText(String source) => switch (source) {
  'initial' => 'repère initial',
  'manual' => 'saisie',
  'koach' => 'proposition Koach acceptée',
  'test' => 'résultat de test',
  _ => source,
};

TextStyle _dimSmall() => TextStyle(color: SL.dim, fontSize: 12.5);

// ===================================================================
// Activation et information (D6, KT-036)
// ===================================================================

/// Explication au premier usage, puis activation (D6 : jamais par défaut).
Future<bool> showKoachActivation(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Activer Koach ?'),
          content: const SingleChildScrollView(
            child: Text(
              'Koach suit tes séries du programme (charge, répétitions, '
              'difficulté) pour estimer ton niveau et te proposer des '
              'ajustements de charge, pendant la séance et à la fin.\n\n'
              '• Rien ne change sans ton accord : chaque proposition '
              's’accepte ou se refuse d’un tap.\n'
              '• La difficulté devient obligatoire sur la première et la '
              'dernière série des quatre mouvements principaux.\n'
              '• Tout est calculé sur ton téléphone, sans compte ni '
              'connexion.\n'
              '• Ce sont des estimations d’entraînement, sans garantie de '
              'résultat.\n\n'
              'Tu peux désactiver Koach à tout moment : l’application '
              'retrouve alors son fonctionnement habituel.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              key: const ValueKey('koach-activate'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activer Koach'),
            ),
          ],
        ),
  );
  if (ok != true) return false;
  store.enableKoach();
  return true;
}

/// Information préalable aux questionnaires (D14, KT-036).
const koachQuestionnaireInfo =
    'Sommeil, forme et douleur peuvent être des données de santé. '
    'Ces questions sont facultatives (« Passer » est toujours possible). '
    'Tes réponses restent sur ce téléphone : aucune n’est envoyée. '
    'Elles figurent dans l’export de sauvegarde et sont effacées avec les '
    'données de l’application ; tu peux aussi les supprimer seules. '
    'Koach s’en sert uniquement pour proposer un volume réduit (sommeil, '
    'forme) ou aucune hausse de charge (douleur).';

Future<bool> showKoachQuestionnaireInfo(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Questionnaires Koach'),
          content: const SingleChildScrollView(
            child: Text(koachQuestionnaireInfo),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ne pas activer'),
            ),
            FilledButton(
              key: const ValueKey('koach-questionnaires-accept'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('J’ai compris, activer'),
            ),
          ],
        ),
  );
  if (ok == true) store.setKoachQuestionnaires(true);
  return ok == true;
}

// ===================================================================
// Bilan Koach (D5 b) : douleur facultative, propositions
// ===================================================================

class KoachReviewScreen extends StatelessWidget {
  final int week, day;
  const KoachReviewScreen({super.key, required this.week, required this.day});

  /// Quelque chose à montrer après cette séance ?
  static bool hasContent(int week, int day) {
    if (!store.koachOn || week < 1) return false;
    final key = store.sessionKey(week, day);
    return store.koachProposals(key).isNotEmpty ||
        (store.koachQuestionnaires &&
            store.koachMovementsDone(week, day).isNotEmpty) ||
        store.koachStructureProposals().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final key = store.sessionKey(week, day);
      final proposals = store.koachProposals(key);
      final structure = store.koachStructureProposals();
      final movements =
          store.koachQuestionnaires
              ? store.koachMovementsDone(week, day)
              : const <String>[];
      return KScreen(
        appBar: AppBar(title: Text('Bilan Koach · S$week · J$day')),
        body: KList(
          children: [
            Text(
              'Koach propose, tu décides : aucune valeur ne change sans ton '
              'accord.',
              style: TextStyle(color: SL.dim),
            ),
            if (movements.isNotEmpty) ...[
              const KSection(
                'Douleur pendant la séance',
                subtitle: 'Facultatif · 0 = aucune, 10 = maximale',
              ),
              for (final m in movements) _PainCard(sessionKey: key, movement: m),
            ],
            const KSection('Propositions'),
            if (proposals.isEmpty)
              const KEmpty(
                icon: Icons.check_circle_outline,
                title: 'Rien à changer',
                message: 'Tes valeurs de pilotage restent telles quelles.',
              ),
            for (final p in proposals) KoachProposalCard(proposal: p),
            if (proposals.length > 1)
              OutlinedButton.icon(
                key: const ValueKey('koach-accept-all'),
                onPressed: () {
                  for (final p in List.of(proposals)) {
                    store.acceptKoachProposal(p);
                  }
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Tout accepter'),
              ),
            if (structure.isNotEmpty) ...[
              KSection('Structure · semaine ${structure.first['week']}'),
              for (final p in structure) KoachStructureCard(proposal: p),
            ],
          ],
        ),
        bottomNavigationBar: KBottomActions(
          child: FilledButton(
            key: const ValueKey('koach-review-done'),
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Terminer'),
          ),
        ),
      );
    },
  );
}

class _PainCard extends StatelessWidget {
  final String sessionKey, movement;
  const _PainCard({required this.sessionKey, required this.movement});

  @override
  Widget build(BuildContext context) {
    final v = store.koach.answers[sessionKey]?.pain[movement];
    return KCard(
      key: ValueKey('koach-pain-$movement'),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            koachMovementName(movement),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i <= 10; i++)
                ChoiceChip(
                  label: Text('$i'),
                  tooltip: 'Douleur $i sur 10',
                  selected: v == i,
                  onSelected:
                      (on) =>
                          store.setKoachPain(sessionKey, movement, on ? i : null),
                ),
            ],
          ),
          if (v != null && v > 3) ...[
            const SizedBox(height: 8),
            Text(
              'Au-dessus de 3/10 : aucune hausse de charge ne sera proposée à '
              'la prochaine séance. Une douleur qui persiste relève d’un '
              'professionnel de santé.',
              style: _dimSmall(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Proposition de fin de séance : « Accepter » / « Refuser ».
class KoachProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  const KoachProposalCard({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    final p = proposal;
    return KCard(
      key: ValueKey('koach-proposal-${p['id']}'),
      radius: 20,
      accent: SL.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            store.koachProposalText(p),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(store.koachProposalReason(p), style: _dimSmall()),
          const SizedBox(height: 10),
          KActionRow(
            minButtonWidth: 120,
            children: [
              FilledButton(
                key: ValueKey('koach-accept-${p['id']}'),
                onPressed: () => store.acceptKoachProposal(p),
                child: const Text('Accepter'),
              ),
              OutlinedButton(
                key: ValueKey('koach-refuse-${p['id']}'),
                onPressed: () => store.refuseKoachProposal(p),
                child: const Text('Refuser'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String koachStructureText(Map<String, dynamic> p) {
  final m = koachMovementName(p['movement'] as String);
  if (p['kind'] == 'deload') {
    return 'Décharge anticipée semaine ${p['week']} : séries × '
        '${koachKg((p['sets'] as num).toDouble())} (au moins 1), charges '
        '−${(((p['load'] as num).toDouble()) * 100).round()} % sur les '
        'mouvements principaux.';
  }
  final delta = p['delta'] as int;
  return '$m : ${delta > 0 ? '+1 série' : '−1 série'} sur l’exercice principal '
      'de la semaine ${p['week']}.';
}

String koachStructureReason(Map<String, dynamic> p) => switch (p['reason']) {
  'late' => 'Rythme observé en retard sur l’objectif.',
  'ahead' => 'Rythme observé en avance sur l’objectif.',
  'decline' =>
    'Estimation en baisse deux semaines de suite, avec un signal de fatigue.',
  _ => '',
};

/// Proposition de structure (D28) pour la semaine suivante.
class KoachStructureCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  const KoachStructureCard({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    final p = proposal;
    return KCard(
      key: ValueKey('koach-structure-${p['id']}'),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            koachStructureText(p),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${koachStructureReason(p)} Le programme d’origine n’est pas '
            'modifié : l’adaptation s’annule à tout moment.',
            style: _dimSmall(),
          ),
          const SizedBox(height: 10),
          KActionRow(
            minButtonWidth: 120,
            children: [
              FilledButton(
                onPressed: () => store.acceptKoachStructure(p),
                child: const Text('Accepter'),
              ),
              OutlinedButton(
                onPressed: () => store.refuseKoachStructure(p),
                child: const Text('Refuser'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// Écran Koach (STATS › Performances, D30)
// ===================================================================

class KoachScreen extends StatelessWidget {
  const KoachScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (!store.koachOn) {
        return KScreen(
          appBar: AppBar(title: const Text('Koach')),
          body: const KList(
            children: [
              KEmpty(
                icon: Icons.insights_rounded,
                title: 'Koach est désactivé',
                message: 'Active-le dans Réglages › Koach.',
              ),
            ],
          ),
        );
      }
      final last = store.koachLastSession;
      final pending =
          last == null
              ? const <Map<String, dynamic>>[]
              : store.koachProposals(last);
      final structure = store.koachStructureProposals();
      final adaptations = [
        for (final a in store.koach.adaptations)
          if (a.active) a,
      ];
      final objectives = store.koachObjectives();
      final lifts = store.program.pilotage.mainLifts;
      final reps = store.program.pilotage.repMax;
      return KScreen(
        appBar: AppBar(title: const Text('Koach')),
        body: KList(
          children: [
            Text(
              'Estimations d’entraînement calculées sur ton téléphone à partir '
              'de tes séries du programme. Ce ne sont pas des mesures : '
              'aucune valeur ne change sans ton accord.',
              style: TextStyle(color: SL.dim),
            ),
            if (store.koachLoadIssues > 0)
              KCard(
                outline: SL.danger,
                child: Text(
                  '${store.koachLoadIssues} entrée(s) Koach illisible(s) '
                  'ignorée(s) à l’ouverture. Le reste de tes données est '
                  'chargé.',
                ),
              ),
            if (pending.isNotEmpty) ...[
              const KSection(
                'Propositions en attente',
                subtitle: 'Dernière séance terminée',
              ),
              for (final p in pending) KoachProposalCard(proposal: p),
            ],
            if (store.koach.structure) ...[
              const KSection(
                'Structure',
                subtitle: 'Option « Koach adapte la structure »',
              ),
              if (structure.isEmpty && adaptations.isEmpty)
                Text(
                  'Aucune adaptation proposée pour la semaine prochaine '
                  '(au moins 6 semaines de données par mouvement).',
                  style: _dimSmall(),
                ),
              for (final p in structure) KoachStructureCard(proposal: p),
              for (final a in adaptations)
                KCard(
                  radius: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Semaine ${a.week} · '
                          '${a.kind == 'deload' ? 'décharge anticipée' : '${a.delta > 0 ? '+1' : '−1'} série · ${koachMovementName(a.movement)}'}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => store.revertKoachAdaptation(a.id),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ),
            ],
            const KSection(
              'Force · 1RM estimé',
              subtitle: 'Lest pour muscle-up, traction et dip ; barre au squat',
            ),
            for (final l in lifts)
              _LiftCard(
                ref: l.ref,
                name: l.name,
                movement: l.key,
                objectives: (objectives[l.ref] as Map?)?.cast<String, dynamic>(),
              ),
            const KSection(
              'Endurance · maximum estimé',
              subtitle: 'Répétitions au poids du corps',
            ),
            for (final r in reps)
              _RepCard(
                ref: r.ref,
                name: r.name,
                objectives: (objectives[r.ref] as Map?)?.cast<String, dynamic>(),
              ),
            const KSection('Historique des valeurs'),
            ..._history(),
            const KSection('Pesées'),
            KMenuTile(
              icon: Icons.monitor_weight_outlined,
              title: 'Pesées',
              subtitle:
                  store.koach.weighIns.isEmpty
                      ? 'Aucune pesée'
                      : 'Dernière : ${koachKg(store.koach.weighIns.last.kg)} kg '
                          'le ${koachDate(DateTime.parse(store.koach.weighIns.last.date))}',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const KoachWeighInsScreen(),
                    ),
                  ),
            ),
          ],
        ),
      );
    },
  );

  List<Widget> _history() {
    final items = store.koach.history.reversed.take(30).toList();
    if (items.isEmpty) {
      return [Text('Aucune valeur enregistrée.', style: _dimSmall())];
    }
    return [
      KCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final h in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${koachDate(DateTime.parse(h.at))} · '
                  '${store.referenceLabel(h.ref)} : ${koachKg(h.value)} · '
                  '${_sourceText(h.source)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (store.koach.history.length > items.length)
              Text(
                '${store.koach.history.length - items.length} valeurs plus '
                'anciennes dans l’export de sauvegarde.',
                style: _dimSmall(),
              ),
          ],
        ),
      ),
    ];
  }
}

String _objectiveLine(
  String ref,
  String level,
  Map<String, dynamic>? objectives,
  String unit,
) {
  final o = store.koachObjective(ref, level);
  final name = level == 'stage' ? 'Étape' : 'Objectif final';
  if (o.target == null || o.date == null) return '$name : non défini';
  final st =
      ((objectives?['objectives'] as Map?)?[level] as Map?)
          ?.cast<String, dynamic>();
  final observed = (st?['observed'] as num?)?.toDouble();
  final required = (st?['required'] as num?)?.toDouble();
  final pace = [
    if (observed != null) 'rythme ${observed >= 0 ? '+' : '−'}${koachKg(observed.abs())} $unit/sem.',
    if (required != null && st?['status'] != 'reached')
      'requis ${required >= 0 ? '+' : '−'}${koachKg(required.abs())}',
  ].join(', ');
  return '$name : ${koachKg(o.target!)} $unit le ${koachDate(o.date!)} · '
      '${_statusText(st?['status'] as String?)}${pace.isEmpty ? '' : ' ($pace)'}';
}

class _LiftCard extends StatelessWidget {
  final String ref, name, movement;
  final Map<String, dynamic>? objectives;
  const _LiftCard({
    required this.ref,
    required this.name,
    required this.movement,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    final est = store.koachEstimate(movement);
    final series = store.koachSeries(movement);
    final value = store.values[ref];
    final locked = store.koach.locks.contains(ref);
    final stage = store.koachObjective(ref, 'stage');
    final fin = store.koachObjective(ref, 'final');
    final slope = (objectives?['slope'] as num?)?.toDouble();
    return KCard(
      key: ValueKey('koach-lift-$movement'),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            est == null
                ? 'Pas encore d’estimation : termine une séance avec ce '
                    'mouvement.'
                : store.koachEstimateText(movement),
          ),
          Text(
            'Valeur de pilotage : '
            '${value == null ? 'non renseignée' : '${koachKg(value)} kg'}'
            '${store.koachUncertain(movement) && est != null ? ' · estimation encore incertaine' : ''}',
            style: _dimSmall(),
          ),
          if (series.length >= 2) ...[
            const SizedBox(height: 10),
            KoachCurve(
              points: series,
              unit: 'kg',
              slope: slope,
              stage: stage.target == null || stage.date == null
                  ? null
                  : (stage.date!, stage.target!),
              finalGoal: fin.target == null || fin.date == null
                  ? null
                  : (fin.date!, fin.target!),
              now: store.storeClock(),
            ),
          ],
          const SizedBox(height: 8),
          Text(_objectiveLine(ref, 'stage', objectives, 'kg'), style: _dimSmall()),
          Text(_objectiveLine(ref, 'final', objectives, 'kg'), style: _dimSmall()),
          SwitchListTile.adaptive(
            key: ValueKey('koach-lock-$ref'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Garder ma valeur'),
            subtitle: const Text(
              'Aucune proposition pour cette valeur (pendant la séance et au '
              'bilan).',
            ),
            value: locked,
            onChanged: (_) => store.toggleKoachLock(ref),
          ),
        ],
      ),
    );
  }
}

class _RepCard extends StatelessWidget {
  final String ref, name;
  final Map<String, dynamic>? objectives;
  const _RepCard({
    required this.ref,
    required this.name,
    required this.objectives,
  });

  @override
  Widget build(BuildContext context) {
    final tr = store.koachState().rtracks[ref];
    final value = store.values[ref];
    final locked = store.koach.locks.contains(ref);
    return KCard(
      key: ValueKey('koach-rep-$ref'),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            tr == null
                ? 'Pas encore d’estimation.'
                : 'Maximum estimé : ${koachKg(ke.r2(tr.x))} reps '
                    '(± ${koachKg(ke.r2(tr.sd))}).',
          ),
          Text(
            'Valeur de pilotage : '
            '${value == null ? 'non renseignée' : '${koachKg(value)} reps'}',
            style: _dimSmall(),
          ),
          const SizedBox(height: 6),
          Text(_objectiveLine(ref, 'stage', objectives, 'reps'), style: _dimSmall()),
          Text(_objectiveLine(ref, 'final', objectives, 'reps'), style: _dimSmall()),
          SwitchListTile.adaptive(
            key: ValueKey('koach-lock-$ref'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Garder ma valeur'),
            value: locked,
            onChanged: (_) => store.toggleKoachLock(ref),
          ),
        ],
      ),
    );
  }
}

/// Courbe de l'estimation (bande ± 1 écart type), mesures, projection au
/// rythme observé et repères d'objectifs. Le texte de la carte donne les
/// mêmes informations (lecteur d'écran, jamais la couleur seule).
class KoachCurve extends StatelessWidget {
  final List<({DateTime at, double value, double sd, String kind})> points;
  final String unit;
  final double? slope;
  final (DateTime, double)? stage, finalGoal;
  final DateTime now;
  const KoachCurve({
    super.key,
    required this.points,
    required this.unit,
    required this.now,
    this.slope,
    this.stage,
    this.finalGoal,
  });

  @override
  Widget build(BuildContext context) {
    final first = points.first, last = points.last;
    final label =
        'Courbe de l’estimation : ${koachKg(ke.r2(first.value))} $unit le '
        '${koachDate(first.at)}, ${koachKg(ke.r2(last.value))} $unit le '
        '${koachDate(last.at)}'
        '${stage == null ? '' : ' ; étape ${koachKg(stage!.$2)} $unit le ${koachDate(stage!.$1)}'}'
        '${finalGoal == null ? '' : ' ; objectif final ${koachKg(finalGoal!.$2)} $unit le ${koachDate(finalGoal!.$1)}'}.';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: _CurvePainter(
            points: points,
            slope: slope,
            stage: stage,
            finalGoal: finalGoal,
            now: now,
            line: SL.accent,
            band: SL.accent.withValues(alpha: .16),
            goal: SL.text,
            grid: SL.dim.withValues(alpha: .35),
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<({DateTime at, double value, double sd, String kind})> points;
  final double? slope;
  final (DateTime, double)? stage, finalGoal;
  final DateTime now;
  final Color line, band, goal, grid;
  _CurvePainter({
    required this.points,
    required this.slope,
    required this.stage,
    required this.finalGoal,
    required this.now,
    required this.line,
    required this.band,
    required this.goal,
    required this.grid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final goals = <(DateTime, double)>[
      if (stage case final st?) st,
      if (finalGoal case final fg?) fg,
    ];
    final t0 = points.first.at;
    var t1 = points.last.at;
    if (now.isAfter(t1)) t1 = now;
    for (final g in goals) {
      if (g.$1.isAfter(t1)) t1 = g.$1;
    }
    var lo = double.infinity, hi = -double.infinity;
    for (final p in points) {
      lo = math.min(lo, p.value - p.sd);
      hi = math.max(hi, p.value + p.sd);
    }
    for (final g in goals) {
      lo = math.min(lo, g.$2);
      hi = math.max(hi, g.$2);
    }
    if (hi - lo < 1) {
      hi += .5;
      lo -= .5;
    }
    final pad = (hi - lo) * .08;
    lo -= pad;
    hi += pad;
    final span = math.max(1, t1.difference(t0).inMinutes).toDouble();
    Offset at(DateTime t, double v) => Offset(
      t.difference(t0).inMinutes / span * size.width,
      size.height - (v - lo) / (hi - lo) * size.height,
    );
    final g = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      g,
    );
    final top = at(points.first.at, points.first.value + points.first.sd);
    final bandPath = Path()..moveTo(top.dx, top.dy);
    for (final p in points) {
      final o = at(p.at, p.value + p.sd);
      bandPath.lineTo(o.dx, o.dy);
    }
    for (final p in points.reversed) {
      final o = at(p.at, p.value - p.sd);
      bandPath.lineTo(o.dx, o.dy);
    }
    bandPath.close();
    canvas.drawPath(bandPath, Paint()..color = band);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i].at, points[i].value);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final p in points) {
      if (p.kind == 'session' || p.kind == 'test' || p.kind == 'manual') {
        canvas.drawCircle(at(p.at, p.value), 3, Paint()..color = line);
      }
    }
    // Projection au rythme observé (pointillés), jusqu'au dernier repère.
    final s = slope;
    if (s != null && t1.isAfter(points.last.at)) {
      final weeks = t1.difference(points.last.at).inHours / (24 * 7);
      final end = at(t1, points.last.value + s * weeks);
      final start = at(points.last.at, points.last.value);
      final dash = Paint()
        ..color = line.withValues(alpha: .7)
        ..strokeWidth = 1.5;
      const n = 24;
      for (var i = 0; i < n; i += 2) {
        canvas.drawLine(
          Offset.lerp(start, end, i / n)!,
          Offset.lerp(start, end, (i + 1) / n)!,
          dash,
        );
      }
    }
    for (final gl in goals) {
      final o = at(gl.$1, gl.$2);
      canvas.drawCircle(
        o,
        5,
        Paint()
          ..color = goal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) =>
      old.points != points ||
      old.slope != slope ||
      old.stage != stage ||
      old.finalGoal != finalGoal ||
      old.line != line;
}

// ===================================================================
// Pesées (D12)
// ===================================================================

class KoachWeighInsScreen extends StatelessWidget {
  const KoachWeighInsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final list = store.koach.weighIns.reversed.toList();
      return KScreen(
        appBar: AppBar(title: const Text('Pesées')),
        body: KList(
          children: [
            Text(
              'La pesée applicable à la date d’une série sert au calcul des '
              'mouvements lestés. La plus récente devient ton poids du corps '
              'dans Références. Un rappel s’affiche sur l’accueil après 7 '
              'jours sans pesée (Koach actif).',
              style: TextStyle(color: SL.dim),
            ),
            if (list.isEmpty)
              const KEmpty(
                icon: Icons.monitor_weight_outlined,
                title: 'Aucune pesée',
                message: 'Ajoute ta première pesée.',
              ),
            for (final w in list)
              KCard(
                key: ValueKey('weigh-in-${w.date}'),
                padding: EdgeInsets.zero,
                radius: 20,
                child: ListTile(
                  title: Text('${koachKg(w.kg)} kg'),
                  subtitle: Text(koachDate(DateTime.parse(w.date))),
                  trailing: IconButton(
                    tooltip: 'Supprimer la pesée du ${koachDate(DateTime.parse(w.date))}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => store.removeWeighIn(w.date),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: KBottomActions(
          child: FilledButton.icon(
            key: const ValueKey('weigh-in-add'),
            onPressed: () => showWeighInDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une pesée'),
          ),
        ),
      );
    },
  );
}

// ===================================================================
// Matériel et incréments (D23)
// ===================================================================

const _equipmentNames = {
  'dumbbell': 'Haltères',
  'plate': 'Lest (disques)',
  'barbell': 'Barre',
  'pulley': 'Poulies',
  'machine': 'Machines guidées',
};

const _equipmentFields = {
  'small': 'Petit incrément',
  'threshold': 'Petit incrément jusqu’à',
  'large': 'Grand incrément au-delà',
  'step': 'Incrément',
};

class KoachEquipmentScreen extends StatelessWidget {
  const KoachEquipmentScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    String kind,
    String field,
    double current,
  ) async {
    final v = await showKoachNumberDialog(
      context,
      title: '${_equipmentNames[kind]} · ${_equipmentFields[field]}',
      label: 'Valeur (${(store.koach.equipmentSettings[kind] as Map)['unit'] ?? 'kg'})',
      initial: current,
      min: 0.01,
      max: 50,
    );
    if (v == null) return;
    final cur = Map<String, dynamic>.from(
      store.koach.equipment[kind] ?? const {},
    );
    cur[field] = v;
    store.setKoachEquipment(kind, cur);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final eq = store.koach.equipmentSettings;
      return KScreen(
        appBar: AppBar(title: const Text('Matériel')),
        body: KList(
          children: [
            Text(
              'Les charges et les propositions de Koach suivent les '
              'incréments de ton matériel. Valeurs par défaut modifiables.',
              style: TextStyle(color: SL.dim),
            ),
            for (final kind in _equipmentNames.keys)
              KCard(
                key: ValueKey('equipment-$kind'),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _equipmentNames[kind]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final f in _equipmentFields.keys)
                      if ((eq[kind] as Map).containsKey(f))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_equipmentFields[f]!),
                          trailing: Text(
                            '${koachKg(((eq[kind] as Map)[f] as num).toDouble())} '
                            '${(eq[kind] as Map)['unit'] ?? 'kg'}',
                            style: KControl.numberStyle,
                          ),
                          onTap:
                              () => _edit(
                                context,
                                kind,
                                f,
                                ((eq[kind] as Map)[f] as num).toDouble(),
                              ),
                        ),
                    if ((eq[kind] as Map).containsKey('unit'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'kg', label: Text('kg')),
                            ButtonSegment(value: 'lb', label: Text('lb')),
                          ],
                          selected: {(eq[kind] as Map)['unit'] as String},
                          onSelectionChanged: (sel) {
                            final cur = Map<String, dynamic>.from(
                              store.koach.equipment[kind] ?? const {},
                            );
                            cur['unit'] = sel.single;
                            store.setKoachEquipment(kind, cur);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: store.resetKoachEquipment,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Rétablir les valeurs par défaut'),
            ),
          ],
        ),
      );
    },
  );
}

/// Saisie d'un nombre borné (virgule ou point).
Future<double?> showKoachNumberDialog(
  BuildContext context, {
  required String title,
  required String label,
  double? initial,
  required double min,
  required double max,
}) => showDialog<double>(
  context: context,
  builder:
      (_) => _NumberDialog(
        title: title,
        label: label,
        initial: initial,
        min: min,
        max: max,
      ),
);

class _NumberDialog extends StatefulWidget {
  final String title, label;
  final double? initial;
  final double min, max;
  const _NumberDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.min,
    required this.max,
  });
  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final _c = TextEditingController(
    text: widget.initial == null ? '' : koachKg(widget.initial!),
  );
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    final v = parseLoadKg(_c.text);
    if (v == null || v < widget.min || v > widget.max) {
      setState(
        () =>
            _error =
                'De ${koachKg(widget.min)} à ${koachKg(widget.max)}, deux '
                'décimales au plus.',
      );
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const ValueKey('koach-number'),
      controller: _c,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: widget.label, errorText: _error),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const ValueKey('koach-number-save'),
        onPressed: _save,
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

// ===================================================================
// Objectifs (D27)
// ===================================================================

class KoachObjectivesScreen extends StatelessWidget {
  const KoachObjectivesScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    String ref,
    String name,
    String level,
    String unit,
  ) async {
    final o = store.koachObjective(ref, level);
    final target = await showKoachNumberDialog(
      context,
      title:
          '$name · ${level == 'stage' ? 'étape' : 'objectif final'} ($unit)',
      label: 'Cible ($unit)',
      initial: o.target,
      min: 0,
      max: 10000,
    );
    if (target == null || !context.mounted) return;
    final today = store.storeClock();
    final date = await showDatePicker(
      context: context,
      helpText: 'Date de l’objectif',
      initialDate:
          o.date ?? DateTime(today.year + 1, today.month, today.day),
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (date == null) return;
    store.setKoachObjective(ref, level, target, date);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final rows = [
        for (final l in store.program.pilotage.mainLifts)
          (l.ref, l.name, 'kg'),
        for (final r in store.program.pilotage.repMax) (r.ref, r.name, 'reps'),
      ];
      return KScreen(
        appBar: AppBar(title: const Text('Objectifs')),
        body: KList(
          children: [
            Text(
              'Étape : par défaut la cible 12 mois du programme, 12 mois après '
              'ton départ. Objectif final : à saisir. Tout est modifiable ; '
              'Koach compare le rythme observé au rythme requis.',
              style: TextStyle(color: SL.dim),
            ),
            for (final (ref, name, unit) in rows)
              KCard(
                key: ValueKey('objective-$ref'),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    for (final level in const ['stage', 'final'])
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          level == 'stage' ? 'Étape' : 'Objectif final',
                        ),
                        subtitle: Text(_objectiveValue(ref, level, unit)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (store.koach.objectives[ref]?[level] != null)
                              IconButton(
                                tooltip:
                                    level == 'stage'
                                        ? 'Revenir à la valeur par défaut'
                                        : 'Effacer l’objectif final',
                                icon: const Icon(Icons.undo_rounded),
                                onPressed:
                                    () => store.setKoachObjective(
                                      ref,
                                      level,
                                      null,
                                      null,
                                    ),
                              ),
                            const Icon(Icons.edit_outlined),
                          ],
                        ),
                        onTap: () => _edit(context, ref, name, level, unit),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );

  String _objectiveValue(String ref, String level, String unit) {
    final o = store.koachObjective(ref, level);
    if (o.target == null || o.date == null) return 'Non défini';
    return '${koachKg(o.target!)} $unit le ${koachDate(o.date!)}';
  }
}
