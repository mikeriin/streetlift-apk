// Tests de propriétés du chemin street (kalis_plan 0.2, CONTRAT.md § 12)
// sur des profils street aléatoires seedés au schéma 3. Chaque profil passe
// par la création (passes 1 et 2) et la relecture des invariants de
// sécurité par `coachAudit` (qui ne sait rien de la construction) : aucune
// technique sans son niveau, aucun exercice contre-indiqué ou hors du
// matériel du jour, volume et charge qui montent dans les bornes, tenues
// bras tendus bornées, séances dans le temps, affûtage sur l'échéance. Une
// part fixe des profils, choisie par la graine, passe aussi par le bloc
// suivant (1 sur 4), une action de revue suivie de la passe 2 (1 sur 2), la
// restructuration (1 sur 8) et le plan de saison (1 sur 4) ; le
// déterminisme est rejoué sur 1 profil sur 4.
//
// Le lot complet compte 10 240 profils, répartis en huit fichiers
// `coach_properties_<n>_test.dart`.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Profils par fichier.
const int coachProfilesPerShard = 1280;

/// Profils par test.
const int coachProfilesPerChunk = 160;

final RegExp _slotIdPattern = RegExp(r'^d(\d+)\.(\d+)$');

void _checkPass1(
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
  if (!isCoachPlan(plan)) {
    fail('$label : programme sans intention de bloc');
  }
  if (plan.days.length != request.profile.availability.length) {
    fail('$label : ${plan.days.length} jours');
  }
  if (plan.engineVersion != kalisPlanVersion) {
    fail('$label : version ${plan.engineVersion}');
  }
  if (plan.weeks < 4 || plan.weeks > 6) {
    fail('$label : ${plan.weeks} semaines');
  }
  if (plan.score.total < 0 || plan.score.total > 1) {
    fail('$label : note ${plan.score.total}');
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
      for (final r in slot.reasons) {
        for (final v in r.validate()) {
          fail('$label : raison ${r.code} ${v.code}');
        }
      }
    }
  }
  final reread = jsonEncode(inspector.scoreOf(request, plan).toJson());
  if (reread != jsonEncode(plan.score.toJson())) {
    fail('$label : la note relue diffère de la note rendue');
  }
}

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
  for (final week in pass2.weeks) {
    if (week.intent == null) {
      fail('$label : semaine ${week.weekIndex} sans intention');
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
        if (item.sets < 1 || item.sets > 20) {
          fail('$where — ${item.sets} séries');
        }
        final flames = item.targetFlames;
        if (flames != null && !Flames.isValid(flames)) {
          fail('$where — $flames flammes');
        }
        final rest = item.restSeconds;
        if (rest != null && rest < 0) {
          fail('$where — repos $rest');
        }
        final load = item.startLoadKg;
        if (load != null && load < 0) {
          fail('$where — charge $load');
        }
        final reps = item.repsHigh;
        if (reps != null && (reps < 1 || reps > 100)) {
          fail('$where — $reps répétitions');
        }
        final seconds = item.secondsHigh;
        if (seconds != null && seconds < 1) {
          fail('$where — $seconds s');
        }
      }
    }
  }
}

/// Joue le profil street aléatoire de graine [seed] ; rend la liste des
/// manquements (vide si tout est conforme).
List<String> checkCoachSeed(Catalog catalog, int seed) {
  final out = <String>[];
  void fail(String message) => out.add('profil $seed — $message');

  final inspector = PlanInspector(catalog);
  final engine = KalisPlan();
  final request = randomCoachRequest(
    catalog,
    seed,
    planSeed: seed % 16 == 7 ? 1 : 0,
  );
  final profile = request.profile;
  for (final v in profile.validate()) {
    fail('profil : ${v.path} ${v.code}');
  }
  if (!coachEligible(profile)) {
    fail('profil hors du chemin street');
    return out;
  }

  // ---------------------------------------------------------------- création
  final p1 = engine.createPass1(catalog, request);
  _checkPass1(fail, 'passe 1', catalog, inspector, request, p1);
  final p2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: p1),
  );
  _checkPass2(fail, 'passe 2', p1, p2);
  final block = ProgramBlock(pass1: p1, pass2: p2);
  for (final v in coachAudit(catalog, profile, request.startDate, [block])) {
    fail('relecture : $v');
  }
  if (seed % 4 == 0) {
    final again = KalisPlan();
    final q1 = again.createPass1(catalog, request);
    final q2 = again.createPass2(
      catalog,
      Pass2Request(request: request, pass1: q1),
    );
    if (jsonEncode(q1.toJson()) != jsonEncode(p1.toJson()) ||
        jsonEncode(q2.toJson()) != jsonEncode(p2.toJson())) {
      fail('création : deux exécutions diffèrent');
    }
  }

  // ------------------------------------------------------------------ saison
  if (seed % 4 == 1) {
    final season = engine.planSeason(
      catalog,
      SeasonRequest(
        profile: profile,
        seed: 0,
        today: request.startDate,
        startDate: request.startDate,
      ),
    );
    for (final v in season.validate()) {
      fail('saison : ${v.path} ${v.code}');
    }
    if (season.phases.isEmpty) {
      fail('saison : aucune phase');
    }
    var cursor = request.startDate;
    for (final phase in season.phases) {
      if (phase.startDate != cursor) {
        fail('saison : phase ${phase.index} au ${phase.startDate.iso}');
      }
      cursor = cursor.addDays(7 * phase.weeks);
    }
  }

  // ------------------------------------------------------------ bloc suivant
  if (seed % 4 == 2) {
    final next = NextBlockRequest(
      profile: profile,
      seed: seed % 3,
      startDate: request.startDate.addDays(7 * p1.weeks),
      previous: block,
      adaptation: AdaptationSummary(
        asOf: request.startDate.addDays(7 * p1.weeks - 1),
        weeksObserved: p1.weeks,
        sessionsPlanned: p1.weeks * p1.days.length,
        sessionsCompleted: p1.weeks * p1.days.length,
        unlockLevel: UnlockLevel.loadsReps,
        confidence: 0,
        estimates: const <ExerciseEstimate>[],
        pains: const <PainTrend>[],
        avoidedExerciseIds: const <String>[],
        reasons: const <Reason>[],
      ),
      locks: const <PlanLock>[],
    );
    final proposal = engine.nextBlock(catalog, next);
    final np1 = proposal.block.pass1;
    final nextRequest = PlanRequest(
      profile: profile,
      seed: next.seed,
      startDate: next.startDate,
      locks: const <PlanLock>[],
      previousBlock: block,
      adaptation: next.adaptation,
    );
    _checkPass1(fail, 'bloc suivant', catalog, inspector, nextRequest, np1);
    _checkPass2(fail, 'bloc suivant', np1, proposal.block.pass2);
    for (final v in proposal.diff.validate()) {
      fail('bloc suivant : diff ${v.path} ${v.code}');
    }
    if (np1.blockIndex != 1 || np1.blockId == p1.blockId) {
      fail('bloc suivant : rang ou identifiant de bloc');
    }
    for (final v in coachAudit(catalog, profile, request.startDate, [
      block,
      proposal.block,
    ])) {
      fail('relecture (deux blocs) : $v');
    }
    final again = KalisPlan().nextBlock(catalog, next);
    if (jsonEncode(again.toJson()) != jsonEncode(proposal.toJson())) {
      fail('bloc suivant : deux exécutions diffèrent');
    }
  }

  // ------------------------------------------------------------------- revue
  final slots = <(int, PlanSlot)>[
    for (final d in p1.days)
      for (final s in d.slots) (d.dayIndex, s),
  ];
  if (seed.isOdd && slots.isNotEmpty) {
    final (day, slot) = slots[fnv1a32('$seed:revue') % slots.length];
    var kind = ReviewKind.values[(seed ~/ 2) % ReviewKind.values.length];
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
    _checkPass1(fail, label, catalog, inspector, next, result.plan);
    for (final v in result.diff.validate()) {
      fail('$label : diff ${v.path} ${v.code}');
    }
    final after = <String, String>{
      for (final d in result.plan.days)
        for (final s in d.slots) s.slotId: s.exerciseId,
    };
    for (final lock in result.locks) {
      switch (lock.kind) {
        case LockKind.keepSlot:
          if (after[lock.slotId] != lock.exerciseId) {
            fail('$label : verrou ${lock.slotId} non tenu');
          }
        case LockKind.excludeExercise:
          if (after.containsValue(lock.exerciseId)) {
            fail('$label : ${lock.exerciseId} exclu et présent');
          }
        case LockKind.requireExercise:
        case LockKind.keepDay:
          break;
      }
    }
    switch (kind) {
      case ReviewKind.canDo:
        if (result.diff.changes.isNotEmpty) {
          fail('$label : « je sais faire » a changé le programme');
        }
      case ReviewKind.cannotDo:
      case ReviewKind.dislike:
        if (after.containsValue(slot.exerciseId)) {
          fail('$label : ${slot.exerciseId} encore au programme');
        }
      case ReviewKind.remove:
        if (p1.days[day].slots.length > 1 &&
            after[slot.slotId] == slot.exerciseId) {
          fail('$label : emplacement ${slot.slotId} encore présent');
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
    // Les autres emplacements ne bougent pas (diff minimal).
    final before = <String, String>{
      for (final d in p1.days)
        for (final s in d.slots) s.slotId: s.exerciseId,
    };
    // (Un exercice que l'action rend inadmissible — variante plus dure
    // d'un mouvement déclaré non su — change aussi.)
    final reread = Athlete.read(
      catalog,
      trace.profile,
      request.startDate,
      extraExcluded: <String>{
        for (final l in result.locks)
          if (l.kind == LockKind.excludeExercise && l.exerciseId != null)
            l.exerciseId!,
      },
    );
    for (final e in before.entries) {
      final d = dayOfSlotId(e.key);
      if (e.value != slot.exerciseId &&
          e.value != other &&
          after[e.key] != e.value &&
          d != null &&
          reread.rejection(e.value, d) == null) {
        fail('$label : ${e.key} a changé sans raison');
      }
    }
    // La passe 2 du programme revu reste conforme.
    final reviewed = engine.createPass2(
      catalog,
      Pass2Request(request: next, pass1: result.plan),
    );
    _checkPass2(fail, '$label, passe 2', result.plan, reviewed);
    final imposed = <String>{
      for (final l in result.locks)
        if (l.kind == LockKind.keepSlot && l.slotId != null) l.slotId!,
    };
    for (final v in coachAudit(catalog, trace.profile, request.startDate, [
      ProgramBlock(pass1: result.plan, pass2: reviewed),
    ], imposedSlotIds: imposed)) {
      // Ce que l'utilisateur impose peut dépasser le volume ou la montée
      // d'un groupe : seuls l'admission et le temps sont relus ici.
      if (v.contains('inadmissible') || v.contains('vide')) {
        fail('$label, relecture : $v');
      }
    }
    if (seed % 4 == 1) {
      final again = KalisPlan().review(catalog, reviewRequest);
      if (jsonEncode(again.toJson()) != jsonEncode(result.toJson())) {
        fail('$label : deux exécutions diffèrent');
      }
    }
  }

  // --------------------------------------------------------- restructuration
  if (seed % 8 == 4) {
    final h = fnv1a32('$seed:restructuration');
    final scope = RestructureScope.values[h % RestructureScope.values.length];
    final weeks = p2.weeks.length;
    final from = 1 + (h >> 4) % (weeks - 1);
    final day = (h >> 8) % p1.days.length;
    final victim = p1.days[day].slots[(h >> 12) % p1.days[day].slots.length];
    final reasons = <Reason>[
      switch ((h >> 16) % 4) {
        0 => Reason(
          code: ReasonCodes.adaptTimeShort,
          params: <String, Object?>{
            'minutesAvailable': p1.days[day].minutesBudget ~/ 2 < 10
                ? 10
                : p1.days[day].minutesBudget ~/ 2,
            'minutesPlanned': p1.days[day].minutesBudget,
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
          params: <String, Object?>{'zone': 'elbow', 'intensity': 5},
        ),
      },
    ];
    final restructure = RestructureRequest(
      profile: profile,
      seed: seed % 3,
      today: p1.startDate.addDays(from * 7),
      current: block,
      scope: scope,
      dayIndex: scope == RestructureScope.session ? day : null,
      fromWeekIndex: from,
      reasons: reasons,
      locks: const <PlanLock>[],
    );
    final proposal = engine.restructure(catalog, restructure);
    final label = 'restructuration ${scope.code}';
    for (final v in proposal.block.validate()) {
      fail('$label : bloc ${v.path} ${v.code}');
    }
    for (final v in proposal.diff.validate()) {
      fail('$label : diff ${v.path} ${v.code}');
    }
    if (proposal.block.pass2.weeks.length != weeks) {
      fail('$label : ${proposal.block.pass2.weeks.length} semaines');
    }
    // Les semaines passées ne changent pas.
    for (var w = 0; w < from; w++) {
      if (jsonEncode(proposal.block.pass2.weeks[w].toJson()) !=
          jsonEncode(p2.weeks[w].toJson())) {
        fail('$label : semaine passée $w modifiée');
      }
    }
    // CX, correction 1 : les semaines réécrites ne montent pas le volume
    // d'un groupe plus vite que les semaines gardées ne l'admettent (même
    // relecture que le programme d'origine : aucune hausse trop rapide de
    // plus que lui).
    Set<String> ramps(ProgramBlock b) => <String>{
      for (final v in coachAudit(catalog, profile, p1.startDate, [b]))
        if (v.contains(' séries pour '))
          if (RegExp(r'^s(\d+) : (\S+)').firstMatch(v) case final m?)
            if (int.parse(m.group(1)!) >= from) '${m.group(1)} ${m.group(2)}',
    };
    final rampsBefore = ramps(block);
    for (final r in ramps(proposal.block)) {
      if (!rampsBefore.contains(r)) {
        fail('$label : hausse de volume trop rapide (semaine, groupe) $r');
      }
    }
    for (final week in proposal.block.pass2.weeks) {
      for (final d in week.days) {
        if (d.items.isEmpty) {
          fail('$label : s${week.weekIndex} j${d.dayIndex} vide');
        }
      }
    }
    final again = KalisPlan().restructure(catalog, restructure);
    if (jsonEncode(again.toJson()) != jsonEncode(proposal.toJson())) {
      fail('$label : deux exécutions diffèrent');
    }
  }
  return out;
}

/// Tests du fichier de rang [shard] (profils `shard × 1280` et suivants).
void coachPropertyShard(int shard) {
  final catalog = loadCatalog();
  final first = shard * coachProfilesPerShard;
  group('chemin street, profils $first à '
      '${first + coachProfilesPerShard - 1}', () {
    for (
      var chunk = 0;
      chunk < coachProfilesPerShard ~/ coachProfilesPerChunk;
      chunk++
    ) {
      final from = first + chunk * coachProfilesPerChunk;
      final to = from + coachProfilesPerChunk;
      test('profils $from à ${to - 1}', () {
        final failures = <String>[];
        for (var seed = from; seed < to; seed++) {
          failures.addAll(checkCoachSeed(catalog, seed));
        }
        expect(
          failures.take(40).toList(),
          isEmpty,
          reason: '${failures.length} manquement(s)',
        );
      });
    }
  });
}
