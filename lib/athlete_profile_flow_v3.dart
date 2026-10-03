// CU (dev6.8.0, PIPELINE_CP) : questions du profil v3 dans le parcours de
// création (G6). Chaque question n'est montrée que si `ProfileQuestionnaire`
// la rend pour le profil en cours de saisie (aucune condition codée ici) ;
// textes, réponses et validations : `packages/kalis_core/docs/PARCOURS_V3.md`
// (données : `data/parcours_v3.json`). « Passer » et « Je ne sais pas »
// laissent le champ absent (D5.8).
part of 'athlete_profile_flow.dart';

/// Ligne de choix (réponse et précision), lisible à 200 % de texte.
class _ChoiceRow extends StatelessWidget {
  final String label;
  final String? hint;
  final bool selected, multi;
  final VoidCallback onTap;
  const _ChoiceRow({
    super.key,
    required this.label,
    this.hint,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    inMutuallyExclusiveGroup: !multi,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                multi
                    ? (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                    : (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                color: selected ? SL.accent : SL.dim,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  if (hint != null)
                    Text(hint!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Nombre saisi (virgule ou point) ; null si vide ou illisible.
double? _parseNum(String t) {
  final s = t.trim().replaceAll(',', '.');
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

/// Durée saisie : « 75 » (secondes), « 1:15 », « 1:02:30 » ; null sinon.
int? _parseDuration(String t) {
  final s = t.trim();
  if (s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length > 3) return null;
  var total = 0;
  for (final p in parts) {
    final v = int.tryParse(p.trim());
    if (v == null || v < 0) return null;
    total = total * 60 + v;
  }
  return total;
}

/// Durée affichée « m:ss » (ou « h:mm:ss »).
String _durationField(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(r)}' : '$m:${two(r)}';
}

/// Première violation lisible d'une valeur du contrat (null : valide).
String? _firstViolation(List<Violation> v) =>
    v.isEmpty ? null : 'Réponse incomplète ou hors limites (${v.first.path}).';

Widget _sheetLabel(BuildContext context, String t) => Padding(
  padding: const EdgeInsets.only(top: 12, bottom: 6),
  child: Text(t, style: Theme.of(context).textTheme.titleMedium),
);

Widget _sheetHint(BuildContext context, String t) =>
    Text(t, style: Theme.of(context).textTheme.bodySmall);

Widget _sheetChips<T>({
  required String keyPrefix,
  required List<(T, String)> options,
  required bool Function(T) selected,
  required void Function(T) onTap,
  bool multi = false,
}) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final o in options)
      multi
          ? FilterChip(
              key: ValueKey('$keyPrefix-${o.$1}'),
              label: Text(o.$2),
              selected: selected(o.$1),
              onSelected: (_) => onTap(o.$1),
            )
          : ChoiceChip(
              key: ValueKey('$keyPrefix-${o.$1}'),
              label: Text(o.$2),
              selected: selected(o.$1),
              onSelected: (_) => onTap(o.$1),
            ),
  ],
);

String _exerciseName(String id) => store.content.byId[id]?.nom ?? id;

Future<String?> _pickExerciseFor(
  BuildContext context, {
  List<String> suggested = const [],
  List<String>? only,
  String title = 'CHOISIR UN EXERCICE',
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) =>
        ExercisePickerPage(suggested: suggested, only: only, title: title),
  ),
);

extension _FlowV3 on AthleteProfileFlowState {
  ProfileQuestionnaire? get _pq => store.content.questionnaire;
  ProfileQuestion? _q(String id) => _pq?.question(id);
  Catalog? get _catalog => store.content.catalog;

  /// Texte de Koach d'un écran du parcours (repli : [fallback]).
  String _screenKoach(String step, String fallback) {
    final screen = kStepScreens[step];
    for (final s in _pq?.screens ?? const <Map<String, Object?>>[]) {
      if (s['id'] == screen && s['koach'] is String) return s['koach']! as String;
    }
    return fallback;
  }

  /// Carte d'une question : texte, mot de Koach, réponses, « Passer ».
  Widget _questionCard(
    ProfileQuestion q,
    List<Widget> body, {
    VoidCallback? onSkip,
    String? title,
  }) => KCard(
    key: ValueKey('q-${q.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(title ?? q.text),
        if (koachOf(q) case final k?) ...[
          const SizedBox(height: 4),
          _hint(k),
        ],
        const SizedBox(height: 8),
        ...body,
        if (q.skip && onSkip != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: ValueKey('q-${q.id}-skip'),
              onPressed: () => _update(onSkip),
              child: const Text('Passer'),
            ),
          ),
      ],
    ),
  );

  List<Widget> _choiceRows(
    ProfileQuestion q,
    String? value,
    void Function(String code) onPick, {
    String? keyPrefix,
  }) => [
    for (final o in q.options)
      _ChoiceRow(
        key: ValueKey('${keyPrefix ?? 'q-${q.id}'}-${o.code}'),
        label: o.label,
        hint: o.hint,
        selected: value == o.code,
        onTap: () => _update(() => onPick(o.code)),
      ),
  ];

  /// Question à un choix (« Passer » remet le champ à absent).
  Widget _choiceQuestion(
    String id,
    String? value,
    void Function(String? code) set, {
    String? keyPrefix,
    List<Widget> extra = const [],
  }) {
    final q = _q(id);
    if (q == null) return const SizedBox.shrink();
    return _questionCard(q, [
      ..._choiceRows(q, value, set, keyPrefix: keyPrefix),
      ...extra,
    ], onSkip: () => set(null));
  }

  // ------------------------------------------------------------ expérience

  List<Widget> _experienceStep() {
    final q = _q('experience_level');
    return [
      _koach(
        KoachPose.analyze,
        _screenKoach(
          'experience',
          'Dis-moi d’où tu pars : je règle la difficulté dessus.',
        ),
        why:
            'Tu reprends après un long arrêt ? Choisis ton niveau d’avant : '
            'je te demande ensuite depuis quand tu as arrêté.',
      ),
      if (_show('experience_level'))
        if (q == null)
          KCard(
            child: _chips<ExperienceLevel>(
              keyPrefix: 'flow-experience',
              options: [
                for (final e in ExperienceLevel.values)
                  (e, kExperienceLabels[e]!),
              ],
              selected: (e) => _d.experience == e,
              onSelected: (e, v) => _d.experience = v ? e : null,
            ),
          )
        else
          _choiceQuestion(
            'experience_level',
            _d.experience?.code,
            (c) => _d.experience = c == null
                ? null
                : ExperienceLevel.fromCode(c),
            keyPrefix: 'flow-experience',
          ),
      if (_show('training_age'))
        _choiceQuestion(
          'training_age',
          _d.trainingAge?.code,
          (c) => _d.trainingAge = c == null ? null : TrainingAge.fromCode(c),
        ),
      if (_show('training_gap'))
        _choiceQuestion(
          'training_gap',
          _d.trainingGap?.code,
          (c) => _d.trainingGap = c == null ? null : TrainingGap.fromCode(c),
        ),
    ];
  }

  // ------------------------------------------------------------- records

  Widget _benchmarksCard() {
    final q = _q('benchmarks')!;
    final list = _d.benchmarks ?? const <Benchmark>[];
    return _questionCard(q, [
      for (var i = 0; i < list.length; i++)
        ListTile(
          key: ValueKey('benchmark-$i'),
          contentPadding: EdgeInsets.zero,
          title: Text(_exerciseName(list[i].exerciseId)),
          subtitle: Text(benchmarkText(list[i], q)),
          onTap: () => _editBenchmark(i),
          trailing: IconButton(
            key: ValueKey('benchmark-remove-$i'),
            tooltip: 'Retirer ce record',
            icon: const Icon(Icons.close),
            onPressed: () => _update(() {
              final next = [...list]..removeAt(i);
              _d.benchmarks = next;
            }),
          ),
        ),
      if (_unknownBenchmarks && list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: KoachSays(
            key: const ValueKey('benchmarks-unknown-koach'),
            pose: KoachPose.thumbsUp,
            child: const Text(
              'Pas de souci : aucun examen aujourd’hui. On calera tes '
              'charges pendant tes premières séances, et je te proposerai un '
              'test guidé si ça vaut le coup.',
            ),
          ),
        ),
      FilledButton.tonalIcon(
        key: const ValueKey('benchmark-add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un record'),
        onPressed: () => _editBenchmark(null),
      ),
      const SizedBox(height: 6),
      OutlinedButton(
        key: const ValueKey('benchmarks-unknown'),
        onPressed: () => _update(() {
          _d.benchmarks = null;
          _unknownBenchmarks = true;
        }),
        child: const Text('Je ne sais pas'),
      ),
    ], onSkip: () {
      _d.benchmarks = null;
      _unknownBenchmarks = false;
    });
  }

  Future<void> _editBenchmark(int? index) async {
    final q = _q('benchmarks')!;
    final list = [...?_d.benchmarks];
    final old = index == null ? null : list[index];
    final b = await showModalBottomSheet<Benchmark>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _BenchmarkSheet(
        question: q,
        initial: old,
        suggested: benchmarkSuggestions(_d, _catalog),
        today: civilOf(_now),
        profileWeight: _d.weightValue == null || _d.weightValue!.isNaN
            ? null
            : _d.weightValue,
        askStandard:
            _d.disciplines.contains(TrainingDiscipline.streetlifting) ||
            (_d.events ?? const <SeasonEvent>[]).any(
              (e) => e.kind == EventKind.strengthCompetition,
            ),
      ),
    );
    if (b == null || !mounted) return;
    _update(() {
      if (index == null) {
        list.add(b);
      } else {
        list[index] = b;
      }
      _d.benchmarks = list;
      _unknownBenchmarks = false;
    });
  }

  // -------------------------------------------------------- fourchettes

  List<Widget> _movementLevelCards() => [
    if (_d.shownMovements.isNotEmpty)
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const ValueKey('levels-unknown-all'),
          icon: const Icon(Icons.help_outline),
          label: const Text('Je ne sais pas, on verra ensemble'),
          onPressed: () => _update(() {
            for (final m in _d.shownMovements) {
              _d.levels[m.key] = -1;
            }
          }),
        ),
      ),
    for (final m in _d.shownMovements)
      KCard(
        key: ValueKey('flow-level-${m.key}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(m.label),
            const SizedBox(height: 2),
            _hint(m.question),
            const SizedBox(height: 8),
            _chips<int>(
              keyPrefix: 'level-${m.key}',
              options: [
                for (var i = 0; i < m.bands.length; i++) (i, m.bands[i].label),
                (-1, 'Je ne sais pas'),
              ],
              selected: (i) => _d.levels[m.key] == i,
              onSelected: (i, v) {
                if (v) {
                  _d.levels[m.key] = i;
                } else {
                  _d.levels.remove(m.key);
                }
              },
            ),
          ],
        ),
      ),
  ];

  // -------------------------------------------------------------- figures

  Widget _skillsCard() {
    final q = _q('skills')!;
    final list = _d.skills ?? const <SkillState>[];
    final tenure = itemOptions(q, 'atStepSince');
    String tenureText(StepTenure? t) {
      if (t == null) return '';
      for (final o in tenure) {
        if (o.$1 == t.code) return ' · depuis ${o.$2.toLowerCase()}';
      }
      return '';
    }

    return _questionCard(q, [
      if (list.length > 1)
        _hint('L’ordre est l’ordre de priorité : la plus importante en haut.'),
      for (var i = 0; i < list.length; i++)
        ListTile(
          key: ValueKey('skill-$i'),
          contentPadding: EdgeInsets.zero,
          title: Text(_exerciseName(list[i].targetExerciseId)),
          subtitle: Text(
            'Étape : ${_exerciseName(list[i].currentExerciseId)}'
            '${list[i].bestHoldSeconds == null ? '' : ' · ${list[i].bestHoldSeconds} s'}'
            '${list[i].bestReps == null ? '' : ' · ${list[i].bestReps} rép.'}'
            '${tenureText(list[i].atStepSince)}',
          ),
          onTap: () => _editSkill(i),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                IconButton(
                  key: ValueKey('skill-up-$i'),
                  tooltip: 'Plus prioritaire',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => _update(() {
                    final next = [...list];
                    final s = next.removeAt(i);
                    next.insert(i - 1, s);
                    _d.skills = next;
                  }),
                ),
              IconButton(
                key: ValueKey('skill-remove-$i'),
                tooltip: 'Retirer cette figure',
                icon: const Icon(Icons.close),
                onPressed: () => _update(() {
                  _d.skills = [...list]..removeAt(i);
                }),
              ),
            ],
          ),
        ),
      FilledButton.tonalIcon(
        key: const ValueKey('skill-add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une figure'),
        onPressed: () => _editSkill(null),
      ),
    ], onSkip: () => _d.skills = null);
  }

  Future<void> _editSkill(int? index) async {
    final q = _q('skills')!;
    final catalog = _catalog;
    if (catalog == null) return;
    final list = [...?_d.skills];
    final old = index == null ? null : list[index];
    final s = await showModalBottomSheet<SkillState>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _SkillSheet(
        question: q,
        catalog: catalog,
        targets: [for (final e in skillTargets(catalog, _d)) e.id],
        taken: {
          for (final x in list)
            if (x != old) x.targetExerciseId,
        },
        initial: old,
      ),
    );
    if (s == null || !mounted) return;
    _update(() {
      if (index == null) {
        list.add(s);
      } else {
        list[index] = s;
      }
      _d.skills = list;
    });
  }

  // ------------------------------------------------------ charge actuelle

  Widget _recentTrainingCard() {
    final q = _q('recent_training')!;
    final rows = <String>[
      for (final r in _d.recentTraining ?? const <RecentTraining>[])
        r.exerciseId,
    ];
    for (final id in recentTrainingSuggestions(_d, _catalog)) {
      if (!rows.contains(id) && rows.length < 4) rows.add(id);
    }
    for (final id in _extraRecentRows) {
      if (!rows.contains(id)) rows.add(id);
    }
    RecentTraining? rowOf(String id) {
      for (final r in _d.recentTraining ?? const <RecentTraining>[]) {
        if (r.exerciseId == id) return r;
      }
      return null;
    }

    void put(String id, {int? sessions, HardSetsBand? hard, bool clearHard = false}) {
      final list = [...?_d.recentTraining];
      final i = list.indexWhere((r) => r.exerciseId == id);
      final old = i < 0 ? null : list[i];
      final s = sessions ?? old?.sessionsPerWeek;
      if (s == null) return;
      final next = RecentTraining(
        exerciseId: id,
        sessionsPerWeek: s,
        hardSets: clearHard ? null : (hard ?? old?.hardSets),
      );
      if (i < 0) {
        list.add(next);
      } else {
        list[i] = next;
      }
      _d.recentTraining = list;
    }

    final sessionsOpts = itemOptions(q, 'sessionsPerWeek');
    final hardOpts = itemOptions(q, 'hardSets');
    final phaseOpts = itemOptions(q, 'currentPhase');
    return _questionCard(q, [
      for (final id in rows) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _exerciseName(id),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        _hint(itemText(q, 'sessionsPerWeek', 'Combien de fois par semaine ?')),
        const SizedBox(height: 4),
        _sheetChips<String>(
          keyPrefix: 'recent-$id-sessions',
          options: sessionsOpts,
          selected: (c) => rowOf(id)?.sessionsPerWeek.toString() == c,
          onTap: (c) => _update(() => put(id, sessions: int.parse(c))),
        ),
        if (rowOf(id) != null && rowOf(id)!.sessionsPerWeek > 0) ...[
          const SizedBox(height: 6),
          _hint(itemText(q, 'hardSets', 'Combien de séries dures par semaine ?')),
          const SizedBox(height: 4),
          _sheetChips<String>(
            keyPrefix: 'recent-$id-hard',
            options: hardOpts,
            selected: (c) => rowOf(id)?.hardSets?.code == c,
            onTap: (c) => _update(
              () => rowOf(id)?.hardSets?.code == c
                  ? put(id, clearHard: true)
                  : put(id, hard: HardSetsBand.fromCode(c)),
            ),
          ),
        ],
      ],
      const SizedBox(height: 8),
      TextButton.icon(
        key: const ValueKey('recent-add'),
        icon: const Icon(Icons.add),
        label: const Text('Un autre mouvement'),
        onPressed: () async {
          final id = await _pickExerciseFor(context);
          if (id == null || !mounted) return;
          _update(() => _extraRecentRows.add(id));
        },
      ),
      const SizedBox(height: 8),
      _title(itemText(q, 'currentPhase', 'En ce moment, tu es plutôt…')),
      const SizedBox(height: 4),
      for (final o in phaseOpts)
        _ChoiceRow(
          key: ValueKey('q-current_phase-${o.$1}'),
          label: o.$2,
          selected: _d.currentPhase?.code == o.$1,
          onTap: () => _update(() => _d.currentPhase = CurrentPhase.fromCode(o.$1)),
        ),
    ], onSkip: () {
      _d.recentTraining = null;
      _d.currentPhase = null;
    });
  }

  // ------------------------------------------------------------ objectifs

  List<Widget> _goalsV3() => [
    if (_show('emphasis'))
      _choiceQuestion(
        'emphasis',
        _d.emphasis?.code,
        (c) => _d.emphasis = c == null ? null : TrainingEmphasis.fromCode(c),
      ),
    if (_show('events')) _eventsCard(),
    if (_show('specialization')) _specializationCard(),
    if (_show('weak_points')) _weakPointsCard(),
    if (_show('running_base')) _runningBaseCard(),
  ];

  Widget _eventsCard() {
    final q = _q('events')!;
    final list = _d.events;
    final kinds = itemOptions(q, 'kind');
    final prios = itemOptions(q, 'priority');
    String label(List<(String, String)> o, String code) {
      for (final x in o) {
        if (x.$1 == code) return x.$2;
      }
      return code;
    }

    final events = list ?? const <SeasonEvent>[];
    return _questionCard(q, [
      if (list != null && list.isEmpty)
        _hint('Aucune échéance pour l’instant.'),
      for (var i = 0; i < events.length; i++)
        ListTile(
          key: ValueKey('event-$i'),
          contentPadding: EdgeInsets.zero,
          title: Text(events[i].name ?? label(kinds, events[i].kind.code)),
          subtitle: Text(
            '${events[i].dateApproximate == true ? 'Vers ${monthText(events[i].date)}' : longDateText(events[i].date)}'
            ' · ${label(prios, events[i].priority.code)}',
          ),
          onTap: () => _editEvent(i),
          trailing: IconButton(
            key: ValueKey('event-remove-$i'),
            tooltip: 'Retirer cette échéance',
            icon: const Icon(Icons.close),
            onPressed: () => _update(() {
              _d.events = [...events]..removeAt(i);
            }),
          ),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('event-add'),
            icon: const Icon(Icons.event),
            label: const Text('Ajouter une date'),
            onPressed: () => _editEvent(null),
          ),
          if (list == null)
            OutlinedButton(
              key: const ValueKey('events-none'),
              onPressed: () => _update(() => _d.events = const <SeasonEvent>[]),
              child: const Text('Non'),
            ),
        ],
      ),
    ], onSkip: () => _d.events = null);
  }

  Future<void> _editEvent(int? index) async {
    final q = _q('events')!;
    final list = [...?_d.events];
    final old = index == null ? null : list[index];
    final e = await showModalBottomSheet<SeasonEvent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _EventSheet(
        question: q,
        presets: _pq?.rulesetPresets ?? const [],
        today: civilOf(_now),
        initial: old,
        id: old?.id ?? _nextEventId(list),
        sex: _d.sex,
        profileWeight: _d.weightValue == null || _d.weightValue!.isNaN
            ? null
            : _d.weightValue,
      ),
    );
    if (e == null || !mounted) return;
    _update(() {
      if (index == null) {
        list.add(e);
      } else {
        list[index] = e;
      }
      _d.events = list;
    });
  }

  static String _nextEventId(List<SeasonEvent> list) {
    var n = 1;
    while (list.any((e) => e.id == 'event-$n')) {
      n++;
    }
    return 'event-$n';
  }

  Widget _specializationCard() {
    final q = _q('specialization')!;
    final s = _d.specialization;
    final mainEvent = (_d.events ?? const <SeasonEvent>[]).any(
      (e) => e.priority == EventPriority.main,
    );
    final musculation =
        _d.disciplines.isNotEmpty &&
        _d.disciplines.first == TrainingDiscipline.musculation;
    final title = mainEvent
        ? 'Lequel de tes mouvements de compétition est le plus en retard ?'
        : musculation
        ? 'Une zone à développer en priorité ?'
        : q.text;
    return _questionCard(
      q,
      [
        if (s != null)
          ListTile(
            key: const ValueKey('specialization-value'),
            contentPadding: EdgeInsets.zero,
            title: Text(specializationText(s, q)),
            onTap: () => _editSpecialization(mainEvent: mainEvent),
            trailing: IconButton(
              key: const ValueKey('specialization-remove'),
              tooltip: 'Retirer',
              icon: const Icon(Icons.close),
              onPressed: () => _update(() => _d.specialization = null),
            ),
          )
        else
          FilledButton.tonalIcon(
            key: const ValueKey('specialization-add'),
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Choisir'),
            onPressed: () => _editSpecialization(mainEvent: mainEvent),
          ),
        if (mainEvent)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _hint(
              'Avec une compétition principale, le reste est entretenu et la '
              'priorité n’est servie que loin de l’échéance.',
            ),
          ),
      ],
      onSkip: () => _d.specialization = null,
      title: title,
    );
  }

  Future<void> _editSpecialization({required bool mainEvent}) async {
    final q = _q('specialization')!;
    final catalog = _catalog;
    if (catalog == null) return;
    final lifts = <String>[
      for (final e in _d.events ?? const <SeasonEvent>[])
        if (e.priority == EventPriority.main)
          for (final l in e.lifts ?? const <CompetitionLift>[]) l.exerciseId,
    ];
    final s = await showModalBottomSheet<Specialization>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _SpecializationSheet(
        question: q,
        catalog: catalog,
        initial: _d.specialization,
        mainEvent: mainEvent,
        competitionLifts: lifts,
        figures: [for (final e in skillTargets(catalog, _d)) e.id],
        preferMuscle:
            _d.disciplines.isNotEmpty &&
            _d.disciplines.first == TrainingDiscipline.musculation,
      ),
    );
    if (s == null || !mounted) return;
    _update(() => _d.specialization = s);
  }

  Widget _weakPointsCard() {
    final q = _q('weak_points')!;
    final catalog = _catalog;
    final list = _d.weakPoints ?? const <WeakPoint>[];
    final exercises = [
      ...weakPointExercises(_d),
      for (final w in list) w.exerciseId,
      ..._extraWeakRows,
    ].toSet().toList();
    bool has(String id, WeakPointKind k) =>
        list.any((w) => w.exerciseId == id && w.kind == k);
    return _questionCard(q, [
      if (exercises.isEmpty)
        _hint(
          'Ajoute d’abord un record ou ton niveau sur un mouvement, ou '
          'choisis-le ici.',
        ),
      for (final id in exercises) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            _exerciseName(id),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        _sheetChips<WeakPointKind>(
          keyPrefix: 'weak-$id',
          multi: true,
          options: [
            for (final c in weakPointChoices(
              catalog?.find(id) == null
                  ? WeakFamily.other
                  : weakFamilyOf(catalog!.find(id)!),
              q,
            ))
              c,
          ],
          selected: (k) => has(id, k),
          onTap: (k) => _update(() {
            final next = [...list];
            if (has(id, k)) {
              next.removeWhere((w) => w.exerciseId == id && w.kind == k);
            } else {
              next.add(WeakPoint(exerciseId: id, kind: k));
            }
            _d.weakPoints = next;
          }),
        ),
      ],
      TextButton.icon(
        key: const ValueKey('weak-add'),
        icon: const Icon(Icons.add),
        label: const Text('Un autre mouvement'),
        onPressed: () async {
          final id = await _pickExerciseFor(context);
          if (id == null || !mounted) return;
          _update(() => _extraWeakRows.add(id));
        },
      ),
      _hint(
        'Une douleur n’est pas un point faible : elle se dit à l’écran Santé.',
      ),
    ], onSkip: () => _d.weakPoints = null);
  }

  Widget _runningBaseCard() {
    final q = _q('running_base')!;
    final base = _d.enduranceBase;
    final volume = base?.weeklyVolume.code ?? _runVolume;
    final sessions = base?.sessionsPerWeek.toString() ?? _runSessions;
    void commit() {
      final v = volume, s = sessions;
      if (v == null || s == null) return;
      _d.enduranceBase = EnduranceBase(
        weeklyVolume: RunVolumeBand.fromCode(v),
        sessionsPerWeek: int.parse(s),
        longRun: base?.longRun,
      );
    }

    return _questionCard(q, [
      _hint(itemText(q, 'weeklyVolume', 'Par semaine, en tout')),
      for (final o in itemOptions(q, 'weeklyVolume'))
        _ChoiceRow(
          key: ValueKey('run-volume-${o.$1}'),
          label: o.$2,
          selected: volume == o.$1,
          onTap: () => _update(() {
            _runVolume = o.$1;
            final s = sessions;
            if (s != null) {
              _d.enduranceBase = EnduranceBase(
                weeklyVolume: RunVolumeBand.fromCode(o.$1),
                sessionsPerWeek: int.parse(s),
                longRun: base?.longRun,
              );
            }
          }),
        ),
      const SizedBox(height: 8),
      _hint(itemText(q, 'sessionsPerWeek', 'Combien de sorties par semaine ?')),
      const SizedBox(height: 4),
      _sheetChips<String>(
        keyPrefix: 'run-sessions',
        options: itemOptions(q, 'sessionsPerWeek'),
        selected: (c) => sessions == c,
        onTap: (c) => _update(() {
          _runSessions = c;
          final v = volume;
          if (v != null) {
            _d.enduranceBase = EnduranceBase(
              weeklyVolume: RunVolumeBand.fromCode(v),
              sessionsPerWeek: int.parse(c),
              longRun: base?.longRun,
            );
          }
        }),
      ),
      if (base != null) ...[
        const SizedBox(height: 8),
        _hint(itemText(q, 'longRun', 'Ta plus longue sortie récente ?')),
        const SizedBox(height: 4),
        _sheetChips<String>(
          keyPrefix: 'run-long',
          options: itemOptions(q, 'longRun'),
          selected: (c) => base.longRun?.code == c,
          onTap: (c) => _update(() {
            commit();
            final b = _d.enduranceBase!;
            _d.enduranceBase = EnduranceBase(
              weeklyVolume: b.weeklyVolume,
              sessionsPerWeek: b.sessionsPerWeek,
              longRun: b.longRun?.code == c ? null : LongRunBand.fromCode(c),
            );
          }),
        ),
      ],
    ], onSkip: () {
      _d.enduranceBase = null;
      _runVolume = null;
      _runSessions = null;
    });
  }

  // --------------------------------------------------------- récupération

  List<Widget> _recoveryStep() => [
    _koach(
      KoachPose.think,
      _screenKoach(
        'recovery',
        'Ton corps récupère aussi en dehors des séances. Quelques questions '
        'rapides.',
      ),
      why:
          'Ce sont tes habitudes : la nuit dernière et le stress du jour se '
          'disent dans le bilan de séance, qui prime dès qu’il est rempli.',
    ),
    if (_show('sleep'))
      _choiceQuestion(
        'sleep',
        _d.sleep?.code,
        (c) => _d.sleep = c == null ? null : SleepBand.fromCode(c),
      ),
    if (_show('stress'))
      _choiceQuestion(
        'stress',
        _d.stress?.code,
        (c) => _d.stress = c == null ? null : StressBand.fromCode(c),
      ),
    if (_show('outside_load')) _outsideLoadCard(),
    if (_show('body_weight_goal')) _bodyWeightGoalCard(),
  ];

  Widget _outsideLoadCard() {
    final q = _q('outside_load')!;
    final occ = _d.occupationalLoad;
    final sports = _d.otherSports;
    final other = sports != null && sports.isNotEmpty || _otherSportOpen;
    final sportList = sports ?? const <OtherSport>[];
    void ensureSports() {
      _d.otherSports ??= const <OtherSport>[];
    }

    return _questionCard(q, [
      for (final o in q.options)
        if (o.code != 'other_sport')
          _ChoiceRow(
            key: ValueKey('q-outside_load-${o.code}'),
            label: o.label,
            hint: o.hint,
            selected: occ?.code == o.code,
            onTap: () => _update(() {
              _d.occupationalLoad = OccupationalLoad.fromCode(o.code);
              ensureSports();
            }),
          )
        else
          _ChoiceRow(
            key: const ValueKey('q-outside_load-other_sport'),
            label: o.label,
            hint: o.hint,
            multi: true,
            selected: other,
            onTap: () => _update(() {
              if (other) {
                _otherSportOpen = false;
                _d.otherSports = const <OtherSport>[];
              } else {
                _otherSportOpen = true;
                ensureSports();
              }
            }),
          ),
      if (other) ...[
        for (var i = 0; i < sportList.length; i++)
          ListTile(
            key: ValueKey('sport-$i'),
            contentPadding: EdgeInsets.zero,
            title: Text(itemOptionLabel(q, 'kind', sportList[i].kind.code)),
            subtitle: Text(
              '${sportList[i].sessionsPerWeek} × ${sportList[i].minutesPerSession} min par semaine'
              '${sportList[i].hard == true ? ' · intense' : ''}'
              '${sportList[i].mainSport == true ? ' · sport principal' : ''}',
            ),
            onTap: () => _editOtherSport(i),
            trailing: IconButton(
              key: ValueKey('sport-remove-$i'),
              tooltip: 'Retirer ce sport',
              icon: const Icon(Icons.close),
              onPressed: () => _update(() {
                _d.otherSports = [...sportList]..removeAt(i);
              }),
            ),
          ),
        FilledButton.tonalIcon(
          key: const ValueKey('sport-add'),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un sport'),
          onPressed: () => _editOtherSport(null),
        ),
      ],
    ], onSkip: () {
      _d.occupationalLoad = null;
      _d.otherSports = null;
      _otherSportOpen = false;
    });
  }

  Future<void> _editOtherSport(int? index) async {
    final q = _q('outside_load')!;
    final list = [...?_d.otherSports];
    final old = index == null ? null : list[index];
    final s = await showModalBottomSheet<OtherSport>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _OtherSportSheet(question: q, initial: old),
    );
    if (s == null || !mounted) return;
    _update(() {
      if (index == null) {
        list.add(s);
      } else {
        list[index] = s;
      }
      _d.otherSports = list;
    });
  }

  Widget _bodyWeightGoalCard() {
    final g = _d.bodyWeightGoal;
    final target = g == BodyWeightGoal.lose || g == BodyWeightGoal.gain;
    return _choiceQuestion(
      'body_weight_goal',
      g?.code,
      (c) => _d.bodyWeightGoal = c == null ? null : BodyWeightGoal.fromCode(c),
      extra: [
        if (target) ...[
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('q-target-weight'),
            controller: _targetWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Jusqu’à combien ? (kg, facultatif)',
            ),
            onChanged: (v) {
              final w = _parseNum(v);
              _d.targetBodyWeightKg = w != null && w >= 25 && w <= 300
                  ? w
                  : null;
            },
          ),
          const SizedBox(height: 4),
          _hint('Je ne donne aucun conseil alimentaire.'),
        ],
      ],
    );
  }
}

/// Texte d'un record (« 100 kg × 3 », « 12 rép. », « 45 s »…).
String benchmarkText(Benchmark b, ProfileQuestion? q) {
  final parts = <String>[];
  switch (b.kind) {
    case BenchmarkKind.loadReps:
      parts.add('${numText(b.externalLoadKg ?? 0)} kg × ${b.reps ?? 0}');
      if (b.rir != null) {
        parts.add('${numText(b.rir!)} en réserve');
      }
    case BenchmarkKind.maxReps:
      parts.add('${b.reps ?? 0} rép.');
      if (b.seconds != null) parts.add('en ${durationText(b.seconds!)}');
    case BenchmarkKind.maxHold:
      parts.add(durationText(b.seconds ?? 0));
    case BenchmarkKind.timeTrial:
    case BenchmarkKind.distanceTrial:
      parts.add(
        '${numText((b.distanceMeters ?? 0) / 1000)} km en '
        '${durationText(b.seconds ?? 0)}',
      );
    case BenchmarkKind.repsForTime:
      parts.add('${b.reps ?? 0} rép. en ${durationText(b.seconds ?? 0)}');
  }
  if (b.source == BenchmarkSource.competition) parts.add('en compétition');
  if (b.source == BenchmarkSource.guidedTest) parts.add('test guidé');
  if (b.date != null) parts.add(monthText(b.date!));
  return parts.join(' · ');
}

/// « mars 2027 ».
String monthText(CivilDate d) => '${kMonthNames[d.month - 1]} ${d.year}';

/// « 14 mars 2027 ».
String longDateText(CivilDate d) =>
    '${d.day} ${kMonthNames[d.month - 1]} ${d.year}';

const kMonthNames = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Texte d'une spécialisation.
String specializationText(Specialization s, ProfileQuestion? q) {
  final what = switch (s.kind) {
    SpecializationKind.muscle => s.muscle ?? '',
    SpecializationKind.pattern => s.pattern?.code.replaceAll('_', ' ') ?? '',
    _ => _exerciseName(s.exerciseId ?? ''),
  };
  return [
    what,
    if (s.weeks != null) '${s.weeks} semaines',
    if (s.maintenance != null && q != null)
      'le reste : ${itemOptionLabel(q, 'maintenance', s.maintenance!.code).toLowerCase()}',
  ].join(' · ');
}

// =================================================================== feuilles

/// Record : mouvement, nature, valeurs, date, source.
class _BenchmarkSheet extends StatefulWidget {
  final ProfileQuestion question;
  final Benchmark? initial;
  final List<String> suggested;
  final CivilDate today;
  final double? profileWeight;
  final bool askStandard;
  const _BenchmarkSheet({
    required this.question,
    this.initial,
    required this.suggested,
    required this.today,
    this.profileWeight,
    required this.askStandard,
  });

  @override
  State<_BenchmarkSheet> createState() => _BenchmarkSheetState();
}

class _BenchmarkSheetState extends State<_BenchmarkSheet> {
  String? _exercise;
  BenchmarkKind? _kind;
  final _load = TextEditingController();
  final _reps = TextEditingController();
  final _seconds = TextEditingController();
  final _distance = TextEditingController();
  final _bw = TextEditingController();
  double? _rir;
  CivilDate? _date;
  String? _dateChoice;
  BenchmarkSource _source = BenchmarkSource.declared;
  bool? _standard;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    if (b != null) {
      _exercise = b.exerciseId;
      _kind = b.kind;
      if (b.externalLoadKg != null) _load.text = numText(b.externalLoadKg!);
      if (b.reps != null) _reps.text = '${b.reps}';
      if (b.seconds != null) _seconds.text = _durationField(b.seconds!);
      if (b.distanceMeters != null) {
        _distance.text = numText(b.distanceMeters! / 1000);
      }
      if (b.bodyWeightKg != null) _bw.text = numText(b.bodyWeightKg!);
      _rir = b.rir;
      _date = b.date;
      _dateChoice = b.date == null ? 'none' : 'date';
      _source = b.source == BenchmarkSource.competition
          ? BenchmarkSource.competition
          : BenchmarkSource.declared;
      _standard = b.competitionStandard;
    }
  }

  @override
  void dispose() {
    for (final c in [_load, _reps, _seconds, _distance, _bw]) {
      c.dispose();
    }
    super.dispose();
  }

  CatalogExercise? get _ex =>
      _exercise == null ? null : store.content.byId[_exercise!]?.ex;

  bool get _bodyweightish =>
      _ex != null &&
      (_ex!.loadType == LoadType.bodyweight ||
          _ex!.loadType == LoadType.addedWeight);

  static BenchmarkKind _defaultKind(CatalogExercise e) {
    if (e.unit == MeasureUnit.seconds) return BenchmarkKind.maxHold;
    if (e.unit == MeasureUnit.distance) return BenchmarkKind.timeTrial;
    if (e.loadType == LoadType.bodyweight || e.loadType == LoadType.none) {
      return BenchmarkKind.maxReps;
    }
    return BenchmarkKind.loadReps;
  }

  Future<void> _pick() async {
    final id = await _pickExerciseFor(
      context,
      suggested: widget.suggested,
      title: 'QUEL MOUVEMENT ?',
    );
    if (id == null || !mounted) return;
    setState(() {
      _exercise = id;
      final e = _ex;
      if (e != null) _kind = _defaultKind(e);
      if (_bodyweightish && _bw.text.isEmpty && widget.profileWeight != null) {
        _bw.text = numText(widget.profileWeight!);
      }
    });
  }

  Future<void> _pickDate() async {
    final now = dateOfCivil(widget.today);
    final d = await showDatePicker(
      context: context,
      initialDate: _date == null ? now : dateOfCivil(_date!),
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (d == null || !mounted) return;
    setState(() {
      _date = civilOf(d);
      _dateChoice = 'date';
    });
  }

  void _save() {
    final e = _exercise, k = _kind;
    if (e == null || k == null) {
      setState(() => _error = 'Choisis le mouvement et le genre de record.');
      return;
    }
    final load = _parseNum(_load.text);
    final reps = int.tryParse(_reps.text.trim());
    final secs = _parseDuration(_seconds.text);
    final km = _parseNum(_distance.text);
    final bw = _parseNum(_bw.text);
    final needLoad = k == BenchmarkKind.loadReps;
    final needReps =
        k == BenchmarkKind.loadReps ||
        k == BenchmarkKind.maxReps ||
        k == BenchmarkKind.repsForTime;
    final needSecs =
        k == BenchmarkKind.maxHold ||
        k == BenchmarkKind.timeTrial ||
        k == BenchmarkKind.distanceTrial ||
        k == BenchmarkKind.repsForTime;
    final needDist =
        k == BenchmarkKind.timeTrial || k == BenchmarkKind.distanceTrial;
    if ((needLoad && load == null) ||
        (needReps && reps == null) ||
        (needSecs && secs == null) ||
        (needDist && km == null)) {
      setState(() => _error = 'Remplis chaque valeur demandée.');
      return;
    }
    final b = Benchmark(
      exerciseId: e,
      kind: k,
      source: _source,
      date: _date,
      externalLoadKg: needLoad ? load : null,
      reps: needReps ? reps : null,
      rir: k == BenchmarkKind.loadReps ? _rir : null,
      seconds: needSecs ? secs : null,
      distanceMeters: needDist ? km! * 1000 : null,
      bodyWeightKg: _bodyweightish && bw != null ? bw : null,
      competitionStandard: widget.askStandard ? _standard : null,
    );
    final err = _firstViolation(b.validate());
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, b);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final k = _kind;
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      bool decimal = false,
      String? hint,
    }) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: ValueKey(key),
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(labelText: label, helperText: hint),
      ),
    );
    return SingleChildScrollView(
      key: const ValueKey('benchmark-sheet'),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Un record' : 'Modifier le record',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _sheetLabel(context, itemText(q, 'exerciseId', 'Quel mouvement ?')),
          OutlinedButton(
            key: const ValueKey('benchmark-exercise'),
            onPressed: _pick,
            child: Text(
              _exercise == null ? 'Choisir le mouvement' : _exerciseName(_exercise!),
            ),
          ),
          if (_exercise != null) ...[
            _sheetLabel(context, itemText(q, 'kind', 'Quel genre de record ?')),
            for (final o in itemOptions(q, 'kind'))
              _ChoiceRow(
                key: ValueKey('benchmark-kind-${o.$1}'),
                label: o.$2,
                selected: k?.code == o.$1,
                onTap: () =>
                    setState(() => _kind = BenchmarkKind.fromCode(o.$1)),
              ),
          ],
          if (k == BenchmarkKind.loadReps)
            field(
              'benchmark-load',
              _load,
              itemText(q, 'externalLoadKg', 'Quelle charge ?'),
              decimal: true,
              hint: 'En kg',
            ),
          if (k == BenchmarkKind.loadReps ||
              k == BenchmarkKind.maxReps ||
              k == BenchmarkKind.repsForTime)
            field(
              'benchmark-reps',
              _reps,
              itemText(q, 'reps', 'Combien de répétitions ?'),
            ),
          if (k == BenchmarkKind.loadReps) ...[
            _sheetLabel(
              context,
              itemText(q, 'rir', 'Il t’en restait combien sous le pied ?'),
            ),
            _sheetChips<String>(
              keyPrefix: 'benchmark-rir',
              options: itemOptions(q, 'rir'),
              selected: (c) => _rir != null && _rir!.round().toString() == c,
              onTap: (c) => setState(() {
                final v = double.parse(c);
                _rir = _rir == v ? null : v;
              }),
            ),
          ],
          if (k == BenchmarkKind.timeTrial || k == BenchmarkKind.distanceTrial)
            field(
              'benchmark-distance',
              _distance,
              itemText(q, 'distanceMeters', 'Quelle distance ?'),
              decimal: true,
              hint: 'En km',
            ),
          if (k == BenchmarkKind.maxHold ||
              k == BenchmarkKind.timeTrial ||
              k == BenchmarkKind.distanceTrial ||
              k == BenchmarkKind.repsForTime)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: const ValueKey('benchmark-seconds'),
                controller: _seconds,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: itemText(q, 'seconds', 'Combien de temps ?'),
                  helperText: 'En secondes, ou min:s (ex. 1:30)',
                ),
              ),
            ),
          if (_bodyweightish)
            field(
              'benchmark-bw',
              _bw,
              itemText(q, 'bodyWeightKg', 'Ton poids ce jour-là ?'),
              decimal: true,
              hint: 'En kg, facultatif',
            ),
          _sheetLabel(context, itemText(q, 'date', 'C’était quand ?')),
          _sheetChips<String>(
            keyPrefix: 'benchmark-date',
            options: const [
              ('month', 'Ce mois-ci'),
              ('recent', 'Il y a 1 à 3 mois'),
              ('date', 'Choisir une date'),
              ('none', 'Je ne sais plus'),
            ],
            selected: (c) => _dateChoice == c,
            onTap: (c) {
              switch (c) {
                case 'month':
                  setState(() {
                    _dateChoice = c;
                    _date = widget.today;
                  });
                case 'recent':
                  setState(() {
                    _dateChoice = c;
                    _date = widget.today.addDays(-61);
                  });
                case 'date':
                  _pickDate();
                default:
                  setState(() {
                    _dateChoice = c;
                    _date = null;
                  });
              }
            },
          ),
          if (_date != null && _dateChoice == 'date')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _sheetHint(context, longDateText(_date!)),
            ),
          _sheetLabel(context, itemText(q, 'source', 'D’où vient ce chiffre ?')),
          for (final o in itemOptions(q, 'source'))
            _ChoiceRow(
              key: ValueKey('benchmark-source-${o.$1}'),
              label: o.$2,
              selected: _source.code == o.$1,
              onTap: () =>
                  setState(() => _source = BenchmarkSource.fromCode(o.$1)),
            ),
          if (widget.askStandard) ...[
            _sheetLabel(
              context,
              itemText(
                q,
                'competitionStandard',
                'C’était au standard de compétition ?',
              ),
            ),
            _sheetChips<String>(
              keyPrefix: 'benchmark-standard',
              options: const [
                ('true', 'Oui'),
                ('false', 'Non'),
                ('unknown', 'Je ne sais pas'),
              ],
              selected: (c) =>
                  (c == 'unknown' && _standard == null) || '$_standard' == c,
              onTap: (c) => setState(
                () => _standard = c == 'unknown' ? null : c == 'true',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('benchmark-error'),
              style: TextStyle(color: SL.danger),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('benchmark-save'),
            onPressed: _save,
            child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Figure : cible, étape actuelle, meilleur maintien ou répétitions,
/// ancienneté à l'étape.
class _SkillSheet extends StatefulWidget {
  final ProfileQuestion question;
  final Catalog catalog;
  final List<String> targets;
  final Set<String> taken;
  final SkillState? initial;
  const _SkillSheet({
    required this.question,
    required this.catalog,
    required this.targets,
    required this.taken,
    this.initial,
  });

  @override
  State<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends State<_SkillSheet> {
  String? _target, _current;
  StepTenure? _tenure;
  final _hold = TextEditingController();
  final _reps = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      _target = s.targetExerciseId;
      _current = s.currentExerciseId;
      _tenure = s.atStepSince;
      if (s.bestHoldSeconds != null) _hold.text = '${s.bestHoldSeconds}';
      if (s.bestReps != null) _reps.text = '${s.bestReps}';
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _pickTarget() async {
    final id = await _pickExerciseFor(
      context,
      only: [
        for (final t in widget.targets)
          if (!widget.taken.contains(t)) t,
      ],
      title: 'QUELLE FIGURE ?',
    );
    if (id == null || !mounted) return;
    setState(() {
      _target = id;
      _current = null;
    });
  }

  void _save() {
    final t = _target, c = _current;
    if (t == null || c == null) {
      setState(() => _error = 'Choisis la figure et ton étape.');
      return;
    }
    final s = SkillState(
      targetExerciseId: t,
      currentExerciseId: c,
      bestHoldSeconds: int.tryParse(_hold.text.trim()),
      bestReps: int.tryParse(_reps.text.trim()),
      atStepSince: _tenure,
    );
    final err = _firstViolation(s.validate());
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, s);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final t = _target;
    final steps = t == null
        ? const <CatalogExercise>[]
        : widget.catalog.progressionCandidates(t);
    return SingleChildScrollView(
      key: const ValueKey('skill-sheet'),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Une figure', style: Theme.of(context).textTheme.titleLarge),
          _sheetLabel(
            context,
            itemText(q, 'targetExerciseId', 'Quelle figure vises-tu ?'),
          ),
          OutlinedButton(
            key: const ValueKey('skill-target'),
            onPressed: _pickTarget,
            child: Text(t == null ? 'Choisir la figure' : _exerciseName(t)),
          ),
          if (t != null) ...[
            _sheetLabel(
              context,
              itemText(q, 'currentExerciseId', 'Où en es-tu ?'),
            ),
            for (final e in steps)
              _ChoiceRow(
                key: ValueKey('skill-step-${e.id}'),
                label: e.id == t ? '${e.name} (la figure elle-même)' : e.name,
                selected: _current == e.id,
                onTap: () => setState(() => _current = e.id),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: const ValueKey('skill-hold'),
                controller: _hold,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: itemText(
                    q,
                    'bestHoldSeconds',
                    'Ton meilleur maintien propre sur cette étape ?',
                  ),
                  helperText: 'En secondes, facultatif',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                key: const ValueKey('skill-reps'),
                controller: _reps,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: itemText(
                    q,
                    'bestReps',
                    'Ou ton meilleur nombre de répétitions propres ?',
                  ),
                  helperText: 'Facultatif',
                ),
              ),
            ),
            _sheetLabel(
              context,
              itemText(q, 'atStepSince', 'Depuis quand tu en es là ?'),
            ),
            _sheetChips<String>(
              keyPrefix: 'skill-tenure',
              options: itemOptions(q, 'atStepSince'),
              selected: (c) => _tenure?.code == c,
              onTap: (c) => setState(
                () => _tenure = _tenure?.code == c
                    ? null
                    : StepTenure.fromCode(c),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: SL.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('skill-save'),
            onPressed: _save,
            child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Spécialisation : nature, cible, durée, le reste.
class _SpecializationSheet extends StatefulWidget {
  final ProfileQuestion question;
  final Catalog catalog;
  final Specialization? initial;
  final bool mainEvent, preferMuscle;
  final List<String> competitionLifts, figures;
  const _SpecializationSheet({
    required this.question,
    required this.catalog,
    this.initial,
    required this.mainEvent,
    required this.competitionLifts,
    required this.figures,
    required this.preferMuscle,
  });

  @override
  State<_SpecializationSheet> createState() => _SpecializationSheetState();
}

class _SpecializationSheetState extends State<_SpecializationSheet> {
  late SpecializationKind _kind;
  String? _exercise, _muscle;
  MovementPattern? _pattern;
  int? _weeks;
  MaintenancePolicy? _maintenance;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _kind =
        s?.kind ??
        (widget.mainEvent
            ? SpecializationKind.exercise
            : widget.preferMuscle
            ? SpecializationKind.muscle
            : SpecializationKind.exercise);
    _exercise = s?.exerciseId;
    _muscle = s?.muscle;
    _pattern = s?.pattern;
    _weeks = s?.weeks;
    _maintenance = widget.mainEvent
        ? MaintenancePolicy.maintain
        : s?.maintenance;
  }

  Future<void> _pickExercise() async {
    final skill = _kind == SpecializationKind.skill;
    final only = skill
        ? widget.figures
        : (widget.mainEvent && widget.competitionLifts.isNotEmpty
              ? widget.competitionLifts
              : null);
    final id = await _pickExerciseFor(
      context,
      only: only,
      title: skill ? 'QUELLE FIGURE ?' : 'QUEL MOUVEMENT ?',
    );
    if (id == null || !mounted) return;
    setState(() => _exercise = id);
  }

  void _save() {
    final s = Specialization(
      kind: _kind,
      exerciseId:
          _kind == SpecializationKind.exercise ||
              _kind == SpecializationKind.skill
          ? _exercise
          : null,
      muscle: _kind == SpecializationKind.muscle ? _muscle : null,
      pattern: _kind == SpecializationKind.pattern ? _pattern : null,
      weeks: _weeks,
      maintenance: widget.mainEvent
          ? MaintenancePolicy.maintain
          : _maintenance,
    );
    final err = _firstViolation(s.validate());
    if (err != null) {
      setState(() => _error = 'Choisis ce que tu veux faire passer avant.');
      return;
    }
    Navigator.pop(context, s);
  }

  static const _patterns = [
    (MovementPattern.tirageVertical, 'Tirage vertical (tractions)'),
    (MovementPattern.tirageHorizontal, 'Tirage horizontal (rowing)'),
    (MovementPattern.pousseeHorizontale, 'Poussée horizontale (pompes, développé)'),
    (MovementPattern.pousseeVerticaleHaute, 'Poussée au-dessus de la tête'),
    (MovementPattern.pousseeVerticaleBasse, 'Poussée vers le bas (dips)'),
    (MovementPattern.squat, 'Squat'),
    (MovementPattern.charniereHanche, 'Charnière de hanche (soulevé de terre)'),
    (MovementPattern.fente, 'Fente'),
  ];

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final kinds = widget.mainEvent
        ? [(SpecializationKind.exercise.code, 'Un mouvement de compétition')]
        : itemOptions(q, 'kind');
    return SingleChildScrollView(
      key: const ValueKey('specialization-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ta priorité', style: Theme.of(context).textTheme.titleLarge),
          _sheetLabel(context, itemText(q, 'kind', 'Quoi ?')),
          for (final o in kinds)
            _ChoiceRow(
              key: ValueKey('spec-kind-${o.$1}'),
              label: o.$2,
              selected: _kind.code == o.$1,
              onTap: () => setState(() {
                _kind = SpecializationKind.fromCode(o.$1);
                _exercise = null;
              }),
            ),
          _sheetLabel(context, 'Lequel ?'),
          if (_kind == SpecializationKind.exercise ||
              _kind == SpecializationKind.skill)
            OutlinedButton(
              key: const ValueKey('spec-target'),
              onPressed: _pickExercise,
              child: Text(
                _exercise == null ? 'Choisir' : _exerciseName(_exercise!),
              ),
            )
          else if (_kind == SpecializationKind.muscle)
            DropdownButtonFormField<String>(
              key: const ValueKey('spec-muscle'),
              isExpanded: true,
              initialValue: widget.catalog.muscles.contains(_muscle)
                  ? _muscle
                  : null,
              decoration: const InputDecoration(labelText: 'Muscle'),
              items: [
                for (final m in widget.catalog.muscles)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: (v) => setState(() => _muscle = v),
            )
          else
            for (final p in _patterns)
              _ChoiceRow(
                key: ValueKey('spec-pattern-${p.$1.code}'),
                label: p.$2,
                selected: _pattern == p.$1,
                onTap: () => setState(() => _pattern = p.$1),
              ),
          _sheetLabel(context, itemText(q, 'weeks', 'Pendant combien de temps ?')),
          _sheetChips<String>(
            keyPrefix: 'spec-weeks',
            options: itemOptions(q, 'weeks'),
            selected: (c) => '$_weeks' == c,
            onTap: (c) => setState(
              () => _weeks = '$_weeks' == c ? null : int.parse(c),
            ),
          ),
          if (!widget.mainEvent) ...[
            _sheetLabel(context, itemText(q, 'maintenance', 'Et le reste ?')),
            for (final o in itemOptions(q, 'maintenance'))
              _ChoiceRow(
                key: ValueKey('spec-maintenance-${o.$1}'),
                label: o.$2,
                selected: _maintenance?.code == o.$1,
                onTap: () => setState(
                  () => _maintenance = MaintenancePolicy.fromCode(o.$1),
                ),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: SL.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('spec-save'),
            onPressed: _save,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Autre sport : nature, fréquence, durée, jours, intensité, régions.
class _OtherSportSheet extends StatefulWidget {
  final ProfileQuestion question;
  final OtherSport? initial;
  const _OtherSportSheet({required this.question, this.initial});

  @override
  State<_OtherSportSheet> createState() => _OtherSportSheetState();
}

class _OtherSportSheetState extends State<_OtherSportSheet> {
  OtherSportKind? _kind;
  int _sessions = 1;
  int _minutes = 60;
  final Set<int> _days = {};
  bool? _hard, _main;
  final Set<BodyRegion> _regions = {};
  String? _error;

  static const _knownRegions = {
    OtherSportKind.running,
    OtherSportKind.cycling,
    OtherSportKind.swimming,
    OtherSportKind.climbing,
  };

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      _kind = s.kind;
      _sessions = s.sessionsPerWeek;
      _minutes = s.minutesPerSession;
      _days.addAll(s.weekdays ?? const <int>[]);
      _hard = s.hard;
      _main = s.mainSport;
      _regions.addAll(s.regions ?? const <BodyRegion>[]);
    }
  }

  void _save() {
    final k = _kind;
    if (k == null) {
      setState(() => _error = 'Choisis le sport.');
      return;
    }
    final s = OtherSport(
      kind: k,
      sessionsPerWeek: _sessions,
      minutesPerSession: _minutes,
      weekdays: _days.isEmpty ? null : (_days.toList()..sort()),
      regions: _knownRegions.contains(k) || _regions.isEmpty
          ? null
          : [
              for (final r in BodyRegion.values)
                if (_regions.contains(r)) r,
            ],
      hard: _hard,
      mainSport: _main,
    );
    final err = _firstViolation(s.validate());
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, s);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final k = _kind;
    return SingleChildScrollView(
      key: const ValueKey('sport-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Un autre sport', style: Theme.of(context).textTheme.titleLarge),
          _sheetLabel(context, itemText(q, 'kind', 'Quel sport ?')),
          _sheetChips<String>(
            keyPrefix: 'sport-kind',
            options: itemOptions(q, 'kind'),
            selected: (c) => k?.code == c,
            onTap: (c) => setState(() {
              _kind = OtherSportKind.fromCode(c);
              if (_kind == OtherSportKind.combatSport && _regions.isEmpty) {
                _regions.add(BodyRegion.wholeBody);
              }
            }),
          ),
          _sheetLabel(
            context,
            itemText(q, 'sessionsPerWeek', 'Combien de fois par semaine ?'),
          ),
          _sheetChips<int>(
            keyPrefix: 'sport-sessions',
            options: [for (var n = 1; n <= 7; n++) (n, '$n')],
            selected: (n) => _sessions == n,
            onTap: (n) => setState(() => _sessions = n),
          ),
          _sheetLabel(
            context,
            itemText(q, 'minutesPerSession', 'Combien de temps à chaque fois ?'),
          ),
          _sheetChips<int>(
            keyPrefix: 'sport-minutes',
            options: [
              for (final m in {30, 45, 60, 90, 120, _minutes}.toList()..sort())
                (m, '$m min'),
            ],
            selected: (m) => _minutes == m,
            onTap: (m) => setState(() => _minutes = m),
          ),
          _sheetLabel(context, itemText(q, 'weekdays', 'Toujours les mêmes jours ?')),
          _sheetChips<int>(
            keyPrefix: 'sport-day',
            multi: true,
            options: [for (var d = 1; d <= 7; d++) (d, weekdayTitle(d))],
            selected: _days.contains,
            onTap: (d) =>
                setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d)),
          ),
          _sheetLabel(
            context,
            itemText(q, 'hard', 'C’est intense (matchs, combats, fractionné) ?'),
          ),
          _sheetChips<String>(
            keyPrefix: 'sport-hard',
            options: const [('true', 'Oui'), ('false', 'Non')],
            selected: (c) => '$_hard' == c,
            onTap: (c) => setState(() => _hard = c == 'true'),
          ),
          _sheetLabel(context, itemText(q, 'mainSport', 'C’est ton sport principal ?')),
          _sheetChips<String>(
            keyPrefix: 'sport-main',
            options: const [('true', 'Oui'), ('false', 'Non')],
            selected: (c) => '$_main' == c,
            onTap: (c) => setState(() => _main = c == 'true'),
          ),
          if (k != null && !_knownRegions.contains(k)) ...[
            _sheetLabel(
              context,
              itemText(q, 'regions', 'Ça fait surtout travailler…'),
            ),
            _sheetChips<String>(
              keyPrefix: 'sport-region',
              multi: true,
              options: itemOptions(q, 'regions'),
              selected: (c) => _regions.any((r) => r.code == c),
              onTap: (c) => setState(() {
                final r = BodyRegion.fromCode(c);
                if (!_regions.remove(r)) _regions.add(r);
              }),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: SL.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('sport-save'),
            onPressed: _save,
            child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

/// Ligne éditable d'une épreuve (mouvement de compétition ou poste).
class _LiftDraft {
  String exerciseId;
  int attempts;
  double? minIncrementKg;
  final TextEditingController best, target;
  _LiftDraft(this.exerciseId, {this.attempts = 3, this.minIncrementKg})
    : best = TextEditingController(),
      target = TextEditingController();
}

class _StationDraft {
  String exerciseId;
  bool unbroken = false;
  final TextEditingController reps, seconds, load, limit;
  _StationDraft(this.exerciseId)
    : reps = TextEditingController(),
      seconds = TextEditingController(),
      load = TextEditingController(),
      limit = TextEditingController();
}

/// Échéance : nature, date (ou mois), priorité, nom, et selon la nature
/// les mouvements et tentatives, le format des postes, la distance.
class _EventSheet extends StatefulWidget {
  final ProfileQuestion question;
  final List<Map<String, Object?>> presets;
  final CivilDate today;
  final SeasonEvent? initial;
  final String id;
  final Sex? sex;
  final double? profileWeight;
  const _EventSheet({
    required this.question,
    required this.presets,
    required this.today,
    this.initial,
    required this.id,
    this.sex,
    this.profileWeight,
  });

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  EventKind? _kind;
  CivilDate? _date;
  bool _approximate = false;
  bool _monthPicker = false;
  EventPriority? _priority;
  final _name = TextEditingController();
  String? _ruleset;
  double? _weightClass;
  bool _openClass = false;
  final _plannedWeight = TextEditingController();
  final List<_LiftDraft> _lifts = [];
  RepsEventMode? _mode;
  bool _formatUnknown = false;
  final List<_StationDraft> _stations = [];
  final _heats = TextEditingController();
  final _bestReps = TextEditingController();
  final _bestTime = TextEditingController();
  double? _distance;
  final _otherDistance = TextEditingController();
  final _targetTime = TextEditingController();
  final List<String> _elements = [];
  String? _error;

  static const _raceDistances = [
    (5000.0, '5 km'),
    (10000.0, '10 km'),
    (21097.5, 'Semi-marathon'),
    (42195.0, 'Marathon'),
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (widget.profileWeight != null) {
      _plannedWeight.text = numText(widget.profileWeight!);
    }
    if (e == null) return;
    _kind = e.kind;
    _date = e.date;
    _approximate = e.dateApproximate == true;
    _priority = e.priority;
    _name.text = e.name ?? '';
    _ruleset = e.ruleset;
    _weightClass = e.weightClassKg;
    _openClass = e.openWeightClass == true;
    _plannedWeight.text = e.plannedBodyWeightKg == null
        ? _plannedWeight.text
        : numText(e.plannedBodyWeightKg!);
    for (final l in e.lifts ?? const <CompetitionLift>[]) {
      final d = _LiftDraft(
        l.exerciseId,
        attempts: l.attempts,
        minIncrementKg: l.minIncrementKg,
      );
      if (l.bestKg != null) d.best.text = numText(l.bestKg!);
      if (l.targetKg != null) d.target.text = numText(l.targetKg!);
      _lifts.add(d);
    }
    _mode = e.mode;
    _formatUnknown = e.formatKnown == false;
    for (final s in e.stations ?? const <EventStation>[]) {
      final d = _StationDraft(s.exerciseId)..unbroken = s.unbroken == true;
      if (s.reps != null) d.reps.text = '${s.reps}';
      if (s.seconds != null) d.seconds.text = '${s.seconds}';
      if (s.externalLoadKg != null) d.load.text = numText(s.externalLoadKg!);
      if (s.timeLimitSeconds != null) d.limit.text = '${s.timeLimitSeconds}';
      _stations.add(d);
    }
    if (e.heats != null) _heats.text = '${e.heats}';
    if (e.bestTotalReps != null) _bestReps.text = '${e.bestTotalReps}';
    if (e.bestSeconds != null) _bestTime.text = _durationField(e.bestSeconds!);
    _distance = e.distanceMeters;
    if (_distance != null &&
        !_raceDistances.any((r) => r.$1 == _distance)) {
      _otherDistance.text = numText(_distance! / 1000);
    }
    if (e.targetSeconds != null) {
      _targetTime.text = _durationField(e.targetSeconds!);
    }
    _elements.addAll(e.elements ?? const <String>[]);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _plannedWeight,
      _heats,
      _bestReps,
      _bestTime,
      _otherDistance,
      _targetTime,
    ]) {
      c.dispose();
    }
    for (final l in _lifts) {
      l.best.dispose();
      l.target.dispose();
    }
    for (final s in _stations) {
      s.reps.dispose();
      s.seconds.dispose();
      s.load.dispose();
      s.limit.dispose();
    }
    super.dispose();
  }

  List<Map<String, Object?>> get _kindPresets => [
    for (final p in widget.presets)
      if (p['kind'] == _kind?.code) p,
  ];

  void _applyPreset(Map<String, Object?> p) {
    _ruleset = p['code'] as String?;
    if (_kind == EventKind.strengthCompetition) {
      _lifts.clear();
      for (final l in (p['lifts'] as List? ?? const [])) {
        final m = (l as Map).cast<String, Object?>();
        _lifts.add(
          _LiftDraft(
            m['exerciseId']! as String,
            attempts: (m['attempts'] as num?)?.toInt() ?? 3,
            minIncrementKg: (m['minIncrementKg'] as num?)?.toDouble(),
          ),
        );
      }
    } else if (_kind == EventKind.repsCompetition) {
      final mode = p['mode'];
      if (mode is String) _mode = RepsEventMode.fromCode(mode);
      _stations.clear();
      _formatUnknown = false;
      for (final s in (p['stations'] as List? ?? const [])) {
        final m = (s as Map).cast<String, Object?>();
        final d = _StationDraft(m['exerciseId']! as String);
        final limit = m['timeLimitSeconds'];
        if (limit is num) d.limit.text = '${limit.toInt()}';
        _stations.add(d);
      }
    }
  }

  List<double> get _classes {
    final p = _kindPresets.where((x) => x['code'] == _ruleset).firstOrNull;
    final byKey = p?['weightClassesKg'];
    if (byKey is! Map) return const [];
    List<double> of(String k) => [
      for (final v in (byKey[k] as List? ?? const [])) (v as num).toDouble(),
    ];
    return switch (widget.sex) {
      Sex.female => of('female'),
      Sex.male => of('male'),
      _ => ({...of('female'), ...of('male')}.toList()..sort()),
    };
  }

  Future<void> _pickDay() async {
    final first = dateOfCivil(widget.today);
    final d = await showDatePicker(
      context: context,
      initialDate: _date == null || _date! < widget.today
          ? first
          : dateOfCivil(_date!),
      firstDate: first,
      lastDate: DateTime(first.year + 3, 12, 31),
    );
    if (d == null || !mounted) return;
    setState(() {
      _date = civilOf(d);
      _approximate = false;
      _monthPicker = false;
    });
  }

  void _save() {
    final k = _kind, date = _date, prio = _priority;
    if (k == null || date == null || prio == null) {
      setState(() => _error = 'Choisis la nature, la date et la priorité.');
      return;
    }
    List<CompetitionLift>? lifts;
    List<EventStation>? stations;
    if (k == EventKind.strengthCompetition) {
      if (_lifts.isEmpty) {
        setState(() => _error = 'Ajoute au moins un mouvement.');
        return;
      }
      lifts = [
        for (final l in _lifts)
          CompetitionLift(
            exerciseId: l.exerciseId,
            attempts: l.attempts,
            minIncrementKg: l.minIncrementKg,
            bestKg: _parseNum(l.best.text),
            targetKg: _parseNum(l.target.text),
          ),
      ];
    }
    if (k == EventKind.repsCompetition) {
      if (_mode == null) {
        setState(() => _error = 'Choisis le format.');
        return;
      }
      if (!_formatUnknown && _stations.isNotEmpty) {
        stations = [
          for (final s in _stations)
            EventStation(
              exerciseId: s.exerciseId,
              reps: int.tryParse(s.reps.text.trim()),
              seconds: int.tryParse(s.reps.text.trim()) == null
                  ? int.tryParse(s.seconds.text.trim())
                  : null,
              externalLoadKg: _parseNum(s.load.text),
              unbroken: s.unbroken ? true : null,
              timeLimitSeconds: int.tryParse(s.limit.text.trim()),
            ),
        ];
      }
    }
    double? distance;
    if (k == EventKind.race) {
      distance = _parseNum(_otherDistance.text) == null
          ? _distance
          : _parseNum(_otherDistance.text)! * 1000;
      if (distance == null) {
        setState(() => _error = 'Choisis la distance.');
        return;
      }
    }
    final repsKind = k == EventKind.repsCompetition;
    final strength = k == EventKind.strengthCompetition;
    final name = _name.text.trim();
    final e = SeasonEvent(
      id: widget.id,
      kind: k,
      priority: prio,
      date: date,
      name: name.isEmpty ? null : name,
      ruleset: _ruleset,
      weightClassKg: strength ? _weightClass : null,
      openWeightClass: strength && _openClass ? true : null,
      plannedBodyWeightKg: strength || repsKind
          ? _parseNum(_plannedWeight.text)
          : null,
      lifts: lifts,
      mode: repsKind ? _mode : null,
      stations: stations,
      formatKnown: repsKind && _formatUnknown ? false : null,
      heats: repsKind || strength ? int.tryParse(_heats.text.trim()) : null,
      bestTotalReps: repsKind ? int.tryParse(_bestReps.text.trim()) : null,
      bestSeconds: repsKind || k == EventKind.race
          ? _parseDuration(_bestTime.text)
          : null,
      distanceMeters: distance,
      targetSeconds: k == EventKind.race || repsKind
          ? _parseDuration(_targetTime.text)
          : null,
      elements: k == EventKind.freestyleCompetition && _elements.isNotEmpty
          ? List.of(_elements)
          : null,
      dateApproximate: _approximate ? true : null,
    );
    final err = _firstViolation(e.validate());
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, e);
  }

  Widget _num(
    String key,
    TextEditingController c,
    String label, {
    bool decimal = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextField(
      key: ValueKey(key),
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, helperText: hint),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final k = _kind;
    final months = [
      for (var i = 0; i < 18; i++)
        CivilDate(
          widget.today.year + (widget.today.month - 1 + i) ~/ 12,
          (widget.today.month - 1 + i) % 12 + 1,
          15,
        ),
    ];
    return SingleChildScrollView(
      key: const ValueKey('event-sheet'),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Une date en vue', style: Theme.of(context).textTheme.titleLarge),
          _sheetLabel(context, itemText(q, 'kind', 'C’est quoi ?')),
          for (final o in itemOptions(q, 'kind'))
            _ChoiceRow(
              key: ValueKey('event-kind-${o.$1}'),
              label: o.$2,
              selected: k?.code == o.$1,
              onTap: () => setState(() {
                _kind = EventKind.fromCode(o.$1);
                _ruleset = null;
              }),
            ),
          _sheetLabel(context, itemText(q, 'date', 'Quel jour ?')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const ValueKey('event-date-pick'),
                onPressed: _pickDay,
                child: Text(
                  _date != null && !_approximate
                      ? longDateText(_date!)
                      : 'Choisir le jour',
                ),
              ),
              OutlinedButton(
                key: const ValueKey('event-date-month'),
                onPressed: () => setState(() => _monthPicker = !_monthPicker),
                child: Text(
                  _date != null && _approximate
                      ? 'Vers ${monthText(_date!)}'
                      : 'Pas encore fixée : un mois',
                ),
              ),
            ],
          ),
          if (_monthPicker) ...[
            const SizedBox(height: 8),
            _sheetChips<int>(
              keyPrefix: 'event-month',
              options: [
                for (var i = 0; i < months.length; i++)
                  (i, monthText(months[i])),
              ],
              selected: (i) => _approximate && _date == months[i],
              onTap: (i) => setState(() {
                _date = months[i];
                _approximate = true;
                _monthPicker = false;
              }),
            ),
          ],
          _sheetLabel(context, itemText(q, 'priority', 'Elle compte comment ?')),
          for (final o in itemOptions(q, 'priority'))
            _ChoiceRow(
              key: ValueKey('event-priority-${o.$1}'),
              label: o.$2,
              selected: _priority?.code == o.$1,
              onTap: () =>
                  setState(() => _priority = EventPriority.fromCode(o.$1)),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              key: const ValueKey('event-name'),
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(
                labelText: '${itemText(q, 'name', 'Son nom ?')} (facultatif)',
              ),
            ),
          ),
          if (k == EventKind.strengthCompetition ||
              k == EventKind.repsCompetition) ...[
            if (_kindPresets.isNotEmpty) ...[
              _sheetLabel(context, itemText(q, 'ruleset', 'Quel règlement ?')),
              _sheetChips<String>(
                keyPrefix: 'event-preset',
                options: [
                  for (final p in _kindPresets)
                    ('${p['code']}', '${p['label']}'),
                  ('other', 'Autre'),
                ],
                selected: (c) =>
                    c == 'other' ? _ruleset == null : _ruleset == c,
                onTap: (c) => setState(() {
                  if (c == 'other') {
                    _ruleset = null;
                  } else {
                    _applyPreset(
                      _kindPresets.firstWhere((p) => p['code'] == c),
                    );
                  }
                }),
              ),
              _sheetHint(
                context,
                'Le règlement pré-remplit les mouvements : tout reste '
                'modifiable.',
              ),
            ],
          ],
          if (k == EventKind.strengthCompetition) ..._strength(context),
          if (k == EventKind.repsCompetition) ..._reps(context),
          if (k == EventKind.race) ..._race(context),
          if (k == EventKind.freestyleCompetition) ..._freestyle(context),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              key: const ValueKey('event-error'),
              style: TextStyle(color: SL.danger),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('event-save'),
            onPressed: _save,
            child: Text(widget.initial == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  List<Widget> _strength(BuildContext context) {
    final q = widget.question;
    final classes = _classes;
    return [
      _sheetLabel(context, itemText(q, 'lifts', 'Les mouvements, dans l’ordre')),
      for (var i = 0; i < _lifts.length; i++)
        KCard(
          key: ValueKey('event-lift-$i'),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_exerciseName(_lifts[i].exerciseId))),
                  IconButton(
                    key: ValueKey('event-lift-remove-$i'),
                    tooltip: 'Retirer ce mouvement',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lifts.removeAt(i)),
                  ),
                ],
              ),
              _sheetHint(context, 'Tentatives'),
              _sheetChips<int>(
                keyPrefix: 'event-lift-$i-attempts',
                options: const [(1, '1'), (2, '2'), (3, '3'), (4, '4')],
                selected: (n) => _lifts[i].attempts == n,
                onTap: (n) => setState(() => _lifts[i].attempts = n),
              ),
              _num(
                'event-lift-$i-best',
                _lifts[i].best,
                'Ta meilleure barre (kg, facultatif)',
                decimal: true,
              ),
              _num(
                'event-lift-$i-target',
                _lifts[i].target,
                'Ta barre visée (kg, facultatif)',
                decimal: true,
              ),
            ],
          ),
        ),
      TextButton.icon(
        key: const ValueKey('event-lift-add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un mouvement'),
        onPressed: () async {
          final id = await _pickExerciseFor(context);
          if (id == null || !mounted) return;
          setState(() => _lifts.add(_LiftDraft(id)));
        },
      ),
      _sheetLabel(
        context,
        itemText(q, 'weightClassKg', 'Ta catégorie de poids ?'),
      ),
      if (classes.isNotEmpty) ...[
        _sheetChips<String>(
          keyPrefix: 'event-class',
          options: [
            for (final c in classes) (numText(c), '${numText(c)} kg'),
            ('open', 'Plus de ${numText(classes.last)} kg'),
          ],
          selected: (c) => c == 'open'
              ? _openClass
              : !_openClass && _weightClass != null &&
                    numText(_weightClass!) == c,
          onTap: (c) => setState(() {
            if (c == 'open') {
              _openClass = true;
              _weightClass = classes.last;
            } else {
              _openClass = false;
              _weightClass = _parseNum(c);
            }
          }),
        ),
      ] else
        _sheetHint(
          context,
          'Saisis ta catégorie dans le nom si le règlement en a.',
        ),
      _num(
        'event-planned-weight',
        _plannedWeight,
        itemText(
          q,
          'plannedBodyWeightKg',
          'Tu comptes peser combien ce jour-là ?',
        ),
        decimal: true,
        hint: 'En kg, facultatif',
      ),
    ];
  }

  List<Widget> _reps(BuildContext context) {
    final q = widget.question;
    return [
      _sheetLabel(context, itemText(q, 'mode', 'Le format')),
      for (final o in itemOptions(q, 'mode'))
        _ChoiceRow(
          key: ValueKey('event-mode-${o.$1}'),
          label: o.$2,
          selected: _mode?.code == o.$1,
          onTap: () => setState(() => _mode = RepsEventMode.fromCode(o.$1)),
        ),
      SwitchListTile(
        key: const ValueKey('event-format-unknown'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Le format sera annoncé le jour même'),
        value: _formatUnknown,
        onChanged: (v) => setState(() => _formatUnknown = v),
      ),
      if (!_formatUnknown) ...[
        _sheetLabel(
          context,
          itemText(q, 'stations', 'Les exercices, dans l’ordre'),
        ),
        for (var i = 0; i < _stations.length; i++)
          KCard(
            key: ValueKey('event-station-$i'),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_exerciseName(_stations[i].exerciseId)),
                    ),
                    IconButton(
                      key: ValueKey('event-station-remove-$i'),
                      tooltip: 'Retirer ce poste',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _stations.removeAt(i)),
                    ),
                  ],
                ),
                _num(
                  'event-station-$i-reps',
                  _stations[i].reps,
                  'Répétitions imposées (facultatif)',
                ),
                _num(
                  'event-station-$i-seconds',
                  _stations[i].seconds,
                  'Ou durée imposée, en secondes (facultatif)',
                ),
                _num(
                  'event-station-$i-load',
                  _stations[i].load,
                  'Lest (kg, facultatif)',
                  decimal: true,
                ),
                _num(
                  'event-station-$i-limit',
                  _stations[i].limit,
                  'Limite de temps du poste, en secondes (facultatif)',
                ),
                SwitchListTile(
                  key: ValueKey('event-station-$i-unbroken'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Série d’une traite'),
                  value: _stations[i].unbroken,
                  onChanged: (v) => setState(() => _stations[i].unbroken = v),
                ),
              ],
            ),
          ),
        TextButton.icon(
          key: const ValueKey('event-station-add'),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un exercice'),
          onPressed: () async {
            final id = await _pickExerciseFor(context);
            if (id == null || !mounted) return;
            setState(() => _stations.add(_StationDraft(id)));
          },
        ),
      ],
      _num(
        'event-heats',
        _heats,
        itemText(q, 'heats', 'Combien de passages dans la journée ?'),
        hint: 'Facultatif',
      ),
      _num(
        'event-best-reps',
        _bestReps,
        'Ton meilleur total de répétitions (facultatif)',
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          key: const ValueKey('event-best-time'),
          controller: _bestTime,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            labelText: 'Ou ton meilleur temps (facultatif)',
            helperText: 'min:s',
          ),
        ),
      ),
      _num(
        'event-planned-weight',
        _plannedWeight,
        itemText(
          q,
          'plannedBodyWeightKg',
          'Tu comptes peser combien ce jour-là ?',
        ),
        decimal: true,
        hint: 'En kg, facultatif',
      ),
    ];
  }

  List<Widget> _race(BuildContext context) {
    final q = widget.question;
    return [
      _sheetLabel(context, itemText(q, 'distanceMeters', 'Quelle distance ?')),
      _sheetChips<double>(
        keyPrefix: 'event-distance',
        options: _raceDistances,
        selected: (m) => _otherDistance.text.trim().isEmpty && _distance == m,
        onTap: (m) => setState(() {
          _distance = m;
          _otherDistance.clear();
        }),
      ),
      _num(
        'event-distance-other',
        _otherDistance,
        'Autre distance (km)',
        decimal: true,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          key: const ValueKey('event-target-time'),
          controller: _targetTime,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            labelText: '${itemText(q, 'targetSeconds', 'Ton temps visé ?')} '
                '(facultatif)',
            helperText: 'h:min:s ou min:s',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          key: const ValueKey('event-best-time'),
          controller: _bestTime,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            labelText: 'Ton meilleur temps sur cette distance (facultatif)',
            helperText: 'h:min:s ou min:s',
          ),
        ),
      ),
    ];
  }

  List<Widget> _freestyle(BuildContext context) => [
    _sheetLabel(
      context,
      itemText(
        widget.question,
        'elements',
        'Les figures que tu veux présenter',
      ),
    ),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final id in _elements)
          InputChip(
            label: Text(_exerciseName(id)),
            onDeleted: () => setState(() => _elements.remove(id)),
            deleteButtonTooltipMessage: 'Retirer',
          ),
      ],
    ),
    TextButton.icon(
      key: const ValueKey('event-element-add'),
      icon: const Icon(Icons.add),
      label: const Text('Ajouter une figure'),
      onPressed: () async {
        final id = await _pickExerciseFor(context);
        if (id == null || !mounted || _elements.contains(id)) return;
        setState(() => _elements.add(id));
      },
    ),
  ];
}
