/// Rejeu du journal : du journal de séances à l'état du modèle individuel.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show SlotKind;

import 'book.dart';
import 'coach.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'params.dart';

/// Lecture du bloc en cours : prescriptions par semaine, jour et
/// emplacement, rôles des emplacements.
final class BlockView {
  /// Vue du bloc [block] pour le profil [profile]. [legacy] : le bloc est
  /// lu comme par `kalis_adapt` 0.1, même s'il porte les champs de
  /// `kalis_core` 0.4.0 (comparaison des deux versions).
  BlockView(this.block, this.params, {this.profile, bool legacy = false})
    : coached = !legacy && blockCoached(block) {
    for (final day in block.pass1.days) {
      for (final slot in day.slots) {
        _roles[slot.slotId] = slot.role;
      }
    }
    final p = profile;
    if (coached && p != null) {
      for (final event in p.events ?? const <SeasonEvent>[]) {
        if (event.priority == EventPriority.main) {
          _eventDays.add(event.date.dayNumber);
        }
      }
      _eventDays.sort();
      for (final l in p.limitations) {
        final since = l.since;
        final recent =
            since == ConstraintSince.under6Weeks ||
            since == ConstraintSince.weeks6To12 ||
            since == ConstraintSince.months3To12;
        if (recent || l.discomfort >= 2) {
          _fragile.add(l.zone);
        }
      }
    }
  }

  /// Bloc.
  final ProgramBlock block;

  /// Paramètres.
  final AdaptParams params;

  /// Profil (échéances, antécédents), ou `null`.
  final AthleteProfile? profile;

  /// Mode coach : le bloc porte des champs de `kalis_core` 0.4.0 que le
  /// moteur exécute. Faux : règle générale de 0.1, inchangée.
  final bool coached;

  final List<int> _eventDays = <int>[];
  final Set<BodyZone> _fragile = <BodyZone>{};

  /// Zones à antécédent récent (moins de 12 mois) ou à gêne déclarée d'au
  /// moins 2 sur 10.
  Set<BodyZone> get fragileZones => _fragile;

  /// Jours entre [day] et la prochaine échéance principale du profil
  /// ([day] compris), ou `null`.
  int? daysToEvent(int day) {
    for (final d in _eventDays) {
      if (d >= day) {
        return d - day;
      }
    }
    return null;
  }

  /// Vrai si le jour [day] suit un affûtage : sa semaine ou la précédente
  /// est une semaine d'affûtage ou de compétition (CA2, partie 0).
  bool taperedAt(int day) {
    final start = block.pass1.startDate.dayNumber;
    if (!coached || day < start) {
      return false;
    }
    final w = (day - start) ~/ 7;
    for (final i in <int>[w, w - 1]) {
      if (i >= 0 && policyOf(week(i)).peak) {
        return true;
      }
    }
    return false;
  }

  /// Ce que la semaine [week] permet.
  WeekPolicy policyOf(WeekPrescription? week) =>
      WeekPolicy(coached ? week?.intent : null, week?.kind);

  /// Lecture « coach » de la prescription [item] de la semaine
  /// [weekIndex], au jour [day] ; `null` hors mode coach.
  CoachSpec? coachOf(
    ExerciseInfo info,
    ExercisePrescription? item,
    int? weekIndex,
    int? day,
  ) {
    if (!coached || item == null || weekIndex == null) {
      return null;
    }
    final p = profile;
    final experience = p?.experience;
    final days = day == null ? null : daysToEvent(day);
    var fragile = false;
    for (final zone in _fragile) {
      if (info.zoneLevel(zone) >= 0.5) {
        fragile = true;
      }
    }
    return CoachSpec(
      slotId: item.slotId,
      item: item,
      policy: policyOf(week(weekIndex)),
      level: experience == null ? 1 : experience.index,
      eventDays: days,
      eventNear: days != null && days <= params.coachEventNearDays,
      fragile: fragile,
    );
  }

  final Map<String, SlotRole> _roles = <String, SlotRole>{};

  /// Programme importé (celui du propriétaire, D5.10) : `kalis_plan` ne
  /// produit que des blocs de 4 à 6 semaines ; un tel bloc n'est jamais
  /// restructuré.
  bool get imported => block.pass1.weeks > 6;

  /// Semaine [weekIndex] du bloc, ou `null`.
  WeekPrescription? week(int weekIndex) {
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekIndex) {
        return w;
      }
    }
    return null;
  }

  /// Séance du jour [dayIndex] de la semaine [weekIndex], ou `null`.
  DayPrescription? day(int weekIndex, int dayIndex) {
    final w = week(weekIndex);
    if (w == null) {
      return null;
    }
    for (final d in w.days) {
      if (d.dayIndex == dayIndex) {
        return d;
      }
    }
    return null;
  }

  /// Prescription de l'emplacement [slotId] (sinon de l'exercice
  /// [exerciseId]) dans la séance désignée par [ref], ou `null`.
  ExercisePrescription? item(
    ProgramRef? ref,
    String? slotId,
    String exerciseId,
  ) {
    if (ref == null || ref.blockId != block.pass1.blockId) {
      return null;
    }
    final d = day(ref.weekIndex, ref.dayIndex);
    if (d == null) {
      return null;
    }
    if (slotId != null) {
      for (final it in d.items) {
        if (it.slotId == slotId) {
          return it;
        }
      }
    }
    for (final it in d.items) {
      if (it.exerciseId == exerciseId) {
        return it;
      }
    }
    return null;
  }

  /// Rôle de l'emplacement [slotId] dans la semaine type, ou `null`.
  SlotRole? roleOf(String slotId) => _roles[slotId];

  /// Emplacement d'un exercice d'après sa prescription [item] (ou des
  /// valeurs neutres si elle manque), pour une semaine de nature [kind].
  SlotSpec specOf(
    ExerciseInfo info,
    ExercisePrescription? item,
    WeekKind? kind, {
    SetTarget? fallback,
    int? weekIndex,
    int? day,
  }) {
    final p = params;
    final hold = info.mode == CapacityMode.hold;
    int? low;
    int? high;
    int? flames;
    if (item != null) {
      low = hold ? item.secondsLow : item.repsLow;
      high = hold ? item.secondsHigh : item.repsHigh;
      flames = item.targetFlames;
      final targets = item.setTargets;
      if ((low == null || high == null) && targets != null) {
        for (final t in targets) {
          final tl = hold ? t.secondsLow : t.repsLow;
          final th = hold ? t.secondsHigh : t.repsHigh;
          if (tl != null && (low == null || tl < low)) {
            low = tl;
          }
          if (th != null && (high == null || th > high)) {
            high = th;
          }
        }
      }
    } else if (fallback != null) {
      low = hold ? fallback.secondsLow : fallback.repsLow;
      high = hold ? fallback.secondsHigh : fallback.repsHigh;
      flames = fallback.flames;
    }
    var lo = low ?? high ?? 0;
    var hi = high ?? low ?? 0;
    if (lo < 1 || hi < lo) {
      lo = hold ? 10 : (info.mode == CapacityMode.loaded ? 6 : 5);
      hi = hold ? 30 : (info.mode == CapacityMode.loaded ? 10 : 15);
    }
    final coach = coachOf(info, item, weekIndex, day);
    final testRir = coach == null ? null : item?.test?.targetRir;
    final rir = flames == null ? (testRir ?? 3.0) : rirOfFlames(flames);
    final role = item == null ? null : roleOf(item.slotId);
    final test = item != null && item.kind == SetKind.test;
    return SlotSpec(
      low: lo,
      high: hi,
      rir: rir,
      sets: item?.sets ?? 3,
      restSeconds: item?.restSeconds ?? defaultRestOf(info, p),
      main: role == SlotRole.main,
      benchmarkOk:
          kind == WeekKind.build &&
          flames != null &&
          rir <= p.benchmarkMaxRir &&
          !test &&
          (role == SlotRole.main ||
              role == SlotRole.secondary ||
              role == SlotRole.accessory),
      hasTarget: flames != null,
      test: test,
      coach: coach,
      coachRead: coached,
    );
  }
}

/// Repos supposé d'un exercice dont la prescription est inconnue (séance
/// d'un bloc précédent, séance importée) : celui que `kalis_plan` donne à
/// un exercice de cette nature.
int defaultRestOf(ExerciseInfo info, AdaptParams p) {
  switch (info.traits.kind) {
    case SlotKind.compound:
    case SlotKind.skillDynamic:
      return 150;
    case SlotKind.skillStatic:
    case SlotKind.power:
      return 120;
    case SlotKind.accessory:
      return 75;
    case SlotKind.core:
      return 60;
    case SlotKind.conditioning:
    case SlotKind.cardioHard:
    case SlotKind.cardioEasy:
    case SlotKind.mobility:
      return p.defaultRestSeconds;
  }
}

/// Résumé d'une séance du journal (ce que la revue relit).
final class SessionDigest {
  /// Résumé.
  SessionDigest({
    required this.session,
    required this.day,
    required this.readiness,
    required this.healthLevel,
  });

  /// Séance.
  final SessionRecord session;

  /// Numéro de jour civil.
  final int day;

  /// Forme du jour estimée à l'ouverture, de 0 à 1.
  final double readiness;

  /// Palier du bilan santé.
  final int healthLevel;

  /// Exercices observés et capacité après la séance.
  final List<DigestEntry> entries = <DigestEntry>[];

  /// Séries de travail utilisables.
  int workSets = 0;

  /// Séries sans note.
  int unrated = 0;

  /// Effet de jour moyen observé (résidus), pondéré.
  double residual = 0;

  /// Séries à l'échec non prévues.
  int unplannedFails = 0;
}

/// Capacité d'un exercice après une séance.
final class DigestEntry {
  /// Entrée.
  const DigestEntry(this.exerciseId, this.capacity, this.relSd, this.sets);

  /// Exercice.
  final String exerciseId;

  /// Capacité estimée après la séance.
  final double capacity;

  /// Écart-type relatif.
  final double relSd;

  /// Séries observées.
  final int sets;
}

/// Résultat d'un rejeu.
final class Replayed {
  /// État [state] et résumés [digests].
  const Replayed(this.state, this.digests);

  /// État du modèle après la dernière séance.
  final ModelState state;

  /// Résumé de chaque séance prise en compte, dans l'ordre.
  final List<SessionDigest> digests;
}

/// Poids de corps d'une séance : celui de la séance, sinon celui du
/// profil, sinon la référence du modèle.
double bodyWeightOf(
  SessionRecord? session,
  AthleteProfile profile,
  AdaptParams p,
) {
  return session?.bodyWeightKg ??
      profile.bodyWeightKg ??
      p.referenceBodyWeightKg;
}

/// Cible d'une série d'après la cible enregistrée [target] (ce qui était
/// affiché), ou `null` si elle ne dit pas les flammes.
SetPlan? planOfTarget(SetTarget? target, {required bool hold}) {
  if (target == null) {
    return null;
  }
  final flames = target.flames;
  var low = hold ? target.secondsLow : target.repsLow;
  var high = hold ? target.secondsHigh : target.repsHigh;
  low ??= high;
  high ??= low;
  if (flames == null || low == null || high == null) {
    return null;
  }
  return SetPlan(
    loadKg: target.loadKg,
    low: low,
    high: high,
    flames: flames,
    open: high > low,
    role: target.role,
  );
}

/// Note les douleurs d'une séance dans [state] : par zone, la plus forte
/// intensité du bilan ([check]) et des signalements ([pains]) ; si la
/// question a été posée au bilan, les zones suivies non citées sont
/// levées.
void notePains(
  ModelState state,
  HealthCheck? check,
  List<PainReport> pains,
  int day,
  AdaptParams p,
) {
  final worst = <BodyZone, PainReport>{};
  void take(PainReport r) {
    final old = worst[r.zone];
    if (old == null || r.intensity > old.intensity) {
      worst[r.zone] = r;
    }
  }

  final asked = check?.pains;
  if (asked != null) {
    asked.forEach(take);
  }
  pains.forEach(take);
  for (final zone in BodyZone.values) {
    final r = worst[zone];
    if (r != null) {
      state.notePain(zone, r.side, r.intensity, day, p);
    } else if (asked != null) {
      state.clearPain(zone, day);
    }
  }
}

/// Séances du journal [log] que le moteur prend en compte jusqu'au jour
/// [untilDay] compris : les séances « reprise » sont ignorées (D4.9).
List<SessionRecord> sessionsOf(TrainingLog log, int untilDay) {
  return <SessionRecord>[
    for (final s in log.countedSessions)
      if (s.date.dayNumber <= untilDay) s,
  ];
}

/// Rejoue les séances [sessions] à la suite de [state] (modifié) et ajoute
/// leurs résumés à [digests]. Séries écartées ignorées, échauffements non
/// pris en compte.
void replaySessions(
  EngineContext ctx,
  BlockView view,
  ModelState state,
  List<SessionDigest> digests,
  Iterable<SessionRecord> sessions,
) {
  final p = ctx.params;
  for (final session in sessions) {
    final day = session.date.dayNumber;
    final health = readHealth(session.healthCheck, p);
    final run = SessionRun(
      ctx,
      state,
      day: day,
      health: health,
      bodyWeightKg: bodyWeightOf(session, ctx.profile, p),
    );
    final digest = SessionDigest(
      session: session,
      day: day,
      readiness: readinessOf(health.shift + state.fatigue.globalShift(p), p),
      healthLevel: health.level,
    );
    notePains(state, session.healthCheck, session.pains, day, p);
    final ref = session.programRef;
    final kind = ref == null || ref.blockId != view.block.pass1.blockId
        ? null
        : view.week(ref.weekIndex)?.kind;
    String? openKey;
    var residualSum = 0.0;
    var residualCount = 0;
    for (final set in session.sets) {
      if (!set.isUsable || set.kind == SetKind.warmup) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      if (info == null || info.mode == null) {
        continue;
      }
      final hold = info.mode == CapacityMode.hold;
      // Lignes qui portent des champs de 0.4.0 (technique, parties, rôle,
      // propreté) : lecture propre à la technique ; sinon lecture de 0.1.
      final item = view.item(ref, set.slotId, set.exerciseId);
      final reading = readLine(set, hold: hold, item: item);
      if (reading != null && reading.skip) {
        continue;
      }
      final amount = reading?.amount ?? (hold ? set.seconds : set.reps);
      if (amount == null) {
        continue;
      }
      final loadKg = reading?.loadKg ?? set.externalLoadKg;
      if (info.mode == CapacityMode.loaded &&
          info.totalLoad(loadKg ?? 0, run.bodyWeightKg) <= 0) {
        // Charge totale nulle ou négative : la série ne dit rien.
        continue;
      }
      // Les séries d'un même exercice enchaînées avec un autre (superset,
      // tours) retrouvent leur déroulement par la clé.
      final key = '${set.slotId ?? ''}|${set.exerciseId}|${set.exerciseOrder}';
      if (key != openKey) {
        openKey = key;
        run.begin(
          info,
          view.specOf(
            info,
            item,
            kind,
            fallback: set.target,
            weekIndex: kind == null ? null : ref?.weekIndex,
            day: day,
          ),
          key: key,
        );
      }
      digest.workSets++;
      if (!set.isRated) {
        digest.unrated++;
      }
      final unclean = reading != null && reading.unclean;
      run.observe(
        loadKg: loadKg,
        amount: amount,
        flames: unclean ? Flames.failure : set.flames,
        missed: !set.success,
        target: planOfTarget(set.target, hold: hold),
        test: set.kind == SetKind.test,
        boundOnly: reading != null && reading.boundOnly,
        quality: set.quality,
        role: set.role,
        lineAmount: hold ? set.seconds : set.reps,
      );
    }
    run.closeAll();
    for (final done in run.closed) {
      final track = done.track!;
      digest.entries.add(
        DigestEntry(
          done.info.id,
          track.filter.capacity,
          track.filter.capacityRelSd,
          done.observed.length,
        ),
      );
      digest.unplannedFails += done.fails;
      residualSum += track.lastResidual;
      residualCount++;
    }
    digest.residual = residualCount == 0 ? 0 : residualSum / residualCount;
    digests.add(digest);
  }
}

/// Rejoue tout le journal [log] jusqu'au jour [untilDay] compris.
Replayed replayLog(
  EngineContext ctx,
  BlockView view,
  TrainingLog log,
  int untilDay,
) {
  final state = ModelState(ctx.params);
  final digests = <SessionDigest>[];
  replaySessions(ctx, view, state, digests, sessionsOf(log, untilDay));
  return Replayed(state, digests);
}
