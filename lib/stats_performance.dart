import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'muscle_body.dart';
import 'pilotage_screen.dart';
import 'store.dart';
import 'ui.dart';
import 'stats_mannequin.dart';
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
    return KList(
      key: const PageStorageKey('stats-performance-scroll'),
      children: [
        const SizedBox(height: 4),
        KWordFitText(
          'Des repères pour avancer',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        KMenuTile(
          icon: Icons.tune_rounded,
          title: 'Modifier mes références',
          subtitle: 'Poids de corps, force, répétitions et charges',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PilotageScreen()),
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
          subtitle: 'Cette semaine · séries validées',
        ),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // M8 : carte 2D des groupes de la semaine (face, dos,
              // profil), fond de la carte.
              TargetedMuscleMap(
                key: const ValueKey('stats-muscle-map'),
                names: store.weeklyNames(),
                groups: muscles,
                height: 230,
                subject: 'muscles de la semaine',
              ),
              const SizedBox(height: 12),
              if (muscles.values.every((value) => value <= 0))
                Text(
                  'Valide tes séries pour voir ta répartition musculaire.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else ...[
                MuscleLegend(data: muscles, values: true),
                const SizedBox(height: 8),
                Text(
                  'Séries validées cette semaine, pondérées : 1 pour le '
                  'groupe principal de l’exercice, 0,6 pour les autres.',
                  key: const ValueKey('stats-muscles-unite'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
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
    final fraction = span <= 0
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
                icon: reached
                    ? Icons.check_circle_outline
                    : Icons.flag_outlined,
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
