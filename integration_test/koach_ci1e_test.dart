// CI1e (dev6.10.0, pipeline CP, DECISIONS_CP.md C11) sur émulateur Android,
// lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_ci1e_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle : programme de 40 semaines du propriétaire commencé il
// y a 12 semaines (aujourd'hui en S13), profil d'exemple en mode assisté.
// Premier lancement de 6.10.0 : sauvegarde d'origine prise ; Mon programme
// montre la saison (phase en cours, compte à rebours jusqu'à la fin de S40)
// et la carte du programme d'origine ; MA SAISON ; séance du jour servie
// en mode coach ; une proposition de Koach acceptée change le programme,
// « Revenir à mon programme d'origine » rend l'original, journal gardé.
// Relevé `ci1e_releve_<partie>.json`, captures `ci1e_*_<thème>.png`.
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
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

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

  void record() => data['ci1e_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ci1e_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> push(WidgetTester tester, Widget screen, [int ms = 1800]) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  testWidgets('CI1e $_part ($theme, $accent) : programme de 40 semaines '
      'sous toutes les fonctionnalités ; retour au programme d’origine', (
    tester,
  ) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 86));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 90))),
          guidance: kc.GuidanceMode.assisted,
        ),
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
    // Premier lancement de 6.10.0 : sauvegarde d'origine prise.
    releve['origine_prise'] = store.programOrigin != null;
    final now = store.storeClock();
    final w = store.program.weekFor(now);
    final j = store.program.offsetOf(now)! % 7 + 1;
    releve['jour'] = 'S$w-J$j';
    final imp = store.importedProgram;
    releve['blocs'] = imp?.segments.length;
    releve['bloc_du_jour'] = imp?.segmentOf(w)?.blockId;
    await shot('01_accueil');

    // Mon programme : saison et programme d'origine.
    await push(tester, const ProgramScreen(), 2000);
    releve['carte_saison'] = find
        .byKey(const ValueKey('program-season'))
        .evaluate()
        .isNotEmpty;
    releve['compte_a_rebours'] = find
        .byKey(const ValueKey('season-countdown'))
        .evaluate()
        .isNotEmpty;
    await shot('02_mon_programme');
    // UI1 (cahier §4.3) : le programme d'origine se rejoint par la ligne
    // « Revenir à un programme précédent » de Mon programme.
    final origin = find.byKey(const ValueKey('program-revert'));
    await scrollTo(tester, origin);
    releve['carte_origine'] = origin.evaluate().isNotEmpty;
    await shot('03_origine');
    await home(tester);
    await push(tester, const SeasonScreen(), 2000);
    releve['ma_saison'] = find
        .byKey(const ValueKey('season-screen'))
        .evaluate()
        .isNotEmpty;
    final view = storeSeasonOverview();
    releve['phases'] = view?.phases.length;
    releve['phase_en_cours'] = view?.currentPhase?.code;
    releve['jours_echeance'] = view?.daysToEvent;
    await shot('04_ma_saison');
    await home(tester);

    // Séance du jour (ou prochaine) servie en mode coach.
    var sw = w, sj = j;
    for (var k = 0; k < 7; k++) {
      final d = DateTime(now.year, now.month, now.day + k);
      final ww = store.program.weekFor(d);
      final jj = store.program.offsetOf(d)! % 7 + 1;
      if (store.adaptPlaceOf(ww, jj) != null) {
        sw = ww;
        sj = jj;
        break;
      }
    }
    final week = store.program.week(sw);
    final day = week.day(sj)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 1000);
    final a = store.sessionAdapt(sw, sj);
    releve['seance'] = 'S$sw-J$sj';
    releve['seance_mode_coach'] = a?.plan.weekIntent != null;
    releve['seance_bloc'] = a?.blockId;
    await shot('05_seance');
    await home(tester);
    await wait(tester, 1200);

    // Une proposition de Koach (une série de plus) appliquée en mode
    // assisté change le programme ; retour à l'origine.
    final place = store.adaptPlaceOf(sw, sj);
    final item = place?.day?.items
        .where((i) => i.setTargets == null && i.sets < 10)
        .firstOrNull;
    if (place != null && item != null) {
      store.evolutionReceive(place, [
        kc.Proposal(
          id: 'volume:${item.slotId}@${place.weekIndex}',
          kind: kc.ProposalKind.volume,
          scope: kc.ProposalScope.exercise,
          createdOn: civilOf(store.storeClock()),
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
                reasons: const [
                  kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
                ],
              ),
            ],
          ),
          reasons: const [
            kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
          ],
        ),
      ]);
      await wait(tester, 800);
      releve['programme_change'] = store.programDiffersFromOrigin;
      await push(tester, const ProgramScreen(), 2000);
      // UI1 : feuille d'actions « Revenir à un programme précédent », puis
      // confirmation au gabarit (KConfirm).
      final revert = find.byKey(const ValueKey('program-revert'));
      await scrollTo(tester, revert);
      await tapF(tester, revert, ms: 1200);
      final restore = find.byKey(const ValueKey('action-origin'));
      await until(tester, restore, max: 30);
      await shot('06_origine_change');
      await tapF(tester, restore, ms: 1200);
      final confirm = find.byKey(const ValueKey('confirm-ok'));
      releve['confirmation'] = await until(tester, confirm, max: 30);
      await shot('07_confirmation');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm.first);
        await wait(tester, 1500);
      }
      releve['origine_rendue'] = !store.programDiffersFromOrigin;
      // État relu dans la feuille, rouverte.
      await scrollTo(tester, revert);
      await tapF(tester, revert, ms: 1200);
      await shot('08_origine_rendue');
      // Relevé : ce qui diffère encore de la sauvegarde d'origine.
      final b = (store.programOrigin?['backup'] as Map?) ?? const {};
      final now = jsonDecode(store.exportAll()) as Map<String, dynamic>;
      releve['origine_rendue_apres'] = !store.programDiffersFromOrigin;
      releve['carte_origine_a_jour'] = find
          .textContaining('encore celui d’origine')
          .evaluate()
          .isNotEmpty;
      final close = find.byKey(const ValueKey('sheet-close'));
      if (close.evaluate().isNotEmpty) await tapF(tester, close, ms: 800);
      releve['sections_differentes'] = [
        for (final k in const [
          'programStart',
          'programInstance',
          'planProgram',
          'programResume',
          'planEvolution',
        ])
          if (jsonEncode(b[k]) != jsonEncode(now[k]))
            '$k : ${jsonEncode(b[k])} → ${jsonEncode(now[k])}',
      ];
      await home(tester);
    }
    await store.flush();
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['accueil'], isTrue);
    expect(releve['origine_prise'], isTrue);
    expect(releve['blocs'], 9);
    expect(releve['carte_saison'], isTrue);
    expect(releve['compte_a_rebours'], isTrue);
    expect(releve['carte_origine'], isTrue);
    expect(releve['ma_saison'], isTrue);
    expect(releve['seance_mode_coach'], isTrue);
    expect(releve['programme_change'], isTrue);
    expect(releve['confirmation'], isTrue);
    expect(releve['origine_rendue'], isTrue);
    expect(releve['origine_rendue_apres'], isTrue);
    expect(releve['carte_origine_a_jour'], isTrue);
  }, timeout: _limit);
}
