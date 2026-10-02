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

import '../app_theme.dart';
import '../dev/dev_flags.dart';
import '../exercise_screens.dart' show openExerciseSheet;
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart' show KoachSurface;
import '../muscle_map_2d.dart';
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
  final c = PlanStore(store).newNextBlockCreation();
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => c == null
          ? const NextBlockUnavailable()
          : PlanCreationScreen(creation: c),
    ),
  );
  return ok == true;
}

/// Bloc suivant impossible à préparer (profil ou base absents, erreur du
/// moteur).
class NextBlockUnavailable extends StatelessWidget {
  const NextBlockUnavailable({super.key});

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('BLOC SUIVANT')),
    body: KList(
      children: [
        KoachSurface(
          color: SL.bg,
          child: const KoachBubble(
            key: ValueKey('next-block-unavailable'),
            pose: KoachPose.oops,
            koachHeight: 100,
            text: 'Je n’arrive pas à préparer le bloc suivant pour l’instant.',
          ),
        ),
      ],
    ),
  );
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
  late final PlanCreation? c =
      widget.creation ?? PlanStore(store).newPlanCreation();
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

  Future<void> _confirmLeave() async {
    final nav = Navigator.of(context);
    final leave = await showKoachSheet<bool>(
      context,
      pose: KoachPose.please,
      text: _isNext
          ? 'Tu quittes ? Ton bloc suivant n’est pas encore validé : rien '
                'n’est enregistré, je te le reproposerai.'
          : 'Tu quittes la création ? Ton programme n’est pas encore créé : '
                'rien n’est enregistré.',
      actions: [
        KoachBubbleAction(
          'Continuer la création',
          () => Navigator.of(context).pop(false),
          primary: true,
          key: const ValueKey('plan-leave-stay'),
        ),
        KoachBubbleAction(
          'Quitter',
          () => Navigator.of(context).pop(true),
          key: const ValueKey('plan-leave-go'),
        ),
      ],
    );
    if (leave == true) nav.pop(false);
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
      final ok = await showKoachSheet<bool>(
        context,
        pose: KoachPose.choice,
        title: 'Remplacer ton programme ?',
        text:
            'Ton nouveau programme remplace l’actuel $when. Ton '
            'historique ne change pas. Tu pourras revenir à l’ancien pendant '
            '7 jours, tant que tu n’as saisi aucune séance du nouveau.',
        actions: [
          KoachBubbleAction(
            'Remplacer mon programme',
            () => Navigator.of(context).pop(true),
            primary: true,
            key: const ValueKey('plan-replace-confirm'),
          ),
          KoachBubbleAction(
            'Garder mon programme actuel',
            () => Navigator.of(context).pop(false),
            key: const ValueKey('plan-replace-cancel'),
          ),
        ],
      );
      if (ok != true) return;
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

  @override
  Widget build(BuildContext context) {
    final creation = c;
    if (creation == null) {
      return KScreen(
        appBar: AppBar(title: const Text('TON PROGRAMME')),
        body: KList(
          children: [
            KoachSurface(
              color: SL.bg,
              child: const KoachBubble(
                pose: KoachPose.oops,
                koachHeight: 110,
                text:
                    'Il me faut d’abord ton profil (Réglages › Profil) pour '
                    'créer ton programme.',
              ),
            ),
          ],
        ),
      );
    }
    return ListenableBuilder(
      listenable: creation,
      builder: (context, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: KScreen(
          appBar: AppBar(
            leading: BackButton(onPressed: _back),
            title: Text(switch (_stage) {
              _Stage.pass1 => _isNext ? 'BLOC SUIVANT' : 'TES EXERCICES',
              _Stage.review => 'REVUE',
              _Stage.recap => 'RÉCAPITULATIF',
              _Stage.pass2 => 'SÉRIES ET CHARGES',
            }),
            actions: [
              if (_dev && creation.started)
                IconButton(
                  key: const ValueKey('plan-inspector'),
                  tooltip: 'Inspecteur du moteur',
                  icon: const Icon(Icons.manage_search),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlanInspectorScreen(creation: creation),
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              if (creation.started) _body(context, creation),
              if (_busy || !creation.started)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: .85),
                    child: Center(
                      child: KoachSurface(
                        color: SL.bg,
                        child: const Padding(
                          padding: EdgeInsets.all(24),
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
    );
  }

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
    final dim = Theme.of(context).textTheme.bodySmall;
    return KCard(
      key: ValueKey('plan-day-${d.dayIndex}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${weekdayLabel(d.weekday)} · ${d.minutesBudget} min',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(focusLabel(d.focus), style: TextStyle(color: SL.accent)),
          const SizedBox(height: 8),
          for (final s in d.slots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('›  ', style: dim),
                  Expanded(child: Text(planName(s.exerciseId))),
                  if (!compact) Text(kRoleLabels[s.role] ?? '', style: dim),
                  if (s.locked)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: SL.dim,
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
          Text('Ta semaine', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Center(
            child: MuscleMap2D(
              key: const ValueKey('plan-week-muscles'),
              intensities: intensities,
              views: const [MapView.face, MapView.dos],
              height: 200,
              semanticLabel: 'Carte des muscles de la semaine',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mapWorkedSummary(intensities),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (shares.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Répartition par discipline',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (final e in shares)
              if (e.value > 0 || (share[e.key] ?? 0) > 0)
                Padding(
                  key: ValueKey('plan-share-${e.key}'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${disciplineClassLabel(e.key)} : '
                        '${((share[e.key] ?? 0) * 100).round()} % du '
                        'temps (visé ${(e.value * 100).round()} %)',
                      ),
                      const SizedBox(height: 4),
                      ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: (share[e.key] ?? 0).clamp(0.0, 1.0),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: SL.accent,
                          backgroundColor: SL.progressTrack,
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
            '${fresh == 0 ? 'Aucun nouvel exercice à passer en revue.' : '$fresh nouvel${fresh > 1 ? 's' : ''} exercice${fresh > 1 ? 's' : ''} à passer en revue.'}',
        why:
            'Je garde tes mouvements principaux, je fais tourner une partie '
            'des exercices de complément et je fais progresser ce que tu '
            'maîtrises, d’après ce que tes séances ont montré. Les exercices '
            'que tu connais déjà restent validés.',
      ),
      if (changes.isNotEmpty)
        KCard(
          key: const ValueKey('next-block-changes'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ce qui change (${changes.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final c in changes)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(changeLine(c, before, plan)),
                  subtitle: Text(
                    'Pourquoi ?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  children: [
                    for (final r in c.reasons)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(planReason(r)),
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
      return KList(
        key: const ValueKey('plan-pass1'),
        children: [
          ..._nextIntro(context, creation),
          if (_error != null) _errorBubble(),
          for (final d in plan.days) _dayCard(context, d),
          _weekOverview(context, creation),
          FilledButton.icon(
            key: const ValueKey('plan-review'),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(
              fresh == 0
                  ? 'Voir le récapitulatif'
                  : 'Passer les nouveaux exercices en revue ($fresh)',
            ),
            onPressed: () => setState(
              () => _stage = fresh == 0 ? _Stage.recap : _Stage.review,
            ),
          ),
        ],
      );
    }
    return KList(
      key: const ValueKey('plan-pass1'),
      children: [
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
          KBanner(
            child: Text(
              'Programme prudent, d’après ton questionnaire santé : pas '
              'd’impact, pas de course, une marche plus bas.',
              style: TextStyle(color: SL.onBrand),
            ),
          ),
        if (_error != null) _errorBubble(),
        for (final d in plan.days) _dayCard(context, d),
        _weekOverview(context, creation),
        if (!creation.reviewed) ...[
          OutlinedButton.icon(
            key: const ValueKey('plan-other'),
            icon: const Icon(Icons.autorenew),
            label: Text(
              creation.index + 1 < n
                  ? 'Proposition suivante (${creation.index + 2}/$n)'
                  : 'Autre proposition',
            ),
            onPressed: () => _run(creation.otherProposal),
          ),
          if (creation.index > 0)
            TextButton.icon(
              key: const ValueKey('plan-previous'),
              icon: const Icon(Icons.undo),
              label: Text('Proposition précédente (${creation.index}/$n)'),
              onPressed: creation.previousProposal,
            ),
        ],
        FilledButton.icon(
          key: const ValueKey('plan-review'),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(
            creation.reviewed
                ? 'Reprendre la revue'
                : 'Passer les exercices en revue',
          ),
          onPressed: () => setState(() => _stage = _Stage.review),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- revue

  Widget _review(BuildContext context, PlanCreation creation) {
    final slots = _slots;
    if (_page >= slots.length) _page = slots.isEmpty ? 0 : slots.length - 1;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Exercice ${_page + 1} / ${slots.length} · '
                  '${creation.decided.length} vu${creation.decided.length > 1 ? 's' : ''}',
                  key: const ValueKey('plan-review-progress'),
                  style: TextStyle(color: SL.dim),
                ),
              ),
              TextButton(
                key: const ValueKey('plan-review-recap'),
                onPressed: () => setState(() => _stage = _Stage.recap),
                child: const Text('Récapitulatif'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        KBottomActions(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('plan-add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  onPressed: () => _add(
                    dayIndex: slots.isEmpty ? null : slots[_page].day.dayIndex,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('plan-undo'),
                  icon: const Icon(Icons.undo),
                  label: const Text('Annuler'),
                  onPressed: creation.steps.isEmpty
                      ? null
                      : () {
                          creation.undo();
                          showKoachToast(context, 'Dernier changement annulé.');
                        },
                ),
              ),
            ],
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
    final d = store.content.detail(slot.exerciseId);
    final points = d?.pointsCles.take(3).toList() ?? const <String>[];
    final why = mainReason(slot.reasons);
    return ListView(
      key: ValueKey('plan-card-${slot.slotId}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${weekdayLabel(day.weekday)} · ${focusLabel(day.focus)} · '
                '${kRoleLabels[slot.role] ?? ''}',
                style: TextStyle(color: SL.accent),
              ),
              const SizedBox(height: 4),
              Text(
                planName(slot.exerciseId),
                key: const ValueKey('plan-card-name'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (why != null) ...[
                const SizedBox(height: 4),
                Text(planReason(why), style: TextStyle(color: SL.dim)),
              ],
              const SizedBox(height: 10),
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
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $p'),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('plan-card-sheet'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Fiche et démonstration'),
                  onPressed: () => openExerciseSheet(context, slot.exerciseId),
                ),
              ),
              if (slot.locked)
                KBadge('Validé', icon: Icons.lock_outline, color: SL.success),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const ValueKey('plan-can-do'),
          icon: const Icon(Icons.check),
          label: const Text('Je sais faire'),
          onPressed: () async {
            final step = await _run(() {
              creation.canDo(slot.slotId);
              return creation.steps.last;
            });
            await _afterStep(step);
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('plan-cannot-do'),
          icon: const Icon(Icons.help_outline),
          label: const Text('Je ne sais pas faire'),
          onPressed: () => _replace(slot, cannotDo: true),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('plan-dislike'),
          icon: const Icon(Icons.thumb_down_outlined),
          label: const Text('Je n’aime pas'),
          onPressed: () => _replace(slot, cannotDo: false),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton.icon(
              key: const ValueKey('plan-remove'),
              icon: const Icon(Icons.remove_circle_outline),
              label: const Text('Retirer'),
              onPressed: () => _remove(slot),
            ),
            const Spacer(),
            TextButton(
              key: const ValueKey('plan-next'),
              onPressed: () {
                creation.keep(slot.slotId);
                _next();
              },
              child: const Text('Suivant'),
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
    return KList(
      key: const ValueKey('plan-recap'),
      children: [
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
        FilledButton.icon(
          key: const ValueKey('plan-validate-exercises'),
          icon: const Icon(Icons.check),
          label: const Text('Valider les exercices'),
          onPressed: _toPass2,
        ),
        TextButton(
          key: const ValueKey('plan-back-review'),
          onPressed: () => setState(() => _stage = _Stage.review),
          child: const Text('Revenir à la revue'),
        ),
      ],
    );
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
    final dim = Theme.of(context).textTheme.bodySmall;
    final calibrate = days.any((d) => d.items.any((i) => i.toCalibrate));
    return KList(
      key: const ValueKey('plan-pass2'),
      children: [
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
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in p2.weeks)
              ChoiceChip(
                key: ValueKey('plan-week-${w.weekIndex}'),
                label: Text('S${w.weekIndex + 1} · ${kWeekKindLabels[w.kind]}'),
                selected: w.weekIndex == week.weekIndex,
                onSelected: (_) => setState(() => _week = w.weekIndex),
              ),
          ],
        ),
        Text(kWeekKindHints[week.kind]!, style: dim),
        if (calibrate)
          const KoachSays(
            pose: KoachPose.analyze,
            child: Text(
              '« À calibrer » : je n’invente pas de charge. Les 2-3 premières '
              'séances, je cale tes charges avec tes flammes.',
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  for (final it in d.items)
                    InkWell(
                      key: ValueKey('plan-p2-${it.slotId}'),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    planName(it.exerciseId),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (creation.adjust[it.slotId]?.isEmpty ==
                                    false)
                                  KBadge(
                                    'Ajusté',
                                    icon: Icons.tune,
                                    color: SL.accent,
                                  ),
                                const Icon(Icons.tune, size: 18),
                              ],
                            ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(prescriptionLabel(it)),
                                if (it.targetFlames != null)
                                  TargetFlames(it.targetFlames!),
                                Text(
                                  'repos ${restLabel(it.restSeconds)}',
                                  style: dim,
                                ),
                                if (loadLabel(it) != null)
                                  Text(loadLabel(it)!, style: dim),
                                if (it.toCalibrate)
                                  KBadge(
                                    'À calibrer',
                                    icon: Icons.tune,
                                    color: SL.dim,
                                  ),
                                if (it.kind == kc.SetKind.test)
                                  KBadge(
                                    'Test',
                                    icon: Icons.flag_outlined,
                                    color: SL.accent,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        if (_error != null) _errorBubble(),
        FilledButton.icon(
          key: const ValueKey('plan-validate'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Valider mon programme'),
          onPressed: _validate,
        ),
        TextButton(
          key: const ValueKey('plan-back-recap'),
          onPressed: () => setState(() => _stage = _Stage.recap),
          child: const Text('Revenir aux exercices'),
        ),
      ],
    );
  }
}

String _date(kc.CivilDate d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
