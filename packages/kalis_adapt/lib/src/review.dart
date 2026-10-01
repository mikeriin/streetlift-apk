/// Revue complète : résumé d'adaptation, propositions (volume, décharge,
/// échange d'exercice, restructurations), records, journal du moteur et
/// état. Règles de décision : `CONTRAT.md`, § Décisions.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart'
    show MuscleGroup, deloadRirBonus, deloadVolumeFactor, volumeBandsByLevel;

import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'params.dart';
import 'replay.dart';
import 'session.dart';
import 'version.dart';

/// Proposition candidate avant les filtres (déblocage, confiance, utilité,
/// refus récents).
final class _Candidate {
  _Candidate({
    required this.family,
    required this.kind,
    required this.scope,
    required this.level,
    required this.confidence,
    required this.progress,
    required this.risk,
    required this.fatigue,
    required this.adherence,
    required this.reasons,
    this.exerciseId,
    this.diff,
  });

  /// Clé stable de la proposition hors semaine (`volume:chest:up`).
  final String family;
  final ProposalKind kind;
  final ProposalScope scope;
  final UnlockLevel level;
  final double confidence;

  /// Progrès attendu (terme positif de l'utilité).
  final double progress;

  /// Risque.
  final double risk;

  /// Coût de fatigue (négatif : la proposition soulage).
  final double fatigue;

  /// Coût d'adhésion (changement d'habitude, temps).
  final double adherence;
  final List<Reason> reasons;
  final String? exerciseId;
  PlanDiff? diff;
  ProgramBlock? block;

  /// Jour visé (restructuration d'une séance).
  int? dayIndex;

  double get utility => progress - risk - fatigue - adherence;
}

/// Semaine civile (lundi → dimanche) d'un numéro de jour : le 1er janvier
/// 1970 était un jeudi.
int weekOfDay(int day) => (day + 3) ~/ 7;

/// Jour civil de la séance [dayIndex] de la semaine [weekIndex] du bloc.
int scheduledDay(Pass1Plan pass1, int weekIndex, int dayIndex) {
  final start = pass1.startDate;
  final weekday = pass1.days[dayIndex].weekday;
  final offset = (weekday - start.weekday) % 7;
  return start.dayNumber + 7 * weekIndex + offset;
}

/// Niveau de déblocage (D5.7) pour [weeks] semaines de données et [blocks]
/// blocs terminés.
UnlockLevel unlockLevelFor(int weeks, int blocks, AdaptParams p) {
  if (blocks >= 2 && weeks >= p.blockRestructureMinWeeks) {
    return UnlockLevel.blockRestructure;
  }
  if (blocks >= 1 && weeks >= p.sessionRestructureMinWeeks) {
    return UnlockLevel.sessionRestructure;
  }
  if (weeks >= p.swapMinWeeks) {
    return UnlockLevel.exerciseSwap;
  }
  if (weeks >= p.volumeMinWeeks) {
    return UnlockLevel.volume;
  }
  return UnlockLevel.loadsReps;
}

/// Confiance minimale d'une proposition de niveau [level].
double confidenceThreshold(UnlockLevel level, AdaptParams p) {
  switch (level) {
    case UnlockLevel.loadsReps:
      return p.confidenceLoads;
    case UnlockLevel.volume:
      return p.confidenceVolume;
    case UnlockLevel.exerciseSwap:
      return p.confidenceSwap;
    case UnlockLevel.sessionRestructure:
      return p.confidenceSession;
    case UnlockLevel.blockRestructure:
      return p.confidenceBlock;
  }
}

/// Unité de capacité d'un mode.
CapacityUnit unitOf(CapacityMode mode) {
  switch (mode) {
    case CapacityMode.loaded:
      return CapacityUnit.oneRmKg;
    case CapacityMode.reps:
      return CapacityUnit.maxReps;
    case CapacityMode.hold:
      return CapacityUnit.maxHoldSeconds;
  }
}

/// Estimations du résumé, par identifiant d'exercice.
List<ExerciseEstimate> estimatesOf(ModelState state) {
  final ids = state.tracks.keys.toList()..sort();
  final out = <ExerciseEstimate>[];
  for (final id in ids) {
    final t = state.tracks[id]!;
    final f = t.filter;
    final capacity = f.capacity;
    final last = t.lastDay;
    out.add(
      ExerciseEstimate(
        exerciseId: id,
        unit: unitOf(f.mode),
        capacity: roundTo(capacity, 3),
        standardError: roundTo(capacity * f.capacityRelSd, 3),
        weeklyTrend: roundTo(capacity * f.trend, 4),
        observations: f.sets,
        lastObservedOn: last == null ? null : CivilDate.fromDayNumber(last),
      ),
    );
  }
  return out;
}

/// Records personnels établis par le journal : meilleures répétitions,
/// meilleure tenue, meilleur 1RM de charge totale impliqué par une série
/// courte et proche de l'échec (courbe a priori, pour qu'un record ne
/// dépende pas de l'état du modèle).
List<PersonalRecord> recordsOf(EngineContext ctx, TrainingLog log) {
  final p = ctx.params;
  final best = <String, PersonalRecord>{};
  void offer(String id, RecordKind kind, double value, SessionRecord s) {
    final key = '$id|${kind.code}';
    final old = best[key];
    if (old == null || value > old.value + 1e-9) {
      best[key] = PersonalRecord(
        exerciseId: id,
        kind: kind,
        value: value,
        date: s.date,
        sessionId: s.id,
        previousValue: old?.value,
      );
    }
  }

  for (final session in log.countedSessions) {
    final bw = bodyWeightOf(session, ctx.profile, p);
    for (final set in session.sets) {
      if (!set.isUsable || set.kind == SetKind.warmup) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      final mode = info?.mode;
      if (info == null || mode == null) {
        continue;
      }
      switch (mode) {
        case CapacityMode.hold:
          final seconds = set.seconds;
          if (seconds != null && seconds > 0) {
            offer(
              info.id,
              RecordKind.maxHoldSeconds,
              seconds.toDouble(),
              session,
            );
          }
        case CapacityMode.reps:
          final reps = set.reps;
          if (reps != null && reps > 0) {
            offer(info.id, RecordKind.maxReps, reps.toDouble(), session);
          }
        case CapacityMode.loaded:
          final reps = set.reps;
          final flames = set.flames;
          if (reps == null ||
              reps < 1 ||
              reps > 10 ||
              flames == null ||
              flames < 8) {
            continue;
          }
          final total = info.totalLoad(set.externalLoadKg ?? 0, bw);
          if (total <= 0) {
            continue;
          }
          final n = reps + rirOfFlames(flames);
          final k = info.lowerBody ? p.kLowerBody : p.kGeneral;
          offer(
            info.id,
            RecordKind.oneRmKg,
            roundTo(total * (1 + (n - 1) / k), 1),
            session,
          );
      }
    }
  }
  final keys = best.keys.toList()..sort();
  return <PersonalRecord>[for (final k in keys) best[k]!];
}

/// Revue complète de [input] à partir de l'état rejoué [replayed] ;
/// [plan] sert aux restructurations (D5.1).
AdaptReview buildReview(
  EngineContext ctx,
  BlockView view,
  Replayed replayed,
  AdaptInput input,
  PlanEngine plan,
) {
  final p = ctx.params;
  final today = input.today;
  final day = today.dayNumber;
  final block = input.block;
  final pass1 = block.pass1;
  final state = replayed.state.fork();
  state.fatigue.advance(day, p);
  final digests = replayed.digests;

  // ------------------------------------------------------------- compteurs
  final weeks = <int>{};
  for (final d in digests) {
    if (d.workSets > 0) {
      weeks.add(weekOfDay(d.day));
    }
  }
  final weeksObserved = weeks.length;
  var planned = 0;
  var plannedRecent = 0;
  for (var w = 0; w < pass1.weeks; w++) {
    for (var d = 0; d < pass1.days.length; d++) {
      final when = scheduledDay(pass1, w, d);
      if (when <= day) {
        planned++;
        if (day - when < 21) {
          plannedRecent++;
        }
      }
    }
  }
  var completed = 0;
  var completedRecent = 0;
  for (final d in digests) {
    final ref = d.session.programRef;
    if (ref != null && ref.blockId == pass1.blockId && d.session.completed) {
      completed++;
      if (day - d.day < 21) {
        completedRecent++;
      }
    }
  }
  if (completed > planned) {
    planned = completed;
  }
  final blocksDone = view.imported ? weeksObserved ~/ 6 : pass1.blockIndex;
  final unlock = unlockLevelFor(weeksObserved, blocksDone, p);

  var confidenceSum = 0.0;
  var confidenceCount = 0;
  for (final t in state.tracks.values) {
    final last = t.lastDay;
    if (last == null || day - last > 28) {
      continue;
    }
    final sd = t.filter.loadSd(t.filter.nRef, withDay: false);
    final seen = t.filter.sessions >= 3 ? 1.0 : t.filter.sessions / 3;
    confidenceSum += clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1) * seen;
    confidenceCount++;
  }
  final confidence = confidenceCount == 0
      ? 0.0
      : roundTo(confidenceSum / confidenceCount, 3);

  // ------------------------------------------------------- faits marquants
  final fatigueShift = state.fatigue.globalShift(p);
  final readiness = readinessOf(fatigueShift, p);
  final reasons = <Reason>[
    reason(ReasonCodes.adaptUnlockLevel, <String, Object?>{
      'level': unlock.code,
    }),
  ];
  if (planned > completed) {
    reasons.add(
      reason(ReasonCodes.adaptMissedSessions, <String, Object?>{
        'missed': planned - completed,
        'planned': planned,
      }),
    );
  }
  if (digests.isNotEmpty && day - digests.last.day >= 7) {
    reasons.add(
      reason(ReasonCodes.adaptResumeAfterBreak, <String, Object?>{
        'days': day - digests.last.day,
      }),
    );
  }
  var unrated = 0;
  for (final d in digests) {
    unrated += d.unrated;
  }
  if (unrated > 0) {
    reasons.add(
      reason(ReasonCodes.adaptNoRating, <String, Object?>{'sets': unrated}),
    );
  }
  if (state.rater.weight(p) < p.benchmarkWeight) {
    reasons.add(
      reason(ReasonCodes.adaptRatingsUninformative, <String, Object?>{
        'confirmRate': roundTo(state.rater.confirmRate, 3),
        'sets': state.rater.window.length,
      }),
    );
  }
  if (readiness < p.deloadReadiness) {
    reasons.add(
      reason(ReasonCodes.adaptFatigueHigh, <String, Object?>{
        'readiness': roundTo(readiness, 3),
      }),
    );
  }
  final painTrends = <PainTrend>[];
  for (final zone in BodyZone.values) {
    final s = state.pains[zone];
    if (s == null || s.sessionsReported == 0) {
      continue;
    }
    painTrends.add(
      PainTrend(
        zone: zone,
        side: s.side,
        sessionsReported: s.sessionsReported,
        lastIntensity:
            state.painActive(zone, day, p) || s.lastIntensity <= p.painThreshold
            ? s.lastIntensity
            : 0,
        consecutiveAboveThreshold: s.consecutiveAbove,
      ),
    );
    if (s.consecutiveAbove > 2) {
      reasons.add(
        reason(ReasonCodes.adaptPainPersistent, <String, Object?>{
          'zone': zone.code,
          'sessions': s.consecutiveAbove,
        }),
      );
    }
  }

  // --------------------------------------------- exercices régulièrement sautés
  final skips = <String, int>{};
  for (final d in digests) {
    final ref = d.session.programRef;
    if (ref == null || ref.blockId != pass1.blockId || d.workSets == 0) {
      continue;
    }
    final prescription = view.day(ref.weekIndex, ref.dayIndex);
    if (prescription == null) {
      continue;
    }
    final done = <String>{for (final s in d.session.sets) s.exerciseId};
    for (final item in prescription.items) {
      if (done.contains(item.exerciseId)) {
        skips[item.exerciseId] = 0;
      } else {
        skips[item.exerciseId] = (skips[item.exerciseId] ?? 0) + 1;
      }
    }
  }
  final skipped = <String>[
    for (final e in skips.entries)
      if (e.value >= p.skipTimes) e.key,
  ]..sort();
  for (final id in skipped) {
    reasons.add(
      reason(ReasonCodes.adaptExerciseSkipped, <String, Object?>{
        'exerciseId': id,
        'times': skips[id],
      }),
    );
  }
  // Exercices dont la plus petite charge du matériel est encore trop
  // lourde (même règle que la prescription de séance).
  final tooHeavy = <String, double>{};
  final bodyWeight = bodyWeightOf(null, ctx.profile, p);
  for (final t in state.tracks.values) {
    final last = t.lastLoad;
    final lastDay = t.lastDay;
    if (t.info.mode != CapacityMode.loaded ||
        last == null ||
        lastDay == null ||
        day - lastDay > 28 ||
        !t.noUp ||
        last > t.info.grid.minimum + 1e-9) {
      continue;
    }
    final total = t.info.totalLoad(t.info.grid.minimum, bodyWeight);
    if (total > 0 && t.filter.repsPossible(ln(total)) < 2) {
      tooHeavy[t.info.id] = t.info.grid.minimum;
    }
  }
  final avoided = <String>{...skipped, ...tooHeavy.keys}.toList()..sort();
  for (final id in tooHeavy.keys.toList()..sort()) {
    reasons.add(
      reason(ReasonCodes.adaptLoadFloor, <String, Object?>{
        'minKg': roundTo(tooHeavy[id]!, 2),
      }),
    );
  }

  final summary = AdaptationSummary(
    asOf: today,
    weeksObserved: weeksObserved,
    sessionsPlanned: planned,
    sessionsCompleted: completed,
    unlockLevel: unlock,
    confidence: confidence,
    estimates: estimatesOf(state),
    fatigue: FatigueState(
      fitness: roundTo(state.fatigue.fitness, 4),
      fatigue: roundTo(state.fatigue.fatigueLevel, 4),
      readiness: roundTo(readiness, 3),
    ),
    pains: painTrends,
    avoidedExerciseIds: avoided,
    reasons: reasons,
  );

  // ------------------------------------------------------------ candidates
  final candidates = <_Candidate>[];
  final currentWeek = day < pass1.startDate.dayNumber
      ? -1
      : (day - pass1.startDate.dayNumber) ~/ 7;
  final nextWeek = currentWeek + 1;
  final hasNextWeek = nextWeek >= 0 && nextWeek < pass1.weeks;
  final recent = digests.length <= 3
      ? digests
      : digests.sublist(digests.length - 3);
  var recentReadiness = 0.0;
  var recentResidual = 0.0;
  for (final d in recent) {
    recentReadiness += d.readiness;
    recentResidual += d.residual;
  }
  if (recent.isNotEmpty) {
    recentReadiness /= recent.length;
    recentResidual /= recent.length;
  } else {
    recentReadiness = 1;
  }
  final adherence = planned == 0 ? 1.0 : completed / planned;

  // Décharge anticipée : forme du jour basse plusieurs séances de suite, ou
  // performances sous l'attendu avec une fatigue modélisée élevée.
  if (hasNextWeek) {
    final next = view.week(nextWeek);
    var low = 0;
    for (final d in digests.reversed) {
      if (d.readiness < p.deloadReadiness) {
        low++;
      } else {
        break;
      }
    }
    final under =
        recent.length >= 3 && recentResidual <= -0.03 && readiness < 0.6;
    if (next != null &&
        (next.kind == WeekKind.build || next.kind == WeekKind.intro) &&
        (low >= p.deloadSessions || under)) {
      final changes = <PlanChange>[];
      final why = <Reason>[
        reason(ReasonCodes.adaptDeload, <String, Object?>{
          'weekIndex': nextWeek,
        }),
        reason(ReasonCodes.adaptFatigueHigh, <String, Object?>{
          'readiness': roundTo(recentReadiness, 3),
        }),
      ];
      for (final d in next.days) {
        for (final item in d.items) {
          final flames = item.targetFlames;
          if (flames == null) {
            continue;
          }
          var sets = (item.sets * deloadVolumeFactor).round();
          if (sets < 1) {
            sets = 1;
          }
          final rir = rirOfFlames(flames) + deloadRirBonus;
          final targets = item.setTargets;
          changes.add(
            PlanChange(
              kind: ChangeKind.prescriptionChanged,
              dayIndex: d.dayIndex,
              weekIndex: nextWeek,
              slotId: item.slotId,
              fromPrescription: item,
              toPrescription: item.copyWith(
                sets: sets,
                targetFlames: flamesOfRir(rir > 5 ? 5.0 : rir),
                setTargets: targets == null
                    ? unset
                    : <SetTarget>[
                        for (var i = 0; i < sets; i++)
                          targets[i < targets.length ? i : targets.length - 1],
                      ],
              ),
              reasons: why,
            ),
          );
        }
      }
      if (changes.isNotEmpty) {
        candidates.add(
          _Candidate(
            family: 'deload:${pass1.blockId}',
            kind: ProposalKind.deload,
            scope: ProposalScope.week,
            level: UnlockLevel.volume,
            confidence: clampDouble(
              under ? 0.5 + -recentResidual * 5 : 1 - recentReadiness,
              0,
              1,
            ),
            progress: 0.4 * (1 - recentReadiness),
            risk: 0,
            fatigue: -0.2,
            adherence: 0.1,
            reasons: why,
            diff: PlanDiff(changes: changes),
          ),
        );
      }
    }
  }

  // Volume par groupe musculaire : réponse observée (pente des capacités
  // des exercices du groupe, résidus de performance), bornée par les
  // bandes de kalis_plan.
  if (hasNextWeek) {
    final band = volumeBandsByLevel[ctx.level];
    final weekly = _weeklySets(ctx, digests, day);
    final found = <_Candidate>[];
    for (final g in MuscleGroup.values) {
      if (!g.major) {
        continue;
      }
      var wSum = 0.0;
      var vSum = 0.0;
      var rSum = 0.0;
      var n = 0;
      for (final t in state.tracks.values) {
        final last = t.lastDay;
        final first = t.firstDay;
        final at = t.info.groups.indexOf(g);
        if (at < 0 ||
            t.info.groupWeights[at] < 1 ||
            last == null ||
            first == null ||
            day - last > 21 ||
            t.filter.sessions < 3) {
          continue;
        }
        final w = 1 / sq(t.filter.trendSd < 1e-6 ? 1e-6 : t.filter.trendSd);
        wSum += w;
        vSum += w * t.filter.trend;
        rSum += t.lastResidual;
        n++;
      }
      if (n == 0) {
        continue;
      }
      final trend = vSum / wSum;
      final trendSd = sqrt(1 / wSum);
      final stalled = normCdf(-trend / trendSd);
      final residual = rSum / n;
      final sets = weekly[g.index];
      final slot = _slotFor(ctx, view, nextWeek, g, up: true);
      final slotDown = _slotFor(ctx, view, nextWeek, g, up: false);
      if (residual <= -0.02 && recentReadiness < 0.6 && slotDown != null) {
        final c = normCdf((-residual - 0.01) / (p.daySd / sqrt(n.toDouble())));
        found.add(
          _volumeCandidate(
            view,
            g,
            slotDown,
            nextWeek,
            -1,
            sets,
            c,
            0.3 * c,
            -0.1,
            0,
          ),
        );
      } else if (stalled >= 0.7 &&
          residual >= -0.01 &&
          recentReadiness >= 0.6 &&
          adherence >= 0.8 &&
          sets < band.$2 &&
          slot != null) {
        final c = stalled * (weeksObserved >= 4 ? 1.0 : weeksObserved / 4);
        found.add(
          _volumeCandidate(
            view,
            g,
            slot,
            nextWeek,
            1,
            sets,
            c,
            0.3 * stalled,
            0.2 * (1 - recentReadiness),
            0.05,
          ),
        );
      }
    }
    found.sort((a, b) {
      final byConfidence = b.confidence.compareTo(a.confidence);
      return byConfidence != 0 ? byConfidence : a.family.compareTo(b.family);
    });
    for (var i = 0; i < found.length && i < 2; i++) {
      candidates.add(found[i]);
    }
  }

  // Restructurations par kalis_plan : jamais sur un programme importé.
  final structural = hasNextWeek && !view.imported;
  RestructureRequest request(
    RestructureScope scope,
    List<Reason> why, {
    int? dayIndex,
  }) {
    return RestructureRequest(
      profile: input.profile,
      seed: pass1.seed,
      today: today,
      current: block,
      scope: scope,
      dayIndex: dayIndex,
      fromWeekIndex: nextWeek,
      reasons: why,
      locks: const <PlanLock>[],
      adaptation: summary,
    );
  }

  if (structural) {
    // Échange d'exercice : plateau (pente ≤ 0 avec une probabilité au moins
    // égale au seuil, sur au moins trois semaines) d'un exercice qui n'est
    // pas un mouvement principal, ou exercice régulièrement sauté.
    _Candidate? swap;
    for (final d in pass1.days) {
      for (final slot in d.slots) {
        if (slot.role == SlotRole.main || slot.locked) {
          continue;
        }
        final id = slot.exerciseId;
        final t = state.tracks[id];
        var probability = 0.0;
        List<Reason> why;
        final floorKg = tooHeavy[id];
        if (floorKg != null) {
          probability = 0.95;
          why = <Reason>[
            reason(ReasonCodes.adaptLoadFloor, <String, Object?>{
              'minKg': roundTo(floorKg, 2),
            }),
          ];
        } else if (skipped.contains(id)) {
          probability = 0.9;
          why = <Reason>[
            reason(ReasonCodes.adaptExerciseSkipped, <String, Object?>{
              'exerciseId': id,
              'times': skips[id],
            }),
          ];
        } else {
          final first = t?.firstDay;
          final last = t?.lastDay;
          if (t == null ||
              first == null ||
              last == null ||
              t.filter.sessions < p.plateauMinSessions ||
              last - first < 7 * p.plateauMinWeeks ||
              day - last > 14) {
            continue;
          }
          final sd = t.filter.trendSd < 1e-6 ? 1e-6 : t.filter.trendSd;
          probability = normCdf(-t.filter.trend / sd);
          if (probability < p.plateauProbability) {
            continue;
          }
          why = <Reason>[
            reason(ReasonCodes.adaptPlateau, <String, Object?>{
              'exerciseId': id,
              'weeks': (last - first) ~/ 7,
            }),
          ];
        }
        if (swap == null || probability > swap.confidence) {
          swap = _Candidate(
            family: 'swap:$id:${pass1.blockId}',
            kind: ProposalKind.exerciseSwap,
            scope: ProposalScope.exercise,
            level: UnlockLevel.exerciseSwap,
            confidence: probability,
            progress: 0.3 * probability,
            risk: 0.05,
            fatigue: 0,
            adherence: 0.1,
            reasons: why,
            exerciseId: id,
          );
        }
      }
    }
    if (swap != null) {
      candidates.add(swap);
    }

    // Douleur persistante : la zone est épargnée sur la fin du bloc.
    for (final s in state.pains.values) {
      if (s.consecutiveAbove >= 2 && state.painActive(s.zone, day, p)) {
        candidates.add(
          _Candidate(
            family: 'pain:${s.zone.code}:${pass1.blockId}',
            kind: ProposalKind.painSparing,
            scope: ProposalScope.block,
            level: UnlockLevel.loadsReps,
            confidence: 0.9,
            progress: 0.2,
            risk: -0.3,
            fatigue: 0,
            adherence: 0.1,
            reasons: <Reason>[
              reason(ReasonCodes.adaptPainReported, <String, Object?>{
                'zone': s.zone.code,
                'intensity': s.lastIntensity,
              }),
            ],
          ),
        );
      }
    }

    // Restructuration d'une séance : le temps manque régulièrement ce
    // jour-là.
    for (final d in pass1.days) {
      var seen = 0;
      var short = 0;
      var minutes = 0;
      for (final digest in digests.reversed) {
        final ref = digest.session.programRef;
        if (ref == null ||
            ref.blockId != pass1.blockId ||
            ref.dayIndex != d.dayIndex) {
          continue;
        }
        if (seen >= 4) {
          break;
        }
        seen++;
        final available = digest.session.healthCheck?.minutesAvailable;
        final duration = digest.session.durationMinutes;
        if (available != null && available < d.minutesBudget) {
          short++;
          minutes += available;
        } else if (duration != null && duration > d.minutesBudget * 1.15) {
          short++;
          minutes += d.minutesBudget;
        }
      }
      if (short >= p.timeShortTimes && seen > 0) {
        candidates.add(
          _Candidate(
            family: 'session:${d.dayIndex}:${pass1.blockId}',
            kind: ProposalKind.sessionRestructure,
            scope: ProposalScope.session,
            level: UnlockLevel.sessionRestructure,
            confidence: short / seen,
            progress: 0.2 * short / seen,
            risk: 0,
            fatigue: 0,
            adherence: -0.2,
            reasons: <Reason>[
              reason(ReasonCodes.adaptTimeShort, <String, Object?>{
                'minutesAvailable': minutes ~/ short,
                'minutesPlanned': d.minutesBudget,
              }),
            ],
          )..dayIndex = d.dayIndex,
        );
      }
    }

    // Restructuration du bloc : trop de séances manquées sur trois semaines.
    if (plannedRecent >= 6) {
      final share = completedRecent / plannedRecent;
      if (share < p.adherenceLow) {
        final z = (0.75 - share) / sqrt(0.75 * 0.25 / plannedRecent);
        candidates.add(
          _Candidate(
            family: 'block:${pass1.blockId}',
            kind: ProposalKind.blockRestructure,
            scope: ProposalScope.block,
            level: UnlockLevel.blockRestructure,
            confidence: normCdf(z),
            progress: 0.3,
            risk: 0,
            fatigue: 0,
            adherence: -0.2,
            reasons: <Reason>[
              reason(ReasonCodes.adaptMissedSessions, <String, Object?>{
                'missed': plannedRecent - completedRecent,
                'planned': plannedRecent,
              }),
            ],
          ),
        );
      }
    }
  }

  // ------------------------------------------------------ filtres, émission
  final previous = input.state;
  var sequence = 0;
  var sessionsLogged = 0;
  if (previous != null) {
    final s = previous['sequence'];
    final n = previous['sessions'];
    if (s is int && s >= 0) {
      sequence = s;
    }
    if (n is int && n >= 0) {
      sessionsLogged = n;
    }
  }
  final log = <EngineLogEntry>[];
  void write(
    String event,
    Map<String, Object?> data, {
    CivilDate? date,
    double? confidence,
    List<Reason> reasons = const <Reason>[],
  }) {
    log.add(
      EngineLogEntry(
        sequence: sequence++,
        date: date ?? today,
        engine: 'adapt',
        event: event,
        confidence: confidence,
        reasons: reasons,
        data: data,
      ),
    );
  }

  final from = sessionsLogged > digests.length
      ? digests.length
      : sessionsLogged;
  final firstLogged = digests.length - from > 60 ? digests.length - 60 : from;
  for (var i = firstLogged; i < digests.length; i++) {
    final d = digests[i];
    write('session', <String, Object?>{
      'sessionId': d.session.id,
      'readiness': roundTo(d.readiness, 3),
      'residual': roundTo(d.residual, 4),
      'workSets': d.workSets,
      'unrated': d.unrated,
      'unplannedFails': d.unplannedFails,
      'estimates': <Object?>[
        for (final e in d.entries)
          <String, Object?>{
            'exerciseId': e.exerciseId,
            'capacity': roundTo(e.capacity, 3),
            'relSd': roundTo(e.relSd, 4),
            'sets': e.sets,
          },
      ],
    }, date: d.session.date);
  }

  final refused = <String, int>{};
  final settled = <String>{};
  int? lastSwapDay;
  for (final decision in input.decisions ?? const <ProposalDecision>[]) {
    final id = decision.proposalId;
    final cut = id.lastIndexOf('@');
    final family = cut < 0 ? id : id.substring(0, cut);
    if (family.startsWith('swap:') &&
        (decision.status == ProposalStatus.autoApplied ||
            decision.status == ProposalStatus.accepted)) {
      final when = decision.date.dayNumber;
      if (lastSwapDay == null || when > lastSwapDay) {
        lastSwapDay = when;
      }
    }
    if (decision.status == ProposalStatus.refused ||
        decision.status == ProposalStatus.undone) {
      final when = decision.date.dayNumber;
      final old = refused[family];
      if (old == null || when > old) {
        refused[family] = when;
      }
    } else {
      settled.add(id);
    }
  }

  final proposals = <Proposal>[];
  for (final c in candidates) {
    final id = '${c.family}@$nextWeek';
    final data = <String, Object?>{
      'id': id,
      'kind': c.kind.code,
      'utility': roundTo(c.utility, 3),
      'progress': roundTo(c.progress, 3),
      'risk': roundTo(c.risk, 3),
      'fatigue': roundTo(c.fatigue, 3),
      'adherence': roundTo(c.adherence, 3),
      'threshold': confidenceThreshold(c.level, p),
    };
    String? withheld;
    final refusedOn = refused[c.family];
    if (c.level.index > unlock.index) {
      withheld = 'unlock';
    } else if (c.confidence < confidenceThreshold(c.level, p)) {
      withheld = 'confidence';
    } else if (c.utility <= 0) {
      withheld = 'utility';
    } else if (refusedOn != null && day - refusedOn < p.refusalQuietDays) {
      withheld = 'refused';
    } else if (settled.contains(id)) {
      withheld = 'settled';
    } else if (c.kind == ProposalKind.exerciseSwap &&
        lastSwapDay != null &&
        day - lastSwapDay < p.swapQuietDays) {
      withheld = 'recent_swap';
    }
    if (withheld == null && c.diff == null) {
      // Restructuration demandée au moteur statique (D5.1).
      try {
        final scope = c.kind == ProposalKind.sessionRestructure
            ? RestructureScope.session
            : RestructureScope.block;
        final result = plan.restructure(
          ctx.catalog,
          request(scope, c.reasons, dayIndex: c.dayIndex),
        );
        if (result.diff.changes.isEmpty) {
          withheld = 'no_change';
        } else {
          c.diff = result.diff;
          c.block = result.block;
        }
      } on ArgumentError {
        withheld = 'plan_error';
      } on StateError {
        withheld = 'plan_error';
      }
    }
    if (withheld != null) {
      data['withheld'] = withheld;
      write(
        'proposal_withheld',
        data,
        confidence: roundTo(clampDouble(c.confidence, 0, 1), 3),
        reasons: c.reasons,
      );
      continue;
    }
    final confidenceOut = roundTo(clampDouble(c.confidence, 0, 1), 3);
    proposals.add(
      Proposal(
        id: id,
        kind: c.kind,
        scope: c.scope,
        createdOn: today,
        confidence: confidenceOut,
        unlockLevel: c.level,
        autoApplicable: true,
        exerciseId: c.exerciseId,
        diff: c.diff,
        block: c.block,
        reasons: c.reasons,
      ),
    );
    write('proposal', data, confidence: confidenceOut, reasons: c.reasons);
  }

  final tracks = <String, Object?>{};
  for (final e in state.tracks.entries) {
    tracks[e.key] = e.value.filter.toJson();
  }
  final stateOut = <String, Object?>{
    'schema': 1,
    'engine': kalisAdaptVersion,
    'sessions': digests.length,
    'sequence': sequence,
    'asOf': today.iso,
    'unlock': unlock.code,
    'rater': <String, Object?>{
      'confirmRate': roundTo(state.rater.confirmRate, 3),
      'weight': roundTo(state.rater.weight(p), 3),
      'sets': state.rater.window.length,
    },
    'fatigue': <String, Object?>{
      'gain': roundTo(state.fatigue.gain, 4),
      'chronic': roundTo(state.fatigue.chronic, 4),
      'fitness': roundTo(state.fatigue.fitness, 4),
    },
    'tracks': tracks,
  };
  return AdaptReview(
    summary: summary,
    proposals: proposals,
    state: stateOut,
    log: log,
    records: recordsOf(ctx, input.log),
  );
}

/// Séries fractionnaires par semaine et par groupe (`MuscleGroup.index`),
/// en moyenne sur les deux dernières semaines.
List<double> _weeklySets(
  EngineContext ctx,
  List<SessionDigest> digests,
  int day,
) {
  final out = List<double>.filled(MuscleGroup.values.length, 0);
  for (final d in digests) {
    if (day - d.day >= 14 || day < d.day) {
      continue;
    }
    for (final set in d.session.sets) {
      if (!set.isUsable || set.kind == SetKind.warmup) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      if (info == null || info.mode == null) {
        continue;
      }
      for (var i = 0; i < info.groups.length; i++) {
        out[info.groups[i].index] += info.groupWeights[i] / 2;
      }
    }
  }
  return out;
}

/// Emplacement de la semaine [weekIndex] sur lequel ajouter ([up]) ou
/// retirer une série pour le groupe [group] : un exercice qui le travaille
/// directement, hors mouvement principal ; à la hausse celui qui a le
/// moins de séries (sous le plafond de la dose de référence), à la baisse
/// celui qui en a le plus.
(int, ExercisePrescription)? _slotFor(
  EngineContext ctx,
  BlockView view,
  int weekIndex,
  MuscleGroup group, {
  required bool up,
}) {
  final week = view.week(weekIndex);
  if (week == null ||
      week.kind == WeekKind.deload ||
      week.kind == WeekKind.test) {
    return null;
  }
  (int, ExercisePrescription)? best;
  for (final d in week.days) {
    for (final item in d.items) {
      if (item.targetFlames == null ||
          view.roleOf(item.slotId) == SlotRole.main) {
        continue;
      }
      final info = ctx.book.find(item.exerciseId);
      if (info == null) {
        continue;
      }
      final at = info.groups.indexOf(group);
      if (at < 0 || info.groupWeights[at] < 1) {
        continue;
      }
      if (up && item.sets >= 5) {
        continue;
      }
      if (!up && item.sets <= 2) {
        continue;
      }
      final current = best;
      final better =
          current == null ||
          (up ? item.sets < current.$2.sets : item.sets > current.$2.sets);
      if (better) {
        best = (d.dayIndex, item);
      }
    }
  }
  return best;
}

_Candidate _volumeCandidate(
  BlockView view,
  MuscleGroup group,
  (int, ExercisePrescription) slot,
  int fromWeek,
  int delta,
  double weeklySets,
  double confidence,
  double progress,
  double fatigue,
  double adherence,
) {
  final (dayIndex, item) = slot;
  final why = <Reason>[
    reason(
      delta > 0 ? ReasonCodes.adaptVolumeUp : ReasonCodes.adaptVolumeDown,
      <String, Object?>{'sets': delta.abs()},
    ),
    reason(ReasonCodes.adaptVolumeResponse, <String, Object?>{
      'muscle': group.code,
      'weeklySets': roundTo(weeklySets, 1),
    }),
  ];
  final changes = <PlanChange>[];
  for (final week in view.block.pass2.weeks) {
    if (week.weekIndex < fromWeek ||
        week.kind == WeekKind.deload ||
        week.kind == WeekKind.test) {
      continue;
    }
    for (final d in week.days) {
      if (d.dayIndex != dayIndex) {
        continue;
      }
      for (final it in d.items) {
        if (it.slotId != item.slotId || it.exerciseId != item.exerciseId) {
          continue;
        }
        final sets = it.sets + delta;
        if (sets < 1 || sets > 20) {
          continue;
        }
        final targets = it.setTargets;
        changes.add(
          PlanChange(
            kind: ChangeKind.prescriptionChanged,
            dayIndex: dayIndex,
            weekIndex: week.weekIndex,
            slotId: it.slotId,
            fromPrescription: it,
            toPrescription: it.copyWith(
              sets: sets,
              setTargets: targets == null
                  ? unset
                  : <SetTarget>[
                      for (var i = 0; i < sets; i++)
                        targets[i < targets.length ? i : targets.length - 1],
                    ],
            ),
            reasons: why,
          ),
        );
      }
    }
  }
  return _Candidate(
    family:
        'volume:${group.code}:${delta > 0 ? 'up' : 'down'}:'
        '${view.block.pass1.blockId}',
    kind: ProposalKind.volume,
    scope: ProposalScope.exercise,
    level: UnlockLevel.volume,
    confidence: confidence,
    progress: progress,
    risk: 0,
    fatigue: fatigue,
    adherence: adherence,
    reasons: why,
    exerciseId: item.exerciseId,
    diff: PlanDiff(changes: changes),
  );
}
