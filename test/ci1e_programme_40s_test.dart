// CI1e (dev6.10.0, pipeline CP, DECISIONS_CP.md C11) — le programme de 40
// semaines du propriétaire passe sous toutes les fonctionnalités :
// annotation déterministe au contrat 0.4.0 (blocs de 6 semaines au plus,
// intentions des semaines, saison, échéance fin S40, rôles des lignes),
// mode coach de `kalis_adapt`, saison, tests, conduite sous douleur,
// tests reportés, propositions réelles de Koach (restructurations
// comprises) ; filets C11.2 : sauvegarde d'origine automatique, retour au
// programme d'origine, journal jamais réécrit.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/journal_adapter.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Ancien emplacement (≤ 6.9.3) et ancien rang de journée : bloc importé
/// unique de 40 semaines, journées J1 à J6 → 0 à 5.
String _oldSlot(int j, String id) => 'j$j-${id.split('~').first}';

/// Sauvegarde au format 6.9.3 du propriétaire : programme commencé le
/// 13/07/2026, journal jusqu'à S13·J[lastJ] ; les séances de S12 et S13
/// portent une séance du moteur enregistrée comme par 6.9.3 (bloc
/// `legacy-programme-v33`, semaine S-1, emplacements « j<J>-<id> »).
Future<Map<String, dynamic>> _backup693(
  AppStore app, {
  int lastWeek = 13,
  int lastJ = 4,
}) async {
  final filled = filledBackup(app);
  final logs = (filled['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && w == 13 && j > lastJ);
  });
  filled['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  return filled;
}

Future<void> _ownerAt(AppStore app, {int lastWeek = 13, int lastJ = 4}) async {
  final b = await _backup693(app, lastWeek: lastWeek, lastJ: lastJ);
  expect(await app.importAll(jsonEncode(b)), isTrue);
}

void _saveProfile(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
}

/// Séance du moteur au format 6.9.3, tirée d'une séance servie aujourd'hui
/// (bloc annoté) : même prescription, ancien bloc, anciens emplacements.
Map<String, dynamic> _as693(
  AppStore app,
  int week,
  int j,
  Map<String, dynamic> now,
) {
  final back = <String, String>{};
  for (final e in app.program.week(week).day(j)!.original.exercises) {
    final s = app.adaptSlotOf(week, j, e.id);
    if (s != null) back[s] = _oldSlot(j, e.id);
  }
  Map<String, dynamic> plan(Map p) => {
    ...p.cast<String, dynamic>(),
    'items': [
      for (final it in p['items'] as List)
        {
          ...(it as Map).cast<String, dynamic>(),
          'slotId': back[it['slotId']] ?? it['slotId'],
        },
    ],
  };
  final js = <int>[
    for (final d in app.program.week(week).days)
      if (d.exercises.isNotEmpty) d.j,
  ]..sort();
  return {
    ...now,
    'blockId': kLegacyProgramBlockId,
    'week': week - 1,
    'day': js.indexOf(j),
    'plan': plan(now['plan'] as Map),
    if (now['base'] != null) 'base': plan(now['base'] as Map),
  };
}

/// Valide la première série du premier exercice servi (séance au journal).
void _logOneSet(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  final day = app.adaptDay(week, base, a);
  for (final e in day.exercises) {
    final log = app.exLog(week, j, e);
    if (log.sets.isEmpty) continue;
    app.adaptPrefill(week, j, e, log);
    final s = log.sets.first;
    if (s.reps.isEmpty) s.reps = '5';
    s.flames = 7;
    if (app.toggleSet(log, 0, app.logSpec(e)).ok) {
      app.adaptAfterSet(week, day, e, 0);
      break;
    }
  }
  app.saveLogs();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('programme de 40 semaines (C11)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 9, 9);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 9, 9); // vendredi, S13·J5
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('découpage : un bloc par bloc du programme, coupé après une '
        'semaine allégée au-delà de 6 semaines', () {
      final keys = {
        for (var n = 1; n <= 40; n++)
          n: n <= 3
              ? 'P0'
              : n <= 11
              ? 'B1'
              : n <= 19
              ? 'B2'
              : n <= 25
              ? 'B3'
              : n <= 31
              ? 'B4'
              : 'B5',
      };
      const deloads = {7, 11, 15, 19, 23, 30, 35};
      expect(importedRanges(1, 40, (n) => keys[n]!, deloads.contains), [
        (1, 3),
        (4, 7),
        (8, 11),
        (12, 15),
        (16, 19),
        (20, 25),
        (26, 31),
        (32, 35),
        (36, 40),
      ]);
      // Sans semaine allégée : parts égales de 6 semaines au plus.
      expect(importedRanges(1, 14, (_) => 'X', (_) => false), [
        (1, 5),
        (6, 10),
        (11, 14),
      ]);
      expect(
        importedPhaseOf('Bloc 1 — Hypertrophie'),
        kc.SeasonPhaseKind.accumulation,
      );
      expect(
        importedPhaseOf('Bloc 2 — Force'),
        kc.SeasonPhaseKind.intensification,
      );
      expect(
        importedPhaseOf('Bloc 3 — Force max'),
        kc.SeasonPhaseKind.realization,
      );
      expect(
        importedPhaseOf('Bloc 4 — Endurance'),
        kc.SeasonPhaseKind.accumulation,
      );
      expect(
        importedPhaseOf('Bloc 5 — Peaking'),
        kc.SeasonPhaseKind.realization,
      );
      expect(importedPhaseOf('Phase 0 — Tests'), kc.SeasonPhaseKind.test);
    });

    test('annotation du programme du propriétaire : blocs valides au '
        'contrat 0.4.0, mode coach, saison et échéance fin S40', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final imp = app.importedProgram!;
      expect(imp.segments.length, 9);
      expect(
        [for (final s in imp.segments) (s.first, s.last)],
        [
          (1, 3),
          (4, 7),
          (8, 11),
          (12, 15),
          (16, 19),
          (20, 25),
          (26, 31),
          (32, 35),
          (36, 40),
        ],
      );
      for (final s in imp.segments) {
        final b = s.block;
        expect(b.validate(), isEmpty, reason: s.blockId);
        expect(b.pass1.weeks, lessThanOrEqualTo(6));
        expect(b.pass1.blockIndex, s.index);
        expect(b.pass1.intent, isNotNull);
        expect(ka.blockCoached(b), isTrue, reason: 'mode coach ${s.blockId}');
        for (final w in b.pass2.weeks) {
          expect(w.intent, isNotNull);
        }
        // Aucun emplacement verrouillé : échanges et restructurations
        // permis (C11).
        for (final d in b.pass1.days) {
          for (final sl in d.slots) {
            expect(sl.locked, isFalse);
          }
        }
      }
      // Phases : tests, hypertrophie, force, force max, endurance, peaking.
      expect(
        [for (final s in imp.segments) s.phase.code],
        [
          'test',
          'accumulation',
          'accumulation',
          'intensification',
          'intensification',
          'realization',
          'accumulation',
          'intensification',
          'realization',
        ],
      );
      // Semaines allégées et de test.
      final b2 = imp.segmentOf(15)!.block;
      expect(b2.pass2.weeks[3].intent, kc.WeekIntent.deload);
      expect(
        imp.segmentOf(39)!.block.pass2.weeks[3].intent,
        kc.WeekIntent.test,
      );
      // Saison : phases contiguës, échéance à la fin de S40 (18/04/2027).
      final season = imp.season!;
      expect(season.validate(), isEmpty);
      expect(season.phases.first.startDate, kc.CivilDate(2026, 7, 13));
      expect(season.phases.fold<int>(0, (a, p) => a + p.weeks), 40);
      expect(season.phases.last.eventId, kImportedEventId);
      expect(imp.event!.date, kc.CivilDate(2027, 4, 18));
      // Emplacements stables d'une semaine à l'autre : le muscle-up lesté
      // de J1 a le même emplacement en S12, S13 et S14.
      String slotOfFirst(int w) => app.adaptSlotOf(
        w,
        1,
        app.program.week(w).day(1)!.exercises.first.id,
      )!;
      expect(slotOfFirst(12), slotOfFirst(13));
      expect(slotOfFirst(13), slotOfFirst(14));
      // Clusters (S14) et tests (1RM en S39, max en S40) annotés.
      final s14 = app.adaptPlaceOf(14, 1)!;
      expect(
        s14.day!.items.any(
          (i) => i.technique?.kind == kc.SetTechniqueKind.cluster,
        ),
        isTrue,
      );
      final s39 = app.adaptPlaceOf(39, 1)!;
      final oneRm = s39.day!.items.firstWhere(
        (i) => i.test?.kind == kc.TestKind.oneRm,
      );
      expect(oneRm.kind, kc.SetKind.test);
      // Une ligne par tentative (montée hors journal), comme kalis_plan.
      expect(oneRm.sets, 3);
      expect(oneRm.setTargets, isNull);
      final s40 = app.adaptPlaceOf(40, 1)!;
      expect(
        s40.day!.items.any((i) => i.test?.kind == kc.TestKind.maxReps),
        isTrue,
      );
      // Ce qui ne se déduit pas proprement reste absent (listé) ; CI1f :
      // les myo-reps sont annotés.
      expect(imp.absent.keys, isNot(contains('N×N puis N×(N)')));
      // ignore: avoid_print
      print('CI1E absent ${jsonEncode(imp.absent)}');
      // ignore: avoid_print
      print(
        'CI1E segments ${[
          for (final s in imp.segments) '${s.blockId}:${s.phase.code}:${[for (final w in s.block.pass2.weeks) w.intent?.code].join('/')}',
        ]}',
      );
    });

    test(
      'migration 6.9.3 → 6.10.0 : sauvegarde d’origine automatique, '
      'séances du moteur relues sur le bloc annoté, journal intact',
      () async {
        // Séances servies par le moteur en S13 (format 6.9.3) : prescrites
        // avec le code d'aujourd'hui puis réécrites à l'ancienne.
        await _ownerAt(app);
        _saveProfile(app, kc.GuidanceMode.assisted);
        final b = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        final logs = (b['logs'] as Map).cast<String, dynamic>();
        final oldAdapts = <String, Map<String, dynamic>>{};
        for (var j = 1; j <= 4; j++) {
          final day = app.program.week(13).day(j)!;
          app.logs.remove('S13-J$j');
          final a = app.adaptOpen(13, day)!;
          final old = _as693(app, 13, j, a.toJson().cast<String, dynamic>());
          oldAdapts['S13-J$j'] = old;
          final l = (logs['S13-J$j'] as Map).cast<String, dynamic>();
          logs['S13-J$j'] = {...l, 'adapt': old};
        }
        b.remove('programOrigin');
        // Nouvelle installation : la sauvegarde 6.9.3 est le document local.
        await app.flush();
        app.dispose();
        SharedPreferences.setMockInitialValues({});
        app = AppStore()..storeClock = () => clock;
        await app.init();
        expect(app.programOrigin, isNull);
        expect(await app.importAll(jsonEncode(b)), isTrue);
        // Sauvegarde d'origine prise (dans le document et en local).
        expect(app.programOrigin, isNotNull);
        final origin = (app.programOrigin!['backup'] as Map)
            .cast<String, dynamic>();
        expect(jsonEncode(origin['logs']), jsonEncode(b['logs']));
        expect(
          (jsonDecode(app.exportAll()) as Map).containsKey('programOrigin'),
          isTrue,
        );
        // Séances du moteur de 6.9.3 relues sur le bloc annoté de S13.
        final seg = app.importedProgram!.segmentOf(13)!;
        for (var j = 1; j <= 4; j++) {
          final a = app.sessionAdapt(13, j)!;
          expect(a.blockId, seg.blockId);
          expect(a.weekIndex, 13 - seg.first);
          for (final it in a.plan.items) {
            expect(it.slotId.startsWith('j$j-'), isTrue);
            expect(
              seg.block.pass1.days.any(
                (d) => d.slots.any((s) => s.slotId == it.slotId),
              ),
              isTrue,
              reason: '${it.slotId} relu sur le bloc annoté',
            );
          }
          // Le journal enregistré n'est pas réécrit.
          expect(
            jsonEncode(app.logs['S13-J$j']!.adapt),
            jsonEncode(oldAdapts['S13-J$j']),
          );
        }
        // Journal présenté au moteur : séances de S13 rattachées au bloc
        // annoté.
        final log = app.adaptTrainingLog();
        final s13 = log.sessions.where(
          (s) => s.programRef?.blockId == seg.blockId,
        );
        expect(s13.length, greaterThanOrEqualTo(4));
      },
    );

    test('séance du jour servie en mode coach, saison et compte à rebours, '
        'échéance donnée au moteur', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final day = app.program.week(13).day(5)!;
      final place = app.adaptPlaceOf(13, 5)!;
      expect(place.imported, isTrue);
      expect(app.adaptSeasonOf(place), isNotNull);
      final a = app.adaptOpen(13, day)!;
      expect(a.plan.validate(), isEmpty);
      expect(a.plan.weekIntent, isNotNull, reason: 'mode coach');
      expect(
        app.adaptProfile!.events!.any((e) => e.id == kImportedEventId),
        isTrue,
      );
      // MA SAISON : phases, phase en cours, compte à rebours.
      final previous = store;
      store = app;
      final view = storeSeasonOverview()!;
      store = previous;
      expect(view.phases.length, greaterThanOrEqualTo(5));
      expect(view.currentPhase, isNotNull);
      expect(
        view.daysToEvent,
        kc.CivilDate(2027, 4, 18).dayNumber -
            kc.CivilDate(2026, 10, 9).dayNumber,
      );
      expect(view.blockWeeks.map((w) => w.n), [12, 13, 14, 15]);
    });

    test('douleur qui dure → arrêt pour douleur (mode coach du '
        'programme importé)', () async {
      await _ownerAt(app, lastWeek: 11);
      _saveProfile(app, kc.GuidanceMode.assisted);
      const wrist = kc.PainReport(
        zone: kc.BodyZone.wristHand,
        side: kc.BodySide.both,
        intensity: 4,
        phase: kc.PainPhase.before,
      );
      final start = DateTime(2026, 9, 28, 9);
      (int, int)? stopDay;
      for (var w = 12; w <= 14 && stopDay == null; w++) {
        for (var j = 1; j <= 6 && stopDay == null; j++) {
          clock = DateTime(2026, 7, 13 + (w - 1) * 7 + j - 1, 9);
          final base = app.program.week(w).day(j)!;
          if (base.exercises.isEmpty) continue;
          final opened = app.adaptOpen(w, base);
          if (opened == null) continue;
          if (clock.difference(start).inDays >= 15 &&
              opened.active.reasons.any(
                (r) => r.code == 'adapt.pain_persistent',
              )) {
            stopDay = (w, j);
            break;
          }
          app.adaptAnswer(w, base, const kc.HealthCheck(pains: [wrist]));
          _logOneSet(app, w, j);
        }
      }
      expect(stopDay, isNotNull, reason: 'arrêt après deux semaines à 4/10');
      final (w, j) = stopDay!;
      final a = app.sessionAdapt(w, j)!;
      expect(painStopsOf(a.active, app.adaptExerciseName), isNotEmpty);
    });

    test('propositions réelles de la revue (relevé) et restructuration '
        'acceptée puis annulée, montrée dans le programme', () async {
      await _ownerAt(app);
      for (final mode in [kc.GuidanceMode.free, kc.GuidanceMode.assisted]) {
        _saveProfile(app, mode);
        app.evolutionRefresh(force: true);
        final r = app.lastEvolutionReview!;
        expect(r.place.imported, isTrue);
        // ignore: avoid_print
        print(
          'CI1E revue ${mode.code} : ${r.place.blockId} déblocage='
          '${r.review.summary.unlockLevel.code} propositions='
          '${[for (final p in r.review.proposals) '${p.id}(${p.kind.code})']}',
        );
      }
      expect(app.evolutionNotApplicable, isEmpty);
      // Restructuration : la journée J2 de S14 perd son dernier exercice
      // porté et la journée J1 en reçoit un nouveau (emplacement ajouté).
      _saveProfile(app, kc.GuidanceMode.free);
      final place = app.adaptPlaceOf(14, 1)!;
      final b = place.block;
      final d1 = place.dayIndex;
      final added = kc.ExercisePrescription(
        slotId: 'j1-kt-ajout',
        exerciseId: b.pass1.days.first.slots.first.exerciseId,
        sets: 2,
        repsLow: 8,
        repsHigh: 10,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.bodyweight,
        reasons: const [],
      );
      final pass1 = b.pass1.copyWith(
        days: [
          for (final d in b.pass1.days)
            d.dayIndex != d1
                ? d
                : d.copyWith(
                    slots: [
                      ...d.slots,
                      kc.PlanSlot(
                        slotId: added.slotId,
                        exerciseId: added.exerciseId,
                        role: kc.SlotRole.accessory,
                        locked: false,
                        reasons: const [],
                      ),
                    ],
                  ),
        ],
      );
      final pass2 = b.pass2.copyWith(
        weeks: [
          for (final w in b.pass2.weeks)
            w.weekIndex < place.weekIndex
                ? w
                : w.copyWith(
                    days: [
                      for (final d in w.days)
                        d.dayIndex != d1
                            ? d
                            : d.copyWith(items: [...d.items, added]),
                    ],
                  ),
        ],
      );
      final p = kc.Proposal(
        id: 'session:test:${place.blockId}@${place.weekIndex}',
        kind: kc.ProposalKind.sessionRestructure,
        scope: kc.ProposalScope.session,
        createdOn: kc.CivilDate(2026, 10, 9),
        confidence: .9,
        unlockLevel: kc.UnlockLevel.sessionRestructure,
        autoApplicable: true,
        block: kc.ProgramBlock(pass1: pass1, pass2: pass2),
        reasons: const [
          kc.Reason(
            code: 'adapt.time_short',
            params: {'minutesAvailable': 30, 'minutesPlanned': 60},
          ),
        ],
      );
      final before = app.program.week(14).day(1)!.exercises.length;
      app.evolutionReceive(place, [p]);
      final e = app.evolutionPending.firstWhere((x) => x.id == p.id);
      app.evolutionAccept(e);
      final shown = app.program.week(14).day(1)!;
      expect(shown.exercises.length, before + 1);
      expect(
        shown.exercises.any(
          (x) => x.id == '${SessionAdaptStore.kKoachAddedPrefix}j1-kt-ajout',
        ),
        isTrue,
      );
      expect(shown.original.exercises.length, before);
      // La séance servie porte l'exercice ajouté.
      clock = DateTime(2026, 10, 12, 9);
      final a = app.adaptOpen(14, shown)!;
      expect(a.plan.items.any((i) => i.slotId == 'j1-kt-ajout'), isTrue);
      // Annuler : l'original revient.
      clock = DateTime(2026, 10, 9, 9);
      app.logs.remove('S14-J1');
      final entry = app.planEvolution.entries.lastWhere((x) => x.id == p.id);
      expect(app.evolutionUndo(entry), isTrue);
      expect(app.program.week(14).day(1)!.exercises.length, before);
    });

    test('ajustement de Koach accepté en 6.9.3 (bloc unique) : ramené sur '
        'le bloc annoté, toujours appliqué et annulable', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final place = app.adaptPlaceOf(14, 2)!;
      final item = place.day!.items.firstWhere(
        (i) => i.setTargets == null && i.sets < 10,
      );
      final shown = app.program
          .week(14)
          .day(2)!
          .exercises
          .firstWhere((e) => app.adaptSlotOf(14, 2, e.id) == item.slotId);
      final setsBefore = app.setCount(shown);
      // Entrée au format 6.9.3 : bloc unique, semaine 13 (S14), journée 1
      // (J2), emplacement « j2-<id> ».
      final old = _oldSlot(2, shown.id);
      final legacyItem = item.copyWith(slotId: old);
      final entry = {
        'proposal': kc.Proposal(
          id: 'volume:$old@13',
          kind: kc.ProposalKind.volume,
          scope: kc.ProposalScope.exercise,
          createdOn: kc.CivilDate(2026, 10, 8),
          confidence: .74,
          unlockLevel: kc.UnlockLevel.volume,
          autoApplicable: true,
          exerciseId: item.exerciseId,
          diff: kc.PlanDiff(
            changes: [
              kc.PlanChange(
                kind: kc.ChangeKind.prescriptionChanged,
                dayIndex: 1,
                weekIndex: 13,
                slotId: old,
                fromPrescription: legacyItem,
                toPrescription: legacyItem.copyWith(sets: item.sets + 1),
                reasons: const [],
              ),
            ],
          ),
          reasons: const [],
        ).toJson(),
        'blockId': kLegacyProgramBlockId,
        'status': 'accepted',
        'decidedOn': '2026-10-08',
        'mode': 'free',
      };
      final b = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      b['planEvolution'] = {
        'v': 1,
        'entries': [entry],
      };
      expect(await app.importAll(jsonEncode(b)), isTrue);
      final e = app.planEvolution.entries.single;
      expect(e.blockId, importedBlockId(12));
      expect(e.fromWeek, 2);
      expect(e.proposal.diff!.changes.single.slotId, item.slotId);
      final after = app.program
          .week(14)
          .day(2)!
          .exercises
          .firstWhere((x) => app.adaptSlotOf(14, 2, x.id) == item.slotId);
      expect(app.setCount(after), setsBefore + 1);
      expect(app.evolutionUndo(e), isTrue);
      final undone = app.program
          .week(14)
          .day(2)!
          .exercises
          .firstWhere((x) => app.adaptSlotOf(14, 2, x.id) == item.slotId);
      expect(app.setCount(undone), setsBefore);
    });

    test('« Supprimer toutes les données » retire aussi la sauvegarde '
        'd’origine', () async {
      await _ownerAt(app);
      expect(app.programOrigin, isNotNull);
      await app.eraseAllData();
      expect(app.programOrigin, isNull);
      expect(ProgramOriginStore(app).canRestoreProgramOrigin, isFalse);
      expect(
        (jsonDecode(app.exportAll()) as Map).containsKey('programOrigin'),
        isFalse,
      );
    });

    test(
      'installation neuve : sauvegarde d’origine au départ du programme ; '
      'retour puis revue du moteur (mode assisté) : programme d’origine',
      () async {
        await app.configureStart(DateTime(2026, 7, 15));
        _saveProfile(app, kc.GuidanceMode.assisted);
        final origin = (app.programOrigin!['backup'] as Map)
            .cast<String, dynamic>();
        final day = app.program.week(13).day(3)!;
        app.adaptOpen(13, day);
        app.evolutionRefresh(force: true);
        final place = app.adaptPlaceOf(13, 3)!;
        final item = place.day!.items.firstWhere((i) => i.setTargets == null);
        app.evolutionReceive(place, [
          kc.Proposal(
            id: 'volume:${item.slotId}@${place.weekIndex}',
            kind: kc.ProposalKind.volume,
            scope: kc.ProposalScope.exercise,
            createdOn: kc.CivilDate(2026, 10, 9),
            confidence: .74,
            unlockLevel: kc.UnlockLevel.volume,
            autoApplicable: true,
            exerciseId: item.exerciseId,
            diff: kc.PlanDiff(
              changes: [
                kc.PlanChange(
                  kind: kc.ChangeKind.prescriptionChanged,
                  dayIndex: place.dayIndex,
                  weekIndex: place.weekIndex,
                  slotId: item.slotId,
                  fromPrescription: item,
                  toPrescription: item.copyWith(sets: item.sets + 1),
                  reasons: const [],
                ),
              ],
            ),
            reasons: const [],
          ),
        ]);
        expect(ProgramOriginStore(app).programDiffersFromOrigin, isTrue);
        expect(ProgramOriginStore(app).restoreProgramOrigin(), isTrue);
        final d0 = ProgramOriginStore(app).programDiffersFromOrigin;
        app.evolutionRefresh();
        final d1 = ProgramOriginStore(app).programDiffersFromOrigin;
        expect(d0, isFalse);
        expect(d1, isFalse);
        final now = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        // ignore: avoid_print
        print(
          'CI1E neuve : avant=$d0 apres=$d1 entrees='
          '${[for (final e in app.planEvolution.entries) '${e.id}/${e.status}']} '
          'sections=${[for (final k in ProgramOriginStore.kProgramOriginSections)
            if (jsonEncode(now[k]) != jsonEncode(origin[k])) '$k: ${jsonEncode(origin[k])} -> ${jsonEncode(now[k])}']}',
        );
      },
    );

    test('retour au programme d’origine : sections du programme identiques '
        'à la sauvegarde, journal gardé', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final origin = (app.programOrigin!['backup'] as Map)
          .cast<String, dynamic>();
      // Le programme change : proposition de volume acceptée, puis un bloc
      // du moteur calibré à la place de la suite.
      final place = app.adaptPlaceOf(13, 5)!;
      final item = place.day!.items.firstWhere((i) => i.setTargets == null);
      app.evolutionReceive(place, [
        kc.Proposal(
          id: 'volume:${item.slotId}@${place.weekIndex}',
          kind: kc.ProposalKind.volume,
          scope: kc.ProposalScope.exercise,
          createdOn: kc.CivilDate(2026, 10, 9),
          confidence: .74,
          unlockLevel: kc.UnlockLevel.volume,
          autoApplicable: true,
          exerciseId: item.exerciseId,
          diff: kc.PlanDiff(
            changes: [
              kc.PlanChange(
                kind: kc.ChangeKind.prescriptionChanged,
                dayIndex: place.dayIndex,
                weekIndex: place.weekIndex,
                slotId: item.slotId,
                fromPrescription: item,
                toPrescription: item.copyWith(sets: item.sets + 1),
                reasons: const [],
              ),
            ],
          ),
          reasons: const [],
        ),
      ]);
      app.evolutionAccept(app.evolutionPending.single);
      expect(ProgramOriginStore(app).programDiffersFromOrigin, isTrue);
      // Une séance validée après la migration.
      final day = app.program.week(13).day(5)!;
      final a = app.adaptOpen(13, day)!;
      final served = app.adaptDay(13, day, a);
      final e = served.exercises.first;
      final log = app.exLog(13, 5, e);
      app.adaptPrefill(13, 5, e, log);
      if (log.sets[0].reps.isEmpty) log.sets[0].reps = '5';
      log.sets[0].flames = 7;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      final logsBefore = jsonEncode(
        (jsonDecode(app.exportAll()) as Map)['logs'],
      );
      expect(ProgramOriginStore(app).restoreProgramOrigin(), isTrue);
      final now = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final k in ProgramOriginStore.kProgramOriginSections) {
        expect(jsonEncode(now[k]), jsonEncode(origin[k]), reason: k);
      }
      expect(jsonEncode(now['logs']), logsBefore, reason: 'journal gardé');
      expect(ProgramOriginStore(app).programDiffersFromOrigin, isFalse);
      // Après le retour, la revue du moteur (mode assisté) : relevé.
      _saveProfile(app, kc.GuidanceMode.assisted);
      app.evolutionRefresh(force: true);
      // ignore: avoid_print
      print(
        'CI1E apres retour : differe=${ProgramOriginStore(app).programDiffersFromOrigin} '
        'entrees=${[for (final e in app.planEvolution.entries) '${e.id}/${e.status}']} '
        'propositions=${[for (final p in app.lastEvolutionReview?.review.proposals ?? const <kc.Proposal>[]) p.id]}',
      );
      final after = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final k in ProgramOriginStore.kProgramOriginSections) {
        if (jsonEncode(after[k]) != jsonEncode(origin[k])) {
          // ignore: avoid_print
          print('CI1E section changée : $k');
        }
      }
      // Exportable : une sauvegarde Kalis Track ordinaire.
      final file = ProgramOriginStore(app).programOriginExport()!;
      expect(app.previewImport(file).status, ImportStatus.success);
    });
  });
}
