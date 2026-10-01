// Tests de propriétés : des journaux aléatoires (seedés) que personne
// n'aurait écrits à la main — charges qui sautent, notes absentes ou
// extrêmes, séries à zéro répétition, séances libres, douleurs, bilans
// partiels, reprises, coupures — et, sur chacun, les invariants de sécurité
// du contrat (`CONTRAT.md`, § Invariants) :
//
//  I1  mouvement principal hors calibrage : jamais plus de +10 % de charge
//      totale d'une séance à l'autre (ou un seul cran de grille quand le
//      plus petit cran dépasse 10 %) ;
//  I2  jamais de hausse après une série à l'échec non prévue ;
//  I3  une douleur au-dessus du seuil n'est jamais suivie d'une charge
//      accrue sur la zone ; un exercice exclu par la douleur du jour n'est
//      pas prescrit ;
//  I4  aucune proposition au-dessus du niveau de déblocage ;
//  I5  sorties valides au sens du contrat (codes de raison compris),
//      charges sur la grille du matériel ;
//  I6  même entrée, même sortie à l'octet près, avec ou sans cache, que le
//      journal soit donné en une fois ou prolongé d'un appel à l'autre ;
//  I7  un bilan santé sans réponse équivaut à l'absence de bilan ;
//  I8  les séances « reprise » ne changent rien.
//
// Un journal sur cinq enchaîne les séries de deux exercices (superset) ;
// les conseils sont demandés avec et sans le bilan du jour, et après des
// séries d'un autre emplacement.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Nombre de fichiers de propriétés (un isolat chacun).
const int propertyFiles = 8;

/// Journaux par fichier : 8 × 1 280 = 10 240 journaux.
const int journalsPerFile = 1280;

/// Profils types utilisés par les journaux aléatoires : ceux dont le
/// programme contient des exercices chargés, au poids du corps ou tenus.
const List<String> propertyProfiles = <String>[
  'homme_25_musculation_debutant_3x60',
  'femme_45_musculation_salle_4x60',
  'proprietaire_streetlifting_avance',
  'musculation_maison_halteres_4x45',
  'femme_30_street_workout_parc_3x45',
  'materiel_complet_gouts_marques',
  'calisthenie_figures_4x75',
  'crossfit_5x60',
  'blessure_epaule_musculation_3x60',
  'niveaux_inconnus_sans_poids',
  'six_jours_musculation_avance_6x75',
  'debutant_forme_generale_maison_2x30',
  'street_streetlifting_4x90',
  'tres_grand_lourd',
  'petite_legere',
  'minimal_1x20',
];

/// Un journal aléatoire et ce qu'il faut pour interroger le moteur.
final class RandomCase {
  /// Cas.
  RandomCase({
    required this.seed,
    required this.profile,
    required this.block,
    required this.log,
    required this.today,
    required this.weekIndex,
    required this.dayIndex,
    required this.health,
    required this.place,
  });

  /// Graine.
  final int seed;

  /// Profil.
  final AthleteProfile profile;

  /// Bloc en cours.
  final ProgramBlock block;

  /// Journal.
  final TrainingLog log;

  /// « Aujourd'hui ».
  final CivilDate today;

  /// Séance demandée.
  final int weekIndex;

  /// Séance demandée.
  final int dayIndex;

  /// Bilan santé du jour.
  final HealthCheck? health;

  /// Lieu du jour.
  final Place? place;

  /// Entrée du moteur.
  AdaptInput get input =>
      AdaptInput(profile: profile, block: block, log: log, today: today);
}

int _between(SeededRandom r, int low, int high) =>
    low + r.nextInt(high - low + 1);

bool _chance(SeededRandom r, int percent) => r.nextInt(100) < percent;

HealthCheck? _randomHealth(SeededRandom r) {
  if (_chance(r, 35)) {
    return null;
  }
  int? scale(int percent) => _chance(r, percent) ? _between(r, 1, 5) : null;
  List<PainReport>? pains;
  if (_chance(r, 40)) {
    pains = <PainReport>[
      for (var i = r.nextInt(3); i > 0; i--)
        PainReport(
          zone: BodyZone.values[r.nextInt(BodyZone.values.length)],
          side: BodySide.values[r.nextInt(BodySide.values.length)],
          intensity: _between(r, 0, 10),
          phase: PainPhase.before,
        ),
    ];
  }
  return HealthCheck(
    overall: scale(70),
    sleepQuality: scale(30),
    sleepHours: _chance(r, 25) ? _between(r, 0, 12).toDouble() : null,
    energy: scale(30),
    mood: scale(15),
    soreness: scale(20),
    stress: scale(15),
    motivation: scale(15),
    nutrition: scale(10),
    hydration: scale(10),
    minutesAvailable: _chance(r, 15) ? _between(r, 0, 120) : null,
    pains: pains,
  );
}

/// Série aléatoire de l'exercice [info] ; [base] est la charge habituelle.
SetRecord _randomSet(
  SeededRandom r,
  ExerciseInfo info,
  ExercisePrescription? item,
  int order,
  int index,
  double base,
) {
  final mode = info.mode;
  final unit = info.exercise.unit;
  int? reps;
  int? seconds;
  double? distance;
  double? calories;
  double? load;
  if (unit == MeasureUnit.seconds) {
    seconds = _chance(r, 4) ? 0 : _between(r, 3, 150);
  } else if (unit == MeasureUnit.distance) {
    distance = _between(r, 50, 5000).toDouble();
  } else if (unit == MeasureUnit.calories) {
    calories = _between(r, 5, 60).toDouble();
  } else {
    reps = _chance(r, 4) ? 0 : _between(r, 1, _chance(r, 10) ? 45 : 15);
  }
  if (mode == CapacityMode.loaded) {
    var kg = base;
    if (_chance(r, 25)) {
      kg = info.grid.next(kg, up: _chance(r, 60));
    }
    if (_chance(r, 4)) {
      kg = info.grid.floor(kg * (_chance(r, 50) ? 1.6 : 0.5));
    }
    if (kg < info.grid.minimum) {
      kg = info.grid.minimum;
    }
    if (kg > 600) {
      kg = 600;
    }
    load = _chance(r, 3) ? null : kg;
  } else if (_chance(r, 5)) {
    load = _chance(r, 50) ? -10 : 5;
  }
  final pick = r.nextInt(100);
  final int? flames = pick < 15
      ? null
      : (pick < 27 ? 10 : (pick < 32 ? 1 : _between(r, 2, 9)));
  SetTarget? target;
  if (_chance(r, 80)) {
    final high = reps == null ? null : reps + r.nextInt(3);
    final low = high == null
        ? null
        : (_chance(r, 70) ? high : (high - 3 < 0 ? 0 : high - 3));
    final secondsHigh = seconds == null ? null : seconds + r.nextInt(10);
    target = SetTarget(
      repsLow: low,
      repsHigh: high,
      secondsLow: secondsHigh,
      secondsHigh: secondsHigh,
      loadKg: _chance(r, 85) ? load : null,
      flames: _chance(r, 10)
          ? null
          : (_chance(r, 8)
                ? 10
                : (_chance(r, 50) && flames != null
                      ? flames
                      : _between(r, 3, 9))),
    );
  }
  final kindPick = r.nextInt(100);
  return SetRecord(
    exerciseId: info.id,
    exerciseOrder: order,
    setIndex: index,
    kind: kindPick < 5
        ? SetKind.warmup
        : (kindPick < 8
              ? SetKind.test
              : (kindPick < 11 ? SetKind.calibration : SetKind.work)),
    externalLoadKg: load,
    reps: reps,
    seconds: seconds,
    distanceMeters: distance,
    calories: calories,
    flames: flames,
    success: flames == 10 ? _chance(r, 30) : _chance(r, 88),
    excluded: _chance(r, 3),
    slotId: item != null && _chance(r, 92) ? item.slotId : null,
    target: target,
  );
}

/// Enchaîne les séries des exercices deux à deux, dans l'ordre de
/// réalisation d'un superset : A1, B1, A2, B2…
void _interleave(List<SetRecord> sets) {
  final byOrder = <int, List<SetRecord>>{};
  for (final s in sets) {
    byOrder.putIfAbsent(s.exerciseOrder, () => <SetRecord>[]).add(s);
  }
  final groups = byOrder.values.toList();
  sets.clear();
  for (var g = 0; g < groups.length; g += 2) {
    final a = groups[g];
    final b = g + 1 < groups.length ? groups[g + 1] : const <SetRecord>[];
    for (var i = 0; i < a.length || i < b.length; i++) {
      if (i < a.length) {
        sets.add(a[i]);
      }
      if (i < b.length) {
        sets.add(b[i]);
      }
    }
  }
}

/// Journal aléatoire de graine [seed] sur l'un des [programs].
RandomCase randomCase(
  Catalog catalog,
  List<(AthleteProfile, SimProgram)> programs,
  int seed,
) {
  final r = SeededRandom(fnvMix(0x4A4F5552, seed));
  final (profile, program) = programs[r.nextInt(programs.length)];
  final blockPick = r.nextInt(100);
  final block = program.block(blockPick < 60 ? 0 : (blockPick < 88 ? 1 : 2));
  final book = ExerciseBook(catalog, profile);
  final weeks = block.pass2.weeks;
  final sessionCount = _chance(r, 6)
      ? 0
      : _between(r, 1, _chance(r, 30) ? 40 : 14);
  // Les séances partent de quelques semaines avant le bloc, ou du bloc.
  var day =
      block.pass1.startDate.dayNumber -
      (_chance(r, 35) ? _between(r, 7, 70) : 0);
  final bases = <String, double>{};
  final sessions = <SessionRecord>[];
  final extras = catalog.exercises;
  var cursor = 0;
  for (var s = 0; s < sessionCount; s++) {
    final week = weeks[(cursor ~/ 3) % weeks.length];
    final prescription = week.days[cursor % week.days.length];
    cursor += _chance(r, 85) ? 1 : 2;
    final inBlock = day >= block.pass1.startDate.dayNumber && _chance(r, 88);
    final sets = <SetRecord>[];
    var order = 0;
    for (final item in prescription.items) {
      if (_chance(r, 12)) {
        continue;
      }
      var info = book.find(item.exerciseId);
      var slotItem = inBlock ? item : null;
      if (_chance(r, 8)) {
        info = book.find(extras[r.nextInt(extras.length)].id);
        slotItem = _chance(r, 50) ? slotItem : null;
      }
      if (info == null) {
        continue;
      }
      var base = bases[info.id];
      if (base == null) {
        final grid = info.grid;
        base = grid.floor(grid.minimum + r.nextInt(120) * 1.0);
        if (base < grid.minimum) {
          base = grid.minimum;
        }
      } else if (_chance(r, 45)) {
        // Marche aléatoire d'une séance à l'autre, parfois brutale.
        final factor = _chance(r, 6)
            ? (_chance(r, 50) ? 1.5 : 0.6)
            : 1 + (r.nextDouble() - 0.45) * 0.16;
        base = info.grid.floor(base * factor);
        if (base < info.grid.minimum) {
          base = info.grid.minimum;
        }
      }
      bases[info.id] = base;
      final count = _between(r, 1, item.sets + 1);
      for (var i = 0; i < count; i++) {
        sets.add(_randomSet(r, info, slotItem, order, i, base));
      }
      order++;
    }
    if (_chance(r, 20)) {
      _interleave(sets);
    }
    final resume = _chance(r, 5);
    sessions.add(
      SessionRecord(
        id: 'r$seed-$s',
        date: CivilDate.fromDayNumber(day),
        origin: _chance(r, 92) ? SessionOrigin.program : SessionOrigin.imported,
        programRef: inBlock
            ? ProgramRef(
                blockId: block.pass1.blockId,
                weekIndex: week.weekIndex,
                dayIndex: prescription.dayIndex,
              )
            : (_chance(r, 50)
                  ? null
                  : ProgramRef(
                      blockId: 'ancien-bloc',
                      weekIndex: r.nextInt(6),
                      dayIndex: r.nextInt(4),
                    )),
        resume: resume,
        completed: _chance(r, 90),
        durationMinutes: _chance(r, 60) ? _between(r, 10, 150) : null,
        bodyWeightKg: _chance(r, 20) ? _between(r, 45, 120).toDouble() : null,
        place: _chance(r, 20) ? Place.values[r.nextInt(3)] : null,
        healthCheck: _randomHealth(r),
        sets: sets,
        pains: <PainReport>[
          if (_chance(r, 12))
            PainReport(
              zone: BodyZone.values[r.nextInt(BodyZone.values.length)],
              side: BodySide.values[r.nextInt(BodySide.values.length)],
              intensity: _between(r, 0, 10),
              phase: _chance(r, 50) ? PainPhase.during : PainPhase.after,
            ),
        ],
      ),
    );
    final gap = r.nextInt(100);
    day += gap < 10 ? 0 : (gap < 80 ? _between(r, 1, 4) : (gap < 95 ? 7 : 25));
  }
  final todayNumber = sessions.isEmpty
      ? block.pass1.startDate.dayNumber + r.nextInt(10)
      : sessions.last.date.dayNumber + (_chance(r, 25) ? 0 : _between(r, 1, 9));
  final week = weeks[r.nextInt(weeks.length)];
  final prescription = week.days[r.nextInt(week.days.length)];
  return RandomCase(
    seed: seed,
    profile: profile,
    block: block,
    log: TrainingLog(sessions: sessions),
    today: CivilDate.fromDayNumber(todayNumber),
    weekIndex: week.weekIndex,
    dayIndex: prescription.dayIndex,
    health: _randomHealth(r),
    place: _chance(r, 12) ? Place.values[r.nextInt(3)] : null,
  );
}

/// Manquements du moteur [engine] sur le cas [c] (liste vide = tout tient).
List<String> checkCase(Catalog catalog, KalisAdapt engine, RandomCase c) {
  final out = <String>[];
  final p = engine.params;
  final r = SeededRandom(fnvMix(0x43484543, c.seed));
  final book = ExerciseBook(catalog, c.profile);
  final where = 'graine ${c.seed}';
  final request = SessionRequest(
    input: c.input,
    weekIndex: c.weekIndex,
    dayIndex: c.dayIndex,
    healthCheck: c.health,
    place: c.place,
  );
  final session = engine.prescribeSession(catalog, request);
  for (final v in session.validate()) {
    out.add('$where, séance : ${v.path} ${v.code} ${v.message}');
  }
  out.addAll(
    checkSession(
      catalog,
      c.profile,
      c.block,
      c.log,
      session,
      p,
      health: c.health,
    ).map((v) => '$where, $v'),
  );
  // I3 : aucun exercice exclu par une douleur du jour n'est prescrit.
  for (final pain in c.health?.pains ?? const <PainReport>[]) {
    if (pain.intensity <= p.painThreshold) {
      continue;
    }
    for (final item in session.items) {
      final info = book.find(item.exerciseId);
      if (info != null &&
          info.excludedByPain(
            pain.zone,
            pain.intensity,
            hard: p.painHard,
            severe: p.painSevere,
          )) {
        out.add(
          '$where : ${item.exerciseId} prescrit malgré une douleur '
          '${pain.zone.code} à ${pain.intensity}',
        );
      }
    }
  }
  // I6 : même sortie sans cache.
  final text = jsonText(session.toJson());
  final fresh = KalisAdapt(params: p);
  if (jsonText(fresh.prescribeSession(catalog, request).toJson()) != text) {
    out.add('$where : séance différente sans cache');
  }
  // I6 : journal prolongé d'un appel à l'autre = journal donné en une fois.
  if (c.seed % 4 == 1 && c.log.sessions.length >= 2) {
    final grown = KalisAdapt(params: p);
    final half = c.log.sessions.length ~/ 2;
    grown.prescribeSession(
      catalog,
      SessionRequest(
        input: AdaptInput(
          profile: c.profile,
          block: c.block,
          log: TrainingLog(sessions: c.log.sessions.sublist(0, half)),
          today: c.today,
        ),
        weekIndex: c.weekIndex,
        dayIndex: c.dayIndex,
        healthCheck: c.health,
        place: c.place,
      ),
    );
    if (jsonText(grown.prescribeSession(catalog, request).toJson()) != text) {
      out.add('$where : séance différente quand le journal est prolongé');
    }
  }
  // I7 : bilan sans réponse = pas de bilan.
  if (c.health == null) {
    final empty = engine.prescribeSession(
      catalog,
      SessionRequest(
        input: c.input,
        weekIndex: c.weekIndex,
        dayIndex: c.dayIndex,
        healthCheck: const HealthCheck(),
        place: c.place,
      ),
    );
    if (jsonText(empty.toJson()) != text) {
      out.add('$where : un bilan vide change la séance');
    }
  }
  // I8 : une séance « reprise » de plus ne change rien.
  if (c.seed % 4 == 0 && c.log.sessions.isNotEmpty) {
    final copy = c.log.sessions.last;
    final withResume = TrainingLog(
      sessions: <SessionRecord>[
        ...c.log.sessions,
        SessionRecord(
          id: '${copy.id}-reprise',
          date: copy.date,
          origin: copy.origin,
          programRef: copy.programRef,
          resume: true,
          completed: true,
          healthCheck: copy.healthCheck,
          sets: copy.sets,
          pains: <PainReport>[
            PainReport(
              zone: BodyZone.shoulder,
              side: BodySide.both,
              intensity: 9,
              phase: PainPhase.during,
            ),
          ],
        ),
      ],
    );
    final again = KalisAdapt(params: p).prescribeSession(
      catalog,
      SessionRequest(
        input: AdaptInput(
          profile: c.profile,
          block: c.block,
          log: withResume,
          today: c.today,
        ),
        weekIndex: c.weekIndex,
        dayIndex: c.dayIndex,
        healthCheck: c.health,
        place: c.place,
      ),
    );
    if (jsonText(again.toJson()) != text) {
      out.add('$where : une séance « reprise » change la séance prescrite');
    }
  }

  // Conseils pendant la séance : quelques séries faites au hasard.
  final done = <SetRecord>[];
  var order = 0;
  var advices = 0;
  for (final item in session.items) {
    if (advices >= 8) {
      break;
    }
    final info = book.find(item.exerciseId);
    if (info == null || info.mode == null) {
      continue;
    }
    final base = item.startLoadKg ?? info.grid.minimum + 20;
    final count = _between(r, 1, item.sets);
    for (var i = 0; i < count; i++) {
      final targets = item.setTargets;
      final shown = targets == null || targets.isEmpty
          ? null
          : targets[i < targets.length ? i : targets.length - 1];
      final made = _randomSet(r, info, item, order, i, info.grid.floor(base));
      // Trois fois sur quatre, la cible enregistrée est celle affichée.
      done.add(
        _chance(r, 75) && shown != null
            ? made.copyWith(target: shown, slotId: item.slotId)
            : made.copyWith(slotId: item.slotId),
      );
      final adviceRequest = AdviceRequest(
        input: c.input,
        session: session,
        done: List<SetRecord>.of(done),
        slotId: item.slotId,
        healthCheck: c.health,
      );
      final advice = engine.adviseNextSet(catalog, adviceRequest);
      advices++;
      for (final v in advice.validate()) {
        out.add('$where, conseil : ${v.path} ${v.code} ${v.message}');
      }
      out.addAll(
        checkAdvice(
          catalog,
          c.profile,
          session,
          done,
          advice,
          p,
        ).map((v) => '$where, $v'),
      );
      if (advices == 1 &&
          jsonText(fresh.adviseNextSet(catalog, adviceRequest).toJson()) !=
              jsonText(advice.toJson())) {
        out.add('$where : conseil différent sans cache');
      }
      if (c.health != null && advices <= 3) {
        // Appelant qui ne redonne pas le bilan du jour : les verrous de la
        // séance tiennent quand même.
        final bare = engine.adviseNextSet(
          catalog,
          AdviceRequest(
            input: c.input,
            session: session,
            done: List<SetRecord>.of(done),
            slotId: item.slotId,
          ),
        );
        for (final v in bare.validate()) {
          out.add('$where, conseil sans bilan : ${v.path} ${v.code}');
        }
        out.addAll(
          checkAdvice(
            catalog,
            c.profile,
            session,
            done,
            bare,
            p,
          ).map((v) => '$where, sans bilan, $v'),
        );
      }
    }
    order++;
  }
  // Séries enchaînées : après des séries d'autres emplacements, le conseil
  // d'un emplacement déjà commencé tient encore ses invariants.
  final started = <String>{};
  for (final s in done) {
    final slot = s.slotId;
    if (slot == null || !started.add(slot) || started.length > 3) {
      continue;
    }
    if (done.last.slotId == slot) {
      continue;
    }
    final late = engine.adviseNextSet(
      catalog,
      AdviceRequest(
        input: c.input,
        session: session,
        done: List<SetRecord>.of(done),
        slotId: slot,
        healthCheck: c.health,
      ),
    );
    for (final v in late.validate()) {
      out.add('$where, conseil enchaîné : ${v.path} ${v.code}');
    }
    out.addAll(
      checkAdvice(
        catalog,
        c.profile,
        session,
        done,
        late,
        p,
      ).map((v) => '$where, enchaîné, $v'),
    );
  }

  // Revue.
  final review = engine.review(catalog, c.input);
  for (final v in review.validate()) {
    out.add('$where, revue : ${v.path} ${v.code} ${v.message}');
  }
  // I4 : niveau de déblocage recalculé depuis le journal seul. Borne haute
  // des semaines de données : les semaines civiles qui ont une séance.
  final weeks = <int>{};
  for (final s in c.log.countedSessions) {
    if (s.date.dayNumber <= c.today.dayNumber) {
      weeks.add(weekOfDay(s.date.dayNumber));
    }
  }
  final allowed = unlockLevelFor(weeks.length, c.block.pass1.blockIndex, p);
  if (review.summary.unlockLevel.index > allowed.index) {
    out.add(
      '$where : niveau ${review.summary.unlockLevel.code} avec '
      '${weeks.length} semaines et ${c.block.pass1.blockIndex} bloc(s)',
    );
  }
  for (final proposal in review.proposals) {
    if (proposal.unlockLevel.index > review.summary.unlockLevel.index) {
      out.add(
        '$where : proposition ${proposal.id} de niveau '
        '${proposal.unlockLevel.code} au niveau '
        '${review.summary.unlockLevel.code}',
      );
    }
    final least = switch (proposal.kind) {
      ProposalKind.volume || ProposalKind.deload => UnlockLevel.volume,
      ProposalKind.exerciseSwap => UnlockLevel.exerciseSwap,
      ProposalKind.sessionRestructure => UnlockLevel.sessionRestructure,
      ProposalKind.blockRestructure => UnlockLevel.blockRestructure,
      ProposalKind.load ||
      ProposalKind.reps ||
      ProposalKind.painSparing ||
      ProposalKind.schedule => UnlockLevel.loadsReps,
    };
    if (least.index > allowed.index) {
      out.add(
        '$where : proposition ${proposal.kind.code} avant son niveau '
        '(${weeks.length} semaines, ${c.block.pass1.blockIndex} bloc(s))',
      );
    }
    final next = applyProposal(c.block, proposal);
    for (final v in next.validate()) {
      out.add('$where, bloc après ${proposal.id} : ${v.path} ${v.code}');
    }
  }
  if (c.seed % 5 == 0 &&
      jsonText(fresh.review(catalog, c.input).toJson()) !=
          jsonText(review.toJson())) {
    out.add('$where : revue différente sans cache');
  }
  return out;
}

/// Programmes des profils de [propertyProfiles].
List<(AthleteProfile, SimProgram)> propertyPrograms() =>
    <(AthleteProfile, SimProgram)>[
      for (final key in propertyProfiles) (profileOf(key), programOf(key)),
    ];

/// Déclare les tests du fichier de rang [file].
void propertyTests(int file) {
  final catalog = loadCatalog();
  final programs = propertyPrograms();
  const chunk = 160;
  for (var from = 0; from < journalsPerFile; from += chunk) {
    final first = file * journalsPerFile + from;
    test('journaux aléatoires $first à ${first + chunk - 1}', () {
      final engine = KalisAdapt();
      final failures = <String>[];
      for (var seed = first; seed < first + chunk; seed++) {
        failures.addAll(
          checkCase(catalog, engine, randomCase(catalog, programs, seed)),
        );
        if (failures.length > 20) {
          break;
        }
      }
      expect(failures, isEmpty);
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}
