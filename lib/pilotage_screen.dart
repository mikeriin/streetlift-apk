// UI4 (refonte UI) : page « Mes références » (cahier §4.1, R3, R9 : plus de
// « Pilotage » visible), ouverte depuis Profil › « Mes références » et les
// raccourcis R2. Sous-page de menu : champs groupés par section ; l'action
// destructrice « Effacer toutes mes références » est une ligne visible du
// dernier groupe, confirmée (C10, R8).
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'store.dart';
import 'ui.dart';

class PilotageScreen extends StatelessWidget {
  const PilotageScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showKConfirm(
      context,
      title: 'Effacer tes références ?',
      message:
          'Toutes tes références repassent à « non renseigné » : les charges '
          'et volumes qui en dépendent afficheront « à renseigner ». Tes '
          'séances, ton historique et tes récompenses sont conservés.',
      confirmLabel: 'Effacer',
      destructive: true,
    );
    if (ok) store.resetPilotage();
  }

  @override
  Widget build(BuildContext context) {
    final p = store.program.pilotage;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => KPage.sub(
        key: const ValueKey('references-screen'),
        title: 'Mes références',
        lead:
            'Tes références ajustent le programme. Enregistrement '
            'automatique. Laisse une valeur « non renseignée » si tu ne la '
            'connais pas : les charges et volumes liés l’indiqueront, sans '
            'rien inventer. Lest = charge ajoutée au poids du corps ; back '
            'squat = barre totale.',
        children: [
          if (store.referenceRefs.any(
            (r) => store.refProvenance(r) == 'historic',
          ))
            const KNotice(
              key: ValueKey('references-historic'),
              icon: Icons.history_rounded,
              tone: KTone.warning,
              message:
                  'Valeurs marquées « à vérifier » : elles viennent d’une '
                  'version précédente et restent utilisées telles quelles. '
                  'Confirme-les ou corrige-les quand tu veux.',
            ),
          const KMenuGroup(
            title: 'Poids du corps',
            dividerIndent: KSpacing.s16,
            children: [
              _NumTile(
                label: 'Poids de corps',
                refCell: 'B4',
                unit: 'kg',
                subtitle: 'Utilisé avec ton lest pour calculer les charges',
              ),
            ],
          ),
          KMenuGroup(
            title: 'Force · 1RM de travail',
            dividerIndent: KSpacing.s16,
            children: [
              for (final l in p.mainLifts)
                _NumTile(
                  label: l.name,
                  refCell: l.ref,
                  unit: l.unit,
                  subtitle: 'Cible 12 mois : ${_n(l.target)} ${l.unit}',
                ),
            ],
          ),
          KMenuGroup(
            title: 'Endurance · répétitions',
            dividerIndent: KSpacing.s16,
            children: [
              for (final m in p.repMax)
                _NumTile(
                  label: m.name,
                  refCell: m.ref,
                  unit: 'reps',
                  subtitle:
                      'Cible 12 mois : ${_n(m.target)} reps · ajuste les '
                      'jours 4 à 6',
                ),
            ],
          ),
          KMenuGroup(
            title: 'Charges des accessoires',
            dividerIndent: KSpacing.s16,
            children: [
              for (final a in p.accessories)
                _NumTile(
                  label: a.name,
                  refCell: a.ref,
                  unit: 'kg',
                  subtitle:
                      'Réf. ${a.refReps} reps · '
                      '${a.note.isEmpty ? 'double progression' : a.note}',
                ),
            ],
          ),
          // C10 : action destructrice dans le dernier groupe, confirmée.
          KMenuGroup(
            children: [
              KMenuRow(
                key: const ValueKey('references-reset'),
                icon: Icons.restore_rounded,
                title: 'Effacer toutes mes références',
                subtitle: 'Elles repassent à « non renseigné »',
                danger: true,
                chevron: false,
                onTap: () => _confirmReset(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Affichage d'une référence avec virgule décimale (« 72,5 »).
String formatReference(double v) => _n(v);

String _n(double v) => v == v.roundToDouble()
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

/// Une référence : nom, description, provenance, actions, champ.
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

  /// Largeur du champ à côté du libellé.
  static const _fieldWidth = 2 * KSize.target + KSpacing.s14;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final provenance = store.refProvenance(refCell);
    final v = store.values[refCell];
    final labelContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KRowLabel(label, subtitle: subtitle),
        if (provenance != 'set') ...[
          const SizedBox(height: KSpacing.s4),
          Text(
            provenance == 'unknown'
                ? 'Non renseigné'
                : 'À vérifier · valeur d’une version précédente',
            key: ValueKey('$refCell-provenance'),
            style: KType.micro.copyWith(color: k.danger),
          ),
        ],
        Wrap(
          spacing: KSpacing.s4,
          children: [
            if (provenance == 'historic')
              KTonalButton(
                key: ValueKey('$refCell-confirm'),
                label: 'C’est bien ma valeur',
                onPressed: () => store.confirmReference(refCell),
              ),
            if (provenance != 'unknown')
              KTonalButton(
                key: ValueKey('$refCell-unknown'),
                label: 'Je ne sais pas',
                onPressed: () => store.clearReference(refCell),
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
      validator: (t) =>
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s16,
        vertical: KSpacing.s12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < KSize.stepperRowMin ||
              MediaQuery.textScalerOf(
                    context,
                  ).scale(KType.libelle.fontSize!) >
                  KType.corpsFort.fontSize!;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelContent,
                const SizedBox(height: KSpacing.s8),
                labelledField,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: labelContent),
              const SizedBox(width: KSpacing.s12),
              SizedBox(width: _fieldWidth, child: labelledField),
            ],
          );
        },
      ),
    );
  }
}
