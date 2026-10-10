// G10 (D5.6, D5.7, D6.4) : les propositions du moteur dynamique dites par
// Koach — carte de l'accueil, carte au début de la séance concernée,
// feuille « ce qui change » (diff de kalis_plan, même présentation qu'à la
// création du programme, G7), écran « Évolution » de Mon programme (mode
// assisté / libre, ce que Koach sait déjà ajuster, historique).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../athlete_profile_screen.dart' show ProfileScreen;
import '../koach/koach_bubble.dart';
import '../store.dart';
import '../ui.dart';
import 'evolution_texts.dart';
import 'plan_program.dart' show PlanBlockEntry;
import 'plan_sheets.dart' show changeLine, planName, planReason;
import 'plan_texts.dart';
import 'widgets/program_widgets.dart';

// ------------------------------------------------------------------ outils

/// Passe 1 du bloc d'une proposition (jours de la semaine), si connue.
kc.Pass1Plan? evolutionPass1(String blockId) {
  for (final b in store.planProgram?.blocks ?? const <PlanBlockEntry>[]) {
    if (b.block.pass1.blockId == blockId) {
      return store.evolveBlock(b.block).pass1;
    }
  }
  final r = store.lastEvolutionReview;
  if (r != null && r.place.blockId == blockId) return r.place.block.pass1;
  // CI1e : bloc du programme importé annoté (blocs précédents compris).
  final seg = store.importedProgram?.byBlockId(blockId);
  if (seg != null) return store.evolveBlock(seg.block).pass1;
  return null;
}

String _dayName(String blockId, int dayIndex) {
  final p = evolutionPass1(blockId);
  if (p != null) {
    for (final d in p.days) {
      if (d.dayIndex == dayIndex) return weekdayLabel(d.weekday);
    }
  }
  return 'Séance ${dayIndex + 1}';
}

String evolutionHeadlineOf(EvolutionEntry e) => evolutionHeadline(
  e,
  exerciseName: planName,
  dayName: (d) => _dayName(e.blockId, d),
  currentWeek: store.evolutionCurrentWeek(e.blockId),
);

/// Clé d'une proposition (l'identifiant du moteur n'est unique que dans
/// son bloc).
String evoKey(EvolutionEntry e) => '${e.blockId}|${e.id}';

/// « Pourquoi ? » : raisons et confiance du moteur, en mots simples.
String evolutionWhy(EvolutionEntry e) {
  final reasons = evolutionReasons(e.proposal, exerciseName: planName);
  return [
    ...reasons,
    confidenceWords(e.proposal.confidence),
    if (e.status == EvoStatus.pending)
      'Si tu refuses, je ne te le reproposerai pas avant quelques semaines.',
  ].join(' ');
}

/// Lignes du diff (G7) : remplacements, ajouts, retraits, déplacements ;
/// changements de séries et de flammes visées.
List<(kc.PlanChange, String)> evolutionDiffLines(EvolutionEntry e) {
  final changes = e.proposal.diff?.changes ?? const <kc.PlanChange>[];
  final before = evolutionPass1(e.blockId);
  final after = e.proposal.block?.pass1 ?? before;
  final out = <(kc.PlanChange, String)>[];
  final seen = <String>{};
  for (final c in changes) {
    if (c.kind == kc.ChangeKind.prescriptionChanged) {
      final to = c.toPrescription;
      final day = c.dayIndex == null
          ? 'Semaine'
          : _dayName(e.blockId, c.dayIndex!);
      final line = prescriptionChangeLine(
        c,
        day,
        planName(to?.exerciseId ?? c.slotId ?? ''),
      );
      if (seen.add(line)) out.add((c, line));
      continue;
    }
    if (before == null || after == null) {
      out.add((c, 'Séances revues'));
      continue;
    }
    final line = changeLine(c, before, after);
    if (seen.add(line)) out.add((c, line));
  }
  return out;
}

void _toast(BuildContext context, String text, {KoachPose? pose}) =>
    showKoachToast(context, text, pose: pose ?? KoachPose.thumbsUp);

/// Actions de Koach pour une proposition, selon sa suite.
List<KoachBubbleAction> evolutionActions(
  BuildContext context,
  EvolutionEntry e, {
  bool details = true,
  bool pop = false,
}) {
  void done(String text, {KoachPose? pose}) {
    if (pop) Navigator.of(context).pop();
    _toast(context, text, pose: pose);
  }

  final out = <KoachBubbleAction>[];
  if (e.status == EvoStatus.pending) {
    out
      ..add(
        KoachBubbleAction(
          'Accepter',
          () {
            store.evolutionAccept(e);
            done('C’est noté, ton programme est à jour.');
          },
          primary: true,
          key: ValueKey('evo-accept-${evoKey(e)}'),
        ),
      )
      ..add(
        KoachBubbleAction('Refuser', () {
          store.evolutionRefuse(e);
          done('D’accord, je garde ton programme tel quel.');
        }, key: ValueKey('evo-refuse-${evoKey(e)}')),
      )
      ..add(
        KoachBubbleAction('Plus tard', () {
          store.evolutionLater(e);
          done('Je t’en reparle demain.', pose: KoachPose.wave);
        }, key: ValueKey('evo-later-${evoKey(e)}')),
      );
  } else if (e.inEffect) {
    if (!e.seen) {
      out.add(
        KoachBubbleAction(
          'Compris',
          () {
            store.evolutionSeen(e);
            if (pop) Navigator.of(context).pop();
          },
          primary: true,
          key: ValueKey('evo-seen-${evoKey(e)}'),
        ),
      );
    }
    if (store.evolutionCanUndo(e)) {
      out.add(
        KoachBubbleAction('Annuler', () {
          final ok = store.evolutionUndo(e);
          done(
            ok
                ? 'Changement annulé : ton programme reprend comme avant.'
                : 'Trop tard pour annuler : la séance concernée a commencé.',
            pose: ok ? KoachPose.thumbsUp : KoachPose.oops,
          );
        }, key: ValueKey('evo-undo-${evoKey(e)}')),
      );
    }
  }
  if (details && evolutionDiffLines(e).isNotEmpty) {
    out.add(
      KoachBubbleAction(
        'Voir le changement',
        () => showEvolutionSheet(context, e),
        key: ValueKey('evo-details-${evoKey(e)}'),
      ),
    );
  }
  return out;
}

// --------------------------------------------------------- feuille du diff

/// Feuille « ce qui change » d'une proposition (diff expliqué par Koach).
Future<void> showEvolutionSheet(BuildContext context, EvolutionEntry e) =>
    showProgramSheet<void>(
      context,
      listKey: const ValueKey('evo-sheet'),
      title: evolutionKindTitle(e.proposal.kind),
      children: (context) => _evolutionSheet(context, e),
    );

List<Widget> _evolutionSheet(BuildContext context, EvolutionEntry e) {
  final k = KTokens.of(context);
  final lines = evolutionDiffLines(e);
  return [
    KoachBubble(
      key: const ValueKey('evo-sheet-koach'),
      pose: evolutionPose(e.proposal.kind, pending: e.status == EvoStatus.pending),
      koachHeight: KSize.primary * 2,
      text: evolutionHeadlineOf(e),
      why: evolutionWhy(e),
      actions: evolutionActions(context, e, details: false, pop: true),
    ),
    if (lines.isNotEmpty)
      KMenuGroup(
        title: 'Ce qui change (${lines.length})',
        color: k.haute,
        dividerIndent: KSpacing.s16,
        children: [
          for (final (c, line) in lines)
            WhyTile(
              key: ValueKey('evo-change-${c.slotId ?? line}-${c.weekIndex}'),
              title: line,
              reasons: [
                for (final r in c.reasons)
                  if (evolutionReasonText(r, exerciseName: planName) ??
                          (r.code.startsWith('plan.') ? planReason(r) : null)
                      case final t?)
                    t,
              ],
            ),
        ],
      ),
  ];
}

// -------------------------------------------------------- carte de l'accueil

/// Carte de l'accueil : proposition en attente (mode libre) ou changement
/// appliqué que Koach annonce (mode assisté).
class EvolutionHomeCard extends StatelessWidget {
  const EvolutionHomeCard({super.key});

  static List<EvolutionEntry> get _items => [
    ...store.evolutionPending,
    ...store.evolutionAnnounced,
  ];

  static bool get visible => _items.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    final e = items.first;
    final more = items.length - 1;
    return KCard(
      key: const ValueKey('evo-home-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Koach · ${evolutionKindTitle(e.proposal.kind)}',
            style: KType.section.copyWith(color: k.texte2),
          ),
          const SizedBox(height: KSpacing.s8),
          KoachBubble(
            key: ValueKey('evo-home-${evoKey(e)}'),
            pose: evolutionPose(
              e.proposal.kind,
              pending: e.status == EvoStatus.pending,
            ),
            koachHeight: KSize.primary + KSpacing.s32,
            text: evolutionHeadlineOf(e),
            why: evolutionWhy(e),
            actions: evolutionActions(context, e),
          ),
          if (more > 0) ...[
            const SizedBox(height: KSpacing.s4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KTextButton(
                key: const ValueKey('evo-home-more'),
                icon: Icons.chevron_right_rounded,
                alignStart: true,
                onPressed: () => openEvolutionScreen(context),
                label:
                    'Et $more autre${more > 1 ? 's' : ''} changement'
                    '${more > 1 ? 's' : ''} : tout voir',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------- carte de la séance

/// Au début de la séance concernée : ce qui change dans cette séance.
class EvolutionSessionCard extends StatelessWidget {
  final int week, j;
  const EvolutionSessionCard({super.key, required this.week, required this.j});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final items = store.evolutionForSession(week, j);
    if (items.isEmpty) return const SizedBox.shrink();
    final e = items.first;
    return KCard(
      key: const ValueKey('evo-session-card'),
      child: KoachSays(
        pose: evolutionPose(e.proposal.kind, pending: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              items.length == 1
                  ? 'Ce qui change dans cette séance : '
                        '${evolutionAction(e, exerciseName: planName, dayName: (d) => _dayName(e.blockId, d))}.'
                  : 'Cette séance change (${items.length} changements).',
              style: KType.corps.copyWith(color: k.texte),
            ),
            const SizedBox(height: KSpacing.s8),
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s8,
              children: [
                for (final x in items)
                  KTonalButton(
                    key: ValueKey('evo-session-see-${evoKey(x)}'),
                    onPressed: () => showEvolutionSheet(context, x),
                    label: items.length == 1
                        ? 'Voir le changement'
                        : evolutionKindTitle(x.proposal.kind),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- écran

Future<void> openEvolutionScreen(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const EvolutionScreen()));

/// Ce que Koach sait déjà ajuster (D5.7), et ce qu'il débloquera.
class EvolutionUnlockCard extends StatelessWidget {
  const EvolutionUnlockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final u = store.evolutionUnlock;
    final next = unlockNextText(
      next: u.next,
      weeks: u.weeksToNext,
      blocks: u.blocksToNext,
    );
    return KCard(
      key: const ValueKey('evo-unlock'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KoachSays(
            pose: KoachPose.progressChart,
            child: Text(
              next ??
                  'Je peux maintenant tout ajuster, jusqu’à réorganiser ton '
                      'bloc, quand je suis assez sûr de moi.',
              key: const ValueKey('evo-unlock-next'),
              style: KType.corps.copyWith(color: k.texte),
            ),
          ),
          const SizedBox(height: KSpacing.s12),
          for (final l in kc.UnlockLevel.values)
            Semantics(
              label:
                  '${l.index <= u.level.index ? 'Débloqué' : 'Pas encore'} : '
                  '${kUnlockCan[l]}, ${kUnlockWhen[l]}',
              excludeSemantics: true,
              child: Padding(
                key: ValueKey('evo-unlock-${l.code}'),
                padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      l.index <= u.level.index
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      size: KSize.iconSmall,
                      color: l.index <= u.level.index
                          ? k.validation
                          : k.texte2,
                    ),
                    const SizedBox(width: KSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capitalized(kUnlockCan[l]!),
                            style: KType.corps.copyWith(
                              color: l.index <= u.level.index
                                  ? k.texte
                                  : k.texte2,
                            ),
                          ),
                          Text(
                            '${kUnlockWhen[l]}'
                            '${l.index <= u.level.index ? '' : ' (pas encore)'}',
                            style: KType.detail.copyWith(color: k.texte2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: KSpacing.s8),
          Text(
            '${u.weeksObserved} semaine${u.weeksObserved > 1 ? 's' : ''} de '
            'séances suivies. Même débloqué, je ne propose un changement que '
            'si je suis assez sûr de moi.',
            style: KType.detail.copyWith(color: k.texte2),
          ),
        ],
      ),
    );
  }
}

/// Mon programme › Évolution : mode (seul réglage du mode, §4.3),
/// déblocage, propositions en attente, historique des changements.
class EvolutionScreen extends StatefulWidget {
  const EvolutionScreen({super.key});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  @override
  void initState() {
    super.initState();
    // Revue à jour (une seule par état du journal).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) store.evolutionRefresh();
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final k = KTokens.of(context);
      final mode = store.adaptMode;
      final pending = store.evolutionPending;
      final history = store.evolutionHistory;
      final body = KType.corps.copyWith(color: k.texte);
      final detail = KType.detail.copyWith(color: k.texte2);
      return KPage.sub(
        key: const ValueKey('evo-list'),
        title: 'Évolution',
        children: [
          if (store.athlete == null)
            KEmpty(
              key: const ValueKey('evo-no-profile'),
              icon: Icons.person_outline_rounded,
              title: 'Il me faut ton profil',
              message:
                  'Il me faut ton profil pour suivre tes séances et faire '
                  'évoluer ton programme.',
              action: 'Créer mon profil',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
            )
          else
            KCard(
              key: const ValueKey('evo-mode'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Quand je vois qu’un changement t’aiderait',
                    style: KType.titreCarte.copyWith(color: k.texte),
                  ),
                  const SizedBox(height: KSpacing.s12),
                  KSegmented<String>(
                    key: const ValueKey('evo-mode-switch'),
                    semanticLabel: 'Mode d’évolution',
                    segments: const [
                      KSegment('assisted', 'Assisté'),
                      KSegment('free', 'Libre'),
                    ],
                    selected: mode,
                    onChanged: store.setGuidanceMode,
                  ),
                  const SizedBox(height: KSpacing.s12),
                  Text(
                    mode == 'assisted'
                        ? 'Assisté : je l’applique moi-même et je te dis '
                              'pourquoi. Tu peux annuler jusqu’à la séance '
                              'concernée.'
                        : 'Libre : je te propose, tu décides (accepter, '
                              'refuser ou plus tard). Rien ne change sans '
                              'ton accord.',
                    key: const ValueKey('evo-mode-text'),
                    style: body,
                  ),
                ],
              ),
            ),
          const EvolutionUnlockCard(),
          if (pending.isNotEmpty) ...[
            const KSectionTitle('Propositions en attente'),
            for (final e in pending)
              KCard(
                key: ValueKey('evo-pending-${evoKey(e)}'),
                child: KoachBubble(
                  pose: evolutionPose(e.proposal.kind, pending: true),
                  koachHeight: KSize.primary + KSpacing.s16,
                  text: evolutionHeadlineOf(e),
                  why: evolutionWhy(e),
                  actions: evolutionActions(context, e),
                ),
              ),
          ],
          // CI1c : ce que Koach a repéré sans pouvoir l'appliquer au
          // programme importé, en clair (pas de bouton « Accepter »).
          for (final p in store.evolutionNotApplicable)
            KCard(
              key: ValueKey('evo-not-applicable-${p.id}'),
              child: KoachSays(
                pose: KoachPose.you,
                child: Text(
                  'J’ai repéré un changement possible '
                  '(${evolutionKindTitle(p.kind).toLowerCase()}), mais il '
                  'ne peut pas s’appliquer à ton programme importé jour '
                  'pour jour : ton programme reste tel quel.',
                  style: body,
                ),
              ),
            ),
          const KSectionTitle('Historique des changements'),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
              child: Text(
                'Aucun changement pour l’instant : je commence par régler tes '
                'charges et tes répétitions, séance après séance.',
                key: const ValueKey('evo-history-empty'),
                style: detail,
              ),
            ),
          for (final e in history)
            KCard(
              key: ValueKey('evo-history-${evoKey(e)}'),
              onTap: () => showEvolutionSheet(context, e),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          evolutionKindTitle(e.proposal.kind),
                          style: KType.corpsFort.copyWith(color: k.texte),
                        ),
                      ),
                      const SizedBox(width: KSpacing.s8),
                      KChip(
                        evolutionStatusLabel(e.status),
                        icon: switch (e.status) {
                          EvoStatus.refused => Icons.block_rounded,
                          EvoStatus.undone => Icons.undo_rounded,
                          _ => Icons.check_rounded,
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: KSpacing.s4),
                  Text(
                    capitalized(
                      evolutionAction(
                        e,
                        exerciseName: planName,
                        dayName: (d) => _dayName(e.blockId, d),
                      ),
                    ),
                    style: body,
                  ),
                  for (final r in evolutionReasons(
                    e.proposal,
                    exerciseName: planName,
                  ))
                    Text(r, style: detail),
                  Text(
                    '${_date(e.decidedOn)}, '
                    '${e.mode == 'assisted' ? 'mode assisté' : 'mode libre'}',
                    style: detail,
                  ),
                  if (store.evolutionCanUndo(e)) ...[
                    const SizedBox(height: KSpacing.s8),
                    KTonalButton(
                      key: ValueKey('evo-history-undo-${evoKey(e)}'),
                      label: 'Annuler ce changement',
                      onPressed: () {
                        final ok = store.evolutionUndo(e);
                        showKoachToast(
                          context,
                          ok ? 'Changement annulé.' : 'Trop tard pour annuler.',
                          pose: ok ? KoachPose.thumbsUp : KoachPose.oops,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    },
  );
}

String _date(String? iso) {
  if (iso == null || iso.length < 10) return '';
  return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}';
}
