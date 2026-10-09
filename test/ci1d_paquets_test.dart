// CI1d (dev6.9.3, pipeline CP, DECISIONS_CP.md C10.6) — paquets
// `kalis_plan` 0.2.3 et `kalis_adapt` 0.2.3 dans l'application : nouvelles
// notes de coach (bloc de reprise après douleur, poignet sensible, série
// repère, simulation du test, repères, critère de passage, sécurités de la
// cage, hauteur d'appui), conduite sous douleur de `kalis_adapt` 0.2.3
// (palier de reprise, tests reportés tant que la zone est au-dessus de
// 2/10, appui neutre pendant l'arrêt du poignet, renvoi vers un
// professionnel une fois par semaine). Textes lisibles, jamais un code
// brut. Données synthétiques ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/plan/coach_texts.dart';
import 'package:streetlift_tracker/store.dart';

/// Profils street des fixtures du parcours v3 (`kalis_core`, CQ), en JSON.
List<Map<String, Object?>> _streetJson() {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return [
    for (final p in raw['profiles']! as List)
      ((p as Map)['profile'] as Map).cast<String, Object?>(),
  ].where((p) {
    final primary = kc.AthleteProfile.fromJson(p).disciplines.primary.code;
    return primary == 'street_workout' ||
        primary == 'streetlifting' ||
        primary == 'calisthenics';
  }).toList();
}

void _save(AppStore app, kc.AthleteProfile p) {
  final r = app.saveAthleteProfile(ProfileDraft.of(p)..consent = 'refused');
  expect(r, isNotNull, reason: 'profil enregistré');
}

void _create(AppStore app) {
  final c = PlanStore(app).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(app).applyPlanCreation(c);
}

/// Toutes les raisons d'un bloc : passes 1 et 2, chaque prescription.
List<kc.Reason> _blockReasons(kc.ProgramBlock block) => [
  ...block.pass1.reasons,
  ...block.pass2.reasons,
  for (final w in block.pass2.weeks)
    for (final d in w.days)
      for (final it in d.items) ...it.reasons,
];

/// Séance servie minimale (raisons et ajustements seulement).
kc.SessionPlan _plan({
  List<kc.Reason> reasons = const [],
  List<kc.SessionAdjustment> adjustments = const [],
}) => kc.SessionPlan(
  date: kc.CivilDate(2026, 10, 1),
  blockId: 'b1',
  weekIndex: 0,
  dayIndex: 0,
  items: const [],
  adjustments: adjustments,
  confidence: 1,
  reasons: reasons,
);

const _newNotes = <String>[
  kp.CoachNotes.checkpointBody,
  kp.CoachNotes.checkpointHold,
  kp.CoachNotes.checkpointLadder,
  kp.CoachNotes.checkpointLoad,
  kp.CoachNotes.entryCheck,
  kp.CoachNotes.painReprise,
  kp.CoachNotes.pushHeight,
  kp.CoachNotes.repsRehearsal,
  kp.CoachNotes.safetyPins,
  kp.CoachNotes.stepCriterion,
  kp.CoachNotes.wristSpare,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paquets 0.2.3 dans l’application', () {
    expect(kp.kalisPlanVersion, '0.2.3');
    expect(ka.kalisAdaptVersion, '0.2.3');
  });

  group('textes des nouvelles raisons (0.2.3)', () {
    late AppStore app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('nouvelles notes de kalis_plan : rédigées, jamais un code brut', () {
      final catalog = app.content.catalog;
      expect(catalog, isNotNull);
      for (final note in _newNotes) {
        for (final v in <double>[0, 2, 12, 85]) {
          final r = kc.Reason(
            code: kc.ReasonCodes.planCoachNote,
            params: {'note': note, 'value': v},
          );
          final t = coachText(r, catalog);
          expect(t, isNotNull, reason: '$note ($v)');
          expect(t!.trim(), isNotEmpty, reason: note);
          expect(t.contains(note), isFalse, reason: '$note : code brut');
          expect(t.contains('plan.'), isFalse, reason: note);
        }
      }
    });

    test('reprise après douleur et poignet sensible : signalés comme '
        'douleur ; les autres nouvelles notes non', () {
      for (final note in _newNotes) {
        final r = kc.Reason(
          code: kc.ReasonCodes.planCoachNote,
          params: {'note': note, 'value': 2},
        );
        expect(
          isPainReason(r),
          note == kp.CoachNotes.painReprise || note == kp.CoachNotes.wristSpare,
          reason: note,
        );
      }
      const held = kc.Reason(
        code: 'adapt.load_held',
        params: {'cause': 'pain_return'},
      );
      expect(isPainReason(held), isTrue);
      final t = adaptReasonText(held, exerciseName: (id) => id)!;
      expect(t, startsWith('Reprise après une douleur'));
      expect(t.contains('pain_return'), isFalse);
      expect(
        isPainReason(
          const kc.Reason(code: 'adapt.load_held', params: {'cause': 'health'}),
        ),
        isFalse,
      );
    });

    test('test reporté sur une zone douloureuse ou en reprise ; appui '
        'neutre pendant l’arrêt du poignet', () {
      String name(String id) => id == 'dips' ? 'Dips' : 'Pompes';
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseRemoved,
            exerciseId: 'dips',
            reasons: [
              kc.Reason(
                code: 'adapt.pain_reported',
                params: {'zone': 'wrist_hand', 'intensity': 3},
              ),
            ],
          ),
          name,
          test: true,
        ),
        'Test de Dips reporté : pas de test tant que le poignet est '
        'au-dessus de 2 sur 10 ; il reviendra un jour sans gêne.',
      );
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseRemoved,
            exerciseId: 'dips',
            reasons: [
              kc.Reason(
                code: 'adapt.load_held',
                params: {'cause': 'pain_return'},
              ),
            ],
          ),
          name,
          test: true,
        ),
        'Test de Dips reporté : pas de test pendant la reprise après une '
        'douleur.',
      );
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseRemoved,
            exerciseId: 'dips',
            reasons: [
              kc.Reason(
                code: 'adapt.pain_reported',
                params: {'zone': 'shoulder', 'intensity': 5},
              ),
            ],
          ),
          name,
        ),
        'Dips retiré aujourd’hui : il charge l’épaule, douleur signalée.',
      );
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseSwapped,
            exerciseId: 'push',
            replacementExerciseId: 'dips',
            reasons: [
              kc.Reason(
                code: 'adapt.pain_persistent',
                params: {'zone': 'wrist_hand', 'sessions': 4},
              ),
            ],
          ),
          name,
        ),
        'Pompes remplacé par Dips : appui neutre, le poignet est à l’arrêt '
        '(douleur qui dure).',
      );
    });

    test('arrêt sans renvoi ce jour-là : la carte reste, sans la consigne '
        'de consulter (renvoi une fois par semaine)', () {
      const why = kc.Reason(
        code: 'adapt.pain_persistent',
        params: {'zone': 'wrist_hand', 'sessions': 9},
      );
      const removed = kc.SessionAdjustment(
        kind: kc.AdjustmentKind.exerciseRemoved,
        exerciseId: 'dips',
        reasons: [why],
      );
      String name(String id) => 'Dips';
      // Jour du renvoi : la raison est dans la séance.
      final notice = _plan(reasons: [why], adjustments: [removed]);
      // Autre jour de l'arrêt : seulement l'ajustement.
      final quiet = _plan(adjustments: [removed]);
      final a = painStopsOf(notice, name);
      final b = painStopsOf(quiet, name);
      expect(a.single.zone, contains('poignet'));
      expect(b.single.zone, a.single.zone);
      expect(b.single.removed, ['Dips']);
      expect(painStopNoticeZones(notice), {a.single.zone});
      expect(painStopNoticeZones(quiet), isEmpty);
      final full = painStopText(a.single);
      final short = painStopText(b.single, notice: false);
      expect(full, contains('Consulte un médecin ou un kinésithérapeute'));
      expect(short, startsWith('Arrêt en cours (poignet'));
      expect(short, contains('Retiré aujourd’hui : Dips.'));
      expect(short.contains('Consulte'), isFalse);
      expect(short, contains('2 sur 10 au plus'));
      // Rien à l'arrêt : pas de carte.
      expect(painStopsOf(_plan(), name), isEmpty);
    });

    test('programmes street des fixtures : chaque note de coach rédigée, '
        'aucun code brut', () async {
      var seen = 0;
      var coach = 0;
      for (final json in _streetJson()) {
        SharedPreferences.setMockInitialValues({});
        final s = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
        await s.init();
        final catalog = s.content.catalog;
        _save(s, kc.AthleteProfile.fromJson(json));
        _create(s);
        final block = s.planProgram!.blocks.last.block;
        if (isCoachBlock(block)) {
          coach++;
          for (final r in _blockReasons(block)) {
            if (r.code != kc.ReasonCodes.planCoachNote) continue;
            seen++;
            final t = coachText(r, catalog);
            expect(t, isNotNull, reason: '${r.params['note']}');
            expect(
              t!.contains('${r.params['note']}'),
              isFalse,
              reason: '${r.params['note']} : code brut',
            );
          }
          for (final line in coachProgramRules(block, catalog)) {
            expect(line.contains('plan.'), isFalse, reason: line);
          }
        }
        await s.flush();
        s.dispose();
      }
      expect(coach, greaterThan(0));
      expect(seen, greaterThan(0));
    });

    test('poignet sensible déclaré au profil : figures en appui réduites '
        '(note « poignet sensible » rédigée, bouclier)', () {
      final catalog = app.content.catalog;
      final json = Map<String, Object?>.of(
        _streetJson().firstWhere(
          (p) =>
              kc.AthleteProfile.fromJson(p).disciplines.primary.code ==
              'street_workout',
        ),
      );
      // Profil de figures (comme le test de `kalis_plan` 0.2.3, C9.8,
      // `street_10`) : planche visée, six séances, parallettes et anneaux.
      json['experience'] = 'elite';
      json['disciplines'] = {
        'primary': 'calisthenics',
        'primaryPct': 60,
        'secondaries': [
          {'discipline': 'street_workout', 'pct': 20},
          {'discipline': 'streetlifting', 'pct': 20},
        ],
      };
      json['streetMode'] = {
        'primary': 'calisthenics',
        'streetliftingPct': 20,
        'setsRepsPct': 20,
        'calisthenicsPct': 60,
      };
      json['availability'] = [
        for (final d in [1, 2, 3, 5, 6, 7]) {'weekday': d, 'minutes': 90},
      ];
      json['equipment'] = [
        ...(json['equipment']! as List),
        'parallettes',
        'anneaux',
      ];
      json['benchmarks'] = [
        ...(json['benchmarks']! as List),
        {
          'exerciseId': 'cs-planche-straddle',
          'kind': 'max_hold',
          'source': 'declared',
          'date': '2026-09-18',
          'seconds': 6,
        },
      ];
      json['skills'] = [
        {
          'targetExerciseId': 'cs-planche',
          'currentExerciseId': 'cs-planche-straddle',
        },
      ];
      json['limitations'] = [
        {
          'zone': 'wrist_hand',
          'side': 'both',
          'joint': 'poignet',
          'discomfort': 2,
        },
      ];
      _save(app, kc.AthleteProfile.fromJson(json));
      _create(app);
      final block = app.planProgram!.blocks.last.block;
      expect(isCoachBlock(block), isTrue);
      final spared = [
        for (final w in block.pass2.weeks)
          for (final d in w.days)
            for (final it in d.items)
              if (it.reasons.any(
                (r) =>
                    r.code == kc.ReasonCodes.planCoachNote &&
                    r.params['note'] == kp.CoachNotes.wristSpare,
              ))
                it,
      ];
      expect(spared, isNotEmpty, reason: 'note wrist_spare attendue');
      for (final it in spared) {
        final r = it.reasons.firstWhere(
          (r) => r.params['note'] == kp.CoachNotes.wristSpare,
        );
        expect(isPainReason(r), isTrue);
        final notes = coachItemNotes(it, catalog);
        expect(
          notes.any((n) => n.startsWith('Poignet sensible')),
          isTrue,
          reason: it.exerciseId,
        );
      }
    });
  });
}
