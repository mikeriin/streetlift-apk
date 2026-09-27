// L10 (KT-050 à KT-057) — générateur de programme branché sur le store :
// instance persistée et exportée, génération au départ d'un nouvel
// utilisateur, régénération de la suite avec aperçu « ce qui change » et
// annulation pendant 7 jours, cycle suivant généré depuis le journal.
// Sans instance (installation antérieure), le programme embarqué reste
// exactement celui de 3.2.0 : modèle « Expert streetlifting » implicite.
// Contrat : docs/CONTRAT_L10.md.
part of 'store.dart';

/// Données du générateur, chargées une fois à la demande.
class ProgramAssets {
  final GenModels models;
  final GenCatalog catalog;
  const ProgramAssets(this.models, this.catalog);

  static Future<ProgramAssets>? _pending;
  static ProgramAssets? loaded;

  static Future<ProgramAssets> load([AssetBundle? bundle]) =>
      _pending ??= _load(bundle ?? rootBundle).catchError((Object e) {
        _pending = null;
        throw e;
      });

  static Future<ProgramAssets> _load(AssetBundle b) async {
    Future<Map<String, dynamic>> gz(String asset) async {
      final bytes = await b.load(asset);
      return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
          as Map<String, dynamic>;
    }

    final models = GenModels.fromJsonString(
      await b.loadString('assets/program_models.json'),
    );
    final catalog = GenCatalog.fromContent(
      index: await gz('assets/content/index.json.gz'),
      details: await gz('assets/content/details.json.gz'),
      progressions: await gz('assets/content/progressions.json.gz'),
    );
    return loaded = ProgramAssets(models, catalog);
  }
}

/// Proposition de programme : nouvelle instance et aperçu des changements,
/// appliquée seulement après validation (ou automatiquement en mode Guidé,
/// annulable 7 jours).
class ProgramProposal {
  final ProgramInstance instance;
  final ProgramDiff diff;
  final ({int week, int day}) from;
  final String reason;
  final DateTime start;
  const ProgramProposal(
    this.instance,
    this.diff,
    this.from,
    this.reason,
    this.start,
  );
}

extension ProgramStore on AppStore {
  DateTime get _programToday {
    final n = storeClock();
    return DateTime(n.year, n.month, n.day);
  }

  /// Un programme personnalisé est en place.
  bool get programGenerated => programInstance?.generated ?? false;

  /// Identifiant du modèle de périodisation en place.
  String get programModel =>
      programInstance?.summary['model'] as String? ?? 'expert_streetlifting';

  /// Résumé de la dernière génération (vide pour le modèle implicite).
  Map<String, dynamic> get programSummary =>
      programInstance?.summary ?? const {'model': 'expert_streetlifting'};

  /// Journal présent pour une journée du programme.
  bool _programLogged(int week, int day) {
    final l = logs[sessionKey(week, day)];
    return l != null && (l.done || l.ex.isNotEmpty);
  }

  bool get _programHasLogs {
    for (final k in logs.keys) {
      if (RegExp(r'^S\d+-J\d$').hasMatch(k) &&
          _programLogged(
            int.parse(k.substring(1, k.indexOf('-'))),
            int.parse(k.substring(k.indexOf('J') + 1)),
          )) {
        return true;
      }
    }
    return false;
  }

  // ------------------------------------------------------------ entrées

  /// Mesures du niveau (KT-051) : références de Pilotage, sinon repère du
  /// profil (tranche → répétitions, « estimé »), complétées par le
  /// calibrage.
  (Map<String, double>, Map<String, String>) _programMeasures(
    Map<String, double> calibrated,
  ) {
    final m = <String, double>{};
    final src = <String, String>{};
    final bands =
        (ProgramAssets.loaded?.models.levels['benchmarkBandReps'] as Map?) ??
        const {
          'pushups': [0, 1, 10, 25, 45],
          'pullups': [0, 1, 5, 12, 20],
        };
    final bench = profile?.benchmarks ?? const <String, int>{};
    void fromRef(String key, String ref, String bench0) {
      final v = values[ref];
      if (v != null) {
        m[key] = v;
        src[key] = refStatus[ref] == 'set' ? 'measured' : 'estimated';
      } else if (bench.containsKey(bench0)) {
        final list = bands[bench0] as List;
        final band = bench[bench0]!;
        final at =
            band < 0 ? 0 : (band >= list.length ? list.length - 1 : band);
        m[key] = (list[at] as num).toDouble();
        src[key] = 'estimated';
      }
    }

    fromRef('pushups', 'B19', 'pushups');
    fromRef('pullups', 'B17', 'pullups');
    final bw = values['B4'];
    if (bw != null && bw > 0) {
      final squat = values['B11'], pull = values['B8'], dip = values['B9'];
      if (squat != null) {
        m['squatRatio'] = squat / bw;
        src['squatRatio'] = 'measured';
      }
      if (pull != null) {
        m['pullLoadPct'] = pull / bw * 100;
        src['pullLoadPct'] = 'measured';
      }
      if (dip != null) {
        m['dipLoadPct'] = dip / bw * 100;
        src['dipLoadPct'] = 'measured';
      }
    }
    for (final e in calibrated.entries) {
      m[e.key] = e.value;
      src[e.key] = 'calibrated';
    }
    return (m, src);
  }

  /// Entrées du générateur depuis le profil (null sans profil ou sans
  /// départ).
  GenInputs? programInputs({
    DateTime? start,
    Map<String, String>? options,
    Map<String, double> calibrated = const {},
    Map<String, String> entries = const {},
    Map<String, int> volumeAdjust = const {},
    bool calibration = true,
  }) {
    final p = profile;
    final s = start ?? program.start;
    if (p == null || s == null) return null;
    final opts = options ?? programInstance?.options ?? const {};
    final places = <String, List<String>>{};
    final rawPlaces = p.value('places');
    if (rawPlaces is Map) {
      for (final e in rawPlaces.entries) {
        places['${e.key}'] = [for (final x in e.value as List) '$x'];
      }
    }
    if (places.isEmpty) places['home_none'] = const [];
    final dayPlace = <int, String>{};
    final rawDay = p.value('dayPlace');
    if (rawDay is Map) {
      for (final e in rawDay.entries) {
        final d = int.tryParse('${e.key}');
        if (d != null && places.containsKey('${e.value}')) {
          dayPlace[d] = '${e.value}';
        }
      }
    }
    final rawDays = p.value('days');
    var days = rawDays is List ? [for (final d in rawDays) d as int] : <int>[];
    if (days.isEmpty) days = const [1, 3, 5];
    final event = p.value('eventGoal');
    DateTime? eventDate;
    final items = <String>[];
    if (event is Map) {
      eventDate = parseCivil(event['date']);
      for (final it in (event['items'] as List? ?? const [])) {
        items.add('${(it as Map)['id']}');
      }
    }
    final pains = <String, int>{};
    if (p.health.consentGiven) {
      for (final i in p.health.injuries) {
        final joint = kZoneToJoint[i.zone];
        if (joint == null) continue;
        if (i.level > (pains[joint] ?? 0)) pains[joint] = i.level;
      }
    }
    final (measures, sources) = _programMeasures(calibrated);
    final refs = <String, double>{
      for (final r in const ['B4', 'B8', 'B9', 'B10', 'B11'])
        if (values[r] != null) r: values[r]!,
    };
    return GenInputs(
      start: DateTime(s.year, s.month, s.day),
      goalPrimary: p.stringValue('goalPrimary') ?? 'health',
      goalSecondary: p.stringValue('goalSecondary'),
      goalWeight: p.intValue('goalWeight') ?? 70,
      eventDate: eventDate,
      eventItems: items,
      weekdays: days,
      sessionMinutes: p.intValue('sessionMinutes') ?? 45,
      dayPlace: dayPlace,
      places: places,
      disliked: p.listValue('disliked'),
      liked: p.listValue('liked'),
      pains: pains,
      caution: ProfileStore(this).cautionActive,
      autonomy: p.stringValue('autonomy') ?? 'guided',
      measures: measures,
      measureSources: sources,
      references: refs,
      split: opts['split'] ?? 'auto',
      focus: opts['focus'] ?? '',
      entries: entries,
      volumeAdjust: volumeAdjust,
      calibration: calibration,
    );
  }

  /// Le profil a changé depuis la dernière génération (KT-057).
  bool get programProfileChanged {
    final inst = programInstance;
    if (inst == null || !inst.generated || inst.profileKey.isEmpty) {
      return false;
    }
    final now = programInputs();
    return now != null && now.profileKey != inst.profileKey;
  }

  /// Une génération personnalisée est possible (profil et départ).
  bool get programCanGenerate => profile != null;

  // ---------------------------------------------------------- génération

  List<Map<String, dynamic>> _currentWeeks() {
    final inst = programInstance;
    if (inst != null && inst.generated) return inst.weeks;
    return copyWeeks(_baseProgramJson['weeks'] as List);
  }

  /// Prépare une (ré)génération de la suite à partir d'aujourd'hui, sans
  /// rien modifier. [options] : répartition et mouvement ciblé.
  Future<ProgramProposal?> proposeProgram({
    String reason = 'user',
    Map<String, String>? options,
    DateTime? start,
  }) async {
    final assets = ProgramAssets.loaded ?? await ProgramAssets.load();
    final today = _programToday;
    final s = start ?? program.start ?? today;
    final current = programInstance;
    final opts = options ?? current?.options ?? const <String, String>{};
    final started = civilDayIndex(today) >= civilDayIndex(s);
    final from = started ? positionOf(s, today) : (week: 1, day: 1);
    final hasLogs = _programHasLogs;
    final inputs = programInputs(
      start: s,
      options: opts,
      calibration: current == null || !current.generated,
    );
    if (inputs == null) return null;
    final seed =
        current?.generated == true
            ? current!.seed
            : genHash('${profile!.createdAt}|${profileAt(storeClock())}') &
                0x7FFFFFFF;
    final cycle = current?.generated == true ? current!.cycle : 0;
    // Le modèle Expert streetlifting (40 semaines) ne se prend qu'au départ
    // (semaine 1, aucun journal) ; en cours de route : blocs.
    final fresh = from.week == 1 && from.day == 1 && !hasLogs;
    final levels = movementLevels(assets.models, inputs);
    final chosen = chooseModel(assets.models, inputs, levels.global);
    final force = chosen == 'expert_streetlifting' && !fresh ? 'block' : null;
    final gen = generateProgram(
      models: assets.models,
      catalog: assets.catalog,
      base: GenBase(_baseProgramJson, _baseKoachJson),
      inputs: inputs,
      seed: seed,
      firstWeek: fresh ? 1 : from.week,
      cycle: cycle,
      forceModel: force,
    );
    final nowAt = profileAt(storeClock());
    final before = _currentWeeks();
    final modelBefore = programModel;
    final modelAfter = gen.summary['model'] as String;
    final ProgramInstance next;
    List<Map<String, dynamic>> merged;
    if (modelAfter == 'expert_streetlifting') {
      next = ProgramInstance.template(
        at: nowAt,
        origin: reason,
        sourceSha: (_baseKoachJson['source'] as Map?)?['sha256'] as String?,
      ).copyWith(
        summary: gen.summary,
        inputs: inputs.toJson(),
        seed: seed,
        options: opts,
        profileKey: inputs.profileKey,
        models: assets.models.version,
        undo: {
          'at': storeClock().toIso8601String(),
          'fromWeek': 1,
          'instance': current?.toJson(withUndo: false),
        },
      );
      merged = copyWeeks(_baseProgramJson['weeks'] as List);
    } else {
      final newWeeks = [
        for (final w in gen.program['weeks'] as List)
          (w as Map).cast<String, dynamic>(),
      ];
      merged =
          fresh
              ? newWeeks
              : mergeWeeks(
                oldWeeks: before,
                newWeeks: newWeeks,
                from: from,
                hasLog: _programLogged,
              );
      // Annotations Koach : celles des journées conservées, puis les
      // nouvelles.
      final keptIds = <String>{
        for (final w in merged)
          for (final d in w['days'] as List)
            for (final e in (d as Map)['exercises'] as List)
              (e as Map)['id'] as String,
      };
      final oldKoach =
          current?.generated == true
              ? (current!.koach['exercises'] as Map? ?? const {})
              : (_baseKoachJson['exercises'] as Map? ?? const {});
      final oldTypes =
          current?.generated == true
              ? (current!.koach['weeks'] as Map? ?? const {})
              : (_baseKoachJson['weeks'] as Map? ?? const {});
      final koachEx = <String, dynamic>{
        for (final e in oldKoach.entries)
          if (keptIds.contains(e.key)) '${e.key}': e.value,
        ...(gen.koach['exercises'] as Map<String, dynamic>),
      };
      final types = <String, dynamic>{
        for (final e in oldTypes.entries)
          if (int.parse('${e.key}') < (fresh ? 1 : from.week) &&
              int.parse('${e.key}') <= merged.length)
            '${e.key}': e.value,
        ...(gen.koach['weeks'] as Map<String, dynamic>),
      };
      final history = <Map<String, dynamic>>[
        ...?current?.history,
        {
          'at': nowAt,
          'fromWeek': fresh ? 1 : from.week,
          'toWeek': merged.length,
          'cycle': cycle,
          'seed': seed,
          'reason': reason,
          'generator': kGeneratorVersion,
          'model': modelAfter,
        },
      ];
      next = ProgramInstance(
        kind: 'generated',
        origin: current?.generated == true ? current!.origin : reason,
        createdAt: current?.generated == true ? current!.createdAt : nowAt,
        updatedAt: nowAt,
        models: assets.models.version,
        seed: seed,
        inputs: inputs.toJson(),
        weeks: merged,
        koach: {'exercises': koachEx, 'weeks': types},
        summary: {...gen.summary, 'fromWeek': fresh ? 1 : from.week},
        history:
            history.length > 100
                ? history.sublist(history.length - 100)
                : history,
        cycle: cycle,
        options: opts,
        // Premier programme (démarrage, départ modifié) : rien à annuler.
        undo:
            reason == 'onboarding' || reason == 'start'
                ? null
                : {
                  'at': storeClock().toIso8601String(),
                  'fromWeek': fresh ? 1 : from.week,
                  'instance': current?.toJson(withUndo: false),
                },
        profileKey: inputs.profileKey,
      );
    }
    final diff = diffWeeks(
      before: before,
      after: merged,
      from: fresh ? (week: 1, day: 1) : from,
      modelBefore: modelBefore,
      modelAfter: modelAfter,
    );
    return ProgramProposal(next, diff, from, reason, s);
  }

  void _programChanged() {
    _progression = null;
    _koachCache = null;
    _koachCacheRevision = -1;
    _koachAuxRevision++;
    _statsCache.clear();
    _allEx = null;
    _muscleIndex = null;
    pilotageEpoch++;
    dataEpoch++;
  }

  /// Applique une proposition. Le départ est fixé s'il ne l'était pas.
  void applyProgram(ProgramProposal p) {
    final start = program.start ?? p.start;
    if (program.start == null) startOrigin = 'user';
    programInstance =
        p.instance.kind == 'template' && p.instance.undo?['instance'] == null
            ? null
            : p.instance;
    _materializeProgram(start);
    _programChanged();
    _persist();
    notifyListeners();
  }

  /// Annulation de la dernière régénération (7 jours), refusée si une
  /// journée régénérée a déjà un journal.
  bool get programCanUndo {
    final inst = programInstance;
    if (inst == null || !inst.canUndo(storeClock())) return false;
    final at = DateTime.tryParse('${inst.undo!['at']}');
    final s = program.start;
    if (at == null || s == null) return false;
    final from = inst.undo!['fromWeek'] as int? ?? 1;
    for (final k in logs.keys) {
      final m = RegExp(r'^S(\d+)-J(\d)$').firstMatch(k);
      if (m == null) continue;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      if (w < from || !_programLogged(w, j)) continue;
      final date = DateTime(s.year, s.month, s.day + (w - 1) * 7 + j - 1);
      if (!date.isBefore(DateTime(at.year, at.month, at.day))) return false;
    }
    return true;
  }

  bool undoProgram() {
    if (!programCanUndo) return false;
    final prev = programInstance!.undo!['instance'];
    programInstance =
        prev == null
            ? null
            : ProgramInstance.fromJson(
              prev,
              strict: false,
            )?.copyWith(clearUndo: true);
    _materializeProgram(program.start);
    _programChanged();
    _persist();
    notifyListeners();
    return true;
  }

  /// Nouvel utilisateur : programme généré dès que le départ est choisi.
  /// Départ modifié sans journal : programme régénéré depuis ce départ.
  Future<void> onProgramStartConfigured() async {
    final p = profile;
    if (p == null || _programHasLogs) return;
    final inst = programInstance;
    final wanted =
        (inst == null && p.origin == 'onboarding') ||
        (inst != null && inst.generated);
    if (!wanted) return;
    final prop = await proposeProgram(
      reason: inst == null ? 'onboarding' : 'start',
    );
    if (prop == null) return;
    applyProgram(prop);
  }

  /// Profil modifié : en mode Guidé, la suite est régénérée tout de suite
  /// (annulable 7 jours) ; sinon une proposition est affichée.
  Future<bool> onProfileSavedForProgram() async {
    if (!programProfileChanged) return false;
    if (profile?.stringValue('autonomy') != 'guided') return false;
    final prop = await proposeProgram(reason: 'profile');
    if (prop == null) return false;
    applyProgram(prop);
    return true;
  }

  /// Séries validées d'un exercice d'une journée.
  List<LoggedSet> _loggedSets(String key, String exerciseId) {
    final l = logs[key]?.ex[exerciseId];
    if (l == null) return const [];
    final out = <LoggedSet>[];
    for (final s in l.sets) {
      if (!s.done || s.excluded) continue;
      final reps = int.tryParse(s.reps.trim());
      if (reps == null) continue;
      final rir = s.effort ?? double.tryParse(s.rir.replaceAll(',', '.'));
      final kg = double.tryParse(s.kg.replaceAll(',', '.'));
      out.add(LoggedSet(reps, rir: rir, kg: kg));
    }
    return out;
  }

  /// Cycle suivant (objectif sans date) : généré pendant la dernière
  /// semaine du cycle depuis le journal (points d'entrée, calibrage, volume
  /// ±2) ; jamais au milieu d'un cycle (KT-051, KT-052, KT-055).
  Future<bool> extendProgramIfNeeded() async {
    final inst = programInstance;
    final s = program.start;
    if (inst == null || !inst.generated || s == null) return false;
    if (inst.summary['eventDate'] != null) return false;
    final pos = positionOf(s, _programToday);
    if (civilDayIndex(_programToday) < civilDayIndex(s)) return false;
    if (pos.week < inst.weeks.length) return false;
    final assets = ProgramAssets.loaded ?? await ProgramAssets.load();
    final prev = GenInputs.fromJson(inst.inputs);
    final progress = progressFromLogs(
      weeks: inst.weeks,
      catalog: assets.catalog,
      sets: _loggedSets,
      entries: prev.entries,
      volumeAdjust: prev.volumeAdjust,
      cycle: inst.cycle,
      step: assets.models.cycleStep,
      maxUp: assets.models.ceilingAbove,
    );
    final calibrated = <String, double>{
      for (final e in prev.measures.entries)
        if (prev.measureSources[e.key] == 'calibrated') e.key: e.value,
      ...progress.measures,
    };
    final inputs = programInputs(
      options: inst.options,
      calibrated: calibrated,
      entries: progress.entries,
      volumeAdjust: progress.volumeAdjust,
      calibration: false,
    );
    if (inputs == null) return false;
    final first = inst.weeks.length + 1;
    final levels = movementLevels(assets.models, inputs);
    final chosen = chooseModel(assets.models, inputs, levels.global);
    final gen = generateProgram(
      models: assets.models,
      catalog: assets.catalog,
      base: GenBase(_baseProgramJson, _baseKoachJson),
      inputs: inputs,
      seed: inst.seed,
      firstWeek: first,
      cycle: inst.cycle + 1,
      forceModel: chosen == 'expert_streetlifting' ? 'block' : null,
    );
    final weeks = [
      ...inst.weeks,
      for (final w in gen.program['weeks'] as List)
        (w as Map).cast<String, dynamic>(),
    ];
    final nowAt = profileAt(storeClock());
    programInstance = inst.copyWith(
      updatedAt: nowAt,
      inputs: inputs.toJson(),
      weeks: weeks,
      koach: {
        'exercises': {
          ...(inst.koach['exercises'] as Map? ?? const {})
              .cast<String, dynamic>(),
          ...(gen.koach['exercises'] as Map<String, dynamic>),
        },
        'weeks': {
          ...(inst.koach['weeks'] as Map? ?? const {}).cast<String, dynamic>(),
          ...(gen.koach['weeks'] as Map<String, dynamic>),
        },
      },
      summary: {...gen.summary, 'fromWeek': first},
      history: <Map<String, dynamic>>[
        ...inst.history,
        {
          'at': nowAt,
          'fromWeek': first,
          'toWeek': weeks.length,
          'cycle': inst.cycle + 1,
          'seed': inst.seed,
          'reason': 'cycle',
          'generator': kGeneratorVersion,
          'model': gen.summary['model'],
        },
      ],
      cycle: inst.cycle + 1,
      profileKey: inputs.profileKey,
      clearUndo: true,
    );
    _materializeProgram(s);
    _programChanged();
    _persist();
    notifyListeners();
    return true;
  }
}
