// CU (dev6.8.0, PIPELINE_CP) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/profil_cu_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet. L'application
// complète (kalisApp, comme main) démarre sur une session personnelle de
// dev6.7.0 (profil v2 au schéma 2, programme commencé) : profil relu au
// schéma 3 sans perte, invitation de Koach « Compléter mon profil »,
// questions du schéma 3 seulement, programme inchangé. Session de test (5
// appuis sur le logo) : création du profil d'un débutant (écrans montrés,
// aucune question de récupération), puis, depuis le récapitulatif, le même
// profil passé en compétiteur élite de streetlifting (poids obligatoire,
// expérience, record, échéance avec règlement, récupération), à 200 % de
// texte pour deux écrans ; Réglages › Profil et tests guidés ; suppression
// de la session de test, session personnelle intacte. Relevé
// `cu_releve_<partie>.json`, captures `cu_*_<thème>.png`, regardées avant
// livraison.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/guided_tests.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_prefs.dart';
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

  void record() => data['cu_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  /// Captures à 1 px par dp (360 × 640), renvoi léger au pilote.
  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['cu_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1000]) async {
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
      await tester.ensureVisible(target.first);
      await wait(tester, 300);
    }
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 80}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> tap(WidgetTester tester, String key, {int ms = 600}) async {
    final f = find.byKey(ValueKey(key));
    await scrollTo(tester, f);
    final nav =
        key.startsWith('flow-next-') ||
        key.startsWith('recap-edit-') ||
        key == 'flow-to-recap';
    final flows = find.byType(AthleteProfileFlow);
    final before = nav && flows.evaluate().isNotEmpty
        ? tester.state<AthleteProfileFlowState>(flows.first).step
        : null;
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
    // Émulateur lent : attendre le changement d'écran (10 s au plus).
    for (var i = 0; before != null && i < 100; i++) {
      final now = find.byType(AthleteProfileFlow);
      if (now.evaluate().isEmpty ||
          tester.state<AthleteProfileFlowState>(now.first).step != before) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> top(WidgetTester tester) async {
    final lists = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    for (var i = 0; i < 14 && lists.evaluate().isNotEmpty; i++) {
      final s = tester.state<ScrollableState>(lists.last);
      if (s.position.pixels <= 0) break;
      await tester.drag(lists.last, const Offset(0, 400));
      await wait(tester, 200);
    }
    await wait(tester, 400);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    final f = find.byKey(ValueKey(key));
    await scrollTo(tester, f);
    await tester.enterText(f, text);
    await wait(tester, 300);
    // Clavier fermé : il cache le bas de l'écran (bouton « Continuer »).
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester, 700);
  }

  AthleteProfileFlowState? flow(WidgetTester tester) {
    final f = find.byType(AthleteProfileFlow);
    if (f.evaluate().isEmpty) return null;
    return tester.state<AthleteProfileFlowState>(f.first);
  }

  testWidgets('CU $_part ($theme, $accent) : compléter son profil (perso), '
      'parcours débutant puis compétiteur (session de test)', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final real = DateTime.now();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 20))),
        ),
      )..consent = 'refused',
    );
    await seed.flush();
    // Session écrite par dev6.7.0 : profil au schéma 2.
    final state = jsonDecode(seed.exportAll()) as Map<String, dynamic>;
    seed.dispose();
    ((state['athleteProfile'] as Map)['profile'] as Map)['schemaVersion'] = 2;
    await raw.setString('kalis_state_v3', jsonEncode(state));

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);

    // 1. Session personnelle : profil relu au schéma 3, invitation.
    releve['perso_schema'] = store.athleteProfile?.schemaVersion;
    releve['perso_questions_a_completer'] = store.profilePendingQuestions
        .map((q) => q.id)
        .toList();
    final logsBefore = jsonEncode(jsonDecode(store.exportAll())['logs']);
    await until(tester, find.byKey(const ValueKey('header-logo')));
    await scrollTo(tester, find.byKey(const ValueKey('profile-invite')));
    releve['perso_invitation'] = find
        .byKey(const ValueKey('profile-invite'))
        .evaluate()
        .isNotEmpty;
    await wait(tester, 800);
    await shot('01_perso_invitation');
    await tap(tester, 'profile-invite-open', ms: 1500);
    final complete = flow(tester);
    releve['completer_etapes'] = complete?.visibleSteps;
    releve['completer_questions'] = complete?.visibleQuestionIds.toList();
    var n = 0;
    for (var guard = 0; guard < 12 && flow(tester) != null; guard++) {
      final st = flow(tester)!;
      final step = st.step;
      await top(tester);
      await shot('0${2 + n}_completer_$step');
      n++;
      if (step == 'recovery') {
        await tap(tester, 'q-sleep-hours_6_to_7', ms: 400);
        await tap(tester, 'q-stress-moderate', ms: 400);
        await top(tester);
        await shot('0${2 + n}_completer_recovery_repondu');
        n++;
      }
      final last = st.visibleSteps.last == step;
      await tap(tester, last ? 'flow-save' : 'flow-next-$step', ms: 1200);
    }
    releve['completer_ferme'] = flow(tester) == null;
    releve['completer_sommeil'] = store.athleteProfile?.sleep?.code;
    releve['completer_programme_a_refaire'] =
        store.athlete?.changes.last.program;
    releve['completer_journal_inchange'] =
        jsonEncode(jsonDecode(store.exportAll())['logs']) == logsBefore;
    await wait(tester, 1200);
    releve['perso_invitation_apres'] = store.profileInviteVisible;
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 2. Session de test : création du profil d'un débutant.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    await scrollTo(tester, logo, up: true);
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_creation'] = await until(
      tester,
      find.byKey(const ValueKey('flow-welcome')),
    );
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    await wait(tester, 1200);
    final seen = <String>[];
    void mark(WidgetTester t) => seen.add(flow(t)?.step ?? '');
    await tap(tester, 'flow-next-welcome');
    mark(tester);
    await tap(tester, 'flow-sex-male', ms: 300);
    await type(tester, 'flow-year', '1996');
    await type(tester, 'flow-height', '167');
    await tap(tester, 'flow-next-identity');
    mark(tester);
    await tap(tester, 'flow-discipline-general_fitness', ms: 300);
    await top(tester);
    await shot('10_debutant_discipline');
    await tap(tester, 'flow-next-discipline');
    mark(tester);
    await tap(tester, 'flow-secondary-mobility', ms: 300);
    await tap(tester, 'flow-next-secondary');
    mark(tester);
    await top(tester);
    await shot('11_debutant_experience');
    await tap(tester, 'flow-experience-beginner', ms: 400);
    await tap(tester, 'flow-next-experience');
    mark(tester);
    releve['debutant_fourchettes'] = flow(tester)?.draft.shownMovements.length;
    await tap(tester, 'level-pushups-2', ms: 300);
    await top(tester);
    await shot('12_debutant_niveaux');
    await tap(tester, 'flow-next-levels');
    mark(tester);
    await tap(tester, 'goal-suggest', ms: 1200);
    await tap(tester, 'goal-suggestion-0', ms: 300);
    await tap(tester, 'goal-suggestions-add', ms: 1000);
    await tap(tester, 'flow-next-goals');
    mark(tester);
    await tap(tester, 'flow-day-2', ms: 300);
    await tap(tester, 'flow-day-5', ms: 300);
    await tap(tester, 'flow-next-availability');
    mark(tester);
    await tap(tester, 'flow-place-maison', ms: 300);
    await tap(tester, 'flow-next-places');
    mark(tester);
    await tap(tester, 'flow-consent-refused', ms: 300);
    await tap(tester, 'flow-next-health');
    mark(tester);
    await tap(tester, 'flow-mode-assisted', ms: 300);
    await tap(tester, 'flow-next-mode');
    mark(tester);
    releve['debutant_ecrans'] = ['welcome', ...seen];
    releve['debutant_questions'] = flow(tester)?.visibleQuestionIds.length;
    releve['debutant_recuperation'] = flow(
      tester,
    )?.visibleSteps.contains('recovery');
    await top(tester);
    await shot('13_debutant_recapitulatif');

    // 3. Le même profil en compétiteur élite de streetlifting.
    await tap(tester, 'recap-edit-discipline');
    await tap(tester, 'flow-street', ms: 400);
    await tap(tester, 'flow-style-streetlifting', ms: 400);
    await tap(tester, 'flow-to-recap', ms: 800);
    releve['poids_obligatoire'] = find
        .byKey(const ValueKey('flow-weight-card'))
        .evaluate()
        .isNotEmpty;
    await scrollTo(tester, find.byKey(const ValueKey('flow-weight-card')));
    await shot('14_poids_obligatoire');
    await type(tester, 'flow-weight', '72,5');
    await tap(tester, 'flow-to-recap', ms: 800);
    await tap(tester, 'recap-edit-experience');
    await tap(tester, 'flow-experience-elite', ms: 400);
    await tap(tester, 'q-training_age-over_5_years', ms: 400);
    await tap(tester, 'q-training_gap-none', ms: 400);
    await top(tester);
    await shot('15_elite_experience');
    await tap(tester, 'flow-to-recap', ms: 800);
    await tap(tester, 'recap-edit-levels');
    await tap(tester, 'benchmark-add', ms: 1000);
    await tap(tester, 'benchmark-exercise', ms: 1200);
    await tap(tester, 'picker-suggested-sl-traction-lestee', ms: 1000);
    await type(tester, 'benchmark-load', '45');
    await type(tester, 'benchmark-reps', '3');
    await tap(tester, 'benchmark-rir-1', ms: 300);
    await tap(tester, 'benchmark-date-recent', ms: 300);
    await tap(tester, 'benchmark-source-competition', ms: 300);
    await tap(tester, 'benchmark-standard-true', ms: 300);
    await shot('16_record_feuille');
    await tap(tester, 'benchmark-save', ms: 1000);
    await tap(tester, 'recent-sl-traction-lestee-sessions-3', ms: 300);
    await top(tester);
    await shot('17_elite_niveaux');
    await tap(tester, 'flow-to-recap', ms: 800);
    await tap(tester, 'recap-edit-goals');
    await tap(tester, 'event-add', ms: 1000);
    await tap(tester, 'event-kind-strength_competition', ms: 300);
    await tap(tester, 'event-date-month', ms: 300);
    await tap(tester, 'event-month-6', ms: 300);
    await tap(tester, 'event-priority-main', ms: 300);
    await tap(tester, 'event-preset-final_rep_all4', ms: 600);
    await tap(tester, 'event-class-73', ms: 300);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('event-lift-0')),
      up: true,
    );
    await shot('18_echeance_feuille');
    await tap(tester, 'event-save', ms: 1000);
    await scrollTo(tester, find.byKey(const ValueKey('q-events')));
    await shot('19_elite_objectifs');
    await tap(tester, 'flow-to-recap', ms: 800);
    // Récupération et records à 200 % de texte.
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await wait(tester, 800);
    await tap(tester, 'recap-edit-recovery');
    await tap(tester, 'q-sleep-hours_7_plus', ms: 300);
    await tap(tester, 'q-stress-low', ms: 300);
    await tap(tester, 'q-outside_load-on_feet', ms: 300);
    await top(tester);
    await shot('20_recuperation_200');
    releve['texte_200_exception'] = '${tester.takeException()}';
    await tap(tester, 'flow-to-recap', ms: 800);
    await tap(tester, 'recap-edit-levels');
    await top(tester);
    await shot('21_niveaux_200');
    releve['texte_200_exception_niveaux'] = '${tester.takeException()}';
    await tap(tester, 'flow-to-recap', ms: 800);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await wait(tester, 800);
    releve['elite_questions'] = flow(tester)?.visibleQuestionIds.length;
    await top(tester);
    await shot('22_elite_recapitulatif');
    await tap(tester, 'flow-next-recap', ms: 1500);
    releve['attente_programme'] = await until(
      tester,
      find.textContaining('Ton profil est prêt'),
    );
    final p = store.athleteProfile;
    releve['profil_schema'] = p?.schemaVersion;
    releve['profil_valide'] = p != null && p.validate().isEmpty;
    releve['profil_catalogue'] =
        p != null && store.content.catalog!.checkProfile(p).isEmpty;
    releve['profil_records'] = p?.benchmarks?.length;
    releve['profil_echeances'] = p?.events?.length;
    releve['profil_sommeil'] = p?.sleep?.code;
    releve['profil_street'] = p?.streetMode?.primary.code;
    await tap(tester, 'flow-done-continue', ms: 1500);

    // 4. Réglages › Profil et tests guidés (session de test).
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
    );
    await wait(tester, 1800);
    await shot('23_reglages_profil');
    await scrollTo(
      tester,
      find.byKey(const ValueKey('profile-rubric-recovery')),
    );
    releve['reglages_rubrique_recuperation'] = find
        .byKey(const ValueKey('profile-rubric-recovery'))
        .evaluate()
        .isNotEmpty;
    await shot('24_reglages_profil_suite');
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const GuidedTestsScreen()),
      ),
    );
    await wait(tester, 1500);
    releve['tests_guides'] = find
        .byKey(const ValueKey('guided-tests-koach'))
        .evaluate()
        .isNotEmpty;
    await shot('25_tests_guides');
    await appNavigator.currentState!.maybePop();
    await wait(tester, 800);
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1000);

    // 5. Suppression de la session de test : session personnelle intacte.
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
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    releve['perso_sommeil'] = store.athleteProfile?.sleep?.code;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_schema'], 3);
    expect(releve['perso_invitation'], isTrue);
    expect(releve['completer_ferme'], isTrue);
    expect(releve['completer_sommeil'], 'hours_6_to_7');
    expect(releve['completer_programme_a_refaire'], isFalse);
    expect(releve['completer_journal_inchange'], isTrue);
    expect(releve['perso_invitation_apres'], isFalse);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_creation'], isTrue);
    expect(releve['debutant_recuperation'], isFalse);
    expect(releve['debutant_fourchettes'], 4);
    expect(releve['poids_obligatoire'], isTrue);
    expect(releve['attente_programme'], isTrue);
    expect(releve['profil_schema'], 3);
    expect(releve['profil_valide'], isTrue);
    expect(releve['profil_catalogue'], isTrue);
    expect(releve['profil_records'], 1);
    expect(releve['profil_echeances'], 1);
    expect(releve['profil_sommeil'], 'hours_7_plus');
    expect(releve['reglages_rubrique_recuperation'], isTrue);
    expect(releve['tests_guides'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
    expect(releve['perso_sommeil'], 'hours_6_to_7');
  }, timeout: _limit);
}
