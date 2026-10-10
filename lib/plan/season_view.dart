// CI1 (dev6.9.0, pipeline CP) : vue de la saison d'un programme écrit par
// le chemin calibré (`kalis_plan` 0.2) : phases calées à rebours sur
// l'échéance, compte à rebours, semaines d'allègement, de test et
// d'affûtage du bloc en cours, règles du programme et échelles des
// figures. Un programme du chemin 0.1 n'a pas de saison : la carte ne
// s'affiche pas. CI1e (C11) : le programme de 40 semaines du propriétaire
// a la saison de son annotation (phases de ses blocs, échéance à la fin
// de S40).
//
// Lecture seule : tout vient du plan de saison et des blocs stockés.
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../athlete_profile_screen.dart' show ProfileScreen;
import '../koach/koach_bubble.dart' show KoachSays;
import '../store.dart';
import '../ui.dart';
import 'coach_texts.dart';
import 'event_day_screen.dart';
import 'plan_program.dart';
import 'plan_screens.dart' show openPlanCreation;
import 'plan_texts.dart' show kWeekKindLabels;

/// Phase de la saison, datée.
class SeasonPhaseView {
  final String code;
  final DateTime start;

  /// Dernier jour de la phase (compris).
  final DateTime end;
  final int weeks;
  final String? eventName;
  final bool current;
  final bool past;
  const SeasonPhaseView({
    required this.code,
    required this.start,
    required this.end,
    required this.weeks,
    required this.eventName,
    required this.current,
    required this.past,
  });
}

/// Semaine du bloc en cours.
class SeasonWeekView {
  /// Numéro de semaine du programme (S).
  final int n;
  final String label;

  /// Semaine allégée, de test, d'affûtage, d'échéance ou de transition.
  final bool special;
  final bool current;
  const SeasonWeekView(this.n, this.label, this.special, this.current);
}

/// Ce que la vue de la saison montre.
class SeasonOverview {
  final List<SeasonPhaseView> phases;
  final String? eventName;
  final DateTime? eventDate;

  /// Échéance principale à venir.
  final kc.SeasonEvent? event;

  /// Jours avant l'échéance principale (0 : aujourd'hui), null sans
  /// échéance à venir.
  final int? daysToEvent;
  final List<SeasonWeekView> blockWeeks;
  final int blockIndex;
  final List<String> rules;
  final List<String> ladders;
  const SeasonOverview({
    required this.phases,
    required this.eventName,
    required this.eventDate,
    this.event,
    required this.daysToEvent,
    required this.blockWeeks,
    required this.blockIndex,
    required this.rules,
    required this.ladders,
  });

  SeasonPhaseView? get currentPhase {
    for (final p in phases) {
      if (p.current) return p;
    }
    return null;
  }

  /// Prochaine semaine particulière du bloc (allègement, test, affûtage).
  SeasonWeekView? get nextSpecial {
    final cur = blockWeeks.indexWhere((w) => w.current);
    for (var i = cur < 0 ? 0 : cur; i < blockWeeks.length; i++) {
      if (blockWeeks[i].special) return blockWeeks[i];
    }
    return null;
  }
}

DateTime _day(kc.CivilDate d) => DateTime(d.year, d.month, d.day);

int _days(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

const _specialIntents = {
  kc.WeekIntent.deload,
  kc.WeekIntent.taper,
  kc.WeekIntent.test,
  kc.WeekIntent.competition,
  kc.WeekIntent.transition,
};

/// Vue de la saison de [plan] (null : programme sans saison calibrée).
SeasonOverview? seasonOverview(
  PlanProgram plan, {
  required List<kc.SeasonEvent> events,
  required DateTime today,
  required DateTime? programStart,
  kc.Catalog? catalog,
}) {
  final season = plan.season;
  final lastBlock = plan.blocks.last.block;
  if (season == null && !isCoachBlock(lastBlock)) return null;
  // Semaines du bloc en cours.
  var blockIndex = plan.blocks.length - 1;
  int? currentWeek;
  if (programStart != null) {
    final o = _days(programStart, today);
    if (o >= 0) currentWeek = o ~/ 7 + 1;
  }
  final loc = currentWeek == null ? null : plan.locate(currentWeek);
  if (loc != null) blockIndex = loc.block;
  return seasonOverviewOf(
    season,
    events: events,
    today: today,
    currentWeek: currentWeek,
    block: plan.blocks[blockIndex].block,
    blockFirstWeek: plan.blockFirstWeek(blockIndex),
    blockIndex: blockIndex,
    catalog: catalog,
  );
}

/// Vue d'une saison [season] dont le bloc en cours est [block] (rang
/// [blockIndex], première semaine [blockFirstWeek]).
SeasonOverview seasonOverviewOf(
  kc.SeasonPlan? season, {
  required List<kc.SeasonEvent> events,
  required DateTime today,
  required int? currentWeek,
  required kc.ProgramBlock block,
  required int blockFirstWeek,
  required int blockIndex,
  kc.Catalog? catalog,
}) {
  String? nameOf(String? id) {
    if (id == null) return null;
    for (final e in events) {
      if (e.id == id) return e.name ?? _eventKind(e.kind);
    }
    return null;
  }

  final phases = <SeasonPhaseView>[];
  for (final p in season?.phases ?? const <kc.SeasonPhase>[]) {
    final start = _day(p.startDate);
    final end = start.add(Duration(days: p.weeks * 7 - 1));
    phases.add(
      SeasonPhaseView(
        code: p.kind.code,
        start: start,
        end: end,
        weeks: p.weeks,
        eventName: nameOf(p.eventId),
        current: _days(start, today) >= 0 && _days(today, end) >= 0,
        past: _days(end, today) > 0,
      ),
    );
  }
  // Échéance principale à venir (sinon la plus proche).
  kc.SeasonEvent? event;
  for (final e in events) {
    if (_days(today, _day(e.date)) < 0) continue;
    if (event == null ||
        (e.priority == kc.EventPriority.main &&
            event.priority != kc.EventPriority.main) ||
        (e.priority == event.priority &&
            _day(e.date).isBefore(_day(event.date)))) {
      event = e;
    }
  }
  final weeks = <SeasonWeekView>[];
  final first = blockFirstWeek;
  for (var w = 0; w < block.pass2.weeks.length; w++) {
    final wk = block.pass2.weeks[w];
    final intent = wk.intent;
    final label = intent == null
        ? (kWeekKindLabels[wk.kind] ?? wk.kind.code)
        : phaseTitle(intent.code);
    final special = intent != null
        ? _specialIntents.contains(intent)
        : wk.kind == kc.WeekKind.deload || wk.kind == kc.WeekKind.test;
    weeks.add(
      SeasonWeekView(first + w, label, special, first + w == currentWeek),
    );
  }
  return SeasonOverview(
    phases: phases,
    eventName: event == null ? null : (event.name ?? _eventKind(event.kind)),
    eventDate: event == null ? null : _day(event.date),
    event: event,
    daysToEvent: event == null ? null : _days(today, _day(event.date)),
    blockWeeks: weeks,
    blockIndex: blockIndex,
    rules: coachProgramRules(block, catalog),
    ladders: coachLadderLines(block, catalog),
  );
}

String _eventKind(kc.EventKind k) => switch (k) {
  kc.EventKind.strengthCompetition => 'Compétition de force',
  kc.EventKind.repsCompetition => 'Compétition de répétitions',
  kc.EventKind.freestyleCompetition => 'Compétition de freestyle',
  kc.EventKind.race => 'Course',
  kc.EventKind.personalTest => 'Test perso',
  _ => 'Échéance',
};

const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// Point final, sauf après une abréviation (« 4 nov. »).
String _sentence(String s) => s.endsWith('.') ? s : '$s.';

String _short(DateTime d) => '${d.day} ${_months[d.month - 1]}';

const _longMonths = [
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

/// « 24 décembre » (l'année s'ajoute hors de l'année en cours).
String _long(DateTime d, DateTime today) =>
    '${d.day == 1 ? '1er' : d.day} ${_longMonths[d.month - 1]}'
    '${d.year == today.year ? '' : ' ${d.year}'}';

/// Compte à rebours en deux parties : le grand chiffre (« 12 semaines »)
/// et la suite (« avant Championnat, le 24 décembre (84 jours) »).
(String, String) countdownParts(
  int days,
  String event,
  DateTime date,
  DateTime today,
) {
  final when = _long(date, today);
  if (days == 0) return ('Aujourd’hui', '$event, le $when');
  if (days == 1) return ('Demain', '$event, le $when');
  if (days < 14) return ('$days jours', 'avant $event, le $when');
  return ('${days ~/ 7} semaines', 'avant $event, le $when ($days jours)');
}

DateTime _today() {
  final n = store.storeClock();
  return DateTime(n.year, n.month, n.day);
}

/// Compte à rebours en clair.
String countdownText(int days) => days == 0
    ? 'aujourd’hui'
    : days == 1
    ? 'demain'
    : days < 14
    ? 'dans $days jours'
    : 'dans ${days ~/ 7} semaines ($days jours)';

/// Vue de la saison du programme en place (null : pas de saison).
SeasonOverview? storeSeasonOverview() {
  final plan = store.planProgram;
  final n = store.storeClock();
  final today = DateTime(n.year, n.month, n.day);
  final start = store.program.start;
  // CI1e (C11) : semaine du programme importé (programme de 40 semaines
  // du propriétaire, ou semaines d'avant un programme créé) : saison de
  // son annotation.
  final week = start == null || _days(start, today) < 0
      ? null
      : _days(start, today) ~/ 7 + 1;
  if (plan == null || (week != null && week < plan.firstWeek)) {
    final imp = store.importedProgram;
    final season = imp?.season;
    if (imp == null || season == null) return null;
    final seg =
        (week == null ? null : imp.segmentOf(week)) ??
        (week != null && week > imp.segments.last.last
            ? imp.segments.last
            : imp.segments.first);
    final event = imp.event;
    return seasonOverviewOf(
      season,
      events: [
        ...?store.athlete?.profile.events,
        if (event != null &&
            !(store.athlete?.profile.events ?? const <kc.SeasonEvent>[]).any(
              (e) => e.priority == kc.EventPriority.main,
            ))
          event,
      ],
      today: today,
      currentWeek: week,
      block: seg.block,
      blockFirstWeek: seg.first,
      blockIndex: seg.index,
      catalog: store.content.catalog,
    );
  }
  return seasonOverview(
    plan,
    events: store.athlete?.profile.events ?? const <kc.SeasonEvent>[],
    today: DateTime(n.year, n.month, n.day),
    programStart: store.program.start,
    catalog: store.content.catalog,
  );
}

/// Carte « Ma saison » de Mon programme (maquette « Mon programme ») :
/// compte à rebours de l'échéance, phase en cours, prochaine semaine
/// particulière ; toute la carte ouvre Ma saison.
class SeasonCard extends StatelessWidget {
  final SeasonOverview view;
  const SeasonCard({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final cur = view.currentPhase;
    final next = view.nextSpecial;
    final today = _today();
    final count = view.eventName != null && view.daysToEvent != null
        ? countdownParts(
            view.daysToEvent!,
            view.eventName!,
            view.eventDate!,
            today,
          )
        : null;
    final detail = KType.detail.copyWith(color: k.texte2);
    final competition =
        view.event?.kind == kc.EventKind.strengthCompetition ||
        view.event?.kind == kc.EventKind.repsCompetition;
    return KeyedSubtree(
      key: const ValueKey('program-season'),
      child: KCard(
        key: const ValueKey('season-open'),
        semanticsLabel: 'Ma saison',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SeasonScreen())),
        child: Row(
          children: [
            Expanded(
              child: KoachSays(
                pose: KoachPose.direction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ma saison',
                      style: KType.titreCarte.copyWith(color: k.texte),
                    ),
                    if (count != null) ...[
                      const SizedBox(height: KSpacing.s4),
                      KFitTitle(
                        // Espaces ordinaires : le grand chiffre passe à la
                        // ligne entre les mots plutôt que de se couper.
                        count.$1.replaceAll('\u00a0', ' '),
                        style: KType.chiffre.copyWith(color: k.encre),
                      ),
                      Text(
                        count.$2,
                        key: const ValueKey('season-countdown'),
                        style: detail,
                      ),
                    ],
                    if (cur != null) ...[
                      const SizedBox(height: KSpacing.s4),
                      Text(
                        _sentence(
                          'Phase en cours : ${phaseLabel(cur.code)}, '
                          'jusqu’au ${_short(cur.end)}',
                        ),
                        style: KType.corps.copyWith(color: k.texte),
                      ),
                    ],
                    if (next != null)
                      Text(
                        next.current
                            ? 'Cette semaine : ${next.label.toLowerCase()}.'
                            : 'Semaine ${next.n} : ${next.label.toLowerCase()}.',
                        style: detail,
                      ),
                    Text(
                      competition
                          ? 'Phases, blocs, Jour J.'
                          : 'Phases et blocs, semaine par semaine.',
                      style: detail,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: KSpacing.s8),
            Icon(
              Icons.chevron_right_rounded,
              size: KSize.icon,
              color: k.texte2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ma saison : échéance et Jour J, frise des phases, semaines du bloc,
/// figures, règles du programme. Vide : l'action qui donne une saison (R6).
class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final view = storeSeasonOverview();
      if (view == null) return _empty(context);
      final k = KTokens.of(context);
      final today = _today();
      final children = <Widget>[];
      if (view.eventName != null && view.daysToEvent != null) {
        final count = countdownParts(
          view.daysToEvent!,
          view.eventName!,
          view.eventDate!,
          today,
        );
        final e = view.event;
        final jourJ =
            e != null &&
            (e.kind == kc.EventKind.strengthCompetition ||
                e.kind == kc.EventKind.repsCompetition);
        children.add(
          KCard(
            key: const ValueKey('season-event'),
            padding: const EdgeInsets.all(KSpacing.s20),
            child: Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    view.eventName!,
                    style: KType.section.copyWith(color: k.texte2),
                  ),
                  KFitTitle(
                    _long(view.eventDate!, today).replaceAll('\u00a0', ' '),
                    style: KType.chiffre.copyWith(color: k.texte),
                  ),
                  Text(
                    count.$1 == 'Aujourd’hui' || count.$1 == 'Demain'
                        ? count.$1
                        : 'dans ${count.$1}'
                              '${view.daysToEvent! >= 14 ? ' (${view.daysToEvent}\u00a0jours)' : ''}',
                    style: KType.corps.copyWith(color: k.texte2),
                  ),
                  if (jourJ) ...[
                    const SizedBox(height: KSpacing.s16),
                    KTonalButton(
                      key: const ValueKey('season-event-day'),
                      expand: true,
                      icon: Icons.emoji_events_outlined,
                      label: e.kind == kc.EventKind.strengthCompetition
                          ? 'Jour J : tentatives'
                          : 'Jour J : rythme',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EventDayScreen(event: e),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      if (view.phases.isNotEmpty) {
        children.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KSectionTitle('Phases', top: 0),
              KTimeline(
                phases: [
                  for (final p in view.phases)
                    KPhase(
                      phaseTitle(p.code),
                      dates:
                          '${_short(p.start)} – ${_short(p.end)}'
                          '${p.eventName == null || p.eventName == view.eventName ? '' : ', ${p.eventName}'}',
                      length: '${p.weeks} semaine${p.weeks > 1 ? 's' : ''}',
                      state: p.current
                          ? KPhaseState.current
                          : p.past
                          ? KPhaseState.past
                          : KPhaseState.upcoming,
                    ),
                ],
              ),
            ],
          ),
        );
      }
      children.add(
        KMenuGroup(
          title: 'Bloc ${view.blockIndex + 1}, semaine par semaine',
          dividerIndent: KSpacing.s16,
          children: [for (final w in view.blockWeeks) _WeekRow(w)],
        ),
      );
      Widget lines(String title, List<String> items) => KMenuGroup(
        title: title,
        dividerIndent: KSpacing.s16,
        children: [
          for (final l in items)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpacing.s16,
                vertical: KSpacing.s12,
              ),
              child: Text(l, style: KType.corps.copyWith(color: k.texte)),
            ),
        ],
      );
      if (view.ladders.isNotEmpty) children.add(lines('Figures', view.ladders));
      if (view.rules.isNotEmpty) {
        children.add(lines('Règles de ton programme', view.rules));
      }
      return KPage.sub(
        key: const ValueKey('season-screen'),
        title: 'Ma saison',
        children: children,
      );
    },
  );

  Widget _empty(BuildContext context) {
    final canCreate = PlanStore(store).planCanCreate;
    final (String action, VoidCallback onAction) = store.athlete == null
        ? (
            'Créer mon profil',
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          )
        : canCreate
        ? ('Créer un nouveau programme', () => openPlanCreation(context))
        : ('Revenir à Mon programme', () => Navigator.of(context).maybePop());
    return KPage.sub(
      title: 'Ma saison',
      children: [
        KEmpty(
          key: const ValueKey('season-empty'),
          icon: Icons.flag_outlined,
          title: 'Pas de saison planifiée',
          message:
              'Ton programme n’a pas de saison planifiée : il est écrit bloc '
              'par bloc. Un programme créé avec Koach la calcule d’après tes '
              'échéances.',
          action: action,
          onAction: onAction,
        ),
      ],
    );
  }
}

/// Une semaine du bloc : numéro, nature (cette semaine en `encre`),
/// drapeau des semaines particulières.
class _WeekRow extends StatelessWidget {
  final SeasonWeekView w;
  const _WeekRow(this.w);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      label:
          'Semaine ${w.n}, ${w.label}'
          '${w.current ? ', cette semaine' : ''}'
          '${w.special ? ', semaine particulière' : ''}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KSize.target),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpacing.s16,
            vertical: KSpacing.s8,
          ),
          child: Row(
            children: [
              SizedBox(
                width: KSize.target,
                child: Text(
                  'S${w.n}',
                  style: KType.chiffrePetit.copyWith(
                    color: w.current ? k.encre : k.texte2,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${w.label}${w.current ? ' · cette semaine' : ''}',
                  style:
                      (w.special || w.current ? KType.corpsFort : KType.corps)
                          .copyWith(color: w.current ? k.encre : k.texte),
                ),
              ),
              if (w.special)
                Icon(
                  Icons.flag_outlined,
                  size: KSize.iconSmall,
                  color: k.texte2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
