import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'ui.dart';
import 'store.dart';

class PilotageScreen extends StatelessWidget {
  const PilotageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = store.program.pilotage;
    return KScreen(
      appBar: AppBar(
        title: const Text('RÉFÉRENCES'),
        actions: [
          IconButton(
            tooltip: 'Rétablir les références initiales',
            icon: const Icon(Icons.restore),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        backgroundColor: SL.surface,
                        title: const Text('Rétablir les défauts ?'),
                        content: const Text(
                          'Les références de départ du programme seront restaurées. Tes séances enregistrées sont conservées.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () {
                              store.resetPilotage();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Rétablir'),
                          ),
                        ],
                      ),
                ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder:
            (context, _) => KList(
              children: [
                KCard(
                  child: Text(
                    'Tes références ajustent le programme. Enregistrement automatique.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const _NumTile(
                  label: 'Poids de corps',
                  refCell: 'B4',
                  unit: 'kg',
                  subtitle: 'Utilisé avec ton lest pour calculer les charges',
                ),
                const _SectionTitle('Force · 1RM de travail'),
                for (final l in p.mainLifts)
                  _NumTile(
                    label: l.name,
                    refCell: l.ref,
                    unit: l.unit,
                    subtitle: 'Cible 12 mois : ${_n(l.target)} ${l.unit}',
                  ),
                const _SectionTitle('Endurance · répétitions'),
                for (final m in p.repMax)
                  _NumTile(
                    label: m.name,
                    refCell: m.ref,
                    unit: 'reps',
                    subtitle:
                        'Cible 12 mois : ${_n(m.target)} reps · ajuste les jours 4 à 6',
                  ),
                const _SectionTitle('Charges des accessoires'),
                for (final a in p.accessories)
                  _NumTile(
                    label: a.name,
                    refCell: a.ref,
                    unit: 'kg',
                    subtitle:
                        'Réf. ${a.refReps} reps · ${a.note.isEmpty ? 'double progression' : a.note}',
                  ),
              ],
            ),
      ),
    );
  }
}

String _n(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class _SectionTitle extends StatelessWidget {
  final String t;
  const _SectionTitle(this.t);
  @override
  Widget build(BuildContext context) => KSection(t);
}

class _NumTile extends StatelessWidget {
  final String label;
  final String refCell;
  final String unit;
  final String subtitle;
  const _NumTile({
    required this.label,
    required this.refCell,
    required this.unit,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final v = store.values[refCell] ?? 0;
    final labelContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    final field = TextFormField(
      key: ValueKey('$refCell-${store.pilotageEpoch}'),
      initialValue: _n(v),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      style: KControl.numberStyle,
      decoration: logDeco(suffix: unit.startsWith('kg') ? 'kg' : unit).copyWith(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (t) {
        final d = double.tryParse(t.replaceAll(',', '.'));
        if (d != null) store.setValue(refCell, d);
      },
    );
    return KCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 16;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [labelContent, const SizedBox(height: 6), field],
            );
          }
          return Row(
            children: [
              Expanded(child: labelContent),
              const SizedBox(width: 12),
              SizedBox(width: 110, child: field),
            ],
          );
        },
      ),
    );
  }
}
