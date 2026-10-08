// Accès aux données de kalis_core depuis les tests (`dart test` s'exécute à
// la racine du paquet ; kalis_core est le dossier voisin).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';

/// Racine du paquet kalis_core.
const String corePath = '../kalis_core';

Catalog? _catalog;

/// Catalogue chargé (une fois par fichier de test).
Catalog loadCatalog() => _catalog ??= Catalog.fromJsonBytes(
  gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
);

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

List<ProfileFixture>? _profiles;

/// Les 40 profils types de kalis_core.
List<ProfileFixture> loadProfiles() => _profiles ??= readProfileFixtures(
  readJsonObject('$corePath/test/fixtures/profiles.json'),
);

/// Profil type de clé [key].
AthleteProfile profileOf(String key) =>
    loadProfiles().firstWhere((p) => p.key == key).profile;

Map<String, Object?>? _street;

Map<String, Object?> _streetFixtures() =>
    _street ??= readJsonObject('test/fixtures/street_profiles.json.gz');

/// Clés des 17 profils street du banc (`kalis_bench`), triées.
List<String> streetKeys() => _streetFixtures().keys.toList()..sort();

/// Profil street du banc de clé [key], tel que l'adaptateur de
/// `kalis_bench` le remet aux moteurs (schéma 3).
AthleteProfile streetProfile(String key) {
  final entry = _streetFixtures()[key]! as Map<String, Object?>;
  return AthleteProfile.fromJson(entry['profile']! as Map<String, Object?>);
}

/// Athlète simulé du profil street de clé [key].
AthleteSpec streetAthlete(String key) {
  final entry = _streetFixtures()[key]! as Map<String, Object?>;
  return athleteFromJson(entry['athlete']! as Map<String, Object?>);
}

/// Programme de `kalis_plan` du profil street de clé [key] (bloc au
/// contrat 0.4.0) ; [inject] : avec une technique du contrat par
/// emplacement (programme de test).
SimProgram streetProgram(String key, {bool inject = false, int offset = 0}) =>
    SimProgram(
      loadCatalog(),
      _plan,
      streetProfile(key),
      transform: inject ? (b) => injectTechniques(b, offset: offset) : null,
    );

final KalisPlan _plan = KalisPlan();
final Map<String, SimProgram> _programs = <String, SimProgram>{};

/// Programme (blocs de kalis_plan) du profil type de clé [key].
SimProgram programOf(String key) => _programs.putIfAbsent(
  key,
  () => SimProgram(loadCatalog(), _plan, profileOf(key)),
);

/// Texte JSON canonique d'un objet du contrat.
String jsonText(Map<String, Object?> json) => jsonEncode(json);

/// Politique `kalis_adapt` qui contrôle chaque sortie du moteur au
/// passage : validité du contrat et invariants de sécurité (voir
/// `CONTRAT.md`, § Invariants). Les manquements sont notés dans
/// [violations].
final class CheckedPolicy implements CoachAwarePolicy {
  /// Politique contrôlée du moteur [engine].
  CheckedPolicy(this.engine) : inner = KalisAdaptPolicy(engine);

  /// Moteur.
  final KalisAdapt engine;

  /// Politique contrôlée.
  final KalisAdaptPolicy inner;

  /// Manquements relevés.
  final List<String> violations = <String>[];

  /// Séances prescrites.
  int sessions = 0;

  /// Conseils demandés.
  int advices = 0;

  @override
  String get name => inner.name;

  @override
  bool get rich => inner.rich;

  @override
  List<IntraSessionAdvice> takeAdvices() => inner.takeAdvices();

  @override
  SessionPlan plan(SessionContext c) {
    final session = inner.plan(c);
    sessions++;
    for (final v in session.validate()) {
      violations.add('séance ${c.date.iso} : ${v.path} ${v.code}');
    }
    violations.addAll(
      checkSession(
        c.catalog,
        c.profile,
        c.block,
        c.log,
        session,
        engine.params,
        health: c.health,
        coached: rich && blockCoached(c.block),
      ),
    );
    return session;
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    if (index > 0) {
      advices++;
      final advice = engine.adviseNextSet(
        c.catalog,
        AdviceRequest(
          input: AdaptInput(
            profile: c.profile,
            block: c.block,
            log: c.log,
            today: c.date,
          ),
          session: inner.lastSession!,
          done: done,
          slotId: item.slotId,
          healthCheck: c.health,
        ),
      );
      for (final v in advice.validate()) {
        violations.add('conseil ${c.date.iso} : ${v.path} ${v.code}');
      }
      violations.addAll(
        checkAdvice(
          c.catalog,
          c.profile,
          inner.lastSession!,
          done,
          advice,
          engine.params,
          coached: rich && blockCoached(c.block),
        ),
      );
    }
    return inner.nextSet(c, item, index, done);
  }

  @override
  void finish(SessionContext c, SessionRecord record) =>
      inner.finish(c, record);

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

/// Vrai si le moteur prend la série [s] en compte pour l'exercice chargé
/// [info] : utilisable, hors échauffement, avec des répétitions et une
/// charge totale positive.
bool countsFor(ExerciseInfo info, SetRecord s) {
  if (s.exerciseId != info.id ||
      !s.isUsable ||
      s.kind == SetKind.warmup ||
      s.reps == null) {
    return false;
  }
  return info.fraction > 0 || (s.externalLoadKg ?? 0) > 0;
}

/// Dernière séance de [log] (hors « reprise ») où l'exercice [info] a des
/// séries prises en compte ; rend leurs charges externes.
List<double>? lastLoadsOf(TrainingLog log, ExerciseInfo info) {
  final sessions = log.countedSessions.toList();
  for (var i = sessions.length - 1; i >= 0; i--) {
    final loads = <double>[
      for (final s in sessions[i].sets)
        if (countsFor(info, s)) s.externalLoadKg ?? 0,
    ];
    if (loads.isNotEmpty) {
      return loads;
    }
  }
  return null;
}

/// Vrai si la dernière séance de l'exercice [info] dans [log] compte un
/// échec qui n'était pas prévu par la cible.
bool lastHadUnplannedFailure(TrainingLog log, ExerciseInfo info) {
  final sessions = log.countedSessions.toList();
  for (var i = sessions.length - 1; i >= 0; i--) {
    var seen = false;
    var failed = false;
    for (final s in sessions[i].sets) {
      if (!countsFor(info, s)) {
        continue;
      }
      seen = true;
      final missed =
          s.flames == Flames.failure || (s.flames == null && !s.success);
      final planned = (s.target?.flames ?? 0) >= Flames.failure;
      if (missed && !planned) {
        failed = true;
      }
    }
    if (seen) {
      return failed;
    }
  }
  return false;
}

/// Plus légère des charges échouées (échec non prévu) de la dernière
/// séance de l'exercice [info] dans [log], ou `null`.
double? lowestFailedLoad(TrainingLog log, ExerciseInfo info) {
  final sessions = log.countedSessions.toList();
  for (var i = sessions.length - 1; i >= 0; i--) {
    var seen = false;
    double? lowest;
    for (final s in sessions[i].sets) {
      if (!countsFor(info, s)) {
        continue;
      }
      seen = true;
      final missed =
          s.flames == Flames.failure || (s.flames == null && !s.success);
      final planned = (s.target?.flames ?? 0) >= Flames.failure;
      final kg = s.externalLoadKg ?? 0;
      if (missed && !planned && (lowest == null || kg < lowest)) {
        lowest = kg;
      }
    }
    if (seen) {
      return lowest;
    }
  }
  return null;
}

/// Nombre de séances de [log] (hors « reprise ») où l'exercice [info] a
/// des séries prises en compte.
int sessionsOfExercise(TrainingLog log, ExerciseInfo info) {
  var count = 0;
  for (final session in log.countedSessions) {
    if (session.sets.any((s) => countsFor(info, s))) {
      count++;
    }
  }
  return count;
}

/// Vrai si le moteur prend la série [s] en compte pour l'exercice sans
/// charge [info] (répétitions ou secondes).
bool countsDirect(ExerciseInfo info, SetRecord s) {
  if (s.exerciseId != info.id || !s.isUsable || s.kind == SetKind.warmup) {
    return false;
  }
  return (info.mode == CapacityMode.hold ? s.seconds : s.reps) != null;
}

/// Dernière séance de [log] où l'exercice sans charge [info] a des séries
/// prises en compte : (plus grande série, échec non prévu, jour), ou
/// `null`.
(int, bool, int)? lastDirectOf(TrainingLog log, ExerciseInfo info) {
  final hold = info.mode == CapacityMode.hold;
  final sessions = log.countedSessions.toList();
  for (var i = sessions.length - 1; i >= 0; i--) {
    var seen = false;
    var top = 0;
    var failed = false;
    for (final s in sessions[i].sets) {
      if (!countsDirect(info, s)) {
        continue;
      }
      seen = true;
      final amount = (hold ? s.seconds : s.reps)!;
      if (amount > top) {
        top = amount;
      }
      final missed =
          s.flames == Flames.failure || (s.flames == null && !s.success);
      final planned = (s.target?.flames ?? 0) >= Flames.failure;
      if (missed && !planned) {
        failed = true;
      }
    }
    if (seen) {
      return (top, failed, sessions[i].date.dayNumber);
    }
  }
  return null;
}

/// Jour de la dernière séance de l'exercice [info] dans [log], ou `null`.
int? lastDayOf(TrainingLog log, ExerciseInfo info) {
  int? day;
  for (final session in log.countedSessions) {
    for (final s in session.sets) {
      if (countsFor(info, s)) {
        day = session.date.dayNumber;
        break;
      }
    }
  }
  return day;
}

/// Zones signalées au-dessus du seuil dans [log] depuis le jour [since]
/// compris (bilan ou séance), et dans le bilan du jour [today].
Set<BodyZone> painsSince(
  TrainingLog log,
  int? since,
  HealthCheck? today,
  AdaptParams p,
) {
  final zones = <BodyZone>{};
  for (final session in log.countedSessions) {
    if (since != null && session.date.dayNumber < since) {
      continue;
    }
    for (final r in <PainReport>[
      ...?session.healthCheck?.pains,
      ...session.pains,
    ]) {
      if (r.intensity > p.painThreshold) {
        zones.add(r.zone);
      }
    }
  }
  for (final r in today?.pains ?? const <PainReport>[]) {
    if (r.intensity > p.painThreshold) {
      zones.add(r.zone);
    }
  }
  return zones;
}

/// La série [s] telle que le moteur la lit quand elle porte des champs de
/// `kalis_core` 0.4.0 (voir `readLine`) : `null` si elle ne compte pas
/// (échauffement, descente accentuée, série relancée sans parties) ;
/// charge de la partie lue (le total de la ligne reste sa quantité) ; une
/// ligne sous le plancher de propreté compte comme un échec.
SetRecord? asRead(SetRecord s, ExerciseInfo? info, ExercisePrescription? item) {
  if (info == null) {
    return s;
  }
  final hold = info.mode == CapacityMode.hold;
  final reading = readLine(s, hold: hold, item: item);
  if (reading == null) {
    return s;
  }
  if (reading.skip) {
    return null;
  }
  var out = s;
  final load = reading.loadKg;
  if (load != null) {
    out = out.copyWith(externalLoadKg: load);
  }
  if (reading.unclean) {
    out = out.copyWith(flames: Flames.failure);
  }
  return out;
}

/// Le journal [log] tel que le moteur le lit pour le bloc [block] (mode
/// coach).
TrainingLog logAsRead(
  Catalog catalog,
  AthleteProfile profile,
  ProgramBlock block,
  TrainingLog log,
  AdaptParams p,
) {
  final book = ExerciseBook(catalog, profile);
  final view = BlockView(block, p, profile: profile);
  return TrainingLog(
    sessions: <SessionRecord>[
      for (final session in log.sessions)
        session.copyWith(
          sets: <SetRecord>[
            for (final s in session.sets)
              if (asRead(
                    s,
                    book.find(s.exerciseId),
                    view.item(session.programRef, s.slotId, s.exerciseId),
                  )
                  case final read?)
                read,
          ],
        ),
    ],
  );
}

/// Invariants de sécurité d'une séance prescrite, lus dans le journal seul
/// (sans l'état du moteur) :
///
/// 1. mouvement principal hors calibrage (l'exercice a déjà trois séances
///    au journal) et hors test : charge totale ≤ +10 % de la plus forte
///    charge de la dernière séance de l'exercice — ou un seul cran de la
///    grille quand le plus petit cran dépasse 10 % ;
/// 2. aucune hausse après une série à l'échec non prévue, et jamais plus
///    que la plus légère des charges échouées ;
/// 3. aucune hausse sur un exercice d'une zone signalée douloureuse
///    au-dessus du seuil depuis sa dernière séance ;
/// 4. charges sur la grille du matériel ;
/// 5. exercices sans charge (répétitions, tenues), hors test : dans les
///    cas 2 et 3, aucune cible au-dessus de la plus grande série de la
///    dernière séance.
List<String> checkSession(
  Catalog catalog,
  AthleteProfile profile,
  ProgramBlock block,
  TrainingLog journal,
  SessionPlan session,
  AdaptParams p, {
  HealthCheck? health,
  bool coached = false,
}) {
  final out = <String>[];
  final book = ExerciseBook(catalog, profile);
  final bodyWeight = profile.bodyWeightKg ?? p.referenceBodyWeightKg;
  final log = coached
      ? logAsRead(catalog, profile, block, journal, p)
      : journal;
  if (coached) {
    out.addAll(checkCoachSession(catalog, profile, block, log, session, p));
  }
  out.addAll(
    checkEndurance(
      catalog,
      profile,
      block,
      journal,
      session,
      p,
      health: health,
    ),
  );
  final roles = <String, SlotRole>{
    for (final d in block.pass1.days)
      for (final s in d.slots) s.slotId: s.role,
  };
  for (final item in session.items) {
    final info = book.find(item.exerciseId);
    if (info != null &&
        (info.mode == CapacityMode.reps || info.mode == CapacityMode.hold) &&
        item.kind != SetKind.test) {
      final last = lastDirectOf(log, info);
      if (last != null) {
        final (top, failed, lastDay) = last;
        final hold = info.mode == CapacityMode.hold;
        var locked = failed ? 'un échec non prévu' : null;
        for (final zone in painsSince(log, lastDay, health, p)) {
          if (info.zoneLevel(zone) >= 0.5) {
            locked ??= 'une douleur (${zone.code})';
          }
        }
        final cap = top < 1 ? 1 : top;
        if (locked != null) {
          for (final t in item.setTargets ?? const <SetTarget>[]) {
            final high = hold ? t.secondsHigh : t.repsHigh;
            if (high != null && high > cap) {
              out.add(
                '${session.date.iso} ${item.exerciseId} : cible $high après '
                '$locked (dernière séance : $top au plus)',
              );
            }
          }
        }
      }
    }
    if (info == null || info.mode != CapacityMode.loaded) {
      continue;
    }
    final targets = item.setTargets;
    final loads = <double>[
      if (item.startLoadKg != null) item.startLoadKg!,
      if (targets != null)
        for (final t in targets)
          if (t.loadKg != null) t.loadKg!,
    ];
    if (loads.isEmpty) {
      continue;
    }
    final where = '${session.date.iso} ${item.exerciseId}';
    final before = lastLoadsOf(log, info);
    for (final kg in loads) {
      // Sur la grille, ou reprise telle quelle d'une charge de la dernière
      // séance sous la plus petite charge de la grille.
      final echo =
          before != null &&
          kg < info.grid.minimum &&
          before.any((b) => (b - kg).abs() < 0.011);
      if ((info.grid.nearest(kg) - kg).abs() > 0.011 && !echo) {
        out.add('$where : charge $kg hors grille');
      }
    }
    if (before == null) {
      continue;
    }
    var reference = before.first;
    for (final kg in before) {
      if (kg > reference) {
        reference = kg;
      }
    }
    var top = loads.first;
    for (final kg in loads) {
      if (kg > top) {
        top = kg;
      }
    }
    final bw = info.fraction * bodyWeight;
    final rise = (top + bw) / (reference + bw) - 1;
    final oneStep = info.grid.next(reference, up: true);
    final test = item.kind == SetKind.test;
    if (!coached &&
        roles[item.slotId] == SlotRole.main &&
        sessionsOfExercise(log, info) >= p.calibrationSessions &&
        !test &&
        rise > p.maxUpMain + 1e-6 &&
        top > oneStep + 0.011) {
      out.add(
        '$where : +${(rise * 100).toStringAsFixed(1)} % sur un mouvement '
        'principal ($reference → $top kg)',
      );
    }
    if (test && coached) {
      // Tentatives et tests : bornés par l'estimation (voir
      // `checkCoachSession`), pas par la dernière séance.
      continue;
    }
    if (top > reference + 0.011 && lastHadUnplannedFailure(log, info)) {
      out.add(
        '$where : hausse après un échec non prévu ($reference → $top) '
        '${_lastLines(journal, info)} ${item.technique?.kind.code} '
        '${item.reasons.map((r) => '${r.code}${r.params}').join(',')}',
      );
    }
    final failedAt = lowestFailedLoad(log, info);
    if (failedAt != null && top > failedAt + 0.011) {
      out.add('$where : $top kg après un échec non prévu à $failedAt kg');
    }
    if (top > reference + 0.011) {
      final zones = painsSince(log, lastDayOf(log, info), health, p);
      for (final zone in zones) {
        if (info.zoneLevel(zone) >= 0.5) {
          out.add(
            '$where : hausse sur une zone douloureuse (${zone.code}, '
            '$reference → $top)',
          );
        }
      }
    }
  }
  return out;
}

/// Invariants d'un conseil : jamais de hausse de charge après une série à
/// l'échec non prévue dans la séance (les séries d'un autre emplacement
/// faites entre-temps n'y changent rien), ni quand la séance est verrouillée
/// (bilan bas, zone douloureuse) ; charge sur la grille ; sans charge,
/// jamais plus que la dernière série après un échec. Une série sans cible
/// enregistrée est jugée d'après la cible de la séance [session], comme le
/// fait le moteur.
List<String> checkAdvice(
  Catalog catalog,
  AthleteProfile profile,
  SessionPlan session,
  List<SetRecord> lines,
  IntraSessionAdvice advice,
  AdaptParams p, {
  bool coached = false,
}) {
  final out = <String>[];
  final book = ExerciseBook(catalog, profile);
  final info = book.find(advice.exerciseId);
  final done = <SetRecord>[
    for (final s in lines)
      if (!coached)
        s
      else if (asRead(
            s,
            book.find(s.exerciseId),
            <ExercisePrescription?>[
              for (final it in session.items)
                if (it.slotId == s.slotId) it,
              null,
            ].first,
          )
          case final read?)
        read,
  ];
  var attemptLine = false;
  for (final item in session.items) {
    if (item.slotId == advice.slotId || item.exerciseId == advice.exerciseId) {
      final kind = item.test?.kind;
      if ((item.kind == SetKind.test &&
              (kind == TestKind.oneRm || kind == TestKind.attemptSimulation)) ||
          (item.setTargets ?? const <SetTarget>[]).any(
            (t) => t.role == SetRole.attempt,
          )) {
        attemptLine = true;
      }
    }
  }
  if (attemptLine) {
    // Tentatives : règle propre (même barre après un échec, hausse après
    // une réussite), contrôlée par `checkCoachSession` et les tests des
    // tentatives.
    return out;
  }
  if (info != null &&
      (info.mode == CapacityMode.reps || info.mode == CapacityMode.hold)) {
    final hold = info.mode == CapacityMode.hold;
    List<SetTarget>? shownDirect;
    for (final item in session.items) {
      if (item.slotId == advice.slotId) {
        shownDirect = item.setTargets;
      }
    }
    int? lastAmount;
    var failedDirect = false;
    var rank = 0;
    for (final s in done) {
      if (s.slotId != advice.slotId || !countsDirect(info, s)) {
        continue;
      }
      lastAmount = hold ? s.seconds : s.reps;
      final recorded = s.target;
      int? aimed;
      if (recorded != null &&
          recorded.flames != null &&
          (hold
                  ? (recorded.secondsLow ?? recorded.secondsHigh)
                  : (recorded.repsLow ?? recorded.repsHigh)) !=
              null) {
        aimed = recorded.flames;
      } else if (shownDirect != null && rank < shownDirect.length) {
        aimed = shownDirect[rank].flames;
      }
      final missed =
          s.flames == Flames.failure || (s.flames == null && !s.success);
      if (missed && (aimed ?? 0) < Flames.failure) {
        failedDirect = true;
      }
      rank++;
    }
    final high = hold ? advice.nextSeconds : advice.nextRepsHigh;
    if (failedDirect && lastAmount != null && high != null) {
      final cap = lastAmount < 1 ? 1 : lastAmount;
      if (high > cap) {
        out.add(
          'conseil ${advice.exerciseId} : cible $high après un échec '
          '(dernière série : $lastAmount) ${_trace(session, done, advice)}',
        );
      }
    }
    return out;
  }
  final next = advice.nextLoadKg;
  if (info == null || next == null || info.mode != CapacityMode.loaded) {
    return out;
  }

  List<SetTarget>? shown;
  for (final item in session.items) {
    if (item.slotId == advice.slotId) {
      shown = item.setTargets;
    }
  }
  double? last;
  var failed = false;
  var index = 0;
  for (final s in done) {
    if (s.slotId != advice.slotId || !countsFor(info, s)) {
      continue;
    }
    last = s.externalLoadKg ?? 0;
    final recorded = s.target;
    int? aimed;
    if (recorded != null &&
        recorded.flames != null &&
        (recorded.repsLow ?? recorded.repsHigh) != null) {
      aimed = recorded.flames;
    } else if (shown != null && index < shown.length) {
      aimed = shown[index].flames;
    }
    final missed =
        s.flames == Flames.failure || (s.flames == null && !s.success);
    if (missed && (aimed ?? 0) < Flames.failure) {
      failed = true;
    }
    index++;
  }
  // Sur la grille, ou reprise telle quelle de la charge de la série
  // précédente (série suivante « comme prévu »).
  if ((info.grid.nearest(next) - next).abs() > 0.011 &&
      (last == null || (last - next).abs() > 0.011)) {
    out.add('conseil ${advice.exerciseId} : charge $next hors grille');
  }
  if (last != null && failed && next > last + 0.011) {
    out.add(
      'conseil ${advice.exerciseId} : hausse après un échec ($last → $next)'
      ' ${_trace(session, done, advice)}',
    );
  }
  if (advice.action == IntraSessionAction.loadUp && failed) {
    out.add('conseil ${advice.exerciseId} : load_up après un échec');
  }
  // Séance verrouillée : bilan bas (dit par la séance) ou zone douloureuse
  // retenue pour cet exercice.
  String? locked;
  for (final r in session.reasons) {
    if (r.code == ReasonCodes.adaptLoadHeld &&
        '${r.params['cause']}'.startsWith('health')) {
      locked = 'bilan bas';
    }
  }
  for (final item in session.items) {
    if (item.slotId != advice.slotId) {
      continue;
    }
    for (final r in item.reasons) {
      if (r.code != ReasonCodes.adaptPainReported) {
        continue;
      }
      final intensity = r.params['intensity'];
      for (final zone in BodyZone.values) {
        if (zone.code == r.params['zone'] &&
            intensity is num &&
            intensity > p.painThreshold &&
            info.zoneLevel(zone) >= 0.5) {
          locked ??= 'douleur ${zone.code}';
        }
      }
    }
  }
  if (last != null && locked != null && next > last + 0.011) {
    out.add(
      'conseil ${advice.exerciseId} : hausse malgré $locked ($last → $next)'
      ' ${_trace(session, done, advice)}',
    );
  }
  return out;
}

/// Invariants propres au mode coach (blocs au contrat 0.4.0), lus dans le
/// journal, le bloc et la séance seuls :
///
/// C1. hors calibrage et hors test, la charge de tête d'un mouvement
///     principal n'excède jamais la plus grande de : la charge écrite par le bloc ;
///     +10 % (ou un cran) de la plus lourde charge de l'exercice au
///     journal ;
/// C2. jamais plus de séries que le bloc n'en écrit (affûtage, décharge et
///     toute autre semaine : le volume ne s'ajoute pas le jour même) ;
/// C3. une technique n'est servie qu'au niveau d'expérience qui y donne
///     accès ;
/// C4. les tentatives d'un test de maximum ne décroissent jamais.
List<String> checkCoachSession(
  Catalog catalog,
  AthleteProfile profile,
  ProgramBlock block,
  TrainingLog log,
  SessionPlan session,
  AdaptParams p,
) {
  final out = <String>[];
  final book = ExerciseBook(catalog, profile);
  final bodyWeight = profile.bodyWeightKg ?? p.referenceBodyWeightKg;
  final experience = profile.experience;
  final level = experience == null ? 1 : experience.index;
  final roles = <String, SlotRole>{
    for (final d in block.pass1.days)
      for (final s in d.slots) s.slotId: s.role,
  };
  final written = <String, ExercisePrescription>{};
  for (final w in block.pass2.weeks) {
    if (w.weekIndex != session.weekIndex) {
      continue;
    }
    for (final d in w.days) {
      if (d.dayIndex == session.dayIndex) {
        for (final it in d.items) {
          written[it.slotId] = it;
        }
      }
    }
  }
  for (final item in session.items) {
    final where = '${session.date.iso} ${item.exerciseId}';
    final basis = written[item.slotId];
    if (basis != null && item.sets > basis.sets) {
      // Un bloc au temps (une ligne) dont la technique n'est pas servie
      // devient des séries classiques : le nombre de lignes ne se compare
      // pas.
      final blockKind = basis.technique?.kind;
      final timed =
          blockKind == SetTechniqueKind.density ||
          blockKind == SetTechniqueKind.forTime;
      // Séries fractionnées (plage hors de portée) : des lignes plus
      // courtes que le bas de la plage écrite, au plus le double des
      // séries (trois au moins permises), pour un total qui ne dépasse le
      // bas de la plage écrite que de moins d'une série.
      final targets = item.setTargets ?? const <SetTarget>[];
      final low = basis.repsLow;
      var split =
          low != null &&
          basis.kind != SetKind.test &&
          targets.length == item.sets &&
          item.sets <= (2 * basis.sets < 3 ? 3 : 2 * basis.sets);
      var total = 0;
      var each = 0;
      for (final t in targets) {
        final reps = t.repsHigh;
        if (reps == null || t.repsLow != reps || low == null || reps >= low) {
          split = false;
          break;
        }
        total += reps;
        each = reps;
      }
      if (split && low != null && total >= basis.sets * low + each) {
        split = false;
      }
      if ((!timed || item.technique != null) && !split) {
        final lines = <String>[
          for (final t in targets) '${t.repsLow}-${t.repsHigh}',
        ].join(' ');
        out.add(
          '$where : ${item.sets} séries pour ${basis.sets} écrites '
          '(lignes $lines ; bas de plage écrit $low ; écrit '
          '${basis.exerciseId} ${basis.repsLow}-${basis.repsHigh} '
          '${basis.technique?.kind.code} ${basis.setTargets?.length} ; servi '
          '${item.repsLow}-${item.repsHigh} ${item.technique?.kind.code} ; '
          '${[for (final r in item.reasons) r.code].join(',')})',
        );
      }
    }
    final kind = item.technique?.kind;
    if (kind != null && level < techniqueAccessLevel(kind)) {
      out.add('$where : technique ${kind.code} au niveau $level');
    }
    final targets = item.setTargets ?? const <SetTarget>[];
    double? previous;
    for (final t in targets) {
      final kg = t.loadKg;
      if (t.role == SetRole.attempt && kg != null) {
        if (previous != null && kg < previous - 0.011) {
          out.add('$where : tentatives décroissantes ($previous → $kg)');
        }
        previous = kg;
      }
    }
    final info = book.find(item.exerciseId);
    if (info == null ||
        info.mode != CapacityMode.loaded ||
        item.kind == SetKind.test ||
        roles[item.slotId] != SlotRole.main ||
        sessionsOfExercise(log, info) < p.calibrationSessions) {
      continue;
    }
    double? heaviest;
    for (final s in log.countedSessions) {
      for (final set in s.sets) {
        if (countsFor(info, set)) {
          final kg = set.externalLoadKg ?? 0;
          if (heaviest == null || kg > heaviest) {
            heaviest = kg;
          }
        }
      }
    }
    if (heaviest == null) {
      continue;
    }
    var top = item.startLoadKg ?? 0;
    for (final t in targets) {
      final kg = t.loadKg;
      if (kg != null && kg > top) {
        top = kg;
      }
    }
    final bw = info.fraction * bodyWeight;
    var bound = (heaviest + bw) * (1 + p.maxUpMain) - bw;
    final step = info.grid.next(heaviest, up: true);
    if (step > bound) {
      bound = step;
    }
    final start = basis?.startLoadKg;
    if (start != null && start > bound) {
      bound = start;
    }
    if (top > bound + 0.011) {
      out.add(
        '$where : $top kg au-delà de la charge écrite ($start) et de +10 % '
        'de la plus lourde charge du journal ($heaviest)',
      );
    }
  }
  return out;
}

/// Trace d'un conseil pour le diagnostic d'un manquement : prescription de
/// l'emplacement, lignes faites, raisons du conseil.
String _trace(
  SessionPlan session,
  List<SetRecord> done,
  IntraSessionAdvice advice,
) {
  final b = StringBuffer('[');
  for (final item in session.items) {
    if (item.slotId == advice.slotId) {
      b.write(
        'item ${item.kind?.code}/${item.test?.kind.code}/'
        '${item.technique?.kind.code} sets ${item.sets} ; ',
      );
    }
  }
  for (final s in done) {
    if (s.slotId == advice.slotId) {
      b.write(
        '${s.reps ?? s.seconds}@${s.externalLoadKg} f${s.flames} '
        '${s.success ? 'ok' : 'raté'} t${s.target?.flames}/'
        '${s.target?.repsHigh ?? s.target?.secondsHigh} ${s.role?.code} '
        '${s.technique?.code} ${s.kind.code} q${s.quality} ; ',
      );
    }
  }
  b.write(
    '→ ${advice.action.code} ${advice.reasons.map((r) => r.code).join(',')}]',
  );
  return b.toString();
}

/// Lignes brutes de la dernière séance du journal où l'exercice [info]
/// apparaît (diagnostic d'un manquement).
String _lastLines(TrainingLog log, ExerciseInfo info) {
  for (final session in log.sessions.reversed) {
    final lines = <String>[
      for (final s in session.sets)
        if (s.exerciseId == info.id)
          '${s.reps ?? s.seconds}@${s.externalLoadKg} f${s.flames} '
              '${s.success ? 'ok' : 'raté'} t${s.target?.flames}/'
              '${s.target?.repsHigh}/${s.target?.loadKg} ${s.role?.code} '
              '${s.technique?.code} ${s.kind.code} q${s.quality} '
              'p${s.parts?.map((p) => '${p.reps}@${p.externalLoadKg}').join('+')}'
              '${s.excluded ? ' exclu' : ''} ${s.slotId}',
    ];
    if (lines.isNotEmpty) {
      return '[${session.date.iso} ${session.resume ? 'reprise ' : ''}'
          '${session.programRef?.blockId}/${session.programRef?.weekIndex}/'
          '${session.programRef?.dayIndex} : ${lines.join(' ; ')}]';
    }
  }
  return '[]';
}

/// Invariants d'endurance (CA2, partie 1 ; `CONTRAT.md`, § 12) :
///
/// E1. une ligne de course, de cardio ou de conditionnement n'est jamais
///     servie plus longue, plus lointaine, avec plus de répétitions ou de
///     séries, ni plus dure (effort visé, allure visée) que l'écrit ;
/// E2. la course du jour (somme des lignes de course) ne dépasse pas de
///     plus de 10 % la plus longue course des 30 jours précédents, quand le
///     journal en compte au moins trois ;
/// E3. un jour de bilan bas, aucune séance de course de qualité (allure,
///     fractionné, effort visé à 3 répétitions en réserve ou moins) n'est
///     servie : aucune hausse d'allure après un mauvais jour.
List<String> checkEndurance(
  Catalog catalog,
  AthleteProfile profile,
  ProgramBlock block,
  TrainingLog journal,
  SessionPlan session,
  AdaptParams p, {
  HealthCheck? health,
}) {
  final out = <String>[];
  if (!p.enduranceConduct) {
    return out;
  }
  final book = ExerciseBook(catalog, profile);
  ExercisePrescription? writtenOf(String slotId) {
    for (final w in block.pass2.weeks) {
      if (w.weekIndex != session.weekIndex) {
        continue;
      }
      for (final d in w.days) {
        if (d.dayIndex != session.dayIndex) {
          continue;
        }
        for (final it in d.items) {
          if (it.slotId == slotId) {
            return it;
          }
        }
      }
    }
    return null;
  }

  final where = session.date.iso;
  final level = readHealth(health, p).level;
  for (final item in session.items) {
    final info = book.find(item.exerciseId);
    final kind = info == null ? null : enduranceKindOf(info);
    if (kind == null ||
        kind == EnduranceKind.mobility ||
        item.kind == SetKind.warmup) {
      continue;
    }
    final w = writtenOf(item.slotId);
    if (w != null) {
      final swapped = w.exerciseId != item.exerciseId;
      bool over(num? served, num? written) =>
          served != null && written != null && served > written + 1e-9;
      if (!swapped) {
        if (item.sets > w.sets ||
            over(item.secondsHigh, w.secondsHigh) ||
            over(item.distanceMeters, w.distanceMeters) ||
            over(item.repsHigh, w.repsHigh)) {
          out.add(
            '$where ${item.exerciseId} : E1, ligne servie au-dessus de '
            'l\'écrit',
          );
        }
      }
      if (over(item.targetFlames, w.targetFlames)) {
        out.add('$where ${item.exerciseId} : E1, effort visé plus dur');
      }
      final si = item.intensity;
      final wi = w.intensity;
      if (si != null) {
        // Base « réserve » : plus bas = plus dur ; autres bases (allure,
        // part) : plus haut = plus dur.
        final rirBasis = si.basis == IntensityBasis.rir;
        bool harder(double? a, double? b) =>
            a != null && b != null && (rirBasis ? a < b - 1e-9 : a > b + 1e-9);
        if (wi == null ||
            wi.basis != si.basis ||
            harder(si.value, wi.value) ||
            harder(si.valueHigh, wi.valueHigh ?? wi.value)) {
          out.add('$where ${item.exerciseId} : E1, allure visée plus rapide');
        }
      }
    }
    if (kind == EnduranceKind.run) {
      if (level >= 1 && isQualityRun(item, info!, p)) {
        out.add(
          '$where ${item.exerciseId} : E3, séance de qualité un jour de '
          'bilan bas',
        );
      }
    }
  }
  // E2 : plus longue course des 30 jours (même lecture de la vitesse).
  final today = session.date.dayNumber;
  var meters = 0.0;
  var timed = 0.0;
  for (final s in journal.countedSessions) {
    for (final set in s.sets) {
      final info = book.find(set.exerciseId);
      if (!set.isUsable ||
          info == null ||
          enduranceKindOf(info) != EnduranceKind.run) {
        continue;
      }
      final m = set.distanceMeters;
      final t = set.seconds;
      if (m != null && t != null && m > 0 && t > 0) {
        meters += m;
        timed += t;
      }
    }
  }
  final speed = timed > 0 ? meters / timed : p.enduranceRunSpeed;
  var longest = 0.0;
  var count = 0;
  for (final s in journal.countedSessions) {
    final d = s.date.dayNumber;
    if (d >= today || d < today - p.enduranceSpikeDays) {
      continue;
    }
    var seconds = 0.0;
    for (final set in s.sets) {
      if (set.kind == SetKind.warmup || !set.isUsable) {
        continue;
      }
      final info = book.find(set.exerciseId);
      if (info == null || enduranceKindOf(info) != EnduranceKind.run) {
        continue;
      }
      final m = set.distanceMeters;
      seconds += set.seconds?.toDouble() ?? (m == null ? 0.0 : m / speed);
    }
    if (seconds > 0) {
      count++;
      if (seconds > longest) {
        longest = seconds;
      }
    }
  }
  if (count >= p.enduranceSpikeMinRuns && longest > 0) {
    var served = 0.0;
    for (final item in session.items) {
      final info = book.find(item.exerciseId);
      if (info != null &&
          enduranceKindOf(info) == EnduranceKind.run &&
          item.kind != SetKind.warmup) {
        served += _runSeconds(item, speed);
      }
    }
    // (Tolérance de 2 % : la vitesse qui convertit une distance en durée
    // est lue sur tout le journal ici, sur les séances rejouées par le
    // moteur.)
    if (served > longest * (1 + p.enduranceSpike) * 1.02 + 1) {
      out.add(
        '$where : E2, course de ${served.round()} s pour une plus longue '
        'de ${longest.round()} s sur 30 jours',
      );
    }
  }
  return out;
}

double _runSeconds(ExercisePrescription item, double speed) =>
    prescribedSeconds(item, item.sets, speed);
