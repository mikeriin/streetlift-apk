// KB2 correction 1 (dev7.2.2, DECISIONS_CP.md C17.36) — popup du
// questionnaire hors modèle à l'écran : message d'entrée sans redite,
// chaque choix sous son texte (jamais « Autre chose »), réponses rendues
// par leur code, « Plus tard » et feuille fermée = « Plus tard » ; puis la
// séance S1·J1 du programme PR2 synthétique, passée par « Plus tard » :
// servie par Koach avec les mêmes exercices, dans le même ordre, que
// l'écrit (muscle-up lesté en tête).
// Données synthétiques ; horloge injectée ; calculs du moteur sur place.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/koach_textes.dart' show texteHorsModeleKoach;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = DateTime(2026, 10, 19, 7); // lundi, S15 = S1 affichée

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    store.storeClock = () => clock;
    await store.init();
    await importPr2Nouveau(store);
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });
  tearDownAll(() {
    debugKoachBasculeAutorisee = false;
  });

  group('textes (purs)', () {
    test('message d’entrée : une phrase par cause, « sort de mon modèle » '
        'une seule fois', () {
      const causes = ['rupture', 'residu', 'assiduite', 'douleur'];
      final combos = [
        for (final c in causes) [c],
        ['rupture', 'residu'],
        causes,
      ];
      for (final cs in combos) {
        final t = koachDiagnosticIntro(cs);
        expect(
          'sort de mon modèle'.allMatches(t).length,
          1,
          reason: '$cs : $t',
        );
        expect(t, endsWith(texteHorsModeleKoach));
        expect(t, isNot(contains('..')));
      }
      expect(
        koachDiagnosticIntro(['rupture']),
        'Tes dernières séances ne ressemblent pas à ce que j’attendais. '
        '$texteHorsModeleKoach',
      );
      expect(koachDiagnosticIntro(const []), texteHorsModeleKoach);
    });

    test('libellés et codes des choix', () {
      const cause = {
        'douleur': 'Une douleur',
        'moins_de_temps': 'Moins de temps',
        'fatigue': 'Fatigue ou vie chargée',
        'rien': 'Rien de spécial',
      };
      for (final e in cause.entries) {
        final c = {'code': e.key, 'texte': 'x'};
        expect(koachChoiceLabel('cause', c), e.value);
        expect(koachChoiceCode(c), e.key);
      }
      expect(
        koachChoiceLabel('intensite', {'code': 0, 'texte': '0'}),
        '0/10 (aucune gêne)',
      );
      expect(koachChoiceLabel('intensite', {'code': 4, 'texte': '4'}), '4/10');
      expect(koachChoiceCode({'code': 4, 'texte': '4'}), 4);
      expect(koachChoiceCode({'code': 4.0}), 4);
      expect(
        koachChoiceLabel('seances_par_semaine', {'code': 3, 'texte': '3'}),
        '3 séances',
      );
      expect(
        koachChoiceLabel('duree_max_min', {'code': 45, 'texte': '45 min'}),
        '45 min',
      );
      // Code inconnu de l'application : le texte du moteur.
      expect(
        koachChoiceLabel('cause', {'code': 'neuf', 'texte': 'Autre motif'}),
        'Autre motif',
      );
      expect(koachChoiceCode({'texte': 'sans code'}), isNull);
    });
  });

  group('popup à l’écran', () {
    Map<String, Object?>? result;
    var closed = false;

    Future<void> show(WidgetTester tester) async {
      result = null;
      closed = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showKoachDiagnostic(context);
                    closed = true;
                  },
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    Future<void> ready(WidgetTester tester) async {
      await tester.runAsync(() async {
        if (store.koachLive == null) await store.koachRefresh();
      });
      expect(store.koachLive, isNotNull);
      store.koachLive!.surveillance!.alertes = [true, false, false, false];
      expect(store.koachNeedsDiagnostic, isTrue);
    }

    testWidgets('message d’entrée et « Plus tard »', (tester) async {
      await ready(tester);
      await show(tester);
      expect(find.textContaining('sort de mon modèle'), findsOneWidget);
      expect(
        find.text(koachDiagnosticIntro(store.koachAlertCauses)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('koach-diag-later')));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, isNull);
    });

    testWidgets('les quatre choix sous leur texte ; « Rien de spécial » '
        'rend son code', (tester) async {
      await ready(tester);
      await show(tester);
      await tester.tap(find.byKey(const ValueKey('koach-diag-start')));
      await tester.pumpAndSettle();
      for (final t in const [
        'Une douleur',
        'Moins de temps',
        'Fatigue ou vie chargée',
        'Rien de spécial',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Autre chose'), findsNothing);
      await tester.tap(find.text('Rien de spécial'));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, {'cause': 'rien'});
    });

    testWidgets('« Une douleur » : zone puis intensité, codes rendus', (
      tester,
    ) async {
      await ready(tester);
      await show(tester);
      await tester.tap(find.byKey(const ValueKey('koach-diag-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une douleur'));
      await tester.pumpAndSettle();
      expect(find.text('Où as-tu mal ?'), findsOneWidget);
      expect(find.text('Autre endroit'), findsNothing);
      final zones =
          store.koachQuestions(const {'cause': 'douleur'})[1]['choix'] as List;
      final first = zones.first as Map;
      await tester.tap(find.text(koachChoiceLabel('zone', first)).first);
      await tester.pumpAndSettle();
      expect(find.text('Quelle intensité, de 0 à 10 ?'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('4/10'),
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('4/10'));
      await tester.pumpAndSettle();
      expect(result, {
        'cause': 'douleur',
        'zone': first['code'],
        'intensite': 4,
      });
      expect(store.koachDiagnosticValid(result!), isTrue);
    });

    testWidgets('« Moins de temps » : séances puis durée', (tester) async {
      await ready(tester);
      await show(tester);
      await tester.tap(find.byKey(const ValueKey('koach-diag-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moins de temps'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 séances'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
      expect(result, {
        'cause': 'moins_de_temps',
        'seances_par_semaine': 3,
        'duree_max_min': 45,
      });
      expect(store.koachDiagnosticValid(result!), isTrue);
    });

    testWidgets('feuille d’une question fermée (glisser, retour) = « Plus '
        'tard »', (tester) async {
      await ready(tester);
      await show(tester);
      await tester.tap(find.byKey(const ValueKey('koach-diag-start')));
      await tester.pumpAndSettle();
      expect(find.text('Une douleur'), findsOneWidget);
      // Retour (Android) : la feuille se ferme sans choix.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });

  testWidgets('S1·J1 par « Plus tard » : séance de Koach identique à '
      'l’écrit (muscle-up lesté en tête)', (tester) async {
    await tester.runAsync(() async {
      if (store.koachLive == null) await store.koachRefresh();
    });
    expect(store.koachEngine.fromWeek, 15);
    final week = store.program.week(15);
    final day = week.day(1)!;
    final ecrit = structureSeance(store, 15, 1);
    expect(ecrit.first, startsWith('MUSCLE-UP LESTÉ'));
    store.koachLive!.surveillance!.alertes = [true, false, false, false];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionScreen(week: week, day: day),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.koachPending(15, 1), isTrue, reason: 'aperçu');
    await tester.tap(find.byKey(const ValueKey('feel-4')));
    final appuis = <String>[];
    for (var i = 0; i < 40 && !store.koachOpen(15, 1); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (final k in const ['koach-diag-later', 'adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k));
        if (f.evaluate().isNotEmpty) {
          appuis.add(k);
          await tester.tap(f.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }
    expect(appuis, contains('koach-diag-later'));
    expect(store.koachOpen(15, 1), isTrue);
    // KB3 (Koach 1.0.6) : l'écrit, dans l'ordre, sans les accessoires que
    // Koach retire en le disant ; muscle-up lesté en tête.
    final servie = structureSeance(store, 15, 1);
    expect(servie.first, ecrit.first);
    expect(servie, orderedEquals(ecrit.where(servie.contains)));
    // Question reposée à la séance suivante.
    expect(store.koachNeedsDiagnostic, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
