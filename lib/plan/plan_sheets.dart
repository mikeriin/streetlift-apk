// G7 (D4.5, D4.6, D4.7) : feuilles de la création du programme — variantes
// d'un exercice (3 ciblées + « Voir tout »), ajout d'un exercice aimé,
// diff expliqué par Koach (« Annuler ce changement »), ajustement d'un
// exercice en passe 2 (borné, refus expliqué).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../exercise_screens.dart' show ExerciseFilters, searchExercises;
import '../koach/flame_icon.dart';
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart' show KoachSurface;
import '../store.dart';
import '../ui.dart';
import 'plan_creation.dart';
import 'plan_program.dart';
import 'plan_texts.dart';

String planName(String id) => store.content.byId[id]?.nom ?? id;

String planReason(kc.Reason r) => reasonText(
  r,
  exerciseName: planName,
  goalLabel: PlanStore(store).planGoalLabel,
);

String planDayLabel(kc.Pass1Plan plan, int dayIndex) {
  for (final d in plan.days) {
    if (d.dayIndex == dayIndex) return weekdayName(d.weekday);
  }
  return 'Jour ${dayIndex + 1}';
}

/// Fond des feuilles (papier de Koach).
Color _sheetColor(BuildContext context) =>
    Theme.of(context).bottomSheetTheme.backgroundColor ??
    Theme.of(context).colorScheme.surfaceContainerLow;

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => KoachSurface(
        color: _sheetColor(context),
        child: builder(context),
      ),
    );

// ------------------------------------------------------------- variantes

const _variantKindLabels = <kc.VariantKind, String>{
  kc.VariantKind.easier: 'Plus facile',
  kc.VariantKind.equivalent: 'Équivalente',
  kc.VariantKind.otherEquipment: 'Autre matériel',
  kc.VariantKind.other: 'Autre',
};

/// Choix d'une variante pour [slotId] : identifiant choisi, '' pour
/// « Laisse Koach choisir », null si l'utilisateur renonce.
Future<String?> showVariantsSheet(
  BuildContext context, {
  required kc.VariantSet set,
  required String exerciseName,
  required bool cannotDo,
}) => _sheet<String>(
  context,
  (context) => _VariantsSheet(
    set: set,
    exerciseName: exerciseName,
    cannotDo: cannotDo,
  ),
);

class _VariantsSheet extends StatefulWidget {
  final kc.VariantSet set;
  final String exerciseName;
  final bool cannotDo;
  const _VariantsSheet({
    required this.set,
    required this.exerciseName,
    required this.cannotDo,
  });

  @override
  State<_VariantsSheet> createState() => _VariantsSheetState();
}

class _VariantsSheetState extends State<_VariantsSheet> {
  bool _all = false;
  int _shown = 20;

  Widget _tile(kc.Variant v, {bool targeted = false}) {
    final why = v.reasons.isEmpty ? null : planReason(v.reasons.first);
    return KCard(
      key: ValueKey('variant-${v.exerciseId}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.of(context).pop(v.exerciseId),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (targeted) ...[
                  KBadge(_variantKindLabels[v.kind]!, color: SL.accent),
                  const SizedBox(height: 6),
                ],
                Text(
                  planName(v.exerciseId),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (why != null)
                  Text(why, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.set;
    final rest = [
      for (final v in s.all)
        if (!s.targeted.any((t) => t.exerciseId == v.exerciseId)) v,
    ];
    return ListView(
      key: const ValueKey('variants-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      children: [
        KoachBubble(
          pose: widget.cannotDo ? KoachPose.choice : KoachPose.direction,
          koachHeight: 88,
          text: widget.cannotDo
              ? 'Pas de souci. Que veux-tu à la place de ${widget.exerciseName} ?'
              : 'D’accord, on le retire. Que veux-tu à la place de '
                    '${widget.exerciseName} ?',
          why:
              'Je te propose une variante plus facile, une équivalente et une '
              'avec un autre matériel. Après ton choix, je réajuste le reste '
              'de la semaine et je te montre ce qui a bougé.',
        ),
        const SizedBox(height: 12),
        if (s.targeted.isEmpty)
          Text(
            'Aucune variante ciblée ne tient dans cette séance.',
            style: TextStyle(color: SL.dim),
          ),
        for (final v in s.targeted) ...[
          _tile(v, targeted: true),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          key: const ValueKey('variants-koach'),
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Laisse Koach choisir'),
          onPressed: () => Navigator.of(context).pop(''),
        ),
        if (rest.isNotEmpty && !_all)
          TextButton(
            key: const ValueKey('variants-all'),
            onPressed: () => setState(() => _all = true),
            child: Text('Voir tout (${rest.length})'),
          ),
        if (_all) ...[
          const SizedBox(height: 8),
          KSection('Toutes les variantes (${rest.length})'),
          for (final v in rest.take(_shown)) ...[
            _tile(v),
            const SizedBox(height: 8),
          ],
          if (rest.length > _shown)
            TextButton(
              onPressed: () => setState(() => _shown += 40),
              child: Text('Afficher plus (${rest.length - _shown} restants)'),
            ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ ajout

/// Ajout d'un exercice aimé : (jour, exercice) ou null.
Future<({int dayIndex, String exerciseId})?> showAddExerciseSheet(
  BuildContext context, {
  required kc.Pass1Plan plan,
  int? dayIndex,
}) => _sheet(context, (context) => _AddSheet(plan: plan, day: dayIndex));

class _AddSheet extends StatefulWidget {
  final kc.Pass1Plan plan;
  final int? day;
  const _AddSheet({required this.plan, this.day});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late int _day = widget.day ?? widget.plan.days.first.dayIndex;
  String _q = '';
  int _shown = 20;

  @override
  Widget build(BuildContext context) {
    final present = {
      for (final d in widget.plan.days)
        if (d.dayIndex == _day)
          for (final s in d.slots) s.exerciseId,
    };
    final all = [
      for (final e in searchExercises(store.content, _q, const ExerciseFilters()))
        if (!present.contains(e.id)) e,
    ];
    return ListView(
      key: const ValueKey('add-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      children: [
        Text(
          'Ajouter un exercice que tu aimes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Quel jour ?', style: TextStyle(color: SL.dim)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in widget.plan.days)
              ChoiceChip(
                key: ValueKey('add-day-${d.dayIndex}'),
                label: Text(weekdayName(d.weekday)),
                selected: _day == d.dayIndex,
                onSelected: (_) => setState(() => _day = d.dayIndex),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('add-search'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Rechercher dans la base (1 039 exercices)',
          ),
          onChanged: (v) => setState(() {
            _q = v;
            _shown = 20;
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '${all.length} exercice${all.length > 1 ? 's' : ''}',
          style: TextStyle(color: SL.dim),
        ),
        for (final e in all.take(_shown))
          ListTile(
            key: ValueKey('add-${e.id}'),
            contentPadding: EdgeInsets.zero,
            title: Text(e.nom),
            subtitle: Text('${e.discipline} · difficulté ${e.difficulte}/10'),
            trailing: const Icon(Icons.add_circle_outline),
            onTap: () => Navigator.of(
              context,
            ).pop((dayIndex: _day, exerciseId: e.id)),
          ),
        if (all.length > _shown)
          TextButton(
            onPressed: () => setState(() => _shown += 40),
            child: Text('Afficher plus (${all.length - _shown} restants)'),
          ),
      ],
    );
  }
}

// -------------------------------------------------------------------- diff

/// Phrase d'un changement de programme.
String changeLine(kc.PlanChange c, kc.Pass1Plan before, kc.Pass1Plan after) {
  final day = c.dayIndex == null ? '' : planDayLabel(after, c.dayIndex!);
  final from = c.fromExerciseId == null ? '' : planName(c.fromExerciseId!);
  final to = c.toExerciseId == null ? '' : planName(c.toExerciseId!);
  switch (c.kind) {
    case kc.ChangeKind.exerciseReplaced:
      return '$day : $from → $to';
    case kc.ChangeKind.exerciseAdded:
      return '$day : + $to';
    case kc.ChangeKind.exerciseRemoved:
      final d = c.dayIndex == null ? '' : planDayLabel(before, c.dayIndex!);
      return '$d : − $from';
    case kc.ChangeKind.exerciseMoved:
      final src = c.fromDayIndex == null
          ? ''
          : planDayLabel(before, c.fromDayIndex!).toLowerCase();
      return '$to : $src → ${day.toLowerCase()}';
    case kc.ChangeKind.orderChanged:
      return '$day : ordre des exercices revu';
    default:
      return 'Séances revues';
  }
}

/// Ce que Koach dit d'un changement de revue : phrase principale.
String stepHeadline(PlanStep s) {
  final side = s.sideEffects;
  final what = switch (s.label) {
    'Je sais faire' => 'Noté, tu sais le faire : il ne bougera plus.',
    'Je ne sais pas faire' => 'C’est fait, je l’ai remplacé.',
    'Je n’aime pas' => 'C’est fait, il ne reviendra plus.',
    'Retirer' => 'Retiré.',
    'Ajouter' => 'Ajouté, et il ne bougera plus.',
    _ => 'C’est fait.',
  };
  if (side.isEmpty) return '$what Rien d’autre n’a bougé.';
  final why = improvedComponent(s.before.score, s.after.score);
  final moved = [
    for (final c in side)
      if (c.kind == kc.ChangeKind.exerciseMoved) c,
  ];
  if (moved.length == 1 && side.length == 1) {
    final c = moved.first;
    final reason = why == null ? '' : ' ${kScoreWhy[why]}';
    return '$what J’ai déplacé ${planName(c.toExerciseId!)} au '
        '${planDayLabel(s.after, c.dayIndex!).toLowerCase()}$reason.';
  }
  final n = side.length;
  final reason = why == null ? '' : ', ${kScoreWhy[why]}';
  return '$what J’ai aussi ajusté $n autre${n > 1 ? 's' : ''} exercice'
      '${n > 1 ? 's' : ''}$reason.';
}

/// Feuille du diff : vrai si l'utilisateur annule le changement.
Future<bool> showStepSheet(BuildContext context, PlanStep step) async {
  final r = await _sheet<bool>(
    context,
    (context) => _StepSheet(step: step),
  );
  return r == true;
}

class _StepSheet extends StatelessWidget {
  final PlanStep step;
  const _StepSheet({required this.step});

  @override
  Widget build(BuildContext context) {
    final why = improvedComponent(step.before.score, step.after.score);
    final lines = [
      for (final c in step.changes) (c, changeLine(c, step.before, step.after)),
    ];
    final dim = Theme.of(context).textTheme.bodySmall;
    return ListView(
      key: const ValueKey('step-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      children: [
        KoachBubble(
          key: const ValueKey('step-koach'),
          pose: step.sideEffects.isEmpty ? KoachPose.thumbsUp : KoachPose.explainBoard,
          koachHeight: 96,
          text: stepHeadline(step),
          why: why == null
              ? 'Ce que tu as validé reste en place ; le reste est '
                    'réajusté seulement si ça améliore ton programme.'
              : 'Ce que tu as validé reste en place. Le reste a été réajusté '
                    '${kScoreWhy[why]} (${kScoreLabels[why]?.toLowerCase()}).',
          actions: [
            KoachBubbleAction(
              'OK',
              () => Navigator.of(context).pop(false),
              primary: true,
              key: const ValueKey('step-ok'),
            ),
            KoachBubbleAction(
              'Annuler ce changement',
              () => Navigator.of(context).pop(true),
              key: const ValueKey('step-undo'),
            ),
          ],
        ),
        if (lines.isNotEmpty) ...[
          const SizedBox(height: 12),
          KSection('Ce qui a bougé (${lines.length})'),
          for (final (c, line) in lines)
            ExpansionTile(
              key: ValueKey('step-change-${c.slotId ?? line}'),
              tilePadding: EdgeInsets.zero,
              title: Text(line),
              subtitle: Text('Pourquoi ?', style: dim),
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
      ],
    );
  }
}

// ------------------------------------------------------------- ajustement

/// Ajustement d'un exercice en passe 2.
Future<void> showAdjustSheet(
  BuildContext context, {
  required PlanCreation creation,
  required kc.ExercisePrescription item,
  required bool cautious,
}) => _sheet<void>(
  context,
  (context) => _AdjustSheet(c: creation, item: item, cautious: cautious),
);

class _AdjustSheet extends StatefulWidget {
  final PlanCreation c;
  final kc.ExercisePrescription item;
  final bool cautious;
  const _AdjustSheet({
    required this.c,
    required this.item,
    required this.cautious,
  });

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  String? _refusal;

  PlanAdjust get _cur => widget.c.adjust[widget.item.slotId] ?? const PlanAdjust();

  void _try(PlanAdjust next) {
    final r = widget.c.setAdjust(widget.item.slotId, next, cautious: widget.cautious);
    setState(() => _refusal = r);
  }

  Widget _row(String label, String value, String key, VoidCallback minus, VoidCallback plus) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: SL.dim)),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          IconButton.outlined(
            key: ValueKey('adjust-$key-minus'),
            tooltip: '$label : moins',
            onPressed: minus,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            key: ValueKey('adjust-$key-plus'),
            tooltip: '$label : plus',
            onPressed: plus,
            icon: const Icon(Icons.add),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final a = _cur;
    final p = a.apply(widget.item);
    final rows = <Widget>[
      _row(
        'Séries',
        '${p.sets}',
        'sets',
        () => _try(a.copyWith(setsDelta: a.setsDelta - 1)),
        () => _try(a.copyWith(setsDelta: a.setsDelta + 1)),
      ),
      if (p.repsLow != null)
        _row(
          'Répétitions',
          p.repsLow == p.repsHigh ? '${p.repsLow}' : '${p.repsLow}-${p.repsHigh}',
          'reps',
          () => _try(a.copyWith(repsShift: a.repsShift - 1)),
          () => _try(a.copyWith(repsShift: a.repsShift + 1)),
        ),
      if (p.restSeconds != null)
        _row(
          'Repos',
          restLabel(p.restSeconds),
          'rest',
          () => _try(a.copyWith(restDelta: a.restDelta - 15)),
          () => _try(a.copyWith(restDelta: a.restDelta + 15)),
        ),
    ];
    return ListView(
      key: const ValueKey('adjust-sheet'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shrinkWrap: true,
      children: [
        Text(planName(widget.item.exerciseId), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Réglage pour tout le bloc (les semaines de test gardent leur épreuve).',
          style: TextStyle(color: SL.dim),
        ),
        const SizedBox(height: 12),
        for (final r in rows) ...[r, const SizedBox(height: 10)],
        if (_refusal != null)
          KoachBubble(
            key: const ValueKey('adjust-refused'),
            pose: KoachPose.oops,
            koachHeight: 72,
            text: _refusal!,
          ),
        if (!a.isEmpty)
          TextButton(
            key: const ValueKey('adjust-reset'),
            onPressed: () => _try(const PlanAdjust()),
            child: const Text('Revenir à ma proposition'),
          ),
        FilledButton(
          key: const ValueKey('adjust-done'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Flammes visées (icône + RIR), sans information portée par la couleur seule.
class TargetFlames extends StatelessWidget {
  final int flames;
  const TargetFlames(this.flames, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FlameIcon(flames, size: 20, semantics: false),
      const SizedBox(width: 4),
      Text(
        '$flames/10 · RIR ${flameRirText(flames)}',
        semanticsLabel: flameSemanticLabel(flames),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
