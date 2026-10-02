// G6 (dev6.4.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/profil_g6_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet. L'application
// complète (kalisApp, comme main) démarre sur une session personnelle
// d'avant G6 (programme commencé, ancien profil L8, pas de profil v2) :
// Koach propose de refaire le profil (« Plus tard »), puis la session de
// test (5 appuis sur le logo) démarre comme une installation neuve et la
// création du profil est faite en entier (12 écrans, Koach à chaque
// étape), avec 3 écrans à 200 % de texte, jusqu'à l'attente du programme ;
// Réglages › Profil de la session de test ; suppression de la session de
// test, session personnelle intacte. Relevé `g6_releve_<partie>.json`,
// captures `g6_*_<thème>.png`, regardées avant livraison.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/koach/koach_view.dart';
import 'package:streetlift_tracker/main.dart';
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

  void record() => data['g6_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  /// Captures à 1 px par dp (360 × 640), renvoi léger au pilote.
  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g6_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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
    // Vers le bas (ou le haut), puis dans l'autre sens si la cible est
    // déjà passée.
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
      await tester.ensureVisible(target.first);
      await wait(tester, 400);
    }
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 80}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> tap(WidgetTester tester, String key, {int ms = 700}) async {
    final f = find.byKey(ValueKey(key));
    await scrollTo(tester, f);
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  /// Haut de la page (Koach visible) avant une capture.
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

  String step(WidgetTester tester) {
    final f = find.byType(AthleteProfileFlow);
    if (f.evaluate().isEmpty) return '';
    return tester.state<AthleteProfileFlowState>(f.first).step;
  }

  int koachs() => find.byType(KoachView).hitTestable().evaluate().length;

  testWidgets('G6 $_part ($theme, $accent) : refaire son profil proposé, '
      'création complète en session de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    final at = profileAt(real.subtract(const Duration(days: 30)));
    seed.saveProfile(
      UserProfile(origin: 'migration', createdAt: at)
        ..setField('birthYear', 1990, at)
        ..setField('days', [1, 3, 5], at)
        ..setField('sessionMinutes', 75, at)
        ..setField('places', {
          'gym': ['pullup_bar', 'dip_bars', 'barbell', 'rack', 'weight_belt'],
        }, at),
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);

    // Session personnelle d'avant G6 : Koach propose de refaire le profil.
    releve['perso_proposition'] = await until(
      tester,
      find.byKey(const ValueKey('redo-proposal')),
    );
    releve['perso_proposition_koach'] = koachs();
    await wait(tester, 800);
    await shot('01_perso_proposition');
    await tap(tester, 'redo-later', ms: 1500);
    releve['perso_accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // Session de test : 5 appuis sur le logo → installation neuve.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
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
    // Session de test neuve : mêmes thème et couleur que la partie.
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    await wait(tester, 1500);
    await shot('02_dev_bienvenue');
    final t0 = DateTime.now();
    await tap(tester, 'flow-next-welcome');

    // 2. Toi.
    await type(tester, 'flow-name', 'Alex');
    await tap(tester, 'flow-sex-female');
    await type(tester, 'flow-year', '1994');
    await type(tester, 'flow-height', '168');
    await type(tester, 'flow-weight', '61');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester, 800);
    await top(tester);
    await shot('03_identite');
    await tap(tester, 'flow-next-identity');

    // 3. Discipline principale.
    await top(tester);
    releve['discipline_koachs'] = koachs();
    await shot('04_discipline');
    await tap(tester, 'flow-discipline-musculation');
    await tap(tester, 'flow-next-discipline');

    // 4. Secondaires et dosage.
    await tap(tester, 'flow-secondary-mobility');
    await tap(tester, 'flow-secondary-cardio');
    await scrollTo(tester, find.byKey(const ValueKey('flow-dosage')));
    await shot('05_dosage');
    await tap(tester, 'flow-next-secondary');

    // 5. Niveau par mouvement.
    await tap(tester, 'flow-experience-intermediate');
    await tap(tester, 'level-squat-3');
    await tap(tester, 'level-deadlift--1');
    await tap(tester, 'level-pullups-2');
    await top(tester);
    await shot('06_niveau');
    await tap(tester, 'flow-next-levels');

    // 6. Objectifs : Koach propose.
    await tap(tester, 'goal-suggest', ms: 1200);
    releve['objectifs_proposes'] = find
        .byKey(const ValueKey('goal-suggestion-1'))
        .evaluate()
        .isNotEmpty;
    await shot('07_objectifs_koach');
    // G12 : sans séance, rien à proposer (kalis_quest) ; une habitude.
    await tap(tester, 'goal-suggestions-add', ms: 1200);
    await tap(tester, 'goal-add-habit', ms: 1200);
    await tap(tester, 'goal-save', ms: 1200);
    await top(tester);
    await shot('08_objectifs');
    await tap(tester, 'flow-next-goals');

    // 7. Disponibilités.
    await tap(tester, 'flow-day-1');
    await tap(tester, 'flow-min-1-60');
    await tap(tester, 'flow-day-3');
    await tap(tester, 'flow-day-6');
    await tap(tester, 'flow-min-6-90');
    await shot('09_disponibilites');
    await tap(tester, 'flow-next-availability');

    // 8. Lieux et matériel.
    await tap(tester, 'flow-place-salle');
    await tap(tester, 'flow-place-maison');
    await tap(tester, 'flow-preset-home_equipped');
    await top(tester);
    await shot('10_lieux_materiel');
    await tap(tester, 'flow-next-places');

    // 9. Santé : accord, questionnaire, une gêne au genou.
    await tap(tester, 'flow-consent-given');
    for (final q in kHealthQuestions) {
      await tap(tester, 'flow-q-${q.id}-false', ms: 300);
    }
    await tap(tester, 'zone-knee', ms: 1200);
    await tap(tester, 'limitation-side-left', ms: 400);
    await tap(tester, 'limitation-save', ms: 1200);
    await scrollTo(
      tester,
      find.byKey(const ValueKey('flow-limitation-knee|left')),
    );
    await wait(tester, 1500);
    await shot('11_sante_carte');
    await tap(tester, 'flow-next-health');

    // 10. Préférences (facultatif), 11. Mode.
    await tap(tester, 'flow-next-preferences');
    await tap(tester, 'flow-mode-free');
    await top(tester);
    await shot('12_mode');
    await tap(tester, 'flow-next-mode');

    // 12. Récapitulatif ; trois écrans à 200 % de texte.
    releve['recap'] = step(tester) == 'recap';
    await top(tester);
    await shot('13_recapitulatif');
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await wait(tester, 1200);
    await top(tester);
    await shot('14_recap_200');
    await tap(tester, 'recap-edit-identity');
    await top(tester);
    await shot('15_identite_200');
    releve['texte_200_exception'] = '${tester.takeException()}';
    await tap(tester, 'flow-to-recap');
    await tap(tester, 'recap-edit-discipline');
    await top(tester);
    await shot('16_discipline_200');
    await tap(tester, 'flow-to-recap');
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await wait(tester, 800);
    releve['duree_parcours_s'] = DateTime.now().difference(t0).inSeconds;
    await tap(tester, 'flow-next-recap', ms: 1500);
    releve['attente_programme'] = await until(
      tester,
      find.textContaining('Ton profil est prêt'),
    );
    await shot('17_attente_programme');
    final p = store.athleteProfile;
    releve['profil_valide'] = p != null && p.validate().isEmpty;
    releve['profil_catalogue'] =
        p != null && store.content.catalog!.checkProfile(p).isEmpty;
    releve['profil_objectifs'] = p?.goals.length;
    releve['profil_jours'] = p?.availability.map((d) => d.weekday).toList();
    releve['profil_genes'] = p?.limitations.length;
    releve['profil_sante'] = p?.healthScreening?.outcome.code;
    await tap(tester, 'flow-done-continue', ms: 1500);
    // Correction 1 : l'onglet Programme n'affiche pas le programme embarqué
    // tant que le programme du profil n'existe pas ; Koach explique.
    releve['programme_en_attente'] = await until(
      tester,
      find.byKey(const ValueKey('program-pending')),
    );
    releve['programme_embarque_cache'] = find
        .byKey(const ValueKey('programme-weeks'))
        .evaluate()
        .isEmpty;
    await shot('19_programme_en_attente');
    await tap(tester, 'program-explainer-open', ms: 1500);
    releve['explication'] = find
        .byKey(const ValueKey('program-explainer'))
        .evaluate()
        .isNotEmpty;
    await shot('20_explication_programme');
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1000);

    // Réglages › Profil (session de test).
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      ),
    );
    await wait(tester, 1800);
    releve['reglages_profil'] = find
        .byKey(const ValueKey('profile-rubric-identity'))
        .evaluate()
        .isNotEmpty;
    await shot('18_reglages_profil');
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1000);

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
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    releve['perso_sans_profil_v2'] = store.athlete == null;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_proposition'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_creation'], isTrue);
    expect(releve['recap'], isTrue);
    expect(releve['attente_programme'], isTrue);
    expect(releve['profil_valide'], isTrue);
    expect(releve['profil_catalogue'], isTrue);
    expect(releve['profil_genes'], 1);
    expect(releve['reglages_profil'], isTrue);
    expect(releve['programme_en_attente'], isTrue);
    expect(releve['programme_embarque_cache'], isTrue);
    expect(releve['explication'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
    expect(releve['perso_sans_profil_v2'], isTrue);
  }, timeout: _limit);
}
