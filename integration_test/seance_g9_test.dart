// G9 (dev6.6.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/seance_g9_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet. Session
// personnelle : copie du programme du propriétaire (fixture : départ il y a
// 11 semaines, journal synthétique des semaines 1 à 11, profil v2 en mode
// assisté), séance du jour (S12·J1) servie par kalis_adapt : bilan santé
// (« Comment tu te sens ? »), réponse basse → détail (sommeil, énergie,
// douleur à l'épaule), ajustement appliqué par Koach, série notée en
// flammes (sélecteur pré-rempli), série notée 10 flammes → conseil de Koach
// pour la série suivante, fin de séance et résumé. Session de test (5
// appuis) : programme généré par kalis_plan, séance complète servie par le
// moteur. Suppression de la session de test, session personnelle intacte.
// Relevé `g9_releve_<partie>.json`, captures `g9_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 6));

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

  void record() => data['g9_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g9_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  /// Valide la série [n] du premier exercice affiché : la coche la valide
  /// avec la flamme visée, la ligne des flammes s'ouvre sous la série (G9
  /// correction 1) ; [flame] : position touchée ensuite sur la ligne.
  Future<bool> validate(
    WidgetTester tester,
    int n, {
    int? flame,
    String? shotName,
  }) async {
    await tapF(tester, find.byTooltip('Valider la série $n'), ms: 900);
    final track = await until(
      tester,
      find.byKey(ValueKey('flame-track-$n')),
    );
    if (!track) return false;
    if (flame != null) {
      await tap(tester, 'flame-pos-$flame', ms: 1500);
    }
    if (shotName != null) {
      await scrollTo(tester, find.byKey(ValueKey('flame-track-$n')));
      await shot(shotName);
    }
    return true;
  }

  /// Fin de séance : page « Bilan de séance », « Terminer la séance ».
  Future<bool> finish(WidgetTester tester, String shotName) async {
    await tapF(tester, find.text('Exercices'), ms: 900);
    await tapF(tester, find.text('Bilan de séance'), ms: 1200);
    await tap(tester, 'finish-session', ms: 2500);
    final ok = await until(
      tester,
      find.byKey(const ValueKey('adapt-summary')),
      max: 150,
    );
    await wait(tester, 1200);
    await top(tester);
    await shot(shotName);
    return ok;
  }

  testWidgets('G9 $_part ($theme, $accent) : séance servie par kalis_adapt '
      '(programme du propriétaire, puis session de test)', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final real = DateTime.now();
    final today = DateTime(real.year, real.month, real.day);
    await seed.configureStart(
      DateTime(today.year, today.month, today.day - 77),
    );
    // Journal synthétique des semaines 1 à 11 (fixture, aucune donnée réelle).
    for (final w in seed.program.weeks.take(11)) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        final date = seed.program.dateFor(w.n, d.j);
        final at = DateTime(date.year, date.month, date.day, 18);
        final log = seed.sessionLog(w.n, d.j)
          ..done = true
          ..finishedAt = at.toIso8601String()
          ..title = 'S${w.n} · J${d.j}';
        for (final e in d.exercises) {
          final x = seed.exLog(w.n, d.j, e);
          for (final s in x.sets) {
            s
              ..kg = '20'
              ..reps = '5'
              ..rir = '2'
              ..done = true
              ..completedAt = at.toIso8601String();
          }
        }
        log.exerciseNames.removeWhere((k, _) => !log.ex.containsKey(k));
      }
    }
    seed.saveLogs(immediate: true);
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

    // Séance du jour : S12·J1 du programme du propriétaire.
    final week = store.program.week(12);
    final day = week.day(store.program.dayFor(today))!;
    releve['perso_jour'] = 'S12-J${day.j}';
    final t0 = DateTime.now();
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    releve['bilan'] = await until(
      tester,
      find.byKey(const ValueKey('health-question')),
    );
    releve['ouverture_ms'] = DateTime.now().difference(t0).inMilliseconds;
    final served = store.sessionAdapt(12, day.j);
    releve['seance_moteur'] = served != null;
    releve['bloc'] = served?.blockId;
    await wait(tester, 1200);
    await shot('01_bilan');

    // Réponse basse → détail sur un seul écran.
    await tap(tester, 'feel-2', ms: 1500);
    releve['bilan_detail'] = await until(
      tester,
      find.byKey(const ValueKey('health-detail')),
    );
    await top(tester);
    await shot('02_bilan_detail');
    await tap(tester, 'detail-sleepQuality-1', ms: 400);
    await tap(tester, 'detail-energy-2', ms: 400);
    await tap(tester, 'pain-zone-shoulder', ms: 1200);
    if (find.byKey(const ValueKey('pain-sheet')).evaluate().isNotEmpty) {
      await tap(tester, 'pain-save', ms: 1000);
    }
    await scrollTo(tester, find.byKey(const ValueKey('pain-shoulder')));
    await shot('03_bilan_detail_douleur');
    await tap(tester, 'detail-save', ms: 2500);
    final a = store.sessionAdapt(12, day.j);
    releve['bilan_reponses'] = a?.check?.toJson();
    releve['ajustement_bilan'] = a?.choice;
    releve['carte_ajustement'] = await until(
      tester,
      find.byKey(const ValueKey('adjust-undo')),
      max: 40,
    );
    await top(tester);
    await shot('04_ajustement_bilan');
    if (find.byKey(const ValueKey('adjust-go')).evaluate().isNotEmpty) {
      await tap(tester, 'adjust-go', ms: 1500);
    } else if (find
        .byKey(const ValueKey('bilan-start'))
        .evaluate()
        .isNotEmpty) {
      await tap(tester, 'bilan-start', ms: 1500);
    }
    await wait(tester, 800);
    await shot('05_exercice');

    // Série 1 : ligne des flammes sous la série (flamme visée placée),
    // corrigée à 10 flammes.
    releve['flammes'] = await validate(
      tester,
      1,
      flame: 10,
      shotName: '06_flammes',
    );
    releve['conseil'] = await until(
      tester,
      find.byKey(const ValueKey('adapt-advice-toast')),
      max: 20,
    );
    await shot('07_ajustement_koach');
    final first = store
        .adaptDay(12, day, store.sessionAdapt(12, day.j)!)
        .exercises
        .first;
    final setLog = store.logs['S12-J${day.j}']?.ex[first.id];
    releve['serie1_flammes'] = setLog?.sets.first.flames;
    releve['serie1_validee'] = setLog?.sets.first.done;
    releve['conseils'] = store
        .sessionAdapt(12, day.j)
        ?.advice
        .map((k, v) => MapEntry(k, [for (final s in v) s.toJson()]));
    ScaffoldMessenger.maybeOf(
      tester.element(find.byType(SessionScreen)),
    )?.hideCurrentSnackBar();
    await wait(tester, 600);
    releve['serie2'] = await validate(tester, 2);
    // Série 3 validée : séries 1 et 2 résumées en une ligne (n − 2).
    if (find.byTooltip('Valider la série 3').evaluate().isNotEmpty) {
      releve['serie3'] = await validate(tester, 3);
    }
    releve['series_resumees'] = [
      for (final n in ['1', '2', '3'])
        if (find.byKey(ValueKey('set-summary-$n')).evaluate().isNotEmpty) n,
    ];
    await scrollTo(tester, find.byKey(const ValueKey('set-summary-1')));
    await shot('08_series');
    releve['fin_seance'] = await finish(tester, '09_fin_seance');
    releve['fin_series'] = find
        .byKey(const ValueKey('summary-sets'))
        .evaluate()
        .isNotEmpty;
    if (releve['fin_series'] == true) {
      await scrollTo(tester, find.byKey(const ValueKey('summary-sets')));
      await shot('12_fin_series');
      await top(tester);
    }
    releve['fin_sections'] = [
      for (final k in [
        'summary-calibration',
        'summary-progress',
        'summary-next',
      ])
        if (find.byKey(ValueKey(k)).evaluate().isNotEmpty) k,
    ];
    releve['perso_seance_faite'] = store.isDone(12, day.j);
    await tap(tester, 'summary-done', ms: 1500);
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1500);
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // Session de test : 5 appuis → installation neuve ; profil et programme
    // généré semés, séance complète servie par le moteur.
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
    store.seedSampleAthleteProfile();
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    releve['dev_programme'] = PlanStore(store).programPlanned;
    await wait(tester, 1500);
    WeekPlan? dw;
    DayPlan? dd;
    for (final w in store.program.weeks) {
      for (final d in w.days) {
        if (dd == null && d.exercises.isNotEmpty) {
          dw = w;
          dd = d;
        }
      }
    }
    if (dw != null && dd != null) {
      final wk = dw;
      final dy = dd;
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SessionScreen(week: wk, day: dy),
          ),
        ),
      );
      releve['dev_bilan'] = await until(
        tester,
        find.byKey(const ValueKey('health-question')),
      );
      releve['dev_seance_moteur'] = store.sessionAdapt(wk.n, dy.j) != null;
      await tap(tester, 'feel-4', ms: 2000);
      if (find.byKey(const ValueKey('adjust-go')).evaluate().isNotEmpty) {
        await tap(tester, 'adjust-go', ms: 1500);
      }
      await wait(tester, 800);
      releve['dev_flammes'] = await validate(tester, 1);
      await shot('10_dev_seance');
      releve['dev_fin'] = await finish(tester, '11_dev_fin_seance');
      await tap(tester, 'summary-done', ms: 1500);
      appNavigator.currentState!.popUntil((r) => r.isFirst);
      await wait(tester, 1200);
    }

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

    expect(releve['bilan'], isTrue);
    expect(releve['seance_moteur'], isTrue);
    expect(releve['bilan_detail'], isTrue);
    expect(releve['flammes'], isTrue);
    expect(releve['serie1_flammes'], 10);
    expect(releve['series_resumees'], contains('1'));
    expect(releve['fin_series'], isTrue);
    expect(releve['fin_seance'], isTrue);
    expect(releve['perso_seance_faite'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_programme'], isTrue);
    expect(releve['dev_seance_moteur'], isTrue);
    expect(releve['dev_flammes'], isTrue);
    expect(releve['dev_fin'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
