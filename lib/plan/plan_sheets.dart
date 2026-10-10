// G7 (D4.5, D4.6, D4.7) : feuilles de la création du programme — variantes
// d'un exercice (3 ciblées + « Voir tout »), ajout d'un exercice aimé,
// diff expliqué par Koach (« Annuler ce changement »), ajustement d'un
// exercice en passe 2 (borné, refus expliqué).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../exercise_screens.dart' show ExerciseFilters, searchExercises;
import '../koach/flame_icon.dart';
import '../koach/koach_bubble.dart';
import '../store.dart';
import '../ui.dart';
import 'plan_creation.dart';
import 'plan_program.dart';
import 'plan_texts.dart';
import 'widgets/program_widgets.dart';

String planName(String id) => store.content.byId[id]?.nom ?? id;

String planReason(kc.Reason r) => reasonText(
  r,
  exerciseName: planName,
  goalLabel: PlanStore(store).planGoalLabel,
);

String planDayLabel(kc.Pass1Plan plan, int dayIndex) {
  for (final d in plan.days) {
    if (d.dayIndex == dayIndex) return weekdayLabel(d.weekday);
  }
  return 'Jour ${dayIndex + 1}';
}

/// Feuille de la création (gabarit de feuille de contenu de la zone).
Future<T?> _sheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? title,
  String? subtitle,
}) => showProgramSheet<T>(
  context,
  title: title,
  subtitle: subtitle,
  children: (context) => [builder(context)],
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
  (context) =>
      _VariantsSheet(set: set, exerciseName: exerciseName, cannotDo: cannotDo),
  title: 'Choisir une variante',
  subtitle: 'À la place de $exerciseName',
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
    return KMenuRow(
      key: ValueKey('variant-${v.exerciseId}'),
      title: planName(v.exerciseId),
      subtitle: [
        if (targeted) _variantKindLabels[v.kind]!,
        if (why != null) why,
      ].join(' · '),
      onTap: () => Navigator.of(context).pop(v.exerciseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final s = widget.set;
    final rest = [
      for (final v in s.all)
        if (!s.targeted.any((t) => t.exerciseId == v.exerciseId)) v,
    ];
    return Column(
      key: const ValueKey('variants-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KoachBubble(
          pose: widget.cannotDo ? KoachPose.choice : KoachPose.direction,
          koachHeight: KSize.primary + KSpacing.s32,
          text: widget.cannotDo
              ? 'Pas de souci. Que veux-tu à la place de ${widget.exerciseName} ?'
              : 'D’accord, on le retire. Que veux-tu à la place de '
                    '${widget.exerciseName} ?',
          why:
              'Je te propose une variante plus facile, une équivalente et une '
              'avec un autre matériel. Après ton choix, je réajuste le reste '
              'de la semaine et je te montre ce qui a bougé.',
        ),
        const SizedBox(height: KSpacing.s12),
        if (s.targeted.isEmpty)
          Text(
            'Aucune variante ciblée ne tient dans cette séance.',
            style: KType.corps.copyWith(color: k.texte2),
          )
        else
          KMenuGroup(
            color: k.haute,
            dividerIndent: KSpacing.s16,
            children: [for (final v in s.targeted) _tile(v, targeted: true)],
          ),
        const SizedBox(height: KSpacing.s12),
        KTonalButton(
          key: const ValueKey('variants-koach'),
          icon: Icons.auto_awesome_outlined,
          label: 'Laisse Koach choisir',
          expand: true,
          onPressed: () => Navigator.of(context).pop(''),
        ),
        if (rest.isNotEmpty && !_all)
          KTextButton(
            key: const ValueKey('variants-all'),
            onPressed: () => setState(() => _all = true),
            label: 'Voir tout (${rest.length})',
          ),
        if (_all) ...[
          const SizedBox(height: KSpacing.s8),
          KMenuGroup(
            title: 'Toutes les variantes (${rest.length})',
            color: k.haute,
            dividerIndent: KSpacing.s16,
            children: [for (final v in rest.take(_shown)) _tile(v)],
          ),
          if (rest.length > _shown)
            KTextButton(
              onPressed: () => setState(() => _shown += 40),
              label: 'Afficher plus (${rest.length - _shown} restants)',
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
}) => _sheet(
  context,
  (context) => _AddSheet(plan: plan, day: dayIndex),
  title: 'Ajouter un exercice que tu aimes',
);

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
      for (final e in searchExercises(
        store.content,
        _q,
        const ExerciseFilters(),
      ))
        if (!present.contains(e.id)) e,
    ];
    final k = KTokens.of(context);
    return Column(
      key: const ValueKey('add-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quel jour ?', style: KType.section.copyWith(color: k.texte2)),
        const SizedBox(height: KSpacing.s4),
        Wrap(
          spacing: KSpacing.s8,
          children: [
            for (final d in widget.plan.days)
              KChip(
                weekdayLabel(d.weekday),
                key: ValueKey('add-day-${d.dayIndex}'),
                selected: _day == d.dayIndex,
                onTap: () => setState(() => _day = d.dayIndex),
              ),
          ],
        ),
        const SizedBox(height: KSpacing.s12),
        KSearchField(
          key: const ValueKey('add-search'),
          hint: 'Rechercher un exercice',
          onChanged: (v) => setState(() {
            _q = v;
            _shown = 20;
          }),
        ),
        const SizedBox(height: KSpacing.s8),
        Text(
          '${all.length} exercice${all.length > 1 ? 's' : ''}',
          style: KType.detail.copyWith(color: k.texte2),
        ),
        const SizedBox(height: KSpacing.s4),
        if (all.isNotEmpty)
          KMenuGroup(
            color: k.haute,
            dividerIndent: KSpacing.s16,
            children: [
              for (final e in all.take(_shown))
                KMenuRow(
                  key: ValueKey('add-${e.id}'),
                  title: e.nom,
                  subtitle: '${e.discipline}, difficulté ${e.difficulte}/10',
                  chevron: false,
                  trailing: Icon(
                    Icons.add_circle_outline_rounded,
                    size: KSize.icon,
                    color: k.texte2,
                  ),
                  onTap: () => Navigator.of(
                    context,
                  ).pop((dayIndex: _day, exerciseId: e.id)),
                ),
            ],
          ),
        if (all.length > _shown)
          KTextButton(
            onPressed: () => setState(() => _shown += 40),
            label: 'Afficher plus (${all.length - _shown} restants)',
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
    title: 'Ce que j’ai changé',
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
    final k = KTokens.of(context);
    return Column(
      key: const ValueKey('step-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KoachBubble(
          key: const ValueKey('step-koach'),
          pose: step.sideEffects.isEmpty
              ? KoachPose.thumbsUp
              : KoachPose.explainBoard,
          koachHeight: KSize.primary * 2,
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
          const SizedBox(height: KSpacing.s12),
          KMenuGroup(
            title: 'Ce qui a bougé (${lines.length})',
            color: k.haute,
            dividerIndent: KSpacing.s16,
            children: [
              for (final (c, line) in lines)
                WhyTile(
                  key: ValueKey('step-change-${c.slotId ?? line}'),
                  title: line,
                  reasons: [for (final r in c.reasons) planReason(r)],
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
  title: planName(item.exerciseId),
  subtitle:
      'Réglage pour tout le bloc (les semaines de test gardent leur épreuve).',
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

  PlanAdjust get _cur =>
      widget.c.adjust[widget.item.slotId] ?? const PlanAdjust();

  void _try(PlanAdjust next) {
    final r = widget.c.setAdjust(
      widget.item.slotId,
      next,
      cautious: widget.cautious,
    );
    setState(() => _refusal = r);
  }

  Widget _row(
    String label,
    String value,
    String key,
    VoidCallback minus,
    VoidCallback plus,
  ) => KStepperRow(
    key: ValueKey('adjust-$key'),
    title: label,
    value: value,
    decrementLabel: '$label : moins',
    incrementLabel: '$label : plus',
    onDecrement: minus,
    onIncrement: plus,
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
          p.repsLow == p.repsHigh
              ? '${p.repsLow}'
              : '${p.repsLow}-${p.repsHigh}',
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
    return Column(
      key: const ValueKey('adjust-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KMenuGroup(
          color: KTokens.of(context).haute,
          dividerIndent: KSpacing.s16,
          children: rows,
        ),
        if (_refusal != null) ...[
          const SizedBox(height: KSpacing.s12),
          KoachBubble(
            key: const ValueKey('adjust-refused'),
            pose: KoachPose.oops,
            koachHeight: KSize.primary + KSpacing.s16,
            text: _refusal!,
          ),
        ],
        const SizedBox(height: KSpacing.s12),
        if (!a.isEmpty)
          KTonalButton(
            key: const ValueKey('adjust-reset'),
            expand: true,
            onPressed: () => _try(const PlanAdjust()),
            label: 'Revenir à ma proposition',
          ),
        const SizedBox(height: KSpacing.s8),
        KPrimaryButton(
          key: const ValueKey('adjust-done'),
          onPressed: () => Navigator.of(context).pop(),
          label: 'OK',
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
      FlameIcon(flames, size: KSize.iconSmall, semantics: false),
      const SizedBox(width: KSpacing.s4),
      Text(
        '$flames/10 · RIR ${flameRirText(flames)}',
        semanticsLabel: flameSemanticLabel(flames),
        style: KType.detail.copyWith(color: KTokens.of(context).texte2),
      ),
    ],
  );
}
