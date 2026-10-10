// G7 (dev6.5.0, D4, D4.9, D5.10) — création du programme avec kalis_plan :
// tests de contrat de l'intégration (INTEGRATION.md de kalis_core, § 4),
// déroulé de la création (propositions, revue : sais / sais pas / n'aime
// pas / ajout / retrait, verrous transmis au moteur, annulation), passe 2
// et ajustements bornés, instance active (mise en forme, sauvegarde,
// import strict), programme du propriétaire (semaines passées gardées,
// retour pendant 7 jours), « Où j'en suis » et séances « reprise »
// neutres, écrans. Données synthétiques ; horloge injectée ; stockage
// simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/plan/plan_creation.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/plan/plan_screens.dart';
import 'package:streetlift_tracker/plan/plan_texts.dart';
import 'package:streetlift_tracker/plan/program_position.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

Map<String, AthleteProfile> _fixtures() {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return {for (final f in readProfileFixtures(raw)) f.key: f.profile};
}

/// Aller-retour JSON d'une valeur du contrat : égalité et validité.
void _roundTrip<T>(
  T value,
  Map<String, Object?> Function(T) toJson,
  T Function(Map<String, Object?>) fromJson,
  List<Violation> Function(T) validate,
) {
  final text = jsonEncode(toJson(value));
  final back = fromJson((jsonDecode(text) as Map).cast<String, Object?>());
  expect(back, value);
  expect(jsonEncode(toJson(back)), text);
  expect(validate(back), isEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Catalog catalog;
  late Map<String, AthleteProfile> fixtures;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    catalog = store.content.catalog!;
    fixtures = _fixtures();
  });

  group('contrat (INTEGRATION.md § 4)', () {
    test('requêtes et réponses de kalis_plan : sérialisées, relues, égales, '
        'valides', () {
      final engine = KalisPlan();
      for (final key in [
        'debutant_forme_generale_maison_2x30',
        'street_streetlifting_4x90',
      ]) {
        final req = PlanRequest(
          profile: fixtures[key]!,
          seed: 0,
          startDate: CivilDate(2026, 10, 5),
          locks: const [],
        );
        _roundTrip(
          req,
          (v) => v.toJson(),
          PlanRequest.fromJson,
          (v) => v.validate(),
        );
        final p1 = engine.createPass1(catalog, req);
        _roundTrip(
          p1,
          (v) => v.toJson(),
          Pass1Plan.fromJson,
          (v) => v.validate(),
        );
        final slot = p1.days.first.slots.first.slotId;
        final vreq = VariantsRequest(request: req, current: p1, slotId: slot);
        _roundTrip(
          vreq,
          (v) => v.toJson(),
          VariantsRequest.fromJson,
          (v) => v.validate(),
        );
        final vs = engine.variants(catalog, vreq);
        _roundTrip(
          vs,
          (v) => v.toJson(),
          VariantSet.fromJson,
          (v) => v.validate(),
        );
        final rreq = ReviewRequest(
          request: req,
          current: p1,
          action: ReviewAction(kind: ReviewKind.cannotDo, slotId: slot),
        );
        _roundTrip(
          rreq,
          (v) => v.toJson(),
          ReviewRequest.fromJson,
          (v) => v.validate(),
        );
        final rr = engine.review(catalog, rreq);
        _roundTrip(
          rr,
          (v) => v.toJson(),
          ReviewResult.fromJson,
          (v) => v.validate(),
        );
        final p2req = Pass2Request(request: req, pass1: rr.plan);
        _roundTrip(
          p2req,
          (v) => v.toJson(),
          Pass2Request.fromJson,
          (v) => v.validate(),
        );
        final p2 = engine.createPass2(catalog, p2req);
        _roundTrip(
          p2,
          (v) => v.toJson(),
          Pass2Plan.fromJson,
          (v) => v.validate(),
        );
        final block = ProgramBlock(pass1: rr.plan, pass2: p2);
        _roundTrip(
          block,
          (v) => v.toJson(),
          ProgramBlock.fromJson,
          (v) => v.validate(),
        );
        expect(
          catalog.checkExerciseIds([
            for (final d in p1.days)
              for (final s in d.slots) s.exerciseId,
          ]),
          isEmpty,
        );
      }
    });
  });

  group('création', () {
    PlanCreation creation([
      String key = 'homme_25_musculation_debutant_3x60',
    ]) => PlanCreation(
      catalog: catalog,
      profile: fixtures[key]!,
      startDate: CivilDate(2026, 10, 5),
      journalOn: true,
    )..start();

    test('propositions : graine = rang, autre proposition différente, retour '
        'possible ; même profil, même programme', () {
      final c = creation();
      final first = jsonEncode(c.plan.toJson());
      expect(c.plan.seed, 0);
      c.otherProposal();
      expect(c.index, 1);
      expect(c.plan.seed, 1);
      expect(jsonEncode(c.plan.toJson()), isNot(first));
      c.previousProposal();
      expect(jsonEncode(c.plan.toJson()), first);
      expect(jsonEncode(creation().plan.toJson()), first);
      expect(c.journal.where((e) => e['op'] == 'createPass1'), hasLength(2));
    });

    test('revue : je sais faire verrouille, je ne sais pas faire et je '
        'n’aime pas remplacent et l’apprennent au profil, verrous transmis, '
        'annulation', () {
      final c = creation();
      final days = c.plan.days;
      final a = days.first.slots.first;
      c.canDo(a.slotId);
      expect(c.profile.knownExerciseIds, contains(a.exerciseId));
      expect(
        c.request().locks.any(
          (l) => l.kind == LockKind.keepSlot && l.slotId == a.slotId,
        ),
        isTrue,
      );
      expect(
        c.plan.days.first.slots.firstWhere((s) => s.slotId == a.slotId).locked,
        isTrue,
      );
      final b = c.plan.days.last.slots.last;
      final vs = c.variants(b.slotId);
      expect(vs.targeted.length, lessThanOrEqualTo(3));
      final choice = vs.targeted.isEmpty ? null : vs.targeted.first.exerciseId;
      final before = c.plan;
      final step = c.act(
        ReviewAction(kind: ReviewKind.cannotDo, slotId: b.slotId),
        then: choice == null
            ? null
            : ReviewAction(
                kind: ReviewKind.replace,
                slotId: b.slotId,
                replacementExerciseId: choice,
              ),
        label: 'Je ne sais pas faire',
      );
      expect(c.profile.cannotDoExerciseIds, contains(b.exerciseId));
      final ids = {
        for (final d in c.plan.days)
          for (final s in d.slots) s.exerciseId,
      };
      expect(ids, isNot(contains(b.exerciseId)));
      if (choice != null) expect(ids, contains(choice));
      expect(step.changes, isNotEmpty);
      // Le verrou du premier exercice tient toujours.
      expect(
        c.plan.days.first.slots.any(
          (s) => s.slotId == a.slotId && s.exerciseId == a.exerciseId,
        ),
        isTrue,
      );
      final undone = c.undo();
      expect(undone, same(step));
      expect(identical(c.plan, before), isTrue);
      expect(
        c.profile.cannotDoExerciseIds ?? const [],
        isNot(contains(b.exerciseId)),
      );
      final d2 = c.plan.days[1].slots.first;
      c.act(
        ReviewAction(kind: ReviewKind.dislike, slotId: d2.slotId),
        label: 'Je n’aime pas',
      );
      expect(c.profile.dislikedExerciseIds, contains(d2.exerciseId));
      final kept = c.plan.days[1].slots.first;
      c.act(
        ReviewAction(kind: ReviewKind.remove, slotId: kept.slotId),
        label: 'Retirer',
      );
      expect(c.plan.days[1].slots.any((s) => s.slotId == kept.slotId), isFalse);
      final add = catalog.exercises.firstWhere(
        (e) =>
            !c.plan.days.first.slots.any((s) => s.exerciseId == e.id) &&
            e.id.startsWith('mu-'),
      );
      c.act(
        ReviewAction(kind: ReviewKind.add, dayIndex: 0, exerciseId: add.id),
        label: 'Ajouter',
      );
      expect(
        c.plan.days.first.slots.any((s) => s.exerciseId == add.id && s.locked),
        isTrue,
      );
      expect(c.profile.likedExerciseIds, contains(add.id));
      expect(c.journal.where((e) => e['op'] == 'review'), isNotEmpty);
      // Après « Autre proposition » refusée : la revue a commencé.
      final n = c.proposals.length;
      c.otherProposal();
      expect(c.proposals.length, n);
    });

    test('passe 2 et ajustements bornés (refus expliqué)', () {
      final c = creation();
      final p2 = c.createPass2();
      expect(p2.weeks.length, c.plan.weeks);
      final effort = p2.weeks
          .expand((w) => w.days)
          .expand((d) => d.items)
          .firstWhere(
            (i) =>
                i.targetFlames != null && i.kind == null && i.repsLow != null,
          );
      expect(
        c.setAdjust(
          effort.slotId,
          const PlanAdjust(setsDelta: 1),
          cautious: false,
        ),
        isNull,
      );
      expect(c.adjust[effort.slotId]!.setsDelta, 1);
      final refused = c.setAdjust(
        effort.slotId,
        const PlanAdjust(setsDelta: 2),
        cautious: false,
      );
      expect(refused, contains('une série de plus'));
      expect(c.adjust[effort.slotId]!.setsDelta, 1);
      expect(
        c.setAdjust(
          effort.slotId,
          const PlanAdjust(restDelta: -45),
          cautious: false,
        ),
        contains('30 s'),
      );
      expect(
        c.setAdjust(
          effort.slotId,
          const PlanAdjust(repsShift: 3),
          cautious: false,
        ),
        isNotNull,
      );
      final cautious = c.setAdjust(
        effort.slotId,
        const PlanAdjust(setsDelta: 1),
        cautious: true,
      );
      if (effort.sets >= 3) expect(cautious, contains('prudent'));
      final e = c.entry('2026-10-01T10:00:00');
      final w = adjustedDays(e, 1);
      final item = w
          .expand((d) => d.items)
          .firstWhere((i) => i.slotId == effort.slotId, orElse: () => effort);
      if (item.kind == null && item.setTargets == null) {
        final raw = p2.weeks[1].days
            .expand((d) => d.items)
            .firstWhere((i) => i.slotId == effort.slotId);
        expect(item.sets, raw.sets + 1);
      }
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

    PlanCreation validated(AppStore s) {
      final c = PlanStore(s).newPlanCreation(journal: false)!;
      c.start();
      c.canDo(c.plan.days.first.slots.first.slotId);
      c.createPass2();
      return c;
    }

    test(
      'installation neuve : le programme validé devient l’instance active '
      '(accueil, calendrier, séances), sauvegardé, relu à l’identique',
      () async {
        app.seedSampleAthleteProfile();
        expect(app.program.start, isNull);
        final s = PlanStore(app).planStartFor();
        expect(s.firstWeek, 1);
        expect(s.replacing, isFalse);
        expect(s.start, CivilDate(2026, 10, 1));
        final c = validated(app);
        PlanStore(app).applyPlanCreation(c);
        expect(PlanStore(app).programPlanned, isTrue);
        expect(app.program.start, DateTime(2026, 10, 1));
        expect(app.program.weeks, hasLength(c.plan.weeks));
        // J1 = jeudi 1er octobre ; le lundi est J5, le mercredi J7.
        final firstDay = c.plan.days.first;
        expect(planJ(firstDay.weekday, 4), greaterThanOrEqualTo(1));
        final day = app.program.week(1).day(planJ(firstDay.weekday, 4))!;
        final items = c.pass2!.weeks.first.days.first.items;
        expect(day.exercises, hasLength(items.length));
        expect(
          day.exercises.first.name,
          catalog.find(items.first.exerciseId)!.name,
        );
        expect(app.program.week(1).block, startsWith('Bloc 1'));
        final exported = app.exportAll();
        final doc = jsonDecode(exported) as Map<String, dynamic>;
        expect(doc['planProgram'], isA<Map>());
        expect(doc.containsKey('programInstance'), isFalse);
        final next = await relaunch();
        expect(next.exportAll(), exported);
        expect(next.program.weeks.length, app.program.weeks.length);
        // Profil : ce que la revue a appris.
        expect(
          next.athlete!.profile.knownExerciseIds,
          contains(c.plan.days.first.slots.first.exerciseId),
        );
        // Import strict d'une section invalide : refusé ; démarrage tolérant.
        final broken = jsonDecode(exported) as Map<String, dynamic>;
        (broken['planProgram'] as Map)['firstWeek'] = 0;
        expect(await next.importAll(jsonEncode(broken)), isFalse);
        expect(
          () => PlanProgram.fromJson(broken['planProgram']),
          throwsFormatException,
        );
      },
    );

    test('programme du propriétaire : semaines passées gardées, nouveau '
        'programme à la semaine suivante, retour pendant 7 jours, refusé '
        'après une séance du nouveau', () async {
      final filled = filledBackup(app);
      final logs = (filled['logs'] as Map).cast<String, dynamic>();
      logs.removeWhere((k, _) {
        final w = int.parse(k.substring(1, k.indexOf('-')));
        return w >= 12;
      });
      filled['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      app.seedSampleAthleteProfile();
      final template = [
        for (final w in app.program.weeks.take(12))
          [
            for (final d in w.days)
              '${d.title}|${[for (final e in d.exercises) '${e.id}:${e.name}:${e.sets.value}'].join(',')}',
          ],
      ];
      final logsBefore = jsonEncode(jsonDecode(app.exportAll())['logs']);
      final xp = app.progression.totalXp;
      final s = PlanStore(app).planStartFor();
      expect(s.replacing, isTrue);
      expect(s.firstWeek, 13);
      expect(s.start, CivilDate(2026, 10, 5));
      final c = validated(app);
      PlanStore(app).applyPlanCreation(c);
      expect(app.program.start, DateTime(2026, 7, 13));
      expect(app.program.weeks.length, 12 + c.plan.weeks);
      for (var n = 1; n <= 12; n++) {
        expect(
          [
            for (final d in app.program.week(n).days)
              '${d.title}|${[for (final e in d.exercises) '${e.id}:${e.name}:${e.sets.value}'].join(',')}',
          ],
          template[n - 1],
          reason: 'semaine $n',
        );
      }
      expect(app.program.week(13).block, startsWith('Bloc 1'));
      expect(jsonEncode(jsonDecode(app.exportAll())['logs']), logsBefore);
      expect(app.progression.totalXp, xp);
      expect(PlanStore(app).planCanUndo, isTrue);
      // Retour à l'ancien programme : identique.
      expect(PlanStore(app).undoPlanProgram(), isTrue);
      expect(PlanStore(app).programPlanned, isFalse);
      expect(app.program.weeks, hasLength(40));
      expect(app.program.start, DateTime(2026, 7, 13));
      // Nouveau programme puis une séance saisie : retour refusé.
      PlanStore(app).applyPlanCreation(validated(app));
      final j = app.program
          .week(13)
          .days
          .firstWhere((d) => d.exercises.isNotEmpty)
          .j;
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      (doc['logs'] as Map)['S13-J$j'] = {
        'done': true,
        'finishedAt': '2026-10-06T18:00:00',
        'ex': <String, dynamic>{},
      };
      expect(await app.importAll(jsonEncode(doc)), isTrue);
      expect(PlanStore(app).programPlanned, isTrue);
      expect(PlanStore(app).planCanUndo, isFalse);
      clock = DateTime(2026, 10, 20, 9);
      expect(PlanStore(app).planCanUndo, isFalse);
    });

    test('« Où j’en suis » : séances d’avant marquées « reprise », neutres ; '
        'XP et niveau inchangés ; journal des moteurs', () async {
      final filled = filledBackup(app);
      final logs = (filled['logs'] as Map).cast<String, dynamic>();
      logs.removeWhere((k, _) {
        final w = int.parse(k.substring(1, k.indexOf('-')));
        return w >= 3;
      });
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      final xp = app.progression.totalXp;
      final level = app.level;
      final statsBefore = jsonEncode(jsonDecode(app.exportAll())['logs']);
      PlanStore(app).setProgramPosition(6, 1);
      expect(PlanStore(app).programPosition, (week: 6, day: 1));
      final r = app.programResume!;
      expect(r.keys, isNotEmpty);
      expect(r.keys.every((k) => !logs.containsKey(k)), isTrue);
      for (final w in [3, 4, 5]) {
        for (final d in app.program.week(w).days) {
          if (d.exercises.isEmpty) continue;
          expect(
            PlanStore(app).isResume(w, d.j),
            isTrue,
            reason: 'S$w-J${d.j}',
          );
          expect(app.isDone(w, d.j), isFalse);
        }
      }
      // Les séances saisies restent réelles ; la séance choisie n'est pas
      // marquée.
      final logged = app.program
          .week(1)
          .days
          .firstWhere((d) => d.exercises.isNotEmpty);
      expect(PlanStore(app).isResume(1, logged.j), isFalse);
      expect(PlanStore(app).isResume(6, 1), isFalse);
      expect(app.progression.totalXp, xp);
      expect(app.level, level);
      expect(jsonEncode(jsonDecode(app.exportAll())['logs']), statsBefore);
      final core = app.coreTrainingLog().log;
      final resumed = core.sessions.where((s) => s.resume).toList();
      expect(resumed.length, r.keys.length);
      expect(resumed.every((s) => s.sets.isEmpty && !s.completed), isTrue);
      final next = await relaunch();
      expect(next.programResume!.toJson(), r.toJson());
      expect(PlanStore(next).isResume(3, logged.j), isTrue);
      // Une séance « reprise » saisie plus tard redevient réelle.
      final doc = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      (doc['logs'] as Map)['S3-J${logged.j}'] = {
        'done': true,
        'finishedAt': '2026-10-01T18:00:00',
        'ex': <String, dynamic>{},
      };
      expect(await next.importAll(jsonEncode(doc)), isTrue);
      expect(PlanStore(next).isResume(3, logged.j), isFalse);
    });

    test('textes : tous les codes de raison du plan ont une phrase', () {
      for (final spec in reasonRegistry) {
        final code = spec.code;
        if (!code.startsWith('plan.')) continue;
        final t = reasonText(
          Reason(code: code, params: const {}),
          exerciseName: (id) => id,
        );
        expect(t, isNot('Choix du moteur.'), reason: code);
      }
    });
  });

  group('écrans', () {
    Widget page(Widget child, {bool dark = true}) => MaterialApp(
      theme: buildTheme(dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f.hitTestable().last);
      await tester.pumpAndSettle();
    }

    testWidgets('création complète : passe 1, autre proposition, revue (sais, '
        'sais pas + variante, diff, annulation), récapitulatif, passe 2, '
        'ajustement refusé, validation', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({});
      await store.eraseAllData();
      store.storeClock = () => DateTime(2026, 10, 1, 9);
      store.seedSampleAthleteProfile();
      await tester.pumpWidget(page(const PlanCreationScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('plan-pass1')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-pass1-koach')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-day-0')), findsOneWidget);
      final state = tester.state<PlanCreationScreenState>(
        find.byType(PlanCreationScreen),
      );
      await tap(tester, 'plan-other');
      expect(state.c!.index, 1);
      await tap(tester, 'plan-previous');
      expect(state.c!.index, 0);
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('plan-week-overview')),
      );
      await tap(tester, 'plan-review');
      expect(find.byKey(const ValueKey('plan-review-pages')), findsOneWidget);
      await tap(tester, 'plan-can-do');
      expect(state.c!.steps, hasLength(1));
      await tap(tester, 'plan-cannot-do');
      expect(find.byKey(const ValueKey('variants-sheet')), findsOneWidget);
      await tap(tester, 'variants-koach');
      expect(find.byKey(const ValueKey('step-sheet')), findsOneWidget);
      expect(state.c!.steps, hasLength(2));
      await tap(tester, 'step-undo');
      expect(state.c!.steps, hasLength(1));
      await tap(tester, 'plan-review-recap');
      expect(find.byKey(const ValueKey('plan-recap')), findsOneWidget);
      await tap(tester, 'plan-validate-exercises');
      expect(find.byKey(const ValueKey('plan-pass2')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-pass2-koach')), findsOneWidget);
      final item = state.c!.pass2!.weeks.first.days.first.items.first;
      await tap(tester, 'plan-p2-${item.slotId}');
      expect(find.byKey(const ValueKey('adjust-sheet')), findsOneWidget);
      await tap(tester, 'adjust-sets-plus');
      await tap(tester, 'adjust-sets-plus');
      expect(find.byKey(const ValueKey('adjust-refused')), findsOneWidget);
      await tap(tester, 'adjust-done');
      await tap(tester, 'plan-validate');
      expect(PlanStore(store).programPlanned, isTrue);
      expect(store.program.start, DateTime(2026, 10, 1));
    });

    testWidgets('« Où j’en suis » : choix de la semaine et de la séance', (
      tester,
    ) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({});
      await store.eraseAllData();
      store.storeClock = () => DateTime(2026, 10, 1, 9);
      await store.importAll(jsonEncode(filledBackup(store)..['logs'] = {}));
      await tester.pumpWidget(page(const ProgramPositionScreen(), dark: false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('position-koach')), findsOneWidget);
      await tap(tester, 'position-week-plus');
      await tap(tester, 'position-confirm');
      expect(store.programResume, isNotNull);
    });
  });
}
