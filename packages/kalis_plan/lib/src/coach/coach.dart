/// Chemin street de `kalis_plan` 0.2 : passe 1 (squelette), passe 2
/// (dosage), revue, bloc suivant, restructuration, plan de saison.
///
/// Tout est fonction pure de la requête : même requête, même résultat à
/// l'octet près (CONTRAT.md, § 12).
library;

import 'package:kalis_core/kalis_core.dart';

import '../assemble.dart';
import '../context.dart' show adaptationVolumeScale;
import '../diff.dart';
import '../inspect.dart';
import '../params.dart';
import '../traits.dart';
import '../version.dart';
import 'athlete.dart';
import 'model.dart';
import 'prescribe.dart';
import 'season.dart';
import 'skeleton.dart';

/// Douleurs encore présentes à la fin du bloc précédent (résumé
/// d'adaptation, CX, correction 1) : une zone à 3 sur 10 ou plus à la
/// dernière séance qui l'a notée est ménagée par le bloc suivant (R5-P23 :
/// travailler sous 3 à 4 sur 10 ; Silbernagel et al. 2007).
List<(BodyZone, int)> adaptationPains(AdaptationSummary? adaptation) =>
    <(BodyZone, int)>[
      for (final p in adaptation?.pains ?? const <PainTrend>[])
        if (p.lastIntensity >= 3) (p.zone, p.lastIntensity),
    ];

/// Paliers de reprise graduée (CX, correction 1, sécurité) lus dans les
/// notes du bloc [block] : une zone à l'arrêt dans ce bloc (note
/// `pain_stop`) repart au premier palier ; une zone en reprise (note
/// `pain_return`) continue au palier qui suit le dernier du bloc — ou, avec
/// [same] (restructuration du bloc lui-même), garde le palier de départ du
/// bloc. Une reprise finie (palier 5 : plein volume) disparaît.
Map<BodyZone, int> coachReturnStepsOf(ProgramBlock? block, {bool same = false}) {
  final out = <BodyZone, int>{};
  if (block == null) {
    return out;
  }
  final stops = <BodyZone>{};
  for (final r in <Reason>[...block.pass1.reasons, ...block.pass2.reasons]) {
    if (r.code != ReasonCodes.planCoachNote) {
      continue;
    }
    final note = r.params['note'];
    final value = r.params['value'];
    if (value is! num) {
      continue;
    }
    final v = value.round();
    if (note == CoachNotes.painStop) {
      if (v >= 0 && v < BodyZone.values.length) {
        stops.add(BodyZone.values[v]);
      }
    } else if (note == CoachNotes.painReturn) {
      final zone = v ~/ 100;
      if (zone < 0 || zone >= BodyZone.values.length) {
        continue;
      }
      final step = same ? (v % 100) ~/ 10 : v % 10 + 1;
      if (step < coachPainReturnSteps) {
        out[BodyZone.values[zone]] = step;
      }
    }
  }
  for (final z in stops) {
    out[z] = 0;
  }
  return out;
}

/// Identifiant du bloc de rang [blockIndex] commençant le [startDate].
String coachBlockIdFor(int blockIndex, CivilDate startDate) =>
    'kp-b$blockIndex-${startDate.iso}';

/// Vrai si [plan] est un programme du chemin street (il porte l'intention
/// de son bloc).
bool isCoachPlan(Pass1Plan plan) => plan.intent != null;

/// Méthode de dosage d'un exercice [e] placé hors squelette (ajout ou
/// remplacement de l'utilisateur).
String coachMethodFor(Athlete a, CatalogExercise e) {
  switch (slotKindOf(e)) {
    case SlotKind.skillStatic:
      return Method.skillEasyHold;
    case SlotKind.skillDynamic:
      return Method.skillDynamic;
    case SlotKind.power:
      return Method.accessoryCompound;
    case SlotKind.compound:
      return e.loadType == LoadType.bodyweight && (a.reps[e.id] ?? 0) > 0
          ? Method.repsVolume
          : Method.accessoryCompound;
    case SlotKind.accessory:
      return Method.accessoryIsolation;
    case SlotKind.core:
      return Method.accessoryCore;
    case SlotKind.conditioning:
      return Method.accessoryCompound;
    case SlotKind.cardioHard:
      return Method.runQuality;
    case SlotKind.cardioEasy:
      return Method.runEasy;
    case SlotKind.mobility:
      return Method.mobility;
  }
}

SlotRole _roleFor(CatalogExercise e) {
  switch (slotKindOf(e)) {
    case SlotKind.skillStatic:
    case SlotKind.skillDynamic:
      return SlotRole.skill;
    case SlotKind.power:
    case SlotKind.compound:
      return SlotRole.secondary;
    case SlotKind.accessory:
      return SlotRole.accessory;
    case SlotKind.core:
      return SlotRole.core;
    case SlotKind.conditioning:
    case SlotKind.cardioHard:
    case SlotKind.cardioEasy:
      return SlotRole.conditioning;
    case SlotKind.mobility:
      return SlotRole.mobility;
  }
}

bool _loaded(CatalogExercise e) =>
    e.loadType != LoadType.bodyweight &&
    e.loadType != LoadType.none &&
    e.loadType != LoadType.band;

/// Squelette de [canonical] ramené aux emplacements de [pass1] : un
/// emplacement de même exercice garde sa méthode ; un exercice remplacé
/// garde la méthode de son emplacement si elle lui convient (même unité,
/// même nature de charge), sinon reçoit la méthode de sa nature ; un
/// emplacement ajouté reçoit la méthode de sa nature ; un emplacement
/// retiré disparaît.
Skeleton reconcileSkeleton(Athlete a, Skeleton canonical, Pass1Plan pass1) {
  final days = <DaySpec>[];
  for (var d = 0; d < a.dayCount; d++) {
    final out = DaySpec(d);
    final base = d < canonical.days.length ? canonical.days[d] : DaySpec(d);
    final day = d < pass1.days.length ? pass1.days[d] : null;
    out.focus = day?.focus ?? base.focus;
    final used = <SlotSpec>{};
    for (final slot in day?.slots ?? const <PlanSlot>[]) {
      final e = a.catalog.find(slot.exerciseId);
      if (e == null) {
        continue;
      }
      SlotSpec? match;
      for (final s in base.slots) {
        if (!used.contains(s) &&
            s.exerciseId == slot.exerciseId &&
            s.slotId == slot.slotId) {
          match = s;
          break;
        }
      }
      if (match == null) {
        for (final s in base.slots) {
          if (!used.contains(s) && s.exerciseId == slot.exerciseId) {
            match = s;
            break;
          }
        }
      }
      SlotSpec spec;
      if (match != null) {
        used.add(match);
        spec = match..slotId = slot.slotId;
      } else {
        SlotSpec? same;
        for (final s in base.slots) {
          if (!used.contains(s) && s.slotId == slot.slotId) {
            same = s;
            break;
          }
        }
        final old = same == null ? null : a.catalog.find(same.exerciseId);
        final kept =
            same != null &&
                old != null &&
                old.unit == e.unit &&
                _loaded(old) == _loaded(e) &&
                slotKindOf(old).orderRank == slotKindOf(e).orderRank
            ? same
            : null;
        if (same != null) {
          used.add(same);
        }
        spec = SlotSpec(
          exerciseId: e.id,
          role: slot.role,
          method: kept?.method ?? coachMethodFor(a, e),
          sets: kept?.sets ?? 3,
          stress: kept?.stress,
          referenceId: kept?.referenceId,
          skillTargetId: kept?.skillTargetId,
          group: kept?.group,
          weak: kept?.weak,
          fromWeek: kept?.fromWeek ?? 0,
          untilWeek: kept?.untilWeek ?? 99,
          support: kept?.support ?? false,
        )..slotId = slot.slotId;
      }
      out.slots.add(spec);
    }
    days.add(out);
  }
  return Skeleton(
    style: canonical.style,
    shape: canonical.shape,
    days: days,
    ladders: canonical.ladders,
    reasons: canonical.reasons,
    intent: canonical.intent,
  );
}

/// Résultat d'une revue du chemin street.
final class CoachReview {
  /// Résultat.
  const CoachReview(this.result, this.reference, this.profile);

  /// Résultat rendu.
  final ReviewResult result;

  /// Programme après l'action seule (ici : le résultat lui-même).
  final Pass1Plan reference;

  /// Profil mis à jour.
  final AthleteProfile profile;
}

/// Moteur du chemin street.
final class CoachEngine {
  /// Moteur de paramètres [params].
  const CoachEngine(this.params);

  /// Paramètres (note du programme).
  final PlanParams params;

  Set<String> _excludedBy(List<PlanLock> locks) => <String>{
    for (final l in locks)
      if (l.kind == LockKind.excludeExercise && l.exerciseId != null)
        l.exerciseId!,
  };

  Skeleton _skeleton(Athlete a, int blockIndex, int seed, {int? blockWeeks}) {
    final shape = shapeBlock(a, a.start, blockIndex, blockWeeks: blockWeeks);
    return buildSkeleton(a, shape, blockIndex, rotation: seed % 16);
  }

  List<Reason> _slotReasons(Athlete a, Skeleton sk, SlotSpec s) {
    final out = <Reason>[];
    final stress = s.stress;
    if (stress != null) {
      out.add(
        reason(ReasonCodes.planUndulation, <String, Object?>{
          'stress': stress.code,
        }),
      );
    }
    final weak = s.weak;
    final referenceId = s.referenceId;
    if (weak != null && referenceId != null) {
      out.add(
        reason(ReasonCodes.planWeakPoint, <String, Object?>{
          'exerciseId': referenceId,
          'kind': weak.code,
        }),
      );
    }
    for (final g in a.profile.goals) {
      if (g.exerciseId == s.exerciseId ||
          (s.skillTargetId != null && g.exerciseId == s.skillTargetId) ||
          (referenceId != null && g.exerciseId == referenceId)) {
        out.add(
          reason(ReasonCodes.planGoalSupport, <String, Object?>{
            'goalId': g.id,
          }),
        );
        break;
      }
    }
    if (s.method == Method.liftMaintain) {
      out.add(
        reason(ReasonCodes.planCoachNote, <String, Object?>{
          'note': CoachNotes.maintenance,
          'value': s.sets.toDouble(),
        }),
      );
    }
    return out;
  }

  Pass1Plan _assemble(
    Catalog catalog,
    Athlete a,
    Skeleton sk, {
    required PlanRequest request,
    required int blockIndex,
    required int seed,
    Set<String> lockedSlots = const <String>{},
  }) {
    final draft = Pass1Plan(
      blockId: coachBlockIdFor(blockIndex, a.start),
      blockIndex: blockIndex,
      weeks: sk.shape.weeks.length,
      startDate: a.start,
      seed: seed,
      engineVersion: kalisPlanVersion,
      days: <PlanDay>[
        for (final d in sk.days)
          PlanDay(
            dayIndex: d.dayIndex,
            weekday: a.days[d.dayIndex].weekday,
            minutesBudget: a.days[d.dayIndex].minutes > 300
                ? 300
                : a.days[d.dayIndex].minutes,
            focus: d.focus,
            slots: <PlanSlot>[
              for (final s in d.slots)
                PlanSlot(
                  slotId: s.slotId,
                  exerciseId: s.exerciseId,
                  role: s.role,
                  locked: lockedSlots.contains(s.slotId),
                  reasons: _slotReasons(a, sk, s),
                ),
            ],
          ),
      ],
      score: const PlanScore(total: 0, components: <ScoreComponent>[]),
      reasons: blockReasonsOf(a, sk),
      intent: sk.intent,
      skillLadders: sk.ladders.isEmpty ? null : sk.ladders,
    );
    return _scored(catalog, request, draft);
  }

  Pass1Plan _scored(Catalog catalog, PlanRequest request, Pass1Plan plan) {
    final score = PlanInspector(catalog, params: params).scoreOf(request, plan);
    return plan.copyWith(score: score);
  }

  /// Applique au squelette [sk] les verrous `keep_slot` et
  /// `require_exercise` de [locks]. Rend les emplacements verrouillés.
  Set<String> _applyLocks(Athlete a, Skeleton sk, List<PlanLock> locks) {
    final locked = <String>{};
    for (final lock in locks) {
      final exerciseId = lock.exerciseId;
      if (exerciseId == null || !a.catalog.contains(exerciseId)) {
        continue;
      }
      final e = a.catalog.exercise(exerciseId);
      if (lock.kind == LockKind.keepSlot) {
        final slotId = lock.slotId;
        final d = slotId == null ? null : dayOfSlotId(slotId);
        if (slotId == null || d == null || d >= sk.days.length) {
          continue;
        }
        final day = sk.days[d];
        final at = day.slots.indexWhere((s) => s.slotId == slotId);
        if (at >= 0 && day.slots[at].exerciseId == exerciseId) {
          locked.add(slotId);
          continue;
        }
        if (day.slots.any((s) => s.exerciseId == exerciseId)) {
          continue;
        }
        final spec = SlotSpec(
          exerciseId: exerciseId,
          role: at >= 0 ? day.slots[at].role : _roleFor(e),
          method: coachMethodFor(a, e),
        )..slotId = slotId;
        if (at >= 0) {
          day.slots[at] = spec;
        } else {
          day.slots.add(spec);
        }
        locked.add(slotId);
      } else if (lock.kind == LockKind.requireExercise) {
        if (sk.days.any((d) => d.hasExercise(exerciseId))) {
          continue;
        }
        var best = 0;
        for (var d = 0; d < a.dayCount; d++) {
          if (a.can(exerciseId, d)) {
            best = d;
            break;
          }
        }
        final day = sk.days[best];
        var n = day.slots.length + 1;
        while (day.slots.any((s) => s.slotId == slotIdFor(best, n))) {
          n++;
        }
        day.slots.add(
          SlotSpec(
            exerciseId: exerciseId,
            role: _roleFor(e),
            method: coachMethodFor(a, e),
          )..slotId = slotIdFor(best, n),
        );
      }
    }
    return locked;
  }

  // ---------------------------------------------------------------- passe 1

  /// Passe 1 d'un premier bloc, ou du bloc qui suit `previousBlock`.
  Pass1Plan createPass1(Catalog catalog, PlanRequest request) {
    final previous = request.previousBlock;
    final blockIndex = previous == null ? 0 : previous.pass1.blockIndex + 1;
    final a = Athlete.read(
      catalog,
      request.profile,
      request.startDate,
      extraExcluded: _excludedBy(request.locks),
      avoidedIds: request.adaptation?.avoidedExerciseIds ?? const <String>[],
      trendPains: adaptationPains(request.adaptation),
      estimates: request.adaptation?.estimates ?? const <ExerciseEstimate>[],
      stopZones: coachPainStops(request.adaptation?.reasons ?? const []),
      returnSteps: coachReturnStepsOf(previous),
    );
    final sk = _skeleton(
      a,
      blockIndex,
      request.seed,
      blockWeeks: request.blockWeeks,
    );
    final locked = _applyLocks(a, sk, request.locks);
    return _assemble(
      catalog,
      a,
      sk,
      request: request,
      blockIndex: blockIndex,
      seed: request.seed,
      lockedSlots: locked,
    );
  }

  // ---------------------------------------------------------------- passe 2

  Pass2Plan _pass2(
    Catalog catalog, {
    required AthleteProfile profile,
    required List<PlanLock> locks,
    required AdaptationSummary? adaptation,
    required Pass1Plan pass1,
    required List<WeekPrescription> previous,
    Set<String> extraExcluded = const <String>{},
    List<(BodyZone, int)> extraPains = const <(BodyZone, int)>[],
    Map<int, int> minutesOverride = const <int, int>{},
    double? volumeScale,
    Set<BodyZone> stopZones = const <BodyZone>{},
    Map<BodyZone, int> returnSteps = const <BodyZone, int>{},
  }) {
    final a = Athlete.read(
      catalog,
      profile,
      pass1.startDate,
      extraExcluded: <String>{..._excludedBy(locks), ...extraExcluded},
      avoidedIds: adaptation?.avoidedExerciseIds ?? const <String>[],
      extraPains: extraPains,
      trendPains: adaptationPains(adaptation),
      minutesOverride: minutesOverride,
      estimates: adaptation?.estimates ?? const <ExerciseEstimate>[],
      stopZones: <BodyZone>{
        ...coachPainStops(adaptation?.reasons ?? const []),
        ...stopZones,
      },
      returnSteps: returnSteps,
    );
    final canonical = _skeleton(
      a,
      pass1.blockIndex,
      pass1.seed,
      blockWeeks: pass1.weeks,
    );
    final sk = reconcileSkeleton(a, canonical, pass1);
    return prescribeBlock(
      a,
      sk,
      blockId: pass1.blockId,
      blockIndex: pass1.blockIndex,
      previous: previous,
      volumeScale: volumeScale ?? adaptationVolumeScale(adaptation),
    );
  }

  /// Passe 2 de [request].
  Pass2Plan createPass2(Catalog catalog, Pass2Request request) {
    final base = request.request;
    return _pass2(
      catalog,
      profile: base.profile,
      locks: base.locks,
      adaptation: base.adaptation,
      pass1: request.pass1,
      previous: base.previousBlock?.pass2.weeks ?? const <WeekPrescription>[],
      returnSteps: coachReturnStepsOf(base.previousBlock),
    );
  }

  // ------------------------------------------------------------ bloc suivant

  /// Bloc qui suit `request.previous`.
  BlockProposal nextBlock(Catalog catalog, NextBlockRequest request) {
    final planRequest = PlanRequest(
      profile: request.profile,
      seed: request.seed,
      startDate: request.startDate,
      locks: request.locks,
      previousBlock: request.previous,
      adaptation: request.adaptation,
      season: request.season,
    );
    final pass1 = createPass1(catalog, planRequest);
    final pass2 = _pass2(
      catalog,
      profile: request.profile,
      locks: request.locks,
      adaptation: request.adaptation,
      pass1: pass1,
      previous: request.previous.pass2.weeks,
      returnSteps: coachReturnStepsOf(request.previous),
    );
    final before = request.previous.pass1;
    final diff = diffPlans(
      before,
      pass1,
      reasons: (kind, slotId, from, to) => <Reason>[
        if (from != null && to != null)
          reason(ReasonCodes.planVariety)
        else
          reason(ReasonCodes.planSeasonPhase, <String, Object?>{
            'phase':
                pass1.intent?.phase.code ?? SeasonPhaseKind.accumulation.code,
            'weeksToEvent': pass1.intent?.weeksToEvent ?? 0,
          }),
      ],
    );
    return BlockProposal(
      block: ProgramBlock(pass1: pass1, pass2: pass2),
      diff: diff,
      season: planSeasonFor(catalog, request.profile, request.startDate),
    );
  }

  // ------------------------------------------------------------------ revue

  /// Candidat de remplacement de l'exercice [id] le jour [day] : le plus
  /// proche parmi les exercices admissibles de même schéma (plus facile
  /// d'abord si [easier]), absent de la séance.
  String? _replacement(
    Athlete a,
    String id,
    int day,
    Set<String> present, {
    required bool easier,
  }) {
    final catalog = a.catalog;
    final e = catalog.exercise(id);
    String? best;
    var bestScore = -1.0;
    for (final c in catalog.byPattern(e.pattern)) {
      if (c.id == id ||
          present.contains(c.id) ||
          c.unit != e.unit ||
          !a.can(c.id, day)) {
        continue;
      }
      if (easier && c.difficulty > e.difficulty) {
        continue;
      }
      var score = catalog.similarity(id, c.id);
      if (c.rootId == e.rootId) {
        score += 0.25;
      }
      if (easier && c.difficulty < e.difficulty) {
        score += 0.1;
      }
      if (_loaded(c) != _loaded(e)) {
        score -= 0.3;
      }
      if (score > bestScore + 1e-12 ||
          ((score - bestScore).abs() <= 1e-12 &&
              best != null &&
              c.id.compareTo(best) < 0)) {
        bestScore = score;
        best = c.id;
      }
    }
    return best;
  }

  /// Revue d'un programme du chemin street : l'action seule, sans
  /// ré-optimisation du reste (le squelette est construit, pas cherché).
  CoachReview review(
    Catalog catalog,
    ReviewRequest request,
    AthleteProfile Function(AthleteProfile, ProfileDelta) applyDelta,
  ) {
    final base = request.request;
    final current = request.current;
    final action = request.action;
    final violations = action.validate();
    if (violations.isNotEmpty) {
      throw ArgumentError(
        'Action de revue invalide : ${violations.first.code}',
      );
    }
    PlanSlot? target;
    var targetDay = -1;
    final slotId = action.slotId;
    if (slotId != null) {
      for (final day in current.days) {
        for (final slot in day.slots) {
          if (slot.slotId == slotId) {
            target = slot;
            targetDay = day.dayIndex;
          }
        }
      }
    }
    if (action.kind != ReviewKind.add && target == null) {
      throw ArgumentError.value(slotId, 'slotId', 'emplacement inconnu');
    }
    for (final id in <String?>[
      action.exerciseId,
      action.replacementExerciseId,
    ]) {
      if (id != null && !catalog.contains(id)) {
        throw ArgumentError.value(id, 'exerciseId', 'exercice inconnu');
      }
    }
    final locks = <PlanLock>[...base.locks];
    void addLock(PlanLock lock) {
      if (!locks.contains(lock)) {
        locks.add(lock);
      }
    }

    void dropSlotLocks(String id) {
      locks.removeWhere((l) => l.kind == LockKind.keepSlot && l.slotId == id);
    }

    var delta = const ProfileDelta(
      knownExerciseIds: <String>[],
      unknownExerciseIds: <String>[],
      likedExerciseIds: <String>[],
      dislikedExerciseIds: <String>[],
    );
    final days = <List<PlanSlot>>[
      for (final d in current.days) <PlanSlot>[...d.slots],
    ];
    final acted = <Reason>[];
    final touched = <String>{};

    void replaceEverywhere(String exerciseId, {required bool easier}) {
      final a = Athlete.read(
        catalog,
        applyDelta(base.profile, delta),
        current.startDate,
        extraExcluded: _excludedBy(locks),
      );
      for (var d = 0; d < days.length; d++) {
        for (var i = 0; i < days[d].length; i++) {
          final s = days[d][i];
          if (s.exerciseId != exerciseId) {
            continue;
          }
          final present = <String>{for (final x in days[d]) x.exerciseId};
          final other = d < a.dayCount
              ? _replacement(a, exerciseId, d, present, easier: easier)
              : null;
          touched.add(s.slotId);
          dropSlotLocks(s.slotId);
          if (other == null) {
            days[d].removeAt(i);
            i--;
          } else {
            days[d][i] = s.copyWith(
              exerciseId: other,
              locked: false,
              reasons: <Reason>[...acted],
            );
          }
        }
      }
    }

    switch (action.kind) {
      case ReviewKind.canDo:
        final slot = target!;
        dropSlotLocks(slot.slotId);
        addLock(
          PlanLock(
            kind: LockKind.keepSlot,
            slotId: slot.slotId,
            exerciseId: slot.exerciseId,
          ),
        );
        delta = delta.copyWith(knownExerciseIds: <String>[slot.exerciseId]);
        final at = days[targetDay].indexWhere((s) => s.slotId == slot.slotId);
        days[targetDay][at] = slot.copyWith(locked: true);
      case ReviewKind.cannotDo:
        final slot = target!;
        addLock(
          PlanLock(kind: LockKind.excludeExercise, exerciseId: slot.exerciseId),
        );
        delta = delta.copyWith(unknownExerciseIds: <String>[slot.exerciseId]);
        acted.add(reason(ReasonCodes.planUserCannotDo));
        replaceEverywhere(slot.exerciseId, easier: true);
      case ReviewKind.dislike:
        final slot = target!;
        addLock(
          PlanLock(kind: LockKind.excludeExercise, exerciseId: slot.exerciseId),
        );
        delta = delta.copyWith(dislikedExerciseIds: <String>[slot.exerciseId]);
        acted.add(reason(ReasonCodes.planUserDislikes));
        replaceEverywhere(slot.exerciseId, easier: false);
      case ReviewKind.remove:
        final slot = target!;
        dropSlotLocks(slot.slotId);
        if (days[targetDay].length > 1) {
          days[targetDay].removeWhere((s) => s.slotId == slot.slotId);
          touched.add(slot.slotId);
        }
      case ReviewKind.replace:
        final slot = target!;
        final id = action.replacementExerciseId!;
        locks.removeWhere(
          (l) => l.kind == LockKind.excludeExercise && l.exerciseId == id,
        );
        dropSlotLocks(slot.slotId);
        // Le remplaçant ne figure qu'une fois dans la séance.
        days[targetDay].removeWhere(
          (s) => s.exerciseId == id && s.slotId != slot.slotId,
        );
        final at = days[targetDay].indexWhere((s) => s.slotId == slot.slotId);
        days[targetDay][at] = slot.copyWith(
          exerciseId: id,
          locked: true,
          reasons: <Reason>[reason(ReasonCodes.planUserReplaced)],
        );
        addLock(
          PlanLock(
            kind: LockKind.keepSlot,
            slotId: slot.slotId,
            exerciseId: id,
          ),
        );
        touched.add(slot.slotId);
      case ReviewKind.add:
        final d = action.dayIndex!;
        final id = action.exerciseId!;
        if (d < 0 || d >= days.length) {
          throw ArgumentError.value(d, 'dayIndex', 'jour inconnu');
        }
        locks.removeWhere(
          (l) => l.kind == LockKind.excludeExercise && l.exerciseId == id,
        );
        delta = delta.copyWith(likedExerciseIds: <String>[id]);
        final existing = days[d].indexWhere((s) => s.exerciseId == id);
        String added;
        if (existing >= 0) {
          added = days[d][existing].slotId;
          days[d][existing] = days[d][existing].copyWith(locked: true);
        } else {
          final used = <String>{
            for (final day in days)
              for (final s in day) s.slotId,
            for (final l in locks)
              if (l.slotId != null) l.slotId!,
          };
          var n = days[d].length + 1;
          while (used.contains(slotIdFor(d, n))) {
            n++;
          }
          added = slotIdFor(d, n);
          final e = catalog.exercise(id);
          final slot = PlanSlot(
            slotId: added,
            exerciseId: id,
            role: _roleFor(e),
            locked: true,
            reasons: <Reason>[reason(ReasonCodes.planUserAdded)],
          );
          // Avant la mobilité de fin de séance.
          var at = days[d].length;
          while (at > 0 && days[d][at - 1].role == SlotRole.mobility) {
            at--;
          }
          days[d].insert(at, slot);
          touched.add(added);
        }
        addLock(
          PlanLock(kind: LockKind.keepSlot, slotId: added, exerciseId: id),
        );
    }

    if (action.kind == ReviewKind.cannotDo ||
        action.kind == ReviewKind.dislike) {
      // Ce que l'action rend inadmissible suit : une variante plus dure
      // d'un mouvement déclaré non su, un exercice dont il est le
      // prérequis.
      final before = Athlete.read(
        catalog,
        base.profile,
        current.startDate,
        extraExcluded: _excludedBy(base.locks),
      );
      final after = Athlete.read(
        catalog,
        applyDelta(base.profile, delta),
        current.startDate,
        extraExcluded: _excludedBy(locks),
      );
      for (var d = 0; d < days.length && d < after.dayCount; d++) {
        for (var i = 0; i < days[d].length; i++) {
          final s = days[d][i];
          if (s.locked ||
              before.rejection(s.exerciseId, d) != null ||
              after.rejection(s.exerciseId, d) == null) {
            continue;
          }
          final present = <String>{for (final x in days[d]) x.exerciseId};
          final other = _replacement(
            after,
            s.exerciseId,
            d,
            present,
            easier: true,
          );
          touched.add(s.slotId);
          if (other == null) {
            if (days[d].length > 1) {
              days[d].removeAt(i);
              i--;
            }
          } else {
            days[d][i] = s.copyWith(
              exerciseId: other,
              reasons: <Reason>[...acted],
            );
          }
        }
      }
    }
    final profile = applyDelta(base.profile, delta);
    final alive = <String>{
      for (final day in days)
        for (final s in day) s.slotId,
    };
    locks.removeWhere(
      (l) =>
          l.kind == LockKind.keepSlot &&
          l.slotId != null &&
          !alive.contains(l.slotId),
    );
    final next = base.copyWith(profile: profile, locks: locks);
    final plan = _scored(
      catalog,
      next,
      current.copyWith(
        days: <PlanDay>[
          for (var d = 0; d < current.days.length; d++)
            current.days[d].copyWith(slots: days[d]),
        ],
      ),
    );
    final diff = diffPlans(
      current,
      plan,
      reasons: (kind, changed, from, to) => acted.isNotEmpty
          ? acted
          : <Reason>[
              reason(switch (action.kind) {
                ReviewKind.add => ReasonCodes.planUserAdded,
                ReviewKind.remove => ReasonCodes.planUserRemoved,
                _ => ReasonCodes.planUserReplaced,
              }),
            ],
    );
    return CoachReview(
      ReviewResult(plan: plan, diff: diff, locks: locks, profileDelta: delta),
      plan,
      profile,
    );
  }

  // -------------------------------------------------------- restructuration

  /// Restructuration d'un bloc du chemin street : les exercices devenus
  /// inadmissibles (douleur signalée, exercice écarté) sont remplacés, les
  /// semaines de la portée sont re-dosées (temps du jour, volume).
  BlockProposal restructure(Catalog catalog, RestructureRequest request) {
    final violations = request.validate();
    if (violations.isNotEmpty) {
      throw ArgumentError(
        'Requête de restructuration invalide : ${violations.first.code}',
      );
    }
    final current = request.current;
    final before = current.pass1;
    final weeks = current.pass2.weeks.length;
    var from = request.fromWeekIndex ?? 0;
    if (from < 0) {
      from = 0;
    }
    if (from > weeks) {
      from = weeks;
    }
    final scope = request.scope;
    final day = request.dayIndex;
    if (scope == RestructureScope.session &&
        (day == null || day < 0 || day >= before.days.length)) {
      throw ArgumentError.value(day, 'dayIndex', 'jour inconnu');
    }
    final excluded = <String>{..._excludedBy(request.locks)};
    final pains = <(BodyZone, int)>[];
    final minutes = <int, int>{};
    var scale = adaptationVolumeScale(request.adaptation);
    for (final r in request.reasons) {
      switch (r.code) {
        case ReasonCodes.adaptPainReported:
          final zone = r.params['zone'];
          final intensity = r.params['intensity'];
          if (zone is String && intensity is int) {
            for (final z in BodyZone.values) {
              if (z.code == zone) {
                pains.add((z, intensity));
              }
            }
          }
        case ReasonCodes.adaptExerciseSkipped:
        case ReasonCodes.adaptPlateau:
          final id = r.params['exerciseId'];
          if (id is String && catalog.contains(id)) {
            excluded.add(id);
          }
        case ReasonCodes.adaptTimeShort:
          final available = r.params['minutesAvailable'];
          if (available is int && day != null && available >= 5) {
            minutes[day] = available;
          }
        case ReasonCodes.adaptFatigueHigh:
        case ReasonCodes.adaptHealthLow:
          if (scale > 0.85) {
            scale = 0.85;
          }
      }
    }
    // Douleur qui dure ou qui revient : arrêt des mouvements qui la
    // provoquent dès la semaine suivante, noté dans le bloc (le bloc
    // suivant en part pour la reprise graduée).
    final stops = <BodyZone>{
      ...coachPainStops(request.reasons),
      ...coachPainStops(request.adaptation?.reasons ?? const []),
    };
    final returning = coachReturnStepsOf(current, same: true);
    final a = Athlete.read(
      catalog,
      request.profile,
      before.startDate,
      extraExcluded: excluded,
      avoidedIds: request.adaptation?.avoidedExerciseIds ?? const <String>[],
      extraPains: pains,
      trendPains: adaptationPains(request.adaptation),
      estimates: request.adaptation?.estimates ?? const <ExerciseEstimate>[],
      minutesOverride: minutes,
      stopZones: stops,
      returnSteps: returning,
    );
    final lockedSlots = <String>{};
    final frozen = <int>{};
    for (final l in request.locks) {
      if (l.kind == LockKind.keepSlot && l.slotId != null) {
        lockedSlots.add(l.slotId!);
      } else if (l.kind == LockKind.keepDay && l.dayIndex != null) {
        frozen.add(l.dayIndex!);
      }
    }
    if (scope == RestructureScope.session) {
      for (var d = 0; d < before.days.length; d++) {
        if (d != day) {
          frozen.add(d);
        }
      }
    }
    final scopeReason = reason(
      ReasonCodes.planRestructureScope,
      <String, Object?>{'scope': scope.code},
    );
    final specific = <String, List<Reason>>{};
    final days = <PlanDay>[];
    for (final d in before.days) {
      if (frozen.contains(d.dayIndex) || d.dayIndex >= a.dayCount) {
        days.add(d);
        continue;
      }
      final slots = <PlanSlot>[...d.slots];
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        final why = a.rejection(s.exerciseId, d.dayIndex);
        final moved = why == 'excluded' || why == 'joint' || why == 'equipment';
        if (!moved || lockedSlots.contains(s.slotId)) {
          continue;
        }
        final present = <String>{for (final x in slots) x.exerciseId};
        final other = _replacement(
          a,
          s.exerciseId,
          d.dayIndex,
          present,
          easier: false,
        );
        specific[s.slotId] = <Reason>[
          scopeReason,
          reason(ReasonCodes.planAdaptationApplied, <String, Object?>{
            'proposalKind': why == 'joint'
                ? ProposalKind.painSparing.code
                : ProposalKind.exerciseSwap.code,
          }),
        ];
        if (other == null) {
          if (slots.length > 1) {
            slots.removeAt(i);
            i--;
          }
        } else {
          slots[i] = s.copyWith(exerciseId: other, reasons: specific[s.slotId]);
        }
      }
      days.add(d.copyWith(slots: slots));
    }
    final planRequest = PlanRequest(
      profile: request.profile,
      seed: before.seed,
      startDate: before.startDate,
      locks: request.locks,
      adaptation: request.adaptation,
      season: request.season,
    );
    final after = _scored(
      catalog,
      planRequest,
      before.copyWith(
        days: days,
        reasons: <Reason>[
          ...before.reasons,
          scopeReason,
          for (final z in stops)
            if (!before.reasons.any(
              (r) =>
                  r.code == ReasonCodes.planCoachNote &&
                  r.params['note'] == CoachNotes.painStop &&
                  r.params['value'] == z.index.toDouble(),
            ))
              reason(ReasonCodes.planCoachNote, <String, Object?>{
                'note': CoachNotes.painStop,
                'value': z.index.toDouble(),
              }),
        ],
      ),
    );
    final fresh = _pass2(
      catalog,
      profile: request.profile,
      locks: request.locks,
      adaptation: request.adaptation,
      pass1: after,
      previous: const <WeekPrescription>[],
      extraExcluded: excluded,
      extraPains: pains,
      minutesOverride: minutes,
      volumeScale: scale > 1 ? 1 : scale,
      stopZones: stops,
      returnSteps: returning,
    );
    final weeksOut = <WeekPrescription>[];
    for (var w = 0; w < weeks; w++) {
      final old = current.pass2.weeks[w];
      final replace = scope == RestructureScope.week ? w == from : w >= from;
      if (!replace || w >= fresh.weeks.length) {
        weeksOut.add(old);
        continue;
      }
      final neu = fresh.weeks[w];
      if (scope == RestructureScope.session) {
        weeksOut.add(
          old.copyWith(
            days: <DayPrescription>[
              for (final dp in old.days)
                if (dp.dayIndex == day)
                  neu.days.firstWhere(
                    (x) => x.dayIndex == day,
                    orElse: () => dp,
                  )
                else
                  dp,
            ],
          ),
        );
      } else {
        weeksOut.add(
          old.copyWith(
            days: <DayPrescription>[
              for (final dp in old.days)
                if (frozen.contains(dp.dayIndex))
                  dp
                else
                  neu.days.firstWhere(
                    (x) => x.dayIndex == dp.dayIndex,
                    orElse: () => dp,
                  ),
            ],
          ),
        );
      }
    }
    final pass1 = scope == RestructureScope.week ? before : after;
    final diff = diffPlans(
      before,
      after,
      weekIndex: scope == RestructureScope.week ? from : null,
      reasons: (kind, slotId, fromId, toId) {
        final own = slotId == null ? null : specific[slotId];
        return own ?? <Reason>[scopeReason];
      },
    );
    return BlockProposal(
      block: ProgramBlock(
        pass1: pass1,
        pass2: current.pass2.copyWith(weeks: weeksOut),
      ),
      diff: diff,
    );
  }

  // ----------------------------------------------------------------- saison

  /// Plan de saison du profil [profile] à partir du [startDate].
  SeasonPlan planSeasonFor(
    Catalog catalog,
    AthleteProfile profile,
    CivilDate startDate, {
    CivilDate? createdOn,
  }) {
    final a = Athlete.read(catalog, profile, startDate);
    return seasonPlanOf(a, startDate, createdOn ?? startDate);
  }

  // ------------------------------------------------------------- inspecteur

  /// Contraintes dures violées par le programme [plan] du chemin street
  /// (liste vide = admissible) : séance vide, exercice en double, exercice
  /// inadmissible pour le profil (matériel, zone à ménager, niveau,
  /// prérequis, exclusion). Un emplacement verrouillé par la requête
  /// échappe aux règles d'admission.
  List<String> violations(
    Catalog catalog,
    PlanRequest request,
    Pass1Plan plan,
  ) {
    final out = <String>[];
    final a = Athlete.read(
      catalog,
      request.profile,
      plan.startDate,
      extraExcluded: _excludedBy(request.locks),
    );
    if (plan.days.length != a.dayCount) {
      out.add('days: ${plan.days.length} jours pour ${a.dayCount}');
      return out;
    }
    for (final day in plan.days) {
      final d = day.dayIndex;
      if (day.weekday != a.days[d].weekday) {
        out.add('day $d: jour ISO ${day.weekday} ≠ ${a.days[d].weekday}');
      }
      if (day.slots.isEmpty) {
        out.add('day $d: séance vide');
      }
      final seen = <String>{};
      for (final slot in day.slots) {
        final id = slot.exerciseId;
        if (!seen.add(id)) {
          out.add('day $d: $id en double');
        }
        final imposed =
            slot.locked &&
            request.locks.any(
              (l) =>
                  l.kind == LockKind.keepDay ||
                  (l.kind != LockKind.excludeExercise &&
                      (l.slotId == slot.slotId || l.exerciseId == id)),
            );
        if (imposed) {
          continue;
        }
        final why = a.rejection(id, d);
        if (why != null) {
          out.add('day $d: $id inadmissible ($why)');
        }
      }
    }
    return out;
  }
}
