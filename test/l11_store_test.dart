// L11 — adaptation au jour le jour branchée sur le store : reprises à 7,
// 14 et 28 jours (une séance par mouvement), maladie et vacances (plan qui
// glisse, rappels suspendus), séance compressée pendant la séance, échange
// d'exercice, modes d'autonomie et annulation, charge de séance, export
// identique sans adaptation, rejeu déterministe après chaque adaptation.
// Stockage simulé, horloge injectée, données synthétiques.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach_adapt.dart';
import 'package:streetlift_tracker/koach_engine.dart' as ke;
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/store.dart';

const _refs = <String, double?>{
  'B4': 71.5,
  'B8': 60,
  'B9': 80,
  'B10': 20,
  'B11': 140,
  'B16': 8,
  'B17': 20,
  'B18': 30,
  'B19': 50,
  'B20': 30,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 8, 24, 10);
  final others = <AppStore>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 8, 24, 10);
    app = AppStore()..storeClock = () => clock;
    await app.init();
    // S1·J1 le 10/08 : S3·J1 le 24/08, S4·J1 le 31/08.
    await app.configureStart(DateTime(2026, 8, 10), references: _refs);
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
    for (final o in others) {
      o.dispose();
    }
    others.clear();
  });

  Future<AppStore> relaunch() async {
    await app.flush();
    final next = AppStore()..storeClock = () => clock;
    await next.init();
    others.add(next);
    return next;
  }

  DayPlan day(int w, int j, [AppStore? s]) =>
      (s ?? app).program.week(w).day(j)!;

  /// Séance faite à l'heure de l'horloge : toutes les séries validées.
  void doSession(int w, int j) {
    final at = clock.toIso8601String();
    final d = app.sessionDay(w, day(w, j));
    final log = app.sessionLog(w, j);
    for (final e in d.exercises) {
      final l = app.exLog(w, j, e);
      for (final s in l.sets) {
        s
          ..reps = '5'
          ..done = true
          ..completedAt = at;
      }
    }
    log
      ..done = true
      ..finishedAt = at;
    app.saveLogs(immediate: true);
  }

  Exercise mainOf(DayPlan d, String prefix) =>
      d.exercises.firstWhere((e) => e.main && e.name.startsWith(prefix));

  String signature(AppStore s, int w, int j) {
    final d = s.sessionDay(w, day(w, j, s));
    return [
      for (final e in d.exercises)
        '${e.id}|${s.setsLabel(e)}|${s.sessionLoad(w, e, day: j)}',
    ].join('\n');
  }

  group('KT-060 reprise après un arrêt', () {
    test('7 jours : −10 % et −1 série, une séance par mouvement ; Assisté : '
        'proposé puis appliqué d\'un tap', () async {
      doSession(3, 1);
      clock = DateTime(2026, 8, 31, 10);
      final base = day(4, 1);
      final info = app.adaptInfo(4, 1);
      expect(info.rule?.band, 1);
      expect(info.movements, containsAll(['mu', 'pull']));
      expect(info.mode, 'assisted');
      expect(info.applied, isFalse);
      final pull = mainOf(base, 'TRACTION');
      final full = app.sessionLoad(4, pull)!;
      expect(full, greaterThan(0));
      expect(app.sessionLoad(4, pull, day: 1), full);
      app.setAdaptSafety(4, base, 'applied');
      final cut = app.sessionLoad(4, pull, day: 1)!;
      expect(cut, lessThanOrEqualTo(full * .9 + 1e-9));
      expect(cut, greaterThan(full * .9 - 2.5));
      final adapted = app.sessionDay(4, base);
      final p2 = adapted.exercises.firstWhere((e) => e.id == pull.id);
      expect(app.setCount(p2), app.setCount(pull) - 1);
      // Rejeu : même séance adaptée après relance.
      final before = signature(app, 4, 1);
      final next = await relaunch();
      expect(signature(next, 4, 1), before);
      // Séance faite ; le lendemain, le dip (pas encore retravaillé) est
      // encore allégé ; la semaine suivante, la traction ne l'est plus.
      doSession(4, 1);
      clock = DateTime(2026, 9, 1, 10);
      expect(app.adaptInfo(4, 2).movements, contains('dip'));
      clock = DateTime(2026, 9, 5, 10);
      expect(app.adaptInfo(5, 1).movements, isNot(contains('pull')));
    });

    test('14 jours : −20 % et série de calibrage, appliqué d\'office en '
        'Guidé, annulable', () {
      doSession(3, 1);
      app.setAutonomyMode('guided');
      expect(app.autonomyMode, 'guided');
      clock = DateTime(2026, 9, 7, 10);
      final base = day(4, 1);
      final info = app.adaptInfo(4, 1);
      expect(info.rule?.band, 2);
      expect(info.rule?.calibrationSet, isTrue);
      expect(info.applied, isTrue);
      final pull = mainOf(base, 'TRACTION');
      final full = app.sessionLoad(4, pull)!;
      expect(app.sessionLoad(4, pull, day: 1)!, lessThanOrEqualTo(full * .8));
      // Pas de série retirée à 14 jours.
      final p2 = app
          .sessionDay(4, base)
          .exercises
          .firstWhere((e) => e.id == pull.id);
      expect(app.setCount(p2), app.setCount(pull));
      app.setAdaptSafety(4, base, 'refused');
      expect(app.adaptInfo(4, 1).applied, isFalse);
      expect(app.sessionLoad(4, pull, day: 1), full);
    });

    test('28 jours : −30 %, semaine de calibrage entière', () {
      doSession(3, 1);
      app.setAutonomyMode('guided');
      clock = DateTime(2026, 9, 21, 10);
      final info = app.adaptInfo(4, 1);
      expect(info.rule?.band, 3);
      expect(info.rule?.calibrationWeek, isTrue);
      doSession(4, 1);
      clock = DateTime(2026, 9, 25, 10);
      expect(app.adaptInfo(4, 2).rule?.band, 3);
      expect(app.adaptInfo(4, 2).movements, isNotEmpty);
      doSession(4, 2);
      clock = DateTime(2026, 9, 29, 10);
      expect(app.adaptInfo(5, 1).rule, isNull);
    });
  });

  group('KT-060 maladie, vacances, plan qui glisse', () {
    test('maladie : pause, rappels suspendus, retour = plan qui glisse, '
        'première semaine × 0,7 (Guidé)', () {
      app.settings.notifOn = true;
      doSession(3, 1);
      app.setAutonomyMode('guided');
      clock = DateTime(2026, 8, 26, 10);
      app.startPause('illness');
      expect(app.adapt.pause?.kind, 'illness');
      expect(planReminders(app, clock), isEmpty);
      expect(app.adaptProposals.where((p) => p.kind == 'slide'), isEmpty);
      clock = DateTime(2026, 9, 8, 10);
      app.endPause();
      expect(app.adapt.pause, isNull);
      expect(app.adapt.pauses.single.to, '2026-09-08');
      // S3·J2 (prévue le 25/08) tombe aujourd'hui : rien n'est doublé.
      expect(app.program.dateFor(3, 2), DateTime(2026, 9, 8));
      expect(planReminders(app, clock), isNotEmpty);
      final info = app.adaptInfo(3, 2);
      expect(info.illness, isTrue);
      expect(info.applied, isTrue);
      final base = day(3, 2);
      final dip = mainOf(base, 'DIP');
      final adapted = app
          .sessionDay(3, base)
          .exercises
          .firstWhere((e) => e.id == dip.id);
      expect(
        app.setCount(adapted),
        (app.setCount(dip) * kIllnessVolume).round(),
      );
      // Semaine suivante : plus d'allègement maladie.
      clock = DateTime(2026, 9, 15, 10);
      expect(app.adaptInfo(4, 2).illness, isFalse);
    });

    test('séances manquées : proposition de glisser, annulable', () {
      doSession(3, 1);
      clock = DateTime(2026, 8, 28, 10);
      final slide = app.adaptProposals.firstWhere((p) => p.kind == 'slide');
      expect(slide.data['days'], 3);
      app.runAdaptAction(slide, 'slide');
      expect(app.program.dateFor(3, 2), DateTime(2026, 8, 28));
      expect(app.adaptProposals.where((p) => p.kind == 'slide'), isEmpty);
      final e = app.adapt.events.lastWhere((e) => e.kind == 'slide');
      expect(app.undoSlide(e), isTrue);
      expect(app.program.dateFor(3, 2), DateTime(2026, 8, 25));
    });
  });

  group('KT-058 et KT-059 dans le store', () {
    test(
      'compression pendant la séance puis annulation ; export et rejeu',
      () async {
        final base = day(3, 1);
        expect(identical(app.sessionDay(3, base), base), isTrue);
        final plain = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        expect(plain.containsKey('adapt'), isFalse);
        // Séance commencée : première série du muscle-up faite.
        for (final e in base.exercises) {
          app.exLog(3, 1, e);
        }
        final mu = mainOf(base, 'MUSCLE-UP');
        app.exLog(3, 1, mu).sets.first
          ..reps = '4'
          ..done = true
          ..completedAt = clock.toIso8601String();
        final plan = app.adaptCompressPreview(3, base, 30);
        expect(plan.unchanged, isFalse);
        expect(plan.warmup, isFalse, reason: 'séance commencée');
        app.applyCompression(3, base, plan);
        final d = app.sessionDay(3, base);
        expect(app.adaptCompressed(3, 1), 30);
        for (final e in base.exercises.where((e) => e.main)) {
          expect(d.exercises.any((x) => x.id == e.id), isTrue);
        }
        for (final id in plan.removed) {
          expect(d.exercises.any((x) => x.id == id), isFalse);
          expect(app.logs['S3-J1']!.ex.containsKey(id), isFalse);
        }
        expect(app.logs['S3-J1']!.ex[mu.id]!.sets.first.done, isTrue);
        final exported = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        expect(exported['adapt']['sessions']['S3-J1']['minutes'], 30);
        final before = signature(app, 3, 1);
        final next = await relaunch();
        expect(signature(next, 3, 1), before);
        app.clearCompression(3, base);
        expect(identical(app.sessionDay(3, base), base), isTrue);
        for (final e in base.exercises.where((e) => e.main)) {
          final log = app.logs['S3-J1']!.ex[e.id]!;
          expect(log.sets.length, app.setCount(e));
        }
      },
    );

    test('échange : substitut du même type, première série de calibrage, '
        'retour à l\'original', () async {
      final base = day(3, 1);
      final catalog = await app.adaptCatalog();
      Exercise? original;
      List<dynamic> candidates = const [];
      for (final e in base.exercises) {
        candidates = app.adaptSwapCandidates(catalog, e, motive: 'busy');
        if (candidates.isNotEmpty) {
          original = e;
          break;
        }
      }
      expect(original, isNotNull);
      final to = app
          .adaptSwapCandidates(catalog, original!, motive: 'busy')
          .first;
      final pack = app.adaptPackOf(original, catalog)!;
      expect(to.type, pack.type);
      app.applySwap(3, base, original, to, 'busy', catalog);
      final d = app.sessionDay(3, base);
      final sub = d.exercises.firstWhere((e) => e.id.startsWith(original!.id));
      expect(sub.id, '${original.id}~${to.id}');
      // G3 : le substitut porte le nom de la base v1.1.
      expect(sub.name, app.adaptCatalogName(to));
      expect(app.content.idFor(sub.name), isNotNull);
      expect(sub.cue, contains('calibrage'));
      final before = signature(app, 3, 1);
      final next = await relaunch();
      expect(signature(next, 3, 1), before);
      app.revertSwap(3, base, original.id);
      expect(identical(app.sessionDay(3, base), base), isTrue);
    });
  });

  group('KT-063 modes d\'autonomie', () {
    test('sans profil : Assisté par défaut ; changement à tout moment', () {
      expect(app.autonomyMode, 'assisted');
      for (final m in kAutonomyModes) {
        app.setAutonomyMode(m);
        expect(app.autonomyMode, m);
      }
      const up2 = ke.KSuggestion(37.5, 32.5, 5, 'up', 'easy2');
      const up1 = ke.KSuggestion(35, 32.5, 2.5, 'up', 'easy1');
      const down = ke.KSuggestion(30, 32.5, -2.5, 'down', 'missed');
      app.setAutonomyMode('guided');
      expect(app.koachSuggestionAction(up2), 'auto');
      expect(app.koachSuggestionAction(up1), 'none');
      expect(app.koachSuggestionAction(down), 'auto');
      app.setAutonomyMode('assisted');
      expect(app.koachSuggestionAction(up1), 'propose');
      app.setAutonomyMode('expert');
      expect(app.koachSuggestionAction(down), 'info');
    });

    test('profil migré sans choix : Assisté ; choix enregistré dans le '
        'profil', () {
      const at = '2026-08-24T10:00:00';
      final p = UserProfile(origin: 'migration', createdAt: at);
      p.setField('autonomy', 'guided', at, source: 'estimated');
      app.saveProfile(p);
      expect(app.autonomyMode, 'assisted');
      app.setAutonomyMode('guided');
      expect(app.autonomyMode, 'guided');
      expect(app.profile!.fields['autonomy']!.source, 'declared');
    });

    test('Guidé : baisse de valeur acceptée d\'office au bilan, annulable', () {
      final p = <String, dynamic>{
        'id': 'S3-J1|B8',
        'kind': 'value',
        'ref': 'B8',
        'from': 60.0,
        'to': 57.5,
        'source': 'koach',
        'reason': 'down',
      };
      app.acceptKoachProposal(p);
      expect(app.values['B8'], 57.5);
      app.undoKoachProposal(p);
      expect(app.values['B8'], 60);
      final d = app.koach.decisions.singleWhere((d) => d.id == 'S3-J1|B8');
      expect(d.status, 'refused');
    });
  });

  group('KT-061 et KT-064', () {
    test('charge de séance : prudence au-delà de 1,5 fois la moyenne', () {
      final keys = <String>[];
      // Une séance par semaine sur 5 semaines (S3 à S7, J2).
      for (var w = 3; w <= 7; w++) {
        clock = app.program.dateFor(w, 2).add(const Duration(hours: 10));
        doSession(w, 2);
        keys.add('S$w-J2');
      }
      for (final k in keys.take(4)) {
        app.adapt.difficulty[k] = {'rpe': 5, 'minutes': 60};
      }
      app.adapt.difficulty[keys.last] = {'rpe': 7, 'minutes': 60};
      app.saveLogs(immediate: true);
      expect(app.adaptLoadCaution, isNull, reason: '420 / 300 = 1,4');
      app.adapt.difficulty[keys.last] = {'rpe': 8, 'minutes': 60};
      app.saveLogs(immediate: true);
      final c = app.adaptLoadCaution;
      expect(c, isNotNull);
      expect(c!.$1, closeTo(480 / 300, 1e-9));
      expect(app.adaptProposals.any((p) => p.kind == 'caution'), isTrue);
      app.applyLighten();
      expect(app.adapt.lightenFrom, isNotNull);
    });

    test('question de difficulté : débutants et novices, Guidé ou Assisté', () {
      const at = '2026-08-24T10:00:00';
      final p = UserProfile(origin: 'onboarding', createdAt: at);
      p.setField('benchmarks', {'pushups': 1, 'pullups': 1}, at);
      p.setField('autonomy', 'guided', at);
      app.saveProfile(p);
      expect(app.adaptLevel, 1);
      expect(app.adaptSimplified, isTrue);
      doSession(3, 1);
      expect(app.adaptAsksDifficulty('S3-J1'), isTrue);
      app.setSessionDifficulty('S3-J1', 6);
      expect(app.adapt.difficulty['S3-J1']!['rpe'], 6);
      expect(app.adaptAsksDifficulty('S3-J1'), isFalse);
      app.setAutonomyMode('expert');
      expect(app.adaptSimplified, isFalse);
    });

    test('export sans adaptation identique ; import strict', () async {
      final plain = app.exportAll();
      expect((jsonDecode(plain) as Map).containsKey('adapt'), isFalse);
      final bad = jsonDecode(plain) as Map<String, dynamic>;
      bad['adapt'] = {
        'v': 1,
        'difficulty': {
          'S3-J1': {'rpe': 42, 'minutes': 60},
        },
      };
      expect(await app.importAll(jsonEncode(bad)), isFalse);
    });
  });
}
