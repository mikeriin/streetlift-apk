// G7 (D4.8, D4.9) : « Où j'en suis » et fin de bloc.
//
// « Où j'en suis » : l'utilisateur choisit sa semaine et sa séance ; la
// séance choisie devient celle d'aujourd'hui et les séances d'avant sans
// journal sont marquées « reprise » (neutres : ni XP, ni statistiques, ni
// série, ni records, ni données pour les moteurs). Fonctionne pour tout
// programme, celui du propriétaire compris.
//
// Fin de bloc : G10 passe par la création du programme (plan_screens.dart,
// mode « bloc suivant »).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../koach/koach_bubble.dart';
import '../models.dart' show WeekPlan;
import '../store.dart';
import '../ui.dart';
import 'plan_texts.dart';

class ProgramPositionScreen extends StatefulWidget {
  const ProgramPositionScreen({super.key});

  @override
  State<ProgramPositionScreen> createState() => _ProgramPositionScreenState();
}

class _ProgramPositionScreenState extends State<ProgramPositionScreen> {
  late int _week;
  int? _day;

  @override
  void initState() {
    super.initState();
    final pos = PlanStore(store).programPosition;
    _week = (pos?.week ?? 1).clamp(1, store.program.weeks.length);
    final w = store.program.week(_week);
    final today = pos?.day;
    _day = today != null && (w.day(today)?.exercises.isNotEmpty ?? false)
        ? today
        : _firstTraining(w);
  }

  int? _firstTraining(WeekPlan w) {
    for (final d in w.days) {
      if (d.exercises.isNotEmpty) return d.j;
    }
    return null;
  }

  void _setWeek(int w) {
    final n = w.clamp(1, store.program.weeks.length);
    setState(() {
      _week = n;
      _day = _firstTraining(store.program.week(n));
    });
  }

  int get _resumeCount {
    final day = _day;
    if (day == null) return 0;
    final at = (_week - 1) * 7 + day - 1;
    var n = 0;
    for (final w in store.program.weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        if ((w.n - 1) * 7 + d.j - 1 >= at) continue;
        final l = store.logs[store.sessionKey(w.n, d.j)];
        final logged =
            l != null &&
            (l.done || l.ex.values.any((x) => x.sets.any((s) => s.done)));
        if (!logged) n++;
      }
    }
    return n;
  }

  Future<void> _confirm() async {
    final day = _day;
    if (day == null) return;
    final nav = Navigator.of(context);
    final colors = KoachToastColors.of(context);
    final messenger = ScaffoldMessenger.of(context);
    PlanStore(store).setProgramPosition(_week, day);
    messenger.showSnackBar(
      koachSnackBar(
        colors,
        'C’est noté : aujourd’hui, semaine $_week, séance J$day.',
        pose: KoachPose.thumbsUp,
      ),
    );
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final w = store.program.week(_week);
    final count = _resumeCount;
    return KPage.sub(
      key: const ValueKey('position-list'),
      title: 'Où j’en suis',
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpacing.page,
            KSpacing.s8,
            KSpacing.page,
            KSpacing.s16,
          ),
          child: KPrimaryButton(
            key: const ValueKey('position-confirm'),
            onPressed: _day == null ? null : _confirm,
            label: 'C’est là que j’en suis',
          ),
        ),
      ),
      children: [
        const KoachBubble(
          key: ValueKey('position-koach'),
          pose: KoachPose.direction,
          koachHeight: KSize.primary * 2,
          text:
              'Dis-moi où tu en es dans ton programme : la séance '
              'choisie devient celle d’aujourd’hui.',
          why:
              'Utile après un changement de téléphone ou une sauvegarde '
              'restaurée. Les séances d’avant que tu n’as pas saisies '
              'sont marquées « reprise » : elles ne comptent ni en XP, ni '
              'dans tes statistiques, ni dans ta série, ni pour tes '
              'records. Ton niveau ne bouge pas. Ce que tu as déjà saisi '
              'reste tel quel.',
        ),
        KCard(
          padding: const EdgeInsets.all(KSpacing.s8),
          child: Row(
            children: [
              KIconButton(
                key: const ValueKey('position-week-minus'),
                tooltip: 'Semaine précédente',
                filled: true,
                icon: Icons.chevron_left_rounded,
                onPressed: _week > 1 ? () => _setWeek(_week - 1) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      k.title('Semaine $_week'),
                      key: const ValueKey('position-week'),
                      textAlign: TextAlign.center,
                      style: k.titleStyle(
                        KType.titreEcran.copyWith(color: k.texte),
                      ),
                    ),
                    Text(
                      w.block,
                      textAlign: TextAlign.center,
                      style: KType.detail.copyWith(color: k.texte2),
                    ),
                  ],
                ),
              ),
              KIconButton(
                key: const ValueKey('position-week-plus'),
                tooltip: 'Semaine suivante',
                filled: true,
                icon: Icons.chevron_right_rounded,
                onPressed: _week < store.program.weeks.length
                    ? () => _setWeek(_week + 1)
                    : null,
              ),
            ],
          ),
        ),
        KMenuGroup(
          title: 'Ta séance d’aujourd’hui',
          children: [
            for (final d in w.days)
              if (d.exercises.isNotEmpty)
                Semantics(
                  selected: _day == d.j,
                  inMutuallyExclusiveGroup: true,
                  child: KMenuRow(
                    key: ValueKey('position-day-${d.j}'),
                    leading: SizedBox(
                      width: KSize.menuIcon,
                      child: Icon(
                        _day == d.j
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: KSize.icon,
                        color: _day == d.j ? k.encre : k.texte3,
                      ),
                    ),
                    title: 'J${d.j} · ${d.title}',
                    subtitle:
                        '${d.exercises.length} exercices'
                        '${store.isDone(_week, d.j) ? ', déjà faite' : ''}',
                    chevron: false,
                    onTap: () => setState(() => _day = d.j),
                  ),
                ),
          ],
        ),
        if (_day != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Text(
              count == 0
                  ? 'Aucune séance ne sera marquée « reprise ».'
                  : '$count séance${count > 1 ? 's' : ''} d’avant '
                        '${count > 1 ? 'seront marquées' : 'sera marquée'} '
                        '« reprise » (neutre).',
              key: const ValueKey('position-count'),
              style: KType.corps.copyWith(color: k.texte2),
            ),
          ),
      ],
    );
  }
}

/// Raccourci : jour civil lisible « lundi 05/10 ».
String civilShort(kc.CivilDate d) =>
    '${weekdayLabel(d.weekday).toLowerCase()} '
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
