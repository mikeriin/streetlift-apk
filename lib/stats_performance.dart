import 'package:flutter/material.dart';
import 'kit/kit.dart';
import 'muscle_body.dart';
import 'pilotage_screen.dart';
import 'records_screen.dart';
import 'store.dart';
import 'stats_mannequin.dart';
import 'stats_widgets.dart';

/// Performances (UI3, cahier §4.1) : « Mes références » (raccourci R2, même
/// page que Réglages › Profil) et « Records » en tête, puis le programme, la
/// force, l'endurance et les muscles de la semaine.
class StatsPerformance extends StatelessWidget {
  const StatsPerformance({super.key});

  static void openReferences(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PilotageScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final defaults = store.program.pilotage;
    final muscles = store.weeklyMuscles();
    final total = store.program.weeks.fold<int>(
      0,
      (n, week) => n + week.days.length,
    );
    final records = statsRecords(store);
    final unknownLifts = defaults.mainLifts.any((l) => !store.refKnown(l.ref));
    final unknownReps = defaults.repMax.any((r) => !store.refKnown(r.ref));
    Widget fillIn() => KNotice(
      message: 'Renseigne-les quand tu les connais : les jauges partent de ces valeurs.',
      actionLabel: 'Mes références',
      onAction: () => openReferences(context),
    );
    return StatsList(
      key: const PageStorageKey('stats-performance-scroll'),
      children: [
        const StatsIntro('Des repères pour avancer'),
        KMenuGroup(
          children: [
            KMenuRow(
              key: const ValueKey('stats-references'),
              icon: Icons.tune_rounded,
              title: 'Mes références',
              subtitle: 'Poids de corps, force, répétitions et charges',
              onTap: () => openReferences(context),
            ),
            KMenuRow(
              key: const ValueKey('stats-records'),
              icon: Icons.emoji_events_outlined,
              title: 'Records',
              subtitle: records.isEmpty
                  ? 'Tes meilleures séries, exercice par exercice'
                  : '${records.length} exercice${records.length > 1 ? 's' : ''} · meilleure charge et meilleures répétitions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecordsScreen()),
              ),
            ),
          ],
        ),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Programme · ${store.completedCount} / $total journées',
                style: KType.titreCarte.copyWith(color: k.texte),
              ),
              const SizedBox(height: KSpacing.s12),
              StatsBar(
                value: total == 0 ? 0 : store.completedCount / total,
                label: 'Journées du programme validées',
                description: '${store.completedCount} sur $total',
              ),
              const SizedBox(height: KSpacing.s8),
              Text(
                'Les journées de récupération validées sont incluses.',
                style: KType.detail.copyWith(color: k.texte2),
              ),
            ],
          ),
        ),
        const KSectionTitle('Force, références actuelles et cibles à 12 mois'),
        const StatsText(
          'La jauge mesure le chemin depuis la référence de départ vers la cible.',
          muted: true,
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
        if (unknownLifts) fillIn(),
        const KSectionTitle(
          'Endurance, maximum de répétitions au poids de corps',
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
        if (unknownReps) fillIn(),
        const KSectionTitle('Muscles sollicités, séries validées cette semaine'),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // M8 : carte 2D des groupes de la semaine (face, dos,
              // profil), fond de la carte. Dessin inchangé (cahier §1).
              TargetedMuscleMap(
                key: const ValueKey('stats-muscle-map'),
                names: store.weeklyNames(),
                groups: muscles,
                height: 230,
                subject: 'muscles de la semaine',
              ),
              const SizedBox(height: KSpacing.s12),
              if (muscles.values.every((value) => value <= 0))
                Text(
                  'Valide tes séries pour voir ta répartition musculaire.',
                  style: KType.detail.copyWith(color: k.texte2),
                )
              else ...[
                MuscleLegend(data: muscles, values: true),
                const SizedBox(height: KSpacing.s8),
                Text(
                  'Séries validées cette semaine, pondérées : 1 pour le '
                  'groupe principal de l’exercice, 0,6 pour les autres.',
                  key: const ValueKey('stats-muscles-unite'),
                  style: KType.detail.copyWith(color: k.texte2),
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
/// inventée ; le bandeau de la section mène à Mes références (R5).
class _Unknown extends StatelessWidget {
  final String name;
  const _Unknown(this.name);
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: KType.titreCarte.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s4),
          Text(
            'Non renseigné',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
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
    final k = KTokens.of(context);
    final span = target - start;
    final reached = current >= target;
    final fraction = span <= 0
        ? (reached ? 1.0 : 0.0)
        : ((current - start) / span).clamp(0.0, 1.0);
    return KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: KType.titreCarte.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KSpacing.s12,
            runSpacing: KSpacing.s4,
            children: [
              Text(
                '${statsNumber(current)} $unit',
                style: KType.chiffreMoyen.copyWith(
                  color: reached ? k.validation : k.texte,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    reached ? Icons.check_circle_outline : Icons.flag_outlined,
                    size: KSize.chevron,
                    color: reached ? k.validation : k.texte2,
                  ),
                  const SizedBox(width: KSpacing.s4),
                  Text(
                    'Cible ${statsNumber(target)} $unit',
                    style: KType.detail.copyWith(color: k.texte2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: KSpacing.s12),
          StatsBar(
            value: fraction,
            label: name,
            description:
                '${statsNumber(current)} $unit, cible ${statsNumber(target)} $unit',
            color: reached ? k.validation : null,
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            reached ? 'Cible atteinte' : 'Départ : ${statsNumber(start)} $unit',
            style: KType.detail.copyWith(
              color: reached ? k.validation : k.texte2,
            ),
          ),
        ],
      ),
    );
  }
}
