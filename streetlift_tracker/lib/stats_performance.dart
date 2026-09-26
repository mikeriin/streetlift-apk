import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'koach_screens.dart';
import 'muscle_body.dart';
import 'pilotage_screen.dart';
import 'store.dart';
import 'ui.dart';
import 'stats_data.dart';
import 'stats_history.dart';
import 'stats_widgets.dart';

class StatsPerformance extends StatelessWidget {
  const StatsPerformance({super.key});
  @override
  Widget build(BuildContext context) {
    final defaults = store.program.pilotage;
    final muscles = store.weeklyMuscles();
    final total = store.program.weeks.fold<int>(
      0,
      (n, week) => n + week.days.length,
    );
    final records =
        store.wods.where((w) => w.best() != null).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return KList(
      key: const PageStorageKey('stats-performance-scroll'),
      children: [
        const SizedBox(height: 4),
        Text(
          'Des repères pour avancer',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        KMenuTile(
          icon: Icons.tune_rounded,
          title: 'Modifier mes références',
          subtitle: 'Poids de corps, force, répétitions et charges',
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PilotageScreen()),
              ),
        ),
        // Koach (L7, D30) : visible seulement Koach actif.
        if (store.koachOn)
          KMenuTile(
            key: const ValueKey('stats-koach'),
            icon: Icons.insights_rounded,
            title: 'Koach',
            subtitle: 'Estimations, objectifs, propositions et historique',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KoachScreen()),
                ),
          ),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programme · ${store.completedCount} / $total journées',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              StatsBar(
                value: total == 0 ? 0 : store.completedCount / total,
                label: 'Journées du programme validées',
                description: '${store.completedCount} sur $total',
              ),
              const SizedBox(height: 7),
              Text(
                'Les journées de récupération validées sont incluses.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const KSection(
          'Force',
          subtitle: 'Références actuelles · cibles à 12 mois',
        ),
        Text(
          'La jauge mesure le chemin depuis la référence de départ vers la cible.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        for (final lift in defaults.mainLifts)
          if (store.refKnown(lift.ref))
            _Target(
              name: lift.name,
              unit: lift.unit,
              start: lift.oneRm,
              target: lift.target,
              current: store.values[lift.ref]!,
            )
          else
            _Unknown(lift.name),
        const KSection(
          'Endurance',
          subtitle: 'Maximum de répétitions au poids de corps',
        ),
        for (final rep in defaults.repMax)
          if (store.refKnown(rep.ref))
            _Target(
              name: rep.name,
              unit: 'rép.',
              start: rep.max,
              target: rep.target,
              current: store.values[rep.ref]!,
            )
          else
            _Unknown(rep.name),
        const KSection(
          'Muscles sollicités',
          subtitle: 'Cette semaine · séries et WOD enregistrés',
        ),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MuscleHeatmap(data: muscles, height: 220),
              const SizedBox(height: 12),
              if (muscles.values.every((value) => value <= 0))
                Text(
                  'Valide tes séries pour voir ta répartition musculaire.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                MuscleLegend(data: muscles),
            ],
          ),
        ),
        const KSection(
          'Tes records WOD',
          subtitle: 'Meilleurs résultats terminés, selon le format',
        ),
        if (records.isEmpty)
          const KEmpty(
            icon: Icons.emoji_events_outlined,
            title: 'Ton premier record t’attend',
            message:
                'Enregistre un résultat WOD terminé pour retrouver ici ta référence.',
          ),
        for (final wod in records)
          StatsHistoryTile(
            StatsHistoryEntry(
              id: 'best-${wod.id}',
              title: wod.name,
              searchText: wod.name.toLowerCase(),
              at: DateTime.tryParse(wod.best()!.at)?.toLocal(),
              wod: wod,
              result: wod.best(),
            ),
            record: true,
          ),
      ],
    );
  }
}

/// Référence non renseignée (KT-007) : pas de jauge calculée sur une valeur
/// inventée.
class _Unknown extends StatelessWidget {
  final String name;
  const _Unknown(this.name);
  @override
  Widget build(BuildContext context) => KCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Non renseigné · à compléter dans Références quand tu le connais.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _Target extends StatelessWidget {
  final String name, unit;
  final double current, start, target;
  const _Target({
    required this.name,
    required this.unit,
    required this.current,
    required this.start,
    required this.target,
  });
  @override
  Widget build(BuildContext context) {
    final span = target - start;
    final reached = current >= target;
    final fraction =
        span <= 0
            ? (reached ? 1.0 : 0.0)
            : ((current - start) / span).clamp(0.0, 1.0);
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              KBadge(
                '${statsNumber(current)} $unit',
                color: reached ? SL.success : SL.accent,
              ),
              KBadge(
                'Cible ${statsNumber(target)} $unit',
                icon:
                    reached ? Icons.check_circle_outline : Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatsBar(
            value: fraction,
            label: name,
            description:
                '${statsNumber(current)} $unit, cible ${statsNumber(target)} $unit',
            color: reached ? SL.success : null,
          ),
          const SizedBox(height: 7),
          Text(
            reached ? 'Cible atteinte' : 'Départ : ${statsNumber(start)} $unit',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
