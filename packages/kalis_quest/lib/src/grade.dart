/// Note de séance S/A/B/C (D8.1).
library;

import 'package:kalis_core/kalis_core.dart';

import 'params.dart';
import 'world.dart';

/// Note d'une séance : score de 0 à 100 et lettre.
final class SessionMark {
  /// Note.
  const SessionMark(this.score, this.grade, this.accuracy, this.records);

  /// Score de 0 à 100.
  final int score;

  /// Lettre.
  final SessionGrade grade;

  /// Justesse des flammes retenue, de 0 à 1.
  final double accuracy;

  /// Records de la séance (hors premières fois).
  final int records;
}

/// Note de la séance [f] : réalisation, justesse des flammes, records.
/// Une séance allégée faite en entier a une réalisation complète ; sans
/// série notée ayant une cible, la justesse vaut la réalisation.
SessionMark markOf(SessionFacts f, QuestParams p) {
  var records = 0;
  for (final r in f.records) {
    if (r.previous != null) {
      records++;
    }
  }
  final accuracy = f.accuracy ?? f.completion;
  final score =
      (p.gradeCompletionWeight * f.completion +
              p.gradeAccuracyWeight * accuracy +
              p.gradeRecordWeight * (records > 0 ? 1 : 0))
          .round();
  final grade = score >= p.gradeS
      ? SessionGrade.s
      : (score >= p.gradeA
            ? SessionGrade.a
            : (score >= p.gradeB ? SessionGrade.b : SessionGrade.c));
  return SessionMark(score, grade, accuracy, records);
}
