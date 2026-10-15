// CIF (dev6.18.0, pipeline CP, lot CI final, DECISIONS_CP.md C17) sur
// émulateur Android, lancé par tools/ci3d_drive.sh avec le build de
// développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/lot_cif_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// 1. Session personnelle : programme de 40 semaines du propriétaire commencé
//    il y a 19 semaines (S20·J1), profil avancé, mode assisté : myo-reps
//    notés mini-série par mini-série, bandeau à hauteur stable jusqu'au
//    dernier bloc (point 12), série validée, parties au journal du moteur
//    (point 2).
// 2. Session de test (5 appuis), profil street des fixtures (6 jours,
//    départ un lundi, horloge fixée) : bilan bas le jour d'un test (S4·J4),
//    test retiré ; séance de S4·J6 : test reporté servi (point 6).
// 3. Même session de test, compétiteur de streetlifting : écran du jour J,
//    une tentative notée ; gardée et écrite au journal (rôle `attempt`,
//    `eventId`) (point 1). Suppression de la session de test, session
//    personnelle intacte.
// Relevé `cif_releve_<partie>.json`, captures `cif_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/event_day_screen.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 9));

/// Profil street des fixtures du parcours v3 (`kalis_core`, données
/// synthétiques), recopié : les fixtures ne sont pas dans l'application.
const _streetWorkout =
    r"""{"schemaVersion":3,"sex":"male","birthYear":2001,"heightCm":172,"bodyWeightKg":66.0,"disciplines":{"primary":"street_workout","primaryPct":60,"secondaries":[{"discipline":"streetlifting","pct":20},{"discipline":"calisthenics","pct":20}]},"streetMode":{"primary":"sets_reps","streetliftingPct":20,"setsRepsPct":60,"calisthenicsPct":20},"movementLevels":[{"exerciseId":"sw-traction-pronation","measure":"max_reps","known":true,"low":26.0,"high":30.0},{"exerciseId":"sw-dips-barres-paralleles","measure":"max_reps","known":true,"low":45.0,"high":50.0},{"exerciseId":"sw-pompe","measure":"max_reps","known":true,"low":65.0,"high":75.0},{"exerciseId":"cd-muscle-up-barre-strict","measure":"max_reps","known":true,"low":10.0,"high":12.0}],"goals":[{"id":"g1","kind":"performance","origin":"user","createdOn":"2026-10-01","exerciseId":"sw-traction-pronation","metric":"max_reps","targetValue":35.0,"targetDate":"2027-05-22"}],"availability":[{"weekday":1,"minutes":75},{"weekday":3,"minutes":75},{"weekday":5,"minutes":75},{"weekday":7,"minutes":60}],"places":["exterieur"],"equipment":["barre fixe","barres parallèles","barre basse","élastique","gilet lesté","ceinture de lest","disques"],"loadIncrements":[{"loadType":"lest","stepKg":1.25},{"loadType":"barre","stepKg":2.5,"minKg":20.0},{"loadType":"halteres","stepKg":2.0,"minKg":2.0},{"loadType":"poulie","stepKg":2.5,"minKg":2.5}],"limitations":[],"likedExerciseIds":[],"dislikedExerciseIds":[],"experience":"advanced","guidanceMode":"assisted","healthScreening":{"questionnaireId":"kalis-sante-l13-v1","answeredOn":"2026-10-01","outcome":"standard"},"createdOn":"2026-10-01","updatedOn":"2026-10-01","trainingAge":"years_2_to_5","trainingGap":"none","sleep":"under_6_hours","stress":"moderate","occupationalLoad":"heavy","otherSports":[{"kind":"combat_sport","sessionsPerWeek":2,"minutesPerSession":90,"weekdays":[2,4],"hard":true}],"bodyWeightGoal":"maintain","benchmarks":[{"exerciseId":"sw-traction-pronation","kind":"max_reps","source":"declared","date":"2026-09-18","reps":28,"bodyWeightKg":66.0},{"exerciseId":"cd-muscle-up-barre-strict","kind":"max_reps","source":"declared","date":"2026-09-18","reps":11,"bodyWeightKg":66.0}],"events":[{"id":"e1","kind":"reps_competition","priority":"main","date":"2027-05-22","name":"Coupe d'endurance","mode":"for_time","stations":[{"exerciseId":"cd-muscle-up-barre-strict","reps":5,"unbroken":true},{"exerciseId":"sw-dips-barres-paralleles","reps":30},{"exerciseId":"sw-traction-pronation","reps":30},{"exerciseId":"sw-pompe","reps":30},{"exerciseId":"mu-air-squat","reps":20,"externalLoadKg":20.0}],"rounds":2,"timeLimitSeconds":600,"goalIds":["g1"],"heats":4,"restBetweenHeatsSeconds":900,"bestSeconds":512,"bestDate":"2026-05-23"}],"skills":[{"targetExerciseId":"cs-back-lever","currentExerciseId":"cs-back-lever-straddle","bestHoldSeconds":6,"atStepSince":"over_6_months"}],"weakPoints":[{"exerciseId":"sw-dips-barres-paralleles","kind":"late_set_fatigue"}],"recentTraining":[{"exerciseId":"sw-traction-pronation","sessionsPerWeek":3,"hardSets":"sets_15_to_20"},{"exerciseId":"sw-dips-barres-paralleles","sessionsPerWeek":3,"hardSets":"sets_15_to_20"},{"exerciseId":"cd-muscle-up-barre-strict","sessionsPerWeek":2,"hardSets":"sets_5_to_9"}],"currentPhase":"unstructured","lifestyleUpdatedOn":"2026-10-01"}""";

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
  };
  binding.reportData = data;

  void record() => data['cif_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['cif_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> opened(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
          i > 25) {
        break;
      }
    }
    await wait(tester, 1000);
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 120}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (final dy in const [-250.0, 250.0]) {
      for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
        final lists = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable();
        if (lists.evaluate().isEmpty) break;
        final s = tester.state<ScrollableState>(lists.last).position;
        if ((dy < 0 && s.pixels >= s.maxScrollExtent) ||
            (dy > 0 && s.pixels <= s.minScrollExtent)) {
          break;
        }
        await tester.drag(lists.last, Offset(0, dy));
        await wait(tester, 300);
      }
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.last);
      await wait(tester, 400);
    }
  }

  Future<void> tapF(WidgetTester tester, Finder f, {int ms = 800}) async {
    await scrollTo(tester, f);
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  Finder keyStarts(String prefix) => find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> && k.value.startsWith(prefix);
  });

  /// Séance ouverte, bilan passé, puis pages suivantes jusqu'à [target].
  Future<bool> openTo(WidgetTester tester, int w, int j, Finder target) async {
    final week = store.program.week(w);
    final day = week.day(j)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 800);
    final skip = find.byKey(const ValueKey('feel-skip'));
    if (skip.evaluate().isNotEmpty) await tapF(tester, skip, ms: 1200);
    final start = find.byKey(const ValueKey('bilan-start'));
    if (await until(tester, start, max: 40)) {
      await tapF(tester, start, ms: 1500);
    }
    for (var page = 1; page < 16 && target.evaluate().isEmpty; page++) {
      final pages = find.byType(PageView);
      if (pages.evaluate().isEmpty) break;
      final ctl = tester.widget<PageView>(pages.first).controller;
      if (ctl == null || !ctl.hasClients) break;
      ctl.jumpToPage(page);
      await wait(tester, 900);
    }
    return target.evaluate().isNotEmpty;
  }

  testWidgets('CIF $_part ($theme, $accent) : mini-séries, test reporté, '
      'jour J', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(
      DateTime(real.year, real.month, real.day - 19 * 7),
    );
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 140))),
          guidance: kc.GuidanceMode.assisted,
        ).copyWith(experience: kc.ExperienceLevel.advanced),
      )..consent = 'refused',
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );
    final now = store.storeClock();
    final w = store.program.weekFor(now);
    final j = store.program.offsetOf(now)! % 7 + 1;
    releve['jour'] = 'S$w-J$j';

    // 1. Mini-séries (points 2 et 12).
    final add = keyStarts('miniset-add-');
    releve['myo_page'] = await openTo(tester, w, j, find.text('CURL BARRE EZ'));
    await scrollTo(tester, add);
    final addKey = add.evaluate().isEmpty
        ? null
        : (tester.widget(add.first).key! as ValueKey<String>).value;
    final rowId = addKey?.substring('miniset-add-'.length);
    releve['myo_ligne'] = rowId;
    if (rowId != null) {
      final slot = find.byKey(ValueKey('miniset-note-slot-$rowId'));
      final strip = find
          .ancestor(of: slot, matching: find.byType(Material))
          .first;
      final heights = <double>[tester.getSize(strip).height];
      await shot('01_myo_avant');
      for (var i = 0; i < 8; i++) {
        final a = find.byKey(ValueKey('miniset-add-$rowId'));
        if (a.evaluate().isEmpty) break;
        if (a.hitTestable().evaluate().isEmpty) await scrollTo(tester, a);
        await tester.tap(a.hitTestable().first);
        await wait(tester, 700);
        heights.add(tester.getSize(strip).height);
      }
      releve['bandeau_hauteurs'] = heights;
      releve['bandeau_stable'] = heights.toSet().length == 1;
      releve['myo_parties'] = keyStarts('miniset-part-').evaluate().length;
      await scrollTo(tester, keyStarts('miniset-advice-'));
      await shot('02_myo_tous_les_blocs');
      final check = find.byKey(ValueKey('set-check-$rowId'));
      if (check.evaluate().isNotEmpty) await tapF(tester, check, ms: 1200);
      final tl = store.adaptTrainingLog();
      final rec = tl.sessions
          .expand((s) => s.sets)
          .where((x) => x.parts != null)
          .lastOrNull;
      releve['journal_parties'] = rec == null
          ? null
          : {
              'technique': rec.technique?.code,
              'reps': rec.reps,
              'parts': [for (final p in rec.parts!) p.reps ?? p.seconds],
            };
      releve['journal_valide'] = tl.validate().isEmpty;
      await shot('03_myo_validee');
    }
    await home(tester);
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 2. Session de test : test reporté (point 6).
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    var clock = DateTime(2026, 10, 5, 9); // lundi
    store.storeClock = () => clock;
    final sw =
        kc.AthleteProfile.fromJson(
          (jsonDecode(_streetWorkout) as Map).cast<String, Object?>(),
        ).copyWith(
          availability: [
            for (var d = 1; d <= 6; d++) kc.DaySlot(weekday: d, minutes: 90),
          ],
          events: const <kc.SeasonEvent>[],
        );
    store.saveAthleteProfile(ProfileDraft.of(sw)..consent = 'refused');
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    DateTime dateOf(int week, int day) {
      final s = store.program.start!;
      return DateTime(s.year, s.month, s.day + (week - 1) * 7 + day - 1, 9);
    }

    // S4·J4 : test écrit ; bilan bas, test retiré, une série notée.
    final it = store
        .adaptPlaceOf(4, 4)
        ?.day
        ?.items
        .where((x) => x.kind == kc.SetKind.test)
        .firstOrNull;
    releve['test_ecrit'] = it?.exerciseId;
    if (it != null) {
      clock = dateOf(4, 4);
      final base = store.program.week(4).day(4)!;
      store.adaptOpen(4, base);
      final low = store.adaptAnswer(
        4,
        base,
        const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      );
      releve['test_retire'] =
          low != null && !low.plan.items.any((x) => x.slotId == it.slotId);
      final a = store.sessionAdapt(4, 4);
      if (a != null) {
        final day = store.adaptDay(4, base, a);
        for (final e in day.exercises) {
          final log = store.exLog(4, 4, e);
          if (log.sets.isEmpty) continue;
          store.adaptPrefill(4, 4, e, log);
          final s = log.sets.first;
          if (s.reps.isEmpty) s.reps = '5';
          s.flames = 7;
          if (store.toggleSet(log, 0, store.logSpec(e)).ok) break;
        }
        store.saveLogs();
      }
      // S4·J6 : test reporté servi.
      clock = dateOf(4, 6);
      final why = find.textContaining('reporté');
      releve['reporte_page'] = await openTo(tester, 4, 6, why);
      final later = store.sessionAdapt(4, 6);
      releve['reporte_servi'] =
          later?.active.items.any(
            (x) => x.slotId == it.slotId && x.kind == kc.SetKind.test,
          ) ??
          false;
      await shot('04_test_reporte');
      await home(tester);
    }

    // 3. Jour J (point 1) : compétiteur de streetlifting.
    clock = DateTime(2026, 10, 1, 9);
    store.saveAthleteProfile(
      ProfileDraft.of(sampleStreetProfile(on: civilOf(clock), beginner: false))
        ..consent = 'refused',
    );
    final c2 = PlanStore(store).newPlanCreation(journal: false);
    if (c2 != null) {
      c2.start();
      c2.createPass2();
      PlanStore(store).applyPlanCreation(c2);
    }
    final event = store.athlete?.profile.events
        ?.where((e) => e.kind == kc.EventKind.strengthCompetition)
        .firstOrNull;
    releve['epreuve'] = event?.id;
    if (event != null) {
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => EventDayScreen(event: event)),
        ),
      );
      final ok = keyStarts('event-ok-');
      releve['jour_j_tentatives'] = await until(tester, ok, max: 80);
      await shot('05_jour_j');
      if (ok.evaluate().isNotEmpty) {
        await tapF(tester, ok, ms: 1200);
      }
      releve['tentatives_gardees'] = store.eventAttemptsOf(event.id).length;
      await shot('06_jour_j_notee');
      await home(tester);
      final tl = store.adaptTrainingLog(today: event.date);
      final ev = tl.sessions.where((s) => s.id == 'event-${event.id}');
      releve['journal_jour_j'] = ev.isEmpty
          ? null
          : {
              'eventId': ev.first.eventId,
              'roles': [for (final x in ev.first.sets) x.role?.code],
              'rangs': [for (final x in ev.first.sets) x.attemptIndex],
            };
      releve['journal_jour_j_valide'] = tl.validate().isEmpty;
    }
    store.storeClock = DateTime.now;

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      final del = find.byKey(const ValueKey('dev-delete'));
      await tester.ensureVisible(del.first);
      await wait(tester, 400);
      await tester.tap(del.hitTestable().first);
      await wait(tester, 800);
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      await wait(tester, 600);
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    await store.flush();
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['accueil'], isTrue);
    expect(releve['myo_page'], isTrue);
    expect(releve['bandeau_stable'], isTrue);
    expect((releve['journal_parties'] as Map?)?['technique'], 'myo_reps');
    expect(releve['journal_valide'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['test_retire'], isTrue);
    expect(releve['reporte_servi'], isTrue);
    expect(releve['reporte_page'], isTrue);
    expect(releve['jour_j_tentatives'], isTrue);
    expect(releve['tentatives_gardees'], 1);
    expect((releve['journal_jour_j'] as Map?)?['eventId'], event?.id);
    expect(releve['journal_jour_j_valide'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
