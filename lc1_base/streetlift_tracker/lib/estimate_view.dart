import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'training_estimate.dart';

void showEstimate(
  BuildContext context,
  String title,
  TrainingEstimate estimate, {
  Widget? overview,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          maxChildSize: .94,
          minChildSize: .35,
          builder:
              (context, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  if (overview != null) ...[
                    overview,
                    const SizedBox(height: 14),
                  ],
                  EstimateView(estimate: estimate),
                  if (estimate.details.isNotEmpty) ...[
                    const Divider(height: 26),
                    const Text(
                      'DÉTAIL DU VOLUME PRÉVU',
                      style: TextStyle(fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    for (final item in estimate.details)
                      InkWell(
                        onTap:
                            () => showEstimate(
                              context,
                              item.title,
                              item.estimate,
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.estimate.volumeLabel} · ${item.estimate.durationLabel}',
                                style: TextStyle(color: SL.dim, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
        ),
  );
}

class EstimateView extends StatelessWidget {
  final TrainingEstimate estimate;
  const EstimateView({super.key, required this.estimate});
  @override
  Widget build(BuildContext context) {
    final e = estimate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _metric(
              e.durationLabel,
              e.observed != null
                  ? 'Selon tes résultats'
                  : e.clock == null
                  ? 'Temps estimé'
                  : 'Durée prévue',
            ),
            if (e.sets > 0)
              _metric(
                '${e.projected ? '≈ ' : ''}${e.sets.round()}',
                'Séries / passages',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          e.volumeLabel,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        if (e.hasTonnage)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              '${e.tonnage.label} kg·rép. externes connus',
              style: TextStyle(color: SL.dim, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        if (e.observed != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Détail théorique ci-dessous. Le temps total est ajusté avec tes ${e.historyCount} derniers résultats complets, à prescription identique.',
              style: TextStyle(color: SL.dim, fontSize: 12),
            ),
          ),
        for (final row in [
          ('Effort', e.work),
          ('Repos', e.rest),
          ('Transitions', e.transitions),
        ])
          if (row.$2.high > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.$1, style: TextStyle(color: SL.dim)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _spanTime(row.$2),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        if (e.capSeconds > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Limite du chrono : ${TrainingEstimate.formatSeconds(e.capSeconds.toDouble())}. Le volume indiqué reste celui du WOD complet.',
              style: TextStyle(color: SL.accent, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Volume prévu. Cadence estimée quand aucun tempo n’est précisé. Le tonnage compte uniquement les charges externes connues, sans le poids du corps.',
          style: TextStyle(color: SL.dim, fontSize: 12, height: 1.4),
        ),
        for (final note in e.notes.toSet())
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              note,
              style: TextStyle(color: SL.dim, fontSize: 12, height: 1.4),
            ),
          ),
        if (e.partial)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Estimation partielle : certains éléments restent à préciser.',
              style: TextStyle(color: SL.accent, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _metric(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      ),
      Text(label, style: TextStyle(color: SL.dim, fontSize: 11.5)),
    ],
  );
  String _spanTime(Span s) =>
      s.low.round() == s.high.round()
          ? TrainingEstimate.formatSeconds(s.low)
          : '${TrainingEstimate.formatSeconds(s.low)} – ${TrainingEstimate.formatSeconds(s.high)}';
}
