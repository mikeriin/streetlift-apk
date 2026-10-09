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

/// CI1f : mini-séries d'une série (`parts` de la saisie) au format du
/// journal du moteur ; null : aucune, ou illisibles.
({int total, List<Map<String, Object?>> json})? _parts(
  Object? raw,
  bool seconds,
) {
  if (raw is! List || raw.isEmpty || raw.length > 120) return null;
  var total = 0;
  final json = <Map<String, Object?>>[];
  for (final p in raw) {
    if (p is! Map) return null;
    final v = p['reps'];
    if (v is! int || v < 0 || v > 1000) return null;
    final r = p['restBefore'];
    total += v;
    json.add({
      (seconds ? 'seconds' : 'reps'): v,
      if (r is int && r >= 0 && r <= 3600) 'restBeforeSeconds': r,
    });
  }
  return (total: total, json: json);
}

/// CI1f : myo-reps notés avant 6.11.0 en lignes séparées (activation, puis
/// une ligne par mini-série) : une série avec ses parties, si c'est sûr
/// (lignes validées d'affilée depuis l'activation, les suivantes non
/// validées : la série s'est arrêtée là) ; null sinon.
({int total, List<(int, int?)> parts, int? flames})? _groupMyo(
  List<Map<String, dynamic>> all,
  int rest,
) {
  if (all.length < 2 || all.length > 120) return null;
  var done = 0;
  while (done < all.length && all[done]['done'] == true) {
    done++;
  }
  if (done == 0) return null;
  for (var i = done; i < all.length; i++) {
    if (all[i]['done'] == true) return null;
  }
  final rows = all.sublist(0, done);
  final parts = <(int, int?)>[];
  String? kg;
  for (var i = 0; i < rows.length; i++) {
    final x = rows[i];
    if (x['done'] != true || x['excluded'] == true) return null;
    if (x['parts'] != null) return null;
    final v = _number(x['reps']);
    if (v == null || v < 0 || v != v.truncateToDouble() || v > 1000) {
      return null;
    }
    if (i == 0 && v < 1) return null;
    final load = '${x['kg'] ?? ''}'.trim();
    if (i == 0) {
      kg = load;
    } else if (load != kg) {
      return null;
    }
    parts.add((v.toInt(), i == 0 ? null : rest));
  }
  final first = rows.first;
  int? flames;
  final f = first['flames'];
  if (f is int && f >= Flames.min && f <= Flames.max) {
    flames = f;
  } else if (first['flamesUnknown'] != true) {
    final rir = _number(first['effort']) ?? _number(first['rir']);
    if (rir != null && rir >= 0) flames = Flames.fromRir(rir);
  }
  return (
    total: parts.fold<int>(0, (a, p) => a + p.$1),
    parts: parts,
    flames: flames,
  );
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
///
/// CI1f (mini-séries, contrat 0.4.0 § 12) :
/// - une série notée avec ses mini-séries (`parts`) devient **une** ligne
///   dont `reps` (ou `seconds`) est le total et `parts` le détail, avec la
///   technique servie ([lineOf] : code `SetTechniqueKind`) ;
/// - [lineOf] donne aussi l'exercice du bloc quand il diffère du nom de
///   la ligne, la mesure (secondes ; minutes : `scale` 60) et la technique
///   des lignes notées par tour ou par bloc (`density` : le moteur les
///   compte sans y lire de capacité) ;
/// - [myoOf] : l'exercice est une ligne de myo-reps du programme importé
///   (repos des mini-séries en secondes) ; ses séries notées avant 6.11.0
///   en lignes séparées (activation puis mini-séries) sont regroupées à la
///   lecture en une série avec ses `parts` quand c'est sûr (toutes
///   validées, mesures lisibles, même charge, aucune écartée, aucune déjà
///   découpée) ; sinon laissées telles quelles. Le journal n'est jamais
///   réécrit.
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
  ({
    String? exerciseId,
    bool? seconds,
    int scale,
    String? technique,
    bool meters,
  })
  Function(int week, int day, String exerciseKey, bool withParts)?
  lineOf,
  int? Function(int week, int day, String exerciseKey)? myoOf,
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
      final line = lineOf?.call(w, j, k, false);
      final id = line?.exerciseId ?? (name.isEmpty ? null : exerciseId(name));
      if (id == null) {
        // C6
        report.setsUnmappedExercise += done.length;
        if (done.isNotEmpty && !report.unmappedExerciseNames.contains(name)) {
          report.unmappedExerciseNames.add(name);
        }
        continue;
      }
      if (done.isEmpty) continue;
      final seconds = line?.seconds ?? usesSeconds(id);
      final scale = line?.scale ?? 1;
      final before = sets.length;
      var setIndex = 0;
      // CI1f : myo-reps notés en lignes séparées, regroupés si c'est sûr.
      final myoRest = myoOf?.call(w, j, k);
      final grouped = myoRest == null ? null : _groupMyo(all, myoRest);
      if (grouped != null) {
        final rec = <String, Object?>{
          'exerciseId': id,
          'exerciseOrder': exerciseOrder,
          'setIndex': 0,
          'kind': test ? 'test' : 'work',
          (seconds ? 'seconds' : 'reps'): grouped.total,
          'technique': 'myo_reps',
          'parts': [
            for (final p in grouped.parts)
              {
                (seconds ? 'seconds' : 'reps'): p.$1,
                if (p.$2 != null) 'restBeforeSeconds': p.$2,
              },
          ],
          'success': grouped.parts.first.$1 > 0,
          'excluded': false,
        };
        final kg = _number(all.first['kg']);
        if (kg != null) rec['externalLoadKg'] = kg;
        if (grouped.flames != null) rec['flames'] = grouped.flames;
        if (slot != null) rec['slotId'] = slot;
        sets.add(rec);
        report.setsConverted += grouped.parts.length;
        exerciseOrder++;
        continue;
      }
      for (final x in done) {
        final position = all.indexOf(x);
        final value = _number(x['reps']);
        if (value == null || value < 0) {
          report.setsWithoutMeasure++; // C8
          continue;
        }
        var measure = value.truncate();
        // CI1f : mini-séries saisies une à une : la ligne porte le total.
        final parts = _parts(x['parts'], seconds);
        if (parts != null) measure = parts.total;
        // CI1f : durée notée en minutes (ligne marquée, ou ligne de durée
        // du programme, toujours en minutes).
        if (parts == null && (x['unit'] == 'min' || scale == 60)) {
          measure *= 60;
        }
        final rec = <String, Object?>{
          'exerciseId': id,
          'exerciseOrder': exerciseOrder,
          'setIndex': setIndex++,
          'kind': test ? 'test' : 'work',
        };
        final kg = _number(x['kg']);
        if (kg != null) rec['externalLoadKg'] = kg; // C7
        if (line?.meters ?? false) {
          rec['distanceMeters'] = measure.toDouble(); // CI1f : mètres
        } else {
          rec[seconds ? 'seconds' : 'reps'] = measure; // C8
        }
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
        // Mini-séries gardées avec leur technique (une ligne dont la
        // technique n'est plus servie est lue sur son total).
        final partsTechnique = parts == null
            ? null
            : lineOf?.call(w, j, k, true).technique;
        if (parts != null && (lineOf == null || partsTechnique != null)) {
          rec['parts'] = parts.json;
          if (partsTechnique != null) rec['technique'] = partsTechnique;
        } else if (line?.technique case final t?) {
          rec['technique'] = t;
        } else if (myoRest != null && all.length >= 2) {
          // Myo-reps en lignes séparées, pas regroupables sans risque :
          // aucune ligne n'est lue comme une série d'une traite.
          rec['technique'] = 'myo_reps';
        }
        if (target != null && target.isNotEmpty) rec['target'] = target;
        // CI1 : rôle de la ligne dans la technique servie (série de tête,
        // allégée, montée, test, tentative…), contrat 0.4.0 § 12.
        final role = target?['role'];
        if (role is String) {
          rec['role'] = role;
          if (role == 'test' || role == 'attempt') rec['kind'] = 'test';
          if (role == 'warmup') rec['kind'] = 'warmup';
        }
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
    // CI1f : résultats des groupes d'exercices enchaînés.
    final groups = s['groups'];
    if (groups is Map && groups.isNotEmpty) {
      final results = <Map<String, Object?>>[];
      for (final g in groups.entries) {
        final v = g.value;
        if (g.key is! String || v is! Map) continue;
        int? whole(Object? x, int max) =>
            x is int && x >= 0 && x <= max ? x : null;
        results.add({
          'groupId': g.key,
          'completed': v['completed'] == true,
          if (whole(v['elapsed'], 86400) case final e?) 'elapsedSeconds': e,
          if (whole(v['rounds'], 1000) case final r?) 'rounds': r,
          if (whole(v['extraReps'], 10000) case final x?) 'extraReps': x,
        });
        if (results.length >= 20) break;
      }
      if (results.isNotEmpty) out['groupResults'] = results;
    }
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
