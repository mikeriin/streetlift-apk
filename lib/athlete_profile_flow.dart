// G6 (D1.6, D3, D5.8, D6) : création du profil d'athlète v2, guidée par
// Koach (≈ 5 minutes, D3.4) : un écran = une question claire, retour
// arrière, barre de progression, reprise là où on s'est arrêté (brouillon
// gardé si l'application est fermée, jamais pour un âge de moins de 18
// ans). Les 12 étapes remplissent exactement le profil v2 de `kalis_core`.
//
// Le même écran sert à modifier une rubrique (Réglages › Profil) et à
// refaire son profil dans la session personnelle (D1.6) ; la porte
// d'entrée de l'application ([ProfileGate]) propose la création sur une
// installation neuve et, sinon, de refaire son profil (« Plus tard » :
// au plus une fois par jour).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'app_theme.dart';
import 'athlete_profile.dart';
import 'athlete_profile_screen.dart';
import 'content_pack.dart' show ContentIndex;
import 'exercise_screens.dart' show searchExercises, ExerciseFilters;
import 'goal_suggestions_g6.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'muscle_map_2d.dart';
import 'store.dart';
import 'ui.dart';
import 'wellbeing_screens.dart' show DisclaimerCard, MinorGate;

/// Premier écran de l'application : création du profil (installation
/// neuve), proposition de refaire son profil (session avec des données,
/// sans profil v2), blocage L13 (moins de 18 ans), puis l'application.
class ProfileGate extends StatefulWidget {
  final Widget child;
  const ProfileGate({super.key, required this.child});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  /// Flux affiché (null : aucun).
  AthleteFlowMode? _flow;

  /// « Plus tard » choisi pendant cette ouverture.
  bool _later = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (_flow == null && store.isFreshInstall) _flow = AthleteFlowMode.create;
      final flow = _flow;
      if (flow != null) {
        return AthleteProfileFlow(
          key: ValueKey('athlete-flow-${flow.name}'),
          mode: flow,
          onDone: () => setState(() => _flow = null),
          onCancel: flow == AthleteFlowMode.redo
              ? () => setState(() => _flow = null)
              : null,
        );
      }
      // L13 (KT-075) : un profil de moins de 18 ans bloque l'application
      // jusqu'à correction ou suppression des données.
      if (store.profileIsMinor) return const MinorGate();
      if (!_later && store.athleteRedoProposed) {
        return ProfileRedoProposal(
          onStart: () => setState(() => _flow = AthleteFlowMode.redo),
          onLater: () {
            setState(() => _later = true);
            unawaited(store.snoozeAthleteRedo());
          },
        );
      }
      return widget.child;
    },
  );
}

/// Koach propose de refaire la création du profil (D1.6) : rien d'autre ne
/// change ; « Plus tard » la reporte au lendemain.
class ProfileRedoProposal extends StatelessWidget {
  final VoidCallback onStart, onLater;
  const ProfileRedoProposal({
    super.key,
    required this.onStart,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final resume = store.athleteDraft?.mode == 'redo';
    return KScreen(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('TON PROFIL'),
      ),
      body: KList(
        key: const ValueKey('redo-proposal'),
        children: [
          KoachSurface(
            color: SL.bg,
            child: KoachBubble(
              pose: KoachPose.wave,
              koachHeight: 120,
              text: resume
                  ? 'On reprend ton profil là où tu t’étais arrêté ?'
                  : 'Nouveau : on crée ton profil complet ensemble, en 5 '
                        'minutes environ (disciplines, niveau par mouvement, '
                        'objectifs, matériel). Il remplace l’ancien profil.',
              why:
                  'Ton programme, ton historique et tes réglages ne changent '
                  'pas. Le nouveau profil servira à construire et à faire '
                  'évoluer tes programmes dans les prochaines versions.',
            ),
          ),
          FilledButton(
            key: const ValueKey('redo-start'),
            onPressed: onStart,
            child: Text(resume ? 'Reprendre mon profil' : 'Refaire mon profil'),
          ),
          TextButton(
            key: const ValueKey('redo-later'),
            onPressed: onLater,
            child: const Text('Plus tard'),
          ),
          Text(
            'Si tu choisis « Plus tard », je te le reproposerai demain.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Création (installation neuve), refaire son profil (D1.6) ou modifier
/// une rubrique (Réglages › Profil).
enum AthleteFlowMode { create, redo, edit }

class AthleteProfileFlow extends StatefulWidget {
  final AthleteFlowMode mode;

  /// Rubrique modifiée (mode [AthleteFlowMode.edit]).
  final String? editStep;
  final VoidCallback? onDone, onCancel;
  const AthleteProfileFlow({
    super.key,
    this.mode = AthleteFlowMode.create,
    this.editStep,
    this.onDone,
    this.onCancel,
  });

  @override
  State<AthleteProfileFlow> createState() => AthleteProfileFlowState();
}

class AthleteProfileFlowState extends State<AthleteProfileFlow>
    with WidgetsBindingObserver {
  late ProfileDraft _d;
  late String _step;
  bool _minor = false;

  /// Étape ouverte depuis le récapitulatif : « Continuer » y revient.
  bool _fromRecap = false;

  /// Profil enregistré : écran de fin.
  ({Set<String> rubrics, bool program})? _saved;

  final _year = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _nameCtl = TextEditingController();
  final _search = TextEditingController();
  String _query = '';

  bool get _edit => widget.mode == AthleteFlowMode.edit;
  String get _modeCode => widget.mode == AthleteFlowMode.redo ? 'redo' : 'create';

  /// Étape courante (tests).
  String get step => _step;

  /// Brouillon (tests).
  ProfileDraft get draft => _d;

  DateTime get _now => store.storeClock();

  @override
  void initState() {
    super.initState();
    if (_edit) {
      _d = store.athleteEditDraft();
      _step = widget.editStep ?? 'identity';
    } else {
      final saved = store.athleteDraft;
      if (saved != null && saved.mode == _modeCode) {
        _d = saved.draft;
        _step = saved.step;
      } else {
        _d = widget.mode == AthleteFlowMode.redo
            ? store.athleteRedoDraft()
            : ProfileDraft();
        _step = 'welcome';
      }
    }
    _year.text = _d.birthYear;
    _height.text = _d.height;
    _weight.text = _d.weight;
    _nameCtl.text = _d.displayName;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveDraft();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in [_year, _height, _weight, _nameCtl, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveDraft() {
    if (_edit || _saved != null) return;
    if (_minor || _d.isMinorIn(_now.year)) {
      unawaited(store.saveAthleteDraft(null));
      return;
    }
    unawaited(store.saveAthleteDraft(_d, step: _step, mode: _modeCode));
  }

  int get _index => kAthleteSteps.indexOf(_step);

  void _go(String step) {
    setState(() => _step = step);
    _saveDraft();
  }

  void _toast(String text, {KoachPose pose = KoachPose.oops}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    showKoachToast(context, text, pose: pose);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final err = _d.stepError(_step, _now);
    if (err != null) {
      _toast(err);
      return;
    }
    if (_step == 'identity' && _d.isMinorIn(_now.year)) {
      // Aucune donnée enregistrée, brouillon effacé (L13).
      unawaited(store.saveAthleteDraft(null));
      setState(() => _minor = true);
      return;
    }
    if (_edit) {
      _save();
      return;
    }
    if (_step == 'recap') {
      _save();
      return;
    }
    if (_fromRecap) {
      _fromRecap = false;
      _go('recap');
      return;
    }
    _go(kAthleteSteps[_index + 1]);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_minor) {
      setState(() => _minor = false);
      return;
    }
    if (_edit) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_fromRecap) {
      _fromRecap = false;
      _go('recap');
      return;
    }
    if (_index > 0) {
      _go(kAthleteSteps[_index - 1]);
    } else {
      widget.onCancel?.call();
    }
  }

  void _save() {
    final res = store.saveAthleteProfile(_d);
    if (res == null) {
      final first = _d.firstIncomplete(_now);
      _toast(
        first == null
            ? 'Profil incomplet.'
            : 'Il manque une réponse : ${kRubricTitles[first] ?? first}.',
      );
      if (first != null && !_edit) _go(first);
      return;
    }
    if (_edit) {
      Navigator.of(context).maybePop(res);
      return;
    }
    setState(() => _saved = res);
  }

  // ================================================================ écrans

  @override
  Widget build(BuildContext context) {
    if (_saved != null) return _doneScreen();
    final title = _minor
        ? 'RÉSERVÉE AUX ADULTES'
        : _edit
        ? (kRubricTitles[_step] ?? 'PROFIL').toUpperCase()
        : switch (_step) {
            'welcome' => widget.mode == AthleteFlowMode.redo
                ? 'TON PROFIL'
                : 'BIENVENUE',
            'recap' => 'RÉCAPITULATIF',
            _ => (kRubricTitles[_step] ?? '').toUpperCase(),
          };
    final steps = kAthleteSteps.length - 1;
    final canBack =
        _minor ||
        _edit ||
        _index > 0 ||
        (widget.onCancel != null && _step == 'welcome');
    return PopScope(
      canPop: _edit && !_minor,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: KScreen(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: canBack
              ? IconButton(
                  key: const ValueKey('flow-back'),
                  tooltip: 'Retour',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _back,
                )
              : null,
          title: Text(title),
        ),
        body: KList(
          key: ValueKey('flow-${_minor ? 'minor' : _step}'),
          children: [
            if (!_minor && !_edit && _index > 0)
              Semantics(
                label: 'Étape $_index sur $steps',
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          key: const ValueKey('flow-progress'),
                          value: _index / steps,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$_index / $steps',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            if (_minor) ..._minorStep() else ..._stepBody(),
            if (!_minor) _actions(),
            if (!_minor && _step == 'welcome') const DisclaimerCard(),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final label = _edit
        ? 'Enregistrer'
        : _step == 'welcome'
        ? (widget.mode == AthleteFlowMode.redo ? 'C’est parti' : 'Commencer')
        : _step == 'recap'
        ? (store.program.start == null && !store.programGenerated
              ? 'Créer mon programme'
              : 'Enregistrer mon profil')
        : _fromRecap
        ? 'Retour au récapitulatif'
        : 'Continuer';
    return FilledButton(
      key: ValueKey(
        _edit ? 'flow-save' : (_fromRecap ? 'flow-to-recap' : 'flow-next-$_step'),
      ),
      onPressed: _next,
      child: Text(label),
    );
  }

  List<Widget> _minorStep() => [
    KCard(
      key: const ValueKey('minor-message'),
      child: KoachSays(
        pose: KoachPose.please,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kalis Track est réservée aux personnes de 18 ans et plus. '
              'Merci de ton intérêt : l’entraînement des plus jeunes mérite un '
              'accompagnement adapté, par exemple dans un club.',
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune donnée n’a été enregistrée.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
    OutlinedButton(
      key: const ValueKey('minor-back'),
      onPressed: _back,
      child: const Text('Corriger mon année de naissance'),
    ),
  ];

  /// Koach présente l'étape.
  Widget _koach(KoachPose pose, String text, {String? why}) => KoachSurface(
    color: SL.bg,
    child: KoachBubble(
      key: ValueKey('flow-koach-$_step'),
      pose: pose,
      text: text,
      why: why,
      koachHeight: 76,
      seed: _index,
    ),
  );

  Widget _title(String t) =>
      Text(t, style: Theme.of(context).textTheme.titleMedium);
  Widget _hint(String t) =>
      Text(t, style: Theme.of(context).textTheme.bodySmall);

  Widget _chips<T>({
    required String keyPrefix,
    required List<(T, String)> options,
    required bool Function(T) selected,
    required void Function(T, bool) onSelected,
    bool multi = false,
    bool Function(T)? enabled,
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
                onSelected: enabled == null || enabled(o.$1) || selected(o.$1)
                    ? (v) => setState(() => onSelected(o.$1, v))
                    : null,
              )
            : ChoiceChip(
                key: ValueKey('$keyPrefix-${o.$1}'),
                label: Text(o.$2),
                selected: selected(o.$1),
                onSelected: (v) => setState(() => onSelected(o.$1, v)),
              ),
    ],
  );

  List<Widget> _stepBody() => switch (_step) {
    'welcome' => _welcome(),
    'identity' => _identity(),
    'discipline' => _discipline(),
    'secondary' => _secondary(),
    'levels' => _levels(),
    'goals' => _goals(),
    'availability' => _availability(),
    'places' => _places(),
    'health' => _health(),
    'preferences' => _preferences(),
    'mode' => _mode(),
    _ => _recap(),
  };

  // ------------------------------------------------------------ 1. accueil

  List<Widget> _welcome() => [
    KoachSurface(
      color: SL.bg,
      child: KoachBubble(
        key: const ValueKey('flow-koach-welcome'),
        pose: KoachPose.wave,
        koachHeight: 120,
        text: widget.mode == AthleteFlowMode.redo
            ? 'On refait ton profil avec la nouvelle méthode. Ton programme, '
                  'ton historique et tes réglages ne changent pas.'
            : 'Salut, moi c’est Koach ! En 5 minutes environ, on crée ton '
                  'profil : tes disciplines, ton niveau, tes objectifs, ton '
                  'temps et ton matériel.',
        why:
            'Tout reste sur ce téléphone : ni compte, ni publicité. Tu pourras '
            'tout modifier ensuite dans Réglages › Profil.',
      ),
    ),
  ];

  // --------------------------------------------------------- 2. identité

  List<Widget> _identity() {
    final age = _d.ageIn(_now.year);
    return [
      _koach(KoachPose.present, 'Faisons connaissance.'),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Ton prénom ou pseudo (facultatif)'),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-name'),
              controller: _nameCtl,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Prénom ou pseudo'),
              onChanged: (v) => _d.displayName = v,
            ),
          ],
        ),
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Sexe'),
            const SizedBox(height: 4),
            _hint('Sert seulement aux repères de niveau par mouvement.'),
            const SizedBox(height: 8),
            _chips<Sex>(
              keyPrefix: 'flow-sex',
              options: [for (final s in Sex.values) (s, kSexLabels[s]!)],
              selected: (s) => _d.sex == s,
              onSelected: (s, _) => _d.sex = s,
            ),
          ],
        ),
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Année de naissance'),
            const SizedBox(height: 4),
            _hint('L’application est réservée aux 18 ans et plus.'),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-year'),
              controller: _year,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Année (ex. 1990)',
                counterText: '',
              ),
              onChanged: (v) => setState(() {
                _d
                  ..birthYear = v
                  ..adult18 = null;
              }),
            ),
            if (age == 18) ...[
              const SizedBox(height: 8),
              _hint('As-tu déjà fêté tes 18 ans ?'),
              const SizedBox(height: 6),
              _chips<bool>(
                keyPrefix: 'flow-adult18',
                options: const [(true, 'Oui'), (false, 'Pas encore')],
                selected: (v) => _d.adult18 == v,
                onSelected: (v, _) => _d.adult18 = v,
              ),
            ],
          ],
        ),
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Taille'),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-height'),
              controller: _height,
              keyboardType: TextInputType.number,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Taille (cm)',
                counterText: '',
              ),
              onChanged: (v) => _d.height = v,
            ),
            const SizedBox(height: 12),
            _title('Poids (facultatif)'),
            const SizedBox(height: 4),
            _hint(
              'Sert aux rangs par mouvement et aux exercices au poids du '
              'corps (tractions, dips…) : on y ajoute ton lest. Modifiable à '
              'tout moment dans les pesées.',
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('flow-weight'),
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Poids (kg)'),
              onChanged: (v) => _d.weight = v,
            ),
          ],
        ),
      ),
    ];
  }

  // ------------------------------------------------------- 3. discipline

  static const _disciplinePoses = <TrainingDiscipline, KoachPose>{
    TrainingDiscipline.musculation: KoachPose.doubleBiceps,
    TrainingDiscipline.streetWorkout: KoachPose.pump,
    TrainingDiscipline.streetlifting: KoachPose.flex,
    TrainingDiscipline.calisthenics: KoachPose.cheer,
    TrainingDiscipline.crossfit: KoachPose.sprint,
    TrainingDiscipline.cardio: KoachPose.run,
    TrainingDiscipline.mobility: KoachPose.happy,
    TrainingDiscipline.generalFitness: KoachPose.thumbsUp,
  };

  static const _stylePoses = <StreetStyle, KoachPose>{
    StreetStyle.streetlifting: KoachPose.flex,
    StreetStyle.setsReps: KoachPose.pump,
    StreetStyle.calisthenics: KoachPose.cheer,
  };

  Widget _option({
    required Key key,
    required KoachPose pose,
    required String title,
    required String hint,
    required bool selected,
    required VoidCallback onTap,
  }) => KCard(
    key: key,
    accent: selected ? SL.accent : null,
    onTap: () => setState(onTap),
    child: Semantics(
      selected: selected,
      button: true,
      child: Row(
        children: [
          KoachView(pose: pose, height: 52, width: 46, animate: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_title(title), const SizedBox(height: 2), _hint(hint)],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? SL.accent : SL.dim,
          ),
        ],
      ),
    ),
  );

  List<Widget> _discipline() => [
    _koach(
      KoachPose.choice,
      'Quelle est ta discipline principale ? Celle qui prendra la plus '
      'grande part de tes séances.',
      why:
          'Le mode street regroupe streetlifting, sets & reps et calisthénie : '
          'tu choisis la principale et tu doses les deux autres.',
    ),
    KCard(
      child: SwitchListTile(
        key: const ValueKey('flow-street'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Mode street'),
        subtitle: const Text('Streetlifting, sets & reps et calisthénie'),
        value: _d.street,
        onChanged: (v) => setState(() => _d.setStreet(v)),
      ),
    ),
    if (_d.street)
      for (final s in StreetStyle.values)
        _option(
          key: ValueKey('flow-style-${s.code}'),
          pose: _stylePoses[s]!,
          title: kStreetStyleLabels[s]!,
          hint: kStreetStyleHints[s]!,
          selected: _d.streetPrimary == s,
          onTap: () => _d.setStreetPrimary(s),
        )
    else
      for (final d in TrainingDiscipline.values)
        _option(
          key: ValueKey('flow-discipline-${d.code}'),
          pose: _disciplinePoses[d]!,
          title: kDisciplineLabels[d]!,
          hint: kDisciplineHints[d]!,
          selected: _d.primary == d,
          onTap: () {
            _d.primary = d;
            _d.secondaries.remove(d);
          },
        ),
  ];

  // -------------------------------------------------------- 4. secondaires

  Widget _slider({
    required String key,
    required int value,
    required int min,
    required int max,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    if (max <= min) {
      return Text('$label : $value %');
    }
    return Semantics(
      label: label,
      child: Slider(
        key: ValueKey(key),
        value: value.clamp(min, max).toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: (max - min) ~/ 5,
        label: '$value %',
        onChanged: (v) => setState(() => onChanged((v / 5).round() * 5)),
      ),
    );
  }

  List<Widget> _secondary() {
    if (_d.street) return _streetDosage();
    final p = _d.primary;
    final available = [
      for (final d in TrainingDiscipline.values)
        if (d != p) (d, kDisciplineLabels[d]!),
    ];
    return [
      _koach(
        KoachPose.explainBoard,
        'Ajoute 1 ou 2 disciplines secondaires et dose-les. La principale '
        'garde toujours la plus grande part.',
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Disciplines secondaires'),
            const SizedBox(height: 8),
            _chips<TrainingDiscipline>(
              keyPrefix: 'flow-secondary',
              multi: true,
              options: available,
              selected: _d.secondaries.containsKey,
              enabled: (_) => _d.secondaries.length < 2,
              onSelected: (d, v) {
                if (v) {
                  _d.addSecondary(d);
                } else {
                  _d.removeSecondary(d);
                }
              },
            ),
          ],
        ),
      ),
      if (p != null)
        KCard(
          key: const ValueKey('flow-dosage'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('${kDisciplineLabels[p]} (principale) : ${_d.primaryPct} %'),
              _hint(dosageInWords(p, _d.primaryPct)),
              for (final e in _d.secondaries.entries.toList()) ...[
                const SizedBox(height: 14),
                Text(
                  '${kDisciplineLabels[e.key]} : ${e.value} %',
                  key: ValueKey('flow-pct-${e.key.code}'),
                ),
                _slider(
                  key: 'flow-slider-${e.key.code}',
                  value: e.value,
                  min: 5,
                  max: _d.maxSecondaryPct(e.key),
                  label: 'Part de ${kDisciplineLabels[e.key]}',
                  onChanged: (v) => _d.setSecondaryPct(e.key, v),
                ),
                _hint(dosageInWords(e.key, e.value)),
              ],
            ],
          ),
        ),
    ];
  }

  List<Widget> _streetDosage() {
    final m = _d.streetMode;
    return [
      _koach(
        KoachPose.explainBoard,
        'Dose les deux autres styles street. Ta principale garde la plus '
        'grande part.',
      ),
      if (m != null)
        KCard(
          key: const ValueKey('flow-dosage'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(
                '${kStreetStyleLabels[m.primary]} (principale) : '
                '${m.pctOf(m.primary)} %',
              ),
              for (final s in StreetStyle.values)
                if (s != m.primary) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${kStreetStyleLabels[s]} : ${m.pctOf(s)} %',
                    key: ValueKey('flow-pct-${s.code}'),
                  ),
                  _slider(
                    key: 'flow-slider-${s.code}',
                    value: m.pctOf(s),
                    min: 0,
                    max: _d.maxStreetPct(s),
                    label: 'Part de ${kStreetStyleLabels[s]}',
                    onChanged: (v) => _d.setStreetPct(s, v),
                  ),
                  _hint(streetDosageInWords(s, m.pctOf(s))),
                ],
            ],
          ),
        ),
    ];
  }

  // ------------------------------------------------------------ 5. niveau

  List<Widget> _levels() => [
    _koach(
      KoachPose.analyze,
      'Dis-moi où tu en es, mouvement par mouvement. Une fourchette suffit, '
      'et « Je ne sais pas » est une bonne réponse.',
      why:
          'Je pars de la valeur basse de ta fourchette, pour être prudent. '
          'Tes 2 ou 3 premières séances me serviront ensuite à caler tes '
          'charges.',
    ),
    KCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Ton expérience'),
          const SizedBox(height: 8),
          _chips<ExperienceLevel>(
            keyPrefix: 'flow-experience',
            options: [
              for (final e in ExperienceLevel.values) (e, kExperienceLabels[e]!),
            ],
            selected: (e) => _d.experience == e,
            onSelected: (e, v) => _d.experience = v ? e : null,
          ),
        ],
      ),
    ),
    for (final m in _d.movements)
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

  // --------------------------------------------------------- 6. objectifs

  ContentIndex get _content => store.content;

  String _name(String id) => _content.byId[id]?.nom ?? id;

  List<Widget> _goals() => [
    _koach(
      KoachPose.flag,
      'Qu’est-ce que tu vises ? Une performance chiffrée avec une date, une '
      'habitude, ou laisse-moi te proposer.',
      why:
          'Tu peux avoir plusieurs objectifs ; le premier est le principal. '
          'L’étoile change l’objectif principal.',
    ),
    for (var i = 0; i < _d.goals.length; i++)
      KCard(
        key: ValueKey('flow-goal-$i'),
        accent: i == 0 ? SL.accent : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hint(
                    [
                      i == 0 ? 'Objectif principal' : 'Objectif',
                      if (_d.goals[i].origin == GoalOrigin.suggested)
                        'proposé par Koach',
                    ].join(' · '),
                  ),
                  const SizedBox(height: 2),
                  Text(goalText(_d.goals[i], _name)),
                ],
              ),
            ),
            if (i > 0)
              IconButton(
                key: ValueKey('flow-goal-main-$i'),
                tooltip: 'En faire l’objectif principal',
                icon: const Icon(Icons.star_border),
                onPressed: () => setState(() {
                  final g = _d.goals.removeAt(i);
                  _d.goals.insert(0, g);
                }),
              ),
            IconButton(
              key: ValueKey('flow-goal-remove-$i'),
              tooltip: 'Retirer cet objectif',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _d.goals.removeAt(i)),
            ),
          ],
        ),
      ),
    FilledButton.tonalIcon(
      key: const ValueKey('goal-add-performance'),
      icon: const Icon(Icons.trending_up),
      label: const Text('Objectif de performance'),
      onPressed: _addPerformance,
    ),
    FilledButton.tonalIcon(
      key: const ValueKey('goal-add-habit'),
      icon: const Icon(Icons.event_repeat),
      label: const Text('Objectif d’habitude'),
      onPressed: _addHabit,
    ),
    OutlinedButton.icon(
      key: const ValueKey('goal-suggest'),
      icon: const Icon(Icons.lightbulb_outline),
      label: const Text('Laisse Koach proposer'),
      onPressed: _suggest,
    ),
  ];

  Future<void> _suggest() async {
    final list = provisionalGoalSuggestions(_d, civilOf(_now));
    final chosen = <Goal>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => KoachSurface(
          color:
              Theme.of(ctx).bottomSheetTheme.backgroundColor ??
              Theme.of(ctx).colorScheme.surfaceContainerLow,
          child: SingleChildScrollView(
            key: const ValueKey('goal-suggestions'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KoachBubble(
                  pose: KoachPose.idea,
                  koachHeight: 90,
                  text: list.isEmpty
                      ? 'Je n’ai rien de sûr à te proposer pour l’instant. '
                            'Dis-moi ton niveau sur quelques mouvements.'
                      : 'Voici ce que je te propose, d’après ce que tu m’as '
                            'dit. Garde ce qui te parle.',
                  why:
                      'Des objectifs prudents, partis du bas de tes '
                      'fourchettes, sur 12 semaines. Tu pourras les changer.',
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < list.length; i++)
                  CheckboxListTile(
                    key: ValueKey('goal-suggestion-$i'),
                    contentPadding: EdgeInsets.zero,
                    value: chosen.contains(list[i]),
                    title: Text(goalText(list[i], _name)),
                    onChanged: (v) => set(
                      () => v == true
                          ? chosen.add(list[i])
                          : chosen.remove(list[i]),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey('goal-suggestions-add'),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    chosen.isEmpty ? 'Fermer' : 'Ajouter (${chosen.length})',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || chosen.isEmpty) return;
    setState(() {
      for (final g in list) {
        if (!chosen.contains(g)) continue;
        _d.goals.add(g.copyWith(id: nextGoalId(_d.goals)));
      }
    });
  }

  Future<String?> _pickExercise() => Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const ExercisePickerPage()),
  );

  Future<void> _addHabit() async {
    var sessions = _d.days.isEmpty ? 3 : _d.days.length.clamp(1, 7).toInt();
    var weeks = 8;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          key: const ValueKey('goal-habit-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Objectif d’habitude',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _title('Séances par semaine'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var n = 1; n <= 7; n++)
                    ChoiceChip(
                      key: ValueKey('goal-sessions-$n'),
                      label: Text('$n'),
                      selected: sessions == n,
                      onSelected: (_) => set(() => sessions = n),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _title('Pendant'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in const [4, 6, 8, 12, 16, 24, 52])
                    ChoiceChip(
                      key: ValueKey('goal-weeks-$w'),
                      label: Text('$w semaines'),
                      selected: weeks == w,
                      onSelected: (_) => set(() => weeks = w),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('goal-save'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(
      () => _d.goals.add(
        Goal(
          id: nextGoalId(_d.goals),
          kind: GoalKind.habit,
          origin: GoalOrigin.user,
          createdOn: civilOf(_now),
          sessionsPerWeek: sessions,
          weeks: weeks,
        ),
      ),
    );
  }

  Future<void> _addPerformance() async {
    final g = await showModalBottomSheet<Goal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _PerformanceGoalSheet(
        draft: _d,
        today: civilOf(_now),
        name: _name,
        pick: _pickExercise,
        id: nextGoalId(_d.goals),
      ),
    );
    if (g == null || !mounted) return;
    setState(() => _d.goals.add(g));
  }

  // ------------------------------------------------------ 7. disponibilités

  List<Widget> _availability() {
    final days = _d.days.keys.toList()..sort();
    return [
      _koach(
        KoachPose.checklist,
        'Quels jours peux-tu t’entraîner, et combien de temps chaque jour ?',
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Jours'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  Semantics(
                    label: weekdayTitle(d),
                    excludeSemantics: true,
                    selected: _d.days.containsKey(d),
                    button: true,
                    child: FilterChip(
                      key: ValueKey('flow-day-$d'),
                      showCheckmark: false,
                      label: Text(kWeekdayShort[d - 1]),
                      selected: _d.days.containsKey(d),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _d.days[d] = _d.days.isEmpty
                              ? 45
                              : _d.days[days.last] ?? 45;
                        } else {
                          _d.days.remove(d);
                          _d.dayPlace.remove(d);
                        }
                      }),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      for (final d in days)
        KCard(
          key: ValueKey('flow-day-card-$d'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('${weekdayTitle(d)} : ${_d.days[d]} min'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in kMinutePresets)
                    ChoiceChip(
                      key: ValueKey('flow-min-$d-$m'),
                      label: Text('$m min'),
                      selected: _d.days[d] == m,
                      onSelected: (_) => setState(() => _d.days[d] = m),
                    ),
                  ChoiceChip(
                    key: ValueKey('flow-min-$d-other'),
                    label: const Text('Autre'),
                    selected: !kMinutePresets.contains(_d.days[d]),
                    onSelected: (_) => _otherMinutes(d),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _otherMinutes(int day) async {
    final c = TextEditingController(text: '${_d.days[day] ?? 45}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Durée du ${weekdayName(day)}'),
        content: TextField(
          key: const ValueKey('flow-min-input'),
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes (10 à 300)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('flow-min-ok'),
            onPressed: () => Navigator.pop(ctx, int.tryParse(c.text.trim())),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    c.dispose();
    if (!mounted || v == null) return;
    if (v < 10 || v > 300) {
      _toast('Durée par jour : de 10 à 300 minutes.');
      return;
    }
    setState(() => _d.days[day] = v);
  }

  // ------------------------------------------------- 8. lieux et matériel

  Place? _equipPlace;

  List<Widget> _places() {
    final chosen = [
      for (final p in Place.values)
        if (_d.places.containsKey(p)) p,
    ];
    final current = chosen.contains(_equipPlace)
        ? _equipPlace!
        : (chosen.isEmpty ? null : chosen.first);
    final set = current == null ? null : _d.places[current]!;
    final days = _d.days.keys.toList()..sort();
    return [
      _koach(
        KoachPose.direction,
        'Où t’entraînes-tu, et avec quel matériel ? Pars d’un préréglage puis '
        'ajuste.',
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Lieux'),
            const SizedBox(height: 8),
            _chips<Place>(
              keyPrefix: 'flow-place',
              multi: true,
              options: [for (final p in Place.values) (p, kPlaceNames[p]!)],
              selected: _d.places.containsKey,
              onSelected: (p, v) {
                if (v) {
                  _d.addPlace(p);
                  _equipPlace = p;
                } else {
                  _d.removePlace(p);
                }
              },
            ),
          ],
        ),
      ),
      if (current != null && set != null) ...[
        if (chosen.length > 1)
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Matériel de quel lieu ?'),
                const SizedBox(height: 8),
                _chips<Place>(
                  keyPrefix: 'flow-equip-place',
                  options: [for (final p in chosen) (p, kPlaceNames[p]!)],
                  selected: (p) => p == current,
                  onSelected: (p, _) => _equipPlace = p,
                ),
              ],
            ),
          ),
        KCard(
          key: const ValueKey('flow-presets'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Partir de… (${kPlaceNames[current]!.toLowerCase()})'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in kEquipmentPresets)
                    ActionChip(
                      key: ValueKey('flow-preset-${p.id}'),
                      label: Text(p.label),
                      onPressed: () => setState(
                        () => _d.places[current] = {...p.equipment},
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _hint('${set.length} élément${set.length > 1 ? 's' : ''} choisi'
                  '${set.length > 1 ? 's' : ''}'),
            ],
          ),
        ),
        for (final g in kEquipmentGroups)
          KCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: ExpansionTile(
              key: ValueKey('flow-equip-group-${g.$1}-${current.code}'),
              tilePadding: EdgeInsets.zero,
              title: Text(g.$1),
              subtitle: Text(
                '${g.$2.where(set.contains).length} sur ${g.$2.length}',
              ),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final e in g.$2)
                        FilterChip(
                          key: ValueKey('equip-$e'),
                          label: Text(e),
                          selected: set.contains(e),
                          onSelected: (v) =>
                              setState(() => v ? set.add(e) : set.remove(e)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      if (chosen.length > 1 && days.isNotEmpty)
        KCard(
          key: const ValueKey('flow-dayplaces'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Lieu de chaque jour (facultatif)'),
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DropdownButtonFormField<Place?>(
                    key: ValueKey('flow-dayplace-$d'),
                    isExpanded: true,
                    initialValue: _d.dayPlace[d],
                    decoration: InputDecoration(labelText: weekdayTitle(d)),
                    items: [
                      const DropdownMenuItem<Place?>(
                        value: null,
                        child: Text('N’importe lequel'),
                      ),
                      for (final p in chosen)
                        DropdownMenuItem<Place?>(
                          value: p,
                          child: Text(kPlaceNames[p]!),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      if (v == null) {
                        _d.dayPlace.remove(d);
                      } else {
                        _d.dayPlace[d] = v;
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  // ------------------------------------------------------------- 9. santé

  List<Widget> _health() {
    final given = _d.consent == 'given';
    final lit = <String, double>{
      for (final l in _d.limitations)
        for (final r in regionsOfZone(l.zone)) r: .35 + .065 * l.discomfort,
    };
    return [
      _koach(
        KoachPose.anatomy,
        'Ta santé d’abord : un court questionnaire, puis tes blessures ou '
        'gênes, s’il y en a.',
        why:
            'Sans réponse, j’applique le mode prudent : pas de test maximal, '
            'des charges limitées. Une gêne me fait éviter les exercices qui '
            'chargent la zone.',
      ),
      KCard(
        key: const ValueKey('flow-consent'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title('Avant de continuer'),
            const SizedBox(height: 6),
            const Text(kHealthInfo),
            const SizedBox(height: 10),
            _chips<String>(
              keyPrefix: 'flow-consent',
              options: const [('given', 'J’accepte'), ('refused', 'Je refuse')],
              selected: (v) => _d.consent == v,
              onSelected: (v, _) => _d.consent = v,
            ),
          ],
        ),
      ),
      if (_d.consent == 'refused')
        const KCard(
          key: ValueKey('flow-refused'),
          child: Text(
            'D’accord : aucune donnée de santé ne sera enregistrée. '
            '$kCautionAdvice Tu pourras donner ton accord plus tard dans '
            'Réglages › Profil.',
          ),
        ),
      if (given) ...[
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Questionnaire d’aptitude'),
              const SizedBox(height: 4),
              _hint(
                'Réponds par oui ou non. Sans réponse, le mode prudent '
                's’applique par défaut.',
              ),
              for (final q in kHealthQuestions) ...[
                const SizedBox(height: 12),
                Text(q.text),
                const SizedBox(height: 6),
                _chips<bool>(
                  keyPrefix: 'flow-q-${q.id}',
                  options: const [(false, 'Non'), (true, 'Oui')],
                  selected: (v) => _d.answers[q.id] == v,
                  onSelected: (v, _) => _d.answers[q.id] = v,
                ),
              ],
            ],
          ),
        ),
        KCard(
          key: const ValueKey('flow-limitations'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Blessures et gênes (facultatif)'),
              const SizedBox(height: 4),
              _hint(
                'Touche la zone sur la carte, ou choisis-la dans la liste '
                '(articulations comprises).',
              ),
              const SizedBox(height: 8),
              MuscleMap2D(
                key: const ValueKey('flow-body-map'),
                views: const [MapView.face, MapView.dos],
                height: 230,
                intensities: lit,
                semanticLabel: 'Carte du corps',
                onRegionTap: (r) {
                  final z = r == null ? null : kRegionZones[r];
                  if (z != null) _editLimitation(z);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final z in BodyZone.values)
                    ActionChip(
                      key: ValueKey('zone-${z.code}'),
                      label: Text(kZoneLabels[z]!),
                      onPressed: () => _editLimitation(z),
                    ),
                ],
              ),
              for (final l in _d.limitations)
                ListTile(
                  key: ValueKey('flow-limitation-${limitationKey(l)}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${kZoneLabels[l.zone]} · ${kSideLabels[l.side]!.toLowerCase()}',
                  ),
                  subtitle: Text('Gêne actuelle : ${l.discomfort}/10'),
                  onTap: () => _editLimitation(l.zone, side: l.side),
                  trailing: IconButton(
                    tooltip: 'Retirer',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _d.limitations.remove(l)),
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  Future<void> _editLimitation(BodyZone zone, {BodySide? side}) async {
    Limitation? existing;
    for (final l in _d.limitations) {
      if (l.zone == zone && (side == null || l.side == side)) existing = l;
    }
    var s = existing?.side ?? side ?? BodySide.both;
    var level = (existing?.discomfort ?? 3).toDouble();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          key: const ValueKey('limitation-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kZoneLabels[zone]!,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              if (zone.joint != null)
                Text(
                  'Articulation suivie : ${kJointLabels[zone.joint]}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              _title('Côté'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in BodySide.values)
                    ChoiceChip(
                      key: ValueKey('limitation-side-${b.code}'),
                      label: Text(kSideLabels[b]!),
                      selected: s == b,
                      onSelected: (_) => set(() => s = b),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Gêne actuelle : ${level.round()}/10'),
              Slider(
                key: const ValueKey('limitation-level'),
                value: level,
                max: 10,
                divisions: 10,
                label: '${level.round()}/10',
                onChanged: (v) => set(() => level = v),
              ),
              Text(
                '0 : aucune gêne aujourd’hui · 10 : la pire imaginable. Une '
                'douleur forte ou qui dure mérite l’avis d’un professionnel de '
                'santé.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('limitation-save'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      if (existing != null) _d.limitations.remove(existing);
      _d.putLimitation(limitationOf(zone, s, level.round()));
    });
  }

  // ------------------------------------------------------ 10. préférences

  List<Widget> _preferences() {
    final results = _query.trim().isEmpty
        ? const <String>[]
        : [
            for (final e in searchExercises(
              _content,
              _query,
              const ExerciseFilters(),
            ).take(8))
              e.id,
          ];
    Widget chipList(String title, List<String> ids, String prefix) => KCard(
      key: ValueKey('flow-$prefix-list'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(title),
          const SizedBox(height: 6),
          if (ids.isEmpty)
            _hint('Aucun pour l’instant.')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final id in ids)
                  InputChip(
                    key: ValueKey('flow-$prefix-$id'),
                    label: Text(_name(id)),
                    onDeleted: () => setState(() => ids.remove(id)),
                    deleteButtonTooltipMessage: 'Retirer',
                  ),
              ],
            ),
        ],
      ),
    );
    return [
      _koach(
        KoachPose.love,
        'Des exercices que tu adores, ou que tu ne veux plus voir ? C’est '
        'facultatif.',
      ),
      KCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KSearch(
              controller: _search,
              hint: 'Chercher un exercice',
              onChanged: (v) => setState(() => _query = v),
            ),
            for (final id in results)
              ListTile(
                key: ValueKey('flow-pref-result-$id'),
                contentPadding: EdgeInsets.zero,
                title: Text(_name(id)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('flow-like-$id'),
                      tooltip: 'J’aime',
                      isSelected: _d.liked.contains(id),
                      icon: const Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite, color: SL.accent),
                      onPressed: () => setState(() {
                        _d.disliked.remove(id);
                        if (!_d.liked.remove(id)) _d.liked.add(id);
                      }),
                    ),
                    IconButton(
                      key: ValueKey('flow-dislike-$id'),
                      tooltip: 'Je n’aime pas',
                      isSelected: _d.disliked.contains(id),
                      icon: const Icon(Icons.thumb_down_outlined),
                      selectedIcon: Icon(Icons.thumb_down, color: SL.accent),
                      onPressed: () => setState(() {
                        _d.liked.remove(id);
                        if (!_d.disliked.remove(id)) _d.disliked.add(id);
                      }),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      chipList('J’aime', _d.liked, 'liked'),
      chipList('Je n’aime pas', _d.disliked, 'disliked'),
    ];
  }

  // -------------------------------------------------------------- 11. mode

  List<Widget> _mode() => [
    _koach(
      KoachPose.settings,
      'Dernier choix : comment veux-tu que je t’accompagne ? Tu pourras '
      'changer à tout moment dans les réglages.',
    ),
    for (final m in GuidanceMode.values)
      _option(
        key: ValueKey('flow-mode-${m.code}'),
        pose: m == GuidanceMode.assisted ? KoachPose.fistBump : KoachPose.present,
        title: kGuidanceLabels[m]!,
        hint: m == GuidanceMode.assisted
            ? 'J’applique moi-même ce que je propose, je t’explique pourquoi, '
                  'et tu peux toujours annuler. Exemple : tes séries étaient '
                  'faciles, je monte la charge de 2,5 kg à la séance suivante.'
            : 'Je te propose, tu décides : rien ne change sans ton accord. '
                  'Exemple : tes séries étaient faciles, je te propose +2,5 kg '
                  'et tu acceptes ou non.',
        selected: _d.guidance == m,
        onTap: () => _d.guidance = m,
      ),
  ];

  // ----------------------------------------------------- 12. récapitulatif

  List<Widget> _recap() {
    final caution = draftCaution(_d, store.profile, _now);
    return [
      _koach(
        KoachPose.thumbsUp,
        'Voilà ton profil. Touche une rubrique pour la modifier.',
      ),
      for (final r in kRubricTitles.keys)
        KCard(
          key: ValueKey('recap-$r'),
          onTap: () {
            _fromRecap = true;
            _go(r);
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _hint(kRubricTitles[r]!),
                    const SizedBox(height: 2),
                    Text(rubricSummary(r, _d, _name)),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('recap-edit-$r'),
                tooltip: 'Modifier : ${kRubricTitles[r]}',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  _fromRecap = true;
                  _go(r);
                },
              ),
            ],
          ),
        ),
      CautionCard(status: caution),
    ];
  }

  // --------------------------------------------------------- écran de fin

  Widget _doneScreen() {
    final noProgram = store.program.start == null && !store.programGenerated;
    final text = noProgram
        ? 'Ton profil est prêt ! Ton programme arrive bientôt : je le '
              'construirai avec toi dans la prochaine version de '
              'l’application.'
        : 'Ton profil est enregistré. Ton programme, ton historique et tes '
              'réglages ne changent pas.';
    return KScreen(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(noProgram ? 'TON PROGRAMME' : 'TON PROFIL'),
      ),
      body: KList(
        key: const ValueKey('flow-done'),
        children: [
          KoachSurface(
            color: SL.bg,
            child: KoachBubble(
              key: const ValueKey('flow-done-koach'),
              pose: noProgram ? KoachPose.present : KoachPose.thumbsUp,
              koachHeight: 140,
              text: text,
            ),
          ),
          FilledButton(
            key: const ValueKey('flow-done-continue'),
            onPressed: widget.onDone,
            child: Text(noProgram ? 'Découvrir l’application' : 'Continuer'),
          ),
        ],
      ),
    );
  }
}

/// Articulations suivies (contraintes du catalogue).
const kJointLabels = <Joint, String>{
  Joint.shoulder: 'épaule',
  Joint.elbow: 'coude',
  Joint.wrist: 'poignet',
  Joint.lumbar: 'lombaires',
  Joint.knee: 'genou',
  Joint.hip: 'hanche',
  Joint.ankle: 'cheville',
};

/// Mode prudent du brouillon (récapitulatif) : bloc santé du brouillon,
/// âge et gênes du brouillon.
CautionStatus draftCaution(ProfileDraft d, UserProfile? legacy, DateTime now) {
  final at = profileAt(now);
  final p = legacy?.copy() ?? UserProfile(origin: 'onboarding', createdAt: at);
  final h = p.health;
  if (d.consent == 'given') {
    h.consent = 'given';
    final same =
        d.answers.length == h.answers.length &&
        d.answers.entries.every((e) => h.answers[e.key] == e.value);
    if (!same) {
      h.answers
        ..clear()
        ..addAll(d.answers);
      h.answeredAt = d.answers.isEmpty ? null : at;
    }
  } else {
    h
      ..consent = d.consent == null ? null : 'refused'
      ..clearContent();
  }
  final by = d.birthYearValue;
  return evaluateCaution(
    p,
    now,
    birth: by == null ? null : (year: by, at: at),
    discomforts: [
      if (d.consent == 'given')
        for (final l in d.limitations) (level: l.discomfort, at: at),
    ],
  );
}

/// Résumé d'une rubrique (récapitulatif, Réglages › Profil).
String rubricSummary(
  String rubric,
  ProfileDraft d,
  String Function(String id) name,
) {
  switch (rubric) {
    case 'identity':
      return [
        if (d.displayName.trim().isNotEmpty) d.displayName.trim(),
        if (d.sex != null) kSexLabels[d.sex]!,
        if (d.birthYearValue != null) 'né(e) en ${d.birthYearValue}',
        if (d.heightValue != null) '${d.heightValue} cm',
        if (d.weightValue != null && !d.weightValue!.isNaN)
          '${numText(d.weightValue!)} kg',
      ].join(' · ');
    case 'discipline':
      if (d.street) {
        final p = d.streetPrimary;
        return p == null ? '—' : 'Mode street · ${kStreetStyleLabels[p]}';
      }
      return d.primary == null ? '—' : kDisciplineLabels[d.primary]!;
    case 'secondary':
      if (d.street) {
        final m = d.streetMode;
        if (m == null) return '—';
        return [
          for (final s in StreetStyle.values)
            '${kStreetStyleLabels[s]} ${m.pctOf(s)} %',
        ].join(' · ');
      }
      final p = d.primary;
      if (p == null) return '—';
      return [
        '${kDisciplineLabels[p]} ${d.primaryPct} %',
        for (final e in d.secondaries.entries)
          '${kDisciplineLabels[e.key]} ${e.value} %',
      ].join(' · ');
    case 'levels':
      final lines = <String>[
        if (d.experience != null) kExperienceLabels[d.experience]!,
        for (final m in d.movements)
          if (d.levels[m.key] case final int i)
            '${m.label} : ${i < 0 ? 'je ne sais pas' : m.bands[i].label}',
      ];
      return lines.isEmpty ? 'Rien de déclaré' : lines.join('\n');
    case 'goals':
      if (d.goals.isEmpty) return 'Aucun objectif';
      return [for (final g in d.goals) goalText(g, name)].join('\n');
    case 'availability':
      final days = d.days.keys.toList()..sort();
      if (days.isEmpty) return '—';
      return [
        for (final x in days)
          '${weekdayTitle(x)} ${d.days[x]} min'
              '${d.dayPlace[x] == null ? '' : ' (${kPlaceNames[d.dayPlace[x]]!.toLowerCase()})'}',
      ].join(' · ');
    case 'places':
      if (d.places.isEmpty) return '—';
      return [
        for (final p in Place.values)
          if (d.places[p] case final Set<String> s)
            '${kPlaceNames[p]} : ${s.isEmpty ? 'sans matériel' : '${s.length} élément${s.length > 1 ? 's' : ''} de matériel'}',
      ].join('\n');
    case 'health':
      if (d.consent != 'given') {
        return d.consent == null
            ? '—'
            : 'Pas d’accord : aucune donnée de santé (mode prudent)';
      }
      final complete = kHealthQuestions.every(
        (q) => d.answers.containsKey(q.id),
      );
      return [
        complete ? 'Questionnaire rempli' : 'Questionnaire sans réponse',
        if (d.limitations.isEmpty)
          'aucune gêne'
        else
          for (final l in d.limitations)
            '${kZoneLabels[l.zone]} ${l.discomfort}/10',
      ].join(' · ');
    case 'preferences':
      if (d.liked.isEmpty && d.disliked.isEmpty) return 'Rien de précisé';
      return [
        if (d.liked.isNotEmpty) 'J’aime : ${d.liked.map(name).join(', ')}',
        if (d.disliked.isNotEmpty)
          'Je n’aime pas : ${d.disliked.map(name).join(', ')}',
      ].join('\n');
    case 'mode':
      return d.guidance == null ? '—' : kGuidanceLabels[d.guidance]!;
  }
  return '';
}

/// Objectif de performance : exercice, grandeur, valeur, échéance.
class _PerformanceGoalSheet extends StatefulWidget {
  final ProfileDraft draft;
  final CivilDate today;
  final String Function(String) name;
  final Future<String?> Function() pick;
  final String id;
  const _PerformanceGoalSheet({
    required this.draft,
    required this.today,
    required this.name,
    required this.pick,
    required this.id,
  });

  @override
  State<_PerformanceGoalSheet> createState() => _PerformanceGoalSheetState();
}

class _PerformanceGoalSheetState extends State<_PerformanceGoalSheet> {
  String? _exercise;
  GoalMetric? _metric;
  final _value = TextEditingController();
  final _extra = TextEditingController();
  late CivilDate _date = widget.today.addDays(12 * 7);
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    _extra.dispose();
    super.dispose();
  }

  CatalogExercise? get _ex =>
      _exercise == null ? null : store.content.byId[_exercise!]?.ex;

  List<GoalMetric> get _metrics => _ex == null ? const [] : metricsFor(_ex!);

  double? _parse(String t) {
    final s = t.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    if (s.contains(':')) {
      final parts = s.split(':');
      final m = int.tryParse(parts[0]);
      final sec = parts.length > 1 ? int.tryParse(parts[1]) : 0;
      if (m == null || sec == null) return null;
      return (m * 60 + sec).toDouble();
    }
    return double.tryParse(s);
  }

  void _choose(String id) {
    setState(() {
      _exercise = id;
      final ms = _metrics;
      _metric = ms.isEmpty ? null : ms.first;
      _extra.text = _metric == GoalMetric.timeSeconds
          ? '${(levelMovementForExercise(id)?.distanceMeters ?? 5000).round()}'
          : '';
    });
  }

  (String, String?) get _valueLabel => switch (_metric) {
    GoalMetric.oneRmKg => ('Charge visée (kg, charge externe)', null),
    GoalMetric.maxReps => ('Répétitions visées', 'À une charge de (kg, facultatif)'),
    GoalMetric.maxHoldSeconds => ('Temps de tenue visé (secondes)', null),
    GoalMetric.timeSeconds => ('Temps visé (min:s, ex. 24:30)', 'Distance (m)'),
    GoalMetric.distanceMeters => ('Distance visée (m)', 'En combien de minutes ?'),
    _ => ('', null),
  };

  void _save() {
    final metric = _metric;
    final ex = _exercise;
    if (ex == null || metric == null) {
      setState(() => _error = 'Choisis un exercice et ce que tu vises.');
      return;
    }
    double? value;
    if (metric != GoalMetric.skillUnlocked) {
      value = _parse(_value.text);
      if (value == null || value < 0 || (value == 0 && metric != GoalMetric.oneRmKg)) {
        setState(() => _error = 'Indique la valeur visée.');
        return;
      }
    }
    double? extra;
    if (_extra.text.trim().isNotEmpty) {
      extra = _parse(_extra.text);
      if (extra == null || extra < 0) {
        setState(() => _error = 'Valeur invalide.');
        return;
      }
    }
    if (metric == GoalMetric.timeSeconds && (extra == null || extra <= 0)) {
      setState(() => _error = 'Indique la distance en mètres.');
      return;
    }
    if (metric == GoalMetric.distanceMeters && (extra == null || extra <= 0)) {
      setState(() => _error = 'Indique la durée en minutes.');
      return;
    }
    if (_date <= widget.today) {
      setState(() => _error = 'Choisis une date à venir.');
      return;
    }
    final g = Goal(
      id: widget.id,
      kind: GoalKind.performance,
      origin: GoalOrigin.user,
      createdOn: widget.today,
      exerciseId: ex,
      metric: metric,
      targetValue: value,
      distanceMeters: metric == GoalMetric.timeSeconds ? extra : null,
      loadKg: metric == GoalMetric.maxReps && extra != null && extra > 0
          ? extra
          : null,
      durationSeconds: metric == GoalMetric.distanceMeters
          ? (extra! * 60).round()
          : null,
      targetDate: _date,
    );
    if (g.validate().isNotEmpty) {
      setState(() => _error = 'Objectif incomplet.');
      return;
    }
    Navigator.pop(context, g);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final suggestions = [
      for (final m in widget.draft.movements) m.exerciseId,
      if (_exercise != null &&
          !widget.draft.movements.any((m) => m.exerciseId == _exercise))
        _exercise!,
    ];
    final (valueLabel, extraLabel) = _valueLabel;
    return SingleChildScrollView(
      key: const ValueKey('goal-performance-sheet'),
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Objectif de performance', style: tt.titleLarge),
          const SizedBox(height: 12),
          Text('Exercice', style: tt.titleMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in suggestions)
                ChoiceChip(
                  key: ValueKey('goal-ex-$id'),
                  label: Text(widget.name(id)),
                  selected: _exercise == id,
                  onSelected: (_) => _choose(id),
                ),
              ActionChip(
                key: const ValueKey('goal-ex-other'),
                avatar: const Icon(Icons.search, size: 18),
                label: const Text('Autre exercice…'),
                onPressed: () async {
                  final id = await widget.pick();
                  if (id != null && mounted) _choose(id);
                },
              ),
            ],
          ),
          if (_metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Ce que tu vises', style: tt.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _metrics)
                  ChoiceChip(
                    key: ValueKey('goal-metric-${m.code}'),
                    label: Text(goalMetricLabel(m)),
                    selected: _metric == m,
                    onSelected: (_) => setState(() {
                      _metric = m;
                      _extra.text = m == GoalMetric.timeSeconds
                          ? '${(levelMovementForExercise(_exercise!)?.distanceMeters ?? 5000).round()}'
                          : '';
                    }),
                  ),
              ],
            ),
          ],
          if (_metric != null && _metric != GoalMetric.skillUnlocked) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('goal-value'),
              controller: _value,
              keyboardType: _metric == GoalMetric.timeSeconds
                  ? TextInputType.datetime
                  : const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: valueLabel),
            ),
          ],
          if (_metric != null && extraLabel != null) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('goal-extra'),
              controller: _extra,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: extraLabel),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('goal-date'),
            icon: const Icon(Icons.event_rounded),
            label: Text('D’ici le ${civilText(_date)}'),
            onPressed: () async {
              final first = dateOfCivil(widget.today.addDays(7));
              final d = await showDatePicker(
                context: context,
                initialDate: dateOfCivil(_date),
                firstDate: first,
                lastDate: DateTime(first.year + 5),
              );
              if (d != null && mounted) setState(() => _date = civilOf(d));
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const ValueKey('goal-error'),
              style: tt.bodySmall?.copyWith(color: SL.accent),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('goal-save'),
            onPressed: _save,
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

/// Choix d'un exercice du catalogue (objectif « autre exercice »).
class ExercisePickerPage extends StatefulWidget {
  const ExercisePickerPage({super.key});

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  final _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = searchExercises(
      store.content,
      _q,
      const ExerciseFilters(),
    ).take(40).toList();
    return KScreen(
      appBar: AppBar(title: const Text('CHOISIR UN EXERCICE')),
      body: KList(
        key: const ValueKey('exercise-picker'),
        children: [
          KSearch(
            controller: _c,
            hint: 'Chercher un exercice',
            onChanged: (v) => setState(() => _q = v),
          ),
          for (final e in list)
            ListTile(
              key: ValueKey('picker-${e.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(e.nom),
              subtitle: Text(e.discipline),
              onTap: () => Navigator.pop(context, e.id),
            ),
        ],
      ),
    );
  }
}
