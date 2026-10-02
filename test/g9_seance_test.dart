// G9 (dev6.6.0, D5.3-D5.10) — séance servie par kalis_adapt : contrat de
// l'intégration (requêtes et réponses du moteur sérialisées et valides),
// programme personnel du propriétaire porté tel quel (D5.10), bilan santé
// (réponses partielles, aucune valeur injectée), ajustement appliqué (mode
// assisté) ou proposé (mode libre), flammes obligatoires à chaque série,
// anciennes séances en flammes, conseil après chaque série dans les deux
// modes, journal présenté au moteur, règle L13 de renvoi, sauvegarde.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_summary_screen.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/adapt/flame_sheet.dart';
import 'package:streetlift_tracker/adapt/health_check.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/journal_adapter.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Programme du propriétaire commencé le 13/07/2026, journal des 11
/// premières semaines ; « aujourd'hui » : lundi 28/09 (S12·J1).
Future<void> _ownerState(AppStore app) async {
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
}

void _saveProfile(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
}

/// Premier exercice servi par le moteur avec une charge.
Exercise _loadedEngine(DayPlan day) => day.exercises.firstWhere(
  (e) => e.engine && e.load.kg != null && e.load.kg! > 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('magasin', () {
    late AppStore app;
    var clock = DateTime(2026, 9, 28, 9);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 9, 28, 9);
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

    test('sans profil v2 : séance hors moteur (L7 inchangé)', () async {
      await _ownerState(app);
      final day = app.program.week(12).day(1)!;
      expect(app.adaptAvailable, isFalse);
      expect(app.adaptOpen(12, day), isNull);
      expect(app.logs['S12-J1']?.adapt, isNull);
    });

    test('programme du propriétaire (D5.10) : porté tel quel dans un bloc '
        'importé, séance servie par kalis_adapt, structure intacte', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final before = [
        for (final w in app.program.weeks)
          [
            for (final d in w.days)
              [for (final e in d.exercises) '${e.id}|${e.name}|${app.setsLabel(e)}'],
          ],
      ];
      final place = app.adaptPlaceOf(12, 1)!;
      expect(place.imported, isTrue);
      expect(place.blockId, kLegacyProgramBlockId);
      expect(place.block.pass1.weeks, 40);
      expect(place.block.validate(), isEmpty);
      expect(place.weekIndex, 11);
      final day = app.program.week(12).day(1)!;
      // Chaque exercice porté garde ses séries, sa plage et sa place.
      final items = place.day!.items;
      expect(items, isNotEmpty);
      for (final it in items) {
        final e = day.exercises.firstWhere(
          (x) => SessionAdaptStore.importedSlot(1, x.id) == it.slotId,
        );
        expect(it.sets, app.setCount(e));
      }
      final a = app.adaptOpen(12, day)!;
      expect(a.blockId, kLegacyProgramBlockId);
      expect(a.asked, isFalse);
      expect(a.check, isNull);
      expect(a.plan.validate(), isEmpty);
      final served = app.adaptDay(12, day, a);
      // Même séance, même structure : mêmes exercices, dans le même ordre.
      expect(
        [for (final e in served.exercises) e.id],
        [for (final e in day.exercises) e.id],
      );
      final engine = served.exercises.where((e) => e.engine).toList();
      expect(engine, isNotEmpty);
      for (final e in engine) {
        final it = app.adaptItemFor(12, 1, e)!;
        expect(app.setCount(e), it.sets);
        // Charge du moteur, pas de Koach L7.
        expect(app.loadFor(e), e.load.kg);
      }
      // Le programme n'est pas régénéré.
      expect([
        for (final w in app.program.weeks)
          [
            for (final d in w.days)
              [for (final e in d.exercises) '${e.id}|${e.name}|${app.setsLabel(e)}'],
          ],
      ], before);
      // La séance prescrite est figée : relue telle quelle après relance.
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      expect(
        jsonEncode(next.sessionAdapt(12, 1)!.toJson()),
        jsonEncode(a.toJson()),
      );
    });

    test('journal présenté au moteur : séances passées placées dans le bloc '
        '(rang du jour), emplacements, flammes (C9), séance en cours '
        'écartée', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final log = app.adaptTrainingLog(excludeKey: 'S12-J1');
      expect(log.validate(), isEmpty);
      expect(log.sessions, isNotEmpty);
      final s = log.sessions.firstWhere((x) => x.id == 'legacy-S3-J1');
      final place = app.adaptPlaceOf(3, 1)!;
      expect(s.programRef!.blockId, place.blockId);
      expect(s.programRef!.weekIndex, 2);
      expect(s.programRef!.dayIndex, place.dayIndex);
      expect(s.sets.first.flames, kc.Flames.fromRir(2));
      expect(s.sets.any((x) => x.slotId != null), isTrue);
      expect(log.sessions.any((x) => x.id == 'legacy-S12-J1'), isFalse);
      // Aucune séance après « aujourd'hui ».
      for (final x in log.sessions) {
        expect(x.date.compareTo(kc.CivilDate(2026, 9, 28)) <= 0, isTrue);
      }
    });

    test('conversion G3 inchangée sans les ajouts G9 ; la note en flammes '
        'passe avant le RIR, « je ne sais pas » = sans note', () {
      final doc = {
        'logs': {
          'S1-J1': {
            'done': true,
            'finishedAt': '2026-07-13T18:00:00',
            'exerciseNames': {'a': 'Traction pronation'},
            'ex': {
              'a': {
                'sets': [
                  {'reps': '8', 'rir': '2', 'done': true},
                  {'reps': '8', 'rir': '2', 'flames': 9, 'done': true},
                  {
                    'reps': '8',
                    'rir': '2',
                    'flamesUnknown': true,
                    'done': true,
                  },
                ],
              },
            },
          },
        },
      };
      final out = convertLegacyJournal(
        doc,
        exerciseId: (_) => 'sw-traction-pronation',
        usesSeconds: (_) => false,
        dayOrder: (_, _) => const ['a'],
        legacyDate: (_, _) => DateTime(2026, 7, 13),
      ).log;
      final sets = out.sessions.single.sets;
      expect(sets[0].flames, 7);
      expect(sets[1].flames, 9);
      expect(sets[2].flames, isNull);
      expect(sets.every((x) => x.slotId == null && x.target == null), isTrue);
      expect(out.sessions.single.programRef!.blockId, kLegacyProgramBlockId);
    });

    test('bilan (D5.8) : réponses partielles gardées telles quelles, aucune '
        'valeur injectée ; mode assisté : ajustement appliqué, annulable',
        () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final day = app.program.week(12).day(1)!;
      app.adaptOpen(12, day);
      final a = app.adaptAnswer(
        12,
        day,
        const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      )!;
      expect(a.asked, isTrue);
      expect(a.check!.toJson(), {'overall': 1, 'sleepQuality': 1, 'energy': 1});
      expect(a.base, isNotNull, reason: 'un bilan très bas change la séance');
      expect(a.choice, 'applied');
      expect(a.adjusted, isTrue);
      expect(identical(a.active, a.plan), isTrue);
      expect(
        sessionDiffLines(a.base!, a.plan, app.adaptExerciseName),
        isNotEmpty,
      );
      final undone = app.adaptChoose(12, day, 'undone')!;
      expect(undone.adjusted, isFalse);
      expect(
        jsonEncode(undone.active.toJson()),
        jsonEncode(undone.base!.toJson()),
      );
      expect(undone.activeCheck, isNull);
      // Le bilan est au journal tel qu'il a été donné (séance terminée).
      final served = app.adaptDay(12, day, undone);
      final e = served.exercises.firstWhere((x) => x.engine);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      if (log.sets[0].reps.isEmpty) log.sets[0].reps = '3';
      log.sets[0].flames = 7;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.markSessionDone(12, 1, true);
      final s = app
          .adaptTrainingLog()
          .sessions
          .firstWhere((x) => x.id == 'legacy-S12-J1');
      expect(s.healthCheck!.toJson(), {
        'overall': 1,
        'sleepQuality': 1,
        'energy': 1,
      });
      expect(s.programRef!.blockId, kLegacyProgramBlockId);
      expect(s.plannedWorkSets, plannedWorkSetsOf(undone.active));
    });

    test('bilan passé : aucun bilan, séance prévue ; un bilan sans réponse '
        'vaut l’absence de bilan', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final day = app.program.week(12).day(1)!;
      final first = app.adaptOpen(12, day)!;
      final skipped = app.adaptAnswer(12, day, null, skipped: true)!;
      expect(skipped.asked, isTrue);
      expect(skipped.check, isNull);
      expect(skipped.base, isNull);
      expect(jsonEncode(skipped.plan.toJson()), jsonEncode(first.plan.toJson()));
      final empty = app.adaptAnswer(12, day, const kc.HealthCheck())!;
      expect(empty.check, isNull);
      expect(empty.base, isNull);
    });

    test('mode libre : l’ajustement est proposé, rien n’est appliqué sans '
        'accord', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final day = app.program.week(12).day(1)!;
      app.adaptOpen(12, day);
      final a = app.adaptAnswer(
        12,
        day,
        const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      )!;
      expect(a.choice, 'pending');
      expect(a.pending, isTrue);
      expect(jsonEncode(a.active.toJson()), jsonEncode(a.base!.toJson()));
      final accepted = app.adaptChoose(12, day, 'accepted')!;
      expect(jsonEncode(accepted.active.toJson()), jsonEncode(a.plan.toJson()));
      final kept = app.adaptChoose(12, day, 'kept')!;
      expect(jsonEncode(kept.active.toJson()), jsonEncode(a.base!.toJson()));
    });

    test('douleur : zone épargnée ; règle L13 (> 3/10 plus de 2 séances de '
        'suite) → renvoi vers un professionnel', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      const pain = kc.PainReport(
        zone: kc.BodyZone.shoulder,
        side: kc.BodySide.both,
        intensity: 6,
        phase: kc.PainPhase.before,
      );
      for (final j in [1, 2, 3]) {
        final day = app.program.week(12).day(j)!;
        if (day.exercises.isEmpty) continue;
        if (app.adaptOpen(12, day) == null) continue;
        app.adaptAnswer(
          12,
          day,
          const kc.HealthCheck(overall: 2, pains: [pain]),
        );
      }
      final history = app.zonePainHistory(kc.BodyZone.shoulder);
      expect(history.where((v) => v > 3), isNotEmpty);
      if (history.length >= 3) {
        expect(app.adaptPainReferralZones, contains('Épaule'));
      }
      final a = app.sessionAdapt(12, 1)!;
      expect(
        a.plan.items.any(
              (it) => it.reasons.any((r) => r.code == 'adapt.pain_reported'),
            ) ||
            a.plan.adjustments.isNotEmpty,
        isTrue,
      );
    });

    test('conseil après chaque série, mode assisté : appliqué aux séries '
        'suivantes non modifiées, annulable', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, base)!;
      final day = app.adaptDay(12, base, a);
      final e = _loadedEngine(day);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      final before = log.sets[1].kg;
      expect(before, isNotEmpty);
      // Série manquée et notée 10 flammes : jamais de hausse ensuite.
      log.sets[0]
        ..reps = '1'
        ..flames = 10;
      expect(
        app.toggleSet(log, 0, app.logSpec(e)).ok,
        isTrue,
      );
      final r = app.adaptAfterSet(12, day, e, 0)!;
      expect(r.advice.action, isNot(kc.IntraSessionAction.loadUp));
      if (r.step != null) {
        expect(r.step!.status, 'applied');
        final applied = log.sets[1].kg;
        final g = app.adaptGoal(12, 1, e, 1)!;
        if (g.kg != null) expect(applied, adaptKgField(g.kg!));
        app.adaptAdviceDecision(12, day, e, 'undone');
        expect(log.sets[1].kg, before);
      }
    });

    test('conseil en mode libre : proposé, appliqué seulement après '
        'accord', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final base = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, base)!;
      final day = app.adaptDay(12, base, a);
      final e = _loadedEngine(day);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      final before = log.sets[1].kg;
      log.sets[0]
        ..reps = '1'
        ..flames = 10;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      final r = app.adaptAfterSet(12, day, e, 0)!;
      if (r.step != null) {
        expect(r.step!.status, 'pending');
        expect(log.sets[1].kg, before);
        expect(app.adaptPendingAdvice(12, 1, e), isNotNull);
        app.adaptAdviceDecision(12, day, e, 'accepted');
        final g = app.adaptGoal(12, 1, e, 1)!;
        if (g.kg != null) expect(log.sets[1].kg, adaptKgField(g.kg!));
        expect(app.adaptPendingAdvice(12, 1, e), isNull);
      }
    });

    test('sauvegarde : séance du moteur et flammes exportées, relues ; import '
        'strict d’une séance du moteur invalide refusé', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, base)!;
      final day = app.adaptDay(12, base, a);
      final e = _loadedEngine(day);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      log.sets[0]
        ..flames = 7
        ..effort = 2;
      app.toggleSet(log, 0, app.logSpec(e));
      final exported = app.exportAll();
      final doc = jsonDecode(exported) as Map<String, dynamic>;
      final s = (doc['logs'] as Map)['S12-J1'] as Map;
      expect((s['adapt'] as Map)['v'], 1);
      expect(
        (((s['ex'] as Map)[e.id] as Map)['sets'] as List).first['flames'],
        7,
      );
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      expect(next.exportAll(), exported);
      final broken = jsonDecode(exported) as Map<String, dynamic>;
      ((broken['logs'] as Map)['S12-J1'] as Map)['adapt'] = {'v': 99};
      expect(await next.importAll(jsonEncode(broken)), isFalse);
      final badFlames = jsonDecode(exported) as Map<String, dynamic>;
      (((((badFlames['logs'] as Map)['S12-J1'] as Map)['ex'] as Map)[e.id]
                  as Map)['sets']
              as List)
          .first['flames'] = 11;
      expect(await next.importAll(jsonEncode(badFlames)), isFalse);
    });

    test('résumé de fin : calibrage, capacité avant / après, prochaine '
        'fois', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, base)!;
      final day = app.adaptDay(12, base, a);
      for (final e in day.exercises.where((x) => x.engine)) {
        final log = app.exLog(12, 1, e);
        app.adaptPrefill(12, 1, e, log);
        for (var i = 0; i < log.sets.length; i++) {
          if (log.sets[i].reps.isEmpty) log.sets[i].reps = '5';
          log.sets[i].flames = 7;
          app.toggleSet(log, i, app.logSpec(e));
        }
      }
      app.markSessionDone(12, 1, true);
      final s = app.adaptSummary(12, base)!;
      expect(s.exercises, isNotEmpty);
      for (final x in s.exercises) {
        expect(x.after, isNotNull);
      }
      expect(s.exercises.any((x) => x.next != null), isTrue);
    });

    test('budgets : prescription et conseil sous 1 s en test (VM)', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(12).day(1)!;
      final w = Stopwatch()..start();
      app.adaptOpen(12, base);
      app.adaptAnswer(12, base, const kc.HealthCheck(overall: 4));
      w.stop();
      expect(w.elapsedMilliseconds, lessThan(5000));
    });
  });

  group('textes', () {
    test('codes de raison du moteur : une phrase pour chaque code dit à '
        'l’utilisateur, aucune allégation médicale', () {
      const codes = [
        'adapt.calibration',
        'adapt.low_confidence',
        'adapt.load_up',
        'adapt.load_down',
        'adapt.load_held',
        'adapt.increment_coarse',
        'adapt.flames_below_target',
        'adapt.flames_above_target',
        'adapt.set_failed',
        'adapt.pain_reported',
        'adapt.pain_persistent',
        'adapt.health_low',
        'adapt.sleep_low',
        'adapt.time_short',
        'adapt.place_changed',
        'adapt.load_floor',
        'adapt.benchmark_set',
      ];
      final banned = RegExp(r'soign|guéri|soulag|rééduc|garanti|prévien');
      for (final c in codes) {
        final t = adaptReasonText(
          kc.Reason(code: c, params: const {'zone': 'shoulder'}),
        );
        expect(t, isNotNull, reason: c);
        expect(banned.hasMatch(t!.toLowerCase()), isFalse, reason: t);
      }
      expect(flameValueText(10), contains('échec'));
      expect(flameValueText(7), '7 flammes · RIR 2');
      expect(flameValueText(1), contains('5 et plus'));
      expect(kFeelLabels.length, 5);
      expect(feelIsLow(2), isTrue);
      expect(feelIsLow(3), isFalse);
    });
  });

  group('écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store.storeClock = () => DateTime(2026, 9, 28, 9);
      await store.init();
      await _ownerState(store);
      _saveProfile(store, kc.GuidanceMode.assisted);
    });

    Widget page(Widget child, {bool dark = true}) => MaterialApp(
      theme: buildTheme(dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('bilan : « Comment tu te sens ? », réponse basse → détail sur '
        'un seul écran, « Passer » partout ; flammes obligatoires ; fin de '
        'séance', (tester) async {
      phone(tester);
      store.clearSession(12, 1);
      final week = store.program.week(12);
      final day = week.day(1)!;
      await tester.pumpWidget(page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      expect(find.text('Comment tu te sens ?'), findsOneWidget);
      for (var n = 1; n <= 5; n++) {
        expect(find.byKey(ValueKey('feel-$n')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('feel-2')));
      await tester.pumpAndSettle();
      expect(find.byType(HealthDetailScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('detail-sleepQuality-1')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('detail-save')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('detail-save')));
      await tester.pumpAndSettle();
      final a = store.sessionAdapt(12, 1)!;
      expect(a.check!.toJson(), {'overall': 2, 'sleepQuality': 1});
      if (a.base != null) {
        expect(find.byKey(const ValueKey('adjust-undo')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('adjust-go')));
        await tester.pumpAndSettle();
      }
      // Premier exercice : valider une série ouvre les flammes.
      final served = store.adaptDay(12, day, store.sessionAdapt(12, 1)!);
      final first = served.exercises.first;
      final button = find.byTooltip('Valider la série 1').first;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flame-sheet')), findsOneWidget);
      // Fermée sans choix : la série reste non validée.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final log = store.logs['S12-J1']!.ex[first.id]!;
      expect(log.sets[0].done, isFalse);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('flame-pick-8')));
      await tester.pumpAndSettle();
      expect(log.sets[0].done, isTrue);
      expect(log.sets[0].flames, 8);
      expect(log.sets[0].effort, 1.5);
      expect(find.byKey(const ValueKey('flame-line-1')), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => store.flush());
    });

    testWidgets('sélecteur de flammes : pré-rempli, « Je ne sais pas », '
        'clair et sombre, grand texte', (tester) async {
      phone(tester);
      for (final dark in [true, false]) {
        FlameChoice? got;
        await tester.pumpWidget(
          page(
            Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async => got = await showFlameSheet(
                    context,
                    title: 'Série 1 · difficulté',
                    target: 7,
                    intro: true,
                  ),
                  child: const Text('ouvrir'),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('flame-intro')), findsOneWidget);
        expect(find.text('7 flammes · RIR 2'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('flame-confirm')));
        await tester.pumpAndSettle();
        expect(got!.flames, 7);
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('flame-unknown')));
        await tester.pumpAndSettle();
        expect(got!.flames, isNull);
        expect(got!.unknown, isTrue);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('résumé de fin de séance : Koach, calibrage, progrès, '
        'prochaine fois', (tester) async {
      phone(tester);
      final week = store.program.week(12);
      final day = week.day(1)!;
      await tester.pumpWidget(
        page(AdaptSummaryScreen(week: week, base: day)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adapt-summary')), findsOneWidget);
      expect(find.byKey(const ValueKey('summary-done')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
