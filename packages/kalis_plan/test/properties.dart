// Tests de propriétés sur des profils aléatoires seedés (D4.8) : chaque
// profil est joué de bout en bout — création, revue, variantes, passe 2,
// bloc suivant, restructuration — et chaque invariant du CONTRAT.md est
// revérifié par un code indépendant de la recherche (`PlanInspector`).
//
// Le lot complet compte 10 240 profils, répartis en huit fichiers
// `properties_<n>_test.dart` pour que `dart test` les joue en parallèle.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Profils par fichier.
const int profilesPerShard = 1280;

/// Profils par test (un test = une tranche, pour suivre l'avancement).
const int profilesPerChunk = 160;

final RegExp _slotIdPattern = RegExp(r'^d(\d+)\.(\d+)$');

Map<String, String> _exerciseBySlot(Pass1Plan plan) => <String, String>{
  for (final day in plan.days)
    for (final slot in day.slots) slot.slotId: slot.exerciseId,
};

/// Résumé d'adaptation plausible pour le profil de graine [seed].
AdaptationSummary sampleAdaptation(int seed, Pass1Plan plan) {
  final h = fnv1a32('adaptation:$seed');
  final planned = plan.days.length * plan.weeks;
  final completed = planned - (h % 3) * plan.days.length ~/ 2;
  return AdaptationSummary(
    asOf: plan.startDate.addDays(plan.weeks * 7 - 1),
    weeksObserved: plan.weeks,
    sessionsPlanned: planned,
    sessionsCompleted: completed < 0 ? 0 : completed,
    unlockLevel: UnlockLevel.values[h % UnlockLevel.values.length],
    confidence: ((h >> 3) % 100) / 100,
    estimates: const <ExerciseEstimate>[],
    fatigue: (h >> 5).isEven
        ? null
        : FatigueState(
            fitness: 1,
            fatigue: 1,
            readiness: ((h >> 7) % 100) / 100,
          ),
    pains: const <PainTrend>[],
    avoidedExerciseIds: <String>[
      if ((h >> 9) % 4 == 0 && plan.days.first.slots.isNotEmpty)
        plan.days.first.slots.first.exerciseId,
    ],
    reasons: const <Reason>[],
  );
}

/// Contrôles d'un programme : contrat, catalogue, contraintes dures, forme.
void _checkPlan(
  void Function(String) fail,
  String label,
  Catalog catalog,
  PlanInspector inspector,
  PlanRequest request,
  Pass1Plan plan,
) {
  for (final v in plan.validate()) {
    fail('$label : contrat ${v.path} ${v.code}');
  }
  for (final v in catalog.checkExerciseIds(<String>{
    for (final d in plan.days)
      for (final s in d.slots) s.exerciseId,
  })) {
    fail('$label : catalogue ${v.code} ${v.message}');
  }
  for (final v in inspector.hardViolations(request, plan)) {
    fail('$label : contrainte dure — $v');
  }
  if (plan.days.length != request.profile.availability.length) {
    fail('$label : ${plan.days.length} jours');
  }
  if (plan.engineVersion != kalisPlanVersion) {
    fail('$label : version ${plan.engineVersion}');
  }
  if (plan.score.total < 0 || plan.score.total > 1) {
    fail('$label : note ${plan.score.total}');
  }
  if (plan.score.components.length != ScoreWeights.codes.length) {
    fail('$label : ${plan.score.components.length} composantes');
  }
  for (final c in plan.score.components) {
    if (c.value < -1e-9 || c.value > 1 + 1e-9) {
      fail('$label : composante ${c.code} = ${c.value}');
    }
  }
  for (final day in plan.days) {
    if (day.slots.isEmpty) {
      fail('$label : jour ${day.dayIndex} vide');
    }
    if (!FocusCodes.all.contains(day.focus)) {
      fail('$label : thème ${day.focus}');
    }
    for (final slot in day.slots) {
      final m = _slotIdPattern.firstMatch(slot.slotId);
      if (m == null || int.parse(m.group(1)!) != day.dayIndex) {
        fail('$label : emplacement ${slot.slotId} au jour ${day.dayIndex}');
      }
      if (dayOfSlotId(slot.slotId) != day.dayIndex) {
        fail('$label : dayOfSlotId(${slot.slotId})');
      }
    }
  }
  final reread = jsonEncode(inspector.scoreOf(request, plan).toJson());
  if (reread != jsonEncode(plan.score.toJson())) {
    fail('$label : la note relue diffère de la note rendue');
  }
}

/// Contrôles d'une passe 2.
void _checkPass2(
  void Function(String) fail,
  String label,
  Pass1Plan pass1,
  Pass2Plan pass2,
) {
  for (final v in pass2.validate()) {
    fail('$label : contrat ${v.path} ${v.code}');
  }
  for (final v in ProgramBlock(pass1: pass1, pass2: pass2).validate()) {
    fail('$label : bloc ${v.path} ${v.code}');
  }
  if (pass2.weeks.length != pass1.weeks) {
    fail('$label : ${pass2.weeks.length} semaines pour ${pass1.weeks}');
  }
  var testOrDeload = 0;
  for (final week in pass2.weeks) {
    if (week.kind == WeekKind.deload || week.kind == WeekKind.test) {
      testOrDeload++;
      if (week.weekIndex != pass2.weeks.length - 1) {
        fail('$label : semaine ${week.kind.code} au rang ${week.weekIndex}');
      }
    }
    if (week.days.length != pass1.days.length) {
      fail('$label : semaine ${week.weekIndex}, ${week.days.length} jours');
    }
    for (final day in week.days) {
      if (day.items.isEmpty) {
        fail('$label : semaine ${week.weekIndex}, jour ${day.dayIndex} vide');
      }
      for (final item in day.items) {
        final where = '$label : s${week.weekIndex} ${item.slotId}';
        if (item.sets < 1) {
          fail('$where — ${item.sets} série');
        }
        final flames = item.targetFlames;
        if (flames != null && (flames < 1 || flames > 10)) {
          fail('$where — $flames flammes');
        }
        final rest = item.restSeconds;
        if (rest != null && rest < 0) {
          fail('$where — repos $rest');
        }
        final load = item.startLoadKg;
        if (load != null && load <= 0) {
          fail('$where — charge $load');
        }
        final pct = item.percentOfOneRm;
        if (pct != null && (pct <= 0 || pct > 1)) {
          fail('$where — $pct du 1RM');
        }
      }
    }
  }
  if (testOrDeload > 1) {
    fail('$label : $testOrDeload semaines de décharge ou de test');
  }
}

int _totalSets(WeekPrescription week) {
  var n = 0;
  for (final d in week.days) {
    for (final i in d.items) {
      n += i.sets;
    }
  }
  return n;
}

/// Joue le profil aléatoire de graine [seed] ; rend la liste des
/// manquements (vide si tout est conforme).
List<String> checkSeed(Catalog catalog, int seed) {
  final out = <String>[];
  void fail(String message) => out.add('profil $seed — $message');

  final inspector = PlanInspector(catalog);
  final engine = KalisPlan();
  final request = randomRequest(
    catalog,
    seed,
    planSeed: seed % 16 == 7 ? 1 : 0,
  );

  // ---------------------------------------------------------------- passe 1
  final p1 = engine.createPass1(catalog, request);
  _checkPlan(fail, 'passe 1', catalog, inspector, request, p1);
  if (p1.seed != request.seed || p1.blockIndex != 0) {
    fail('passe 1 : graine ou rang de bloc');
  }
  if (p1.weeks < 4 || p1.weeks > 6) {
    fail('passe 1 : ${p1.weeks} semaines');
  }
  if (seed % 4 == 0) {
    final again = KalisPlan().createPass1(catalog, request);
    if (jsonEncode(again.toJson()) != jsonEncode(p1.toJson())) {
      fail('passe 1 : deux exécutions diffèrent');
    }
  }

  // ------------------------------------------------------------------ revue
  final slots = <(int, PlanSlot)>[
    for (final d in p1.days)
      for (final s in d.slots) (d.dayIndex, s),
  ];
  var current = p1;
  var currentRequest = request;
  if (slots.isNotEmpty) {
    final (day, slot) = slots[fnv1a32('$seed:revue') % slots.length];
    var kind = ReviewKind.values[seed % ReviewKind.values.length];
    String? other;
    if (kind == ReviewKind.replace || kind == ReviewKind.add) {
      final vs = engine.variants(
        catalog,
        VariantsRequest(request: request, current: p1, slotId: slot.slotId),
      );
      if (vs.all.isEmpty) {
        kind = ReviewKind.cannotDo;
      } else {
        other = vs.all[fnv1a32('$seed:variante') % vs.all.length].exerciseId;
      }
    }
    final action = switch (kind) {
      ReviewKind.replace => ReviewAction(
        kind: kind,
        slotId: slot.slotId,
        replacementExerciseId: other,
      ),
      ReviewKind.add => ReviewAction(
        kind: kind,
        dayIndex: day,
        exerciseId: other,
      ),
      _ => ReviewAction(kind: kind, slotId: slot.slotId),
    };
    final reviewRequest = ReviewRequest(
      request: request,
      current: p1,
      action: action,
    );
    final trace = engine.reviewTraced(catalog, reviewRequest);
    final result = trace.result;
    final next = request.copyWith(profile: trace.profile, locks: result.locks);
    final label = 'revue ${kind.code}';
    _checkPlan(fail, label, catalog, inspector, next, result.plan);
    for (final v in result.diff.validate()) {
      fail('$label : diff ${v.path} ${v.code}');
    }
    if (jsonEncode(
          applyProfileDelta(request.profile, result.profileDelta).toJson(),
        ) !=
        jsonEncode(trace.profile.toJson())) {
      fail('$label : profil mis à jour');
    }

    // Verrous intacts.
    final after = _exerciseBySlot(result.plan);
    final lockedFlag = <String, bool>{
      for (final d in result.plan.days)
        for (final s in d.slots) s.slotId: s.locked,
    };
    for (final lock in result.locks) {
      switch (lock.kind) {
        case LockKind.keepSlot:
          if (after[lock.slotId] != lock.exerciseId ||
              lockedFlag[lock.slotId] != true) {
            fail('$label : verrou ${lock.slotId} non tenu');
          }
        case LockKind.excludeExercise:
          if (after.containsValue(lock.exerciseId)) {
            fail('$label : ${lock.exerciseId} exclu et présent');
          }
        case LockKind.requireExercise:
          if (!after.containsValue(lock.exerciseId)) {
            fail('$label : ${lock.exerciseId} exigé et absent');
          }
        case LockKind.keepDay:
          break;
      }
    }

    // Effet de l'action.
    switch (kind) {
      case ReviewKind.canDo:
        if (result.diff.changes.isNotEmpty ||
            jsonEncode(_exerciseBySlot(p1)) != jsonEncode(after)) {
          fail('$label : « je sais faire » a changé le programme');
        }
        if (!result.profileDelta.knownExerciseIds.contains(slot.exerciseId)) {
          fail('$label : exercice non noté comme su');
        }
      case ReviewKind.cannotDo:
      case ReviewKind.dislike:
        if (after.containsValue(slot.exerciseId)) {
          fail('$label : ${slot.exerciseId} encore au programme');
        }
      case ReviewKind.remove:
        if (after.containsKey(slot.slotId)) {
          fail('$label : emplacement ${slot.slotId} encore présent');
        }
        if (result.plan.days[day].slots.any(
          (s) => s.exerciseId == slot.exerciseId,
        )) {
          fail('$label : exercice retiré revenu dans la séance');
        }
      case ReviewKind.replace:
        if (after[slot.slotId] != other) {
          fail('$label : remplacement non appliqué');
        }
      case ReviewKind.add:
        if (!result.plan.days[day].slots.any(
          (s) => s.exerciseId == other && s.locked,
        )) {
          fail('$label : ajout absent ou non verrouillé');
        }
    }

    // Le diff décrit exactement ce qui a changé.
    final before = _exerciseBySlot(p1);
    final changed = <String>{
      for (final e in before.entries)
        if (after[e.key] != e.value) e.key,
      for (final k in after.keys)
        if (!before.containsKey(k)) k,
    };
    final described = <String>{};
    for (final c in result.diff.changes) {
      final id = c.slotId;
      if (id == null) {
        continue;
      }
      switch (c.kind) {
        case ChangeKind.exerciseAdded:
        case ChangeKind.exerciseRemoved:
        case ChangeKind.exerciseReplaced:
          described.add(id);
        case ChangeKind.exerciseMoved:
          // Un déplacement décrit deux emplacements : le nouveau, et
          // celui du jour d'origine qui portait l'exercice.
          described.add(id);
          for (final s in p1.days[c.fromDayIndex!].slots) {
            if (s.exerciseId == c.toExerciseId &&
                !after.containsKey(s.slotId)) {
              described.add(s.slotId);
            }
          }
        case ChangeKind.orderChanged:
        case ChangeKind.prescriptionChanged:
        case ChangeKind.dayAdded:
        case ChangeKind.dayRemoved:
          break;
      }
    }
    if (changed.length != described.length ||
        !changed.containsAll(described)) {
      fail(
        '$label : diff ${described.toList()..sort()} pour '
        '${changed.toList()..sort()}',
      );
    }

    // Diff minimal : la ré-optimisation ne fait jamais moins bien que
    // l'action seule, pénalité de changement comprise.
    if (inspector.hardViolations(next, trace.reference).isEmpty) {
      final kept = inspector.objective(
        next,
        trace.reference,
        reference: trace.reference,
      );
      final got = inspector.objective(
        next,
        result.plan,
        reference: trace.reference,
      );
      if (got < kept - 1e-9) {
        fail('$label : objectif $got < $kept (action seule)');
      }
    }
    if (seed % 4 == 1) {
      final again = KalisPlan().review(catalog, reviewRequest);
      if (jsonEncode(again.toJson()) != jsonEncode(result.toJson())) {
        fail('$label : deux exécutions diffèrent');
      }
    }
    current = result.plan;
    currentRequest = next;
  }

  // --------------------------------------------------------------- variantes
  if (seed.isEven) {
    final all = <(int, PlanSlot)>[
      for (final d in current.days)
        for (final s in d.slots) (d.dayIndex, s),
    ];
    final (day, slot) = all[fnv1a32('$seed:variantes') % all.length];
    final vs = engine.variants(
      catalog,
      VariantsRequest(
        request: currentRequest,
        current: current,
        slotId: slot.slotId,
      ),
    );
    for (final v in vs.validate()) {
      fail('variantes : contrat ${v.path} ${v.code}');
    }
    final inDay = <String>{
      for (final s in current.days[day].slots) s.exerciseId,
    };
    if (vs.slotId != slot.slotId || vs.targeted.length > 3) {
      fail('variantes : ${vs.targeted.length} ciblées');
    }
    final kinds = <VariantKind>{};
    for (final v in vs.targeted) {
      if (v.kind == VariantKind.other || !kinds.add(v.kind)) {
        fail('variantes : ciblée ${v.kind.code} en double ou hors liste');
      }
      if (!vs.all.any((x) => x.exerciseId == v.exerciseId)) {
        fail('variantes : ciblée ${v.exerciseId} absente de la liste');
      }
    }
    final seen = <String>{};
    var last = 2.0;
    final ctx = inspector.contextFor(currentRequest, current);
    for (final v in vs.all) {
      if (!seen.add(v.exerciseId) || inDay.contains(v.exerciseId)) {
        fail('variantes : ${v.exerciseId} en double ou déjà dans la séance');
      }
      if (v.similarity < 0 || v.similarity > 1 || v.similarity > last + 1e-9) {
        fail('variantes : proximité ${v.similarity} hors ordre');
      }
      last = v.similarity;
      final entry = ctx.entryOf(v.exerciseId);
      if (entry == null || !entry.selectable || !entry.feasibleOn(day)) {
        fail('variantes : ${v.exerciseId} inadmissible ce jour-là');
      }
    }
  }

  // ----------------------------------------------------------------- passe 2
  ProgramBlock? block;
  if (seed % 3 == 0 || seed % 8 == 3 || seed % 8 == 5) {
    final p2Request = Pass2Request(request: currentRequest, pass1: current);
    final p2 = engine.createPass2(catalog, p2Request);
    _checkPass2(fail, 'passe 2', current, p2);
    final kinds = <WeekKind>[for (final w in p2.weeks) w.kind];
    if (kinds.length > 1 && kinds.first != WeekKind.intro) {
      fail('passe 2 : première semaine ${kinds.first.code}');
    }
    final builds = <int>[
      for (final w in p2.weeks)
        if (w.kind == WeekKind.build) _totalSets(w),
    ];
    if (builds.isNotEmpty) {
      final most = builds.reduce((a, b) => a > b ? a : b);
      for (final w in p2.weeks) {
        if ((w.kind == WeekKind.intro || w.kind == WeekKind.deload) &&
            _totalSets(w) > most) {
          fail('passe 2 : semaine ${w.kind.code} plus chargée que la charge');
        }
      }
    }
    if (!current.days.any((d) => d.slots.any((s) => s.locked)) &&
        inspector.metrics(currentRequest, current).overBudgetDays != 0) {
      fail('passe 2 : séance au-delà du temps disponible');
    }
    if (seed % 12 == 0) {
      final again = KalisPlan().createPass2(catalog, p2Request);
      if (jsonEncode(again.toJson()) != jsonEncode(p2.toJson())) {
        fail('passe 2 : deux exécutions diffèrent');
      }
    }
    block = ProgramBlock(pass1: current, pass2: p2);
  }

  // ------------------------------------------------------------ bloc suivant
  if (block != null && seed % 8 == 3) {
    final adaptation = sampleAdaptation(seed, current);
    final nextRequest = NextBlockRequest(
      profile: currentRequest.profile,
      seed: seed % 5,
      startDate: current.startDate.addDays(current.weeks * 7),
      previous: block,
      adaptation: adaptation,
      locks: currentRequest.locks,
    );
    final proposal = engine.nextBlock(catalog, nextRequest);
    final asRequest = PlanRequest(
      profile: nextRequest.profile,
      seed: nextRequest.seed,
      startDate: nextRequest.startDate,
      locks: nextRequest.locks,
      adaptation: adaptation,
    );
    final np1 = proposal.block.pass1;
    _checkPlan(fail, 'bloc suivant', catalog, inspector, asRequest, np1);
    _checkPass2(fail, 'bloc suivant', np1, proposal.block.pass2);
    for (final v in proposal.diff.validate()) {
      fail('bloc suivant : diff ${v.path} ${v.code}');
    }
    if (np1.blockIndex != current.blockIndex + 1 ||
        np1.blockId == current.blockId) {
      fail('bloc suivant : rang ou identifiant de bloc');
    }
    for (final id in adaptation.avoidedExerciseIds) {
      // Un verrou de l'utilisateur l'emporte sur l'évitement.
      if (nextRequest.locks.any((l) => l.exerciseId == id)) {
        continue;
      }
      if (_exerciseBySlot(np1).containsValue(id)) {
        fail('bloc suivant : $id à éviter et présent');
      }
    }
    final again = KalisPlan().nextBlock(catalog, nextRequest);
    if (jsonEncode(again.toJson()) != jsonEncode(proposal.toJson())) {
      fail('bloc suivant : deux exécutions diffèrent');
    }
  }

  // --------------------------------------------------------- restructuration
  if (block != null && seed % 8 == 5) {
    final h = fnv1a32('$seed:restructuration');
    final scope = RestructureScope.values[h % RestructureScope.values.length];
    final weeks = block.pass2.weeks.length;
    final from = 1 + (h >> 4) % (weeks - 1);
    final day = (h >> 8) % current.days.length;
    final victim = current.days[day].slots[(h >> 12) %
        current.days[day].slots.length];
    final reasons = <Reason>[
      switch ((h >> 16) % 4) {
        0 => Reason(
          code: ReasonCodes.adaptTimeShort,
          params: <String, Object?>{
            'minutesAvailable': current.days[day].minutesBudget ~/ 2 < 10
                ? 10
                : current.days[day].minutesBudget ~/ 2,
            'minutesPlanned': current.days[day].minutesBudget,
          },
        ),
        1 => const Reason(
          code: ReasonCodes.adaptFatigueHigh,
          params: <String, Object?>{'readiness': 0.3},
        ),
        2 => Reason(
          code: ReasonCodes.adaptExerciseSkipped,
          params: <String, Object?>{
            'exerciseId': victim.exerciseId,
            'times': 3,
          },
        ),
        _ => const Reason(
          code: ReasonCodes.adaptPainReported,
          params: <String, Object?>{'zone': 'knee', 'intensity': 5},
        ),
      },
    ];
    final restructure = RestructureRequest(
      profile: currentRequest.profile,
      seed: seed % 3,
      today: current.startDate.addDays(from * 7),
      current: block,
      scope: scope,
      dayIndex: scope == RestructureScope.session ? day : null,
      fromWeekIndex: from,
      reasons: reasons,
      locks: currentRequest.locks,
    );
    final proposal = engine.restructure(catalog, restructure);
    final label = 'restructuration ${scope.code}';
    for (final v in proposal.block.validate()) {
      fail('$label : bloc ${v.path} ${v.code}');
    }
    for (final v in proposal.diff.validate()) {
      fail('$label : diff ${v.path} ${v.code}');
    }
    for (final v in proposal.block.pass1.validate()) {
      fail('$label : passe 1 ${v.path} ${v.code}');
    }
    final newWeeks = proposal.block.pass2.weeks;
    if (newWeeks.length != weeks) {
      fail('$label : ${newWeeks.length} semaines');
    }
    for (var w = 0; w < weeks && w < newWeeks.length; w++) {
      final same =
          jsonEncode(newWeeks[w].toJson()) ==
          jsonEncode(block.pass2.weeks[w].toJson());
      if (w < from && !same) {
        fail('$label : semaine $w (passée) modifiée');
      }
      if (scope == RestructureScope.week && w != from && !same) {
        fail('$label : semaine $w modifiée hors de la semaine visée');
      }
      if (newWeeks[w].kind != block.pass2.weeks[w].kind) {
        fail('$label : nature de la semaine $w changée');
      }
      if (scope == RestructureScope.session) {
        for (final dp in newWeeks[w].days) {
          if (dp.dayIndex == day) {
            continue;
          }
          final old = block.pass2.weeks[w].days.firstWhere(
            (x) => x.dayIndex == dp.dayIndex,
          );
          if (jsonEncode(dp.toJson()) != jsonEncode(old.toJson())) {
            fail('$label : jour ${dp.dayIndex} modifié hors de la séance');
          }
        }
      }
    }
    if (scope == RestructureScope.week &&
        jsonEncode(proposal.block.pass1.toJson()) !=
            jsonEncode(current.toJson())) {
      fail('$label : la semaine type a changé pour une seule semaine');
    }
    final again = KalisPlan().restructure(catalog, restructure);
    if (jsonEncode(again.toJson()) != jsonEncode(proposal.toJson())) {
      fail('$label : deux exécutions diffèrent');
    }
  }
  return out;
}

/// Déclare les tests du fichier de rang [shard] (de 0 à 7).
void propertyShard(int shard) {
  final catalog = loadCatalog();
  final first = shard * profilesPerShard;
  group('propriétés, profils $first à ${first + profilesPerShard - 1}', () {
    for (
      var from = first;
      from < first + profilesPerShard;
      from += profilesPerChunk
    ) {
      test(
        'profils $from à ${from + profilesPerChunk - 1}',
        () {
          final failures = <String>[];
          for (var seed = from; seed < from + profilesPerChunk; seed++) {
            try {
              failures.addAll(checkSeed(catalog, seed));
            } on Object catch (e, s) {
              final trace = s.toString().split('\n').take(6).join('\n');
              failures.add('profil $seed — exception $e\n$trace');
            }
          }
          expect(
            failures,
            isEmpty,
            reason:
                '${failures.length} manquement(s) :\n'
                '${failures.take(12).join('\n')}',
          );
        },
        timeout: const Timeout(Duration(minutes: 30)),
      );
    }
  });
}
