// G5 (dev6.3.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_g5_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, couleur dominante rouge Kalis ; b = thème clair,
// couleur dominante violette (deux couleurs dominantes). L'application
// complète (kalisApp, comme main) démarre sur une session personnelle avec
// un programme commencé il y a 10 jours (S1·J1 faite). Écrans : accueil
// (carte du jour de Koach, proposition « Reprendre là où tu t'es
// arrêté »), Arsenal › Anatomie › Galerie de Koach (36 poses, flammes 1 à
// 10, sélecteur, transition, bulle « Pourquoi ? »), « Réduire les
// animations », puis la session de test (5 appuis sur le logo : message de
// Koach, galerie) et sa suppression (message de Koach). Relevé
// `g5_releve_<partie>.json`, captures `g5_*_<thème>.png`, regardées avant
// livraison.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/koach/koach_gallery_screen.dart';
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

  void record() => data['g5_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  /// Captures à 1 px par dp (360 × 640), renvoi léger au pilote.
  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g5_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Attend la fin de l'ouverture (initialisation du magasin comprise).
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
    for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .last,
        Offset(0, up ? 250 : -250),
      );
      await wait(tester, 300);
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await wait(tester, 500);
    }
  }

  Future<void> tab(WidgetTester tester, int i) async {
    await tester.tap(find.byKey(ValueKey('nav-$i')));
    await wait(tester, 1200);
  }

  Future<void> back(WidgetTester tester) async {
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1200);
  }

  /// Koach visibles à l'écran.
  int koachs() => find.byType(KoachView).hitTestable().evaluate().length;

  Future<void> gallery(WidgetTester tester) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const KoachGalleryScreen()),
      ),
    );
    await wait(tester, 1800);
  }

  testWidgets('G5 $_part ($theme, $accent) : Koach 2D, galerie, flammes, '
      'session de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.saveProfile(seed.ownerDraft());
    final plan = seed.program.week(1).day(1);
    if (plan != null) {
      for (final ex in plan.exercises) {
        for (final set in seed.exLog(1, 1, ex).sets) {
          set
            ..kg = '20'
            ..reps = '5'
            ..done = true
            ..completedAt = real.toIso8601String();
        }
      }
      seed.markSessionDone(1, 1, true);
    }
    await seed.flush();
    seed.dispose();

    // L'émulateur de la CI a ses animations coupées : on les rallume pour
    // voir les micro-animations, puis « Réduire les animations » plus bas.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);

    // Accueil : Koach sur la carte du jour.
    await tab(tester, 2);
    final card = find.byKey(const ValueKey('koach-today-view'));
    await scrollTo(tester, card);
    releve['carte_du_jour'] = card.evaluate().isNotEmpty;
    releve['accueil_koachs'] = koachs();
    await shot('1_accueil_carte_du_jour');
    // Proposition (L11 : séances manquées depuis S1·J1) dite par Koach.
    final proposal = find.byKey(const ValueKey('adapt-proposal-slide'));
    await scrollTo(tester, proposal);
    releve['proposition'] = proposal.evaluate().isNotEmpty;
    releve['proposition_koach'] = find
        .descendant(of: proposal, matching: find.byType(KoachView))
        .evaluate()
        .isNotEmpty;
    await shot('2_accueil_proposition');

    // Arsenal › Anatomie › Galerie de Koach.
    await tab(tester, 0);
    final anatomy = find.byKey(const ValueKey('arsenal-anatomy'));
    if (anatomy.evaluate().isNotEmpty) {
      await tester.tap(anatomy.first);
      await wait(tester, 2000);
    }
    final entry = find.byKey(const ValueKey('anatomy-koach-gallery'));
    await scrollTo(tester, entry);
    releve['entree_galerie'] = entry.evaluate().isNotEmpty;
    releve['entree_apercu_3d'] = find
        .byKey(const ValueKey('anatomy-koach-preview'))
        .evaluate()
        .isNotEmpty;
    await shot('3_anatomie_entree');
    if (entry.evaluate().isNotEmpty) {
      await tester.tap(entry.first);
      await wait(tester, 1800);
    } else {
      await gallery(tester);
    }
    releve['galerie'] = find.byType(KoachGalleryScreen).evaluate().isNotEmpty;
    await shot('4_galerie_haut');
    await scrollTo(tester, find.byKey(const ValueKey('koach-pose-explain_board')));
    await wait(tester, 800);
    await shot('5_galerie_poses_1');
    await scrollTo(tester, find.byKey(const ValueKey('koach-pose-present')));
    await wait(tester, 800);
    await shot('6_galerie_poses_2');
    final poses = <String>[
      for (final p in KoachPose.values)
        if (find.byKey(ValueKey('koach-pose-${p.id}')).evaluate().isNotEmpty)
          p.id,
    ];
    releve['poses'] = poses.length;
    // Flammes et sélecteur.
    await scrollTo(tester, find.byKey(const ValueKey('flame-pick-9')));
    await tester.tap(find.byKey(const ValueKey('flame-pick-9')));
    await wait(tester, 600);
    releve['selecteur'] =
        (find.byKey(const ValueKey('flame-pick-caption')).evaluate().first.widget
                as Text)
            .data;
    await shot('7_flammes');
    // Bulle « Pourquoi ? ».
    final why = find.byKey(const ValueKey('koach-why'));
    await scrollTo(tester, why);
    await tester.tap(why.first);
    await wait(tester, 1200);
    releve['pourquoi'] = find
        .byKey(const ValueKey('koach-why-text'))
        .evaluate()
        .isNotEmpty;
    await shot('8_bulle_pourquoi');
    // Transition : une pose choisie en haut de la galerie.
    await scrollTo(tester, find.byKey(const ValueKey('koach-pose-flag')), up: true);
    await tester.tap(find.byKey(const ValueKey('koach-pose-flag')));
    await tester.pump(const Duration(milliseconds: 90));
    final stage = find.byKey(const ValueKey('koach-gallery-stage'));
    releve['transition_en_cours'] =
        stage.evaluate().isNotEmpty &&
        tester.state<KoachViewState>(stage).previous != null;
    await wait(tester, 600);
    await tester.ensureVisible(stage);
    await wait(tester, 600);
    await shot('9_galerie_drapeau');
    releve['respiration'] =
        stage.evaluate().isNotEmpty &&
        tester.state<KoachViewState>(stage).breathing;

    // « Réduire les animations » : poses fixes.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await wait(tester, 800);
    await scrollTo(tester, find.byKey(const ValueKey('koach-pose-cheer')));
    await tester.tap(find.byKey(const ValueKey('koach-pose-cheer')));
    await tester.pump(const Duration(milliseconds: 16));
    releve['reduit_transition'] =
        tester.state<KoachViewState>(stage).previous != null;
    releve['reduit_respiration'] = tester
        .state<KoachViewState>(stage)
        .breathing;
    releve['reduit_texte'] = find
        .text('Animations réduites : Koach reste immobile.')
        .evaluate()
        .isNotEmpty;
    await tester.ensureVisible(stage);
    await wait(tester, 600);
    await shot('10_animations_reduites');
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await wait(tester, 600);
    await back(tester);
    await back(tester);

    // Session de test : 5 appuis sur le logo, message de Koach.
    await tab(tester, 2);
    await store.flush();
    final persoBefore = KalisPrefs(raw, dev: false).snapshot();
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    releve['logo_present'] = logo.evaluate().isNotEmpty;
    if (logo.evaluate().isNotEmpty) {
      for (var i = 0; i < 5; i++) {
        await tester.tap(logo.first);
        await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
      }
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      releve['dev_message_koach'] = find
          .byKey(const ValueKey('session-toast-koach'))
          .evaluate()
          .isNotEmpty;
      await shot('11_dev_message_entree');
      await opened(tester);
    }
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_espace'] = SessionSpace.isDev;
    await gallery(tester);
    releve['dev_galerie'] = find
        .byType(KoachGalleryScreen)
        .evaluate()
        .isNotEmpty;
    releve['dev_galerie_koachs'] = koachs();
    await shot('12_dev_galerie');
    await back(tester);
    // Suppression par les outils de test (confirmation) : message de Koach.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      final delete = find.byKey(const ValueKey('dev-delete'));
      await scrollTo(tester, delete);
      await tester.tap(delete.first);
      await wait(tester, 800);
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      releve['dev_suppression_message'] = find
          .text('Session de test supprimée')
          .evaluate()
          .isNotEmpty;
      releve['dev_suppression_koach'] = find
          .byKey(const ValueKey('session-toast-koach'))
          .evaluate()
          .isNotEmpty;
      await shot('13_dev_supprimee');
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) ==
        jsonEncode(persoBefore);
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['carte_du_jour'], isTrue);
    expect(releve['proposition_koach'], isTrue);
    expect(releve['entree_galerie'], isTrue);
    expect(releve['entree_apercu_3d'], isFalse);
    expect(releve['galerie'], isTrue);
    expect(releve['poses'], 36);
    expect(releve['pourquoi'], isTrue);
    expect(releve['transition_en_cours'], isTrue);
    expect(releve['respiration'], isTrue);
    expect(releve['reduit_transition'], isFalse);
    expect(releve['reduit_respiration'], isFalse);
    expect(releve['reduit_texte'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_galerie'], isTrue);
    expect(releve['dev_suppression_message'], isTrue);
    expect(releve['dev_suppression_koach'], isTrue);
    expect(releve['retour_perso'], isTrue);
  }, timeout: _limit);
}
