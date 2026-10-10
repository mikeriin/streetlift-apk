// UI2 (refonte UI) : estimation de durée et de volume aux jetons du kit ;
// la feuille passe par la feuille de contenu de la zone (poignée, titre,
// contenu, « Fermer »), le détail du volume en titre de section (C6) et en
// groupe de lignes qui rouvrent chacune son estimation. Calculs et textes
// inchangés.
import 'package:flutter/material.dart';

import 'adapt/widgets/session_kit.dart' show showKContentSheet;
import 'kit/kit.dart';
import 'training_estimate.dart';

void showEstimate(
  BuildContext context,
  String title,
  TrainingEstimate estimate, {
  Widget? overview,
}) {
  showKContentSheet<void>(
    context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview != null) ...[
          overview,
          const SizedBox(height: KSpacing.s14),
        ],
        EstimateView(estimate: estimate),
        if (estimate.details.isNotEmpty) ...[
          const SizedBox(height: KSpacing.s8),
          const KSectionTitle('Détail du volume prévu'),
          _DetailGroup(
            details: estimate.details,
            onOpen: (item) => showEstimate(context, item.title, item.estimate),
          ),
        ],
      ],
    ),
  );
}

/// Élément du détail du volume ([TrainingEstimate.details]).
typedef _Detail = ({String title, TrainingEstimate estimate});

/// Lignes du détail du volume (groupe `haute`, rayon des menus) : chacune
/// rouvre l'estimation de son élément.
class _DetailGroup extends StatelessWidget {
  final List<_Detail> details;
  final ValueChanged<_Detail> onOpen;
  const _DetailGroup({required this.details, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Material(
      color: k.haute,
      shape: KRadius.menuShape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < details.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: KSpacing.s16,
                endIndent: KSpacing.s16,
                color: k.filet,
              ),
            InkWell(
              onTap: () => onOpen(details[i]),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: KSize.target),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KSpacing.s16,
                    vertical: KSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details[i].title,
                              style: KType.libelle.copyWith(color: k.texte),
                            ),
                            const SizedBox(height: KSpacing.s4),
                            Text(
                              '${details[i].estimate.volumeLabel} · ${details[i].estimate.durationLabel}',
                              style: KType.detail.copyWith(color: k.texte2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KSpacing.s8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: KSize.chevron,
                        color: k.texte2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EstimateView extends StatelessWidget {
  final TrainingEstimate estimate;
  const EstimateView({super.key, required this.estimate});
  @override
  Widget build(BuildContext context) {
    final e = estimate;
    final k = KTokens.of(context);
    final note = KType.detail.copyWith(color: k.texte2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: KSpacing.s24,
          runSpacing: KSpacing.s12,
          children: [
            _metric(
              k,
              e.durationLabel,
              e.clock == null ? 'Temps estimé' : 'Durée prévue',
            ),
            if (e.sets > 0)
              _metric(
                k,
                '${e.projected ? '≈ ' : ''}${e.sets.round()}',
                'Séries / passages',
              ),
          ],
        ),
        const SizedBox(height: KSpacing.s12),
        Text(e.volumeLabel, style: KType.corpsMoyen.copyWith(color: k.texte)),
        if (e.hasTonnage)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s4),
            child: Text(
              '${e.tonnage.label} kg·rép. externes connus',
              style: note,
            ),
          ),
        const SizedBox(height: KSpacing.s12),
        for (final row in [
          ('Effort', e.work),
          ('Repos', e.rest),
          ('Transitions', e.transitions),
        ])
          if (row.$2.high > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: KType.corps.copyWith(color: k.texte2),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _spanTime(row.$2),
                      textAlign: TextAlign.end,
                      style: KType.corps.copyWith(
                        color: k.texte,
                        fontFeatures: KFont.tabular,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: KSpacing.s12),
        Text(
          'Volume prévu. Cadence estimée quand aucun tempo n’est précisé. Le tonnage compte uniquement les charges externes connues, sans le poids du corps.',
          style: note,
        ),
        for (final line in e.notes.toSet())
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s4),
            child: Text(line, style: note),
          ),
        if (e.partial)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s8),
            child: Text(
              'Estimation partielle : certains éléments restent à préciser.',
              style: KType.detail.copyWith(color: k.avertissement),
            ),
          ),
      ],
    );
  }

  Widget _metric(KTokens k, String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: KType.chiffreMoyen.copyWith(color: k.texte)),
      Text(label, style: KType.detail.copyWith(color: k.texte2)),
    ],
  );
  String _spanTime(Span s) => s.low.round() == s.high.round()
      ? TrainingEstimate.formatSeconds(s.low)
      : '${TrainingEstimate.formatSeconds(s.low)} – ${TrainingEstimate.formatSeconds(s.high)}';
}
