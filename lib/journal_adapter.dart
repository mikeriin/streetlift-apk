// G3 — Conversion du journal actuel de l'application vers le journal de
// `kalis_core` (`TrainingLog`), règles C1 à C12 de
// packages/kalis_core/docs/CONVERSION_JOURNAL.md. L'adaptateur est côté
// application (D0.3) ; il lit la sauvegarde telle qu'elle est exportée
// (`logs`, `programStart`, `koach.answers`) et ne modifie rien : l'ancien
// journal reste la source (D1.1 mise à part). Les exercices sont retrouvés
// par la correspondance des noms du lot G3 ; un nom sans correspondance est
// écarté et compté, aucun identifiant n'est inventé.
//
// Utilisé par les tests de G3 ; G9 s'en servira pour présenter l'historique
// au moteur dynamique.
import 'package:kalis_core/kalis_core.dart' show Flames, TrainingLog;

/// Rapport de conversion (mêmes compteurs que la conversion de référence).
class JournalConversionReport {
  int sessionsRead = 0,
      sessionsConverted = 0,
      manualSessionsDropped = 0,
      emptySessionsDropped = 0,
      setsConverted = 0,
      setsNotDone = 0,
      setsUnmappedExercise = 0,
      setsWithoutMeasure = 0,
      painAnswersDropped = 0;
  final List<String> unmappedExerciseNames = [];

  Map<String, Object?> toJson() => {
    'sessionsRead': sessionsRead,
    'sessionsConverted': sessionsConverted,
    'manualSessionsDropped': manualSessionsDropped,
    'emptySessionsDropped': emptySessionsDropped,
    'setsConverted': setsConverted,
    'setsNotDone': setsNotDone,
    'setsUnmappedExercise': setsUnmappedExercise,
    'setsWithoutMeasure': setsWithoutMeasure,
    'unmappedExerciseNames': unmappedExerciseNames,
    'painAnswersDropped': painAnswersDropped,
  };
}

/// Identifiant du bloc importé du programme personnel (CONTRAT.md §6).
const kLegacyProgramBlockId = 'legacy-programme-v33';

double? _number(Object? text) {
  if (text is num) return text.toDouble();
  if (text is! String) return null;
  return double.tryParse(text.trim().replaceAll(',', '.'));
}

String _civil(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Convertit le journal de la sauvegarde [doc] (`logs`, `programStart`,
/// `koach.answers`).
///
/// - [exerciseId] : nom enregistré → identifiant v1.1 (null : sans
///   correspondance) ;
/// - [usesSeconds] : l'exercice du catalogue se mesure en secondes ;
/// - [dayOrder] : identifiants des exercices d'une journée du programme,
///   dans l'ordre (C5) ;
/// - [legacyDate] : date d'origine d'une journée sans départ enregistré (C3).
///
/// G9 (moteur dynamique, facultatifs ; sans eux la conversion est celle de
/// G3) :
/// - [skip] : séance laissée hors du journal (la séance en cours) ;
/// - [session] : champs de la séance fournis par l'application (place
///   dans le bloc `programRef`, bilan santé, lieu, séries prévues), qui
///   remplacent ceux des règles C3 et C11 ;
/// - [slotOf] : emplacement du bloc d'un exercice du journal ;
/// - [targetOf] : cible affichée de la série de rang [index] (rang dans le
///   journal, séries non validées comprises). Avec une cible, une série
///   réussie atteint au moins le bas de sa plage (C10) ;
/// - [testOf] : les séries de l'exercice sont celles d'un test.
/// La note `flames` (G9, flammes de 1 à 10) passe avant `effort` et `rir`.
({TrainingLog log, JournalConversionReport report}) convertLegacyJournal(
  Map<String, dynamic> doc, {
  required String? Function(String name) exerciseId,
  required bool Function(String id) usesSeconds,
  required List<String> Function(int week, int day) dayOrder,
  required DateTime Function(int week, int day) legacyDate,
  bool Function(String key)? skip,
  Map<String, Object?>? Function(int week, int day, String key)? session,
  String? Function(int week, int day, String exerciseKey)? slotOf,
  bool Function(int week, int day, String exerciseKey)? testOf,
  Map<String, Object?>? Function(
    int week,
    int day,
    String exerciseKey,
    int index,
  )?
  targetOf,
}) {
  final report = JournalConversionReport();
  final logs = (doc['logs'] as Map?)?.cast<String, dynamic>() ?? const {};
  final start = (doc['programStart'] as Map?)?['date'];
  final startDate = start is String ? DateTime.tryParse(start) : null;
  final answers =
      ((doc['koach'] as Map?)?['answers'] as Map?)?.cast<String, dynamic>() ??
      const {};
  final key = RegExp(r'^S(\d+)-J(\d+)$');
  final sessions = <Map<String, Object?>>[];
  for (final entry in logs.entries) {
    report.sessionsRead++;
    final m = key.firstMatch(entry.key);
    if (m == null || int.parse(m[1]!) == 0) {
      report.manualSessionsDropped++; // C2
      continue;
    }
    if (skip != null && skip(entry.key)) continue;
    final w = int.parse(m[1]!), j = int.parse(m[2]!);
    final s = (entry.value as Map).cast<String, dynamic>();
    final finished = s['finishedAt'];
    final date = finished is String && finished.length >= 10
        ? finished.substring(0, 10)
        : _civil(
            startDate != null
                ? DateTime(
                    startDate.year,
                    startDate.month,
                    startDate.day + (w - 1) * 7 + j - 1,
                  )
                : legacyDate(w, j),
          ); // C3
    final order = dayOrder(w, j);
    final ex = (s['ex'] as Map?)?.cast<String, dynamic>() ?? const {};
    final names =
        (s['exerciseNames'] as Map?)?.cast<String, dynamic>() ?? const {};
    int rank(String k) {
      final i = order.indexOf(k);
      return i < 0 ? order.length : i;
    }

    final keys = ex.keys.toList()
      ..sort((a, b) {
        final c = rank(a).compareTo(rank(b));
        return c != 0 ? c : a.compareTo(b);
      }); // C5
    final sets = <Map<String, Object?>>[];
    var exerciseOrder = 0;
    for (final k in keys) {
      final name = '${names[k] ?? ''}';
      final all = [
        for (final x in ((ex[k] as Map)['sets'] as List? ?? const []))
          (x as Map).cast<String, dynamic>(),
      ];
      final done = [
        for (final x in all)
          if (x['done'] == true) x,
      ];
      final slot = slotOf?.call(w, j, k);
      final test = testOf?.call(w, j, k) ?? false;
      report.setsNotDone += all.length - done.length;
      final id = name.isEmpty ? null : exerciseId(name);
      if (id == null) {
        // C6
        report.setsUnmappedExercise += done.length;
        if (done.isNotEmpty && !report.unmappedExerciseNames.contains(name)) {
          report.unmappedExerciseNames.add(name);
        }
        continue;
      }
      if (done.isEmpty) continue;
      final seconds = usesSeconds(id);
      final before = sets.length;
      var setIndex = 0;
      for (final x in done) {
        final position = all.indexOf(x);
        final value = _number(x['reps']);
        if (value == null || value < 0) {
          report.setsWithoutMeasure++; // C8
          continue;
        }
        final measure = value.truncate();
        final rec = <String, Object?>{
          'exerciseId': id,
          'exerciseOrder': exerciseOrder,
          'setIndex': setIndex++,
          'kind': test ? 'test' : 'work',
        };
        final kg = _number(x['kg']);
        if (kg != null) rec['externalLoadKg'] = kg; // C7
        rec[seconds ? 'seconds' : 'reps'] = measure; // C8
        final flames = x['flames'];
        if (flames is int && flames >= Flames.min && flames <= Flames.max) {
          rec['flames'] = flames; // G9
        } else if (x['flamesUnknown'] != true) {
          final rir = _number(x['effort']) ?? _number(x['rir']);
          if (rir != null && rir >= 0) {
            rec['flames'] = Flames.fromRir(rir); // C9
          }
        }
        final target = targetOf?.call(w, j, k, position);
        final low = target?[seconds ? 'secondsLow' : 'repsLow'];
        rec['success'] = measure > 0 && (low is! int || measure >= low); // C10
        rec['excluded'] = x['excluded'] == true;
        if (slot != null) rec['slotId'] = slot;
        if (target != null && target.isNotEmpty) rec['target'] = target;
        sets.add(rec);
        report.setsConverted++;
      }
      if (sets.length > before) exerciseOrder++;
    }
    if (sets.isEmpty) {
      report.emptySessionsDropped++; // C4
      continue;
    }
    final out = <String, Object?>{
      'id': 'legacy-${entry.key}',
      'date': date,
      'origin': 'imported',
      'programRef': {
        'blockId': kLegacyProgramBlockId,
        'weekIndex': w - 1,
        'dayIndex': j - 1,
      },
      'resume': false,
      'completed': s['done'] == true,
    };
    final a = (answers[entry.key] as Map?)?.cast<String, dynamic>();
    if (a != null && a.isNotEmpty) {
      // C11
      final check = <String, Object?>{};
      final form = _number(a['form']);
      if (form != null) check['overall'] = (form / 2).ceil().clamp(1, 5);
      final sleep = _number(a['sleep']);
      if (sleep != null) check['sleepHours'] = sleep;
      final pain = a['pain'];
      if (pain is Map && pain.isNotEmpty) {
        report.painAnswersDropped += pain.length;
      }
      if (check.isNotEmpty) out['healthCheck'] = check;
    }
    final extra = session?.call(w, j, entry.key);
    // G9 : une valeur nulle retire le champ (séance hors de tout bloc).
    extra?.forEach((k, v) => v == null ? out.remove(k) : out[k] = v);
    out['sets'] = sets;
    out['pains'] = const <Object?>[];
    sessions.add(out);
    report.sessionsConverted++;
  }
  // G7 (D4.9) : séances marquées « reprise » par « Où j'en suis », sans
  // journal : neutres, signalées aux moteurs (`resume`), sans série.
  final resume = (doc['programResume'] as Map?)?['keys'];
  if (resume is List) {
    for (final k in resume) {
      final m = k is String ? key.firstMatch(k) : null;
      if (m == null || logs.containsKey(k)) continue;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      sessions.add({
        'id': 'resume-$k',
        'date': _civil(
          startDate != null
              ? DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day + (w - 1) * 7 + j - 1,
                )
              : legacyDate(w, j),
        ),
        'origin': 'program',
        'resume': true,
        'completed': false,
        'sets': const <Object?>[],
        'pains': const <Object?>[],
      });
    }
  }
  sessions.sort((a, b) {
    final c = (a['date'] as String).compareTo(b['date'] as String);
    return c != 0 ? c : (a['id'] as String).compareTo(b['id'] as String);
  }); // C12
  return (
    log: TrainingLog.fromJson({'schemaVersion': 1, 'sessions': sessions}),
    report: report,
  );
}
