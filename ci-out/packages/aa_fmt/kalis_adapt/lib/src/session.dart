/// Prescription de la séance du jour : charges et répétitions tirées du
/// modèle, ajustement gradué au bilan santé, zones douloureuses épargnées,
/// séance raccourcie au temps disponible, lieu du jour (D5.8, D5.9).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart'
    show coachPainProvokes, coachPainStopHits, planSimilarity;

import 'book.dart';
import 'coach.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'pain_return.dart';
import 'params.dart';
import 'replay.dart';
import 'skills.dart';

/// Raison de code [code] et de paramètres [params].
Reason reason(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

/// Proximité minimale d'un exercice de remplacement (celle des variantes
/// de `kalis_plan`).
const double substituteMinSimilarity = 0.45;

/// Exercice de la séance en cours de préparation.
final class _Draft {
  _Draft(this.item, this.info, this.role);

  ExercisePrescription item;
  ExerciseInfo? info;
  final SlotRole? role;
  int sets = 0;
  List<SetPlan>? plans;
  ExerciseRun? run;
  final List<Reason> reasons = <Reason>[];
  bool removed = false;

  /// Cibles calculées par le mode coach.
  bool coached = false;

  /// Douleur de 5 sur 10 sur une contrainte moyenne : exercice allégé.
  bool regress = false;

  /// Bloc au contrat 0.4.0 : les techniques sont filtrées par leurs
  /// prérequis même quand la règle générale sert l'exercice.
  bool gated = false;

  /// Semaine servie telle que le bloc l'écrit (décharge, affûtage, test).
  bool locked = false;

  /// Mouvement en reprise graduée après une douleur qui dure (CA2,
  /// partie 0).
  bool inReturn = false;

  /// Part du 1RM la plus haute permise pendant la reprise, ou `null`.
  double? returnPct;

  /// Zone en reprise dont le palier recule aujourd'hui, ou `null`.
  BodyZone? returnBack;

  /// Zone douloureuse du jour pour laquelle l'exercice a été remplacé, ou
  /// `null` (CA2, partie 0 : remplaçant dosé loin de l'échec).
  BodyZone? painSub;
}

/// Matériel disponible aujourd'hui : celui du lieu [place] si le profil le
/// détaille, sinon tout le matériel du profil.
Set<String> equipmentFor(AthleteProfile profile, Place? place) {
  if (place != null) {
    for (final pe in profile.equipmentByPlace ?? const <PlaceEquipment>[]) {
      if (pe.place == place) {
        return pe.equipment.toSet();
      }
    }
  }
  return profile.equipment.toSet();
}

/// Meilleur remplaçant de [original] : même mode de capacité, même unité,
/// même discipline ou même chaîne de variantes, pas plus difficile,
/// faisable avec [equipment] (et au lieu [place]), ni détesté ni déclaré
/// non su, épargnant les zones de [pains], absent de [taken] ; le plus
/// proche au sens de `planSimilarity`, puis par identifiant. [notLoadType]
/// écarte un type de charge (celui dont la plus petite charge est trop
/// lourde).
ExerciseInfo? findSubstitute(
  EngineContext ctx,
  ExerciseInfo original, {
  required Set<String> equipment,
  required Place? place,
  required Map<BodyZone, int> pains,
  required Set<String> taken,
  LoadType? notLoadType,
  bool neutralWrist = false,
  bool Function(CatalogExercise)? avoid,
}) {
  final p = ctx.params;
  final profile = ctx.profile;
  final banned = <String>{
    ...profile.dislikedExerciseIds,
    ...?profile.cannotDoExerciseIds,
  };
  ExerciseInfo? best;
  var bestScore = substituteMinSimilarity;
  final o = original.exercise;
  for (final e in ctx.catalog.exercises) {
    if (e.id == o.id ||
        taken.contains(e.id) ||
        banned.contains(e.id) ||
        e.unit != o.unit ||
        e.loadType == notLoadType ||
        e.difficulty > o.difficulty ||
        (e.discipline != o.discipline && e.rootId != o.rootId) ||
        !e.feasibleWith(equipment) ||
        (place != null && !e.places.contains(place)) ||
        (avoid != null && avoid(e))) {
      continue;
    }
    final info = ctx.book.find(e.id);
    if (info == null || info.mode != original.mode) {
      continue;
    }
    var spared = true;
    for (final entry in pains.entries) {
      if (neutralWrist &&
          entry.key == BodyZone.wristHand &&
          entry.value < p.coachPainStop &&
          !coachPainProvokes(e, BodyZone.wristHand)) {
        // Mode coach : un appui à prise neutre (barres parallèles,
        // parallettes, poignées) garde la poussée quand le poignet est
        // douloureux (CA2, partie 0 ; règle du programme) — pourvu que sa
        // contrainte sur le poignet reste permise à cette douleur.
        if (info.excludedByPain(
          entry.key,
          entry.value,
          hard: p.painHard,
          severe: p.coachPainStop,
        )) {
          spared = false;
          break;
        }
        continue;
      }
      // (Mode coach : le remplaçant obéit au même seuil que l'exercice
      // remplacé — douleur pendant l'effort sous 5 sur 10, Silbernagel et
      // al. 2007 ; CA2, partie 0.)
      if (info.excludedByPain(
            entry.key,
            entry.value,
            hard: p.painHard,
            severe: neutralWrist ? p.coachPainStop : p.painSevere,
          ) ||
          info.zoneLevel(entry.key) > original.zoneLevel(entry.key)) {
        spared = false;
        break;
      }
    }
    if (!spared) {
      continue;
    }
    final score = planSimilarity(o, e);
    if (score > bestScore ||
        (score == bestScore && best != null && e.id.compareTo(best.id) < 0)) {
      best = info;
      bestScore = score;
    }
  }
  return best;
}

/// Durée estimée d'un exercice, en secondes (formule de `kalis_plan` :
/// transition + séries × (effort + repos)).
double itemSeconds(ExercisePrescription item, int sets, AdaptParams p) {
  final rest = item.restSeconds ?? p.defaultRestSeconds;
  double effort;
  final seconds = item.secondsHigh;
  final reps = item.repsHigh;
  if (seconds != null) {
    effort = seconds.toDouble();
  } else if (reps != null) {
    effort = (reps * p.repSeconds).toDouble();
  } else {
    effort = 60;
  }
  return p.transitionSeconds + sets * (effort + rest);
}

/// Construit la prescription de la séance demandée par [request] à partir
/// de l'état rejoué [replayed].
SessionPlan buildSessionPlan(
  EngineContext ctx,
  BlockView view,
  Replayed replayed,
  SessionRequest request,
) {
  final p = ctx.params;
  final input = request.input;
  final today = input.today;
  final day = today.dayNumber;
  final dayPrescription = view.day(request.weekIndex, request.dayIndex);
  if (dayPrescription == null) {
    throw ArgumentError(
      'séance inconnue du bloc : semaine ${request.weekIndex}, '
      'jour ${request.dayIndex}',
    );
  }
  final week = view.week(request.weekIndex);
  final weekKind = week?.kind;
  final policy = view.policyOf(week);
  final coached = view.coached;
  final state = replayed.state.fork();
  final check = request.healthCheck;
  final health = readHealth(check, p);
  notePains(state, check, const <PainReport>[], day, p);
  final painsToday = <BodyZone, int>{};
  for (final s in state.pains.values) {
    if (s.lastIntensity > p.painThreshold && state.painActive(s.zone, day, p)) {
      painsToday[s.zone] = s.lastIntensity;
    }
  }
  // Reprise graduée après une douleur qui dure (CA2, partie 0).
  final comeback = coached
      ? PainReturn.of(view, state, day, request.weekIndex, p)
      : PainReturn.none;
  final extraRir = health.level * p.healthRirBonus;
  final run = SessionRun(
    ctx,
    state,
    day: day,
    health: health,
    bodyWeightKg: bodyWeightOf(null, ctx.profile, p),
    extraRir: extraRir,
    noIncrease: health.level >= 1,
  );
  final fatigueShift = state.fatigue.globalShift(p);
  final readiness = readinessOf(health.shift + fatigueShift, p);

  final sessionReasons = <Reason>[
    reason(ReasonCodes.adaptReadiness, <String, Object?>{
      'readiness': roundTo(readiness, 3),
    }),
  ];
  final healthReasons = <Reason>[];
  final overall = check?.overall;
  if (overall != null && overall < p.healthNeutral) {
    healthReasons.add(
      reason(ReasonCodes.adaptHealthLow, <String, Object?>{'overall': overall}),
    );
  }
  final sleep = check?.sleepQuality;
  if (sleep != null && sleep <= 2) {
    healthReasons.add(
      reason(ReasonCodes.adaptSleepLow, <String, Object?>{
        'sleepQuality': sleep,
      }),
    );
  }
  if (readinessOf(fatigueShift, p) < p.deloadReadiness) {
    healthReasons.add(
      reason(ReasonCodes.adaptFatigueHigh, <String, Object?>{
        'readiness': roundTo(readinessOf(fatigueShift, p), 3),
      }),
    );
  }
  sessionReasons.addAll(healthReasons);
  if (health.level >= 1) {
    // Le palier du bilan est dit dans la séance : le conseil le relit quand
    // le bilan ne lui est pas redonné.
    sessionReasons.add(
      reason(ReasonCodes.adaptLoadHeld, <String, Object?>{
        'cause': health.level >= 2 ? 'health_strong' : 'health',
      }),
    );
  }
  if (replayed.digests.isNotEmpty) {
    final gap = day - replayed.digests.last.day;
    if (gap >= 7) {
      sessionReasons.add(
        reason(ReasonCodes.adaptResumeAfterBreak, <String, Object?>{
          'days': gap,
        }),
      );
    }
  }
  final eventDays = coached ? view.daysToEvent(day) : null;
  if (coached) {
    if (policy.locked) {
      sessionReasons.add(
        reason(ReasonCodes.adaptPhaseRespected, <String, Object?>{
          'phase': policy.code,
        }),
      );
    }
    if (policy.peak) {
      sessionReasons.add(reason(ReasonCodes.adaptTaperNoVolume));
    }
    if (eventDays != null && eventDays <= p.coachEventNearDays) {
      sessionReasons.add(
        reason(ReasonCodes.adaptEventNear, <String, Object?>{
          'days': eventDays,
        }),
      );
    }
    sessionReasons.addAll(recoveryReasons(ctx.profile));
  }
  final weight = state.rater.weight(p);
  if (weight < p.benchmarkWeight) {
    sessionReasons.add(
      reason(ReasonCodes.adaptRatingsUninformative, <String, Object?>{
        'confirmRate': roundTo(state.rater.confirmRate, 3),
        'sets': state.rater.window.length,
      }),
    );
  }

  final adjustments = <SessionAdjustment>[];
  final place = request.place;
  final equipment = equipmentFor(ctx.profile, place);
  final drafts = <_Draft>[
    for (final item in dayPrescription.items)
      _Draft(item, ctx.book.find(item.exerciseId), view.roleOf(item.slotId))
        ..sets = item.sets,
  ];
  final taken = <String>{for (final d in drafts) d.item.exerciseId};

  // 1. Lieu du jour et zones douloureuses : exercices remplacés ou retirés.
  for (final d in drafts) {
    final info = d.info;
    if (info == null) {
      continue;
    }
    final e = info.exercise;
    final misplaced =
        place != null &&
        (!e.feasibleWith(equipment) || !e.places.contains(place));
    BodyZone? painZone;
    for (final entry in painsToday.entries) {
      if (info.excludedByPain(
        entry.key,
        entry.value,
        hard: p.painHard,
        severe: coached ? p.coachPainStop : p.painSevere,
      )) {
        painZone = entry.key;
        break;
      }
      if (coached &&
          entry.value >= p.coachPainRegress &&
          info.zoneLevel(entry.key) >= 0.5) {
        d.regress = true;
      }
    }
    // Plus petite charge du matériel encore trop lourde : la dernière
    // séance, à cette charge, a échoué, et le modèle n'y prévoit pas deux
    // répétitions.
    var tooHeavy = false;
    final track = state.tracks[info.id];
    final lastLoad = track?.lastLoad;
    if (track != null &&
        info.mode == CapacityMode.loaded &&
        lastLoad != null &&
        track.noUp &&
        lastLoad <= info.grid.minimum + 1e-9) {
      final total = info.totalLoad(info.grid.minimum, run.bodyWeightKg);
      tooHeavy = total > 0 && track.filter.repsPossible(ln(total)) < 2;
    }
    if (coached && d.item.kind == SetKind.test) {
      // Un test ne se fait jamais sur une zone douloureuse : il est
      // reporté, jamais remplacé (CA2, partie 0 ; R3-P16).
      for (final entry in painsToday.entries) {
        if (info.zoneLevel(entry.key) >= 0.5) {
          painZone ??= entry.key;
        }
      }
      // (Ni tant que la zone a été signalée au-dessus de 2 sur 10 dans la
      // semaine : relecture documentée du pilotage, manche 4.)
      for (final s in state.pains.values) {
        if (painZone == null &&
            info.zoneLevel(s.zone) >= 0.5 &&
            s.reportsBetween(day - 6, day).any((r) => r > p.coachReturnPain)) {
          painZone = s.zone;
        }
      }
      if (painZone != null) {
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: e.id,
            reasons: <Reason>[
              reason(ReasonCodes.adaptPainReported, <String, Object?>{
                'zone': painZone.code,
                'intensity': painsToday[painZone],
              }),
            ],
          ),
        );
        continue;
      }
    }
    if (!misplaced && painZone == null && !tooHeavy) {
      continue;
    }
    final why = <Reason>[
      if (tooHeavy)
        reason(ReasonCodes.adaptLoadFloor, <String, Object?>{
          'minKg': roundTo(info.grid.minimum, 2),
        }),
      if (painZone != null)
        reason(ReasonCodes.adaptPainReported, <String, Object?>{
          'zone': painZone.code,
          'intensity': painsToday[painZone],
        }),
      if (misplaced)
        reason(ReasonCodes.adaptPlaceChanged, <String, Object?>{
          'place': place.code,
        }),
    ];
    final substitute = info.mode == null
        ? null
        : findSubstitute(
            ctx,
            info,
            equipment: equipment,
            place: place,
            pains: painsToday,
            taken: taken,
            notLoadType: tooHeavy ? e.loadType : null,
            neutralWrist: coached,
          );
    if (substitute == null) {
      d.removed = true;
      adjustments.add(
        SessionAdjustment(
          kind: AdjustmentKind.exerciseRemoved,
          exerciseId: e.id,
          reasons: why,
        ),
      );
      continue;
    }
    taken.add(substitute.id);
    adjustments.add(
      SessionAdjustment(
        kind: AdjustmentKind.exerciseSwapped,
        exerciseId: e.id,
        replacementExerciseId: substitute.id,
        reasons: why,
      ),
    );
    d.reasons.addAll(why);
    d.info = substitute;
    d.item = _retarget(d.item, substitute);
    if (coached && painZone != null) {
      d.painSub = painZone;
    }
  }

  // 1 bis 0. Mode coach : douleur qui dure ou qui revient (CX, correction
  // 1, sécurité) — tout mouvement qui provoque la zone est retiré de la
  // séance (pas remplacé par une variante plus douce de la même zone),
  // jusqu'à deux semaines à 2 sur 10 au plus ; consulte (règle du bloc).
  if (coached) {
    final allStops = state.painStops(day);
    for (final stop in allStops) {
      final why = <Reason>[
        reason(ReasonCodes.adaptPainPersistent, <String, Object?>{
          'zone': stop.zone.code,
          'sessions': stop.sessions,
        }),
      ];
      // (La consigne — arrêt, consulter, reprise graduée — figure sur la
      // séance même quand la douleur du jour a déjà remplacé les
      // mouvements : panel CX correction 1, gêne à 4/10 six semaines sans
      // la règle « douleur qui dure ».)
      // Un renvoi vers un professionnel à la première séance de l'arrêt,
      // puis un rappel par semaine (relecture documentée du pilotage,
      // manche 4 : une trentaine de rappels identiques noyaient le suivi).
      if (_stopNoticeDue(state.pains[stop.zone], day) &&
          !sessionReasons.contains(why.first)) {
        sessionReasons.add(why.first);
      }
      for (final d in drafts) {
        final info = d.info;
        // (Échauffement compris : un appui sur les poignets à l'échauffement
        // provoque la zone comme une série de travail — relecture
        // documentée du pilotage, manche 4.)
        if (d.removed ||
            info == null ||
            !coachPainStopHits(info.exercise, stop.zone)) {
          continue;
        }
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: d.item.exerciseId,
            reasons: why,
          ),
        );
      }
    }
    // Arrêt gardé : il se lèverait sur une semaine qui n'est pas de charge
    // (jamais de levée sur un allègement, un affûtage ou un test).
    for (final zone in comeback.held) {
      final why = <Reason>[
        reason(ReasonCodes.adaptPainPersistent, <String, Object?>{
          'zone': zone.code,
          'sessions': 0,
        }),
      ];
      for (final d in drafts) {
        final info = d.info;
        if (d.removed ||
            info == null ||
            d.item.kind == SetKind.warmup ||
            !coachPainStopHits(info.exercise, zone)) {
          continue;
        }
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: d.item.exerciseId,
            reasons: why,
          ),
        );
      }
    }
    // Reprise graduée : les mouvements qui provoquent la zone sont servis
    // à la part du palier (celle du bloc, ou celle du moteur quand l'arrêt
    // s'est levé au milieu d'un bloc qui les écrit encore) ; le palier
    // recule d'un cran quand la douleur répond ; jamais de test.
    for (final d in drafts) {
      final info = d.info;
      if (d.removed ||
          info == null ||
          d.item.kind == SetKind.warmup ||
          !comeback.hits(info.exercise)) {
        continue;
      }
      final e = info.exercise;
      final held = <Reason>[
        reason(ReasonCodes.adaptLoadHeld, <String, Object?>{
          'cause': 'pain_return',
        }),
      ];
      if (d.item.kind == SetKind.test) {
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: d.item.exerciseId,
            reasons: held,
          ),
        );
        continue;
      }
      d.inReturn = true;
      d.reasons.addAll(held);
      final written = writtenReturnShare(d.item);
      final own = comeback.ownShareOf(e);
      // (Plusieurs zones : la part la plus basse, celle du bloc ou celle du
      // moteur.)
      var share = written ?? 1.0;
      var ownLower = false;
      if (own != null && (written == null || own < written)) {
        share = own;
        ownLower = true;
      }
      var effective = share;
      var sets = d.sets;
      if (ownLower) {
        sets = (d.sets * share / (written ?? 1.0)).floor();
      }
      final back = comeback.backZoneOf(e);
      if (back != null) {
        final lower = share - p.coachReturnStep;
        effective = lower < p.coachReturnFloor ? p.coachReturnFloor : lower;
        sets = (sets * effective / share).floor();
        d.returnBack = back;
      }
      if (ownLower || back != null) {
        d.returnPct = _returnLoadAt(effective, p);
      }
      if (sets < 1) {
        sets = 1;
      }
      if (sets < d.sets) {
        if (!_setsAdjustable(d.item)) {
          d.item = standardEquivalent(d.item);
        }
        final why = <Reason>[
          reason(ReasonCodes.adaptVolumeDown, <String, Object?>{
            'sets': d.sets - sets,
          }),
        ];
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: d.item.exerciseId,
            setsDelta: sets - d.sets,
            reasons: why,
          ),
        );
        d.reasons.addAll(why);
        d.sets = sets;
      }
    }
    // Arrêt en cours : les mouvements qui chargent la zone sans la
    // provoquer (contrainte moyenne, appui à prise neutre) restent, servis
    // comme au premier palier de la reprise — moitié des séries écrites,
    // trois répétitions en réserve, aucune hausse, 67,5 % du 1RM au plus ;
    // jamais de test. Quand la douleur ne baisse pas après deux semaines
    // d'arrêt (encore 3 sur 10 ou plus dans la semaine), ils sont retirés
    // aussi : la charge qui reste entretient la douleur (CA2, partie 0 ;
    // relecture documentée du pilotage, manche 4 ; Silbernagel et al. 2007 :
    // douleur sous 5 sur 10 pendant l'effort, revenue le lendemain matin,
    // jamais en hausse d'une semaine à l'autre).
    void stopDose(_Draft d, BodyZone zone) {
      d.inReturn = true;
      d.returnBack = zone;
      d.returnPct = _returnLoadAt(p.coachReturnStart, p);
      d.reasons.add(
        reason(ReasonCodes.adaptLoadHeld, <String, Object?>{
          'cause': 'pain_return',
        }),
      );
      var sets = (d.sets * p.coachReturnStart).floor();
      if (sets < 1) {
        sets = 1;
      }
      if (sets < d.sets) {
        if (!_setsAdjustable(d.item)) {
          d.item = standardEquivalent(d.item);
        }
        final cut = <Reason>[
          reason(ReasonCodes.adaptVolumeDown, <String, Object?>{
            'sets': d.sets - sets,
          }),
        ];
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: d.item.exerciseId,
            setsDelta: sets - d.sets,
            reasons: cut,
          ),
        );
        d.reasons.addAll(cut);
        d.sets = sets;
      }
    }

    final stopZones = <BodyZone, int>{
      for (final stop in allStops) stop.zone: stop.sessions,
      for (final zone in comeback.held) zone: 0,
    };
    for (final entry in stopZones.entries) {
      final zone = entry.key;
      final track = state.pains[zone];
      // (Poignet : l'arrêt couvre d'emblée toute charge d'appui, prise
      // neutre comprise — relecture documentée du pilotage, manche 4,
      // `street_10`.)
      final escalated =
          zone == BodyZone.wristHand ||
          (entry.value > 0 &&
              track != null &&
              track.stopAt(day - p.coachStopEscalateDays) != null &&
              track
                  .reportsBetween(day - 6, day)
                  .any((r) => r >= painPersistMin));
      final why = <Reason>[
        reason(ReasonCodes.adaptPainPersistent, <String, Object?>{
          'zone': zone.code,
          'sessions': entry.value,
        }),
      ];
      for (final d in drafts) {
        final info = d.info;
        if (d.removed ||
            info == null ||
            (d.item.kind == SetKind.warmup && !escalated) ||
            info.zoneLevel(zone) < 0.5) {
          continue;
        }
        if (escalated || d.item.kind == SetKind.test) {
          d.removed = true;
          adjustments.add(
            SessionAdjustment(
              kind: AdjustmentKind.exerciseRemoved,
              exerciseId: d.item.exerciseId,
              reasons: why,
            ),
          );
          continue;
        }
        if (!d.inReturn) {
          stopDose(d, zone);
        }
      }
    }
    // Remplaçant choisi pour une douleur du jour : loin de l'échec, sans
    // hausse, 70 % du 1RM au plus (CA2, partie 0 ; relecture documentée du
    // pilotage, manche 4 : un remplaçant lourd chargeait la zone).
    for (final d in drafts) {
      final zone = d.painSub;
      if (d.removed || zone == null || d.inReturn) {
        continue;
      }
      d.inReturn = true;
      d.returnBack = zone;
      d.returnPct = p.coachPainSubPct;
      d.reasons.add(
        reason(ReasonCodes.adaptLoadHeld, <String, Object?>{
          'cause': 'pain_return',
        }),
      );
    }
  }

  // 1 bis. Mode coach, figures : une étape dont le passage n'est pas acquis
  // n'est pas servie — l'étape actuelle la remplace (ou reste seule si elle
  // est déjà dans la séance).
  final board = coached
      ? SkillBoard.of(ctx, view, state, replayed.digests, day)
      : null;
  if (board != null) {
    for (final d in drafts) {
      final target = d.item.skillTargetId;
      if (d.removed ||
          target == null ||
          board.allowed(target, d.item.exerciseId)) {
        continue;
      }
      final current = board.currentStep(target);
      final substitute = current == null ? null : ctx.book.find(current);
      final why = <Reason>[
        reason(ReasonCodes.adaptSkillHold, <String, Object?>{
          'exerciseId': current ?? d.item.exerciseId,
          'weeksAtStep': board.weeksAtStep(target),
        }),
      ];
      if (substitute == null ||
          substitute.mode == null ||
          taken.contains(substitute.id)) {
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: d.item.exerciseId,
            reasons: why,
          ),
        );
        continue;
      }
      taken.add(substitute.id);
      adjustments.add(
        SessionAdjustment(
          kind: AdjustmentKind.exerciseSwapped,
          exerciseId: d.item.exerciseId,
          replacementExerciseId: substitute.id,
          reasons: why,
        ),
      );
      d.reasons.addAll(why);
      final intensity = d.item.intensity;
      d.info = substitute;
      d.item = d.item.copyWith(
        exerciseId: substitute.id,
        toCalibrate: true,
        intensity: intensity != null && intensity.referenceExerciseId != null
            ? intensity.copyWith(referenceExerciseId: substitute.id)
            : intensity,
      );
    }
  }

  // 1 ter. Mode coach : une technique au-dessus du niveau d'expérience
  // n'est pas servie (R2-P22) — séries classiques équivalentes à la place.
  if (coached) {
    final experience = ctx.profile.experience;
    final level = experience == null ? 1 : experience.index;
    for (final d in drafts) {
      final technique = d.item.technique;
      if (d.removed ||
          technique == null ||
          technique.kind == SetTechniqueKind.standard ||
          level >= techniqueAccessLevel(technique.kind)) {
        continue;
      }
      d.item = standardEquivalent(d.item);
      d.sets = d.item.sets;
      d.reasons.add(
        reason(ReasonCodes.planTechniqueWithheld, <String, Object?>{
          'technique': technique.kind.code,
          'cause': 'level',
        }),
      );
    }
  }

  // 1 quater. Mode coach : pas de test un jour de bilan bas (2 sur 5 ou
  // moins, nuit courte ; CX, correction 1) hors jour d'échéance — le test
  // est retiré, il se refait frais à une séance suivante de la semaine
  // (1 quater bis).
  if (coached && health.level >= 1) {
    var eventToday = false;
    for (final event in ctx.profile.events ?? const <SeasonEvent>[]) {
      if (event.date.dayNumber == day) {
        eventToday = true;
      }
    }
    if (!eventToday) {
      for (final d in drafts) {
        if (d.removed || d.item.kind != SetKind.test) {
          continue;
        }
        d.removed = true;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.exerciseRemoved,
            exerciseId: d.item.exerciseId,
            reasons: healthReasons,
          ),
        );
      }
    }
  }

  // 1 quater bis. Mode coach : un test de la semaine qui n'a pas été fait
  // (bilan bas, séance manquée) se fait à la séance suivante d'un bon
  // jour, au moins 48 h après, avant le travail du jour (règle du
  // programme : « un test fait un jour de bilan bas se reporte de 48 à
  // 72 h » ; R3-P16).
  // (Jamais un jour de douleur au-dessus du seuil, ni sur une zone à
  // l'arrêt.)
  final stops = coached ? state.painStops(day) : const <PainStop>[];
  if (coached && health.level == 0 && painsToday.isEmpty && week != null) {
    final doneTests = <String>{};
    for (final d in replayed.digests) {
      final ref = d.session.programRef;
      if (ref == null ||
          ref.blockId != view.block.pass1.blockId ||
          ref.weekIndex != request.weekIndex) {
        continue;
      }
      for (final set in d.session.sets) {
        if (set.kind == SetKind.test) {
          doneTests.add(set.exerciseId);
        }
      }
    }
    final today = <String>{
      for (final d in drafts)
        if (!d.removed) d.item.exerciseId,
    };
    final todayTests = drafts.any(
      (d) => !d.removed && d.item.kind == SetKind.test,
    );
    var at = 0;
    while (at < drafts.length && drafts[at].item.kind == SetKind.warmup) {
      at++;
    }
    for (final other in week.days) {
      if (todayTests || other.dayIndex == request.dayIndex) {
        continue;
      }
      final start = view.block.pass1.startDate;
      final weekday = view.block.pass1.days[other.dayIndex].weekday;
      final when =
          start.dayNumber +
          7 * request.weekIndex +
          (weekday - start.weekday) % 7;
      if (day - when < 2) {
        continue;
      }
      for (final item in other.items) {
        final info = ctx.book.find(item.exerciseId);
        if (item.kind != SetKind.test ||
            item.test == null ||
            info == null ||
            doneTests.contains(item.exerciseId) ||
            today.contains(item.exerciseId) ||
            comeback.hits(info.exercise) ||
            comeback.heldFor(info.exercise) ||
            painsToday.keys.any((z) => info.zoneLevel(z) >= 0.5) ||
            stops.any((x) => coachPainStopHits(info.exercise, x.zone))) {
          continue;
        }
        // (Jamais hors du matériel ou du lieu du jour, ni une étape de
        // figure dont le passage n'est pas acquis ; relecture du code CX,
        // correction 1.)
        final skill = item.skillTargetId;
        if ((place != null &&
                (!info.exercise.feasibleWith(equipment) ||
                    !info.exercise.places.contains(place))) ||
            (board != null &&
                skill != null &&
                !board.allowed(skill, item.exerciseId))) {
          continue;
        }
        final moved = _Draft(item, info, view.roleOf(item.slotId))
          ..sets = item.sets;
        drafts.insert(at, moved);
        at++;
        today.add(item.exerciseId);
        taken.add(item.exerciseId);
      }
    }
  }

  // 1 quinquies. Mode coach : reprise après une coupure d'au moins deux
  // semaines — pendant la semaine du retour, un cinquième de séries en
  // moins (règle du programme ; R5-P22 : pas de pic au retour).
  if (coached && replayed.digests.isNotEmpty) {
    var breakDays = 0;
    final digests = replayed.digests;
    if (day - digests.last.day >= p.coachBreakDays) {
      breakDays = day - digests.last.day;
    } else {
      for (var i = digests.length - 1; i >= 1; i--) {
        if (digests[i].day < day - 7) {
          break;
        }
        final gap = digests[i].day - digests[i - 1].day;
        if (gap >= p.coachBreakDays) {
          breakDays = gap;
          break;
        }
      }
    }
    if (breakDays > 0) {
      final why = <Reason>[
        reason(ReasonCodes.adaptResumeAfterBreak, <String, Object?>{
          'days': breakDays,
        }),
      ];
      for (final d in drafts) {
        if (d.removed ||
            d.item.kind == SetKind.test ||
            !_setsAdjustable(d.item)) {
          continue;
        }
        final kept = (d.sets * p.coachBreakSets).round();
        if (kept >= 1 && kept < d.sets) {
          adjustments.add(
            SessionAdjustment(
              kind: AdjustmentKind.setsReduced,
              exerciseId: d.item.exerciseId,
              setsDelta: kept - d.sets,
              reasons: why,
            ),
          );
          d.sets = kept;
          d.reasons.addAll(why);
        }
      }
    }
  }

  // 2. Bilan nettement bas : une série de moins par exercice (les
  // mouvements principaux gardent au moins trois séries).
  if (health.level >= 2) {
    for (final d in drafts) {
      if (d.removed || d.item.targetFlames == null) {
        continue;
      }
      if (coached && !_setsAdjustable(d.item)) {
        continue;
      }
      final floor = d.role == SlotRole.main ? 3 : 2;
      if (d.sets > floor) {
        d.sets--;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: d.item.exerciseId,
            setsDelta: -1,
            reasons: healthReasons,
          ),
        );
        d.reasons.addAll(healthReasons);
      }
    }
  }

  // 2 bis. Mode coach : douleur de 5 sur 10 sur une contrainte moyenne —
  // l'exercice est gardé avec moins de séries (R5-P23, R4-F11).
  if (coached) {
    for (final d in drafts) {
      if (d.removed || !d.regress || !_setsAdjustable(d.item)) {
        continue;
      }
      var kept = (d.sets * p.coachPainRegressSets).floor();
      if (kept < 1) {
        kept = 1;
      }
      if (kept < d.sets) {
        final why = <Reason>[
          for (final entry in painsToday.entries)
            if (entry.value >= p.coachPainRegress &&
                (d.info?.zoneLevel(entry.key) ?? 0) >= 0.5)
              reason(ReasonCodes.adaptPainReported, <String, Object?>{
                'zone': entry.key.code,
                'intensity': entry.value,
              }),
        ];
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: d.item.exerciseId,
            setsDelta: kept - d.sets,
            reasons: why,
          ),
        );
        d.sets = kept;
      }
    }
  }

  // 3. Charges, répétitions et flammes de chaque exercice.
  final wristGuard = coached && wristSensitive(view, state, comeback, day);
  final recentZones = coached
      ? recentPainZones(state, day, p)
      : const <BodyZone>{};
  var confidenceSum = 0.0;
  var confidenceCount = 0;
  for (final d in drafts) {
    if (d.removed) {
      continue;
    }
    final info = d.info;
    final item = d.item;
    if (info == null || info.mode == null) {
      continue;
    }
    final driven =
        item.targetFlames != null ||
        item.percentOfOneRm != null ||
        item.setTargets != null ||
        (coached && item.kind == SetKind.test && item.test != null);
    if (!driven) {
      continue;
    }
    final spec = view.specOf(
      info,
      item,
      weekKind,
      weekIndex: request.weekIndex,
      day: day,
    );
    final sized = SlotSpec(
      low: spec.low,
      high: spec.high,
      rir: spec.rir,
      sets: d.sets,
      restSeconds: spec.restSeconds,
      main: spec.main,
      benchmarkOk: spec.benchmarkOk,
      hasTarget: spec.hasTarget,
      test: spec.test,
      coach: spec.coach,
      coachRead: spec.coachRead,
    );
    final exercise = run.begin(info, sized);
    d.run = exercise;
    d.gated = coached;
    d.locked = coached && policy.locked;
    final coach = spec.coach;
    if (coach != null) {
      // Semaine verrouillée : aucune hausse ; plafonds de hausse du niveau.
      exercise.lockUp = policy.locked || coach.eventNear;
      final rise = coachRiseOf(coach, p);
      exercise.riseCap = spec.main || d.role == SlotRole.secondary
          ? rise
          : 2 * rise;
      if (d.regress && exercise.rirEff < 5) {
        exercise.rirEff = exercise.rirEff + 1 > 5 ? 5 : exercise.rirEff + 1;
      }
      if (health.level >= 2 &&
          item.kind != SetKind.test &&
          exercise.rirEff < p.coachLowDayRir) {
        // Bilan nettement bas : aucune série à moins de trois répétitions
        // en réserve (règle du programme, R5-P14).
        exercise.rirEff = p.coachLowDayRir;
      }
      if (item.kind == SetKind.test && view.taperedAt(day)) {
        exercise.tapered = true;
      }
      if (d.inReturn) {
        // Reprise graduée : la dose écrite au plus, loin de l'échec ;
        // quand le palier recule, aucune hausse (comme une zone
        // douloureuse).
        exercise.inReturn = true;
        exercise.doseCapped = true;
        exercise.returnPct = d.returnPct;
        if (exercise.rirEff < p.coachReturnRir) {
          exercise.rirEff = p.coachReturnRir;
        }
        final back = d.returnBack;
        if (back != null && !exercise.painZones.contains(back)) {
          exercise.painZones = <BodyZone>[...exercise.painZones, back];
        }
      }
      for (final zone in recentZones) {
        if (info.zoneLevel(zone) >= 0.5) {
          exercise.recentZone = true;
          break;
        }
      }
      if (wristGuard && coachPainStopHits(info.exercise, BodyZone.wristHand)) {
        // Appui du poignet sensible (gêne déclarée, signalée ces deux
        // dernières semaines, arrêt ou reprise) : la dose d'appui écrite par
        // le bloc n'est jamais dépassée.
        exercise.doseCapped = true;
      }
    }
    confidenceCount++;
    final track = exercise.track;
    if (track == null) {
      d.reasons.add(
        reason(ReasonCodes.adaptCalibration, <String, Object?>{'session': 1}),
      );
      continue;
    }
    final sd = track.filter.loadSd(exercise.nPlan, withDay: false);
    confidenceSum += clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1);
    if (coach != null) {
      for (final r in d.reasons) {
        if (r.code == ReasonCodes.planTechniqueWithheld) {
          // Technique retirée pour le niveau : séries classiques
          // équivalentes, sans série ajoutée.
          exercise.techniqueWithheld = true;
        }
      }
      final plans = coachPlans(run, exercise, item, d.sets);
      final kept = exercise.lines;
      if (kept != null && kept < d.sets) {
        // Moins de lignes que le bloc (douleur, alerte de surmenage) :
        // le temps de séance et la règle générale en tiennent compte.
        d.sets = kept;
      }
      if (plans != null) {
        if (exercise.split && plans.length > d.sets) {
          // Séries fractionnées : plus de lignes, plus courtes.
          d.sets = plans.length;
        }
        exercise.plan = List<SetPlan?>.of(plans);
        d.plans = plans;
        d.coached = true;
      }
    }
    if (!d.coached) {
      d.plans = _plansFor(run, exercise, item, d.sets);
      if (coach != null && !policy.build) {
        d.plans = _withinBlock(d.plans!, sized);
        exercise.plan = List<SetPlan?>.of(d.plans!);
      }
    }
    if (health.level >= 1 &&
        info.mode == CapacityMode.loaded &&
        health.shift < 0) {
      adjustments.add(
        SessionAdjustment(
          kind: AdjustmentKind.loadReduced,
          exerciseId: info.id,
          loadFactor: roundTo(exp(health.shift), 3),
          reasons: healthReasons,
        ),
      );
    }
  }
  run.closeAll();

  // 4. Temps disponible aujourd'hui : la séance est raccourcie en gardant
  // les priorités.
  final available = check?.minutesAvailable;
  if (available != null) {
    double total() {
      var sum = 0.0;
      for (final d in drafts) {
        if (!d.removed) {
          sum += itemSeconds(d.item, d.sets, p);
        }
      }
      return sum;
    }

    final planned = (total() / 60).ceil();
    final budget = available * 60.0;
    if (total() > budget) {
      final why = <Reason>[
        reason(ReasonCodes.adaptTimeShort, <String, Object?>{
          'minutesAvailable': available,
          'minutesPlanned': planned,
        }),
      ];
      sessionReasons.addAll(why);
      final cut = <_Draft, int>{};
      bool trim(Set<SlotRole?> roles, int floor) {
        for (final d in drafts.reversed) {
          if (!d.removed && roles.contains(d.role) && d.sets > floor) {
            d.sets--;
            cut[d] = (cut[d] ?? 0) + 1;
            return true;
          }
        }
        return false;
      }

      bool remove(Set<SlotRole?> roles) {
        for (final d in drafts.reversed) {
          if (!d.removed && roles.contains(d.role)) {
            d.removed = true;
            cut.remove(d);
            adjustments.add(
              SessionAdjustment(
                kind: AdjustmentKind.exerciseRemoved,
                exerciseId: d.item.exerciseId,
                reasons: why,
              ),
            );
            return true;
          }
        }
        return false;
      }

      const easy = <SlotRole?>{SlotRole.cooldown, SlotRole.mobility};
      const light = <SlotRole?>{
        SlotRole.accessory,
        SlotRole.core,
        SlotRole.conditioning,
        null,
      };
      const heavy = <SlotRole?>{
        SlotRole.main,
        SlotRole.secondary,
        SlotRole.skill,
      };
      var guard = 0;
      while (total() > budget && guard < 400) {
        guard++;
        if (remove(easy)) {
          continue;
        }
        if (trim(light, 2)) {
          continue;
        }
        if (remove(light)) {
          continue;
        }
        if (trim(heavy, 2)) {
          continue;
        }
        if (remove(const <SlotRole?>{SlotRole.warmup})) {
          continue;
        }
        if (remove(const <SlotRole?>{SlotRole.skill, SlotRole.secondary})) {
          continue;
        }
        if (trim(heavy, 1)) {
          continue;
        }
        break;
      }
      for (final entry in cut.entries) {
        entry.key.reasons.addAll(why);
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: entry.key.item.exerciseId,
            setsDelta: -entry.value,
            reasons: why,
          ),
        );
      }
    }
  }

  // 5. Mise en forme.
  final items = <ExercisePrescription>[
    for (final d in drafts)
      if (!d.removed)
        d.coached
            ? _finishCoach(ctx, run, d)
            : (coached
                  ? coherentTechnique(_finish(ctx, run, d))
                  : _finish(ctx, run, d)),
  ];
  List<GroupSpec>? groups;
  String? eventId;
  if (coached) {
    final used = <String>{
      for (final item in items)
        if (item.groupId != null) item.groupId!,
    };
    final kept = <GroupSpec>[
      for (final g in dayPrescription.groups ?? const <GroupSpec>[])
        if (used.contains(g.groupId)) g,
    ];
    groups = kept.isEmpty ? null : kept;
    for (final event in ctx.profile.events ?? const <SeasonEvent>[]) {
      if (event.date.dayNumber == day) {
        eventId = event.id;
      }
    }
  }
  return SessionPlan(
    date: today,
    blockId: view.block.pass1.blockId,
    weekIndex: request.weekIndex,
    dayIndex: request.dayIndex,
    items: items,
    adjustments: adjustments,
    confidence: confidenceCount == 0
        ? 0.5
        : roundTo(confidenceSum / confidenceCount, 3),
    reasons: sessionReasons,
    phase: coached ? policy.phase : null,
    weekIntent: coached ? policy.intent : null,
    eventId: eventId,
    groups: groups,
  );
}

/// La prescription [item] dont la technique est rendue cohérente avec son
/// nombre de lignes (`sets`) : séries allégées et intervalles recomptés ;
/// une technique à paliers ou un bloc au temps dont le nombre de lignes ne
/// tient plus laisse la place à des séries classiques.
ExercisePrescription coherentTechnique(ExercisePrescription item) {
  final t = item.technique;
  if (t == null || t.lastSetOnly == true) {
    return item;
  }
  final sets = item.sets;
  ExercisePrescription plain() {
    final rules = <AutoregulationRule>[
      for (final r in item.autoregulation ?? const <AutoregulationRule>[])
        if (r.kind != AutoregulationKind.backoffFromTopSet &&
            r.kind != AutoregulationKind.stopOnRepDrop)
          r,
    ];
    return item.copyWith(
      technique: null,
      autoregulation: rules.isEmpty ? null : rules,
    );
  }

  switch (t.kind) {
    case SetTechniqueKind.topSetBackoff:
      final backoff = t.backoffSets;
      if (sets < 2) {
        return plain();
      }
      return backoff != null && backoff >= sets
          ? item.copyWith(technique: t.copyWith(backoffSets: sets - 1))
          : item;
    case SetTechniqueKind.emom:
      return t.intervals == sets
          ? item
          : item.copyWith(technique: t.copyWith(intervals: sets));
    case SetTechniqueKind.wave:
      final reps = t.waveReps;
      final waves = t.waves;
      return reps != null && waves != null && waves * reps.length != sets
          ? plain()
          : item;
    case SetTechniqueKind.pyramid:
      final reps = t.pyramidReps;
      return reps != null && reps.length != sets ? plain() : item;
    case SetTechniqueKind.ladder:
      final start = t.ladderStart;
      final step = t.ladderStep;
      final top = t.ladderTop;
      if (start == null || step == null || top == null || step <= 0) {
        return item;
      }
      final rungs = ((top - start) ~/ step + 1) * (t.ladderCount ?? 1);
      return rungs != sets ? plain() : item;
    case SetTechniqueKind.density:
    case SetTechniqueKind.forTime:
      return sets != 1 ? plain() : item;
    case SetTechniqueKind.standard:
    case SetTechniqueKind.cluster:
    case SetTechniqueKind.restPause:
    case SetTechniqueKind.myoReps:
    case SetTechniqueKind.dropSet:
    case SetTechniqueKind.isometricHold:
    case SetTechniqueKind.accentuatedEccentric:
    case SetTechniqueKind.contrast:
    case SetTechniqueKind.amrap:
    case SetTechniqueKind.skillPractice:
      return item;
  }
}

/// La prescription [item] sans sa technique : séries classiques au même
/// travail approché. Paliers (vagues, échelle, pyramide) : autant de séries
/// que de paliers, au nombre médian de répétitions ; bloc au temps
/// (densité, contre la montre) : trois séries d'un quart du total ; les
/// autres techniques gardent leurs séries et leur plage.
ExercisePrescription standardEquivalent(ExercisePrescription item) {
  final t = item.technique;
  if (t == null) {
    return item;
  }
  int median(List<int> reps) {
    final sorted = List<int>.of(reps)..sort();
    return sorted[sorted.length ~/ 2];
  }

  var sets = item.sets;
  var low = item.repsLow;
  var high = item.repsHigh;
  final kind = t.kind;
  final wave = t.waveReps;
  final pyramid = t.pyramidReps;
  if (kind == SetTechniqueKind.wave && wave != null && wave.isNotEmpty) {
    low = median(wave);
    high = low;
  } else if (kind == SetTechniqueKind.pyramid &&
      pyramid != null &&
      pyramid.isNotEmpty) {
    low = median(pyramid);
    high = low;
  } else if (kind == SetTechniqueKind.ladder) {
    final start = t.ladderStart;
    final top = t.ladderTop;
    if (start != null && top != null) {
      low = (start + top) ~/ 2;
      high = low;
    }
  } else if ((kind == SetTechniqueKind.density ||
          kind == SetTechniqueKind.forTime) &&
      low != null &&
      high != null) {
    final total = t.totalRepsTarget ?? high;
    final each = total ~/ 4 < 1 ? 1 : total ~/ 4;
    sets = total < 4 ? 1 : 3;
    low = each;
    high = each;
  } else if (kind == SetTechniqueKind.cluster) {
    final mini = t.miniSets;
    final each = t.miniSetReps;
    if (mini != null && each != null && low != null && high != null) {
      // Série d'une traite : deux tiers du total fractionné.
      final whole = (2 * mini * each + 2) ~/ 3;
      low = whole < 1 ? 1 : whole;
      high = low;
    }
  }
  final rules = <AutoregulationRule>[
    for (final r in item.autoregulation ?? const <AutoregulationRule>[])
      if (r.kind != AutoregulationKind.backoffFromTopSet &&
          r.kind != AutoregulationKind.stopOnRepDrop)
        r,
  ];
  return item.copyWith(
    sets: sets,
    repsLow: low,
    repsHigh: high,
    technique: null,
    setTargets: null,
    autoregulation: rules.isEmpty ? null : rules,
  );
}

/// Vrai si l'appui du poignet est sensible au jour [day] : gêne déclarée
/// au profil ou antécédent récent, gêne signalée depuis deux semaines,
/// arrêt ou reprise graduée en cours (CA2, partie 0).
bool wristSensitive(
  BlockView view,
  ModelState state,
  PainReturn comeback,
  int day,
) {
  const zone = BodyZone.wristHand;
  if (view.fragileZones.contains(zone) ||
      comeback.zones.contains(zone) ||
      comeback.held.contains(zone)) {
    return true;
  }
  final s = state.pains[zone];
  if (s == null) {
    return false;
  }
  if (s.stopAt(day) != null) {
    return true;
  }
  for (final r in s.reportsBetween(day - 13, day)) {
    if (r >= 1) {
      return true;
    }
  }
  return false;
}

/// Vrai si le nombre de séries de [item] peut être réduit le jour même sans
/// défaire sa technique (les techniques dont `sets` compte des paliers ou
/// des intervalles sont servies entières ou pas du tout).
bool _setsAdjustable(ExercisePrescription item) {
  if (item.kind == SetKind.test) {
    return false;
  }
  final kind = item.technique?.kind;
  return kind == null ||
      kind == SetTechniqueKind.standard ||
      kind == SetTechniqueKind.topSetBackoff ||
      kind == SetTechniqueKind.isometricHold ||
      kind == SetTechniqueKind.skillPractice ||
      kind == SetTechniqueKind.restPause ||
      kind == SetTechniqueKind.myoReps ||
      kind == SetTechniqueKind.dropSet ||
      kind == SetTechniqueKind.accentuatedEccentric ||
      kind == SetTechniqueKind.contrast ||
      kind == SetTechniqueKind.amrap;
}

/// Cibles de la règle générale ramenées dans la plage du bloc : une
/// semaine d'allègement, d'affûtage, de test ou de compétition ne reçoit ni
/// plage étendue ni série repère.
List<SetPlan> _withinBlock(List<SetPlan> plans, SlotSpec spec) {
  return <SetPlan>[
    for (final s in plans)
      SetPlan(
        loadKg: s.loadKg,
        low: s.low > spec.high ? spec.high : s.low,
        high: s.high > spec.high ? spec.high : s.high,
        flames: s.benchmark ? flamesOfRir(spec.rir) : s.flames,
        open: s.open && !s.benchmark && s.low < spec.high,
        role: s.role,
      ),
  ];
}

/// Raisons de tolérance tirées des réponses de récupération et de vie du
/// profil (schéma 3) : sommeil habituel court, stress élevé, métier
/// physique, déficit énergétique.
List<Reason> recoveryReasons(AthleteProfile profile) {
  final out = <Reason>[];
  void add(String factor, String level) {
    out.add(
      reason(ReasonCodes.adaptRecoveryProfile, <String, Object?>{
        'factor': factor,
        'level': level,
      }),
    );
  }

  final sleep = profile.sleep;
  if (sleep == SleepBand.under6Hours) {
    add('sleep', SleepBand.under6Hours.code);
  }
  final stress = profile.stress;
  if (stress == StressBand.high) {
    add('stress', StressBand.high.code);
  }
  final job = profile.occupationalLoad;
  if (job == OccupationalLoad.heavy) {
    add('occupational_load', OccupationalLoad.heavy.code);
  }
  final goal = profile.bodyWeightGoal;
  if (goal == BodyWeightGoal.lose) {
    add('body_weight_goal', BodyWeightGoal.lose.code);
  }
  return out;
}

/// Vrai si le profil déclare une récupération réduite (sommeil habituel
/// sous 6 h, stress élevé ou métier physique lourd) : aucune hausse de
/// volume n'est proposée tant que cela dure (R5-P14, R5-P15, R5-P18).
bool recoveryLimited(AthleteProfile profile) =>
    profile.sleep == SleepBand.under6Hours ||
    profile.stress == StressBand.high ||
    profile.occupationalLoad == OccupationalLoad.heavy;

/// La prescription [item] portée sur l'exercice de remplacement
/// [substitute] : mêmes séries, même plage, même cible ; la charge sera
/// celle du modèle, ou à calibrer.
ExercisePrescription _retarget(
  ExercisePrescription item,
  ExerciseInfo substitute,
) {
  final e = substitute.exercise;
  LoadBasis basis;
  switch (e.loadType) {
    case LoadType.addedWeight:
      basis = LoadBasis.bodyweightPlusExternal;
    case LoadType.barbell:
    case LoadType.dumbbells:
    case LoadType.kettlebell:
    case LoadType.machine:
    case LoadType.cable:
    case LoadType.other:
      basis = LoadBasis.external;
    case LoadType.bodyweight:
      basis = LoadBasis.bodyweight;
    case LoadType.none:
    case LoadType.band:
      basis = LoadBasis.unloaded;
  }
  return ExercisePrescription(
    slotId: item.slotId,
    exerciseId: e.id,
    sets: item.sets,
    repsLow: item.repsLow,
    repsHigh: item.repsHigh,
    secondsLow: item.secondsLow,
    secondsHigh: item.secondsHigh,
    distanceMeters: item.distanceMeters,
    calories: item.calories,
    targetFlames: item.targetFlames,
    restSeconds: item.restSeconds,
    toCalibrate: true,
    loadBasis: basis,
    groupId: item.groupId,
    format: item.format,
    kind: item.kind,
    reasons: item.reasons,
  );
}

/// Cibles des séries d'un exercice suivi : règle générale (RIR visé), ou
/// consignes propres de la prescription (cibles série par série d'un
/// test, part du 1RM d'un programme importé).
List<SetPlan> _plansFor(
  SessionRun run,
  ExerciseRun exercise,
  ExercisePrescription item,
  int sets,
) {
  final p = run.ctx.params;
  final info = exercise.info;
  final track = exercise.track!;
  final f = track.filter;
  final targets = item.setTargets;
  final loaded = info.mode == CapacityMode.loaded;
  final bw = info.fraction * run.bodyWeightKg;
  double capped(double kg) {
    // Mêmes garde-fous que la règle générale : aucune hausse après un échec
    // non prévu, une douleur ou un bilan bas ; plafond de hausse.
    final last = track.lastLoad;
    if (last == null) {
      return kg;
    }
    final floored = info.grid.floor(last);
    final start = floored > last ? last : floored;
    if ((track.noUp || exercise.painZones.isNotEmpty || run.noIncrease) &&
        kg > start) {
      return start;
    }
    if (exercise.spec.test) {
      // Un test mesure : il se fait à l'effort demandé, sans plafond de
      // hausse (les trois verrous ci-dessus tiennent).
      return kg;
    }
    final rise = exercise.calibrating
        ? p.maxUpCalibration
        : (exercise.spec.main ? p.maxUpMain : p.maxUpOther);
    final cap = info.grid.floor((last + bw) * (1 + rise) - bw);
    final ceiling = cap < start ? start : cap;
    return kg > ceiling ? ceiling : kg;
  }

  if (loaded && targets != null && targets.isNotEmpty) {
    // Cibles série par série (montée d'un test) : chaque charge est celle
    // que le modèle prévoit pour les répétitions et les flammes dites.
    final out = <SetPlan>[];
    for (var i = 0; i < sets; i++) {
      final t = targets[i < targets.length ? i : targets.length - 1];
      final high = t.repsHigh ?? t.repsLow ?? exercise.spec.high;
      final low = t.repsLow ?? high;
      final flames =
          t.flames ?? item.targetFlames ?? flamesOfRir(exercise.rirEff);
      final rir = rirOfFlames(flames) + (exercise.rirEff - exercise.spec.rir);
      final shift = -run.quantileZ(rir) * f.loadSd(high + rir);
      final ideal = exp(f.logLoadFor(high + rir, shift: shift)) - bw;
      final kg = capped(
        info.grid.floor(ideal < info.grid.minimum ? info.grid.minimum : ideal),
      );
      out.add(SetPlan(loadKg: kg, low: low, high: high, flames: flames));
    }
    exercise.plan = List<SetPlan?>.of(out);
    return out;
  }
  final share = item.percentOfOneRm;
  if (loaded && item.targetFlames == null && share != null) {
    // Programme importé : la charge est la part dite du 1RM estimé ; les
    // flammes pré-remplies sont celles que le modèle prévoit.
    final ideal = share * f.capacity - bw;
    final kg = capped(
      info.grid.nearest(ideal < info.grid.minimum ? info.grid.minimum : ideal),
    );
    final high = exercise.spec.high;
    final possible = f.repsPossible(ln(info.totalLoad(kg, run.bodyWeightKg)));
    final out = <SetPlan>[];
    for (var i = 0; i < sets; i++) {
      final fatigue = plannedFatigue(i, 3, exercise.spec.restSeconds, p);
      final rir = possible * (1 - fatigue) - high;
      out.add(
        SetPlan(
          loadKg: kg,
          low: exercise.spec.low,
          high: high,
          flames: flamesOfRir(rir < 0 ? 0.0 : rir),
        ),
      );
    }
    exercise.plan = List<SetPlan?>.of(out);
    return out;
  }
  return run.planSets(exercise);
}

ExercisePrescription _finish(EngineContext ctx, SessionRun run, _Draft d) {
  final p = ctx.params;
  var item = d.item;
  final plans = d.plans;
  final exercise = d.run;
  final reasons = <Reason>[...item.reasons, ...d.reasons];
  // Bloc au contrat 0.4.0 servi par la règle générale (pas encore de suivi
  // ou pas de part du 1RM) : une technique qui mène près de l'échec n'est
  // pas servie en semaine verrouillée, un jour de bilan nettement bas ou
  // sur une zone douloureuse.
  final technique = item.technique;
  if (d.gated &&
      technique != null &&
      techniqueIntensifies(technique.kind) &&
      (d.locked ||
          run.health.level >= 2 ||
          (exercise != null && exercise.painZones.isNotEmpty))) {
    reasons.add(
      reason(ReasonCodes.planTechniqueWithheld, <String, Object?>{
        'technique': technique.kind.code,
        'cause': d.locked
            ? 'phase'
            : (run.health.level >= 2 ? 'health' : 'pain'),
      }),
    );
    final sets = d.sets;
    item = standardEquivalent(item);
    if (item.sets != sets &&
        technique.kind != SetTechniqueKind.density &&
        technique.kind != SetTechniqueKind.forTime) {
      item = item.copyWith(sets: sets);
    }
  }
  if (plans == null || exercise == null || plans.isEmpty) {
    // Exercice non modélisé, ou sans a priori : la prescription du bloc,
    // au nombre de séries du jour.
    final written = item.secondsHigh;
    if (exercise != null &&
        exercise.spec.coach != null &&
        exercise.track == null &&
        exercise.info.mode == CapacityMode.hold &&
        item.kind != SetKind.test &&
        written != null &&
        written >= 3) {
      // Mode coach, premier maintien d'un exercice dont le maximum n'est
      // pas connu : tenue repère — jusqu'à la durée écrite par le bloc,
      // arrêt avant la perte de position. Elle dit d'où part la
      // progression (les hausses suivantes se comptent depuis ce qui a été
      // tenu).
      return item.copyWith(
        sets: d.sets,
        secondsLow: written ~/ 3 < 1 ? 1 : written ~/ 3,
        secondsHigh: written,
        targetFlames: flamesOfRir(2),
        setTargets: unset,
        toCalibrate: true,
        reasons: <Reason>[
          ...reasons,
          reason(ReasonCodes.adaptBenchmarkSet, <String, Object?>{'rir': 2.0}),
        ],
      );
    }
    final targets = item.setTargets;
    return item.copyWith(
      sets: d.sets,
      setTargets: targets == null
          ? unset
          : <SetTarget>[
              for (var i = 0; i < d.sets; i++)
                targets[i < targets.length ? i : targets.length - 1],
            ],
      toCalibrate: item.toCalibrate || (exercise != null && !exercise.modelled),
      reasons: reasons,
    );
  }
  final info = exercise.info;
  final track = exercise.track!;
  final used = plans.length > d.sets ? plans.sublist(0, d.sets) : plans;
  final hold = info.mode == CapacityMode.hold;
  final loaded = info.mode == CapacityMode.loaded;
  var low = exercise.spec.low;
  var high = exercise.spec.high;
  for (final s in used) {
    if (s.low < low) {
      low = s.low;
    }
    if (s.high > high) {
      high = s.high;
    }
  }
  final first = used.first;
  final firstLoad = first.loadKg;
  if (exercise.calibrating) {
    reasons.add(
      reason(ReasonCodes.adaptCalibration, <String, Object?>{
        'session': track.filter.sessions + 1,
      }),
    );
  } else if (exercise.uncertain) {
    final sd = track.filter.loadSd(exercise.nPlan, withDay: false);
    reasons.add(
      reason(ReasonCodes.adaptLowConfidence, <String, Object?>{
        'confidence': roundTo(
          clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1),
          3,
        ),
      }),
    );
  }
  final last = track.lastLoad;
  if (loaded && firstLoad != null && last != null) {
    final delta = roundTo(firstLoad - last, 2);
    if (delta > 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadUp, <String, Object?>{'deltaKg': delta}),
      );
    } else if (delta < 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadDown, <String, Object?>{'deltaKg': -delta}),
      );
    }
  }
  final held = exercise.heldCause;
  if (held != null) {
    reasons.add(
      reason(ReasonCodes.adaptLoadHeld, <String, Object?>{'cause': held}),
    );
  }
  if (exercise.coarse && firstLoad != null) {
    reasons.add(
      reason(ReasonCodes.adaptIncrementCoarse, <String, Object?>{
        'stepKg': roundTo(info.grid.stepAbove(firstLoad), 3),
      }),
    );
  }
  for (final zone in exercise.painZones) {
    final state = run.state.pains[zone];
    final r = reason(ReasonCodes.adaptPainReported, <String, Object?>{
      'zone': zone.code,
      'intensity': state?.lastIntensity ?? 0,
    });
    if (!reasons.contains(r)) {
      reasons.add(r);
    }
  }
  if (exercise.easyMode) {
    reasons.add(
      reason(ReasonCodes.adaptFlamesBelowTarget, <String, Object?>{
        'delta': p.adviceGapFlames.toDouble(),
        'sets': track.easySets,
      }),
    );
  }
  if (used.last.benchmark) {
    reasons.add(
      reason(ReasonCodes.adaptBenchmarkSet, <String, Object?>{
        'rir': rirOfFlames(used.last.flames),
      }),
    );
  }
  double? share;
  if (loaded && firstLoad != null) {
    final total = info.totalLoad(firstLoad, run.bodyWeightKg);
    final value = total / track.filter.capacity;
    share = roundTo(clampDouble(value, 0, 1.5), 3);
  }
  return ExercisePrescription(
    slotId: item.slotId,
    exerciseId: item.exerciseId,
    sets: used.length,
    repsLow: hold ? null : low,
    repsHigh: hold ? null : high,
    secondsLow: hold ? low : null,
    secondsHigh: hold ? high : null,
    targetFlames: flamesOfRir(exercise.rirEff),
    restSeconds: item.restSeconds,
    startLoadKg: loaded && firstLoad != null ? roundTo(firstLoad, 2) : null,
    percentOfOneRm: share,
    toCalibrate: exercise.uncertain,
    loadBasis: item.loadBasis,
    setTargets: <SetTarget>[
      for (final s in used)
        SetTarget(
          repsLow: hold ? null : s.low,
          repsHigh: hold ? null : s.high,
          secondsLow: hold ? s.low : null,
          secondsHigh: hold ? s.high : null,
          loadKg: s.loadKg == null ? null : roundTo(s.loadKg!, 2),
          flames: s.flames,
        ),
    ],
    groupId: item.groupId,
    format: item.format,
    kind: item.kind,
    reasons: reasons,
  );
}

/// Prescription d'un exercice dont les cibles viennent du mode coach : la
/// prescription du bloc, avec les charges, les répétitions et les flammes
/// du jour, sa technique (ajustée au nombre de séries, ou retirée quand un
/// prérequis manque) et les raisons des décisions.
ExercisePrescription _finishCoach(EngineContext ctx, SessionRun run, _Draft d) {
  final p = ctx.params;
  final item = d.item;
  final exercise = d.run!;
  final plans = d.plans!;
  final coach = exercise.spec.coach!;
  final info = exercise.info;
  final track = exercise.track!;
  final used = plans.length > d.sets ? plans.sublist(0, d.sets) : plans;
  final hold = info.mode == CapacityMode.hold;
  final loaded = info.mode == CapacityMode.loaded;
  final reasons = <Reason>[...item.reasons, ...d.reasons, ...exercise.notes];

  for (final s in used) {
    if (s.benchmark) {
      reasons.add(
        reason(ReasonCodes.adaptBenchmarkSet, <String, Object?>{
          'rir': rirOfFlames(s.flames),
        }),
      );
      break;
    }
  }
  // Technique servie, cohérente avec le nombre de lignes du jour.
  var technique = exercise.techniqueWithheld ? null : item.technique;
  var keepRange = false;
  if (technique != null) {
    final kind = technique.kind;
    if (technique.lastSetOnly == true) {
      keepRange = true;
    } else if (kind == SetTechniqueKind.topSetBackoff) {
      technique = used.length < 2
          ? null
          : technique.copyWith(backoffSets: used.length - 1);
    } else if (kind == SetTechniqueKind.emom) {
      technique = technique.copyWith(intervals: used.length);
    } else if (kind == SetTechniqueKind.wave ||
        kind == SetTechniqueKind.pyramid ||
        kind == SetTechniqueKind.ladder) {
      if (used.length == item.sets) {
        keepRange = true;
      } else {
        technique = null;
      }
    } else if (kind == SetTechniqueKind.cluster) {
      keepRange = true;
    } else if ((kind == SetTechniqueKind.density ||
            kind == SetTechniqueKind.forTime) &&
        used.length != 1) {
      technique = null;
    }
  }
  var low = used.first.low;
  var high = used.first.high;
  if (keepRange) {
    low = (hold ? item.secondsLow : item.repsLow) ?? low;
    high = (hold ? item.secondsHigh : item.repsHigh) ?? high;
  } else if (technique?.kind != SetTechniqueKind.topSetBackoff) {
    for (final s in used) {
      if (s.low < low) {
        low = s.low;
      }
      if (s.high > high) {
        high = s.high;
      }
    }
  }

  final first = used.first;
  final firstLoad = first.loadKg;
  if (exercise.calibrating) {
    reasons.add(
      reason(ReasonCodes.adaptCalibration, <String, Object?>{
        'session': track.filter.sessions + 1,
      }),
    );
  } else if (exercise.uncertain) {
    final sd = track.filter.loadSd(exercise.nPlan, withDay: false);
    reasons.add(
      reason(ReasonCodes.adaptLowConfidence, <String, Object?>{
        'confidence': roundTo(
          clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1),
          3,
        ),
      }),
    );
  }
  // Hausse ou baisse : par rapport à la dernière séance du même
  // emplacement, à schéma égal.
  final mark = track.slotMarks[coach.slotId];
  final markLoad = mark != null && mark.amount == coach.schemeAmount
      ? mark.loadKg
      : null;
  if (loaded && firstLoad != null && markLoad != null) {
    final delta = roundTo(firstLoad - markLoad, 2);
    if (delta > 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadUp, <String, Object?>{'deltaKg': delta}),
      );
    } else if (delta < 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadDown, <String, Object?>{'deltaKg': -delta}),
      );
    }
  }
  final held = exercise.heldCause;
  if (held != null) {
    reasons.add(
      reason(ReasonCodes.adaptLoadHeld, <String, Object?>{'cause': held}),
    );
  }
  for (final zone in exercise.painZones) {
    final state = run.state.pains[zone];
    // (La douleur montrée est celle du journal : un bilan qui n'a pas cité
    // la zone ne la ramène pas à 0 tant que le signalement est récent.)
    final r = reason(ReasonCodes.adaptPainReported, <String, Object?>{
      'zone': zone.code,
      'intensity': state?.shownIntensity(run.day, p.painClearDays) ?? 0,
    });
    if (!reasons.contains(r)) {
      reasons.add(r);
    }
  }
  if (technique != null && technique.kind != SetTechniqueKind.standard) {
    reasons.add(
      reason(ReasonCodes.adaptTechniqueExecuted, <String, Object?>{
        'technique': technique.kind.code,
      }),
    );
  }

  double? share;
  if (loaded && firstLoad != null) {
    final total = info.totalLoad(firstLoad, run.bodyWeightKg);
    share = roundTo(clampDouble(total / track.filter.capacity, 0, 1.5), 3);
  }
  final test = item.kind == SetKind.test;
  final flames = test ? item.targetFlames : flamesOfRir(exercise.rirEff);
  // Deux écritures de la même intensité doivent s'accorder (contrat de
  // kalis_core) : l'intensité rendue est celle du jour.
  var intensity = item.intensity;
  if (intensity != null) {
    if (intensity.basis == IntensityBasis.percentOneRm &&
        intensity.referenceExerciseId == null) {
      intensity = share == null
          ? null
          : IntensityTarget(
              basis: IntensityBasis.percentOneRm,
              value: share,
              rirCap: intensity.rirCap,
            );
    } else if (intensity.basis == IntensityBasis.rir) {
      intensity = flames == null
          ? null
          : IntensityTarget(
              basis: IntensityBasis.rir,
              value: rirOfFlames(flames),
            );
    }
  }
  return item.copyWith(
    sets: used.length,
    repsLow: hold ? null : low,
    repsHigh: hold ? null : high,
    secondsLow: hold ? low : null,
    secondsHigh: hold ? high : null,
    targetFlames: flames,
    startLoadKg:
        loaded && firstLoad != null && item.loadBasis != LoadBasis.unloaded
        ? roundTo(firstLoad, 2)
        : null,
    percentOfOneRm: share,
    toCalibrate: exercise.uncertain,
    setTargets: <SetTarget>[
      for (final s in used)
        SetTarget(
          repsLow: hold ? null : s.low,
          repsHigh: hold ? null : s.high,
          secondsLow: hold ? s.low : null,
          secondsHigh: hold ? s.high : null,
          loadKg: s.loadKg == null ? null : roundTo(s.loadKg!, 2),
          flames: s.flames,
          role: s.role,
        ),
    ],
    reasons: reasons,
    technique: technique,
    intensity: intensity,
  );
}

/// Part du 1RM la plus haute permise au palier de reprise [share] (règle de
/// `kalis_plan`, CX correction 1 : 67,5 % au premier palier, +2,5 % par
/// palier de 10 %).
double _returnLoadAt(double share, AdaptParams p) =>
    0.675 + 0.25 * clampDouble(share - p.coachReturnStart, 0, 1);

/// Zones à l'arrêt au jour [day] ou sorties d'un arrêt depuis
/// [AdaptParams.coachReturnWatchDays] jours au plus (CA2, partie 0 : la
/// quantité par série des mouvements qui les chargent monte de 10 % au plus
/// d'une séance à la suivante).
Set<BodyZone> recentPainZones(ModelState state, int day, AdaptParams p) {
  final out = <BodyZone>{};
  for (final s in state.pains.values) {
    if (s.stopAt(day) != null) {
      out.add(s.zone);
      continue;
    }
    final lift = s.liftedOn(day);
    if (lift != null && day - lift <= p.coachReturnWatchDays) {
      out.add(s.zone);
    }
  }
  return out;
}

/// Vrai si la séance du jour [day] porte le rappel de l'arrêt de la zone
/// suivie par [s] : première séance de l'arrêt, puis première séance de
/// chaque semaine d'arrêt.
bool _stopNoticeDue(PainState? s, int day) {
  if (s == null) {
    return true;
  }
  // Début de l'arrêt : premier jour, en remontant les signalements, où
  // l'arrêt est déjà en cours.
  var start = day;
  int? previous;
  for (var i = s.history.length - 1; i >= 0; i--) {
    final d = s.history[i].$1;
    if (d >= day) {
      continue;
    }
    previous ??= d;
    if (s.stopAt(d) == null) {
      break;
    }
    start = d;
  }
  if (previous == null || previous < start) {
    return true;
  }
  return (day - start) ~/ 7 > (previous - start) ~/ 7;
}
