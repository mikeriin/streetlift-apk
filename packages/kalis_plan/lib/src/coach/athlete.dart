/// Lecture « coach » du profil d'athlète au schéma 3 : niveau, records,
/// acquis, matériel par jour, contraintes, tolérance. C'est tout ce que
/// les règles de programmation du chemin street de `kalis_plan` 0.2 lisent
/// du profil (CONTRAT.md, § 12).
library;

import 'dart:math' as math;

import 'package:kalis_core/kalis_core.dart';

import '../traits.dart';

/// Poids de corps pris quand le profil ne le donne pas, en kg.
const double coachDefaultBodyWeightKg = 75;

/// Jour d'entraînement lu du profil.
final class CoachDay {
  /// Jour.
  const CoachDay({
    required this.index,
    required this.weekday,
    required this.minutes,
    required this.place,
    required this.equipment,
  });

  /// Rang du jour d'entraînement (0 = premier de la semaine).
  final int index;

  /// Jour ISO (1 = lundi).
  final int weekday;

  /// Minutes disponibles.
  final int minutes;

  /// Lieu imposé, ou `null`.
  final Place? place;

  /// Matériel du jour.
  final Set<String> equipment;
}

/// Zone à ménager : gêne actuelle ou antécédent.
final class CoachLimit {
  /// Zone.
  const CoachLimit({
    required this.zone,
    required this.joint,
    required this.discomfort,
    required this.recent,
    required this.since,
    this.trend = false,
  });

  /// Zone du corps.
  final BodyZone zone;

  /// Articulation du catalogue, ou `null`.
  final Joint? joint;

  /// Gêne de 0 à 10 (la plus forte de la gêne du moment et de la gêne à
  /// l'effort).
  final int discomfort;

  /// Vrai pour une gêne ou un antécédent de moins de douze mois.
  final bool recent;

  /// Ancienneté déclarée, ou `null`.
  final ConstraintSince? since;

  /// Vrai pour une douleur relevée par le moteur d'évolution pendant le
  /// bloc précédent (et non déclarée au profil).
  final bool trend;
}

/// Schémas des figures (tenues et dynamiques bras tendus, équilibres).
const Set<MovementPattern> coachFigurePatterns = <MovementPattern>{
  MovementPattern.figureStatiquePoussee,
  MovementPattern.figureStatiqueTirage,
  MovementPattern.figureStatiqueMixte,
  MovementPattern.figureDynamiquePoussee,
  MovementPattern.figureDynamiqueTirage,
  MovementPattern.equilibreMains,
};

/// Part du volume gardée sur une figure qui charge une zone douloureuse
/// pendant le bloc précédent (R5-P23 : −30 à −50 %).
const double coachTrendPainShare = 0.6;

/// Matériel qui tient le poignet près de la position neutre : un appui
/// pris sur une barre, des anneaux, des parallettes ou des poignées ne met
/// pas le poignet en extension forcée (choix raisonné ; les modifications
/// de la pompe pour le poignet douloureux passent par ces prises : poings,
/// poignées, barre basse).
const Set<String> coachNeutralGripEquipment = <String>{
  'barre fixe',
  'barres parallèles',
  'barre basse',
  'anneaux',
  'parallettes',
  'poignées',
  'sangles de suspension',
};

/// Vrai si l'exercice [e] provoque la zone [zone] au sens de la règle
/// d'arrêt d'une douleur qui dure (CX, correction 1, sécurité) :
/// contrainte forte sur l'articulation de la zone ; pour le poignet, aussi
/// tout appui en extension (contrainte moyenne sans prise neutre : pompes
/// au sol ou sur un banc…). Un appui à prise neutre (barres parallèles,
/// anneaux, poignées) reste permis : c'est la variante « poignet neutre »
/// (NHS, douleur du poignet : éviter ce qui la déclenche ; e3rehab,
/// modifications de la pompe pour le poignet).
bool coachPainProvokes(CatalogExercise e, BodyZone zone) {
  final joint = zone.joint;
  if (joint == null) {
    return false;
  }
  final stress = e.stressOn(joint);
  if (stress == JointStress.high) {
    return true;
  }
  if (zone == BodyZone.wristHand && stress == JointStress.moderate) {
    return !e.equipment.any(coachNeutralGripEquipment.contains);
  }
  return false;
}

/// Vrai pour un tirage vertical en pronation (prise ordinaire ou large,
/// derrière la nuque) : la prise la plus provocante d'une tendinopathie
/// des fléchisseurs et pronateurs du coude (NCBI Bookshelf, épicondylite
/// médiale : la pronation contrariée reproduit la douleur). Après une
/// poussée de douleur au coude, la prise neutre la remplace.
bool coachPronationPull(CatalogExercise e) =>
    e.pattern == MovementPattern.tirageVertical &&
    !e.id.contains('neutre') &&
    !e.id.contains('supination') &&
    !e.id.contains('chin') &&
    !e.id.contains('corde') &&
    !e.assisted &&
    (e.id.contains('pronation') ||
        e.id.contains('large') ||
        e.id.contains('nuque') ||
        e.id == 'sl-traction-lestee');

/// Reprise graduée après une douleur qui dure : part du volume habituel
/// rendue à la première semaine de charge (choix raisonné sur la relecture
/// documentée CX : la moitié du volume au départ).
const double coachPainReturnStart = 0.5;

/// Hausse de la part rendue par semaine de charge (Soligard et al. 2016,
/// consensus du CIO : petites hausses régulières, de l'ordre de 10 % par
/// semaine).
const double coachPainReturnStep = 0.1;

/// Paliers de la reprise graduée (0,5 → 1,0 en cinq semaines de charge).
const int coachPainReturnSteps = 5;

/// Zones dont l'arrêt (douleur qui dure ou qui revient) est signalé par le
/// moteur d'évolution dans [reasons] (`adapt.pain_persistent`).
Set<BodyZone> coachPainStops(Iterable<Reason> reasons) {
  final out = <BodyZone>{};
  for (final r in reasons) {
    if (r.code != ReasonCodes.adaptPainPersistent) {
      continue;
    }
    final code = r.params['zone'];
    for (final z in BodyZone.values) {
      if (z.code == code) {
        out.add(z);
      }
    }
  }
  return out;
}

/// Disciplines que le chemin street sait programmer.
const Set<TrainingDiscipline> coachStreetDisciplines = <TrainingDiscipline>{
  TrainingDiscipline.streetWorkout,
  TrainingDiscipline.streetlifting,
  TrainingDiscipline.calisthenics,
};

/// Séries observées au moins pour qu'une estimation du moteur d'évolution
/// recale un repère (choix raisonné : deux semaines de séances sur le
/// mouvement).
const int coachEstimateMinObservations = 6;

/// Erreur type relative maximale de cette estimation (choix raisonné :
/// l'incertitude d'un 1RM estimé sur des séries sous-maximales est de
/// l'ordre de 5 %, Helms et al. 2016).
const double coachEstimateMaxError = 0.06;

/// Écart minimal sous le repère pour que l'estimation le remplace : 2,5 %,
/// un pas de charge ou une répétition sur dix (choix raisonné).
const double coachEstimateMargin = 0.025;

/// Même écart pour un 1RM : 6 %. L'estimation du moteur d'évolution se
/// tient 3 à 5 % sous le 1RM réel (CA1.3, prudence voulue) ; au-dessous
/// de cette marge, elle ferait baisser à tort les charges du bloc suivant
/// (panel CX, boucle 5 : séries allégées à 6 à 10 répétitions de réserve).
const double coachEstimateLoadMargin = 0.06;

/// Vrai si [profile] relève du chemin street de `kalis_plan` 0.2 : profil
/// au schéma 3 rempli par le questionnaire 0.4 (expérience et ancienneté
/// renseignées — sans elles le niveau n'est pas lisible et le chemin 0.1
/// s'applique), discipline principale street (streetlifting, sets & reps,
/// calisthénie), disciplines secondaires street, cardio ou mobilité.
bool coachEligible(AthleteProfile profile) {
  if (!profile.isSchema3 ||
      profile.experience == null ||
      profile.trainingAge == null) {
    return false;
  }
  final mix = profile.disciplines;
  if (!coachStreetDisciplines.contains(mix.primary)) {
    return false;
  }
  for (final s in mix.secondaries) {
    if (!coachStreetDisciplines.contains(s.discipline) &&
        s.discipline != TrainingDiscipline.cardio &&
        s.discipline != TrainingDiscipline.mobility) {
      return false;
    }
  }
  return profile.availability.isNotEmpty;
}

double _pow(double x, double y) => math.pow(x, y).toDouble();

/// Rythme le plus rapide que le plan s'autorise pour un maximum de
/// répétitions, en fraction du record par semaine et par niveau (choix
/// raisonné : R5-P13, les gains ralentissent avec l'ancienneté ; le plan
/// ne promet jamais plus, même si l'objectif déclaré le demande).
const List<double> coachPlannedRepsRate = <double>[0.08, 0.03, 0.02, 0.012];

/// Même borne pour un maintien maximal (choix raisonné).
const List<double> coachPlannedHoldRate = <double>[0.05, 0.04, 0.03, 0.02];

/// Profil lu par le coach.
final class Athlete {
  Athlete._({
    required this.catalog,
    required this.traits,
    required this.profile,
    required this.start,
    required this.level,
    required this.bodyWeight,
    required this.age,
    required this.days,
    required this.oneRm,
    required this.reps,
    required this.holds,
    required this.recordDay,
    required this.runTenKSeconds,
    required this.notAcquired,
    required this.known,
    required this.excluded,
    required this.limits,
    required this.cautious,
    required this.volumeFactor,
    required this.pullFactor,
    required this.legsFactor,
    required this.rirBonus,
    required this.freezeVolume,
    required this.slowRamp,
    required this.gapWeeks,
    required this.heavyImpactBanned,
    required this.allImpactBanned,
    this.stopZones = const <BodyZone>{},
    this.returnSteps = const <BodyZone, int>{},
    this.stalled = const <String>{},
  });

  /// Lit [profile] pour un bloc qui commence le [start].
  factory Athlete.read(
    Catalog catalog,
    AthleteProfile profile,
    CivilDate start, {
    Set<String> extraExcluded = const <String>{},
    List<(BodyZone, int)> extraPains = const <(BodyZone, int)>[],
    List<(BodyZone, int)> trendPains = const <(BodyZone, int)>[],
    Iterable<String> avoidedIds = const <String>[],
    Map<int, int> minutesOverride = const <int, int>{},
    List<ExerciseEstimate> estimates = const <ExerciseEstimate>[],
    Set<BodyZone> stopZones = const <BodyZone>{},
    Map<BodyZone, int> returnSteps = const <BodyZone, int>{},
  }) {
    final traits = CatalogTraits.of(catalog);
    final bodyWeight = profile.bodyWeightKg ?? coachDefaultBodyWeightKg;
    final age = start.year - profile.birthYear;

    // Jours, triés par jour de la semaine.
    final slots = <DaySlot>[...profile.availability]
      ..sort((a, b) => a.weekday.compareTo(b.weekday));
    final byPlace = <Place, Set<String>>{
      for (final pe in profile.equipmentByPlace ?? const <PlaceEquipment>[])
        pe.place: pe.equipment.toSet(),
    };
    final all = profile.equipment.toSet();
    final days = <CoachDay>[];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      final place = s.place;
      days.add(
        CoachDay(
          index: i,
          weekday: s.weekday,
          minutes: minutesOverride[i] ?? s.minutes,
          place: place,
          equipment: place == null ? all : (byPlace[place] ?? all),
        ),
      );
    }

    // Records : tests datés du schéma 3 d'abord, fourchettes du schéma 2
    // ensuite (borne basse).
    final oneRm = <String, double>{};
    final reps = <String, int>{};
    final holds = <String, int>{};
    final recordDay = <String, CivilDate>{};
    double? runTenK;
    final zero = <String>{};
    for (final l in profile.movementLevels) {
      final low = l.low;
      if (!l.known || low == null) {
        continue;
      }
      switch (l.measure) {
        case LevelMeasure.oneRmKg:
          oneRm[l.exerciseId] = low;
        case LevelMeasure.maxReps:
          if (low <= 0 && (l.high ?? 0) <= 0) {
            zero.add(l.exerciseId);
          } else {
            reps[l.exerciseId] = low.floor();
          }
        case LevelMeasure.maxHoldSeconds:
          if (low > 0) {
            holds[l.exerciseId] = low.floor();
          }
        case LevelMeasure.timeSeconds:
          break;
      }
    }
    for (final b in profile.benchmarks ?? const <Benchmark>[]) {
      switch (b.kind) {
        case BenchmarkKind.loadReps:
          final load = b.externalLoadKg;
          final n = b.reps;
          if (load == null || n == null) {
            break;
          }
          final e = catalog.find(b.exerciseId);
          final fraction = e?.bodyweightFraction?.value ?? 0;
          final total = load + fraction * (b.bodyWeightKg ?? bodyWeight);
          final estimate = estimateOneRm(
            loadKg: total,
            reps: n,
            rir: b.rir ?? 0,
          );
          if (estimate != null) {
            final external = estimate.valueKg - fraction * bodyWeight;
            final before = oneRm[b.exerciseId];
            if (before == null || external > before) {
              oneRm[b.exerciseId] = external;
            }
          }
        case BenchmarkKind.maxReps:
          final n = b.reps;
          if (n != null && (b.externalLoadKg ?? 0) == 0) {
            final before = reps[b.exerciseId];
            if (before == null || n > before) {
              reps[b.exerciseId] = n;
              final day = b.date;
              if (day != null) {
                recordDay[b.exerciseId] = day;
              }
            }
            zero.remove(b.exerciseId);
          }
        case BenchmarkKind.maxHold:
          final s = b.seconds;
          if (s != null && (b.externalLoadKg ?? 0) == 0) {
            final before = holds[b.exerciseId];
            if (before == null || s > before) {
              holds[b.exerciseId] = s;
              final day = b.date;
              if (day != null) {
                recordDay[b.exerciseId] = day;
              }
            }
          }
        case BenchmarkKind.timeTrial:
          final t = b.seconds;
          final meters = b.distanceMeters;
          if (t != null && meters != null && meters >= 1000 && t > 0) {
            // Allure ramenée à 10 km par la formule de Riegel (exposant
            // 1,06).
            final ten = t * _pow(10000 / meters, 1.06);
            if (runTenK == null || ten < runTenK) {
              runTenK = ten;
            }
          }
        default:
          break;
      }
    }
    for (final s in profile.skills ?? const <SkillState>[]) {
      final hold = s.bestHoldSeconds;
      if (hold != null && hold > 0) {
        final before = holds[s.currentExerciseId];
        if (before == null || hold > before) {
          holds[s.currentExerciseId] = hold;
        }
      }
      final n = s.bestReps;
      if (n != null && n > 0) {
        final before = reps[s.currentExerciseId];
        if (before == null || n > before) {
          reps[s.currentExerciseId] = n;
        }
      }
    }

    // Le dernier test mesuré fait foi (CX, correction 1 : « le bloc suivant
    // part du résultat réel du test ») : un résultat de test ou de
    // compétition daté remplace la valeur du même mouvement, même plus
    // basse, tant qu'aucune valeur déclarée plus récente ne le contredit.
    // Un record déclaré n'est qu'un repère de départ ; le test le recale
    // dans les deux sens (R2-P2, R3-P14 ; Helms et al. 2018 : régler la
    // charge sur la performance mesurée plutôt que sur un pourcentage
    // supposé). Le moteur d'évolution ne rend pas un test fait un jour de
    // bilan nettement bas (`kalis_adapt`, CA1).
    final latest = <String, Benchmark>{};
    final newestOther = <String, CivilDate>{};
    for (final b in profile.benchmarks ?? const <Benchmark>[]) {
      final day = b.date;
      if (day == null) {
        continue;
      }
      final key = '${b.kind.code}|${b.exerciseId}';
      final measured =
          b.source == BenchmarkSource.guidedTest ||
          b.source == BenchmarkSource.competition;
      if (measured) {
        final current = latest[key];
        if (current == null || day.compareTo(current.date!) >= 0) {
          latest[key] = b;
        }
      } else {
        final current = newestOther[key];
        if (current == null || day.compareTo(current) > 0) {
          newestOther[key] = day;
        }
      }
    }
    // Plateau (CX, correction 1) : un test de répétitions ou de maintien
    // qui ne dépasse pas le repère d'avant (record déclaré ou meilleur
    // résultat d'avant) — le bloc suivant change de méthode.
    final stalled = <String>{};
    for (final entry in latest.entries) {
      final b = entry.value;
      final day = b.date!;
      final prior = <int>[
        for (final l in profile.movementLevels)
          if (l.exerciseId == b.exerciseId &&
              l.known &&
              l.low != null &&
              ((b.kind == BenchmarkKind.maxReps &&
                      l.measure == LevelMeasure.maxReps) ||
                  (b.kind == BenchmarkKind.maxHold &&
                      l.measure == LevelMeasure.maxHoldSeconds)))
            l.low!.floor(),
        for (final o in profile.benchmarks ?? const <Benchmark>[])
          if (!identical(o, b) &&
              o.exerciseId == b.exerciseId &&
              o.kind == b.kind &&
              (o.externalLoadKg ?? 0) == 0)
            (b.kind == BenchmarkKind.maxHold ? o.seconds : o.reps) ?? 0,
      ];
      final value = b.kind == BenchmarkKind.maxHold ? b.seconds : b.reps;
      if (value != null &&
          prior.isNotEmpty &&
          (b.kind == BenchmarkKind.maxReps || b.kind == BenchmarkKind.maxHold) &&
          value <= prior.reduce((x, y) => x > y ? x : y)) {
        stalled.add(b.exerciseId);
      }
      final other = newestOther[entry.key];
      if (other != null && other.compareTo(day) > 0) {
        continue;
      }
      // Un test plus bas que le repère n'abaisse le repère que jusqu'à ce
      // que l'athlète a montré à l'entraînement (estimation du moteur
      // d'évolution sur assez de séries) : un seul test d'un mauvais jour
      // ne fait pas tomber tout le bloc (R3-P16 ; panel CX, boucle 1).
      // (Répétitions et maintiens ; l'estimation doit être sûre et récente,
      // quinze jours au plus avant le test. Un 1RM testé plus bas fait foi :
      // une barre manquée se recale à la baisse.)
      // Un repère ne baisse qu'après deux mesures concordantes (CX,
      // correction 1 : un test fait sur la fatigue ne réécrit pas le bloc
      // suivant à la baisse ; Bosquet et al. 2007, la forme se mesure
      // après quelques jours légers) : une mesure plus basse, seule, cède
      // devant le plus haut du test et de l'estimation du moteur
      // d'évolution — et, sans estimation sûre, devant le repère connu.
      // Deux tests de suite plus bas (dix semaines au plus d'écart) font
      // foi.
      int lowered(int measured, int? before, CapacityUnit unit) {
        if (before == null || measured >= before) {
          return measured;
        }
        var concordant = false;
        for (final o in profile.benchmarks ?? const <Benchmark>[]) {
          final when = o.date;
          if (identical(o, b) ||
              when == null ||
              o.exerciseId != b.exerciseId ||
              o.kind != b.kind ||
              (o.externalLoadKg ?? 0) != 0 ||
              (o.source != BenchmarkSource.guidedTest &&
                  o.source != BenchmarkSource.competition) ||
              when.compareTo(day) >= 0 ||
              when.compareTo(day.addDays(-70)) < 0) {
            continue;
          }
          final value = unit == CapacityUnit.maxHoldSeconds ? o.seconds : o.reps;
          if (value != null && value < before) {
            concordant = true;
          }
        }
        int? estimate;
        for (final e in estimates) {
          final seen = e.lastObservedOn;
          if (e.exerciseId == b.exerciseId &&
              e.unit == unit &&
              e.observations >= coachEstimateMinObservations &&
              e.standardError <= coachEstimateMaxError * e.capacity &&
              seen != null &&
              seen.compareTo(day.addDays(-14)) >= 0) {
            estimate = e.capacity.floor();
          }
        }
        if (concordant) {
          if (estimate != null && estimate > measured) {
            return estimate < before ? estimate : before;
          }
          return measured;
        }
        if (estimate == null) {
          return before;
        }
        final high = estimate > measured ? estimate : measured;
        return high < before ? high : before;
      }

      switch (b.kind) {
        case BenchmarkKind.maxReps:
          final n = b.reps;
          if (n != null && n > 0 && (b.externalLoadKg ?? 0) == 0) {
            reps[b.exerciseId] = lowered(
              n,
              reps[b.exerciseId],
              CapacityUnit.maxReps,
            );
            recordDay[b.exerciseId] = day;
            zero.remove(b.exerciseId);
          }
        case BenchmarkKind.maxHold:
          final s = b.seconds;
          if (s != null && s > 0 && (b.externalLoadKg ?? 0) == 0) {
            holds[b.exerciseId] = lowered(
              s,
              holds[b.exerciseId],
              CapacityUnit.maxHoldSeconds,
            );
            recordDay[b.exerciseId] = day;
          }
        case BenchmarkKind.loadReps:
          final load = b.externalLoadKg;
          final n = b.reps;
          if (load == null || n == null || n < 1) {
            break;
          }
          final e = catalog.find(b.exerciseId);
          final fraction = e?.bodyweightFraction?.value ?? 0;
          final estimate = estimateOneRm(
            loadKg: load + fraction * (b.bodyWeightKg ?? bodyWeight),
            reps: n,
            rir: b.rir ?? 0,
          );
          if (estimate != null) {
            oneRm[b.exerciseId] = estimate.valueKg - fraction * bodyWeight;
            recordDay[b.exerciseId] = day;
          }
        default:
          break;
      }
    }

    // Estimations du moteur d'évolution (résumé d'adaptation du bloc
    // précédent, CX, correction 1) : une capacité nettement plus basse que
    // le repère, estimée sur assez de séries et sans test plus récent,
    // devient le repère du bloc (le bloc suivant part de ce que l'athlète
    // a montré, R2-P20 ; Helms et al. 2018). Jamais au-dessus d'un repère
    // connu : une hausse attend un test (CP1.3). Un exercice sans repère
    // prend l'estimation.
    for (final e in estimates) {
      final seen = e.lastObservedOn;
      if (e.observations < coachEstimateMinObservations ||
          e.capacity <= 0 ||
          e.standardError > coachEstimateMaxError * e.capacity ||
          seen == null) {
        continue;
      }
      var newer = false;
      for (final b in latest.values) {
        if (b.exerciseId == e.exerciseId && b.date!.compareTo(seen) >= 0) {
          newer = true;
        }
      }
      if (newer) {
        continue;
      }
      switch (e.unit) {
        case CapacityUnit.oneRmKg:
          final before = oneRm[e.exerciseId];
          final fraction =
              catalog.find(e.exerciseId)?.bodyweightFraction?.value ?? 0;
          final external = e.capacity - fraction * bodyWeight;
          final total = (before ?? 0) + fraction * bodyWeight;
          // (Une amplitude partielle surchargée ne prend pas d'estimation
          // sans record : ses séries servies ne mesurent pas un 1RM.)
          // (Seuls les mouvements de compétition lestés prennent une
          // estimation sans record : un 1RM d'isolation ou de variante
          // estimé sur des séries longues n'est pas fiable.)
          final partial =
              e.exerciseId.contains('partiel') ||
              !e.exerciseId.startsWith('sl-');
          if ((before == null && external > 0 && !partial) ||
              (before != null &&
                  external > 0 &&
                  e.capacity < total * (1 - coachEstimateLoadMargin))) {
            oneRm[e.exerciseId] = external;
            recordDay[e.exerciseId] = seen;
          }
        // Sans repère du tout (variante jamais déclarée ni testée, dosée
        // jusque-là par une plage fixe), l'estimation devient le repère :
        // elle remplace une plage supposée par ce que l'athlète a montré
        // (CX, correction 1 ; R5-P2 : 50 à 70 % du maximum).
        case CapacityUnit.maxReps:
          final before = reps[e.exerciseId];
          if (e.capacity >= 1 &&
              (before == null ||
                  e.capacity < before * (1 - coachEstimateMargin))) {
            reps[e.exerciseId] = e.capacity.floor();
            recordDay[e.exerciseId] = seen;
          }
        case CapacityUnit.maxHoldSeconds:
          final before = holds[e.exerciseId];
          if (e.capacity >= 1 &&
              (before == null ||
                  e.capacity < before * (1 - coachEstimateMargin))) {
            holds[e.exerciseId] = e.capacity.floor();
            recordDay[e.exerciseId] = seen;
          }
        default:
          break;
      }
    }

    // Record sans date : il vaut à la dernière mise à jour du profil.
    for (final id in <String>[...reps.keys, ...holds.keys]) {
      recordDay.putIfAbsent(id, () => profile.updatedOn);
    }

    final cannot = (profile.cannotDoExerciseIds ?? const <String>[]).toSet();
    final notAcquired = <CatalogExercise>[];
    for (final id in <String>{...zero, ...cannot}) {
      final e = catalog.find(id);
      if (e != null) {
        notAcquired.add(e);
      }
    }
    notAcquired.sort((a, b) => a.id.compareTo(b.id));
    final known = <String>{
      ...profile.knownExerciseIds ?? const <String>[],
      ...oneRm.keys,
      ...reps.keys,
      ...holds.keys,
    };
    // Figure écartée par le moteur d'évolution à cause d'une douleur
    // relevée sous le seuil d'arrêt (6/10) : elle revient au bloc suivant,
    // en volume réduit (`pain_trend`) — on recule, on n'abandonne pas
    // (R5-P23, R5-P24 ; panel CX, boucle 4 : planche retirée quatre
    // semaines).
    bool keptFigure(String id) {
      final e = catalog.find(id);
      if (e == null || !coachFigurePatterns.contains(e.pattern)) {
        return false;
      }
      for (final zone in stopZones) {
        if (coachPainProvokes(e, zone)) {
          return false;
        }
      }
      for (final (zone, pain) in trendPains) {
        final joint = zone.joint;
        if (pain < 6 && joint != null && e.stressOn(joint) != JointStress.low) {
          return true;
        }
      }
      return false;
    }

    final excluded = <String>{
      ...profile.dislikedExerciseIds,
      ...cannot,
      ...extraExcluded,
      for (final id in avoidedIds)
        if (!keptFigure(id)) id,
    };

    // Niveau : expérience déclarée, sinon ancienneté.
    var level = 0;
    final experience = profile.experience;
    final trainingAge = profile.trainingAge;
    if (experience != null) {
      level = experience.index;
    } else if (trainingAge != null) {
      level = switch (trainingAge) {
        TrainingAge.under6Months => 0,
        TrainingAge.months6To24 => 1,
        _ => 2,
      };
    }
    if (level > 3) {
      level = 3;
    }

    // Zones à ménager.
    final limits = <CoachLimit>[];
    for (final l in profile.limitations) {
      final effort = l.effortDiscomfort ?? 0;
      final discomfort = effort > l.discomfort ? effort : l.discomfort;
      final since = l.since;
      final recent =
          since == null ||
          (since != ConstraintSince.over12Months &&
              since != ConstraintSince.pastResolved);
      limits.add(
        CoachLimit(
          zone: l.zone,
          joint: l.joint ?? l.zone.joint,
          discomfort: discomfort,
          recent: recent,
          since: since,
        ),
      );
    }
    for (final (zone, pain) in extraPains) {
      limits.add(
        CoachLimit(
          zone: zone,
          joint: zone.joint,
          discomfort: pain,
          recent: true,
          since: null,
          trend: false,
        ),
      );
    }
    for (final (zone, pain) in trendPains) {
      limits.add(
        CoachLimit(
          zone: zone,
          joint: zone.joint,
          discomfort: pain,
          recent: true,
          since: null,
          trend: true,
        ),
      );
    }

    final screening = profile.healthScreening;
    final cautious =
        screening == null ||
        screening.outcome != HealthScreeningOutcome.standard ||
        age >= 65 ||
        age < 18;

    // Tolérance (R5-P10, P14, P15, P18, P19, P21 : choix raisonnés).
    var volume = 1.0;
    var pull = 1.0;
    var legs = 1.0;
    var rirBonus = 0.0;
    var freeze = false;
    if (age >= 60) {
      volume *= 0.8;
    }
    if (profile.sleep == SleepBand.under6Hours) {
      volume *= 0.85;
      rirBonus = 1;
      freeze = true;
    }
    if (profile.stress == StressBand.high) {
      volume *= 0.9;
      rirBonus = 1;
      freeze = true;
    }
    if (profile.occupationalLoad == OccupationalLoad.heavy) {
      pull *= 0.85;
      legs *= 0.85;
    }
    if (profile.bodyWeightGoal == BodyWeightGoal.lose) {
      freeze = true;
    }
    var enduranceSessions = 0;
    for (final s in profile.otherSports ?? const <OtherSport>[]) {
      if (s.kind == OtherSportKind.running ||
          s.kind == OtherSportKind.cycling ||
          s.kind == OtherSportKind.otherEndurance ||
          s.kind == OtherSportKind.teamSport) {
        enduranceSessions += s.sessionsPerWeek;
      }
    }
    for (final s in profile.disciplines.secondaries) {
      if (s.discipline == TrainingDiscipline.cardio && s.pct >= 30) {
        enduranceSessions += 3;
      }
    }
    if (enduranceSessions >= 3) {
      legs *= 0.7;
    }
    for (final l in limits) {
      if (l.discomfort >= 2 && l.recent) {
        if (l.zone == BodyZone.elbow ||
            l.zone == BodyZone.shoulder ||
            l.zone == BodyZone.wristHand) {
          pull *= 0.6;
        } else if (l.zone == BodyZone.knee ||
            l.zone == BodyZone.hip ||
            l.zone == BodyZone.ankleFoot ||
            l.zone == BodyZone.lowerBack) {
          legs *= 0.7;
        }
      }
    }
    // R5-P21 : le cumul des réductions ne dépasse pas 40 %.
    if (volume < 0.6) {
      volume = 0.6;
    }
    if (volume * pull < 0.6) {
      pull = 0.6 / volume;
    }
    if (volume * legs < 0.6) {
      legs = 0.6 / volume;
    }

    final gap = profile.trainingGap;
    final gapWeeks = gap == null
        ? 0
        : switch (gap) {
            TrainingGap.reduced => 1,
            TrainingGap.under3Weeks => 2,
            TrainingGap.weeks3To10 => 6,
            TrainingGap.weeks10To26 => 16,
            TrainingGap.months6To24 => 36,
            TrainingGap.over2Years => 104,
            _ => 0,
          };

    final height = profile.heightCm / 100;
    final bmi = bodyWeight / (height * height);
    return Athlete._(
      catalog: catalog,
      traits: traits,
      profile: profile,
      start: start,
      level: level,
      bodyWeight: bodyWeight,
      age: age,
      days: days,
      oneRm: oneRm,
      reps: reps,
      holds: holds,
      recordDay: recordDay,
      runTenKSeconds: runTenK,
      notAcquired: notAcquired,
      known: known,
      excluded: excluded,
      limits: limits,
      cautious: cautious,
      volumeFactor: volume,
      pullFactor: pull,
      legsFactor: legs,
      rirBonus: rirBonus,
      freezeVolume: freeze,
      slowRamp: age >= 40,
      gapWeeks: gapWeeks,
      heavyImpactBanned: level == 0 && bmi >= 30,
      allImpactBanned: cautious,
      stopZones: stopZones,
      stalled: stalled,
      returnSteps: <BodyZone, int>{
        for (final e in returnSteps.entries)
          if (!stopZones.contains(e.key)) e.key: e.value,
      },
    );
  }

  /// Catalogue.
  final Catalog catalog;

  /// Traits du catalogue.
  final CatalogTraits traits;

  /// Profil.
  final AthleteProfile profile;

  /// Premier jour du bloc.
  final CivilDate start;

  /// Niveau : 0 débutant, 1 intermédiaire, 2 avancé, 3 élite.
  final int level;

  /// Poids de corps, en kg.
  final double bodyWeight;

  /// Âge, en années.
  final int age;

  /// Jours d'entraînement.
  final List<CoachDay> days;

  /// 1RM de charge externe par exercice, en kg.
  final Map<String, double> oneRm;

  /// Maximum de répétitions par exercice (strictement positif).
  final Map<String, int> reps;

  /// Maintien maximal par exercice, en secondes.
  final Map<String, int> holds;

  /// Jour du record (répétitions ou maintien) par exercice, quand il est
  /// connu.
  final Map<String, CivilDate> recordDay;

  /// Temps actuel sur 10 km, en secondes (meilleur chrono déclaré, ramené
  /// à 10 km), ou `null`.
  final double? runTenKSeconds;

  /// Objectif de course chronométré (distance en mètres, temps visé en
  /// secondes), ou `null`.
  (double, double)? get runGoal {
    for (final g in profile.goals) {
      final meters = g.distanceMeters;
      final target = g.targetValue;
      if (g.metric == GoalMetric.timeSeconds &&
          meters != null &&
          target != null &&
          meters >= 1000 &&
          target > 0) {
        return (meters, target);
      }
    }
    return null;
  }

  /// Temps prévu sur [meters] d'après le chrono actuel (formule de Riegel,
  /// exposant 1,06), en secondes, ou `null` sans chrono.
  double? runTimeOn(double meters) {
    final ten = runTenKSeconds;
    return ten == null ? null : ten * _pow(meters / 10000, 1.06);
  }

  /// Exercices déclarés non acquis (zéro répétition, « je ne sais pas
  /// faire »).
  final List<CatalogExercise> notAcquired;

  /// Exercices sus (déclarés, ou avec un record).
  final Set<String> known;

  /// Exercices écartés (non aimés, non sus, verrous d'exclusion).
  final Set<String> excluded;

  /// Zones à ménager.
  final List<CoachLimit> limits;

  /// Mode prudent (questionnaire santé, 65 ans et plus, moins de 18 ans).
  final bool cautious;

  /// Facteur de volume général (au plus 1).
  final double volumeFactor;

  /// Facteur de volume du tirage et de la préhension.
  final double pullFactor;

  /// Facteur de volume des jambes.
  final double legsFactor;

  /// Répétitions en réserve ajoutées (sommeil court, stress élevé).
  final double rirBonus;

  /// Vrai quand le volume ne monte pas d'un bloc à l'autre.
  final bool freezeVolume;

  /// Vrai quand la progression du volume est ralentie (40 ans et plus).
  final bool slowRamp;

  /// Semaines d'arrêt avant le programme (0 : aucune ; 1 : entraînement
  /// allégé).
  final int gapWeeks;

  /// Sauts, corde, balistique et haltérophilie écartés (R5-P9).
  final bool heavyImpactBanned;

  /// Tout exercice à impact écarté (mode prudent).
  final bool allImpactBanned;

  /// Zones à l'arrêt : douleur qui dure ou qui revient (signalée par le
  /// moteur d'évolution, `adapt.pain_persistent`) — tout mouvement qui les
  /// provoque est écarté, figures comprises (CX, correction 1).
  final Set<BodyZone> stopZones;

  /// Exercices dont le dernier test n'a pas dépassé le repère d'avant
  /// (plateau) : le bloc change de méthode (CX, correction 1).
  final Set<String> stalled;

  /// Zones en reprise graduée après un arrêt : palier de départ du bloc
  /// (0 : moitié du volume habituel ; chaque palier ajoute 10 %).
  final Map<BodyZone, int> returnSteps;

  /// Part du volume habituel rendue la semaine de charge de rang
  /// [loaded] (0 = première du bloc) à l'exercice [e] en reprise graduée,
  /// ou `null` hors reprise.
  double? returnShareOf(CatalogExercise e, int loaded) {
    double? least;
    for (final entry in returnSteps.entries) {
      if (!coachPainProvokes(e, entry.key)) {
        continue;
      }
      final step = entry.value + (loaded < 0 ? 0 : loaded);
      final share = coachPainReturnStart + coachPainReturnStep * step;
      if (share >= 1 - 1e-9) {
        continue;
      }
      if (least == null || share < least) {
        least = share;
      }
    }
    return least;
  }

  /// Douleur relevée par le moteur d'évolution (bloc précédent) sur
  /// l'articulation [joint], la plus forte, ou 0.
  int trendPainOn(Joint joint) {
    var worst = 0;
    for (final l in limits) {
      if (l.trend && l.joint == joint && l.discomfort > worst) {
        worst = l.discomfort;
      }
    }
    return worst;
  }

  /// Nombre de jours d'entraînement.
  int get dayCount => days.length;

  /// Vrai si le matériel [item] existe le jour [day].
  bool has(int day, String item) => days[day].equipment.contains(item);

  /// Vrai si le matériel [item] existe au moins un jour.
  bool hasAny(String item) => days.any((d) => d.equipment.contains(item));

  /// Zone à ménager la plus gênante sur l'articulation [joint], ou `null`.
  CoachLimit? limitOn(Joint joint) {
    CoachLimit? worst;
    for (final l in limits) {
      if (l.joint == joint &&
          (worst == null || l.discomfort > worst.discomfort)) {
        worst = l;
      }
    }
    return worst;
  }

  /// Objectif chiffré de [metric] sur l'exercice [id], ou `null`.
  Goal? goalOn(String id, GoalMetric metric) {
    for (final g in profile.goals) {
      if (g.exerciseId == id && g.metric == metric && g.targetValue != null) {
        return g;
      }
    }
    return null;
  }

  /// Vrai si un objectif (ou une épreuve de l'échéance) porte sur
  /// l'exercice [id] ou sur une variante de sa chaîne.
  bool aimsAt(String id) {
    final root = catalog.find(id)?.rootId ?? id;
    for (final g in profile.goals) {
      final other = g.exerciseId;
      if (other != null &&
          (other == id || (catalog.find(other)?.rootId ?? other) == root)) {
        return true;
      }
    }
    for (final e in profile.events ?? const <SeasonEvent>[]) {
      for (final l in e.lifts ?? const <CompetitionLift>[]) {
        if (l.exerciseId == id ||
            (catalog.find(l.exerciseId)?.rootId ?? l.exerciseId) == root) {
          return true;
        }
      }
      for (final st in e.stations ?? const <EventStation>[]) {
        if (st.exerciseId == id) {
          return true;
        }
      }
    }
    return false;
  }

  /// Gain prévu du record [record] de l'exercice [id] le [day], en
  /// fraction du record : la trajectoire qui mène à l'objectif déclaré,
  /// bornée par le rythme plausible du niveau, ou la moitié de ce rythme
  /// sans objectif. C'est un plan, pas une mesure : chaque test le recale
  /// (le record et sa date changent, la trajectoire repart de là).
  double plannedGain(String id, GoalMetric metric, num record, CivilDate day) {
    if (record <= 0) {
      return 0;
    }
    final goal = goalOn(id, metric);
    final anchor = recordDay[id] ?? goal?.createdOn;
    if (anchor == null) {
      return 0;
    }
    final weeks = anchor.daysUntil(day) / 7;
    if (weeks <= 0) {
      return 0;
    }
    var cap = (metric == GoalMetric.maxHoldSeconds
        ? coachPlannedHoldRate
        : coachPlannedRepsRate)[level];
    // Petits records : une répétition (ou une seconde) de plus toutes les
    // trois semaines reste plausible à tout niveau.
    if (cap < 1 / (3 * record)) {
      cap = 1 / (3 * record);
    }
    var rate = cap / 2;
    var ceiling = double.infinity;
    final target = goal?.targetValue;
    final deadline = goal?.targetDate;
    if (target != null && target > record) {
      ceiling = target / record - 1;
      if (deadline != null && anchor.daysUntil(deadline) >= 7) {
        final wanted = ceiling / (anchor.daysUntil(deadline) / 7);
        rate = wanted > cap ? cap : wanted;
      } else {
        rate = cap;
      }
    }
    var gain = rate * weeks;
    // Sans objectif chiffré, le plan ne suppose jamais plus de 20 % de
    // progrès sans nouveau test.
    if (target == null && gain > 0.20) {
      gain = 0.20;
    }
    return gain > ceiling ? ceiling : gain;
  }

  /// 1RM de charge totale (charge externe + part du poids de corps) de
  /// l'exercice [id], ou `null`.
  double? totalOneRm(String id) {
    final external = oneRm[id];
    final e = catalog.find(id);
    if (external == null || e == null) {
      return null;
    }
    return external + (e.bodyweightFraction?.value ?? 0) * bodyWeight;
  }

  /// Raison qui écarte l'exercice [id] le jour [day], ou `null` s'il est
  /// admissible. Codes : `unknown`, `excluded`, `equipment`, `joint`,
  /// `level`, `prerequisite`, `technique`, `impact`.
  String? rejection(String id, int day) {
    final e = catalog.find(id);
    if (e == null) {
      return 'unknown';
    }
    if (excluded.contains(id)) {
      return 'excluded';
    }
    final info = days[day];
    final place = info.place;
    final placeOk = place == null
        ? e.places.any(profile.places.contains)
        : e.places.contains(place);
    // Mur : sûr à la maison et en salle seulement ; matériel de
    // remplacement (barre basse pour une pompe mains surélevées…) : kalis_core
    // 0.4.2 (CX, correction 7).
    if (!placeOk ||
        !e.feasibleAt(
          info.equipment,
          place: place,
          places: profile.places.toSet(),
        )) {
      return 'equipment';
    }
    // Douleur qui dure ou qui revient (CX, correction 1, sécurité) : tout
    // mouvement qui provoque la zone est écarté, figure comprise, jusqu'à
    // deux semaines à 2 sur 10 au plus (NHS : consulter si la douleur ne
    // s'améliore pas en deux semaines ou revient).
    for (final zone in stopZones) {
      if (coachPainProvokes(e, zone)) {
        return 'joint';
      }
    }
    // Coude douloureux au bloc précédent (3 sur 10 ou plus) : la prise
    // neutre remplace la pronation sur le tirage vertical (relecture
    // documentée CX, `street_12`).
    // (Le mouvement de l'objectif lui-même reste, sous la règle de
    // douleur : il est l'épreuve.)
    if (coachPronationPull(e) &&
        !aimsAt(id) &&
        (trendPainOn(Joint.elbow) >= 3 || stopZones.contains(BodyZone.elbow))) {
      return 'joint';
    }
    for (final l in limits) {
      final joint = l.joint;
      if (joint == null) {
        continue;
      }
      final stress = e.stressOn(joint);
      // Douleur relevée pendant le bloc précédent, sous le seuil d'arrêt
      // (6/10) : une figure reste au programme, en volume réduit
      // (`coachTrendPainShare`) — on recule, on n'abandonne pas (R5-P23,
      // R5-P24 ; panel CX, boucle 1 : la planche retirée quatre semaines
      // régressait).
      final figure = coachFigurePatterns.contains(e.pattern);
      if (l.trend && figure && l.discomfort < 6) {
        continue;
      }
      if ((stress == JointStress.high && l.discomfort >= 4) ||
          (stress != JointStress.low && l.discomfort >= 6)) {
        return 'joint';
      }
    }
    final isKnown = known.contains(id);
    if (!isKnown && e.level.index > level + 1) {
      return 'level';
    }
    for (final missing in notAcquired) {
      final harder =
          e.rootId == missing.rootId &&
          !e.assisted &&
          e.difficulty >= missing.difficulty;
      if (e.id == missing.id ||
          harder ||
          e.prerequisites.contains(missing.id)) {
        return 'prerequisite';
      }
    }
    if (level < 2 &&
        (id.contains('supramaximal') ||
            id.contains('partielle-haute') ||
            id.contains('partiel-haut') ||
            id.contains('partiel-surcharge') ||
            id.contains('isometrie-lestee'))) {
      return 'technique';
    }
    if (level < 1 && id.contains('chaines')) {
      return 'technique';
    }
    final t = traits.of(id);
    if (allImpactBanned && t.impact) {
      return 'impact';
    }
    if (heavyImpactBanned &&
        (e.pattern == MovementPattern.pliometrie ||
            e.pattern == MovementPattern.cordeASauter ||
            e.pattern == MovementPattern.balistique ||
            e.pattern == MovementPattern.halterophilie)) {
      return 'impact';
    }
    return null;
  }

  /// Vrai si l'exercice [id] est admissible le jour [day].
  bool can(String id, int day) => rejection(id, day) == null;

  /// Premier exercice admissible de [candidates] le jour [day], ou `null`.
  String? pick(List<String> candidates, int day) {
    for (final id in candidates) {
      if (can(id, day)) {
        return id;
      }
    }
    return null;
  }
}
