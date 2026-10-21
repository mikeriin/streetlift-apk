/// Reprise graduée après une douleur qui dure, conduite séance par séance
/// (CA2, partie 0, sécurité) : le palier suit la douleur, une levée ne
/// tombe jamais sur une semaine qui n'est pas de charge, et un arrêt levé
/// au milieu d'un bloc qui écrit encore les mouvements provocants les
/// ramène par paliers. Règles et sources : `CONTRAT.md`, § 11.16.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show CoachNotes, coachPainStopHits;

import 'coach.dart';
import 'model.dart';
import 'params.dart';
import 'replay.dart';

/// Part du volume habituel écrite par `kalis_plan` pour un mouvement en
/// reprise graduée (note `pain_return_item`), ou `null`.
double? writtenReturnShare(ExercisePrescription item) {
  for (final r in item.reasons) {
    if (r.code != ReasonCodes.planCoachNote ||
        r.params['note'] != CoachNotes.painReturnItem) {
      continue;
    }
    final v = r.params['value'];
    if (v is num) {
      return v.toDouble();
    }
  }
  return null;
}

/// Zones en reprise graduée écrites par le bloc [block] (notes
/// `pain_return` de `kalis_plan`).
Set<BodyZone> plannedReturnZones(ProgramBlock block) {
  final out = <BodyZone>{};
  for (final r in <Reason>[...block.pass1.reasons, ...block.pass2.reasons]) {
    if (r.code != ReasonCodes.planCoachNote ||
        r.params['note'] != CoachNotes.painReturn) {
      continue;
    }
    final v = r.params['value'];
    if (v is! num) {
      continue;
    }
    final zone = v.round() ~/ 100;
    if (zone >= 0 && zone < BodyZone.values.length) {
      out.add(BodyZone.values[zone]);
    }
  }
  return out;
}

/// Vrai si la semaine de politique [policy] compte comme semaine de charge
/// pour la reprise graduée (comme dans `kalis_plan` : semaines de charge et
/// d'introduction ; jamais une semaine d'allègement, d'affûtage, de test,
/// de compétition ou de transition).
bool returnLoadedWeek(WeekPolicy policy) =>
    !policy.locked || policy.intent == WeekIntent.intro;

/// État de la reprise graduée au jour d'une séance.
final class PainReturn {
  const PainReturn._({
    required this.zones,
    required this.own,
    required this.held,
    required this.stepBack,
  });

  /// Aucune reprise en cours.
  static const PainReturn none = PainReturn._(
    zones: <BodyZone>{},
    own: <BodyZone, double>{},
    held: <BodyZone>{},
    stepBack: <BodyZone>{},
  );

  /// Zones en reprise graduée (écrite par le bloc ou conduite par le
  /// moteur).
  final Set<BodyZone> zones;

  /// Reprise conduite par le moteur : part du volume écrit servie
  /// aujourd'hui, par zone.
  final Map<BodyZone, double> own;

  /// Zones dont l'arrêt est gardé : il se lèverait sur une semaine qui
  /// n'est pas de charge (jamais de levée sur un allègement).
  final Set<BodyZone> held;

  /// Zones dont le palier recule d'un cran : la douleur a répondu (gêne au-
  /// dessus de 2 sur 10, pas revenue au niveau d'avant le lendemain, ou en
  /// hausse d'une semaine à l'autre).
  final Set<BodyZone> stepBack;

  /// Vrai si l'exercice [e] est en reprise graduée.
  bool hits(CatalogExercise e) => zones.any((z) => coachPainStopHits(e, z));

  /// Zone en reprise de l'exercice [e] dont le palier recule, ou `null`.
  BodyZone? backZoneOf(CatalogExercise e) {
    for (final z in stepBack) {
      if (coachPainStopHits(e, z)) {
        return z;
      }
    }
    return null;
  }

  /// Plus petite part propre au moteur pour l'exercice [e], ou `null`.
  double? ownShareOf(CatalogExercise e) {
    double? least;
    for (final entry in own.entries) {
      if (coachPainStopHits(e, entry.key) &&
          (least == null || entry.value < least)) {
        least = entry.value;
      }
    }
    return least;
  }

  /// Vrai si l'arrêt de la zone de l'exercice [e] est gardé aujourd'hui.
  bool heldFor(CatalogExercise e) => held.any((z) => coachPainStopHits(e, z));

  /// État de la reprise au jour [day], semaine [weekIndex] du bloc vu par
  /// [view], d'après les douleurs de [state].
  static PainReturn of(
    BlockView view,
    ModelState state,
    int day,
    int weekIndex,
    AdaptParams p,
  ) {
    if (!view.coached) {
      return none;
    }
    final planned = plannedReturnZones(view.block);
    final zones = <BodyZone>{};
    final own = <BodyZone, double>{};
    final held = <BodyZone>{};
    final back = <BodyZone>{};
    final start = view.block.pass1.startDate.dayNumber;
    final current = view.policyOf(view.week(weekIndex));
    final loadedNow = returnLoadedWeek(current);
    for (final s in state.pains.values) {
      final zone = s.zone;
      if (s.stopAt(day) != null) {
        continue;
      }
      final lift = s.liftedOn(day);
      final recent = lift != null && day - lift <= p.coachReturnWatchDays;
      if (!recent && !planned.contains(zone)) {
        continue;
      }
      if (lift != null && recent) {
        // Semaines de charge commencées depuis la levée, la semaine du jour
        // exclue (celles d'avant le bloc comptent comme semaines de charge).
        var loaded = lift < start ? (start - lift + 6) ~/ 7 : 0;
        for (var w = 0; w < weekIndex; w++) {
          final weekStart = start + 7 * w;
          // (Une semaine compte quand la levée laisse au moins la moitié
          // de ses jours.)
          if (weekStart + 3 >= lift &&
              returnLoadedWeek(view.policyOf(view.week(w)))) {
            loaded++;
          }
        }
        if (!loadedNow && loaded == 0) {
          // La levée tomberait sur une semaine qui n'est pas de charge :
          // l'arrêt est gardé jusqu'à la première semaine de charge.
          held.add(zone);
          continue;
        }
        if (!planned.contains(zone)) {
          // Reprise propre au moteur : 50 % du volume écrit à la première
          // semaine de charge, +10 % par semaine de charge ; une semaine
          // allégée garde la part de la dernière semaine de charge.
          final steps = loadedNow ? loaded : loaded - 1;
          final share = p.coachReturnStart + p.coachReturnStep * steps;
          if (share < 1 - 1e-9) {
            own[zone] = share;
            zones.add(zone);
          }
        }
      }
      if (planned.contains(zone)) {
        zones.add(zone);
      }
      if (zones.contains(zone) && _responds(s, day, p)) {
        back.add(zone);
      }
    }
    // (Une reprise écrite par le bloc vaut même sans douleur au journal du
    // moteur : la dose écrite n'est jamais dépassée.)
    zones.addAll(planned);
    if (zones.isEmpty && held.isEmpty) {
      return none;
    }
    return PainReturn._(zones: zones, own: own, held: held, stepBack: back);
  }

  /// Vrai si la douleur de la zone [s] a répondu à la reprise (règle écrite
  /// par `kalis_plan` : « chaque palier se garde seulement si la gêne reste
  /// à 2 sur 10 au plus pendant la séance et revient à ton état habituel le
  /// lendemain matin, sans hausse d'une semaine à l'autre »).
  static bool _responds(PainState s, int day, AdaptParams p) {
    final week = s.reportsBetween(day - 6, day);
    if (week.isEmpty) {
      return false;
    }
    for (final r in week) {
      if (r > p.coachReturnPain) {
        return true;
      }
    }
    final latest = week.last;
    // Pas revenue au niveau d'avant : deux signalements qui montent.
    if (week.length >= 2 && latest > 0 && latest > week[week.length - 2]) {
      return true;
    }
    // En hausse d'une semaine à l'autre.
    final before = s.reportsBetween(day - 13, day - 7);
    var worstWeek = 0;
    for (final r in week) {
      if (r > worstWeek) {
        worstWeek = r;
      }
    }
    var worstBefore = 0;
    for (final r in before) {
      if (r > worstBefore) {
        worstBefore = r;
      }
    }
    return worstWeek > 0 && before.isNotEmpty && worstWeek > worstBefore;
  }
}
