// G10 (dev6.7.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/evolution_g10_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis, mode assisté ; b = thème clair, violet,
// mode libre. Session personnelle : profil v2 et programme créé, Réglages ›
// Mon programme (carte « Évolution ») et écran Évolution (mode assisté /
// libre, déblocage, historique). Session de test (5 appuis) : profil et
// programme semés, simulateur de séances (8 semaines, athlète simulé de
// kalis_adapt) lancé depuis son écran, horloge de la session de test au
// dernier jour simulé ; propositions de Koach sur l'accueil, feuille du
// diff, historique des changements, inspecteur du moteur dynamique.
// Suppression de la session de test, session personnelle intacte.
// Relevé `g10_releve_<partie>.json`, captures `g10_*_<thème>.png`.
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
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/dev/engine_inspector.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_host.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

/// Calendrier fixe de la session de test : le programme commence le jeudi
/// 1er octobre 2026 (l'horloge de la session de test y est ramenée), pour
/// que la simulation soit la même à chaque passage, quel que soit le jour
/// réel. Athlète simulé `calisthenie_parc`, graine 3 : le moteur fait ses
/// propositions de volume dans le 2e bloc (semaines 7 et 8). Partie a
/// (mode assisté) : 8 semaines, changements appliqués et annoncés ;
/// partie b (mode libre) : 7 semaines, proposition en attente sur
/// l'accueil, acceptée depuis la carte.
final _day0 = DateTime(2026, 10, 1);
const _athlete = 'calisthenie_parc';
const _seedN = 3;

/// Décalage (jours) de l'horloge de la session de test pour être le [d].
int _offsetTo(DateTime d) {
  final real = KalisClock.realNow();
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(real.year, real.month, real.day)).inDays;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final mode = dark ? kc.GuidanceMode.assisted : kc.GuidanceMode.free;
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
    'mode': mode.code,
  };
  binding.reportData = data;

  void record() => data['g10_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g10_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> tap(WidgetTester tester, String key, {int ms = 800}) =>
      tapF(tester, find.byKey(ValueKey(key)), ms: ms);

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

  /// Profil d'exemple (mode de la partie) et programme créé par kalis_plan.
  void seedProgram(AppStore s) {
    s.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(on: civilOf(s.storeClock()), guidance: mode),
      )..consent = 'refused',
    );
    final c = PlanStore(s).newPlanCreation(journal: false);
    if (c == null) return;
    c.start();
    c.createPass2();
    PlanStore(s).applyPlanCreation(c);
  }

  testWidgets('G10 $_part ($theme, $accent, ${mode.code}) : évolution du '
      'programme, simulateur, propositions, inspecteur', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    seedProgram(seed);
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

    // Session personnelle : Mon programme › Évolution.
    await push(tester, const ProgramScreen());
    releve['perso_carte_evolution'] = await until(
      tester,
      find.byKey(const ValueKey('program-evolution')),
    );
    await scrollTo(tester, find.byKey(const ValueKey('program-evolution')));
    await shot('01_mon_programme');
    await tap(tester, 'program-evolution-open', ms: 1800);
    releve['perso_evolution'] = await until(
      tester,
      find.byKey(const ValueKey('evo-mode-switch')),
    );
    releve['perso_deblocage'] = find
        .byKey(const ValueKey('evo-unlock'))
        .evaluate()
        .isNotEmpty;
    await shot('02_evolution_perso');
    // Mode modifiable : bascule puis retour.
    final other = mode == kc.GuidanceMode.assisted ? 'Libre' : 'Assisté';
    await tapF(tester, find.text(other), ms: 900);
    releve['perso_mode_bascule'] = store.adaptMode;
    await tapF(
      tester,
      find.text(mode == kc.GuidanceMode.assisted ? 'Assisté' : 'Libre'),
      ms: 900,
    );
    releve['perso_mode'] = store.adaptMode;
    await home(tester);
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // Session de test : 5 appuis → installation neuve ; profil et
    // programme semés, simulateur de séances.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    await SessionHost.restart(
      () => DevSession.setOffsetDays(_offsetTo(_day0)),
      message: 'Voyage dans le temps',
    );
    await opened(tester);
    releve['dev_jour0'] = civilOf(KalisClock.now()).iso;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    seedProgram(store);
    releve['dev_programme'] = PlanStore(store).programPlanned;
    await store.flush();
    await wait(tester, 1200);

    await push(tester, const DevSimulatorScreen());
    await tap(tester, 'sim-weeks-8', ms: 500);
    await top(tester);
    await shot('03_simulateur');
    await home(tester);
    // Simulation (même fonction que le bouton « Simuler ») : 8 semaines
    // en mode assisté, 7 en mode libre (proposition encore en attente).
    final t0 = DateTime.now();
    final weeks = mode == kc.GuidanceMode.assisted ? 8 : 7;
    final sim = await runDevSimulation(
      store,
      athleteKey: _athlete,
      weeks: weeks,
      seed: _seedN,
    );
    releve['sim'] =
        '$_athlete/$_seedN, $weeks semaines : ${sim.sessionsDone} séances, '
        '${sim.sessionsMissed} manquées, ${sim.blocksAdded} bloc ajouté, '
        'erreur : ${sim.error}';
    await SessionHost.restart(
      () => DevSession.setOffsetDays(_offsetTo(sim.end)),
      message: 'Simulation terminée',
    );
    await opened(tester);
    releve['sim_ms'] = DateTime.now().difference(t0).inMilliseconds;
    releve['sim_decalage_jours'] = KalisClock.offsetDays;
    releve['sim_seances'] = store.logs.values.where((l) => l.done).length;
    releve['propositions'] = [
      for (final e in store.planEvolution.entries)
        '${e.proposal.kind.code}:${e.status}@${e.fromWeek}',
    ];
    // Accueil : carte de Koach (proposition en attente ou annoncée).
    store.evolutionRefresh();
    await wait(tester, 1200);
    final card = find.byKey(const ValueKey('evo-home-card'));
    releve['carte_accueil'] = card.evaluate().isNotEmpty;
    if (card.evaluate().isNotEmpty) {
      await scrollTo(tester, card);
      await shot('04_proposition');
      final details = find.descendant(
        of: card,
        matching: find.text('Voir le changement'),
      );
      if (details.evaluate().isNotEmpty) {
        await tapF(tester, details, ms: 1500);
        releve['diff'] = await until(
          tester,
          find.byKey(const ValueKey('evo-sheet')),
        );
        await shot('05_diff');
        Navigator.of(
          tester.element(find.byKey(const ValueKey('evo-sheet'))),
        ).pop();
        await wait(tester, 800);
      }
      final accept = find.descendant(of: card, matching: find.text('Accepter'));
      if (mode == kc.GuidanceMode.free && accept.evaluate().isNotEmpty) {
        await tapF(tester, accept, ms: 1500);
        releve['accepte'] = store.planEvolution.entries
            .where((e) => e.status == 'accepted')
            .length;
      }
    }
    // Historique des changements (Mon programme › Évolution).
    await push(tester, const EvolutionScreen());
    releve['evolution'] = await until(
      tester,
      find.byKey(const ValueKey('evo-mode-switch')),
    );
    await shot('06_evolution');
    final hist = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          ((w.key! as ValueKey<String>).value.startsWith('evo-history-') ||
              (w.key! as ValueKey<String>).value.startsWith('evo-pending-')),
    );
    // Liste construite à la demande : descendre jusqu'à l'historique.
    await scrollTo(tester, find.text('Historique des changements'));
    await scrollTo(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('evo-history-'),
      ),
    );
    releve['historique'] = hist.evaluate().length;
    if (hist.evaluate().isNotEmpty) {
      await scrollTo(tester, hist.first);
      await shot('07_historique');
      // Feuille du diff depuis l'historique (ou la proposition en attente).
      if (releve['diff'] != true) {
        final h = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('evo-history-') &&
              !(w.key! as ValueKey<String>).value.startsWith(
                'evo-history-undo',
              ),
        );
        if (h.evaluate().isNotEmpty) {
          await tapF(tester, h, ms: 1500);
          releve['diff'] = await until(
            tester,
            find.byKey(const ValueKey('evo-sheet')),
          );
          await shot('05_diff');
          Navigator.of(
            tester.element(find.byKey(const ValueKey('evo-sheet'))),
          ).pop();
          await wait(tester, 800);
        }
      }
    } else {
      await scrollTo(tester, find.byKey(const ValueKey('evo-history-empty')));
      await shot('07_historique');
    }
    await home(tester);

    // Inspecteur du moteur dynamique.
    await push(tester, const EngineInspectorScreen(), 2500);
    releve['inspecteur'] = await until(
      tester,
      find.byKey(const ValueKey('inspector-state')),
    );
    releve['inspecteur_seance'] = find
        .byKey(const ValueKey('inspector-session'))
        .evaluate()
        .isNotEmpty;
    await shot('08_inspecteur');
    final item = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('inspector-item-'),
    );
    if (item.evaluate().isNotEmpty) {
      await scrollTo(tester, item.first);
      await shot('09_inspecteur_charges');
    }
    final props = find.textContaining('Propositions de la revue');
    if (props.evaluate().isNotEmpty) {
      await scrollTo(tester, props);
      await shot('10_inspecteur_propositions');
    }
    await home(tester);

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
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_carte_evolution'], isTrue);
    expect(releve['perso_evolution'], isTrue);
    expect(releve['perso_deblocage'], isTrue);
    expect(
      releve['perso_mode'],
      mode == kc.GuidanceMode.free ? 'free' : 'assisted',
    );
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_programme'], isTrue);
    expect(releve['sim_seances'], greaterThan(10));
    expect(releve['propositions'], isNotEmpty);
    expect(releve['carte_accueil'], isTrue);
    if (mode == kc.GuidanceMode.free) expect(releve['accepte'], 1);
    expect(releve['evolution'], isTrue);
    expect(releve['historique'], greaterThan(0));
    expect(releve['diff'], isTrue);
    expect(releve['inspecteur'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
