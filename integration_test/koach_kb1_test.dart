// KB1 (dev7.2.0, Koach 1.0.5 et `kalis_plan` 0.4.2, bascule fermée,
// DECISIONS_CP.md C17.30) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_kb1_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// 1. Session personnelle (migration depuis dev7.1.9) : programme de 40
//    semaines du propriétaire commencé le 13/07/2026, journal saisi
//    jusqu'à la veille (S1 à S14). Au lancement : même journal, sauvegarde
//    d'origine, Koach pas actif (bascule fermée), date de bascule
//    inchangée ; inspecteur de Koach : versions 1.0.5, « Exporter le
//    journal moteur » (fichier capté) au format de walk_forward.
// 2. Session de test : profil street 50 / 50 à six séances, poignet très
//    gêné : création, carte « Structure de la semaine » avec la raison du
//    changement de type des jours de poussée ; puis la sauvegarde du
//    propriétaire, bascule forcée : prise de main par Koach 1.0.5,
//    inspecteur, export du journal moteur ; suppression de la session de
//    test, session personnelle intacte.
// Relevé `kb1_releve_<partie>.json`, captures `kb1_*_<thème>.png`.
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
import 'package:streetlift_tracker/dev/koach_inspector.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/nav_bar.dart';
import 'package:streetlift_tracker/plan/plan_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 9));

/// Profil street 50 / 50 à six séances, salle complète, poignet très gêné
/// (comme test/kb1_koach105_test.dart).
kc.AthleteProfile _wrist(kc.CivilDate on) {
  final p = sampleStreet5050Profile(on: on);
  return p.copyWith(
    equipment: <String>{
      ...p.equipment,
      'barre basse',
      'élastique',
      'banc plat',
      'haltères',
      'poulie',
      'anneaux',
      'tapis',
    }.toList(),
    limitations: const <kc.Limitation>[
      kc.Limitation(
        zone: kc.BodyZone.wristHand,
        side: kc.BodySide.both,
        joint: kc.Joint.wrist,
        discomfort: 6,
        since: kc.ConstraintSince.under6Weeks,
      ),
    ],
  );
}

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

  void record() => data['kb1_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['kb1_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
    AppTabs.open(appNavigator.currentContext!, AppTab.program);
    await wait(tester, 1200);
  }

  Future<void> push(WidgetTester tester, Widget page, {int ms = 1500}) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => page),
      ),
    );
    await wait(tester, ms);
  }

  /// Fait défiler la liste visible jusqu'à [target] (vers le bas).
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
      final lists = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (lists.evaluate().isEmpty) break;
      final s = tester.state<ScrollableState>(lists.last).position;
      if (s.pixels >= s.maxScrollExtent) break;
      await tester.drag(lists.last, const Offset(0, -250));
      await wait(tester, 300);
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await wait(tester, 400);
    }
  }

  /// Inspecteur de Koach ouvert, « Exporter le journal moteur » touché :
  /// fichier capté (nom, JSON décodé) ; capture [name].
  Future<Map<String, Object?>> inspectAndExport(
    WidgetTester tester,
    String name,
  ) async {
    final out = <String, Object?>{};
    DevShare.debugHook = (n, text) async {
      if (n != null && text != null) {
        out['fichier'] = n;
        out['json'] = jsonDecode(text);
      }
      return 'shared';
    };
    await push(tester, const KoachInspectorScreen(), ms: 2500);
    out['inspecteur'] = find
        .byKey(const ValueKey('koach-inspector'))
        .evaluate()
        .isNotEmpty;
    out['versions_1_0_5'] = find
        .textContaining('1.0.5-ref.1')
        .evaluate()
        .isNotEmpty;
    await shot(name);
    final b = find.byKey(const ValueKey('ki-export-journal'));
    await scrollTo(tester, b);
    if (b.hitTestable().evaluate().isNotEmpty) {
      await tester.tap(b.hitTestable().first);
      for (var i = 0; i < 300 && out['json'] == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await wait(tester, 800);
    }
    DevShare.debugHook = null;
    final j = out['json'];
    if (j is Map) {
      out['type'] = j['type'];
      out['version_moteur'] = j['version_moteur'];
      out['version_parametres'] = j['version_parametres'];
      out['seances'] = (j['seances'] as List?)?.length;
      out['prise_de_main'] = j['prise_de_main'];
    }
    out.remove('json');
    await home(tester);
    return out;
  }

  testWidgets('KB1 $_part ($theme, $accent) : Koach 1.0.5 bascule fermée, '
      'export du journal moteur, structure de la semaine ; sessions perso '
      'et de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Sauvegarde du propriétaire au format de dev7.1.9 : programme
    // commencé le 13/07/2026, journal saisi jusqu'à la veille (S14 au
    // plus).
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
    await until(tester, find.byKey(const ValueKey('header-logo')));
    await store.koachRefresh();
    await wait(tester, 800);

    // 1. Session personnelle : migration, bascule fermée.
    releve['journal_identique'] =
        jsonEncode(
          (jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs'],
        ) ==
        logsBefore;
    releve['origine_presente'] = store.programOrigin != null;
    releve['koach_actif'] = store.koachEngine.snap != null;
    releve['bascule'] = store.koachBasculeDate.iso;
    releve['installation'] = store.koachEngine.installedOn;
    await shot('1_accueil_perso');
    releve['perso_inspecteur'] = await inspectAndExport(
      tester,
      '2_inspecteur_perso',
    );
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 2. Session de test (5 appuis sur le logo de l'accueil).
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 30 && logo.evaluate().isEmpty; i++) {
      final lists = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (lists.evaluate().isEmpty) break;
      await tester.drag(lists.first, const Offset(0, 300));
      await wait(tester, 300);
    }
    releve['logo_visible'] = logo.evaluate().isNotEmpty;
    for (var i = 0; i < 5 && logo.evaluate().isNotEmpty; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_espace'] = SessionSpace.isDev;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();

    // 2a. Création : jours de poussée qui changent de type (poignet).
    final monday = (DateTime.monday - real.weekday + 7) % 7;
    KalisClock.setOffsetDays(monday);
    releve['profil'] =
        store.saveAthleteProfile(
          ProfileDraft.of(_wrist(civilOf(KalisClock.now())))
            ..consent = 'refused',
        ) !=
        null;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const PlanCreationScreen()),
      ),
    );
    final card = find.byKey(const ValueKey('plan-structure'));
    releve['structure'] = await until(tester, card, max: 300);
    await wait(tester, 1200);
    final change = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'plan-structure-change-',
          ),
    );
    releve['changements'] = change.evaluate().length;
    if (change.evaluate().isNotEmpty) {
      await scrollTo(tester, change);
      final texts = find.descendant(
        of: change.first,
        matching: find.byType(Text),
      );
      releve['changement_texte'] = texts.evaluate().isEmpty
          ? null
          : (texts.evaluate().first.widget as Text).data;
    }
    await shot('3_structure_semaine');
    await home(tester);
    KalisClock.setOffsetDays(0);

    // 2b. Sauvegarde du propriétaire, bascule forcée : Koach 1.0.5.
    releve['dev_import'] = await store.importAll(jsonEncode(b));
    store.seedSampleAthleteProfile();
    store.koachForceBascule(civilOf(store.storeClock()));
    final sw = Stopwatch()..start();
    await store.koachRefresh();
    releve['dev_prise_de_main_ms'] = sw.elapsedMilliseconds;
    releve['dev_koach_actif'] = store.koachEngine.snap != null;
    releve['dev_version_moteur'] = store.koachEngine.snap?.versionMoteur;
    releve['dev_parametres'] = store.koachLive?.params['version'];
    releve['dev_evenements'] = store.koachEngine.journal.length;
    await wait(tester, 800);
    releve['dev_inspecteur'] = await inspectAndExport(
      tester,
      '4_inspecteur_dev',
    );

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

    expect(releve['import'], isTrue);
    expect(releve['journal_identique'], isTrue);
    expect(releve['origine_presente'], isTrue);
    expect(releve['koach_actif'], isFalse);
    expect(releve['bascule'], anyOf('2026-11-23', '2027-01-04'));
    final perso = releve['perso_inspecteur']! as Map;
    expect(perso['inspecteur'], isTrue);
    expect(perso['fichier'], 'koach_journal_moteur.json');
    expect(perso['type'], 'journal_moteur');
    expect(perso['version_moteur'], '1.0.5-ref.1');
    expect(perso['version_parametres'], '1.0.5-ref.1');
    expect(perso['seances'] as int, greaterThan(0));
    expect(releve['dev_actif'], isTrue);
    expect(releve['profil'], isTrue);
    expect(releve['structure'], isTrue);
    expect(releve['changements'] as int, greaterThan(0));
    expect('${releve['changement_texte']}', contains('zone à ménager'));
    expect(releve['dev_import'], isTrue);
    expect(releve['dev_koach_actif'], isTrue);
    expect(releve['dev_version_moteur'], '1.0.5-ref.1');
    expect(releve['dev_parametres'], '1.0.5-ref.1');
    final dev = releve['dev_inspecteur']! as Map;
    expect(dev['versions_1_0_5'], isTrue);
    expect(dev['type'], 'journal_moteur');
    expect(dev['version_moteur'], '1.0.5-ref.1');
    expect(dev['seances'] as int, greaterThan(0));
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
