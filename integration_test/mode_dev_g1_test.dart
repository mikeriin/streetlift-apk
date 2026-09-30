// G1 (mode dev) sur émulateur Android, lancé par tools/ci3d_drive.sh avec
// le drapeau du build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/mode_dev_g1_test.dart \
//     --dart-define=KALIS_DEV=true --dart-define=M6B_PART=a -d emulator-5554
// L'application complète (kalisApp, comme main) est lancée.
// a (sombre) : session personnelle avec des données ; 5 appuis sur le logo
//   → ouverture au logo rose, premier écran d'une installation neuve ;
//   un écran de plus ; outils de test ; voyage d'une semaine ; accueil de
//   la session de test (logo rose). La session de test reste active.
// b (nouveau processus = redémarrage à froid, clair) : toujours en session
//   de test (date simulée conservée) ; appui long relâché avant 3 s
//   (annulé) ; appui long de 3 s → retour à la session personnelle, données
//   identiques (préférences clé par clé, export), plus aucune clé de test.
// Relevés `g1_releve_<partie>.json`, captures `g1_*.png`.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 5));
final _fixedAt = DateTime(2026, 10, 1, 12);
const _logoKey = ValueKey('header-logo');

File get _snapshotFile => File('${Directory.systemTemp.path}/g1_perso.json');

/// Égalité profonde de deux valeurs JSON (ordre des clés indifférent).
bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_same(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final releve = <String, Object?>{'partie': _part, 'kDevBuild': kDevBuild};
  binding.reportData = data;

  void record() => data['g1_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: _ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g1_$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Part des pixels rose vif (#FF1493 et ses bords adoucis) dans [rect].
  Future<double> pinkShare(Rect rect) async {
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    var total = 0, pink = 0;
    for (var y = rect.top; y < rect.bottom; y += 1) {
      for (var x = rect.left; x < rect.right; x += 1) {
        final px = (x * _ratio).round().clamp(0, image.width - 1);
        final py = (y * _ratio).round().clamp(0, image.height - 1);
        final o = (py * image.width + px) * 4;
        final r = rgba.getUint8(o), g = rgba.getUint8(o + 1);
        final b = rgba.getUint8(o + 2);
        total++;
        if (r > 200 && g < 90 && b > 100 && b < 200) pink++;
      }
    }
    image.dispose();
    return total == 0 ? 0 : pink / total;
  }

  Finder logo() => find.byKey(_logoKey).hitTestable();

  Future<double> logoPink(WidgetTester tester) async =>
      pinkShare(tester.getRect(logo().first));

  Map<String, Object?> persoRaw(SharedPreferences raw) =>
      KalisPrefs(raw, dev: false).snapshot();

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
  }

  /// Attend la fin d'une ouverture (initialisation du magasin comprise).
  Future<void> opened(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
          i > 25) {
        break;
      }
    }
    await wait(tester, 800);
  }

  if (_part == 'a') {
    testWidgets('G1 a (sombre) : 5 appuis → session de test', (tester) async {
      final raw = await SharedPreferences.getInstance();
      await raw.clear();
      // Session personnelle avec des données.
      final seed = AppStore();
      await seed.init();
      seed.settings
        ..theme = 'dark'
        ..accent = 'turquoise';
      seed.saveSettings();
      final real = DateTime.now();
      await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
      seed.saveProfile(seed.ownerDraft());
      final plan = seed.program.week(1).day(1);
      if (plan != null) {
        for (final ex in plan.exercises) {
          for (final set in seed.exLog(1, 1, ex).sets) {
            set
              ..done = true
              ..completedAt = real.toIso8601String();
          }
        }
        seed.saveLogs(immediate: true);
      }
      await seed.flush();

      await pumpApp(tester);
      await opened(tester);
      // État personnel au moment d'entrer dans la session de test (écritures
      // de l'ouverture comprises), comparé au retour (partie b).
      await store.flush();
      final snapshot = {
        'raw': persoRaw(raw),
        'export': store.exportForFile(appVersion: 'g1', at: _fixedAt),
      };
      _snapshotFile.writeAsStringSync(jsonEncode(snapshot));
      releve['perso_cles'] = (snapshot['raw']! as Map).length;
      releve['perso_dev_actif'] = DevSession.active.value;
      releve['perso_logo_rose'] = await logoPink(tester);
      await shot('a1_perso_accueil_sombre');

      // 5 appuis d'affilée sur le logo.
      for (var i = 0; i < 5; i++) {
        await tester.tap(logo().first);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await wait(tester, 700);
      final opening = find.byKey(const ValueKey('opening-logo'));
      releve['ouverture_logo_rose'] = opening.evaluate().isEmpty
          ? -1.0
          : await pinkShare(tester.getRect(opening));
      await shot('a2_ouverture_rose');
      await opened(tester);
      releve['dev_actif'] = DevSession.active.value;
      releve['dev_espace'] = SessionSpace.isDev;
      releve['dev_installation_neuve'] = store.isFreshInstall;
      releve['dev_premier_ecran'] = find
          .byKey(const ValueKey('flow-next-welcome'))
          .evaluate()
          .isNotEmpty;
      releve['dev_etiquette'] = find
          .byKey(const ValueKey('dev-badge'))
          .evaluate()
          .isNotEmpty;
      await shot('a3_dev_premier_ecran');
      await tester.tap(find.byKey(const ValueKey('flow-next-welcome')));
      await wait(tester, 1200);
      await shot('a4_dev_ecran_suivant');
      releve['perso_intact_apres_creation'] = _same(
        persoRaw(raw),
        snapshot['raw'],
      );

      // Profil et départ créés dans la session de test (comme au bout du
      // démarrage), pour voir l'accueil de la session de test.
      store.saveProfile(store.ownerDraft());
      await store.configureStart(
        DateTime(real.year, real.month, real.day - 3),
      );
      await store.flush();

      // Outils de test : appui long sur l'étiquette DEV.
      await tester.longPress(find.byKey(const ValueKey('dev-badge')));
      await wait(tester, 1200);
      releve['outils'] = find
          .byKey(const ValueKey('dev-tools'))
          .evaluate()
          .isNotEmpty;
      await shot('a5_outils_de_test');
      await tester.tap(find.byKey(const ValueKey('dev-plus-week')));
      await wait(tester, 300);
      await opened(tester);
      final now = KalisClock.now();
      releve['decalage_jours'] = KalisClock.offsetDays;
      releve['date_simulee'] = now.toIso8601String();
      releve['date_attendue_ok'] =
          DateTime(now.year, now.month, now.day) ==
          DateTime(real.year, real.month, real.day + 7);
      releve['dev_accueil'] = logo().evaluate().isNotEmpty;
      releve['dev_logo_rose'] = logo().evaluate().isEmpty
          ? 0.0
          : await logoPink(tester);
      await shot('a6_dev_accueil_logo_rose');
      releve['perso_intact_apres_voyage'] = _same(
        persoRaw(raw),
        snapshot['raw'],
      );
      releve['cles_dev'] = raw
          .getKeys()
          .where((k) => k.startsWith(SessionSpace.devPrefix))
          .length;
      // Partie b en clair : thème de la session de test.
      store.settings.theme = 'light';
      store.saveSettings();
      await store.flush();
      await wait(tester, 1500);
      record();

      expect(releve['perso_dev_actif'], isFalse);
      expect(releve['perso_logo_rose'] as double, lessThan(.01));
      expect(releve['ouverture_logo_rose'] as double, greaterThan(.05));
      expect(releve['dev_actif'], isTrue);
      expect(releve['dev_installation_neuve'], isTrue);
      expect(releve['dev_premier_ecran'], isTrue);
      expect(releve['dev_etiquette'], isTrue);
      expect(releve['perso_intact_apres_creation'], isTrue);
      expect(releve['outils'], isTrue);
      expect(releve['decalage_jours'], 7);
      expect(releve['date_attendue_ok'], isTrue);
      expect(releve['dev_accueil'], isTrue);
      expect(releve['dev_logo_rose'] as double, greaterThan(.05));
      expect(releve['perso_intact_apres_voyage'], isTrue);
    }, timeout: _limit);
  }

  if (_part == 'b') {
    testWidgets('G1 b (clair, redémarrage à froid) : retour à la session '
        'personnelle intacte', (tester) async {
      final raw = await SharedPreferences.getInstance();
      final snapshot =
          jsonDecode(_snapshotFile.readAsStringSync()) as Map<String, dynamic>;
      await DevSession.load();
      await pumpApp(tester);
      await opened(tester);
      releve['froid_dev_actif'] = DevSession.active.value;
      releve['froid_decalage_jours'] = KalisClock.offsetDays;
      releve['froid_logo_rose'] = logo().evaluate().isEmpty
          ? 0.0
          : await logoPink(tester);
      await shot('b1_dev_redemarrage_froid_clair');

      // Appui long relâché avant 3 s : annulé.
      final center = tester.getCenter(logo().first);
      var g = await tester.startGesture(center);
      await tester.pump();
      await wait(tester, 1500);
      releve['anneau_visible'] = find
          .byKey(const ValueKey('dev-hold-ring'))
          .evaluate()
          .isNotEmpty;
      await shot('b2_appui_long_anneau');
      await wait(tester, 1000);
      await g.up();
      await wait(tester, 800);
      releve['relache_avant_3s_dev_actif'] = DevSession.active.value;

      // Appui long de 3 s : suppression directe.
      g = await tester.startGesture(tester.getCenter(logo().first));
      await tester.pump();
      await wait(tester, 3300);
      await g.up();
      await wait(tester, 700);
      releve['message'] = find
          .text('Session de test supprimée')
          .evaluate()
          .isNotEmpty;
      await opened(tester);
      releve['retour_dev_actif'] = DevSession.active.value;
      releve['retour_decalage_jours'] = KalisClock.offsetDays;
      releve['retour_cles_reservees'] = raw
          .getKeys()
          .where(SessionSpace.reserved)
          .toList();
      final current = persoRaw(raw);
      releve['retour_perso_cles'] = current.length;
      releve['retour_perso_identique'] = _same(current, snapshot['raw']);
      releve['retour_export_identique'] = _same(
        jsonDecode(store.exportForFile(appVersion: 'g1', at: _fixedAt)),
        jsonDecode(snapshot['export'] as String),
      );
      releve['retour_logo_rose'] = logo().evaluate().isEmpty
          ? 1.0
          : await logoPink(tester);
      await shot('b3_retour_session_perso');
      record();

      expect(releve['froid_dev_actif'], isTrue);
      expect(releve['froid_decalage_jours'], 7);
      expect(releve['froid_logo_rose'] as double, greaterThan(.05));
      expect(releve['anneau_visible'], isTrue);
      expect(releve['relache_avant_3s_dev_actif'], isTrue);
      expect(releve['retour_dev_actif'], isFalse);
      expect(releve['retour_decalage_jours'], 0);
      expect(releve['retour_cles_reservees'], isEmpty);
      expect(releve['retour_perso_identique'], isTrue);
      expect(releve['retour_export_identique'], isTrue);
      expect(releve['retour_logo_rose'] as double, lessThan(.01));
    }, timeout: _limit);
  }
}
