/// Critères du lot KS1 « Structure de la semaine » (`pipeline/cp/
/// CAHIER_KS.md`, § 9), mesurés sur un programme créé : couverture des
/// objectifs, récupération, temps par séance, séance sans principal, ordre
/// par exigence, identité du squelette des profils mono-discipline,
/// contrôles du profil de test. Validation automatique, sans panel (comme
/// C13.3). Le module ne lit que le contrat de `kalis_core` (et l'estimation
/// de durée de l'audit de `kalis_plan`) : il mesure aussi bien `kalis_plan`
/// 0.3.1 (mesure avant) que 0.4.0.
library;

import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show coachSessionSeconds;

import 'analysis.dart';
import 'profile.dart';
import 'program.dart';
import 'safety.dart';

/// Gabarits des chemins d'avant 0.4.0 (profils mono-discipline).
const Set<String> structureLegacyTemplates = <String>{
  'lift_dup',
  'reps_pillars',
  'figures',
  'fb_beginner',
  'gym_split',
  'power_dup',
  'run_week',
  'wod_week',
  'health_week',
};

/// Seuil de la récupération par bloc (CAHIER_KS.md § 9).
const double structureRecoveryFloor = 0.9;

/// Bande du temps par séance, en part du temps disponible (± 15 %).
const (double, double) structureTimeBand = (0.85, 1.15);

/// Clé du profil de test (CAHIER_KS.md § 7.1).
const String structureTestProfile = 'ks_test_ppl6';

/// Exigence d'un mouvement de compétition (CAHIER_KS.md § 11.2 : muscle-up
/// lesté, traction lestée, dips lesté, squat ; 0 hors des quatre).
int structureDemand(String id) => switch (id) {
  'sl-muscle-up-leste' => 4,
  'sl-traction-lestee' => 3,
  'sl-dips-leste' => 2,
  'sl-squat-competition' => 1,
  _ => 0,
};

/// Schéma chargé d'un exercice : `pull`, `push`, `legs`, ou `null`.
String? structureSchemaOf(CatalogExercise e) => switch (e.pattern) {
  MovementPattern.tirageVertical ||
  MovementPattern.tirageHorizontal ||
  MovementPattern.transitionMuscleUp ||
  MovementPattern.figureStatiqueTirage ||
  MovementPattern.figureDynamiqueTirage ||
  MovementPattern.isolationBiceps ||
  MovementPattern.isolationDos => 'pull',
  MovementPattern.pousseeHorizontale ||
  MovementPattern.pousseeInclinee ||
  MovementPattern.pousseeVerticaleBasse ||
  MovementPattern.pousseeVerticaleHaute ||
  MovementPattern.figureStatiquePoussee ||
  MovementPattern.figureDynamiquePoussee ||
  MovementPattern.equilibreMains ||
  MovementPattern.isolationTriceps ||
  MovementPattern.isolationPectoraux ||
  MovementPattern.isolationEpaules => 'push',
  MovementPattern.squat ||
  MovementPattern.fente ||
  MovementPattern.charniereHanche ||
  MovementPattern.extensionHanche ||
  MovementPattern.flexionGenou ||
  MovementPattern.extensionGenou ||
  MovementPattern.mollets ||
  MovementPattern.adducteursAbducteurs => 'legs',
  _ => null,
};

/// Charge d'un emplacement de passe 1 sur son schéma : 2 lourd, 1 moyen, 0
/// léger (raison `plan.undulation`) ; sans charge écrite, le rôle décide
/// (principal 2, secondaire 1, le reste 0 — les figures et la pratique
/// technique ne portent pas de charge écrite et sont dosées loin de
/// l'échec).
int structureSlotLoad(PlanSlot s) {
  for (final r in s.reasons) {
    if (r.code == ReasonCodes.planUndulation) {
      return switch (r.params['stress']) {
        'heavy' => 2,
        'medium' => 1,
        _ => 0,
      };
    }
  }
  return switch (s.role) {
    SlotRole.main => 2,
    SlotRole.secondary => 1,
    _ => 0,
  };
}

int _gap(int from, int to) {
  var g = to - from;
  if (g <= 0) {
    g += 7;
  }
  return g;
}

/// Récupération d'une passe 1, recalculée par le banc (même définition que
/// la composante recalée de `kalis_plan` 0.4.0, lue sur le contrat) : la
/// note et le nombre de paires de jours consécutifs qui chargent
/// lourdement le même schéma.
(double, int) structureRecoveryOf(Catalog catalog, Pass1Plan plan) {
  final loads = <Map<String, int>>[];
  var total = 0;
  for (final d in plan.days) {
    final m = <String, int>{};
    for (final s in d.slots) {
      final e = catalog.find(s.exerciseId);
      final schema = e == null ? null : structureSchemaOf(e);
      final load = structureSlotLoad(s);
      if (schema == null || load == 0) {
        continue;
      }
      m[schema] = (m[schema] ?? 0) + load;
      total += load;
    }
    loads.add(m);
  }
  if (total == 0 || plan.days.length < 2) {
    return (1.0, 0);
  }
  var overlap = 0;
  var pairs = 0;
  for (var i = 0; i < plan.days.length; i++) {
    for (var j = i + 1; j < plan.days.length; j++) {
      final g = _gap(plan.days[i].weekday, plan.days[j].weekday);
      if (g != 1 && g != 6) {
        continue;
      }
      var bad = false;
      for (final schema in loads[i].keys) {
        final u = loads[i][schema]!;
        final v = loads[j][schema] ?? 0;
        if (u >= 2 && v >= 2) {
          overlap += u < v ? u : v;
          bad = true;
        }
      }
      if (bad) {
        pairs++;
      }
    }
  }
  final value = 1 - 2 * overlap / total;
  return (value < 0 ? 0.0 : value, pairs);
}

/// Signature du squelette d'une passe 1 (jour, thème, emplacements :
/// identifiant, exercice, rôle) : ce que le contrôle d'identité compare.
List<Object?> structureSignatureOf(Pass1Plan plan) => <Object?>[
  for (final d in plan.days)
    <String, Object?>{
      'weekday': d.weekday,
      'focus': d.focus,
      'slots': <String>[
        for (final s in d.slots) '${s.slotId}|${s.exerciseId}|${s.role.code}',
      ],
    },
];

/// Gabarit d'une passe 1 (`Pass1Plan.split`, 0.4.4), ou `null`.
String? structureTemplateOf(Pass1Plan plan) => plan.split?.templateId;

/// Mesures du lot KS1 d'un profil.
final class StructureMeasure {
  /// Mesures.
  StructureMeasure({
    required this.key,
    required this.group,
    required this.sessions,
    required this.templates,
    required this.safety,
    required this.goals,
    required this.uncovered,
    required this.loadedWeeks,
    required this.recoveryScore,
    required this.recoveryBench,
    required this.recoveryPairs,
    required this.daysCounted,
    required this.timeOff,
    required this.timeLow,
    required this.timeHigh,
    required this.noMain,
    required this.orderSessions,
    required this.orderOff,
    required this.rotationChecked,
    required this.rotationOff,
    required this.signature,
    this.testChecks = const <String, bool>{},
  });

  /// Profil.
  final String key;

  /// `street` ou `autres`.
  final String group;

  /// Séances par semaine.
  final int sessions;

  /// Gabarit de chaque bloc (`?` avant 0.4.0).
  final List<String> templates;

  /// Violations de sécurité du programme créé.
  final int safety;

  /// Objectifs de performance.
  final int goals;

  /// Couples (objectif, semaine de charge) sans porteur : `objectif@semaine`.
  final List<String> uncovered;

  /// Semaines de charge mesurées.
  final int loadedWeeks;

  /// Composante `recovery` de la note de chaque bloc.
  final List<double> recoveryScore;

  /// Récupération recalculée par le banc, par bloc.
  final List<double> recoveryBench;

  /// Paires de jours consécutifs en défaut, par bloc.
  final List<int> recoveryPairs;

  /// Séances mesurées (semaines de charge).
  final int daysCounted;

  /// Séances hors de ± 15 % du temps disponible.
  final int timeOff;

  /// Plus petite part du temps disponible.
  final double timeLow;

  /// Plus grande part du temps disponible.
  final double timeHigh;

  /// Séances (bloc, jour) sans emplacement principal (ni figure).
  final List<String> noMain;

  /// Séances qui portent un mouvement de compétition lesté.
  final int orderSessions;

  /// Séances dont le premier mouvement de compétition n'est pas le plus
  /// exigeant de la séance : `bloc/jour`.
  final List<String> orderOff;

  /// Blocs où la rotation est contrôlée.
  final int rotationChecked;

  /// Blocs où le jour du mouvement le plus exigeant n'ouvre pas la
  /// rotation : `bloc`.
  final List<String> rotationOff;

  /// Signature du squelette de chaque bloc.
  final List<Object?> signature;

  /// Contrôles du profil de test (CAHIER_KS.md § 7).
  final Map<String, bool> testChecks;

  /// Plus petite récupération (composante de la note) des blocs.
  double get recoveryMin =>
      recoveryScore.isEmpty ? 1 : recoveryScore.reduce((x, y) => x < y ? x : y);

  /// Vrai si le profil garde un gabarit d'avant 0.4.0.
  bool get mono =>
      templates.every((t) => t == '?' || structureLegacyTemplates.contains(t));

  /// Objet JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'key': key,
    'group': group,
    'sessions': sessions,
    'templates': templates,
    'safety': safety,
    'goals': goals,
    'uncovered': uncovered,
    'loadedWeeks': loadedWeeks,
    'recoveryScore': <double>[for (final v in recoveryScore) _r(v)],
    'recoveryBench': <double>[for (final v in recoveryBench) _r(v)],
    'recoveryPairs': recoveryPairs,
    'daysCounted': daysCounted,
    'timeOff': timeOff,
    'timeLow': _r(timeLow),
    'timeHigh': _r(timeHigh),
    'noMain': noMain,
    'orderSessions': orderSessions,
    'orderOff': orderOff,
    'rotationChecked': rotationChecked,
    'rotationOff': rotationOff,
    'signature': signature,
    if (testChecks.isNotEmpty) 'testChecks': testChecks,
  };
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

/// Vrai pour une séance de course ou de récupération (pas de principal
/// attendu).
bool _restful(Catalog catalog, PlanDay d) {
  final type = d.toJson()['type'];
  if (type is Map<String, Object?>) {
    final quality = type['quality'];
    if (quality == 'run' || quality == 'recovery') {
      return true;
    }
  }
  for (final s in d.slots) {
    if (s.role == SlotRole.warmup ||
        s.role == SlotRole.mobility ||
        s.role == SlotRole.conditioning) {
      continue;
    }
    final kind = catalog.find(s.exerciseId)?.pattern;
    if (kind != MovementPattern.cardioContinu &&
        kind != MovementPattern.cardioFractionne &&
        kind != MovementPattern.marche) {
      return false;
    }
  }
  return true;
}

/// Mesures du lot KS1 du programme [program] du profil [bench].
StructureMeasure structureMeasureOf(
  Catalog catalog,
  BenchProgram program,
  BenchProfile bench,
) {
  final view = ProgramView(catalog, program);
  final goals = <Goal>[
    for (final g in program.profile.goals)
      if (g.kind == GoalKind.performance && g.exerciseId != null) g,
  ];
  // Couverture : chaque objectif, chaque semaine de charge (ni
  // introduction, ni allègement, ni test).
  final slotsOf = <int, Map<String, PlanSlot>>{
    for (var i = 0; i < program.blocks.length; i++)
      i: <String, PlanSlot>{
        for (final d in program.blocks[i].pass1.days)
          for (final s in d.slots) s.slotId: s,
      },
  };
  final uncovered = <String>[];
  var loadedWeeks = 0;
  var daysCounted = 0;
  var timeOff = 0;
  var low = 99.0;
  var high = 0.0;
  for (final w in view.weeks) {
    if (w.isLight) {
      continue;
    }
    loadedWeeks++;
    for (final g in goals) {
      var ok = false;
      for (final i in w.items) {
        if (i.p.sets <= 0 || i.isWarmup) {
          continue;
        }
        if (i.exercise.id == g.exerciseId) {
          ok = true;
          break;
        }
        final slot = slotsOf[w.blockIndex]?[i.p.slotId];
        if (slot != null &&
            slot.reasons.any(
              (r) =>
                  r.code == ReasonCodes.planGoalSupport &&
                  r.params['goalId'] == g.id,
            )) {
          ok = true;
          break;
        }
      }
      if (!ok) {
        uncovered.add('${g.id}@${w.index}');
      }
    }
    for (final d in w.days) {
      if (d.minutesBudget <= 0) {
        continue;
      }
      final seconds = coachSessionSeconds(
        catalog,
        DayPrescription(
          dayIndex: d.dayIndex,
          items: <ExercisePrescription>[for (final i in d.items) i.p],
        ),
        minutes: d.minutesBudget,
      );
      final ratio = seconds / (d.minutesBudget * 60);
      daysCounted++;
      if (ratio < structureTimeBand.$1 || ratio > structureTimeBand.$2) {
        timeOff++;
      }
      if (ratio < low) {
        low = ratio;
      }
      if (ratio > high) {
        high = ratio;
      }
    }
  }
  final recoveryScore = <double>[];
  final recoveryBench = <double>[];
  final recoveryPairs = <int>[];
  final noMain = <String>[];
  final orderOff = <String>[];
  final rotationOff = <String>[];
  var orderSessions = 0;
  var rotationChecked = 0;
  for (var b = 0; b < program.blocks.length; b++) {
    final plan = program.blocks[b].pass1;
    for (final c in plan.score.components) {
      if (c.code == 'recovery') {
        recoveryScore.add(c.value);
      }
    }
    final (value, pairs) = structureRecoveryOf(catalog, plan);
    recoveryBench.add(value);
    recoveryPairs.add(pairs);
    for (final d in plan.days) {
      if (_restful(catalog, d)) {
        continue;
      }
      if (!d.slots.any(
        (s) => s.role == SlotRole.main || s.role == SlotRole.skill,
      )) {
        noMain.add('$b/${d.dayIndex}');
      }
      var first = -1;
      var most = 0;
      for (final s in d.slots) {
        final v = structureDemand(s.exerciseId);
        if (v <= 0) {
          continue;
        }
        if (first < 0) {
          first = v;
        }
        if (v > most) {
          most = v;
        }
      }
      if (first > 0) {
        orderSessions++;
        if (first < most) {
          orderOff.add('$b/${d.dayIndex}');
        }
      }
    }
    // Rotation : le jour qui suit le plus long repos porte le mouvement le
    // plus exigeant de la semaine (le plus exigeant, puis le plus chargé).
    final n = plan.days.length;
    var opener = -1;
    var longest = -1;
    for (var i = 0; i < n; i++) {
      final before = n == 1
          ? 7
          : _gap(plan.days[(i - 1 + n) % n].weekday, plan.days[i].weekday);
      if (before > longest) {
        longest = before;
        opener = i;
      }
    }
    var best = 0;
    final scores = <int>[];
    for (final d in plan.days) {
      var top = 0;
      for (final s in d.slots) {
        final v = structureDemand(s.exerciseId) * 10 + structureSlotLoad(s);
        if (structureDemand(s.exerciseId) > 0 && v > top) {
          top = v;
        }
      }
      scores.add(top);
      if (top > best) {
        best = top;
      }
    }
    if (best > 0 && opener >= 0) {
      rotationChecked++;
      if (scores[opener] < best) {
        rotationOff.add('$b');
      }
    }
  }
  final checks = <String, bool>{};
  if (bench.key == structureTestProfile &&
      program.blocks.isNotEmpty &&
      program.blocks.first.pass1.days.isNotEmpty) {
    final plan = program.blocks.first.pass1;
    checks['gabarit ppl6_q à chaque bloc'] = program.blocks.every(
      (b) => structureTemplateOf(b.pass1) == 'ppl6_q',
    );
    final monday = plan.days.first;
    String? lead;
    for (final s in monday.slots) {
      if (s.role != SlotRole.warmup) {
        lead = s.exerciseId;
        break;
      }
    }
    checks['muscle-up lesté en tête du premier jour, qui ouvre la rotation'] =
        lead == 'sl-muscle-up-leste' && rotationOff.isEmpty;
    checks['neuf objectifs et quatre cibles de l\'échéance portés chaque '
            'semaine de charge'] =
        goals.length == 13 && uncovered.isEmpty;
    var schemas = true;
    for (final b in program.blocks) {
      for (final schema in const <String>['pull', 'push', 'legs']) {
        final days = <int>[];
        for (final d in b.pass1.days) {
          var load = 0;
          // (Travail porteur seulement : principal et secondaire ; la
          // pratique technique, la puissance légère et les compléments ne
          // font pas un jour du schéma.)
          for (final s in d.slots) {
            final e = catalog.find(s.exerciseId);
            if (e != null &&
                structureSchemaOf(e) == schema &&
                (s.role == SlotRole.main || s.role == SlotRole.secondary)) {
              load++;
            }
          }
          if (load >= 1) {
            days.add(d.weekday);
          }
        }
        if (days.length < 2) {
          schemas = false;
          continue;
        }
        for (var i = 0; i < days.length; i++) {
          final g = _gap(days[i], days[(i + 1) % days.length]);
          if (g < 3) {
            schemas = false;
          }
        }
      }
    }
    checks['chaque schéma deux fois par semaine, à 72 h'] = schemas;
    checks['aucun schéma lourd deux jours de suite'] = recoveryPairs.every(
      (p) => p == 0,
    );
    checks['séances de 100 à 125 min (semaines de charge)'] =
        daysCounted > 0 && low * 120 >= 100 - 1e-9 && high * 120 <= 125 + 1e-9;
    checks['aucune séance sans principal'] = noMain.isEmpty;
    // (La première passe 1 suffit à lire le jour de tête.)
    final firstType = plan.days.first.type;
    checks['premier jour : tirage, force'] =
        firstType != null &&
        firstType.quality == DayQuality.force &&
        firstType.patterns.contains(DayPattern.pull);
  }
  return StructureMeasure(
    key: bench.key,
    group: bench.group,
    sessions: program.profile.availability.length,
    templates: <String>[
      for (final b in program.blocks) structureTemplateOf(b.pass1) ?? '?',
    ],
    safety: safetyFindings(view, bench).length,
    goals: goals.length,
    uncovered: uncovered,
    loadedWeeks: loadedWeeks,
    recoveryScore: recoveryScore,
    recoveryBench: recoveryBench,
    recoveryPairs: recoveryPairs,
    daysCounted: daysCounted,
    timeOff: timeOff,
    timeLow: daysCounted == 0 ? 0 : low,
    timeHigh: high,
    noMain: noMain,
    orderSessions: orderSessions,
    orderOff: orderOff,
    rotationChecked: rotationChecked,
    rotationOff: rotationOff,
    signature: <Object?>[
      for (final b in program.blocks) structureSignatureOf(b.pass1),
    ],
    testChecks: checks,
  );
}

String _pct(double v) =>
    '${(v * 100).toStringAsFixed(1).replaceAll('.', ',')} %';

String _num(double v) => v.toStringAsFixed(3).replaceAll('.', ',');

/// Rapport du lot KS1 : `structure.json` (mesures par profil, avant et
/// après, différences de squelette) et `STRUCTURE.md` (tableau des critères
/// du § 9, puis le détail par profil). [before] : mesures de `kalis_plan`
/// 0.3.1 (`docs/data/ks1/mesure_0_3_1.json`, profils → mesure) ;
/// [reference] : signatures des squelettes de 0.3.1 (profils → blocs).
Map<String, String> structureReport(
  List<StructureMeasure> measures, {
  required int seasonViolations,
  Map<String, Object?> before = const <String, Object?>{},
  Map<String, Object?> reference = const <String, Object?>{},
}) {
  final identity = <String, List<String>>{};
  for (final m in measures) {
    if (!m.mono) {
      continue;
    }
    final ref = reference[m.key];
    if (ref == null) {
      identity[m.key] = <String>['pas de squelette de référence'];
      continue;
    }
    final blocks = ref as List<Object?>;
    final out = <String>[];
    for (var b = 0; b < m.signature.length || b < blocks.length; b++) {
      if (b >= m.signature.length || b >= blocks.length) {
        out.add('bloc $b : présent d\'un seul côté');
        continue;
      }
      final x = m.signature[b] as List<Object?>;
      final y = blocks[b] as List<Object?>;
      if (x.length != y.length) {
        out.add('bloc $b : ${x.length} jours pour ${y.length}');
        continue;
      }
      for (var d = 0; d < x.length; d++) {
        final dx = x[d] as Map<String, Object?>;
        final dy = y[d] as Map<String, Object?>;
        if (dx['weekday'] != dy['weekday'] || dx['focus'] != dy['focus']) {
          out.add('bloc $b, jour $d : jour ou thème');
        }
        final sx = (dx['slots'] as List<Object?>).cast<String>();
        final sy = (dy['slots'] as List<Object?>).cast<String>();
        if (sx.join(';') != sy.join(';')) {
          final gone = <String>[
            for (final s in sy)
              if (!sx.contains(s)) s,
          ];
          final added = <String>[
            for (final s in sx)
              if (!sy.contains(s)) s,
          ];
          out.add(
            'bloc $b, jour $d : '
            '${gone.isEmpty ? '' : 'retirés ${gone.join(', ')}'}'
            '${gone.isNotEmpty && added.isNotEmpty ? ' ; ' : ''}'
            '${added.isEmpty ? '' : 'ajoutés ${added.join(', ')}'}'
            '${gone.isEmpty && added.isEmpty ? 'ordre' : ''}',
          );
        }
      }
    }
    identity[m.key] = out;
  }
  var safety = 0;
  var goalPairs = 0;
  var uncovered = 0;
  final recoveryLow = <String>[];
  var timeDays = 0;
  var timeOff = 0;
  final noMain = <String>[];
  var orderSessions = 0;
  final orderOff = <String>[];
  var rotation = 0;
  final rotationOff = <String>[];
  for (final m in measures) {
    safety += m.safety;
    goalPairs += m.goals * m.loadedWeeks;
    uncovered += m.uncovered.length;
    if (m.sessions >= 4) {
      for (var b = 0; b < m.recoveryScore.length; b++) {
        if (m.recoveryScore[b] < structureRecoveryFloor - 1e-9) {
          recoveryLow.add(
            '`${m.key}` bloc $b (${_num(m.recoveryScore[b])}'
            '${m.mono ? ', gabarit inchangé' : ''})',
          );
        }
      }
    }
    timeDays += m.daysCounted;
    timeOff += m.timeOff;
    for (final d in m.noMain) {
      noMain.add('`${m.key}` $d${m.mono ? ' (gabarit inchangé)' : ''}');
    }
    orderSessions += m.orderSessions;
    for (final d in m.orderOff) {
      orderOff.add('`${m.key}` $d');
    }
    rotation += m.rotationChecked;
    for (final b in m.rotationOff) {
      rotationOff.add(
        '`${m.key}` bloc $b${m.mono ? ' (gabarit inchangé)' : ''}',
      );
    }
  }
  final changed = <String>[
    for (final e in identity.entries)
      if (e.value.isNotEmpty) e.key,
  ];
  StructureMeasure? test;
  for (final m in measures) {
    if (m.key == structureTestProfile) {
      test = m;
    }
  }
  String held(bool ok) => ok ? 'oui' : '**non**';
  final b = StringBuffer()
    ..writeln('# Structure de la semaine — critères du lot KS1')
    ..writeln()
    ..writeln(
      'Mesures automatiques (`pipeline/cp/CAHIER_KS.md`, § 9) sur les '
      '${measures.length} profils (banc et profils ajoutés `profiles_ks`), '
      'graine 0, horizon du profil (le profil de test sur 40 semaines). '
      'Couverture, temps et principal : semaines de charge (ni '
      'introduction, ni allègement, ni test) ; temps estimé par '
      '`coachSessionSeconds` de `kalis_plan` ; récupération : composante '
      '`recovery` de la note de chaque bloc, profils à 4 séances et plus.',
    )
    ..writeln()
    ..writeln('| Critère | Seuil | Mesuré | Tenu |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| Violations de sécurité (programmes créés) | 0 | $safety | '
      '${held(safety == 0)} |',
    )
    ..writeln(
      '| Violations de sécurité (saisons des profils ajoutés, modèle B, '
      'graine 0, scénarios) | 0 | $seasonViolations | '
      '${held(seasonViolations == 0)} |',
    )
    ..writeln(
      '| Couverture des objectifs (semaines de charge) | 100 % | '
      '${goalPairs == 0 ? '—' : _pct((goalPairs - uncovered) / goalPairs)} '
      '($uncovered couple(s) sans porteur) | ${held(uncovered == 0)} |',
    )
    ..writeln(
      '| Récupération ≥ 0,9 par bloc (4 séances et plus) | 0 bloc sous le '
      'seuil | ${recoveryLow.length} | ${held(recoveryLow.isEmpty)} |',
    )
    ..writeln(
      '| Temps par séance ± 15 % | 0 séance hors bande | $timeOff sur '
      '$timeDays | ${held(timeOff == 0)} |',
    )
    ..writeln(
      '| Séance sans principal | 0 | ${noMain.length} | '
      '${held(noMain.isEmpty)} |',
    )
    ..writeln(
      '| Squelette des profils mono-discipline identique à 0.3.1 | tous, '
      'sauf écart justifié | ${identity.length - changed.length} sur '
      '${identity.length} | ${held(changed.isEmpty)} |',
    )
    ..writeln(
      '| Ordre par exigence : mouvement le plus exigeant en tête de séance '
      '| 0 séance | ${orderOff.length} sur $orderSessions | '
      '${held(orderOff.isEmpty)} |',
    )
    ..writeln(
      '| Ordre par exigence : son jour en tête de la rotation | 0 bloc | '
      '${rotationOff.length} sur $rotation | ${held(rotationOff.isEmpty)} |',
    );
  if (test != null) {
    for (final e in test.testChecks.entries) {
      b.writeln(
        '| Profil de test : ${e.key} | oui | ${e.value ? 'oui' : 'non'} | '
        '${held(e.value)} |',
      );
    }
  }
  void list(String title, List<String> items) {
    if (items.isEmpty) {
      return;
    }
    b
      ..writeln()
      ..writeln('## $title')
      ..writeln();
    for (final i in items) {
      b.writeln('- $i');
    }
  }

  list('Blocs sous le seuil de récupération', recoveryLow);
  list('Séances sans principal', noMain);
  list('Séances où le plus exigeant ne vient pas en tête', orderOff);
  list(
    'Blocs où le jour le plus exigeant n\'ouvre pas la rotation',
    rotationOff,
  );
  list('Squelettes mono-discipline différents de 0.3.1', <String>[
    for (final k in changed) '`$k` : ${identity[k]!.join(' ; ')}',
  ]);
  b
    ..writeln()
    ..writeln('## Par profil')
    ..writeln()
    ..writeln(
      '| Profil | Séances | Gabarit | Sécurité | Objectifs sans porteur | '
      'Récupération (min) | Temps hors bande | Sans principal | Avant '
      '(0.3.1) : récupération, sans porteur, temps hors bande |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final m in measures) {
    final old = before[m.key];
    var was = '—';
    if (old is Map<String, Object?>) {
      final rec = (old['recoveryScore'] as List<Object?>? ?? const <Object?>[])
          .whereType<num>();
      final low = rec.isEmpty
          ? 1.0
          : rec.map((v) => v.toDouble()).reduce((x, y) => x < y ? x : y);
      final unc =
          (old['uncovered'] as List<Object?>? ?? const <Object?>[]).length;
      was =
          '${_num(low)} (0.1) ; $unc ; ${old['timeOff']} sur '
          '${old['daysCounted']}';
    }
    b.writeln(
      '| `${m.key}` | ${m.sessions} | ${m.templates.toSet().join(', ')} | '
      '${m.safety} | ${m.uncovered.length} | ${_num(m.recoveryMin)} | '
      '${m.timeOff} sur ${m.daysCounted} '
      '(${_pct(m.timeLow)} à ${_pct(m.timeHigh)}) | ${m.noMain.length} | '
      '$was |',
    );
  }
  return <String, String>{
    'STRUCTURE.md': b.toString(),
    'structure.json':
        '${jsonEncode(<String, Object?>{
          'measures': <Object?>[for (final m in measures) m.toJson()],
          'identity': identity,
          'seasonViolations': seasonViolations,
        })}\n',
  };
}
