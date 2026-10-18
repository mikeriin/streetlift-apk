// KM3 (dev7.0.0, Koach 1.0, DECISIONS_CP.md C13, C17.14) sur émulateur
// Android, lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_km3_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// 1. Session personnelle : programme de 40 semaines du propriétaire
//    commencé le 13/07/2026, journal jusqu'à la veille (format de
//    dev6.19.0). Koach 1.0 installé, bascule fermée dans ce build : le
//    bloc en cours continue comme avant (moteur d'avant), date de bascule
//    du cahier, journal identique, sauvegarde d'origine ; Réglages › Koach
//    1.0 ; export du journal moteur disponible avant la bascule.
// 2. Session de test (5 appuis sur le logo) : même sauvegarde importée,
//    bascule forcée : prise de main (rejeu, replanification) mesurée sur
//    l'émulateur ; séance du jour servie par Koach (bilan, premier
//    exercice, cible par série, temps d'une série), suggestion refusée
//    avec une raison, fin de séance versée ; Évolution ; inspecteur (temps
//    réels) ; arrêt d'urgence puis réactivation ; session personnelle
//    intacte.
// Relevé `km3_releve_<partie>.json`, captures `km3_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart' show civilOf;
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/dev/koach_inspector.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/nav_bar.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 9));

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

  void record() => data['km3_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['km3_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 80}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
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

  Future<void> tapKey(WidgetTester tester, String key, {int ms = 800}) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) return;
    await tester.ensureVisible(f.first);
    await wait(tester, 300);
    if (f.hitTestable().evaluate().isEmpty) return;
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  Future<void> push(WidgetTester tester, Widget page, {int ms = 1500}) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  /// Sauvegarde du propriétaire : programme commencé le 13/07/2026, journal
  /// saisi jusqu'à la veille (S14 au plus).
  Map<String, dynamic> backup(AppStore seed) {
    final real = DateTime.now();
    final today = DateTime(real.year, real.month, real.day);
    final b = filledBackup(seed);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    logs.removeWhere((k, _) {
      final m = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(k);
      if (m == null) return true;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      final day = DateTime(2026, 7, 13 + (w - 1) * 7 + j - 1);
      return w > 14 || !day.isBefore(today);
    });
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    return b;
  }

  testWidgets('KM3 $_part ($theme, $accent) : Koach 1.0, sessions perso et '
      'de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    final b = backup(seed);
    releve['import'] = await seed.importAll(jsonEncode(b));
    seed.seedSampleAthleteProfile();
    await seed.flush();
    final logsBefore = jsonEncode(
      (jsonDecode(seed.exportAll()) as Map<String, dynamic>)['logs'],
    );
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    await store.koachRefresh();
    await wait(tester, 800);

    // 1. Session personnelle : bascule fermée, rien ne change.
    releve['perso_koach_actif'] = store.koachEngine.snap != null;
    releve['perso_bascule'] = store.koachBasculeDate.iso;
    releve['perso_installation'] = store.koachEngine.installedOn;
    releve['perso_origine'] = store.programOrigin != null;
    releve['perso_journal_identique'] =
        jsonEncode(
          (jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs'],
        ) ==
        logsBefore;
    final now = store.storeClock();
    final w = store.program.weekFor(now);
    final j = store.program.offsetOf(now)! % 7 + 1;
    releve['jour'] = 'S$w-J$j';
    final exp = await store.koachJournalExport();
    releve['perso_export_seances'] = (exp?['seances'] as List?)?.length;
    releve['perso_export_type'] = exp?['type'];
    await push(
      tester,
      const KPage.sub(
        key: ValueKey('koach-engine-page'),
        title: 'Koach 1.0',
        children: [KoachEngineCard()],
      ),
    );
    releve['perso_carte_attente'] = find
        .byKey(const ValueKey('koach-engine-waiting'))
        .evaluate()
        .isNotEmpty;
    await shot('1_perso_koach');
    await home(tester);

    // 2. Session de test : la même sauvegarde, bascule forcée.
    AppTabs.open(appNavigator.currentContext!, AppTab.program);
    await wait(tester, 1200);
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    if (logo.evaluate().isNotEmpty) {
      for (var i = 0; i < 5; i++) {
        await tester.tap(logo.first);
        await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
      }
      await opened(tester);
    }
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_espace'] = SessionSpace.isDev;
    releve['dev_import'] = await store.importAll(jsonEncode(b));
    store.seedSampleAthleteProfile();
    store.koachForceBascule(civilOf(store.storeClock()));
    final sw = Stopwatch()..start();
    await store.koachRefresh();
    releve['dev_prise_de_main_ms'] = sw.elapsedMilliseconds;
    releve['dev_koach_actif'] = store.koachEngine.snap != null;
    releve['dev_depuis'] = store.koachEngine.fromWeek;
    releve['dev_evenements'] = store.koachEngine.journal.length;
    await wait(tester, 800);

    // Séance du jour servie par Koach (première journée avec exercices à
    // partir d'aujourd'hui dans la semaine).
    // Jour du test : aujourd'hui, ou la semaine suivante quand il ne reste
    // plus de journée d'entraînement dans la semaine (un dimanche).
    var wd = w;
    var jd = j;
    while (jd <= 7 &&
        (store.program.week(wd).day(jd)?.exercises.isEmpty ?? true)) {
      jd++;
    }
    if (jd > 7) {
      // (Horloge de l'application avancée au lundi : séance du jour réel.)
      final now0 = store.storeClock();
      KalisClock.setOffsetDays(8 - now0.weekday);
      await store.koachRefresh();
      await wait(tester, 800);
      wd = w + 1;
      jd = 1;
    }
    final week = store.program.week(wd);
    while (jd <= 7 && (week.day(jd)?.exercises.isEmpty ?? true)) {
      jd++;
    }
    releve['dev_seance'] = 'S$wd-J$jd';
    if (jd <= 7) {
      final day = week.day(jd)!;
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SessionScreen(week: week, day: day),
          ),
        ),
      );
      await until(tester, find.byKey(const ValueKey('health-question')));
      await wait(tester, 800);
      releve['dev_apercu'] = store.koachPending(wd, jd);
      await shot('2_bilan');
      await tapKey(tester, 'feel-4', ms: 300);
      // Début réel (rattrapage, `seance_debut`, `plan(seance)`) : attendu
      // jusqu'à 60 s, diagnostic hors modèle éventuel passé (« Plus tard »).
      final debut = Stopwatch()..start();
      final appuis = <String>[];
      while (!store.koachOpen(wd, jd) && debut.elapsedMilliseconds < 60000) {
        await wait(tester, 250);
        for (final k in const [
          'koach-diag-later',
          'adjust-go',
          'bilan-start',
        ]) {
          final f = find.byKey(ValueKey(k)).hitTestable();
          if (f.evaluate().isNotEmpty) {
            appuis.add(k);
            await tester.tap(f.first);
            await wait(tester, 300);
          }
        }
      }
      releve['dev_debut_ms'] = debut.elapsedMilliseconds;
      releve['dev_debut_appuis'] = appuis;
      releve['dev_temps_debut'] = store.koachTemps.toJson();
      await wait(tester, 1000);
      releve['dev_seance_ouverte'] = store.koachOpen(wd, jd);
      final a = store.sessionAdapt(wd, jd);
      releve['dev_items_servis'] = (a?.koach?['items'] as List?)?.length;
      await shot('3_exercice');
      // Première série : cible de Koach, validée ; temps d'une série.
      final served = store
          .adaptDay(wd, day, a!)
          .exercises
          .where((e) => e.engine && e.slotId != null)
          .toList();
      if (served.isNotEmpty) {
        final e = served.first;
        final log = store.exLog(wd, jd, e);
        store.adaptPrefill(wd, jd, e, log);
        final g = store.adaptGoal(wd, jd, e, 0);
        releve['dev_cible_0'] = g == null
            ? null
            : {'kg': g.kg, 'bas': g.low, 'haut': g.high, 'flammes': g.flames};
        if (log.sets.isNotEmpty) {
          if (log.sets[0].reps.isEmpty) log.sets[0].reps = '${g?.prefill ?? 5}';
          log.sets[0].flames = 8;
          final ok = store.toggleSet(log, 0, store.logSpec(e)).ok;
          releve['dev_serie_validee'] = ok;
          final t = Stopwatch()..start();
          store.koachAfterSet(wd, day, e, 0);
          releve['dev_serie_ms'] = t.elapsedMicroseconds / 1000;
        }
        // Suggestion (forme d'adhérence) posée sur la première série du
        // deuxième exercice, puis refusée « trop lourd » dans l'écran.
        if (served.length > 1) {
          final e2 = served[1];
          final log2 = store.exLog(wd, jd, e2);
          store.adaptPrefill(wd, jd, e2, log2);
          final a2 = store.sessionAdapt(wd, jd)!;
          final st = Map<String, Object?>.of(a2.koach!);
          final cibles = Map<String, Object?>.of(
            ((st['cibles'] as Map?) ?? const {}).cast<String, Object?>(),
          );
          final m = Map<String, Object?>.of(
            ((cibles[e2.slotId] as Map?) ?? const {}).cast<String, Object?>(),
          );
          m['0'] = {
            ...((m['0'] as Map?) ?? const {}).cast<String, Object?>(),
            'proposition': {
              'type': 'charge_plus',
              'depart': 20.0,
              'cible': 22.5,
              'pas': 2.5,
              'ampleur': 1.0,
              'paliers': [22.5],
              'moment': 'debut_de_seance',
            },
          };
          cibles[e2.slotId!] = m;
          st['cibles'] = cibles;
          store.sessionLog(wd, jd).adapt = a2
              .copyWith(koach: st)
              .toJson()
              .cast<String, dynamic>();
          store.notifyListeners();
          final pages = find.byType(PageView);
          if (pages.evaluate().isNotEmpty) {
            final ctl = tester.widget<PageView>(pages.first).controller;
            for (var p = 1; p < 12; p++) {
              if (find
                  .byKey(ValueKey('koach-suggestion-${e2.id}'))
                  .evaluate()
                  .isNotEmpty) {
                break;
              }
              ctl?.jumpToPage(p);
              await wait(tester, 900);
            }
          }
          releve['dev_suggestion_visible'] = find
              .byKey(ValueKey('koach-suggestion-${e2.id}'))
              .evaluate()
              .isNotEmpty;
          await tapKey(tester, 'koach-suggestion-${e2.id}', ms: 300);
          await shot('4_suggestion');
          await tapKey(tester, 'koach-refuse-${e2.id}', ms: 1200);
          await shot('5_refus_raisons');
          final heavy = find.text('Trop lourd');
          if (heavy.evaluate().isNotEmpty) {
            await tester.tap(heavy.first);
            await wait(tester, 1200);
          }
          releve['dev_suggestion_refusee'] = store
              .koachSuggestion(wd, jd, e2)
              ?.decided;
          await shot('6_refuse');
        }
      }
      store.markSessionDone(wd, jd, true);
      await wait(tester, 800);
      releve['dev_versee'] = store.koachEngine.versed.contains(
        store.sessionKey(wd, jd),
      );
      final dec = store.koachEngine.journal.where(
        (x) => x['type'] == 'decision' && x['proposition'] != null,
      );
      releve['dev_decision_raison'] = dec.isEmpty ? null : dec.last['raison'];
      await home(tester);
    }

    // Évolution, inspecteur, arrêt d'urgence et réactivation.
    await push(tester, const EvolutionScreen());
    releve['dev_evolution_actif'] = find
        .byKey(const ValueKey('koach-engine-active'))
        .evaluate()
        .isNotEmpty;
    await shot('7_evolution');
    await home(tester);
    await push(tester, const KoachInspectorScreen(), ms: 2500);
    await shot('8_inspecteur');
    releve['dev_temps'] = store.koachTemps.toJson();
    await home(tester);
    await push(
      tester,
      const KPage.sub(
        key: ValueKey('koach-engine-page'),
        title: 'Koach 1.0',
        children: [KoachEngineCard()],
      ),
    );
    await tapKey(tester, 'koach-stop', ms: 1200);
    final confirm = find.text('Arrêter');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm.last);
      await wait(tester, 1200);
    }
    releve['dev_arret'] = store.koachEngine.stop != null;
    await shot('9_arret');
    await tapKey(tester, 'koach-resume', ms: 2500);
    await store.koachRefresh();
    releve['dev_reactive'] =
        store.koachEngine.stop == null && store.koachLive != null;
    await shot('10_reactive');
    await home(tester);
    await store.flush();

    KalisClock.setOffsetDays(0);
    final stored = raw.getString('kalis_state_v3') ?? '';
    releve['perso_intacte'] = stored.isNotEmpty;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['perso_koach_actif'], isFalse);
    expect(releve['perso_journal_identique'], isTrue);
    expect(releve['perso_origine'], isTrue);
    expect(releve['perso_export_type'], 'journal_moteur');
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_koach_actif'], isTrue);
    expect(releve['dev_seance_ouverte'], isTrue);
    expect(releve['dev_versee'], isTrue);
    expect(releve['dev_arret'], isTrue);
    expect(releve['dev_reactive'], isTrue);
    final temps = releve['dev_temps'] as Map;
    final rep = temps['replanification'] ?? temps['prise_de_main'];
    if (rep is Map) expect((rep['max_ms'] as num) < 10000, isTrue);
    final serie = temps['plan_serie'];
    if (serie is Map) expect((serie['max_ms'] as num) < 50, isTrue);
  }, timeout: _limit);
}
