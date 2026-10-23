// CIF (dev6.18.0, pipeline CP, lot CI final) — écrans de la séance : carte
// « Pas encore » sans consigne répétée (point 8) ; bandeau des mini-séries
// à hauteur stable quand le dernier bloc est noté (point 12). Thèmes
// sombre et clair. Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/clearance.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

Map<String, Object?> _streetJson() {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return [
    for (final p in raw['profiles']! as List)
      ((p as Map)['profile'] as Map).cast<String, Object?>(),
  ].firstWhere((p) {
    final primary = kc.AthleteProfile.fromJson(p).disciplines.primary.code;
    return const {
      'street_workout',
      'streetlifting',
      'calisthenics',
    }.contains(primary);
  });
}

Widget _app(Widget home, bool dark) => MaterialApp(
  theme: buildTheme(dark),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

Finder _keyStarts(String prefix) => find.byWidgetPredicate((w) {
  final k = w.key;
  return k is ValueKey<String> && k.value.startsWith(prefix);
});

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('8 : carte « Pas encore »', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9);
      await store.init();
      final json = Map<String, Object?>.of(_streetJson());
      json['limitations'] = [
        {
          'zone': 'shoulder',
          'side': 'right',
          'joint': 'epaule',
          'discomfort': 6,
          'since': 'months_3_to_12',
        },
      ];
      store.saveAthleteProfile(
        ProfileDraft.of(kc.AthleteProfile.fromJson(json))..consent = 'given',
      );
      final c = PlanStore(store).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    });

    for (final dark in [true, false]) {
      testWidgets('gêne à 6/10 : « En attendant » dit une fois '
          '(${dark ? 'sombre' : 'clair'})', (tester) async {
        await _phone(tester);
        final plan = store.planProgram!;
        int? w0, j0;
        for (var w = plan.firstWeek; w0 == null && w <= 4; w++) {
          for (var j = 1; j0 == null && j <= 7; j++) {
            final d = store.program.week(w).day(j);
            if (d != null &&
                d.exercises.isNotEmpty &&
                store.adaptPlaceOf(w, j) != null) {
              w0 = w;
              j0 = j;
            }
          }
        }
        final w = w0!, j = j0!;
        expect(store.clearancePending(w, j), isNotNull);
        clearanceDeferred.clear();
        await tester.pumpWidget(
          _app(
            SessionScreen(
              week: store.program.week(w),
              day: store.program.week(w).day(j)!,
            ),
            dark,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('clearance-not-yet')));
        await tester.pumpAndSettle();
        final card = find.byKey(const ValueKey('clearance-card'));
        expect(card, findsOneWidget);
        final texts = [
          for (final t
              in find
                  .descendant(of: card, matching: find.byType(Text))
                  .evaluate())
            (t.widget as Text).data ?? '',
        ];
        // ignore: avoid_print
        print('CIF8|${texts.join(' / ')}');
        final waiting = texts.where((t) => t.contains('En attendant')).length;
        expect(waiting, 1);
        expect(
          find.descendant(
            of: card,
            matching: find.byKey(const ValueKey('clearance-card-waiting')),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await _close(tester);
      });
    }
  });

  group('12 : bandeau des mini-séries à hauteur stable', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9); // S13
      await store.init();
      final filled = filledBackup(store);
      final logs = (filled['logs'] as Map).cast<String, dynamic>();
      logs.removeWhere((k, _) {
        final w = int.parse(k.substring(1, k.indexOf('-')));
        final j = int.parse(k.substring(k.indexOf('J') + 1));
        return w > 13 || (w == 13 && j > 4);
      });
      filled['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      expect(await store.importAll(jsonEncode(filled)), isTrue);
      store.saveAthleteProfile(
        ProfileDraft.of(
          sampleAthleteProfile(
            on: civilOf(store.storeClock()),
            guidance: kc.GuidanceMode.assisted,
          ).copyWith(experience: kc.ExperienceLevel.advanced),
        )..consent = 'refused',
      );
    });

    for (final dark in [true, false]) {
      testWidgets('dernier bloc noté : même hauteur '
          '(${dark ? 'sombre' : 'clair'})', (tester) async {
        await _phone(tester);
        store.clearSession(13, 5);
        await tester.pumpWidget(
          _app(
            SessionScreen(
              week: store.program.week(13),
              day: store.program.week(13).day(5)!,
            ),
            dark,
          ),
        );
        await tester.pumpAndSettle();
        final skip = find.byKey(const ValueKey('feel-skip'));
        if (skip.evaluate().isNotEmpty) {
          await tester.ensureVisible(skip);
          await tester.tap(skip);
          await tester.pumpAndSettle();
        }
        final start = find.byKey(const ValueKey('bilan-start'));
        if (start.evaluate().isNotEmpty) {
          await tester.ensureVisible(start);
          await tester.tap(start);
          await tester.pumpAndSettle();
        }
        final add = _keyStarts('miniset-add-');
        for (var page = 1; page < 16 && add.evaluate().isEmpty; page++) {
          final pages = find.byType(PageView);
          if (pages.evaluate().isEmpty) break;
          final ctl = tester.widget<PageView>(pages.first).controller;
          if (ctl == null || !ctl.hasClients) break;
          ctl.jumpToPage(page);
          await tester.pumpAndSettle();
          for (var k = 0; k < 8 && add.evaluate().isEmpty; k++) {
            final lists = find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            );
            if (lists.evaluate().isEmpty) break;
            await tester.drag(
              lists.last,
              const Offset(0, -400),
              warnIfMissed: false,
            );
            await tester.pumpAndSettle();
          }
        }
        expect(add, findsWidgets, reason: 'bandeau des mini-séries trouvé');
        await tester.ensureVisible(add.first);
        await tester.pumpAndSettle();
        final slot = _keyStarts('miniset-note-slot-').first;
        final strip = find
            .ancestor(of: slot, matching: find.byType(Material))
            .first;
        final h0 = tester.getSize(strip).height;
        final s0 = tester.getSize(slot).height;
        final heights = <double>[h0];
        for (var b = 0; b < 8 && add.evaluate().isNotEmpty; b++) {
          await tester.ensureVisible(add.first);
          await tester.tap(add.first);
          await tester.pumpAndSettle();
          heights.add(tester.getSize(strip).height);
        }
        // ignore: avoid_print
        print(
          'CIF12|${dark ? 'sombre' : 'clair'}|bandeau $heights|'
          'ligne $s0 → ${tester.getSize(slot).height}',
        );
        expect(add, findsNothing, reason: 'tous les blocs notés');
        expect(_keyStarts('miniset-advice-'), findsOneWidget);
        expect(heights.toSet(), hasLength(1));
        expect(tester.getSize(slot).height, s0);
        expect(tester.takeException(), isNull);
        await _close(tester);
      });
    }
  });
}
