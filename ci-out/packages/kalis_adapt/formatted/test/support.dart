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
final class CheckedPolicy implements SimPolicy {
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
  bool get rangeIsTarget => inner.rangeIsTarget;

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

/// Invariants de sécurité d'une séance prescrite, lus dans le journal seul
/// (sans l'état du moteur) :
///
/// 1. mouvement principal hors calibrage : charge totale ≤ +10 % de la plus
///    forte charge de la dernière séance de l'exercice — ou un seul cran de
///    la grille quand le plus petit cran dépasse 10 % ;
/// 2. aucune hausse après une série à l'échec non prévue ;
/// 3. aucune hausse sur un exercice d'une zone signalée douloureuse
///    au-dessus du seuil depuis sa dernière séance ;
/// 4. charges sur la grille du matériel.
List<String> checkSession(
  Catalog catalog,
  AthleteProfile profile,
  ProgramBlock block,
  TrainingLog log,
  SessionPlan session,
  AdaptParams p, {
  HealthCheck? health,
}) {
  final out = <String>[];
  final book = ExerciseBook(catalog, profile);
  final bodyWeight = profile.bodyWeightKg ?? p.referenceBodyWeightKg;
  final roles = <String, SlotRole>{
    for (final d in block.pass1.days)
      for (final s in d.slots) s.slotId: s.role,
  };
  for (final item in session.items) {
    final info = book.find(item.exerciseId);
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
    if (roles[item.slotId] == SlotRole.main &&
        !item.toCalibrate &&
        !test &&
        rise > p.maxUpMain + 1e-6 &&
        top > oneStep + 0.011) {
      out.add(
        '$where : +${(rise * 100).toStringAsFixed(1)} % sur un mouvement '
        'principal ($reference → $top kg)',
      );
    }
    if (top > reference + 0.011 && lastHadUnplannedFailure(log, info)) {
      out.add('$where : hausse après un échec non prévu ($reference → $top)');
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
/// l'échec non prévue dans la séance ; charge sur la grille. Une série sans
/// cible enregistrée est jugée d'après la cible de la séance [session],
/// comme le fait le moteur.
List<String> checkAdvice(
  Catalog catalog,
  AthleteProfile profile,
  SessionPlan session,
  List<SetRecord> done,
  IntraSessionAdvice advice,
  AdaptParams p,
) {
  final out = <String>[];
  final info = ExerciseBook(catalog, profile).find(advice.exerciseId);
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
      'conseil ${advice.exerciseId} : hausse après un échec ($last → $next)',
    );
  }
  if (advice.action == IntraSessionAction.loadUp && failed) {
    out.add('conseil ${advice.exerciseId} : load_up après un échec');
  }
  return out;
}
