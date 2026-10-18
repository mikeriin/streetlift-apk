// KB2 (dev7.2.1, pipeline CP, DECISIONS_CP.md C17.32, C17.33, C17.34) —
// bascule ouverte par dérogation du propriétaire et prise de main
// immédiate : Koach 1.0.5 prend la main la semaine de la première séance
// non faite du programme en cours (jamais une semaine d'avant le départ
// affiché de PR2, jamais une semaine passée, jamais une séance faite),
// programme importé comme programme créé.
//
// Données synthétiques de la forme de la sauvegarde du propriétaire :
// programme importé (`programInstance` généré, semaines au schéma
// `programme_v33`) dont l'affichage repart de S1 à S15 (PR2), ancien
// programme S1 à S14 au journal. Les semaines S15 et suivantes sont celles
// du programme embarqué (même forme : six séances par semaine, squat
// d'endurance à 70 kg à charge fixe). Jamais l'export réel (C17.33.2).
// Horloge injectée ; stockage simulé ; calculs du moteur sur place.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/plan_store.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Programme embarqué et annotations de Koach (fichiers du dépôt).
Map<String, dynamic> _asset(String name) =>
    jsonDecode(utf8.decode(gzip.decode(File('assets/$name').readAsBytesSync())))
        as Map<String, dynamic>;

/// Sauvegarde synthétique de la forme de celle du propriétaire : programme
/// importé de 24 semaines au départ affiché S15 (PR2), commencé le
/// 13/07/2026 ; journal de l'ancien programme jusqu'à S[lastWeek]·J[lastJ]
/// (séries notées à 2 en réserve) ; profil avec poids.
Future<Map<String, dynamic>> _pr2Owner(
  AppStore app, {
  int lastWeek = 14,
  int lastJ = 7,
  bool import = true,
}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ);
  });
  final base = _asset('programme_v33.json.gz');
  final koach = _asset('koach_program.json.gz');
  final weeks = [
    for (final w in (base['weeks'] as List).take(24))
      (w as Map).cast<String, dynamic>(),
  ];
  b['programInstance'] = {
    'v': 1,
    'kind': 'generated',
    'origin': 'user',
    'createdAt': '2026-10-17T12:00:00',
    'updatedAt': '2026-10-17T12:00:00',
    'generator': 'test-kb2',
    'seed': 0,
    'weeks': weeks,
    'koach': {
      'exercises': koach['exercises'],
      'weeks': {
        for (final e in (koach['weeks'] as Map).entries)
          if (int.parse('${e.key}') <= 24) '${e.key}': e.value,
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
  if (import) {
    expect(await app.importAll(jsonEncode(b)), isTrue);
    _profile(app);
  }
  return b;
}

void _profile(AppStore app) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: kc.GuidanceMode.assisted,
      ),
    )..consent = 'refused',
  );
}

/// Journée de la semaine avec des exercices, à partir de [from].
int _dayWithWork(AppStore app, int week, [int from = 1]) {
  for (final d in app.program.week(week).days) {
    if (d.j >= from && d.exercises.isNotEmpty) return d.j;
  }
  fail('aucune journée');
}

/// Section de la sauvegarde exportée.
String _section(AppStore app, String key) =>
    jsonEncode((jsonDecode(app.exportAll()) as Map<String, dynamic>)[key]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 18, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    clock = DateTime(2026, 10, 18, 9); // dimanche, veille de S15 (S1)
    app = AppStore()..storeClock = () => clock;
    await app.init();
  });
  tearDown(() async {
    debugKoachBasculeAutorisee = false;
    await app.flush();
    app.dispose();
  });

  group('bascule ouverte (C17.34)', () {
    test('constante ouverte, critère 10 affiché tel que mesuré', () {
      expect(kKoachBasculeAutorisee, isTrue);
      expect(kKoachCritere10, contains('non tenu'));
      expect(kKoachCritere10, contains('dérogation'));
      expect(kKoachCritere10, contains('5,9 %'));
      expect(kKoachCritere10, contains('86,9 %'));
    });

    test('date d’ouverture notée au premier lancement ; la date '
        'd’installation de dev7.0.0 à dev7.2.0 ne compte pas', () async {
      await _pr2Owner(app);
      app.koachEngine.installedOn = '2026-10-16';
      app.koachNoteInstall();
      expect(app.koachEngine.installedOn, '2026-10-16');
      expect(app.koachEngine.openedOn, '2026-10-18');
      clock = DateTime(2026, 10, 20, 9);
      app.koachNoteInstall();
      expect(app.koachEngine.openedOn, '2026-10-18');
      final back = KoachEngineData.fromJson(
        jsonDecode(jsonEncode(app.koachEngine.toJson())),
      );
      expect(back.openedOn, '2026-10-18');
    });
  });

  group('programme importé PR2 (départ affiché S15)', () {
    test('ouverture le dimanche 18/10 : prise de main en S15 interne '
        '(S1 affichée) dès J1', () async {
      await _pr2Owner(app);
      expect(app.program.firstShown, 15);
      expect(app.program.weekLabel(15), 'S1');
      app.koachNoteInstall();
      expect(app.koachTakeoverPlanned(), 15);
      // Dimanche : la semaine n'a pas commencé, rien n'est coupé.
      expect(app.koachTakeoverWeek(), isNull);
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNull);
      // Lundi 19/10 : prise de main à l'ouverture, J1 servi par Koach.
      clock = DateTime(2026, 10, 19, 7);
      expect(app.koachTakeoverWeek(), 15);
      final sw = Stopwatch()..start();
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.snap, isNotNull, reason: '${e.blocked}');
      expect(e.fromWeek, 15);
      expect(e.closed, 14);
      expect(e.activatedOn, '2026-10-19');
      final types = [for (final x in e.journal) x['type']];
      expect(types.where((t) => t == 'reference').length, 1);
      expect(types, isNot(contains('plan')));
      final j = _dayWithWork(app, 15);
      expect(j, 1);
      final base = app.program.week(15).day(j)!;
      expect(app.koachServesDay(15, j), isTrue);
      final a = app.adaptOpen(15, base)!;
      expect(a.koach?['state'], 'preview');
      expect(await app.koachStart(15, base), isTrue);
      expect(app.sessionAdapt(15, j)!.koach?['state'], 'open');
      // ignore: avoid_print
      print(
        'KB2|dimanche|prise_de_main_ms=${sw.elapsedMilliseconds}|'
        'evenements=${e.journal.length}',
      );
    });

    test('ouverture le mercredi 21/10 avec J1 et J2 faits : J1 et J2 '
        'intacts, Koach sert J3', () async {
      await _pr2Owner(app, lastWeek: 15, lastJ: 2);
      clock = DateTime(2026, 10, 21, 8);
      final before = _section(app, 'logs');
      final j1 = jsonEncode(app.logs[app.sessionKey(15, 1)]!.toJson());
      expect(app.logs[app.sessionKey(15, 1)]!.done, isTrue);
      expect(app.logs[app.sessionKey(15, 2)]!.done, isTrue);
      expect(app.koachTakeoverWeek(), 15);
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.snap, isNotNull, reason: '${e.blocked}');
      expect(e.fromWeek, 15);
      // Séances faites : versées au journal de Koach (sans `plan`), jamais
      // réécrites.
      expect(e.versed, containsAll([app.sessionKey(15, 1), 'S15-J2']));
      expect(_section(app, 'logs'), before);
      final b1 = app.program.week(15).day(1)!;
      app.adaptOpen(15, b1);
      expect(jsonEncode(app.logs[app.sessionKey(15, 1)]!.toJson()), j1);
      expect(app.sessionAdapt(15, 1)?.koach, isNull);
      // J3 : servi par Koach.
      final j = _dayWithWork(app, 15, 3);
      final base = app.program.week(15).day(j)!;
      expect(app.adaptOpen(15, base)!.koach?['state'], 'preview');
      expect(await app.koachStart(15, base), isTrue);
      expect(_section(app, 'logs'), isNot(before));
      expect(jsonEncode(app.logs[app.sessionKey(15, 1)]!.toJson()), j1);
    });

    test('ouverture avant le départ affiché : jamais une semaine de '
        'l’ancien programme', () async {
      // Lundi 12/10 (S14 interne), S14 pas encore faite.
      clock = DateTime(2026, 10, 12, 9);
      await _pr2Owner(app, lastWeek: 13);
      app.koachNoteInstall();
      expect(app.koachEngine.openedOn, '2026-10-12');
      expect(app.koachTakeoverPlanned(), 15);
      expect(app.koachTakeoverWeek(), isNull);
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNull);
      final j = _dayWithWork(app, 14);
      final a = app.adaptOpen(14, app.program.week(14).day(j)!);
      expect(a?.koach, isNull);
      // Le lundi du départ affiché : S15.
      clock = DateTime(2026, 10, 19, 9);
      expect(app.koachTakeoverWeek(), 15);
    });

    test('semaine passée jamais reprise : prise de main la semaine du '
        'jour', () async {
      await _pr2Owner(app);
      app.koachEngine.openedOn = '2026-10-21';
      // Rien fait en S15 ; mercredi 28/10 (S16 interne).
      clock = DateTime(2026, 10, 28, 9);
      expect(app.koachTakeoverWeek(), 16);
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 16);
      expect(app.koachServesWeek(15), isFalse);
      expect(app.koachServesWeek(16), isTrue);
    });

    test('semaine en cours toute faite : prise de main le lundi suivant',
        () async {
      await _pr2Owner(app, lastWeek: 15);
      clock = DateTime(2026, 10, 25, 20); // dimanche, S15 finie
      expect(app.koachTakeoverPlanned(), 16);
      expect(app.koachTakeoverWeek(), isNull);
      clock = DateTime(2026, 10, 26, 8);
      expect(app.koachTakeoverWeek(), 16);
    });

    test('bascule fermée (constante à faux) : rien ne change', () async {
      debugKoachBasculeAutorisee = false;
      await _pr2Owner(app);
      clock = DateTime(2026, 10, 19, 9);
      app.koachNoteInstall();
      expect(app.koachEngine.openedOn, isNull);
      expect(app.koachTakeoverPlanned(), isNull);
      expect(app.koachTakeoverWeek(), isNull);
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNull);
      final a = app.adaptOpen(15, app.program.week(15).day(1)!);
      expect(a, isNotNull);
      expect(a!.koach, isNull);
    });

    test('charge fixe (C15) : squat d’endurance servi à 70 kg par Koach ; '
        'arrêt d’urgence puis réactivation', () async {
      await _pr2Owner(app);
      clock = DateTime(2026, 10, 19, 7);
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15);
      final imp = app.importedProgram!;
      String? key;
      for (final k in imp.fixedLoad.keys) {
        if (int.parse(k.split('|').first) == 15) key = k;
      }
      expect(key, isNotNull);
      final slot = key!.substring(key.indexOf('|') + 1);
      final kg = imp.fixedLoad[key]!.$2;
      expect(kg, 70.0);
      int? j;
      for (final d in app.program.week(15).days) {
        for (final e in d.original.exercises) {
          if (imp.slotOf(15, d.j, e.id) == slot) j = d.j;
        }
      }
      expect(j, isNotNull);
      clock = DateTime(2026, 10, 19 + j! - 1, 9);
      await app.koachRefresh();
      final base = app.program.week(15).day(j)!;
      app.adaptOpen(15, base);
      expect(await app.koachStart(15, base), isTrue);
      final served = app.adaptDay(15, base, app.sessionAdapt(15, j)!);
      final e = served.exercises.firstWhere((x) => x.slotId == slot);
      final log = app.exLog(15, j, e);
      app.adaptPrefill(15, j, e, log);
      expect(app.adaptGoal(15, j, e, 0)!.kg, 70.0);
      // Arrêt d'urgence : la séance suivante est servie telle qu'écrite.
      final before = app.koachEngine.journal.length;
      app.koachStop();
      expect(app.koachEngine.stop, isNotNull);
      final next = _dayWithWork(app, 15, j + 1);
      final nb = app.program.week(15).day(next)!;
      expect(app.koachServesDay(15, next), isFalse);
      expect(app.adaptOpen(15, nb), isNull);
      await app.koachResume();
      expect(app.koachEngine.stop, isNull);
      expect(app.koachEngine.journal.length, greaterThanOrEqualTo(before));
      expect(app.koachServesDay(15, next), isTrue);
    });
  });

  group('données', () {
    test('migration depuis dev7.2.0 : aucune séance réécrite, sauvegarde '
        'd’origine intacte ; export après la prise de main réimporté à '
        'l’identique', () async {
      await _pr2Owner(app);
      // État de dev7.2.0 : installation notée, bascule fermée.
      app.koachEngine.installedOn = '2026-10-18';
      await app.flush();
      final logs = _section(app, 'logs');
      final instance = _section(app, 'programInstance');
      final origin = _section(app, 'programOrigin');
      expect(app.programOrigin, isNotNull);
      clock = DateTime(2026, 10, 19, 7);
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15);
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      expect(app.program.firstShown, 15);
      // Export, puis réimport : mêmes sections, même moteur.
      final text = app.exportAll();
      final engine = _section(app, 'koachEngine');
      expect(await app.importAll(text), isTrue);
      expect(_section(app, 'koachEngine'), engine);
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15);
      expect(app.koachLive, isNotNull);
    });

    test('application fermée pendant la prise de main : rien d’écrit, '
        'reprise propre au lancement suivant', () async {
      final b = await _pr2Owner(app);
      clock = DateTime(2026, 10, 19, 7);
      // La prise de main commence ; l'état enregistré à cet instant est
      // celui qu'un arrêt brutal laisserait.
      final running = app.koachRefresh();
      final cut = app.exportAll();
      expect(
        (jsonDecode(cut) as Map<String, dynamic>)['koachEngine'],
        anyOf(isNull, isNot(contains('snap'))),
      );
      expect(
        jsonEncode((jsonDecode(cut) as Map<String, dynamic>)['logs']),
        jsonEncode(b['logs']),
      );
      await running;
      // Lancement suivant (autre instance, même horloge) depuis cet état.
      SharedPreferences.setMockInitialValues({});
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      expect(await next.importAll(cut), isTrue);
      expect(next.koachEngine.snap, isNull);
      await next.koachRefresh();
      expect(next.koachEngine.fromWeek, 15);
      expect(
        jsonEncode((jsonDecode(next.exportAll()) as Map)['logs']),
        jsonEncode(b['logs']),
      );
      await next.flush();
      next.dispose();
    });
  });

  group('programme créé (kalis_plan)', () {
    test('même règle : la semaine de la première séance non faite, séance '
        'faite intacte', () async {
      clock = DateTime(2026, 10, 5, 9); // lundi
      debugKoachBasculeAutorisee = false;
      final r = app.saveAthleteProfile(
        ProfileDraft.of(sampleStreet5050Profile(on: civilOf(clock)))
          ..consent = 'refused',
      );
      expect(r, isNotNull);
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(app).applyPlanCreation(c);
      final plan = app.planProgram!;
      final lundi = app.koachLundi!;
      final w0 = plan.firstWeek;
      final monday = lundi.addDays(7 * (w0 - 1));
      // Mercredi de la première semaine : la première séance faite.
      clock = DateTime(monday.year, monday.month, monday.day + 2, 9);
      final j0 = _dayWithWork(app, w0);
      app.markSessionDone(w0, j0, true);
      final done = jsonEncode(app.logs[app.sessionKey(w0, j0)]!.toJson());
      debugKoachBasculeAutorisee = true;
      expect(app.koachTakeoverWeek(), w0);
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.snap, isNotNull, reason: '${e.blocked}');
      expect(e.fromWeek, w0);
      expect(
        jsonEncode(app.logs[app.sessionKey(w0, j0)]!.toJson()),
        done,
      );
      final j1 = _dayWithWork(app, w0, j0 + 1);
      expect(app.koachServesDay(w0, j1), isTrue);
      expect(
        app.adaptOpen(w0, app.program.week(w0).day(j1)!)!.koach?['state'],
        'preview',
      );
    });
  });

  group('écran d’attente de la prise de main', () {
    Future<void> show(WidgetTester tester, Future<void> done) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(false, KAccentSpec.byId('violet')),
          home: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => KoachTakeoverDialog(done: done),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('se ferme seul à la fin de la prise de main', (tester) async {
      final done = Completer<void>();
      await show(tester, done.future);
      expect(find.byKey(const ValueKey('koach-takeover')), findsOneWidget);
      expect(
        find.text('Koach prend la main sur ton programme'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('koach-takeover-skip')), findsNothing);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('koach-takeover')), findsNothing);
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('attente bornée : passé le délai, la séance s’ouvre sans '
        'attendre', (tester) async {
      final done = Completer<void>();
      await show(tester, done.future);
      await tester.pump(kKoachTakeoverPatience);
      await tester.pump(const Duration(milliseconds: 300));
      final skip = find.byKey(const ValueKey('koach-takeover-skip'));
      expect(skip, findsOneWidget);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('koach-takeover')), findsNothing);
      // La fin de la prise de main après coup ne ferme rien d'autre.
      done.complete();
      await tester.pumpAndSettle();
      expect(find.text('ouvrir'), findsOneWidget);
    });
  });
}
