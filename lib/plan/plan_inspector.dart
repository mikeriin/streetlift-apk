// G7 (D2.5) : inspecteur du moteur statique (session de test seulement).
//
// Pour chaque proposition : note totale et détail des composantes. Pour
// le programme montré : ce que le moteur retient du profil (niveaux,
// prudence, dosage, vivier), contraintes dures revérifiées, et pour chaque
// exercice sa contribution à la note (note sans lui), ses contraintes
// (rôle, verrou, difficulté) et ses raisons (codes et texte). Rien n'est
// modifié ; export du journal du moteur en JSON.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart'
    show PlanInspector, kalisPlanVersion;

import '../app_theme.dart';
import '../dev/dev_session.dart' show DevShare;
import '../store.dart';
import '../ui.dart';
import 'plan_creation.dart';
import 'plan_sheets.dart' show planName, planReason;
import 'plan_texts.dart';

class PlanInspectorScreen extends StatefulWidget {
  /// Création en cours (propositions, journal) ; sinon [plan] et [request]
  /// (programme en place).
  final PlanCreation? creation;
  final kc.Pass1Plan? plan;
  final kc.PlanRequest? request;
  final String? journal;
  const PlanInspectorScreen({
    super.key,
    this.creation,
    this.plan,
    this.request,
    this.journal,
  });

  @override
  State<PlanInspectorScreen> createState() => _PlanInspectorScreenState();
}

class _PlanInspectorScreenState extends State<PlanInspectorScreen> {
  final Map<String, double> _contribution = {};

  kc.Pass1Plan get _plan => widget.creation?.plan ?? widget.plan!;
  kc.PlanRequest get _request => widget.creation?.request() ?? widget.request!;
  kc.Catalog? get _catalog => widget.creation?.catalog ?? _storeCatalog;
  kc.Catalog? get _storeCatalog => store.content.catalog;

  String _num(double v) => v.toStringAsFixed(3).replaceAll('.', ',');

  void _contributionOf(PlanInspector ins, kc.PlanSlot slot) {
    final plan = _plan;
    final without = plan.copyWith(
      days: [
        for (final d in plan.days)
          d.copyWith(
            slots: [
              for (final s in d.slots)
                if (s.slotId != slot.slotId) s,
            ],
          ),
      ],
    );
    try {
      final a = ins.scoreOf(_request, plan).total;
      final b = ins.scoreOf(_request, without).total;
      setState(() => _contribution[slot.slotId] = a - b);
    } catch (_) {
      setState(() => _contribution[slot.slotId] = double.nan);
    }
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final text =
        widget.journal ??
        jsonEncode(
          widget.creation?.journalJson(engineVersion: kalisPlanVersion) ??
              {'kind': 'kalis_plan_journal', 'v': 1, 'entries': const []},
        );
    final r = await DevShare.shareJson('kalis_plan_journal.json', text);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          r == 'shared'
              ? 'Journal du moteur prêt : choisis où l’envoyer.'
              : 'Export impossible ($r).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    if (catalog == null) {
      return const KScreen(body: Center(child: Text('Base non chargée.')));
    }
    final ins = PlanInspector(catalog);
    final plan = _plan;
    final dim = Theme.of(context).textTheme.bodySmall;
    Map<String, Object?> profile;
    List<String> violations;
    try {
      profile = ins.explainProfile(_request);
      violations = ins.hardViolations(_request, plan);
    } catch (e) {
      profile = {'erreur': '$e'};
      violations = const [];
    }
    final proposals = widget.creation?.proposals ?? [plan];
    return KScreen(
      appBar: AppBar(
        title: const Text('INSPECTEUR DU MOTEUR'),
        actions: [
          IconButton(
            key: const ValueKey('inspector-export'),
            tooltip: 'Exporter le journal du moteur (JSON)',
            icon: const Icon(Icons.ios_share),
            onPressed: _export,
          ),
        ],
      ),
      body: KList(
        key: const ValueKey('plan-inspector-list'),
        children: [
          Text(
            'kalis_plan $kalisPlanVersion · base ${catalog.sourceVersion} · '
            'graine ${plan.seed} · ${widget.creation?.lastMs ?? 0} ms (dernier appel)',
            style: dim,
          ),
          const KSection('Propositions'),
          for (var i = 0; i < proposals.length; i++)
            KCard(
              key: ValueKey('inspector-proposal-$i'),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Proposition ${i + 1} · note ${_num(proposals[i].score.total)}',
                ),
                subtitle: Text(
                  i == (widget.creation?.index ?? 0) ? 'montrée' : '',
                  style: dim,
                ),
                children: [
                  for (final c in proposals[i].score.components)
                    Row(
                      children: [
                        Expanded(child: Text(kScoreLabels[c.code] ?? c.code)),
                        Text(
                          '${_num(c.value)} × ${_num(c.weight)}',
                          style: dim,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const KSection('Ce que le moteur retient du profil'),
          KCard(
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(profile),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          KSection(
            'Contraintes dures (${violations.length} violation${violations.length > 1 ? 's' : ''})',
          ),
          KCard(
            child: Text(
              violations.isEmpty
                  ? 'Aucune contrainte dure violée.'
                  : violations.join('\n'),
              style: TextStyle(
                color: violations.isEmpty ? SL.success : SL.danger,
              ),
            ),
          ),
          const KSection('Exercices'),
          for (final d in plan.days)
            for (final s in d.slots)
              KCard(
                key: ValueKey('inspector-slot-${s.slotId}'),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(planName(s.exerciseId)),
                  subtitle: Text(
                    '${s.slotId} · ${weekdayLabel(d.weekday)} · ${s.role.code}'
                    '${s.locked ? ' · verrouillé' : ''} · difficulté '
                    '${catalog.find(s.exerciseId)?.difficulty ?? '?'}',
                    style: dim,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _contribution.containsKey(s.slotId)
                          ? Text(
                              'Contribution à la note : '
                              '${_num(_contribution[s.slotId]!)}',
                            )
                          : TextButton(
                              onPressed: () => _contributionOf(ins, s),
                              child: const Text('Calculer sa contribution'),
                            ),
                    ),
                    for (final r in s.reasons)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${r.code} ${jsonEncode(r.params)}\n${planReason(r)}',
                            style: dim,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          const KSection('Pourquoi pas un exercice de plus ?'),
          KCard(
            child: Builder(
              builder: (context) {
                List<String> lines;
                try {
                  lines = ins.whatIfAdd(_request, plan);
                } catch (e) {
                  lines = ['$e'];
                }
                return SelectableText(
                  lines.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
