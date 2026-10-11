/// Suivi des figures : étape actuelle de chaque échelle du bloc
/// (`Pass1Plan.skillLadders`), critère de passage tenu ou non, étape plus
/// facile un mauvais jour. Les critères sont ceux de l'échelle (usage
/// d'entraîneur, R4-F7 ; délai des tendons, R4-F9) : le moteur les
/// applique, il ne les invente pas.
library;

import 'package:kalis_core/kalis_core.dart';

import 'model.dart';
import 'params.dart';
import 'replay.dart';

Reason _r(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

/// État d'une échelle de figure d'après le journal.
final class SkillLine {
  /// Échelle [ladder].
  SkillLine(this.ladder);

  /// Échelle.
  final SkillLadder ladder;

  /// Rang de l'étape actuelle.
  int index = 0;

  /// Jour de la première séance du journal à cette étape, ou `null`.
  int? startDay;

  /// Semaines déjà passées à l'étape avant le journal (profil).
  int tenureWeeks = 0;

  /// Séances de suite où le critère est tenu.
  int streak = 0;

  /// Séances de suite nettement sous le critère.
  int downStreak = 0;

  /// Meilleur maintien propre à l'étape actuelle, en secondes.
  int bestHold = 0;

  /// Meilleur nombre de répétitions propres à l'étape actuelle.
  int bestReps = 0;

  /// Jour de cette meilleure série.
  int? bestDay;

  /// Le passage à l'étape suivante est acquis (critère, durée, douleur).
  bool earned = false;

  /// Étape actuelle.
  SkillStep get step => ladder.steps[index];

  /// Identifiant de l'étape de rang [i], ou `null`.
  String? idAt(int i) =>
      i < 0 || i >= ladder.steps.length ? null : ladder.steps[i].exerciseId;

  /// Rang de l'exercice [exerciseId] dans l'échelle, ou −1.
  int indexOf(String exerciseId) {
    for (var i = 0; i < ladder.steps.length; i++) {
      if (ladder.steps[i].exerciseId == exerciseId) {
        return i;
      }
    }
    return -1;
  }

  /// Semaines de journal à l'étape actuelle, au jour [day].
  int observedWeeks(int day) {
    final start = startDay;
    return start == null || day < start ? 0 : (day - start) ~/ 7;
  }
}

/// Tableau des figures d'un bloc.
final class SkillBoard {
  SkillBoard._(this.lines, this._day, this._params);

  /// Tableau du bloc de [view] d'après les séances [digests], au jour
  /// [day] ; `null` si le bloc n'a pas d'échelle.
  static SkillBoard? of(
    EngineContext ctx,
    BlockView view,
    ModelState state,
    List<SessionDigest> digests,
    int day,
  ) {
    final ladders = view.block.pass1.skillLadders;
    if (ladders == null || ladders.isEmpty) {
      return null;
    }
    final p = ctx.params;
    final lines = <SkillLine>[];
    for (final ladder in ladders) {
      if (ladder.steps.isEmpty) {
        continue;
      }
      final line = SkillLine(ladder);
      for (final s in ctx.profile.skills ?? const <SkillState>[]) {
        if (s.targetExerciseId != ladder.targetExerciseId) {
          continue;
        }
        final at = line.indexOf(s.currentExerciseId);
        if (at >= 0) {
          line.index = at;
          final tenure = s.atStepSince;
          if (tenure != null && tenure.index < p.skillTenureWeeks.length) {
            line.tenureWeeks = p.skillTenureWeeks[tenure.index];
          }
        }
      }
      for (final d in digests) {
        _walk(line, d, p);
      }
      // Une douleur active sur la zone de l'étape retient le passage.
      if (line.earned) {
        final info = ctx.book.find(line.step.exerciseId);
        for (final pain in state.pains.values) {
          if (info != null &&
              pain.lastIntensity > p.skillPainMax &&
              state.painActive(pain.zone, day, p) &&
              info.zoneLevel(pain.zone) >= 0.5) {
            line.earned = false;
          }
        }
      }
      lines.add(line);
    }
    return lines.isEmpty ? null : SkillBoard._(lines, day, p);
  }

  /// Échelles suivies.
  final List<SkillLine> lines;

  final int _day;
  final AdaptParams _params;

  static void _walk(SkillLine line, SessionDigest d, AdaptParams p) {
    // Étape suivante pratiquée après que le passage a été acquis : elle
    // devient l'étape actuelle.
    final nextId = line.idAt(line.index + 1);
    if (line.earned && nextId != null) {
      for (final set in d.session.sets) {
        if (set.isUsable && set.exerciseId == nextId) {
          line
            ..index = line.index + 1
            ..startDay = d.day
            ..tenureWeeks = 0
            ..streak = 0
            ..downStreak = 0
            ..bestHold = 0
            ..bestReps = 0
            ..bestDay = null
            ..earned = false;
          break;
        }
      }
    }
    final step = line.step;
    final c = step.criterion;
    final needHold = c.holdSeconds;
    final needReps = c.reps;
    final minQuality = c.minQuality;
    var seen = false;
    var clean = 0;
    var best = 0;
    for (final set in d.session.sets) {
      if (!set.isUsable ||
          set.kind == SetKind.warmup ||
          set.exerciseId != step.exerciseId) {
        continue;
      }
      seen = true;
      final quality = set.quality;
      final proper = quality == null
          ? set.success
          : (minQuality == null ? quality >= 3 : quality >= minQuality);
      if (!proper) {
        continue;
      }
      final seconds = set.seconds ?? 0;
      final reps = set.reps ?? 0;
      if (seconds > line.bestHold) {
        line
          ..bestHold = seconds
          ..bestDay = d.day;
      }
      if (reps > line.bestReps) {
        line
          ..bestReps = reps
          ..bestDay = d.day;
      }
      final amount = needHold != null ? seconds : reps;
      if (amount > best) {
        best = amount;
      }
      final holdOk = needHold == null || seconds >= needHold;
      final repsOk = needReps == null || reps >= needReps;
      if (holdOk && repsOk) {
        clean++;
      }
    }
    if (!seen) {
      return;
    }
    line.startDay ??= d.day;
    if (clean >= c.sets) {
      line
        ..streak = line.streak + 1
        ..downStreak = 0;
    } else {
      line.streak = 0;
      final need = needHold ?? needReps ?? 1;
      if (best < p.skillDownShare * need) {
        line.downStreak++;
      } else {
        line.downStreak = 0;
      }
    }
    final sessions = c.sessions ?? p.skillSessions;
    final weeks = c.minWeeks ?? 0;
    // La durée minimale se compte en semaines de journal à l'étape (les
    // tendons s'adaptent à ce qui est fait, pas à ce qui est déclaré).
    line.earned =
        line.streak >= sessions &&
        line.observedWeeks(d.day) >= weeks &&
        line.index < line.ladder.steps.length - 1;
  }

  SkillLine? _lineOf(String target) {
    for (final line in lines) {
      if (line.ladder.targetExerciseId == target) {
        return line;
      }
    }
    return null;
  }

  /// Étape actuelle de la figure [target], ou `null`.
  String? currentStep(String target) => _lineOf(target)?.step.exerciseId;

  /// Vrai si l'étape [exerciseId] de la figure [target] peut être servie :
  /// étape actuelle ou plus facile, ou étape suivante une fois le passage
  /// acquis. Un exercice hors de l'échelle est toujours servi.
  bool allowed(String target, String exerciseId) {
    final line = _lineOf(target);
    if (line == null) {
      return true;
    }
    final at = line.indexOf(exerciseId);
    if (at < 0 || at <= line.index) {
      return true;
    }
    return line.earned && at == line.index + 1;
  }

  /// Semaines passées à l'étape actuelle de la figure [target].
  int weeksAtStep(String target) {
    final line = _lineOf(target);
    return line == null ? 0 : line.tenureWeeks + line.observedWeeks(_day);
  }

  /// Étape plus facile que [exerciseId] dans l'échelle de [target], ou
  /// `null`.
  String? easierStep(String target, String exerciseId) {
    final line = _lineOf(target);
    if (line == null) {
      return null;
    }
    final at = line.indexOf(exerciseId);
    return at <= 0 ? null : line.idAt(at - 1);
  }

  /// Suivi de chaque figure pour le résumé d'adaptation.
  List<SkillProgress> progress() {
    final out = <SkillProgress>[];
    for (final line in lines) {
      final step = line.step;
      final weeks = line.tenureWeeks + line.observedWeeks(_day);
      final reasons = <Reason>[];
      final next = line.idAt(line.index + 1);
      final easier = line.idAt(line.index - 1);
      if (line.earned && next != null) {
        reasons.add(
          _r(ReasonCodes.adaptSkillStepUp, <String, Object?>{
            'exerciseId': next,
          }),
        );
      } else if (line.downStreak >= _params.skillDownSessions &&
          easier != null) {
        reasons.add(
          _r(ReasonCodes.adaptSkillStepDown, <String, Object?>{
            'exerciseId': easier,
          }),
        );
      } else {
        reasons.add(
          _r(ReasonCodes.adaptSkillHold, <String, Object?>{
            'exerciseId': step.exerciseId,
            'weeksAtStep': weeks,
          }),
        );
      }
      out.add(
        SkillProgress(
          targetExerciseId: line.ladder.targetExerciseId,
          currentExerciseId: step.exerciseId,
          stepIndex: line.index,
          weeksAtStep: weeks,
          criterionMet: line.earned,
          bestHoldSeconds: line.bestHold > 0 ? line.bestHold : null,
          bestReps: line.bestReps > 0 ? line.bestReps : null,
          reasons: reasons,
        ),
      );
    }
    return out;
  }

  /// États à reporter dans le profil par l'application.
  List<SkillState> states() {
    final out = <SkillState>[];
    for (final line in lines) {
      final best = line.bestDay;
      out.add(
        SkillState(
          targetExerciseId: line.ladder.targetExerciseId,
          currentExerciseId: line.step.exerciseId,
          bestHoldSeconds: line.bestHold > 0 ? line.bestHold : null,
          bestReps: line.bestReps > 0 ? line.bestReps : null,
          assessedOn: best == null ? null : CivilDate.fromDayNumber(best),
        ),
      );
    }
    return out;
  }
}
