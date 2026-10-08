// G10 (dev6.7.0, D5.1, D5.6, D5.7, D5.11) — évolution du programme : chaque
// type de proposition de kalis_adapt dans les deux modes (assisté : appliqué
// et annoncé ; libre : accepter, refuser, plus tard), annulation jusqu'à la
// séance concernée, refus transmis au moteur, propositions périmées
// retirées, programme affiché et bloc servi au moteur avec les couches,
// semaines passées intactes, sauvegarde (section `planEvolution`), fin de
// bloc par la revue G7 (nouveaux exercices seulement), déblocage visible,
// simulateur de séances déterministe (même graine = même session).
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/plan/evolution_texts.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/store.dart';

/// Profil d'exemple dans le mode [mode], puis programme créé et validé.
void _program(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
  final c = PlanStore(app).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(app).applyPlanCreation(c);
}

/// Bloc servi au moteur pour la semaine S[week] (première journée).
AdaptPlace _place(AppStore app, int week) {
  for (var j = 1; j <= 7; j++) {
    final p = app.adaptPlaceOf(week, j);
    if (p != null) return p;
  }
  throw StateError('semaine $week sans séance');
}

/// Proposition de volume : une série de plus sur le premier exercice
/// chargé de la semaine [weekIndex] du bloc.
kc.Proposal _volume(
  AdaptPlace place,
  int weekIndex, {
  String day = '2026-10-01',
}) {
  final week = place.block.pass2.weeks[weekIndex];
  final d = week.days.first;
  final item = d.items.firstWhere((i) => i.setTargets == null);
  return kc.Proposal(
    id: 'volume:${item.slotId}@$weekIndex',
    kind: kc.ProposalKind.volume,
    scope: kc.ProposalScope.exercise,
    createdOn: kc.CivilDate.parse(day),
    confidence: .74,
    unlockLevel: kc.UnlockLevel.volume,
    autoApplicable: true,
    exerciseId: item.exerciseId,
    diff: kc.PlanDiff(
      changes: [
        kc.PlanChange(
          kind: kc.ChangeKind.prescriptionChanged,
          dayIndex: d.dayIndex,
          weekIndex: weekIndex,
          slotId: item.slotId,
          fromPrescription: item,
          toPrescription: item.copyWith(sets: item.sets + 1),
          reasons: [
            const kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
          ],
        ),
      ],
    ),
    reasons: [
      const kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
      const kc.Reason(
        code: 'adapt.volume_response',
        params: {'muscle': 'lats', 'weeklySets': 10.0},
      ),
    ],
  );
}

/// Décharge anticipée de la semaine [weekIndex] : séries × 0,6, +1 RIR.
kc.Proposal _deload(AdaptPlace place, int weekIndex) {
  final week = place.block.pass2.weeks[weekIndex];
  final changes = <kc.PlanChange>[
    for (final d in week.days)
      for (final it in d.items)
        if (it.targetFlames != null && it.setTargets == null)
          kc.PlanChange(
            kind: kc.ChangeKind.prescriptionChanged,
            dayIndex: d.dayIndex,
            weekIndex: weekIndex,
            slotId: it.slotId,
            fromPrescription: it,
            toPrescription: it.copyWith(
              sets: (it.sets * .6).round().clamp(1, 20),
              targetFlames: (it.targetFlames! - 2).clamp(1, 10),
            ),
            reasons: const [],
          ),
  ];
  return kc.Proposal(
    id: 'deload:${place.blockId}@$weekIndex',
    kind: kc.ProposalKind.deload,
    scope: kc.ProposalScope.week,
    createdOn: kc.CivilDate(2026, 10, 1),
    confidence: .62,
    unlockLevel: kc.UnlockLevel.volume,
    autoApplicable: true,
    diff: kc.PlanDiff(changes: changes),
    reasons: [
      kc.Reason(code: 'adapt.deload', params: {'weekIndex': weekIndex}),
      const kc.Reason(code: 'adapt.fatigue_high', params: {'readiness': .35}),
    ],
  );
}

/// Restructuration demandée au vrai moteur statique (D5.1) : échange d'un
/// exercice (tous les autres emplacements verrouillés), séance ou bloc.
kc.Proposal _restructure(
  AppStore app,
  AdaptPlace place,
  kc.ProposalKind kind,
  int fromWeek,
) {
  final pass1 = place.block.pass1;
  final scope = switch (kind) {
    kc.ProposalKind.sessionRestructure => kc.RestructureScope.session,
    kc.ProposalKind.blockRestructure => kc.RestructureScope.block,
    _ => kc.RestructureScope.block,
  };
  final free =
      kind == kc.ProposalKind.exerciseSwap ||
          kind == kc.ProposalKind.painSparing
      ? {
          for (final s in pass1.days.first.slots)
            if (s.role != kc.SlotRole.main) s.slotId,
        }.take(1).toSet()
      : null;
  final r = kp.KalisPlan().restructure(
    app.content.catalog!,
    kc.RestructureRequest(
      profile: app.adaptProfile!,
      seed: pass1.seed,
      today: civilOf(app.storeClock()),
      current: place.block,
      scope: scope,
      dayIndex: scope == kc.RestructureScope.session
          ? pass1.days.first.dayIndex
          : null,
      fromWeekIndex: fromWeek,
      reasons: [
        const kc.Reason(
          code: 'adapt.time_short',
          params: {'minutesAvailable': 30, 'minutesPlanned': 60},
        ),
      ],
      locks: [
        if (free != null)
          for (final d in pass1.days)
            for (final s in d.slots)
              if (!free.contains(s.slotId))
                kc.PlanLock(
                  kind: kc.LockKind.keepSlot,
                  slotId: s.slotId,
                  exerciseId: s.exerciseId,
                ),
        if (free != null)
          for (final s in free)
            kc.PlanLock(
              kind: kc.LockKind.excludeExercise,
              exerciseId: pass1.days.first.slots
                  .firstWhere((x) => x.slotId == s)
                  .exerciseId,
            ),
      ],
    ),
  );
  return kc.Proposal(
    id: '${kind.code}:${place.blockId}@$fromWeek',
    kind: kind,
    scope: kind == kc.ProposalKind.blockRestructure
        ? kc.ProposalScope.block
        : kc.ProposalScope.session,
    createdOn: civilOf(app.storeClock()),
    confidence: .9,
    unlockLevel: switch (kind) {
      kc.ProposalKind.sessionRestructure => kc.UnlockLevel.sessionRestructure,
      kc.ProposalKind.blockRestructure => kc.UnlockLevel.blockRestructure,
      kc.ProposalKind.painSparing => kc.UnlockLevel.loadsReps,
      _ => kc.UnlockLevel.exerciseSwap,
    },
    autoApplicable: true,
    diff: r.diff,
    block: r.block,
    reasons: [
      if (kind == kc.ProposalKind.exerciseSwap)
        kc.Reason(
          code: 'adapt.plateau',
          params: {
            'exerciseId': pass1.days.first.slots.first.exerciseId,
            'weeks': 4,
          },
        ),
      if (kind == kc.ProposalKind.painSparing)
        const kc.Reason(
          code: 'adapt.pain_reported',
          params: {'zone': 'shoulder', 'intensity': 5},
        ),
      if (kind == kc.ProposalKind.sessionRestructure)
        const kc.Reason(
          code: 'adapt.time_short',
          params: {'minutesAvailable': 30, 'minutesPlanned': 60},
        ),
      if (kind == kc.ProposalKind.blockRestructure)
        const kc.Reason(
          code: 'adapt.missed_sessions',
          params: {'missed': 5, 'planned': 9},
        ),
    ],
  );
}

/// Exercices affichés de la semaine S[week] (id, nom, séries).
List<String> _shown(AppStore app, int week) => [
  for (final d in app.program.week(week).days)
    for (final e in d.exercises) '${e.id}|${e.name}|${app.setsLabel(e)}',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('modèle', () {
    test('section planEvolution : relue à l’identique, contrôlée ; suites '
        'données au format du moteur ; bloc retiré d’une proposition '
        'refusée', () {
      final p = kc.Proposal(
        id: 'deload:b@2',
        kind: kc.ProposalKind.deload,
        scope: kc.ProposalScope.week,
        createdOn: kc.CivilDate(2026, 10, 1),
        confidence: .6,
        unlockLevel: kc.UnlockLevel.volume,
        autoApplicable: true,
        reasons: const [],
      );
      final evo = PlanEvolution(
        entries: [
          EvolutionEntry(
            proposal: p,
            blockId: 'b',
            status: EvoStatus.refused,
            decidedOn: '2026-10-02',
            mode: 'free',
          ),
          EvolutionEntry(
            proposal: p.copyWith(id: 'volume:x@2'),
            blockId: 'b',
            status: EvoStatus.applied,
            decidedOn: '2026-10-01',
            mode: 'assisted',
          ),
          EvolutionEntry(
            proposal: p.copyWith(id: 'swap:y@3'),
            blockId: 'b',
            status: EvoStatus.pending,
            mode: 'free',
            laterUntil: '2026-10-03',
          ),
        ],
      );
      final json = jsonDecode(jsonEncode(evo.toJson()));
      final back = PlanEvolution.fromJson(json);
      expect(jsonEncode(back.toJson()), jsonEncode(evo.toJson()));
      expect(back.entries.first.fromWeek, 2);
      expect(
        [for (final d in back.decisions) d.toJson()],
        [
          {
            'proposalId': 'deload:b@2',
            'date': '2026-10-02',
            'status': 'refused',
          },
          {
            'proposalId': 'volume:x@2',
            'date': '2026-10-01',
            'status': 'auto_applied',
          },
        ],
      );
      expect(back.inEffect('b').map((e) => e.id), ['volume:x@2']);
      // Contrôle strict : suite inconnue, date invalide, doublon.
      for (final bad in [
        {'v': 2, 'entries': []},
        {
          'v': 1,
          'entries': [
            {...(json['entries'] as List).first as Map, 'status': 'maybe'},
          ],
        },
        {
          'v': 1,
          'entries': [
            {...(json['entries'] as List).first as Map, 'decidedOn': '02/10'},
          ],
        },
        {
          'v': 1,
          'entries': [
            (json['entries'] as List).first,
            (json['entries'] as List).first,
          ],
        },
      ]) {
        expect(
          () => PlanEvolution.fromJson(bad),
          throwsFormatException,
          reason: jsonEncode(bad),
        );
      }
    });

    test('déblocage : textes de Koach (D5.7)', () {
      expect(
        unlockNextText(next: kc.UnlockLevel.volume, weeks: 2, blocks: 0),
        'Dans 2 semaines de séances, je pourrai ajuster ton volume et '
        'alléger une semaine.',
      );
      expect(
        unlockNextText(
          next: kc.UnlockLevel.sessionRestructure,
          weeks: 0,
          blocks: 1,
        ),
        'Encore un bloc terminé, et je pourrai réorganiser une séance.',
      );
      expect(unlockNextText(next: null, weeks: 0, blocks: 0), isNull);
      expect(confidenceWords(.9), 'Je suis très sûr de moi (90 %).');
      expect(confidenceWords(.4), 'Je suis encore peu sûr de moi (40 %).');
    });
  });

  group('magasin', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 1, 9);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 1, 9);
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
      for (final o in others) {
        o.dispose();
      }
      others.clear();
    });

    Future<AppStore> relaunch() async {
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      return next;
    }

    test('mode assisté : volume appliqué d’office, annoncé, programme '
        'affiché et bloc du moteur à jour à partir de la semaine visée ; '
        'semaines d’avant intactes ; annulation jusqu’à la séance '
        'concernée', () async {
      _program(app, kc.GuidanceMode.assisted);
      final place = _place(app, 1);
      final w1 = _shown(app, 1);
      final w2 = _shown(app, 2);
      final p = _volume(place, 1);
      expect(app.evolutionReceive(place, [p]), isTrue);
      final e = app.planEvolution.entries.single;
      expect(e.status, EvoStatus.applied);
      expect(e.decidedOn, '2026-10-01');
      expect(app.evolutionAnnounced.single.id, p.id);
      expect(app.evolutionPending, isEmpty);
      // Semaine 1 inchangée ; semaine 2 : une série de plus.
      expect(_shown(app, 1), w1);
      final after = _shown(app, 2);
      expect(after, isNot(w2));
      final slot = p.diff!.changes.single.slotId!;
      final served = app.adaptPlaceOf(2, 1) ?? _place(app, 2);
      final it = served.block.pass2.weeks[1].days
          .expand((d) => d.items)
          .firstWhere((x) => x.slotId == slot);
      expect(it.sets, p.diff!.changes.single.toPrescription!.sets);
      // Blocs enregistrés jamais réécrits.
      expect(
        app.planProgram!.blocks.single.block.pass2.weeks[1].days
            .expand((d) => d.items)
            .firstWhere((x) => x.slotId == slot)
            .sets,
        p.diff!.changes.single.fromPrescription!.sets,
      );
      // Rien n'est reproposé : décision transmise au moteur.
      expect(
        app.planEvolution.decisions.single.status,
        kc.ProposalStatus.autoApplied,
      );
      // Annulation possible tant qu'aucune séance de la semaine 2 n'a
      // commencé.
      expect(app.evolutionCanUndo(e), isTrue);
      expect(app.evolutionUndo(e), isTrue);
      expect(app.planEvolution.entries.single.status, EvoStatus.undone);
      expect(_shown(app, 2), w2);
      expect(
        app.planEvolution.decisions.single.status,
        kc.ProposalStatus.undone,
      );
    });

    test('annulation refusée une fois la séance concernée commencée, et '
        'seulement pour le dernier changement du bloc', () async {
      _program(app, kc.GuidanceMode.assisted);
      final place = _place(app, 1);
      app.evolutionReceive(place, [_volume(place, 1)]);
      final first = app.planEvolution.entries.single;
      app.evolutionReceive(_place(app, 1), [
        _volume(place, 1),
        _deload(_place(app, 1), 2),
      ]);
      expect(app.planEvolution.entries, hasLength(2));
      // Le premier n'est plus le dernier de son bloc.
      expect(app.evolutionCanUndo(app.planEvolution.entries.first), isFalse);
      final deload = app.planEvolution.entries.last;
      expect(app.evolutionCanUndo(deload), isTrue);
      // Une séance de la semaine 3 commencée : trop tard.
      final w3 = app.program.week(3);
      final d = w3.days.firstWhere((x) => x.exercises.isNotEmpty);
      final log = app.exLog(3, d.j, d.exercises.first);
      log.sets.first
        ..reps = '8'
        ..done = true;
      expect(app.evolutionCanUndo(deload), isFalse);
      expect(app.evolutionUndo(deload), isFalse);
      expect(first.id, startsWith('volume:'));
    });

    test('mode libre : rien n’est appliqué sans accord ; Accepter, Refuser '
        '(transmis au moteur), Plus tard (le lendemain)', () async {
      _program(app, kc.GuidanceMode.free);
      final place = _place(app, 1);
      final w2 = _shown(app, 2);
      final v = _volume(place, 1);
      final dl = _deload(place, 2);
      app.evolutionReceive(place, [v, dl]);
      expect(
        [for (final e in app.planEvolution.entries) e.status],
        [EvoStatus.pending, EvoStatus.pending],
      );
      expect(_shown(app, 2), w2);
      expect(app.planEvolution.decisions, isEmpty);
      // Plus tard : cachée jusqu'au lendemain.
      app.evolutionLater(app.planEvolution.entries.last);
      expect(app.evolutionPending.map((e) => e.id), [v.id]);
      clock = clock.add(const Duration(days: 1));
      expect(app.evolutionPending.map((e) => e.id), [v.id, dl.id]);
      clock = clock.subtract(const Duration(days: 1));
      // Accepter : appliqué.
      app.evolutionAccept(app.planEvolution.entries.first);
      // Une proposition acceptée passe en dernier (ordre des couches).
      expect(app.planEvolution.entries.last.id, v.id);
      expect(app.planEvolution.entries.last.status, EvoStatus.accepted);
      expect(_shown(app, 2), isNot(w2));
      // Refuser : transmis au moteur (ne repropose pas avant son délai).
      app.evolutionRefuse(app.planEvolution.entries.first);
      expect(app.planEvolution.entries.first.status, EvoStatus.refused);
      final decisions = {
        for (final d in app.planEvolution.decisions) d.proposalId: d.status,
      };
      expect(decisions, {
        v.id: kc.ProposalStatus.accepted,
        dl.id: kc.ProposalStatus.refused,
      });
      // Le bloc d'une proposition refusée n'est pas gardé.
      expect(app.planEvolution.entries.first.proposal.block, isNull);
      // La revue suivante transmet les décisions au moteur.
      clock = DateTime(2026, 10, 2, 9);
      app.evolutionRefresh(force: true);
      final input = app.lastEvolutionReview?.input;
      expect(input, isNotNull);
      expect({for (final d in input!.decisions!) d.proposalId}, {v.id, dl.id});
    });

    test('proposition en attente que le moteur ne fait plus : retirée ; '
        'passage au mode assisté : appliquée', () async {
      _program(app, kc.GuidanceMode.free);
      final place = _place(app, 1);
      final v = _volume(place, 1);
      final dl = _deload(place, 2);
      app.evolutionReceive(place, [v, dl]);
      app.evolutionReceive(place, [dl]);
      expect(app.planEvolution.entries.map((e) => e.id), [dl.id]);
      // Même proposition reçue de nouveau : rien ne change.
      expect(app.evolutionReceive(place, [dl]), isFalse);
      app.setGuidanceMode('assisted');
      expect(app.athlete!.profile.guidanceMode, kc.GuidanceMode.assisted);
      expect(app.athlete!.changes.last.rubrics, ['mode']);
      app.evolutionReceive(_place(app, 1), [dl]);
      expect(app.planEvolution.entries.single.status, EvoStatus.applied);
    });

    for (final mode in kc.GuidanceMode.values) {
      for (final kind in [
        kc.ProposalKind.exerciseSwap,
        kc.ProposalKind.painSparing,
        kc.ProposalKind.sessionRestructure,
        kc.ProposalKind.blockRestructure,
      ]) {
        test('${kind.code} (${mode.code}) : restructuration de kalis_plan '
            'appliquée ${mode == kc.GuidanceMode.free ? 'une fois acceptée' : 'd’office'} '
            'à partir de la semaine visée, semaines d’avant intactes, '
            'annulable', () async {
          _program(app, mode);
          final place = _place(app, 1);
          final w1 = _shown(app, 1);
          final w2 = _shown(app, 2);
          final p = _restructure(app, place, kind, 1);
          expect(p.validate(), isEmpty);
          app.evolutionReceive(place, [p]);
          final e = app.planEvolution.entries.single;
          if (mode == kc.GuidanceMode.free) {
            expect(e.status, EvoStatus.pending);
            expect(_shown(app, 2), w2);
            app.evolutionAccept(e);
          }
          final now = app.planEvolution.entries.single;
          expect(now.inEffect, isTrue);
          expect(_shown(app, 1), w1);
          if (p.diff!.changes.isNotEmpty) {
            expect(_shown(app, 2), isNot(w2), reason: kind.code);
          }
          // Le bloc servi au moteur est celui de la restructuration.
          final served = _place(app, 2);
          expect(
            jsonEncode(served.block.pass2.weeks[1].toJson()),
            jsonEncode(p.block!.pass2.weeks[1].toJson()),
          );
          expect(app.evolutionUndo(now), isTrue);
          expect(_shown(app, 2), w2);
          // Texte de Koach et diff (même présentation que G7).
          expect(evolutionReasons(p, exerciseName: (id) => id), isNotEmpty);
        });
      }
    }

    test('sauvegarde : section planEvolution exportée, relue au démarrage '
        'et à l’import ; section invalide refusée à l’import, gardée telle '
        'quelle au démarrage', () async {
      _program(app, kc.GuidanceMode.assisted);
      final place = _place(app, 1);
      app.evolutionReceive(place, [_volume(place, 1)]);
      final exported = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(exported['planEvolution']['v'], 1);
      final next = await relaunch();
      expect(
        jsonEncode(next.planEvolution.toJson()),
        jsonEncode(app.planEvolution.toJson()),
      );
      expect(_shown(next, 2), _shown(app, 2));
      // Import strict.
      final bad = Map<String, dynamic>.from(exported)
        ..['planEvolution'] = {'v': 1, 'entries': 'x'};
      expect(await next.importAll(jsonEncode(bad)), isFalse);
      // Démarrage : section illisible gardée telle quelle.
      SharedPreferences.setMockInitialValues({});
      final third = AppStore()..storeClock = () => clock;
      await third.init();
      others.add(third);
      expect(await third.importAll(jsonEncode(exported)), isTrue);
      expect(third.planEvolution.entries, hasLength(1));
    });

    test('démarrage sur une section planEvolution illisible : gardée telle '
        'quelle, aucune proposition écrite par-dessus', () async {
      _program(app, kc.GuidanceMode.assisted);
      final place = _place(app, 1);
      app.evolutionReceive(place, [_volume(place, 1)]);
      await app.flush();
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final bad = jsonDecode(jsonEncode(doc['planEvolution'])) as Map;
      ((bad['entries'] as List).first as Map)['status'] = 'inconnu';
      doc['planEvolution'] = bad;
      SharedPreferences.setMockInitialValues({
        'kalis_state_v3': jsonEncode(doc),
      });
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      expect(next.evolutionLoadIssues, 1);
      expect(next.planEvolution.isEmpty, isTrue);
      expect(
        next.evolutionReceive(_place(next, 1), [_deload(_place(next, 1), 2)]),
        isFalse,
      );
      expect(next.evolutionRefresh(force: true), isFalse);
      final out = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      expect(jsonEncode(out['planEvolution']), jsonEncode(bad));
    });

    test('fin de bloc : bloc suivant passé en revue (nouveaux exercices '
        'seulement) puis validé ; propositions en place reprises', () async {
      _program(app, kc.GuidanceMode.assisted);
      final weeks = app.planProgram!.blocks.single.weeks;
      // Dernière semaine du bloc.
      clock = DateTime(2026, 10, 1 + (weeks - 1) * 7, 9);
      expect(PlanStore(app).planBlockEnding, isTrue);
      final c = PlanStore(app).newNextBlockCreation(journal: false)!;
      expect(c.isNext, isTrue);
      expect(c.started, isTrue);
      final known = {
        for (final d in app.planProgram!.blocks.single.block.pass1.days)
          for (final s in d.slots) s.exerciseId,
      };
      for (final d in c.plan.days) {
        for (final s in d.slots) {
          expect(
            c.decided.contains(s.slotId),
            known.contains(s.exerciseId),
            reason: s.exerciseId,
          );
          expect(
            c.newSlotIds.contains(s.slotId),
            !known.contains(s.exerciseId),
          );
        }
      }
      // Sans changement de revue, la passe 2 est celle du moteur (résumé
      // d'adaptation compris).
      final p2 = c.createPass2();
      expect(p2.blockId, c.plan.blockId);
      PlanStore(app).applyNextBlockCreation(c);
      expect(app.planProgram!.blocks, hasLength(2));
      expect(app.program.weeks.length, weeks + c.plan.weeks);
    });

    test('simulateur : même graine, même session ; séances faites, notées en '
        'flammes, revue du moteur', () async {
      Future<String> run(int seed) async {
        SharedPreferences.setMockInitialValues({});
        final s = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
        await s.init();
        others.add(s);
        _program(s, kc.GuidanceMode.assisted);
        final r = await runDevSimulation(
          s,
          athleteKey: 'intermediaire_salle',
          weeks: 2,
          seed: seed,
        );
        expect(r.error, isNull);
        expect(r.sessionsDone, greaterThan(0));
        expect(r.end, DateTime(2026, 10, 15));
        final done = s.logs.values.where((l) => l.done).toList();
        expect(done, hasLength(r.sessionsDone));
        final rated = [
          for (final l in done)
            for (final x in l.ex.values)
              for (final st in x.sets)
                if (st.flames != null) st,
        ];
        expect(rated, isNotEmpty);
        expect(s.lastEvolutionReview, isNotNull);
        expect(s.storeClock(), DateTime(2026, 10, 1, 9));
        return s.exportAll();
      }

      final a = await run(7);
      final b = await run(7);
      expect(a, b);
      final c = await run(8);
      expect(c, isNot(a));
    }, timeout: const Timeout(Duration(minutes: 4)));

    test('déblocage visible (D5.7) : charges dès la première séance, volume '
        'dans 2 semaines', () async {
      _program(app, kc.GuidanceMode.assisted);
      app.evolutionRefresh(force: true);
      final u = app.evolutionUnlock;
      expect(u.level, kc.UnlockLevel.loadsReps);
      expect(u.next, kc.UnlockLevel.volume);
      expect(u.weeksToNext, 2);
      expect(
        unlockNextText(next: u.next, weeks: u.weeksToNext, blocks: 0),
        startsWith('Dans 2 semaines'),
      );
    });
  });

  group('écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
    });

    Widget page(Widget child, {bool dark = true, double scale = 1}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(body: child),
        );

    for (final dark in [true, false]) {
      testWidgets('carte de l’accueil (${dark ? 'sombre' : 'clair'}) : '
          'proposition en attente, Accepter / Refuser / Plus tard, Pourquoi '
          '?, ce qui change ; 320 px et texte à 200 %', (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        store.storeClock = () => DateTime(2026, 10, 1, 9);
        addTearDown(() => store.storeClock = DateTime.now);
        store.logs.clear();
        store.planEvolution = PlanEvolution.empty;
        _program(store, kc.GuidanceMode.free);
        final place = _place(store, 1);
        store.evolutionReceive(place, [_volume(place, 1)]);
        await tester.pumpWidget(
          page(
            const SingleChildScrollView(child: EvolutionHomeCard()),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final e = store.planEvolution.entries.single;
        expect(find.byKey(const ValueKey('evo-home-card')), findsOneWidget);
        expect(find.textContaining('Je te propose'), findsOneWidget);
        expect(find.byKey(ValueKey('evo-accept-${evoKey(e)}')), findsOneWidget);
        expect(find.byKey(ValueKey('evo-refuse-${evoKey(e)}')), findsOneWidget);
        expect(find.byKey(ValueKey('evo-later-${evoKey(e)}')), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(ValueKey('evo-details-${evoKey(e)}')),
        );
        await tester.tap(find.byKey(ValueKey('evo-details-${evoKey(e)}')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('evo-sheet')), findsOneWidget);
        await tester.dragUntilVisible(
          find.textContaining('→'),
          find.byKey(const ValueKey('evo-sheet')),
          const Offset(0, -200),
        );
        expect(find.textContaining('→'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('écran Évolution : mode modifiable, déblocage, historique '
        'avec raisons ; annulation', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      store.storeClock = () => DateTime(2026, 10, 1, 9);
      addTearDown(() => store.storeClock = DateTime.now);
      store.logs.clear();
      store.planEvolution = PlanEvolution.empty;
      _program(store, kc.GuidanceMode.assisted);
      final place = _place(store, 1);
      store.evolutionReceive(place, [_volume(place, 1)]);
      final e = store.planEvolution.entries.single;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const EvolutionScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('evo-mode-switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('evo-unlock')), findsOneWidget);
      expect(find.byKey(ValueKey('evo-history-${evoKey(e)}')), findsOneWidget);
      expect(find.text('Appliqué (mode assisté)'), findsOneWidget);
      await tester.tap(find.text('Libre'));
      await tester.pumpAndSettle();
      expect(store.adaptMode, 'free');
      await tester.ensureVisible(
        find.byKey(ValueKey('evo-history-undo-${evoKey(e)}')),
      );
      await tester.tap(find.byKey(ValueKey('evo-history-undo-${evoKey(e)}')));
      await tester.pumpAndSettle();
      expect(store.planEvolution.entries.single.status, EvoStatus.undone);
      expect(find.text('Annulé'), findsOneWidget);
    });
  });
}
