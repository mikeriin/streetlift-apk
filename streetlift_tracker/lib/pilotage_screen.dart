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
            tooltip: 'Effacer toutes mes références',
            icon: const Icon(Icons.restore),
            onPressed:
                () => showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        backgroundColor: SL.surface,
                        title: const Text('Effacer tes références ?'),
                        content: const Text(
                          'Toutes tes références repassent à « non renseigné » : les charges et volumes qui en dépendent afficheront « à renseigner ». Tes séances, ton historique et tes récompenses sont conservés.',
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
                            child: const Text('Effacer'),
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
                    'Tes références ajustent le programme. Enregistrement automatique. '
                    'Laisse une valeur « non renseignée » si tu ne la connais pas : '
                    'les charges et volumes liés l’indiqueront, sans rien inventer. '
                    'Lest = charge ajoutée au poids du corps ; back squat = barre totale.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (store.referenceRefs.any(
                  (r) => store.refProvenance(r) == 'historic',
                ))
                  KCard(
                    key: const ValueKey('references-historic'),
                    child: Text(
                      'Valeurs marquées « à vérifier » : elles viennent d’une version précédente '
                      'et restent utilisées telles quelles. Confirme-les ou corrige-les quand tu veux.',
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

/// Affichage d'une référence avec virgule décimale (« 72,5 »).
String formatReference(double v) => _n(v);

String _n(double v) =>
    v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toString().replaceAll('.', ',');

/// Saisie d'une référence : virgule ou point, deux décimales au plus,
/// 0 à 10 000 (poids du corps > 0). Vide, texte, valeur non finie : null.
double? parseReference(String? text, String ref) {
  final t = (text ?? '').trim();
  if (!RegExp(r'^\d{1,5}(?:[.,]\d{1,2})?$').hasMatch(t)) return null;
  final v = double.parse(t.replaceAll(',', '.'));
  if (!v.isFinite || v > 10000 || (ref == 'B4' && v == 0)) return null;
  return v;
}

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
    final provenance = store.refProvenance(refCell);
    final v = store.values[refCell];
    final labelContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        if (provenance != 'set') ...[
          const SizedBox(height: 4),
          Text(
            provenance == 'unknown'
                ? 'Non renseigné'
                : 'À vérifier · valeur d’une version précédente',
            key: ValueKey('$refCell-provenance'),
            style: TextStyle(
              color: SL.danger,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
        Wrap(
          spacing: 4,
          children: [
            if (provenance == 'historic')
              TextButton(
                key: ValueKey('$refCell-confirm'),
                onPressed: () => store.confirmReference(refCell),
                child: const Text('C’est bien ma valeur'),
              ),
            if (provenance != 'unknown')
              TextButton(
                key: ValueKey('$refCell-unknown'),
                onPressed: () => store.clearReference(refCell),
                child: const Text('Je ne sais pas'),
              ),
          ],
        ),
      ],
    );
    final field = TextFormField(
      key: ValueKey('$refCell-${store.pilotageEpoch}'),
      initialValue: v == null ? '' : _n(v),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      style: KControl.numberStyle,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator:
          (t) =>
              (t ?? '').trim().isEmpty || parseReference(t, refCell) != null
                  ? null
                  : 'Nombre (ex. 72,5)',
      // L5 : le nom de la référence est à côté du champ ; dans le champ, il
      // était tronqué (« Poids de cor… ») et masquait « — ». TalkBack le lit
      // toujours par la sémantique ci-dessous.
      decoration: logDeco(
        hint: '—',
        suffix: unit.startsWith('kg') ? 'kg' : unit,
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      onChanged: (t) {
        final d = parseReference(t, refCell);
        if (d != null) store.setValue(refCell, d);
      },
    );
    final labelledField = Semantics(label: label, child: field);
    return KCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 16;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelContent,
                const SizedBox(height: 6),
                labelledField,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: labelContent),
              const SizedBox(width: 12),
              SizedBox(width: 110, child: labelledField),
            ],
          );
        },
      ),
    );
  }
}
