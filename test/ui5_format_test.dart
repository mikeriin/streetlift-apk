// UI5 (refonte UI, cahier C9 ; décisions U0.19, U0.23) : formateurs de
// présentation français (`lib/kit/format.dart`) et leur usage à l'écran :
// virgule décimale, espace fine insécable (U+202F) avant l'unité, secondes
// au-delà de 90 s en minutes, « au moins » plutôt que « ≥ », saisie de la
// charge à la virgule comme au point (le journal garde le point).
// Tests purs, puis deux tests de widgets (estimation, champ de charge).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/adapt/flame_track.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart' show durationText;
import 'package:streetlift_tracker/estimate_view.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/kit/format.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/set_validation.dart' show parseLoadKg;
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/training_estimate.dart';

/// Espace fine insécable (C9).
const _t = '\u202F';

Widget _page(Widget child) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void main() {
  group('nombres', () {
    test('virgule décimale, entier sans décimale', () {
      expect(kUnitSpace, _t);
      expect(formatDecimal(62.5), '62,5');
      expect(formatDecimal(60), '60');
      expect(formatDecimal(60.0), '60');
      expect(formatDecimal(7.25), '7,25');
      expect(formatDecimal(59.999), '60');
      expect(formatDecimal(-2.5), '-2,5');
      expect(formatDecimal(-0.001), '0');
      expect(formatDecimal(117.46, maxDecimals: 1), '117,5');
    });

    test('nombre et unité : espace fine insécable', () {
      expect(formatUnit(75, 'kg'), '75${_t}kg');
      expect(formatUnit(62.5, 'kg'), '62,5${_t}kg');
      expect(formatUnit(180, 'cm'), '180${_t}cm');
      expect(unitText('3–4', 'min'), '3–4${_t}min');
      expect(formatUnit(75, 'kg'), isNot(contains(' ')));
    });

    test('charge arrondie au pas d’affichage', () {
      expect(formatKg(62.5), '62,5${_t}kg');
      expect(formatKg(87.34, step: 0.5), '87,5${_t}kg');
      expect(formatKg(36.25, step: 0.25), '36,25${_t}kg');
      // Charges proposées par le moteur : la grille (lest 1,25 kg) reste
      // exacte ; une charge hors grille (poulie en livres) s'arrondit.
      expect(kAdaptKgDisplayStep, 0.25);
      expect(adaptKgLabel(36.25), '36,25${_t}kg');
      expect(adaptKgLabel(60), '60${_t}kg');
      expect(adaptKgLabel(4.5359237), '4,5${_t}kg');
      // Le texte enregistré au journal (« Prescrit ce jour-là ») ne change
      // pas.
      expect(adaptKg(62.5), '62,5\u00A0kg');
    });
  });

  group('durées', () {
    test('secondes jusqu’à 90 s, minutes au-delà', () {
      expect(formatSeconds(45), '45${_t}s');
      expect(formatSeconds(90), '90${_t}s');
      expect(formatSeconds(59.6), '60${_t}s');
      expect(formatSeconds(91), '1${_t}min 31${_t}s');
      expect(formatSeconds(120), '2${_t}min');
      expect(formatSeconds(150), '2${_t}min 30${_t}s');
      expect(formatSeconds(600), '10${_t}min');
    });

    test('plages', () {
      expect(formatSecondsRange(30, 45), '30–45${_t}s');
      expect(formatSecondsRange(45, 30), '30–45${_t}s');
      expect(formatSecondsRange(540, 660), '9–11${_t}min');
      expect(formatSecondsRange(600, 600), '10${_t}min');
      expect(adaptAmount(30, 45, seconds: true), '30–45${_t}s');
      expect(adaptAmount(120, 120, seconds: true), '2${_t}min');
      expect(adaptAmount(6, 8, seconds: false), '6-8${_t}reps');
    });

    test('« ≥ n min » devient « au moins n min »', () {
      expect(atLeastText('≥ 38 min'), 'au moins 38 min');
      expect(atLeastText('34–49 min'), '34–49 min');
    });

    test('libellés de l’estimation au format C9', () {
      expect(estimateLabelText('≥ 38 min'), 'au moins 38${_t}min');
      expect(estimateLabelText('≥ 45 s'), 'au moins 45${_t}s');
      expect(estimateLabelText('34–49 min'), '34–49${_t}min');
      expect(estimateLabelText('≈ 15 s'), '≈ 15${_t}s');
      expect(estimateLabelText('1 min 15 s'), '1${_t}min 15${_t}s');
      expect(
        estimateLabelText('≈ 162 rép. · 600 s d’effort + non chiffré'),
        '≈ 162${_t}rép. · 10${_t}min d’effort + non chiffré',
      );
      expect(estimateLabelText('540–660 s d’effort'), '9–11${_t}min d’effort');
      // « 3 séries » n'est pas « 3 s ».
      expect(estimateLabelText('19 séries'), '19 séries');
      expect(estimateLabelText('À préciser'), 'À préciser');
      expect(estimateLabelText('—'), '—');
    });

    test('durée lisible du profil', () {
      expect(durationText(45), '45${_t}s');
      expect(durationText(1530), '25${_t}min 30${_t}s');
      expect(durationText(3900), '1${_t}h 05');
    });
  });

  group('textes', () {
    test('virgule et espace fine dans un texte du journal', () {
      expect(
        frenchNumbersText('S8 : 12.5 kg × 3 · 3'),
        'S8 : 12,5${_t}kg × 3 · 3',
      );
      expect(frenchNumbersText('62,5\u00A0kg'), '62,5${_t}kg');
      expect(unitSpacesText('40 à 60 kg'), '40 à 60${_t}kg');
      expect(unitSpacesText('30 s à 1 min'), '30${_t}s à 1${_t}min');
      expect(unitSpacesText('Plus de 1 min 30'), 'Plus de 1${_t}min 30');
      expect(unitSpacesText('3 séries'), '3 séries');
    });

    test('série résumée : unités, tenue longue en minutes', () {
      SetEntry e(String kg, String reps) => SetEntry()
        ..kg = kg
        ..reps = reps
        ..done = true;
      expect(
        setDoneText(e('16.25', '8'), const LogSpec('reps')),
        '16,25${_t}kg × 8${_t}reps',
      );
      expect(
        setDoneText(e('', '150'), const LogSpec('hold')),
        '2${_t}min 30${_t}s',
      );
      expect(setDoneText(e('', '45'), const LogSpec('hold')), '45${_t}s');
    });
  });

  group('saisie de la charge (U0.19)', () {
    test('virgule ou point, vide ou illisible : null', () {
      expect(parseDecimalInput('62,5'), 62.5);
      expect(parseDecimalInput('62.5'), 62.5);
      expect(parseDecimalInput(' 62,5 '), 62.5);
      expect(parseDecimalInput('−7,5'), -7.5);
      expect(parseDecimalInput('-10'), -10);
      expect(parseDecimalInput('60'), 60);
      for (final bad in [null, '', '  ', '62,', ',5', 'abc', '1e3', '72 5']) {
        expect(parseDecimalInput(bad), isNull, reason: '$bad');
      }
    });

    test('champ : virgule montrée, point enregistré, même valeur', () {
      expect(decimalFieldText('62.5'), '62,5');
      expect(decimalFieldText('60'), '60');
      expect(decimalFieldText(''), '');
      expect(decimalStoredText('62,5'), '62.5');
      expect(decimalStoredText('62.5'), '62.5');
      for (final typed in ['62,5', '62.5', '-10', '7,25', '100']) {
        final stored = decimalStoredText(typed);
        expect(parseLoadKg(stored), parseDecimalInput(typed), reason: typed);
        expect(parseLoadKg(stored), parseLoadKg(typed), reason: typed);
        expect(decimalStoredText(decimalFieldText(stored)), stored);
      }
    });
  });

  group('écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false;
    });

    testWidgets('estimation : « au moins », minutes, espace fine', (
      tester,
    ) async {
      final e = TrainingEstimate()
        ..work = const Span.exact(600)
        ..partial = true;
      e.movements.add(const MovementVolume('Planche', 's', Span.exact(600)));
      expect(e.durationLabel, '≥ 10 min');
      await tester.pumpWidget(
        _page(
          Scaffold(
            body: SingleChildScrollView(child: EstimateView(estimate: e)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('au moins 10${_t}min'), findsOneWidget);
      expect(find.text('10${_t}min d’effort + non chiffré'), findsOneWidget);
      // Ligne « Effort » : 600 s écrites en minutes.
      expect(find.text('10${_t}min'), findsOneWidget);
      expect(find.textContaining('≥'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('champ de charge : « 62,5 » à l’écran, « 62.5 » au journal', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Jour du programme par défaut ouvert sur un exercice en répétitions
      // (colonne de charge possible : ni tenue, ni durée…), hors moteur
      // (pas de page « Bilan du jour » avant l'exercice).
      late WeekPlan week;
      late DayPlan day;
      late Exercise exercise;
      var found = false;
      for (final w in store.program.weeks) {
        for (final d in w.days) {
          if (found || d.exercises.isEmpty) continue;
          if (d.exercises.any((e) => e.engine)) continue;
          final first = store.groups(d, week: w.n).first.first;
          if (store.logSpec(first).kind != 'reps') continue;
          week = w;
          day = d;
          exercise = first;
          found = true;
        }
      }
      expect(found, isTrue);
      store.clearSession(week.n, day.j);
      final log = store.exLog(week.n, day.j, exercise)..showKg = true;
      // Saisie de l'utilisateur (gardée à l'ouverture : les séries
      // pré-remplies d'une séance pas commencée sont refaites).
      log.sets.first
        ..kg = '62.5'
        ..edited = true;
      await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('${exercise.id}-0-0'));
      expect(row, findsOneWidget);
      // Le champ de charge est le seul de la ligne à convertir la saisie
      // (point tapé → virgule).
      final load = find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) => w is TextField && (w.inputFormatters?.isNotEmpty ?? false),
        ),
      );
      expect(load, findsOneWidget);
      String shown() => tester.widget<TextField>(load).controller!.text;
      // Texte enregistré avec le point, montré avec la virgule.
      expect(shown(), '62,5');
      expect(log.sets.first.kg, '62.5');
      // Saisie au point : montrée en virgule ; enregistrée au point.
      await tester.enterText(load, '70.5');
      await tester.pump();
      expect(shown(), '70,5');
      expect(log.sets.first.kg, '70.5');
      // Saisie à la virgule : même valeur au journal qu'au point.
      await tester.enterText(load, '72,5');
      await tester.pump();
      expect(shown(), '72,5');
      expect(log.sets.first.kg, '72.5');
      expect(parseLoadKg(log.sets.first.kg), 72.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.clearSession(week.n, day.j);
      await tester.runAsync(() => store.flush());
    });
  });
}
