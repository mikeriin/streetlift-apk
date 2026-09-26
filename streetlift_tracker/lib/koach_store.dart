// Koach (L7) — branchement du moteur sur le store : entrées normalisées,
// état recalculé depuis le journal (cache incrémental), décisions de
// l'utilisateur, règles pendant la séance et au bilan. Rien n'est modifié
// sans une action explicite (D4). Koach désactivé : aucun de ces chemins
// n'intervient (D6). Contrat : docs/CONTRAT_L7.md.
part of 'store.dart';

/// Mouvements principaux (clés de la feuille Pilotage).
const koachMovementNames = {
  'mu': 'Muscle-up lesté',
  'pull': 'Traction lestée',
  'dip': 'Dip lesté',
  'squat': 'Back squat',
};

String koachMovementName(String key) => koachMovementNames[key] ?? key;

String _kgText(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  var t = kg.toStringAsFixed(2);
  while (t.endsWith('0')) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}

/// « 2,5 » ; « 35 » ; « 36,25 ».
String koachKg(double kg) => _kgText(kg).replaceAll('.', ',');

extension KoachStore on AppStore {
  /// Koach actif (interrupteur + annotations du programme disponibles).
  bool get koachOn => koach.enabled && koachProgram.available;

  Set<String> get koachKnownRefs => referenceRefs.toSet();

  Set<String> get koachMovements => {
    for (final l in program.pilotage.mainLifts) l.key,
  };

  void _koachSave() {
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------- options
  /// Première activation : repère initial daté (valeurs actuelles), première
  /// pesée, échelle des RIR/RPE déjà saisis figée (contrat §3.3, §10).
  void enableKoach() {
    if (koach.enabled) return;
    koach.enabled = true;
    koach.introSeen = true;
    koach.legacyScale ??= settings.rpe ? 'rpe' : 'rir';
    final now = storeClock();
    final at = ke.wallIso(now);
    for (final entry in values.entries) {
      if (entry.key == 'B4') continue;
      final known = koach.history.any(
        (h) => h.ref == entry.key && h.source == 'initial',
      );
      if (!known) {
        koach.history.add(PilotageEvent(at, entry.key, entry.value, 'initial'));
      }
    }
    final bw = values['B4'];
    if (bw != null && koach.weighIns.isEmpty) {
      koach.weighIns.add(WeighIn(ke.civilIso(now), bw));
    }
    _koachSave();
  }

  void disableKoach() {
    if (!koach.enabled) return;
    koach.enabled = false;
    _koachSave();
  }

  void setKoachStructure(bool on) {
    koach.structure = on;
    _koachSave();
  }

  void setKoachAdvanced(bool on) {
    koach.advanced = on;
    _koachSave();
  }

  /// Questionnaires (D14, KT-036) : activés seulement après l'information.
  void setKoachQuestionnaires(bool on) {
    koach.questionnaires = on ? 'on' : 'off';
    _koachSave();
  }

  bool get koachQuestionnaires => koachOn && koach.questionnaires == 'on';

  void setKoachEquipment(String kind, Map<String, dynamic> value) {
    koach.equipment[kind] = Map<String, dynamic>.of(value);
    _koachSave();
  }

  void resetKoachEquipment() {
    koach.equipment.clear();
    _koachSave();
  }

  void toggleKoachLock(String ref) {
    if (!koach.locks.remove(ref)) koach.locks.add(ref);
    _koachSave();
  }

  // ------------------------------------------------------------ annotations
  KoachAnnotation? koachAnnotation(Exercise e) => koachProgram.of(e.id);

  /// Série de travail d'un des 4 mouvements principaux (D8, D24).
  bool koachStrength(Exercise e) =>
      koachAnnotation(e)?.cat == 'strength' && e.main;

  /// RIR d'une série : échelle Koach, sinon texte libre (échelle figée).
  double? koachRir(SetEntry s) =>
      s.effort ??
      ke.parseLegacyEffort(
        s.rir,
        koach.legacyScale ?? (settings.rpe ? 'rpe' : 'rir'),
      );

  /// D8 : difficulté obligatoire sur la série 1 et la dernière série.
  bool koachEffortRequired(Exercise e, ExerciseLog log, int index) =>
      koachOn &&
      koachStrength(e) &&
      (index == 0 || index == log.sets.length - 1);

  SetCheck _koachBeforeCheck(Exercise e, ExerciseLog log, int index) {
    final s = log.sets[index];
    if (s.effort == null) {
      // Mode avancé : RIR ou RPE saisi à la main (RIR = 10 − RPE).
      final v = ke.parseLegacyEffort(s.rir, settings.rpe ? 'rpe' : 'rir');
      if (v != null) s.effort = v;
    }
    if (s.effort == null && koachEffortRequired(e, log, index)) {
      return const SetCheck.error(
        SetField.effort,
        'Indique la difficulté de la série (Échec, Très dur, Dur, Soutenu, '
        'Modéré ou Facile) pour la valider.',
      );
    }
    return const SetCheck.ok();
  }

  void setEffort(ExerciseLog log, int index, double? rir) {
    log.sets[index].effort = rir;
    saveLogs(affectsProgression: false);
  }

  /// Champ RIR/RPE modifié à la main (mode avancé) : la difficulté suit la
  /// dernière saisie explicite (RIR = 10 − RPE). Koach désactivé : rien.
  void koachRirEdited(SetEntry s) {
    if (!koachOn) return;
    s.effort = ke.parseLegacyEffort(s.rir, settings.rpe ? 'rpe' : 'rir');
  }

  /// « Dur · encore 2 » ; « Dur · RIR 2,5 » ; null sans difficulté lisible.
  String? koachEffortLabel(SetEntry s) {
    final r = koachRir(s);
    if (r == null) return null;
    final level = ke.effortScale[math.min(5, math.max(0, r.floor()))];
    if (r != r.roundToDouble()) return '${level.label} · RIR ${koachKg(r)}';
    return '${level.label} · ${level.more}';
  }

  /// Prescription datée conservée au journal (KT-029) : charge et séries
  /// affichées, adaptations de la semaine comprises.
  String koachPrescription(Exercise e, int week) {
    final load = loadLabel(e, week: week).replaceAll('\u00A0', ' ');
    return [
      if (load != '—') load,
      setsLabel(e),
      for (final ad in koachAdaptationsFor(week, e))
        ad.kind == 'deload'
            ? 'décharge anticipée'
            : ad.delta > 0
            ? '+1 série'
            : '−1 série',
    ].where((p) => p.trim().isNotEmpty).join(' · ');
  }

  /// D11 : la série reste au journal (validée), hors estimation.
  void toggleExcluded(ExerciseLog log, int index) {
    final s = log.sets[index];
    s.excluded = !s.excluded;
    saveLogs(affectsProgression: false);
  }

  // ------------------------------------------------------------ poids (D12)
  double? get koachBodyweightNow => ke.bodyweightAt(
    [for (final w in koach.weighIns) w.toJson()],
    ke.dayOf(ke.parseDt(ke.civilIso(storeClock()))!),
    values['B4'],
  );

  /// Pesée datée ; la plus récente devient le poids de corps des charges.
  void addWeighIn(DateTime date, double kg) {
    if (!kg.isFinite || kg < 20 || kg > 400) return;
    final day = ke.civilIso(date);
    koach.weighIns
      ..removeWhere((w) => w.date == day)
      ..add(WeighIn(day, kg))
      ..sort((a, b) => a.date.compareTo(b.date));
    if (koach.weighIns.last.date == day) {
      values['B4'] = kg;
      refStatus['B4'] = 'set';
      pilotageEpoch++;
    }
    _koachSave();
  }

  void removeWeighIn(String date) {
    koach.weighIns.removeWhere((w) => w.date == date);
    _koachSave();
  }

  /// Rappel de pesée hebdomadaire (dans l'application, jamais notifié).
  bool get koachWeighInDue {
    if (!koachOn) return false;
    if (koach.weighIns.isEmpty) return true;
    final last = ke.parseDt(koach.weighIns.last.date)!;
    final today = ke.parseDt(ke.civilIso(storeClock()))!;
    return ke.dayOf(today) - ke.dayOf(last) >= 7;
  }

  /// D33 : saisie manuelle d'une valeur de pilotage (regroupée sur 30 s :
  /// « 7 », « 72 », « 72,5 » = une seule mesure). Poids du corps = pesée.
  void _koachRecordManual(String ref, double v) {
    final now = storeClock();
    if (ref == 'B4') {
      final day = ke.civilIso(now);
      koach.weighIns
        ..removeWhere((w) => w.date == day)
        ..add(WeighIn(day, v))
        ..sort((a, b) => a.date.compareTo(b.date));
      return;
    }
    final at = ke.wallIso(now);
    if (koach.history.isNotEmpty) {
      final last = koach.history.last;
      final t = ke.parseDt(last.at);
      if (last.ref == ref &&
          last.source == 'manual' &&
          t != null &&
          ke.parseDt(at)! - t <= 30) {
        koach.history.removeLast();
      }
    }
    koach.history.add(PilotageEvent(at, ref, v, 'manual'));
  }

  // ------------------------------------------------------ entrées du moteur
  Map<String, dynamic> _koachLift(String movement) {
    final eq = koach.equipmentSettings;
    for (final l in program.pilotage.mainLifts) {
      if (l.key != movement) continue;
      final body = l.unit.contains('lest');
      return {
        'key': l.key,
        'ref': l.ref,
        'bodyweight': body,
        'k': koachProgram.kPrior[l.key] ?? 22.4,
        'grid':
            ((eq[body ? 'plate' : 'barbell'] as Map)['step'] as num).toDouble(),
      };
    }
    throw ArgumentError(movement);
  }

  int? _koachPlanned(Exercise e, int n) {
    if (e.sets.type != 'text') return null;
    int? best;
    for (final v in plannedReps(e, logSpec(e), math.max(1, n))) {
      if (v != null && (best == null || v < best)) best = v;
    }
    return best;
  }

  /// Entrée normalisée du moteur (même format que la référence Python) :
  /// séances du programme terminées seulement (D2, D32). [withWeeks] :
  /// structure du programme (propositions D28 seulement).
  Map<String, dynamic> koachInput({String? exclude, bool withWeeks = false}) {
    final now = storeClock();
    final eq = koach.equipmentSettings;
    final sessions = <Map<String, dynamic>>[];
    for (final entry in logs.entries) {
      final m = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(entry.key);
      if (m == null || entry.key == exclude) continue;
      final n = int.parse(m[1]!), j = int.parse(m[2]!);
      if (n < 1 || n > program.weeks.length) continue;
      final log = entry.value;
      if (!log.done) continue;
      final day = program.week(n).day(j);
      if (day == null) continue;
      final exercises = <Map<String, dynamic>>[];
      for (final e in day.exercises) {
        final a = koachProgram.of(e.id);
        final el = log.ex[e.id];
        if (a == null || a.cat == null || el == null) continue;
        final spec = logSpec(e);
        exercises.add({
          'id': e.id,
          'cat': a.cat,
          'ref': a.ref,
          'restSec': e.restSec,
          'rirTarget': a.rirTarget,
          'plannedReps': _koachPlanned(e, el.sets.length),
          'cluster': spec.cluster,
          'emom': spec.kind == 'emom',
          'sets': [
            for (final s in el.sets)
              {
                'kg': parseLoadKg(s.kg),
                'reps': parseWholeNumber(s.reps),
                'rir': koachRir(s),
                'excluded': s.excluded,
                'done': s.done,
                'at': s.completedAt,
              },
          ],
        });
      }
      sessions.add({
        'key': entry.key,
        'week': n,
        'day': j,
        'done': true,
        'finishedAt': log.finishedAt,
        'exercises': exercises,
      });
    }
    final pain = <String, dynamic>{};
    final quest = <String, dynamic>{};
    koach.answers.forEach((k, a) {
      if (a.pain.isNotEmpty) pain[k] = Map<String, dynamic>.from(a.pain);
      if (a.sleep != null || a.form != null) {
        quest[k] = {
          if (a.sleep != null) 'sleep': a.sleep,
          if (a.form != null) 'form': a.form,
        };
      }
    });
    final objectives = <String, dynamic>{};
    for (final ref in [
      for (final l in program.pilotage.mainLifts) l.ref,
      for (final r in program.pilotage.repMax) r.ref,
    ]) {
      final levels = <String, dynamic>{};
      for (final level in const ['stage', 'final']) {
        final o = koachObjective(ref, level);
        if (o.target != null && o.date != null) {
          levels[level] = {'target': o.target, 'date': ke.civilIso(o.date!)};
        }
      }
      if (levels.isNotEmpty) objectives[ref] = levels;
    }
    return {
      'now': ke.wallIso(now),
      'lifts': [for (final l in program.pilotage.mainLifts) _koachLift(l.key)],
      'repmax': [
        for (final r in program.pilotage.repMax)
          {
            'ref': r.ref,
            if (r.name.toLowerCase().startsWith('dip')) 'dips': true,
          },
      ],
      'accessories': [
        for (final e in koachProgram.accessories.entries)
          {
            'ref': e.key,
            'equipment': e.value.equipment,
            'prevention': e.value.prevention,
          },
      ],
      'references': Map<String, dynamic>.from(values),
      'history': [for (final h in koach.history) h.toJson()],
      'weighIns': [for (final w in koach.weighIns) w.toJson()],
      'equipment': eq,
      'locks': koach.locks.toList(),
      'pain': pain,
      'questionnaires': quest,
      'painRelief': koach.painRelief.keys.toList(),
      'objectives': objectives,
      if (withWeeks)
        'weeks': [
          for (final w in program.weeks)
            {
              'n': w.n,
              'type': koachProgram.weekTypes[w.n] ?? 'normal',
              'totalSets': w.days.fold<int>(
                0,
                (s, d) =>
                    s + d.exercises.fold<int>(0, (t, e) => t + setCount(e)),
              ),
              'main': {
                for (final l in program.pilotage.mainLifts)
                  if (_mainExercise(w, l.key) != null)
                    l.key: _mainExercise(w, l.key),
              },
            },
        ],
      'sessions': sessions,
    };
  }

  String? _mainExercise(WeekPlan w, String movement) {
    for (final d in w.days) {
      for (final e in d.exercises) {
        final a = koachProgram.of(e.id);
        if (a?.cat == 'strength' && a?.movement == movement && e.main) {
          return e.id;
        }
      }
    }
    return null;
  }

  /// État de Koach recalculé depuis le journal (D31), cache incrémental
  /// identique au rejeu complet (test).
  ke.KoachState koachState() {
    final day = ke.civilIso(storeClock());
    final cached = _koachCache;
    if (cached != null &&
        _koachCacheRevision == _dataRevision &&
        _koachCacheDay == day) {
      return cached;
    }
    final state = ke.replayIncremental(koachInput(), cached);
    _koachCache = state;
    _koachCacheRevision = _dataRevision;
    _koachCacheDay = day;
    return state;
  }

  /// D29 : estimation trop incertaine (σ > 5 %) ou inexistante.
  bool koachUncertain(String movement) {
    final tr = koachState().tracks[movement];
    return tr == null || tr.sd > ke.koachParams['uncertain']! * tr.x;
  }

  // ----------------------------------------------- pendant la séance (D24)
  List<Map<String, dynamic>> _koachDoneSets(ExerciseLog log) => [
    for (final s in log.sets)
      if (s.done && !s.excluded && parseWholeNumber(s.reps) != null)
        {
          'kg': parseLoadKg(s.kg),
          'reps': parseWholeNumber(s.reps),
          'rir': koachRir(s),
        },
  ];

  /// D26 : dernière douleur notée > 3/10 sur ce mouvement.
  bool koachPainBlocks(String movement, {String? excludeSession}) {
    String? bestKey;
    DateTime? best;
    koach.answers.forEach((k, a) {
      if (k == excludeSession || !a.pain.containsKey(movement)) return;
      final t = DateTime.tryParse(logs[k]?.finishedAt ?? '') ?? DateTime(1970);
      if (best == null || t.isAfter(best!)) {
        best = t;
        bestKey = k;
      }
    });
    if (bestKey == null) return false;
    return (koach.answers[bestKey]!.pain[movement] ?? 0) > 3;
  }

  bool koachFatigueAccepted(String key) => koach.decisions.any(
    (d) =>
        d.kind == 'fatigue' &&
        d.status == 'accepted' &&
        d.detail['session'] == key,
  );

  /// Suggestion de charge pour les séries restantes, ou null.
  ke.KSuggestion? koachSuggestion(
    int week,
    int day,
    Exercise e,
    ExerciseLog log,
  ) {
    if (!koachOn || week < 1 || !koachStrength(e)) return null;
    final a = koachAnnotation(e)!;
    final key = sessionKey(week, day);
    final sets = _koachDoneSets(log);
    if (sets.isEmpty) return null;
    final refused = [
      for (final d in koach.decisions)
        if (d.kind == 'inSession' &&
            d.status == 'refused' &&
            d.detail['session'] == key &&
            d.detail['exercise'] == e.id)
          d.detail['direction'] as String,
    ];
    final lift = _koachLift(a.movement!);
    final sug = ke.inSession(
      ke.koachParams,
      lift,
      sets,
      a.rirTarget,
      _koachPlanned(e, log.sets.length),
      koachBodyweightNow,
      (lift['grid'] as num).toDouble(),
      {
        'locked': koach.locks.contains(a.ref),
        'deload': koachProgram.isDeload(week),
        'pain': koachPainBlocks(a.movement!, excludeSession: key),
        'fatigue': koachFatigueAccepted(key),
        'refused': refused,
      },
    );
    if (sug == null) return null;
    final id = '$key|${e.id}|${sets.length}|${sug.direction}';
    if (koach.decisions.any((d) => d.id == id)) return null;
    return sug;
  }

  /// Raison en une ligne (D30) : « +2,5 kg — série 1 à Soutenu, visé Dur ».
  String koachReason(Exercise e, ExerciseLog log, ke.KSuggestion sug) {
    final delta = sug.kg - sug.from;
    final amount = '${delta >= 0 ? '+' : '−'}${koachKg(delta.abs())} kg';
    final target = koachAnnotation(e)?.rirTarget;
    final first = _koachDoneSets(log).firstOrNull;
    final rir = (first?['rir'] as num?)?.toDouble();
    return switch (sug.reason) {
      'easy1' || 'easy2' when rir != null && target != null =>
        '$amount — série 1 à ${ke.effortName(rir)}, visé ${ke.effortName(target)}',
      'twoHard' => '$amount — deux séries très dures de suite',
      'missed' => '$amount — série ratée',
      'missed2' => '$amount — série ratée de 2 reps ou plus',
      _ => amount,
    };
  }

  void applyKoachSuggestion(
    int week,
    int day,
    Exercise e,
    ExerciseLog log,
    ke.KSuggestion sug,
  ) {
    final key = sessionKey(week, day);
    final count = _koachDoneSets(log).length;
    final reason = koachReason(e, log, sug);
    final text = _kgText(sug.kg);
    for (final s in log.sets) {
      if (!s.done) s.kg = text;
    }
    log.koach = 'Koach : $reason (appliqué)';
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        '$key|${e.id}|$count|${sug.direction}',
        'inSession',
        'accepted',
        {
          'session': key,
          'exercise': e.id,
          'from': sug.from,
          'to': sug.kg,
          'direction': sug.direction,
          'reason': sug.reason,
        },
      ),
    );
    saveLogs(affectsProgression: false);
  }

  /// D7 : refus enregistré, non reproposé dans la séance (même sens).
  void refuseKoachSuggestion(
    int week,
    int day,
    Exercise e,
    ExerciseLog log,
    ke.KSuggestion sug,
  ) {
    final key = sessionKey(week, day);
    final count = _koachDoneSets(log).length;
    log.koach = 'Koach : ${koachReason(e, log, sug)} (charge gardée)';
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        '$key|${e.id}|$count|${sug.direction}',
        'inSession',
        'refused',
        {
          'session': key,
          'exercise': e.id,
          'from': sug.from,
          'to': sug.kg,
          'direction': sug.direction,
          'reason': sug.reason,
        },
      ),
    );
    saveLogs(affectsProgression: false);
  }

  // ------------------------------------------------ jour de fatigue (D25)
  /// Réduction de volume proposée pour la séance (0 = rien à proposer).
  double koachFatigueLevel(int week, int day, List<Exercise> exercises) {
    if (!koachOn || week < 1) return 0;
    final key = sessionKey(week, day);
    if (koach.decisions.any(
      (d) => d.kind == 'fatigue' && d.detail['session'] == key,
    )) {
      return 0;
    }
    final a = koach.answers[key];
    var level = ke.fatigueLevel(
      ke.koachParams,
      null,
      null,
      null,
      null,
      0,
      22.4,
      sleep: a?.sleep,
      form: a?.form?.toDouble(),
    );
    final state = koachState();
    for (final e in exercises) {
      if (!koachStrength(e)) continue;
      final log = logs[key]?.ex[e.id];
      if (log == null) continue;
      SetEntry? first;
      for (final s in log.sets) {
        if (s.done && !s.excluded) {
          first = s;
          break;
        }
      }
      if (first == null) continue;
      final ann = koachAnnotation(e)!;
      final tr = state.tracks[ann.movement];
      final reps = parseWholeNumber(first.reps);
      if (tr == null || reps == null) break;
      final lift = _koachLift(ann.movement!);
      final kg = parseLoadKg(first.kg);
      final bw = koachBodyweightNow;
      final double? mass =
          lift['bodyweight'] == true
              ? (bw == null ? null : bw + (kg ?? 0))
              : kg;
      final planned = _koachPlanned(e, log.sets.length);
      level = math.max(
        level,
        ke.fatigueLevel(
          ke.koachParams,
          tr.x,
          mass,
          reps,
          koachRir(first),
          state.bias.b,
          tr.k,
          failed: planned != null && reps < planned,
        ),
      );
      break;
    }
    return level;
  }

  /// Volume réduit sur les séries non validées restantes ; charges
  /// maintenues ; hausses D24 coupées pour la journée.
  void acceptKoachFatigue(
    int week,
    int day,
    List<Exercise> exercises,
    double level,
  ) {
    final key = sessionKey(week, day);
    for (final e in exercises) {
      final log = exLog(week, day, e);
      final target = math.max(1, (log.sets.length * (1 - level)).round());
      while (log.sets.length > target && !log.sets.last.done) {
        log.sets.removeLast();
      }
    }
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        '$key|fatigue',
        'fatigue',
        'accepted',
        {'session': key, 'level': level},
      ),
    );
    saveLogs(immediate: true);
  }

  void refuseKoachFatigue(int week, int day, double level) {
    final key = sessionKey(week, day);
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        '$key|fatigue',
        'fatigue',
        'refused',
        {'session': key, 'level': level},
      ),
    );
    _koachSave();
  }

  // ------------------------------------------------ questionnaires (D14)
  SessionAnswers koachAnswers(String key) =>
      koach.answers.putIfAbsent(key, SessionAnswers.new);

  bool koachAnswered(String key) {
    final a = koach.answers[key];
    return a != null && (a.sleep != null || a.form != null);
  }

  /// Questionnaire d'avant séance proposé : actif, séance du programme pas
  /// encore commencée, ni répondu ni passé.
  bool koachAskBefore(int week, int day) {
    if (!koachQuestionnaires || week < 1) return false;
    final key = sessionKey(week, day);
    final a = koach.answers[key];
    if (koachSkipped.contains(key) || (a?.sleep != null && a?.form != null)) {
      return false;
    }
    return !(logs[key]?.ex.values.any((e) => e.sets.any((s) => s.done)) ??
        false);
  }

  void koachSkipQuestions(String key) {
    koachSkipped.add(key);
    notifyListeners();
  }

  void setKoachAnswers(String key, {double? sleep, int? form}) {
    final a = koachAnswers(key);
    a.sleep = sleep;
    a.form = form;
    if (a.isEmpty) koach.answers.remove(key);
    _koachSave();
  }

  void setKoachPain(String key, String movement, int? value) {
    final a = koachAnswers(key);
    if (value == null) {
      a.pain.remove(movement);
    } else {
      a.pain[movement] = value.clamp(0, 10);
    }
    if (a.isEmpty) koach.answers.remove(key);
    _koachSave();
  }

  /// Mouvements principaux réalisés dans une séance (questionnaire douleur).
  List<String> koachMovementsDone(int week, int day) {
    final log = logs[sessionKey(week, day)];
    final plan =
        week >= 1 && week <= program.weeks.length
            ? program.week(week).day(day)
            : null;
    if (log == null || plan == null) return const [];
    final out = <String>[];
    for (final e in plan.exercises) {
      final a = koachAnnotation(e);
      final m = a?.movement;
      if (m == null || out.contains(m)) continue;
      if ((a!.cat == 'strength' || a.cat == 'test1rm') &&
          (log.ex[e.id]?.sets.any((s) => s.done) ?? false)) {
        out.add(m);
      }
    }
    return out;
  }

  // -------------------------------------------------------- bilan (D5 b)
  /// Propositions en attente pour une séance terminée (sans décision).
  List<Map<String, dynamic>> koachProposals(String key) {
    if (!koachOn || !(logs[key]?.done ?? false)) return const [];
    final out = <Map<String, dynamic>>[];
    for (final p in ke.proposals(koachInput(), koachState(), key)) {
      if (koach.decisions.any((d) => d.id == p['id'])) continue;
      out.add(p);
    }
    for (final m in koach.painRelief.keys) {
      final v = koach.answers[key]?.pain[m];
      final id = '$key|painEnd|$m';
      if (v != null && v <= 3 && !koach.decisions.any((d) => d.id == id)) {
        out.add({
          'id': id,
          'kind': 'painEnd',
          'movement': m,
          'source': 'koach',
          'reason': 'painEnd',
        });
      }
    }
    return out;
  }

  /// Dernière séance du programme terminée (propositions retrouvables).
  String? get koachLastSession {
    String? best;
    DateTime? at;
    for (final e in logs.entries) {
      if (!RegExp(r'^S([1-9]\d*)-J\d+$').hasMatch(e.key) || !e.value.done) {
        continue;
      }
      final t = DateTime.tryParse(e.value.finishedAt ?? '');
      if (t != null && (at == null || t.isAfter(at))) {
        at = t;
        best = e.key;
      }
    }
    return best;
  }

  void acceptKoachProposal(Map<String, dynamic> p) {
    final at = ke.wallIso(storeClock());
    final kind = p['kind'] as String;
    if (kind == 'value') {
      final ref = p['ref'] as String;
      final to = (p['to'] as num).toDouble();
      if (!referenceRefs.contains(ref) || !to.isFinite || to < 0) return;
      values[ref] = to;
      refStatus[ref] = 'set';
      pilotageEpoch++;
      koach.history.add(
        PilotageEvent(at, ref, to, p['source'] == 'test' ? 'test' : 'koach'),
      );
    } else if (kind == 'pain') {
      koach.painRelief[p['movement'] as String] = at;
    } else if (kind == 'painEnd') {
      koach.painRelief.remove(p['movement'] as String);
    }
    koach.decisions.add(
      KoachDecision(at, p['id'] as String, kind, 'accepted', _detail(p)),
    );
    _koachSave();
  }

  void refuseKoachProposal(Map<String, dynamic> p) {
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        p['id'] as String,
        p['kind'] as String,
        'refused',
        _detail(p),
      ),
    );
    _koachSave();
  }

  Map<String, dynamic> _detail(Map<String, dynamic> p) => {
    for (final k in const ['ref', 'from', 'to', 'source', 'movement', 'cut'])
      if (p[k] != null) k: p[k],
  };

  /// Libellé d'une proposition : « Traction lestée (1RM) : 32,5 → 35 kg ».
  String koachProposalText(Map<String, dynamic> p) {
    final kind = p['kind'];
    if (kind == 'pain') {
      return '${koachMovementName(p['movement'] as String)} : allègement de '
          '20 % des charges et isométries 5 × 30-45 s (règle 6).';
    }
    if (kind == 'painEnd') {
      return '${koachMovementName(p['movement'] as String)} : reprendre les '
          'charges normales (douleur redescendue).';
    }
    final ref = p['ref'] as String;
    final unit =
        program.pilotage.repMax.any((r) => r.ref == ref) ? 'reps' : 'kg';
    final from = koachKg((p['from'] as num).toDouble());
    final to = koachKg((p['to'] as num).toDouble());
    return '${referenceLabel(ref)} : $from → $to $unit';
  }

  String koachProposalReason(Map<String, dynamic> p) => switch (p['reason']) {
    'test' => 'Résultat du test.',
    'up' => 'Tes séries montrent une marge : estimation en hausse.',
    'down' => 'Tes séries montrent moins de marge : estimation en baisse.',
    'accUp' =>
      'Toutes les séries au nombre visé avec de la marge : un cran de plus.',
    'accDown' => 'Nombre visé manqué deux séances de suite : un cran de moins.',
    'pain' =>
      'Douleur au-dessus de 3/10 deux séances de suite. Une douleur qui '
          'persiste relève d’un professionnel de santé.',
    'painEnd' => 'Douleur à 3/10 ou moins.',
    _ => '',
  };

  // ------------------------------------------------------ objectifs (D27)
  double? _programmeTarget(String ref) {
    for (final l in program.pilotage.mainLifts) {
      if (l.ref == ref) return l.target;
    }
    for (final r in program.pilotage.repMax) {
      if (r.ref == ref) return r.target;
    }
    return null;
  }

  /// Étape : « cible 12 mois » du programme, 12 mois après le départ ;
  /// objectif final : saisi par l'utilisateur. Tout est modifiable.
  ({double? target, DateTime? date}) koachObjective(String ref, String level) {
    final o = koach.objectives[ref]?[level];
    var target = o?.target;
    var date = o?.date == null ? null : parseCivilDate(o!.date);
    if (level == 'stage') {
      target ??= _programmeTarget(ref);
      final s = program.start;
      date ??= s == null ? null : DateTime(s.year + 1, s.month, s.day);
    }
    return (target: target, date: date);
  }

  void setKoachObjective(
    String ref,
    String level,
    double? target,
    DateTime? date,
  ) {
    final m = koach.objectives.putIfAbsent(ref, () => {});
    if (target == null && date == null) {
      m.remove(level);
    } else {
      m[level] = Objective(target, date == null ? null : ke.civilIso(date));
    }
    if (m.isEmpty) koach.objectives.remove(ref);
    _koachSave();
  }

  Map<String, dynamic> koachObjectives() =>
      ke.objectives(koachInput(), koachState());

  // ------------------------------------------------------ structure (D28)
  /// Semaine du programme visée par les propositions : la suivante.
  int? get koachNextWeek {
    final s = program.start;
    if (s == null) return null;
    final w = program.weekFor(storeClock()) + 1;
    return w > program.weeks.length ? null : w;
  }

  List<Map<String, dynamic>> koachStructureProposals() {
    final week = koachNextWeek;
    if (!koachOn || !koach.structure || week == null) return const [];
    return [
      for (final p in ke.structure(
        koachInput(withWeeks: true),
        koachState(),
        week,
      ))
        if (!koach.decisions.any((d) => d.id == p['id'])) p,
    ];
  }

  void acceptKoachStructure(Map<String, dynamic> p) {
    final at = ke.wallIso(storeClock());
    koach.adaptations.add(
      Adaptation(
        id: p['id'] as String,
        at: at,
        week: p['week'] as int,
        kind: p['kind'] as String,
        movement: p['movement'] as String,
        exercise: p['exercise'] as String?,
        delta: (p['delta'] as int?) ?? 0,
        sets: ((p['sets'] as num?) ?? 1).toDouble(),
        load: ((p['load'] as num?) ?? 0).toDouble(),
      ),
    );
    koach.decisions.add(
      KoachDecision(at, p['id'] as String, 'structure', 'accepted', {
        'week': p['week'],
        'kind': p['kind'],
        'movement': p['movement'],
      }),
    );
    _koachSave();
  }

  void refuseKoachStructure(Map<String, dynamic> p) {
    koach.decisions.add(
      KoachDecision(
        ke.wallIso(storeClock()),
        p['id'] as String,
        'structure',
        'refused',
        {'week': p['week'], 'kind': p['kind'], 'movement': p['movement']},
      ),
    );
    _koachSave();
  }

  /// Annule une adaptation (le programme d'origine n'est jamais réécrit).
  void revertKoachAdaptation(String id) {
    for (final a in koach.adaptations) {
      if (a.id == id && a.active) {
        a.status = 'reverted';
        a.revertedAt = ke.wallIso(storeClock());
      }
    }
    _koachSave();
  }

  Iterable<Adaptation> _koachAdaptations(int week) => koach.adaptations.where(
    (a) => a.active && a.week == week && koachOn && koach.structure,
  );

  /// Nombre de séries avec les adaptations actives de la semaine.
  int koachSetCount(int week, Exercise e) {
    var n = setCount(e);
    final a = koachAnnotation(e);
    for (final ad in _koachAdaptations(week)) {
      if (ad.kind == 'sets' && ad.exercise == e.id) {
        n = math.max(1, n + ad.delta);
      } else if (ad.kind == 'deload' && a?.cat == 'strength' && e.main) {
        n = math.max(1, (n * ad.sets).round());
      }
    }
    return n;
  }

  /// Adaptation(s) de la semaine concernant cet exercice (affichage).
  List<Adaptation> koachAdaptationsFor(int week, Exercise e) {
    final a = koachAnnotation(e);
    return [
      for (final ad in _koachAdaptations(week))
        if ((ad.kind == 'sets' && ad.exercise == e.id) ||
            (ad.kind == 'deload' && a?.cat == 'strength' && e.main))
          ad,
    ];
  }

  // -------------------------------------------------- charges avec Koach
  double _koachFactor(int? week, Exercise e) {
    var f = 1.0;
    final a = koachAnnotation(e);
    if (a?.cat != 'strength' || !e.main) return f;
    final relief = koach.painRelief.containsKey(a!.movement);
    if (relief) f *= 1 - ke.koachParams['pain_cut']!;
    if (week != null) {
      for (final ad in _koachAdaptations(week)) {
        if (ad.kind == 'deload') f *= 1 - ad.load;
      }
    }
    return f;
  }

  /// Charge prescrite avec Koach : formules du programme, arrondies à la
  /// grille du matériel (D23), allègement douleur (D26) et décharge
  /// anticipée (D28) éventuels.
  double? koachLoadFor(Exercise e, {int? week}) {
    final s = e.load;
    final eq = koach.equipmentSettings;
    final f = _koachFactor(week, e);
    switch (s.type) {
      case 'fixed':
        return s.kg;
      case 'system':
        final pdc = values['B4']!;
        final rm = values[s.ref!] ?? 0;
        final lest = ((pdc + rm) * s.pct! - pdc) * f;
        final g = ((eq['plate'] as Map)['step'] as num).toDouble();
        final r = f < 1 ? ke.floorGrid(lest, g) : ke.nearGrid(lest, g);
        return r < 0 ? 0.0 : r;
      case 'barbell':
        final bar = (values[s.ref ?? 'B11'] ?? 0) * s.pct! * f;
        final g = ((eq['barbell'] as Map)['step'] as num).toDouble();
        return f < 1 ? ke.floorGrid(bar, g) : ke.nearGrid(bar, g);
      case 'acc':
        final ref = values[s.ref!] ?? 0;
        final rr = refReps[s.ref!] ?? 10;
        final raw = ref * (1 + (rr + 2) / 30) / (1 + (s.dayReps! + 2) / 30);
        final kind = koachProgram.accessories[s.ref!]?.equipment;
        if (kind == null) return _round(raw, s.step!);
        return ke.gridRound(raw, kind, eq);
      default:
        return null;
    }
  }

  /// Unité native du matériel (poulies en livres : D23).
  bool koachNativeLb(Exercise e) {
    if (e.load.type != 'acc') return false;
    final kind = koachProgram.accessories[e.load.ref]?.equipment;
    if (kind == null) return false;
    return (koach.equipmentSettings[kind] as Map)['unit'] == 'lb';
  }
}
