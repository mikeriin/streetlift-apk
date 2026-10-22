// RV2 (dev7.6.0, lot de correction des constats mineurs de RV1) — zone
// accueil, jeu, statistiques et écrans du programme : tests de
// non-régression.
//
// - P5 : numéros de semaine affichés (PR2) dans les textes (échéance de fin
//   du programme, boss, phrases de Mon programme) ;
// - H5 : une seule numérotation à l'écran (séances à reprendre,
//   historique) ;
// - P6 : Ma saison quand un bloc est à cheval sur la première semaine
//   affichée ;
// - P8 : lignes de course d'un programme créé (distance, durée) ;
// - H8 : titre « Gardien du repos » ;
// - H10 : remerciement après « Compléter mon profil » ;
// - H7 : jauge des journées du programme sans les semaines masquées.
//
// Données synthétiques seulement (C17.33.2) : programme PR2 synthétique
// (`importPr2Nouveau`), programme embarqué ; horloge injectée ; stockage
// simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart'
    show AthleteProfileFlow;
import 'package:streetlift_tracker/game.dart'
    show GameState, computeBosses, isDeloadWeek;
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/plan/plan_texts.dart' show shownWeekNumber;
import 'package:streetlift_tracker/plan/season_view.dart'
    show storeSeasonOverview;
import 'package:streetlift_tracker/profile_completion.dart'
    show openProfileCompletion;
import 'package:streetlift_tracker/progression.dart' show Progression;
import 'package:streetlift_tracker/stats_data.dart' show statsHistory;
import 'package:streetlift_tracker/stats_performance.dart'
    show shownProgramDays;
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

/// Programme embarqué (40 semaines), JSON décodé.
Map<String, dynamic> _base() =>
    jsonDecode(
          utf8.decode(
            gzip.decode(File('assets/programme_v33.json.gz').readAsBytesSync()),
          ),
        )
        as Map<String, dynamic>;

/// Ligne de programme au format de la sauvegarde.
Exercise _ligne(String sets, {String name = 'Course à pied'}) =>
    Exercise.fromJson({
      'id': 'x',
      'name': name,
      'sets': {'type': 'text', 'value': sets},
      'load': {'type': 'none'},
      'rest': '2 min',
      'restSec': 120,
    });

/// Hôte de « Compléter mon profil » : comme l'invitation de l'accueil, la
/// carte disparaît dès l'appui (invitation vue).
class _Hote extends StatefulWidget {
  const _Hote();
  @override
  State<_Hote> createState() => _HoteState();
}

class _HoteState extends State<_Hote> {
  bool _carte = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _carte
          ? Builder(
              builder: (carte) => TextButton(
                key: const ValueKey('rv2-carte'),
                onPressed: () {
                  setState(() => _carte = false);
                  openProfileCompletion(carte);
                },
                child: const Text('Compléter mon profil'),
              ),
            )
          : const SizedBox.shrink(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Lundi 19/10/2026 : S15 interne = S1 affichée.
  var clock = DateTime(2026, 10, 19, 7);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    store.storeClock = () => clock;
    await store.init();
    await importPr2Nouveau(store);
    expect(store.program.firstShown, 15);
  });
  tearDownAll(() {
    debugKoachBasculeAutorisee = false;
  });

  group('P5 : numéros de semaine affichés (PR2)', () {
    test('fin du programme importé : « S10 » et non « S24 »', () {
      final imp = store.importedProgram;
      expect(imp, isNotNull);
      expect(imp!.event?.name, 'Fin du programme (S10)');
    });

    test('phrases de Mon programme : numéro affiché, ancien numéro marqué', () {
      expect(shownWeekNumber(24, firstShown: 15), '10');
      expect(shownWeekNumber(15, firstShown: 15), '1');
      expect(shownWeekNumber(12, firstShown: 15), '12 (ancienne numérotation)');
      expect(shownWeekNumber(7, firstShown: 1), '7');
    });

    test('boss au-delà des quatre nommés : « Tests · S25 » et non '
        '« Tests · semaine 39 »', () {
      final json = _base();
      // Cinquième semaine de tests (S33) : le dernier boss n'a pas de nom.
      final w33 = (json['weeks'] as List).firstWhere(
        (w) => (w as Map)['n'] == 33,
      );
      ((w33 as Map)['days'] as List).first['title'] = 'TEST bonus';
      final program = Program.fromJson(json)..firstShown = 15;
      final bosses = computeBosses(program, (week, day) => false);
      expect(bosses, hasLength(5));
      expect(bosses.last.firstWeek, 39);
      expect(bosses.last.name, 'Tests · S25');
    });
  });

  group('H5 : une seule numérotation à l’écran', () {
    test('séance à reprendre : « S1 · J… », comme l’accueil (avant : '
        '« S15 · J… »)', () {
      final w = store.program.week(15);
      final d = w.days.firstWhere((x) => x.exercises.isNotEmpty);
      final key = store.sessionKey(15, d.j);
      final serie = store.exLog(15, d.j, d.exercises.first).sets.first
        ..reps = '5'
        ..done = true;
      addTearDown(() {
        serie.done = false;
        store.logs.remove(key);
      });
      final resume = store.sessionsInProgress.firstWhere((s) => s.key == key);
      expect(resume.title, startsWith('S1 · J${d.j} — '));
    });

    test('historique : séances de l’ancien programme marquées « (ancien) », '
        'jamais confondues avec les semaines affichées', () {
      final history = statsHistory(store);
      final old = history.firstWhere((e) => e.id.startsWith('S3-J'));
      expect(old.title, 'S3 (ancien) · ${old.id.substring(3)}');
      // Aucune séance de l'ancien programme n'a un titre de la
      // numérotation affichée.
      for (final e in history) {
        final m = RegExp(r'^S(\d+)-J\d+$').firstMatch(e.id);
        if (m == null) continue;
        final n = int.parse(m[1]!);
        if (n < 1 || n >= 15) continue;
        expect(e.title, contains('(ancien)'), reason: e.id);
      }
    });
  });

  group('H7 : jauge des journées du programme', () {
    test('semaines affichées seulement (avant : journées masquées '
        'comptées)', () {
      final days = shownProgramDays(store);
      final shown = store.program.shownWeeks;
      expect(shown, hasLength(10));
      expect(days.total, shown.fold<int>(0, (n, w) => n + w.days.length));
      expect(days.total, lessThan(store.program.weeks.length * 7));
      // Journal synthétique : ancien programme seulement.
      expect(days.done, 0);
      expect(store.completedCount, greaterThan(0));
    });
  });

  group('P6 : Ma saison, bloc à cheval sur la première semaine affichée', () {
    test('ni semaine masquée dans le bloc, ni phase datée avant S1 '
        'affichée, premier bloc affiché numéroté 1', () {
      final before = clock;
      // Affichage à partir de S17 : le bloc S15-S19 est à cheval.
      store.program.firstShown = 17;
      clock = DateTime(2026, 11, 4, 7);
      addTearDown(() {
        store.program.firstShown = 15;
        clock = before;
      });
      final from = store.program.shownStart!;
      expect(from, DateTime(2026, 11, 2));
      final view = storeSeasonOverview();
      expect(view, isNotNull);
      expect(view!.blockWeeks.map((w) => w.n), [17, 18, 19]);
      expect(
        view.blockWeeks.map((w) => store.program.shownNumber(w.n)),
        everyElement(greaterThanOrEqualTo(1)),
      );
      expect(view.blockIndex, 0);
      expect(view.phases, isNotEmpty);
      for (final p in view.phases) {
        expect(p.start.isBefore(from), isFalse, reason: p.code);
      }
      final first = view.phases.first;
      expect(first.start, from);
      expect(first.weeks, (first.end.difference(from).inDays + 1) ~/ 7);
      expect(first.current, isTrue);
    });
  });

  group('P8 : lignes de course d’un programme créé', () {
    test('« 4 × 400 m » en mètres, « 2 × 10-15 min » en durée (avant : '
        'répétitions)', () {
      final course = _ligne('4 × 400 m');
      final sp = store.logSpec(course);
      expect(sp.kind, 'distance');
      expect(store.setCount(course), 4);
      expect(store.plannedReps(course, sp, 4), everyElement(isNull));
      final duree = _ligne('2 × 10-15 min', name: 'Vélo léger');
      final sd = store.logSpec(duree);
      expect(sd.kind, 'duration');
      expect(sd.seconds, 900);
      // Inchangés : durée d'une traite, séries de répétitions.
      final traite = store.logSpec(_ligne('20-30 min', name: 'Marche'));
      expect(traite.kind, 'duration');
      expect(traite.seconds, 1800);
      expect(store.logSpec(_ligne('5 × 8', name: 'Tractions')).kind, 'reps');
    });
  });

  group('H8 : titre « Gardien du repos »', () {
    // Programme embarqué : deloads S7 (saison 1), S11, S15, S19 (saison 2),
    // S23 (saison 3)…
    final program = Program.fromJson(_base())..start = DateTime(2026, 7, 13);

    bool gardien(Set<int> honorees, int semaine, {int jour = 3}) {
      final now = DateTime(2026, 7, 13 + (semaine - 1) * 7 + jour - 1, 12);
      final g = GameState.compute(
        progression: Progression.calculate(
          logs: const {},
          program: program,
          now: now,
        ),
        program: program,
        logs: const {},
        refs: const {},
        isDone: (w, _) => honorees.contains(w),
        now: now,
      );
      return g.titles.firstWhere((t) => t.id == 'guardian').earned;
    }

    test('pas obtenu tant que des deloads de la saison restent à venir '
        '(avant : obtenu dès le premier)', () {
      expect(gardien({11}, 13), isFalse);
      expect(gardien({11, 15}, 17), isFalse);
    });

    test('obtenu quand tous les deloads d’une saison sont honorés, et gardé '
        'à la saison suivante (avant : perdu)', () {
      expect(gardien({11, 15, 19}, 21), isTrue);
      expect(gardien({7}, 8), isTrue);
      expect(gardien({7}, 30), isTrue);
      // Après la fin du programme.
      expect(gardien({7}, 45), isTrue);
    });

    test('deload manqué ou à venir : pas obtenu', () {
      expect(gardien({}, 8), isFalse);
      expect(gardien({7}, 7), isFalse);
      expect(gardien({7}, 5), isFalse);
    });

    test('« Décharge » d’un programme créé : semaine de deload', () {
      DayPlan jour(String cycle) => DayPlan.manual(
        j: 1,
        title: 'Tirage',
        cycle: cycle,
        exercises: const [],
      );
      WeekPlan semaine(String cycle) => WeekPlan.manual(
        n: 1,
        block: 'Bloc 1',
        color: const Color(0xFF4FA3C7),
        days: [jour(cycle)],
      );
      expect(isDeloadWeek(semaine('Décharge')), isTrue);
      expect(isDeloadWeek(semaine('DELOAD')), isTrue);
      expect(isDeloadWeek(semaine('Montée')), isFalse);
    });
  });

  group('H10 : remerciement de « Compléter mon profil »', () {
    testWidgets('affiché au retour, même quand l’invitation a disparu '
        '(avant : jamais)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const _Hote(),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('rv2-carte')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(AthleteProfileFlow), findsOneWidget);
      expect(find.byKey(const ValueKey('rv2-carte')), findsNothing);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop((
        rubrics: <String>{},
        program: false,
      ));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        find.textContaining('Merci ! Ton profil est à jour.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  });
}
