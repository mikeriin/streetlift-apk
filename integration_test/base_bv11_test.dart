// BV11 (dev6.19.0, pipeline CP, base d'exercices v1.1, DECISIONS_CP.md
// C12.1, C17.9) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/base_bv11_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// 1. Session personnelle : programme de 40 semaines du propriétaire commencé
//    le 13/07/2026, journal saisi jusqu'à la veille (S1 à S14, sauvegarde
//    au format de dev6.18.0, noms enregistrés du programme). Au lancement :
//    mêmes séances, séries, records et séries par groupe qu'avant ;
//    sauvegarde d'origine présente ; STATS, une séance de l'historique
//    (anciens noms lisibles), Arsenal › Exercices : filtres Catégorie et
//    Muscle principal (vocabulaires fermés de la base v1.1), fiche.
// 2. Session de test (5 appuis sur le logo) : même bibliothèque et mêmes
//    filtres, fiche ; session personnelle intacte.
// Relevé `bv11_releve_<partie>.json`, captures `bv11_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/nav_bar.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

/// Relevé du journal : séances, séries validées, records, meilleures
/// performances, séries par groupe de chaque semaine saisie.
Map<String, Object?> _journal(AppStore app, int weeks) {
  final history = statsHistory(app);
  var sets = 0, records = 0;
  for (final h in history) {
    for (final e in h.session.ex.values) {
      sets += e.sets.where((s) => s.done).length;
    }
    records += app.sessionRecords(h.id).length;
  }
  final start = app.program.start ?? app.program.anchorMonday;
  return {
    'seances': history.length,
    'series': sets,
    'records': records,
    'meilleures': exerciseBests(app.logs).length,
    'groupes': [
      for (var w = 0; w < weeks; w++)
        {
          for (final e
              in app
                  .weeklyMuscles(
                    DateTime(
                      start.year,
                      start.month,
                      start.day + 7 * w + 6,
                      22,
                    ),
                  )
                  .entries)
            if (e.value > 0) e.key: (e.value * 1000).round(),
        },
    ],
  };
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

  void record() => data['bv11_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['bv11_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
      final lists = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (lists.evaluate().isEmpty) break;
      await tester.drag(lists.last, const Offset(0, -250));
      await wait(tester, 300);
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await wait(tester, 500);
    }
  }

  Future<void> tapKey(WidgetTester tester, String key, {int ms = 800}) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) return;
    await tester.ensureVisible(f.first);
    await wait(tester, 300);
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  int count() {
    final t = find.byKey(const ValueKey('library-count'));
    if (t.evaluate().isEmpty) return -1;
    final text = (t.evaluate().first.widget as Text).data ?? '';
    return int.tryParse(text.split(' ').first) ?? -1;
  }

  Future<void> back(WidgetTester tester) async {
    await appNavigator.currentState!.maybePop();
    await wait(tester, 1200);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  /// Bibliothèque : Catégorie « Tirage vertical », Muscle principal « grand
  /// dorsal », puis la fiche du premier résultat. Clé du relevé : [p].
  Future<void> library(WidgetTester tester, String p) async {
    ExerciseLibraryScreen.session = const FilterSelection();
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ExerciseLibraryScreen()),
      ),
    );
    await wait(tester, 1500);
    releve['${p}bibliotheque'] = count();
    await tapKey(tester, 'library-filters', ms: 1000);
    await tapKey(tester, 'library-filter-cat-categorie');
    await tapKey(tester, 'library-filter-cat:Tirage vertical');
    releve['${p}categorie'] = count();
    await tapKey(tester, 'library-filter-cat-muscle');
    await tapKey(tester, 'library-filter-mus:grand dorsal');
    releve['${p}muscle'] = count();
    await shot('${p}2_filtres');
    await tester.tapAt(const Offset(5, 5));
    await wait(tester, 1000);
    await shot('${p}3_liste_filtree');
    final rows = find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> && k.value.startsWith('library-ex-');
    });
    if (rows.evaluate().isNotEmpty) {
      final key = (tester.widget(rows.first).key! as ValueKey<String>).value;
      releve['${p}fiche_id'] = key.substring('library-ex-'.length);
      await tester.ensureVisible(rows.first);
      await wait(tester, 300);
      await tester.tap(rows.first);
      await wait(tester, 1500);
      releve['${p}fiche'] = find
          .byKey(const ValueKey('fiche-titre'))
          .evaluate()
          .isNotEmpty;
      await shot('${p}4_fiche');
      await scrollTo(tester, find.byKey(const ValueKey('fiche-materiel')));
      releve['${p}fiche_materiel'] = find
          .byKey(const ValueKey('fiche-materiel'))
          .evaluate()
          .isNotEmpty;
      await shot('${p}5_fiche_muscles_materiel');
    }
    ExerciseLibraryScreen.session = const FilterSelection();
    await home(tester);
  }

  testWidgets('BV11 $_part ($theme, $accent) : base v1.1, historique gardé, '
      'filtres, sessions perso et de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Sauvegarde du propriétaire : programme commencé le 13/07/2026,
    // journal saisi jusqu'à la veille (S14 au plus).
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
    // Profil enregistré (sinon l'invitation au profil v3 couvre l'accueil).
    seed.seedSampleAthleteProfile();
    await seed.flush();
    final weeks = logs.keys
        .map((k) => int.parse(RegExp(r'^S(\d+)').firstMatch(k)![1]!))
        .fold<int>(0, (a, w) => w > a ? w : a);
    releve['semaines_saisies'] = weeks;
    final before = _journal(seed, weeks);
    releve['journal_avant'] = before;
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    final after = _journal(store, weeks);
    releve['journal_identique'] = jsonEncode(after) == jsonEncode(before);
    releve['origine_presente'] = store.programOrigin != null;
    releve['catalogue_exercices'] = store.content.entries.length;
    final names = <String>{
      for (final log in store.logs.values) ...log.exerciseNames.values,
    };
    releve['noms_journal'] = names.length;
    releve['noms_sans_id'] = [
      for (final n in names)
        if (store.content.idFor(n) == null) n,
    ];
    final persoLogs = jsonEncode(
      (jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs'],
    );
    await shot('1_accueil');

    // STATS : séries par groupe (groupes historiques des anciens noms).
    releve['onglet_stats'] = AppTabs.open(
      appNavigator.currentContext!,
      AppTab.stats,
    );
    await wait(tester, 1800);
    await shot('1b_stats');
    await home(tester);

    // Une séance de l'historique : noms enregistrés lisibles.
    final log = store.logs[store.sessionKey(1, 1)];
    releve['historique_s1j1'] = log != null;
    if (log != null) {
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SessionHistoryScreen(
              log: log,
              sessionKey: store.sessionKey(1, 1),
              week: store.program.week(1),
              day: store.program.week(1).day(1),
            ),
          ),
        ),
      );
      await wait(tester, 1800);
      // Un des noms enregistrés (tels quels, casse ignorée) est affiché.
      final saved = [
        for (final n in log.exerciseNames.values)
          store.splitName(n).$1.toLowerCase(),
      ];
      final shown = find.byWidgetPredicate((w) {
        final text = w is Text
            ? (w.data ?? w.textSpan?.toPlainText())
            : (w is RichText ? w.text.toPlainText() : null);
        if (text == null) return false;
        final t = text.toLowerCase();
        return saved.any((n) => n.isNotEmpty && t.contains(n));
      });
      final hit = shown.evaluate().firstOrNull?.widget;
      releve['historique_nom'] = hit is Text
          ? hit.data ?? hit.textSpan?.toPlainText()
          : (hit is RichText ? hit.text.toPlainText() : null);
      releve['historique_nom_lisible'] = hit != null;
      await shot('1c_historique');
      await home(tester);
    }

    // Arsenal › Exercices : filtres de la base v1.1, fiche.
    await library(tester, '');

    // Session de test : même base et mêmes filtres.
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
    await library(tester, 'dev_');
    await store.flush();
    final stored = raw.getString('kalis_state_v3') ?? '';
    releve['perso_journal_intact'] =
        stored.isNotEmpty && _logsOf(stored) == persoLogs;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['import'], isTrue);
    expect(releve['journal_identique'], isTrue);
    expect(releve['origine_presente'], isTrue);
    expect(releve['catalogue_exercices'], 1039);
    expect(
      (releve['noms_sans_id'] as List).every((n) => '$n'.startsWith('BILAN')),
      isTrue,
    );
    expect(releve['historique_nom_lisible'], isTrue);
    for (final p in const ['', 'dev_']) {
      expect(releve['${p}bibliotheque'], 1039, reason: p);
      expect(releve['${p}categorie'] as int, greaterThan(0), reason: p);
      expect(releve['${p}categorie'] as int, lessThan(1039), reason: p);
      expect(releve['${p}muscle'] as int, greaterThan(0), reason: p);
      expect(
        releve['${p}muscle'] as int,
        lessThanOrEqualTo(releve['${p}categorie'] as int),
        reason: p,
      );
      expect(releve['${p}fiche'], isTrue, reason: p);
      expect(releve['${p}fiche_materiel'], isTrue, reason: p);
    }
    expect(releve['dev_actif'], isTrue);
    expect(releve['perso_journal_intact'], isTrue);
  }, timeout: _limit);
}

/// Journal d'un document d'état enregistré (compressé ou non).
String _logsOf(String stored) {
  final text = stored.startsWith('gz:')
      ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
      : stored;
  return jsonEncode((jsonDecode(text) as Map<String, dynamic>)['logs']);
}
