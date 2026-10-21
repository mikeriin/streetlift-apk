// RV1c1 (dev7.5.1, DECISIONS_CP.md C17.45) sur émulateur Android, lancé
// par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/rv1c1_chronos_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, palette bordeaux, taille d'affichage 90 % ;
// b = thème clair, palette neon, taille d'affichage 110 %.
// Constats du propriétaire du 21/10/2026 (dev7.4.0), données synthétiques
// (C17.33.2) ; chrono de la séance à horloge décalée (les 3 min d'un tour
// d'E3MOM passent d'un coup) :
// 1. squat E3MOM 6 × 3 avec dead hang 30 s dans la pause : « avant » =
//    ancien chemin du sablier (le chrono de la tenue remplace celui des
//    tours) ; « après » = sablier au tour 3 : chrono secondaire, chrono des
//    tours intact, série validée sans repos, tour 4 au bon moment ;
// 2. intervalles 8 × 30 s / 30 s (exercice remplacé) : aucun sablier par
//    tour, Lancer rythme effort et récupération ;
// 3. tenue hors groupe : chrono principal, comme avant.
// Relevé `rv1c1_releve_<partie>.json`, captures `rv1c1_*_<partie>.png`.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': dark ? 'sombre' : 'clair',
    'palette': dark ? 'bordeaux' : 'neon',
    'taille': dark ? 90 : 110,
  };
  final shots = <String>[];
  binding.reportData = data;

  void record() => data['rv1c1_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['rv1c1_${name}_$_part.png'] = base64Encode(png.buffer.asUint8List());
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

  testWidgets('RV1c1 $_part : chronos des groupes au chrono', (tester) async {
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
      ..prefill = true;
    var offset = Duration.zero;
    final ctl = TimerCtl(now: () => DateTime.now().add(offset));
    Future<void> avance(WidgetTester tester, int s) async {
      offset += Duration(seconds: s);
      await wait(tester, 1300);
    }

    final accent = dark ? KAccentSpec.bordeaux : KAccentSpec.neon;
    final scale = dark ? 0.9 : 1.1;

    Future<void> ouvrir(List<Exercise> exs, int j) async {
      final week = WeekPlan.manual(
        n: 0,
        block: 'RV1c1',
        color: const Color(0xFF4FA3C7),
        days: [DayPlan.manual(j: j, title: 'RV1c1', exercises: exs)],
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
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: SessionScreen(
              week: week,
              day: week.days.single,
              timer: ctl,
            ),
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

    // ---------------------------------------- 1. E3MOM avec dead hang
    final squat = Exercise.manual(
      id: 'C1E-SQ',
      name: 'Squat',
      setsText: '6×3 · E3MOM',
      kg: 95,
    );
    final hang = Exercise.manual(
      id: 'C1E-DH',
      name: 'Dead hang — enchaîné dans la pause',
      setsText: '6×30 s',
    );
    await ouvrir([squat, hang], 9841);
    final launch = find.textContaining('Lancer l’E3MOM');
    expect(launch, findsOneWidget);
    // Avant (dev7.4.0) : le sablier appelait le chrono principal et
    // remplaçait le chrono des tours.
    await tapVisible(launch);
    await avance(tester, 2 * 180 + 20);
    ctl.single('TENUE', 30);
    await wait(tester, 800);
    releve['avant'] = {'barre': ctl.label, 'groupe': ctl.groupRunning};
    await shot('avant_e3mom_tenue');
    ctl.stop();
    offset = Duration.zero;
    await wait(tester, 500);
    // Après : relancé, tour 3, sablier de la 3e tenue.
    await tapVisible(launch);
    await avance(tester, 2 * 180 + 20);
    final tour3 = ctl.label;
    final hourglass = find.byTooltip('Compte à rebours');
    final sabliers = hourglass.evaluate().length;
    await tapVisible(hourglass.at(2));
    final apresSablier = ctl.label;
    final second = ctl.side.running ? ctl.side.label : null;
    await shot('apres_e3mom_tenue');
    await tapVisible(find.byTooltip('Valider la série B·1'));
    final apresValidation = ctl.label;
    final validee = store.exLog(0, 9841, hang).sets.first.done;
    await avance(tester, 30);
    final tenue = ctl.side.label;
    await shot('apres_e3mom_tenue_finie');
    await avance(tester, 3 * 180 - (2 * 180 + 20 + 30));
    final tour4 = ctl.label;
    await shot('apres_e3mom_tour4');
    releve['e3mom'] = {
      'tour3': tour3,
      'sabliers': sabliers,
      'apresSablier': apresSablier,
      'secondaire': second,
      'apresValidation': apresValidation,
      'tenueValidee': validee,
      'tenue': tenue,
      'tour4': tour4,
    };
    record();
    ctl.stop();
    ctl.side.stop();
    offset = Duration.zero;

    // ---------------------------------------- 2. intervalles
    final iv = Exercise.manual(
      id: 'C1E-IV',
      name: 'Mountain climbers',
      setsText: '8× (30 s effort / 30 s repos)',
    );
    await ouvrir([iv], 9842);
    final ivSabliers =
        find.byTooltip('Compte à rebours').evaluate().length +
        find.byTooltip('Chrono montant').evaluate().length;
    final ivLaunch = find.textContaining('Lancer 8 × 30');
    final ivLancer = ivLaunch.evaluate().length;
    await tapVisible(ivLaunch);
    final effort1 = ctl.label;
    await tapVisible(find.byTooltip('Valider la série 1').first);
    final apresTour = ctl.label;
    await avance(tester, 31);
    final repos1 = ctl.label;
    await shot('apres_intervalles');
    await avance(tester, 30);
    final effort2 = ctl.label;
    releve['intervalles'] = {
      'sabliers': ivSabliers,
      'lancer': ivLancer,
      'effort1': effort1,
      'apresTour': apresTour,
      'repos1': repos1,
      'effort2': effort2,
    };
    record();
    ctl.stop();
    offset = Duration.zero;

    // ---------------------------------------- 3. tenue hors groupe
    final plank = Exercise.manual(
      id: 'C1E-PL',
      name: 'Planche',
      setsText: '3×30 s',
    );
    await ouvrir([plank], 9843);
    await tapVisible(find.byTooltip('Compte à rebours').first);
    releve['horsGroupe'] = {
      'barre': ctl.label,
      'groupe': ctl.groupClock,
      'secondaire': ctl.side.visible,
      'plus15': find.text('+15 s').evaluate().length,
    };
    await shot('apres_tenue_hors_groupe');
    ctl.stop();
    await wait(tester, 500);
    releve['exceptions'] = '${tester.takeException()}';
    record();

    expect(releve['avant'], {'barre': 'TENUE', 'groupe': false});
    expect(releve['e3mom'], {
      'tour3': 'TOUR 3/6',
      'sabliers': 6,
      'apresSablier': 'TOUR 3/6',
      'secondaire': 'TENUE',
      'apresValidation': 'TOUR 3/6',
      'tenueValidee': true,
      'tenue': 'TERMINÉ',
      'tour4': 'TOUR 4/6',
    });
    expect(releve['intervalles'], {
      'sabliers': 0,
      'lancer': 1,
      'effort1': 'EFFORT 1/8',
      'apresTour': 'EFFORT 1/8',
      'repos1': 'REPOS 1/8',
      'effort2': 'EFFORT 2/8',
    });
    expect(releve['horsGroupe'], {
      'barre': 'TENUE',
      'groupe': false,
      'secondaire': false,
      'plus15': 1,
    });
    expect(releve['exceptions'], 'null');
    await tester.pumpWidget(const SizedBox());
    await wait(tester, 300);
  });
}
