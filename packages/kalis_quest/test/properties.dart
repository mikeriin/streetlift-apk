// Tests de propriétés : des journaux aléatoires (seedés) — assiduité,
// séances partielles, notes absentes, douleurs déclarées, triche par
// surentraînement, pauses, reprises, exercices inconnus, séances
// supprimées — donnés au moteur à des cadences variées, et, sur chacun, les
// garanties du contrat (`CONTRAT.md`, § Invariants) :
//
//  P1  le niveau global (prestige × 100 + niveau), l'XP total, le solde de
//      Krédits, la meilleure série, la meilleure valeur des attributs et
//      les rangs ne baissent jamais ; les registres rendus prolongent ceux
//      reçus sans en toucher une écriture ; une quête terminée le reste ;
//  P2  même suite d'appels, même résultat à l'octet près ;
//  P3  export puis import de l'état entre deux appels : même résultat ;
//  P4  garde-fous : XP d'effort d'une séance et d'une semaine bornés par
//      le programme ; aucune récompense pour une séance faite malgré une
//      douleur ; un jour de repos ou de pause ne propose que de la
//      récupération ; aucune quête ne demande plus que le programme ;
//  P5  entrées constantes, séances terminées le jour même : le résultat ne
//      dépend pas de la cadence des appels (chaque jour ou une seule fois
//      à la fin) ;
//  P6  les séances « reprise » ne changent rien ;
//  P7  sorties valides au sens du contrat, exercices cités au catalogue,
//      codes de raison du registre.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Nombre de fichiers de propriétés (un isolat chacun).
const int propertyFiles = 8;

/// Journaux par fichier : 8 × 1 280 = 10 240 journaux.
const int journalsPerFile = 1280;

/// Journaux par test.
const int journalsPerTest = 160;

/// Profils types des journaux aléatoires.
const List<String> propertyProfiles = <String>[
  'homme_25_musculation_debutant_3x60',
  'femme_45_musculation_salle_4x60',
  'street_streetlifting_4x90',
  'debutant_forme_generale_maison_2x30',
  'femme_30_street_workout_parc_3x45',
  'six_jours_musculation_avance_6x75',
];

/// Durée du programme préparé par profil, en semaines.
const int stageWeeks = 10;

final KalisQuest _engine = KalisQuest();

/// Un journal aléatoire et ce qu'il faut pour interroger le moteur.
final class RandomCase {
  /// Cas de graine [seed].
  RandomCase(this.seed) {
    final rng = SimRng(seed, 'cas');
    double u() => rng.next();
    final profileKey =
        propertyProfiles[(u() * propertyProfiles.length).floor()];
    weeks = 3 + (u() * (stageWeeks - 2)).floor();
    final archetype = Archetype(
      key: 'aleatoire',
      profileKey: profileKey,
      level: (u() * 4).floor(),
      adherence: 0.4 + 0.6 * u(),
      note: '',
      fullRate: 0.5 + 0.5 * u(),
      ratingSkip: u() < 0.5 ? 0 : 0.4 * u(),
      claimRate: u(),
      mobilityRate: 0.5 * u(),
      painRate: u() < 0.5 ? 0 : 0.3 * u(),
      throughRate: u(),
      cheat: u() < 0.2,
      vacations: u() < 0.3
          ? <YearlySpan>[YearlySpan((u() * 8).floor(), 3 + (u() * 12).floor())]
          : const <YearlySpan>[],
      illnesses: u() < 0.2
          ? <YearlySpan>[YearlySpan((u() * 8).floor(), 2 + (u() * 9).floor())]
          : const <YearlySpan>[],
      stops: u() < 0.2
          ? <YearlySpan>[YearlySpan((u() * 8).floor(), 7 + (u() * 14).floor())]
          : const <YearlySpan>[],
    );
    stage = stageOf(archetype, stageWeeks);
    final log = generateLog(archetype, stage, seed, weeks);
    claims = log.claims;
    breaks = log.breaks;
    final stripPlanned = u() < 0.3;
    final unknown = u() < 0.05;
    for (final s in log.sessions) {
      var session = s;
      if (stripPlanned || u() < 0.1) {
        session = session.copyWith(plannedWorkSets: null);
      }
      if (u() < 0.08) {
        session = session.copyWith(completed: false);
      }
      if (u() < 0.05) {
        session = session.copyWith(programRef: null);
      }
      if (unknown && u() < 0.3) {
        session = session.copyWith(
          sets: <SetRecord>[
            ...session.sets,
            SetRecord(
              exerciseId: 'x-inconnu-$seed',
              exerciseOrder: 99,
              setIndex: 0,
              kind: SetKind.work,
              reps: 5,
              flames: 7,
              success: true,
              excluded: false,
            ),
          ],
        );
      }
      sessions.add(session);
      if (u() < 0.06) {
        resumes.add(
          session.copyWith(id: 'reprise-${session.id}', resume: true),
        );
      }
    }
    start = stage.startDay;
    end = start + 7 * weeks - 1;
    cadence = seed % 4;
    extra = (seed ~/ 4) % 4;
    // Jours d'appel du moteur.
    switch (cadence) {
      case 0:
        for (var d = start; d <= end; d++) {
          days.add(d);
        }
      case 1:
        for (var d = start + 6; d <= end; d += 7) {
          days.add(d);
        }
      case 2:
        for (
          var d = start + (u() * 5).floor();
          d < end;
          d += 1 + (u() * 10).floor()
        ) {
          days.add(d);
        }
        days.add(end);
      default:
        days.add(end);
    }
    // Une séance supprimée en cours de route, une fois sur quatre.
    if (sessions.length > 3 && u() < 0.25) {
      deleted = sessions[(u() * (sessions.length - 1)).floor()].id;
      deletedFrom = days[(u() * days.length).floor()];
    }
    for (final b in stage.blocks) {
      if (b.pass1.days.length > maxPerWeek) {
        maxPerWeek = b.pass1.days.length;
      }
      for (final d in b.pass1.days) {
        trainingWeekdays.add(d.weekday);
      }
    }
    for (final d in stage.profile.availability) {
      trainingWeekdays.add(d.weekday);
    }
    if (stage.profile.availability.length > maxPerWeek) {
      maxPerWeek = stage.profile.availability.length;
    }
  }

  /// Graine.
  final int seed;

  /// Programme et profil.
  late final SimStage stage;

  /// Durée, en semaines.
  late final int weeks;

  /// Séances (hors reprises).
  final List<SessionRecord> sessions = <SessionRecord>[];

  /// Séances « reprise » à intercaler.
  final List<SessionRecord> resumes = <SessionRecord>[];

  /// Déclarations.
  late final List<QuestClaim> claims;

  /// Pauses.
  late final List<TrainingBreak> breaks;

  /// Premier et dernier jour.
  late final int start;

  /// Voir [start].
  late final int end;

  /// Cadence des appels (0 chaque jour, 1 chaque dimanche, 2 irrégulière,
  /// 3 une seule fois).
  late final int cadence;

  /// Vérification supplémentaire tirée (0 à 3).
  late final int extra;

  /// Jours d'appel.
  final List<int> days = <int>[];

  /// Séance supprimée à partir du jour [deletedFrom].
  String? deleted;

  /// Voir [deleted].
  int deletedFrom = 0;

  /// Plus grand nombre de séances prévues par semaine.
  int maxPerWeek = 0;

  /// Jours ISO où une séance peut être prévue.
  final Set<int> trainingWeekdays = <int>{};

  /// Journal vu le jour [today].
  TrainingLog logAt(
    int today, {
    bool withResumes = true,
    bool deletions = true,
  }) {
    final all =
        <SessionRecord>[
          for (final s in sessions)
            if (s.date.dayNumber <= today &&
                !(deletions && s.id == deleted && today >= deletedFrom))
              // Régime constant (P5) : ni suppression ni séance laissée
              // inachevée (celle-ci est réglée le lendemain, après les
              // quêtes du jour : l'ordre des écritures en dépend).
              deletions || s.completed ? s : s.copyWith(completed: true),
          if (withResumes)
            for (final s in resumes)
              if (s.date.dayNumber <= today) s,
        ]..sort((a, b) {
          final c = a.date.compareTo(b.date);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    return TrainingLog(sessions: all, breaks: breaks);
  }

  /// Entrée du jour [today].
  QuestInput inputAt(
    int today,
    QuestState state, {
    bool withBlock = true,
    bool withResumes = true,
    bool deletions = true,
  }) {
    return QuestInput(
      profile: stage.profile,
      log: logAt(today, withResumes: withResumes, deletions: deletions),
      block: withBlock ? stage.blockOn(today) : null,
      state: state,
      today: CivilDate.fromDayNumber(today),
      seed: seed,
      claims: <QuestClaim>[
        for (final c in claims)
          if (c.date.dayNumber <= today) c,
      ],
    );
  }

  /// État au démarrage du registre (premier jour, journal vide).
  QuestState started({bool withBlock = true}) => _engine
      .evaluate(
        stage.catalog,
        QuestInput(
          profile: stage.profile,
          log: TrainingLog(sessions: const <SessionRecord>[], breaks: breaks),
          block: withBlock ? stage.blockOn(start) : null,
          state: emptyState,
          today: CivilDate.fromDayNumber(start),
          seed: seed,
        ),
      )
      .state;
}

Map<String, Object?> _comparable(QuestState s) {
  final data = Map<String, Object?>.of(s.data)..remove('attrBest');
  return <String, Object?>{
    'xp': <Object?>[for (final e in s.xp) e.toJson()],
    'kredits': <Object?>[for (final e in s.kredits) e.toJson()],
    'quests': <Object?>[for (final q in s.quests) q.toJson()],
    'data': data,
  };
}

void _checkStep(
  RandomCase c,
  QuestOutcome? before,
  QuestOutcome after,
  int day,
) {
  final why = 'graine ${c.seed}, jour ${day - c.start}';
  final p = _engine.params;
  // P7
  expect(after.validate(), isEmpty, reason: why);
  final ids = <String>{};
  after.collectExerciseIds(ids);
  expect(c.stage.catalog.checkExerciseIds(ids), isEmpty, reason: why);
  for (final code in reasonCodesOf(after)) {
    expect(code.startsWith('quest.'), isTrue, reason: '$why $code');
  }
  expect(after.attributes, hasLength(6), reason: why);
  for (final a in after.attributes) {
    expect(a.value, inInclusiveRange(1, 100), reason: why);
    expect(a.best!, greaterThanOrEqualTo(a.value), reason: why);
  }
  var total = 0;
  for (final e in after.state.xp) {
    total += e.amount;
  }
  expect(after.level.totalXp, total, reason: why);
  var balance = 0;
  for (final e in after.state.kredits) {
    balance += e.amount;
  }
  expect(after.kreditBalance, balance, reason: why);

  // P4
  final effortByWeek = <String, int>{};
  final paidByWeek = <String, int>{};
  for (final e in after.state.xp) {
    if (e.source != XpSource.effort) {
      continue;
    }
    expect(
      e.amount,
      lessThanOrEqualTo(p.sessionXp + p.comboBonusCap),
      reason: why,
    );
    final pain = e.reasons.any((r) => r.code == ReasonCodes.questNoRewardPain);
    if (pain) {
      expect(e.amount, 0, reason: why);
    }
    final ref = e.refId!;
    effortByWeek.update(ref, (n) => n + e.amount, ifAbsent: () => e.amount);
    if (e.reasons.first.code == ReasonCodes.questXpEffort) {
      paidByWeek.update(ref, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  for (final entry in effortByWeek.entries) {
    expect(
      entry.value,
      lessThanOrEqualTo(c.maxPerWeek * (p.sessionXp + p.comboBonusCap)),
      reason: '$why ${entry.key}',
    );
    expect(
      paidByWeek[entry.key] ?? 0,
      lessThanOrEqualTo(c.maxPerWeek),
      reason: '$why ${entry.key}',
    );
  }
  // Séances faites malgré une douleur : ni quête ni coffre ni record ne
  // portent leur identifiant.
  final painful = <String>{
    for (final e in after.state.xp)
      if (e.source == XpSource.effort &&
          e.reasons.any((r) => r.code == ReasonCodes.questNoRewardPain))
        e.sessionId!,
  };
  for (final e in after.state.xp) {
    if (e.source != XpSource.effort && e.sessionId != null) {
      expect(painful.contains(e.sessionId), isFalse, reason: why);
    }
  }
  for (final k in after.state.kredits) {
    if (k.source == KreditSource.chest) {
      expect(painful.contains(k.refId!.split('|').last), isFalse, reason: why);
    }
  }
  for (final q in after.state.quests) {
    expect(q.target, greaterThan(0), reason: '$why ${q.id}');
    expect(q.rewardXp, lessThanOrEqualTo(p.chapterXp), reason: why);
    if (q.kind == QuestKind.daily) {
      final d = q.startsOn;
      var paused = false;
      for (final b in c.breaks) {
        if (d >= b.startDate && (b.endDate == null || d <= b.endDate!)) {
          paused = true;
        }
      }
      final rest = paused || !c.trainingWeekdays.contains(d.weekday);
      if (rest) {
        expect(
          QuestTemplates.recovery,
          contains(q.template),
          reason: '$why ${q.id}',
        );
      }
    }
    if (q.template == QuestTemplates.weeklySessions ||
        q.template == QuestTemplates.koachFullSessions) {
      expect(q.target, lessThanOrEqualTo(c.maxPerWeek), reason: why);
    }
  }

  // P1
  if (before != null) {
    expect(
      LevelCurve.ordinal(after.level),
      greaterThanOrEqualTo(LevelCurve.ordinal(before.level)),
      reason: why,
    );
    expect(
      after.level.totalXp,
      greaterThanOrEqualTo(before.level.totalXp),
      reason: why,
    );
    expect(
      after.kreditBalance,
      greaterThanOrEqualTo(before.kreditBalance),
      reason: why,
    );
    expect(
      after.state.data['bestStreak']! as int,
      greaterThanOrEqualTo(before.state.data['bestStreak']! as int),
      reason: why,
    );
    expect(after.state.xp.length, greaterThanOrEqualTo(before.state.xp.length));
    for (var i = 0; i < before.state.xp.length; i++) {
      expect(
        identical(after.state.xp[i], before.state.xp[i]),
        isTrue,
        reason: why,
      );
    }
    expect(
      after.state.kredits.length,
      greaterThanOrEqualTo(before.state.kredits.length),
    );
    for (var i = 0; i < before.state.kredits.length; i++) {
      expect(
        identical(after.state.kredits[i], before.state.kredits[i]),
        isTrue,
        reason: why,
      );
    }
    for (var i = 0; i < 6; i++) {
      expect(
        after.attributes[i].best!,
        greaterThanOrEqualTo(before.attributes[i].best!),
        reason: why,
      );
    }
    final ranks = <String, int>{
      for (final r in before.ranks) r.exerciseId: r.tier.index,
    };
    for (final r in after.ranks) {
      expect(
        r.tier.index,
        greaterThanOrEqualTo(ranks[r.exerciseId]!),
        reason: why,
      );
    }
    final done = <String>{
      for (final q in before.state.quests)
        if (q.status == QuestStatus.completed) q.id,
    };
    for (final q in after.state.quests) {
      if (done.contains(q.id)) {
        expect(q.status, QuestStatus.completed, reason: '$why ${q.id}');
      }
    }
  }
}

/// Déroule le cas [c] à sa cadence ; rend le dernier résultat.
QuestOutcome _play(
  RandomCase c, {
  bool check = false,
  bool reimportState = false,
  bool withResumes = true,
  bool withBlock = true,
  bool deletions = true,
  List<int>? days,
}) {
  var state = c.started(withBlock: withBlock);
  QuestOutcome? previous;
  for (final day in days ?? c.days) {
    final outcome = _engine.evaluate(
      c.stage.catalog,
      c.inputAt(
        day,
        reimportState ? reimport(state) : state,
        withBlock: withBlock,
        withResumes: withResumes,
        deletions: deletions,
      ),
    );
    if (check) {
      _checkStep(c, previous, outcome, day);
    }
    previous = outcome;
    state = outcome.state;
  }
  return previous!;
}

/// Vérifie le journal aléatoire de graine [seed].
void checkCase(int seed) {
  final c = RandomCase(seed);
  final why = 'graine $seed';
  final a = _play(c, check: true);
  final text = outcomeText(a);
  switch (c.extra) {
    case 0:
      // P2
      expect(outcomeText(_play(c)), text, reason: why);
    case 1:
      // P3
      expect(outcomeText(_play(c, reimportState: true)), text, reason: why);
    case 2:
      // P6
      expect(outcomeText(_play(c, withResumes: false)), text, reason: why);
    default:
      // État relu : les registres passent l'export et l'import sans perte.
      expect(stateText(reimport(a.state)), stateText(a.state), reason: why);
  }
  // P5 : sans bloc ni suppression, chaque jour ou une seule fois.
  if (seed % 3 == 0) {
    final short = c.weeks <= 6;
    final often = _play(
      c,
      withBlock: false,
      deletions: false,
      days: <int>[
        for (var d = c.start; d <= c.end; d += short ? 1 : 7) d,
        if (!short) c.end,
      ],
    );
    final once = _play(
      c,
      withBlock: false,
      deletions: false,
      days: <int>[c.end],
    );
    expect(
      jsonEncode(_comparable(once.state)),
      jsonEncode(_comparable(often.state)),
      reason: why,
    );
    expect(once.level, often.level, reason: why);
    expect(once.kreditBalance, often.kreditBalance, reason: why);
  }
}

/// Tests du fichier [file] (0 à [propertyFiles] − 1).
void propertyTests(int file) {
  group('journaux aléatoires', () {
    final first = file * journalsPerFile;
    for (
      var from = first;
      from < first + journalsPerFile;
      from += journalsPerTest
    ) {
      test('journaux $from à ${from + journalsPerTest - 1}', () {
        for (var seed = from; seed < from + journalsPerTest; seed++) {
          checkCase(seed);
        }
      });
    }
  });
}
