// G2 (dev6.1.0) sur émulateur Android, lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/retrait_g2_test.dart \
//     --dart-define=M6B_PART=a -d emulator-5554
// a = thème sombre, b = thème clair. L'application complète (kalisApp,
// comme main) démarre sur le document d'état d'un utilisateur de 6.0.x :
// programme commencé, journées faites, profil, WOD joués et débloqués,
// séances perso, crédits, données « Motivation ». Écrans : annonce de la
// suppression (haut et bas), accueil et barre de navigation, Arsenal,
// STATS, Réglages › Données et confidentialité (copie). Relevé
// `g2_releve_<partie>.json` : copie, document réécrit, éléments retirés
// absents. Captures `g2_*.png`, regardées avant livraison.
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/retired_data.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/support/retired_fixtures.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 5));
const _key = 'kalis_state_v3';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final theme = _part == 'a' ? 'sombre' : 'clair';
  final releve = <String, Object?>{'partie': _part, 'theme': theme};
  binding.reportData = data;

  void record() => data['g2_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  /// Captures à 1 px par dp (360 × 640), renvoi léger au pilote.
  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g2_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  bool shown(String text) => find.text(text).evaluate().isNotEmpty;

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
        const Offset(0, -250),
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

  testWidgets('G2 $_part ($theme) : annonce, copie, écrans sans WOD', (
    tester,
  ) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    // Utilisateur du programme (profil, départ, journées faites), écrit par
    // l'application elle-même, puis complété des données de 6.0.x.
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = _part == 'a' ? 'dark' : 'light';
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.seedSampleAthleteProfile();
    final plan = seed.program.week(1).day(1);
    if (plan != null) {
      for (final ex in plan.exercises) {
        for (final set in seed.exLog(1, 1, ex).sets) {
          set
            ..done = true
            ..completedAt = real.toIso8601String();
        }
      }
      seed.markSessionDone(1, 1, true);
    }
    await seed.flush();
    final program = jsonDecode(seed.exportAll()) as Map<String, dynamic>;
    seed.dispose();
    final old = withRetiredData(program);
    await raw.setString(_key, jsonEncode(old));
    releve['journal_programme'] = (program['logs'] as Map).length;

    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    final notice = store.retiredNotice;
    releve['copie'] = notice?.toJson();
    releve['copie_relue'] = store.retiredCopy != null;
    final stored = raw.getString(_key)!;
    final doc =
        jsonDecode(
              stored.startsWith('gz:')
                  ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
                  : stored,
            )
            as Map<String, dynamic>;
    releve['document_sans_sections_retirees'] = !doc.keys.any(
      kRetiredSections.contains,
    );
    releve['journal_sans_seances_perso'] = !(doc['logs'] as Map).keys.any(
      (k) => isManualSessionKey(k as String),
    );
    releve['journal_programme_apres'] = (doc['logs'] as Map).length;
    releve['annonce'] = find
        .byKey(const ValueKey('retired-notice'))
        .evaluate()
        .isNotEmpty;
    await shot('1_annonce');
    await scrollTo(tester, find.byKey(const ValueKey('retired-notice-close')));
    await shot('2_annonce_bas');
    await tester.tap(find.byKey(const ValueKey('retired-notice-close')));
    await wait(tester, 1500);
    releve['annonce_vue'] = store.retiredNotice?.seen;
    await shot('3_accueil');

    await tab(tester, 0);
    releve['arsenal_sans_wod'] =
        !shown('Mes WODs') &&
        !shown('Nouvelle séance') &&
        !shown('Mes séances');
    releve['arsenal_tuiles'] = [
      for (final k in ['arsenal-exercises', 'arsenal-anatomy'])
        if (find.byKey(ValueKey(k)).evaluate().isNotEmpty) k,
    ];
    await shot('4_arsenal');

    await tab(tester, 1);
    await scrollTo(tester, find.text('Tout ton historique'));
    releve['stats_sans_mes_progres'] = !shown('Mes progrès');
    await shot('5_stats');

    await tab(tester, 3);
    Future<void> section(String title) async {
      final tile = find.text(title);
      await scrollTo(tester, tile);
      await tester.tap(tile.first);
      await wait(tester, 1200);
    }

    // UI4 : les sauvegardes sont dans « Données et confidentialité ».
    await section('Données et confidentialité');
    final copyTile = find.byKey(const ValueKey('settings-retired-copy'));
    await scrollTo(tester, copyTile);
    releve['reglages_copie'] = copyTile.evaluate().isNotEmpty;
    await shot('6_reglages_sauvegardes');
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1200);
    // UI4 : plus de rubrique « Programme » dans les Réglages ; la racine
    // liste toutes les rubriques.
    releve['reglages_sans_motivation'] = !shown('Motivation et progression');
    await shot('7_reglages_racine');
    record();

    expect(releve['copie'], isNotNull);
    expect(releve['copie_relue'], isTrue);
    expect(releve['document_sans_sections_retirees'], isTrue);
    expect(releve['journal_sans_seances_perso'], isTrue);
    expect(releve['journal_programme_apres'], releve['journal_programme']);
    expect(releve['annonce'], isTrue);
    expect(releve['annonce_vue'], isTrue);
    expect(releve['arsenal_sans_wod'], isTrue);
    expect(releve['arsenal_tuiles'], ['arsenal-exercises', 'arsenal-anatomy']);
    expect(releve['stats_sans_mes_progres'], isTrue);
    expect(releve['reglages_copie'], isTrue);
    expect(releve['reglages_sans_motivation'], isTrue);
  }, timeout: _limit);
}
