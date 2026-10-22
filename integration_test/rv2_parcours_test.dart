// RV2 (dev7.6.0) sur émulateur Android, lancé par tools/ci3d_drive.sh avec
// le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/rv2_parcours_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, palette bordeaux, taille d'affichage 90 % ;
// b = thème clair, palette neon, taille d'affichage 110 %.
// Correctifs RV2 des constats mineurs de RV1 qui se voient à l'écran,
// données synthétiques seulement (C17.33.2) :
// 1. écran de séance (séances synthétiques, horloge du chrono décalée) :
//    S6 message de record posé au-dessus de la barre de repos lancée par
//    la série ; S10 intervalles sans récupération écrite (un départ toutes
//    les 30 s, aucune récupération inventée ; le groupe n'existe que dans
//    une séance servie par Koach : son chrono est lancé ici comme le fait
//    l'en-tête du groupe) ; S11 palier de tenue d'un drop set vérifié en
//    secondes, sans record de répétitions ; S15 « Repos complet » ;
// 2. programme PR2 synthétique (`kb2c1_semaine.dart`, départ affiché S15 =
//    S1) : accueil avec une séance à reprendre (H5), Mon programme et fin
//    du programme aux numéros affichés (P5), Ma saison, puis bloc à cheval
//    sur la première semaine affichée (P6) ;
// 3. profil : baisser son expérience (F4) : avertissement qui liste les
//    réponses effacées, « Annuler » ne change rien ;
// 4. écritures refusées (crochet `debugWriteHook`) : bannière fixe qui
//    compte les échecs d'affilée, retirée à la première écriture acceptée
//    (M6).
// Chaque étape note son erreur dans le relevé et le parcours continue ; le
// test échoue à la fin si une vérification a échoué. Relevé
// `rv2_releve_<partie>.json` (écrit à chaque étape), captures
// `rv2_*_<partie>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart'
    show AthleteFlowMode, AthleteProfileFlow;
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/kit/kit.dart' show KSnack;
import 'package:streetlift_tracker/main.dart' show appNavigator, kalisApp;
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/plan/plan_texts.dart' show shownWeekNumber;
import 'package:streetlift_tracker/plan/season_view.dart'
    show SeasonScreen, storeSeasonOverview;
import 'package:streetlift_tracker/profile_v3.dart' show DraftV3;
import 'package:streetlift_tracker/program_screens.dart' show ProgramScreen;
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';
import 'kb2c1_semaine.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

const _cue =
    'Dernier exercice. Un tour = 4 paliers enchaînés en moins de 10 s : '
    '1. tractions pronation PdC jusqu’à RIR 1 → 2. rows australiens jusqu’à '
    'RIR 1 → 3. tenue menton au-dessus de la barre jusqu’à l’échec → 4. dead '
    'hang jusqu’à l’échec. Note les reps (paliers 1-2) et les secondes '
    '(paliers 3-4) sur chaque ligne. 3 min entre les tours.';

/// Numéros internes du nouveau programme (S15 à S24, affichés S1 à S10) :
/// jamais à l'écran (P5, H5).
final _interne = RegExp(r'\bS(1[5-9]|2[0-4])\b');

Future<Map<String, dynamic>> _asset(String name) async {
  final bytes = await rootBundle.load('assets/$name');
  return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
      as Map<String, dynamic>;
}

/// Profil complet d'un intermédiaire avec un record, une échéance et son
/// ancienneté (comme `test/rv2_pf_programme_test.dart`).
ProfileDraft _intermediaire() {
  final d = ProfileDraft()
    ..sex = kc.Sex.male
    ..birthYear = '1994'
    ..height = '178'
    ..weight = '70'
    ..primary = kc.TrainingDiscipline.generalFitness
    ..experience = kc.ExperienceLevel.intermediate
    ..consent = 'refused'
    ..guidance = kc.GuidanceMode.assisted
    ..trainingAge = kc.TrainingAge.over5Years
    ..benchmarks = [
      kc.Benchmark(
        exerciseId: 'sl-traction-lestee',
        kind: kc.BenchmarkKind.loadReps,
        source: kc.BenchmarkSource.declared,
        externalLoadKg: 20,
        reps: 3,
        rir: 1,
        bodyWeightKg: 70,
        date: kc.CivilDate(2026, 9, 1),
      ),
    ]
    ..events = [
      kc.SeasonEvent(
        id: 'event-1',
        kind: kc.EventKind.race,
        priority: kc.EventPriority.main,
        date: kc.CivilDate(2027, 3, 15),
        dateApproximate: true,
        distanceMeters: 10000,
      ),
    ];
  d.addSecondary(kc.TrainingDiscipline.mobility);
  d.goals.add(
    kc.Goal(
      id: 'goal-1',
      kind: kc.GoalKind.habit,
      origin: kc.GoalOrigin.user,
      createdOn: kc.CivilDate(2026, 10, 1),
      sessionsPerWeek: 2,
      weeks: 8,
    ),
  );
  d.days
    ..[2] = 30
    ..[5] = 30;
  d.addPlace(kc.Place.home);
  return d;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  const dark = _part == 'a';
  const theme = dark ? 'sombre' : 'clair';
  const palette = dark ? 'bordeaux' : 'neon';
  const size = dark ? 90 : 110;
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'palette': palette,
    'taille': size,
  };
  final shots = <String>[];
  final erreurs = <String>[];
  binding.reportData = data;

  void record() => data['rv2_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['rv2_${name}_$_part.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    shots.add(name);
    releve['captures'] = shots;
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Étape du parcours : une erreur (vérification ratée, exception) est
  /// notée dans le relevé et le parcours continue.
  Future<void> etape(
    WidgetTester tester,
    String nom,
    Future<void> Function() corps,
  ) async {
    try {
      await corps();
      final ex = tester.takeException();
      if (ex != null) erreurs.add('$nom : exception $ex');
    } catch (e, st) {
      erreurs.add('$nom : $e');
      final pile = '$st'.split('\n').take(12).join('\n');
      releve['pile_$nom'] = pile;
      tester.takeException();
    }
    releve['erreurs'] = erreurs;
    record();
  }

  testWidgets('RV2 $_part ($theme, $palette, $size %) : correctifs de la '
      'séance, du programme PR2, du profil et des écritures refusées', (
    tester,
  ) async {
    KalisClock.setOffsetDays(0);
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = true
      ..defaultRest = 90
      ..prepSec = 0
      ..prefill = true
      ..celebrations = true;
    var offset = Duration.zero;
    final ctl = TimerCtl(now: () => DateTime.now().add(offset));
    Future<void> avance(int s) async {
      offset += Duration(seconds: s);
      await wait(tester, 1300);
    }

    void arret() {
      ctl.stop();
      ctl.side.stop();
      offset = Duration.zero;
    }

    const accent = dark ? KAccentSpec.bordeaux : KAccentSpec.neon;
    const scale = dark ? 0.9 : 1.1;

    Future<void> ouvrir(List<Exercise> exs, int j) async {
      final week = WeekPlan.manual(
        n: 0,
        block: 'RV2',
        color: const Color(0xFF4FA3C7),
        days: [DayPlan.manual(j: j, title: 'RV2', exercises: exs)],
      );
      await tester.pumpWidget(const SizedBox());
      await wait(tester, 300);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _root,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(dark, accent),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(scale)),
              child: child!,
            ),
            home: SessionScreen(week: week, day: week.days.single, timer: ctl),
          ),
        ),
      );
      await wait(tester, 1500);
    }

    Future<void> tapVisible(Finder f) async {
      await tester.ensureVisible(f);
      await wait(tester, 400);
      await tester.tap(f);
      await wait(tester, 600);
    }

    /// Séance passée (autre journée) où [ex] est noté : base des records.
    void passe(int j, Exercise ex, String reps) {
      final log = store.exLog(0, j, ex);
      log.sets.first
        ..reps = reps
        ..done = true
        ..completedAt = '2026-10-20T18:00:00.000';
    }

    // ------------------------------------------- 1. écran de séance
    await etape(tester, 's6', () async {
      final ex = Exercise.manual(
        id: 'RV2-TR',
        name: 'Tractions RV2',
        setsText: '3×8',
        rest: '90 s',
        restSec: 90,
      );
      passe(9601, ex, '5');
      await ouvrir([ex], 9602);
      final serie = store.exLog(0, 9602, ex).sets.first;
      final prerempli = serie.reps;
      if (serie.reps.isEmpty) serie.reps = '8';
      await tapVisible(find.byKey(const ValueKey('set-check-RV2-TR-0')));
      await wait(tester, 400);
      final snack = find.byType(KSnack);
      final bar = find.byKey(const ValueKey('timer-bar-rest'));
      final mesure = snack.evaluate().length == 1 && bar.evaluate().length == 1;
      releve['s6'] = {
        'prerempli': prerempli,
        'validee': serie.done,
        'barre': ctl.label,
        'messages': snack.evaluate().length,
        'record': find
            .textContaining('Record : Tractions RV2')
            .evaluate()
            .length,
        'barres': bar.evaluate().length,
        'auDessus': mesure
            ? tester.getRect(snack).bottom <= tester.getRect(bar).top + 0.5
            : null,
      };
      record();
      await shot('s6_record_barre_repos');
      arret();
      expect(releve['s6'], {
        'prerempli': '8',
        'validee': true,
        'barre': 'REPOS',
        'messages': 1,
        'record': 1,
        'barres': 1,
        'auDessus': true,
      });
    });

    await etape(tester, 's10', () async {
      const sans = kc.GroupSpec(
        groupId: 'g',
        format: kc.GroupFormat.intervals,
        rounds: 3,
        intervalSeconds: 30,
      );
      const avec = kc.GroupSpec(
        groupId: 'g',
        format: kc.GroupFormat.intervals,
        rounds: 3,
        intervalSeconds: 30,
        restBetweenRoundsSeconds: 20,
      );
      final ex = Exercise.manual(
        id: 'RV2-BU',
        name: 'Burpees — intervalles RV2',
        setsText: '3×30 s',
      );
      await ouvrir([ex], 9631);
      // Comme « Lancer les intervalles » de l'en-tête du groupe.
      ctl.startInterval(3, 30, groupIntervalRest(sans));
      await wait(tester, 800);
      final effort1 = ctl.label;
      await shot('s10_effort1');
      await avance(31);
      final effort2 = ctl.label;
      await shot('s10_effort2_sans_recuperation');
      await avance(30);
      final effort3 = ctl.label;
      releve['s10'] = {
        'recuperationSans': groupIntervalRest(sans),
        'recuperationAvec': groupIntervalRest(avec),
        'titreSans': groupTitle(sans),
        'titreAvec': groupTitle(avec),
        'effort1': effort1,
        'apres31s': effort2,
        'apres61s': effort3,
      };
      record();
      arret();
      final r = releve['s10']! as Map;
      expect(r['recuperationSans'], 0);
      expect(r['recuperationAvec'], 20);
      expect('${r['titreSans']}', isNot(contains('récupération')));
      expect('${r['titreAvec']}', contains('récupération'));
      expect(r['effort1'], 'EFFORT 1/3');
      expect(r['apres31s'], 'EFFORT 2/3');
      expect(r['apres61s'], 'EFFORT 3/3');
    });

    await etape(tester, 's11', () async {
      final ex = Exercise.manual(
        id: 'RV2-ZR',
        name: 'ZONE ROUGE — drop set RV2',
        setsText: '2 tours × 4 paliers',
        intensity: 'Échec sur les paliers 3 et 4',
        rest: '3 min',
        restSec: 180,
        cue: _cue,
      );
      // Meilleur passé : 10 au poids du corps (un palier en reps).
      passe(9611, ex, '10');
      await ouvrir([ex], 9612);
      final log = store.exLog(0, 9612, ex);
      // Palier 3 (tenue) vide : le message parle de secondes.
      log.sets[2].reps = '';
      await tapVisible(find.byKey(const ValueKey('set-check-RV2-ZR-2')));
      final videValidee = log.sets[2].done;
      final secondes = find
          .textContaining('Indique le nombre de secondes')
          .evaluate()
          .length;
      final enReps = find.textContaining('nombre de reps').evaluate().length;
      await shot('s11_tenue_vide');
      // 40 s de tenue : validées, sans « record » de 40 répétitions.
      log.sets[2].reps = '40';
      await tapVisible(find.byKey(const ValueKey('set-check-RV2-ZR-2')));
      await wait(tester, 300);
      final record40 = find.textContaining('Record :').evaluate().length;
      await shot('s11_tenue_40s_validee');
      releve['s11'] = {
        'videValidee': videValidee,
        'messageSecondes': secondes,
        'messageReps': enReps,
        'validee40s': log.sets[2].done,
        'record': record40,
      };
      record();
      arret();
      expect(releve['s11'], {
        'videValidee': false,
        'messageSecondes': 1,
        'messageReps': 0,
        'validee40s': true,
        'record': 0,
      });
    });

    await etape(tester, 's15', () async {
      await ouvrir(const [], 9621);
      final title = find.byKey(const ValueKey('rest-day-title'));
      releve['s15'] = {
        'titres': title.evaluate().length,
        'texte': title.evaluate().isEmpty
            ? null
            : tester.widget<Text>(title).data,
        'capitales': find.text('REPOS COMPLET').evaluate().length,
      };
      record();
      await shot('s15_repos_complet');
      expect(releve['s15'], {
        'titres': 1,
        'texte': 'Repos complet',
        'capitales': 0,
      });
    });
    arret();
    await tester.pumpWidget(const SizedBox());
    await wait(tester, 300);
    await store.flush();

    // ------------------------------- 2. programme PR2 synthétique
    Future<void> home() async {
      appNavigator.currentState!.popUntil((r) => r.isFirst);
      await wait(tester, 1200);
    }

    Future<void> push(Widget w) async {
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => w),
        ),
      );
      await wait(tester, 1800);
    }

    Future<void> jour(DateTime d) async {
      final now0 = KalisClock.now().subtract(
        Duration(days: KalisClock.offsetDays),
      );
      final ecart = DateTime(
        d.year,
        d.month,
        d.day,
      ).difference(DateTime(now0.year, now0.month, now0.day)).inHours;
      KalisClock.setOffsetDays((ecart + 12) ~/ 24);
      await wait(tester, 300);
      await store.koachRefresh();
      await wait(tester, 600);
    }

    var monte = false;
    await etape(tester, 'montage', () async {
      // Magasin global de la partie 1 (déjà initialisé) écrit puis
      // remplacé avant la sauvegarde importée : l'application relit
      // celle-ci sur un magasin neuf, comme après un changement de session
      // (SessionHost). Après l'import, une écriture de l'ancien magasin
      // l'écraserait.
      await store.flush();
      store.dispose();
      store = AppStore();
      await raw.clear();
      final seed = AppStore();
      await seed.init();
      seed.settings.theme = dark ? 'dark' : 'light';
      seed.settings.accent = palette;
      seed.settings.displaySize = size;
      seed.saveSettings();
      final b = filledBackup(seed);
      final logs = (b['logs'] as Map).cast<String, dynamic>();
      // Trois semaines d'historique (S12 à S14).
      logs.removeWhere((k, _) {
        final w = int.parse(k.substring(1, k.indexOf('-')));
        return w < 12 || w > 14;
      });
      final base = await _asset('programme_v33.json.gz');
      final koach = await _asset('koach_program.json.gz');
      b['programInstance'] = {
        'v': 1,
        'kind': 'generated',
        'origin': 'user',
        'createdAt': '2026-10-17T12:00:00',
        'updatedAt': '2026-10-17T12:00:00',
        'generator': 'test-rv2',
        'seed': 0,
        'weeks': [
          for (final w in (base['weeks'] as List).take(14))
            (w as Map).cast<String, dynamic>(),
          for (var n = 15; n <= 24; n++)
            (jsonDecode(kKb2c1Semaine) as Map<String, dynamic>)
              ..['n'] = n
              ..['blockKey'] = n <= 19 ? 'NA' : 'NB',
        ],
        'koach': {
          'exercises': koach['exercises'],
          'weeks': {
            for (final e in (koach['weeks'] as Map).entries)
              if (int.parse('${e.key}') <= 14) '${e.key}': e.value,
          },
        },
        'summary': {'firstShownWeek': 15},
        'cycle': 1,
      };
      final pilot = (b['pilotage'] as Map).cast<String, dynamic>();
      const refs = {
        'B4': 71.5,
        'B8': 55.0,
        'B9': 75.0,
        'B10': 15.0,
        'B11': 120.0,
        'B16': 10.0,
        'B17': 30.0,
        'B18': 70.0,
        'B19': 65.0,
        'B20': 35.0,
      };
      for (final e in refs.entries) {
        pilot.putIfAbsent(e.key, () => e.value);
      }
      b['pilotage'] = pilot;
      b['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      releve['import'] = await seed.importAll(jsonEncode(b));
      await seed.flush();
      seed.dispose();

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
            i > 25) {
          break;
        }
      }
      await wait(tester, 1000);
      // Mercredi de S16 (S2 affichée).
      await jour(store.program.dateFor(16, 3));
      store.saveAthleteProfile(
        ProfileDraft.of(
          sampleAthleteProfile(
            on: civilOf(KalisClock.now()),
            guidance: kc.GuidanceMode.assisted,
          ),
        )..consent = 'refused',
      );
      await wait(tester, 600);
      await store.koachRefresh();
      await wait(tester, 600);
      expect(releve['import'], isTrue);
      expect(store.program.firstShown, 15);
      monte = true;
    });

    if (monte) {
      await etape(tester, 'accueil', () async {
        // H5 : séance de S15 commencée puis laissée : à reprendre sous son
        // numéro affiché.
        final w = store.program.week(15);
        final d = w.days.firstWhere((x) => x.exercises.isNotEmpty);
        final key = store.sessionKey(15, d.j);
        store.exLog(15, d.j, d.exercises.first).sets.first
          ..reps = '5'
          ..flames = 8
          ..done = true
          ..completedAt = store.program
              .dateFor(15, d.j)
              .add(const Duration(hours: 18))
              .toIso8601String();
        store.saveLogs();
        await home();
        await wait(tester, 600);
        final resume = store.sessionsInProgress
            .where((s) => s.key == key)
            .map((s) => s.title)
            .toList();
        releve['accueil'] = {
          'libelles': [
            store.program.weekLabel(14),
            store.program.weekLabel(15),
            store.program.weekLabel(16),
          ],
          'aReprendre': resume,
          'finProgramme': store.importedProgram?.event?.name,
          'semaine24': shownWeekNumber(24, firstShown: 15),
          'numerosInternes': find.textContaining(_interne).evaluate().length,
        };
        record();
        await shot('accueil_s2_a_reprendre');
        final r = releve['accueil']! as Map;
        expect(r['libelles'], ['S14 (ancien)', 'S1', 'S2']);
        expect(r['aReprendre'], hasLength(1));
        expect('${(r['aReprendre'] as List).single}', startsWith('S1 · J'));
        expect(r['finProgramme'], 'Fin du programme (S10)');
        expect(r['semaine24'], '10');
        expect(r['numerosInternes'], 0);
      });

      await etape(tester, 'mon_programme', () async {
        await push(const ProgramScreen());
        final internes = find.textContaining(_interne).evaluate().length;
        await shot('mon_programme');
        releve['monProgramme'] = {'numerosInternes': internes};
        record();
        await home();
        expect(internes, 0);
      });

      await etape(tester, 'ma_saison', () async {
        final view = storeSeasonOverview();
        final from = store.program.shownStart;
        await push(const SeasonScreen());
        await shot('ma_saison');
        releve['maSaison'] = {
          'vue': view != null,
          'semainesAffichees': [
            for (final w in view?.blockWeeks ?? const <Never>[])
              store.program.shownNumber(w.n),
          ],
          'phaseAvantS1': view == null || from == null
              ? null
              : view.phases.any((p) => p.start.isBefore(from)),
        };
        record();
        await home();
        final r = releve['maSaison']! as Map;
        expect(r['vue'], isTrue);
        expect(r['semainesAffichees'], everyElement(greaterThanOrEqualTo(1)));
        expect(r['phaseAvantS1'], isFalse);
      });

      await etape(tester, 'ma_saison_a_cheval', () async {
        // P6 : affichage à partir de S17 : le bloc S15-S19 est à cheval
        // (en mémoire seulement, rétabli ensuite).
        store.program.firstShown = 17;
        try {
          await jour(store.program.dateFor(17, 3));
          final view = storeSeasonOverview();
          final from = store.program.shownStart;
          await push(const SeasonScreen());
          await shot('ma_saison_bloc_a_cheval');
          releve['maSaisonACheval'] = {
            'semaines': [
              for (final w in view?.blockWeeks ?? const <Never>[]) w.n,
            ],
            'blocAffiche': view?.blockIndex,
            'premierePhase': view == null || view.phases.isEmpty
                ? null
                : view.phases.first.start == from,
            'phaseAvantS1': view == null || from == null
                ? null
                : view.phases.any((p) => p.start.isBefore(from)),
          };
          record();
          await home();
        } finally {
          store.program.firstShown = 15;
          await jour(store.program.dateFor(16, 3));
        }
        expect(releve['maSaisonACheval'], {
          'semaines': [17, 18, 19],
          'blocAffiche': 0,
          'premierePhase': true,
          'phaseAvantS1': false,
        });
      });

      // --------------------------------------------- 3. profil (F4)
      await etape(tester, 'profil_f4', () async {
        expect(store.saveAthleteProfile(_intermediaire()), isNotNull);
        await wait(tester, 600);
        final saved = jsonEncode(store.athleteProfile!.toJson());
        await push(
          const AthleteProfileFlow(
            mode: AthleteFlowMode.edit,
            editStep: 'experience',
          ),
        );
        await tapVisible(
          find.byKey(const ValueKey('flow-experience-beginner')),
        );
        await tapVisible(find.byKey(const ValueKey('flow-save')));
        await wait(tester, 600);
        final avertissement = {
          'dialogue': find
              .byKey(const ValueKey('pruned-answers'))
              .evaluate()
              .length,
          'records': find.text('• tes records (1)').evaluate().length,
          'echeances': find.text('• tes échéances (1)').evaluate().length,
          'annuler': find
              .byKey(const ValueKey('pruned-cancel'))
              .evaluate()
              .length,
        };
        await shot('profil_f4_avertissement');
        await tester.tap(find.byKey(const ValueKey('pruned-cancel')));
        await wait(tester, 900);
        releve['profilF4'] = {
          ...avertissement,
          'apresAnnuler': find
              .byKey(const ValueKey('pruned-answers'))
              .evaluate()
              .length,
          'parcoursOuvert': find
              .byType(AthleteProfileFlow)
              .evaluate()
              .isNotEmpty,
          'profilInchange': jsonEncode(store.athleteProfile!.toJson()) == saved,
        };
        record();
        await shot('profil_f4_annule');
        await home();
        expect(releve['profilF4'], {
          'dialogue': 1,
          'records': 1,
          'echeances': 1,
          'annuler': 1,
          'apresAnnuler': 0,
          'parcoursOuvert': true,
          'profilInchange': true,
        });
      });

      // ------------------------------------ 4. écritures refusées (M6)
      await etape(tester, 'ecritures_m6', () async {
        final banner = find.byKey(const ValueKey('persistence-banner'));
        final avant = banner.evaluate().length;
        try {
          store.debugWriteHook = (_) async => false;
          store.settings.defaultRest = 100;
          store.saveSettings();
          await store.flush();
          await wait(tester, 1200);
          final un = banner.evaluate().length;
          final echecs1 = store.persistenceFailures.value;
          store.settings.defaultRest = 110;
          store.saveSettings();
          await store.flush();
          await wait(tester, 1200);
          final deux = banner.evaluate().length;
          final echecs2 = store.persistenceFailures.value;
          final texte2 = find
              .textContaining('2 essais refusés d’affilée')
              .evaluate()
              .length;
          final reessayer = find
              .byKey(const ValueKey('persistence-retry'))
              .evaluate()
              .length;
          await shot('m6_banniere_deux_echecs');
          store.debugWriteHook = null;
          final accepte = await store.retrySave();
          await wait(tester, 1500);
          releve['m6'] = {
            'avant': avant,
            'premierEchec': un,
            'echecs1': echecs1,
            'deuxiemeEchec': deux,
            'echecs2': echecs2,
            'echecsApres': store.persistenceFailures.value,
            'texteDeuxEchecs': texte2,
            'reessayer': reessayer,
            'accepte': accepte,
            'apres': banner.evaluate().length,
            'erreur': store.persistenceError.value,
          };
          record();
          await shot('m6_enregistre');
        } finally {
          store.debugWriteHook = null;
        }
        expect(releve['m6'], {
          'avant': 0,
          'premierEchec': 1,
          'echecs1': 1,
          'deuxiemeEchec': 1,
          'echecs2': 2,
          'echecsApres': 0,
          'texteDeuxEchecs': 1,
          'reessayer': 1,
          'accepte': true,
          'apres': 0,
          'erreur': null,
        });
      });
    }

    store.debugWriteHook = null;
    await store.flush();
    KalisClock.setOffsetDays(0);
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    releve['erreurs'] = erreurs;
    record();
    expect(erreurs, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await wait(tester, 300);
  }, timeout: _limit);
}
