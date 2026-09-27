// L12 — écrans de la motivation et de la progression : « MES PROGRÈS »
// d'un débutant (au plus 3 chiffres sur l'écran entier, défilement réel),
// « Afficher toutes les statistiques », poids masquable, célébration vue
// une fois (animations réduites ou non), chaînes mises en avant, ton de
// Koach, image de partage sans poids par défaut, STATS d'un débutant.
// Fenêtres 390 × 844 et 320 × 720, texte 130 et 200 %, thèmes clair et
// sombre.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/motivation.dart';
import 'package:streetlift_tracker/motivation_screens.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/store_widget.dart';

import 'phone_test_support.dart';

const _at = '2026-08-01T10:00:00';

UserProfile _beginner() {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.health
    ..consent = 'given'
    ..consentAt = _at
    ..answeredAt = _at;
  p.health.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  p.setField('birthYear', 1990, _at);
  p.setField('goalPrimary', 'health', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', {
    'park': ['pullup_bar', 'dip_bars'],
  }, _at);
  p.setField('benchmarks', {'pushups': 0, 'pullups': 0}, _at);
  p.setField('autonomy', 'assisted', _at);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 8, 24, 10);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ProgramAssets.load();
  });
  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.storeClock = () => now;
    await store.configureStart(
      DateTime(2026, 8, 10),
      references: const {
        'B4': 71.5,
        'B8': 60,
        'B9': 80,
        'B10': 20,
        'B11': 140,
        'B17': 20,
        'B18': 30,
        'B19': 50,
        'B20': 30,
      },
    );
  });
  tearDown(() {
    store.debugWriteHook = null;
    store.storeClock = DateTime.now;
  });

  void log(String key, DateTime at, String name, List<int> reps) {
    final iso = at.toIso8601String();
    store.logs[key] = SessionLog(
      done: true,
      finishedAt: iso,
      title: key,
      exerciseNames: {'x1': name},
      ex: {
        'x1': ExerciseLog(
          sets: [
            for (final r in reps)
              SetEntry(reps: '$r', done: true, completedAt: iso),
          ],
        ),
      },
    );
    store.saveLogs(immediate: true);
  }

  void beginnerHistory() {
    store.saveProfile(_beginner());
    log('S1-J1', DateTime(2026, 8, 10, 18), 'Pompes', [4, 3, 3]);
    log('S1-J3', DateTime(2026, 8, 12, 18), 'Pompes', [6, 5, 5]);
    log('S2-J1', DateTime(2026, 8, 17, 18), 'Pompes', [10, 8, 8]);
    log('S3-J1', DateTime(2026, 8, 24, 9), 'Traction pronation', [1]);
  }

  Widget page(
    Widget child, {
    double scale = 1,
    bool dark = true,
    bool reduce = false,
  }) => MaterialApp(
    theme: buildTheme(dark),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder:
        (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduce,
          ),
          child: child!,
        ),
    home: child,
  );

  Set<String> grab(WidgetTester tester, Set<String> into) {
    for (final t in tester.widgetList<Text>(find.byType(Text))) {
      into.add(t.data ?? t.textSpan?.toPlainText() ?? '');
    }
    return into;
  }

  for (final size in const [Size(390, 844), Size(320, 720)]) {
    for (final scale in const [1.3, 2.0]) {
      for (final dark in const [true, false]) {
        testWidgets('MES PROGRÈS d\'un débutant : au plus 3 chiffres, '
            '${size.width.toInt()} px, texte ${(scale * 100).round()} %, '
            '${dark ? 'sombre' : 'clair'}', (tester) async {
          phone(tester, size: size);
          beginnerHistory();
          expect(store.motivDetail, DetailLevel.victories);
          await tester.pumpWidget(
            page(const ProgressScreen(), scale: scale, dark: dark),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('motiv-progress')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('motiv-victory-first:traction-pronation')),
            findsOneWidget,
          );
          final texts = grab(tester, {});
          final target = find.byKey(const ValueKey('motiv-show-all'));
          final vertical = find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          );
          for (var i = 0; i < 30 && target.hitTestable().evaluate().isEmpty; i++) {
            await tester.drag(vertical.last, const Offset(0, -250));
            await tester.pumpAndSettle();
            grab(tester, texts);
          }
          expect(target.hitTestable(), findsOneWidget);
          final figures = texts.fold<int>(0, (n, t) => n + figureCount(t));
          expect(figures, lessThanOrEqualTo(3), reason: texts.join(' | '));
          expect(find.textContaining('RECORDS RÉCENTS'), findsNothing);
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(store.motiv.showAll, isTrue);
          expect(store.motivDetail, DetailLevel.full);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('poids facultatif : affiché puis masqué, sans jugement', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(page(const ProgressScreen(), scale: 2));
    await tester.pumpAndSettle();
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('motiv-body-toggle')),
    );
    expect(find.textContaining('71,5 kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('motiv-body-toggle')));
    await tester.pumpAndSettle();
    expect(store.motiv.hideBody, isTrue);
    expect(find.textContaining('71,5'), findsNothing);
    expect(find.text('Poids masqué.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reduce in const [false, true]) {
    testWidgets('célébration sobre vue une fois (animations '
        '${reduce ? 'réduites' : 'normales'})', (tester) async {
      phone(tester, size: const Size(320, 720));
      log('S2-J1', DateTime(2026, 8, 20, 18), 'Pompes', [5, 5, 5]);
      log('S3-J1', DateTime(2026, 8, 24, 9), 'Pompes', [12, 12, 12]);
      expect(store.motivPending, isNotEmpty);
      await tester.pumpWidget(
        page(
          Scaffold(
            body: StoreBuilder(
              builder:
                  (_) => ListView(
                    children: [
                      if (MotivHomeCard.visible) const MotivHomeCard(),
                      const Text('fin'),
                    ],
                  ),
            ),
          ),
          scale: 2,
          reduce: reduce,
        ),
      );
      if (reduce) {
        await tester.pump();
      } else {
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('motiv-celebration')), findsOneWidget);
      expect(find.textContaining('Étape franchie : Pompes'), findsOneWidget);
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('motiv-celebration-ok')),
      );
      await tester.tap(find.byKey(const ValueKey('motiv-celebration-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('motiv-celebration')), findsNothing);
      expect(store.motivPending, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('MES FIGURES : chaînes de l\'objectif mises en avant, étape '
      'en cours et critère de passage', (tester) async {
    phone(tester, size: const Size(320, 720));
    store.saveProfile(_beginner());
    await tester.pumpWidget(page(const ChainsScreen(), scale: 1.3));
    await tester.pumpAndSettle();
    expect(find.text('POUR TON OBJECTIF'), findsOneWidget);
    final tile = find.byKey(const ValueKey('motiv-chain-pompes'));
    await scrollToAction(tester, tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('motiv-chain-detail')), findsOneWidget);
    expect(find.textContaining('Pour passer : 3 × 15'), findsOneWidget);
    expect(find.text('Étape en cours'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ton de Koach réglable ; exemple affiché', (tester) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(page(const MotivSettingsScreen(), scale: 2));
    await tester.pumpAndSettle();
    final demanding = find.byKey(const ValueKey('motiv-tone-demanding'));
    await scrollToAction(tester, demanding);
    await tester.tap(demanding);
    await tester.pumpAndSettle();
    expect(store.koachTone, 'demanding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('partage : poids décoché par défaut, image sans poids', (
    tester,
  ) async {
    phone(tester, size: const Size(390, 844));
    log('S2-J1', DateTime(2026, 8, 20, 18), 'Pompes', [5, 5, 5]);
    log('S3-J1', DateTime(2026, 8, 24, 9), 'Pompes', [12, 12, 12]);
    await tester.pumpWidget(page(const ShareProgressScreen(), scale: 1.3));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('motiv-share-card'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.textContaining('Poids')),
      findsNothing,
    );
    final box = find.byKey(const ValueKey('motiv-share-bodyweight'));
    await scrollToAction(tester, box);
    expect(tester.widget<CheckboxListTile>(box).value, isFalse);
    await tester.tap(box);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.textContaining('Poids')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('STATS : victoires pour un débutant, onglets sinon', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(page(const StatsScreen(standalone: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stats-section-0')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    beginnerHistory();
    await tester.pumpWidget(page(const StatsScreen(standalone: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('motiv-progress')), findsOneWidget);
    expect(find.byKey(const ValueKey('stats-section-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
