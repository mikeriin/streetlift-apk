// G10 (D2.5) : inspecteur du moteur dynamique (`kalis_adapt`) et export de
// son journal, en session de test.
//
// Pour la séance du jour (ou la prochaine) : charges, répétitions et
// flammes visées de chaque exercice avec la capacité estimée ± incertitude,
// la règle de décision (codes de raison) et la confiance ; ajustements du
// bilan ; forme du jour et fatigue ; niveau de déblocage ; propositions
// retenues et écartées avec leurs termes (progrès, risque, fatigue,
// adhésion) et la raison d'un écart.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../adapt/adapt_texts.dart';
import '../app_theme.dart';
import '../athlete_profile.dart' show civilOf;
import '../koach/koach_bubble.dart';
import '../plan/evolution_texts.dart';
import '../plan/plan_texts.dart';
import '../session_prefs.dart' show SessionSpace;
import '../store.dart';
import '../ui.dart';
import 'dev_flags.dart';
import 'dev_session.dart' show DevShare;

Future<void> openEngineInspector(BuildContext context) {
  if (!kDevBuild || !SessionSpace.isDev) return Future.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const EngineInspectorScreen()),
  );
}

/// Exporte le journal du moteur dynamique (JSON, menu de partage).
Future<void> shareEngineJournal(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  store.evolutionRefresh();
  final j = store.evolutionJournalJson;
  if (j == null) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Rien à exporter : il faut un profil et un programme commencé.',
        ),
      ),
    );
    return;
  }
  final r = await DevShare.shareJson(
    'kalis_adapt_journal.json',
    const JsonEncoder.withIndent(' ').convert(j),
  );
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        r == 'shared'
            ? 'Journal du moteur prêt : choisis où l’envoyer.'
            : 'Export impossible ($r).',
      ),
    ),
  );
}

const _withheldLabels = <String, String>{
  'unlock': 'pas encore débloquée',
  'confidence': 'confiance insuffisante',
  'utility': 'pas assez utile (progrès − risque − fatigue − adhésion ≤ 0)',
  'refused': 'refusée ou annulée récemment',
  'settled': 'déjà décidée',
  'recent_swap': 'un échange vient d’être fait',
  'no_change': 'le moteur statique ne change rien',
  'scope': 'déborde de sa portée',
  'plan_error': 'erreur du moteur statique',
};

String _n(Object? v, [int digits = 2]) {
  if (v is! num) return '—';
  final s = v.toStringAsFixed(digits);
  return s.replaceAll('.', ',');
}

class EngineInspectorScreen extends StatefulWidget {
  const EngineInspectorScreen({super.key});

  @override
  State<EngineInspectorScreen> createState() => _EngineInspectorScreenState();
}

class _EngineInspectorScreenState extends State<EngineInspectorScreen> {
  ({kc.SessionPlan plan, int week, int j, bool stored})? _session;
  List<kc.ExerciseEstimate> _estimates = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Séance du jour (celle du journal si elle a été prescrite), sinon la
  /// prochaine séance servie par le moteur dans les 14 jours.
  void _load() {
    store.evolutionRefresh();
    final r = store.lastEvolutionReview;
    if (r == null) {
      _error =
          'Pas de revue du moteur : il faut un profil, la base d’exercices et '
          'un programme commencé.';
      return;
    }
    try {
      _estimates = kalisAdaptEngine.estimates(store.content.catalog!, r.input);
    } catch (_) {
      _estimates = const [];
    }
    final now = store.storeClock();
    for (var d = 0; d < 14; d++) {
      final date = DateTime(now.year, now.month, now.day + d);
      if (!store.program.containsDate(date)) break;
      final w = store.program.weekFor(date), j = store.program.dayFor(date);
      final base = store.program.week(w).day(j);
      if (base == null || base.exercises.isEmpty) continue;
      final a = store.sessionAdapt(w, j);
      if (a != null && d == 0) {
        _session = (plan: a.active, week: w, j: j, stored: true);
        return;
      }
      final place = store.adaptPlaceOf(w, j);
      if (place == null) continue;
      try {
        final plan = kalisAdaptEngine.prescribeSession(
          store.content.catalog!,
          kc.SessionRequest(
            input: kc.AdaptInput(
              profile: r.input.profile,
              block: place.block,
              log: r.input.log,
              today: civilOf(date),
              decisions: r.input.decisions,
            ),
            weekIndex: place.weekIndex,
            dayIndex: place.dayIndex,
          ),
        );
        _session = (plan: plan, week: w, j: j, stored: false);
      } catch (e) {
        _error = 'Prescription impossible : $e';
      }
      return;
    }
  }

  kc.ExerciseEstimate? _estimate(String id) {
    for (final e in _estimates) {
      if (e.exerciseId == id) return e;
    }
    return null;
  }

  String _name(String id) => store.adaptExerciseName(id);

  String _reasonLine(kc.Reason r) {
    final t =
        evolutionReasonText(r, exerciseName: _name) ??
        (r.code.startsWith('plan.')
            ? reasonText(r, exerciseName: _name)
            : null);
    final params = r.params.isEmpty ? '' : ' ${jsonEncode(r.params)}';
    return '${r.code}$params${t == null ? '' : '\n→ $t'}';
  }

  Widget _kv(String k, String v, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(k, style: TextStyle(color: SL.dim)),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 5, child: Text(v)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = store.lastEvolutionReview;
    final s = r?.review.summary;
    final u = store.evolutionUnlock;
    final mono = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final session = _session;
    final children = <Widget>[];
    if (_error != null) {
      children.add(
        KCard(
          key: const ValueKey('inspector-error'),
          child: KoachSays(pose: KoachPose.oops, child: Text(_error!)),
        ),
      );
    }
    if (r != null && s != null) {
      final f = s.fatigue;
      children
        ..add(const KSection('État du moteur'))
        ..add(
          KCard(
            key: const ValueKey('inspector-state'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kv('Jour', r.input.today.iso),
                _kv(
                  'Bloc',
                  '${r.place.blockId}${r.place.imported ? ' (importé)' : ''}'
                      ' · semaine ${r.place.weekIndex + 1} (S${r.week})',
                ),
                _kv('Semaines de données', '${s.weeksObserved}'),
                _kv(
                  'Séances faites / prévues',
                  '${s.sessionsCompleted} / ${s.sessionsPlanned}',
                ),
                _kv(
                  'Déblocage',
                  '${s.unlockLevel.code} — ${kUnlockCan[s.unlockLevel]}',
                  key: const ValueKey('inspector-unlock'),
                ),
                _kv(
                  'Prochain palier',
                  u.next == null
                      ? 'aucun'
                      : '${u.next!.code} : ${u.weeksToNext} sem., '
                            '${u.blocksToNext} bloc(s)',
                ),
                _kv('Confiance globale', _n(s.confidence)),
                if (f != null) ...[
                  _kv(
                    'Forme du jour (0-1)',
                    _n(f.readiness),
                    key: const ValueKey('inspector-readiness'),
                  ),
                  _kv('Forme / fatigue', '${_n(f.fitness)} / ${_n(f.fatigue)}'),
                ],
                _kv('Temps de la revue', '${r.ms} ms'),
                for (final x in s.reasons) Text(_reasonLine(x), style: mono),
              ],
            ),
          ),
        );
    }
    if (session != null) {
      final p = session.plan;
      children
        ..add(
          KSection(
            'Séance S${session.week} · J${session.j} '
            '(${session.stored ? 'prescrite' : 'prévision'})',
          ),
        )
        ..add(
          KCard(
            key: const ValueKey('inspector-session'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _kv('Confiance de la séance', _n(p.confidence)),
                for (final x in p.reasons) Text(_reasonLine(x), style: mono),
                for (final a in p.adjustments) ...[
                  const Divider(),
                  Text(
                    'Ajustement : ${a.kind.code}'
                    '${a.exerciseId == null ? '' : ' · ${_name(a.exerciseId!)}'}'
                    '${a.loadFactor == null ? '' : ' · charge × ${_n(a.loadFactor)}'}'
                    '${a.setsDelta == null ? '' : ' · séries ${a.setsDelta! > 0 ? '+' : ''}${a.setsDelta}'}',
                  ),
                  for (final x in a.reasons) Text(_reasonLine(x), style: mono),
                ],
              ],
            ),
          ),
        );
      for (final it in p.items) {
        final e = _estimate(it.exerciseId);
        children.add(
          KCard(
            key: ValueKey('inspector-item-${it.slotId}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _name(it.exerciseId),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                _kv('Prescription', prescriptionLabel(it)),
                _kv(
                  'Charge',
                  it.startLoadKg == null
                      ? (it.percentOfOneRm == null
                            ? '—'
                            : '${(it.percentOfOneRm! * 100).round()} % du 1RM')
                      : adaptKg(it.startLoadKg!),
                ),
                _kv('Flammes visées', inspectorFlames(it.targetFlames)),
                _kv(
                  'Capacité estimée',
                  e == null
                      ? 'non modélisé ou sans donnée'
                      : '${capacityText(e)} ± ${_n(e.standardError, 1)} '
                            '(${e.observations} séries, tendance '
                            '${_n(e.weeklyTrend, 2)}/sem.)',
                ),
                if (it.toCalibrate) _kv('Calibrage', 'oui'),
                for (final x in it.reasons) Text(_reasonLine(x), style: mono),
              ],
            ),
          ),
        );
      }
    }
    if (r != null) {
      final props = [
        for (final l in r.review.log)
          if (l.event == 'proposal' || l.event == 'proposal_withheld') l,
      ];
      children.add(KSection('Propositions de la revue (${props.length})'));
      if (props.isEmpty) {
        children.add(
          const Text(
            'Aucune proposition étudiée à ce niveau de déblocage et avec ces '
            'données.',
          ),
        );
      }
      for (final l in props) {
        final d = l.data;
        final w = d['withheld'];
        children.add(
          KCard(
            key: ValueKey('inspector-proposal-${d['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${d['kind']} · ${w == null ? 'retenue' : 'écartée : ${_withheldLabels[w] ?? w}'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                _kv('Identifiant', '${d['id']}'),
                _kv(
                  'Confiance / seuil',
                  '${_n(l.confidence)} / ${_n(d['threshold'])}',
                ),
                _kv(
                  'Utilité',
                  '${_n(d['utility'], 3)} = progrès ${_n(d['progress'], 3)} − '
                      'risque ${_n(d['risk'], 3)} − fatigue '
                      '${_n(d['fatigue'], 3)} − adhésion ${_n(d['adherence'], 3)}',
                ),
                for (final x in l.reasons) Text(_reasonLine(x), style: mono),
              ],
            ),
          ),
        );
      }
      if (_estimates.isNotEmpty) {
        children.add(
          KSection('Capacités estimées (${_estimates.length} exercices)'),
        );
        for (final e in _estimates) {
          children.add(
            _kv(
              _name(e.exerciseId),
              '${capacityText(e)} ± ${_n(e.standardError, 1)} · '
              '${e.observations} séries',
            ),
          );
        }
      }
    }
    return KScreen(
      appBar: AppBar(
        title: const Text('INSPECTEUR · MOTEUR DYNAMIQUE'),
        actions: [
          IconButton(
            key: const ValueKey('inspector-export'),
            tooltip: 'Exporter le journal du moteur (JSON)',
            icon: const Icon(Icons.ios_share),
            onPressed: () => shareEngineJournal(context),
          ),
        ],
      ),
      body: KList(key: const ValueKey('inspector-list'), children: children),
    );
  }
}
