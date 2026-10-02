// G7 (dev6.5.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/programme_g7_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet. L'application
// complète (kalisApp, comme main) démarre sur une session personnelle
// (programme commencé, profil v2) : Réglages › Mon programme et « Où j'en
// suis » (sans valider). Puis la session de test (5 appuis sur le logo)
// démarre comme une installation neuve : création du profil, puis création
// du programme — passe 1, autre proposition, revue (« Je sais faire », « Je
// ne sais pas faire » + variante, « Je n'aime pas » + variante : diff de
// Koach), récapitulatif, passe 2, ajustement refusé, validation : le
// programme devient l'instance active (accueil). Suppression de la session
// de test, session personnelle intacte. Relevé `g7_releve_<partie>.json`,
// captures `g7_*_<thème>.png`, regardées avant livraison.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart' show kHealthQuestions;
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/plan_screens.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 5));

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

  void record() => data['g7_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g7_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> scrollTo(
    WidgetTester tester,
    Finder target, {
    bool up = false,
  }) async {
    for (final dy in up ? const [250.0, -250.0] : const [-250.0, 250.0]) {
      for (var i = 0; i < 30 && target.hitTestable().evaluate().isEmpty; i++) {
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

  Future<bool> until(WidgetTester tester, Finder f, {int max = 120}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> tap(WidgetTester tester, String key, {int ms = 700}) async {
    final f = find.byKey(ValueKey(key));
    await scrollTo(tester, f);
    await tester.tap(f.hitTestable().last);
    await wait(tester, ms);
  }

  Future<void> top(WidgetTester tester) async {
    final lists = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    for (var i = 0; i < 12 && lists.evaluate().isNotEmpty; i++) {
      final s = tester.state<ScrollableState>(lists.last);
      if (s.position.pixels <= 0) break;
      await tester.drag(lists.last, const Offset(0, 400));
      await wait(tester, 200);
    }
    await wait(tester, 500);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    final f = find.byKey(ValueKey(key));
    await scrollTo(tester, f);
    await tester.enterText(f, text);
    await wait(tester, 400);
  }

  /// Engine busy : attente de la fin de l'appel au moteur.
  Future<void> idle(WidgetTester tester) async {
    await wait(tester, 400);
    for (var i = 0; i < 100; i++) {
      if (find.byKey(const ValueKey('plan-busy')).evaluate().isEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await wait(tester, 600);
  }

  testWidgets('G7 $_part ($theme, $accent) : Mon programme et Où j’en suis '
      '(perso), création complète du programme en session de test', (
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
    await seed.configureStart(DateTime(real.year, real.month, real.day - 30));
    seed.seedSampleAthleteProfile();
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['perso_accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // Session personnelle : Réglages › Mon programme, Où j'en suis.
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ProgramScreen()),
      ),
    );
    await wait(tester, 1800);
    releve['perso_mon_programme'] = find
        .byKey(const ValueKey('program-create-open'))
        .evaluate()
        .isNotEmpty;
    await shot('01_perso_mon_programme');
    await tap(tester, 'program-position', ms: 1500);
    releve['perso_ou_j_en_suis'] = find
        .byKey(const ValueKey('position-koach'))
        .evaluate()
        .isNotEmpty;
    await shot('02_perso_ou_j_en_suis');
    await appNavigator.currentState!.maybePop();
    await wait(tester, 800);
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1000);

    // Session de test : 5 appuis sur le logo → installation neuve.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_creation_profil'] = await until(
      tester,
      find.byKey(const ValueKey('flow-welcome')),
    );
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    await wait(tester, 1200);

    // Création du profil (parcours court, réponses simples).
    await tap(tester, 'flow-next-welcome');
    await type(tester, 'flow-name', 'Alex');
    await tap(tester, 'flow-sex-female');
    await type(tester, 'flow-year', '1994');
    await type(tester, 'flow-height', '168');
    await type(tester, 'flow-weight', '61');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester, 600);
    await tap(tester, 'flow-next-identity');
    await tap(tester, 'flow-discipline-musculation');
    await tap(tester, 'flow-next-discipline');
    await tap(tester, 'flow-secondary-mobility');
    await tap(tester, 'flow-next-secondary');
    await tap(tester, 'flow-experience-intermediate');
    await tap(tester, 'level-squat-3');
    await tap(tester, 'level-pullups-2');
    await tap(tester, 'flow-next-levels');
    // G12 : sans séance, rien à proposer (kalis_quest) ; une habitude.
    await tap(tester, 'goal-add-habit', ms: 1200);
    await tap(tester, 'goal-save', ms: 1200);
    await tap(tester, 'flow-next-goals');
    await tap(tester, 'flow-day-1');
    await tap(tester, 'flow-min-1-60');
    await tap(tester, 'flow-day-3');
    await tap(tester, 'flow-day-5');
    await tap(tester, 'flow-next-availability');
    await tap(tester, 'flow-place-salle');
    await tap(tester, 'flow-next-places');
    await tap(tester, 'flow-consent-given');
    for (final q in kHealthQuestions) {
      await tap(tester, 'flow-q-${q.id}-false', ms: 300);
    }
    await tap(tester, 'flow-next-health');
    await tap(tester, 'flow-next-preferences');
    await tap(tester, 'flow-mode-assisted');
    await tap(tester, 'flow-next-mode');
    await tap(tester, 'flow-next-recap', ms: 1500);
    releve['profil_cree'] = store.athlete != null;
    releve['fin_profil'] = await until(
      tester,
      find.byKey(const ValueKey('flow-done-create')),
    );

    // Création du programme : passe 1.
    final t0 = DateTime.now();
    await tap(tester, 'flow-done-create', ms: 600);
    await idle(tester);
    releve['passe1'] = await until(
      tester,
      find.byKey(const ValueKey('plan-pass1')),
    );
    releve['passe1_ms'] = DateTime.now().difference(t0).inMilliseconds;
    await top(tester);
    await shot('03_passe1');
    await scrollTo(tester, find.byKey(const ValueKey('plan-week-overview')));
    await shot('04_passe1_semaine');
    await tap(tester, 'plan-other');
    await idle(tester);
    final state = tester.state<PlanCreationScreenState>(
      find.byType(PlanCreationScreen),
    );
    releve['autre_proposition'] = state.c!.index == 1;
    await tap(tester, 'plan-previous', ms: 900);
    releve['retour_proposition'] = state.c!.index == 0;

    // Revue.
    await tap(tester, 'plan-review', ms: 1200);
    await shot('05_revue_carte');
    await tap(tester, 'plan-can-do');
    await idle(tester);
    await wait(tester, 1200);
    await tap(tester, 'plan-cannot-do');
    await idle(tester);
    releve['variantes'] = await until(
      tester,
      find.byKey(const ValueKey('variants-sheet')),
    );
    await shot('06_variantes');
    final variants = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('variant-'),
    );
    if (variants.evaluate().isNotEmpty) {
      await tester.tap(variants.hitTestable().first);
    } else {
      await tap(tester, 'variants-koach');
    }
    await idle(tester);
    releve['diff_1'] = await until(
      tester,
      find.byKey(const ValueKey('step-sheet')),
    );
    await shot('07_diff_koach');
    await tap(tester, 'step-ok', ms: 1000);
    await tap(tester, 'plan-dislike');
    await idle(tester);
    await tap(tester, 'variants-koach');
    await idle(tester);
    releve['diff_2'] = await until(
      tester,
      find.byKey(const ValueKey('step-sheet')),
    );
    await tap(tester, 'step-ok', ms: 1000);
    releve['changements'] = state.c!.steps
        .where((s) => s.changes.isNotEmpty)
        .length;
    releve['verrous'] = state.c!.locks.length;
    await tap(tester, 'plan-review-recap', ms: 1200);
    await top(tester);
    await shot('08_recapitulatif');

    // Passe 2.
    await tap(tester, 'plan-validate-exercises');
    await idle(tester);
    releve['passe2'] = await until(
      tester,
      find.byKey(const ValueKey('plan-pass2')),
    );
    await top(tester);
    await shot('09_passe2');
    final item = state.c!.pass2!.weeks.first.days.first.items.first;
    await tap(tester, 'plan-p2-${item.slotId}', ms: 1200);
    await tap(tester, 'adjust-sets-plus');
    await tap(tester, 'adjust-sets-plus');
    releve['ajustement_refuse'] = find
        .byKey(const ValueKey('adjust-refused'))
        .evaluate()
        .isNotEmpty;
    await shot('10_ajustement');
    await tap(tester, 'adjust-done', ms: 1000);
    await tap(tester, 'plan-validate', ms: 2500);
    releve['programme_actif'] = PlanStore(store).programPlanned;
    releve['semaines'] = store.program.weeks.length;
    releve['accueil'] = await until(
      tester,
      find.byKey(const ValueKey('programme-weeks')),
    );
    await wait(tester, 1500);
    await shot('11_accueil_programme');
    releve['journal_moteur'] = PlanStore(store).planJournalText != null;

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      await tap(tester, 'dev-delete');
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      await wait(tester, 600);
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    await store.flush();
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    releve['perso_programme_inchange'] = !PlanStore(store).programPlanned;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_mon_programme'], isTrue);
    expect(releve['perso_ou_j_en_suis'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['profil_cree'], isTrue);
    expect(releve['passe1'], isTrue);
    expect(releve['autre_proposition'], isTrue);
    expect(releve['variantes'], isTrue);
    expect(releve['diff_1'], isTrue);
    expect(releve['passe2'], isTrue);
    expect(releve['ajustement_refuse'], isTrue);
    expect(releve['programme_actif'], isTrue);
    expect(releve['accueil'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
    expect(releve['perso_programme_inchange'], isTrue);
  }, timeout: _limit);
}
