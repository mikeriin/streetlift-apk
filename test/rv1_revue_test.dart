// RV1 (dev7.5.0, pipeline CP, DECISIONS_CP.md C17.41, C17.43.3) — revue
// complète du code : tests de non-régression des bugs corrigés.
//
// - charges : poulie au pas de 2,5 kg (avant : 20,41 kg, grille en livres
//   du moteur), charge « 22, » refusée, livres à la virgule, cible de Koach
//   en livres ;
// - intervalles « 8× (30 s effort / 30 s repos) » : une ligne par tour,
//   Koach actif comme arrêté (ligne importée servie telle qu'écrite) ;
// - départ chronométré raté : indication sous l'en-tête ;
// - journal : résultat d'un groupe jamais pris pour une consultation ;
// - profil : enregistrer une rubrique ne remet pas l'ancien poids ;
// - Koach : arrêt d'urgence, séance commencée jamais déclarée manquée,
//   charge fixe sans suggestion.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_journal.dart' show koachJour;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'l2_fixtures.dart';

/// Ligne de programme au format de la sauvegarde.
Exercise _ligne(String sets, {String name = 'HIIT court'}) =>
    Exercise.fromJson({
      'id': 'x',
      'name': name,
      'sets': {'type': 'text', 'value': sets},
      'load': {'type': 'fixed', 'kg': 0.0},
      'rest': '—',
      'restSec': null,
    });

/// Sonde imprimée (relevé de la livraison).
void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('RV1|$nom|${jsonEncode(v)}');
}

bool _surGrille(double kg, double pas) =>
    ((kg / pas) - (kg / pas).roundToDouble()).abs() < 1e-6;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('charges', () {
    test('charge calculée à 22,000000000000004 : « 22 », jamais « 22, »', () {
      const bruit = 22.000000000000004;
      expect(adaptKgField(bruit), '22');
      expect(koachKg(bruit), '22');
      expect(adaptKg(bruit), '22 kg');
      expect(adaptKgField(36.25), '36.25');
      expect(koachKg(36.25), '36,25');
      expect(adaptKgField(62.5), '62.5');
      expect(koachKg(62.5), '62,5');
      expect(adaptKgField(60), '60');
      expect(adaptKgField(19.999999999), '20');
    });

    test('poulie : pas de 2,5 kg donné aux moteurs quand le profil n’en '
        'dit rien ; un pas du profil est gardé', () {
      final def = withCableIncrement(const []);
      expect(def.single.loadType, kc.LoadType.cable);
      expect(def.single.stepKg, 2.5);
      expect(def.single.minKg, 2.5);
      const own = [
        kc.LoadIncrement(loadType: kc.LoadType.cable, stepKg: 5, minKg: 5),
      ];
      expect(withCableIncrement(own), same(own));
      // Grille du moteur : 2,5 kg (avant : 2,5 lb = 1,134 kg).
      final g = ka.LoadGrid.of(
        kc.LoadType.cable,
        sampleAthleteProfile(
          on: kc.CivilDate(2026, 10, 21),
        ).copyWith(loadIncrements: def),
      );
      expect(g.step, 2.5);
      expect(g.minimum, 2.5);
    });

    group('livres', () {
      late AppStore app;
      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        app = AppStore();
        await app.init();
      });
      tearDown(() async {
        await app.flush();
        app.dispose();
      });

      test('en livres : virgule décimale ; la cible passe par le même '
          'libellé', () {
        app.settings.lb = true;
        expect(app.massLabel(62.5, engine: true), '137,8 lb');
        expect(app.massLabel(100), '220,5 lb');
        app.settings.lb = false;
        expect(app.massLabel(62.5, engine: true), '62,5 kg');
        expect(app.massLabel(20.41, engine: true), '20,41 kg');
        expect(app.massLabel(62.5), '62,5 kg');
      });
    });
  });

  group('intervalles : une ligne par tour', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('« 8× (30 s effort / 30 s repos) » et « 6× (30 s / 30 s) » : une '
        'ligne de 30 s par tour, ni repos ni chrono de tenue par ligne', () {
      for (final (txt, tours) in [
        ('8× (30 s effort / 30 s repos)', 8),
        ('6× (30 s / 30 s)', 6),
      ]) {
        final e = _ligne(txt);
        final sp = app.logSpec(e);
        expect(app.setCount(e), tours, reason: txt);
        expect(sp.kind, 'hold', reason: txt);
        expect(sp.seconds, 30, reason: txt);
        expect(sp.rowPrefix, 'I', reason: txt);
        expect(sp.every, isNull);
        for (var i = 0; i < tours; i++) {
          expect(app.restAfterSet(e, sp, i, tours), isNull);
        }
      }
    });

    test('séance d’intervalles ouverte avant dev7.5.0 (une ligne, rien '
        'noté) : une ligne par tour ; une ligne notée jamais retirée', () {
      final e = Exercise.manual(
        id: 'IV-1',
        name: 'HIIT court',
        setsText: '8× (30 s effort / 30 s repos)',
      );
      final s = app.sessionLog(0, 9811);
      s.ex[e.id] = ExerciseLog(sets: [SetEntry()]);
      expect(app.exLog(0, 9811, e).sets.length, 8);
      final f = Exercise.manual(
        id: 'IV-2',
        name: 'HIIT court',
        setsText: '6× (30 s / 30 s)',
      );
      s.ex[f.id] = ExerciseLog(sets: [SetEntry(reps: '6', done: true)]);
      expect(app.exLog(0, 9811, f).sets.length, 1);
      expect(app.exLog(0, 9811, f).sets.single.reps, '6');
    });

    test('programme de 40 semaines : la ligne HIIT importée est servie '
        'telle qu’écrite ; tours du groupe = lignes de la carte', () async {
      final filled = filledBackup(app);
      filled['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      app.saveAthleteProfile(
        ProfileDraft.of(
          sampleAthleteProfile(
            on: civilOf(app.storeClock()),
            guidance: kc.GuidanceMode.assisted,
          ).copyWith(experience: kc.ExperienceLevel.advanced),
        )..consent = 'refused',
      );
      final day = app.program.week(3).day(6)!;
      final e = day.exercises.firstWhere((x) => x.interval != null);
      final slot = app.adaptSlotOf(3, 6, e.id);
      expect(slot, isNotNull);
      expect(app.adaptAsWritten(3, slot), isTrue);
      final g = app.exerciseGroupOf(3, 6, e);
      expect(g?.format, kc.GroupFormat.intervals);
      expect(g!.rounds, app.setCount(e));
      expect(app.setCount(e), e.interval!.rounds);
      _sonde('hiit', {
        'ligne': app.setsLabel(e),
        'lignes': app.setCount(e),
        'groupe': g.rounds,
      });
    });
  });

  group('écran de séance', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false
        ..prefill = true;
    });

    Future<void> ouvrir(WidgetTester tester, DayPlan day, WeekPlan week) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SessionScreen(week: week, day: day),
        ),
      );
      await tester.pumpAndSettle();
    }

    (WeekPlan, DayPlan) semaine(int j, List<Exercise> exs) {
      final week = WeekPlan.manual(
        n: 0,
        block: 'RV1',
        color: const Color(0xFF4FA3C7),
        days: [DayPlan.manual(j: j, title: 'RV1', exercises: exs)],
      );
      return (week, week.days.single);
    }

    testWidgets('EMOM minute par minute : « Minute ratée : laisse sa ligne '
        'non validée. » sous l’en-tête', (tester) async {
      final (week, day) = semaine(9812, [
        Exercise.manual(
          id: 'RV-EM',
          name: 'Muscle-ups PdC — EMOM technique',
          setsText: 'EMOM 8 min × 3 reps par minute',
        ),
      ]);
      await ouvrir(tester, day, week);
      final hint = find.byKey(const ValueKey('timing-missed-hint'));
      expect(hint, findsOneWidget);
      expect(
        find.text('Minute ratée : laisse sa ligne non validée.'),
        findsOneWidget,
      );
      expect(find.textContaining('EMOM · 8 tours'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('E2MOM : « Départ raté » ; un seul tour : « 1 tour »', (
      tester,
    ) async {
      final (week, day) = semaine(9813, [
        Exercise.manual(
          id: 'RV-E2',
          name: 'Traction lestée',
          setsText: '8×3 · E2MOM',
        ),
      ]);
      await ouvrir(tester, day, week);
      expect(
        find.text('Départ raté : laisse sa ligne non validée.'),
        findsOneWidget,
      );
      expect(emomMissedHint(60), startsWith('Minute ratée'));
      expect(emomMissedHint(120), startsWith('Départ raté'));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('intervalles écrits : 8 lignes de 30 s, un seul chrono des '
        'tours, aucun chrono de tenue par ligne', (tester) async {
      final e = Exercise.manual(
        id: 'RV-IV',
        name: 'HIIT court',
        setsText: '8× (30 s effort / 30 s repos)',
      );
      final (week, day) = semaine(9814, [e]);
      await ouvrir(tester, day, week);
      final log = store.exLog(week.n, day.j, e);
      expect(log.sets.length, 8);
      expect([for (final s in log.sets) s.reps], List.filled(8, '30'));
      expect(find.textContaining('Lancer 8 × 30'), findsOneWidget);
      expect(find.byTooltip('Valider la série 8'), findsWidgets);
      await tester.tap(find.byTooltip('Valider la série 1').first);
      await tester.pumpAndSettle();
      expect(log.sets[0].done, isTrue);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  group('journal et profil', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => DateTime(2026, 10, 21, 9);
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('résultat d’un AMRAP saisi, sans série validée : jamais retiré '
        'comme une simple consultation ; séance à reprendre', () {
      final key = app.sessionKey(3, 2);
      app.sessionLog(3, 2).groups['g1'] = {'rounds': 4, 'extra': 7};
      expect(app.isConsultation(key), isFalse);
      expect(app.inProgress(key), isTrue);
      app.forgetConsultation(3, 2);
      expect(app.logs.containsKey(key), isTrue);
    });

    test('enregistrer une autre rubrique du profil ne remet pas l’ancien '
        'poids (pesée de « Mes références » gardée)', () {
      app.saveAthleteProfile(
        ProfileDraft.of(sampleAthleteProfile(on: civilOf(app.storeClock())))
          ..consent = 'refused',
      );
      expect(app.currentBodyweight, 75);
      app.setValue('B4', 78);
      expect(app.currentBodyweight, 78);
      final d = app.athleteEditDraft();
      app.saveAthleteProfile(d);
      expect(app.currentBodyweight, 78);
      expect(app.values['B4'], 78);
      // Un poids saisi dans le parcours est bien enregistré.
      final d2 = app.athleteEditDraft()..weight = '77';
      app.saveAthleteProfile(d2);
      expect(app.currentBodyweight, 77);
    });
  });

  group('Koach (programme PR2 synthétique)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7);
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
      await importPr2Nouveau(app, firstWeek: 12);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15);
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    test(
      'extension triceps poulie servie au pas de 2,5 kg (avant : '
      '20,41 kg) ; toute charge servie sur la grille de son matériel',
      () async {
        clock = DateTime(2026, 10, 20, 7);
        await app.koachRefresh();
        final base = app.program.week(15).day(2)!;
        expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
        expect(await app.koachStart(15, base), isTrue);
        final a = app.sessionAdapt(15, 2)!;
        final shown = app.adaptDay(15, base, a).exercises;
        final relev = <String, Object?>{};
        var poulie = 0;
        for (final e in shown.where((x) => x.engine)) {
          final goal = app.adaptGoal(15, 2, e, 0);
          final kg = goal?.kg;
          relev['${e.catalogId}'] = kg;
          if (kg == null || kg <= 0) continue;
          if (e.catalogId == 'mu-pushdown-corde') {
            poulie++;
            expect(_surGrille(kg, 2.5), isTrue, reason: '$kg');
          }
          // Aucune charge à plus de deux décimales.
          expect(_surGrille(kg, 0.01), isTrue, reason: '${e.catalogId} $kg');
        }
        _sonde('charges_j2', relev);
        expect(poulie, 1, reason: jsonEncode(relev));
      },
    );

    test('arrêt d’urgence : rien versé au moteur ensuite ; séance commencée '
        'passée minuit jamais déclarée manquée', () async {
      final j1 = app.program.week(15).day(1)!;
      expect(app.adaptOpen(15, j1)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j1), isTrue);
      final e = app
          .adaptDay(15, j1, app.sessionAdapt(15, 1)!)
          .exercises
          .firstWhere((x) => x.engine);
      final log = app.exLog(15, 1, e);
      log.sets.first
        ..reps = '5'
        ..flames = 8;
      app.toggleSet(log, 0, app.logSpec(e));
      app.koachAfterSet(15, j1, e, 0);
      // Dimanche → lundi suivant : la séance commencée n'est pas manquée.
      clock = DateTime(2026, 10, 26, 8);
      await app.koachRefresh();
      final jourJ1 = koachJour(
        app.koachLundi!,
        civilOf(app.program.dateFor(15, 1)),
      );
      final manquees = [
        for (final x in app.koachEngine.journal)
          if (x['type'] == 'seance_manquee') x['jour'],
      ];
      expect(manquees, isNot(contains(jourJ1)), reason: '$manquees');
      final n0 = app.koachEngine.journal.length;
      app.koachStop();
      expect(app.koachEngine.active, isFalse);
      expect(app.koachAfterSet(15, j1, e, 0), isNull);
      expect(app.koachEngine.journal.length, n0);
      _sonde('arret', {'manquees': manquees, 'journal': n0});
    });
  });
}
