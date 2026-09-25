// Diagnostic temporaire (non livré) : origine des débordements à 200 %.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..autoTimer = false
      ..wakelock = false;
  });
  for (final (w, j) in [(8, 3), (8, 1), (11, 3), (12, 3), (12, 1), (12, 4), (12, 5), (12, 6)]) {
    testWidgets('diag S$w J$j', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final errors = <String>[];
      final old = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString().split('\n').take(40).join('\n'));
      final week = store.program.week(w);
      final day = week.day(j)!;
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: SessionScreen(week: week, day: day),
      ));
      await tester.pumpAndSettle();
      for (var p = 0; p < day.exercises.length; p++) {
        if (errors.isNotEmpty) {
          // ignore: avoid_print
          print('DIAG S$w J$j page $p (${day.exercises[p].name}) :\n${errors.join('\n---\n')}');
          errors.clear();
        }
        await tester.tap(find.widgetWithIcon(FilledButton, Icons.chevron_right));
        await tester.pumpAndSettle();
      }
      FlutterError.onError = old;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
