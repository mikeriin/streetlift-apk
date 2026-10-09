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

import '../app_theme.dart';
import '../koach/koach_bubble.dart' show KoachSays;
import '../store.dart';
import '../ui.dart';
import 'coach_texts.dart';
import 'event_day_screen.dart';
import 'plan_program.dart';
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

/// Carte « Ta saison » de Réglages › Mon programme.
class SeasonCard extends StatelessWidget {
  final SeasonOverview view;
  const SeasonCard({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final dim = Theme.of(context).textTheme.bodySmall;
    final cur = view.currentPhase;
    final next = view.nextSpecial;
    return KCard(
      key: const ValueKey('program-season'),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SeasonScreen())),
      child: KoachSays(
        pose: KoachPose.direction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ta saison', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (view.eventName != null && view.daysToEvent != null)
              Text(
                '${view.eventName} ${countdownText(view.daysToEvent!)}'
                ' (${_short(view.eventDate!)}).',
                key: const ValueKey('season-countdown'),
              ),
            if (cur != null)
              Text(
                _sentence(
                  'Phase en cours : ${phaseLabel(cur.code)}, jusqu’au '
                  '${_short(cur.end)}',
                ),
              ),
            if (next != null)
              Text(
                next.current
                    ? 'Cette semaine : ${next.label.toLowerCase()}.'
                    : 'Semaine ${next.n} : ${next.label.toLowerCase()}.',
                style: dim,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('season-open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SeasonScreen()),
                ),
                child: const Text('Voir la saison'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran de la saison : phases, compte à rebours, semaines du bloc,
/// règles du programme, figures.
class SeasonScreen extends StatelessWidget {
  const SeasonScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final view = storeSeasonOverview();
      final t = Theme.of(context).textTheme;
      return KScreen(
        appBar: AppBar(title: const Text('MA SAISON')),
        body: view == null
            ? const KList(
                children: [
                  Text(
                    'Ton programme n’a pas de saison planifiée : il est '
                    'écrit bloc par bloc.',
                  ),
                ],
              )
            : KList(
                key: const ValueKey('season-screen'),
                children: [
                  if (view.eventName != null && view.daysToEvent != null)
                    KCard(
                      accent: SL.accent,
                      child: Semantics(
                        container: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(view.eventName!, style: t.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${_short(view.eventDate!)} · '
                              '${countdownText(view.daysToEvent!)}',
                              style: t.titleSmall?.copyWith(color: SL.accent),
                            ),
                            if (view.event case final e?
                                when e.kind ==
                                        kc.EventKind.strengthCompetition ||
                                    e.kind == kc.EventKind.repsCompetition)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  key: const ValueKey('season-event-day'),
                                  icon: const Icon(Icons.emoji_events_outlined),
                                  label: Text(
                                    e.kind == kc.EventKind.strengthCompetition
                                        ? 'Jour J : tentatives'
                                        : 'Jour J : rythme',
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => EventDayScreen(event: e),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (view.phases.isNotEmpty) ...[
                    const KSection('Phases', topPadding: 0),
                    KCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [for (final p in view.phases) _PhaseRow(p)],
                      ),
                    ),
                  ],
                  KSection('Bloc ${view.blockIndex + 1}, semaine par semaine'),
                  KCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [for (final w in view.blockWeeks) _WeekRow(w)],
                    ),
                  ),
                  if (view.ladders.isNotEmpty) ...[
                    const KSection('Figures'),
                    for (final l in view.ladders)
                      KCard(child: Text(l, style: t.bodyMedium)),
                  ],
                  if (view.rules.isNotEmpty) ...[
                    const KSection('Règles de ton programme'),
                    for (final r in view.rules)
                      KCard(child: Text(r, style: t.bodyMedium)),
                  ],
                ],
              ),
      );
    },
  );
}

class _PhaseRow extends StatelessWidget {
  final SeasonPhaseView p;
  const _PhaseRow(this.p);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = p.current ? SL.accent : (p.past ? SL.dim : SL.text);
    return Semantics(
      label: p.current ? 'Phase en cours' : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              p.current
                  ? Icons.play_circle_fill
                  : p.past
                  ? Icons.check_circle_outline
                  : Icons.circle_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${phaseTitle(p.code)}${p.current ? ' · en cours' : ''}',
                    style: t.titleSmall?.copyWith(color: color),
                  ),
                  Text(
                    '${_short(p.start)} → ${_short(p.end)} · ${p.weeks} '
                    'semaine${p.weeks > 1 ? 's' : ''}'
                    '${p.eventName == null ? '' : ' · ${p.eventName}'}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final SeasonWeekView w;
  const _WeekRow(this.w);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              'S${w.n}',
              style: t.titleSmall?.copyWith(
                color: w.current ? SL.accent : SL.dim,
                fontWeight: w.current ? FontWeight.w700 : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${w.label}${w.current ? ' · cette semaine' : ''}',
              style: t.bodyMedium?.copyWith(
                fontWeight: w.special || w.current ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (w.special)
            Icon(
              Icons.flag_outlined,
              size: 18,
              color: SL.dim,
              semanticLabel: 'semaine particulière',
            ),
        ],
      ),
    );
  }
}
