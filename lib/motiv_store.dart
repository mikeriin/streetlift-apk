// L12 (KT-065 à KT-071) — motivation et progression visible branchées sur
// le store : niveau de détail, victoires, chaînes de progression, étapes
// réelles et célébrations (vues une seule fois), ton de Koach, bilans
// hebdomadaire et de fin de cycle, parcours d'habitude et séance de 10
// minutes, contenu de l'image de partage.
// Règles pures : lib/motivation.dart. Contrat : docs/CONTRAT_L12.md.
part of 'store.dart';

/// Record daté (étape réelle) avec son libellé.
class MotivRecord {
  final Milestone milestone;
  final String exercise, label;
  const MotivRecord(this.milestone, this.exercise, this.label);
}

/// Séance « 10 minutes, ça compte » (séance perso créée à la demande).
const kMinimalSessionName = '10 minutes, ça compte';

/// Premières fois marquantes (première pratique d'une étape de chaîne).
const kFirstTimes = <String, String>{
  'pompes': 'Première pompe complète !',
  'traction-pronation': 'Première traction !',
  'dips': 'Premier dip aux barres !',
  'pistol-squat': 'Premier pistol squat !',
  'muscle-up-kipping': 'Premier muscle-up !',
  'muscle-up-strict': 'Premier muscle-up strict !',
  'l-sit': 'Premier L-sit !',
  'atr-equilibre': 'Premier équilibre sur les mains !',
};

extension MotivStore on AppStore {
  // ------------------------------------------------------------ outils
  int get _motivToday => dayIndex(storeClock());

  void _motivSave() {
    _motivCache.clear();
    _motivCacheRev = '';
    _persist();
    notifyListeners();
  }

  /// Valeur mise en cache jusqu'à la prochaine modification des données.
  T _motivCached<T>(String key, T Function() compute) {
    final rev =
        '$_dataRevision|$_motivToday|${identityHashCode(program)}|'
        '${identityHashCode(ChainBook.loaded)}';
    if (_motivCacheRev != rev) {
      _motivCache.clear();
      _motivCacheRev = rev;
    }
    if (_motivCache.containsKey(key)) return _motivCache[key] as T;
    final value = compute();
    _motivCache[key] = value;
    return value;
  }

  // -------------------------------------------- niveau et ton (KT-065, 068)

  /// Niveau global (0 débutant … 4 expert), identique à L11.
  int get motivLevel => adaptLevel;

  DetailLevel get motivDetail =>
      detailLevelFor(motivLevel, showAll: motiv.showAll);

  void setShowAllStats(bool on) {
    if (motiv.showAll == on) return;
    motiv.showAll = on;
    _motivSave();
  }

  void setHideBody(bool on) {
    if (motiv.hideBody == on) return;
    motiv.hideBody = on;
    _motivSave();
  }

  void setHabitOff(bool off) {
    if (motiv.habitOff == off) return;
    motiv.habitOff = off;
    _adaptCache.clear();
    _motivSave();
  }

  /// Ton de Koach : profil (choisi, ou par défaut selon le niveau en L8),
  /// sinon choix sans profil, sinon défaut selon le niveau.
  String get koachTone {
    final t = profile?.stringValue('tone');
    if (t != null && kToneIds.contains(t)) return t;
    return motiv.tone ?? defaultToneFor(motivLevel);
  }

  void setKoachTone(String tone) {
    if (!kToneIds.contains(tone) || tone == koachTone) return;
    final p = profile;
    if (p != null) {
      final next = p.copy();
      next.setField('tone', tone, profileAt(storeClock()));
      ProfileStore(this).saveProfile(next);
    } else {
      motiv.tone = tone;
    }
    _motivSave();
  }

  /// Message de Koach au ton choisi (sécurité : toujours neutre).
  String motivLine(String context) => koachLine(context, koachTone, motivLevel);

  // ------------------------------------------------ performances du journal

  static final RegExp _leadingInt = RegExp(r'^\s*(\d+)');

  /// Séances réalisées par exercice du pack (séries validées, non
  /// écartées) : jour civil, valeur (répétitions ou secondes) et lest.
  Map<String, List<PerfSession>> motivPerf() => _motivCached('perf', () {
    final out = <String, List<PerfSession>>{};
    for (final l in logs.entries) {
      int? day;
      for (final x in l.value.ex.entries) {
        final name = l.value.exerciseNames[x.key];
        if (name == null || name.isEmpty) continue;
        final id = content.idFor(name);
        if (id == null) continue;
        final sets = <PerfSet>[];
        for (final s in x.value.sets) {
          if (!s.done || s.excluded) continue;
          final m = _leadingInt.firstMatch(s.reps);
          final v = m == null ? null : int.tryParse(m.group(1)!);
          if (v == null || v <= 0) continue;
          final kg = double.tryParse(s.kg.trim().replaceAll(',', '.')) ?? 0;
          sets.add((value: v, kg: kg));
        }
        if (sets.isEmpty) continue;
        day ??= adaptSessionDay(l.key);
        (out[id] ??= []).add((day: day, sets: sets));
      }
    }
    return out;
  });

  /// Nom affiché d'un exercice du pack.
  String motivStepName(String id) {
    final e = content.byId[id];
    return e == null ? id : (e.n.isNotEmpty ? e.n : e.nom);
  }

  // ------------------------------------------------------ chaînes (KT-066)

  /// Chaînes utiles à l'objectif du profil (mises en avant).
  List<String> get motivGoalChains {
    final p = profile;
    final goals = <String>[
      for (final k in const ['goalPrimary', 'goalSecondary'])
        if (p?.stringValue(k) != null) p!.stringValue(k)!,
    ];
    final items = <String>[];
    final ev = p?.value('eventGoal');
    if (ev is Map) {
      for (final i in (ev['items'] as List? ?? const [])) {
        if (i is Map && i['id'] is String) items.add(i['id'] as String);
      }
    }
    return chainsForGoals(goals, eventItems: items);
  }

  /// Avancement de toutes les chaînes du pack (vide si le pack n'est pas
  /// chargé).
  List<ChainProgress> motivChains() => _motivCached('chains', () {
    final book = ChainBook.loaded;
    if (book == null) return const <ChainProgress>[];
    final perf = motivPerf();
    final bw = ProfileStore(this).currentBodyweight;
    return [
      for (final c in book.chains) chainProgress(c, perf, bodyweight: bw),
    ];
  });

  // ------------------------------------------------- régularité (KT-067)

  Set<int> get _motivPlannedDays => _motivCached('planned', () {
    final out = <int>{};
    if (program.start == null) return out;
    for (final w in program.weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        out.add(dayIndex(program.dateFor(w.n, d.j)));
      }
    }
    return out;
  });

  int _mondayOf(int day) => day - ((day + 3) % 7);

  /// Parcours d'habitude actif pour le jour [day].
  bool _habitOn(int day) {
    final s = program.start;
    return habitActive(
      level: motivLevel,
      startDay: s == null ? null : dayIndex(s),
      today: day,
      disabled: motiv.habitOff,
    );
  }

  /// Régularité d'une semaine civile.
  WeekRegularity motivWeek(int monday) => weekRegularity(
    monday: monday,
    planned: _motivPlannedDays,
    training: adaptTrainingDays().toSet(),
    today: _motivToday,
    paused: _pausedDays,
    habit: _habitOn(monday) || _habitOn(monday + 6),
  );

  /// Semaines civiles depuis le départ du programme (ou la première séance)
  /// jusqu'à la semaine en cours (104 au plus).
  List<WeekRegularity> motivWeeks() => _motivCached('weeks', () {
    final today = _motivToday;
    final current = _mondayOf(today);
    final training = adaptTrainingDays();
    int? first;
    final s = program.start;
    if (s != null) first = dayIndex(s);
    if (training.isNotEmpty) {
      final t = training.reduce(math.min);
      first = first == null ? t : math.min(first, t);
    }
    if (first == null || first > today) return const <WeekRegularity>[];
    var monday = math.max(_mondayOf(first), current - 7 * 103);
    final out = <WeekRegularity>[];
    for (; monday <= current; monday += 7) {
      out.add(motivWeek(monday));
    }
    return out;
  });

  int get motivRegularStreak =>
      regularStreak(motivWeeks(), _mondayOf(_motivToday));

  WeekRegularity get motivThisWeek => motivWeek(_mondayOf(_motivToday));

  // ---------------------------------------------- étapes réelles (KT-067)

  static void _fold(ExerciseBests b, double kg, int reps) {
    if (reps <= 0) return;
    if (kg > 0) {
      b.weightedSets++;
      final e = e1rmOf(kg, reps);
      if (e > b.bestE1rm) {
        b.bestE1rm = e;
        b.bestKg = kg;
        b.bestKgReps = reps;
      }
    } else {
      b.bodyweightSets++;
      if (reps > b.bestReps) b.bestReps = reps;
    }
  }

  /// Records datés, dans l'ordre chronologique des séances (une étape par
  /// exercice et par semaine civile).
  List<MotivRecord> motivRecords() => _motivCached('records', () {
    final sessions =
        [
          for (final e in logs.entries)
            if (e.value.ex.values.any((x) => x.sets.any((s) => s.done)))
              (key: e.key, day: adaptSessionDay(e.key), log: e.value),
        ]..sort((a, b) {
          final c = a.day.compareTo(b.day);
          return c != 0 ? c : a.key.compareTo(b.key);
        });
    final bests = <String, ExerciseBests>{};
    final out = <String, MotivRecord>{};
    for (final s in sessions) {
      final hits = <String, RecordHit>{};
      for (final x in s.log.ex.entries) {
        final name = s.log.exerciseNames[x.key];
        if (name == null || name.isEmpty) continue;
        for (final set in x.value.sets) {
          if (!set.done || set.excluded) continue;
          final hit = recordFor(bests, name, set.kg, set.reps);
          if (hit == null) continue;
          final prev = hits[name];
          if (prev == null || hit.current > prev.current) hits[name] = hit;
        }
      }
      for (final x in s.log.ex.entries) {
        final name = s.log.exerciseNames[x.key];
        if (name == null || name.isEmpty) continue;
        final b = bests.putIfAbsent(normalizeText(name), ExerciseBests.new);
        for (final set in x.value.sets) {
          if (!set.done) continue;
          _fold(
            b,
            double.tryParse(set.kg.trim().replaceAll(',', '.')) ?? 0,
            int.tryParse(set.reps.trim()) ?? 0,
          );
        }
      }
      for (final h in hits.entries) {
        final week = dayString(dayOfIndex(_mondayOf(s.day)));
        final id = 'record:${normalizeText(h.key).replaceAll(' ', '-')}:$week';
        final safe = id.replaceAll(RegExp(r'[^\w:.\-~]'), '');
        out[safe] = MotivRecord(
          Milestone(
            safe.length > 120 ? safe.substring(0, 120) : safe,
            'record',
            'Record : ${h.key}',
            s.day,
          ),
          h.key,
          h.value.label,
        );
      }
    }
    return out.values.toList();
  });

  /// Toutes les étapes réelles, de la plus récente à la plus ancienne.
  List<Milestone> get motivMilestones => _motivCached('milestones', () {
    final today = _motivToday;
    final out = <String, Milestone>{};
    void add(Milestone m) {
      final prev = out[m.id];
      if (prev == null || m.day < prev.day) out[m.id] = m;
    }

    for (final r in motivRecords()) {
      add(r.milestone);
    }
    for (final c in motivChains()) {
      for (final e in c.met.entries) {
        final step = c.chain.steps[e.key];
        // Dernière étape (sans critère) : atteinte dès sa pratique.
        add(
          Milestone(
            'chain:${step.id}',
            'chain',
            'Étape franchie : ${motivStepName(step.id)}',
            e.value,
          ),
        );
      }
      final last = c.chain.steps.length - 1;
      final lastDay = c.practiced[last];
      if (last >= 0 &&
          lastDay != null &&
          c.chain.steps[last].threshold == null) {
        final step = c.chain.steps[last];
        add(
          Milestone(
            'chain:${step.id}',
            'chain',
            'Étape atteinte : ${motivStepName(step.id)}',
            lastDay,
          ),
        );
      }
    }
    for (final cy in motivCycles()) {
      final last = dayIndex(program.dateFor(cy.lastWeek, 7));
      final first = dayIndex(program.dateFor(cy.firstWeek, 1));
      if (last >= today) continue;
      final trained = adaptTrainingDays().any((d) => d >= first && d <= last);
      if (!trained) continue;
      add(
        Milestone(
          'cycle:${cy.index}:${cy.firstWeek}',
          'cycle',
          'Cycle terminé : ${cy.label}',
          last + 1,
        ),
      );
    }
    for (final m in regularMilestones(motivWeeks(), today)) {
      add(m);
    }
    final list = out.values.where((m) => m.day <= today).toList()
      ..sort((a, b) {
        final c = b.day.compareTo(a.day);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    return list;
  });

  /// Étapes à célébrer (récentes, jamais vues).
  List<Milestone> get motivPending =>
      pendingMilestones(motivMilestones, motiv.seen, _motivToday);

  /// Célébration vue : chaque étape n'est célébrée qu'une fois. Le barème
  /// de récompenses (proposé, docs/CONTRAT_L12.md §5) ne s'applique
  /// qu'après validation du propriétaire : [milestoneCredits] vaut 0 tant
  /// que [kMilestoneRewardsApproved] est faux, le registre des gains
  /// (KT-005) n'est pas modifié.
  void acknowledgeMilestones(Iterable<Milestone> list) {
    final today = dayString(dayOfIndex(_motivToday));
    var changed = false;
    for (final m in list) {
      if (motiv.seen.containsKey(m.id)) continue;
      motiv.seen[m.id] = today;
      changed = true;
    }
    if (!changed) return;
    if (motiv.seen.length > MotivData.maxSeen) {
      final keys = motiv.seen.keys.toList();
      for (final k in keys.take(keys.length - MotivData.maxSeen)) {
        motiv.seen.remove(k);
      }
    }
    _motivSave();
  }

  // ----------------------------------------------------- victoires (KT-065)

  /// Victoires concrètes (débutant et novice ; aussi en tête des autres
  /// niveaux).
  List<Victory> motivVictories() => _motivCached('victories', () {
    final today = _motivToday;
    final out = <Victory>[];
    // Progrès depuis le départ : meilleure série actuelle contre la
    // première séance, par exercice.
    final firsts = <String, (int, double)>{};
    final bestsNow = <String, (int, double)>{};
    final names = <String, String>{};
    final sessions = [
      for (final e in logs.entries) (day: adaptSessionDay(e.key), log: e.value),
    ]..sort((a, b) => a.day.compareTo(b.day));
    for (final s in sessions) {
      for (final x in s.log.ex.entries) {
        final name = s.log.exerciseNames[x.key];
        if (name == null || name.isEmpty) continue;
        final k = normalizeText(name);
        var reps = 0;
        var kg = 0.0;
        for (final set in x.value.sets) {
          if (!set.done || set.excluded) continue;
          final r = int.tryParse(set.reps.trim()) ?? 0;
          final w = double.tryParse(set.kg.trim().replaceAll(',', '.')) ?? 0;
          if (w > kg || (w == kg && r > reps)) {
            kg = w;
            reps = r;
          }
        }
        if (reps <= 0) continue;
        names[k] = name;
        if (!firsts.containsKey(k)) {
          firsts[k] = (reps, kg);
          bestsNow[k] = (reps, kg);
          continue;
        }
        final b = bestsNow[k]!;
        if (kg > b.$2 || (kg == b.$2 && reps > b.$1)) bestsNow[k] = (reps, kg);
      }
    }
    String? bestRep;
    var bestGain = 0;
    String? bestKgName;
    var bestKgGain = 0.0;
    for (final k in firsts.keys) {
      final f = firsts[k]!, b = bestsNow[k]!;
      if (f.$2 == 0 && b.$2 == 0 && b.$1 - f.$1 > bestGain) {
        bestGain = b.$1 - f.$1;
        bestRep = k;
      }
      if (f.$2 > 0 && b.$2 - f.$2 > bestKgGain) {
        bestKgGain = b.$2 - f.$2;
        bestKgName = k;
      }
    }
    if (bestRep != null) {
      out.add(
        Victory(
          'gain-reps',
          '+$bestGain répétitions en ${names[bestRep]!.toLowerCase()} depuis ton départ',
          1,
        ),
      );
    }
    if (bestKgName != null) {
      out.add(
        Victory(
          'gain-kg',
          '+${koachKg(bestKgGain)} kg en ${names[bestKgName]!.toLowerCase()} depuis ton départ',
          2,
        ),
      );
    }
    // Première fois la plus récente (une seule).
    String? firstId;
    var firstDay = -1;
    for (final c in motivChains()) {
      for (final e in c.practiced.entries) {
        final id = c.chain.steps[e.key].id;
        if (!kFirstTimes.containsKey(id)) continue;
        if (e.value > firstDay ||
            (e.value == firstDay && id.compareTo(firstId!) < 0)) {
          firstDay = e.value;
          firstId = id;
        }
      }
    }
    if (firstId != null) {
      out.add(
        Victory(
          'first:$firstId',
          kFirstTimes[firstId]!,
          today - firstDay <= 28 ? 0 : 3,
        ),
      );
    }
    final chainMs = [
      for (final m in motivMilestones)
        if (m.kind == 'chain') m,
    ];
    if (chainMs.isNotEmpty) {
      out.add(Victory('chain', chainMs.first.title, 1));
    }
    final streak = motivRegularStreak;
    if (streak > 0) {
      out.add(
        Victory(
          'regular',
          '$streak semaine${streak > 1 ? 's' : ''} régulière${streak > 1 ? 's' : ''}',
          2,
        ),
      );
    }
    final week = motivThisWeek;
    if (week.restRespected > 0) {
      out.add(
        const Victory(
          'rest',
          'Jours de repos respectés : ils comptent aussi.',
          5,
        ),
      );
    }
    final done = adaptTrainingDays().length;
    if (done > 0) {
      out.add(
        Victory('days', '$done jour${done > 1 ? 's' : ''} d’entraînement', 4),
      );
    } else {
      out.add(
        const Victory(
          'start',
          'Ta première séance sera ta première victoire.',
          9,
        ),
      );
    }
    return out;
  });

  /// Victoires affichées sur un écran (au plus 3 chiffres).
  List<Victory> get motivTopVictories => pickVictories(motivVictories());

  // ---------------------------------------------- estimations et poids

  /// Libellé d'un mouvement principal (pilotage) ou du nom d'exercice.
  String motivMovementName(String key) {
    for (final l in program.pilotage.mainLifts) {
      if (l.key == key) return l.name;
    }
    return key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
  }

  /// Poids du corps (facultatif, jamais jugé).
  double? get motivBodyweight => ProfileStore(this).currentBodyweight;

  // ------------------------------------------------ cycles et bilans

  List<ProgramCycle> motivCycles() => _motivCached('cycles', () {
    if (program.start == null) return const <ProgramCycle>[];
    return programCycles([
      for (final w in program.weeks) (w.n, w.blockKey, w.block),
    ]);
  });

  /// Bilan hebdomadaire de la semaine civile précédente (lundi → dimanche
  /// de la semaine qui suit), s'il n'a pas été lu.
  WeekReview? get motivWeekReview => _motivCached('weekReview', () {
    final today = _motivToday;
    final monday = reviewWeekMonday(today);
    if (motiv.reviews.containsKey('week:${dayString(dayOfIndex(monday))}')) {
      return null;
    }
    final w = motivWeek(monday);
    if (!w.counted && w.done == 0) return null;
    // Utilisateur actif : au moins un entraînement dans la semaine résumée
    // ou les 3 précédentes (sinon, les propositions de reprise de L11).
    if (!adaptTrainingDays().any((d) => d >= monday - 21 && d <= monday + 6)) {
      return null;
    }
    final ms = [
      for (final m in motivMilestones)
        if (m.day >= monday && m.day <= monday + 6) m,
    ];
    final victory = ms.isNotEmpty
        ? ms.first.title
        : w.regular
        ? 'Semaine régulière.'
        : w.done > 0
        ? '${w.done} séance${w.done > 1 ? 's' : ''} faite${w.done > 1 ? 's' : ''}.'
        : null;
    final nextPlanned = _motivPlannedDays
        .where((d) => d >= monday + 7 && d <= monday + 13)
        .length;
    final habit = _habitOn(monday + 7);
    final next = nextPlanned == 0
        ? 'Cap : repos ou séance libre, à ton rythme.'
        : habit
        ? 'Cap : ${math.min(2, nextPlanned)} séance${math.min(2, nextPlanned) > 1 ? 's' : ''} courte${math.min(2, nextPlanned) > 1 ? 's' : ''}.'
        : w.counted && !w.regular
        ? 'Cap : une première séance, même de 10 minutes.'
        : 'Cap : $nextPlanned séance${nextPlanned > 1 ? 's' : ''} prévue${nextPlanned > 1 ? 's' : ''}.';
    return WeekReview(monday, victory, adherenceLine(w), next);
  });

  void dismissWeekReview(int monday) {
    motiv.reviews['week:${dayString(dayOfIndex(monday))}'] = dayString(
      dayOfIndex(_motivToday),
    );
    _trimReviews();
    _motivSave();
  }

  void _trimReviews() {
    if (motiv.reviews.length <= MotivData.maxReviews) return;
    final keys = motiv.reviews.keys.toList();
    for (final k in keys.take(keys.length - MotivData.maxReviews)) {
      motiv.reviews.remove(k);
    }
  }

  /// Bilan de fin de cycle (visible du lendemain du dernier jour du cycle,
  /// 14 jours au plus), s'il n'a pas été lu.
  CycleReview? get motivCycleReview => _motivCached('cycleReview', () {
    final today = _motivToday;
    final cycles = motivCycles();
    for (var i = cycles.length - 1; i >= 0; i--) {
      final cy = cycles[i];
      final last = dayIndex(program.dateFor(cy.lastWeek, 7));
      if (!cycleReviewOpen(last, today)) continue;
      if (motiv.reviews.containsKey('cycle:${cy.index}:${cy.firstWeek}')) {
        return null;
      }
      final first = dayIndex(program.dateFor(cy.firstWeek, 1));
      if (!adaptTrainingDays().any((d) => d >= first && d <= last)) {
        return null;
      }
      return _buildCycleReview(
        cy,
        i + 1 < cycles.length ? cycles[i + 1] : null,
      );
    }
    return null;
  });

  CycleReview _buildCycleReview(ProgramCycle cy, ProgramCycle? next) {
    final estimates = adaptWeeklyEstimates();
    final changes = <String, double>{};
    for (final e in estimates.entries) {
      final c = cycleChange(e.value, cy.firstWeek, cy.lastWeek);
      if (c != null) changes[e.key] = c;
    }
    String pct(double v) =>
        '${v >= 0 ? '+' : '−'}${koachKg(double.parse(v.abs().toStringAsFixed(1)))} %';
    final sorted = changes.entries.toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });
    // Séances du cycle.
    final first = dayIndex(program.dateFor(cy.firstWeek, 1));
    final last = dayIndex(program.dateFor(cy.lastWeek, 7));
    final planned = _motivPlannedDays
        .where((d) => d >= first && d <= last)
        .length;
    final done = adaptTrainingDays()
        .where((d) => d >= first && d <= last)
        .length;
    final goal = goalById(profile?.stringValue('goalPrimary') ?? '')?.label;
    final progress = sorted.isEmpty
        ? '$done séance${done > 1 ? 's' : ''} faite${done > 1 ? 's' : ''} sur $planned prévue${planned > 1 ? 's' : ''}'
              '${goal == null ? '' : ' pour ton objectif « $goal »'}.'
        : '${motivMovementName(sorted.first.key)} : ${pct(sorted.first.value)} sur le cycle'
              '${goal == null ? '' : ' (objectif « $goal »)'}.';
    final strength = sorted.isNotEmpty && sorted.first.value > 0
        ? '${motivMovementName(sorted.first.key)}, en progrès.'
        : motivRegularStreak > 0
        ? 'Ta régularité : $motivRegularStreak semaine${motivRegularStreak > 1 ? 's' : ''} régulière${motivRegularStreak > 1 ? 's' : ''}.'
        : 'Tu as terminé le cycle.';
    final plateaus = adaptPlateaus;
    final work = plateaus.isNotEmpty
        ? '${motivMovementName(plateaus.first)} : palier, à relancer.'
        : sorted.length > 1 && sorted.last.value <= 0
        ? '${motivMovementName(sorted.last.key)} : à relancer.'
        : planned > 0 && done < regularTarget(planned)
        ? 'La régularité : vise tes séances prévues, même courtes.'
        : 'Garder la même régularité.';
    final nextText = next != null
        ? 'Cycle suivant : ${next.label}.'
        : 'Mon programme : génère la suite quand tu es prêt.';
    String? projection;
    if (KoachStore(this).koachOn) {
      final objs = KoachStore(this).koachObjectives();
      for (final l in program.pilotage.mainLifts) {
        final o = objs[l.ref] as Map?;
        final fin = ((o?['objectives'] as Map?)?['final'] as Map?)?['status'];
        if (fin is String && fin != 'none') {
          projection =
              'Objectif final ${l.name} : ${const {'reached': 'atteint', 'past': 'échéance passée', 'insufficient': 'données insuffisantes', 'late': 'en retard sur le rythme observé', 'ahead': 'en avance', 'onTrack': 'dans les temps'}[fin] ?? fin} (repère, pas une promesse).';
          break;
        }
        final slope = (o?['slope'] as num?)?.toDouble();
        if (slope != null && slope > 0 && projection == null) {
          projection =
              '${l.name} : +${koachKg(double.parse(slope.toStringAsFixed(2)))} kg par semaine au rythme observé (repère, pas une promesse).';
        }
      }
    }
    return CycleReview(
      cycle: cy,
      progress: progress,
      strength: strength,
      work: work,
      next: nextText,
      projection: projection,
    );
  }

  void dismissCycleReview(ProgramCycle cy) {
    motiv.reviews['cycle:${cy.index}:${cy.firstWeek}'] = dayString(
      dayOfIndex(_motivToday),
    );
    _trimReviews();
    _motivSave();
  }

  // ------------------------------------ parcours d'habitude (KT-071)

  /// Parcours d'habitude actif aujourd'hui.
  bool get motivHabitActive => _habitOn(_motivToday);

  /// Semaine du parcours (1 à 4).
  int get motivHabitWeek {
    final s = program.start;
    return s == null ? 1 : habitWeek(dayIndex(s), _motivToday);
  }

  /// Débutant ou novice : parcours proposé (réglage visible).
  bool get motivHabitEligible => motivLevel <= 1;

  int get motivHabitMinutes {
    final m = profile?.value('sessionMinutes');
    return habitMinutes(m is int ? m : null);
  }

  /// Durée visée d'une séance du programme pendant le parcours (null hors
  /// parcours).
  int? motivHabitMinutesFor(int week, int j) {
    if (program.start == null || week < 1) return null;
    final day = dayIndex(program.dateFor(week, j));
    return _habitOn(day) ? motivHabitMinutes : null;
  }

  /// Séance « 10 minutes, ça compte » : créée à la demande dans les
  /// séances perso (4 exercices sans matériel, 2 séries, repos 30 s),
  /// comptée pour la régularité comme toute séance.
  CustomSession ensureMinimalSession(GenCatalog c) {
    for (final s in customSessions) {
      if (s.name == kMinimalSessionName) return s;
    }
    final level = motivLevel;
    final items = <CustomExercise>[
      for (final e in maintenanceExercises(c, level).take(4))
        e.measure == 'temps'
            ? CustomExercise(
                name: e.name,
                mode: 'iso',
                p: {'series': 2, 'hold': level <= 1 ? 20 : 30},
                rest: 30,
              )
            : CustomExercise(
                name: e.name,
                mode: 'classic',
                p: {'series': 2, 'reps': level <= 1 ? 8 : 12},
                rest: 30,
              ),
    ];
    final s = CustomSession(
      id: newSessionId(),
      name: kMinimalSessionName,
      items: items,
    );
    upsertSession(s);
    return s;
  }

  // ------------------------------------------------ partage (KT-071)

  /// Contenu disponible pour l'image de partage. Poids seulement si connu
  /// (décoché par défaut) ; aucune donnée de santé.
  ShareData get motivShareData {
    final records = motivRecords().reversed.take(3);
    final chain = motivMilestones.where((m) => m.kind == 'chain').firstOrNull;
    final streak = motivRegularStreak;
    final bw = motivBodyweight;
    return ShareData(
      victories: [for (final v in motivTopVictories) v.text],
      records: [for (final r in records) '${r.exercise} : ${r.label}'],
      regularity: streak > 0
          ? '$streak semaine${streak > 1 ? 's' : ''} régulière${streak > 1 ? 's' : ''}'
          : null,
      chain: chain?.title,
      bodyweight: bw == null ? null : 'Poids de corps : ${koachKg(bw)} kg',
    );
  }
}
