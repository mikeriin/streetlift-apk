import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  testWidgets('diag', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() => store.init());
    store.settings..prefill = false..wakelock = false..vibration = false..sound = false;
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    late WeekPlan w; late DayPlan d;
    outer:
    for (final ww in store.program.weeks) {
      for (final dd in ww.days) {
        if (dd.exercises.isEmpty) continue;
        final s = store.logSpec(dd.exercises.first);
        if (s.kind == 'reps' && !s.myo && !s.cluster && s.rowPrefix.isEmpty) { w = ww; d = dd; break outer; }
      }
    }
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)), child: child!),
      home: SessionScreen(week: w, day: d),
    ));
    await tester.pumpAndSettle();
    final t = find.byTooltip('Valider la série 1').first;
    print('DIAG exercise ${d.exercises.first.name} group ${store.groups(d).first.length}');
    for (final s in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
      print('DIAG scrollable ${s.axisDirection}');
    }
    print('DIAG tooltip before ${tester.getRect(t)}');
    print('DIAG pageview ${tester.getRect(find.byType(PageView))}');
    await tester.ensureVisible(t);
    await tester.pumpAndSettle();
    print('DIAG tooltip after ${tester.getRect(t)}');
    print('DIAG listview ${tester.getRect(find.byType(ListView).first)}');
    print('DIAG exc ${tester.takeException()}');
  });
}
