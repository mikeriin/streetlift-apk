// KS1A (dev7.1.0, pipeline CP, DECISIONS_CP.md C17.20) — structure de la
// semaine de KS1 dans l'application : `kalis_core` 0.4.4 et `kalis_plan`
// 0.4.1 copiés à l'octet, types de jour affichés (programme créé,
// programme de 40 semaines), textes des six nouveaux codes de raison,
// notes de coach `minimum_load` et `fixed_load`, Koach inchangé (référence
// et signature de dev7.0.0), changement d'échéance (contrat § 12.9 :
// début du bloc suivant = début du bloc précédent + semaines entières
// servies), durée estimée sur le temps disponible (C17.15, option a).
//
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/plan/coach_texts.dart';
import 'package:streetlift_tracker/plan/day_type.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/plan/plan_texts.dart';
import 'package:streetlift_tracker/retired_data.dart' show fnv1a32;
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/training_estimate.dart';

import 'l2_fixtures.dart';

/// Sauvegarde du propriétaire (programme de 40 semaines commencé le
/// 13/07/2026), journal jusqu'à S[lastWeek]·J7 (comme KM3).
Future<void> _owner(AppStore app, {int lastWeek = 14}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    return w > lastWeek;
  });
  for (final e in logs.entries) {
    final log = (e.value as Map).cast<String, dynamic>();
    final ex = (log['ex'] as Map).cast<String, dynamic>();
    for (final x in ex.values) {
      for (final s in ((x as Map)['sets'] as List)) {
        (s as Map)['rir'] = '2';
      }
    }
  }
  final pilot = (b['pilotage'] as Map).cast<String, dynamic>();
  const refs = {
    'B4': 71.5,
    'B8': 55.0,
    'B9': 75.0,
    'B10': 15.0,
    'B11': 120.0,
    'B16': 10.0,
    'B17': 30.0,
    'B18': 70.0,
    'B19': 65.0,
    'B20': 35.0,
  };
  for (final e in refs.entries) {
    pilot.putIfAbsent(e.key, () => e.value);
  }
  b['pilotage'] = pilot;
  b['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(b)), isTrue);
  app.saveAthleteProfile(
    ProfileDraft.of(sampleAthleteProfile(on: civilOf(app.storeClock())))
      ..consent = 'refused',
  );
}

/// Profil street 50 / 50 (streetlifting, sets & reps) à 6 séances de
/// 120 min : compétiteur avancé de `sampleStreetProfile` (lest possible,
/// compétition dans 12 semaines), comme la cible émulateur.
kc.AthleteProfile _street5050(kc.CivilDate on) =>
    sampleStreet5050Profile(on: on);

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

/// Bloc sans les types de jour, comme l'écrivait dev7.0.0.
kc.ProgramBlock _withoutTypes(kc.ProgramBlock b) => b.copyWith(
  pass1: b.pass1.copyWith(
    days: [for (final d in b.pass1.days) d.copyWith(type: null)],
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 19, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    clock = DateTime(2026, 10, 19, 9); // lundi, S15·J1 du propriétaire
    app = AppStore()..storeClock = () => clock;
    await app.init();
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
  });

  group('paquets et textes', () {
    test('kalis_core 0.4.4, kalis_plan 0.4.1, kalis_adapt 1.0.2 inchangé ; '
        'parcours v3 recopié à l’octet', () {
      expect(kc.kalisCoreVersion, '0.4.4');
      expect(kp.kalisPlanVersion, '0.4.1');
      expect(ka.kalisAdaptVersion, '1.0.2');
      expect(kc.reasonRegistry, hasLength(144));
      expect(
        File('assets/catalog/parcours_v3.json').readAsBytesSync(),
        File('packages/kalis_core/data/parcours_v3.json').readAsBytesSync(),
      );
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub, contains('version: 7.1.0+'));
    });

    test('six codes de structure : phrases de l’application, aucun code '
        'brut', () {
      String t(String code, Map<String, Object?> params) => reasonText(
        kc.Reason(code: code, params: params),
        exerciseName: (id) =>
            id == 'sl-traction-lestee' ? 'Traction lestée' : id,
      );
      expect(
        t('plan.split_chosen', {'templateId': 'ppl6_q', 'sessions': 6}),
        'Semaine construite en tirage, poussée, jambes, deux fois, pour tes '
        '6 séances.',
      );
      expect(
        t('plan.day_type', {'patterns': 'legs', 'quality': 'endurance'}),
        'Séance jambes — endurance de force.',
      );
      expect(
        t('plan.milestone', {'date': '2026-12-12', 'goals': 2}),
        'Jalon le 12 décembre : on teste tes 2 objectifs, puis on repart vers '
        'l\'échéance.',
      );
      expect(
        t('plan.milestone', {'date': '2027-01-01', 'goals': 1}),
        'Jalon le 1er janvier : on teste ton objectif, puis on repart vers '
        'l\'échéance.',
      );
      expect(
        t('plan.replaced_disliked', {'exerciseId': 'sl-traction-lestee'}),
        'À la place de Traction lestée, que tu n’aimes pas.',
      );
      expect(
        t('plan.replaced_cannot_do', {'exerciseId': 'sl-traction-lestee'}),
        'À la place de Traction lestée, que tu ne sais pas encore faire.',
      );
      expect(
        t('plan.goal_uncovered', {'goalId': 'goal-1'}),
        contains('je le signale'),
      );
      for (final code in [
        'plan.split_chosen',
        'plan.day_type',
        'plan.goal_uncovered',
        'plan.milestone',
        'plan.replaced_disliked',
        'plan.replaced_cannot_do',
      ]) {
        final text = t(code, const {});
        expect(text, isNot('Choix du moteur.'), reason: code);
        expect(text, isNot(contains('{')), reason: code);
      }
    });

    test('notes de coach minimum_load et fixed_load rédigées', () {
      final catalog = app.content.catalog!;
      for (final note in [kp.CoachNotes.minimumLoad, kp.CoachNotes.fixedLoad]) {
        final text = coachText(
          kc.Reason(
            code: kc.ReasonCodes.planCoachNote,
            params: {'note': note, 'value': 70.0},
          ),
          catalog,
        );
        expect(text, isNotNull, reason: note);
        expect(text, isNot(contains(note)), reason: note);
        expect(text, contains('70'), reason: note);
      }
    });

    test('libellés des types de jour', () {
      expect(
        dayTypeLabel(
          const kc.DayType(
            patterns: [kc.DayPattern.pull],
            quality: kc.DayQuality.force,
          ),
        ),
        'Tirage — force',
      );
      expect(
        dayTypeLabel(
          const kc.DayType(
            patterns: [kc.DayPattern.legs],
            quality: kc.DayQuality.endurance,
          ),
        ),
        'Jambes — endurance de force',
      );
      expect(
        dayTypeLabel(
          const kc.DayType(
            patterns: [kc.DayPattern.skill, kc.DayPattern.pull],
            quality: kc.DayQuality.power,
          ),
        ),
        'Figures + tirage — puissance',
      );
      expect(
        dayTypeLabel(
          const kc.DayType(
            patterns: [kc.DayPattern.recovery],
            quality: kc.DayQuality.recovery,
          ),
        ),
        'Récupération',
      );
      expect(dayTypeLabel(null), isNull);
      for (final p in kc.DayPattern.values) {
        expect(kDayPatternLabels[p], isNotNull, reason: p.code);
      }
      for (final q in kc.DayQuality.values) {
        expect(kDayQualityLabels[q], isNotNull, reason: q.code);
      }
    });
  });

  group('programme de 40 semaines', () {
    test('types déduits des titres : J1 à J3 force, J4 et J5 endurance de '
        'force, J6 puissance ; tests et récupération', () async {
      await _owner(app);
      String? label(int week, int j) =>
          app.dayTypeLabelOf(app.program.week(week).day(j)!);
      // Semaine de construction (B3).
      expect(label(21, 1), 'Tirage — force');
      expect(label(21, 2), 'Poussée — force');
      expect(label(21, 3), 'Jambes — force');
      expect(label(21, 4), 'Tirage — endurance de force');
      expect(label(21, 5), 'Poussée — endurance de force');
      expect(label(21, 6), 'Figures + tirage — puissance');
      expect(label(21, 7), isNull);
      // Puissance du muscle-up et squat d'endurance (S11 à S19).
      expect(label(12, 6), 'Corps entier — puissance');
      // Semaines de test.
      expect(label(1, 1), 'Tirage — force');
      expect(label(1, 5), 'Récupération');
      expect(label(1, 6), 'Récupération');
      expect(label(2, 1), 'Tirage — endurance de force');
      expect(label(2, 3), 'Récupération');
      expect(label(2, 6), 'Jambes — endurance de force');
      final counts = <String, int>{};
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          final l = app.dayTypeLabelOf(d);
          if (d.exercises.isEmpty) {
            expect(l, isNull, reason: 'S${w.n}·J${d.j}');
            continue;
          }
          expect(l, isNotNull, reason: 'S${w.n}·J${d.j} ${d.title}');
          counts[l!] = (counts[l] ?? 0) + 1;
        }
      }
      // ignore: avoid_print
      print('KS1A|40s|$counts');
    });

    test('blocs importés : chaque journée porte son type ; rien n’est '
        'enregistré, aucune séance réécrite', () async {
      await _owner(app);
      final before = jsonEncode(
        (jsonDecode(app.exportAll()) as Map<String, dynamic>)['logs'],
      );
      final imp = app.importedProgram!;
      for (final s in imp.segments) {
        expect(s.block.validate(), isEmpty, reason: s.blockId);
        for (final d in s.block.pass1.days) {
          expect(d.type, isNotNull, reason: '${s.blockId} ${d.dayIndex}');
        }
      }
      // Le type des journées du bloc est celui de ses semaines de
      // construction (B3, S21 : J1 tirage, force).
      final b3 = imp.segmentOf(21)!;
      final j1 = b3.block.pass1.days.firstWhere((d) => d.dayIndex == 0);
      expect(dayTypeLabel(j1.type), 'Tirage — force');
      final out = app.exportAll();
      expect(out, isNot(contains('"patterns"')));
      expect(
        jsonEncode((jsonDecode(out) as Map<String, dynamic>)['logs']),
        before,
      );
      expect(app.planProgram, isNull);
    });

    test('Koach (bascule forcée) : référence sans type, signature de '
        'dev7.0.0, aucune nouvelle référence', () async {
      await _owner(app);
      app.koachForceBascule(civilOf(clock));
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.snap, isNotNull, reason: '${e.blocked}');
      List<Map<String, Object?>> refs() => [
        for (final x in e.journal)
          if (x['type'] == 'reference') x,
      ];
      expect(refs(), hasLength(1));
      for (final b in refs().single['blocs']! as List) {
        for (final d in ((b as Map)['pass1'] as Map)['days'] as List) {
          expect((d as Map).containsKey('type'), isFalse);
        }
      }
      final imp = app.importedProgram!;
      final old = fnv1a32(
        jsonEncode([
          [for (final s in imp.segments) s.first - 1],
          app.importedLastWeek,
          [for (final s in imp.segments) _withoutTypes(s.block).toJson()],
        ]),
      ).toString();
      expect(e.refSig, old);
      expect(
        jsonEncode(refs().single['blocs']),
        jsonEncode([
          for (final s in imp.segments) _withoutTypes(s.block).toJson(),
        ]),
      );
      await app.koachRefresh();
      expect(refs(), hasLength(1));
    });
  });

  group('programme créé', () {
    test('profil street 50 / 50 à 6 séances : gabarit et types écrits par '
        'kalis_plan 0.4.1, affichés ; durée sur le temps disponible', () async {
      clock = DateTime(2026, 10, 5, 9); // lundi
      _save(app, _street5050(civilOf(clock)));
      expect(PlanStore(app).planCoachEligible, isTrue);
      _create(app);
      final plan = app.planProgram!;
      final block = plan.blocks.single.block;
      expect(isCoachBlock(block), isTrue);
      final split = block.pass1.split;
      expect(split, isNotNull);
      expect(split!.reasons.map((r) => r.code), contains('plan.split_chosen'));
      final qualities = <kc.DayQuality>{};
      for (final d in block.pass1.days) {
        expect(d.type, isNotNull, reason: 'jour ${d.dayIndex}');
        qualities.add(d.type!.quality);
      }
      expect(
        qualities,
        containsAll([kc.DayQuality.force, kc.DayQuality.endurance]),
      );
      expect(plan.eventsKey, planEventsKey(app.athlete!.profile.events));
      // Affichage : chaque journée d'entraînement de la semaine 1 porte
      // son type (JSON de la semaine), sans déduction depuis son titre.
      final labels = <String>[];
      final durations = <String>[];
      for (final d in app.program.week(1).days) {
        if (d.exercises.isEmpty) {
          expect(app.dayTypeLabelOf(d), isNull);
          continue;
        }
        expect(d.type, isNotNull);
        expect(d.minutes, 120);
        final l = app.dayTypeLabelOf(d);
        expect(l, dayTypeLabel(d.type));
        labels.add('J${d.j} ${d.title} : $l');
        durations.add(app.dayDurationText(d));
      }
      expect(labels, hasLength(6));
      // C17.15 (a) : la séance tient sous les 120 min disponibles ;
      // l'affichage le dit, rien n'est ajouté.
      expect(durations.any((t) => t.endsWith('sur 120 disponibles')), isTrue);
      final rendered = reasonText(
        split.reasons.firstWhere((r) => r.code == 'plan.split_chosen'),
        exerciseName: (id) => id,
      );
      expect(rendered, startsWith('Semaine construite en '));
      // ignore: avoid_print
      print(
        'KS1A|gabarit|${split.templateId}|$rendered\n'
        'KS1A|types|${labels.join(' / ')}\n'
        'KS1A|durees|${durations.join(' / ')}',
      );
    });

    test('durée : rien de plus quand le créneau n’est pas plus long que la '
        'séance', () {
      final d = DayPlan.fromJson({
        'j': 1,
        'title': 'TIRAGE',
        'minutes': 45,
        'exercises': <Object?>[],
      });
      expect(d.minutes, 45);
      final e = TrainingEstimate()..work = const Span.exact(50 * 60);
      expect(app.dayAvailableMinutes(d, e), isNull);
      final e2 = TrainingEstimate()..work = const Span.exact(30 * 60);
      expect(app.dayAvailableMinutes(d, e2), 45);
      final imported = DayPlan.fromJson({
        'j': 1,
        'title': 'TIRAGE',
        'exercises': <Object?>[],
      });
      expect(imported.minutes, isNull);
      expect(app.dayAvailableMinutes(imported, e2), isNull);
    });

    test('changement d’échéance : le bloc suivant commence au début du bloc '
        'en cours + ses semaines entières servies ; le bloc en cours est '
        'tronqué', () async {
      clock = DateTime(2026, 10, 5, 9); // lundi
      final p0 = _street5050(civilOf(clock));
      _save(app, p0);
      _create(app);
      final plan0 = app.planProgram!;
      final prev = plan0.blocks.single.block;
      final weeks0 = prev.pass1.weeks;
      expect(weeks0, greaterThanOrEqualTo(3));
      expect(PlanStore(app).planDeadlineChanged, isFalse);
      final start = app.program.start!;
      // Milieu de la semaine 2 du programme.
      clock = DateTime(start.year, start.month, start.day + 10, 9);
      expect(PlanStore(app).planDeadlineChanged, isFalse);
      expect(PlanStore(app).planNextFirstWeek, weeks0 + 1);
      // L'athlète avance son échéance de six semaines.
      final ev = p0.events!.single;
      _save(
        app,
        p0.copyWith(
          events: [ev.copyWith(date: ev.date.addDays(-42))],
        ),
      );
      expect(PlanStore(app).planDeadlineChanged, isTrue);
      expect(PlanStore(app).planNextFirstWeek, 3);
      final p = PlanStore(app).proposeNextBlock()!;
      expect(p.request.startDate, prev.pass1.startDate.addDays(14));
      expect(kp.servedWeeksOf(prev, p.request.startDate), 2);
      final c = PlanStore(app).newNextBlockCreation(journal: false)!;
      expect(c.startDate, prev.pass1.startDate.addDays(14));
      c.createPass2();
      PlanStore(app).applyNextBlockCreation(c);
      final plan = app.planProgram!;
      expect(plan.blocks, hasLength(2));
      expect(plan.blocks.first.weeks, 2);
      expect(plan.blocks.first.block.pass2.weeks, hasLength(2));
      expect(
        plan.blocks.last.block.pass1.startDate,
        prev.pass1.startDate.addDays(14),
      );
      expect(plan.blockFirstWeek(1), 3);
      expect(app.program.weeks.length, 2 + c.plan.weeks);
      expect(PlanStore(app).planDeadlineChanged, isFalse);
      expect(plan.eventsKey, planEventsKey(app.athlete!.profile.events));
      // Relu à l'identique.
      final again = PlanProgram.fromJson(jsonDecode(jsonEncode(plan.toJson())));
      expect(again.eventsKey, plan.eventsKey);
      expect(again.blocks.first.weeks, 2);
      // ignore: avoid_print
      print(
        'KS1A|echeance|bloc1=${prev.pass1.startDate.iso}+$weeks0 sem|'
        'servies=2|bloc2=${plan.blocks.last.block.pass1.startDate.iso}',
      );
    });
  });
}
