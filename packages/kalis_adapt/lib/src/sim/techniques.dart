/// Programmes de test : un bloc de `kalis_plan` dont les prescriptions
/// reçoivent tour à tour chacune des techniques du contrat 0.4.0, pour
/// vérifier que le moteur d'évolution sait toutes les exécuter et les
/// journaliser (`kalis_plan` 0.2.0 n'en écrit qu'une partie).
library;

import 'package:kalis_core/kalis_core.dart';

/// Techniques injectées par [injectTechniques], dans l'ordre.
const List<SetTechniqueKind> injectedTechniques = <SetTechniqueKind>[
  SetTechniqueKind.cluster,
  SetTechniqueKind.restPause,
  SetTechniqueKind.myoReps,
  SetTechniqueKind.dropSet,
  SetTechniqueKind.accentuatedEccentric,
  SetTechniqueKind.wave,
  SetTechniqueKind.amrap,
  SetTechniqueKind.emom,
  SetTechniqueKind.density,
  SetTechniqueKind.ladder,
  SetTechniqueKind.pyramid,
  SetTechniqueKind.forTime,
  SetTechniqueKind.topSetBackoff,
];

bool _needsLoad(SetTechniqueKind kind) =>
    kind == SetTechniqueKind.dropSet ||
    kind == SetTechniqueKind.wave ||
    kind == SetTechniqueKind.topSetBackoff;

ExercisePrescription _withTechnique(
  ExercisePrescription it,
  SetTechniqueKind kind,
) {
  final low = it.repsLow!;
  final high = it.repsHigh!;
  switch (kind) {
    case SetTechniqueKind.cluster:
      final each = high ~/ 3 < 1 ? 1 : high ~/ 3;
      return it.copyWith(
        repsLow: 3 * each,
        repsHigh: 3 * each,
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          miniSets: 3,
          miniSetReps: each,
          intraRestSeconds: 20,
        ),
      );
    case SetTechniqueKind.restPause:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(kind: kind, intraRestSeconds: 20, miniSets: 2),
      );
    case SetTechniqueKind.myoReps:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          miniSetReps: 3,
          intraRestSeconds: 15,
          miniSets: 4,
        ),
      );
    case SetTechniqueKind.dropSet:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          drops: 2,
          dropPct: 0.2,
          lastSetOnly: true,
        ),
      );
    case SetTechniqueKind.accentuatedEccentric:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(kind: kind, eccentricOnly: true),
      );
    case SetTechniqueKind.wave:
      return it.copyWith(
        sets: 6,
        repsLow: 1,
        repsHigh: 3,
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          waves: 2,
          waveReps: const <int>[3, 2, 1],
          waveStepPct: 0.025,
        ),
      );
    case SetTechniqueKind.amrap:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(kind: kind, lastSetOnly: true),
      );
    case SetTechniqueKind.emom:
      return it.copyWith(
        repsLow: low,
        repsHigh: low,
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          intervalSeconds: 60,
          intervals: it.sets,
        ),
      );
    case SetTechniqueKind.density:
      return it.copyWith(
        sets: 1,
        repsLow: it.sets * high,
        repsHigh: it.sets * high,
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          durationSeconds: 300,
          totalRepsTarget: it.sets * high,
        ),
      );
    case SetTechniqueKind.ladder:
      return it.copyWith(
        sets: 3,
        repsLow: 1,
        repsHigh: 3,
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          ladderStart: 1,
          ladderStep: 1,
          ladderTop: 3,
        ),
      );
    case SetTechniqueKind.pyramid:
      final reps = <int>[
        high,
        high - 2 < 1 ? 1 : high - 2,
        high - 4 < 1 ? 1 : high - 4,
      ];
      return it.copyWith(
        sets: 3,
        repsLow: reps.last,
        repsHigh: reps.first,
        setTargets: null,
        technique: SetTechnique(kind: kind, pyramidReps: reps),
      );
    case SetTechniqueKind.forTime:
      return it.copyWith(
        sets: 1,
        repsLow: it.sets * high,
        repsHigh: it.sets * high,
        setTargets: null,
        technique: SetTechnique(kind: kind, totalRepsTarget: it.sets * high),
      );
    case SetTechniqueKind.topSetBackoff:
      return it.copyWith(
        setTargets: null,
        technique: SetTechnique(
          kind: kind,
          backoffSets: it.sets - 1,
          backoffDropPct: 0.1,
        ),
      );
    case SetTechniqueKind.standard:
    case SetTechniqueKind.isometricHold:
    case SetTechniqueKind.contrast:
    case SetTechniqueKind.skillPractice:
      return it;
  }
}

/// Le bloc [block] où chaque emplacement de travail en répétitions, sans
/// technique ni groupe, reçoit une des techniques de [injectedTechniques]
/// (la même toutes les semaines), à partir du rang [offset] ; ses règles
/// d'autorégulation sont retirées. Les tests, les échauffements, les
/// maintiens, les groupes et les emplacements dotés d'une autre technique
/// que « série de tête puis séries allégées » sont laissés tels quels.
ProgramBlock injectTechniques(ProgramBlock block, {int offset = 0}) {
  var counter = offset;
  final bySlot = <String, SetTechniqueKind?>{};
  ExercisePrescription change(ExercisePrescription it) {
    final technique = it.technique;
    if (it.kind == SetKind.test ||
        it.kind == SetKind.warmup ||
        it.repsLow == null ||
        it.repsHigh == null ||
        it.sets < 2 ||
        it.groupId != null ||
        (technique != null &&
            technique.kind != SetTechniqueKind.standard &&
            technique.kind != SetTechniqueKind.topSetBackoff)) {
      return it;
    }
    final loaded = it.startLoadKg != null || it.percentOfOneRm != null;
    final kind = bySlot.putIfAbsent(it.slotId, () {
      for (var i = 0; i < injectedTechniques.length; i++) {
        final k = injectedTechniques[(counter + i) % injectedTechniques.length];
        if (loaded || !_needsLoad(k)) {
          counter += i + 1;
          return k;
        }
      }
      return null;
    });
    return kind == null
        ? it
        : _withTechnique(it.copyWith(autoregulation: null), kind);
  }

  return block.copyWith(
    pass2: block.pass2.copyWith(
      weeks: <WeekPrescription>[
        for (final w in block.pass2.weeks)
          w.copyWith(
            days: <DayPrescription>[
              for (final d in w.days)
                d.copyWith(
                  items: <ExercisePrescription>[
                    for (final it in d.items) change(it),
                  ],
                ),
            ],
          ),
      ],
    ),
  );
}
