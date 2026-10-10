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

import 'athlete_profile.dart';
import 'athlete_profile_screen.dart';
import 'content_pack.dart' show ContentIndex, ExerciseEntry;
import 'exercise_screens.dart' show searchExercises, ExerciseFilters;
import 'goal_suggestions_g6.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'muscle_map_2d.dart';
import 'plan/plan_screens.dart' show openPlanCreation;
import 'profile_v3.dart';
import 'program_explainer.dart';
import 'program_screens.dart' show ProgramScreen;
import 'store.dart';
import 'ui.dart';
import 'wellbeing_screens.dart' show DisclaimerCard, MinorGate;

part 'athlete_profile_flow_v3.dart';

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
    final k = KTokens.of(context);
    final resume = store.athleteDraft?.mode == 'redo';
    return _FlowPage(
      title: 'Ton profil',
      listKey: const ValueKey('redo-proposal'),
      actions: [
        KPrimaryButton(
          key: const ValueKey('redo-start'),
          label: resume ? 'Reprendre mon profil' : 'Refaire mon profil',
          onPressed: onStart,
        ),
        KTonalButton(
          key: const ValueKey('redo-later'),
          label: 'Plus tard',
          expand: true,
          onPressed: onLater,
        ),
      ],
      children: [
        KoachSurface(
          color: k.fond,
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
        Text(
          'Si tu choisis « Plus tard », je te le reproposerai demain.',
          textAlign: TextAlign.center,
          style: KType.detail.copyWith(color: k.texte2),
        ),
      ],
    );
  }
}

/// Page du parcours (UI4) : en-tête standard (retour, titre) ou, sans
/// retour possible, titre en tête de page ; une barre fixe sous l'en-tête
/// ([top], segments de progression) ; contenu qui défile ; actions fixées en
/// bas de l'écran, zone du pouce, au-dessus du clavier.
class _FlowPage extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  /// Clé de l'en-tête (le bouton retour s'y trouve).
  final Key? barKey;
  final Key? listKey;
  final Widget? top;
  final List<Widget> children, actions;
  const _FlowPage({
    required this.title,
    this.onBack,
    this.barKey,
    this.listKey,
    this.top,
    required this.children,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final list = ListView.separated(
      key: listKey,
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: KSpacing.cardGap),
      itemBuilder: (_, i) => children[i],
    );
    return Scaffold(
      backgroundColor: k.fond,
      appBar: onBack == null
          ? null
          : KTopBar.sub(key: barKey, title: title, onBack: onBack),
      body: SafeArea(
        top: onBack == null,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onBack == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpacing.page,
                      KSpacing.s16,
                      KSpacing.page,
                      KSpacing.s4,
                    ),
                    child: Semantics(
                      header: true,
                      child: KFitTitle(
                        k.title(title),
                        style: k.titleStyle(
                          KType.titreEcran.copyWith(color: k.texte),
                        ),
                      ),
                    ),
                  ),
                if (top != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: KSpacing.page,
                      right: KSpacing.page,
                      top: KSpacing.s8,
                    ),
                    child: top,
                  ),
                Expanded(child: list),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpacing.page,
                      KSpacing.s8,
                      KSpacing.page,
                      KSpacing.s16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(height: KSpacing.s8),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progression du parcours en segments (UI4) : une pilule par étape
/// montrée, séparées de 4 ; faites en `validation`, courante en `pleine`,
/// à venir en `haute`. Lue « Étape n sur N ».
class _FlowProgress extends StatelessWidget {
  final int position, count;
  const _FlowProgress({required this.position, required this.count});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      label: 'Étape $position sur $count',
      child: ExcludeSemantics(
        child: Row(
          key: const ValueKey('flow-progress'),
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: KSpacing.s4),
              Expanded(
                child: Container(
                  key: ValueKey('flow-progress-$i'),
                  height: KSpacing.s8,
                  decoration: ShapeDecoration(
                    color: i < position - 1
                        ? k.validation
                        : i == position - 1
                        ? k.pleine
                        : k.haute,
                    shape: i < position ? KRadius.pill : k.controlPill,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bas d'une sous-page de formulaire (ex-feuille) : bouton principal.
class _FormBottom extends StatelessWidget {
  final Widget child;
  const _FormBottom({required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s16,
      ),
      child: child,
    ),
  );
}

/// Création (installation neuve), refaire son profil (D1.6), modifier
/// une rubrique (Réglages › Profil) ou, CU, compléter son profil (questions
/// du schéma 3 seulement : utilisateurs existants, questions reportées).
enum AthleteFlowMode { create, redo, edit, complete }

class AthleteProfileFlow extends StatefulWidget {
  final AthleteFlowMode mode;

  /// Rubrique modifiée (mode [AthleteFlowMode.edit]).
  final String? editStep;
  final VoidCallback? onDone, onCancel;

  /// Mode [AthleteFlowMode.complete] : seulement les questions reportées
  /// après la première semaine (sinon toutes celles du schéma 3).
  final bool deferredOnly;
  const AthleteProfileFlow({
    super.key,
    this.mode = AthleteFlowMode.create,
    this.editStep,
    this.onDone,
    this.onCancel,
    this.deferredOnly = false,
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

  /// Résultats affichés de la recherche d'exercices (« Afficher plus »).
  int _shown = 20;

  // CU : état d'écran des questions du schéma 3.
  bool _unknownBenchmarks = false;
  final List<String> _extraRecentRows = [];
  final List<String> _extraWeakRows = [];
  String? _runVolume, _runSessions;
  bool _otherSportOpen = false;
  final _targetWeight = TextEditingController();

  /// Questions montrées (identifiants), recalculées à chaque construction.
  Set<String> _visible = const {};

  /// Compléter son profil sans niveau déclaré : la question du niveau est
  /// ajoutée (elle ouvre les autres).
  bool _askExperience = false;

  /// UI4 : « Passer » de chaque question de l'étape affichée (relevés à la
  /// construction) ; le « Passer » de l'étape les applique tous.
  final List<VoidCallback> _stepSkips = [];

  /// UI4 : jours dont la durée se règle en place (« Autre »).
  final Set<int> _minutesOpen = {};

  bool get _edit => widget.mode == AthleteFlowMode.edit;
  bool get _complete => widget.mode == AthleteFlowMode.complete;
  String get _modeCode =>
      widget.mode == AthleteFlowMode.redo ? 'redo' : 'create';

  /// Étape courante (tests).
  String get step => _step;

  /// Brouillon (tests).
  ProfileDraft get draft => _d;

  /// CU : étapes montrées et questions visibles (tests).
  List<String> get visibleSteps => _steps;
  Set<String> get visibleQuestionIds => _visible;

  /// CU : aller à une étape (tests).
  @visibleForTesting
  void debugGo(String step) => _go(step);

  DateTime get _now => store.storeClock();

  @override
  void initState() {
    super.initState();
    if (_edit) {
      _d = store.athleteEditDraft();
      _step = widget.editStep ?? 'identity';
    } else if (_complete) {
      _d = store.athleteEditDraft();
      _askExperience = _d.experience == null && !widget.deferredOnly;
      _visible = _computeVisible();
      final steps = _steps;
      _step = steps.isEmpty ? 'recap' : steps.first;
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
    final tw = _d.targetBodyWeightKg;
    if (tw != null) _targetWeight.text = numText(tw);
    _visible = _computeVisible();
    if (!_edit && !_steps.contains(_step)) _step = _nearestStep(_step);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Change l'état de l'écran (questions du schéma 3, part
  /// athlete_profile_flow_v3.dart).
  void _update(VoidCallback f) => setState(f);

  /// Questions du parcours montrées pour le brouillon (identifiants) :
  /// `ProfileQuestionnaire` décide, l'écran ne code aucune condition.
  Set<String> _computeVisible() {
    final p = store.content.questionnaire;
    if (p == null) return kV2QuestionIds;
    final json = _d.conditionJson();
    final year = _now.year;
    final List<ProfileQuestion> qs = switch (widget.mode) {
      AthleteFlowMode.create ||
      AthleteFlowMode.redo => p.visibleQuestions(json, todayYear: year),
      AthleteFlowMode.edit => p.visibleQuestions(
        json,
        todayYear: year,
        includeDeferred: true,
      ),
      AthleteFlowMode.complete =>
        widget.deferredOnly
            ? p.deferredQuestions(json, todayYear: year)
            : p.visibleQuestions(
                json,
                todayYear: year,
                since: 3,
                includeDeferred: true,
              ),
    };
    return {for (final q in qs) q.id, if (_askExperience) 'experience_level'};
  }

  /// Question montrée.
  bool _show(String id) => _visible.contains(id);

  /// Étapes montrées pour le brouillon (une étape sans question visible ne
  /// l'est pas) ; accueil et récapitulatif hors du mode « compléter ».
  List<String> get _steps {
    final p = store.content.questionnaire;
    final screens = <String>{
      for (final id in _visible)
        if (p?.question(id)?.screen case final s?) s,
    };
    return [
      for (final s in kAthleteSteps)
        if (s == 'welcome' || s == 'recap'
            ? !_complete
            : p == null
            ? s != 'experience' && s != 'recovery'
            : screens.contains(kStepScreens[s]))
          s,
    ];
  }

  /// Étape montrée la plus proche après [step] (reprise d'un brouillon).
  String _nearestStep(String step) {
    final steps = _steps;
    final i = kAthleteSteps.indexOf(step);
    for (final s in steps) {
      if (kAthleteSteps.indexOf(s) >= i) return s;
    }
    return steps.isEmpty ? 'recap' : steps.last;
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
    for (final c in [
      _year,
      _height,
      _weight,
      _nameCtl,
      _search,
      _targetWeight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _saveDraft() {
    if (_edit || _complete || _saved != null) return;
    if (_minor || _d.isMinorIn(_now.year)) {
      unawaited(store.saveAthleteDraft(null));
      return;
    }
    unawaited(store.saveAthleteDraft(_d, step: _step, mode: _modeCode));
  }

  int get _index => _steps.indexOf(_step);

  void _go(String step) {
    setState(() => _step = step);
    _saveDraft();
  }

  /// Dernière étape du mode « compléter » (son bouton enregistre).
  bool get _lastComplete => _complete && _index >= _steps.length - 1;

  void _toast(String text, {KoachPose pose = KoachPose.oops}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    showKoachToast(context, text, pose: pose);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    final err = _d.stepError(
      _step,
      _now,
      parcours: store.content.questionnaire,
    );
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
    if (_edit || _lastComplete) {
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
    final steps = _steps;
    final i = steps.indexOf(_step);
    _go(i < 0 ? _nearestStep(_step) : steps[i + 1]);
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
      _go(_steps[_index - 1]);
    } else if (_complete) {
      Navigator.of(context).maybePop();
    } else {
      widget.onCancel?.call();
    }
  }

  /// UI4 : « Passer » est proposé sur une étape facultative — que
  /// `stepError` accepte vide, ou dont toutes les questions montrées sont du
  /// schéma 3 —, jamais sur l'accueil, le récapitulatif, une rubrique
  /// modifiée ni la dernière étape de « Compléter mon profil ».
  bool get _skippable {
    if (_edit || _minor || _step == 'welcome' || _step == 'recap') {
      return false;
    }
    if (_lastComplete) return false;
    final p = store.content.questionnaire;
    if (ProfileDraft().stepError(_step, _now, parcours: p) == null) {
      return true;
    }
    if (p == null) return false;
    final screen = kStepScreens[_step];
    final qs = [
      for (final id in _visible)
        if (p.question(id) case final q? when q.screen == screen) q,
    ];
    return qs.isNotEmpty && qs.every((q) => q.since >= 3);
  }

  /// UI4 : « Passer » l'étape : chaque question de l'étape revient sans
  /// réponse (le « Passer » de la question, D5.8), puis l'étape suivante,
  /// sans validation. Les questions du schéma 3 laissées ainsi sont
  /// retenues comme passées à l'enregistrement, comme aujourd'hui.
  void _skipStep() {
    FocusScope.of(context).unfocus();
    final skips = List<VoidCallback>.of(_stepSkips);
    setState(() {
      for (final f in skips) {
        f();
      }
      _visible = _computeVisible();
    });
    if (_fromRecap) {
      _fromRecap = false;
      _go('recap');
      return;
    }
    final steps = _steps;
    final i = steps.indexOf(_step);
    if (i >= 0 && i + 1 >= steps.length) {
      _next();
      return;
    }
    _go(i < 0 ? _nearestStep(_step) : steps[i + 1]);
  }

  void _save() {
    // CU : questions du schéma 3 montrées et laissées sans réponse =
    // passées (retenues hors du profil, jamais reproposées d'office).
    final passed = <String>[
      if (!_edit)
        for (final id in _visible)
          if (store.content.questionnaire?.question(id) case final q?
              when q.since >= 3 && !_d.answered(q))
            id,
    ];
    final res = store.saveAthleteProfile(
      _d,
      createdByV3:
          widget.mode == AthleteFlowMode.create ||
          widget.mode == AthleteFlowMode.redo,
    );
    if (res == null) {
      final first = _d.firstIncomplete(
        _now,
        parcours: store.content.questionnaire,
      );
      _toast(
        first == null
            ? 'Profil incomplet.'
            : 'Il manque une réponse : ${kRubricTitles[first] ?? first}.',
      );
      if (first != null && !_edit && !_complete) _go(first);
      return;
    }
    unawaited(store.addSkippedProfileQuestions(passed));
    if (_complete) {
      // Fermeture directe : le retour arrière du système (PopScope) ramène
      // à l'étape précédente tant que le profil n'est pas enregistré.
      Navigator.of(context).pop(res);
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
    _visible = _computeVisible();
    final title = _minor
        ? 'Réservée aux adultes'
        : _edit
        ? (kRubricTitles[_step] ?? 'Profil')
        : _complete
        ? 'Compléter mon profil'
        : switch (_step) {
            'welcome' =>
              widget.mode == AthleteFlowMode.redo ? 'Ton profil' : 'Bienvenue',
            'recap' => 'Récapitulatif',
            _ => kRubricTitles[_step] ?? '',
          };
    final steps = _complete ? _steps.length : _steps.length - 1;
    final position = _complete ? _index + 1 : _index;
    final canBack =
        _minor ||
        _edit ||
        _complete ||
        _index > 0 ||
        (widget.onCancel != null && _step == 'welcome');
    // « Passer » de chaque question, relevés pendant la construction.
    _stepSkips.clear();
    final body = _minor ? _minorStep() : _stepBody();
    return PopScope(
      canPop: (_edit || (_complete && _index <= 0)) && !_minor,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _FlowPage(
        title: title,
        onBack: canBack ? _back : null,
        barKey: const ValueKey('flow-back'),
        listKey: ValueKey('flow-${_minor ? 'minor' : _step}'),
        top: !_minor && !_edit && position > 0 && steps > 0
            ? _FlowProgress(position: position, count: steps)
            : null,
        actions: _minor
            ? [
                KPrimaryButton(
                  key: const ValueKey('minor-back'),
                  label: 'Corriger mon année de naissance',
                  onPressed: _back,
                ),
              ]
            : _actions(),
        children: [
          ...body,
          if (!_minor && _step == 'welcome') const DisclaimerCard(),
        ],
      ),
    );
  }

  /// Bouton principal (et « Passer » sur une étape facultative), fixés en
  /// bas de l'écran.
  List<Widget> _actions() {
    final label = _edit || _lastComplete
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
    final main = KPrimaryButton(
      key: ValueKey(
        _edit || _lastComplete
            ? 'flow-save'
            : (_fromRecap ? 'flow-to-recap' : 'flow-next-$_step'),
      ),
      label: label,
      onPressed: _next,
    );
    if (!_skippable) return [main];
    final skip = KTextButton(
      key: ValueKey('flow-skip-$_step'),
      label: 'Passer',
      onPressed: _skipStep,
    );
    // Grand texte : « Passer » au-dessus du bouton principal, pour qu'aucun
    // libellé ne soit coupé (C3) ; sinon à côté.
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) return [skip, main];
    return [
      Row(
        children: [
          skip,
          const SizedBox(width: KSpacing.s8),
          Expanded(child: main),
        ],
      ),
    ];
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
            const SizedBox(height: KSpacing.s8),
            _hint('Aucune donnée n’a été enregistrée.'),
          ],
        ),
      ),
    ),
  ];

  /// Koach présente l'étape.
  Widget _koach(KoachPose pose, String text, {String? why}) => KoachSurface(
    color: KTokens.of(context).fond,
    child: KoachBubble(
      key: ValueKey('flow-koach-$_step'),
      pose: pose,
      text: text,
      why: why,
      koachHeight: 76,
      seed: kAthleteSteps.indexOf(_step),
    ),
  );

  Widget _title(String t) => Text(
    t,
    style: KType.corpsFort.copyWith(color: KTokens.of(context).texte),
  );
  Widget _hint(String t) =>
      Text(t, style: KType.detail.copyWith(color: KTokens.of(context).texte2));

  /// Choix en puces du kit (UI4) : une puce choisie prend l'aplat `pleine`.
  /// Un nouvel appui sur une puce choisie la décoche (`onSelected(o, false)`),
  /// comme les anciennes puces Material.
  Widget _chips<T>({
    required String keyPrefix,
    required List<(T, String)> options,
    required bool Function(T) selected,
    required void Function(T, bool) onSelected,
    bool multi = false,
    bool Function(T)? enabled,
  }) => Wrap(
    spacing: KSpacing.s8,
    children: [
      for (final o in options)
        KChip(
          o.$2,
          key: ValueKey('$keyPrefix-${_keyOf(o.$1)}'),
          selected: selected(o.$1),
          onTap: multi && enabled != null && !enabled(o.$1) && !selected(o.$1)
              ? null
              : () => setState(() => onSelected(o.$1, !selected(o.$1))),
        ),
    ],
  );

  /// Code stable d'une option (code du contrat pour un enum).
  static String _keyOf(Object? v) => switch (v) {
    Sex x => x.code,
    Place x => x.code,
    TrainingDiscipline x => x.code,
    ExperienceLevel x => x.code,
    _ => '$v',
  };

  List<Widget> _stepBody() => switch (_step) {
    'welcome' => _welcome(),
    'identity' => _identity(),
    'discipline' => _discipline(),
    'secondary' => _secondary(),
    'experience' => _experienceStep(),
    'levels' => _levels(),
    'goals' => _goals(),
    'availability' => _availability(),
    'places' => _places(),
    'recovery' => _recoveryStep(),
    'health' => _health(),
    'preferences' => _preferences(),
    'mode' => _mode(),
    _ => _recap(),
  };

  // ------------------------------------------------------------ 1. accueil

  List<Widget> _welcome() => [
    KoachSurface(
      color: KTokens.of(context).fond,
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
            'tout modifier ensuite dans ton profil.',
      ),
    ),
    const ProgramExplainerButton(),
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
            const SizedBox(height: KSpacing.s8),
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
            const SizedBox(height: KSpacing.s4),
            _hint(
              _koachText(
                'sex',
                'Ça ne change pas ton programme : ça sert aux repères de '
                    'classement et aux catégories de compétition.',
              ),
            ),
            const SizedBox(height: KSpacing.s8),
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
            const SizedBox(height: KSpacing.s4),
            _hint('L’application est réservée aux 18 ans et plus.'),
            const SizedBox(height: KSpacing.s8),
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
              const SizedBox(height: KSpacing.s8),
              _hint('As-tu déjà fêté tes 18 ans ?'),
              const SizedBox(height: KSpacing.s8),
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
            const SizedBox(height: KSpacing.s8),
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
            const SizedBox(height: KSpacing.s12),
            ..._weightField(),
          ],
        ),
      ),
    ];
  }

  /// Poids : obligatoire en street et au poids du corps (`requiredWhen`),
  /// facultatif ailleurs (« Passer » : champ laissé vide).
  List<Widget> _weightField() {
    final required = _d.weightRequired(store.content.questionnaire, _now.year);
    return [
      _title(required ? 'Poids' : 'Poids (facultatif)'),
      const SizedBox(height: KSpacing.s4),
      _hint(
        _koachText(
          'body_weight',
          'Aux pompes ou aux tractions, c’est ton propre poids que tu '
              'soulèves. Si je le connais, je dose mieux. Personne d’autre '
              'ne le voit.',
        ),
      ),
      const SizedBox(height: KSpacing.s8),
      TextField(
        key: const ValueKey('flow-weight'),
        controller: _weight,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Poids (kg)'),
        onChanged: (v) => setState(() => _d.weight = v),
      ),
    ];
  }

  /// Carte du poids sur l'écran de la discipline : montrée dès que la
  /// discipline rend le poids obligatoire et qu'il manque, puis gardée
  /// pendant la saisie.
  bool _weightAsked = false;
  bool _needWeightCard() {
    if (!_d.weightRequired(store.content.questionnaire, _now.year)) {
      return false;
    }
    final w = _d.weightValue;
    if (w == null || w.isNaN) _weightAsked = true;
    return _weightAsked;
  }

  /// Texte de Koach d'une question du parcours (repli : [fallback]).
  String _koachText(String id, String fallback) {
    final q = store.content.questionnaire?.question(id);
    return (q == null ? null : koachOf(q)) ?? fallback;
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
    // Élément choisi : contour 1,5 dp `encre` (cahier §5.3).
    outline: selected ? KTokens.of(context).encre : null,
    onTap: () => setState(onTap),
    child: Semantics(
      selected: selected,
      button: true,
      child: Row(
        children: [
          KoachView(pose: pose, height: 52, width: 46, animate: false),
          const SizedBox(width: KSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(title),
                const SizedBox(height: KSpacing.s4),
                _hint(hint),
              ],
            ),
          ),
          const SizedBox(width: KSpacing.s8),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected
                ? KTokens.of(context).encre
                : KTokens.of(context).texte2,
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
    KMenuGroup(
      children: [
        KSwitchRow(
          key: const ValueKey('flow-street'),
          title: 'Mode street',
          subtitle: 'Streetlifting, sets & reps et calisthénie',
          value: _d.street,
          onChanged: (v) => setState(() => _d.setStreet(v)),
        ),
      ],
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
    // CU : dernier choix, la forme générale (une réponse est écrite,
    // modifiable ensuite).
    if (!_d.street)
      _option(
        key: const ValueKey('flow-discipline-unsure'),
        pose: KoachPose.shrug,
        title: 'Je ne sais pas, choisis pour moi',
        hint:
            'Je te mets en forme générale : un peu de tout, modifiable '
            'ensuite.',
        selected: false,
        onTap: () {
          _d.primary = TrainingDiscipline.generalFitness;
          _d.secondaries.remove(TrainingDiscipline.generalFitness);
        },
      ),
    // CU : poids obligatoire pour les disciplines au poids du corps.
    if (_needWeightCard())
      KCard(
        key: const ValueKey('flow-weight-card'),
        accent: KTokens.of(context).avertissement,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _weightField(),
        ),
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
            const SizedBox(height: KSpacing.s8),
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
              _title(
                '${kDisciplineLabels[p]} (principale) : ${_d.primaryPct} %',
              ),
              _hint(dosageInWords(p, _d.primaryPct)),
              for (final e in _d.secondaries.entries.toList()) ...[
                const SizedBox(height: KSpacing.s14),
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
                  const SizedBox(height: KSpacing.s14),
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
      _screenKoach(
        'levels',
        'Donne-moi une idée, même vague. Si tu ne sais pas, pas d’examen : '
            'on verra tranquillement pendant tes premières séances.',
      ),
      why:
          'Je pars de la valeur basse de ta fourchette, pour être prudent. '
          'Tes 2 ou 3 premières séances me serviront ensuite à caler tes '
          'charges.',
    ),
    // CU : les records d'abord ; les fourchettes ensuite, seulement pour
    // les mouvements sans record (PARCOURS_V3.md § 1).
    if (_show('benchmarks')) _benchmarksCard(),
    if (_show('movement_levels')) ..._movementLevelCards(),
    if (_show('skills')) _skillsCard(),
    if (_show('recent_training')) _recentTrainingCard(),
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
          'L’étoile change l’objectif principal ; le crayon (ou un appui '
          'sur l’objectif) le modifie.',
    ),
    if (_show('goals')) ..._goalList(),
    // CU : orientation, échéances, priorité, points faibles, course.
    ..._goalsV3(),
  ];

  List<Widget> _goalList() => [
    // CU : « Laisse Koach proposer » en premier (PARCOURS_V3.md, `goals`).
    KTonalButton(
      key: const ValueKey('goal-suggest'),
      icon: Icons.lightbulb_outline_rounded,
      label: 'Laisse Koach proposer',
      expand: true,
      onPressed: _suggest,
    ),
    for (var i = 0; i < _d.goals.length; i++)
      KCard(
        key: ValueKey('flow-goal-$i'),
        accent: i == 0 ? KTokens.of(context).encre : null,
        onTap: () => _editGoal(i),
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
                  const SizedBox(height: KSpacing.s4),
                  Text(goalText(_d.goals[i], _name)),
                ],
              ),
            ),
            if (i > 0)
              KIconButton(
                key: ValueKey('flow-goal-main-$i'),
                tooltip: 'En faire l’objectif principal',
                icon: Icons.star_border_rounded,
                onPressed: () => setState(() {
                  final g = _d.goals.removeAt(i);
                  _d.goals.insert(0, g);
                }),
              ),
            KIconButton(
              key: ValueKey('flow-goal-edit-$i'),
              tooltip: 'Modifier cet objectif',
              icon: Icons.edit_outlined,
              onPressed: () => _editGoal(i),
            ),
            KIconButton(
              key: ValueKey('flow-goal-remove-$i'),
              tooltip: 'Retirer cet objectif',
              icon: Icons.close_rounded,
              onPressed: () => setState(() => _d.goals.removeAt(i)),
            ),
          ],
        ),
      ),
    KTonalButton(
      key: const ValueKey('goal-add-performance'),
      icon: Icons.trending_up_rounded,
      label: 'Objectif de performance',
      expand: true,
      onPressed: _addPerformance,
    ),
    KTonalButton(
      key: const ValueKey('goal-add-habit'),
      icon: Icons.event_repeat_rounded,
      label: 'Objectif d’habitude',
      expand: true,
      onPressed: _addHabit,
    ),
  ];

  /// UI4 : formulaire (ex-feuille du bas) en sous-page `KPage.sub`, poussée
  /// par `Navigator.push` ; le résultat revient par `Navigator.pop` (cahier
  /// §4.5). [children] et [action] sont reconstruits par `set`.
  Future<T?> _openForm<T>({
    required Key key,
    required String title,
    required List<Widget> Function(BuildContext ctx, StateSetter set) children,
    required Widget Function(BuildContext ctx, StateSetter set) action,
  }) => Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => KPage.sub(
          key: key,
          title: title,
          bottom: _FormBottom(child: action(ctx, set)),
          children: children(ctx, set),
        ),
      ),
    ),
  );

  Future<void> _suggest() async {
    final list = provisionalGoalSuggestions(_d, civilOf(_now));
    final chosen = <Goal>{};
    await _openForm<void>(
      key: const ValueKey('goal-suggestions'),
      title: 'Laisse Koach proposer',
      children: (ctx, set) => [
        KoachSurface(
          color: KTokens.of(ctx).fond,
          child: KoachBubble(
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
        ),
        if (list.isNotEmpty)
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < list.length; i++)
                  _ChoiceRow(
                    key: ValueKey('goal-suggestion-$i'),
                    label: goalText(list[i], _name),
                    multi: true,
                    selected: chosen.contains(list[i]),
                    onTap: () => set(
                      () => chosen.contains(list[i])
                          ? chosen.remove(list[i])
                          : chosen.add(list[i]),
                    ),
                  ),
              ],
            ),
          ),
      ],
      action: (ctx, set) => KPrimaryButton(
        key: const ValueKey('goal-suggestions-add'),
        label: chosen.isEmpty ? 'Fermer' : 'Ajouter (${chosen.length})',
        onPressed: () => Navigator.pop(ctx),
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

  Future<String?> _pickExercise() => Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const ExercisePickerPage()));

  /// Modifie l'objectif [i] sans le supprimer (même identifiant, même
  /// place dans la liste).
  Future<void> _editGoal(int i) async {
    final g = _d.goals[i];
    if (g.kind == GoalKind.habit) {
      await _addHabit(index: i);
    } else {
      await _addPerformance(index: i);
    }
  }

  void _putGoal(Goal g, int? index) => setState(() {
    if (index == null) {
      _d.goals.add(g);
    } else {
      _d.goals[index] = g;
    }
  });

  Future<void> _addHabit({int? index}) async {
    final old = index == null ? null : _d.goals[index];
    var sessions =
        old?.sessionsPerWeek ??
        (_d.days.isEmpty ? 3 : _d.days.length.clamp(1, 7).toInt());
    var weeks = old?.weeks ?? 8;
    final ok = await _openForm<bool>(
      key: const ValueKey('goal-habit-sheet'),
      title: old == null
          ? 'Objectif d’habitude'
          : 'Modifier l’objectif d’habitude',
      children: (ctx, set) => [
        const KSectionTitle('Séances par semaine'),
        Wrap(
          spacing: KSpacing.s8,
          children: [
            for (var n = 1; n <= (sessions > 7 ? sessions : 7); n++)
              KChip(
                '$n',
                key: ValueKey('goal-sessions-$n'),
                selected: sessions == n,
                onTap: () => set(() => sessions = n),
              ),
          ],
        ),
        const KSectionTitle('Pendant'),
        Wrap(
          spacing: KSpacing.s8,
          children: [
            for (final w in {
              ...const [4, 6, 8, 12, 16, 24, 52],
              weeks,
            }.toList()..sort())
              KChip(
                '$w semaines',
                key: ValueKey('goal-weeks-$w'),
                selected: weeks == w,
                onTap: () => set(() => weeks = w),
              ),
          ],
        ),
      ],
      action: (ctx, set) => KPrimaryButton(
        key: const ValueKey('goal-save'),
        label: old == null ? 'Ajouter' : 'Enregistrer',
        onPressed: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;
    final changed =
        old == null || old.sessionsPerWeek != sessions || old.weeks != weeks;
    if (!changed) return;
    _putGoal(
      Goal(
        id: old?.id ?? nextGoalId(_d.goals),
        kind: GoalKind.habit,
        origin: GoalOrigin.user,
        createdOn: old?.createdOn ?? civilOf(_now),
        sessionsPerWeek: sessions,
        weeks: weeks,
      ),
      index,
    );
  }

  Future<void> _addPerformance({int? index}) async {
    final old = index == null ? null : _d.goals[index];
    final g = await Navigator.of(context).push<Goal>(
      MaterialPageRoute<Goal>(
        builder: (_) => _PerformanceGoalSheet(
          draft: _d,
          today: civilOf(_now),
          name: _name,
          pick: _pickExercise,
          id: old?.id ?? nextGoalId(_d.goals),
          initial: old,
        ),
      ),
    );
    if (g == null || !mounted) return;
    _putGoal(g, index);
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
            const SizedBox(height: KSpacing.s8),
            Wrap(
              spacing: KSpacing.s4,
              children: [
                for (var d = 1; d <= 7; d++)
                  Semantics(
                    label: weekdayTitle(d),
                    excludeSemantics: true,
                    selected: _d.days.containsKey(d),
                    button: true,
                    onTap: () => _toggleDay(d, days),
                    child: KChip(
                      kWeekdayShort[d - 1],
                      key: ValueKey('flow-day-$d'),
                      selected: _d.days.containsKey(d),
                      onTap: () => _toggleDay(d, days),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      for (final d in days) _dayCard(d),
    ];
  }

  void _toggleDay(int d, List<int> days) => setState(() {
    if (!_d.days.containsKey(d)) {
      _d.days[d] = _d.days.isEmpty ? 45 : _d.days[days.last] ?? 45;
    } else {
      _d.days.remove(d);
      _d.dayPlace.remove(d);
      _minutesOpen.remove(d);
    }
  });

  /// Durée d'un jour : puces des durées proposées ; « Autre » règle la
  /// durée en place (pas à pas de 5 min, de 10 à 300 min), à la place de
  /// l'ancien dialogue « Durée du <jour> » (C12).
  Widget _dayCard(int d) {
    final k = KTokens.of(context);
    final minutes = _d.days[d] ?? 45;
    final custom = !kMinutePresets.contains(minutes);
    final open = custom || _minutesOpen.contains(d);
    return KCard(
      key: ValueKey('flow-day-card-$d'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('${weekdayTitle(d)} : $minutes min'),
          const SizedBox(height: KSpacing.s8),
          Wrap(
            spacing: KSpacing.s8,
            children: [
              for (final m in kMinutePresets)
                KChip(
                  '$m min',
                  key: ValueKey('flow-min-$d-$m'),
                  selected: !open && minutes == m,
                  onTap: () => setState(() {
                    _d.days[d] = m;
                    _minutesOpen.remove(d);
                  }),
                ),
              KChip(
                'Autre',
                key: ValueKey('flow-min-$d-other'),
                selected: open,
                onTap: () => setState(() => _minutesOpen.add(d)),
              ),
            ],
          ),
          if (open) ...[
            const SizedBox(height: KSpacing.s8),
            Text(
              'Durée du ${weekdayName(d)}',
              style: KType.detail.copyWith(color: k.texte2),
            ),
            const SizedBox(height: KSpacing.s4),
            KStepper(
              key: ValueKey('flow-min-$d-stepper'),
              value: '$minutes min',
              semanticLabel: 'Durée du ${weekdayName(d)}',
              decrementLabel: 'Moins 5 minutes',
              incrementLabel: 'Plus 5 minutes',
              onDecrement: minutes <= 10
                  ? null
                  : () => setState(
                      () => _d.days[d] = minutes - 5 < 10 ? 10 : minutes - 5,
                    ),
              onIncrement: minutes >= 300
                  ? null
                  : () => setState(
                      () => _d.days[d] = minutes + 5 > 300 ? 300 : minutes + 5,
                    ),
            ),
          ],
        ],
      ),
    );
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
            const SizedBox(height: KSpacing.s8),
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
                const SizedBox(height: KSpacing.s8),
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
              const SizedBox(height: KSpacing.s8),
              Wrap(
                spacing: KSpacing.s8,
                children: [
                  for (final p in kEquipmentPresets)
                    KChip(
                      p.label,
                      key: ValueKey('flow-preset-${p.id}'),
                      onTap: () =>
                          setState(() => _d.places[current] = {...p.equipment}),
                    ),
                ],
              ),
              const SizedBox(height: KSpacing.s4),
              _hint(
                '${set.length} élément${set.length > 1 ? 's' : ''} choisi'
                '${set.length > 1 ? 's' : ''}',
              ),
            ],
          ),
        ),
        for (final g in kEquipmentGroups)
          KCard(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s16),
            child: ExpansionTile(
              key: ValueKey('flow-equip-group-${g.$1}-${current.code}'),
              tilePadding: EdgeInsets.zero,
              title: Text(g.$1),
              subtitle: Text(
                '${g.$2.where(set.contains).length} sur ${g.$2.length}',
              ),
              childrenPadding: const EdgeInsets.only(bottom: KSpacing.s12),
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Wrap(
                    spacing: KSpacing.s8,
                    children: [
                      for (final e in g.$2)
                        KChip(
                          e,
                          key: ValueKey('equip-$e'),
                          selected: set.contains(e),
                          onTap: () => setState(
                            () => set.contains(e) ? set.remove(e) : set.add(e),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      // UI4 : un choix en segments par jour (au plus 4 options) à la place
      // des menus déroulants.
      if (chosen.length > 1 && days.isNotEmpty)
        KCard(
          key: const ValueKey('flow-dayplaces'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _title('Lieu de chaque jour (facultatif)'),
              for (final d in days) ...[
                const SizedBox(height: KSpacing.s12),
                _hint(weekdayTitle(d)),
                const SizedBox(height: KSpacing.s4),
                KSegmented<Place?>(
                  key: ValueKey('flow-dayplace-$d'),
                  semanticLabel: 'Lieu du ${weekdayName(d)}',
                  segments: [
                    const KSegment<Place?>(null, 'N’importe lequel'),
                    for (final p in chosen)
                      KSegment<Place?>(p, kPlaceNames[p]!),
                  ],
                  selected: _d.dayPlace[d],
                  onChanged: (v) => setState(() {
                    if (v == null) {
                      _d.dayPlace.remove(d);
                    } else {
                      _d.dayPlace[d] = v;
                    }
                  }),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  // ------------------------------------------------------------- 9. santé

  List<Widget> _health() {
    final k = KTokens.of(context);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title('Avant de continuer'),
            const SizedBox(height: KSpacing.s8),
            const Text(kHealthInfo),
            const SizedBox(height: KSpacing.s12),
            // UI4 : même contrôle que l'accord du Profil (segments) ; les
            // choix portent les clés `segment-given` / `segment-refused`.
            KSegmented<String>(
              semanticLabel: 'Avant de continuer',
              segments: const [
                KSegment('given', 'J’accepte'),
                KSegment('refused', 'Je refuse'),
              ],
              selected: _d.consent,
              onChanged: (v) => setState(() => _d.consent = v),
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
            'ton profil.',
          ),
        ),
      if (given) ...[
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Questionnaire d’aptitude'),
              const SizedBox(height: KSpacing.s4),
              _hint(
                'Réponds par oui ou non. Sans réponse, le mode prudent '
                's’applique par défaut.',
              ),
              for (final q in kHealthQuestions) ...[
                const SizedBox(height: KSpacing.s12),
                Text(q.text),
                const SizedBox(height: KSpacing.s4),
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
              const SizedBox(height: KSpacing.s4),
              _hint(
                _koachText(
                  'limitations',
                  'Une ancienne blessure, une articulation sensible : '
                      'dis-moi ce qui la réveille, je la protège. Je ne pose '
                      'aucun diagnostic.',
                ),
              ),
              if (_d.limitations.isEmpty && !_edit) ...[
                const SizedBox(height: KSpacing.s8),
                KTonalButton(
                  key: const ValueKey('limitations-none'),
                  label: 'Non, rien',
                  onPressed: _next,
                ),
              ],
              const SizedBox(height: KSpacing.s8),
              _hint(
                'Touche la zone sur la carte, ou choisis-la dans la liste '
                '(articulations comprises).',
              ),
              const SizedBox(height: KSpacing.s8),
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
              const SizedBox(height: KSpacing.s8),
              Wrap(
                spacing: KSpacing.s8,
                children: [
                  for (final z in BodyZone.values)
                    KChip(
                      kZoneLabels[z]!,
                      key: ValueKey('zone-${z.code}'),
                      onTap: () => _editLimitation(z),
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
                  subtitle: Text(
                    limitationText(l),
                    style: KType.detail.copyWith(color: k.texte2),
                  ),
                  onTap: () => _editLimitation(l.zone, side: l.side),
                  trailing: KIconButton(
                    tooltip: 'Retirer',
                    icon: Icons.close_rounded,
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
    // CU : détails du schéma 3 (contraintes d'entraînement, jamais un
    // diagnostic) : depuis quand, gêne à l'effort, ce qui la réveille.
    var since = existing?.since;
    var resolved = since == ConstraintSince.pastResolved;
    double? effort = existing?.effortDiscomfort?.toDouble();
    final aggravated = <AggravatingMovement>{...?existing?.aggravatedBy};
    final q = store.content.questionnaire?.question('limitations');
    final beginner =
        _d.experience == null || _d.experience == ExperienceLevel.beginner;
    final allAggravating = q == null
        ? const <(String, String)>[]
        : itemOptions(q, 'aggravatedBy');
    // Un débutant ne voit que les six premières réponses et « Courir ou
    // sauter » (PARCOURS_V3.md, `limitations`).
    final aggravating = [
      for (var i = 0; i < allAggravating.length; i++)
        if (!beginner ||
            i < 6 ||
            allAggravating[i].$1 == AggravatingMovement.runningJumping.code)
          allAggravating[i],
    ];
    final sinceOpts = [
      for (final o
          in q == null ? const <(String, String)>[] : itemOptions(q, 'since'))
        if (o.$1 != ConstraintSince.pastResolved.code) o,
    ];
    const central = {
      BodyZone.neck,
      BodyZone.upperBack,
      BodyZone.lowerBack,
      BodyZone.chest,
      BodyZone.abdomen,
    };
    // UI4 : sous-page titrée du nom de la zone touchée (R3).
    final ok = await _openForm<bool>(
      key: const ValueKey('limitation-sheet'),
      title: kZoneLabels[zone]!,
      children: (ctx, set) => [
        if (zone.joint != null)
          KLead('Articulation suivie : ${kJointLabels[zone.joint]}'),
        const KSectionTitle('Côté'),
        Wrap(
          spacing: KSpacing.s8,
          children: [
            for (final b in BodySide.values)
              KChip(
                b == BodySide.both && central.contains(zone)
                    ? 'Au milieu, ou des deux côtés'
                    : kSideLabels[b]!,
                key: ValueKey('limitation-side-${b.code}'),
                selected: s == b,
                onTap: () => set(() => s = b),
              ),
          ],
        ),
        KMenuGroup(
          children: [
            KSwitchRow(
              key: const ValueKey('limitation-resolved'),
              title: 'C’est ancien, je ne sens plus rien',
              value: resolved,
              onChanged: (v) => set(() {
                resolved = v;
                if (resolved) {
                  level = 0;
                  since = ConstraintSince.pastResolved;
                } else if (since == ConstraintSince.pastResolved) {
                  since = null;
                }
              }),
            ),
          ],
        ),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!resolved) ...[
                _title('Gêne actuelle : ${level.round()}/10'),
                Slider(
                  key: const ValueKey('limitation-level'),
                  value: level,
                  max: 10,
                  divisions: 10,
                  label: '${level.round()}/10',
                  onChanged: (v) => set(() => level = v),
                ),
              ],
              _hint(
                '0 : aucune gêne aujourd’hui · 10 : la pire imaginable. Une '
                'douleur forte ou qui dure mérite l’avis d’un professionnel '
                'de santé.',
              ),
            ],
          ),
        ),
        if (q != null) ...[
          KMenuGroup(
            children: [
              KSwitchRow(
                key: const ValueKey('limitation-effort-known'),
                title: itemText(
                  q,
                  'effortDiscomfort',
                  'Quand elle se réveille pendant l’effort, elle monte à '
                      'combien ?',
                ),
                value: effort != null,
                onChanged: (v) => set(() => effort = v ? level : null),
              ),
            ],
          ),
          if (effort != null)
            KCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _title('Pendant l’effort : ${effort!.round()}/10'),
                  Slider(
                    key: const ValueKey('limitation-effort'),
                    value: effort!,
                    max: 10,
                    divisions: 10,
                    label: '${effort!.round()}/10',
                    onChanged: (v) => set(() => effort = v),
                  ),
                ],
              ),
            ),
          if (!resolved) ...[
            KSectionTitle(itemText(q, 'since', 'Depuis quand ?')),
            Wrap(
              spacing: KSpacing.s8,
              children: [
                for (final o in sinceOpts)
                  KChip(
                    o.$2,
                    key: ValueKey('limitation-since-${o.$1}'),
                    selected: since?.code == o.$1,
                    onTap: () => set(
                      () => since = since?.code == o.$1
                          ? null
                          : ConstraintSince.fromCode(o.$1),
                    ),
                  ),
              ],
            ),
          ],
          KSectionTitle(
            itemText(q, 'aggravatedBy', 'Qu’est-ce qui la réveille ?'),
          ),
          Wrap(
            spacing: KSpacing.s8,
            children: [
              for (final o in aggravating)
                KChip(
                  o.$2,
                  key: ValueKey('limitation-aggravated-${o.$1}'),
                  selected: aggravated.any((a) => a.code == o.$1),
                  onTap: () => set(() {
                    final a = AggravatingMovement.fromCode(o.$1);
                    if (!aggravated.remove(a)) aggravated.add(a);
                  }),
                ),
            ],
          ),
        ],
      ],
      action: (ctx, set) => KPrimaryButton(
        key: const ValueKey('limitation-save'),
        label: 'Enregistrer',
        onPressed: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      if (existing != null) _d.limitations.remove(existing);
      _d.putLimitation(
        limitationOf(zone, s, resolved ? 0 : level.round()).copyWith(
          since: since,
          effortDiscomfort: effort?.round(),
          aggravatedBy: aggravated.isEmpty
              ? null
              : [
                  for (final a in AggravatingMovement.values)
                    if (aggravated.contains(a)) a,
                ],
        ),
      );
    });
  }

  // ------------------------------------------------------ 10. préférences

  List<Widget> _preferences() {
    // Sans recherche : les exercices des disciplines choisies ; avec une
    // recherche : toute la base. Toujours tous les résultats, par pages.
    final disciplines = {
      for (final d in _d.disciplines)
        for (final c in d.catalogDisciplines) c.code,
    };
    final all = searchExercises(
      _content,
      _query,
      ExerciseFilters(
        disciplines: _query.trim().isEmpty ? disciplines : const {},
      ),
    );
    final results = [for (final e in all.take(_shown)) e];
    final k = KTokens.of(context);
    Widget chipList(String title, List<String> ids, String prefix) => KCard(
      key: ValueKey('flow-$prefix-list'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(title),
          const SizedBox(height: KSpacing.s8),
          if (ids.isEmpty)
            _hint('Aucun pour l’instant.')
          else
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s8,
              children: [
                for (final id in ids)
                  KChip(
                    _name(id),
                    key: ValueKey('flow-$prefix-$id'),
                    onDeleted: () => setState(() => ids.remove(id)),
                  ),
              ],
            ),
        ],
      ),
    );
    // UI4 : « Passer » l'étape laisse la question sans réponse (D5.8).
    _stepSkips.add(() {
      _d.liked.clear();
      _d.disliked.clear();
    });
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
            KSearchField(
              key: const ValueKey('flow-pref-search'),
              controller: _search,
              hint: 'Rechercher un exercice',
              onChanged: (v) => setState(() {
                _query = v;
                _shown = 20;
              }),
            ),
            const SizedBox(height: KSpacing.s8),
            _hint(
              _query.trim().isEmpty
                  ? '${all.length} exercices de tes disciplines · cherche '
                        'pour voir toute la base'
                  : '${all.length} exercice${all.length > 1 ? 's' : ''} '
                        'trouvé${all.length > 1 ? 's' : ''}',
            ),
            for (final e in results)
              ListTile(
                key: ValueKey('flow-pref-result-${e.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(e.nom),
                subtitle: Text(
                  e.discipline,
                  style: KType.detail.copyWith(color: k.texte2),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('flow-like-${e.id}'),
                      tooltip: 'J’aime',
                      isSelected: _d.liked.contains(e.id),
                      icon: const Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(
                        Icons.favorite_rounded,
                        color: k.encre,
                      ),
                      onPressed: () => setState(() {
                        _d.disliked.remove(e.id);
                        if (!_d.liked.remove(e.id)) _d.liked.add(e.id);
                      }),
                    ),
                    IconButton(
                      key: ValueKey('flow-dislike-${e.id}'),
                      tooltip: 'Je n’aime pas',
                      isSelected: _d.disliked.contains(e.id),
                      icon: const Icon(Icons.thumb_down_outlined),
                      selectedIcon: Icon(
                        Icons.thumb_down_rounded,
                        color: k.encre,
                      ),
                      onPressed: () => setState(() {
                        _d.liked.remove(e.id);
                        if (!_d.disliked.remove(e.id)) _d.disliked.add(e.id);
                      }),
                    ),
                  ],
                ),
              ),
            if (all.length > results.length)
              KTonalButton(
                key: const ValueKey('flow-pref-more'),
                label:
                    'Afficher plus (${all.length - results.length} restants)',
                onPressed: () => setState(() => _shown += 40),
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
        pose: m == GuidanceMode.assisted
            ? KoachPose.fistBump
            : KoachPose.present,
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
    const ProgramExplainerButton(),
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
        if (_steps.contains(r))
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
                      const SizedBox(height: KSpacing.s4),
                      Text(rubricSummary(r, _d, _name)),
                    ],
                  ),
                ),
                KIconButton(
                  key: ValueKey('recap-edit-$r'),
                  tooltip: 'Modifier : ${kRubricTitles[r]}',
                  icon: Icons.edit_outlined,
                  onPressed: () {
                    _fromRecap = true;
                    _go(r);
                  },
                ),
              ],
            ),
          ),
      CautionCard(status: caution),
      const ProgramExplainerButton(),
    ];
  }

  // --------------------------------------------------------- écran de fin

  Widget _doneScreen() {
    final noProgram = store.program.start == null && !store.programGenerated;
    // G7 : sans programme, Koach enchaîne sur la création du programme.
    // UI4 (R5) : plus de chemin écrit ; un bouton ouvre Mon programme.
    final text = noProgram
        ? 'Ton profil est prêt ! On crée maintenant ton programme ensemble : '
              'd’abord les exercices de chaque séance, puis les séries et les '
              'charges.'
        : 'Ton profil est enregistré. Ton programme, ton historique et tes '
              'réglages ne changent pas. Tu peux créer un nouveau programme '
              'depuis Mon programme.';
    return _FlowPage(
      title: noProgram ? 'Ton programme' : 'Ton profil',
      listKey: const ValueKey('flow-done'),
      actions: [
        if (noProgram) ...[
          KPrimaryButton(
            key: const ValueKey('flow-done-create'),
            icon: Icons.auto_awesome_outlined,
            label: 'Créer mon programme',
            onPressed: () async {
              final done = widget.onDone;
              final created = await openPlanCreation(context);
              if (created) done?.call();
            },
          ),
          KTonalButton(
            key: const ValueKey('flow-done-continue'),
            label: 'Plus tard',
            expand: true,
            onPressed: widget.onDone,
          ),
        ] else
          KPrimaryButton(
            key: const ValueKey('flow-done-continue'),
            label: 'Continuer',
            onPressed: widget.onDone,
          ),
      ],
      children: [
        KoachSurface(
          color: KTokens.of(context).fond,
          child: KoachBubble(
            key: const ValueKey('flow-done-koach'),
            pose: noProgram ? KoachPose.checklist : KoachPose.thumbsUp,
            koachHeight: 140,
            text: text,
          ),
        ),
        if (!noProgram)
          KTonalButton(
            key: const ValueKey('flow-done-program'),
            icon: Icons.calendar_month_outlined,
            label: 'Mon programme',
            expand: true,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const ProgramScreen()),
            ),
          ),
        const ProgramExplainerButton(),
      ],
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
    case 'experience':
      final q = store.content.questionnaire;
      String? opt(String id, String? code) {
        final question = q?.question(id);
        if (code == null) return null;
        return question == null ? code : optionLabel(question, code);
      }

      final lines = <String>[
        if (d.experience != null) kExperienceLabels[d.experience]!,
        ?opt('training_age', d.trainingAge?.code),
        ?opt('training_gap', d.trainingGap?.code),
      ];
      return lines.isEmpty ? 'Rien de déclaré' : lines.join(' · ');
    case 'levels':
      final q = store.content.questionnaire;
      final lines = <String>[
        for (final b in d.benchmarks ?? const <Benchmark>[])
          '${name(b.exerciseId)} : ${benchmarkText(b, q?.question('benchmarks'))}',
        for (final m in d.movements)
          if (d.levels[m.key] case final int i)
            '${m.label} : ${i < 0 ? 'je ne sais pas' : m.bands[i].label}',
        for (final sk in d.skills ?? const <SkillState>[])
          '${name(sk.targetExerciseId)} : ${name(sk.currentExerciseId)}',
        if (d.recentTraining case final r? when r.isNotEmpty)
          'En ce moment : ${r.map((x) => '${name(x.exerciseId)} ${x.sessionsPerWeek}×/sem.').join(', ')}',
      ];
      return lines.isEmpty ? 'Rien de déclaré' : lines.join('\n');
    case 'goals':
      final q = store.content.questionnaire;
      final lines = <String>[
        for (final g in d.goals) goalText(g, name),
        if (d.emphasis case final e?)
          'Musculation : ${q?.question('emphasis') == null ? e.code : optionLabel(q!.question('emphasis')!, e.code).toLowerCase()}',
        for (final e in d.events ?? const <SeasonEvent>[])
          'Échéance : ${e.name ?? kEventKindShort[e.kind] ?? e.kind.code}, '
              '${e.dateApproximate == true ? 'vers ${monthText(e.date)}' : longDateText(e.date)}',
        if (d.events case final e? when e.isEmpty) 'Aucune échéance',
        if (d.specialization case final sp?)
          'Priorité : ${specializationText(sp, q?.question('specialization'))}',
        if (d.weakPoints case final w? when w.isNotEmpty)
          'Points faibles : ${w.length}',
        if (d.enduranceBase case final b?)
          'Course : ${q?.question('running_base') == null ? b.weeklyVolume.code : itemOptionLabel(q!.question('running_base')!, 'weeklyVolume', b.weeklyVolume.code).toLowerCase()}',
      ];
      return lines.isEmpty ? 'Aucun objectif' : lines.join('\n');
    case 'recovery':
      final q = store.content.questionnaire;
      String? opt(String id, String? code) {
        final question = q?.question(id);
        if (code == null) return null;
        return question == null ? code : optionLabel(question, code);
      }

      final lines = <String>[
        ?opt('sleep', d.sleep?.code),
        ?opt('stress', d.stress?.code),
        ?opt('outside_load', d.occupationalLoad?.code),
        if (d.otherSports case final o? when o.isNotEmpty)
          '${o.length} autre${o.length > 1 ? 's' : ''} sport${o.length > 1 ? 's' : ''}',
        ?opt('body_weight_goal', d.bodyWeightGoal?.code),
      ];
      return lines.isEmpty ? 'Rien de déclaré' : lines.join(' · ');
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
            '${kZoneLabels[l.zone]} ${l.discomfort}/10'
                '${l.since == ConstraintSince.pastResolved ? ' (ancien)' : ''}',
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

/// Gêne : niveau actuel, à l'effort, depuis quand (CU).
String limitationText(Limitation l) {
  if (l.since == ConstraintSince.pastResolved) {
    return 'Ancienne, plus rien aujourd’hui';
  }
  final q = store.content.questionnaire?.question('limitations');
  return [
    'Gêne actuelle : ${l.discomfort}/10',
    if (l.effortDiscomfort != null) 'à l’effort : ${l.effortDiscomfort}/10',
    if (l.since != null && q != null)
      itemOptionLabel(q, 'since', l.since!.code).toLowerCase(),
    if (l.aggravatedBy case final a? when a.isNotEmpty)
      '${a.length} mouvement${a.length > 1 ? 's' : ''} qui la réveille${a.length > 1 ? 'nt' : ''}',
  ].join(' · ');
}

/// Objectif de performance : exercice, grandeur, valeur, échéance.
class _PerformanceGoalSheet extends StatefulWidget {
  final ProfileDraft draft;
  final CivilDate today;
  final String Function(String) name;
  final Future<String?> Function() pick;
  final String id;

  /// Objectif modifié (null : nouvel objectif).
  final Goal? initial;
  const _PerformanceGoalSheet({
    this.initial,
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
  void initState() {
    super.initState();
    final g = widget.initial;
    if (g == null) return;
    _exercise = g.exerciseId;
    _metric = g.metric;
    if (g.targetDate != null) _date = g.targetDate!;
    final v = g.targetValue;
    if (v != null) {
      _value.text = g.metric == GoalMetric.timeSeconds
          ? '${v ~/ 60}:${(v.round() % 60).toString().padLeft(2, '0')}'
          : numText(v);
    }
    final extra = switch (g.metric) {
      GoalMetric.timeSeconds => g.distanceMeters,
      GoalMetric.maxReps => g.loadKg,
      GoalMetric.distanceMeters =>
        g.durationSeconds == null ? null : g.durationSeconds! / 60,
      _ => null,
    };
    if (extra != null) _extra.text = numText(extra);
  }

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
    GoalMetric.maxReps => (
      'Répétitions visées',
      'À une charge de (kg, facultatif)',
    ),
    GoalMetric.maxHoldSeconds => ('Temps de tenue visé (secondes)', null),
    GoalMetric.timeSeconds => ('Temps visé (min:s, ex. 24:30)', 'Distance (m)'),
    GoalMetric.distanceMeters => (
      'Distance visée (m)',
      'En combien de minutes ?',
    ),
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
      if (value == null ||
          value < 0 ||
          (value == 0 && metric != GoalMetric.oneRmKg)) {
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
      createdOn: widget.initial?.createdOn ?? widget.today,
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
    final k = KTokens.of(context);
    final suggestions = [
      for (final m in widget.draft.movements) m.exerciseId,
      if (_exercise != null &&
          !widget.draft.movements.any((m) => m.exerciseId == _exercise))
        _exercise!,
    ];
    final (valueLabel, extraLabel) = _valueLabel;
    // UI4 : sous-page titrée du libellé du bouton qui y mène (R3).
    return KPage.sub(
      key: const ValueKey('goal-performance-sheet'),
      title: widget.initial == null
          ? 'Objectif de performance'
          : 'Modifier l’objectif',
      bottom: _FormBottom(
        child: KPrimaryButton(
          key: const ValueKey('goal-save'),
          label: widget.initial == null ? 'Ajouter' : 'Enregistrer',
          onPressed: _save,
        ),
      ),
      children: [
        const KSectionTitle('Exercice'),
        Wrap(
          spacing: KSpacing.s8,
          children: [
            for (final id in suggestions)
              KChip(
                widget.name(id),
                key: ValueKey('goal-ex-$id'),
                selected: _exercise == id,
                onTap: () => _choose(id),
              ),
            KChip(
              'Autre exercice…',
              key: const ValueKey('goal-ex-other'),
              icon: Icons.search_rounded,
              onTap: () async {
                final id = await widget.pick();
                if (id != null && mounted) _choose(id);
              },
            ),
          ],
        ),
        if (_metrics.isNotEmpty) ...[
          const KSectionTitle('Ce que tu vises'),
          Wrap(
            spacing: KSpacing.s8,
            children: [
              for (final m in _metrics)
                KChip(
                  goalMetricLabel(m),
                  key: ValueKey('goal-metric-${m.code}'),
                  selected: _metric == m,
                  onTap: () => setState(() {
                    _metric = m;
                    _extra.text = m == GoalMetric.timeSeconds
                        ? '${(levelMovementForExercise(_exercise!)?.distanceMeters ?? 5000).round()}'
                        : '';
                  }),
                ),
            ],
          ),
        ],
        if (_metric != null && _metric != GoalMetric.skillUnlocked)
          TextField(
            key: const ValueKey('goal-value'),
            controller: _value,
            keyboardType: _metric == GoalMetric.timeSeconds
                ? TextInputType.datetime
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: valueLabel),
          ),
        if (_metric != null && extraLabel != null)
          TextField(
            key: const ValueKey('goal-extra'),
            controller: _extra,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: extraLabel),
          ),
        KMenuGroup(
          children: [
            KMenuRow(
              key: const ValueKey('goal-date'),
              icon: Icons.event_rounded,
              title: 'D’ici le ${civilText(_date)}',
              onTap: () async {
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
          ],
        ),
        if (_error != null)
          Text(
            _error!,
            key: const ValueKey('goal-error'),
            style: KType.detail.copyWith(color: k.danger),
          ),
      ],
    );
  }
}

/// Choix d'un exercice du catalogue (objectif « autre exercice »). CU :
/// exercices proposés d'abord ([suggested]) ou choix restreint ([only]).
class ExercisePickerPage extends StatefulWidget {
  final List<String> suggested;
  final List<String>? only;
  final String title;
  const ExercisePickerPage({
    super.key,
    this.suggested = const [],
    this.only,
    this.title = 'Choisir un exercice',
  });

  @override
  State<ExercisePickerPage> createState() => _ExercisePickerPageState();
}

class _ExercisePickerPageState extends State<ExercisePickerPage> {
  final _c = TextEditingController();
  String _q = '';
  int _shown = 40;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final only = widget.only?.toSet();
    final found = searchExercises(store.content, _q, const ExerciseFilters());
    final all = [
      for (final e in found)
        if (only == null || only.contains(e.id)) e,
    ];
    final list = all.take(_shown).toList();
    final suggested = _q.trim().isEmpty
        ? [
            for (final id in widget.suggested)
              if (store.content.byId[id] case final e?
                  when only == null || only.contains(id))
                e,
          ]
        : const <ExerciseEntry>[];
    // UI4 : sous-page du kit, titre en capitales par le style (U3).
    return KPage.sub(
      key: const ValueKey('exercise-picker'),
      title: widget.title,
      children: [
        KSearchField(
          controller: _c,
          hint: 'Rechercher un exercice',
          onChanged: (v) => setState(() {
            _q = v;
            _shown = 40;
          }),
        ),
        if (suggested.isNotEmpty)
          KMenuGroup(
            title: 'Proposés',
            children: [
              for (final e in suggested)
                KMenuRow(
                  key: ValueKey('picker-suggested-${e.id}'),
                  icon: Icons.star_outline_rounded,
                  title: e.nom,
                  subtitle: e.discipline,
                  onTap: () => Navigator.pop(context, e.id),
                ),
            ],
          ),
        if (list.isNotEmpty)
          KMenuGroup(
            title: suggested.isNotEmpty ? 'Toute la base' : null,
            dividerIndent: KSpacing.s16,
            children: [
              for (final e in list)
                KMenuRow(
                  key: ValueKey('picker-${e.id}'),
                  title: e.nom,
                  subtitle: e.discipline,
                  onTap: () => Navigator.pop(context, e.id),
                ),
            ],
          ),
        if (all.length > list.length)
          KTonalButton(
            key: const ValueKey('picker-more'),
            label: 'Afficher plus (${all.length - list.length} restants)',
            expand: true,
            onPressed: () => setState(() => _shown += 40),
          ),
      ],
    );
  }
}
