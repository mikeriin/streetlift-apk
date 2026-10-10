// G7 (D4.3 à D4.7, D6.4) : création du programme en deux passes avec Koach.
//
// Passe 1 : une carte par jour (exercices sans séries), carte des muscles
// de la semaine et répartition par discipline, « Autre proposition » et
// retour aux propositions précédentes. Revue exercice par exercice (« Je
// sais faire » / « Je ne sais pas faire » / « Je n'aime pas », variantes,
// ajout, retrait), chaque changement relancé par `kalis_plan` avec tous les
// verrous et expliqué par Koach (diff, « Annuler ce changement »).
// Récapitulatif, « Valider les exercices ». Passe 2 : séries, répétitions,
// flammes visées, repos, charges prudentes « à calibrer », semaine par
// semaine ; ajustements bornés ; « Valider mon programme ».
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;
import 'package:kalis_plan/kalis_plan.dart' show PlanInspector, PlanMetrics;

import '../athlete_profile_flow.dart' show AthleteFlowMode, AthleteProfileFlow;
import '../dev/dev_flags.dart';
import '../exercise_screens.dart' show openExerciseSheet;
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart' show KoachSurface;
import '../muscle_map_2d.dart';
import '../program_screens.dart' show ProgramScreen;
import '../session_prefs.dart' show SessionSpace;
import '../store.dart';
import '../ui.dart';
import 'plan_creation.dart';
import 'plan_inspector.dart';
import 'plan_program.dart';
import 'plan_sheets.dart';
import 'plan_texts.dart';

/// G10 (D4.8) : fin de bloc — le bloc suivant proposé par le moteur, passé
/// en revue (nouveaux exercices) puis validé ; vrai s'il a été validé.
Future<bool> openNextBlock(BuildContext context) async {
  // CI1e (C11) : fin d'un bloc du programme importé (programme de 40
  // semaines) : le moteur calibré peut écrire le bloc suivant à la place de
  // la suite du programme ; jamais imposé.
  // UI4 (R9) : « moteur calibré » n'est plus écrit à l'écran.
  final seg = PlanStore(store).planImportedSegment;
  if (seg != null) {
    final ends = seg.last >= store.importedLastWeek;
    final offer = ends
        ? 'Ton programme se termine en semaine ${seg.last}. Je peux écrire '
              'ton prochain bloc d’après ton profil et tes séances.'
        : 'Ton programme continue tel qu’il est écrit après la semaine '
              '${seg.last}. Je peux aussi écrire ton prochain bloc d’après '
              'ton profil et tes séances : il remplace alors la suite de ton '
              'programme.';
    final choice = await showKoachSheet<String>(
      context,
      pose: KoachPose.choice,
      title: 'Ton prochain bloc',
      text:
          '$offer Ton programme d’origine reste sauvegardé : tu pourras y '
          'revenir depuis Mon programme.',
      actions: [
        KoachBubbleAction(
          'Voir mon prochain bloc',
          () => Navigator.of(context).pop('calibrated'),
          primary: true,
          key: const ValueKey('next-block-calibrated'),
        ),
        KoachBubbleAction(
          ends ? 'Plus tard' : 'Garder mon programme',
          () => Navigator.of(context).pop('keep'),
          key: const ValueKey('next-block-keep'),
        ),
      ],
    );
    if (choice != 'calibrated' || !context.mounted) return false;
  }
  // CI1 : programme écrit par le moteur d'avant, profil street calibrable :
  // le passage au moteur calibré est proposé ici, à la fin du bloc, jamais
  // imposé (il reste possible plus tard).
  if (PlanStore(store).planOnLegacyEngine) {
    final choice = await showKoachSheet<String>(
      context,
      pose: KoachPose.choice,
      title: 'Ton prochain bloc',
      text:
          'Nouveau : je peux écrire ton prochain bloc avec ma nouvelle '
          'méthode pour le street — saison calée sur ton échéance, séries '
          'de tête et séries allégées, maintiens chronométrés, tests. Ou je '
          'garde la même façon de faire que ton bloc actuel. Tu pourras '
          'changer d’avis au bloc suivant.',
      actions: [
        KoachBubbleAction(
          'Passer à la nouvelle méthode',
          () => Navigator.of(context).pop('calibrated'),
          primary: true,
          key: const ValueKey('next-block-calibrated'),
        ),
        KoachBubbleAction(
          'Garder la méthode actuelle',
          () => Navigator.of(context).pop('legacy'),
          key: const ValueKey('next-block-legacy'),
        ),
      ],
    );
    if (choice == null) return false;
    PlanStore(store).setPlanKeepLegacyEngine(choice == 'legacy');
    if (!context.mounted) return false;
  }
  // UI4 (R6) : ouvert depuis Mon programme, « Revenir à Mon programme »
  // referme la page ; ouvert depuis l'accueil, il ouvre Mon programme.
  final inProgram = context.findAncestorWidgetOfExactType<ProgramScreen>();
  final c = PlanStore(store).newNextBlockCreation();
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => c == null
          ? NextBlockUnavailable(openProgram: inProgram == null)
          : PlanCreationScreen(creation: c),
    ),
  );
  return ok == true;
}

/// Bloc suivant impossible à préparer (profil ou base absents, erreur du
/// moteur) ; UI4 (R6) : jamais un cul-de-sac, « Revenir à Mon programme ».
class NextBlockUnavailable extends StatelessWidget {
  /// Vrai : la page remplace par Mon programme (ouverte hors de Mon
  /// programme) ; faux : elle se referme sur Mon programme.
  final bool openProgram;
  const NextBlockUnavailable({super.key, this.openProgram = false});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return KPage.sub(
      title: 'Bloc suivant',
      children: [
        KoachSurface(
          color: k.fond,
          child: const KoachBubble(
            key: ValueKey('next-block-unavailable'),
            pose: KoachPose.oops,
            koachHeight: 100,
            text: 'Je n’arrive pas à préparer le bloc suivant pour l’instant.',
          ),
        ),
        KTonalButton(
          key: const ValueKey('next-block-unavailable-back'),
          label: 'Revenir à Mon programme',
          icon: Icons.event_note_outlined,
          expand: true,
          onPressed: () {
            final nav = Navigator.of(context);
            if (openProgram) {
              nav.pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const ProgramScreen()),
              );
            } else {
              nav.pop(false);
            }
          },
        ),
      ],
    );
  }
}

/// Ouvre la création du programme ; vrai si un programme a été validé.
Future<bool> openPlanCreation(BuildContext context) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(builder: (_) => const PlanCreationScreen()),
  );
  return ok == true;
}

/// Intensités de la carte des muscles pour une liste d'exercices (séries
/// par exercice, 1 sans passe 2) : principaux 1, secondaires 0,5.
Map<String, double> planMuscleIntensities(Iterable<(String, int)> items) {
  final w = <String, double>{};
  for (final (id, sets) in items) {
    final d = store.content.detail(id);
    if (d == null) continue;
    for (final m in d.primaires) {
      w[m] = (w[m] ?? 0) + sets;
    }
    for (final m in d.secondaires) {
      w[m] = (w[m] ?? 0) + sets * .5;
    }
  }
  return mapIntensitiesFromWeights(w);
}

enum _Stage { pass1, review, recap, pass2 }

class PlanCreationScreen extends StatefulWidget {
  /// Création injectée (tests) ; sinon celle du magasin.
  final PlanCreation? creation;
  const PlanCreationScreen({super.key, this.creation});

  @override
  State<PlanCreationScreen> createState() => PlanCreationScreenState();
}

class PlanCreationScreenState extends State<PlanCreationScreen> {
  /// Création en cours ; null sans profil (UI4, R6 : recalculée au retour
  /// de « Créer mon profil »).
  late PlanCreation? c = widget.creation ?? PlanStore(store).newPlanCreation();
  _Stage _stage = _Stage.pass1;
  bool _busy = false;
  String? _error;
  int _page = 0;
  int _week = 0;
  final PageController _pages = PageController();
  kc.Pass1Plan? _metricsFor;
  PlanMetrics? _metrics;

  bool get _dev => kDevBuild && SessionSpace.isDev;

  /// G10 : bloc suivant (revue des nouveaux exercices seulement).
  bool get _isNext => c?.isNext ?? false;

  @override
  void initState() {
    super.initState();
    if (c != null && !c!.started) _run(() => c!.start());
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Appel au moteur après l'affichage de l'attente (Koach réfléchit).
  Future<T?> _run<T>(T Function() fn) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    T? r;
    try {
      r = fn();
    } catch (e) {
      _error =
          'Je n’ai pas pu faire ce changement. Réessaie ou choisis '
          'autre chose.';
    }
    if (mounted) setState(() => _busy = false);
    return r;
  }

  PlanMetrics? _metricsOf(kc.Pass1Plan plan) {
    if (identical(_metricsFor, plan)) return _metrics;
    _metricsFor = plan;
    try {
      _metrics = PlanInspector(c!.catalog).metrics(c!.request(), plan);
    } catch (_) {
      _metrics = null;
    }
    return _metrics;
  }

  // ------------------------------------------------------------ navigation

  void _back() {
    switch (_stage) {
      case _Stage.pass1:
        _confirmLeave();
      case _Stage.review:
        setState(() => _stage = _Stage.pass1);
      case _Stage.recap:
        setState(() => _stage = _Stage.review);
      case _Stage.pass2:
        setState(() => _stage = _Stage.recap);
    }
  }

  /// UI4 (§4.5) : confirmation au gabarit, titrée (elle n'avait pas de
  /// titre).
  Future<void> _confirmLeave() async {
    final nav = Navigator.of(context);
    final leave = await showKConfirm(
      context,
      title: 'Quitter la création ?',
      message: _isNext
          ? 'Ton bloc suivant n’est pas encore validé : rien n’est '
                'enregistré, je te le reproposerai.'
          : 'Ton programme n’est pas encore créé : rien n’est enregistré.',
      confirmLabel: 'Quitter',
      cancelLabel: 'Continuer la création',
    );
    if (leave) nav.pop(false);
  }

  /// UI4 (R6) : création sans profil → « Créer mon profil » ouvre le
  /// parcours de création du profil (même entrée que la page Profil) ; au
  /// retour, la création démarre si le profil existe.
  Future<void> _createProfile() async {
    final nav = Navigator.of(context);
    final before = store.planProgram;
    await nav.push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => AthleteProfileFlow(
          mode: AthleteFlowMode.redo,
          onDone: () => Navigator.pop(ctx),
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
    if (!mounted) return;
    // Programme créé depuis la fin du parcours : rien à refaire ici.
    if (!identical(store.planProgram, before)) {
      nav.pop(true);
      return;
    }
    final next = PlanStore(store).newPlanCreation();
    if (next == null) return;
    setState(() => c = next);
    _run(next.start);
  }

  // ----------------------------------------------------------------- revue

  List<({kc.PlanDay day, kc.PlanSlot slot})> get _slots => [
    for (final d in c!.plan.days)
      for (final s in d.slots)
        if (!_isNext || c!.newSlotIds.contains(s.slotId) || !_wasKnown(s))
          (day: d, slot: s),
  ];

  /// Bloc suivant : exercice déjà fait au bloc précédent.
  bool _wasKnown(kc.PlanSlot s) {
    final prev = c?.previous;
    if (prev == null) return false;
    return prev.pass1.days.any(
      (d) => d.slots.any((x) => x.exerciseId == s.exerciseId),
    );
  }

  Future<void> _afterStep(PlanStep? step) async {
    if (step == null || !mounted) return;
    if (step.changes.isEmpty && step.label == 'Je sais faire') {
      showKoachToast(context, 'Noté : tu sais le faire.');
      _next();
      return;
    }
    final undo = await showStepSheet(context, step);
    if (undo && mounted) {
      c!.undo();
      showKoachToast(context, 'Changement annulé.', pose: KoachPose.thumbsUp);
    }
    if (mounted) setState(() {});
  }

  void _next() {
    final n = _slots.length;
    if (_page + 1 < n) {
      _pages.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      setState(() => _stage = _Stage.recap);
    }
  }

  Future<void> _replace(kc.PlanSlot slot, {required bool cannotDo}) async {
    final set = await _run(() => c!.variants(slot.slotId));
    if (set == null || !mounted) return;
    final choice = await showVariantsSheet(
      context,
      set: set,
      exerciseName: planName(slot.exerciseId),
      cannotDo: cannotDo,
    );
    if (choice == null || !mounted) return;
    final step = await _run(
      () => c!.act(
        kc.ReviewAction(
          kind: cannotDo ? kc.ReviewKind.cannotDo : kc.ReviewKind.dislike,
          slotId: slot.slotId,
        ),
        then: choice.isEmpty
            ? null
            : kc.ReviewAction(
                kind: kc.ReviewKind.replace,
                slotId: slot.slotId,
                replacementExerciseId: choice,
              ),
        label: cannotDo ? 'Je ne sais pas faire' : 'Je n’aime pas',
      ),
    );
    await _afterStep(step);
  }

  Future<void> _remove(kc.PlanSlot slot) async {
    final step = await _run(
      () => c!.act(
        kc.ReviewAction(kind: kc.ReviewKind.remove, slotId: slot.slotId),
        label: 'Retirer',
      ),
    );
    await _afterStep(step);
  }

  Future<void> _add({int? dayIndex}) async {
    final pick = await showAddExerciseSheet(
      context,
      plan: c!.plan,
      dayIndex: dayIndex,
    );
    if (pick == null || !mounted) return;
    final step = await _run(
      () => c!.act(
        kc.ReviewAction(
          kind: kc.ReviewKind.add,
          dayIndex: pick.dayIndex,
          exerciseId: pick.exerciseId,
        ),
        label: 'Ajouter',
      ),
    );
    await _afterStep(step);
  }

  // ---------------------------------------------------------------- passe 2

  Future<void> _toPass2() async {
    final p = await _run(() => c!.createPass2());
    if (p != null && mounted) {
      setState(() {
        _stage = _Stage.pass2;
        _week = 0;
      });
    }
  }

  Future<void> _validate() async {
    final nav = Navigator.of(context);
    final colors = KoachToastColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_isNext) {
      PlanStore(store).applyNextBlockCreation(c!);
      messenger.showSnackBar(
        koachSnackBar(
          colors,
          'Ton bloc suivant est prêt : il commence le '
          '${planDayName(c!.startDate)} ${_date(c!.startDate)}.',
          pose: KoachPose.victory,
        ),
      );
      nav.pop(true);
      return;
    }
    final start = PlanStore(store).planStartFor();
    if (start.replacing) {
      final when = start.firstWeek > 1
          ? 'à partir du ${planDayName(start.start)} ${_date(start.start)} '
                '(semaine ${start.firstWeek}) ; tes semaines passées restent '
                'telles quelles'
          : 'dès aujourd’hui';
      // UI4 (§4.5, R8) : confirmation au gabarit, verbe exact.
      final ok = await showKConfirm(
        context,
        title: 'Remplacer ton programme ?',
        message:
            'Ton nouveau programme remplace l’actuel $when. Ton '
            'historique ne change pas. Tu pourras revenir à l’ancien pendant '
            '7 jours, tant que tu n’as saisi aucune séance du nouveau.',
        confirmLabel: 'Remplacer',
      );
      if (!ok) return;
    }
    PlanStore(store).applyPlanCreation(c!);
    messenger.showSnackBar(
      koachSnackBar(
        colors,
        'Ton programme est prêt : retrouve-le dans l’onglet Programme.',
        pose: KoachPose.victory,
      ),
    );
    nav.pop(true);
  }

  // ------------------------------------------------------------------ rendu

  /// Titre de l'étape (UI4, R3 : la page ouverte par « Créer mon
  /// programme » porte ce titre ; l'étape est dite dessous).
  String get _stageLabel => switch (_stage) {
    _Stage.pass1 => 'Étape 1 sur 4 · Exercices',
    _Stage.review => 'Étape 2 sur 4 · Revue des exercices',
    _Stage.recap => 'Étape 3 sur 4 · Récapitulatif',
    _Stage.pass2 => 'Étape 4 sur 4 · Séries et charges',
  };

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final creation = c;
    if (creation == null) {
      final noProfile = store.athlete == null;
      return KPage.sub(
        title: 'Créer mon programme',
        children: [
          KoachSurface(
            color: k.fond,
            child: KoachBubble(
              key: const ValueKey('plan-no-profile'),
              pose: KoachPose.oops,
              koachHeight: 110,
              text: noProfile
                  ? 'Il me faut d’abord ton profil pour créer ton programme : '
                        'disciplines, niveau, objectifs, disponibilités, '
                        'matériel.'
                  : 'Je n’arrive pas à préparer ton programme pour '
                        'l’instant.',
            ),
          ),
          if (noProfile)
            KPrimaryButton(
              key: const ValueKey('plan-no-profile-create'),
              label: store.profile == null
                  ? 'Créer mon profil'
                  : 'Refaire mon profil',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _createProfile,
            ),
        ],
      );
    }
    return ListenableBuilder(
      listenable: creation,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: k.fond,
          appBar: KTopBar.sub(
            title: _isNext ? 'Bloc suivant' : 'Créer mon programme',
            subtitle: _stageLabel,
            onBack: _back,
            action: _dev && creation.started
                ? KIconButton(
                    key: const ValueKey('plan-inspector'),
                    tooltip: 'Inspecteur du moteur',
                    icon: Icons.manage_search,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlanInspectorScreen(creation: creation),
                      ),
                    ),
                  )
                : null,
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (creation.started) _body(context, creation),
                    if (_busy || !creation.started)
                      Positioned.fill(
                        child: ColoredBox(
                          color: k.fond.withValues(alpha: .85),
                          child: Center(
                            child: KoachSurface(
                              color: k.fond,
                              child: const Padding(
                                padding: EdgeInsets.all(KSpacing.s24),
                                child: KoachBubble(
                                  key: ValueKey('plan-busy'),
                                  pose: KoachPose.think,
                                  koachHeight: 110,
                                  text: 'Je réfléchis à ton programme…',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Liste d'une étape : marges de page, écart entre cartes, réserve basse
  /// du téléphone.
  Widget _list(String key, List<Widget> children) => ListView.separated(
    key: ValueKey(key),
    padding: EdgeInsets.fromLTRB(
      KSpacing.page,
      KSpacing.s8,
      KSpacing.page,
      KSpacing.s24 + MediaQuery.paddingOf(context).bottom,
    ),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    itemCount: children.length,
    separatorBuilder: (_, __) => const SizedBox(height: KSpacing.cardGap),
    itemBuilder: (_, i) => children[i],
  );

  Widget _body(BuildContext context, PlanCreation creation) => switch (_stage) {
    _Stage.pass1 => _pass1(context, creation),
    _Stage.review => _review(context, creation),
    _Stage.recap => _recap(context, creation),
    _Stage.pass2 => _pass2(context, creation),
  };

  Widget _errorBubble() => KoachBubble(
    key: const ValueKey('plan-error'),
    pose: KoachPose.oops,
    koachHeight: 72,
    text: _error!,
  );

  // ----------------------------------------------------------- passe 1

  Widget _dayCard(BuildContext context, kc.PlanDay d, {bool compact = false}) {
    final k = KTokens.of(context);
    final dim = KType.detail.copyWith(color: k.texte2);
    return KCard(
      key: ValueKey('plan-day-${d.dayIndex}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekdayLabel(d.weekday)} · ${d.minutesBudget} min',
            style: KType.titreCarte.copyWith(color: k.texte),
          ),
          Text(
            focusLabel(d.focus),
            style: KType.detail.copyWith(color: k.texte2),
          ),
          const SizedBox(height: KSpacing.s8),
          for (final s in d.slots)
            Padding(
              padding: const EdgeInsets.only(bottom: KSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('›  ', style: dim),
                  Expanded(
                    child: Text(
                      planName(s.exerciseId),
                      style: KType.corps.copyWith(color: k.texte),
                    ),
                  ),
                  if (!compact) Text(kRoleLabels[s.role] ?? '', style: dim),
                  if (s.locked)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: KSpacing.s4,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: KSize.chevron,
                        color: k.texte2,
                        semanticLabel: 'validé',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _weekOverview(BuildContext context, PlanCreation creation) {
    final k = KTokens.of(context);
    final plan = creation.plan;
    final m = _metricsOf(plan);
    final intensities = planMuscleIntensities([
      for (final d in plan.days)
        for (final s in d.slots) (s.exerciseId, 1),
    ]);
    final share = m?.classShare ?? const <String, double>{};
    final shares = m == null
        ? const <MapEntry<String, double>>[]
        : (m.classTarget.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)));
    return KCard(
      key: const ValueKey('plan-week-overview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ta semaine', style: KType.titreCarte.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s8),
          Center(
            child: MuscleMap2D(
              key: const ValueKey('plan-week-muscles'),
              intensities: intensities,
              views: const [MapView.face, MapView.dos],
              height: 200,
              semanticLabel: 'Carte des muscles de la semaine',
            ),
          ),
          const SizedBox(height: KSpacing.s8),
          Text(
            mapWorkedSummary(intensities),
            style: KType.detail.copyWith(color: k.texte2),
          ),
          if (shares.isNotEmpty) ...[
            const SizedBox(height: KSpacing.s12),
            Text(
              'Répartition par discipline',
              style: KType.section.copyWith(color: k.texte2),
            ),
            const SizedBox(height: KSpacing.s8),
            for (final e in shares)
              if (e.value > 0 || (share[e.key] ?? 0) > 0)
                Padding(
                  key: ValueKey('plan-share-${e.key}'),
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${disciplineClassLabel(e.key)} : '
                        '${((share[e.key] ?? 0) * 100).round()} % du '
                        'temps (visé ${(e.value * 100).round()} %)',
                        style: KType.corps.copyWith(color: k.texte),
                      ),
                      const SizedBox(height: KSpacing.s4),
                      ExcludeSemantics(
                        child: KProgressBar(
                          value: (share[e.key] ?? 0).clamp(0.0, 1.0),
                          height: KSpacing.s8,
                          color: k.second,
                          track: k.filet,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }

  /// G10 : présentation du bloc suivant par Koach (résumé d'adaptation et
  /// ce qui change).
  List<Widget> _nextIntro(BuildContext context, PlanCreation creation) {
    final k = KTokens.of(context);
    final plan = creation.plan;
    final a = creation.adaptation;
    final changes = creation.blockDiff?.changes ?? const <kc.PlanChange>[];
    final fresh = _slots.length;
    final before = creation.previous!.pass1;
    final done = a == null
        ? ''
        : ' Tu as fait ${a.sessionsCompleted} séance'
              '${a.sessionsCompleted > 1 ? 's' : ''} sur '
              '${a.sessionsPlanned} prévue${a.sessionsPlanned > 1 ? 's' : ''}.';
    return [
      KoachBubble(
        key: const ValueKey('next-block-koach'),
        pose: KoachPose.progressChart,
        koachHeight: 110,
        text:
            'Ton bloc se termine. Voici le suivant : ${plan.weeks} semaines, '
            '${plan.days.length} séance${plan.days.length > 1 ? 's' : ''} par '
            'semaine.$done '
            '${fresh == 0
                ? 'Aucun nouvel exercice à passer en revue.'
                : fresh == 1
                ? 'Un nouvel exercice à passer en revue.'
                : '$fresh nouveaux exercices à passer en revue.'}',
        why:
            'Je garde tes mouvements principaux, je fais tourner une partie '
            'des exercices de complément et je passe à une variante plus '
            'difficile quand tes séances montrent que tu es prêt. Les '
            'exercices que tu connais déjà restent validés.',
      ),
      if (changes.isNotEmpty)
        KCard(
          key: const ValueKey('next-block-changes'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ce qui change (${changes.length})',
                style: KType.titreCarte.copyWith(color: k.texte),
              ),
              for (final c in changes)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    changeLine(c, before, plan),
                    style: KType.corps.copyWith(color: k.texte),
                  ),
                  subtitle: Text(
                    'Pourquoi ?',
                    style: KType.detail.copyWith(color: k.encre),
                  ),
                  children: [
                    for (final r in c.reasons)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: KSpacing.s8),
                          child: Text(
                            planReason(r),
                            style: KType.corps.copyWith(color: k.texte2),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
    ];
  }

  Widget _pass1(BuildContext context, PlanCreation creation) {
    final plan = creation.plan;
    final n = creation.proposals.length;
    if (_isNext) {
      final fresh = _slots.length;
      return _list('plan-pass1', [
        ..._nextIntro(context, creation),
        if (_error != null) _errorBubble(),
        for (final d in plan.days) _dayCard(context, d),
        _weekOverview(context, creation),
        KPrimaryButton(
          key: const ValueKey('plan-review'),
          icon: Icons.fact_check_outlined,
          label: fresh == 0
              ? 'Voir le récapitulatif'
              : 'Passer les nouveaux exercices en revue ($fresh)',
          onPressed: () => setState(
            () => _stage = fresh == 0 ? _Stage.recap : _Stage.review,
          ),
        ),
      ]);
    }
    return _list('plan-pass1', [
      KoachBubble(
        key: const ValueKey('plan-pass1-koach'),
        pose: KoachPose.checklist,
        koachHeight: 110,
        text:
            'Voici ton bloc de ${plan.weeks} semaines : '
            '${plan.days.length} séance${plan.days.length > 1 ? 's' : ''} '
            'par semaine. Pour l’instant, juste les exercices : on règle les '
            'séries ensuite.',
        why:
            'Je choisis chaque exercice selon tes disciplines, ton niveau, '
            'ton matériel et ton temps, en laissant au moins 48 h entre '
            'deux séances lourdes des mêmes muscles. « Autre proposition » '
            'te montre un autre programme presque aussi bien noté.',
      ),
      if (plan.reasons.any((r) => r.code == 'plan.cautious_health'))
        const KNotice(
          icon: Icons.health_and_safety_outlined,
          message:
              'Programme prudent, d’après ton questionnaire santé : pas '
              'd’impact, pas de course, une marche plus bas.',
        ),
      if (_error != null) _errorBubble(),
      for (final d in plan.days) _dayCard(context, d),
      _weekOverview(context, creation),
      if (!creation.reviewed) ...[
        KTonalButton(
          key: const ValueKey('plan-other'),
          icon: Icons.autorenew,
          expand: true,
          label: creation.index + 1 < n
              ? 'Proposition suivante (${creation.index + 2}/$n)'
              : 'Autre proposition',
          onPressed: () => _run(creation.otherProposal),
        ),
        if (creation.index > 0)
          KTonalButton(
            key: const ValueKey('plan-previous'),
            icon: Icons.undo,
            expand: true,
            label: 'Proposition précédente (${creation.index}/$n)',
            onPressed: creation.previousProposal,
          ),
      ],
      KPrimaryButton(
        key: const ValueKey('plan-review'),
        icon: Icons.fact_check_outlined,
        label: creation.reviewed
            ? 'Reprendre la revue'
            : 'Passer les exercices en revue',
        onPressed: () => setState(() => _stage = _Stage.review),
      ),
    ]);
  }

  // ------------------------------------------------------------- revue

  Widget _review(BuildContext context, PlanCreation creation) {
    final k = KTokens.of(context);
    final slots = _slots;
    if (_page >= slots.length) _page = slots.isEmpty ? 0 : slots.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: KSpacing.page,
            right: KSpacing.page,
            top: KSpacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Exercice ${_page + 1} / ${slots.length} · '
                  '${creation.decided.length} vu${creation.decided.length > 1 ? 's' : ''}',
                  key: const ValueKey('plan-review-progress'),
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              KTonalButton(
                key: const ValueKey('plan-review-recap'),
                label: 'Récapitulatif',
                onPressed: () => setState(() => _stage = _Stage.recap),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.page),
            child: _errorBubble(),
          ),
        Expanded(
          child: PageView.builder(
            key: const ValueKey('plan-review-pages'),
            controller: _pages,
            itemCount: slots.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) =>
                _reviewCard(context, creation, slots[i].day, slots[i].slot),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpacing.page,
              KSpacing.s8,
              KSpacing.page,
              KSpacing.s16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: KTonalButton(
                    key: const ValueKey('plan-add'),
                    icon: Icons.add,
                    label: 'Ajouter',
                    expand: true,
                    onPressed: () => _add(
                      dayIndex: slots.isEmpty
                          ? null
                          : slots[_page].day.dayIndex,
                    ),
                  ),
                ),
                const SizedBox(width: KSpacing.s8),
                Expanded(
                  child: KTonalButton(
                    key: const ValueKey('plan-undo'),
                    icon: Icons.undo,
                    label: 'Annuler',
                    expand: true,
                    onPressed: creation.steps.isEmpty
                        ? null
                        : () {
                            creation.undo();
                            showKoachToast(
                              context,
                              'Dernier changement annulé.',
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(
    BuildContext context,
    PlanCreation creation,
    kc.PlanDay day,
    kc.PlanSlot slot,
  ) {
    final k = KTokens.of(context);
    final d = store.content.detail(slot.exerciseId);
    final points = d?.pointsCles.take(3).toList() ?? const <String>[];
    final why = mainReason(slot.reasons);
    return ListView(
      key: ValueKey('plan-card-${slot.slotId}'),
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s16,
      ),
      children: [
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${weekdayLabel(day.weekday)} · ${focusLabel(day.focus)} · '
                '${kRoleLabels[slot.role] ?? ''}',
                style: KType.detail.copyWith(color: k.texte2),
              ),
              const SizedBox(height: KSpacing.s4),
              Text(
                planName(slot.exerciseId),
                key: const ValueKey('plan-card-name'),
                style: KType.titreSeance.copyWith(color: k.texte),
              ),
              if (why != null) ...[
                const SizedBox(height: KSpacing.s4),
                Text(
                  planReason(why),
                  style: KType.corps.copyWith(color: k.texte2),
                ),
              ],
              const SizedBox(height: KSpacing.s12),
              if (d != null)
                Center(
                  child: MuscleMap2D(
                    intensities: mapIntensitiesFromRoles(
                      primaires: d.primaires,
                      secondaires: d.secondaires,
                    ),
                    views: const [MapView.face, MapView.dos],
                    height: 150,
                    viewLabels: false,
                    semanticLabel: 'Muscles de ${planName(slot.exerciseId)}',
                  ),
                ),
              for (final p in points)
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s4),
                  child: Text(
                    '• $p',
                    style: KType.corps.copyWith(color: k.texte),
                  ),
                ),
              const SizedBox(height: KSpacing.s8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KTonalButton(
                  key: const ValueKey('plan-card-sheet'),
                  icon: Icons.menu_book_outlined,
                  label: 'Fiche et démonstration',
                  onPressed: () => openExerciseSheet(context, slot.exerciseId),
                ),
              ),
              if (slot.locked) ...[
                const SizedBox(height: KSpacing.s8),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: KChip('Validé', icon: Icons.lock_outline),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KSpacing.s12),
        KPrimaryButton(
          key: const ValueKey('plan-can-do'),
          icon: Icons.check,
          label: 'Je sais faire',
          onPressed: () async {
            final step = await _run(() {
              creation.canDo(slot.slotId);
              return creation.steps.last;
            });
            await _afterStep(step);
          },
        ),
        const SizedBox(height: KSpacing.s8),
        KTonalButton(
          key: const ValueKey('plan-cannot-do'),
          icon: Icons.help_outline,
          label: 'Je ne sais pas faire',
          expand: true,
          onPressed: () => _replace(slot, cannotDo: true),
        ),
        const SizedBox(height: KSpacing.s8),
        KTonalButton(
          key: const ValueKey('plan-dislike'),
          icon: Icons.thumb_down_outlined,
          label: 'Je n’aime pas',
          expand: true,
          onPressed: () => _replace(slot, cannotDo: false),
        ),
        const SizedBox(height: KSpacing.s8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: KSpacing.s8,
          runSpacing: KSpacing.s8,
          children: [
            KTonalButton(
              key: const ValueKey('plan-remove'),
              icon: Icons.remove_circle_outline,
              label: 'Retirer',
              onPressed: () => _remove(slot),
            ),
            KTonalButton(
              key: const ValueKey('plan-next'),
              icon: Icons.arrow_forward,
              label: 'Suivant',
              onPressed: () {
                creation.keep(slot.slotId);
                _next();
              },
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------ récap

  Widget _recap(BuildContext context, PlanCreation creation) {
    final plan = creation.plan;
    final total = plan.days.fold<int>(0, (a, d) => a + d.slots.length);
    final changes = creation.steps.where((s) => s.changes.isNotEmpty).length;
    return _list('plan-recap', [
      KoachBubble(
        key: const ValueKey('plan-recap-koach'),
        pose: KoachPose.thumbsUp,
        koachHeight: 110,
        text:
            'Récapitulatif : $total exercices sur ${plan.days.length} '
            'séances${changes == 0 ? '' : ', $changes changement${changes > 1 ? 's' : ''} de ta part'}. '
            'Si tout te va, je règle les séries et les charges.',
      ),
      if (_error != null) _errorBubble(),
      for (final d in plan.days) _dayCard(context, d, compact: true),
      KPrimaryButton(
        key: const ValueKey('plan-validate-exercises'),
        icon: Icons.check,
        label: 'Valider les exercices',
        onPressed: _toPass2,
      ),
      KTonalButton(
        key: const ValueKey('plan-back-review'),
        label: 'Revenir à la revue',
        expand: true,
        onPressed: () => setState(() => _stage = _Stage.review),
      ),
    ]);
  }

  // ----------------------------------------------------------- passe 2

  String _blockLogic(kc.Pass2Plan p) {
    final kinds = [
      for (final w in p.weeks) kWeekKindLabels[w.kind]!.toLowerCase(),
    ];
    final parts = <String>[];
    for (var i = 0; i < kinds.length; i++) {
      parts.add('S${i + 1} ${kinds[i]}');
    }
    return 'Ton bloc : ${parts.join(', ')}. La difficulté visée est en '
        'flammes : 10 = échec, plus il y en a, plus c’est dur. Les 2-3 '
        'premières séances, je cale tes charges avec tes flammes.';
  }

  Widget _pass2(BuildContext context, PlanCreation creation) {
    final k = KTokens.of(context);
    final p2 = creation.pass2!;
    final plan = creation.plan;
    final entry = PlanBlockEntry(
      block: kc.ProgramBlock(pass1: plan, pass2: p2),
      seed: creation.seed,
      locks: creation.locks,
      adjust: creation.adjust,
      validatedAt: '',
    );
    final week = p2.weeks[_week.clamp(0, p2.weeks.length - 1)];
    final days = adjustedDays(entry, week.weekIndex);
    final cautious = plan.reasons.any((r) => r.code == 'plan.cautious_health');
    final dim = KType.detail.copyWith(color: k.texte2);
    final calibrate = days.any((d) => d.items.any((i) => i.toCalibrate));
    return _list('plan-pass2', [
      KoachBubble(
        key: const ValueKey('plan-pass2-koach'),
        pose: KoachPose.explainBoard,
        koachHeight: 120,
        text: _blockLogic(p2),
        why:
            'Première semaine plus légère pour apprendre les gestes, '
            'puis les séries montent doucement. Les charges de départ sont '
            'prudentes ; tu peux régler séries, répétitions et repos en '
            'touchant un exercice, dans les limites que je garde pour toi.',
      ),
      Wrap(
        spacing: KSpacing.s8,
        runSpacing: KSpacing.s8,
        children: [
          for (final w in p2.weeks)
            KChip(
              'Semaine ${w.weekIndex + 1} · ${kWeekKindLabels[w.kind]}',
              key: ValueKey('plan-week-${w.weekIndex}'),
              selected: w.weekIndex == week.weekIndex,
              onTap: () => setState(() => _week = w.weekIndex),
            ),
        ],
      ),
      Text(kWeekKindHints[week.kind]!, style: dim),
      if (calibrate)
        KoachSays(
          pose: KoachPose.analyze,
          child: Text(
            '« À calibrer » : je n’invente pas de charge. Les 2-3 premières '
            'séances, je cale tes charges avec tes flammes.',
            style: KType.corps.copyWith(color: k.texte),
          ),
        ),
      for (final d in days)
        if (d.items.isNotEmpty)
          KCard(
            key: ValueKey('plan-p2-day-${d.dayIndex}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  planDayLabel(plan, d.dayIndex),
                  style: KType.titreCarte.copyWith(color: k.texte),
                ),
                Divider(color: k.filet),
                for (final it in d.items)
                  InkWell(
                    key: ValueKey('plan-p2-${it.slotId}'),
                    customBorder: KRadius.menuShape,
                    onTap: () => showAdjustSheet(
                      context,
                      creation: creation,
                      item: p2.weeks
                          .expand((w) => w.days)
                          .expand((x) => x.items)
                          .firstWhere(
                            (x) =>
                                x.slotId == it.slotId &&
                                x.kind != kc.SetKind.test &&
                                x.kind != kc.SetKind.calibration,
                            orElse: () => it,
                          ),
                      cautious: cautious,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: KSize.target,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: KSpacing.s8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    planName(it.exerciseId),
                                    style: KType.corpsFort.copyWith(
                                      color: k.texte,
                                    ),
                                  ),
                                ),
                                if (creation.adjust[it.slotId]?.isEmpty ==
                                    false) ...[
                                  const KChip('Ajusté', icon: Icons.tune),
                                  const SizedBox(width: KSpacing.s8),
                                ],
                                Icon(
                                  Icons.tune,
                                  size: KSize.chevron,
                                  color: k.texte2,
                                ),
                              ],
                            ),
                            const SizedBox(height: KSpacing.s4),
                            Wrap(
                              spacing: KSpacing.s12,
                              runSpacing: KSpacing.s4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  prescriptionLabel(it),
                                  style: KType.corps.copyWith(color: k.texte),
                                ),
                                if (it.targetFlames != null)
                                  TargetFlames(it.targetFlames!),
                                Text(
                                  'repos ${restLabel(it.restSeconds)}',
                                  style: dim,
                                ),
                                if (loadLabel(it) != null)
                                  Text(loadLabel(it)!, style: dim),
                                if (it.toCalibrate)
                                  const KChip('À calibrer', icon: Icons.tune),
                                if (it.kind == kc.SetKind.test)
                                  const KChip(
                                    'Test',
                                    icon: Icons.flag_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      if (_error != null) _errorBubble(),
      KPrimaryButton(
        key: const ValueKey('plan-validate'),
        icon: Icons.check_circle_outline,
        label: 'Valider mon programme',
        onPressed: _validate,
      ),
      // UI4 (inventaire, partie 2) : le bouton mène au récapitulatif ; son
      // libellé le dit.
      KTonalButton(
        key: const ValueKey('plan-back-recap'),
        label: 'Revenir au récapitulatif',
        expand: true,
        onPressed: () => setState(() => _stage = _Stage.recap),
      ),
    ]);
  }
}

String _date(kc.CivilDate d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
