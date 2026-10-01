// G3 (dev6.2.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec le
// build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/catalogue_g3_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, b = thème clair. L'application complète (kalisApp,
// comme main) démarre sur une session personnelle avec un historique
// (programme commencé, S1·J1 faite). Écrans : Arsenal › Exercices (base
// v1.1, 1 039 exercices), menu Filtres (discipline), liste filtrée,
// recherche, une fiche de chaque discipline (haut de fiche), carte des
// muscles d'une fiche, puis la même bibliothèque dans la session de test
// (5 appuis sur le logo). Relevé `g3_releve_<partie>.json`, captures
// `g3_*_<thème>.png`, regardées avant livraison.
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
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 5));

/// Un exercice par discipline de la base v1.1.
const _fiches = {
  'musculation': 'mu-developpe-couche-barre',
  'street_workout': 'sw-traction-pronation',
  'streetlifting': 'sl-squat-competition',
  'calisthenie_statique': 'cs-planche-tuck',
  'calisthenie_dynamique': 'cd-muscle-up-barre-strict',
  'crossfit': 'cf-burpee',
  'cardio': 'ca-footing-endurance-fondamentale',
  'mobilite': 'mo-routine-mobilite-epaules-poignets',
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final theme = _part == 'a' ? 'sombre' : 'clair';
  final releve = <String, Object?>{'partie': _part, 'theme': theme};
  binding.reportData = data;

  void record() => data['g3_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  /// Captures à 1 px par dp (360 × 640), renvoi léger au pilote.
  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['g3_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .last,
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

  testWidgets('G3 $_part ($theme) : base v1.1 dans Arsenal, fiches, session '
      'de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = _part == 'a' ? 'dark' : 'light';
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

    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['catalogue_version'] = store.content.version;
    releve['catalogue_exercices'] = store.content.entries.length;
    final journal = store.coreTrainingLog();
    releve['journal_converti'] = journal.report.toJson();
    releve['journal_valide'] = journal.log.validate().isEmpty;
    final persoLogs = jsonEncode(
      (jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs'],
    );

    // Arsenal › Exercices.
    await tab(tester, 0);
    await tester.tap(find.byKey(const ValueKey('arsenal-exercises')));
    await wait(tester, 1500);
    releve['bibliotheque'] = count();
    await shot('1_bibliotheque');

    // Filtres : discipline Streetlifting.
    await tester.tap(find.byKey(const ValueKey('library-filters')));
    await wait(tester, 1000);
    await shot('2_filtres');
    await tester.tap(
      find.byKey(const ValueKey('library-filter-disc:Streetlifting')).first,
    );
    await wait(tester, 800);
    await tester.tapAt(const Offset(5, 5));
    await wait(tester, 1000);
    releve['filtre_streetlifting'] = count();
    await shot('3_liste_filtree');
    ExerciseLibraryScreen.session = const FilterSelection();
    await back(tester);

    // Recherche.
    await tester.tap(find.byKey(const ValueKey('arsenal-exercises')));
    await wait(tester, 1500);
    await tester.enterText(find.byType(TextField).first, 'traction lestée');
    await wait(tester, 1200);
    releve['recherche'] = count();
    releve['recherche_premier'] = find
        .byKey(const ValueKey('library-ex-sl-traction-lestee'))
        .evaluate()
        .isNotEmpty;
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester, 800);
    await shot('4_recherche');
    await back(tester);

    // Une fiche de chaque discipline (haut de fiche).
    final fiches = <String, Object?>{};
    for (final e in _fiches.entries) {
      unawaited(openExerciseSheet(appNavigator.currentContext!, e.value));
      await wait(tester, 1500);
      fiches[e.key] = {
        'id': e.value,
        'titre': find
            .byKey(const ValueKey('fiche-titre'))
            .evaluate()
            .isNotEmpty,
        'points_cles': find
            .byKey(const ValueKey('fiche-points-cles'))
            .evaluate()
            .isNotEmpty,
      };
      await shot('5_fiche_${e.key}');
      if (e.key == 'street_workout') {
        await scrollTo(tester, find.byKey(const ValueKey('fiche-respiration')));
        await shot('6_fiche_erreurs_respiration');
        await scrollTo(
          tester,
          find.byKey(const ValueKey('fiche-muscle-map-sw-traction-pronation')),
        );
        await shot('7_fiche_carte_muscles');
        await scrollTo(tester, find.byKey(const ValueKey('fiche-variantes')));
        (fiches[e.key]! as Map)['variantes'] = find
            .byKey(const ValueKey('fiche-variantes'))
            .evaluate()
            .isNotEmpty;
        await shot('8_fiche_variantes');
      }
      await back(tester);
    }
    releve['fiches'] = fiches;

    // Session de test : même catalogue, sans toucher à la session
    // personnelle.
    await back(tester);
    await tab(tester, 2);
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    releve['logo_present'] = logo.evaluate().isNotEmpty;
    if (logo.evaluate().isNotEmpty) {
      for (var i = 0; i < 5; i++) {
        await tester.tap(logo.first);
        await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
      }
      await opened(tester);
    }
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_espace'] = SessionSpace.isDev;
    releve['dev_catalogue_exercices'] = store.content.entries.length;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ExerciseLibraryScreen()),
      ),
    );
    await wait(tester, 1500);
    releve['dev_bibliotheque'] = count();
    await shot('9_dev_bibliotheque');
    unawaited(
      openExerciseSheet(appNavigator.currentContext!, 'cs-planche-tuck'),
    );
    await wait(tester, 1500);
    await shot('10_dev_fiche');
    releve['dev_fiche'] = find
        .byKey(const ValueKey('fiche-titre'))
        .evaluate()
        .isNotEmpty;
    // Session personnelle : document d'état inchangé (journal identique).
    final stored = raw.getString('kalis_state_v3') ?? '';
    final doc =
        jsonDecode(
              stored.startsWith('gz:')
                  ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
                  : stored,
            )
            as Map<String, dynamic>;
    releve['perso_journal_intact'] = jsonEncode(doc['logs']) == persoLogs;
    record();

    expect(releve['catalogue_exercices'], 1039);
    expect(releve['journal_valide'], isTrue);
    expect(releve['bibliotheque'], 1039);
    expect(releve['filtre_streetlifting'], 61);
    expect(releve['recherche'], greaterThan(0));
    expect(releve['recherche_premier'], isTrue);
    for (final f in fiches.values) {
      final m = f! as Map;
      expect(m['titre'], isTrue, reason: '$m');
      expect(m['points_cles'], isTrue, reason: '$m');
    }
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_catalogue_exercices'], 1039);
    expect(releve['dev_bibliotheque'], 1039);
    expect(releve['dev_fiche'], isTrue);
    expect(releve['perso_journal_intact'], isTrue);
  }, timeout: _limit);
}
