// CI1 (dev6.9.0, pipeline CP) : textes des prescriptions du chemin street
// calibré (`kalis_plan` 0.2, `kalis_adapt` 0.2, contrat `kalis_core` 0.4).
//
// Les moteurs décrivent la séance en données (technique, tempo, intensité,
// rôles des séries, tests, groupes) ; ce fichier les rend en phrases
// courtes, comme l'export lu par le panel de coachs (`kalis_bench`,
// `export.dart`), pour l'écran de séance et la vue du programme. Les notes
// de coach du chemin street (`plan.coach_note`, `plan.pain_rule`,
// `plan.progression_rule`…) sont rédigées par `kalis_plan`
// (`coachReasonText`) : l'application les affiche telles quelles.
// Aucune règle d'entraînement ici : seulement de la lecture.
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart'
    as kp
    show CoachNotes, coachPhaseLabel, coachReasonText, isCoachPlan;

String _num(double v) {
  final rounded = (v * 100).roundToDouble() / 100;
  var text = rounded.toStringAsFixed(2);
  if (text.endsWith('00')) {
    text = text.substring(0, text.length - 3);
  } else if (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  return text.replaceAll('.', ',');
}

String _duration(int seconds) {
  if (seconds >= 120 && seconds % 60 == 0) return '${seconds ~/ 60} min';
  if (seconds >= 120) {
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }
  return '$seconds s';
}

String _range(int low, int high) => low == high ? '$low' : '$low à $high';

/// Vrai si le bloc est écrit par le chemin calibré (intention de bloc).
bool isCoachBlock(kc.ProgramBlock block) => kp.isCoachPlan(block.pass1);

/// Nom français d'une phase de saison ou d'une intention de semaine.
String phaseLabel(String code) => kp.coachPhaseLabel(code);

/// Nom court d'une phase, avec majuscule (titres, puces).
String phaseTitle(String code) {
  final l = phaseLabel(code);
  final short = l.split(' (').first;
  return short.isEmpty ? l : '${short[0].toUpperCase()}${short.substring(1)}';
}

/// Libellé court du rôle d'une ligne de journal (colonne des séries).
/// Null : série classique, numérotée.
String? rowRoleShort(kc.SetRole? role, int i, int firstOfRole) =>
    switch (role) {
      kc.SetRole.top => 'Tête',
      kc.SetRole.backOff => 'A${i - firstOfRole + 1}',
      kc.SetRole.warmup => 'Éc${i - firstOfRole + 1}',
      kc.SetRole.test => 'Test',
      kc.SetRole.attempt => 'T${i - firstOfRole + 1}',
      kc.SetRole.wave => 'V${i - firstOfRole + 1}',
      kc.SetRole.rung => 'P${i - firstOfRole + 1}',
      kc.SetRole.interval => 'M${i - firstOfRole + 1}',
      _ => null,
    };

/// Libellé lisible (TalkBack, légende) du rôle d'une ligne.
String? rowRoleLong(kc.SetRole? role) => switch (role) {
  kc.SetRole.top => 'série de tête',
  kc.SetRole.backOff => 'série allégée',
  kc.SetRole.warmup => 'montée d’échauffement',
  kc.SetRole.test => 'série de test',
  kc.SetRole.attempt => 'tentative',
  kc.SetRole.wave => 'palier de vague',
  kc.SetRole.rung => 'palier',
  kc.SetRole.interval => 'intervalle',
  _ => null,
};

/// Rôle et plage de la ligne [index] d'une prescription sans cibles par
/// série : lecture du contrat (`kalis_core`, § 12). Avec cibles, c'est le
/// rôle écrit dans la cible.
({kc.SetRole? role, int? low, int? high}) prescriptionRow(
  kc.ExercisePrescription p,
  int index,
) {
  final seconds = p.secondsLow != null || p.secondsHigh != null;
  final low = seconds ? p.secondsLow : p.repsLow;
  final high = seconds ? p.secondsHigh : p.repsHigh;
  final targets = p.setTargets;
  if (targets != null && targets.isNotEmpty) {
    final t = targets[index < targets.length ? index : targets.length - 1];
    return (
      role: t.role ?? _derivedRole(p, index).role,
      low: seconds ? t.secondsLow : t.repsLow,
      high: seconds ? t.secondsHigh : t.repsHigh,
    );
  }
  final d = _derivedRole(p, index);
  return (role: d.role, low: d.low ?? low, high: d.high ?? high);
}

({kc.SetRole? role, int? low, int? high}) _derivedRole(
  kc.ExercisePrescription p,
  int index,
) {
  if (p.kind == kc.SetKind.test) {
    final k = p.test?.kind;
    return (
      role: k == kc.TestKind.oneRm || k == kc.TestKind.attemptSimulation
          ? kc.SetRole.attempt
          : kc.SetRole.test,
      low: null,
      high: null,
    );
  }
  if (p.kind == kc.SetKind.warmup) {
    return (role: kc.SetRole.warmup, low: null, high: null);
  }
  final t = p.technique;
  if (t == null || t.kind == kc.SetTechniqueKind.standard) {
    return (role: null, low: null, high: null);
  }
  if (t.lastSetOnly == true && index < p.sets - 1) {
    return (role: null, low: null, high: null);
  }
  switch (t.kind) {
    case kc.SetTechniqueKind.topSetBackoff:
      return index == 0
          ? (role: kc.SetRole.top, low: null, high: null)
          : (
              role: kc.SetRole.backOff,
              low: t.backoffRepsLow,
              high: t.backoffRepsHigh,
            );
    case kc.SetTechniqueKind.wave:
      final reps = t.waveReps;
      if (reps == null || reps.isEmpty) break;
      final n = reps[index % reps.length];
      return (role: kc.SetRole.wave, low: n, high: n);
    case kc.SetTechniqueKind.pyramid:
      final reps = t.pyramidReps;
      if (reps == null || reps.isEmpty) break;
      final n = reps[index < reps.length ? index : reps.length - 1];
      return (role: kc.SetRole.rung, low: n, high: n);
    case kc.SetTechniqueKind.ladder:
      final s = t.ladderStart, st = t.ladderStep, top = t.ladderTop;
      if (s == null || st == null || top == null || st <= 0) break;
      final rungs = (top - s) ~/ st + 1;
      final n = s + st * (index % (rungs < 1 ? 1 : rungs));
      return (role: kc.SetRole.rung, low: n, high: n);
    case kc.SetTechniqueKind.emom:
      return (role: kc.SetRole.interval, low: null, high: null);
    default:
      break;
  }
  return (role: null, low: null, high: null);
}

/// Séries et répétitions (ou durée) d'une prescription, en clair.
String coachVolumeText(kc.ExercisePrescription p) {
  final reps = p.repsLow != null || p.repsHigh != null;
  final timed = p.secondsLow != null || p.secondsHigh != null;
  final rl = p.repsLow ?? p.repsHigh ?? 0, rh = p.repsHigh ?? p.repsLow ?? 0;
  final sl = p.secondsLow ?? p.secondsHigh ?? 0;
  final sh = p.secondsHigh ?? p.secondsLow ?? 0;
  final t = p.technique;
  if (t != null && reps) {
    switch (t.kind) {
      case kc.SetTechniqueKind.topSetBackoff:
        final back = t.backoffSets ?? p.sets - 1;
        final low = t.backoffRepsLow ?? rl;
        final high = t.backoffRepsHigh ?? rh;
        final drop = t.backoffDropPct;
        return '1 × ${_range(rl, rh)} (série de tête), puis '
            '$back × ${_range(low, high)}'
            '${drop == null || drop == 0 ? '' : ' à −${_num(drop * 100)} %'}';
      case kc.SetTechniqueKind.emom:
        final count = t.intervals ?? p.sets;
        final every = t.intervalSeconds ?? 60;
        return every == 60
            ? '$count min : ${_range(rl, rh)} rép. au début de chaque minute'
            : '$count × ${_range(rl, rh)}, un départ toutes les ${_duration(every)}';
      case kc.SetTechniqueKind.cluster:
        return '${p.sets} × ${t.miniSets ?? '?'} × ${t.miniSetReps ?? '?'} '
            '(${t.intraRestSeconds ?? 15} s entre les mini-séries)';
      case kc.SetTechniqueKind.restPause:
        return '${p.sets} × ${_range(rl, rh)} au total, en relances '
            'après ${t.intraRestSeconds ?? 20} s de pause';
      case kc.SetTechniqueKind.myoReps:
        return '${p.sets} × série d’activation, puis mini-séries de '
            '${t.miniSetReps ?? 3} après ${t.intraRestSeconds ?? 5} s';
      case kc.SetTechniqueKind.density:
        final d = t.durationSeconds;
        return d == null
            ? '${_range(rl, rh)} rép. au total'
            : '${_range(rl, rh)} rép. au total en ${_duration(d)}';
      case kc.SetTechniqueKind.wave:
      case kc.SetTechniqueKind.pyramid:
      case kc.SetTechniqueKind.ladder:
        final steps = <int>[
          for (var i = 0; i < p.sets; i++) prescriptionRow(p, i).high ?? rh,
        ];
        return '${p.sets} paliers : ${steps.join(' – ')} rép.';
      default:
        break;
    }
  }
  final test = p.test;
  if (test != null && reps) {
    return switch (test.kind) {
      kc.TestKind.oneRm => '${p.sets} tentatives × ${_range(rl, rh)}',
      kc.TestKind.maxReps => '1 série maximale (repère : ${_range(rl, rh)})',
      _ => '${p.sets} × ${_range(rl, rh)}',
    };
  }
  if (reps) return '${p.sets} × ${_range(rl, rh)}';
  if (timed) {
    if (p.sets == 1 && sh >= 300) {
      return sl == sh ? _duration(sh) : '${sl ~/ 60} à ${sh ~/ 60} min';
    }
    return sl == sh
        ? '${p.sets} × ${_duration(sh)}'
        : '${p.sets} × $sl à $sh s';
  }
  final m = p.distanceMeters;
  if (m != null) {
    return p.sets == 1 && m >= 1500
        ? '${_num(m / 1000)} km'
        : '${p.sets} × ${m.round()} m';
  }
  return '${p.sets} séries';
}

/// Intensité écrite (part du 1RM ou d'un repère), ou null.
String? coachIntensityText(kc.ExercisePrescription p) {
  final percent = p.percentOfOneRm;
  if (percent != null) {
    return '≈ ${(percent * 100).round()} % du 1RM (charge totale)';
  }
  final it = p.intensity;
  if (it == null) return null;
  final share = '${(it.value * 100).round()} %';
  switch (it.basis) {
    case kc.IntensityBasis.percentOneRm:
      return '≈ $share du 1RM du mouvement de référence';
    case kc.IntensityBasis.percentBenchmark:
      final top = p.secondsHigh ?? p.repsLow ?? p.repsHigh;
      final base = top == null || it.value <= 0
          ? null
          : (top / it.value).round();
      return it.referenceKind == kc.BenchmarkKind.maxHold
          ? '≈ $share de ton maintien maximal'
                '${base == null ? '' : ' (repère : $base s)'}'
          : '≈ $share de ton maximum de répétitions'
                '${base == null ? '' : ' (repère : $base)'}';
    default:
      return null;
  }
}

/// Tempo écrit, en clair (descente, pauses), ou null.
String? coachTempoText(kc.ExercisePrescription p) {
  final t = p.tempo;
  if (t == null) return null;
  final parts = <String>[];
  if (t.topPauseSeconds > 0) parts.add('${t.topPauseSeconds} s tenues en haut');
  if (t.eccentricSeconds > 0) {
    parts.add('descente en ${t.eccentricSeconds} s');
  }
  if (t.bottomPauseSeconds > 0) {
    parts.add('${t.bottomPauseSeconds} s de pause en bas');
  }
  if (t.concentricSeconds == 0 && t.eccentricSeconds > 0) {
    parts.add('remontée aidée');
  }
  if (parts.isEmpty) return null;
  final s = parts.join(', ');
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Nom de la technique de série, ou null pour une série classique.
String? techniqueLabel(kc.SetTechniqueKind k) => switch (k) {
  kc.SetTechniqueKind.standard => null,
  kc.SetTechniqueKind.topSetBackoff => 'Série de tête puis séries allégées',
  kc.SetTechniqueKind.cluster => 'Clusters (pauses courtes dans la série)',
  kc.SetTechniqueKind.restPause => 'Rest-pause',
  kc.SetTechniqueKind.myoReps => 'Myo-reps',
  kc.SetTechniqueKind.dropSet => 'Série dégressive',
  kc.SetTechniqueKind.isometricHold => 'Maintien chronométré',
  kc.SetTechniqueKind.accentuatedEccentric => 'Descentes freinées',
  kc.SetTechniqueKind.contrast => 'Contraste (lourd puis explosif)',
  kc.SetTechniqueKind.wave => 'Vagues',
  kc.SetTechniqueKind.amrap => 'Série au maximum',
  kc.SetTechniqueKind.emom => 'EMOM (départ chaque minute)',
  kc.SetTechniqueKind.density => 'Bloc de densité',
  kc.SetTechniqueKind.ladder => 'Échelle',
  kc.SetTechniqueKind.pyramid => 'Pyramide',
  kc.SetTechniqueKind.skillPractice => 'Pratique de la figure',
  kc.SetTechniqueKind.forTime => 'Contre la montre',
};

/// Consigne courte de la technique servie (comment la faire).
String? techniqueHint(kc.ExercisePrescription p) {
  final t = p.technique;
  if (t == null) return null;
  return switch (t.kind) {
    kc.SetTechniqueKind.topSetBackoff =>
      'La série de tête d’abord ; les séries allégées sont recalculées sur '
          'ce que tu viens de faire.',
    kc.SetTechniqueKind.isometricHold =>
      'Lance le chrono à chaque tenue ; arrête avant de perdre la position.',
    kc.SetTechniqueKind.accentuatedEccentric =>
      'Contrôle chaque descente ; arrête la série dès qu’une descente '
          'accélère.',
    kc.SetTechniqueKind.emom =>
      'Lance le chrono : chaque série part au début de la minute, le repos '
          'est ce qui reste. Si les répétitions ne passent plus, arrête là.',
    kc.SetTechniqueKind.density =>
      'Lance le chrono : un maximum de répétitions propres dans le temps, '
          'en petites séries.',
    kc.SetTechniqueKind.cluster ||
    kc.SetTechniqueKind.restPause ||
    kc.SetTechniqueKind.myoReps =>
      'Note le total de la série ; le chrono des mini-repos est sous le '
          'titre.',
    kc.SetTechniqueKind.skillPractice =>
      'Essais frais et propres ; arrête quand la qualité baisse.',
    _ => null,
  };
}

/// Raisons d'une prescription écrites une fois dans les règles du
/// programme, pas sous chaque exercice.
const Set<String> _ruleCodes = <String>{
  kc.ReasonCodes.planProgressionRule,
  kc.ReasonCodes.planToCalibrate,
};

bool _isBlockNote(kc.Reason r) {
  if (r.code != kc.ReasonCodes.planCoachNote) return false;
  final note = r.params['note'];
  return note == kp.CoachNotes.rampWarmup ||
      note == kp.CoachNotes.rampBodyweight ||
      note == kp.CoachNotes.loadAdjust ||
      note == kp.CoachNotes.repsAdjust ||
      note == kp.CoachNotes.testUse ||
      note == kp.CoachNotes.badDay ||
      note == kp.CoachNotes.missed ||
      note == kp.CoachNotes.testRest ||
      note == kp.CoachNotes.topSetBackoff ||
      note == kp.CoachNotes.submaximalHold ||
      note == kp.CoachNotes.qualityFirst ||
      note == kp.CoachNotes.everyMinute ||
      note == kp.CoachNotes.generalWarmup;
}

/// Texte d'une raison du chemin street (rédigé par `kalis_plan`), ou null.
String? coachText(kc.Reason r, kc.Catalog? catalog) {
  if (catalog == null) return null;
  try {
    return kp.coachReasonText(r, catalog);
  } catch (_) {
    return null;
  }
}

/// Notes de coach propres à un exercice (consignes, règle de douleur…).
List<String> coachItemNotes(kc.ExercisePrescription p, kc.Catalog? catalog) {
  final out = <String>[];
  for (final r in p.reasons) {
    if (_ruleCodes.contains(r.code) || _isBlockNote(r)) continue;
    final text = coachText(r, catalog);
    if (text != null && !out.contains(text)) out.add(text);
  }
  return out;
}

/// Vrai si la raison parle de douleur (règle, arrêt, consultation) :
/// affichée en tête des notes, avec l'icône de prudence.
bool isPainReason(kc.Reason r) =>
    r.code == kc.ReasonCodes.planPainRule ||
    r.code == 'adapt.pain_reported' ||
    r.code == 'adapt.pain_persistent' ||
    (r.code == 'adapt.exercise_skipped' && r.params['cause'] == 'pain') ||
    // CI1d (`kalis_adapt` 0.2.3) : dose du palier de reprise après une
    // douleur, ou remplaçant d'une douleur du jour.
    (r.code == 'adapt.load_held' && r.params['cause'] == 'pain_return') ||
    (r.code == kc.ReasonCodes.planCoachNote &&
        _painNotes.contains(r.params['note']));

/// CI1b : notes de coach de `kalis_plan` 0.2.2 qui parlent de douleur
/// (arrêt d'une douleur qui dure, reprise graduée, étape plus facile,
/// douleur relevée au bloc précédent).
const Set<String> _painNotes = <String>{
  kp.CoachNotes.painTrend,
  kp.CoachNotes.painStop,
  kp.CoachNotes.painStep,
  kp.CoachNotes.painReturn,
  kp.CoachNotes.painReturnItem,
  // CI1d (`kalis_plan` 0.2.3) : bloc de reprise après une douleur qui dure
  // (ni test ni affûtage), poignet sensible déclaré (appuis en extension
  // réduits de moitié).
  kp.CoachNotes.painReprise,
  kp.CoachNotes.wristSpare,
};

/// CI1b : notes du bloc sur une douleur qui dure (`pain_stop` : arrêt et
/// consultation ; `pain_return` : reprise graduée), rédigées par
/// `kalis_plan` 0.2.2 ; vide pour un bloc du chemin 0.1. CI1d : plus
/// `pain_reprise` (`kalis_plan` 0.2.3 : bloc de reprise, sans test ni
/// affûtage, échéance repoussée).
/// [stopped] : zones (index de `kc.BodyZone`) dont l'arrêt est déjà dit
/// par la séance ; leur note d'arrêt n'est pas répétée.
List<String> coachBlockPainNotes(
  kc.ProgramBlock block,
  kc.Catalog? catalog, {
  Set<int> stopped = const <int>{},
}) {
  final out = <String>[];
  if (!isCoachBlock(block)) return out;
  for (final r in [...block.pass1.reasons, ...block.pass2.reasons]) {
    if (r.code != kc.ReasonCodes.planCoachNote) continue;
    final note = r.params['note'];
    if (note != kp.CoachNotes.painStop &&
        note != kp.CoachNotes.painReturn &&
        note != kp.CoachNotes.painReprise) {
      continue;
    }
    final v = r.params['value'];
    if (note == kp.CoachNotes.painStop &&
        v is num &&
        stopped.contains(v.round())) {
      continue;
    }
    final t = coachText(r, catalog);
    if (t != null && !out.contains(t)) out.add(t);
  }
  return out;
}

/// CI1b : vrai si le bloc porte une note d'arrêt (`pain_stop`).
bool coachBlockHasPainStop(kc.ProgramBlock block) =>
    isCoachBlock(block) &&
    [...block.pass1.reasons, ...block.pass2.reasons].any(
      (r) =>
          r.code == kc.ReasonCodes.planCoachNote &&
          r.params['note'] == kp.CoachNotes.painStop,
    );

/// Règles du programme, écrites une fois (progression, douleur, exécution).
/// Vide pour un bloc du chemin 0.1.
List<String> coachProgramRules(kc.ProgramBlock block, kc.Catalog? catalog) {
  final out = <String>[];
  void add(String? t) {
    if (t != null && !out.contains(t)) out.add(t);
  }

  if (!isCoachBlock(block)) return out;
  for (final r in block.pass2.reasons) {
    if (r.code != kc.ReasonCodes.planSeasonPhase) add(coachText(r, catalog));
  }
  for (final w in block.pass2.weeks) {
    for (final d in w.days) {
      for (final p in d.items) {
        for (final r in p.reasons) {
          if (_isBlockNote(r) &&
              r.params['note'] == kp.CoachNotes.everyMinute) {
            add(
              'Départs au chrono : chaque série part à heure fixe (le repos '
              'est ce qui reste) ; si les répétitions ne passent plus, '
              'arrête là.',
            );
          } else if (_ruleCodes.contains(r.code) || _isBlockNote(r)) {
            add(coachText(r, catalog));
          }
        }
      }
    }
  }
  add(
    'Effort visé : les « répétitions en réserve » sont celles que tu '
    'pourrais encore faire proprement à la fin de la série ; s’il t’en '
    'reste moins que prévu, allège ou arrête la série.',
  );
  return out;
}

/// Échelles des figures travaillées : étapes et critère de passage.
List<String> coachLadderLines(kc.ProgramBlock block, kc.Catalog? catalog) {
  String name(String id) => catalog?.find(id)?.name ?? id;
  final out = <String>[];
  for (final ladder in block.pass1.skillLadders ?? const <kc.SkillLadder>[]) {
    final steps = [for (final s in ladder.steps) name(s.exerciseId)];
    final buf = StringBuffer(
      'Vers ${name(ladder.targetExerciseId)} : ${steps.join(' → ')}.',
    );
    if (ladder.steps.isNotEmpty) {
      final c = ladder.steps.first.criterion;
      final hold = c.holdSeconds;
      buf.write(
        ' Étape suivante quand tu tiens ${c.sets} séries de '
        '${hold != null ? '$hold s' : '${c.reps ?? 3} répétitions'} '
        'propres'
        '${c.sessions == null ? '' : ', ${c.sessions} séances de suite'}.',
      );
    }
    out.add(buf.toString());
  }
  return out;
}
